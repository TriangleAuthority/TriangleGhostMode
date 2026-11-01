# Feature mapping: how we map Ghost Mode's changes for the 5.x port

The goal is a record of **which changes in Ghost Mode are responsible for which gameplay change**, and what 5.x means for each of them. With that record we can port big systems and small fixes in a deliberate order instead of file by file.

This doc defines the method, the format, and how porting proceeds: in small steps, each run in the game before the next. The map itself lives in `docs/features/` (see [Layout](#layout)).

## Legacy behaviour first

The first version of the port reproduces legacy Ghost Mode's behaviour, which was tested thoroughly for balance (decision 2026-10-03, project owner). Where 5.x lets the port express a rule better (a cleaner hook, a generic mechanism instead of a special case), it may, as long as the behaviour stays legacy's. A deviation needs a good reason: a 5.x change that would otherwise defeat the rule's intent (e.g. STAM-09 targets 5.x's Whirl, `sword_s35`, because legacy's no longer exists in the skill tree), or a defect that keeps the feature from working. Gaps and side effects legacy had stay; possible improvements are recorded in the feature entry under **Later** for after the first version.

**Every deviation is recorded when it is made**, as a bullet of its own in the feature entry's **Decisions** (project owner, 2026-10-04):

```markdown
- **Deviation:** what differs from legacy's code or changelist, and why (project owner, 2026-10-04).
```

A deviation is any behaviour that differs from legacy: a fix of a legacy defect, a 5.x behaviour kept, a rule changed or left out. Implementation differences with the same behaviour are not deviations. Each bullet ends with who decided and when; one the owner has not reviewed says "porter's call, not confirmed by the owner", one that lasts until another area is ported says "temporary, until <area>". Where only running legacy could show how it actually played, the case also goes on the [list to test in legacy](open-questions.md#to-test-in-legacy-ghost-mode). `python tools/deviations.py` lists them all (`--unconfirmed`: those waiting for the owner); `--write` regenerates [features/deviations.md](features/deviations.md) for milestone reviews.

**Legacy's code against its changelist** (project owner, 2026-10-05). Where they differ, the code is the better guide: the changelist could drift. Every difference is still recorded in [open-questions.md](open-questions.md#legacy-data-vs-changelist), in one of two buckets:
- **Contradictions:** the changelist states something explicitly and the code does otherwise, e.g. a potion duration. These get special attention: each is brought to the owner.
- **Omissions:** the code changes something against vanilla that the changelist never mentions. A believable oversight; noted for lookup.

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
- On 5.x, Ghost Mode's DLC carries the NG+ counterparts as generated copies of its XML, scaled by this rule (`tools/gen_ngplus.py`; see [development.md](development.md#fine-grained-xml-overrides-50)).
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
- **Legacy kept the value in NG+** (legacy Ghost Mode gave it the same value in its NG and NG+ files): keep Ghost Mode's value; legacy behaviour first (project owner, 2026-10-04).

The [balance tables](#balance-tables) show vanilla NG+ and the resulting Ghost Mode NG+ value next to the regular columns, so the scaling can be applied and checked mechanically.

## Two skill trees

**The port supports both of 5.x's skill trees** (decision 2026-10-03, project owner): the classic tree is legacy Ghost Mode's tree, the new tree carries legacy's skills on 5.x's new slots and 3 levels, with a few new designs. Every feature that touches skills is ported to both.

What 5.x has (from its data and scripts; setting the hidden option by script is verified in game, the classic character screen not yet; see [game-automation.md](game-automation.md#skill-trees)):

- **Three kinds of skill.** Each skill is defined once in `geralt_skills.xml` (and the expansions' files): 68 classic-only skills (all of 1.32's, e.g. `sword_s1` Whirl, `sword_s9` Fleet Footed), 52 reworked skills that exist only in the new tree (`isReworked`, e.g. `sword_s35` Whirl, `sword_s36` Fleet Footed), and 28 shared skills used by both trees (`isUnchangedLegacy`: `alchemy_s2` to `s5`, `s8`, `s10` to `s16`, `s18`, `s20`; `magic_s1`, `s3`, `s4`, `s8`, `s11`, `s13`, `s17`, `s19`, `s20`; `sword_s2` Rend, `s16`, `s18`, `s19`, `s20`).
- **Choosing the tree.** The setting `UseLegacySkillTree` (group `RemasterCombat`, `gameplay.xml`, default off) is hidden from the options screen (`hideAlways`); in the scripts it only decides which character screen opens (`CharacterMenu`, the classic tree, or `CharacterMenuDupe`, the new one). Skills of either kind work under either setting; the per-skill passive bonuses go to every equipped skill, classic ones included (from the code: 5.x's function that would limit them to reworked and shared skills has no caller). Ghost Mode will need its own visible option for the tree.
- **5.x changed the classic tree too.** Nearly every classic and shared skill went from 5 levels to 3 (Fleet Footed `sword_s9` 5 → 1, `alchemy_s9` and `sword_s13` 3 → 1, `sword_s10` 3 → 2), the points needed per tier dropped by 40% (8/20/28–30 → 6/12/18), and about 40 skills' ability values were raised to fit three levels (e.g. `sword_s9` damage reduction 0.2 → 1.0, `sword_s1` Whirl cost 50 → 75 per second, spell power bonuses 0.05 → 0.1 per level).

What it means for the port:

- **Every feature that touches skills is mapped, ported and tested for both trees.** Its entry names the skills in each tree (**Skill trees** row of the [entry template](#feature-entry-template)); the [audit](#audit-signing-a-feature-off) checks it.

- **The trees are separated** (project owner, 2026-10-05). The 28 shared skills get per-tree values, levels, tiers and descriptions. The classic tree is legacy Ghost Mode's tree: legacy's skills, values, maximum levels, tier points and descriptions. The new tree carries legacy's skills on 3 levels, under legacy's names, gated by legacy's tiers scaled ×3/5, with general perks as legacy's 1-point perks and a few new designs by the project owner (SKL's per-skill pass, complete 2026-10-11: [skl.md](features/skl.md#area-decisions)). The plan, the technique (a per-tree skill profile applied at runtime) and the first slice are in [balance.md](features/balance.md#two-skill-trees-the-plan).
- **Until the separation slice is done**, features already ported (STAM, DEF, DMG) keep their per-tree code as it is: a change to a classic-only skill applies to the classic tree and the new tree gets it on its own skill (as STAM-09 did for Whirl, `sword_s35`); a change to a shared skill applies to both trees through its one definition.
- **Ghost Mode gets a visible option for the tree** (decision 2026-10-03, project owner): a toggle in Ghost Mode's menu that sets 5.x's hidden `UseLegacySkillTree`; the default is the classic tree (SKL's D46, project owner, 2026-10-05; OPT-01).

## Progression

Progression (experience, levels, skill points, how fast skills are bought) is a part of the port in its own right, with its own pillar (P10, [pillars.md](features/pillars.md)); legacy reworked it (the changelist's Experience section: smooth experience scaling by level difference, diminishing returns for kills, quest levels re-ordered).

What 5.x changed (from the game data, 2026-10-03; not tested in game): experience and levels are unchanged (`geralt_levelups.xml` identical: the same XP per level, 1 skill point per level up; quest rewards changed gold, not XP, apart from two new small rewards; monster XP code unchanged), but **skills became about a third cheaper**: maxing every skill costs 260 points in 1.32's classic tree, 171 in 5.x's classic tree and 180 in its new tree (3 ranks per skill instead of 5, tier gates 6/12/18 points instead of 8/20/28–30), with stronger ranks. A player levelling at the same speed therefore completes their build sooner. In the port the classic tree costs legacy's points again, and the new tree stays cheaper than legacy (3 levels per skill, 1-point perks). Not checked yet: the expansions' reward files, and how many Places of Power there are.

**Skill point sources and slots** (from the data and code, 2026-10-11; the same in 1.32, legacy and 5.x, except that 5.x unlocks skill slots and skill mutagen slots by total skill points instead of the level, which the port sets back to the level: [SKL-01](features/skl.md#skl-01-skill-system-rules); the mutagen slots since XP slice X5): 1 skill point per level from level 2 (49 by level 50; past 50 each level costs 2,000 XP and gives 1 point; cap 100), 1 per Place of Power on first use, 2 from Imlerith's acorn, 1 from Blood and Wine's golden egg; skill slots unlock at levels 0, 2, 4, 6, 8, 10, 12, 15, 18, 22, 26 and 30, mutagen slots at 2, 9, 16 and 28. In legacy a level gives +50 base Vitality and a full heal (not on Death March) besides the point; 5.x gives 100 Vitality per level tapering to 25, and attack power.

**Current direction:** both trees use legacy's tiers (rule B10 in [balance.md](features/balance.md), SKL's D59): the classic tree with legacy's levels and tier points, the new tree with 3 levels and the tier points scaled ×3/5 (sword 5/12/18, alchemy 5/12/17, signs 4/11/17; ported 2026-10-16), their pace to be examined with the skill-point income below. Since the new tree's skills cost fewer points, the project owner wants to lower its skill point income (2026-10-11): **on every third level Geralt gains no skill point, and his Vitality bonus is concentrated into those levels** (the three levels' Vitality given on the third, none on the two before). Ported as [XP-09](features/xp.md#xp-09-the-new-trees-skill-point-income-new-owner) (DX1 (a), DX2 (a); slice X5, verified by script in both trees, 2026-10-31): in the new tree levels divisible by 3 give no point (also past 50) and levels 3 to 48 +150 Vitality, the others none: 33 points and 2,400 Vitality from levels by level 50 (classic 49 and 2,450), 13 at level 20 (classic 19). A wrapper of `W3LevelManager.GainLevel` withholds the point and one of `GetLevelupAbility` gives the new tree's level abilities (`GMLvlNew<n>`), following the tree whose profile Geralt has; Places of Power, the acorn and the egg are unchanged; the character reset (SKL's D44) recomputes the level points and swaps the level abilities for the tree in force, reading under which rule each level was gained from the level ability held for it.

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
| `MISC` | Misfits: anything that fits no area, feature or pillar ([misc.md](features/misc.md)) | | |

Sources for the feature list: the changelist (primary), the 77 original commit subjects in the Ghost Mode 4.1 commit message, `design-docs/` on `legacy-GM`, and any units nobody can attribute (these become new features, marked as undocumented, or, when they fit no area, entries in the `MISC` bucket, [misc.md](features/misc.md), to be dealt with later).

**Before calling an area mapped, sweep the units for its subject**, not just the changelist: `python tools/unit_sweep.py <keyword> --unattributed` lists every unattributed unit whose Ghost Mode change (master vs `legacy-GM`) touches the keyword, in scripts and XML; attribute or hand off each one, and repeat with the area's other keywords. The STAM area was first mapped from the changelist with 126 units; a sweep for `stamina` (2026-10-02) found 105 more script units and about 900 XML units (NPC abilities, armor items, skills), two missing features (STAM-08 NPC stamina, STAM-09 Whirl and Rend costs) and large gaps in STAM-03 and STAM-06. Units whose change belongs to another area go into a hand-off list in the area file (see [stam.md](features/stam.md#hand-off-to-other-areas)), so that area's mapping starts from it.

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

Each `<area>.md` has an intro (what Ghost Mode does in this area, and what 5.x changed there), then one entry per feature. **Entries state results, briefly.** The table holds short values only; the text explains the feature and its decisions; each slice gets a few lines. Measurements, sample logs and investigations behind a result are kept in working notes outside the repository; the entry keeps the conclusion, so it reads on its own. STAM-08 in [stam.md](features/stam.md) is the reference example.

```markdown
### STAM-01 Stamina cost for light and heavy attacks

| | |
|---|---|
| Kind | system |
| Pillars | P2 |
| 5.x class | overlap |
| Flags | balance, needs-decision |
| Depends on | OPT-01, INFRA-02 |
| Skill trees | n/a / both: the skills in each tree (classic `sword_s1`, new `sword_s35`; shared skills named once) |
| Port form | one line: the techniques and where the code lives (see [development.md](development.md#port-forms)) |
| Port status | not started |
| Open checks | — (checks not done yet, including the owner's) |
| Save impact | none (expected) |
| NG+ counterpart | applied and scaled, untested / none |

**What it does:** player-facing behaviour, and why Ghost Mode wanted it (cite the changelist).

**Implementation (legacy):** which units do what, in a few lines; the full list is in attribution.csv.

**5.x:** what 5.x does in this area, with evidence (5.x diff, patch notes, in-game test).

**Decisions:** port as-is / adapt / drop / redesign, and why; who decided and when.

- **Deviation:** each deviation from legacy as a bullet of its own, with its reason, who decided and when ([legacy behaviour first](#legacy-behaviour-first)).

**Slices:**

1. **Name.** What the slice ports. Verified <date> (`gmtest_*` functions; for each check, real action or scripted call): the result in one or two sentences.

**Later:** possible improvements after the first version.

**Balance values:** link to the balance table rows involved.
```

**Port status:** `not started`, `in progress` (some slices ported and verified), `ported` (every slice ported and verified in game), `signed off` (ported and passed the [audit](#audit-signing-a-feature-off)), `deferred`, `dropped`. Checks still missing, such as a situation no test reached, are listed under **Open checks** instead of holding the status back.

**Checks only the project owner can do** (listening to a sound, judging a visual or the feel of a fight) are open checks marked *waiting for the owner*; they are also listed on the status page ([features/README.md](features/README.md#where-the-port-stands)) until done.

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
4. The changed behaviour works, as far as it can be tested at that point (check the feature's "What it does"), through a `gmtest_*` exec function. Say for each check whether it was a **real action** (input handler, a real cast, a real attack) or a **scripted call** (e.g. `DrainStamina` directly); scripted is fine where it runs the same code path.
5. When a feature is finished: the regression run, `gmtest_regress()`, in one game session. It runs every check that needs no particular situation, sets up and restores what it needs (options, stamina, spawns), and reports PASS/FAIL per check (see [development.md](development.md#testing-in-game)).

Record the result in the feature entry's slice and update its port status. If the check fails, fix that step or revert it. Do not build more on top of it.

Checks that need specific game situations (a certain enemy, a late-game item) get console commands or a dedicated test save, recorded in [game-automation.md](game-automation.md) so later checks can repeat them.

## Audit: signing a feature off

A feature that is `ported` is audited before it is `signed off`. The audit is done by **a new session that did not port the feature** (decision 2026-10-03, project owner): during the pilot, large parts of features were missed and found only later, while probing other questions (STAM-08 and STAM-09 were found only by a unit sweep, and most of STAM-03's units with them). A reviewer without the porter's assumptions catches what the porter cannot see. The audit comes in addition to the regression run, not instead of it.

The auditor checks, and reports findings rather than fixing them silently:

1. **Both skill trees.** For every skill the feature touches (in its code, XML or tests): the classic tree's skill and the new tree's counterpart are both handled, or the entry says why one is not; no reworked or classic skill ID is hard-coded where the equipped one should be read; shared skills are special-cased where the trees need different rules; the checks ran on both trees. STAM was first ported for the new tree only and missed the classic Whirl and the new tree's alternate Igni and Axii ([follow-ups](features/stam.md#two-skill-trees-follow-ups)).
2. **Completeness against legacy.** Every unit attributed to the feature (`attribution.csv`) is ported, or dropped, kept for another feature or handed off with a reason in the entry. Re-run `tools/unit_sweep.py` with the feature's keywords for units nobody attributed. Compare the entry's "What it does" with the changelist and with the legacy code: behaviour legacy had that the port lacks is a finding (legacy behaviour first).
3. **The code.** Read the port on `5.x-GM`: each legacy change has its counterpart, deviations are marked and recorded in the entry with their reason, no leftovers (temporary probes, debug logging, dead code, test-only wrappers outside `tests/`), conventions held (prefixes, feature tags, `//modSigns` markers in replaced bodies), no absolute paths.
4. **The verification.** The slices' recorded checks cover what the feature does; each check says real or scripted; untested parts are listed as open checks. Run the [regression check](development.md#testing-in-game).
5. **The docs and notes.** The entry, the status page ([features/README.md](features/README.md#where-the-port-stands)) and the other docs touched say what the code does now; the working notes on the feature are still correct; nothing a reader needs exists only in the working notes.

Findings go to the project owner, who decides what is fixed, accepted or handed off. Fixes go through the usual small steps; when the findings are settled, the entry's port status becomes `signed off`, with the audit's date in the entry.

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
- **Ghost Mode is installed at the start of a playthrough; adding it to or removing it from a save in the middle of a playthrough is not supported** (the project owner's decision, 2026-10-18). Save impacts are still recorded as facts, and so is what a save meets when the mod is removed, labelled unsupported; such cases need no fix or fix-up code.

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
2. **Map the pilot area.** Sign cooldowns plus stamina: they touch scripts, XML, the options menu and localization, and 5.x has its own `overloadCooldown.ws` to compare against. Inventory, attribution and 5.x analysis for just this area. *Done 2026-10-02:* `tools/change_units.py` built the inventory; [features/stam.md](features/stam.md) maps STAM-01 to STAM-07 (126 units) and [features/opt.md](features/opt.md) the parts of OPT-01 they use. A sweep of every stamina-related unit then completed the mapping (STAM-08 and STAM-09 added, 1068 units).
3. **Port it in slices**, each through the in-game check. *Done 2026-10-03:* STAM-01 to STAM-09 ported and verified in game (34 commits on `5.x-GM` over two days), with OPT-01's gameplay and QoL groups.
4. **Review the process.** *Done 2026-10-03.* What the pilot showed, and the changes made:
   - Small slices verified in game, the fully scripted test loop (`tools/game.py`, `gmtest_*` functions), [legacy behaviour first](#legacy-behaviour-first), the sweep before calling an area mapped, the hand-off list and the status page for session hand-offs worked; kept.
   - Entries grew into logs (one feature's verification cell reached about 4,800 characters). The [entry template](#feature-entry-template) now keeps the table to short values and records verification per slice; measurements and investigations live in working notes outside the repository.
   - The status values did not match their use; they are now `not started`, `in progress`, `ported`, `deferred`, `dropped`, with missing checks listed as open checks.
   - Some checks need the project owner (listening to the heartbeat); they are now a kind of open check, listed on the status page.
   - The regression check ("a quick check of nearby features") was not done systematically; it is now `gmtest_regress()`, one game session, run when a feature is finished.
   - Mapping from the changelist missed most units (the stamina sweep found about 80% of the area); the sweep rule is in [Feature IDs and areas](#feature-ids-and-areas). Mapping also deepened during porting (STAM-08's per-mechanism mapping was done when its port started): expect an area's map to be refined slice by slice.
   - Large parts of features were missed and found later while probing other questions; finished features now get an [audit](#audit-signing-a-feature-off) by a new session before they are signed off.
   - The "run guide" this method planned was not needed as a separate doc: test setups are in [game-automation.md](game-automation.md), the working agreements in [features/README.md](features/README.md#where-the-port-stands).

After the pilot, mapping of different areas is independent and can be done in parallel. Porting stays sequential in dependency order, one verified step at a time. The second area was DEF (dodging, parrying, countering; decision 2026-10-03, project owner), the third SKL (skills; mapped 2026-10-04).

## Keeping it current

- After a new game release lands on `vanilla-5.x`, re-run `tools/change_units.py`. Features whose units changed in the new release get their 5.x analysis re-checked.
- When a slice passes the in-game check, record it in the feature's **Slices** and update its port status; when every slice has passed, the status is `ported`; after the audit, `signed off`.
- The map lives on `master`, like the rest of the docs.
