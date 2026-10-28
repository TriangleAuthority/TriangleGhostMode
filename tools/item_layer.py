"""ITEM's and CRAFT's fields of an item or ability entry, shared by the item generators
(docs/features/item.md, docs/features/craft.md).

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

PORTED = {"ITEM-03", "ITEM-04", "ITEM-05", "ITEM-06", "ITEM-07", "ITEM-08", "ITEM-09", "ITEM-10", "ITEM-11",
          "CRAFT-01", "CRAFT-02", "CRAFT-03", "CRAFT-04", "CRAFT-05", "CRAFT-06", "CRAFT-07", "CRAFT-08", "CRAFT-09", "LOOT-08", "FOOD-04", "FOOD-07",
          "XBOW-02", "XBOW-03"}
AREAS = ("ITEM-", "CRAFT-", "LOOT-", "FOOD-", "XBOW-")

# The item tags each feature owns (added or removed where legacy did); "*": every tag but the mod_*
# price tags (ECON's).
TAGS = {
    "CRAFT-07": {"*"},  # the ingredients' kind tags (CraftingIngredient, AlchemyIngredient, ...)
    "ITEM-03": {"AutogenUseLevelRange", "AutogenForceLevel", "EP1"},
    "ITEM-04": {"Autogen"},
    "ITEM-05": {"Autogen", "AutogenForceLevel"},
    "ITEM-08": {"DoNotEnhance", "DoNotEnhancem"},
    "XBOW-03": {"mod_nosale", "mod_nosalem"},  # bolts sellable; the quest bolt's misspelt mod_nosalem fixed (xbow.md)
    "FOOD-04": {"*"},  # the food and drink kind tags (Drinks, Alcohol, Uncooked, Potion off seven items, ...)  # DoNotEnhancem: 1.32's misspelt tag on the sq701 gloves
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
    "CRAFT-04": {"*"},  # the craftable quest armors' abilities (new, legacy's whole)
    "CRAFT-09": {"*"},  # the dismantle kits' abilities (new)
}
# The child blocks of an item each feature owns (taken whole from legacy).
BLOCKS = {
    "ITEM-11": {"base_abilities"},  # the kits' quality abilities
    "CRAFT-01": {"base_abilities"},  # the schematic items' rarity (bugfix 183)
    "CRAFT-02": {"base_abilities"},
    "CRAFT-06": {"base_abilities"},  # the recipe items' rarity
    "CRAFT-07": {"base_abilities"},  # the ingredients' rarity (bugfix 120)
    "CRAFT-08": {"recycling_parts"},  # the dismantling parts
    "FOOD-04": {"base_abilities", "recycling_parts"},
    "XBOW-02": {"base_abilities"},  # the two Blood and Wine quest crossbows on Toussaint Crossbow 1's stats  # the food and drink tier, rarity and toxicity abilities; Wolf liver's parts (none: audit F1)
}
# (block, item) where legacy's block is taken although 5.x changed it (the owner's DC4: Cheesecutter
# without 5.x's Cheese).
FORCE_LEGACY = {("recycling_parts", "Cheesecutter")}
# (block, item) left as 5.x has it although the item's feature owns the block: another area's part of
# legacy's block (none since FOOD-04 gave the Free nilfgaardian lemon its drink abilities).
KEEP_5X = set()

# New items another generator writes with its own --verify (gen_item.py's check skips them):
# (feature, name pattern) -> reason.
ELSEWHERE = {("FOOD-07", r"^Recipe for "): "FOOD-07's cooking recipe items, written by gen_food.py with Q1's names"}

# The attributes of an item's opening tag each feature owns.
ATTRS = {
    "ITEM-10": {"initial_durability", "max_durability"},  # the two Beauclair trousers start at full durability
    "CRAFT-02": {"localisation_key_name"},  # the NG+ Wolf school sword schematics' names
    "CRAFT-07": {"category", "grid_size", "localisation_key_description"},
    # every drink stacks to 100; Wolf liver's category and description (legacy moved it from the ingredients to the
    # food: its ingredient unit, CRAFT-07's and CRAFT-08's, shares the name with its food unit, which wins; audit F1)
    "FOOD-04": {"stackable", "category", "localisation_key_description"},
}

_UNITS = None
UNIT = re.compile(r'^(.*/gameplay/)(items|items_plus|items\*)(/[^/]+\.xml)::definitions/(items/item|abilities/ability):(.+)$')


def units():
    """{(folder, kind, name): (path, {ITEM and CRAFT features})} of their item and ability units."""
    global _UNITS
    if _UNITS is None:
        _UNITS = {}
        with open(os.path.join(REPO, "docs", "features", "attribution.csv"), encoding="utf-8") as f:
            for row in csv.DictReader(f):
                feats = {x for x in row["features"].split() if x.startswith(AREAS)}
                m = UNIT.match(row["unit"])
                if m and feats:
                    # `items*`: one row for the regular and the NG+ entry (XBOW's rows)
                    for folder in (["items", "items_plus"] if m.group(2) == "items*" else [m.group(2)]):
                        _UNITS[(folder, m.group(4).split("/")[1], m.group(5))] = (
                            "modGhostMode/" + m.group(1) + folder + m.group(3), feats)
    return _UNITS


def ported(folder, kind, name, only=None):
    """The ported ITEM features of a unit (`only`: a set of features to restrict to)."""
    u = units().get((folder, kind, name))
    feats = (u[1] & PORTED) if u else set()
    return feats & only if only is not None else feats


def own_tags(feature, mtags, ltags):
    """The tags `feature` owns on an item whose 1.32 and legacy tags are `mtags`, `ltags`."""
    own = set(TAGS.get(feature, set()))
    if "*" in own:
        own.discard("*")
        own |= {t for t in set(mtags) | set(ltags) if not t.startswith("mod_")}
    return own


def item_tags(folder, name, mtags=(), ltags=(), area=None):
    out = set()
    for f in ported(folder, "item", name):
        if area and not f.startswith(area):
            continue
        out |= own_tags(f, mtags, ltags)
    return out


def owns(own, tag):
    """Whether a node tag is among `own` ("*": every node but the weight, WGT's)."""
    return tag in own or ("*" in own and tag != "weight")


def ability_nodes(folder, name):
    out = set()
    for f in ported(folder, "ability", name):
        out |= NODES.get(f, set())
    return out


def merge_tags(folder, name, mtags, ltags, vtags, cur, area=None):
    """`cur` (a tag list) with ITEM's ported tag changes; `vtags` 5.x's own tags (5.x's change kept)."""
    out = list(cur)
    for t in sorted(item_tags(folder, name, mtags, ltags, area)):
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
    for t in sorted(item_tags(folder, name, mtags, ltags)):
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


def merge_attrs(folder, name, mentry, lentry, entry, area=None):
    """`entry` with the ported opening-tag attribute changes; [changes]."""
    own = set()
    for f in ported(folder, "item", name):
        if area and not f.startswith(area):
            continue
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


class _Block:
    """A block's span in an entry, with the entry's own text (comments inside the block kept)."""

    def __init__(self, entry, m):
        self._text, self._s, self._e = entry[m.start():m.end()], m.start(), m.end()

    def start(self):
        return self._s

    def end(self):
        return self._e

    def group(self, _=0):
        return self._text


def block_of(entry, tag):
    """An item's top-level child block `tag` (None if it has none). Blocks inside comments do not
    count (1.32 and 5.x comment some out, e.g. the Grave Hag ear's parts: CRAFT/LOOT audit F1)."""
    text = re.sub(r'<!--.*?-->', lambda c: " " * len(c.group(0)), entry, flags=re.S)
    m = re.search(rf'<{tag}>.*?</{tag}>|<{tag}\s*/>', text, re.S)
    return _Block(entry, m) if m else None


def norm_block(m):
    return " ".join(m.group(0).split()) if m else None


def merge_blocks(folder, name, mentry, lentry, entry, area=None):
    """`entry` with the ported child blocks (legacy's, where 5.x kept 1.32's); [changes]."""
    own = set()
    for f in ported(folder, "item", name):
        if area and not f.startswith(area):
            continue
        own |= BLOCKS.get(f, set())
    changes = []
    for tag in sorted(own):
        if (tag, name) in KEEP_5X:
            continue
        mb, lb, vb = (block_of(e, tag) for e in (mentry, lentry, entry))
        if norm_block(lb) == norm_block(mb) or norm_block(vb) == norm_block(lb):
            continue
        if norm_block(vb) != norm_block(mb) and (tag, name) not in FORCE_LEGACY:
            continue  # 5.x changed it: 5.x's kept
        if vb and lb:
            entry = entry[:vb.start()] + lb.group(0) + entry[vb.end():]
        elif vb:  # legacy removed the block
            entry = entry[:vb.start()].rstrip(" \t") + entry[vb.end():].lstrip(" \t\r\n")
        else:  # legacy added it: before the closing tag
            end = entry.rindex("</item>")
            entry = entry[:end].rstrip() + "\n\t\t" + lb.group(0) + "\n\t" + entry[end:]
        changes.append(tag)
    return entry, changes


def apply_item(folder, name, mentry, lentry, entry, area="CRAFT-"):
    """`entry` (an item's entry as a generator writes it) with every ported ITEM and CRAFT field of the
    item (by default CRAFT's: the item tools apply ITEM's themselves): tags, opening-tag attributes
    and child blocks; [changes]. Idempotent."""
    vtags = split_tags(entry)
    mt, lt = split_tags(mentry), split_tags(lentry)
    new = merge_tags(folder, name, mt, lt, vtags, vtags, area)
    changes = []
    if new != vtags:
        tm = re.search(r'(<tags>)(.*?)(</tags>)', entry, re.S)
        if tm:
            entry = entry[:tm.start(2)] + "\t\t\t\t\t\t\t" + ", ".join(new) + "\n\t\t" + entry[tm.end(2):]
            changes.append(f"tags {', '.join(vtags)} -> {', '.join(new)}")
    entry, a = merge_attrs(folder, name, mentry, lentry, entry, area)
    entry, b = merge_blocks(folder, name, mentry, lentry, entry, area)
    return entry, changes + a + b


def split_tags(entry):
    m = re.search(r'<tags>(.*?)</tags>', re.sub(r'<!--.*?-->', '', entry, flags=re.S), re.S)
    return [t.strip() for t in m.group(1).split(",") if t.strip()] if m else []
