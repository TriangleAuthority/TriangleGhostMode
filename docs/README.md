# Docs

Start here when picking up work on the Ghost Mode 5.0 port.

| Doc | What it covers |
|---|---|
| [repository.md](repository.md) | Branch layout, keeping branches up to date, how to diff, encodings and line endings, the porting workflow, regenerating the vanilla baselines |
| [game-5.0-changes.md](game-5.0-changes.md) | Observed differences between the legacy game (1.32) and 5.0: install layout, bundle format, encodings, file structure, gameplay systems |
| [5.x-file-status.md](5.x-file-status.md) | Generated per-file status of every Ghost Mode file against 5.x (regenerate with `python tools/port_status.py`) |
| [development.md](development.md) | How to write, build and test the port: port forms (script annotations, XML `on_conflict` overrides, DLC mounters, whole-file overrides), conventions, `tools/build_mod.py` with its compile check, testing in game |
| [game-automation.md](game-automation.md) | Automated game runs with `tools/game.py` (launch, load a save, run exec functions, quit in about 30 s, no key presses): the test-only `modAutomation`, rw3d_cli, startup screens, and what failed along the way |
| [console-commands.md](console-commands.md) | Generated catalog of the game's 874 console commands (vanilla exec functions) by topic: signature, what each calls, source line; tested ones marked (regenerate with `python tools/exec_catalog.py`) |
| [open-questions.md](open-questions.md) | Unanswered questions about modding 5.x (e.g. how several mods' script blobs merge), why they matter and how to test them |
| [feature-mapping.md](feature-mapping.md) | How we map Ghost Mode's changes to features and classify each against 5.x (change units, pillars, classification, the `docs/features/` layout, phases), and how to port in small steps checked in game, starting with a pilot |
| [features/](features/README.md) | **Where the port stands and what's next**, and the feature map: design pillars, feature entries per area (with 5.x analysis and port plan; the latest mapped, [diff.md](features/diff.md): difficulty modes, enemy scaling options, fake levels, Ciri), the player power and balance rules ([balance.md](features/balance.md)) with their reference ledger, the generated change unit inventory and attribution coverage, and the generated list of deviations from legacy |
| [skill-trees/](skill-trees/) | Both games' skill trees and mutations at max level, with tooltip texts and numbers ([legacy](skill-trees/legacy-skill-tree.html), [5.x](skill-trees/5x-skill-trees.html)), and SKL's decisions with one row per skill of every tree ([skl-decisions.md](skill-trees/skl-decisions.md), where the decisions are kept); generated 2026-10-05 from the code |
| [binary-files.md](binary-files.md) | What Ghost Mode's binary files (`.w2ent`, `.journal`, scenes, ...) are, what it changed in them, and how to inspect them |
| [tools.md](tools.md) | Tools used on this project: what they do, where they are, how to run them; git setup, including the `cr2w` diff driver that shows binary game files as text in diffs |
| [legacy-ghost-mode.md](legacy-ghost-mode.md) | The legacy mod itself: the 4.1 release, its dependencies (Shared Imports, Community Patch – Base), how the release was packaged, where it stores settings and save data, and gaps in the vanilla baselines |
| [legacy-FullChangelist.txt](legacy-FullChangelist.txt) | Ghost Mode 4.1's full changelist from the Nexus release: every change the mod makes, feature by feature. The best starting point for deciding what to port |
| [legacy-ModDescription.txt](legacy-ModDescription.txt) | Ghost Mode 4.1's mod description from the Nexus release: its goals and main features |
| [legacy-readme.md](legacy-readme.md) | The original Ghost Mode README, verbatim (legacy build and install instructions) |

`design-docs/` (on the Ghost Mode branches) holds Ghost Mode's original design notes (part English, part Russian, not fully accurate).
