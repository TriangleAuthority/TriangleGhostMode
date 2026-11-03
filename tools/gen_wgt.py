"""WGT's item and ability weights, the saddlebags' capacities and the horse gear's two stats: write the abilities no
other tool writes, verify them all and write their in-game data test (docs/features/wgt.md, WGT-03 to WGT-06).

WGT owns the `weight` attribute of its item units and the `EncumbranceOff` tag of three items
(`item_layer.py`'s WGT lines, PW2). Whichever generator writes an item entry whole applies them
(`gen_item.py`, `gen_ench.py` through `item_layer.apply_item`); `gen_econ.py` writes the WGT units no other file
defines, in the same entry as the item's price (short `extend` entries; Hearts of Stone and NG+ whole, PW4); the
razor's hand-written entry in `gm_ui.xml` carries legacy's 0.3 by hand.

The abilities' nodes WGT owns (slice W2: `<weight>`; WGT-06's `encumbrance`, `panic`, `sprint_stamina_cost`) are
applied the same way by the tools that write an ability whole (`gen_arm_items.py`, `gen_swd_items.py`, `gen_item.py`
through `item_layer.merge_nodes`; `gen_ai.py` with WGT in its PORTED; `gen_xbow.py`). This tool writes the rest
into `items/gm_wgt.xml` and `items_plus/gm_wgt.xml` (PW4): an `extend` entry with only the changed nodes for an
ability of the base game or Blood and Wine; the entry whole (5.x's with WGT's nodes, `replace`) for Hearts of Stone
(`extend` empties it), the free DLCs (not probed), an ability losing a node and every NG+ entry. Names another DLC
file defines (TRPH's trophy abilities, written whole with legacy's weights) are skipped.

How the game reads an item's weight (slice W1's probe, 2026-11-02, `gmtest_wgt_probe`): `GetItemWeight` is the
item's own `weight` attribute when it has one above 0, else the `<weight>` nodes of its abilities (not a sum:
Blood and Wine's Toussaint Crossbow 1, item 1.53 and ability 2.39, weighs 1.53). The data test computes each
item's expected weight that way from the definitions as the game reads them (Ghost Mode's DLC over 5.x).

    python tools/gen_wgt.py --worktree DIR [--check | --verify]

Writes `gm_wgt.xml` and the data test `tests/gmTestsWgtData.ws` (every regular WGT item unit: its weight read from
a copy spawned into the horse manager's inventory, and whether it counts towards the load; every regular WGT
ability unit's owned nodes legacy changed, read from the definitions; read by `GMTest_wgt` in the regression).
Run it last (after `gen_econ.py`). --check writes nothing and fails if a file is out of date. --verify compares
every WGT item unit's weight and EncumbranceOff tag and every WGT ability unit's owned nodes as the game reads
them (Ghost Mode's DLC over 5.x, `extend` entries resolved; both folders) with legacy's, and fails on a name
defined twice in the DLC folder.
"""
import argparse, collections, os, re, sys
import xml.etree.ElementTree as ET

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import gen_arm_items as arm  # noqa: E402
import gen_item  # noqa: E402
import item_layer  # noqa: E402
import paths  # noqa: E402

TEST = "modGhostMode/scripts/local/gm/tests/gmTestsWgtData.ws"
OUT = "gm_wgt.xml"
FEATS = {"WGT-03", "WGT-04", "WGT-05", "WGT-06"}
WGT = ("WGT-",)
CHUNK = 60  # data-test calls per function (script compiler memory)
ABILITY_ANY = re.compile(r'<ability\b([^>]*?)(?<!/)>(.*?)</ability>', re.S)
DUPLICATES = {}  # (worktree, folder, skip): abilities defined twice, as dlc_abilities found them
BOM = "﻿"


def wgt_units(folder, kind):
    """{name: WGT features} of the WGT units of a kind ("item", "ability") in a folder."""
    out = {}
    for (fold, k, name), (path, feats) in sorted(item_layer.units().items()):
        f = feats & FEATS
        if fold == folder and k == kind and f:
            out[name] = f
    return out


def owned(feats):
    """The ability nodes the ported WGT features own."""
    out = set()
    for f in feats:
        if f in item_layer.PORTED:
            out |= item_layer.NODES.get(f, set())
    return out


def attr(entry, a):
    h, _ = item_layer.head(entry)
    return entry[h[a][0]:h[a][1]].strip() if a in h else None


def num(x):
    try:
        return float(x)
    except (TypeError, ValueError):
        return None


def dlc_abilities(worktree, folder, skip=None):
    """{name: (file, extend?, body)} of every ability the DLC folder's files define (`skip`: a file left out)."""
    out, dup = {}, []
    d = os.path.join(worktree, arm.DLC, folder)
    for f in sorted(os.listdir(d)):
        if not f.endswith(".xml") or f == skip:
            continue
        text = arm.blank_comments(open(os.path.join(d, f), encoding="utf-8-sig").read())
        # any attribute order (gen_arm_new.py writes `on_conflict` before `name`, which arm.ABILITY misses)
        for m in ABILITY_ANY.finditer(text):
            n = re.search(r'\bname\s*=\s*"([^"]+)"', m.group(1))
            if not n:
                continue
            if n.group(1) in out:
                dup.append(f"ability {n.group(1)} in {out[n.group(1)][0]} and {f}")
            ext = bool(re.search(r'on_conflict\s*=\s*"extend"', m.group(1)))
            out[n.group(1)] = (f, ext, m.group(2))
    DUPLICATES[(worktree, folder, skip)] = dup
    return out


def node_list(body):
    """[(tag, node text)] of an ability body's value nodes, in order."""
    return [(m.group(1), m.group(0)) for m in arm.NODE.finditer(arm.blank_comments(body))]


def resolve(name, dlc, va):
    """An ability's value nodes as the game reads them ([(tag, text)]): the DLC's entry (an `extend` entry's nodes
    replace 5.x's of the same tag in order, the rest kept; a Hearts of Stone ability comes out empty), else 5.x's."""
    if name not in dlc:
        return node_list(va[name][1]) if name in va else []
    _, ext, body = dlc[name]
    if not ext or name not in va:
        return node_list(body)
    if "/dlc/ep1/" in va[name][0]:
        return []
    by_tag = collections.defaultdict(list)
    for t, x in node_list(body):
        by_tag[t].append(x)
    out, used = [], collections.Counter()
    for t, x in node_list(va[name][1]):
        out.append((t, by_tag[t][used[t]] if used[t] < len(by_tag[t]) else x))
        used[t] += 1
    for t, xs in by_tag.items():
        out += [(t, x) for x in xs[used[t]:]]
    return out


def node_type(x):
    m = re.search(r'\btype\s*=\s*"([^"]*)"', x)
    return m.group(1) if m else "base"


def parts(nodes, tag):
    """(base, mult, add) of a tag's nodes, as GetAbilityAttributeValue sums their min values."""
    b = mu = a = 0.0
    for t, x in nodes:
        if t != tag:
            continue
        m = re.search(r'\bmin\s*=\s*"([^"]*)"', x)
        v = (num(m.group(1)) if m else 0.0) or 0.0
        typ = node_type(x)
        if typ == "mult":
            mu += v
        elif typ == "add":
            a += v
        else:
            b += v
    return (round(b, 4), round(mu, 4), round(a, 4))


def tag_values(nodes, tag):
    return [(node_type(x),) + arm.values(x) for t, x in nodes if t == tag]


def generate(worktree, folder):
    """gm_wgt.xml's text: the WGT ability units no other DLC file defines; report, counts."""
    ma, la, va = (arm.abilities(b, folder) for b in ("master", "legacy-GM", "vanilla-5.x"))
    other = dlc_abilities(worktree, folder, skip=OUT)
    blocks, report, counts = [], [], collections.Counter()
    for name, feats in wgt_units(folder, "ability").items():
        if name in other:
            counts["written whole by another tool"] += 1
            continue
        if name not in ma or name not in la or name not in va:
            counts["not in all three branches"] += 1
            continue
        vpath, vbody, _ = va[name]
        body, changes = item_layer.merge_nodes(folder, name, ma[name][2], la[name][2], vbody, arm.nodes, arm.norm, WGT)
        if not changes:
            counts["no change to carry (5.x's own change kept, or legacy's equal)"] += 1
            continue
        tags = {c.split()[0].lstrip("+-") for c in changes}
        old, new = node_list(vbody), node_list(body)
        same_count = all(sum(t == g for t, _ in old) == sum(t == g for t, _ in new) for g in tags)
        whole = (folder == "items_plus" or "/dlc/ep1/" in vpath or ("/dlc/" in vpath and "/dlc/bob/" not in vpath)
                 or any(c.startswith("-") for c in changes) or not same_count)
        if whole:
            entry = f'<ability name="{name}" on_conflict="replace">{body}</ability>'
            counts["replace (NG+)" if folder == "items_plus" else "replace (Hearts of Stone, free DLC, a node removed)"] += 1
        else:
            entry = (f'<ability name="{name}" on_conflict="extend">\n'
                     + "".join(f"\t\t{x.strip()}\n" for t, x in new if t in tags) + "\t</ability>")
            counts["extend"] += 1
        blocks.append((vpath, name, entry))
        report.append(f"{folder}: ability {name}: {'replace' if whole else 'extend'}: {', '.join(changes)}")
    # DW2 (slice W3): 5.x's new gear at its counterpart's legacy weight, on the piece's own ability
    done = {n for _, n, _ in blocks}
    for name in sorted(va):
        w = item_layer.dw2_weight(name)
        if w is None or name in other or name in done:
            continue
        vpath, vbody, _ = va[name]
        nodes = [(t, x) for t, x in node_list(vbody) if t == "weight"]
        if len(nodes) != 1:
            report.append(f"{folder}: ability {name}: DW2 skipped ({len(nodes)} weight nodes)")
            continue
        old = nodes[0][1]
        new = re.sub(r'\b(min|max)\s*=\s*"[^"]*"', lambda m: f'{m.group(1)}="{fmt(w)}"', old)
        if new == old:
            continue
        if folder == "items_plus" or "/dlc/" in vpath:
            entry = f'<ability name="{name}" on_conflict="replace">{vbody.replace(old, new, 1)}</ability>'
            counts["DW2 replace (NG+)" if folder == "items_plus" else "DW2 replace"] += 1
        else:
            entry = f'<ability name="{name}" on_conflict="extend">\n\t\t{new.strip()}\n\t</ability>'
            counts["DW2 extend"] += 1
        blocks.append((vpath, name, entry))
        report.append(f"{folder}: ability {name}: DW2 weight {parts(nodes, 'weight')[0]} -> {fmt(w)}")
    lines = [BOM + '<?xml version="1.0" encoding="UTF-8"?>',
             "<!-- Generated by tools/gen_wgt.py: WGT-03 to WGT-06, legacy Ghost Mode's ability weights, saddlebag capacities and"
             " the horse gear's panic and sprint cost on the abilities no other item tool writes, and DW2's weights of 5.x's new"
             " gear (extend entries with the"
             " changed nodes; Hearts of Stone, free DLCs, removed nodes and NG+ whole); do not edit. -->",
             "<redxml>", "<definitions>", "<abilities>"]
    last = None
    for p, name, entry in sorted(blocks):
        if p != last:
            lines.append(f"\n<!-- {p.split('modGhostMode/files/', 1)[-1]} -->")
            last = p
        lines.append("\t" + entry.strip())
    lines += ["", "</abilities>", "</definitions>", "</redxml>", ""]
    return "\r\n".join(x.replace("\r\n", "\n").replace("\n", "\r\n") for x in lines), report, counts


def base_abilities(entry):
    m = re.search(r'<base_abilities>(.*?)</base_abilities>', arm.blank_comments(entry), re.S)
    return re.findall(r'<a>\s*([^<]+?)\s*</a>', m.group(1)) if m else []


def weight_range(nodes):
    """(lowest, highest) base weight of an ability: a node with a `max` above its `min` (absent: 0) is rolled for
    each copy (legacy's pig contest trophy: max 5, so 0 to 5)."""
    lo = hi = 0.0
    for t, x in nodes:
        if t == "weight" and node_type(x) == "base":
            mn = re.search(r'\bmin\s*=\s*"([^"]*)"', x)
            mx = re.search(r'\bmax\s*=\s*"([^"]*)"', x)
            a = (num(mn.group(1)) if mn else 0.0) or 0.0
            b = num(mx.group(1)) if mx else a
            lo, hi = lo + min(a, b), hi + max(a, b)
    return lo, hi


def game_weight(entry, final):
    """GetItemWeight as the probe found it, (lowest, highest): the item's own weight above 0, else the sum of its
    abilities' weights (seen in slice W2: the pig contest trophy's two abilities, 5 and a roll of 0 to 5)."""
    w = num(attr(entry, "weight"))
    if w and w > 0:
        return w, w
    rs = [weight_range(final[a]) for a in base_abilities(entry) if a in final]
    return sum(r[0] for r in rs), sum(r[1] for r in rs)


def counts(entry, tags):
    """IsItemEncumbranceItem (5.x, "Ignore Item Weight" off): EncumbranceOn, else not EncumbranceOff, a recipe,
    a schematic or a body."""
    if "EncumbranceOn" in tags:
        return True
    return not ("EncumbranceOff" in tags or "Body" in tags
                or attr(entry, "category") in ("alchemy_recipe", "crafting_schematic"))


def dw2_expected(name, reg, fin_v):
    """DW2's weight of a new 5.x item (its counterpart's legacy weight as the game reads it, or the item's 5.x weight
    where legacy left the counterpart at 1.32's), and the counterpart; None for an item DW2 does not weigh."""
    k = item_layer.de2_name(name)
    if k is None or "schematic" in k.lower():
        return None
    cp = item_layer.DE2[k][1]
    (m, l, fm, fl) = reg
    cm, cl = game_weight(m[cp][1], fm)[0], game_weight(l[cp][1], fl)[0]
    return (fin_v if abs(cm - cl) < 1e-6 else cl), cp


def verify(worktree):
    unexplained, test = 0, []
    rm, rl = arm.items("master", "items"), arm.items("legacy-GM", "items")
    rfm = {n: node_list(x[1]) for n, x in arm.abilities("master", "items").items()}
    rfl = {n: node_list(x[1]) for n, x in arm.abilities("legacy-GM", "items").items()}
    dw2_seen = set()
    for folder in ("items", "items_plus"):
        m, l, v = arm.items("master", folder), arm.items("legacy-GM", folder), arm.items("vanilla-5.x", folder)
        ma, la, va = (arm.abilities(b, folder) for b in ("master", "legacy-GM", "vanilla-5.x"))
        gi, _ = arm.dlc_entries(worktree, folder)
        dlc = dlc_abilities(worktree, folder)
        final = {n: resolve(n, dlc, va) for n in set(va) | set(dlc)}
        explained, problems, checked = collections.Counter(), [], 0
        items, abls = wgt_units(folder, "item"), wgt_units(folder, "ability")
        for name, feats in items.items():
            if name not in m or name not in l or name not in v:
                explained["item not in all three branches"] += 1
                continue
            fe, me, le, ve = gi.get(name, v[name][1]), m[name][1], l[name][1], v[name][1]
            checked += 1
            if num(attr(fe, "weight")) != num(attr(le, "weight")):
                if num(attr(ve, "weight")) != num(attr(me, "weight")):
                    explained["weight: 5.x changed it, 5.x's kept"] += 1
                else:
                    problems.append(f"{folder}: item {name}: weight {attr(fe, 'weight')}, legacy {attr(le, 'weight')}")
            ft, mt, lt, vt = (set(item_layer.split_tags(e)) for e in (fe, me, le, ve))
            off = "EncumbranceOff"
            if off in mt | lt | ft:
                checked += 1
                if (off in ft) != (off in lt):
                    if (off in vt) != (off in mt):
                        explained[f"{off}: 5.x changed it, 5.x's kept"] += 1
                    else:
                        problems.append(f"{folder}: item {name}: {off} {'missing' if off in lt else 'present'}")
            if folder == "items":
                lo, hi = game_weight(fe, final)
                test.append(("item", name, (round(lo, 4), round(hi, 4)), counts(fe, ft)))
        for name, feats in abls.items():
            if name not in ma or name not in la or name not in va:
                explained["ability not in all three branches"] += 1
                continue
            fn = final.get(name, [])
            ln, mn, vn = node_list(la[name][1]), node_list(ma[name][1]), node_list(va[name][1])
            for tag in sorted(owned(feats)):
                lv, mv, vv, fv = (tag_values(x, tag) for x in (ln, mn, vn, fn))
                if lv == mv:
                    continue  # legacy did not change it
                checked += 1
                if fv != lv:
                    if vv != mv:
                        explained[f"{tag}: 5.x changed it, 5.x's kept"] += 1
                    else:
                        problems.append(f"{folder}: ability {name}: {tag} {fv}, legacy {lv}")
                if folder == "items":
                    test.append(("ability", name, tag, parts(fn, tag)))
        # DW2 (slice W3): every new 5.x gear item DE2 prices (its NG+ copies too) at its counterpart's legacy weight
        fv5 = {n: node_list(x[1]) for n, x in va.items()}
        for name, (vpath, ve, _) in sorted(v.items()):
            if name in m:
                continue
            exp = dw2_expected(name, (rm, rl, rfm, rfl), game_weight(ve, fv5)[0])
            if exp is None:
                continue
            want, cp = exp
            fe = gi.get(name, ve)
            got = game_weight(fe, final)[0]
            checked += 1
            explained["DW2: new 5.x gear at its counterpart's legacy weight, checked"] += 1
            if abs(got - want) > 1e-6:
                problems.append(f"{folder}: DW2 item {name}: weighs {got}, {cp}'s legacy weight {want}")
            for a in base_abilities(fe):
                if item_layer.dw2_weight(a) is not None:
                    if folder == "items" and a not in dw2_seen:
                        test.append(("ability", a, "weight", parts(final.get(a, []), "weight")))
                    dw2_seen.add(a[4:] if a.startswith("NGP ") else a)
            if folder == "items":
                lo, hi = game_weight(fe, final)
                test.append(("item", name, (round(lo, 4), round(hi, 4)), counts(fe, set(item_layer.split_tags(fe)))))
        if folder == "items_plus":
            problems += [f"DW2 table: {a} weighs no DE2 item" for a in sorted(set(item_layer.DW2) - dw2_seen)]
        problems += [f"{folder}: defined twice: {d}" for d in gen_item.duplicates(worktree, folder)]
        problems += [f"{folder}: defined twice: {d}" for d in DUPLICATES.get((worktree, folder, None), [])]
        print(f"{folder}: {checked} weights, tags and nodes of {len(items)} WGT item units and {len(abls)} ability units"
              " checked; explained differences:")
        for reason, n in sorted(explained.items()):
            print(f"  {n:5d}  {reason}")
        for p in problems:
            print("  UNEXPLAINED " + p)
        print(f"{folder}: {len(problems)} unexplained")
        unexplained += len(problems)
    return unexplained, test


def fmt(x):
    s = ("%.4f" % x).rstrip("0")
    return s + "0" if s.endswith(".") else s


def data_test(test):
    # a name with other characters (5.x's `Azurite mineral` has a no-break space) cannot be a name literal
    test = [t for t in test if re.fullmatch(r"[A-Za-z0-9 _]+", t[1])]
    calls = []
    for t in test:
        if t[0] == "item":
            calls.append(f"\tf += GMTestWgtItemDef('{t[1]}', {fmt(t[2][0])}, {fmt(t[2][1])}, {'true' if t[3] else 'false'}, checks);")
        else:
            b, mu, a = t[3]
            calls.append(f"\tf += GMTestWgtAblDef('{t[1]}', '{t[2]}', {fmt(b)}, {fmt(mu)}, {fmt(a)}, checks);")
    out = ["// Generated by tools/gen_wgt.py; do not edit. WGT-03 to WGT-06's data as the game reads it (docs/features/wgt.md):",
           "// every regular WGT item unit's weight (GetItemWeight of a copy spawned into the horse manager's inventory: the",
           "// item's own weight, or its abilities' when it has none) and whether it counts towards the load (EncumbranceOff);",
           "// every regular WGT ability unit's owned nodes legacy changed (weight, saddlebag capacity, blinders' panic, the base",
           "// horse's sprint cost) as the definitions give them (base, mult, add). One function per group: compiler memory.", ""]
    n = 0
    for i in range(0, len(calls), CHUNK):
        n += 1
        out += [f"function GMTestWgtData{n}(out checks : int) : int", "{", "\tvar f : int;", ""] + calls[i:i + CHUNK] + ["\treturn f;", "}", ""]
    out += ["function GMTestWgtDataAll(out checks : int) : int", "{", "\tvar f : int;", ""]
    out += [f"\tf += GMTestWgtData{k}(checks);" for k in range(1, n + 1)] + ["\treturn f;", "}", ""]
    out += ["function GMTestWgtDataItems() : int", "{", f"\treturn {sum(t[0] == 'item' for t in test)};", "}", ""]
    out += ["function GMTestWgtDataChecks() : int", "{", f"\treturn {len(test)};", "}", ""]
    return "\r\n".join(out)


def main():
    ap = argparse.ArgumentParser()
    paths.add_worktree(ap)
    ap.add_argument("--check", action="store_true")
    ap.add_argument("--verify", action="store_true")
    args = ap.parse_args()
    if args.verify:
        bad, _ = verify(args.worktree)
        print("verify:", "differences found" if bad else "no difference")
        sys.exit(1 if bad else 0)
    stale = []

    def write(dst, text):
        old = open(dst, encoding="utf-8", newline="").read() if os.path.exists(dst) else None
        if old is not None and old.replace("\r\n", "\n") == text.replace("\r\n", "\n"):
            return
        stale.append(dst)
        if not args.check:
            with open(dst, "w", encoding="utf-8", newline="") as f:
                f.write(text)

    for folder in ("items", "items_plus"):
        text, report, cnt = generate(args.worktree, folder)
        print("\n".join(report))
        print(f"{folder}: " + ", ".join(f"{k} {n}" for k, n in sorted(cnt.items())))
        ET.fromstring(text.lstrip(BOM).encode("utf-8"))
        write(os.path.join(args.worktree, arm.DLC, folder, OUT), text)
    _, test = verify(args.worktree)  # the data test from the DLC files as they are now
    write(os.path.join(args.worktree, TEST), data_test(test))
    if args.check and stale:
        sys.exit("out of date: " + ", ".join(stale) + ": run python tools/gen_wgt.py")


if __name__ == "__main__":
    main()
