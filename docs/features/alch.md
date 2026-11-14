# ALCH: alchemy (potions, decoctions, bombs, oils, toxicity)

Everything Geralt brews and uses: the toxicity bar and overdose, potions and how they combine, the 28 mutagen decoctions, bombs, blade oils, and their tooltips and descriptions. Ghost Mode reworked all of it so that "alchemy is now vital on higher difficulties to buff your character in combat and/or control groups of enemies" (changelist 674–679): potions stack instead of being replaced and are cheaper in toxicity, decoctions were all reworked ("some retain the vanilla idea behind their effect, some were redone from scratch, because they were useless", 773–775) and all cost 70 toxicity, bombs got fixed damage that "never scales with anything" and clearer roles (695–729), oils got crit chance and crit damage at higher tiers (585–589 with the Wolven set), and the overdose threshold is a fixed 75% (384–386). Sources: the changelist's Alchemy section (674–835), the skills paragraph on toxicity (384–386), the bugfix list (lines 62–186: decoctions and overdose, White Raffard, White Honey, Swallow and Tawny Owl regen, Blizzard, Northern Wind, oils stuck on swords, pheromone and Pops' Antidote sounds), and the code, which has more than the changelist (Golden Oriole's level 3, Dimeritium's mechanics, the decoction details below).

Alchemy is a large part of every build's power: balance it with [balance.md](balance.md) (rules B9 "alchemy effects stay where they are" and the overdose row) and the [alchemy ledger](ledger/alchemy.md), which tabulates every potion and decoction in 1.32, legacy and 5.x, the access timing of formulas and mutagens, the toxicity system and the build cornerstones.

**What 5.x did in this area** (from `vanilla-5.x`, unverified in game). The overdose threshold fell from 75% to 50% (`TOXICITY_DAMAGE_THRESHOLD` 0.50001), toxicity decays ×1.1 out of combat (1.32: ×2), and the toxicity head effects were rebuilt in five steps. Decoctions lock 50 toxicity instead of 70 (Basilisk keeps 40 and its long duration); Katakan +10% crit (1.32: 5%), Grave Hag +10 regen per kill (5), Leshen 10 + 10% returned (2%), Werewolf adds stamina regen at night in clear weather, Forktail counts light and heavy attacks as separate actions, Reliever's blocks a specter's shadow form on any hit. Potions: Blizzard reworked into a continuous, weaker slow motion in combat (8/10/12 s, time ×0.8/0.7/0.6, not after kills), Cat gains +5/7/10% crit chance, toxicity changed on Black Blood and Golden Oriole (25), Killer Whale (15), Blizzard (20), White Raffard (25); White Honey also clears the locked decoction toxicity; Reinald's Philtre added (a quest potion, `mq1060`). Bombs: Grapeshot 250/450/450 (1.32: 350/600/600), Dragon's Dream 250/300/300 and its explosion 15 (300/400/400, 20), Dimeritium also blocks `ablMagic`, Silver Dust blocks six more monster abilities directly, Northern Wind blocks `PoisonDeath`; **potion duration bonuses now raise bomb damage** (impact and damage over time; new in 5.x). Oils: a silver tag on three oils. Skills that feed alchemy changed too (SKL-13 to SKL-17, ported as legacy).

**How legacy Ghost Mode implements it.** Data: `def_item_alchemy_potion.xml` (toxicity, duration, charges), `effects_potions.xml` (potion effects), `def_item_alchemy_mutagens.xml` and `effects_mutagens.xml` (decoctions), `def_item_alchemy_petards.xml` and the bomb effects in `effects.xml`, `def_item_alchemy_oils.xml`, all with NG+ copies; 49 rows of `tooltip_settings.csv`; about 120 description strings in 9 languages. Scripts: the toxicity effect (`toxicity.ws`), the potion effects (`effects/potion/*.ws`), one script per decoction (`effects/mutagens/mutagenNN.ws`, most rewritten), hooks for the decoctions in the player, damage, stamina and sign code, a new `W3Effect_DimeritiumEffect`, the bomb and potion tooltips in `inventoryComponent.ws`, and the oil removal on item transfer.

Unit lists: [attribution.csv](attribution.csv), mapped from the changelist, the other areas' hand-offs and sweeps (a field-by-field comparison of every unit in the alchemy item and effect files in 1.32, legacy and 5.x): 2,017 units carry an ALCH feature (272 script units, 182 XML units and their 212 NG+ copies, 1 binary file, 45 tooltip rows, 1,305 string rows: 145 strings × 9 languages); 68 of the script units are shared with other features (DMG, SKL, STAM, MUT, ARM, ENCH hold the functions; ALCH adds its terms). Units whose only change is a weight, price, recipe ingredient or loot entry are WGT's, ECON's, CRAFT's and LOOT's.

**Status:** ALCH-01 to ALCH-18 **ported** and verified in both trees (twelve slices, 2026-10-20); the [area decisions](#area-decisions) made and every deviation confirmed by the owner (2026-10-20). Signed off by the owner (2026-10-20). What stays open: the open checks in the entries (real fights, kills, bombs and oils in play, the tooltips and menus on screen, the strings in the other eight languages, NG+).

## Scope

**ALCH covers** toxicity and overdose; the rules every potion follows (stacking, when Geralt can drink, durations); every potion's values and special effects; the decoction rules (toxicity offset, duration) and all 28 decoctions; bombs' values and effects, including Dimeritium and Silver Dust; oils' values, their tooltip rows and the stuck-oil fix; the alchemy tooltips and descriptions; the alchemy debug commands.

**Not ALCH** (DL8):

| Subject | Area | Why |
|---|---|---|
| The alchemy skills (Brewing, Oil Preparation, Bomb Creation, Mutation, Trial of the Grasses) and the alchemy perks (Metabolism Boost, Metabolic Control, Advanced Pyrotechnics, In Combat's Fires) | SKL (signed off) | Ported with SKL-13 to SKL-18: potion duration from Prolonged Effects, decoctions without duration bonuses, Expert Brewer, Adaptation, Tissue Transmutation, oils wearing off, Fixative, the non-aimed bomb penalty, own bombs not halved |
| The Mutation Catalyst (potion, recipe, effect) | MUT-12 (signed off) | Ported with Life Leech |
| Manticore and Netflix gear's potion duration on potions; Viper's poison healing | ARM (signed off) | Ported (ARM-10, ARM-15, ARM-11); their ALCH parts are ported (ALCH-05, ALCH-14) |
| Recipes: ingredients (117 recipes), the new alcohol recipes, recipe prices, recipe level gates in shops and loot, the master alchemist's stock, the missing Tawny Owl recipe fix, the Alchemy dismantle kit and dismantling named mutagens | CRAFT, LOOT, ECON | Crafting and availability, not what the items do; the alcohol recipes with FOOD |
| Prices and weights of alchemy items (`weight` 0 → 0.1 on potions, oils, bombs; mutagens 1 → 0.1) | ECON, WGT | |
| Well fed, well hydrated, drunkenness, alcohol and raw-food toxicity | FOOD | Connoisseur's toxicity already with SKL-18 |
| The generic bleeding, poison, burning, frozen (DoT pause, Aard on frozen enemies), hypnotized and frost-slowdown effects, the frozen rotfiend | EFX, AI | Shared by every source; the bomb-specific effect abilities are ALCH-14 |
| The character panel's toxicity lines (`attribute_name_tox_*`, `avail_tox`) and the recipe book's layout | UI | |
| Witch boiling water, monster nest experience | AI, XP | Found by the sweeps, not alchemy |

## Changes at a glance

### What Ghost Mode changed

| # | Feature | Vanilla 1.32 | Legacy GM | Units (main) |
|---|---|---|---|---|
| ALCH-01 | Toxicity and overdose | Overdose at 75% (Heightened Tolerance raises it); decay ×2 out of combat; decoctions' locked toxicity does not start overdose damage or the HUD's overdose look; the green screen border at 50% | Fixed 75%; decay the same in and out of combat; decoctions count; the border and visuals at the real threshold; overdose damage through `GetToxicityDamage` (Euphoria's factor); toxicity head effects kept right under Quen and after fast travel | `W3Effect_Toxicity.OnUpdate`, head-effect helpers, `TOXICITY_DAMAGE_THRESHOLD`, `Add/Set/RemoveToxicityOffset`, `CR4HudModuleWolfHead.UpdateToxicity` |
| ALCH-02 | Potion-wide rules | Drinking a potion again replaces it; drinkable at any time | Potions (not decoctions) stack: drinking again extends the duration; no drinking during special sword attacks or channelled signs; decoctions refresh | `CBaseGameplayEffect.GetSelfInteraction`, `CumulateWith`, `DrinkPotionFromSlot` |
| ALCH-03 | Potion values | Toxicity 15–30, durations as in the [ledger](ledger/alchemy.md#1a-potions) | Toxicity mostly lower (Swallow, Tawny Owl, Golden Oriole 15; Thunderbolt, Petri 20; Cat 10), Black Blood and Full Moon 30; Cat 240/360/480 s, Tawny Owl 60 s, Full Moon 90/120/150 s and +900/1300/1700 Vitality, Black Blood 60/90/120 s and 10/15/20%, Blizzard 30 s and time ×0.5/0.35/0.25, Thunderbolt T1 +25%, Petri +25/30/35%, Maribor +15/20/25% | `def_item_alchemy_potion.xml`, `effects_potions.xml` (and NG+) |
| ALCH-04 | Swallow, White Raffard, White Honey | White Raffard cancels Swallow and over-heals (multiplies max Vitality first); a second White Raffard or White Honey dose does nothing; Swallow's regen effect buggy | Both stop bleeding, Swallow +20/35/50% bleeding resistance, White Raffard no longer cancels Swallow, heals the stated share and every dose works, 2 charges at T3; White Honey 2/3/4 charges, every dose clears toxicity; Swallow's regen from its ability, not a second regen effect | `Swallow.ws`, `WhiteRaffardDecoction.ws`, `WhiteHoney.ws`, `potionVitalityRegen.ws`, potion data |
| ALCH-05 | Golden Oriole | Full poison immunity, cure; T3 poison heals | +20/35/50% poison resistance, cure; T3 adds 5 s of poison immunity; no healing from poison | `GoldenOriole.ws`, `CActor.RemoveGoldenOriolePoisonImmunity`, `CActor.ReduceDamage`, `ProcessActionDamage`, data |
| ALCH-06 | Petri's Philtre level 3 | — | Sign effects last a third longer (knockdown, confusion, puppet, burning ×1.34; Yrden and Quen durations) | `CBaseGameplayEffect.CalculateDuration`, `W3YrdenEntity`, `W3QuenEntity.GetSignStats`, `GetSignApplyBuffTest` |
| ALCH-07 | Other potions' special effects | Blizzard: T3 free actions with 1 adrenaline point; Cat: hypnosis immunity from T2; Tawny Owl T3: never expires at night (buggy); Maribor Forest cancels Well Hydrated | Blizzard: no finishers while slowed, T3's free actions need 3 points; Cat: hypnosis immunity at T3; Tawny Owl's night rule rewritten; Maribor and Well Hydrated coexist; Black Blood's returned damage not scaled by attack power | `ProcessActionReaction`, `GetStaminaActionCost`, `W3Effect_Hypnotized.OnUpdate`, `W3Potion_TawnyOwl.OnTimeUpdated`, `ProcessActionBlackBloodReturnedDamage` |
| ALCH-08 | Pheromones, Killer Whale, Pops' Antidote | Pheromones 15 toxicity, 90 s, quality 2–4, bear and nekker unobtainable; Killer Whale 15 toxicity, duplicate tier definitions; Pops' Antidote 25–30 toxicity, no sound | 10 toxicity, 120 s, quality 4, recipes of quest type, start sound; Killer Whale 10 toxicity, 180 s, one tier; Pops' Antidote 10 toxicity, sound | potion data, `PheromoneBear.ws`, `FactPotion` |
| ALCH-09 | Decoction rules | Toxicity offset 70 (Basilisk 40, 96 min); Cockatrice, Nightwraith, Ekimmara, Chort | Offset 70 for all, 30 min for all; no duration bonuses (SKL-13); Cockatrice, Chort as vanilla, Nightwraith's stacks reset on a new dose, Ekimmara's data rewritten | `def_item_alchemy_mutagens.xml`, `effects_mutagens.xml` effects, `mutagen06.ws`, strings |
| ALCH-10 | Decoctions that build up on melee hits | Katakan +5% crit; Water Hag +50% at full Vitality; Wyvern +1% per hit; Alghoul +50% adrenaline until hit; Forktail 3 action types | Katakan, Water Hag, Alghoul, Forktail stack per melee hit (crit, attack power, adrenaline gain, sign intensity) and decay or reset; Wyvern stacks per sign cast | `mutagen01/05/10/15/17.ws`, hooks in the player, sign and NPC code |
| ALCH-11 | Sign decoctions | Foglet +25% intensity in bad weather; Succubus attack power over time; Wraith free Quen on big hits; Ancient Leshen +2 stamina regen per sign | Foglet flat sign damage per blue mutagen; Succubus Puppet +50% damage; Wraith Quen from behind, +50% Quen near specters; Ancient Leshen +10% intensity per sign | `mutagen09/14/19/22.ws`, damage and Quen hooks |
| ALCH-12 | Sustain and stamina decoctions | ArchGriffin heavy attacks spend all stamina for 5% HP; Troll regen; Noonwraith short CC; Grave Hag +5 per kill; Ekhidna 10% heal per action; Basilisk shrine buff; Nekker Warrior mounted attack power | ArchGriffin +50% melee cost, damage by stamina spent; Troll +80 combat regen at low stamina; Noonwraith stamina regen per kill; Grave Hag capped per kill; Ekhidna 0.1% per stamina point; Basilisk regen per green mutagen; Nekker Warrior cheaper melee per red mutagen | `mutagen04/12/13/18/21/23/25.ws`, stamina code |
| ALCH-13 | Defensive and conditional decoctions | Arachas resistance by free carry weight; Doppler +50% damage from behind; Fiend +20 carry weight; Elemental growing DoT resistance; Werewolf free sprint; Leshen 10 + 2%; Griffin stacking resistances; Reliever's vs specters | Arachas acid on attackers; Doppler +50% crit damage from behind; Fiend no stagger from small hits; Elemental flat 50%; Werewolf berserk at 20% Vitality; Leshen 25%; Griffin 2 s immunity after two quick hits; Reliever's spectral-form damage | `mutagen02/11/16/20/24/26/27/28.ws`, damage and actor hooks |
| ALCH-14 | Bombs | Grapeshot 350/600/600, Dancing Star and Puffball damage per tick, Dragon's Dream 300/400/400, Samum 4/6/8 s, Silver Dust 20/40/permanent, Northern Wind +5/7/10% per hit | Fixed damage, clear roles: Grapeshot 300/400/500 + 50/100/150 fire, only T3 breaks shields; clouds 3/4/5 s with 1% of health per tick; Dragon's Dream 300/400/500, 0/50/75% burning, T3 explosion 500; Samum 4/5/6 s and +50/75/100% crit chance; Silver Dust 20/30/40 s, more blocks, no teleporting; Northern Wind +25/35/50%; the equipped bomb destroys nests | petard data, bomb effects in `effects.xml`, `W3Petard`, `silverDust.ws`, `monsterNestEntity.ws`, AI tasks |
| ALCH-15 | Dimeritium bomb | Blocks signs and monsters' magic abilities while in the cloud | A Dimeritium effect for 20/30/40 s: blocks signs, magic creatures −50/75/100 armor and −5/10/15% resistance, mages −30/40/50% damage; smaller cloud | `W3Effect_DimeritiumEffect`, `dimeritium.ws`, damage hooks, `petard_dimeritium_bomb.w2ent` |
| ALCH-16 | Oils | +10%/…/+50% attack power, resistance reduction at T3 | +25% attack power at every tier, +5% crit chance from T2, +25% crit damage at T3, no resistance reduction; tooltip rows; oils removed when a sword changes hands | `def_item_alchemy_oils.xml`, `GiveItemTo`, `RemoveAllOilAbilitiesFromItem`, `AddOilInfo`, 36 tooltip rows, strings |
| ALCH-17 | Alchemy tooltips and descriptions | Potion and bomb tooltips miss effects; decoction tooltips generic | Every effect listed (by item and by name: alchemy menu, shops, recipe book); decoction descriptions with values; new attribute names | `GetPotionAttributesForTooltip/ByName`, `GetBombAttributesForTooltip/ByName`, `FillInMutagenDescription*`, `FindAttrInTooltipSettings`, strings |
| ALCH-18 | Alchemy debug commands | — | `addalchemy1/2/3`, `adddecoctions`, `toggledebugoils` | `console_debug.ws` |

### What 5.x changed

| # | Feature | 5.x change (from code and data) |
|---|---|---|
| ALCH-01 | Toxicity | Threshold 50%; decay ×1.1 out of combat; head effects in 5 steps; camera effect at the threshold (as legacy) |
| ALCH-02 | Potion rules | none (replace, drink any time); Netflix potion duration (ARM-15) |
| ALCH-03 | Potion values | Black Blood 25 toxicity; Blizzard 20 toxicity, 8/10/12 s, ×0.8/0.7/0.6; Reinald's Philtre added |
| ALCH-04 | Swallow and co. | White Raffard 25 toxicity (legacy's value); White Honey also clears the decoction offset |
| ALCH-05 | Golden Oriole | 25 toxicity; T3's healing from poison still in `ProcessActionDamage` |
| ALCH-06 | Petri level 3 | none |
| ALCH-07 | Other potions | Blizzard reworked (continuous slow motion in combat); Cat +5/7/10% crit chance and screen effects; Tawny Owl touched |
| ALCH-08 | Pheromones and co. | Killer Whale 15 toxicity; the drowner pheromone's sound |
| ALCH-09 | Decoction rules | Offset 50 (Basilisk 40, 96 min) |
| ALCH-10 to 13 | Decoctions | Katakan 10%, Grave Hag +10, Leshen 10 + 10%, Werewolf night stamina regen, Forktail's action types, Reliever's specter block; scripts otherwise 1.32's |
| ALCH-14 | Bombs | Grapeshot and Dragon's Dream lower; Silver Dust and Northern Wind blocks; potion duration raises bomb damage |
| ALCH-15 | Dimeritium | `ablMagic` blocked |
| ALCH-16 | Oils | Silver tag on three oils |
| ALCH-17 | Tooltips | `GetPotionAttributesForTooltip` rewritten (Reinald's Philtre, attributes) |
| ALCH-18 | Debug | none |

### Classification and proposed action

| # | Feature | Class | Proposed action |
|---|---|---|---|
| ALCH-01 | Toxicity | overlap | Legacy's threshold and decay (DL1); legacy's fixes on 5.x's head effects; ends MUT-09's threshold deviation |
| ALCH-02 | Potion rules | clean | Port |
| ALCH-03 | Potion values | clean, overlap (Black Blood, Blizzard toxicity) | Port legacy's values (DL3 on the durations) |
| ALCH-04 | Swallow and co. | clean, overlap (White Honey) | Port |
| ALCH-05 | Golden Oriole | overlap | Port; remove 5.x's T3 absorption (DL5); ends DMG-05's deviation |
| ALCH-06 | Petri level 3 | clean | Port; ends DMG-07's, SKL-10's and SKL-11's deviations |
| ALCH-07 | Other potions | rethink (Blizzard), overlap (Cat) | Legacy's Blizzard and Cat (DL4); ends ENCH-09's Tawny Owl hand-off |
| ALCH-08 | Pheromones and co. | clean | Port; ends ITEM's quality hand-off |
| ALCH-09 | Decoction rules | overlap | Legacy's offset 70 (DL2) |
| ALCH-10 to 13 | Decoctions | conflict (5.x callers of 1.32's rules remain), overlap on five | Port legacy's, neutralise 5.x's live terms (DL6); ends DMG-01 to DMG-04's and DMG-12's mutagen deviations, SKL-11's Mutagen 19, STAM's hand-offs |
| ALCH-14 | Bombs | overlap | Legacy's values and rules (DL7) |
| ALCH-15 | Dimeritium | conflict | Port as a GM effect; ends DMG-02's and DMG-05's Dimeritium deviations |
| ALCH-16 | Oils | clean | Port (the decay code is SKL-14's); ends DMG-02's oil deviation, SWD's and ARM's hand-offs |
| ALCH-17 | Tooltips | conflict | Port on 5.x's rewritten functions |
| ALCH-18 | Debug | clean | Port as test-free debug commands |

---

### ALCH-01 Toxicity and overdose

| | |
|---|---|
| Kind | system, fix |
| Pillars | P8 |
| 5.x class | overlap |
| Flags | balance, decided (DL1) |
| Depends on | SKL-13 (`GetToxicityDamageThreshold`, no skill raises it), SKL-17 (Frenzy, Endure Pain), MUT-08, MUT-09 (the shared `OnUpdate` replacement, `mutations/toxicity.ws`), ARM-04 (medium armor decay) |
| Skill trees | n/a (the threshold moves the "while overdosed" skills of both trees: Frenzy, Endure Pain) |
| Port form | the threshold as a `default` in Ghost Mode's `W3GameParams` block (`stamina/staminaCosts.ws`: `TOXICITY_DAMAGE_THRESHOLD` 0.75, read by SKL-13's `GetToxicityDamageThreshold` and the character panel); ALCH's hunks in MUT's `@replaceMethod W3Effect_Toxicity.OnUpdate` (`mutations/toxicity.ws`: the decay and its guard); `@wrapMethod`s of the three offset functions (`alchemy/toxicity.ws`) |
| Port status | signed off (2026-10-20); **verified** in both trees |
| Open checks | does 5.x's five-step head effect still break under Quen and after fast travel (legacy's fix not ported, below; not watched in game) |
| Save impact | none (expected) |
| NG+ counterpart | none (scripts) |

**What it does** (changelist 384–386, bugfixes 92–95, 130–131): overdose starts at 75% of maximum toxicity, which no skill raises; toxicity decays 0.25 points per second in and out of combat (1.32 doubled it out of combat); overdose costs 0.5% of maximum Vitality per second (Euphoria's factor on top, MUT-09). Decoctions' locked toxicity counts toward overdose damage and the HUD's overdose look (1.32: it did not trigger them); the green screen border shows at the real threshold, not at 50%; the head effects follow the toxicity steps and are replayed when Quen ends and after fast travel.

**Implementation (legacy):** `gameParams.ws` `TOXICITY_DAMAGE_THRESHOLD` 0.75 (unchanged from 1.32; Heightened Tolerance no longer adds to it, SKL-13); `W3Effect_Toxicity.OnUpdate` (camera effect at the threshold, damage from `GetToxicityDamage`, decay only above 0 and without the out-of-combat doubling; Frenzy and Euphoria hunks are SKL's and MUT's), new `ToxPrc2EffectIdx`, `EffectIdx2EffectName`, `UpdateHeadEffect`, `<members>` (`playerHadQuen`); `W3PlayerAbilityManager.AddToxicityOffset`, `SetToxicityOffset`, `RemoveToxicityOffset` call `OnToxicityChanged` (the decoction fix); `CR4HudModuleWolfHead.UpdateToxicity` (overdose look with the locked toxicity).

Not in the changelist: decay runs only while toxicity is above 0 (`GetStat(BCS_Toxicity, true) > 0`).

**5.x:** threshold 0.50001; decay ×1.1 out of combat; the head effect rebuilt in five steps (0 to 4, with an `IsEffectActive` guard); the camera effect already at the threshold; the HUD counts the locked toxicity itself (`UpdateToxicity` rewritten: nothing of legacy's left to port, in-5.x); a decoction adds 0.001 toxicity when drunk (kept in the port's `DrinkPreparedPotion`). The port today: MUT's `OnUpdate` replacement keeps 5.x's threshold, 5.x's ×1.1 and 5.x's head effects; `GetToxicityDamage` and Euphoria's factor are MUT-09's (ported).

**Decisions:**

- DL1 (owner, 2026-10-20): legacy's 75% threshold and legacy's decay (the same in and out of combat, only while there is toxicity).
- **Deviation:** the toxicity head effects are 5.x's five-step version; legacy's helper (`UpdateHeadEffect`, replaying the effect after Quen and fast travel) is not ported: 5.x rebuilt the head effects with an `IsEffectActive` guard, legacy's fix was made for 1.32's four-step code, and whether 5.x's still break under Quen is unchecked (cosmetic only; porter's call, confirmed by the owner, 2026-10-20: keep 5.x's visuals for the effects).

**Slices:** slice 1, verified 2026-10-20 in both trees. Scripted (`GMTest_alch01`, in the regression): the threshold reads 0.75; adding locked toxicity starts the toxicity effect and removing it ends it. Scripted in time (`gmtest_alch01_set/_tick`): the same decay in and out of combat; overdose damage at 80% toxicity, none at 70%. The head effects not watched.

**Ends:** MUT-09's deviation (Euphoria at 5.x's 50%); SKL-17's open check (the threshold).

**Later:** —

### ALCH-02 Potion-wide rules

| | |
|---|---|
| Kind | system |
| Pillars | P8 |
| 5.x class | clean |
| Flags | balance |
| Depends on | SKL-13 (`DrinkPreparedPotion`, `CalculatePotionDuration`), ENCH-09 (Prolongation on the potion timers) |
| Skill trees | n/a |
| Port form | `@replaceMethod` of `CBaseGameplayEffect.GetSelfInteraction` and `CumulateWith`; a wrapper of `W3PlayerWitcher.DrinkPotionFromSlot` (`alchemy/potionRules.ws`) |
| Port status | signed off (2026-10-20); **verified** in both trees |
| Open checks | the refusal message |
| Save impact | none (expected) |
| NG+ counterpart | none (scripts) |

**What it does** (changelist 732–735): potions, but not decoctions, stack: drinking a potion that is active adds its duration (time left and total) instead of replacing it (the effect's own `CumulateWith` runs: Swallow and White Raffard stop bleeding, White Honey clears toxicity again, ALCH-04); decoctions refresh. Geralt cannot drink during a special sword attack (Whirl, Rend) or while channelling a sign.

**Implementation (legacy):** `CBaseGameplayEffect.GetSelfInteraction` (cumulate for potion effects that are not decoctions; 1.32 cumulated only with Side Effects), `CBaseGameplayEffect.CumulateWith`; `W3PlayerWitcher.DrinkPotionFromSlot` (the combat-action check; attributed to SKL-18 for its Connoisseur part). Also in legacy, inert: an Alchemy Table effect (Blood and Wine's `effects_ep2.xml`, 60 minutes) that no script applies.

**5.x:** 1.32's (replace; drink at any time). 5.x's Netflix set adds potion duration (ARM-15, ported). The port's potion duration (potions only, Prolonged Effects, Netflix) is SKL-13's and ARM-15's, done.

**Legacy's quirks:** `OnEffectAdded` does not run again on a stacked dose, so Maribor Forest T3's adrenaline point and Full Moon T3's heal come only with the first dose (ported as legacy). The stacking test compares effect strength, which is equal for every tier of most potions (0 for those without a main value in legacy: Swallow, Tawny Owl, Cat, Maribor Forest; Thunderbolt's tiers too, in the game; Golden Oriole's is the sum of its resistances, so its tiers differ), so any two doses of those cumulate, and legacy's ability swap let a lower tier replace a higher one: fixed (DL12, below).

**Decisions:** port as legacy. The Alchemy Table effect is dropped: inert in legacy (no script or resource names it), no behaviour to carry (porter's call, confirmed by the owner, 2026-10-20).

- **Deviation:** potion stacking never swaps a stronger dose for a weaker one: when a dose cumulates with the running effect, the durations add up and the effect keeps the higher of the two tiers (`GetBuffLevel`, from the effect's ability name); a higher tier still raises it. Doses of different strength keep legacy's rule (the stronger replaces the running effect, a weaker one is refused). Legacy swapped the ability to the new dose's tier, so a lower tier drunk on a higher one lowered it (the owner's DL12, confirmed by the owner, 2026-10-20).

**Slices:** slice 2, verified 2026-10-20 in both trees. Scripted (`GMTest_alch02`, in the regression; drunk through `DrinkPreparedPotion`): durations add up, a higher tier raises the effect and a lower one keeps it (DL12), a second decoction refreshes. Real actions with a scripted read (`gmtest_alch02_cannot`): drinking refused during a real Whirl and a real Firestream, allowed afterwards. The refusal message not seen.

**Later:** —

### ALCH-03 Potion values

| | |
|---|---|
| Kind | tuning |
| Pillars | P8 |
| 5.x class | clean; overlap (Black Blood's and Blizzard's toxicity, Blizzard's values, Killer Whale) |
| Flags | balance, decided (DL3) |
| Depends on | ALCH-02 |
| Skill trees | n/a |
| Port form | DLC XML from `tools/gen_alch.py` (`items/gm_alch.xml`, NG+ from legacy's NG+ files): the potion abilities and effect abilities given whole from legacy (`replace`), 5.x's weights kept (WGT) |
| Port status | signed off (2026-10-20); **verified** in both trees (Blizzard's data with ALCH-07; Swallow's, White Raffard's, White Honey's and Golden Oriole's with ALCH-04 and ALCH-05) |
| Open checks | no potion's effect measured in a fight; NG+ (policy: not tested) |
| Save impact | none (expected: potion values are read from the definitions when drunk) |
| NG+ counterpart | applied (legacy's NG+ files), untested |

**What it does** (changelist 738–770): toxicity, duration, charges and effect values per tier. Thunderbolt 20 toxicity, +25/30/35% attack power; Petri's Philtre 20, +25/30/35% sign intensity; Maribor Forest 20, +15/20/25% adrenaline gain; Tawny Owl 15, 60 s at every tier; Full Moon 30, 90/120/150 s, +900/1300/1700 Vitality; Black Blood 30, 60/90/120 s, 10/15/20% returned; Blizzard 25, 30 s, time ×0.5/0.35/0.25 after a kill; Cat 10, 240/360/480 s. Full table in the [ledger](ledger/alchemy.md#1a-potions).

**Implementation (legacy):** `def_item_alchemy_potion.xml` abilities `BlackBlood_*`, `Blizzard_1/2`, `Cat_*`, `FullMoon_*`, `PetriPhiltre_*`, `TawnyOwl_*`, `Thunderbolt_*`; `effects_potions.xml` `BlackBloodEffect_*`, `BlizzardEffect_Level2/3`, `FullMoonEffect_*`, `MariborForestEffect_Level2/3`, `PetriPhiltreEffect_*`, `ThunderboltEffect_Level1`; NG+ copies (Full Moon's NG+ Vitality 1300/1700/2100).

**5.x:** Black Blood toxicity 25 (legacy 30), Blizzard toxicity 20 at every tier and 8/10/12 s with ×0.8/0.7/0.6 (legacy left Blizzard 3 and the toxicity at 1.32's 25 and 30 s, ×0.5); the rest 1.32's.

**Decisions:** port legacy's values, also on fields legacy left at 1.32's and 5.x changed (Blizzard's toxicity, Blizzard 3's duration and its slow motion), legacy behaviour first. DL3 (owner, 2026-10-20): the durations of legacy's code and data (Thunderbolt, Petri's Philtre, Maribor Forest 30/60/90 s, Swallow 30 s); the changelist's 60/120/180 s are the values with Prolonged Effects maxed.

**Slices:** slice 2, verified 2026-10-20 in both trees. Scripted (`GMTest_alch02`, in the regression): held potions read legacy's toxicity and duration; `gen_alch.py --verify` for every listed entry, regular and NG+. No potion's effect measured in a fight.

**Later:** —

### ALCH-04 Swallow, White Raffard's Decoction, White Honey

| | |
|---|---|
| Kind | fix, tuning |
| Pillars | P8 |
| 5.x class | clean; overlap (White Honey) |
| Flags | — |
| Depends on | ALCH-02 (their `CumulateWith`) |
| Skill trees | n/a |
| Port form | `alchemy/swallowHoneyOriole.ws`: scope-based overrides of `W3Potion_Swallow` (`OnEffectAdded`, `CumulateWith`), `W3Potion_WhiteRaffardDecoction` (`dontAddAbilityOnTarget`, `CacheSettings` dropping its `SwallowEffect` override, `CumulateWith`), `W3Potion_WhiteHoney` (`CumulateWith`), `W3Potion_Swallow` and `W3Potion_ReinaldPhiltre` (`GetEffectStrength` 0, legacy's strength); `@replaceMethod` of `W3Potion_VitalityRegen.OnUpdate` zeroing the effect's own regen (the base class `W3RegenEffect` cannot change: its `stat` is saved) and of `W3Potion_WhiteRaffardDecoction.OnEffectAdded`; DLC XML (`gen_alch.py`) |
| Port status | signed off (2026-10-20); **verified** in both trees |
| Open checks | no real bleeding. (Tawny Owl's regen counted twice was settled by ALCH-07: its own regen is zeroed) |
| Save impact | none (expected) |
| NG+ counterpart | applied, untested |

**What it does** (changelist 736–738, 752–754, 765–766; bugfixes 85, 89–90, 96–100): Swallow 15 toxicity, 30 s, +40/65/80 regen, +20/35/50% bleeding resistance, stops bleeding on every dose; its regen is a plain ability bonus (1.32's `W3Potion_VitalityRegen` started a second regen effect that read tier 1 and doubled itself); T3's regen not paused on hit (1.32, kept). White Raffard's Decoction (a potion) 25 toxicity, 2 charges at every tier, heals 35/60/100% of maximum Vitality without first raising it (1.32 multiplied maximum Vitality by the same share), every dose heals, stops bleeding, no longer cancels Swallow. White Honey 2/3/4 charges; every dose clears toxicity and potions, also a repeated one.

**Implementation (legacy):** `Swallow.ws` (`OnEffectAdded`, `CumulateWith`), `potionVitalityRegen.ws` (Swallow's and Tawny Owl's base class emptied: `<members>`, `CacheSettings`, `OnEffectAdded`, `OnLoad`, `OnUpdate`), `WhiteRaffardDecoction.ws` (`<members>`, `OnEffectAdded`, `CumulateWith`, `AddVitality`), `WhiteHoney.ws` (`OnEffectAdded`, `CumulateWith`, `CleanupToxicity`); data: `Swallow_*`, `WhiteRaffardDecoction_*`, `WhiteHoney_*`, `SwallowEffect_*`, the `WhiteRaffardDecoctionEffect` override of `SwallowEffect` removed; NG+ (Swallow's and White Raffard's NG+ values set to the regular ones: legacy's own NG+ values, kept by the NG+ rule).

**5.x:** 1.32's scripts; White Raffard toxicity 25; White Honey also sets the locked toxicity (decoction offset) to 0 when drunk.

**Decisions:** port as legacy. White Honey: the owner's DL6 (2026-10-20) keeps 5.x's reset of the locked toxicity (`SetToxicityOffset(0)`) as well as legacy's `CumulateWith`. Reinald's Philtre (5.x's quest potion, DL10): 5.x's values; its own regen effect is zeroed as Swallow's, so its stamina regen counts once, through its ability (the owner's "no double regen").

- **Deviation:** White Honey also resets the locked decoction toxicity, on every dose (5.x's addition; legacy's White Honey left it) (the owner's DL6, confirmed by the owner, 2026-10-20).

- **Deviation:** string 2110992178 (Swallow 3's text without the bleeding line) no longer carries the key `item_desc_swallow_3`: legacy gave the key to two rows, so which text showed was not defined; 2110992539, the full text, now owns it (audit F9; the owner, 2026-10-20; confirmed by the owner, 2026-10-20).

**Slices:** slice 3, verified 2026-10-20 in both trees. Scripted (`GMTest_alch04`, in the regression): Swallow's toxicity, duration and bleeding resistance; bleeding removed by every dose of Swallow and White Raffard; White Raffard heals its share with maximum Vitality unchanged and keeps Swallow; charges; a second White Honey clears toxicity and locked toxicity again. Scripted in time (`gmtest_alch_regen_a/_b`): Swallow's regen counted once (legacy's 40/80). Real drinks from the first potion slot (`gmtest_alch04_slot`), each dose in its own call: Swallow 1 on Swallow 3 keeps tier 3 and adds 30 s (`GMTest_alch04_after` in `gmtest_panel()` checks the same). Swallow 3's tooltip shows 2110992539's text (`gmtest_alch17_texts`, `GMTest_alch17_texts`). White Raffard's NG+ effect abilities are generated by `gen_alch.py` (35/60/100%, `--verify`); NG+ not run in game. No real bleeding.

**Later:** —

### ALCH-05 Golden Oriole

| | |
|---|---|
| Kind | tuning, system |
| Pillars | P8 |
| 5.x class | overlap |
| Flags | decided (DL5) |
| Depends on | ARM-11 (Viper set heals from poison, ported), DMG-05 (`ProcessActionDamage`), DMG (`CActor.ReduceDamage`, `damage/pipeline.ws`) |
| Skill trees | n/a |
| Port form | `alchemy/swallowHoneyOriole.ws`: `@replaceMethod` of `W3Potion_GoldenOriole.OnEffectAdded` and `CumulateWith`, `@addMethod GMHandlePoisonStatus`, a scope-based `OnEffectRemoved`; `@addMethod CActor.GMRemoveGoldenOriolePoisonImmunity` (timer); the absorption removed from `GMProcessActionDamage` (`damage/pipeline.ws`; `ReduceDamage`'s check sits in the minimum-damage block DMG-05 switched off); DLC XML |
| Port status | signed off (2026-10-20); **verified** in both trees |
| Open checks | poison damage with Golden Oriole 3 active (the healing's removal is from the code) |
| Save impact | none (expected) |
| NG+ counterpart | applied, untested |

**What it does** (changelist 746–750): 15 toxicity, 60/90/120 s; +20/35/50% poison resistance instead of immunity; every dose cures poison; T3 also gives 5 s of poison immunity. Poison no longer heals Geralt at T3 (the Viper set does that, ARM-11).

**Implementation (legacy):** `GoldenOriole.ws` (`OnEffectAdded`, `CumulateWith`, `HandlePoisonStatus`, `OnEffectRemoved`), `CActor.RemoveGoldenOriolePoisonImmunity`, `CActor.ReduceDamage` and `W3DamageManagerProcessor.ProcessActionDamage` (the T3 absorption removed), `W3QuenEntity.AddBuffImmunities` (Golden Oriole's line removed); data `GoldenOriole_*`, `GoldenOrioleEffect_*`; tooltip row `poison_immunity_duration`; strings.

**5.x:** 1.32's immunity and T3 absorption, toxicity 25.

**Decisions:** port as legacy; DL5 (owner, 2026-10-20): 5.x's absorption removed, as legacy did.

- **Deviation:** Golden Oriole's buff text (`effect_GoldenOrioleEffect_desc`, 5.x's "Immunity to poison.", which legacy kept) is legacy's item text, "Increases poison resistance, neutralizes the effects of poisons already in bloodstream." (string 2110992638, the vanilla key), in the 9 languages; Czech, German, French and Italian translated by the port, where legacy's item row is English (audit F12; the owner, 2026-10-20; the translations porter's call, confirmed by the owner, 2026-10-20).

**Slices:** slice 3, verified 2026-10-20 in both trees. Scripted (`GMTest_alch04`, in the regression): toxicity, resistance, T3's 5 s immunity, the cure; scripted in time (`gmtest_alch05_timer_a/_b`): poison takes again 6 s after Golden Oriole 3 while the potion runs. Poison damage with T3 active not tested (the healing's removal is from the code).

**Ends:** DMG-05's Golden Oriole deviation; ARM-11's dependency.

**Later:** —

### ALCH-06 Petri's Philtre level 3

| | |
|---|---|
| Kind | system |
| Pillars | P8 |
| 5.x class | clean |
| Flags | balance |
| Depends on | DMG-07 (`CBaseGameplayEffect.CalculateDuration`, `damage/durations.ws`), SKL-10, SKL-11 (Yrden's and Quen's `GetSignStats`, `skills/yrden.ws`, `skills/quen.ws`), SKL-08/09/12 |
| Skill trees | both (the same signs) |
| Port form | the term in the existing replacements (`damage/durations.ws`, `skills/yrden.ws:139`, `skills/quen.ws:100`) |
| Port status | signed off (2026-10-20); **verified** in both trees |
| Open checks | knockdown, confusion and puppet durations (the same code path as burning) |
| Save impact | none (expected) |
| NG+ counterpart | none |

**What it does** (changelist 759–760): with Petri's Philtre at T3, sign effects last a third longer: heavy knockdown, confusion, Axii's puppet and burning ×1.34 (after resistances), Yrden's trap and Quen's shield durations by the same bonus.

**Implementation (legacy):** `CBaseGameplayEffect.CalculateDuration` (DMG-07's unit), `W3YrdenEntity.GetSignStats` and the Yrden units SKL-10 noted (`<members>`, `GetCachedYrdenPower`, `DisablePreviousYrdens`), `W3QuenEntity.GetSignStats`; 1.32's own T3 term in `W3EffectManager.GetSignApplyBuffTest` commented out; the description string.

**5.x:** none (1.32's `GetSignApplyBuffTest` term).

**Decisions:** port as legacy. 1.32's level-3 term in `GetSignApplyBuffTest` was already removed with SKL-09 (`skills/igni.ws`).

**Slices:** slice 4, verified 2026-10-20 in both trees. Scripted (`gmtest_alch06_burn`): a sign burning effect lasts ×1.34 with Petri's Philtre 3. Real casts with a scripted read (`autocast`, `gmtest_alch06_signs`): Quen's shield 30 → 40.2 s and Yrden's trap 7.5 → 10.05 s. No knockdown, confusion or puppet measured (the same code path).

**Ends:** DMG-07's, SKL-10's and SKL-11's (Petri part) deviations.

**Later:** —

### ALCH-07 Other potions' special effects

| | |
|---|---|
| Kind | system, fix |
| Pillars | P8 |
| 5.x class | rethink (Blizzard), overlap (Cat), clean |
| Flags | decided (DL4) |
| Depends on | SKL-12 (`ProcessActionReaction`, `skills/axii.ws`), STAM-03 (`GetStaminaActionCost`), ENCH-09 (Tawny Owl's timer, `enchantments/prolongation.ws`), DMG-11 (`damage/returned.ws`) |
| Skill trees | n/a |
| Port form | `alchemy/otherPotions.ws`: `@replaceMethod` of `W3Potion_Blizzard.KilledEnemy` and `OnTimeUpdated` with 1.32's bodies, of `W3Effect_Hypnotized.OnUpdate`; scope-based overrides of `W3Potion_TawnyOwl` (its own regen zeroed) and `W3Potion_MariborForest` (`CacheSettings` dropping the Well Hydrated override); Blizzard T3's free actions in a scope-based override of `W3PlayerAbilityManager.GetStaminaActionCost` (legacy's override, ahead of 5.x's cost and every Ghost Mode term; `alchemy/staminaCostInternal.ws`), removed from `GetStaminaActionCostInternal`; Tawny Owl's `GetEffectStrength` 0; the finisher rule already in SKL-12's `ProcessActionReaction`; Tawny Owl's hours in ENCH-09's replacement; legacy's Blizzard and Cat data (`gen_alch.py`) |
| Port status | signed off (2026-10-20); **verified** in both trees (Cat's hypnosis rule from the code) |
| Open checks | Cat's hypnosis rule (from the code); a kill in a real fight starting Blizzard (a scripted kill through the game's death path seen); Tawny Owl at night; Blizzard 3's free actions in a real Whirl, Rend or blocked hit (scripted drains only) |
| Save impact | none (expected) |
| NG+ counterpart | applied (data), untested |

**What it does** (changelist 739, 744–745, 755–756, 763–764, 767–768; bugfix 135): Blizzard slows time after a kill (×0.5/0.35/0.25) and no finisher starts while it does; at T3 actions are free during the slow motion only with 3 adrenaline points (1.32 checked for 1). Cat grants hypnosis immunity at T3 only (1.32: from T2). Tawny Owl T3 never expires at night (rewritten timer). Maribor Forest no longer cancels Well Hydrated. Black Blood returns damage that attack power does not scale.

**Implementation (legacy):** `W3DamageManagerProcessor.ProcessActionReaction` (no finisher while Blizzard's slow motion runs), `W3PlayerAbilityManager.GetStaminaActionCost`, `GetStaminaActionCostInternal` (Blizzard's T3 moved), `W3Effect_Hypnotized.OnUpdate`, `W3Potion_TawnyOwl.OnTimeUpdated`, `ProcessActionBlackBloodReturnedDamage` (`CPS_Undefined`; DMG-11's unit), the `MariborForestEffect` override removed; data and descriptions.

**5.x:** Blizzard reworked: from drinking, the slow motion runs whenever Geralt is in combat with targets or under attack, 8/10/12 s, ×0.8/0.7/0.6, with a screen effect; kills no longer start it. Cat +5/7/10% crit chance and a screen effect shared with Blizzard. Tawny Owl's timer touched: it freezes while the hour is at or before dawn, legacy's while before dawn or from dusk on (the port's ENCH-09 replacement is 5.x's body). Blizzard T3's free actions need Battle Trance in 5.x. **In the port today** 5.x's Blizzard runs with legacy's finisher rule (SKL-12): no finishers at all while 5.x's potion lasts.

**Decisions:** DL4 (owner, 2026-10-20): legacy's Blizzard (3 s slow motion after kills, legacy's values, no finishers while it runs) and legacy's Cat (hypnosis immunity at T3 only, no crit chance). Tawny Owl: legacy's night rule and legacy's single regen (legacy turned it into a plain effect fed by its ability; the port zeroes its own regen effect, the base class cannot change).

- **Deviation:** Blizzard T3's free actions are legacy's (3 adrenaline points, no 5.x Battle Trance condition, every stamina drain free, fixed drains such as Whirl's, Rend's, a blocked hit's and Quen's included, checked first in `W3PlayerAbilityManager.GetStaminaActionCost` as legacy did; audit F4) (porter's call, confirmed by the owner, 2026-10-20: Blizzard 3 without Battle Trance). 5.x's Mutation 7 toxicity denial, once kept in front of them, could never fire (it read Delayed Recovery's threshold, which SKL's `GetAlchemyS03Threshold` sets out of reach) and was removed by the whole-port fix round (audit A3-4, 2026-11-03), so Blizzard is never denied, as in legacy and as [MUT-07](mut.md#mut-07-adrenaline-rush-mutation-7) says.
- **Deviation:** Cat's and Blizzard's 5.x screen effects (the cat view settings, Blizzard's 5.x-only blue tint, shown while legacy's 3 s slow motion after a kill runs: audit F5) are kept: cosmetic, no rule depends on them (porter's call, confirmed by the owner, 2026-10-20: keep 5.x's visuals for the effects).

**Slices:** slice 4, verified 2026-10-20 in both trees. Scripted (`GMTest_alch07`, in the regression): Blizzard's data; no slow motion before a kill, a kill starts it; with Blizzard 3 and 3 adrenaline a light attack, a fixed drain and Whirl's drain cost nothing during the slow motion, with 2 adrenaline they cost; Cat T3 without crit chance; Maribor Forest with Well Hydrated keeps both; Blizzard's screen effect on after a kill and off with the potion. Scripted in time (`gmtest_alch07_blizzard_a/_b`, in combat with a wolf): time ×0.5 for the slow motion, back to 1, no restart while the fight goes on. The test dummy killed by script through the game's death path (`gmtest_alch07_blizzard_kill`): slow motion and tint on at once, off 8 s later; seen on screen in the classic tree. The texts read by key in the regression and as the tooltips build them (`gmtest_alch17_texts`). Not verified in game: Cat's hypnosis rule (from the code, `== 3` for 5.x's `>= 2`); a kill in a real fight; Tawny Owl at night; the texts on screen.

Not in legacy's code: Cat's "+25 to range of vision" and Black Blood's T2 stagger and T3 bleeding (changelist 745, 768) are vanilla 1.32's.

The texts: Cat 1's item text and Cat's buff text are 5.x's first sentence, without "Increases critical hit chance." (strings 2110992633, 634 with the vanilla keys), Blizzard 1's is legacy's tier-2 text and Blizzard 3's that text plus 5.x's sentence on 3 adrenaline points (2110992635, 636); Czech translated by the port for tiers 1 and 3, where legacy had none (legacy's tier-2 row stays English; porter's call, confirmed by the owner, 2026-10-20).

**Ends:** ENCH-09's Tawny Owl hand-off; STAM's Blizzard line.

**Later:** —

### ALCH-08 Pheromones, Killer Whale, Pops' Antidote

| | |
|---|---|
| Kind | tuning, content, fix |
| Pillars | P8 |
| 5.x class | clean; overlap (Killer Whale's toxicity) |
| Flags | — |
| Depends on | CRAFT, LOOT (where the bear and nekker pheromones are sold, changelist 737–738) |
| Skill trees | n/a |
| Port form | DLC XML (`gen_alch.py`: the pheromone, Killer Whale and Pops' Antidote abilities); wrappers of `W3Potion_PheromoneBear.OnEffectAdded`/`OnEffectRemoved`; scope-based `onAddedSound` defaults of `W3Potion_PheromoneBear`, `W3Potion_PheromoneNekker` and `W3Potion_Fact`; `GMIsPheromoneRecipe` in SKL-16's Acquired Tolerance count (`alchemy/potionRules.ws`) |
| Port status | signed off (2026-10-20); **verified** in both trees |
| Open checks | the drinking sounds not heard; a grizzly bear not met |
| Save impact | none (expected) |
| NG+ counterpart | applied, untested |

**What it does** (changelist 737–743; bugfixes 148–149): pheromone potions 10 toxicity, 120 s, quality 4 (1.32: 2 to 4); their recipes are of the quest type (shown with quest items, not counted as potion formulas); the bear pheromone's effect cleaned up; every pheromone and Pops' Antidote plays the drinking sound. Killer Whale 10 toxicity, 180 s, one tier (1.32's file defined Killer Whale twice, the second time with tiers 2 and 3 that no item uses; legacy commented the second set out). Pops' Antidote 10 toxicity.

Why quest type: legacy's Acquired Tolerance counts potion, bomb, oil, substance and decoction formulas only (`IsAlchemy18Recipe`), so the pheromones add no maximum toxicity; the port's SKL-16 recount counts potion formulas, so today they do.

**Implementation (legacy):** `PheromonePotion*_1`, `KillerWhale_1` (both), `KillerWhale_2/3`, `PopsImmunity`; effects `PheromoneEffect*` (sound), `FactPotion` (sound); `PheromoneBear.ws` (`OnEffectAdded`, `OnEffectRemoved`: grizzly bears befriended too); recipes `Recipe for Bear/Drowner/Nekker Pheromone Potion 1` (`cookedItemType` quest; their ingredients are CRAFT's).

**5.x:** Killer Whale 15 (both definitions), the drowner pheromone's sound; otherwise 1.32's.

**Decisions:** port as legacy (Killer Whale 10, quality 4 for the pheromones: ITEM's hand-off). The drinking sound comes from class defaults: an effect's first `<effects>` definition wins, so a DLC cannot add the attribute; the result is legacy's.

- The pheromone formulas are quest formulas, as legacy's (`cookedItemType` quest, listed under the alchemy menu's quest group): carried in CRAFT-06's whole-file override of the recipe file by `gen_craft.py` (the owner's decision, 2026-11-03, whole-port audit C3-4). A DLC cannot override `<alchemy_recipes>`, but the port overrides the file whole. Acquired Tolerance's name check (`GMIsPheromoneRecipe`) still skips them; with the quest type it is redundant. Verified 2026-11-03 in both trees (scripted: `GMTest_data_items` in the regression).

**Slices:** slice 2, verified 2026-10-20 in both trees. Scripted (`GMTest_alch02`, in the regression): Killer Whale 10 toxicity and 180 s (5.x defines it twice; the override wins), the pheromones' and Pops' Antidote's data; a drunk bear pheromone makes grizzly bears friendly, hostile again when it ends. The sounds not heard, no grizzly met.

**Ends:** ITEM's hand-off (pheromones' and Killer Whale's quality).

**Later:** —

### ALCH-09 Decoction rules

| | |
|---|---|
| Kind | tuning, system |
| Pillars | P8 |
| 5.x class | overlap |
| Flags | balance, decided (DL2) |
| Depends on | ALCH-01 (threshold), SKL-13 (no duration bonuses for decoctions, `skills/brewing.ws`, ported), SKL-16 (Adaptation, Tissue Transmutation, offsets only when above 0, ported), MUT-13 (Metamorphosis) |
| Skill trees | n/a |
| Port form | DLC XML from `tools/gen_alch.py` (`items/gm_alch.xml`, NG+ in `items_plus/`): the 28 decoction abilities `Mutagen_1` to `Mutagen_28` given whole from legacy (`on_conflict="replace"`); `effects_mutagens.xml` entries given whole per decoction slice (ALCH-10 to 13) |
| Port status | signed off (2026-10-20); **verified** in both trees |
| Open checks | Cockatrice and Chort in play (Chort scripted only); the load-time cleanup on a real load with Elemental, Basilisk or Foglet running (only the removal is tested); 5.x's Mutation 12 (a random decoction per kill) with the reworked decoctions, not reviewed |
| Save impact | none (expected: the offset is read when drunk) |
| NG+ counterpart | applied, untested |

**What it does** (changelist 773–775): every decoction locks 70 toxicity (its offset) for 30 minutes, Basilisk included (1.32: 40 and about 96 minutes); decoctions get no duration bonus and do not stack (ALCH-02, SKL-13). The four decoctions legacy left in effect as they were: Cockatrice (+1 charge to bombs and potions), Chort (stagger immunity), Ekimmara (life leech, data rewritten to the same 10%), Nightwraith (+50 Vitality per kill; a new dose wipes the stacks). The tooltip explains the toxicity offset.

**Implementation (legacy):** `def_item_alchemy_mutagens.xml` `Mutagen_23` (offset 70, the extra 3960 s commented out; the other 27 items unchanged at 1.32's 70); `effects_mutagens.xml` custom effects (start sounds, only in the NG+ file: NG+-only change); `Mutagen07Effect`; `mutagen06.ws` (`CumulateWith`); strings 2110992381–382, 188, 246, 477.

**5.x:** the offset of the 27 items lowered to 50 (Basilisk 40, 96 minutes): a change on items legacy never touched, which therefore replaces legacy's 70 unless the port overrides it.

**Decisions:** DL2 (owner, 2026-10-20): legacy's 70 for all 28, Basilisk included. Weight is WGT's (`CommonMutagenAbility` keeps 5.x's).

Chort's conversion sits at the top of SKL-11's `InternalAddEffect` wrapper (`skills/quen.ws`): a knockdown or heavy knockdown on Geralt becomes a stagger for Quen's rules (alternate Quen denies it without breaking, the basic shield denies it and breaks), as legacy (legacy turned `EET_HeavyKnockdown` into a stagger too; 5.x converts `EET_Knockdown` only).

**Slices:** slices 1 and 8, verified 2026-10-20 in both trees. Scripted (`GMTest_alch01`, `GMTest_alch13`, `GMTest_alch09_chort`, in the regression): all 28 decoctions' offset 70 and 1800 s, Basilisk's extra duration 0 (`gen_alch.py --verify`, regular and NG+); a second Nightwraith decoction wipes its stacks; Ekimmara's 10% life leech; the load-time cleanup (`GMCleanupDecoctionAbilities`, run on every load by an `OnSpawned` wrapper) removes leftover stacks and 5.x's abilities; with Chort a knockdown or heavy knockdown leaves Geralt staggered and a stagger is denied. The decoctions' start sounds are 5.x's already (legacy added them only in NG+).

**Later:** —

### ALCH-10 Decoctions that build up on melee hits (Katakan, Water Hag, Wyvern, Alghoul, Forktail)

| | |
|---|---|
| Kind | system, tuning |
| Pillars | P2, P8 |
| 5.x class | conflict (5.x's 1.32 rules still called); overlap (Katakan's crit, Forktail's action types) |
| Flags | balance, decided (DL6) |
| Depends on | DMG-03 (`GetAttackersPowerMod`, `damage/formula.ws`), SKL's sign cast states (`skills/signSlots.ws`), MUT's combat-start and take-damage replacements (`mutations/combatStart.ws`, `mutations/takeDamage.ws`), `OnProcessActionPost`, `OnCombatFinished` |
| Skill trees | n/a (sign casts of either tree) |
| Port form | `alchemy/decoctionsMelee.ws`: scope-based overrides of `W3Mutagen01/05/10/17_Effect` (`dontAddAbilityOnTarget`, `OnEffectRemoved`), `@addMethod`s (legacy's `Manage*`, `Add*`, `Remove*`, `GetStacks` with the `GM` prefix), `@replaceMethod` of `W3Mutagen15_Effect.OnEffectAdded`/`OnEffectRemoved` and `W3Mutagen17_Effect.OnUpdate`/`OnLoad`; hooks: a wrapper of `W3PlayerWitcher.OnProcessActionPost` and `OnCombatFinished`, the sign-cast point `GMAddSignCooldown` (`stamina/signCooldowns.ws`, every player cast), MUT's `OnTakeDamage` replacement (`mutations/takeDamage.ws`); 5.x's live 1.32 terms removed (Water Hag's full-Vitality term in `GetAttackersPowerMod`, Alghoul's combat-start ability in `mutations/combatStart.ws`, Wyvern's and Alghoul's loss on any hit, Forktail's boost; Wyvern's per-hit add taken back by a `CNewNPC.OnTakeDamage` wrapper); HUD counters (`extraValue`, shown by the HUD's format 4 with the six decoctions in its condition) in MUT-14's `UpdateBuffs` replacement; DLC XML (`gen_alch.py`) |
| Port status | signed off (2026-10-20); **verified** in both trees |
| Open checks | a real sword attack or sign cast with the decoctions; fist hits of Katakan and Water Hag (Wyvern's scripted); the HUD percentages of Katakan, Water Hag, Wyvern and Ancient Leshen on screen (Alghoul's and Forktail's seen); Katakan's stacks: once, in the new tree, the first Katakan test after a regression run showed 0 stacks after three sword hits; a second run passed and it could not be reproduced, so watch for it |
| Save impact | none (expected); stacks are abilities on Geralt that a save keeps: a load-time cleanup is advisable |
| NG+ counterpart | applied, untested |

**What it does** (changelist 776–779, 785–786, 795–797, 803–808):
- **Katakan:** each non-critical, non-fist melee hit +5% crit chance (5 stacks, 25%); at 5 stacks +50% crit damage; reset on a crit and at combat end.
- **Water Hag:** each melee hit +10% attack power (max +100%; 20 stacks of 0.5%); taking damage removes 0.5% per 1% of Vitality lost (damage over time excluded); reset at combat end. 1.32's +50% at full Vitality gone.
- **Wyvern:** each sign cast in combat +16.7% melee attack power (max 50%); dealing melee damage or combat end clears it. 1.32's +1% per hit gone.
- **Alghoul:** as Water Hag, on adrenaline gain (+10% per hit, max 50%). 1.32's +50% until hit gone.
- **Forktail:** each melee hit +10% sign intensity (max 50%); any sign cast or combat end clears it. 1.32's three-action-types rule gone.

**Implementation (legacy):** `mutagen01.ws`, `mutagen05.ws`, `mutagen10.ws`, `mutagen15.ws`, `mutagen17.ws` (new `Manage*`, `Add*`, `Remove*`, `GetStacks`; 1.32's methods removed); `KatakanBonusEffect` and the five `MutagenNNEffect` abilities; the calls in `W3PlayerWitcher.OnProcessActionPost`, `OnCombatFinished`, `OnTakeDamage`, `Attack`, `CastSign`, `W3SignEntity.OnEnded`, `CNewNPC.OnTakeDamage`, every sign's cast state (Aard, Igni, Axii, Quen, Yrden), `GetAttackersPowerMod`; HUD counters in `CR4HudModuleBuffs`; descriptions.

**5.x:** 1.32's rules, live in the port through 5.x's callers; Katakan's crit 10% (1.32: 5%; legacy's script with 5.x's value would cap at 50%); Forktail counts light and heavy attacks separately.

**Decisions:** port as legacy, with legacy's data (Katakan 5% per stack, the owner's DL6). Wyvern and Forktail react to every sign cast of Geralt's that starts a cooldown (normal and alternate casts; legacy called them in each sign's cast code, at the same points).

- **Deviation:** 5.x's per-hit Wyvern stack (`CNewNPC.OnTakeDamage`) is taken back by a wrapper instead of being removed from 5.x's function, which the port does not replace; the result is legacy's; it matters only for fist hits, checked in `gmtest_alch10` (audit F18) (porter's call, confirmed by the owner, 2026-10-20).

- **Deviation:** the Spanish Katakan description (2110992455, `es.csv`) gets the maximum legacy's translation left out, "(máx. $I$%)": with two `$I$` for three values the maximum filled the crit damage line ("25%") (audit F10; the owner, 2026-10-20; confirmed by the owner, 2026-10-20).
- The character panel and the stats popup show no 5.x Water Hag lines (UI-01, UI-02).

**Slices:** slice 5, verified 2026-10-20 in both trees. Scripted (`gmtest_alch10`: decoctions drunk through `DrinkPreparedPotion`, scripted sword and fist hits on a neutral human test dummy and its hits on Geralt; `GMTest_alch10` in the regression for the data): each decoction's stacks, caps, losses and resets as above; Wyvern unaffected by a fist hit. Seen on screen: Alghoul's and Forktail's HUD percentages (screenshot, both trees). Not real: a real sword attack or sign cast with the decoctions (the cast hook is the cooldown's, verified with real casts in STAM-01).

**Ends:** DMG-03's Mutagen 5 deviation.

**Later:** —

### ALCH-11 Sign decoctions (Foglet, Succubus, Wraith, Ancient Leshen)

| | |
|---|---|
| Kind | system, tuning |
| Pillars | P3, P8 |
| 5.x class | conflict |
| Flags | balance |
| Depends on | DMG-04 (`damage/pool.ws`), DMG-12 (`GMAllyDamage`, `damage/formula.ws`), SKL-11 (Quen, `skills/quen.ws`), SKL-16 (mutagen-slot wrappers, `skills/mutation.ws`), SKL's sign cast states |
| Skill trees | n/a |
| Port form | scope-based overrides of `W3Mutagen09/14/19/22_Effect`; Foglet's sign damage in the pool, its recount in the mutagen-slot wrappers (`OnSwappedMutagensPost` needs one); Succubus in `GMAllyDamage`; Wraith's protective Quen at the top of `GMProcessDamageDecrease`, its Quen power in `GetSignStats`; Ancient Leshen in the sign cast states; 5.x's live terms removed (Ancient Leshen's regen, Wraith's 30% Quen in `mutations/takeDamage.ws`, Succubus's timer in `mutations/combatStart.ws`) |
| Port status | signed off (2026-10-20); **verified** in both trees |
| Open checks | the Succubus puppet bonus; whether the free Quen absorbs the hit; Wraith's exclusions (dodged, parried, damage over time, falls) |
| Save impact | none; Foglet's saved field `gmM09Bonus` (`@addField`, recounted when the decoction is drunk); stack abilities kept by saves |
| NG+ counterpart | applied, untested |

**What it does** (changelist 783–784, 793–794, 809–811, 814–816):
- **Foglet:** +10/17.5/25 base damage to every sign hit per equipped lesser/normal/greater blue mutagen (Synergy does not scale it; per second for damage over time), recounted when mutagens are equipped, removed or swapped. 1.32's +25% intensity in bad weather gone.
- **Succubus:** Axii puppets deal 50% more damage (the puppet's damage limit ×1.5). 1.32's attack power over time gone (5.x's timer is no longer started: `mutations/combatStart.ws`, `decoctionsSigns.ws`).
- **Wraith:** Quen cast for free when Geralt is attacked from behind (not while Quen is up, not for damage over time or falls, not when dodged, parried or countered); +50% Quen power while a hostile specter is near. 1.32's free Quen on a hit of 30% Vitality gone.
- **Ancient Leshen:** each sign cast in combat +10% sign intensity (max 50%, 20 stacks of 0.5%); taking damage removes 0.5% per 1% of Vitality lost; reset at combat end. 1.32's +2 stamina regen per sign gone.

**Implementation (legacy):** `mutagen09.ws` (`RecalcM09Bonus`), `mutagen14.ws` (`GetMutagen14Bonus`), `mutagen19.ws` (`ProtectiveQuen`, `GetQuenPowerBonus`), `mutagen22.ws`; their abilities; `W3PlayerAbilityManager.OnSkillMutagenEquipped/Unequipped`, `OnSwappedMutagensPost`, `ProcessDamageIncrease` (Foglet), `ProcessDamageDecrease` (Wraith), `CalculateDamage` (Succubus), `W3QuenEntity.GetSignStats`, `OnSignCastPerformed`, `CastFreeQuen`; descriptions.

**5.x:** 1.32's rules, live in the port (Ancient Leshen's regen in `skills/signSlots.ws`, Wraith's big-hit Quen in `mutations/takeDamage.ws`, Succubus's attack power in `mutations/combatStart.ws`).

**Decisions:** port as legacy. Port form as planned, in `alchemy/decoctionsSigns.ws` (Foglet's recount wraps the three mutagen-slot functions; Wraith's free Quen is legacy's `CastFreeQuen` as `GMCastFreeQuen`, free through `freeFromBearSetBonus` as ENCH's Warding; legacy's `CActor.IsSpecter` as the global `GMIsSpecter`); Ancient Leshen's sign hook is Wyvern's and Forktail's (`GMDecoctionsOnSignCast`).

- The stats popup's sign lines show Foglet's sign damage bonus and Wraith's Quen intensity (UI-03).

**Slices:** slice 6, verified 2026-10-20 in both trees. Scripted (`gmtest_alch11`, `GMTest_alch11` in the regression): Foglet's bonus by blue mutagens, recounted on equipping and unequipping; Ancient Leshen's stacks, loss and reset; Wraith's free Quen from behind only, not while Quen is up, its intensity bonus near a hostile wraith. A real Igni with a scripted read (`gmtest_alch_probe`): 150 raw fire damage, 175 with Foglet and a greater blue mutagen. Not tested: the Succubus puppet bonus (from the code); whether the free Quen absorbs that same hit.

**Ends:** DMG-04's Mutagen 9 deviation, DMG-12's Succubus deviation, SKL-11's Mutagen 19 deviation.

**Later:** —

### ALCH-12 Sustain and stamina decoctions (ArchGriffin, Troll, Noonwraith, Grave Hag, Ekhidna, Basilisk, Nekker Warrior)

| | |
|---|---|
| Kind | system, tuning |
| Pillars | P2, P8 |
| 5.x class | conflict; overlap (Grave Hag) |
| Flags | balance |
| Depends on | STAM-03 (`GetStaminaActionCost`, `stamina/staminaCosts.ws`), STAM-09 (`GMGetWhirlStaminaCost`), STAM (`DrainStamina`, `stamina/channelStamina.ws`), ENCH-08 (kills, `enchantments/npcDeath.ws`), MUT (`mutations/takeDamage.ws`), SKL-16 (mutagen-slot wrappers) |
| Skill trees | n/a |
| Port form | scope-based overrides of `W3Mutagen04/12/13/18/21/23/25_Effect`; ArchGriffin's and Nekker Warrior's terms in the cost wrapper and Whirl's cost; ArchGriffin's damage in `CActor.OnTakeDamage` (`mutations/takeDamage.ws`), the combat log written after it with it added (`GMLogCombatDamage`, legacy's order); Troll's hook on stamina changes; Noonwraith and Grave Hag in `npcDeath.ws`; Ekhidna in `DrainStamina`; Basilisk's and Nekker Warrior's recounts with Foglet's; 5.x's live terms removed (1.32's ArchGriffin rule, Ekhidna's 10% heals in `channelStamina.ws` and the special-attack code, Noonwraith's short crowd control in `W3EffectManager.OnBuffAdded`, Grave Hag's +10 per kill, Nekker Warrior's horseback attack power and horse panic) |
| Port status | signed off (2026-10-20); **verified** in both trees |
| Open checks | a real kill, attack, sprint or horse ride; Troll's regen (its ability read only); Ekhidna out of combat; Basilisk and Nekker Warrior on unequipping or swapping a mutagen; the combat log's line with ArchGriffin's drain (from the code) |
| Save impact | none; Nekker Warrior's saved field `gmM25Bonus` (`@addField`, recounted when the decoction is drunk); stack abilities kept by saves |
| NG+ counterpart | applied, untested |

**What it does** (changelist 780–782, 789–792, 801–802, 812–813, 817–819, 823–825):
- **ArchGriffin:** fast, strong and counter attacks and Whirl cost +50% stamina; each melee hit takes 0.1% of the victim's current Vitality per stamina point spent on it (Rend by its charge). 1.32's "heavy attacks spend all stamina, −5%" gone.
- **Troll:** +100 regen out of combat, +20 in combat, +80 more in combat at 33% stamina or less.
- **Noonwraith:** each kill +1 combat stamina regen per hostile alive within 30 m (max +10), reset at combat end. 1.32's 0.5 s crowd control gone.
- **Grave Hag:** each kill +5 Vitality regen per hostile alive within 30 m (max +50, in and out of combat), reset at combat end.
- **Ekhidna:** heals 0.1% of maximum Vitality per stamina point spent, in combat, on every stamina drain (sprint, Whirl and channelled signs included). 1.32's 10% per action gone.
- **Basilisk:** +4/8/16 Vitality regen per equipped lesser/normal/greater green mutagen. 1.32's shrine buff at dawn and dusk gone (offset in ALCH-09).
- **Nekker Warrior:** every melee stamina action (attacks, parries, counters, dodges, rolls, sprint, jump; not Whirl or Rend) costs 2.5/3.75/5% less per equipped lesser/normal/greater red mutagen. 1.32's horseback attack power and horse panic immunity gone.

**Implementation (legacy):** `mutagen04.ws`, `mutagen12.ws` (`ManageAdditionalBonus`), `mutagen13.ws`, `mutagen18.ws`, `mutagen21.ws`, `mutagen23.ws` (`AddM23Abilities`), `mutagen25.ws` (`RecalcM25Bonus`); `TrollBonusEffect`, their abilities, `Mutagen_23`; `W3PlayerAbilityManager.OnStaminaChanged` (new), `CalcMutagen04Penalty`, `DrainStamina`, `GetWhirlStaminaCost`, `CActor.OnTakeDamage`, `CNewNPC.OnDeath`, `W3EffectManager.OnBuffAdded`, `OnPerformSpecialAttack`; the horse code (`CNewNPC.GainStat`, `ForceSetStat`, `W3HorseComponent.ShouldUpdatePanic`, the exploration state); descriptions.

**5.x:** 1.32's rules, live in the port; Grave Hag +10 per kill, uncapped.

**Decisions:** port as legacy (`alchemy/decoctionsSustain.ws`; the cost terms in a wrapper of `W3AbilityManager.GetStaminaActionCost` for Geralt's melee actions, Whirl's in `GMGetWhirlStaminaCost`; ArchGriffin's damage in MUT's `CActor.OnTakeDamage` replacement; Ekhidna's heal in STAM's `DrainStamina` replacement, 5.x's `Heal()` emptied for its special-attack callers; the kills in ENCH's `CNewNPC.OnDeath` replacement; the slot decoctions recounted by wrappers of the three mutagen-slot functions; the horse code replaced where 5.x checks Nekker Warrior).

- **Deviation:** Troll's low-stamina bonus stays on while Geralt is in combat at 33% stamina or less, checked at every update of the decoction's effect; legacy switched it on and off at every stamina change while stamina stayed low, so it was on about half the time (the owner's DL12, confirmed by the owner, 2026-10-20).

**Slices:** slice 7, verified 2026-10-20 in both trees. Scripted (`gmtest_alch12`, level 30, a neutral human test dummy; `GMTest_alch12` in the regression for the data): ArchGriffin's costs (the dodge cost read before drinking) and its extra drain (0.1% of the victim's Vitality per stamina point); Troll on at low stamina in combat and still on at the next check (DL12); Noonwraith and Grave Hag stacks per hostile in range (asserted), capped at 10; Ekhidna's heal per stamina point; Basilisk's and Nekker Warrior's slot bonuses. Not real: no real kill, attack, sprint or horse ride.

**Ends:** STAM's hand-offs (ArchGriffin's cost, Mutagen 21's heal, Troll, Nekker Warrior), STAM-09's ArchGriffin line.

**Later:** —

### ALCH-13 Defensive and conditional decoctions (Arachas, Doppler, Fiend, Elemental, Werewolf, Leshen, Griffin, Reliever's)

| | |
|---|---|
| Kind | system, tuning |
| Pillars | P8, P9 |
| 5.x class | conflict; overlap (Leshen, Werewolf, Reliever's) |
| Flags | balance, decided (DL6) |
| Depends on | DMG-01, DMG-02 (`damage/formula.ws`: Arachas, Reliever's), DMG-11 (Leshen, `damage/returned.ws`, already legacy's code), DEF-01 (`defense/dodge.ws`: Griffin), SKL-14 (`skills/oils.ws`: Doppler's crit damage term), ENCH (`OnVitalityChanged` wrapper, `enchantments/invigoration.ws`: Werewolf), MUT (`mutations/takeDamage.ws`) |
| Skill trees | n/a |
| Port form | scope-based overrides of `W3Mutagen02/11/16/20/24/26/27/28_Effect` (class defaults, Werewolf's flags); Arachas's debuff in `GetDamageResists`, its stack in `takeDamage.ws`; Fiend in `CActor.OnTakeDamage`; Griffin in DEF's `W3PlayerWitcher.ReduceDamage` replacement right after `super.ReduceDamage`, as legacy (`defense/dodge.ws`: before Glyph of Warding's Quen); Reliever's in `CActor.ReduceDamage`; Werewolf from the Vitality hook, combat start and end; DLC XML; 5.x's live terms removed (Arachas's carry-weight resistance, Elemental's growing resistance in `GetResistValue`, Griffin's stacking resistances, Reliever's attack power and resistances, Werewolf's free sprint) |
| Port status | signed off (2026-10-20); **verified** in both trees |
| Open checks | Reliever's against a real spectral form and its zero monster bonus, Doppler's crit from behind, Leshen's returned damage; Elemental's resistance after seconds of burning; Griffin's expiry and environment hits; Griffin with Glyph of Warding's Quen (from the code) |
| Save impact | none (expected); stack abilities kept by saves |
| NG+ counterpart | applied, untested |

**What it does** (changelist 777–778, 787–788, 798–800, 817, 820–822, 826–835):
- **Arachas:** an enemy that damages Geralt in melee (not dodged) gets acid: −1% to all its resistances per hit (max −10%). Legacy never removed the stacks from the enemy; the port removes them at the end of Geralt's fight and when the decoction ends (DL12, deviation below). 1.32's resistance by free carry weight gone.
- **Doppler:** +50% crit damage from behind (1.32: +50% damage from behind; the data value moved from mult to add, which makes it work).
- **Fiend:** no hit reaction from hits below 15% of maximum Vitality (damage over time excluded). 1.32's +20 carry weight gone.
- **Elemental:** flat +50% resistance to bleeding, burning and poison effects and to fire and poison damage. 1.32's resistance growing 10% per second gone.
- **Werewolf:** at 20% Vitality or less in combat: +50% attack power and sign intensity, +5 stamina regen, +25% adrenaline gain; off above 20% (then a 10 s cooldown) and out of combat. 1.32's free sprint and jump out of combat gone.
- **Leshen:** 25% of damage taken returned (1.32: 10 + 2%).
- **Griffin:** two hits within 1 s (not environment or damage over time) make Geralt immune to damage for 2 s (counted as dodged, with an effect). 1.32's stacking resistances gone.
- **Reliever's:** against an enemy in spectral form, Geralt's damage is 60% of normal instead of 10%, its damage to him halved. 1.32's attack power and resistances against specters gone.

**Implementation (legacy):** `mutagen02.ws` (`AddDebuffToEnemy`), `mutagen11.ws`, `mutagen16.ws` (`Mutagen16ModifyHitAnim`), `mutagen20.ws`, `mutagen24.ws` (`ManageMutagen24Bonus` and the rest), `mutagen26.ws`, `mutagen27.ws` (`AccumulateHits`, `IsBonusActive`), `mutagen28.ws` (`GetDmgMultiplier`, `GetDmgReduction`); their abilities; `GetDamageResists`, `ProcessActionLeshenMutagenDamage`, `W3Action_Attack.GetPowerStatValue`, `W3PlayerWitcher.ReduceDamage`, `OnTakeDamage`, `OnCombatStart`, `W3PlayerAbilityManager.OnVitalityChanged`, `CActor.OnTakeDamage`, `CActor.ReduceDamage`; descriptions.

**5.x:** 1.32's rules, live in the port; Leshen 10 + 10%; Werewolf adds +50% stamina regen at night in clear weather; Reliever's: any hit on a specter blocks its shadow form, flash step, essence regen and teleport (kept in the port's `damage/pipeline.ws` "for ALCH to decide").

**Decisions:** port as legacy (`alchemy/decoctionsDefense.ws`); DL6 (owner, 2026-10-20): 5.x's Werewolf night regen, Leshen's 10 + 10% and Reliever's specter block are gone. Werewolf's HUD quirk is ported as legacy's (its cooldown branch marks the effect negative twice where neutral was meant; HUD colour only). Arachas and Griffin react once the hit's damage is dealt (after `super.OnTakeDamage`, as legacy's `DealtDamage` checks need). Elemental and Griffin add their ability on Geralt again (`dontAddAbilityOnTarget` false, as legacy; 5.x set it true).

- **Deviation:** the Arachas acid leaves the enemies when Geralt's fight ends and when the decoction ends (the port keeps a list of the enemies it put acid on, not saved); legacy never removed it, so an enemy kept up to -10% resistances for good (the owner's DL12, confirmed by the owner, 2026-10-20).

**Slices:** slice 8, verified 2026-10-20 in both trees. Scripted (`gmtest_alch13`, its hits on Geralt from a neutral human test dummy; `GMTest_alch13` in the regression for the data): Arachas's acid stacks on the enemy, gone at combat end and when the decoction ends; Fiend's hit reaction; Elemental's 50%; Werewolf's threshold and cooldown; Griffin's immunity after two quick hits (with its check in DEF's body). Not tested: Reliever's against a real spectral form, Doppler's crit from behind, Leshen's returned damage (data and code only).

**Ends:** DMG-01's and DMG-02's Mutagen 2 deviations, DMG-02's Mutagen 28 term.

**Later:** Werewolf's HUD flag.

### ALCH-14 Bombs

| | |
|---|---|
| Kind | tuning, system, fix |
| Pillars | P5, P8 |
| 5.x class | overlap |
| Flags | balance, decided (DL7) |
| Depends on | SKL-15, SKL-18 (bomb skills and perks, ported), SKL-06 (non-aimed bombs), ARM-10 (Manticore: bomb crit, ported), DMG-03 (`ProcessCriticalHitCheck`), DMG-04 (`damage/pool.ws`), EFX (frozen, burning, poison, blindness), AI (Silver Dust's monster tasks) |
| Skill trees | n/a |
| Port form | DLC XML (petard abilities given whole, bomb effect abilities in `effects.xml`, NG+); `@replaceMethod`s of `W3Petard.OnProjectileCollision` (shields), `CMonsterNestEntity.PlayerHasBombActivator`, `W3Effect_SilverDust.OnEffectAdded`, the teleport tasks' `IsAvailable`, `CBTTaskWraithDrainDance.Main`; Samum's crit chance in DMG-03's crit check; a frozen target's `hpPercDamageBonusPerHit` (Northern Wind's +25/35/50%) a pool term in `ProcessDamageIncrease` (`damage/pool.ws`, legacy's `dmgBonusMult`; 5.x's separate frost hit removed); 5.x's `potion_duration` bomb-damage readers removed (`damage/pool.ws`, `skills/heavyArtilleryTrickShot.ws`, `criticalDOTEffect`), DL7; tooltip rows |
| Port status | signed off (2026-10-20); **verified** in both trees |
| Open checks | a real bomb's damage and shields (Grapeshot 2 not breaking them; Northern Wind's freeze seen); Northern Wind's bonus in a real sword attack; the nest; the teleport and drain dance rules; the potion-duration removal (from the code) |
| Save impact | none (expected: bomb values are read when thrown) |
| NG+ counterpart | applied: legacy's NG+ petard file equals its regular one (kept, legacy's NG+ values), untested |

**What it does** (changelist 695–729, bugfix 40): bombs are upgraded only by skills and perks, their damage never scales (attack power never applied in 1.32 either; 5.x's potion-duration scaling, below, is new):
- **Grapeshot:** 300/400/500 physical and silver plus 50/100/150 fire; only T3 breaks shields (1.32: T2 and T3).
- **Dancing Star:** 100/150/200 fire on impact, a fire cloud for 3/4/5 s, burning of 1% of health per tick over 3 s (1.32: a flat 20 per 0.3 s on top).
- **Devil's Puffball:** 100/150/200 poison, a cloud for 3/4/5 s (1.32: 10/30/30 s), poison of 1% per tick over 3 s (1.32: 30 flat per 0.3 s).
- **Dragon's Dream:** a gas cloud for 15/20/25 s, 300/400/500 on ignition, 0/50/75% burning chance; at T3 enemies it kills explode for 500 (1.32: 20).
- **Northern Wind (White Frost):** freezes; frozen enemies take +25/35/50% damage (1.32: +5/7/10%); no longer blocks dust clouds and stone throws (its `DustCloud`, `ThrowStone` blocks removed). The frozen effect's own rules (DoT pause, Aard on frozen enemies, no knockdown on the shattering hit: ported by EFX-02 and EFX-03; rotfiends) are EFX's and AI's.
- **Samum:** blinds for 4/5/6 s (1.32: 4/6/8) and gives +50/75/100% crit chance against the blinded enemy (for sword hits, bolts and, with the Manticore set, bombs; 1.32: +100% at T3 only, on the item); no longer blocks hypnosis.
- **Silver Dust (Moon Dust):** 20/30/40 s (1.32: 20/40/permanent); blocks essence regen, doppelgangers, mist and shadow forms, flash step, shapeshifting, swarms, teleport and the full-moon buff; specters cannot teleport; a nightwraith's or noonwraith's drain dance heals 0.05% instead of 0.2%; the effect never stays on Geralt.
- **Monster nests:** the equipped bomb is used to destroy a nest when it can.

**Implementation (legacy):** petard abilities `Grapeshot_*`, `DancingStar_*`, `DevilsPuffball_*`, `DragonsDream_*`, `Samum_*`, `SilverDustBomb_*`, `WhiteFrost_*`; `effects.xml` `BlindnessEffect_Samum_*`, `BurningEffect_DancingStar_*`, `PoisonEffect_DevilsPuffball_*`, `FrozenEffect_WhiteFrost*`, `SilverDustEffect_Level2/3`; `W3Petard.OnProjectileCollision`, `ProcessCriticalHitCheck` (Samum), `CMonsterNestEntity.PlayerHasBombActivator` and `<members>`, `silverDust.ws`, `btTaskTeleport.ws` (three `IsAvailable`), `CBTTaskWraithDrainDance.Main`, `GetItemTooltipAttributes` (cloud duration label); tooltip rows `cloud_duration`, `hpPercDamageBonusPerHit`, `explosionFireDamage`; strings.

**5.x:** Grapeshot 250/450/450, Dragon's Dream 250/300/300 and explosion 15 (both replaced by legacy's own values); Silver Dust's item blocks six more abilities directly; Northern Wind blocks `PoisonDeath` (a rotfiend fix); Samum T3 +100% crit (the port's Manticore code reads it); a throw range clamp, water effects, `isFromBomb` on bomb damage over time; **potion duration raises bomb damage** (impact, damage over time and critical damage over time). The port removes these readers (DL7, slice 9): the Manticore gear's potion duration no longer raises bomb damage.

**Decisions:** port as legacy (`alchemy/bombs.ws`, data from `gen_alch.py`). DL7 (owner, 2026-10-20): potion duration no longer raises bomb damage (5.x's three readers removed), only Grapeshot T3 breaks shields, legacy's Samum, Silver Dust and Dimeritium, 5.x's Northern Wind `PoisonDeath` block kept (a `KEEP_5X` change in `gen_alch.py`). DL11 (owner, 2026-10-20): Samum 4/5/6 s. Samum's crit bonus is read in `GetCriticalHitChance` (`skills/oils.ws`) as the larger of it and confusion's, where the port already had confusion's; legacy took the larger of the two in `ProcessCriticalHitCheck` for Geralt's hits, so swords, bolts and the Manticore set's bombs get it as in legacy. With legacy's bomb poison and burning (1% of health per tick, no flat part), Heavy Artillery's doubling of the flat part (SKL-18) has nothing to double, as in legacy.

- The frozen effect's rules (no knockdown on the shattering hit, Aard's 5% force damage on frozen enemies) are legacy's, ported by [EFX-02](efx.md#efx-02-hitting-a-frozen-enemy).
- **Deviation:** 5.x's other bomb changes legacy never saw are kept: the throw range clamp, the water effects, `isFromBomb` on bomb damage over time (the potion-duration bonus it carried is removed; it still gates the new tree's Heavy Artillery doubling, `skills/heavyArtilleryTrickShot.ws`, SKL's) (porter's call, confirmed by the owner, 2026-10-20).

- **Deviation:** Samum 3's text (`item_desc_samum_3`, 5.x's "The first hit landed on a blinded opponent is always critical.", which legacy kept) says "Increases critical hit chance against blinded opponents." (string 2110992637, the vanilla key), in the 9 languages, the 8 non-English ones translated by the port, where legacy had none (audit F12; the owner, 2026-10-20; the translations porter's call, confirmed by the owner, 2026-10-20). Samum 1 and 2 keep 5.x's texts.

**Slices:** slice 9, verified 2026-10-20 in both trees. Scripted (`GMTest_alch14`, in the regression): every bomb's data; Silver Dust does not stay on Geralt; Samum 1/2/3 blindness 4/5/6 s on a test dummy and Geralt's crit bonus (`gmtest_alch14_samum`). A real Northern Wind throw with a scripted read (`gmtest_alch14_throw`, `_thrown`) and scripted freezes of all three tiers (`gmtest_alch14_frozen`): ×1.25/1.35/1.5 on the next hit, no separate frost hit. `GMIsWildHuntMinion` on a dummy given `mon_wild_hunt_minion` (`gmtest_alch15_minion`). Not tested in game: the other bombs thrown (damage, shields), the nest, the teleport and drain dance rules, the potion-duration removal (from the code).

**Later:** —

### ALCH-15 Dimeritium bomb

| | |
|---|---|
| Kind | system, tuning |
| Pillars | P5 |
| 5.x class | conflict |
| Flags | balance |
| Depends on | DMG-02 (`GetDamageResists`, `damage/formula.ws`), DMG-05 (`GMProcessDamageModification`, `damage/pipeline.ws`), the effect framework (`effects/gmEffectTypes.ws`, `gmEffectRegistration.ws`), AI (Wild Hunt minions, the djinn) |
| Skill trees | n/a |
| Port form | `alchemy/dimeritium.ws`: the GM effect type `EET_GMDimeritium` (class `W3GMEffect_Dimeritium`, legacy's `W3Effect_DimeritiumEffect`; enum extension and registration in `effects/`, its effect name with a level suffix mapped too), `@replaceMethod`s of `W3Dimeritium.LoopFunction` and `ProcessTargetOutOfArea` (W3Petard's, as legacy) and of `BTTaskManageDjinnRage.Main` and `OnListenedGameplayEvent`, a wrapper of `IsNegativeEffectType`; the armor and resistance terms in `GetDamageResists` (`damage/formula.ws`), the mage term in `GMProcessDamageModification` (`damage/pipeline.ws`); DLC XML from `gen_alch.py` (`DwimeritiumBomb_1–3` given whole, legacy's `DimeritiumEffect_Level1–3` as `GMDimeritiumEffect_Level1–3`), the effect and icon in `gm_effects.xml`, the label string; the bomb entity's cloud ranges by binary edit (`cr2w_patch.py`, floats inside structs and in the template's compiled copy) |
| Port status | signed off (2026-10-20); **verified** in both trees |
| Open checks | a real Wild Hunt minion or mage, the djinn task, the minions' essence regen pause, the elementals' blocked abilities; a save and reload under the effect |
| Save impact | none (expected) |
| NG+ counterpart | applied, untested |

**What it does** (changelist 724–729): everything in the cloud gets a Dimeritium effect for 20/30/40 s (the cloud itself lasts 5/10/15 s; 1.32's blocks lasted while in the cloud plus 5 s at T3). On Geralt it blocks every sign and ends Quen. Monsters' magic abilities are blocked (wave, ground slam, spawned arena, fire throw, frost, sign attacks); magic creatures and Wild Hunt minions lose 50/75/100 armor and 5/10/15% resistance, and minions their essence regen; mages deal Geralt 30/40/50% less damage but keep their magic; the djinn gets no rage from bombs; Wild Hunt portals close (as 1.32). The cloud is smaller (impact range 6 → 4, cloud 6 → 3: not in the changelist).

**Implementation (legacy):** `dimeritiumEffect.ws` (new class: `<members>`, `GetDamageReduction`, `GetArmorPiercing`, `GetResistReduction`, `OnEffectAdded`, `OnEffectRemoved`, `BlockAbilities`), `dimeritium.ws` (`LoopFunction`; `ProcessTargetOutOfArea` commented out), `IsNegativeEffectType`, the three `gameEffectManager.ws` registrations, `GetDamageResists` and `ProcessDamageModification` terms, `btTaskManageDjinnRage.ws`; data `DwimeritiumBomb_*`, `DimeritiumEffect_Level1–3`, effect and icon; `petard_dimeritium_bomb.w2ent`; tooltip rows `duration_out_of_cloud` (unused), `dbomb_*`; strings 2110992239, 343–347, 456, 480.

**5.x:** 1.32's bomb, with `ablMagic` added to the blocked abilities.

**Decisions:** port as legacy; 5.x's `ablMagic` block is part of the item's direct blocks legacy replaced by the effect: dropped with them (DL7). Wild Hunt minions are found by their abilities (`mon_wild_hunt_minion`, `_minionMH`, `_lesser`, `_weak`), the ones legacy's `GetEnemyTypeByAbility` (a legacy helper not in the port) tested. The effect's added XML entries carry the `GM` prefix (`GMDimeritiumEffect`, its abilities `GMDimeritiumEffect_Level1–3`: an effect ability's name starts with its effect's). On Geralt the effect also blocks the new tree's own alternate Igni and Axii skills (`S_Magic_s28`, `S_Magic_s31`; both trees). The binary edit sets both copies of the template (legacy edited only the compiled copy the game reads; no play difference). What the target is (magic creature, minion, mage) is worked out again after a load (legacy kept it in unsaved fields set when the effect was added).

**Slices:** slice 10, verified 2026-10-20 in both trees. Real bomb throws with a scripted read (`gmtest_alch15_throw`, `_check`): a Dimeritium bomb 3 gives a golem 5 m away the effect (40 s) and not Geralt (outside the 4 m impact range; 5.x's 6 m would reach him); bombs thrown 2.5 m away give both the effect and block a real Igni until it ends. Scripted (`gmtest_alch15`, `GMTest_alch15` in the regression): the armor and resistance cut on a magic creature, the effect ending at once on a plain human, a mage's damage halved, every sign of both trees blocked and unblocked; `gen_alch.py --verify` checks the binary file is 5.x's plus exactly the two range edits. Not tested in game: a real Wild Hunt minion or mage, the djinn task, the minions' essence regen pause, the elementals' blocked abilities (from the code).

**Ends:** DMG-02's and DMG-05's Dimeritium deviations (ended).

**Later:** —

### ALCH-16 Oils

| | |
|---|---|
| Kind | tuning, fix |
| Pillars | P8 |
| 5.x class | clean; overlap (Hanged Man's Venom's silver tag) |
| Flags | balance, decided (DL9) |
| Depends on | SKL-14 (oil effects, decay, Poisoned Blades, Protective Coating, Fixative, Hunter Instinct, ported), ARM-09 (Wolven set, ported), DMG-02 (`GetDamageResists`), UI (the oil tooltip's stats, ARM-09's deviation) |
| Skill trees | n/a |
| Port form | `alchemy/oils.ws`: `@replaceMethod`s of the three `MonsterCategoryTo*` functions in `types.ws` (`MC_Troll` → `vsOgre_*`); a wrapper of `CInventoryComponent.GiveItemTo`, `@addMethod GMRemoveAllOilAbilitiesFromItem`; DLC XML from `gen_alch.py` (the 36 oil abilities and Hanged Man's Venom's three items given whole, NG+); the 36 tooltip rows in the `tooltip_settings.csv` override; the values read by SKL-14's code (`skills/oils.ws`, `damage/formula.ws`); strings with ALCH-17 |
| Port status | signed off (2026-10-20); **verified** in both trees |
| Open checks | a real sword hit with an oil; 5.x's auto-oil; an older save's stuck oil; the oils' own texts on screen (read from the tooltip as built); the 36 oil names not checked against the data in the regression; the transfer check (`gmtest_alch16_transfer`) is not in the regression |
| Save impact | none (expected: oil values are read from the oil effect); an oil stuck on a sword from an older save stays until the sword changes hands (changelist 27–29) |
| NG+ counterpart | applied, untested |

**What it does** (changelist 585–589, bugfixes 41–42; values from the code): every oil tier gives +25% attack power against its monster type (1.32: +10/25/50%); T2 and T3 add +5% crit chance, T3 +25% crit damage; no resistance reduction (1.32's T3 node was empty, so 0 there too; legacy left a 0.15 value commented out). The Ogroid oil's attributes are renamed `vsOgre_*` and the monster-category lookup maps ogroids to them. Oils on a sword are removed when it moves to another inventory (the stuck-oil fix). Descriptions say "Effectiveness decreases with oil rubbing off the blade" (SKL-14's decay).

**Implementation (legacy):** `def_item_alchemy_oils.xml` 36 abilities `BeastOil_1` … `VampireOil_3`, `HangedManVenom_*`; `types.ws` `MonsterCategoryToCriticalChanceBonus`, `MonsterCategoryToCriticalDamageBonus`, `MonsterCategoryToResistReduction` (a change inside name literals only: in `units.csv` since `change_units.py` compares literals, 2026-10-20); `CInventoryComponent.GiveItemTo`, `RemoveAllOilAbilitiesFromItem`; `W3TooltipComponent.AddOilInfo`; 36 tooltip rows; strings 2110992034–070, 192–230, 234.

**5.x:** 1.32's values (Hanged Man's Venom 1 gave +10% before ALCH-16), Hanged Man's Venom tagged for silver swords too; 5.x's auto-oil option and re-applying a brewed oil of a higher tier (kept by DMG; DL9); no stuck-oil fix.

**Correction to DMG's hand-off:** the oils' resistance reduction is 0 in 1.32, legacy, 5.x and the port alike (the "flat 0.25" in [dmg.md](dmg.md#dmg-02-armor-and-resistance-rules) is the oils' attack power); DMG-02's temporary deviation on it changes nothing in play.

**Decisions:** port as legacy; DL9 (owner): Hanged Man's Venom on steel swords only (5.x's `SilverOil` tag dropped), 5.x's auto-oil and re-apply kept. The stuck-oil fix wraps `GiveItemTo` with legacy's conditions (a non-singleton sword, a transfer that is allowed) and removes the oils before 5.x's transfer. Consistency: SKL-14's code reads the new crit chance and crit damage values (wearing off with the oil, as its attack power), ARM-09's Wolven bonuses come on top (per oil, unchanged); the ogroid oil now gives its crit values against ogroids (5.x's lookup found none).

- A sword's oil line in the tooltip (the oil's name and charges; its bonuses in the oil's own tooltip) is legacy's (UI-06).

**Slices:** slice 11, verified 2026-10-20 in both trees. Real oil applications (`W3PlayerWitcher.ApplyOil`) with a scripted read against a neutral test dummy (`gmtest_alch16`): Ogroid oil 1/2/3 against a troll and Hanged Man's Venom 1/2/3 against a human +25% attack power each, +0/5/5% crit chance, +0/0/25% crit damage; Hanged Man's Venom refused on the silver sword; an oiled sword given away arrives without the oil (`gmtest_alch16_transfer`). `GMTest_alch16` (regression): the data, the `vsOgre_` names, the tags. Not tested in game: a real sword hit with an oil, 5.x's auto-oil, an older save's stuck oil.

**Ends:** DMG-02's oil deviation (no play difference), SKL-14's open check in part (a fresh oil's crit chance and crit damage verified; their wearing off stays an open check of SKL-14's), SWD's and ARM's oil hand-offs (ended).

**Later:** —

### ALCH-17 Alchemy tooltips and descriptions

| | |
|---|---|
| Kind | ui |
| Pillars | P7 |
| 5.x class | conflict (5.x rewrote `GetPotionAttributesForTooltip`) |
| Flags | — |
| Depends on | every ALCH feature (their values), UI (layout, the recipe book), ITEM (`GMFindAttrInTooltipSettings`), ENCH-17 (item tooltip), SKL-13 (`AddItemStats` toxicity line) |
| Skill trees | n/a |
| Port form | `alchemy/tooltips.ws`: `@replaceMethod` of `GetPotionAttributesForTooltip` (legacy's: by name), `@addMethod`s `GMGetPotionAttributesByName`, `GMGetBombAttributesForTooltipByName`, `GMFillInMutagenDescription`, `…ByName`, `…FromBuffType` (legacy's `FindAttrInTooltipSettings` is ITEM's `GMFindAttrInTooltipSettings`); wrappers of `W3TooltipComponent.GetBaseItemData` (bomb stats, decoction description), `AddBuffStats` (a potion's duration as drunk), `CInventoryComponent.GetItemTooltipAttributes` (a bomb's cloud duration) and `W3GuiPlayerInventoryComponent.GetCraftedItemInfo` (the alchemy menu); legacy's descriptions by name key in the `GetBaseItemData` wrapper with `@addMethod GMItemHasRecyclingParts` (legacy's `ItemHasRecyclingParts`); wrappers of `W3TooltipComponent.AddItemStats` and the global `CalculateStatsComparance` (the units); legacy's 144 ALCH strings in the nine languages (`modGhostMode` tables: the potion, decoction, bomb and oil descriptions and attribute names of ALCH-04 to ALCH-17); the tooltip rows in the `tooltip_settings.csv` override |
| Port status | signed off (2026-10-20); **verified** in both trees |
| Open checks | the menus and tooltips on screen (the flash objects read); the strings in the other eight languages; a book's, key's and quest item's description by name key in play |
| Save impact | none |
| NG+ counterpart | none |

**What it does** (bugfixes 62–63, 101–102): potion and bomb tooltips list every effect, in the inventory, shops, the alchemy menu and the recipe book (by name); resistances and adrenaline gain as percentages; White Raffard T3's immunity; Blizzard's slow motion and Killer Whale's breath attributes named; decoction tooltips show their values (`$S$`/`$I$` filled from the data) and explain the toxicity offset; decoction stacks shown in the buff tooltip; the potion duration attribute named.

**Implementation (legacy):** `CInventoryComponent.GetPotionAttributesForTooltip`, `GetPotionAttributesByName`, `FillInMutagenDescription`, `FillInMutagenDescriptionByName`, `FillInMutagenDescriptionFromBuffType`, `GetBombAttributesForTooltip`, `GetBombAttributesForTooltipByName`, `FindAttrInTooltipSettings`; `W3GuiBaseInventoryComponent.GetAlchemyBookText`, `W3GuiPlayerInventoryComponent.GetCraftedItemInfo`, `W3TooltipComponent.GetBaseItemData`, `AddBuffStats`; tooltip row `potion_duration`; string 2110992015. The descriptions of each potion, decoction, bomb and oil are attributed to their features (ALCH-04 to ALCH-16), about 120 rows × 9 languages.

**5.x:** `GetPotionAttributesForTooltip` rewritten (Reinald's Philtre, Cat's crit chance); the rest 1.32's.

**Decisions:** port as legacy, values from the ported features; layout and the recipe book are UI's. Reinald's Philtre (5.x's, DL10) gets legacy's generic handling. The decoction description replaces 5.x's text of the item in the tooltip's description, so lines other wrappers add (ITEM-12's buff line) stay.

The description lookup by name key (the owner, 2026-10-20): legacy's whole lookup is ALCH's: an item that is not armor, a weapon, horse gear, a decoction, a decoction's recipe or a Gwent card shows the text of `item_desc_<x>` for its name key `item_name_<x>` when that key exists (the 36 oils, Cat 3's hypnosis line, and the books, keys and quest items changelist 41 restored), junk without recycling parts legacy's "Can be sold to merchants." (2110992259), anything else 5.x's text; the text replaces 5.x's in the description, so other wrappers' lines stay. The units (the owner, 2026-10-20), as legacy's `AddItemStats` and `CalculateStatsComparance`: a bomb's cloud, Dimeritium's out-of-cloud and Golden Oriole's immunity durations in seconds, a decoction's toxicity offset under its own name (2110992381) with no "/max"; done by wrappers that rewrite the rows those functions build (one row per stat, in order).

- A potion's toxicity line shows the value after Expert Brewer without "/max", and the offset line after Adaptation (UI-06, legacy's `AddItemStats`); the recipe book's text and a recipe item's tooltip are legacy's (UI-08).

**Slices:** slice 12, verified 2026-10-20 in both trees. Scripted, the tooltips as the game builds them (`gmtest_alch17_tooltips`, `gmtest_alch17_crafted`, `gmtest_alch17_texts`: `GetBaseItemData` on items in Geralt's inventory and the alchemy menu's `GetCraftedItemInfo`): the bombs', potions' and decoctions' lines and values, the oils' and Cat 3's own texts, durations in seconds, "Toxicity offset 70". `GMTest_alch17` (regression): every potion attribute path, all 28 decoction descriptions filled, the bomb effects' values, the attribute names, each changed key resolving to the row that must win, the oils' texts by name key. Not seen on screen: the rendered panels; the strings in the other eight languages (copied from legacy's tables by id); a book, key, quest item or junk item's description.

Two more of legacy's tooltip changes (whole-port audit C1-3, C1-5, 2026-11-03), in `alchemy/tooltips.ws`:
- **Bomb damage with skills** (C1-3; legacy's `GetItemBaseStats` and `GetItemTooltipAttributes`, units SKL-15 and SKL-18 carry): with Pyrotechnics (`alchemy_s10`, both trees) a bomb's tooltip lists physical and silver damage of 50 per level (new tree 83.33), added to any it already has, even for a bomb without them (Samum 1 at level 1: 50 and 50); with Heavy Artillery (classic `perk_20`, new tree `perk_43`) every damage line is doubled, the Pyrotechnics part included (Samum 1 with both: 100 and 100; Dancing Star 1's fire 100 → 200). As in legacy the missing lines are added only in the item tooltip (`GetItemBaseStats`); the other stat lists (preparation menu, loot popup) get the doubling only. Code: a `GetItemBaseStats` wrapper flags the call, the existing `GetItemTooltipAttributes` wrapper calls `GMAddBombSkillDamage`.
- **Deviation:** the Snow Ball's tooltip gets no Pyrotechnics damage: the skill does not raise its damage (5.x's and legacy's `W3Petard` skip it), and legacy's tooltip listed it anyway (porter's call, confirmed by the owner, 2026-11-03).
- **A decoction's toxicity offset by name** (C1-5; legacy's `GetItemStatsFromName`): in the recipe book, the alchemy menu and shops the offset is named "Toxicity offset", as legacy; 5.x names it "Toxicity" (a `GetItemStatsFromName` wrapper).

Verified 2026-11-03 in both trees (scripted, `GMTest_alch17_offset` and `GMTest_alch17_bombskills` in the regression; each failed first on a throwaway build without the code). Not seen on screen.

**Ends:** STAM's tooltip hand-off (potion and decoction tooltips).

**Later:** —

### ALCH-18 Alchemy debug commands

| | |
|---|---|
| Kind | infra |
| Pillars | — |
| 5.x class | clean |
| Flags | — |
| Depends on | — |
| Skill trees | n/a |
| Port form | `alchemy/debugCommands.ws` (legacy's names, outside `tests/`, as ENCH's) |
| Port status | signed off (2026-10-20); **verified** in both trees |
| Open checks | — |
| Save impact | none |
| NG+ counterpart | none |

**What it does:** `addalchemy1/2/3` give every potion, bomb and oil of a tier; `adddecoctions` every decoction; `toggledebugoils` logs the oils' bonuses (`modSigns_debug_oils` fact).

**Implementation (legacy):** `console_debug.ws` `addalchemy1`, `addalchemy2`, `addalchemy3`, `adddecoctions`, `toggledebugoils`.

**Decisions:** port as legacy's console commands (every item with full charges).

- **Deviation:** `toggledebugoils` (a log of the oils' bonuses in legacy's oil effect) is not ported: SKL-14's oil code was rewritten for the port and its tests (`gmtest_skl14_oil`, ALCH-16's `gmtest_alch16`) read the same values (porter's call, confirmed by the owner, 2026-10-20).

**Slices:** slice 12, verified 2026-10-20: `addalchemy3()` and `adddecoctions()` run from the console give the items (`gmtest_alch18`).

**Later:** —

---

### Dependencies on other areas

- **ALCH builds on:** SKL-13 to SKL-18 (the alchemy skills and perks, `skills/brewing.ws`, `oils.ws`, `bombs.ws`, `mutation.ws`, `grasses.ws`), MUT-08, MUT-09, MUT-12, MUT-13 (`mutations/toxicity.ws`, `combatStart.ws`, `takeDamage.ws`), DMG (the damage functions hosting the decoction, oil, Golden Oriole, Petri and Dimeritium terms), STAM (stamina costs and drains), ARM-09, ARM-10, ARM-11, ARM-15 (Wolven, Manticore, Viper, Netflix), ENCH-08, ENCH-09 (`npcDeath.ws`, potion timers), ITEM (`GMFindAttrInTooltipSettings`).
- **Shared with:** EFX (frozen, burning, poison, bleeding, blindness), AI (monster abilities Silver Dust and Dimeritium block, rotfiends, the djinn, Wild Hunt minions), UI (tooltip layout, the toxicity panel, the oil tooltip, the recipe book, legacy's descriptions by name key for books, keys and quest items), CRAFT, LOOT, ECON, WGT, FOOD (recipes, availability, prices, weights, edibles), XP (monster nest experience), FIX (`FixQuestItems`).

### Save impact

None expected for a new playthrough: potion, decoction, bomb and oil values are read from the definitions when used. Facts for the port and the release notes:
- Decoction stacks and buffs are abilities on Geralt that a save keeps (Katakan, Water Hag, Alghoul, Forktail, Ancient Leshen, Griffin stacks, Nightwraith's, 5.x's Werewolf night ability): a save made mid-decoction before the port may carry 5.x's: a load-time cleanup removes them on every load (`alchemy/decoctionCleanup.ws`, slice 8). 5.x's Basilisk shrine bonus is a shrine effect, not an ability: a save made before the port keeps it until its 6 game hours run out.
- Saved fields added: Foglet's `gmM09Bonus`, Nekker Warrior's `gmM25Bonus` (recounted on load); potion stacking writes the summed duration into the saved `initialDuration`; Golden Oriole T3's immunity timer is not saved but the immunity is, so after a reload it lasts until the potion ends (legacy's quirk).
- Class hierarchies stay 5.x's (`W3RegenEffect`'s `stat` is saved): Swallow's fix replaces methods, not the base class.
- Oils stuck on a sword from an older save stay until the sword changes hands.

Adding or removing the mod mid-playthrough is not supported ([save compatibility](../feature-mapping.md#save-compatibility)).

### Area decisions

Decided by the project owner (2026-10-20). Legacy behaviour first applies where 5.x did not change the subject.

| # | Question | Decision |
|---|---|---|
| DL1 | Overdose threshold (ALCH-01) | Legacy's 75%, with legacy's decay: the same in and out of combat (no ×1.1) |
| DL2 | Decoction toxicity offset (ALCH-09) | Legacy's 70 for all 28 decoctions, Basilisk included |
| DL3 | Potion durations (ALCH-03) | Legacy's code and data: Thunderbolt, Petri's Philtre, Maribor Forest 30/60/90 s, Swallow 30 s. The changelist's 60/120/180 s are the values with Prolonged Effects maxed |
| DL4 | Blizzard and Cat (ALCH-07) | Legacy's Blizzard (3 s slow motion after kills, legacy's values, no finishers while it runs); legacy's Cat (hypnosis immunity at T3 only, no 5.x crit chance) |
| DL5 | Golden Oriole T3 (ALCH-05) | 5.x's poison healing removed (the Viper set heals instead, ARM-11); legacy's resistance and 5 s immunity |
| DL6 | 5.x's changes to decoctions legacy reworked (ALCH-10 to 13), White Honey (ALCH-04) | Legacy's versions (Grave Hag, Werewolf without the night regen, Reliever's without the specter block, Katakan's 5%, Leshen, Forktail, and the rest); White Honey keeps 5.x's `SetToxicityOffset(0)` as well as legacy's `CumulateWith` |
| DL7 | Bombs (ALCH-14, ALCH-15) | Potion duration no longer raises bomb damage (5.x's three readers removed: the impact pool term, the bomb DoT, the critical DoT); only Grapeshot T3 breaks shields; legacy's Samum, Silver Dust and Dimeritium (no `ablMagic` block on mages, legacy's mage damage cut instead; no direct Silver Dust blocks); 5.x's Northern Wind `PoisonDeath` block kept (the rotfiend fix) |
| DL8 | The boundary | As in [Scope](#scope) |
| DL9 | Oils (ALCH-16) | Hanged Man's Venom on steel swords only (5.x's `SilverOil` tag dropped); 5.x's auto-oil option and brew re-apply kept |
| DL10 | Reinald's Philtre | 5.x's values under Ghost Mode's rules (no double regen) |
| DL11 | Samum's blindness | Legacy's code: 4/5/6 s |
| DL12 | Legacy's bugs | Fixed to their evident intent, each a deviation confirmed by the owner: Troll's bonus stays on while the condition holds; the Arachas debuff stacks are removed from enemies; potion stacking never swaps a stronger dose for a weaker one. The rules chosen are in the entries (ALCH-02, ALCH-12, ALCH-13). Also: a load-time cleanup of 5.x's runtime decoction stacks and abilities |
