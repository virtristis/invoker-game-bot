; Invoker Game Bot — Тренировка без сайта: окно, очередь спеллов, проверка нажатий.
; Часть invoker_bot.ahk (подключается через #Include), сам по себе не запускается.

DrillActive(*) => DW && WinActive("ahk_id " DW.Hwnd)

DrillOpen() {
    global DW, dwPic
    if !DW {
        DW := Gui("+Owner" G.Hwnd " +AlwaysOnTop -MinimizeBox")
        DW.BackColor := C.card
        DW.MarginX := 0, DW.MarginY := 0
        DarkTitle(DW.Hwnd)
        dwPic := DW.Add("Picture", "x0 y0 w" DW_W " h" DW_H)
        DW.OnEvent("Close", (*) => StopBot())
        DW.OnEvent("Escape", (*) => StopBot())
    }
    DW.Title := T("drillTitle")
    RegisterDrillKeys()
    DrillReset()
    DS.loading := !IconsReady(DS.mode)
    DW.Show("w" DW_W " h" DW_H)
    RenderDrill()
    SetTimer DrillTick, 100
    if DS.loading                                     ; иконки качаются один раз
        SetTimer DrillLoadIcons, -50
}

DrillLoadIcons() {
    IconsFetch(DS.mode)
    DS.loading := false
    RenderDrill()
}

DrillClose() {
    SetTimer DrillTick, 0
    DS.phase := ""
    if DW
        DW.Hide()
}

; свои Q/W/E/R и пробел, пока активно окно тренировки
RegisterDrillKeys() {
    global DrillKeys
    HotIf DrillActive
    for phys in DrillKeys
        try Hotkey(phys, "Off")
    DrillKeys := Map()
    for letter in ["q", "w", "e", "r"] {
        phys := CurKeyMap[letter]
        DrillKeys[phys] := letter
        try Hotkey(phys, DrillKey, "On")
    }
    Hotkey("Space", DrillSpace, "On")
    HotIf
}

DrillReset() {
    DS.mode := DrillGame, DS.weak := DrillWeak, DS.noData := false
    spells := DS.mode = "old" ? OldSpells : NewSpells
    pool := []
    for name in spells
        pool.Push(name)
    length := pool.Length
    if DS.weak {
        avgs := SpellAvgs(DS.mode)
        if avgs.Count {
            pool := WeakSpells(spells, avgs, DS.mode = "old" ? 9 : 4)
            length := pool.Length * 2
        } else
            DS.noData := true
    }
    DS.queue := DrillQueue(pool, length)
    DS.phase := "ready", DS.idx := 0, DS.orbs := [], DS.mistakes := 0, DS.times := []
    DS.missed := false, DS.flash := ""
    RenderDrill()
}

DrillSpace(*) {
    if (DS.phase = "done")
        DrillReset()
    if (DS.phase != "ready")
        return
    DS.phase := "run", DS.idx := 1
    DS.startTick := DS.spellTick := A_TickCount
    SetStatus(T("drillRun"))
    RenderDrill()
}

DrillKey(hk) {
    letter := DrillKeys.Has(hk) ? DrillKeys[hk] : ""
    if (letter = "" || DS.phase != "run")
        return
    if (letter != "r") {                              ; шар: держим три последних, как в игре
        DS.orbs.Push(letter)
        if (DS.orbs.Length > 3)
            DS.orbs.RemoveAt(1)
        DrillRedraw()
        return
    }
    spell := DS.queue[DS.idx]
    if !OrbsMatch(DrillCombo(spell), DS.orbs, DS.mode) {
        DS.mistakes++, DS.missed := true
        DS.flash := "wrong", DS.flashTick := A_TickCount
        DrillRedraw()
        return
    }
    ms := A_TickCount - DS.spellTick
    RecordSpell(DS.mode, spell, ms)
    DS.times.Push([spell, ms])
    if (DS.idx >= DS.queue.Length)
        return DrillFinish()
    DS.idx++
    DS.spellTick := A_TickCount, DS.missed := false
    DS.flash := "ok", DS.flashTick := A_TickCount
    DrillRedraw()
}

; перерисовка после нажатия — в отдельном потоке, чтобы обработчик клавиши был мгновенным
DrillRedraw() => SetTimer(RenderDrill, -1)

DrillCombo(spell) => (DS.mode = "old" ? OldSpells : NewSpells)[spell]

DrillFinish() {
    DS.phase := "done", DS.endTick := A_TickCount
    total := Format("{:.2f}", (DS.endTick - DS.startTick) / 1000)
    RecordRun("drill", DS.mode, DS.weak && !DS.noData ? "weak" : "all", Map("sec", total, "rank", "err:" DS.mistakes))
    PlayChime()
    SetStatus(T("drillDone") " " total " " T("sec") "  ·  " T("drillErr") ": " DS.mistakes)
    RenderDrill()
}

DrillTick() {
    if (DS.phase = "run")
        RenderDrill()
}

; outFile — для автотестов: сохранить кадр в PNG вместо показа
RenderDrill(outFile := "") {
    static OrbColors := Map("q", "38BDF8", "w", "C084FC", "e", "F59E0B", "r", "E6E8EF")
    static OrbNames  := Map("q", "quas", "w", "wex", "e", "exort")
    if !DW
        return
    W := DW_W, H := DW_H
    cv := CvNew(W, H, C.card)
    br := Linear(0, 0, 0, H, C.head, C.card)
    DllCall("gdiplus\GdipFillRectangle", "ptr", cv.g, "ptr", br, "float", 0, "float", 0, "float", W, "float", H)
    DllCall("gdiplus\GdipDeleteBrush", "ptr", br)
    Glow(cv, 60, 0, 190, C.accent, 80)
    Glow(cv, W - 40, 20, 140, C.glow2, 40)

    n := DS.queue.Length
    pool := DS.weak && !DS.noData ? T("drillWeak") : T("drillAll")
    now := DS.phase = "done" ? DS.endTick : A_TickCount
    elapsed := DS.phase = "ready" ? 0 : (now - DS.startTick) / 1000
    Txt(cv, StrUpper(DS.mode) "  ·  " pool, 20, 12, 280, 20, "Segoe UI Semibold", 11, 0, C.muted, 0)
    Txt(cv, Format("{:.1f}", elapsed) " " T("sec"), W - 160, 12, 140, 20, "Segoe UI Semibold", 11, 0, C.text, 2)
    doneN := DS.phase = "done" ? n : Max(0, DS.idx - 1)
    RRect(cv, 20, 38, W - 40, 6, 3, Solid(C.field))
    if doneN
        RRect(cv, 20, 38, Max(6, (W - 40) * doneN / n), 6, 3, Linear(20, 0, W - 20, 0, C.accent2, C.accent))

    if (DS.phase = "ready") {
        Txt(cv, T("drillTitle"), 0, 62, W, 44, "Segoe UI Semibold", 26, 0, C.text)
        Txt(cv, StrUpper(DS.mode) "  ·  " n "  ·  " pool, 0, 106, W, 22, "Segoe UI", 12, 0, C.muted)
        for i, ch in ["q", "w", "e"] {                     ; Quas / Wex / Exort
            cx := W / 2 + (i - 2) * 72, col := OrbColors[ch]
            Glow(cv, cx, 190, 50, col, 130)
            if !DrawIcon(cv, IconBmp(DS.mode, OrbNames[ch]), cx - 28, 162, 56, 12)
                Orb(cv, cx, 190, 22, col)
        }
        if DS.loading
            Txt(cv, T("drillIcons"), 0, 244, W, 20, "Segoe UI", 11, 0, C.muted)
        else if DS.noData
            Txt(cv, T("drillNoData"), 0, 244, W, 20, "Segoe UI", 11, 0, "FBBF24")
        Txt(cv, T("drillReady"), 0, 300, W, 30, "Segoe UI Semibold", 13, 0, C.accent2)
    } else if (DS.phase = "run") {
        spell := DS.queue[DS.idx], combo := DrillCombo(spell)
        Txt(cv, DS.idx " / " n, 20, 50, 100, 20, "Segoe UI", 11, 0, C.muted, 0)
        if DS.mistakes
            Txt(cv, "✗ " DS.mistakes, W - 80, 50, 60, 20, "Segoe UI Semibold", 11, 0, "F87171", 2)
        ; иконка спелла — как в игре; если иконки нет, крупно пишем название
        Glow(cv, W / 2, 106, 80, C.accent, 90)
        if DrawIcon(cv, IconBmp(DS.mode, spell), W / 2 - 44, 62, 88, 14) {
            p := RoundPath(W / 2 - 44, 62, 88, 88, 14)
            DllCall("gdiplus\GdipCreatePen1", "uint", ARGB("FFFFFF", 60), "float", 1.5, "int", 2, "ptr*", &pen := 0)
            DllCall("gdiplus\GdipDrawPath", "ptr", cv.g, "ptr", pen, "ptr", p)
            DllCall("gdiplus\GdipDeletePen", "ptr", pen), DllCall("gdiplus\GdipDeletePath", "ptr", p)
            Txt(cv, SpellTitle(spell), 0, 154, W, 28, "Segoe UI Semibold", 15, 0, C.text)
        } else
            Txt(cv, SpellTitle(spell), 0, 84, W, 56, "Segoe UI Semibold", 26, 0, C.text)
        loop 3 {                                          ; три слота шаров, как у Инвокера
            cx := W / 2 + (A_Index - 2) * 56
            if (A_Index <= DS.orbs.Length) {
                ch := DS.orbs[A_Index], col := OrbColors[ch]
                Glow(cv, cx, 212, 40, col, 120)
                if !DrawIcon(cv, IconBmp(DS.mode, OrbNames[ch]), cx - 21, 191, 42, 21)
                    Orb(cv, cx, 212, 20, col)
            } else
                Circle(cv, cx, 212, 20, Solid("1E2130"))
        }
        ; подсказка — если думаешь дольше 2.5 сек или ошибся
        if (DS.missed || A_TickCount - DS.spellTick > 2500) {
            k := ComboProgress(combo, DS.orbs, DS.mode)
            shown := ComboDisplay(combo, DS.orbs, DS.mode, k) "r"
            loop 4 {
                ch := SubStr(shown, A_Index, 1), col := OrbColors[ch]
                key := StrUpper(CurKeyMap[ch])
                x := W / 2 - 95 + (A_Index - 1) * 48, y := 248
                if (A_Index <= k) {
                    RRect(cv, x, y, 42, 42, 10, Solid(col, 210))
                    Txt(cv, key, x, y, 42, 42, "Segoe UI Black", 16, 0, ch = "r" ? "1A1D27" : "FFFFFF")
                } else if (A_Index = k + 1) {
                    RRect(cv, x, y, 42, 42, 10, Solid(col, 230))
                    RRect(cv, x + 2, y + 2, 38, 38, 8, Solid("181B26"))
                    Txt(cv, key, x, y, 42, 42, "Segoe UI Black", 16, 0, col)
                } else {
                    RRect(cv, x, y, 42, 42, 10, Solid("1E2130"))
                    Txt(cv, key, x, y, 42, 42, "Segoe UI Black", 16, 0, col, 1, 80)
                }
            }
        }
        if (DS.flash != "" && A_TickCount - DS.flashTick < 700)
            Txt(cv, DS.flash = "wrong" ? T("drillWrong") : T("drillOk"), 0, 304, W, 30,
                "Segoe UI Semibold", 14, 0, DS.flash = "wrong" ? "F87171" : "4ADE80")
        else
            Txt(cv, Tf("drillPrompt", StrUpper(CurKeyMap["r"])), 0, 304, W, 30, "Segoe UI", 12, 0, C.muted)
    } else if (DS.phase = "done") {
        secs := (DS.endTick - DS.startTick) / 1000
        Txt(cv, T("drillDone"), 0, 56, W, 30, "Segoe UI Semibold", 16, 0, C.muted)
        TitleText(cv, Format("{:.2f}", secs) " " T("sec"), 0, 86, W, 52, "Georgia", 34, 1)
        Txt(cv, Tf("drillAvg", Format("{:.2f}", secs / Max(1, n))) "  ·  " T("drillErr") ": " DS.mistakes,
            0, 146, W, 22, "Segoe UI", 12, 0, C.text)
        ; три самых долгих спелла этого прогона — с иконками
        lines := ""
        for tm in DS.times
            lines .= tm[2] "`t" tm[1] "`n"
        Txt(cv, T("drillSlow"), 0, 180, W, 18, "Segoe UI", 10, 0, C.muted)
        for i, ln in StrSplit(Sort(RTrim(lines, "`n"), "N R"), "`n") {
            if (i > 3)
                break
            p := StrSplit(ln, "`t"), x := 30 + (i - 1) * 136
            if !DrawIcon(cv, IconBmp(DS.mode, p[2]), x + 44, 204, 44, 9)
                RRect(cv, x + 44, 204, 44, 44, 9, Solid("1E2130"))
            Txt(cv, SpellTitle(p[2]), x, 250, 132, 18, "Segoe UI", 10, 0, C.text)
            Txt(cv, Format("{:.2f}", p[1] / 1000) " " T("sec"), x, 266, 132, 18, "Segoe UI Semibold", 10.5, 0, "FBBF24")
        }
        Txt(cv, T("drillAgain"), 0, 304, W, 30, "Segoe UI Semibold", 13, 0, C.accent2)
    }
    if (outFile != "")
        CvSave(cv, outFile)
    else
        CvToPic(cv, dwPic)
}

; автотест --selftest drill-gif: кадры прохождения для GIF в README (%TEMP%\igb-shots\gif\f0001.png …).
; Время виртуальное: перед каждым вызовом метки DS переводятся в «реальные» A_TickCount и обратно,
; так что кадры идут ровно через FrameMs, сколько бы ни занимала отрисовка
DrillGif() {
    global Sound
    static FrameMs := 80
    if DS.loading {
        SetTimer DrillGif, -300
        return
    }
    Sound := false                                         ; без звука в конце
    dir := A_Temp "\igb-shots\gif"
    try DirDelete dir, true
    DirCreate dir
    v := {t: 0, start: 0, spell: 0, flash: -10000, end: 0, frame: 0}   ; v.t — «текущее» время, мс
    ToReal() {
        now := A_TickCount
        DS.startTick := now - (v.t - v.start), DS.spellTick := now - (v.t - v.spell)
        DS.flashTick := now - (v.t - v.flash), DS.endTick := now - (v.t - v.end)
    }
    FromReal() {
        now := A_TickCount
        v.start := v.t - (now - DS.startTick), v.spell := v.t - (now - DS.spellTick)
        v.flash := v.t - (now - DS.flashTick), v.end := v.t - (now - DS.endTick)
    }
    Wait(ms) {                                             ; кадры, пока «идёт время»
        loop Max(1, Round(ms / FrameMs)) {
            ToReal()
            RenderDrill(dir "\f" Format("{:04}", ++v.frame) ".png")
            v.t += FrameMs
        }
    }
    Press(ch) => (ToReal(), DrillKey(CurKeyMap[ch]), FromReal())
    Wait(1600)                                             ; экран «Тренировка»
    ToReal(), DrillSpace(), FromReal()
    for i, spell in DS.queue {
        combo := DrillCombo(spell)
        Wait(i = 3 ? 3600 : Random(260, 520))              ; на третьем «задумались» — видна подсказка
        if (i = 6) {                                       ; ошибка: не те шары
            wrong := combo = "qqq" ? "www" : "qqq"
            loop 3
                Press(SubStr(wrong, A_Index, 1)), Wait(120)
            Press("r"), Wait(700)
        }
        loop 3
            Press(SubStr(combo, A_Index, 1)), Wait(i = 3 ? 260 : 120)
        Press("r")
        Wait(i = DS.queue.Length ? 160 : 240)
    }
    Wait(3600)                                             ; результат
    FileAppend "gif frames " v.frame " in " dir "`n", "*", "UTF-8"
    ExitApp
}

; автотест --selftest drill-shots: проходит тренировку прямыми вызовами (без нажатий,
; работает и на скрытом рабочем столе) и сохраняет кадры окна в %TEMP%\igb-shots
DrillShots() {
    dir := A_Temp "\igb-shots"
    try DirCreate dir
    if DS.loading {                                        ; иконки ещё качаются — зайдём позже
        SetTimer DrillShots, -300
        return
    }
    RenderDrill(dir "\1-ready.png")
    DrillSpace()
    combo := DrillCombo(DS.queue[1])
    DrillKey(CurKeyMap[SubStr(combo, 1, 1)])
    RenderDrill(dir "\2-run.png")
    DS.spellTick -= 3000, DS.startTick -= 3000            ; «думаем» 3 сек — появляется подсказка
    DrillKey(CurKeyMap[SubStr(combo, 2, 1)])
    RenderDrill(dir "\3-hint.png")
    while (DS.phase = "run") {
        wait := Random(500, 2200)                          ; правдоподобное время на спелл
        DS.spellTick -= wait, DS.startTick -= wait
        for ch in StrSplit(DrillCombo(DS.queue[DS.idx]) "r")
            DrillKey(CurKeyMap[ch])
    }
    RenderDrill(dir "\4-done.png")
    FileAppend "shots " dir " mistakes:" DS.mistakes " runs:" DS.times.Length "`n", "*", "UTF-8"
    StopBot(T("drillDone"))
}

; автотест (--selftest drill[-old][-weak][-slow]): сам проходит тренировку настоящими
; нажатиями (SendLevel 1 — чтобы сработали горячие клавиши самой программы)
DrillAutoPlay() {
    SendLevel 1
    WinActivate DW
    WinWaitActive DW, , 2
    delay := InStr(SelfArg, "slow") ? 300 : 30
    Send "{Space}"
    Sleep 200
    Send "{" CurKeyMap["r"] "}"                          ; нарочно ошибаемся один раз
    Sleep 100
    while (DS.phase = "run") {
        idx := DS.idx
        for k in StrSplit(DrillCombo(DS.queue[idx]) "r") {
            Sleep delay
            Send "{" CurKeyMap[k] "}"
        }
        t0 := A_TickCount
        while (DS.phase = "run" && DS.idx = idx && A_TickCount - t0 < 1000)
            Sleep 10
        if (DS.phase = "run" && DS.idx = idx) {
            FileAppend "FAIL: spell not accepted: " DS.queue[idx] "`n", "*", "UTF-8"
            ExitApp 1
        }
    }
    FileAppend "drill " DS.mode " spells:" DS.queue.Length " mistakes:" DS.mistakes "`n", "*", "UTF-8"
    Sleep InStr(SelfArg, "slow") ? 2500 : 300
    StopBot(T("drillDone"))
}
