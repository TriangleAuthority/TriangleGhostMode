"""Generate FOOD's definition overrides for Ghost Mode's DLC: legacy's food effects, drink and toxicity
abilities and cooking recipes (docs/features/food.md).

The same technique as `gen_alch.py` (whose functions it reuses): each listed ability is taken from
`legacy-GM` whole and written into Ghost Mode's DLC, on_conflict="replace" where `vanilla-5.x` defines it,
as a plain new entry otherwise; weights (WGT) and item prices (ECON) stay 5.x's. The food and drink items
themselves are not written here: their FOOD fields go through `item_layer.py` and `gen_item.py` (DF9, each
item defined once). The list grows with each port slice (food.md's port order).

New Game+ (`items_plus`): the entry as legacy's NG+ file has it (legacy's NG+ food files equal the regular).

    python tools/gen_food.py --worktree DIR [--check | --verify [--list]]

Writes `items/gm_food.xml` and `items_plus/gm_food.xml` in Ghost Mode's DLC (--worktree, required). --check writes nothing and fails if a file is out of date. --verify writes nothing and
compares every listed entry as the port leaves it with legacy's, node by node, and lists for information
the entries of the food files still differing from legacy's and not listed.

Needs, not in this repository: the game install (5.x; found by tools/paths.py through Steam or W3_GAME_DIR)'s string tables (content/content0/*.w3strings).
"""
import os, re, sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import gen_alch as g  # noqa: E402
import paths  # noqa: E402  (tools/: below-normal priority)

g.OUT = "gm_food.xml"
g.GENERATOR = "tools/gen_food.py"
g.FILES = {
    "effects": "modGhostMode/files/gameplay/%s/effects.xml",
    "ep1_effects": "modGhostMode/files/dlc/ep1/data/gameplay/%s/effects.xml",
    "edibles": "modGhostMode/files/gameplay/%s/def_item_edibles.xml",
}
g.folder_of = lambda key, folder: folder.replace("items", "abilities") if key.endswith("effects") else folder

# (file key, feature, kind, names), in port order.
g.SPEC = [
    ("effects", "FOOD-01: Well Fed and Well Hydrated: 60 s for every tier; food 10/20/30 Vitality/s out of combat, 1/5/10 in "
     "combat; drinks 5/10/20 and 1/5/10, plus 1/2/3% stamina regen (the owner's DF1)", "ability",
     ["WellFedEffect_Level%d" % i for i in (1, 2, 3)] + ["WellHydratedEffect_Level%d" % i for i in (1, 2, 3)]),
    ("ep1_effects", "FOOD-01: Cornucopia's Well Fed, 30 s at 15 in and out of combat (DF1)", "ability", ["WellFedEffect_Cornucopia"]),
    ("edibles", "FOOD-02: drinks give Well Hydrated (the owner's DF2)", "ability", ["BeverageQuality_%d" % i for i in (1, 2, 3)]),
    ("edibles", "FOOD-05: the toxicity the items name: beer and other mild alcohol 5, wine and spirits 10, raw meat and fish 5 "
     "(the owner's DF5; added with the items, FOOD-04)", "ability", ["alco_toxicity", "alco_toxicity_strong", "food_toxicity"]),
    ("effects", "FOOD-05: drunkenness lasts 60 s (DF5)", "ability", ["DrunkennessEffect"]),
]
g.KEEP_5X = {}
g.RENAME = {}
g.BINARIES = []

# FOOD-07: the cooking recipes (the owner's DF8): legacy's 27 recipe items and their <alchemy_recipes>
# entries (cookedItemType "edibles", EACIT_Edibles in food/cooking.ws); Butter Bandalura's, commented out
# in legacy's data, stays out. The recipe items are named "Recipe: <dish>" with vanilla's pattern
# (item_name_recipe_for_scrambled_eggs: "Recipe: Scrambled eggs") and vanilla's recipe description
# item_desc_recipe_food (the owner's Q1); their names are written to the string table
# localization/modGhostModeFood (ids from RECIPE_ID_BASE, one per recipe in legacy's order; the dish names
# and the prefix from the game's own tables, so the game must be installed).
g.FILES["cooking"] = "modGhostMode/files/gameplay/%s/def_item_cooking_recipes.xml"
RECIPE_ID_BASE = 2110992639
LANGS = ["br", "cz", "de", "en", "es", "fr", "it", "pl", "ru"]
STRINGS = "modGhostMode/localization/modGhostModeFood/%s.csv"
RECIPE = re.compile(r"(?s)<recipe\b.*?</recipe>")


def recipe_names():
    """The recipe items legacy defines (comments dropped), in file order."""
    text = re.sub(r"(?s)<!--.*?-->", "", g.source("cooking", "items", "legacy-GM"))
    return re.findall(r'<item\s+name\s*=\s*"(Recipe for [^"]+)"', text)


def dish_key(body):
    return re.search(r'localisation_key_name\s*=\s*"([^"]+)"', body).group(1)


def gm_key(key):
    return "gm_item_name_recipe_for_" + re.sub(r"^item_name_", "", key)


def _q1(body, vanilla):
    key = dish_key(body)
    body = re.sub(r'(localisation_key_name\s*=\s*")[^"]+(")', lambda m: m.group(1) + gm_key(key) + m.group(2), body, count=1)
    return re.sub(r'(localisation_key_description\s*=\s*")[^"]+(")', lambda m: m.group(1) + "item_desc_recipe_food" + m.group(2), body, count=1)


RECIPES = recipe_names()
g.SPEC.append(("cooking", "FOOD-07: the cooking recipe items (legacy's; named \"Recipe: <dish>\" with vanilla's recipe description, Q1)",
               "item", RECIPES))
for _n in RECIPES:
    g.KEEP_5X[_n] = ("FOOD-07, Q1", _q1)


def recipe_map(text):
    out = {}
    for r in RECIPE.finditer(text):
        out[re.search(r'name_name\s*=\s*"([^"]+)"', r.group(0)).group(1)] = r.group(0)
    return out


def recipe_entries(folder, branch="legacy-GM"):
    """name -> <recipe> entry of the cooking file's <alchemy_recipes> block (comments dropped)."""
    text = re.sub(r"(?s)<!--.*?-->", "", g.source("cooking", folder, branch))
    m = re.search(r"(?s)<alchemy_recipes>(.*?)</alchemy_recipes>", text)
    return recipe_map(m.group(1) if m else "")


def recipes_block(folder):
    lines = ["\t<custom>", "\t\t<alchemy_recipes>",
             "\t\t\t<!-- FOOD-07: legacy's cooking recipes, brewed in the alchemy menu as their own group (DF8) -->"]
    for name, body in recipe_entries(folder).items():
        depth = 0
        for l in [x.strip() for x in body.split("\n") if x.strip()]:
            if l.startswith("</"):
                depth -= 1
            lines.append("\t" * (3 + max(depth, 0)) + re.sub(r"\s+", " ", l))
            if l.startswith("<recipe") or (l.startswith("<ingredients>") and "</ingredients>" not in l):
                depth += 1
    return lines + ["\t\t</alchemy_recipes>", "\t</custom>"]


_build = g.build


def build(folder):
    text = _build(folder)
    return text.replace("\t</definitions>\r\n</redxml>", "\t</definitions>\r\n" + "\r\n".join(recipes_block(folder)) + "\r\n</redxml>")


g.build = build


def norm_recipe(body):
    return sorted(re.findall(r'(\w+)\s*=\s*"([^"]*)"', body))


_verify = g.verify


def verify(worktree):
    bad = _verify(worktree)
    for folder in ["items", "items_plus"]:
        port = recipe_map(open(os.path.join(worktree, g.DLC, folder, g.OUT), encoding="utf-8-sig").read())
        legacy = recipe_entries(folder)
        diff = [n for n in legacy if n not in port or norm_recipe(port[n]) != norm_recipe(legacy[n])] + [n for n in port if n not in legacy]
        print("%s: %d cooking recipes compared with legacy's%s" % (folder, len(legacy), (": DIFF " + ", ".join(diff)) if diff else ", no difference"))
        bad |= bool(diff)
    for lang in LANGS:
        path = os.path.join(worktree, STRINGS % lang)
        if not os.path.exists(path) or open(path, encoding="utf-8").read().replace("\r\n", "\n") != strings(lang):
            print("strings %s: out of date" % lang)
            bad = 1
    print("strings: %d recipe names in %d languages checked" % (len(RECIPES), len(LANGS)))
    print("verify:", "differences found" if bad else "no difference")
    return bad


g.verify = verify


def _table(lang):
    import w3strings
    p = os.path.join(w3strings.game_dir(), "content", "content0", lang + ".w3strings")
    _, _, strs, keys = w3strings.decode(open(p, "rb").read(), lang)
    byid, h2id = dict(strs), {a: b for a, b in keys}
    return lambda key: byid.get(h2id.get(w3strings.key_hash(key)))


def strings(lang):
    """The recipe names' string table for one language: vanilla's "Recipe: " prefix and dish casing."""
    look = _table(lang)
    sample = look("item_name_recipe_for_scrambled_eggs")
    cut = sample.index(":") + 1
    while cut < len(sample) and sample[cut].isspace():
        cut += 1
    prefix, lower = sample[:cut], sample[cut:cut + 1].islower()
    legacy = g.entries(g.source("cooking", "items", "legacy-GM"), "item")
    rows = [";meta[language=%s]" % lang, "; id      |key(hex)|key(str)| text",
            "; Generated by tools/gen_food.py: FOOD-07's cooking recipe names (\"Recipe: <dish>\", the owner's Q1); do not edit."]
    for i, n in enumerate(RECIPES):
        key = dish_key(legacy[n])
        dish = look(key) or key
        if lower:
            dish = dish[:1].lower() + dish[1:]
        rows.append("%d|        |%s|%s%s" % (RECIPE_ID_BASE + i, gm_key(key), prefix, dish))
    return "\n".join(rows) + "\n"


def write_strings(worktree, check):
    bad = 0
    for lang in LANGS:
        path = os.path.join(worktree, STRINGS % lang)
        text = strings(lang)
        old = open(path, encoding="utf-8").read().replace("\r\n", "\n") if os.path.exists(path) else None
        if old != text:
            if check:
                print("out of date:", path)
                bad = 1
            else:
                os.makedirs(os.path.dirname(path), exist_ok=True)
                open(path, "w", encoding="utf-8", newline="\n").write(text)
                print("wrote", path)
    return bad


if __name__ == "__main__":
    paths.below_normal()
    if "--verify" not in sys.argv and "--worktree" in sys.argv:  # without --worktree, g.main() stops: it is required
        wt = sys.argv[sys.argv.index("--worktree") + 1]
        if write_strings(wt, "--check" in sys.argv):
            sys.exit(1)
    g.main()
