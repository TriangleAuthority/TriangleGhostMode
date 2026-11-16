# Setting up a new machine

How to go from a fresh clone to building the mod, testing it in game by script, and running several AI agents in parallel on one game install. Every step links to the doc that explains it in full. The sibling ports ([TriangleFriendlyMeditation](https://github.com/TriangleAuthority/TriangleFriendlyMeditation), [TrianglePreparations](https://github.com/TriangleAuthority/TrianglePreparations), [TriangleGwentImprovements](https://github.com/TriangleAuthority/TriangleGwentImprovements)) use this repository's game tools: clone them next to this one.

## What you need

- Windows, with **The Witcher 3 game version 5.x** on Steam (the tools find it through Steam, or take `W3_GAME_DIR`).
- **REDkit** (free, on Steam) for building: its `wcc_lite` compiles the scripts and packs files (`W3_REDKIT_DIR` overrides where it is).
- **Python 3** (3.13 tested; no extra packages) and git. The GitHub CLI `gh` makes one download easier (step 3).

Check what the tools find: `python tools/paths.py`.

## 1. Build

```bash
python tools/build_mod.py --ref master --out build/master-<commit>              # a test build (with the in-game tests)
python tools/build_mod.py --ref master --out build/release --package           # a release zip, to install by extracting
```

See [development.md](development.md#build-compile-install) and [tools.md](tools.md). Optional: the `cr2w` diff driver shows binary game files as text in `git diff` ([tools.md](tools.md#git-and-github)).

## 2. The game slot: not in use yet

`tools/game_lock.py` lets several agents share the one game install, one at a time ([game-automation.md](game-automation.md#the-game-slot)). It is not a process that runs in the background: each command takes a per-machine OS file lock for a moment and reads and writes the slot's state in `%LOCALAPPDATA%\TGM`. So every copy of the script, from any checkout, worktree or sibling repository, shares the same slot; a copy older than the state refuses to touch it and says to update, and only one `watch` runs per machine. Until a first turn is granted on the machine, it is not in use: the commands below change the game without `--holder`. The first granted `request` turns it on for good; from then on every command that changes the game needs the holder's token.

## 3. Game automation

The tools drive the game without key presses: `game.py` launches it, loads a save, runs exec functions and reads the script log ([game-automation.md](game-automation.md)).

1. **rw3d_cli** (the script debugger's command-line client), into `tools/rw3d/` (git-ignored): `gh release download v0.8.0 -R SpontanCombust/rusty_witcher_debugger -p "*windows-msvc.zip" -D tools/rw3d`, then unzip it there ([rw3d_cli](game-automation.md#rw3d_cli)).
2. **modAutomation** (the test-only helper mod, source in `tools/automation/`): `python tools/build_mod.py --scripts tools/automation/scripts --name modAutomation --out build/automation --install --enable --parent`.
3. **A Ghost Mode test build:** `python tools/build_mod.py --install-from build/master-<commit> --enable`.
4. **The test saves:** make the two saves and name them in the slot's config (`python tools/game_lock.py config --test-save NAME --slot-save NAME`), as [Test saves](game-automation.md#test-saves) describes. `game.py run` loads only these.
5. **Try it** (Steam running): `python tools/game.py run test`, `python tools/game.py exec "autoplayer()"`, `python tools/game.py quit`. The game window takes the screen while it runs, but needs no input.

## 4. Before the first turn: the settings baseline

A turn's release puts the game's settings files back, so options a test changed never reach the next agent or your own play. With the game closed and its settings as you play: `python tools/game_lock.py baseline --parent` ([game-automation.md](game-automation.md#the-game-slot)). A grant needs it.

## 5. Parallel agents

- **Agent directions:** copy [CLAUDE.md.public](../CLAUDE.md.public) to `CLAUDE.md` (git-ignored) to give an AI coding agent such as Claude Code this project's directions, and add your own below them. The Claude Code skill in [.claude/skills/w3-game-automation](../.claude/skills/w3-game-automation/SKILL.md) teaches it the game loop.
- **Roles:** one *parent* agent plans the work, creates a worktree per area and watches the slot (`game_lock.py watch`, `preempt --parent`, `reclaim --parent`); *area* agents build in their worktree and queue for the game (`game_lock.py request`, `wait`, `--holder AREA:TOKEN` on every command, `release`). The procedure: [Working in parallel](development.md#working-in-parallel), with the design in [proposals/parallel-ports.md](proposals/parallel-ports.md).
- **The regression run** (all of Ghost Mode's checks, both skill trees): `python tools/regress.py --holder AREA:TOKEN --trees both`.

## What stays on the machine

Not in the repository: the slot's state, config and logs (`%LOCALAPPDATA%\TGM`), the save backup each grant makes (`%USERPROFILE%\W3SaveBackup`), rw3d_cli, the builds (`build/`) and your `CLAUDE.md` and `CLAUDE.local.md`.
