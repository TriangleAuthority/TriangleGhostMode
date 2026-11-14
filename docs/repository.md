# Repository layout and workflow

## Branches

```
vanilla-1.32:  Legacy vanilla files (1.32) ── tournament entities           the shared baseline
                 │
                 ├── legacy-GM:    SI ── CPB ── Ghost Mode 4.1                 the original mod
                 │
                 └── vanilla-5.x:  Vanilla files (5.0) ── 5.0 hotfix ── build 26238013 ── ...   CDPR's updates
                       │
                       └── master: the port ── ... ┬── tools, docs           the port, with the project's tools and docs
                                                    │
                       (tools and docs history) ───┘
```

| Branch | Contents |
|---|---|
| `vanilla-1.32` | The root commit with the unmodified legacy (1.32, Steam build 3280809) game files at the mod's paths under `modGhostMode/`, plus the Blood and Wine tournament entities Ghost Mode edits. The baseline every other branch starts from. |
| `legacy-GM` | `vanilla-1.32` plus the legacy mod, in three commits: its Shared Imports and Community Patch – Base dependencies, then Ghost Mode 4.1, the canonical legacy version (the Nexus release; the original repository's 77 commits by wghost are squashed into it, subjects listed in its message). They hold only the mod: `modGhostMode/`, `design-docs/` and `modGhostMode.w3modproj`. See [legacy-ghost-mode.md](legacy-ghost-mode.md). |
| `vanilla-5.x` | `vanilla-1.32` plus the same game file set from the current 5.x release (now 5.0 Steam build 26238013, `witcher3.exe` 5.0.0.1090142), one commit per release. |
| `master` | `vanilla-5.x` plus the Ghost Mode port, and the project's README, tools and docs (their history joins `master` in one merge). All work happens here or on short-lived branches off it. |

`vanilla-1.32`, `legacy-GM` and `vanilla-5.x` hold game and mod data only: no tools or docs. Their one other file is a `.gitattributes` with `* text=auto`, so text is stored LF-normalized whatever the committer's `core.autocrlf` (see [Encodings and line endings](#encodings-and-line-endings)).

The vanilla file set is the same in every branch:

- `modGhostMode/scripts/`: every vanilla script (`content/content0/scripts`).
- `modGhostMode/files/`: every `.xml`/`.csv` under `gameplay/` and `game/` (base game and each DLC's `data/`), plus every other file Ghost Mode overrides (`.w2ent`, `.journal`, `.w2scene`, ...). Editor, engine, level-layer, sound, QA/test and console files are left out.

Because the mod sits on top of the full vanilla set, `modGhostMode/` on `legacy-GM` and `master` is the complete merged game state, not an installable mod.

## Keeping branches up to date

- **`vanilla-1.32` and `legacy-GM` do not move.** They are the legacy reference.
- **A new game release** (5.1, ...) is a new commit on `vanilla-5.x`: in a worktree of `vanilla-5.x`, re-extract the files with the main checkout's `tools/extract_vanilla.py` (see [below](#regenerating-the-baselines)) and commit them on top. `git diff <previous>..vanilla-5.x` then shows exactly what the patch changed.
- **Then the port moves onto it, squashed.** The port is re-applied to the new release as one commit, then joined to the old history, so `master`'s first-parent history stays "vanilla releases, then the port" and `master` only moves forward (no force push, other worktrees keep working):

  ```bash
  git switch -c rebase-5.1 vanilla-5.x
  git merge --squash master        # the port, tools and docs re-applied on the new release (base: the previous vanilla-5.x)
  git commit -m "Ghost Mode port on 5.1 (squashed)"   # after resolving: keep the port's intent on the new vanilla file
  git merge -s ours -m "Join the port's history before 5.1" master   # every earlier commit stays reachable; the tree is the squashed one
  git switch master && git merge --ff-only rebase-5.1
  ```

  Then regenerate (`tools/gen_all.py --worktree .`), rebuild, and run the regression in both trees.
- **When the new vanilla commit sits on its own branch** until the owner fast-forwards `vanilla-5.x`: the tools read `vanilla-5.x` by name, so they still see the previous release. Build with `build_mod.py --base <the vanilla branch>` (without it the build stops: the ref then changes vanilla scripts), and run the generators and checks from a throwaway local clone whose `vanilla-5.x` points at the new commit (`git clone --shared --no-checkout <main checkout> <dir>`, then local `vanilla-5.x`, `vanilla-1.32` and `legacy-GM` branches, then check out the port branch), with `--worktree` at the port's worktree. Do not move the real `vanilla-5.x` for it.

## Encodings and line endings

| Tree | Scripts | XML | CSV |
|---|---|---|---|
| Legacy game as shipped | UTF-16 LE with BOM (13 files ASCII) | UTF-16 LE with BOM | mostly ASCII, some UTF-16 |
| `vanilla-1.32` and `legacy-GM` | UTF-8, no BOM (converted) | UTF-8, no BOM (converted; declaration says `UTF-8`) | as shipped (ASCII/UTF-8) |
| 5.0 as shipped = `vanilla-5.x` | UTF-8, no BOM | UTF-8 **with BOM** | mostly ASCII; 7 files UTF-16 LE, 1 UTF-8 with BOM, 2 UTF-8 |

- The legacy baseline and the legacy mod were converted from UTF-16 to UTF-8 so git can diff them. They are not byte-identical to what the legacy game shipped.
- `vanilla-5.x` keeps the game's own encodings (BOMs included), because ported files must match what 5.x uses. For scripts, the earlier conversion to BOM-less UTF-8 turned out to match 5.0 already. For XML, 5.0 adds a BOM that the converted mod files lack.
- Line endings: `.gitattributes` has `* text=auto`, so git stores text with LF and Windows checkouts (`core.autocrlf=true`) get CRLF. The game ships CRLF, with mixed CRLF/LF in about 980 scripts. UTF-16 files contain NUL bytes, so git treats them as binary and stores them untouched.
- Diffs need no special setup. The old `diff=astextplain` rules for `.ws/.xml/.csv` were removed from `.gitattributes` because they broke on UTF-16.

## Porting workflow

**Most features should not be ported by merging.** 5.x lets a mod change functions and XML entries through override files (script annotations, XML `on_conflict` overrides in a DLC, DLC mounters) instead of edited copies of vanilla files. [development.md](development.md#port-forms) sets the order of preference, and [feature-mapping.md](feature-mapping.md) the order of work. The merge below is for the analysis, and for the changes that do end up as whole-file overrides.

`legacy-GM` and `vanilla-5.x` share their base, `vanilla-1.32`, so git can do a three-way merge: base = legacy vanilla, ours = Ghost Mode, theirs = 5.x. On `master` (or a branch off it), Ghost Mode can be brought in wholesale or piece by piece:

```bash
git switch master
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

- The file selection includes everything under `modGhostMode/files` on the checkout the tool runs from (the main checkout, `master`): the port's whole-file overrides at vanilla paths are extracted too, and paths only the port has (its DLC) are listed as missing and skipped.
- The Steam install is now 5.x. Legacy (1.32) files come from the legacy game copy described in [tools.md](tools.md#game-install): `extract_vanilla.py --utf8 --game <legacy copy>` reproduces the legacy baseline on `vanilla-1.32` exactly (`--utf8` matches the committed conversion).
- 5.x baselines are extracted without `--utf8`, into the `vanilla-5.x` worktree's `modGhostMode/`. Commit them with LF-normalized text (as git does on `git add`), leaving BOMs and UTF-16 files untouched.
