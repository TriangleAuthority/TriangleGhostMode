"""Generate SWD's sword item overrides for Ghost Mode's DLC (docs/features/swd.md).

Legacy Ghost Mode rewrote the swords' item entries and their `_Stats` abilities: damage by item level
(SWD-01), fixed bonuses on crafted, relic, unique and school swords (SWD-02 to SWD-04), Aerondight's and
Iris's items (SWD-05, SWD-06), the NG+ swords' damage bonuses (SWD-07) and display fixes (SWD-08).
This port carries SWD's share of those changes onto 5.x's entries. The units are the item and ability
units `docs/features/attribution.csv` gives an SWD feature (SWD-10, 5.x's new swords, which legacy
never had, come from the owner's values instead: the `SWD10` table below), each
merged from its own file: 5.x's entry (`vanilla-5.x`) taken whole, legacy's change applied as a
three-way merge against 1.32 (`vanilla-1.32`): what legacy changed comes, what 5.x itself changed and
legacy did not stays. Written with on_conflict="replace" (given whole, as the expansions' entries
need; docs/development.md).

What is SWD's (other areas' changes to the same entries are left as 5.x has them):

- in an ability: every stat legacy changed except `weight` (WGT) and `item_level_min/max` (ITEM); a
  fixed damage legacy removed (for damage by item level through the `Autogen` tags, ITEM's) stays
  until ITEM;
- in an item: every attribute of the opening tag legacy changed except the price (ECON) and the
  weight; the look (`variants`), the ability list (`base_abilities`) and the draw, holster and attack
  animations (`anim_actions`, `anim_switches`; SWD-08); the tags, except `Autogen*` (ITEM) and the
  `mod_*` price tags (ECON); `DoNotEnhance` where legacy added it (crafted swords get no random
  bonus, SWD-02; the owner's decision on the SWD audit's F4, 2026-10-19); where legacy removed it,
  ITEM-08 removes it (`item_layer.py`). The set tags of set swords are ARM's: the
  sword entries come from `gen_arm_items.py`'s output with ARM's tags merged in (that tool leaves the
  swords out of `gm_arm_items.xml`), so one entry per sword carries both areas' changes. Not the
  dismantling parts (CRAFT) or NPC scabbards (`bound_items`, AI).
- ITEM's fields of the same entries (level tags, level ranges, ...) as `item_layer.py` gives them
  for ITEM's ported slices; ITEM's entries no area tool writes come from `gen_item.py`.
- where 5.x changed the same field as legacy (the three crafted silver swords' animation switch,
  DS3), 5.x's stays.

The port goes in slices (swd.md's port order): PORTED lists the features ported so far; a unit is
ported with its main feature (SWD-06 > 05 > 04 > 03 > 02 > 01 > 08), and the SWD-07 stats
(`sword_dmg_bonus`, `spell_dmg_bonus`) only when SWD-07 is.

    python tools/gen_swd_items.py --worktree DIR [--check | --verify]

Writes `items/gm_swd_items.xml` and `items_plus/gm_swd_items.xml` in Ghost Mode's DLC
(--worktree). --check writes nothing and fails if a file is out of date. --verify reads
what the game reads (Ghost Mode's DLC items over 5.x's) and compares every SWD stat, field and child
block of every SWD unit with legacy's (the dismantling parts and NPC scabbards excepted: CRAFT, AI),
and SWD's strings in the nine tables with legacy's rows, counting the differences that are rules of
the port (or slices not ported yet) and failing on any other.
"""
import argparse, csv, os, re, sys
import xml.etree.ElementTree as ET

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import gen_arm_items as arm  # noqa: E402
import item_layer  # noqa: E402  ITEM's fields of the same entries
import paths  # noqa: E402  (tools/: the shared --worktree argument)

REPO = arm.REPO
DLC = arm.DLC
OUT = "gm_swd_items.xml"
PORTED = {"SWD-01", "SWD-02", "SWD-03", "SWD-04", "SWD-05", "SWD-06", "SWD-07", "SWD-08", "SWD-10"}
ORDER = ("SWD-06", "SWD-05", "SWD-04", "SWD-03", "SWD-02", "SWD-01", "SWD-08")
NOT_SWD = {"weight", "item_level_min", "item_level_max"}
SWD07 = {"sword_dmg_bonus", "spell_dmg_bonus"}
DAMAGE = re.compile(r'^(?:Slashing|Silver|Piercing|Bludgeoning)Damage$')
NOT_SWD_ATTRS = {"name", "price", "weight"}
NOT_SWD_TAG = re.compile(r'^(?:DoNotEnhance|Autogen\w*|mod_\w+)$')
BLOCKS = ("variants", "base_abilities", "anim_actions", "anim_switches")
# Child blocks of an item that are other areas' (--verify compares every other child block but `tags`).
NOT_SWD_BLOCKS = {"recycling_parts": "dismantling parts (CRAFT)", "bound_items": "NPC scabbards (AI)"}
# Abilities legacy deleted that 5.x's scripts still add (NG+: NewGamePlusAdjustDLCItem gives the NG+
# Wolven swords -40 damage): given empty, which is what the deleted ability did in legacy.
EMPTIED = {"NGP Wolf Steel Sword Mod", "NGP Wolf Silver Sword Mod"}


# SWD-10: 5.x's new swords, which legacy never had, under Ghost Mode's sword rules with the owner's
# values (swd.md SWD-10, decided 2026-10-19). Each `_Stats` ability is rebuilt from 5.x's: its weight,
# quality and secondary damage node (1) kept, the main damage set by the level (steel 25 + 8 x level,
# silver 90 + 10 x level; the level-scaled Top Notch swords keep none: their damage comes from the
# per-level abilities), every other stat replaced by the decided ones (5.x's XP on kill, bleeding, crit
# and sign bonuses go unless decided). The items get the decided slots; the Netflix swords' items also
# ARM-15's set tags (gen_arm_new.minor_tags), so each sword has one entry.
# NG+ (`items_plus`; its NGP entries hold 5.x's regular values, the regular names 5.x's NG+ values): the
# level moves by the difference between the levels of 5.x's NG+ and NG damage (the NG+ rule for a level);
# another stat takes the ratio of the 5.x stat it replaces (SWD10_SOURCE) where 5.x has it in both, else
# Ghost Mode's value.
NEW_FILES = ("dlc18_netflix_swords", "def_item_swords_dol_blathanna", "def_item_swords_vixen", "def_item_weapons")


def effect(name, chance):
    return [("buff_apply_chance", "add", chance), (f"desc_{name.lower()}chance_mult", "add", chance), (f"{name}Effect", None, None)]


# ability: (kind, level or None for level-scaled, [(tag, type, value or (min, max)), ...], slots)
SWD10 = {}
for _t, _sfx in enumerate(("", " 1", " 2")):
    for _kind in ("steel", "silver"):
        SWD10[f"Netflix {_kind} sword{_sfx} _Stats"] = (_kind, (21, 35, 41)[_t], [
            ("attack_power", "mult", (.15, .25, .30)[_t]), ("spell_power_yrden", "mult", (.10, .20, .25)[_t]),
            ("focus_gain", "add", (.05, .07, .10)[_t])], (2, 3, 3)[_t])
SWD10["Dol Blathanna longsword _Stats"] = ("steel", 8, [
    ("spell_power_aard", "mult", .10), ("armor_reduction", "base", 20), ("critical_hit_damage_bonus", "add", .20),
    ("dismember_chance", "add", .10)], 2)
# The White Widow's fire damage and burning chance raised from 15 and 5% (the owner's decision on the
# SWD audit's F10, 2026-10-19).
SWD10["White Widow of Dol Blathanna _Stats"] = ("silver", 8, [
    ("spell_power_igni", "mult", .10), ("FireDamage", "add", 25)] + effect("Burning", .08) + [
    ("dismember_chance", "add", .10)], 2)
_VIXEN = [("critical_hit_chance", "add", .15), ("critical_hit_damage_bonus", "add", .25)] + effect("Bleeding", .10) + [
    ("dismember_chance", "add", .10)]
SWD10["Steel Vixen _Stats"] = ("steel", 12, list(_VIXEN), 2)
SWD10["Silver Vixen _Stats"] = ("silver", 12, _VIXEN + [("focus_gain", "add", .05)], 2)
SWD10["Top Notch Steel Sword _Stats"] = ("steel", None, [
    ("critical_hit_chance", "add", (.10, .20)), ("critical_hit_damage_bonus", "add", (.20, .40)),
    ("dismember_chance", "add", .10)], 3)
SWD10["Top Notch Silver sword _Stats"] = ("silver", None, [
    ("spell_power", "mult", (.08, .15)), ("critical_hit_damage_bonus", "add", (.15, .30)),
    ("dismember_chance", "add", .10)], 3)
SWD10_SOURCE = {"spell_power_yrden": "spell_power", "dismember_chance": "dismember_chance_mult"}
SWD10_KEEP = {"weight", "quality"}
MAIN = {"steel": "SlashingDamage", "silver": "SilverDamage"}


def sword_level(kind, damage):
    """Legacy's level of a sword's main damage (SWD-01)."""
    return -(-(damage - 25) // 8) if kind == "steel" else -(-(damage - 90) // 10)


def level_damage(kind, level):
    return 25 + 8 * level if kind == "steel" else 90 + 10 * level


def node_min(nodes, tag):
    for k, (_, _, text) in nodes.items():
        if k[0] == tag:
            m = re.search(r'\bmin\s*=\s*"([^"]*)"', text)
            return float(m.group(1)) if m else None
    return None


def fmt(v):
    return str(int(v)) if v == int(v) else ("%.4f" % v).rstrip("0").rstrip(".")


def swd10_base(name):
    return name[4:] if name.startswith("NGP ") else name


def swd10_ability(folder, name, ventry_nodes, ng_nodes):
    """The ability's value nodes as Ghost Mode has them: [(tag, type, min, max)] (type None: is_ability)."""
    kind, level, stats, _ = SWD10[swd10_base(name)]
    out = []
    for k, (_, _, text) in sorted(ventry_nodes.items(), key=lambda x: x[1][0]):
        if k[0] in SWD10_KEEP or (k[0] in MAIN.values() and k[0] != MAIN[kind]):
            vals = dict(re.findall(r'\b(min|max)="([^"]*)"', text))
            mn, mx = float(vals["min"]), float(vals.get("max", vals["min"]))
            if k[0] == "weight" and item_layer.dw2_weight(name) is not None:  # WGT's DW2 (slice W3)
                mn = mx = float(item_layer.dw2_weight(name))
            out.append((k[0], k[1], mn, mx))
    if level is not None:
        if folder == "items_plus":
            level += sword_level(kind, node_min(ventry_nodes, MAIN[kind])) - sword_level(kind, node_min(ng_nodes, MAIN[kind]))
        d = level_damage(kind, level)
        out.insert(len([o for o in out if o[0] in SWD10_KEEP]), (MAIN[kind], "base", d, d))
    for tag, typ, v in stats:
        if typ is None:
            out.append((tag, None, None, None))
            continue
        lo, hi = v if isinstance(v, tuple) else (v, v)
        if folder == "items_plus":
            src = SWD10_SOURCE.get(tag, tag)
            vn, vc = node_min(ng_nodes, src), node_min(ventry_nodes, src)
            if vn and vc:
                prec = 0 if lo >= 1 else 2
                lo, hi = round(lo * vc / vn, prec), round(hi * vc / vn, prec)
        out.append((tag, typ, lo, hi))
    return out


def swd10_body(name, nodes):
    lines = [f'<ability name="{name}" on_conflict="replace">']
    for tag, typ, lo, hi in nodes:
        if typ is None:
            lines.append(f'\t\t<{tag}\t\tis_ability="true" />')
        else:
            rng = f' max="{fmt(hi)}"' if hi != lo else ""
            lines.append(f'\t\t<{tag}\t\ttype="{typ}"\tmin="{fmt(lo)}"{rng} />')
    lines.append("\t</ability>")
    return "\n".join(lines)


def swd10_entries(folder):
    """{name: (path, kind, entry text, value nodes or None)} of SWD-10's abilities and items in `folder`."""
    import gen_arm_new as arm_new
    out = {}
    cache = {}
    for f in NEW_FILES:
        path = f"modGhostMode/files/gameplay/{folder}/{f}.xml"
        _, ng = file_entries("vanilla-5.x", f"modGhostMode/files/gameplay/items/{f}.xml", cache)
        its, abls = file_entries("vanilla-5.x", path, cache)
        for name, (body, nodes) in abls.items():
            if swd10_base(name) not in SWD10:
                continue
            ab = swd10_ability(folder, name, nodes, ng[swd10_base(name)][1])
            out[name] = (path, "ability", swd10_body(name, ab), ab)
        for name, entry in its.items():
            ab = re.findall(r'<a>\s*([^<]+?)\s*</a>', arm.blank_comments(entry))
            mine = [a for a in ab if swd10_base(a) in SWD10]
            if not mine:
                continue
            slots = SWD10[swd10_base(mine[0])][3]
            m = arm.head_attr(entry, "enhancement_slots")[0]
            entry = entry[:m.start(1)] + str(slots) + entry[m.end(1):]
            if arm_new.MINOR.match(name):
                entry = arm_new.minor_tags(entry)
            entry = item_layer.apply_de2(name, entry)  # ECON's DE2 price
            out[name] = (path, "item", re.sub(r'^<item\b', '<item on_conflict="replace"', entry), None)
    return out


def units():
    """{(folder, kind, name): (path, main feature, features)} of SWD's item and ability units."""
    out = {}
    with open(os.path.join(REPO, "docs", "features", "attribution.csv"), encoding="utf-8") as f:
        for row in csv.DictReader(f):
            unit, feats = row["unit"], row["features"].split()
            m = re.match(r'^(.*/gameplay/(items|items_plus)/[^/]+\.xml)::definitions/(items/item|abilities/ability):(.+)$', unit)
            swd = [x for x in ORDER if x in feats]
            if not m or not swd:
                continue
            out[(m.group(2), m.group(3).split("/")[1], m.group(4))] = ("modGhostMode/" + m.group(1), swd[0], feats)
    return out


def file_entries(ref, path, cache):
    """({item: entry}, {ability: (body, nodes)}) of one file of <ref>."""
    key = (ref, path)
    if key not in cache:
        try:
            text = arm.git("show", f"{ref}:{path}")
        except Exception:
            text = ""
        blank = arm.blank_comments(text)
        its = {}
        for start, end, head in arm.item_spans(blank):
            n = re.search(r'\bname\s*=\s*"([^"]+)"', head)
            if n:
                its[n.group(1)] = text[start:end]
        abls = {}
        for m in arm.ABILITY.finditer(blank):
            body = text[m.start(2):m.end(2)]
            abls[m.group(1)] = (body, arm.nodes(body))
        cache[key] = (its, abls)
    return cache[key]


def ported_node(tag, ported):
    return tag not in NOT_SWD and (tag not in SWD07 or "SWD-07" in ported)


def merge_ability(mn, ln, vbody, ported, notes):
    """5.x's ability body with legacy's SWD changes (vs 1.32); None when nothing changes."""
    vn = arm.nodes(vbody)
    edits, appends = [], []
    for k in sorted(set(mn) | set(ln), key=str):
        if not ported_node(k[0], ported):
            continue
        lv, mv = ln.get(k), mn.get(k)
        if lv and mv and arm.values(lv[2]) == arm.values(mv[2]) and arm.norm(lv[2]) == arm.norm(mv[2]):
            continue
        if mv and k in vn and arm.norm(vn[k][2]) != arm.norm(mv[2]):
            notes.append(f"{k[0]}: 5.x changed it, 5.x's kept")
            continue
        if lv:
            if k in vn:
                if arm.norm(vn[k][2]) != arm.norm(lv[2]):
                    edits.append((vn[k][0], vn[k][1], lv[2].strip()))
            else:
                appends.append(lv[2].strip())
        elif k in vn:
            if DAMAGE.match(k[0]) and not any(x[0] == k[0] and x not in mn for x in ln):
                # removed for damage by level (ITEM-04, item_layer.py); a node legacy gave a type (1.32's
                # typeless SilverDamage of NG+'s crafted Burning Rose sword) is a fix, carried here
                notes.append(f"{k[0]} kept (legacy removed it for damage by level: ITEM)")
                continue
            edits.append((vn[k][0], vn[k][1], ""))
    if not edits and not appends:
        return None
    body = vbody
    for start, end, new in sorted(edits, reverse=True):
        body = body[:start] + new + body[end:]
    if appends:
        body = body.rstrip() + "".join("\n\t\t" + a for a in appends) + "\n\t"
    return re.sub(r'\n[ \t]*(?=\n)', '', body)


def head_attrs(entry):
    text = arm.blank_comments(entry)
    return dict(re.findall(r'\b(\w+)\s*=\s*"([^"]*)"', text[:text.index(">")]))


def is_swd_tag(t):
    return not NOT_SWD_TAG.match(t) and not arm.SET_TAG.match(t)


def merge_item(mentry, lentry, entry, notes, folder=None, name=None, ventry=None):
    """`entry` (5.x's, or ARM's output) with legacy's SWD item changes."""
    changes = []
    ma, la, va = head_attrs(mentry), head_attrs(lentry), head_attrs(entry)
    for attr in sorted(set(ma) | set(la)):
        if attr in NOT_SWD_ATTRS or la.get(attr) == ma.get(attr):
            continue
        if va.get(attr) != ma.get(attr):
            if va.get(attr) != la.get(attr):
                notes.append(f"{attr}: 5.x changed it, 5.x's kept")
            continue
        if attr not in la or attr not in va:
            notes.append(f"{attr}: added or removed by legacy, not carried")
            continue
        m = arm.head_attr(entry, attr)[0]
        entry = entry[:m.start(1)] + la[attr] + entry[m.end(1):]
        changes.append(f"{attr} {va[attr]} -> {la[attr]}")
    for tag in BLOCKS:
        mb, lb, vb = arm.block(mentry, tag), arm.block(lentry, tag), arm.block(entry, tag)
        if not (mb and lb and vb) or lb[2] == mb[2]:
            continue
        if vb[2] != mb[2]:
            notes.append(f"{tag}: 5.x changed it, 5.x's kept")
            continue
        entry = entry[:vb[0]] + lentry[lb[0]:lb[1]] + entry[vb[1]:]
        changes.append(tag)
    mt, lt = arm.split_tags(arm.blank_comments(mentry)), arm.split_tags(arm.blank_comments(lentry))
    vt = arm.split_tags(arm.blank_comments(entry))
    ventry = ventry or entry
    new = arm.add_dne(mt, lt, arm.merge(mt, lt, vt, is_swd_tag))
    new = item_layer.merge_tags(folder, name, mt, lt, arm.split_tags(arm.blank_comments(ventry)), new, item_layer.WHOLE)  # ITEM's tags (ECON's with apply_item)
    if new != vt:
        tm = arm.TAGS.search(arm.blank_comments(entry))
        if tm:
            entry = entry[:tm.start(2)] + "\t\t\t\t\t\t\t" + ", ".join(new) + "\n\t\t" + entry[tm.end(2):]
            changes.append(f"tags {', '.join(vt)} -> {', '.join(new)}")
        else:
            notes.append("tags: 5.x's entry has none, legacy's not carried")
    return entry, changes


def arm_swords():
    """ARM's generated sword entries ({folder: {name: entry}}), which this tool writes."""
    out, regular = {}, None
    for folder in ("items", "items_plus"):
        _, _, ctx, _ = arm.generate(folder, regular)
        regular = ctx
        out[folder] = ctx["swords"]
    return out


def generate(folder, armsw, ported=PORTED):
    us = units()
    cache, report, iblocks, ablocks = {}, [], [], []
    done = set()
    for (fold, kind, name), (path, main, feats) in sorted(us.items()):
        if fold != folder:
            continue
        mi, mab = file_entries("vanilla-1.32", path, cache)
        li, lab = file_entries("legacy-GM", path, cache)
        vi, vab = file_entries("vanilla-5.x", path, cache)
        notes = []
        if kind == "ability":
            if name in EMPTIED and name in vab and name not in lab and main in ported:
                ablocks.append((path, name, f'<ability name="{name}" on_conflict="replace"></ability>'))
                report.append(f"{folder}: ability {name}: deleted by legacy, given empty")
                continue
            if name not in mab or name not in lab or name not in vab:
                report.append(f"{folder}: ability {name}: not in all three branches, skipped")
                continue
            if main not in ported:
                continue
            body = merge_ability(mab[name][1], lab[name][1], vab[name][0], ported, notes)
            if body is not None:
                body, _ = item_layer.merge_nodes(folder, name, mab[name][1], lab[name][1], body, arm.nodes, arm.norm)  # ITEM's nodes
                ablocks.append((path, name, f'<ability name="{name}" on_conflict="replace">{body}</ability>'))
                report.append(f"{folder}: ability {name}" + (f" ({'; '.join(notes)})" if notes else ""))
        else:
            if name not in mi or name not in li or name not in vi:
                report.append(f"{folder}: item {name}: not in all three branches, skipped")
                continue
            base = armsw.get(name)
            entry = re.sub(r'^<item on_conflict="replace"', '<item', base) if base else vi[name]
            changes = []
            if main in ported:
                entry, changes = merge_item(mi[name], li[name], entry, notes, folder, name, vi[name])
            if not changes and not base:
                continue
            done.add(name)
            entry = re.sub(r'^<item\b', '<item on_conflict="replace"', entry)
            entry, craft = item_layer.apply_item(folder, name, mi[name], li[name], entry)  # CRAFT's and ECON's fields
            changes = changes + craft
            iblocks.append((path, name, entry))
            report.append(f"{folder}: item {name}: {'; '.join(changes) or 'ARM set tags only'}" + (f" ({'; '.join(notes)})" if notes else ""))
    for name, entry in sorted(armsw.items()):
        if name not in done:  # set swords not among SWD's units (none expected)
            vpath = next((p for (f, k, n), (p, _, _) in us.items() if n == name), "?")
            if "all" not in cache:
                cache["all"] = (arm.items("vanilla-1.32", folder), arm.items("legacy-GM", folder))
            ma, la = cache["all"]
            if name in ma and name in la:
                entry, _ = item_layer.apply_item(folder, name, ma[name][1], la[name][1], entry)  # CRAFT's and ECON's fields
            iblocks.append((vpath, name, entry))
            report.append(f"{folder}: item {name}: ARM set tags only (not an SWD unit)")
    if "SWD-10" in ported:
        for name, (path, kind, entry, _) in sorted(swd10_entries(folder).items()):
            (ablocks if kind == "ability" else iblocks).append((path, name, entry))
            report.append(f"{folder}: {kind} {name}: SWD-10")
    lines = ['﻿<?xml version="1.0" encoding="UTF-8"?>',
             "<!-- Generated by tools/gen_swd_items.py from 5.x's entries with SWD's changes from legacy Ghost Mode"
             " (and ARM's set tags on set swords); do not edit. -->", "<redxml>", "<definitions>", "<abilities>"]
    for blocks, close, opener in ((sorted(ablocks), "</abilities>", "<items>"), (sorted(iblocks), "</items>", None)):
        last = None
        for path, name, entry in blocks:
            if path != last:
                lines.append(f"\n<!-- {path.split('modGhostMode/files/', 1)[-1]} -->")
                last = path
            lines.append("\t" + entry.strip())
        lines += ["", close]
        if opener:
            lines.append(opener)
    lines += ["</definitions>", "</redxml>", ""]
    return "\r\n".join(x.replace("\r\n", "\n").replace("\n", "\r\n") for x in lines), report


def dlc_entries(worktree, folder):
    return arm.dlc_entries(worktree, folder)


def canon(el):
    """An element as a comparable value: tag, attributes and text with whitespace ignored, children in order."""
    return (el.tag, tuple(sorted((k, v.strip()) for k, v in el.attrib.items())),
            re.sub(r'\s+', ' ', (el.text or "")).strip(), tuple(canon(c) for c in el))


def child_blocks(entry):
    """{tag: [canonical block, ...]} of an item's child blocks (every child of <item>, comments ignored)."""
    out = {}
    for c in ET.fromstring(arm.blank_comments(entry)):
        out.setdefault(c.tag, []).append(canon(c))
    return out


def verify(worktree):
    """Compares every SWD unit as the game reads it (Ghost Mode's DLC over 5.x) with legacy's."""
    us = units()
    cache, unexplained = {}, 0
    for folder in ("items", "items_plus"):
        gi, ga = dlc_entries(worktree, folder)
        explained, problems, checked = {}, [], [0, 0]

        def note(reason):
            explained[reason] = explained.get(reason, 0) + 1

        for (fold, kind, name), (path, main, feats) in sorted(us.items()):
            if fold != folder:
                continue
            mi, mab = file_entries("vanilla-1.32", path, cache)
            li, lab = file_entries("legacy-GM", path, cache)
            vi, vab = file_entries("vanilla-5.x", path, cache)
            pending = main not in PORTED
            if kind == "ability":
                if name not in lab and name in vab:
                    if name in EMPTIED and not pending:
                        if ga.get(name) == {}:
                            note("abilities legacy deleted, given empty")
                        else:
                            problems.append(f"ability {name}: legacy deleted it; not empty")
                    else:
                        note("entries legacy deleted (5.x's kept)")
                if name not in lab or name not in vab or name not in mab:
                    continue
                checked[1] += 1
                fn = ga.get(name, vab[name][1])
                ln, mn, vn = lab[name][1], mab[name][1], vab[name][1]
                for k in sorted(set(ln) | set(fn), key=str):
                    if k[0] in NOT_SWD:
                        continue
                    lv = arm.norm(ln[k][2]) if k in ln else None
                    fv = arm.norm(fn[k][2]) if k in fn else None
                    if lv == fv:
                        continue
                    mv = arm.norm(mn[k][2]) if k in mn else None
                    if pending:
                        note(f"not ported yet ({main})")
                    elif k[0] in SWD07 and "SWD-07" not in PORTED:
                        note("NG+ sword and sign damage bonus not ported yet (SWD-07)")
                    elif lv is None and DAMAGE.match(k[0]):
                        note(f"fixed damage kept where legacy moved to damage by level (until ITEM): {folder} {name}")
                    elif mv == lv and k in vn:
                        note("stats legacy left as 1.32's (5.x's kept)")
                    elif k in vn and k in mn and arm.norm(vn[k][2]) != mv:
                        note("stats 5.x changed (5.x's kept)")
                    else:
                        problems.append(f"ability {name}: {k[0]} ({k[1]}) {fv}; legacy {lv}")
            else:
                if name not in li and name in vi:
                    note("entries legacy deleted (5.x's kept)")
                if name not in li or name not in vi or name not in mi:
                    continue
                checked[0] += 1
                final = gi.get(name, vi[name])
                fa, la, ma, va = head_attrs(final), head_attrs(li[name]), head_attrs(mi[name]), head_attrs(vi[name])
                for attr in sorted(set(la) | set(fa)):
                    if attr in NOT_SWD_ATTRS or attr == "on_conflict" or fa.get(attr) == la.get(attr):
                        continue
                    if pending:
                        note(f"not ported yet ({main})")
                    elif la.get(attr) == ma.get(attr):
                        note("fields legacy left as 1.32's (5.x's kept: scabbards and other 5.x changes)")
                    elif va.get(attr) != ma.get(attr):
                        note("fields 5.x changed as well (5.x's kept, DS3)")
                    else:
                        problems.append(f"{name}: {attr} {fa.get(attr)}; legacy {la.get(attr)}")
                fc, lc, mc, vc = (child_blocks(e) for e in (final, li[name], mi[name], vi[name]))
                for tag in sorted(set(fc) | set(lc)):
                    if tag == "tags" or fc.get(tag) == lc.get(tag):
                        continue
                    if tag in NOT_SWD_BLOCKS:
                        note(f"child blocks of other areas: {NOT_SWD_BLOCKS[tag]}")
                    elif pending:
                        note(f"not ported yet ({main})")
                    elif lc.get(tag) == mc.get(tag):
                        note("fields legacy left as 1.32's (5.x's kept: scabbards and other 5.x changes)")
                    elif vc.get(tag) != mc.get(tag):
                        note("fields 5.x changed as well (5.x's kept, DS3)")
                    else:
                        problems.append(f"{name}: <{tag}> differs from legacy's")
                dne = arm.check_dne(*(arm.split_tags(arm.blank_comments(e)) for e in (mi[name], li[name], vi[name], final)))
                if dne is True:
                    problems.append(f"{name}: no DoNotEnhance; legacy has it")
                elif dne:
                    note(dne)
                want = sorted({t for t in arm.split_tags(arm.blank_comments(li[name])) if is_swd_tag(t)})
                got = sorted({t for t in arm.split_tags(arm.blank_comments(final)) if is_swd_tag(t)})
                if want != got:
                    mt = {t for t in arm.split_tags(arm.blank_comments(mi[name])) if is_swd_tag(t)}
                    if pending:
                        note(f"not ported yet ({main})")
                    elif set(got) - set(want) <= set(arm.split_tags(arm.blank_comments(vi[name]))) - mt and not set(want) - set(got):
                        note("tags 5.x added (kept)")
                    else:
                        problems.append(f"{name}: tags {', '.join(got)}; legacy {', '.join(want)}")
        print(f"verify {folder}: {checked[0]} items, {checked[1]} abilities checked against legacy (ported: {', '.join(sorted(PORTED))})")
        for reason, n in sorted(explained.items()):
            print(f"  explained ({n}): {reason}")
        for p in problems:
            print(f"  DIFF {p}")
        unexplained += len(problems)
    unexplained += verify_swd10(worktree)
    unexplained += verify_strings(worktree)
    print(f"verify: {unexplained} unexplained differences")
    return unexplained


# SWD's strings in the mod's tables (SWD-09's attribute names, SWD-07's rows, Aerondight's and Iris's
# descriptions): each must be legacy's row (the same id and key, the key given as text or as its hash,
# and legacy's text) in all nine languages.
SWD_STRINGS = (2110992014, 2110992154, 2110992155, 2110992440, 2110992161, 2110992162, 2110992291, 2110992292, 2110992299)
LANGS = ("br", "cz", "de", "en", "es", "fr", "it", "pl", "ru")


def string_rows(text):
    """{id: (key hash, text)} of a string table in the encoder's CSV format (the key as text or hash)."""
    import w3strings
    out = {}
    for line in text.lstrip("﻿").splitlines():
        parts = line.split("|", 3)
        if len(parts) == 4 and parts[0].strip().isdigit():
            h = parts[1].strip()
            key = int(h, 16) if h else (w3strings.key_hash(parts[2].strip()) if parts[2].strip() else 0)
            out[int(parts[0])] = (key, parts[3])
    return out


def verify_strings(worktree):
    """SWD's strings in the nine tables against legacy's rows, by id (legacy gives six tables' keys as hashes)."""
    problems, ids = [], {}
    for lang in LANGS:
        rel = f"modGhostMode/localization/modGhostMode/{lang}.csv"
        got = string_rows(open(os.path.join(worktree, rel), encoding="utf-8-sig").read())
        want = string_rows(arm.git("show", f"legacy-GM:{rel}"))
        ids[lang] = sorted(got)
        for sid in SWD_STRINGS:
            if sid not in want:
                problems.append(f"{lang}: string {sid} not in legacy's table")
            elif got.get(sid) != want[sid]:
                problems.append(f"{lang}: string {sid} {got.get(sid)!r}; legacy {want[sid]!r}")
    if any(ids[lang] != ids["en"] for lang in LANGS):
        problems.append("the nine string tables do not have the same ids: " + ", ".join(l for l in LANGS if ids[l] != ids["en"]))
    print(f"verify strings: {len(SWD_STRINGS)} SWD strings in {len(LANGS)} languages checked against legacy's rows; the tables' ids alike")
    for p in problems:
        print(f"  DIFF {p}")
    return len(problems)


# SWD-10's decided levels and slots, kept apart from SWD10 so --verify checks the damage against them.
SWD10_LEVELS = {"Netflix": (21, 35, 41), "Dol Blathanna longsword": 8, "White Widow": 8, "Vixen": 12}
XP = re.compile(r'exp_bonus_when_fatal$')


def parsed(nodes):
    out = []
    for k, (_, _, text) in nodes.items():
        vals = dict(re.findall(r'\b(min|max)="([^"]*)"', text))
        lo = float(vals["min"]) if "min" in vals else None
        out.append((k[0], k[1] if "is_ability" not in text else None, lo, float(vals.get("max", vals["min"])) if lo is not None else None))
    return sorted(out, key=str)


def verify_swd10(worktree):
    """SWD-10: the new swords as the game reads them (every file of Ghost Mode's DLC) against the owner's values."""
    problems, checked = [], [0, 0]
    for folder in ("items", "items_plus"):
        d = os.path.join(worktree, DLC, folder)
        defined = {}
        for f in sorted(os.listdir(d)):
            if f.endswith(".xml"):
                text = arm.blank_comments(open(os.path.join(d, f), encoding="utf-8-sig").read())
                for n in re.findall(r'<(?:item|ability)\b[^>]*?\bname\s*=\s*"([^"]+)"', text):
                    defined.setdefault(n, []).append(f)
        gi, ga = dlc_entries(worktree, folder)
        for name, (path, kind, entry, want) in sorted(swd10_entries(folder).items()):
            if len(defined.get(name, [])) != 1:
                problems.append(f"{folder}: {name} defined in {defined.get(name)}")
            if kind == "ability":
                checked[1] += 1
                got = ga.get(name)
                if got is None:
                    problems.append(f"{folder}: ability {name} missing")
                    continue
                g = parsed(got)
                if g != sorted(want, key=str):
                    problems.append(f"{folder}: ability {name}: {g}; decided {sorted(want, key=str)}")
                if any(XP.search(t[0]) for t in g):
                    problems.append(f"{folder}: ability {name} keeps an XP bonus")
                kd, lvl, stats, _ = SWD10[swd10_base(name)]
                for key, lv in SWD10_LEVELS.items():
                    if key in name and lvl is not None and (folder == "items" or name.startswith("NGP ")):
                        tier = re.search(r'(?: (\d))? _Stats$', name).group(1)
                        level = lv[int(tier or 0)] if isinstance(lv, tuple) else lv
                        dmg = [t[2] for t in g if t[0] == MAIN[kd]]
                        if dmg != [level_damage(kd, level)]:
                            problems.append(f"{folder}: ability {name}: damage {dmg}, level {level} wants {level_damage(kd, level)}")
                if lvl is None and any(t[0] == MAIN[kd] for t in g):
                    problems.append(f"{folder}: ability {name}: level-scaled but has a main damage")
            else:
                checked[0] += 1
                final = gi.get(name)
                if final is None:
                    problems.append(f"{folder}: item {name} missing")
                    continue
                ab = [a for a in re.findall(r'<a>\s*([^<]+?)\s*</a>', arm.blank_comments(final)) if swd10_base(a) in SWD10]
                slots = arm.head_attr(final, "enhancement_slots")[1]
                if not ab or slots != str(SWD10[swd10_base(ab[0])][3]):
                    problems.append(f"{folder}: item {name}: slots {slots}")
                tags = set(arm.split_tags(arm.blank_comments(final)))
                if "Netflix" in name:
                    want_tags = {"NetflixSet", "SetBonusPiece"} | ({"NetflixSetMinor"} if not name.endswith(" 2") else set())
                    if not want_tags <= tags:
                        problems.append(f"{folder}: item {name}: tags {sorted(tags)}")
                if "Top Notch" in name and "Autogen" not in tags:
                    problems.append(f"{folder}: item {name}: not level-scaled")
        print(f"verify {folder} SWD-10: {checked[0]} items, {checked[1]} abilities checked against the owner's values")
        checked = [0, 0]
    for p in problems:
        print(f"  DIFF {p}")
    return len(problems)


def main():
    ap = argparse.ArgumentParser()
    paths.add_worktree(ap)  # required: parallel areas each pass their own worktree
    ap.add_argument("--check", action="store_true")
    ap.add_argument("--verify", action="store_true", help="compare the final items with legacy's SWD data")
    args = ap.parse_args()
    if args.verify:
        sys.exit(1 if verify(args.worktree) else 0)
    armsw = arm_swords()
    stale = False
    for folder in ("items", "items_plus"):
        text, report = generate(folder, armsw[folder])
        print("\n".join(report))
        print(f"{folder}: {len(report)} entries")
        ET.fromstring(text.lstrip("﻿").encode("utf-8"))  # fails on XML the game could not read
        dst = os.path.join(args.worktree, DLC, folder, OUT)
        old = open(dst, encoding="utf-8", newline="").read() if os.path.exists(dst) else None
        if old != text:
            stale = True
            if not args.check:
                with open(dst, "w", encoding="utf-8", newline="") as f:
                    f.write(text)
    if args.check and stale:
        sys.exit("gm_swd_items.xml is out of date: run python tools/gen_swd_items.py")


if __name__ == "__main__":
    main()
