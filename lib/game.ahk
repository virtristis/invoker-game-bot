; Invoker Game Bot — Чтение страницы через UI Automation, режим бота и режим тренера.
; Часть invoker_bot.ahk (подключается через #Include), сам по себе не запускается.

; условие: ControlType = Text ИЛИ Button
MakeCondition() {
    v := Buffer(24, 0)
    NumPut("ushort", 3, v, 0), NumPut("int", 50020, v, 8)
    ComCall(23, UIA, "int", 30003, "ptr", v, "ptr*", &cText := 0)
    NumPut("int", 50000, v, 8)
    ComCall(23, UIA, "int", 30003, "ptr", v, "ptr*", &cBtn := 0)
    ComCall(28, UIA, "ptr", cText, "ptr", cBtn, "ptr*", &cOr := 0)
    ObjRelease(cText), ObjRelease(cBtn)
    return cOr
}

; кэш: имя и тип забираются одним запросом
MakeCacheRequest() {
    ComCall(20, UIA, "ptr*", &cr := 0)
    ComCall(3, cr, "int", 30005)    ; Name
    ComCall(3, cr, "int", 30003)    ; ControlType
    return cr
}

ToggleRun(*) => Running ? StopBot() : StartBot()

StartBot() {
    global Running, CurKeyMap
    if Running
        return
    if !CoachMode && !DrillMode && !IsNumber(StrReplace(eTime.Value, ",", ".")) {
        SetStatus(T("badTime"))
        return
    }
    CurKeyMap := Map()
    for k, ed in KeyEdits
        CurKeyMap[k] := ed.Value != "" ? ed.Value : k
    SaveCfg()
    Running := true
    PaintMain()
    if DrillMode {
        SetStatus(T("drillReady"))
        DrillOpen()
        return
    }
    if CoachMode && !(IconsReady("new") && IconsReady("old")) {
        SetStatus(T("drillIcons"))                     ; иконки для оверлея — один раз
        IconsFetch("new"), IconsFetch("old")
    }
    SetStatus(T("running"))
    if CoachMode {
        RegisterCoachKeys()
        SetTimer CoachLoop, -1
    } else {
        SetTimer BotLoop, -1
    }
}

StopBot(msg := "") {
    global Running
    Running := false
    OverlayHide()
    UnregisterCoachKeys()
    DrillClose()
    PaintMain()
    SetStatus(msg != "" ? msg : T("stopped"))
    if SelfTest {
        FileAppend tStatus.Value "`n", "*", "UTF-8"
        ExitApp
    }
}

; Возвращает Map: inGame, finished, done, total, spell, result, sec, rank,
; startBtn (элемент кнопки Start/Play Again или 0)
ReadPage(hwnd) {
    st := Map("inGame", false, "finished", false, "done", -1, "total", -1,
              "spell", "", "result", "", "sec", "", "rank", "", "startBtn", 0)
    root := 0, arr := 0, n := 0
    try {
        ComCall(6, UIA, "ptr", hwnd, "ptr*", &root)                   ; ElementFromHandle
        ; FindAllBuildCache(descendants, Text|Button, cache)
        ComCall(8, root, "int", 4, "ptr", UiaCond, "ptr", UiaCache, "ptr*", &arr)
        ComCall(3, arr, "int*", &n)
    } catch {
        if arr
            ObjRelease(arr)
        if root
            ObjRelease(root)
        Sleep 50
        return st
    }
    texts := []
    loop n {
        el := 0
        try {
            ComCall(4, arr, "int", A_Index - 1, "ptr*", &el)
            ComCall(53, el, "int*", &ct := 0)                         ; CachedControlType
            ComCall(55, el, "ptr*", &bstr := 0)                       ; CachedName
            name := bstr ? StrGet(bstr, "UTF-16") : ""
            DllCall("OleAut32\SysFreeString", "ptr", bstr)
        } catch {
            if el
                ObjRelease(el)
            continue
        }
        if (ct = 50020) {                                             ; Text
            texts.Push(Trim(name))
        } else if (!st["startBtn"] && RegExMatch(name, "^(Start Game|Play Again)")) {
            st["startBtn"] := el
            continue                                                  ; не освобождаем
        }
        ObjRelease(el)
    }
    ObjRelease(arr), ObjRelease(root)

    ; (не называть переменную "t" — в AHK это то же самое, что функция T())
    for i, txt in texts {
        if (txt = "Game Finished!") {
            st["finished"] := true
            ; дальше идут: ранг, "8.52", "s"
            loop 4 {
                j := i + A_Index
                if (j <= texts.Length && RegExMatch(texts[j], "^\d+(\.\d+)?$")) {
                    st["sec"]    := texts[j]
                    st["rank"]   := texts[i + 1]
                    st["result"] := texts[j] " " T("sec") " (" texts[i + 1] ")"
                    break
                }
            }
        }
        ; "<done>", "/", "<total>", "<Spell>"
        if (txt = "/" && i > 1 && i + 2 <= texts.Length
            && IsInteger(texts[i - 1]) && IsInteger(texts[i + 1])) {
            st["inGame"] := true
            st["done"]   := Integer(texts[i - 1])
            st["total"]  := Integer(texts[i + 1])
            st["spell"]  := StrLower(texts[i + 2])
        }
    }
    return st
}

ReleaseBtn(st) {
    if st["startBtn"]
        ObjRelease(st["startBtn"]), st["startBtn"] := 0
}

PressStart(st) {
    try {
        ComCall(16, st["startBtn"], "int", 10000, "ptr*", &pat := 0)  ; InvokePattern
        ComCall(3, pat)
        ObjRelease(pat)
    }
}

GameWindow() {
    return WinActive("Invoker-Game")
}

; New = 10 спеллов, Old = 27; если спелла нет в таблице — пробуем другую
ResolveSpell(st, &mode, &combo) {
    spell := st["spell"]
    mode := (st["total"] = 27) ? "old" : "new"
    spells := (mode = "old") ? OldSpells : NewSpells
    if !spells.Has(spell) {
        mode := (mode = "old") ? "new" : "old"
        spells := (mode = "old") ? OldSpells : NewSpells
    }
    if !spells.Has(spell)
        return false
    combo := spells[spell]
    return true
}

BotLoop() {
    global Running
    target := Float(StrReplace(eTime.Value, ",", ".")) * 1000
    targetTxt := FastMode ? "fast" : Format("{:.1f}", target / 1000)
    startTick := 0
    lastDone := -1
    lastMode := "new"
    played := false

    while Running {
        hwnd := GameWindow()
        if !hwnd {
            OverlayHide()
            SetStatus(T("waitTab"))
            Sleep 200
            continue
        }
        st := ReadPage(hwnd)

        ; меню или экран результата
        if !st["inGame"] {
            if st["finished"] && played {
                ReleaseBtn(st)
                res := st["result"] != "" ? st["result"] : "?"
                RecordRun("bot", lastMode, targetTxt, st)
                Notify(res)
                if !Repeat {
                    StopBot(T("done") res)
                    return
                }
                SetStatus(Tf("again", res))
                Sleep 1000
                played := false
                continue
            }
            if st["startBtn"] {
                PressStart(st)
                startTick := A_TickCount     ; таймер сайта стартует здесь
                ReleaseBtn(st)
                Sleep 300
            } else {
                SetStatus(T("noGame"))
                Sleep 200
            }
            lastDone := -1
            continue
        }
        ReleaseBtn(st)

        done := st["done"], total := st["total"], spell := st["spell"]
        if (startTick = 0 || (done = 0 && lastDone > 0))
            startTick := A_TickCount         ; игра уже шла / перезапуск вручную
        lastDone := done
        played := true

        if !ResolveSpell(st, &mode, &combo) {
            SetStatus(T("unknown") spell)
            Sleep 100
            continue
        }
        lastMode := mode

        if FastMode {
            gap := 15
        } else {
            ; -950 мс: сайт засчитывает с задержкой, иначе итог выходит дольше
            deadline := startTick + (target - 950) * (done + 1) / total
            gap := Max(15, (deadline - A_TickCount) / 4)
        }

        progress := (done + 1) " / " total
        SetStatus(T("mode") ": " StrUpper(mode) "   " progress
            . "`n" T("spell") ": " spell
            . "`n" T("time") ": " Format("{:.1f}", (A_TickCount - startTick) / 1000) " " T("sec"))

        for idx, k in StrSplit(combo "r") {
            if !Running || !GameWindow()
                break
            if MainHidden                    ; компактный режим — показываем, что жмём
                OverlayShow(hwnd, spell, combo, idx - 1, StrUpper(mode) "  ·  " progress, mode)
            delay := Jitter ? gap * (0.75 + Random() * 0.5) : gap
            Sleep Round(delay)
            Send "{" CurKeyMap[k] "}"
        }
        if MainHidden
            OverlayShow(hwnd, spell, combo, 4, StrUpper(mode) "  ·  " progress, mode)

        ; ждём, пока сайт засчитает (до 1.5 сек)
        t0 := A_TickCount
        while Running && (A_TickCount - t0 < 1500) {
            hwnd := GameWindow()
            if !hwnd
                break
            s2 := ReadPage(hwnd)
            ReleaseBtn(s2)
            if !s2["inGame"] || s2["done"] != done
                break
            Sleep 10
        }
    }
}

CoachActive(*) => Running && CoachMode && WinActive("Invoker-Game")

; слушаем свои Q/W/E/R (с "~", чтобы нажатия доходили до сайта). Без #HotIf: условие
; проверяем в самом обработчике — так нажатие не теряется, даже если программа
; в этот момент занята чтением страницы
RegisterCoachKeys() {
    global CoachKeys
    for phys in CoachKeys
        try Hotkey("~" phys, "Off")
    CoachKeys := Map()
    for letter in ["q", "w", "e", "r"] {
        phys := CurKeyMap[letter]
        CoachKeys[phys] := letter
        try Hotkey("~" phys, CoachKey, "On")
    }
}
UnregisterCoachKeys() {
    for phys in CoachKeys
        try Hotkey("~" phys, "Off")
}

CoachKey(hk) {
    phys := SubStr(hk, 2)
    if !CoachActive() || !CoachKeys.Has(phys) || CoachKeys[phys] = "r"
        return
    CoachSt.orbs.Push(CoachKeys[phys])
    if (CoachSt.orbs.Length > 3)
        CoachSt.orbs.RemoveAt(1)
}

CoachProgress() => ComboProgress(CoachSt.combo, CoachSt.orbs, CoachSt.mode)

CoachDisplay(k) => ComboDisplay(CoachSt.combo, CoachSt.orbs, CoachSt.mode, k)

CoachLoop() {
    global Running
    lastDone := -1, lastSpell := "", lastMode := "new"
    spellTick := 0, startTick := 0
    played := false

    while Running {
        hwnd := GameWindow()
        if !hwnd {
            OverlayHide()
            SetStatus(T("waitTab"))
            Sleep 200
            continue
        }
        st := ReadPage(hwnd)
        menu := st["startBtn"] != 0                  ; на странице кнопка Start / Play Again
        ReleaseBtn(st)

        if !st["inGame"] {
            ; чтение страницы иногда не успевает (браузер занят) — это ещё не конец игры:
            ; не прячем оверлей и не забываем нажатые шары, просто читаем ещё раз
            if played && !st["finished"] && !menu {
                Sleep 60
                continue
            }
            OverlayHide()
            if st["finished"] && played {
                if (lastSpell != "" && spellTick)
                    RecordSpell(lastMode, lastSpell, A_TickCount - spellTick)
                res := st["result"] != "" ? st["result"] : "?"
                RecordRun("coach", lastMode, "-", st)
                Notify(res)
                played := false
                if SelfTest {
                    StopBot(T("done") res)
                    return
                }
                SetStatus(T("done") res)
            } else if !played {
                SetStatus(T("coachWait"))
            }
            lastDone := -1, lastSpell := "", spellTick := 0
            CoachSt.orbs := []                      ; новая игра начинается без шаров
            Sleep 120
            continue
        }

        if !ResolveSpell(st, &mode, &combo) {
            SetStatus(T("unknown") st["spell"])
            Sleep 100
            continue
        }

        done := st["done"]
        if (done != lastDone) {                     ; новый спелл
            if (lastSpell != "" && spellTick && done = lastDone + 1)
                RecordSpell(lastMode, lastSpell, A_TickCount - spellTick)
            if (done = 0 || !played)
                startTick := A_TickCount
            lastDone := done, lastSpell := st["spell"], lastMode := mode
            spellTick := A_TickCount
            ; шары не сбрасываем: в игре они остаются от прошлого спелла
            CoachSt.combo := combo, CoachSt.mode := mode
            played := true
        }

        k := CoachProgress()
        elapsed := Format("{:.1f}", (A_TickCount - startTick) / 1000)
        progress := (done + 1) " / " st["total"]
        OverlayShow(hwnd, st["spell"], CoachDisplay(k), k, StrUpper(mode) "  ·  " progress "  ·  " elapsed " " T("sec"), mode)
        hint := ""
        for ch in StrSplit(combo "r")
            hint .= StrUpper(CurKeyMap[ch]) " "
        SetStatus(T("mode") ": " StrUpper(mode) "   " progress
            . "`n" T("spell") ": " st["spell"] "  →  " Trim(hint)
            . "`n" T("time") ": " elapsed " " T("sec"))
        Sleep 40
    }
    OverlayHide()
}
