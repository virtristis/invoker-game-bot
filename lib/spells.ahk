; Invoker Game Bot — комбинации спеллов New и Old.
; Часть invoker_bot.ahk (подключается через #Include), сам по себе не запускается.

; комбинации с сайта (q/w/e = Quas/Wex/Exort)
NewSpells := Map(
    "cold snap", "qqq",  "ghost walk", "qqw",  "ice wall", "qqe",
    "emp", "www",        "tornado", "qww",     "alacrity", "wwe",
    "sun strike", "eee", "forge spirit", "qee", "chaos meteor", "wee",
    "deafening blast", "qwe"
)
; в Old порядок шаров важен
OldSpells := Map(
    "icy path", "qqq",        "portal", "qqw",           "betrayal", "qwq",
    "mana burn", "wqq",       "tornado blast", "qww",    "emp", "wqw",
    "telelightning", "wwq",   "shock", "www",            "frost nova", "qqe",
    "power word", "qeq",      "chaos meteor", "eqq",     "shroud of flames", "qee",
    "disarm", "eqe",          "deafening blast", "eeq",  "firebolt", "eee",
    "arcane arts", "wwe",     "energy ball", "wew",      "firestorm", "eww",
    "lightning shield", "wee", "incinerate", "ewe",      "inferno", "eew",
    "levitation", "qwe",      "invisibility aura", "qew", "soul reaver", "ewq",
    "confuse", "eqw",         "scout", "weq",            "soul blast", "wqe"
)
