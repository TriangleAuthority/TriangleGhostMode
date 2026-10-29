"""Generate AI's ability overrides for Ghost Mode's DLC: legacy's enemy stats (docs/features/ai.md).

Takes legacy's abilities (`legacy-GM`) whole and writes them into Ghost Mode's DLC, with
on_conflict="replace" where 5.x defines the name, as a new entry otherwise. Which abilities:

- SPEC: hand-listed (slice A1: the level abilities and NPC templates, plus `MonsterMHBoss`);
- AUTO: every ability unit `docs/features/attribution.csv` gives one of the AUTO features (AI-03 monster
  stats, AI-04 human armor and allies, AI-05 NPC, monster and secondary weapons, and since slice C1 AI-15
  the Wild Hunt and AI-16 weakened states and the djinn), from the file the unit
  names; abilities in item files go to `items/`, the others to `abilities/`;
- DA5: 5.x's new enemies' abilities, the porter's values by analogy (confirmed by the owner, 2026-10-28);
- PART (slice B1): the AI-08 abilities no AUTO feature or SPEC gives whole (the human combat-skill templates,
  the Wild Hunt's, the djinn's, a few Blood and Wine abilities): 5.x's entry whole with legacy's nodes for
  the tags legacy changed among PART_TAGS (AI-08's combat parameters and STAM-08's stamina values) and the
  AI-08 tags where legacy kept 1.32's value and 5.x changed it (AI-B audit F3: SkillShield), so the
  stats of features ported later stay 5.x's until their slice (since C1 the Wild Hunt's and the djinn's
  abilities are AUTO's, legacy's whole, and leave PART).

Nodes other features own are not legacy's: for the tags in LATER whose feature is not in PORTED, the
entry carries 5.x's nodes of that tag (none where 5.x has none). So the combat rolls (AI-08, the owner's
DA3, ported in B1), morale and attack tickets (AI-08), hit severity (AI-12), kill experience (XP) and weapon weight
(WGT) stay 5.x's until their slice; adding the feature to PORTED switches them to legacy's. Abilities
5.x does not define at all (legacy's new ones) are legacy's whole. Abilities listed here leave STAM-08's
`gm_npc_stamina.xml` (PA2: gen_npc_stamina.py's OWNED), so one DLC entry holds each.

New Game+: `abilities_plus` is written by gen_ngplus.py from the regular file (run it afterwards);
legacy's NG+ entries equal its regular ones, and gen_ngplus keeps legacy's values where legacy did not
scale them (PA14). `items_plus` (gen_ngplus reads abilities only) is written here, from legacy's
`items_plus` entries and 5.x's `items_plus` nodes for LATER. --verify checks all four folders.

    python tools/gen_ai.py [--worktree DIR] [--check | --verify]

Writes `abilities/<file>`, `items/<file>` and `items_plus/<file>` in Ghost Mode's DLC (default worktree
../TGM-5x-GM), and the in-game data test `tests/gmTestsAiData.ws` (per ability one value the port changes
from 5.x's, and one LATER value that must still read 5.x's; read by GMTest_ai03 in the regression run).
--check writes nothing and fails if a file is out of date.

--verify writes nothing and compares what the game reads (Ghost Mode's DLC over 5.x) with what this
tool means it to read, for every listed ability in every folder, node by node: legacy's nodes, 5.x's for
the LATER tags, the DA5 table; fails on any difference or on a listed name defined twice in a DLC
folder. It also lists the nodes where the port's legacy value replaces a value 5.x changed (PA1).
"""
import argparse, csv, os, re, subprocess, sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from gen_ench import abilities, ability_stats  # noqa: E402

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DLC = "modGhostMode/files/dlc/dlcghostmode/data/gameplay/"
MONSTER_NEW = "modGhostMode/files/gameplay/%s/monster_base_abl_new.xml"
OPP_BASE = "modGhostMode/files/gameplay/%s/opp_base_abl.xml"
EP1_MONSTER = "modGhostMode/files/dlc/ep1/data/gameplay/%s/monster_base_abl.xml"

# The features ported so far (ai.md's port order). B1 adds AI-08 (DA3 (a), owner, 2026-10-28), B2 AI-12,
# C1 AI-15 and AI-16, C3 AI-19 and AI-20.
PORTED = {"AI-01", "AI-02", "AI-03", "AI-04", "AI-05", "AI-08", "AI-12", "AI-15", "AI-16", "AI-19", "AI-20"}

# Tags of a listed ability that belong to another feature: 5.x's nodes until that feature is ported.
LATER = {
    "AI-08": {  # combat parameters (B1): legacy's rolls on every enemy (the owner's DA3 (a))
        "dodge_melee_light_chance", "dodge_melee_heavy_chance", "dodge_projectile_chance", "dodge_bomb_chance",
        "dodge_magic_chance", "dodge_fear_chance", "counter_chance", "counter_chance_per_hit",
        "hits_to_roll_counter", "hits_to_raise_guard", "raise_guard_chance", "raise_guard_chance_mult_per_hit",
        "lower_guard_chance", "delay_between_raise_guard", "critical_states_to_raise_guard", "taunt_chance",
        "teleport_chance", "teleport_on_hit_chance", "teleport_chance_per_hit", "hits_to_roll_tele",
        "parry_chance", "dash_movement_chance", "ticket_request_interval", "morale", "moraleRegen"},
    "AI-12": {"hit_severity"},  # poise (B2): legacy zeroed the stat its code no longer reads
    "XP": {"experience"},  # kill experience (the XP area)
    "WGT": {"weight"},  # weapon weight (the WGT area)
}

# (output file, source file pattern, feature, abilities), hand-listed, in port order.
SPEC = [
    ("gm_ai_levels.xml", OPP_BASE, "AI-01: the human level bonuses (per level; 6+ and 15+ levels above Geralt)",
     ["NPCLevelBonus", "NPCLevelBonusHigh", "NPCLevelBonusDeadly"]),
    ("gm_ai_levels.xml", MONSTER_NEW, "AI-01: the monster and animal level bonuses, the displayed level; AI-17: contract monsters (MonsterMHBoss: no health or attack power of its own, instant-kill immune)",
     ["MonsterLevelBonus", "MonsterLevelBonusGroup", "MonsterLevelBonusArmored", "MonsterLevelBonusGroupArmored",
      "MonsterLevelBonusHigh", "MonsterLevelBonusDeadly", "AnimalLevelBonus", "DisplayedLevelAbl", "BossNGPLevelBonus",
      "MonsterMHBoss"]),
    ("gm_ai_levels.xml", OPP_BASE, "AI-02: the NPC templates (constitution, MiniBoss, Boss)",
     ["ConDefault", "ConFrail", "ConFat", "ConAverage", "ConPudzian", "ConAthletic", "ConWitcher",
      "ConHumanoidMonster", "MiniBoss", "Boss"]),
    # AI-A audit F1: Hearts of Stone abilities (dlc/ep1) cannot take extend (it empties them), so STAM-08's
    # stamina values for the Caretaker and his shades came with legacy's whole abilities ahead of AI-19 (C3);
    # mon_caretaker_ep1 goes with them, as legacy's three abilities make the Caretaker's stats together.
    ("gm_ai_monsters.xml", EP1_MONSTER, "AI-19: the Caretaker's and his shades' abilities, legacy's whole "
     "(Hearts of Stone abilities take replace; STAM-08's stamina values inside)",
     ["mon_caretaker_ep1", "q604_caretaker", "q604_shades"]),
]

# AI-A audit F3: legacy's NG+-only changes (an ability legacy edited in its `_plus` file only, undoing 1.32's
# NG+-only nerfs and boosts, PA14): the attributed `_plus` units of the AUTO features whose name has no regular
# AUTO unit, written only into the NG+ folders (abilities_plus/PLUS_ONLY, items_plus/gm_ai_weapons.xml).
PLUS_ONLY = "gm_ai_ngplus.xml"

# Attribution-driven: feature -> output file (abilities in item files go to items/gm_ai_weapons.xml).
# A unit with several AUTO features goes to the first listed (NPC_Wild_Hunt_Armor AI-04's, the Hunt's weapons AI-05's).
# Since slice C3: AI-19's shovel abilities (items) and AI-20's fistfight abilities (the tiers, the quest fights,
# Geralt's fists; the NPC ones in gm_ai_humans.xml, Geralt's fists in items).
AUTO = {"AI-04": "gm_ai_humans.xml", "AI-03": "gm_ai_monsters.xml", "AI-05": "gm_ai_weapons.xml",
        "AI-15": "gm_ai_special.xml", "AI-16": "gm_ai_special.xml", "AI-19": "gm_ai_monsters.xml",
        "AI-20": "gm_ai_humans.xml"}
AUTO_TITLE = {
    "gm_ai_monsters.xml": "AI-03: monster stats (health, attack power, armor, resistances; legacy's whole)",
    "gm_ai_humans.xml": "AI-04: human NPC armor, allies' and quest humans' stats; AI-20: fistfight opponents (tiers, "
                        "quest fights; legacy's whole)",
    "gm_ai_weapons.xml": "AI-05: NPC, monster and secondary weapons; AI-19: the Caretaker's shovel; AI-20: Geralt's fists "
                         "(legacy's whole)",
    "gm_ai_special.xml": "AI-15, AI-16: the Wild Hunt (health, armor, resistances; mon_wild_hunt_default, the generals' "
                         "phase abilities), weakened states and the djinn (legacy's whole)",
}

# DA5 (owner, 2026-10-28: Ghost Mode numbers by analogy with legacy's nearest enemies, proposed by the
# porter, confirmed by the owner, 2026-10-28). 5.x's new enemies of its quest mq1060 "Devil's Pit":
# - the witcher Reinald (mq1060_witcher.w2ent): his template mq1060_Reinald is a copy of 1.32's ConDefault,
#   and his entity adds Boss and Gundar's quest-boss ability (qmq2038_gundar), which AI-02 and AI-03 give
#   legacy's values: so the template is legacy's ConDefault (80 Vitality, no fire resistance, stamina regen
#   x0.25), and he is a boss as legacy's Gundar is (1,880 Vitality base, +100 and +80% attack power, +10%
#   physical and +30% other resistances, +50% damage-over-time resistance);
# - the plague victims (ConDefaultSilver, 5.x's silver-vulnerable human template, 25 Essence): legacy's
#   ConDefault on Essence (80, no fire resistance, no attack damage of its own, stamina regen x0.25).
# The red-plague creature (mq1060_evil_spirit.w2ent) is built from Skellige's Hym (mon_him) and the leshen
# (mon_lessog_base), which AI-03 gives legacy's values: nothing of its own here.
# Since B1 (AI-08) their morale and taunt nodes are legacy's ConDefault's too (moraleRegen 0.10, no taunt chance).
DA5 = [
    ("gm_ai_humans.xml", "mq1060_Reinald", """<ability name="mq1060_Reinald" on_conflict="replace">
<tags> "base" </tags>
<level type="add" always_random="false" min="1" max="1" />
<vitality type="base" always_random="false" min="80" max="80" />
<stamina type="base" always_random="false" min="100" max="100" />
<morale type="base" always_random="false" min="100" max="100" />
<humanoid type="add" always_random="false" min="1.0" max="1.0" />
<staminaRegen type="mult" always_random="false" min="0.25" max="0.25" />
<moraleRegen type="mult" always_random="false" min="0.10" max="0.10" />
<attack_light is_ability="true" />
<attack_heavy is_ability="true" />
</ability>"""),
    ("gm_ai_humans.xml", "ConDefaultSilver", """<ability name="ConDefaultSilver" on_conflict="replace">
<tags> "base" </tags>
<level type="add" always_random="false" min="1" max="1" />
<essence type="base" always_random="false" min="80" max="80" />
<stamina type="base" always_random="false" min="100" max="100" />
<morale type="base" always_random="false" min="100" max="100" />
<humanoid type="add" always_random="false" min="1.0" max="1.0" />
<staminaRegen type="mult" always_random="false" min="0.25" max="0.25" />
<moraleRegen type="mult" always_random="false" min="0.10" max="0.10" />
<attack_light is_ability="true" />
<attack_heavy is_ability="true" />
</ability>"""),
]

# Items given whole (slice C3): legacy's entry (`on_conflict="replace"` where 5.x defines the name) into
# items/ITEMS_FILE and, from legacy's `items_plus` entries, items_plus/ITEMS_FILE: (legacy path pattern, comment, names).
ITEMS_FILE = "gm_ai_weapons.xml"
ITEMS = [
    ("modGhostMode/files/dlc/ep1/data/gameplay/%s/def_item_weapons.xml",
     "AI-19: the Caretaker's shovel and his phantom body weapon name legacy's own Caretaker Shovel _Stats (5.x: the shared "
     "Shovel _Stats); legacy's item entries whole (Hearts of Stone items take replace)",
     ["Caretaker Shovel", "caretaker_body"]),
]


def _git_text(ref, path):
    r = subprocess.run(["git", "-C", REPO, "show", "%s:%s" % (ref, path)], capture_output=True)
    return r.stdout.decode("utf-8-sig", "replace") if r.returncode == 0 else ""


def item_texts(text):
    """{name: entry} of the top-level <item> elements of a definitions file (comments removed)."""
    from gen_arm_items import item_spans
    text = re.sub(r'(?s)<!--.*?-->', '', text)
    out = {}
    for start, end, head in item_spans(text):
        m = re.search(r'\bname\s*=\s*"([^"]+)"', head)
        if m:
            out[m.group(1)] = text[start:end]
    return out


_vitems = {}


def vanilla_items(folder):
    """{name: entry} of every item 5.x defines in gameplay/<folder>/ (base game and DLCs)."""
    if folder not in _vitems:
        out = {}
        for path in git("ls-tree", "-r", "--name-only", "vanilla-5.x", "--", "modGhostMode/files").splitlines():
            if re.search(r"/gameplay/%s/[^/]+\.xml$" % folder, path):
                for n, e in item_texts(_git_text("vanilla-5.x", path)).items():
                    out.setdefault(n, e)
        _vitems[folder] = out
    return _vitems[folder]


def item_want(pattern, folder, name):
    """The port's item entry: legacy's whole, replace where 5.x defines the name."""
    legacy = item_texts(_git_text("legacy-GM", pattern % folder)).get(name)
    if legacy is None:
        raise SystemExit("legacy-GM has no item %s in %s" % (name, pattern % folder))
    if name in vanilla_items(folder):
        legacy = re.sub(r'^<item\b', '<item on_conflict="replace"', legacy)
    return legacy


def item_norm(text):
    return re.sub(r'\s+', ' ', text).strip()


# Slice B1: AI-08's abilities that nothing above gives whole (attribution-driven: every regular AI-08 ability
# unit not in SPEC, AUTO or DA5), written into PART_FILE as 5.x's entry with legacy's nodes of the tags legacy
# changed among PART_TAGS (AI-08's combat parameters, STAM-08's stamina values: they leave gm_npc_stamina.xml,
# PA2) and, since slice B2, AI-12's hit severity (legacy's 0 in the human combat templates and the Wild Hunt's
# generals); every other node 5.x's (AI-15's and AI-16's stats, legacy's tag fix of CaranthirStrong: AI-15's).
PART_FEATURE = "AI-08"
PART_FILE = "gm_ai_combat.xml"


def part_tag(tag):
    """AI-08's combat parameters, STAM-08's stamina values and, once AI-12 is ported (B2), its hit severity."""
    return tag in LATER["AI-08"] or "stamina" in tag.lower() or ("AI-12" in PORTED and tag in LATER["AI-12"])


NODE = re.compile(r'(?s)<(\w+)\b[^>]*?(?:/>|>.*?</\1>)')


def git(*args):
    return subprocess.run(["git", "-C", REPO] + list(args), capture_output=True, check=True).stdout.decode("utf-8-sig")


_cache = {}


def show(ref, path):
    if (ref, path) not in _cache:
        r = subprocess.run(["git", "-C", REPO, "show", "%s:%s" % (ref, path)], capture_output=True)
        _cache[ref, path] = abilities(r.stdout.decode("utf-8-sig", "replace")) if r.returncode == 0 else {}
    return _cache[ref, path]


_all = {}


def all_abilities(ref, folder):
    """{name: entry} of every ability in <ref>'s gameplay/<folder>/*.xml (base game and DLCs); the first wins."""
    if (ref, folder) not in _all:
        out = {}
        for path in git("ls-tree", "-r", "--name-only", ref, "--", "modGhostMode/files").splitlines():
            if re.search(r"/gameplay/%s/[^/]+\.xml$" % folder, path):
                for n, e in show(ref, path).items():
                    out.setdefault(n, e)
        _all[ref, folder] = out
    return _all[ref, folder]


def later_tags():
    return {t for f, tags in LATER.items() if f not in PORTED for t in tags}


def auto_units():
    """[(output file, regular folder, legacy path pattern, name, features)] of the AUTO abilities."""
    hand = {n for _, _, _, names in SPEC for n in names} | {n for _, n, _ in DA5}
    if "units" in _cache:
        return _cache["units"]
    out, seen = [], set()
    with open(os.path.join(REPO, "docs/features/attribution.csv"), encoding="utf-8") as f:
        for row in csv.reader(f):
            m = re.match(r"files/((?:.*/)?)gameplay/(abilities|items)\*?/([^/]+\.xml)::definitions/abilities/ability:(.+)$", row[0])
            if not m or "_plus" in row[0]:
                continue
            feats = row[1].split()
            hit = [x for x in AUTO if x in feats]
            name, folder = m.group(4), m.group(2)
            if not hit or name in hand or name in seen:
                continue
            pattern = "modGhostMode/files/%sgameplay/%%s/%s" % (m.group(1), m.group(3))
            if name not in show("legacy-GM", pattern % folder):
                continue  # a unit of the file 5.x defines it in; legacy moved it (its own file's unit is used)
            seen.add(name)
            outf = "gm_ai_weapons.xml" if folder == "items" else AUTO[hit[0]]
            out.append((outf, folder, pattern, name, feats))
    _cache["units"] = out
    return out


def plus_units():
    """[(output file, NG+ folder, legacy path pattern, name, features)] of legacy's NG+-only AUTO abilities
    (audit F3): attributed `_plus` units whose name has no regular unit here (legacy changed only the NG+
    entry, mostly to make it equal its regular one) and 5.x has not made the same change."""
    if "plus" in _cache:
        return _cache["plus"]
    regular = {u[3] for u in auto_units()} | {n for _, _, _, names in SPEC for n in names} | {n for _, n, _ in DA5}
    out, seen = [], set()
    with open(os.path.join(REPO, "docs/features/attribution.csv"), encoding="utf-8") as f:
        for row in csv.reader(f):
            m = re.match(r"files/((?:.*/)?)gameplay/(abilities|items)_plus/([^/]+\.xml)::definitions/abilities/ability:(.+)$", row[0])
            if not m:
                continue
            feats = row[1].split()
            name, base = m.group(4), m.group(2)
            if not [x for x in AUTO if x in feats] or name in regular or name in seen:
                continue
            pattern = "modGhostMode/files/%sgameplay/%%s/%s" % (m.group(1), m.group(3))
            legacy = show("legacy-GM", pattern % (base + "_plus")).get(name)
            if legacy is None:
                continue
            if strip(legacy) == strip(show("master", pattern % (base + "_plus")).get(name, "")):
                raise SystemExit("%s: legacy did not change its NG+ entry" % name)
            if ability_stats(legacy) == ability_stats(all_abilities("vanilla-5.x", base + "_plus").get(name, "")):
                continue  # 5.x made legacy's change already (the NG+ files' tag fixes)
            seen.add(name)
            out.append(("gm_ai_weapons.xml" if base == "items" else PLUS_ONLY, base + "_plus", pattern, name, feats))
    _cache["plus"] = out
    return out


def part_units():
    """[(name, legacy path pattern)] of the PART abilities (regular folder `abilities`)."""
    if "part" in _cache:
        return _cache["part"]
    taken = {u[3] for u in auto_units()} | {n for _, _, _, names in SPEC for n in names} | {n for _, n, _ in DA5}
    out, seen = [], set()
    with open(os.path.join(REPO, "docs/features/attribution.csv"), encoding="utf-8") as f:
        for row in csv.reader(f):
            m = re.match(r"files/((?:.*/)?)gameplay/abilities/([^/]+\.xml)::definitions/abilities/ability:(.+)$", row[0])
            if not m or PART_FEATURE not in row[1].split():
                continue
            name = m.group(3)
            if name in taken or name in seen:
                continue
            pattern = "modGhostMode/files/%sgameplay/%%s/%s" % (m.group(1), m.group(2))
            if name not in show("legacy-GM", pattern % "abilities"):
                continue
            seen.add(name)
            out.append((name, pattern))
    _cache["part"] = out
    return out


def part_entry(name, legacy, old, vanilla):
    """5.x's entry whole (replace), with legacy's nodes for each PART_TAGS tag legacy changed from 1.32."""
    def nodes(e):
        inner = re.sub(r'^<ability[^>]*>|</ability>$', '', strip(e or ""))
        return [(m.group(1), m.group(0)) for m in NODE.finditer(inner)]
    ln, on, vn = nodes(legacy), nodes(old), nodes(vanilla)

    def stats(ns, t):
        return ability_stats("".join(x for g, x in ns if g == t))
    changed = {t for t in {g for g, _ in ln} | {g for g, _ in on} if part_tag(t) and stats(ln, t) != stats(on, t)}
    # AI-08's tags where legacy kept 1.32's value and 5.x changed it (SkillShield's counter_chance, AI-B audit F3):
    # legacy's too, as in the abilities AI gives whole (PA1).
    changed |= {t for t in {g for g, _ in ln} if t in LATER["AI-08"]
                and stats(ln, t) == stats(on, t) and stats(vn, t) != stats(on, t)}
    head = '<ability name="%s" on_conflict="replace">' % name
    lines, done = [head], set()
    for t, x in vn:
        if t in changed:
            if t not in done:
                lines += [y for g, y in ln if g == t]
                done.add(t)
        else:
            lines.append(x)
    for t, x in ln:
        if t in changed and t not in done:
            lines.append(x)
    return "\n".join(lines + ["</ability>"])


def part_want(name, pattern, folder="abilities"):
    vanilla = all_abilities("vanilla-5.x", folder).get(name)
    if vanilla is None:
        raise SystemExit("PART %s: 5.x has no such ability" % name)
    return part_entry(name, show("legacy-GM", pattern % folder)[name], show("master", pattern % folder).get(name), vanilla)


def owned():
    """{ability: output file} of every ability this tool writes (gen_npc_stamina.py leaves them out)."""
    o = {n: out for out, _, _, names in SPEC for n in names}
    o.update({n: out for out, _, _, n, _ in auto_units()})
    o.update({n: out for out, n, _ in DA5})
    o.update({n: PART_FILE for n, _ in part_units()})
    return o  # the NG+-only abilities (plus_units) are not here: gen_npc_stamina's regular entries are other names' business


def strip(body):
    return re.sub(r'(?s)\s*<!--.*?-->', '', body.strip())


def entry(name, legacy, vanilla):
    """The port's entry: legacy's whole, 5.x's nodes for the LATER tags; head with on_conflict if 5.x has it."""
    body = strip(legacy)
    head = '<ability name="%s"%s>' % (name, ' on_conflict="replace"' if vanilla else "")
    body = re.sub(r'^<ability\s+name="[^"]+"[^>]*>', head, body)
    if vanilla:
        tags = later_tags()
        inner = body[len(head):-len("</ability>")]
        kept = [m.group(0) for m in NODE.finditer(inner) if m.group(1) not in tags]
        dropped = [m.group(0) for m in NODE.finditer(inner) if m.group(1) in tags]
        vinner = re.sub(r'^<ability[^>]*>|</ability>$', '', strip(vanilla))
        five = [(m.group(1), m.group(0)) for m in NODE.finditer(vinner) if m.group(1) in tags]
        if dropped or five:
            lines = [head] + kept
            if five:
                feats = sorted({f for f, t in LATER.items() if f not in PORTED and any(tag in t for tag, _ in five)})
                lines.append("<!-- 5.x's until %s -->" % ", ".join(feats))
                lines += [x for _, x in five]
            body = "\n".join(lines + ["</ability>"])
    return body


def indent(body):
    out = []
    lines = [l.strip() for l in body.split("\n") if l.strip()]
    for i, l in enumerate(lines):
        out.append(("\t\t\t" if i in (0, len(lines) - 1) else "\t\t\t\t") + l)
    return "\n".join(out)


def entries(out, folder):
    """[(comment or None, name, text)] of the entries of output file `out` for `folder` (abilities, items, items_plus)."""
    plus = folder.endswith("_plus")
    base = folder.replace("_plus", "")
    res = []
    for o, pattern, feature, names in SPEC:
        if o == out and base == "abilities":
            res.append((feature, None, None))
            legacy = show("legacy-GM", pattern % "abilities")
            for n in names:
                res.append((None, n, entry(n, legacy[n], all_abilities("vanilla-5.x", "abilities").get(n))))
    autos = [u for u in auto_units() if u[0] == out and u[1] == base]
    if autos:
        res.append((AUTO_TITLE[out], None, None))
        last = None
        for _, f, pattern, n, feats in autos:
            src = pattern % folder
            if src != last:
                res.append((src.split("modGhostMode/files/")[1], None, None))
                last = src
            legacy = show("legacy-GM", src).get(n)
            if legacy is None:
                raise SystemExit("legacy-GM has no %s in %s" % (n, src))
            res.append((None, n, entry(n, legacy, all_abilities("vanilla-5.x", folder).get(n))))
    plus_only = [u for u in plus_units() if u[0] == out and u[1] == folder]
    if plus_only:
        res.append(("AI-03, AI-05 (AI-A audit F3), AI-19: legacy's NG+-only changes (NG+ equal to the regular game, PA14), "
                    "legacy's NG+ entry whole", None, None))
        last = None
        for _, f, pattern, n, feats in plus_only:
            src = pattern % folder
            if src != last:
                res.append((src.split("modGhostMode/files/")[1], None, None))
                last = src
            res.append((None, n, entry(n, show("legacy-GM", src)[n], all_abilities("vanilla-5.x", folder).get(n))))
    if out == PART_FILE and folder == "abilities":
        res.append(("AI-08: combat parameters (dodge, counter, guard, taunt chances; with STAM-08's stamina values): "
                    "5.x's entry with legacy's nodes for the tags legacy changed among them; other nodes 5.x's", None, None))
        last = None
        for n, pattern in part_units():
            src = pattern % "abilities"
            if src != last:
                res.append((src.split("modGhostMode/files/")[1], None, None))
                last = src
            res.append((None, n, part_want(n, pattern)))
    da5 = [(n, b) for o, n, b in DA5 if o == out and base == "abilities"]
    if da5 and not plus:
        res.append(("DA5: 5.x's new enemies, Ghost Mode numbers by analogy with legacy's nearest enemies, proposed "
                    "by the porter and confirmed by the owner (ai.md)", None, None))
        for n, b in da5:
            res.append((None, n, b))
    return res


def build(out, folder):
    lines = ['<?xml version="1.0" encoding="UTF-8"?>', "<!-- Generated by tools/gen_ai.py from legacy-GM; do not edit. -->",
             "<redxml>", "\t<definitions>", "\t\t<abilities>"]
    for comment, n, text in entries(out, folder):
        lines.append("\t\t\t<!-- %s -->" % comment if comment else indent(text))
    lines.append("\t\t</abilities>")
    if out == ITEMS_FILE and folder in ("items", "items_plus"):
        lines.append("\t\t<items>")
        for pattern, comment, names in ITEMS:
            lines.append("\t\t\t<!-- %s -->" % comment)
            for n in names:
                lines.append("\t\t\t" + item_want(pattern, folder, n).strip())
        lines.append("\t\t</items>")
    lines += ["\t</definitions>", "</redxml>", ""]
    return "﻿" + "\n".join(lines).replace("\r\n", "\n").replace("\n", "\r\n")


def outputs():
    """[(folder, file)] this tool writes."""
    files = sorted({o for o, _, _, _ in SPEC} | {u[0] for u in auto_units() if u[1] == "abilities"} | {o for o, _, _ in DA5}
                   | ({PART_FILE} if part_units() else set()))
    res = [("abilities", f) for f in files]
    if any(u[1] == "items" for u in auto_units()):
        res += [("items", "gm_ai_weapons.xml"), ("items_plus", "gm_ai_weapons.xml")]
    if any(u[0] == PLUS_ONLY for u in plus_units()):
        res.append(("abilities_plus", PLUS_ONLY))  # NG+ only: gen_ngplus.py copies abilities/ and leaves it alone
    return res


def dlc_abilities(worktree, folder):
    """{name: entry} of the abilities in the DLC folder; names defined twice."""
    found, dup = {}, []
    d = os.path.join(worktree, DLC, folder)
    for f in sorted(os.listdir(d)):
        if not f.endswith(".xml"):
            continue
        for n, e in abilities(re.sub(r'(?s)<!--.*?-->', '', open(os.path.join(d, f), encoding="utf-8-sig").read())).items():
            if n in found:
                dup.append("ability %s twice in %s (%s)" % (n, folder, f))
            found[n] = e
    return found, dup


def verify(worktree):
    bad = 0
    own = owned()
    da5 = {n: b for _, n, b in DA5}
    for folder in ["abilities", "abilities_plus", "items", "items_plus"]:
        gm, dup = dlc_abilities(worktree, folder)
        for d in dup:
            if re.match(r"ability (.+) twice in", d).group(1) in own:  # other areas' entries are their tools' business
                print("DUPLICATE", d)
                bad = 1
        n = pa1 = 0
        vanilla = all_abilities("vanilla-5.x", folder)
        names = []
        if folder.startswith("abilities"):
            for _, pattern, _, ns in SPEC:
                names += [(n_, pattern % folder) for n_ in ns]
            names += [(n_, None) for n_ in da5]
        names += [(u[3], u[2] % folder) for u in auto_units() if u[1] == folder.replace("_plus", "")]
        plus = [(u[3], u[2] % folder) for u in plus_units() if u[1] == folder]
        names += plus
        part = dict(part_units()) if folder == "abilities" else {}
        names += [(n_, "PART") for n_ in part]
        for d in dup:
            if re.match(r"ability (.+) twice in", d).group(1) in {p[0] for p in plus}:
                print("DUPLICATE", d)
                bad = 1
        for name, src in names:
            final = gm.get(name, vanilla.get(name))
            if src is None:
                want = da5[name]
            elif src == "PART":
                want = part_want(name, part[name])
            else:
                legacy = show("legacy-GM", src).get(name)
                if legacy is None:
                    print("MISSING legacy %s: %s" % (src, name))
                    bad = 1
                    continue
                want = entry(name, legacy, vanilla.get(name))
                # PA1: nodes 5.x changed from 1.32 that the port sets to legacy's
                old = show("master", src).get(name)
                if old and vanilla.get(name):
                    o, v, w = set(ability_stats(old)), set(ability_stats(vanilla[name])), set(ability_stats(want))
                    for tag in sorted({x[0] for x in o ^ v}):
                        if {x for x in v if x[0] == tag} != {x for x in w if x[0] == tag}:
                            pa1 += 1
                            if os.environ.get("GEN_AI_PA1"):
                                print("PA1 %s: %s.%s 1.32 %s | 5.x %s | port %s" % (folder, name, tag,
                                      [x[1] for x in o if x[0] == tag], [x[1] for x in v if x[0] == tag], [x[1] for x in w if x[0] == tag]))
            a, b = ability_stats(final or ""), ability_stats(want)
            if final is None or a != b:
                print("DIFF %s: ability %s\n  port only:   %s\n  expected only: %s" % (
                    folder, name, [x for x in a if x not in b], [x for x in b if x not in a]))
                bad = 1
            else:
                n += 1
        print("%s: %d abilities as meant (%d nodes where legacy's value replaces a 5.x change, PA1)" % (folder, n, pa1))
    for folder in ("items", "items_plus"):
        found = {}
        d = os.path.join(worktree, DLC, folder)
        for f in sorted(os.listdir(d)):
            if f.endswith(".xml"):
                for n, e in item_texts(open(os.path.join(d, f), encoding="utf-8-sig").read()).items():
                    found.setdefault(n, []).append(e)
        n = 0
        for pattern, _, names in ITEMS:
            for name in names:
                got = found.get(name, [])
                if len(got) != 1 or item_norm(got[0]) != item_norm(item_want(pattern, folder, name)):
                    print("DIFF %s: item %s (%d DLC entries)" % (folder, name, len(got)))
                    bad = 1
                else:
                    n += 1
        print("%s: %d items as meant" % (folder, n))
    print("verify:", "differences found" if bad else "no difference")
    return bad


TESTS = "modGhostMode/scripts/local/gm/tests/gmTestsAiData.ws"
NUM = re.compile(r'<(\w+)\b([^>]*?)/>')


def sums(body):
    """{tag: [base, mult, add]} of an ability's numeric nodes (min values; a node without a type is base)."""
    out = {}
    inner = re.sub(r'^<ability\b[^>]*>|</ability>$', '', strip(body or ""))
    for m in NUM.finditer(inner):
        a = dict(re.findall(r'(\w+)\s*=\s*"([^"]*)"', m.group(2)))
        if "is_ability" in a:
            continue
        try:
            v = float(a.get("min", ""))
        except ValueError:
            continue
        s = out.setdefault(m.group(1), [0.0, 0.0, 0.0])
        s[{"base": 0, "mult": 1, "add": 2}.get(a.get("type", "base"), 0)] += v
    return out


def checks():
    """[(ability, attribute, (base, mult, add), kind)] the in-game data test reads: per ability one attribute
    whose value the port changes from 5.x's ("port"; the first numeric node where there is no 5.x entry), and
    one LATER attribute where legacy's value differs from 5.x's, which must still read 5.x's ("later")."""
    res = []
    da5 = {n: b for _, n, b in DA5}
    names = [(n, pattern % "abilities", "abilities") for _, pattern, _, ns in SPEC for n in ns]
    names += [(u[3], u[2] % u[1], u[1]) for u in auto_units()] + [(n, None, "abilities") for n in da5]
    part = dict(part_units())
    names += [(n, "PART", "abilities") for n in part]
    later = later_tags()
    for name, src, folder in names:
        vanilla = all_abilities("vanilla-5.x", folder).get(name)
        if src == "PART":
            legacy, want = vanilla, part_want(name, part[name])  # no "later" check: every other node is 5.x's
        else:
            legacy = da5[name] if src is None else show("legacy-GM", src)[name]
            want = da5[name] if src is None else entry(name, legacy, vanilla)
        w, v, l = sums(want), sums(vanilla), sums(legacy)
        pick = None
        for tag in list(w) + [t for t in v if t not in w]:
            if tag in later:
                continue
            if vanilla is None or w.get(tag, [0, 0, 0]) != v.get(tag, [0, 0, 0]):
                pick = tag
                break
        if pick:
            res.append((name, pick, tuple(w.get(pick, [0, 0, 0])), "port"))
        for tag in v:
            if tag in later and l.get(tag, [0, 0, 0]) != v[tag]:
                res.append((name, tag, tuple(v[tag]), "later"))
                break
    return res


def fnum(x):
    s = ("%.6f" % x).rstrip("0").rstrip(".")
    return "0" if s in ("-0", "") else s


def build_tests():
    cs = checks()
    head = ["// Generated by tools/gen_ai.py; do not edit. AI-A's data as the game reads it (docs/features/ai.md):",
            "// per ability AI gives, one attribute the port changes from 5.x's (\"port\"), and for abilities whose",
            "// combat rolls, morale, hit severity, experience or weight legacy changed, one such attribute that must",
            "// still read 5.x's until its feature is ported (\"later\": AI-12, XP, WGT; AI-08's since slice B1 are \"port\").",
            "// Base, mult and add are the sums GetAbilityAttributeValue returns (min values).", ""]
    body, fn = [], 0
    for i in range(0, len(cs), 60):
        fn += 1
        body.append("function GMTestAiData%d(out port : int, out later : int) : int" % fn)
        body.append("{")
        body.append("\tvar f : int;")
        body.append("")
        for name, attr, (b, m, a), kind in cs[i:i + 60]:
            body.append("\tf += GMTestAiNode('%s', '%s', %s, %s, %s, %s, port, later);" % (
                name, attr, fnum(b), fnum(m), fnum(a), "true" if kind == "later" else "false"))
        body.append("\treturn f;")
        body.append("}")
        body.append("")
    body.append("// Every check above; returns the failures (each logged as FAIL).")
    body.append("function GMTestAiDataAll(out checksPort : int, out checksLater : int) : int")
    body.append("{")
    body.append("\tvar f : int;")
    body.append("")
    for k in range(1, fn + 1):
        body.append("\tf += GMTestAiData%d(checksPort, checksLater);" % k)
    body.append("\treturn f;")
    body.append("}")
    body.append("")
    body.append("function GMTestAiDataAbilities() : int")
    body.append("{")
    body.append("\treturn %d;" % len({c[0] for c in cs}))
    body.append("}")
    return "\n".join(head + body) + "\n"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--worktree", default=os.path.join(os.path.dirname(REPO), "TGM-5x-GM"))
    ap.add_argument("--check", action="store_true")
    ap.add_argument("--verify", action="store_true")
    a = ap.parse_args()
    if a.verify:
        sys.exit(verify(a.worktree))
    bad = 0
    files = [(os.path.join(a.worktree, DLC, folder, out), lambda o=out, f=folder: build(o, f)) for folder, out in outputs()]
    files.append((os.path.join(a.worktree, TESTS), build_tests))
    for path, make in files:
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
