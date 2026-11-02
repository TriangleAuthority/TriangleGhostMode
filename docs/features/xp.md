# XP: experience and levels

How Geralt gains experience and what a level gives him: experience from quests (by the quest's level against Geralt's), the reward amounts and quest levels, experience from kills (by enemy type, level difference and how many of that type he has killed), the smaller sources (monster nests, bribes), the "Experience" options, the Vitality each level adds, and the skill points per level in each skill tree. Ghost Mode's changelist has its own section, "Experience" (lines 1075–1089), the experience half of "Mod options" (lines 1217–1225), the difficulty line "Experience gained no longer depends on difficulty level" (line 1142, DIFF-08) and the level-up line of "General player abilities" (lines 472–473); the mod description's section 6, "Quests, experience and rewards", and section 9, point 3, explain the intent.

**The player-visible texts first.** Legacy's changelist, quoted exactly: "Experience tables were reworked, difficulty dependent modifiers were removed. Experience scaling is now smooth: you get progressively less experience for lower level quests and more experience for higher level quests."; "Experience for kills was reworked, you get progressively less experience for killing monsters of the same type."; "You always get at least 5 XP for quests and at least 1 XP for monsters."; "Smooth experience adjustment means that you can can now get more experience for higher level quests, so they're now worth the trouble."; "Quest levels were tweaked so they make more sense (especially for Novigrad and Skellige where completing level 14 quest could result in next quest being level 9)."; "Some of the side quests related to main quest were moved later into the game, because they can indeed be completed later and to spread experience and quests a bit."; "Experience gained no longer depends on difficulty level."; "Passive attack and sign power bonuses were removed from Geralt's levelups: each level now adds 50 points to base Geralt's health - and nothing more."; and for the options: "Experience presets: default - everything zero and off.", "Disable quest levels: disables levels for quests, affects the numbers displayed in UI and quest XP gain; doesn't affect NPC levels are those are independent from quest levels internally.", "Fixed experience for quests and combat: disables smooth experience scaling and progressive experience for kills, the amount of exp rewarded is always the same and is define by quest settings and monster type.", "Quest/combat experience modifiers: allow to reduce or increase the amount of exp gained from quests/combat. The formula: XP*(1 + modifier)." The mod description adds "you get progressively more (up to 150%) experience for higher level quests/opponents and progressively less (up to 0%) for lower level quests/opponents" and "huge spikes like 4000 exp points at once were replaced with more reasonable rewards". Legacy's menu (Options → Mods → Ghost Mode, group "Experience", preset list "Experience Presets" with one preset, "Default") has "Disable quest levels", "Fixed experience for quests and combat", "Quest experience modifier" and "Combat experience modifier" (string ids 2110992328, 2110992452, 2110992451, 2110992253, 2110992300, 2110992270, 2110992271; 9 languages). Legacy also prints each kill's experience in the combat log with vanilla's string "Experience Points: $I$" (1066285, the key `hud_combat_log_gained_experience`, the same in 1.32 and 5.x). The game's own texts on levels (decoded from 1.32's and 5.x's `en.w3strings` with `w3strings.py`): "Each time you gain a level, you receive one Ability Point, which you can use to learn a new Ability or develop an Ability you already have." (1076557, unchanged in 5.x), and the tutorial 1076528, which 5.x rewrote for its new tree: 1.32 "When you have gained a certain number of Experience Points, you advance to the next level. You get Experience Points for killing monsters and completing quests.", 5.x "Gain Experience Points by killing monsters and completing quests to level up. Each level grants Ability Points, which you can spend to unlock or upgrade Abilities. Abilities only take effect when placed in an open Ability slot. They can be swapped at any time." (markup left out). Legacy changed none of them.

**What 5.x did in this area** (from `vanilla-5.x`, unverified in game). Almost nothing: the experience curve (`geralt_levelups.xml`: 1,000 XP per level at first, 84,000 in all for level 50, 2,000 per level after it, 1 skill point per level, cap 100), the quest experience rule (`CR4Game.OnGiveReward`), the kill experience formula (`CNewNPC.CalculateExperiencePoints`, its call in `OnDeath`), monster nests, bribes, `exp_mods.csv` (1 and 1), the quest levels and reward experience and levels, and the level-up abilities (`Lvl2` to `Lvl50`, regular and NG+) are 1.32's. What moved: the level-difference thresholds the quest and kill rules read (`LEVEL_DIFF_HIGH`/`DEADLY` 6/15 → 10/20; already back to 6/15 in the port since AI-01, DA4); 7 new rewards, 4 with experience (`q504_horse_returned` level 30, 20 XP; `sq106_3_hammond_killed_crach` level 11, 50 XP; `mq1060_priest_reward` and `mq1060_priest_dead_reward` level 15, 75 XP) and gold changes in 10 rewards (ECON); one new quest level (`mq1060_devils_pit` 15); the new tree's "Ability Points" (the same 1 per level) and its skill slots unlocked by points spent (SKL-01 set them back to levels); `W3LevelManager.AddPoints` updates the skill slots; the tutorial text above; and who earns a kill's experience (`CNewNPC.ShouldGiveExp`): 5.x added any NPC friendly to Geralt within 30 m of him, guards included, to 1.32's rule (Geralt's own kills, and within 20 m a non-actor's, a party companion's or an Axii'd NPC's, never a guard's), so allies' kills gave Geralt their experience and used up his kill counts (found by the [XP audit](#xp-audit-2026-10-31), F1; the port has 1.32's and legacy's rule again, XP-04). 5.x's XP-on-kill bonuses on its new swords are gone already (SWD-10).

**How legacy Ghost Mode implements it.** Data: the experience and level of 630 quest rewards in six `rewards.xml` files (base game, Hearts of Stone, Blood and Wine, three free DLCs), 89 quest levels in four `quest_levels` tables, the 49 level-up abilities `Lvl2`–`Lvl50` in `geralt_stats.xml` (NG+ the same, NG+'s `Lvl51`–`Lvl100` removed), the `experience` nodes of 14 enemy abilities (inert), the menu group `GMExpOptions` in `modSignsConfig.xml` and its 7 labels. Scripts: `CR4Game.OnGiveReward` (reworked), `CNewNPC.CalculateExperiencePoints` (rewritten) and the experience lines of `CNewNPC.OnDeath`, `GetExpByEnemyType` (new, `gm_generic.ws`), `W3PlayerWitcher.GetExpModifierByEnemyType` (new; it reads UI-10's kill counter), `CMonsterNestEntity.AddExp`, `AddBonusExp` and its fields, three `PerformAction`s in `choiceActions.ws`, the option getters in `W3GameParams`, `CR4Game.LoadQuestLevels` and `gmUserSettingsQuestLevels`, the option handlers in `CR4IngameMenu`; debug commands (`resetLevels`, `fb1`, `fb2`, `resetme`, ...) and `W3LevelManager.AddPoints`' `ignoreNGP`. No binary file: legacy's three experience-adjacent scene and phase edits are money (handed off).

Unit lists: [attribution.csv](attribution.csv): mapped 2026-10-31 from the changelist's sections, the mod description, every hand-off to XP in the other areas' files, a script diff of every function legacy changed that adds or reads experience or levels (`AddPoints`, `EExperiencePoint`, `CalculateExperiencePoints`, `OnGiveReward`, `W3LevelManager`, `LoadQuestLevels`, `GetLevelupAbility`), an attribute-by-attribute comparison of every reward in the six reward files (master, `legacy-GM`, `vanilla-5.x`), the quest-level tables row by row, the `experience` nodes and the `*_exp_bonus_when_fatal` bonuses in every XML file, the level-up abilities, legacy's menu XML and labels, and sweeps (`unit_sweep.py --unattributed` for experience, `Exp`, `EExperiencePoint`, `GetLevel()`, quest level, `LevelUp`, `levelManager`, `AddPoints`, skill points; `exp_bonus`). **989 units carry an XP feature**: 905 newly attributed, XP added to 84 shared units (LOOT's 52 rewards with items, AI's 25 abilities with `experience` nodes, UI-10's kill-counter functions, ALCH-14's nest fields, SKL-01's `AddPoints`, OPT-01's and DIFF-04's menu XML). By type: 34 script units, 690 XML units and 113 NG+ XML units, 152 CSV rows (89 quest levels, 63 labels). Unattributed units: 3,128 before, 2,223 after. Left unattributed: 31 rewards whose only change is gold (ECON) and the debug command `whoareyou`. Port status: **mapped** (2026-10-31), analysed against 5.x from the code and data (unverified in game); the [area decisions](#area-decisions) DX1 to DX5 made and the porter's calls PX1 to PX12 confirmed by the owner (2026-10-31); slice X1 (XP-08, XP-05) **verified** in both trees (2026-10-31, 5.x-GM `9e08f96a`); slice X2 (XP-01, XP-02, XP-03) **verified** in both trees (2026-10-31, 5.x-GM `086aa4b3`); slice X3 (XP-04, XP-06) **verified** in both trees by script (2026-10-31, 5.x-GM `9ce4fd30`); slice X4 (XP-07) **verified** in both trees by script (2026-10-31, 5.x-GM `bacb86cc`; the menu on screen in the [cleared run](#cleared-run-on-screen-2026-11-01), 2026-11-01); slice X5 (XP-09) **verified** in both trees by script (2026-10-31, 5.x-GM `201c25c3`). **Every XP slice is done**. **Audited** 2026-10-31 ([XP audit](#xp-audit-2026-10-31): 6 findings, none high; owner decisions: F1, kills by friendly NPCs near Geralt (5.x's rule kept unnoticed), and F3, the porter's calls to confirm; clear fixes F2, F4, F5; regression clean in both trees); the audit's fixes and the owner's decisions made (2026-10-31, 5.x-GM `c9133d5e`, [close-out](#xp-audit-close-out)): F1 (a), legacy's rule for who earns a kill's experience; F2, F4 and F5 fixed; F3's porter's calls confirmed by the owner. **Signed off** by the owner (2026-10-31).

**Size.** One area, one part, one audit at the end (PX1): mostly data (rewards, quest levels, level-up abilities) from generators, two rewritten script functions, a menu group, and the new tree's income rule, the one new design.

## Scope

**XP covers** experience from quests and kills and the other experience sources legacy changed, the reward amounts and levels, the quest levels, the experience options, what a level gives (Vitality, skill points) in both trees, and the debug level commands.

**Unchanged by legacy, and by 5.x** (from the data): the experience curve and the level cap (`geralt_levelups.xml`, `W3LevelManager.GetMaxLevel` 100), 1 skill point per level in the classic tree, `exp_mods.csv`, NG+'s doubled experience below level 50 (`AddPoints`), the full heal at a level-up except on "Death March!", Places of Power and the other skill-point sources (feature-mapping's [progression](../feature-mapping.md#progression)). Crafting and discovering places give no experience of their own in any of the three games; points of interest pay through their rewards (XP-02).

**Already ported by other areas** (nothing left for XP):

| Subject | Ported by | What |
|---|---|---|
| The kill counter per enemy type, its saved field, the enemy types and their names, the counting place (a wrapper of `CalculateExperiencePoints`) | UI-10 (signed off) | `ui/bestiary.ws`; XP-04 reads the counts and must merge with the wrapper (PX5) |
| The XP-on-kill bonuses of swords and crossbows removed (`human_exp_bonus_when_fatal`, `nonhuman_exp_bonus_when_fatal`), also 5.x's new swords | SWD-02, SWD-03, SWD-04, SWD-10, XBOW-02 (signed off) | item data |
| The character panel's experience bonus lines removed | UI-05 (signed off) | |
| The level-difference thresholds 6 and 15 that quest and kill experience read | AI-01 (DA4, signed off) | `W3GameParams` defaults |
| The quest rewards' items | LOOT-07 (signed off) | `gen_loot.py`'s reward overrides, whose experience, level and gold stay 5.x's until XP and ECON |
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
| Port status | **verified** (slice X2, 2026-10-31, both trees, 5.x-GM `086aa4b3`) |
| Open checks | — |
| Save impact | none (expected) |
| NG+ counterpart | the rule reads the base game's level in NG+ (legacy's), untested |

**What it does** (changelist 1078–1080, 1083–1085, 1142): a quest reward's experience follows the quest's level against Geralt's: each level the quest is above him adds 16%, up to 150% at about 3 levels above; each level below takes 16% away, down to nothing at about 6 levels below; then the reward is at least 5 XP. Example, a 300-XP reward of a level-10 quest: Geralt at 10 gets 300, at 8 gets 396, at 7 gets 444, at 6 or below 450 (the cap), at 12 gets 204, at 14 gets 108, at 16 gets 12, at 17 and above 5. The mode no longer matters. In 1.32 and 5.x the same reward gives 300 on the two lower modes, 270 on "Blood and Broken Bones!", 240 on "Death March!" whatever Geralt's level, until the quest is 6 levels below him (Geralt 16: 15, a twentieth); only Hearts of Stone's quests (`q60*`) scale by level; and once the main story is finished every base-game quest pays half.

**Implementation (legacy):** `CR4Game.OnGiveReward`: modifier 1; Geralt's level less the NG+ level in NG+; the reward's level (0 with "Disable quest levels"); unless "Fixed experience" or a reward of level 0, modifier + (reward level − Geralt's level) × `LEVEL_DIFF_XP_MOD` (0.16), clamped to 0 … `MAX_XP_MOD` (1.5); `RoundMath(experience × expGlobalMod_quests × modifier)`, at least 5; then × (1 + the quest experience modifier) if it is not 0 (XP-07). The post-game halving and the difficulty multipliers are gone.

**5.x:** 1.32's code; 0.16 and 1.5 are 1.32's too. Today the port runs it with AI-01's thresholds (6 and 15), so a quest 6 levels below Geralt pays 5%, as in 1.32.

**Decisions:** legacy's (PX4).

**Verification (slice X2, 2026-10-31, both trees; 5.x-GM `086aa4b3`; `tests/gmTestsXpQuest.ws`).** `gmtest_xp01()`, from the freshly loaded test save, raises Geralt through the level manager's own path (`AddPoints` with exactly the experience the next level needs) to 8, 10, 12, 16 and 17, and at each gives four rewards through the game's own `theGame.GiveReward` (what quest reward blocks and scenes call), comparing the experience gained with legacy's rule worked by hand. The rewards' data is XP-02's. The checks first ran on a throwaway build with the tests and 5.x's `OnGiveReward` and data, and failed there (20 of 22, e.g. the Triss reward +180 at Geralt 8 on "Blood and Broken Bones!", Olgierd's +135); the throwaway build was then deleted. The test save was reloaded between runs and never saved; the mode was set with `gmtest_diff_mode` in its own exec call and set back to "Blood and Broken Bones!"; no autosave was written.

| Check | How | Classic tree | New tree |
|---|---|---|---|
| A level-10, 250-XP reward (`q301_2_helped_triss`) at Geralt 8, 10, 12, 16, 17: 330, 250, 170, 10, 5 (5.x: 250 up to Geralt 15, then 13; ×0.9 or ×0.8 on the two higher modes) | scripted: `GiveReward` (`gmtest_xp01`) | 5 of 5 on each mode | 5 of 5 on each mode |
| Hearts of Stone like the rest: `q601_olgierd_met` (level 32, 200 XP) at the 150% cap, 300 at each level (5.x: 200; its own scaling only within 6 levels) | scripted (`gmtest_xp01`) | 5 of 5 on each mode | 5 of 5 on each mode |
| The 5 XP minimum: `mq1045_encounter_02_exp` (level 10, 25 XP): 33, 25, 17, then 5 and 5 (5.x: 25, then 1) | scripted (`gmtest_xp01`) | 5 of 5 on each mode | 5 of 5 on each mode |
| Killbill's 5.x branch (`sq106_3_hammond_killed_crach`, DX4: level 16, 50 XP): 75, 75, 75, 50, 42 (5.x's level 11: 50 up to Geralt 16, then 3) | scripted (`gmtest_xp01`) | 5 of 5 on each mode | 5 of 5 on each mode |
| No post-story halving: the Triss reward at Geralt 10 with `witcher3_game_finished` at 2 (5.x's condition) still 250 (5.x: 125); the fact set back | scripted (`gmtest_xp01`) | 2 of 2 on each mode | 2 of 2 on each mode |
| The mode does not matter | the same run on two modes | "Blood and Broken Bones!" and "Death March!": 22 of 22 each | "Blood and Broken Bones!" and "Just the Story!": 22 of 22 each |

Not tested: NG+ (PX12). The XP-07 options' effect on rewards is XP-07's checks.

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
| Port status | **verified** (slice X2, 2026-10-31, both trees, 5.x-GM `086aa4b3`) |
| Open checks | — |
| Save impact | none (expected: rewards are read when given) |
| NG+ counterpart | none (one reward table for both) |

**What it does** (changelist 1078, 1086–1089; mod description section 6): "huge spikes ... were replaced with more reasonable rewards"; the main quest stays the main source, then contracts; side and minor quests give little, races, fistfights and gwent less and more money. Of 1.32's 891 rewards in the six files legacy changed the experience of 547 and the level of 193 (630 rewards): base game 73,060 → 60,235 XP, Hearts of Stone 11,400 → 11,100, Blood and Wine 41,100 → 31,050, the free DLCs 1,150 → 1,410. Examples: finding Ciri (`q402_2_found_ciri`) 4,000 at level 22 → 1,500 at level 24; gathering the allies for Kaer Morhen 1,000 → 100; the Battle of Kaer Morhen's end (`q403_09_completed`) 1,000 → 1,500; Dun Tynne 1,500 → 500; Johnny found 50 → 150; Killbill's (`sq106`) rewards from level 11 to 16; the cave troll left alone (`mh201_troll_left_alone`) given level 27.

**Implementation (legacy):** the `experience` and `level` attributes of the rewards in `gameplay/rewards/rewards.xml` (449), `dlc/ep1` (55), `dlc/bob` (116), `dlc3` (4), `dlc12` (2), `dlc15` (4).

**5.x:** 1.32's values for every reward legacy changed; 7 new rewards (DX4), gold in 10 (ECON).

**Decisions:** legacy's values (PX2). 5.x's new rewards by analogy (DX4 (a), owner, 2026-10-31): Killbill's new branch `sq106_3_hammond_killed_crach` at legacy's level for the quest, 16, with 5.x's 50 XP; `q504_horse_returned` and the two `mq1060` priest rewards 5.x's. Content legacy never had, so not a deviation.

**Verification (slice X2, 2026-10-31, both trees; 5.x-GM `086aa4b3`; `tests/gmTestsXpQuestData.ws`).** `gen_xp.py --verify`, independently of `gen_loot.py`'s merge: all 898 rewards of the six files read as expected, each attribute once; 629 have an experience or level other than 5.x's (the other two XP-02 units differ from 5.x's only in writing: legacy's `experience="0"` for 1.32's `"00"`); `gen_loot.py --verify`: 0 unexplained. The data check first ran on the throwaway build with 5.x's data and failed there (629 of 634). A reward's effect in play is XP-01's checks above, which give four of them through `GiveReward`.

| Check | How | Classic tree | New tree |
|---|---|---|---|
| 634 rewards as `GetReward` reads them: the 630 XP-02 units with legacy's experience and level and 5.x's gold at the time (legacy's since ECON's slice E4; finding Ciri 1,500 XP at level 24, Killbill's at 16), from all six files (base game, Hearts of Stone, Blood and Wine, `dlc3`, `dlc12`, `dlc15`); 5.x's four new rewards with experience 5.x's, the Killbill branch at level 16 | scripted: definitions read (`GMTest_xpquestdata`, in the regression) | passed | passed |

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
| Port status | **verified** (slice X2, 2026-10-31, both trees, 5.x-GM `086aa4b3`) |
| Open checks | — |
| Save impact | none (expected: loaded at game start) |
| NG+ counterpart | none |

**What it does** (changelist 1086–1089): the level shown for each quest in the journal and the quest tracker, its colour against Geralt's level, the "high-level quest" tutorial, and whether a contract can be tracked (Geralt at most 5 levels below its level: `CanTrackQuest` allows it when his level is at least the quest's − 5). Quest experience reads the reward's own level (XP-02), not this table. Legacy moved 79 base-game quests (68 up, 11 down: the Fistfight Championship 11 → 30, "Master of the Arena" 14 → 22, "Immoral Proposition" 15 → 23, the Courier 2 → 12; a sunken treasure and a pond 18 → 5), added two (`mq2052 Reversed Monster Hunt` 29, `mh201 : Cave Troll` 27) and removed one (`mq2040_trial_of_power`, then shown without a level); Hearts of Stone's Ofieri armor 33 → 32, Blood and Wine's `ww_belgard_secret` 42 → 38, the Wolf School gear hunt 14/21/29 → 21/24/28 (the table dlc10's quest mounter loads is `th1009_quest_levels_copy.csv`, read from 5.x's `dlc10.reddlc`).

**5.x:** 1.32's rows; one new row (`mq1060_devils_pit` 15).

**Decisions:** legacy's (PX3); 5.x's new row `mq1060_devils_pit` (15) kept (DX4 (a)). Legacy's two added base-game rows (`mh201 : Cave Troll` 27, `mq2052 Reversed Monster Hunt` 29) repeat rows the free DLCs `dlc3` and `dlc12` already load at the same levels (1.32 and 5.x alike), so they change nothing in play; kept as legacy has them.

**Verification (slice X2, 2026-10-31, both trees; 5.x-GM `086aa4b3`; `tests/gmTestsXpQuestData.ws`).** `gen_xp.py --verify`: each table 5.x's with legacy's rows (base game 294 rows, 82 differ from 5.x's; Hearts of Stone 1, Blood and Wine 1, the Wolf School gear 5). The game loads seven tables, the DLCs' first (`bob`, `dlc3`, `dlc10`'s copy, `dlc12`, `dlc15`, `ep1`) and the base game's last (read in game); the overrides replace the base game's and the DLCs' tables alike. The check first ran on the throwaway build and failed there (87 of 90: Wolf Set 14, `ww_belgard_secret` 42, `mq2040_trial_of_power` 16); the first real run found the two repeated rows above, which the check accepts when every copy agrees.

| Check | How | Classic tree | New tree |
|---|---|---|---|
| 90 quest levels as the journal reads them (every loaded table, the last row of the name, as `CR4JournalQuestMenu`): legacy's 89 changed rows (the Fistfight Championship 30, the Wolf School gear 21/24/28, Ofieri's armor 32, `ww_belgard_secret` 38), `mq2040_trial_of_power` none, 5.x's `mq1060_devils_pit` 15 | scripted: tables read (`GMTest_xpquestdata`, in the regression) | passed | passed |

The journal and quest tracker on screen: not doable from the test save ([cleared run](#cleared-run-on-screen-2026-11-01), 2026-11-01): its two quests (Lilac and Gooseberries, Kaer Morhen) are level 1 and show no level either way; needs a save with higher-level quests in the journal.

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
| Port status | **verified** by script (slice X3, 2026-10-31, both trees, 5.x-GM `9ce4fd30`); who earns a kill's experience (XP audit F1) verified by script in both trees (2026-10-31, 5.x-GM `c9133d5e`) |
| Open checks | an ally's kill beside Geralt in a real fight (not set up on the test save). A kill by Geralt's own attacks **verified** ([cleared run](#cleared-run-on-screen-2026-11-01), 2026-11-01): a wolf +1 XP. The combat log line cannot be seen on screen: 5.x's HUD shows no combat log |
| Save impact | none (expected); the counts are UI-10's saved field, counting from the mod's installation |
| NG+ counterpart | legacy's code (DX3), verified by script (the NG+ facts set and taken back within one call) |

**What it does** (changelist 1081–1083, 1142; mod description section 6): a kill gives a base amount by enemy type: wolves and dogs 1; humans, drowners, nekkers, ghouls, harpies, wraiths, sirens, wyverns, foglets, water hags, the Wild Hunt's warriors and hounds, bears, endrega workers, boars, giant spiders, panthers, barghests, kikimore workers and archespores 5; most other monsters (griffins, basilisks, cockatrices, forktails, werewolves, katakans, ekimmas, trolls, cyclopes, noonwraiths and nightwraiths, grave hags, Blood and Wine's bruxae, alps, slyzards, kikimore warriors, centipedes and garkains) 10; arachases, golems, elementals, fiends, chorts, leshens, shaelmaars, spriggans and wights 15; contract monsters 15; bosses 20; unidentified creatures and animals a base of 0, which the 1 XP minimum makes 1. It is multiplied by 1 + 0.16 × (enemy level − Geralt's level), from 0 to 150%, and, but for bosses, by 1 − (kills of that type so far ÷ 100): the hundredth drowner and every one after it gives 0 before the minimum; the product is rounded down (legacy's `RoundF` truncates, seen in game). Then × Geralt's gear's kill-experience bonus (none left in legacy's data but two random bonuses), × the combat experience modifier (XP-07), at least 1, and the combat log shows "Experience Points: N". Examples at Geralt 10 (verified by script): a drowner at his level 5, after 50 drowners 2 (2.5 rounded down), after 100 1; a drowner 3 levels below him 2, 5 above 7 (the 150% cap), 7 below 1; a wolf 1; a bandit 5; a griffin 3 levels above him 14 (14.8), a griffin at his level after 50 griffins 5; a contract monster 15, cut by earlier kills of its creature type (a contract wyvern after 40 wyverns 9); a boss 20 whatever the kills, 29 at 3 levels above. Guards give none and count as human kills, so killing guards lowers later human experience. **Who earns it:** Geralt's own kills; within 20 m of him also a kill by something that is not an actor (a trap, the environment), by a party companion or by an NPC under Axii; never a guard's kill, and no other ally's (1.32's and legacy's `ShouldGiveExp`). Only a kill that earns experience is counted for the diminishing returns. With DIFF's default soft upscaling, an enemy far below Geralt is lifted to 6 levels below him and then gives the minimum (a level-1 drowner at Geralt 10: level 4, 1 XP); legacy's behaviour. 5.x's new enemies (DX4): the plague victims are humans (5); the red-plague creature is a contract monster with the Hym's boss ability, so 15, never cut, counted as a boss; Reinald's entity grants no kill experience (5.x's flag, kept), so he gives none and is not counted. In NG+ (DX3) an enemy at Geralt's level counts 30 or more levels below him: the 1 XP minimum, which 5.x's NG+ doubling in `AddPoints` makes 2 (the log shows 1). In 1.32 and 5.x a kill's experience comes from the enemy's damage, armor, health and special abilities, capped by its level (1 + 2 per level for humans, 5 + 4 for monsters), quartered below level 30 and halved above, with bonuses at 6 and 15 levels above Geralt, 2 when 6 or more below, halved again past level 35, at most 50, then ×1.2 on "Just the Story!", ×0.9 and ×0.8 on the two higher modes; no combat log line. On the port before the slice (Geralt 10, "Blood and Broken Bones!", read in game): a drowner 2 at any kill count and 2 at 5 levels up, a wolf 2, a bandit 4, a griffin 10 (also 3 levels up), a contract wyvern 10, the Caretaker 10 (13 at 3 levels up), a plague victim 4.

**Implementation (legacy):** `CNewNPC.CalculateExperiencePoints` (`npc.ws`, rewritten): 0 for `grantNoExperienceAfterKill` or `Zero_XP`; a guard counts as a human kill and gives 0; type by `GetEnemyTypeByAbility`, base by `GetExpByEnemyType` (`gm_generic.ws`), 15 for `W3MonsterHuntNPC`; in NG+ the NG+ level is taken off the enemy's level only; unless "Fixed experience", modifier `ClampF(1 + (currentLevel − Geralt's level) × 0.16, 0, 1.5) × GetExpModifierByEnemyType` (`playerWitcher.ws`: bosses 1, generic and animals 0, else `1 − Min(100, kills) / 100`); `Max(1, RoundF(exp × modifier))`, then `IncKills`. `CNewNPC.OnDeath`: `RoundMath(exp × (1 + gear bonus) × expGlobalMod_kills)`, at least 1, × (1 + combat modifier) if not 0, `AddPoints`, the combat log line.

**5.x:** 1.32's code (`CalculateExperiencePoints` unchanged; `OnDeath`'s experience lines 1.32's in 5.x's body, which the port replaces for ENCH). UI-10 wraps `CalculateExperiencePoints` and counts the kill before the body runs; legacy counts after computing (PX5). `ShouldGiveExp` is 1.32's with a new branch: a kill by any NPC friendly to Geralt within 30 m of him gives Geralt the experience (and so the kill count), guards included; seen in game before the fix (Geralt at level 10, a drowner at his level: killed by a friendly renegade 6 m away or a friendly Novigrad guard 8 m away, +5 XP and one drowner kill more each).

**Decisions:** legacy's (PX5, PX6). NG+: legacy's code, 1 XP a kill (DX3 (a), owner, 2026-10-31; the fix is on the Later list). 5.x's new enemies (Reinald, the `mq1060` plague victims and red-plague creature) get the XP type of their creature, the one `GMGetEnemyTypeByAbility` finds for their abilities, checked in slice X3 (DX4 (a)). Who earns a kill's experience: legacy's (1.32's) rule (XP audit F1, option (a), owner, 2026-10-31); 5.x's friendly-NPC branch removed, so allies' and guards' kills near Geralt give him nothing and count no kill. Not a deviation (legacy's rule; it differs from 5.x's). Porter's calls of slice X3 (confirmed by the owner, 2026-10-31; content legacy never had, or no play effect, so not deviations):
- The plague victims' template `ConDefaultSilver` (5.x's silver-vulnerable humans; no other entity keeps it after AI-02's lists) counts as human in `GMGetEnemyTypeByAbility`: 5 XP, cut by human kills, counted as humanoids in the bestiary. Without it they are unidentified: the 1 XP minimum, not shown by type.
- The red-plague creature stays what the function finds: its Hym ability `mon_him` is one of legacy's boss abilities and its entity a contract monster (`W3MonsterHuntNPC`), so 15 XP × the level term, never cut, counted as a boss. The alternative, the leshen's type (AI's DA5 analogy): the same 15 at first, then cut by earlier leshen kills, counted with leshens.
- Reinald keeps his entity's `grantNoExperienceAfterKill` (5.x's own flag; his entity is a contract monster too): no kill experience and no count, the quest's rewards pay. The alternative, the flag ignored for him: he would need a type first (his template `mq1060_Reinald` is a copy of `ConDefault` under another name), then 5 XP as a human.
- In NG+ the NG+ level is taken off a local copy of the enemy's level; legacy subtracts it from the dying NPC's stored level itself. The kill's experience is the same; only the dead NPC's stored level differs.

**Verification (slice X3, 2026-10-31, both trees; 5.x-GM `9ce4fd30`; `tests/gmTestsXpKills.ws`).** `gmtest_xp04_spawn()` raises Geralt to level 10 through the level manager's path and spawns the samples frozen and friendly; `gmtest_xp04()` sets each one's level (`SetLevel`) and the kills of its type (the saved counter) by script, makes it hostile and mortal, and kills it with a scripted hit through the damage manager with Geralt as the attacker, which runs the game's own death handling (`OnDeath`); it compares the experience gained, the kill counter and the combat log's messages (a test wrapper of `W3GameLog.AddMessage`) with legacy's formula worked by hand, then puts the counts back. The checks first ran on a throwaway build with the tests and 5.x's code and failed there (18 of 23: e.g. a drowner 2 XP whatever its level and kills, the Caretaker 10, a contract wyvern 10, no log line; the guard's and Reinald's passed, as 5.x gives neither experience); the throwaway build was then deleted. Each launch loaded the test save and was quit without saving.

| Check | How | Classic tree | New tree |
|---|---|---|---|
| A drowner at Geralt's level after 0, 50 and 100 drowner kills: 5, 2, 1; 5 levels up 7 (the cap), 3 down 2, 7 down 1; each kill counted once (0 → 1, 50 → 51, 100 → 101) | scripted: kill counts set, a killing hit through the damage manager (`gmtest_xp04`) | 6 of 6 | 6 of 6 |
| A wolf 1; a bandit (a renegade) 5, counted as a human | scripted (`gmtest_xp04`) | 2 of 2 | 2 of 2 |
| A griffin 3 levels above Geralt 14 (14.8); a griffin at his level after 50 griffins 5 | scripted (`gmtest_xp04`) | 2 of 2 | 2 of 2 |
| A contract monster (`mq1051_wyvern`, `W3MonsterHuntNPC`): 15, after 40 wyverns 9 (its creature's kills) | scripted (`gmtest_xp04`) | 2 of 2 | 2 of 2 |
| A boss (the Caretaker, `q604_caretaker`): 20 after 50 boss kills, 29 at 3 levels up after 100 (never cut) | scripted (`gmtest_xp04`) | 2 of 2 | 2 of 2 |
| A guard (Novigrad's community guard, given the guard group type, which it spawns without): no experience, no log line, counted as a human kill (0 → 1) | scripted (`gmtest_xp04`) | 1 of 1 | 1 of 1 |
| 5.x's new enemies (DX4): a plague victim 5 as a human; the red-plague creature 15 as a contract monster and boss; Reinald none, not counted | scripted (`gmtest_xp04`) | 3 of 3 | 3 of 3 |
| DIFF's soft upscaling: a level-1 drowner at Geralt 10 lifted to level 4, 1 XP | scripted: its own level after the spawn (`gmtest_xp04`) | 1 of 1 | 1 of 1 |
| NG+ (DX3): with `NewGamePlus` and an NG+ level of 30 set by script, a drowner at Geralt's level: the log shows 1, Geralt gains 2 (5.x's NG+ doubling); the facts and the NG+ level set back | scripted (`gmtest_xp04`) | 2 of 2 | 2 of 2 |
| The combat log line "Experience Points: N" with each kill's experience (every kill above that gives some) | scripted: the messages read (`gmtest_xp04`) | in each check | in each check |
| UI-10's kill counter after the fold (only the counting order moved): its regression checks, and a wolf killed through the game's death path counted once | scripted (`GMTest_ui10`, `gmtest_ui10_kill_a/b/c`) | passed | passed |

`gmtest_xp04` in all: 23 of 23 in each tree. The regression: `gmtest_regress()` 1,105 passed, 0 failed, and `gmtest_panel()` 139 passed, 0 failed, in each tree; XP-05's check now reads the bandit's and drowner's kill experience as 7 and 7 (XP-04's formula; 5 and 6 with 5.x's), its expectation (unchanged by the node) the same. ENCH's kill checks outside the regression, run again in the classic tree: Rejuvenation and Elation (`gmtest_ench08_a/b`, the sword drawn before each) and Eruption's 300 fire damage (`gmtest_ench13_erupt_a/b`) passed; Eruption's "second dummy alight" failed with this session's setup, the same on the build before the slice (5.x-GM `086aa4b3`), so not from the slice.

**Who earns a kill's experience** (XP audit F1 and F4, 2026-10-31, both trees; 5.x-GM `c9133d5e`; `tests/gmTestsXpAuditChecks.ws`). Four drowners at Geralt's level (no earlier drowner kills) spawned frozen at 10, 6, 8 and 45 m behind him, a friendly renegade and a friendly Novigrad community guard given the guard group type; each drowner made hostile and killed by a scripted hit through the damage manager (`OnDeath`) with the attacker named; the experience taken back and the counts put back after each. Before the fix (5.x-GM `201c25c3`'s code, and a throwaway build without `xp/killEarner.ws`, deleted afterwards) it failed 2 of 6: the renegade's kill 6 m away and the guard's 8.4 m away each gave Geralt +5 and a drowner kill.

| Check | How | Classic tree | New tree |
|---|---|---|---|
| Geralt's kill 10 m away +5 XP, counted; a friendly renegade's 6 m away, a friendly guard's 8.4 m away and the renegade's 45 m away +0, not counted; experience and counts back | scripted: kills through the damage manager with the attacker named (`GMTest_xp04_who_spawn` in `gmtest_regress()`, `GMTest_xp04_who_after` in `gmtest_panel()`; standalone at Geralt 10: `gmtest_xp04_who_spawn()`, `gmtest_xp04_who()`) | 6 of 6 (in the panel and standalone) | 6 of 6 (in the panel and standalone) |

Geralt's own attacks in a real fight: **verified** in the [cleared run](#cleared-run-on-screen-2026-11-01) (a wolf, +1 XP). Not done: an ally fighting beside him. The combat log line is not shown on screen in 5.x (no combat log in the HUD); the scripted read of the log's messages stays its check.

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
| Port status | **verified** (slice X1, 2026-10-31, both trees, 5.x-GM `9e08f96a`) |
| Open checks | — |
| Save impact | none (nothing reads the nodes; an NPC's attribute reads the definitions live) |
| NG+ counterpart | applied, as legacy's NG+ entries (`gen_ai.py --verify`), untested |

**What it does:** nothing in play. Legacy changed or dropped the `experience` node of `MonsterLevelBonusArmored` (2 → 4), `ConAthletic` (10 → 0), the new `AnimalLevelBonus`, `NPCLevelBonus`, `MiniBoss`, `Boss` and `ConHumanoidMonster` (1, 2, 30, 50, 0), and dropped it from `MonsterMHBoss` (50), `MonsterLevelBonusHigh` (20), `MonsterLevelBonusDeadly` (100), `sq201_werewolf` (44) and the NG+ Wild Hunt leaders (100); 5.x itself has no node in `MonsterLevelBonusHigh` and `MonsterLevelBonusDeadly` (1.32's 20 and 100). No script of 1.32, legacy or 5.x reads an NPC's `experience` attribute (the only reader of the name is the journal's reward line, `hudModuleJournalUpdate.ws`); 1.32's kill formula reads damage, armor and health instead. These are the `LATER` nodes AI left to XP.

**Decisions:** legacy's nodes (PX7), so AI's abilities equal legacy's but for WGT's weights.

**Verification (slice X1, 2026-10-31, both trees; 5.x-GM `9e08f96a`; `tests/gmTestsXp.ws`, `tests/gmTestsXpData.ws`).** `gen_ai.py --verify`: no difference (531 abilities in `abilities`, 526 in `abilities_plus`); `gen_xp.py --verify`: 27 experience nodes of AI's abilities as legacy's entries have them, 8 different from 5.x's. A static search of 5.x's and the port's scripts finds no reader of an `experience` attribute (the only `'experience'` is the journal's reward line, an item name). The data check was first run on a throwaway build with the tests and 5.x's nodes and failed there (7 nodes, e.g. `MonsterMHBoss` 50, `NPCLevelBonus` 0); the build was then deleted.

| Check | How | Classic tree | New tree |
|---|---|---|---|
| The experience node of every ability `gen_ai.py` gives that has one in legacy or 5.x: 42 nodes, legacy's (0 where legacy dropped it: `MonsterMHBoss`, `ConAthletic`, `sq201_werewolf`; `NPCLevelBonus` 2, `MonsterLevelBonusArmored` 4, `MiniBoss` 30, `Boss` 50) | scripted: definitions read (`GMTest_xpdata`, in the regression) | passed | passed |
| Nothing reads the node: a bandit and a drowner spawned frozen and friendly, set 10 levels above Geralt; their `experience` attribute reads legacy's level nodes (20: ten levels of `NPCLevelBonus`' and `MonsterLevelBonusGroup`'s 2), and with a test ability adding +1000 experience it reads 1,020 while their kill experience (`CalculateExperiencePoints` with `skipLog`, which counts no kill) stays the same: 5 and 6 with 5.x's formula (slice X1), 7 and 7 with XP-04's (since slice X3) | scripted (`GMTest_xp05`, in the regression) | 2 of 2 | 2 of 2 |

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
| Port status | **verified** by script (slice X3, 2026-10-31, both trees, 5.x-GM `9ce4fd30`) |
| Open checks | — |
| Save impact | none (expected; a nest already destroyed keeps its saved flag) |
| NG+ counterpart | none |

**What it does** (not in the changelist): destroying a monster nest gives 25 XP, once per nest (a rebuilt nest destroyed again gives nothing), and killing its boss 25 more. In 1.32 and 5.x a nest gives the values its entity sets, every time it is destroyed (the base game's nekker nest sets 20 and its boss 50, not once only; without entity values the script's defaults are 100 and, by a typo, 0 for the boss). Paying a bribe or a dialogue payment gives 5 XP (1.32 and 5.x: a tenth of the money, so a 300-crown bribe 30 XP); an Axii choice in dialogue gives 5 per Axii level (1 + Delusion's level: 5 to 20; 1.32 and 5.x: 20 more, 25 to 40): legacy's code drops the 20, not the level term.

**Implementation (legacy):** `CMonsterNestEntity.AddExp`, `AddBonusExp` and three new fields (`expOnNestDestroyedMod`, `bonusExpOnBossKilledMod`, `addExpOnlyOnceMod`; the fields' defaults fixed too); `CPayFactBasedStorySceneChoiceAction`, `CPayStorySceneChoiceAction`, `CAxiiStorySceneChoiceAction.PerformAction`.

**5.x:** 1.32's.

**Decisions:** legacy's (PX8). The Axii choice follows legacy's code (5 × Axii level), not a flat 5 XP as the map summarised it.

**Verification (slice X3, 2026-10-31, both trees; 5.x-GM `9ce4fd30`; `tests/gmTestsXpKills.ws`).** The choice actions as a scene calls them: each class created by script and its own `PerformAction` called (crowns given first and taken back). The nest: the base game's nekker nest (`gameplay\interactive_objects\monster_nest\monster_nest_nekker.w2ent`, which takes only a placed bomb, `interactionOnly`) spawned 15 m away and blown up through its own `Explosion` state, as `OnInteraction` leads there once Geralt has a bomb, without his animation and the bomb item (a test method; the nest tagged out of the destroyed-nests statistic and its achievement check); read 8 s later, then its boss's `SetBossKilled`, then the nest put back to its intact state and blown up again. The checks first ran on the throwaway build with 5.x's code and failed there (6 of 6: 30, 12 and 25 XP; the nest 20, its boss 50, the second destruction 20 again).

| Check | How | Classic tree | New tree |
|---|---|---|---|
| A dialogue payment of 300 crowns 5 XP (5.x 30); a bribe of 120 from a fact 5 (5.x 12); an Axii choice at Axii level 1 5 (5.x 25) | scripted: the actions' own `PerformAction` (`gmtest_xp06_a`) | 3 of 3 | 3 of 3 |
| A nest destroyed 25 XP (5.x: the entity's 20), its boss 25 (5.x 50), the same nest destroyed again 0 (5.x 20) | scripted: the nest's `Explosion` state and `SetBossKilled` (`gmtest_xp06_a/b/c`) | 3 of 3 | 3 of 3 |

Not done in the cleared run (2026-11-01; needs a save at a monster nest and at those dialogues): a nest blown up with a real bomb by Geralt; a payment and an Axii choice chosen in a real dialogue.

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
| Port status | **verified** by script (slice X4, 2026-10-31, both trees, 5.x-GM `bacb86cc`) |
| Open checks | the journal's and the quest tracker's levels on screen with quest levels disabled (the test save's quests show no level either way). The menu on screen and a change by hand **verified** ([cleared run](#cleared-run-on-screen-2026-11-01), 2026-11-01) |
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

**Verification (slice X4, 2026-10-31, both trees; 5.x-GM `bacb86cc`; `tests/gmTestsXpOpts.ws`).** Each case goes through the options menu's own code path: the pause menu opened (`ingamemenu()`), each option that changes set and the open `CR4IngameMenu`'s `OnOptionValueChanged` called as its Flash does (the preset: `OnPresetApplied('GMExpOptions', 0)`), then the menu closed (`game.py resume`: `SaveChangedSettings`, the change hook, the settings file saved). Then the options are read back, three rewards given through `GiveReward` and three spawned samples killed by a scripted hit through the damage manager (the game's `OnDeath`), with Geralt held at level 12 by a test override, and the quest-level tables read as the journal reads them; the expected values are legacy's rules worked by hand. The checks first ran on a throwaway build with the tests, the menu, the labels and the defaults but 5.x's code for the rest (the hooks off and 0, 5.x's `LoadQuestLevels`, no reload) and failed there: every case with an option set (e.g. −50%: Triss's reward +170 for 85, the griffin +14 for 7; fixed: the drowner +2 for 5; quest levels disabled or turned on again: all seven tables loaded; after a relaunch with everything at once stored: every effect missing, seven tables loaded; the regression's hooks check); the labels, the defaults, the preset's values and the values surviving a relaunch passed there, being the menu's and OPT's, and the unset check cannot fail there (5.x's behaviour is the defaults'); the throwaway build was then deleted. Launches loaded the test save and quit without saving; the settings file was backed up first and restored with the game closed; the saves were backed up before each launch; no autosave was written.

| Check | How | Classic tree | New tree |
|---|---|---|---|
| The defaults through the menu (case 0): Triss's reward 170, Olgierd's 300, the level-1 reward 5; the drowner 2, the griffin 14, the wolf 1 | scripted: the menu's events, `GiveReward`, kills through the damage manager (`gmtest_xp07_set`, `gmtest_xp07_check`) | 8 of 8 | 8 of 8 |
| Both modifiers at −100%: every reward and kill 0 (the log "Experience Points: 0") | scripted (as above) | 8 of 8 | 8 of 8 |
| −50%: 85, 150, 3; kills 1, 7, 1 | scripted | 8 of 8 | 8 of 8 |
| +50%: 255, 450, 8; kills 3, 21, 2 | scripted | 8 of 8 | 8 of 8 |
| +100%: 340, 600, 10; kills 4, 28, 2 | scripted | 8 of 8 | 8 of 8 |
| Fixed experience: 250, 200, 200; kills 5, 10, 1 | scripted | 8 of 8 | 8 of 8 |
| Quest levels disabled: 250, 200, 200; kills as the defaults; no quest-level table, no level for the Fistfight Championship, Ofieri's armor, `ww_belgard_secret` or the Wolf School set | scripted; tables read (`GMTestXpJournalLevel`) | 8 of 8 | 8 of 8 |
| Quest levels enabled again (legacy's gap): the defaults' experience; the base game's, Hearts of Stone's and Blood and Wine's tables back (30, 32, 38), the Wolf School set (dlc10's table) still without a level | scripted | 8 of 8 | 8 of 8 |
| Everything at once (quest levels disabled, fixed, quest +20%, combat −40%): 300, 240, 240; kills 3, 6, 1; no table | scripted | 8 of 8 | 8 of 8 |
| The "Default" preset from that state: the four options false, false, 0, 0 (legacy's table), the defaults' experience, the three tables reloaded (the gap again) | scripted: `OnPresetApplied` (`gmtest_xp07_preset`, `gmtest_xp07_preset_check`) | 9 of 9 | 9 of 9 |
| Unset options (cleared in memory): read "", the hooks off and 0, the defaults' experience; set back | scripted (`gmtest_xp07_unset`) | 11 of 11 | 11 of 11 |
| A relaunch with everything at once saved by the menu: the values read back, no table loaded at the load (the free DLCs' neither), the same experience; then the defaults saved by the menu and a relaunch: all seven tables back, the Wolf School set 21 | scripted: the menu, `game.py quit` and `run` (`gmtest_xp07_check(8, 1)`, then `(0, 0)`) | 8 of 8, 8 of 8 | 8 of 8, 8 of 8 |
| The 7 labels by key equal legacy's ids; the defaults; the hooks follow options set in memory (a level-10, 250-XP reward at Geralt 12 with quest levels disabled, fixed and +50%: 375) | scripted (`GMTest_xp07`, in the regression) | passed | passed |

The regression: `gmtest_regress()` 1,118 passed, 0 failed, and `gmtest_panel()` 139 passed, 0 failed, in each tree.

The group on screen and a change by hand: **verified** in the [cleared run](#cleared-run-on-screen-2026-11-01). Not doable from the test save: the journal's and the quest tracker's levels with quest levels disabled (its quests show no level either way).

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
| Port status | **verified** (slice X1, 2026-10-31, both trees, 5.x-GM `9e08f96a`); the new tree's Vitality is XP-09's (slice X5, verified) |
| Open checks | — |
| Save impact | none for the player: a loaded character's stored maximum Vitality (from 5.x's values) is recomputed at the load, and his level abilities, held by name, give legacy's values (verified on the level-20 test slot: 4,900 → 4,450) |
| NG+ counterpart | applied: legacy's values, past 50 nothing (as 5.x); untested |

**What it does** (changelist 472–473): each level from 2 to 50 adds 50 to Geralt's base Vitality and nothing else (2,450 by level 50). In 1.32 and 5.x a level adds 100 Vitality at first, falling to 80 by level 10, 60 by 11, 50 by 21, 30 by 30 and 25 from 40 (2,425 by 50), plus attack power (`add`, 4 falling to 1; 77 in all) and spell power (2% falling to 0.1%; 28% in all). NG+'s table names levels up to 100 in 1.32 and 5.x, but `Lvl51` to `Lvl100` are empty there (one misnamed `Lvl60`); legacy deleted them, with the same effect.

**Implementation (legacy):** `Lvl2`–`Lvl50` in `abilities/geralt_stats.xml` and `abilities_plus/` (NG+ `Lvl51`–`Lvl100` deleted, one of them misnamed `Lvl60` in 1.32); added at each level-up by `W3LevelManager.AddPoints` through `GetLevelupAbility`.

**5.x:** 1.32's (read in game on a build without the slice: from level 1 to 50 +2,425 maximum Vitality, attack power's additive part +77, spell power ×1.281).

**Decisions:** legacy's (PX10): +50 Vitality per level in the classic tree, no attack or spell power; NG+ as legacy (5.x's NG+ level abilities past 50 are already empty, so no entry). Porter's call (confirmed by the owner, 2026-10-31): a loaded save's stored maximum Vitality is recomputed once at the load, so a character from before the install gets legacy's level Vitality at once rather than at his next Vitality change (legacy asked for `cleardevelop` on existing characters); a new game is unaffected. In the new tree the Vitality follows XP-09's rule (DX1 (a), its deviation recorded there), since slice X5.

**Verification (slice X1, 2026-10-31, both trees; 5.x-GM `9e08f96a`; `tests/gmTestsXp.ws`, `tests/gmTestsXpData.ws`).** `gen_xp.py --verify`: 49 level abilities as legacy's in `abilities` and `abilities_plus`. Each check was first run on a throwaway build with the tests and 5.x's level abilities and failed there (138 level attributes; 40 Vitality steps and 49 attack and spell power steps of 59 level-ups; the loaded save's 1,400 Vitality and its attack and spell power), and the load check on the real build before the load recompute existed (4,900 stored, 4,450 recomputed); the throwaway build was then deleted. The tree was switched with the option and `gmreset()` and set back to the classic tree; no autosave was written.

| Check | How | Classic tree | New tree |
|---|---|---|---|
| `Lvl2` to `Lvl50` as the game reads them: 147 attributes, Vitality 50 each, 0 for 5.x's attack power and spell power | scripted: definitions read (`GMTest_xpdata`, in the regression) | passed | passed |
| 59 level-ups from 1 to 60 on the test save through the level manager's path (`AddPoints` with the experience the next level needs): +50 maximum Vitality on each level up to 50, none past 50; attack power and spell power unchanged by every level | scripted (`gmtest_xp08_levels(60)`) | 2 of 2 | 2 of 2 |
| A loaded level-20 Geralt (the test-only slot, saved with 5.x's level abilities): his maximum Vitality recomputed at the load (log: 4,900 → 4,450) and equal to what the definitions give; he holds `Lvl2` to `Lvl20`; they give 950 Vitality, no attack power, no spell power | scripted (`gmtest_xp08_parts()`, after a fresh launch into the slot) | 4 of 4 | 4 of 4 |
| A Vitality effect at the load (XP audit F4, 2026-10-31, 5.x-GM `c9133d5e`): Geralt at level 10 with Blood and Wine's "Well rested" (+500: 3,950 → 4,450) at 60% (2,670), saved into a new manual slot and loaded: when the recompute runs the effect and its ability are back (the effect manager and the abilities come from the save in `CActor.OnSpawned`, before the wrapper's code), so it finds the saved 4,450; after the load 4,450 and 2,670, the effect active. On a throwaway build whose recompute ran without the effect's ability (taken off and given back around it; deleted afterwards) it failed 1 of 6 (the maximum recomputed 4,450 → 3,950); the final values still came back, because the game keeps the Vitality percentage when an ability's Vitality is added | scripted (`gmtest_xp08_vit_a`, `_b(true)`, then after the load `_c`) | 6 of 6 | — (no tree involved: one save) |

Geralt on the test save (level 1: 3,500 maximum Vitality, attack power and spell power 0/1/0) before and after the slice, as levelled by the check above:

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
| Port status | **verified** by script (slice X5, 2026-10-31, both trees, 5.x-GM `201c25c3`) |
| Open checks | the HUD's level-up message and point indicator on a level reached by real experience (none showed on screen for levels given by `levelup()` and `addexp`); the standalone starts' points (compiles; not run). The character panel's points on a no-point level **verified** on screen in the new tree ([cleared run](#cleared-run-on-screen-2026-11-01), 2026-11-01) |
| Save impact | none on a new game. A new-tree character from before the slice keeps its points and level Vitality from the levels it already has (1 point and +50 each) until the character reset (`gmreset`), which gives it the new rule's; levels gained after the install follow the new rule at once (verified on the test-only slot) |
| NG+ counterpart | the same rule (DX2): the wrappers do not depend on NG+; untested |

**What it does** (the owner, 2026-10-11, [feature-mapping](../feature-mapping.md#progression), SKL's D59 revisit): the new tree's skills cost fewer points (3 levels, tiers ×3/5), so it earns fewer: on every third level Geralt gets no skill point, and the Vitality of those three levels comes all at once on that level. With DX1 (a): no point on levels 3, 6, …, 48, 150 Vitality on each of them, none on the others; 33 points from levels by level 50 instead of 49 (the classic tree), 2,400 Vitality instead of 2,450. A path's capstone then arrives at about 0.9 of legacy's level (SKL's estimate). Other sources (Places of Power, the acorn, the egg) stay as they are.

**Implementation (legacy):** none (one tree). 5.x: 1 point per level in both trees.

**Interactions:** the new tree's tier gates (5/12/18, 5/12/17, 4/11/17) arrive later in levels; MUT-01's research costs (29 skill points in both trees) take a larger share of the new tree's points; skill slots and skill mutagen slots unlock by level in both trees (SKL-01; the mutagen slots since slice X5, which found them still on 5.x's skill-point rule), so slots are not affected; the game's texts say one point per level (DX5).

**Decisions:** the owner's rule made exact by DX1 (a) and DX2 (a) (owner, 2026-10-31); the game's level texts stay as they are, a new-tree line on the Later list (DX5 (a)).
- **Deviation:** in the new tree levels 3, 6, 9, …, 48 give no skill point and +150 Vitality, and the other levels a point and no Vitality: 33 points and 2,400 Vitality from levels by level 50 (legacy, one tree: a point and +50 Vitality every level, 49 and 2,450). The new tree's skills cost fewer points (DX1 (a), owner, 2026-10-31)
- **Deviation:** past level 50 the new tree keeps the same pace, no skill point on every third level (51, 54, …), and no level past 50 gives Vitality, the third levels included; NG+ the same. Legacy's levels past 50 give a point every level and no Vitality (DX2 (a), owner, 2026-10-31)

Porter's calls of slice X5 (none is a deviation: legacy had one tree; each porter's call confirmed by the owner, 2026-10-31):
- **The rule follows the tree Geralt has, not the option alone.** A level-up uses the new tree's rule while the new tree's profile is in force (SKL-02's facts, set by the character reset), so changing the option changes nothing until `gmreset()`, which is when the tree itself changes. A character with no profile yet (a new game before its first load) follows the option. The alternative, the option read at each level-up: a level gained between the option change and the reset would follow the other tree's rule; the reset would still put it right.
- **A loaded save is not recomputed at the load.** A new-tree character from before the slice (level 20: 19 points from levels, `Lvl2` to `Lvl20`, 950 Vitality) keeps them as they are; its next level-ups follow the new rule, and `gmreset()` gives it the new rule for every level (13 points, 900 Vitality, the percentage kept). The alternative, recomputing at the load as XP-08's Vitality is: the level abilities could be swapped, but the 6 points too many cannot be taken back once spent without a reset; a forced reset at load would empty the character's skills unasked.
- **The level abilities record the rule.** Geralt holds one level ability per level, `Lvl<n>` (classic, to 50) or `GMLvlNew<n>` (new tree, to 100: the ones without Vitality and those past 50 are empty markers), and the reset reads them to tell the points from levels from the other sources (Places of Power, the acorn, the egg), so a character whose levels were gained under both rules (a save from before the slice, or a reset in between) comes out right. The alternative, a saved field: a change to the save format for the same result. No play effect.
- **The point is given and taken back.** `GainLevel` gives the level definitions' point as 5.x does, and the wrapper takes it back on a no-point level, so the HUD's point indicator may still light on those levels (not seen: in the cleared run the HUD showed nothing for scripted level-ups); the level-up texts stay (DX5 (a)). The alternative, a replaced `GainLevel` that gives no point there: a replaced 5.x method for a HUD detail.

**Verification (slice X5, 2026-10-31, both trees; 5.x-GM `201c25c3`; `tests/gmTestsXp09.ws`).** Level-ups go through the level manager's own path (`AddPoints` with the experience the next level needs: `GainLevel`, the level ability, the slot updates); after each level the test reads the skill points and maximum Vitality it added, the skill slots and the skill mutagen slots, against DX1 and DX2 worked by hand. The tree was switched with the option and `gmreset()` (`autoconfigset(GMGameplayOptions, GMClassicSkillTree, false)`), the Vitality set to a known percentage and points from another source added before each switch (`gmtest_xp09_prep`); the option was set back to the classic tree at the end. The checks first ran on a throwaway build with the tests on 5.x-GM `bacb86cc`'s code and failed there: the new tree +1 point on every third level and +50 Vitality on every level (14 and 30 of 40 level-ups from 20 to 60), the reset to the new tree at level 20 21 points (13 + 2 expected), `Lvl2` to `Lvl20` held and 950 Vitality, the mutagen slots by points (opened at level 3, 10 and 17 instead of 2, 9 and 16, the fourth at 27 with two other points), the 16 Vitality nodes of `GMLvlNew<n>` in the data check; the Place of Power check and the Vitality percentage passed there (5.x's behaviour is the expected one); the throwaway build was then deleted. Launches loaded the test save or the test-only slot and quit without saving; the later ones locked saves for the session (`gmtest_nosave`).

| Check | How | Classic tree | New tree |
|---|---|---|---|
| 59 level-ups from 1 to 60: each level's points (classic 1; new 0 on 3, 6, …, 60, else 1) and Vitality (classic +50 to 50; new +150 on 3 to 48, else 0; none past 50) | scripted: `AddPoints` (`gmtest_xp09_levels(60)`) | 3 of 3 (59 levels) | 3 of 3 (59 levels) |
| The totals from levels at 20, 50 and 60: classic 19 / 950, 49 / 2,450, 59 / 2,450; new 13 / 900, 33 / 2,400, 39 / 2,400 | scripted (as above) | 3 of 3 | 3 of 3 |
| Skill slots (SKL-01's levels) and skill mutagen slots (levels 2, 9, 16, 28) after every level-up | scripted (as above) | 59 of 59 levels | 59 of 59 levels |
| A tree switch by `gmreset()` at level 20 with 2 points from another source: to the new tree 15 free (13 + 2), `GMLvlNew2` to `GMLvlNew20` held and no `Lvl<n>`, 900 Vitality from levels, 60% Vitality kept (4,450 → 4,400); back to the classic tree 21 free (19 + 2), `Lvl2` to `Lvl20`, 950 | scripted: `gmreset()`, `gmtest_xp09_tree()` | 4 of 4 | 4 of 4 |
| The same at level 50 (after 30 level-ups in the new tree): classic 51 (49 + 2), 2,450 Vitality, 45% kept; new 35 (33 + 2), 2,400, 70% kept | scripted (as above) | 4 of 4 | 4 of 4 |
| At level 60 after a Place of Power: new 42 (39 + 3), 59 level abilities; classic 62 (59 + 3), 49 level abilities, 2,450 | scripted (as above) | 4 of 4 | 4 of 4 |
| A Place of Power (`place_of_power_quen.w2ent` spawned behind Geralt, set to its `PlaceOfPower_Activated` state, which grants the point) at level 60, a level that gives no point in the new tree: +1 | scripted (`gmtest_xp09_pop_a/b/c`) | — | 1 of 1 |
| A loaded save (the test-only slot, level 20, `Lvl2` to `Lvl20`, 19 points), its profile made the new tree's (`gmtest_xp09_asnew`, as a save from before the slice): at the load unchanged (19 points, 950 Vitality); level 21 then gives no point and +150 (`GMLvlNew21`); `gmreset()` gives 13 points, `GMLvlNew2` to `GMLvlNew21`, 1,050 Vitality, 80% kept | scripted (`gmtest_xp09_load`, `gmtest_xp09_levels(21)`, `gmtest_xp09_tree`) | as loaded: 19 points, `Lvl2`–`Lvl20`, XP-08's 4 of 4 (`gmtest_xp08_parts`) | 3 of 3 and 4 of 4 |
| `GMLvlNew2` to `GMLvlNew100` as the game reads them (150 on 3 to 48, else 0), with XP-08's and XP-05's data | scripted: definitions read (`GMTest_xpdata`, in the regression) | passed | passed |

The first switch at level 50 failed the Vitality percentage in both directions (100% for 60%): a test fault, not the code's: the level-ups between `gmtest_xp09_prep` and the switch heal Geralt fully (5.x's level-up heal), so the percentage was recorded too early; recorded again just before the switch, both passed. The regression: `gmtest_regress()` 1,118 passed, 0 failed, and `gmtest_panel()` 139 passed, 0 failed, in each tree (no expectation changed: the data check reads the 99 new abilities within its one check).

Geralt on the test save (level 1: 3,500 maximum Vitality, no points), levelled by the check above:

| Level | Classic tree: points from levels, level Vitality (maximum) | New tree: points from levels, level Vitality (maximum) |
|---|---|---|
| 10 | 9, 450 (3,950) | 6, 450 (3,950) |
| 20 | 19, 950 (4,450) | 13, 900 (4,400) |
| 30 | 29, 1,450 (4,950) | 19, 1,500 (5,000) |
| 50 | 49, 2,450 (5,950) | 33, 2,400 (5,900) |
| 60 | 59, 2,450 (5,950) | 39, 2,400 (5,900) |

The character panel on a no-point level: **verified** in the [cleared run](#cleared-run-on-screen-2026-11-01) (new tree, level 3: "Points available 1", the level-2 point only). Still open: the HUD's indicators on a level reached by real experience, a real Place of Power, the standalone starts.

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

**What it does:** debug only. Legacy's `resetLevels`, `fb1`, `fb2`, `fb3`, `resetme`, `addAllSkills` and the quest function `SetGeraltLevel` reset the character (legacy's respec) and set the level directly (`AddPoints` with the new `ignoreNGP`, no NG+ doubling) instead of raising it by adding experience; `cleanupInv` empties the inventory. The level-scaled gear they give is ITEM-02's (`addAutogenEquipment`, ported). 5.x's versions are 1.32's; SKL-01's `gmreset()` is the port's reset; `setlevel()` and the automation's own commands set the level for tests.

**Decisions:** not ported (PX11).

---

### Cleared run on screen (2026-11-01)

The first checks with the game in front and real input (5.x-GM `92548132`; the test save, Geralt level 1; nothing saved, `gmtest_nosave()` on).

| Check | How | Seen | Result |
|---|---|---|---|
| Options > Mods > Ghost Mode > Experience: "Experience Presets" with "Default"; "Disable quest levels" Off, "Fixed experience for quests and combat" Off, "Quest experience modifier" 0, "Combat experience modifier" 0 (XP-07) | real mouse: the pause menu, Settings, Mods, Ghost Mode, Experience | as listed; "Disable quest levels" switched to On with the arrow key, the menu closed, then set back to Off by hand | **verified** |
| A kill in a real fight (XP-04) | a level-1 wolf spawned hostile and locked on; Geralt's own light attacks (real left clicks) | the wolf died; experience 235 → 236 (+1, a wolf's base, at Geralt's level), seen in the menus' bar (236/1000). No combat log on screen: 5.x's HUD has none | **verified** (the combat log line: not shown by the game) |
| Locked-slot tooltips (XP audit F2), classic tree | real mouse over the character menu's locked slots | skill slots "Slot unlocked at level: 2" and "…: 6"; skill mutagen slot "Slot unlocked at level: 2" | **verified** |
| The same, new tree (`autoconfigset(…GMClassicSkillTree, false)`, `gmreset()`) | as above | skill slot "Slot unlocked at level: 2"; skill mutagen slot "Slot unlocked at level: 9" (slice X5's levels 2, 9, 16, 28) | **verified** |
| The new tree's no-point level (XP-09): level 2 by `levelup()`, level 3 by `addexp(1000)` | the character menu on screen | level 3, "Points available 1" (level 2's point; none for level 3); Vitality 3,500 → 3,650 (+150, read by script); the level-2 skill and mutagen slots open | **verified** (the panel); the HUD showed no level-up message or point indicator for either scripted level |
| The journal's levels with quest levels disabled and enabled (XP-03, XP-07) | the journal opened with J, both ways | Lilac and Gooseberries and Kaer Morhen show no level either way (both level 1) | not doable from the test save: needs a save with higher-level quests |

### XP audit (2026-10-31)

Done by a fresh session ([audit](../feature-mapping.md#audit-signing-a-feature-off)) on 5.x-GM `201c25c3` and master `26d27a4a`, reading code and data, with game runs in both trees on 2026-10-31. The five slices' commits (5.x-GM `9e08f96a`, `086aa4b3`, `9ce4fd30`, `bacb86cc`, `201c25c3`) were read whole. Every method they replace, wrap or add was read against legacy (`legacy-GM`), 1.32 (`master`) and 5.x (`vanilla-5.x`): `CR4Game.OnGiveReward` and `LoadQuestLevels`, `CNewNPC.CalculateExperiencePoints` and ENCH's `OnDeath` (its experience lines and `ShouldGiveExp`, which decides who earns a kill's experience), `CMonsterNestEntity.AddExp` and `AddBonusExp`, the three choice actions' `PerformAction`, `W3LevelManager.GainLevel` and `W3PlayerWitcher.GetLevelupAbility`, the load recompute in `W3PlayerWitcher.OnSpawned`, the character reset's level points and level-ability swap, `IsSkillMutagenSlotUnlocked` and the new character menu's `UpdateMutagens`, the options' hooks and change hook. Every 5.x caller of the code involved was listed: `AddPoints` (its level loop calls `GainLevel` and `GetLevelupAbility`; `GainLevel` calls `AddPoints(ESkillPoint)` and `OnLevelGained`), `GetLevelupAbility`'s other caller `Hack_EP2StandaloneLevelShrink`, `OnDeath`'s kill lines and 5.x's debug call with `skipLog` (`temp.ws`), the nest's `Explosion` state and `SetBossKilled`, `LoadQuestLevels` from the game's start and the DLC quest mounters, the readers of the quest-level tables (journal, quest HUD, `CanTrackQuest`), the reset `gmreset()`, the Potion of Clearance, the standalone starts, `NewGamePlusInitialize`, and the Places of Power, Imlerith's acorn and the golden egg (`AddPoints(ESkillPoint)`). Every other `AddPoints(EExperiencePoint)` in 5.x's scripts was read for paths that bypass the port.

**Data** was checked by scripts written for this audit, independently of `gen_xp.py` and `gen_loot.py`: every `<reward>` of the six reward files in `master`, `legacy-GM`, `vanilla-5.x` and `5.x-GM` (experience and level legacy's wherever legacy changed them from 1.32, else 5.x's; DX4's Killbill branch at 16; gold 5.x's), every row of the eight quest-level tables (5.x's with legacy's changes against 1.32), and the 49 `Lvl<n>` and 99 `GMLvlNew<n>` abilities in both folders.

**Checked and holding:**

**Data**
- **Rewards.** All 898 rewards of the six files as expected, none twice, none missing: experience 104,015 in all (legacy's 103,795 plus 5.x's four new rewards with experience, 220), finding Ciri 1,500 at level 24, gold 5.x's everywhere. `gen_xp.py --verify` and `gen_loot.py --verify` agree (629 rewards with experience or level other than 5.x's; 0 unexplained binary differences); `gen_xp.py --check` current.
- **Quest levels.** The four overridden tables equal 5.x's with legacy's changes (base game 294 rows, Hearts of Stone 25, Blood and Wine 78, the Wolf School gear's copy 7); the four tables legacy left (`dlc3`, `dlc12`, `dlc15`, dlc10's `quest_levels_th1009th.csv`) are 5.x's; no row twice in a table; spot checks: the Courier 12, `mq2040_trial_of_power` gone, `mq1060_devils_pit` 15, the Wolf School set 21/24/24/28/28.
- **Level abilities.** `Lvl2` to `Lvl50` +50 Vitality each and nothing else, `GMLvlNew3` to `GMLvlNew48` (every third) +150, the others only the `base` tag, in `abilities` and `abilities_plus` alike.
- **The kill table.** `GMGetExpByEnemyType` equals legacy's `GetExpByEnemyType` for all 70 enemy types (compared by script); the diminishing returns equal legacy's `GetExpModifierByEnemyType`.
- **The menu group** equals legacy's `modSignsConfig.xml` group line by line (ids, sliders, the "Default" preset's four entries).

**Code**
- **Quest experience.** `GMQuestExperience` is legacy's block line for line (the modifier, NG+'s level, "Disable quest levels", "Fixed experience", `RoundMath`, the 5 XP minimum, the quest modifier after it); the rest of `OnGiveReward` is 5.x's.
- **Kill experience.** `CalculateExperiencePoints` is legacy's body but for three marked points (the NG+ level taken off a local copy, a porter's call of slice X3; the kill counted only without `skipLog`, UI-10's rule; the guard counted the same way); `OnDeath`'s lines are legacy's (gear bonus, `expGlobalMod_kills`, the 1 XP minimum, the combat modifier after it, the combat log line). 1.32's and 5.x's experience block in `OnDeath` and their `CalculateExperiencePoints` are identical, so nothing of 5.x's was lost there.
- **Nests and choices** equal legacy's values; the Axii choice reads `GetAxiiLevel`, which reads Delusion (`magic_s17`), the skill both trees share.
- **Options.** The hooks read legacy's ids; `LoadQuestLevels` and the reload equal legacy's `LoadQuestLevels` and `gmUserSettingsQuestLevels`; the change hook runs from `SaveChangedSettings` for the option and the preset, as legacy's.
- **Level-ups.** `GainLevel`'s wrapper takes back only the point the level definitions gave, only on a no-point level and only while the new tree's rule is in force; `GetLevelupAbility`'s wrapper names `GMLvlNew<n>` only then; the reset counts the points each level gave by the level ability held for it, so Places of Power, the acorn and the egg (all `AddPoints(ESkillPoint)`, never `GainLevel`) stay outside the rule in both trees; the Potion of Clearance moves points only (no tree change, no recompute). The mutagen slots by level: both 5.x readers of the points rule are replaced (`IsSkillMutagenSlotUnlocked` and the new menu's `UpdateMutagens`; 5.x's classic menu already reads the level and is not used).
- **Paths outside the port** (all legacy's too, none changed by legacy): the collectible places (`W3CollectiblePlaces`, their entity's `xpPoints`), the tutorial's reward function (50 XP), the quest and debug level functions (`BoostPlayerLevel`, `SetGeraltLevel`, `SetGeraltLevelHandsOn`; XP-10's, not ported), `NewGamePlusInitialize`'s levels to 30. They add experience without XP-07's modifiers or the level rule, as in legacy.
- **Tests' expected values** were worked again from legacy's code, not the port's: every value of `gmtest_xp01`, `gmtest_xp04`, the XP-07 cases and XP-06's; all hold (e.g. Killbill's branch at Geralt 17: 50 × 0.84 = 42; a griffin 3 levels up 10 × 1.48 = 14.8 → 14; −50% on the level-1 reward 5 × 0.5 = 2.5 → 3 by `RoundMath`).

**Tool checks:** `check_modsigns.py` 502 bodies, 0 unmarked, 0 native wraps; `unit_sweep.py --unattributed` for `experience`, `EExperiencePoint`, `AddPoints`, `GetLevel()`, `ShouldGiveExp`, `quest_levels`, `LevelUp`, `ESkillPoint`, `exp_bonus`, `addedSkillPoints`: only what xp.md already hands off (the 31 gold-only rewards to ECON, the 44 trophy abilities to TRPH, the debug command `whoareyou`).

**In game** (scripted through exec calls; no real input, no screen; a throwaway build with this audit's probes, `tests/gmTestsXpAudit.ws`, deleted afterwards and 5.x-GM `201c25c3`'s build reinstalled; the test save, saves locked with `gmtest_nosave()`):

| Check | How | Classic tree | New tree |
|---|---|---|---|
| Who earns a kill's experience (F1): Geralt at level 10, four drowners at his level (no earlier drowner kills), each made hostile and killed by a scripted hit through the damage manager (`OnDeath`): by Geralt 10 m away +5 XP, counted; by a friendly renegade 6 m away +5, counted; by a friendly Novigrad guard (guard group type) 8 m away +5, counted; by the friendly renegade 45 m away +0, not counted. Legacy's (1.32's) rule gives the two ally kills nothing | scripted (`gmaudit_xp_spawn`, `gmaudit_xp_kill`) | F1 seen | — (no tree involved) |
| The new menu's locked-slot text (F2): `skill_slot_unlock_description` with 28 reads "Unlocked at 28 Ability Points acquired."; 1.32's `panel_character_tooltip_mutagen_locked_desc` reads "Slot unlocked at level" | scripted string reads (`gmaudit_xp_kill`) | F2 seen | — |

**Regression** (5.x-GM `201c25c3`, `god()` off, `exec --wait 6000 "gmtest_regress()" "ingamemenu()" "gmtest_panel()"`): `gmtest_regress()` 1,118 passed, 0 failed, and `gmtest_panel()` 139 passed, 0 failed, in each tree (the new tree by the option and `gmreset()`, then set back to the classic tree).

**Findings:**

1. **Kills by friendly NPCs near Geralt give him experience and use up his kill counts** (medium; owner decision).
   - Who earns a kill's experience is decided by `CNewNPC.ShouldGiveExp`, which the port keeps as 5.x's. 5.x added a branch: a kill by any NPC friendly to Geralt within 30 m of him gives Geralt the experience, guards included. 1.32 and legacy (legacy left the function as 1.32's) give it only for Geralt's own kills, and within 20 m for kills by something that is not an actor (a trap, the environment) or by a party companion or an NPC under Axii; never for a guard's kill. xp.md's "What 5.x did" missed the change, so it is neither ported nor recorded as a deviation.
   - Play effect: in fights alongside allies (city guards, soldiers in battles, the Kaer Morhen defenders, Roche's men) every enemy an ally kills near Geralt gives him the full kill experience and counts as his kill of that type, so his own later kills of the type give less (legacy's diminishing returns are per type, 1% per kill). Example (seen in game): Geralt at level 10, a guard kills a drowner 8 m away: Geralt +5 XP and one drowner kill more; in legacy +0 and no kill. A battle where allies kill 30 humans near Geralt costs him 30% of every later human kill's experience. Allies also fill the bestiary's kill counts (UI-10).
   - Options: (a) legacy's (1.32's) rule: `@replaceMethod(CNewNPC) ShouldGiveExp` with 1.32's body (5.x's friendly branch removed), so only Geralt's kills, party companions' and Axii'd NPCs' within 20 m and non-actor kills count; (b) keep 5.x's rule and record it as a deviation (allies' kills within 30 m count, guards' too). Recommendation: **(a)**, legacy behaviour first: legacy's experience rules count Geralt's own kills, and 5.x's branch also undoes 1.32's exclusion of guards' kills.
   - Tested: scripted, classic tree (no tree involved); legacy's side by reading 1.32's `ShouldGiveExp`, which legacy keeps.
2. **The new character menu says locked slots unlock at a number of Ability Points; they unlock at a level** (low; clear fix, SKL-01's).
   - Since SKL-01 (skill slots) and slice X5 (skill mutagen slots) the slots open by Geralt's level, as legacy. The new character menu, which both trees use, still builds the locked slot's tooltip from 5.x's `skill_slot_unlock_description`, "Unlocked at $I$ Ability Points acquired.", in `CR4CharacterDupeMenu.OnGetLockedTooltipData` and `OnGetMutagenLockedTooltipData`, filled with the slot's unlock level.
   - Play effect: a locked slot's tooltip names a number of Ability Points that is really a level. In the new tree the two differ most (XP-09): at level 20 with 13 points from levels, the fourth mutagen slot says "Unlocked at 28 Ability Points acquired."; it opens at level 28, with 19 points from levels. A player saving points or counting Places of Power is misled in both trees.
   - Fix: wrap the two events to give 1.32's and legacy's text instead, "Slot unlocked at level: N" (`panel_character_tooltip_skill_locked_desc` and `panel_character_tooltip_mutagen_locked_desc`, 1070951 and 1070952, in every language of the game; the classic menu's format). No new strings. Not a deviation (legacy's menu text); the tooltip on screen **verified** in both trees ([cleared run](#cleared-run-on-screen-2026-11-01)).
   - Tested: the strings read in game (scripted); the menu code by reading.
3. **Porter's calls waiting for the owner's confirmation** (no play effect or legacy's; owner decision).
   - XP-08 (slice X1): a loaded save's maximum Vitality is recomputed once at the load.
   - XP-04 (slice X3): the plague victims count as humans; the red-plague creature is a contract monster and a boss; Reinald keeps 5.x's no-experience flag; NG+'s level is taken off a local copy of the enemy's level.
   - XP-07 (slice X4): the defaults written to the settings file when unset; the labels' keys as names.
   - XP-09 (slice X5): the rule follows the tree profile in force, not the option alone; a loaded save is not recomputed at the load; the level abilities record the rule; the point is given and taken back in `GainLevel`.
   - SKL-01 (slice X5): the skill mutagen slots unlock by level (2, 9, 16, 28), legacy's rule extending the owner's rule for skill slots.
   - Recommendation: confirm all; each follows legacy or has no play effect, and each entry gives its alternative.
4. **Gaps in the tests** (low, test-only; clear fix).
   - No check covers who earns a kill's experience: every kill check uses Geralt as the attacker, so F1 passed unseen. Fix: after F1's decision, a check with the four kills above (Geralt's, an ally's and a guard's near him, an ally's far away), shown failing on a throwaway build without the fix.
   - The load recompute (XP-08) is checked only on a save without a Vitality effect active; whether an effect that raises maximum Vitality (e.g. Blood and Wine's "Well rested") is back in place when `OnSpawned` recomputes is not known: if it comes back later, Geralt would load with less Vitality than he saved with. Fix: a check on the test-only slot saved with such an effect, the Vitality percentage compared before the save and after the load.
5. **Doc corrections** (doc-only; clear fix).
   - xp.md's "What 5.x did" and XP-04's "What it does" and "5.x" paragraphs: 5.x's `ShouldGiveExp` change (F1), and who earns a kill's experience in legacy.
   - XP-03's "What it does": a contract can be tracked when Geralt is at most 5 levels below its level (`CanTrackQuest`: Geralt's level ≥ the quest's − 5), not "at least 5 levels below".
   - XP-04's type list: unidentified creatures and animals have a base of 0 but still give the 1 XP minimum; the list's "none" reads as no experience.
   - features/README.md: the "Updated" line and XP's row in the area table still stopped at slice X4 (corrected with this audit).
6. **Not verified in game** (no action; open checks kept in the entries).
   - Seen on screen in the [cleared run](#cleared-run-on-screen-2026-11-01) (2026-11-01, real input): a kill in a real fight; the Experience group in the menu and a change by hand; the new tree's character panel on a level that gives no point; the locked-slot tooltips (F2) in both trees. The combat log line: 5.x's HUD shows no combat log.
   - Still open (each needs a save at that point in the story, or real experience): a nest blown up with a real bomb; a payment and an Axii choice in a real dialogue; the journal's and the quest tracker's levels, also with quest levels disabled; the HUD's level-up indicators on a level from real experience; a real Place of Power.
   - Not run: the standalone starts' points (compiles only); "Disable quest levels" changed from the main menu before a load; the load recompute with a Vitality effect active (F4; run since, [close-out](#xp-audit-close-out)).
   - NG+, beyond DX3's scripted kill: quest experience on base-game levels (XP-01), the level abilities past 50 (XP-08), the new tree's rule in NG+ (XP-09, DX2), `NewGamePlusInitialize`'s levels to 30 through `GainLevel` under that rule, and whether SKL-02's profile facts exist in NG+ when those levels are gained (the rule falls back to the option without them).

**Autosave:** none written: the newest save after every run was an earlier session's `<save name>` (17:33). The live save folder holds the 1,074 saves it held at the start; the backup's one extra save, `<save name>`, was removed by an earlier session's autosave rotation (recorded in game-automation.md), not by this audit. The test save `<save name>` and the test-only slot were not saved over. The user settings were restored with the game closed (no scaling or experience group; the classic tree, sign cooldown 5, armour regen penalty off, combat stamina regen 5, difficulty 3).

**Not reviewed:** legacy's own behaviour in play; NG+ in game.

**Suggested fix slices:**
- **C** (code and tests): F1 once decided, F2, F4.
- **W** (docs): F5's xp.md corrections.
- **O** (owner): F1's decision and F3's confirmations.

#### XP audit close-out

**Closed 2026-10-31** (5.x-GM `c9133d5e`): the owner decided F1 (a) and confirmed every porter's call of F3 ("all as recommended"); F1, F2 and F4 made and verified by script in both trees, F5's corrections made; F6 stays as the entries' open checks.

| Finding | Outcome | How tested |
|---|---|---|
| F1 Kills by friendly NPCs near Geralt | **fixed** (owner: option (a), 2026-10-31): `@replaceMethod(CNewNPC) ShouldGiveExp` with 1.32's and legacy's rule (`xp/killEarner.ws`: 5.x's body without its friendly-NPC branch); Geralt earns his own kills and, within 20 m, a non-actor's, a party companion's or an Axii'd NPC's, never a guard's; allies' kills no longer use up his kill counts. Legacy's rule, so not a deviation ([XP-04](#xp-04-kill-experience)) | scripted kills, both trees (F4's check, below) |
| F2 Locked-slot tooltips | **fixed**: the new character menu's locked skill and skill mutagen slots say "Slot unlocked at level: N" (1.32's and legacy's 1070951 and 1070952), not 5.x's Ability Points text ([skl.md](skl.md#skl-01-skill-system-rules)'s SKL-01). Not a deviation | scripted, both trees; on screen in both trees ([cleared run](#cleared-run-on-screen-2026-11-01)) |
| F3 Porter's calls | **confirmed** by the owner (2026-10-31): XP-08's load recompute; XP-04's plague victims as humans, the red-plague creature as a contract monster and boss, Reinald without experience, NG+'s level on a local copy; XP-07's defaults written and the labels' keys as names; XP-09's rule by the tree in force, no recompute at a load, the level abilities as the record, the point given and taken back; SKL-01's mutagen slots by level. Each entry now says so | — |
| F4 Test gaps | **fixed**: who earns a kill's experience (in the regression since F1's fix); the load recompute with a Vitality effect active | below |
| F5 Doc corrections | **corrected**: "What 5.x did", XP-04's "What it does" and "5.x" (`ShouldGiveExp`, who earns a kill in legacy); XP-03's tracking rule ("at most 5 levels below"); XP-04's type list (animals and unidentified creatures give the 1 XP minimum); features/README.md (with the audit) | read |
| F6 Not verified in game | **kept** as the entries' open checks: real fights and the combat log on screen, a real bomb, real dialogue choices, the Experience menu group by hand, the journal's and tracker's levels, the new tree's level-up on screen, a real Place of Power, the locked-slot tooltips on screen, the standalone starts, "Disable quest levels" from the main menu, NG+ beyond DX3's scripted kill | — |

**F4's checks** (`tests/gmTestsXpAuditChecks.ws`):
- **Who earns a kill's experience** (`GMTest_xp04_who_spawn(false)` in `gmtest_regress()`, `GMTest_xp04_who_after()` in `gmtest_panel()`; standalone at Geralt 10 `gmtest_xp04_who_spawn()`, `gmtest_xp04_who()`): four drowners at Geralt's level at 10, 6, 8 and 45 m behind him, killed through the damage manager by Geralt, a friendly renegade, a friendly Novigrad guard (guard group type) and the renegade: +5 counted, then +0 and no kill three times; the experience and counts put back. 6 of 6 in each tree, in the panel and standalone. Before F1's fix (the real build of 5.x-GM `201c25c3`'s rule, then a throwaway build without `xp/killEarner.ws`) 4 of 6: the renegade's kill 6 m away and the guard's 8.4 m away gave Geralt +5 and a drowner kill each.
- **Vitality at the load** (`gmtest_xp08_vit_a`, `_b(true)`, `_c`): Blood and Wine's "Well rested" on Geralt (level 10; +500, 3,950 → 4,450; its base effect adds the ability), Vitality at 60%, saved into a new manual slot and loaded. The effect manager and Geralt's abilities come back from the save in `CActor.OnSpawned`, before XP-08's wrapper recomputes, so the recompute finds the saved maximum (`GMRecomputeVitalityAtLoad` returns whether the maximum changed: no) and Geralt loads with 4,450 and 2,670, the effect active: 6 of 6. No fix needed. On a throwaway build whose recompute ran without the effect's ability it failed 1 of 6 (4,450 → 3,950 in the recompute); the final values still matched, as the game keeps the percentage when an ability's Vitality comes back.
- **The tooltips** (`gmtest_skl01_tooltip`, the menu opened with `dupemenu()`): 4 of 4 in each tree; on the throwaway build without the wrappers 2 of 4 (no text set).
- The throwaway build (the three guarded pieces of code taken out, the tests kept) was deleted and the real build reinstalled.

**Regression** (5.x-GM `c9133d5e`, `god()` off, `exec --wait 6000 "gmtest_regress()" "ingamemenu()" "gmtest_panel()"`): `gmtest_regress()` 1,118 passed, 0 failed, and `gmtest_panel()` 145 passed, 0 failed (139 and the six kill-earner checks), in each tree (the new tree by the option and `gmreset()`, then set back to the classic tree).

**Saves:** one new manual slot, `<save name>` (Geralt at level 10 with "Well rested" at 60%, the test's `gmtest_xp08v_*` facts), saved with the session's no-save lock lifted for that one save; the save count went from 509 to 510 with no autosave rotation (a new manual slot rotates none). Its name holds the test-only slot's key `7ea4f800` too: pass the slot's longer key `7ea4f800_2f8df1f` to `gmtest_diff04_lsave_save`. No autosave written; the test save and the test-only slot `<save name>` not saved over. The live folder lacks only `<save name>`, removed by an earlier session's rotation. The user settings were restored with the game closed (no scaling or experience group; the classic tree, sign cooldown 5, armour regen penalty off, combat stamina regen 5, difficulty 3).

**Deviations:** none new: F1 and F2 restore legacy's behaviour.

---

### Dependencies on other areas

- **Done areas XP builds on:** UI-10 (kill counter, enemy types), AI-01 and DIFF-04 (enemy levels), ENCH (the replaced `OnDeath`), ALCH-14 (the replaced nest method), LOOT-07 (the reward overrides and `gen_loot.py`), SKL-01 and SKL-02 (the reset, per-tree points, the tree option), OPT-01 (the menu).
- **Areas XP shares with or waits for:** ECON (the same rewards' gold), TRPH (the trophies' experience bonuses), GEN (the changelist puts the level-up Vitality under "General player abilities"; XP-08 takes it, with XP-09).

### Hand-offs received

| From | Item | XP |
|---|---|---|
| DIFF (DIFF-08, PD7) | Experience independent of the mode (`CalculateExperiencePoints`, `OnGiveReward`); the "Experience" option group | XP-01, XP-04; XP-07 |
| AI (hand-off, AI-A audit F5) | `CalculateExperiencePoints`, `GetExpByEnemyType`, `GetEnemyTypeByAbility`, the `experience` nodes (`LATER`); DA4's thresholds already move 5.x's quest cut-off and kill bonuses | XP-04, XP-05; XP-01 and XP-04 replace the code that read the thresholds. AI's note that XP reads `CActor.IsBeast` is wrong: only DIFF-04 does (corrected in ai.md) |
| UI (UI-10, DU6) | `CalculateExperiencePoints` (the counting place), `GetExpByEnemyType`, `GetExpModifierByEnemyType`; the counter shared | XP-04 (PX5) |
| DMG (hand-off) | Experience no longer from attack power and armor | XP-04 |
| LOOT, CRAFT (hand-offs) | The rewards' experience (547) and levels (193) | XP-02 (630 rewards) |
| ENCH, FOOD, MUT, XBOW (sweeps) | `q702_03b_wight_disenchanted`'s experience; rewards naming food; an XP reward; Crach's reward's level and experience | XP-02 |
| ALCH (hand-off, audit F26) | Nest experience (`AddExp`, `AddBonusExp`, the fields); `fb3_internal` | XP-06; XP-10 |
| ITEM (hand-off) | The debug level reset (`fb1`, `fb2`, `fb3_internal`, `resetLevels`, `resetLevels_internal`, `cleanupInv`, `SetGeraltLevel`, `resetme`) | XP-10 |
| SKL (D59 revisit, the income rule), balance.md (B10), feature-mapping (progression) | The new tree's skill-point income and Vitality per level; its levels and tier points examined with it | XP-09 (DX1, DX2); the tiers stay as decided |

**Temporary deviations "until XP"** ([deviations.md](deviations.md)): none recorded; the `LATER` experience nodes in AI's abilities are legacy's since slice X1 (XP-05); the rewards' experience and levels in LOOT's overrides are legacy's since slice X2 (XP-02).

### Hand-off to other areas

| Area | Changes |
|---|---|
| TRPH | The trophies' XP bonuses removed (44 trophy abilities with their other changes, unattributed) |
| ECON | 31 rewards whose only change is gold; every reward's gold; the Vivaldi bank payment (`vimme_vivaldi_default.w2scene`), the Hearts of Stone taxes (`mq6003_taxes.w2phase`); the `mh307` contract's reward name in two scenes (or FIX) |

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
| PX1 | XP is ported as one area with one audit at the end, about 990 units, in the slices of the [port order](#port-order) |
| PX2 | XP-02: `gen_loot.py`'s reward overrides take legacy's `experience` and `level` for XP-02's units (gold 5.x's until ECON; legacy's since ECON's slice E4), and the two free-DLC files legacy changed without items (`dlc12`, `dlc15`) get overrides of their own |
| PX3 | XP-03: whole-file overrides of the four quest-level tables (DT1's form): 5.x's tables with legacy's 89 rows, 5.x's `mq1060_devils_pit` kept, legacy's removal of `mq2040_trial_of_power` kept (its journal entry shows no level) |
| PX4 | XP-01: legacy's rule replaces `OnGiveReward`'s experience block (no difficulty multipliers, no post-game halving, Hearts of Stone no longer special); the rest of 5.x's body kept |
| PX5 | XP-04: legacy's `CalculateExperiencePoints` with UI-10's counting folded in, so each kill is counted once and the diminishing returns read the count before the kill, as legacy (the first drowner gives 100%); UI-10's wrapper is removed; the debug log's call with `skipLog` counts nothing (UI-10's rule) |
| PX6 | XP-04: the combat log line "Experience Points: N" for each kill, as legacy |
| PX7 | XP-05: legacy's `experience` nodes in AI's abilities, which nothing reads (checked by script in the slice) |
| PX8 | XP-06: nests 25 XP once and 25 for the boss, dialogue payments and Axii choices 5 XP, as legacy, in replaced methods without legacy's new fields |
| PX9 | XP-07: legacy's group, ids, labels (2110992253, 270, 271, 300, 328, 451, 452), sliders and "Default" preset in OPT's framework; untouched options read off and 0 (legacy's and the preset's); "Disable quest levels" turned off in the menu reloads only the base game's, Hearts of Stone's and Blood and Wine's levels until the next load, as legacy |
| PX10 | XP-08: legacy's 50 Vitality per level and no attack or spell power in the classic tree; NG+ as legacy (its regular values; 5.x's `Lvl51`–`Lvl100` are already empty, found in slice X1, so nothing to empty) |
| PX11 | XP-10: the debug commands are not ported (debug only; `gmreset()` and the test commands do their work) |
| PX12 | NG+: XP-01 and XP-04 as legacy's code (DX3), XP-08 as PX10, XP-09 as DX2; untested |

### Port order

Each slice compiles and is verified on its own in both trees (the regression in both; XP-08 and XP-09 also by level-ups in each tree). One audit after the last (PX1).

| # | Slice | Verified by |
|---|---|---|
| X1 | **Done** (5.x-GM `9e08f96a`, 2026-10-31). XP-08 and XP-05: `tools/gen_xp.py` (`--check`, `--verify`, a data test) with the 49 level abilities (NG+ by `gen_ngplus.py`); `gen_ai.py` with XP in `PORTED` | Definitions read; level-ups by script (`AddPoints`) from 1 to 20: +50 base Vitality each, no attack or spell power, in both trees (the new tree's Vitality waits for X5); an NPC's `experience` read and a kill's experience unchanged |
| X2 | **Done** (5.x-GM `086aa4b3`, 2026-10-31). XP-01, XP-02, XP-03: `OnGiveReward` (`xp/questExperience.ws`, XP-07's hooks in `xp/expOptions.ws`); `gen_loot.py` with legacy's experience and levels (six files, DX4's Killbill branch); the quest-level overrides from `gen_xp.py`; the data test `tests/gmTestsXpQuestData.ws` | Rewards given through `GiveReward` at several Geralt levels and modes (the formula, the 5 XP floor, no mode effect, Hearts of Stone like the rest); quest levels read in the journal's tables |
| X3 | **Done** (5.x-GM `9ce4fd30`, 2026-10-31). XP-04, XP-06: `CalculateExperiencePoints` (`xp/killExperience.ws`, UI-10's wrapper folded in), the type table and diminishing returns, the `OnDeath` lines; nests and dialogue choices (`xp/otherExperience.ws`) | Scripted kills of spawned enemies through the damage manager (drowners, a wolf, a bandit, griffins, a contract monster, a boss, a guard, 5.x's new enemies, NG+), scripted kill counts at 0, 40, 50 and 100, the combat log line; a nest blown up through its own state, its boss; the choice actions' own `PerformAction`. A real kill seen in the cleared run (2026-11-01); a real bomb needs a save at a nest |
| X4 | **Done** (5.x-GM `bacb86cc`, 2026-10-31). XP-07: the options group, `LoadQuestLevels`, the reload (`xp/expOptions.ws`, `options/gmOptions.ws`), the labels | Each option by script through the menu's code path (a reward and a kill under each), quest levels cleared and restored; the menu on screen and a change by hand in the cleared run (2026-11-01) |
| X5 | **Done** (5.x-GM `201c25c3`, 2026-10-31). XP-09: `xp/levelUp.ws` (the point withheld in `GainLevel`, `GetLevelupAbility`'s `GMLvlNew<n>`), the level abilities from `gen_xp.py`, `GMGetLevelSkillPoints` and the reset's swap; SKL-01's mutagen slots by level | Level-ups 1 to 60 in each tree by script (points, Vitality, skill and mutagen slots), the totals at 20, 50 and 60, a tree switch through `gmreset()` both ways at 20, 50 and 60, a Place of Power, a loaded save |

**Generator work:** `tools/gen_xp.py`: legacy's `Lvl` entries whole, `replace` (X1); the quest-level overrides and the rewards' independent check (X2); the new tree's `GMLvlNew<n>` from DX1 and DX2 and `xp/levelNames.ws` (X5); `--check`, `--verify`. `gen_loot.py`'s reward merge takes the two attributes for XP-02 units, with the two files (X2); `gen_ai.py`'s `PORTED` has XP (X1); `gen_ngplus.py` after.

**Later:** NG+ kill experience on the base game's levels (DX3 (b)); a new-tree line in the level texts (DX5 (b)); the free DLCs' quest levels reloaded with the others when "Disable quest levels" is turned off.
