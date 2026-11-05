"""Generate ALCH's definition overrides for Ghost Mode's DLC: legacy's potions, decoctions, bombs and oils
(docs/features/alch.md).

Takes each listed ability (or item) from `legacy-GM` whole and writes it into Ghost Mode's DLC, with
on_conflict="replace" where `vanilla-5.x` defines it, as a plain new entry otherwise. What belongs to other
areas stays 5.x's: an ability's `weight` nodes (WGT) and an item's `price` (ECON) are taken from 5.x's
entry. The owner's decisions that keep a piece of 5.x (alch.md's area decisions) are applied as listed
KEEP_5X changes. The list grows with each port slice (alch.md's port order): an entry not listed keeps
5.x's definition.

New Game+ (`items_plus`): the entry as legacy's NG+ file (`abilities_plus`, `items_plus`) has it.

    python tools/gen_alch.py --worktree DIR [--check | --verify]

Writes `items/gm_alch.xml` and `items_plus/gm_alch.xml` in Ghost Mode's DLC (--worktree, required). --check writes nothing and fails if a file is out of date. --verify writes nothing and
compares every listed entry as the port leaves it with legacy's, node by node (weights, prices and the
KEEP_5X changes excepted), and each binary file with 5.x's plus exactly its listed cr2w_patch.py edits; it also lists, for information, the entries of the alchemy files that still
differ from legacy's and are not listed (not ported yet, or other areas').
"""
import argparse, os, re, subprocess, sys
import paths  # noqa: E402  (tools/: the shared --worktree argument)

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DLC = "modGhostMode/files/dlc/dlcghostmode/data/gameplay/"
OUT = "gm_alch.xml"
GENERATOR = "tools/gen_alch.py"  # named in the generated file's header (gen_food.py reuses this module)
LIST = False
# Source files: key -> path pattern (%s = the folder; abilities files use abilities/abilities_plus).
FILES = {
    "mutagens": "modGhostMode/files/gameplay/%s/def_item_alchemy_mutagens.xml",
    "potions": "modGhostMode/files/gameplay/%s/def_item_alchemy_potion.xml",
    "petards": "modGhostMode/files/gameplay/%s/def_item_alchemy_petards.xml",
    "oils": "modGhostMode/files/gameplay/%s/def_item_alchemy_oils.xml",
    "bob_potions": "modGhostMode/files/dlc/bob/data/gameplay/%s/def_item_alchemy_potion.xml",
    "eff_mutagens": "modGhostMode/files/gameplay/%s/effects_mutagens.xml",
    "eff_potions": "modGhostMode/files/gameplay/%s/effects_potions.xml",
    "effects": "modGhostMode/files/gameplay/%s/effects.xml",
}
MUTAGENS = ["Mutagen_%d" % i for i in range(1, 29)]

# (file key, feature, kind, names), in port order.
SPEC = [
    ("mutagens", "ALCH-09: decoction toxicity offset 70 for all 28, Basilisk without its extra duration (the owner's DL2)",
     "ability", MUTAGENS),
    ("potions", "ALCH-03: potion values (toxicity, duration, charges; the durations from legacy's data, the owner's DL3)", "ability",
     ["BlackBlood_%d" % i for i in (1, 2, 3)] + ["Cat_%d" % i for i in (1, 2, 3)] + ["FullMoon_%d" % i for i in (1, 2, 3)]
     + ["PetriPhiltre_%d" % i for i in (1, 2, 3)] + ["TawnyOwl_%d" % i for i in (1, 2, 3)] + ["Thunderbolt_%d" % i for i in (1, 2, 3)]),
    ("eff_potions", "ALCH-03: potion effect values", "ability",
     ["BlackBloodEffect_Level%d" % i for i in (1, 2, 3)] + ["FullMoonEffect_Level%d" % i for i in (1, 2, 3)]
     + ["PetriPhiltreEffect_Level%d" % i for i in (1, 2, 3)] + ["ThunderboltEffect_Level1", "MariborForestEffect_Level2", "MariborForestEffect_Level3"]),
    ("potions", "ALCH-08: pheromones (10 toxicity, 120 s, quality 4), Killer Whale (10 toxicity, 180 s, one tier), Pops' Antidote (10 toxicity)",
     "ability", ["PheromonePotionBear_1", "PheromonePotionDrowner_1", "PheromonePotionNekker_1", "KillerWhale_1", "PopsImmunity"]),
    ("potions", "ALCH-04: Swallow, White Raffard's Decoction, White Honey; ALCH-05: Golden Oriole", "ability",
     ["Swallow_%d" % i for i in (1, 2, 3)] + ["WhiteRaffardDecoction_%d" % i for i in (1, 2, 3)]
     + ["WhiteHoney_%d" % i for i in (1, 2, 3)] + ["GoldenOriole_%d" % i for i in (1, 2, 3)]),
    ("eff_potions", "ALCH-04: Swallow's effect (bleeding resistance), White Raffard's (NG+ heals as the regular game's, audit F17); ALCH-05: Golden Oriole's effect (poison resistance, immunity time)",
     "ability", ["SwallowEffect_Level%d" % i for i in (1, 2, 3)] + ["WhiteRaffardDecoctionEffect_Level%d" % i for i in (1, 2, 3)]
     + ["GoldenOrioleEffect_Level%d" % i for i in (1, 2, 3)]),
    ("potions", "ALCH-07: Blizzard (legacy's: 25 toxicity, 30 s; the owner's DL4)", "ability", ["Blizzard_%d" % i for i in (1, 2, 3)]),
    ("eff_potions", "ALCH-07: Blizzard's slow motion x0.5/0.35/0.25; Cat without 5.x's crit chance (DL4)", "ability",
     ["BlizzardEffect_Level%d" % i for i in (1, 2, 3)] + ["CatEffect_Level%d" % i for i in (1, 2, 3)]),
    ("eff_mutagens", "ALCH-10: Katakan, Water Hag, Wyvern, Alghoul, Forktail (their stack abilities; Katakan 5% per stack, the owner's DL6)",
     "ability", ["Mutagen01Effect", "KatakanBonusEffect", "Mutagen05Effect", "Mutagen10Effect", "Mutagen15Effect", "Mutagen17Effect"]),
    ("eff_mutagens", "ALCH-11: Foglet, Succubus, Wraith, Ancient Leshen", "ability",
     ["Mutagen09Effect", "Mutagen14Effect", "Mutagen19Effect", "Mutagen22Effect"]),
    ("eff_mutagens", "ALCH-12: ArchGriffin, Troll, Noonwraith, Grave Hag, Ekhidna, Basilisk, Nekker Warrior", "ability",
     ["Mutagen04Effect", "Mutagen12Effect", "TrollBonusEffect", "Mutagen13Effect", "Mutagen18Effect", "Mutagen21Effect",
      "Mutagen23Effect", "Mutagen25Effect"]),
    ("eff_mutagens", "ALCH-13: Arachas, Doppler, Fiend, Elemental, Werewolf, Leshen, Griffin, Reliever's (the owner's DL6); ALCH-09: Ekimmara's data",
     "ability", ["Mutagen02Effect", "Mutagen11Effect", "Mutagen16Effect", "Mutagen20Effect", "Mutagen24Effect", "Mutagen26Effect",
                 "Mutagen27Effect", "Mutagen28Effect", "Mutagen07Effect"]),
]

# Pieces of 5.x kept by the owner's decisions: name -> (feature, function(body, vanilla body) -> body).
def _keep_poison_death(body, vanilla):
    # DL7: 5.x's Northern Wind blocks a rotfiend's PoisonDeath (its explosion), next to legacy's blocks.
    return re.sub(r'(<Burrow is_ability="true" />)', lambda m: m.group(1) + '\n<PoisonDeath is_ability="true" />', body, count=1)


KEEP_5X = {"WhiteFrost_%d_impact" % i: ("ALCH-14, DL7", _keep_poison_death) for i in (1, 2, 3)}
BOMBS = ["DancingStar_1_loop", "DancingStar_2_impact", "DancingStar_2_loop", "DancingStar_3_impact", "DancingStar_3_loop",
         "DevilsPuffball_1_loop", "DevilsPuffball_2_impact", "DevilsPuffball_2_loop", "DevilsPuffball_3_impact", "DevilsPuffball_3_loop",
         "DragonsDream_1", "DragonsDream_2", "DragonsDream_3", "Grapeshot_1", "Grapeshot_2", "Grapeshot_3", "Samum_1", "Samum_2", "Samum_3",
         "SilverDustBomb_1", "SilverDustBomb_2", "SilverDustBomb_3", "WhiteFrost_1_impact", "WhiteFrost_2_impact", "WhiteFrost_3_impact"]
BOMB_EFFECTS = (["BlindnessEffect_Samum_%d" % i for i in (1, 2, 3)] + ["BurningEffect_DancingStar_%d" % i for i in (1, 2, 3)]
                + ["PoisonEffect_DevilsPuffball_%d" % i for i in (1, 2, 3)] + ["FrozenEffect_WhiteFrost%d" % i for i in (1, 2, 3)]
                + ["SilverDustEffect_Level2", "SilverDustEffect_Level3"])


OILS = ["%s_%d" % (o, i) for o in ("BeastOil", "CursedOil", "HangedManVenom", "HybridOil", "InsectoidOil", "MagicalsOil",
                                    "NecrophageOil", "SpecterOil", "VampireOil", "DraconideOil", "OgreOil", "RelicOil")
        for i in (1, 2, 3)]


SPEC += [
    ("petards", "ALCH-14: bombs (legacy's fixed damage and roles, the owner's DL7; Samum 4/5/6 s, DL11)", "ability", BOMBS),
    ("effects", "ALCH-14: the bombs' effects", "ability", BOMB_EFFECTS),
    ("petards", "ALCH-15: Dimeritium bomb (legacy's: the cloud gives the Dimeritium effect, no direct blocks; the owner's DL7)", "ability",
     ["DwimeritiumBomb_%d" % i for i in (1, 2, 3)]),
    ("effects", "ALCH-15: the Dimeritium effect (20/30/40 s; magic creatures -50/75/100 armor, -5/10/15% resistances; mages -30/40/50% damage)",
     "ability", ["DimeritiumEffect_Level%d" % i for i in (1, 2, 3)]),
    ("oils", "ALCH-16: oils (+25% attack power at every tier, +5% crit chance from tier 2, +25% crit damage at tier 3, no resistance "
     "reduction; the ogroid oil's vsOgre_ attributes)", "ability", OILS),
    ("oils", "ALCH-16: Hanged Man's Venom on steel swords only (5.x's SilverOil tag dropped, the owner's DL9)", "item",
     ["Hanged Man Venom %d" % i for i in (1, 2, 3)]),
]

# Entries Ghost Mode adds under a new name (the GM prefix for added entries; an effect ability's name starts
# with its effect's name, GMDimeritiumEffect): legacy name -> port name, also renamed where other entries
# refer to them.
RENAME = {"DimeritiumEffect_Level%d" % i: "GMDimeritiumEffect_Level%d" % i for i in (1, 2, 3)}


# Binary files: path -> cr2w_patch.py edits; the port's copy must be 5.x's file with exactly these edits.
BINARIES = [
    # ALCH-15: the Dimeritium bomb's cloud (legacy: impact range 6 -> 4, cloud 6 -> 3; legacy changed the
    # template's compiled copy, the port both copies)
    ("modGhostMode/files/items/weapons/projectiles/petards/petard_dimeritium_bomb.w2ent",
     [("W3Dimeritium", "impactParams.range", 6.0, 4.0), ("W3Dimeritium", "loopParams.range", 6.0, 3.0)]),
]


def port_name(name):
    return RENAME.get(name, name)


def apply_rename(body):
    for old, new in RENAME.items():
        body = re.sub(r'(?<![\w])%s(?![\w])' % re.escape(old), new, body)
    return body


def git(*args):
    return subprocess.run(["git", "-C", REPO] + list(args), capture_output=True, check=True).stdout.decode("utf-8-sig")


def folder_of(key, folder):
    if key.startswith("eff") or key == "effects":
        return folder.replace("items", "abilities")
    return folder


def entries(text, kind):
    """name -> entry text; comments are dropped first (legacy comments entries out, e.g. Killer Whale's
    second definition); the first definition of a name is kept."""
    out = {}
    text = re.sub(r'(?s)<!--.*?-->', '', text)
    if kind == "ability":
        for m in re.finditer(r'(?ms)^([ \t]*)<ability\s+name="([^"]+)"(?:[^>]*?/>|[^>]*>.*?</ability>)', text):
            out.setdefault(m.group(2), m.group(0))
    else:
        # Items can nest <item> (variants): balance the tags.
        for m in re.finditer(r'(?m)^[ \t]*<item\s+name\s*=\s*"([^"]+)"', text):
            depth, pos = 0, m.start()
            for t in re.finditer(r'<item\b[^>]*?(/?)>|</item>', text[m.start():]):
                if t.group(0).startswith("</"):
                    depth -= 1
                elif not t.group(1):
                    depth += 1
                if depth == 0:
                    out.setdefault(m.group(1), text[m.start():m.start() + t.end()])
                    break
    return out


def source(key, folder, branch):
    try:
        return git("show", "%s:%s" % (branch, FILES[key] % folder_of(key, folder)))
    except subprocess.CalledProcessError:
        return ""


def weights(body):
    return re.findall(r'<weight\b[^>]*/>', body)


def build_entry(name, kind, legacy, vanilla):
    body = re.sub(r'[ \t]*<!--\s*modSigns[^>]*-->', '', legacy.strip())
    if vanilla is not None:
        # WGT: 5.x's weights; ECON: 5.x's price.
        lw, vw = weights(body), weights(vanilla)
        if lw or vw:
            body = re.sub(r'[ \t]*<weight\b[^>]*/>\s*\n?', '', body)
            if vw:
                body = re.sub(r'(<%s\b[^>]*>)' % kind, lambda m: m.group(1) + "\n" + "\n".join(vw), body, count=1)
        if kind == "item":
            vp = re.search(r'\bprice\s*=\s*"([^"]*)"', vanilla.split(">", 1)[0])
            if vp:
                body = re.sub(r'(<item\b[^>]*?\bprice\s*=\s*")[^"]*(")', lambda m: m.group(1) + vp.group(1) + m.group(2), body, count=1)
    if name in KEEP_5X:
        body = KEEP_5X[name][1](body, vanilla)
    if vanilla is not None:
        body = re.sub(r'^(<%s\s+name\s*=\s*"[^"]*")' % kind, r'\1 on_conflict="replace"', body, count=1)
    lines = [l.strip() for l in body.split("\n") if l.strip()]
    out = []
    depth = 0
    for l in lines:
        if l.startswith("</"):
            depth -= 1
        out.append("\t" * (3 + max(depth, 0)) + l)
        if re.match(r'<(ability|item|variants|variant|base_abilities|tags|recycling_parts)\b', l) and not l.endswith("/>") \
                and not re.search(r'</\w+>\s*$', l):
            depth += 1
    return "\n".join(out)


def build(folder):
    lines = ['<?xml version="1.0" encoding="UTF-8"?>', "<!-- Generated by %s from legacy-GM; do not edit. -->" % GENERATOR,
             "<redxml>", "\t<definitions>"]
    for kind, tag in [("ability", "abilities"), ("item", "items")]:
        block = []
        for key, feature, k, names in SPEC:
            if k != kind:
                continue
            legacy = entries(source(key, folder, "legacy-GM"), kind)
            vanilla = entries(source(key, folder, "vanilla-5.x"), kind)
            block.append("\t\t\t<!-- %s -->" % feature)
            for n in names:
                block.append(build_entry(port_name(n), kind, apply_rename(legacy[n]), vanilla.get(port_name(n))))
        if block:
            lines += ["\t\t<%s>" % tag] + block + ["\t\t</%s>" % tag]
    lines += ["\t</definitions>", "</redxml>", ""]
    return "﻿" + "\n".join(lines).replace("\r\n", "\n").replace("\n", "\r\n")


def norm_value(v):
    try:
        return repr(float(v))
    except ValueError:
        return v


def stats(body, kind):
    body = re.sub(r'(?s)<!--.*?-->', '', body)
    head = re.match(r'\s*<%s\b([^>]*)>' % kind, body)
    attrs = tuple(sorted((k, norm_value(v)) for k, v in re.findall(r'(\w+)\s*=\s*"([^"]*)"', head.group(1))
                         if k not in ("on_conflict", "price"))) if head else ()
    body = body[head.end():] if head else body
    out = [("<head>", attrs, "")]
    for m in re.finditer(r'(?s)<(\w+)\b([^>]*?)(/?)>(?:([^<]*?)</\1>)?', body):
        if m.group(1) in ("weight",):
            continue
        a = tuple(sorted((k, norm_value(v)) for k, v in re.findall(r'(\w+)\s*=\s*"([^"]*)"', m.group(2))))
        out.append((m.group(1), a, " ".join((m.group(4) or "").split())))
    return sorted(out)


def verify(worktree):
    bad = 0
    listed = {}
    for key, feature, kind, names in SPEC:
        for n in names:
            listed[(key, n)] = kind
    for folder in ["items", "items_plus"]:
        gm_text = open(os.path.join(worktree, DLC, folder, OUT), encoding="utf-8-sig").read()
        n = 0
        others = []
        for key in FILES:
            for kind in ["ability", "item"]:
                gm = entries(gm_text, kind)
                legacy = entries(source(key, folder, "legacy-GM"), kind)
                vanilla = entries(source(key, folder, "vanilla-5.x"), kind)
                master = entries(source(key, folder, "vanilla-1.32"), kind)
                for name, body in legacy.items():
                    final = gm.get(port_name(name), vanilla.get(port_name(name)))
                    if (key, name) in listed:
                        n += 1
                        if final is None:
                            print("MISSING %s: %s" % (folder, name))
                            bad = 1
                            continue
                        a, b = stats(final, kind), stats(apply_rename(body), kind)
                        if name in KEEP_5X:
                            b = stats(KEEP_5X[name][1](body, vanilla.get(name)), kind)
                        if a != b:
                            print("DIFF %s: %s\n  port only:   %s\n  legacy only: %s" % (
                                folder, name, [x for x in a if x not in b], [x for x in b if x not in a]))
                            bad = 1
                    elif final is not None and stats(final, kind) != stats(body, kind) and name in master:
                        others.append(name)
        print("%s: %d listed entries compared with legacy's" % (folder, n))
        if others:
            print("  not listed, still differing from legacy (later slices or other areas): %d%s" % (
                len(set(others)), (": " + ", ".join(sorted(set(others)))) if LIST else " (--list names them)"))
    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    import cr2w_patch
    for path, edits in BINARIES:
        port = open(os.path.join(worktree, path), "rb").read()
        vanilla = subprocess.run(["git", "-C", REPO, "show", "vanilla-5.x:" + path], capture_output=True, check=True).stdout
        expected, changes, hit = cr2w_patch.patch(vanilla, edits)
        ok = port == expected and cr2w_patch.check_crcs(port) and len(hit) == len(edits)
        print("%s %s: %s" % ("ok  " if ok else "DIFF", os.path.basename(path), "; ".join(changes)))
        bad |= not ok
    print("verify:", "differences found" if bad else "no difference")
    return bad


def main():
    ap = argparse.ArgumentParser()
    paths.add_worktree(ap)  # required: parallel areas each pass their own worktree
    ap.add_argument("--check", action="store_true")
    ap.add_argument("--verify", action="store_true")
    ap.add_argument("--list", action="store_true", help="with --verify: name the unlisted entries that differ")
    a = ap.parse_args()
    global LIST
    LIST = a.list
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
