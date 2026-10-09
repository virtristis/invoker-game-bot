; Invoker Game Bot — Рисование через GDI+: холсты, скругления, градиенты, текст, иконки, снимки окон.
; Часть invoker_bot.ahk (подключается через #Include), сам по себе не запускается.

DarkTitle(hwnd) {
    ; тёмный заголовок окна (Windows 10/11) и цвет заголовка (Windows 11)
    DllCall("dwmapi\DwmSetWindowAttribute", "ptr", hwnd, "int", 20, "int*", 1, "int", 4)
    DllCall("dwmapi\DwmSetWindowAttribute", "ptr", hwnd, "int", 35, "int*", 0x17110F, "int", 4)
}

; плоская кнопка из Text (для окна статистики)
Pill(opts, txt, bg, fn, fontOpts := "s10", gui := "") {
    if (gui = "")
        gui := G
    gui.SetFont("norm " fontOpts " c" C.text, "Segoe UI Semibold")
    ctl := gui.Add("Text", opts " Center 0x200 Background" bg, txt)
    ctl.OnEvent("Click", fn)
    Clickable[ctl.Hwnd] := true
    return ctl
}

Paint(ctrl, bg, fg := "") {
    ctrl.Opt("Background" bg)
    if fg != ""
        ctrl.SetFont("c" fg)
    ctrl.Redraw()
}

ARGB(hex, a := 255) => (a << 24) | Integer("0x" hex)

FontExists(name) {
    st := DllCall("gdiplus\GdipCreateFontFamilyFromName", "wstr", name, "ptr", 0, "ptr*", &f := 0)
    if !st
        DllCall("gdiplus\GdipDeleteFontFamily", "ptr", f)
    return !st
}

Fam(name) {
    static cache := Map()
    if cache.Has(name)
        return cache[name]
    if DllCall("gdiplus\GdipCreateFontFamilyFromName", "wstr", name, "ptr", 0, "ptr*", &f := 0)
        DllCall("gdiplus\GdipCreateFontFamilyFromName", "wstr", "Segoe UI", "ptr", 0, "ptr*", &f := 0)
    return cache[name] := f
}

; холст в логических пикселях (масштаб DPI — через мировую трансформацию)
CvNew(w, h, bg) {
    pw := Round(w * DPI), ph := Round(h * DPI)
    DllCall("gdiplus\GdipCreateBitmapFromScan0", "int", pw, "int", ph, "int", 0, "int", 0x26200A, "ptr", 0, "ptr*", &bmp := 0)
    DllCall("gdiplus\GdipGetImageGraphicsContext", "ptr", bmp, "ptr*", &gr := 0)
    DllCall("gdiplus\GdipSetSmoothingMode", "ptr", gr, "int", 4)
    DllCall("gdiplus\GdipSetTextRenderingHint", "ptr", gr, "int", 4)
    DllCall("gdiplus\GdipSetPixelOffsetMode", "ptr", gr, "int", 4)
    DllCall("gdiplus\GdipGraphicsClear", "ptr", gr, "uint", ARGB(bg))
    DllCall("gdiplus\GdipScaleWorldTransform", "ptr", gr, "float", DPI, "float", DPI, "int", 0)
    return {bmp: bmp, g: gr, bg: bg}
}

CvToPic(cv, pic) {
    DllCall("gdiplus\GdipCreateHBITMAPFromBitmap", "ptr", cv.bmp, "ptr*", &hbm := 0, "uint", ARGB(cv.bg))
    pic.Value := "HBITMAP:" hbm
    DllCall("gdiplus\GdipDeleteGraphics", "ptr", cv.g)
    DllCall("gdiplus\GdipDisposeImage", "ptr", cv.bmp)
}

RoundPath(x, y, w, h, r) {
    DllCall("gdiplus\GdipCreatePath", "int", 0, "ptr*", &p := 0)
    d := r * 2
    DllCall("gdiplus\GdipAddPathArc", "ptr", p, "float", x, "float", y, "float", d, "float", d, "float", 180, "float", 90)
    DllCall("gdiplus\GdipAddPathArc", "ptr", p, "float", x + w - d, "float", y, "float", d, "float", d, "float", 270, "float", 90)
    DllCall("gdiplus\GdipAddPathArc", "ptr", p, "float", x + w - d, "float", y + h - d, "float", d, "float", d, "float", 0, "float", 90)
    DllCall("gdiplus\GdipAddPathArc", "ptr", p, "float", x, "float", y + h - d, "float", d, "float", d, "float", 90, "float", 90)
    DllCall("gdiplus\GdipClosePathFigure", "ptr", p)
    return p
}

Solid(hex, a := 255) {
    DllCall("gdiplus\GdipCreateSolidFill", "uint", ARGB(hex, a), "ptr*", &b := 0)
    return b
}

Linear(x1, y1, x2, y2, hex1, hex2, a1 := 255, a2 := 255) {
    p1 := Buffer(8), p2 := Buffer(8)
    NumPut("float", x1, "float", y1, p1), NumPut("float", x2, "float", y2, p2)
    DllCall("gdiplus\GdipCreateLineBrush", "ptr", p1, "ptr", p2, "uint", ARGB(hex1, a1), "uint", ARGB(hex2, a2), "int", 3, "ptr*", &b := 0)
    return b
}

; заливка скруглённого прямоугольника (кисть удаляется)
RRect(cv, x, y, w, h, r, brush) {
    p := RoundPath(x, y, w, h, r)
    DllCall("gdiplus\GdipFillPath", "ptr", cv.g, "ptr", brush, "ptr", p)
    DllCall("gdiplus\GdipDeletePath", "ptr", p)
    DllCall("gdiplus\GdipDeleteBrush", "ptr", brush)
}

Circle(cv, cx, cy, r, brush) {
    DllCall("gdiplus\GdipFillEllipse", "ptr", cv.g, "ptr", brush, "float", cx - r, "float", cy - r, "float", 2 * r, "float", 2 * r)
    DllCall("gdiplus\GdipDeleteBrush", "ptr", brush)
}

; мягкое круглое свечение
Glow(cv, cx, cy, rad, hex, a) {
    DllCall("gdiplus\GdipCreatePath", "int", 0, "ptr*", &p := 0)
    DllCall("gdiplus\GdipAddPathEllipse", "ptr", p, "float", cx - rad, "float", cy - rad, "float", 2 * rad, "float", 2 * rad)
    DllCall("gdiplus\GdipCreatePathGradientFromPath", "ptr", p, "ptr*", &b := 0)
    DllCall("gdiplus\GdipSetPathGradientCenterColor", "ptr", b, "uint", ARGB(hex, a))
    sc := Buffer(4), NumPut("uint", ARGB(hex, 0), sc), n := 1
    DllCall("gdiplus\GdipSetPathGradientSurroundColorsWithCount", "ptr", b, "ptr", sc, "int*", &n)
    DllCall("gdiplus\GdipFillPath", "ptr", cv.g, "ptr", b, "ptr", p)
    DllCall("gdiplus\GdipDeleteBrush", "ptr", b), DllCall("gdiplus\GdipDeletePath", "ptr", p)
}

; шар с бликом (Quas / Wex / Exort)
Orb(cv, cx, cy, r, hex) {
    DllCall("gdiplus\GdipCreatePath", "int", 0, "ptr*", &p := 0)
    DllCall("gdiplus\GdipAddPathEllipse", "ptr", p, "float", cx - r, "float", cy - r, "float", 2 * r, "float", 2 * r)
    DllCall("gdiplus\GdipCreatePathGradientFromPath", "ptr", p, "ptr*", &b := 0)
    pt := Buffer(8), NumPut("float", cx - r * 0.3, "float", cy - r * 0.35, pt)
    DllCall("gdiplus\GdipSetPathGradientCenterPoint", "ptr", b, "ptr", pt)
    DllCall("gdiplus\GdipSetPathGradientCenterColor", "ptr", b, "uint", ARGB("FFFFFF"))
    sc := Buffer(4), NumPut("uint", ARGB(hex), sc), n := 1
    DllCall("gdiplus\GdipSetPathGradientSurroundColorsWithCount", "ptr", b, "ptr", sc, "int*", &n)
    DllCall("gdiplus\GdipFillPath", "ptr", cv.g, "ptr", b, "ptr", p)
    DllCall("gdiplus\GdipDeleteBrush", "ptr", b), DllCall("gdiplus\GdipDeletePath", "ptr", p)
}

; текст; align: 0 — слева, 1 — по центру, 2 — справа; style: 1 — жирный, 4 — подчёркнутый
Txt(cv, str, x, y, w, h, font, size, style, hex, align := 1, a := 255) {
    DllCall("gdiplus\GdipCreateFont", "ptr", Fam(font), "float", size, "int", style, "int", 2, "ptr*", &f := 0)
    DllCall("gdiplus\GdipCreateStringFormat", "int", 0x5000, "int", 0, "ptr*", &fmt := 0)
    DllCall("gdiplus\GdipSetStringFormatAlign", "ptr", fmt, "int", align)
    DllCall("gdiplus\GdipSetStringFormatLineAlign", "ptr", fmt, "int", 1)
    rc := Buffer(16), NumPut("float", x, "float", y, "float", w, "float", h, rc)
    br := Solid(hex, a)
    DllCall("gdiplus\GdipDrawString", "ptr", cv.g, "wstr", str, "int", -1, "ptr", f, "ptr", rc, "ptr", fmt, "ptr", br)
    DllCall("gdiplus\GdipDeleteBrush", "ptr", br), DllCall("gdiplus\GdipDeleteStringFormat", "ptr", fmt)
    DllCall("gdiplus\GdipDeleteFont", "ptr", f)
}

TxtW(cv, str, font, size, style) {
    DllCall("gdiplus\GdipCreateFont", "ptr", Fam(font), "float", size, "int", style, "int", 2, "ptr*", &f := 0)
    DllCall("gdiplus\GdipCreateStringFormat", "int", 0x5000, "int", 0, "ptr*", &fmt := 0)
    rc := Buffer(16, 0), NumPut("float", 0, "float", 0, "float", 2000, "float", 200, rc)
    bd := Buffer(16, 0)
    DllCall("gdiplus\GdipMeasureString", "ptr", cv.g, "wstr", str, "int", -1, "ptr", f, "ptr", rc, "ptr", fmt, "ptr", bd, "ptr", 0, "ptr", 0)
    DllCall("gdiplus\GdipDeleteStringFormat", "ptr", fmt), DllCall("gdiplus\GdipDeleteFont", "ptr", f)
    return NumGet(bd, 8, "float")
}

; иконка + подпись, вместе по центру области
IconText(cv, icon, str, x, y, w, h, size, col, iconCol := "") {
    iw := size + 2, tw := TxtW(cv, str, "Segoe UI Semibold", size, 0)
    sx := x + (w - iw - 7 - tw) / 2
    Txt(cv, Chr(icon), sx, y, iw, h, IconFont, size * 0.92, 0, iconCol != "" ? iconCol : col, 1)
    Txt(cv, str, sx + iw + 7, y, tw + 4, h, "Segoe UI Semibold", size, 0, col, 0)
}

; заголовок с золотым градиентом и свечением; align: 0 — слева, 1 — по центру
TitleText(cv, str, x, y, w, h, font, size, align := 0) {
    DllCall("gdiplus\GdipCreatePath", "int", 0, "ptr*", &p := 0)
    DllCall("gdiplus\GdipCreateStringFormat", "int", 0x5000, "int", 0, "ptr*", &fmt := 0)
    DllCall("gdiplus\GdipSetStringFormatAlign", "ptr", fmt, "int", align)
    DllCall("gdiplus\GdipSetStringFormatLineAlign", "ptr", fmt, "int", 1)
    rc := Buffer(16), NumPut("float", x, "float", y, "float", w, "float", h, rc)
    DllCall("gdiplus\GdipAddPathString", "ptr", p, "wstr", str, "int", -1, "ptr", Fam(font), "int", 1, "float", size, "ptr", rc, "ptr", fmt)
    for wd in [9, 6, 3] {
        DllCall("gdiplus\GdipCreatePen1", "uint", ARGB("F59E0B", 34), "float", wd, "int", 2, "ptr*", &pen := 0)
        DllCall("gdiplus\GdipSetPenLineJoin", "ptr", pen, "int", 2)
        DllCall("gdiplus\GdipDrawPath", "ptr", cv.g, "ptr", pen, "ptr", p)
        DllCall("gdiplus\GdipDeletePen", "ptr", pen)
    }
    br := Linear(0, y + 4, 0, y + h - 4, "FEF3C7", "F59E0B")
    DllCall("gdiplus\GdipFillPath", "ptr", cv.g, "ptr", br, "ptr", p)
    DllCall("gdiplus\GdipDeleteBrush", "ptr", br), DllCall("gdiplus\GdipDeleteStringFormat", "ptr", fmt)
    DllCall("gdiplus\GdipDeletePath", "ptr", p)
}

; снимок окна в PNG через PrintWindow (WM_PRINT: окно и контролы дорисовываются сами — надёжно и на скрытом рабочем столе)
SaveWindowShot(gui, file) => CvSave({bmp: WindowBitmap(gui), g: 0}, file)

; содержимое окна -> GDI+ bitmap (для снимков и эффекта при закрытии)
WindowBitmap(gui) {
    WinGetClientPos , , &w, &h, gui
    hdc := DllCall("GetDC", "ptr", 0, "ptr")
    mdc := DllCall("CreateCompatibleDC", "ptr", hdc, "ptr")
    hbm := DllCall("CreateCompatibleBitmap", "ptr", hdc, "int", w, "int", h, "ptr")
    obm := DllCall("SelectObject", "ptr", mdc, "ptr", hbm, "ptr")
    DllCall("PrintWindow", "ptr", gui.Hwnd, "ptr", mdc, "uint", 1)     ; PW_CLIENTONLY
    DllCall("SelectObject", "ptr", mdc, "ptr", obm)
    DllCall("gdiplus\GdipCreateBitmapFromHBITMAP", "ptr", hbm, "ptr", 0, "ptr*", &bmp := 0)
    DllCall("DeleteObject", "ptr", hbm), DllCall("DeleteDC", "ptr", mdc), DllCall("ReleaseDC", "ptr", 0, "ptr", hdc)
    return bmp
}

; холст -> PNG (для автотестов и картинок в README)
CvSave(cv, file) {
    clsid := Buffer(16)
    DllCall("ole32\CLSIDFromString", "wstr", "{557CF406-1A04-11D3-9A73-0000F81EF32E}", "ptr", clsid)
    DllCall("gdiplus\GdipSaveImageToFile", "ptr", cv.bmp, "wstr", file, "ptr", clsid, "ptr", 0)
    DllCall("gdiplus\GdipDeleteGraphics", "ptr", cv.g)
    DllCall("gdiplus\GdipDisposeImage", "ptr", cv.bmp)
}

; иконка со скруглёнными углами; false — если картинки нет
DrawIcon(cv, bmp, x, y, s, r := 8) {
    if !bmp
        return false
    p := RoundPath(x, y, s, s, r)
    DllCall("gdiplus\GdipSetClipPath", "ptr", cv.g, "ptr", p, "int", 0)
    DllCall("gdiplus\GdipSetInterpolationMode", "ptr", cv.g, "int", 7)
    DllCall("gdiplus\GdipDrawImageRect", "ptr", cv.g, "ptr", bmp, "float", x, "float", y, "float", s, "float", s)
    DllCall("gdiplus\GdipResetClip", "ptr", cv.g)
    DllCall("gdiplus\GdipDeletePath", "ptr", p)
    return true
}
