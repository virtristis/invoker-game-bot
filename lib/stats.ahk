; Invoker Game Bot — Статистика: запись прогонов и спеллов, окно статистики, график прогресса.
; Часть invoker_bot.ahk (подключается через #Include), сам по себе не запускается.

RecordRun(kind, mode, target, st) {
    if (st["sec"] = "")
        return
    line := FormatTime(, "yyyy-MM-dd HH:mm") ";" kind ";" mode ";" target ";" st["sec"] ";" st["rank"] "`n"
    try FileAppend line, StatsFile, "UTF-8"
}

RecordSpell(mode, spell, ms) {
    try {
        p := StrSplit(IniRead(SpellFile, mode, spell, "0,0"), ",")
        IniWrite (p[1] + 1) "," (p[2] + ms), SpellFile, mode, spell
    }
}

LoadRuns() {
    runs := []
    if !FileExist(StatsFile)
        return runs
    for line in StrSplit(FileRead(StatsFile, "UTF-8"), "`n", "`r")
        if (line != "") {
            f := StrSplit(line, ";")
            if (f.Length >= 6)
                runs.Push(f)
        }
    return runs
}

ShowStats() {
    global SG
    try SG.Destroy()
    SG := Gui("+Owner" G.Hwnd " +AlwaysOnTop", T("statsTitle"))
    SG.BackColor := C.bg
    SG.MarginX := 0, SG.MarginY := 0
    DarkTitle(SG.Hwnd)

    runs := LoadRuns()
    ; график прогресса: по умолчанию та игра, в которую ты играл последней
    global ChartRuns := runs, ChartGame := "new", ChartPts := []
    i := runs.Length
    while (i >= 1) {
        if (runs[i][2] != "bot") {
            ChartGame := runs[i][3] = "old" ? "old" : "new"
            break
        }
        i--
    }
    global chartPic := SG.Add("Picture", "x16 y16 w500 h210 +0x4000000")
    chartPic.OnEvent("Click", ChartClick)
    Clickable[chartPic.Hwnd] := true
    RenderChart()
    SetTimer ChartHover, 50
    SG.OnEvent("Close", (*) => CloseStats())

    SG.SetFont("norm s9 c" C.text, "Segoe UI")
    lv := SG.Add("ListView", "x16 y236 w500 h170 -Multi NoSortHdr -E0x200 Background" C.card,
        [T("colDate"), T("colKind"), T("colMode"), T("colTarget"), T("colTime"), T("colRank")])
    DllCall("uxtheme\SetWindowTheme", "ptr", lv.Hwnd, "str", "DarkMode_Explorer", "ptr", 0)
    hdr := SendMessage(0x101F, 0, 0, lv)                           ; LVM_GETHEADER
    DllCall("uxtheme\SetWindowTheme", "ptr", hdr, "str", "DarkMode_ItemsView", "ptr", 0)

    best := Map()
    i := runs.Length
    while (i >= 1) {
        r := runs[i]
        kind := r[2] = "bot" ? T("kindBot") : r[2] = "drill" ? T("kindDrill") : T("kindCoach")
        target := r[4] = "fast" ? T("fastShort") : r[4] = "-" ? "—"
            : r[4] = "all" ? T("drillAll") : r[4] = "weak" ? T("drillWeak") : r[4] " " T("sec")
        rank := RegExMatch(r[6], "^err:(\d+)$", &em) ? "✗ " em[1] : r[6]
        lv.Add(, r[1], kind, StrUpper(r[3]), target, r[5] " " T("sec"), rank)
        key := kind " " StrUpper(r[3]) (r[4] = "weak" ? " (" T("drillWeak") ")" : "")
        if IsNumber(r[5]) && (!best.Has(key) || Float(r[5]) < best[key])
            best[key] := Float(r[5])
        i--
    }
    loop 6
        lv.ModifyCol(A_Index, "AutoHdr")

    ; лучшие времена
    txt := ""
    if !runs.Length
        txt := T("noStats")
    else {
        txt := T("best") ":"
        for key, v in best
            txt .= "   " key " — " Format("{:.2f}", v) " " T("sec")
    }

    ; самые медленные спеллы (по данным тренера и тренировки)
    slow := ""
    for mode in ["new", "old"] {
        lines := ""
        for name, avg in SpellAvgs(mode)
            lines .= Round(avg) "`t" name "`n"
        if (lines = "")
            continue
        lines := Sort(RTrim(lines, "`n"), "N R")
        top := ""
        for idx, ln in StrSplit(lines, "`n") {
            if (idx > 5)
                break
            p := StrSplit(ln, "`t")
            top .= (top = "" ? "" : ",  ") p[2] " " Format("{:.2f}", p[1] / 1000)
        }
        slow .= "`n" StrUpper(mode) ":  " top
    }
    if (slow != "")
        txt .= "`n`n" T("slowest") ":" slow

    SG.SetFont("norm s9 c" C.text, "Segoe UI")
    SG.Add("Text", "x16 y416 w500 h96 Background" C.bg, txt)
    Pill("x16 y520 w120 h28", T("clear"), C.card, (*) => ClearStats(), "s9", SG)
    Pill("x396 y520 w120 h28", T("close"), C.accent, (*) => CloseStats(), "s9", SG)
    SG.Show("w532 h564")
}

CloseStats() {
    SetTimer ChartHover, 0
    ToolTip()
    try SG.Destroy()
}

; Одна ось: секунды на спелл (так сравнимы прогоны разной длины). Бот не считается —
; это не твой прогресс. New и Old — разные игры, поэтому показываем по одной (переключатель).
; цвета серий проверены на различимость (в т. ч. при дальтонизме) и контраст с фоном карточки
ChartColor(kind) => kind = "coach" ? "2E8BD0" : "D4780A"

RenderChart() {
    global ChartPts
    W := 500, H := 210
    cv := CvNew(W, H, C.bg)
    RRect(cv, 0, 0, W, H, 12, Solid(C.card))
    Txt(cv, T("chartTitle"), 14, 8, 260, 20, "Segoe UI Semibold", 10.5, 0, C.text, 0)
    ; переключатель New / Old справа сверху
    for i, g in ["new", "old"] {
        x := W - 110 + (i - 1) * 48, on := (ChartGame = g)
        RRect(cv, x, 8, 44, 20, 6, Solid(on ? C.accent : C.field))
        Txt(cv, StrUpper(g), x, 8, 44, 20, "Segoe UI Semibold", 9.5, 0, on ? C.onAccent : C.muted)
    }
    pts := ProgressPoints(ChartRuns, ChartGame)
    ChartPts := pts
    ; легенда
    lx := 14
    for kind in ["coach", "drill"] {
        RRect(cv, lx, 37, 14, 3, 1.5, Solid(ChartColor(kind)))
        Circle(cv, lx + 7, 38.5, 3.5, Solid(ChartColor(kind)))
        name := T(kind = "coach" ? "kindCoach" : "kindDrill")
        Txt(cv, name, lx + 20, 29, 120, 18, "Segoe UI", 9.5, 0, C.muted, 0)
        lx += 28 + TxtW(cv, name, "Segoe UI", 9.5, 0)
    }
    if !pts.Length {
        Txt(cv, T("chartEmpty"), 0, 50, W, H - 60, "Segoe UI", 10.5, 0, C.muted)
        CvToPic(cv, chartPic)
        return
    }
    ; область построения и шкала
    L := 48, R := W - 92, Tp := 56, B := H - 28
    ymin := ymax := pts[1].y
    for p in pts
        ymin := Min(ymin, p.y), ymax := Max(ymax, p.y)
    if (ymax - ymin < 0.05)                          ; одна точка или ровная линия — даём шкале запас
        pad := Max(0.1, ymax * 0.1), ymin := Max(0, ymin - pad), ymax += pad
    step := NiceStep(ymax - ymin)
    lo := Floor(ymin / step) * step, hi := Ceil(ymax / step) * step
    if (hi - lo < step)
        hi := lo + step
    dec := step < 0.1 ? 2 : 1
    v := lo
    while (v <= hi + step / 1000) {
        y := B - (v - lo) / (hi - lo) * (B - Tp)
        DllCall("gdiplus\GdipFillRectangle", "ptr", cv.g, "ptr", br := Solid("FFFFFF", 16), "float", L, "float", y, "float", R - L, "float", 1)
        DllCall("gdiplus\GdipDeleteBrush", "ptr", br)
        Txt(cv, Format("{:." dec "f}", v), 4, y - 9, L - 10, 18, "Segoe UI", 9, 0, C.muted, 2)
        v += step
    }
    Txt(cv, T("perSpell"), 4, B + 6, 120, 18, "Segoe UI", 8.5, 0, C.muted, 0)
    Txt(cv, SubStr(pts[1].date, 1, 10), L, B + 6, 120, 18, "Segoe UI", 8.5, 0, C.muted, 0)
    if (pts.Length > 1)
        Txt(cv, SubStr(pts[pts.Length].date, 1, 10), R - 120, B + 6, 120, 18, "Segoe UI", 8.5, 0, C.muted, 2)
    ; координаты точек (x — номер прогона по порядку)
    for i, p in pts {
        p.px := pts.Length = 1 ? (L + R) / 2 : L + (i - 1) / (pts.Length - 1) * (R - L)
        p.py := B - (p.y - lo) / (hi - lo) * (B - Tp)
    }
    ; линии 2 px и маркеры с кольцом цвета фона
    ends := []
    for kind in ["coach", "drill"] {
        ser := []
        for p in pts
            if (p.kind = kind)
                ser.Push(p)
        if !ser.Length
            continue
        if (ser.Length > 1) {
            buf := Buffer(8 * ser.Length)
            for i, p in ser
                NumPut("float", p.px, "float", p.py, buf, (i - 1) * 8)
            DllCall("gdiplus\GdipCreatePen1", "uint", ARGB(ChartColor(kind)), "float", 2, "int", 2, "ptr*", &pen := 0)
            DllCall("gdiplus\GdipSetPenLineJoin", "ptr", pen, "int", 2)
            DllCall("gdiplus\GdipDrawLines", "ptr", cv.g, "ptr", pen, "ptr", buf, "int", ser.Length)
            DllCall("gdiplus\GdipDeletePen", "ptr", pen)
        }
        for p in ser {
            Circle(cv, p.px, p.py, 6, Solid(C.card))
            Circle(cv, p.px, p.py, 4, Solid(ChartColor(kind)))
        }
        ends.Push([ser[ser.Length], kind])
    }
    ; подписи у последних точек: название серии и последнее значение (текст — цветом текста)
    if (ends.Length = 2 && Abs(ends[1][1].py - ends[2][1].py) < 30) {
        up := ends[1][1].py <= ends[2][1].py ? 1 : 2
        ends[up].Push(-15), ends[3 - up].Push(15)
    }
    for e in ends {
        p := e[1], dy := e.Length > 2 ? e[3] : 0
        ly := Max(Tp - 10, Min(B - 20, p.py + dy - 15))
        Txt(cv, T(e[2] = "coach" ? "kindCoach" : "kindDrill"), R + 10, ly, 84, 15, "Segoe UI", 8.5, 0, C.muted, 0)
        Txt(cv, Format("{:.2f}", p.y), R + 10, ly + 13, 84, 17, "Segoe UI Semibold", 10, 0, C.text, 0)
    }
    CvToPic(cv, chartPic)
}

ChartClick(ctl, *) {
    global ChartGame
    MouseRel(ctl, &mx, &my)
    if (my <= 30 && mx >= 390) {
        ChartGame := mx < 438 ? "new" : "old"
        ToolTip()
        RenderChart()
    }
}

; подсказка при наведении: ближайшая точка по горизонтали
ChartHover() {
    static last := 0
    try {
        if !WinActive("ahk_id " SG.Hwnd)
            throw Error()
        MouseRel(chartPic, &mx, &my)
    } catch {
        if last
            ToolTip(), last := 0
        return
    }
    best := 0, bd := 18
    if (mx >= 0 && mx <= 500 && my >= 40 && my <= 210)
        for p in ChartPts
            if p.HasOwnProp("px") && Abs(p.px - mx) < bd
                best := p, bd := Abs(p.px - mx)
    if !best {
        if last
            ToolTip(), last := 0
        return
    }
    if (best = last)
        return
    last := best
    ToolTip(best.date "`n" T(best.kind = "coach" ? "kindCoach" : "kindDrill") ": " Format("{:.2f}", best.sec) " " T("sec")
        . "`n" Format("{:.2f}", best.y) " " T("perSpell"))
}

ClearStats() {
    if (MsgBox(T("clearConfirm"), T("statsTitle"), "YesNo Owner" SG.Hwnd) != "Yes")
        return
    try FileDelete StatsFile
    try FileDelete SpellFile
    ShowStats()
}

; среднее время по спеллам из invoker_spells.ini: Map имя -> мс
SpellAvgs(mode) {
    avgs := Map()
    try sect := IniRead(SpellFile, mode)
    catch
        return avgs
    for kv in StrSplit(sect, "`n", "`r")
        if RegExMatch(kv, "^(.+?)=(\d+),(\d+)$", &m) && m[2] > 0
            avgs[m[1]] := m[3] / m[2]
    return avgs
}
