# ALCH: alchemy (potions, decoctions, bombs, oils, toxicity)

Everything Geralt brews and uses: the toxicity bar and overdose, potions and how they combine, the 28 mutagen decoctions, bombs, blade oils, and their tooltips and descriptions. Ghost Mode reworked all of it so that "alchemy is now vital on higher difficulties to buff your character in combat and/or control groups of enemies" (changelist 674–679): potions stack instead of being replaced and are cheaper in toxicity, decoctions were all reworked ("some retain the vanilla idea behind their effect, some were redone from scratch, because they were useless", 773–775) and all cost 70 toxicity, bombs got fixed damage that "never scales with anything" and clearer roles (695–729), oils got crit chance and crit damage at higher tiers (585–589 with the Wolven set), and the overdose threshold is a fixed 75% (384–386). Sources: the changelist's Alchemy section (674–835), the skills paragraph on toxicity (384–386), the bugfix list (lines 62–186: decoctions and overdose, White Raffard, White Honey, Swallow and Tawny Owl regen, Blizzard, Northern Wind, oils stuck on swords, pheromone and Pops' Antidote sounds), and the code, which has more than the changelist (Golden Oriole's level 3, Dimeritium's mechanics, the decoction details below).

Alchemy is a large part of every build's power: balance it with [balance.md](balance.md) (rules B9 "alchemy effects stay where they are" and the overdose row) and the [alchemy ledger](ledger/alchemy.md), which tabulates every potion and decoction in 1.32, legacy and 5.x, the access timing of formulas and mutagens, the toxicity system and the build cornerstones.

**What 5.x did in this area** (from `vanilla-5.x`, unverified in game). The overdose threshold fell from 75% to 50% (`TOXICITY_DAMAGE_THRESHOLD` 0.50001), toxicity decays ×1.1 out of combat (1.32: ×2), and the toxicity head effects were rebuilt in five steps. Decoctions lock 50 toxicity instead of 70 (Basilisk keeps 40 and its long duration); Katakan +10% crit (1.32: 5%), Grave Hag +10 regen per kill (5), Leshen 10 + 10% returned (2%), Werewolf adds stamina regen at night in clear weather, Forktail counts light and heavy attacks as separate actions, Reliever's blocks a specter's shadow form on any hit. Potions: Blizzard reworked into a continuous, weaker slow motion in combat (8/10/12 s, time ×0.8/0.7/0.6, not after kills), Cat gains +5/7/10% crit chance, toxicity changed on Black Blood and Golden Oriole (25), Killer Whale (15), Blizzard (20), White Raffard (25); White Honey also clears the locked decoction toxicity; Reinald's Philtre added (a quest potion, `mq1060`). Bombs: Grapeshot 250/450/450 (1.32: 350/600/600), Dragon's Dream 250/300/300 and its explosion 15 (300/400/400, 20), Dimeritium also blocks `ablMagic`, Silver Dust blocks six more monster abilities directly, Northern Wind blocks `PoisonDeath`; **potion duration bonuses now raise bomb damage** (impact and damage over time; new in 5.x). Oils: a silver tag on three oils. Skills that feed alchemy changed too (SKL-13 to SKL-17, ported as legacy).

**How legacy Ghost Mode implements it.** Data: `def_item_alchemy_potion.xml` (toxicity, duration, charges), `effects_potions.xml` (potion effects), `def_item_alchemy_mutagens.xml` and `effects_mutagens.xml` (decoctions), `def_item_alchemy_petards.xml` and the bomb effects in `effects.xml`, `def_item_alchemy_oils.xml`, all with NG+ copies; 49 rows of `tooltip_settings.csv`; about 120 description strings in 9 languages. Scripts: the toxicity effect (`toxicity.ws`), the potion effects (`effects/potion/*.ws`), one script per decoction (`effects/mutagens/mutagenNN.ws`, most rewritten), hooks for the decoctions in the player, damage, stamina and sign code, a new `W3Effect_DimeritiumEffect`, the bomb and potion tooltips in `inventoryComponent.ws`, and the oil removal on item transfer.

Unit lists: [attribution.csv](attribution.csv): mapped 2026-10-20 from the changelist, the hand-offs of DMG, STAM, SKL, MUT, ARM, ENCH, SWD and ITEM, and sweeps (`unit_sweep.py` for toxicity, potion, decoction, mutagen, bomb, petard, oil and every potion, bomb and decoction name; a field-by-field comparison of every unit in the alchemy item and effect files, master against `legacy-GM` and `vanilla-5.x`): 2,017 units carry an ALCH feature (272 script units, 182 XML units and their 212 NG+ copies, 1 binary file, 45 tooltip rows, 1,305 string rows: 145 strings × 9 languages); 68 of the script units are shared with other features (DMG, SKL, STAM, MUT, ARM, ENCH hold the functions; ALCH adds its terms). Units whose only change is a weight, price, recipe ingredient or loot entry are left to WGT, ECON, CRAFT and LOOT ([hand-off](#hand-off-to-other-areas)). Port status: **signed off** by the project owner (2026-10-20, ALCH-01 to ALCH-18); **ported** (all 12 slices done and verified in both trees, 2026-10-20; [port order](#port-order)); audited 2026-10-20 ([ALCH audit](#alch-audit-2026-10-20)): fix slices A to D done and verified in both trees (5.x-GM `3ee751ab`, `eef6c32e`, `1f7e26d2`, `861a3217`), the audit closed ([close-out](#audit-close-out)); the [area decisions](#area-decisions) made by the owner (2026-10-20).

## Scope

**ALCH covers** toxicity and overdose; the rules every potion follows (stacking, when Geralt can drink, durations); every potion's values and special effects; the decoction rules (toxicity offset, duration) and all 28 decoctions; bombs' values and effects, including Dimeritium and Silver Dust; oils' values, their tooltip rows and the stuck-oil fix; the alchemy tooltips and descriptions; the alchemy debug commands.

**Not ALCH** (porter's call from the docs, for the owner to confirm with DL8):

| Subject | Area | Why |
|---|---|---|
| The alchemy skills (Brewing, Oil Preparation, Bomb Creation, Mutation, Trial of the Grasses) and the alchemy perks (Metabolism Boost, Metabolic Control, Advanced Pyrotechnics, In Combat's Fires) | SKL (signed off) | Ported with SKL-13 to SKL-18: potion duration from Prolonged Effects, decoctions without duration bonuses, Expert Brewer, Adaptation, Tissue Transmutation, oils wearing off, Fixative, the non-aimed bomb penalty, own bombs not halved |
| The Mutation Catalyst (potion, recipe, effect) | MUT-12 (signed off) | Ported with Life Leech |
| Manticore and Netflix gear's potion duration on potions; Viper's poison healing | ARM (signed off) | Ported (ARM-10, ARM-15, ARM-11); what remains for ALCH is listed in [hand-offs received](#hand-offs-received) |
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
| Port status | **signed off** (2026-10-20); **ported** (slice 1, 5.x-GM `ad3f4dec`), verified in both trees |
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

**Verification (slice 1, 2026-10-20, both trees):** scripted (`GMTest_alch01`, in the regression): the threshold reads 0.75 (the param and `GetToxicityDamageThreshold`); adding locked toxicity starts the toxicity effect at once and removing it ends it (5.x left the effect running). Scripted in time (`gmtest_alch01_set/_tick`, toxicity set by script): decay 0.5 per second out of combat and in combat (a spawned wolf), the same rate; overdose damage at 80% toxicity (161 Vitality in 9.7 s) and none at 70% out of combat. Not real: no potion or decoction drunk (slice 2 drinks them), the head effects not watched.

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
| Port status | **signed off** (2026-10-20); **ported** (slice 2, 5.x-GM `86483235`), verified in both trees |
| Open checks | the refusal message |
| Save impact | none (expected) |
| NG+ counterpart | none (scripts) |

**What it does** (changelist 732–735): potions, but not decoctions, stack: drinking a potion that is active adds its duration (time left and total) instead of replacing it (the effect's own `CumulateWith` runs: Swallow and White Raffard stop bleeding, White Honey clears toxicity again, ALCH-04); decoctions refresh. Geralt cannot drink during a special sword attack (Whirl, Rend) or while channelling a sign.

**Implementation (legacy):** `CBaseGameplayEffect.GetSelfInteraction` (cumulate for potion effects that are not decoctions; 1.32 cumulated only with Side Effects), `CBaseGameplayEffect.CumulateWith`; `W3PlayerWitcher.DrinkPotionFromSlot` (the combat-action check; attributed to SKL-18 for its Connoisseur part). Also in legacy, inert: an Alchemy Table effect (Blood and Wine's `effects_ep2.xml`, 60 minutes) that no script applies.

**5.x:** 1.32's (replace; drink at any time). 5.x's Netflix set adds potion duration (ARM-15, ported). The port's potion duration (potions only, Prolonged Effects, Netflix) is SKL-13's and ARM-15's, done.

**Legacy's quirks:** `OnEffectAdded` does not run again on a stacked dose, so Maribor Forest T3's adrenaline point and Full Moon T3's heal come only with the first dose (ported as legacy). The stacking test compares effect strength, which is equal for every tier of most potions (0 for those without a main value in legacy: Swallow, Tawny Owl, Cat, Maribor Forest; Thunderbolt's tiers too, in the game; Golden Oriole's is the sum of its resistances, so its tiers differ), so any two doses of those cumulate, and legacy's ability swap let a lower tier replace a higher one: fixed (DL12, below).

**Decisions:** port as legacy. The Alchemy Table effect is dropped: inert in legacy (no script or resource names it), no behaviour to carry (porter's call, confirmed by the owner, 2026-10-20).

- **Deviation:** potion stacking never swaps a stronger dose for a weaker one: when a dose cumulates with the running effect, the durations add up and the effect keeps the higher of the two tiers (`GetBuffLevel`, from the effect's ability name); a higher tier still raises it. Doses of different strength keep legacy's rule (the stronger replaces the running effect, a weaker one is refused). Legacy swapped the ability to the new dose's tier, so a lower tier drunk on a higher one lowered it (the owner's DL12, confirmed by the owner, 2026-10-20).

**Verification (slice 2, 2026-10-20, both trees):** scripted (`GMTest_alch02`, in the regression; drunk through `DrinkPreparedPotion`): Thunderbolt 1 twice 30 → 60 s; Thunderbolt 3 on it raises the tier and adds 90 s (150 s); Thunderbolt 1 on tier 3 adds 30 s and tier 3 stays (DL12); Cat 1 on Cat 3: 480 → 720 s, tier 3 kept, only `CatEffect_Level3` on Geralt; Cat 3 on Cat 1 raises it; a second Cockatrice decoction refreshes (1800 s, no stacking). Real actions with a scripted read: drinking refused during a real Whirl (scripted input, `gmtest_stam02_press`) and a real Firestream (`autocast`), allowed afterwards (`gmtest_alch02_cannot`); the refusal message and a real drink from the quick slot not seen.

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
| Port status | **signed off** (2026-10-20); **ported** (slice 2, 5.x-GM `86483235`; Blizzard's data with ALCH-07, Swallow's, White Raffard's, White Honey's and Golden Oriole's with ALCH-04 and ALCH-05), verified in both trees |
| Open checks | no potion's effect measured in a fight; NG+ (policy: not tested) |
| Save impact | none (expected: potion values are read from the definitions when drunk) |
| NG+ counterpart | applied (legacy's NG+ files), untested |

**What it does** (changelist 738–770): toxicity, duration, charges and effect values per tier. Thunderbolt 20 toxicity, +25/30/35% attack power; Petri's Philtre 20, +25/30/35% sign intensity; Maribor Forest 20, +15/20/25% adrenaline gain; Tawny Owl 15, 60 s at every tier; Full Moon 30, 90/120/150 s, +900/1300/1700 Vitality; Black Blood 30, 60/90/120 s, 10/15/20% returned; Blizzard 25, 30 s, time ×0.5/0.35/0.25 after a kill; Cat 10, 240/360/480 s. Full table in the [ledger](ledger/alchemy.md#1a-potions).

**Implementation (legacy):** `def_item_alchemy_potion.xml` abilities `BlackBlood_*`, `Blizzard_1/2`, `Cat_*`, `FullMoon_*`, `PetriPhiltre_*`, `TawnyOwl_*`, `Thunderbolt_*`; `effects_potions.xml` `BlackBloodEffect_*`, `BlizzardEffect_Level2/3`, `FullMoonEffect_*`, `MariborForestEffect_Level2/3`, `PetriPhiltreEffect_*`, `ThunderboltEffect_Level1`; NG+ copies (Full Moon's NG+ Vitality 1300/1700/2100).

**5.x:** Black Blood toxicity 25 (legacy 30), Blizzard toxicity 20 at every tier and 8/10/12 s with ×0.8/0.7/0.6 (legacy left Blizzard 3 and the toxicity at 1.32's 25 and 30 s, ×0.5); the rest 1.32's.

**Decisions:** port legacy's values, also on fields legacy left at 1.32's and 5.x changed (Blizzard's toxicity, Blizzard 3's duration and its slow motion), legacy behaviour first. DL3 (owner, 2026-10-20): the durations of legacy's code and data (Thunderbolt, Petri's Philtre, Maribor Forest 30/60/90 s, Swallow 30 s); the changelist's 60/120/180 s are the values with Prolonged Effects maxed.

**Verification (slice 2, 2026-10-20, both trees):** scripted (`GMTest_alch02`, in the regression): held potions read legacy's toxicity and duration (Thunderbolt 20, 30/90 s; Petri's Philtre 20, 60 s at T2; Full Moon 30, 90/150 s; Black Blood 30, 120 s at T3; Cat 10, 480 s at T3; Tawny Owl 15, 60 s); `gen_alch.py --verify` for every listed entry, regular and NG+. Not real: no potion's effect measured in a fight.

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
| Port form | `alchemy/swallowHoneyOriole.ws`: scope-based overrides of `W3Potion_Swallow` (`OnEffectAdded`, `CumulateWith`), `W3Potion_WhiteRaffardDecoction` (`dontAddAbilityOnTarget`, `CacheSettings` dropping its `SwallowEffect` override, `CumulateWith`), `W3Potion_WhiteHoney` (`CumulateWith`), `W3Potion_Swallow` and `W3Potion_ReinaldPhiltre` (`GetEffectStrength` 0, legacy's strength: audit F1); `@replaceMethod` of `W3Potion_VitalityRegen.OnUpdate` zeroing the effect's own regen (the base class `W3RegenEffect` cannot change: its `stat` is saved) and of `W3Potion_WhiteRaffardDecoction.OnEffectAdded`; DLC XML (`gen_alch.py`) |
| Port status | **signed off** (2026-10-20); **ported** (slice 3, 5.x-GM `89a09d41`), verified in both trees |
| Open checks | no real bleeding. (Tawny Owl's regen counted twice was settled by ALCH-07: its own regen is zeroed) |
| Save impact | none (expected) |
| NG+ counterpart | applied, untested |

**What it does** (changelist 736–738, 752–754, 765–766; bugfixes 85, 89–90, 96–100): Swallow 15 toxicity, 30 s, +40/65/80 regen, +20/35/50% bleeding resistance, stops bleeding on every dose; its regen is a plain ability bonus (1.32's `W3Potion_VitalityRegen` started a second regen effect that read tier 1 and doubled itself); T3's regen not paused on hit (1.32, kept). White Raffard's Decoction (a potion) 25 toxicity, 2 charges at every tier, heals 35/60/100% of maximum Vitality without first raising it (1.32 multiplied maximum Vitality by the same share), every dose heals, stops bleeding, no longer cancels Swallow. White Honey 2/3/4 charges; every dose clears toxicity and potions, also a repeated one.

**Implementation (legacy):** `Swallow.ws` (`OnEffectAdded`, `CumulateWith`), `potionVitalityRegen.ws` (Swallow's and Tawny Owl's base class emptied: `<members>`, `CacheSettings`, `OnEffectAdded`, `OnLoad`, `OnUpdate`), `WhiteRaffardDecoction.ws` (`<members>`, `OnEffectAdded`, `CumulateWith`, `AddVitality`), `WhiteHoney.ws` (`OnEffectAdded`, `CumulateWith`, `CleanupToxicity`); data: `Swallow_*`, `WhiteRaffardDecoction_*`, `WhiteHoney_*`, `SwallowEffect_*`, the `WhiteRaffardDecoctionEffect` override of `SwallowEffect` removed; NG+ (Swallow's and White Raffard's NG+ values set to the regular ones: legacy's own NG+ values, kept by the NG+ rule).

**5.x:** 1.32's scripts; White Raffard toxicity 25; White Honey also sets the locked toxicity (decoction offset) to 0 when drunk.

**Decisions:** port as legacy. White Honey: the owner's DL6 (2026-10-20) keeps 5.x's reset of the locked toxicity (`SetToxicityOffset(0)`) as well as legacy's `CumulateWith`. Reinald's Philtre (5.x's quest potion, DL10): 5.x's values; its own regen effect is zeroed as Swallow's, so its stamina regen counts once, through its ability (the owner's "no double regen").

- **Deviation:** White Honey also resets the locked decoction toxicity, on every dose (5.x's addition; legacy's White Honey left it) (the owner's DL6, confirmed by the owner, 2026-10-20).

- **Deviation:** string 2110992178 (Swallow 3's text without the bleeding line) no longer carries the key `item_desc_swallow_3`: legacy gave the key to two rows, so which text showed was not defined; 2110992539, the full text, now owns it (audit F9; the owner, 2026-10-20; confirmed by the owner, 2026-10-20).

**Verification (slice 3, 2026-10-20, both trees):** scripted (`GMTest_alch04`, in the regression; drunk through `DrinkPreparedPotion`): Swallow 15 toxicity, 30 s, T3 bleeding resistance 50%; a bleeding effect (added by script) removed by Swallow and by a second Swallow; White Raffard 1 heals 35% (700 → 1925 of 3500) with maximum Vitality unchanged, Swallow kept, a second dose heals again and stops bleeding; T3 2 charges, White Honey T3 4; a second White Honey clears toxicity and locked toxicity again. Scripted in time (`gmtest_alch_regen_a/_b`, Vitality set to 20% out of combat): Geralt's base 1/s, with Swallow 1 41/s, Swallow 3 81/s (once, legacy's 40/80; 5.x counted it twice); Reinald's Philtre's own regen effect reads 0 (`gmtest_alch_regenvals`), its ability feeds Geralt's regen (from the code). Not real: no potion drunk from the quick slot, no real bleeding.

**Verification (audit fix slice A, 2026-10-20, both trees; audit F1):** real drinks from the first potion slot (`gmtest_alch04_slot`: the potion equipped there by script, then `OnPotionDrinkKeyboardsInput`, what the slot's key calls), each dose in its own call a few seconds after the last: Swallow 1 (30 s); Swallow 3 on it: tier 3, 20.2 → 50.2 s; Swallow 1 on that: tier 3 kept, 42.4 → 72.4 s (classic tree; new tree: Swallow 3, then Swallow 1 on it: tier 3, 22.2 → 52.2 s). Scripted in the regression (`GMTest_alch04` drinks Swallow 1; `GMTest_alch04_after`, in `gmtest_panel()`, the next call): the running dose has updated (its own regen value 0, the state in which a new dose replaced it before the fix), Swallow 3 on it raises it to tier 3 and adds 30 s, Swallow 1 on that keeps tier 3 and adds 30 s.

**Verification (audit fix slice D, 2026-10-20, both trees; audit F9, F17):** Swallow 3's tooltip as built shows 2110992539's text (`gmtest_alch17_texts`), its key resolves to that row (`GMTest_alch17_texts`, in the regression). White Raffard's Decoction's three effect abilities are now generated by `gen_alch.py` (5.x-GM `861a3217`): in NG+ they heal 35/60/100% as in the regular game, legacy's values (`gen_alch.py --verify`: no difference, 204 listed entries; the two NG+ entries no longer listed as differing). NG+ not run in game (the policy).

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
| Port status | **signed off** (2026-10-20); **ported** (slice 3, 5.x-GM `89a09d41`), verified in both trees |
| Open checks | poison damage with Golden Oriole 3 active (the healing's removal is from the code) |
| Save impact | none (expected) |
| NG+ counterpart | applied, untested |

**What it does** (changelist 746–750): 15 toxicity, 60/90/120 s; +20/35/50% poison resistance instead of immunity; every dose cures poison; T3 also gives 5 s of poison immunity. Poison no longer heals Geralt at T3 (the Viper set does that, ARM-11).

**Implementation (legacy):** `GoldenOriole.ws` (`OnEffectAdded`, `CumulateWith`, `HandlePoisonStatus`, `OnEffectRemoved`), `CActor.RemoveGoldenOriolePoisonImmunity`, `CActor.ReduceDamage` and `W3DamageManagerProcessor.ProcessActionDamage` (the T3 absorption removed), `W3QuenEntity.AddBuffImmunities` (Golden Oriole's line removed); data `GoldenOriole_*`, `GoldenOrioleEffect_*`; tooltip row `poison_immunity_duration`; strings.

**5.x:** 1.32's immunity and T3 absorption, toxicity 25. The port keeps the absorption ahead of Viper's healing (DMG-05's temporary deviation).

**Decisions:** port as legacy; DL5 (owner, 2026-10-20): 5.x's absorption removed, as legacy did.

- **Deviation:** Golden Oriole's buff text (`effect_GoldenOrioleEffect_desc`, 5.x's "Immunity to poison.", which legacy kept) is legacy's item text, "Increases poison resistance, neutralizes the effects of poisons already in bloodstream." (string 2110992638, the vanilla key), in the 9 languages; Czech, German, French and Italian translated by the port, where legacy's item row is English (audit F12; the owner, 2026-10-20; the translations porter's call, confirmed by the owner, 2026-10-20).

**Verification (slice 3, 2026-10-20, both trees):** scripted (`GMTest_alch04`, in the regression): 15 toxicity, poison resistance 35% at T2, immunity 5 s at T3; a poison effect (added by script) cured by Golden Oriole 1, which gives no immunity; Golden Oriole 3 makes Geralt immune at once, the immunity gone when the potion ends. Scripted in time (`gmtest_alch05_timer_a/_b`): 6 s after drinking Golden Oriole 3, poison takes again while the potion runs. Not tested in game: poison damage with T3 active (the healing's removal is from the code).

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
| Port status | **signed off** (2026-10-20); **ported** (slice 4, 5.x-GM `b3e7da72`), verified in both trees |
| Open checks | knockdown, confusion and puppet durations (the same code path as burning) |
| Save impact | none (expected) |
| NG+ counterpart | none |

**What it does** (changelist 759–760): with Petri's Philtre at T3, sign effects last a third longer: heavy knockdown, confusion, Axii's puppet and burning ×1.34 (after resistances), Yrden's trap and Quen's shield durations by the same bonus.

**Implementation (legacy):** `CBaseGameplayEffect.CalculateDuration` (DMG-07's unit), `W3YrdenEntity.GetSignStats` and the Yrden units SKL-10 noted (`<members>`, `GetCachedYrdenPower`, `DisablePreviousYrdens`), `W3QuenEntity.GetSignStats`; 1.32's own T3 term in `W3EffectManager.GetSignApplyBuffTest` commented out; the description string.

**5.x:** none (1.32's `GetSignApplyBuffTest` term).

**Decisions:** port as legacy. 1.32's level-3 term in `GetSignApplyBuffTest` was already removed with SKL-09 (`skills/igni.ws`).

**Verification (slice 4, 2026-10-20, both trees):** scripted (`gmtest_alch06_burn`): a sign burning effect (added by script with Geralt as creator) on a neutral human test dummy lasts 2.915 s, 3.907 s with Petri's Philtre 3 (×1.34). Real casts with a scripted read (`autocast`, `gmtest_alch06_signs`): Quen's shield 30 → 40.2 s and Yrden's trap 7.5 → 10.05 s with Petri's Philtre 3. Not real: no knockdown, confusion or puppet measured (the same code path).

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
| Port form | `alchemy/otherPotions.ws`: `@replaceMethod` of `W3Potion_Blizzard.KilledEnemy` and `OnTimeUpdated` with 1.32's bodies, of `W3Effect_Hypnotized.OnUpdate`; scope-based overrides of `W3Potion_TawnyOwl` (its own regen zeroed) and `W3Potion_MariborForest` (`CacheSettings` dropping the Well Hydrated override); Blizzard T3's free actions in a scope-based override of `W3PlayerAbilityManager.GetStaminaActionCost` (legacy's override, ahead of 5.x's cost and every Ghost Mode term; `alchemy/staminaCostInternal.ws`, audit F4), removed from `GetStaminaActionCostInternal`; Tawny Owl's `GetEffectStrength` 0 (audit F1); the finisher rule already in SKL-12's `ProcessActionReaction`; Tawny Owl's hours in ENCH-09's replacement; legacy's Blizzard and Cat data (`gen_alch.py`) |
| Port status | **signed off** (2026-10-20); **ported** (slice 4, 5.x-GM `b3e7da72`), verified in both trees (Cat's hypnosis rule from the code) |
| Open checks | Cat's hypnosis rule (from the code); a kill in a real fight starting Blizzard (a scripted kill through the game's death path seen, audit F5); Tawny Owl at night; Blizzard 3's free actions in a real Whirl, Rend or blocked hit (scripted drains only, audit F4) |
| Save impact | none (expected) |
| NG+ counterpart | applied (data), untested |

**What it does** (changelist 739, 744–745, 755–756, 763–764, 767–768; bugfix 135): Blizzard slows time after a kill (×0.5/0.35/0.25) and no finisher starts while it does; at T3 actions are free during the slow motion only with 3 adrenaline points (1.32 checked for 1). Cat grants hypnosis immunity at T3 only (1.32: from T2). Tawny Owl T3 never expires at night (rewritten timer). Maribor Forest no longer cancels Well Hydrated. Black Blood returns damage that attack power does not scale.

**Implementation (legacy):** `W3DamageManagerProcessor.ProcessActionReaction` (no finisher while Blizzard's slow motion runs), `W3PlayerAbilityManager.GetStaminaActionCost`, `GetStaminaActionCostInternal` (Blizzard's T3 moved), `W3Effect_Hypnotized.OnUpdate`, `W3Potion_TawnyOwl.OnTimeUpdated`, `ProcessActionBlackBloodReturnedDamage` (`CPS_Undefined`; DMG-11's unit), the `MariborForestEffect` override removed; data and descriptions.

**5.x:** Blizzard reworked: from drinking, the slow motion runs whenever Geralt is in combat with targets or under attack, 8/10/12 s, ×0.8/0.7/0.6, with a screen effect; kills no longer start it. Cat +5/7/10% crit chance and a screen effect shared with Blizzard. Tawny Owl's timer touched: it freezes while the hour is at or before dawn, legacy's while before dawn or from dusk on (the port's ENCH-09 replacement is 5.x's body). Blizzard T3's free actions need Battle Trance in 5.x. **In the port today** 5.x's Blizzard runs with legacy's finisher rule (SKL-12): no finishers at all while 5.x's potion lasts.

**Decisions:** DL4 (owner, 2026-10-20): legacy's Blizzard (3 s slow motion after kills, legacy's values, no finishers while it runs) and legacy's Cat (hypnosis immunity at T3 only, no crit chance). Tawny Owl: legacy's night rule and legacy's single regen (legacy turned it into a plain effect fed by its ability; the port zeroes its own regen effect, the base class cannot change).

- **Deviation:** Blizzard T3's free actions are legacy's (3 adrenaline points, no 5.x Battle Trance condition, every stamina drain free, fixed drains such as Whirl's, Rend's, a blocked hit's and Quen's included, checked first in `W3PlayerAbilityManager.GetStaminaActionCost` as legacy did; audit F4), but 5.x's Mutation 7 toxicity denial stays in front of them (porter's call, confirmed by the owner, 2026-10-20: Blizzard 3 without Battle Trance).
- **Deviation:** Cat's and Blizzard's 5.x screen effects (the cat view settings, Blizzard's 5.x-only blue tint, shown while legacy's 3 s slow motion after a kill runs: audit F5, 5.x-GM `861a3217`) are kept: cosmetic, no rule depends on them (porter's call, confirmed by the owner, 2026-10-20: keep 5.x's visuals for the effects).

**Verification (slice 4, 2026-10-20, both trees):** scripted (`GMTest_alch07`, in the regression): Blizzard 25 toxicity, 30 s, ×0.5 and ×0.25; no slow motion before a kill, a kill (`KilledEnemy` called by script) starts it; with Blizzard 3 and 3 adrenaline a light attack costs 0 during the slow motion, with 2 adrenaline 6.67; Cat T3 without crit chance; Maribor Forest drunk with Well Hydrated active keeps both; Tawny Owl's ability on Geralt. Scripted in time, in combat with a wolf (`gmtest_alch07_blizzard_a/_b`): the time scale 0.5 for the slow motion, back to 1 after it, and it does not restart while the fight goes on (5.x's would). Not verified in game: Cat's hypnosis rule (a scripted hypnosis on Geralt did not behave as a monster's: from the code, `== 3` for 5.x's `>= 2`); a real kill starting Blizzard; Tawny Owl at night.

**Verification (audit fix slice A, 2026-10-20, both trees; audit F4):** scripted (`GMTest_alch07`, in the regression): with Blizzard 3, its slow motion started by `KilledEnemy` and 3 adrenaline, a fixed drain of 20 (`DrainStamina(ESAT_FixedValue, ...)`, a blocked hit's path) and half a second of Whirl (`GMWhirlDrainResources`, Whirl's drain) take no stamina; with 2 adrenaline the fixed drain takes 20 and a light attack 6.67. Not real: no Whirl, Rend or block performed.

**Verification (audit fix slice D, 2026-10-20, both trees; audit F5, F7, F8):** scripted: Blizzard's screen effect on after a kill and off with the potion (`GMTest_alch07`, in the regression); the test dummy killed by script with Geralt as the killer (`gmtest_alch07_blizzard_kill`: the game's death path, ENCH's `OnDeath`, calls `KilledEnemy`): slow motion and tint on at once, both off 8 s later (`gmtest_alch07_blizzard_b`); seen on screen in the classic tree (a screenshot during the slow motion: 5.x's cat-view effect over the scene; at the test save's sunrise it reads as a bright yellow-white wash rather than blue). The texts (5.x-GM `861a3217`): Cat 1's item text and Cat's buff text are 5.x's first sentence, without "Increases critical hit chance." (strings 2110992633, 634 with the vanilla keys), Blizzard 1's is legacy's tier-2 text and Blizzard 3's that text plus 5.x's sentence on 3 adrenaline points (2110992635, 636); Czech translated by the port for tiers 1 and 3, where legacy had none (legacy's tier-2 row stays English; porter's call, confirmed by the owner, 2026-10-20); read by key in the regression and as the tooltips build them (`gmtest_alch17_texts`). Not seen: the texts on screen; the tint at another time of day.

Not in legacy's code: Cat's "+25 to range of vision" and Black Blood's T2 stagger and T3 bleeding (changelist 745, 768) are vanilla 1.32's.

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
| Port status | **signed off** (2026-10-20); **ported** (slice 2, 5.x-GM `86483235`), verified in both trees |
| Open checks | the drinking sounds not heard; a grizzly bear not met |
| Save impact | none (expected) |
| NG+ counterpart | applied, untested |

**What it does** (changelist 737–743; bugfixes 148–149): pheromone potions 10 toxicity, 120 s, quality 4 (1.32: 2 to 4); their recipes are of the quest type (shown with quest items, not counted as potion formulas); the bear pheromone's effect cleaned up; every pheromone and Pops' Antidote plays the drinking sound. Killer Whale 10 toxicity, 180 s, one tier (1.32's file defined Killer Whale twice, the second time with tiers 2 and 3 that no item uses; legacy commented the second set out). Pops' Antidote 10 toxicity.

Why quest type: legacy's Acquired Tolerance counts potion, bomb, oil, substance and decoction formulas only (`IsAlchemy18Recipe`), so the pheromones add no maximum toxicity; the port's SKL-16 recount counts potion formulas, so today they do.

**Implementation (legacy):** `PheromonePotion*_1`, `KillerWhale_1` (both), `KillerWhale_2/3`, `PopsImmunity`; effects `PheromoneEffect*` (sound), `FactPotion` (sound); `PheromoneBear.ws` (`OnEffectAdded`, `OnEffectRemoved`: grizzly bears befriended too); recipes `Recipe for Bear/Drowner/Nekker Pheromone Potion 1` (`cookedItemType` quest; their ingredients are CRAFT's).

**5.x:** Killer Whale 15 (both definitions), the drowner pheromone's sound; otherwise 1.32's.

**Decisions:** port as legacy (Killer Whale 10, quality 4 for the pheromones: ITEM's hand-off). The drinking sound comes from class defaults: an effect's first `<effects>` definition wins, so a DLC cannot add the attribute; the result is legacy's.

- **Deviation:** the pheromone formulas stay potion formulas in the alchemy menu (legacy made them quest formulas): a DLC cannot override `<alchemy_recipes>`; Acquired Tolerance skips them by name, which is what the quest type did in play (porter's call, confirmed by the owner, 2026-10-20).

**Verification (slice 2, 2026-10-20, both trees):** scripted (`GMTest_alch02`, in the regression): Killer Whale 10 toxicity and 180 s (5.x defines it twice; the override wins), the pheromones 10 toxicity, 120 s, quality 4, Pops' Antidote 10; a drunk bear pheromone makes grizzly bears friendly, hostile again when it ends. Not real: the sounds not heard, no grizzly met.

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
| Port status | **signed off** (2026-10-20); **ported** (offset data slice 1, 5.x-GM `ad3f4dec`; Nightwraith, Ekimmara and the load-time cleanup slice 8, `0646ce16`), verified in both trees |
| Open checks | Cockatrice and Chort in play (Chort scripted only, audit F3); the load-time cleanup on a real load with Elemental, Basilisk or Foglet running |
| Save impact | none (expected: the offset is read when drunk) |
| NG+ counterpart | applied, untested |

**What it does** (changelist 773–775): every decoction locks 70 toxicity (its offset) for 30 minutes, Basilisk included (1.32: 40 and about 96 minutes); decoctions get no duration bonus and do not stack (ALCH-02, SKL-13). The four decoctions legacy left in effect as they were: Cockatrice (+1 charge to bombs and potions), Chort (stagger immunity), Ekimmara (life leech, data rewritten to the same 10%), Nightwraith (+50 Vitality per kill; a new dose wipes the stacks). The tooltip explains the toxicity offset.

**Implementation (legacy):** `def_item_alchemy_mutagens.xml` `Mutagen_23` (offset 70, the extra 3960 s commented out; the other 27 items unchanged at 1.32's 70); `effects_mutagens.xml` custom effects (start sounds, only in the NG+ file: NG+-only change); `Mutagen07Effect`; `mutagen06.ws` (`CumulateWith`); strings 2110992381–382, 188, 246, 477.

**5.x:** the offset of the 27 items lowered to 50 (Basilisk 40, 96 minutes): a change on items legacy never touched, which therefore replaces legacy's 70 unless the port overrides it.

**Decisions:** DL2 (owner, 2026-10-20): legacy's 70 for all 28, Basilisk included. Weight is WGT's (`CommonMutagenAbility` keeps 5.x's).

**Verification (slice 1, 2026-10-20, both trees):** scripted (`GMTest_alch01`, in the regression): all 28 decoction abilities read `toxicity_offset` 70, Basilisk's (`Mutagen_23`) extra duration 0, the decoctions' 1800 s; `gen_alch.py --verify` against legacy's data, regular and NG+.

**Verification (slice 8, 2026-10-20, both trees):** scripted (`GMTest_alch13`, in the regression): a second Nightwraith decoction wipes its stacks (3 → 0); Ekimmara's 10% life leech; the load-time cleanup (`GMCleanupDecoctionAbilities`, run on every load by an `OnSpawned` wrapper) removes leftover Wyvern stacks, Griffin's stacked abilities and Werewolf's night ability and puts back the abilities that belong on Geralt (Elemental, Griffin, Basilisk's copies; the putting back is from the code: the test checks the removal with no decoction running, audit F24). The decoctions' start sounds are 5.x's already (legacy added them only in NG+: nothing to port). Cockatrice and Chort as 1.32 and 5.x.

**Verification (audit fix slice C, 2026-10-20, both trees; audit F3):** scripted (`GMTest_alch09_chort`, in the regression): with Chort's decoction a heavy knockdown added to Geralt leaves him staggered (no knockdown), a knockdown too, a stagger is denied. The conversion sits at the top of SKL-11's `InternalAddEffect` wrapper (`skills/quen.ws`), so Quen's rules see a stagger, as in legacy (alternate Quen denies it without breaking, the basic shield denies it and breaks). Not real: no enemy's knockdown attack.

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
| Port form | `alchemy/decoctionsMelee.ws`: scope-based overrides of `W3Mutagen01/05/10/17_Effect` (`dontAddAbilityOnTarget`, `OnEffectRemoved`), `@addMethod`s (legacy's `Manage*`, `Add*`, `Remove*`, `GetStacks` with the `GM` prefix), `@replaceMethod` of `W3Mutagen15_Effect.OnEffectAdded`/`OnEffectRemoved` and `W3Mutagen17_Effect.OnUpdate`/`OnLoad`; hooks: a wrapper of `W3PlayerWitcher.OnProcessActionPost` and `OnCombatFinished`, the sign-cast point `GMAddSignCooldown` (`stamina/signCooldowns.ws`, every player cast), MUT's `OnTakeDamage` replacement (`mutations/takeDamage.ws`); 5.x's live 1.32 terms removed (Water Hag's full-Vitality term in `GetAttackersPowerMod`, Alghoul's combat-start ability in `mutations/combatStart.ws`, Wyvern's and Alghoul's loss on any hit, Forktail's boost; Wyvern's per-hit add taken back by a `CNewNPC.OnTakeDamage` wrapper); HUD counters (`extraValue`, shown by the HUD's format 4 with the six decoctions in its condition: audit F13) in MUT-14's `UpdateBuffs` replacement; DLC XML (`gen_alch.py`) |
| Port status | **signed off** (2026-10-20); **ported** (slice 5, 5.x-GM `b80771ad`), verified in both trees |
| Open checks | a real sword attack or sign cast with the decoctions; fist hits of Katakan and Water Hag (Wyvern's scripted, audit F18); the HUD percentages of Katakan, Water Hag, Wyvern and Ancient Leshen on screen (Alghoul's and Forktail's seen); Katakan's stacks: once, in the new tree, the first Katakan test after a regression run showed 0 stacks after three sword hits; a second run passed and it could not be reproduced, so watch for it |
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
- The character panel and the stats popup no longer show 5.x's Water Hag lines (the offense list since UI-01, the crossbow's headline value since UI-02, 2026-10-21, 5.x-GM `8dad0e47`): the temporary deviation has ended.

**Verification (slice 5, 2026-10-20, both trees):** scripted (`gmtest_alch10`: decoctions drunk through `DrinkPreparedPotion`, scripted light sword hits of Geralt's on a neutral human test dummy and its scripted hits on him, in combat and threatened): Katakan no stack when drunk, 3 hits 3 stacks, capped at 5 with the crit damage bonus (HUD 25%), a crit resets it; Water Hag 20 stacks (+10%) per hit, a hit for 5% of Vitality takes 5 off, capped at 200 (+100%), gone with the decoction; Wyvern: a melee hit adds nothing, two sign casts (the hook called) 2 stacks (HUD 33%), a hit clears them; Alghoul: no ability when drunk in combat, 20 stacks per hit, damage taken takes 5 off; Forktail: two hits 2 stacks (HUD 20%), a sign cast clears them; combat end clears all. `GMTest_alch10` (regression): the stack data. Not real: no real sword attack or sign cast with the decoctions (the cast hook is the cooldown's, verified with real casts in STAM-01); the HUD counters not seen on screen.

**Verification (audit fix slice C, 2026-10-20; audit F13, F24):** seen on screen (a screenshot of the HUD; `gmtest_alch10_hud`: Alghoul and Forktail drunk, three scripted sword hits on the test dummy): both icons show "30%" next to their timers, in both trees. Scripted (`gmtest_alch10`, classic tree): Alghoul capped at 100 stacks after 120 hits, Forktail at 5 after 12.

**Verification (audit fix slice D, 2026-10-20, both trees; audit F18):** scripted (`gmtest_alch10`, a neutral human test dummy): Wyvern with two sign stacks, then a fist hit of Geralt's (his fists item as the weapon; melee, 7 damage): 2 stacks (the hit neither clears them nor adds 5.x's stack). In the new tree the first `gmtest_alch10` run after the regression reported Katakan with 0 stacks after 3 sword hits; a second run passed every check; not reproduced (Katakan's code untouched by this slice).

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
| Port status | **signed off** (2026-10-20); **ported** (slice 6, 5.x-GM `5497dd03`), verified in both trees |
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

- The stats popup's sign lines show Foglet's sign damage bonus and Wraith's Quen intensity since UI-03 (2026-10-21, 5.x-GM `52db5ef7`): the temporary deviation has ended.

**Verification (slice 6, 2026-10-20, both trees):** scripted (`gmtest_alch11`, level 30, a neutral test dummy): Foglet +0 without blue mutagens, +25 with a greater blue mutagen equipped by script (recounted on equipping), +0 after unequipping; Ancient Leshen 20 stacks (+10%) per sign cast (the hook called), a hit for 5% takes 5 off, combat end clears it. Real cast with a scripted read (damage probe, `gmtest_alch_probe`): a real Igni on the dummy deals 150 raw fire damage, 175 with Foglet and a greater blue mutagen (+25 before the pool). Wraith (`gmtest_alch11_wraith_place/_hit`, the dummy's scripted hits): no Quen against a hit from the front, a free Quen against one from behind, no second while Quen is up; the Quen intensity bonus 0.5 with a live wraith hostile nearby, 0 with only a wolf. `GMTest_alch11` (regression): the data. In the new tree at level 1 Foglet's slot check has no unlocked slot (the rest passed). Not tested: the Succubus puppet bonus (from the code); whether the free Quen absorbs that same hit (the test hit is direct damage, which Quen lets through).

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
| Port form | scope-based overrides of `W3Mutagen04/12/13/18/21/23/25_Effect`; ArchGriffin's and Nekker Warrior's terms in the cost wrapper and Whirl's cost; ArchGriffin's damage in `CActor.OnTakeDamage` (`mutations/takeDamage.ws`), the combat log written after it with it added (`GMLogCombatDamage`, legacy's order; audit F16); Troll's hook on stamina changes; Noonwraith and Grave Hag in `npcDeath.ws`; Ekhidna in `DrainStamina`; Basilisk's and Nekker Warrior's recounts with Foglet's; 5.x's live terms removed (1.32's ArchGriffin rule, Ekhidna's 10% heals in `channelStamina.ws` and the special-attack code, Noonwraith's short crowd control in `W3EffectManager.OnBuffAdded`, Grave Hag's +10 per kill, Nekker Warrior's horseback attack power and horse panic) |
| Port status | **signed off** (2026-10-20); **ported** (slice 7, 5.x-GM `76928461`), verified in both trees |
| Open checks | a real kill, attack, sprint or horse ride; Troll's regen (its ability read only); Ekhidna out of combat; Basilisk and Nekker Warrior on unequipping or swapping a mutagen; the combat log's line with ArchGriffin's drain (audit F16, from the code) |
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

**Verification (slice 7, 2026-10-20, both trees):** scripted (`gmtest_alch12`, level 30, a neutral human test dummy, decoctions drunk through `DrinkPreparedPotion`): ArchGriffin light attack 6.67 → 10 stamina, dodges unchanged; a scripted light hit takes 21.5 Vitality without and 1023 with it (`gmtest_alch12_griffin`: 0.1% of the dummy's 100000 per stamina point); Troll on at 20% stamina in combat and still on at the next check (DL12), off at full stamina; a kill (the hook called) adds a Noonwraith and a Grave Hag stack per hostile in range, Grave Hag capped at 10 (+50); Ekhidna: 20 stamina spent (`DrainStamina`) heals 107.6 of 5380 (0.1% per point); Basilisk 4 copies (+16 regen) with a greater green mutagen in a slot; Nekker Warrior dodge 5 → 4.75 with a greater red one. `GMTest_alch12` (regression): the data. Not real: no real kill, attack, sprint or horse ride; Troll's regen measured by its ability only.

**Verification (audit fix slice C, 2026-10-20, classic tree; audit F24):** scripted (`gmtest_alch12`, level 30, a neutral human test dummy): ArchGriffin's dodge cost read before drinking, 5 → 5 with it (the old check compared the cost with itself); its hit's extra drain 999.6 = the dummy's 99,970.8 Vitality left × 0.1% × 9.999 stamina (asserted), none once the decoction ends; one hostile in range for the kill checks (asserted); Noonwraith capped at 10 stacks, Grave Hag at 10.

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
| Port form | scope-based overrides of `W3Mutagen02/11/16/20/24/26/27/28_Effect` (class defaults, Werewolf's flags); Arachas's debuff in `GetDamageResists`, its stack in `takeDamage.ws`; Fiend in `CActor.OnTakeDamage`; Griffin in DEF's `W3PlayerWitcher.ReduceDamage` replacement right after `super.ReduceDamage`, as legacy (`defense/dodge.ws`; audit F14: before Glyph of Warding's Quen); Reliever's in `CActor.ReduceDamage`; Werewolf from the Vitality hook, combat start and end; DLC XML; 5.x's live terms removed (Arachas's carry-weight resistance, Elemental's growing resistance in `GetResistValue`, Griffin's stacking resistances, Reliever's attack power and resistances, Werewolf's free sprint) |
| Port status | **signed off** (2026-10-20); **ported** (slice 8, 5.x-GM `0646ce16`), verified in both trees |
| Open checks | Reliever's against a real spectral form, Doppler's crit from behind, Leshen's returned damage; Elemental's resistance after seconds of burning; Griffin's expiry and environment hits; Griffin with Glyph of Warding's Quen (audit F14, from the code) |
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

**Verification (slice 8, 2026-10-20, both trees):** scripted (`gmtest_alch13`, a neutral human test dummy, its scripted hits on Geralt): Arachas three hits taken, 3 acid stacks on the enemy (-3% resistances), gone at combat end and when the decoction ends; Fiend no hit reaction from a 5% hit; Elemental's ability on Geralt, fire resistance 50%, gone with the decoction; Werewolf nothing at full Vitality, on at 15% Vitality in combat, off above 20%, not again during the 10 s cooldown; Griffin two quick hits start the immunity, the next (physical) hit dodged with no damage. `GMTest_alch13` (regression): the data (Doppler 50% as an add value, Leshen 25%, Reliever's 60%). Not tested: Reliever's against a real spectral form, Doppler's crit from behind, Leshen's returned damage (data and code only).

**Verification (audit fix slice C, 2026-10-20, classic tree; audit F14):** scripted (`gmtest_alch13`): with Griffin's check moved into DEF's body, two quick hits start the immunity and the next hit is dodged with no damage, as before. Glyph of Warding's Quen with Griffin was not set up (from the code: it now runs after Griffin's check, only on a hit that still deals damage).

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
| Port form | DLC XML (petard abilities given whole, bomb effect abilities in `effects.xml`, NG+); `@replaceMethod`s of `W3Petard.OnProjectileCollision` (shields), `CMonsterNestEntity.PlayerHasBombActivator`, `W3Effect_SilverDust.OnEffectAdded`, the teleport tasks' `IsAvailable`, `CBTTaskWraithDrainDance.Main`; Samum's crit chance in DMG-03's crit check; a frozen target's `hpPercDamageBonusPerHit` (Northern Wind's +25/35/50%) a pool term in `ProcessDamageIncrease` (`damage/pool.ws`, legacy's `dmgBonusMult`; 5.x's separate frost hit removed; audit F2); 5.x's `potion_duration` bomb-damage readers removed (`damage/pool.ws`, `skills/heavyArtilleryTrickShot.ws`, `criticalDOTEffect`), DL7; tooltip rows |
| Port status | **signed off** (2026-10-20); **ported** (slice 9, 5.x-GM `c346cf34`), verified in both trees |
| Open checks | a real bomb's damage and shields (Northern Wind's freeze seen); Northern Wind's bonus in a real sword attack; the nest; the teleport and drain dance rules; the potion-duration removal (from the code) |
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

- **Ended with EFX-02** (2026-10-24): the temporary deviation of audit F2 (a frozen enemy's shattering hit still knocked down, no Aard force damage on frozen enemies; until EFX, confirmed by the owner, 2026-10-20) is gone: the shattering hit no longer knocks down and Aard adds 5% of the victim's maximum health as force damage, legacy's ([EFX-02](efx.md#efx-02-hitting-a-frozen-enemy)).
- **Deviation:** 5.x's other bomb changes legacy never saw are kept: the throw range clamp, the water effects, `isFromBomb` on bomb damage over time (the potion-duration bonus it carried is removed; it still gates the new tree's Heavy Artillery doubling, `skills/heavyArtilleryTrickShot.ws`, SKL's) (porter's call, confirmed by the owner, 2026-10-20).

- **Deviation:** Samum 3's text (`item_desc_samum_3`, 5.x's "The first hit landed on a blinded opponent is always critical.", which legacy kept) says "Increases critical hit chance against blinded opponents." (string 2110992637, the vanilla key), in the 9 languages, the 8 non-English ones translated by the port, where legacy had none (audit F12; the owner, 2026-10-20; the translations porter's call, confirmed by the owner, 2026-10-20). Samum 1 and 2 keep 5.x's texts.

**Verification (slice 9, 2026-10-20, both trees):** scripted (`GMTest_alch14`, in the regression): Grapeshot T3 500 + 150 fire, Dragon's Dream T3 500, Dancing Star's cloud 5 s at T3 and burning 1% per tick, Devil's Puffball's poison 1% per tick, Samum T2 5 s and T3 +100% crit (none on the item), Silver Dust T3 40 s, Northern Wind T3 +50%; Silver Dust added to Geralt does not stay. On a neutral test dummy (`gmtest_alch14_samum`): Samum 1/2/3 blindness lasts 4/5/6 s, its ability stays off the enemy, Geralt's bonus +50/75/100%. Not tested in game: a real bomb throw (damage, shields), the nest, the teleport and drain dance rules, the potion-duration removal (from the code).

**Verification (audit fix slice B, 2026-10-20, both trees; audit F2):** a real bomb throw with a scripted read (`gmtest_alch14_throw`, `gmtest_alch14_thrown`; the throw input scripted as in SKL-06): Northern Wind 3 (classic tree) and 2 (new tree) thrown at a neutral human test dummy freeze it (`FrozenEffect_WhiteFrost3`, `2`); its next fixed hit of Geralt's (physical 100, not melee: no random factor) deals 150 and 135, the same hit unfrozen 100 (read within about a second of the throw: the freeze is short). Scripted (`gmtest_alch14_frozen`, the freeze added by script, tiers 1 to 3 in the classic tree, 3 in the new one): ×1.25, ×1.35, ×1.5 on the fixed hit; the dummy loses exactly the hit's damage (no separate frost hit, which was 25/35/50% of its 100,000 health); the freeze ends with the hit and the knockdown is applied (5.x's, kept); a light sword hit 23.3 → 29.5, 23.3 → 30.2, 22.2 → 33.2 (melee's random factor). `GMIsWildHuntMinion` true on the dummy given `mon_wild_hunt_minion`, and the Dimeritium effect stays on it (`gmtest_alch15_minion`).

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
| Port status | **signed off** (2026-10-20); **ported** (slice 10, 5.x-GM `977bcb46`), verified in both trees |
| Open checks | a real Wild Hunt minion or mage, the djinn task, the minions' essence regen pause, the elementals' blocked abilities; a save and reload under the effect |
| Save impact | none (expected) |
| NG+ counterpart | applied, untested |

**What it does** (changelist 724–729): everything in the cloud gets a Dimeritium effect for 20/30/40 s (the cloud itself lasts 5/10/15 s; 1.32's blocks lasted while in the cloud plus 5 s at T3). On Geralt it blocks every sign and ends Quen. Monsters' magic abilities are blocked (wave, ground slam, spawned arena, fire throw, frost, sign attacks); magic creatures and Wild Hunt minions lose 50/75/100 armor and 5/10/15% resistance, and minions their essence regen; mages deal Geralt 30/40/50% less damage but keep their magic; the djinn gets no rage from bombs; Wild Hunt portals close (as 1.32). The cloud is smaller (impact range 6 → 4, cloud 6 → 3: not in the changelist).

**Implementation (legacy):** `dimeritiumEffect.ws` (new class: `<members>`, `GetDamageReduction`, `GetArmorPiercing`, `GetResistReduction`, `OnEffectAdded`, `OnEffectRemoved`, `BlockAbilities`), `dimeritium.ws` (`LoopFunction`; `ProcessTargetOutOfArea` commented out), `IsNegativeEffectType`, the three `gameEffectManager.ws` registrations, `GetDamageResists` and `ProcessDamageModification` terms, `btTaskManageDjinnRage.ws`; data `DwimeritiumBomb_*`, `DimeritiumEffect_Level1–3`, effect and icon; `petard_dimeritium_bomb.w2ent`; tooltip rows `duration_out_of_cloud` (unused), `dbomb_*`; strings 2110992239, 343–347, 456, 480.

**5.x:** 1.32's bomb, with `ablMagic` added to the blocked abilities. Until ALCH-15 the port kept 5.x's Dimeritium terms out of DMG's functions (DMG-02's and DMG-05's temporary deviations, ended).

**Decisions:** port as legacy; 5.x's `ablMagic` block is part of the item's direct blocks legacy replaced by the effect: dropped with them (DL7). Wild Hunt minions are found by their abilities (`mon_wild_hunt_minion`, `_minionMH`, `_lesser`, `_weak`), the ones legacy's `GetEnemyTypeByAbility` (a legacy helper not in the port) tested. The effect's added XML entries carry the `GM` prefix (`GMDimeritiumEffect`, its abilities `GMDimeritiumEffect_Level1–3`: an effect ability's name starts with its effect's). On Geralt the effect also blocks the new tree's own alternate Igni and Axii skills (`S_Magic_s28`, `S_Magic_s31`; both trees). The binary edit sets both copies of the template (legacy edited only the compiled copy the game reads; no play difference). What the target is (magic creature, minion, mage) is worked out again after a load (legacy kept it in unsaved fields set when the effect was added).

**Verification (slice 10, 2026-10-20, both trees):** real bomb throws with a scripted read (`gmtest_alch15_throw`, `gmtest_alch15_check`; the throw input scripted as in SKL-06): a Dimeritium bomb 3 thrown at a golem test dummy 5 m away gives it the effect (40 s) and not Geralt (outside the 4 m impact range; 5.x's 6 m would reach him); bombs 1 and 2 thrown at one 2.5 m away give both the effect (20 and 30 s) and block Geralt's Igni: a real cast (`autocast`) does nothing under it and works once it is gone. Scripted (`gmtest_alch15`, effect added by script): on the golem (magic creature) -100 armor and -15% resistances, Geralt's sword hit on 100 armor 0 without and 23.3 with the effect; on a plain human the effect ends at once; on a human with `ablMagic` (a mage) it stays, no armor cut, and its hit on Geralt is halved (367.1 → 183.5). `GMTest_alch15` (regression): the data, no direct blocks on the bomb (DL7), the effect name mapping, on Geralt every sign of both trees blocked and unblocked when it ends; `gen_alch.py --verify` compares the binary file with 5.x's plus exactly the two range edits. Not tested in game: a real Wild Hunt minion or mage, the djinn task, the minions' essence regen pause, the elementals' blocked abilities (from the code).

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
| Port status | **signed off** (2026-10-20); **ported** (slice 11, 5.x-GM `9f50e5f9`), verified in both trees |
| Open checks | a real sword hit with an oil; 5.x's auto-oil; an older save's stuck oil; the oils' own texts on screen (read from the tooltip as built, audit F6) |
| Save impact | none (expected: oil values are read from the oil effect); an oil stuck on a sword from an older save stays until the sword changes hands (changelist 27–29) |
| NG+ counterpart | applied, untested |

**What it does** (changelist 585–589, bugfixes 41–42; values from the code): every oil tier gives +25% attack power against its monster type (1.32: +10/25/50%); T2 and T3 add +5% crit chance, T3 +25% crit damage; no resistance reduction (1.32's T3 node was empty, so 0 there too; legacy left a 0.15 value commented out). The Ogroid oil's attributes are renamed `vsOgre_*` and the monster-category lookup maps ogroids to them. Oils on a sword are removed when it moves to another inventory (the stuck-oil fix). Descriptions say "Effectiveness decreases with oil rubbing off the blade" (SKL-14's decay).

**Implementation (legacy):** `def_item_alchemy_oils.xml` 36 abilities `BeastOil_1` … `VampireOil_3`, `HangedManVenom_*`; `types.ws` `MonsterCategoryToCriticalChanceBonus`, `MonsterCategoryToCriticalDamageBonus`, `MonsterCategoryToResistReduction` (a change inside name literals only: in `units.csv` since `change_units.py` compares literals, 2026-10-20); `CInventoryComponent.GiveItemTo`, `RemoveAllOilAbilitiesFromItem`; `W3TooltipComponent.AddOilInfo`; 36 tooltip rows; strings 2110992034–070, 192–230, 234.

**5.x:** 1.32's values (Hanged Man's Venom 1 gave +10% before ALCH-16), Hanged Man's Venom tagged for silver swords too; 5.x's auto-oil option and re-applying a brewed oil of a higher tier (kept by DMG; DL9); no stuck-oil fix.

**Correction to DMG's hand-off:** the oils' resistance reduction is 0 in 1.32, legacy, 5.x and the port alike (the "flat 0.25" in [dmg.md](dmg.md#hand-off-to-other-areas) is the oils' attack power); DMG-02's temporary deviation on it changes nothing in play.

**Decisions:** port as legacy; DL9 (owner): Hanged Man's Venom on steel swords only (5.x's `SilverOil` tag dropped), 5.x's auto-oil and re-apply kept. The stuck-oil fix wraps `GiveItemTo` with legacy's conditions (a non-singleton sword, a transfer that is allowed) and removes the oils before 5.x's transfer. Consistency: SKL-14's code reads the new crit chance and crit damage values (wearing off with the oil, as its attack power), ARM-09's Wolven bonuses come on top (per oil, unchanged); the ogroid oil now gives its crit values against ogroids (5.x's lookup found none).

- A sword's oil line is legacy's (the oil's name and charges; its bonuses in the oil's own tooltip) since UI-06 (2026-10-20, 5.x-GM `6ca81e09`): the temporary deviation has ended.

**Verification (slice 11, 2026-10-20, both trees):** real oil applications (`W3PlayerWitcher.ApplyOil`, the inventory's path) with a scripted read of the sword's values against a neutral test dummy (`gmtest_alch16`: attack power through the attack action, crit chance and crit damage through Geralt's functions): Ogroid oil 1/2/3 on the silver sword against a troll +25% attack power each, +0/5/5% crit chance, +0/0/25% crit damage (5.x's lookup gave ogroids no crit value); Hanged Man's Venom 1/2/3 on the steel sword against a human the same; Hanged Man's Venom refused on the silver sword (`gmtest_alch16_silver`); an oiled steel sword given to the dummy's inventory arrives without the oil's ability (`gmtest_alch16_transfer`). `GMTest_alch16` (regression): the data (every tier +25%, crit chance from tier 2, crit damage at tier 3, no resistance reduction), the `vsOgre_` names, Hanged Man's Venom's tags. Not tested in game: a real sword hit with an oil (the values are read on the attack's path), 5.x's auto-oil, an older save's stuck oil.

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
| Port form | `alchemy/tooltips.ws`: `@replaceMethod` of `GetPotionAttributesForTooltip` (legacy's: by name), `@addMethod`s `GMGetPotionAttributesByName`, `GMGetBombAttributesForTooltipByName`, `GMFillInMutagenDescription`, `…ByName`, `…FromBuffType` (legacy's `FindAttrInTooltipSettings` is ITEM's `GMFindAttrInTooltipSettings`); wrappers of `W3TooltipComponent.GetBaseItemData` (bomb stats, decoction description), `AddBuffStats` (a potion's duration as drunk), `CInventoryComponent.GetItemTooltipAttributes` (a bomb's cloud duration) and `W3GuiPlayerInventoryComponent.GetCraftedItemInfo` (the alchemy menu); legacy's descriptions by name key in the `GetBaseItemData` wrapper with `@addMethod GMItemHasRecyclingParts` (legacy's `ItemHasRecyclingParts`); wrappers of `W3TooltipComponent.AddItemStats` and the global `CalculateStatsComparance` (the units, audit F11); legacy's 144 ALCH strings in the nine languages (`modGhostMode` tables: the potion, decoction, bomb and oil descriptions and attribute names of ALCH-04 to ALCH-17); the tooltip rows in the `tooltip_settings.csv` override |
| Port status | **signed off** (2026-10-20); **ported** (slice 12, 5.x-GM `b37c48c9`; the descriptions by name key and the tooltip units with audit fix slice D, 5.x-GM `861a3217`), verified in both trees |
| Open checks | the menus and tooltips on screen (the flash objects read, audit F6 to F12); the strings in the other eight languages; a book's, key's and quest item's description by name key in play |
| Save impact | none |
| NG+ counterpart | none |

**What it does** (bugfixes 62–63, 101–102): potion and bomb tooltips list every effect, in the inventory, shops, the alchemy menu and the recipe book (by name); resistances and adrenaline gain as percentages; White Raffard T3's immunity; Blizzard's slow motion and Killer Whale's breath attributes named; decoction tooltips show their values (`$S$`/`$I$` filled from the data) and explain the toxicity offset; decoction stacks shown in the buff tooltip; the potion duration attribute named.

**Implementation (legacy):** `CInventoryComponent.GetPotionAttributesForTooltip`, `GetPotionAttributesByName`, `FillInMutagenDescription`, `FillInMutagenDescriptionByName`, `FillInMutagenDescriptionFromBuffType`, `GetBombAttributesForTooltip`, `GetBombAttributesForTooltipByName`, `FindAttrInTooltipSettings`; `W3GuiBaseInventoryComponent.GetAlchemyBookText`, `W3GuiPlayerInventoryComponent.GetCraftedItemInfo`, `W3TooltipComponent.GetBaseItemData`, `AddBuffStats`; tooltip row `potion_duration`; string 2110992015. The descriptions of each potion, decoction, bomb and oil are attributed to their features (ALCH-04 to ALCH-16), about 120 rows × 9 languages.

**5.x:** `GetPotionAttributesForTooltip` rewritten (Reinald's Philtre, Cat's crit chance); the rest 1.32's.

**Decisions:** port as legacy, values from the ported features; layout and the recipe book are UI's. Reinald's Philtre (5.x's, DL10) gets legacy's generic handling. The decoction description replaces 5.x's text of the item in the tooltip's description, so lines other wrappers add (ITEM-12's buff line) stay.

Audit F6 (the owner, 2026-10-20): legacy's whole description lookup by name key is ALCH's: an item that is not armor, a weapon, horse gear, a decoction, a decoction's recipe or a Gwent card shows the text of `item_desc_<x>` for its name key `item_name_<x>` when that key exists (the 36 oils, Cat 3's hypnosis line, and the books, keys and quest items changelist 41 restored), junk without recycling parts legacy's "Can be sold to merchants." (2110992259), anything else 5.x's text; the text replaces 5.x's in the description, so other wrappers' lines stay. The books, keys and quest items are noted for UI in the [hand-off](#hand-off-to-other-areas). Audit F11 (the owner, 2026-10-20): now, as legacy's `AddItemStats` and `CalculateStatsComparance`: a bomb's cloud, Dimeritium's out-of-cloud and Golden Oriole's immunity durations in seconds, a decoction's toxicity offset under its own name (2110992381) with no "/max"; done by wrappers that rewrite the rows those functions build (one row per stat, in order).

- A potion's toxicity line shows the value after Expert Brewer without "/max", and the offset line after Adaptation, since UI-06 (legacy's `AddItemStats`, 2026-10-20, 5.x-GM `6ca81e09`): the temporary deviation has ended.

- The recipe book's text and a recipe item's tooltip are legacy's since UI-08 (2026-10-20, 5.x-GM `5b5ab8a5`): the potion's and bomb's effects and the decoction's values are listed; the temporary deviation has ended.

**Verification (slice 12, 2026-10-20, both trees):** scripted, the tooltips as the game builds them (`gmtest_alch17_tooltips`: `W3TooltipComponent.GetBaseItemData` on items in Geralt's inventory; `gmtest_alch17_crafted`: the alchemy menu's `GetCraftedItemInfo`): the Dimeritium bomb 2's tooltip lists "Cloud duration 10", its effect's 30 s and armor piercing 75, -10% resistances, -40% damage; the Werewolf decoction's description reads "+50% to Attack Power, +50% to Sign Intensity, +5/s … at 20% or lower"; Thunderbolt 3's shows 90 s (as drunk) and +35% attack power; the alchemy menu lists the Dimeritium bomb 3's and Golden Oriole 3's values (+50% poison resistance, 5 s immunity) and the Troll decoction's filled description. `GMTest_alch17` (regression): every potion attribute path, no attributes for decoctions, all 28 decoction descriptions filled with no placeholder left and the toxicity offset note, the bomb effects' values, the attribute names. Not seen on screen: the menus themselves (the flash objects were read, not the rendered panels); the strings in the other eight languages (copied from legacy's tables by id).

**Verification (audit fix slice D, 2026-10-20, both trees; audit F6, F11):** scripted, the tooltips as the game builds them (`gmtest_alch17_texts`: `GetBaseItemData` on items added to Geralt's inventory, and the alchemy menu's `GetCraftedItemInfo`): Beast Oil 1 and Hanged Man's Venom 3 show their own texts, not "Apply to a sword…"; Cat 3 "Grants sight in total darkness and immunity to hypnosis. Extended duration."; Golden Oriole 3 "Poison immunity duration 5 s"; the Dimeritium bomb 2 "Cloud duration 10 s" and "Effect duration 30 s"; the Katakan decoction "Toxicity offset 70" (no "/"); Thunderbolt 3 "Effect duration 90 s"; the alchemy menu's list Golden Oriole 3 "Poison immunity duration 5 s". In the regression (`GMTest_alch17_texts`): each changed key resolves to the row that must win (Cat 1 and its buff, Blizzard 1/2/3, Swallow 3, Samum 3, Golden Oriole's buff, Cat 3, the junk string), and the 36 oils have their own texts by name key. Not seen: a book, key, quest item or junk item's description (the lookup is the same code); the rendered panels.

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
| Port status | **signed off** (2026-10-20); **ported** (slice 12, 5.x-GM `b37c48c9`), verified in both trees |
| Open checks | — |
| Save impact | none |
| NG+ counterpart | none |

**What it does:** `addalchemy1/2/3` give every potion, bomb and oil of a tier; `adddecoctions` every decoction; `toggledebugoils` logs the oils' bonuses (`modSigns_debug_oils` fact).

**Implementation (legacy):** `console_debug.ws` `addalchemy1`, `addalchemy2`, `addalchemy3`, `adddecoctions`, `toggledebugoils`.

**Decisions:** port as legacy's console commands (every item with full charges).

- **Deviation:** `toggledebugoils` (a log of the oils' bonuses in legacy's oil effect) is not ported: SKL-14's oil code was rewritten for the port and its tests (`gmtest_skl14_oil`, ALCH-16's `gmtest_alch16`) read the same values (porter's call, confirmed by the owner, 2026-10-20).

**Verification (slice 12, 2026-10-20):** `addalchemy3()` and `adddecoctions()` run from the console (`game.py exec`) give the items (`gmtest_alch18`).

**Later:** —

### ALCH audit (2026-10-20)

Done by a fresh session ([audit](../feature-mapping.md#audit-signing-a-feature-off)) on 5.x-GM `b37c48c9` and master `0bf768bf` (regression 711 passed, 0 failed in each tree, as recorded by the port), reading code and data only; no game run (every finding below is plain in the code or the data; F1 and F2 should be confirmed by the fix slices' tests, the way they are written). Every script unit [attribution.csv](attribution.csv) gives ALCH (272, `gm/alchemy/*.ws` and ALCH's hunks in `gm/damage`, `gm/mutations`, `gm/stamina`, `gm/skills`, `gm/enchantments`, `gm/defense`, `gm/effects`) was read against legacy's code (`legacy-GM`), 1.32 and 5.x, and against the changelist (lines 41, 62–186, 384–386, 585–589, 674–835); the 28 decoctions one by one, with every 5.x reader of a decoction's effect class. The data was compared by an independent script (the auditor's, not `gen_alch.py`): every ability, item and custom effect entry of legacy's alchemy files (`def_item_alchemy_potion/mutagens/petards/oils.xml`, Blood and Wine's potions, `effects_potions.xml`, `effects_mutagens.xml`, `effects.xml`, `effects_ep2.xml`, Hearts of Stone's `effects.xml`; 496 entries, regular and NG+) as the game reads them (5.x's definitions with every file of Ghost Mode's DLC applied, `replace` and `extend`) against legacy's, weights and prices left to WGT and ECON. The 145 ALCH strings in the 9 tables, the 45 tooltip rows, the binary file (`cr2w_dump.py` of legacy's, 1.32's, 5.x's and the port's copy) and the debug commands' item lists were compared with legacy's.

**Checked and holding:** the data equals legacy's in the regular game: every difference is recorded or another area's (Dimeritium's effect under its `GM` name, Northern Wind's kept `PoisonDeath` block, DL7; the pheromones' and Pops' Antidote's sound and the White Raffard and Maribor Forest overrides, given by script; the cooldown, bleeding, frozen, well-fed and other generic effects: STAM, EFX, FOOD; the Mutation Catalyst: MUT-12; the inert Alchemy Table, dropped); in NG+ also F17. 5.x's own changes to the alchemy data are all overridden (no entry keeps a 5.x value legacy would not have had). The code: toxicity (DL1: 0.75, decay only while there is toxicity, the same in and out of combat, the offset functions update the effect), the drinking refusal, the stacking rule and DL12's tier rule (but F1), Swallow's, White Raffard's, White Honey's (DL6) and Golden Oriole's scripts (DL5), Petri's Philtre 3 in the three places, Blizzard's slow motion after kills with its caller in ENCH's `OnDeath`, Cat's hypnosis rule, Tawny Owl and Maribor Forest, the bear pheromone; the 28 decoctions as legacy's (stacking, caps, resets, hooks) apart from F3, F13, F14 and F16, and every 5.x 1.32-rule reader neutralised: Forktail's `HasBoost` always false (so `ClearBoost` in `signEntity.ws`, `playerWitcher.ws` and `OnCombatFinished` does nothing), Elemental's `GetResistBonus` returning none (its only caller multiplied the resistance by the seconds of burning), Reliever's `GetMonsterDamageBonus` and `GetProtection` returning zero and 5.x's specter block gone, Nekker Warrior's horse code (`GainStat`, `ForceSetStat`, `ShouldUpdatePanic`, both exploration-state events) and `GetAttackPowerBonus`, Noonwraith's `IsEffectTypeAffected` false (both `OnBuffAdded` and the on-drink loop), Succubus's timer removed in both places, Alghoul's combat-start and on-drink ability, Werewolf's free sprint and night regen, Water Hag's full-Vitality term, Arachas's carry-weight block, Wraith's 30% Quen, Ancient Leshen's regen, Grave Hag's +10, Ekhidna's 10% heals, ArchGriffin's 1.32 rule; the attributes those rules read are absent from the final data. Wyvern's per-hit wrapper is exact (F18). Bombs: the shield rule, Samum (in `GetCriticalHitChance`, swords, bolts and the Manticore set's bombs), Silver Dust's blocks, the three teleport gates (5.x's new water teleport inherits one), the drain dance, the nest, Dragon's Dream 3's explosion; the potion-duration readers of bomb damage are exactly three and all removed (DL7). Dimeritium as legacy's effect (values, targets, blocks of both trees' signs, unblocking, the kind worked out again after a load, the djinn, the minions found by legacy's abilities); the damage terms equal legacy's. The binary file is 5.x's plus exactly the two range floats in both copies, CRCs valid; legacy changed only those two floats (in the compiled copy); 5.x's own change to the file (a collider component) does not conflict. Oils: the `vsOgre_` lookup, the stuck-oil fix with legacy's conditions, the 36 names complete against the data, SKL-14 reading crit chance and crit damage, Hanged Man's Venom on steel only (DL9). Tooltips: the potion attributes by name equal legacy's (5.x's Cat branch dropped with DL4; Reinald's Philtre's generic lines are right), the bomb attributes, the 28 decoction descriptions (all 58 attribute reads exist with legacy's values), the alchemy menu and `AddBuffStats`. The 145 strings equal legacy's in all 9 languages (text, key and key hash); the 45 tooltip rows equal legacy's; `addalchemy1/2/3` and `adddecoctions` hold legacy's 33/32/32/28 items. The load-time cleanup runs after the effects are restored, removes only combat stacks and 5.x's leftovers, and cannot remove or double a running decoction's own ability; the saved fields `gmM09Bonus` and `gmM25Bonus` are recounted on load. The temporary deviations other areas kept until ALCH are all ended (DMG-01, 02, 03, 04's Mutagen 9, 05, 07, 12; MUT-09; SKL-10, SKL-11; ENCH-09's hand-off; STAM's hand-offs; ARM-10, 11, 15; SWD's and ARM's oils): none in [deviations.md](deviations.md) waits for ALCH. No skill is per-tree in ALCH beyond Dimeritium's sign list (both trees) and Blizzard and the threshold's skills (SKL's, checked in both). `check_modsigns.py` clean (374 bodies, 0 unmarked); `deviations.py --check` current; `gen_alch.py --check` current and `--verify` no difference (201 entries and NG+, the binary file ok); `gen_item.py`, `gen_arm_items.py`, `gen_swd_items.py`, `gen_arm_km.py`, `gen_arm_new.py`, `gen_ngplus.py`, `gen_ench.py`, `gen_npc_stamina.py` `--check` current, `gen_item.py`, `gen_arm_items.py`, `gen_swd_items.py`, `gen_ench.py --verify` 0 unexplained. `unit_sweep.py --unattributed` (toxicit, potion, decoction, mutagen, bomb, petard, oil, dimerit and every potion and bomb name) finds no unattributed ALCH unit: the rest are edibles (FOOD), trophies, quest rewards and loot (LOOT), recipes and dismantling (CRAFT), `FixQuestItems` (FIX), `fb3_internal` (XP), the standalone starts, two Blood and Wine monster debuffs (AI) and `CActor.RemoveBuffImmunity_AllNegative` (unmapped, not alchemy); F3's and F6's units, which the sweep cannot see (their keywords are `HeavyKnockdown` and `item_desc_`), are noted with this audit.

**Findings:**

1. **A second Swallow replaces the running one instead of stacking, so Swallow 1 drunk on Swallow 3 lowers it** (clear fix). Two doses cumulate only when the effects' strengths are equal (`GetSelfInteraction`, `alchemy/potionRules.ws:25-39`, checked both ways by 5.x's `CheckInteractionWith`, `gameEffectManager.ws:498-517`); the strength is `CalculateAttributeValue(effectValue)` (5.x `baseEffect.ws:573`). Swallow keeps 5.x's base class `W3RegenEffect`, whose `CacheSettings` makes `vitalityRegen` its main value (40/65/80), and the port zeroes `effectValue` at every update of the running effect (`alchemy/swallowHoneyOriole.ws:16-25`). So from the first tick on, a new dose (40) beats the running one (0): `EI_Override`, the running Swallow is removed and the new one starts with its own duration and tier. Legacy's Swallow was a plain effect with no main value (legacy `potionVitalityRegen.ws:9-11`: strength 0, every dose cumulates). The regression misses it because `GMTest_alch02`/`GMTest_alch04` drink both doses in one frame (`gmTestsAlchPotions.ws:147-151`), before the first update. Tawny Owl and Reinald's Philtre are zeroed the same way but their main value is a multiplier (`staminaRegen` mult, strength 0): they stack. Fix: `GetEffectStrength` returning 0 in the `W3Potion_Swallow` override (legacy's strength; also for Tawny Owl and Reinald's Philtre, for robustness), and a regression check that drinks the second dose in a later call (Swallow 1 then Swallow 3, Swallow 3 then Swallow 1: durations add, tier 3 kept). Check: the same, in game. **Fixed** (5.x-GM `3ee751ab`): `GetEffectStrength` 0 in the `W3Potion_Swallow`, `W3Potion_ReinaldPhiltre` and `W3Potion_TawnyOwl` overrides; the regression drinks the next doses in its next call (`GMTest_alch04_after`) after checking that the running dose's own regen value is 0 (the finding's evidence: the state in which a new dose replaced it); real drinks from the potion slot in separate calls keep tier 3 and add the time, in both trees ([ALCH-04](#alch-04-swallow-white-raffards-decoction-white-honey)).
2. **Northern Wind: a frozen enemy's next hit adds a frost hit of 25/35/50% of its current health, with a knockdown** (clear fix). The port took legacy's `FrozenEffect_WhiteFrost1–3` (`hpPercDamageBonusPerHit` 0.25/0.35/0.5, `gm_alch.xml`; 5.x 0.05/0.07/0.10), but the code that reads it is still 5.x's (`gm/damage/pool.ws:98-130`: a separate frost action of `GetAdditionalDamagePercents() × GetHealth()` and `EET_KnockdownTypeApplicator`). Legacy reads the value as a damage bonus, `dmgBonusMult += hpPercDamageBonusPerHit`, removes the knockdown and gives Aard 5% of the victim's maximum health as force damage (legacy `damageManagerProcessor.ws:1293-1318`; changelist "Northern Wind bomb bugs fixed"). DMG-04's temporary deviation ("the frozen target's bonus (EFX; 5.x's separate frost hit stays)", [dmg.md](dmg.md)) was written while the values were 5.x's; with legacy's values the hit is five times 5.x's. ALCH-14's "+25/35/50%" and the slice's "Northern Wind T3 +50%" are a data read. Fix: legacy's frozen term in the pool now (the knockdown and Aard's force damage with it, or those two explicitly left to EFX as a deviation), ending DMG-04's frozen deviation; a scripted check: a sword hit on a dummy frozen with `FrozenEffect_WhiteFrost3`, with and without. **Fixed** (5.x-GM `eef6c32e`): the bonus is a pool term (legacy's), 5.x's frost hit removed, DMG-04's frozen deviation ended; 5.x's knockdown kept and Aard's force damage not ported, recorded as a deviation (temporary, until EFX or the owner's call); a real Northern Wind throw and scripted freezes of all three tiers give ×1.25/1.35/1.5 on the next hit with no frost hit, in both trees ([ALCH-14](#alch-14-bombs)).
3. **Chort: a heavy knockdown still floors Geralt** (clear fix). Legacy turns `EET_HeavyKnockdown` into a stagger too (legacy `effectManager.ws:808`, changelist 792 "reduces knockdown to stagger"); 5.x converts `EET_Knockdown` only (5.x `effectManager.ws:821-831`), and the port only wraps `InternalAddEffect` (`skills/quen.ws:614`). The unit was attributed to SKL-11 only; ALCH-09 said "Chort as vanilla". Fix: in that wrapper, a heavy knockdown on Geralt with `EET_Mutagen08` becomes `EET_Stagger` before `wrappedMethod` (mind SKL-11's ordering note); a scripted check. Attributed to ALCH-09 with this audit. **Fixed** (5.x-GM `1f7e26d2`): at the top of the wrapper a knockdown or heavy knockdown on Geralt with Chort becomes a stagger for Quen's rules and goes on as a plain knockdown (5.x's code turns that into the stagger; a stagger passed on would be denied there); a stagger is denied first, legacy's order; scripted in the regression, both trees ([ALCH-09](#alch-09-decoction-rules)).
4. **Blizzard 3's free actions miss Whirl, Rend, stamina lost on blocks and other fixed drains** (clear fix; relevant to the owner's open call on Battle Trance). Legacy zeroed the cost in `W3PlayerAbilityManager.GetStaminaActionCost` before anything else (legacy `PlayerAbilityManager.ws:1237-1245`), so every drain through `DrainStamina` was free during the slow motion with 3 adrenaline, `ESAT_FixedValue` ones included (Whirl's and Rend's drains, `stamina/whirlRendStamina.ws:79`, `:156`; the stamina damage of a blocked hit, `mutations/takeDamage.ws:180`; Quen's drain, `skills/quen.ws:394`), and with no regen delay. The port checks it in `GetStaminaActionCostInternal` (`alchemy/staminaCostInternal.ws:45-55`), which `ESAT_FixedValue` never reaches (5.x `abilityManager.ws:485-496`). The recorded deviation calls it "the same rule". Fix: the check in a `W3PlayerAbilityManager.GetStaminaActionCost` wrapper (cost 0, delay 0, before the GM multipliers), Mutation 7's denial kept in front as recorded; correct the deviation's text; a scripted Whirl cost during the slow motion. **Fixed** (5.x-GM `3ee751ab`): legacy's override of `W3PlayerAbilityManager.GetStaminaActionCost` (a scope-based override, since the class inherits the method; the wrappers of `W3AbilityManager`'s definition still run through `super`): cost 0 and only the stamina-delay option's pause, Mutation 7's denial in front; the check removed from `GetStaminaActionCostInternal`; the deviation's text corrected; a fixed drain and Whirl's drain cost nothing in the regression, both trees ([ALCH-07](#alch-07-other-potions-special-effects)). The Battle Trance call stays the owner's.
5. **Blizzard's 5.x blue tint does not show at all** (owner decision). The confirmed deviation (ALCH-07) says the tint "now shows during legacy's 3 s slow motion after a kill"; only 5.x's replaced `OnTimeUpdated` called `EnableScreenFx(true)` (5.x `Blizzard.ws`), and the port's `KilledEnemy` does not (`alchemy/otherPotions.ws:12-22`); `RemoveSlowMo` still turns the cat view off. In play Blizzard looks as legacy's (no tint); Cat's view is 5.x's and 1.32's. Options: (a) add `EnableScreenFx(true)` in `KilledEnemy`, as the owner's "keep 5.x's visuals" said; (b) keep legacy's look and correct the deviation (Cat's view only). Recommendation: (a), a one-line cosmetic change matching the owner's confirmation. **Fixed** (5.x-GM `861a3217`; the owner, 2026-10-20: (a)): `EnableScreenFx(true)` when a kill starts the slow motion; scripted and seen on screen in both trees ([ALCH-07](#alch-07-other-potions-special-effects)).
6. **Legacy's own descriptions of the oils and of Cat 3 never show** (clear fix for ALCH's part; owner decision on the owner of the rest). Legacy's `GetBaseItemData` looks a description up by the item's name key (`item_name_` → `item_desc_`) for items that are not armor, weapons or horse gear, falling back to the XML key (legacy `guiTooltipComponent.ws:457-466`; changelist 41, "Restored extended items descriptions for books, keys, quest items"). No port wrapper does: every oil shows 5.x's generic "Apply to a sword for additional effects in combat." (`item_desc_oil`), so legacy's 39 oil strings (2110992192–230, 234, ported with ALCH-17) are dead, and Cat 3 shows `item_desc_cat_2` without its hypnosis immunity (2110992235, `item_desc_cat_3`). The hunk was unattributed (noted on `GetBaseItemData` with this audit). Fix: legacy's lookup in a `GetBaseItemData` wrapper (`alchemy/tooltips.ws`); the books, keys and quest items it also restores are UI's or ITEM's: the owner says whose (recommendation: port the whole lookup with ALCH, since one wrapper does all, and note it in UI's hand-off). **Fixed** (5.x-GM `861a3217`; the owner, 2026-10-20: the whole lookup with ALCH, the books, keys and quest items noted in UI's hand-off): legacy's lookup in the `GetBaseItemData` wrapper with legacy's junk string; the oils' and Cat 3's texts read from the tooltips as built ([ALCH-17](#alch-17-alchemy-tooltips-and-descriptions)).
7. **Cat 1 still says it raises critical hit chance** (clear fix). 5.x's `item_desc_cat_1` (1064023) and the buff text `effect_CatEffect_desc` say "Increases critical hit chance."; DL4 removed it (`gm_alch.xml` Cat effects without `critical_hit_chance`); 1.32's text needed no override, so legacy had none. Fix: override both in the 9 tables with the first sentence (5.x's wording per language). **Fixed** (5.x-GM `861a3217`): strings 2110992633 and 634.
8. **Blizzard 1 and 3 describe 5.x's potion ("When you are in danger, time slows")** (clear fix). 5.x 1064020, 1064022; only Blizzard 2 is overridden (2110992471, "Whenever you slay an enemy…"). Fix: override `item_desc_blizzard_1` and `_3` (tier 3 with 5.x's sentence on 3 adrenaline points) in the 9 tables. **Fixed** (5.x-GM `861a3217`): strings 2110992635 and 636.
9. **Two string rows claim Swallow 3's description** (clear fix, check in game). 2110992178 (no bleeding line) and 2110992539 (the full text) both carry key hash `56747c57` (`item_desc_swallow_3`) in every table, as in legacy; which one the game shows is not defined. Fix: drop the key from 2110992178 (nothing reads it by id) and record it; check Swallow 3's tooltip. **Fixed** (5.x-GM `861a3217`): recorded in ALCH-04; Swallow 3's tooltip shows the full text.
10. **The Spanish Katakan description states 25% crit damage** (owner decision; legacy's translation bug). 2110992455 in `es.csv` has two `$I$` where English has three (per hit, maximum, crit damage), so the maximum fills the crit damage. Recommendation: add the missing "(máx. $I$%)", a deviation from legacy's row (as SKL-19's translation rule). **Fixed** (5.x-GM `861a3217`; the owner, 2026-10-20): recorded in ALCH-10, confirmed.
11. **Alchemy durations in tooltips show bare numbers, and a decoction's offset reads "Toxicity 70/max"** (owner decision: now or with UI). Legacy's `AddItemStats` and `CalculateStatsComparance` add " sec" to `cloud_duration`, `duration_out_of_cloud` and `poison_immunity_duration` and show `toxicity_offset` under its own label, string 2110992381 (legacy `guiTooltipComponent.ws:1245`, `1272`, `2448`); the port changes neither, and its rename of the bomb's `duration` row to `cloud_duration` (`alchemy/tooltips.ws:590-594`) loses 5.x's " sec" ("Cloud duration 10" in the slice's own check); the decoction description's offset note names a label the tooltip does not show. Unattributed (noted on both units with this audit). Options: (a) a wrapper post-processing the rows, as the `AddBuffStats` wrapper does; (b) a temporary deviation until UI. Recommendation: (a), small and in ALCH's file. **Fixed** (5.x-GM `861a3217`; the owner, 2026-10-20: now, with a small wrapper): wrappers of `AddItemStats` and `CalculateStatsComparance`; recorded in ALCH-17 with the toxicity line that waits for UI.
12. **Samum's and Golden Oriole's texts legacy never updated** (owner decision). Samum 1 and 2 (5.x 1063976/977) say nothing of the crit bonus and Samum 3 (1055157) says "the first hit … is always critical", against +50/75/100% while blinded (DL11); the buff text `effect_GoldenOrioleEffect_desc` says "Immunity to poison". The item tooltips list the right values. Options: keep legacy's texts (no deviation, as now) or override them (a deviation). Recommendation: override Samum 3 and the Golden Oriole buff text, which state rules that no longer exist. **Fixed** (5.x-GM `861a3217`; the owner, 2026-10-20: update both in the 9 languages, translated where legacy has none): strings 2110992637 and 638, recorded in ALCH-14 and ALCH-05.
13. **The decoction stack percentages do not show on the HUD** (clear fix). Legacy put Katakan, Water Hag, Wyvern, Alghoul, Forktail and Ancient Leshen in the HUD's format 4, which shows `extraValue` (legacy `hudModuleBuffs.ws:372`); the port sends the values (`mutations/hudCounters.ws:341-352`) but its format list is 5.x's (`:64-72`), so they stay at format 3. ALCH-10 lists the HUD as not seen. Fix: the six effect types in the format-4 condition; look at the HUD in game. **Fixed** (5.x-GM `1f7e26d2`): the six types in the format-4 condition; Alghoul's and Forktail's "30%" seen on the HUD (screenshot) in both trees.
14. **Griffin: Glyph of Warding's free Quen can fire on a hit Griffin then cancels** (clear fix, edge case). Legacy applies Griffin right after `super.ReduceDamage` and returns if the hit no longer deals damage (legacy `playerWitcher.ws:2084-2093`); the port wraps the whole of `ReduceDamage` (`alchemy/decoctionsDefense.ws:351-357`), so DEF's replaced body runs first, including `GMWardingQuen` (`defense/dodge.ws:172`). Fix: call Griffin's check inside `dodge.ws`'s body after `super.ReduceDamage` (`:133`), drop the wrapper. **Fixed** (5.x-GM `1f7e26d2`): Griffin's check right after `super.ReduceDamage` in `dodge.ws`, the wrapper dropped; Griffin's test passes (classic tree, `gmtest_alch13`); Glyph of Warding with Griffin not set up in game.
15. **The character panel still shows 5.x's Water Hag bonus, and lacks legacy's Foglet and Wraith lines** (owner decision; no play effect). 5.x's `GetOffenseStatsList` and the stats popup's crossbow power add `damageIncrease` at full Vitality with Water Hag (5.x `playerWitcher.ws:8822-8825`, `CharacterStatsPopup.ws:900-903`; now non-zero only with Doppler); legacy removed both and added Foglet's (`CharacterStatsPopup.ws:662`) and Wraith's Quen power (`:905`). Not recorded. Recommendation: a temporary deviation until UI in ALCH-10 and ALCH-11, as the other areas' panel lines (the UI hand-off row now lists them). **Decided** (the owner, 2026-10-20): recorded as temporary deviations until UI in ALCH-10 and ALCH-11.
16. **The combat log leaves out ArchGriffin's extra damage** (clear fix, log only). Legacy logs after the drain and adds it (legacy `actor.ws:2679-2717`); the port logs first (`mutations/takeDamage.ws:211-215`). Fix: move the log, or record a deviation. **Fixed** (5.x-GM `1f7e26d2`): the log written after the drain with it added (`GMLogCombatDamage`, called from one marked line); the drain is asserted in `gmtest_alch12`, the log line itself was not read.
17. **White Raffard's Decoction 1 and 2 heal 60/80% in NG+, not legacy's 35/60%** (clear fix, NG+). Legacy set the NG+ values of `WhiteRaffardDecoctionEffect_Level1/2` to the regular ones (attributed to ALCH-04, "NG+ values set to the regular ones"); `gen_alch.py`'s list lacks them (its `--verify --list` names them among the unlisted). Fix: add the three `WhiteRaffardDecoctionEffect_Level*` to the ALCH-04 entry of `gen_alch.py`. **Fixed** (5.x-GM `861a3217`, master's `gen_alch.py`): `--verify` no difference.
18. **Wyvern's per-hit wrapper is exact; it matters only for fist hits** (no action; for the owner's open call). The wrapper (`alchemy/decoctionsMelee.ws:379-399`) takes back only the stacks 5.x added in that call (5.x `npc.ws:5147-5174`), only for Geralt's hits with Wyvern active, nothing at the cap or without the decoction. A sword hit's stacks are cleared by Wyvern's own rule anyway, so the wrapper changes play only for fist hits (and melee damage actions that are not attacks); the test "a melee hit adds nothing" would pass without it. Replacing `CNewNPC.OnTakeDamage` instead means owning a 94-line 5.x event (HUD refreshes, Runeword 11's hunk) and conflicting with other mods' replacements, for no play difference. Recommendation: keep the wrapper and confirm the deviation; add a fist-hit check with sign stacks (F24). **Decided** (the owner, 2026-10-20): the wrapper confirmed; the fist-hit check added to `gmtest_alch10` (5.x-GM `861a3217`), passing in both trees.
19. **The bomb throw range clamp and the water effects in play** (no action; for the owner's open call). The clamp (5.x `petard.ws:133-142`) pulls a target point farther than 25 m back to 25 m; it matters only for a quick throw at a locked target beyond 25 m, since aimed throws are capped at 25 m in 1.32 too (1.32 and legacy aimed the arc at the far point and the bomb went off where its range ran out, probably in mid-air). The water effects (`alchemy/bombs.ws:73-111`, 5.x's) are cosmetic: a splash and sound in shallow water too; the rules are 1.32's (shallow: it carries on; deep: no explosion). `isFromBomb` now only gates the new tree's Heavy Artillery (SKL's). Options: (a) keep all, as now; (b) legacy's throw, a `@replaceMethod` of `W3Petard.OnProcessThrowEvent` without the clamp. Recommendation: (a): no rule depends on the clamp, and it removes an odd mid-air explosion. **Decided** (the owner, 2026-10-20): (a), the deviation confirmed.
20. **Two latent behaviour-tree functions are replaced as plain functions** (no action in code). `CBTTaskWraithDrainDance.Main` (`alchemy/bombs.ws:356`) and `BTTaskManageDjinnRage.Main` (`alchemy/dimeritium.ws:283`) keep their `Sleep` calls and compile; the same pattern runs in play for Yrden (`skills/yrden.ws:353`). [development.md](../development.md) states the rule for `@wrapMethod` only (added for `@replaceMethod` with this audit); a wraith's drain under Silver Dust and a djinn under Dimeritium are open checks.
21. **5.x's load-time sign unblock is inert** (no action). 5.x's `OnSpawned` unblocks the skills `DwimeritiumBomb_3` lists (5.x `r4Player.ws:680-686`); with legacy's data it lists none, as in legacy; the effect's `OnEffectRemoved` unblocks. Worth one in-game check: save under the effect, reload, the signs come back.
22. **5.x's combat end removes Griffin's ability from Geralt** (no action). 5.x `playerWitcher.ws:3378-3381` (wrapped, still runs); the port puts it back on drinking and on load; the ability now holds only values the port reads from the definitions.
23. **Stale comments and leftovers** (clear fix, cosmetic). `damage/formula.ws:58`, `:192` ("Kept until ALCH: Mutagen 2's resistance"; unused locals at `:199`, `:201`), `:454`; `damage/pipeline.ws:476` ("Mutagen 28: ALCH"); `gmWraithQuens`, a test counter in `alchemy/decoctionsSigns.ws:226-231`; the decoction files tag their overrides in the file header only ([development.md](../development.md#conventions) asks for a tag per override). **Fixed** (5.x-GM `eef6c32e`, `1f7e26d2`): the damage comments corrected and the unused locals removed (`formula.ws`, `pipeline.ws`, `pool.ws`; B); `gmWraithQuens` and its count moved to the tests as a test wrapper of `GMCastFreeQuen` (C). The decoction files' per-override tags are not added.
24. **Regression gaps** (clear fix, tests). Not exercised, or only as exec checks: a second dose in a later call (F1); Blizzard 3 on fixed costs (F4); Northern Wind's bonus in a hit (F2); potion duration not raising bomb damage (pool, damage over time, critical damage over time); Grapeshot 2 not breaking shields; the nest; `GMIsWildHuntMinion` (an ability added to the dummy); the 36 oil names against the data; `gmtest_alch16_transfer` (not in `gmtest_regress`); Chort (F3); fist hits for Wyvern, Katakan and Water Hag (F18); the caps of Alghoul, Forktail and Noonwraith (the kill test can pass with no hostile in range, `gmTestsAlchDecoctions.ws:320`); Succubus; Elemental's resistance after seconds of burning; Reliever's zero monster bonus; Basilisk and Nekker Warrior on unequipping; the cleanup's putting back on a real load; the item descriptions resolved by key (F6 to F9) and the decoction descriptions' numbers. One check cannot fail: ArchGriffin's dodge cost is compared with itself, both read with the decoction active (`gmTestsAlchDecoctions.ws:298`); read it before drinking, as `:291` does. **Partly fixed** (5.x-GM `3ee751ab`, `eef6c32e`, `1f7e26d2`): in the regression, a later-call Swallow dose (F1), Blizzard 3 on a fixed drain and on Whirl's (F4), Chort (F3); as exec checks, Northern Wind's bonus in a hit, scripted and after a real throw (F2), `GMIsWildHuntMinion` on the dummy, the caps of Alghoul, Forktail and Noonwraith, a hostile in range asserted for the kill checks, ArchGriffin's dodge cost read before drinking and its drain asserted. Slice D (5.x-GM `861a3217`): Wyvern's fist hit (F18, exec check), the descriptions by key (F6 to F9, F12, in the regression) and as built (exec check). Still open, as open checks: the potion-duration removal on bomb damage, Grapeshot 2 and shields, the nest, the 36 oil names against the data (their texts are checked), `gmtest_alch16_transfer` in the regression, fist hits of Katakan and Water Hag, Succubus, Elemental's resistance over time, Reliever's zero monster bonus, Basilisk and Nekker Warrior on unequipping, the cleanup's putting back on a real load.
25. **Docs that said what the code does not** (corrected with this audit). ALCH-02's quirk listed Golden Oriole among the strength-0 potions (its strength is its resistances, so its tiers differ); ALCH-11 said Succubus's timer "still starts"; ALCH-13 said the Arachas acid stays on the enemy (DL12 removes it); ALCH-09's slice 8 said the cleanup's putting back was verified (only the removal is tested); the save-impact list counted 5.x's Basilisk shrine bonus among the abilities the cleanup removes (it is a shrine effect: a pre-port save keeps it for its 6 game hours); ALCH-14 still described 5.x's bomb scaling as "in the port today" and its port form "if DL7 says so", and its deviation said `isFromBomb` "only marks them" (it gates the new tree's Heavy Artillery); ALCH-15's "5.x:" described the pre-port state; ALCH-16 said Hanged Man's Venom 1 gives +10% "in the port today" and that it ended SKL-14's open check (the wearing off of crit values stays SKL-14's); ALCH-04's open check (Tawny Owl's regen counted twice) was settled by ALCH-07; every other **Open checks** row said "—" while its slice listed what was not tested; the hand-off rows of ARM-10/15 and the oils lacked "(ended)"; [dmg.md](dmg.md) kept "Mutagen 28's specter block for ALCH to decide"; [arm.md](arm.md) listed ALCH as pending; the [skills ledger](ledger/skills.md) said "ALCH decides the threshold".
26. **Hand-offs and attribution** (corrected with this audit). `CMonsterNestEntity.<members>` holds no bomb change: legacy's change there is nest experience (`expOnNestDestroyedMod`, `bonusExpOnBossKilledMod`, `addExpOnlyOnceMod`), now in the XP row; the panel lines of F15 added to the UI row; F3's, F6's and F11's units noted in [attribution.csv](attribution.csv). The other hand-offs are complete and placed: CRAFT, LOOT, ECON, WGT, FOOD, EFX, AI, XP, UI, FIX; every hand-off received lands in a feature. Not ALCH, for the UI mapping: four legacy tooltip rows (`frost_resistance_perc`, `desc_knockdownchance_mult`, `vitalityCombatRegen`, `q108_bounce_arrows`) are in neither the port nor `attribution.csv`; legacy's generic `FrozenEffect` (5 s, +0.5) is unattributed (EFX).
27. **Porter's calls not confirmed by the owner** (owner decision). Besides the four open calls (the pheromone formulas, F4's Battle Trance, F18's Wyvern wrapper, F19's bombs): the oil line of a sword's tooltip stays 5.x's until UI (ALCH-16), the recipe book stays 5.x's until UI (ALCH-17), `toggledebugoils` not ported (ALCH-18), the inert Alchemy Table effect dropped (ALCH-02). Recommendation: confirm all four (each has no play effect, or waits for UI). **Decided** (the owner, 2026-10-20): all four confirmed, and the four open calls: the pheromone formulas skipped by name, Blizzard 3 without Battle Trance, Wyvern's wrapper, the bombs' clamp and water effects; Northern Wind's knockdown kept and Aard's bonus left to EFX (temporary until EFX), confirmed.
28. **Small differences with no effect** (no action). Water Hag's, Alghoul's and Ancient Leshen's loss on damage taken is computed before `super.OnTakeDamage` behind a damage check (legacy after, without it; the same result); Foglet's empty ability is not added to Geralt (no stats); unused 5.x locals in `W3Dimeritium.LoopFunction` and the critical damage over time; the inherited unused `argsFloat` in the debug commands; legacy's binary file had stale CRCs (the port's are valid).

**Doc corrections made with the audit:** F25, F26 and F20's rule: this page (ALCH-02's quirk, ALCH-04's open check, every **Open checks** row, ALCH-09's verification, ALCH-11, ALCH-13, ALCH-14's 5.x line, port form and deviation text, ALCH-15's and ALCH-16's 5.x lines, ALCH-16's "Ends", the hand-off rows of ARM-10/15, the oils, XP and UI, the save-impact list), [dmg.md](dmg.md) (DMG-05's decisions), [arm.md](arm.md) (the areas ARM waits for), the [skills ledger](ledger/skills.md), [attribution.csv](attribution.csv) (`InternalAddEffect` to ALCH-09 too; notes on `GetBaseItemData`, `AddItemStats`, `CalculateStatsComparance`, `CMonsterNestEntity.<members>`), [development.md](../development.md) (a replaced latent function), [deviations.md](deviations.md) (regenerated), the [status page](README.md#where-the-port-stands).

**Not reviewed:** the on-screen rendering of tooltips and the HUD; 1.32's own string tables (not in the repository: whether 1.32's texts for Blizzard 1/3 were right is inferred from legacy overriding only tier 2); 5.x's vanilla texts in languages other than English, German and Russian; how 5.x's Mutation 12 (a random decoction per kill) interacts with the decoctions; the generic damage-over-time and critical-effect changes (EFX's); NG+ in game (the policy: not tested).

**Suggested fix slices** (each touching distinct files; verified in game in one tree, since no skill is involved beyond SKL's, plus the regression in both):

- **A, potions** (`gm/alchemy/swallowHoneyOriole.ws`, `staminaCostInternal.ws`, `otherPotions.ws`, `gm/tests/gmTestsAlchPotions.ws`, `gmTestsAlchPotions2.ws`): F1, F4 (with the owner's Battle Trance call), F5 if (a), their regression checks (F24). **Done** (5.x-GM `3ee751ab`, 2026-10-20: F1, F4 and their checks; F5 and the Battle Trance call are the owner's), verified in both trees.
- **B, Northern Wind and the damage files** (`gm/damage/pool.ws`, `formula.ws`, `pipeline.ws`, `gm/tests/gmTestsAlchBombs.ws`): F2 (ends DMG-04's frozen deviation in [dmg.md](dmg.md)), F23's damage comments, the bomb regression checks (F24). **Done** (5.x-GM `eef6c32e`, 2026-10-20: F2, with the knockdown and Aard's force damage left to EFX as a deviation; F23's comments; Northern Wind's and the minion's checks), verified in both trees.
- **C, decoction hooks** (`gm/skills/quen.ws`, `gm/mutations/hudCounters.ws`, `gm/defense/dodge.ws`, `gm/alchemy/decoctionsDefense.ws`, `gm/mutations/takeDamage.ws`, `gm/alchemy/decoctionsSigns.ws`, `gm/tests/gmTestsAlchDecoctions.ws`): F3, F13, F14, F16, `gmWraithQuens`, the ArchGriffin test and the decoction checks (F24). **Done** (5.x-GM `1f7e26d2`, 2026-10-20), verified in both trees (the regression and the HUD; the exec checks in the classic tree).
- **D, texts and data** (`gm/alchemy/tooltips.ws`, `modGhostMode/localization/modGhostMode/*.csv`, `tools/gen_alch.py` and its output, `gm/tests/gmTestsAlchTooltips.ws`): F6, F7, F8, F9, F17; F10, F11, F12 as the owner decides. **Done** (5.x-GM `861a3217`, 2026-10-20, with F5 and F18's check and the owner's decisions), verified in both trees.
- **Docs**: F25, F26 and F20's rule done (2026-10-20); with the slices, the deviations they add or end (F4's text, F15's panel deviations, F9's and F10's rows, F12's texts, F11's toxicity line). **Done** (2026-10-20).

#### Audit close-out

Closed 2026-10-20: every finding is fixed, recorded or decided by the owner. Fixed and verified in both trees: F1 and F4 (5.x-GM `3ee751ab`), F2 (`eef6c32e`; the knockdown and Aard's force damage left to EFX, confirmed), F3, F13, F14, F16 and F23 (`1f7e26d2`), F5 to F12 and F17 (5.x-GM `861a3217`: the owner's calls on F5, F6, F10, F11 and F12), F24 in part (the checks added by slices A to D; the rest are open checks). Recorded: F15 (temporary deviations until UI in ALCH-10 and ALCH-11, confirmed), F20 to F22 and F28 (no action), F25 and F26 (doc corrections made with the audit). Decided by the owner (2026-10-20): F18 (Wyvern's wrapper, a fist-hit check added), F19 (the bombs' clamp and water effects kept), F27 (the oil tooltip line and the recipe book stay 5.x's until UI, `toggledebugoils` not ported, the inert Alchemy Table effect dropped, the pheromone formulas skipped by name in Acquired Tolerance, Blizzard 3 without Battle Trance). Checks at close: regression 725 passed, 0 failed in each tree (plus the panel's and the later-dose checks); `check_modsigns.py` 0 unmarked (379 bodies); `gen_alch.py --check` current and `--verify` no difference; `deviations.py --check` current. Deviations: every ALCH deviation is confirmed by the owner; the last two porter's calls on 2026-10-20 with the sign-off: ALCH-17's potion toxicity line (temporary, until UI) and the translations where legacy had none (Golden Oriole's buff in Czech, German, French and Italian, Samum 3 in the 8 non-English languages, Czech Blizzard 1 and 3); no ALCH deviation is left unconfirmed (`python tools/deviations.py --unconfirmed`). No owner decision is left open. What stays open after the sign-off: the open checks listed in the entries (among them real fights, kills, bombs and oils in play, the tooltips and menus on screen, the strings in the other eight languages, NG+, Katakan's 0 stacks seen once in the new tree and not reproduced, ALCH-10); the temporary deviations until UI and EFX; the hand-offs to other areas. **Signed off** by the project owner, 2026-10-20 (ALCH-01 to ALCH-18).

---

### Dependencies on other areas

- **Done areas ALCH builds on:** SKL-13 to SKL-18 (the alchemy skills and perks, `skills/brewing.ws`, `oils.ws`, `bombs.ws`, `mutation.ws`, `grasses.ws`), MUT-08, MUT-09, MUT-12, MUT-13 (`mutations/toxicity.ws`, `combatStart.ws`, `takeDamage.ws`), DMG (the damage functions hosting the decoction, oil, Golden Oriole, Petri and Dimeritium terms), STAM (stamina costs and drains), ARM-09, ARM-10, ARM-11, ARM-15 (Wolven, Manticore, Viper, Netflix), ENCH-08, ENCH-09 (`npcDeath.ws`, potion timers), ITEM (`GMFindAttrInTooltipSettings`).
- **Areas ALCH waits for or shares with:** EFX (frozen, burning, poison, bleeding, blindness), AI (monster abilities Silver Dust and Dimeritium block, rotfiends, the djinn, Wild Hunt minions), UI (tooltip layout, the toxicity panel, the oil tooltip), CRAFT, LOOT, ECON, WGT, FOOD (recipes, availability, prices, weights, edibles), XP (nests).

### Hand-offs received

Every item other areas handed to ALCH, and where it lands:

| From | Item | ALCH |
|---|---|---|
| DMG-01 deviation (until ALCH) | Mutagen 2's resistance bonus | ALCH-13 (ends it) |
| DMG-02 deviation (until ALCH) | Oils' resistance reduction; Mutagen 28; Dimeritium's armor and resistance cut; Mutagen 2's debuff | ALCH-16 (no play difference: 0 in every version), ALCH-13, ALCH-15 (end them) |
| DMG-03 deviation (until ALCH) | Mutagen 5's attack power | ALCH-10 (ends it) |
| DMG-04 deviation (until ALCH) | Mutagen 9 in the pool | ALCH-11 (ends it) |
| DMG-05 deviations (until ALCH) | Golden Oriole's T3 poison absorption; Dimeritium's final-damage cut | ALCH-05, ALCH-15 (ended) |
| DMG-07 deviation (until ALCH) | Petri's Philtre T3 in effect durations | ALCH-06 (ends it) |
| DMG-11 (notes) | Mutagen 26 (Leshen), Black Blood returned damage | ALCH-13, ALCH-07 (the code is already legacy's; the values) |
| DMG-12 deviation (until ALCH) | The Succubus decoction's puppet bonus | ALCH-11 (ends it) |
| MUT-09 deviation (until ALCH) | Euphoria at 5.x's 50% overdose threshold | ALCH-01 with DL1 (ends it) |
| MUT (hand-off) | The rest of `W3Effect_Toxicity.OnUpdate` | ALCH-01 |
| SKL-10 deviation (until ALCH) | Petri's Philtre T3 on Yrden | ALCH-06 (ends it) |
| SKL-11 deviation (until ALCH) | Mutagen 19's Quen intensity and Petri's Philtre T3 on Quen | ALCH-11, ALCH-06 (end it) |
| SKL (hand-off; SKL-13 to 17 open checks) | The toxicity rules, potion, decoction and bomb items, mutagen decoctions | ALCH-01, ALCH-03 to ALCH-15 |
| STAM-09, STAM (hand-off) | ArchGriffin decoction's cost; Mutagen 21's heal; Troll and Nekker Warrior decoctions; potion and decoction tooltips | ALCH-12, ALCH-17 (the `npc.ws` `GainStat`/`ForceSetStat` lines STAM listed under Troll are Nekker Warrior's horse panic) |
| ENCH-09 (hand-off) | Tawny Owl's night freeze | ALCH-07 |
| ARM-10, ARM-15 (hand-offs) | Potion duration with Manticore and Netflix gear | Ported already on potions (SKL-13's `CalculatePotionDuration`, ARM-15); 5.x's potion duration on bomb damage removed with ALCH-14, DL7 (ended) |
| ARM-11 (dependency) | Golden Oriole with Viper | ALCH-05 |
| ARM, SWD (hand-offs) | Oil items, oil tooltip rows, the stuck-oil fix | ALCH-16 (ended; the oil tooltip's layout and ARM-09's stats line stay UI's) |
| ITEM (hand-off, audit) | The pheromones' and Killer Whale's quality | ALCH-08 |
| SKL-17 (open check) | The overdose threshold for Frenzy and Endure Pain | ALCH-01 |

### Hand-off to other areas

| Area | Changes |
|---|---|
| CRAFT | Recipe ingredients (117 recipes in the alchemy recipe files, both folders), the alcohol recipes (with FOOD), the Alchemy dismantle kit and `CR4InventoryMenu.PlayerDismantleItem`, `W3InventoryGridContext.execurePrimaryAction`/`updateInputFeedback` (dismantle input), named mutagens dismantled into lesser ones (`recycling_parts` on 27 mutagens), the missing Tawny Owl recipe granted on load (`OnSpawned`), quest items' recycling parts |
| LOOT | Recipe entries in shops and loot (the Master Alchemist's stock, pheromone recipes at four more vendors, recipe level gates: T2 at 8/9/10, T3 at 16/18/20, which do not match the changelist's 10 and 20), mutagen drops (`_monster_add__Mutagens_lesser`), the standalone starts' mutagens |
| ECON | Prices of alchemy items and recipes, `mod_alchemy`, `mod_alcohol` |
| WGT | Alchemy item weights (`default_potion_stats`, `ClearingPotion_stats`, `RestoringPotion_stats`, `default_oil_stats`, `default_bomb_stats`, `CommonMutagenAbility`) |
| FOOD | Well fed, well hydrated, drunkenness, alcohol and raw-food toxicity (`alco_toxicity*`, `food_toxicity`), `EACIT_Edibles` and `W3AlchemyManager.CookItem` (cooking) (mapped 2026-10-23: [food.md](food.md)) |
| EFX | Generic bleeding, poison critical, frozen (DoT pause, Aard damage on frozen enemies, legacy's removal of the knockdown on a frozen enemy's hit, the generic `FrozenEffect`'s +0.5), hypnotized and frost-slowdown effects |
| AI | The frozen rotfiend's explosion, witch boiling water, monster abilities blocked by Silver Dust and Dimeritium |
| XP | Monster nest experience (`CMonsterNestEntity.AddExp`, `AddBonusExp` and the modifiers in `CMonsterNestEntity.<members>`: `expOnNestDestroyedMod` 25, `bonusExpOnBossKilledMod` 25, `addExpOnlyOnceMod`; audit F26), `fb3_internal` |
| UI | Buying ingredients from the alchemy menu (`CR4AlchemyMenu`: 5.x has its own; legacy's Herbalist or Alchemist gate and merchant panel), the recipe book's layout, the character panel's toxicity lines (strings 2110992423–425, 519), the oil tooltip's stats (`AddOilStats`, ARM-09), `W3TooltipComponent.GetRecipeDataFromXML` (a typo fix, also missing from `units.csv`), `AddItemStats`' toxicity line with Adaptation; the decoctions' lines in the character panel and stats popup (legacy removed 5.x's Water Hag `damageIncrease` lines in `GetOffenseStatsList` and `CharacterStatsPopup.GetEquippedCrossbowDamage`, added Foglet's and Wraith's; audit F15, recorded as temporary deviations in ALCH-10 and ALCH-11); legacy's descriptions by name key for books, keys and quest items (ported with ALCH-17 by the owner's call, audit F6: UI checks them with its tooltip layout); `GetBaseItemData`'s other legacy hunks, not ALCH's: a Gwent card's empty description and the description line of armor and weapons |
| FIX (FIX-NEW5, sweep D G11; mapped as an area of its own, the owner's decision 2026-11-02) | `FixQuestItems` (alchemy quest items) |
| tools | Done 2026-10-20: `change_units.py` compares string and name literals, so the three `types.ws` `MonsterCategoryTo*` functions (ALCH-16), `GetRecipeDataFromXML` (UI's typo fix, unattributed until UI is mapped) and four more units whose only change is a literal are inventoried |

### Save impact

None expected for a new playthrough: potion, decoction, bomb and oil values are read from the definitions when used. Facts for the port and the release notes:
- Decoction stacks and buffs are abilities on Geralt that a save keeps (Katakan, Water Hag, Alghoul, Forktail, Ancient Leshen, Griffin stacks, Nightwraith's, 5.x's Werewolf night ability): a save made mid-decoction before the port may carry 5.x's: a load-time cleanup removes them on every load (`alchemy/decoctionCleanup.ws`, slice 8). 5.x's Basilisk shrine bonus is a shrine effect, not an ability: a save made before the port keeps it until its 6 game hours run out (audit F25).
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

### Port order

Proposed; each slice compiles and is verified on its own, in both trees where skills are involved (the threshold moves Frenzy and Endure Pain):

| # | Slice | Ends |
|---|---|---|
| 1 | ALCH-01 toxicity (DL1) with ALCH-09's offset data (DL2): **done** (2026-10-20, 5.x-GM `ad3f4dec`) | MUT-09's threshold deviation (ended); SKL-17's open check |
| 2 | ALCH-02 stacking and drinking rules; ALCH-03 and ALCH-08 data (DL3, DL10): **done** (2026-10-20, 5.x-GM `86483235`) | ITEM's quality hand-off (ended) |
| 3 | ALCH-04 Swallow, White Raffard, White Honey; ALCH-05 Golden Oriole (DL5): **done** (2026-10-20, 5.x-GM `89a09d41`) | DMG-05's Golden Oriole deviation (ended) |
| 4 | ALCH-06 Petri's Philtre T3; ALCH-07 other potions (DL4): **done** (2026-10-20, 5.x-GM `b3e7da72`) | DMG-07's, SKL-10's and SKL-11's Petri deviations; ENCH-09's Tawny Owl hand-off (ended) |
| 5 | ALCH-10 melee-stacking decoctions: **done** (2026-10-20, 5.x-GM `b80771ad`) | DMG-03's Mutagen 5 deviation (ended) |
| 6 | ALCH-11 sign decoctions: **done** (2026-10-20, 5.x-GM `5497dd03`) | DMG-04's Mutagen 9, DMG-12's Succubus and SKL-11's Mutagen 19 deviations (ended) |
| 7 | ALCH-12 sustain and stamina decoctions: **done** (2026-10-20, 5.x-GM `76928461`) | STAM's and STAM-09's hand-offs (ended) |
| 8 | ALCH-13 defensive decoctions and ALCH-09's four unchanged ones (DL6), the load-time cleanup: **done** (2026-10-20, 5.x-GM `0646ce16`) | DMG-01's and DMG-02's Mutagen 2 and 28 deviations (ended) |
| 9 | ALCH-14 bombs (DL7): **done** (2026-10-20, 5.x-GM `c346cf34`) | — |
| 10 | ALCH-15 Dimeritium: **done** (2026-10-20, 5.x-GM `977bcb46`) | DMG-02's and DMG-05's Dimeritium deviations (ended) |
| 11 | ALCH-16 oils (DL9; after the inventory fix for `types.ws`): **done** (2026-10-20, 5.x-GM `9f50e5f9`) | DMG-02's oil deviation; SWD's and ARM's oil hand-offs (ended) |
| 12 | ALCH-17 tooltips and descriptions, ALCH-18 debug commands: **done** (2026-10-20, 5.x-GM `b37c48c9`) | STAM's tooltip hand-off (ended) |
