# Ghost Mode for The Witcher 3 — 5.x port

Ghost Mode is a gameplay overhaul for The Witcher 3 by wghost. The last release, v4.0, targets the **legacy** game (patch 1.32) and does not work on current versions.

This repository exists to port Ghost Mode to **game version 5.x** (the 2026 "Remastered" update and its patches). 5.x changes a lot of what Ghost Mode touches: skills were reworked into a ranked tree with prerequisites, monster combat behaviour was reworked, and most scripts, XML files and binary resources changed. Some Ghost Mode features no longer made sense, and some already existed in the base game in another form.

The goal is to carry over the spirit of Ghost Mode wherever possible. Port what is still compatible or still makes sense, adapt what needs adapting, and drop what 5.x makes redundant, always following the original vision of the mod.

**First version: legacy behaviour.** Legacy Ghost Mode was tested thoroughly for balance, so the first version of the port reproduces its behaviour, including its rules' limits and side effects, and does not improve on it without a good reason (for example a 5.x change that would otherwise break a rule's intent, or a bug that makes a feature not work). Improvements found along the way are recorded with the feature, for after the first version. See [docs/feature-mapping.md](docs/feature-mapping.md#legacy-behaviour-first).

**The classic skill tree, plus an optional new-tree mode.** 5.x keeps the classic skill tree, behind a hidden setting, beside its new one. The port of Ghost Mode is played on the classic tree: legacy Ghost Mode's skills, values and rules. It is the default, set by Ghost Mode's own option "Classic skill tree". Turning that option off switches to 5.x's new tree, in a mode that is not part of the port: it is the maintainer's own modding on top of Ghost Mode, which carries Ghost Mode's skills and rules onto the new tree with some new designs. Legacy Ghost Mode had nothing like it, so its differences are listed apart ([docs/features/deviations-new-tree.md](docs/features/deviations-new-tree.md)). See [docs/feature-mapping.md](docs/feature-mapping.md#two-skill-trees).

**New Game+: changes carried over and scaled, but not balanced or tested.** The port applies Ghost Mode's changes to the New Game+ data as well, scaling its numbers the way vanilla scales them from a normal game to NG+ (a reasonable effort, not a tuned NG+ experience). Only regular playthroughs are balanced and tested; NG+ is not tested at all, not even for crashes. Extending the port properly to NG+ is left to whoever wants to take it on after the port is done. See [docs/feature-mapping.md](docs/feature-mapping.md#new-game-carried-over-and-scaled-not-balanced-or-tested).

**Installed at the start of a playthrough.** Adding Ghost Mode to a save, or removing it, in the middle of a playthrough is not supported. See [docs/feature-mapping.md](docs/feature-mapping.md#save-compatibility).

**Status:** every area of Ghost Mode is ported and signed off; what is left (checks that need a playthrough, balance passes) is in [docs/features/README.md](docs/features/README.md#where-the-port-stands).

## Installing

Needs The Witcher 3 game version 5.x (PC). Legacy Ghost Mode's dependencies do not apply: 5.x contains what they provided.

**Install it before starting a new game.** Adding Ghost Mode to a playthrough in progress, or removing it from one, is not supported (see above).

1. **Get the zip** `modGhostMode-<version>.zip`: from a release once there is one, or build it from this repository with `python tools/build_mod.py --ref master --out build/release --package` (needs Python 3 and REDkit, see [docs/tools.md](docs/tools.md)); the zip is then in `build/release/`.
2. **Extract it into the game folder** `<game>` (the folder that holds `bin` and `content`), keeping its folders: it puts the mod into `<game>\mods\modGhostMode\` and its options menu into `<game>\bin\config\r4game\user_config_matrix\pc\modGhostMode.xml`. Nothing else in the game changes.
3. Start a new game. The options are under **Options → Mods → Ghost Mode** and start at Ghost Mode's defaults. "Classic skill tree" (in the Gameplay group) chooses the tree; changing it takes effect with a character reset.

## Using it with other mods (Script Merger)

**With the Friendly Meditation, Preparations and Gwent Improvements ports: nothing to merge.** They are built to run side by side with Ghost Mode as separate mods, in the default folder order (tested in game with Ghost Mode's full regression run).

**With other mods:** Script Merger merges *loose* scripts (`.ws` files) that two mods both edited. This port ships compiled scripts instead (`content\precompiled.rsblob`, built with 5.x's script annotations), which Script Merger cannot merge. Use it to find conflicts, not to fix Ghost Mode's:

1. Install all your mods first, Ghost Mode included.
2. Run Script Merger Remastered (the 5.x version of Script Merger, on Nexus Mods) and refresh the conflict list.
3. Merge the conflicts it can merge between your *other* mods as usual.
4. Conflicts that involve Ghost Mode are listed as "not mergeable": leave them unmerged. The game resolves them itself:
   - Where two compiled mods replace the same function, the mod whose folder name sorts first wins. To change that, give the mod you want to win a lower `Priority` in `Documents\The Witcher 3\mods.settings` (a section `[modGhostMode]` with `Priority=50`, for example; the default is 100).
   - Where a mod only adds code around a function, both mods' additions run.
   - A loose-script mod that edits the same function as Ghost Mode loses to it, whatever its priority.
5. Do **not** let Script Merger Remastered 3.x merge Ghost Mode's compiled scripts into a merged mod: in tests of that feature, compiled mods lost some of their changes.

**Another compiled mod that adds its own effect types** (or other members of a game enum) breaks Ghost Mode's effects when both are installed: the game numbers the two mods' additions in load order, so one mod's numbers shift. If the numbers clash, Ghost Mode and Preparations each say so in game a few seconds after a save loads: a message that another installed mod also adds effect types and that enum_sync.py should be run (and a line in the script log). `python tools/enum_sync.py apply` (from this repository) fixes the installed mods' compiled scripts so the numbers agree; run it again after installing, updating or removing such a mod. See [docs/tools.md](docs/tools.md). Not needed with the Friendly Meditation and Preparations ports: Friendly Meditation adds no effect types, and Preparations declares Ghost Mode's first, in Ghost Mode's order, then its own (so a new Ghost Mode effect type must be added to Preparations' copy in the same release).

If two mods still clash in game, keep the one you prefer first in the load order, or do not combine them.

## How this repository is organised

The git history is built so that every change is visible as a diff. Every branch starts from the same root commit, the legacy (1.32) game files:

| Branch | Contents |
|---|---|
| `vanilla-1.32` | Unmodified legacy (1.32) game files at the mod's paths: the baseline every other branch starts from |
| `legacy-GM` | `vanilla-1.32` + the original Ghost Mode v4.1 and its two dependencies |
| `vanilla-5.x` | `vanilla-1.32` + the same game files from the current 5.x release (now Steam build 26238013, `witcher3.exe` 5.0.0.1090142) |
| `master` | `vanilla-5.x` + the Ghost Mode port (the classic skill tree by default), plus the README, tools and docs |

- What Ghost Mode changed: `git diff vanilla-1.32...legacy-GM`
- What CDPR changed in 5.x: `git diff vanilla-1.32...vanilla-5.x`
- The port: `git diff vanilla-5.x...master -- modGhostMode`

A new 5.x release lands on `vanilla-5.x` first; `master`'s port is then moved onto it through a merge. See [docs/repository.md](docs/repository.md).

`modGhostMode/` on `legacy-GM` and `master` contains the full vanilla file set with the mod's changes applied, so it is a reference tree, not a ready-to-install mod.

## Documentation

See [docs/](docs/README.md), in particular:

- [docs/features/](docs/features/README.md): where the port stands, and the feature map with every feature's legacy and 5.x behaviour, decisions and deviations; every difference from legacy Ghost Mode is listed in [docs/features/deviations.md](docs/features/deviations.md) (the classic tree) and [docs/features/deviations-new-tree.md](docs/features/deviations-new-tree.md) (the new-tree mode)
- [docs/setup.md](docs/setup.md): setting up a new machine, from a fresh clone to building, testing in game by script and running AI agents in parallel
- [docs/repository.md](docs/repository.md): branches, encodings, porting workflow
- [docs/game-5.0-changes.md](docs/game-5.0-changes.md): what changed in 5.x that affects porting
- [docs/5.x-file-status.md](docs/5.x-file-status.md): per-file status of every Ghost Mode file against 5.x (generated)
- [docs/binary-files.md](docs/binary-files.md): what Ghost Mode's binary files (`.w2ent` and others) do and how to inspect them
- [docs/tools.md](docs/tools.md): tools, where to find them and how to use them, and git setup (including the diff driver for binary files)
- [docs/legacy-readme.md](docs/legacy-readme.md): the original Ghost Mode README (legacy build and install instructions)

`design-docs/` (on `legacy-GM`) holds Ghost Mode's original design documents (not very well structured, not 100% accurate, part English, part Russian).

Working with an AI coding agent such as Claude Code: [CLAUDE.md.public](CLAUDE.md.public) holds this project's directions for it; copy it to `CLAUDE.md` to use them.
