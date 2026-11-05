# Proposal: porting areas in parallel with a shared game slot

Status: **in use** (since 2026-11-02; approved by the owner 2026-11-02). Step 0, the prerequisites, is built ([What is built](#what-is-built)); steps 1 and 2 are done: ARM-12's New Game+ fix was the lock's first user, and WGT, OPT and TRPH were ported in parallel, integrated, audited and signed off by the owner (2026-11-02). Area agents follow the procedure in [development.md](../development.md#working-in-parallel); the game slot, its commands and the gating are in [game-automation.md](../game-automation.md#the-game-slot).

## Goal

Port several areas at the same time, one agent per area. The single game install is the bottleneck: it must be busy as much as possible, and never shared.

## 1. What is exclusive and what is not

**The game slot (one holder at a time):**
- **Installing a build:** `<game>\mods\modGhostMode`, the menu XML in `bin\config\r4game\user_config_matrix\pc\`, and `mods.settings`.
- **The running game:** every state-changing `game.py` command (`run`, `start`, `load`, `exec`, `resume`).
- **What the game writes:**
  - its script log `scriptslog.txt` (deleted at each start);
  - the settings files `dx12user.settings`, `input.settings` and `profile.settings`;
  - the saves folder;
  - the shared test-only save slot.

**The compiler slot (serialized automatically, never held for long):** each `wcc_lite` run (compile, pack, metadata). Every run writes shared files: REDkit's `wcc.log`, its script cache and its `temp\`, and `editoruser.settings`. Every run also listens on port 37000. `build_mod.py` takes a short OS file lock around each `wcc_lite` call (about 50 s for compile, 45 s for pack). Other agents' builds simply wait their turn.

**Free in parallel:** editing, the generators, `check_modsigns`, `dlc_conflicts`, `deviations`, docs, Mnemosyne. These write only inside their own checkouts, once `--worktree` is given (see section 4).

**Parent only:** the modAutomation build and `tools/automation`, the canonical settings baseline, and saving the shared test-only slot.

**Prohibited for agents:** these bypass the lock.
- calling `rw3d_cli` directly;
- installing with `--scripts`;
- copying saves by hand;
- editing the settings files.

**CPU load:** builds and generators run at below-normal priority, so they disturb the game's timing-sensitive checks less. The rule stays that a check counts as failed only if it fails twice in a row.

## 2. The game lock: `tools/game_lock.py`

A tool manages the slot, so grants never wait for the parent. The parent sets policy and watches.

**State:**
- The state lives in `%LOCALAPPDATA%\TGM\`: the holder and its token, the FIFO queue, the lease, a paused flag and a log.
- Every change is made under an OS file lock (`msvcrt.locking`), which the OS releases if a process dies. The state is written via a temp file and `os.replace`.

**Commands:**

| Command | What it does |
|---|---|
| `request --who AREA --why TEXT` | Grants the slot at once, with a **token**, if it is free, nobody is queued, nothing is paused and the game is closed. Otherwise it queues the agent and prints its position. |
| `wait --who AREA --timeout S` | Blocks until the agent holds the slot. Exit codes: 0 granted (prints the token), 2 timed out (run it again), 3 paused or preempted. An agent with other work runs it in the background and is notified. An idle agent loops it in the foreground with `--timeout 540`. |
| `status` | The holder, the queue, the lease, paused or not. |
| `release --holder AREA:TOKEN` | Needs the game closed. Restores the four settings files from the canonical baseline, archives `scriptslog.txt` into a file for that holder, compares the saves with the backup and logs any difference (it restores no save), then gives the slot to the next agent. |
| `cancel --who AREA` | Leaves the queue. |
| `pause` / `resume` | For the parent, or for **the owner from his own terminal**. No new grants while paused. Waiting agents are woken with code 3. |
| `preempt` | Parent only. Quits the game, restores the baseline and revokes the token. |
| `reclaim` | Parent only. Takes back a slot whose lease expired. |
| `watch` | Parent only. Runs in the background and exits on an expired lease, a stale holder, an unclaimed grant or a pause. This is how the parent gets alerted. |

**Timing rules:**
- **Claim deadline:** a grant is skipped if no game command comes within the claim deadline: 5 minutes by default, set in the lock's config. The parent raises it if `watch` shows agents often missing it (the owner, 2026-11-02).
- **Lease:** 20 minutes, renewed by every gated command.

**On every grant:** the tool backs up the saves. The robocopy line uses `documents_dir()` for the path.

**Canonical settings baseline:** taken once by the parent, with the owner's OK, while the game is closed. It is taken again only after the owner has played. A crashed run can therefore never become the baseline.

**Enforcement, inside `game.py` and `build_mod.py --install`:**
- Every state-changing command needs `--holder AREA:TOKEN`. There is no environment variable, because environment variables don't persist between calls.
- **Saves:** `run` and `load` need a save name from an allow-list: the test save, plus the test-only slot by its full key. A missing name is refused; today a missing name loads the newest save. `gmtest_nosave()` is called automatically after each load, and its absence is an error.
- **Installed build:** `run` checks that the installed build is the holder's own (its branch and commit, from `.built-by-build_mod`), so no agent tests the previous holder's leftover install.
- `quit` and `log` always work.
- **One copy of the tools:** every game-slot command runs from the main checkout, `TriangleGhostMode\tools`. That is the only copy with `rw3d_cli.exe` (it is git-ignored) and the only copy guaranteed to have the gating code.

## 3. A holder's turn

- **Commit at every testable point** (the owner, 2026-11-02). Each time the area's code reaches a state worth testing, commit it on `gm/<area>` and make its compile-only build into a folder named for the commit. When the slot arrives in the middle of other work, the agent installs that last testable build (`--install-from`) and runs it. Its uncommitted edits stay where they are (`build_mod.py` builds from commits, never from the working tree), or are stashed if it needs to step back. The commits are squashed into one per slice at integration.
- **Before requesting:**
  - the slice is committed on the area's branch;
  - it compiles, with a compile-only build into the area's own folder;
  - `gen_all.py --verify` and the offline checks pass.
- **The turn:**
  1. install the **prebuilt** build (`build_mod.py --install-from <out>`, so no rebuilding while holding the slot);
  2. launch;
  3. the slice's checks in both trees, plus the "fail first" throwaway build when one is needed;
  4. `regress.py` when the regression run is due;
  5. quit and release.
- **Release before editing code.** If a check fails, release first, fix, then request again.
- **Keep each `exec` short,** so a pause or stop reaches the agent quickly.
- **The existing hard rules still apply:**
  - scripted checks only;
  - never save over the owner's saves;
  - only the allowed test saves;
  - no story teleports or time skips.

## 4. Branches and worktrees

Since the history rewrite (2026-11-05) the tools, docs and port share one branch, `master`. An area has one branch and one worktree:

| Worktree | Branch | Holds |
|---|---|---|
| `../TGM-<area>` | `gm/<area>`, from `master` | the mod code, the generated XML, the area's **tools and generators**, its doc, its attribution rows and its open questions |

- **Where tools run:**
  - The area's generators and compile-only builds run from `TGM-<area>`, with `--worktree .` and `--ref gm/<area>`.
  - While parallel work runs, these two arguments become **required** in every generator and in `build_mod.py`.
- **Findings for shared docs:** CLAUDE.md sends findings to `development.md`, `game-5.0-changes.md` or `tools.md`. Agents put them instead in a "For the shared docs" block in their area doc, and integration moves them.
- **Git hygiene:**
  - Agents never fetch.
  - Agents push only their own branch.
  - `gc.auto=0` while parallel work runs; the parent runs `git gc` when nothing else is running.
  - Every area worktree is created after the lock commit.

## 5. Shared ownership (settled before launch)

- **OPT and WGT:**
  - OPT owns the menu (`modGhostMode.xml`), `gmOptions.ws` and the option labels. In its slice O2, OPT adds WGT's three entries: boat sinking, its threshold, and the weight reduction.
  - WGT owns the mechanics. That includes the single `@replaceMethod` of `W3Boat.OnAreaEnter` and of `CInventoryComponent.GetItemEncumbrance`, and the boat message. (The mod allows only one replacement per function.)
  - OPT's slices O4 and O5 become checks inside WGT's slices W4 and W6. OPT ends after O3.
- **WGT and TRPH:**
  - `gen_trph.py` writes the trophy abilities whole, including legacy's weights.
  - `gen_wgt.py` skips names that another DLC file defines.
  - W5's overburdened checks read the carry limit from the game, never as a fixed number, because the Wight trophy adds +20.
- **Pre-seeded hooks**, set up on `master` before branching, so areas don't edit the same lines:
  - per-area test stubs already called from `gmtest_regress()` and `gmtest_panel()`;
  - `item_layer.py`'s `PORTED`, `TAGS` and `NODES` split into per-area sets on separate lines;
  - the string CSVs merged by union through `.gitattributes`. The build already stops on any duplicate string id.

## 6. Integration

Integration is too heavy for the parent per slice: about 15–25 minutes each, 12–15 times. A fresh **integrator subagent** does it, in batches, and the parent verifies its result as it verifies any agent today. A batch is:

1. Merge the squashed `gm/<area>` into `master` (code, tools and docs together). For generated files, take either side, then rebuild them with the merged tools: `tools/gen_all.py` runs every generator in its order, with `--check` and `--verify`, and lists the generated paths.
2. Run every `--verify`, `check_modsigns`, `dlc_conflicts`, `deviations --check`, and a compile.
3. Fast-forward, push, and regenerate `deviations.md` and `coverage.md`. The parent then updates `features/README.md`.
4. Run the **integrated regression in both trees**, queued in the game lock as holder `integration`.

**When integration runs:**
- Batches happen as needed.
- A dependency is integrated at once: OPT's O2 goes in before WGT's W4.
- An audit always follows an integrated regression.

**What agents do:**
- They rebase at their next slice boundary, never in the middle of a slice.
- Until its slice is integrated, an area's docs say "verified on the area build".
- Regression counts are recorded at integration. Area counts are given as "+N checks".

## 7. Order of work

0. **Prerequisites.** One agent, serial: everything in sections 1, 2, 4 and 5 that is tooling, plus `gen_all.py`, `regress.py` and `--install-from`. Then an offline self-test: fake agents queueing, a process killed while it holds the lock, refusals, pause, preempt, the claim deadline. Then one real turn in the game. **Done** 2026-11-02 ([What is built](#what-is-built)).
1. **ARM-12's New Game+ fix**, the first real user of the lock. **Done** 2026-11-02.
2. **WGT, OPT and TRPH start together.** **Done**: ported, integrated, audited and signed off 2026-11-02.
3. **When OPT and TRPH finish, the next mapped area starts,** so the game doesn't sit idle while WGT runs alone. The remaining areas still need mapping. A mapping agent can run any time, since mapping needs no game.

## Expected gain

This is an estimate, not a measurement:
- About **1.5–1.7×** faster than serial for these three areas. The critical path is WGT, the largest area, which runs alone at the end.
- About **2–2.5×** once more areas overlap, because the game becomes the limit.

The new bottlenecks are integration, then the game queue, then timing flakes from CPU load.

**For the owner:** the game window comes up at every launch, so with the slot busy most of the time, the computer is effectively occupied. `python tools/game_lock.py pause` lets you take it back. The current game finishes or is stopped, and no one gets the game again until `resume`, or until you tell me to resume.

## What is built

Step 0, 2026-11-02. **Verified:** the offline self-test (`game_lock.py selftest`: 82 checks, among them FIFO queueing, the claim deadline, lease expiry and `reclaim`, pause, preempt, refusals, and a process killed while it holds the file lock) and one real turn as holder `tooling` (master `3d1d8ff3`: compile-only build, `--install-from`, `regress.py --trees both`: `gmtest_regress()` 1,300 passed and `gmtest_panel()` 156 passed, 0 failed, in each tree; the release restored the four settings files, archived the log, and found the saves unchanged, 1,079 live and in the backup). `gen_all.py --verify --worktree ../TGM-5x-GM`: every generator and check passed, no diff. The procedure an area agent follows is [development.md: Working in parallel](../development.md#working-in-parallel); the lock and the guards are in [game-automation.md: The game slot](../game-automation.md#the-game-slot); the tools in [tools.md](../tools.md).

| Plan | Built as |
|---|---|
| Section 1: the compiler slot, CPU load | `build_mod.py`: an OS file lock around each `wcc_lite` run (`%LOCALAPPDATA%\TGM\wcc.lock`), wcc_lite at below-normal priority. Generators and checks lower their own priority (`paths.add_worktree`); `gen_all.py` starts them below normal |
| Section 2: the game lock | `tools/game_lock.py` with every command of the table, plus `config` (the claim deadline and the lease) and `selftest`; the claim deadline in `%LOCALAPPDATA%\TGM\config.json` (`claim_deadline_s`, 300) |
| Section 2: enforcement | `game.py` (`--holder` on run, start, load, exec, resume; the save allow-list; `gmtest_nosave()` after each load; the installed-build check at `start`) and `build_mod.py --install`/`--install-from` |
| Section 3: prebuilt installs | `build_mod.py --install-from <out>`; `--ref` and `--out` required; a warning for uncommitted changes in the ref's worktree |
| Section 4: `--worktree` | Required in every generator, `check_modsigns.py` and `dlc_conflicts.py` (always, not only in a parallel mode); `gen_loot.py`'s and `gen_ai_ent.py`'s module defaults removed, so nothing falls back to `TGM-5x-GM`. `gc.auto` 0 in the main repository's config |
| Section 5: pre-seeded hooks | master `3d1d8ff3`: `tests/gmTestsWgt.ws`, `gmTestsOpt.ws`, `gmTestsTrph.ws` (`GMTest_<area>()` in `gmtest_regress()`, `GMTest_<area>_after()` in `gmtest_panel()`, empty) and `.gitattributes`' `merge=union` for `modGhostMode/localization/**/*.csv`. Master: `item_layer.py`'s `PORTED`, `AREAS` and the `TAGS`, `NODES`, `BLOCKS` and `ATTRS` additions one line per area, with WGT's, OPT's and TRPH's ready (the same values) |
| Section 6: integration | `tools/gen_all.py` (write in order, `--check`, `--verify`, `--list`); `tools/regress.py` (both trees, counts, archived logs, the flake rerun) |

**Choices made while building** (the porter's, not yet confirmed by the owner):
- **The pause also stops the holder:** its game commands are refused (exit 3), so it quits and releases at once; `quit` and `release` still work. The plan let the current game finish.
- **A grant needs the settings files equal to the baseline,** so a game the owner played (or a crashed run nobody released) blocks the queue, and `watch` says so, until the parent takes the baseline again with the owner's OK.
- **The parent's bypass is `--parent`** on `game.py`, `build_mod.py` and `regress.py` (logged in `events.log`); the parent's integration runs queue as holder `integration` like any agent. `preempt`, `reclaim` and `baseline` need `--parent` too.
- **`game.py exec` refuses calls that load or save** (`autoload`, `SaveGame`, the test save makers), which would get around the allow-list.
- **A skipped grant is not re-queued:** the agent requests again (a dead agent would otherwise be granted and skipped forever).
- **`gen_npc_stamina.py --check` now fails when its file is out of date** (it only printed the report), and `gen_test_dummy.py` has a `--check`, so `gen_all.py --check` covers every generator.
