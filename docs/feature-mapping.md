# Feature mapping: how we map Ghost Mode's changes for the 5.x port

The goal is a record of **which changes in Ghost Mode are responsible for which gameplay change**, and what 5.x means for each of them. With that record we can port big systems and small fixes in a deliberate order instead of file by file.

This doc defines the method, the format, and how porting proceeds: in small steps, each run in the game before the next. The map itself lives in `docs/features/` (see [Layout](#layout)).

## Why files are the wrong unit

[5.x-file-status.md](5.x-file-status.md) tracks files, but a file is not a feature. `playerWitcher.ws` or `geralt_skills.xml` each hold dozens of unrelated Ghost Mode changes. A single feature, such as sign cooldowns, spans scripts, XML, the options menu and localization at once.

The map therefore works at two levels:

- **Change unit**: the smallest thing Ghost Mode changed that can be judged on its own:
  - scripts (`.ws`): a function, method, or class/struct/enum declaration
  - XML: one top-level entry, such as an `<ability name=...>`, `<item name=...>`, loot definition or `<var>`
  - CSV: one row
  - binary (`.w2ent`, ...): one changed property, as reported by `tools/bindiff.py`
  - new files: the whole file
- **Feature**: one player-facing change (or one fix), built from one or more change units. A unit can belong to more than one feature.

## What counts as Ghost Mode

`legacy-GM` has three commits (see [legacy-ghost-mode.md](legacy-ghost-mode.md)): Shared Imports v0.6, Community Patch – Base v1.0, then Ghost Mode 4.1. **For simplicity the map treats all three as Ghost Mode**: the unit inventory covers `master...legacy-GM`.

Every unit records which commit it came from (`SI`, `CPB` or `GM`), so the dependency changes can be filtered out in one step.

> **Expected outcome for `SI` and `CPB` units:** throw them out. Shared Imports is built into 5.0. Most of Community Patch – Base is in 5.0 too, and what is missing (community hub support in `areaTypes.ws`, `types.ws`, `igmStructureCreator.ws`) is probably not needed. Confirm this per unit during the 5.x analysis, but do not spend design effort on them.

Ghost Mode marks most of its script edits with `//modSigns` comments (about 2,270 of them). The inventory records whether each script unit has one. A changed unit without a marker is not necessarily wrong, but it is worth a look: it may be a re-save artifact, a dependency change, or an unmarked edit.

## New Game+: carried over and scaled, not balanced or tested

**The port balances and tests regular playthroughs only, but carries Ghost Mode's changes over to New Game+ as well.** Concretely:

- **Applied:** every change made to regular-game data is also made to its New Game+ counterpart, so NG+ gets the same rules, mechanics and fixes.
- **Scaled like vanilla, as a reasonable effort:** Ghost Mode's change to a number is applied to vanilla's NG+ value, so Ghost Mode's NG+ relates to vanilla NG+ the way Ghost Mode's normal game relates to vanilla's (see [NG+ numbers](#ng-numbers) below). This is not a tuned NG+ experience.
- **Not tested:** NG+ is not tested at all, not even for crashes.
- **Left for later:** once the port is finished, extending it properly to NG+ (balance and testing) is up to whoever wants to take it on.

Legacy Ghost Mode 4.1 handled NG+ the same way: it called NG+ "supported, but not recommended" and mirrored many of its changes into the NG+ files.

In the game data, folders named `*_plus` that have a sibling without the suffix hold the NG+ variants of definitions: `gameplay/abilities_plus/`, `gameplay/items_plus/`, and the same under `dlc/*/data/gameplay/`. In a regular game the game reads the folder without the suffix (verified in pilot slice 3a: with different values in `abilities/` and `abilities_plus/`, a normal save used the `abilities/` value).

For the map:

- Legacy Ghost Mode changed **153 files in `*_plus` folders**. Their units are flagged in the inventory (`ngplus` column in `units.csv`) and attributed to the same features as their regular-game counterparts.
- A feature's port includes its NG+ counterpart changes. Its in-game check covers the regular game only, and its entry notes that NG+ is untested.
- Changes Ghost Mode made only in the NG+ files (with no regular-game counterpart) get a feature of their own, so they are not lost.

### NG+ numbers

For a numeric value, keep Ghost Mode's change relative to vanilla, and apply it to vanilla's NG+ value:

> GM NG+ = vanilla NG+ × (GM NG ÷ vanilla NG)

Example: Ghost Mode doubles an enemy's damage compared with vanilla, and vanilla NG+ doubles that enemy's damage compared with vanilla NG. Ghost Mode's NG+ damage is then double vanilla NG+, i.e. four times vanilla NG.

Edge cases, decided case by case with a reasonable effort:

- **Vanilla NG and NG+ are the same:** use Ghost Mode's NG value.
- **The vanilla NG value is 0, or the value is a level or offset rather than a magnitude** (a ratio makes no sense): apply Ghost Mode's difference instead (GM NG+ = vanilla NG+ + (GM NG − vanilla NG)).
- **Non-numeric changes** (abilities added or removed, tags, categories, loot entries): make the same change in NG+.
- **Rounding:** round to the precision vanilla uses for that value.

The [balance tables](#balance-tables) show vanilla NG+ and the resulting Ghost Mode NG+ value next to the regular columns, so the scaling can be applied and checked mechanically.

## Two layers: pillars and features

Porting has two halves: carrying over Ghost Mode's **philosophy and play style**, and **re-balancing** the numbers for 5.x. The map keeps them apart.

1. **Design pillars**: the 8–12 principles Ghost Mode is built on, taken from [legacy-ModDescription.txt](legacy-ModDescription.txt) and the changelist. Examples (to be finalized in `docs/features/pillars.md`):
   - Armor must be penetrated before attack power counts (no damage snowballing).
   - Every combat action costs stamina.
   - Signs have cooldowns.
   - Armor classes are distinct (light, medium, heavy) and have real trade-offs.
   - Enemy types are distinct in armor, resistances and dodging.
   - Loot and money are scarce.
   - Descriptions match what things actually do.
   - Stay close to vanilla in spirit and basics.

   Every feature names the pillars it serves. When 5.x breaks the *implementation* of a feature, the pillar is what we preserve, and the mechanism gets rebuilt on 5.x's systems.
2. **Features**: concrete changes, each with an ID, the units that implement it, and a 5.x classification.

Balance values sit across both layers. See [Balance tables](#balance-tables).

## Classifying features

### Kind of change

| Kind | Meaning | Examples |
|---|---|---|
| `fix` | Fixes a vanilla bug, no design intent beyond that | Undying skill not working, oils stuck on blades |
| `system` | New or reworked mechanics (code) | Damage formula, stamina-based combat, sign cooldowns |
| `tuning` | Numbers only | Skill values, potion durations, enemy stats |
| `content` | Data placement: levels, loot tables, prices, spawns, monster categories | Lesser mutagens removed from monster loot |
| `ui` | Descriptions, tooltips, menus, tutorials | Rewritten skill descriptions |
| `infra` | Support code other features rely on | Options menu, config reading, localization, shared helpers |

### 5.x classification

| Class | Meaning | Default action |
|---|---|---|
| `clean` | Merges or applies mechanically, and the idea still holds in 5.x | Carry over, then review |
| `conflict` | Code or file structure conflicts with 5.x, but the idea still holds | Re-implement on the 5.x code |
| `in-5.x` | 5.x already fixes or implements the same thing | Drop (note where 5.x does it) |
| `overlap` | 5.x addresses the same problem in a different way | Decide: Ghost Mode's way, 5.x's way, or a hybrid |
| `rethink` | What Ghost Mode changed was replaced or redesigned in 5.x (e.g. a reworked skill, a new skill tree) | Redesign from the pillars |
| `obsolete` | The underlying feature was removed in 5.x (e.g. old focus-mode scripts, the drinking minigame) | Drop |

Two extra flags:

- **`balance`**: the feature's numbers will need re-tuning once the systems it depends on are ported.
- **`needs-decision`**: the classification or action is a design call for the project owner, not just analysis. All `overlap` and `rethink` features carry it.

## Feature IDs and areas

Features are grouped into areas that follow the sections of [legacy-FullChangelist.txt](legacy-FullChangelist.txt). Each area has a short prefix, and IDs are numbered within it (`DMG-01`, `STAM-03`). IDs are never reused or renumbered.

| Prefix | Area | Prefix | Area |
|---|---|---|---|
| `FIX` | Bugfixes | `ALCH` | Alchemy (bombs, potions, decoctions) |
| `DMG` | Damage formula | `FOOD` | Edibles |
| `STAM` | Stamina | `EFX` | Effects |
| `SKL` | Skills (sword, signs, alchemy, perks) | `ITEM` | Other items |
| `GEN` | General player abilities | `TRPH` | Trophies |
| `HORSE` | Horse combat | `LOOT` | Loot |
| `DEF` | Dodging, parrying, countering | `WGT` | Weight |
| `ARM` | Armor and set bonuses | `ECON` | Money and economy |
| `SWD` | Swords | `ENCH` | Enchantments (runewords, glyphwords) |
| `CRAFT` | Crafting | `MUT` | Mutations |
| `XBOW` | Crossbow | `XP` | Experience |
| `AI` | Enemy AI | `DIFF` | Difficulty modes and enemy scaling |
| `UI` | UI | `OPT` | Mod options |
| `DEP` | Shared Imports and Community Patch – Base | `INFRA` | Shared support code |

Sources for the feature list: the changelist (primary), the 77 original commit subjects in the Ghost Mode 4.1 commit message, `design-docs/` on `legacy-GM`, and any units nobody can attribute (these become new features, marked as undocumented).

## Layout

```
docs/
  feature-mapping.md          this doc
  features/
    README.md                 index of areas, progress per area, features with a save impact
    pillars.md                the design pillars
    <area>.md                 feature entries for one area (dmg.md, stam.md, ...)
    units.csv                 generated: every change unit (do not edit by hand)
    attribution.csv           hand-maintained: unit -> feature ID(s)
    coverage.md               generated: unattributed units, features without units
    balance/                  generated balance tables
tools/
  change_units.py             builds units.csv and coverage.md (balance tables: not yet)
```

### `units.csv` (generated)

One row per change unit:

| Column | Content |
|---|---|
| `unit` | Stable key `<path under modGhostMode>::<name>`. Scripts: `Class.Method`, `Class.<members>` (fields and defaults), a global function's name, a struct or enum name, `<file>` for leftovers; states as `<Class>State<State>`, the name annotations use (e.g. `scripts/game/gameParams.ws::W3GameParams.GetSignCooldownDuration`). XML: the element path and its name (`files/gameplay/abilities/effects.xml::definitions/abilities/ability:AardCooldownEffect`). CSV: `row:<first column>`. Binary: `<file>` |
| `type` | `ws`, `xml`, `csv`, `bin`, `other` |
| `change` | `modified`, `added` (not in legacy vanilla), `removed` (by Ghost Mode) |
| `origin` | Which legacy-GM commits changed it: `SI`, `CPB`, `GM` |
| `marked` | Script units: the Ghost Mode version has a `//modSigns` marker |
| `lines` | Changed statements in the unit, `+added/-removed` (scripts, CSV) |
| `vanilla_5x` | What 5.x did to the vanilla unit: `unchanged`, `changed`, `removed`; `new` when Ghost Mode added it and 5.x has a unit with the same key |
| `overlap` | `yes` when both Ghost Mode and 5.x changed the unit: its port needs a hand merge |
| `ngplus` | The unit is in a `*_plus` (New Game+) folder: attributed like any unit, but [not balanced or tested](#new-game-carried-over-and-scaled-not-balanced-or-tested) |
| `gm_line` | First line of the unit in the Ghost Mode file |

Comments and whitespace never count as changes. Binary files are one unit each for now; splitting them by property (with `tools/bindiff.py`) is left for when an area needs it.

Unit keys are stable across regenerations, so attribution survives re-running the tool, including after a new 5.x release lands on `vanilla-5.x`.

### `attribution.csv` (hand-maintained)

`unit,features,note`, where `features` is a space-separated list of IDs. It is kept separate from `units.csv` so regenerating never loses work. `coverage.md` lists units that are missing from it and features that no unit points to. The map is complete when there are no unattributed units.

Bulk binary changes do not need one row per file: a unit key may use a glob (`files/**/*.w2ent::CR4LootParam:_monster_add__Mutagens_lesser`) for a change applied the same way to many files.

### Feature entry template

Each `<area>.md` has an intro (what Ghost Mode does in this area, and what 5.x changed there), then one entry per feature:

```markdown
### STAM-01 Stamina cost for light and heavy attacks

| | |
|---|---|
| Kind | system |
| Pillars | Every combat action costs stamina |
| 5.x class | overlap |
| Flags | balance, needs-decision |
| Depends on | OPT-01 (stamina mode option), INFRA-02 |
| Port form | annotation (see [development.md](development.md#port-forms)) |
| Port status | not started |
| Save impact | none (expected) |
| NG+ counterpart | applied and scaled, untested / none |
| Verified in game | — (5.x version, date, what was tested) |

**What it does:** player-facing behaviour, and why Ghost Mode wanted it (cite the changelist).

**Implementation:** which units do what. List the key units; the full list is in attribution.csv.

**5.x:** what 5.x does in this area, with evidence (5.x diff, patch notes, in-game test).

**Decision:** port as-is / adapt / drop / redesign, and why. Open questions.

**Balance values:** link to the balance table rows involved.
```

Port status values: `not started`, `in progress`, `ported` (committed on `5.x-GM`, not yet run), `verified` (passed the [in-game check](#small-steps-verified-in-game)), `dropped`, `deferred`.

## Balance tables

Generated from the XML and the binary units, one table per domain (skills, signs, potions, weapons, armor, enemies, economy). Each row shows a value in **legacy vanilla, Ghost Mode and 5.x**, plus **Ghost Mode's change relative to vanilla** (ratio or delta). Where the value has an NG+ counterpart, the row also shows the **vanilla NG+ value and the Ghost Mode NG+ value** derived from it (see [NG+ numbers](#ng-numbers)).

Recording the relative change matters because 5.x rebalanced many base values. "Ghost Mode made this 50% stronger than vanilla" can be re-applied to a new 5.x baseline. A copied absolute number cannot.

Balance is tuned **last**: after the systems the values depend on are ported, and with in-game testing.

## Phases

1. **Inventory.** Write `tools/change_units.py` and generate `units.csv` for scripts, XML and CSV, plus binary properties via `bindiff.py`. Check how the unit counts compare with [5.x-file-status.md](5.x-file-status.md).
2. **Catalogue.** Write `pillars.md`, then create every area file with feature stubs (ID, name, kind, pillars) from the changelist and commit subjects.
3. **Attribution.** Area by area, assign units to features in `attribution.csv` until `coverage.md` is empty. Unattributed units become new features or are noted as noise (re-save artifacts, formatting). `SI` and `CPB` units go to `DEP` features.
4. **5.x analysis.** For each feature, read the 5.x side (the 5.x diff of the same units, new 5.x scripts, patch notes) and fill in the 5.x class, evidence and a proposed action. `overlap` and `rethink` decisions, and anything system-level, go to the project owner for review.
5. **Port roadmap.** Order the work by dependencies, then port it in [small, verified steps](#small-steps-verified-in-game):
   1. infrastructure: options menu, config, localization, `gm_bugfixes.ws`
   2. core systems: damage formula, stamina, sign cooldowns, dodging and parrying
   3. skills: the skill tree redesign (largest rethink; a design exercise)
   4. items: armor, swords, alchemy, crafting, enchantments, mutations
   5. enemies: AI, abilities, binary entity data
   6. progression and economy: experience, loot, prices, difficulty
   7. balance pass, with in-game testing

## Small steps, verified in game

Mapping can run ahead, but **porting moves in small steps, and each step is run in the game before the next one starts**. A broken script stops the whole script set from compiling, and a bad resource can crash the game. When a step is small, a failure points straight at its cause.

**What a step is:**

- One feature, or one slice of a feature (e.g. the cooldown effect script before the menu option that configures it). Where a feature is too big, split it into slices that each compile and run on their own, using hard-coded defaults until the pieces they depend on exist.
- One commit (or a few) on `5.x-GM`, with the feature IDs in the commit message, and the [save impact](#save-compatibility) if it is not `none`.
- No mixing: no unrelated fixes, and no reformatting of code the step does not need to touch.

**The in-game check**, done for every step before the next one:

1. Build, compile-check and install the mod with `tools/build_mod.py` (see [development.md](development.md#build-compile-install)). The compile check runs the game's script compiler without starting the game, so script errors are caught here.
2. The scripts compile in game too: the game starts without a script compilation error.
3. The game reaches the main menu, then starts a new game or loads a test save, without crashing. If the step's save impact is `none`, loading an existing save is part of the test. Otherwise apply what it says (e.g. run `cleardevelop`) and confirm that it is enough.
4. The changed behaviour works, as far as it can be tested at that point (check the feature's "What it does").
5. A quick check of nearby features ported earlier, to catch regressions.

Record the result in the feature entry ("Verified in game") and set its port status to `verified`. If the check fails, fix that step or revert it. Do not build more on top of it.

Checks that need specific game situations (a certain enemy, a late-game item) get console commands or a dedicated test save, and the run guide records how to set them up, so later checks can repeat them.

## Save compatibility

Some changes only take effect on a fresh character or on newly created items, because the game stores their old state in the save. Every ported feature records its **save impact**, from least to most disruptive:

| Save impact | When | What the player does |
|---|---|---|
| `none` | Scripts and definitions the game reads live | Nothing; existing saves pick it up |
| `reacquire items` | Item stats or abilities that are copied onto an item when it is created, so items already in the inventory keep the old values | Drop and pick up, re-craft or re-spawn the affected items |
| `cleardevelop` | Character development stored in the save: skills, skill tree layout, skill points, the experience curve, abilities granted to the player | Run the `cleardevelop` console command, which resets the character's level, skills and abilities so they are rebuilt under the new rules |
| `new game` | Anything a save cannot be fixed for: world or quest state already passed, entities already spawned with old data, changes `cleardevelop` does not reset | Start a new game |

Rules:

- Record the impact when the feature is analysed (*expected*), and confirm it during the in-game check (*confirmed*). The entry shows which: `cleardevelop (expected)`, `none (confirmed)`.
- **`new game` should be extremely rare.** Treat it as `needs-decision`: before accepting it, look for an alternative, such as a fix-up that runs when a save is loaded (Ghost Mode's `gm_bugfixes.ws` is an example of this kind of code), or limiting the change to content the player has not reached yet. If none works, the project owner decides.
- Legacy Ghost Mode already asked players to run `cleardevelop` when moving an existing save to the mod, and to re-craft items to get the new stats ([legacy-ModDescription.txt](legacy-ModDescription.txt)). Expect the skills, perks and experience changes to need `cleardevelop` again.
- `docs/features/README.md` keeps a running list of every feature whose impact is not `none`, so it can go straight into release notes and the install instructions.

## Pilot

Run the whole process on one small area before doing the others: mapping (phases 1–4), and then the port itself, in small steps through the in-game check. The pilot also answers an open question: **how to install a mod on 5.x and run the game with it** (see the *unverified* items under "Mod support" in [game-5.0-changes.md](game-5.0-changes.md)).

1. **Smoke test the toolchain** before porting anything, in slices on the throwaway `pilot-smoke` branch, each through the in-game check:
   1. Scripts: a new file using annotations (`@addField`, `@addMethod`, `@wrapMethod`) and a console command, plus one whole-file override of a vanilla script. *Done: verified in game 2026-10-01.*
   2. Scripts: the 5.0 scope-based override syntax, enum extensions, `@replaceMethod`, and wrapping state functions. *Done: verified in game 2026-10-01.* Found that scope-based overrides and enum extensions only work from a precompiled script blob, which replaces the mod's loose scripts; Ghost Mode therefore ships as a blob (see [development.md](development.md#how-the-game-loads-mod-scripts)).
   3. XML, in two parts:
      1. A whole-file override of `geralt_skills.xml` packed into a bundle (`wcc_lite pack`, `metadata.store`). *Done: verified in game 2026-10-01.* Also showed that a regular game reads `abilities/`, not `abilities_plus/` (the NG+ variant).
         Open for slice 3b: does a DLC override of an entry (e.g. `sword_s1`) apply to the NG+ definitions too, or does NG+ need its own override?
      2. The same value changed through a Ghost Mode DLC (`.reddlc` with a `CR4DefinitionsDLCMounter`) using `on_conflict="extend"`. *Done: verified in game 2026-10-01, with `tools/game.py`.* The attribute is `on_conflict` (the changelog's `onConflict` is ignored); `extend` keeps the entry's other sub-nodes and `replace` drops them; the DLC ships inside the mod's bundle; `.reddlc` files are written by `tools/make_reddlc.py`.
   4. Localization: one new string, looked up by key and by id, and vanilla strings overridden by id. *Done: verified in game 2026-10-01.* Strings are encoded by `tools/w3strings.py` (5.0 format) from the legacy CSV layout; Ghost Mode keeps its legacy IDs (2110992000–2110992999).
   5. Options menu: one new option, read from a script. *Done: verified in game 2026-10-01.* The game reads every menu XML in `bin\config\r4game\user_config_matrix\pc\` (no list file); values persist in `dx12user.settings`; checked by script with `modAutomation`'s `autoconfig`, plus one screenshot of the rendered menu.

   **The toolchain smoke test is complete.** The answers are in [development.md](development.md) (how to write, build and test the mod) and [game-automation.md](game-automation.md) (automated game runs); build and install are scripted in `tools/build_mod.py`.

   Find out:
   - where mods go (`Mods\<name>\content\...` or something new, such as mod.io)
   - how scripts get compiled and how compile errors show up
   - how XML and other resources get packed (bundle format and tools) and loaded
   - how options menus and localization strings get registered
   - how to read logs and use the console

   Record the answers in [development.md](development.md), and add build and install scripts to `tools/`.
2. **Map the pilot area.** Sign cooldowns plus stamina: they touch scripts, XML, the options menu and localization, and 5.x has its own `overloadCooldown.ws` to compare against. Inventory, attribution and 5.x analysis for just this area.
3. **Port it in slices**, each through the in-game check. For example: the cooldown effect scripts with hard-coded values, then the sign casting hooks, then the options menu entries, then localization, then the stamina costs.
4. **Review the process.** Update this doc, the entry template and the run guide based on what the pilot showed, then move on to the other areas.

After the pilot, mapping of different areas is independent and can be done in parallel. Porting stays sequential in dependency order, one verified step at a time.

## Keeping it current

- After a new game release lands on `vanilla-5.x`, re-run `tools/change_units.py`. Features whose units changed in the new release get their 5.x analysis re-checked.
- When a feature is ported on `5.x-GM`, update its port status and decision in the area file. After it passes the in-game check, set it to `verified` and record the check.
- The map lives on `master`, like the rest of the docs.
