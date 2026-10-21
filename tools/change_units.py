"""Inventory Ghost Mode's changes as change units, and report attribution coverage.

A change unit is the smallest thing Ghost Mode changed that can be judged on its own
(see docs/feature-mapping.md):

    scripts (.ws)   one global function, one class/state method, a class's fields and
                    defaults (<Class>.<members>), one struct or enum, or the file-level
                    leftovers (<file>)
    XML             one element with a name/id/key attribute (an <ability>, <item>,
                    <Group>, ...), keyed by its tag and name; elements without one
                    belong to their nearest named ancestor (or <file>)
    CSV             one row, keyed by its first column
    binary          the whole file (property-level splitting is not implemented yet)

States 'master' (legacy vanilla), the three legacy-GM commits (Shared Imports,
Community Patch - Base, Ghost Mode 4.1) and 'vanilla-5.x' are compared unit by unit.
Comments and whitespace do not count as changes. Writes:

    docs/features/units.csv     every unit Ghost Mode changed, added or removed
    docs/features/coverage.md   if docs/features/attribution.csv exists: which units
                                no feature claims yet, and which features claim nothing

units.csv columns:
    unit        <path under modGhostMode>::<name>
    type        ws, xml, csv, bin, other
    change      modified, added (not in legacy vanilla), removed (by Ghost Mode)
    origin      which legacy-GM commits changed it: SI, CPB, GM (space separated)
    marked      script units: the Ghost Mode version contains a //modSigns marker
    lines       changed lines in the unit, +added/-removed (text units)
    vanilla_5x  what 5.x did to the vanilla unit: unchanged, changed, removed, new
                (Ghost Mode added it and 5.x has a unit with the same key), '' otherwise
    overlap     'yes' when both Ghost Mode and 5.x changed the unit (merge by hand)
    ngplus      'yes' for New Game+ definitions (*_plus folders)
    gm_line     first line of the unit in the Ghost Mode file

attribution.csv: unit,features,note. 'unit' may contain * and ? wildcards (fnmatch);
'features' is a space-separated list of feature IDs. The first matching row wins.

Usage:
    python tools/change_units.py                 # write units.csv (and coverage.md)
    python tools/change_units.py --filter "*Cooldown*"   # print matching units only
"""
import argparse
import csv
import difflib
import fnmatch
import io
import re
import subprocess
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
OUT_DIR = REPO / "docs" / "features"
ROOT = "modGhostMode/"
STAGES = [("SI", "legacy-GM~2"), ("CPB", "legacy-GM~1"), ("GM", "legacy-GM")]
BASE, NEW = "master", "vanilla-5.x"
TEXT_TYPES = {".ws": "ws", ".xml": "xml", ".csv": "csv"}
BINARY_EXT = {".w2ent", ".journal", ".w2scene", ".w2phase", ".w2beh", ".w2behtree", ".w2comm", ".reddlc"}


def git(*args: str) -> str:
    return subprocess.run(["git", *args], cwd=REPO, check=True, capture_output=True).stdout.decode("utf-8")


class Blobs:
    """Read many blobs through one `git cat-file --batch` process."""

    def __init__(self):
        self.p = subprocess.Popen(["git", "cat-file", "--batch"], cwd=REPO, stdin=subprocess.PIPE,
                                  stdout=subprocess.PIPE)

    def get(self, ref: str, path: str) -> bytes | None:
        self.p.stdin.write(f"{ref}:{path}\n".encode("utf-8"))
        self.p.stdin.flush()
        header = self.p.stdout.readline().decode("utf-8").split()
        if len(header) < 3 or header[1] == "missing":
            return None
        data = self.p.stdout.read(int(header[2]))
        self.p.stdout.read(1)  # newline after the object
        return data


# ---------------------------------------------------------------- scripts --

def blank_comments_and_strings(text: str, keep_strings: bool = False) -> str:
    """Replace comments and string/name literals with spaces, keeping offsets and newlines; with
    keep_strings, only comments (the literals are skipped over, not blanked)."""
    out = list(text)
    i, n = 0, len(text)
    while i < n:
        c = text[i]
        if c == "/" and i + 1 < n and text[i + 1] == "/":
            j = text.find("\n", i)
            j = n if j < 0 else j
            for k in range(i, j):
                out[k] = " "
            i = j
        elif c == "/" and i + 1 < n and text[i + 1] == "*":
            j = text.find("*/", i + 2)
            j = n if j < 0 else j + 2
            for k in range(i, j):
                if text[k] != "\n":
                    out[k] = " "
            i = j
        elif c in "\"'":
            j = i + 1
            while j < n and text[j] != c and text[j] != "\n":
                j += 2 if text[j] == "\\" else 1
            if not keep_strings:
                for k in range(i + 1, min(j, n)):
                    out[k] = " "
            i = j + 1
        else:
            i += 1
    return "".join(out)


DECL_NAME = [
    (re.compile(r"\bstate\s+(\w+)\s+in\s+(\w+)"), lambda m: f"{m.group(2)}State{m.group(1)}"),
    (re.compile(r"\b(?:class|struct|enum)\s+(\w+)"), lambda m: m.group(1)),
    (re.compile(r"\b(?:function|event)\s+(\w+)"), lambda m: m.group(1)),
]


def decl_name(header: str) -> tuple[str, str] | None:
    """(kind, name) of a declaration header, kind 'scope' for class/state/struct/enum."""
    for rx, name in DECL_NAME:
        m = rx.search(header)
        if m:
            kind = "func" if rx.pattern.startswith(r"\b(?:function") else "scope"
            if kind == "scope" and re.search(r"\b(?:struct|enum)\b", header):
                kind = "block"
            return kind, name(m)
    return None


def script_units(text: str) -> dict[str, tuple[str, int, str]]:
    """Split a script into units: {name: (comparable text, first line, source text)}.

    The source text includes comments (and the comment lines just above a function);
    the comparable text does not, but keeps string and name literals (a change of a name such as
    'vsOgre_attack_power' is a change; the structure is read with the literals blanked).
    """
    clean = blank_comments_and_strings(text)
    comparable = blank_comments_and_strings(text, keep_strings=True)
    units: dict[str, list] = {}

    def add(name, start, end):
        body = re.sub(r"\s+", " ", comparable[start:end]).strip()
        if not body:
            return
        line = text.count("\n", 0, start) + 1
        if name in units:
            units[name][0] += " " + body
            units[name][2] += text[start:end]
        else:
            units[name] = [body, line, text[start:end]]

    depth = 0
    boundary = 0          # start of the current header at depth 0
    scope = None          # (name, body start) of the class/state being read
    member_boundary = 0   # start of the current header at depth 1
    item_start = None     # start of a depth-0 item or a method
    item_name = None
    for i, c in enumerate(clean):
        if c == "{":
            if depth == 0:
                d = decl_name(clean[boundary:i])
                if d and d[0] == "scope":
                    scope = (d[1], i + 1)
                    member_boundary = i + 1
                else:
                    item_name = d[1] if d else "<file>"
                    item_start = boundary
            elif depth == 1 and scope:
                d = decl_name(clean[member_boundary:i])
                if d and d[0] == "func":
                    add(f"{scope[0]}.<members>", member_boundary, member_boundary)  # keeps order
                    item_name = f"{scope[0]}.{d[1]}"
                    item_start = member_boundary
                else:
                    item_name, item_start = None, None
            depth += 1
        elif c == "}":
            depth -= 1
            if depth == 0:
                if scope:
                    add(f"{scope[0]}.<members>", member_boundary, i)
                    scope = None
                elif item_name:
                    add(item_name, item_start, i + 1)
                item_name, item_start = None, None
                boundary = i + 1
            elif depth == 1 and scope and item_name:
                add(item_name, item_start, i + 1)
                item_name, item_start = None, None
                member_boundary = i + 1
        elif c == ";":
            if depth == 0:
                add("<file>", boundary, i + 1)
                boundary = i + 1
            elif depth == 1 and scope:
                add(f"{scope[0]}.<members>", member_boundary, i + 1)
                member_boundary = i + 1
    add("<file>", boundary, len(clean))
    return {k: (v[0], v[1], v[2]) for k, v in units.items()}


# -------------------------------------------------------------------- XML --

ID_ATTRS = ("name", "id", "key", "name_name", "iconType_name")


def canonical(el: ET.Element) -> str:
    attrs = " ".join(f'{k}="{v}"' for k, v in sorted(el.attrib.items()))
    text = re.sub(r"\s+", " ", (el.text or "")).strip()
    return f"<{el.tag} {attrs}>{text}" + "".join(canonical(c) for c in el) + f"</{el.tag}>"


ATTR = re.compile(r'([\w:.-]+)\s*=\s*"([^"]*)"')


def lenient_xml(text: str) -> str:
    """Make XML the game accepts parseable: it tolerates "--" inside comments (Ghost Mode's
    merge markers), repeated attributes (some 5.x loot entries) and bare '&'."""
    text = re.sub(r"^\s*<\?xml[^>]*\?>", "", text)
    text = re.sub(r"<!--.*?-->", lambda m: "\n" * m.group().count("\n"), text, flags=re.S)
    text = re.sub(r"&(?!\w+;|#)", "&amp;", text)

    def dedupe(m):
        seen, attrs = set(), []
        for name, value in ATTR.findall(m.group(2)):
            if name not in seen:
                seen.add(name)
                attrs.append(f'{name}="{value}"')
        return f"<{m.group(1)}{' ' if attrs else ''}{' '.join(attrs)}{m.group(3)}>"

    return re.sub(r"<([\w:.-]+)((?:\s+[\w:.-]+\s*=\s*\"[^\"]*\")*)\s*(/?)>", dedupe, text)


def xml_units(data: bytes) -> dict[str, tuple[str, int]] | None:
    text = lenient_xml(data.decode("utf-8-sig", errors="replace"))
    try:
        parser = ET.XMLParser(target=ET.TreeBuilder(insert_comments=False))
        root = ET.fromstring(text, parser=parser)
    except ET.ParseError:
        return None
    units: dict[str, list] = {}
    counts: dict[str, int] = {}

    def walk(el, path):
        ident = next((el.attrib[a] for a in ID_ATTRS if a in el.attrib), None)
        if ident is not None and el is not root:
            key = f"{path}/{el.tag}:{ident}" if path else f"{el.tag}:{ident}"
            counts[key] = counts.get(key, 0) + 1
            if counts[key] > 1:
                key += f"#{counts[key]}"
            units[key] = [canonical(el), 0]
            return
        own = canonical_shallow(el)
        name = path or "<file>"
        units.setdefault(name, ["", 0])[0] += own
        child_path = "" if el is root else (f"{path}/{el.tag}" if path else el.tag)
        for c in el:
            walk(c, child_path)

    def canonical_shallow(el):
        attrs = " ".join(f'{k}="{v}"' for k, v in sorted(el.attrib.items()))
        return f"<{el.tag} {attrs}>{re.sub(r'\s+', ' ', (el.text or '')).strip()}"

    walk(root, "")
    # Line numbers: find each named element's opening tag in the source.
    for key in units:
        last = key.rsplit("/", 1)[-1].split("#")[0]
        if ":" in last:
            tag, ident = last.split(":", 1)
            m = re.search(rf"<{re.escape(tag)}\b[^>]*\b(?:{'|'.join(ID_ATTRS)})\s*=\s*\"{re.escape(ident)}\"", text)
            if m:
                units[key][1] = text.count("\n", 0, m.start()) + 1
    return {k: (v[0], v[1]) for k, v in units.items()}


# -------------------------------------------------------------------- CSV --

def csv_units(data: bytes) -> dict[str, tuple[str, int]]:
    text = data.decode("utf-8-sig", errors="replace")
    if data[:2] in (b"\xff\xfe", b"\xfe\xff"):
        text = data.decode("utf-16")
    units = {}
    for n, line in enumerate(text.splitlines(), 1):
        if not line.strip() or line.startswith(";"):
            continue
        key = "row:" + re.split(r"[;,|]", line, maxsplit=1)[0].strip().strip('"')
        while key in units:
            key += "+"
        units[key] = (re.sub(r"\s+", " ", line).strip(), n)
    return units


# ---------------------------------------------------------------- driver --

def units_of(path: str, data: bytes | None) -> dict[str, tuple[str, int]] | None:
    if data is None:
        return None
    ext = Path(path).suffix.lower()
    if ext == ".ws":
        return script_units(data.decode("utf-8-sig", errors="replace"))
    if ext == ".xml":
        u = xml_units(data)
        if u is not None:
            return u
        print(f"warning: cannot parse {path}; treating it as one unit", file=sys.stderr)
    if ext == ".csv":
        return csv_units(data)
    return {"<file>": (data.hex() if len(data) < 64 else str(hash(data)), 1)}


def changed_paths() -> list[str]:
    out = git("diff", "--name-only", "--no-renames", "-z", f"{BASE}..{STAGES[-1][1]}", "--", ROOT)
    return sorted(p for p in out.split("\0") if p)


def line_delta(old: str, new: str) -> str:
    a, r = 0, 0
    for op in difflib.ndiff(old.split("; ") if old else [], new.split("; ") if new else []):
        if op.startswith("+ "):
            a += 1
        elif op.startswith("- "):
            r += 1
    return f"+{a}/-{r}"


def inventory() -> list[dict]:
    blobs = Blobs()
    rows = []
    paths = changed_paths()
    for n, path in enumerate(paths, 1):
        if n % 200 == 0:
            print(f"  {n}/{len(paths)} files", file=sys.stderr)
        rel = path[len(ROOT):]
        ext = Path(path).suffix.lower()
        ftype = TEXT_TYPES.get(ext, "bin" if ext in BINARY_EXT else "other")
        base = units_of(path, blobs.get(BASE, path))
        stages = [units_of(path, blobs.get(ref, path)) for _, ref in STAGES]
        new = units_of(path, blobs.get(NEW, path))
        gm = stages[-1]
        names = list(dict.fromkeys([*(gm or {}), *(base or {})]))
        for name in names:
            b = (base or {}).get(name)
            g = (gm or {}).get(name)
            if b and g and b[0] == g[0]:
                continue
            change = "modified" if b and g else ("added" if g else "removed")
            origin, prev = [], b
            for (label, _), st in zip(STAGES, stages):
                cur = (st or {}).get(name)
                if (cur[0] if cur else None) != (prev[0] if prev else None):
                    origin.append(label)
                prev = cur
            v = (new or {}).get(name)
            if b:
                vstat = "removed" if not v else ("unchanged" if v[0] == b[0] else "changed")
            else:
                vstat = "new" if v else ""
            rows.append({
                "unit": f"{rel}::{name}",
                "type": ftype,
                "change": change,
                "origin": " ".join(origin),
                "marked": "yes" if ftype == "ws" and g and "modSigns" in g[2] else "",
                "lines": line_delta(b[0] if b else "", g[0] if g else "") if ftype in ("ws", "csv") else "",
                "vanilla_5x": vstat,
                "overlap": "yes" if change == "modified" and vstat == "changed" else "",
                "ngplus": "yes" if re.search(r"(^|/)\w+_plus/", rel) else "",
                "gm_line": str(g[1]) if g else "",
            })
    return rows


def coverage(rows: list[dict]) -> None:
    attr_path = OUT_DIR / "attribution.csv"
    if not attr_path.exists():
        return
    rules = []
    with attr_path.open(encoding="utf-8") as f:
        for r in csv.DictReader(f):
            rules.append((r["unit"].strip(), r["features"].split()))
    used: dict[str, int] = {}
    unattributed: dict[str, int] = {}
    for row in rows:
        feats = next((fs for pat, fs in rules if fnmatch.fnmatchcase(row["unit"], pat)), None)
        if feats:
            for fid in feats:
                used[fid] = used.get(fid, 0) + 1
        else:
            file = row["unit"].split("::", 1)[0]
            unattributed[file] = unattributed.get(file, 0) + 1
    declared = {fid for _, fs in rules for fid in fs}
    lines = ["# Attribution coverage", "",
             "Generated by `python tools/change_units.py`; do not edit by hand. "
             "See [feature-mapping.md](../feature-mapping.md#layout).", "",
             f"- Units: {len(rows)}, attributed: {len(rows) - sum(unattributed.values())}, "
             f"unattributed: {sum(unattributed.values())}",
             f"- Features referenced in attribution.csv: {len(declared)}", ""]
    unused = sorted(fid for fid in declared if not used.get(fid))
    if unused:
        lines += ["## Features that claim no unit", ""] + [f"- {fid}" for fid in unused] + [""]
    lines += ["## Unattributed units by file", "", "| File | Units |", "|---|---|"]
    lines += [f"| `{f}` | {c} |" for f, c in sorted(unattributed.items())]
    (OUT_DIR / "coverage.md").write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"wrote {OUT_DIR / 'coverage.md'}")


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--filter", help="print only units whose key matches this wildcard pattern; write nothing")
    args = ap.parse_args()
    rows = inventory()
    if args.filter:
        w = csv.DictWriter(sys.stdout, fieldnames=list(rows[0]), lineterminator="\n")
        w.writeheader()
        for r in rows:
            if fnmatch.fnmatchcase(r["unit"], args.filter):
                w.writerow(r)
        return
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    buf = io.StringIO()
    w = csv.DictWriter(buf, fieldnames=list(rows[0]), lineterminator="\n")
    w.writeheader()
    w.writerows(rows)
    (OUT_DIR / "units.csv").write_text(buf.getvalue(), encoding="utf-8")
    by_type: dict[str, int] = {}
    for r in rows:
        by_type[r["type"]] = by_type.get(r["type"], 0) + 1
    print(f"wrote {OUT_DIR / 'units.csv'}: {len(rows)} units ({', '.join(f'{k} {v}' for k, v in sorted(by_type.items()))})")
    coverage(rows)


if __name__ == "__main__":
    main()
