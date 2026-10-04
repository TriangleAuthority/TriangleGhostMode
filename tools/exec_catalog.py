"""Catalog the game's console commands (vanilla exec functions) into docs/console-commands.md.

Every `exec function` in the vanilla scripts of a ref (default `vanilla-5.x`) is listed with
its signature, its source file and line, and its first statement as a hint of what it does,
grouped by topic. Topics come from keyword rules on the name (first match wins), so a few
commands land in a loose bucket; the hint and the source settle what a command really does.

Commands tested in game are listed in VERIFIED and marked in the catalog; the details are in
docs/game-automation.md#setting-up-geralt-and-the-world. Keep the two in step.

Usage:
    python tools/exec_catalog.py                    # write docs/console-commands.md
    python tools/exec_catalog.py --ref vanilla-5.x --out docs/console-commands.md
"""
import argparse
import re
import subprocess
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SCRIPTS = "modGhostMode/scripts/"

# Tested in game (lower case names); see docs/game-automation.md.
VERIFIED = {
    "setlevel", "addskillpoints", "skilleq", "learnskill", "additem", "addmoney",
    "hitstamina", "buffme", "spawn", "killall", "settime", "god", "tptopos",
}

# (topic, name pattern), first match wins. Patterns are matched against the lower-case name.
TOPICS = [
    ("Profiling, platform, telemetry and engine debugging",
     r"^profiler|marketing|modio|^mod(menu|terms|verif|failed)$|kinect|telemetry|achiev|rumble|^xdp|"
     r"^startupexp|^debugforcecrash|^pvd$|^writepgo$|^playstation$|^enablepcmode$|^setstartscreenplatform$|"
     r"^simulatedlcsavailable$|^testdlcinstalled$|^issa$|^ssa$|^standalone_|^redreminder$|^fakeskipframe$|"
     r"^enablelog$|^inputlogging$|^loginputcontext$|^printcontext$|^bgf|^srfdes$|^setshowflag$|^forcegraphicallod$|"
     r"^forceactorlod$|^disp(skeleton)|^gametestdummy$|^debugfirstlaunch$|^savefix$|^testsaveind$|^testautosave$"),
    ("Gwent", r"gwent|card|deck"),
    ("Horse and boat", r"horse|boat|mount|^roach|^instantmount$"),
    ("Tutorials", r"^tut|tut$|tutorial|^untut$|^hidetut$|^fhint$|^hintloc$|^showcrossbowtut$|pattern"),
    ("Sound and music", r"sound|music|^mute|^unmute$|^hpitch$|^cry"),
    ("Character development: level, experience, skills, mutations",
     r"level|^addexp$|^getexppoints$|skill|perk|^learn|^cleardevelop$|^resetbuild$|^setplayerbuild$|mut|"
     r"^logplayerdev$|^dbg|^addslot$|^slottest$|^difflevel$|^printdiff$|^set(easy|medium|hard|hardcore)$|"
     r"^bonusvalue$|^newgameplus$|^startnewgameplus$|^simngp$|^focusboy$|^criticalboy$"),
    ("Player stats, effects and invulnerability",
     r"^god|stamina|^heal|^hitme$|^hittarget$|^drainstat$|^addstat$|buff|immunity|^addabl$|^rmvabl$|"
     r"^targetaddabl$|^blockab|^printab|^testab$|^stats|^logstats$|^addfocus$|^knockdown$|^hackknockdown$|"
     r"^drunk$|^playerkill$|^resurrect$|^freezetodeath$|^weak$|^likeaboss$|^imback$|^shakeoffgeralt$|"
     r"^printbuffs$|^printstate$|^slog$|^sgo$|^spop$|^spush$|^attackmult|^addattackmult$|^med|^abortmeditation$"),
    ("Items, inventory, crafting and money",
     r"item|^add|inv|equip|^eq|^removeitem$|money|craft|recipe|schematic|^rw|rune|^dye|^testlydyes$|"
     r"^dur|dur\b|^decdur$|^incdur$|^reduceidur|^testdur$|enchant|dismantle|recycle|^upi$|^iu$|^ii$|^loot|"
     r"^vloot$|^vcrafting$|^vrecycling$|^autoloot$|^fillchest$|^fillshop$|^giveset$|^dressmeup$|^undressme$|"
     r"transmog|^hideitem$|^useoil$|^oilstats$|^drinkpot|^expots$|^potmode$|^pottip$|^eatapple$|^mule$|"
     r"^reduceitems$|^omnom$|^fb\d?$|^primabooks$|^primarec$|^readabook$|^readbook$|^bookread$|^tmut$|^witchcraft$|"
     r"^klapaucius$|^makeitrain$|^r4ryanalchemy$|^teststash$|^printinv"),
    ("Combat, NPCs and spawning",
     r"spawn|^kill|attitude|faction|^getatt|^getactoratt|^sethostile$|^combatstage$|finish|dismember|"
     r"stagger|parry|counter|^dodge|^approachattack$|^ragdoll$|^appearance$|^changeap$|^freeze$|^panic$|"
     r"^nopolice$|^cage$|^printtags$|^testmonster|^testbeast$|^specials$|^blockrageontarget$|^forcecombatmode$|"
     r"^togglecloseCombat$|^toggleclosecombat$|^testnewcombat$|^shoottest$|^bufftarget$|^hittarget$|^stopuncon$|"
     r"^imlerithsecondstage$|^eredins$|^magicbubble$|^scalebubble$|^snowball$|^testdrownerswimming$|"
     r"^ethereal|^megabomb$|^addmeteoritem$|^suppressreactions$|^createreactionevent$|^emitreactionevent$|"
     r"^runcgossip$|^rungossip$|^followNPC$|^follownpc$|^moveto|^movealongpath$|^testcustomaction$|^cost|"
     r"^dumpcommunityagents$|^clearandstopcanfindpathenemieslistupdate$|^showattrange$|^upperbody$|"
     r"^testsw$|^settlement$|^innkeep$|^ciri$|^geralt$|^replaceplayer$|^panther$|^cat$|^skate$|^shieldapp$"),
    ("World: time, weather, travel, map, environment",
     r"time|^tm$|weather|rain|^wait$|^passtime$|^hour$|^tp|teleport|^tlp$|^xy$|^pos$|^goto|^debugtp$|"
     r"map|pin|^ft|ft$|^countft$|^testft$|^allowft$|^showallft$|^bft$|^uft$|^light$|^execsetlight$|"
     r"^execislighton$|^isfiresource$|^isininterior$|^useinteriors$|^interiorcam$|door|rift|gate|^hidelayer$|"
     r"polarsun|^poi$|^openrift$|^closerift$|^testrootsmaze$|^fixnoticeboard$|^censer$|^zzz$|^gather$"),
    ("Quests, facts, journal and glossary",
     r"fact|quest|journal|^jour$|glossary|bestiary|charactersep2|^acticon$|^startcontentep2$|^thebegining|"
     r"^r4quest$|^r4glossaryencyclopedia$|^reputation|^reptest$|^resetnegativepoints$|^addreppoints$|"
     r"^testgameprogress$|^addtreasurehuntitems$|^addallthmaps$|^addftmaps$"),
    ("Camera", r"cam|^fd|^fm|^fon$|^foff$|^ton$|^toff$|^treset$|^dcc$|^dscale$|^setcam$|^staticcam$|^arcam$|^gamecam$"),
    ("HUD, menus and UI",
     r"hud|menu|popup|^ui|ui$|^closeui$|^showmouse$|^subscale$|^olscale$|oneliner|^sysmsg|^test2popup|"
     r"^testnotify$|^showdebugtext$|^hidedebugtext$|^dlg|^loadingmenu|^testmessage$|^showsaferect$|"
     r"^setpmaspect$|^recapmovies$|^startupmovies$|^showloadingscreenvideo$|^deathscreen$|^postermenu$|"
     r"^gammamenu$|^testgamma$|^mm_|^hl$|^asub$|^rsub$|^hud_|^testcrosshair$|^showitemnames$|^testloc|"
     r"^testturkish|^testvoice|^testblock|^testlock|^testpause$|^testunpause$|^closelootpopup$|^closeoverlay$|"
     r"^closetutorialpopup$|^testarea$|^testrescale$|^headname$|^showquestgroups$|^ingamemenu$|^ws_|^dupemenu"),
    ("Player input and movement",
     r"input|^actionblock$|^remactlocks$|^printallgameplayblocks$|^climb|^slide$|^walk$|^setmove$|"
     r"^setrunttype$|^setruntype$|^uber|^enableubermovement$|^fixmovement$|^moveplayerfwd$|^playerdynamic$|"
     r"^playerkinematic$|^pc_snaptonavdata$|^enablesnaptonavmesh$|^setautoclimb$|^hardlock$|^forceholster$|"
     r"^changestyle$|^addfactdualgripstyle$|^settargetswitch|^usenativetargeting$|^obstacle$|^dupa$|"
     r"^breaksync$|^switchattach$|^spamplayerspeed$|^slow$|^sm$|^at$|^act$|^inact$|^alert$|^proxy$|"
     r"^togglejdbg$|^toggleqt$|^toggleall$|^togglemenus$|^invertcamera$|^lunge"),
    ("Appearance: hair, beard, head", r"hair|beard|^shave$|tattoo|head|^setcol$|^witcherhairstyle$"),
]
OTHER = "Other and one-off tests"

# Names the keyword rules would misplace (lower case).
OVERRIDES = {
    "addfact": "Quests, facts, journal and glossary",
    "addgameplayfact": "Quests, facts, journal and glossary",
    "addreppoints": "Quests, facts, journal and glossary",
    "addfactdualgripstyle": "Player input and movement",
    "hidelayer": "World: time, weather, travel, map, environment",
    **{n: "Appearance: hair, beard, head" for n in
       ("addhair1", "addhair2", "addhair3", "addhairdlc1", "addhairdlc2", "addhairdlc3")},
}

EXEC_RE = re.compile(r"^\s*exec\s+function\s+(\w+)\s*\((.*?)\)\s*(?::\s*(\w+))?", re.S)


def git(*args: str) -> str:
    return subprocess.run(["git", *args], cwd=ROOT, capture_output=True, check=True,
                          text=True, encoding="utf-8", errors="replace").stdout


def first_statement(lines: list[str], start: int) -> str:
    """The first statement in the body after a signature at index start, or ''."""
    depth = 0
    seen_brace = False
    for line in lines[start:start + 200]:
        text = line.split("//")[0].strip()
        if not seen_brace:
            if "{" in text:
                seen_brace = True
                text = text.split("{", 1)[1].strip()
                if text.startswith("}"):
                    return ""
            else:
                continue
        if text.startswith("var ") or text in ("", "{", "}"):
            depth += line.count("{") - line.count("}")
            if text == "}" and depth < 0:
                return ""
            continue
        return text.rstrip(";")[:90]
    return ""


def clean_args(args: str) -> str:
    args = re.sub(r"\s+", " ", args).strip()
    args = re.sub(r"\s*:\s*", " : ", args)
    return args


def topic_of(name: str) -> str:
    low = name.lower()
    if low in OVERRIDES:
        return OVERRIDES[low]
    for topic, pattern in TOPICS:
        if re.search(pattern, low):
            return topic
    return OTHER


def collect(ref: str) -> list[dict]:
    files = [f for f in git("ls-tree", "-r", "--name-only", ref, "--", SCRIPTS).splitlines()
             if f.endswith(".ws")]
    out = []
    for path in files:
        text = git("show", f"{ref}:{path}")
        if "exec function" not in text:
            continue
        lines = text.splitlines()
        for i, line in enumerate(lines):
            if not re.match(r"\s*exec\s+function\b", line):
                continue
            sig = " ".join(lines[i:i + 3])
            m = EXEC_RE.match(sig)
            if not m:
                continue
            name, args, ret = m.group(1), clean_args(m.group(2)), m.group(3)
            out.append({
                "name": name,
                "sig": f"{name}({args})" + (f" : {ret}" if ret else ""),
                "file": path[len(SCRIPTS):],
                "line": i + 1,
                "hint": first_statement(lines, i),
            })
    return out


def md_escape(s: str) -> str:
    return s.replace("|", "\\|")


def render(cmds: list[dict], ref: str) -> str:
    by_topic = defaultdict(list)
    for c in cmds:
        by_topic[topic_of(c["name"])].append(c)
    order = [t for t, _ in TOPICS] + [OTHER]
    files = defaultdict(int)
    for c in cmds:
        files[c["file"]] += 1

    out = [
        "# Console commands",
        "",
        "<!-- Generated by tools/exec_catalog.py; do not edit by hand. -->",
        "",
        f"Every console command (vanilla `exec function`) in the game's scripts on `{ref}`: "
        f"{len(cmds)} commands. Generated by `python tools/exec_catalog.py`; re-run it when a new "
        "game version lands on `vanilla-5.x`.",
        "",
        "**Using them.** Type a command in the in-game console (`~`), or run it from a script with "
        "`python tools/game.py exec \"<call>\"`. Write names as listed: case may matter (`addskillpoints` and `addSkillPoints` "
        "are separate functions). Arguments: numbers as is; "
        "`name` arguments and enum values (`EEffectType`, `ESkill`, `EBaseCharacterStats`, ...) as bare words "
        "(`spawn(wolf)`, `buffme(EET_Drunkenness)`); text with spaces in quotes (`additem('Viper School steel sword')`; single quotes work through `game.py exec`). "
        "Optional arguments (marked `?`) can be left out.",
        "",
        "**Caveats.**",
        "",
        "- Commands that only log (`logskills()`, `printinv()`, `statsplayer()`, ...) run, but their output never "
        "reaches the script log in the release build. Read state with `modAutomation`'s probes instead "
        "(`autoplayer()`, `autoskills()`, ...; see [game-automation.md](game-automation.md#modautomation)).",
        "- Many commands are developer tests from the original production (`test...`, numbered quest tests) and "
        "may refer to content or tags that only exist in one place in the world, or do nothing.",
        "- Online command lists describe the legacy game; the hint and the source here are what 5.x does.",
        "- ✔ marks commands tested in game on 5.x; their usage and pitfalls are in "
        "[game-automation.md](game-automation.md#setting-up-geralt-and-the-world).",
        "",
        "Columns: **Command** is the signature (`?` = optional); **Does** is the first statement of its body, as a hint; "
        "**Source** is the file under `scripts/` and line on the baseline branch. Topics are assigned by name, so a "
        "few commands sit under a loose fit.",
        "",
        "## Topics",
        "",
    ]
    for t in order:
        if by_topic[t]:
            anchor = re.sub(r"[^a-z0-9 -]", "", t.lower()).replace(" ", "-")
            out.append(f"- [{t}](#{anchor}) ({len(by_topic[t])})")
    out.append("")
    for t in order:
        if not by_topic[t]:
            continue
        out += [f"## {t}", "", "| Command | Does | Source |", "|---|---|---|"]
        for c in sorted(by_topic[t], key=lambda c: c["name"].lower()):
            sig = c["sig"].replace("optional ", "?")
            mark = " ✔" if c["name"].lower() in VERIFIED else ""
            hint = f"`{md_escape(c['hint'])}`" if c["hint"] else ""
            out.append(f"| `{md_escape(sig)}`{mark} | {hint} | `{c['file']}:{c['line']}` |")
        out.append("")
    out += ["## Commands per source file", "", "| File | Commands |", "|---|---|"]
    for f, n in sorted(files.items(), key=lambda kv: -kv[1]):
        out.append(f"| `{f}` | {n} |")
    out.append("")
    return "\n".join(out)


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--ref", default="vanilla-5.x")
    ap.add_argument("--out", default="docs/console-commands.md")
    a = ap.parse_args()
    cmds = collect(a.ref)
    (ROOT / a.out).write_text(render(cmds, a.ref), encoding="utf-8", newline="\n")
    counts = defaultdict(int)
    for c in cmds:
        counts[topic_of(c["name"])] += 1
    print(f"{len(cmds)} commands -> {a.out}")
    for t, n in sorted(counts.items(), key=lambda kv: -kv[1]):
        print(f"  {n:4} {t}")


if __name__ == "__main__":
    main()
