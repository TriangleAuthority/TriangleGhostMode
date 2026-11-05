"""Find the change units whose Ghost Mode change touches a subject.

Lists every unit in docs/features/units.csv whose change from legacy vanilla (`vanilla-1.32`) to
Ghost Mode (`legacy-GM`) adds or removes a line matching a pattern, with its attribution from
docs/features/attribution.csv and what 5.x did to it. Used to check an area's mapping before
calling it complete (see docs/feature-mapping.md#feature-ids-and-areas).

Scripts: one unit per function, method or event (`<Class>.<members>` and `<file>` units are
skipped); the changed lines of its body are compared. XML: one unit per named element (e.g. an
<ability>); the matching lines inside it are compared. Comments do not count. Matching ignores case unless --case-sensitive is given.

Usage:
    python tools/unit_sweep.py stamina                      # all units touching "stamina"
    python tools/unit_sweep.py stamina --unattributed      # what the area's mapping still misses
    python tools/unit_sweep.py adrenaline --type ws --lines 3   # show up to 3 matching lines per unit
"""
import argparse
import collections
import csv
import difflib
import fnmatch
import functools
import re
import subprocess
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
FEATURES = REPO / "docs" / "features"


def git(*args: str) -> str:
    return subprocess.run(["git", *args], cwd=REPO, capture_output=True, text=True,
                          encoding="utf-8", errors="replace").stdout


@functools.lru_cache(None)
def source(ref: str, path: str) -> list[str]:
    return git("show", f"{ref}:modGhostMode/{path}").splitlines()


def function_body(lines: list[str], name: str) -> list[str]:
    """All definitions of function/event `name` in the file, concatenated."""
    pattern = re.compile(r"\b(function|event)\s+" + re.escape(name) + r"\s*\(")
    out: list[str] = []
    for i, line in enumerate(lines):
        if not pattern.search(line) or line.strip().startswith("//"):
            continue
        depth, started = 0, False
        for j in range(i, len(lines)):
            out.append(lines[j])
            code = lines[j].split("//")[0]
            depth += code.count("{") - code.count("}")
            started = started or "{" in code
            if started and depth <= 0:
                break
    return out


NAMED = re.compile(r'<(\w+)\b[^>]*\bname(?:_name)?\s*=\s*"([^"]+)"')


@functools.lru_cache(None)
def xml_matches(ref: str, path: str, pattern: str) -> dict[str, list[str]]:
    """Matching lines (comments stripped) per named element: {'ability:Name': [...]}."""
    regex = re.compile(pattern)
    result: dict[str, list[str]] = collections.defaultdict(list)
    current = None
    for line in source(ref, path):
        m = NAMED.search(line)
        if m:
            current = f"{m.group(1)}:{m.group(2)}"
        text = re.sub(r"<!--.*?-->", "", line)
        if current and regex.search(text):
            result[current].append(re.sub(r"\s+", " ", text).strip())
    return result


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("pattern", help="regular expression matched against changed lines")
    ap.add_argument("--unattributed", action="store_true", help="only units no attribution row claims")
    ap.add_argument("--type", choices=["ws", "xml", "all"], default="all")
    ap.add_argument("--lines", type=int, default=0, help="show up to N matching changed lines per unit")
    ap.add_argument("--case-sensitive", action="store_true", help="match case (default: ignore it)")
    a = ap.parse_args()
    if not a.case_sensitive:
        a.pattern = "(?i)" + a.pattern
    regex = re.compile(a.pattern)

    attribution = [r for r in csv.reader(open(FEATURES / "attribution.csv", encoding="utf-8"))
                   if r and r[0] != "unit"]

    def attributed(unit: str) -> str:
        return next((r[1] for r in attribution if fnmatch.fnmatchcase(unit, r[0])), "")

    count = collections.Counter()
    for row in csv.DictReader(open(FEATURES / "units.csv", encoding="utf-8")):
        unit, kind = row["unit"], row["type"]
        if (a.type != "all" and kind != a.type) or kind not in ("ws", "xml") or "::" not in unit:
            continue
        path, name = unit.split("::", 1)
        if kind == "ws":
            if name.startswith("<") or name.endswith(">"):
                continue
            func = name.split(".")[-1]
            old, new = function_body(source("vanilla-1.32", path), func), function_body(source("legacy-GM", path), func)
            changed = [l for l in difflib.unified_diff(old, new, lineterm="", n=0)
                       if l[:1] in "+-" and not l.startswith(("+++", "---"))]
            hits = [l.strip() for l in changed
                    if regex.search(l.split("//")[0]) and not l[1:].strip().startswith("//")]
        else:
            element = name.rsplit("/", 1)[-1]
            old = xml_matches("vanilla-1.32", path, a.pattern).get(element, [])
            new = xml_matches("legacy-GM", path, a.pattern).get(element, [])
            if old == new:
                continue
            hits = [f"- {l}" for l in old if l not in new] + [f"+ {l}" for l in new if l not in old]
        if not hits:
            continue
        features = attributed(unit)
        if a.unattributed and features:
            continue
        count[kind] += 1
        print(f"{unit} | {features or 'UNATTRIBUTED'} | 5.x: {row['vanilla_5x'] or '-'}")
        for h in hits[:a.lines]:
            print(f"    {h[:140]}")
    print(f"-- {sum(count.values())} units ({count['ws']} script, {count['xml']} XML)")


if __name__ == "__main__":
    main()
