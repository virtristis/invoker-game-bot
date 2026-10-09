; Invoker Game Bot — Проверка обновлений и обновление в один клик.
; Часть invoker_bot.ahk (подключается через #Include), сам по себе не запускается.

CheckUpdate() {
    global UpdateVer, UpdateUrl, UpdateInfo
    info := LatestRelease(true)
    if info && VerCompare(info.ver, VERSION) > 0 {
        UpdateVer := info.ver, UpdateUrl := info.page, UpdateInfo := info
        PaintSub()
    }
}

; последний релиз с GitHub: {ver, page, exe, sums} или 0.
; async — ждать ответ, не блокируя окно (при запуске)
LatestRelease(async := false) {
    try {
        req := ComObject("WinHttp.WinHttpRequest.5.1")
        req.Open("GET", REPO_API, async)
        req.SetRequestHeader("User-Agent", "invoker-game-bot/" VERSION)
        req.Send()
        if async
            loop 50 {                               ; до 5 сек
                if req.WaitForResponse(0)
                    break
                Sleep 100
            }
        if (req.Status != 200)
            return 0
        body := req.ResponseText
    } catch
        return 0
    return ParseRelease(body)
}

; обновление в один клик: качаем новый exe рядом со старым, сверяем SHA-256,
; запускаем его, а он удаляет старый файл (--cleanup). Из исходника — просто страница релиза.
DoUpdate() {
    if Running
        StopBot()
    if !A_IsCompiled || !IsObject(UpdateInfo) || UpdateInfo.exe = "" {
        Run(UpdateUrl)
        return
    }
    SetStatus(Tf("updLoading", UpdateVer))
    newExe := DownloadVerified(UpdateInfo, A_ScriptDir)
    if (newExe = "") {
        SetStatus(T("updFail"))
        Run(UpdateUrl)
        return
    }
    SaveCfg()
    Run('"' newExe '" --cleanup "' A_ScriptFullPath '" ' ProcessExist())
    ExitApp
}

; скачать exe релиза в папку dir и проверить SHA-256; путь к файлу или ""
DownloadVerified(info, dir) {
    SplitPath info.exe, &name
    dest := dir "\" name, tmp := dest ".part"
    try {
        Download info.exe, tmp
        sums := HttpGet(info.sums)
        if !RegExMatch(sums, "im)^" RegExReplace(name, "[.\\]", "\$0") "\s+([0-9a-f]{64})", &m)
            || StrLower(m[1]) != Sha256File(tmp)
            throw Error("checksum")
        FileMove tmp, dest, 1
        return dest
    }
    try FileDelete tmp
    return ""
}

Sha256File(path) {
    data := FileRead(path, "RAW")
    return Sha256(data, data.Size)
}
