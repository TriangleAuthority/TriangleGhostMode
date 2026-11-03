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

# PORTED, AREAS, TAGS, NODES, BLOCKS and ATTRS are written per area, one line (or block) each with a comment line
# between them, so areas ported in parallel never edit the same lines (docs/proposals/parallel-ports.md, section 5).
# An area adds its features on its own line; WGT, OPT and TRPH have theirs ready (empty).
PORTED = set()
# ITEM
PORTED |= {"ITEM-03", "ITEM-04", "ITEM-05", "ITEM-06", "ITEM-07", "ITEM-08", "ITEM-09", "ITEM-10", "ITEM-11"}
# CRAFT
PORTED |= {"CRAFT-01", "CRAFT-02", "CRAFT-03", "CRAFT-04", "CRAFT-05", "CRAFT-06", "CRAFT-07", "CRAFT-08", "CRAFT-09"}
# LOOT
PORTED |= {"LOOT-08"}
# FOOD
PORTED |= {"FOOD-04", "FOOD-07"}
# XBOW
PORTED |= {"XBOW-02", "XBOW-03"}
# ECON
PORTED |= {"ECON-01", "ECON-02", "ECON-03", "ECON-04"}
# WGT (wgt.md): slice W1, the items' weight attribute and the coins' and pig trophy's EncumbranceOff tag
PORTED |= {"WGT-03", "WGT-04", "WGT-05", "WGT-06"}
# OPT
PORTED |= set()
# TRPH
PORTED |= {"TRPH-01", "TRPH-02", "TRPH-03"}
# (the features' prefixes this layer reads from attribution.csv)
AREAS = ()
# ITEM, CRAFT, LOOT, FOOD, XBOW, ECON
AREAS += ("ITEM-", "CRAFT-", "LOOT-", "FOOD-", "XBOW-", "ECON-")
# WGT
AREAS += ("WGT-",)
# OPT
AREAS += ()
# TRPH
AREAS += ("TRPH-",)
# ECON's features (prices and price tags, docs/features/econ.md): they never make a tool write an entry whole
# by themselves. A tool that writes an entry for another area's change applies them too (`apply_item`);
# entries with ECON's changes only are `gen_econ.py`'s (short `extend` entries, the owner's form, 2026-11-01).
ECON = {"ECON-01", "ECON-02", "ECON-03", "ECON-04"}
# WGT's fields (weights, capacities) never make a tool write an entry whole either (wgt.md PW2)
WHOLE = tuple(a for a in AREAS if a not in ("ECON-", "WGT-"))
# The mod_ tags other areas own (ECON owns every other mod_ price tag).
ECON_KEEP = {"mod_nosale", "mod_nosalem", "mod_alchemy_table"}

# The item tags each feature owns (added or removed where legacy did); "*": every tag but the mod_*
# price tags (ECON's); "mod_*": every mod_ price tag but ECON_KEEP.
TAGS = {
    "CRAFT-07": {"*"},  # the ingredients' kind tags (CraftingIngredient, AlchemyIngredient, ...)
    "ITEM-03": {"AutogenUseLevelRange", "AutogenForceLevel", "EP1"},
    "ITEM-04": {"Autogen"},
    "ITEM-05": {"Autogen", "AutogenForceLevel"},
    "ITEM-08": {"DoNotEnhance", "DoNotEnhancem"},
    "XBOW-03": {"mod_nosale", "mod_nosalem"},  # bolts sellable; the quest bolt's misspelt mod_nosalem fixed (xbow.md)
    "CRAFT-08": {"mod_alchemy_table"},  # PE13: the tag the dismantling station reads (Protofleder Mutagen)
    "ECON-01": {"mod_*"}, "ECON-02": {"mod_*"}, "ECON-03": {"mod_*"},
    "ECON-04": {"mod_*"},  # the price tags; legacy's fixes of 1.32's mod_weapo, mod_legendar, mod_valuable EP1 (PE4)
    "FOOD-04": {"*"},  # the food and drink kind tags (Drinks, Alcohol, Uncooked, Potion off seven items, ...)  # DoNotEnhancem: 1.32's misspelt tag on the sq701 gloves
}
# WGT: Nilfgaardian florens and Redanian orens weightless, Hearts of Stone's pig contest trophy weighted (WGT-05)
TAGS.update({"WGT-05": {"EncumbranceOff"}})
# OPT
TAGS.update({})
# TRPH
TAGS.update({"TRPH-01": {"Quest"}, "TRPH-02": {"Quest"}})  # NG+'s Wyvern trophy mq1051 and the Camerlengo's Seal no longer quest items (PT4)
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
# WGT (slice W2): the abilities' weights; the saddlebags' capacity, the blinders' panic resistance and the base
# horse's sprint cost (WGT-06, PW9)
NODES.update({"WGT-03": {"weight"}, "WGT-04": {"weight"}, "WGT-05": {"weight"},
              "WGT-06": {"weight", "encumbrance", "panic", "sprint_stamina_cost"}})
# OPT
NODES.update({})
# TRPH
NODES.update({})
# The child blocks of an item each feature owns (taken whole from legacy).
BLOCKS = {
    "ITEM-11": {"base_abilities"},  # the kits' quality abilities
    "CRAFT-01": {"base_abilities"},  # the schematic items' rarity (bugfix 183)
    "CRAFT-02": {"base_abilities"},
    "CRAFT-06": {"base_abilities"},  # the recipe items' rarity
    "CRAFT-07": {"base_abilities"},  # the ingredients' rarity (bugfix 120)
    "CRAFT-08": {"recycling_parts"},  # the dismantling parts
    "FOOD-04": {"base_abilities", "recycling_parts"},
    "ECON-02": {"base_abilities"},  # Blood and Wine's dyes lose their Relic rarity (CRAFT's hand-off)
    "XBOW-02": {"base_abilities"},  # the two Blood and Wine quest crossbows on Toussaint Crossbow 1's stats  # the food and drink tier, rarity and toxicity abilities; Wolf liver's parts (none: audit F1)
}
# WGT
BLOCKS.update({})
# OPT
BLOCKS.update({})
# TRPH
BLOCKS.update({})
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
    # the list price (ECON-01 to ECON-03); NG+'s Gwent Almanac also stacks as its regular entry (ECON-02)
    "ECON-01": {"price"}, "ECON-02": {"price", "stackable"}, "ECON-03": {"price"}, "ECON-04": {"price"},
}
# WGT: an item's own weight (WGT-03 to WGT-06; the abilities' <weight> nodes in NODES)
ATTRS.update({f: {"weight"} for f in ("WGT-03", "WGT-04", "WGT-05", "WGT-06")})
# WGT, slice W3 (DW2, the owner's decision, 2026-11-02): the weights of 5.x's new gear, the legacy weight of the
# counterpart ECON's DE2 gave each piece (as the game reads it: GetItemWeight), on the piece's `_Stats` ability
# where 5.x keeps it; the same for the NG+ copies (`NGP ` and items_plus). The Fire Horse gear keeps 5.x's (legacy
# left its counterparts at 1.32's); Heavy armor 03 Netflix and Heavy gloves 04 Netflix share their counterparts'
# abilities (legacy's since slice W2). `gen_wgt.py --verify` recomputes each from DE2 and the branches.
DW2 = {}
for _t in ("", " 1", " 2"):
    DW2.update({f"Netflix Armor{_t} _Stats": 10, f"Netflix Boots{_t} _Stats": 4, f"Netflix Gloves{_t} _Stats": 3,
                f"Netflix Pants{_t} _Stats": 3, f"Netflix steel sword{_t} _Stats": 4, f"Netflix silver sword{_t} _Stats": 2})
for _s in ("Dol Blathanna", "White Tiger"):
    DW2.update({f"{_s} Armor _Stats": 15, f"{_s} Boots _Stats": 4.5, f"{_s} Gloves _Stats": 3.5, f"{_s} Pants _Stats": 3.5})
DW2.update({"Scarlet Crest Armor _Stats": 15, "Scarlet Crest Boots _Stats": 5, "Scarlet Crest Gauntlets _Stats": 2,
            "Scarlet Crest Trousers _Stats": 3, "Dol Blathanna longsword _Stats": 6, "Steel Vixen _Stats": 6,
            "White Widow of Dol Blathanna _Stats": 4, "Silver Vixen _Stats": 4, "Top Notch Steel Sword _Stats": 6,
            "Top Notch Silver sword _Stats": 4})


def dw2_weight(ability):
    """DW2's weight of a 5.x ability (its `NGP ` copy as the regular one), or None."""
    return DW2.get(ability[4:] if ability.startswith("NGP ") else ability)
# OPT
ATTRS.update({})
# TRPH
ATTRS.update({})

# DE2 (ECON-01, ECON-03; the owner's decision, 2026-11-01): the list prices of 5.x's new gear, schematics and
# horse gear, by analogy with a legacy counterpart (legacy never had these items, so they are no ECON units).
# {5.x item name: (price, counterpart, rule)}: "ratio" is round(5.x's price x the counterpart's legacy / 1.32
# price), "copy" the counterpart's legacy price (an item with the counterpart's stats), "owner" a figure the
# owner wrote in the decision (the ratio's own result in the comment). `gen_econ.py --verify` recomputes every
# price from the branches. The Netflix set (and its schematics) by the Wolf School piece of the same tier, the
# owner's choice; each Netflix schematic and Top Notch at its counterpart's legacy price (the owner's decision on
# the ECON audit's F3, 2026-11-01); the other sets by hand (econ.md's DE2 table). NG+: the same price, for the
# same name in `items_plus` and for 5.x's `NGP ` copies (legacy's NG+ prices equal its regular ones, PE3).
# Applied by whichever tool writes the entry: gen_arm_new.py (the lower Netflix armor tiers), gen_swd_items.py
# (SWD-10's swords), gen_econ.py (the rest). Gwent cards, potions and quest items keep 5.x's prices.
DE2 = {}
for _p, _w, _t in (("Armor", "Wolf Armor", (1, 3, 4)), ("Boots", "Wolf Boots", (2, 4, 5)),
                   ("Gloves", "Wolf Gloves", (2, 4, 5)), ("Pants", "Wolf Pants", (2, 4, 5))):
    _sch = "Witcher Wolf Jacket" if _p == "Armor" else "Witcher Wolf " + _p
    for _i, _s in enumerate(("", " 1", " 2")):
        DE2[f"Netflix {_p}{_s}"] = (None, f"{_w} {_t[_i]}", "ratio")
        _u = _t[_i] - (0 if _p == "Armor" or _t[_i] == 5 else 1)  # the Upgrade schematic that crafts it
        DE2[f"Netflix {_p} schematic{_s}"] = (None, f"{_sch} Upgrade schematic {_u}", "copy")
for _k in ("steel", "silver"):
    for _i, _s in enumerate(("", " 1", " 2")):
        DE2[f"Netflix {_k} sword{_s}"] = (None, f"Wolf School {_k} sword {(1, 3, 4)[_i]}", "ratio")
        DE2[f"Netflix {_k} sword schematic{_s}"] = (None, f"Wolf School {_k} sword Upgrade schematic {(1, 3, 4)[_i]}", "copy")
    DE2[f"Reinald Netflix {_k} sword"] = (None, f"Wolf School {_k} sword 1", "ratio")  # = the first tier (SWD-10)
for _n in [n for n in DE2 if "schematic" in n]:
    DE2["NGP " + _n] = DE2[_n]  # 5.x's NG+ schematics in the regular folder: as the regular ones
_PRICES = {  # the resulting prices (checked against the rule by gen_econ.py --verify)
    "Netflix Armor": 842, "Netflix Armor 1": 3240, "Netflix Armor 2": 5040,
    "Netflix Boots": 634, "Netflix Boots 1": 1660, "Netflix Boots 2": 2620,
    "Netflix Gloves": 570, "Netflix Gloves 1": 1410, "Netflix Gloves 2": 2298,
    "Netflix Pants": 604, "Netflix Pants 1": 1665, "Netflix Pants 2": 3272,
    "Netflix steel sword": 544, "Netflix steel sword 1": 1402, "Netflix steel sword 2": 1709, "Reinald Netflix steel sword": 544,
    "Netflix silver sword": 631, "Netflix silver sword 1": 1650, "Netflix silver sword 2": 2540, "Reinald Netflix silver sword": 631,
    "Netflix Armor schematic": 173, "Netflix Armor schematic 1": 638, "Netflix Armor schematic 2": 1027,
    "Netflix Boots schematic": 65, "Netflix Boots schematic 1": 332, "Netflix Boots schematic 2": 524,
    "Netflix Gloves schematic": 114, "Netflix Gloves schematic 1": 267, "Netflix Gloves schematic 2": 460,
    "Netflix Pants schematic": 122, "Netflix Pants schematic 1": 328, "Netflix Pants schematic 2": 520,
    "Netflix steel sword schematic": 100, "Netflix steel sword schematic 1": 270, "Netflix steel sword schematic 2": 345,
    "Netflix silver sword schematic": 114, "Netflix silver sword schematic 1": 322, "Netflix silver sword schematic 2": 505,
}
for _n, _v in list(_PRICES.items()):
    if "schematic" in _n:
        _PRICES["NGP " + _n] = _v
for _n in DE2:
    DE2[_n] = (_PRICES[_n],) + DE2[_n][1:]
# The owner's figures for two Netflix trousers (the ratio gives 605 and 3,273): the decision's numbers kept.
DE2["Netflix Pants"] = (604, "Wolf Pants 2", "owner")
DE2["Netflix Pants 2"] = (3272, "Wolf Pants 5", "owner")
DE2.update({
    # copies of a 1.32 item (its price and stats): that item's legacy price
    "Heavy armor 03 Netflix": (856, "Heavy armor 03", "ratio"),
    "Heavy gloves 04 Netflix": (470, "Heavy gloves 04", "ratio"),
    # Dol Blathanna and White Tiger (relic medium armor, levels 8 and 12, the same 5.x prices): the relic medium
    # piece of the same slot nearest in 1.32 price
    "Dol Blathanna Armor": (714, "Medium armor 10r", "ratio"), "White Tiger Armor": (714, "Medium armor 10r", "ratio"),
    "Dol Blathanna Boots": (288, "Heavy boots 07_crafted", "ratio"), "White Tiger Boots": (288, "Heavy boots 07_crafted", "ratio"),
    "Dol Blathanna Gloves": (280, "Guard Lvl2 Gloves 3", "ratio"), "White Tiger Gloves": (280, "Guard Lvl2 Gloves 3", "ratio"),
    "Dol Blathanna Pants": (343, "Guard Lvl2 Pants 3", "ratio"), "White Tiger Pants": (343, "Guard Lvl2 Pants 3", "ratio"),
    # Scarlet Crest (relic medium armor, level 41): the same rule
    "Scarlet Crest Armor": (755, "Medium armor 11r", "ratio"), "Scarlet Crest Boots": (320, "Heavy boots 07", "ratio"),
    "Scarlet Crest Gauntlets": (563, "Thief Gloves", "ratio"), "Scarlet Crest Trousers": (232, "Thief Pants", "ratio"),
    # the relic swords (Dol Blathanna, the Nine-Tailed Vixen, Top Notch): the relic sword of the same kind nearest
    # in 1.32 price; Top Notch (both 5.x prices placeholders) at its counterpart's legacy price (F3)
    "Dol Blathanna longsword": (1145, "Lune", "ratio"), "Steel Vixen": (1145, "Lune", "ratio"),
    "White Widow of Dol Blathanna": (1289, "Harpy", "ratio"), "Silver Vixen": (1289, "Harpy", "ratio"),
    "Top Notch Steel": (1500, "Eredin Sword", "copy"), "Top Notch Silver": (1050, "Breathofthenorth", "copy"),
    # the Fire Horse gear has the stats of Blood and Wine's Toussaint gear: legacy's price of that piece
    "Fire Horse Saddle": (450, "Toussaint saddle", "copy"), "Fire Horse Blinders": (250, "Toussaint horse blinders", "copy"),
    "Fire Horse Saddlebags": (450, "Toussaint horsebag", "copy"),
})
_DE2_LOWER = {n.lower(): n for n in DE2}


def de2_name(name):
    """The DE2 key of an item name (5.x's `NGP ` copies and NG+'s spelling variants map to the regular item),
    or None."""
    n = name.lower()
    if n in _DE2_LOWER:
        return _DE2_LOWER[n]
    if n.startswith("ngp ") and n[4:] in _DE2_LOWER:
        return _DE2_LOWER[n[4:]]
    return None


def de2_price(name):
    k = de2_name(name)
    return DE2[k][0] if k else None


def apply_de2(name, entry):
    """`entry` with DE2's price set on its opening tag (unchanged for an item DE2 does not price)."""
    p = de2_price(name)
    if p is None:
        return entry
    h, end = head(entry)
    if "price" in h:
        return entry[:h["price"][0]] + str(p) + entry[h["price"][1]:]
    return entry[:end].rstrip() + f' price="{p}"' + entry[end:]


_UNITS = None
UNIT =re.compile(r'^(.*/gameplay/)(items|items_plus|items\*)(/[^/]+\.xml)::definitions/(items/item|abilities/ability):(.+)$')


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
    if "mod_*" in own:
        own.discard("mod_*")
        own |= {t for t in set(mtags) | set(ltags) if t.startswith("mod_") and t not in ECON_KEEP}
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


def ability_nodes(folder, name, area=None):
    out = set()
    for f in ported(folder, "ability", name):
        if area and not f.startswith(area):
            continue
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


def merge_nodes(folder, name, mn, ln, body, nodes_fn, norm, area=None):
    """`body` (an ability body) with ITEM's ported node changes; mn, ln: 1.32's and legacy's nodes
    (as `gen_arm_items.nodes`); `nodes_fn` parses a body, `norm` normalises a node's text; `area`: only the
    features of these prefixes (None: every area's)."""
    own = ability_nodes(folder, name, area)
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


def apply_item(folder, name, mentry, lentry, entry, area=("CRAFT-", "ECON-", "WGT-")):
    """`entry` (an item's entry as a generator writes it) with every ported ITEM, CRAFT, ECON and WGT field of
    the item (by default CRAFT's, ECON's and WGT's: the item tools apply ITEM's themselves; None: every area's):
    tags, opening-tag attributes and child blocks; [changes]. Idempotent."""
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


def resolve_extend(stub, ventry):
    """The entry the game reads for an `on_conflict="extend"` item entry `stub` over 5.x's `ventry`
    (verified, ECON slice E1): the stub's opening-tag attributes set, its `<tags>` added (a tag written
    `-tag` removed). Any other child of the stub is not supported (ValueError)."""
    h, end = head(stub)
    attrs = {a: stub[s:e].strip() for a, (s, e) in h.items() if a not in ("name", "on_conflict")}
    inner = re.sub(r'<!--.*?-->', '', stub[end + 1:], flags=re.S)
    inner = re.sub(r'</item>\s*$', '', inner.strip())
    tm = re.search(r'<tags>(.*?)</tags>', inner, re.S)
    if re.sub(r'<tags>.*?</tags>', '', inner, flags=re.S).strip():
        raise ValueError("extend entry with children other than <tags>")
    entry = ventry
    for a, val in attrs.items():
        vh, vend = head(entry)
        if a in vh:
            entry = entry[:vh[a][0]] + val + entry[vh[a][1]:]
        else:
            entry = entry[:vend].rstrip() + f' {a}="{val}"' + entry[vend:]
    if tm:
        tags = split_tags(entry)
        for t in (x.strip() for x in tm.group(1).split(",") if x.strip()):
            if t.startswith("-"):
                tags = [x for x in tags if x != t[1:]]
            elif t not in tags:
                tags.append(t)
        vt = re.search(r'(<tags>)(.*?)(</tags>)', entry, re.S)
        if vt:
            entry = entry[:vt.start(2)] + ", ".join(tags) + entry[vt.end(2):]
        else:
            vh, vend = head(entry)
            entry = entry[:vend + 1] + f"\n\t\t<tags>{', '.join(tags)}</tags>" + entry[vend + 1:]
    return entry


def empty_item(name):
    """What a Hearts of Stone item reads after an `extend` (verified, ECON slice E1: no price, category,
    tags, texts or weight)."""
    return f'<item name="{name}"></item>'
