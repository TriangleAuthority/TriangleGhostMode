# Ghost Mode for The Witcher 3 — 5.0 port

Ghost Mode is a gameplay overhaul for The Witcher 3 by wghost. The last release, v4.0, targets the **legacy** game (patch 1.32) and does not work on current versions.

This repository exists to port Ghost Mode to **game version 5.0** (the 2026 "Remastered" update). Version 5.0 changes a lot of what Ghost Mode touches: skills were reworked into a ranked tree with prerequisites, monster combat behaviour was reworked, and most scripts, XML files and binary resources changed. Some Ghost Mode features may no longer make sense, and some may already exist in the base game in another form.

The goal is to carry over the spirit of Ghost Mode wherever possible. Port what is still compatible or still makes sense, adapt what needs adapting, and drop what 5.0 makes redundant, always following the original vision of the mod.

**First version: legacy behaviour.** Legacy Ghost Mode was tested thoroughly for balance, so the first version of the port reproduces its behaviour, including its rules' limits and side effects, and does not improve on it without a good reason (for example a 5.x change that would otherwise break a rule's intent, or a bug that makes a feature not work). Improvements found along the way are recorded with the feature, for after the first version (decision 2026-10-03). See [docs/feature-mapping.md](docs/feature-mapping.md#legacy-behaviour-first).

**Both skill trees.** 5.x keeps the classic skill tree (hidden setting) beside its new one. The port supports both: the classic tree for the most faithful Ghost Mode, the new tree with Ghost Mode's rules adapted to it (decision 2026-10-03). See [docs/feature-mapping.md](docs/feature-mapping.md#two-skill-trees).

**New Game+: changes carried over and scaled, but not balanced or tested.** The port applies Ghost Mode's changes to the New Game+ data as well, scaling its numbers the way vanilla scales them from a normal game to NG+ (a reasonable effort, not a tuned NG+ experience). Only regular playthroughs are balanced and tested; NG+ is not tested at all, not even for crashes. Extending the port properly to NG+ is left to whoever wants to take it on after the port is done. See [docs/feature-mapping.md](docs/feature-mapping.md#new-game-carried-over-and-scaled-not-balanced-or-tested).

**Installed at the start of a playthrough.** Adding Ghost Mode to a save, or removing it, in the middle of a playthrough is not supported (decision 2026-10-18). See [docs/feature-mapping.md](docs/feature-mapping.md#save-compatibility).

## How this repository is organised

The git history is built so that every change is visible as a diff. Every branch starts from the same root commit, the legacy (1.32) game files:

| Branch | Contents |
|---|---|
| `vanilla-1.32` | Unmodified legacy (1.32) game files at the mod's paths: the baseline every other branch starts from |
| `legacy-GM` | `vanilla-1.32` + the original Ghost Mode v4.1 and its two dependencies |
| `vanilla-5.x` | `vanilla-1.32` + the same game files from the current 5.x release (now Steam build 26238013, `witcher3.exe` 5.0.0.1090142) |
| `master` | `vanilla-5.x` + the port (work in progress), plus the README, tools and docs |

- What Ghost Mode changed: `git diff vanilla-1.32...legacy-GM`
- What CDPR changed in 5.x: `git diff vanilla-1.32...vanilla-5.x`
- The port so far: `git diff vanilla-5.x...master -- modGhostMode`

A new 5.x release lands on `vanilla-5.x` first; `master`'s port is then rebased onto it. See [docs/repository.md](docs/repository.md).

`modGhostMode/` on `legacy-GM` and `master` contains the full vanilla file set with the mod's changes applied, so it is a reference tree, not a ready-to-install mod.

## Documentation

See [docs/](docs/README.md), in particular:

- [docs/repository.md](docs/repository.md): branches, encodings, porting workflow
- [docs/game-5.0-changes.md](docs/game-5.0-changes.md): what changed in 5.0 that affects porting
- [docs/5.x-file-status.md](docs/5.x-file-status.md): per-file status of every Ghost Mode file against 5.x (generated)
- [docs/binary-files.md](docs/binary-files.md): what Ghost Mode's binary files (`.w2ent` and others) do and how to inspect them
- [docs/tools.md](docs/tools.md): tools, where to find them and how to use them, and git setup (including the diff driver for binary files)
- [docs/legacy-readme.md](docs/legacy-readme.md): the original Ghost Mode README (legacy build and install instructions)

`design-docs/` (on `legacy-GM`) holds Ghost Mode's original design documents (not very well structured, not 100% accurate, part English, part Russian).
