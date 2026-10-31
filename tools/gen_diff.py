"""Generate DIFF's ability overrides for Ghost Mode's DLC: legacy's difficulty data (docs/features/diff.md).

Takes legacy's abilities (`legacy-GM`) whole and writes them into Ghost Mode's DLC file `abilities/gm_diff.xml`,
with on_conflict="replace" where 5.x defines the name (every one so far), as a new entry otherwise. The list
grows with each DIFF slice (diff.md's port order):

- D1: DIFF-01, the four difficulty abilities `difficulty_Common*` (legacy's health and damage multipliers on
  every mode; "Death March!" without 5.x's +20% stamina regen, which STAM-08 ported, and without its +10% sign
  resistances; the inert leshen-root area nodes dropped), and DIFF-03, `PrologModifier` emptied.
- D2: DIFF-02, the expansions' per-enemy difficulty variants: every ability unit attribution.csv gives DIFF-02
  in a regular `abilities` folder (50: 37 emptied or added empty, 13 retuned, e.g. the drunken master's +50 fist
  damage on "Death March!"), legacy's entry whole. Given whole with `replace`, never `extend`: `extend` empties
  Hearts of Stone's abilities (development.md). Nine of them 5.x defines only in its NG+ files (or not at all
  in the regular ones): a plain new entry in `abilities/`; gen_ngplus.py gives the NG+ copy `replace` where 5.x's
  NG+ files define the name.
- D3: DIFF-06, Ciri's eight abilities (`opp_base_abl.xml`): her five quest abilities and her rage, and her
  enemies' "Death March!" adjustment `CiriHardcoreDebuffHuman`/`...Monster` (attack power x0; 5.x: +0.7, +0.6).
- D5b: DIFF-04, the scaling menu's five health and damage step abilities `ModSigns*` (`monster_base_abl_new.xml`,
  new in legacy: +/-0.1 `health_final_multiplier` or `damage_final_multiplier` each, -0.99 health at -100%).
- DIFF audit F3 (owner, 2026-10-31): the port's own finer steps (`OWN`, not legacy's): +/-1, 0.01 and 0.001 of each
  multiplier, `GM_ScalingHealth_*` and `GM_ScalingDamage_*`, for the modifiers' (1 + mode) x (1 + enemy + boss)
  (GMAddOptionBonuses adds them with legacy's 0.1 steps). Written as given; --verify checks them as written.

One home per ability (PD2): the abilities listed here leave STAM-08's `gm_npc_stamina.xml`
(gen_npc_stamina.py's OWNED). New Game+: `abilities_plus/gm_diff.xml` is written by gen_ngplus.py from the
regular file (run it afterwards); legacy's NG+ entries equal its regular ones, and gen_ngplus keeps legacy's
value where legacy gave NG and NG+ the same (PD9). --verify checks both folders.

    python tools/gen_diff.py [--worktree DIR] [--check | --verify]

Writes `abilities/gm_diff.xml` in Ghost Mode's DLC (default worktree ../TGM-5x-GM) and the in-game data test
`tests/gmTestsDiffData.ws` (every numeric attribute of every listed ability, legacy's or 5.x's, read as the game
must read it: legacy's sums, 0 where only 5.x has the attribute; read by GMTest_diffdata in the regression run).
--check writes nothing and fails if a file is out of date.

--verify writes nothing and compares what the game reads (Ghost Mode's DLC over 5.x) with legacy's entry, for
every listed ability in `abilities` and `abilities_plus`, node by node; fails on any difference or on a listed
name defined twice in a DLC folder.
"""
import argparse, csv, os, re, sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from gen_ench import ability_stats  # noqa: E402
from gen_ai import show, all_abilities, strip, indent, dlc_abilities, sums, fnum  # noqa: E402

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DLC = "modGhostMode/files/dlc/dlcghostmode/data/gameplay/"
OUT = "gm_diff.xml"
COMMON = "modGhostMode/files/gameplay/%s/common_abilities.xml"
MONSTER_NEW = "modGhostMode/files/gameplay/%s/monster_base_abl_new.xml"
OPP = "modGhostMode/files/gameplay/%s/opp_base_abl.xml"
TESTS = "modGhostMode/scripts/local/gm/tests/gmTestsDiffData.ws"

# (legacy path pattern, comment, abilities), in port order.
SPEC = [
    (COMMON, "DIFF-01: the difficulty modes' enemy health and damage multipliers (legacy's: x0.5/x0.75, x1/x1, x2/x2, "
             "x2.5/x3.5; Death March without 5.x's stamina regen (STAM-08) and sign resistances; legacy's whole)",
     ["difficulty_CommonEasy", "difficulty_CommonMedium", "difficulty_CommonHard", "difficulty_CommonHardcore"]),
    (MONSTER_NEW, "DIFF-03: the prologue's attack-power cut emptied (legacy's empty entry; 5.x's OnSpawned still adds it)",
     ["PrologModifier"]),
    (OPP, "DIFF-06: Ciri's quest stats (armor 150 to 320, more health and attack power on Skellige, frost immunity in "
          "the last two fights, her rage's health halved) and her enemies' Death March adjustment zeroed (legacy's whole)",
     ["Ciri_Q205", "Ciri_Q305", "Ciri_Q403", "Ciri_Q111", "Ciri_Q501", "Ciri_Rage",
      "CiriHardcoreDebuffHuman", "CiriHardcoreDebuffMonster"]),
    (MONSTER_NEW, "DIFF-04: the enemy scaling menu's health and damage steps (+/-10% of the difficulty's multipliers "
                  "each, -99% health at -100%; added by GMAddOptionBonuses, legacy's ModSignsAddBonuses)",
     ["ModSignsAdditionalHealth", "ModSignsAdditionalHealthNegative", "ModSignsMaxHealthNegative",
      "ModSignsAdditionalDamage", "ModSignsAdditionalDamageNegative"]),
]
# The port's own abilities (no legacy entry): (comment, [(name, attribute, value)]).
OWN = [
    ("DIFF-04 (DIFF audit F3, owner 2026-10-31): the port's finer steps of the scaling modifiers (+/-1, 0.01, 0.001 of "
     "the difficulty's multipliers; with legacy's 0.1 steps above, (1 + mode) x (1 + enemy + boss); GMAddOptionBonuses)",
     [("GM_Scaling%s_%s%s" % (k, "p" if sign > 0 else "n", step), attr, sign * float(step))
      for k, attr in [("Health", "health_final_multiplier"), ("Damage", "damage_final_multiplier")]
      for step in ["1", "0.01", "0.001"] for sign in (1, -1)]),
]
DIFF02 = "DIFF-02"
_spec = []


def diff02():
    """[(legacy path pattern, comment, names)] of DIFF-02's variants, one group per legacy file, from attribution.csv
    (the regular folder's units; legacy's NG+ entries equal its regular ones and come from gen_ngplus.py)."""
    groups = {}
    with open(os.path.join(REPO, "docs/features/attribution.csv"), encoding="utf-8") as f:
        for row in csv.reader(f):
            m = re.match(r"files/((?:.*/)?)gameplay/abilities/([^/]+\.xml)::definitions/abilities/ability:(.+)$", row[0])
            if not m or DIFF02 not in row[1].split():
                continue
            pattern = "modGhostMode/files/%sgameplay/%%s/%s" % (m.group(1), m.group(2))
            groups.setdefault(pattern, []).append(m.group(3))
    return [(p, "DIFF-02: per-enemy difficulty variants of %s (legacy's whole: emptied, added empty or retuned)"
             % (p % "abilities").split("modGhostMode/files/")[1], names) for p, names in groups.items()]


def spec():
    """SPEC and DIFF-02's variants: [(legacy path pattern, comment, names)]."""
    if not _spec:
        _spec.extend(SPEC + diff02())
    return _spec


def owned():
    """{ability: output file} of every ability this tool writes (gen_npc_stamina.py leaves them out)."""
    own = {n: OUT for _, _, names in spec() for n in names}
    own.update({n: OUT for _, items in OWN for n, _, _ in items})
    return own


def own_entry(name, attr, value):
    return ('<ability name="%s">\n<%s type="add" min="%s" />\n</ability>' % (name, attr, fnum(value)))


def own_entries():
    """[(name, entry)] of the port's own abilities."""
    return [(n, own_entry(n, a, v)) for _, items in OWN for n, a, v in items]


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


def build():
    lines = ['<?xml version="1.0" encoding="UTF-8"?>', "<!-- Generated by tools/gen_diff.py from legacy-GM; do not edit. -->",
             "<redxml>", "\t<definitions>", "\t\t<abilities>"]
    for pattern, comment, names in spec():
        lines.append("\t\t\t<!-- %s -->" % comment)
        for n in names:
            lines.append(indent(want(n, pattern, "abilities")))
    for comment, items in OWN:
        lines.append("\t\t\t<!-- %s -->" % comment)
        for n, a, v in items:
            if all_abilities("vanilla-5.x", "abilities").get(n) is not None:
                raise SystemExit("5.x defines %s: the port's own ability needs another name" % n)
            lines.append(indent(own_entry(n, a, v)))
    lines += ["\t\t</abilities>", "\t</definitions>", "</redxml>", ""]
    return "﻿" + "\n".join(lines).replace("\n", "\r\n")


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
        for pattern, _, names in spec():
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
        for name, w in own_entries():
            final = gm.get(name)
            if final is None or ability_stats(final) != ability_stats(w):
                print("DIFF %s: the port's own ability %s is not as written: %s" % (folder, name, final))
                bad = 1
            else:
                n += 1
        print("%s: %d abilities as meant" % (folder, n))
    print("verify:", "differences found" if bad else "no difference")
    return bad


def checks():
    """[(ability, attribute, (base, mult, add))]: every numeric attribute legacy's or 5.x's entry has, with
    legacy's sums (0 where only 5.x has it)."""
    res = []
    for pattern, _, names in spec():
        for name in names:
            w = sums(want(name, pattern, "abilities"))
            v = sums(all_abilities("vanilla-5.x", "abilities").get(name))
            for tag in list(w) + [t for t in v if t not in w]:
                res.append((name, tag, tuple(w.get(tag, [0.0, 0.0, 0.0]))))
    for name, w in own_entries():
        for tag, v in sums(w).items():
            res.append((name, tag, tuple(v)))
    return res


def build_tests():
    cs = checks()
    out = ["// Generated by tools/gen_diff.py; do not edit. DIFF's data as the game reads it (docs/features/diff.md):",
           "// every numeric attribute of every ability DIFF gives, legacy's or 5.x's, with legacy's value (0 where only",
           "// 5.x has the attribute: Death March's stamina regen and sign resistances, the root area nodes, the",
           "// prologue cut, the emptied per-enemy variants' nodes). Base, mult and add are the sums",
           "// GetAbilityAttributeValue returns (min values).",
           "",
           "function GMTestDiffDataAll(out checks : int) : int",
           "{",
           "\tvar f : int;",
           ""]
    for name, attr, (b, m, a) in cs:
        out.append("\tf += GMTestDiffNode('%s', '%s', %s, %s, %s, checks);" % (name, attr, fnum(b), fnum(m), fnum(a)))
    out += ["\treturn f;", "}", "", "function GMTestDiffDataAbilities() : int", "{",
            "\treturn %d;" % len({c[0] for c in cs}), "}", "", "function GMTestDiffDataChecks() : int", "{",
            "\treturn %d;" % len(cs), "}"]
    return "\n".join(out) + "\n"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--worktree", default=os.path.join(os.path.dirname(REPO), "TGM-5x-GM"))
    ap.add_argument("--check", action="store_true")
    ap.add_argument("--verify", action="store_true")
    a = ap.parse_args()
    if a.verify:
        sys.exit(verify(a.worktree))
    bad = 0
    for path, make in [(os.path.join(a.worktree, DLC, "abilities", OUT), build), (os.path.join(a.worktree, TESTS), build_tests)]:
        text = make()
        old = open(path, encoding="utf-8", newline="").read() if os.path.exists(path) else None
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
