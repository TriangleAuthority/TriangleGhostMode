"""ITEM's fields of an item or ability entry, shared by the item generators (docs/features/item.md).

ITEM's changes sit in the same entries as ARM's and SWD's (an armor piece's level tags next to its
class tags, a sword's level range next to its damage), and the game reads one definition per name.
So ITEM's fields are applied by whichever generator writes the entry:

- `gen_arm_items.py` applies them to the armor pieces and swords it merges (swords go on to
  `gen_swd_items.py`), and to the abilities it writes;
- `gen_swd_items.py` applies them to the sword entries and abilities it writes;
- `gen_item.py` writes every other entry ITEM changes (5.x's entry with ITEM's fields only) and checks,
  with --verify, that every ITEM field the game reads matches legacy's, and that no name is defined twice
  in Ghost Mode's DLC.

The units and their features come from `docs/features/attribution.csv`: a field is applied only to a
unit attributed to the feature that owns it, and only once that feature is in PORTED (the slices of
item.md's port order). Each field is merged three-way: legacy's change against 1.32 (`master`) applied
to 5.x's entry; where 5.x itself changed the field, 5.x's stays.
"""
import csv, os, re

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

PORTED = {"ITEM-03", "ITEM-04", "ITEM-05", "ITEM-06", "ITEM-07", "ITEM-08", "ITEM-09", "ITEM-10", "ITEM-11"}

# The item tags each feature owns (added or removed where legacy did).
TAGS = {
    "ITEM-03": {"AutogenUseLevelRange", "AutogenForceLevel", "EP1"},
    "ITEM-04": {"Autogen"},
    "ITEM-05": {"Autogen", "AutogenForceLevel"},
    "ITEM-08": {"DoNotEnhance", "DoNotEnhancem"},  # DoNotEnhancem: 1.32's misspelt tag on the sq701 gloves
}
# The ability nodes each feature owns.
NODES = {
    "ITEM-03": {"item_level_min", "item_level_max"},
    # the fixed armor or damage legacy removed (or turned into an add) for armor and damage by level
    "ITEM-04": {"armor", "SlashingDamage", "SilverDamage", "BludgeoningDamage", "PiercingDamage"},
    "ITEM-05": {"armor", "SlashingDamage", "SilverDamage", "quality"},
    "ITEM-07": {"*"},  # the random bonus abilities (MA_*), given as legacy has them
    "ITEM-09": {"quality"},
    "ITEM-11": {"*"},  # the repair kits' values and quality, the master kits
}
# The child blocks of an item each feature owns (taken whole from legacy).
BLOCKS = {
    "ITEM-11": {"base_abilities"},  # the kits' quality abilities
}

# The attributes of an item's opening tag each feature owns.
ATTRS = {
    "ITEM-10": {"initial_durability", "max_durability"},  # the two Beauclair trousers start at full durability
}

_UNITS = None
UNIT = re.compile(r'^(.*/gameplay/(items|items_plus)/[^/]+\.xml)::definitions/(items/item|abilities/ability):(.+)$')


def units():
    """{(folder, kind, name): (path, {ITEM features})} of ITEM's item and ability units."""
    global _UNITS
    if _UNITS is None:
        _UNITS = {}
        with open(os.path.join(REPO, "docs", "features", "attribution.csv"), encoding="utf-8") as f:
            for row in csv.DictReader(f):
                feats = {x for x in row["features"].split() if x.startswith("ITEM-")}
                m = UNIT.match(row["unit"])
                if m and feats:
                    _UNITS[(m.group(2), m.group(3).split("/")[1], m.group(4))] = ("modGhostMode/" + m.group(1), feats)
    return _UNITS


def ported(folder, kind, name, only=None):
    """The ported ITEM features of a unit (`only`: a set of features to restrict to)."""
    u = units().get((folder, kind, name))
    feats = (u[1] & PORTED) if u else set()
    return feats & only if only is not None else feats


def item_tags(folder, name):
    out = set()
    for f in ported(folder, "item", name):
        out |= TAGS.get(f, set())
    return out


def owns(own, tag):
    """Whether a node tag is among `own` ("*": every node but the weight, WGT's)."""
    return tag in own or ("*" in own and tag != "weight")


def ability_nodes(folder, name):
    out = set()
    for f in ported(folder, "ability", name):
        out |= NODES.get(f, set())
    return out


def merge_tags(folder, name, mtags, ltags, vtags, cur):
    """`cur` (a tag list) with ITEM's ported tag changes; `vtags` 5.x's own tags (5.x's change kept)."""
    out = list(cur)
    for t in sorted(item_tags(folder, name)):
        was, want = t in mtags, t in ltags
        if was == want or (t in vtags) != was:  # legacy did not change it, or 5.x did
            continue
        if want and t not in out:
            out.append(t)
        elif not want and t in out:
            out.remove(t)
    return out


def tag_changes(folder, name, mtags, ltags, vtags):
    """[(tag, added?)] of ITEM's ported tag changes legacy made and 5.x did not."""
    out = []
    for t in sorted(item_tags(folder, name)):
        was, want = t in mtags, t in ltags
        if was != want and (t in vtags) == was:
            out.append((t, want))
    return out


def merge_nodes(folder, name, mn, ln, body, nodes_fn, norm):
    """`body` (an ability body) with ITEM's ported node changes; mn, ln: 1.32's and legacy's nodes
    (as `gen_arm_items.nodes`); `nodes_fn` parses a body, `norm` normalises a node's text."""
    own = ability_nodes(folder, name)
    if not own:
        return body, []
    vn = nodes_fn(body)
    edits, appends, changes = [], [], []
    for k in sorted(set(mn) | set(ln), key=str):
        if not owns(own, k[0]):
            continue
        lv, mv = ln.get(k), mn.get(k)
        if lv and mv and norm(lv[2]) == norm(mv[2]):
            continue
        if mv and k in vn and norm(vn[k][2]) != norm(mv[2]):
            continue  # 5.x changed it: 5.x's kept
        if not mv and k in vn:
            continue  # 5.x added it too: 5.x's kept
        if lv:
            if k in vn:
                if norm(vn[k][2]) != norm(lv[2]):
                    edits.append((vn[k][0], vn[k][1], lv[2].strip()))
                    changes.append(f"{k[0]} {k[1]}")
            else:
                appends.append(lv[2].strip())
                changes.append(f"+{k[0]} {k[1]}")
        elif k in vn:
            edits.append((vn[k][0], vn[k][1], ""))
            changes.append(f"-{k[0]} {k[1]}")
    if not edits and not appends:
        return body, []
    for start, end, new in sorted(edits, reverse=True):
        body = body[:start] + new + body[end:]
    if appends:
        body = body.rstrip() + "".join("\n\t\t" + a for a in appends) + "\n\t"
    return re.sub(r'\n[ \t]*(?=\n)', '', body), changes


def head(entry):
    """{attribute: (start, end) of its value} of an item's opening tag (comments ignored)."""
    text = re.sub(r'<!--.*?-->', lambda m: " " * len(m.group(0)), entry, flags=re.S)
    end = text.index(">")
    return {m.group(1): (m.start(2), m.end(2)) for m in re.finditer(r'\b(\w+)\s*=\s*"([^"]*)"', text[:end])}, end


def merge_attrs(folder, name, mentry, lentry, entry):
    """`entry` with ITEM's ported opening-tag attribute changes; [changes]."""
    own = set()
    for f in ported(folder, "item", name):
        own |= ATTRS.get(f, set())
    if not own:
        return entry, []
    (mh, _), (lh, _) = head(mentry), head(lentry)
    mv = {a: mentry[s:e].strip() for a, (s, e) in mh.items()}
    lv = {a: lentry[s:e].strip() for a, (s, e) in lh.items()}
    changes = []
    for a in sorted(own):
        if lv.get(a) == mv.get(a):
            continue
        vh, end = head(entry)
        cur = entry[vh[a][0]:vh[a][1]].strip() if a in vh else None
        if cur != mv.get(a):
            continue  # 5.x changed it: 5.x's kept
        if a in vh and a in lv:
            entry = entry[:vh[a][0]] + lv[a] + entry[vh[a][1]:]
        elif a in lv:
            entry = entry[:end].rstrip() + f' {a}="{lv[a]}"' + entry[end:]
        else:
            continue  # legacy removed it: not carried (none so far)
        changes.append(f"{a} {cur} -> {lv[a]}")
    return entry, changes


def merge_blocks(folder, name, mentry, lentry, entry):
    """`entry` with ITEM's ported child blocks (legacy's, where 5.x kept 1.32's); [changes]."""
    own = set()
    for f in ported(folder, "item", name):
        own |= BLOCKS.get(f, set())
    changes = []
    for tag in sorted(own):
        mb, lb, vb = (re.search(rf'<{tag}>.*?</{tag}>', e, re.S) for e in (mentry, lentry, entry))
        if not (mb and lb and vb):
            continue
        n = lambda m: " ".join(m.group(0).split())
        if n(lb) == n(mb) or n(vb) != n(mb):
            continue
        entry = entry[:vb.start()] + lb.group(0) + entry[vb.end():]
        changes.append(tag)
    return entry, changes
