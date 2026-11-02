"""Generate XP's ability overrides for Ghost Mode's DLC and XP's in-game data test (docs/features/xp.md).

Slice X1:

- XP-08, the level-up abilities `Lvl2` to `Lvl50` (`gameplay/abilities/geralt_stats.xml`): legacy's entries whole
  (+50 Vitality each, no attack power or spell power), `on_conflict="replace"`, in `abilities/gm_xp.xml`. 5.x adds
  them at each level-up (`W3LevelManager.AddPoints` through `W3PlayerWitcher.GetLevelupAbility`) and Geralt holds
  them by name, so their values are read live. New Game+: gen_ngplus.py writes `abilities_plus/gm_xp.xml` from the
  regular file (run it afterwards); legacy's NG+ entries equal its regular ones, as 5.x's do. 5.x's NG+ `Lvl51` to
  `Lvl100` are already empty (as 1.32's, one of them misnamed `Lvl60`), so legacy's deletion of them needs no entry.
- XP-05, the enemies' `experience` nodes: gen_ai.py writes them (XP in its PORTED); this tool only reads them for
  the data test.

Slice X2:

- XP-02, the rewards' experience and levels: gen_loot.py writes them into its reward overrides (legacy's `experience`
  and `level`, gold ECON's since slice E4, DX4's Killbill branch at level 16); this tool reads them for the data test and checks them
  in --verify, independently of gen_loot.py's merge (every reward of the six files, each attribute once).
- XP-03, the quest-level tables: whole-file overrides of the four tables (PX3), 5.x's rows with legacy's changes against
  1.32 (values changed; rows removed: `mq2040_trial_of_power`; rows added, appended), so 5.x's own row
  (`mq1060_devils_pit`) stays. Written by this tool (`QUEST_LEVELS`).

Slice X5:

- XP-09, the new tree's level abilities (DX1 (a), DX2 (a)): `GMLvlNew2` to `GMLvlNew100`, plain new entries in the same
  file, from `NEW_TREE_VITALITY`: +150 Vitality on levels 3, 6, ..., 48 and nothing on the others (those entries hold
  only the `base` tag). `xp/levelUp.ws`'s wrapper of `GetLevelupAbility` gives them while the new tree's profile is in
  force; the ones Geralt holds also record under which tree's rule each level was gained (the character reset reads
  them). Also writes `xp/levelNames.ws`: `GMClassicLevelAbility(n)` (5.x's `Lvl<n>`, '' past 50) and
  `GMNewTreeLevelAbility(n)`, since WitcherScript cannot build a name from a string.

    python tools/gen_xp.py [--worktree DIR] [--check | --verify]

Writes `abilities/gm_xp.xml` in Ghost Mode's DLC (default worktree ../TGM-5x-GM), `xp/levelNames.ws` and the in-game data test
`tests/gmTestsXpData.ws` (read by GMTest_xpdata in the regression run): every numeric attribute of the level
abilities, legacy's or 5.x's (0 where only 5.x has it: attack power, spell power), and every `experience` node of
the abilities gen_ai.py writes, legacy's (0 where legacy dropped it). --check writes nothing and fails if a file is
out of date.

--verify writes nothing and compares what the game reads (Ghost Mode's DLC over 5.x) with legacy's entry, for every
level ability in `abilities` and `abilities_plus`, node by node, and the experience nodes of gen_ai.py's abilities
with legacy's; fails on any difference or on a listed name defined twice in a DLC folder.
"""
import argparse, csv, os, re, subprocess, sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from gen_ench import ability_stats  # noqa: E402
import gen_ai  # noqa: E402
from gen_ai import show, all_abilities, strip, indent, dlc_abilities, sums, fnum  # noqa: E402

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DLC = "modGhostMode/files/dlc/dlcghostmode/data/gameplay/"
OUT = "gm_xp.xml"
GERALT = "modGhostMode/files/gameplay/%s/geralt_stats.xml"
TESTS = "modGhostMode/scripts/local/gm/tests/gmTestsXpData.ws"
TESTS_X2 = "modGhostMode/scripts/local/gm/tests/gmTestsXpQuestData.ws"
NAMES_WS = "modGhostMode/scripts/local/gm/xp/levelNames.ws"

# XP-02: the reward files legacy changed (base game, Hearts of Stone, Blood and Wine, three free DLCs).
REWARDS = ["modGhostMode/files/gameplay/rewards/rewards.xml"] + [
    "modGhostMode/files/dlc/%s/data/gameplay/rewards/rewards.xml" % d for d in ("ep1", "bob", "dlc3", "dlc12", "dlc15")]
# 5.x's new rewards with experience, checked in the data test (5.x's values; the Killbill branch DX4's).
NEW_REWARDS_CHECKED = ["q504_horse_returned", "sq106_3_hammond_killed_crach", "mq1060_priest_reward", "mq1060_priest_dead_reward"]
# XP-03: the quest-level tables Ghost Mode overrides. The game loads the DLCs' tables first (their quest mounters, also
# dlc3's, dlc12's and dlc15's) and the base game's last (OnGameStarting); a name in two tables would show the base game's.
QUEST_LEVELS = ["modGhostMode/files/gameplay/globals/quest_levels.csv",
                "modGhostMode/files/dlc/ep1/data/gameplay/globals/quest_levels.csv",
                "modGhostMode/files/dlc/bob/data/gameplay/globals/quest_levels.csv",
                "modGhostMode/files/dlc/dlc10/data/gameplay/globals/th1009_quest_levels_copy.csv"]
# The other tables the game loads, unchanged (5.x's; legacy's base-game rows for mh201 and mq2052 repeat dlc3's and
# dlc12's at the same levels).
QUEST_LEVELS_OTHER = ["modGhostMode/files/dlc/%s/data/gameplay/globals/quest_levels.csv" % d for d in ("dlc3", "dlc12", "dlc15")]
# 5.x's quest-level rows kept (DX4 (a)), checked in the data test.
NEW_QUEST_ROWS = ["mq1060_devils_pit"]

LEVELS = ["Lvl%d" % n for n in range(2, 51)]
SPEC = [
    (GERALT, "XP-08: the level-up abilities, +50 Vitality per level and nothing else (legacy's whole; 5.x: Vitality "
             "100 falling to 25, attack power +4 to +1, spell power +2% to +0.1%)", LEVELS),
]

# Slice X5 (XP-09): the new tree's Vitality per level by DX1 (a) and DX2 (a), {level: Vitality}, written as
# GMLvlNew<n>: levels 3, 6, ..., 48 +150, every other level to 100 nothing (no point on every third level, also past 50,
# is xp/levelUp.ws's; no level past 50 gives Vitality).
NEW_TREE_VITALITY = {n: (150 if n % 3 == 0 and n <= 50 else 0) for n in range(2, 101)}
NEW_COMMENT = ("XP-09: the new tree's level abilities (DX1 (a), DX2 (a)): +150 Vitality on levels 3, 6, ..., 48, nothing on "
               "the others (to 100); the ones Geralt holds record which levels he gained under the new tree's rule")


def new_entry(n):
    v = NEW_TREE_VITALITY[n]
    node = ' <vitality type="base" always_random="false" min="%d" max="%d" />' % (v, v) if v else ""
    return '<ability name="GMLvlNew%d">  <tags> "base" </tags>%s </ability>' % (n, node)


def entry(name, legacy, vanilla):
    """Legacy's entry whole; head with on_conflict="replace" if 5.x defines the name."""
    body = strip(legacy)
    head = '<ability name="%s"%s>' % (name, ' on_conflict="replace"' if vanilla else "")
    return re.sub(r'^<ability\s+name\s*=\s*"[^"]+"[^>]*>', head, body)


def want(name, pattern, folder):
    legacy = show("legacy-GM", pattern % folder).get(name)
    if legacy is None:
        raise SystemExit("legacy-GM has no %s in %s" % (name, pattern % folder))
    return entry(name, legacy, all_abilities("vanilla-5.x", folder).get(name))


def owned():
    return {n for _, _, names in SPEC for n in names}


def build():
    lines = ['<?xml version="1.0" encoding="UTF-8"?>', "<!-- Generated by tools/gen_xp.py from legacy-GM; do not edit. -->",
             "<redxml>", "\t<definitions>", "\t\t<abilities>"]
    for pattern, comment, names in SPEC:
        lines.append("\t\t\t<!-- %s -->" % comment)
        for n in names:
            lines.append(indent(want(n, pattern, "abilities")))
    lines.append("\t\t\t<!-- %s -->" % NEW_COMMENT)
    for n in sorted(NEW_TREE_VITALITY):
        lines.append(indent(new_entry(n)))
    lines += ["\t\t</abilities>", "\t</definitions>", "</redxml>", ""]
    return "﻿" + "\n".join(lines).replace("\n", "\r\n")


def ai_experience():
    """[(ability, (base, mult, add))]: the experience node of every regular ability gen_ai.py writes whose
    legacy or 5.x entry has one, as the port's entry has it (legacy's; 0 where legacy dropped it)."""
    da5 = {n: b for _, n, b in gen_ai.DA5}
    part = dict(gen_ai.part_units())
    names = [(n, p % "abilities") for _, p, _, ns in gen_ai.SPEC for n in ns]
    names += [(u[3], u[2] % u[1]) for u in gen_ai.auto_units() if u[1] == "abilities"]
    names += [(n, None) for n in da5] + [(n, "PART") for n in part]
    res, seen = [], set()
    for name, src in names:
        if name in seen:
            continue
        seen.add(name)
        vanilla = all_abilities("vanilla-5.x", "abilities").get(name)
        if src is None:
            legacy = w = da5[name]
        elif src == "PART":
            legacy, w = vanilla, gen_ai.part_want(name, part[name])
        else:
            legacy = show("legacy-GM", src)[name]
            w = gen_ai.entry(name, legacy, vanilla)
        if any("experience" in sums(x) for x in (legacy, vanilla) if x):
            res.append((name, tuple(sums(w).get("experience", [0.0, 0.0, 0.0]))))
    return res


def legacy_experience(name):
    """Legacy's experience sums of a gen_ai.py ability (for --verify), or None if it is not legacy's whole."""
    for _, p, _, ns in gen_ai.SPEC:
        if name in ns:
            return sums(show("legacy-GM", p % "abilities")[name]).get("experience", [0.0, 0.0, 0.0])
    for u in gen_ai.auto_units():
        if u[1] == "abilities" and u[3] == name:
            return sums(show("legacy-GM", u[2] % u[1])[name]).get("experience", [0.0, 0.0, 0.0])
    return None


def verify(worktree):
    bad = 0
    own = owned()
    for folder in ["abilities", "abilities_plus"]:
        gm, dup = dlc_abilities(worktree, folder)
        for d in dup:
            if re.match(r"ability (.+) twice in", d).group(1) in own:
                print("DUPLICATE", d)
                bad = 1
        vanilla = all_abilities("vanilla-5.x", folder)
        n = 0
        for pattern, _, names in SPEC:
            for name in names:
                final = gm.get(name, vanilla.get(name))
                w = want(name, pattern, folder)  # legacy's NG+ entry for abilities_plus
                a, b = ability_stats(final or ""), ability_stats(w)
                if final is None or a != b:
                    print("DIFF %s: ability %s\n  port only:     %s\n  expected only: %s" % (
                        folder, name, [x for x in a if x not in b], [x for x in b if x not in a]))
                    bad = 1
                else:
                    n += 1
        print("%s: %d level abilities as legacy's" % (folder, n))
        m = 0
        for lv in sorted(NEW_TREE_VITALITY):
            name = "GMLvlNew%d" % lv
            want_s = {"vitality": [float(NEW_TREE_VITALITY[lv]), 0.0, 0.0]} if NEW_TREE_VITALITY[lv] else {}
            if name in vanilla or name not in gm or sums(gm[name]) != want_s:
                print("DIFF %s: ability %s reads %s, expected %s" % (folder, name, sums(gm.get(name)) if name in gm else None, want_s))
                bad = 1
            else:
                m += 1
        print("%s: %d new-tree level abilities as XP-09's rule (DX1, DX2)" % (folder, m))
    gm, _ = dlc_abilities(worktree, "abilities")
    vanilla = all_abilities("vanilla-5.x", "abilities")
    n = changed = 0
    for name, _ in ai_experience():
        got = sums(gm.get(name, vanilla.get(name)) or "").get("experience", [0.0, 0.0, 0.0])
        leg = legacy_experience(name)
        if leg is None:  # DA5's or PART's: the port's own entry, checked by gen_ai.py --verify
            continue
        if got != leg:
            print("DIFF abilities: %s experience %s, legacy's %s" % (name, got, leg))
            bad = 1
        else:
            n += 1
            changed += sums(vanilla.get(name) or "").get("experience", [0.0, 0.0, 0.0]) != leg
    print("abilities: %d experience nodes as legacy's (%d differ from 5.x's)" % (n, changed))
    print("verify:", "differences found" if bad else "no difference")
    return bad


def checks():
    """[(ability, attribute, (base, mult, add))]: every numeric attribute of the level abilities, legacy's or 5.x's,
    with legacy's sums (0 where only 5.x has it); then the experience nodes of gen_ai.py's abilities."""
    res = []
    for pattern, _, names in SPEC:
        for name in names:
            w = sums(want(name, pattern, "abilities"))
            v = sums(all_abilities("vanilla-5.x", "abilities").get(name))
            for tag in list(w) + [t for t in v if t not in w]:
                res.append((name, tag, tuple(w.get(tag, [0.0, 0.0, 0.0]))))
    for n in sorted(NEW_TREE_VITALITY):
        res.append(("GMLvlNew%d" % n, "vitality", (float(NEW_TREE_VITALITY[n]), 0.0, 0.0)))
    lv = len(res)
    res += [(n, "experience", v) for n, v in ai_experience()]
    return res, lv


def build_tests():
    cs, lv = checks()
    out = ["// Generated by tools/gen_xp.py; do not edit. XP's data as the game reads it (docs/features/xp.md):",
           "// XP-08, every numeric attribute of the level-up abilities Lvl2 to Lvl50, legacy's (Vitality 50; 0 for 5.x's",
           "// attack power and spell power); XP-09, the Vitality of the new tree's GMLvlNew2 to GMLvlNew100 (150 on levels 3,",
           "// 6, ..., 48, else 0); XP-05, the experience node of every ability gen_ai.py gives that has one in",
           "// legacy or 5.x, legacy's (0 where legacy dropped it). Base, mult and add are the sums",
           "// GetAbilityAttributeValue returns (min values). One function per group: compiler memory.",
           ""]
    groups = [cs[i:i + 60] for i in range(0, len(cs), 60)]
    for k, g in enumerate(groups, 1):
        out += ["function GMTestXpData%d(out checks : int) : int" % k, "{", "\tvar f : int;", ""]
        for name, attr, (b, m, a) in g:
            out.append("\tf += GMTestXpNode('%s', '%s', %s, %s, %s, checks);" % (name, attr, fnum(b), fnum(m), fnum(a)))
        out += ["\treturn f;", "}", ""]
    out += ["function GMTestXpDataAll(out checks : int) : int", "{", "\tvar f : int;", ""]
    out += ["\tf += GMTestXpData%d(checks);" % k for k in range(1, len(groups) + 1)]
    out += ["\treturn f;", "}", "",
            "function GMTestXpDataLevelChecks() : int", "{", "\treturn %d;" % lv, "}", "",
            "function GMTestXpDataExpChecks() : int", "{", "\treturn %d;" % (len(cs) - lv), "}"]
    return "\n".join(out) + "\n"


def build_names():
    out = ["// Generated by tools/gen_xp.py; do not edit. The level-up abilities' names by level (docs/features/xp.md), for",
           "// XP-09 (xp/levelUp.ws): WitcherScript cannot build a name from a string.", "",
           "// XP-08: the classic tree's level ability of a level, 5.x's Lvl<n> (GetLevelupAbility's own table); '' past 50.",
           "function GMClassicLevelAbility(lvl : int) : name", "{", "\tswitch(lvl)", "\t{"]
    out += ["\t\tcase %d: return 'Lvl%d';" % (n, n) for n in range(2, 51)]
    out += ["\t}", "\treturn '';", "}", "",
            "// XP-09: the new tree's level ability of a level (GMLvlNew<n>, levels 2 to 100).",
            "function GMNewTreeLevelAbility(lvl : int) : name", "{", "\tswitch(lvl)", "\t{"]
    out += ["\t\tcase %d: return 'GMLvlNew%d';" % (n, n) for n in sorted(NEW_TREE_VITALITY)]
    out += ["\t}", "\treturn '';", "}"]
    return "\n".join(out) + "\n"


# ---- XP-02: rewards (written by gen_loot.py, checked here) ------------------------------------------------------

def _git(*args):
    return subprocess.run(["git", "-C", REPO, *args], capture_output=True).stdout.decode("utf-8-sig", errors="replace")


REWARD_HEAD = re.compile(r'<reward\s[^>]*?/?>', re.S)
ATTR = re.compile(r'(\b\w+)\s*=\s*"([^"]*)"')


def reward_heads(text):
    """{name: {attribute: value}} of every reward (comments ignored); [problems] (a name or an attribute twice)."""
    out, bad = {}, []
    text = re.sub(r'<!--.*?-->', '', text, flags=re.S)
    for m in REWARD_HEAD.finditer(text):
        attrs = ATTR.findall(m.group(0))
        d = dict(attrs)
        if len(d) != len(attrs):
            bad.append("%s: an attribute twice" % d.get("name"))
        if d.get("name") in out:
            bad.append("%s: reward twice" % d.get("name"))
        out[d.get("name")] = d
    return out, bad


def reward_units():
    """{path: {reward: features}} of the XP-02 reward units (attribution.csv)."""
    out = {}
    rx = re.compile(r'^(.*\.xml)::reward:(.+)$')
    with open(os.path.join(REPO, "docs", "features", "attribution.csv"), encoding="utf-8") as f:
        for row in csv.DictReader(f):
            m = rx.match(row["unit"])
            if m and "XP-02" in row["features"].split():
                out.setdefault("modGhostMode/" + m.group(1), {})[m.group(2)] = set(row["features"].split())
    return out


def reward_expected():
    """{path: {reward: (experience, level, gold)}} for every reward of the six files: legacy's experience and level for
    an XP-02 unit, DX4's for 5.x's new Killbill branch, else 5.x's; gold legacy's where ECON decides it (gen_loot.py's
    ECON_GOLD: ECON-10, the loan, DE1; slice E4), else 5.x's."""
    import gen_loot
    us = reward_units()
    eg = gen_loot.econ_gold_units()
    res = {}
    for path in REWARDS:
        v, _ = reward_heads(_git("show", "vanilla-5.x:" + path))
        l, _ = reward_heads(_git("show", "legacy-GM:" + path))
        new = gen_loot.NEW_REWARDS.get(path, {})
        out = {}
        for name, a in v.items():
            e, lv, g = a.get("experience", "0"), a.get("level", "0"), a.get("gold", "0")
            if name in us.get(path, {}):
                e, lv = l[name].get("experience", "0"), l[name].get("level", "0")
            if name in new:
                e, lv = new[name].get("experience", e), new[name].get("level", lv)
            if name in eg.get(path, set()):
                g = l[name].get("gold", "0")
            out[name] = (int(e), int(lv), int(g))
        for name in us.get(path, {}):
            if name not in v:
                raise SystemExit("%s: XP-02 reward %s is not in 5.x" % (path, name))
        res[path] = out
    return res


def reward_verify(worktree):
    bad, n, changed = 0, 0, 0
    exp = reward_expected()
    us = reward_units()
    for path in REWARDS:
        got, probs = reward_heads(open(os.path.join(worktree, path), encoding="utf-8-sig").read())
        v, _ = reward_heads(_git("show", "vanilla-5.x:" + path))
        for p in probs:
            print("DIFF %s: %s" % (path, p))
            bad = 1
        for name, want in exp[path].items():
            a = got.get(name)
            have = (int(a.get("experience", "0")), int(a.get("level", "0")), int(a.get("gold", "0"))) if a else None
            if have != want:
                print("DIFF %s: reward %s reads %s, expected %s (experience, level, gold)" % (path, name, have, want))
                bad = 1
            else:
                n += 1
                vv = v[name]
                changed += (int(vv.get("experience", "0")), int(vv.get("level", "0"))) != want[:2]
        extra = set(got) - set(exp[path])
        if extra:
            print("DIFF %s: rewards 5.x does not have: %s" % (path, sorted(extra)))
            bad = 1
    units = sum(len(x) for x in us.values())
    print("rewards: %d read as expected (experience and level legacy's for the %d XP-02 units, DX4's for 1, 5.x's for the "
          "rest; gold legacy's where ECON decides it, else 5.x's); %d with experience or level other than 5.x's" % (n, units, changed))
    return bad


# ---- XP-03: quest levels ------------------------------------------------------------------------------------------

def ql_rows(text):
    """[(name, level)] of a quest-level table (header left out)."""
    rows = []
    for line in text.replace("\r\n", "\n").split("\n")[1:]:
        if line.strip():
            name, level = line.rsplit(";", 1)
            rows.append((name, level))
    return rows


def ql_units():
    out = {}
    rx = re.compile(r'^(.*\.csv)::row:(.+)$')
    with open(os.path.join(REPO, "docs", "features", "attribution.csv"), encoding="utf-8") as f:
        for row in csv.DictReader(f):
            m = rx.match(row["unit"])
            if m and "XP-03" in row["features"].split():
                out.setdefault("modGhostMode/" + m.group(1), set()).add(m.group(2))
    return out


def ql_build(path):
    """5.x's table with legacy's changes against 1.32 (PX3); every row legacy changed, removed or added must be an XP-03
    unit, and 5.x must not have changed it."""
    m, l, v = (dict(ql_rows(_git("show", "%s:%s" % (r, path)))) for r in ("master", "legacy-GM", "vanilla-5.x"))
    head = _git("show", "vanilla-5.x:" + path).replace("\r\n", "\n").split("\n")[0]
    units = ql_units().get(path, set())
    changes = {n for n in set(m) | set(l) if m.get(n) != l.get(n)}
    if changes != units:
        raise SystemExit("%s: legacy's changes %s and the XP-03 units %s differ" % (path, sorted(changes - units), sorted(units - changes)))
    rows = []
    for name, level in ql_rows(_git("show", "vanilla-5.x:" + path)):
        if name in changes:
            if m.get(name) != level:
                raise SystemExit("%s: 5.x changed %s (%s, 1.32 %s)" % (path, name, level, m.get(name)))
            if name not in l:
                continue  # removed by legacy
            level = l[name]
        rows.append((name, level))
    rows += [(n, lv) for n, lv in ql_rows(_git("show", "legacy-GM:" + path)) if n not in m and n not in v]
    return "\n".join([head] + ["%s;%s" % r for r in rows]) + "\n"


def ql_expected():
    """[(row name, the level the journal reads, 0 for none)]: every XP-03 row and 5.x's kept row, as the journal finds
    them (a name in two tables has the same level in each,
    so load order does not matter: legacy's two added rows repeat dlc3's and dlc12's own)."""
    tables = [dict(ql_rows(ql_build(p))) for p in QUEST_LEVELS]
    tables += [dict(ql_rows(_git("show", "vanilla-5.x:" + p))) for p in QUEST_LEVELS_OTHER]
    names = sorted({n for us in ql_units().values() for n in us} | set(NEW_QUEST_ROWS))
    out = []
    for n in names:
        hits = [t[n] for t in tables if n in t]
        if len(set(hits)) > 1:
            raise SystemExit("quest level %s in %d tables with different levels %s" % (n, len(hits), hits))
        out.append((n, int(hits[-1]) if hits else 0))
    return out


def ql_verify(worktree):
    bad = 0
    for path in QUEST_LEVELS:
        got = open(os.path.join(worktree, path), encoding="utf-8", newline="").read().replace("\r\n", "\n")
        if got != ql_build(path):
            print("DIFF %s: not 5.x's table with legacy's rows" % path)
            bad = 1
        g, l, v, m = (dict(ql_rows(t)) for t in (got, _git("show", "legacy-GM:" + path), _git("show", "vanilla-5.x:" + path),
                                                  _git("show", "master:" + path)))
        for name in set(g) | set(l) | set(v):
            want = l.get(name) if (name in m or name in l) else v.get(name)  # legacy's row, or 5.x's own
            if g.get(name) != want:
                print("DIFF %s: %s reads %s, expected %s" % (path, name, g.get(name), want))
                bad = 1
        print("%s: %d rows as legacy's (5.x's own kept), %d differ from 5.x's" % (
            path, len(g), sum(1 for n in set(g) | set(v) if g.get(n) != v.get(n))))
    return bad


def ws_str(x):
    return '"%s"' % x.replace("\\", "\\\\").replace('"', '\\"')


def build_tests_x2():
    rws = []
    us = reward_units()
    exp = reward_expected()
    for path in REWARDS:
        for name in exp[path]:
            if name in us.get(path, {}) or name in NEW_REWARDS_CHECKED:
                rws.append((name,) + exp[path][name])
    qls = ql_expected()
    out = ["// Generated by tools/gen_xp.py; do not edit. XP's slice X2 data as the game reads it (docs/features/xp.md):",
           "// XP-02, the experience, level and gold of every XP-02 reward (legacy's experience and level; gold ECON's: legacy's,",
           "// 5.x's where ECON keeps it) and of",
           "// 5.x's four new rewards with experience (5.x's; the Killbill branch at level 16, DX4); XP-03, the level the",
           "// journal reads for every quest-level row legacy changed (0: none, mq2040_trial_of_power) and 5.x's",
           "// mq1060_devils_pit. One function per group: compiler memory.", ""]
    groups = [rws[i:i + 60] for i in range(0, len(rws), 60)]
    for k, g in enumerate(groups, 1):
        out += ["function GMTestXpRewards%d(out checks : int) : int" % k, "{", "\tvar f : int;", ""]
        out += ["\tf += GMTestXpReward('%s', %d, %d, %d, checks);" % r for r in g]
        out += ["\treturn f;", "}", ""]
    qgroups = [qls[i:i + 60] for i in range(0, len(qls), 60)]
    for k, g in enumerate(qgroups, 1):
        out += ["function GMTestXpQuestLevels%d(out checks : int) : int" % k, "{", "\tvar f : int;", ""]
        out += ["\tf += GMTestXpQuestLevel(%s, %d, checks);" % (ws_str(n), lv) for n, lv in g]
        out += ["\treturn f;", "}", ""]
    out += ["function GMTestXpRewardsAll(out checks : int) : int", "{", "\tvar f : int;", ""]
    out += ["\tf += GMTestXpRewards%d(checks);" % k for k in range(1, len(groups) + 1)]
    out += ["\treturn f;", "}", "", "function GMTestXpQuestLevelsAll(out checks : int) : int", "{", "\tvar f : int;", ""]
    out += ["\tf += GMTestXpQuestLevels%d(checks);" % k for k in range(1, len(qgroups) + 1)]
    out += ["\treturn f;", "}", "",
            "function GMTestXpRewardChecks() : int", "{", "\treturn %d;" % len(rws), "}", "",
            "function GMTestXpQuestLevelChecks() : int", "{", "\treturn %d;" % len(qls), "}"]
    return "\n".join(out) + "\n"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--worktree", default=os.path.join(os.path.dirname(REPO), "TGM-5x-GM"))
    ap.add_argument("--check", action="store_true")
    ap.add_argument("--verify", action="store_true")
    a = ap.parse_args()
    if a.verify:
        bad = verify(a.worktree)
        bad |= reward_verify(a.worktree)
        bad |= ql_verify(a.worktree)
        print("verify (X2):", "differences found" if bad else "no difference")
        sys.exit(bad)
    bad = 0
    outs = [(os.path.join(a.worktree, DLC, "abilities", OUT), build), (os.path.join(a.worktree, TESTS), build_tests),
            (os.path.join(a.worktree, TESTS_X2), build_tests_x2), (os.path.join(a.worktree, NAMES_WS), build_names)]
    outs += [(os.path.join(a.worktree, p), (lambda p=p: ql_build(p))) for p in QUEST_LEVELS]
    for path, make in outs:
        text = make()
        old = open(path, encoding="utf-8", newline="").read() if os.path.exists(path) else None
        if old is not None and old.replace(chr(13) + chr(10), chr(10)) == text.replace(chr(13) + chr(10), chr(10)):
            old = text  # line ends only: git's checkout may turn LF into CRLF
        if a.check:
            if old != text:
                print("out of date:", path)
                bad = 1
        elif old != text:
            os.makedirs(os.path.dirname(path), exist_ok=True)
            with open(path, "w", encoding="utf-8", newline="") as f:
                f.write(text)
            print("wrote", path)
    sys.exit(bad)


if __name__ == "__main__":
    main()
