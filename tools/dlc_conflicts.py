"""Guards on Ghost Mode's DLC definitions: overrides carry `on_conflict`, and item abilities exist.

1. Every entry of the DLC that redefines a name 5.x already defines carries `on_conflict`.

A DLC `<item>`, `<ability>` or `<item_extension>` entry without `on_conflict` on a name 5.x defines is
ignored by the game, which keeps 5.x's entry, with no error in the script log (verified, ECON audit
2026-11-01: `Jar of Honey`; docs/development.md, "Fine-grained XML overrides"). This lists every such entry in
every XML file of the DLC's definition folders (`abilities`, `items` and their `_plus` twins), whichever
tool wrote it. A name counts as 5.x's when `vanilla-5.x` defines an entry of the same kind under
`gameplay/abilities/` or `gameplay/items/` (the `_plus` folders for the `_plus` DLC folders): the game's
definitions manager holds one table per kind, whatever the folder.

2. Every ability a DLC item names (`<a>` in `<base_abilities>`, variants included) is defined: by an
`<ability>` of 5.x's or the DLC's definition folders of the same game (`items`/`abilities` for a regular
item, `items_plus`/`abilities_plus` for an NG+ one). The game gives an item no ability for a name nobody
defines, silently (ARM-12's NG+ pieces lacked their 16 `Base Kaer Morhen ... _Stats`, 2026-11-02). A
reference that 5.x's own entry of the same item also makes is 5.x's gap, listed but not failed; an NG+
reference defined only in the regular folders is listed as such (whether NG+ also reads the regular
folders is not known) and fails too.

    python tools/dlc_conflicts.py --worktree DIR

Exits 1 when an entry lacks the attribute or an item names an undefined ability. `gen_econ.py --verify`
runs the first check (`missing()`).
"""
import argparse, os, re, sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import gen_arm_items as arm  # noqa: E402
import paths  # noqa: E402  (tools/: the shared --worktree argument)

FOLDERS = ("abilities", "items", "abilities_plus", "items_plus")
KINDS = ("item", "ability", "item_extension")
OPEN = re.compile(r'<(ability|item_extension)\b([^>]*?)/?>', re.S)
NAME = re.compile(r'\bname\s*=\s*"([^"]+)"')
A_REF = re.compile(r'<a\b[^>]*>\s*([^<]*?)\s*</a>')
_V5 = {}
_V5_REFS = {}


def entries(text):
    """(kind, name, opening tag) of every top-level item, every ability and every item extension of a file."""
    text = arm.blank_comments(text)
    for _, _, head in arm.item_spans(text):
        n = NAME.search(head)
        if n:
            yield "item", n.group(1), head
    for m in OPEN.finditer(text):
        n = NAME.search(m.group(2))
        if n:
            yield m.group(1), n.group(1), m.group(0)


def vanilla_names(plus):
    """{kind: set of names} 5.x defines in its regular (or NG+) definition folders, Ghost Mode's DLC excluded."""
    if plus not in _V5:
        want = re.compile(r"/gameplay/(?:abilities|items)%s/[^/]+\.xml$" % ("_plus" if plus else ""))
        out = {k: set() for k in KINDS}
        for path in arm.git("ls-tree", "-r", "--name-only", "vanilla-5.x").splitlines():
            if want.search(path) and "dlcghostmode" not in path:
                for kind, name, _ in entries(arm.git("show", f"vanilla-5.x:{path}")):
                    out[kind].add(name)
        _V5[plus] = out
    return _V5[plus]


def missing(worktree):
    """'folder/file: kind name' for every DLC entry without `on_conflict` on a name 5.x defines."""
    out = []
    for folder in FOLDERS:
        d = os.path.join(worktree, arm.DLC, folder)
        if not os.path.isdir(d):
            continue
        names = vanilla_names(folder.endswith("_plus"))
        for f in sorted(os.listdir(d)):
            if not f.endswith(".xml"):
                continue
            for kind, name, head in entries(open(os.path.join(d, f), encoding="utf-8-sig").read()):
                if name in names[kind] and not re.search(r'\bon_conflict\s*=', head):
                    out.append(f"{folder}/{f}: {kind} {name}")
    return out


def item_refs(text):
    """(item name, set of ability names its <a> nodes name) of every top-level item of a file."""
    text = arm.blank_comments(text)
    for start, end, head in arm.item_spans(text):
        n = NAME.search(head)
        if n:
            yield n.group(1), set(A_REF.findall(text[start:end]))


def vanilla_refs(plus):
    """{item name: set of ability names} of 5.x's items in its regular (or NG+) item folders."""
    if plus not in _V5_REFS:
        want = re.compile(r"/gameplay/items%s/[^/]+\.xml$" % ("_plus" if plus else ""))
        out = {}
        for path in arm.git("ls-tree", "-r", "--name-only", "vanilla-5.x").splitlines():
            if want.search(path) and "dlcghostmode" not in path:
                for name, refs in item_refs(arm.git("show", f"vanilla-5.x:{path}")):
                    out.setdefault(name, set()).update(refs)
        _V5_REFS[plus] = out
    return _V5_REFS[plus]


def dlc_abilities(worktree, plus):
    """Names of every ability the DLC's regular (or NG+) definition folders define."""
    out = set()
    for folder in FOLDERS:
        d = os.path.join(worktree, arm.DLC, folder)
        if folder.endswith("_plus") != plus or not os.path.isdir(d):
            continue
        for f in os.listdir(d):
            if f.endswith(".xml"):
                out |= {n for k, n, _ in entries(open(os.path.join(d, f), encoding="utf-8-sig").read()) if k == "ability"}
    return out


def undefined(worktree):
    """(failing, inherited) lists of 'folder/file: item -> ability (why)' for item abilities nobody defines."""
    bad, inherited = [], []
    defined = {p: vanilla_names(p)["ability"] | dlc_abilities(worktree, p) for p in (False, True)}
    for folder in ("items", "items_plus"):
        plus = folder.endswith("_plus")
        d = os.path.join(worktree, arm.DLC, folder)
        if not os.path.isdir(d):
            continue
        v5 = vanilla_refs(plus)
        for f in sorted(os.listdir(d)):
            if not f.endswith(".xml"):
                continue
            for item, refs in item_refs(open(os.path.join(d, f), encoding="utf-8-sig").read()):
                for a in sorted(refs - defined[plus]):
                    why = "defined only in the regular folders" if plus and a in defined[False] else "defined nowhere"
                    line = f"{folder}/{f}: {item} -> {a} ({why})"
                    (inherited if a in v5.get(item, ()) else bad).append(line)
    return bad, inherited


def main():
    ap = argparse.ArgumentParser()
    paths.add_worktree(ap)  # required: parallel areas each pass their own worktree
    args = ap.parse_args()
    bad = missing(args.worktree)
    for b in bad:
        print("NO on_conflict " + b)
    print(f"{len(bad)} DLC entries without on_conflict on a name 5.x defines")
    undef, inherited = undefined(args.worktree)
    for u in undef:
        print("UNDEFINED ABILITY " + u)
    for u in inherited:
        print("undefined in 5.x too " + u)
    print(f"{len(undef)} DLC item abilities nobody defines ({len(inherited)} more as 5.x's own entries name them)")
    sys.exit(1 if bad or undef else 0)


if __name__ == "__main__":
    main()
