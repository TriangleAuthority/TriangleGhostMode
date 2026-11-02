"""Generate ITEM's item overrides for Ghost Mode's DLC and verify ITEM's fields (docs/features/item.md).

ITEM's fields (level tags, level ranges, ...; `item_layer.py` lists them by feature) join the entries
the area tools already write: `gen_arm_items.py` and `gen_swd_items.py` apply them to their armor
pieces, swords and abilities. This tool writes every other entry ITEM changes: 5.x's entry
(`vanilla-5.x`) given whole with ITEM's ported fields merged three-way from legacy, on_conflict="replace",
for every ITEM unit of `docs/features/attribution.csv` whose name no other file of Ghost Mode's DLC
defines (one entry per name: run it after the other item tools).

    python tools/gen_item.py [--worktree DIR] [--check | --verify]

Writes `items/gm_item.xml` and `items_plus/gm_item.xml` (default worktree ../TGM-5x-GM). --check
writes nothing and fails if a file is out of date. --verify reads what the game reads (Ghost Mode's DLC
over 5.x) and compares every ITEM field of every ITEM unit with legacy's: differences that are rules of
the port (5.x's own change kept, a slice not ported yet) are counted by reason, any other is listed and
fails; it also fails on a name defined twice in Ghost Mode's DLC folder.
"""
import argparse, os, re, sys
import xml.etree.ElementTree as ET

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import gen_arm_items as arm  # noqa: E402
import item_layer  # noqa: E402

OUT = "gm_item.xml"
ECON_OUT = "gm_econ.xml"  # gen_econ.py's, written after this tool: the ECON-only entries


def other_names(worktree, folder):
    """Item and ability names defined by the DLC folder's other files."""
    its, abls = set(), set()
    d = os.path.join(worktree, arm.DLC, folder)
    for f in sorted(os.listdir(d)):
        if not f.endswith(".xml") or f in (OUT, ECON_OUT):
            continue
        text = arm.blank_comments(open(os.path.join(d, f), encoding="utf-8-sig").read())
        for _, _, head in arm.item_spans(text):
            n = re.search(r'\bname\s*=\s*"([^"]+)"', head)
            if n:
                its.add(n.group(1))
        abls.update(m.group(1) for m in arm.ABILITY.finditer(text))
    return its, abls


def set_tags(entry, tags):
    tm = arm.TAGS.search(arm.blank_comments(entry))
    return entry[:tm.start(2)] + "\t\t\t\t\t\t\t" + ", ".join(tags) + "\n\t\t" + entry[tm.end(2):] if tm else None


def generate(worktree, folder):
    m, l, v = arm.items("master", folder), arm.items("legacy-GM", folder), arm.items("vanilla-5.x", folder)
    ma, la, va = arm.abilities("master", folder), arm.abilities("legacy-GM", folder), arm.abilities("vanilla-5.x", folder)
    taken_i, taken_a = other_names(worktree, folder)
    iblocks, ablocks, report = [], [], []
    for (fold, kind, name), (path, feats) in sorted(item_layer.units().items()):
        if fold != folder or not item_layer.ported(folder, kind, name):
            continue
        if kind == "item":
            if name in l and name not in m and name not in v and name not in taken_i:
                if not feats <= item_layer.PORTED:
                    continue  # a new item is written once every feature it carries is ported
                # an item legacy added (the master kits): legacy's, new
                iblocks.append((l[name][0], name, l[name][1]))
                report.append(f"{folder}: new item {name}")
                continue
            if name in taken_i or name not in m or name not in l or name not in v:
                continue
            vpath, ventry, vtags = v[name]
            # written whole only for another area's change; ECON's fields join it (gen_econ.py writes the rest)
            if (item_layer.merge_tags(folder, name, m[name][2], l[name][2], vtags, vtags, item_layer.WHOLE) == vtags
                    and not item_layer.merge_attrs(folder, name, m[name][1], l[name][1], ventry, item_layer.WHOLE)[1]
                    and not item_layer.merge_blocks(folder, name, m[name][1], l[name][1], ventry, item_layer.WHOLE)[1]):
                continue
            new = item_layer.merge_tags(folder, name, m[name][2], l[name][2], vtags, vtags)
            entry, achanges = item_layer.merge_attrs(folder, name, m[name][1], l[name][1], ventry)
            entry, bchanges = item_layer.merge_blocks(folder, name, m[name][1], l[name][1], entry)
            achanges += bchanges
            if new == vtags and not achanges:
                continue
            if new != vtags:
                entry = set_tags(entry, new)
                if entry is None:
                    report.append(f"{folder}: item {name}: 5.x's entry has no tags, not written")
                    continue
            iblocks.append((vpath, name, re.sub(r'^<item\b', '<item on_conflict="replace"', entry)))
            report.append(f"{folder}: item {name}: " + "; ".join(([f"tags {', '.join(vtags)} -> {', '.join(new)}"] if new != vtags else []) + achanges))
        else:
            if name in la and name not in ma and name not in va and name not in taken_a:
                # an ability legacy added (MA_ArmorPenetrationPerc): legacy's, new
                ablocks.append((la[name][0], name, f'<ability name="{name}">{la[name][1]}</ability>'))
                report.append(f"{folder}: new ability {name}")
                continue
            if name in taken_a or name not in ma or name not in la or name not in va:
                continue
            body, changes = item_layer.merge_nodes(folder, name, ma[name][2], la[name][2], va[name][1], arm.nodes, arm.norm)
            if not changes:
                continue
            ablocks.append((va[name][0], name, f'<ability name="{name}" on_conflict="replace">{body}</ability>'))
            report.append(f"{folder}: ability {name}: {', '.join(changes)}")
    lines = ['﻿<?xml version="1.0" encoding="UTF-8"?>',
             "<!-- Generated by tools/gen_item.py from 5.x's entries with ITEM's changes from legacy Ghost Mode"
             " (entries no other item tool writes); do not edit. -->", "<redxml>", "<definitions>", "<abilities>"]
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


def attr(entry, a):
    """The value of an opening-tag attribute, or None."""
    h, _ = item_layer.head(entry)
    return entry[h[a][0]:h[a][1]].strip() if a in h else None


def duplicates(worktree, folder):
    """Names defined by more than one entry in the DLC folder."""
    seen, dup = {}, []
    d = os.path.join(worktree, arm.DLC, folder)
    for f in sorted(os.listdir(d)):
        if not f.endswith(".xml"):
            continue
        text = arm.blank_comments(open(os.path.join(d, f), encoding="utf-8-sig").read())
        names = [("item", re.search(r'\bname\s*=\s*"([^"]+)"', h).group(1)) for _, _, h in arm.item_spans(text)
                 if re.search(r'\bname\s*=\s*"([^"]+)"', h)]
        names += [("ability", mm.group(1)) for mm in arm.ABILITY.finditer(text)]
        for k in names:
            if k in seen:
                dup.append(f"{k[0]} {k[1]} in {seen[k]} and {f}")
            seen[k] = f
    return dup


def verify(worktree):
    """Every ITEM field of every ITEM unit as the game reads it (DLC over 5.x) against legacy's."""
    unexplained = 0
    for folder in ("items", "items_plus"):
        m, l, v = arm.items("master", folder), arm.items("legacy-GM", folder), arm.items("vanilla-5.x", folder)
        ma, la, va = arm.abilities("master", folder), arm.abilities("legacy-GM", folder), arm.abilities("vanilla-5.x", folder)
        gi, ga = arm.dlc_entries(worktree, folder)
        explained, problems, checked = {}, [], [0, 0]

        def note(reason):
            explained[reason] = explained.get(reason, 0) + 1

        for (fold, kind, name), (path, feats) in sorted(item_layer.units().items()):
            if fold != folder:
                continue
            for f in sorted(feats):
                own_n = item_layer.NODES.get(f, set())
                own_t = item_layer.own_tags(f, m[name][2], l[name][2]) if kind == "item" and name in m and name in l else item_layer.TAGS.get(f, set())
                if kind == "item" and own_t:
                    if name not in m or name not in l or name not in v:
                        note("item not in all three branches")
                        continue
                    final = arm.split_tags(arm.blank_comments(gi[name])) if name in gi else v[name][2]
                    mt, lt, vt = m[name][2], l[name][2], v[name][2]
                    for t in sorted(own_t):
                        checked[0] += 1
                        if (t in final) == (t in lt):
                            continue
                        if f not in item_layer.PORTED:
                            note(f"{f} not ported yet")
                        elif (t in vt) != (t in mt):
                            note(f"{t}: 5.x changed it, 5.x's kept")
                        elif (t in mt) == (t in lt):
                            note(f"{t}: legacy did not change it (5.x's kept)")
                        else:
                            problems.append(f"{folder}: item {name}: {t} {'missing' if t in lt else 'present'} ({f})")
                if kind == "item" and name in l and name not in m and name not in v:
                    checked[0] += 1
                    other = [r for (ft, p), r in item_layer.ELSEWHERE.items() if ft in feats and re.match(p, name)]
                    if other:
                        note(other[0])
                        continue
                    if not feats <= item_layer.PORTED:
                        note(f"{f}: new item, {', '.join(sorted(feats - item_layer.PORTED))} not ported yet")
                    elif name not in gi or " ".join(gi[name].split()) != " ".join(l[name][1].split()):
                        problems.append(f"{folder}: new item {name} missing or not legacy's")
                    continue
                for tag in sorted(item_layer.BLOCKS.get(f, set())):
                    if kind != "item" or name not in l or name not in v:
                        continue
                    checked[0] += 1
                    blk = lambda e: item_layer.norm_block(item_layer.block_of(e, tag))
                    if blk(gi.get(name, v[name][1])) == blk(l[name][1]):
                        continue
                    if f not in item_layer.PORTED:
                        note(f"{f} not ported yet")
                    elif (tag, name) in item_layer.KEEP_5X and blk(gi.get(name, v[name][1])) == blk(v[name][1]):
                        note(f"{tag}: another area's part of legacy's block, 5.x's kept (KEEP_5X)")
                    elif name in m and blk(v[name][1]) != blk(m[name][1]) and (tag, name) not in item_layer.FORCE_LEGACY:
                        note(f"{tag}: 5.x changed it, 5.x's kept")
                    else:
                        problems.append(f"{folder}: item {name}: {tag} not legacy's ({f})")
                own_a = item_layer.ATTRS.get(f, set())
                if kind == "item" and own_a and name in l and name in v:
                    fe = gi.get(name, v[name][1])
                    for a in sorted(own_a):
                        checked[0] += 1
                        if attr(fe, a) == attr(l[name][1], a):
                            continue
                        if f not in item_layer.PORTED:
                            note(f"{f} not ported yet")
                        elif name in m and attr(v[name][1], a) != attr(m[name][1], a):
                            note(f"{a}: 5.x changed it, 5.x's kept")
                        else:
                            problems.append(f"{folder}: item {name}: {a} is {attr(fe, a)}, legacy {attr(l[name][1], a)} ({f})")
                if kind == "ability" and own_n and name in la and name not in ma and name not in va:
                    checked[1] += 1
                    if f not in item_layer.PORTED:
                        note(f"{f} not ported yet")
                    elif name not in ga or {k: arm.values(x[2]) for k, x in ga[name].items()} != {k: arm.values(x[2]) for k, x in la[name][2].items()}:
                        problems.append(f"{folder}: new ability {name} missing or not legacy's")
                    continue
                if kind == "ability" and own_n:
                    if name not in ma or name not in la or name not in va:
                        note("ability not in all three branches")
                        continue
                    final = ga.get(name) or va[name][2]
                    mn, ln, vn = ma[name][2], la[name][2], va[name][2]
                    for k in sorted(set(mn) | set(ln) | set(final), key=str):
                        if not item_layer.owns(own_n, k[0]):
                            continue
                        checked[1] += 1
                        fv, lv = final.get(k), ln.get(k)
                        if (fv and arm.norm(fv[2])) == (lv and arm.norm(lv[2])) or (fv and lv and arm.values(fv[2]) == arm.values(lv[2])):
                            continue
                        mv, vv = mn.get(k), vn.get(k)
                        if f not in item_layer.PORTED:
                            note(f"{f} not ported yet")
                        elif (mv and arm.norm(mv[2])) != (vv and arm.norm(vv[2])):
                            note(f"{k[0]}: 5.x changed it, 5.x's kept")
                        else:
                            problems.append(f"{folder}: ability {name}: {k[0]} {k[1]} is {fv and fv[2].strip()}, legacy {lv and lv[2].strip()} ({f})")
        dup = duplicates(worktree, folder)
        problems += [f"{folder}: defined twice: {d}" for d in dup]
        print(f"{folder}: {checked[0]} tags and {checked[1]} nodes checked; explained differences:")
        for reason, n in sorted(explained.items()):
            print(f"  {n:5d}  {reason}")
        for p in problems:
            print("  UNEXPLAINED " + p)
        print(f"{folder}: {len(problems)} unexplained")
        unexplained += len(problems)
    return unexplained


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--worktree", default=os.path.join(arm.REPO, "..", "TGM-5x-GM"))
    ap.add_argument("--check", action="store_true")
    ap.add_argument("--verify", action="store_true")
    args = ap.parse_args()
    if args.verify:
        sys.exit(1 if verify(args.worktree) else 0)
    stale = False
    for folder in ("items", "items_plus"):
        text, report = generate(args.worktree, folder)
        print("\n".join(report))
        print(f"{folder}: {len(report)} entries")
        ET.fromstring(text.lstrip("﻿").encode("utf-8"))
        dst = os.path.join(args.worktree, arm.DLC, folder, OUT)
        old = open(dst, encoding="utf-8", newline="").read() if os.path.exists(dst) else None
        if old != text:
            stale = True
            if not args.check:
                with open(dst, "w", encoding="utf-8", newline="") as f:
                    f.write(text)
    if args.check and stale:
        sys.exit("gm_item.xml is out of date: run python tools/gen_item.py")


if __name__ == "__main__":
    main()
