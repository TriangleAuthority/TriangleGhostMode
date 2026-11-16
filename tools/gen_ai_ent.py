"""Generate AI's entity edits (docs/features/ai.md, slice A3): legacy's levels, stat flags, NPC templates,
monster categories and weakness lists, as binary edits of 5.x's entity files (PA8); since slice C2 also AI-18's
projectile and special-attack entities (damage, armor and Quen rules, the quicksand, the toad's acid pool:
PROPS_LATER), with legacy's value also where 5.x changed it (LEGACY_OVER_5X) and struct fields (STRUCT_PROPS); since
the AI-C audit also the fake level addon where legacy made a fake level real, and files legacy left as 1.32's whose
value 5.x changed (GAME_FILES, read from the games' bundles: the 5.x install and the legacy copy).

For every binary file `docs/features/attribution.csv` gives AI-02, AI-06, AI-07, AI-14, AI-18, AI-19 or AI-20, the edits legacy made to
1.32's file (`vanilla-1.32` -> `legacy-GM`) in the properties AI-A owns (PROPS) are derived object by object and
applied to 5.x's file (`vanilla-5.x`) with `cr2w_patch.py`; the W3Edit re-save noise and every other
property stay 5.x's. Rules:

- a number, flag or category legacy changed takes legacy's value; where 5.x changed it too, the file is
  listed (CONFLICT) and nothing is written for it;
- an ability list (`CCharacterStatsParam.abilities`) or weakness list gets legacy's removals and additions
  applied to 5.x's list ("legacy's intent on 5.x's file"), so 5.x's own entries stay. Abilities of features
  not ported yet stay as 5.x has them (LATER: the fistfight abilities, AI-20's since slice C3; `ablIgnoreSigns` AI-14's;
  AI-08's human combat-skill templates and `abl*` behaviour abilities came with slice B1); files whose AI edits belong wholly to a later
  feature are left out (LATER_FILES). PA7: an entity 5.x moved to its own silver template
  (`ConDefaultSilver`) where legacy put `ConHumanoidMonster` takes legacy's instead (SILVER);
- an object legacy edited must exist in 5.x's file under the same class and ordinal, else the file is
  listed (STRUCTURAL) and nothing is written for it.

Files LOOT also edits (`gen_loot.py`'s binary units) get LOOT's edits first, then AI's: both tools write
the same bytes for them. Header-only files: a file whose only 5.x change is its header (CR2W version and
build fields) takes legacy's whole body with 5.x's header (HEADER_ONLY: the cave nekkers' spawn set, whose
new entity reference `cr2w_patch.py` cannot write as an edit).

    python tools/gen_ai_ent.py --worktree DIR [--check | --verify | --list]

--check writes nothing and fails if a file is out of date. --verify reads the written files: each must be
5.x's file (LOOT's edits applied) with exactly the derived edits, every edit matching, CRCs valid, every
object outside the edited ones 5.x's byte for byte, every edited property as derived, and every ability
the edits add defined by 5.x's XML or Ghost Mode's DLC. --list prints every file's edits and the files
left out with why.

Needs, not in this repository: the game install (5.x; found by tools/paths.py through Steam or W3_GAME_DIR)'s bundles, and the legacy 1.32 game copy (docs/tools.md) for the values 5.x changed.
"""
import argparse, csv, os, re, sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import cr2w_patch as cp  # noqa: E402
import gen_loot  # noqa: E402
import paths  # noqa: E402  (tools/: the shared --worktree argument)
from gen_loot import Blobs, bin_chunks, fmt  # noqa: E402

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FEATURES = {"AI-02", "AI-06", "AI-07", "AI-14", "AI-18", "AI-19", "AI-20"}
UNIT = re.compile(r'^(.*\.(?:w2ent|w2comm))::<file>$')

# The properties AI-A owns, by class ("*": any class). Levels (AI-06: CNewNPC, W3MonsterHuntNPC, W3Rat,
# CDettlaffColumn, CHeartMiniboss ...) and the group flag the level bonuses read; the template and flag
# abilities (AI-02, AI-06); categories and weakness lists (AI-07). levelFakeAddon: in every AI file where legacy
# changed it (71), legacy turned the fake level into a real one (the addon 0 or gone, the level raised), so the
# addon goes with the level (AI-C audit F6: the HUD adds it to the level; the fake levels themselves stay DIFF's).
# Not here: the buff immunities (AI-19's, PROPS_LATER), W3Edit's runtime noise (currentLevel, CCharacterStats,
# the ability manager).
PROPS = {
    "*": {"level", "isMonsterType_Group", "levelFakeAddon"},
    "CCharacterStatsParam": {"abilities", "overrideInherited"},
    "CMonsterParam": {"monsterCategory"},
    "CCreatureDataComponent": {"itemsUsedAgainstCreature"},
}
# AI parameters of later features, owned once the feature is in PORTED (AI-14, slice B3): the two quest fiends'
# reachability tolerance (legacy: 5.x's 4 removed, so the class default 2 m), the Hakland mage's hit counter
# (legacy: 5.x's false removed, so the default: only melee hits count); the golems', earth elementals' and Ifryts'
# all-round slam (fix3, sweep C gap 1, changelist 136): every template's own `wide_arc` attack range 3 m (5.x: 2 m
# for the Daos, 4 m for the golems and Ifryts), object by object, so an included base's copy stays 5.x's.
PROPS_LATER = {
    ("CAIMonsterCombatParams", "reachabilityTolerance"): "AI-14",
    ("CAINpcWindMageCombatParams", "increaseHitCounterOnlyOnMelee"): "AI-14",
    ("CConeAttackRange", "rangeMax"): "AI-14",
}
# Properties owned only in the files whose attribution note names them (the 22 golem, Dao and Ifryt files, "wide_arc"):
# elsewhere W3Edit's re-save drops, adds and renumbers attack-range objects with no AI change. _SCOPE: the note of the
# file plan() reads.
FILE_SCOPED = {("CConeAttackRange", "rangeMax"): "wide_arc"}
_SCOPE = [""]
# AI-18 (slice C2): the special attacks' entity values (the Blood and Wine and Hearts of Stone projectiles' damage,
# armor and Quen rules, the mages' quicksand, the toad's acid pool, the djinn's and the sorceresses' stones).
for _cls, _props in {
        "PoisonProjectile": ("projDMG",),
        "SpawnMultipleEntitiesPoisonProjectile": ("projDMG",),
        "DebuffProjectile": ("projDMG", "ignoreArmor", "destroyQuen", "dealDamageEvenIfDodging", "damageTypeName"),
        "W3DracolizardFireball": ("projDMG", "projSilverDMG"),
        "W3BoulderProjectile": ("projDMG", "ignoreArmor"),
        "W3IceSpearProjectile": ("projDMG",),
        "W3WitchBoilingWaterObstacle": ("damageValue", "debuffDuration"),
        "CToadAcidPool": ("damageVal", "poisonDamage"),
}.items():
    for _p in _props:
        PROPS_LATER[(_cls, _p)] = "AI-18"
# Features whose values take legacy's also where 5.x changed them (as PA1 for the abilities): AI-18's projectile
# damage (5.x lowered four projectiles' damage: the echinops' acid 1,000 -> 500, Dettlaff's swarm 1,000 -> 30, the
# toad's spit 890 -> 500 and tongue 900 -> 400; legacy: 350, 600, 200, 300).
LEGACY_OVER_5X = {"AI-18"}
# Struct properties edited field by field.
STRUCT_PROPS = {"poisonDamage"}
# Files legacy left as 1.32 has them where 5.x changed an owned value of a LEGACY_OVER_5X feature: the value legacy
# played is 1.32's (as AI-B's PART for abilities). The baselines on vanilla-1.32 and vanilla-5.x hold only the files legacy
# changed, so these are read from the games' bundles (the 5.x install; the legacy copy, docs/tools.md): AI-C audit F2's
# scan of every projectile entity. The Wild Hunt mage's ice spear: 1.32 500, 5.x 285 (5.x lowered it for its level
# term, which PA11 removed).
GAME_FILES = {
    "modGhostMode/files/gameplay/abilities/wh_mage/wh_icespear.w2ent": "AI-18",
}
LEGACY_GAME = os.path.join(REPO, "..", "legacy-The Witcher 3")
_GAME = {}


def game_file(which, path):
    """A file's bytes in the 5.x install ('5.x') or the legacy copy ('1.32'), the last bundle in load order."""
    import extract_vanilla
    import unbundle
    import paths
    if which not in _GAME:
        root = str(paths.game_dir()) if which == "5.x" else LEGACY_GAME
        idx = {}
        for b in extract_vanilla.bundle_load_order(root):
            for e in extract_vanilla.read_toc(b):
                idx[e.name.lower()] = e
        _GAME[which] = idx
    e = _GAME[which][path.replace("modGhostMode/files/", "").replace("/", "\\").lower()]
    with open(e.bundle, "rb") as f:
        return unbundle.read_entry(f, e)


class GameBlobs:
    """Blobs, with GAME_FILES read from the games: 1.32's (= legacy's) for vanilla-1.32 and legacy-GM, 5.x's for vanilla-5.x."""

    def __init__(self):
        self.b = Blobs()

    def get(self, ref, path):
        if path in GAME_FILES:
            return game_file("5.x" if ref == "vanilla-5.x" else "1.32", path)
        return self.b.get(ref, path)
# AI-19 (slice C3): the quest monsters' buff immunities (the Caretaker, Gregoire, mh102's arachas, the ancient
# fogling, mh210's lamia). Their lists hold EEffectType numbers, and 5.x inserted two effect types (EET_Catalyst,
# EET_ConvergenceTheory at 127), so 1.32's and legacy's numbers are translated to 5.x's by name (ENUM_ARRAYS).
PROPS_LATER[("CBuffImmunityParam", "immunityTo")] = "AI-19"


def _enum(ref, path, enum):
    import subprocess
    text = subprocess.run(["git", "-C", REPO, "show", "%s:%s" % (ref, path)], capture_output=True, check=True).stdout.decode("utf-8-sig", "replace")
    body = re.search(r"enum\s+%s\s*\{(.*?)\}" % enum, text, re.S).group(1)
    return re.findall(r"\b(EET_\w+)", re.sub(r"//[^\n]*", "", body))


_EET = []


def eet_5x(x):
    """1.32's (and legacy's) EEffectType number -> 5.x's, by name."""
    if not _EET:
        path = "modGhostMode/scripts/game/gameplay/effects/effectTypes.ws"
        old, new = _enum("vanilla-1.32", path, "EEffectType"), _enum("vanilla-5.x", path, "EEffectType")
        _EET.append({i: new.index(n) for i, n in enumerate(old) if n in new})
    return _EET[0][x]


ENUM_ARRAYS = {"immunityTo": eet_5x}

# Abilities of features not ported yet: legacy's additions and removals of these wait for their slice.
LATER = [
    (re.compile(r"^Skill(?!Fists)"), "AI-08"),  # human combat-skill templates (SkillPeasant, SkillBoss, ...)
    (re.compile(r"^abl(?!IgnoreSigns)"), "AI-08"),  # behaviour abilities (ablCounterHeavyAttacks, ...)
    (re.compile(r"^ablIgnoreSigns$"), "AI-14"),  # signs ignored (legacy: off the Goldilocks bears)
    (re.compile(r"^(StatsFists|SkillFists|sq301_fistfighters$)"), "AI-20"),  # fistfight tiers and quest fights
]
PORTED = {"AI-02", "AI-06", "AI-07", "AI-08", "AI-14", "AI-18", "AI-19", "AI-20"}  # AI-08 since slice B1: the combat-skill templates and abl*
# abilities; AI-14 since slice B3: ablIgnoreSigns off the Goldilocks bears, PROPS_LATER; AI-19, AI-20 since slice C3:
# the buff immunities (ENUM_ARRAYS), the fistfight tiers and sq301_fistfighters

# Files left out: the three smiths legacy turned from quest NPCs into commoners (AI-14). Legacy's files are
# rebuilt from commoner templates (a commoner AI preset: group type, combat, reaction and soft-reaction trees,
# new objects and imports; Commoner; no IsNotScaredOfMonsters/DisableFinishers), which cr2w_patch.py cannot
# write as edits of 5.x's files (themselves rebuilt by CDPR); they stay 5.x's (ai.md, AI-14's deviation).
LATER_FILES = {
    "modGhostMode/files/quests/secondary_npcs/fergus_graem.w2ent": "STRUCTURAL AI-14 (commoner preset)",
    "modGhostMode/files/quests/secondary_npcs/master_blacksmith.w2ent": "STRUCTURAL AI-14 (commoner preset)",
    "modGhostMode/files/quests/secondary_npcs/prologue_smith.w2ent": "STRUCTURAL AI-14 (commoner preset)",
}

# PA7: in a file where legacy gives ConHumanoidMonster, 5.x's own silver-humanoid abilities (its template
# ConDefaultSilver and the succubi's Essence abilities, 5.x's renames of legacy's quest abilities) leave every
# ability list of the file; legacy's quest ability takes the renamed one's place where legacy's file has it.
SILVER_5X = {"ConDefaultSilver", "sq205_suc", "mh303_suc"}
RENAMED_5X = {"mh303_suc": "qmh303_suc", "sq205_suc": "sq205_succubus"}
# Files 5.x rebuilt so that legacy's edited object has no counterpart (STRUCTURAL); legacy's intent is
# applied by the PA7 pass alone: the crowd succubi (5.x: one list, its sq205_suc; legacy: ConHumanoidMonster
# in place of ConDefault in its 'Stats' list).
INTENT_ONLY = {
    "modGhostMode/files/characters/npc_entities/crowd_npc/succubus/succubus.w2ent",
    "modGhostMode/files/characters/npc_entities/crowd_npc/succubus/succubus_censored.w2ent",
}

HEADER_ONLY = {
    "modGhostMode/files/quests/sidequests/skellige/quest_files/sq209_weregild/spawnsets/sq209_cave_nekkers.w2comm",
}



_UNITS = None
_NOTES = {}  # {path: its attribution note}


def units():
    """{path: features} of the binary files with a unit of one of FEATURES."""
    global _UNITS
    if _UNITS is not None:
        return _UNITS
    out = _UNITS = {}
    with open(os.path.join(REPO, "docs", "features", "attribution.csv"), encoding="utf-8") as f:
        for row in csv.DictReader(f):
            m = UNIT.match(row["unit"])
            feats = set(row["features"].split())
            if m and feats & FEATURES:
                out["modGhostMode/" + m.group(1)] = feats
                _NOTES["modGhostMode/" + m.group(1)] = row["note"]
    return out


def later(name):
    for rx, feat in LATER:
        if rx.search(name) and feat not in PORTED:
            return feat
    return None


def owned(cls, name):
    f = PROPS_LATER.get((cls, name))
    if f:
        return f in PORTED and ((cls, name) not in FILE_SCOPED or FILE_SCOPED[(cls, name)] in _SCOPE[0])
    return name in PROPS["*"] or name in PROPS.get(cls, ())


def restrict(cls, chunk):
    """[(name, (type, value))] of the AI-owned properties of a chunk (bytes, file object)."""
    d, fo = chunk
    pl, _ = cp.parse_list(d, 0, len(d), chunk=True)
    return [(fo.name(ni), gen_loot.bin_value(fo, fo.name(ti), v)) for ni, ti, v in pl[1] if owned(cls, fo.name(ni))]


def others(cls, chunk):
    """The raw (name, type, bytes) of the other properties (embedded copies left out: compared per object)."""
    d, fo = chunk
    pl, _ = cp.parse_list(d, 0, len(d), chunk=True)
    return [(fo.name(ni), fo.name(ti), b"embedded" if fo.name(ti).endswith(",Uint8") and v[4:8] == b"CR2W" else v)
            for ni, ti, v in pl[1] if not owned(cls, fo.name(ni))]


class Plan:
    """One file's derived edits: ops (cr2w_patch syntax), the edited objects with their expected AI
    properties, what was kept 5.x's (later features), and why a file was left out."""

    def __init__(self, path):
        self.path = path
        self.ops, self.targets, self.kept, self.problems, self.notes = [], {}, [], [], []
        self.added_abilities = set()


def plan(blobs, path):
    p = Plan(path)
    units()
    _SCOPE[0] = _NOTES.get(path, "")
    if path in LATER_FILES:
        p.problems.append(LATER_FILES[path])
        return p
    m, l, v = (bin_chunks(blobs.get(r, path)) for r in ("vanilla-1.32", "legacy-GM", "vanilla-5.x"))
    for key in sorted(set(m) | set(l)):
        where, cls, n = key
        mr = restrict(cls, m[key]) if key in m else None
        lr = restrict(cls, l[key]) if key in l else None
        if mr == lr or (mr is None and lr == []) or (lr is None and mr == []):
            continue  # objects W3Edit's re-save added or dropped (attack ranges, ...) carry no AI property
        if mr is None or lr is None or key not in v:
            if path in INTENT_ONLY:
                p.notes.append("structural: %s has no counterpart in 5.x's file (PA7 pass applies legacy's intent)" % (key,))
                continue
            p.problems.append("STRUCTURAL %s: object only in %s" % (key, "legacy" if mr is None else "1.32" if lr is None else "1.32 and legacy, not 5.x"))
            continue
        vr = restrict(cls, v[key])
        md, ld, vd = dict(mr), dict(lr), dict(vr)
        target = dict(vd)
        order = [n_ for n_, _ in vr]
        tgt = "%s#%d" % (cls, n)
        for name in sorted(set(md) | set(ld)):
            mv, lv = md.get(name), ld.get(name)
            if mv == lv:
                continue
            vv = vd.get(name)
            if name in STRUCT_PROPS and mv and lv and vv:
                # a struct (CToadAcidPool.poisonDamage, an SAbilityAttributeValue): legacy's changed fields
                mf, lf, vf = dict(mv[1]), dict(lv[1]), dict(vv[1])
                for fld in sorted(set(mf) | set(lf)):
                    if mf.get(fld) == lf.get(fld):
                        continue
                    if vf.get(fld) != mf.get(fld) or fld not in vf or fld not in lf:
                        p.problems.append("CONFLICT %s.%s.%s: 1.32 %s, legacy %s, 5.x %s" % (key, name, fld, mf.get(fld), lf.get(fld), vf.get(fld)))
                        continue
                    p.ops.append("%s.%s.%s=%s:%s" % (tgt, name, fld, fmt(vf[fld][1]), fmt(lf[fld][1])))
                    vf[fld] = lf[fld]
                target[name] = (vv[0], tuple((f_, vf[f_]) for f_, _ in vv[1]))
                continue
            if (mv and isinstance(mv[1], tuple)) or (lv and isinstance(lv[1], tuple)):
                # an array: legacy's removals and additions on 5.x's list
                ml = list(mv[1]) if mv else []
                ll = list(lv[1]) if lv else []
                if name in ENUM_ARRAYS:  # 1.32's numbers in 5.x's enum
                    ml, ll = [ENUM_ARRAYS[name](x) for x in ml], [ENUM_ARRAYS[name](x) for x in ll]
                if vv is None:
                    p.problems.append("STRUCTURAL %s.%s: no list in 5.x's object" % (key, name))
                    continue
                cur = list(vv[1])
                removed = [x for x in ml if x not in ll]
                added = [x for x in ll if x not in ml]
                for x in removed:
                    f = later(x) if name == "abilities" else None
                    if f:
                        p.kept.append("%s: %s.%s keeps %s (%s)" % (key, cls, name, x, f))
                    elif x in cur:
                        cur = [y for y in cur if y != x]
                        p.ops.append("%s.%s-=%s" % (tgt, name, x))
                    else:
                        p.notes.append("%s: %s.%s: %s already gone in 5.x" % (key, cls, name, x))
                for x in added:
                    f = later(x) if name == "abilities" else None
                    if f:
                        p.kept.append("%s: %s.%s does not get %s (%s)" % (key, cls, name, x, f))
                    elif x not in cur:
                        cur.append(x)
                        p.ops.append("%s.%s+=%s" % (tgt, name, x))
                        if name == "abilities":
                            p.added_abilities.add(x)
                    else:
                        p.notes.append("%s: %s.%s: %s already in 5.x" % (key, cls, name, x))
                if vv[1] != tuple(cur):
                    target[name] = (vv[0], tuple(cur))
                continue
            # a scalar
            if vv == lv:
                p.notes.append("%s: %s.%s: 5.x has legacy's %s already" % (key, cls, name, lv and fmt(lv[1])))
                continue
            if vv != mv:
                if PROPS_LATER.get((cls, name)) in LEGACY_OVER_5X and vv is not None and lv is not None:
                    p.notes.append("%s: %s.%s: legacy's %s over 5.x's %s (1.32 %s)" % (key, cls, name, fmt(lv[1]), fmt(vv[1]), mv and fmt(mv[1])))
                    p.ops.append("%s.%s=%s:%s" % (tgt, name, fmt(vv[1]), fmt(lv[1])))
                    target[name] = lv
                    continue
                p.problems.append("CONFLICT %s.%s: 1.32 %s, legacy %s, 5.x %s" % (key, name, mv and mv[1], lv and lv[1], vv and vv[1]))
                continue
            if lv is None:
                p.ops.append("%s.%s-=*" % (tgt, name))
                target.pop(name)
            elif vv is None:
                p.ops.append("%s.%s:%s+=%s" % (tgt, name, lv[0], fmt(lv[1])))
                target[name] = lv
                order.append(name)
            else:
                p.ops.append("%s.%s=%s:%s" % (tgt, name, fmt(vv[1]), fmt(lv[1])))
                target[name] = lv
        if target != vd:
            p.targets[key] = target
    if path in GAME_FILES:  # legacy kept 1.32's file: 1.32's value where 5.x changed it
        for key in sorted(set(m) & set(v)):
            cls = key[1]
            md, vd = dict(restrict(cls, m[key])), dict(restrict(cls, v[key]))
            for name in sorted(set(md) | set(vd)):
                mv, vv = md.get(name), vd.get(name)
                if mv == vv or PROPS_LATER.get((cls, name)) not in LEGACY_OVER_5X:
                    continue
                if mv is None or vv is None or isinstance(mv[1], tuple):
                    p.problems.append("STRUCTURAL %s.%s: 1.32 %s, 5.x %s" % (key, name, mv, vv))
                    continue
                p.notes.append("%s: %s.%s: 1.32's (legacy's) %s over 5.x's %s" % (key, cls, name, fmt(mv[1]), fmt(vv[1])))
                p.ops.append("%s#%d.%s=%s:%s" % (cls, key[2], name, fmt(vv[1]), fmt(mv[1])))
    silver_pass(p, m, l, v)
    seen, ops = set(), []
    for o in p.ops:  # the compiled copy (flatCompiledData) derives the same edits: once each
        if o not in seen:
            seen.add(o)
            ops.append(o)
    p.ops = ops
    p.derived = p.targets
    p.targets = simulate(p.ops, v)
    return p


OPRX = re.compile(r"^(\w+)#(\d+)\.([\w.]+?)(?::(\w+))?(=|-=|\+=)(.*)$")


def simulate(ops, chunks):
    """{key: AI properties} of every object the ops change, as the ops' rules give them (an edit addresses
    the class's Nth object in the file and in its compiled copy alike: legacy changed some levels in one copy
    only, the port changes both)."""
    out = {}
    for key, c in chunks.items():
        props = dict(restrict(key[1], c))
        new = dict(props)
        for o in ops:
            cls, n, name, typ, kind, val = OPRX.match(o).groups()
            if cls != key[1] or int(n) != key[2]:
                continue
            if "." in name:  # a struct field (STRUCT_PROPS)
                sname, fld = name.split(".", 1)
                cur = new.get(sname)
                old, nv = val.split(":", 1)
                if kind == "=" and cur is not None:
                    flds = dict(cur[1])
                    if fld in flds and fmt(flds[fld][1]) == old:
                        x = flds[fld]
                        flds[fld] = (x[0], type(x[1])(float(nv)) if isinstance(x[1], (int, float)) else nv)
                        new[sname] = (cur[0], tuple((f_, flds[f_]) for f_, _ in cur[1]))
                continue
            cur = new.get(name)
            if kind == "=":
                old, nv = val.split(":", 1)
                if cur is not None and fmt(cur[1]) == old:
                    x = cur[1]
                    new[name] = (cur[0], nv == "true" if isinstance(x, bool) else type(x)(float(nv)) if isinstance(x, (int, float)) else nv)
            elif kind == "-=":
                if cur is None:
                    continue
                if isinstance(cur[1], tuple) and re.search(r"Int\d+$", cur[0]):
                    val = int(val)
                if isinstance(cur[1], tuple):
                    new[name] = (cur[0], tuple(x for x in cur[1] if x != val))
                elif val == "*" or fmt(cur[1]) == val:
                    new.pop(name)
            elif typ:
                if cur is None:
                    new[name] = (typ, int(val) if typ.startswith(("Int", "Uint")) else val == "true" if typ == "Bool" else val)
            elif cur is not None and isinstance(cur[1], tuple):
                new[name] = (cur[0], cur[1] + ((int(val) if re.search(r"Int\d+$", cur[0]) else val),))
        if new != props:
            out[key] = new
    return out


def ability_lists(chunks):
    """{key: [abilities]} of a file's CCharacterStatsParam objects."""
    out = {}
    for key, c in chunks.items():
        if key[1] == "CCharacterStatsParam":
            r = dict(restrict(key[1], c))
            out[key] = list(r["abilities"][1]) if "abilities" in r else None
    return out


def silver_pass(p, m, l, v):
    """PA7 on a file where legacy gives ConHumanoidMonster (see SILVER_5X)."""
    ml, ll, vl = ability_lists(m), ability_lists(l), ability_lists(v)
    count = lambda lists, a: sum((x or []).count(a) for x in lists.values())
    if count(ll, "ConHumanoidMonster") <= count(ml, "ConHumanoidMonster"):
        return
    legacy_names = {a for x in ll.values() for a in (x or [])}
    cur = {}
    for key, lst in vl.items():
        if lst is None:
            continue
        t = p.targets.get(key)
        cur[key] = list(t["abilities"][1]) if t and "abilities" in t else list(lst)
    for key in sorted(cur):
        lst = cur[key]
        gone = SILVER_5X | ({"ConDefault"} if "ConDefault" not in legacy_names else set())
        for x in [a for a in lst if a in gone]:
            lst.remove(x)
            p.ops.append("%s#%d.abilities-=%s" % (key[1], key[2], x))
            p.notes.append("%s: PA7: %s removed" % (key, x))
            y = RENAMED_5X.get(x)
            if y and y in legacy_names and not any(y in o for o in cur.values()):
                lst.append(y)
                p.ops.append("%s#%d.abilities+=%s" % (key[1], key[2], y))
                p.added_abilities.add(y)
                p.notes.append("%s: legacy's %s in place of 5.x's rename %s" % (key, y, x))
            if not any("ConHumanoidMonster" in o for o in cur.values() if o is not lst) and "ConHumanoidMonster" not in lst                     and not any("ConHumanoidMonster" in o for o in cur.values()):
                lst.append("ConHumanoidMonster")
                p.ops.append("%s#%d.abilities+=ConHumanoidMonster" % (key[1], key[2]))
                p.added_abilities.add("ConHumanoidMonster")
    for key, lst in cur.items():
        if tuple(lst) != tuple(vl[key]):
            t = p.targets.setdefault(key, dict(restrict(key[1], v[key])))
            t["abilities"] = (t["abilities"][0], tuple(lst))


_LOOT = None


def loot_base(blobs, path):
    """5.x's file with LOOT's edits if gen_loot.py edits it, else 5.x's."""
    global _LOOT
    if _LOOT is None:
        _LOOT = gen_loot.bin_units()
    v = blobs.get("vanilla-5.x", path)
    if path not in _LOOT:
        return v, set()
    out, ops, changes, missing, touched, conflicts = gen_loot.bin_expected(blobs, path, with_ai=False)
    return out, touched


def header_swap(blobs, path):
    """Legacy's file with 5.x's header fields (version, build) and the header CRC recomputed; None unless
    5.x's file is 1.32's but for those header bytes."""
    m, l, v = (blobs.get(r, path) for r in ("vanilla-1.32", "legacy-GM", "vanilla-5.x"))
    diff = [i for i in range(max(len(m), len(v))) if i >= len(m) or i >= len(v) or m[i] != v[i]]
    if len(m) != len(v) or any(not (4 <= i < 24 or 32 <= i < 36) for i in diff):
        return None
    head = bytearray(l[:160])
    head[4:24] = v[4:24]
    out, _, _ = cp.apply(bytes(head) + l[160:], [])  # rebuilt: every CRC recomputed (legacy's are stale)
    return out


def expected(blobs, path):
    """(bytes or None, plan)."""
    if path in HEADER_ONLY:
        p = Plan(path)
        out = header_swap(blobs, path)
        if out is None:
            p.problems.append("STRUCTURAL: 5.x changed more than the header")
        else:
            p.notes.append("legacy's file with 5.x's header")
        return out, p
    p = plan(blobs, path)
    base, _ = loot_base(blobs, path)
    if not p.ops or any(x.startswith(("STRUCTURAL", "CONFLICT")) for x in p.problems):
        return None, p
    out, changes, hit = cp.apply(base, [cp.Op(o) for o in p.ops])
    p.missing = [o for k, o in enumerate(p.ops) if k not in hit]
    if p.missing:
        p.problems.append("edits matching nothing: %s" % p.missing)
        return None, p
    return out, p


def defined_abilities(worktree):
    """Every ability name 5.x's XML (base game and DLCs, both folders) or Ghost Mode's DLC defines."""
    import gen_ai
    names = set(gen_ai.all_abilities("vanilla-5.x", "abilities")) | set(gen_ai.all_abilities("vanilla-5.x", "items"))
    for folder in ("abilities", "items"):
        names |= set(gen_ai.dlc_abilities(worktree, folder)[0])
    return names


# The in-game check (tests/gmTestsAiEntData.ws, read by GMTest_ai06 in the regression run): a sample of edited
# entities, spawned and read against the edited files: the entity's level, its category, the abilities AI's
# edits give it and take away, its weakness list.
SAMPLE = [
    "dlc/bob/data/living_world/enemy_templates/spider_early.w2ent",  # AI-07: weakness list (insectoid oil)
    "characters/npc_entities/monsters/bies_lvl2.w2ent",  # AI-07: the fiend's weaknesses
    "dlc/ep1/data/quests/quest_files/q602_wedding/characters/q602_everc_aunt.w2ent",  # ghostly human: specter, ConHumanoidMonster
    "quests/sidequests/skellige/quest_files/sq209_weregild/characters/sq209_brans_warriors_vision.w2ent",  # vision: specter, level 17
    "quests/generic_quests/novigrad/quest_files/mh305_doppler/characters/mh305_doppler_01.w2ent",  # doppler: relic
    "characters/npc_entities/animals/rat.w2ent",  # AI-06: rats without level bonuses
    "quests/generic_quests/novigrad/quest_files/mh303_succubus/characters/mh303_succbus_v2.w2ent",  # PA7: legacy's template and quest ability
    "quests/sidequests/skellige/quest_files/sq205_alchemist/characters/sq205_succubus.w2ent",  # PA7
    "characters/npc_entities/crowd_npc/succubus/succubus.w2ent",  # PA7, structural
    "quests/minor_quests/no_mans_land/quest_files/mq1005_battlefield_scavengers/characters/mq1005_scavenger_boss.w2ent",  # ConAthletic added
    "dlc/ep1/data/characters/npc_entities/secondary_npc/hakland_mage.w2ent",  # Boss and ConDefault off, ConAthletic
    "quests/generic_quests/no_mans_land/quest_files/mh102_arachas/characters/mh102_arachas.w2ent",  # Boss off, its quest ability
    "dlc/dlc3/data/characters/mh201_cave_troll.w2ent",  # W3MonsterHuntNPC level 35 -> 28, Boss off
    "living_world/enemy_templates/skellige_bandit_axe2h.w2ent",  # a level: 14 -> 17
    "quests/sidequests/skellige/quest_files/sq209_weregild/characters/sq209_lugos_hero_03.w2ent",  # NPCDoNotGainBoost off, quest set added
    "dlc/bob/data/quests/main_quests/quest_files/q704b_fairy_tale/entities/q704_ft_goldilocks_bear_01.w2ent",  # AI-14: ablIgnoreSigns off
]
TESTS = "modGhostMode/scripts/local/gm/tests/gmTestsAiEntData.ws"


def sample_row(blobs, rel):
    """(path, level, category, has, hasNot, weak) the in-game check expects of a sample entity."""
    path = "modGhostMode/files/" + rel
    out, p = expected(blobs, path)
    final = bin_chunks(out if out is not None else blobs.get("vanilla-5.x", path))
    top = {k: dict(restrict(k[1], c)) for k, c in final.items() if k[0] == ""}
    level = next((t["level"][1] for k, t in sorted(top.items()) if "level" in t and k[2] == 0), -1)
    cats = [t["monsterCategory"][1] for k, t in top.items() if k[1] == "CMonsterParam" and "monsterCategory" in t]
    cat = cats[0] if len(cats) == 1 else -1
    lists = [a for k, t in top.items() if k[1] == "CCharacterStatsParam" and "abilities" in t for a in t["abilities"][1]]
    has, has_not = [], []
    for o in p.ops:
        m = OPRX.match(o)
        if m.group(1) == "CCharacterStatsParam":
            (has if m.group(5) == "+=" else has_not).append(m.group(6))
    has = [a for a in dict.fromkeys(has) if a in lists]
    has_not = [a for a in dict.fromkeys(has_not) if a not in lists]
    weak = next((list(t["itemsUsedAgainstCreature"][1]) for k, t in sorted(top.items()) if "itemsUsedAgainstCreature" in t), None)
    return rel, level, cat, has, has_not, weak


def build_tests(blobs):
    rows = [sample_row(blobs, r) for r in SAMPLE]
    q = lambda xs: ", ".join("'%s'" % x for x in xs)
    out = ["// Generated by tools/gen_ai_ent.py; do not edit. AI-06, AI-07 and AI-02's entity edits as the edited",
           "// files give them, for a sample of entities (docs/features/ai.md): the entity's level (-1: the file sets",
           "// none, not checked), its monster",
           "// category (-1: not checked), the abilities AI's edits add (must have) and remove (must not have once",
           "// the level bonuses ran, AI-02's template check included), its weakness list (empty: not checked).", "",
           "function GMTestAiEntSamples() : int", "{", "\treturn %d;" % len(rows), "}", "",
           "function GMTestAiEntSample(i : int, out path : string, out level : int, out category : int, out has : array<name>, out hasNot : array<name>, out weak : array<name>)",
           "{", "\thas.Clear();", "\thasNot.Clear();", "\tweak.Clear();", "\tswitch(i)", "\t{"]
    for i, (rel, level, cat, has, has_not, weak) in enumerate(rows):
        out.append("\t\tcase %d:" % i)
        out.append('\t\t\tpath = "%s";' % rel)
        out.append("\t\t\tlevel = %d;" % level)
        out.append("\t\t\tcategory = %d;" % cat)
        for a in has:
            out.append("\t\t\thas.PushBack('%s');" % a)
        for a in has_not:
            out.append("\t\t\thasNot.PushBack('%s');" % a)
        for w in weak or []:
            out.append("\t\t\tweak.PushBack('%s');" % w)
        out.append("\t\t\tbreak;")
    out += ["\t}", "}", ""]
    return "\n".join(out)


def run(worktree, mode):
    blobs = GameBlobs()
    us = dict(units())
    us.update({path: {feat} for path, feat in GAME_FILES.items()})
    written = stale = 0
    left_out, edited, bad = [], [], []
    nops = 0
    known = defined_abilities(worktree) if mode == "verify" else None
    for path in sorted(us):
        out, p = expected(blobs, path)
        dst = os.path.join(worktree, path)
        cur = open(dst, "rb").read() if os.path.exists(dst) else None
        loot, _ = loot_base(blobs, path)
        if out is None:
            want = loot  # left out: 5.x's file (with LOOT's edits)
            left_out.append((path, p))
        else:
            want = out
            edited.append((path, p))
            nops += len(p.ops)
        if mode == "verify":
            bad += verify_file(blobs, path, cur, want, p, known)
        elif cur != want:
            stale += 1
            if mode == "write":
                os.makedirs(os.path.dirname(dst), exist_ok=True)
                with open(dst, "wb") as f:
                    f.write(want)
                written += 1
        if mode == "list":
            print("## %s%s" % (path.replace("modGhostMode/files/", ""), "" if out is not None else "  (left out)"))
            for x in p.ops + ["kept 5.x's: " + k for k in p.kept] + ["note: " + n for n in p.notes] + p.problems:
                print("   ", x)
    tpath = os.path.join(worktree, TESTS)
    text = build_tests(blobs)
    told = open(tpath, encoding="utf-8", newline="").read() if os.path.exists(tpath) else None
    # compare without line endings: a worktree with core.autocrlf checks the file out with CRLF
    if told is None or told.replace("\r\n", "\n") != text.replace("\r\n", "\n"):
        if mode == "write":
            with open(tpath, "w", encoding="utf-8", newline="") as f:
                f.write(text)
            print("wrote", TESTS)
        elif mode in ("check", "verify"):
            stale += 1
            bad.append("%s out of date" % TESTS)
    print("AI entity files: %d units, %d edited (%d edits), %d left out" % (len(us), len(edited), nops, len(left_out)))
    reasons = {}
    for path, p in left_out:
        r = p.problems[0].split(":")[0] if p.problems else "no AI edit (only re-save noise or other features' properties)"
        reasons[r] = reasons.get(r, 0) + 1
    for r, n in sorted(reasons.items()):
        print("  left out: %4d  %s" % (n, r))
    kept = sum(len(p.kept) for _, p in edited + left_out)
    print("  kept 5.x's for later features: %d entries" % kept)
    if mode == "check" and stale:
        sys.exit("out of date: %d files: run python tools/gen_ai_ent.py" % stale)
    if mode == "write":
        print("written: %d" % written)
    if mode == "verify":
        for b in bad:
            print("  UNEXPLAINED " + b)
        print("verify: %d unexplained differences" % len(bad))
        sys.exit(1 if bad else 0)


def verify_file(blobs, path, cur, want, p, known):
    bad = []
    if cur != want:
        bad.append("%s: not 5.x's file with the derived edits" % path)
        return bad
    if not cp.check_crcs(cur):
        bad.append("%s: CRCs invalid" % path)
    if path in HEADER_ONLY:
        return bad
    base, loot_touched = loot_base(blobs, path)
    g, b = bin_chunks(cur), bin_chunks(base)
    if set(g) != set(b):
        bad.append("%s: objects differ from 5.x's" % path)
        return bad
    for key in sorted(g):
        cls = key[1]
        if key in p.targets:
            if dict(restrict(cls, g[key])) != p.targets[key]:
                bad.append("%s: %s does not read as derived" % (path, key))
            if others(cls, g[key]) != others(cls, b[key]):
                bad.append("%s: %s: properties outside AI's changed" % (path, key))
        elif g[key][0] != b[key][0] and gen_loot.without_embedded(*g[key]) != gen_loot.without_embedded(*b[key]):
            bad.append("%s: %s differs from 5.x's" % (path, key))
    # every changed value is legacy's (in this object or its twin copy), or PA7's
    lc = bin_chunks(blobs.get("legacy-GM", path))
    pa7 = {"ConHumanoidMonster"} | set(RENAMED_5X.values())
    for key, t in p.targets.items():
        bd = dict(restrict(key[1], b[key]))
        twins = [k for k in ((w, key[1], key[2]) for w in ("", "/flatCompiledData")) if k in lc]
        lvals = [dict(restrict(key[1], lc[k])) for k in twins]
        for name in set(t) | set(bd):
            old, new = bd.get(name), t.get(name)
            if old == new:
                continue
            if new is not None and isinstance(new[1], tuple):
                was = old[1] if old else ()
                leg = {x for lv in lvals if name in lv for x in lv[name][1]}
                if name in ENUM_ARRAYS:
                    leg = {ENUM_ARRAYS[name](x) for x in leg}
                for x in new[1]:
                    if x not in was and x not in leg and x not in pa7:
                        bad.append("%s: %s.%s gets %s, not in legacy's list" % (path, key, name, x))
                for x in was:
                    if x not in new[1] and x in leg and x not in SILVER_5X | {"ConDefault"}:
                        bad.append("%s: %s.%s loses %s, which legacy keeps" % (path, key, name, x))
            elif not any(lv.get(name) == new for lv in lvals):
                bad.append("%s: %s.%s = %s, not legacy's" % (path, key, name, new and new[1]))
    for a in sorted(p.added_abilities):
        if a not in known:
            bad.append("%s: adds ability %s, which no definition has" % (path, a))
    return bad


def main():
    ap = argparse.ArgumentParser()
    paths.add_worktree(ap)  # required: parallel areas each pass their own worktree
    g = ap.add_mutually_exclusive_group()
    g.add_argument("--check", action="store_true")
    g.add_argument("--verify", action="store_true")
    g.add_argument("--list", action="store_true")
    a = ap.parse_args()
    gen_loot.WORKTREE[0] = a.worktree
    run(a.worktree, "check" if a.check else "verify" if a.verify else "list" if a.list else "write")


if __name__ == "__main__":
    main()
