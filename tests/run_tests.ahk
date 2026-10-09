#Requires AutoHotkey v2.0
; Автотесты логики тренера (без окон). Запуск:
;   AutoHotkey64.exe /ErrorStdOut tests\run_tests.ahk
; Пишет результат в stdout, код выхода 0 — всё прошло, 1 — есть ошибки.
; Их же запускает GitHub Actions перед каждой сборкой (.github/workflows/tests.yml).
#NoTrayIcon
#Warn All, StdOut
#Warn LocalSameAsGlobal, Off

REPO_URL := "https://github.com/virtristis/invoker-game-bot"
#Include "%A_ScriptDir%\..\lib\spells.ahk"
#Include "%A_ScriptDir%\..\lib\logic.ahk"

global Passed := 0, Failed := 0, Report := ""

Check(name, cond) {
    global Passed, Failed, Report
    if cond
        Passed++
    else
        Failed++, Report .= "FAIL  " name "`n"
}
Eq(name, got, want) => Check(name " (got " Show(got) ", want " Show(want) ")", Show(got) == Show(want))
Show(v) {
    if IsObject(v) && v is Array {
        s := ""
        for x in v
            s .= (s = "" ? "" : ",") Show(x)
        return "[" s "]"
    }
    return String(v)
}
Orbs(s) {                                      ; "qwe" -> ["q", "w", "e"]
    a := []
    loop parse s
        a.Push(A_LoopField)
    return a
}

; ---------- таблицы спеллов ----------
Check("New: 10 spells", NewSpells.Count = 10)
Check("Old: 27 spells", OldSpells.Count = 27)
for tbl in [NewSpells, OldSpells]
    for name, combo in tbl
        Check("combo of " name " is 3 orbs of q/w/e", combo ~= "^[qwe]{3}$")
seen := Map()
for name, combo in OldSpells {
    Check("Old combo unique: " name, !seen.Has(combo))
    seen[combo] := true
}
seen := Map()
for name, combo in NewSpells {                 ; в New порядок не важен — уникальны наборы
    k := SortChars(combo)
    Check("New combo unique as a set: " name, !seen.Has(k))
    seen[k] := true
}
Check("New covers all 10 orb sets", seen.Count = 10)

; ---------- ComboProgress: сколько клавиш комбинации уже набрано ----------
Eq("old: nothing pressed", ComboProgress("qwe", [], "old"), 0)
Eq("old: right prefix", ComboProgress("qwe", Orbs("qw"), "old"), 2)
Eq("old: full", ComboProgress("qwe", Orbs("qwe"), "old"), 3)
Eq("old: wrong order", ComboProgress("qwe", Orbs("ew"), "old"), 0)
Eq("old: prefix at the end of older orbs", ComboProgress("qwe", Orbs("eeq"), "old"), 1)
Eq("new: any order", ComboProgress("qwe", Orbs("ewq"), "new"), 3)
Eq("new: partial any order", ComboProgress("qee", Orbs("eq"), "new"), 2)
Eq("new: too many of one orb", ComboProgress("qwe", Orbs("ww"), "new"), 1)
Eq("new: wrong orb", ComboProgress("eee", Orbs("q"), "new"), 0)

; ---------- ComboDisplay: в New сначала нажатые шары ----------
Eq("display old unchanged", ComboDisplay("qwe", Orbs("qw"), "old", 2), "qwe")
Eq("display new pressed first", ComboDisplay("qwe", Orbs("ew"), "new", 2), "ewq")
Eq("display new k=0", ComboDisplay("qee", [], "new", 0), "qee")

; ---------- OrbsMatch: можно ли вызвать спелл ----------
Check("match old exact", OrbsMatch("eqw", Orbs("eqw"), "old"))
Check("no match old reordered", !OrbsMatch("eqw", Orbs("qwe"), "old"))
Check("match new reordered", OrbsMatch("wee", Orbs("ewe"), "new"))
Check("no match with 2 orbs", !OrbsMatch("qqq", Orbs("qq"), "new"))
Check("match uses the last 3 orbs", OrbsMatch("eee", Orbs("qweee"), "new"))

; ---------- SpellTitle ----------
Eq("title", SpellTitle("chaos meteor"), "Chaos Meteor")
Eq("title emp", SpellTitle("emp"), "EMP")

; ---------- WeakSpells: не сыгранные, потом самые медленные ----------
avgs := Map("cold snap", 900, "tornado", 3000, "emp", 2000, "ice wall", 1500, "alacrity", 800,
            "sun strike", 700, "forge spirit", 2500, "chaos meteor", 1200)   ; ghost walk, deafening blast — не сыграны
Eq("weak: fresh first, then slowest", WeakSpells(NewSpells, avgs, 4), ["deafening blast", "ghost walk", "tornado", "forge spirit"])
Eq("weak: limit", WeakSpells(NewSpells, avgs, 1).Length, 1)
all := Map()
for name in NewSpells
    all[name] := 1000
Eq("weak: all equal still gives limit", WeakSpells(NewSpells, all, 4).Length, 4)

; ---------- DrillQueue: круги перемешаны, без повторов подряд ----------
pool := []
for name in OldSpells
    pool.Push(name)
loop 20 {
    q := DrillQueue(pool, 27)
    Check("queue length", q.Length = 27)
    s := Map()
    for x in q
        s[x] := true
    Check("one round has every spell once", s.Count = 27)
}
loop 50 {
    q := DrillQueue(["a", "b", "c"], 30), ok := true
    loop q.Length - 1
        if (q[A_Index] = q[A_Index + 1])
            ok := false
    Check("no spell twice in a row", ok)
}
Eq("queue from one spell", DrillQueue(["a"], 3), ["a", "a", "a"])
Eq("queue from empty pool", DrillQueue([], 5).Length, 0)

; ---------- ProgressPoints: секунды на спелл, без бота ----------
runs := [["2026-10-01 10:00", "coach", "new", "-", "20", "Pro"],
         ["2026-10-01 11:00", "bot", "new", "fast", "3.1", "Divine"],
         ["2026-10-02 10:00", "drill", "new", "weak", "8", "err:1"],
         ["2026-10-02 11:00", "drill", "old", "all", "54", "err:0"],
         ["2026-10-03 10:00", "coach", "new", "-", "oops", "?"]]
pts := ProgressPoints(runs, "new")
Eq("points: bot and bad values skipped", pts.Length, 2)
Eq("points: coach per spell", pts[1].y, 2.0)
Eq("points: weak drill = 8 spells", pts[2].n, 8)
Eq("points: old game", ProgressPoints(runs, "old")[1].y, 2.0)
many := []
loop 60
    many.Push(["d", "drill", "new", "all", A_Index, ""])
p := ProgressPoints(many, "new")
Check("points: only the last 40", p.Length = 40 && p[1].sec = 21)

; ---------- NiceStep: шаг сетки графика ----------
Eq("step 0..1", NiceStep(1), 0.25)
Eq("step 0..10", NiceStep(10), 2.5)
Check("step 0..3 = 1", NiceStep(3) = 1)
Check("step for zero span is positive", NiceStep(0) > 0)

; ---------- LerpColor ----------
Eq("lerp start", LerpColor(0x000000, 0xFFFFFF, 0), "000000")
Eq("lerp end", LerpColor(0x000000, 0xFFFFFF, 1), "FFFFFF")
Eq("lerp middle", LerpColor(0x000000, 0xFF0000, 0.5), "800000")

; ---------- ParseRelease: ответ GitHub API ----------
body := '{"tag_name": "v2.0.0", "html_url": "https://github.com/x/y/releases/tag/v2.0.0", "assets": ['
    . '{"browser_download_url": "https://github.com/x/y/releases/download/v2.0.0/InvokerGameBot-v2.0.0.exe"},'
    . '{"browser_download_url": "https://github.com/x/y/releases/download/v2.0.0/SHA256SUMS.txt"}]}'
r := ParseRelease(body)
Eq("release version", r.ver, "2.0.0")
Check("release exe", InStr(r.exe, "InvokerGameBot-v2.0.0.exe"))
Check("release sums", InStr(r.sums, "SHA256SUMS.txt"))
Check("release page", InStr(r.page, "/releases/tag/v2.0.0"))
Check("broken json", ParseRelease("<html>rate limited</html>") = 0)
Check("newer version is detected", VerCompare(r.ver, "1.8.4") > 0)

; ---------- SHA-256 (контрольная сумма при обновлении) ----------
abc := Buffer(3), StrPut("abc", abc, 3, "UTF-8")
Eq("sha256(abc)", Sha256(abc, 3), "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad")
Eq("sha256(empty)", Sha256(Buffer(0), 0), "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")

; ---------- звуки ----------
for name in SoundList()
    if (name != "windows" && name != "custom") {
        pr := SoundPreset(name)
        Check("sound " name " has notes", pr.notes.Length >= 1 && pr.dur > 0 && pr.gain > 0 && pr.gain < 0.5)
    }

FileAppend Report "passed " Passed ", failed " Failed "`n", "*", "UTF-8"
ExitApp Failed ? 1 : 0
