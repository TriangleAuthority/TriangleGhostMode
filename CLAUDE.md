# CLAUDE.md

Porting the Witcher 3 mod Ghost Mode from the legacy game (1.32) to game version 5.x.

Read [README.md](README.md) for the project's purpose and branch layout, then [docs/README.md](docs/README.md), which indexes the rest (repository workflow, 5.x changes, per-file port status, binary files, tools).

To see where the port stands and what to do next, start at [docs/features/README.md](docs/features/README.md#where-the-port-stands).

Before writing or changing mod code, read [docs/development.md](docs/development.md): how to make changes on 5.x (script annotations such as `@wrapMethod`/`@replaceMethod`, XML overrides with `on_conflict` through a DLC, DLC mounters), the project's conventions, and the build, compile-check and in-game test loop. Port work follows [docs/feature-mapping.md](docs/feature-mapping.md): small steps, each verified in game.

**Ghost Mode supports both of 5.x's skill trees** (the classic tree, behind a hidden setting, and the new one). Anything that touches skills is ported, and tested, for both; see [docs/feature-mapping.md](docs/feature-mapping.md#two-skill-trees).

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

- **Record every deviation from legacy when it is made:** whenever the port differs from legacy Ghost Mode's code or its changelist (a fix, a kept 5.x behaviour, a changed rule), record it in the feature entry's **Decisions** as its own bullet, `- **Deviation:** what and why (who, date)`; one the owner has not confirmed says "porter's call, not confirmed by the owner", a temporary one "temporary, until <area>". Regenerate the list with `python tools/deviations.py --write` in the same commit. Where only running legacy could show how it actually played, also add it to [docs/open-questions.md](docs/open-questions.md#to-test-in-legacy-ghost-mode). See [legacy behaviour first](docs/feature-mapping.md#legacy-behaviour-first).
- **Working notes go to Mnemosyne:** detailed notes (investigation evidence, per-slice verification detail, notes on open questions while they are open, session handoffs) go into the local `mnemosyne` MCP store, tagged with project `TriangleGhostMode`, feature ID, date and the commit they refer to. This project has the owner's standing permission to store and recall there without asking (an exception to the global "only when asked" rule). The repo docs stay authoritative and lean, and the open questions themselves stay in [docs/open-questions.md](docs/open-questions.md): nothing a reader needs exists only in Mnemosyne. No secrets. *(To be sanitized before the repo goes public.)*
- **Status labels:** mark claims as **verified** (tested in game), **compiles** (accepted by the compile check only) or **unverified** (from documentation or other sources), and upgrade them as tests confirm things (see [docs/development.md](docs/development.md)).
- New docs go into the index in [docs/README.md](docs/README.md).

Binary game files (`.w2ent`, `.journal`, `.w2scene`, ...) show up as text in `git diff`/`git show`/`git log -p` through the `cr2w` diff driver. It needs a one-time setup per clone; if `git config --get diff.cr2w.textconv` prints nothing, enable it as described in [docs/tools.md](docs/tools.md#git-and-github).
