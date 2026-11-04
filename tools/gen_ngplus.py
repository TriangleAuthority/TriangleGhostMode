"""Generate the New Game+ copies of Ghost Mode's DLC ability XML.

The game reads NG+ definitions from `abilities_plus/` folders; a DLC mounts its own with a
CR4DefinitionsNGPlusDLCMounter (see docs/development.md, "DLC and mounters"). For every XML
file in the DLC's `abilities/` folder this writes a copy into `abilities_plus/`, with each
number scaled by the NG+ rule (docs/feature-mapping.md, "NG+ numbers"):

    GM NG+ = vanilla NG+ x (GM NG / vanilla NG)

where vanilla is 5.x (`vanilla-5.x`), GM NG the value in Ghost Mode's file, and vanilla NG / NG+
the same ability's node in vanilla's `abilities/` / `abilities_plus/` files (matched by tag,
`type` and order). Edge cases: vanilla NG and NG+ equal, a node or ability vanilla does not
have, or one missing from NG+: Ghost Mode's value as is (a new entry whose name vanilla defines only in its NG+
files gets on_conflict="replace" there); vanilla NG 0: the difference is added
(GM NG + vanilla NG+). Legacy behaviour first: where legacy Ghost Mode (`legacy-GM`) gave a node
the same value in NG and NG+ and Ghost Mode's value is that value, it is kept (legacy chose not to
scale it). The same holds for a shared skill's new-tree value that rescales legacy's to 3 levels: when the
classic tree's `GM_C_<skill>` (legacy's value, never scaled: vanilla has no such name) gives that node
legacy's value and legacy kept it in NG+, the new tree's value is kept too, so both trees keep legacy's
total (SKL-15's Pyrotechnics, whole-port audit A3-1). Comments and layout are kept. Prints every value that changes or is kept that way.

    python tools/gen_ngplus.py --worktree DIR [--check | --verify]

--worktree is required. --check writes nothing: it prints the report and fails if a copy
in `abilities_plus/` is missing or out of date. --verify reads the copies as written and fails if a
shared skill's two trees scale differently in NG+: for every node of a `GM_C_<skill>` ability, the new
tree's `<skill>` must keep the same NG+/NG ratio as the classic one (whole-port audit A3-1: the new tree's
Pyrotechnics doubled in NG+, the classic tree's did not). Re-run after changing any file in `abilities/`.
"""
import argparse, os, re, subprocess, sys
import paths  # noqa: E402  (tools/: the shared --worktree argument)

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DLC = "modGhostMode/files/dlc/dlcghostmode/data/gameplay/"
ABILITY = re.compile(r'(<ability\s+name\s*=\s*"([^"]+)"[^>]*>)(.*?)(</ability>)', re.S)
NODE = re.compile(r'<([A-Za-z_]\w*)\b([^>]*?)/>')
ATTR = re.compile(r'\b(min|max)="([^"]*)"')
TYPE = re.compile(r'\btype="([^"]*)"')


def git(*args):
    return subprocess.run(["git", *args], cwd=REPO, capture_output=True, check=True).stdout.decode("utf-8-sig", errors="replace")


def node_keys(body):
    """[(key, attrs, span)] for the value nodes of an ability body; key = (tag, type, occurrence)."""
    seen, out = {}, []
    for m in NODE.finditer(body):
        if body.rfind("<!--", 0, m.start()) > body.rfind("-->", 0, m.start()):
            continue  # inside a comment
        t = TYPE.search(m.group(2))
        base = (m.group(1), t.group(1) if t else "")
        seen[base] = seen.get(base, 0) + 1
        out.append((base + (seen[base],), m.group(2), m.span(2)))
    return out


def values(attrs):
    v = dict(ATTR.findall(attrs))
    v.setdefault("max", v.get("min"))
    return v


def vanilla_abilities(folder, ref="vanilla-5.x"):
    """{ability: {key: attrs}} from every <ref> <...>/gameplay/<folder>/*.xml."""
    out = {}
    for path in git("ls-tree", "-r", "--name-only", ref).splitlines():
        if re.search(rf"/gameplay/{folder}/[^/]+\.xml$", path):
            for m in ABILITY.finditer(git("show", f"{ref}:{path}")):
                out.setdefault(m.group(2), {k: a for k, a, _ in node_keys(m.group(3))})
    return out


def fmt(x, *samples):
    dec = max([len(s.split(".")[1]) if "." in s else 0 for s in samples] + [0])
    s = f"{x:.{max(dec, 3)}f}".rstrip("0").rstrip(".")
    return "0" if s in ("-0", "") else s


def scale(gm, ng, ngp):
    """The NG+ value for Ghost Mode's value gm, from vanilla's NG and NG+ values (strings or None)."""
    try:
        g = float(gm)
        n, p = float(ng), float(ngp)
    except (TypeError, ValueError):
        return gm
    if n == p:
        return gm
    if n == 0:
        return fmt(g + p, gm, ngp)
    return fmt(g * p / n, gm, ngp)


def same(*xs):
    try:
        return len({float(x) for x in xs}) == 1
    except (TypeError, ValueError):
        return False


def classic_values(folder):
    """{skill: {key: attrs}} of the classic tree's GM_C_<skill> abilities in Ghost Mode's DLC folder."""
    out = {}
    for name in sorted(os.listdir(folder)):
        if name.endswith(".xml"):
            with open(os.path.join(folder, name), encoding="utf-8-sig") as f:
                for m in ABILITY.finditer(f.read()):
                    if m.group(2).startswith("GM_C_"):
                        out.setdefault(m.group(2)[5:], {k: a for k, a, _ in node_keys(m.group(3))})
    return out


def convert(text, name, ng, ngp, lng, lngp, report, classic=None):
    def ability(m):
        a = m.group(2)
        head = m.group(1)
        if "on_conflict" not in head and a in ngp:
            # a new entry of the regular folder whose name 5.x defines only in its NG+ files (DIFF-02's variants)
            head = re.sub(r"\s*>$", ' on_conflict="replace">', head)
            report.append(f"{name}: {a} new in the regular folder, defined by vanilla NG+: replace")
        if a not in ng:
            return head + m.group(3) + m.group(4)
        if a not in ngp:
            report.append(f"{name}: {a} not in vanilla NG+, copied")
            return m.group(0)
        body, parts, last = m.group(3), [], 0
        for key, attrs, (s, e) in node_keys(body):
            nv, pv = values(ng[a].get(key, "")), values(ngp[a].get(key, ""))
            lv, lpv = values(lng.get(a, {}).get(key, "")), values(lngp.get(a, {}).get(key, ""))
            cv = values((classic or {}).get(a, {}).get(key, ""))
            def sub(am):
                at = am.group(1)
                new = scale(am.group(2), nv.get(at), pv.get(at))
                if new != am.group(2) and same(am.group(2), lv.get(at), lpv.get(at)):
                    report.append(f"{name}: {a}.{key[0]} ({key[1]}) {at} {am.group(2)} kept: legacy has it"
                                  f" in NG+ too (the rule would give {new})")
                    new = am.group(2)
                elif new != am.group(2) and same(cv.get(at), lv.get(at), lpv.get(at)):
                    report.append(f"{name}: {a}.{key[0]} ({key[1]}) {at} {am.group(2)} kept: the new tree's rescale of"
                                  f" legacy's {lv.get(at)} (GM_C_{a}), which legacy has in NG+ too (the rule would give {new})")
                    new = am.group(2)
                if new != am.group(2):
                    report.append(f"{name}: {a}.{key[0]} ({key[1]}) {am.group(1)} {am.group(2)} -> {new}"
                                  f" (vanilla {nv.get(am.group(1))} / NG+ {pv.get(am.group(1))})")
                return f'{am.group(1)}="{new}"'
            parts += [body[last:s], ATTR.sub(sub, attrs)]
            last = e
        parts.append(body[last:])
        return head + "".join(parts) + m.group(4)
    return ABILITY.sub(ability, text)


def dlc_abilities(folder):
    """{ability: {key: attrs}} of Ghost Mode's DLC folder, the last entry of a name winning per node."""
    out = {}
    for name in sorted(os.listdir(folder)):
        if name.endswith(".xml"):
            with open(os.path.join(folder, name), encoding="utf-8-sig") as f:
                for m in ABILITY.finditer(f.read()):
                    out.setdefault(m.group(2), {}).update({k: a for k, a, _ in node_keys(m.group(3))})
    return out


def verify(src, dst):
    """Both trees of each shared skill scale alike in NG+: [problems]."""
    ng, ngp, bad = dlc_abilities(src), dlc_abilities(dst), []
    for c in sorted(a for a in ng if a.startswith("GM_C_")):
        skill = c[5:]
        for key, attrs in ng.get(skill, {}).items():
            if key not in ng[c]:
                continue
            for at, v in ATTR.findall(attrs):
                cn, cp = values(ng[c][key]).get(at), values(ngp.get(c, {}).get(key, "")).get(at)
                vp = values(ngp.get(skill, {}).get(key, "")).get(at)
                try:
                    rc = float(cp) / float(cn) if float(cn) else None
                    rn = float(vp) / float(v) if float(v) else None
                except (TypeError, ValueError):
                    continue
                if rc is not None and rn is not None and abs(rc - rn) > 1e-4:
                    bad.append(f"{skill}.{key[0]} ({key[1]}) {at}: new tree NG {v} -> NG+ {vp} (x{rn:.3f}),"
                               f" classic {c} {cn} -> {cp} (x{rc:.3f})")
    return bad


def main():
    ap = argparse.ArgumentParser()
    paths.add_worktree(ap)  # required: parallel areas each pass their own worktree
    g = ap.add_mutually_exclusive_group()
    g.add_argument("--check", action="store_true")
    g.add_argument("--verify", action="store_true")
    args = ap.parse_args()
    if args.verify:
        bad = verify(os.path.join(args.worktree, DLC, "abilities"), os.path.join(args.worktree, DLC, "abilities_plus"))
        print("\n".join(bad) or "every shared skill scales alike in both trees in NG+")
        sys.exit(1 if bad else 0)
    ng, ngp = vanilla_abilities("abilities"), vanilla_abilities("abilities_plus")
    lng, lngp = vanilla_abilities("abilities", "legacy-GM"), vanilla_abilities("abilities_plus", "legacy-GM")
    src = os.path.join(args.worktree, DLC, "abilities")
    dst = os.path.join(args.worktree, DLC, "abilities_plus")
    classic = classic_values(src)
    report, stale = [], []
    for name in sorted(os.listdir(src)):
        if not name.endswith(".xml"):
            continue
        with open(os.path.join(src, name), encoding="utf-8-sig", newline="") as f:
            text = f.read()
        out = convert(text, name, ng, ngp, lng, lngp, report, classic)
        head = (f"<!-- New Game+ copy of abilities/{name}, generated by tools/gen_ngplus.py: numbers scaled by"
                f" the NG+ rule (docs/feature-mapping.md). Do not edit by hand. -->")
        nl = "\r\n" if "\r\n" in out else "\n"
        out = re.sub(r"^(<\?xml[^>]*\?>)", lambda m: m.group(1) + nl + head, out, count=1)
        path = os.path.join(dst, name)
        if args.check:
            try:
                with open(path, encoding="utf-8-sig", newline="") as f:
                    current = f.read()
            except FileNotFoundError:
                current = None
            if current != out:
                stale.append(name)
        else:
            os.makedirs(dst, exist_ok=True)
            with open(path, "w", encoding="utf-8-sig", newline="") as f:
                f.write(out)
            print("wrote", path)
    print("\n".join(report) or "no value changes")
    if stale:
        sys.exit("out of date (run without --check): " + ", ".join(stale))


if __name__ == "__main__":
    main()
