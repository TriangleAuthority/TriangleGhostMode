"""Generate ARM-15's item overrides for Ghost Mode's DLC: 5.x's new armor under Ghost Mode's rules
(docs/features/arm.md, ARM-15, the owner's decisions DA3 and DA4).

5.x added armor legacy never had: the Netflix set (dlc18, 3 tiers), Dol Blathanna, White Tiger and
the Scarlet Crest set (w3r). This tool takes each of their `_Stats` abilities and items from
`vanilla-5.x` whole and writes them with on_conflict="replace", with these changes:

- Netflix (DA3): armor and resistances like legacy's grandmaster Griffin set (the top tier; the lower
  tiers keep the resistances and scale the armor by level, as legacy's Griffin tiers); the gloves give
  Yrden intensity (the boots' per-tier values) instead of Aard; the trousers give sign intensity for all
  signs (0.05/0.10/0.12) instead of their stamina regen and inert base intensity; the lower tiers
  (armor and swords, Reinald's swords too) are tagged `NetflixSetMinor` and `SetBonusPiece`, so they
  count towards the 3-piece bonus, and carry ECON's DE2 price (`item_layer.DE2`). The swords' entries are written by `gen_swd_items.py` (SWD-10, which
  also sets their stats and slots), with these tags from `minor_tags`, so each sword has one entry.
- Dol Blathanna and White Tiger (DA4): legacy's medium resistances (legacy's DLC5 Nilfgaardian
  armor); Dol Blathanna's chest gives Igni and Aard intensity +10% instead of stamina regen.
- Scarlet Crest (DA4): armor 465 and resistances slashing 40%, piercing 32%, bludgeoning 44% in all
  (none against rending and elemental damage), spread over the pieces as legacy's Griffin set.

New Game+ (`items_plus`, including 5.x's `NGP` items): resistances keep Ghost Mode's value (legacy kept
its armor resistances in NG+); other numbers follow the NG+ rule (vanilla NG+ x GM NG / vanilla NG,
docs/feature-mapping.md#ng-numbers), a new stat taking the ratio of the stat it replaces.

    python tools/gen_arm_new.py --worktree DIR [--check]

Writes `items/gm_arm_new.xml` and `items_plus/gm_arm_new.xml` in Ghost Mode's DLC (--worktree, required). --check writes nothing and fails if a file is out of date.
"""
import argparse, os, re, subprocess, sys
import xml.etree.ElementTree as ET

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import item_layer  # noqa: E402  ECON's DE2 prices of these items
import paths  # noqa: E402  (tools/: the shared --worktree argument)

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DLC = "modGhostMode/files/dlc/dlcghostmode/data/gameplay/"
OUT = "gm_arm_new.xml"
FILES = ["dlc18_netflix_armor", "dlc18_netflix_swords", "def_item_armor_dol_blathanna", "def_item_armor_white_tiger", "w3r_items"]
RES = ["slashing_resistance_perc", "piercing_resistance_perc", "bludgeoning_resistance_perc", "rending_resistance_perc", "elemental_resistance_perc"]


def res(*v):
    return dict(zip(RES, v))


# Legacy's grandmaster Griffin set per piece (armor at levels 21, 35 and 41) and legacy's DLC5
# Nilfgaardian medium armor (Dol Blathanna, White Tiger).
GRIFFIN = {"Armor": res(.17, .09, .09, .17, .17), "Boots": res(.06, .04, .04, .06, .06),
           "Gloves": res(.05, .03, .03, .05, .05), "Pants": res(.07, .04, .04, .07, .07)}
NETFLIX_ARMOR = {"Armor": [125, 195, 225], "Boots": [45, 73, 85], "Gloves": [41, 69, 81], "Pants": [45, 73, 85]}
NETFLIX_YRDEN = [.06, .10, .12]
NETFLIX_SIGNS = [.05, .10, .12]
SCARLET = {"Armor": (220, res(.19, .15, .21, 0, 0)), "Boots": (83, res(.07, .06, .08, 0, 0)),
           "Gauntlets": (79, res(.06, .05, .06, 0, 0)), "Trousers": (83, res(.08, .06, .09, 0, 0))}

# ability name -> list of changes: ("set", tag, type, value[, source tag, source type]) sets or adds a
# node (NG+ by the ratio of the node itself, or of the source node it replaces); ("res", values) sets
# the resistances (0 removes); ("del", tag, type) removes a node.
SPEC = {}
for t, sfx in enumerate(["", " 1", " 2"]):
    for piece in ["Armor", "Boots", "Gloves", "Pants"]:
        ch = [("set", "armor", "base", NETFLIX_ARMOR[piece][t]), ("res", GRIFFIN[piece])]
        if piece == "Gloves":
            ch += [("del", "spell_power_aard", "mult"), ("set", "spell_power_yrden", "mult", NETFLIX_YRDEN[t], "spell_power_aard", "mult")]
        if piece == "Pants":
            ch += [("del", "staminaRegen_armor_mod", "mult"), ("del", "spell_power", "base"), ("set", "spell_power", "mult", NETFLIX_SIGNS[t], "spell_power", "base")]
        SPEC["Netflix %s%s _Stats" % (piece, sfx)] = ch
NILF = {"Armor": res(.14, .06, .06, .14, .14), "Boots": res(.06, .04, .04, .06, .06),
        "Gloves": res(.05, .03, .03, .05, .05), "Pants": res(.07, .04, .04, .07, .07)}
for piece, r in NILF.items():
    SPEC["White Tiger %s _Stats" % piece] = [("res", r)]
    SPEC["Dol Blathanna %s _Stats" % piece] = [("res", r)]
SPEC["Dol Blathanna Armor _Stats"] += [("del", "staminaRegen_armor_mod", "mult"),
                                       ("set", "spell_power_igni", "mult", .10, "@Dol Blathanna Gloves _Stats", "spell_power_igni"),
                                       ("set", "spell_power_aard", "mult", .10, "@Dol Blathanna Gloves _Stats", "spell_power_aard")]
for piece, (armor, r) in SCARLET.items():
    SPEC["Scarlet Crest %s _Stats" % piece] = [("set", "armor", "base", armor), ("res", r)]

# Netflix items of the lower tiers: they count towards the set's first bonus.
MINOR = re.compile(r'^(?:NGP )?(?:Netflix (?:Armor|Boots|Gloves|Pants|steel sword|silver sword)(?: 1)?|Reinald Netflix (?:steel|silver) sword)$')
NODE = re.compile(r'<([A-Za-z_]\w*)\b([^>]*?)/>')
SWORD = re.compile(r'\bcategory\s*=\s*"(?:steelsword|silversword)"')


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


def find_node(body, tag, typ):
    for m in NODE.finditer(body):
        t = re.search(r'\btype\s*=\s*"([^"]*)"', m.group(2))
        if m.group(1) == tag and (t.group(1) if t else "") == typ:
            return m
    return None


def node_value(body, tag, typ):
    m = find_node(body, tag, typ) if body else None
    return float(re.search(r'\bmin\s*=\s*"([^"]*)"', m.group(2)).group(1)) if m else None


def fmt(v):
    return ("%.4f" % v).rstrip("0").rstrip(".") if v != int(v) else str(int(v))


def set_node(body, tag, typ, v):
    m = find_node(body, tag, typ)
    if m:
        node = re.sub(r'(\b(?:min|max)\s*=\s*")[^"]*(")', lambda x: x.group(1) + fmt(v) + x.group(2), m.group(0))
        return body[:m.start()] + node + body[m.end():]
    end = body.rfind("</ability>")
    return body[:end].rstrip() + '\n\t\t\t\t<%s type="%s" min="%s" />\n\t\t\t' % (tag, typ, fmt(v)) + body[end:]


def del_node(body, tag, typ):
    m = find_node(body, tag, typ)
    if not m:
        return body
    start = body.rfind("\n", 0, m.start())
    return body[:start] + body[m.end():]


def minor_tags(entry):
    """A lower-tier Netflix item's entry with the tags that count it towards the set's first bonus."""
    tm = re.search(r'(<tags>)(.*?)(</tags>)', entry, re.S)
    tags = [t.strip() for t in tm.group(2).split(",") if t.strip()]
    new = tags + [t for t in ("NetflixSetMinor", "SetBonusPiece") if t not in tags]
    return entry[:tm.start(2)] + "\t\t\t\t\t\t\t" + ", ".join(new) + "\n\t\t\t\t" + entry[tm.end(2):]


def generate(folder):
    ng = {n: e for f in FILES for n, e in entries(no_comments(git("show", "vanilla-5.x:modGhostMode/files/gameplay/items/%s.xml" % f)), "ability", "name")}
    abilities, items = [], []
    for f in FILES:
        text = no_comments(git("show", "vanilla-5.x:modGhostMode/files/gameplay/%s/%s.xml" % (folder, f)))
        own = dict(entries(text, "ability", "name"))
        for name, entry in entries(text, "ability", "name"):
            base = name[4:] if name.startswith("NGP ") else name
            if base not in SPEC:
                continue
            body = entry
            for ch in SPEC[base]:
                if ch[0] == "res":
                    for tag, v in ch[1].items():
                        body = set_node(body, tag, "base", v) if v else del_node(body, tag, "base")
                elif ch[0] == "del":
                    body = del_node(body, ch[1], ch[2])
                else:
                    tag, typ, v = ch[1:4]
                    stag, styp = (ch[4], ch[5]) if len(ch) > 4 else (tag, typ)
                    if stag.startswith("@"):   # the same stat on another piece of the set
                        src_ng, src_cur = ng.get(stag[1:]), own.get(("NGP " if name.startswith("NGP ") else "") + stag[1:])
                        stag, styp = styp, "mult"
                    else:
                        src_ng, src_cur = ng.get(base), entry
                    vn, vc = node_value(src_ng, stag, styp), node_value(src_cur, stag, styp)
                    if folder == "items_plus" and vn and vc is not None:
                        v = round(v * vc / vn, 4 if v < 1 else 0)
                    body = set_node(body, tag, typ, v)
            if item_layer.dw2_weight(name) is not None and find_node(body, "weight", "base"):  # WGT's DW2 (slice W3)
                body = set_node(body, "weight", "base", float(item_layer.dw2_weight(name)))
            body = re.sub(r'<ability\b', '<ability on_conflict="replace"', body, count=1)
            abilities.append(body)
        for name, entry in entries(text, "item", "name"):
            if not MINOR.match(name) or SWORD.search(entry):  # swords: gen_swd_items.py (SWD-10)
                continue
            entry = item_layer.apply_de2(name, minor_tags(entry))  # ECON's DE2 price
            items.append(re.sub(r'^<item\b', '<item on_conflict="replace"', entry))

    def block(lst):
        return "\n".join("\t" + e.strip() for e in lst)
    text = ('﻿<?xml version="1.0" encoding="UTF-8"?>\n'
            "<!-- Ghost Mode: ARM-15, 5.x's new armor under Ghost Mode's rules (Netflix, Dol Blathanna, White Tiger,\n"
            "     Scarlet Crest). Generated by tools/gen_arm_new.py from 5.x's entries: do not edit. -->\n"
            "<redxml>\n<definitions>\n<abilities>\n" + block(abilities) + "\n</abilities>\n<items>\n" + block(items)
            + "\n</items>\n</definitions>\n</redxml>\n")
    text = re.sub(r'\n[ \t]*(?=\n)', '', text.replace("\r", ""))
    return text, (len(abilities), len(items))


def main():
    ap = argparse.ArgumentParser()
    paths.add_worktree(ap)  # required: parallel areas each pass their own worktree
    ap.add_argument("--check", action="store_true")
    a = ap.parse_args()
    bad = False
    for folder in ("items", "items_plus"):
        text, counts = generate(folder)
        ET.fromstring(text.lstrip("﻿").encode("utf-8"))  # fails on XML the game could not read
        path = os.path.join(a.worktree, DLC, folder, OUT)
        old = open(path, encoding="utf-8").read() if os.path.exists(path) else None
        if a.check:
            if old != text:
                print("out of date:", path)
                bad = True
            continue
        with open(path, "w", encoding="utf-8", newline="\n") as f:
            f.write(text)
        print("%s/%s: %d abilities, %d items" % ((folder, OUT) + counts))
    sys.exit(1 if bad else 0)


if __name__ == "__main__":
    main()
