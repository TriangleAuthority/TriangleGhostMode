"""Generate the New Game+ copies of Ghost Mode's DLC ability XML.

The game reads NG+ definitions from `abilities_plus/` folders; a DLC mounts its own with a
CR4DefinitionsNGPlusDLCMounter (see docs/development.md, "DLC and mounters"). For every XML
file in the DLC's `abilities/` folder this writes a copy into `abilities_plus/`, with each
number scaled by the NG+ rule (docs/feature-mapping.md, "NG+ numbers"):

    GM NG+ = vanilla NG+ x (GM NG / vanilla NG)

where vanilla is 5.x (`vanilla-5.x`), GM NG the value in Ghost Mode's file, and vanilla NG / NG+
the same ability's node in vanilla's `abilities/` / `abilities_plus/` files (matched by tag,
`type` and order). Edge cases: vanilla NG and NG+ equal, a node or ability vanilla does not
have, or one missing from NG+: Ghost Mode's value as is; vanilla NG 0: the difference is added
(GM NG + vanilla NG+). Legacy behaviour first: where legacy Ghost Mode (`legacy-GM`) gave a node
the same value in NG and NG+ and Ghost Mode's value is that value, it is kept (legacy chose not to
scale it). Comments and layout are kept. Prints every value that changes or is kept that way.

    python tools/gen_ngplus.py [--worktree DIR] [--check]

Default worktree ../TGM-5x-GM. --check writes nothing: it prints the report and fails if a copy
in `abilities_plus/` is missing or out of date. Re-run after changing any file in `abilities/`.
"""
import argparse, os, re, subprocess, sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DLC = "modGhostMode/files/dlc/dlcghostmode/data/gameplay/"
ABILITY = re.compile(r'(<ability\s+name="([^"]+)"[^>]*>)(.*?)(</ability>)', re.S)
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


def convert(text, name, ng, ngp, lng, lngp, report):
    def ability(m):
        a = m.group(2)
        if a not in ng:
            return m.group(0)
        if a not in ngp:
            report.append(f"{name}: {a} not in vanilla NG+, copied")
            return m.group(0)
        body, parts, last = m.group(3), [], 0
        for key, attrs, (s, e) in node_keys(body):
            nv, pv = values(ng[a].get(key, "")), values(ngp[a].get(key, ""))
            lv, lpv = values(lng.get(a, {}).get(key, "")), values(lngp.get(a, {}).get(key, ""))
            def sub(am):
                new = scale(am.group(2), nv.get(am.group(1)), pv.get(am.group(1)))
                if new != am.group(2) and same(am.group(2), lv.get(am.group(1)), lpv.get(am.group(1))):
                    report.append(f"{name}: {a}.{key[0]} ({key[1]}) {am.group(1)} {am.group(2)} kept: legacy has it"
                                  f" in NG+ too (the rule would give {new})")
                    new = am.group(2)
                if new != am.group(2):
                    report.append(f"{name}: {a}.{key[0]} ({key[1]}) {am.group(1)} {am.group(2)} -> {new}"
                                  f" (vanilla {nv.get(am.group(1))} / NG+ {pv.get(am.group(1))})")
                return f'{am.group(1)}="{new}"'
            parts += [body[last:s], ATTR.sub(sub, attrs)]
            last = e
        parts.append(body[last:])
        return m.group(1) + "".join(parts) + m.group(4)
    return ABILITY.sub(ability, text)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--worktree", default=os.path.join(os.path.dirname(REPO), "TGM-5x-GM"))
    ap.add_argument("--check", action="store_true")
    args = ap.parse_args()
    ng, ngp = vanilla_abilities("abilities"), vanilla_abilities("abilities_plus")
    lng, lngp = vanilla_abilities("abilities", "legacy-GM"), vanilla_abilities("abilities_plus", "legacy-GM")
    src = os.path.join(args.worktree, DLC, "abilities")
    dst = os.path.join(args.worktree, DLC, "abilities_plus")
    report, stale = [], []
    for name in sorted(os.listdir(src)):
        if not name.endswith(".xml"):
            continue
        with open(os.path.join(src, name), encoding="utf-8-sig", newline="") as f:
            text = f.read()
        out = convert(text, name, ng, ngp, lng, lngp, report)
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
