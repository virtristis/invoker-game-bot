; Invoker Game Bot — Иконки спеллов: загрузка (Valve CDN / invoker-game.com), WebP через WIC, кэш.
; Часть invoker_bot.ahk (подключается через #Include), сам по себе не запускается.

; new-cold-snap.png, old-tornado-blast.webp, old-quas.webp
IconFile(mode, name) => IconDir "\" mode "-" StrReplace(name, " ", "-") (mode = "new" ? ".png" : ".webp")

IconNames(mode) {
    names := ["quas", "wex", "exort", "invoke"]
    for name in (mode = "old" ? OldSpells : NewSpells)
        names.Push(name)
    return names
}

IconsReady(mode) {
    for name in IconNames(mode)
        if !FileExist(IconFile(mode, name))
            return false
    return true
}

; качаем недостающие иконки (за сеанс — одна попытка на режим)
IconsFetch(mode) {
    static tried := Map()
    if tried.Has(mode)
        return
    tried[mode] := true
    if (mode = "new") {
        for name in IconNames("new")
            IconDownload("https://cdn.cloudflare.steamstatic.com/apps/dota2/images/dota_react/abilities/invoker_"
                StrReplace(name, " ", "_") ".png", IconFile("new", name))
        return
    }
    media := SiteMedia()
    for name in IconNames("old") {
        slug := name = "tornado blast" ? "tornado" : StrReplace(name, " ", "-")
        if RegExMatch(name, "^(quas|wex|exort|invoke)$")
            slug .= "-old"
        if media.Has(slug)
            IconDownload("https://invoker-game.com/_next/" media[slug], IconFile("old", name))
    }
}

IconDownload(url, file) {
    if FileExist(file)
        return
    tmp := file ".part"
    try {
        Download url, tmp
        if (FileGetSize(tmp) > 100)
            FileMove tmp, file, 1
    }
    try FileDelete tmp
}

; картинки сайта: имя -> "static/media/имя.хэш.webp". На сайте сначала объявлены
; иконки New, потом все 27 Old, поэтому у повторяющихся имён (emp, tornado…) берём последнее
SiteMedia() {
    media := Map(), seen := Map()
    html := HttpGet("https://invoker-game.com/")
    pos := 1
    while (pos := RegExMatch(html, "/_next/static/chunks/[\w\-.]+\.js", &m, pos)) {
        pos += StrLen(m[0])
        if seen.Has(m[0])
            continue
        seen[m[0]] := true
        js := HttpGet("https://invoker-game.com" m[0]), p2 := 1
        while (p2 := RegExMatch(js, "static/media/([a-z0-9\-]+)\.[\w\-]+\.webp", &mm, p2)) {
            media[mm[1]] := mm[0]
            p2 += StrLen(mm[0])
        }
    }
    return media
}

HttpGet(url) {
    try {
        req := ComObject("WinHttp.WinHttpRequest.5.1")
        req.SetTimeouts(5000, 5000, 5000, 10000)
        req.Open("GET", url, false)
        req.SetRequestHeader("User-Agent", "invoker-game-bot/" VERSION)
        req.Send()
        return req.Status = 200 ? req.ResponseText : ""
    }
    return ""
}

; GDI+-картинка иконки (с кэшем); 0 — если файла пока нет
IconBmp(mode, name) {
    static cache := Map()
    key := mode ":" name
    if cache.Has(key)
        return cache[key]
    f := IconFile(mode, name)
    if !FileExist(f)
        return 0
    return cache[key] := WicLoad(f)
}

; любой формат, который знает Windows (PNG, WebP…) -> GDI+ bitmap 32bpp ARGB
WicLoad(path) {
    static fac := 0
    bmp := 0, dec := 0, frame := 0, conv := 0
    try {
        if !fac      ; CLSID_WICImagingFactory, IID_IWICImagingFactory
            fac := ComObject("{CACAF262-9370-4615-A13B-9F5539DA4C0A}", "{EC5EC8A9-C395-4314-9C77-54D7A935FF70}")
        ComCall(3, fac, "wstr", path, "ptr", 0, "uint", 0x80000000, "int", 0, "ptr*", &dec)   ; CreateDecoderFromFilename
        ComCall(13, dec, "uint", 0, "ptr*", &frame)                                           ; GetFrame
        ComCall(10, fac, "ptr*", &conv)                                                       ; CreateFormatConverter
        guid := Buffer(16)
        DllCall("ole32\CLSIDFromString", "wstr", "{6FDDC324-4E03-4BFE-B185-3D77768DC90F}", "ptr", guid) ; 32bppBGRA
        ComCall(8, conv, "ptr", frame, "ptr", guid, "int", 0, "ptr", 0, "double", 0, "int", 0) ; Initialize
        ComCall(3, conv, "uint*", &w := 0, "uint*", &h := 0)                                 ; GetSize
        DllCall("gdiplus\GdipCreateBitmapFromScan0", "int", w, "int", h, "int", 0, "int", 0x26200A, "ptr", 0, "ptr*", &bmp)
        rc := Buffer(16), NumPut("int", 0, "int", 0, "int", w, "int", h, rc)
        bd := Buffer(32, 0)
        DllCall("gdiplus\GdipBitmapLockBits", "ptr", bmp, "ptr", rc, "uint", 2, "int", 0x26200A, "ptr", bd)
        stride := NumGet(bd, 8, "int"), scan0 := NumGet(bd, 16, "ptr")
        ComCall(7, conv, "ptr", 0, "uint", stride, "uint", stride * h, "ptr", scan0)          ; CopyPixels
        DllCall("gdiplus\GdipBitmapUnlockBits", "ptr", bmp, "ptr", bd)
    } catch {
        if bmp
            DllCall("gdiplus\GdipDisposeImage", "ptr", bmp), bmp := 0
    }
    for p in [conv, frame, dec]
        if p
            ObjRelease(p)
    return bmp
}
