"""Generate ECON's item prices and price tags for Ghost Mode's DLC and verify them (docs/features/econ.md,
ECON-01 to ECON-04).

ECON owns the `price` attribute and the `mod_*` price tags of its units (`item_layer.py`: every `mod_*` tag
but XBOW-03's `mod_nosale`/`mod_nosalem` and CRAFT-08's `mod_alchemy_table`), and Blood and Wine's dyes'
`base_abilities` (their rarity). Whichever generator writes an item entry whole applies them
(`item_layer.apply_item`: `gen_arm_items.py`, `gen_swd_items.py`, `gen_arm_km.py`, `gen_ench.py`,
`gen_item.py`); this tool writes the ECON units no other file of the DLC folder defines, in the form the
owner chose (2026-11-01):

- base game, Blood and Wine and free-DLC items: a short `extend` entry, `<item name=… price=…
  on_conflict="extend">` with a `<tags>` node that adds tags and removes those written `-mod_…`;
- Hearts of Stone items (`extend` empties them, slice E1), entries that change a child block (the dyes)
  and every NG+ (`items_plus`) entry (an NG+ `extend` cannot be read in a regular game: untested, so whole):
  5.x's entry given whole with ECON's fields, `on_conflict="replace"`.

Each field is merged three-way (1.32 `vanilla-1.32`, legacy `legacy-GM`, 5.x `vanilla-5.x`, same folder): legacy's
change where 5.x kept 1.32's.

WGT (docs/features/wgt.md, slice W1, PW4): the item units of WGT-03 to WGT-06 (an item's `weight` attribute, the
coins' and the pig trophy's `EncumbranceOff` tag) that no other file defines are written here too, in the same
forms and in the same entry as the item's price (one entry per name); `gen_wgt.py --verify` checks them.

DE2 (slice E5): the prices of 5.x's new gear, schematics and horse gear (`item_layer.DE2`, by analogy with a
legacy counterpart), in the same forms, where no other tool writes the entry (`gen_arm_new.py` and
`gen_swd_items.py` apply them to theirs). ECON-11 and ECON-12 (slice E5): the four binary files (`BINARIES`),
5.x's with legacy's edits made by `cr2w_patch.py`.

    python tools/gen_econ.py --worktree DIR [--check | --verify]

Writes `items/gm_econ.xml` and `items_plus/gm_econ.xml` (the worktree given by --worktree) and the in-game data
test `tests/gmTestsEconData.ws` (every regular ECON unit's price, category, name key and price tags as the
DLC over 5.x gives them; read by `GMTest_econdata` in the regression). Run it after the other item tools
(`gen_item.py` last before it). --check writes nothing and fails if a file is out of date. --verify reads the
items the game reads (Ghost Mode's DLC over 5.x, `extend` entries resolved over 5.x's) and compares every
ECON unit's price and `mod_*` tags with legacy's, both folders; differences that are rules of the port are
counted by reason; it also fails on an entry that would come out empty (a Hearts of Stone `extend`, a price
of 0 where 5.x has one, a lost category or name key) and on a name defined twice in the DLC folder; every
DE2 item's price and price tags as DE2 gives them (both folders, other fields 5.x's), every DE2 price recomputed from its
counterpart in 1.32 and legacy, every new priced 5.x item of a gear, schematic or horse category priced; and
each of `BINARIES` equal to 5.x's file with exactly its edits, CRCs valid; and no entry of any of the DLC's
definition files (whichever tool wrote it) without `on_conflict` on a name 5.x defines, which the game would
ignore (`dlc_conflicts.py`, ECON audit F1).
"""
import argparse, collections, os, re, subprocess, sys
import xml.etree.ElementTree as ET

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import gen_arm_items as arm  # noqa: E402
import gen_item  # noqa: E402
import item_layer  # noqa: E402
import cr2w_patch  # noqa: E402
import dlc_conflicts  # noqa: E402
import paths  # noqa: E402  (tools/: the shared --worktree argument)

OUT = "gm_econ.xml"
TEST = "modGhostMode/scripts/local/gm/tests/gmTestsEconData.ws"
HOS = "/dlc/ep1/"
CHUNK = 120  # data-test checks per function (script compiler memory)
# ECON-11 and ECON-12 (PE10): legacy's edits made on 5.x's files with cr2w_patch.py, shipped in the bundle;
# --verify checks each is 5.x's file with exactly these edits (legacy's values) and valid CRCs
BINARIES = [
    # ECON-11: Vimme Vivaldi's loan (300 crowns, the reward vivaldis_loan) is repaid with 390 (1.32: 130)
    ("modGhostMode/files/quests/secondary_npcs/default_dialogues/vimme_vivaldi_default.w2scene",
     ["CPayStorySceneChoiceAction.money=130:390"]),
    # ECON-11: the Hearts of Stone tax collector's quest starts once Geralt holds 10,000 crowns (1.32: 35,000)
    ("modGhostMode/files/dlc/ep1/data/quests/quest_files/mq6003_taxes/mq6003_taxes.w2phase",
     ["CQCItemQuantity.quantity=35000:10000"]),
    # ECON-12: Contract: The Apiarian Phantom negotiates under its own reward, not the White Lady's
    ("modGhostMode/files/quests/generic_quests/novigrad/quest_files/mh307_minion/scenes/mh307_01_halflings.w2scene",
     ["CStorySceneScript.comment=mh308_final:mh307_02_minion_killed_completed",
      "CStorySceneScript.@rewardName=mh308_final:mh307_02_minion_killed_completed"]),
    ("modGhostMode/files/quests/generic_quests/novigrad/quest_files/mh307_minion/scenes/mh307_05_halflings_closing.w2scene",
     ["CStorySceneScript.comment=mh308_final:mh307_02_minion_killed_completed",
      "CStorySceneScript.@rewardName=mh308_final:mh307_02_minion_killed_completed"]),
]


# WGT's item units (wgt.md PW4): their `weight` attribute and EncumbranceOff tag, written by this tool in the
# same entry as the price (one entry per name) where no other tool writes the item
WGT = {"WGT-03", "WGT-04", "WGT-05", "WGT-06"}


def econ_units(folder, also=frozenset()):
    """{name: (unit path, ECON features)} of the ECON item units of a folder (`also`: other features whose item
    units this tool writes too, WGT's)."""
    out = {}
    for (fold, kind, name), (path, feats) in sorted(item_layer.units().items()):
        e = feats & (item_layer.ECON | also)
        if fold == folder and kind == "item" and e:
            out[name] = (path, e)
    return out


def taken(worktree, folder):
    """Item names the DLC folder's other files define (they carry ECON's fields themselves)."""
    its = set()
    d = os.path.join(worktree, arm.DLC, folder)
    for f in sorted(os.listdir(d)):
        if f.endswith(".xml") and f != OUT:
            text = arm.blank_comments(open(os.path.join(d, f), encoding="utf-8-sig").read())
            for _, _, head in arm.item_spans(text):
                n = re.search(r'\bname\s*=\s*"([^"]+)"', head)
                if n:
                    its.add(n.group(1))
    return its


def head_values(entry):
    h, _ = item_layer.head(entry)
    return {a: entry[s:e].strip() for a, (s, e) in h.items()}


def stub(name, ventry, entry):
    """The `extend` entry that turns 5.x's `ventry` into `entry` (opening-tag attributes and tags only), or
    None if anything else differs."""
    vh, eh = head_values(ventry), head_values(entry)
    attrs = [(a, eh[a]) for a in eh if a != "name" and vh.get(a) != eh[a]]
    if any(a not in eh for a in vh):
        return None
    vt, et = item_layer.split_tags(ventry), item_layer.split_tags(entry)
    rest = lambda e: " ".join(re.sub(r'<tags>.*?</tags>', '', arm.blank_comments(e)[item_layer.head(e)[1]:], flags=re.S).split())
    if rest(ventry) != rest(entry):
        return None
    tags = [t for t in et if t not in vt] + ["-" + t for t in vt if t not in et]
    a = "".join(f' {k}="{v}"' for k, v in attrs)
    body = (f"\n\t\t<tags>{', '.join(tags)}</tags>" if tags else "") + "\n\t"  # </item> on its own line, as other tools' readers expect
    return f'<item name="{name}"{a} on_conflict="extend">{body}</item>'


def replace_entry(entry):
    """5.x's entry given whole with `on_conflict="replace"` (5.x's entries may start with whitespace: ECON
    audit F1, 69 NG+ entries written without the attribute, which the game ignores)."""
    out, n = re.subn(r'^(\s*)<item\b', r'\1<item on_conflict="replace"', entry, count=1)
    assert n == 1, entry[:80]
    return out


def generate(worktree, folder):
    m, l, v = arm.items("vanilla-1.32", folder), arm.items("legacy-GM", folder), arm.items("vanilla-5.x", folder)
    other = taken(worktree, folder)
    blocks, report, counts = [], [], collections.Counter()
    for name, (path, feats) in econ_units(folder, WGT).items():
        if name in other:
            counts["written whole by another tool"] += 1
            continue
        if name not in m or name not in l or name not in v:
            report.append(f"{folder}: item {name}: not in all three branches, skipped")
            counts["not in all three branches"] += 1
            continue
        vpath, ventry, _ = v[name]
        entry, changes = item_layer.apply_item(folder, name, m[name][1], l[name][1], ventry, area=None)
        if not changes:
            counts["no change to carry (5.x's own change kept, or legacy's equal)"] += 1
            continue
        small = None if folder == "items_plus" or HOS in vpath else stub(name, ventry, entry)
        if small:
            blocks.append((vpath, name, small))
            counts["extend"] += 1
        else:
            blocks.append((vpath, name, replace_entry(entry)))
            counts["replace (NG+)" if folder == "items_plus" else "replace (Hearts of Stone)" if HOS in vpath else "replace (a child block)"] += 1
        report.append(f"{folder}: item {name}: {'extend' if small else 'replace'}: {'; '.join(changes)}")
    # DE2: 5.x's new gear, schematics and horse gear (no ECON units: legacy never had them), by analogy
    for name, (vpath, ventry, _) in sorted(v.items()):
        if name in m or item_layer.de2_name(name) is None:
            continue
        if name in other:
            counts["DE2: written whole by another tool"] += 1
            continue
        entry = item_layer.apply_de2(name, ventry)
        if entry == ventry:
            continue
        small = None if folder == "items_plus" or HOS in vpath else stub(name, ventry, entry)
        if small:
            blocks.append((vpath, name, small))
            counts["DE2 extend"] += 1
        else:
            blocks.append((vpath, name, replace_entry(entry)))
            counts["DE2 replace (NG+)" if folder == "items_plus" else "DE2 replace"] += 1
        report.append(f"{folder}: item {name}: DE2 {'extend' if small else 'replace'}: price {price(ventry)} -> {item_layer.de2_price(name)}")
    lines = ['﻿<?xml version="1.0" encoding="UTF-8"?>',
             "<!-- Generated by tools/gen_econ.py: ECON-01 to ECON-04, legacy Ghost Mode's item prices and price tags on the"
             " items no other item tool writes, and DE2's prices of 5.x's new gear; WGT-03 to WGT-06, the items' weights and"
             " EncumbranceOff tags (short extend entries; Hearts of Stone, NG+ and block changes whole); do not edit. -->",
             "<redxml>", "<definitions>", "<items>"]
    last = None
    for p, name, entry in sorted(blocks):
        if p != last:
            lines.append(f"\n<!-- {p.split('modGhostMode/files/', 1)[-1]} -->")
            last = p
        lines.append("\t" + entry.strip())
    lines += ["", "</items>", "</definitions>", "</redxml>", ""]
    return "\r\n".join(x.replace("\r\n", "\n").replace("\n", "\r\n") for x in lines), report, counts


def final_items(worktree, folder, v):
    """{name: entry} as the game reads it: the DLC's entry (an `extend` resolved over 5.x's), else 5.x's."""
    gi, _ = arm.dlc_entries(worktree, folder)
    out = {n: e[1] for n, e in v.items()}
    out.update(gi)
    return out, gi


def price(entry):
    return head_values(entry).get("price")


def num(x):
    try:
        return float(x)
    except (TypeError, ValueError):
        return None


def mods(entry):
    return {t for t in item_layer.split_tags(entry) if t.startswith("mod_")}


def de2_rule_problems(m, l, v):
    """Every DE2 price recomputed from the branches (regular folder): the counterpart exists in 1.32 and legacy,
    the item is new in 5.x, the price follows its rule; every new priced 5.x item of a gear, schematic or horse
    category is in DE2 or a category 5.x keeps (Gwent cards, potions, quest items)."""
    out = []
    for name, (p, cp, rule) in sorted(item_layer.DE2.items()):
        if name not in v or name in m:
            out.append(f"DE2 {name}: not a new 5.x item of the regular folder")
            continue
        if cp not in m or cp not in l:
            out.append(f"DE2 {name}: counterpart {cp} not in 1.32 and legacy")
            continue
        vp, mp, lp = num(price(v[name][1])), num(price(m[cp][1])), num(price(l[cp][1]))
        want = int(lp) if rule == "copy" else int(vp * lp / mp + 0.5)
        if rule == "owner":
            if abs(want - p) > 1:
                out.append(f"DE2 {name}: the owner's {p}, the ratio {want}: more than a crown apart")
        elif want != p:
            out.append(f"DE2 {name}: {p}, its rule gives {want}")
    keep = {"gwint", "potion", "misc", "key", "usable", "mask", "hair", "head", "horse_tail"}
    for name, (vpath, ve, _) in sorted(v.items()):
        if name in m or not num(price(ve)) or item_layer.de2_name(name):
            continue
        cat = head_values(ve).get("category")
        if cat not in keep:
            out.append(f"DE2: new 5.x item {name} ({cat}, price {price(ve)}) not priced")
    return out


def binaries_expected(path, edits):
    """5.x's file with the edits applied as cr2w_patch.py applies them; (bytes, changes, all matched)."""
    vanilla = subprocess.run(["git", "-C", arm.REPO, "show", "vanilla-5.x:" + path], capture_output=True, check=True).stdout
    ops = [cr2w_patch.Op(e) for e in edits]
    numeric = all(o.kind == "set" and o.nth is None and all(s is None for _, s in o.path) and not o.path[0][0].startswith("@")
                  and re.fullmatch(r"-?[\d.]+", o.old) and re.fullmatch(r"-?[\d.]+", o.new) for o in ops)
    if numeric:
        out, changes, hit = cr2w_patch.patch(vanilla, [(o.cls, ".".join(c for c, _ in o.path), int(o.old), int(o.new)) for o in ops])
    else:
        out, changes, hit = cr2w_patch.apply(vanilla, ops)
    return out, changes, len(hit) == len(ops)


def verify_binaries(worktree):
    bad = 0
    for path, edits in BINARIES:
        port = open(os.path.join(worktree, path), "rb").read()
        expected, changes, all_hit = binaries_expected(path, edits)
        ok = port == expected and all_hit and cr2w_patch.check_crcs(port)
        print("%s %s: %s" % ("ok  " if ok else "DIFF", os.path.basename(path), "; ".join(c.split(": ", 1)[-1] if "name added" not in c else c for c in changes)))
        bad += not ok
    return bad


def verify(worktree, write_test=False):
    unexplained, test = 0, []
    for folder in ("items", "items_plus"):
        m, l, v = arm.items("vanilla-1.32", folder), arm.items("legacy-GM", folder), arm.items("vanilla-5.x", folder)
        fin, gi = final_items(worktree, folder, v)
        econ_file = os.path.join(worktree, arm.DLC, folder, OUT)
        stubs = set(re.findall(r'<item name="([^"]+)"[^>]*on_conflict="extend"', open(econ_file, encoding="utf-8-sig").read())) if os.path.exists(econ_file) else set()
        explained, problems, checked = collections.Counter(), [], 0
        for name, (path, feats) in econ_units(folder).items():
            if name not in m or name not in l or name not in v:
                explained["item not in all three branches"] += 1
                continue
            fe, me, le, ve = fin[name], m[name][1], l[name][1], v[name][1]
            # empty entries (the Hearts of Stone pitfall, a lost price, category or name key)
            fh, vh = head_values(fe), head_values(ve)
            for a in ("category", "localisation_key_name"):
                if vh.get(a) and fh.get(a) != vh.get(a) and head_values(le).get(a) != fh.get(a):
                    problems.append(f"{folder}: item {name}: {a} {fh.get(a)} (5.x {vh.get(a)})")
            if num(vh.get("price")) and not num(fh.get("price")) and num(price(le)):
                problems.append(f"{folder}: item {name}: price {fh.get('price')} (empty entry?)")
            # the price
            checked += 1
            if num(price(fe)) != num(price(le)):
                if num(price(ve)) != num(price(me)):
                    explained["price: 5.x changed it, 5.x's kept"] += 1
                else:
                    problems.append(f"{folder}: item {name}: price {price(fe)}, legacy {price(le)}")
            # the price tags (ECON's, and the other areas' mod_ tags as they port them)
            ft, mt, lt, vt = mods(fe), mods(me), mods(le), mods(ve)
            for t in sorted(ft | lt):
                checked += 1
                if (t in ft) == (t in lt):
                    continue
                if (t in vt) != (t in mt):
                    explained[f"{t}: 5.x changed it, 5.x's kept"] += 1
                elif t in item_layer.ECON_KEEP:
                    explained[f"{t}: another area's tag"] += 1
                else:
                    problems.append(f"{folder}: item {name}: {t} {'missing' if t in lt else 'present'}")
            # every other tag kept (an extend adds and removes only ECON's)
            other_f = {t for t in item_layer.split_tags(fe) if not t.startswith("mod_")}
            if name not in gi or name in stubs:
                other_v = {t for t in item_layer.split_tags(ve) if not t.startswith("mod_")}
                if other_f != other_v:
                    problems.append(f"{folder}: item {name}: other tags {sorted(other_f ^ other_v)} changed by ECON's entry")
            if folder == "items":
                test.append((name, fe, sorted(ft | mt | lt | vt)))
        # DE2: 5.x's new items priced by analogy (item_layer.DE2)
        de2 = 0
        for name, (vpath, ve, vtags) in sorted(v.items()):
            if name in m or item_layer.de2_name(name) is None:
                continue
            de2 += 1
            fe = fin[name]
            fh, vh = head_values(fe), head_values(ve)
            if num(fh.get("price")) != item_layer.de2_price(name):
                problems.append(f"{folder}: DE2 item {name}: price {fh.get('price')}, DE2 {item_layer.de2_price(name)}")
            for a in ("category", "localisation_key_name"):
                if fh.get(a) != vh.get(a):
                    problems.append(f"{folder}: DE2 item {name}: {a} {fh.get(a)} (5.x {vh.get(a)})")
            if mods(fe) != set(item_layer.de2_tags(name)):
                problems.append(f"{folder}: DE2 item {name}: price tags {sorted(mods(fe))}, its counterpart's"
                                f" {sorted(item_layer.de2_tags(name))}")
            if name not in gi or name in stubs:
                if {t for t in item_layer.split_tags(fe) if not t.startswith("mod_")} != {t for t in item_layer.split_tags(ve) if not t.startswith("mod_")}:
                    problems.append(f"{folder}: DE2 item {name}: tags changed by ECON's entry")
            checked += 1
            if folder == "items":
                test.append((name, fe, sorted(mods(fe) | mods(ve))))
        explained["DE2 prices of 5.x's new items (item_layer.DE2), checked"] += de2
        if folder == "items":
            problems += de2_rule_problems(m, l, v)
        # DLC entries with ECON fields not legacy's on items no ECON unit names: none expected
        dup = gen_item.duplicates(worktree, folder)
        problems += [f"{folder}: defined twice: {d}" for d in dup]
        print(f"{folder}: {checked} prices and price tags of {len(econ_units(folder))} ECON units checked; explained differences:")
        for reason, n in sorted(explained.items()):
            print(f"  {n:5d}  {reason}")
        for p in problems:
            print("  UNEXPLAINED " + p)
        print(f"{folder}: {len(problems)} unexplained")
        unexplained += len(problems)
    return unexplained, test


def data_test(test):
    """tests/gmTestsEconData.ws: each regular ECON unit's price, category, name key and price tags."""
    calls = []
    for name, fe, tags in test:
        h = head_values(fe)
        p = int(round(num(h.get("price")) or 0))
        has = set(item_layer.split_tags(fe))
        calls.append(f"\tf += GMTestEconDef('{name}', {p}, '{h.get('category', '')}', \"{h.get('localisation_key_name', '')}\", checks);")
        for t in tags:
            if " " in t:  # a misspelt 1.32 tag with a space (mod_valuable EP1) cannot be a name literal
                continue
            calls.append(f"\tf += GMTestEconTag('{name}', '{t}', {'true' if t in has else 'false'}, checks);")
    out = ["// Generated by tools/gen_econ.py; do not edit. ECON-01 to ECON-04's data as the game reads it (docs/features/econ.md):",
           "// every regular ECON unit's list price (the definition's), category and name key (none lost: the Hearts of Stone",
           "// pitfall), and each mod_ price tag it has in 1.32, legacy or 5.x, present or absent as Ghost Mode's DLC gives it",
           "// (tools/gen_econ.py --verify compares that with legacy's). One function per group: compiler memory.", ""]
    n = 0
    for i in range(0, len(calls), CHUNK):
        n += 1
        out += [f"function GMTestEconData{n}(out checks : int) : int", "{", "\tvar f : int;", ""] + calls[i:i + CHUNK] + ["\treturn f;", "}", ""]
    out += ["function GMTestEconDataAll(out checks : int) : int", "{", "\tvar f : int;", ""]
    out += [f"\tf += GMTestEconData{k}(checks);" for k in range(1, n + 1)] + ["\treturn f;", "}", ""]
    out += ["function GMTestEconDataItems() : int", "{", f"\treturn {len(test)};", "}", "",
            "function GMTestEconDataChecks() : int", "{", f"\treturn {len(calls)};", "}", ""]
    return "\r\n".join(out)


def main():
    ap = argparse.ArgumentParser()
    paths.add_worktree(ap)  # required: parallel areas each pass their own worktree
    ap.add_argument("--check", action="store_true")
    ap.add_argument("--verify", action="store_true")
    args = ap.parse_args()
    if args.verify:
        bad, _ = verify(args.worktree)
        bad += verify_binaries(args.worktree)
        # ECON audit F1: an entry without on_conflict on a name 5.x defines is ignored by the game; every
        # gm_*.xml of the DLC's definition folders, whichever tool wrote it
        nc = dlc_conflicts.missing(args.worktree)
        for b in nc:
            print("  NO on_conflict " + b)
        print(f"on_conflict: {len(nc)} DLC entries without it on a name 5.x defines (all definition folders)")
        bad += len(nc)
        print("verify:", "differences found" if bad else "no difference")
        sys.exit(1 if bad else 0)
    stale = False
    for folder in ("items", "items_plus"):
        text, report, counts = generate(args.worktree, folder)
        print("\n".join(report))
        print(f"{folder}: " + ", ".join(f"{k} {n}" for k, n in sorted(counts.items())))
        ET.fromstring(text.lstrip("﻿").encode("utf-8"))
        dst = os.path.join(args.worktree, arm.DLC, folder, OUT)
        old = open(dst, encoding="utf-8", newline="").read() if os.path.exists(dst) else None
        if old != text:
            stale = True
            if not args.check:
                with open(dst, "w", encoding="utf-8", newline="") as f:
                    f.write(text)
    _, test = verify(args.worktree)  # the data test is written from the items as the game reads them
    ws = data_test(test)
    dst = os.path.join(args.worktree, TEST)
    old = open(dst, encoding="utf-8", newline="").read() if os.path.exists(dst) else None
    if old != ws:
        stale = True
        if not args.check:
            with open(dst, "w", encoding="utf-8", newline="") as f:
                f.write(ws)
    if args.check and stale:
        sys.exit("gm_econ.xml or gmTestsEconData.ws is out of date: run python tools/gen_econ.py")


if __name__ == "__main__":
    main()
