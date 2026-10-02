# Repository layout and workflow

## Branches

```
master:  Legacy vanilla files (1.32) ── tools ── README ── docs ── ...     shared base
           │
           ├── legacy-GM:    Ghost Mode v4.0                                the original mod
           │
           └── vanilla-5.x:  Vanilla files (5.0) ── (5.1, 5.2, ...)         CDPR's updates
                 │
                 └── 5.x-GM: porting work                                   the port
```

| Branch | Contents |
|---|---|
| `master` | The root commit with the unmodified legacy (1.32, Steam build 3280809) game files at the mod's paths under `modGhostMode/`, plus the README, tools and docs shared by every branch. |
| `legacy-GM` | `master` plus the legacy mod, in three commits: its Shared Imports and Community Patch – Base dependencies, then Ghost Mode 4.1, the canonical legacy version (the Nexus release; the original repository's 77 commits by wghost are squashed into it, subjects listed in its message). They hold only the mod: `modGhostMode/`, `design-docs/` and `modGhostMode.w3modproj`. See [legacy-ghost-mode.md](legacy-ghost-mode.md). |
| `vanilla-5.x` | `master` plus the same game file set from the current 5.x release (now the 5.0 hotfix, Steam build 25646871). Each future CDPR update gets its own commit on top. |
| `5.x-GM` | `vanilla-5.x` plus the Ghost Mode port. All porting work happens here. |

The vanilla file set is the same in every branch:

- `modGhostMode/scripts/`: every vanilla script (`content/content0/scripts`).
- `modGhostMode/files/`: every `.xml`/`.csv` under `gameplay/` and `game/` (base game and each DLC's `data/`), plus every other file Ghost Mode overrides (`.w2ent`, `.journal`, `.w2scene`, ...). Editor, engine, level-layer, sound, QA/test and console files are left out.

Because the mod sits on top of the full vanilla set, `modGhostMode/` on `legacy-GM` and `5.x-GM` is the complete merged game state, not an installable mod.

## Keeping branches up to date

- **Shared tools and docs go on `master`.** Anything that should be available everywhere must end up on `master`; if it was written on another branch, merge or cherry-pick it into `master`.
- **`legacy-GM` and `vanilla-5.x` are rebased onto `master`** when it moves (`git rebase master legacy-GM`). Each is only data on top of `master`, so the rebase just replays it and the mod stays on top. Rebasing rewrites the branch, so pushing needs `--force-with-lease`.
- **`5.x-GM` merges instead of rebasing**, because it holds ongoing work: `git merge vanilla-5.x` after `vanilla-5.x` gets a new game version or a rebase onto a newer `master`.
- **A new game release** (5.1, ...) is a new commit on `vanilla-5.x`: re-extract the files (see below), commit them on top, then merge `vanilla-5.x` into `5.x-GM`. `git diff <previous>..vanilla-5.x` then shows exactly what the patch changed.

## Useful commands

Use three dots (`A...B`) against `master`: it diffs from where `B` branched off, so newer tools and docs on `master` do not show up as changes.

```bash
# Everything Ghost Mode changes (legacy)
git diff master...legacy-GM -- modGhostMode

# Only files Ghost Mode modified (skip its new files)
git diff --diff-filter=M --stat master...legacy-GM -- modGhostMode

# Everything CDPR changed between legacy and 5.x
git diff master...vanilla-5.x

# Same, ignoring whitespace and the reformatting noise
git diff -w master...vanilla-5.x -- modGhostMode/scripts/game/player/playerWitcher.ws

# The port so far, relative to vanilla 5.x
git diff vanilla-5.x...5.x-GM

# One file, three ways: legacy vanilla, Ghost Mode, 5.x
git show master:modGhostMode/files/gameplay/abilities/geralt_skills.xml
git show legacy-GM:modGhostMode/files/gameplay/abilities/geralt_skills.xml
git show vanilla-5.x:modGhostMode/files/gameplay/abilities/geralt_skills.xml

# Binary files at property level (see binary-files.md)
python tools/bindiff.py master legacy-GM --summary

# Binary files as text in plain git diffs (needs the cr2w diff driver, see tools.md)
git diff master...legacy-GM -- modGhostMode/files/characters/npc_entities/monsters/arachas_lvl1.w2ent
```

## Encodings and line endings

| Tree | Scripts | XML | CSV |
|---|---|---|---|
| Legacy game as shipped | UTF-16 LE with BOM (13 files ASCII) | UTF-16 LE with BOM | mostly ASCII, some UTF-16 |
| `master` and `legacy-GM` | UTF-8, no BOM (converted) | UTF-8, no BOM (converted; declaration says `UTF-8`) | as shipped (ASCII/UTF-8) |
| 5.0 as shipped = `vanilla-5.x` | UTF-8, no BOM | UTF-8 **with BOM** | mostly ASCII; 7 files UTF-16 LE, 1 UTF-8 with BOM, 2 UTF-8 |

- The legacy baseline and the legacy mod were converted from UTF-16 to UTF-8 so git can diff them. They are not byte-identical to what the legacy game shipped.
- `vanilla-5.x` keeps the game's own encodings (BOMs included), because ported files must match what 5.x uses. For scripts, the earlier conversion to BOM-less UTF-8 turned out to match 5.0 already. For XML, 5.0 adds a BOM that the converted mod files lack.
- Line endings: `.gitattributes` has `* text=auto`, so git stores text with LF and Windows checkouts (`core.autocrlf=true`) get CRLF. The game ships CRLF, with mixed CRLF/LF in about 980 scripts. UTF-16 files contain NUL bytes, so git treats them as binary and stores them untouched.
- Diffs need no special setup. The old `diff=astextplain` rules for `.ws/.xml/.csv` were removed from `.gitattributes` because they broke on UTF-16.

## Porting workflow

**Most features should not be ported by merging.** 5.x lets a mod change functions and XML entries through override files (script annotations, XML `on_conflict` overrides in a DLC, DLC mounters) instead of edited copies of vanilla files. [development.md](development.md#port-forms) sets the order of preference, and [feature-mapping.md](feature-mapping.md) the order of work. The merge below is for the analysis, and for the changes that do end up as whole-file overrides.

`legacy-GM` and `vanilla-5.x` share their base on `master`, so git can do a three-way merge: base = legacy vanilla, ours = Ghost Mode, theirs = 5.x. On `5.x-GM`, Ghost Mode can be brought in wholesale or piece by piece:

```bash
git switch 5.x-GM
git merge -X ignore-all-space legacy-GM            # everything at once
git checkout legacy-GM -- <path>                   # or one file at a time, then adapt it
```

A dry run (`git merge-tree --write-tree -X ignore-all-space legacy-GM vanilla-5.x`) gives:

- **353 of the 523 text files `legacy-GM` modifies merge cleanly** (counts include its Shared Imports and Community Patch – Base scripts). The Ghost Mode edits land on the 5.x file, and 5.x's BOM and formatting are kept. 93 of these are files 5.x really changed, so review them anyway.
- **170 text files conflict:** 73 scripts, 96 XML files and `gameplay/globals/quest_levels.csv`. Resolve these by hand, keeping the spirit of the Ghost Mode change on top of the 5.x logic.
- **All 650 binary files conflict**, because 5.0 re-saved every one (CR2W format 163 → 164). Take the 5.x file (`git checkout --theirs <path>`), then reapply Ghost Mode's edit. [binary-files.md](binary-files.md) explains what those edits are and how to inspect them.

[5.x-file-status.md](5.x-file-status.md) lists every file in each group. Some Ghost Mode features overlap with 5.0's reworked systems (see [game-5.0-changes.md](game-5.0-changes.md)); decide per feature whether to port, adapt or drop it.

## Regenerating the baselines

`tools/extract_vanilla.py` rebuilds either baseline from an installed game. See [tools.md](tools.md). Notes:

- The file selection includes everything under `modGhostMode/files` on the current checkout. That path list is the same on every branch, so any of them works.
- The Steam install is now 5.x. Legacy (1.32) files come from the legacy game copy described in [tools.md](tools.md#game-install): `extract_vanilla.py --utf8 --game <legacy copy>` reproduces the legacy baseline on `master` exactly (`--utf8` matches the committed conversion).
- 5.x baselines are extracted without `--utf8`. Commit them with LF-normalized text (as git does on `git add`), leaving BOMs and UTF-16 files untouched. After committing a new release on `vanilla-5.x`, regenerate [5.x-file-status.md](5.x-file-status.md) with `python tools/port_status.py` and commit it on `master`.
