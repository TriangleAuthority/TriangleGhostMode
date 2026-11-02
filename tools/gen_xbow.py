"""Generate XBOW's ability overrides for Ghost Mode's DLC: legacy's bolts, crossbows and NPC bows
(docs/features/xbow.md).

Takes each listed ability from `legacy-GM` whole and writes it into Ghost Mode's DLC with
on_conflict="replace" (legacy removed nodes: the Bait and Tracking bolts' 1.32 armor piercing, two
`duration` nodes). The list grows with each port slice (xbow.md's port order): an ability not listed
keeps 5.x's definition. The `weight` nodes of a crossbow ability stay 5.x's (WGT's), placed last.

The bolt and crossbow items' XBOW fields (XBOW-03's sale tags, XBOW-02's base abilities of the two
quest crossbows) are not written here: `item_layer.py` holds them and `gen_item.py` writes the items
(one entry per name, with ITEM's and CRAFT's fields): run gen_item.py after this tool.

New Game+ (`items_plus`): the ability as legacy's `items_plus` file has it (equal to the regular one
in 1.32, legacy and 5.x, xbow.md's PB11).

    python tools/gen_xbow.py [--worktree DIR] [--check | --verify]

Writes `items/gm_xbow.xml` and `items_plus/gm_xbow.xml` in Ghost Mode's DLC (default worktree
../TGM-5x-GM). --check writes nothing and fails if a file is out of date.

--verify writes nothing and compares what the game reads (Ghost Mode's DLC over 5.x) with legacy's
data, for every ability and item legacy defines in XBOW's files (both folders): abilities node by node
(5.x's weight nodes in crossbow abilities counted as WGT's), items by their XBOW fields (tags without
the `mod_*` price tags ECON keeps, base abilities); entries of a slice not ported yet are counted, not
compared. Fails on any other difference or on a name defined twice in the DLC folder. Each binary
file XBOW patches (`BINARIES`: XBOW-04's explosive bolt) must be 5.x's with exactly its cr2w_patch.py
edits, valid CRCs, and the new values legacy's file has.
"""
import argparse, os, re, subprocess, sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from gen_ench import abilities, ability_stats  # noqa: E402
import gen_arm_items as arm  # noqa: E402  extend_over_5x (ECON's short entries)

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DLC = "modGhostMode/files/dlc/dlcghostmode/data/gameplay/"
OUT = "gm_xbow.xml"
BOLTS = "modGhostMode/files/gameplay/%s/def_item_bolts.xml"
BOB_BOLTS = "modGhostMode/files/dlc/bob/data/gameplay/%s/def_item_bolts.xml"
CROSSBOWS = "modGhostMode/files/gameplay/%s/def_item_weapons_crossbow.xml"
BOB_CROSSBOWS = "modGhostMode/files/dlc/bob/data/gameplay/%s/def_item_weapons_crossbows.xml"
DLC13 = "modGhostMode/files/dlc/dlc13/data/gameplay/%s/dlc13_items.xml"
EP1_WEAPONS = "modGhostMode/files/dlc/ep1/data/gameplay/%s/def_item_weapons.xml"
NPC_WEAPONS = "modGhostMode/files/gameplay/%s/def_item_npcweapons.xml"
NPC_BOWS = ["%s _Stats" % b for b in ["Bow 1", "Bow 2", "Long bow 1", "Long bow 2", "Elven bow", "Crossbow 01",
                                      "Dwarven crossbow", "Nilfgaardian crossbow"]]
BOLT_ABILITIES = ["%s _Stats" % b for b in [
    "bodkin_bolt", "harpoon_bolt", "bait_bolt", "tracking_bolt", "blunt_bolt", "blunt_bolt_legendary",
    "broadhead_bolt", "broadhead_bolt_legendary", "target_point_bolt", "target_point_bolt_legendary",
    "split_bolt", "split_bolt_legendary", "explosive_bolt", "explosive_bolt_legendary"]]

# (source file pattern, feature, abilities), in port order.
SPEC = [
    (BOLTS, "XBOW-01: the bolts (damage by level, Target Point armor piercing, effect chances)", BOLT_ABILITIES),
    (CROSSBOWS, "XBOW-02: the crossbows (attack power, armor piercing by level, crit damage, adrenaline; no experience bonuses)",
     ["Crossbow %s _Stats" % c for c in ["1 q1", "2", "q206", "3", "4", "5", "6", "7"]] + ["Lynx School Crossbow _Stats", "Bear School Crossbow _Stats"]),
    (BOB_CROSSBOWS, "XBOW-02: the Toussaint crossbows (the two quest crossbows use Toussaint Crossbow 1's, item_layer.py)",
     ["Toussaint Crossbow 1 _Stats", "Toussaint Crossbow 2 _Stats"]),
    (DLC13, "XBOW-02: the free DLC's crossbows (armor piercing)",
     ["DLC13 Nilfgaardian Crossbow _Stats", "DLC13 Skellige Crossbow _Stats", "DLC13 Elven Crossbow _Stats"]),
    (EP1_WEAPONS, "XBOW-02: the Ofir crossbows", ["Ofir Crossbow _Stats", "Ofir Crossbow R _Stats"]),
    (NPC_WEAPONS, "XBOW-08: NPC bows and crossbows (an NPC's arrow deals its held bow's damage, npcBows.ws)", NPC_BOWS),
]
PORTED = {"XBOW-01", "XBOW-02", "XBOW-03", "XBOW-04", "XBOW-08"}
# Binary files: path -> cr2w_patch.py edits; the port's copy must be 5.x's file with exactly these edits.
BINARIES = [
    # XBOW-04: the explosive bolt's blast, 5 m -> 3 m (legacy's edit of the same property)
    ("modGhostMode/files/items/weapons/projectiles/witcher_bolts/explosive_bolt.w2ent",
     [("W3ExplosiveBolt", "explosionRange", 5.0, 3.0)]),
]
# XBOW's files for --verify: (file pattern, feature of its abilities, feature of its items).
FILES = [(BOLTS, "XBOW-01", "XBOW-03"), (BOB_BOLTS, "XBOW-01", "XBOW-03"), (CROSSBOWS, "XBOW-02", "XBOW-02"),
         (BOB_CROSSBOWS, "XBOW-02", "XBOW-02")]
# Files where only some abilities are XBOW's (the rest other areas'): (file pattern, feature, abilities).
PARTS = [(DLC13, "XBOW-02", SPEC[3][2]), (EP1_WEAPONS, "XBOW-02", SPEC[4][2]), (NPC_WEAPONS, "XBOW-08", NPC_BOWS)]
# Items whose legacy changes are other areas' only (price, weight: ECON, WGT).
ECON_TAGS = re.compile(r"^mod_(?!nosale)")


def git(*args):
    return subprocess.run(["git", "-C", REPO] + list(args), capture_output=True, check=True).stdout.decode("utf-8-sig")


def indent(body):
    out = []
    lines = [l.strip() for l in body.split("\n") if l.strip()]
    for i, l in enumerate(lines):
        out.append(("\t\t\t" if i in (0, len(lines) - 1) else "\t\t\t\t") + l)
    return "\n".join(out)


def build(folder):
    lines = ['<?xml version="1.0" encoding="UTF-8"?>', "<!-- Generated by tools/gen_xbow.py from legacy-GM; do not edit. -->",
             "<redxml>", "\t<definitions>", "\t\t<abilities>"]
    for pattern, feature, names in SPEC:
        path = pattern % folder
        legacy = abilities(git("show", "legacy-GM:" + path))
        vanilla = abilities(git("show", "vanilla-5.x:" + path))
        lines.append("\t\t\t<!-- %s -->" % feature)
        for n in names:
            body = re.sub(r'\s*<!--.*?-->', '', legacy[n].strip())
            head = '<ability name="%s"%s>' % (n, ' on_conflict="replace"' if n in vanilla else "")
            body = re.sub(r'^<ability\s+name="[^"]+"[^>]*>', head, body)
            # 5.x's weight node stays (WGT)
            vw = re.findall(r'<weight\b[^>]*/>', vanilla.get(n, ""))
            body = re.sub(r'\s*<weight\b[^>]*/>', '', body)
            if vw:
                body = re.sub(r'</ability>$', "\n" + "\n".join(vw) + "\n</ability>", body)
            lines.append(indent(body))
    lines += ["\t\t</abilities>", "\t</definitions>", "</redxml>", ""]
    return "﻿" + "\n".join(lines).replace("\r\n", "\n").replace("\n", "\r\n")


def item_entries(text):
    out = {}
    for m in re.finditer(r'(?ms)^[ \t]*<item\b(.*?)>(.*?)^[ \t]*</item>', re.sub(r'(?s)<!--.*?-->', '', text)):
        n = re.search(r'\bname\s*=\s*"([^"]+)"', m.group(1))
        if n:
            out[n.group(1)] = m.group(0)
    return out


def item_fields(entry):
    """An item's XBOW fields: its tags but the price tags (ECON), its base abilities."""
    t = re.search(r'(?s)<tags>(.*?)</tags>', entry)
    tags = sorted(x.strip() for x in (t.group(1).split(",") if t else []) if x.strip() and not ECON_TAGS.match(x.strip()))
    b = re.search(r'(?s)<base_abilities>(.*?)</base_abilities>', entry)
    return tags, sorted(re.findall(r'<a>\s*(.*?)\s*</a>', b.group(1)) if b else [])


def dlc_entries(worktree, folder):
    """{name: entry} of the abilities and items in the DLC folder; names defined twice."""
    abls, its, dup = {}, {}, []
    d = os.path.join(worktree, DLC, folder)
    for f in sorted(os.listdir(d)):
        if not f.endswith(".xml"):
            continue
        text = open(os.path.join(d, f), encoding="utf-8-sig").read()
        for kind, found, store in (("ability", abilities(re.sub(r'(?s)<!--.*?-->', '', text)), abls), ("item", item_entries(text), its)):
            for n, e in found.items():
                if n in store:
                    dup.append("%s %s twice in %s" % (kind, n, folder))
                store[n] = e
    its = arm.dlc_entries(worktree, folder)[0]  # the items as the game reads them (ECON's extend entries resolved over 5.x's)
    return abls, its, dup


def verify(worktree):
    bad = 0
    for folder in ["items", "items_plus"]:
        gm_a, gm_i, dup = dlc_entries(worktree, folder)
        for d in dup:
            print("DUPLICATE", d)
            bad = 1
        counts = {}
        for pattern, afeat, ifeat in FILES:
            path = pattern % folder
            ltext, vtext = git("show", "legacy-GM:" + path), git("show", "vanilla-5.x:" + path)
            legacy, vanilla = abilities(re.sub(r'(?s)<!--.*?-->', '', ltext)), abilities(vtext)
            for name, body in legacy.items():
                final = gm_a.get(name, vanilla.get(name))
                if afeat not in PORTED:
                    counts["%s not ported yet" % afeat] = counts.get("%s not ported yet" % afeat, 0) + 1
                    continue
                a = [x for x in ability_stats(final or "") if x[0] != "weight"]
                b = [x for x in ability_stats(body) if x[0] != "weight"]
                if final is None or a != b:
                    print("DIFF %s: ability %s\n  port only:   %s\n  legacy only: %s" % (
                        folder, name, [x for x in a if x not in b], [x for x in b if x not in a]))
                    bad = 1
                else:
                    counts["abilities equal to legacy's (weight WGT's)"] = counts.get("abilities equal to legacy's (weight WGT's)", 0) + 1
            litems, vitems = item_entries(ltext), item_entries(vtext)
            for name, entry in litems.items():
                final = gm_i.get(name, vitems.get(name))
                if ifeat not in PORTED:
                    counts["%s not ported yet" % ifeat] = counts.get("%s not ported yet" % ifeat, 0) + 1
                    continue
                if final is None or item_fields(final) != item_fields(entry):
                    print("DIFF %s: item %s\n  port:   %s\n  legacy: %s" % (folder, name, item_fields(final or ""), item_fields(entry)))
                    bad = 1
                else:
                    counts["items: tags and base abilities equal to legacy's (price tags ECON's)"] = counts.get(
                        "items: tags and base abilities equal to legacy's (price tags ECON's)", 0) + 1
        for pattern, afeat, names in PARTS:
            path = pattern % folder
            legacy = abilities(re.sub(r'(?s)<!--.*?-->', '', git("show", "legacy-GM:" + path)))
            vanilla = abilities(git("show", "vanilla-5.x:" + path))
            for name in names:
                final = gm_a.get(name, vanilla.get(name))
                a = [x for x in ability_stats(final or "") if x[0] != "weight"]
                b = [x for x in ability_stats(legacy[name]) if x[0] != "weight"]
                if final is None or a != b:
                    print("DIFF %s: ability %s\n  port only:   %s\n  legacy only: %s" % (
                        folder, name, [x for x in a if x not in b], [x for x in b if x not in a]))
                    bad = 1
                else:
                    counts["abilities equal to legacy's (weight WGT's)"] = counts.get("abilities equal to legacy's (weight WGT's)", 0) + 1
        for k, v in sorted(counts.items()):
            print("%s: %d %s" % (folder, v, k))
    import cr2w_patch
    for path, edits in BINARIES:
        port = open(os.path.join(worktree, path), "rb").read()
        vanilla = subprocess.run(["git", "-C", REPO, "show", "vanilla-5.x:" + path], capture_output=True, check=True).stdout
        legacy = subprocess.run(["git", "-C", REPO, "show", "legacy-GM:" + path], capture_output=True, check=True).stdout
        expected, changes, hit = cr2w_patch.patch(vanilla, edits)
        _, lchanges, lhit = cr2w_patch.patch(legacy, [(c, p, n, n) for c, p, o, n in edits])
        ok = port == expected and cr2w_patch.check_crcs(port) and len(hit) == len(edits) and len(lhit) == len(edits)
        print("%s %s: %s%s" % ("ok  " if ok else "DIFF", os.path.basename(path), "; ".join(changes),
                               "" if len(lhit) == len(edits) else " (legacy's file does not have the new values)"))
        bad |= not ok
    print("verify:", "differences found" if bad else "no difference")
    return bad


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
