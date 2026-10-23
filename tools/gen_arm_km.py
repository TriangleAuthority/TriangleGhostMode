"""Generate the Kaer Morhen set's items for Ghost Mode's DLC (ARM-12, docs/features/arm.md).

Legacy Ghost Mode added a 4-piece medium set to the base game's item files: the "Kaer Morhen *"
armor pieces and their `_Stats` abilities, their crafting schematics (items and `<schematic>`
entries), and renamed the starting armor ("Worn Kaer Morhen ..."). This tool copies legacy's new
entries (`legacy-GM`) into a DLC file, and gives the four starting items whole from 5.x
(`vanilla-5.x`, on_conflict="replace") with legacy's name keys (and legacy's `DoNotEnhance`, as
`gen_arm_items.py` carries it; that tool leaves these four items to this one), with CRAFT's fields
(their dismantling parts) applied through `item_layer.apply_item`.

Legacy turned the vanilla "Starting Armor Upgrade schematic 1" into the first armor schematic
(Starting Armor -> Kaer Morhen Armor). A DLC cannot override a `<schematic>` (the crafting manager
reads every entry of that name), so the port adds it as "Kaer Morhen Armor schematic" and leaves
the vanilla schematic alone.

    python tools/gen_arm_km.py [--worktree DIR] [--check]

Writes `items/gm_arm_kaer_morhen.xml` and `items_plus/gm_arm_kaer_morhen.xml` in Ghost Mode's DLC
(default worktree ../TGM-5x-GM). --check writes nothing and fails if a file is out of date.
"""
import argparse, os, re, subprocess, sys

import item_layer

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DLC = "modGhostMode/files/dlc/dlcghostmode/data/gameplay/"
OUT = "gm_arm_kaer_morhen.xml"
PIECES = ["armor", "boots", "gloves", "pants"]
KM = re.compile(r'^(?:NGP )?Kaer Morhen ')
STARTING = {"Starting Armor": "armor", "Starting Pants": "pants", "Starting Boots": "boots", "Starting Gloves": "gloves"}
OLD_SCHEMATIC, NEW_SCHEMATIC = "Starting Armor Upgrade schematic 1", "Kaer Morhen Armor schematic"
CRAFTS_KM_ARMOR = re.compile(r'craftedItem_name\s*=\s*"Kaer Morhen Armor"')


def git(*args):
    r = subprocess.run(["git", *args], cwd=REPO, capture_output=True)
    return r.stdout.decode("utf-8-sig", errors="replace") if r.returncode == 0 else ""


def no_comments(text):
    return re.sub(r'<!--.*?-->', '', text, flags=re.S)


def entries(text, tag, attr):
    """(name, text) of each top-level <tag ...> element, balanced (items nest <item> in <variants>)."""
    out, pos = [], 0
    tok = re.compile(r'<%s\b[^>]*?(/?)>|</%s>' % (tag, tag))
    while True:
        m = tok.search(text, pos)
        if not m:
            return out
        if m.group(0).startswith('</') or m.group(1) == '/':
            pos = m.end()
            continue
        depth, end = 0, len(text)
        for t in tok.finditer(text, m.start()):
            if t.group(0).startswith('</'):
                depth -= 1
            elif t.group(1) != '/':
                depth += 1
            if depth == 0:
                end = t.end()
                break
        nm = re.search(r'\b%s\s*=\s*"([^"]*)"' % attr, m.group(0))
        if nm:
            out.append((nm.group(1), text[m.start():end]))
        pos = end


def generate(folder):
    abilities, items, schem_items, schematics, starting = [], [], [], [], []
    for p in PIECES:
        text = no_comments(git("show", "legacy-GM:modGhostMode/files/gameplay/%s/def_item_crafting_%s.xml" % (folder, p)))
        abilities += [e for n, e in entries(text, "ability", "name") if KM.match(n)]
        items += [e for n, e in entries(text, "item", "name") if KM.match(n)]
    text = no_comments(git("show", "legacy-GM:modGhostMode/files/gameplay/%s/def_item_crafting_recipes.xml" % folder))
    for n, e in entries(text, "item", "name"):
        if KM.match(n) and n.endswith(" schematic"):
            schem_items.append(e)
    olds = [e for n, e in entries(text, "item", "name") if n == OLD_SCHEMATIC]
    if olds:   # legacy's second definition is the Kaer Morhen one
        schem_items.insert(0, olds[-1].replace('"%s"' % OLD_SCHEMATIC, '"%s"' % NEW_SCHEMATIC))
    for n, e in entries(text, "schematic", "name_name"):
        if KM.match(n):
            schematics.append(e)
        elif n == OLD_SCHEMATIC and CRAFTS_KM_ARMOR.search(e):
            schematics.insert(0, e.replace('"%s"' % OLD_SCHEMATIC, '"%s"' % NEW_SCHEMATIC))
    for name, piece in STARTING.items():
        five = no_comments(git("show", "vanilla-5.x:modGhostMode/files/gameplay/%s/def_item_%s.xml" % (folder, piece)))
        leg = no_comments(git("show", "legacy-GM:modGhostMode/files/gameplay/%s/def_item_%s.xml" % (folder, piece)))
        e5 = [e for n, e in entries(five, "item", "name") if n == name]
        el = [e for n, e in entries(leg, "item", "name") if n == name]
        if not e5 or not el:
            continue
        key = re.search(r'localisation_key_name\s*=\s*"([^"]*)"', el[0]).group(1)
        e = re.sub(r'(localisation_key_name\s*=\s*")[^"]*(")', lambda m: m.group(1) + key + m.group(2), e5[0], count=1)
        e = re.sub(r'<item\b', '<item on_conflict="replace"', e, count=1)
        tl = re.search(r'<tags>(.*?)</tags>', el[0], re.S)
        if tl and "DoNotEnhance" in [t.strip() for t in tl.group(1).split(",")]:
            # legacy's DoNotEnhance, as gen_arm_items.py carries it (SWD audit F4, the owner's decision)
            e = re.sub(r'(<tags>)(.*?)(\s*</tags>)', lambda m: m.group(1) + m.group(2).rstrip()
                       + ("" if "DoNotEnhance" in m.group(2) else ", DoNotEnhance") + m.group(3), e, count=1, flags=re.S)
        # CRAFT's fields (the dismantling parts, CRAFT-08; CRAFT/LOOT audit F2), as the other item tools apply them
        mst = no_comments(git("show", "master:modGhostMode/files/gameplay/%s/def_item_%s.xml" % (folder, piece)))
        em = [x for n, x in entries(mst, "item", "name") if n == name]
        if em:
            e, _ = item_layer.apply_item(folder, name, em[0], el[0], e)
        starting.append(e)

    def block(lst):
        return "\n".join("\t" + e.strip() for e in lst)
    head = ('﻿<?xml version="1.0" encoding="UTF-8"?>\n'
            '<!-- Ghost Mode: ARM-12, the Kaer Morhen set (legacy\'s items, abilities and schematics; the starting\n'
            '     items renamed "Worn Kaer Morhen"). Generated by tools/gen_arm_km.py: do not edit. -->\n')
    text = (head + "<redxml>\n<definitions>\n<abilities>\n" + block(abilities) + "\n</abilities>\n<items>\n"
            + block(items + schem_items + starting) + "\n</items>\n</definitions>\n<custom>\n<crafting_schematics>\n"
            + block(schematics) + "\n</crafting_schematics>\n</custom>\n</redxml>\n")
    return text, (len(abilities), len(items), len(schem_items), len(schematics), len(starting))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--worktree", default=os.path.join(os.path.dirname(REPO), "TGM-5x-GM"))
    ap.add_argument("--check", action="store_true")
    a = ap.parse_args()
    bad = False
    for folder in ("items", "items_plus"):
        text, counts = generate(folder)
        path = os.path.join(a.worktree, DLC, folder, OUT)
        old = open(path, encoding="utf-8").read() if os.path.exists(path) else None
        if a.check:
            if old != text:
                print("out of date:", path)
                bad = True
            continue
        with open(path, "w", encoding="utf-8", newline="\n") as f:
            f.write(text)
        print("%s/%s: %d abilities, %d items, %d schematic items, %d schematics, %d starting items" % ((folder, OUT) + counts))
    sys.exit(1 if bad else 0)


if __name__ == "__main__":
    main()
