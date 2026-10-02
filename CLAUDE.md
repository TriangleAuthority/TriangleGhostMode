# CLAUDE.md

Porting the Witcher 3 mod Ghost Mode from the legacy game (1.32) to game version 5.x.

Read [README.md](README.md) for the project's purpose and branch layout, then [docs/README.md](docs/README.md), which indexes the rest (repository workflow, 5.x changes, per-file port status, binary files, tools).

Before writing or changing mod code, read [docs/development.md](docs/development.md): how to make changes on 5.x (script annotations such as `@wrapMethod`/`@replaceMethod`, XML overrides with `on_conflict` through a DLC, DLC mounters), the project's conventions, and the build, compile-check and in-game test loop. Port work follows [docs/feature-mapping.md](docs/feature-mapping.md): small steps, each verified in game.

To launch the game, run something in it or test in game, use the `w3-game-automation` skill (`.claude/skills/w3-game-automation/`): `tools/game.py` drives the game without key presses or screenshots. Details in [docs/game-automation.md](docs/game-automation.md).

## Keeping docs current

The docs are the project's authoritative reference, not a log. Keep them accurate as the work teaches us things:

- **When:** update the docs at milestones (a pilot slice or feature verified, a tool working, a decision made) and before pausing or ending a session. Do not write running notes while still exploring.
- **How:** revise what is already there so it states the current knowledge, and delete what turned out wrong. Record the result, not the path to it: no narrative of attempts or intermediate steps. A failed approach belongs in the docs only as a short rule or pitfall that saves a future session from repeating it (e.g. "the attribute is `on_conflict`; the changelog's `onConflict` is ignored").
- **Where:**

  | Finding | Doc |
  |---|---|
  | How to write, build or test mod code | [docs/development.md](docs/development.md) |
  | Facts about the game (5.x vs legacy) | [docs/game-5.0-changes.md](docs/game-5.0-changes.md) |
  | Project tools | [docs/tools.md](docs/tools.md), automated game runs in [docs/game-automation.md](docs/game-automation.md) |
  | Questions not answered yet | [docs/open-questions.md](docs/open-questions.md); move answers into the doc they belong to and delete the entry |
  | Port and feature progress, pilot status | [docs/feature-mapping.md](docs/feature-mapping.md) (and `docs/features/` once it exists) |
  | Lasting decisions (e.g. the New Game+ policy) | The doc they govern, plus [README.md](README.md) if they change the project's scope |

- **Status labels:** mark claims as **verified** (tested in game), **compiles** (accepted by the compile check only) or **unverified** (from documentation or other sources), and upgrade them as tests confirm things (see [docs/development.md](docs/development.md)).
- New docs go into the index in [docs/README.md](docs/README.md).

Binary game files (`.w2ent`, `.journal`, `.w2scene`, ...) show up as text in `git diff`/`git show`/`git log -p` through the `cr2w` diff driver. It needs a one-time setup per clone; if `git config --get diff.cr2w.textconv` prints nothing, enable it as described in [docs/tools.md](docs/tools.md#git-and-github).
