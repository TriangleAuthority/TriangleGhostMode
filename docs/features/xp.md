# XP: experience and levels

How Geralt gains experience and what a level gives him: experience from quests (by the quest's level against Geralt's), the reward amounts and quest levels, experience from kills (by enemy type, level difference and how many of that type he has killed), the smaller sources (monster nests, bribes), the "Experience" options, the Vitality each level adds, and the skill points per level in each skill tree. Ghost Mode's changelist has its own section, "Experience" (lines 1075–1089), the experience half of "Mod options" (lines 1217–1225), the difficulty line "Experience gained no longer depends on difficulty level" (line 1142, DIFF-08) and the level-up line of "General player abilities" (lines 472–473); the mod description's section 6, "Quests, experience and rewards", and section 9, point 3, explain the intent.

**The player-visible texts first.** Legacy's changelist, quoted exactly: "Experience tables were reworked, difficulty dependent modifiers were removed. Experience scaling is now smooth: you get progressively less experience for lower level quests and more experience for higher level quests."; "Experience for kills was reworked, you get progressively less experience for killing monsters of the same type."; "You always get at least 5 XP for quests and at least 1 XP for monsters."; "Smooth experience adjustment means that you can can now get more experience for higher level quests, so they're now worth the trouble."; "Quest levels were tweaked so they make more sense (especially for Novigrad and Skellige where completing level 14 quest could result in next quest being level 9)."; "Some of the side quests related to main quest were moved later into the game, because they can indeed be completed later and to spread experience and quests a bit."; "Experience gained no longer depends on difficulty level."; "Passive attack and sign power bonuses were removed from Geralt's levelups: each level now adds 50 points to base Geralt's health - and nothing more."; and for the options: "Experience presets: default - everything zero and off.", "Disable quest levels: disables levels for quests, affects the numbers displayed in UI and quest XP gain; doesn't affect NPC levels are those are independent from quest levels internally.", "Fixed experience for quests and combat: disables smooth experience scaling and progressive experience for kills, the amount of exp rewarded is always the same and is define by quest settings and monster type.", "Quest/combat experience modifiers: allow to reduce or increase the amount of exp gained from quests/combat. The formula: XP*(1 + modifier)." The mod description adds "you get progressively more (up to 150%) experience for higher level quests/opponents and progressively less (up to 0%) for lower level quests/opponents" and "huge spikes like 4000 exp points at once were replaced with more reasonable rewards". Legacy's menu (Options → Mods → Ghost Mode, group "Experience", preset list "Experience Presets" with one preset, "Default") has "Disable quest levels", "Fixed experience for quests and combat", "Quest experience modifier" and "Combat experience modifier" (string ids 2110992328, 2110992452, 2110992451, 2110992253, 2110992300, 2110992270, 2110992271; 9 languages). Legacy also prints each kill's experience in the combat log with vanilla's string "Experience Points: $I$" (1066285, the key `hud_combat_log_gained_experience`, the same in 1.32 and 5.x). The game's own texts on levels (decoded from 1.32's and 5.x's `en.w3strings` with `w3strings.py`): "Each time you gain a level, you receive one Ability Point, which you can use to learn a new Ability or develop an Ability you already have." (1076557, unchanged in 5.x), and the tutorial 1076528, which 5.x rewrote for its new tree: 1.32 "When you have gained a certain number of Experience Points, you advance to the next level. You get Experience Points for killing monsters and completing quests.", 5.x "Gain Experience Points by killing monsters and completing quests to level up. Each level grants Ability Points, which you can spend to unlock or upgrade Abilities. Abilities only take effect when placed in an open Ability slot. They can be swapped at any time." (markup left out). Legacy changed none of them.

**What 5.x did in this area** (from `vanilla-5.x`, unverified in game). Almost nothing: the experience curve (`geralt_levelups.xml`: 1,000 XP per level at first, 84,000 in all for level 50, 2,000 per level after it, 1 skill point per level, cap 100), the quest experience rule (`CR4Game.OnGiveReward`), the kill experience formula (`CNewNPC.CalculateExperiencePoints`, its call in `OnDeath`), monster nests, bribes, `exp_mods.csv` (1 and 1), the quest levels and reward experience and levels, and the level-up abilities (`Lvl2` to `Lvl50`, regular and NG+) are 1.32's. What moved: the level-difference thresholds the quest and kill rules read (`LEVEL_DIFF_HIGH`/`DEADLY` 6/15 → 10/20; already back to 6/15 in the port since AI-01, DA4); 7 new rewards, 4 with experience (`q504_horse_returned` level 30, 20 XP; `sq106_3_hammond_killed_crach` level 11, 50 XP; `mq1060_priest_reward` and `mq1060_priest_dead_reward` level 15, 75 XP) and gold changes in 10 rewards (ECON); one new quest level (`mq1060_devils_pit` 15); the new tree's "Ability Points" (the same 1 per level) and its skill slots unlocked by points spent (SKL-01 set them back to levels); `W3LevelManager.AddPoints` updates the skill slots; the tutorial text above; and who earns a kill's experience (`CNewNPC.ShouldGiveExp`): 5.x added any NPC friendly to Geralt within 30 m of him, guards included, to 1.32's rule (Geralt's own kills, and within 20 m a non-actor's, a party companion's or an Axii'd NPC's, never a guard's), so allies' kills gave Geralt their experience and used up his kill counts (the port has 1.32's and legacy's rule again, XP-04). 5.x's XP-on-kill bonuses on its new swords are gone already (SWD-10).

**How legacy Ghost Mode implements it.** Data: the experience and level of 630 quest rewards in six `rewards.xml` files (base game, Hearts of Stone, Blood and Wine, three free DLCs), 89 quest levels in four `quest_levels` tables, the 49 level-up abilities `Lvl2`–`Lvl50` in `geralt_stats.xml` (NG+ the same, NG+'s `Lvl51`–`Lvl100` removed), the `experience` nodes of 14 enemy abilities (inert), the menu group `GMExpOptions` in `modSignsConfig.xml` and its 7 labels. Scripts: `CR4Game.OnGiveReward` (reworked), `CNewNPC.CalculateExperiencePoints` (rewritten) and the experience lines of `CNewNPC.OnDeath`, `GetExpByEnemyType` (new, `gm_generic.ws`), `W3PlayerWitcher.GetExpModifierByEnemyType` (new; it reads UI-10's kill counter), `CMonsterNestEntity.AddExp`, `AddBonusExp` and its fields, three `PerformAction`s in `choiceActions.ws`, the option getters in `W3GameParams`, `CR4Game.LoadQuestLevels` and `gmUserSettingsQuestLevels`, the option handlers in `CR4IngameMenu`; debug commands (`resetLevels`, `fb1`, `fb2`, `resetme`, ...) and `W3LevelManager.AddPoints`' `ignoreNGP`. No binary file: legacy's three experience-adjacent scene and phase edits are money (handed off).

Unit lists: [attribution.csv](attribution.csv). **989 units carry an XP feature** (905 attributed to XP alone, 84 shared: LOOT's 52 rewards with items, AI's 25 abilities with `experience` nodes, UI-10's kill-counter functions, ALCH-14's nest fields, SKL-01's `AddPoints`, OPT-01's and DIFF-04's menu XML). By type: 34 script units, 690 XML units and 113 NG+ XML units, 152 CSV rows (89 quest levels, 63 labels). Left unattributed: 31 rewards whose only change is gold (ECON) and the debug command `whoareyou`. Port status: **signed off** by the owner (2026-10-31).

## Scope

**XP covers** experience from quests and kills and the other experience sources legacy changed, the reward amounts and levels, the quest levels, the experience options, what a level gives (Vitality, skill points) in both trees, and the debug level commands.

**Unchanged by legacy, and by 5.x** (from the data): the experience curve and the level cap (`geralt_levelups.xml`, `W3LevelManager.GetMaxLevel` 100), 1 skill point per level in the classic tree, `exp_mods.csv`, NG+'s doubled experience below level 50 (`AddPoints`), the full heal at a level-up except on "Death March!", Places of Power and the other skill-point sources (feature-mapping's [progression](../feature-mapping.md#progression)). Crafting and discovering places give no experience of their own in any of the three games; points of interest pay through their rewards (XP-02). Some paths add experience outside the port's rules, in legacy as in 5.x (legacy changed none of them): the collectible places (`W3CollectiblePlaces`, their entity's `xpPoints`), the tutorial's reward function (50 XP), the quest and debug level functions (`BoostPlayerLevel`, `SetGeraltLevel`, `SetGeraltLevelHandsOn`; XP-10's, not ported) and `NewGamePlusInitialize`'s levels to 30; they ignore XP-07's modifiers and the level rule.

**Already ported by other areas** (nothing left for XP):

| Subject | Ported by | What |
|---|---|---|
| The kill counter per enemy type, its saved field, the enemy types and their names, the counting place (a wrapper of `CalculateExperiencePoints`) | UI-10 (signed off) | `ui/bestiary.ws`; XP-04 reads the counts and must merge with the wrapper (PX5) |
| The XP-on-kill bonuses of swords and crossbows removed (`human_exp_bonus_when_fatal`, `nonhuman_exp_bonus_when_fatal`), also 5.x's new swords | SWD-02, SWD-03, SWD-04, SWD-10, XBOW-02 (signed off) | item data |
| The character panel's experience bonus lines removed | UI-05 (signed off) | |
| The level-difference thresholds 6 and 15 that quest and kill experience read | AI-01 (DA4, signed off) | `W3GameParams` defaults |
| The quest rewards' items | LOOT-07 (signed off) | `gen_loot.py`'s reward overrides; their experience and level are legacy's since XP-02 (slice X2), their gold since ECON-10 (slice E4) |
| The character reset and the level-based skill points per tree (`GMGetLevelSkillPoints`; the new tree's rule since slice X5, XP-09) | SKL-01 (D44, signed off) | `skills/characterReset.ws` |
| The DIFF-08 record of the difficulty line | DIFF (signed off) | the code is XP-01's and XP-04's |

**Not XP:**

| Subject | Area | Why |
|---|---|---|
| The trophies' XP bonuses removed (44 trophy abilities, regular and NG+, part of their rework: other stats, weights, prices) | TRPH | The trophies' own rework; the bonus goes with it |
| Reward gold (188 rewards, 31 of them changing only gold), the Vivaldi bank payment (`vimme_vivaldi_default.w2scene` 130 → 390), the Hearts of Stone taxes (`mq6003_taxes.w2phase` 35,000 → 10,000) | ECON | Money |
| The `mh307` contract's two scenes negotiating and paying under `mh308`'s reward name (`mh307_01_halflings`, `mh307_05_halflings_closing`: `SetRewardModifierScene` and `NegotiateMonsterHunt` take `mh307_02_minion_killed_completed`) | ECON (or FIX) | A fix of the contract's money reward, not experience |
| The random bonuses `MA_HumanHunter` and `MA_MonsterHunter` and the Corvo Bianco bookshelf's experience bonus, which legacy kept | ITEM, (none) | Kept as in 1.32; nothing to port |
| Places of Power, Imlerith's acorn, the golden egg | — | Unchanged |

## Changes at a glance

### What Ghost Mode changed

| # | Feature | Vanilla 1.32 (and 5.x) | Legacy GM | Units (main) |
|---|---|---|---|---|
| XP-01 | Quest experience by level | The reward's experience × 0.9 on "Blood and Broken Bones!", × 0.8 on "Death March!"; 5% for a quest 6+ levels below Geralt; ×0.5 for base-game quests once the main story is finished; level scaling for Hearts of Stone only | × (1 + 0.16 × (quest level − Geralt's level)), from 0 to 150%, every quest, every mode; at least 5 XP | 1 script unit |
| XP-02 | Reward experience and levels | 1.32's tables (126,710 XP in all, spikes such as 4,000 for finding Ciri) | 630 rewards retuned (103,795 XP; finding Ciri 1,500), 193 reward levels moved | 630 rewards |
| XP-03 | Quest levels | 1.32's levels | 79 base-game quest levels moved (68 up, 11 down), 2 added, 1 removed; 1 Hearts of Stone, 1 Blood and Wine, 5 Wolf School gear levels | 89 rows |
| XP-04 | Kill experience | From the enemy's damage, armor, health and abilities, capped by its level, /4 below level 30, ×1.2 / 1 / 0.9 / 0.8 by mode, bonuses 6 and 15 levels up, at most 50 | By enemy type (1, 5, 10, 15; contract monsters 15, bosses 20) × (1 + 0.16 × level difference), 0 to 150%, × (1 − kills of that type / 100), rounded down; at least 1; shown in the combat log | 7 script units |
| XP-05 | Enemies' experience nodes | `experience` in 14 enemy abilities (read by no script) | Values changed or dropped (inert) | 25 abilities (shared with AI) |
| XP-06 | Nests and dialogue choices | A nest: its entity's values, every time (the nekker nest 20, its boss 50); a bribe or dialogue payment: a tenth of the money; an Axii choice 20 + 5 per Axii level | A nest 25 XP once, its boss 25 more; a bribe or dialogue payment 5 XP; an Axii choice 5 per Axii level | 6 script units |
| XP-07 | Experience options | — | "Disable quest levels", "Fixed experience for quests and combat", quest and combat experience modifiers (−100% to +100%), a "Default" preset | 13 script units (3 shared with XP-01 and XP-04), the menu group, 63 labels |
| XP-08 | Level-up Vitality | +100 Vitality at level 2 falling to +25 (2,425 by level 50), attack power +4 to +1, spell power +2% to +0.1%; NG+ to level 100 | +50 Vitality per level (2,450 by 50), nothing else; NG+ the same, no level-up ability past 50 | 148 abilities |
| XP-09 | The new tree's skill-point income (new, owner) | 1 point per level in both trees | — (one tree) | — (new code) |
| XP-10 | Debug level commands | Raise the level by adding experience | Reset the character and set the level | 10 script units |

DIFF-08 (experience independent of the mode) is XP-01's and XP-04's difficulty part.

### What 5.x changed

| # | 5.x change (from code and data) |
|---|---|
| XP-01, XP-04 | None in the experience code; the thresholds it reads moved to 10 and 20 (the port has 6 and 15 again, AI-01's DA4); `ShouldGiveExp` gives Geralt the kills of friendly NPCs within 30 m (the port has 1.32's rule again, XP audit F1) |
| XP-02 | 7 new rewards, 4 with experience; gold in 10 rewards (ECON) |
| XP-03 | One new quest level (`mq1060_devils_pit` 15) |
| XP-05 to XP-08, XP-10 | None |
| XP-09 | The new tree ("Ability Points", 1 per level); skill slots by points spent (set back to levels by SKL-01); the tutorial 1076528 rewritten for it |

### Classification and proposed action

| # | Feature | Class | Proposed action |
|---|---|---|---|
| XP-01 | Quest experience | clean | Legacy's rule (PX4) |
| XP-02 | Rewards | clean | Legacy's values; 5.x's new rewards by analogy (DX4) |
| XP-03 | Quest levels | clean | Legacy's (PX3) |
| XP-04 | Kill experience | clean | Legacy's (PX5, PX6); NG+'s defect: DX3 |
| XP-05 | Experience nodes | clean | Legacy's (PX7) |
| XP-06 | Nests, dialogue | clean | Legacy's (PX8) |
| XP-07 | Options | clean | Legacy's (PX9) |
| XP-08 | Level-up Vitality | clean | Legacy's (PX10); in the new tree as DX1 sets it |
| XP-09 | New tree's income | rethink (new) | The owner's rule, made exact by DX1 and DX2 |
| XP-10 | Debug commands | clean | Not ported (PX11) |

---

### XP-01 Quest experience by level

| | |
|---|---|
| Kind | system |
| Pillars | P10 |
| 5.x class | clean |
| Flags | balance |
| Depends on | AI-01 (the thresholds, no longer read once XP-01 is in), XP-02 (the amounts and levels), XP-07 (the options) |
| Skill trees | n/a |
| Port form | `xp/questExperience.ws`: `@replaceMethod(CR4Game)` `OnGiveReward`, 5.x's body (its `AddAnItem` flag kept) with legacy's experience block in `GMQuestExperience`; XP-07's options read through `GMXpNoQuestLevels`, `GMXpFixedExp` and `GMXpQuestExpModifier` (`xp/expOptions.ws`) |
| Port status | signed off |
| Open checks | — |
| Save impact | none (expected) |
| NG+ counterpart | the rule reads the base game's level in NG+ (legacy's), untested |

**What it does** (changelist 1078–1080, 1083–1085, 1142): a quest reward's experience follows the quest's level against Geralt's: each level the quest is above him adds 16%, up to 150% at about 3 levels above; each level below takes 16% away, down to nothing at about 6 levels below; then the reward is at least 5 XP. Example, a 300-XP reward of a level-10 quest: Geralt at 10 gets 300, at 8 gets 396, at 7 gets 444, at 6 or below 450 (the cap), at 12 gets 204, at 14 gets 108, at 16 gets 12, at 17 and above 5. The mode no longer matters. In 1.32 and 5.x the same reward gives 300 on the two lower modes, 270 on "Blood and Broken Bones!", 240 on "Death March!" whatever Geralt's level, until the quest is 6 levels below him (Geralt 16: 15, a twentieth); only Hearts of Stone's quests (`q60*`) scale by level; and once the main story is finished every base-game quest pays half.

**Implementation (legacy):** `CR4Game.OnGiveReward`: modifier 1; Geralt's level less the NG+ level in NG+; the reward's level (0 with "Disable quest levels"); unless "Fixed experience" or a reward of level 0, modifier + (reward level − Geralt's level) × `LEVEL_DIFF_XP_MOD` (0.16), clamped to 0 … `MAX_XP_MOD` (1.5); `RoundMath(experience × expGlobalMod_quests × modifier)`, at least 5; then × (1 + the quest experience modifier) if it is not 0 (XP-07). The post-game halving and the difficulty multipliers are gone.

**5.x:** 1.32's code; 0.16 and 1.5 are 1.32's too. Today the port runs it with AI-01's thresholds (6 and 15), so a quest 6 levels below Geralt pays 5%, as in 1.32.

**Decisions:** legacy's (PX4).

**Slices:**

1. **Quest experience (slice X2).** Verified 2026-10-31, both trees (`gmtest_xp01`, scripted: Geralt raised through `AddPoints` to levels 8 to 17, rewards given through `theGame.GiveReward` on two modes each): legacy's rule worked by hand holds for a base-game reward, a Hearts of Stone reward at the 150% cap, the 5 XP minimum and Killbill's 5.x branch; no post-story halving; the mode does not matter. NG+ not tested (PX12).

### XP-02 Reward experience and levels

| | |
|---|---|
| Kind | tuning |
| Pillars | P10 |
| 5.x class | clean |
| Flags | balance |
| Depends on | LOOT-07 (the same reward overrides), XP-01 |
| Skill trees | n/a |
| Port form | `gen_loot.py`'s reward overrides take legacy's `experience` and `level` for every XP-02 unit (their gold legacy's since ECON's slice E4, ECON-10; `gen_xp.py`'s data test expects it), with the two free-DLC files legacy changed without items (`dlc12`, `dlc15`); 5.x's new rewards by DX4 (`NEW_REWARDS`: the Killbill branch at level 16) (PX2); checked by `gen_xp.py --verify` and its data test |
| Port status | signed off |
| Open checks | — |
| Save impact | none (expected: rewards are read when given) |
| NG+ counterpart | none (one reward table for both) |

**What it does** (changelist 1078, 1086–1089; mod description section 6): "huge spikes ... were replaced with more reasonable rewards"; the main quest stays the main source, then contracts; side and minor quests give little, races, fistfights and gwent less and more money. Of 1.32's 891 rewards in the six files legacy changed the experience of 547 and the level of 193 (630 rewards): base game 73,060 → 60,235 XP, Hearts of Stone 11,400 → 11,100, Blood and Wine 41,100 → 31,050, the free DLCs 1,150 → 1,410. Examples: finding Ciri (`q402_2_found_ciri`) 4,000 at level 22 → 1,500 at level 24; gathering the allies for Kaer Morhen 1,000 → 100; the Battle of Kaer Morhen's end (`q403_09_completed`) 1,000 → 1,500; Dun Tynne 1,500 → 500; Johnny found 50 → 150; Killbill's (`sq106`) rewards from level 11 to 16; the cave troll left alone (`mh201_troll_left_alone`) given level 27.

**Implementation (legacy):** the `experience` and `level` attributes of the rewards in `gameplay/rewards/rewards.xml` (449), `dlc/ep1` (55), `dlc/bob` (116), `dlc3` (4), `dlc12` (2), `dlc15` (4).

**5.x:** 1.32's values for every reward legacy changed; 7 new rewards (DX4), gold in 10 (ECON).

**Decisions:** legacy's values (PX2). 5.x's new rewards by analogy (DX4 (a), owner, 2026-10-31): Killbill's new branch `sq106_3_hammond_killed_crach` at legacy's level for the quest, 16, with 5.x's 50 XP; `q504_horse_returned` and the two `mq1060` priest rewards 5.x's. Content legacy never had, so not a deviation.

**Slices:**

1. **Reward data (slice X2).** Verified 2026-10-31, both trees (`GMTest_xpquestdata`, scripted definitions read, in the regression; `gen_xp.py --verify`): the 630 XP-02 rewards have legacy's experience and level in all six files, 5.x's new rewards as DX4 sets them. Their effect in play is XP-01's check.

### XP-03 Quest levels

| | |
|---|---|
| Kind | content |
| Pillars | P10 |
| 5.x class | clean |
| Flags | — |
| Depends on | XP-07 ("Disable quest levels") |
| Skill trees | n/a |
| Port form | whole-file overrides of the four tables (`gameplay/globals/quest_levels.csv`, `dlc/ep1/...`, `dlc/bob/...`, `dlc/dlc10/.../th1009_quest_levels_copy.csv`) in the mod's bundle: 5.x's table with legacy's changes against 1.32 (rows legacy added appended), 5.x's own row kept (PX3); `gen_xp.py` (`QUEST_LEVELS`) |
| Port status | signed off |
| Open checks | — |
| Save impact | none (expected: loaded at game start) |
| NG+ counterpart | none |

**What it does** (changelist 1086–1089): the level shown for each quest in the journal and the quest tracker, its colour against Geralt's level, the "high-level quest" tutorial, and whether a contract can be tracked (Geralt at most 5 levels below its level: `CanTrackQuest` allows it when his level is at least the quest's − 5). Quest experience reads the reward's own level (XP-02), not this table. Legacy moved 79 base-game quests (68 up, 11 down: the Fistfight Championship 11 → 30, "Master of the Arena" 14 → 22, "Immoral Proposition" 15 → 23, the Courier 2 → 12; a sunken treasure and a pond 18 → 5), added two (`mq2052 Reversed Monster Hunt` 29, `mh201 : Cave Troll` 27) and removed one (`mq2040_trial_of_power`, then shown without a level); Hearts of Stone's Ofieri armor 33 → 32, Blood and Wine's `ww_belgard_secret` 42 → 38, the Wolf School gear hunt 14/21/29 → 21/24/28 (the table dlc10's quest mounter loads is `th1009_quest_levels_copy.csv`, read from 5.x's `dlc10.reddlc`).

**5.x:** 1.32's rows; one new row (`mq1060_devils_pit` 15).

**Decisions:** legacy's (PX3); 5.x's new row `mq1060_devils_pit` (15) kept (DX4 (a)). Legacy's two added base-game rows (`mh201 : Cave Troll` 27, `mq2052 Reversed Monster Hunt` 29) repeat rows the free DLCs `dlc3` and `dlc12` already load at the same levels (1.32 and 5.x alike), so they change nothing in play; kept as legacy has them.

**Slices:**

1. **Quest levels (slice X2).** Verified 2026-10-31, both trees (`GMTest_xpquestdata`, scripted: every loaded table read as the journal reads it, in the regression): legacy's 89 rows, `mq2040_trial_of_power` without a level, 5.x's `mq1060_devils_pit` 15. The game loads seven tables, the DLCs' first and the base game's last; the overrides replace both. The journal and quest tracker on screen are not checked (the test save's quests show no level).

### XP-04 Kill experience

| | |
|---|---|
| Kind | system |
| Pillars | P10 |
| 5.x class | clean |
| Flags | balance |
| Depends on | UI-10 (the kill counter and enemy types), AI-01 and DIFF-04 (the enemy's level, after scaling), ENCH (the replaced `OnDeath`), XP-07 |
| Skill trees | n/a |
| Port form | `xp/killExperience.ws`: `@replaceMethod(CNewNPC)` `CalculateExperiencePoints` with legacy's body (every line marked), the kill counted after the experience, once (UI-10's wrapper removed from `ui/bestiary.ws`, PX5; a call with `skipLog` counts nothing); `GMGetExpByEnemyType` (legacy's table), `@addMethod(W3PlayerWitcher)` `GMGetExpModifierByEnemyType`; legacy's experience lines in ENCH's `OnDeath` (`enchantments/npcDeath.ws`: the 1 XP minimum, XP-07's combat modifier, the combat log line); `xp/killEarner.ws`: `@replaceMethod(CNewNPC)` `ShouldGiveExp`, 5.x's body without its friendly-NPC branch (1.32's and legacy's rule, XP audit F1); XP-07's hooks `GMXpFixedExp` and `GMXpCombatExpModifier` (`xp/expOptions.ws`); 5.x's `ConDefaultSilver` counted as human in UI-10's `GMGetEnemyTypeByAbility` (DX4) |
| Port status | signed off |
| Open checks | an ally's kill beside Geralt in a real fight. The combat log line cannot be seen on screen: 5.x's HUD shows no combat log |
| Save impact | none (expected); the counts are UI-10's saved field, counting from the mod's installation |
| NG+ counterpart | legacy's code (DX3), verified by script (the NG+ facts set and taken back within one call) |

**What it does** (changelist 1081–1083, 1142; mod description section 6): a kill gives a base amount by enemy type: wolves and dogs 1; humans, drowners, nekkers, ghouls, harpies, wraiths, sirens, wyverns, foglets, water hags, the Wild Hunt's warriors and hounds, bears, endrega workers, boars, giant spiders, panthers, barghests, kikimore workers and archespores 5; most other monsters (griffins, basilisks, cockatrices, forktails, werewolves, katakans, ekimmas, trolls, cyclopes, noonwraiths and nightwraiths, grave hags, Blood and Wine's bruxae, alps, slyzards, kikimore warriors, centipedes and garkains) 10; arachases, golems, elementals, fiends, chorts, leshens, shaelmaars, spriggans and wights 15; contract monsters 15; bosses 20; unidentified creatures and animals a base of 0, which the 1 XP minimum makes 1. It is multiplied by 1 + 0.16 × (enemy level − Geralt's level), from 0 to 150%, and, but for bosses, by 1 − (kills of that type so far ÷ 100): the hundredth drowner and every one after it gives 0 before the minimum; the product is rounded down (legacy's `RoundF` truncates, seen in game). Then × Geralt's gear's kill-experience bonus (none left in legacy's data but two random bonuses), × the combat experience modifier (XP-07), at least 1, and the combat log shows "Experience Points: N". Examples at Geralt 10 (verified by script): a drowner at his level 5, after 50 drowners 2 (2.5 rounded down), after 100 1; a drowner 3 levels below him 2, 5 above 7 (the 150% cap), 7 below 1; a wolf 1; a bandit 5; a griffin 3 levels above him 14 (14.8), a griffin at his level after 50 griffins 5; a contract monster 15, cut by earlier kills of its creature type (a contract wyvern after 40 wyverns 9); a boss 20 whatever the kills, 29 at 3 levels above. Guards give none and count as human kills, so killing guards lowers later human experience. **Who earns it:** Geralt's own kills; within 20 m of him also a kill by something that is not an actor (a trap, the environment), by a party companion or by an NPC under Axii; never a guard's kill, and no other ally's (1.32's and legacy's `ShouldGiveExp`). Only a kill that earns experience is counted for the diminishing returns. With DIFF's default soft upscaling, an enemy far below Geralt is lifted to 6 levels below him and then gives the minimum (a level-1 drowner at Geralt 10: level 4, 1 XP); legacy's behaviour. 5.x's new enemies (DX4): the plague victims are humans (5); the red-plague creature is a contract monster with the Hym's boss ability, so 15, never cut, counted as a boss; Reinald's entity grants no kill experience (5.x's flag, kept), so he gives none and is not counted. In NG+ (DX3) an enemy at Geralt's level counts 30 or more levels below him: the 1 XP minimum, which 5.x's NG+ doubling in `AddPoints` makes 2 (the log shows 1). In 1.32 and 5.x a kill's experience comes from the enemy's damage, armor, health and special abilities, capped by its level (1 + 2 per level for humans, 5 + 4 for monsters), quartered below level 30 and halved above, with bonuses at 6 and 15 levels above Geralt, 2 when 6 or more below, halved again past level 35, at most 50, then ×1.2 on "Just the Story!", ×0.9 and ×0.8 on the two higher modes; no combat log line.

**Implementation (legacy):** `CNewNPC.CalculateExperiencePoints` (`npc.ws`, rewritten): 0 for `grantNoExperienceAfterKill` or `Zero_XP`; a guard counts as a human kill and gives 0; type by `GetEnemyTypeByAbility`, base by `GetExpByEnemyType` (`gm_generic.ws`), 15 for `W3MonsterHuntNPC`; in NG+ the NG+ level is taken off the enemy's level only; unless "Fixed experience", modifier `ClampF(1 + (currentLevel − Geralt's level) × 0.16, 0, 1.5) × GetExpModifierByEnemyType` (`playerWitcher.ws`: bosses 1, generic and animals 0, else `1 − Min(100, kills) / 100`); `Max(1, RoundF(exp × modifier))`, then `IncKills`. `CNewNPC.OnDeath`: `RoundMath(exp × (1 + gear bonus) × expGlobalMod_kills)`, at least 1, × (1 + combat modifier) if not 0, `AddPoints`, the combat log line.

**5.x:** 1.32's code (`CalculateExperiencePoints` unchanged; `OnDeath`'s experience lines 1.32's in 5.x's body, which the port replaces for ENCH). UI-10 wraps `CalculateExperiencePoints` and counts the kill before the body runs; legacy counts after computing (PX5). `ShouldGiveExp` is 1.32's with a new branch: a kill by any NPC friendly to Geralt within 30 m of him gives Geralt the experience (and so the kill count), guards included.

**Decisions:** legacy's (PX5, PX6). NG+: legacy's code, 1 XP a kill (DX3 (a), owner, 2026-10-31; the fix is on the Later list). 5.x's new enemies (Reinald, the `mq1060` plague victims and red-plague creature) get the XP type of their creature, the one `GMGetEnemyTypeByAbility` finds for their abilities, checked in slice X3 (DX4 (a)). Who earns a kill's experience: legacy's (1.32's) rule (XP audit F1, option (a), owner, 2026-10-31); 5.x's friendly-NPC branch removed, so allies' and guards' kills near Geralt give him nothing and count no kill. Not a deviation (legacy's rule; it differs from 5.x's). Porter's calls of slice X3 (confirmed by the owner, 2026-10-31; content legacy never had, or no play effect, so not deviations):
- The plague victims' template `ConDefaultSilver` (5.x's silver-vulnerable humans; no other entity keeps it after AI-02's lists) counts as human in `GMGetEnemyTypeByAbility`: 5 XP, cut by human kills, counted as humanoids in the bestiary. Without it they are unidentified: the 1 XP minimum, not shown by type.
- The red-plague creature stays what the function finds: its Hym ability `mon_him` is one of legacy's boss abilities and its entity a contract monster (`W3MonsterHuntNPC`), so 15 XP × the level term, never cut, counted as a boss. The alternative, the leshen's type (AI's DA5 analogy): the same 15 at first, then cut by earlier leshen kills, counted with leshens.
- Reinald keeps his entity's `grantNoExperienceAfterKill` (5.x's own flag; his entity is a contract monster too): no kill experience and no count, the quest's rewards pay. The alternative, the flag ignored for him: he would need a type first (his template `mq1060_Reinald` is a copy of `ConDefault` under another name), then 5 XP as a human.
- In NG+ the NG+ level is taken off a local copy of the enemy's level; legacy subtracts it from the dying NPC's stored level itself. The kill's experience is the same; only the dead NPC's stored level differs.

**Slices:**

1. **Kill experience (slice X3).** Verified 2026-10-31, both trees (`gmtest_xp04`, scripted: samples spawned frozen, their level and kill counts set, killed by a scripted hit through the damage manager so the game's `OnDeath` runs; the combat log read by a test wrapper): every example above (drowners at several levels and kill counts, a wolf, a bandit, griffins, a contract monster, a boss, a guard, 5.x's new enemies, the soft upscaling, NG+) gives legacy's value, each kill counted once, the log line written. UI-10's kill counter passes its own checks after the fold. A wolf killed by Geralt's real light attacks gave +1 XP (real input, 2026-11-01).
2. **Who earns a kill's experience.** Verified 2026-10-31, both trees (`GMTest_xp04_who_spawn` in `gmtest_regress()`, `GMTest_xp04_who_after` in `gmtest_panel()`; scripted kills with the attacker named): Geralt's kill counts; a friendly renegade's and a friendly guard's near him, and the renegade's 45 m away, give nothing and count no kill.

### XP-05 Enemies' experience nodes

| | |
|---|---|
| Kind | tuning |
| Pillars | P10 |
| 5.x class | clean |
| Flags | — |
| Depends on | AI-01, AI-02, AI-03, AI-15, AI-17 (the abilities, given whole by `gen_ai.py`) |
| Skill trees | n/a |
| Port form | `gen_ai.py`: XP added to `PORTED`, so `LATER`'s `experience` tag takes legacy's node (PX7); `gen_ai.py`'s data test no longer picks the node, `gen_xp.py`'s reads every one |
| Port status | signed off |
| Open checks | — |
| Save impact | none (nothing reads the nodes; an NPC's attribute reads the definitions live) |
| NG+ counterpart | applied, as legacy's NG+ entries (`gen_ai.py --verify`), untested |

**What it does:** nothing in play. Legacy changed or dropped the `experience` node of `MonsterLevelBonusArmored` (2 → 4), `ConAthletic` (10 → 0), the new `AnimalLevelBonus`, `NPCLevelBonus`, `MiniBoss`, `Boss` and `ConHumanoidMonster` (1, 2, 30, 50, 0), and dropped it from `MonsterMHBoss` (50), `MonsterLevelBonusHigh` (20), `MonsterLevelBonusDeadly` (100), `sq201_werewolf` (44) and the NG+ Wild Hunt leaders (100); 5.x itself has no node in `MonsterLevelBonusHigh` and `MonsterLevelBonusDeadly` (1.32's 20 and 100). No script of 1.32, legacy or 5.x reads an NPC's `experience` attribute (the only reader of the name is the journal's reward line, `hudModuleJournalUpdate.ws`); 1.32's kill formula reads damage, armor and health instead. These are the `LATER` nodes AI left to XP.

**Decisions:** legacy's nodes (PX7), so AI's abilities equal legacy's but for WGT's weights.

**Slices:**

1. **Experience nodes (slice X1).** Verified 2026-10-31, both trees (`GMTest_xpdata` and `GMTest_xp05`, scripted, in the regression): every node is legacy's; a test ability adding +1000 experience to a bandit and a drowner changes their `experience` attribute but not their kill experience. A static search finds no reader of the attribute.

### XP-06 Nests and dialogue choices

| | |
|---|---|
| Kind | tuning |
| Pillars | P10 |
| 5.x class | clean |
| Flags | — |
| Depends on | ALCH-14 (the nest's bomb choice, same class) |
| Skill trees | n/a |
| Port form | `xp/otherExperience.ws`: `@replaceMethod(CMonsterNestEntity)` `AddExp` (25, once per nest) and `AddBonusExp` (25); `@replaceMethod` of `CPayStorySceneChoiceAction`'s and `CPayFactBasedStorySceneChoiceAction`'s `PerformAction` (5 XP) and `CAxiiStorySceneChoiceAction`'s (5 per Axii level); legacy's values as constants, without its three nest fields (PX8) |
| Port status | signed off |
| Open checks | a nest blown up with a real bomb by Geralt; a payment and an Axii choice chosen in a real dialogue (each needs a save at that point) |
| Save impact | none (expected; a nest already destroyed keeps its saved flag) |
| NG+ counterpart | none |

**What it does** (not in the changelist): destroying a monster nest gives 25 XP, once per nest (a rebuilt nest destroyed again gives nothing), and killing its boss 25 more. In 1.32 and 5.x a nest gives the values its entity sets, every time it is destroyed (the base game's nekker nest sets 20 and its boss 50, not once only; without entity values the script's defaults are 100 and, by a typo, 0 for the boss). Paying a bribe or a dialogue payment gives 5 XP (1.32 and 5.x: a tenth of the money, so a 300-crown bribe 30 XP); an Axii choice in dialogue gives 5 per Axii level (1 + Delusion's level: 5 to 20; 1.32 and 5.x: 20 more, 25 to 40): legacy's code drops the 20, not the level term.

**Implementation (legacy):** `CMonsterNestEntity.AddExp`, `AddBonusExp` and three new fields (`expOnNestDestroyedMod`, `bonusExpOnBossKilledMod`, `addExpOnlyOnceMod`; the fields' defaults fixed too); `CPayFactBasedStorySceneChoiceAction`, `CPayStorySceneChoiceAction`, `CAxiiStorySceneChoiceAction.PerformAction`.

**5.x:** 1.32's.

**Decisions:** legacy's (PX8). The Axii choice follows legacy's code (5 × Axii level), not a flat 5 XP as the map summarised it.

**Slices:**

1. **Nests and choices (slice X3).** Verified 2026-10-31, both trees (`gmtest_xp06_a/b/c`, scripted: the choice actions' own `PerformAction`; the base game's nekker nest blown up through its own `Explosion` state, then `SetBossKilled`, then restored and blown up again): a 300-crown payment 5 XP, a bribe 5, an Axii choice at level 1 5; the nest 25, its boss 25, the second destruction 0.

### XP-07 Experience options

| | |
|---|---|
| Kind | infra, ui |
| Pillars | P10 |
| 5.x class | clean |
| Flags | — |
| Depends on | OPT-01 (the menu framework), XP-01, XP-03, XP-04 |
| Skill trees | n/a |
| Port form | the group `GMExpOptions` in `menu/modGhostMode.xml` (after the scaling group, as legacy) with legacy's ids, sliders (`SLIDER;-1;1;200`) and "Default" preset; `options/gmOptions.ws`: its four defaults (false, false, 0, 0) and the flag `gmQuestLevelsOptionChanged`, set in OPT's wrappers of `OnOptionValueChanged` (`GMNoQuestLevels`) and `OnPresetApplied` (the group), acted on in `SaveChangedSettings` (`GMOnQuestLevelsOptionChanged`); `xp/expOptions.ws`: the four hooks read the options (`GMGetOptionBool`, `GMGetOptionFloat`), `@replaceMethod(CR4Game)` `LoadQuestLevels` with legacy's check, `@addMethod(CR4Game)` `GMReloadQuestLevels` (legacy's `gmUserSettingsQuestLevels`); the 7 labels in 9 languages with legacy's ids, keys and texts (PX9) |
| Port status | signed off |
| Open checks | the journal's and the quest tracker's levels on screen with quest levels disabled (the test save's quests show no level either way); "Disable quest levels" changed from the main menu before a load |
| Save impact | none (options in the user settings) |
| NG+ counterpart | — |

**What it does** (changelist 1217–1225; mod description section 9, point 3; legacy's code): Options → Mods → Ghost Mode → Experience, with the preset list "Experience Presets" (one preset, "Default") and four options.
- "Disable quest levels": every quest reward pays its full experience whatever Geralt's level (its level is read as 0, so XP-01's scaling is skipped; the 5 XP minimum and the quest modifier still apply), and no quest has a level: the journal, the quest tracker and the level colours show none, and every contract can be tracked. Enemies' levels are not affected. Turned on in the menu, it takes effect when the menu closes, and at every load while it is on no table is loaded. Turned off in the menu, the base game's, Hearts of Stone's and Blood and Wine's quest levels come back when the menu closes, the free DLCs' (the Wolf School gear hunt, `dlc3`'s, `dlc12`'s and `dlc15`'s quests) only at the next load (legacy's gap, PX9).
- "Fixed experience for quests and combat": a quest pays its reward's own experience (at least 5) and a kill its type's base (wolves 1, drowners 5, griffins 10, contract monsters 15, bosses 20), with no level scaling and no diminishing returns; the kill is still counted.
- "Quest experience modifier" and "Combat experience modifier", −100% to +100% in 1% steps: the experience × (1 + modifier), rounded half up, after the 5 XP and 1 XP minimums, so −100% gives nothing; a kill at −100% still shows "Experience Points: 0" in the combat log (legacy's).
- These three are read at each reward and kill, so they apply as soon as the menu closes (the game is paused while it is open).

Examples, Geralt at level 12: Triss's reward `q301_2_helped_triss` (level 10, 250 XP) gives 170; at −50% 85, +50% 255, +100% 340, −100% 0; with fixed experience or quest levels disabled 250. Olgierd's first reward (level 32, 200 XP) gives 300 (the 150% cap), fixed 200. A level-1 reward of 200 XP gives the 5 XP minimum, at +100% 10, fixed or with quest levels disabled 200. A drowner at his level after 50 drowners gives 2, at −50% 1, +50% 3, +100% 4, fixed 5; a griffin 3 levels above him 14, at −50% 7, +50% 21, +100% 28, fixed 10. Everything at once (quest levels disabled, fixed, quest +20%, combat −40%): Triss's reward 300, the drowner 3, the griffin 6. "Default" sets everything off and 0, which is also what an untouched menu reads.

**Implementation (legacy):** `modSignsConfig.xml` group `GMExpOptions` (`GMNoQuestLevels`, `GMUseXMLExp`, `GMQuestExpModifier`, `GMMonsterExpModifier`; sliders `-1;1;200`); `W3GameParams.GetNoQuestLevels`, `GetFixedExp`, `GetQuestExpModifier`, `GetMonsterExpModifier`; `CR4Game.LoadQuestLevels` (clears every table and loads none while "Disable quest levels" is on), `gmUserSettingsQuestLevels` (reloads the base game's, Hearts of Stone's and Blood and Wine's tables: the free DLCs' come back only at the next load, a gap kept, PX9); `CR4IngameMenu`: `gmHasChangedQuestLevelsOption`, set by `OnOptionValueChanged` for `GMNoQuestLevels` and by `OnPresetApplied` for the group, calls `gmUserSettingsQuestLevels` when the menu saves the settings. The getters read the options live; legacy writes no defaults for the group (an unset option reads off and 0).

**5.x:** no such options; OPT-01's framework has the other groups. 5.x's `LoadQuestLevels` is 1.32's; the game loads seven quest-level tables at a load, the DLCs' first.

**Decisions:** legacy's (PX9). Porter's calls of slice X4 (no play effect, so not deviations; confirmed by the owner, 2026-10-31):
- The four options get their defaults (false, false, 0, 0) written to the settings file at a load when unset, as every Ghost Mode option in OPT's framework; legacy writes none and reads an unset option as off and 0. The game plays the same; the settings file gains a `[GMExpOptions]` section.
- The labels are rows with the key's name (`key(str)`) in every language; legacy's `br`, `de`, `es`, `fr`, `it` and `pl` tables give the key as its hash, which is the same key (checked with `w3strings.key_hash`).

**Slices:**

1. **Options (slice X4).** Verified 2026-10-31, both trees (`gmtest_xp07_set`, `gmtest_xp07_check`, `gmtest_xp07_preset`, `gmtest_xp07_unset`, and `GMTest_xp07` in the regression; scripted through the options menu's own events, then rewards given and samples killed): each option and the examples above give legacy's values, quest-level tables are cleared and reloaded as legacy (the free DLCs' only at the next load), the "Default" preset resets everything, unset options read off and 0, and the values survive a relaunch. The group on screen and a change by hand with real input: verified 2026-11-01.

### XP-08 Level-up Vitality

| | |
|---|---|
| Kind | tuning |
| Pillars | P10, P1 |
| 5.x class | clean |
| Flags | balance |
| Depends on | DMG (attack power), XP-09 (the new tree) |
| Skill trees | classic: legacy's (50 per level); new: as DX1 sets it (XP-09) |
| Port form | the 49 `Lvl<n>` abilities given whole (`replace`) in `abilities/gm_xp.xml` from `tools/gen_xp.py`; NG+ copy by `gen_ngplus.py` (legacy kept NG+ equal; 5.x's NG+ `Lvl51`–`Lvl100` are already empty, PX10); `xp/levelStats.ws`: `@wrapMethod(W3PlayerWitcher)` `OnSpawned` recomputes the maximum Vitality once at a load (the save impact). The new tree has its own level abilities since slice X5 (XP-09: `GMLvlNew<n>`, `gen_xp.py`'s `NEW_TREE_VITALITY`) |
| Port status | signed off |
| Open checks | — |
| Save impact | none for the player: a loaded character's stored maximum Vitality (from 5.x's values) is recomputed at the load, and his level abilities, held by name, give legacy's values (verified on the test-only slot) |
| NG+ counterpart | applied: legacy's values, past 50 nothing (as 5.x); untested |

**What it does** (changelist 472–473): each level from 2 to 50 adds 50 to Geralt's base Vitality and nothing else (2,450 by level 50). In 1.32 and 5.x a level adds 100 Vitality at first, falling to 80 by level 10, 60 by 11, 50 by 21, 30 by 30 and 25 from 40 (2,425 by 50), plus attack power (`add`, 4 falling to 1; 77 in all) and spell power (2% falling to 0.1%; 28% in all). NG+'s table names levels up to 100 in 1.32 and 5.x, but `Lvl51` to `Lvl100` are empty there (one misnamed `Lvl60`); legacy deleted them, with the same effect.

**Implementation (legacy):** `Lvl2`–`Lvl50` in `abilities/geralt_stats.xml` and `abilities_plus/` (NG+ `Lvl51`–`Lvl100` deleted, one of them misnamed `Lvl60` in 1.32); added at each level-up by `W3LevelManager.AddPoints` through `GetLevelupAbility`.

**5.x:** 1.32's (read in game on a build without the slice: from level 1 to 50 +2,425 maximum Vitality, attack power's additive part +77, spell power ×1.281).

**Decisions:** legacy's (PX10): +50 Vitality per level in the classic tree, no attack or spell power; NG+ as legacy (5.x's NG+ level abilities past 50 are already empty, so no entry). Porter's call (confirmed by the owner, 2026-10-31): a loaded save's stored maximum Vitality is recomputed once at the load, so a character from before the install gets legacy's level Vitality at once rather than at his next Vitality change (legacy asked for `cleardevelop` on existing characters); a new game is unaffected. In the new tree the Vitality follows XP-09's rule (DX1 (a), its deviation recorded there), since slice X5.

**Slices:**

1. **Level-up Vitality (slice X1).** Verified 2026-10-31, both trees (`GMTest_xpdata` in the regression; `gmtest_xp08_levels(60)`, `gmtest_xp08_parts()`; scripted level-ups through `AddPoints`): `Lvl2` to `Lvl50` give +50 Vitality each and nothing else, none past 50; a loaded level-20 Geralt saved with 5.x's level abilities has his maximum Vitality recomputed at the load. With a Vitality effect active at the save (Blood and Wine's "Well rested"), the effect is back before the recompute, so Geralt loads with the Vitality he saved with (`gmtest_xp08_vit_a`, `_b`, `_c`).

Geralt on the test save (level 1: 3,500 maximum Vitality), levelled by script:

| Level | 5.x (before) | Ghost Mode (after; legacy's) |
|---|---|---|
| 10 | Vitality 4,300; attack power +31; spell power ×1.12 | Vitality 3,950; no attack or spell power from levels |
| 20 | Vitality 4,900; attack power +47; spell power ×1.215 | Vitality 4,450 |
| 50 | Vitality 5,925; attack power +77; spell power ×1.281 | Vitality 5,950 |
| 60 | as at 50 | as at 50 |

Attack power's "+N" is the additive part `GetPowerStatValue` returns, which the damage formula adds to each hit after the multiplier.

### XP-09 The new tree's skill-point income (new, owner)

| | |
|---|---|
| Kind | system |
| Pillars | P10 |
| 5.x class | rethink |
| Flags | balance |
| Depends on | SKL-01 (the reset, `GMGetLevelSkillPoints`), SKL-02 (the tree option), XP-08 |
| Skill trees | new tree only; the classic tree keeps 1 point and legacy's 50 Vitality per level |
| Port form | `xp/levelUp.ws`: `@wrapMethod(W3LevelManager)` `GainLevel` takes back the point the level definitions just gave on a level divisible by 3 in the new tree; `@wrapMethod(W3PlayerWitcher)` `GetLevelupAbility` returns the new tree's level ability `GMLvlNew<n>` (levels 2 to 100; `abilities/gm_xp.xml` from `gen_xp.py`'s `NEW_TREE_VITALITY`, +150 Vitality on 3 to 48, the others hold only the `base` tag; NG+ copy by `gen_ngplus.py`); `xp/levelNames.ws` (generated) names both trees' level abilities by level; the rule follows the skill-tree profile in force (`GMIsNewTreeIncome`: SKL-02's facts, the option for a character with no profile); `skills/characterReset.ws`: `GMGetLevelSkillPoints(false)` counts the new rule, and the reset counts the points the levels gave by the level ability held for each (`GMGetGainedLevelSkillPoints`), swaps the level abilities to the tree in force keeping the Vitality percentage (`GMSwapLevelAbilities`) and sets the points; `loot/standalone.ws`: the standalone starts' free points by the tree's rule (`GMGetLevelSkillPoints` + 5.x's 11) |
| Port status | signed off |
| Open checks | the HUD's level-up message and point indicator on a level reached by real experience (none showed on screen for levels given by `levelup()` and `addexp`); a real Place of Power; the standalone starts' points (compiles; not run) |
| Save impact | none on a new game. A new-tree character from before the slice keeps its points and level Vitality from the levels it already has (1 point and +50 each) until the character reset (`gmreset`), which gives it the new rule's; levels gained after the install follow the new rule at once (verified on the test-only slot) |
| NG+ counterpart | the same rule (DX2): the wrappers do not depend on NG+; untested |

**What it does** (the owner, 2026-10-11, [feature-mapping](../feature-mapping.md#progression), SKL's D59 revisit): the new tree's skills cost fewer points (3 levels, tiers ×3/5), so it earns fewer: on every third level Geralt gets no skill point, and the Vitality of those three levels comes all at once on that level. With DX1 (a): no point on levels 3, 6, …, 48, 150 Vitality on each of them, none on the others; 33 points from levels by level 50 instead of 49 (the classic tree), 2,400 Vitality instead of 2,450. A path's capstone then arrives at about 0.9 of legacy's level (SKL's estimate). Other sources (Places of Power, the acorn, the egg) stay as they are.

**Implementation (legacy):** none (one tree). 5.x: 1 point per level in both trees.

**Interactions:** the new tree's tier gates (5/12/18, 5/12/17, 4/11/17) arrive later in levels; MUT-01's research costs (29 skill points in both trees) take a larger share of the new tree's points; skill slots and skill mutagen slots unlock by level in both trees (SKL-01; the mutagen slots since slice X5, which found them still on 5.x's skill-point rule), so slots are not affected (their locked tooltips say "Slot unlocked at level: N", SKL-01); the game's texts say one point per level (DX5).

**Decisions:** the owner's rule made exact by DX1 (a) and DX2 (a) (owner, 2026-10-31); the game's level texts stay as they are, a new-tree line on the Later list (DX5 (a)).
- **Deviation (new tree):** in the new tree levels 3, 6, 9, …, 48 give no skill point and +150 Vitality, and the other levels a point and no Vitality: 33 points and 2,400 Vitality from levels by level 50 (legacy, one tree: a point and +50 Vitality every level, 49 and 2,450). The new tree's skills cost fewer points (DX1 (a), owner, 2026-10-31)
- **Deviation (new tree):** past level 50 the new tree keeps the same pace, no skill point on every third level (51, 54, …), and no level past 50 gives Vitality, the third levels included; NG+ the same. Legacy's levels past 50 give a point every level and no Vitality (DX2 (a), owner, 2026-10-31)

Porter's calls of slice X5 (none is a deviation: legacy had one tree; each porter's call confirmed by the owner, 2026-10-31):
- **The rule follows the tree Geralt has, not the option alone.** A level-up uses the new tree's rule while the new tree's profile is in force (SKL-02's facts, set by the character reset), so changing the option changes nothing until `gmreset()`, which is when the tree itself changes. A character with no profile yet (a new game before its first load) follows the option. The alternative, the option read at each level-up: a level gained between the option change and the reset would follow the other tree's rule; the reset would still put it right.
- **A loaded save is not recomputed at the load.** A new-tree character from before the slice (level 20: 19 points from levels, `Lvl2` to `Lvl20`, 950 Vitality) keeps them as they are; its next level-ups follow the new rule, and `gmreset()` gives it the new rule for every level (13 points, 900 Vitality, the percentage kept). The alternative, recomputing at the load as XP-08's Vitality is: the level abilities could be swapped, but the 6 points too many cannot be taken back once spent without a reset; a forced reset at load would empty the character's skills unasked.
- **The level abilities record the rule.** Geralt holds one level ability per level, `Lvl<n>` (classic, to 50) or `GMLvlNew<n>` (new tree, to 100: the ones without Vitality and those past 50 are empty markers), and the reset reads them to tell the points from levels from the other sources (Places of Power, the acorn, the egg), so a character whose levels were gained under both rules (a save from before the slice, or a reset in between) comes out right. The alternative, a saved field: a change to the save format for the same result. No play effect.
- **The point is given and taken back.** `GainLevel` gives the level definitions' point as 5.x does, and the wrapper takes it back on a no-point level, so the HUD's point indicator may still light on those levels (not seen: the HUD showed nothing for scripted level-ups); the level-up texts stay (DX5 (a)). The alternative, a replaced `GainLevel` that gives no point there: a replaced 5.x method for a HUD detail.

**Slices:**

1. **The new tree's income (slice X5).** Verified 2026-10-31, both trees (`gmtest_xp09_levels(60)`, `gmtest_xp09_tree`, `gmtest_xp09_pop_a/b/c`, `gmtest_xp09_load`, and `GMTest_xpdata` in the regression; scripted level-ups through `AddPoints` and tree switches through `gmreset()`): each level's points and Vitality, the totals, the skill and mutagen slots follow DX1 and DX2; a tree switch at levels 20, 50 and 60 sets the points from levels and other sources and keeps the Vitality percentage; a Place of Power gives its point on a no-point level; a loaded save from before the slice keeps its levels until the reset. The character panel on a no-point level on screen (new tree, level 3): verified 2026-11-01.

Geralt on the test save (level 1: 3,500 maximum Vitality, no points), levelled by script:

| Level | Classic tree: points from levels, level Vitality (maximum) | New tree: points from levels, level Vitality (maximum) |
|---|---|---|
| 10 | 9, 450 (3,950) | 6, 450 (3,950) |
| 20 | 19, 950 (4,450) | 13, 900 (4,400) |
| 30 | 29, 1,450 (4,950) | 19, 1,500 (5,000) |
| 50 | 49, 2,450 (5,950) | 33, 2,400 (5,900) |
| 60 | 59, 2,450 (5,950) | 39, 2,400 (5,900) |

### XP-10 Debug level commands

| | |
|---|---|
| Kind | infra |
| Pillars | — |
| 5.x class | clean |
| Flags | — |
| Depends on | SKL-01 (legacy builds them on its rebuilt `Debug_ClearCharacterDevelopment`) |
| Skill trees | n/a |
| Port form | none (PX11) |
| Port status | not started (not to be ported, PX11) |
| Save impact | — |
| NG+ counterpart | — |

**What it does:** debug only. Legacy's `resetLevels`, `fb1`, `fb2`, `fb3`, `resetme`, `addAllSkills` and the quest function `SetGeraltLevel` reset the character (legacy's respec) and set the level directly (`AddPoints` with the new `ignoreNGP`, no NG+ doubling) instead of raising it by adding experience; `cleanupInv` empties the inventory. The level-scaled gear they give is ITEM-02's (`addAutogenEquipment`, dropped by ITEM-02: tests add items directly). 5.x's versions are 1.32's; SKL-01's `gmreset()` is the port's reset; `setlevel()` and the automation's own commands set the level for tests.

**Decisions:** not ported (PX11).

---

### Dependencies on other areas

- **Done areas XP builds on:** UI-10 (kill counter, enemy types), AI-01 and DIFF-04 (enemy levels), ENCH (the replaced `OnDeath`), ALCH-14 (the replaced nest method), LOOT-07 (the reward overrides and `gen_loot.py`), SKL-01 and SKL-02 (the reset, per-tree points, the tree option), OPT-01 (the menu).
- **Areas XP shares with or waits for:** ECON (the same rewards' gold), TRPH (the trophies' experience bonuses), GEN (the changelist puts the level-up Vitality under "General player abilities"; XP-08 takes it, with XP-09).

### Save impact

None for the player: rewards and quest levels are read live (expected); the level-up abilities' attack and spell power are read live, and the maximum Vitality a save stores is recomputed at the load (XP-08, verified in slice X1); the options live in the user settings, the kill counts are UI-10's. XP-09 on an existing new-tree character applies to the levels it gains from the install; the levels it already has keep their point and Vitality until the character reset (`gmreset`), a porter's call of slice X5; the mod is installed at the start of a playthrough ([save compatibility](../feature-mapping.md#save-compatibility)).

### Area decisions

**Area decisions** (all decided by the project owner, 2026-10-31, each the recommendation):

| # | Question | Options | Recommendation | Decision |
|---|---|---|---|---|
| DX1 | Which levels give no skill point in the new tree, and where the Vitality goes (XP-09). The owner's rule: no point on every third level, the three levels' Vitality on that level. Legacy: one tree, a point and 50 Vitality every level. 5.x: a point every level in both trees | (a) no point on levels 3, 6, …, 48; 150 Vitality on each, none on the levels between: by level 50, 33 points and 2,400 Vitality (a level-20 Geralt has 13 level points, a classic one 19); (b) counted from the first level-up: no point on levels 4, 7, …, 49, 150 Vitality on each, level 50 its point and 50 Vitality: 33 points and 2,450 Vitality by 50, as legacy's total; (c) no point on every third level, Vitality 50 every level as legacy (the rule's first half only) | **(a)**, the rule as stated; (b) only if level 50's total should equal legacy's to the point | **(a)** (project owner, 2026-10-31): in the new tree levels 3, 6, 9, …, 48 give no skill point and +150 Vitality, the other levels a point and no Vitality; a deviation ([XP-09](#xp-09-the-new-trees-skill-point-income-new-owner)) |
| DX2 | The rule past level 50 and in NG+ (XP-09). Past 50 each level costs 2,000 XP and gives 1 point and no Vitality in legacy (no level ability); NG+ starts at Geralt's level (at least 30) | (a) the same rhythm: no point on every third level past 50 and in NG+, no Vitality past 50 (legacy has none); (b) the rule stops at level 50: every level after it gives its point | **(a)**: one rule whatever the level; NG+ is not balanced anyway | **(a)** (project owner, 2026-10-31, with the owner's clarification): past level 50 the same pace continues (no point on every third level: 51, 54, …), and no level past 50 gives Vitality, the third levels included (legacy's levels past 50 give a point and no Vitality); NG+ the same; a deviation ([XP-09](#xp-09-the-new-trees-skill-point-income-new-owner)) |
| DX3 | Kill experience in NG+ (XP-04). Legacy's code takes the NG+ level off the enemy's level but compares it with Geralt's full level, so in NG+ (Geralt at least 30 levels up) every kill is about 30 levels "below" him and gives the minimum, 1 XP; quest experience compares both on the base game's levels and works. 1.32 and 5.x: their own formula, which works in NG+ | (a) legacy's code: 1 XP a kill in NG+; (b) compare both on the base game's levels (a fix, a deviation): an NG+ griffin at Geralt's level gives 10 | **(a)**: legacy behaviour first, and NG+ is carried over, not balanced or tested; (b) goes to Later. Not a defect that keeps the regular game's feature from working | **(a)** (project owner, 2026-10-31): legacy's code, 1 XP a kill in NG+; the fix (b) goes to Later. Not a deviation. How legacy played stays on the [legacy test list](../open-questions.md#to-test-in-legacy-ghost-mode) |
| DX4 | 5.x's new experience content (XP-02, XP-03, XP-04). Legacy: none existed. 5.x: `sq106_3_hammond_killed_crach` (level 11, 50 XP), a new branch of Killbill, whose other rewards legacy moved from level 11 to 16 (50, 25, 50, 75, 50, 75 XP); `q504_horse_returned` (30, 20 XP); the two `mq1060` priest rewards (15, 75 XP) and its quest level (15); its enemies (Reinald, plague victims, the red-plague creature) | (a) by analogy: the Killbill branch at level 16 with 5.x's 50 XP (inside legacy's range for the quest), the others 5.x's; each new enemy the type of its creature by its abilities (the red-plague creature AI's leshen analogy, DA5), checked in the slice; (b) everything 5.x's as it is | **(a)**: the Killbill branch otherwise pays like a level-11 quest in a quest legacy moved to 16 (a level-16 Geralt would get 5 XP instead of 50); the rest already fits legacy's scale | **(a)** (project owner, 2026-10-31): the Killbill branch `sq106_3_hammond_killed_crach` at level 16 with 5.x's 50 XP, the other new rewards and `mq1060_devils_pit`'s level 5.x's; each new enemy the XP type of its creature by its abilities. Not a deviation: content legacy never had, placed by analogy as AI's DA5 |
| DX5 | The game's texts on levels in the new tree (XP-09): "Each time you gain a level, you receive one Ability Point…" (1076557) and 5.x's "Each level grants Ability Points…" (1076528) are wrong on a third of the new tree's levels. Legacy: one tree, the texts true | (a) leave the texts; a new-tree line goes to Later; (b) new texts for the new tree in 9 languages (the classic tree keeps 5.x's) | **(a)**: tutorials, no legacy text to carry, and the panel shows the points Geralt has; (b) needs translations the project does not have | **(a)** (project owner, 2026-10-31): the texts stay; a new-tree line goes to Later. Not a deviation: legacy changed none |

**Porter's calls** (each follows legacy or has no play effect; all confirmed by the project owner, 2026-10-31):

| # | Call |
|---|---|
| PX1 | XP is ported as one area with one audit at the end, about 990 units |
| PX2 | XP-02: `gen_loot.py`'s reward overrides take legacy's `experience` and `level` for XP-02's units (gold 5.x's until ECON; legacy's since ECON's slice E4), and the two free-DLC files legacy changed without items (`dlc12`, `dlc15`) get overrides of their own |
| PX3 | XP-03: whole-file overrides of the four quest-level tables (DT1's form): 5.x's tables with legacy's 89 rows, 5.x's `mq1060_devils_pit` kept, legacy's removal of `mq2040_trial_of_power` kept (its journal entry shows no level) |
| PX4 | XP-01: legacy's rule replaces `OnGiveReward`'s experience block (no difficulty multipliers, no post-game halving, Hearts of Stone no longer special); the rest of 5.x's body kept |
| PX5 | XP-04: legacy's `CalculateExperiencePoints` with UI-10's counting folded in, so each kill is counted once and the diminishing returns read the count before the kill, as legacy (the first drowner gives 100%); UI-10's wrapper is removed; the debug log's call with `skipLog` counts nothing (UI-10's rule) |
| PX6 | XP-04: the combat log line "Experience Points: N" for each kill, as legacy |
| PX7 | XP-05: legacy's `experience` nodes in AI's abilities, which nothing reads (checked by script in the slice) |
| PX8 | XP-06: nests 25 XP once and 25 for the boss, dialogue payments 5 XP and Axii choices 5 XP per Axii level (1.32: 20 + 5 per level), as legacy, in replaced methods without legacy's new fields |
| PX9 | XP-07: legacy's group, ids, labels (2110992253, 270, 271, 300, 328, 451, 452), sliders and "Default" preset in OPT's framework; untouched options read off and 0 (legacy's and the preset's); "Disable quest levels" turned off in the menu reloads only the base game's, Hearts of Stone's and Blood and Wine's levels until the next load, as legacy |
| PX10 | XP-08: legacy's 50 Vitality per level and no attack or spell power in the classic tree; NG+ as legacy (its regular values; 5.x's `Lvl51`–`Lvl100` are already empty, found in slice X1, so nothing to empty) |
| PX11 | XP-10: the debug commands are not ported (debug only; `gmreset()` and the test commands do their work) |
| PX12 | NG+: XP-01 and XP-04 as legacy's code (DX3), XP-08 as PX10, XP-09 as DX2; untested |

### Later

NG+ kill experience on the base game's levels (DX3 (b)); a new-tree line in the level texts (DX5 (b)); the free DLCs' quest levels reloaded with the others when "Disable quest levels" is turned off.
