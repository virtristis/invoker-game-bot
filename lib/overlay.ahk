; Invoker Game Bot — Оверлей тренера и компактного режима: отрисовка, место, перетаскивание и размер.
; Часть invoker_bot.ahk (подключается через #Include), сам по себе не запускается.

; нажатая — светится своим цветом, следующая — с цветной рамкой, остальные — серые.
; Рисуем в «логических» 272×126 и масштабируем на OvScale (размер меняется мышкой).
; mode — "new"/"old": тогда слева от названия иконка спелла; outFile — для автотестов
RenderOverlay(title, combo, k, sub, mode := "", outFile := "") {
    static OrbColors := Map("q", "38BDF8", "w", "C084FC", "e", "F59E0B", "r", "E6E8EF")
    global OvLast := [title, combo, k, sub, mode]
    cv := CvNew(272 * OvScale, 126 * OvScale, C.card)
    DllCall("gdiplus\GdipScaleWorldTransform", "ptr", cv.g, "float", OvScale, "float", OvScale, "int", 0)
    br := Linear(0, 0, 0, 126, C.head, C.card)
    DllCall("gdiplus\GdipFillRectangle", "ptr", cv.g, "ptr", br, "float", 0, "float", 0, "float", 272, "float", 126)
    DllCall("gdiplus\GdipDeleteBrush", "ptr", br)
    tx := 16
    if (mode != "" && DrawIcon(cv, IconBmp(mode, title), 16, 9, 22, 5))
        tx := 44
    Txt(cv, SpellTitle(title), tx, 8, 256 - tx, 24, "Segoe UI Semibold", 14, 0, C.text, 0)
    letters := combo "r"
    loop 4 {
        ch := SubStr(letters, A_Index, 1)
        col := OrbColors[ch]
        key := StrUpper(CurKeyMap.Has(ch) ? CurKeyMap[ch] : ch)
        x := 16 + (A_Index - 1) * 62, y := 38
        if (A_Index <= k) {                                  ; нажата
            Glow(cv, x + 27, y + 27, 42, col, 120)
            RRect(cv, x, y, 54, 54, 12, Linear(0, y, 0, y + 54, "FFFFFF", col, 120, 255))
            RRect(cv, x + 3, y + 3, 48, 48, 10, Solid(col, 210))
            Txt(cv, key, x, y, 54, 54, "Segoe UI Black", 22, 0, ch = "r" ? "1A1D27" : "FFFFFF")
        } else if (A_Index = k + 1) {                        ; следующая
            Glow(cv, x + 27, y + 27, 36, col, 45)
            RRect(cv, x, y, 54, 54, 12, Solid(col, 230))
            RRect(cv, x + 2, y + 2, 50, 50, 10, Solid("181B26"))
            Txt(cv, key, x, y, 54, 54, "Segoe UI Black", 22, 0, col)
        } else {                                             ; ещё не нажата
            RRect(cv, x, y, 54, 54, 12, Solid("1E2130"))
            Txt(cv, key, x, y, 54, 54, "Segoe UI Black", 22, 0, col, 1, 80)
        }
    }
    Txt(cv, sub, 16, 98, 226, 20, "Segoe UI", 11, 0, C.muted, 0)
    ; уголок для изменения размера
    for d in [[0, 0], [4, 0], [8, 0], [0, 4], [4, 4], [0, 8]]
        Circle(cv, 262 - d[1], 116 - d[2], 1.2, Solid("FFFFFF", 80))
    if (outFile != "")
        CvSave(cv, outFile)
    else
        CvToPic(cv, ovPic)
}

; title — заголовок, combo — "qwe", k — сколько клавиш уже нажато, sub — нижняя строка
; Оверлей стоит относительно окна игры: смещение OvDX/OvDY от правого верхнего угла
; (его задаёшь, перетаскивая оверлей мышкой; пусто — место по умолчанию)
OverlayShow(gameHwnd, title, combo, k, sub, mode := "") {
    global OvVisible, OvState, OvPos, OvGame
    try WinGetPos &gx, &gy, &gw, &gh, gameHwnd
    catch
        return
    OvGame := [gx, gy, gw, gh]
    state := title "|" combo "|" k "|" sub "|" mode
    if (state != OvState) {
        OvState := state
        RenderOverlay(title, combo, k, sub, mode)
    }
    if OvDragging                                      ; пока тащишь мышкой — не мешаем
        return
    WinGetPos , , &ow, , OV
    pos := OvDX = "" ? (gx + gw - ow - 40) "," (gy + 140) : (gx + gw + OvDX) "," (gy + OvDY)
    if !OvVisible {
        p := StrSplit(pos, ",")
        OV.Show("NA x" p[1] " y" p[2])
        OvVisible := true, OvPos := pos
    } else if (pos != OvPos) {
        p := StrSplit(pos, ",")
        WinMove p[1], p[2], , , OV
        OvPos := pos
    }
}

OverlayHide() {
    global OvVisible, OvState
    if OvVisible
        OV.Hide()
    OvVisible := false, OvState := ""
}

OvInCorner(mx, my) {                                   ; экранные координаты мыши
    WinGetPos &ox, &oy, &ow, &oh, OV
    return mx > ox + ow - 22 * DPI && my > oy + oh - 22 * DPI
}

IsOv(hwnd) => IsSet(OV) && OV && (hwnd = OV.Hwnd || hwnd = ovPic.Hwnd)

; Перетаскивание целиком делает Windows (как окно за заголовок): так оно работает,
; даже пока тренер занят чтением страницы. Если потянули за уголок — во время
; перетаскивания (WM_MOVING) окно стоит на месте, а сдвиг мыши меняет размер.
; запоминаем, где была мышь при последней проверке «что под курсором»: Windows начинает
; перетаскивание, когда мышь уже чуть сдвинулась, и тогда она может быть уже не в уголке
OvHitTest(wParam, lParam, msg, hwnd) {
    global OvLastHit
    if !IsOv(hwnd)
        return
    x := lParam << 48 >> 48, y := lParam << 32 >> 48     ; знаковые экранные X/Y
    if !GetKeyState("LButton")
        OvLastHit := {x: x, corner: OvInCorner(x, y)}
    return 2                                            ; HTCAPTION
}
OvEnterMove(wParam, lParam, msg, hwnd) {
    global OvDragging, OvResize
    if !IsOv(hwnd)
        return
    OvDragging := true
    WinGetPos &ox, &oy, &ow, , OV
    OvResize := OvLastHit && OvLastHit.corner ? {mx: OvLastHit.x, x: ox, y: oy, w: ow, s: OvScale} : 0
}
OvMoving(wParam, lParam, msg, hwnd) {
    global OvScale
    if !OvResize || !IsOv(hwnd)
        return
    CoordMode "Mouse", "Screen"
    MouseGetPos &mx
    s := Round(Max(0.6, Min(2.0, OvResize.s * (OvResize.w + mx - OvResize.mx) / OvResize.w)), 2)
    if (s != OvScale)
        OvScale := s, OvApplyScale()
    w := Round(272 * OvScale * DPI), h := Round(126 * OvScale * DPI)
    NumPut("int", OvResize.x, "int", OvResize.y, "int", OvResize.x + w, "int", OvResize.y + h, lParam)
    return true
}
OvExitMove(wParam, lParam, msg, hwnd) {
    global OvDragging, OvResize
    if !IsOv(hwnd)
        return
    OvDragging := false, OvResize := 0
    OvSavePos()
}
; колесо над оверлеем: ±10 %
OvWheel(wParam, lParam, msg, hwnd) {
    global OvScale
    if !IsOv(hwnd)
        return
    s := Round(Max(0.6, Min(2.0, OvScale + ((wParam << 32 >> 48) > 0 ? 0.1 : -0.1))), 2)
    if (s != OvScale)
        OvScale := s, OvApplyScale(), OvSavePos()
    return 0
}

OvMenu(wParam, lParam, msg, hwnd) {
    if (hwnd != OV.Hwnd && hwnd != ovPic.Hwnd)
        return
    m := Menu()
    m.Add(T("ovReset"), (*) => OvReset())
    m.Show()
    return 0
}

; запомнить место относительно окна игры
OvSavePos() {
    global OvDX, OvDY, OvPos
    WinGetPos &ox, &oy, , , OV
    if !OvGame
        return
    OvDX := ox - (OvGame[1] + OvGame[3]), OvDY := oy - OvGame[2]
    OvPos := ox "," oy
    SaveCfg()
}

OvReset() {
    global OvScale, OvDX, OvDY, OvPos
    OvScale := 1, OvDX := "", OvDY := "", OvPos := ""
    OvApplyScale()
    SaveCfg()
}

; новый размер окна и перерисовка в нём
OvApplyScale() {
    global OvState
    w := Round(272 * OvScale), h := Round(126 * OvScale)
    ovPic.Move(0, 0, w, h)
    WinMove , , Round(w * DPI), Round(h * DPI), OV
    OvState := ""
    if OvLast
        RenderOverlay(OvLast*)
}
