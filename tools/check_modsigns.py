"""Check Ghost Mode's replaced script bodies against vanilla 5.x, and flag native wraps.

Every body that replaces vanilla code must mark each change with //modSigns (docs/development.md,
Conventions), so the code can later be ported to direct edits of the vanilla files:
  - an added or changed line carries //modSigns at its end;
  - a removed vanilla line or block leaves a comment line with //modSigns where it was;
  - a body with no vanilla counterpart in that class (an override of an inherited method in a
    scope-based override block) is all Ghost Mode's: every line carries the marker.
Checked: @replaceMethod functions, and methods in scope-based override blocks (a class block in
Ghost Mode's scripts whose class exists in vanilla) that replace a vanilla method of the class or
override one it inherits. New methods (@addMethod, or not defined anywhere in vanilla) need no marks.

Also raises an alarm for every @wrapMethod of a native (import) function: that works only from a
script blob, with probably no loose-script equivalent (docs/development.md, Annotations).

    python tools/check_modsigns.py --worktree DIR [--verbose]

Scans modGhostMode/scripts/local/ in the port's worktree (--worktree, required), working tree
files, against the vanilla-5.x branch. Exits 1 if anything is unmarked or alarming.
"""
import argparse
import difflib
import os
import re
import subprocess
import sys
import paths  # noqa: E402  (tools/: the shared --worktree argument)

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SCRIPTS = "modGhostMode/scripts/"
LOCAL = "modGhostMode/scripts/local"
MARK = "//modSigns"

CLASS = re.compile(r"(?m)^[ \t]*((?:import|abstract|statemachine)[ \t]+)*class[ \t]+(\w+)(?:[ \t]+extends[ \t]+(\w+))?")
STATE = re.compile(r"(?m)^[ \t]*((?:import|abstract)[ \t]+)*state[ \t]+(\w+)[ \t]+in[ \t]+(\w+)")
FUNC = re.compile(r"\b((?:(?:import|final|private|public|protected|latent|timer|entry|cleanup|exec|storyscene|quest|reward)\s+)*)(function|event)\s+(\w+)\s*\(")
ANNOT = re.compile(r"@(replaceMethod|wrapMethod|addMethod)(?:\(\s*(\w+)\s*\))?\s*$")


def mask(text, keep_strings=False):
    """The text with comments, strings and names blanked (same length), for structure scans;
    with keep_strings, strings and names are kept (for comparing lines of code)."""
    out = list(text)
    i, n = 0, len(text)
    while i < n:
        c = text[i]
        if text.startswith("//", i):
            j = text.find("\n", i)
            j = n if j < 0 else j
        elif text.startswith("/*", i):
            j = text.find("*/", i + 2)
            j = n if j < 0 else j + 2
        elif c in "\"'":
            j = i + 1
            while j < n and text[j] != c and text[j] != "\n":
                j += 2 if text[j] == "\\" else 1
            j = min(j + 1, n)
            if keep_strings:
                i = j
                continue
        else:
            i += 1
            continue
        for k in range(i, j):
            if out[k] != "\n":
                out[k] = " "
        i = j
    return "".join(out)


def match_brace(m, start):
    """Index after the brace block that opens at m[start] == '{'."""
    depth = 0
    for k in range(start, len(m)):
        if m[k] == "{":
            depth += 1
        elif m[k] == "}":
            depth -= 1
            if depth == 0:
                return k + 1
    return len(m)


def functions(text, m, lo, hi):
    """[(name, is_import, body_start, body_end, header_start)] directly in m[lo:hi] (skips nested blocks)."""
    out = []
    pos = lo
    while True:
        f = FUNC.search(m, pos, hi)
        if not f:
            return out
        k = f.end() - 1
        depth = 0
        while k < hi:                       # the parameter list
            if m[k] == "(":
                depth += 1
            elif m[k] == ")":
                depth -= 1
                if depth == 0:
                    break
            k += 1
        while k < hi and m[k] not in "{;":
            k += 1
        if k >= hi or m[k] == ";":
            out.append((f.group(3), "import" in f.group(1).split(), None, None, f.start()))
            pos = k + 1
        else:
            end = match_brace(m, k)
            out.append((f.group(3), "import" in f.group(1).split(), k + 1, end - 1, f.start()))
            pos = end


def containers(text, m):
    """{container: (parent, lo, hi)} for the class and state blocks of a file; 'Global' is implied."""
    out = {}
    for rx, kind in ((CLASS, "class"), (STATE, "state")):
        for c in rx.finditer(m):
            brace = m.find("{", c.end())
            semi = m.find(";", c.end())
            if brace < 0 or (0 <= semi < brace):
                continue
            end = match_brace(m, brace)
            if kind == "class":
                out[c.group(2)] = (c.group(3), brace + 1, end - 1)
            else:
                out[c.group(3) + "State" + c.group(2)] = (None, brace + 1, end - 1)
    return out


def global_ranges(m, conts):
    spans = sorted((lo, hi) for _, lo, hi in conts.values())
    ranges, pos = [], 0
    for lo, hi in spans:
        if lo > pos:
            ranges.append((pos, lo))
        pos = max(pos, hi + 1)
    ranges.append((pos, len(m)))
    return ranges


def git(*args):
    return subprocess.run(["git", *args], cwd=REPO, capture_output=True, check=True).stdout


def vanilla_index():
    """classes {name: parent}, defs {(container, name): (is_import, body_text)}."""
    files = [p for p in git("ls-tree", "-r", "--name-only", "vanilla-5.x", "--", SCRIPTS).decode().splitlines()
             if p.endswith(".ws") and not p.startswith(LOCAL)]
    data = subprocess.run(["git", "cat-file", "--batch"], cwd=REPO, capture_output=True, check=True,
                          input="".join(f"vanilla-5.x:{p}\n" for p in files).encode()).stdout
    classes, defs = {}, {}
    pos = 0
    for _ in files:
        nl = data.index(b"\n", pos)
        size = int(data[pos:nl].split()[2])
        text = data[nl + 1:nl + 1 + size].decode("utf-8-sig", errors="replace").replace("\r\n", "\n")
        pos = nl + 1 + size + 1
        m = mask(text)
        conts = containers(text, m)
        for cname, (parent, lo, hi) in conts.items():
            classes.setdefault(cname, parent)
            for name, imp, b0, b1, _ in functions(text, m, lo, hi):
                defs.setdefault((cname, name), (imp, text[b0:b1] if b0 is not None else None))
        for lo, hi in global_ranges(m, conts):
            for name, imp, b0, b1, _ in functions(text, m, lo, hi):
                defs.setdefault(("Global", name), (imp, text[b0:b1] if b0 is not None else None))
    return classes, defs


def lookup(classes, defs, cont, name, inherited):
    """(container, is_import, body) of the definition, in cont or (if inherited) its ancestors."""
    seen = set()
    while cont and cont not in seen:
        seen.add(cont)
        if (cont, name) in defs:
            return (cont,) + defs[(cont, name)]
        if not inherited:
            return None
        cont = classes.get(cont)
    return None


def code(line):
    """The line's code (comments dropped, whitespace collapsed) and whether it carries the marker."""
    marked = MARK.lower() in line.lower()
    c = mask(line, keep_strings=True)  # names kept: lines differing only in a name align correctly
    return " ".join(c.split()), marked


def check_body(mod_body, vanilla_body, first_line):
    """Unmarked changes: [(line number, text, reason)]."""
    mod = []        # (lineno, code, marked, original)
    for k, raw in enumerate(mod_body.split("\n")):
        cd, mk = code(raw)
        mod.append((first_line + k, cd, mk, raw.strip()))
    mcode = [x for x in mod if x[1]]
    problems = []
    if vanilla_body is None:
        for ln, cd, mk, raw in mcode:
            if not mk:
                problems.append((ln, raw, "no vanilla body in this class: every line is Ghost Mode's"))
        return problems
    vcode = [c for c in (code(l)[0] for l in vanilla_body.replace("\r\n", "\n").split("\n")) if c]
    # Two alignments: the plain one, and one where a marked line never pairs with a vanilla line (else a
    # marked brace can take a kept brace's place). A change counts as unmarked only when both find it.
    found = [_unmarked(vcode, mcode, mod, first_line, distinct) for distinct in (False, True)]
    return [p for p in found[0] if p in found[1]]


def _unmarked(vcode, mcode, mod, first_line, distinct):
    problems = []
    sm = difflib.SequenceMatcher(None, vcode, [x[1] + ("" if distinct and x[2] else "") for x in mcode], autojunk=False)
    for tag, i1, i2, j1, j2 in sm.get_opcodes():
        if tag in ("replace", "insert"):
            for ln, cd, mk, raw in mcode[j1:j2]:
                if not mk:
                    problems.append((ln, raw, "changed or added"))
        elif tag == "delete":
            # a marker comment (or a marked line) between the neighbouring kept lines
            # (brace-only lines align ambiguously, so the window extends over them)
            a, b = j1 - 1, j1
            while a > 0 and mcode[a][1] in ("{", "}"):
                a -= 1
            while b < len(mcode) - 1 and mcode[b][1] in ("{", "}"):
                b += 1
            lo = mcode[a][0] if a >= 0 else first_line - 1
            hi = mcode[b][0] if b < len(mcode) else first_line + len(mod)
            # a marker comment line right after hi counts too (identical lines such as `break;` can
            # align the removal one line earlier than the comment that records it)
            nxt = mcode[b + 1][0] if b + 1 < len(mcode) else hi + 1
            near = [x for x in mod if lo <= x[0] <= hi and x[2]] + [x for x in mod if hi < x[0] < nxt and x[2] and not x[1]]
            if not near:
                problems.append((hi if j1 < len(mcode) else lo, "", f"vanilla lines removed here without a //modSigns comment: {' | '.join(vcode[i1:i2])[:120]}"))
    return problems


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    paths.add_worktree(ap)  # required: parallel areas each pass their own worktree
    ap.add_argument("--verbose", action="store_true", help="also list the bodies that pass")
    args = ap.parse_args()
    classes, defs = vanilla_index()
    root = os.path.join(args.worktree, LOCAL)
    bad = alarms = checked = 0
    for dirpath, _, names in os.walk(root):
        for fn in sorted(names):
            if not fn.endswith(".ws"):
                continue
            path = os.path.join(dirpath, fn)
            rel = os.path.relpath(path, args.worktree).replace("\\", "/")
            text = open(path, encoding="utf-8-sig").read().replace("\r\n", "\n")
            m = mask(text)
            lines_before = lambda k: text.count("\n", 0, k) + 1
            jobs = []   # (label, kind, container, name, body_start, body_end)
            conts = containers(text, m)
            for cname, (_, lo, hi) in conts.items():
                if cname not in classes:
                    continue                        # Ghost Mode's own class
                funcs = functions(text, m, lo, hi)
                for name, _, b0, b1, h in funcs:
                    if b0 is not None:
                        jobs.append(("scope override", cname, name, b0, b1))
                # the block's own lines (default values, fields) are Ghost Mode's too
                spans = [(h, b1) for _, _, b0, b1, h in funcs if b0 is not None]
                unmarked = []
                for k in range(lines_before(lo), lines_before(hi) + 1):
                    start = len("\n".join(text.split("\n")[:k - 1])) + (1 if k > 1 else 0)
                    end = start + len(text.split("\n")[k - 1])
                    if any(start <= e and end >= h for h, e in spans):
                        continue
                    cd, mk = code(text.split("\n")[k - 1])
                    if cd and cd not in ("{", "}") and not mk:
                        unmarked.append((k, text.split("\n")[k - 1].strip()))
                checked += 1
                if unmarked:
                    bad += 1
                    print(f"UNMARKED {rel}:{lines_before(lo)} scope override block {cname}")
                    for ln, raw in unmarked:
                        print(f"    line {ln}: Ghost Mode's line in the block: {raw}")
                elif args.verbose:
                    print(f"ok {rel}:{lines_before(lo)} scope override block {cname}")
            for lo, hi in global_ranges(m, conts):
                for name, _, b0, b1, h in functions(text, m, lo, hi):
                    head = text[:h].rstrip().split("\n")[-1].strip()
                    a = ANNOT.search(head)
                    if not a:
                        continue
                    kind, cont = a.group(1), a.group(2) or "Global"
                    if kind == "replaceMethod" and b0 is not None:
                        jobs.append(("@replaceMethod", cont, name, b0, b1))
                    elif kind == "wrapMethod":
                        found = lookup(classes, defs, cont, name, True)
                        if found and found[1]:
                            alarms += 1
                            print(f"ALARM {rel}:{lines_before(h)} @wrapMethod of the native function {found[0]}.{name}: blob only, "
                                  "no loose-script equivalent (needs the project owner's agreement)")
            for label, cont, name, b0, b1 in jobs:
                own = lookup(classes, defs, cont, name, False)
                if label == "scope override" and not own and not lookup(classes, defs, cont, name, True):
                    continue                        # a new method, not a replacement
                vanilla = own[2] if own else None
                problems = check_body(text[b0:b1], vanilla, lines_before(b0))
                checked += 1
                where = f"{rel}:{lines_before(b0)} {label} {cont}.{name}" + ("" if own else " (inherited, no vanilla body here)")
                if problems:
                    bad += 1
                    print(f"UNMARKED {where}")
                    for ln, raw, why in problems:
                        print(f"    line {ln}: {why}" + (f": {raw}" if raw else ""))
                elif args.verbose:
                    print(f"ok {where}")
    print(f"{checked} replaced bodies checked, {bad} with unmarked changes, {alarms} native wrap alarm(s)")
    sys.exit(1 if bad or alarms else 0)


if __name__ == "__main__":
    main()
