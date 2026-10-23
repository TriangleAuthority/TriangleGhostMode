"""Generate LOOT's loot lists and quest rewards as whole-file overrides (docs/features/loot.md).

Ghost Mode ships its own copy of each loot and reward file it changes (the owner's DT1, 2026-10-21: a
DLC override if it works, else whole files; no DLC override of `<loot>` is known to work, so whole files):
5.x's file (`vanilla-5.x`) with legacy's entries (`legacy-GM`) for every list and reward unit
`docs/features/attribution.csv` gives LOOT features that are all ported (`PORTED`); every other line stays
5.x's (5.x's own lists, e.g. its new gear's, DT3). Rules:

- a loot list legacy changed: legacy's entries; its opening tag (the list's attributes) legacy's where
  legacy changed it, else 5.x's (DT8: 5.x's `respawn_time` on the quest lists);
- a list legacy added: legacy's, appended to its file;
- a quest reward: 5.x's entry with legacy's `<items>` (LOOT-07, DT4); its experience, level and gold
  stay 5.x's (XP, ECON).

    python tools/gen_loot.py [--worktree DIR] [--check | --verify]

Writes the files at their vanilla paths under `modGhostMode/files/` in the 5.x-GM worktree (default
../TGM-5x-GM). --check fails if a file is out of date. --verify reads the written files and checks every
LOOT unit's entry against legacy's (ported) or 5.x's (not yet ported, counted), no name defined twice,
and the rest of each file 5.x's.
"""
import argparse, csv, os, re, struct, subprocess, sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

# The features whose lists and rewards are ported (loot.md's port order).
PORTED = {"LOOT-01", "LOOT-02", "LOOT-03", "LOOT-04", "LOOT-05", "LOOT-06", "LOOT-07", "LOOT-08", "CRAFT-10"}

UNIT = re.compile(r'^(.*\.xml)::(?:definitions/loot_definitions/(loot)|(reward)):(.+)$')
ENTRY = {
    "loot": re.compile(r'<loot\s[^>]*?/>|<loot\s[^>]*?>.*?</loot>', re.S),
    "reward": re.compile(r'<reward\s[^>]*?/>|<reward\s[^>]*?>.*?</reward>', re.S),
}
CLOSE = {"loot": "</loot_definitions>", "reward": "</redxml>"}


def git(*args):
    return subprocess.run(["git", "-C", REPO, *args], capture_output=True, check=True).stdout.decode("utf-8-sig", errors="replace")


def git_bytes(*args):
    return subprocess.run(["git", "-C", REPO, *args], capture_output=True, check=True).stdout


def units():
    """{path: {(kind, name): features}} of the loot list and reward units with a LOOT feature."""
    out = {}
    with open(os.path.join(REPO, "docs", "features", "attribution.csv"), encoding="utf-8") as f:
        for row in csv.DictReader(f):
            m = UNIT.match(row["unit"])
            feats = set(row["features"].split())
            if m and any(x.startswith("LOOT-") for x in feats):
                out.setdefault("modGhostMode/" + m.group(1), {})[(m.group(2) or m.group(3), m.group(4))] = feats
    return out


def area(feats):
    return {x for x in feats if x.startswith(("LOOT-", "CRAFT-"))}


def wanted(feats):
    return area(feats) <= PORTED


def blank_comments(text):
    return re.sub(r'<!--.*?-->', lambda m: " " * len(m.group(0)), text, flags=re.S)


def entries(text):
    """{(kind, name): (start, end)} of every loot list and reward (comments ignored); [names twice]."""
    out, dup = {}, []
    blank = blank_comments(text)
    for kind, rx in ENTRY.items():
        for m in rx.finditer(blank):
            n = re.search(r'\bname\s*=\s*"([^"]+)"', m.group(0))
            if n:
                key = (kind, n.group(1))
                if key in out:
                    dup.append(key)
                out[key] = (m.start(), m.end())
    return out, dup


def norm(text):
    return " ".join(text.split()) if text is not None else None


def head(entry):
    return re.match(r'<\w+\s[^>]*?/?>', entry, re.S).group(0)


def body(entry):
    """The children of an entry ('' for a self-closing one)."""
    h = head(entry)
    if h.endswith("/>"):
        return ""
    return entry[len(h):entry.rindex("</")]


def items_block(entry):
    m = re.search(r'<items>.*?</items>', body(entry), re.S)
    return m.group(0) if m else None


_KNOWN = None


def known_items():
    """Every item name the game defines: 5.x's items and Ghost Mode's DLC items (both folders)."""
    global _KNOWN
    if _KNOWN is None:
        sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
        import gen_arm_items as arm
        _KNOWN = set()
        for folder in ("items", "items_plus"):
            _KNOWN |= set(arm.items("vanilla-5.x", folder)) | set(arm.dlc_entries(WORKTREE[0], folder)[0])
            for path in arm.git("ls-tree", "-r", "--name-only", "vanilla-5.x").splitlines():
                if re.search(rf"/gameplay/{folder}/[^/]+\.xml$", path):
                    _KNOWN |= set(re.findall(r'<item\s[^>]*?name\s*=\s*"([^"]+)"', git("show", f"vanilla-5.x:{path}")))
    return _KNOWN


WORKTREE = [os.path.join(REPO, "..", "TGM-5x-GM")]
# Entries naming items no definition has yet: FOOD's new cooking recipes (innkeepers and butchers sell
# them in legacy), left out until FOOD defines them (temporary deviation, loot.md LOOT-01).
PENDING = re.compile(r'^Recipe for ')


def drop_unknown(entry):
    """`entry` without the loot entries of items not defined yet (PENDING); [names dropped]."""
    dropped = []

    def keep(m):
        n = re.search(r'\bname\s*=\s*"([^"]+)"', m.group(0))
        n = n.group(1) if n else ""
        if not n or n in known_items() or not PENDING.match(n):
            return m.group(0)
        dropped.append(n)
        return ""
    entry = re.sub(r'[ \t]*<loot_entry\s[^>]*?/>[ \t]*\n?', keep, entry)
    return entry, dropped


ATTR = re.compile(r'(\b\w+)(\s*=\s*")([^"]*)(")')


def head_merged(mh, lh, vh):
    """5.x's opening tag `vh` with the attributes legacy's `lh` changed against 1.32's `mh` (every
    occurrence: 5.x's quest list tags repeat `player_level_min` and `player_level_max`); an attribute
    legacy added is appended, one it removed is removed."""
    attrs = lambda h: {a: v for a, _, v, _ in ATTR.findall(h)}
    ma, la = attrs(mh), attrs(lh)
    changed = {a: la.get(a) for a in set(ma) | set(la) if ma.get(a) != la.get(a)}
    for a, val in changed.items():
        if val is None:
            vh = re.sub(rf'\s+{a}\s*=\s*"[^"]*"', '', vh)
        elif re.search(rf'\b{a}\s*=', vh):
            vh = re.sub(rf'(\b{a}\s*=\s*")[^"]*(")', lambda m: m.group(1) + val + m.group(2), vh)
        else:
            end = len(vh) - (2 if vh.endswith("/>") else 1)
            vh = vh[:end].rstrip() + f' {a}="{val}"' + vh[end:]
    return vh


def merged(kind, ment, lent, vent):
    """The final entry of a ported unit."""
    if kind == "loot":
        if vent is None:
            return drop_unknown(lent)[0]  # a list legacy added
        # DT8: 5.x's list attributes, with only the ones legacy changed against 1.32 (CRAFT/LOOT audit F4)
        h = head_merged(head(ment), head(lent), head(vent)) if ment is not None else head(lent)
        if h.endswith("/>"):
            h = h[:-2].rstrip() + ">"
        return drop_unknown(h + body(lent) + "</loot>")[0]
    # reward: 5.x's with legacy's <items>
    if vent is None:
        return lent
    li = items_block(lent)
    vh = head(vent)
    if vh.endswith("/>"):
        vh = vh[:-2].rstrip() + " >"
    rest = re.sub(r'\s*<items>.*?</items>', '', body(vent), flags=re.S).rstrip()
    inner = rest + ("\n\t\t" + li + "\n\t" if li else "")
    if not inner.strip():
        h = head(vent)
        return h if h.endswith("/>") else h[:-1].rstrip() + " />"
    return vh + inner + "</reward>"


def texts(path):
    def show(ref):
        try:
            return git("show", f"{ref}:{path}").replace("\r\n", "\n")
        except subprocess.CalledProcessError:
            return None
    return show("master"), show("legacy-GM"), show("vanilla-5.x")


def generate(path, us):
    mtext, ltext, vtext = texts(path)
    me, le, ve = (entries(t)[0] if t else {} for t in (mtext, ltext, vtext))
    get = lambda text, ents, key: text[ents[key][0]:ents[key][1]] if key in ents else None
    edits, adds, report = [], [], []
    for key, feats in sorted(us.items()):
        if not wanted(feats):
            continue
        lent, ment, vent = get(ltext, le, key), get(mtext, me, key), get(vtext, ve, key)
        if lent is None:
            if vent is not None:
                report.append(f"{key[0]} {key[1]}: legacy has none, 5.x's kept")
            continue
        new = merged(key[0], ment, lent, vent)
        dropped = drop_unknown(lent)[1] if key[0] == "loot" else []
        if dropped:
            report.append(f"{key[0]} {key[1]}: left out until FOOD: {', '.join(dropped)}")
        if vent is None:
            adds.append((key[0], new))
            report.append(f"{key[0]} {key[1]}: new")
        elif norm(new) != norm(vent):
            edits.append((ve[key][0], ve[key][1], new))
            report.append(f"{key[0]} {key[1]}")
    text = vtext
    for s, e, new in sorted(edits, reverse=True):
        text = text[:s] + new + text[e:]
    for kind, new in adds:
        close = text.rindex(CLOSE[kind])
        line = text.rfind("\n", 0, close) + 1
        text = text[:line] + "\t" + new.strip() + "\n" + text[line:]
    return text, report


def expected(kind, ment, lent, vent):
    return norm(merged(kind, ment, lent, vent)) if lent is not None else norm(vent)


def verify(worktree, us_all):
    problems, counts = [], {}
    for path, us in sorted(us_all.items()):
        mtext, ltext, vtext = texts(path)
        if vtext is None:
            problems.append(f"{path}: not in 5.x")
            continue
        dst = os.path.join(worktree, path)
        final = open(dst, encoding="utf-8-sig").read().replace("\r\n", "\n") if os.path.exists(dst) else vtext
        fe, dup = entries(final)
        me, le, ve = (entries(t)[0] if t else {} for t in (mtext, ltext, vtext))
        get = lambda text, ents, key: text[ents[key][0]:ents[key][1]] if key in ents else None
        problems += [f"{path}: {k[0]} {k[1]} defined twice" for k in dup if k in us or k not in entries(vtext)[1]]
        for key, feats in sorted(us.items()):
            f, l, v, m = get(final, fe, key), get(ltext, le, key), get(vtext, ve, key), get(mtext, me, key)
            if wanted(feats):
                if norm(f) == expected(key[0], m, l, v):
                    r = "legacy's" if l is not None else "legacy has none, 5.x's"
                    counts[r] = counts.get(r, 0) + 1
                else:
                    problems.append(f"{path}: {key[0]} {key[1]} ({' '.join(sorted(feats))}) not legacy's")
            elif norm(f) == norm(v):
                r = f"{', '.join(sorted(area(feats) - PORTED))}: not ported yet"
                counts[r] = counts.get(r, 0) + 1
            else:
                problems.append(f"{path}: {key[0]} {key[1]} changed before its features are ported")

        def rest(text, ents):
            for s, e in sorted((ents[k] for k in us if k in ents), reverse=True):
                text = text[:s] + text[e:]
            return norm(text)
        if rest(final, fe) != rest(vtext, ve):
            problems.append(f"{path}: outside LOOT's entries the file is not 5.x's")
    print("LOOT list and reward units by state:")
    for r, n in sorted(counts.items()):
        print(f"  {n:5d}  {r}")
    for p in problems:
        print("  UNEXPLAINED " + p)
    print(f"verify: {len(problems)} unexplained differences")
    return len(problems)


# ---- binary entity edits (QT1): LOOT-02, LOOT-06, LOOT-07's quest NPCs, CRAFT-01's Midcotts smith ----------

BIN_FEATURES = {"LOOT-02", "LOOT-06", "LOOT-07", "CRAFT-01"}
# The objects legacy's loot edits are in: the loot parameters, the craftsman, the inventory entries.
BIN_CLASSES = {"CR4LootParam", "W3CraftsmanComponent", "CInventoryDefinitionEntry", "CInventoryInitializerUniform"}
BIN_UNIT = re.compile(r'^(.*\.w2ent)::<file>$')


def bin_units():
    """{path: features} of the binary entity files with a LOOT or CRAFT-01 edit."""
    out = {}
    with open(os.path.join(REPO, "docs", "features", "attribution.csv"), encoding="utf-8") as f:
        for row in csv.DictReader(f):
            m = BIN_UNIT.match(row["unit"])
            feats = set(row["features"].split())
            if m and feats & BIN_FEATURES:
                out["modGhostMode/" + m.group(1)] = feats
    return out


class Blobs:
    """Reads many files from git refs through one `git cat-file --batch`."""

    def __init__(self):
        self.p = subprocess.Popen(["git", "-C", REPO, "cat-file", "--batch"], stdin=subprocess.PIPE, stdout=subprocess.PIPE)

    def get(self, ref, path):
        self.p.stdin.write(f"{ref}:{path}\n".encode())
        self.p.stdin.flush()
        header = self.p.stdout.readline().split()
        if header[-1] == b"missing":
            return None
        return self.p.stdout.read(int(header[2]) + 1)[:-1]


def bin_chunks(data, where="", out=None):
    """{(where, class, n): (chunk bytes, file object)} of every chunk of a CR2W file and of the files
    embedded in it (`where`: the byte-array property's name, '' for the file itself)."""
    import cr2w_patch as cp
    out = {} if out is None else out
    fo = cp.File(data, readonly=True)
    n = {}
    for i, cls in enumerate(fo.classes):
        k = n[cls] = n.get(cls, -1) + 1
        d = fo.chunks[i]
        out[(where, cls, k)] = (d, fo)
        pl, _ = cp.parse_list(d, 0, len(d), chunk=True)
        for ni, ti, v in pl[1]:
            t = fo.name(ti)
            if t.startswith("array:") and t.endswith(",Uint8") and v[4:8] == b"CR2W":
                bin_chunks(v[4:], where + "/" + fo.name(ni), out)
    return out


def bin_value(fo, t, v):
    """A property value as (type, Python value): scalars decoded, arrays as tuples, structs as tuples of
    (field, (type, value)); pointers as 'ptr' (chunk numbers differ between versions)."""
    import cr2w_patch as cp
    it = cp.inner_type(t)
    if it is not None and not t.endswith(",Uint8"):
        elems, _ = cp.parse_array(v, it)
        return t, tuple(bin_value(fo, it, e)[1] for e in elems)
    if t.startswith(("ptr:", "handle:")):
        return t, "ptr"
    x = cp.decode(fo, t, v)
    if x is not None:
        return t, (round(x, 4) if isinstance(x, float) else x)
    if t == "TagList":
        return t, tuple(fo.name(struct.unpack_from("<H", v, 1 + 2 * i)[0]) for i in range(v[0]))
    if t in ("String", "StringAnsi", "CGUID", "LocalizedString"):
        return t, v.hex()
    try:
        pl, _ = cp.parse_list(v, 0, len(v))
        return t, tuple((fo.name(ni), bin_value(fo, fo.name(ti), vv)) for ni, ti, vv in pl[1])
    except ValueError:
        return t, v.hex()


def without_embedded(d, fo):
    """A chunk's bytes with its embedded CR2W files left out (they are compared object by object)."""
    import cr2w_patch as cp
    pl, _ = cp.parse_list(d, 0, len(d), chunk=True)
    for p in pl[1]:
        if fo.name(p[1]).endswith(",Uint8") and p[2][4:8] == b"CR2W":
            p[2] = b"embedded"
    return cp.build_list(pl)


def bin_decoded(d, fo):
    """A chunk's properties as an ordered tuple of (name, (type, value))."""
    import cr2w_patch as cp
    pl, _ = cp.parse_list(d, 0, len(d), chunk=True)
    return tuple((fo.name(ni), bin_value(fo, fo.name(ti), v)) for ni, ti, v in pl[1])


def fmt(x):
    if isinstance(x, bool):
        return "true" if x else "false"
    if isinstance(x, float):
        return repr(float(x))
    return str(x)


def fields_spec(elem, typed):
    return ",".join(f"{k}:{t}={fmt(x)}" if typed else f"{k}={fmt(x)}" for k, (t, x) in elem)


def derive_ops(cls, n, mprops, lprops):
    """cr2w_patch edits that turn the chunk `mprops` (1.32's) into `lprops` (legacy's)."""
    ops = []
    m, l = dict(mprops), dict(lprops)
    target = f"{cls}#{n}"
    for name, (t, mv) in mprops:
        if name not in l:
            ops.append(f"{target}.{name}-=*" if isinstance(mv, tuple) else f"{target}.{name}-={fmt(mv)}")
            continue
        lt, lv = l[name]
        if lv == mv:
            continue
        if not isinstance(mv, tuple):
            ops.append(f"{target}.{name}={fmt(mv)}:{fmt(lv)}")
            continue
        removed = [(i, e) for i, e in enumerate(mv) if e not in lv]
        added = [(i, e) for i, e in enumerate(lv) if e not in mv]
        for (ri, r), (ai, a) in [(r, a) for r in removed for a in added if r[0] == a[0]]:
            rd, ad = dict(r), dict(a)
            if set(rd) != set(ad):
                continue
            same = [(k, rd[k]) for k, _ in r if rd[k] == ad[k]]
            sel = f"[{fields_spec(same, False)}]" if same else ""
            for k, (ft, x) in r:
                if ad[k] != (ft, x):
                    ops.append(f"{target}.{name}{sel}.{k}={fmt(x)}:{fmt(ad[k][1])}")
            removed.remove((ri, r))
            added.remove((ai, a))
        for _, r in removed:
            ops.append(f"{target}.{name}-={fields_spec(r, False)}")
        for _, a in added:
            ops.append(f"{target}.{name}+={fields_spec(a, True)}")
    for name, (t, lv) in lprops:
        if name not in m:
            if isinstance(lv, tuple):
                raise SystemExit(f"{target}.{name}: adding an array property is not supported")
            ops.append(f"{target}.{name}:{t}+={fmt(lv)}")
    return ops


def bin_plan(blobs, path):
    """(ops, touched chunk keys, conflicts) for one file: the edits legacy made to 1.32's loot objects."""
    m, l, v = (bin_chunks(blobs.get(r, path)) for r in ("master", "legacy-GM", "vanilla-5.x"))
    ops, touched, conflicts = [], set(), []
    for key in sorted(set(m) | set(l)):
        if key[1] not in BIN_CLASSES:
            continue
        if key not in m or key not in l:
            raise SystemExit(f"{path}: {key} only in {'legacy' if key in l else '1.32'}")
        md, ld = bin_decoded(*m[key]), bin_decoded(*l[key])
        if md == ld:
            continue
        if key not in v or bin_decoded(*v[key]) != md:
            conflicts.append(key)
            continue
        touched.add(key)
        for op in derive_ops(key[1], key[2], md, ld):
            if op not in ops:
                ops.append(op)
    return ops, touched, conflicts


def bin_expected(blobs, path):
    import cr2w_patch as cp
    ops, touched, conflicts = bin_plan(blobs, path)
    out, changes, hit = cp.apply(blobs.get("vanilla-5.x", path), [cp.Op(o) for o in ops])
    missing = [o for k, o in enumerate(ops) if k not in hit]
    return out, ops, changes, missing, touched, conflicts


def bin_generate(worktree, check):
    blobs, stale = Blobs(), []
    for path, feats in sorted(bin_units().items()):
        out, ops, changes, missing, touched, conflicts = bin_expected(blobs, path)
        if missing or conflicts:
            sys.exit(f"{path}: edits matching nothing {missing}, 5.x changed {conflicts}")
        dst = os.path.join(worktree, path)
        if open(dst, "rb").read() != out:
            stale.append(path)
            if not check:
                with open(dst, "wb") as f:
                    f.write(out)
    print(f"binary entity files: {len(bin_units())}, {len(stale)} {'out of date' if check else 'written'}")
    return stale


def bin_verify(worktree):
    """Every binary file is 5.x's with exactly legacy's loot edits: the bytes equal 5.x's file with the derived
    edits applied (every edit matching), the CRCs are valid, every chunk outside the edited loot objects is
    5.x's byte for byte (the file's and its compiled copy's), and every edited object reads as legacy's."""
    import cr2w_patch as cp
    blobs, problems, counts = Blobs(), [], {}
    nops = 0
    for path, feats in sorted(bin_units().items()):
        port = open(os.path.join(worktree, path), "rb").read()
        out, ops, changes, missing, touched, conflicts = bin_expected(blobs, path)
        nops += len(ops)
        bad = []
        if port != out:
            bad.append("not 5.x's file with the edits")
        if missing:
            bad.append(f"edits matching nothing: {missing}")
        if conflicts:
            bad.append(f"5.x changed legacy's objects: {conflicts}")
        if not cp.check_crcs(port):
            bad.append("CRCs invalid")
        g, v, l = bin_chunks(port), bin_chunks(blobs.get("vanilla-5.x", path)), bin_chunks(blobs.get("legacy-GM", path))
        if set(g) != set(v):
            bad.append("objects differ from 5.x's")
        for key in sorted(set(g) & set(v)):
            if key in touched:
                if bin_decoded(*g[key]) != bin_decoded(*l[key]):
                    bad.append(f"{key} does not read as legacy's")
            elif g[key][0] != v[key][0] and without_embedded(*g[key]) != without_embedded(*v[key]):
                bad.append(f"{key} differs from 5.x's")
        if not touched:
            bad.append("no loot edit found")
        kinds = sorted(f for f in feats if f in BIN_FEATURES)
        r = f"{' '.join(kinds)}: 5.x's with legacy's edits"
        counts[r] = counts.get(r, 0) + 1
        problems += [f"{path}: {b}" for b in bad]
    print("binary entity files by feature:")
    for r, n in sorted(counts.items()):
        print(f"  {n:5d}  {r}")
    print(f"  {nops} edits in all")
    for p in problems:
        print("  UNEXPLAINED " + p)
    print(f"verify (binary): {len(problems)} unexplained differences")
    return len(problems)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--worktree", default=os.path.join(REPO, "..", "TGM-5x-GM"))
    ap.add_argument("--check", action="store_true")
    ap.add_argument("--verify", action="store_true")
    args = ap.parse_args()
    WORKTREE[0] = args.worktree
    us_all = units()
    if args.verify:
        bad = verify(args.worktree, us_all)
        bad += bin_verify(args.worktree)
        sys.exit(1 if bad else 0)
    stale = bin_generate(args.worktree, args.check)
    for path, us in sorted(us_all.items()):
        text, report = generate(path, us)
        vtext = texts(path)[2]
        dst = os.path.join(args.worktree, path)
        old = open(dst, encoding="utf-8", newline="").read() if os.path.exists(dst) else None
        if text == vtext:
            if old is not None and norm(old.lstrip("﻿")) != norm(vtext):
                stale.append(path)
                if not args.check:
                    subprocess.run(["git", "-C", args.worktree, "checkout", "vanilla-5.x", "--", path], check=True)
            continue
        print(f"{path}: {len(report)} entries")
        for r in report:
            if "left out" in r:
                print("  " + r)
        bom = git_bytes("show", f"vanilla-5.x:{path}").startswith(b"\xef\xbb\xbf")
        new = ("﻿" if bom else "") + text.replace("\n", "\r\n")
        if old != new:
            stale.append(path)
            if not args.check:
                with open(dst, "w", encoding="utf-8", newline="") as f:
                    f.write(new)
    if args.check and stale:
        sys.exit("out of date: " + ", ".join(stale) + ": run python tools/gen_loot.py")


if __name__ == "__main__":
    main()
