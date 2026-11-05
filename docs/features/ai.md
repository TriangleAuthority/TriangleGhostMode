# AI: enemies, their stats and how they fight

Enemies and NPCs: how much health, attack power, armor and resistance each kind has and how that grows with its level, the weapons they hold, how they dodge, guard, parry, counter, taunt and pick targets, how hits stagger them, and the special rules of particular enemies (the Wild Hunt's Ice Armor, the djinn's rage, the Caretaker's healing, rotfiends, golems, flyers, fistfight opponents). Ghost Mode's changelist has its own section (AI, 1091–1135): "Individual monster armor and resistances changed significantly, armored monsters are indeed armored and you need to deal with it", "Levelup bonuses for NPCs redone ... both armor and resistances are defined by enemy type alone", "AI combat parameters were tweaked to make them react better to player actions", "AI should be better at dodging", "Adjusted AI targeting priorities ... makes Axii Puppet more useful", the Wild Hunt's frost damage and Ice Armor, the djinn, the weakened state, the Caretaker; the bugfix list adds the Wild Hunt bosses' frost slowdown (75), chorts and fiends not attacking (77) and the Caretaker's shovel (101). Sources: those lines, every hand-off to AI ([hand-offs received](#hand-offs-received)), and the code and data, which have more than the changelist (the hit-reaction rules, the level code, the monster projectiles, the fistfights, the arachas' speed).

**What 5.x did in this area** (from `vanilla-5.x`, unverified in game). The enemy data is almost all 1.32's: of the 1,000-odd monster, NPC and weapon entries legacy changed, 5.x changed 39 (the level abilities' sign resistances, the human combat templates' guard and counter rolls, allies' attack power, a few spiders' and boars' resistances, two quest enemies' attack power; [AI-08](#ai-08-combat-parameters), [AI-03](#ai-03-monster-stats)); NPC, monster and secondary weapons are 1.32's. 5.x adds enemies legacy never saw: the witcher Reinald of its new quest `mq1060` (`mq1060_Reinald`, his own sign effects) and a red-plague creature with its own behaviour tree and projectile (DA5). 5.x's monster rework ("attack patterns, counterattacks, movement and effect application of all non-boss monsters") is in the monsters' behaviour trees (`.w2behtree`, from the game files, unverified in game): about 13 monster combat trees changed (the fiend and chort; wolves: pack tactics, the pack leader's howl, reactions on hit; the gryphon family: griffins, basilisks, cockatrices; wyverns and forktails: counterattacks on the counter event, a venom spit; werewolves: five wolves summoned, a full-moon buff on Hard; arachases and endregas: the shell pull after a hit a fixed 15% roll; ghouls: a hop away; drowners: an attacker limit by difficulty, directional dodges; cyclops and ice giants: a taunt as a counter; small changes to the leshen, the Hearts of Stone boar, fugas and gargoyles, golems and elementals), while every other tree equals 1.32's (nekkers, harpies, wraiths, katakans, bears, trolls, sirens, foglets and hags, all of Blood and Wine's monsters, every human defence and tactic tree but one property of `npc_def_parry`), and the entity templates keep their tree assignments. 5.x's new scripted tasks (drowner adds, the three-state charge, summons with a level, drop from above, teleport conditions, ability add and remove, buff immunity, fact check, can-dodge) are used by no tree or monster entity. Of the tasks AI ports, 5.x touched only dodging (a ×1.15 dodge and counter chance in NG+, an instant dodge), the defend task's parry sound, a quest boss's taunt, the new quest witcher's sign effects and the Caretaker's bleed removal. The level code changed: animals, rats and the djinn get no level bonuses, guards are 1–4 levels above Geralt instead of 11–13, the "red skull" bonuses for enemies far above Geralt are commented out, and the level-difference thresholds moved from 6 and 15 to 10 and 20 ([AI-01](#ai-01-level-bonuses)). Every monster and NPC projectile gains 2.5% of its damage per Geralt level when it hits (`W3AdvancedProjectile.OnProjectileCollision`, as XBOW found). The witch's boiling water is rebuilt as a weapon attack. Succubi became silver-vulnerable humanoids (5.x's `ConDefaultSilver`, the same intent as legacy's [AI-02](#ai-02-npc-templates)). 5.x's entity files keep 1.32's levels; they add two buff immunities to many monsters.

**How legacy Ghost Mode implements it.** Data: the monster abilities (`monster_base_abl.xml` and the Hearts of Stone, Blood and Wine and free-DLC files), the NPC abilities (`opp_base_abl.xml` and Hearts of Stone's), the level-bonus abilities (`monster_base_abl_new.xml`), NPC, monster and secondary weapons (`def_item_npcweapons.xml`, `def_item_weapons_mon.xml`, `def_item_weapons_secondary.xml`, the `NPC *` and fist entries of `def_item_weapons.xml`, the expansions' counterparts), all regular and NG+ (legacy's NG+ files equal its regular ones); 422 binary files, nearly all entity templates (levels, stat templates, monster categories, weaknesses, immunities, projectiles, the fiend's behaviour tree). Scripts: the level code (`CNewNPC.AddLevelBonuses` rewritten and split), the behaviour-tree tasks (dodge, defend, parry, taunt, Quen, the toad, the tornado and ground trap), the AI parameters (target weights, taunt timing), hit reactions (`types.ws`), flyers (`CNewNPC.ReactToBeingHit`), Ice Armor (`OnFireHit`, `GetDamageResists`), the special attacks' damage (monster projectiles, ice spikes, leshen roots, boiling water, bird swarms, the toad's acid), fistfights.

Unit lists: [attribution.csv](attribution.csv): mapped 2026-10-27 from the changelist, every hand-off to AI, a field-by-field comparison of every ability and item legacy changed in the monster, NPC and weapon files (`vanilla-1.32` against `legacy-GM` and `vanilla-5.x`), `bindiff.py` over every binary file legacy changed (`vanilla-1.32` against `legacy-GM`, and the entity folders against `vanilla-5.x`), every unit in `npc.ws`, `actor.ws`, `scripts/game/behavior_tree/` and `scripts/game/projectile/`, and sweeps (`unit_sweep.py --unattributed` for dodge, parry, counter, taunt, guard, hit_severity, level, essence, vitality, attack_power, armor, resistance, frost, fist, LastBreath, IceArmor, projDMG). **2,125 units carry an AI feature**: 93 script units, 789 XML units and their 821 NG+ copies, 422 binary files; 1,789 of them were unattributed, 345 are shared (the enemies' abilities with STAM-08's stamina values, the entity files with LOOT's loot, the damage functions with DMG and EFX). Ten unattributed behaviour-tree units the sweep found belong to STAM-08, which ports them already, and are attributed there. Units that only look like AI are handed off ([hand-off](#hand-off-to-other-areas)): the per-difficulty enemy variants, Ciri, the scaling options and fake levels (DIFF), experience (XP), weights and prices. Unattributed units: 5,282 before, 3,493 after. Port status: **AI-A signed off** by the project owner (2026-10-28), after its audit ([AI-A audit](#ai-a-audit-2026-10-28), 2026-10-28: 7 findings, no owner decision; fixed by slices A, T and D, master `b38c0eed`, verified in both trees; [close-out](#audit-close-out)) ([port order](#port-order)): slice A1 (AI-01, AI-02's abilities, DA4's thresholds), slice A2 (AI-03 to AI-05, `MonsterMHBoss`, DA5's proposed numbers) and slice A3 (AI-06, AI-07, AI-02's entity lists) verified in both trees (2026-10-28); the rest mapped (2026-10-27) and analysed against 5.x from the code and data (unverified in game). The owner decided DA1 to DA5, confirmed PA1 to PA15, DA5's numbers and the porter's calls and deviations of AI-A, and signed off AI-A (2026-10-28) ([area decisions](#area-decisions)). **AI-B:** slice B1 (AI-08 to AI-10, legacy's combat rolls, dodging, guarding and taunts) ported and verified in both trees (2026-10-28, master `e5fc2b5c`); slice B2 (AI-11 to AI-13, targeting, poise, flyers forced to land) ported and verified in both trees (2026-10-28, master `cf290eed`); slice B3 (AI-14, monster fixes) ported and verified in both trees (2026-10-28, master `654bc96e`). **AI-B signed off** by the project owner (2026-10-28), after its audit ([AI-B audit](#ai-b-audit-2026-10-28), 2026-10-28: 6 findings; fixed by slices C, D and W, master `be7d5c63`, verified in both trees; [close-out](#ai-b-audit-close-out)); the owner decided F1's combination of slows (an arachas in Yrden or frost moves at the slow's value, [AI-14](#ai-14-monster-fixes)) and confirmed AI-B's porter's calls and deviations (2026-10-28). **AI-C:** slice C1 (AI-15, AI-16: the Wild Hunt, weakened states and the djinn) ported and verified in both trees (2026-10-28, master `c94ce08e`); slice C2 (AI-17, AI-18: instant kills and LastBreath, special attacks and monster projectiles) ported and verified in both trees (2026-10-28, master `78c2e754`); slice C3 (AI-19, AI-20: the Caretaker and quest monsters' immunities, fistfights) ported and verified in both trees (2026-10-28, master `16111528`); AI-21 not ported (PA13). AI-C audited ([AI-C audit](#ai-c-audit-2026-10-28), 2026-10-28: 7 findings, none high); fixes of F2, F3, F4 and F6 made and verified in both trees (2026-10-29, master `6a9fdab3`; [close-out](#ai-c-audit-close-out)); the owner's decisions F1 and F5 implemented as legacy's and verified in both trees (2026-10-29, master `99fd2b88`). **AI-C signed off** by the project owner (2026-10-29); the owner confirmed AI-C's porter's calls and deviations, the last two on 2026-10-29 (the ice spear's 500, the fake level addon in all 71 files). With AI-C, **the AI area is signed off** (2026-10-29); its open checks stay in the entries.

**Size and a proposed split.** AI is the largest area after CRAFT and LOOT by units, and the only one mixing a data overhaul (every enemy's numbers) with behaviour code. It is mapped whole here, with every feature analysed, but ported and audited in three parts (DA1):

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

**Not AI** (to be confirmed by the owner with DA2):

| Subject | Area | Why |
|---|---|---|
| The level-scaling options (none, upscale, match, soft, random), the extra health and damage options, the nonlinear level-up, guards' extra levels option (`W3GameParams.Get*Mult`, `GetEnemyScalingOption`, `ModSignsAddBonuses`, `ModSigns*` abilities, the menu) | DIFF | Options; AI ports the level code with legacy's recommended preset fixed |
| Difficulty multipliers (`difficulty_Common*`), the prologue's attack-power cut (`PrologModifier`), per-difficulty enemy variants (65 abilities and their NG+ copies: `*_hard`, `*_hardcore`, `*_easy`, Olgierd's four, Blood and Wine's) | DIFF | "Difficulty modes" section; DMG handed them to DIFF |
| Ciri's stats (`Ciri_*`, `CiriHardcoreDebuff*`) | DIFF | "Ciri health, armor and damage tweaked accordingly" (Difficulty modes) |
| The fake level addon (the HUD code; `levelFakeAddon` in `mq1028_gerd`, unattributed; the 71 AI files where legacy made a fake level real carry legacy's addon with their level since the AI-C audit, F6) | DIFF | Ported by DIFF-05 (slice D6, 2026-10-30), which ended UI-12's temporary deviation |
| Experience for kills (`CalculateExperiencePoints`, `GetExpByEnemyType`, the `experience` nodes of the level abilities) | XP | Progression |
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
| Flags | balance, needs-decision (DA2, DA4) |
| Depends on | DMG (the formula the stats feed, signed off), DMG-15 (lazy armor fix, called from the same code), DIFF (the options) |
| Skill trees | n/a |
| Port form | the twelve level abilities given whole (`replace`; `AnimalLevelBonus` and `DisplayedLevelAbl` new) in `abilities/gm_ai_levels.xml`, generated by `tools/gen_ai.py`, NG+ copy by `gen_ngplus.py`; `ai/levels.ws`: `@replaceMethod(CNewNPC)` `AddLevelBonuses` (the timer: legacy's body; its scaling by DIFF-04's options since DIFF's slice D5a, DA2's fixed preset before), `OnLevelUpscalingChanged` (emptied), `SetLevel`; `@wrapMethod(CNewNPC)` `OnSpawned` calling `@addMethod` `GMManageNGPLevels` (overrides 5.x's NG+ block); `@addMethod` `GMInternalAddLevelBonuses`, `GMRemoveAllLevelBonuses`, `GMRestoreHealthPerc`, `GMResetLevel`; `@addField` `gmCurrentNGPLevel`; the thresholds as `W3GameParams` defaults (`stamina/staminaCosts.ws`, DA4). DMG-15's armor fix is called from `AddLevelBonuses`, as in legacy. `CActor.IsBeast` is not needed (only DIFF's animal option reads it; XP does not, XP's mapping 2026-10-31) |
| Port status | **signed off** (2026-10-28); ported (slice A1, master `9dfb2078`), verified in both trees (2026-10-28) |
| Open checks | real guards in the world (none near the test save, none reached without teleporting; the guard rule ran on a spawned human set to `ENGT_Guard`); a summon made by a real behaviour tree (the werewolf's wolves, the pack leader's howl; the summon templates spawned by script hold, AI-A audit F7); New Game+ (untested, as every NG+ change) |
| Save impact | none: bonuses are removed and re-added whenever they are recomputed (Geralt's level changed, combat start); an NPC the save already holds keeps the maximum health it was saved with until then (verified, slice A3: Vesemir, in the test save, 6,030 Vitality from 5.x's `ConDefault` until his bonuses were recomputed, then 6,096, legacy's) |
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

**5.x:** 1.32's level abilities but for the commented-out High and Deadly and 0.7% sign resistances for monsters; `AddLevelBonuses` returns early for animals, rats and the djinn (no bonuses at all), puts guards 1–4 above Geralt (1.32: 11–13, more in NG+), drops the deadly blindness immunity, and caches the initial sign resistances (`CheckInitialPercResistances`; nothing in 5.x reads the cached values, `GetInitial*ResistancePerc` have no callers, so legacy's body without it changes nothing); thresholds 10 and 20 (`LEVEL_DIFF_HIGH`, `LEVEL_DIFF_DEADLY`). In the port today enemies have 5.x's model: a level-30 griffin carries about 7,800 Essence of level bonus over its base 500.

**Decisions:** legacy's model (PA3); legacy's guards (PA4), animals, rats and the djinn levelled as legacy (PA5), legacy's damage-over-time resistances for High and Deadly (PA6), all confirmed by the owner (2026-10-28). DA2 (project owner, 2026-10-28): AI ports how enemies grow with level with legacy's recommended scaling fixed until DIFF: enemies at most 6 levels below Geralt, guards 16 above, no nonlinear level-up, no animal halving, no extra health or damage; DIFF later adds the scaling menu, the difficulty multipliers, the per-difficulty variants and the hidden (fake) level bonus. The fixed preset ended with DIFF's slice D5a (master `c994f81d`, 2026-10-30): the scaling follows DIFF-04's options, whose default is the same soft upscaling (DD1); the guards' 16 levels and the animals' halving are options there ([DIFF-04](diff.md#diff-04-enemy-scaling-options)). DA4 (project owner, 2026-10-28): legacy's 6 and 15 levels for "high" and "deadly", which also moves SKL-12's finisher rule (15 levels) and UI-12's red level (6 levels up) back to legacy's values ([skl.md](skl.md#skl-12-axii), [ui.md](ui.md#ui-12-enemy-level-on-the-hud)). The same thresholds are read by 5.x code of other features, which so reads 1.32's values again (AI-A audit F5): quest experience (none for a quest 6 or more levels below Geralt; 10 in 5.x) and the kill-experience bonuses for enemies above Geralt, which legacy rewrote (XP, [hand-off](#hand-off-to-other-areas)); the quest colours in the journal and the "high-level quest" tutorial (1.32's, kept by legacy); not the fistfight opponents' level buffs: their function (`ApplyFistFightLevelDiff`) has no caller in 1.32 or 5.x ([AI-20](#ai-20-fistfights); an earlier statement here was wrong). Lines of legacy's `AddLevelBonuses` that belong to other features come with them: AI-06's level fixes (a free DLC's nekker warrior, the deserters at one encounter) came in slice A3, AI-14's cyclops and arachas lines came in slice B3 (`GMMonsterFixes`). Since A3 rats and mice carry legacy's `NPCDoNotGainBoost` and get no level bonuses (as in 5.x, by legacy's flag instead of 5.x's code). 5.x's cache of the starting sign resistances (`CheckInitialPercResistances`) is dropped with legacy's body (nothing reads it), and `CActor.IsBeast` is not ported (only DIFF's animal option reads it; it came with DIFF-04): porter's calls, confirmed by the owner (2026-10-28).
- `PrologModifier` (an attack-power cut of 30% for enemies on Easy and Normal while Geralt is level 1) is empty since DIFF's slice D1, as legacy emptied it ([DIFF-03](diff.md#diff-03-the-prologues-attack-power-cut), master `0876cf52`, 2026-10-29); until then a temporary deviation. Slice D1 found that 5.x's `OnSpawned` (1.32's) never adds the ability: it tests a local `playerLevel` it never sets, so the cut never applied in 1.32 or 5.x either.

**Verification (slice A1, 2026-10-28, both trees; master `9dfb2078`):** scripted, on frozen hostile test dummies (`gmtest_ai01_spawn()`, then `gmtest_ai01_read()`: bandits at their own level 5, at Geralt's +5, +6, +14 and +15, at level 1, and one set to `ENGT_Guard`; two wolves, a bear, a drowner, a nekker, an arachas, a werewolf, a wraith), at Geralt levels 1, 10 and 30 (`setlevel`), and the same enemies recomputed after Geralt rose from 10 to 30 (`gmtest_ai01_recalc()`, the call combat start makes): 73 checks passed at each level, in each tree. Every enemy had the level legacy's rules give (no raise at Geralt's level 1; at 10 a level-1 bandit raised to 4; at 30 every enemy below 24 raised to 24; the guard 17, 26 and 46), one per-level ability per level above 1, of the kind legacy picks (bandits `NPCLevelBonus`, wolves `AnimalLevelBonus`, the bear, arachas and werewolf `MonsterLevelBonusArmored` (Essence and armor), drowners, nekkers and wraiths `MonsterLevelBonusGroup`), and as many `DisplayedLevelAbl`; High from 6 levels up and Deadly from 15 on hostile humans and monsters, none on wolves (as legacy); maximum health equal to legacy's formula, (template base + n × per-level base) × (template mult + n × per-level mult) + add, times 5.x's Hard multiplier 1.2 (`health_final_multiplier`, DIFF's; legacy's 2 since DIFF's slice D1, which the test reads): a bandit at level 24 has (80 + 23 × 8) × (1 + 23 × 0.15) × 1.2 = 1,409.76 Vitality and attack power base 253, mult 1.23, add 23; the bandits' template part was the same at every level. Shown levels equal the level for every enemy but the wolves, which show 4 more: 5.x's `mon_wolf_base` still adds 4 levels (AI-03's data, slice A2). The definitions (`GMTest_ai01`, in the regression): the level abilities, templates and thresholds read as legacy's; on a throwaway build without the XML and the thresholds all seven checks failed (55 Vitality per level, 270 Essence, `ConDefault` 25, thresholds 10/20). `gen_ai.py --verify`: the 22 abilities equal legacy's in both folders. Regression: `gmtest_regress()` 967 passed, 0 failed in each tree. **Regression checks of the level code** (AI-A audit F4, master `b38c0eed`, `GMTest_ai06_after` in `gmtest_panel()`): a frozen bandit set to level 2 and a drowner set to 6 levels above a set Geralt level P (his own + 20; a test-only `W3PlayerWitcher.GetLevel` override, set and cleared inside the one call), made hostile and recomputed with `RecalcLevel` (combat start's call): the bandit raised to P − 6 with P − 7 `NPCLevelBonus` and `DisplayedLevelAbl`, its maximum Vitality equal to what it had before plus the added per-level abilities' values read from the definitions (714.24 at P 21), no High; the drowner at P + 6 with High and not Deadly; both trees, scripted. On a throwaway build without the soft scaling and the monsters' High lines the bandit's level, count and health and the drowner's High failed.

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
| Port status | **signed off** (2026-10-28); ported: abilities in slice A1 (master `9dfb2078`), the entity lists in slice A3 (master `f9b08de3`), verified in both trees (2026-10-28) |
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

**Decisions:** legacy's templates and lists (PA7, confirmed by the owner, 2026-10-28). Since slice A2 the templates' experience nodes are 5.x's until XP (`ConAthletic`'s, `MiniBoss`'s and `Boss`'s experience; AI-01's level abilities' experience too); their morale and taunt nodes are legacy's since slice B1 (AI-08: `ConDefault`'s morale regen ×0.1, no taunt chance); the new `ConHumanoidMonster` has no 5.x counterpart and stays legacy's whole: legacy's templates also where 5.x changed one (`ConWitcher` 500 Vitality, no attack-power bonus), and legacy's `ConHumanoidMonster` where 5.x gave an entity its own silver template; 5.x's `ConDefaultSilver` stays for 5.x's new entities. The entity lists (slice A3): legacy's removals and additions on 5.x's lists; PA7 there: in the four succubus files where legacy gives `ConHumanoidMonster`, 5.x's own silver abilities leave every list (`ConDefaultSilver`; `sq205_suc` and `mh303_suc`, 5.x's renames of legacy's quest abilities `sq205_succubus` and `qmh303_suc`, which take their place where legacy's file has them). Abilities of later features in these lists came with their slices: AI-08's combat-skill templates and `abl*` abilities with slice B1, AI-14's `ablIgnoreSigns` with slice B3, AI-20's fistfight tiers and `sq301_fistfighters` (which 5.x does not define) with slice C3 (until then a temporary deviation).
- **Deviation:** the crowd succubi (`succubus.w2ent`, `succubus_censored.w2ent`) keep 5.x's hybrid category; legacy left them human (11) and gave only its quest succubi the hybrid category, while 5.x rebuilt these two files with the hybrid category and its own Essence ability, which `ConHumanoidMonster` now replaces. They have no health stats in 5.x at all (non-combat NPCs), so only the category's oils and bestiary entry differ (confirmed by the owner, 2026-10-28).
- **Deviation:** Regis's vampire template (`dlc/bob/data/quests/main_npcs/regis_terzieff_vampire.w2ent`) keeps 1.32's and 5.x's slot component `dettlaff_vampire_base`, which legacy renamed to `man_base` in one slot; legacy's only other change to the file, the `NPCDoNotGainBoost` removal, is ported. Taken for an editor artifact (porter's call, confirmed by the owner, 2026-11-03). In play: whatever that slot attaches to Regis's vampire form attaches as in 1.32; probably no visible difference.

**Verification (slice A1, 2026-10-28, both trees):** scripted: the ten templates read as legacy's (`GMTest_ai01`, in the regression: `ConDefault` 80 Vitality, no fire resistance, no attack damage, stamina regen ×0.25; `ConAverage` 160, `ConAthletic` 320, `ConFrail` 50, `ConFat` 100, `ConPudzian` 150, `ConWitcher` 500 without attack power; `ConHumanoidMonster` 500 Essence; `MiniBoss` +500 health, +50 and +25% attack power, +10%/+20% resistances; `Boss` +1,000, +100 and +50%, +30% sign resistances, +50% damage over time); spawned bandits (`ConDefault`) have 80 Vitality before their level bonuses. `GMCheckConstitutionAbility` is not exercised until A3 gives entities two templates.

**Verification (slice A3, 2026-10-28, both trees; master `f9b08de3`):** spawned entities (scripted, `GMTest_ai06`): every added template present, every removed one gone once the level bonuses ran; the ghostly humans, the dopplers and the quest succubi on Essence (no Vitality) with `ConHumanoidMonster` and counted human; the scavenger boss, the Hakland mage and a `sq209` crewman of Lugos keep only `ConAthletic` (no `ConDefault`); `mh303`'s succubus has legacy's `qmh303_suc` (2,000 Essence: 10,341.6 at her level 15 on Hard = (500 + 2,000 + 14 × 20) × 3.1 × 1.2), neither `ConDefaultSilver` nor `mh303_suc`; the contract monsters (`mh102_arachas`, the `dlc3` cave troll) without `Boss`. The silver sword hurts the humanoid monsters: scripted hits (both trees) 79 to 97 Essence a hit with silver, 1 with steel; a **real** light attack (the input handler, new tree) on the Novigrad succubus dealt 87.8 silver damage.

### AI-03 Monster stats

| | |
|---|---|
| Kind | tuning |
| Pillars | P1, P5 |
| 5.x class | clean |
| Flags | balance |
| Depends on | AI-01, DMG (armor before attack power), STAM-08 (the same abilities' stamina) |
| Skill trees | n/a |
| Port form | every ability `attribution.csv` gives AI-03 (404 since DIFF's slice D1) given whole (`replace`, new ones plain) from legacy's entry by `tools/gen_ai.py` into `abilities/gm_ai_monsters.xml`, but for the nodes of features not ported yet, which carry 5.x's nodes (`LATER`: WGT's `weight`; AI-08's combat rolls, morale and attack tickets since slice B1, AI-12's `hit_severity` since slice B2 and XP's `experience` since XP's slice X1 legacy's); the abilities STAM-08 overrode left `gm_npc_stamina.xml` whole (PA2: 15 remain there since B1); NG+ copy by `gen_ngplus.py`; legacy's NG+-only changes (11 abilities legacy edited only in its `_plus` files) given whole in `abilities_plus/gm_ai_ngplus.xml` (AI-A audit F3); `--verify` compares every ability in both folders with what the game reads |
| Port status | **signed off** (2026-10-28); ported (slice A2, master `cd569312`), verified in both trees (2026-10-28) |
| Open checks | — (5.x's quest succubi get legacy's `qmh303_suc` and `sq205_succubus` through A3's entity lists, verified) |
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

**Decisions:** legacy's (PA1); where 5.x also changed an entry, legacy's value (PA1): 41 nodes (`GEN_AI_PA1=1 python tools/gen_ai.py --verify` lists them): the spiders', boars' and kikimoras' force and will resistance, `q103_werewolf`'s and Letho's attack power, `guardKnight`, `mon_EP2_followernerf`, the wolf's stamina values, and in AI-01's and AI-02's abilities the per-level sign resistances and `ConWitcher`. Three abilities name legacy's per-difficulty variants (`mon_q701_bruxa`, `mon_q703_arena_knights`, `mon_barghest_base`: `*_hardcore`), which 5.x defines only in its NG+ files: in a regular game the reference is empty, as legacy's variants were (DIFF ports them). Legacy also edited 11 abilities only in its NG+ files, undoing 1.32's NG+-only nerfs and boosts so that NG+ equals the regular game (PA14): `mon_wolf_ngnerf`, `q104_evilKeira`, `q503_replacer`, `q302_ReplacerThugs`, `qPhilippa_NG`, `mon_witch3_NGP`, `MonsterLevelBonusLow` and Hearts of Stone's `mon_boarNG_ep1`, `mon_spidersbank_ep1`, `mon_dogs_ep1`, `mon_trapmonsters_ep1`; they are in the NG+ folder only (AI-A audit F3; `gen_ai.py`'s `plus_units`: attributed `_plus` units with no regular unit, which legacy changed and 5.x did not; untested, NG+ policy).

**Two abilities AI-03 missed** (found by DIFF's mapping, ported with DIFF's slice D1, master `0876cf52`, 2026-10-29; porter's call to port them in that slice, not confirmed by the owner): Blood and Wine's tougher archespore `mon_archespor_hard` (legacy: 800 Essence base; 1.32 and 5.x: +1,500 and ×2.2 Essence, −60% attack power) and the barber quest's enemy `mon_q703_mqsidqpyt` (legacy: 200 Vitality base, armor ×60; 1.32 and 5.x: +40% attack power, +150% Vitality, armor ×50) are legacy's whole like the rest (NG+ equal). The second was missed because its XML writes `name ="..."` with a space, which the tools' ability parser did not read; `gen_ench.abilities`, `gen_ai.entry` and `gen_ngplus.py` now accept it (DIFF-02's variants use the same spelling). Verified: `GMTest_ai03`'s generated table reads both as legacy's in each tree, and both failed on a throwaway build without them.

**Verification (slice A2, 2026-10-28, both trees; master `cd569312`):** the definitions (`GMTest_ai03`, in the regression; scripted reads): all 656 abilities AI gives read in game as the port means them: per ability one value that differs from 5.x's (654), and, where legacy changed one, a combat-roll, morale, hit-severity, experience or weight value that still reads 5.x's (132); the expansions' abilities given with `replace` keep every attribute (Hearts of Stone, Blood and Wine, the free DLC). On a throwaway build without A2's XML files, 631 of the 654 values (the rest are A1's) and 6 of the 7 checks failed. Spawned frozen enemies at Geralt's level 10 (`gmtest_ai03_spawn()`, then `gmtest_ai03_read()`, scripted reads, 77 checks): template health, armor, a resistance and the weapon's damage equal legacy's data for each enemy's own abilities: drowner 300 Essence and 50% will, nekker 250, griffin 900 and 15 armor, golem 1,300, 200 armor and 65% physical, arachas 450, 60 armor and 80% force, wolf 80 Vitality and 30% frost, troll 1,080 and 200 armor, fiend 1,350, 60 armor and 100% force; maximum health is A1's formula times Hard's 1.2 (a golem at level 10: (1,300 + 9 × 10) × 2.35 × 1.2 = 3,919.8 Essence); every enemy shows its level, the wolf included (5.x's `mon_wolf` +5 showed 4 levels too many). `gen_ai.py --verify`: no difference in the four folders.

### AI-04 Human NPC armor and allies' stats

| | |
|---|---|
| Kind | tuning |
| Pillars | P1, P5 |
| 5.x class | clean |
| Flags | balance |
| Depends on | DMG-15 (armor from equipment, signed off), DMG-12 (allies' damage) |
| Skill trees | n/a |
| Port form | the abilities `attribution.csv` gives AI-04 (24) given whole by `gen_ai.py` into `abilities/gm_ai_humans.xml` (5.x's nodes for `LATER`, as AI-03), NG+ copy; DA5's two abilities in the same file |
| Port status | **signed off** (2026-10-28); ported (slice A2, master `cd569312`), verified in both trees (2026-10-28) |
| Open checks | — |
| Save impact | none (expected) |
| NG+ counterpart | applied, untested |

**What it does** (changelist 1102): humans' armor counts ("Added different resistances to human armor"): leather 8 → 30 (shock and burning 10%, fire 20%), heavy leather 20 → 45, chainmail 30 → 60, partial plate 40 → 90, full plate 50 → 120 (will, force, bleeding 20%), the Wild Hunt's armor and rear rock armor alike. Allies and quest humans retuned (`_canBeFollower`, Vesemir, Keira, Yennefer, `_q403Follower`, `MedDamage`, `q403BuffUp`, the Hearts of Stone ethereal and Olgierd's default stats, the Hakland mage and soldiers, quest humans moved to the monster file).

**Implementation (legacy):** 30 entries of `opp_base_abl.xml` and Hearts of Stone's, regular and NG+.

**5.x:** 1.32's values; in the port today humans have 8 to 50 armor (DMG-15's note).

**Decisions:** legacy's (PA1); the allies' attack and spell power legacy's where 5.x changed them (`_canBeFollower`, Vesemir, Keira, Yennefer).

**Verification (slice A2, 2026-10-28, both trees):** the definitions (`GMTest_ai03`): NPC armor 30/45/60/90/120, the plate's +20% will, force and bleeding resistance. A Nilfgaardian deserter in plate (`nilfgaardian_deserter_sword_hard`) has 120 armor and 15% physical resistance, a Baron's renegade with an axe 30 armor and 7–10% (scripted reads). **Real hits** in each tree: Geralt's light attack through the input handler on the deserter (`gmtest_swd_hit_a/b`): 22.7 raw slashing against 120 armor and 15% resistance, 26.35 dealt (the port's formula); the deserter, unfrozen with Geralt immortal (`gmtest_ai03_fight_a/b`), hit Geralt five times in 8 s, raw slashing 308 to 349 (its sword's 320 × the 0.9 to 1.1 melee roll) and once 413 to 435 (a stronger attack), each step through Geralt's armor as the formula gives. Scripted hits both ways (`gmtest_ai03_probe`, the damage probe) with the deserter, a golem, a drowner and Reinald matched the formula at every step.

**Fix round fix3 (2026-11-02, sweep C gap 3):** NG+ only: followers' Death March Vitality ×2.5 (`_combatFollowerHardcoreV` in `abilities_plus`, as in the regular game; 1.32 and 5.x NG+ ×6), written by `gen_ai.py`'s `plus_units` into `gm_ai_ngplus.xml`. Offline check only (a regular game does not read `_plus`): `gen_ai.py --check` failed before the regeneration and `--verify` passes after it.


### AI-05 NPC, monster and secondary weapons

| | |
|---|---|
| Kind | tuning |
| Pillars | P1, P5 |
| 5.x class | clean |
| Flags | balance |
| Depends on | DMG-08 (damage from the held item, signed off) |
| Skill trees | n/a |
| Port form | the 214 weapon abilities `attribution.csv` gives AI-05 given whole by `gen_ai.py` into `items/gm_ai_weapons.xml` with 5.x's `weight` nodes (WGT), the NG+ copy `items_plus/gm_ai_weapons.xml` from legacy's `items_plus` entries, with legacy's three NG+-only weapon changes (AI-A audit F3); no item entries (legacy's item changes are scabbards, kept 5.x's, and dismantling parts, prices and weights: CRAFT's, ECON's, WGT's) |
| Port status | **signed off** (2026-10-28); ported (slice A2, master `cd569312`; Hearts of Stone's NPC torch, AI-A audit F2, master `b38c0eed`), verified in both trees (2026-10-28) |
| Open checks | — |
| Save impact | none (expected): NPCs equip at spawn |
| NG+ counterpart | applied, untested |

**What it does** (changelist 1103: "Damage values for NPC weapons tweaked (group enemies deal less damage in general)"): human swords mostly up (Short sword 200 → 300, Skellige sword 1 230 → 320, the rusty swords 150 → 250 with silver 10–20 → 5), monster weapons retuned (arachas 35–50 → 450, cyclops 250 → 550, leshen 250 → 600, alghoul 650 → 350), crit bonuses trimmed; Hearts of Stone's NPC torch 20 → 150 bludgeoning, 3 → 5 silver; Wild Hunt weapons add frost damage (AI-15); secondary weapons (axes, maces, clubs, halberds) retuned; fists: NPC fists' silver damage, magic fists (AI-18).

**Implementation (legacy):** 80 entries of `def_item_npcweapons.xml` (the eight bows are XBOW-08's), 87 of `def_item_weapons_mon.xml`, the `NPC *`, fist, Wild Hunt and shield entries of `def_item_weapons.xml`, `def_item_weapons_secondary.xml`, the expansions' NPC and monster weapons, regular and NG+.

**5.x:** 1.32's.

**Decisions:** legacy's (PA1). Weight and price changes are listed, not ported: 21 weapon abilities carry a legacy weight change (only that in `Knight Mace 1` and `2`), WGT's; legacy's price changes sit in the item entries (ECON's, next to CRAFT-08's dismantling parts). The Wild Hunt's weapons (frost damage, AI-15) and the magic fists (AI-18) came with this slice's data; their code comes with C1 and C2. Legacy's NG+-only weapon changes (PA14: `mon_harpy_weapon _Stats` 650 → 250 rending, `mon_ghoul_lesser_weapon _Stats` 390 → 250, `NPC_Witcher_Silver_Sword_q403_Upgrade _Stats` 100 → 400 silver, as in the regular game) are in `items_plus/gm_ai_weapons.xml` (AI-A audit F3; untested, NG+ policy).
- **Deviation:** NPC swords keep 5.x's scabbards: legacy added scabbard items of its own (`NPC Scabbard 1`, `2`, `Sabre`, `Knight`, `HOS`) to the `bound_items` of NPC swords, items 5.x does not define, while 5.x gives the same swords scabbards of its own (`scabbard_nomansland_lvl2` and the like); the look only (confirmed by the owner, 2026-10-28).

**Verification (slice A2, 2026-10-28, both trees):** the definitions (`GMTest_ai03`): all 213 weapon abilities as meant (the NPC short sword 300 slashing, the arachas's claws 450 rending, the golem's fists 600, the nekker's claws 300). Spawned enemies hold legacy's weapons (scripted reads): drowner 300 rending, nekker 300, griffin 500, golem 600 bludgeoning, arachas 450, wolf 200, troll 550, fiend 600, the deserter's Nilfgaardian sword 320 slashing, the renegade's axe 300, the red-plague creature 600 elemental, the plague victim's club 200. Real and scripted hits: AI-04's. The NPC torch (AI-A audit F2, both trees, 2026-10-28; `gmtest_ai05_torch()`, scripted): 150 bludgeoning and 5 silver in a bandit's hand (5.x 20 and 3); a scripted light attack of the bandit's with it on Geralt dealt 139.5 raw bludgeoning (150 × the melee roll) through his armor as the formula gives; the data table (`GMTest_ai03`) reads it in the regression.

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
| Port status | **signed off** (2026-10-28); ported (slice A3, master `f9b08de3`), verified in both trees (2026-10-28); the deserters' fix only away from its encounter |
| Open checks | the deserters at No Man's Land's encounter gr13 (level 7): only reachable by travelling there |
| Save impact | none for enemies not yet spawned; an NPC the save holds keeps its saved level and maximum health until its bonuses are recomputed (AI-01's save impact) |
| NG+ counterpart | none (entity files have no NG+ copy; NG+ adds its level in code) |

**What it does:** about 285 enemies change level, most by +1 to +5, quest NPCs who should scale like real enemies a lot more (2 → 27, 0 → 30), a few down (−1 to −35); 35 set a level where they had none. Flags: `NPCDoNotGainBoost` and `NoAdaptBalance` added to rats and mice (no level bonus) and removed from 23 others (the vampires, Olgierd, Eredin, Imlerith, Canaris, Lugos's crew and others now level), `NewGamePlusFakeLevel` and `NPCDoNotGainNGPlusLevel` removed with the fake levels (inert in the port: AI-01's NG+ code reads neither), the group flag on the Goldilocks wolf and off on the `mh210` lamia. Code: the nekker warrior of a free DLC's quest (`dlc7`, `sq107`, spawned with the tag `sq107_monster_heavy` from `nekker_lvl3__warrior.w2ent`) forced to level 8, three deserter templates at one encounter (`IsAtLWGR13`) to level 7.

**Implementation (legacy):** 284 entity files (W3Edit re-saves); `CNewNPC.AddLevelBonuses`, `IsAtLWGR13`.

**5.x:** 1.32's levels (no level differs in the entity folders, `bindiff.py vanilla-1.32 vanilla-5.x`).

**Decisions:** legacy's levels and flags as binary edits (PA8). Legacy changed `levelFakeAddon` in 71 of these files, each time making a fake level real (the addon 0 or gone, the level raised: the sergeant 0 + 11 → 11 + 0, Blood and Wine's quest fighters, guards and thugs, Olgierd's men, the Novigrad and Skellige fistfighters, the `q201` stuffed animals 2 + 70 → 16); since the AI-C audit (F6, 2026-10-29) the addon goes with the level (`gen_ai_ent.py`'s `PROPS`), so the HUD, which adds the addon (UI-12), shows legacy's level (before: the level twice, the sergeant 22); in all 71 files, not only the sergeant's (confirmed by the owner, 2026-10-29). The fake levels as such stay DIFF's (DA2), with `mq1028_gerd`'s addon 1 → 0 (no level change; not an AI file). Legacy's W3Edit re-saves sometimes changed a level in only one of a file's two copies (the template's entity object or its compiled copy, `flatCompiledData`: Lugos 17 in the one, the `sq201` werewolf 17 and `sq106_elven_scum` 16 in the other); the port sets both. `GMIsAtLWGR13` reads 5.x's area names (CNames, `'AN_NMLandNovigrad'`; 1.32's were enum values).
- **Deviation:** legacy's two console spawn aliases (`gameplay.xml`'s `succubus_mh` and Hearts of Stone's `golem37`) are not ported: debug shortcuts with no play effect; tests spawn by path (confirmed by the owner, 2026-10-28).
- **Deviation:** six enemy files keep 1.32's empty runtime ability list (the `CCharacterStats` object): Olgierd (`olgierd.w2ent`), the Ofir mage (`q601_ofir_mage`), the Skellige herbarium werewolf (`sq201_herbarium_warewolf`) and three Hearts of Stone boars (`wild_boar_ep1`, `boar_34_normal`, `q603_boar`). Legacy's files carry a filled list (Olgierd's 15 entries: `EtherealActive`, `EtherealSkill_1` to `5`, `difficulty_CommonHardcore`, `all_NPC_ability` and others; the Ofir mage's runtime `currentLevel` 32), which looks like W3Edit's snapshot of a spawned NPC rather than an edit: taken for an editor artifact (porter's call, confirmed by the owner, 2026-11-03). Their levels and `CCharacterStatsParam` abilities, legacy's real edits, are ported. In play: these enemies get their abilities from their templates and the chosen mode, as in 1.32; if legacy's game did use the list, legacy's Olgierd fought with the "Death March!" ability (and his ethereal skills from the start) on every mode, and the port's does not.

**Verification (slice A3, 2026-10-28, both trees; master `f9b08de3`):** `gen_ai_ent.py --verify`: 404 file units, 388 edited (574 edits, among them 285 levels), each file 5.x's (with LOOT's edits) plus exactly the derived edits, CRCs valid, every other object 5.x's byte for byte, every changed value legacy's (or PA7's), every added ability defined; 16 left out (3 smiths for AI-14, 4 `sq301` fistfighters for AI-20, 9 with nothing left to change: 5.x has legacy's spider categories already, or only later features' abilities). In game (`GMTest_ai06`, in the regression; scripted reads of 15 spawned sample entities from `tests/gmTestsAiEntData.ws`, which the generator writes from the edited files): the levels (e.g. the BaW spider 35, the `sq209` vision 17, the cave troll 28, a Skellige bandit 17), categories, abilities and weakness lists the files give; rats carry `NPCDoNotGainBoost` and `NoAdaptBalance` and get no level abilities; the `sq107` nekker warrior at level 8 with its tag, 12 without; `GMIsAtLWGR13` false away from gr13. On a throwaway build with 5.x's entity files (A2's) 38 of these checks failed (the code fix's two passed). Since the AI-A audit (F4, master `b38c0eed`) the nekker check is one comparison, the tagged warrior at 8 and an untagged one at its template's level (12), so it fails without the fix (shown on a throwaway build: 12 and 12); the gr13 check is labelled a negative check only (it fails only if the fix applied away from the encounter; its positive case is the open check). The save's own NPCs: Vesemir (persistent, `NPCDoNotGainBoost`) kept his saved maximum Vitality (6,030, 5.x's `ConDefault`) until `RecalcLevel` (combat start's call), then had legacy's 6,096; the ghouls near the save had legacy's level abilities and health. No guard was reachable from the test save without teleporting.

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
| Port status | **signed off** (2026-10-28); ported (slice A3, master `f9b08de3`), verified in both trees (2026-10-28) |
| Open checks | — |
| Save impact | none (expected) |
| NG+ counterpart | none |

**What it does:** the category decides which oils, bombs and bestiary entry work on an enemy. Spiders specter → insectoid (13; "Spiders fix"), ghostly humans human → specter (13; `q602_everc_*`, `q604_ethereal`, the preacher's ghost), dopplers → relic, succubi → hybrid, `sq209`'s visions → specter; ethereal and `ConHumanoidMonster` enemies still count as human for human rules (finishers, dismemberment, human resistances). The creatures' own weakness lists (12 files: necrophage → insectoid oil for spiders, the Silver Dust bomb for leshens, Axii and Yrden for the djinn), which the bestiary journals mirror (UI-11).

**Implementation (legacy):** 36 entity files (categories), 12 (weaknesses); `CActor.IsHuman`.

**5.x:** 1.32's categories in most of these files, but the spiders (5.x's Hearts of Stone and Blood and Wine spiders are insectoids already) and the succubi (hybrids, AI-02).

**Decisions:** legacy's (PA8): 19 categories and 27 weakness lists edited; where 5.x already has legacy's category, nothing to do. The crowd succubi's category: AI-02's deviation.

**Verification (slice A3, 2026-10-28, both trees):** categories and weakness lists of the spawned samples (`GMTest_ai06`, scripted reads): the Blood and Wine spider insectoid with Golden Oriole and insectoid oil, the fiend relic with relic oil, Samum, Cat and Devil's Puffball, the Hearts of Stone ghosts and `sq209`'s visions specters, the doppler a relic, the succubi hybrids; humanoid monsters count as human (`IsHuman`). **Real oil applications** (`ApplyOil`, the inventory's path) on Geralt's sword, then the attack power a hit on the sample would get (scripted read), in both trees: insectoid oil +25% on the spider, necrophage oil (the spider's old weakness) +0; specter oil +25% on a Hearts of Stone ghost, Hanged Man's Venom (human oil) +0 on it; hybrid oil +25% on both quest succubi; relic oil +25% on the doppler (classic tree).

### AI-A audit (2026-10-28)

Done by a fresh session ([audit](../feature-mapping.md#audit-signing-a-feature-off)) on master `f9b08de3` (port) and `52fd2ae6` (docs), reading code and data, with game runs in both trees. The three slices' commits (master `9dfb2078`, `cd569312`, `f9b08de3`) were read whole; every method they replace, wrap or add was read against legacy's code (`legacy-GM`), 1.32 (`vanilla-1.32`) and 5.x (`vanilla-5.x`). Data, by two scripts written for this audit, independently of `gen_ai.py` and `gen_ai_ent.py`: (1) every `<ability>` of every abilities and items file legacy changed against 1.32 (2,156 regular, 2,352 NG+), compared node by node (tag, type, min, max; tags as sets) with what the game reads in the port: the port's vanilla-path files merged with every Ghost Mode DLC entry of that name (`replace` whole, `extend` sub-nodes in order by tag), flagging `extend` on an expansion's ability and abilities with two Ghost Mode homes; the NPC weapon items' entries compared separately (prices, weights and dismantling parts set aside); (2) every one of the 631 binary files legacy changed, through `cr2w_dump.py` for `vanilla-1.32`, `legacy-GM`, `vanilla-5.x` and the port, the AI-owned properties (`level`, `isMonsterType_Group`, `CCharacterStatsParam.abilities` and `overrideInherited`, `CMonsterParam.monsterCategory`, `CCreatureDataComponent.itemsUsedAgainstCreature`) per object and compiled copy, the port checked against legacy's edit applied to 5.x's value (arrays: legacy's removals and additions on 5.x's list).

**Checked and holding:** the data: every ability attributed to AI-01 to AI-07 reads legacy's value in the port in both folders but for the `LATER` nodes the deviations name (AI-08's rolls, morale and attack tickets, AI-12's `hit_severity`, XP's `experience`, WGT's `weight`; all legacy's since: XP's with XP's slice X1, 2026-10-31, WGT's with WGT's slice W2, 2026-11-02, but AI-19's `Shovel _Stats` weight, kept 5.x's by the owner's decision on the WGT audit's F4); no AI ability has two Ghost Mode homes (PA2) and none is given by `extend` on an expansion's definition; `NPC Long Steel Sword _Stats`, defined in both the base game and Hearts of Stone, reads the port's 250 in game (`GMTest_ai03`); legacy's item changes in the weapon files are scabbards (AI-05's deviation: legacy's `NPC Scabbard *` items are defined nowhere, not even in legacy), prices, weights and parts. The entities: every legacy edit to the owned properties is in the port's file but for the recorded ones (the crowd succubi's intent, PA7's silver abilities, the `LATER` abilities of AI-08, AI-14 and AI-20 in 30 lists, `sq701_tournament_npcs` ported by DEF-06 in script) and the compiled copies set where legacy's re-save left them (Lugos, the `sq201` werewolf and also `sq106_elven_scum`, 11 → 16); the `sq209` spawn set is legacy's body with 5.x's header. The code: `AddLevelBonuses`, `GMRemoveAllLevelBonuses`, `GMInternalAddLevelBonuses`, `GMCheckConstitutionAbility`, `GMManageNGPLevels`, `SetLevel`, `GMResetLevel`, the guard rule and DA2's fixed preset equal legacy's with its options at the preset (the random-level and animal branches and `ModSignsAddBonuses` are DIFF's); `IsHuman` gives legacy's answer (re-evaluated per call instead of cached, so a template added later counts); the nekker warrior's and deserters' fixes are legacy's with 5.x's area names. No 5.x path bypasses the level model: every NPC with an ability manager gets the bonus timer at spawn, combat start and the HUD's focus call `RecalcLevel`, NPCs restored from a save keep their saved bonuses until then (the save impact recorded); summons are entities spawned from templates and get the timer like any spawn, and quest and encounter levels come through `SetLevel`, kept as legacy keeps them. The thresholds: every reader of `LEVEL_DIFF_HIGH`/`DEADLY` was listed (the level code, SKL-12's finisher rule, UI-12's level colour, the quest colours and the "high-level quest" tutorial, quest and kill XP, the fistfight level buffs, the parry-fail chance (no XML gives `chance_to_fail_parry_per_level_diff`: inert), 5.x's Aard-in-Yrden damage (removed by DMG)); none reads 10 or 20 as a literal. `check_modsigns.py` 0 unmarked (428 bodies), no native wrap; `deviations.py --check` current. In game (both trees; Geralt invulnerable with `god()`, level 10 or 30; real light attacks through the input handler, `gmtest_swd_hit_a`, against unfrozen hostile enemies spawned with `spawn()` and `gmtest_spawnat`; levels and health read by script with `gmtest_ai06_near`): a wolf pack (level 4, 181 Vitality) and a Baron's renegade died to the steel sword, a Nilfgaardian deserter in plate at level 16 (+6, 780 Vitality) after a long fight, nekkers and drowners at level 24 (soft scaling at Geralt 30, 2,563 and 2,830 Essence) to the silver sword; a werewolf at 17 and 24 lost health to silver and none to steel; levels shown on the HUD in red with the skull from 6 levels up (screenshots), the black troll at 52 (+22) in red; 20 more monster templates spawned by script (golems, trolls, arachases, leshen, ifrit, wraiths, harpies, a white bear, a lycan, alghouls, a noonwraith) each had legacy's per-level ability and the formula's health, none 0 or absurd; the werewolf's and the summoning task's wolf templates (`wolf_lvl1__summon_were`, `wolf_lvl1__summon`) spawned by script got the same model (level 4, 626 Essence; 20, 1,970). Regression: 1,019 passed, 0 failed in each tree, `gmtest_panel()`'s 72 checks passing.

**Findings:**

1. **The Caretaker's and his shades' quest abilities are empty in game** (high, clear fix; STAM-08's data, AI-19's abilities). `q604_caretaker` and `q604_shades` are Hearts of Stone abilities; STAM-08's `gm_npc_stamina.xml` gives them by `extend`, which empties an expansion's ability ([development.md](../development.md#fine-grained-xml-overrides-50)): `gmtest_ability_probe` reads **0 attributes** for both in game (new tree, scripted read), where 5.x's has 20-odd (the Caretaker's −70% attack power, −20% Essence, 0.8 crit damage reduction, Igni amplifier, resistances; the shades' level and Essence). In play the Caretaker hits about three times as hard as meant and lacks his resistances. `mon_EP2_ffquicki` and `BloodBuff`, the other two `extend`s on expansion abilities, read whole (9 and 2 attributes). Fix: give both whole (`replace`) now, with 5.x's values where legacy's are AI-19's (C3) or with legacy's whole and `LATER` nodes, and leave `gm_npc_stamina.xml` (PA2); add both to a regression check. (DMG's `attack_heavy_noparry` also reads 0 attributes and loses its `attack_heavy` tag and `focus_hit_drain_mod`, beyond the recorded attack power: for DMG.) **Fixed** (fix slice A, master `b38c0eed`), **verified** in both trees: legacy's whole abilities with `mon_caretaker_ep1`, which legacy rewrote with them (details and the temporary `mon_wild_hunt_default` deviation in [AI-19](#ai-19-the-caretaker-and-quest-monsters-immunities)); `attack_heavy_noparry` given whole as legacy's ([dmg.md](dmg.md#dmg-01-damage-formula)); the regression reads all four. A sweep of every Ghost Mode DLC `extend` against the definitions' homes in `vanilla-5.x` finds no other expansion ability but Blood and Wine's `BloodBuff` and `mon_EP2_ffquicki`, which read whole.
2. **Hearts of Stone's NPC torch keeps 5.x's damage** (low, clear fix; missed unit). Legacy raised `NPC torch _Stats` (`dlc/ep1/.../def_item_weapons.xml`) from 20 to 150 bludgeoning and 3 to 5 silver; it is unattributed and not ported: the game reads 20/3 (`gmtest_ability_probe`, scripted read). Fix: attribute it to AI-05 and give it whole (with its NG+ copy). `Caretaker Shovel _Stats` (legacy's new ability in the same file, 400 slashing, 80 silver) is unattributed too: attribute it to AI-19. **Fixed** (fix slice A, master `b38c0eed`), **verified** in both trees: the torch 150/5 in a bandit's hand and in a scripted hit ([AI-05](#ai-05-npc-monster-and-secondary-weapons)); `Caretaker Shovel _Stats` attributed to AI-19, ported with the shovel in C3 (its two item entries must name it).
3. **Fourteen NG+-only changes of legacy's are not ported** (low, NG+ only, clear fix). Legacy also edited abilities only in its `_plus` files, to undo 1.32's NG+-only nerfs and boosts (so its NG+ equals its regular game, PA14): `mon_wolf_ngnerf`, `q104_evilKeira`, `q503_replacer`, `q302_ReplacerThugs`, `qPhilippa_NG`, `mon_witch3_NGP`, `MonsterLevelBonusLow`, the Hearts of Stone `mon_boarNG_ep1`, `mon_spidersbank_ep1`, `mon_dogs_ep1`, `mon_trapmonsters_ep1`, and the weapons `mon_harpy_weapon _Stats` (legacy 250 rending, the port 650), `mon_ghoul_lesser_weapon _Stats` (250, port 390), `NPC_Witcher_Silver_Sword_q403_Upgrade _Stats` (400 silver, port 100). They are attributed (AI-03, AI-05) only on their NG+ rows, which `gen_ai.py` does not read; `gen_ngplus.py` copies only the regular ones. Fix: let the generator give legacy's `_plus` entries that differ from legacy's regular ones (or every attributed `_plus` row) in the NG+ files. Untested in game (NG+ policy). **Fixed** (fix slice A, master `b38c0eed`): `gen_ai.py` gives the attributed `_plus`-only entries legacy changed and 5.x did not (exactly these 14; nine more attributed `_plus` rows are tag fixes 5.x made too) in `abilities_plus/gm_ai_ngplus.xml` and `items_plus/gm_ai_weapons.xml`; `--verify` checks them (465 and 217 abilities as meant in the NG+ folders). Untested in game (NG+ policy).
4. **The regression does not exercise the level code, and one check cannot fail** (low, test-only, clear fix). `GMTest_ai01` reads only the definitions; the soft scaling, the guard rule, the per-level ability counts and High/Deadly run only in the manual `gmtest_ai01_read()`; the regression's only level-code checks are `GMTest_ai06_after`'s (rats without bonuses, the nekker warrior's fix). `GMTest_ai06_after`'s "the deserters' level fix does not apply away from gr13" passes for a `GMIsAtLWGR13` that always returns false, and "a nekker warrior without the tag keeps its template's level" passes without the fix. A later replacement of `AddLevelBonuses` (AI-14 adds lines in B3) could break the model unnoticed. Fix: add a hostile spawn at a set Geralt level to `GMTest_ai06`/`_after` (a bandit far below Geralt raised to 6 below with its `NPCLevelBonus` count and health; a monster 6 above with High), and say that the gr13 check is a negative only. **Fixed** (fix slice T, master `b38c0eed`), **verified** in both trees: the level-code checks ([AI-01](#ai-01-level-bonuses)), the nekker comparison and the gr13 label ([AI-06](#ai-06-enemy-levels-and-flags)); on a throwaway build without the soft scaling, the monsters' High lines and the nekker fix, in game, the bandit's three checks, the drowner's High and the nekker check failed (and the data table's and `attack_heavy_noparry`'s, with the old XML); on the real build all pass.
5. **DA4's other readers are not recorded** (low, doc-only). Besides SKL-12 and UI-12, the 6/15 thresholds also move 5.x's quest XP (no experience for a quest 6 or more levels below Geralt, 10 before), the kill-XP bonuses, the quest colours and high-level quest tutorial, and the fistfight level buffs (full at 7 levels up, 11 before): 1.32's values, but legacy rewrote quest and kill XP (XP) and the fistfight buffs (AI-20). Fix: name them under DA4 and in the XP and AI-20 entries' hand-offs. **Corrected** (fix slice D): [AI-01](#ai-01-level-bonuses)'s DA4, [AI-20](#ai-20-fistfights), the XP [hand-off](#hand-off-to-other-areas).
6. **Small doc inaccuracies** (doc-only). AI-01's 5.x paragraph says SKL-08 and SKL-09 bypass `CheckInitialPercResistances`: nothing in 5.x reads the cached values at all (`GetInitial*ResistancePerc` have no callers), so dropping it changes nothing. AI-02's second deviation names "Imlerith's shieldmaiden fight": the files are `mq2038_gundar` and `mq2038_shieldmaiden` (Skellige), plus the test template `enemy_2handed_sword`. AI-06's twin-copy note names Lugos and the `sq201` werewolf; `sq106_elven_scum` is a third. **Corrected** (fix slice D) in AI-01, AI-02 and AI-06.
7. **Not verified in game** (no action; open checks). A summon made by a real behaviour tree (the werewolf's wolves, the pack leader's howl: none came in a one-minute fight; the summon templates spawned by script hold); whether any tree uses 5.x's `CBTTaskSummonCreaturesWithLevel`, which would give the summons their summoner's level through `SetLevel` (the mapping read the trees; the audit could not, the bundles being compressed); real guards; the deserters at gr13; New Game+. Kept as open checks in the entries.

**Autosave:** the game wrote `<save name>` during the new-tree run; the test save is unchanged.

**Not reviewed:** AI-B and AI-C entries beyond the hand-offs AI-A touches; legacy's own behaviour in play.

**Suggested fix slices:** **A** (data): F1 (with STAM-08's entry and AI-19's), F2, F3, `gen_ai.py --verify` and the `_plus` rows; **T** (tests): F4; **D** (docs): F5, F6. No owner decision is needed. **Done** (2026-10-28, master `b38c0eed`, one commit), verified in both trees.

#### Audit close-out

Closed 2026-10-28: every finding is fixed, corrected or recorded; no owner decision was needed. Fixed and verified in both trees: F1, F2, F3 (data; F3 untested in game, NG+ policy), F4 (tests), all in master `b38c0eed`. Corrected in the docs: F5, F6. Recorded: F7 (the open checks). New: a temporary deviation, the Caretaker's inherited `mon_wild_hunt_default` until AI-15 ([AI-19](#ai-19-the-caretaker-and-quest-monsters-immunities)). Checks at close: regression 1,020 passed, 0 failed in each tree, `gmtest_panel()`'s 77 checks passing; `gen_ai.py --check` and `--verify`, `gen_ngplus.py --check` current; `check_modsigns.py` 0 unmarked (428 bodies), no native wrap; `deviations.py --check` current. No autosave was written. What stays open: the open checks (F7: real summons from a behaviour tree, real guards, the gr13 deserters, New Game+). **AI-A signed off** by the project owner (2026-10-28), with the open checks kept open.

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
| Port status | **signed off** (2026-10-28); ported (slice B1, master `e5fc2b5c`), verified in both trees (2026-10-28) |
| Open checks | teleport and dash chances (no wraith, noonwraith or bruxa fought); the reworked gryphon family and wyverns in a fight; New Game+ (untested, as every NG+ change) |
| Save impact | none (expected) |
| NG+ counterpart | applied, untested; 5.x's NG+ ×1.15 kept (PA14) |

**What it does** (changelist 1114: "AI combat parameters were tweaked to make them react better to player actions"; 1116): the behaviour trees' rolls are retuned per enemy and template: dodge chances evened out (light attacks mostly 20%, 40–60% for nimble monsters; bears and endregas 95% → 20%), counters on most monsters (20–60%, golems 100% → 80%), counters and guards rolled from the first hit (`hits_to_roll_counter`, `hits_to_raise_guard` 2–3 → 0) and rising per hit (+10%), humans' guard and counter 70% → 30%, taunts 25% → 10%, teleport and dash chances, `hit_severity` zeroed (AI-12).

**Implementation (legacy):** about 140 abilities (`mon_*_base`, the `Skill*` human templates, the Wild Hunt's), regular and NG+.

**5.x:** about 13 monster combat trees reworked (see the area's introduction); the human trees unchanged. 5.x's own XML changes to the rolls are only `mon_bies_base` (dodge 15% → 35%, counter 15% → 30%, after 1 hit) and `mon_wolf_base` (dodge 20/40% → 40/50–60%), both of which legacy sets; the human templates' waits randomised (2–4 hits) and counter chance 50–75%; dodge and counter ×1.15 in NG+. Legacy's chances still reach the reworked moves (the fiend's new dodge, the wolves' circular dodge and counters, the wyverns' counters, the cyclops's counter-taunt); some moves bypass them: the gryphon family's instant dodges within 3 m and its charge out of a block, the arachas's 15% shell roll, the ghoul's hop away, the wolves' hit reactions, the attacker limits by difficulty.

**Who reads the rolls** (5.x's behaviour trees, `tools/unbundle.py` over the game's 389 `.w2behtree` files, 2026-10-28; unverified beyond the fights below): the dodge chances (`dodge_*_chance`) are read only by the dodge tasks (`CBTTaskDodge`, `CBTTaskCircularDodge`), which 29 trees use: the human sword and axe trees, the drowner, ghoul, grave hag, gryphon family, harpy, katakan, noonwraith, pesta, siren, werewolf, witch, wraith and fiend trees, the nekker, wolf and barghest trees (circular dodge), and Blood and Wine's big bad wolf, bruxa, fairytale witch, fleder, gravier, sharley and wight. The bear's, golem's, troll's, arachas's, wyvern's, ice giant's and djinn's trees have no dodge task, so their dodge chances are inert data (in 1.32 too: the trees are 1.32's); legacy's bear 95% → 20% changes nothing in play. The gryphon family's tree (griffins, basilisks, cockatrices) has a dodge task but sets `ignoreDodgeChanceStats`, so every roll says yes and its dodge chances are inert too (AI-B audit F5: 16 of 16 and 6 of 6 rolls at legacy's 20%, both trees; few start a dodge, 3 of 16). Guard and counter chances are rolled by the hit reaction (`CBTTaskHitReactionDecorator`, the monsters' base combat tree), the additive hit (`BTTaskAdditiveHitListener`, 29 trees: bear, golem, fiend, wyvern, ...), the parry task (`CBTTaskPerformParry`, humans) and the dodge task's counter; a monster's guard or counter is rolled only on a hit that plays a (additive) hit reaction (hits below 1 damage play none, DMG-01). The taunt chance is read by the taunt task (46 trees), which no tree sets to roll it in 5.x (AI-10). Moves of 5.x's reworked monsters that bypass the chances keep 5.x's behaviour: the gryphon family's instant dodges within 3 m and its charge out of a block, the arachas's fixed 15% shell pull, the ghoul's hop away, the wolves' hit reactions, the attacker limits by difficulty (from the mapping).

**Decisions:** DA3 (a) (project owner, 2026-10-28): legacy's dodge, counter, guard and taunt chances on every enemy, including the monsters 5.x reworked. XP's `experience` and WGT's `weight` nodes in these abilities stay 5.x's (`LATER`); AI-12's `hit_severity` is legacy's since slice B2. `PART` also takes legacy's node for an AI-08 tag where legacy kept 1.32's value and 5.x changed it, as the abilities AI gives whole do (PA1): `SkillShield`'s counter chance is legacy's 0.4 (5.x 0.3 to 0.5; AI-B audit F3, master `be7d5c63`; `GMTest_ai08` reads it).

**Note for the balance pass** (2026-10-28; not a deviation; confirmed by the owner, 2026-10-28): bears, endregas and golems (and the other monsters whose trees have no dodge task: trolls, arachases, wyverns, ice giants, the djinn; and griffins, basilisks and cockatrices, whose tree ignores the chances) carry legacy's dodge chances as data, but nothing reads them, so they have no effect in play, as in 1.32 and legacy. Whether those numbers should drive anything is for the balance pass; until then they stay legacy's, inert (confirmed by the owner, 2026-10-28).
Until slice C1 the AI-08 abilities that belong also to AI-15 or AI-16 (the Wild Hunt's generals and minions, Caranthir's and Imlerith's phase abilities, the djinn) carried legacy's combat rolls and stamina values with 5.x's other nodes (a temporary deviation, confirmed by the owner, 2026-10-28); since C1 they are legacy's whole ([AI-15](#ai-15-the-wild-hunt)), and the deviation ended.

**Verification (slice B1, 2026-10-28, both trees; master `e5fc2b5c`):** the data: `gen_ai.py --verify` (487 abilities in `abilities/`, 465 in `abilities_plus/` as meant; 50 nodes where legacy's value replaces a 5.x change, PA1), `gen_ai_ent.py --verify` (391 files, 589 edits); in game (`GMTest_ai03`'s generated table, now reading AI-08's nodes as legacy's, and `GMTest_ai08`, in the regression, scripted reads): bears and endregas 20% light-attack dodge, golems 80% counter from the first hit, the human templates guarding and countering from the first hit with +10% guard per hit, Eredin's rolls legacy's with his 5.x Essence, `ConDefault`'s morale regen ×0.1. STAM-08's stamina values in the 26 abilities that moved from `gm_npc_stamina.xml` are unchanged (compared node by node; the only difference, legacy's removed nodes written as 0 there and absent now, reads the same). **Real fights** (`gmtest_ai08_fight_a/_b`: the enemy spawned hostile 3 m ahead, Geralt's real light attacks through the input handler every 1.4 s, both sides' stamina and the enemy's health refilled at each swing, test probes logging every roll the enemy's AI makes, with its chance and outcome), legacy's chance (5.x's in brackets):

| Enemy, tree | Swings | Rolls seen (yes of asked, at the chance read) |
|---|---|---|
| Bandit (`sq107_bandit_lvl1_mortal`; its numbers are `SkillThug`'s), classic tree | 30 | dodges 7 of 23 at 20% (0%); guard from the first hit at 20%, 30%, ... 80% at the 7th hit in a row (40% after 3 hits), 5 guards of 14; counters after the parry task 1 of 8 at 20–30% (30% after 2 hits); one dodge started out of its own attack |
| Bandit, new tree | 16 (killed) | dodges 0 of 10 at 20%; guards from the first hit 20% +10% per hit, 2 of 6; counters 1 of 6 and 0 of 5 at 20–30% |
| Wolf (`wolf_lvl1`, 5.x's reworked tree, circular dodge), classic / new | 30 / 30 | dodges 2 of 20 / 3 of 19 at 20% (40%); counters in hit reactions from the first hit at 20% +10% per hit, 5 of 13 / 3 of 11 (50% after 2 hits, +25%); never a guard (`hits_to_raise_guard` −1) |
| Fiend (`bies_lvl2`, reworked), classic | 30 | dodges 0 of 4 at 20% (35%); counters in additive hits from the first hit at 60%, 80% at the third, 7 of 10 (30% after a hit, +35%) |
| Golem (`golem_lvl2`, its armor set to 0 by a test ability so level-1 hits play reactions), classic | 30 | guard from the first hit at 60% +10% per hit, 5 of 5; the counter read 80% at the first hit (5.x: guard 100% after 3 hits, counter 100% after 2) but every roll ended in the guard first; taunts 8 of 89 rolls at 10% (5.x: no roll) |
| Bear (`bear_berserker_lvl1`), classic | 25 | no dodge roll (no dodge task in its tree); one counter roll, at 40% (0% after 3 hits) |


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
| Port status | **signed off** (2026-10-28); ported (slice B1, master `e5fc2b5c`), verified in both trees (2026-10-28) |
| Open checks | the reaction task's fix: no 5.x behaviour tree uses `CBTTaskReaction` (the 389 trees read, 2026-10-28), so the fix and its guard are inert until a tree does; the 0.25 s window and the missing delay are not timed separately (dodges were seen, not their timing) |
| Save impact | none |
| NG+ counterpart | none |

**What it does** (changelist 1116: "AI should be better at dodging"): an enemy has 0.25 s (0.1) after an incoming attack's dodge signal to start its dodge, with no minimum delay between dodges, also out of its own attack, without overlapping dodges, and only within 3 m of its target (5 m); never in the air or off the ground. `CBTTaskReaction.Main` dodged when `ChooseAndCheckDodge` said no (a vanilla bug in 1.32 and 5.x): fixed, with DEF-06's stun guard on that check (the DEF audit's F12 left both for AI). The NPC dodge's minimum distance (1.7 m) is vanilla's, unchanged.

**Implementation (legacy):** `CBTTaskDodge` (`<members>`, `IsAvailable`, `OnActivate`, `OnDeactivate`, `Dodge`, `ChooseAndCheckDodge`, `OnListenedGameplayEvent`), `CBTTaskDodgeDef`, `CBTTaskCircularDodge.ChooseAndCheckDodge`, `CBTTaskReaction` (`Main`, `ChooseAndCheckDodge`, `OnGameplayEvent`).

**5.x:** 1.32's task with an instant dodge option (`instantActivation`) and the NG+ multiplier. One tree sets `allowDodgeOverlap` (default true), three `allowDodgeWhileAttacking` (the bruxa, the fiend, the gryphon), three `minDelayBetweenDodges`, 18 `maxDistanceFromTarget` (those keep their own distance; the others take the new default).

**Decisions:** legacy's; 5.x's instant dodge (`instantActivation`, used by no tree) and NG+ ×1.15 kept (PA14).

**Verification (slice B1, 2026-10-28, both trees):** the default distance (`GMTest_ai08`, in the regression: a new `CBTTaskDodgeDef` reads 3). Dodges out of the enemy's own attack: in the real bandit fight (classic tree) the dodge task rolled 9 times while the bandit was attacking (5.x refuses before the roll) and once started a dodge from it (probe log, `attacking=true`). The air guard (`gmtest_ai09_air`, scripted reads in a real encounter, classic tree): a harpy spawned hostile (`spawn('harpy', 1, 8, true)`) read not on the ground at 1.7 to 7.5 m above it and `GMEnemyCannotDodge` true in four reads 2.5 s apart; the horses nearby on the ground, false.

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
| Port status | **signed off** (2026-10-28); ported (slice B1, master `e5fc2b5c`), verified in both trees (2026-10-28) |
| Open checks | the defend task ending on the blocked hit and the 2 s protection of the counter (golems, drowners, ghouls use it; not isolated in the fights); the monster taunt timing in a fight (only the defaults read) |
| Save impact | none |
| NG+ counterpart | none |

**What it does:** hits and blocks count towards an enemy's guard and counter for 2.5 s (2 s); the defend pose ends on the hit it blocked and keeps the enemy's counter from being interrupted (no hit animation for 2 s); a broken shield lowers the guard and does not stagger its holder; the taunt always rolls the enemy's XML chance (which changes little in play: the roll repeats every tick); monsters taunt every 5 s (3) and force an attack after 10 s (20).

**Implementation (legacy):** `CActor.IncHitCounter`, `IncDefendCounter`; `CBTTaskDefend.OnGameplayEvent`, `OnDeactivate`; `CBTTaskTaunt.IsAvailable`, `CBTTaskTauntDef`; `CAIMonsterTauntParams`; `CNewNPC.ProcessShieldDestruction`.

**5.x:** 1.32's, plus a parry sound on blocked damage and a quest boss that never taunts (`mq1060_pv_boss`). No tree sets `useXMLTauntChance`, so in 5.x the taunt task never rolls: every enemy taunts whenever its delay allows. With legacy's rule the task rolls the enemy's `taunt_chance` (AI-08's values: 10–25% for most; wolves 100%) at each check after the delay, but it re-rolls every tick, so a 10% chance passes within a moment: in play taunts come about as often as in 5.x (AI-B audit F4: a noonwraith and an idle Geralt for 45 s, the port 3 taunts 10 to 16 s apart, 5.x 4 taunts 12 to 13 s apart). The timing comes from the delays (5 s, 10 s) and the tree, not the chance.

**Decisions:** legacy's; 5.x's `mq1060` taunt line kept (5.x's new content).

**Verification (slice B1, 2026-10-28, both trees):** the defaults (`GMTest_ai08`, in the regression: a new `CBTTaskTauntDef` rolls the XML chance, `CAIMonsterTauntParams` 5 s and 10 s). The counters' window (`gmtest_ai10_window_a/_b`, scripted, each tree): a spawned deserter's hit and defend counters raised once read 1 and 1 at 2.25 s and 0 and 0 at 2.75 s (timers on the NPC). A broken shield (`gmtest_ai10_shield`, scripted call of the function bombs, Axii, Iris and STAM-08 use, on a Nilfgaardian deserter with a shield in a real fight, each tree): it held its shield with the guard up; afterwards not staggered, the guard down (`bShieldUp` 0), the shield dropped. Taunts (golem fight, real): 8 of 89 rolls at 10%. **Regression** (AI-B audit F2, master `be7d5c63`, scripted; `GMTest_ai10` in `gmtest_regress()`, `GMTest_ai10_after` in `gmtest_panel()`): a spawned frozen deserter's counters raised once read 1 and 1 at 2.25 s and 0 and 0 at 2.6 s (its timers, during `gmtest_regress()`'s 3 s wait); a spawned shield bearer, neutral to Geralt (5.x's stagger names him its creator, and negative effects from a friendly creator are refused), not staggered and its guard 0 after `ProcessShieldDestruction` (a frozen NPC's graph does not take `RaiseShield`, so the guard going down is shown by the fight above). Both failed on a throwaway build with 5.x's counters and shield code (0 and 0 at 2.25 s; staggered).

**Tests shown failing without the slice** (a throwaway build: master `e5fc2b5c` with the DLC and entity files, `enemyDefense.ws` and no `ai/dodge.ws`/`ai/defence.ws` as at `b38c0eed`, the tests kept; classic tree): the regression 1,019 passed, 10 failed (the generated data table, 15 values; the entity lists' combat-skill templates, 2; `GMTest_ai08`'s eight checks of rolls and defaults); the counters' window read 0 and 0 at 2.25 s; the broken shield left its holder staggered with the guard up. On the real build all pass.

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
| Port status | **signed off** (2026-10-28); ported (slice B2, master `cf290eed`), verified in both trees (2026-10-28) |
| Open checks | a real Axii Puppet cast (the fights used Axii's puppet effect added by script, with the real AI on both sides); NPCs the save itself holds (the fights spawned theirs) |
| Save impact | none: the weights are class defaults, read by the native target selection from each NPC's parameter object (entities store only values that differ from the defaults; 8 of 5.x's entity files set `playerWeight` themselves and keep theirs, as in legacy: Blood and Wine's garkains, the `q701` bruxa, the `q704` monster-hunt vampire, a `q206` berserker) |
| NG+ counterpart | none |

**What it does** (changelist 1117–1118): enemies attack whoever hurts them first and no longer single out Geralt: hitter weight 20 → 30, current target 9 → 20, player 1,000 (monsters) or 100 (NPCs) → 15, monsters for NPCs 101 → 25. A puppet draws its victims' attacks.

**Implementation (legacy):** `CAIBaseMonsterCombatParams.<members>`, `CAINpcCombatParams.<members>`.

**5.x:** 1.32's weights. The target selection is native; it adds the weights to a distance term (`distanceWeight` 30 over `maxWeightedDistance` 30) and the hostile-actor weight (10), so with legacy's weights a nearer enemy or one that hits wins over Geralt, while 5.x's 1,000 or 100 for the player nearly always wins.

**Decisions:** legacy's.

**Verification (slice B2, 2026-10-28, both trees; master `cf290eed`):** the weights (`GMTest_ai11`, in the regression, scripted reads of new parameter objects: monsters and flyers 15, 30, 20; humans 15, 30, 20, 25). **Real fights** (`gmtest_ai11_a/_b`: the enemy hostile, the ally next to it, both run by their own AI and kept alive, Geralt immortal and idle; the enemy's target sampled every 0.5 s, every hit between them counted), against a throwaway build with 5.x's weights (the same tests):

| Fight | Port | 5.x's weights |
|---|---|---|
| A bandit, a Nilfgaardian deserter under Axii's puppet effect (added by script, real AI) beside it, Geralt 20 m away, new tree | Geralt 1, puppet 41 of 42 samples (from the second sample on); 8 puppet hits on it, none on Geralt | Geralt 33, puppet 9 of 42; 10 puppet hits on it |
| A bandit and a bandit puppet, Geralt 14 m away, classic tree | turned on the puppet at its first hit (4.5 s) and stayed: Geralt 8, puppet 14 of 22 | — |
| A wolf, a friendly deserter hostile to it, Geralt 14 m away, classic tree | Geralt 58, ally 10 of 68: the wolf turned on the ally after 16 of its hits | Geralt 53 of 53; 11 ally hits |

A puppet fight with Geralt 14 m away in the new tree stayed on Geralt (41 of 41, 7 puppet hits): the enemy had reached Geralt before the puppet's first hit, and the current target's weight and the distance then favour him. So the rule works as legacy's numbers say: whoever is nearer or hits draws the attacks, not always Geralt.

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
| Port status | **signed off** (2026-10-28); ported (slice B2, master `cf290eed`), verified in both trees (2026-10-28) |
| Open checks | ranged hits (bolts, signs) on a huge enemy in a fight (the fights used melee; other hits are covered by the regression's crafted hits); a real elemental (a spawned frozen one read the flying stance, which exempts it) |
| Save impact | none |
| NG+ counterpart | none |

**What it does** (changelist 1095–1097): "the bigger they are, the less severe their hit reaction is". Melee hits on enemies up to 2 m tall are left to parries and counters; any other hit (not parried, countered, dodged or damage over time) loses one step of hit reaction (heavy → light → none) when it takes less than 3% of the victim's health and two below 1%, the thresholds scaled up by the victim's height over 2 m; golems never react to hits; flyers are exempt. The unused `hit_severity` stat is no longer read. "Huge" (`IsHuge`, which other rules read) means a capsule taller than 2 m instead of the `mon_type_huge` ability.

**Implementation (legacy):** `ModifyHitSeverityReactionFromDamage` (its second half), `ModifyHitSeverityReaction`, `ModifySeverity`, `CActor.IsHuge`, `CActor.GetCapsuleHeight` (STAM-06).

**5.x:** 1.32's. No 5.x ability sets `hit_severity` (legacy adds it, at 0, to the 17 human combat-skill templates and the Wild Hunt's three generals), so 5.x's `ModifyHitSeverityReaction` never changes a reaction either; replacing it changes nothing in play. **Movement capsules** (read in game, 2026-10-28): humans, bears, harpies, cave and ice trolls, werewolves 1.8 m, griffins 1.5 m; wyverns 2.1, horses 2.35, leshens 2.7, golems and earth elementals 3.1, fiends 4, cyclopes and ice giants 5. So under legacy's rule trolls, werewolves and griffins are no longer "huge" (5.x's `mon_type_huge` makes them so) and fiends, leshens, wyverns, golems and horses are; `IsHuge` is read by Mutation 4's reach and by Retribution (ENCH). Elementals carry `mon_golem_base`, so they never react to hits either.

**Decisions:** legacy's. "Huge" follows legacy's capsule rule (taller than 2 m), with its effect on Mutation 4's reach and Retribution (confirmed by the owner, 2026-10-28). A2's temporary deviation (5.x's `hit_severity` in the abilities AI gives whole) ended with this slice.

**Finding for the owner** (legacy's code, not a deviation): golems never react to hits, so they also never roll their guard or counter, which the monsters' additive-hit listener rolls only on a hit that plays a reaction (AI-08): in a real golem fight on the port (12 swings, 6 hits, classic tree) no guard or counter roll came, where slice B1, before AI-12, saw 5 guards of 5 and a counter chance of 80%. Legacy's code combines the same two rules, so its golems presumably did the same ([legacy test](../open-questions.md#to-test-in-legacy-ghost-mode)); AI-08's golem guard and counter numbers are then inert, a point for the balance pass. The owner confirmed it (2026-10-28): golems never guard or counter, because they never react to hits.

**Verification (slice B2, 2026-10-28, both trees; master `cf290eed`):** `GMTest_ai11_after` (in `gmtest_panel()`; crafted hits of Geralt's through `GMZeroSubOneDamage`, where `ReduceDamage` calls it, on spawned frozen NPCs set to the ground stance): a bandit (1.8 m) keeps a heavy melee hit at 0.5% of its health; a non-melee heavy hit becomes none and no animation at 0.5%, light at 2%, stays heavy at 5%; a fiend (4 m, thresholds ×3) loses a heavy melee hit at 1.5%, has it light at 6%, heavy at 12%; a golem has no reaction and no animation from a 30% hit; `IsHuge` follows the capsule (the fiend yes, the cave troll no). **Real fights** (B1's `gmtest_ai08_fight_a`, real light attacks through the input handler; a probe logs each hit's reaction before and after the rule; `gmtest_ai11_poise`):

| Enemy | Classic tree | New tree |
|---|---|---|
| Bandit (1.8 m) | 6 hits, none lowered, each with its reaction | 3 hits, none lowered |
| Fiend (`bies_lvl2`, 4 m, level 28: a hit took 0.16% of its health) | 5 hits, all lowered from light to none, no animation | 4 hits, all lowered |
| Golem (`golem_lvl2`, armor set to 0 so the hits deal damage) | 7 hits, all lowered to none, no animation | 8 hits, all lowered |

On the throwaway build with 5.x's rules the golem's hits kept their light reaction (5 of 6).

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
| Port status | **signed off** (2026-10-28); ported (slice B2, master `cf290eed`), verified in both trees (2026-10-28) |
| Open checks | a wyvern, griffin or siren (only harpies fought); the stronger lamia (`mon_lamia_stronger`, 5.x's 50% threshold) in play |
| Save impact | none |
| NG+ counterpart | none |

**What it does:** a flying enemy is knocked out of the air (knockdown applicator, also when the hit deals no damage) by any damaging hit that is not damage over time, by any bolt, by Yrden's shock and by burning; 1.32 needed a hit taking a set share of its health.

**Implementation (legacy):** `CNewNPC.ReactToBeingHit`.

**5.x:** 1.32's rule: a plain knockdown when a hit takes at least `healthLossToForceLand_perc` of the flyer's health, unless an effect deals it. That share is 0 for harpies, sirens, lamias, griffins, wyverns and Blood and Wine's draconids (50% only for `mon_lamia_stronger`, which legacy sets to 0), so in 5.x any hit but an effect's tick brings them down, also one without damage, while burning never does. The hit reaction aims at a targeted part's bone (`SetHitReaction`), bombs signal `BombHit`. The Yrden trap's grounding of flyers inside it (`BlockAbility('Flying')`) is 5.x's and unchanged.

**Decisions:** legacy's. The change in play: burning brings a flyer down; a hit without damage that is not a bolt or Yrden's shock no longer does; the knockdown goes through the applicator (SKL-08's `GMModifyKnockdownSeverity` makes it a heavy knockdown for a flyer). A regular Igni's own hit adds the applicator, but a regular Igni's effects pass only at its burn chance (`GetSignApplyBuffTest`, SKL-09, as legacy), so it grounds a flyer mostly through the burning it sets; Firestream's ticks are damage over time and do not count, its burning does.

**Verification (slice B2, 2026-10-28, both trees; master `cf290eed`):** `GMTest_ai11_after` (in `gmtest_panel()`, scripted: a spawned harpy's own `ReactToBeingHit` with its stance set to flying): a hit for 0.1% of its health and a burning tick add the knockdown applicator, a bleeding tick and a hit without damage add nothing (5.x: a plain knockdown on both hits, nothing on the burning). **Real fights** (`gmtest_ai13_a/_b`: a hostile harpy, `harpy_lvl1`, health refilled, Geralt immortal; its flying state, knockdowns and every hit while flying logged):

| Cause | Classic tree | New tree |
|---|---|---|
| Geralt's sword (real light attacks) | a hit while flying: applicator, landed | a hit while flying: applicator, heavy knockdown, landed |
| Bolt (a real quick shot, Bodkin) | applicator, landed | applicator, heavy knockdown, landed |
| Yrden's shock (a real alternate Yrden: its turret) | a shock on the flying harpy: applicator, landed | the same (after two casts; the harpy often landed by itself to attack) |
| Regular Igni (a real cast) | the applicator on the hit, no knockdown (the burn-chance test) | the same |
| Firestream (a real held cast) | — | its ticks no applicator (damage over time); the burning it set: the applicator on each tick, landed |
| Burning (the effect added by script, its real ticks) | applicator, heavy knockdown | applicator, heavy knockdown, landed |

On the throwaway build with 5.x's rules ten burning ticks on the flying harpy brought nothing (it landed by itself later).

**Tests shown failing without the slice** (a throwaway build: master `cf290eed` without `ai/targeting.ws`, the `ReactToBeingHit`, `ModifyHitSeverityReaction` and `IsHuge` replacements and the poise call, the tests kept; classic tree): the regression 1,029 passed, 2 failed (both weight checks), `gmtest_panel()`'s B2 checks all 5 failed (the bandit's, fiend's and golem's reactions unchanged, the cave troll huge and the fiend not, the flying harpy given a plain knockdown on the hits and nothing on the burning tick); the fights in the tables above. On the real build all pass.

### AI-14 Monster fixes

| | |
|---|---|
| Kind | fix |
| Pillars | P5, P8 |
| 5.x class | clean |
| Flags | — |
| Depends on | AI-01 (where legacy put the cyclops and arachas lines) |
| Skill trees | both: Axii on a cyclops, Yrden on a toad; checks in both trees |
| Port form | `ai/monsters.ws`: `@addMethod(CNewNPC)` `GMMonsterFixes` (legacy's cyclops and arachas lines, called from AI-01's replaced `AddLevelBonuses` in `ai/levels.ws` where legacy has them; `@addField` `gmArachasSpeedId`, `gmArachasSpeedSet`: legacy's `animSpeedMult`, one speed causer across recomputes, set through `@addMethod(CActor)` `GMSetAnimSpeedCauser`, which never gives a causer id 0 (AI-B audit F1; SKL-10's Yrden slowdown uses it too)); `@replaceMethod(CBTTaskToadYrden)` `Main`; `@replaceMethod(CBTTaskCastQuen)` `ProcessAction` calling the global `GMNpcQuenStagger`; entity edits by `tools/gen_ai_ent.py` (`PORTED` gains AI-14; `PROPS_LATER`): `ablIgnoreSigns` off the two Goldilocks bears, `CAIMonsterCombatParams.reachabilityTolerance` (5.x's 4) removed from the two quest fiends `mq4005_czart` and `q402_fiend`, `CAINpcWindMageCombatParams.increaseHitCounterOnlyOnMelee` (5.x's false) removed from the Hakland mage `q601_ofir_mage`; the fiend's tree stays 5.x's (PA9) |
| Port status | **signed off** (2026-10-28); ported (slice B3, master `654bc96e`; the causer fix, AI-B audit F1, `be7d5c63`), verified in both trees (2026-10-28) |
| Open checks | real hits raising the toad's hit counter inside Yrden (a 2.5 m toad's light hits are lowered by AI-12's poise and Geralt's level-1 hits dealt 0, so the counter was raised by script); the quest fiends' reachability and the Hakland mage's hit counter in their own fights (quest places; the edits checked by `gen_ai_ent.py --verify` only) |
| Save impact | none (the entity edits are read at spawn) |
| NG+ counterpart | none |

**What it does:** cyclopes lose `ablIgnoreSigns`, so Axii's confusion and the other signs' critical states take on them (changelist 1120); arachases move at 75% animation speed (an omission); the Hearts of Stone toad stays in Yrden's trap until it leaves it or the trap's hold ends (5.x: also on a third hit that plays a hit reaction); an NPC's Quen staggers its melee attacker with the stagger's default length (1.32 and 5.x: 0.1 s); the Goldilocks bears no longer ignore signs; the two quest fiends of Kaer Morhen's `mq4005` and `q402` take the default reachability tolerance (2 m; 5.x 4 m); the Hakland mage's hit counter rises only on melee hits; the fiend's (and chort's) tree gains a close-range melee branch (bugfix 77; in 5.x already, PA9); the sorceress's hand effect stops after combat (a community fix, in 5.x already); the three smiths become commoners (see the deviation).

**Implementation (legacy):** `CNewNPC.AddLevelBonuses`, `<members>`, `OnCombatModeSet`; `CBTTaskToadYrden.Main`, `CBTTaskCastQuen.ProcessAction`; `monster_bies_logic.w2behtree`; AI tree properties in 6 entity files (the smiths, the quest fiends, the Hakland mage), `ablIgnoreSigns` in the Goldilocks bears' lists.

**5.x:** 1.32's lines; the sorceress fix is in. The fiend's tree (`monster_bies_logic.w2behtree`) is 5.x's own (from the game files, unverified in game): it adds legacy's close-range melee branch itself (three attacks within 4 m, the same values), and also a new dodge that rolls the ability's chances, a hypnosis wind-up of 3 s up to Medium and 1.5 s on Hard and above, and changed charge distances. 5.x's smith files (`fergus_graem`, `master_blacksmith`, `prologue_smith`) are rebuilt by CDPR (appearances, included templates).

**Decisions:** legacy's. The fiend's branch (bugfix 77) needs no port: 5.x's tree has it, so 5.x's tree is kept (PA9's outcome, 2026-10-28; confirmed by the owner, 2026-10-28). Legacy's arachas line passes its previous speed causer to replace it; the port does the same (a recompute leaves one causer). The causer never takes id 0 (`GMSetAnimSpeedCauser`, AI-B audit F1): `SetAnimationSpeedMultiplier`'s optional id defaults to 0, so every caller that leaves it out (Yrden's slowdown effect, 5.x's frost slowdown, Blizzard) overwrote the arachas's causer 0 and removed it when it ended, and the arachas moved at 1.0 for the rest of the fight. Now a slow on an arachas applies as the most recent causer (the last one wins: inside Yrden it moves at Yrden's value, 0.75 to 0.84 in a level-1 trap, not below it) and after it ends the arachas is back at 0.75. The quest fiends' and the mage's edits remove a property, so the class default applies, as in legacy's files. AI-02's temporary deviation for the bears' `ablIgnoreSigns` ended with this slice.
- **Owner decision** (project owner, 2026-10-28, AI-B audit F1): inside Yrden or frost an arachas moves at the slow's value, as the port does (the last causer wins; presumably as in legacy), not at the product of both (0.75 × the slow's).
- **Deviation:** AI-14's arachas speed and SKL-10's Yrden slowdown never take animation-speed causer id 0 (`GMSetAnimSpeedCauser`), so a slowdown that leaves the id out no longer overwrites and removes the arachas's 0.75: legacy's same lines on the same vanilla code presumably lost it after the first slow ([legacy test](../open-questions.md#to-test-in-legacy-ghost-mode)); a fix of a bug, not a rule change (confirmed by the owner, 2026-10-28).
- **Deviation:** the three smiths (Fergus Graem, the Novigrad master blacksmith, the White Orchard smith) stay 5.x's quest NPCs: legacy's files are rebuilt from commoner templates (a commoner AI preset: group type `ENGT_Commoner`, scared combat, commoner reaction and soft-reaction trees, the `Commoner` ability, no `IsNotScaredOfMonsters` or `DisableFinishers`; the White Orchard smith also in the `civilians` attitude group), new objects and imports that `cr2w_patch.py` cannot write as edits of 5.x's files, which CDPR rebuilt too; the changelist does not mention it, and a commoner has no ability or effect manager in 5.x's code (confirmed by the owner, 2026-10-28).
- **Deviation:** the two quest fiends (`mq4005_czart`, `q402_fiend`) keep their obstacle probe (a phantom component that stops a charge at obstacles, with its attachment), which legacy's files lack: removing a component is beyond `cr2w_patch.py`, and the fiend's charge behaviour is 5.x's reworked tree's (confirmed by the owner, 2026-10-28).
- **Deviation:** Ekimma (`sq106_ekimma`) and the Skellige herbarium werewolf (`sq201_herbarium_warewolf`) keep their obstacle probe too (Ekimma also its grass collider), which legacy's files lack, as for the two quest fiends above; generic fiends kept theirs in legacy, so it is taken for a re-save artifact (porter's call, confirmed by the owner, 2026-11-03). In play: their charges stop at walls and obstacles, as in 1.32 (the probe raises `CollisionWithObstacleProbe`, which ends a charge); in legacy these two, like the two fiends, presumably charged through obstacles.

**Verification (slice B3, 2026-10-28, both trees; master `654bc96e`):** the regression (`GMTest_ai14` in `gmtest_regress()`, `GMTest_ai14_after` in `gmtest_panel()`; scripted): a spawned cyclops (`cyclop_lvl1`) without `ablIgnoreSigns` once its level bonuses ran (it spawns with it); an arachas (`arachas_lvl1`) at animation speed 0.75 with one causer across a recompute (since the AI-B audit: never id 0, and under the real slowdown effects, below); NPC Quen's stagger helper on a melee attacker 0.5 s (`GMNpcQuenStagger` only, what the task's `ProcessAction` calls; a task created by script crashed the game; the task itself: `gmtest_ai14_quen`, below); a Goldilocks bear without `ablIgnoreSigns` (the generated entity sample, `GMTest_ai06`). `gen_ai_ent.py --verify`: 391 files, 594 edits (5 new), 0 unexplained. In game:

| Check | How | Port (classic / new tree) | 5.x's rules (throwaway build, classic) |
|---|---|---|---|
| Axii on a cyclops | **real** Axii casts (`autocast(ST_Axii)`, locked on) on a hostile cyclops, Geralt immortal | confused, the confusion animation played (8 and 10 samples of 0.25 s), it stood | confused (the effect) but no animation (`ablIgnoreSigns`): it kept moving and attacking |
| Toad in Yrden | **real** Yrden on a hostile toad (`dlc/ep1/data/characters/npc_entities/monsters/toad.w2ent`, `yrden_lock` on it), its hit counter raised to 3 by script during its Yrden task | the task ran its full 5.0 s (both trees) | the task ended 1.1 s after it started, at the third hit |
| Arachas speed | a hostile arachas's approach from 25 m, ground speed sampled every 0.25 s, its AI-14 causer set to 0.75 or 1 by script (three runs each, one session, classic) | 2.5, 2.8, 3.0 m/s at 0.75 | 2.9, 3.3, 3.3 m/s at 1 (about 12% faster; the gait changes over the approach) |
| NPC Quen | **real** light attacks (B1's swings) on Reinald (`mq1060_witcher`, whose tree casts Quen), the task's `ProcessAction` logged | Geralt staggered for the stagger's default (read 1.83 s on him) | 0.1 s |

The regression's four AI-14 checks failed on the throwaway build (5.x's code and entity files; classic tree: 1,035 passed, 1 failed, and three panel checks). With `god()` on, the Quen stagger is not added to Geralt at all (both builds): test it with Geralt immortal instead.

**Verification (AI-B audit fixes, 2026-10-28, both trees; master `be7d5c63`):**

| Check | How | Port (classic / new tree) | Throwaway build without the fix (classic) |
|---|---|---|---|
| The arachas's causer under the real slowdowns (`GMTest_ai14_after`, panel) | scripted: Yrden's `EET_Slowdown` added at 0.4, reset at 0.35 as a trap tick, removed; 5.x's `EET_SlowdownFrost` added and removed (creator none: negative effects from a friendly creator are refused) | causer id 1 (never 0); 0.6, 0.65, then 0.75; frost 0.7, then 0.75 (both trees) | id 0; 0.6, 0.65, then **1**; frost 0.7, then **1** |
| An arachas in a real Yrden trap | **real** Yrden cast (`autocast(ST_Yrden)`, `god()` for the cast), the arachas (`gmtest_ai14_a`, 8 m) put into the trap by script (`gmtest_ai14_bring`), its animation multiplier sampled every 0.25 s | 0.75 before; 0.756 to 0.802 inside (the trap's decaying slow), 0.75 after it and for the next 20 s / 0.75; 0.754 to 0.784, 0.75 out of the trap, 0.814 to 0.828 back in it, 0.75 after it for 20 s | (the audit, before the fix: 0.81 to 0.84 inside, then 1.0 for the rest of the fight) |
| The toad in Yrden (`gmtest_ai14_toad`, automated) | **real** Yrden cast through the input handler on a hostile toad 3 m ahead; its hit counter raised to 3 by script once its Yrden task ran | the task still ran 1.5 s after the counter reached 3 (both trees, first try) | the task ended 0.25 s after the counter reached 3 |
| NPC Quen through `CBTTaskCastQuen.ProcessAction` (`gmtest_ai14_quen`, automated) | **real** light attacks on Reinald (hostile, his tree casts Quen), Geralt immortal, `god()` off | Geralt staggered 1.83 s (both trees) | 0.1 s |

**Fix round fix3 (2026-11-02, sweep C gap 1, changelist 136; the owner's decision):** the all-round slam of every golem, earth elemental (Dao) and Ifryt reaches legacy's 3 m: the template's own `wide_arc` attack range (`CConeAttackRange.rangeMax`) in the 22 entity files legacy edited (the 21 of sweep C and `mh306_dao`), 5.x's 2 m for the Daos and 4 m for the golems, the Ifryts, q104's and q310's elementals. Port form: `gen_ai_ent.py` owns `("CConeAttackRange", "rangeMax")` (`PROPS_LATER`, AI-14) only in the files whose attribution note names `wide_arc` (`FILE_SCOPED`): elsewhere W3Edit's re-save drops, adds and renumbers attack-range objects with no AI change. An included base's copy of the range stays 5.x's (object by object). Save impact none (read at spawn). **verified on the area build** (2026-11-02, gm/fix3 `51bce9eb`, both trees): `GMTest_ai14_slam` (in `gmtest_panel()`, at the end of `GMTest_ai14_after`; scripted): a golem, an Ifryt, an earth elemental, mh306's and q104's Daos spawned, `theGame.GetAttackRangeForEntity(npc, 'wide_arc').rangeMax` reads 3 for each; it failed first on a throwaway build with 1c2b351a's code and data (gm/fix3-ff `efa40f24`, classic tree; the code checks also in the new tree) (4, 4, 2, 2, 4). Whether 5.x's reworked golem and elemental trees use this range for the slam in a fight: not seen.


### AI-B audit (2026-10-28)

Done by a fresh session ([audit](../feature-mapping.md#audit-signing-a-feature-off)) on master `654bc96e` (port) and `9003d1fb` (docs), reading code and data, with game runs in both trees. The three slices' commits (master `e5fc2b5c`, `cf290eed`, `654bc96e`) were read whole; every method they replace, wrap or add was read against legacy (`legacy-GM`), 1.32 (`vanilla-1.32`) and 5.x (`vanilla-5.x`), with every caller of the changed functions. Data, by two scripts written for this audit, independently of `gen_ai.py` and `gen_ai_ent.py`: (1) every ability in the abilities folders whose combat-roll nodes (dodge, counter, guard, taunt, teleport, dash, hits before a roll, morale, ticket interval), stamina nodes or `hit_severity` legacy changed against 1.32, regular and NG+, compared node by node with what the game reads in the port (5.x's files with every Ghost Mode DLC entry applied: `replace` whole, `extend` by tag in order, `extend` on a Hearts of Stone ability as empty; two Ghost Mode homes flagged); (2) every one of the 630 entity files legacy changed, through `cr2w_dump.py` for `vanilla-1.32`, `legacy-GM`, `vanilla-5.x` and the port: every fact legacy added or removed that names a combat-skill template, an `abl*` ability, `ablIgnoreSigns`, a target weight, `reachabilityTolerance`, `increaseHitCounterOnlyOnMelee` or a taunt, dodge, parry, counter or guard property, checked in the port's file.

**Checked and holding:** the data: of the 154 abilities whose combat rolls legacy changed (and their 154 NG+ copies) all read legacy's rolls in the port but seven: the four fistfight abilities and `fistfight_q002` (AI-20's, C3), `mon_wild_hunt_default`'s morale (AI-15's, C1) and `SkillShield` (F3); STAM-08's stamina values read legacy's in every enemy ability, wherever it now lives (the 28 differences are Geralt's abilities, AI-20's `stamina_damage` and an inert zero node of AI-15's); no enemy ability has two Ghost Mode homes; `hit_severity` reads legacy's in all 20 abilities legacy set it in. The entities: 20 files carry AI-B-relevant legacy edits; all are in the port but the three smiths (the recorded deviation), `mq0005_arsonist`'s fistfight tier (AI-20's) and copies that only W3Edit's re-save wrote (`flatCompiledData` and the saved `CCharacterStats` of Olgierd, the Hakland mage and the `sq201` werewolf, whose parameter lists hold the same abilities in 5.x already); no legacy file sets a target weight. The code: the dodge, reaction, defend, taunt, hit-counter, shield, flyer, poise, `IsHuge`, toad and Quen bodies equal legacy's changes on 5.x's bodies (5.x's instant dodge, parry sound on damage, `mq1060` taunt line, targeted-part hit reaction and bomb signal kept, as recorded); 5.x's `ReactToBeingHit` has a dangling `if` that limits the zero-stamina perk to Rend, kept unchanged (5.x's). DEF-06's six dodge wrappers and AI-09's replacements both apply (the wrappers run first, so the air guard covers 5.x's `instantActivation` path too). The target weights are defaults of the only two combat-parameter base classes (`CAIBaseMonsterCombatParams`, `CAINpcCombatParams`; animals' quest and riders' parameters keep 5.x's, as in legacy). `IsHuge`'s readers are Mutation 4's reach (5.x's damage processor) and Retribution (ENCH), as legacy's; Aard's knockdown severity still reads `mon_type_huge` (SKL-08), as legacy's does. Flyers: bolts (any `W3ArrowProjectile`, XBOW's included), Yrden's turret shock and burning reach `GMFlyerForcedToLand`; DMG-01's `GMZeroSubOneDamage` keeps legacy's early exits before the poise rule (damage over time, parried, countered, dodged, flying). `ProcessShieldDestruction`'s callers (bombs, Axii, Iris, STAM-08's empty-stamina drop) all get legacy's lowered guard. `check_modsigns.py` and `deviations.py --check` pass. **In game** (Geralt invulnerable with `god()` unless a test sets immortality; B1's `gmtest_ai08_fight_a` real light attacks through the input handler; a throwaway probe mod, removed afterwards, logged every activation of the attack, dodge, defend, taunt, dash and teleport-marker tasks of nearby NPCs with time and position, and each NPC's target, flying state and animation speed): classic tree: a wraith (25 swings: dodges 2 of 14 and 9 of 24 at 40% in two fights, 34 attacks), a noonwraith (30 swings: dodges 10 of 26 at 40%, an attack every 3.5 to 4.5 s, 5 taunts), a bruxa (30 swings: 3 dashes at the start, then an attack every 1 to 3 s, dodges 5 of 8 at 40%), a griffin (30 swings: it flew off 20 m once and came back; 23 attacks, 3 defends, 3 dodges started), a wyvern (30 swings and 70 s idle: it took off and landed, re-engaged each time, attacked at 2 to 5 m), three wolves on the road (57 attacks in 30 s; Ghost Mode switched off, the same spot and spawn: 21), a bandit against a friendly Nilfgaardian deserter with two wolves beside them (the bandit on the deserter 132 of 132 samples, 31 and 14 hits between them; the wolves on Geralt); new tree: a griffin (25 swings, 18 attacks) and the arachas of F1. No enemy stood idle, chain-dodged, blocked without end or stuck in the air. Monster taunt timing, an idle Geralt and a noonwraith for 45 s: the port taunted 3 times, 10 to 16 s apart, between attacks every 3.5 to 4.5 s; 5.x (Ghost Mode off, the same spot) 4 times, 12 to 13 s apart (F4). Regression: `gmtest_regress()` 1,036 passed, 0 failed in each tree, `gmtest_panel()` 87 checks passing, none failing.

**Findings:**

1. **An arachas loses its 0.75 speed for the rest of the fight after Yrden, and moves faster inside Yrden than outside** (medium; the id collision a clear fix, how the two slows combine an owner decision). AI-14's arachas causer is the arachas's first animation-speed causer, id 0 (`gmArachasSpeedId` read 0 in the regression). 5.x's `SetAnimationSpeedMultiplier(mul, optional overrideExistingId)` defaults the id to 0 when it is left out, and the slowdown effects leave it out (SKL-10's `GMRecalcSlowdown` for Yrden's `EET_Slowdown`, 5.x's `W3Effect_SlowdownFrost`): Yrden's slowdown overwrites causer 0 with its own value and, when it ends, removes causer 0, the arachas's. Since the last causer wins ([development.md](../development.md)), the arachas also moves at Yrden's value instead of below it. **Real Yrden casts** (`autocast(ST_Yrden)`, the arachas brought into the trap; `gmtest_ai14_a` sampling its animation multiplier every 0.25 s), both trees: 0.75 before, 0.81 rising to 0.84 inside the trap, then **1.0** for the rest of the fight (10 s and more watched; restored only by the next recompute of its level bonuses, at the next combat start). Legacy's lines pass the same ids to the same vanilla slowdown, so legacy most likely had the same bug (not verifiable without legacy's game). The regression's check (`GMTest_ai14_after`) adds its "other slow" with id −1, which cannot collide, so it passes; the AI-14 entry's "0.75 after it" and the decision's "until another slow comes and goes" are wrong for a real slow. Fix: never leave causer 0 to the arachas (e.g. reserve a throwaway causer first, or let SKL-10's slowdown pass −1 on its first set and its own id after), and test with the real `EET_Slowdown` effect; the owner decides whether an arachas in Yrden should move at Yrden's value (as now and, presumably, legacy) or at the product of both (0.75 × Yrden's).
2. **The regression does not exercise AI-09's and AI-10's task code, and two AI-14 checks cannot fail for what they claim** (low, test-only, clear fix). `GMTest_ai08` reads data and the three class defaults only: the replaced dodge wait, delay, attack and overlap lines, the reaction-task fix, the 2.5 s counters, the defend task's end, the taunt roll and the shield break run only in manual helpers (`gmtest_ai10_window_a/_b`, `gmtest_ai10_shield`). `GMTest_ai14`'s NPC Quen check calls `GMNpcQuenStagger` itself, so it passes with `CBTTaskCastQuen.ProcessAction`'s replacement removed (behaviour-tree tasks cannot be created by script); its arachas check cannot see F1; the toad's Yrden task has no regression check. Fix: move the counter window (two reads 2.25 and 2.75 s after a raise) and the shield break (a spawned shield bearer, scripted call) into `gmtest_panel()`; label the Quen check as the helper's only; test the arachas with the real slowdown effect (F1).
3. **`SkillShield`'s counter chance is 5.x's random 0.3 to 0.5, not legacy's 0.4** (low, data, clear fix). Legacy kept 1.32's 0.4; 5.x randomised it; `gen_ai.py`'s `PART` takes legacy's nodes only for the tags legacy changed, so 5.x's change survives in this one node (the only such node in the 154 abilities; the whole abilities AI gives carry legacy's unchanged nodes too, PA1). Same mean; shield bearers' counters vary per spawn. Fix: let `PART` also take legacy's node where legacy kept 1.32's value and 5.x changed it, for AI-08's tags.
4. **AI-10's "taunts come later and less often" does not hold in play** (low, doc). The taunt task re-rolls its chance every tick once its delay has passed, so a 10% chance passes within a moment: a noonwraith taunted 3 times in 45 s, 10 to 16 s apart, with 5.x 4 times, 12 to 13 s apart (above). Legacy's wolves also have a 100% taunt chance. Fix: say that the XML chance changes little in play; the timing comes from the delays and the tree.
5. **The gryphon family's dodge chances are inert entirely** (low, doc). Its tree sets `ignoreDodgeChanceStats`: every roll said yes (16 of 16 and 6 of 6 at legacy's 20%, both trees), not only within 3 m; few rolls start a dodge (3 of 16). AI-08's "Who reads the rolls" and the balance-pass note should name griffins (and basilisks, cockatrices) with the monsters whose dodge numbers are inert.
6. **Not verified in game** (no action; open checks). Teleports: legacy changed teleport and dash chances only on Blood and Wine monsters (barghests, kikimores, sprigans and lessogs per hit, the fairytale witch; other nodes moved to base abilities), the base game's equal 1.32's; no teleport came in the wraith and noonwraith fights (the probe watched the teleport-marker task, which these trees may not use), and no Blood and Wine monster with changed chances was fought. Wolves on uneven ground (a rocky ledge, a forest slope) circled 8 to 13 m away and attacked rarely or not at all for 30 s and more (on the ledge they could not reach Geralt; the slope was not compared with 5.x). The quest fiends, the Hakland mage and the Quen stagger on a puppet or ally, as before. Kept as open checks.

**Autosave:** the game wrote `<save name>` (14:51, during the runs); the test save is unchanged.

**Not reviewed:** legacy's own behaviour in play; NG+ in game; AI-C.

**Suggested fix slices:** **C** (code and tests): F1's id collision with its test, F2; **D** (data): F3; **W** (docs): F1's statements, F4, F5. Owner decision: F1's combination of the two slows. **Done** (2026-10-28, master `be7d5c63`, one commit; docs on master), verified in both trees.

Outcomes: 1. **Fixed** (C): `GMSetAnimSpeedCauser` gives the arachas's causer and Yrden's slowdown a causer that is never id 0; inside a slow the arachas moves at the slow's value, after it at 0.75 again (real Yrden casts, both trees); the AI-14 entry's statements corrected; a new deviation (a fix of legacy's presumable bug); the owner decision recorded in [AI-14](#ai-14-monster-fixes). Other speed settings checked for the same problem: SKL-10's Yrden slowdown (fixed with the arachas: a trapped enemy's first causer could be overwritten and removed by a frost slowdown); Axii's slow motion and the bomb and crossbow aiming slow motion are Geralt's own, 5.x's pattern among themselves; Blizzard's slowdown, the frost slowdown and the slowdown's decay are 5.x's id-less callers, which still collide with each other on an enemy's causer 0 (5.x's behaviour, unchanged); the frozen test dummies (`SetAnimationSpeedMultiplier(0.001)`, id left out) hold id 0, which is why a frost slowdown frees them ([development.md](../development.md#testing-in-game), test code only). 2. **Fixed** (C): the counter window and a scripted shield break in the regression (`GMTest_ai10`, `GMTest_ai10_after`); the toad's hold and NPC Quen through the task's `ProcessAction` as automated fight checks (`gmtest_ai14_toad`, `gmtest_ai14_quen`, run after the regression: they fight); the Quen regression check labelled as the helper's only; the arachas check with the real slowdown effects. Each new or changed check failed on a throwaway build without its code (deleted afterwards): `GMTest_ai08`'s `SkillShield` (0.3 to 0.5), the counters at 2.25 s (0 and 0), the shield (staggered), the arachas's three checks (id 0; 1 after Yrden and after frost), the toad (ended 0.25 s after the third hit), Quen (0.1 s). AI-09's replaced dodge lines and the reaction task's fix stay covered only by the fights (the dodge task is a behaviour-tree task: none can run by script). 3. **Fixed** (D): `gen_ai.py`'s `PART` takes legacy's node for AI-08's tags where legacy kept 1.32's value and 5.x changed it: `SkillShield`'s counter chance 0.4, regular and NG+ (the only such node; `GMTest_ai08` reads it). 4. **Corrected** (W): [AI-10](#ai-10-guarding-parrying-and-taunts)'s taunt statement. 5. **Corrected** (W): [AI-08](#ai-08-combat-parameters)'s "Who reads the rolls" and balance note name griffins, basilisks and cockatrices. 6. **Recorded**: the open checks stay open.

#### AI-B audit close-out

Closed 2026-10-28: every finding is fixed, corrected or recorded. Fixed and verified in both trees: F1, F2 (code and tests), F3 (data), all in master `be7d5c63`. Corrected in the docs: F1's statements, F4, F5. Recorded: F6 (the open checks). New: a deviation (the arachas's and Yrden's causers never id 0, [AI-14](#ai-14-monster-fixes)). The owner decided F1's combination of the two slows (2026-10-28): the slow's value, as now. Checks at close: `gmtest_regress()` 1,038 passed, 0 failed in each tree (`god()` off), `gmtest_panel()`'s 92 checks passing; `gmtest_ai14_toad()` and `gmtest_ai14_quen()` 1 passed each, in each tree; `gen_ai.py --check` and `--verify` (487 abilities, 465 NG+), `gen_ngplus.py --check` current; `check_modsigns.py` 0 unmarked (449 bodies), no native wrap; `deviations.py --check` current. No autosave was written. What stays open: the open checks (F6). **AI-B signed off** by the project owner (2026-10-28), with the open checks kept open; the owner decided F1's combination (the slow's value) and confirmed AI-B's porter's calls and deviations (the inert dodge chances, the Wild Hunt's and the djinn's stats until C1, golems never guarding or countering, legacy's "huge", the smiths, the quest fiends' obstacle probe, the causers never id 0).

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
| Port status | **signed off** (2026-10-29); ported (slice C1, master `c94ce08e`; Eredin's frost projectile with AI-18, slice C2, master `78c2e754`), verified in both trees (2026-10-28) |
| Open checks | Eredin's frost projectile cast by Eredin himself (shot by script from a spawned Eredin, below); Caranthir casting Ice Armor in a real fight (no spawnable Caranthir template found; Ice Armor was added by script, and Eredin's template carries it); Eredin attacking in a real fight (the spawned `enemy_eredin` stood idle; his sword's frost slowdown was seen through a scripted attack); a real Firestream and the fire runes on Ice Armor (their fire damage takes the same path); Easy (no bonus) and Ciri's rage; New Game+ (untested, as every NG+ change) |
| Save impact | none |
| NG+ counterpart | applied, untested |

**What it does** (changelist 1123–1129, bugfix 75): Ice Armor adds 30% to all resistances (not on Easy, not against Ciri's rage, not for damage over time) instead of halving damage, so resistance reduction counters it and Igni is no longer mandatory; any fire hit removes it (1.32: Igni's). The Hunt's weapons and Eredin's frost projectile deal frost damage (Eredin's sword 350 slashing, 40 silver, +50 frost and frost slowdown; Caranthir's staff, Imlerith's mace and shield), countered by armor, frost resistance and dodging. Minions get 20 armor and full frost resistance; the generals' Essence 8,000–12,000 → 2,500, armor 125–150 → 200–250, resistances 50–70% → 30% with full burning and will resistance. Eredin no longer ignores signs (`EredinInvulnerable` commented out) or fire (`EredinFireResistance` emptied).

**Implementation (legacy):** `W3DamageManagerProcessor.GetDamageResists` (the Ice Armor term), `CActor.ReduceDamage` (halving and Eredin removed), `CNewNPC.OnFireHit`; 44 abilities and the Hunt's weapons.

**5.x:** 1.32's halving (5% on Easy) and Igni-only removal. `EredinInvulnerable` is defined in no XML, and `AddAbility` refuses a name no XML defines (tried on a spawned Eredin, 2026-10-28), so 5.x's check never applies: none of the three Eredin templates spawned carries it, and removing the check changes nothing in play, as legacy's commenting-out did.

**Decisions:** legacy's; ends DMG-02's temporary deviation, B1's (the Hunt's and the djinn's stats, [AI-08](#ai-08-combat-parameters)) and AI-19's (`mon_wild_hunt_default`, [AI-19](#ai-19-the-caretaker-and-quest-monsters-immunities)). The bonus is added to the resistance before the resistance reductions (legacy's order), so armor piercing and oils reduce it as any resistance. The removal runs in `OnFireHit`, which the damage pipeline calls for any hit that deals fire damage (a fire hit stopped by armor deals none and removes nothing; Igni's own hit also removes it through 5.x's `OnIgniHit`). The Hunt's warriors (`wlh_2h_sword`, `q403_wild_hunt_2h_sword`) and Imlerith refuse burning (`EI_Deny`, an immunity of their templates): on them "any fire" means fire hits (Igni, Firestream, fire bombs, runes); the hounds (`wildhunt_minion_*`) take burning, and its first tick removes Ice Armor. The warriors' and Imlerith's immunity stays as their templates have it, so "any fire" works on them only through fire hits (confirmed by the owner, 2026-10-29); the [legacy test](../open-questions.md#to-test-in-legacy-ghost-mode) of whether legacy's warriors burned stays open. Eredin's frost projectile is legacy's since AI-18 (slice C2, 2026-10-28; until then a temporary deviation): its entity (`gameplay/abilities/eredin/eredin_frost_proj.w2ent`, which neither 5.x nor legacy changed) sets 500 frost damage, so legacy's class default of 200 never applies to it; legacy's default effect, the frost slowdown, does (the entity sets none), for 3 s. 5.x: 500 frost raised by its level term (875 at Geralt level 30) and no slowdown (C1's entry said 20 damage: the class default, which the entity overrides).

**Verification (slice C1, 2026-10-28, both trees; master `c94ce08e`):** the regression (`GMTest_ai15` in `gmtest_regress()`, `GMTest_ai15_after` in `gmtest_panel()`; scripted): a hound of the Hunt with Ice Armor, burning (Geralt its creator), lost the armor to the burning's ticks; a crafted silver hit on a frozen Wild Hunt warrior with Ice Armor dealt 0.647 of one without (15% physical resistance: (1 − 0.45) / (1 − 0.15); 5.x 0.5) and kept the armor; a crafted fire hit past its armor removed it; a sign's hit on Eredin dealt 210 (a negative check: 5.x's immunity never applies, above). Data (`GMTest_ai03`'s generated table; `GMTest_ai08`: Eredin's 2,500 Essence): the 30 abilities read legacy's values; `gen_ai.py --verify`: 505 abilities in `abilities/`, 498 in `abilities_plus/` as meant. In game (Geralt at level 20, immortal by script):

| Check | How | Classic tree | New tree |
|---|---|---|---|
| Ice Armor's resistances in real hits | **real** light attacks with the silver sword (B1's swings) on a hostile Wild Hunt warrior (`wlh_2h_sword`, Ice Armor added by script), probes on `GetDamageResists` | silver and slashing 45% (its 15% + 30%) in 3 hits; the armor stayed on | 45% in 6 hits; stayed on |
| A real Igni | **real** cast (`autocast(ST_Igni)`, `god()` for the cast) | the Igni hit read fire 60% (30% + 30%) with the armor, dealt 29.2, and its fire damage took the armor off (`OnFireHit`, before 5.x's `OnIgniHit`) | the same |
| A fire bomb | **real** throw of a Dancing Star (Geralt's item action) | its impact read fire 60% with the armor (100 fire, 2 dealt past 90 armor) and took the armor off | the same |
| Burning | the burning effect added by script, its **real** ticks, on a hostile hound (`wildhunt_minion_lvl1`) with Ice Armor | the first tick took the armor off | the same |
| Frost damage on Geralt | **real** attacks of the warrior | every hit carried 45 to 55 frost (the sword's 50 × the melee roll) with about 250 slashing and 40 silver | the same |
| Eredin's sword | a **scripted** light attack of a spawned Eredin (`enemy_eredin`) with his held sword on Geralt (he stood idle) | 335 slashing, 36 silver, 55 frost (his 350/40/50 × the roll), and the frost slowdown on Geralt | — |
| Signs on Eredin | **real** alternate Yrden (the turret) on a hostile Eredin, who carries Ice Armor | shock resisted 60% (30% + 30%), 24.3 a shot; a regular Igni (150 fire) was stopped by his 250 armor (0) but took his Ice Armor off through 5.x's `OnIgniHit` | 29.3 a shot |
| The Hunt's stats | spawned templates, scripted reads | Eredin (`enemy_eredin`) level 30, 22,662.6 Essence = (2,500 + 450 + 29 × 20) × (1 + 29 × 0.15) × 1.2, 250 armor, 30% slashing, full frost resistance; Imlerith 200 armor; a warrior 540 Essence at level 1 (legacy's 450 × 1.2), 90 armor, full frost; a hound 20 armor, full frost | — |

**Tests shown failing without the slice** (a throwaway build: master `c94ce08e` with `be7d5c63`'s DLC, `pipeline.ws` and `formula.ws` and no removal in `OnFireHit`, the tests kept; classic tree): the regression 1,038 passed, 1 failed (Eredin's Essence 8,000), and 5 of C1's 6 panel checks failed (the burning hound kept its armor, the silver hit's ratio, the fire hit kept it, the weakened state and the djinn's rage unchanged; the Eredin check, negative only, passed). On the real build all pass.

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
| Port status | **signed off** (2026-10-29); ported (slice C1, master `c94ce08e`), verified in both trees (2026-10-28) |
| Open checks | the djinn's rage and weakness in a real fight (the spawned quest djinn never fought: Geralt stayed out of combat and Axii found no target; the abilities were added by script, as its rage task does); Olgierd's weakened state in his fight (the spawned `olgierd.w2ent` lacks the `olgierd_gpl` tag the state needs; tested on a tagged warrior) |
| Save impact | none |
| NG+ counterpart | applied, untested |

**What it does** (changelist 1130–1133): the djinn's rage gives +10% stamina regen and +50% attack and spell power (1.32: +100% regen), its weakness −10% and −50% (−100%); a weakened special enemy (Olgierd countered, and the like: `WeakenedState`) takes −15% physical resistances; the djinn 11,000 → 3,000 Essence, level 15 → 1, full damage-over-time resistance (AI-03).

**Implementation (legacy):** `DjinnRage`, `DjinnWeak`, `mon_djinn`, `WeakenedState`.

**5.x:** 1.32's. `WeakenedState` is added by `CNewNPC.SetWeakenedState` only to NPCs tagged `olgierd_gpl` (Olgierd); the djinn's abilities by its rage task (`BTTaskManageDjinnRage`, ALCH-15's).

**Decisions:** legacy's.

**Verification (slice C1, 2026-10-28, both trees; master `c94ce08e`):** the regression (`GMTest_ai15_after`, scripted): a Wild Hunt warrior tagged `olgierd_gpl`, through `SetWeakenedState(true)` (the call of the animation event and the behaviour task), slashing resistance 15% → 0% (5.x unchanged); a spawned djinn's attack power ×1.15 → ×1.65 with `DjinnRage`, ×0.65 with `DjinnWeak` (5.x unchanged); the data table reads the four abilities. In game (classic tree; scripted calls of what the rage task adds, `gmtest_ai15_rage`): attack and spell power ×1.15 → ×1.65 and ×0.65, stamina regen ×0.33 → ×0.43 and ×0.23; the djinn 3,600 Essence at level 1 (legacy's 3,000 × 1.2), 12,870 at level 16.

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
| Port status | **signed off** (2026-10-29); ported (slice C2, master `78c2e754`), verified in both trees (2026-10-28) |
| Open checks | the explosion's damage in play: no real rotfiend death ran it (EFX-09's finding, seen again in C2; its damage seen by a scripted `Death` signal); an instant kill from a weapon's `instant_kill_chance` or Deadly Precision on a contract monster (the real hits used vanilla's `ForceInstantKill` ability, the same function) |
| Save impact | none |
| NG+ counterpart | applied (`MonsterMHBoss`), untested |

**What it does** (changelist 1098): contract monsters are immune to instant kills (legacy also strips `MonsterMHBoss`'s 8,000 Essence and attack power; their stats come from AI-03's quest abilities); an instant kill on a LastBreath monster (rotfiends) deals only the health above its LastBreath threshold, so it cannot kill it outright (legacy's comment: so its explosion cannot kill Geralt with it; a frozen one dies outright, EFX-09); the rotfiend explosion deals the damage of the monster's weapon, 300 without one.

**Implementation (legacy):** `MonsterMHBoss`; `ProcessInstantKill` (a return for `W3MonsterHuntNPC` victims; the instant kill's damage set to the victim's health, or to `GetLastBreathMaxAllowedDamage` on a LastBreath monster not frozen); `BTTaskExplodeAtDeath.Explode`.

**5.x:** no instant-kill immunity for contract monsters beyond the `InstantKillImmune` ability most contract entities carry (mh102's arachas, mh202's nekker, mh107's fiend, mh301's griffin, the red-plague creature; not mq1051's wyvern, mh303's succubus, mh305's dopplers, sq204's leshen: from the entity files); an instant kill adds the victim's health to the hit's damage after `ReduceDamage`, so it kills a rotfiend outright, past LastBreath; the explosion 50/100/150/200 + 2/3/4/5 × the weapon's damage by difficulty (150 + 4× on Hard).

**Decisions:** legacy's (PA10: the explosion's damage is ported though no real death runs it in 5.x). Legacy's immunity is its check of the class (`W3MonsterHuntNPC`), not the `InstantKillImmune` tag on `MonsterMHBoss` (A2): `HasAbility` reads ability names, so the tag changes nothing (it stays, as legacy's data). The instant kill sets the victim's health as the damage (legacy; 5.x adds it to the hit's), so the floater and the logs show the health taken. A rotfiend cut to its threshold by an instant kill does not swell (its swelling starts on the `LastBreath` signal of a held-back hit in `ReduceDamage`); it fights on at 25% (seen in both trees), as legacy's code reads (confirmed by the owner, 2026-10-29); with `ForceInstantKill` every later hit deals 0 (the health above the threshold is 0). Contract monsters of 5.x's new content that are `W3MonsterHuntNPC` (the red-plague creature, the Hakland mage of Hearts of Stone) are immune too.

**Verification (slice C2, 2026-10-28, both trees; master `78c2e754`):** the regression (`GMTest_ai17`/`_after`, scripted): an instant kill (a scripted hit with `SetInstantKill`) on mq1051's contract wyvern (a `W3MonsterHuntNPC` without `InstantKillImmune`) left it at 99.9%; on a rotfiend left it alive at 25.0% (its threshold); a rotfiend's death signal next to a bandit dealt 300 physical and 300 silver raw (no weapon in the slot; 5.x: 150). In game (Geralt with vanilla's `ForceInstantKill`, so every hit is an instant kill; probes on each hit):

| Check | How | Classic tree | New tree |
|---|---|---|---|
| A contract monster | **real** light attacks (the input handler) on mq1051's wyvern, frozen | hits of 59 and 65, no instant kill, alive | 55 and 52, alive |
| A rotfiend | **real** light attack, hostile | instant kill, 630 dealt, left at 210 of 840 (25%), alive; it did not swell and fought on | 2,322.9 of 3,097.2 dealt, left at 25%, alive |
| A plain monster (control) | **real** light attack on an arachas | instant kill, 1,950 of 1,950 dealt, dead | 4,859.4 of 4,859.4, dead |
| A real rotfiend death next to Geralt | **real** light attacks (Geralt 1.5 to 2.5 m away), it died of its bleeding | no explosion hit on Geralt | — |
| The explosion's damage | the rotfiend's `Death` signal by **script**, Geralt 1.5 m away | 350 physical and 350 silver raw (its claws, `mon_rotfiend_weapon`, 350; 5.x on Hard: 1,550), 891.7 dealt | — |

On a throwaway build without the slice (the tests kept) the contract wyvern and the rotfiend died, and the explosion read 150.

### AI-18 Special attacks and monster projectiles

| | |
|---|---|
| Kind | system, tuning |
| Pillars | P1, P5 |
| 5.x class | overlap |
| Flags | balance |
| Depends on | DMG (attack power after armor), XBOW-08 (its kept level term) |
| Skill trees | both: Quen against the Blood and Wine projectiles that break it (legacy: they no longer do); checks in both trees |
| Port form | `ai/specialAttacks.ws`: `@replaceMethod` of `W3AdvancedProjectile.OnProjectileCollision` (5.x's level term out), of eleven projectile classes' collision or damage functions (5.x bodies, the effect 3 s and the projectile's own damage and effect), `DebuffProjectile.OnProjectileCollision` (the Hakland mage's hack, `@addField`/`@addMethod(CNewNPC)` `GMHaklandMageDebuffProjectileHack`; `ignoreArmor` on every victim, legacy's line), `W3BoulderProjectile.DealDamageToVictim` (bludgeoning, `ignoreArmor` on every victim; since the AI-C owner decisions), `W3LeshyRootProjectile.DelayDamageTimer`, `W3LeshyBirdProjectile.OnProjectileCollision`, `W3RedPlagueProjectile.DelayDamageTimerNew` (DA5), `W3IceSpike.DealDamage`, `W3WitchBoilingWaterObstacle.Appear`, `CFlyingCrittersLairEntityScript.OnBoidPointOfInterestReached`, `W3ReactToBeingHitEntity.DealDamage`, `CToadAcidPool.OnFireHit`, `CBTTaskTornadoAttack.Main`, `CBTTaskGroundTrapAttack.Main`; scope-based defaults of ten projectile classes and `CBTTaskGroundTrapAttackDef`; `@wrapMethod(W3Action_Attack)` `Init` (magic fists); binary edits of 16 projectile and obstacle entities by `tools/gen_ai_ent.py` (AI-18 in `PROPS_LATER`, legacy's value also where 5.x changed it), and since the AI-C audit the Wild Hunt mage's ice spear (`GAME_FILES`: a file legacy left as 1.32's); the Hakland mage's and the magic fists' abilities came whole with AI-04 and AI-05 (slice A2) |
| Port status | **signed off** (2026-10-29); ported (slice C2, master `78c2e754`; the AI-C owner decisions on armor and boulders, master `99fd2b88`), verified in both trees (2026-10-28, 2026-10-29) |
| Open checks | a boulder thrown by a monster in a fight (none throws them near the test save; boulders shot by script); the witch's boiling water and the Hakland mage's quicksand and sand coil in a real fight (the Crones and the Hakland mage, spawned by script, were removed by the game at once: quest NPCs; the quicksand's entity value read by script); the toad's acid pool, ice spikes, objects striking back, the Blood and Wine tornado, ground trap, Dettlaff's and the other Blood and Wine projectiles in a fight (not reached without quests); the bird swarms and the leshen's birds in a fight (neither seen); a magic fist's hit (scripted: the attack reads ranged); Quen against the Blood and Wine projectiles; Caranthir's ice spear in a fight (500 by script) |
| Save impact | none |
| NG+ counterpart | none |

**What it does:** special attacks deal set damage with the attacker's attack power (spell power for eight projectile classes, as in 1.32: Ifryt's, Eredin's, poison, fireballs, the Dracolizard's, ice meteors, lightning strikes and lightning bolts) and the victim's armor (DMG's rule), instead of reading the attacker's basic-attack stats or ignoring armor: monster projectiles their projectile's damage, 200 by default (boulders, stones, elementals', Eredin's, fireballs, meteors, lightning), with their effects 3 s (2 s); ice spikes their own frost damage (100 when unset) with attack power; the leshen's roots 400 rending with a heavy reaction (its birds dealt by the swarm); the witch's boiling water with attack power; bird swarms ignoring armor, without attack power; objects that strike back when hit (`W3ReactToBeingHitEntity`) their own damage type, and when they have no damage set the larger of 500 and half Geralt's health, with a heavy reaction; the toad's acid pool at least 20% of the victim's health in fire; the Blood and Wine tornado 2% of the victim's health, the ground trap at least 500 or 20% as direct damage; magic fists count as ranged attacks; the Hakland mage's debuff projectile hits once in 3 s (it hit three times); the Blood and Wine and Hearts of Stone projectiles' damage and whether they break Quen (legacy: none does) and ignore armor (none does), the djinn's wood and the sorceresses' stone no longer ignoring armor; boulders deal bludgeoning damage (1.32's), and boulders and debuff projectiles set to ignore armor ignore it on every victim (1.32's lines). **No projectile gains damage from Geralt's level.**

**Implementation (legacy):** 20 `advancedProjectile.ws` units, 2 leshen units, 6 obstacle and swarm units, 3 Blood and Wine task units, `W3Action_Attack.Init`, `CNewNPC.HaklandMageDebuffProjectileHack`, the `HaklandMage` abilities; 16 projectile and obstacle entities (13 projectiles, 2 quicksands, the toad's acid pool).

**5.x:** +2.5% damage per Geralt level on every projectile at each collision (per the victim's level when playing Ciri), kept for monster projectiles and reflected arrows by XBOW-08 until now; the leshen's roots and the boiling water below 101 damage (but the q111 witch's) rebuilt as heavy attacks of the attacker's weapon; a debuff projectile adds a second hit of rending damage of its value when its damage type does not hit Essence; boulders deal rending damage (1.32: bludgeoning) and ignore armor only on Vitality users; bird swarms ignore armor (as legacy) with attack power; four Blood and Wine and Hearts of Stone projectiles' damage lowered (the echinops' acid 1,000 → 500, Dettlaff's swarm 1,000 → 30, the toad's spit 890 → 500 and tongue 900 → 400), and the Wild Hunt mage's (Caranthir's) ice spear 500 → 285, a file legacy did not touch (with 5.x's level term, 285 is about 500 at Geralt level 30); new: the red-plague creature's roots (200 to 300 elemental or its heavy attack + 200) and a thrall's boulder (`W3ThrallBoulderProjectile`).

**Decisions:** legacy's; 5.x's level term removed for every projectile (PA11), ending XBOW-08's temporary deviation ([xbow.md](xbow.md#xbow-08-npc-bows-and-crossbows)); the boiling water uses attack power on both of 5.x's paths (PA12); the red-plague creature's roots follow legacy's leshen-roots rule (DA5, confirmed by the owner, 2026-10-28). Legacy's projectile values also where 5.x changed them (as PA1 for abilities). Legacy's class defaults apply only where a projectile's entity sets no value of its own: Eredin's frost projectile keeps its entity's 500 frost (legacy and 1.32 alike) and takes legacy's default frost slowdown ([AI-15](#ai-15-the-wild-hunt)); the sorceresses' stone reads 200 from legacy's entity edit. 5.x's second rending hit of the debuff projectiles is removed (legacy's numbers are tuned for one damage type; legacy's behaviour; confirmed by the owner, 2026-10-29). Debuff projectiles and boulders set to ignore armor ignore it on every victim, as legacy's and 1.32's lines (AI-C audit F1, owner, 2026-10-29; 5.x: only on Vitality users), and boulders deal bludgeoning damage, as legacy and 1.32 (owner, 2026-10-29; 5.x: rending). Bludgeoning and physical damage do not hit Essence, so a boulder or a physical debuff projectile deals nothing to a monster, as in legacy and 1.32: a boulder Aard sends back at a troll does not hurt it (5.x's rending did). Legacy's dead code in the ice spike (the summoner's weapon damage, computed and discarded) is not carried over, nor legacy's hit-animation and attacker lines before `Initialize` in the leshen's roots (`Initialize` clears them; the heavy reaction comes from `EHRT_Heavy`). The Wild Hunt mage's ice spear takes 1.32's 500, which legacy played (it left the file as 1.32's), over 5.x's 285 (AI-C audit F2: the rule for legacy's own edits, as AI-B's `PART` for abilities; with PA11, 5.x's 285 would deal 285 at every level; confirmed by the owner, 2026-10-29).

**Entity scan (AI-C audit F2, 2026-10-29):** the classes that read their entity's damage or effect since this port (the elementals', stones, environment projectiles; the effect of poison, fireballs, meteors, lightning) made every value stored in a 5.x entity count. Every entity of a `W3AdvancedProjectile` class in the game's bundles was dumped in both games (58 files in 5.x, the same 58 in 1.32; the scripts were the session's, not kept), with legacy's and the port's edits applied, and compared with what legacy played (the stored value, else legacy's class default, which the port shares). They store: the elementals' Dao and Ifryt projectiles, the giant's and the sharley's shockwaves, the elemental's stone, the elemental's, the sorceresses' and Philippa's fireballs nothing (200 and their class's effect); the sorceresses' five environment projectiles only their stagger (the default); the sorceress's lightning bolt nothing (40, paralysis), the `q205` lightning ball burning instead; poison: the arachas's venom 400, the scolopendromorph's 400, the black spider's web line 400, the fairytale witch's 500, the echinops' acid 350 (legacy's edit), the toad's spawn 150 and mortar 50, the endriaga worker's nothing (40), the fugas stink cloud 0 with burning, the fairytale witch's spawn 0 without an effect; the meteors of `q403` 2,000 and 2,300, Eredin's 500 frost with its slowdown; the Dracolizard's fireball 300 and 300 silver, burning 3 s (legacy's edit); boulders: the djinn's 100, the sorceresses' and the rock witch's 200, the troll's 250, the sharley's 250 with a heavy knockdown; Eredin's frost projectile 500; the debuff projectiles their damage and debuff (legacy's edits where it made them). All 57 but one read what legacy read; the one is the Wild Hunt mage's ice spear (1.32 and legacy 500, 5.x 285), now 500 (above). The `q205` lightning ball's and the stink cloud's burning apply, as in legacy (1.32: paralysis and poison).
- **Deviation:** the witch's boiling water keeps 5.x's two paths: below 101 damage (but the q111 witch's) a heavy attack of the summoner's weapon with its attack power, 101 and above legacy's set damage with attack power (legacy: the set damage with attack power always; PA12, confirmed by the owner, 2026-10-28).
- **Deviation:** 5.x's new thrall boulder (`W3ThrallBoulderProjectile`, a class legacy has no counterpart of) keeps its entity's numbers and 5.x's rules (rending damage, armor ignored only on Vitality users, its own Aard deflection), without the level term (confirmed by the owner, 2026-10-29).

**Verification (slice C2, 2026-10-28, both trees; master `78c2e754`):** the regression (`GMTest_ai17` in `gmtest_regress()`, `GMTest_ai17_after` in `gmtest_panel()`; scripted): the entity edits read legacy's (the sorceresses' stone 200 and armor applying, the toad's spit 200 poison, Dettlaff's swarm 600 not breaking Quen and dodgeable, the Hakland mage's quicksand 300, the toad's acid pool 100); Eredin's frost projectile's collision with Geralt at a set level 30 leaves its damage at 500 (5.x: 875); a lightning fist's attack reads ranged; the Hakland mage's second debuff hit within 3 s does not count; Eredin's frost projectile's collision with a bandit dealt 500 frost and a 3 s frost slowdown. In game (Geralt immortal by script; probes on each hit on Geralt: attacker, the projectile's class, raw damage by type):

| Check | How | Classic tree | New tree |
|---|---|---|---|
| A monster projectile, Geralt level 1 and 30 | **real** spit of a hostile arachas (`PoisonProjectile`) | 400 poison raw at level 1 and at level 30 (5.x: 410 and 700) | — |
| Another monster projectile | **real** mud of a water hag (`DebuffProjectile`), Geralt level 30 | 20 piercing, no rending hit (5.x: 35 + 35 rending) | — |
| Eredin's frost projectile | its projectile entity shot at Geralt by **script** from a spawned Eredin (as its task would; Eredin stands idle when spawned) | 500 frost at level 30 (5.x: 875), the frost slowdown on Geralt (1.6 s left 1.3 s after the hit) | the same |
| A reflected arrow | **real** arrows of a Skellige archer reflected by Deflection (classic `sword_s10`, new `S_Sword_s33`; the parry stamped, XBOW's procedure), Geralt level 30 | projectile damage 200 → 200 (5.x: 612.5), 453 after SKL-05's pool | the same, three arrows |
| The leshen's roots | **real** root attack of a hostile leshen | 400 rending raw, heavy reaction | 400 rending, heavy, 1,500.6 dealt at Geralt level 30 |
| The red-plague creature's roots | **real** root attack of `mq1060_evil_spirit` | 400 rending raw, heavy (5.x: 200 to 300 elemental, light) | — |

On a throwaway build without the slice (the tests kept, classic tree) the regression had 9 failures and the panel 4 (every C2 check but the two spawns): the entities' 5.x values, Eredin's projectile without an effect (and 875 at level 30, 512.5 at the test save's level 1), lightning fists melee, the Hakland hack, both instant kills, the explosion. Regression on the real build: 1,050 passed, 0 failed in each tree, `gmtest_panel()` 102 passed, 0 failed (god() off).

**Verification (AI-C audit fixes, 2026-10-29, both trees; master `6a9fdab3`):** scripted collisions through each projectile's real `OnProjectileCollision` on a neutral bandit (`GMTest_ai17_after`, in `gmtest_panel()`; Geralt the caster where an effect is read): Ifryt's projectile (nothing stored) 200 fire and burning 3 s; the elemental's stone 200 bludgeoning and a knockdown; a sorceress's lightning bolt 40 shock and paralysis 3 s; the ice spear 500 frost and its slowdown 3 s; the Hakland mage's sand coil cast by a deserter 150 physical without a rending hit; the same projectile cast twice in one moment by an NPC with `HaklandMage`: the first hit 150 physical, the second nothing. The regression reads the ice spear's entity value (500). On a throwaway build without the guarded code (the class defaults, the 3 s durations, the ice spear's edit, the rending hit's removal, the Hakland call), deleted afterwards, each of these failed: 20 fire without burning, 20 bludgeoning without a knockdown, paralysis 2 s, 285 frost with 2 s, 150 physical + 150 rending, both Hakland hits dealt.

**Test fix (found by the ECON audit, F5; 2026-11-01, both trees; master `7109c6e5`):** the stone's knockdown lands on a deserter only at random (the audit: 7 to 9 in 10 with the stone alone, fewer after another critical effect; the native effect code, after the port's part), so the panel's single-deserter check failed on some launches. `GMTest_ai17` now spawns three more fresh deserters, and `GMTest_ai17_after` hits each with the stone alone through its real collision: every hit deals 200 bludgeoning and its damage action carries `EET_Knockdown` (the class default, what the port controls; the damage probe reads the action's effect types); the landed knockdowns are logged. Passed on six fresh launches in both trees, with 2, 3, 1, 2, 3 and 2 of 3 knocked down. Requiring a landing on one of three would still fail about 1 run in 30 at that rate, so the landing is logged, not required. No play change.

**Verification (AI-C owner decisions, 2026-10-29, both trees; master `99fd2b88`):** scripted collisions through the real `OnProjectileCollision` on mq1051's contract wyvern (an Essence user, 15 armor; `GMTest_ai17_after`, Geralt the caster), the damage probe reading the action's ignore-armor flag: the sand coil set to ignore armor: 150 physical, armor ignored (0 dealt: physical damage does not hit Essence); a debuff projectile of silver damage (the toad's spit, its type set by the test): 74 dealt without `ignoreArmor`, 80 with it, armor ignored; the sorceresses' stone (a boulder) set to ignore armor: 200 bludgeoning, no rending, armor ignored (0 dealt). On a throwaway build without the code (deleted afterwards) all three failed: armor counted, 74 both times, 200 rending with armor (74 dealt). The same in both trees. Aard's deflection: [SKL-08](skl.md#skl-08-aard).

### AI-19 The Caretaker and quest monsters' immunities

| | |
|---|---|
| Kind | tuning |
| Pillars | P5 |
| 5.x class | clean |
| Flags | — |
| Depends on | AI-03 |
| Skill trees | n/a (checks in both trees) |
| Port form | `ai/caretaker.ws`: `@replaceMethod(BTTaskCaretakerManager)` `OnListenedGameplayEvent` (5.x's body; 5.x's bleed removal at the dispel, in `OnAnimEvent`, untouched); `@addMethod(W3DamageManagerProcessor)` `GMCausesDamageValue`, the `CausesDamage` signal's value, called from one marked line of DEF's replaced `ProcessAction` (`defense/processAction.ws`); binary edits of five entities' `CBuffImmunityParam.immunityTo` by `tools/gen_ai_ent.py` (AI-19 in `PROPS_LATER`; legacy's effect numbers translated to 5.x's by name, `ENUM_ARRAYS`); `mon_caretaker_ep1`, `q604_caretaker`, `q604_shades` given whole (`replace`, Hearts of Stone abilities) by `gen_ai.py` (`SPEC`) in `abilities/gm_ai_monsters.xml` (AI-A audit F1); `Shovel _Stats` and the new `Caretaker Shovel _Stats` whole in `items/gm_ai_weapons.xml` (`AUTO`), the `Caretaker Shovel` and `caretaker_body` items whole (`replace`) naming it (`gen_ai.py`'s `ITEMS`); legacy's NG+-only `mon_caretakereasy_ep1` and `mon_caretakermedium_ep1` in `abilities_plus/gm_ai_ngplus.xml`; the spade's description (2110992475) in the string tables |
| Port status | **signed off** (2026-10-29); ported (the three abilities with the AI-A audit, F1, master `b38c0eed`; the rest in slice C3, master `16111528`), verified in both trees (2026-10-28) |
| Open checks | the Caretaker's heal from a hit on a shade in a real fight (the shades were not summoned; a hit on another NPC signals 1, scripted); the quest monsters' immunities in their own fights (read with `IsImmuneToBuff` on spawned entities); the spade's description on screen (the string read by key); New Game+ (untested, as every NG+ change) |
| Save impact | none |
| NG+ counterpart | applied, untested |

**What it does** (changelist 1134–1135, bugfix 101): the Caretaker heals in proportion to the damage of his hit (1.32: a fixed share per hit), so a heavily armored Geralt can tank him; he still heals fully from killing shades; his weapon uses the Hearts of Stone shovel ability; immune to knockdown, heavy knockdown and bleeding. Immunities also set for Gregoire (acid, bleeding), the `mh102` arachas (poison instead of burning), the ancient fogling (heavy knockdown) and the `mh210` lamia (no longer knockdown).

**Implementation (legacy):** `BTTaskCaretakerManager.OnListenedGameplayEvent` and the `CausesDamage` signal in `W3DamageManagerProcessor.ProcessAction` (the relative damage); `mon_caretaker_ep1` (3,000 Essence and 200 armor in place of 5.x's ×2.5 Essence, 100 armor and +30% attack power), `q604_caretaker` (30% physical and elemental resistances, full will, bleeding and poison resistance, crit damage reduction 0.5; 5.x's −70% attack power, −20% Essence and stamina values gone), `q604_shades` (stamina values gone); `Caretaker Shovel _Stats` (new: 400 slashing, 80 silver; his shovel items in Hearts of Stone's `def_item_weapons.xml` name it in place of `Shovel _Stats`, whose Hearts of Stone duplicate legacy deleted) and the base game's NPC `Shovel _Stats` (150 slashing, 4 silver); five entity files; the player's spade's description (`item_name_caretaker_spade_desc`, a key 5.x leaves without text).

**5.x:** 1.32's healing: `healing_per_hit_perc` of his maximum health per damaging hit (6.6% on Hard, ×1.2 while shades are up); the `CausesDamage` signal carries the damage dealt, which nothing reads; the Caretaker also removes 5.x's three extra bleeding types (`EET_Bleeding1` to `3`) at his dispel. 5.x adds its own entries to two of the five immunity lists (the Caretaker's 61; the arachas's second list 60 and 61: `EET_ShrineAard` and `EET_ShrineAxii` by the script enum's numbers, purpose unknown).

**Decisions:** legacy's. The heal is his maximum health × the hit's relative damage × `healing_per_hit_perc` (× `number_of_shades` while shades are up); the relative damage is legacy's signal value: on Geralt the Vitality the hit took over half his maximum, at most 1; on any other victim (a shade) 1. The immunity lists hold `EEffectType` numbers, and 5.x inserted two effect types at 127 (`EET_Catalyst`, `EET_ConvergenceTheory`), so legacy's numbers are translated by name (legacy's acid, 134, is 5.x's 136); legacy's removals and additions apply to 5.x's lists. The three abilities came ahead of C3 with the AI-A audit (F1): STAM-08's `extend` had emptied them in game (Hearts of Stone abilities, [development.md](../development.md#fine-grained-xml-overrides-50)); legacy's whole abilities carry STAM-08's stamina values (PA2). Until slice C1 the Caretaker inherited 5.x's `mon_wild_hunt_default` (a temporary deviation, ended by C1); his Essence is legacy's: 29,345.4 at his level 34 on Hard = (3,000 + 450 + 33 × 20) × (1 + 33 × 0.15) × 1.2 (4,140 at level 1). The gameplay alias `caretaker` (`secondary_npc\caretaker.w2ent`) is another template, without `mon_caretaker_ep1` (7,925 at level 34); the quest's is `q604_caretaker.w2ent`. The spade's description is legacy's ("Restores Vitality proportional to damage dealt.", nine languages; UI's hand-off).
- **Deviation:** the Caretaker is not immune to 5.x's three new bleeding types (`EET_Bleeding1` to `3`): legacy's list predates them; he keeps removing them at his dispel, as in 5.x; the three are inert since ARM-09 (confirmed by the owner, 2026-10-29).
- **Deviation:** 5.x's own entries in the Caretaker's and mh102's arachas's immunity lists (61; 60 and 61) are kept beside legacy's (confirmed by the owner, 2026-10-29).

**Verification (AI-A audit F1, 2026-10-28, both trees; master `b38c0eed`):** the definitions in game (`gmtest_ability_probe`, scripted reads): `q604_caretaker` 23 attributes (0 before), `q604_shades` 5 (0 before), `mon_caretaker_ep1` 2 (3,000 Essence, 200 armor); the regression's data table (`GMTest_ai03`) reads a legacy value and a `LATER` 5.x value of each, which failed on a throwaway build with the old `extend` entries. The Caretaker at his own level 34 (`gmtest_dummy`, scripted reads): 200 armor, 30% physical, slashing, piercing, bludgeoning, rending and elemental resistance, full will, poison and bleeding, attack power ×1.33 (legacy's: 1 + 33 × 1%; 5.x's abilities gave ×0.93). **Real attacks** (new tree): he hit Geralt with his shovel seven times in 10 s, each at attack power base 363, ×1.33, +33. A shade (`q604_shade.w2ent`): `q604_shades` present, 1.2 Essence (one hit, as in 5.x).

**Verification (slice C3, 2026-10-28, both trees; master `16111528`):** the regression (`GMTest_ai19` in `gmtest_regress()`, `GMTest_ai19_after` in `gmtest_panel()`; scripted): the `CausesDamage` value of a scripted hit of the Caretaker's on Geralt taking 10% of his Vitality 0.2 (5.x: the damage, 350), of one taking 90% 1, of one on a bandit 1; the `Caretaker Shovel` and `caretaker_body` items carry `Caretaker Shovel _Stats`, not `Shovel _Stats`; the spade's description by key is 2110992475's; the shovel abilities' values in the data table (`GMTest_ai03`); the five quest monsters spawned frozen, `IsImmuneToBuff`: the Caretaker to knockdown, heavy knockdown, bleeding tracking (and bleeding, 1.32's), Gregoire to acid, bleeding tracking and the knockdown applicator, mh102's arachas to poison and not to burning, the ancient fogling to heavy knockdown, mh210's lamia not to knockdown (heavy knockdown kept). In game (Geralt at level 1 with 3,500 Vitality, immortal by script; probes on each hit):

| Check | How | Classic tree | New tree |
|---|---|---|---|
| The Caretaker's heal | **real** shovel attacks of a hostile Caretaker (`q604_caretaker.w2ent`, level 34, 29,345.4 Essence; his health set to 50% by script) on Geralt, his health read before and after each hit | a hit dealing 1,579.4 of Geralt's 3,500 (relative 0.902) healed him 1,748.0 = 29,345.4 × 0.902 × 0.066; hits on Geralt at 2 Vitality (1 to 2 dealt) healed 1.1 to 2.5 (5.x: 1,936.8 a hit) | a hit dealing 1,901.7 (relative 1) healed 1,936.8; one dealing 1,597.3 (0.913) 1,767.8; hits of 1 to 2 healed 1.1 to 2.5 |
| His shovel | the same **real** attacks | 376 to 409 slashing, 73 to 85 silver raw (400 and 80 × the melee roll) | the same |

On a throwaway build without the slice (the tests kept, classic tree) the three signal checks, the two item checks, the description and all ten immunity checks failed.

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
| Port status | **signed off** (2026-10-29); ported (slice C3, master `16111528`), verified in both trees (2026-10-28) |
| Open checks | a quest fistfight started by its quest block (the minigame was started by script, through the events the block calls); the Baron's −100 and the quest fights' health in their quests; the sergeant's old-save fix on a real old save (scripted on a bandit); New Game+ (no NG+ level cut; untested, as every NG+ change) |
| Save impact | none |
| NG+ counterpart | applied, untested |

**What it does:** fistfight opponents get no level-difference abilities or NG+ level cut; each tier adds flat fist damage (easy +50, medium +100, hard +150; the Baron −100); opponents' health retuned (`HealthFistFight*`: the tier's flat health in place of 1.32's addition to the opponent's own, and the quest fights'); duplicate tier abilities cleaned up (and the sergeant's save fix); Geralt's Vitality is not clamped to 2,000 in a fistfight; Geralt's fistfight fists 300 bludgeoning and 300 silver (1.32: 150 and 1).

**Implementation (legacy):** 33 fistfight abilities (`StatsFists*`, `SkillFists*`, `HealthFistFight*`, `NPCLevelModFistFight*`, the quest fights, `sq301_fistfighters`, `qSergeantFistFIght`, Geralt's fists); `CNewNPC.OnStartFistfightMinigame`, `ValidateFistfighterAbilities`, `RemoveFistFightLevelDiff`, `FistFightNewGamePlusSetup`, `ApplyFistFightLevelDiff`; `CR4Player.FistFightHealthChange`; `ProcessDamageIncrease`'s fist bonus; the fistfighters' entity lists (`mq0005`'s arsonist, the sergeant, the four `sq301` fighters).

**5.x:** 1.32's. `ApplyFistFightLevelDiff` (the level-difference buffs) has no caller in 1.32 or 5.x, so neither gives fistfight opponents level buffs; 5.x removes an NG+ opponent's NG+ levels of `NPCLevelBonus` at the fight's start (`FistFightNewGamePlusSetup`).

**Decisions:** legacy's; ends DMG-04's temporary deviation (`fist_dmg_bonus`) and AI-02's last one (the fistfighters' tiers and `sq301_fistfighters` in the entity lists). The fist bonus is legacy's first flat addition, before the pool, to the hit's bludgeoning damage (as bludgeoning when it has none), for melee hits of an attacker holding fists. Legacy's commenting-out of `ApplyFistFightLevelDiff` changes nothing in play (no caller); the port leaves 5.x's uncalled function. The earlier statement here that 5.x's fistfight buffs read DA4's thresholds was wrong: DA4 has no fistfight effect. Legacy's tier health abilities set the health with a ×−10 multiplier and a flat addition; the game floors the multiplier, so an opponent's health is its flat additions (the tier's 1,000 to 2,000 and its own) × 5.x's Hard multiplier (1,200 for an Easy opponent, 1,800 for Lugos, Medium). Blood and Wine's drunken master's Hardcore ability (`mon_EP2_hardcore_FF`, legacy's +50 fist damage) is a per-difficulty variant, ported by DIFF ([DIFF-02](diff.md#diff-02-per-enemy-difficulty-variants)).
- Blood and Wine's drunken master gets legacy's +50 fist damage on "Death March!" (`mon_EP2_hardcore_FF`; 5.x: +80% attack power) since DIFF's slice D2 ([DIFF-02](diff.md#diff-02-per-enemy-difficulty-variants), master `7e124300`, 2026-10-29); until then a temporary deviation. Verified with a real fistfight on "Death March!" in both trees: each of his punches carried +200 before the pool, his Hard tier's 150 and the variant's 50. The variant sits in his entity's own ability list, so it is chosen when he spawns (his quest spawns him on the mode being played) and a later mode change drops it.

**Verification (slice C3, 2026-10-28, both trees; master `16111528`):** the regression (`GMTest_ai20` in `gmtest_regress()`, `GMTest_ai20_after` in `gmtest_panel()`; scripted): Geralt's maximum Vitality through `FistFightHealthChange(true)` 3,500 → 3,500 (5.x: 2,000); scripted fist hits of a fistfighter holding its fists add +0 bludgeoning without a tier, +150 with `StatsFistsHard`, +50 with `StatsFistsEasy` (5.x: +0); a bandit with three skill tiers, three stat tiers, five level-difference abilities and the sergeant's mix keeps only `SkillFistsEasy` and `StatsFistsEasy`, no level-difference ability and no `SkillBrigand` after `OnStartFistfightMinigame`, and gets `HealthFistFightEasy`; the abilities' values in the data table (`GMTest_ai03`). In game (the minigame started by script on both sides, as the quest block does, `gmtest_ai20_start`; Geralt at level 1, 3,500 Vitality; probes on each hit):

| Check | How | Classic tree | New tree |
|---|---|---|---|
| Fist bonus by tier | **real** punches of hostile fistfighters on Geralt: Easy `enemy_fists_easy.w2ent`, Medium `q201_lugos_fistfight.w2ent`, Hard `sq701_guillaume_fistfight.w2ent` | +50, +100, +150 bludgeoning before the pool (45 to 55 raw a punch; 180 to 640 dealt) | Medium +100, Hard +150 |
| Opponents' health | the same, read at the start | Easy 1,200.1, Lugos 1,800.25, Guillaume 2,404 (level 35), each with its tier's health ability | Lugos 1,800.25, Guillaume 2,404 |
| Geralt | at the start and end; **real** punches of Geralt's (B1's light attacks) | maximum Vitality 3,500 throughout (5.x: 2,000); his punches 300 bludgeoning and 300 silver raw (`Geralt Fistfight Fists _Stats`), 302 to 322 dealt to the Easy fighter | 3,500 throughout; one punch on Guillaume, 280 raw, parried |

On a throwaway build without the slice (the tests kept, classic tree) the maximum Vitality (2,000), both bonus checks, both tier checks, the level-difference check and the sergeant's fix failed (the tier's health ability, which 5.x adds too, passed). Regression on the real build: `gmtest_regress()` 1,058 passed, 0 failed in each tree, `gmtest_panel()` 123 passed, 0 failed (`god()` off).

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

### AI-C audit (2026-10-28)

Done by a fresh session ([audit](../feature-mapping.md#audit-signing-a-feature-off)) on master `16111528` (port) and `ebfeceef` (docs), reading code and data, with game runs in both trees on 2026-10-29. The three slices' commits (master `c94ce08e`, `78c2e754`, `16111528`) were read whole. Every method they replace, wrap or add was read against legacy (`legacy-GM`), 1.32 (`vanilla-1.32`) and 5.x (`vanilla-5.x`), with every caller and subclass of the changed functions.

**Data** was checked by scripts written for this audit, independently of `gen_ai.py` and `gen_ai_ent.py`:
1. **Abilities and items.** All 171 ability units attributed to AI-15, AI-16, AI-18 (the `Hakland*` abilities, the magic fists), AI-19 and AI-20, plus `MonsterMHBoss`: 83 regular and 88 NG+. Each was compared node by node with legacy's definition as the game reads it in the port. That reading is 5.x's files with every Ghost Mode DLC entry applied: `replace` whole; `extend` by tag in order; `extend` on an expansion ability as empty.
2. **Legacy's other changes in the same files.** Every other ability legacy changed in the 18 files these units live in (1,386).
3. **The items.** The `Caretaker Shovel` and `caretaker_body` items, against legacy's and 5.x's.
4. **The entities.** The 27 entity files AI-C edits, dumped by `cr2w_dump.py` for `vanilla-1.32`, `legacy-GM`, `vanilla-5.x` and the port:
   - the projectile and obstacle properties (`projDMG`, `projSilverDMG`, `ignoreArmor`, `destroyQuen`, `dealDamageEvenIfDodging`, `damageTypeName`, `damageValue`, `debuffDuration`, `damageVal`, `poisonDamage`);
   - `CBuffImmunityParam.immunityTo`, its effect numbers translated by name through `EEffectType` tables built from each branch's `effectTypes.ws`;
   - `CCharacterStatsParam.abilities`;
   - each property in the object and in its compiled copy.

   A scan of all 630 entity files legacy changed then looked for edits of those properties anywhere else.

**Checked and holding:**

**Data**
- **Abilities.** All 171 units read legacy's values, except two kinds of `LATER` node:
  - experience: `MonsterMHBoss`, the three `WildHunt_*_NGPlus`;
  - weight: `Shovel _Stats` 8 for legacy's 1, from Hearts of Stone's duplicate that legacy deleted; the Hunt's three weapons.
- **How they are given.**
  - Every Hearts of Stone ability is given by `replace`: `q604_caretaker`, `q604_shades`, `mon_caretaker_ep1` and its two NG+-only variants, `WeakenedState`, the three `Hakland*`, `Shovel _Stats`.
  - No AI-C ability has two Ghost Mode homes.
  - The four abilities legacy moved between files read legacy's definition.
  - The only 5.x node a whole replacement drops is `HaklandMage`'s empty `force_resistance_perc`, which legacy deleted.
- **NG+ copies.** They equal legacy's, and the five NG+-only entries equal legacy's `_plus` definitions.
- **Unported changes in these files.** Of legacy's other 1,386 changed abilities, the 46 not ported are DIFF's (per-difficulty variants, Ciri, `ModSigns*`, `PrologModifier`); none is attributed to AI-C.
- **Items.**
  - The two Caretaker items equal legacy's. They differ from 5.x's only in naming `Caretaker Shovel _Stats`.
  - The base game's NPC `Shovel` items keep `Shovel _Stats`, as legacy.
- **Projectile and obstacle entities.**
  - Exactly 16 files carry legacy's projectile and obstacle edits: 13 projectiles and 3 obstacles. All 16 are the ports' files, and no other entity has such an edit.
  - Their 89 legacy edits are applied to 5.x's values in both copies, including the four 5.x had changed: the echinops acid 350, Dettlaff's swarm 600, the toad's spit 200 poison and its tongue 300.
- **Immunity lists.** The 7 lists in the 5 AI-19 files equal 5.x's lists with legacy's additions and removals by name. Legacy's acid, 134 in 1.32, is written as 136. The only extras are 5.x's `EET_ShrineAard` and `EET_ShrineAxii`, the recorded deviation.
- **Ability lists.** The 12 ability lists of the fistfighters and AI-19's other entities equal 5.x's plus legacy's edits.
- **Nothing else changed** in the 27 files.

**Code**
- **AI-15, Ice Armor.**
  - `GMIceArmorResistBonus` equals legacy's term and sits in legacy's place, before the resistance reductions.
  - The final resistance is clamped to [0, 1], so a fully frost-resistant warrior's 130% heals nothing.
  - The `OnFireHit` wrapper runs after 5.x's body. Both of the pipeline's fire callers reach it.
  - 5.x's halving and `EredinInvulnerable` lines are gone from `ReduceDamage`.
- **AI-17, `ProcessInstantKill`.** The function equals legacy's two rules on SKL-05's 5.x body. Axii's instant kill (SKL-12's `GMIsAxiiInstakillTarget`) excludes contract monsters too, as legacy. Nothing changes the damage between `ProcessInstantKill` and `DealDamage`.
- **The rotfiend explosion.** It equals legacy's.
- **AI-19, the Caretaker's heal and its signal.** These equal legacy's. `BTTaskCaretakerManager` is the only listener of `CausesDamage` in 5.x, 1.32 and legacy, so the changed value breaks nothing else.
- **AI-20, fistfights.**
  - These equal legacy's on 5.x's bodies: `OnStartFistfightMinigame`, `GMValidateFistfighterAbilities`, `RemoveFistFightLevelDiff`, `FistFightHealthChange` and `GMAddFistDamageBonus`. The last is legacy's own block, in legacy's place after `VulnerableFromFront`.
  - `ClampGeraltMaxHealth` has no other caller, so nothing clamps Geralt's Vitality.
  - `ApplyFistFightLevelDiff` has no caller.
  - The quest block's `ChangeCombatStyleByTag` is unchanged by legacy.
- **AI-18 holds** apart from F1 to F4:
  - Every replaced body is 5.x's plus legacy's changes.
  - The only projectile level term in 5.x is in `W3AdvancedProjectile.OnProjectileCollision`, and every subclass calls `super`. That includes the thrall boulder, arrows, bolts and the trace-ground classes, so PA11 holds for every projectile.
  - No subclass bypasses a replacement.
  - No 5.x fix inside a replaced body is lost; only the debuff projectile's armor line changed, F1.
  - Attack or spell power is applied once, through the action's power stat.
  - The magic fists count as ranged only for the `fists_lightning` and `fists_fire` items, as legacy.
- **AI-21.** Nothing of it is in the port: no `toggledebugpreattack`, its fact, `lastAttackTime` or `GetDelaySinceLastAttack`.

**Tool checks**
- `check_modsigns.py`: 487 bodies, 0 unmarked.
- `deviations.py --check`, `gen_ai.py --check`, `gen_ai_ent.py --check` and `gen_ngplus.py --check` pass.

**In game**
Geralt immortal by script; a throwaway probe mod, removed afterwards, read Geralt's abilities before and after.

| Check | How | Classic tree | New tree |
|---|---|---|---|
| A fistfight played to its end | The minigame started by script as the quest block does (`gmtest_ai20_start`). **Real** punches (`gmtest_light`) until the opponent was knocked out. The end called on both sides as the quest block does. | Easy `enemy_fists_easy`: 1,200.1 health, knocked out by five landed punches (about 300 each) while it hit Geralt with its +50 fist bonus. After the end: Geralt's maximum Vitality 3,500 (3,500 at the start and throughout), Vitality refilled to full. No fistfight ability left on Geralt: the only difference is his normal fist items' abilities back in hand. The opponent revived at full health with its tier health ability (5.x and legacy alike). | Lugos (Medium, level 17): 1,800.25, knocked out by seven landed punches. After the end the same: Geralt 3,500 maximum, nothing left on him. |
| The Caretaker in a long fight | **Real** shovel attacks for 50 s, his health set to 50% | He healed in proportion to each hit. At Geralt 1 to 15 Vitality, hits dealing 0.15 to 14 healed 0.1 to 12; no shade was summoned, so the heal from a shade stays unchecked. | — |
| A rotfiend after an instant kill | **Real** light attack with vanilla's `ForceInstantKill`, then without it | 840 → 210 (25%). The next **real** hit dealt 0 and set off LastBreath. It died about 15 s later from a damage-over-time effect, and no explosion hit Geralt 2 m away (EFX-09's finding: a real death runs no explosion). | — |
| Firestream on Ice Armor | **Real** held Igni (`autocast(ST_Igni, true)`, `magic_s2`) on a hostile Wild Hunt warrior with Ice Armor | Firestream's first hit (no fire damage) took the armor off through 5.x's `OnIgniHit`. Its ticks are damage over time, without the +30%. | — |

**Regression:** `gmtest_regress()` 1,058 passed, 0 failed in each tree (`god()` off), and `gmtest_panel()` 123 passed, 0 failed in each tree.

**Findings:**

1. **Debuff projectiles keep 5.x's armor rule** (low; owner decision).
   - In 1.32 and legacy, a debuff projectile with `ignoreArmor` ignores armor on every victim. 5.x and the port ignore it only on Vitality users (`DebuffProjectile.OnProjectileCollision`, `ai/specialAttacks.ws`).
   - Play effect: none on Geralt. Such a projectile that strikes a monster (an Essence user) goes through that monster's armor.
   - The entry records this rule for boulders only (the second deviation), not here.
   - Options: (a) legacy's line, as legacy behaviour first asks; (b) keep 5.x's rule and record it as a deviation beside the boulders'. Recommendation: (a), since it has no effect on Geralt and is legacy's code.
   - Tested by reading the code only.
2. **Entity values that 1.32 and 5.x ignored now count, and only legacy's 16 entities were checked** (low; clear fix, a scan).
   - Like legacy, the port makes four classes read the entity's `projDMG` and `projEfect` instead of a fixed 200 and effect: `W3ElementalIfrytProjectile`, `W3ElementalDaoProjectile`, `W3StoneProjectile`, `W3EnvironmentProjectile`.
   - The poison, fireball, meteor and lightning classes now read the entity's effect.
   - Any 5.x entity of these classes that stores a value of its own now deals or applies it. Such entities are new content, or ones 5.x re-saved.
   - Fix: scan the game's bundles for entities of these classes (`unbundle.py`, `cr2w_dump.py`). Record what they store, and give legacy's value where a stored one differs from the 200 or the effect 1.32 used.
   - Tested by reading the code only.
3. **Gaps in the regression** (low, test-only; clear fix).
   - **The Hakland mage's check is helper-only.** "The Hakland mage's second debuff hit within 3 s does not count" calls `GMHaklandMageDebuffProjectileHack()` itself. It would pass with the call in `DebuffProjectile.OnProjectileCollision` removed.
   - **Untested defaults.** No check reads a class default: Eredin's entity sets its own 500. Nine classes' 200 and effects, the 3 s effect durations of the poison, fireball, Ifryt, meteor and lightning projectiles, and the ice spear's 3 s have no check.
   - **The rending hit's removal** is seen only in C2's real water-hag hit.
   - Fix:
     - Label the Hakland check as the helper's only.
     - Add a scripted collision of a projectile whose entity sets no damage (as `GMTest_ai17_after` does for Eredin's), reading 200 and a 3 s effect.
     - Add a scripted debuff projectile collision reading one damage type.
   - Each new check is to be shown failing on a throwaway build.
4. **Doc and comment corrections** (doc-only; clear fix).
   - AI-18's "Implementation (legacy)" says 14 projectile entities: legacy edited 16 (13 projectiles, 2 quicksands, the toad's acid pool).
   - "What it does" says the special attacks use attack power. Eight projectile classes use the caster's spell power (`CPS_SpellPower`), as in legacy and 1.32: Ifryt, Eredin's, poison, fireball, Dracolizard, ice meteor, lightning strike, lightning bolt.
   - AI-18's open checks lack the bird swarms and the leshen's birds; neither has been seen in a fight.
   - `ai/instantKill.ws`'s header says a rotfiend cut by an instant kill "swells and explodes instead of dying". It fights on at 25%, and the next hit sets off LastBreath (seen above).
   - `gmTestsAi17.ws`'s comment on Eredin's projectile says 200 frost; the check reads 500.
   - The ground trap's comment credits a no-op line; the light reaction comes from `EHRT_Light`.
   - In the leshen roots' and red-plague roots' bodies, `SetHitAnimationPlayType` and `.attacker` are set before `Initialize`, which clears them: dead lines.
5. **Stones and environment projectiles keep 5.x's Aard deflection** (low; outside AI-C, for SKL-08; owner decision).
   - Legacy added `W3StoneProjectile.OnAardHit` with a fixed 0.7 of the speed, and 1.32's environment projectile used 0.7. 5.x makes both depend on Aard Sweep and Aard Intensity (0.1 without them).
   - D25 and SKL-08's port cover the boulders only. `attribution.csv` gives the stone's handler to SKL-08 as "in 5.x", and no deviation is recorded.
   - Options: (a) legacy's 0.7 for stones and environment projectiles too, as D25 decided for boulders; (b) keep 5.x's and record a deviation. Recommendation: (a).
   - Tested by reading the code only.
6. **The sergeant shows level 22** (low; outside AI-C: AI-06's level, AI-20's fighter; clear fix).
   - Legacy turned the sergeant's fake level into a real one: `level` 0 → 11 and `levelFakeAddon` 11 → 0.
   - The port took the level, in slice A3, but left 5.x's addon, so the HUD shows 11 + 11 = 22 (UI-12's displayed level adds the addon).
   - UI-12's deviation keeps the addon in general, until DIFF, but here the pair doubles the level.
   - Fix: write legacy's `levelFakeAddon` 0 for this file with its level (`gen_ai_ent.py`). Also check the other files of the 72 where legacy moved an addon into the level.
   - Tested by reading the data only; not seen in game.
7. **Not verified in game** (no action; open checks). Kept in the entries:
   - The Caretaker's heal from a shade (no shade came in a 50 s fight; summons come from his tree).
   - Eredin and Caranthir in a real fight.
   - The djinn's rage in a real fight.
   - The Blood and Wine projectiles, the boiling water, the quicksand, the bird swarms.
   - A quest fistfight started by its quest block.
   - New Game+.

**Autosave:** none written during the runs; the newest, `<save name>`, dates from slice C3's session. The test save is unchanged.

**Not reviewed:** legacy's own behaviour in play; NG+ in game.

**Suggested fix slices:**
- **C** (code and tests): F1 once decided, F3.
- **D** (data): F2's scan, F6.
- **W** (docs): F4.
- F5 goes to SKL-08.

**Fixes done** (2026-10-29; docs on master): F2, F3, F4, F6 in master `6a9fdab3`; the owner's decisions F1 and F5 (option (a) each) in master `99fd2b88`; all verified in both trees.

Outcomes:
1. **Fixed as decided** (owner, 2026-10-29, option (a); master `99fd2b88`): debuff projectiles set to ignore armor ignore it on every victim (legacy's line). With it, boulders take legacy's rule (owner): bludgeoning damage and `ignoreArmor` on every victim; the thrall boulder keeps 5.x's (the deviation, now confirmed). Scripted collisions on an armored monster, each failing on a throwaway build ([AI-18](#ai-18-special-attacks-and-monster-projectiles)).
2. **Fixed** (D): every 5.x projectile entity scanned ([AI-18's entity scan](#ai-18-special-attacks-and-monster-projectiles)): 58 files, the same in both games; 57 read what legacy read. The one that did not, the Wild Hunt mage's (Caranthir's) ice spear, 1.32 and legacy 500, 5.x 285, takes 500 through `gen_ai_ent.py`'s new `GAME_FILES` (legacy left the file as 1.32's; 5.x lowered it for its level term, which PA11 removed; a porter's call, confirmed by the owner, 2026-10-29). Read in game: the entity 500, and 500 frost with a 3 s slowdown at a scripted collision.
3. **Fixed** (C): `GMTest_ai17_after` collides projectiles through their real `OnProjectileCollision` (`GMTestAi17Collide`): the class defaults with 3 s effects (Ifryt's 200 fire and burning, the elemental's stone 200 and a knockdown, a sorceress's lightning bolt's paralysis), the ice spear's slowdown, a debuff projectile without the rending hit, and the Hakland mage's projectile twice in one moment (the second deals nothing; the helper-only check is gone). Each failed on a throwaway build without its code (deleted afterwards).
4. **Corrected** (W): AI-18's 16 entities, its attack and spell power wording, the bird swarms and the leshen's birds in its open checks; `instantKill.ws`'s header; the test comments' 500 frost; the ground trap's comment (the light reaction is `EHRT_Light`'s; the removed line was a no-op); the two dead lines in the leshen's roots and the red-plague creature's roots removed (`Initialize` clears them), the bodies' other lines still marked.
5. **Fixed as decided** (owner, 2026-10-29, option (a); master `99fd2b88`, [SKL-08](skl.md#skl-08-aard) slice 7): Aard deflects stones and environment projectiles at 0.7 of their speed whatever the skills, as boulders (D25). Real Aard casts on stones, environment projectiles and boulders shot by script, in both trees.
6. **Fixed** (D): legacy changed `levelFakeAddon` in 71 AI entity files, each time turning a fake level into a real one; all 71 now carry legacy's addon with legacy's level (`gen_ai_ent.py`'s `PROPS`, [AI-06](#ai-06-enemy-levels-and-flags); all 71, not only the sergeant's: a porter's call, confirmed by the owner, 2026-10-29). Beyond the sergeant: Blood and Wine's quest fighters, guards and thugs (27 to 49), Olgierd's men (29, 32), the Novigrad and Skellige fistfighters, Lugos (17, was 46 on the HUD), the `q201` stuffed animals (16, was 86), `sq209`'s Eredin vision (19, was 49). The 72nd file legacy changed, `mq1028_gerd` (addon 1 → 0 without a level), is not an AI file: DIFF's. The sergeant's level on the HUD, **real** (spawned hostile with `gmtest_ai17_a`, locked on with `autolock()`, screenshot): 11 in red in both trees (master `16111528`: 22); the regression reads his displayed level (11; 22 on the throwaway build).
7. **Recorded**: the open checks stay in the entries.

#### AI-C audit close-out

Closed 2026-10-29: F2, F3 and F6 fixed and verified in both trees, F4 corrected, F7 recorded (master `6a9fdab3`); the owner's decisions F1 and F5 implemented as legacy's and verified in both trees (master `99fd2b88`), with boulders taking legacy's rule too (bludgeoning, `ignoreArmor` on every victim). **Owner confirmations (2026-10-29):** the Hunt's warriors and Imlerith keep their burning immunity (AI-15; the legacy test stays open); a rotfiend cut to 25% by an instant kill fights on without swelling (AI-17); 5.x's second rending hit of debuff projectiles removed (AI-18); the thrall boulder keeps 5.x's rules (AI-18's deviation); the Caretaker not immune to 5.x's three new bleeding types, and 5.x's extra immunity entries kept (AI-19's two deviations); the drunken master's Hardcore +50 fist bonus left to DIFF (AI-20's temporary deviation). **Porter's calls confirmed by the owner (2026-10-29):** the ice spear's 1.32 value (F2); the fake level addon taken with the level in all 71 files, not only the sergeant's (F6). No deviation added or ended (113; the boulder deviation narrowed to the thrall boulder). Checks at close (master `99fd2b88`): `gmtest_regress()` 1,062 passed, 0 failed in each tree (`god()` off, `--wait 4500`: at less AI-10's counter-window check can miss its samples on this machine, [development.md](../development.md#testing-in-game)), `gmtest_panel()` 133 passed, 0 failed in each tree; `check_modsigns.py` 0 unmarked; `deviations.py --check` current; `gen_ai.py --verify` and `gen_ai_ent.py --verify` pass. No autosave was written (the newest, `<save name>`, dates from slice C3's session); the test save is unchanged. What stays open: the open checks (F7). **AI-C signed off** by the project owner (2026-10-29), with the open checks kept open; the owner confirmed AI-C's porter's calls and deviations, the last two (the ice spear's 500, the fake level addon in all 71 files) on 2026-10-29. With AI-A and AI-B (2026-10-28), **the AI area is signed off**.

---

### Dependencies on other areas

- **Done areas AI builds on:** DMG (the formula, the pool, the lazy armor fix, allies), STAM-08 (NPC stamina; the same abilities), DEF-06 (enemy guards after a counter), SKL-08, SKL-10, SKL-12 (Aard, Yrden, Axii's Puppet and instant kill), EFX-05, EFX-09 (frost slowdown, the frozen rotfiend), ALCH-14, ALCH-15, ALCH-16 (Silver Dust, Dimeritium, oils by category), XBOW-08 (NPC bows), UI-11, UI-12 (journals, the enemy level), LOOT (the same entity files).
- **Areas AI shares with or waits for:** DIFF (scaling options, difficulty multipliers and variants, Ciri, fake levels), XP (kill experience), FIX (projectile collisions), WGT, ECON.

### Hand-offs received

Every item other areas handed to AI, and where it lands:

| From | Item | AI |
|---|---|---|
| DMG (hand-off), DMG-13 | The enemy stat model's level bonuses and NPC templates | AI-01, AI-02 (the difficulty multipliers and scaling options: DIFF, DA2) |
| DMG (hand-off) | About 2,900 XML units with damage stats, the AI part: NPC armor with resistances, `WeakenedState`, monster armor and resistances (about 830 units), NPC and monster weapons | AI-04, AI-16, AI-03, AI-05 (2,000 units counted here, NG+ included) |
| DMG (hand-off), DMG-02 deviation | Ice Armor: +30% resistances, removed by any fire (`OnFireHit`); `EredinInvulnerable` | AI-15 (ported in slice C1); the deviation ended |
| DMG (hand-off), DMG-04 deviation | `fist_dmg_bonus` | AI-20 (ported in slice C3); the deviation ended |
| DMG (hand-off), EFX (hand-off) | The hit-severity half of `ModifyHitSeverityReactionFromDamage`, `ModifyHitSeverityReaction`, `ModifySeverity` (poise, golems) | AI-12 (ported in slice B2) |
| DMG (hand-off) | Monster-hunt monsters immune to instant kills, `GetLastBreathMaxAllowedDamage` | AI-17 (ported in slice C2) |
| DMG (hand-off), EFX (hand-off), XBOW (hand-off) | NPC special-attack damage (tornado, ground trap, ice spike, leshen roots and birds, boiling water, critters, `advancedProjectile.ws`), monster projectiles' effect lengths, magic fists | AI-18 (ported in slice C2) |
| DMG (hand-off) | The Caretaker's heal | AI-19 (ported in slice C3) |
| XBOW (hand-off), XBOW-08 deviation | 5.x's level term on projectile damage (reflected arrows, monster projectiles) | AI-18 (PA11, ported in slice C2); the deviation ended |
| XBOW, SKL, EFX (hand-offs) | `CNewNPC.ReactToBeingHit`: flyers forced to land | AI-13 (ported in slice B2: bolts, Yrden's shock and burning, both trees) |
| XBOW (hand-off) | The Skellige archers' and the Emhyr crossbowman's levels and attack ranges | AI-06 (levels); the attack ranges are W3Edit's lost `rangeShort` cones (138 files, re-save noise, binary-files.md): nothing to port |
| SWD, ITEM (hand-offs) | NPC swords and weapons, secondary weapons and their quality and damage, monster weapons, fists, the Caretaker's shovel; NPC scabbards (`bound_items`) | AI-05 (with Hearts of Stone's NPC torch, a unit the mapping missed: AI-A audit F2), AI-19 (`Shovel _Stats`, and `Caretaker Shovel _Stats`, attributed by the audit; ported in slice C3), AI-20 (Geralt's fists, slice C3); quality and damage nodes AI-05's; the scabbards: no change of legacy's found in the weapons' entries (to recheck in AI-05's generator) |
| DEF (hand-off), DEF audit F12 | NPC dodge rules and tasks, the air and ground guards, the 0.25 s wait, `CBTTaskReaction.Main` with its stun guard, the 2.5 s counter windows | AI-09, AI-10 (ported in slice B1; the reaction task's fix inert, no 5.x tree uses the task); the minimum distance is vanilla's (nothing to port) |
| STAM (hand-off) | Dodge timing and distance, NPC Quen's stagger; the fiend's tree (to FIX) | AI-09, AI-14 (ported in slices B1 and B3); the fiend's tree moved to AI-14 (PA9), where 5.x's tree already has the branch |
| SKL (hand-off) | The Yrden turret's removed `EntersYrden`/`LeavesYrden` signals | Kept by SKL-10 as 5.x's (confirmed by the owner, 2026-10-16): nothing for AI |
| SKL (hand-off) | NPC Quen | AI-14 (ported in slice B3: the default stagger on a melee attacker, a real fight with Reinald) |
| EFX (hand-off) | NPC weapons and attacks with frost slowdown (Wild Hunt, bugfix 75) | AI-05 (the weapons, slice A2; Eredin's sword's slowdown seen in C1), AI-18 (Eredin's frost projectile, ported in C2) |
| EFX (hand-off) | `ProcessShieldDestruction` | AI-10 |
| EFX (hand-off), EFX-05 | The fiend's hypnosis length (5.x: 20 s by default) | Legacy changed none: nothing to port (EFX-05's default is ported) |
| EFX (hand-off) | Monsters' effect resistances | AI-03 (the resistance nodes), AI-19 (immunities, ported in slice C3) |
| EFX (hand-off), EFX-09 | The rotfiend explosion's damage | AI-17 (ported in slice C2) |
| ALCH (hand-off) | Witch boiling water; monster abilities blocked by Silver Dust and Dimeritium; the frozen rotfiend | AI-18 (ported in slice C2); the blocks are ported by ALCH-14 and ALCH-15; the rotfiend AI-17 (C2) |
| UI (hand-off) | The creatures' weakness lists (12 entity files) | AI-07 |
| UI (hand-off) | The Caretaker's spade text (2110992475) | AI-19 (ported in slice C3: the player's spade's description, a key 5.x leaves without text) |
| LOOT (hand-off) | The other properties of the binary entities LOOT edits (stats, abilities, levels, immunities) | AI-02, AI-06, AI-07, AI-19 (41 of LOOT's files) |
| Open question (STAM-08) | Ungated NPC attacks | Waits for the author's answer; no AI slice depends on it. If every attack is to be refused without stamina, the fix is STAM-08's (the attack's start) |
| feature-mapping (roadmap, step 5) | The `AI` area | this file |

### Hand-off to other areas

| Area | Changes |
|---|---|
| DIFF | The scaling options and their code paths in `AddLevelBonuses` (random levels `savedRandomLevel`, nonlinear level-up, animals halved, guards' extra levels), `ModSignsAddBonuses` and the `ModSigns*` abilities, `W3GameParams.Get*Mult`/`GetEnemyScalingOption` and the other option getters, the menu; `difficulty_Common*`, `PrologModifier`; 65 per-difficulty enemy variants and their NG+ copies (with Blood and Wine's drunken master's Hardcore fist bonus, `mon_EP2_hardcore_FF`, unattributed: AI-20's temporary deviation); Ciri's abilities; `levelFakeAddon` in `mq1028_gerd` (the other 71 files' addons came with AI-06's levels, AI-C audit F6); `r4Game.GetSpawnDifficultyMode` |
| XP | `CalculateExperiencePoints`, `GetExpByEnemyType`, `GetEnemyTypeByAbility`, the level abilities' `experience` nodes; DA4's thresholds (6 and 15 since slice A1) already move 5.x's quest experience cut-off (no experience 6 or more levels below Geralt) and kill-experience bonuses, which legacy rewrote (AI-A audit F5) |
| FIX | `CBTTaskShoot.ShootProjectile`, `CBTTaskProjectileAttack.Initialize` (collision groups) |
| SKL | The siren crawl finisher's animation (`SetupSimpleSyncAnim`); `attack_light` and `attack_speed_based` lose their `focus_gain` (Geralt's adrenaline) |
| WGT, ECON | Weapon weights; weapon prices |

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

### Port order

Each part is ported, audited and signed off before the next (DA1). Each slice compiles and is verified on its own with spawned enemies (`spawn()`, the test save), the damage probe and the regression; slices touching a skill run in both trees.

| # | Slice | Ends |
|---|---|---|
| A1 | AI-01, AI-02's abilities: the level model and templates, the thresholds (DA4, with SKL-12's finisher rule and UI-12's red level); `gen_ai.py`; levels and bonuses read by script on spawned humans, monsters, a wolf, a guard at Geralt levels 1, 10 and 30 (**done**, 2026-10-28, master `9dfb2078`) | the New Game+ addon part of UI-12's temporary deviation |
| A2 | AI-03, AI-04, AI-05: `gen_ai.py --verify` (monsters, humans, weapons; STAM-08's abilities absorbed, PA2); `MonsterMHBoss` (its 8,000 Essence and attack power go with the contract monsters' own abilities; its instant-kill tag is checked in C2); the new enemies' numbers (DA5); a drowner, nekker, griffin, golem, bandit in plate read by script and fought (damage probe through armor) (**done**, 2026-10-28, master `cd569312`) | DMG's "fights judged once AI and DIFF port the stats" (DMG-13) for AI's share |
| A3 | AI-06, AI-07 and AI-02's template lists: the entity edits (levels, flags, categories, weaknesses, constitution templates), and AI-06's two level fixes in `AddLevelBonuses`; a spider's category with an oil, a ghostly human with silver, levels of spawned templates (**done**, 2026-10-28, master `f9b08de3`) | — |
| B1 | AI-08, AI-09, AI-10: combat rolls, dodging, guarding and taunts; real fights against a bandit, a wolf, a fiend, a golem and a bear, counting the AI's rolls (**done**, 2026-10-28, master `e5fc2b5c`) | DEF audit F12's hand-off; AI-08's temporary deviation (5.x's rolls in AI-A's abilities) and AI-02's for the combat-skill templates |
| B2 | AI-11, AI-12, AI-13: targeting with a puppet and an ally, poise on a fiend (trolls are not huge by legacy's rule) and a golem, a flying harpy knocked down by a sword hit, a bolt, Yrden's shock and burning (both trees) (**done**, 2026-10-28, master `cf290eed`) | A2's temporary AI-12 deviation (5.x's `hit_severity`) |
| B3 | AI-14: the cyclops with Axii, the toad in Yrden (both trees), NPC Quen, the arachas's speed (**done**, 2026-10-28, master `654bc96e`) | AI-02's temporary deviation for the Goldilocks bears' `ablIgnoreSigns` (narrowed to AI-20) |
| C1 | AI-15, AI-16: Ice Armor with Igni and a fire bomb (both trees), frost hits from a Hunt warrior, the djinn's rage (**done**, 2026-10-28, master `c94ce08e`) | DMG-02's deviation; B1's (the Hunt's and the djinn's stats, AI-08); AI-19's `mon_wild_hunt_default` |
| C2 | AI-17, AI-18: a contract monster against an instant kill, a rotfiend's explosion, monster projectiles' damage at Geralt levels 1 and 30, a reflected arrow; Eredin's frost projectile (AI-15's damage and slowdown) (**done**, 2026-10-28, master `78c2e754`) | XBOW-08's deviation; AI-15's (Eredin's frost projectile) |
| C3 | AI-19, AI-20: the Caretaker's healing, a fistfight at each tier (AI-19's three abilities came with the AI-A audit's fix, 2026-10-28) (**done**, 2026-10-28, master `16111528`) | DMG-04's deviation; AI-02's (the fistfighters' tiers in the entity lists) |

**Later:** the AI-C audit (**done**, 2026-10-28, [AI-C audit](#ai-c-audit-2026-10-28): 7 findings, two owner decisions); its fixes (**done**, 2026-10-29, master `6a9fdab3` and `99fd2b88`); AI-C **signed off** (2026-10-29), closing the AI area.
