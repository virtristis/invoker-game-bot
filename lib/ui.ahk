; Invoker Game Bot — Главное окно: шапка, переключатели, наведение и анимация, заставка, трей, настройки.
; Часть invoker_bot.ahk (подключается через #Include), сам по себе не запускается.

DefaultLang() {
    switch SubStr(A_Language, -2) {   ; основной язык Windows
        case "19": return "ru"
        case "0A": return "es"
        case "04": return "zh"
        default:   return "en"
    }
}

Cfg(key, def) => IniRead(IniFile, "settings", key, def)

T(key) => Strings[Lang][key]

Tf(key, arg) => StrReplace(T(key), "{}", arg)

ApplyThemeColors() {
    th := Themes[Theme]
    for k in ["accent", "accent2", "link", "next", "glow2", "head", "onAccent"]
        C.%k% := th.%k%
}

PicBtn(opts, fn) {
    p := G.Add("Picture", opts " +0x4000000")     ; WS_CLIPSIBLINGS — не закрашивать поля поверх
    p.OnEvent("Click", fn), p.OnEvent("DoubleClick", fn)
    Clickable[p.Hwnd] := true
    return p
}

SectionLabel(y, icon) {
    G.SetFont("norm s10 c" C.accent, IconFont)
    ic := G.Add("Text", "x20 y" (y - 1) " w18 h18 Background" C.bg, Chr(icon))
    SectionIcons.Push(ic)
    G.SetFont("norm s8 bold c" C.muted, "Segoe UI")
    return G.Add("Text", "x40 y" y " w280 h16 Background" C.bg)
}

; Портрет Инвокера точками Брайля (2×4 точки на символ), 96×24 символов
InvokerArt() {
    return "
(
⠀⠀⠀⠀⠀⠀⠀⢠⠞⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⠤⠪⠕⡋⡡⣐⢔⢬⢒⢁⢂⣐⠜⢈⢐⠠⡰⡸⣰⠯⠒⢢⣍⢻⣝⢿⢿⣷⣤⡂⢐⠠⠀⠄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡄⠀
⠀⠀⠀⠀⠄⠂⢁⡞⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⡴⢃⢕⢝⢜⢔⡷⣕⢯⣣⢧⡳⣕⢅⢆⢢⢃⢼⢼⡾⠋⣀⢀⢄⢘⠦⢻⣆⡿⣿⡿⡿⣆⢐⠀⠂⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡘⡌⢆
⠀⠀⠄⠈⠀⠀⣺⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡔⠕⡐⣔⢇⢧⢃⢟⢭⡯⡻⡨⣚⣼⡟⢕⢌⢣⣷⣻⠏⡀⡌⡆⡣⡱⡱⡱⣭⣺⣟⣁⠀⠻⣿⣧⠠⠁⡈⠠⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡘⢜
⠀⠀⠀⠀⠀⠂⡏⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⡜⠜⢕⠕⡡⡣⠣⣕⢽⢕⠕⢡⢎⠼⣑⡼⡝⣜⣽⡿⠁⡐⡌⡆⣇⢣⢣⠱⡱⣹⣿⣿⣿⣷⡀⢻⣿⣧⡂⡐⠀⠂⠐⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠠⠐⡁
⠀⠀⠀⠀⠐⠀⡧⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⢚⠀⢅⠣⡸⠈⡔⡝⢜⢌⠆⠠⣃⣪⣲⡿⣽⡪⣯⠟⠀⠔⠕⠑⠱⢱⣕⣮⢪⢪⣮⢿⣿⣿⣿⣷⠀⢻⣿⡗⢀⠁⡈⢀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠠⢐⠀⠁⠐
⠀⠀⠀⠀⠈⠄⣫⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠌⠀⠄⠕⠀⡠⡪⠊⠨⠂⠂⣰⣼⢾⡾⢟⢋⣯⣾⠋⠀⡠⠢⡂⡂⠀⠀⠈⠺⢷⣵⢙⣿⡟⣿⣿⣿⣇⠩⣿⣿⣀⠐⢀⠀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡀⠀⠀⠀⡠⠀⠀⠀⠀⠀⠀⠀⢈⢢⠁⠀⠀
⠀⠀⠀⠀⠀⠅⠸⡆⠀⠀⠀⠀⠀⠀⠀⠀⠀⡈⠀⠀⠨⠈⠀⠊⠀⡠⠥⢖⠟⠟⠋⡉⣢⣃⣾⡿⠁⠀⠔⡀⠁⢀⣤⣬⣤⡀⠀⠐⠉⣳⠟⣇⢿⣿⣿⣿⡄⢽⣿⣧⡨⠀⠄⠄⠐⠀⠀⠀⠀⠀⢀⠀⢀⠠⢀⢔⠰⣑⢅⡂⢔⢠⣺⠁⠀⠀⠀⠀⠀⠀⠀⢀⠢⠁⡢⠀
⠀⠀⢀⠀⠀⠈⠄⢽⡀⠈⠨⠐⠐⠠⠀⠂⠌⠀⠃⠋⠊⠒⠱⢤⠁⠁⠁⠀⢠⠂⣨⢣⣷⣿⠟⠁⠠⡨⡪⡪⣢⢂⠌⣛⢿⠳⠀⢀⠀⠠⡲⣾⠉⠉⠘⣻⣿⢊⢿⣿⡗⢈⠀⠂⠀⠄⠐⠀⡀⢁⠠⠐⢀⢰⢅⢆⡣⣞⢜⢜⢜⣽⠃⠀⠀⠀⠀⠀⠀⠀⠂⡁⠌⡀⢎⠂
⠀⠀⡐⡀⠀⠀⢁⠢⡻⡀⠀⠀⠀⠀⠀⠀⡁⠐⠈⠄⡀⢀⠀⠀⠈⢂⠀⢐⡕⡔⣕⣿⡻⡣⠂⠀⠌⡪⢮⡫⣗⡯⣾⢴⢔⢕⢠⢠⢑⢕⠸⡺⣷⢶⣮⠠⠃⠘⡼⣿⣿⡄⠐⠈⠀⡀⠄⠂⡀⡂⠄⠂⠕⣅⢦⣳⣿⣽⣷⣽⣾⠃⠀⠀⠀⠀⠀⠀⠀⡀⢀⠂⠌⠨⢪⢱
⠀⠀⡆⡇⠀⠀⠀⠂⢕⢳⡀⠀⠀⠀⠀⠀⢀⠔⠀⠁⠄⢰⠁⠁⠀⠀⢄⢗⢕⢕⡽⣋⢺⡍⠀⠀⠀⠂⠂⢕⢑⢝⢺⡫⣇⢇⡇⡎⠆⠆⡃⢇⢿⡹⣷⡅⠀⠐⣇⣿⣿⡙⣦⠀⠂⠀⠀⢂⠐⠠⠊⡌⣎⣖⣽⣿⣿⣿⣿⣿⠃⠀⠀⠀⠀⠀⠀⠀⠀⠂⠀⠐⠀⠁⠁⢑
⠀⢘⢜⡆⠀⠀⠀⠀⠂⢳⢱⢄⠀⠀⠀⠀⠂⠐⠀⠀⠐⡐⠢⠀⠀⠨⡺⡪⠊⡬⡶⠁⢸⠅⠀⠀⡀⠈⡈⠄⠢⡑⡕⣝⢼⢱⢕⠅⢕⠱⠘⠨⢚⢿⣿⣷⠀⠀⡳⣹⣿⣇⠈⣇⢀⠡⠈⠀⡀⡎⢌⢜⣾⣿⣿⣿⣿⣿⠏⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⡺⡸⡅⠀⠀⠀⠀⠀⠂⡣⡫⣢⠀⠀⠀⠈⠀⢀⠐⠀⠀⠂⢀⠁⢠⠋⡠⣪⠟⠁⠀⣽⠁⠀⢐⢐⠡⡐⠨⢂⢪⢊⢎⢮⢪⡳⡱⡠⡠⡐⣰⣐⣽⣿⣿⠁⠄⡪⣊⣿⣿⣀⣸⣀⣀⣠⢸⢸⢸⢜⣾⣿⣿⠿⡛⠋⠁⠀⣠⠐⠀⠁⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⣣⢣⠃⠀⠀⠀⠀⠀⠀⠘⢜⢔⡳⣀⠀⠀⠀⠠⠨⠀⠀⠀⠀⠈⠌⣜⢼⠱⠀⢌⢤⣿⠀⢀⢂⢕⢑⠌⢌⠢⠡⡃⡇⡇⢇⢇⢇⠇⠧⢿⣽⣿⣿⣿⠃⠀⡅⣻⣷⢹⡻⣏⠈⠊⠊⠊⠊⠊⠊⠋⠋⠑⠁⠁⠈⡈⣨⡼⠃⠀⠈⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⣳⢱⠅⠀⠀⠀⠀⠀⠀⠀⠈⠸⣘⠬⡲⡀⠀⠀⠁⠀⠀⠀⠀⠠⠡⡳⡹⡈⠀⡔⢽⣏⠀⠀⢆⠢⡡⡑⡐⡡⢑⢅⢃⢄⣈⢠⢀⢤⣬⡄⠍⢿⣿⠇⠀⠄⡂⣽⣿⣸⡃⢹⠂⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡠⣮⡾⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⡆⠀⠀⠀⠀⠈⠐
⠀⠸⡌⣇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠪⡪⡍⡧⡄⠀⢀⠁⠀⠀⠄⡪⡪⢘⠀⢐⢘⢽⡧⠀⠈⠐⡐⡐⢌⢂⢂⢂⠪⡘⡌⢎⠪⡊⢄⠙⠝⣿⣼⡿⠀⠨⡀⢒⢼⣿⣿⠀⡼⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⢪⡾⠋⠀⠀⠠⠐⠈⠀⠀⠀⠀⣠⢴⡿⠀⠀⠀⠀⠀⠀⠀
⢄⡸⡜⡺⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⢇⢇⢍⢗⣄⠀⠀⠨⠨⠪⠀⠀⠌⠄⡸⣸⡇⠀⠀⠀⠀⠈⠢⢑⢐⠔⡑⢬⢨⢢⠣⡊⣢⣷⣵⣿⣿⠃⠀⢨⠂⢸⢽⣿⣇⠞⠁⠀⠀⠀⠀⠀⠀⠀⠀⡠⣴⣷⡟⠁⠀⠀⡁⠠⠀⠄⣐⣨⢴⣿⣿⡿⠁⠀⠀⠀⠀⠀⠀⠀
⢸⣸⢪⢪⢫⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠁⠳⣕⢺⣳⣄⠀⠁⡁⠀⠀⠘⡐⢔⢹⡇⠂⠀⠀⠀⠀⠀⠀⠀⠂⠡⠑⢕⢜⢜⢜⢼⣿⣿⣿⡏⠀⠀⢐⠅⢸⣿⣿⠏⠀⠀⠀⠀⠀⠀⠀⢀⠔⣱⣾⠟⠙⢢⢢⣒⣦⠦⠖⠊⠋⠁⣠⣾⣿⡿⠁⠀⡀⠀⠀⠀⠀⠀⠀
⠙⠿⣮⡪⣪⢦⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⢫⡺⡸⡵⣄⠀⠀⠀⠀⠅⠥⢹⡇⠀⠄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠐⠈⠐⠅⠝⡘⢿⣿⠂⠀⠀⠠⣃⣿⣿⣿⠀⠀⠀⠀⠀⠀⡀⡔⣕⠾⠋⠑⠐⠘⠑⠁⠁⠀⠀⠀⢀⣤⣾⣿⣿⠟⠀⠠⢀⠀⠐⠀⠀⡀⡀⡂
⠀⠀⠈⠻⣾⣕⢇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠯⡯⡿⣷⡄⠐⠀⠈⡊⢸⡇⠀⠀⠀⠀⠀⠀⢀⠀⠀⠀⠀⠀⠀⠀⠀⠁⠀⠉⠁⠀⠀⡂⠸⢫⣿⣿⡟⠀⠀⠀⠀⡐⡔⠜⠈⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣠⣴⣿⣿⣿⡟⠁⠄⢁⠐⢀⠈⠄⢂⠡⣀⠨⡀
⠀⠀⠀⠀⠈⢷⡹⣆⠀⢄⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⢯⣷⣻⣄⠀⠀⠐⢘⣗⠀⠀⠂⠀⠀⠀⡀⠀⠀⠀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠠⠀⢨⣿⣿⣿⡇⠀⠀⢀⠆⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⣴⣾⣿⣿⣿⠟⡃⡐⠨⢐⠠⠂⠠⢈⠐⠠⠣⢨⢣⠂
⠀⠀⠀⠀⠀⠀⠙⡾⠷⠰⠪⠍⢆⠤⡀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠳⣗⣿⣧⠀⠈⡘⣿⠀⠀⠀⠀⠀⠀⠀⠀⢠⠊⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡠⣠⢿⠏⣼⣿⡇⠀⠀⠁⠀⠀⠀⠀⠀⠀⠀⠀⣀⣠⣶⣿⣿⣿⣿⠿⡋⡅⡌⢄⢂⢅⠢⡈⡂⡑⡐⠡⢁⠊⡀⠂⠄
⠀⠀⠀⠀⠀⠀⠀⠁⠀⠀⠀⠀⠀⠈⠐⡐⡐⠄⠄⡀⠀⠀⠀⠀⠀⠀⠈⢿⣿⣷⠀⠨⣻⡈⠄⠀⠀⠀⠠⠐⠀⠜⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⢐⢘⠞⠉⡤⣿⣿⠂⠀⠀⠀⠀⠀⠀⠀⠤⣶⣶⣿⣿⣿⣿⡿⢟⣫⣵⣕⡕⢌⢎⢢⢱⠐⢅⢂⠆⠢⠨⠈⠄⠂⡀⠁⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠁⠃⠂⡂⢀⠀⠀⠀⠀⠀⠀⠻⣿⣧⠈⢜⢆⠈⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠠⠀⢰⠫⠀⠀⢸⣿⡏⠀⠀⠀⠀⠀⠀⢀⢰⢣⢲⣼⡿⠟⡋⣴⣾⣿⣿⣿⣿⣿⣷⣥⣊⠔⠡⠑⠔⡁⠅⠈⡀⠈⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠠⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠁⠪⡠⡀⠀⠀⠀⠀⠻⣿⣧⠈⢧⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠁⠀⠠⠀⠀⢀⣽⣿⠀⠀⠀⠀⠀⠀⡠⡪⢢⡷⢟⠝⢈⠔⡱⣹⢿⡿⣿⣿⣿⣿⣿⣿⡿⣿⡿⣷⣶⣦⣦⣥⢤⣤⣤⢤⠤⡤
)"
}

; «консоль», в которой точками прорисовывается Инвокер; клик или Esc — пропустить
ShowSplash(shotFile := "") {
    global SplashSkip := false
    lines := StrSplit(InvokerArt(), "`n", "`r")
    rows := lines.Length, cols := StrLen(lines[1])
    bg := "0A0A12"

    S := Gui("-Caption +AlwaysOnTop +ToolWindow")
    S.BackColor := bg
    S.MarginX := 22, S.MarginY := 16
    S.SetFont("norm s9 c" C.muted, "Consolas")
    S.Add("Text", "xm ym Background" bg, "C:\> InvokerGameBot.exe")
    rowCtl := []
    for i, ln in lines {
        S.SetFont("norm s7 c" LerpColor(0xA78BFA, 0xFBBF24, (i - 1) / Max(1, rows - 1)), "Segoe UI Symbol")
        rowCtl.Push(S.Add("Text", "xm y" (i = 1 ? "+10" : "+0") " Background" bg, ln))
    }
    S.SetFont("norm s14 bold cFBBF24", "Consolas")
    tTitleS := S.Add("Text", "xm y+14 w640 Background" bg)
    S.SetFont("norm s9 c" C.muted, "Consolas")
    info := []
    loop 3
        info.Push(S.Add("Text", "xm y+2 w640 Background" bg))
    S.SetFont("norm s9 c" C.link, "Consolas")
    tBy := S.Add("Text", "xm y+8 w640 Background" bg)

    ; сначала всё пустое: строки из «пустых» символов Брайля той же ширины
    blank := StrReplace(Format("{:" cols "}", ""), " ", Chr(0x2800))
    for ctl in rowCtl
        ctl.Text := blank
    S.OnEvent("Escape", SplashClick)
    OnMessage(0x201, SplashClick)
    S.Show("Center AutoSize")
    DllCall("dwmapi\DwmSetWindowAttribute", "ptr", S.Hwnd, "int", 33, "int*", 2, "int", 4)

    ; 1) портрет проявляется по диагонали, впереди «курсор» ⣿
    shown := []
    loop rows
        shown.Push(-1)
    step := 0
    while !SplashSkip && step <= cols + rows * 2 {
        for i, ctl in rowCtl {
            n := Min(cols, Max(0, step - (i - 1) * 2))
            if (n != shown[i]) {
                ctl.Text := SubStr(lines[i], 1, n) (n < cols && n > 0 ? Chr(0x28FF) : "")
                shown[i] := n
            }
        }
        step += 2
        Sleep 16
    }
    for i, ctl in rowCtl
        ctl.Text := lines[i]

    ; 2) строки «загрузки» печатаются как в терминале
    msgs := [[tTitleS, "INVOKER BOT  v" VERSION],
             [info[1], "> reading the page via UI Automation ....... ok"],
             [info[2], "> spells loaded: New 10 · Old 27 ........... ok"],
             [info[3], "> quas · wex · exort ........................ ready"],
             [tBy,     "made by " AUTHOR "  ·  github.com/" AUTHOR]]
    for m in msgs {
        txt := m[2]
        if SplashSkip {
            m[1].Text := txt
            continue
        }
        loop StrLen(txt) {
            m[1].Text := SubStr(txt, 1, A_Index) "▌"
            if Mod(A_Index, 2) = 0
                Sleep 8
        }
        m[1].Text := txt
        Sleep 60
    }
    if !SplashSkip
        Sleep 700

    if (shotFile != "")                             ; автотест: снимок заставки
        SaveWindowShot(S, shotFile)
    ; 3) плавно гаснем
    loop 10 {
        WinSetTransparent 255 - A_Index * 25, S
        Sleep 18
    }
    OnMessage(0x201, SplashClick, 0)
    S.Destroy()
}

SplashClick(*) {
    global SplashSkip := true
}

WM_SETCURSOR(wParam, *) {
    if Clickable.Has(wParam) {
        DllCall("SetCursor", "ptr", DllCall("LoadCursor", "ptr", 0, "ptr", 32649, "ptr"))
        return true
    }
    ; оверлей: в уголке — «размер», иначе — «двигать» (OV создаётся позже заставки — проверяем)
    if IsSet(OV) && OV && (wParam = OV.Hwnd || wParam = ovPic.Hwnd) {
        CoordMode "Mouse", "Screen"
        MouseGetPos &mx, &my
        DllCall("SetCursor", "ptr", DllCall("LoadCursor", "ptr", 0, "ptr", OvInCorner(mx, my) ? 32642 : 32646, "ptr"))
        return true
    }
}

; позиция мыши относительно контрола, в логических пикселях
MouseRel(ctl, &mx, &my) {
    pt := Buffer(8)
    DllCall("GetCursorPos", "ptr", pt)
    DllCall("ScreenToClient", "ptr", ctl.Hwnd, "ptr", pt)
    mx := NumGet(pt, 0, "int") / DPI, my := NumGet(pt, 4, "int") / DPI
}

; правые элементы шапки привязаны к правому краю: R — сдвиг относительно ширины 360
RenderHeader() {
    R := HW - 360
    cv := CvNew(HW, 92, C.bg)
    br := Linear(0, 0, 0, 92, C.head, C.bg)
    DllCall("gdiplus\GdipFillRectangle", "ptr", cv.g, "ptr", br, "float", 0, "float", 0, "float", HW, "float", 92)
    DllCall("gdiplus\GdipDeleteBrush", "ptr", br)
    Glow(cv, 40, 0, 150, C.accent, 120)
    Glow(cv, 330 + R, 18, 110, C.glow2, 60)
    if Horiz
        Glow(cv, HW / 2, 10, 160, C.accent, 50)

    hv := Hover.hwnd = hdr.Hwnd ? Hover.part : ""      ; что в шапке под мышкой
    ; языки
    for i, lbl in LangLabels {
        x := 16 + (i - 1) * 30, on := (LangCodes[i] = Lang), h := !on && hv = "lang:" LangCodes[i]
        RRect(cv, x, 10, 26, 20, 6, Solid(on ? C.accent : h ? C.field : C.card, on || h ? 255 : 210))
        Txt(cv, lbl, x, 10, 26, 20, "Segoe UI Semibold", 11, 0, on ? C.onAccent : h ? C.text : C.muted)
    }
    ; темы
    for i, name in ThemeNames {
        cx := 206 + R + (i - 1) * 18
        if (name = Theme)
            Circle(cv, cx, 20, 8.5, Solid("FFFFFF", 220))
        else if (hv = "theme:" name)
            Circle(cv, cx, 20, 8.5, Solid("FFFFFF", 90))
        Circle(cv, cx, 20, 6, Solid(Themes[name].accent))
    }
    ; раскладка / свернуть / закрыть (закрыть при наведении — красная, как в Windows)
    for i, spot in ["layout", "min", "close"] {
        x := 220 + R + i * 34
        if (hv = spot)
            RRect(cv, x, 6, 28, 26, 7, spot = "close" ? Solid("E81123") : Solid("FFFFFF", 40))
        else
            RRect(cv, x, 6, 28, 26, 7, Solid("FFFFFF", 14))
    }
    Txt(cv, Horiz ? "⇅" : "⇆", 254 + R, 5, 28, 26, "Segoe UI Symbol", 14, 0, C.text, 1, hv = "layout" ? 255 : 220)
    Txt(cv, Chr(0xE921), 288 + R, 6, 28, 26, IconFont, 11, 0, C.text, 1, hv = "min" ? 255 : 220)
    Txt(cv, Chr(0xE8BB), 322 + R, 6, 28, 26, IconFont, 11, 0, hv = "close" ? "FFFFFF" : C.text, 1, hv = "close" ? 255 : 220)

    TitleText(cv, "INVOKER BOT", 15, 30, 245, 38, "Georgia", 27)
    if (UpdateVer != "")
        Txt(cv, Tf("update", UpdateVer), 19, 67, 240, 18, "Segoe UI Semibold", 11.5, 4, C.link, 0)
    else
        Txt(cv, T("subtitle"), 19, 67, 240, 18, "Segoe UI", 11.5, 0, C.muted, 0)

    ; Quas / Wex / Exort
    for i, col in ["38BDF8", "C084FC", "FB923C"] {
        cx := 266 + R + (i - 1) * 30
        Glow(cv, cx, 56, 26, col, 150)
        Orb(cv, cx, 56, 11, col)
    }
    br := Linear(20, 0, HW - 20, 0, C.accent, C.bg, 170, 0)
    DllCall("gdiplus\GdipFillRectangle", "ptr", cv.g, "ptr", br, "float", 20, "float", 91, "float", HW - 40, "float", 1)
    DllCall("gdiplus\GdipDeleteBrush", "ptr", br)
    CvToPic(cv, hdr)
}

; вертикальная (360×672) или горизонтальная (720×404) раскладка: правая колонка
; переезжает вправо-вверх, левая остаётся на месте
ApplyLayout(redraw := true) {
    global HW, GH
    HW := Horiz ? 720 : 360, GH := Horiz ? 404 : 672
    dx := Horiz ? 360 : 0, dy := Horiz ? -300 : 0
    hdr.Move(0, 0, HW, 92)
    for it in RightCol
        it[1].Move(it[2] + dx, it[3] + dy)
    if redraw {
        RenderHeader()
        G.Show("w" HW " h" GH)
        WinRedraw(G)
    }
}

ToggleLayout() {
    global Horiz
    Horiz := !Horiz
    ApplyLayout()
    SaveCfg()
}

; сегментированный переключатель на 2–3 части; sel: номер выбранной, dim — неактивен,
; key — имя анимации: подсветка выбранного плавно переезжает на новое место
RenderSeg(pic, items, sel, dim := false, key := "") {
    sw := 320 / items.Length
    pos := key != "" ? AnimVal(key, sel) : sel
    cv := CvNew(320, 32, C.bg)
    RRect(cv, 0, 0, 320, 32, 9, Solid(C.card))
    if !dim
        RRect(cv, (pos - 1) * sw + 3, 3, sw - 6, 26, 7, Linear(0, 3, 0, 29, C.accent2, C.accent))
    for i, it in items {
        on := !dim && Abs(pos - i) < 0.5
        hov := !dim && !on && IsHover(pic, i)
        if hov
            RRect(cv, (i - 1) * sw + 3, 3, sw - 6, 26, 7, Solid("FFFFFF", 14))
        IconText(cv, it[1], it[2], (i - 1) * sw, 0, sw, 32, items.Length > 2 ? 11.5 : 12.5,
            on ? C.onAccent : hov ? C.text : C.muted)
    }
    CvToPic(cv, pic)
}

; переключатель на холсте: p — положение 0..1 (для анимации), hov — под мышкой
DrawSwitch(cv, x, y, p, hov) {
    RRect(cv, x, y, 46, 24, 12, Solid(hov ? "2E3344" : C.field))
    if (p > 0.01)
        RRect(cv, x, y, 46, 24, 12, Linear(x, 0, x + 46, 0, C.accent2, C.accent, Round(255 * p), Round(255 * p)))
    kx := x + 12 + 22 * p
    if hov
        Circle(cv, kx, y + 12, 11.5, Solid("FFFFFF", 45))
    Circle(cv, kx, y + 12, 8.5, Solid(LerpColor(Integer("0x" C.muted), 0xFFFFFF, p)))
}

RenderTimeRow() {
    if DrillMode {                     ; в тренировке здесь переключатель «только слабые»
        cv := CvNew(320, 36, C.bg)
        RRect(cv, 0, 0, 320, 36, 9, Solid(IsHover(timeRow) ? "21242F" : C.card))
        Txt(cv, Chr(0xE7BA), 12, 0, 18, 36, IconFont, 12, 0, C.accent, 0)
        Txt(cv, T("weakOnly"), 36, 0, 220, 36, "Segoe UI", 12, 0, C.text, 0)
        DrawSwitch(cv, 264, 6, AnimVal("sw:weak", DrillWeak ? 1 : 0), IsHover(timeRow))
        CvToPic(cv, timeRow)
        TimeEditState("hidden")
        return
    }
    dim := FastMode || CoachMode
    col := dim ? C.muted : C.text
    cv := CvNew(320, 36, C.bg)
    RRect(cv, 0, 0, 36, 36, 9, Solid(!dim && IsHover(timeRow, "minus") ? C.field : C.card))
    Txt(cv, "−", 0, 0, 36, 34, "Segoe UI Semibold", 18, 0, col)
    RRect(cv, 40, 0, 92, 36, 9, Solid(C.card))
    RRect(cv, 136, 0, 36, 36, 9, Solid(!dim && IsHover(timeRow, "plus") ? C.field : C.card))
    Txt(cv, "+", 136, 0, 36, 34, "Segoe UI Semibold", 18, 0, col)
    Txt(cv, Chr(0xE916), 182, 0, 18, 36, IconFont, 12, 0, dim ? C.muted : C.accent, 0)
    Txt(cv, T("perGame"), 204, 0, 116, 36, "Segoe UI", 12, 0, C.muted, 0)
    CvToPic(cv, timeRow)
    TimeEditState(dim ? "dim" : "on")
}

; поле времени трогаем только когда его вид правда меняется (иначе окно мерцает при наведении)
TimeEditState(st) {
    static last := ""
    if (st = last && st != "")
        return
    last := st
    eTime.Visible := st != "hidden"
    if (st != "hidden")
        eTime.SetFont("c" (st = "dim" ? C.muted : C.text)), eTime.Opt(st = "dim" ? "+ReadOnly" : "-ReadOnly")
}

RenderSwitch(pic, key, on) {
    cv := CvNew(46, 24, C.bg)
    DrawSwitch(cv, 0, 0, AnimVal(key, on ? 1 : 0), IsHover(pic))
    CvToPic(cv, pic)
}

RenderKeyPill(pic, str) {
    cv := CvNew(56, 24, C.bg)
    RRect(cv, 0, 0, 56, 24, 7, Solid(IsHover(pic) ? "353A4A" : C.field))
    Txt(cv, str, 0, 0, 56, 24, "Segoe UI Semibold", 12, 0, C.text)
    CvToPic(cv, pic)
}

RenderKeysRow() {
    cv := CvNew(320, 30, C.bg)
    for i, k in ["q", "w", "e", "r"] {
        x0 := (i - 1) * 80
        Txt(cv, StrUpper(k), x0, 0, 20, 30, "Segoe UI", 13, 1, C.muted, 0)
        RRect(cv, x0 + 22, 0, 52, 30, 8, Solid(C.card))
    }
    CvToPic(cv, keysRow)
}

RenderMain() {
    hov := IsHover(bMain)                              ; при наведении кнопка светлеет
    c1 := Running ? (hov ? "F87171" : "EF4444") : (hov ? "4ADE80" : "22C55E")
    c2 := Running ? (hov ? "DC2626" : "B91C1C") : (hov ? "16A34A" : "15803D")
    cv := CvNew(320, 46, C.bg)
    RRect(cv, 0, 0, 320, 46, 12, Linear(0, 0, 0, 46, c1, c2))
    RRect(cv, 2, 1, 316, 20, 11, Solid("FFFFFF", 26))
    label := RegExReplace(Running ? T("stop") : (CoachMode ? T("startCoach") : DrillMode ? T("startDrill") : T("start")), "^[▶■]\s*")
    IconText(cv, Running ? 0xE71A : 0xE768, label, 0, 0, 260, 46, 15, "FFFFFF")
    RRect(cv, 258, 12, 50, 22, 6, Solid("000000", 55))
    Txt(cv, RunKey, 258, 12, 50, 22, "Segoe UI Semibold", 11, 0, "FFFFFF")
    CvToPic(cv, bMain)
}

RenderCard() {
    cv := CvNew(320, 64, C.bg)
    RRect(cv, 0, 0, 320, 64, 12, Solid(C.card))
    RRect(cv, 0, 12, 3, 40, 1.5, Solid(C.accent))
    CvToPic(cv, statusCard)
}

RenderFooterBtn(pic, icon, str) {
    cv := CvNew(156, 30, C.bg)
    RRect(cv, 0, 0, 156, 30, 8, Solid(IsHover(pic) ? C.field : C.card))
    IconText(cv, icon, str, 0, 0, 156, 30, 11.5, C.text, C.accent)
    CvToPic(cv, pic)
}

; иконка программы: три шара (окно, трей)
SetAppIcon() {
    if A_IsCompiled                     ; у exe иконка уже вшита (assets\icon.ico)
        return
    ico := A_ScriptDir "\assets\icon.ico"
    if FileExist(ico) {
        TraySetIcon(ico)
        SendMessage(0x80, 0, LoadPicture(ico, "w16 h16", &imgType), , G)
        SendMessage(0x80, 1, LoadPicture(ico, "w32 h32", &imgType), , G)
        return
    }
    ; запасной вариант: рисуем шары сами
    cv := CvNew(64 / DPI, 64 / DPI, "0F1117")
    s := 1 / DPI
    for i, col in ["38BDF8", "C084FC", "FB923C"] {
        cx := (12 + (i - 1) * 20) * s, cy := (i = 2 ? 22 : 40) * s
        Glow(cv, cx, cy, 16 * s, col, 160)
        Orb(cv, cx, cy, 10 * s, col)
    }
    DllCall("gdiplus\GdipCreateHICONFromBitmap", "ptr", cv.bmp, "ptr*", &hIcon := 0)
    DllCall("gdiplus\GdipDeleteGraphics", "ptr", cv.g), DllCall("gdiplus\GdipDisposeImage", "ptr", cv.bmp)
    TraySetIcon("HICON:" hIcon)
    SendMessage(0x80, 0, hIcon, , G)     ; WM_SETICON (малый)
    SendMessage(0x80, 1, hIcon, , G)     ; WM_SETICON (большой)
}

PaintBorder() {
    rgb := Integer("0x" C.accent)
    bgr := ((rgb & 0xFF) << 16) | (rgb & 0xFF00) | ((rgb >> 16) & 0xFF)
    DllCall("dwmapi\DwmSetWindowAttribute", "ptr", G.Hwnd, "int", 34, "uint*", bgr, "int", 4)
}

RenderAll() {
    RenderHeader()
    PaintModes()
    PaintToggles()
    RenderKeyPill(bHot, RunKey)
    RenderSoundPill()
    RenderKeysRow()
    RenderMain()
    RenderCard()
    RenderFooterBtn(bStats, 0xE9D2, T("stats"))
    RenderFooterBtn(bTray, 0xE90C, T("tray"))
    for ic in SectionIcons
        ic.SetFont("c" C.accent)
    tLink.SetFont("c" C.link)
}

; что находится в точке шапки (логические координаты):
; "lang:ru", "theme:blue", "layout", "min", "close", "update" или ""
HeaderSpot(x, y) {
    R := HW - 360
    if (y >= 92)
        return ""
    if (y >= 8 && y <= 32) {
        for i, code in LangCodes
            if (x >= 16 + (i - 1) * 30 && x <= 42 + (i - 1) * 30)
                return "lang:" code
        for i, name in ThemeNames
            if (Abs(x - (206 + R + (i - 1) * 18)) <= 9)
                return "theme:" name
    }
    if (y <= 36 && x >= 252 + R && x < 284 + R)
        return "layout"
    if (y <= 36 && x >= 286 + R && x < 318 + R)
        return "min"
    if (y <= 36 && x >= 318 + R)
        return "close"
    if (UpdateVer != "" && y >= 64 && y <= 88 && x <= 260)
        return "update"
    return ""
}

; шапка без кнопок = заголовок окна: Windows сама даёт его перетаскивать
HeaderHitTest(wParam, lParam, msg, hwnd) {
    if (hwnd != G.Hwnd)
        return
    pt := Buffer(8)
    NumPut("int", lParam << 48 >> 48, "int", lParam << 32 >> 48, pt)   ; знаковые X/Y экрана
    DllCall("ScreenToClient", "ptr", G.Hwnd, "ptr", pt)
    x := NumGet(pt, 0, "int") / DPI, y := NumGet(pt, 4, "int") / DPI
    if (y < 0 || y >= 92)
        return
    return HeaderSpot(x, y) = "" ? 2 : 1      ; HTCAPTION / HTCLIENT
}

HeaderDown(wParam, lParam, msg, hwnd) {
    if (hwnd != G.Hwnd)
        return
    spot := HeaderSpot((lParam & 0xFFFF) / DPI, ((lParam >> 16) & 0xFFFF) / DPI)
    if (spot = "")
        return
    parts := StrSplit(spot, ":")
    switch parts[1] {
        case "lang":   SetLang(parts[2])
        case "theme":  SetTheme(parts[2])
        case "layout": ToggleLayout()
        case "min":    WinMinimize(G)
        case "close":  SaveCfg(), ExitApp()
        case "update": DoUpdate()
    }
    return 0
}

ApplyLang() {
    G.Title       := T("title")
    lblMode.Text  := T("modeLbl")
    lblSpeed.Text := T("speed")
    lblOpt.Text   := T("options")
    lblKeys.Text  := T("keys")
    OptRows["jitter"][1].Text := T("jitter")
    OptRows["repeat"][1].Text := T("repeat")
    OptRows["sound"][1].Text  := T("sound")
    tHot.Text     := T("hotkey")
    tAuthor.Text  := Tf("author", AUTHOR) "  ·  v" VERSION
    RenderAll()
    if !Running
        ShowHint()
}

ShowHint() => SetStatus(Tf(CoachMode ? "hintCoach" : DrillMode ? "hintDrill" : "hint", RunKey))

PaintSub() => RenderHeader()

SetLang(code, *) {
    global Lang
    Lang := code
    ApplyLang()
    SetupTray()
    SaveCfg()
}

SetTheme(name) {
    global Theme
    Theme := name
    ApplyThemeColors()
    RenderAll()
    PaintBorder()
    SaveCfg()
}

SegModeClick(ctl, *) {
    MouseRel(ctl, &mx, &my)
    SetMode(Min(3, Floor(mx / (320 / 3)) + 1))
}

SegSpeedClick(ctl, *) {
    MouseRel(ctl, &mx, &my)
    if DrillMode
        SetDrillGame(mx >= 160 ? "old" : "new")
    else
        SetFast(mx >= 160)
}

TimeRowClick(ctl, *) {
    MouseRel(ctl, &mx, &my)
    if DrillMode
        ToggleWeak()
    else if (mx < 38)
        StepTime(-0.5)
    else if (mx >= 134 && mx < 174)
        StepTime(0.5)
}

; 1 — бот, 2 — тренер, 3 — тренировка без сайта
SetMode(n) {
    global CoachMode, DrillMode
    if Running
        return
    old := CoachMode ? 2 : DrillMode ? 3 : 1
    if (old = n)
        return
    AnimStart("seg:mode", old, n)
    if Anims.Has("seg:speed")                          ; в блоке скорости другие пункты — без анимации
        Anims.Delete("seg:speed")
    CoachMode := (n = 2), DrillMode := (n = 3)
    PaintModes(), PaintMain(), ShowHint()
    SaveCfg()
}

SetFast(v) {
    global FastMode
    if CoachMode || FastMode = v
        return
    AnimStart("seg:speed", FastMode ? 2 : 1, v ? 2 : 1)
    FastMode := v
    PaintModes()
    SaveCfg()
}

SetDrillGame(g) {
    global DrillGame
    if Running || DrillGame = g
        return
    AnimStart("seg:speed", DrillGame = "old" ? 2 : 1, g = "old" ? 2 : 1)
    DrillGame := g
    PaintModes()
    SaveCfg()
}

ToggleWeak() {
    global DrillWeak
    if Running
        return
    AnimStart("sw:weak", DrillWeak ? 1 : 0, DrillWeak ? 0 : 1)
    DrillWeak := !DrillWeak
    RenderTimeRow()
    SaveCfg()
}

PaintModes() {
    RenderSeg(segMode, [[0xE99A, T("modeBot")], [0xE7BE, T("modeCoach")], [0xE7FC, T("modeDrill")]],
        CoachMode ? 2 : DrillMode ? 3 : 1, false, "seg:mode")
    if DrillMode {
        ; в тренировке блок скорости превращается в выбор игры и «только слабые»
        if (lblSpeed.Text != T("drillLbl"))
            lblSpeed.Text := T("drillLbl")
        RenderSeg(segSpeed, [[0xE734, "New · 10"], [0xE81C, "Old · 27"]], DrillGame = "old" ? 2 : 1, false, "seg:speed")
    } else {
        if (lblSpeed.Text != T("speed"))
            lblSpeed.Text := T("speed")
        ; в режиме тренера скорость не нужна — гасим этот блок
        RenderSeg(segSpeed, [[0xE916, T("segTime")], [0xE945, T("segFast")]], FastMode ? 2 : 1, CoachMode, "seg:speed")
    }
    RenderTimeRow()
}

StepTime(d) {
    if FastMode || CoachMode || DrillMode
        return
    v := StrReplace(eTime.Value, ",", ".")
    v := IsNumber(v) ? Float(v) : 15
    eTime.Value := Format("{:.1f}", Max(1, v + d))
    SaveCfg()
}

Toggle(which, *) {
    global Jitter, Repeat, Sound
    switch which {
        case "jitter": AnimStart("sw:jitter", Jitter, !Jitter), Jitter := !Jitter
        case "repeat": AnimStart("sw:repeat", Repeat, !Repeat), Repeat := !Repeat
        case "sound":  AnimStart("sw:sound", Sound, !Sound), Sound := !Sound
    }
    PaintToggles()
    if (which = "sound")
        RenderSoundPill()
    SaveCfg()
}

PaintToggles() {
    RenderSwitch(OptRows["jitter"][2], "sw:jitter", Jitter)
    RenderSwitch(OptRows["repeat"][2], "sw:repeat", Repeat)
    RenderSwitch(OptRows["sound"][2], "sw:sound", Sound)
}

AnimStart(key, from, to, dur := 170) {
    if Anims.Has(key)                                  ; продолжаем с текущего места, без рывка
        from := AnimVal(key, from)
    Anims[key] := {from: from, to: to, t0: A_TickCount, dur: dur}
    SetTimer AnimTick, 15
}

AnimVal(key, target) {
    if !Anims.Has(key)
        return target
    a := Anims[key], k := Min(1, (A_TickCount - a.t0) / a.dur)
    return a.from + (a.to - a.from) * (1 - (1 - k) ** 3)
}

AnimTick() {
    keys := [], done := []
    for key, a in Anims {
        keys.Push(key)
        if (A_TickCount - a.t0 >= a.dur)
            done.Push(key)
    }
    for key in done
        Anims.Delete(key)
    modes := false, toggles := false
    for key in keys
        if (key = "seg:mode" || key = "seg:speed" || key = "sw:weak")
            modes := true
        else
            toggles := true
    if modes
        PaintModes()
    if toggles
        PaintToggles()
    if !Anims.Count
        SetTimer AnimTick, 0
}

IsHover(ctl, part := "") => Hover.hwnd = ctl.Hwnd && (part = "" || Hover.part = part)

; часть контрола под мышкой
HoverPart(hwnd) {
    if (hwnd = segMode.Hwnd || hwnd = segSpeed.Hwnd) {
        n := hwnd = segMode.Hwnd ? 3 : 2
        MouseRel(segMode.Hwnd = hwnd ? segMode : segSpeed, &mx, &my)
        return Min(n, Max(1, Floor(mx / (320 / n)) + 1))
    }
    if (hwnd = timeRow.Hwnd) {
        if DrillMode
            return "row"
        MouseRel(timeRow, &mx, &my)
        return mx < 38 ? "minus" : (mx >= 134 && mx < 174) ? "plus" : ""
    }
    return "on"
}

; перерисовать то, что зависит от наведения на этот контрол
RepaintHover(hwnd) {
    switch hwnd {
        case hdr.Hwnd: RenderHeader()
        case segMode.Hwnd, segSpeed.Hwnd, timeRow.Hwnd: PaintModes()
        case bMain.Hwnd: RenderMain()
        case bHot.Hwnd: RenderKeyPill(bHot, RunKey)
        case bSnd.Hwnd: RenderSoundPill()
        case bStats.Hwnd: RenderFooterBtn(bStats, 0xE9D2, T("stats"))
        case bTray.Hwnd: RenderFooterBtn(bTray, 0xE90C, T("tray"))
        default:
            for _, row in OptRows
                if (row[2].Hwnd = hwnd)
                    PaintToggles()
    }
}

HoverTick() {
    global Hover
    static hoverable := 0
    if !hoverable {
        hoverable := Map()
        for ctl in [segMode, segSpeed, timeRow, bMain, bHot, bSnd, bStats, bTray]
            hoverable[ctl.Hwnd] := true
        for _, row in OptRows
            hoverable[row[2].Hwnd] := true
    }
    hw := 0, part := ""
    if !MainHidden && !CapturingKey {
        try {
            MouseGetPos , , &win, &ctl, 2
            if (win = G.Hwnd) {
                if (ctl && hoverable.Has(ctl))
                    hw := ctl, part := HoverPart(ctl)
                else {                                     ; шапка — картинка без SS_NOTIFY
                    MouseRel(hdr, &mx, &my)
                    if (mx >= 0 && mx < HW && my >= 0 && my < 92 && (sp := HeaderSpot(mx, my)) != "")
                        hw := hdr.Hwnd, part := sp
                }
            }
        }
    }
    if (hw = Hover.hwnd && part = Hover.part)
        return
    old := Hover.hwnd
    Hover := {hwnd: hw, part: part}
    if old
        RepaintHover(old)
    if (hw && hw != old)
        RepaintHover(hw)
}

PaintMain() => RenderMain()

; клик по пилюле с клавишей -> ждём новую клавишу
CaptureHotkey(*) {
    global RunKey
    if Running
        return
    global CapturingKey := true
    RenderKeyPill(bHot, T("pressKey"))
    ih := InputHook("T6")
    ih.KeyOpt("{All}", "E")
    ih.KeyOpt("{LCtrl}{RCtrl}{LAlt}{RAlt}{LShift}{RShift}{LWin}{RWin}{CapsLock}{NumLock}{ScrollLock}", "-E")
    ih.Start()
    ih.Wait()
    key := (ih.EndReason = "EndKey") ? ih.EndKey : ""
    CapturingKey := false
    taken := ["d", "f", "Escape", "Enter", "Space", "Tab", "Backspace"]
    for _, ed in KeyEdits
        taken.Push(ed.Value)
    bad := false
    for x in taken
        if (key = x)
            bad := true
    if (key != "" && !bad) {
        try {
            Hotkey(RunKey, "Off")
            Hotkey(key, ToggleRun, "On")
            RunKey := key
        } catch {
            try Hotkey(RunKey, "On")
            bad := true
        }
    }
    RenderKeyPill(bHot, RunKey)
    PaintMain()
    if bad
        SetStatus(T("badKey"))
    else
        ShowHint()
    SaveCfg()
}

SaveCfg() {
    try {
        IniWrite Lang, IniFile, "settings", "lang"
        IniWrite Theme, IniFile, "settings", "theme"
        IniWrite Horiz ? "h" : "v", IniFile, "settings", "layout"
        IniWrite FastMode ? 1 : 0, IniFile, "settings", "fast"
        IniWrite CoachMode ? 1 : 0, IniFile, "settings", "coach"
        IniWrite DrillMode ? 1 : 0, IniFile, "settings", "drill"
        IniWrite DrillGame, IniFile, "settings", "drill_game"
        IniWrite DrillWeak ? 1 : 0, IniFile, "settings", "drill_weak"
        IniWrite OvScale, IniFile, "settings", "ov_scale"
        IniWrite OvDX, IniFile, "settings", "ov_dx"
        IniWrite OvDY, IniFile, "settings", "ov_dy"
        IniWrite Jitter ? 1 : 0, IniFile, "settings", "jitter"
        IniWrite Repeat ? 1 : 0, IniFile, "settings", "repeat"
        IniWrite Sound ? 1 : 0, IniFile, "settings", "sound"
        IniWrite SoundName, IniFile, "settings", "sound_name"
        IniWrite SoundFile, IniFile, "settings", "sound_file"
        IniWrite SoundVol, IniFile, "settings", "sound_vol"
        IniWrite RunKey, IniFile, "settings", "hotkey"
        IniWrite eTime.Value, IniFile, "settings", "time"
        for k, ed in KeyEdits
            IniWrite ed.Value, IniFile, "settings", "key_" k
    }
}

SetStatus(txt) {
    if SelfTest && tStatus.Value != txt
        FileAppend A_TickCount " " StrReplace(txt, "`n", " / ") "`n", "*", "UTF-8"
    tStatus.Value := txt
}

SetupTray() {
    tm := A_TrayMenu
    tm.Delete()
    tm.Add(T("trayShow"), (*) => ShowMain())
    tm.Add(T("trayToggle"), (*) => ToggleRun())
    tm.Add()
    tm.Add(T("trayExit"), (*) => (SaveCfg(), ExitApp()))
    tm.Default := T("trayShow")
    tm.ClickCount := 1
    A_IconTip := T("title")
}

ToTray() {
    global MainHidden
    G.Hide()
    MainHidden := true
    TrayTip T("trayTip"), T("title"), "Mute"
}

ShowMain() {
    global MainHidden
    G.Show()
    MainHidden := false
    if !(Running && CoachMode)
        OverlayHide()
}
