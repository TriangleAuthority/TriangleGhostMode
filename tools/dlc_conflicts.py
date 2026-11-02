"""Guard: every entry of Ghost Mode's DLC that redefines a name 5.x already defines carries `on_conflict`.

A DLC `<item>`, `<ability>` or `<item_extension>` entry without `on_conflict` on a name 5.x defines is
ignored by the game, which keeps 5.x's entry, with no error in the script log (verified, ECON audit
2026-11-01: `Jar of Honey`; docs/development.md, "Fine-grained XML overrides"). This lists every such entry in
every XML file of the DLC's definition folders (`abilities`, `items` and their `_plus` twins), whichever
tool wrote it. A name counts as 5.x's when `vanilla-5.x` defines an entry of the same kind under
`gameplay/abilities/` or `gameplay/items/` (the `_plus` folders for the `_plus` DLC folders): the game's
definitions manager holds one table per kind, whatever the folder.

    python tools/dlc_conflicts.py [--worktree DIR]

Exits 1 when an entry lacks the attribute. `gen_econ.py --verify` runs the same check (`missing()`).
"""
import argparse, os, re, sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import gen_arm_items as arm  # noqa: E402

FOLDERS = ("abilities", "items", "abilities_plus", "items_plus")
KINDS = ("item", "ability", "item_extension")
OPEN = re.compile(r'<(ability|item_extension)\b([^>]*?)/?>', re.S)
NAME = re.compile(r'\bname\s*=\s*"([^"]+)"')
_V5 = {}


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


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--worktree", default=os.path.join(arm.REPO, "..", "TGM-5x-GM"))
    args = ap.parse_args()
    bad = missing(args.worktree)
    for b in bad:
        print("NO on_conflict " + b)
    print(f"{len(bad)} DLC entries without on_conflict on a name 5.x defines")
    sys.exit(1 if bad else 0)


if __name__ == "__main__":
    main()
