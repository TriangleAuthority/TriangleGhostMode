"""Generate ARM's item overrides for Ghost Mode's DLC (docs/features/arm.md).

Legacy Ghost Mode rewrote the armor and set item entries in the game's item files. This port
carries ARM's share of those changes onto 5.x's entries: for every item legacy changed (compared
with vanilla 1.32, `master`), it takes 5.x's entry (`vanilla-5.x`) whole, applies legacy's
change as a three-way merge (what 1.32 had and legacy removed goes, what legacy added comes, what
5.x itself changed stays), and writes it with on_conflict="replace" (an entry given whole works
for the expansions' items too; see docs/development.md, "Fine-grained XML overrides").

What is ARM's (other areas' changes to the same entries, such as prices, weights or dismantling
parts, are left as 5.x has them):

- set tags: the school set tags, the lower tiers' `*SetMinor`, `SetBonusPiece`, `ViperSet`,
  `VampireSet` (ARM-05);
- armor pieces (items of the categories armor, boots, pants, gloves; ARM-01): the class tags
  (`LightArmor`, `MediumArmor`, `HeavyArmor`), `gm_NoSetBonuses` (ARM-04), the number of
  enhancement slots, and every stat legacy changed in the abilities the pieces list (resistances,
  armor, the set gear's bonuses, `staminaRegen_armor_mod`, ...) except `weight` (WGT), `quality`
  and `item_level_min/max` (ITEM); a fixed `armor` legacy removed (for armor by item level) is kept
  until ITEM; plus the armor-by-level abilities (`autogen_*`, `Autogen ... _Stats`).
- `DoNotEnhance` on armor pieces where legacy added it, so crafted armor gets no random bonus (the
  owner's decision on the SWD audit's F4, 2026-10-19; `gen_swd_items.py` does the same for swords);
  where legacy removed it, ITEM-08 removes it (`item_layer.py`).
- ITEM's fields of the same entries (level tags, level ranges, ...), on the armor pieces, the swords
  and the abilities written here, as `item_layer.py` gives them for ITEM's ported slices; ITEM's
  entries no area tool writes come from `gen_item.py`.

- the display of armor pieces where legacy changed it and 5.x kept 1.32's (audit F4): the class
  text (`localisation_key_description`), the icon, the look (`equip_template` and its `<variants>`)
  and the ability list (the quest-equipped `Autogen` pieces), with the abilities legacy added for
  them; for Yoana's reward armor, which legacy made heavy, also legacy's name and its armor-stand
  look (`_armor_stand_variants_extension.xml`, written to `gm_arm_item_extensions.xml`; audit F4b,
  the owner's decision, 2026-10-18).

Abilities are given whole as well: 5.x's ability with legacy's changed nodes (matched by tag,
`type` and occurrence) set, added or removed; in an ability legacy rewrote, legacy's value also
where 5.x changed one legacy had left at 1.32's (DA5, audit F2 and F3).

The set swords' entries (their set tags) are not written here: `gen_swd_items.py` takes them from
`generate` and writes them with SWD's changes, one entry per sword in `gm_swd_items.xml`.

Regular items come from `gameplay/items/` folders, New Game+ items from `items_plus/`, each merged
against the same folder in the three branches (legacy's NG+ entries are legacy's own). In NG+ the
lower tiers of school gear take the regular lower tiers' set tags (`<School>SetMinor`,
`SetBonusPiece`), the NG+ rule's non-numeric change (audit F9: legacy's NG+ entries kept the school
tag); legacy's NG+-only display changes (NG+ names, glove looks) are not carried.

    python tools/gen_arm_items.py --worktree DIR [--check | --verify]

Writes `items/gm_arm_items.xml` and `items_plus/gm_arm_items.xml` (and `gm_arm_item_extensions.xml`
in both) in Ghost Mode's DLC (the worktree given by --worktree). --check writes nothing and fails if a file is out of date. --verify reads
what the game reads (Ghost Mode's DLC items over 5.x's) and compares every ARM tag (`DoNotEnhance` included), slot count,
display field and ability stat with legacy's, counting the differences that are rules of the port
and failing on any other (audit F10; about a minute).
"""
import argparse, os, re, subprocess, sys
import xml.etree.ElementTree as ET

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import item_layer  # noqa: E402  ITEM's fields of the same entries
import paths  # noqa: E402  (tools/: the shared --worktree argument)

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DLC = "modGhostMode/files/dlc/dlcghostmode/data/gameplay/"
OUT = "gm_arm_items.xml"
OUT_EXT = "gm_arm_item_extensions.xml"
STAND = "_armor_stand_variants_extension.xml"
EXTENSION = re.compile(r'<item_extension\s+name="([^"]+)"[^>]*>.*?</item_extension>', re.S)
ITEM = re.compile(r'<item\b([^>]*)>(.*?)</item>', re.S)
TAGS = re.compile(r'(<tags>)(.*?)(</tags>)', re.S)
SET_TAG = re.compile(r'^(?:Lynx|Gryphon|Bear|Wolf|RedWolf|Vampire|Viper)Set(?:Minor)?$|^SetBonusPiece$')
ARMOR_TAG = re.compile(r'^(?:Light|Medium|Heavy)Armor$|^gm_NoSetBonuses$')
SWORD_CATEGORY = re.compile(r'\bcategory\s*=\s*"(steelsword|silversword)"')
ARMOR_CATEGORY = re.compile(r'\bcategory\s*=\s*"(armor|boots|pants|gloves)"')
NOT_ARM = {"weight", "quality", "item_level_min", "item_level_max"}
DISPLAY_ATTRS = ("localisation_key_description", "icon_path", "equip_template")
# Yoana's reward armor, made heavy by legacy, also takes legacy's name (audit F4b, the owner's decision)
NAME_CARRIED = {"q108 Medium armor 10"}
AUTOGEN = re.compile(r'^autogen_(?:fixed_)?(?:armor|pants|gloves|boots)_|^Autogen (?:Armor|Gloves|Boots|Pants) _Stats$')
# The starting armor pieces are given whole by gen_arm_km.py (ARM-12), legacy's DoNotEnhance included.
KM_STARTING = {"Starting Armor", "Starting Pants", "Starting Boots", "Starting Gloves"}
# group 1 the name (in any attribute order: gen_arm_new.py writes <ability on_conflict="replace" name="...">), group 2
# the body; a self-closing <ability .../> has no body
ABILITY = re.compile(r'<ability\b(?=[^>]*?\sname\s*=\s*"([^"]+)")[^>]*?(?<!/)>(.*?)</ability>', re.S)
NODE = re.compile(r'<([A-Za-z_]\w*)\b([^>]*?)/>')


def git(*args):
    return subprocess.run(["git", *args], cwd=REPO, capture_output=True, check=True).stdout.decode("utf-8-sig", errors="replace")


def blank_comments(text):
    """The text with every comment replaced by spaces (offsets kept)."""
    return re.sub(r'<!--.*?-->', lambda m: " " * len(m.group(0)), text, flags=re.S)


def split_tags(body):
    m = TAGS.search(body)
    return [t.strip() for t in m.group(2).split(",") if t.strip()] if m else []


def items(ref, folder):
    """{name: (path, entry text, tags)} for every item in <ref>'s gameplay/<folder>/ files (not Ghost Mode's DLC)."""
    out = {}
    for path in sorted(git("ls-tree", "-r", "--name-only", ref).splitlines()):
        if not re.search(rf"/gameplay/{folder}/[^/]+\.xml$", path) or "dlcghostmode" in path:
            continue
        text = git("show", f"{ref}:{path}")
        for start, end, head in item_spans(blank_comments(text)):
            name = re.search(r'\bname\s*=\s*"([^"]+)"', head)
            if name:
                entry = text[start:end]
                out[name.group(1)] = (path, entry, split_tags(blank_comments(entry)))
    return out


def item_spans(text):
    """(start, end, opening tag) of every top-level <item> element (variants hold <item> elements too)."""
    depth, start, head = 0, 0, ""
    for m in re.finditer(r'<item\b[^>]*?(/?)>|</item>', text):
        if m.group(0).startswith("</"):
            depth -= 1
            if depth == 0:
                yield start, m.end(), head
        elif not m.group(1):
            if depth == 0:
                start, head = m.start(), m.group(0)
            depth += 1


def abilities(ref, folder):
    """{name: (path, body text, nodes)} for every ability in <ref>'s gameplay/<folder>/ files."""
    out = {}
    for path in sorted(git("ls-tree", "-r", "--name-only", ref).splitlines()):
        if not re.search(rf"/gameplay/{folder}/[^/]+\.xml$", path) or "dlcghostmode" in path:
            continue
        text = git("show", f"{ref}:{path}")
        for m in ABILITY.finditer(blank_comments(text)):
            body = text[m.start(2):m.end(2)]
            out[m.group(1)] = (path, body, nodes(body))
    return out


def nodes(body):
    """{(tag, type, occurrence): (start, end, node text)} of an ability body's value nodes."""
    seen, out = {}, {}
    for m in NODE.finditer(blank_comments(body)):
        t = re.search(r'\btype="([^"]*)"', m.group(2))
        base = (m.group(1), t.group(1) if t else "")
        seen[base] = seen.get(base, 0) + 1
        out[base + (seen[base],)] = (m.start(), m.end(), body[m.start():m.end()])
    return out


def values(node):
    return tuple(re.findall(r'\b(min|max)="([^"]*)"', node))


def merge_ability(mn, ln, vbody):
    """5.x's ability body with legacy's ARM changes (vs 1.32); None when nothing changes."""
    vn = nodes(vbody)
    edits, appends = [], []
    rewritten = any(k[0] not in NOT_ARM and (k not in mn or k not in ln or values(ln[k][2]) != values(mn[k][2]))
                    for k in set(mn) | set(ln))
    for k in sorted(set(mn) | set(ln), key=str):
        if k[0] in NOT_ARM:
            continue
        lv, mv = ln.get(k), mn.get(k)
        if lv and mv and values(lv[2]) == values(mv[2]):
            # DA5: in an ability legacy rewrote, legacy's value also where 5.x changed one legacy left at 1.32's
            if rewritten and k in vn and values(vn[k][2]) != values(lv[2]):
                edits.append((vn[k][0], vn[k][1], lv[2].strip()))
            continue
        if lv:  # changed or added by legacy
            if k in vn:
                if values(vn[k][2]) != values(lv[2]):
                    edits.append((vn[k][0], vn[k][1], lv[2].strip()))
            else:
                appends.append(lv[2].strip())
        elif k[0] != "armor" and k in vn:  # removed by legacy (a fixed armor stays until ITEM)
            edits.append((vn[k][0], vn[k][1], ""))
    if not edits and not appends:
        return None
    body = vbody
    for start, end, new in sorted(edits, reverse=True):
        body = body[:start] + new + body[end:]
    if appends:
        body = body.rstrip() + "".join("\n\t\t" + a for a in appends) + "\n\t"
    return re.sub(r'\n[ \t]*(?=\n)', '', body)


def merge(base, ours, theirs, is_arm):
    """Three-way merge of tag lists restricted to ARM's tags: base 1.32, ours legacy, theirs 5.x."""
    removed = {t for t in base if is_arm(t)} - set(ours)
    added = [t for t in ours if is_arm(t) and t not in base]
    result = [t for t in theirs if t not in removed]
    result += [t for t in added if t not in result]
    return result


def add_dne(base, ours, result):
    """`DoNotEnhance` added to a merged tag list where legacy (ours) added it to 1.32's (base); never removed."""
    if "DoNotEnhance" in ours and "DoNotEnhance" not in base and "DoNotEnhance" not in result:
        result = result + ["DoNotEnhance"]
    return result


def check_dne(mtags, ltags, vtags, ftags):
    """--verify's `DoNotEnhance` check: None when the final tags agree with legacy's, a reason (str) for
    a difference that is a rule of the port, True for a missing tag legacy added."""
    want, got = "DoNotEnhance" in ltags, "DoNotEnhance" in ftags
    if want == got:
        return None
    if want:
        return True if "DoNotEnhance" not in mtags else "DoNotEnhance 1.32 had and 5.x removed (5.x's kept)"
    if "DoNotEnhance" in mtags:
        return "DoNotEnhance legacy removed (5.x's kept: legacy's rework of the random bonuses is ITEM's)"
    return "DoNotEnhance 5.x added (kept)"


def head_attr(entry, attr):
    """(match, stripped value) of an attribute of an item's opening tag, or (None, None)."""
    text = blank_comments(entry)
    m = re.search(r'\b' + attr + r'\s*=\s*"([^"]*)"', text[:text.index(">")])
    return (m, m.group(1).strip()) if m else (None, None)


def block(entry, tag):
    """(start, end, normalised text) of an entry's <tag>...</tag> block (comments ignored), or None."""
    m = re.search(rf'<{tag}>.*?</{tag}>', blank_comments(entry), re.S)
    return (m.start(), m.end(), re.sub(r'\s+', ' ', m.group(0))) if m else None


def regular_name(name):
    return name[4:] if name.startswith("NGP ") else name


def display_attrs(name):
    return DISPLAY_ATTRS + (("localisation_key_name",) if regular_name(name) in NAME_CARRIED else ())


def stand_extensions(ref, folder):
    """{item: entry text} of <ref>'s gameplay/<folder>/_armor_stand_variants_extension.xml."""
    text = git("show", f"{ref}:modGhostMode/files/gameplay/{folder}/{STAND}")
    return {m.group(1): text[m.start():m.end()] for m in EXTENSION.finditer(blank_comments(text))}


def norm(text):
    return re.sub(r'\s+', ' ', blank_comments(text)).strip()


def changed_stands(folder, carried):
    """Audit F4b: legacy's armor-stand looks of the pieces whose look ARM carries, where 5.x kept 1.32's."""
    m, l, v = (stand_extensions(r, folder) for r in ("master", "legacy-GM", "vanilla-5.x"))
    return {n: l[n] for n in sorted(l) if n in carried and n in m and n in v
            and norm(l[n]) != norm(m[n]) and norm(v[n]) == norm(m[n])}


def carry_display(name, folder, mentry, lentry, entry, ventry, ctx, regular, changes):
    """Audit F4: legacy's class text, icon and look, and its ability list, where 5.x kept 1.32's.

    In items_plus only what legacy also changed on the regular item (legacy's NG+ files carry other
    differences, such as NG+ names, that are not ARM's)."""
    done = ctx["display"].setdefault(name, {})
    allowed = None if regular is None else regular["display"].get(regular_name(name), {})
    for attr in display_attrs(name):
        (_, mv), (_, lv), (_, vv) = head_attr(mentry, attr), head_attr(lentry, attr), head_attr(entry, attr)
        if lv is None or lv == mv or vv != mv or (allowed is not None and allowed.get(attr) != lv):
            continue
        match = head_attr(entry, attr)[0]
        entry = entry[:match.start(1)] + lv + entry[match.end(1):]
        done[attr] = lv
        changes.append(f"{attr} {vv} -> {lv}")
    for tag, needs in (("variants", "equip_template"), ("base_abilities", None)):
        mb, lb, vb = block(mentry, tag), block(lentry, tag), block(entry, tag)
        if not (mb and lb and vb) or lb[2] == mb[2] or vb[2] != mb[2] or (needs and needs not in done):
            continue
        if allowed is not None and allowed.get(tag) != lb[2]:
            continue
        entry = entry[:vb[0]] + lentry[lb[0]:lb[1]] + entry[vb[1]:]
        done[tag] = lb[2]
        changes.append(tag)
    return entry


def generate(folder, regular=None):
    """The file's text, the report, and what items_plus takes from the regular folder (`regular`)."""
    m, l, v = items("master", folder), items("legacy-GM", folder), items("vanilla-5.x", folder)
    blocks, report = [], []
    armor_abilities = set()
    ctx = {"minor": {}, "display": {}, "swords": {}}
    for name, (path, lentry, ltags) in l.items():
        if name not in m or name not in v:
            continue
        mentry, mtags, (vpath, ventry, vtags) = m[name][1], m[name][2], v[name]
        piece = bool(ARMOR_CATEGORY.search(lentry))
        if piece:
            armor_abilities.update(a.strip() for a in re.findall(r'<a>([^<]+)</a>', lentry))
        is_arm = (lambda t: SET_TAG.match(t) or ARMOR_TAG.match(t)) if piece else SET_TAG.match
        new = merge(mtags, ltags, vtags, is_arm)
        if piece:
            new = add_dne(mtags, ltags, new)
        if piece or SWORD_CATEGORY.search(ventry):
            new = item_layer.merge_tags(folder, name, mtags, ltags, vtags, new, item_layer.WHOLE)  # ITEM's tags (item_layer.py; ECON's with apply_item)
        minor = [t for t in ltags if t.endswith("SetMinor")]
        if minor:
            ctx["minor"][name] = minor[0]
        if regular is not None and regular_name(name) in regular["minor"]:
            # audit F9, the NG+ rule: NG+ lower tiers take the regular lower tiers' set tags
            tag = regular["minor"][regular_name(name)]
            new = [tag if t == tag[:-len("Minor")] else t for t in new]
            new += [t for t in (tag, "SetBonusPiece") if t not in new]
        entry, changes = ventry, []
        if new != vtags:
            tm = TAGS.search(blank_comments(entry))
            entry = entry[:tm.start(2)] + "\t\t\t\t\t\t\t" + ", ".join(new) + "\n\t\t" + entry[tm.end(2):]
            changes.append(f"tags {', '.join(vtags)} -> {', '.join(new)}")
        slots = [re.search(r'\benhancement_slots\s*=\s*"(\d+)"', e) for e in (mentry, lentry, entry)]
        if piece and all(slots) and slots[0].group(1) != slots[1].group(1) and slots[2].group(1) != slots[1].group(1):
            entry = entry[:slots[2].start(1)] + slots[1].group(1) + entry[slots[2].end(1):]
            changes.append(f"slots {slots[2].group(1)} -> {slots[1].group(1)}")
        if piece:
            entry = carry_display(name, folder, mentry, lentry, entry, ventry, ctx, regular, changes)
            if changes:
                entry, _ = item_layer.merge_attrs(folder, name, mentry, lentry, entry, item_layer.WHOLE)  # ITEM's attributes
        if not changes or name in KM_STARTING:
            continue
        entry = re.sub(r'^<item\b', '<item on_conflict="replace"', entry)
        if SWORD_CATEGORY.search(ventry):
            ctx["swords"][name] = entry  # written by gen_swd_items.py, with SWD's changes merged in
            continue
        entry, craft = item_layer.apply_item(folder, name, mentry, lentry, entry)  # CRAFT's and ECON's fields (item_layer.py)
        blocks.append((vpath, name, entry))
        report.append(f"{folder}: {name}: {'; '.join(changes + craft)}")
    ma, la, va = abilities("master", folder), abilities("legacy-GM", folder), abilities("vanilla-5.x", folder)
    ablocks = []
    for name in sorted(la):
        if name not in armor_abilities and not AUTOGEN.match(name):
            continue
        if name not in ma and name not in va and name in armor_abilities:
            # an ability legacy added for a piece (audit F4: the quest-equipped Autogen boots and trousers)
            ablocks.append((la[name][0], name, f'<ability name="{name}">{la[name][1]}</ability>'))
            report.append(f"{folder}: new ability {name}")
            continue
        if name not in ma or name not in va:
            continue
        body = merge_ability(ma[name][2], la[name][2], va[name][1])
        if body is None:
            continue
        body, _ = item_layer.merge_nodes(folder, name, ma[name][2], la[name][2], body, nodes, norm)  # ITEM's nodes
        ablocks.append((va[name][0], name, f'<ability name="{name}" on_conflict="replace">{body}</ability>'))
        report.append(f"{folder}: ability {name}")
    ablocks.sort()
    blocks.sort()
    lines = ['﻿<?xml version="1.0" encoding="UTF-8"?>', "<!-- Generated by tools/gen_arm_items.py from 5.x's entries with ARM's changes from legacy Ghost Mode; do not edit. -->", "<redxml>", "<definitions>", "<abilities>"]
    last = None
    for vpath, name, entry in ablocks:
        if vpath != last:
            lines.append(f"\n<!-- {vpath.split('modGhostMode/files/', 1)[-1]} -->")
            last = vpath
        lines.append("\t" + entry.strip())
    lines += ["", "</abilities>", "<items>"]
    last = None
    for vpath, name, entry in blocks:
        if vpath != last:
            lines.append(f"\n<!-- {vpath.split('modGhostMode/files/', 1)[-1]} -->")
            last = vpath
        lines.append("\t" + entry.strip())
    lines += ["", "</items>", "</definitions>", "</redxml>", ""]
    stands = changed_stands(folder, {n for n, d in ctx["display"].items() if "equip_template" in d})
    ext = ['﻿<?xml version="1.0" encoding="UTF-8"?>', "<!-- Generated by tools/gen_arm_items.py: legacy Ghost Mode's armor-stand looks of the armor pieces whose look ARM carries; do not edit. -->", "<redxml>", "<definitions>", "<items_extensions>"]
    for name, entry in stands.items():
        ext.append("\t" + re.sub(r'^<item_extension\s+name="([^"]+)"', r'<item_extension name="\1" on_conflict="replace"', entry.strip()))
        report.append(f"{folder}: armor-stand look {name}")
    ext += ["</items_extensions>", "</definitions>", "</redxml>", ""]
    crlf = lambda ls: "\r\n".join(x.replace("\r\n", "\n").replace("\n", "\r\n") for x in ls)
    return crlf(lines), report, ctx, crlf(ext)


def dlc_entries(worktree, folder):
    """({item: entry}, {ability: nodes}) of every XML file in Ghost Mode's DLC folder `folder`."""
    its, abls = {}, {}
    d = os.path.join(worktree, DLC, folder)
    for f in sorted(os.listdir(d)):
        if not f.endswith(".xml"):
            continue
        text = open(os.path.join(d, f), encoding="utf-8-sig").read()
        for start, end, head in item_spans(blank_comments(text)):
            name = re.search(r'\bname\s*=\s*"([^"]+)"', head)
            if name:
                its[name.group(1)] = text[start:end]
                if re.search(r'\bon_conflict\s*=\s*"extend"', head):  # ECON's short entries (gen_econ.py)
                    its[name.group(1)] = extend_over_5x(folder, name.group(1), text[start:end])
        for m in ABILITY.finditer(blank_comments(text)):
            abls[m.group(1)] = nodes(text[m.start(2):m.end(2)])
    return its, abls


_V5 = {}


def extend_over_5x(folder, name, stub):
    """An `extend` item entry as the game reads it: over 5.x's entry; a Hearts of Stone item comes out
    empty (verified, ECON slice E1); no 5.x entry: the stub itself."""
    if folder not in _V5:
        _V5[folder] = items("vanilla-5.x", folder)
    v = _V5[folder].get(name)
    if not v:
        return stub
    if "/dlc/ep1/" in v[0]:
        return item_layer.empty_item(name)
    return item_layer.resolve_extend(stub, v[1])


def verify(worktree):
    """Audit F10: compares the items the game reads (Ghost Mode's DLC over 5.x) with legacy's ARM data.

    Every ARM tag, slot count, class text, icon, look and ability list of the armor pieces and set
    items legacy has, and every ARM stat of their abilities; differences that are rules of the port are
    counted by reason, any other is listed. Returns the number of unexplained differences."""
    unexplained = 0
    regular_minor = {}
    for folder in ("items", "items_plus"):
        m, l, v = items("master", folder), items("legacy-GM", folder), items("vanilla-5.x", folder)
        ma, la, va = abilities("master", folder), abilities("legacy-GM", folder), abilities("vanilla-5.x", folder)
        gi, ga = dlc_entries(worktree, folder)
        if folder == "items":
            regular = (m, l)
        explained, problems, checked = {}, [], [0, 0]
        armor_abilities = set()

        def note(reason):
            explained[reason] = explained.get(reason, 0) + 1

        def regular_change(rname, field, value):
            """Whether legacy made the same display change on the regular item."""
            if rname not in regular[1] or rname not in regular[0]:
                return False
            rl, rm = regular[1][rname][1], regular[0][rname][1]
            if field in DISPLAY_ATTRS:
                return head_attr(rl, field)[1] == value != head_attr(rm, field)[1]
            bl, bm = block(rl, field), block(rm, field)
            return bool(bl and bm) and bl[2] == value != bm[2]

        for name, (path, lentry, ltags) in sorted(l.items()):
            if name not in m or name not in v:
                continue
            final = gi.get(name, v[name][1])
            ftags = split_tags(blank_comments(final))
            piece = bool(ARMOR_CATEGORY.search(lentry))
            is_arm = (lambda t: SET_TAG.match(t) or ARMOR_TAG.match(t)) if piece else SET_TAG.match
            if folder == "items":
                minor = [t for t in ltags if t.endswith("SetMinor")]
                if minor:
                    regular_minor[name] = minor[0]
            if piece:
                armor_abilities.update(a.strip() for a in re.findall(r'<a>([^<]+)</a>', lentry))
            checked[0] += 1
            want = sorted({t for t in ltags if is_arm(t)})
            got = sorted({t for t in ftags if is_arm(t)})
            if folder == "items_plus" and regular_name(name) in regular_minor:
                tag = regular_minor[regular_name(name)]
                rule = sorted(({tag if t == tag[:-len("Minor")] else t for t in want}) | {tag, "SetBonusPiece"})
                if rule != want:  # the NG+ rule: legacy's NG+ lower tiers kept the school tag
                    want = rule
                    if got == rule:
                        note("NG+ lower tiers tagged as the regular ones (audit F9)")
            if got != want:
                added = set(got) - set(want) - set(m[name][2])
                if set(want) - set(got) or not added <= set(v[name][2]):
                    problems.append(f"{name}: tags {', '.join(got)}; legacy {', '.join(want)}")
                else:
                    note("set tags 5.x added and legacy did not remove (5.x's NG+ SetBonusPiece, ViperSet)")
            if not piece:
                continue
            dne = check_dne(m[name][2], ltags, v[name][2], ftags)
            if dne is True:
                problems.append(f"{name}: no DoNotEnhance; legacy has it")
            elif dne:
                note(dne)
            fs, ls = (re.search(r'\benhancement_slots\s*=\s*"(\d+)"', e) for e in (final, lentry))
            if fs and ls and fs.group(1) != ls.group(1):
                ms = re.search(r'\benhancement_slots\s*=\s*"(\d+)"', m[name][1])
                if ms and ms.group(1) == ls.group(1):
                    note("slots legacy left at 1.32's and 5.x changed (not ARM's)")
                else:
                    problems.append(f"{name}: slots {fs.group(1)}; legacy {ls.group(1)}")
            for attr in display_attrs(name):
                fv, lv, mv = head_attr(final, attr)[1], head_attr(lentry, attr)[1], head_attr(m[name][1], attr)[1]
                if lv != mv and fv != lv:
                    if folder == "items_plus" and not regular_change(regular_name(name), attr, lv):
                        note("legacy's NG+-only display changes (not carried)")
                    else:
                        problems.append(f"{name}: {attr} {fv}; legacy {lv}")
            for tag in ("base_abilities", "variants"):
                fb, lb, mb = block(final, tag), block(lentry, tag), block(m[name][1], tag)
                if lb and mb and lb[2] != mb[2] and (not fb or fb[2] != lb[2]):
                    if tag == "variants" and head_attr(lentry, "equip_template")[1] == head_attr(m[name][1], "equip_template")[1]:
                        note("variants legacy changed without a new look (not ARM's)")
                    elif folder == "items_plus" and not regular_change(regular_name(name), tag, lb[2]):
                        note("legacy's NG+-only display changes (not carried)")
                    else:
                        problems.append(f"{name}: {tag} differ from legacy's")
        for name in sorted(la):
            if name not in armor_abilities and not AUTOGEN.match(name):
                continue
            final = ga.get(name, va[name][2] if name in va else None)
            if final is None:
                problems.append(f"ability {name}: missing")
                continue
            checked[1] += 1
            ln, mn = la[name][2], ma.get(name, (None, None, {}))[2]
            for k in sorted(set(ln) | set(final), key=str):
                if k[0] in NOT_ARM:
                    continue
                lv = values(ln[k][2]) if k in ln else None
                fv = values(final[k][2]) if k in final else None
                if lv == fv:
                    continue
                if k[0] == "armor" and lv is None:
                    note("fixed armor kept where legacy moved to armor by level (until ITEM)")
                elif lv is None and k not in mn:
                    note("stats 5.x added to an ability (kept)")
                elif not any(kk[0] not in NOT_ARM and (kk not in mn or kk not in ln or values(ln[kk][2]) != values(mn[kk][2])) for kk in set(mn) | set(ln)):
                    note("abilities legacy left as 1.32's (5.x's values kept)")
                else:
                    problems.append(f"ability {name}: {k[0]} ({k[1]}) {fv}; legacy {lv}")
        # audit F4b: armor-stand looks legacy changed for items 1.32 has (its new items' are CRAFT's)
        sm, sl, sv = (stand_extensions(r, folder) for r in ("master", "legacy-GM", "vanilla-5.x"))
        ext_path = os.path.join(worktree, DLC, folder, OUT_EXT)
        ext_text = open(ext_path, encoding="utf-8-sig").read() if os.path.exists(ext_path) else ""
        gs = {mm.group(1): ext_text[mm.start():mm.end()] for mm in EXTENSION.finditer(blank_comments(ext_text))}
        for name in sorted(sl):
            if name not in sm or norm(sl[name]) == norm(sm[name]):
                continue
            final = gs.get(name, sv.get(name, ""))
            strip = lambda t: re.sub(r'\s+on_conflict="[^"]*"', '', norm(t))
            if strip(final) != strip(sl[name]):
                problems.append(f"{name}: armor-stand look differs from legacy's")
        print(f"verify {folder}: {checked[0]} items, {checked[1]} abilities checked against legacy")
        for reason, n in sorted(explained.items()):
            print(f"  explained ({n}): {reason}")
        for p in problems:
            print(f"  DIFF {p}")
        unexplained += len(problems)
    print(f"verify: {unexplained} unexplained differences")
    return unexplained


def main():
    ap = argparse.ArgumentParser()
    paths.add_worktree(ap)  # required: parallel areas each pass their own worktree
    ap.add_argument("--check", action="store_true")
    ap.add_argument("--verify", action="store_true", help="compare the final items with legacy's ARM data (audit F10)")
    args = ap.parse_args()
    if args.verify:
        sys.exit(1 if verify(args.worktree) else 0)
    stale = False
    regular = None
    for folder in ("items", "items_plus"):
        text, report, ctx, ext = generate(folder, regular)
        regular = ctx
        print("\n".join(report))
        print(f"{folder}: {len(report)} items")
        for out, content in ((OUT, text), (OUT_EXT, ext)):
            ET.fromstring(content.lstrip("﻿").encode("utf-8"))  # fails on XML the game could not read
            dst = os.path.join(args.worktree, DLC, folder, out)
            old = open(dst, encoding="utf-8", newline="").read() if os.path.exists(dst) else None
            if old != content:
                stale = True
                if not args.check:
                    os.makedirs(os.path.dirname(dst), exist_ok=True)
                    with open(dst, "w", encoding="utf-8", newline="") as f:
                        f.write(content)
    if args.check and stale:
        sys.exit("gm_arm_items.xml or gm_arm_item_extensions.xml is out of date: run python tools/gen_arm_items.py")


if __name__ == "__main__":
    main()
