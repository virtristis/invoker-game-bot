#Requires AutoHotkey v2.0
#SingleInstance Force
#MaxThreadsBuffer True   ; быстрые повторные нажатия (E E) не теряются
; ==========================================================
;  Invoker Game Bot (AutoHotkey v2)
;  Автор: virtristis — https://github.com/virtristis
;  Лицензия: MIT (см. LICENSE)
;
;  Учебный проект: пример автоматизации через Windows UI Automation.
;  НЕ предназначен для установки рекордов на invoker-game.com.
;  Не связан с invoker-game.com, его автором или Valve.
;
;  Два режима работы:
;   • Бот    — сам проходит тренажёр за заданное время;
;   • Тренер — ничего не нажимает, а показывает поверх игры
;              комбинацию текущего спелла и подсвечивает нажатое.
;  Режимы сайта New (10 спеллов) и Old (27 спеллов) определяются сами.
;  Языки интерфейса: русский, English, Español, 中文.
;
;  Спелл читается со страницы через Windows UI Automation —
;  никаких закладок и расширений не нужно.
; ==========================================================

;@Ahk2Exe-SetName Invoker Game Bot
;@Ahk2Exe-SetDescription Invoker Game Bot (educational)
;@Ahk2Exe-SetVersion 1.8.2
;@Ahk2Exe-SetCompanyName virtristis
;@Ahk2Exe-SetCopyright (c) 2026 virtristis - MIT License
;@Ahk2Exe-SetMainIcon assets\icon.ico

VERSION    := "1.8.2"
AUTHOR     := "virtristis"
AUTHOR_URL := "https://github.com/virtristis"
REPO_URL   := "https://github.com/virtristis/invoker-game-bot"
REPO_API   := "https://api.github.com/repos/virtristis/invoker-game-bot/releases/latest"

#Include "%A_ScriptDir%\lib\spells.ahk"    ; комбинации New / Old
#Include "%A_ScriptDir%\lib\strings.ahk"   ; тексты интерфейса на 4 языках

; ---------------- настройки и файлы ----------------
; всё храним в %APPDATA%\InvokerGameBot, чтобы не мусорить рядом с программой
; (автотесты --selftest пишут во временную папку, чтобы не трогать настоящую статистику)
DataDir   := (A_Args.Length && A_Args[1] = "--selftest") ? A_Temp "\InvokerGameBot-selftest" : A_AppData "\InvokerGameBot"
IniFile   := DataDir "\invoker_bot.ini"
StatsFile := DataDir "\invoker_stats.csv"
SpellFile := DataDir "\invoker_spells.ini"
IconDir   := A_AppData "\InvokerGameBot\icons"   ; иконки спеллов (качаются один раз)
try DirCreate DataDir
try DirCreate IconDir
; файлы от старых версий (лежали рядом с программой) — переносим в новую папку
for name in ["invoker_bot.ini", "invoker_stats.csv", "invoker_spells.ini"]
    if FileExist(A_ScriptDir "\" name) && !FileExist(DataDir "\" name) && !InStr(DataDir, "selftest")
        try FileMove A_ScriptDir "\" name, DataDir "\" name

global Lang      := Cfg("lang", DefaultLang())
global FastMode  := Cfg("fast", 0) = 1
global CoachMode := Cfg("coach", 0) = 1
global DrillMode := !CoachMode && Cfg("drill", 0) = 1   ; своя тренировка без сайта
global DrillGame := Cfg("drill_game", "new") = "old" ? "old" : "new"
global DrillWeak := Cfg("drill_weak", 0) = 1             ; только самые медленные спеллы
global Jitter    := Cfg("jitter", 0) = 1
global Repeat    := Cfg("repeat", 0) = 1
global Sound     := Cfg("sound", 1) = 1
global RunKey    := Cfg("hotkey", "F1")
global Intro     := Cfg("intro", 1) = 1     ; заставка при запуске (intro=0 в ini — выключить)
global Horiz     := Cfg("layout", "v") = "h" ; раскладка окна: v — вертикальная, h — горизонтальная
global HW := 360, GH := 672                  ; текущие ширина / высота окна
if !Strings.Has(Lang)
    Lang := "en"

global Running    := false
global MainHidden := false
global UpdateVer  := "", UpdateUrl := "", UpdateInfo := 0
global CurKeyMap  := Map("q", "q", "w", "w", "e", "e", "r", "r")
global CoachKeys  := Map()                      ; физическая клавиша -> q/w/e/r
global CoachSt    := {orbs: [], combo: "", mode: "new"}
global DrillKeys  := Map()                      ; физическая клавиша -> q/w/e/r (окно тренировки)
global Anims      := Map()                      ; анимации переключателей
global Hover      := {hwnd: 0, part: ""}          ; контрол под мышкой (подсветка)
global CapturingKey := false                    ; ждём новую клавишу старт/стоп
global OV := 0, ovPic := 0                      ; оверлей (окно создаётся после заставки)
global SoundName  := Cfg("sound_name", "chime")       ; какой звук в конце прогона
global SoundFile  := Cfg("sound_file", "")            ; свой WAV / MP3
global SoundVol   := Cfg("sound_vol", "80")           ; громкость 0–100
SoundVol := IsInteger(SoundVol) ? Max(0, Min(100, SoundVol + 0)) : 80
global SW := 0, swPic := 0                         ; окно «Звук»
global OvScale    := Cfg("ov_scale", "1")             ; размер оверлея (0.6–2)
global OvDX      := Cfg("ov_dx", ""), OvDY := Cfg("ov_dy", "")   ; место оверлея от правого верхнего угла игры
OvScale := IsNumber(OvScale) && OvScale >= 0.6 && OvScale <= 2 ? OvScale + 0 : 1
if !IsInteger(OvDX) || !IsInteger(OvDY)
    OvDX := "", OvDY := ""
; состояние тренировки без сайта (окно DW рисуется одной картинкой)
global DS := {phase: "", mode: "new", weak: false, noData: false, loading: false, queue: [], idx: 0, orbs: [],
              startTick: 0, spellTick: 0, endTick: 0, mistakes: 0, missed: false, times: [],
              flash: "", flashTick: 0}
global DW := 0, dwPic := 0
DW_W := 460, DW_H := 370
; запущены после обновления: ждём, пока закроется старая версия, и удаляем её файл
if (A_Args.Length >= 3 && A_Args[1] = "--cleanup") {
    try ProcessWaitClose(Integer(A_Args[3]), 10)
    if (A_Args[2] != A_ScriptFullPath && InStr(A_Args[2], "InvokerGameBot"))
        try FileDelete A_Args[2]
}
global SelfTest   := (A_Args.Length && A_Args[1] = "--selftest")
global SelfArg    := A_Args.Length > 1 ? A_Args[2] : ""

SetTitleMatchMode 2
SendMode "Event"
SetKeyDelay 5, 5

; IUIAutomation2 (CUIAutomation8) — с таймаутами, чтобы не зависать на браузере
UIA := ComObject("{e22ad333-b25f-460c-83d0-0581107395c9}", "{34723aff-0c9d-49d0-9896-7ab52df8cd8a}")
ComCall(61, UIA, "uint", 1000)   ; ConnectionTimeout
ComCall(63, UIA, "uint", 1000)   ; TransactionTimeout
UiaCond  := MakeCondition()
UiaCache := MakeCacheRequest()

; ---------------- GUI (тёмная тема, своя отрисовка) ----------------
; Цветовые темы: акцент, светлый акцент, ссылка, подсветка «следующей» клавиши,
; второе свечение в шапке, верх градиента шапки, цвет текста на акценте
Themes := Map(
    "violet", {accent: "8B5CF6", accent2: "A78BFA", link: "A78BFA", next: "3B3466", glow2: "3B82F6", head: "1C1233", onAccent: "FFFFFF"},
    "blue",   {accent: "3B82F6", accent2: "60A5FA", link: "60A5FA", next: "1E3A5F", glow2: "22D3EE", head: "0E1B33", onAccent: "FFFFFF"},
    "gold",   {accent: "F59E0B", accent2: "FBBF24", link: "FBBF24", next: "4A3410", glow2: "F97316", head: "261A08", onAccent: "1A1205"})
ThemeNames := ["violet", "blue", "gold"]
global Theme := Cfg("theme", "violet")
if !Themes.Has(Theme)
    Theme := "violet"
C := {bg: "0F1117", card: "1A1D27", field: "252936", text: "E6E8EF", muted: "8B90A0", go: "16A34A", stop: "DC2626"}
ApplyThemeColors()
Clickable := Map()      ; hwnd -> true, для курсора-руки

; ---------------- GDI+: рисуем кнопки, переключатели, шапку ----------------
DllCall("LoadLibrary", "str", "gdiplus")
GdipSI := Buffer(24, 0), NumPut("uint", 1, GdipSI)
DllCall("gdiplus\GdiplusStartup", "ptr*", &GdipToken := 0, "ptr", GdipSI, "ptr", 0)
global DPI := A_ScreenDPI / 96
global IconFont := FontExists("Segoe Fluent Icons") ? "Segoe Fluent Icons" : "Segoe MDL2 Assets"

; ---------------- окно ----------------
G := Gui("+AlwaysOnTop -Caption")
G.BackColor := C.bg
G.MarginX := 0, G.MarginY := 0

SectionIcons := []

; шапка: градиент, заголовок, языки, темы, свернуть/закрыть (всё одной картинкой)
; (без SS_NOTIFY картинка «прозрачна» для мыши — клики получает само окно)
hdr := G.Add("Picture", "x0 y0 w360 h92 +0x4000000")
OnMessage(0x84, HeaderHitTest)
OnMessage(0x201, HeaderDown)

lblMode  := SectionLabel(98, 0xE99A)
segMode  := PicBtn("x20 y116 w320 h32", SegModeClick)
lblSpeed := SectionLabel(156, 0xE945)
segSpeed := PicBtn("x20 y174 w320 h32", SegSpeedClick)
timeRow  := PicBtn("x20 y214 w320 h36", TimeRowClick)
G.SetFont("norm s14 c" C.text, "Segoe UI Semibold")
eTime := G.Add("Edit", "x66 y219 w80 h26 Center -E0x200 Background" C.card, Cfg("time", "15"))

lblOpt := SectionLabel(260, 0xE713)
OptRows := Map()
for i, which in ["jitter", "repeat", "sound"] {
    y := 278 + (i - 1) * 28
    G.SetFont("norm s10 c" C.text, "Segoe UI")
    OptRows[which] := [G.Add("Text", "x20 y" y " w" (which = "sound" ? 228 : 260) " h26 0x200 Background" C.bg),
                       PicBtn("x294 y" (y + 1) " w46 h24", Toggle.Bind(which))]
}
bSnd := PicBtn("x254 y335 w32 h24", (*) => ShowSoundWin())     ; выбор звука и громкости
OnMessage(0x201, SoundWinDown)
G.SetFont("norm s10 c" C.text, "Segoe UI")
tHot := G.Add("Text", "x20 y362 w250 h26 0x200 Background" C.bg)
bHot := PicBtn("x284 y363 w56 h24", CaptureHotkey)

lblKeys := SectionLabel(398, 0xE765)
keysRow := G.Add("Picture", "x20 y416 w320 h30 +0x4000000")
KeyEdits := Map()
for i, k in ["q", "w", "e", "r"] {
    G.SetFont("norm s12 c" C.text, "Segoe UI Semibold")
    KeyEdits[k] := G.Add("Edit", "x" (20 + (i - 1) * 80 + 28) " y419 w40 h24 Center Limit1 -E0x200 Background" C.card,
        Cfg("key_" k, k))
}

bMain := PicBtn("x20 y456 w320 h46", (*) => ToggleRun())

statusCard := G.Add("Picture", "x20 y512 w320 h64 +0x4000000")
G.SetFont("norm s10 c" C.text, "Segoe UI")
tStatus := G.Add("Text", "x34 y518 w300 h52 Background" C.card)

bStats := PicBtn("x20 y586 w156 h30", (*) => ShowStats())
bTray  := PicBtn("x184 y586 w156 h30", (*) => ToTray())

; невидимая кнопка забирает фокус, чтобы поле времени не было выделено
bFocus := G.Add("Button", "x0 y0 w0 h0")

; автор и ссылка на GitHub
G.SetFont("norm s9 c" C.muted, "Segoe UI")
tAuthor := G.Add("Text", "x20 y626 w320 Center Background" C.bg)
G.SetFont("norm s10 underline c" C.link, "Segoe UI Semibold")
tLink := G.Add("Text", "x20 y644 w320 Center Background" C.bg, "github.com/" AUTHOR)
tLink.OnEvent("Click", (*) => Run(AUTHOR_URL))
Clickable[tLink.Hwnd] := true

; правая колонка горизонтальной раскладки: [контрол, x, y] для вертикальной
RightCol := [[SectionIcons[4], 20, 397], [lblKeys, 40, 398], [keysRow, 20, 416],
             [bMain, 20, 456], [statusCard, 20, 512], [tStatus, 34, 518],
             [bStats, 20, 586], [bTray, 184, 586], [tAuthor, 20, 626], [tLink, 20, 644]]
for i, k in ["q", "w", "e", "r"]
    RightCol.Push([KeyEdits[k], 20 + (i - 1) * 80 + 28, 419])

ApplyLayout(false)
ApplyLang()
SetAppIcon()

OnMessage(0x20, WM_SETCURSOR)
G.OnEvent("Close", (*) => (SaveCfg(), ExitApp()))
if Intro && !SelfTest
    ShowSplash()
G.Show("w" HW " h" GH)
DllCall("dwmapi\DwmSetWindowAttribute", "ptr", G.Hwnd, "int", 33, "int*", 2, "int", 4)   ; скруглённые углы
PaintBorder()
bFocus.Focus()

; горячая клавиша старт/стоп
try Hotkey(RunKey, ToggleRun)
catch {
    RunKey := "F1"
    Hotkey(RunKey, ToggleRun)
    RenderKeyPill(bHot, RunKey)
}

; ---------------- оверлей (тренер и компактный режим) ----------------
; без WS_EX_TRANSPARENT: оверлей можно таскать мышкой; WS_EX_NOACTIVATE — фокус остаётся у игры
OV := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x08000000")
OV.BackColor := C.card
OV.MarginX := 0, OV.MarginY := 0
ovPic := OV.Add("Picture", "x0 y0 w" Round(272 * OvScale) " h" Round(126 * OvScale))   ; весь оверлей — одна картинка
OV.Show("Hide w" Round(272 * OvScale) " h" Round(126 * OvScale))
OnMessage(0x84, OvHitTest)                          ; перенос — силами Windows (как за заголовок)
OnMessage(0x231, OvEnterMove)
OnMessage(0x232, OvExitMove)
OnMessage(0x216, OvMoving)                          ; за уголок — меняем размер
OnMessage(0x20A, OvWheel)                           ; размер — колесом мыши
; при выходе снимаем обработчики: AutoHotkey очищает переменные раньше, чем закрывает окна
OnExit((*) => (OnMessage(0x84, OvHitTest, 0), OnMessage(0x231, OvEnterMove, 0), OnMessage(0x232, OvExitMove, 0),
    OnMessage(0x216, OvMoving, 0), OnMessage(0x20A, OvWheel, 0),
    OnMessage(0x20, WM_SETCURSOR, 0), OnMessage(0x84, HeaderHitTest, 0), OnMessage(0x201, HeaderDown, 0),
    OnMessage(0x201, SoundWinDown, 0), 0))
OnMessage(0x204, OvMenu)                            ; правый клик — сбросить
DllCall("dwmapi\DwmSetWindowAttribute", "ptr", OV.Hwnd, "int", 33, "int*", 2, "int", 4)  ; скруглённые углы
WinSetTransparent 235, OV
global OvVisible := false, OvState := "", OvPos := "", OvGame := 0, OvLast := 0, OvDragging := false, OvResize := 0, OvLastHit := 0

SetupTray()
SetTimer CheckUpdate, -1500
SetTimer HoverTick, 30                             ; подсветка кнопок при наведении

if SelfTest {
    ; аргументы для автотестов: coach | timed | tray | drill[-old][-weak][-slow]
    ; (можно вместе: "tray-timed")
    DrillMode := InStr(SelfArg, "drill") > 0
    CoachMode := !DrillMode && InStr(SelfArg, "coach") > 0
    FastMode  := !CoachMode && !InStr(SelfArg, "timed")
    if DrillMode
        DrillGame := InStr(SelfArg, "old") ? "old" : "new", DrillWeak := InStr(SelfArg, "weak") > 0
    PaintModes()
    if InStr(SelfArg, "shot-main") {                     ; снимок главного окна и выход
        PaintMain(), ShowHint()
        Sleep 1000                                       ; на скрытом рабочем столе окно дорисовывается дольше
        DllCall("RedrawWindow", "ptr", G.Hwnd, "ptr", 0, "ptr", 0, "uint", 0x185)   ; INVALIDATE|ERASE|ALLCHILDREN|UPDATENOW
        Sleep 200
        try DirCreate A_Temp "\igb-shots"
        SaveWindowShot(G, A_Temp "\igb-shots\main-" SelfArg ".png")
        ExitApp
    }
    if InStr(SelfArg, "shot-hover") {                    ; снимки подсветки и середины анимации
        SetTimer HoverTick, 0
        try DirCreate A_Temp "\igb-shots"
        for i, h in [[segMode, 2], [segSpeed, 1], [timeRow, "plus"], [OptRows["repeat"][2], "on"], [bMain, "on"],
                     [bStats, "on"], [hdr, "close"], [hdr, "lang:ru"]] {
            Hover := {hwnd: h[1].Hwnd, part: h[2]}
            RepaintHover(h[1].Hwnd)
            Sleep 400
            SaveWindowShot(G, A_Temp "\igb-shots\hover-" i ".png")
            Hover := {hwnd: 0, part: ""}
            RepaintHover(h[1].Hwnd)
        }
        Toggle("repeat"), SetMode(3)
        Sleep 70
        SaveWindowShot(G, A_Temp "\igb-shots\anim-mid.png")
        Sleep 300
        SaveWindowShot(G, A_Temp "\igb-shots\anim-end.png")
        ExitApp
    }
    if InStr(SelfArg, "shot-stages") {                   ; оверлей тренера: стадии 0/4 … 4/4 (для README)
        try DirCreate A_Temp "\igb-shots"
        IconsFetch("new")
        OvScale := 1.25
        loop 5
            RenderOverlay("chaos meteor", "wee", A_Index - 1, "NEW  ·  4 / 10  ·  3.8 " T("sec"), "new",
                A_Temp "\igb-shots\stage-" (A_Index - 1) ".png")
        ExitApp
    }
    if InStr(SelfArg, "shot-overlay") {                  ; оверлей в трёх размерах + перетаскивание
        try DirCreate A_Temp "\igb-shots"
        IconsFetch("new"), IconsFetch("old")
        for i, o in [[1, "sun strike", "eee", 2, "new"], [1.5, "disarm", "eqe", 1, "old"], [0.7, "tornado", "qww", 3, "new"]] {
            OvScale := o[1]
            RenderOverlay(o[2], o[3], o[4], StrUpper(o[5]) "  ·  3 / 10  ·  4.2 " T("sec"), o[5], A_Temp "\igb-shots\overlay-" i ".png")
        }
        ; «игра» — само главное окно: показываем, «перетаскиваем», двигаем «игру» — оверлей едет следом
        OvScale := 1, OvDX := "", OvDY := ""
        WinMove 100, 100, , , G
        OverlayShow(G.Hwnd, "emp", "www", 1, "NEW", "new")
        WinGetPos &x1, &y1, , , OV
        WinMove x1 - 50, y1 + 30, , , OV
        OvSavePos()
        WinMove 300, 150, , , G
        OverlayShow(G.Hwnd, "emp", "www", 2, "NEW", "new")
        WinGetPos &x2, &y2, &w2, &h2, OV
        ok := (x2 - x1 = 200 - 50) && (y2 - y1 = 50 + 30)
        OvScale := 1.5, OvApplyScale()
        WinGetPos , , &w3, &h3, OV
        FileAppend "overlay follow " (ok ? "OK" : "FAIL") " dx=" OvDX " dy=" OvDY " size " w2 "x" h2 " -> " w3 "x" h3 "`n", "*", "UTF-8"
        ExitApp ok ? 0 : 1
    }
    if InStr(SelfArg, "shot-sound") {                    ; звуки (без проигрывания) и окно «Звук»
        try DirCreate A_Temp "\igb-shots"
        out := ""
        for name in ["chime", "bell", "arcade", "soft", "invoke"] {
            wav := A_Temp "\igb-shots\sound-" name ".wav"
            t0 := A_TickCount
            MakeTone(wav, SoundPreset(name))
            raw := FileRead(wav, "RAW"), peak := 0
            loop (raw.Size - 44) // 2
                peak := Max(peak, Abs(NumGet(raw, 42 + A_Index * 2, "short")))
            out .= name " " raw.Size " bytes, peak " Round(peak / 327.67) "%, " (A_TickCount - t0) " ms`n"
        }
        FileAppend out, "*", "UTF-8"
        SaveWindowShot(G, A_Temp "\igb-shots\main-sound.png")
        ShowSoundWin()
        Sleep 300
        SaveWindowShot(SW, A_Temp "\igb-shots\sound-win.png")
        ExitApp
    }    if InStr(SelfArg, "update-dry") {                    ; обновление: релиз, загрузка, SHA-256, --cleanup
        try DirCreate A_Temp "\igb-shots\upd"
        info := LatestRelease()
        upd := info ? DownloadVerified(info, A_Temp "\igb-shots\upd") : ""
        abc := Buffer(3), StrPut("abc", abc, 3, "UTF-8")
        shaOk := Sha256(abc, 3) = "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad"
        FileAppend "update latest=" (info ? info.ver : "?") " exe=" (info ? info.exe : "") "`n"
            . "download+sha: " (upd != "" ? "OK " upd : "FAIL") ", sha256(abc): " (shaOk ? "OK" : "FAIL") "`n", "*", "UTF-8"
        ExitApp (upd != "" && shaOk) ? 0 : 1
    }    if InStr(SelfArg, "update-run") {                    ; полный цикл обновления (для проверки)
        CheckUpdate()
        FileAppend "found update: " UpdateVer "`n", "*", "UTF-8"
        DoUpdate()
        ExitApp 1
    }
    if InStr(SelfArg, "shot-intro") {                    ; снимок заставки (для README)
        try DirCreate A_Temp "\igb-shots"
        ShowSplash(A_Temp "\igb-shots\intro.png")
        ExitApp
    }
    if InStr(SelfArg, "shot-stats") {                    ; снимок окна статистики
        ShowStats()
        Sleep 1000
        DllCall("RedrawWindow", "ptr", SG.Hwnd, "ptr", 0, "ptr", 0, "uint", 0x185)
        Sleep 200
        try DirCreate A_Temp "\igb-shots"
        SaveWindowShot(SG, A_Temp "\igb-shots\stats.png")
        ExitApp
    }
    if InStr(SelfArg, "tray")
        ToTray()
    if !DrillMode
        try WinActivate "Invoker-Game"
    StartBot()
    if DrillMode
        SetTimer InStr(SelfArg, "gif") ? DrillGif : InStr(SelfArg, "shots") ? DrillShots : DrillAutoPlay, -400
}

; ======================= заставка =======================

; ======================= функции интерфейса =======================

; ---------- отрисовка элементов ----------

; ---------- шапка: клики ----------

; ---------- состояние ----------

; ---------- анимация переключателей ----------
; Anims: ключ -> {from, to, t0, dur}; значение плавно идёт from -> to (ease-out)

; ---------- подсветка при наведении ----------
; Hover — что под мышкой: hwnd контрола и его часть (номер сегмента, "plus", "lang:ru"…)

; ---------------- трей ----------------

; ---------------- проверка обновлений ----------------

; ---------------- оверлей ----------------
; цвета клавиш как у шаров: Quas — голубой, Wex — фиолетовый, Exort — жёлто-оранжевый, R (Invoke) — белый

; ---------- оверлей: перетаскивание и размер ----------
; Тянешь за любое место — двигаешь, за правый нижний уголок — меняешь размер (60–200 %).
; Правый клик — меню «сбросить». Окно не забирает фокус у игры (WS_EX_NOACTIVATE).

; ---------------- статистика ----------------

; ---------- график прогресса ----------

; ---------- звук: выбор и громкость ----------

; ======================= старт / стоп =======================

; ---------- чтение страницы через UI Automation ----------

; ======================= режим бота =======================

; ======================= режим тренера =======================

; ======================= логика комбинаций (без интерфейса) =======================

; ======================= тренировка без сайта =======================
; Программа сама показывает спелл, ты собираешь шары и жмёшь R, она засекает время.
; Время каждого спелла пишется в ту же статистику, что и у тренера.

; ======================= иконки спеллов =======================
; New — официальные иконки Dota 2 с CDN Valve (PNG 128×128).
; Old — иконки с invoker-game.com. В репозитории их нет: программа качает их
; один раз в %APPDATA%\InvokerGameBot\icons. Без сети просто рисуем шары сами.
; WebP открываем через Windows Imaging Component — GDI+ его не умеет.

; ======================= модули (только функции) =======================
#Include "%A_ScriptDir%\lib\ui.ahk"
#Include "%A_ScriptDir%\lib\logic.ahk"
#Include "%A_ScriptDir%\lib\gdip.ahk"
#Include "%A_ScriptDir%\lib\icons.ahk"
#Include "%A_ScriptDir%\lib\update.ahk"
#Include "%A_ScriptDir%\lib\sound.ahk"
#Include "%A_ScriptDir%\lib\overlay.ahk"
#Include "%A_ScriptDir%\lib\stats.ahk"
#Include "%A_ScriptDir%\lib\drill.ahk"
#Include "%A_ScriptDir%\lib\game.ahk"
