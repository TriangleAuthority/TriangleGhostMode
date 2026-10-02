# Ghost Mode for The Witcher 3 — 5.0 port

Ghost Mode is a gameplay overhaul for The Witcher 3 by wghost. The last release, v4.0, targets the **legacy** game (patch 1.32) and does not work on current versions.

This repository exists to port Ghost Mode to **game version 5.0** (the 2026 "Remastered" update). Version 5.0 changes a lot of what Ghost Mode touches: skills were reworked into a ranked tree with prerequisites, monster combat behaviour was reworked, and most scripts, XML files and binary resources changed. Some Ghost Mode features may no longer make sense, and some may already exist in the base game in another form.

The goal is to carry over the spirit of Ghost Mode wherever possible. Port what is still compatible or still makes sense, adapt what needs adapting, and drop what 5.0 makes redundant, always following the original vision of the mod.

**New Game+: changes carried over and scaled, but not balanced or tested.** The port applies Ghost Mode's changes to the New Game+ data as well, scaling its numbers the way vanilla scales them from a normal game to NG+ (a reasonable effort, not a tuned NG+ experience). Only regular playthroughs are balanced and tested; NG+ is not tested at all, not even for crashes. Extending the port properly to NG+ is left to whoever wants to take it on after the port is done. See [docs/feature-mapping.md](docs/feature-mapping.md#new-game-carried-over-and-scaled-not-balanced-or-tested).

## How this repository is organised

The git history is built so that every change is visible as a diff:

| Branch | Contents |
|---|---|
| `master` | Unmodified legacy (1.32) game files at the mod's paths, plus the README, tools and docs shared by every branch |
| `legacy-GM` | `master` + the original Ghost Mode v4.0 (one commit) |
| `vanilla-5.x` | `master` + the same game files from the current 5.x release (now 5.0) |
| `5.x-GM` | `vanilla-5.x` + the port (work in progress) |

- What Ghost Mode changed: `git diff master...legacy-GM`
- What CDPR changed in 5.x: `git diff master...vanilla-5.x`

`modGhostMode/` on the Ghost Mode branches contains the full vanilla file set with the mod's changes applied, so it is a reference tree, not a ready-to-install mod.

## Documentation

See [docs/](docs/README.md), in particular:

- [docs/repository.md](docs/repository.md): branches, encodings, porting workflow
- [docs/game-5.0-changes.md](docs/game-5.0-changes.md): what changed in 5.0 that affects porting
- [docs/5.x-file-status.md](docs/5.x-file-status.md): per-file status of every Ghost Mode file against 5.x (generated)
- [docs/binary-files.md](docs/binary-files.md): what Ghost Mode's binary files (`.w2ent` and others) do and how to inspect them
- [docs/tools.md](docs/tools.md): tools, where to find them and how to use them, and git setup (including the diff driver for binary files)
- [docs/legacy-readme.md](docs/legacy-readme.md): the original Ghost Mode README (legacy build and install instructions)

`design-docs/` (on the Ghost Mode branches) holds Ghost Mode's original design documents (not very well structured, not 100% accurate, part English, part Russian).
