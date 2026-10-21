"""Generate ENCH's ability overrides for Ghost Mode's DLC: legacy's runewords, glyphwords, runes and
glyphs (docs/features/ench.md).

Takes each listed ability from `legacy-GM` whole and writes it into Ghost Mode's DLC, with
on_conflict="replace" where `vanilla-5.x` defines it (the Hearts of Stone abilities lose their tags and
attributes under "extend", docs/development.md#xml-and-csv), as a plain new entry otherwise (legacy's
added abilities, e.g. `Glyphword 10 abl`). The list grows with each port slice (ench.md's port order):
an ability not listed keeps 5.x's definition.

New Game+ (`items_plus`): the ability as legacy's `items_plus` file has it (for the runewords and
glyphwords the same as the regular one, in legacy as in 5.x).

    python tools/gen_ench.py [--worktree DIR] [--check | --verify]

Also writes legacy's 23 enchanter schematics (ENCH-02) whole into a `<custom><gm_enchantment_schematics>`
node, which Ghost Mode's replaced schematic readers prefer to the vanilla entries.

Writes `items/gm_ench.xml` and `items_plus/gm_ench.xml` in Ghost Mode's DLC (default worktree
../TGM-5x-GM). --check writes nothing and fails if a file is out of date.

--verify (ENCH audit F10) writes nothing and compares what the game reads with legacy's data: every
ability legacy defines in the three files (runewords and glyphwords, runes and glyphs, Hearts of Stone
runes and glyphs; `items` and `items_plus`) as the port leaves it (Ghost Mode's `gm_ench.xml` entry, else
5.x's) against legacy's, attribute by attribute; the enchanter's four binary files (each must equal
5.x's file with exactly the price edits applied, `cr2w_patch.py`, with valid CRCs); and
`economy_tagmodifiers.csv` (5.x's rows but legacy's `mod_enchantment` and `mod_removeenchantment`).
Fails on any difference.
"""
import argparse, os, re, subprocess, sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DLC = "modGhostMode/files/dlc/dlcghostmode/data/gameplay/"
OUT = "gm_ench.xml"
RUNEWORDS = "modGhostMode/files/dlc/ep1/data/gameplay/%s/def_item_ep1_runewords.xml"
UPGRADES = "modGhostMode/files/gameplay/%s/def_item_upgrades.xml"
EP1_UPGRADES = "modGhostMode/files/dlc/ep1/data/gameplay/%s/def_item_ep1_upgrades.xml"
RUNES = ["Rune %s%s _Stats" % (r, t) for r in ["stribog", "dazhbog", "devana", "zoria", "morana", "triglav", "veles", "perun", "elemental"]
         for t in [" lesser", ""]] + ["Rune svarog _Stats", "Rune svarog greater _Stats"]
GLYPHS = ["Glyph %s%s _Stats" % (g, t) for g in ["aard", "axii", "igni", "quen", "yrden"] for t in [" lesser", "", " greater"]]
EP1_GLYPHS = ["Rune pierog _Stats", "Rune tvarog _Stats"] + ["Glyph %s%s _Stats" % (g, t) for g in ["warding", "binding", "mending"]
                                                            for t in [" lesser", "", " greater"]]

# (source file pattern, feature, abilities), in port order.
SPEC = [
    (RUNEWORDS, "ENCH-01: words whose definitions legacy left as 1.32's, given whole (the expansion's abilities need it)",
     ["Runeword 5 _Stats", "Glyphword 1 _Stats"]),
    (RUNEWORDS, "ENCH-10: Levity, Balance, Heft", ["Glyphword 2 _Stats", "Glyphword 3 _Stats", "Glyphword 4 _Stats"]),
    (UPGRADES, "ENCH-16: runes and glyphs (the ones legacy changed)", RUNES + GLYPHS),
    (RUNEWORDS, "ENCH-12: Retribution; ENCH-15: Entanglement, Protection", ["Glyphword 5 _Stats", "Glyphword 15 _Stats", "Glyphword 17 _Stats"]),
    (RUNEWORDS, "ENCH-13: Depletion, Rotation, Ignition, Eruption", ["Glyphword 6 _Stats", "Glyphword 7 _Stats", "Glyphword 12 _Stats", "Glyphword 20 _Stats"]),
    (RUNEWORDS, "ENCH-14: Usurpation, Beguilement (and their stack abilities), Possession",
     ["Glyphword 10 _Stats", "Glyphword 10 abl", "Glyphword 14 _Stats", "Glyphword 14 abl", "Glyphword 18 _Stats"]),
    (RUNEWORDS, "ENCH-03: Replenishment; ENCH-04: Severance", ["Runeword 1 _Stats", "Runeword 2 _Stats"]),
    (RUNEWORDS, "ENCH-05: Invigoration", ["Runeword 4 _Stats"]),
    (RUNEWORDS, "ENCH-07: Placation; ENCH-08: Rejuvenation, Elation", ["Runeword 8 _Stats", "Runeword 8 Regen", "Runeword 10 _Stats", "Runeword 12 _Stats"]),
    (RUNEWORDS, "ENCH-09: Prolongation", ["Runeword 11 _Stats"]),
    (RUNEWORDS, "ENCH-06: Dumplings", ["Runeword 6 _Stats"]),
    (EP1_UPGRADES, "ENCH-16: Hearts of Stone runes and glyphs", EP1_GLYPHS),
]

# Items: (source file pattern, feature, item, change), taken from vanilla-5.x whole with the change.
# Only what the feature changes: prices, weights and dismantling parts stay 5.x's (ECON, WGT, CRAFT).
ITEMS = [
    (EP1_UPGRADES, "ENCH-16: Pierog and Tvarog are not relics (legacy removed Relic _Stats)", "Rune pierog", ("drop", "<a>Relic _Stats</a>")),
    (EP1_UPGRADES, None, "Rune tvarog", ("drop", "<a>Relic _Stats</a>")),
]


def git(*args):
    return subprocess.run(["git", "-C", REPO] + list(args), capture_output=True, check=True).stdout.decode("utf-8-sig")


def abilities(text):
    out = {}
    for m in re.finditer(r'(?ms)^([ \t]*)<ability\s+name="([^"]+)"[^>]*>.*?</ability>', text):
        out[m.group(2)] = m.group(0)
    return out


def build(folder):
    lines = ['<?xml version="1.0" encoding="UTF-8"?>', "<!-- Generated by tools/gen_ench.py from legacy-GM; do not edit. -->",
             "<redxml>", "\t<definitions>", "\t\t<abilities>"]
    for pattern, feature, names in SPEC:
        path = pattern % folder
        legacy = abilities(git("show", "legacy-GM:" + path))
        vanilla = abilities(git("show", "vanilla-5.x:" + path))
        lines.append("\t\t\t<!-- %s -->" % feature)
        for n in names:
            body = legacy[n].strip()
            body = re.sub(r'\s*<!--\s*modSigns\s*-->', '', body)
            head = '<ability name="%s"%s>' % (n, ' on_conflict="replace"' if n in vanilla else "")
            body = re.sub(r'^<ability\s+name="[^"]+"[^>]*>', head, body)
            body = "\n".join("\t\t\t" + l.strip() if i in (0, body.count("\n")) else "\t\t\t\t" + l.strip()
                             for i, l in enumerate(body.split("\n")) if l.strip())
            lines.append(body)
    lines += ["\t\t</abilities>", "\t\t<items>"]
    for pattern, feature, item, change in ITEMS:
        text = git("show", "vanilla-5.x:" + pattern % folder)
        m = re.search(r'(?ms)^[ \t]*<item\s+name\s*="%s".*?</item>' % re.escape(item), text)
        body = m.group(0).strip()
        if change[0] == "drop":
            body = re.sub(r'\s*' + re.escape(change[1]), '', body, count=1)
        body = body.replace("<item", '<item on_conflict="replace"', 1)
        if feature:
            lines.append("\t\t\t<!-- %s -->" % feature)
        lines.append("\n".join(("\t\t\t" if l.strip().startswith(("<item", "</item", ">")) else "\t\t\t\t") + l.strip()
                               for l in body.split("\n") if l.strip()))
    lines += ["\t\t</items>", "\t</definitions>"]
    # ENCH-02: legacy's enchanter schematics (fee, enchanter level, runes or glyphs) whole, in a custom
    # node of Ghost Mode's own: a schematic cannot be overridden (every <schematic> of a name is read),
    # so the replaced readers (enchantments/enchanter.ws) take a schematic from here before the vanilla one.
    lines += ["\t<custom>", "\t\t<!-- ENCH-02: legacy's enchanter schematics, read before the vanilla ones -->",
              "\t\t<gm_enchantment_schematics>"]
    text = git("show", "legacy-GM:" + RUNEWORDS % folder)
    for m in re.finditer(r'(?ms)^[ \t]*<schematic\s.*?</schematic>', text):
        body = re.sub(r'\s*<!--.*?-->', '', m.group(0).strip())
        lines.append("\n".join(("\t\t\t" if l.strip().startswith(("<schematic", "</schematic", ">")) else "\t\t\t\t") + l.strip()
                               for l in body.split("\n") if l.strip()))
    lines += ["\t\t</gm_enchantment_schematics>", "\t</custom>", "</redxml>", ""]
    return "\ufeff" + "\n".join(lines).replace("\r\n", "\n").replace("\n", "\r\n")


# ENCH-02's binary price edits: (file, [(class, property, 5.x value, legacy value)]).
BINARIES = [
    ("modGhostMode/files/dlc/ep1/data/gameplay/community/dialogues/shop_enchanter_01_lvl_0.w2scene",
     [("CPayStorySceneChoiceAction", "money", 5000, 3000)]),
    ("modGhostMode/files/dlc/ep1/data/gameplay/community/dialogues/shop_enchanter_01_lvl_1.w2scene",
     [("CPayStorySceneChoiceAction", "money", 10000, 6000)]),
    ("modGhostMode/files/dlc/ep1/data/gameplay/community/dialogues/shop_enchanter_01_lvl_2.w2scene",
     [("CPayStorySceneChoiceAction", "money", 15000, 9000)]),
    ("modGhostMode/files/dlc/ep1/data/quests/mq6005_enchanter.w2phase",
     [("W3QuestCond_IsItemQuantityMet", "count", 5000, 3000)]),
]
CSV = "modGhostMode/files/gameplay/globals/economy_tagmodifiers.csv"
CSV_ROWS = ["mod_enchantment", "mod_removeenchantment"]


def git_bytes(*args):
    return subprocess.run(["git", "-C", REPO] + list(args), capture_output=True, check=True).stdout


def norm_value(v):
    try:
        return repr(float(v))
    except ValueError:
        return v


def ability_stats(body):
    """An ability as a sorted list of its nodes: (tag, sorted attributes) and the tags' text."""
    body = re.sub(r'(?s)<!--.*?-->', '', body)
    body = re.sub(r'^\s*<ability\b[^>]*>', '', body.strip())
    body = re.sub(r'</ability>\s*$', '', body)
    out = []
    for m in re.finditer(r'(?s)<(\w+)\b([^>]*?)(/?)>(?:(.*?)</\1>)?', body):
        attrs = tuple(sorted((k, norm_value(v)) for k, v in re.findall(r'(\w+)\s*=\s*"([^"]*)"', m.group(2))))
        text = " ".join((m.group(4) or "").split()) if m.group(3) != "/" else ""
        out.append((m.group(1), attrs, text))
    return sorted(out)


def verify(worktree):
    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    import cr2w_patch
    bad = 0
    for folder in ["items", "items_plus"]:
        gm = abilities(open(os.path.join(worktree, DLC, folder, OUT), encoding="utf-8-sig").read())
        n = 0
        for pattern in [RUNEWORDS, UPGRADES, EP1_UPGRADES]:
            path = pattern % folder
            legacy = abilities(git("show", "legacy-GM:" + path))
            vanilla = abilities(git("show", "vanilla-5.x:" + path))
            for name, body in legacy.items():
                final = gm.get(name, vanilla.get(name))
                n += 1
                if final is None:
                    print("MISSING %s: %s (legacy defines it, the port does not)" % (folder, name))
                    bad = 1
                elif ability_stats(final) != ability_stats(body):
                    a, b = ability_stats(final), ability_stats(body)
                    print("DIFF %s: %s\n  port only:   %s\n  legacy only: %s" % (
                        folder, name, [x for x in a if x not in b], [x for x in b if x not in a]))
                    bad = 1
        print("abilities %s: %d compared with legacy's" % (folder, n))
    for path, edits in BINARIES:
        port = open(os.path.join(worktree, path), "rb").read()
        expected, changes, hit = cr2w_patch.patch(git_bytes("show", "vanilla-5.x:" + path), edits)
        ok = port == expected and cr2w_patch.check_crcs(port) and len(hit) == len(edits)
        print("%s %s: %s" % ("ok  " if ok else "DIFF", os.path.basename(path), "; ".join(changes)))
        bad |= not ok
    rows = lambda text: [l for l in text.replace("\r", "").split("\n") if l]
    port = rows(open(os.path.join(worktree, CSV), encoding="utf-8-sig", newline="").read())
    vanilla = rows(git("show", "vanilla-5.x:" + CSV))
    legacy = {l.split(";")[0]: l for l in rows(git("show", "legacy-GM:" + CSV))}
    expected = [legacy[l.split(";")[0]] if l.split(";")[0] in CSV_ROWS else l for l in vanilla]
    ok = port == expected
    print("%s %s: 5.x's %d rows, legacy's %s" % ("ok  " if ok else "DIFF", os.path.basename(CSV), len(vanilla), ", ".join(CSV_ROWS)))
    if not ok:
        for a, b in zip(port, expected):
            if a != b:
                print("  port:     %s\n  expected: %s" % (a, b))
        bad = 1
    print("verify:", "differences found" if bad else "no difference")
    return int(bad)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--worktree", default=os.path.join(os.path.dirname(REPO), "TGM-5x-GM"))
    ap.add_argument("--check", action="store_true")
    ap.add_argument("--verify", action="store_true")
    a = ap.parse_args()
    if a.verify:
        sys.exit(verify(a.worktree))
    bad = 0
    for folder in ["items", "items_plus"]:
        path = os.path.join(a.worktree, DLC, folder, OUT)
        text = build(folder)
        old = open(path, encoding="utf-8", newline="").read() if os.path.exists(path) else None
        if a.check:
            if old != text:
                print("out of date:", path)
                bad = 1
        elif old != text:
            with open(path, "w", encoding="utf-8", newline="") as f:
                f.write(text)
            print("wrote", path)
    sys.exit(bad)


if __name__ == "__main__":
    main()
