"""Compare item prices, price tags and reward gold across 1.32, legacy Ghost Mode and 5.x (ECON's map,
docs/features/econ.md).

For every item entry in the game's item files (`gameplay/items/` and `items_plus/`, base game and DLCs,
not Ghost Mode's own DLC) it reads the opening tag's `price` and the item's `mod_*` price tags
(`economy_tagmodifiers.csv` rows) on `vanilla-1.32` (1.32), `legacy-GM` and `vanilla-5.x`; for every
`<reward>` in the reward files their `gold`. It reports what legacy changed, by file and item category,
with the ratio legacy/1.32 and what 5.x did to the same values.

    python tools/econ_prices.py                 # summary by file and category
    python tools/econ_prices.py --items [RE]    # one line per changed item (name filter RE)
    python tools/econ_prices.py --rewards       # one line per reward whose gold legacy or 5.x changed
    python tools/econ_prices.py --tags          # the price tag changes, item by item
    python tools/econ_prices.py --units         # the unit keys (docs/features/units.csv) with a money change

Read-only; about a minute (it reads every item file of the three branches).
"""
import argparse, collections, os, re, statistics, subprocess, sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import gen_arm_items as arm  # noqa: E402  items(), item_spans(), blank_comments()

REFS = ("vanilla-1.32", "legacy-GM", "vanilla-5.x")
REWARD = re.compile(r'<reward\b[^>]*\bname\s*=\s*"([^"]+)"[^>]*>', re.S)


def head_attrs(entry):
    end = entry.index(">")
    return {m.group(1): m.group(2) for m in re.finditer(r'\b(\w+)\s*=\s*"([^"]*)"', entry[:end])}


def num(v):
    try:
        return float(v)
    except (TypeError, ValueError):
        return None


def load_items():
    """{(folder, name): {ref: (path, price, category, mod tags)}}"""
    out = collections.defaultdict(dict)
    for ref in REFS:
        for folder in ("items", "items_plus"):
            for name, (path, entry, tags) in arm.items(ref, folder).items():
                a = head_attrs(arm.blank_comments(entry))
                out[(folder, name)][ref] = (path, a.get("price"), a.get("category", "?"),
                                            tuple(sorted(t for t in tags if t.startswith("mod_"))))
    return out


def load_rewards():
    """{(path, name): {ref: gold}}"""
    out = collections.defaultdict(dict)
    for ref in REFS:
        for path in arm.git("ls-tree", "-r", "--name-only", ref).splitlines():
            if not path.endswith("rewards.xml") or "dlcghostmode" in path:
                continue
            text = arm.blank_comments(arm.git("show", f"{ref}:{path}"))
            for m in REWARD.finditer(text):
                g = re.search(r'\bgold\s*=\s*"([^"]*)"', m.group(0))
                out[(path, m.group(1))][ref] = g.group(1) if g else None
    return out


def short(path):
    return path.replace("modGhostMode/files/", "")


def unit_key(path, kind, name):
    p = path.replace("modGhostMode/", "")
    return f"{p}::definitions/items/item:{name}" if kind == "item" else f"{p}::reward:{name}"


def changes(items):
    """[(folder, name, path, category, m, l, v)] where legacy changed the price or the price tags."""
    out = []
    for (folder, name), refs in sorted(items.items()):
        if "legacy-GM" not in refs:
            continue
        l = refs["legacy-GM"]
        m = refs.get("vanilla-1.32")
        v = refs.get("vanilla-5.x")
        if m and (num(m[1]) == num(l[1]) and m[3] == l[3]):
            continue
        out.append((folder, name, l[0], l[2], m, l, v))
    return out


def summary(items, rewards):
    ch = changes(items)
    by = collections.defaultdict(list)
    for c in ch:
        by[(c[0], short(c[2]), c[3])].append(c)
    print("Item price and price-tag changes by legacy (vanilla-1.32 -> legacy-GM), regular and NG+ folders\n")
    print("folder | file | category | items | price changed (up/down) | median legacy/1.32 | new items | tag changes | 5.x changed the 1.32 price")
    tot = collections.Counter()
    for (folder, path, cat), cs in sorted(by.items()):
        pc = [c for c in cs if c[4] and num(c[4][1]) != num(c[5][1])]
        up = sum(1 for c in pc if (num(c[5][1]) or 0) > (num(c[4][1]) or 0))
        ratios = [num(c[5][1]) / num(c[4][1]) for c in pc if num(c[4][1]) and num(c[5][1]) is not None]
        med = f"{statistics.median(ratios):.2f}" if ratios else "-"
        new = sum(1 for c in cs if not c[4])
        tags = sum(1 for c in cs if c[4] and c[4][3] != c[5][3])
        v5 = sum(1 for c in pc if c[6] and num(c[6][1]) != num(c[4][1]))
        print(f"{folder} | {path} | {cat} | {len(cs)} | {len(pc)} ({up}/{len(pc) - up}) | {med} | {new} | {tags} | {v5}")
        tot.update(items=len(cs), price=len(pc), new=new, tags=tags, v5=v5)
    print(f"\nTotal: {tot['items']} entries; price changed {tot['price']}, new {tot['new']}, tags {tot['tags']}, "
          f"5.x changed the same price {tot['v5']}")
    # 5.x's own price changes on items legacy did not touch
    touched = {(c[0], c[1]) for c in ch}
    v5only = [(k, r) for k, r in items.items() if k not in touched and "vanilla-1.32" in r and "vanilla-5.x" in r
              and num(r["vanilla-1.32"][1]) != num(r["vanilla-5.x"][1])]
    new5 = [(k, r) for k, r in items.items() if "vanilla-1.32" not in r and "vanilla-5.x" in r and "legacy-GM" not in r]
    print(f"5.x changed the price of {len(v5only)} items legacy left alone; 5.x added {len(new5)} items "
          f"({sum(1 for k, _ in new5 if k[0] == 'items')} regular)")
    rg = [(k, r) for k, r in rewards.items() if "legacy-GM" in r and r.get("vanilla-1.32") is not None and num(r["vanilla-1.32"]) != num(r["legacy-GM"])]
    rv = [(k, r) for k, r in rewards.items() if r.get("vanilla-1.32") is not None and "vanilla-5.x" in r and num(r["vanilla-1.32"]) != num(r["vanilla-5.x"])]
    gm = sum(num(r["vanilla-1.32"]) or 0 for k, r in rg)
    gl = sum(num(r["legacy-GM"]) or 0 for k, r in rg)
    print(f"Rewards: legacy changed the gold of {len(rg)} rewards ({gm:.0f} -> {gl:.0f} crowns over those); "
          f"5.x changed the gold of {len(rv)}; new in legacy: "
          f"{sum(1 for k, r in rewards.items() if 'legacy-GM' in r and 'vanilla-1.32' not in r)}")
    allm = sum(num(r.get("vanilla-1.32")) or 0 for r in rewards.values() if "vanilla-1.32" in r)
    alll = sum(num(r.get("legacy-GM")) or 0 for r in rewards.values() if "legacy-GM" in r)
    allv = sum(num(r.get("vanilla-5.x")) or 0 for r in rewards.values() if "vanilla-5.x" in r)
    print(f"All reward gold: 1.32 {allm:.0f}, legacy {alll:.0f}, 5.x {allv:.0f}")


def fmt(t):
    return f"{t[1]} {','.join(t[3]) or '-'}" if t else "-"


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--items", nargs="?", const="", default=None)
    ap.add_argument("--rewards", action="store_true")
    ap.add_argument("--tags", action="store_true")
    ap.add_argument("--units", action="store_true")
    a = ap.parse_args()
    items = load_items()
    rewards = load_rewards() if (a.rewards or a.units or a.items is None and not a.tags) else {}
    if a.items is not None:
        for folder, name, path, cat, m, l, v in changes(items):
            if a.items and not re.search(a.items, name, re.I):
                continue
            print(f"{folder} | {short(path)} | {cat} | {name} | 1.32 {fmt(m)} | legacy {fmt(l)} | 5.x {fmt(v)}")
    elif a.rewards:
        for (path, name), r in sorted(rewards.items()):
            m, l, v = r.get("vanilla-1.32"), r.get("legacy-GM"), r.get("vanilla-5.x")
            if num(m) != num(l) or num(m) != num(v):
                print(f"{short(path)} | {name} | 1.32 {m} | legacy {l} | 5.x {v}")
    elif a.tags:
        cnt = collections.Counter()
        for folder, name, path, cat, m, l, v in changes(items):
            if m and m[3] != l[3]:
                add, rem = set(l[3]) - set(m[3]), set(m[3]) - set(l[3])
                cnt.update(f"+{t}" for t in add)
                cnt.update(f"-{t}" for t in rem)
                print(f"{folder} | {short(path)} | {cat} | {name} | {' '.join(sorted('+' + t for t in add) + sorted('-' + t for t in rem))} | 5.x {','.join(v[3]) if v else '-'}")
        print(cnt.most_common())
    elif a.units:
        for folder, name, path, cat, m, l, v in changes(items):
            print(unit_key(path, "item", name))
        for (path, name), r in sorted(rewards.items()):
            if "legacy-GM" in r and num(r.get("vanilla-1.32")) != num(r["legacy-GM"]):
                print(unit_key(path, "reward", name))
    else:
        summary(items, rewards)


if __name__ == "__main__":
    main()
