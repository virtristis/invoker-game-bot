; Invoker Game Bot — Логика без интерфейса: комбинации, слабые спеллы, очередь тренировки, график, разбор релиза. Её проверяют автотесты (tests\run_tests.ahk).
; Часть invoker_bot.ahk (подключается через #Include), сам по себе не запускается.

; цвет между двумя RGB-цветами (k = 0..1) -> "RRGGBB"
LerpColor(c1, c2, k) {
    r := Round(((c1 >> 16) & 0xFF) + (((c2 >> 16) & 0xFF) - ((c1 >> 16) & 0xFF)) * k)
    g2 := Round(((c1 >> 8) & 0xFF) + (((c2 >> 8) & 0xFF) - ((c1 >> 8) & 0xFF)) * k)
    b := Round((c1 & 0xFF) + ((c2 & 0xFF) - (c1 & 0xFF)) * k)
    return Format("{:02X}{:02X}{:02X}", r, g2, b)
}

; разбор JSON релиза (без библиотек: нужные поля регулярками)
ParseRelease(body) {
    if !RegExMatch(body, '"tag_name"\s*:\s*"v?([\d.]+)"', &m)
        return 0
    info := {ver: m[1], page: REPO_URL "/releases/latest", exe: "", sums: ""}
    if RegExMatch(body, '"html_url"\s*:\s*"([^"]*/releases/tag/[^"]*)"', &u)
        info.page := u[1]
    if RegExMatch(body, '"browser_download_url"\s*:\s*"([^"]*/InvokerGameBot-v[\d.]+\.exe)"', &e)
        info.exe := e[1]
    if RegExMatch(body, '"browser_download_url"\s*:\s*"([^"]*/SHA256SUMS\.txt)"', &h)
        info.sums := h[1]
    return info
}

; точки графика из прогонов: {kind, date, sec, n, y}; последние 40
ProgressPoints(runs, game, limit := 40) {
    pts := []
    for r in runs {
        if (r[3] != game || r[2] = "bot" || !IsNumber(r[5]))
            continue
        full := game = "old" ? 27 : 10
        n := (r[2] = "drill" && r[4] = "weak") ? (game = "old" ? 18 : 8) : full
        pts.Push({kind: r[2], date: r[1], sec: Float(r[5]), n: n, y: Float(r[5]) / n})
    }
    if (pts.Length > limit)
        pts.RemoveAt(1, pts.Length - limit)
    return pts
}

; «красивый» шаг сетки: 1, 2, 2.5 или 5 × 10^k
NiceStep(span, target := 4) {
    raw := Max(span, 0.0001) / target
    mag := 10 ** Floor(Log(raw))
    for m in [1, 2, 2.5, 5, 10]
        if (m * mag >= raw - 1e-9)
            return m * mag
}

; Свои звуки программа синтезирует сама (WAV в %APPDATA%), поэтому громкость можно
; менять для любого звука: это громкость самой программы в микшере Windows.
SoundList() => ["chime", "bell", "arcade", "soft", "invoke", "windows", "custom"]

; ноты: f — частота, t — начало (сек), decay — затухание, p — обертоны [кратность, громкость],
; f1/sweep — плавный подъём частоты от f до f1 за sweep сек
SoundPreset(name) {
    switch name {
        case "bell":   return {dur: 1.6, gain: 0.14, notes: [
            {f: 784, t: 0, decay: 2.6, p: [[1, 1], [2.76, 0.45], [5.4, 0.22], [8.93, 0.1]]}]}
        case "arcade": return {dur: 0.6, gain: 0.16, notes: [
            {f: 1046.5, t: 0, decay: 10, p: [[1, 1], [3, 0.33], [5, 0.2]]},
            {f: 1318.5, t: 0.08, decay: 10, p: [[1, 1], [3, 0.33], [5, 0.2]]},
            {f: 1568, t: 0.16, decay: 8, p: [[1, 1], [3, 0.33], [5, 0.2]]}]}
        case "soft":   return {dur: 1.0, gain: 0.17, notes: [
            {f: 440, t: 0, decay: 4, p: [[1, 1]]}, {f: 659.25, t: 0.2, decay: 4, p: [[1, 1]]}]}
        case "invoke": return {dur: 0.9, gain: 0.21, notes: [
            {f: 330, f1: 990, sweep: 0.22, t: 0, decay: 4.2, p: [[1, 1], [2, 0.3], [3, 0.12]]},
            {f: 1320, t: 0.22, decay: 7, p: [[1, 0.5], [2, 0.12]]}]}
        default:       return {dur: 0.7, gain: 0.16, notes: [            ; chime: E5 -> B5
            {f: 659.25, t: 0, decay: 6.5, p: [[1, 1], [2, 0.18]]},
            {f: 987.77, t: 0.12, decay: 6.5, p: [[1, 1], [2, 0.18]]}]}
    }
}

; сколько первых клавиш комбинации уже набрано (по последним шарам, как в игре)
; combo — "qwe", orbs — массив нажатых шаров (последние в конце), mode — "new" / "old"
ComboProgress(combo, orbs, mode) {
    best := 0
    loop 3 {
        k := A_Index
        if (orbs.Length < k)
            break
        last := []
        loop k
            last.Push(orbs[orbs.Length - k + A_Index])
        ok := true
        if (mode = "old") {
            loop k
                if (last[A_Index] != SubStr(combo, A_Index, 1))
                    ok := false
        } else {                       ; New: порядок не важен
            rest := combo
            for ch in last {
                p := InStr(rest, ch)
                if !p {
                    ok := false
                    break
                }
                rest := SubStr(rest, 1, p - 1) SubStr(rest, p + 1)
            }
        }
        if ok
            best := k
    }
    return best
}

; что показывать в оверлее: в Old — комбинация как есть; в New порядок не важен,
; поэтому сначала уже нажатые шары (в твоём порядке), потом недостающие
ComboDisplay(combo, orbs, mode, k) {
    if (mode = "old" || k = 0)
        return combo
    shown := "", rest := combo
    loop k {
        ch := orbs[orbs.Length - k + A_Index]
        shown .= ch
        p := InStr(rest, ch)
        rest := SubStr(rest, 1, p - 1) SubStr(rest, p + 1)
    }
    return shown rest
}

; собраны ли нужные шары: в Old — точный порядок, в New — тот же набор в любом порядке
OrbsMatch(combo, orbs, mode) {
    if (orbs.Length < 3)
        return false
    have := orbs[orbs.Length - 2] orbs[orbs.Length - 1] orbs[orbs.Length]
    if (mode = "old")
        return have == combo
    return SortChars(have) == SortChars(combo)
}

SortChars(s) {
    chars := ""
    loop parse s
        chars .= A_LoopField "`n"
    return StrReplace(Sort(RTrim(chars, "`n")), "`n")
}

; «mana burn» -> «Mana Burn», «emp» -> «EMP»
SpellTitle(name) => name = "emp" ? "EMP" : StrTitle(name)

; слабые спеллы: сначала ни разу не сыгранные, потом самые медленные по среднему времени
; spells — Map имя -> комбо, avgs — Map имя -> среднее время (мс), limit — сколько взять
WeakSpells(spells, avgs, limit) {
    out := [], timed := ""
    for name in spells {
        if avgs.Has(name)
            timed .= Format("{:010}", Round(avgs[name])) "`t" name "`n"
        else if (out.Length < limit)
            out.Push(name)
    }
    if (timed != "")
        for ln in StrSplit(Sort(RTrim(timed, "`n"), "R"), "`n") {
            if (out.Length >= limit)
                break
            out.Push(StrSplit(ln, "`t")[2])
        }
    return out
}

; очередь из length спеллов: весь pool по кругу, каждый круг перемешан,
; один и тот же спелл два раза подряд не выпадает (если в pool их больше одного)
DrillQueue(pool, length) {
    q := []
    if !pool.Length
        return q
    while (q.Length < length) {
        bag := pool.Clone()
        i := bag.Length
        while (i > 1) {                                  ; перемешивание Фишера — Йетса
            j := Random(1, i)
            tmp := bag[i], bag[i] := bag[j], bag[j] := tmp
            i--
        }
        if (q.Length && bag.Length > 1 && bag[1] = q[q.Length])
            tmp := bag[1], bag[1] := bag[2], bag[2] := tmp
        for s in bag {
            if (q.Length >= length)
                break
            q.Push(s)
        }
    }
    return q
}

; SHA-256 через системный bcrypt (Windows 10+): hex в нижнем регистре
Sha256(buf, size) {
    hash := Buffer(32)
    DllCall("bcrypt\BCryptOpenAlgorithmProvider", "ptr*", &alg := 0, "wstr", "SHA256", "ptr", 0, "uint", 0)
    DllCall("bcrypt\BCryptHash", "ptr", alg, "ptr", 0, "uint", 0, "ptr", buf, "uint", size, "ptr", hash, "uint", 32)
    DllCall("bcrypt\BCryptCloseAlgorithmProvider", "ptr", alg, "uint", 0)
    hex := ""
    loop 32
        hex .= Format("{:02x}", NumGet(hash, A_Index - 1, "uchar"))
    return hex
}
