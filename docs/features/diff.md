# DIFF: difficulty modes and enemy scaling

How hard the game is, beyond each enemy's own numbers: what each difficulty mode does to enemies, the per-enemy adjustments some fights get on each mode, the prologue's softer enemies, Ghost Mode's enemy scaling menu (how enemy levels follow Geralt's, extra health and damage), the level shown above enemies, Ciri's sections, and the money guards take when they knock Geralt out. Ghost Mode's changelist has its own section, "Difficulty modes" (lines 1137–1152), and the enemy scaling half of "Mod options" (lines 1179–1216).

**The player-visible texts first.** The four difficulty modes keep their names in 1.32, legacy and 5.x: "Just the Story!", "Story and Sword!", "Blood and Broken Bones!", "Death March!" (string ids 1092305, 1092307, 1092308, 1092309, unchanged in 5.x). 5.x adds the line "You can change the difficulty level at any point in the Options menu." (1211206) and keeps 1.32's "Vitality regenerates when you eat. On lower difficulty levels, it also regenerates during Meditation." (1085730). Legacy's changelist names them differently ("Easy (Story): -50% to enemy health, -25% to enemy damage", "Normal (Sword and Story): no modifiers", "Hard (Blood and Broken Bones): +100% to enemy health, +100% to enemy damage", "Hardcore (Death Match): +150% to enemy health, +250% to enemy damage") and says "Removed vanilla difficulty level restrictions for Ciri (the game is always easy or normal for her in vanilla). Ciri health, armor and damage tweaked accordingly", "Experience gained no longer depends on difficulty level", "Stamina regen for AI no longer boosted for DM", "New harcore difficulty preset added to GM options: increases the number of bonuses enemies get per level, makes mid to end game enemies tougher. Can be used with any base game difficulty mode" and "Note that vanilla scaling option is irrelevant with the mod". Legacy's menu (Options → Mods → Ghost Mode, group "Enemy scaling", presets "Scaling Presets": "Recommended", "Hardcore", "Off") has: "Enemy scaling" (None, Upscale, Match, Soft upscaling, Random, Random no downscaling), "Random scaling: lower bound (relative to player level)", "Random scaling: upper bound (relative to player level)", "Use progressive level bonuses", "Level delta", "Abilities per level delta", "No additional levels for guards", "Do not upscale animals", "Enemy health modifier", "Enemy damage modifier", "Additional health modifier for bosses", "Additional damage modifier for bosses". The mod description (section 9, "Your very own difficulty mode") presents Normal as the base for a custom difficulty, and the release readme says "RECOMMENDED MOD SETTINGS: use default/recommended presets in mod's options menu." 5.x's own menu keeps vanilla's "Enemy Upscaling" toggle (1214362; inert under Ghost Mode since AI-01) and adds accessibility aids: "Vitality Regeneration Boost" ("Activates Below (%) Vitality", "Regeneration Multiplier") and the preset "Bard's Ballad: Focus & Rest" ("This preset is recommended for players experiencing mental fatigue or trouble concentrating."), which bundles several of them.

**What 5.x did in this area** (from `vanilla-5.x`, unverified in game). Almost nothing: the difficulty multipliers (`difficulty_Common*`, regular and NG+), every per-enemy difficulty variant (52 of them changed by legacy), the prologue's attack-power cut, Ciri's abilities and her difficulty cap (`CR4Game.GetSpawnDifficultyMode`), and the fake level addon in the entity files are 1.32's. One rule changed: when guards knock Geralt out, 5.x takes 25%, 40%, 65% or 85% of his money by difficulty, capped at 750, 1,250, 1,750 and 2,250 crowns (1.32: 25%, 50%, 75%, 100%, no cap; `CR4PlayerStateUnconscious.TakeMoneyFromPlayer`). 5.x adds no new difficulty variant, also not for its new enemies (`mq1060`'s Reinald, the red-plague creature). New next to the difficulty modes: the accessibility aids above (`LowHPAutoHeal*` read by `W3Effect_AutoVitalityRegen`, off by default; the "Disable item durability" option ITEM kept as DI4) and a difficulty-change warning about achievements. The level code that hosts the scaling options is AI-01's (5.x's rewrite already replaced by legacy's, signed off).

**How legacy Ghost Mode implements it.** Data: the four difficulty abilities (`common_abilities.xml`), 50 per-enemy variants in the expansions' monster and NPC files (emptied or retuned), `PrologModifier` (emptied), the five `ModSigns*` health and damage step abilities (`monster_base_abl_new.xml`, new), Ciri's eight abilities (`opp_base_abl.xml`), all regular and NG+ (legacy's NG+ entries equal its regular ones); one entity file (`mq1028_gerd`, fake addon 1 → 0). Scripts: `CNewNPC.AddLevelBonuses`' scaling branches, `InternalAddLevelBonuses`' progressive level-up, `ModSignsAddBonuses` (new), `ManageNGPLevels` (fake addon zeroed), `GetExperienceDifferenceLevelName` (no addon, no cap), the option getters in `W3GameParams`, `CR4Game.gmUserSettingsScaling` and `GetSpawnDifficultyMode`, `W3ReplacerCiri.CheckCiriAbilities` (new) and its two callers, `TakeMoneyFromPlayer`; the menu group `GMScalingOptions` in `modSignsConfig.xml` and its 21 labels in 9 languages.

Unit lists: [attribution.csv](attribution.csv): mapped 2026-10-29 from the changelist's two sections, every hand-off to DIFF in the other areas' files and in [deviations.md](deviations.md), a field-by-field comparison of every ability carrying a `DifficultyModeAbility` tag in any of the three games (master, `legacy-GM`, `vanilla-5.x`, regular and NG+; 130 entries), every script line legacy changed that reads the difficulty (`GetDifficultyMode`, `GetSpawnDifficultyMode`, `EDM_*`), the 73 entity files in Ghost Mode's file set that carry `levelFakeAddon` (dumped in the three games), legacy's menu XML and option code, and the 5.x string tables (`content0/en.w3strings`, decoded with `w3strings.py`) and accessibility options. **358 units carry a DIFF feature**: 343 newly attributed (19 script units, 67 XML units and their 66 NG+ copies, 2 binary files, 189 string rows), DIFF added to 15 shared units (AI-01's level functions, UI-12's level name, STAM-08's Death March ability, STAM-03's Ciri spawn, OPT-01's menu and scaling-option list); two unattributed Ciri stamina functions the sweep found are STAM-03's (commented out as unused, nothing to port). Unattributed units: 3,477 before, 3,132 after. Port status: **mapped** (2026-10-29), analysed against 5.x from the code and data (unverified in game); **decided** (2026-10-29): the owner made the [area decisions](#area-decisions) DD1 to DD4 and confirmed the porter's calls PD1 to PD10. **Ported so far:** slice D1 (DIFF-01, DIFF-03; 5.x-GM `5d06b030`, 2026-10-29), slice D2 (DIFF-02; 5.x-GM `53427f7b`, 2026-10-29), slice D3 (DIFF-06; 5.x-GM `73734341`, 2026-10-29), slice D4 (DIFF-07; 5.x-GM `232d10f8`, 2026-10-29), each verified in both trees: **part DIFF-A is complete**; slice D5a (DIFF-04 part 1; 5.x-GM `f929bfc3`, 2026-10-30) and slice D5b (DIFF-04 part 2; 5.x-GM `ad314f9f`, 2026-10-30), each verified in both trees: **DIFF-04 is ported**; slice D6 (DIFF-05; 5.x-GM `523457b1`, 2026-10-30), verified in both trees: **every DIFF feature is ported** (DIFF-08 handed to XP) and all four temporary deviations until DIFF are ended. **Audited** 2026-10-30 ([DIFF audit](#diff-audit-2026-10-30): 6 findings, three of them owner decisions: F1 Ciri's takeover, F2 late bosses, F3 zero or negative multipliers; regression clean in both trees). The audit's clear fixes made (F4's checks, F5's independent corrections; 5.x-GM `fa4b96ff`, 2026-10-30, [close-out](#diff-audit-close-out)). The owner's decisions on F1 to F3 made and verified in both trees (2026-10-31, 5.x-GM `38e2b55e`): a player change re-levels the NPCs near the new player, the boss modifiers follow the boss bar, the difficulty mode multiplies the menu's modifiers (three deviations); the audit is closed. **Signed off** by the owner (2026-10-31), with the last fix's three porter's calls confirmed. **Two additions the owner asked for** ([DIFF-C](#diff-c-additions-owner-2026-10-31-new-not-legacy)): DIFF-09, "Ciri's sections: difficulty", and DIFF-10, the "Interpolated" scaling type, ported and verified in both trees (5.x-GM `c0e2dcdb`, 2026-10-31); new, not legacy (deviations; their porter's calls and the assumption confirmed by the owner, 2026-10-31).

**Size and a proposed split.** DIFF is small next to AI: mostly data from one generator, plus the scaling menu, which is the only part with real code. One area, two parts, one audit at the end (PD1):

| Part | Features | Units | What it is |
|---|---|---|---|
| **DIFF-A Difficulty modes** | DIFF-01, DIFF-02, DIFF-03, DIFF-06, DIFF-07 | about 130 | What each mode does to enemies, the per-enemy variants, the prologue, Ciri, the guards' toll. Generated data with `--verify`, three small script changes |
| **DIFF-B Scaling options and levels shown** | DIFF-04, DIFF-05 | about 230 (189 of them labels) | The enemy scaling menu on top of AI-01's level code, and the level shown above enemies |
| **DIFF-C Additions** (owner, 2026-10-31; new) | DIFF-09, DIFF-10 | — (new code, 5 labels) | Ciri's sections capped by an option; the "Interpolated" scaling type |

## Scope

**DIFF covers** the difficulty multipliers on enemy health and damage, the per-enemy difficulty variants, the prologue's attack-power cut, the enemy scaling options (scaling types, random bounds, progressive level bonuses, guards' and animals' options, extra health and damage for enemies and bosses, the presets), the displayed level's fake addon, Ciri's difficulty and stats, and the money guards take.

**Already ported by other areas** (nothing left for DIFF; the hand-offs naming them close here):

| Subject | Ported by | What |
|---|---|---|
| The difficulty multiplier's place in the damage steps (final damage, hostile NPCs hitting Geralt only) | DMG-05 (signed off) | `damage/pipeline.ws`; its values are DIFF-01's (DMG-05's temporary deviation) |
| Fistfight damage by difficulty and level difference | DMG-10 (signed off) | `damage/pipeline.ws` reads `GetSpawnDifficultyMode` (DIFF-06 removes Ciri's cap under it) |
| Death March's +20% NPC stamina regen removed ("Stamina regen for AI no longer boosted for DM") | STAM-08 (signed off) | Since slice D1 in DIFF-01's `gm_diff.xml` (legacy's `difficulty_CommonHardcore` has no stamina regen node; PD2) |
| Durability penalty by difficulty | ITEM-10 (signed off) | `items/durability.ws` |
| Ice Armor's +30% resistances not on "Just the Story!" | AI-15 (signed off) | `ai/wildHunt.ws` |
| The level model the scaling sits in: per-level bonuses, guards at Geralt's level +16, High and Deadly at 6 and 15 levels, NG+ levels, legacy's recommended soft scaling fixed (DA2) | AI-01 (signed off) | `ai/levels.ws`; DIFF-04 replaces the fixed preset with the options |
| Deadly enemies' blindness immunity removed (EFX hand-off) | AI-01 (signed off) | `GMRemoveAllLevelBonuses`; nothing for DIFF |
| The 71 entity files where legacy made a fake level real (the sergeant, Lugos, Blood and Wine's quest fighters, ...) | AI-06 (AI-C audit F6, signed off) | `gen_ai_ent.py`; DIFF-05 is the rest of the fake levels |
| Two per-difficulty variants AI's generator already gives (Bossek's Hard attack-power cut and Golyat's Easy one emptied: `mon_EP2_bossekhardnerf`, `q701_giant_peasant`) | AI-03 (signed off) | `gm_ai_monsters.xml`; attributed to AI-03 before DIFF was mapped, left there |
| The Caretaker's NG+ healing per difficulty (`mon_caretaker*_ep1` in NG+) | AI-19 (signed off) | `gm_ai_monsters.xml` |
| Skellige archers' and the Emhyr crossbowman's levels (XBOW hand-off) | AI-06 (signed off) | entity levels |

**Not DIFF:**

| Subject | Area | Why |
|---|---|---|
| Experience independent of the difficulty (the changelist's "Experience gained no longer depends on difficulty level"; `CalculateExperiencePoints`, `CR4Game.OnGiveReward`) | XP | DIFF-08 records it; the code is XP's kill and quest experience (PD7) |
| The options menu framework (groups, presets, defaults, re-reading on change; the "Recommended" and "Off" preset labels shared by every group) | OPT | DIFF-04 adds its group to it |
| The "Experience" option group (quest levels, fixed experience, experience modifiers) | XP | |
| Two unattributed abilities the sweep met that are not difficulty variants: the sturdier archespore `mon_archespor_hard` (legacy: 800 Essence base; 1.32 and 5.x: +1,500 and ×2.2 Essence, −60% attack power) and the barber quest's enemy `mon_q703_mqsidqpyt` (legacy: 200 Vitality, armor ×60; 1.32 and 5.x: +40% attack power, +150% Vitality, armor ×50) | AI (AI-03) | Enemy stats AI-03 missed; handed back and ported as AI-03's with slice D1 ([AI-03](ai.md#ai-03-monster-stats)) |
| The golems' and ice elementals' attack ranges (8 unattributed entity files) | AI or FIX | W3Edit re-saves or attack cones, not difficulty |

## Changes at a glance

### What Ghost Mode changed

| # | Feature | Vanilla 1.32 | Legacy GM | Units (main) |
|---|---|---|---|---|
| DIFF-01 | Difficulty modes | Health / damage: "Just the Story!" −50% / none; "Story and Sword!" +10% / +40%; "Blood and Broken Bones!" +20% / +130%; "Death March!" +80% / +230%, +20% stamina regen, +10% Aard, Igni, Axii and shock resistance (NG+ higher) | −50% / −25%; none; +100% / +100%; +150% / +250%; nothing else; NG+ the same | 4 abilities (and NG+) |
| DIFF-02 | Per-enemy difficulty variants | 52 per-mode adjustments of the expansions' special enemies (Olgierd, the Toad Prince, Dettlaff, Golyat, bruxae, slyzards, shaelmaars, the Toussaint guard knights, ...) | 37 emptied or added empty, 13 retuned (milder kikimore venom, the drunken master's +50 fist damage on "Death March!", ...) | 50 abilities (and NG+) |
| DIFF-03 | Prologue attack-power cut | −30% attack power for enemies on the two lower modes while Geralt is level 1 | Removed | 1 ability (and NG+), 1 script unit |
| DIFF-04 | Enemy scaling options | Vanilla's "Enemy Upscaling" toggle | Six scaling types, random bounds, progressive level bonuses, guards' and animals' options, extra health and damage for enemies and bosses, three presets; vanilla's toggle ignored | 5 abilities (and NG+), 14 script units, 189 labels, the menu group |
| DIFF-05 | Fake levels | Many quest NPCs show a level above their real one (`levelFakeAddon`), capped at the maximum level +5 | Every enemy shows its real level | 2 script units, 2 entity files |
| DIFF-06 | Ciri | Her fights capped at "Story and Sword!"; on "Death March!" her enemies get an attack-power adjustment; her quest stats | No cap, the adjustment zeroed; armor, health and attack power per quest, frost immunity in the last two; her rage's health halved; two quest abilities added by journal state | 4 script units, 8 abilities (and NG+) |
| DIFF-07 | Money taken by guards | 25 / 50 / 75 / 100% by difficulty | 25% on every difficulty | 1 script unit |
| DIFF-08 | Experience by difficulty | Kill experience ×1.2 / 1 / 0.9 / 0.8 by difficulty, quest experience ×0.9 and ×0.8 on the two higher modes | Removed | (XP's units) |
| DIFF-09 | Ciri's sections: difficulty (new, owner) | — (5.x: capped at "Story and Sword!") | — (no cap) | 1 option, 4 labels, 4 script units |
| DIFF-10 | Interpolated enemy scaling (new, owner) | — | — | 1 menu entry, 1 label, 1 script unit |

### What 5.x changed

| # | 5.x change (from code and data) |
|---|---|
| DIFF-01 to DIFF-03 | None (1.32's values and code) |
| DIFF-04 | None to the level code legacy's options sit in beyond AI-01's (already replaced); vanilla's "Enemy Upscaling" toggle unchanged |
| DIFF-05, DIFF-06 | None |
| DIFF-07 | 25 / 40 / 65 / 85% by difficulty, capped at 750 / 1,250 / 1,750 / 2,250 crowns |
| DIFF-08 | None (XP's) |
| New | Accessibility aids: "Vitality Regeneration Boost" below a Vitality threshold, the "Bard's Ballad: Focus & Rest" preset, "Disable item durability" (DD3, ITEM's DI4) |

### Classification and proposed action

| # | Feature | Class | Proposed action |
|---|---|---|---|
| DIFF-01 | Difficulty modes | clean | Legacy's (PD3); ends DMG-05's deviation |
| DIFF-02 | Variants | clean | Legacy's (PD3); ends AI-20's deviation |
| DIFF-03 | Prologue cut | clean | Legacy's; ends AI-01's deviation |
| DIFF-04 | Scaling options | conflict (AI-01's port fixed one preset) | Legacy's options; the "Recommended" preset as the default (DD1), the animal option as legacy's code (DD4) |
| DIFF-05 | Fake levels | clean | Legacy's; ends UI-12's deviation |
| DIFF-06 | Ciri | clean | Legacy's (PD5) |
| DIFF-07 | Guards' toll | overlap (5.x changed the rule) | Legacy's quarter, no cap (DD2) |
| DIFF-08 | Experience | clean | Handed off to XP (PD7) |

---

## DIFF-A Difficulty modes

### DIFF-01 Difficulty modes

| | |
|---|---|
| Kind | tuning |
| Pillars | P1, P5 |
| 5.x class | clean |
| Flags | balance |
| Depends on | DMG-05 (where the damage multiplier applies), AI-01 (the health it multiplies), STAM-08 (the same ability) |
| Skill trees | n/a; "Death March!"'s sign resistances apply to every Aard, Igni, Axii and Yrden cast in either tree (no skill named) |
| Port form | the four `difficulty_Common*` abilities given whole (`replace`) in a new DLC file `abilities/gm_diff.xml` from `tools/gen_diff.py`; `difficulty_CommonHardcore` left STAM-08's `gm_npc_stamina.xml` (one home per ability, as AI's PA2; PD2); NG+ copy by `gen_ngplus.py` (legacy kept NG+ equal to NG) |
| Port status | ported (slice D1, 5.x-GM `5d06b030`), verified in both trees (2026-10-29) |
| Open checks | — |
| Save impact | none (verified for a mode change: every NPC's difficulty ability is swapped at once and its maximum health follows) |
| NG+ counterpart | applied: legacy's values carried over (legacy gave NG+ its regular values, so they are kept, not scaled; `gen_ngplus.py` keeps them), untested |

**What it does** (changelist 1144–1148): each mode multiplies every enemy's health and the damage hostile enemies deal to Geralt, by legacy's own numbers ("game difficulties were reworked, so Blood and Broken Bones is now hard and Death Match is deadly", mod description). "Story and Sword!" leaves enemies at their own numbers, the base for a custom difficulty (DIFF-04's modifiers add to it):

| Mode | 1.32 and 5.x: health / damage | Legacy |
|---|---|---|
| "Just the Story!" | ×0.5 / ×1 | ×0.5 / ×0.75 |
| "Story and Sword!" | ×1.1 / ×1.4 | ×1 / ×1 |
| "Blood and Broken Bones!" | ×1.2 / ×2.3 | ×2 / ×2 |
| "Death March!" | ×1.8 / ×3.3; +20% stamina regen; +10% resistance to Aard, Igni, Axii and Yrden's shock | ×2.5 / ×3.5; nothing else |
| NG+ (1.32 and 5.x) | ×0.5 / ×1, ×1.3 / ×1.9, ×1.3 / ×2.7, ×2 / ×4 | as the regular game |

Legacy also drops the abilities' leshen-root area nodes (`root_ground_damage_area`, base 0 and ×0 in 1.32: inert). The damage multiplier applies where DMG-05 put it: final damage, hostile NPCs hitting Geralt only (1.32 and 5.x: raw damage of any NPC hit); the health multiplier applies to every NPC, allies included, as in 1.32.

**Implementation (legacy):** `difficulty_CommonEasy`, `…Medium`, `…Hard`, `…Hardcore` in `common_abilities.xml` and `abilities_plus/`; added by `CNewNPC.OnGameDifficultyChanged` (vanilla's) and through `all_NPC_ability`'s difficulty sub-abilities when an NPC spawns.

**5.x:** 1.32's (read in game on a build without the slice: ×0.5 / ×1, ×1.1 / ×1.4, ×1.2 / ×2.3, ×1.8 / ×3.3, and +0.1 in each of the four sign resistances on "Death March!").

**Decisions:** legacy's values (PD3), "Death March!"'s ability exactly legacy's (no sign resistances, no stamina regen boost); NG+ as legacy, equal to the regular game (PD9); ended [DMG-05](dmg.md#dmg-05-order-of-damage-steps-and-final-damage)'s temporary deviation (slice D1). The other areas' tests read the multiplier the game has rather than a fixed value, so none needed changing; doc statements that gave 5.x's values as current (development.md's health and damage multiplier notes, AI-01's and XBOW-08's verification records) now say which values held when.

**Verification (slice D1, 2026-10-29, both trees; 5.x-GM `5d06b030`; `tests/gmTestsDiff.ws`, `tests/gmTestsDiffData.ws`).** The mode is set through the game's own path (`SetDifficultyLevel` and `OnDifficultyChanged`, what the options menu's confirmation calls) and set back to the save's "Blood and Broken Bones!" after each run.

| Check | How | Classic tree | New tree |
|---|---|---|---|
| The five abilities as the game reads them: 18 attributes, legacy's values, 0 for the nodes only 5.x has (Death March's stamina regen and four sign resistances, the root area nodes, the prologue cut) | scripted: definitions read (`GMTest_diffdata`, in the regression) | passed | passed |
| Each of the four modes in turn on a spawned frozen bandit and wolf: that mode's ability alone, health and damage ×0.5 / ×0.75, ×1 / ×1, ×2 / ×2, ×2.5 / ×3.5, the four sign resistances on "Death March!" as on "Story and Sword!" | scripted (`gmtest_diff01_modes`) | 8 passed | 8 passed |
| Maximum health = health attribute × the mode's multiplier on "Blood and Broken Bones!" and "Death March!" (bandit 278.8: 557.6 and 697; wolf 80: 160 and 200) | scripted (`gmtest_diff01_read`) | passed | passed |
| Hits of the bandit and the wolf on Geralt through the damage manager: the final-damage step ×2 on "Blood and Broken Bones!", ×3.5 on "Death March!" (226.2 → 452.4; 132.8 → 464.9) | scripted (`gmtest_diff01_hits`; a test probe on `GMProcessDamageModification`) | 4 passed | 4 passed |
| A real wolf bite on "Death March!": the wolf unfrozen and attacking Geralt (immortal) on its own; its hit ×3.5 at the step (142.5 → 498.9; new tree 187.5 → 656.2) | real: the enemy's own attack (`gmtest_diff01_bite_a`, `_b`) | passed | passed |

On a throwaway build without the slice's data (deleted), every one of these failed: the data check (12 of 18 attributes 5.x's), all 8 mode reads (×1.1 / ×1.4 and the like, +0.4 sign resistance on "Death March!"), both health reads, the four scripted hits (×2.3, ×3.3) and the real bite (×3.3). STAM-08's "Death March!" stamina regen read 0 on both builds (the old `extend` entry on the throwaway, legacy's whole entry with the slice), and the regression's STAM-08 checks passed (PD2). Regression 1,063 passed, 0 failed in each tree; `gmtest_panel()` 133. A real bite needs patience: the unfrozen wolf landed its first bite 15 to 27 s after it was unfrozen in three of six tries, none within 8 to 15 s in the other three.

### DIFF-02 Per-enemy difficulty variants

| | |
|---|---|
| Kind | tuning |
| Pillars | P5 |
| 5.x class | clean |
| Flags | balance |
| Depends on | DIFF-01; AI-03, AI-04, AI-19, AI-20 (the parent abilities that list them, already legacy's) |
| Skill trees | n/a |
| Port form | the 50 variants given whole in `gm_diff.xml` by `gen_diff.py` from the units attribution.csv gives DIFF-02 (`replace` where 5.x's regular files define the name, never `extend`, which empties Hearts of Stone's abilities; a plain new entry for the eight 5.x defines only in its NG+ files); NG+ by `gen_ngplus.py` (legacy's NG+ entries equal its regular ones; a new entry whose name 5.x's NG+ files define gets `replace` there) |
| Port status | ported (slice D2, 5.x-GM `53427f7b`), verified in both trees (2026-10-29) |
| Open checks | the variants of the enemies not spawned (Dettlaff, the Toad Prince, Iris's nightwraith, Golyat, bruxae, the Spotted Wight, the garkain, panthers and the rest) are checked as data only; the drunken master's quest fight itself (the minigame was started by script) |
| Save impact | none (verified for a mode change: the variants under a parent ability are swapped at once) |
| NG+ counterpart | applied: legacy's values carried over (all 50 in NG+, equal to the regular ones; `mon_olgierdeasy_ep1`, which legacy left 1.32's in NG+, is empty there as in 1.32), untested |

**What it does:** not in the changelist (an omission): legacy takes the per-mode adjustments off the expansions' special fights, so the mode's multipliers (DIFF-01) are the only difficulty rule, and keeps a few of its own. The game picks the variant tagged with the current mode (`DifficultyModeAbility` sub-abilities of the enemy's ability):

| Enemy (parent ability) | 1.32 and 5.x | Legacy |
|---|---|---|
| Olgierd (`olgierd_default_stats`) | "Blood and Broken Bones!" +50% health, −20% attack power; "Death March!" +50%, −30% | Nothing on any mode (empty variants added for the two lower modes) |
| The Toad Prince (`mon_toad_base`) | +70% Essence, −20% attack power; "Death March!" +84%, −10% | Nothing |
| Iris's nightwraith (`mon_nightwraith_iris`) | Essence regen on the two higher modes (a min/max typo, 0.049/0.045) | The same regen, typo fixed (0.049) |
| Dettlaff, his monster form and his construct (`mon_dettlaff_*`) | Per mode: +60 to +95% Essence, −80 to +50% attack power, damage-over-time resistance, an Igni damage amplifier (some nodes misspelt `typr`, inert) | Nothing (empty variants added for the construct's unused modes) |
| Golyat (`mon_q701_giant`) | "Death March!" +60% attack power, +50% Essence, burning resistance | Nothing |
| Bruxae (`mon_bruxa`), the bruxa of quest `q701` (`mon_q701_bruxa`, an empty variant added) | "Death March!" +35% attack power, burning resistance | Nothing |
| Slyzards (`mon_draco_base`) | Every mode but "Blood and Broken Bones!" (no variant) +40% Essence and +9 Igni damage taken (`igni_damage_amplifier`, read by 1.32's and 5.x's damage step); "Just the Story!" −50%, "Story and Sword!" −20%, "Death March!" +40% attack power | Nothing |
| Shaelmaars (`mon_sharley_base`) | "Just the Story!" −200 armor, −50% attack power and Essence; "Story and Sword!" −30% attack power; "Death March!" +50% poison resistance | −150 armor on "Just the Story!"; +20% poison and +20% poison damage-over-time resistance on "Death March!" |
| The shaelmaar of quest `q701` (`mon_q701_sharkley`) | "Death March!" +30% attack power, burning resistance | +20% attack power |
| The Spotted Wight (`mon_EP2_SpoonCollector`) | "Blood and Broken Bones!" +50%, "Death March!" +110% attack power, −20% Essence, burning resistance | +20% and +50% attack power |
| Kikimores (`mon_kikimora_worker`, `…_warrior`) | Venom (toxicity per bite, `toxicityVenom`) 0.025 on "Blood and Broken Bones!"; on "Death March!" 0.04 with +10% Essence and +9 Igni damage taken (workers), 0.06 and +15% attack power (warriors); 0.01 and 0.015 on the two lower modes (left by legacy) | Venom 0.02 on "Blood and Broken Bones!", 0.025 (workers) and 0.03 (warriors) on "Death March!"; nothing else |
| The garkain of quest `q704` (`mon_q704_garkain`) | "Death March!" +200% attack power, +30% burning resistance | +50% burning, bleeding and poison damage-over-time resistance |
| Ghost panthers (`mon_panther_ghost`) | "Death March!" +60% attack power, −20% Essence | +20% attack power |
| Toussaint's guard knights (`guardKnight`) | The two higher modes ×5 health, +40 armor | Nothing |
| The drunken master (`ff701_master` entity, `mon_EP2_hardcore_FF`) | "Death March!" +80% attack power | +50 fist damage (AI-20's `fist_dmg_bonus`) |
| Panthers, the panther witch, Blood and Wine's ghouls and wild dogs, giant centipedes, the `mq7018` basilisk, `mon_EP_dafne`, the `q701` bandits, the `q702` event monsters, the mq7004 witch (her variant never applied: a typo in its parent) | "Death March!" (one each) −20 to +200% attack power, −30 to +150% health | Nothing |
| Barghests (`mon_barghest_base`), the tourney knights (`mon_q703_arena_knights`) | Defined only in the NG+ files: nothing in a regular game | Empty variants added (nothing) |

The two variants AI-03 already gives are emptied as well (Bossek's Hard −60% attack power, Golyat's Easy −70%); the Caretaker's and the banshee summons' are 1.32's in legacy's regular files (AI-19 changed the Caretaker's NG+ ones).

**Implementation (legacy):** 50 abilities in the Blood and Wine and Hearts of Stone monster and NPC files, regular and NG+.

**5.x:** 1.32's, none new: each of the 50 has 1.32's values in 5.x's regular and NG+ files, so there is no variant where 5.x and legacy both changed a value (checked field by field, 2026-10-29).

**Variants in an entity's own ability list are chosen at spawn** (seen in game, 2026-10-29): the drunken master's `mon_EP2_hardcore_FF` sits in his entity's own `CCharacterStatsParam` (`ff701_master.w2ent`), not under a parent ability. He has it when spawned on "Death March!"; a mode change removes it and does not add it back (spawned on "Blood and Broken Bones!" and switched to "Death March!", he never gets it; spawned on "Death March!" and switched away and back, he has lost it). Variants under a parent ability (kikimores, shaelmaars, slyzards, the guard knight, Olgierd) follow every mode change at once. His quest spawns him on the mode being played; the entity is 1.32's, so this is the engine's behaviour, not 5.x's.

**Decisions:** legacy's (PD3); ended [AI-20](ai.md#ai-20-fistfights)'s temporary deviation (the drunken master's +50 fist damage on "Death March!", slice D2). No variant has a stamina node, so none leaves STAM-08's `gm_npc_stamina.xml`; Bossek's and Golyat's emptied variants stay AI-03's.

**Verification (slice D2, 2026-10-29, both trees; 5.x-GM `53427f7b`; `tests/gmTestsDiff02.ws`, `tests/gmTestsDiffData.ws`).** `gen_diff.py --verify`: 55 abilities as legacy's in `abilities` and `abilities_plus`. The mode is set through the game's own path (`GMTestDiffSetMode`) and set back to the save's "Blood and Broken Bones!" after each run. Geralt is the player throughout, so Ciri's spawn call that caps the variants never runs (DIFF-06, resolved in slice D3): `GetSpawnDifficultyMode` read each mode as set.

| Check | How | Classic tree | New tree |
|---|---|---|---|
| Every DIFF ability as the game reads it: 112 attributes of 47 abilities (the variants' legacy values, 0 for each node only 5.x has; 8 empty variants have no attribute in either game) | scripted: definitions read (`GMTest_diffdata`, in the regression) | passed | passed |
| A kikimore worker (`kikimore_small.w2ent`) and warrior (`kikimore.w2ent`), a shaelmaar (`sharley.w2ent`), a slyzard (`living_world/enemy_templates/dracolizard.w2ent`), the guard knight `knight_hansa.w2ent` and Olgierd (`dlc/ep1/data/quests/main_npcs/olgierd.w2ent`), spawned frozen, each mode in turn: only that mode's variant among its parent's, and each stat's change from "Story and Sword!" is legacy's variant alone: kikimore venom −0.005, +0.005, +0.01 (warrior +0.015); the shaelmaar −150 armor on "Just the Story!", +0.2 poison and +0.2 poison damage-over-time resistance on "Death March!"; the slyzard, the guard knight and Olgierd unchanged on every mode | scripted (`gmtest_diff02_modes`) | 24 passed | 24 passed |
| The drunken master (`ff701_master.w2ent`) spawned on "Story and Sword!": fist bonus 150 (his Hard tier); spawned on "Death March!": `mon_EP2_hardcore_FF` held, 200 | scripted (`gmtest_diff02_master`) | 2 passed | 2 passed |
| A real fistfight on "Death March!" (the minigame started by script, AI-20's way): every punch of his on Geralt got +200 bludgeoning before the pool, his tier's 150 + legacy's 50 | **real**: his own punches (`gmtest_diff02_fists`) | 11 of 11 punches | 14 of 14 punches |

On a throwaway build without the slice's data (D1's `gm_diff.xml`; deleted), these failed: the data check (92 of 112 attributes 5.x's), 16 of the 24 mode reads (the 8 that passed involve no legacy change: the "Story and Sword!" bases and the kikimores' and guard knight's "Just the Story!"; failures such as the warrior's venom +0.045 and attack power +0.15 on "Death March!", the shaelmaar's −200 armor and −50% Essence, the guard knight's ×5 Vitality and +40 armor, Olgierd's +50% Vitality, Olgierd without a "Just the Story!" variant), the master's 150 on "Death March!" and his 13 real punches (+150 each). Regression 1,063 passed, 0 failed in each tree; `gmtest_panel()` 133. Resistances are read through the character stats: the ability manager answers −9999 for them ([development.md](../development.md#testing-in-game)).

### DIFF-03 The prologue's attack-power cut

| | |
|---|---|
| Kind | tuning |
| Pillars | P5 |
| 5.x class | clean |
| Flags | — |
| Depends on | AI-01 |
| Skill trees | n/a |
| Port form | `PrologModifier` given empty (`replace`) in `gm_diff.xml`, NG+ copy; 5.x's `OnSpawned` line left as it is (it never fires; legacy neither added nor filled the ability) |
| Port status | ported (slice D1, 5.x-GM `5d06b030`), verified in both trees (2026-10-29) |
| Open checks | — |
| Save impact | none |
| NG+ counterpart | applied (empty in both), untested |

**What it does:** not in the changelist (an omission). 1.32's `OnSpawned` means to cut the attack power of every non-guard enemy by 30% while Geralt is level 1 on "Just the Story!" and "Story and Sword!" (White Orchard's first fights); legacy empties the ability and drops the line. **The cut never applied** (found in slice D1, 2026-10-29): the line tests a local `playerLevel` that `OnSpawned` never sets, so no enemy gets the ability in 1.32 or 5.x; emptying it changes nothing in play unless something else adds it (no script or file in the repository's set does).

**5.x:** 1.32's (the ability −30% attack power; the dead line in `OnSpawned`). **Decisions:** legacy's; ended [AI-01](ai.md#ai-01-level-bonuses)'s temporary deviation (slice D1), which had no effect in play.

**Verification (slice D1, 2026-10-29, both trees):** at Geralt's level 1 on "Story and Sword!" and on "Just the Story!", six enemies spawned at their entity's own level (a bandit at 8, a ghoul 9, a werewolf 17, a golem 29, a rock troll 16, an endrega warrior 11): none got `PrologModifier` from `OnSpawned`, and each one's attack power with the ability (added by the test) and without it read the same, mult 1 (scripted, `gmtest_diff03`; 7 passed per mode and tree); the ability empty in the regression's data check. On the throwaway build the six reads failed (mult 0.7 with it).

### DIFF-06 Ciri

| | |
|---|---|
| Kind | tuning, system |
| Pillars | P5 |
| 5.x class | clean |
| Flags | balance |
| Depends on | DIFF-01, DIFF-02 (what the mode gives her enemies), DEF-04 and STAM-03 (her dodge and stamina, signed off), AI-01 (the Death March adjustment's code, already ported) |
| Skill trees | n/a (Ciri has no skill tree; Geralt's regression runs in both) |
| Port form | `difficulty/ciri.ws`: `@replaceMethod(CR4Game) GetSpawnDifficultyMode` (legacy's body, no Ciri cap; since DIFF-09 the option's cap while she plays, [DIFF-09](#diff-09-ciris-sections-difficulty)); `@wrapMethod(CR4Game) UpdateStatsForDifficultyLevel` (every update uses the spawn mode, so her spawn's capped call no longer caps: a deviation); `@addMethod(W3ReplacerCiri) GMCheckCiriAbilities` (legacy's `CheckCiriAbilities`) and `GMSetCiriQuestAbilities`, called from `@wrapMethod` `OnSpawned` and `OnCombatStart`; `@wrapMethod(CR4Game) OnPlayerChanged` re-levels every NPC near the new player (DIFF audit F1, a deviation); Ciri's eight abilities whole (`replace`) in `gm_diff.xml` by `gen_diff.py`, NG+ copy; legacy's `ciriquests` debug command not ported (PD8) |
| Port status | ported (slice D3, 5.x-GM `73734341`), verified in both trees (2026-10-29); the re-level at a player change (DIFF audit F1, 5.x-GM `38e2b55e`) verified in both trees (2026-10-31) |
| Open checks | a save loaded during one of Ciri's sections: not tested (the test save is Geralt's, and saving as Ciri is avoided). `OnPlayerChanged` does not run at a load (none at the test save's load), so in legacy her spawn's capped update may hold until the next mode change; the port's wrapper makes that update uncapped either way. Her quest abilities in their real quests (Q205, Q302, Q305 are not reachable from the test save; their journal entries were activated by script) |
| Save impact | none (the quest abilities are added and removed by journal state at her spawn and each combat start) |
| NG+ counterpart | applied (legacy's NG+ entries equal its regular ones; 5.x's NG+ adjustment −0.4 humans, +0.6 monsters, legacy's 0), untested |

**What it does** (changelist 1140–1141): Ciri's sections are played on the chosen mode, not capped at "Story and Sword!", and her stats are retuned for it:

| Ciri's ability (legacy's comment) | 1.32 and 5.x | Legacy |
|---|---|---|
| `Ciri_Q205` ("Lofoten Lvl 17", Skellige) | 250 health | 800 health, 150 armor, +250 attack power |
| `Ciri_Q305` ("Novigrad - Whoreson Lvl 12") | 500 health, +100 attack power | 500, 150 armor, +150 |
| `Ciri_Q403` ("KM battle Lvl 24") | 2,000, +500 | 2,000, 230 armor, +500, immune to frost |
| `Ciri_Q111` ("Sabbath - Witches Lvl 26") | 2,500, +600 | 2,500, 260 armor, +600 |
| `Ciri_Q501` ("Final - Lvl 30") | 2,500, +80 | 2,500, 320 armor, +150, immune to frost |
| `Ciri_Rage` (her rage at Kaer Morhen) | 10,000 health, sure crits | 5,000 health |
| `CiriHardcoreDebuffHuman`, `…Monster` (her enemies on "Death March!") | attack power `mult` +0.7 humans, +0.6 monsters (NG+: −0.4 humans, +0.6 monsters) | 0 |

Legacy also adds `Ciri_Q305` while "Q302 Ciri - Rescuing Dudu" or "Q305 Ciri - chase to the temple" is active and `Ciri_Q205` while "Q205 Ciri - safe heaven" is, removing them otherwise, at her spawn and at each combat start (`CheckCiriAbilities`; the changelist does not say why the quests' own grants were not enough). The strings it looks up are the entries' `uniqueScriptIdentifier` in 5.x's journal files too (`gameplay\journal\quests\q302rescuingdudu.journal`, `q305cirichasetothetemple.journal`, `q205cirireplacer.journal`).

**Her spawn's update** (seen in game, slice D3): Ciri's `OnSpawned` (1.32's, 5.x's and legacy's) calls `UpdateStatsForDifficultyLevel(MinDiffMode(mode, "Story and Sword!"))`, which sets every NPC's difficulty ability and per-enemy variants for that mode (the native update uses its argument, not the spawn mode). On a player change (`Ciri()`), `CR4Game.OnPlayerChanged` runs right after her `OnSpawned` and updates them again for the spawn mode, so with legacy's uncapped `GetSpawnDifficultyMode` they were back on "Death March!" by the next call; a variant in an enemy's own entity list (the drunken master's) is dropped by the capped update and never comes back ([DIFF-02](#diff-02-per-enemy-difficulty-variants)). `OnPlayerChanged` does not run when a save is loaded. A mode change also re-levels every NPC (vanilla's `OnGameDifficultyChanged`), so in legacy, on "Blood and Broken Bones!" and "Death March!", the capped update recomputed the enemies already near Ciri from their own level with her as the player (Geralt's scaling dropped, her adjustment added); on the two lower modes, and with the port's uncapped update on every mode, the NPCs already hold the mode, nothing changes and nothing is recomputed (DIFF audit F1).

**The re-level at a player change** (DIFF audit F1, the owner's option (a), 2026-10-31): the port re-levels every NPC within 10,000 m of the new player after `OnPlayerChanged`, both ways (legacy's `ResetLevel`, as a scaling option change does): enemies near Ciri when her section starts are at their own level (her sections are not scaled) with her "Death March!" adjustment (empty, PD5), and back at Geralt's scaling when he returns. The mode stays the chosen one: `GetSpawnDifficultyMode` is the one place that decides it for her sections (her spawn's update, `OnPlayerChanged`'s update, every NPC spawned while she plays; the modifiers follow the difficulty ability it gives). As any reset, it gives an NPC whose level a script set its entity's level back and rolls a random level again.

**Implementation (legacy):** `CR4Game.GetSpawnDifficultyMode` (the `MinDiffMode(…, EDM_Medium)` branch commented out), the eight abilities in `opp_base_abl.xml` and NG+, `W3ReplacerCiri.CheckCiriAbilities`, `OnSpawned`, `OnCombatStart`; the Death March adjustment's code is in `InternalAddLevelBonuses` (AI-01: Vitality users other than wolves and boars get the human one, Essence users the monster one, only while Ciri is the player on "Death March!").

**5.x:** 1.32's (read in game on a build without the slice: as Ciri on "Death March!" the spawn mode is "Story and Sword!", spawned enemies hold `difficulty_CommonHardcore` and `difficulty_CommonMedium` with ×1 health and damage, the bandit's attack power multiplier 1.77 with the adjustment and 1.07 without it, the ghoul's 1.64 and 1.04; her abilities 1.32's).

**Decisions:** legacy's (PD5): no cap, her stats, the adjustment zeroed, the two quest abilities by journal state.
- **Deviation:** her spawn's update of the NPCs around her uses the chosen mode. Legacy kept vanilla's call that sets them for at most "Story and Sword!": their health and damage multipliers and per-enemy variants until `OnPlayerChanged` follows on a player change, possibly until the next mode change after a save is loaded in her sections, and the drunken master's own variant for good. On the two higher modes that mode change also re-levelled the enemies already near her (the effect the next deviation now gives on every mode). The port's wrapper of `UpdateStatsForDifficultyLevel` follows the changelist's "Removed vanilla difficulty level restrictions for Ciri" (porter's call 2026-10-29, confirmed by the owner, 2026-10-31)
- **Deviation:** a player change (Geralt to Ciri and back) re-levels every NPC near the new player from its own level, on every mode and both ways: enemies near Ciri when her section starts drop Geralt's enemy scaling, and get it back when he returns. Legacy got the first only on "Blood and Broken Bones!" and "Death March!", as a side effect of the capped spawn update (a mode change re-levels), and nothing on the way back (Geralt's scaling came back at his next level-up, an option or a mode change). Chosen by the owner for legacy's result with the uncapped update (DIFF audit F1, option (a), owner, 2026-10-31). The re-level is a full reset, as an option change: an NPC whose level a script set gets its entity's level back, and a random level is rolled again (porter's call, confirmed by the owner, 2026-10-31)

**Verification (slice D3, 2026-10-29, both trees; 5.x-GM `73734341`; `tests/gmTestsDiff06.ws`, `tests/gmTestsDiffData.ws`).** Played as Ciri with vanilla's `Ciri()` and back with `Geralt()` (`theGame.ChangePlayer`: no scene, no teleport, no time skip; [game-automation.md](../game-automation.md#playing-as-ciri)), her enemies spawned next to her. The mode was set through the game's own path and set back to the save's "Blood and Broken Bones!" after each run. No autosave was written.

| Check | How | Classic tree | New tree |
|---|---|---|---|
| Ciri's eight abilities as the game reads them (22 attributes: legacy's values, 0 for the adjustment) | scripted: definitions read (`GMTest_diffdata`, in the regression: 55 abilities, 134 attributes) | passed | passed |
| As Ciri, each of the four modes: the spawn mode is the mode; a spawned bandit and ghoul hold that mode's difficulty ability alone with legacy's multipliers (×0.5 / ×0.75 to ×2.5 / ×3.5); a kikimore warrior and a shaelmaar spawned before the change hold that mode's variant | scripted mode changes (`gmtest_diff06_modes`) | 20 passed | 20 passed |
| As Ciri on "Death March!": the bandit holds `CiriHardcoreDebuffHuman`, the ghoul `CiriHardcoreDebuffMonster` (added by AI-01's level code), attack power multiplier the same with and without it (1.07, 1.04) | scripted (`gmtest_diff06_debuff`) | 2 passed | 2 passed |
| A real fight as Ciri on "Death March!": the bandit and the ghoul unfrozen, Ciri immortal; every hit on her ×3.5 at the difficulty step (e.g. 282.7 → 989.5); Ciri's own light attacks (through the input handler) took the ghoul from 2,090 to 1,351 | **real**: the enemies' attacks and hers (`gmtest_diff06_fight_a`, `_b`) | 7 of 7 and 10 of 10 hits (two runs) | 9 of 9 and 5 of 5 hits (two runs) |
| Her quest abilities and rage added on her: health, armor, attack power and frost resistance move by legacy's values (Q205 +800 / +150 / +250, Q403 and Q501 frost +1, her rage +5,000 health) | scripted (`gmtest_diff06_abl`) | 6 passed | 6 passed |
| The journal check: "Q205 Ciri - safe heaven" activated before `Ciri()`, and she spawns with `Ciri_Q205`; each of the three entries activated and put back (`ActivateEntry`), and `GMCheckCiriAbilities` adds and removes the ability; the rule for the four combinations; Q305's entry active and a hostile bandit spawned, and her real combat start adds `Ciri_Q305` | journal states set by script (the quests are not reachable from the test save); her spawn and combat start real (`gmtest_diff06_jset`, `_spawned`, `_journal`, `_combat_a`, `_b`) | 16 passed | 16 passed |
| Her spawn's update: NPCs present at the change (a kikimore warrior, a shaelmaar, the drunken master, spawned on "Death March!") keep "Death March!"'s ability and variant at the end of her `OnSpawned`, after `OnPlayerChanged` and after `Geralt()` | a probe in her `OnSpawned`; scripted reads (`gmtest_diff06_var`) | passed | passed |
| Geralt after Ciri: recorded before `Ciri()` and compared after `Geralt()`: his level, experience, skill points, money, mutation, equipped skills, every ability (skills' and items' included), every item with its quantity and whether it is equipped, his effects, maximum Vitality, stamina, toxicity and adrenaline, attack power, sign intensity, armor, two resistances and immortality are identical; his Vitality is not lower (it regenerates). He returns where Ciri stood (0.8 to 6.7 m away) | scripted state comparison (`gmtest_diff06_snap`, `_same`; 63 lines classic, 78 new tree) | passed | passed |

On a throwaway build without the slice (5.x's Ciri code and data, the test helpers kept; deleted), these failed: 14 of the 22 Ciri attributes in the data check, the spawn mode ("Story and Sword!" on "Blood and Broken Bones!" and "Death March!"), both enemies' multipliers on the two higher modes (×1 / ×1, two difficulty abilities held), the adjustment (+0.7 and +0.6), the six ability reads, the journal check at her spawn and at combat start (no ability added), the variants at her spawn (the kikimore and the shaelmaar on "Story and Sword!"'s, the drunken master's own variant lost) and all ten real hits (×1, raw damage 523 to 782 with 5.x's adjustment). The direct calls of the journal rule passed there (the methods were kept so the tests compile). Regression 1,063 passed, 0 failed in each tree; `gmtest_panel()` 133. Once, after a Ciri run, the panel's AI-18 stone check found no knockdown on its bandit; it passed in three other runs, one of them after a Ciri run in the same launch.

The re-level at a player change (DIFF audit F1) is verified with the audit's fixes ([close-out](#diff-audit-close-out)).

### DIFF-07 Money taken by guards

| | |
|---|---|
| Kind | tuning |
| Pillars | P6 |
| 5.x class | overlap |
| Flags | — (DD2 decided) |
| Depends on | — |
| Skill trees | n/a (Geralt's regression runs in both) |
| Port form | `difficulty/guards.ws`: `@replaceMethod(CR4PlayerStateUnconscious) TakeMoneyFromPlayer` (legacy's body) |
| Port status | ported (slice D4, 5.x-GM `232d10f8`), verified in both trees (2026-10-29) |
| Open checks | a knockout by the world's own guards (none stands near the test save; the test's guard is a spawned soldier given the guard type, as a community's spawn tree gives it) |
| Save impact | none |
| NG+ counterpart | none |

**What it does:** not in the changelist (an omission). When guards knock Geralt out, they take a quarter of his money on every mode (1.32: 25%, 50%, 75%, all of it by mode).

**The path** (5.x, as 1.32): `CR4Player.OnDeath` sends Geralt to the `Unconscious` state instead of death when the killing blow's attacker is an NPC of type `ENGT_Guard` and he is not swimming, in water deeper than 0.5 m or on a horse or boat (`OnKilledByGuard`, then `PushState('Unconscious')`; an elevator and `WillBeUnconscious` take the same state without the toll). The state's `killedByGuard` branch is the only caller of `TakeMoneyFromPlayer`: fade out, holster, the toll, `TimeFlow` (about 2.7 game hours pass: seen 2.73 h in each run), the sword back, fade in, then the message. Geralt is not moved (1.5 m, the fall animation; `TeleportPlayerToNewPosition` exists but nothing calls it) and is revived at full Vitality. No other path takes the toll; the other `RemoveMoney` callers are shops, crafting, scenes and quests. The world's guards get their type from their community's spawn tree (`SetNPCTypeEffector`); a guard template spawned alone is a commoner (type 1).

**What the player sees:** only "You have lost coin." (string 1066164, `panel_hud_message_guards_took_money`, shown on the HUD after the fade-in), and a loading-screen hint (1091438): "Don't upset the guards. If provoked, they'll try bring you to order by force, then take some of your coin as a fine for causing trouble." Neither states a share or an amount, in 5.x or legacy, so no text changes; Ghost Mode's own strings have none either.

**5.x:** 25%, 40%, 65%, 85% by mode, at most 750, 1,250, 1,750, 2,250 crowns.

**Decisions:** legacy's quarter of Geralt's money on every mode, with no cap (DD2, owner, 2026-10-29).

**Verification (slice D4, 2026-10-29, both trees; 5.x-GM `232d10f8`; `tests/gmTestsDiff07.ws`).** With 20,000 crowns, where a quarter (5,000) is above every 5.x cap. The mode was set through the game's own path and set back to the save's "Blood and Broken Bones!", Geralt's money back to his 250, after each run. No autosave was written.

| Check | How | Classic tree | New tree |
|---|---|---|---|
| A real knockout on "Just the Story!" and on "Death March!": a hostile Nilfgaardian deserter given the guard type (level 17, AI-01's guard rule) fights Geralt (god mode off, 10% Vitality) until he goes down; the state's `killedByGuard` is set, the money falls once, by 5,000 of 20,000 (5.x: 750 and 2,250); Geralt up again, alive, at full Vitality; 2.73 game hours passed, Geralt moved 1.5 m; "You have lost coin." on screen | **real** (the guard's own attacks; `gmtest_diff07_a`, `_b`) | 3 of 3 on each mode | 3 of 3 on each mode |
| The toll of 20,000 and of 1,001 crowns on each of the four modes: 5,000 and 250 | scripted: the state's `TakeMoneyFromPlayer` called directly (`gmtest_diff07(true)`) | passed | — |
| The same on the current mode (in the regression) | scripted (`GMTest_diff07`) | passed | passed |

On a throwaway build without the slice (deleted), these failed: the four modes' toll (750 / 250, 1,250 / 400, 1,750 / 650, 2,250 / 850), the regression check, and a real knockout on "Death March!" (2,250 taken). Regression 1,064 passed, 0 failed in each tree; `gmtest_panel()` 133. The regression check keeps to the current mode: changing the mode inside the regression rebuilt the AI-06 samples' stats (the drowner lost its set level, failing three AI-01 checks and the AI-18 stone check).

## DIFF-B Scaling options and levels shown

### DIFF-04 Enemy scaling options

| | |
|---|---|
| Kind | system, infra |
| Pillars | P5, P10 |
| 5.x class | conflict |
| Flags | balance, needs-decision (DD1, DD4) |
| Depends on | AI-01 (the level code, signed off), OPT-01 (the menu framework, defaults, change hooks), DIFF-01 (the multipliers the modifiers add to) |
| Skill trees | n/a (levels feed SKL-12's finisher rule and UI-12's colour through the level difference, unchanged) |
| Port form | the group `GMScalingOptions` in `menu/modGhostMode.xml` with legacy's ids, presets and labels (21 strings × 9 languages, legacy's ids); per-option defaults in `options/gmOptions.ws` (DD1); `difficulty/scaling.ws`: the getters, `@addMethod(CNewNPC) GMApplyLevelScaling` (legacy's scaling branches, called from `ai/levels.ws`'s `AddLevelBonuses` in place of DA2's fixed preset), `GMIsScalingOption`, `GMOnScalingOptionsChanged`; `@addMethod(CNewNPC) GMAddOptionBonuses` (legacy's `ModSignsAddBonuses`) and the progressive count in `GMInternalAddLevelBonuses`; `@addField` saved `gmSavedRandomLevel` (as UI-10's kill counts); `@addMethod(CActor) GMIsBeast`; the levels of NPCs around Geralt recomputed when a scaling option changes (OPT's change hook, as `GMOnQoLOptionsChanged`); the five `ModSigns*` abilities in `gm_diff.xml`, NG+ copy; since the DIFF audit (F2, F3; 5.x-GM `38e2b55e`): `GMAddOptionBonuses` gives the owner's (1 + mode) × (1 + enemy + boss), floored, in steps of 1, 0.1 (legacy's `ModSigns*`), 0.01 and 0.001 (twelve `GM_Scaling*` abilities, `gen_diff.py`'s `OWN`), the steps taken off in the `OnGameDifficultyChanged` wrapper; `@addMethod(CNewNPC) GMRecomputeLevelBonuses` from `@wrapMethod(CR4HudModuleBossFocus)` `OnShow` and `OnHide` and the global `@wrapMethod HealthBarVisiblityQuest`; DMG-05's step reads the damage multiplier as at least 0 |
| Port status | ported: part 1 (slice D5a, 5.x-GM `f929bfc3`) and part 2 (slice D5b, 5.x-GM `ad314f9f`), each verified in both trees (2026-10-30); the owner's decisions on the DIFF audit's F2 and F3 (5.x-GM `38e2b55e`) verified in both trees (2026-10-31) |
| Open checks | the group seen in Options > Mods > Ghost Mode with its 12 options, labels and the "Scaling Presets" row, and an option and a preset changed there by hand: **verified** ([cleared run](#cleared-run-on-screen-2026-11-01), 2026-11-01). Still open: a fight's start after a load under a random type (scripted: the recompute combat start makes, `RecalcLevel`); real guards in the world (AI-01's). Not run: a real enemy attack under the damage modifier (scripted hits through the damage manager cover the step, as DIFF-01's real bite showed for the same step); a real story boss whose quest shows the bar (the bar given to a spawned bandit through the quest's own path, `ShowBossFightIndicator`'s body, and the quest function `HealthBarVisiblityQuest` are scripted checks, DIFF audit F2), and a contract monster's own bar going and coming (the same `OnShow` and `OnHide`) |
| Save impact | a new saved field per NPC, the random level (`gmSavedRandomLevel`). **Verified** 2026-10-30: kept across a save and a load; the health and damage modifiers and progressive bonuses come back as one set, also at the fight's start and a full recompute (DIFF audit F4, `gmtest_diff04_lsave_*`); an older save without it loads, its NPCs reading 0 (no random level yet), rolled at their next level computation. Option values live in the user settings. Removing the mod: unsupported |
| NG+ counterpart | applied (the `ModSigns*` steps are new: as is), untested |

**What it does** (changelist 1149–1152, 1179–1216): enemy levels follow Geralt's as the player chooses, for Geralt's sections only (not Ciri's), on top of AI-01's model (guards at his level +16 unless "No additional levels for guards", level 1 enemies without bonuses):

| Option | Legacy's rule |
|---|---|
| "Enemy scaling": None | Enemies keep their own level |
| Upscale | Enemies below Geralt's level are raised to it; higher ones keep theirs |
| Match | Every enemy is set to Geralt's level |
| Soft upscaling | Enemies more than 6 levels below Geralt are raised to 6 below (AI-01's fixed preset today) |
| Random / Random no downscaling | A random level between Geralt's level + the lower and + the upper bound (−12 to +12), kept per enemy (saved) until it falls outside the bounds; the second never below the enemy's own level |
| "Use progressive level bonuses", "Level delta" (LD), "Abilities per level delta" (AD) | Above level LD, an enemy gets round((1 + AD/LD) × level − AD) − 1 per-level bonuses instead of level − 1 (the "Hardcore" preset's 10 and 5: 24 instead of 19 at level 20, 39 instead of 29 at level 30) |
| "No additional levels for guards" | Guards stay at Geralt's level |
| "Do not upscale animals" | Wolves, boars and other beasts on Vitality skip scaling, and with scaling on any above half Geralt's level are set to half of it (the changelist says only "disable upscaling for animals"; the port follows the code, DD4) |
| "Enemy health modifier", "Enemy damage modifier" (−100% to +500%, steps of 10%) | Legacy: added to every NPC's difficulty multipliers (DIFF-01): "HP*(1 + difficultyModifier + enemyModifier + bossModifier)"; health at −100% is −99%. **The port** (owner, DIFF audit F3, a deviation): the mode multiplies, the modifiers add to each other: (1 + mode) × (1 + enemy + boss), health and damage separately, health at least ×0.01, damage at least ×0 |
| "Additional health/damage modifier for bosses" | Added to the enemy modifier for bosses: NPCs tagged `HideHealthBarModule`, the tag that puts an enemy's health bar at the top of the screen (contract monsters with the boss bar get it at spawn, `W3MonsterHuntNPC.displayBossBar`; quests and the boss-bar HUD module add it to others). Legacy read the tag only when the level was computed; **the port** recomputes the NPC's bonuses whenever the bar adds or removes the tag (owner, DIFF audit F2, a deviation) |
| "Enemy scaling": Interpolated (new, [DIFF-10](#diff-10-interpolated-enemy-scaling)) | Enemies below Geralt's level gain half the difference, rounded down |
| Presets | "Recommended": Soft upscaling, the rest off; "Hardcore": Upscale, progressive LD 10, AD 5, +50% health and damage for all, +50% more for bosses; "Off": None, the rest off |

Changing an option recomputes the levels of every NPC near Geralt; legacy's list of options that trigger it (`gmIsScalingOption`) misses the progressive level-up, its two level-delta options and the two boss modifiers, which then apply at the next level-up. The port adds the five to the list, so every option applies at once (the owner's decision, 2026-10-29, changing PD6: a deviation). The Blood and Wine banshee's summons never scale. Vanilla's "Enemy Upscaling" toggle does nothing (AI-01, since slice A1). Without a preset applied, legacy's code reads every scaling option as unset: no scaling, no extra health or damage, guards +16; the port applies the "Recommended" preset's values instead (DD1).

**Implementation (legacy):** `CNewNPC.AddLevelBonuses` (scaling branches, `ModSignsAddBonuses` before the `NPCDoNotGainBoost` stop), `InternalAddLevelBonuses` (progressive count), `ModSignsAddBonuses`, `RemoveAllLevelBonuses` (the `ModSigns*` abilities), `SetLevel`, `ResetLevel`, `savedRandomLevel`, `CActor.IsBeast`; `W3GameParams.GetEnemyHealthMult` and 11 other getters; `CR4Game.gmUserSettingsScaling`; `gmIsScalingOption`; `modSignsConfig.xml`'s `GMScalingOptions`; `ModSignsAdditional*`, `ModSignsMaxHealthNegative` (and NG+).

**5.x:** none in this place: the level code is AI-01's port of legacy's, with soft scaling fixed (DA2).

**Decisions:** legacy's options and presets; "Do not upscale animals" as legacy's code, lowering animals above half Geralt's level to half of it (DD4, owner, 2026-10-29); every scaling option re-levels the enemies near Geralt at once (the owner's change of PD6, 2026-10-29). Slice D5b, porter's calls without play effect: legacy's removal of four older modifier names (`ModSignsAdditionalEssence`, `…Vitality` and their negatives, "old mod version, just in case"; no file defines them) is not ported; the shared "Recommended" and "Off" preset labels (OPT's, ids 2110992448 and 2110992449) come with this slice, the first group with presets; only the scaling group's presets re-level (legacy's preset hook also flagged the experience, gameplay and QoL groups, whose presets are OPT's and XP's, not ported yet).
- **Deviation:** all scaling options apply at once; legacy's list missed the progressive and boss options, which waited for Geralt's next level-up (owner, 2026-10-29)
- **Deviation:** a random level survives saving and loading: an enemy restored from a save keeps the level a random scaling type gave it at its next level computation (the start of a fight), until a scaling option or the mode changes or its level falls outside the bounds as Geralt levels. Legacy reset it at every spawn, a load included, so every reload rolled each saved enemy's level again at the start of the next fight (porter's call 2026-10-30, confirmed by the owner, 2026-10-31)
- **Deviation:** with the menu never opened, every unset scaling option takes the "Recommended" preset's value: soft upscaling (enemies more than 6 levels below Geralt raised to 6 below), nothing else (no extra health or damage, no progressive level bonuses). Legacy's code read unset options as no scaling, though its readme told players to apply the recommended presets; the port has been balanced and tested with soft upscaling since AI-A (DD1, owner, 2026-10-29).
- **Deviation:** the difficulty mode multiplies the menu's health and damage modifiers, which add to each other: (1 + mode) × (1 + enemy + boss), health at least ×0.01, damage at least ×0. Legacy summed them, 1 + mode + enemy + boss, so the modifiers counted the same on every mode and could take enemies to no health or a negative damage factor on the lower modes; "Death March!" with the "Hardcore" preset now gives a boss ×5 health and ×7 damage (legacy ×3.5 and ×4.5) (DIFF audit F3, owner, 2026-10-31)
- **Deviation:** the boss modifiers (and AI-01's rule of no "High" or "Deadly" ability for bosses) follow the boss bar: an NPC's bonuses are recomputed when the boss bar or the quest tag function adds or removes its boss tag, so story bosses whose bar appears in the fight get them during it and lose them when it goes. Legacy read the tag only when the level was computed, so story bosses never got them unless Geralt levelled up, or an option or the mode changed, while the bar was up (DIFF audit F2, owner, 2026-10-31: "fix it so the scaling options affect bosses like a user would expect"). The recompute keeps the NPC's current level (the level a scaling type or a script gave it), not a full reset of the level; and the quest function `HealthBarVisiblityQuest` counts as a boss path, next to the boss bar's own `OnShow` and `OnHide` (two porter's calls, confirmed by the owner, 2026-10-31)

**How the modifiers combine** (the owner's rule, DIFF audit F3, 2026-10-31): for health (`health_final_multiplier`) and damage (`damage_final_multiplier`) separately, multiplier = (1 + mode) × (1 + enemy modifier + boss modifier), the boss modifier for bosses only; health at least ×0.01, damage at least ×0. So "Death March!" with the "Hardcore" preset: a boss ×2.5 × 2 = ×5 health and ×3.5 × 2 = ×7 damage, any other enemy ×3.75 and ×5.25; "Story and Sword!" with +50% health ×1.5; "Just the Story!" with −50% health 0.5 × 0.5 = ×0.25; health −100% ×0.01 on any mode, damage −100% ×0. Legacy added them to the mode's multiplier (on "Blood and Broken Bones!" with the "Hardcore" preset ×2.5, a boss ×3, where the port has ×3 and ×4; ×0 or less on "Just the Story!" from −50% health, F3). (1 + mode) is read from the NPC, its multiplier with no step on (the base 1 and its difficulty ability: nothing else in 5.x's or Ghost Mode's data touches the two attributes), and the difference, rounded to 0.001, is added as step abilities of 1 (`GM_ScalingHealth_p1`, `…_n1`, `GM_ScalingDamage_*`), 0.1 (legacy's `ModSignsAdditionalHealth`, `…HealthNegative`, `…Damage`, `…DamageNegative`), 0.01 and 0.001; legacy's −0.99 `ModSignsMaxHealthNegative` is no longer added (the floor replaces it; still removed, for NPCs from older saves). A mode change takes the steps off before it swaps the difficulty ability, and its own re-level adds the new mode's: steps sized for the old mode met the new mode's ability before (from health −100% on "Blood and Broken Bones!" to "Just the Story!" the multiplier read 0.5 − 1.99, and a wolf was left alive with a negative maximum health). The damage one acts where DMG-05's final-damage step reads the multiplier (hostile NPCs hitting Geralt), read there as at least 0 (at the floor the step sum can read a hair below 0, about −2e-8). When the maximum health changes (a modifier, a mode change, the boss bar), the current health keeps its share of it (`GMRestoreHealthPerc`, AI-01's rule).

**The boss modifiers follow the boss bar** (the owner's rule, DIFF audit F2, 2026-10-31): whenever 5.x's code adds or removes `HideHealthBarModule` on a living NPC, its bonuses are recomputed at its current level (the level a scaling type or a script gave it is kept, as at Geralt's level-up): the boss-bar HUD module's `OnShow` and `OnHide` (the quest block `ShowBossFightIndicator` through `RunEvent_BossFocusModule_ShowBossIndicator`, the delayed HUD event, a contract monster's own bar shown when it sees Geralt and hidden 45 m away or at its death) and the quest function `HealthBarVisiblityQuest` (which adds the tag when a quest hides an NPC's health bar). So a story boss gets the boss modifiers when its bar appears and loses them when it goes, and AI-01's rule that bosses get no "High" or "Deadly" ability follows the same recompute. Contract monsters tagged at their spawn have them from their first computation. Only a change of the tag recomputes (a bar shown again for an NPC already tagged does not), and the steps are removed before they are added, so nothing is applied twice.

**Notes (as legacy, part 2):** every NPC gets the modifiers, allies, NPCs with `NPCDoNotGainBoost` and Ciri's sections included (legacy's "for Geralt only" test is commented out); they are recomputed with the level (an option change, a preset, Geralt's level-up, a fight's start after a reset). Progressive level bonuses change only the count of per-level abilities, not the level or the level shown. Applying a preset re-levels like an option change (legacy's `OnPresetApplied`).

**Notes (as legacy, part 1):** an option change applies when the options menu closes (the menu's `SaveChangedSettings`, as legacy's `gmUserSettings`) and re-levels every NPC within 10,000 m. An NPC whose level a script set (`SetLevel`: summons, quest NPCs) gets its entity's level back at a scaling option change, as legacy's `ResetLevel`. "Do not upscale animals" counts what the game's own categories call animals and beasts: wolves, the black, grizzly and white bears (`MC_Beast`, on Vitality), horses, deer and hares (`MC_Animal`); not the bear berserker (`bear_berserker_lvl1`, a werebear: `MC_Cursed`, on Essence). Legacy's code is the same (`IsBeast` reads `MC_Beast`) and legacy changed none of these entities, so it agrees (not run in 1.32). The virtual scaling-type variable reads "-1" while unset ([development.md](../development.md#options-menu)).

**Verification (slice D5a, 2026-10-30, both trees; 5.x-GM `f929bfc3`; `tests/gmTestsDiff04.ws`).** Nine frozen samples (bandits of level 2, 15 and 30, a guard, wolves of 3 and 15, the bear berserker of 12, drowners of 3 and 25) levelled with Geralt held at a set level (AI-06's test override of his level), each against legacy's rule computed in the test: the level and as many `DisplayedLevelAbl` abilities. The options were set back after each check, and the settings file left as it was found (no scaling group). No autosave was written.

| Check | How | Classic tree | New tree |
|---|---|---|---|
| None, Upscale, Match and Soft upscaling at Geralt 10 and 20; "No additional levels for guards" with None and Match; "Do not upscale animals" with None, Upscale and Soft (DD4: the level-15 wolf at 5 and 10, the level-3 wolf kept) | scripted (`gmtest_diff04_levels`) | 19 of 19 | 19 of 19 |
| Random and Random no downscaling (−3..3 at 10 and 20, 0..0, −12..−10): every level in the bounds, guards then +16, never below the own level for the second; kept while Geralt's next level leaves it in the bounds, rolled again when not; 100 rolls cover 11 of 11 values | scripted (`gmtest_diff04_random`) | 14 of 14 | 14 of 14 |
| DD1 from a settings file without the group (edited with the game closed): the options read soft upscaling, bounds 0, both toggles off; the samples level as soft upscaling; the game then writes these values into the file (OPT's defaults) | scripted (`gmtest_diff04_opts`, `gmtest_diff04_default`) | passed | — (a setting, not a tree) |
| DD1 with the options emptied in game | scripted (`gmtest_diff04_default`) | 4 of 4 | 4 of 4 |
| A change through the menu's code path: the pause menu open (`ingamemenu()`), the scaling type set and the menu's own `OnOptionValueChanged` called as its Flash does, the menu closed: every NPC within 100 m (a hostile spawned bandit and wolf, the world's ghouls, horses, deer, hares, Vesemir) at the new type's level at once | scripted (`gmtest_diff04_change_*`) | Soft to Match: 14 of 14 | Soft to Upscale: 16 of 16 |
| Every name in the scaling list through the same path: the six D5a variables and D5b's seven (the two modifiers and the five of PD6) re-level every NPC near Geralt; a gameplay option (sign cooldown) does not | scripted (`gmtest_diff04_hook_names`) | 14 of 14 | 14 of 14 |
| A save and a load under Random −12..12 at Geralt 1: four persistent bandits (levels 1, 8, 4, 3) saved into a new manual slot and loaded: each shows its level, keeps it at a recompute (as at a fight's start) and was restored; an option change and a mode change after the load roll again | scripted (`gmtest_diff04_save_*`; the save made in the classic tree, loaded in each) | 3 of 3 | 3 of 3 |
| An older save without the field (the test save) under Random: loads, its NPCs roll at their recompute | scripted (`gmtest_diff04_world`, `gmtest_ai06_near`) | passed | — |
| The types and the guards' option on two samples (in the regression) | scripted (`GMTest_diff04`) | passed | passed |

D5b's option names could not be set by script in slice D5a (no menu entries yet); the hook's reaction to them was checked by name, their effect with slice D5b. On a throwaway build without the slice's behaviour (DA2's fixed soft scaling, no scaling defaults, no change hook; the menu and tests kept so they compile; deleted), these failed: 16 of the 19 level checks (only Soft without the animal option passed, which DA2 fixed), 13 of the 14 random checks, DD1 from a file without the group (the type read None; the samples still levelled soft by DA2's code), the change to Match (1 of 24 NPCs at its level: Vesemir, unchanged either way) and 13 of the 14 hook checks (the sign cooldown's passed). Regression 1,076 passed, 0 failed in each tree; `gmtest_panel()` 133 (in the classic tree's first run the panel's AI-18 stone check found no knockdown, a known intermittent; 133 on a fresh launch).

**Verification (slice D5b, 2026-10-30, both trees; 5.x-GM `ad314f9f`; `tests/gmTestsDiff04b.ws`).** Four frozen samples: a bandit (Vitality), a drowner (Essence), a wolf (`AnimalLevelBonus`) and mh102's arachas, a contract monster spawned with the boss bar (`HideHealthBarModule`; Essence). Expected values are legacy's rules computed in the test from the options; the mode was the save's "Blood and Broken Bones!" (×2 / ×2). The options were set back after each check, and the settings file left as it was found (no scaling group). No autosave was written.

| Check | How | Classic tree | New tree |
|---|---|---|---|
| The five `ModSigns*` abilities as the game reads them (legacy's values, in the DIFF data test: 60 abilities, 139 attributes) | scripted: definitions read (`GMTest_diffdata`, in the regression) | passed | passed |
| Each modifier on the four samples: health and damage multipliers, the step abilities and maximum health = health × multiplier, for none, health +50%, damage +50%, the "Hardcore" four at +50% (the boss ×3 / ×3, the rest ×2.5), the boss modifiers alone (+100% / −50%: only the boss changes), −50% / −30%, −100% (health ×1.01 through the −99% step, damage ×1), the boss's health below −90% in sum (−60% and −50%: the −99% step for the boss, six −10% steps for the rest), +500% (×7) | scripted (`gmtest_diff04b_mods`) | 11 of 11 | 11 of 11 |
| Scripted hits (200 slashing) of each sample on Geralt through the damage manager: the final-damage step ×2 with no modifier, ×2.5 (the boss ×3) with the "Hardcore" modifiers, ×1.5 at −50% | scripted (`gmtest_diff04b_hits`) | 12 of 12 | 12 of 12 |
| Progressive level bonuses, every sample matched to the level: off 19 at 20 and 29 at 30; LD 10, AD 5: 24 at 20 and 39 at 30 (legacy's figures), 7 at 8 and 9 at 10 (at or below LD); LD 0: 19; LD 5, AD 10: 49 at 20; LD 20, AD 20: 39 at 30; the level and the displayed-level abilities unchanged | scripted (`gmtest_diff04b_prog`) | 9 of 9 | 9 of 9 |
| DD1: the seven options unset (cleared in memory): defaults the "Recommended" preset's, no modifier, per-level bonuses level − 1; and from a settings file without the group (edited with the game closed): all 12 options read the preset's values at the load | scripted (`gmtest_diff04b_default`, `gmtest_diff04_opts`) | 2 of 2; file passed | 2 of 2 |
| The three presets through the menu's code path: the pause menu open, the menu's own `OnPresetApplied` called as its Flash does, the menu closed; the options are legacy's table, and every sample at once at the preset's level, per-level bonuses and modifiers at Geralt 20 ("Hardcore": the bandit 8 → 20 with 24 bonuses and ×2.5, the boss ×3; "Off": back to 8 with 7; "Recommended": 14 with 13) | scripted (`gmtest_diff04b_preset`, `_preset_check`) | 6 of 6 | 6 of 6 |
| PD6: each of D5b's seven options changed through the menu's `OnOptionValueChanged` and closing, one at a time (progressive on, LD 10 → 5, AD 5 → 10, health +30%, damage +20%, boss health +50%, boss damage −50%): the value read back, and every sample carries the new count or steps at once (19 → 24 → 34 → 49 per-level bonuses, then the steps) | scripted (`gmtest_diff04b_relevel_*`) | 14 of 14 | 14 of 14 |
| A bandit under the "Hardcore" modifiers and progressive bonuses at Geralt 20 (24 bonuses, ×2.5), then with the boss tag (×3) (in the regression) | scripted (`GMTest_diff04`) | passed | passed |

On a throwaway build without the slice's behaviour (D5a's scripts and data; the menu entries, labels and tests kept so they compile; deleted), these failed: the data check (the five abilities read 0), 8 of the 9 modifier settings (only "no modifier" passed), the 8 hits with a modifier (×2), the 4 progressive cases with more bonuses than level − 1, the DD1 defaults (none), the "Hardcore" and "Off" presets (the samples stayed at soft upscaling: no re-level, no modifier), all 7 re-level checks, and the two regression checks. The "Recommended" preset passed there (the samples were already at soft upscaling) and so did the DD1 effect check (with nothing set, nothing is added either way). Regression 1,092 passed, 0 failed in each tree; `gmtest_panel()` 133 (in the new tree's first run the panel's AI-18 stone check found no knockdown, the known intermittent: 132 passed, 1 failed; 133 on a fresh launch).

### DIFF-05 Fake levels

| | |
|---|---|
| Kind | ui, content |
| Pillars | P7 |
| 5.x class | clean |
| Flags | — |
| Depends on | UI-12 (the displayed level, signed off), AI-06 (the 71 files whose fake level legacy made real) |
| Skill trees | n/a |
| Port form | `ui/enemyLevel.ws` (UI-12's replacement of `GetExperienceDifferenceLevelName`): the addon, the NG+ addon and the cap dropped (`//modSigns` lines); `ai/levels.ws`: `GMManageNGPLevels` sets `levelFakeAddon` to 0, as legacy's `ManageNGPLevels`; `mq1028_gerd`'s entity edit not ported (PD4) |
| Port status | ported (slice D6, 5.x-GM `523457b1`), verified in both trees (2026-10-30) |
| Open checks | the level in the threat list, and on the HUD for an entity whose addon the port clears (Gerd, the `q305` guard; seen only on a wolf). Gerd and the `q305` guard in their own quests (spawned from their entity files). The level on the HUD with an enemy locked on **verified** ([cleared run](#cleared-run-on-screen-2026-11-01), 2026-11-01: a level-1 wolf shows 1, the level the function returns) |
| Save impact | none; the addon of an NPC spawned or loaded with the mod is 0 (a saved field) |
| NG+ counterpart | none (NG+ levels are AI-01's real levels) |

**What it does** (changelist 1112–1113, "Removed ??? from deadly enemies, now they just show their level normally"; the addon's removal is an omission): every enemy shows the level its strength comes from. 1.32 and 5.x let an entity show its level plus a "fake" addon (`levelFakeAddon`, only for display and vanilla's upscaling), capped at the maximum level +5 (105); legacy zeroes the addon on every NPC at spawn and drops it and the cap from the level shown. The level's colour (and the skull the HUD shows with the red level) follows the real level: red from 6 levels above Geralt, grey from 6 below (UI-12, AI-01).

**Who shows a different level** (scan of every 5.x entity file, 2026-10-30: the 24,097 `.w2ent` files in the install's bundles, the last copy in load order, read with `unbundle.py` and `cr2w_dump.py`; 1.32's 23,666 scanned the same way). 81 files carry an addon (1.32: 79). 71 of them are AI-06's files, whose Ghost Mode copy already turned the addon into a real level as legacy did (the sergeant, Lugos, Olgierd's men, Blood and Wine's fistfighters and quest fighters, Dettlaff's columns, ...): their level shown is unchanged by D6. The other 10 now show their level without the addon:

| Entity (file) | Level | Addon | Shown in 5.x and before D6 | Shown now |
|---|---|---|---|---|
| Gerd (`mq1028_gerd`; in Ghost Mode's file set, PD4) | 1 | 1 | level + 1 | level |
| A `q305` thug guard (`q305_thug_guard2`; in Ghost Mode's file set, legacy kept 11) | 0 | 11 | level + 11 | level |
| Blood and Wine's mill workers of `q702` (six files: `q702_mill_worker_1h_blunt`, `_1h_plank`, `_1h_stick`, `_1h_torch`, `_2h_pitchfork`, `_2h_spear`) | 40 | 2 | 42 | 40 |
| The wraith of `mq1000` (`mq1000_enter_mage\wraith`, new in 5.x) | 100 | 50 | 105 (the cap) | 100 |
| Reinald of `mq1060` (`mq1060_witcher`, new in 5.x; AI's DA5) | 15 | 5 | 20 | 15 |

Levels are the files'; under scaling the real level moves (soft upscaling at Geralt 30: Gerd, the guard and Reinald 24) and 5.x added the addon on top. Two colours change in play: Reinald at Geralt 10 shows a green 15 where 5.x showed a red 20; the `q305` guard with scaling off at Geralt 10 shows a grey 1 where 5.x showed a green 12. An enemy above level 105 now shows its level (none in the files; NG+ levels, AI-01's, can pass it).

**Implementation (legacy):** `CNewNPC.ManageNGPLevels` ("modSigns: just in case", `levelFakeAddon = 0`), `GetExperienceDifferenceLevelName` ("fake levels removed"), `mq1028_gerd.w2ent` (1 → 0); `q305_thug_guard2.w2ent` keeps 11 (a re-save; cleared at runtime like every NPC's).

**5.x:** 1.32's, plus two new files with an addon (the `mq1000` wraith, Reinald). 5.x's upscaling also read the addon (`AddLevelBonuses`); the port's is legacy's (AI-01), which never did.

**Decisions:** legacy's; ended [UI-12](ui.md#ui-12-enemy-level-on-the-hud)'s temporary deviation (slice D6). PD4: Gerd's file is not edited; the runtime zeroing shows the same level. 5.x's two new files are zeroed like every NPC (legacy's rule): Reinald and the `mq1000` wraith show their real level (porter's call, confirmed by the owner, 2026-10-31).

**Verification (slice D6, 2026-10-30, both trees; 5.x-GM `523457b1`; `tests/gmTestsDiff05.ws`).** The level the HUD shows, read through the function the HUD's enemy focus module and the threat list call (`GetExperienceDifferenceLevelName`), each enemy made hostile for the read and set back to neutral, Geralt's level set by AI-06's test override; samples frozen and neutral 12 m behind Geralt. The scaling options set in memory and set back in the same call; the settings file restored from its backup afterwards (the regression's menu run writes the scaling group). Mode: the save's "Blood and Broken Bones!". No autosave was written.

| Check | How | Classic tree | New tree |
|---|---|---|---|
| The 5.x entities with an addon the mod's files do not clear (Gerd, the `q305` guard, a `q702` mill worker, the `mq1000` wraith, Reinald), the sergeant (AI-06's) and a bandit without an addon, with scaling off and under soft upscaling at Geralt 10 and 30: the addon 0 after spawn, the HUD's number the real level, its name and colour legacy's rule (Gerd and the guard 1 off, 4 and 24 soft, grey; the mill worker 40 and the wraith 100, red; Reinald 15 green at Geralt 10, grey at 30) | scripted (`gmtest_diff05_a`, `_read`) | 28 of 28 | 28 of 28 |
| An addon of 7 and the NG+ addon flag set by hand on a level-20 bandit, Geralt 10: shows 20 in red (5.x: 27); a bandit at the maximum level + 20: shows 120 (5.x: 105) | scripted (`gmtest_diff05_synth`) | 2 of 2 | 2 of 2 |
| NG+: a bandit spawned with the `NewGamePlus` fact and an NG+ level of 30 (both in memory, set back in the call): the NG+ level a real one (AI-01), no addon, the HUD shows 38 at Geralt 40 | scripted (`gmtest_diff05_ngplus`) | 2 of 2 | 2 of 2 |
| Gerd and the `q305` guard at their real level under soft upscaling at Geralt 10, and the synthetic addon and cap (in the regression); the sergeant's AI-06 check still 11 | scripted (`GMTest_diff05`, `GMTest_ai17_after`) | passed | passed |

On a throwaway build without the slice (D6's two script changes undone, the tests kept; deleted), the 20 reads of the five entities with an addon failed, showing 5.x's numbers (Gerd 2, the guard a green 12 at Geralt 10, the mill worker 42, the wraith 105, Reinald a red 20), and so did both synthetic checks and the regression's three DIFF-05 checks (regression 1,093 passed, 3 failed); the sergeant, the bandit and the NG+ check passed there (no addon on them; NG+ levels were already real since AI-01). Regression 1,096 passed, 0 failed in each tree, `gmtest_panel()` 133.

### DIFF-08 Experience by difficulty

| | |
|---|---|
| Kind | tuning |
| Pillars | P10 |
| 5.x class | clean |
| Flags | — |
| Depends on | XP |
| Skill trees | n/a |
| Port form | none in DIFF |
| Port status | handed off to XP ([XP-01](xp.md#xp-01-quest-experience-by-level), [XP-04](xp.md#xp-04-kill-experience); mapped 2026-10-31) |
| Save impact | — |
| NG+ counterpart | — |

**What it does** (changelist 1142, 1078): quest and kill experience no longer depend on the mode (1.32: kill experience ×1.2 on "Just the Story!", ×0.9 on "Blood and Broken Bones!", ×0.8 on "Death March!"; quest experience ×0.9 and ×0.8 on the two higher modes). Legacy's code is XP's rework of `CNewNPC.CalculateExperiencePoints` and `CR4Game.OnGiveReward`; 5.x's experience code is 1.32's. The ID is kept so the changelist line is accounted for; XP ports it (PD7).

## DIFF-C Additions (owner, 2026-10-31; new, not legacy)

Two options the owner asked for after the audit. Neither exists in legacy or 5.x; both sit in the Enemy scaling group and are left out of its presets. Ported together (5.x-GM `c0e2dcdb`, 2026-10-31), verified in both trees.

### DIFF-09 Ciri's sections: difficulty

| | |
|---|---|
| Kind | system |
| Pillars | P5, P10 |
| 5.x class | new |
| Flags | — |
| Depends on | DIFF-06 (the one place that decides her sections' mode), DIFF-04 (the menu group, the change hook, the modifiers), DIFF-01 and DIFF-02 (what the mode gives her enemies), AI-01 (her Death March adjustment), AI-15 (Ice Armor) |
| Skill trees | n/a (Ciri has no skill tree; Geralt's regression runs in both) |
| Port form | the option `Virtual_GMCiriDifficulty` (entries `GMCiriDifficulty` 0, 1, 2) last in `GMScalingOptions` (`menu/modGhostMode.xml`), not in the presets; its default "0" in `options/gmOptions.ws` (`GMOptionDefault`, `GMOptionList`); `difficulty/ciri.ws`: `GetSpawnDifficultyMode` (DIFF-06's `@replaceMethod`) returns `GMCiriSectionsMode()` while Ciri is the player, `@addMethod(CR4Game) GMCiriSectionsMode` (the lower of the chosen mode and the option's), `GMOnCiriDifficultyChanged` (run when the options menu closes, from `gmOptions.ws`' `SaveChangedSettings` wrapper with its own flag), `@addMethod(W3ReplacerCiri) timer GMCiriSectionsModeAfterLoad` (from her `OnSpawned` wrapper when restored); AI-01's Death March adjustment (`GMInternalAddLevelBonuses`) and AI-15's Ice Armor bonus (`GMIceArmorResistBonus`) read `GetSpawnDifficultyMode`; 4 labels × 9 languages (2110992667 to 2110992670) |
| Port status | ported (5.x-GM `c0e2dcdb`), verified in both trees (2026-10-31) |
| Open checks | none in the menu: the option seen in Options > Mods > Ghost Mode > Enemy scaling and changed there by hand **verified** ([cleared run](#cleared-run-on-screen-2026-11-01), 2026-11-01). Not run: a real fight in one of her sections with the option on; her real quests (not reachable from the test save) |
| Save impact | none: the option lives in the user settings; the mode it gives is applied to the NPCs at once, at a player change and after a load |
| NG+ counterpart | none (the NG+ difficulty abilities follow the mode as in the regular game) |

**What it does:** "Ciri's sections: difficulty" makes Ciri's sections easier than the chosen mode, for players who find them a chore. It only caps: while Ciri is the player, her sections are played on the lower of the chosen mode and the option's.

| Value | Chosen "Death March!" | Chosen "Blood and Broken Bones!" | Chosen "Story and Sword!" | Chosen "Just the Story!" |
|---|---|---|---|---|
| "Same as game" (the default; legacy's: no cap) | "Death March!" | "Blood and Broken Bones!" | "Story and Sword!" | "Just the Story!" |
| "Story and Sword!" | "Story and Sword!" | "Story and Sword!" | "Story and Sword!" | "Just the Story!" |
| "Just the Story!" | "Just the Story!" | "Just the Story!" | "Just the Story!" | "Just the Story!" |

Everything that depends on the mode in her sections follows it: her enemies' difficulty ability and per-enemy variants (DIFF-01, DIFF-02), the menu's modifiers through the owner's (1 + mode) × (1 + enemy + boss) (DIFF-04: "Death March!" with +50% health and damage gives her enemies ×3.75 / ×5.25; capped at "Story and Sword!" ×1.5 / ×1.5; at "Just the Story!" ×0.75 / ×1.125), her Death March adjustment (only on an effective "Death March!"; empty either way, PD5), DMG-10's fistfight rule, and the Wild Hunt's Ice Armor (no +30% resistances on an effective "Just the Story!", AI-15). When Geralt returns, everything is back on the chosen mode. Changing the option while Ciri plays applies when the options menu closes: every NPC gets the new mode at once and is re-levelled, as at a player change; changed as Geralt, it applies at her next section. Ciri's own stats do not depend on the mode: she holds no difficulty-tagged ability (read in game), and her quest abilities follow the journal (DIFF-06).

**How the mode reaches the NPCs:** at a player change, her spawn's update and `OnPlayerChanged`'s update both pass the spawn mode (DIFF-06's wrapper), and DIFF-06's re-level follows. **At a save load** in her sections (no `OnPlayerChanged`), the NPCs restored with the save kept the mode they were saved with (seen in game: her spawn's update does not reach them); half a second after her restored spawn, every NPC gets her sections' mode and its bonuses are recomputed at its level. The native update swaps the difficulty ability and variants but runs no level computation (seen: the modifiers' steps stayed sized for the saved mode), hence the recompute.

**Implementation (legacy):** none (new).

**5.x:** vanilla caps Ciri's sections at "Story and Sword!" (`GetSpawnDifficultyMode`, 1.32's); legacy removed the cap (DIFF-06), and this option brings a cap back as the player's choice.

**Decisions:**
- **Deviation:** a new option, "Ciri's sections: difficulty" ("Same as game", "Story and Sword!", "Just the Story!"), caps the mode while Ciri is the player and never raises it; "Same as game", the default, plays as legacy (owner, 2026-10-31: Ciri's sections are boring)
- **Deviation:** the option's place and values: last in the Enemy scaling group, three values (the two lower modes and "Same as game"), the default "Same as game", not in the group's presets (owner, 2026-10-31)
- **Deviation:** everything that reads the mode in her sections follows the capped one: AI-01's Death March adjustment and AI-15's Ice Armor read the spawn mode instead of the chosen one (the same unless the option caps it), so the mode her enemies hold and these rules cannot disagree (owner, 2026-10-31)
- **Deviation:** after a save load in her sections, every NPC gets her sections' mode and its bonuses recomputed half a second after her spawn, so a save made under another value of the option plays on the option's mode (owner, 2026-10-31)
- Labels: the two mode values use the game's own names of the modes in each language (strings 1092307 and 1092305, copied); "Ciri's sections: difficulty" and "Same as game" are the porter's translations in de, fr, es, it, pl, ru, cz and br, not checked by a native speaker (no play effect).

**Verification (2026-10-31, both trees; 5.x-GM `c0e2dcdb`; `tests/gmTestsDiff09.ws`).** On the test-only slot (Geralt at level 20), "Death March!" set through the game's path, health and damage +50%, a friendly frozen bandit and drowner spawned as Geralt, a ghoul spawned as Ciri; vanilla's `Ciri()` and `Geralt()`. Expected modes are written in the test from the option's value, not read through the code under test. All scripted (exec calls, no real input, no screen). Options and mode set back after each run.

| Check | How | Classic tree | New tree |
|---|---|---|---|
| As Geralt with the option at "Story and Sword!" and at "Just the Story!": the spawn mode "Death March!", both samples on "Death March!" ×3.75 / ×5.25, no adjustment | scripted (`gmtest_diff09_a(1)`, `(2)`) | 3 of 3 each | 3 of 3 each |
| As Ciri, the option at "Story and Sword!": the spawn mode "Story and Sword!", every sample (the ghoul spawned as Ciri too) holds `difficulty_CommonMedium` alone, ×1.5 / ×1.5 with one set of steps and its maximum health, re-levelled, no adjustment; Ice Armor's +0.3; `GetWitcherPlayer()` NULL | scripted swaps (`gmtest_diff09_b`, `_check`) | 5 of 5, 5 of 5 | 5 of 5, 5 of 5 |
| As Ciri, the option at "Just the Story!" at the swap: `difficulty_CommonEasy`, ×0.75 / ×1.125, Ice Armor's bonus 0 | scripted swaps | 5 of 5, 5 of 5 | 5 of 5, 5 of 5 |
| A change while Ciri plays, through the menu's code path (the pause menu open, `OnOptionValueChanged` called as its Flash does, the menu closed): "Story and Sword!" → "Just the Story!" (every NPC on "Just the Story!" at once, ×0.75 / ×1.125) → "Same as game" (legacy's: "Death March!", ×3.75 / ×5.25, her adjustment held) | scripted (`gmtest_diff09_menu`, `_check`) | 5 of 5 each | 5 of 5 each |
| Back as Geralt: every sample on "Death March!", ×3.75 / ×5.25, no adjustment | scripted (`gmtest_diff09_end`) | 5 of 5 (two runs) | 5 of 5 (two runs) |
| A load into a Ciri section: as Ciri on "Death March!" with "Same as game", a persistent bandit (on "Death March!"), saved over the test-only slot; the option set to "Just the Story!" and the slot loaded: Ciri the player, the spawn mode "Just the Story!", the restored bandit on `difficulty_CommonEasy` with ×0.75 / ×1.125, re-levelled; after `Geralt()` on "Death March!" | scripted (`gmtest_diff09_ls_*`, `gmtest_diff04_lsave_save`, `game.py load`) | 2, 3 and 2 passed | — (no tree involved) |
| In the regression: the cap for each value on the current mode, none for Geralt | scripted (`GMTest_diff09`) | passed | passed |

On a throwaway build without the option's behaviour (the cap in `GetSpawnDifficultyMode`, the change hook and the load timer removed, AI-01's and AI-15's lines as in 5.x-GM `38e2b55e`; the menu, labels and tests kept; deleted), these failed: the spawn mode as Ciri ("Death March!" for both values), every sample as Ciri (on "Death March!" ×3.75, with the adjustment), the change through the menu (nothing changed), Ice Armor on "Just the Story!" (0.3); Geralt's checks passed there. The regression's `GMTest_diff09` reads `GMCiriSectionsMode` directly, kept on the throwaway so the tests compile. The load check failed on two earlier builds of this work: with the cap but no load timer the restored bandit stayed on "Death March!"; with a timer that only updated the mode it held `difficulty_CommonEasy` with "Death March!"'s steps (×1.75 / ×2.5); both fixed before the commit.

### DIFF-10 Interpolated enemy scaling

| | |
|---|---|
| Kind | system |
| Pillars | P5, P10 |
| 5.x class | new |
| Flags | — |
| Depends on | DIFF-04 (the scaling types, the change hook), AI-01 (the level model) |
| Skill trees | n/a |
| Port form | a seventh entry, value 6, in `Virtual_GMScaling`'s options (`menu/modGhostMode.xml`; legacy's 0 to 5 keep their meaning), not in the presets; `case 6` in `GMApplyLevelScaling` (`difficulty/scaling.ws`); its label `preset_value_gm_es_interpolated` × 9 languages (2110992666) |
| Port status | ported (5.x-GM `c0e2dcdb`), verified in both trees (2026-10-31); the fix to recomputes (whole-port audit A2-1, `gm/fx-diff`) verified on the area build in both trees (2026-11-03) |
| Open checks | none: the choice seen in the menu and picked by hand **verified** ([cleared run](#cleared-run-on-screen-2026-11-01), 2026-11-01) |
| Save impact | none (the type lives in the user settings; levels are recomputed as for the other types) |
| NG+ counterpart | none |

**What it does:** "Interpolated" raises an enemy below Geralt's level half the way to his level, rounded down: it gains floor((Geralt's level − its level) / 2) levels. Geralt 20 and an enemy at 4 (16 below): +8, level 12; Geralt 19, the same enemy (15 below): +7, level 11; a level-1 enemy at Geralt 20: +9, level 10; a wolf at 15 with Geralt at 20: +2, level 17. Enemies at or above his level keep their own. Everything else is as for the other types: guards stand at Geralt's level + 16 (at his level with "No additional levels for guards"), "Do not upscale animals" keeps animals at their level and lowers those above half Geralt's to half of it (DD4), NPCs with `NPCDoNotGainBoost` and the Blood and Wine banshee's summons keep their level, an enemy left at level 1 gets no level bonuses, and Ciri's sections are not scaled. Choosing it re-levels the NPCs near Geralt at once, as any scaling option. Like every type it is applied again at an enemy's next level computation after Geralt's level changes (a fight's start, or targeting it out of combat; legacy's re-level) and when the boss bar comes or goes, each time from the enemy's own level (its entity's, or the level a script set): an enemy of level 4 is 12 at Geralt's 20, 12 at 21 and 13 at 22, and a boss bar at 20 keeps it at 12.

**Implementation (legacy):** none (new).

**5.x:** none.

**Decisions:**
- **Deviation:** a seventh scaling type, "Interpolated": an enemy below Geralt's level gains half the difference, rounded down (owner, 2026-10-31, with the two examples)
- **Deviation:** an enemy at or above Geralt's level keeps its own level under "Interpolated" (owner, 2026-10-31; not chosen: interpolating down as well, an enemy above him losing half the difference)
- **Deviation:** "Interpolated" is the last choice (value 6, so a saved setting of 0 to 5 keeps its meaning) and in none of the presets (owner, 2026-10-31)
- **Fix** (whole-port audit A2-1, 2026-11-03; the port's own option, not a difference from legacy): a recompute without a reset (Geralt's level-up, the boss bar) took half the remaining gap again from the level already raised, so enemies closed in on Geralt much faster than the rule (an enemy of level 4: 12 at Geralt's 20, then 16 when a boss bar came, and 16, 19, 21 at his 21, 22, 23). `GMApplyLevelScaling` now interpolates from the NPC's own level: the entity's level plus New Game+'s, or the level `SetLevel` gave it (`gmScriptLevel`, `ai/levels.ws`, cleared by a full reset as the script's level is). The owner first asked for levels fixed at the spawn, then kept legacy's re-level at Geralt's level-ups (2026-11-03), which the fix makes safe for this type.
- Label: "Interpolated" translated by the porter in de ("Interpoliert"), fr ("Interpolé"), es and br ("Interpolado"), it ("Interpolato"), pl ("Interpolowane"), ru ("Интерполяция"), cz ("Interpolované"); not checked by a native speaker.

**Verification (2026-10-31, both trees; 5.x-GM `c0e2dcdb`; `tests/gmTestsDiff10.ws`, `tests/gmTestsDiff04.ws`).** Seven frozen friendly samples (bandits of level 4, 25 and 1, a drowner of 4, wolves of 4 and 15, a guard), Geralt's level held by AI-06's test override; the expected levels are the owner's figures written in the test, each also matched against the rule computed in the test. All scripted.

| Check | How | Classic tree | New tree |
|---|---|---|---|
| At Geralt 20 and 19: the bandit, drowner and wolf at 4 → 12 and 11, the wolf at 15 → 17, the level-1 bandit → 10, the guard 36 and 35, the bandit at 25 keeps 25; the displayed-level abilities agree | scripted (`gmtest_diff10_levels`) | 2 of 2 | 2 of 2 |
| "Do not upscale animals": the wolf at 4 stays 4, the wolf at 15 → 10 and 9; "No additional levels for guards": the guard 20 and 19 | scripted | 4 of 4 | 4 of 4 |
| `NPCDoNotGainBoost` and `banshee_summons` on the level-4 bandit at Geralt 20: it keeps 4 | scripted | 2 of 2 | 2 of 2 |
| Chosen through the menu's code path (the pause menu open, `OnOptionValueChanged`, the menu closed) at Geralt 20: every NPC within 100 m at once at Interpolated's level (bandits 2 → 11, the world's ghouls 2 → 11, hares and horses 1 → 10, Vesemir kept) | scripted (`gmtest_diff04_change_*`) | 30 of 30 NPCs | 29 of 29 NPCs |
| The value after quitting and relaunching the game: `Virtual_GMScaling` reads "6", the getter Interpolated | scripted (`gmtest_diff10_persist`) | passed | passed |
| In the regression: a level-2 bandit and a guard at Geralt 20 (11 and 36) | scripted (`GMTest_diff04`) | passed | passed |

On a throwaway build without the type (no `case 6`, no menu entry; the tests kept; deleted), these failed: all six level cases (the samples at soft upscaling's 14 and 13), the menu choice (the type read back as soft upscaling) and the relaunch check ("3"); the two stop abilities passed there (they keep the level either way).

**The fix to recomputes (2026-11-03, both trees, verified on the area build `gm/fx-diff`; `GMTestDiff04Relevel` in the regression's `GMTest_diff04`).** Scripted, Geralt's level held by AI-06's test override, on the regression's bandit, for every scaling type (None at level 26, Upscale, Match, Soft and both random types at 0..0 from level 2, Interpolated from level 4): computed at Geralt 20; the boss bar's recompute at 20 (`GMRecomputeLevelBonuses` with the tag, then without) keeps the level; a fight's start (`RecalcLevel`, no reset) after level-ups to 21 and 22 gives the rule's level for each (Interpolated 12, 12, 13); an option change (`GMResetLevel`) at 22 gives it too: 7 of 7 in each tree. On a throwaway build with the old level code (deleted) Interpolated failed (16 and 18 at the bar, 19 at 21, 20 at 22) and the other six passed, as expected (legacy's re-level was already there). Regression `gmtest_regress()` 1,592 passed, `gmtest_panel()` 166, 0 failed in each tree (+8: these seven and DMG-01's armor-flag check).

**Regression with DIFF-09 and DIFF-10** (5.x-GM `c0e2dcdb`, `god()` off): `gmtest_regress()` 1,100 passed, 0 failed in each tree; `gmtest_panel()` 139 in each tree at `exec --wait 6000`. At `--wait 4500`, AI-10's counter-window check failed in three of four launches ("1 of 2" samples) and AI-18's stone check in two (classic tree: 138 + 1, 137 + 1, 136 + 2; new tree: 137 + 1); both passed at 6000 on a fresh launch in each tree.

**Saves:** the test-only slot was saved over twice: as Ciri for the load check, then as Geralt (level 20, no samples) to put it back; it is now `<save name>` (the name's key changed from `7ea4f400` to `7ea4f800`). No autosave was written; the test save `<save name>` is unchanged; the user settings were restored with the game closed (no scaling group; the classic tree, sign cooldown 5, armour regen penalty off, combat stamina regen 5, difficulty 3).

### Cleared run on screen (2026-11-01)

The first checks with the game in front and real input (5.x-GM `92548132`; the test save, Geralt level 1; nothing saved). Options > Mods > Ghost Mode > Enemy scaling reached with the real mouse from the pause menu.

| Check | Seen | Result |
|---|---|---|
| The group (DIFF-04, DIFF-09) | the "Scaling Presets" row with "Recommended", "Hardcore" and "Off", then 13 rows: "Enemy scaling" (Soft upscaling), "Random scaling: lower bound (relative to player level)" 0, "Random scaling: upper bound (relative to player level)" 0, "Use progressive level bonuses" Off, "Level delta" 0, "Abilities per level delta" 0, "No additional levels for guards" Off, "Do not upscale animals" Off, "Enemy health modifier" 0, "Enemy damage modifier" 0, "Additional health modifier for bosses" 0, "Additional damage modifier for bosses" 0, "Ciri's sections: difficulty" Same as game | **verified** (DD1's defaults, the "Recommended" preset) |
| "Hardcore" clicked | Upscale, progressive bonuses On, level delta 10, abilities per level delta 5, the four modifiers 0.50 | **verified** |
| "Enemy scaling" changed with the arrow key | Upscale → Match → Soft upscaling → Random → Random no downscaling → Interpolated | **verified** |
| "Recommended" clicked to set it back | Soft upscaling, the rest Off or 0 | **verified** |
| "Ciri's sections: difficulty" changed with the arrow key and set back (DIFF-09) | Same as game → Story and Sword! → Just the Story!, back to Same as game | **verified** |
| An enemy's level on the HUD, locked on (DIFF-05, UI-12) | a level-1 wolf, hard-locked (`autolock()`): "1" in the diamond beside its health bar, the level the function returns | **verified** |

### DIFF audit (2026-10-30)

Done by a fresh session ([audit](../feature-mapping.md#audit-signing-a-feature-off)) on 5.x-GM `523457b1` and master `c7b0237b`, reading code and data, with game runs in both trees on 2026-10-30. The seven slices' commits (5.x-GM `5d06b030`, `53427f7b`, `73734341`, `232d10f8`, `f929bfc3`, `ad314f9f`, `523457b1`) were read whole. Every method they replace, wrap or add was read against legacy (`legacy-GM`), 1.32 (`master`) and 5.x (`vanilla-5.x`), with every 5.x caller of the level code (`OnSpawned`, `OnGameDifficultyChanged`, `OnLevelUpscalingChanged`, `SetLevel`, `RecalcLevel` from the combat start and the enemy focus, the ability manager's init, the quest fistfight block, `UpdateStatsForDifficultyLevel` and its three callers, the boss-bar HUD module and the quest tag function).

**Data** was checked by scripts written for this audit, independently of `gen_diff.py`, `gen_ngplus.py` and `gen_ai_ent.py`:
1. **Abilities.** The 61 ability XML files of the installed 5.x game were taken from its bundles (`unbundle.py`); every Ghost Mode DLC entry (all 20 `gm_*.xml` files, both folders) was applied to them (`replace` whole, `extend` by node, no `on_conflict` flagged), and each of attribution.csv's DIFF ability units (68 regular, 67 NG+) was compared node by node and tag by tag with legacy's definition.
2. **Legacy's other changes.** Every ability legacy changed against 1.32 whose name or tags mark it as a difficulty variant, a difficulty ability, Ciri's or a `ModSigns*` step, to find any legacy change attributed nowhere.
3. **The entities.** All 24,097 entity files of the installed game (the last copy in load order) were searched for `levelFakeAddon` and dumped with `cr2w_dump.py`; every entity file in Ghost Mode's file set was dumped in `master`, `legacy-GM`, `vanilla-5.x` and `5.x-GM`. The same search counted the entity files that carry the boss-bar tag `HideHealthBarModule` themselves.
4. **The menu.** The scaling group of `menu/modGhostMode.xml` against legacy's `modSignsConfig.xml`, line by line.

**Checked and holding:**

**Data**
- **Abilities.** All 68 regular and 67 NG+ DIFF units read legacy's definition: the four difficulty abilities, the 50 variants, `PrologModifier`, Ciri's eight, the five `ModSigns*`. `mon_olgierdeasy_ep1` in NG+ (not a unit) is empty in legacy, 1.32, 5.x and the port. None of these abilities was changed by 5.x against 1.32, so no whole replacement drops a 5.x change.
- **How they are given.** No DIFF ability has a second Ghost Mode entry (`difficulty_CommonHardcore` lives only in `gm_diff.xml`, PD2); no DIFF ability is given by `extend`; no entry without `on_conflict` redefines a 5.x name. The 13 regular entries 5.x does not define are the five `ModSigns*` and eight variants 5.x defines only in its NG+ files (F5).
- **Nothing unattributed.** The only legacy-changed difficulty-tagged abilities outside DIFF are AI-03's two (`mon_EP2_bossekhardnerf`, `q701_giant_peasant`) and AI-19's two NG+ Caretaker variants, as recorded.
- **Fake levels.** 81 installed entity files carry a nonzero addon (D6's count): 71 are AI-06's files, which the mod ships with legacy's level and addon 0; Gerd's file keeps 5.x's addon 1 (PD4) and the `q305` guard keeps 11 (legacy kept it too); 8 are not in the file set (the six `q702` mill workers, the `mq1000` wraith, Reinald), zeroed at spawn like every NPC. Every legacy level or addon edit is carried except Gerd's (PD4).
- **The menu group** equals legacy's: the twelve options, their ranges, the three presets' 36 entries.
- **In game** (definitions read, `gmtest_ability_probe`): `barghest_hardcore` exists in a regular game, empty with its `Hardcore` tag; `ModSignsMaxHealthNegative` −0.99. STAM-08's `BloodBuff`, given by `extend` though Blood and Wine defines it, reads both its values (Essence regen 50, stamina regen 20) and its tag: the rule that `extend` empties an expansion's ability ([development.md](../development.md#fine-grained-xml-overrides-50)) did not hold for it (not DIFF's; noted for the dev docs).

**Code**
- **The level code** (`AddLevelBonuses`, `GMApplyLevelScaling`, `GMInternalAddLevelBonuses`, `GMLevelBonusCount`, `GMAddOptionBonuses`, `GMRemoveAllLevelBonuses`) equals legacy's branches, count and steps; the modifiers are removed before they are added on every path, and nothing else adds them. The guards' 16 levels, the animal rule (DD4), the banshee summons and `NPCDoNotGainBoost` (modifiers yes, levels no) are legacy's.
- **Options.** The getters read legacy's ids; unset options fall back to DD1's defaults, "-1" only for the virtual scaling type; the five PD6 names are in the change list; presets re-level through `OnPresetApplied`; the change hook runs from `SaveChangedSettings`, as legacy's.
- **The saved random level.** Kept only for an NPC restored from a save, until its first level computation; cleared by an option change, a mode change and `SetLevel`; rolled again outside the bounds; never 0 once rolled.
- **DMG-05's step** reads `damage_final_multiplier` for hostile NPCs hitting the player, as legacy; the fistfight branch uses legacy's formula without the modifiers, as legacy.
- **Ciri.** `GetSpawnDifficultyMode` and `GMCheckCiriAbilities` (its three journal strings) equal legacy's, called after 5.x's `OnSpawned` and `OnCombatStart` bodies as in legacy; the three 5.x callers of `UpdateStatsForDifficultyLevel` pass the spawn mode already, so the wrapper changes only her spawn's call (F1).
- **`TakeMoneyFromPlayer`** equals legacy's; its only caller is the state's `killedByGuard` branch.
- **The displayed level** equals legacy's `GetExperienceDifferenceLevelName`; `GMManageNGPLevels` zeroes the addon and the NG+ flag for restored NPCs too.

**Tool checks:** `check_modsigns.py` 492 bodies, 0 unmarked; `deviations.py --check` current; `gen_diff.py --check` and `gen_ngplus.py --check` pass.

**In game** (scripted through exec on a throwaway build with this audit's probes, `tests/gmTestsDiffAudit.ws`, deleted afterwards; the samples a friendly frozen bandit, drowner and wolf and mh102's arachas with the boss bar from its spawn; Geralt at level 20 by `setlevel`; the "Hardcore" preset's values in memory: Upscale, progressive 10 and 5, +50% health and damage, +50% more for bosses; the expected values legacy's rules computed in the probe, as D5b's tests do):

| Check | How | Classic tree | New tree |
|---|---|---|---|
| A mode change with the modifiers active: after each change exactly one set of step abilities (+5 / +5, the boss +10 / +10), the per-level count (24, the boss 44), the mode's difficulty ability alone, the multipliers (Death March ×3 / ×4, the boss ×3.5 / ×4.5) and the maximum health | scripted mode changes through the game's path (`SetDifficultyLevel`, `OnDifficultyChanged`): "Blood and Broken Bones!" → "Death March!" → "Just the Story!" and back in one call → "Story and Sword!" → back | 20 of 20 | 12 of 12 (two changes) |
| A save and a load with the modifiers and progressive bonuses: a persistent bandit and arachas saved into the test-only slot and loaded; as loaded, the abilities are restored once (+5 / +5 and +10 / +10, 24 and 44 per-level, the displayed level 20 and 33; the `currentLevel` field reads the entity's level until the fight starts, as legacy); at the fight's start (`RecalcLevel`) one set again | scripted (`SaveGame` over the slot, `game.py load`) | 2 of 2 | — (no tree involved) |
| The modifiers, then "Death March!", then `Ciri()` and `Geralt()`: the NPCs present keep Geralt's scaling while Ciri plays (F1); after her fight's start they carry her Death March adjustment, still there after `Geralt()` until his fight's start, which puts every sample back to his values | scripted swaps and recomputes | F1 seen; 4 of 4 after Geralt's fight start | the same |
| Random −3..3 across a mode change: every sample rolled again (4 of 4 changed), in the bounds, one set of steps | scripted | 8 of 8 | — |
| A bandit given the boss bar after its spawn, as a quest does (`RunEvent_BossFocusModule_ShowBossIndicator`, `ShowBossFightIndicator`'s body): the HUD tags it; at the fight's start it keeps the plain modifiers (F2) | scripted | F2 seen | F2 seen |
| "Just the Story!" with the health modifier at −50%: the samples' maximum health 0 (alive); with the damage modifier at −100%: damage ×0 on "Story and Sword!", ×−0.25 on "Just the Story!" (F3) | scripted (`autoconfigset`, `gmtest_diff04b_a`, `gmtest_diff01_modes`, `gmtest_dummy_info`) | F3 seen | — (no tree involved) |

**Regression** (the 5.x-GM `523457b1` build, `god()` off, `exec --wait 4500`): `gmtest_regress()` 1,096 passed, 0 failed in each tree; `gmtest_panel()` 133 passed in the new tree and in the classic tree's fourth launch. The panel's AI-18 stone check (no knockdown on its bandit) failed in the classic tree's first three launches (132 passed, 1 failed each), more often than the "once" seen before; it is AI's check, and nothing in DIFF touches it.

**Findings:**

1. **Ciri's takeover re-levels nobody** (low; owner decision).
   - The port's wrapper of `UpdateStatsForDifficultyLevel` (DIFF-06's deviation) makes Ciri's spawn update every NPC for the chosen mode. On every mode the NPCs already hold that mode, so the engine changes nothing and runs no level computation.
   - Legacy kept vanilla's capped call: on "Blood and Broken Bones!" and "Death March!" it changed every NPC's mode, which recomputes its level with Ciri as the player (Geralt's scaling dropped, its own level back, her adjustment added); `OnPlayerChanged` then put the mode back.
   - Play effect: enemies already near when a Ciri section starts keep the level Geralt's scaling gave them (Upscale at Geralt 20: a level-8 bandit fights Ciri at 20, with 24 per-level bonuses); her fight's start recomputes them without the reset, so they stay there. Enemies spawned during her section are not affected. Rare in play: her sections usually start with a scene and enemies spawned for her. The swap back to Geralt re-levels nobody either, in legacy too; his next fight's start corrects them.
   - The deviation's text says that keeping legacy's call "would change nothing on a player change but the lost entity variant": it would also re-level the NPCs present, on the two higher modes.
   - Options: (a) re-level every NPC at a player change (`GMResetLevel` from `OnPlayerChanged`), so enemies near Ciri drop Geralt's scaling on every mode, and Geralt's come back at once; (b) keep the port as it is and correct the deviation's text. Recommendation: (a): it gives legacy's result on the two higher modes, also on the two lower ones, and keeps the uncapped update; the deviation's text is corrected either way.
   - Tested: scripted swaps in both trees (above); legacy's side by reading, with the engine's mode-change behaviour seen in slice D3.
2. **The boss modifiers miss bosses whose bar appears in the fight** (medium; owner decision).
   - Legacy's boss rule is the tag `HideHealthBarModule`, read only when the level is computed. Contract monsters get it at their spawn (45 `W3MonsterHuntNPC` entity files) and 11 entity files carry it; story bosses get it from the boss-bar HUD when the quest shows the bar (`ShowBossFightIndicator`), at the fight, after the level was computed. The fight's start (`RecalcLevel`) recomputes nothing at the same Geralt level, and the bar's end removes the tag.
   - Play effect: under the "Hardcore" preset, contract monsters get +50% more health and damage, but story bosses with a quest boss bar get none, unless Geralt levels up or an option or the mode changes while the bar is up. The same holds for AI-01's rule that bosses get no "High" or "Deadly" ability. Legacy's code is the same, so this is how legacy played, as far as the code shows.
   - DIFF-04's open check says such a boss "gets the boss modifiers at its next level computation": that computation is not its fight's start (F5).
   - Options: (a) keep legacy's timing and record what the boss modifiers reach; (b) re-level an NPC when the boss bar tags or untags it (the HUD module's `OnShow` and `OnHide`, the quest tag function), so every boss with a bar gets them during its fight (a deviation). Recommendation: (a), legacy behaviour first; the legacy test list asks how it played. (b) if the owner wants the menu's label honoured for story bosses.
   - Tested: scripted in both trees (above); the entity counts by the data scan.
3. **The modifiers can take an enemy's health or damage to zero or below** (low; owner decision).
   - The modifiers add to the mode's multiplier, as legacy: on "Just the Story!" (×0.5) a health modifier of −50% gives ×0, lower values a negative factor; the −99% step meant for −100% does not prevent it there. The damage modifier at −100% gives ×0 on "Story and Sword!" and ×−0.25 on "Just the Story!" (a negative factor on every hit of a hostile NPC on Geralt).
   - Play effect: only with the player's own extreme settings on the two lower modes. Enemies with 0 maximum health were alive in the test; what a hit then does was not tried.
   - Options: (a) floor the sums (health at least ×0.01, as the −99% step intends on "Story and Sword!"; damage at least ×0), a deviation; (b) keep legacy's sums. Recommendation: (a): no setting should make enemies without health or hits that heal.
   - Tested: scripted, classic tree (a setting, no tree involved).
4. **Gaps in the tests** (low, test-only; clear fix).
   - D5a's "an option change and a mode change after a load roll the random level again" calls `OnGameDifficultyChanged` and `GMResetLevel` directly and reads only the keep flag; it would pass with the flag never consulted. Nothing reads a level rolled again after a real mode change.
   - No check covers a mode change with the modifiers active, the modifiers and progressive bonuses across a save and a load, the levels of NPCs present across a Ciri swap (where F1 hid), or a boss bar given after the spawn (F2). This audit ran them once.
   - Fix: add exec checks for the four (the probes above are the model: a mode change through the game's path with one set of steps per mode; a save into the test-only slot and a load; the swap after F1's decision; the late boss bar after F2's decision); have the random check read a level rolled again after a real mode change; show each failing on a throwaway build.
5. **Doc corrections** (doc-only; clear fix).
   - DIFF-02's port form says "the nine 5.x defines only in its NG+ files": eight (`barghest_hardcore`, `dettlaff_construct_normal`, `_hard`, `_hardcore`, `q701_bruxa_hardcore`, `q703_arena_knights_hardcore`, `mon_olgierdeasy_ep1`, `mon_olgierdmedium_ep1`).
   - DIFF-04's open check on a late boss (F2): the next re-level is Geralt's level-up or an option or mode change, not the fight's start, and the boss bar's end removes the tag.
   - DIFF-06's deviation and its "Her spawn's update" paragraph (F1).
   - development.md's rule that `extend` empties an expansion's ability: `BloodBuff` (Blood and Wine's, STAM-08's `extend`) keeps its values in game; the rule's scope needs stating (which expansion abilities it hits).
   - The AI-18 stone check's intermittent failure rate (3 of 4 classic launches today) belongs in development.md's regression notes.
6. **Not verified in game** (no action; open checks kept in the entries).
   - Seen on screen in the [cleared run](#cleared-run-on-screen-2026-11-01) (2026-11-01): the Enemy scaling group, a change and a preset by hand, an enemy's level on the HUD.
   - A scaling option changed from the main menu before a load (the change hook would run with no player; legacy's does the same).
   - A real fight's start (the checks call `RecalcLevel`, what `OnCombatModeSet` calls); a real story boss with a quest boss bar; Ciri's quest abilities in their quests; NG+.

**Autosave:** none written. The test-only slot `<save name>` was saved over once (the save check above) and is now `<save name>` (Geralt at level 20, a persistent friendly bandit and arachas frozen in front of him); the test save `<save name>` is unchanged. The user settings were restored with the game closed (no scaling group).

**Not reviewed:** legacy's own behaviour in play; NG+ in game.

**Suggested fix slices:**
- **C** (code and tests): F1 and F2 once decided, F3 once decided, F4.
- **W** (docs): F5.

#### DIFF audit close-out

Partly closed 2026-10-30: F4 fixed and F5's three independent corrections made (5.x-GM `fa4b96ff`). **Closed 2026-10-31**: the owner decided F1 (a), F2 (b) and F3 (floors, and a new rule for how the modifiers combine), made and verified in both trees (5.x-GM `38e2b55e`), with F4's two checks and F5's corrections that hung on them.

| Finding | Outcome | How tested |
|---|---|---|
| F1 Ciri's takeover re-levels nobody | **fixed** (owner: option (a), 2026-10-31): a player change re-levels every NPC near the new player, both ways (a deviation, [DIFF-06](#diff-06-ciri)); DIFF-06's deviation text and its "Her spawn's update" paragraph corrected | scripted swaps in both trees (below) |
| F2 Late boss bars | **fixed** (owner: option (b), 2026-10-31): the boss bar's `OnShow` and `OnHide` and the quest tag function recompute the NPC's bonuses (a deviation, [DIFF-04](#diff-04-enemy-scaling-options)); DIFF-04's late-boss wording and open check corrected | scripted, both trees (below) |
| F3 Zero or negative multipliers | **fixed** (owner, 2026-10-31): (1 + mode) × (1 + enemy + boss), health at least ×0.01, damage at least ×0 (a deviation, [DIFF-04](#diff-04-enemy-scaling-options)) | scripted, both trees (below) |
| F4 Test gaps | **fixed**: the three that hung on no decision (2026-10-30), the Ciri swap and the late boss bar (2026-10-31) | below |
| F5 Doc corrections | **corrected**: DIFF-02's port form says eight NG+-only variants; [development.md](../development.md#fine-grained-xml-overrides-50) states what is known (`extend` empties Hearts of Stone's abilities; Blood and Wine's, `BloodBuff` included, keep theirs; no other DLC tried); the AI-18 stone check's failure rate is in development.md's regression notes; DIFF-04's late-boss wording and DIFF-06's deviation (2026-10-31) | read |

**F4's checks** (5.x-GM `fa4b96ff`, `tests/gmTestsDiff04.ws`, `tests/gmTestsDiff04b.ws`):
- **In the panel** (`GMTest_diff04_after`, last in `gmtest_panel()`, on a friendly frozen bandit `GMTest_diff04_spawn()` leaves in the regression; last because a mode change rebuilds every NPC's stats): under the "Hardcore" values at Geralt 20 (the test override), three mode changes through the game's path (to "Death March!"; "Just the Story!" then "Story and Sword!" with no re-level between; back to the save's mode), each followed by the re-level its timer runs (`RecalcLevel`): exactly one set of step abilities (+5 / +5), the mode's multipliers plus 0.5, the mode's difficulty ability alone, level 20 with 24 per-level bonuses. The random level of an NPC as restored from a save (the keep flag set, a saved level 18, Random no downscaling −2..2, base 24): its first computation keeps 18; after a real mode change, and after the change hook (`GMOnScalingOptionsChanged`), its level reads 24 (a roll of 18 to 22 raised to its own 24), so the level read shows the roll, not the flag. Options and mode set back (a sixth check).
- **A save and a load** (`gmtest_diff04_lsave_a`, `_b`, `_save(key)`, `_c`, `_d`; [game-automation.md](../game-automation.md#test-saves)): a persistent bandit and mh102's arachas under the "Hardcore" values at Geralt 20, saved over the test-only slot (the one manual save whose name holds the key; none or several: nothing saved) and loaded: restored from the save, then one set of steps and the recorded per-level count as loaded, at the fight's start (`RecalcLevel`, the level the one before the save: 20 and 33) and at a full recompute (+5 / +5 and 24; the arachas +10 / +10 and 44): 2 of 2 before the save, 10 of 10 after the load.
- **On a throwaway build** without the code they guard (the keep-flag clears in `GMResetLevel` and the `OnGameDifficultyChanged` wrapper, and the step abilities' removal in `GMRemoveAllLevelBonuses`; deleted, the real build reinstalled), each failed: the three mode changes (+10, +15, +20 steps), both random checks (level 18 kept), and the save check at the fight's start and at the full recompute for both samples (+10 / +15 steps; the boss +20); as loaded they passed (one set comes back from the save). The regression's existing boss-tag check failed there too (+15 steps).

**Regression** (5.x-GM `fa4b96ff`, `god()` off, `exec --wait 4500`): `gmtest_regress()` 1,097 passed, 0 failed in each tree (the new spawn check one more); `gmtest_panel()` 139 passed (133 and the six new) in the new tree and in the classic tree's second launch; in the classic tree's first launch 138 passed and the AI-18 stone check failed (the known intermittent; also on the throwaway build's launch).

**Saves:** the test-only slot was saved over twice (the real build's run, then the throwaway's) and is now `<save name>` (Geralt at level 20, the two persistent samples of the last run in front of him; `gmtest_diff04_lsave_a()` removes them). **One autosave** was written, `<save name>` (2026-10-30 04:40), right after `setlevel(20)` on the test save during the first save run; the later runs load the slot (already at level 20) instead. The test save `<save name>` is unchanged; the user settings were restored with the game closed (no scaling group).

**Deviations:** none new (2026-10-30).

**The owner's decisions on F1 to F3** (2026-10-31, 5.x-GM `38e2b55e`, `tests/gmTestsDiff04c.ws`; D5b's `tests/gmTestsDiff04b.ws` and the regression's DIFF-04 checks moved to the new rule). All scripted through exec calls (no real input, no screen); expected values are the owner's figures written in the tests, or the rule computed in the test. The mode and the options were set back after each run.

| Check | How | Classic tree | New tree |
|---|---|---|---|
| F3 on four samples (a bandit, a drowner, a wolf, mh102's arachas with the boss bar): each case's mode set through the game's path, the mode change asks for a re-level, which gives the owner's figures and the maximum health, every sample alive with health above 0: "Death March!" with the "Hardcore" values ×3.75 / ×5.25, the boss ×5 / ×7; "Story and Sword!" +50% health ×1.5; "Just the Story!" −50% health ×0.25; the boss modifiers alone (−50% / −100%) on "Just the Story!" the boss ×0.25 / ×0; health and damage −100% on "Blood and Broken Bones!" and "Just the Story!" ×0.01 / ×0; −50% on "Death March!" ×1.25 / ×1.75; +500% on "Blood and Broken Bones!" ×12; none ×0.5 / ×0.75 | scripted mode changes (`gmtest_diff04c_f3`) | 10 of 10 | 10 of 10 |
| D5b's modifier settings on the four samples under the new rule: multipliers, the step sum (one set: the multiplier's change from the mode's) and maximum health | scripted (`gmtest_diff04b_mods`) | 11 of 11 | 11 of 11 |
| Scripted hits of each sample on Geralt: the final-damage step ×2, ×3 (the boss ×4) with the "Hardcore" values, ×1 at −50%, ×0 at −100% | scripted (`gmtest_diff04b_hits`) | 17 of 17 | 17 of 17 |
| Progressive bonuses and DD1 on the new rule; the three presets and D5b's seven options through the menu's code path | scripted (`gmtest_diff04b_prog`, `_default`; `_preset`, `_relevel_*`) | 10 of 10, 3 of 3 | 10 of 10, 3 of 3; presets 6 of 6, re-level 15 of 15 |
| F2: a hostile frozen bandit of level 30 at Geralt 10 (Deadly) under the "Hardcore" values at 50% health; the boss bar shown for it after its spawn through the quest's path (`RunEvent_BossFocusModule_ShowBossIndicator`, `ShowBossFightIndicator`'s body): tagged, ×4 / ×4 (the mode's ×2 × 2), no Deadly ability, still 50% of a higher maximum, level 30, one set at its fight's start too; the bar hidden: ×3, Deadly back, 50%; the quest function `HealthBarVisiblityQuest` both ways: the same | scripted (`gmtest_diff04c_f2_a`, `_bar`, `_check`, `_b`) | 6 of 6 | 6 of 6 |
| F1 on the test-only slot (Geralt at level 20), the "Hardcore" values (Upscale, progressive 10 and 5): a friendly frozen bandit (level 8) and drowner (4) at Geralt's 20; after `Ciri()`: each at its own level with its per-level count (7, 3), re-levelled already, the mode's multipliers under the modifiers, her adjustment on "Death March!" only; after `Geralt()`: both at 20 with 24 per-level bonuses, no adjustment; on "Blood and Broken Bones!" and on "Death March!" | scripted swaps (vanilla's `Ciri()` and `Geralt()`; `gmtest_diff04c_f1_a`, `_b`, `_c`) | 6 of 6 per mode | 6 of 6 per mode |
| In the regression: the "Hardcore" values and the boss tag on a bandit (×3 / ×4); in the panel: three mode changes under the "Hardcore" values (×3.75 on "Death March!", ×1.5 on "Story and Sword!", ×3 back) | scripted (`GMTest_diff04`, `GMTest_diff04_after`) | passed | passed |

On a throwaway build without the code they guard (legacy's sum in `GMAddOptionBonuses`, no boss-bar or quest-function wrappers, no `OnPlayerChanged` wrapper, the steps left on at a mode change, DMG-05's step without the floor; the tests kept; deleted, the real build reinstalled), these failed: 8 of the 10 F3 cases (legacy's figures: ×3 / ×4 for the "Hardcore" values on "Death March!", the boss ×3.5 / ×4.5, ×0 and less on "Just the Story!", ×−0.49 / ×−0.25 at −100% there; the two that passed are "Story and Sword!" +50%, the same under both rules, and the restore), 9 of D5b's 11 modifier settings and 12 of the 17 hits, every F2 step (with the bar or the quest tag the bandit kept its Deadly ability and the plain modifiers), the F1 checks as Ciri (both samples still at Geralt's 20 with 24 per-level bonuses), and in the regression the two DIFF-04 modifier checks (1,095 passed, 2 failed) and two of the panel's three mode changes.

**Regression** (5.x-GM `38e2b55e`, `god()` off, `exec --wait 4500`): `gmtest_regress()` 1,097 passed, 0 failed in each tree; `gmtest_panel()` 139 passed in the new tree's first launch; in the classic tree 138 passed and 1 failed (the AI-18 stone check, no knockdown) in the first two launches and 139 in the third.

**Saves:** none written: the test-only slot `<save name>` was loaded and not saved over; no autosave. The user settings were restored with the game closed (no scaling group; the classic tree, sign cooldown, regen settings and difficulty as before).

**Deviations:** three new, one per decision (DIFF-06's re-level at a player change; DIFF-04's combination and its boss-bar recompute); the porter's calls the owner confirmed on 2026-10-31 (Ciri's spawn update with the chosen mode, random levels across a reload, Reinald's and the `mq1000` wraith's real level, the knockout's encumbrance update left to WGT, legacy's stats for the archespore and the barber quest's enemy) are marked confirmed where they are recorded.

---

### Planned additions (owner, 2026-10-31)

Both built (2026-10-31): (A) is [DIFF-09](#diff-09-ciris-sections-difficulty), (B) is [DIFF-10](#diff-10-interpolated-enemy-scaling).

### Dependencies on other areas

- **Done areas DIFF builds on:** AI (the level code and the levels, AI-01, AI-06; the variants' parents, AI-03, AI-04, AI-19, AI-20), DMG-05 and DMG-10 (where the multipliers apply), STAM-08 (the Death March ability), STAM-03 and DEF-04 (Ciri), UI-12 (the displayed level), OPT-01 (the menu framework).
- **Areas DIFF shares with or waits for:** OPT (the scaling group joins its menu; OPT's own regen options are UI-05's temporary deviation, not DIFF's), XP (DIFF-08, the "Experience" group), ECON (money is scarcer under ECON; DIFF-07's share is DIFF's).

### Hand-offs received

Every item other areas handed to DIFF, and where it lands:

| From | Item | DIFF |
|---|---|---|
| DMG (hand-off), DMG-05 deviation | The difficulty multipliers' values (`difficulty_Common*`) | DIFF-01; ends the deviation |
| DMG (hand-off), DMG-13 | The scaling options' abilities (`ModSigns*`), the scaling options and level randomisation (`W3GameParams.Get*Mult`, `ManageNGPLevels`, `ResetLevel`, `SetLevel`, `OnLevelUpscalingChanged`), the options in `modSignsConfig.xml` | DIFF-04 (`ManageNGPLevels`' fake addon: DIFF-05; `OnLevelUpscalingChanged`, `SetLevel`, `ResetLevel` are ported by AI-01) |
| DMG (hand-off) | Per-enemy difficulty variants and Ciri's stats ("97 units") | DIFF-02 (99 units, NG+ included), DIFF-06 (16 ability units) |
| AI (hand-off), AI-01 deviation | `PrologModifier` | DIFF-03; ends the deviation |
| AI (hand-off), DA2 | The scaling options and their code paths in `AddLevelBonuses` (random levels, nonlinear level-up, animals halved, guards' extra levels), `ModSignsAddBonuses`, the option getters, the menu | DIFF-04 |
| AI (hand-off) | 65 per-difficulty enemy variants and their NG+ copies | DIFF-02: by the comparison, 52 variants legacy changed in the regular files (50 DIFF-02's, 2 already AI-03's) and 49 NG+ copies (the Caretaker's 2 NG+-only changes are AI-19's); the difficulty multipliers are DIFF-01's |
| AI (hand-off), AI-20 deviation | The drunken master's +50 fist damage on "Death March!" (`mon_EP2_hardcore_FF`) | DIFF-02; ends the deviation |
| AI (hand-off) | Ciri's abilities (`Ciri_*`, `CiriHardcoreDebuff*`) | DIFF-06 |
| AI (hand-off), UI (hand-off), UI-12 deviation | The fake level addon (`levelFakeAddon`, `mq1028_gerd`) and the displayed level's cap | DIFF-05; ends the deviation |
| AI (hand-off) | `r4Game.GetSpawnDifficultyMode` | DIFF-06 |
| EFX (hand-off) | Deadly enemies' blindness immunity (`AddLevelBonuses`, `RemoveAllLevelBonuses`) | Ported by AI-01 (slice A1): nothing left |
| LOOT (hand-off) | The other properties of LOOT's binary entities (stats, abilities, levels, immunities) | Placed by AI; the only DIFF property in them is the fake addon, AI-06's for its 71 files: nothing left |
| XBOW (hand-off) | Skellige archers' and the Emhyr crossbowman's levels | AI-06's (signed off): nothing left |
| STAM (STAM-08) | "Stamina regen for AI no longer boosted for DM" | Ported by STAM-08: nothing left (the ability moves to DIFF-01's file, PD2) |
| ITEM (ITEM-10) | Durability by difficulty | Ported by ITEM-10: nothing left |
| STAM-03 attribution note | Ciri's quest abilities (`OnSpawned`) | DIFF-06 |
| feature-mapping (roadmap, step 6) | The `DIFF` area | this file |

**Temporary deviations "until DIFF"** ([deviations.md](deviations.md)), all four ended by this area:

| Feature | The port today | Ended by | What ending it needs |
|---|---|---|---|
| [AI-01](ai.md#ai-01-level-bonuses) | Enemies on the two lower modes lose 30% attack power while Geralt is level 1 (5.x's `PrologModifier`; in fact never added, see DIFF-03) | DIFF-03, slice D1 | **Ended** (2026-10-29): the ability emptied, the bullet rewritten |
| [AI-20](ai.md#ai-20-fistfights) | The drunken master gets no +50 fist damage on "Death March!" (5.x: +80% attack power) | DIFF-02, slice D2 | **Ended** (2026-10-29): legacy's variant; a real fistfight on "Death March!", +50 on every punch |
| [DMG-05](dmg.md#dmg-05-order-of-damage-steps-and-final-damage) | 5.x's damage multipliers (+40%, +130%, +230%; "Just the Story!" none) at legacy's position | DIFF-01, slice D1 | **Ended** (2026-10-29): legacy's four abilities (health too); scripted hits on two modes and a real bite |
| [UI-12](ui.md#ui-12-enemy-level-on-the-hud) | The displayed level adds 5.x's fake addon, capped at the maximum level +5 | DIFF-05, slice D6 | **Ended** (2026-10-30): the addon and the cap dropped, the addon zeroed at spawn; the HUD's level read for the five 5.x entities with an addon |

Not recorded as deviations but also 5.x's until DIFF: the scaling menu, until slices D5a and D5b (DIFF-04; AI-01 fixed legacy's recommended preset meanwhile, DA2, ended by D5a). D5b ends no temporary deviation; D6 ends the last, UI-12's. Ciri's cap, stats and Death March adjustment were 5.x's until slice D3 (DIFF-06), the guards' toll until slice D4 (DIFF-07).

### Hand-off to other areas

| Area | Changes |
|---|---|
| AI | `mon_archespor_hard` and `mon_q703_mqsidqpyt` (and NG+): enemy stats legacy changed that AI-03's attribution missed (not difficulty variants); attributed to AI-03 and ported through `gen_ai.py` with slice D1, legacy's stats (porter's call, confirmed by the owner, 2026-10-31) |
| XP | DIFF-08 (experience independent of the mode; `CalculateExperiencePoints`, `OnGiveReward`); the "Experience" option group |
| OPT | The menu framework the scaling group joins; the shared "Recommended", "Off" preset labels |
| WGT | Found with slice D4, unattributed: legacy's `CR4PlayerStateUnconscious.OnLeaveState` updates Geralt's encumbrance after he is revived from any knockout (`UpdateEncumbrance`, `//modSigns`; not in the changelist). Not ported in DIFF: WGT's (porter's call, confirmed by the owner, 2026-10-31) |

### Save impact

None expected: abilities are read at spawn and when the mode changes, options live in the user settings. New saved data: DIFF-04's random level per NPC (a new field) and DIFF-05's zeroed addon on NPCs spawned with the mod. Adding or removing the mod mid-playthrough is not supported ([save compatibility](../feature-mapping.md#save-compatibility)).

### Area decisions

**Area decisions** (all decided by the project owner, 2026-10-29):

| # | Question | Options | Recommendation | Decision |
|---|---|---|---|---|
| DD1 | Enemy scaling when the player never opens the menu (DIFF-04). Legacy's code reads untouched scaling options as off: enemies keep their own levels (a level-3 drowner stays level 3 next to a level-20 Geralt), guards 16 levels above him; its release readme told players to apply the recommended presets, whose "Recommended" scaling preset is soft upscaling; only the gameplay group got defaults in code. 5.x has no such options; the port plays soft upscaling, fixed (AI's DA2) | (a) the "Recommended" preset's values as the defaults of every unset scaling option (soft upscaling, nothing else); (b) legacy's literal default: no scaling until the player picks a preset | **(a)**: the setting legacy told players to use and the one the port has been balanced and tested with since AI-A; OPT already gives every other group per-option defaults | **(a)** (project owner, 2026-10-29): with the menu never opened, soft upscaling; a deviation from legacy's code ([DIFF-04](#diff-04-enemy-scaling-options)). How legacy played stays on the [legacy test list](../open-questions.md#to-test-in-legacy-ghost-mode) |
| DD2 | Money taken when guards knock Geralt out (DIFF-07). Legacy: a quarter of his money on every mode, no cap. 5.x: 25% on "Just the Story!", 40% on "Story and Sword!", 65% on "Blood and Broken Bones!", 85% on "Death March!", at most 750, 1,250, 1,750 and 2,250 crowns | (a) legacy's quarter; (b) 5.x's tiers and caps; (c) a quarter, with 5.x's cap | **(a)**: legacy behaviour first; 5.x rebalanced the toll, it fixed no defect, and legacy deliberately took the difficulty out of it. Against 5.x, legacy takes the same on "Just the Story!" up to 3,000 crowns and more above it, and less on the other modes below 5,000, 7,000 and 9,000 crowns, more above | **(a)** (project owner, 2026-10-29): a quarter of Geralt's money on every mode, no cap |
| DD3 | 5.x's accessibility aids next to the difficulty modes. Legacy: none existed (1.32 had none). 5.x: "Vitality Regeneration Boost" (extra Vitality regen below a threshold, off by default) and the "Bard's Ballad: Focus & Rest" preset, which switches several aids on at once, in the Accessibility menu | (a) leave them available as 5.x has them, untuned for Ghost Mode, as ITEM's DI4 did for "Disable item durability"; (b) hide them | **(a)**: opt-in aids outside the difficulty modes; hiding vanilla accessibility options is not legacy's to decide. The regen boost adds to Ghost Mode's regen when on (not tested) | **(a)** (project owner, 2026-10-29): both stay, untuned. Not a deviation: no legacy rule changes; the options are new in 5.x, off by default and the player's own choice, as ITEM's DI4 |
| DD4 | "Do not upscale animals" (DIFF-04): legacy's changelist says "disable upscaling for animals"; legacy's code, with any scaling on, has wolves, boars and other beasts on Vitality skip scaling and lowers any above half Geralt's level to half of it (a level-20 wolf pack meets a level-20 Geralt at level 10). 5.x has no such option | (a) the code, lowering included; (b) the changelist: animals only skip scaling | **(a)**, by the project's rule that the code is the better guide (2026-10-05); the option is off in all three presets | **(a)** (project owner, 2026-10-29): legacy's code, lowering included |

**Porter's calls** (each follows legacy or has no play effect; all confirmed by the project owner, 2026-10-29; PD6 then changed by the owner to a deviation from legacy):

| # | Call |
|---|---|
| PD1 | DIFF is ported as one area in two parts (DIFF-A, DIFF-B) with one audit at the end, about 360 units |
| PD2 | One home per ability: `difficulty_CommonHardcore` leaves STAM-08's `gm_npc_stamina.xml` for `gm_diff.xml`, given whole with legacy's entry (stamina regen 0 included); STAM-08's checks re-run with slice D1 |
| PD3 | DIFF-01, DIFF-02: legacy's values for every mode and every variant, as 5.x changed none |
| PD4 | DIFF-05: `mq1028_gerd`'s addon edit not ported as an entity edit: the runtime zeroing gives the same level on screen |
| PD5 | DIFF-06: legacy's Ciri: no cap, her stats, the Death March adjustment zeroed, the two quest abilities by journal state |
| PD6 | DIFF-04: every scaling option applies at once (the owner's decision, 2026-10-29, replacing the call to keep legacy's gap). Legacy's `gmIsScalingOption` list misses "Use progressive level bonuses", its two level-delta options ("Level delta", "Abilities per level delta") and the two boss health and damage modifiers, so changing only those left the enemies already near Geralt as they were until his next level-up. The port adds the five to the list: changing any scaling option re-levels the enemies near Geralt at once (a deviation, recorded in DIFF-04's Decisions) |
| PD7 | DIFF-08 goes to XP with the rest of experience |
| PD8 | Legacy's `ciriquests` debug command is not ported (a debug print, as AI-21's log) |
| PD9 | NG+: legacy's NG+ difficulty abilities, variants and Ciri's abilities equal its regular ones, so the NG+ copies keep legacy's values ([NG+ numbers](../feature-mapping.md#ng-numbers): legacy kept the value), not scaled from 5.x's higher NG+ multipliers; untested |
| PD10 | Option ids, label keys and string ids stay legacy's (`GMScalingOptions`, `Virtual_GMScaling`, 2110992002 to 2110992498), so legacy's translations in 9 languages carry over |

### Port order

Each slice compiles and is verified on its own with spawned enemies, `difflevel()` per mode (restored after) and the regression in both trees; DIFF touches no skill, so the trees differ only in the regression run. One audit after D6 (PD1).

| # | Slice | Ends |
|---|---|---|
| D1 | **Done** (5.x-GM `5d06b030`, 2026-10-29). DIFF-01, DIFF-03: `tools/gen_diff.py` (`--check`, `--verify`, a data test `tests/gmTestsDiffData.ws`) with the four difficulty abilities and `PrologModifier`, `gen_npc_stamina.py` dropping its Death March entry (PD2); multipliers on each mode, scripted hits on two modes, a real bite on "Death March!", the prologue cut gone at level 1; with it AI-03's two missed abilities | DMG-05's and AI-01's deviations (ended) |
| D2 | **Done** (5.x-GM `53427f7b`, 2026-10-29). DIFF-02: the 50 variants added to the generator (attribution.csv's DIFF-02 units); data read, spawned kikimores, a shaelmaar, a slyzard, the guard knight and Olgierd on each mode, a real fistfight against the drunken master on "Death March!" | AI-20's deviation (ended) |
| D3 | **Done** (5.x-GM `73734341`, 2026-10-29). DIFF-06: Ciri's cap removed (also from her spawn's update, a deviation), her eight abilities, the journal check; as Ciri on every mode, multipliers and variants read, the adjustment empty on "Death March!", a real fight, her abilities, the journal states set by script; Geralt's state compared after the swap back | — |
| D4 | **Done** (5.x-GM `232d10f8`, 2026-10-29). DIFF-07: the guards' toll (DD2: a quarter on every mode, no cap); a real knockout by a spawned guard on "Just the Story!" and "Death March!", the toll on each mode by script. Part DIFF-A complete | — |
| D5a | **Done** (5.x-GM `f929bfc3`, 2026-10-30). DIFF-04, part 1: the menu group with the scaling types, random bounds, guards' and animals' options and DD1's defaults, replacing DA2's fixed soft scaling; levels per type at Geralt levels 10 and 20, random levels across a save (kept after a load: a deviation, porter's call), re-levelling on a change through the menu's code path, every name in the scaling list; the menu on screen and a change by hand in the cleared run (2026-11-01) | AI's DA2 fixed preset (ended) |
| D5b | **Done** (5.x-GM `ad314f9f`, 2026-10-30). DIFF-04, part 2: the health and damage modifiers (`ModSigns*`, `GMAddOptionBonuses`), the boss modifiers (bosses: the `HideHealthBarModule` tag), progressive level bonuses, the three presets, the last 9 labels in 9 languages (and OPT's shared "Recommended" and "Off"); modifiers, hits and progressive counts on four samples, the presets and each new option re-levelling at once through the menu's code path, DD1; the menu on screen and changes by hand in the cleared run (2026-11-01) | — |
| D6 | **Done** (5.x-GM `523457b1`, 2026-10-30). DIFF-05: the displayed level without the addon and cap, the addon zeroed at spawn; the scan of every 5.x entity (10 files now show a lower level); the HUD's level read for Gerd, the `q305` guard, a `q702` mill worker, the `mq1000` wraith and Reinald, under soft upscaling and with scaling off, and in NG+; the HUD on screen in the cleared run (2026-11-01). **The whole of DIFF is ported**: next, DIFF's audit (PD1) | UI-12's deviation (ended) |

**Generator work:** `tools/gen_diff.py` (since D1) on `gen_ai.py`'s pattern (legacy's entries whole, `replace` where 5.x defines the name; its `SPEC` lists the four difficulty abilities and `PrologModifier`, since D3 Ciri's eight, since D5b the five `ModSigns*`; since D2 it adds every unit attribution.csv gives DIFF-02 (`diff02()`); `--check`, `--verify` node by node against legacy in both folders, the data test). Four of DIFF-02's variants are written `name ="..."` with a space; the tools' ability parser reads that spelling since D1; `gen_ngplus.py` after it (it keeps legacy's values where legacy gave NG and NG+ the same, which covers every DIFF entry); `gen_npc_stamina.py`'s `OWNED` gains `difficulty_CommonHardcore`; the labels copied from legacy's CSVs by id into the port's localization (OPT's way). No entity edit (PD4).

**Later:** —
