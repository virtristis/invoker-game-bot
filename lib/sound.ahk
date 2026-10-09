; Invoker Game Bot — Звук в конце прогона: синтез WAV, громкость, окно выбора.
; Часть invoker_bot.ahk (подключается через #Include), сам по себе не запускается.

; сигнал по окончании прогона: выбранный звук (свои звуки — синтезированные WAV)
; + уведомление Windows (может быть скрыто режимом «Не беспокоить»)
Notify(res) {
    if !Sound
        return
    PlayChime()
    TrayTip T("done") res, T("title"), "Mute"
}

PlayChime() {
    if Sound
        PlaySound(SoundName)
}

; громкость программы 0–100 (не трогает общую громкость Windows)
SetAppVolume(v) {
    x := Round(Max(0, Min(100, v)) / 100 * 0xFFFF)
    DllCall("winmm\waveOutSetVolume", "ptr", 0, "uint", x | (x << 16))
}

PlaySound(name) {
    SetAppVolume(SoundVol)
    try {
        switch name {
            case "windows": SoundPlay "*64"
            case "custom":
                if (SoundFile != "" && FileExist(SoundFile))
                    SoundPlay SoundFile
                else
                    PlaySound("chime")
            default:
                wav := DataDir "\sound-" name ".wav"
                if !FileExist(wav)
                    MakeTone(wav, SoundPreset(name))
                SoundPlay wav                          ; асинхронно, не тормозит бота
        }
    }
}

; синтез в WAV: 16 бит моно 22 кГц, мягкая атака и затухание
MakeTone(path, preset) {
    sr := 22050, n := Round(sr * preset.dur)
    buf := Buffer(44 + n * 2, 0)
    PutAscii(off, str) {                         ; ASCII-метки заголовка без нулевого байта
        loop parse str
            NumPut("uchar", Ord(A_LoopField), buf, off + A_Index - 1)
    }
    ; заголовок WAV: RIFF / WAVE / fmt (PCM, 1 канал, 16 бит) / data
    PutAscii(0, "RIFF"), NumPut("uint", 36 + n * 2, buf, 4)
    PutAscii(8, "WAVEfmt ")
    NumPut("uint", 16, "ushort", 1, "ushort", 1, "uint", sr, "uint", sr * 2, "ushort", 2, "ushort", 16, buf, 16)
    PutAscii(36, "data"), NumPut("uint", n * 2, buf, 40)
    pi2 := 6.283185307179586
    loop n {
        tt := (A_Index - 1) / sr, v := 0
        for nt in preset.notes {
            dt := tt - nt.t
            if (dt < 0)
                continue
            if nt.HasOwnProp("f1") {                 ; подъём частоты, потом ровный тон
                sw := nt.sweep, k := (nt.f1 - nt.f) / sw
                ph := dt < sw ? pi2 * (nt.f * dt + k * dt * dt / 2)
                              : pi2 * (nt.f * sw + k * sw * sw / 2 + nt.f1 * (dt - sw))
            } else
                ph := pi2 * nt.f * dt
            env := Exp(-dt * nt.decay) * Min(1, dt / 0.006)
            for pt in nt.p
                v += env * pt[2] * Sin(pt[1] * ph)
        }
        NumPut("short", Round(Max(-1, Min(1, v * preset.gain)) * 32767), buf, 44 + (A_Index - 1) * 2)
    }
    f := FileOpen(path, "w")
    f.RawWrite(buf)
    f.Close()
}

; окно «Звук»: список звуков (клик — выбрать и послушать) и ползунок громкости
ShowSoundWin() {
    global SW, swPic
    try SW.Destroy()
    SW := Gui("+Owner" G.Hwnd " +AlwaysOnTop -MinimizeBox", T("sndTitle"))
    SW.BackColor := C.bg
    SW.MarginX := 0, SW.MarginY := 0
    DarkTitle(SW.Hwnd)
    swPic := SW.Add("Picture", "x0 y0 w320 h372 +0x100")     ; SS_NOTIFY — получаем клики
    Clickable[swPic.Hwnd] := true
    RenderSoundWin()
    SW.Show("w320 h372")
}

RenderSoundWin() {
    cv := CvNew(320, 372, C.bg)
    Txt(cv, T("sndTitle"), 20, 12, 280, 24, "Segoe UI Semibold", 12.5, 0, C.text, 0)
    for i, name in SoundList() {
        y := 46 + (i - 1) * 36, on := (SoundName = name)
        RRect(cv, 20, y, 280, 30, 8, on ? Linear(0, y, 0, y + 30, C.accent2, C.accent) : Solid(C.card))
        label := T("snd_" name)
        if (name = "custom" && SoundFile != "")
            SplitPath(SoundFile, &label)                   ; имя выбранного файла
        icon := name = "custom" ? 0xE8E5 : name = "windows" ? 0xE7F4 : 0xE8D6
        Txt(cv, Chr(icon), 32, y, 20, 30, IconFont, 11, 0, on ? C.onAccent : C.accent, 0)
        Txt(cv, label, 58, y, 230, 30, "Segoe UI", 11, 0, on ? C.onAccent : C.text, 0)
    }
    Txt(cv, T("sndVolume"), 20, 306, 200, 20, "Segoe UI Semibold", 10, 0, C.muted, 0)
    Txt(cv, SoundVol " %", 220, 306, 80, 20, "Segoe UI Semibold", 10, 0, C.text, 2)
    kx := 20 + 280 * SoundVol / 100
    RRect(cv, 20, 337, 280, 6, 3, Solid(C.field))
    RRect(cv, 20, 337, Max(6, kx - 20), 6, 3, Linear(20, 0, 300, 0, C.accent2, C.accent))
    Circle(cv, kx, 340, 9, Solid("FFFFFF"))
    CvToPic(cv, swPic)
}

; клики по окну «Звук» (WM_LBUTTONDOWN — чтобы ползунок можно было тянуть)
SoundWinDown(wParam, lParam, msg, hwnd) {
    global SoundName, SoundFile, SoundVol
    if !IsSet(swPic) || !swPic || hwnd != swPic.Hwnd
        return
    MouseRel(swPic, &mx, &my)
    if (my >= 324 && my <= 356) {                     ; ползунок: тянем, пока зажата кнопка
        while GetKeyState("LButton") {
            MouseRel(swPic, &mx, &my)
            v := Round(Max(0, Min(100, (mx - 20) / 280 * 100)) / 5) * 5
            if (v != SoundVol)
                SoundVol := v, RenderSoundWin()
            Sleep 15
        }
        SaveCfg()
        PlaySound(SoundName)
        return 0
    }
    i := Floor((my - 46) / 36) + 1
    if (i < 1 || i > SoundList().Length || Mod(my - 46, 36) > 30 || mx < 20 || mx > 300)
        return 0
    name := SoundList()[i]
    if (name = "custom") {
        SW.Opt("+OwnDialogs")
        file := FileSelect(1, SoundFile, T("snd_custom"), "Audio (*.wav; *.mp3)")
        if (file = "")
            return 0
        SoundFile := file
    }
    SoundName := name
    RenderSoundWin()
    SaveCfg()
    PlaySound(name)
    return 0
}

RenderSoundPill() {
    cv := CvNew(32, 24, C.bg)
    RRect(cv, 0, 0, 32, 24, 7, Solid(IsHover(bSnd) ? "353A4A" : C.field))
    Txt(cv, Chr(0xE767), 0, 0, 32, 24, IconFont, 11, 0, Sound ? C.accent : C.muted)
    CvToPic(cv, bSnd)
}
