# AI: enemies, their stats and how they fight

Enemies and NPCs: how much health, attack power, armor and resistance each kind has and how that grows with its level, the weapons they hold, how they dodge, guard, parry, counter, taunt and pick targets, how hits stagger them, and the special rules of particular enemies (the Wild Hunt's Ice Armor, the djinn's rage, the Caretaker's healing, rotfiends, golems, flyers, fistfight opponents). Ghost Mode's changelist has its own section (AI, 1091–1135): "Individual monster armor and resistances changed significantly, armored monsters are indeed armored and you need to deal with it", "Levelup bonuses for NPCs redone ... both armor and resistances are defined by enemy type alone", "AI combat parameters were tweaked to make them react better to player actions", "AI should be better at dodging", "Adjusted AI targeting priorities ... makes Axii Puppet more useful", the Wild Hunt's frost damage and Ice Armor, the djinn, the weakened state, the Caretaker; the bugfix list adds the Wild Hunt bosses' frost slowdown (75), chorts and fiends not attacking (77) and the Caretaker's shovel (101). Sources: those lines, every hand-off to AI, and the code and data, which have more than the changelist (the hit-reaction rules, the level code, the monster projectiles, the fistfights, the arachas' speed).

**What 5.x did in this area** (from `vanilla-5.x`, unverified in game). The enemy data is almost all 1.32's: of the 1,000-odd monster, NPC and weapon entries legacy changed, 5.x changed 39 (the level abilities' sign resistances, the human combat templates' guard and counter rolls, allies' attack power, a few spiders' and boars' resistances, two quest enemies' attack power; [AI-08](#ai-08-combat-parameters), [AI-03](#ai-03-monster-stats)); NPC, monster and secondary weapons are 1.32's. 5.x adds enemies legacy never saw: the witcher Reinald of its new quest `mq1060` (`mq1060_Reinald`, his own sign effects) and a red-plague creature with its own behaviour tree and projectile (DA5). 5.x's monster rework ("attack patterns, counterattacks, movement and effect application of all non-boss monsters") is in the monsters' behaviour trees (`.w2behtree`, from the game files, unverified in game): about 13 monster combat trees changed (the fiend and chort; wolves: pack tactics, the pack leader's howl, reactions on hit; the gryphon family: griffins, basilisks, cockatrices; wyverns and forktails: counterattacks on the counter event, a venom spit; werewolves: five wolves summoned, a full-moon buff on Hard; arachases and endregas: the shell pull after a hit a fixed 15% roll; ghouls: a hop away; drowners: an attacker limit by difficulty, directional dodges; cyclops and ice giants: a taunt as a counter; small changes to the leshen, the Hearts of Stone boar, fugas and gargoyles, golems and elementals), while every other tree equals 1.32's (nekkers, harpies, wraiths, katakans, bears, trolls, sirens, foglets and hags, all of Blood and Wine's monsters, every human defence and tactic tree but one property of `npc_def_parry`), and the entity templates keep their tree assignments. 5.x's new scripted tasks (drowner adds, the three-state charge, summons with a level, drop from above, teleport conditions, ability add and remove, buff immunity, fact check, can-dodge) are used by no tree or monster entity. Of the tasks AI ports, 5.x touched only dodging (a ×1.15 dodge and counter chance in NG+, an instant dodge), the defend task's parry sound, a quest boss's taunt, the new quest witcher's sign effects and the Caretaker's bleed removal. The level code changed: animals, rats and the djinn get no level bonuses, guards are 1–4 levels above Geralt instead of 11–13, the "red skull" bonuses for enemies far above Geralt are commented out, and the level-difference thresholds moved from 6 and 15 to 10 and 20 ([AI-01](#ai-01-level-bonuses)). Every monster and NPC projectile gains 2.5% of its damage per Geralt level when it hits (`W3AdvancedProjectile.OnProjectileCollision`, as XBOW found). The witch's boiling water is rebuilt as a weapon attack. Succubi became silver-vulnerable humanoids (5.x's `ConDefaultSilver`, the same intent as legacy's [AI-02](#ai-02-npc-templates)). 5.x's entity files keep 1.32's levels; they add two buff immunities to many monsters.

**How legacy Ghost Mode implements it.** Data: the monster abilities (`monster_base_abl.xml` and the Hearts of Stone, Blood and Wine and free-DLC files), the NPC abilities (`opp_base_abl.xml` and Hearts of Stone's), the level-bonus abilities (`monster_base_abl_new.xml`), NPC, monster and secondary weapons (`def_item_npcweapons.xml`, `def_item_weapons_mon.xml`, `def_item_weapons_secondary.xml`, the `NPC *` and fist entries of `def_item_weapons.xml`, the expansions' counterparts), all regular and NG+ (legacy's NG+ files equal its regular ones); 422 binary files, nearly all entity templates (levels, stat templates, monster categories, weaknesses, immunities, projectiles, the fiend's behaviour tree). Scripts: the level code (`CNewNPC.AddLevelBonuses` rewritten and split), the behaviour-tree tasks (dodge, defend, parry, taunt, Quen, the toad, the tornado and ground trap), the AI parameters (target weights, taunt timing), hit reactions (`types.ws`), flyers (`CNewNPC.ReactToBeingHit`), Ice Armor (`OnFireHit`, `GetDamageResists`), the special attacks' damage (monster projectiles, ice spikes, leshen roots, boiling water, bird swarms, the toad's acid), fistfights.

Unit lists: [attribution.csv](attribution.csv), mapped 2026-10-27 from the changelist, every hand-off to AI, a field-by-field comparison of every ability and item legacy changed in the monster, NPC and weapon files, `bindiff.py` over every binary file legacy changed, every unit in `npc.ws`, `actor.ws`, `scripts/game/behavior_tree/` and `scripts/game/projectile/`, and `unit_sweep.py` sweeps. **2,125 units carry an AI feature**: 93 script units, 789 XML units and their 821 NG+ copies, 422 binary files; 345 are shared (the enemies' abilities with STAM-08's stamina values, the entity files with LOOT's loot, the damage functions with DMG and EFX). Ten behaviour-tree units the sweep found belong to STAM-08, which ports them. Units that only look like AI belong to other areas ([scope](#scope)): the per-difficulty enemy variants, Ciri, the scaling options and fake levels (DIFF), experience (XP), weights and prices.

Port status: **the AI area is signed off** by the project owner (2026-10-29): AI-A (2026-10-28), AI-B (2026-10-28) and AI-C (2026-10-29), each audited before its sign-off; AI-21 is not ported (PA13). The owner decided DA1 to DA5 and confirmed PA1 to PA15, DA5's numbers and every porter's call and deviation of the area. Open checks stay in the entries.

**Size and split.** AI is the largest area after CRAFT and LOOT by units, and the only one mixing a data overhaul (every enemy's numbers) with behaviour code. It was ported and audited in three parts (DA1):

| Part | Features | Units | What it is |
|---|---|---|---|
| **AI-A Enemy stats** | AI-01 to AI-07 | about 1,850 | Data and the level code: how strong each enemy is. Generators with `--verify`, as ITEM, SWD and ARM did |
| **AI-B Enemy behaviour** | AI-08 to AI-14 | about 300 | How enemies fight: their combat rolls, dodging, guarding, targeting, poise |
| **AI-C Special enemies** | AI-15 to AI-21 | about 250 | One-off rules: the Wild Hunt, the djinn, rotfiends, the Caretaker, special attacks and projectiles, fistfights |

## Scope

**AI covers** the enemy stat model (level bonuses and NPC templates), every enemy's health, attack power, armor and resistances, human NPC armor and allies' stats, NPC, monster and secondary weapons, enemy levels and stat flags in the entity files, monster categories and weakness lists, the enemies' combat rolls, dodging, guarding and countering timing, taunts, targeting, poise and hit reactions, flyers forced to land, monster-specific fixes, the Wild Hunt, weakened states and the djinn, instant kills and LastBreath, special attacks and monster projectiles, the Caretaker and the quest monsters' immunities, fistfights, the pre-attack debug log.

**Already ported by other areas** (nothing left for AI; the hand-offs naming them close here):

| Subject | Ported by | What |
|---|---|---|
| NPC stamina: attack costs, defence needing stamina, the low-stamina wait, the enemies' stamina values | STAM-08 (signed off) | `stamina/npcStamina.ws`, `gm_npc_stamina.xml` (145 abilities, generated); AI gives some of the same abilities whole ([PA2](#area-decisions)) |
| Stunned or countered enemies do not dodge, parry or react | DEF-06 | `defense/enemyDefense.ws`; AI-09 adds legacy's other guards in the same lines |
| Human NPC armor from their equipment (the lazy armor fix) | DMG-15 | `damage/weapon.ws`, called from AI-01's `AddLevelBonuses` (slice A1); the armor values are AI-04's |
| Hits below 1 deal nothing and play no hit animation | DMG-01 | the damage half of `ModifyHitSeverityReactionFromDamage`; its poise half is AI-12 |
| NPC weapon damage read from the held item | DMG-08 | `CActor.GetTotalWeaponDamage` |
| Allies' damage dealt and received, 5.x's ally damage boosts off | DMG-12 | `damage/formula.ws`; the allies' own stats are AI-04's |
| NPC bows and crossbows, archers' stamina | XBOW-08, XBOW-09 | the 5.x projectile level term they kept is AI-18's (removed in slice C2) |
| A frozen rotfiend killed outright, its explosion harmless | EFX-09 | the explosion's own damage and LastBreath's cap are AI-17's (slice C2) |
| The creatures' weaknesses in the bestiary journals | UI-11 | the same lists in the creatures' entity files are AI-07's |
| No "???" for enemies far above Geralt | UI-12 | the fake level addon stays DIFF's |
| Silver Dust on monsters (no teleport, weaker drain), the djinn kept weak under Dimeritium | ALCH-14, ALCH-15 | the djinn's rage and weakness values are AI-16's |
| Aard deflecting boulders and stones | SKL-08 | the projectiles' damage is AI-18's (slice C2) |
| Axii's Puppet freed by Geralt's hits | SKL-12 | legacy also removed vanilla's freeing line in `CNewNPC.ReactToBeingHit`; SKL-12's rule covers it; the line is gone since AI-13's replacement of the function (slice B2) |
| The enemies' monster-hunt loot, mutagens, quest inventories | LOOT | the same entity files' levels and stats are AI's |

**Not AI** (DA2):

| Subject | Area | Why |
|---|---|---|
| The level-scaling options (none, upscale, match, soft, random), the extra health and damage options, the nonlinear level-up, guards' extra levels option (`W3GameParams.Get*Mult`, `GetEnemyScalingOption`, `ModSignsAddBonuses`, `ModSigns*` abilities, `r4Game.GetSpawnDifficultyMode`, the menu) | DIFF | Options; AI ports the level code, whose scaling follows DIFF-04's options |
| Difficulty multipliers (`difficulty_Common*`), the prologue's attack-power cut (`PrologModifier`), per-difficulty enemy variants (65 abilities and their NG+ copies: `*_hard`, `*_hardcore`, `*_easy`, Olgierd's four, Blood and Wine's) | DIFF | "Difficulty modes" section; DMG handed them to DIFF |
| Ciri's stats (`Ciri_*`, `CiriHardcoreDebuff*`) | DIFF | "Ciri health, armor and damage tweaked accordingly" (Difficulty modes) |
| The fake level addon (the HUD code; `levelFakeAddon` in `mq1028_gerd`; the 71 AI files where legacy made a fake level real carry legacy's addon with their level, AI-06) | DIFF | Ported by DIFF-05 |
| Experience for kills (`CalculateExperiencePoints`, `GetExpByEnemyType`, `GetEnemyTypeByAbility`, the `experience` nodes of the level abilities) | XP | Progression |
| Weapon weights, prices | WGT, ECON | as every area |
| Projectile collision fixes (`CBTTaskShoot.ShootProjectile`, `CBTTaskProjectileAttack.Initialize`) | FIX | as XBOW and DEF left them |
| Adrenaline-gain pause (`CActor.PauseFocusGain`), the basic attacks' `focus_gain` | STAM, SKL | Geralt's adrenaline |
| The siren crawl finisher's animation (`W3SyncAnimationManager.SetupSimpleSyncAnim`) | SKL (finishers) | Geralt's finisher |
| Iris's phantom strike in `CActor.OnProcessActionPost` | SWD-06 | |

## Changes at a glance

### What Ghost Mode changed

| # | Feature | Vanilla 1.32 | Legacy GM | Units (main) |
|---|---|---|---|---|
| AI-01 | Level bonuses | Per level: humans +55 Vitality, +20 attack damage; monsters +270 Essence (+90 in groups), +40 attack power; +0.7–1% sign resistances; enemies 6+ and 15+ levels above Geralt ×3.5–8 health, ×1.2–5 attack power, effect immunities | Per level: +8–20 health plus 15%, +1 attack power plus 0.5–1% (from 11); no resistances; 6+ and 15+ levels above: +33% and +50% damage-over-time resistance only; animals levelled too; NG+ level added to the level | 12 abilities (and NG+), 10 `npc.ws` units |
| AI-02 | NPC templates | `ConDefault` 25 Vitality, 50% fire resistance; `ConAverage` 500, `ConAthletic` 1000; `MiniBoss` ×1.5, `Boss` ×2.5 health | `ConDefault` 80 (no fire resistance), `ConAverage` 160, `ConAthletic` 320; `ConHumanoidMonster` (500 Essence) for humanoid monsters; `MiniBoss`/`Boss` +500/+1000, attack power, +10% resistances, +50% damage-over-time resistance | 10 abilities (and NG+), 150 entity files |
| AI-03 | Monster stats | 1.32's health, attack power, armor and resistances | Retuned per monster: group monsters less health, contract monsters and bosses more, armor where monsters are armored, resistances by kind | about 400 abilities (and NG+) |
| AI-04 | Human NPC armor and allies' stats | NPC armor 8/20/30/40/50 | 30/45/60/90/120, with resistances; allies' and quest humans' stats retuned | 30 abilities (and NG+) |
| AI-05 | NPC, monster and secondary weapons | 1.32's damage | Retuned (humans' swords up, most monsters' attacks up, a few down), Wild Hunt weapons with frost damage | about 250 entries (and NG+) |
| AI-06 | Enemy levels and flags | 1.32's levels | About 270 entities re-levelled (mostly +1 to +5, quest NPCs up to +35); stat flags (`NPCDoNotGainBoost`, `NoAdaptBalance`) set; two level fixes in code | 284 entity files, 2 units |
| AI-07 | Monster categories and weaknesses | Spiders specters, ghostly humans and succubi humans, dopplers humans | Spiders insectoids, ghostly humans specters, dopplers relics, succubi hybrids; weaknesses fixed | 41 entity files, `CActor.IsHuman` |
| AI-08 | Combat parameters | 1.32's dodge, counter, guard, taunt and teleport rolls | Retuned per enemy (e.g. dodge 20%, counter 20–60%, no waiting hits before a counter) | about 140 abilities (and NG+) |
| AI-09 | Dodging | 0.1 s dodge window, a delay between dodges, no dodge while attacking, dodges overlap, up to 5 m away; dodges when the check says no | 0.25 s window, no delay, dodge out of an attack, no overlap, up to 3 m; no dodge in the air or off the ground; the inverted check fixed | 12 units |
| AI-10 | Guarding, parrying, taunts | Hit and defend windows 2 s; taunt chance only when asked; monster taunt every 3 s, forced attack after 20 s; a broken shield staggers | 2.5 s windows; the defend task ends on the hit and protects the counter; always the taunt chance; 5 s and 10 s; a broken shield no longer staggers | 8 units |
| AI-11 | Targeting | Player weight 1000 (monsters) or 100 (NPCs) | 15; hitters and the current target weigh more, monsters for NPCs less | 2 units |
| AI-12 | Poise | Hit severity lowered by an unused stat | Light and heavy hit reactions reduced by the share of health a hit takes, more for tall enemies; golems never staggered by hits; huge means taller than 2 m | 4 units |
| AI-13 | Flyers forced to land | Only a hit taking enough health knocks a flyer down | Any damaging hit, bolt, Yrden or burning does | 1 unit |
| AI-14 | Monster fixes | Cyclops ignore Axii; toads escape Yrden after 3 hits; NPC Quen staggers 0.1 s; chorts and fiends may not attack | Fixed; arachas slower (×0.75); the fiend's tree gains a close-range melee branch | 12 units |
| AI-15 | The Wild Hunt | Ice Armor halves damage, removed by Igni; no frost damage | Ice Armor +30% resistances (not on Easy), removed by any fire; frost damage and slowdown on their weapons and projectiles; generals retuned; Eredin no longer immune to signs | 44 abilities (and NG+), 4 units |
| AI-16 | Weakened states and the djinn | Djinn rage ±100% stamina regen | ±10% stamina regen, ±50% attack power; weakened enemies −15% physical resistances | 4 abilities (and NG+) |
| AI-17 | Instant kills and LastBreath | Contract monsters can be killed instantly | Immune; a LastBreath monster's hit capped at its threshold | 3 units, 1 ability |
| AI-18 | Special attacks and projectiles | Damage from the attacker's basic-attack stats, effects 2 s | Fixed damage or a share of the victim's health, with attack power and armor; effects 3 s; magic fists ranged; the Hakland mage's triple hit fixed | 56 units, 5 abilities |
| AI-19 | The Caretaker and quest monsters' immunities | Heals a fixed share per hit | Heals by the damage he deals; immunities set for five quest monsters; his shovel's Hearts of Stone ability | 10 units (and NG+) |
| AI-20 | Fistfights | Level-difference buffs, Geralt's Vitality clamped at 2000 | No level buffs, no clamp, fist damage bonus by opponent tier | 33 units (and NG+) |
| AI-21 | Pre-attack debug log | — | `toggledebugpreattack`, logs of incoming attacks | 6 units |

### What 5.x changed

| # | 5.x change (from code and data) |
|---|---|
| AI-01 | Animals, rats and the djinn get no level bonuses; guards 1–4 levels above Geralt; the High and Deadly bonuses commented out; thresholds 10/20 (1.32: 6/15); monsters' per-level sign resistances 0.7% (1.32: 0.9–1%) |
| AI-02 | `ConDefaultSilver` (new) for silver-vulnerable humanoids; succubi moved off `ConDefault` |
| AI-03 | Spiders' and boars' force and will resistances, two quest enemies' attack power (16 entries); two new abilities for succubi |
| AI-04 to AI-07 | None to the values (entity levels 1.32's) |
| AI-08 | Human combat templates: guard and counter waits 2–4 hits, counter chance 50–75% (randomised); NG+ ×1.15 dodge and counter chance |
| AI-09 to AI-14 | About 13 monster combat trees reworked (the fiend's gains legacy's close-range branch itself); the dodge task's instant dodge; the targeting weights, hit-reaction functions, flyers and the other fixes 1.32's |
| AI-15 to AI-17 | None (1.32's Ice Armor, Eredin, LastBreath) |
| AI-18 | +2.5% damage per Geralt level on every projectile hit; the boiling water rebuilt as a weapon attack; bird swarms ignore armor |
| AI-19 | The Caretaker clears 5.x's extra bleeding types when he heals |
| AI-20, AI-21 | None |

### Classification and proposed action

| # | Feature | Class | Proposed action |
|---|---|---|---|
| AI-01 | Level bonuses | conflict (5.x rewrote parts) | Legacy's (PA3 to PA6, DA2, DA4) |
| AI-02 | NPC templates | clean, overlap (5.x's silver humanoids) | Legacy's (PA7) |
| AI-03 | Monster stats | clean | Legacy's (PA1) |
| AI-04 | Human armor, allies | clean | Legacy's (PA1) |
| AI-05 | Weapons | clean | Legacy's (PA1) |
| AI-06 | Levels and flags | clean (binary edits) | Legacy's (PA8) |
| AI-07 | Categories, weaknesses | clean (binary edits) | Legacy's (PA8) |
| AI-08 | Combat parameters | overlap (5.x's trees, human rolls) | Legacy's on every enemy (DA3) |
| AI-09 | Dodging | clean | Legacy's |
| AI-10 | Guarding, taunts | clean | Legacy's |
| AI-11 | Targeting | clean | Legacy's |
| AI-12 | Poise | clean | Legacy's |
| AI-13 | Flyers | clean | Legacy's |
| AI-14 | Monster fixes | clean; the fiend's branch in 5.x already | Legacy's; the fiend's tree stays 5.x's (PA9) |
| AI-15 | Wild Hunt | clean | Legacy's; ends DMG-02's deviation |
| AI-16 | Weakened, djinn | clean | Legacy's |
| AI-17 | Instant kills, LastBreath | clean | Legacy's (PA10) |
| AI-18 | Special attacks | overlap (5.x's level term, boiling water) | Legacy's (PA11, PA12); ends XBOW-08's deviation |
| AI-19 | Caretaker, immunities | clean | Legacy's |
| AI-20 | Fistfights | clean | Legacy's; ends DMG-04's deviation |
| AI-21 | Debug log | clean | Not ported (PA13) |

---

## AI-A Enemy stats

### AI-01 Level bonuses

| | |
|---|---|
| Kind | system |
| Pillars | P1, P5 |
| 5.x class | conflict |
| Flags | balance (DA2, DA4 decided) |
| Depends on | DMG (the formula the stats feed, signed off), DMG-15 (lazy armor fix, called from the same code), DIFF (the options) |
| Skill trees | n/a |
| Port form | the twelve level abilities given whole (`replace`; `AnimalLevelBonus` and `DisplayedLevelAbl` new) in `abilities/gm_ai_levels.xml`, generated by `tools/gen_ai.py`, NG+ copy by `gen_ngplus.py`; `ai/levels.ws`: `@replaceMethod(CNewNPC)` `AddLevelBonuses` (the timer: legacy's body; its scaling by DIFF-04's options since DIFF's slice D5a, DA2's fixed preset before), `OnLevelUpscalingChanged` (emptied), `SetLevel`; `@wrapMethod(CNewNPC)` `OnSpawned` calling `@addMethod` `GMManageNGPLevels` (overrides 5.x's NG+ block); `@addMethod` `GMInternalAddLevelBonuses`, `GMRemoveAllLevelBonuses`, `GMRestoreHealthPerc`, `GMResetLevel`; `@addField` `gmCurrentNGPLevel`; the thresholds as `W3GameParams` defaults (`stamina/staminaCosts.ws`, DA4). DMG-15's armor fix is called from `AddLevelBonuses`, as in legacy. `CActor.IsBeast` is not needed (only DIFF's animal option reads it; XP does not, XP's mapping 2026-10-31) |
| Port status | **signed off** (2026-10-28); ported (slice A1), verified in both trees |
| Open checks | real guards in the world (none near the test save, none reached without teleporting; the guard rule ran on a spawned human set to `ENGT_Guard`); a summon made by a real behaviour tree (the werewolf's wolves, the pack leader's howl; the summon templates spawned by script hold); New Game+ (untested, as every NG+ change) |
| Save impact | none: bonuses are removed and re-added whenever they are recomputed (Geralt's level changed, combat start); an NPC the save already holds keeps the maximum health it was saved with until then (verified with Vesemir in the test save, slice A3) |
| NG+ counterpart | applied (legacy's NG+ abilities equal its regular ones), untested |

**What it does** (changelist 1106–1113): an enemy's level adds only a little health and attack power, so its armor and resistances stay those of its kind at any level, and a strong kind stays stronger than a weak one as both level up (P1, P5):

| Per level above 1 | 1.32 | Legacy |
|---|---|---|
| Humans (`NPCLevelBonus`) | +55 Vitality, +20 light and heavy attack damage, +0.7% force, burning, will and shock resistance | +8 Vitality and +15%, attack power +1 and +1% (base 11) |
| Monsters, solo (`MonsterLevelBonus`, `…Armored`) | +270 (armored +240) Essence, +40 (42) attack power, +0.9–1% sign resistances | +20 Essence and +15%, attack power +1 and +1% |
| Monsters in groups (`…Group`, `…GroupArmored`) | +90 (80) Essence, +5 attack power, +1% | +10 Essence and +15%, +1 and +0.5% |
| Wolves and boars (`AnimalLevelBonus`, new) | the human bonus (1.32) | +8 Vitality and +15%, +1 attack power |
| 6+ levels above Geralt (`…High`) | ×3.5 (monsters) or ×5 (humans) health, ×1.2–1.4 attack power, +30–50% sign resistances, instant-kill immunity | +33% damage-over-time resistance (not on bosses), instant-kill immunity (monsters) |
| 15+ levels above (`…Deadly`) | ×6–8 health, ×4–5 attack power, 100% effect resistances, blindness immunity, no backstabs | +50% damage-over-time resistance, instant-kill immunity |
| A contract boss in NG+ (`BossNGPLevelBonus`) | +3% health and power per level | nothing |

Per-level swarm damage drops from +10–20 to +1. The rewritten `AddLevelBonuses` first removes every bonus, then: fixes duplicate constitution templates (AI-02), applies DMG-15's armor fix and DIFF's extra health and damage, stops for `NPCDoNotGainBoost`, sets guards to Geralt's level plus 16 (LEVEL_DIFF_DEADLY + 1; DIFF's option removes the 16), applies the level-scaling option (DIFF; legacy's recommended preset is "soft": enemies more than 6 levels below Geralt are raised to 6 below; animals optionally halved), gives level-1 enemies nothing, and adds the per-level abilities by kind (Vitality users, Essence users armored or not, group or solo; wolves and boars) and the High or Deadly ability to hostile non-bosses. A `DisplayedLevelAbl` per level keeps the level readable. NG+ adds the NG+ level to every non-animal's level instead of fake levels (none for Ciri, none with `NoAdaptBalance`). Vanilla's own upscaling option is switched off.

**Implementation (legacy):** `monster_base_abl_new.xml` (MonsterLevelBonus ×4, High, Deadly, AnimalLevelBonus, DisplayedLevelAbl, BossNGPLevelBonus, MonsterMHBoss), `opp_base_abl.xml` (NPCLevelBonus, High, Deadly); `CNewNPC.AddLevelBonuses`, `InternalAddLevelBonuses`, `RemoveAllLevelBonuses`, `ManageNGPLevels`, `OnSpawned`, `SetLevel`, `ResetLevel`, `OnLevelUpscalingChanged`, `<members>`; `CActor.IsBeast`.

**5.x:** 1.32's level abilities but for the commented-out High and Deadly and 0.7% sign resistances for monsters; `AddLevelBonuses` returns early for animals, rats and the djinn (no bonuses at all), puts guards 1–4 above Geralt (1.32: 11–13, more in NG+), drops the deadly blindness immunity, and caches the initial sign resistances (`CheckInitialPercResistances`; nothing in 5.x reads the cached values, `GetInitial*ResistancePerc` have no callers, so legacy's body without it changes nothing); thresholds 10 and 20 (`LEVEL_DIFF_HIGH`, `LEVEL_DIFF_DEADLY`). Under 5.x's model a level-30 griffin carries about 7,800 Essence of level bonus over its base 500.

**Decisions:** legacy's model (PA3); legacy's guards (PA4), animals, rats and the djinn levelled as legacy (PA5), legacy's damage-over-time resistances for High and Deadly (PA6), all confirmed by the owner (2026-10-28). DA2 (project owner, 2026-10-28): AI ports how enemies grow with level with legacy's recommended scaling fixed until DIFF: enemies at most 6 levels below Geralt, guards 16 above, no nonlinear level-up, no animal halving, no extra health or damage; DIFF later adds the scaling menu, the difficulty multipliers, the per-difficulty variants and the hidden (fake) level bonus. The fixed preset ended with DIFF's slice D5a (2026-10-30): the scaling follows DIFF-04's options, whose default is the same soft upscaling (DD1); the guards' 16 levels and the animals' halving are options there ([DIFF-04](diff.md#diff-04-enemy-scaling-options)). DA4 (project owner, 2026-10-28): legacy's 6 and 15 levels for "high" and "deadly", which also moves SKL-12's finisher rule (15 levels) and UI-12's red level (6 levels up) back to legacy's values ([skl.md](skl.md#skl-12-axii), [ui.md](ui.md#ui-12-enemy-level-on-the-hud)). The same thresholds are read by 5.x code of other features, which so reads 1.32's values again: quest experience (none for a quest 6 or more levels below Geralt; 10 in 5.x) and the kill-experience bonuses for enemies above Geralt, which legacy rewrote (XP); the quest colours in the journal and the "high-level quest" tutorial (1.32's, kept by legacy); not the fistfight opponents' level buffs: their function (`ApplyFistFightLevelDiff`) has no caller in 1.32 or 5.x ([AI-20](#ai-20-fistfights)). No reader uses 10 or 20 as a literal; the parry-fail chance per level difference is inert (no XML gives `chance_to_fail_parry_per_level_diff`). Lines of legacy's `AddLevelBonuses` that belong to other features come with them: AI-06's level fixes (a free DLC's nekker warrior, the deserters at one encounter) came in slice A3, AI-14's cyclops and arachas lines came in slice B3 (`GMMonsterFixes`). Since A3 rats and mice carry legacy's `NPCDoNotGainBoost` and get no level bonuses (as in 5.x, by legacy's flag instead of 5.x's code). 5.x's cache of the starting sign resistances (`CheckInitialPercResistances`) is dropped with legacy's body (nothing reads it), and `CActor.IsBeast` is not ported (only DIFF's animal option reads it; it came with DIFF-04): porter's calls, confirmed by the owner (2026-10-28). No 5.x path bypasses the level model: every NPC with an ability manager gets the bonus timer at spawn, combat start and the HUD's focus call `RecalcLevel`; summons are spawned from templates and get it like any spawn; quest and encounter levels come through `SetLevel`.
- `PrologModifier` (an attack-power cut of 30% for enemies on Easy and Normal while Geralt is level 1) is empty, as legacy emptied it ([DIFF-03](diff.md#diff-03-the-prologues-attack-power-cut)). 5.x's `OnSpawned` (1.32's) never adds the ability: it tests a local `playerLevel` it never sets, so the cut never applied in 1.32 or 5.x either.

**Verification (slice A1, 2026-10-28, both trees):** scripted, on frozen hostile spawned enemies (`gmtest_ai01_spawn()`, `gmtest_ai01_read()`, `gmtest_ai01_recalc()`) at Geralt levels 1, 10 and 30: every enemy had legacy's level, one per-level ability of legacy's kind per level above 1, High from 6 and Deadly from 15 levels up (none on wolves), and maximum health by legacy's formula (a bandit at level 24 on Hard: (80 + 23 × 8) × (1 + 23 × 0.15) × 1.2 = 1,409.76 Vitality). In the regression: the definitions (`GMTest_ai01`) and the level code (`GMTest_ai06_after`: a bandit raised to 6 below a set Geralt level, a drowner 6 above with High); both failed on a throwaway build without the slice. `gen_ai.py --verify` passes.

### AI-02 NPC templates

| | |
|---|---|
| Kind | tuning |
| Pillars | P1, P5 |
| 5.x class | clean, overlap |
| Flags | balance |
| Depends on | AI-01 |
| Skill trees | n/a |
| Port form | the ten templates given whole in `gm_ai_levels.xml` (`gen_ai.py`; `ConHumanoidMonster` new; `ConDefault` and `ConAthletic` left STAM-08's `gm_npc_stamina.xml`, PA2); `@addMethod(CNewNPC)` `GMCheckConstitutionAbility` (`ai/levels.ws`, called by `AddLevelBonuses`); the entity files' ability lists (`CCharacterStatsParam.abilities`) as binary edits of 5.x's files by `tools/gen_ai_ent.py` (with AI-06's and AI-07's, [below](#ai-06-enemy-levels-and-flags)) |
| Port status | **signed off** (2026-10-28); ported: abilities in slice A1, the entity lists in slice A3, verified in both trees |
| Open checks | — |
| Save impact | none (expected) for abilities; entity templates are read at spawn |
| NG+ counterpart | applied, untested |

**What it does** (changelist 1101, 1104–1105): base health by build, humans without 50% fire resistance ("Removed 87.5% of fire resistance from humans"), humanoid monsters (succubi, ghostly humans, the Ethereal) on Essence so silver works on them, and stronger elites:

| Template | 1.32 | Legacy |
|---|---|---|
| `ConDefault` | 25 Vitality, 50% fire resistance, stamina regen ×0.07 | 80, none, ×0.25 |
| `ConFrail`, `ConFat`, `ConAverage`, `ConPudzian`, `ConAthletic` | 10–50, 200, 500, 600, 1,000 Vitality; `ConFrail`/`ConFat`/`ConPudzian` +20/40/80% attack power | 50, 100, 160, 150, 320; no attack power bonus |
| `ConWitcher` (witcher NPCs) | 400 Vitality, +60% attack power (5.x: 800, +100%) | 500, none |
| `ConHumanoidMonster` (new) | — | 500 Essence, no Vitality |
| `MiniBoss` | ×1.5 health, ×1.25 attack damage | +500 health, +50 and +25% attack power, +10% physical, +20% other resistances, +50% damage-over-time resistance |
| `Boss` | ×2.5 health, ×1.5 attack damage, +40% sign resistances | +1,000 health, +100 and +50% attack power, +10% physical, +30% other, +30% sign, +50% damage over time |

In 150 entity files the template list changes: `ConDefault` removed 34 times, `ConHumanoidMonster` added 27 times, `ConAthletic` 10, `Boss`/`MiniBoss` removed from 12, quest sets added (`sq301_fistfighters`, `sq209_followers`, `mq1011_merchants`). An NPC with both `ConDefault` and `ConAthletic` keeps only the stronger one.

**Implementation (legacy):** `opp_base_abl.xml`; `CNewNPC.CheckConstitutionAbility`; `CCharacterStatsParam` in 150 entity files.

**5.x:** 1.32's templates but `ConWitcher` (800 Vitality, +100% attack power); a new `ConDefaultSilver` (25 Essence) for 5.x's own silver humanoids (the Blood and Wine succubus `mh303_succbus_v2`), and the generic succubus no longer `ConDefault`/human.

**Decisions:** legacy's templates and lists (PA7, confirmed by the owner, 2026-10-28). The templates' experience nodes are legacy's (XP's slice X1, AI-01's level abilities' too); their morale and taunt nodes are legacy's (AI-08: `ConDefault`'s morale regen ×0.1, no taunt chance); the new `ConHumanoidMonster` has no 5.x counterpart and stays legacy's whole: legacy's templates also where 5.x changed one (`ConWitcher` 500 Vitality, no attack-power bonus), and legacy's `ConHumanoidMonster` where 5.x gave an entity its own silver template; 5.x's `ConDefaultSilver` stays for 5.x's new entities. The entity lists (slice A3): legacy's removals and additions on 5.x's lists; PA7 there: in the four succubus files where legacy gives `ConHumanoidMonster`, 5.x's own silver abilities leave every list (`ConDefaultSilver`; `sq205_suc` and `mh303_suc`, 5.x's renames of legacy's quest abilities `sq205_succubus` and `qmh303_suc`, which take their place where legacy's file has them). Abilities of other features in these lists are ported with them: AI-08's combat-skill templates and `abl*` abilities, AI-14's `ablIgnoreSigns`, AI-20's fistfight tiers and `sq301_fistfighters` (which 5.x does not define).
- **Deviation:** the crowd succubi (`succubus.w2ent`, `succubus_censored.w2ent`) keep 5.x's hybrid category; legacy left them human (11) and gave only its quest succubi the hybrid category, while 5.x rebuilt these two files with the hybrid category and its own Essence ability, which `ConHumanoidMonster` now replaces. They have no health stats in 5.x at all (non-combat NPCs), so only the category's oils and bestiary entry differ (confirmed by the owner, 2026-10-28).
- **Deviation:** Regis's vampire template (`dlc/bob/data/quests/main_npcs/regis_terzieff_vampire.w2ent`) keeps 1.32's and 5.x's slot component `dettlaff_vampire_base`, which legacy renamed to `man_base` in one slot; legacy's only other change to the file, the `NPCDoNotGainBoost` removal, is ported. Taken for an editor artifact (porter's call, confirmed by the owner, 2026-11-03). In play: whatever that slot attaches to Regis's vampire form attaches as in 1.32; probably no visible difference.

**Verification (slices A1 and A3, 2026-10-28, both trees):** scripted reads (`GMTest_ai01`, `GMTest_ai06`, in the regression): the ten templates read as legacy's; spawned entities carry every added template and none removed once their level bonuses ran; the ghostly humans, dopplers and quest succubi are on Essence with `ConHumanoidMonster` and count as human; NPCs given two constitution templates keep only `ConAthletic`; the contract monsters have no `Boss`. Scripted silver hits hurt the humanoid monsters (steel deals 1), and a **real** light attack (new tree) on the Novigrad succubus dealt silver damage.

### AI-03 Monster stats

| | |
|---|---|
| Kind | tuning |
| Pillars | P1, P5 |
| 5.x class | clean |
| Flags | balance |
| Depends on | AI-01, DMG (armor before attack power), STAM-08 (the same abilities' stamina) |
| Skill trees | n/a |
| Port form | every ability `attribution.csv` gives AI-03 (404 since DIFF's slice D1) given whole (`replace`, new ones plain) from legacy's entry by `tools/gen_ai.py` into `abilities/gm_ai_monsters.xml`, the nodes other features own (`LATER`: AI-08's combat rolls, morale and attack tickets, AI-12's `hit_severity`, XP's `experience`, WGT's `weight`) legacy's too, those features being ported; the abilities STAM-08 overrode left `gm_npc_stamina.xml` whole (PA2: 15 remain there); NG+ copy by `gen_ngplus.py`; legacy's NG+-only changes (11 abilities legacy edited only in its `_plus` files) given whole in `abilities_plus/gm_ai_ngplus.xml`; `--verify` compares every ability in both folders with what the game reads |
| Port status | **signed off** (2026-10-28); ported (slice A2), verified in both trees |
| Open checks | — |
| Save impact | none (expected) |
| NG+ counterpart | applied, untested |

**What it does** (changelist 1099–1100, 1104–1105): each monster kind gets its own health, attack power, armor and resistances, so armored monsters need armor piercing and every kind plays differently; group monsters have less health, contract monsters and bosses more. Examples (base Essence; armor; notable resistances):

| Monster | 1.32 | Legacy |
|---|---|---|
| Nekker | 60 | 250 |
| Drowner | 220 | 300, will 50% |
| Endrega worker | 35; 20 | 250; 30 |
| Arachas | 10; 80; slashing 30%, force 50% | 450; 60; slashing 35%, force 80% |
| Wyvern | 500; 30 (base) | 750; 15, slashing and force 20% |
| Griffin | 500 | 1,100; 30 |
| Forktail | 500 | 900; 30 |
| Fiend | 350 (attack power −620); 40 | 1,350; 60, slashing 50%, force 100% |
| Golem | 5,550; 180 | 1,300; 200 |
| Basilisk | 4,500 | 1,350; 45 |
| Wolf | 150 Vitality, level +5 | 80, level +1, frost 30% |

Neutral `base 0` nodes were dropped; most monsters' sign and elemental resistances were raised or set. 28 abilities are new (quest and contract monsters: `mh102_arachas`, `qmh105_wyvern`, `sq204_leshy` …), 10 moved from the NPC file. Legacy fixed a vanilla tag (`CaranthirStrong` was tagged `CaranthirWeak`).

**Implementation (legacy):** 271 entries of `monster_base_abl.xml`, 52 of Hearts of Stone's, 163 of Blood and Wine's (the difficulty variants are DIFF's), 4 of the free DLC's, regular and NG+; `_Monster_*_base _Stats`.

**5.x:** 1.32's values but 16 entries (spiders' and boars' force and will resistance, `q103_werewolf`'s and Letho's attack power, `guardKnight`, `mon_EP2_followernerf`, the fiend's armor and rolls, the wolf's); two new succubus abilities; the new enemies of DA5 (Reinald, the red-plague creature) with 5.x's numbers, made for 5.x's level model.

**Decisions:** legacy's (PA1); where 5.x also changed an entry, legacy's value (PA1): 41 nodes (`GEN_AI_PA1=1 python tools/gen_ai.py --verify` lists them): the spiders', boars' and kikimoras' force and will resistance, `q103_werewolf`'s and Letho's attack power, `guardKnight`, `mon_EP2_followernerf`, the wolf's stamina values, and in AI-01's and AI-02's abilities the per-level sign resistances and `ConWitcher`. Three abilities name legacy's per-difficulty variants (`mon_q701_bruxa`, `mon_q703_arena_knights`, `mon_barghest_base`: `*_hardcore`), which 5.x defines only in its NG+ files: in a regular game the reference is empty, as legacy's variants were (DIFF ports them). Legacy also edited 11 abilities only in its NG+ files, undoing 1.32's NG+-only nerfs and boosts so that NG+ equals the regular game (PA14): `mon_wolf_ngnerf`, `q104_evilKeira`, `q503_replacer`, `q302_ReplacerThugs`, `qPhilippa_NG`, `mon_witch3_NGP`, `MonsterLevelBonusLow` and Hearts of Stone's `mon_boarNG_ep1`, `mon_spidersbank_ep1`, `mon_dogs_ep1`, `mon_trapmonsters_ep1`; they are in the NG+ folder only (`gen_ai.py`'s `plus_units`: attributed `_plus` units with no regular unit, which legacy changed and 5.x did not; untested, NG+ policy).

**Two abilities found later** (by DIFF's mapping; ported with DIFF's slice D1, 2026-10-29; porter's call to port them there, not confirmed by the owner): Blood and Wine's tougher archespore `mon_archespor_hard` (legacy: 800 Essence base; 1.32 and 5.x: +1,500 and ×2.2 Essence, −60% attack power) and the barber quest's enemy `mon_q703_mqsidqpyt` (legacy: 200 Vitality base, armor ×60; 1.32 and 5.x: +40% attack power, +150% Vitality, armor ×50) are legacy's whole like the rest (NG+ equal). The second was missed because its XML writes `name ="..."` with a space, which the tools' ability parser did not read; `gen_ench.abilities`, `gen_ai.entry` and `gen_ngplus.py` now accept it (DIFF-02's variants use the same spelling). Verified: `GMTest_ai03`'s generated table reads both as legacy's in each tree.

**Verification (slice A2, 2026-10-28, both trees):** scripted reads (`GMTest_ai03`, in the regression): all 656 abilities AI gives read in game as the port means them, the expansions' abilities given with `replace` included; the checks failed on a throwaway build without A2's XML. Spawned frozen enemies (`gmtest_ai03_spawn()`, `gmtest_ai03_read()`) have legacy's template health, armor, resistances and weapon damage, and maximum health by AI-01's formula (a golem at level 10 on Hard: 3,919.8 Essence). `gen_ai.py --verify`: no difference in the four folders.

### AI-04 Human NPC armor and allies' stats

| | |
|---|---|
| Kind | tuning |
| Pillars | P1, P5 |
| 5.x class | clean |
| Flags | balance |
| Depends on | DMG-15 (armor from equipment, signed off), DMG-12 (allies' damage) |
| Skill trees | n/a |
| Port form | the abilities `attribution.csv` gives AI-04 (24) given whole by `gen_ai.py` into `abilities/gm_ai_humans.xml` (the `LATER` nodes as AI-03), NG+ copy; DA5's two abilities in the same file |
| Port status | **signed off** (2026-10-28); ported (slice A2), verified in both trees |
| Open checks | — |
| Save impact | none (expected) |
| NG+ counterpart | applied, untested |

**What it does** (changelist 1102): humans' armor counts ("Added different resistances to human armor"): leather 8 → 30 (shock and burning 10%, fire 20%), heavy leather 20 → 45, chainmail 30 → 60, partial plate 40 → 90, full plate 50 → 120 (will, force, bleeding 20%), the Wild Hunt's armor and rear rock armor alike. Allies and quest humans retuned (`_canBeFollower`, Vesemir, Keira, Yennefer, `_q403Follower`, `MedDamage`, `q403BuffUp`, the Hearts of Stone ethereal and Olgierd's default stats, the Hakland mage and soldiers, quest humans moved to the monster file).

**Implementation (legacy):** 30 entries of `opp_base_abl.xml` and Hearts of Stone's, regular and NG+.

**5.x:** 1.32's values (human armor 8 to 50).

**Decisions:** legacy's (PA1); the allies' attack and spell power legacy's where 5.x changed them (`_canBeFollower`, Vesemir, Keira, Yennefer). Legacy's NG+-only change to followers' "Death March!" Vitality (`_combatFollowerHardcoreV` ×2.5, as in the regular game; 1.32 and 5.x NG+ ×6) is in `gm_ai_ngplus.xml` (`plus_units`, 2026-11-02; checked offline by `gen_ai.py --verify`: a regular game does not read `_plus`).

**Verification (slice A2, 2026-10-28, both trees):** the definitions (`GMTest_ai03`): NPC armor 30/45/60/90/120 with the plate's resistances; a spawned Nilfgaardian deserter in plate has 120 armor (scripted read). **Real hits** both ways with the deserter (`gmtest_swd_hit_a/b`, `gmtest_ai03_fight_a/b`) and scripted hits (`gmtest_ai03_probe`) on a golem, a drowner and Reinald matched the damage formula at every step.

### AI-05 NPC, monster and secondary weapons

| | |
|---|---|
| Kind | tuning |
| Pillars | P1, P5 |
| 5.x class | clean |
| Flags | balance |
| Depends on | DMG-08 (damage from the held item, signed off) |
| Skill trees | n/a |
| Port form | the 214 weapon abilities `attribution.csv` gives AI-05 given whole by `gen_ai.py` into `items/gm_ai_weapons.xml` (legacy's `weight` nodes since WGT's slice W2), the NG+ copy `items_plus/gm_ai_weapons.xml` from legacy's `items_plus` entries, with legacy's three NG+-only weapon changes; no item entries (legacy's item changes are scabbards, kept 5.x's, and dismantling parts, prices and weights: CRAFT's, ECON's, WGT's) |
| Port status | **signed off** (2026-10-28); ported (slice A2; Hearts of Stone's NPC torch with the AI-A audit), verified in both trees |
| Open checks | — |
| Save impact | none (expected): NPCs equip at spawn |
| NG+ counterpart | applied, untested |

**What it does** (changelist 1103: "Damage values for NPC weapons tweaked (group enemies deal less damage in general)"): human swords mostly up (Short sword 200 → 300, Skellige sword 1 230 → 320, the rusty swords 150 → 250 with silver 10–20 → 5), monster weapons retuned (arachas 35–50 → 450, cyclops 250 → 550, leshen 250 → 600, alghoul 650 → 350), crit bonuses trimmed; Hearts of Stone's NPC torch 20 → 150 bludgeoning, 3 → 5 silver; Wild Hunt weapons add frost damage (AI-15); secondary weapons (axes, maces, clubs, halberds) retuned; fists: NPC fists' silver damage, magic fists (AI-18).

**Implementation (legacy):** 80 entries of `def_item_npcweapons.xml` (the eight bows are XBOW-08's), 87 of `def_item_weapons_mon.xml`, the `NPC *`, fist, Wild Hunt and shield entries of `def_item_weapons.xml`, `def_item_weapons_secondary.xml`, the expansions' NPC and monster weapons, regular and NG+.

**5.x:** 1.32's.

**Decisions:** legacy's (PA1). Weight and price changes are listed, not ported: 21 weapon abilities carry a legacy weight change (only that in `Knight Mace 1` and `2`), WGT's; legacy's price changes sit in the item entries (ECON's, next to CRAFT-08's dismantling parts). The Wild Hunt's weapons (frost damage) and the magic fists carry legacy's data; their rules are AI-15's and AI-18's. Legacy's NG+-only weapon changes (PA14: `mon_harpy_weapon _Stats` 650 → 250 rending, `mon_ghoul_lesser_weapon _Stats` 390 → 250, `NPC_Witcher_Silver_Sword_q403_Upgrade _Stats` 100 → 400 silver, as in the regular game) are in `items_plus/gm_ai_weapons.xml` (untested, NG+ policy).
- **Deviation:** NPC swords keep 5.x's scabbards: legacy added scabbard items of its own (`NPC Scabbard 1`, `2`, `Sabre`, `Knight`, `HOS`) to the `bound_items` of NPC swords, items 5.x does not define, while 5.x gives the same swords scabbards of its own (`scabbard_nomansland_lvl2` and the like); the look only (confirmed by the owner, 2026-10-28).

**Verification (slice A2, 2026-10-28, both trees):** the definitions (`GMTest_ai03`): every weapon ability as meant, Hearts of Stone's NPC torch included (150 bludgeoning, 5 silver); spawned enemies hold legacy's weapons (scripted reads); real and scripted hits: AI-04's, and a scripted attack of a bandit with the torch (`gmtest_ai05_torch()`).

### AI-06 Enemy levels and flags

| | |
|---|---|
| Kind | content |
| Pillars | P5, P10 |
| 5.x class | clean |
| Flags | balance |
| Depends on | AI-01, LOOT (the same entity files, already patched) |
| Skill trees | n/a |
| Port form | binary edits of 5.x's entity files by `tools/gen_ai_ent.py` (with AI-02's lists and AI-07's categories and weaknesses): legacy's edits to 1.32's file (`vanilla-1.32` → `legacy-GM`) in the properties AI-A owns (any class's `level` and `isMonsterType_Group`, `CCharacterStatsParam.abilities` and `overrideInherited`, `CMonsterParam.monsterCategory`, `CCreatureDataComponent.itemsUsedAgainstCreature`) applied to 5.x's file with `cr2w_patch.py`, LOOT's edits first where LOOT patches the file; the cave nekkers' spawn set (`sq209_cave_nekkers.w2comm`, which points at the existing `sq209_cave_nekker.w2ent` instead of a generic warrior): legacy's file with 5.x's header (5.x changed only the header); the nekker warrior's and deserters' levels in AI-01's `AddLevelBonuses` (`@addMethod(CNewNPC)` `GMFixEntityLevel`, the global `GMIsAtLWGR13`, `ai/levels.ws`) |
| Port status | **signed off** (2026-10-28); ported (slice A3), verified in both trees |
| Open checks | the deserters at No Man's Land's encounter gr13 (level 7): only reachable by travelling there |
| Save impact | none for enemies not yet spawned; an NPC the save holds keeps its saved level and maximum health until its bonuses are recomputed (AI-01's save impact) |
| NG+ counterpart | none (entity files have no NG+ copy; NG+ adds its level in code) |

**What it does:** about 285 enemies change level, most by +1 to +5, quest NPCs who should scale like real enemies a lot more (2 → 27, 0 → 30), a few down (−1 to −35); 35 set a level where they had none. Flags: `NPCDoNotGainBoost` and `NoAdaptBalance` added to rats and mice (no level bonus) and removed from 23 others (the vampires, Olgierd, Eredin, Imlerith, Canaris, Lugos's crew and others now level), `NewGamePlusFakeLevel` and `NPCDoNotGainNGPlusLevel` removed with the fake levels (inert in the port: AI-01's NG+ code reads neither), the group flag on the Goldilocks wolf and off on the `mh210` lamia. Code: the nekker warrior of a free DLC's quest (`dlc7`, `sq107`, spawned with the tag `sq107_monster_heavy` from `nekker_lvl3__warrior.w2ent`) forced to level 8, three deserter templates at one encounter (`IsAtLWGR13`) to level 7.

**Implementation (legacy):** 284 entity files (W3Edit re-saves); `CNewNPC.AddLevelBonuses`, `IsAtLWGR13`.

**5.x:** 1.32's levels (no level differs in the entity folders, `bindiff.py vanilla-1.32 vanilla-5.x`).

**Decisions:** legacy's levels and flags as binary edits (PA8). Legacy changed `levelFakeAddon` in 71 of these files, each time making a fake level real (the addon 0 or gone, the level raised: the sergeant 0 + 11 → 11 + 0, Blood and Wine's quest fighters, guards and thugs, Olgierd's men, the Novigrad and Skellige fistfighters, the `q201` stuffed animals 2 + 70 → 16); the addon goes with the level (`gen_ai_ent.py`'s `PROPS`), so the HUD, which adds the addon (UI-12), shows legacy's level (the sergeant 11 in red, seen on screen in both trees; 5.x's addon with legacy's level showed 22); in all 71 files, not only the sergeant's (confirmed by the owner, 2026-10-29). The fake levels as such stay DIFF's (DA2), with `mq1028_gerd`'s addon 1 → 0 (no level change; not an AI file). Legacy's W3Edit re-saves sometimes changed a level in only one of a file's two copies (the template's entity object or its compiled copy, `flatCompiledData`: Lugos 17 in the one, the `sq201` werewolf 17 and `sq106_elven_scum` 16 in the other); the port sets both. `GMIsAtLWGR13` reads 5.x's area names (CNames, `'AN_NMLandNovigrad'`; 1.32's were enum values).
- **Deviation:** legacy's two console spawn aliases (`gameplay.xml`'s `succubus_mh` and Hearts of Stone's `golem37`) are not ported: debug shortcuts with no play effect; tests spawn by path (confirmed by the owner, 2026-10-28).
- **Deviation:** six enemy files keep 1.32's empty runtime ability list (the `CCharacterStats` object): Olgierd (`olgierd.w2ent`), the Ofir mage (`q601_ofir_mage`), the Skellige herbarium werewolf (`sq201_herbarium_warewolf`) and three Hearts of Stone boars (`wild_boar_ep1`, `boar_34_normal`, `q603_boar`). Legacy's files carry a filled list (Olgierd's 15 entries: `EtherealActive`, `EtherealSkill_1` to `5`, `difficulty_CommonHardcore`, `all_NPC_ability` and others; the Ofir mage's runtime `currentLevel` 32), which looks like W3Edit's snapshot of a spawned NPC rather than an edit: taken for an editor artifact (porter's call, confirmed by the owner, 2026-11-03). Their levels and `CCharacterStatsParam` abilities, legacy's real edits, are ported. In play: these enemies get their abilities from their templates and the chosen mode, as in 1.32; if legacy's game did use the list, legacy's Olgierd fought with the "Death March!" ability (and his ethereal skills from the start) on every mode, and the port's does not.

**Verification (slice A3, 2026-10-28, both trees):** `gen_ai_ent.py --verify`: each edited file is 5.x's (with LOOT's edits) plus exactly the derived edits, CRCs valid, every changed value legacy's. In game (`GMTest_ai06` and `GMTest_ai06_after`, in the regression; scripted reads of 15 spawned samples from `tests/gmTestsAiEntData.ws`, which the generator writes): the levels, categories, abilities and weakness lists the files give; rats without level abilities; the `sq107` nekker warrior at 8 with its tag and 12 without; `GMIsAtLWGR13` false away from gr13 (a negative check only). The checks failed on a throwaway build with 5.x's entity files.

### AI-07 Monster categories and weaknesses

| | |
|---|---|
| Kind | content, fix |
| Pillars | P5, P8 |
| 5.x class | clean |
| Flags | — |
| Depends on | ALCH-16 (oils by category), UI-11 (the journals) |
| Skill trees | n/a |
| Port form | binary edits (`CMonsterParam.monsterCategory`, `CCreatureDataComponent.itemsUsedAgainstCreature`) by `tools/gen_ai_ent.py` (AI-06's); `@wrapMethod(CActor)` `IsHuman` (`ai/categories.ws`) |
| Port status | **signed off** (2026-10-28); ported (slice A3), verified in both trees |
| Open checks | — |
| Save impact | none (expected) |
| NG+ counterpart | none |

**What it does:** the category decides which oils, bombs and bestiary entry work on an enemy. Spiders specter → insectoid (13; "Spiders fix"), ghostly humans human → specter (13; `q602_everc_*`, `q604_ethereal`, the preacher's ghost), dopplers → relic, succubi → hybrid, `sq209`'s visions → specter; ethereal and `ConHumanoidMonster` enemies still count as human for human rules (finishers, dismemberment, human resistances). The creatures' own weakness lists (12 files: necrophage → insectoid oil for spiders, the Silver Dust bomb for leshens, Axii and Yrden for the djinn), which the bestiary journals mirror (UI-11).

**Implementation (legacy):** 36 entity files (categories), 12 (weaknesses); `CActor.IsHuman`.

**5.x:** 1.32's categories in most of these files, but the spiders (5.x's Hearts of Stone and Blood and Wine spiders are insectoids already) and the succubi (hybrids, AI-02).

**Decisions:** legacy's (PA8): 19 categories and 27 weakness lists edited; where 5.x already has legacy's category, nothing to do. The crowd succubi's category: AI-02's deviation. `IsHuman` gives legacy's answer, re-evaluated per call instead of cached, so a template added later counts.

**Verification (slice A3, 2026-10-28, both trees):** categories and weakness lists of the spawned samples (`GMTest_ai06`, scripted reads), humanoid monsters counted human. **Real oil applications** (`ApplyOil`, the inventory's path; the hit's attack power read by script): insectoid oil +25% on the Blood and Wine spider, necrophage oil (its old weakness) +0; specter oil +25% on a Hearts of Stone ghost; hybrid oil on the quest succubi and relic oil on the doppler +25%.

## AI-B Enemy behaviour

### AI-08 Combat parameters

| | |
|---|---|
| Kind | tuning |
| Pillars | P2, P5 |
| 5.x class | overlap |
| Flags | balance |
| Depends on | STAM-08 (the rolls are followed by a stamina check), DEF-06 |
| Skill trees | n/a (checks in both trees) |
| Port form | the AI-08 nodes of the abilities AI gives whole (AI-01 to AI-05's, `gen_ai.py`: AI-08 in `PORTED`); the 33 AI-08 abilities nothing else gives whole in `abilities/gm_ai_combat.xml` (`gen_ai.py`'s `PART`: 5.x's entry, `replace`, with legacy's nodes of the AI-08 and STAM-08 tags legacy changed, and of the AI-08 tags where legacy kept 1.32's value and 5.x changed it; they leave `gm_npc_stamina.xml`, PA2); the combat-skill templates and `abl*` abilities in seven entity lists (`gen_ai_ent.py`: AI-08 in `PORTED`); NG+ copy by `gen_ngplus.py` |
| Port status | **signed off** (2026-10-28); ported (slice B1), verified in both trees |
| Open checks | the teleport and dash chances legacy changed (Blood and Wine's barghests, kikimores, sprigans, lessogs, the fairytale witch: none fought); wolves on uneven ground circled 8 to 13 m away and rarely attacked (not compared with 5.x); New Game+ (untested, as every NG+ change) |
| Save impact | none (expected) |
| NG+ counterpart | applied, untested; 5.x's NG+ ×1.15 kept (PA14) |

**What it does** (changelist 1114: "AI combat parameters were tweaked to make them react better to player actions"; 1116): the behaviour trees' rolls are retuned per enemy and template: dodge chances evened out (light attacks mostly 20%, 40–60% for nimble monsters; bears and endregas 95% → 20%), counters on most monsters (20–60%, golems 100% → 80%), counters and guards rolled from the first hit (`hits_to_roll_counter`, `hits_to_raise_guard` 2–3 → 0) and rising per hit (+10%), humans' guard and counter 70% → 30%, taunts 25% → 10%, teleport and dash chances, `hit_severity` zeroed (AI-12).

**Implementation (legacy):** about 140 abilities (`mon_*_base`, the `Skill*` human templates, the Wild Hunt's), regular and NG+.

**5.x:** about 13 monster combat trees reworked (see the area's introduction); the human trees unchanged. 5.x's own XML changes to the rolls are only `mon_bies_base` (dodge 15% → 35%, counter 15% → 30%, after 1 hit) and `mon_wolf_base` (dodge 20/40% → 40/50–60%), both of which legacy sets; the human templates' waits randomised (2–4 hits) and counter chance 50–75%; dodge and counter ×1.15 in NG+. Legacy's chances still reach the reworked moves (the fiend's new dodge, the wolves' circular dodge and counters, the wyverns' counters, the cyclops's counter-taunt); some moves bypass them: the gryphon family's instant dodges within 3 m and its charge out of a block, the arachas's 15% shell roll, the ghoul's hop away, the wolves' hit reactions, the attacker limits by difficulty.

**Who reads the rolls** (5.x's 389 behaviour trees, read with `tools/unbundle.py`; unverified beyond the fights below): the dodge chances (`dodge_*_chance`) are read only by the dodge tasks (`CBTTaskDodge`, `CBTTaskCircularDodge`), which 29 trees use: the human sword and axe trees, the drowner, ghoul, grave hag, gryphon family, harpy, katakan, noonwraith, pesta, siren, werewolf, witch, wraith and fiend trees, the nekker, wolf and barghest trees (circular dodge), and Blood and Wine's big bad wolf, bruxa, fairytale witch, fleder, gravier, sharley and wight. The bear's, golem's, troll's, arachas's, wyvern's, ice giant's and djinn's trees have no dodge task, so their dodge chances are inert data (in 1.32 too: the trees are 1.32's); legacy's bear 95% → 20% changes nothing in play. The gryphon family's tree (griffins, basilisks, cockatrices) has a dodge task but sets `ignoreDodgeChanceStats`, so every roll says yes and its dodge chances are inert too (seen in both trees; few of its rolls start a dodge). Guard and counter chances are rolled by the hit reaction (`CBTTaskHitReactionDecorator`, the monsters' base combat tree), the additive hit (`BTTaskAdditiveHitListener`, 29 trees: bear, golem, fiend, wyvern, ...), the parry task (`CBTTaskPerformParry`, humans) and the dodge task's counter; a monster's guard or counter is rolled only on a hit that plays a (additive) hit reaction (hits below 1 damage play none, DMG-01). The taunt chance is read by the taunt task (46 trees), which no tree sets to roll it in 5.x (AI-10).

**Decisions:** DA3 (a) (project owner, 2026-10-28): legacy's dodge, counter, guard and taunt chances on every enemy, including the monsters 5.x reworked. Legacy changed teleport and dash chances only on Blood and Wine monsters; the base game's equal 1.32's. `PART` also takes legacy's node for an AI-08 tag where legacy kept 1.32's value and 5.x changed it, as the abilities AI gives whole do (PA1): `SkillShield`'s counter chance is legacy's 0.4 (5.x 0.3 to 0.5; `GMTest_ai08` reads it).

**Note for the balance pass** (2026-10-28; not a deviation; confirmed by the owner, 2026-10-28): bears, endregas and golems (and the other monsters whose trees have no dodge task: trolls, arachases, wyverns, ice giants, the djinn; and griffins, basilisks and cockatrices, whose tree ignores the chances) carry legacy's dodge chances as data, but nothing reads them, so they have no effect in play, as in 1.32 and legacy. Whether those numbers should drive anything is for the balance pass; until then they stay legacy's, inert (confirmed by the owner, 2026-10-28).

**Verification (slice B1, 2026-10-28, both trees):** the data: `gen_ai.py --verify`, `gen_ai_ent.py --verify`, and in game `GMTest_ai03`'s generated table and `GMTest_ai08` (regression, scripted reads); STAM-08's stamina values in the abilities that moved from `gm_npc_stamina.xml` unchanged. **Real fights** (`gmtest_ai08_fight_a/_b`: real light attacks through the input handler, probes logging every roll the enemy's AI makes with its chance) against a bandit and a wolf (both trees), a fiend, a golem and a bear (classic tree): every roll read legacy's chance (dodges at 20%, guards and counters from the first hit rising 10% a hit, the golem's taunt at 10%), and the bear rolled no dodge (its tree has no dodge task).

### AI-09 Dodging

| | |
|---|---|
| Kind | system |
| Pillars | P5 |
| 5.x class | clean |
| Flags | — |
| Depends on | DEF-06 (the counter guards, ported), AI-08 |
| Skill trees | n/a |
| Port form | `ai/dodge.ws`: a `CBTTaskDodgeDef` scope-based default (`maxDistanceFromTarget` 3); `@replaceMethod(CBTTaskDodge)` `IsAvailable` and `Dodge` (the 0.25 s wait; `Dodge` without the delay and attacking checks), `OnDeactivate` (no next-dodge time), `OnListenedGameplayEvent` (no overlap); the global `GMEnemyNotGrounded` (in the air or off the ground), checked in DEF-06's `GMEnemyCannotDodge` (`defense/enemyDefense.ws`), so all six of DEF-06's dodge wrappers apply it as legacy's guard lines do; `@replaceMethod(CBTTaskReaction)` `Main` (dodge on a yes) with `@wrapMethod` `ChooseAndCheckDodge` (DEF-06's stun guard, DEF audit F12) |
| Port status | **signed off** (2026-10-28); ported (slice B1), verified in both trees |
| Open checks | the reaction task's fix: no 5.x behaviour tree uses `CBTTaskReaction` (the 389 trees read, 2026-10-28), so the fix and its guard are inert until a tree does; the 0.25 s window and the missing delay are not timed separately (dodges were seen, not their timing) |
| Save impact | none |
| NG+ counterpart | none |

**What it does** (changelist 1116: "AI should be better at dodging"): an enemy has 0.25 s (0.1) after an incoming attack's dodge signal to start its dodge, with no minimum delay between dodges, also out of its own attack, without overlapping dodges, and only within 3 m of its target (5 m); never in the air or off the ground. `CBTTaskReaction.Main` dodged when `ChooseAndCheckDodge` said no (a vanilla bug in 1.32 and 5.x): fixed, with DEF-06's stun guard on that check (the DEF audit's F12 left both for AI). The NPC dodge's minimum distance (1.7 m) is vanilla's, unchanged.

**Implementation (legacy):** `CBTTaskDodge` (`<members>`, `IsAvailable`, `OnActivate`, `OnDeactivate`, `Dodge`, `ChooseAndCheckDodge`, `OnListenedGameplayEvent`), `CBTTaskDodgeDef`, `CBTTaskCircularDodge.ChooseAndCheckDodge`, `CBTTaskReaction` (`Main`, `ChooseAndCheckDodge`, `OnGameplayEvent`).

**5.x:** 1.32's task with an instant dodge option (`instantActivation`) and the NG+ multiplier. One tree sets `allowDodgeOverlap` (default true), three `allowDodgeWhileAttacking` (the bruxa, the fiend, the gryphon), three `minDelayBetweenDodges`, 18 `maxDistanceFromTarget` (those keep their own distance; the others take the new default).

**Decisions:** legacy's; 5.x's instant dodge (`instantActivation`, used by no tree) and NG+ ×1.15 kept (PA14). DEF-06's dodge wrappers run before AI-09's replacements, so the air guard also covers the `instantActivation` path.

**Verification (slice B1, 2026-10-28, both trees):** the default distance 3 (`GMTest_ai08`, regression). In the real bandit fight (classic tree) the dodge task rolled while the bandit was attacking (5.x refuses before the roll) and once started a dodge from its attack. A hostile harpy in the air read `GMEnemyCannotDodge` true (`gmtest_ai09_air`, scripted reads, classic tree), horses on the ground false.

### AI-10 Guarding, parrying and taunts

| | |
|---|---|
| Kind | system, tuning |
| Pillars | P5 |
| 5.x class | clean |
| Flags | — |
| Depends on | STAM-08 (guard and parry stamina, ported) |
| Skill trees | n/a |
| Port form | `ai/defence.ws`: `@replaceMethod(CActor)` `IncHitCounter`, `IncDefendCounter`; `@replaceMethod(CBTTaskDefend)` `OnGameplayEvent`, `OnDeactivate`; `@replaceMethod(CBTTaskTaunt)` `IsAvailable` (5.x's `mq1060_pv_boss` line kept); scope-based defaults of `CBTTaskTauntDef` (`useXMLTauntChance`) and `CAIMonsterTauntParams` (5 s, 10 s); `@replaceMethod(CNewNPC)` `ProcessShieldDestruction` |
| Port status | **signed off** (2026-10-28); ported (slice B1), verified in both trees |
| Open checks | the defend task ending on the blocked hit and the 2 s protection of the counter (golems, drowners, ghouls use it; not isolated in the fights); the monster taunt timing in a fight (only the defaults read) |
| Save impact | none |
| NG+ counterpart | none |

**What it does:** hits and blocks count towards an enemy's guard and counter for 2.5 s (2 s); the defend pose ends on the hit it blocked and keeps the enemy's counter from being interrupted (no hit animation for 2 s); a broken shield lowers the guard and does not stagger its holder; the taunt always rolls the enemy's XML chance (which changes little in play: the roll repeats every tick); monsters taunt every 5 s (3) and force an attack after 10 s (20).

**Implementation (legacy):** `CActor.IncHitCounter`, `IncDefendCounter`; `CBTTaskDefend.OnGameplayEvent`, `OnDeactivate`; `CBTTaskTaunt.IsAvailable`, `CBTTaskTauntDef`; `CAIMonsterTauntParams`; `CNewNPC.ProcessShieldDestruction`.

**5.x:** 1.32's, plus a parry sound on blocked damage and a quest boss that never taunts (`mq1060_pv_boss`). No tree sets `useXMLTauntChance`, so in 5.x the taunt task never rolls: every enemy taunts whenever its delay allows. With legacy's rule the task rolls the enemy's `taunt_chance` (AI-08's values: 10–25% for most; wolves 100%) at each check after the delay, but it re-rolls every tick, so a 10% chance passes within a moment: in play taunts come about as often as in 5.x (a noonwraith fought on both). The timing comes from the delays (5 s, 10 s) and the tree, not the chance.

**Decisions:** legacy's; 5.x's `mq1060` taunt line kept (5.x's new content).

**Verification (slice B1 and the AI-B audit, 2026-10-28, both trees):** the defaults (`GMTest_ai08`); the hit and defend counters' 2.5 s window and a broken shield without stagger and with the guard down (`GMTest_ai10`, `GMTest_ai10_after`, scripted; the shield also in a real fight, `gmtest_ai10_shield`); taunts rolled at 10% in the real golem fight. The checks failed on a throwaway build with 5.x's code.

### AI-11 Targeting

| | |
|---|---|
| Kind | tuning |
| Pillars | P5 |
| 5.x class | clean |
| Flags | balance |
| Depends on | SKL-12 (Puppet, signed off) |
| Skill trees | both: Puppet (classic `magic_s5`, new `magic_s31`) is what the change serves; checks in both trees |
| Port form | scope-based defaults of `CAIBaseMonsterCombatParams` (abstract; every monster combat parameter class derives from it) and `CAINpcCombatParams`, in `ai/targeting.ws` |
| Port status | **signed off** (2026-10-28); ported (slice B2), verified in both trees |
| Open checks | a real Axii Puppet cast (the fights used Axii's puppet effect added by script, with the real AI on both sides); NPCs the save itself holds (the fights spawned theirs) |
| Save impact | none: the weights are class defaults, read by the native target selection from each NPC's parameter object (entities store only values that differ from the defaults; 8 of 5.x's entity files set `playerWeight` themselves and keep theirs, as in legacy: Blood and Wine's garkains, the `q701` bruxa, the `q704` monster-hunt vampire, a `q206` berserker) |
| NG+ counterpart | none |

**What it does** (changelist 1117–1118): enemies attack whoever hurts them first and no longer single out Geralt: hitter weight 20 → 30, current target 9 → 20, player 1,000 (monsters) or 100 (NPCs) → 15, monsters for NPCs 101 → 25. A puppet draws its victims' attacks.

**Implementation (legacy):** `CAIBaseMonsterCombatParams.<members>`, `CAINpcCombatParams.<members>`.

**5.x:** 1.32's weights. The target selection is native; it adds the weights to a distance term (`distanceWeight` 30 over `maxWeightedDistance` 30) and the hostile-actor weight (10), so with legacy's weights a nearer enemy or one that hits wins over Geralt, while 5.x's 1,000 or 100 for the player nearly always wins.

**Decisions:** legacy's. Animals' quest and riders' combat parameters keep 5.x's weights, as in legacy (the defaults sit on the two base classes only).

**Verification (slice B2, 2026-10-28, both trees):** the weights (`GMTest_ai11`, regression, scripted reads). **Real fights** (`gmtest_ai11_a/_b`: enemy and ally run by their own AI, Geralt idle and away, the enemy's target sampled every 0.5 s), against a throwaway build with 5.x's weights: a bandit turned on a puppet (Axii's effect added by script) beside it and stayed on it (41 of 42 samples; 5.x's weights 9 of 42); a wolf turned on a friendly deserter after its hits (5.x's: never). An enemy that had reached Geralt before the puppet's first hit stayed on him: whoever is nearer or hits draws the attacks, as legacy's numbers say.

### AI-12 Poise

| | |
|---|---|
| Kind | system |
| Pillars | P5 |
| 5.x class | clean |
| Flags | balance |
| Depends on | DMG-01 (the damage half of the same function, ported) |
| Skill trees | n/a (every hit) |
| Port form | `ai/poise.ws`: the global `GMModifyHitSeverityFromDamage` (legacy's hit-severity half) with `GMModifySeverity` (legacy's `ModifySeverity`), called at the end of DMG-01's `GMZeroSubOneDamage` (`damage/pipeline.ws`) for the hits it leaves alone; `@replaceMethod` of the global `ModifyHitSeverityReaction` (returns the reaction unchanged); `@replaceMethod(CActor)` `IsHuge`; `@addMethod(CActor)` `GMGetCapsuleHeight`; `gen_ai.py`'s `PORTED` gains AI-12 (legacy's `hit_severity` 0 in the abilities AI gives whole, `PART` included) |
| Port status | **signed off** (2026-10-28); ported (slice B2), verified in both trees |
| Open checks | ranged hits (bolts, signs) on a huge enemy in a fight (the fights used melee; other hits are covered by the regression's crafted hits); a real elemental (a spawned frozen one read the flying stance, which exempts it) |
| Save impact | none |
| NG+ counterpart | none |

**What it does** (changelist 1095–1097): "the bigger they are, the less severe their hit reaction is". Melee hits on enemies up to 2 m tall are left to parries and counters; any other hit (not parried, countered, dodged or damage over time) loses one step of hit reaction (heavy → light → none) when it takes less than 3% of the victim's health and two below 1%, the thresholds scaled up by the victim's height over 2 m; golems never react to hits; flyers are exempt. The unused `hit_severity` stat is no longer read. "Huge" (`IsHuge`, which other rules read) means a capsule taller than 2 m instead of the `mon_type_huge` ability.

**Implementation (legacy):** `ModifyHitSeverityReactionFromDamage` (its second half), `ModifyHitSeverityReaction`, `ModifySeverity`, `CActor.IsHuge`, `CActor.GetCapsuleHeight` (STAM-06).

**5.x:** 1.32's. No 5.x ability sets `hit_severity` (legacy adds it, at 0, to the 17 human combat-skill templates and the Wild Hunt's three generals), so 5.x's `ModifyHitSeverityReaction` never changes a reaction either; replacing it changes nothing in play. **Movement capsules** (read in game, 2026-10-28): humans, bears, harpies, cave and ice trolls, werewolves 1.8 m, griffins 1.5 m; wyverns 2.1, horses 2.35, leshens 2.7, golems and earth elementals 3.1, fiends 4, cyclopes and ice giants 5. So under legacy's rule trolls, werewolves and griffins are no longer "huge" (5.x's `mon_type_huge` makes them so) and fiends, leshens, wyverns, golems and horses are; `IsHuge` is read by Mutation 4's reach and by Retribution (ENCH); Aard's knockdown severity still reads `mon_type_huge` (SKL-08), as legacy's does. Elementals carry `mon_golem_base`, so they never react to hits either.

**Decisions:** legacy's. "Huge" follows legacy's capsule rule (taller than 2 m), with its effect on Mutation 4's reach and Retribution (confirmed by the owner, 2026-10-28).

**Golems never guard or counter** (legacy's code, not a deviation; confirmed by the owner, 2026-10-28): golems never react to hits, and the monsters' additive-hit listener rolls guard and counter only on a hit that plays a reaction (AI-08), so in a real golem fight on the port no guard or counter roll came. Legacy's code combines the same two rules, so its golems presumably did the same ([legacy test](../open-questions.md#to-test-in-legacy-ghost-mode)); AI-08's golem guard and counter numbers are inert, a point for the balance pass.

**Verification (slice B2, 2026-10-28, both trees):** `GMTest_ai11_after` (`gmtest_panel()`, crafted hits through `GMZeroSubOneDamage` on spawned frozen NPCs): a bandit keeps its melee reactions, non-melee hits lose steps by the share of health they take, a fiend's thresholds scale with its 4 m, a golem never reacts; `IsHuge` follows the capsule. **Real fights** (`gmtest_ai11_poise`, real light attacks): a bandit's reactions unchanged, every hit on a fiend and a golem lowered to none; on a throwaway build with 5.x's rules the golem's hits kept their reaction.

### AI-13 Flyers forced to land

| | |
|---|---|
| Kind | system |
| Pillars | P5, P9 |
| 5.x class | clean |
| Flags | — |
| Depends on | XBOW-01 (bolts), SKL-10 (Yrden), EFX (burning) |
| Skill trees | both: Yrden's shock (classic `magic_s3` shared, new tree's Yrden) and Igni's burning bring flyers down; checks in both trees |
| Port form | `ai/flyers.ws`: `@replaceMethod(CNewNPC)` `ReactToBeingHit`, 5.x's body (its targeted-part hit reaction and bomb signal kept) with legacy's rule in the global `GMFlyerForcedToLand`; the Puppet's freeing by Geralt's hits removed there as legacy did (SKL-12's rule frees it on his damaging hits) |
| Port status | **signed off** (2026-10-28); ported (slice B2), verified in both trees |
| Open checks | a wyvern, griffin or siren (only harpies fought); the stronger lamia (`mon_lamia_stronger`, 5.x's 50% threshold) in play |
| Save impact | none |
| NG+ counterpart | none |

**What it does:** a flying enemy is knocked out of the air (knockdown applicator, also when the hit deals no damage) by any damaging hit that is not damage over time, by any bolt, by Yrden's shock and by burning; 1.32 needed a hit taking a set share of its health.

**Implementation (legacy):** `CNewNPC.ReactToBeingHit`.

**5.x:** 1.32's rule: a plain knockdown when a hit takes at least `healthLossToForceLand_perc` of the flyer's health, unless an effect deals it. That share is 0 for harpies, sirens, lamias, griffins, wyverns and Blood and Wine's draconids (50% only for `mon_lamia_stronger`, which legacy sets to 0), so in 5.x any hit but an effect's tick brings them down, also one without damage, while burning never does. The hit reaction aims at a targeted part's bone (`SetHitReaction`), bombs signal `BombHit`. The Yrden trap's grounding of flyers inside it (`BlockAbility('Flying')`) is 5.x's and unchanged.

**Decisions:** legacy's. The change in play: burning brings a flyer down; a hit without damage that is not a bolt or Yrden's shock no longer does; the knockdown goes through the applicator (SKL-08's `GMModifyKnockdownSeverity` makes it a heavy knockdown for a flyer). A regular Igni's own hit adds the applicator, but a regular Igni's effects pass only at its burn chance (`GetSignApplyBuffTest`, SKL-09, as legacy), so it grounds a flyer mostly through the burning it sets; Firestream's ticks are damage over time and do not count, its burning does. 5.x's `ReactToBeingHit` has a dangling `if` that limits the zero-stamina perk to Rend; kept unchanged (5.x's).

**Verification (slice B2, 2026-10-28, both trees):** `GMTest_ai11_after` (`gmtest_panel()`, scripted, a spawned harpy set to flying): a small hit and a burning tick add the knockdown applicator, a bleeding tick and a hit without damage nothing. **Real fights** (`gmtest_ai13_a/_b`, a hostile harpy): Geralt's sword, a bolt, Yrden's turret shock and burning brought it down in both trees; a regular Igni's hit added the applicator without a knockdown (its burn-chance test); Firestream's ticks did not count, the burning it set did. On a throwaway build with 5.x's rules burning never grounded it and the B2 checks failed.

### AI-14 Monster fixes

| | |
|---|---|
| Kind | fix |
| Pillars | P5, P8 |
| 5.x class | clean |
| Flags | — |
| Depends on | AI-01 (where legacy put the cyclops and arachas lines) |
| Skill trees | both: Axii on a cyclops, Yrden on a toad; checks in both trees |
| Port form | `ai/monsters.ws`: `@addMethod(CNewNPC)` `GMMonsterFixes` (legacy's cyclops and arachas lines, called from AI-01's replaced `AddLevelBonuses` in `ai/levels.ws` where legacy has them; `@addField` `gmArachasSpeedId`, `gmArachasSpeedSet`: legacy's `animSpeedMult`, one speed causer across recomputes, set through `@addMethod(CActor)` `GMSetAnimSpeedCauser`, which never gives a causer id 0 (SKL-10's Yrden slowdown uses it too)); `@replaceMethod(CBTTaskToadYrden)` `Main`; `@replaceMethod(CBTTaskCastQuen)` `ProcessAction` calling the global `GMNpcQuenStagger`; entity edits by `tools/gen_ai_ent.py` (`PORTED` gains AI-14; `PROPS_LATER`): `ablIgnoreSigns` off the two Goldilocks bears, `CAIMonsterCombatParams.reachabilityTolerance` (5.x's 4) removed from the two quest fiends `mq4005_czart` and `q402_fiend`, `CAINpcWindMageCombatParams.increaseHitCounterOnlyOnMelee` (5.x's false) removed from the Hakland mage `q601_ofir_mage`; the golems', earth elementals' and Ifryts' `wide_arc` attack range (`CConeAttackRange.rangeMax`) in the 22 entity files legacy edited (`FILE_SCOPED`: only in the files whose attribution note names `wide_arc`); the fiend's tree stays 5.x's (PA9) |
| Port status | **signed off** (2026-10-28); ported (slice B3; the causer fix with the AI-B audit; the slam range 2026-11-02), verified in both trees |
| Open checks | real hits raising the toad's hit counter inside Yrden (a 2.5 m toad's light hits are lowered by AI-12's poise and Geralt's level-1 hits dealt 0, so the counter was raised by script); the quest fiends' reachability and the Hakland mage's hit counter in their own fights (quest places; the edits checked by `gen_ai_ent.py --verify` only); whether 5.x's reworked golem and elemental trees use the `wide_arc` range for the slam in a fight |
| Save impact | none (the entity edits are read at spawn) |
| NG+ counterpart | none |

**What it does:** cyclopes lose `ablIgnoreSigns`, so Axii's confusion and the other signs' critical states take on them (changelist 1120); arachases move at 75% animation speed (an omission); the Hearts of Stone toad stays in Yrden's trap until it leaves it or the trap's hold ends (5.x: also on a third hit that plays a hit reaction); an NPC's Quen staggers its melee attacker with the stagger's default length (1.32 and 5.x: 0.1 s); the Goldilocks bears no longer ignore signs; the two quest fiends of Kaer Morhen's `mq4005` and `q402` take the default reachability tolerance (2 m; 5.x 4 m); the Hakland mage's hit counter rises only on melee hits; the fiend's (and chort's) tree gains a close-range melee branch (bugfix 77; in 5.x already, PA9); the sorceress's hand effect stops after combat (a community fix, in 5.x already); the three smiths become commoners (see the deviation). The all-round slam of every golem, earth elemental (Dao) and Ifryt reaches 3 m (changelist 136; 5.x: 2 m for the Daos, 4 m for the others; the owner's decision, 2026-11-02).

**Implementation (legacy):** `CNewNPC.AddLevelBonuses`, `<members>`, `OnCombatModeSet`; `CBTTaskToadYrden.Main`, `CBTTaskCastQuen.ProcessAction`; `monster_bies_logic.w2behtree`; AI tree properties in 6 entity files (the smiths, the quest fiends, the Hakland mage), `ablIgnoreSigns` in the Goldilocks bears' lists.

**5.x:** 1.32's lines; the sorceress fix is in. The fiend's tree (`monster_bies_logic.w2behtree`) is 5.x's own (from the game files, unverified in game): it adds legacy's close-range melee branch itself (three attacks within 4 m, the same values), and also a new dodge that rolls the ability's chances, a hypnosis wind-up of 3 s up to Medium and 1.5 s on Hard and above, and changed charge distances. 5.x's smith files (`fergus_graem`, `master_blacksmith`, `prologue_smith`) are rebuilt by CDPR (appearances, included templates).

**Decisions:** legacy's. The fiend's branch (bugfix 77) needs no port: 5.x's tree has it, so 5.x's tree is kept (PA9's outcome, 2026-10-28; confirmed by the owner, 2026-10-28). Legacy's arachas line passes its previous speed causer to replace it; the port does the same (a recompute leaves one causer). The causer never takes id 0 (`GMSetAnimSpeedCauser`): `SetAnimationSpeedMultiplier`'s optional id defaults to 0, so every caller that leaves it out (Yrden's slowdown effect, 5.x's frost slowdown, Blizzard) overwrote the arachas's causer 0 and removed it when it ended, and the arachas moved at 1.0 for the rest of the fight. Now a slow on an arachas applies as the most recent causer (the last one wins: inside Yrden it moves at Yrden's value, 0.75 to 0.84 in a level-1 trap, not below it) and after it ends the arachas is back at 0.75. The quest fiends' and the mage's edits remove a property, so the class default applies, as in legacy's files. 5.x's own id-less callers (Blizzard's slowdown, the frost slowdown, the slowdown's decay) still collide with each other on an enemy's causer 0 (5.x's behaviour, unchanged). The slam range: an included base's copy stays 5.x's (object by object); outside the 22 files W3Edit's re-save drops, adds and renumbers attack-range objects with no AI change.
- **Owner decision** (project owner, 2026-10-28): inside Yrden or frost an arachas moves at the slow's value, as the port does (the last causer wins; presumably as in legacy), not at the product of both (0.75 × the slow's).
- **Deviation:** AI-14's arachas speed and SKL-10's Yrden slowdown never take animation-speed causer id 0 (`GMSetAnimSpeedCauser`), so a slowdown that leaves the id out no longer overwrites and removes the arachas's 0.75: legacy's same lines on the same vanilla code presumably lost it after the first slow ([legacy test](../open-questions.md#to-test-in-legacy-ghost-mode)); a fix of a bug, not a rule change (confirmed by the owner, 2026-10-28).
- **Deviation:** the three smiths (Fergus Graem, the Novigrad master blacksmith, the White Orchard smith) stay 5.x's quest NPCs: legacy's files are rebuilt from commoner templates (a commoner AI preset: group type `ENGT_Commoner`, scared combat, commoner reaction and soft-reaction trees, the `Commoner` ability, no `IsNotScaredOfMonsters` or `DisableFinishers`; the White Orchard smith also in the `civilians` attitude group), new objects and imports that `cr2w_patch.py` cannot write as edits of 5.x's files, which CDPR rebuilt too; the changelist does not mention it, and a commoner has no ability or effect manager in 5.x's code (confirmed by the owner, 2026-10-28).
- **Deviation:** the two quest fiends (`mq4005_czart`, `q402_fiend`) keep their obstacle probe (a phantom component that stops a charge at obstacles, with its attachment), which legacy's files lack: removing a component is beyond `cr2w_patch.py`, and the fiend's charge behaviour is 5.x's reworked tree's (confirmed by the owner, 2026-10-28).
- **Deviation:** Ekimma (`sq106_ekimma`) and the Skellige herbarium werewolf (`sq201_herbarium_warewolf`) keep their obstacle probe too (Ekimma also its grass collider), which legacy's files lack, as for the two quest fiends above; generic fiends kept theirs in legacy, so it is taken for a re-save artifact (porter's call, confirmed by the owner, 2026-11-03). In play: their charges stop at walls and obstacles, as in 1.32 (the probe raises `CollisionWithObstacleProbe`, which ends a charge); in legacy these two, like the two fiends, presumably charged through obstacles.

**Verification (slice B3 and the AI-B audit, 2026-10-28, both trees):** the regression (`GMTest_ai14`, `GMTest_ai14_after`, scripted): a cyclops loses `ablIgnoreSigns`; an arachas holds 0.75 with one causer across a recompute and after Yrden's and frost's real slowdown effects (never id 0); `GMNpcQuenStagger` (the helper only); a Goldilocks bear without `ablIgnoreSigns`. Automated fight checks: a toad stays in a **real** Yrden after its hit counter reaches 3 (`gmtest_ai14_toad`); Reinald's Quen, through the task, staggers Geralt for the default length (`gmtest_ai14_quen`; with `god()` on the stagger is not added, so test with Geralt immortal). Real fights: a cyclops under **real** Axii played the confusion animation (5.x: it kept attacking); an arachas in a **real** Yrden trap moved at the trap's slow and was back at 0.75 after it; arachases approached about 12% slower than at 1.0. Each check failed on a throwaway build without its code. The slam range (`GMTest_ai14_slam`, `gmtest_panel()`, 2026-11-02): `wide_arc` reads 3 m on a golem, an Ifryt, an earth elemental and two Daos (5.x: 4, 4, 2, 2, 4).

## AI-C Special enemies

### AI-15 The Wild Hunt

| | |
|---|---|
| Kind | system, tuning |
| Pillars | P1, P5 |
| 5.x class | clean |
| Flags | balance |
| Depends on | DMG-02 (`GetDamageResists`, signed off), EFX-05 (frost slowdown), AI-03, AI-05 |
| Skill trees | both: Igni and Firestream remove Ice Armor (any fire: also bombs and runes); checks in both trees |
| Port form | `ai/wildHunt.ws`: the global `GMIceArmorResistBonus`, read by DMG-02's replaced `GetDamageResists` (`damage/formula.ws`, one marked line); `@wrapMethod(CNewNPC)` `OnFireHit` calling `@addMethod(CNewNPC)` `GMRemoveIceArmor`; 5.x's Ice Armor halving removed from the replaced `CActor.ReduceDamage` and its `EredinInvulnerable` check disabled (`damage/pipeline.ws`); data: every ability attribution gives AI-15 legacy's whole in `abilities/gm_ai_special.xml` (`gen_ai.py`: AI-15 in `AUTO` and `PORTED`; they leave `gm_ai_combat.xml` and `gm_npc_stamina.xml`, PA2), legacy's NG+-only `WildHunt_*_NGPlus` in `abilities_plus/gm_ai_ngplus.xml`, NG+ copy by `gen_ngplus.py`; the Hunt's weapons are AI-05's (slice A2) |
| Port status | **signed off** (2026-10-29); ported (slice C1; Eredin's frost projectile with AI-18, slice C2), verified in both trees |
| Open checks | Eredin's frost projectile cast by Eredin himself (shot by script from a spawned Eredin, below); Caranthir casting Ice Armor in a real fight (no spawnable Caranthir template found; Ice Armor was added by script, and Eredin's template carries it); Eredin attacking in a real fight (the spawned `enemy_eredin` stood idle; his sword's frost slowdown was seen through a scripted attack); the fire runes on Ice Armor (their fire damage takes the same path); Easy (no bonus) and Ciri's rage; New Game+ (untested, as every NG+ change) |
| Save impact | none |
| NG+ counterpart | applied, untested |

**What it does** (changelist 1123–1129, bugfix 75): Ice Armor adds 30% to all resistances (not on Easy, not against Ciri's rage, not for damage over time) instead of halving damage, so resistance reduction counters it and Igni is no longer mandatory; any fire hit removes it (1.32: Igni's). The Hunt's weapons and Eredin's frost projectile deal frost damage (Eredin's sword 350 slashing, 40 silver, +50 frost and frost slowdown; Caranthir's staff, Imlerith's mace and shield), countered by armor, frost resistance and dodging. Minions get 20 armor and full frost resistance; the generals' Essence 8,000–12,000 → 2,500, armor 125–150 → 200–250, resistances 50–70% → 30% with full burning and will resistance. Eredin no longer ignores signs (`EredinInvulnerable` commented out) or fire (`EredinFireResistance` emptied).

**Implementation (legacy):** `W3DamageManagerProcessor.GetDamageResists` (the Ice Armor term), `CActor.ReduceDamage` (halving and Eredin removed), `CNewNPC.OnFireHit`; 44 abilities and the Hunt's weapons.

**5.x:** 1.32's halving (5% on Easy) and Igni-only removal. `EredinInvulnerable` is defined in no XML, and `AddAbility` refuses a name no XML defines (tried on a spawned Eredin, 2026-10-28), so 5.x's check never applies: none of the three Eredin templates spawned carries it, and removing the check changes nothing in play, as legacy's commenting-out did.

**Decisions:** legacy's; this ended DMG-02's temporary deviation. The bonus is added to the resistance before the resistance reductions (legacy's order), so armor piercing and oils reduce it as any resistance. The removal runs in `OnFireHit`, which the damage pipeline calls for any hit that deals fire damage (a fire hit stopped by armor deals none and removes nothing; Igni's own hit also removes it through 5.x's `OnIgniHit`). The Hunt's warriors (`wlh_2h_sword`, `q403_wild_hunt_2h_sword`) and Imlerith refuse burning (`EI_Deny`, an immunity of their templates): on them "any fire" means fire hits (Igni, Firestream, fire bombs, runes); the hounds (`wildhunt_minion_*`) take burning, and its first tick removes Ice Armor. The warriors' and Imlerith's immunity stays as their templates have it, so "any fire" works on them only through fire hits (confirmed by the owner, 2026-10-29); the [legacy test](../open-questions.md#to-test-in-legacy-ghost-mode) of whether legacy's warriors burned stays open. Eredin's frost projectile is legacy's (AI-18): its entity (`gameplay/abilities/eredin/eredin_frost_proj.w2ent`, which neither 5.x nor legacy changed) sets 500 frost damage, so legacy's class default of 200 never applies to it; legacy's default effect, the frost slowdown, does (the entity sets none), for 3 s. 5.x: 500 frost raised by its level term (875 at Geralt level 30) and no slowdown. The final resistance is clamped to [0, 1], so a fully frost-resistant warrior's 130% heals nothing. Firestream's first hit (no fire damage) removes Ice Armor through 5.x's `OnIgniHit`; its ticks are damage over time, without the +30%.

**Verification (slice C1, 2026-10-28, both trees):** the regression (`GMTest_ai15`, `GMTest_ai15_after`, scripted): a burning hound loses Ice Armor; a silver hit on a warrior with Ice Armor deals 0.647 of one without (5.x 0.5); a fire hit removes it; the Hunt's abilities read legacy's (`GMTest_ai03`, `GMTest_ai08`). In game, both trees: **real** silver hits on a warrior with Ice Armor read 45% resistance (its 15% + 30%) and left the armor on; a **real** Igni, a **real** Dancing Star and burning's real ticks took it off; the warrior's **real** attacks carried frost damage; Eredin's sword (a scripted attack) dealt frost and the frost slowdown; **real** Yrden shocks on Eredin were resisted 60%; spawned Eredin, Imlerith, a warrior and a hound have legacy's stats by AI-01's formula. The checks failed on a throwaway build without the slice.

### AI-16 Weakened states and the djinn

| | |
|---|---|
| Kind | tuning |
| Pillars | P5 |
| 5.x class | clean |
| Flags | — |
| Depends on | ALCH-15 (the djinn under Dimeritium, ported) |
| Skill trees | both: Yrden and Axii weaken the djinn (5.x's rage task) |
| Port form | the abilities given whole in `abilities/gm_ai_special.xml` (`gen_ai.py`: AI-16 in `AUTO` and `PORTED`; `WeakenedState` is a Hearts of Stone ability: `replace` with its tag; `mon_djinn` leaves `gm_ai_combat.xml`, `DjinnRage` and `DjinnWeak` leave `gm_npc_stamina.xml`) |
| Port status | **signed off** (2026-10-29); ported (slice C1), verified in both trees |
| Open checks | the djinn's rage and weakness in a real fight (the spawned quest djinn never fought: Geralt stayed out of combat and Axii found no target; the abilities were added by script, as its rage task does); Olgierd's weakened state in his fight (the spawned `olgierd.w2ent` lacks the `olgierd_gpl` tag the state needs; tested on a tagged warrior) |
| Save impact | none |
| NG+ counterpart | applied, untested |

**What it does** (changelist 1130–1133): the djinn's rage gives +10% stamina regen and +50% attack and spell power (1.32: +100% regen), its weakness −10% and −50% (−100%); a weakened special enemy (Olgierd countered, and the like: `WeakenedState`) takes −15% physical resistances; the djinn 11,000 → 3,000 Essence, level 15 → 1, full damage-over-time resistance (AI-03).

**Implementation (legacy):** `DjinnRage`, `DjinnWeak`, `mon_djinn`, `WeakenedState`.

**5.x:** 1.32's. `WeakenedState` is added by `CNewNPC.SetWeakenedState` only to NPCs tagged `olgierd_gpl` (Olgierd); the djinn's abilities by its rage task (`BTTaskManageDjinnRage`, ALCH-15's).

**Decisions:** legacy's.

**Verification (slice C1, 2026-10-28, both trees):** the regression (`GMTest_ai15_after`, scripted): a warrior tagged `olgierd_gpl`, through `SetWeakenedState(true)`, loses 15% slashing resistance; a spawned djinn's attack power ×1.15 → ×1.65 with `DjinnRage`, ×0.65 with `DjinnWeak` (5.x unchanged). `gmtest_ai15_rage` (classic tree) also reads the stamina regen and the djinn's 3,600 Essence at level 1 on Hard.

### AI-17 Instant kills and LastBreath

| | |
|---|---|
| Kind | system |
| Pillars | P5 |
| 5.x class | clean |
| Flags | — |
| Depends on | EFX-09 (the frozen rotfiend, ported), SKL-05 and SKL-12 (the instant-kill function and the Axii instant kill, ported) |
| Skill trees | n/a (checks in both trees) |
| Port form | `MonsterMHBoss` in `gm_ai_levels.xml` (slice A2: legacy's, without 5.x's 8,000 Essence and attack power); `ai/instantKill.ws`: `@addMethod(W3DamageManagerProcessor)` `GMGetLastBreathMaxAllowedDamage`, read by legacy's two rules added to SKL-05's replaced `ProcessInstantKill` (`skills/deadlyPrecision.ws`); the explosion's damage in EFX-09's replaced `BTTaskExplodeAtDeath.Explode` (`effects/frozenRotfiend.ws`) |
| Port status | **signed off** (2026-10-29); ported (slice C2), verified in both trees |
| Open checks | the explosion's damage in play: no real rotfiend death ran it (EFX-09's finding, seen again in C2; its damage seen by a scripted `Death` signal); an instant kill from a weapon's `instant_kill_chance` or Deadly Precision on a contract monster (the real hits used vanilla's `ForceInstantKill` ability, the same function) |
| Save impact | none |
| NG+ counterpart | applied (`MonsterMHBoss`), untested |

**What it does** (changelist 1098): contract monsters are immune to instant kills (legacy also strips `MonsterMHBoss`'s 8,000 Essence and attack power; their stats come from AI-03's quest abilities); an instant kill on a LastBreath monster (rotfiends) deals only the health above its LastBreath threshold, so it cannot kill it outright (legacy's comment: so its explosion cannot kill Geralt with it; a frozen one dies outright, EFX-09); the rotfiend explosion deals the damage of the monster's weapon, 300 without one.

**Implementation (legacy):** `MonsterMHBoss`; `ProcessInstantKill` (a return for `W3MonsterHuntNPC` victims; the instant kill's damage set to the victim's health, or to `GetLastBreathMaxAllowedDamage` on a LastBreath monster not frozen); `BTTaskExplodeAtDeath.Explode`.

**5.x:** no instant-kill immunity for contract monsters beyond the `InstantKillImmune` ability most contract entities carry (mh102's arachas, mh202's nekker, mh107's fiend, mh301's griffin, the red-plague creature; not mq1051's wyvern, mh303's succubus, mh305's dopplers, sq204's leshen: from the entity files); an instant kill adds the victim's health to the hit's damage after `ReduceDamage`, so it kills a rotfiend outright, past LastBreath; the explosion 50/100/150/200 + 2/3/4/5 × the weapon's damage by difficulty (150 + 4× on Hard).

**Decisions:** legacy's (PA10: the explosion's damage is ported though no real death runs it in 5.x). Legacy's immunity is its check of the class (`W3MonsterHuntNPC`), not the `InstantKillImmune` tag on `MonsterMHBoss` (A2): `HasAbility` reads ability names, so the tag changes nothing (it stays, as legacy's data). The instant kill sets the victim's health as the damage (legacy; 5.x adds it to the hit's), so the floater and the logs show the health taken. A rotfiend cut to its threshold by an instant kill does not swell (its swelling starts on the `LastBreath` signal of a held-back hit in `ReduceDamage`); it fights on at 25% (seen in both trees), as legacy's code reads (confirmed by the owner, 2026-10-29); with `ForceInstantKill` every later hit deals 0 (the health above the threshold is 0). Contract monsters of 5.x's new content that are `W3MonsterHuntNPC` (the red-plague creature, the Hakland mage of Hearts of Stone) are immune too. Axii's instant kill (SKL-12's `GMIsAxiiInstakillTarget`) excludes contract monsters too, as legacy.

**Verification (slice C2, 2026-10-28, both trees):** the regression (`GMTest_ai17`/`_after`, scripted): an instant kill leaves mq1051's contract wyvern (no `InstantKillImmune`) unharmed and a rotfiend at its 25% threshold; a rotfiend's death signal deals 300 without a weapon (5.x: 150). In game, Geralt with vanilla's `ForceInstantKill`: **real** light attacks did not instant-kill the contract wyvern, left a rotfiend alive at 25% (it fought on without swelling) and killed an arachas outright; the explosion, set off by script, dealt the rotfiend claws' 350 (a real rotfiend death ran none). Each failed on a throwaway build without the slice.

### AI-18 Special attacks and monster projectiles

| | |
|---|---|
| Kind | system, tuning |
| Pillars | P1, P5 |
| 5.x class | overlap |
| Flags | balance |
| Depends on | DMG (attack power after armor), XBOW-08 (its kept level term) |
| Skill trees | both: Quen against the Blood and Wine projectiles that break it (legacy: they no longer do); checks in both trees |
| Port form | `ai/specialAttacks.ws`: `@replaceMethod` of `W3AdvancedProjectile.OnProjectileCollision` (5.x's level term out), of eleven projectile classes' collision or damage functions (5.x bodies, the effect 3 s and the projectile's own damage and effect), `DebuffProjectile.OnProjectileCollision` (the Hakland mage's hack, `@addField`/`@addMethod(CNewNPC)` `GMHaklandMageDebuffProjectileHack`; `ignoreArmor` on every victim, legacy's line), `W3BoulderProjectile.DealDamageToVictim` (bludgeoning, `ignoreArmor` on every victim), `W3LeshyRootProjectile.DelayDamageTimer`, `W3LeshyBirdProjectile.OnProjectileCollision`, `W3RedPlagueProjectile.DelayDamageTimerNew` (DA5), `W3IceSpike.DealDamage`, `W3WitchBoilingWaterObstacle.Appear`, `CFlyingCrittersLairEntityScript.OnBoidPointOfInterestReached`, `W3ReactToBeingHitEntity.DealDamage`, `CToadAcidPool.OnFireHit`, `CBTTaskTornadoAttack.Main`, `CBTTaskGroundTrapAttack.Main`; scope-based defaults of ten projectile classes and `CBTTaskGroundTrapAttackDef`; `@wrapMethod(W3Action_Attack)` `Init` (magic fists); binary edits of 16 projectile and obstacle entities by `tools/gen_ai_ent.py` (AI-18 in `PROPS_LATER`, legacy's value also where 5.x changed it), and the Wild Hunt mage's ice spear (`GAME_FILES`: a file legacy left as 1.32's); the Hakland mage's and the magic fists' abilities came whole with AI-04 and AI-05 (slice A2) |
| Port status | **signed off** (2026-10-29); ported (slice C2; the owner's decisions on armor and boulders, 2026-10-29), verified in both trees |
| Open checks | a boulder thrown by a monster in a fight (none throws them near the test save; boulders shot by script); the witch's boiling water and the Hakland mage's quicksand and sand coil in a real fight (the Crones and the Hakland mage, spawned by script, were removed by the game at once: quest NPCs; the quicksand's entity value read by script); the toad's acid pool, ice spikes, objects striking back, the Blood and Wine tornado, ground trap, Dettlaff's and the other Blood and Wine projectiles in a fight (not reached without quests); the bird swarms and the leshen's birds in a fight (neither seen); a magic fist's hit (scripted: the attack reads ranged); Quen against the Blood and Wine projectiles; Caranthir's ice spear in a fight (500 by script) |
| Save impact | none |
| NG+ counterpart | none |

**What it does:** special attacks deal set damage with the attacker's attack power (spell power for eight projectile classes, as in 1.32: Ifryt's, Eredin's, poison, fireballs, the Dracolizard's, ice meteors, lightning strikes and lightning bolts) and the victim's armor (DMG's rule), instead of reading the attacker's basic-attack stats or ignoring armor: monster projectiles their projectile's damage, 200 by default (boulders, stones, elementals', Eredin's, fireballs, meteors, lightning), with their effects 3 s (2 s); ice spikes their own frost damage (100 when unset) with attack power; the leshen's roots 400 rending with a heavy reaction (its birds dealt by the swarm); the witch's boiling water with attack power; bird swarms ignoring armor, without attack power; objects that strike back when hit (`W3ReactToBeingHitEntity`) their own damage type, and when they have no damage set the larger of 500 and half Geralt's health, with a heavy reaction; the toad's acid pool at least 20% of the victim's health in fire; the Blood and Wine tornado 2% of the victim's health, the ground trap at least 500 or 20% as direct damage; magic fists count as ranged attacks; the Hakland mage's debuff projectile hits once in 3 s (it hit three times); the Blood and Wine and Hearts of Stone projectiles' damage and whether they break Quen (legacy: none does) and ignore armor (none does), the djinn's wood and the sorceresses' stone no longer ignoring armor; boulders deal bludgeoning damage (1.32's), and boulders and debuff projectiles set to ignore armor ignore it on every victim (1.32's lines). **No projectile gains damage from Geralt's level.**

**Implementation (legacy):** 20 `advancedProjectile.ws` units, 2 leshen units, 6 obstacle and swarm units, 3 Blood and Wine task units, `W3Action_Attack.Init`, `CNewNPC.HaklandMageDebuffProjectileHack`, the `HaklandMage` abilities; 16 projectile and obstacle entities (13 projectiles, 2 quicksands, the toad's acid pool).

**5.x:** +2.5% damage per Geralt level on every projectile at each collision (per the victim's level when playing Ciri), kept for monster projectiles and reflected arrows by XBOW-08 until now; the leshen's roots and the boiling water below 101 damage (but the q111 witch's) rebuilt as heavy attacks of the attacker's weapon; a debuff projectile adds a second hit of rending damage of its value when its damage type does not hit Essence; boulders deal rending damage (1.32: bludgeoning) and ignore armor only on Vitality users; bird swarms ignore armor (as legacy) with attack power; four Blood and Wine and Hearts of Stone projectiles' damage lowered (the echinops' acid 1,000 → 500, Dettlaff's swarm 1,000 → 30, the toad's spit 890 → 500 and tongue 900 → 400), and the Wild Hunt mage's (Caranthir's) ice spear 500 → 285, a file legacy did not touch (with 5.x's level term, 285 is about 500 at Geralt level 30); new: the red-plague creature's roots (200 to 300 elemental or its heavy attack + 200) and a thrall's boulder (`W3ThrallBoulderProjectile`).

**Decisions:** legacy's; 5.x's level term removed for every projectile (PA11), ending XBOW-08's temporary deviation ([xbow.md](xbow.md#xbow-08-npc-bows-and-crossbows)); the boiling water uses attack power on both of 5.x's paths (PA12); the red-plague creature's roots follow legacy's leshen-roots rule (DA5, confirmed by the owner, 2026-10-28). Legacy's projectile values also where 5.x changed them (as PA1 for abilities). Legacy's class defaults apply only where a projectile's entity sets no value of its own: Eredin's frost projectile keeps its entity's 500 frost (legacy and 1.32 alike) and takes legacy's default frost slowdown ([AI-15](#ai-15-the-wild-hunt)); the sorceresses' stone reads 200 from legacy's entity edit. 5.x's second rending hit of the debuff projectiles is removed (legacy's numbers are tuned for one damage type; legacy's behaviour; confirmed by the owner, 2026-10-29). Debuff projectiles and boulders set to ignore armor ignore it on every victim, as legacy's and 1.32's lines (owner, 2026-10-29; 5.x: only on Vitality users), and boulders deal bludgeoning damage, as legacy and 1.32 (owner, 2026-10-29; 5.x: rending). Bludgeoning and physical damage do not hit Essence, so a boulder or a physical debuff projectile deals nothing to a monster, as in legacy and 1.32: a boulder Aard sends back at a troll does not hurt it (5.x's rending did). Legacy's dead code in the ice spike (the summoner's weapon damage, computed and discarded) is not carried over, nor legacy's hit-animation and attacker lines before `Initialize` in the leshen's roots (`Initialize` clears them; the heavy reaction comes from `EHRT_Heavy`). The Wild Hunt mage's ice spear takes 1.32's 500, which legacy played (it left the file as 1.32's), over 5.x's 285 (the rule for legacy's own edits, as AI-B's `PART` for abilities; with PA11, 5.x's 285 would deal 285 at every level; confirmed by the owner, 2026-10-29). The magic fists count as ranged only for the `fists_lightning` and `fists_fire` items, as legacy.

**Projectile entities** (scanned 2026-10-29): the classes that read their entity's damage or effect since this port (the elementals', stones, environment projectiles; the effect of poison, fireballs, meteors, lightning) made every value stored in a 5.x entity count. Every entity of a `W3AdvancedProjectile` class in the game's bundles was dumped in both games (58 files, the same in 1.32 and 5.x), with legacy's and the port's edits applied, and compared with what legacy played (the stored value, else legacy's class default, which the port shares). They store: the elementals' Dao and Ifryt projectiles, the giant's and the sharley's shockwaves, the elemental's stone, the elemental's, the sorceresses' and Philippa's fireballs nothing (200 and their class's effect); the sorceresses' five environment projectiles only their stagger (the default); the sorceress's lightning bolt nothing (40, paralysis), the `q205` lightning ball burning instead; poison: the arachas's venom 400, the scolopendromorph's 400, the black spider's web line 400, the fairytale witch's 500, the echinops' acid 350 (legacy's edit), the toad's spawn 150 and mortar 50, the endriaga worker's nothing (40), the fugas stink cloud 0 with burning, the fairytale witch's spawn 0 without an effect; the meteors of `q403` 2,000 and 2,300, Eredin's 500 frost with its slowdown; the Dracolizard's fireball 300 and 300 silver, burning 3 s (legacy's edit); boulders: the djinn's 100, the sorceresses' and the rock witch's 200, the troll's 250, the sharley's 250 with a heavy knockdown; Eredin's frost projectile 500; the debuff projectiles their damage and debuff (legacy's edits where it made them). All 57 but one read what legacy read; the one is the Wild Hunt mage's ice spear (1.32 and legacy 500, 5.x 285), now 500 (above). The `q205` lightning ball's and the stink cloud's burning apply, as in legacy (1.32: paralysis and poison).
- **Deviation:** the witch's boiling water keeps 5.x's two paths: below 101 damage (but the q111 witch's) a heavy attack of the summoner's weapon with its attack power, 101 and above legacy's set damage with attack power (legacy: the set damage with attack power always; PA12, confirmed by the owner, 2026-10-28).
- **Deviation:** 5.x's new thrall boulder (`W3ThrallBoulderProjectile`, a class legacy has no counterpart of) keeps its entity's numbers and 5.x's rules (rending damage, armor ignored only on Vitality users, its own Aard deflection), without the level term (confirmed by the owner, 2026-10-29).

**Verification (slice C2 and the AI-C audit, 2026-10-28 and 2026-10-29, both trees):** the regression (`GMTest_ai17`, `GMTest_ai17_after`, scripted): the entity edits read legacy's; collisions through each projectile's real `OnProjectileCollision` (`GMTestAi17Collide`) deal the class defaults with 3 s effects, Eredin's frost projectile 500 frost with a 3 s slowdown at any Geralt level (5.x: 875 at level 30), the ice spear 500, a debuff projectile one damage type, the Hakland mage's second hit within a moment nothing, and debuff projectiles and boulders set to ignore armor ignore it on an armored monster; a lightning fist's attack reads ranged. The stone's knockdown lands only at random (native effect code), so the panel checks that the action carries `EET_Knockdown` and only logs the landing. In game: **real** monster projectiles (an arachas's spit, a water hag's mud) and a **real** arrow reflected by Deflection dealt the same at Geralt levels 1 and 30, without a rending hit; the leshen's and the red-plague creature's **real** root attacks dealt 400 rending with a heavy reaction. Each check failed on a throwaway build without its code. Aard's deflection: [SKL-08](skl.md#skl-08-aard).

### AI-19 The Caretaker and quest monsters' immunities

| | |
|---|---|
| Kind | tuning |
| Pillars | P5 |
| 5.x class | clean |
| Flags | — |
| Depends on | AI-03 |
| Skill trees | n/a (checks in both trees) |
| Port form | `ai/caretaker.ws`: `@replaceMethod(BTTaskCaretakerManager)` `OnListenedGameplayEvent` (5.x's body; 5.x's bleed removal at the dispel, in `OnAnimEvent`, untouched); `@addMethod(W3DamageManagerProcessor)` `GMCausesDamageValue`, the `CausesDamage` signal's value, called from one marked line of DEF's replaced `ProcessAction` (`defense/processAction.ws`); binary edits of five entities' `CBuffImmunityParam.immunityTo` by `tools/gen_ai_ent.py` (AI-19 in `PROPS_LATER`; legacy's effect numbers translated to 5.x's by name, `ENUM_ARRAYS`); `mon_caretaker_ep1`, `q604_caretaker`, `q604_shades` given whole (`replace`, Hearts of Stone abilities) by `gen_ai.py` (`SPEC`) in `abilities/gm_ai_monsters.xml`; `Shovel _Stats` and the new `Caretaker Shovel _Stats` whole in `items/gm_ai_weapons.xml` (`AUTO`), the `Caretaker Shovel` and `caretaker_body` items whole (`replace`) naming it (`gen_ai.py`'s `ITEMS`); legacy's NG+-only `mon_caretakereasy_ep1` and `mon_caretakermedium_ep1` in `abilities_plus/gm_ai_ngplus.xml`; the spade's description (2110992475) in the string tables |
| Port status | **signed off** (2026-10-29); ported (the three abilities with the AI-A audit, the rest in slice C3), verified in both trees |
| Open checks | the Caretaker's heal from a hit on a shade in a real fight (the shades were not summoned; a hit on another NPC signals 1, scripted); the quest monsters' immunities in their own fights (read with `IsImmuneToBuff` on spawned entities); the spade's description on screen (the string read by key); New Game+ (untested, as every NG+ change) |
| Save impact | none |
| NG+ counterpart | applied, untested |

**What it does** (changelist 1134–1135, bugfix 101): the Caretaker heals in proportion to the damage of his hit (1.32: a fixed share per hit), so a heavily armored Geralt can tank him; he still heals fully from killing shades; his weapon uses the Hearts of Stone shovel ability; immune to knockdown, heavy knockdown and bleeding. Immunities also set for Gregoire (acid, bleeding), the `mh102` arachas (poison instead of burning), the ancient fogling (heavy knockdown) and the `mh210` lamia (no longer knockdown).

**Implementation (legacy):** `BTTaskCaretakerManager.OnListenedGameplayEvent` and the `CausesDamage` signal in `W3DamageManagerProcessor.ProcessAction` (the relative damage); `mon_caretaker_ep1` (3,000 Essence and 200 armor in place of 5.x's ×2.5 Essence, 100 armor and +30% attack power), `q604_caretaker` (30% physical and elemental resistances, full will, bleeding and poison resistance, crit damage reduction 0.5; 5.x's −70% attack power, −20% Essence and stamina values gone), `q604_shades` (stamina values gone); `Caretaker Shovel _Stats` (new: 400 slashing, 80 silver; his shovel items in Hearts of Stone's `def_item_weapons.xml` name it in place of `Shovel _Stats`, whose Hearts of Stone duplicate legacy deleted) and the base game's NPC `Shovel _Stats` (150 slashing, 4 silver); five entity files; the player's spade's description (`item_name_caretaker_spade_desc`, a key 5.x leaves without text).

**5.x:** 1.32's healing: `healing_per_hit_perc` of his maximum health per damaging hit (6.6% on Hard, ×1.2 while shades are up); the `CausesDamage` signal carries the damage dealt, which nothing reads; the Caretaker also removes 5.x's three extra bleeding types (`EET_Bleeding1` to `3`) at his dispel. 5.x adds its own entries to two of the five immunity lists (the Caretaker's 61; the arachas's second list 60 and 61: `EET_ShrineAard` and `EET_ShrineAxii` by the script enum's numbers, purpose unknown).

**Decisions:** legacy's. The heal is his maximum health × the hit's relative damage × `healing_per_hit_perc` (× `number_of_shades` while shades are up); the relative damage is legacy's signal value: on Geralt the Vitality the hit took over half his maximum, at most 1; on any other victim (a shade) 1. The immunity lists hold `EEffectType` numbers, and 5.x inserted two effect types at 127 (`EET_Catalyst`, `EET_ConvergenceTheory`), so legacy's numbers are translated by name (legacy's acid, 134, is 5.x's 136); legacy's removals and additions apply to 5.x's lists. The three abilities are given whole because an `extend` empties a Hearts of Stone ability ([development.md](../development.md#fine-grained-xml-overrides-50)); they carry STAM-08's stamina values (PA2). His Essence is legacy's: 29,345.4 at his level 34 on Hard = (3,000 + 450 + 33 × 20) × (1 + 33 × 0.15) × 1.2 (4,140 at level 1). The gameplay alias `caretaker` (`secondary_npc\caretaker.w2ent`) is another template, without `mon_caretaker_ep1` (7,925 at level 34); the quest's is `q604_caretaker.w2ent`. The spade's description is legacy's ("Restores Vitality proportional to damage dealt.", nine languages; UI's hand-off). `BTTaskCaretakerManager` is the only listener of `CausesDamage` in 5.x, 1.32 and legacy, so the changed value breaks nothing else. `Shovel _Stats`' weight stays 5.x's (the owner's decision in the WGT audit).
- **Deviation:** the Caretaker is not immune to 5.x's three new bleeding types (`EET_Bleeding1` to `3`): legacy's list predates them; he keeps removing them at his dispel, as in 5.x; the three are inert since ARM-09 (confirmed by the owner, 2026-10-29).
- **Deviation:** 5.x's own entries in the Caretaker's and mh102's arachas's immunity lists (61; 60 and 61) are kept beside legacy's (confirmed by the owner, 2026-10-29).

**Verification (the AI-A audit and slice C3, 2026-10-28, both trees):** the three abilities read whole in game (`gmtest_ability_probe`; `GMTest_ai03`); the Caretaker at level 34 has legacy's armor, resistances and attack power, and his **real** shovel attacks carry legacy's 400 slashing and 80 silver. The regression (`GMTest_ai19`, `GMTest_ai19_after`, scripted): the `CausesDamage` value (0.2 for a hit taking 10% of Geralt's Vitality, 1 at 90% and on another NPC), the shovel items naming `Caretaker Shovel _Stats`, the spade's description, and the five quest monsters' immunities (`IsImmuneToBuff`). **Real** attacks of a hostile Caretaker healed him by legacy's formula (a hit of relative damage 0.902: 29,345.4 × 0.902 × 0.066 = 1,748; 5.x: 1,936.8 a hit, whatever its damage). The checks failed on a throwaway build without the slice.

### AI-20 Fistfights

| | |
|---|---|
| Kind | tuning, system |
| Pillars | P5 |
| 5.x class | clean |
| Flags | balance |
| Depends on | DMG-04 (the pool hosts `fist_dmg_bonus`), STAM (fistfight parries) |
| Skill trees | n/a (checks in both trees) |
| Port form | the fistfight abilities whole (`gen_ai.py`: AI-20 in `AUTO` and `PORTED`): the opponents' in `abilities/gm_ai_humans.xml` (they leave `gm_npc_stamina.xml`, PA2), Geralt's fists in `items/gm_ai_weapons.xml`; the fistfighters' ability lists in their entities (`gen_ai_ent.py`: AI-20 in `PORTED`); `ai/fistfights.ws`: `@replaceMethod(CNewNPC)` `OnStartFistfightMinigame`, `RemoveFistFightLevelDiff`, `@addMethod(CNewNPC)` `GMValidateFistfighterAbilities`; `@replaceMethod(CR4Player)` `FistFightHealthChange`; `@addMethod(W3DamageManagerProcessor)` `GMAddFistDamageBonus`, called from one marked line of DMG-04's replaced `ProcessDamageIncrease` (`damage/pool.ws`) |
| Port status | **signed off** (2026-10-29); ported (slice C3), verified in both trees |
| Open checks | a quest fistfight started by its quest block (the minigame was started by script, through the events the block calls); the Baron's −100 and the quest fights' health in their quests; the sergeant's old-save fix on a real old save (scripted on a bandit); New Game+ (no NG+ level cut; untested, as every NG+ change) |
| Save impact | none |
| NG+ counterpart | applied, untested |

**What it does:** fistfight opponents get no level-difference abilities or NG+ level cut; each tier adds flat fist damage (easy +50, medium +100, hard +150; the Baron −100); opponents' health retuned (`HealthFistFight*`: the tier's flat health in place of 1.32's addition to the opponent's own, and the quest fights'); duplicate tier abilities cleaned up (and the sergeant's save fix); Geralt's Vitality is not clamped to 2,000 in a fistfight; Geralt's fistfight fists 300 bludgeoning and 300 silver (1.32: 150 and 1).

**Implementation (legacy):** 33 fistfight abilities (`StatsFists*`, `SkillFists*`, `HealthFistFight*`, `NPCLevelModFistFight*`, the quest fights, `sq301_fistfighters`, `qSergeantFistFIght`, Geralt's fists); `CNewNPC.OnStartFistfightMinigame`, `ValidateFistfighterAbilities`, `RemoveFistFightLevelDiff`, `FistFightNewGamePlusSetup`, `ApplyFistFightLevelDiff`; `CR4Player.FistFightHealthChange`; `ProcessDamageIncrease`'s fist bonus; the fistfighters' entity lists (`mq0005`'s arsonist, the sergeant, the four `sq301` fighters).

**5.x:** 1.32's. `ApplyFistFightLevelDiff` (the level-difference buffs) has no caller in 1.32 or 5.x, so neither gives fistfight opponents level buffs; 5.x removes an NG+ opponent's NG+ levels of `NPCLevelBonus` at the fight's start (`FistFightNewGamePlusSetup`).

**Decisions:** legacy's; ends DMG-04's temporary deviation (`fist_dmg_bonus`). The fist bonus is legacy's first flat addition, before the pool, to the hit's bludgeoning damage (as bludgeoning when it has none), for melee hits of an attacker holding fists. Legacy's commenting-out of `ApplyFistFightLevelDiff` changes nothing in play (no caller); the port leaves 5.x's uncalled function. DA4 has no fistfight effect. `ClampGeraltMaxHealth` has no other caller, so nothing clamps Geralt's Vitality. Legacy's tier health abilities set the health with a ×−10 multiplier and a flat addition; the game floors the multiplier, so an opponent's health is its flat additions (the tier's 1,000 to 2,000 and its own) × 5.x's Hard multiplier (1,200 for an Easy opponent, 1,800 for Lugos, Medium). Blood and Wine's drunken master's Hardcore ability (`mon_EP2_hardcore_FF`, legacy's +50 fist damage) is a per-difficulty variant, ported by DIFF ([DIFF-02](diff.md#diff-02-per-enemy-difficulty-variants)).
- Blood and Wine's drunken master gets legacy's +50 fist damage on "Death March!" (`mon_EP2_hardcore_FF`; 5.x: +80% attack power) ([DIFF-02](diff.md#diff-02-per-enemy-difficulty-variants)). Verified with a real fistfight on "Death March!" in both trees: each of his punches carried +200 before the pool, his Hard tier's 150 and the variant's 50. The variant sits in his entity's own ability list, so it is chosen when he spawns (his quest spawns him on the mode being played) and a later mode change drops it.

**Verification (slice C3 and the AI-C audit, 2026-10-28 and 2026-10-29, both trees):** the regression (`GMTest_ai20`, `GMTest_ai20_after`, scripted): Geralt's maximum Vitality unclamped (5.x: 2,000), the tiers' fist bonus, the tier cleanup and the sergeant's fix. In fistfights started by script as the quest block does (`gmtest_ai20_start`): **real** punches of Easy, Medium and Hard fighters carried +50, +100 and +150 before the pool; the opponents' health was their tier's (Easy 1,200.1, Lugos 1,800.25 on Hard); Geralt's punches dealt 300 bludgeoning and 300 silver raw; fights played to a knockout left Geralt's maximum Vitality and abilities as before. The checks failed on a throwaway build without the slice.

### AI-21 Pre-attack debug log

| | |
|---|---|
| Kind | infra |
| Pillars | — |
| 5.x class | clean |
| Flags | — |
| Depends on | — |
| Skill trees | n/a |
| Port form | none |
| Port status | not ported (PA13); signed off with AI-C (2026-10-29) |
| Open checks | — |
| Save impact | none |
| NG+ counterpart | none |

**What it does:** `toggledebugpreattack` logs each incoming attack's name, range, dodgeability and parry result (`CActor.OnPreAttackEvent`, `PreAttackParry`); an unused `GetDelaySinceLastAttack` with its field; a comment in `ReactToReflectedAttack`.

**Decisions:** not ported (PA13), as EFX-12.

---

### Dependencies on other areas

- **Done areas AI builds on:** DMG (the formula, the pool, the lazy armor fix, allies), STAM-08 (NPC stamina; the same abilities), DEF-06 (enemy guards after a counter), SKL-08, SKL-10, SKL-12 (Aard, Yrden, Axii's Puppet and instant kill), EFX-05, EFX-09 (frost slowdown, the frozen rotfiend), ALCH-14, ALCH-15, ALCH-16 (Silver Dust, Dimeritium, oils by category), XBOW-08 (NPC bows), UI-11, UI-12 (journals, the enemy level), LOOT (the same entity files).
- **Areas AI shares with:** DIFF (scaling options, difficulty multipliers and variants, Ciri, fake levels), XP (kill experience), FIX (projectile collisions), WGT, ECON; what each takes is in [scope](#scope).
- **Open:** the question on [ungated NPC attacks](../open-questions.md#ungated-npc-attacks) stays STAM-08's; no AI feature depends on it. If every attack is to be refused without stamina, the fix is STAM-08's (the attack's start).
- **Hand-offs with nothing to port:** the Skellige archers' and the Emhyr crossbowman's attack ranges (W3Edit's lost `rangeShort` cones, re-save noise, [binary-files.md](../binary-files.md)); the fiend's hypnosis length (legacy changed none; EFX-05's default is ported); the Yrden turret's `EntersYrden`/`LeavesYrden` signals (kept by SKL-10 as 5.x's, confirmed by the owner, 2026-10-16); the NPC dodge's minimum distance (vanilla's).

### Save impact

None: abilities are read when an enemy spawns or levels, entity templates at spawn, behaviour defaults when the AI parameters are created. An NPC the save already holds keeps its saved level (AI-06) and its saved maximum health until its bonuses are recomputed at combat start or Geralt's next level (AI-01; verified with Vesemir, slice A3). Adding or removing the mod mid-playthrough is not supported ([save compatibility](../feature-mapping.md#save-compatibility)).

### Area decisions

**Area decisions** (all decided by the project owner, 2026-10-28):

| # | Question | Options | Recommendation | Decision |
|---|---|---|---|---|
| DA1 | How to port an area this size | (a) three parts, each ported, audited and signed off in turn: AI-A enemy stats, AI-B behaviour, AI-C special enemies; (b) one area, one audit at the end | **(a)**: the stats are mostly generated data with their own checks, behaviour needs fights watched, and the special enemies are one-off rules; an audit of 2,100 units at once would be thin. Each part's fights are judged once the parts before it are in | **(a)** (project owner, 2026-10-28): AI-A, AI-B, AI-C, each ported, audited and signed off in turn |
| DA2 | Where AI ends and DIFF begins | (a) AI ports how enemies grow with level (per-level bonuses, templates, entity levels, NG+ levels) with legacy's recommended scaling fixed: enemies more than 6 levels below Geralt are raised to 6 below, guards at Geralt's level +16, no extra health or damage; DIFF later adds the scaling menu, the difficulty multipliers, the per-difficulty enemy variants, Ciri and the fake levels; (b) AI also ports the scaling menu; (c) AI ports only each enemy's own numbers, DIFF the level bonuses and levels | **(a)**: legacy balanced each enemy's numbers against its level bonuses, so they belong together; the menu is an option, not a stat. Until DIFF, the difficulty modes keep 5.x's multipliers (DMG's temporary deviation) and enemies show 5.x's fake level (UI-12's) | **(a)** (project owner, 2026-10-28): enemies at most 6 levels below Geralt, guards 16 above, fixed until DIFF; DIFF adds the scaling menu, the difficulty multipliers, the per-difficulty variants and the hidden level bonus. The fixed preset ended with DIFF's slice D5a (2026-10-30) |
| DA3 | Legacy's combat rolls on 5.x's reworked monsters | (a) legacy's dodge, counter, guard and taunt chances on every enemy, including the monsters whose fighting 5.x reworked, judged in fights; (b) legacy's for humans only, 5.x's for monsters | **(a)**: legacy behaviour first; 5.x changed none of the monster numbers, only the moves they choose between, and the human rolls legacy sets anyway. If a reworked monster plays badly, that is for the balance pass | **(a)** (project owner, 2026-10-28): legacy's dodge, counter, guard and taunt chances on every enemy, including 5.x's reworked monsters |
| DA4 | How far above Geralt an enemy counts as "high" and "deadly" | (a) legacy's 6 and 15 levels, as in 1.32; (b) 5.x's 10 and 20 | **(a)**: legacy's damage-over-time bonuses and guards use them, and so do two signed-off features that today read 5.x's values without a recorded deviation: the enemy level shows red from 10 levels up instead of 6 (UI-12), and finishers are never or always rolled from 20 levels' difference instead of 15 (SKL-12). (a) moves both back to legacy's; (b) keeps them and records both as deviations | **(a)** (project owner, 2026-10-28): 6 and 15; SKL-12's finisher rule and UI-12's red level back to legacy's (done in slice A1) |
| DA5 | 5.x's new enemies (the witcher Reinald of the new quest `mq1060`, the red-plague creature) | (a) Ghost Mode numbers made by analogy with legacy's nearest enemies (a witcher NPC's template and armor, a monster of the same kind), proposed by the porter in AI-A's slice A2 and confirmed by the owner; (b) 5.x's own numbers under legacy's level model; (c) left out of legacy's level model | **(a)**: as ARM's DA3/DA4 and SWD-10 did for 5.x's new gear. Under (b) they keep numbers made for 5.x's large per-level bonuses (Reinald's template: 25 Vitality, plus 55 per level in 5.x), which legacy's model removes, so they would be far weaker than legacy's enemies of their level | **(a)** (project owner, 2026-10-28); the numbers proposed and ported in A2 confirmed (2026-10-28): Reinald as a quest boss like legacy's quest witchers, the plague victims as legacy's `ConDefault` on Essence, the red-plague creature with legacy's Hym and leshen numbers, its root attack by legacy's leshen-roots rule in C2 ([DA5's numbers](#da5-5xs-new-enemies)) |

### DA5: 5.x's new enemies

5.x's quest `mq1060` ("Devil's Pit") brings three kinds of enemy legacy never had. Their numbers, proposed by the porter by analogy with legacy's nearest enemies and **confirmed by the owner** (2026-10-28), are in `gm_ai_humans.xml` (`gen_ai.py`'s `DA5` table); legacy's level model (AI-01) grows them with their level as any other enemy. Values at level 10 on Hard (scripted reads of spawned enemies, both trees, 2026-10-28):

| Enemy (entity) | 5.x | Proposed | Based on |
|---|---|---|---|
| The witcher Reinald (`mq1060_witcher`, level 15) | his template `mq1060_Reinald`, a copy of 1.32's `ConDefault`: 25 Vitality, 50% fire resistance, stamina regen ×0.07; plus `Boss` (+150% health) and Gundar's `qmq2038_gundar` (+200% health, +50 armor) | the template = legacy's `ConDefault`: 80 Vitality, no fire resistance, stamina regen ×0.25; with legacy's `Boss` (+1,000, +100 and +50% attack power, +10% physical and +30% other resistances, +50% damage over time) and Gundar's legacy ability (+800, +30% attack power), 1,880 Vitality before his level: 5,505 at level 10, about 7,400 at his own level 15 | legacy's `ConDefault` (5.x's template is its copy) and legacy's quest bosses built the same way (Gundar, whose ability 5.x reuses for him); legacy's quest witcher of `mq1058` (the Cat witcher: 1,320 Vitality, 30% damage over time, level 25) is of the same size |
| The plague victims (`mq1060_plague_victim_*`, level 14) | `ConDefaultSilver` (5.x's silver-vulnerable human template, also the Blood and Wine succubus's): 25 Essence, 50% fire resistance, 100 light and heavy attack damage | 80 Essence, no fire resistance, no attack damage of its own, stamina regen ×0.25: 733 Essence at level 10 | legacy's `ConDefault` on Essence (legacy gives silver-vulnerable humanoids Essence, `ConHumanoidMonster`); as an Essence user it takes the monsters' per-level bonus (+20 Essence and +15%), so a victim has about 1.7 times a bandit's health at the same level |
| The red-plague creature (`mq1060_evil_spirit`, `red_miasmal`, level 10, a group monster) | Skellige's Hym (`mon_him`: 10,000 Essence) and the leshen (`mon_lessog_base`), the Hym's weapon 150 elemental | nothing of its own: legacy's Hym (1,350 Essence, 50% fire and burning, full bleeding, poison and frost resistance) and leshen (50% physical, 80% force): 4,061 Essence at level 10, its claws 600 elemental | its own abilities, which AI-03 gives legacy's values; its root attack (`W3RedPlagueProjectile`, a leshen root projectile: 200 to 300 or heavy attack + 200 elemental) follows legacy's leshen-roots rule in C2 (AI-18), as the owner confirmed (2026-10-28) |

Their morale and taunt nodes are legacy's `ConDefault`'s since slice B1 (AI-08: morale regen ×0.1, no taunt chance). Not proposed: Reinald's armor (none, like legacy's quest witchers, whose entities include no armor), his and the victims' weapons (Reinald's swords are SWD-10's), their levels (the entities' own; the fake level addon is DIFF's).
- **Deviation:** 5.x's new enemies of `mq1060` get Ghost Mode numbers, proposed by the porter and confirmed by the owner: Reinald's template legacy's `ConDefault` (80 Vitality, no fire resistance), the plague victims' `ConDefaultSilver` 80 Essence without fire resistance or attack damage; the red-plague creature takes legacy's Hym and leshen through its own abilities and its roots legacy's leshen-roots rule (400 rending, attack power, heavy; ported in slice C2) (confirmed by the owner, 2026-10-28).

**Porter's calls** (each follows legacy or has no play effect; all confirmed by the project owner, 2026-10-28, PA7 with legacy's `ConWitcher` and `ConHumanoidMonster`):

| # | Call |
|---|---|
| PA1 | AI-03, AI-04, AI-05: legacy's values for every enemy, NPC and weapon, also where 5.x changed an entry (16 monster abilities: spiders' and boars' resistances, two quest enemies' attack power, the fiend's and the wolf's numbers; the allies' attack and spell power: Vesemir, Keira, Yennefer, `_canBeFollower`); weight-only and price-only changes left to WGT and ECON |
| PA2 | One home per ability: the abilities AI gives whole (with legacy's stamina values in them) leave STAM-08's `gm_npc_stamina.xml`, so two DLC entries never fight over one ability; STAM-08's checks re-run with AI-A |
| PA3 | AI-01: legacy's level model whole, including its rewrite of 5.x's function |
| PA4 | AI-01: guards at Geralt's level +16, as legacy (5.x: +1 to +4); attacking guards stays deadly |
| PA5 | AI-01: wolves, boars, rats and the djinn levelled as legacy (5.x skips them); rats and mice carry `NPCDoNotGainBoost` (AI-06), so nothing changes for them |
| PA6 | AI-01: enemies 6+ and 15+ levels above Geralt get legacy's +33% and +50% damage-over-time resistance (5.x gives them nothing) |
| PA7 | AI-02: legacy's templates also where 5.x changed one (`ConWitcher`), and legacy's `ConHumanoidMonster` where 5.x gave an entity its own silver template; 5.x's `ConDefaultSilver` stays for 5.x's new entities |
| PA8 | AI-06, AI-07: legacy's levels, flags, categories and weakness lists as binary edits of 5.x's entity files (`cr2w_patch.py`, as LOOT); the W3Edit re-save noise (lost attack-range cones, cooked effects) is not reproduced |
| PA9 | AI-14: the fiend's close-range branch moves from FIX to AI; ported (a binary edit of the tree, by REDkit if `cr2w_patch.py` cannot add nodes) only after a check that 5.x's fiends and chorts still do not attack at close range, dropped as fixed otherwise. Outcome (2026-10-28): 5.x's tree already has the branch, so it is not ported (confirmed by the owner, 2026-10-28) |
| PA10 | AI-17: the rotfiend explosion's damage ported with the rest, though EFX saw no real explosion hurt anyone in 5.x |
| PA11 | AI-18: 5.x's +2.5% per Geralt level removed from every projectile (legacy's code has none), ending XBOW-08's temporary deviation |
| PA12 | AI-18: the witch's boiling water uses attack power on both of 5.x's paths |
| PA13 | AI-21: the debug log is not ported |
| PA14 | NG+: legacy's NG+ files equal its regular ones, so the NG+ copies carry legacy's values ([NG+ numbers](../feature-mapping.md#ng-numbers)); 5.x's NG+ ×1.15 dodge and counter chance stays (vanilla's NG+ scaling) |
| PA15 | Attribution: ten unattributed behaviour-tree units the sweep found are STAM-08's (already ported by it); AI added to 345 shared units; the nine bare `AI` placeholders are AI-09 |
