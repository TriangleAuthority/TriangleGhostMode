"""Generate CRAFT's crafting schematics and alchemy recipes as whole-file overrides (docs/features/craft.md).

A DLC cannot override a schematic or an alchemy recipe (the crafting and alchemy managers read every
entry of a name, ARM-12), so Ghost Mode ships its own copy of each schematic and recipe file it changes
(the owner's DC1, 2026-10-21): 5.x's file (`vanilla-5.x`) with legacy's entries (`legacy-GM`) for every
schematic and recipe unit `docs/features/attribution.csv` gives a ported CRAFT feature; every other line of
the file stays 5.x's (its items, which Ghost Mode's DLC overrides through the item tools, and 5.x's own
schematics and recipes, e.g. the Netflix set's, DC2). A schematic legacy changed is taken whole from
legacy, also where 5.x changed it (DC4: the six Blood and Wine Wolf upgrades), with legacy's inert
`price` (DC3). Entries another area ports its own way are left alone (`OTHER`).

    python tools/gen_craft.py [--worktree DIR] [--check | --verify]

Writes the files at their vanilla paths under `modGhostMode/files/` in the 5.x-GM worktree (default
../TGM-5x-GM), regular and NG+. --check writes nothing and fails if a file is out of date. --verify reads
the written files and checks that every CRAFT unit's entry equals legacy's (the ported ones) or 5.x's (the
others, counted by reason), that no name is defined twice, and that the rest of each file is 5.x's.
"""
import argparse, csv, os, re, subprocess, sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# The CRAFT features whose schematic and recipe entries are ported (the slices of craft.md's port order).
PORTED = {"CRAFT-01", "CRAFT-02", "CRAFT-03", "CRAFT-04", "CRAFT-05", "CRAFT-06"}
# Features of other areas whose entries are ported their own way (left as 5.x's here).
OTHER = {"ARM-12", "MUT-12", "ENCH-02"}

# Attributes of an entry kept as 5.x's where the unit also carries another area's feature, which ported its
# own way: the pheromone formulas stay potion formulas (ALCH-08's deviation, confirmed by the owner
# 2026-10-20), with legacy's ingredients (CRAFT-06).
KEEP_5X = {"ALCH-08": ("cookedItemType",)}

KINDS = {"schematic": "crafting_schematics", "recipe": "alchemy_recipes"}
UNIT = re.compile(r'^(.*\.xml)::custom/(crafting_schematics/schematic|alchemy_recipes/recipe):(.+)$')


def git(*args):
    return subprocess.run(["git", "-C", REPO, *args], capture_output=True, check=True).stdout.decode("utf-8-sig", errors="replace")


def units():
    """{path: {(kind, name): features}} of the schematic and recipe units with a CRAFT feature."""
    out = {}
    with open(os.path.join(REPO, "docs", "features", "attribution.csv"), encoding="utf-8") as f:
        for row in csv.DictReader(f):
            m = UNIT.match(row["unit"])
            feats = set(row["features"].split())
            if m and any(x.startswith("CRAFT-") for x in feats):
                out.setdefault("modGhostMode/" + m.group(1), {})[(m.group(2).split("/")[1], m.group(3))] = feats
    return out


def blank_comments(text):
    return re.sub(r'<!--.*?-->', lambda m: " " * len(m.group(0)), text, flags=re.S)


def entries(text):
    """{(kind, name): (start, end)} of every schematic and recipe entry (comments ignored)."""
    out, dup = {}, []
    blank = blank_comments(text)
    for kind in KINDS:
        for m in re.finditer(rf'<{kind}\b[^>]*?>.*?</{kind}>', blank, re.S):
            n = re.search(r'\bname_name\s*=\s*"([^"]+)"', m.group(0))
            if n:
                key = (kind, n.group(1))
                if key in out:
                    dup.append(key)
                out[key] = (m.start(), m.end())
    return out, dup


def norm(text):
    return " ".join(text.split())


def craft(feats):
    return {x for x in feats if x.startswith("CRAFT-")}


def wanted(feats):
    """Whether a unit's entry is legacy's: every CRAFT feature it carries is ported (CRAFT-04's
    schematics wait for their items), and no other area ports it."""
    return craft(feats) <= PORTED and not feats & OTHER


def keep_5x(entry, ventry, feats):
    """`entry` (legacy's) with KEEP_5X's attributes set to 5.x's."""
    for f, attrs in KEEP_5X.items():
        if f not in feats or ventry is None:
            continue
        for a in attrs:
            vm = re.search(rf'\b{a}\s*=\s*"([^"]*)"', ventry)
            if vm:
                entry = re.sub(rf'(\b{a}\s*=\s*")[^"]*(")', lambda m: m.group(1) + vm.group(1) + m.group(2), entry, count=1)
    return entry


def generate(path, us):
    """The file's new text (LF) and a report."""
    vtext, ltext = git("show", f"vanilla-5.x:{path}"), git("show", f"legacy-GM:{path}")
    ve, _ = entries(vtext)
    le, _ = entries(ltext)
    edits, adds, report = [], {}, []
    for key, feats in sorted(us.items()):
        if not wanted(feats):
            continue
        if key not in le:
            if key in ve:
                report.append(f"{key[0]} {key[1]}: legacy has none, 5.x's kept")
            continue
        lt = keep_5x(ltext[le[key][0]:le[key][1]], vtext[ve[key][0]:ve[key][1]] if key in ve else None, feats)
        if key in ve:
            if norm(vtext[ve[key][0]:ve[key][1]]) != norm(lt):
                edits.append((ve[key][0], ve[key][1], lt))
                report.append(f"{key[0]} {key[1]}")
        else:
            adds.setdefault(key[0], []).append(lt)
            report.append(f"{key[0]} {key[1]}: new")
    text = vtext
    for s, e, new in sorted(edits, reverse=True):
        text = text[:s] + new + text[e:]
    for kind, items in adds.items():
        close = text.rindex(f"</{KINDS[kind]}>")
        line = text.rfind("\n", 0, close) + 1
        text = text[:line] + "".join("\t" + x.strip() + "\n\n" for x in items) + text[line:]
    return text, report


def target(worktree, path):
    return os.path.join(worktree, path)


def bom(path):
    return git("show", f"vanilla-5.x:{path}") is not None and subprocess.run(
        ["git", "-C", REPO, "show", f"vanilla-5.x:{path}"], capture_output=True).stdout.startswith(b"\xef\xbb\xbf")


def write_text(text, path):
    return ("﻿" if bom(path) else "") + text.replace("\r\n", "\n").replace("\n", "\r\n")


def verify(worktree, us_all):
    problems, counts = [], {}
    for path, us in sorted(us_all.items()):
        dst = target(worktree, path)
        final = open(dst, encoding="utf-8-sig").read().replace("\r\n", "\n") if os.path.exists(dst) else git("show", f"vanilla-5.x:{path}")
        vtext, ltext = git("show", f"vanilla-5.x:{path}"), git("show", f"legacy-GM:{path}")
        fe, dup = entries(final)
        ve, _ = entries(vtext)
        le, _ = entries(ltext)
        problems += [f"{path}: {k[0]} {k[1]} defined twice" for k in dup]
        for key, feats in sorted(us.items()):
            f = norm(final[fe[key][0]:fe[key][1]]) if key in fe else None
            l = norm(keep_5x(ltext[le[key][0]:le[key][1]], vtext[ve[key][0]:ve[key][1]] if key in ve else None, feats)) if key in le else None
            v = norm(vtext[ve[key][0]:ve[key][1]]) if key in ve else None
            if f == l:
                counts["legacy's"] = counts.get("legacy's", 0) + 1
            elif feats & OTHER and not wanted(feats):
                reason = f"{', '.join(sorted(feats & OTHER))}: ported by its area" if f == v else None
                if reason:
                    counts[reason] = counts.get(reason, 0) + 1
                else:
                    problems.append(f"{path}: {key[0]} {key[1]} ({' '.join(sorted(feats))}) is neither legacy's nor 5.x's")
            elif not wanted(feats) and f == v:
                r = f"{', '.join(sorted(craft(feats) - PORTED))}: not ported yet"
                counts[r] = counts.get(r, 0) + 1
            else:
                problems.append(f"{path}: {key[0]} {key[1]} ({' '.join(sorted(feats))}) not legacy's")
        # the rest of the file: 5.x's (entries of CRAFT units cut out of both)
        def rest(text, ents):
            cut = sorted((ents[k] for k in us if k in ents), reverse=True)
            for s, e in cut:
                text = text[:s] + text[e:]
            return norm(text)
        if rest(final, fe) != rest(vtext, ve):
            problems.append(f"{path}: outside CRAFT's entries the file is not 5.x's")
        extra = set(fe) - set(ve) - set(us)
        problems += [f"{path}: {k[0]} {k[1]} added but not a CRAFT unit" for k in sorted(extra)]
    eu = ext_units()
    for folder in ("items", "items_plus"):
        dst = os.path.join(worktree, DLC_FILE % folder)
        have = {m.group(1): norm(m.group(0)) for m in EXTENSION.finditer(open(dst, encoding="utf-8-sig").read())} if os.path.exists(dst) else {}
        for name, (path, feats) in sorted(eu.get(folder, {}).items()):
            text = git("show", f"legacy-GM:{path}")
            lm = next((x for x in EXTENSION.finditer(blank_comments(text)) if x.group(1) == name), None)
            want = norm(re.sub(r'<!--.*?-->', '', text[lm.start():lm.end()], flags=re.S)) if lm else None
            if not wanted(feats):
                if name in have:
                    problems.append(f"{folder}: item extension {name} written before its features are ported")
                else:
                    counts["item extension: not ported yet"] = counts.get("item extension: not ported yet", 0) + 1
            elif have.get(name) != want:
                problems.append(f"{folder}: item extension {name} missing or not legacy's")
            else:
                counts["legacy's"] = counts.get("legacy's", 0) + 1
    print("CRAFT schematic and recipe units by state:")
    for r, n in sorted(counts.items()):
        print(f"  {n:5d}  {r}")
    for p in problems:
        print("  UNEXPLAINED " + p)
    print(f"verify: {len(problems)} unexplained differences")
    return len(problems)


EXT = re.compile(r'^(.*/gameplay/(items|items_plus)/_armor_stand_variants_extension\.xml)::definitions/items_extensions/item_extension:(.+)$')
EXTENSION = re.compile(r'<item_extension\s+name="([^"]+)"[^>]*>.*?</item_extension>', re.S)
DLC_FILE = "modGhostMode/files/dlc/dlcghostmode/data/gameplay/%s/gm_craft.xml"


def ext_units():
    """{folder: {name: (path, features)}} of the armor-stand looks with a CRAFT feature (CRAFT-04)."""
    out = {}
    with open(os.path.join(REPO, "docs", "features", "attribution.csv"), encoding="utf-8") as f:
        for row in csv.DictReader(f):
            m = EXT.match(row["unit"])
            feats = set(row["features"].split())
            if m and any(x.startswith("CRAFT-") for x in feats):
                out.setdefault(m.group(2), {})[m.group(3)] = ("modGhostMode/" + m.group(1), feats)
    return out


def dlc_text(folder, eu):
    """Ghost Mode's DLC file of CRAFT's new item extensions (the craftable quest armors' armor-stand
    looks), legacy's entries; None when there is none to write."""
    blocks = []
    for name, (path, feats) in sorted(eu.get(folder, {}).items()):
        if not wanted(feats):
            continue
        text = git("show", f"legacy-GM:{path}")
        m = next((x for x in EXTENSION.finditer(blank_comments(text)) if x.group(1) == name), None)
        if m:
            blocks.append("\t" + re.sub(r'\s*<!--\s*modSigns\s*-->', '', text[m.start():m.end()]).strip())
    if not blocks:
        return None
    lines = ['\ufeff<?xml version="1.0" encoding="UTF-8"?>',
             "<!-- Generated by tools/gen_craft.py: CRAFT-04's armor-stand looks of the craftable quest armors (legacy's); do not edit. -->",
             "<redxml>", "<definitions>", "<items_extensions>"] + blocks + ["</items_extensions>", "</definitions>", "</redxml>", ""]
    return "\r\n".join(x.replace("\r\n", "\n").replace("\n", "\r\n") for x in lines)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--worktree", default=os.path.join(REPO, "..", "TGM-5x-GM"))
    ap.add_argument("--check", action="store_true")
    ap.add_argument("--verify", action="store_true")
    args = ap.parse_args()
    us_all = units()
    if args.verify:
        sys.exit(1 if verify(args.worktree, us_all) else 0)
    stale = []
    for path, us in sorted(us_all.items()):
        text, report = generate(path, us)
        dst = target(args.worktree, path)
        vtext = git("show", f"vanilla-5.x:{path}")
        if text == vtext:
            new = None  # nothing ported in this file: the vanilla file (no override)
        else:
            new = write_text(text, path)
        old = open(dst, encoding="utf-8", newline="").read() if os.path.exists(dst) else None
        if new is None:
            # the worktree holds 5.x's own copy (5.x-GM derives from vanilla-5.x): restore it if changed
            if old is not None and norm(old.lstrip("﻿")) != norm(vtext):
                stale.append(path)
                if not args.check:
                    subprocess.run(["git", "-C", args.worktree, "checkout", "vanilla-5.x", "--", path], check=True)
            continue
        print(f"{path}: {len(report)} entries")
        if old != new:
            stale.append(path)
            if not args.check:
                with open(dst, "w", encoding="utf-8", newline="") as f:
                    f.write(new)
    eu = ext_units()
    for folder in ("items", "items_plus"):
        new = dlc_text(folder, eu)
        dst = os.path.join(args.worktree, DLC_FILE % folder)
        old = open(dst, encoding="utf-8", newline="").read() if os.path.exists(dst) else None
        if new != old:
            stale.append(DLC_FILE % folder)
            if not args.check:
                if new is None:
                    os.remove(dst)
                else:
                    with open(dst, "w", encoding="utf-8", newline="") as f:
                        f.write(new)
    if args.check and stale:
        sys.exit("out of date: " + ", ".join(stale) + ": run python tools/gen_craft.py")


if __name__ == "__main__":
    main()
