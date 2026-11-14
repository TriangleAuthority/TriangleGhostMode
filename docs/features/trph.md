# TRPH: trophies

The monster trophies Geralt hangs on Roach's saddle: the bonus each one gives him while it is equipped in the horse's trophy slot, and what happens when he takes a trophy from a monster. Ghost Mode's changelist has its own section, "Trophies" (lines 871–911), and names a trophy in two other places (the Golden Oriole note, lines 749–751, and the Wild Hunt's frost damage, lines 1123–1125); the mod description's section 5, "Items and equipment", explains the intent; legacy's design sheet is `design-docs/trophies.ods` on `legacy-GM`.

**The player-visible texts first.** Legacy's changelist, quoted exactly: "All trophies now have individual bonuses:" followed by 36 lines, "Noonwraith (lvl 2, prologue): +5% to Sign Intensity", "Gryphon (lvl 3, prologue): +5% to Attack Power", "Wyvern (lvl 7, No Man's Land): +5% to stamina regen speed", "Cockatrice (lvl 8, No Man's Land): +10% to Aard Intensity", "Nightwraith (lvl 10, No Man's Land): +10% to Yrden Intensity", "Gravehag (lvl 10, No Man's Land): +5% to Focus gain", "Fogling (lvl 12, No Man's Land): +10% to Quen Intensity", "Czart (lvl 20, No Man's Land): +25% to critical hit power", "Ekimma (lvl 22, No Man's Land): +15% to critical hit chance", "Wyvern (lvl 23, No Man's Land): +25% to poison resistance", "Gryphon_sq108 (lvl 24, No Man's Land): +15% to Attack Power", "Arachas (lvl 33, No Man's Land): +40 to max toxicity", "Doppler (lvl 13, Novigrad): +25% to bonus money", "Wild Hunt Minion (lvl 14, Novigrad): +25% to frost resistance", "Succubus (lvl 15, Novigrad): +10% to Axii Intensity", "Noonwraith_mh308 (lvl 16, Novigrad): +5 to Vitality regen", "Dao (lvl 24, Novigrad): +40 to armor reduction", "Leshy (lvl 25, Novigrad): +10% to armor reduction", "Katakan (lvl 26, Novigrad): +15% to Quen Intensity", "Gryphon (lvl 35, Novigrad): +15% to Igni Intensity", "Nekker Warrior (lvl 16, Sellige): +5% to resistance against monsters", "Wraith (lvl 17, Sellige): +5% to resistance against magic creatures", "Water Hag (lvl 18, Sellige): +20% to potion duration", "Lamia (lvl 19, Sellige): +25% to bleeding resistance", "Leshy (lvl 22, Sellige): +10% to Sign Intensity", "Forktail (lvl 28, Sellige): +25% to burning resistance", "Fiend (lvl 29, Sellige): +35% to critical hit power", "Cave Troll (DLC): +500 to Vitality", "Cyclop (lvl 35, DLC): +15% to bludgeoning resistance", "Camerlengo (lvl 37, DLC): +15% to piercing resistance", "Dracolizard (lvl 38, DLC): +20% to Igni Intensity", "Wight (lvl 39, DLC): +20 to max encumbrance", "Spriggan (lvl 45, DLC): +100% to bonus herbs", "White Basilisk (lvl 46, DLC): +10% to stamina regen speed", "Garkain (lvl 47, DLC): +20% to Axii Intensity", "Sharley Matriarch (lvl 48, DLC): +60 to armor reduction"; then "Trophies are no longer auto-equipped when you loot them." Elsewhere: "Note: it is still possible to achieve 100% poison resistance with wyvern trophy (+25% poison resistance) and certain armors." and "You can counter this damage partially with better armor, monster hunt trophy (+50% resistance to frost) or with better dodging." The mod description: "There also is an issue with monster hunt trophies giving you useless and repetitive bonuses." and "trophies were completely redone: all of them are now unique and provide useful bonuses which are related to abilities of a creature the trophy comes from;". Legacy has no trophy options and no strings of its own: every trophy text is the game's (decoded from 1.32's and 5.x's `en.w3strings` with `w3strings.py`). The trophies' names, unchanged in 5.x (e.g. "Griffin trophy" 1063794, "Grave hag trophy" 1063801, "Wild Hunt hound trophy" 1063438 for the changelist's "Wild Hunt Minion", "Ekhidna trophy" 1082745 for its "Lamia", "Golyat trophy" 1116877, "Camerlengo's Seal" 1214671, "Umbra trophy" 1196465, "King of Swineherd's crown" 1135578, "Conserved shaelmaar trophy" 1136794); the horse slot's name "Trophy" (1076175); the common description `item_desc_trophy` (1082377), which **5.x rewrote**: 1.32 "Trophies can be turned in for a reward.", 5.x "Strap trophies to your saddle to receive a bonus."; Blood and Wine's own descriptions, which name no bonus (e.g. "Unique trophy from the wight, the Spoon Collector." 1166094). A trophy's tooltip lists its bonus by the attribute's name (e.g. "Adrenaline Point gain" 1078305, "Bonus gold" 1084504, "Chance to find additional herbs" 1084506, "Armor piercing" 1083714, "Maximum inventory weight" 1085275); the names legacy added that trophies use, "Frost resistance" (2110992013), "Enemy damage resistance reduction" (2110992014), "Potion duration" (2110992015) and "Vitality regeneration during combat" (2110992157), are ported (UI-07, SWD-09, ALCH-17).

**What 5.x did in this area** (from `vanilla-5.x` and the 5.x install's full XML, unverified in game): nothing to the trophies themselves. **No new trophy**: 5.x defines the same 40 trophy items (base game 28, Blood and Wine 10, Hearts of Stone 2) in the same six files, every item and ability equal to 1.32's (re-save noise only). The code that gives a trophy's bonus is 1.32's: `W3HorseManager.EquipItem` and `UnequipItem` add and remove every ability of the item in `EES_HorseTrophy` but `base_trophy_stats` to Geralt (5.x changed this file only for the Fire Horse gear); the readers of the bonus attributes are 1.32's (`W3Container.CheckForBonusMoney`, `W3RefillableContainer.CheckForBonusHerbs`, the wight trophy's Spoon Collector chance in `W3Container`, `CNewNPC.OnDeath`'s experience bonus); the auto-equipping of a looted trophy (`W3ActorRemains.OnItemTaken`, `FinalizeLooting`) and of a contract trophy (`ProcessMonsterHuntTrophyQuest`) is 1.32's. What 5.x added around trophies: the new description text above; the accessibility option **"Auto-loot"** (`Accessibility`/`AutoLoot`), which takes a corpse's whole loot without the loot panel (`W3Container.OnInteractionActivated`: `TakeAllItems` on a `W3ActorRemains`), so with it on a trophy goes through the same `OnItemTaken` and `FinalizeLooting`; 5.x's bomb damage bonus from `potion_duration` (the Water Hag trophy's stat), which ALCH already removed ([deviations.md](deviations.md), ALCH's bomb changes).

**How legacy Ghost Mode implements it.** Data: the bonus abilities in the six `def_item_trophies.xml` files (base game, `dlc\bob`, `dlc\ep1`; `items` and `items_plus`, legacy's NG+ files equal to its regular ones): 38 abilities rewritten (1.32's experience, gold, herb and dismemberment bonuses replaced by one bonus each; 28 base game, 8 Blood and Wine, 2 Hearts of Stone), four unused abilities emptied (`nekkers_`, `drowned_dead_`, `bies_`, `erynie_trophy_stats`, which no item names); the item entries only for tags (the Camerlengo's Seal and NG+'s Wyvern trophy `mq1051` lose `Quest`; Hearts of Stone's crown loses `EncumbranceOff`) and prices (ECON-02, ported); the shared `base_trophy_stats` (weight 2 → 5). Scripts: `W3ActorRemains.OnItemTaken` and `FinalizeLooting` (the queue and the equip block commented out), `ProcessMonsterHuntTrophyQuest` (the whole body commented out: no equip and no teleport of Roach to Geralt). Legacy did not touch the horse manager, the bonus readers, the tooltips' trophy code beyond UI-06's, or any string.

Unit lists: [attribution.csv](attribution.csv). **90 units carry a TRPH feature**: 87 XML units (43 regular, 44 NG+) and 3 script units; TRPH also shares UI-07's `frost_resistance_perc` tooltip row. Six weight-only units of the trophy files are WGT's (`base_trophy_stats` in the base game's and Blood and Wine's files, Hearts of Stone's crown item; regular and NG+).

**Status:** signed off by the owner (2026-11-02). The [area decisions](#area-decisions) and [porter's calls](#porters-calls) were decided by the owner on 2026-11-02.

## Scope

**TRPH covers** the trophies' bonus abilities, the trophy items' tags that legacy changed, and how a trophy reaches Roach (no auto-equipping on looting or after a contract).

**Unchanged by legacy, and by 5.x** (from the code and data): how a trophy is worn and what it does while worn (one trophy at a time in Roach's trophy slot, `EES_HorseTrophy`; its abilities but `base_trophy_stats` given to Geralt while it is equipped, wherever Roach is; taken away when it is unequipped); which trophies exist, where they come from and their models (`equip_template`); the Wight trophy's own Spoon Collector rule (a 10% chance per container of a bonus item while it is equipped, `W3Container`, `q702_wicht_trophy`), kept on top of legacy's new bonus; that a trophy tagged `Quest` cannot be sold or dropped (`guiPlayerInventoryComponent`; the shop marks it "not for sale"; 31 of the 40 keep the tag in legacy, so their ECON-02 price shows but cannot be cashed, in 1.32 as in legacy); the bonus readers (above); the trophy descriptions (legacy changed no string).

**Already ported by other areas** (nothing left for TRPH):

| Subject | Ported by | What |
|---|---|---|
| The trophy items' prices (56 entries, regular and NG+; trophies ×1.28 in all) | ECON-02 (PE11, signed off) | `gm_econ.xml` `extend` entries; TRPH's bonuses are in the abilities, not the item entries |
| A trophy's tooltip lists its stats like gear | UI-06 (signed off) | Legacy's flag passing trophies to `AddItemStats` as gear changes only the toxicity line; the only trophy with one is the Arachas trophy (`toxicity` 40), which the port passes as gear, so it reads "Maximum Toxicity +40" as in legacy, with and without Expert Brewer ([TRPH-01](#trph-01-base-game-trophy-bonuses)) |
| The tooltip rows and names for frost resistance, combat Vitality regen, resistance reduction and potion duration | UI-07, SWD-09, ALCH-17 (signed off) | `tooltip_settings.csv`, strings 2110992013–015, 2110992157 |
| The character panel's bonus gold line and the experience bonus lines removed | UI-05 (signed off) | |
| 5.x's bomb damage bonus from `potion_duration` removed | ALCH (signed off) | So the Water Hag trophy lengthens potions only, as legacy |
| Adrenaline gain from hits read as 0.1 × (1 + `focus_gain`) | SKL-07 (signed off) | The Grave Hag trophy's `focus_gain` +0.1 is +10% adrenaline gain, summed with Razor Focus and Adrenaline Burst in both trees |

**Not TRPH:**

| Subject | Area | Why |
|---|---|---|
| The trophies' weight: `base_trophy_stats` 2 → 5 (base game and Blood and Wine files, regular and NG+, 4 units, weight-only), Hearts of Stone's King of Swineherd's crown loses `EncumbranceOff` (2 units) and weighs 5 (`pig_contest_trophy_stats`' weight `max` 0 → 5), the Conserved shaelmaar trophy 2 → 5 | WGT | Weights are WGT's, except inside the two Hearts of Stone abilities: `gen_trph.py` gives those whole with legacy's weight nodes (5), and WGT's generators skip every name another DLC file defines (parallel-ports.md, section 5) |
| `FixQuestItems` (`gm_bugfixes.ws`): a load fix-up removing the `Quest` tag from many items in a save, the Camerlengo's Seal among them, and the Umbra trophy's after its quest | FIX-03 | A general quest-item fix (it also releases the Umbra trophy for sale after its quest, `mq7017_talking_horse`); TRPH-02's tag change on the definition already reaches items a save holds (item tags are read from the definition, [development.md](../development.md#fine-grained-xml-overrides-50)), so the port needs no fix-up for the Seal |
| The Vitality regen options that scale the Noonwraith trophy's +5 regen (`W3Effect_AutoVitalityRegen`, `GetCombatVitalityRegen`, `GetOutOfCombatVitalityRegen`; unattributed) | OPT | Options |

## Changes at a glance

### What Ghost Mode changed

A trophy's bonus is an ability of the trophy item that the horse manager gives Geralt while the trophy is equipped; legacy rewrote the abilities. 1.32's 38 trophy abilities gave +5% experience from monsters (13) or from humans (6), bonus gold (7: +5%, the Swineherd's crown +15%), +5% herbs (4) or +10% dismemberment chance (6), and two a little of several; legacy gives each trophy one bonus of its own, scaled to the trophy's level, mostly combat stats.

| # | Feature | Vanilla 1.32 (and 5.x) | Legacy GM | Units |
|---|---|---|---|---|
| TRPH-01 | Base-game trophy bonuses | +5% kill experience, +5% bonus gold, +5% herbs or +10% dismemberment (e.g. Griffin trophy: dismemberment +10%; Grave hag trophy: experience from humans +5%) | One combat or utility bonus each (Griffin trophy +5% attack power; Grave hag trophy +10% adrenaline gain; Doppler trophy +25% bonus gold; Cave troll trophy +500 Vitality); four unused abilities emptied; NG+'s Wyvern trophy (`mq1051`) no longer a quest item | 65 (32 regular, 33 NG+) |
| TRPH-02 | Blood and Wine trophy bonuses | +5% kill experience, gold, herbs or dismemberment; the Silver basilisk trophy +1% of each, the Camerlengo's Seal +3% gold and +1% experience | Golyat trophy +15% bludgeoning resistance, Wight trophy +20 maximum weight, Grottore and Umbra trophies +100% herbs, Shaelmaar trophy +60 armor piercing, ...; the Camerlengo's Seal no longer a quest item | 18 (9, 9) |
| TRPH-03 | Hearts of Stone trophy bonuses | King of Swineherd's crown +15% bonus gold, Conserved shaelmaar trophy +5% | +35% and +50% (not in the changelist) | 4 (2, 2) |
| TRPH-04 | Trophies no longer auto-equipped | A trophy taken from a corpse is equipped on Roach when the loot window closes; a contract's trophy is equipped and Roach brought next to Geralt | The trophy stays in Geralt's inventory; Roach stays where she is | 3 script units |

**The trophies one by one** (legacy's value from the code; the changelist's where it differs; 1.32's and 5.x's bonus; what the bonus meets in the port):

| Trophy (item) | Changelist | 1.32 and 5.x | Legacy | Meets |
|---|---|---|---|---|
| Griffin trophy (`q002_griffin_trophy`, prologue) | Gryphon lvl 3 | dismemberment +10% | attack power +5% (`gryphon_trophy_stats`) | DMG-03 |
| Noonwraith trophy (`mq0003`, White Orchard) | Noonwraith lvl 2 | human XP +5% | Sign intensity +5% | DMG-06 |
| Wyvern trophy (`mq1051`) | Wyvern lvl 7 | monster XP +5% | stamina regen +5% (`staminaRegen` mult) | STAM-04 |
| Cockatrice trophy (`mh101`) | lvl 8 | dismemberment +10% | Aard intensity +10% | DMG, SKL (Aard) |
| Nightwraith trophy (`mh103`) | lvl 10 | human XP +5% | Yrden intensity +10% | DMG, SKL |
| Grave hag trophy (`mh106`) | lvl 10, "+5% to Focus gain" | human XP +5% | **adrenaline gain +10%** (`focus_gain` +0.1; DT1) | SKL-07 |
| Foglet trophy (`mh108`) | Fogling lvl 12 | bonus gold +5% | Quen intensity +10% | SKL-11 |
| Chort trophy (`mh107`) | Czart lvl 20 | monster XP +5% | crit damage +25% | DMG-03 |
| Ekimmara trophy (`mh104`) | Ekimma lvl 22, "+15%" | monster XP +5% | **crit chance +10%** (DT2) | DMG-03 |
| Wyvern trophy (`mh105`) | Wyvern lvl 23 | monster XP +5% | poison resistance +25% | EFX, ALCH (Golden Oriole) |
| Archgriffin trophy (`sq108`) | Gryphon_sq108 lvl 24 | dismemberment +10% | attack power +15% | DMG-03 |
| Arachas trophy (`mh102`) | lvl 33 | herbs +5% | maximum toxicity +40 (`toxicity` base) | ALCH (overdose threshold, balance.md) |
| Doppler trophy (`mh305`) | lvl 13 | bonus gold +5% | bonus gold +25% | ECON, LOOT-06 |
| Wild Hunt hound trophy (`mh307`) | Wild Hunt Minion lvl 14, "+25%" (but "+50%" in the Wild Hunt section) | herbs +5% | **frost resistance +50%** (DT3) | AI-15 (the Hunt's frost damage), EFX-05 (frost slowdown) |
| Succubus trophy (`mh303`) | lvl 15 | bonus gold +5% | Axii intensity +10% | SKL (Axii) |
| Noonwraith trophy (`mh308`) | Noonwraith_mh308 lvl 16 | human XP +5% | Vitality regen +5 in and out of combat | UI-05, OPT (regen options) |
| Earth elemental trophy (`mh306`) | Dao lvl 24 | dismemberment +10% | armor piercing +40 (`armor_reduction`) | DMG-01 |
| Leshen trophy (`mh302`) | Leshy lvl 25 | monster XP +5% | enemy resistance reduction +10% (`armor_reduction_perc`) | DMG-01 |
| Katakan trophy (`mh304`) | lvl 26 | monster XP +5% | Quen intensity +15% | SKL-11 |
| Griffin trophy (`mh301`) | Gryphon lvl 35 | dismemberment +10% | Igni intensity +15% | SKL (Igni) |
| Nekker warrior trophy (`mh202`) | lvl 16 | herbs +5% | monster damage resistance +5% (`rending_resistance_perc`) | DMG |
| Wraith trophy (`mh207`) | lvl 17 | human XP +5% | elemental damage resistance +5% | DMG |
| Water hag trophy (`mh203`) | lvl 18 | human XP +5% | potion duration +20% | SKL-13 (summed with Prolonged Effects) |
| Ekhidna trophy (`mh210`) | Lamia lvl 19 | bonus gold +5% | bleeding resistance +25% | EFX |
| Leshen trophy (`mh204`) | Leshy lvl 22 | monster XP +5% | Sign intensity +10% | DMG-06 |
| Forktail trophy (`mh208`) | lvl 28 | monster XP +5% | burning resistance +25% | EFX |
| Fiend trophy (`mh206`) | lvl 29 | monster XP +5% | crit damage +35% | DMG-03 |
| Cave troll trophy (`mh201`) | "Cave Troll (DLC)" | monster XP +5% | Vitality +500 | XP-08 (legacy's 50 per level) |
| Golyat trophy (`q701_cyclops`) | Cyclop lvl 35 | monster XP +5% | bludgeoning resistance +15% | DMG |
| Camerlengo's Seal (`camm_trophy`) | Camerlengo lvl 37 | bonus gold +3%, XP +1% each | piercing resistance +15%; not a quest item | DMG; ECON (sellable at 250) |
| Slyzard trophy (`mq7010`) | Dracolizard lvl 38 | dismemberment +10% | Igni intensity +20% | SKL (Igni) |
| Wight trophy (`q702_wicht`) | Wight lvl 39 | monster XP +5% | maximum weight +20 (`encumbrance`) | WGT |
| Grottore trophy (`mq7002`) | Spriggan lvl 45 | herbs +5% | herbs +100% (every herb plant gives one more of each herb) | LOOT, CRAFT |
| Umbra trophy (`mq7017_zmora`, shares Grottore's ability) | — | herbs +5% | herbs +100% | LOOT, CRAFT |
| Silver basilisk trophy (`mq7018`) | White Basilisk lvl 46 | +1% gold, XP, dismemberment, herbs | stamina regen +10% | STAM-04 |
| Garkain trophy (`q704`) | lvl 47 | monster XP +5% | Axii intensity +20% | SKL (Axii) |
| Shaelmaar trophy (`mh701`) | Sharley Matriarch lvl 48 | bonus gold +5% | armor piercing +60 | DMG-01 |
| Griffin trophy (`mq7009`, Blood and Wine, shares the prologue griffin's ability) | — | dismemberment +10% | attack power +5% | DMG |
| King of Swineherd's crown (`q602_pig_contest`) | — | bonus gold +15% | bonus gold +35% | ECON, LOOT-06 |
| Conserved shaelmaar trophy (`q603_sharley`) | — | bonus gold +5% | bonus gold +50% | ECON, LOOT-06 |

How the bonuses work in play (from the code, unverified): "bonus gold" adds its share to the money in a container or corpse when Geralt first comes in range of it (`CheckForBonusMoney`, rounded; also on a refill near him), stacking with gear's bonus gold; "herbs" rolls once per herb kind in a plant, so +100% always adds one of each; the resistances, crit, attack power, Sign intensities, armor piercing and resistance reduction, Vitality, regen, toxicity, weight and potion duration are attributes the port's own formulas already read from Geralt (DMG-01's formula reads `armor_reduction` and `armor_reduction_perc` of the attacker; STAM-04's regen the `staminaRegen` multiplier; ALCH and SKL-13 the potion duration).

### What 5.x changed

| # | 5.x change (from code and data) |
|---|---|
| TRPH-01 to TRPH-03 | None: the abilities and items are 1.32's; the common description now says "Strap trophies to your saddle to receive a bonus." (PT8) |
| TRPH-04 | None in the code; 5.x's "Auto-loot" option loots corpses through the same functions |

### Classification and proposed action

| # | Feature | Class | Proposed action |
|---|---|---|---|
| TRPH-01 | Base-game bonuses | clean | Legacy's abilities whole (PT2), DT1 to DT3 for the three values the changelist contradicts |
| TRPH-02 | Blood and Wine bonuses | clean | Legacy's abilities whole (PT2), the Seal's tag (PT4) |
| TRPH-03 | Hearts of Stone bonuses | clean | Legacy's abilities whole, `replace` (PT2, PT5) |
| TRPH-04 | No auto-equipping | clean | Legacy's three changes on 5.x's bodies (PT7) |

---

### TRPH-01 Base-game trophy bonuses

| | |
|---|---|
| Kind | tuning |
| Pillars | P6 (money scarce: one gold trophy of note), P10 (no experience from gear), P8 (vanilla's trophy slot, a useful bonus in it) |
| 5.x class | clean |
| Flags | balance, needs-decision (DT1 to DT3) |
| Depends on | DMG-01 (attack power, crit, armor piercing, resistance reduction, resistances), STAM-04 (stamina regen), SKL-07 (adrenaline gain), SKL-13 and ALCH (potion duration, toxicity), EFX (effect resistances), XP-04 (reads the experience bonuses the rework removes), ECON (bonus gold), UI-06 and UI-07 (tooltips) |
| Skill trees | n/a: no trophy names a skill; the bonuses are generic attributes that the skills' own bonuses add to in both trees (adrenaline gain with Razor Focus, classic `GM_C_sword_s20`, new `sword_s20`, and Adrenaline Burst, `perk_10`, `perk_42`; potion duration with Prolonged Effects, classic `alchemy_s4`, new tree's own attribute `gm_potion_duration`; Sign intensity with the Sign skills); checked in both trees by the regression |
| Port form | `tools/gen_trph.py`: each changed trophy ability of `gameplay/items/def_item_trophies.xml` from `legacy-GM`, whole, `on_conflict="replace"`, in `gm_trph.xml` in Ghost Mode's DLC `items/` and `items_plus/` (legacy's NG+ file equals its regular one); NG+'s Wyvern trophy `mq1051` given whole without `Quest` (PT2, PT4) |
| Port status | signed off (2026-11-02) |
| Open checks | The tooltip seen on screen (read by script only) |
| Save impact | none (expected): the ability is given to Geralt by name and its values come from the definitions; a trophy already on Roach shows the new bonus |
| NG+ counterpart | legacy's NG+ abilities (equal to the regular ones; 1.32's NG+ equal to its regular ones too), untested |

**What it does** (changelist 874–902, 749–751, 1123–1125; mod description section 5): every base-game trophy gives one bonus related to its monster (the [table](#what-ghost-mode-changed) above), instead of 1.32's repeated +5% experience, gold, herbs or dismemberment. In play a trophy is a choice of one bonus at a time: early ones small (Griffin trophy +5% attack power, Noonwraith trophy +5% Sign intensity), later ones larger and specialised (Archgriffin trophy +15% attack power, Fiend trophy +35% crit damage, Earth elemental trophy +40 armor piercing, Cave troll trophy +500 Vitality, Arachas trophy +40 maximum toxicity), some aimed at one enemy (the Wild Hunt hound trophy's +50% frost resistance against the Hunt's frost damage, AI-15). No base-game trophy gives experience any more (pillar P10: the port already removed the swords' and crossbows' experience bonuses, SWD-02, XBOW-02). The four abilities no item uses lose their 1.32 bonus (no play effect).

**Implementation (legacy):** the 32 abilities of `gameplay/items/def_item_trophies.xml` and their NG+ copies; the `gryphon_trophy_stats` ability is shared with Blood and Wine's Griffin trophy (`mq7009`, TRPH-02's item). NG+'s `mq1051_wyvern_trophy` loses its `Quest` tag (1.32's regular entry has none, its NG+ entry has it).

**5.x:** 1.32's.

**Port:** `tools/gen_trph.py` writes the 32 changed abilities of the base game's file whole (`replace`) into `items/gm_trph.xml` and `items_plus/gm_trph.xml` (NG+ equal), and the data test `tests/gmTestsTrphData.ws`; `item_layer.py`'s TRPH lines make `gen_item.py` write NG+'s `mq1051_wyvern_trophy` whole without `Quest`. `--verify` compares every trophy ability and item tag with legacy's. The Arachas trophy's tooltip passes as gear to the `AddItemStats` wrapper, so it reads "Maximum Toxicity +40" as legacy's, with and without Expert Brewer (ALCH's wrapper would otherwise show the potion form "Toxicity 40", reduced by Expert Brewer).

**Bonus gold and 5.x's loot merge:** a container gets its bonus gold (`CheckForBonusMoney`) once, when Geralt first comes within its interaction range; 5.x's loot merge (the gameplay setting `LootMergeEnabled`: one loot window, or one Auto-loot, takes every remains within 15 m) also takes corpses he never walked up to. `trph/bonusGold.ws` runs the check, once per container, on every remains the merge takes, before its loot is listed (a wrapper of the loot window's `CR4LootPopup.BuildCache`) or taken (a wrapper of `W3Container.ProcessLoot`, Auto-loot with the merge). So every looted corpse's crowns get the gold trophies' bonus and gear's, as in legacy's play.

From the code: the Wyvern trophy's stamina regen multiplies `staminaRegen`, which STAM-04's regen reads in combat (out of combat it reads `staminaOutOfCombatRegen`), as in 1.32 and legacy.

**Decisions:** legacy's abilities (PT2). Three values differ between legacy's code and its changelist, and legacy's design sheet (`trophies.ods`) agrees with the changelist on all three: DT1 (Grave hag trophy), DT2 (Ekimmara trophy), DT3 (Wild Hunt hound trophy).
- **Deviation:** with 5.x's loot merge on, every corpse the merge lists or takes gets its bonus gold check first, so the gold trophies (Doppler +25%, the King of Swineherd's crown +35%, the Conserved shaelmaar trophy +50%) and gear's bonus gold count on every merged corpse's crowns, not only on the one Geralt walked up to; legacy had no merge and every looted corpse had been approached, so this gives legacy's result on a 5.x path (TRPH audit F3, owner, 2026-11-02).

**Slices:**

1. **Base-game trophies.** Verified 2026-11-02, both trees (scripted calls, `gmtest_trph`, `gmtest_trph_spawn`/`_fight`): every ability reads legacy's values; each trophy put on Roach through the horse manager gives Geralt its bonus through the game's own reader and loses it when taken off; the Grave hag trophy raises a hit's adrenaline from 0.10 to 0.11 (with Razor Focus and Prolonged Effects in each tree); no trophy gives experience; the tooltips list the bonus.
2. **Bonus gold on merged loot.** Verified 2026-11-02, both trees (scripted, `GMTestTrphMerge`, `gmtest_trph_merge_*`): three remains with 100 crowns at 2, 6 and 12 m and the Doppler trophy on Roach give 375 in one merged loot, through Auto-loot and through the loot window.
3. **Arachas tooltip.** Verified 2026-11-02, both trees (scripted, `gmtest_trph_toxtip`, `GMTestTrphToxTip`): "Maximum Toxicity +40" with and without Expert Brewer.

**Later:** the Noonwraith trophy's (`mh308`) combat regen row is named "Vitality regeneration per enemy killed during combat", the game's own name (1070910) for `vitalityCombatRegen`, as in 1.32 and legacy, although the bonus is 5 per second; a clearer name is a possible improvement.

### TRPH-02 Blood and Wine trophy bonuses

| | |
|---|---|
| Kind | tuning |
| Pillars | P6, P10, P8 |
| 5.x class | clean |
| Flags | balance |
| Depends on | as TRPH-01; WGT (the Wight trophy's +20 maximum weight meets legacy's weights); LOOT and CRAFT (herbs) |
| Skill trees | n/a (as TRPH-01) |
| Port form | `gen_trph.py`: the eight changed abilities of `dlc/bob/.../def_item_trophies.xml` whole with `replace` (they drop 1.32's nodes, so `extend` cannot express them), NG+ copies; the Camerlengo's Seal without `Quest`, an `item_layer.py` TRPH field: a short `extend` entry with `<tags>-Quest</tags>` for the regular Blood and Wine entry, the NG+ entry whole (PT4); the Wight trophy counted once in the carry limit: `trph/carryLimit.ws` (a `@wrapMethod(W3HorseManager)` `GetHorseAttributeValue`) |
| Port status | signed off (2026-11-02) |
| Open checks | — |
| Save impact | none (expected); the Seal's tag is read from its definition |
| NG+ counterpart | legacy's NG+ abilities and Seal (equal to the regular ones), untested |

**What it does** (changelist 903–910): Blood and Wine's trophies get late-game bonuses (Golyat trophy +15% bludgeoning resistance, Camerlengo's Seal +15% piercing resistance, Slyzard trophy +20% Igni intensity, Wight trophy +20 maximum weight, Grottore trophy +100% herbs, Silver basilisk trophy +10% stamina regen, Garkain trophy +20% Axii intensity, Shaelmaar trophy +60 armor piercing). Two trophies the changelist does not list share an ability with one it does: the Umbra trophy gives Grottore's +100% herbs, Blood and Wine's Griffin trophy (`mq7009`) the prologue griffin's +5% attack power (PT6). The Camerlengo's Seal, a reward, is no longer a quest item, so it can be sold (250 crowns, its 1.32 price) and dropped. The Wight trophy keeps 1.32's Spoon Collector rule (a 10% chance of a bonus item per container) on top of its new bonus.

**Implementation (legacy):** eight abilities of `dlc/bob/data/gameplay/items/def_item_trophies.xml` and NG+ copies; the `camm_trophy` item's tags `Quest, Trophy` → `Trophy`.

**5.x:** 1.32's.

**Port:** `gen_trph.py` writes the eight abilities whole into `gm_trph.xml` (both folders) and the Seal's regular entry as a short `extend` entry with `<tags>-Quest</tags>` (PT4); `gen_item.py` writes NG+'s Seal whole without `Quest`.

**The Wight trophy counts once in the carry limit.** 1.32's, legacy's and 5.x's code counted it twice: the horse manager gives the trophy's abilities to Geralt and also keeps them among the horse's (`EquipItem` fills `horseAbilities` with every ability of the item), and `GetMaxRunEncumbrance` adds the horse's `encumbrance` to Geralt's, so the ability's +20 (the tooltip and the changelist's "+20") raised the carry limit by 40. `trph/carryLimit.ws`: a `@wrapMethod(W3HorseManager)` `GetHorseAttributeValue` leaves out of the horse's `encumbrance` what the trophy in the slot gives Geralt (its abilities but `base_trophy_stats`), so it counts once, on Geralt; saddlebags work through the horse and are unchanged. WGT's overburdened checks read the carry limit from the game.

**Decisions:** legacy's (PT2, PT4, PT6).
- **Deviation:** the Wight trophy gives the +20 carry weight its tooltip and the changelist show, not the +40 legacy's code gave (1.32's code, which legacy kept, counted the trophy's ability on Geralt and again on the horse); the trophy's bonus counts once and saddlebags are unchanged (TRPH audit, owner, 2026-11-02).

**Slices:**

1. **Blood and Wine trophies.** Verified 2026-11-02, both trees (scripted, `gmtest_trph` and the regression): each trophy on Roach gives its bonus and drops 1.32's, Blood and Wine's Griffin trophy the prologue griffin's (PT6); a herb plant with 2 herbs gives 3 with the Grottore or Umbra trophy; the Seal reads `Trophy` only, price 250, sellable and droppable.
2. **Wight trophy carry limit.** Verified 2026-11-02, both trees (scripted, `GMTestTrphWightLimit`): the limit rises by 20 with the trophy, the saddlebags' steps are unchanged, and bag and trophy add up.

### TRPH-03 Hearts of Stone trophy bonuses

| | |
|---|---|
| Kind | tuning |
| Pillars | P6 |
| 5.x class | clean |
| Flags | balance |
| Depends on | ECON (money), LOOT-06 (crowns in loot), WGT (the two items' weight) |
| Skill trees | n/a |
| Port form | `gen_trph.py`: the two abilities whole with `replace` (Hearts of Stone: `extend` empties them, [development.md](../development.md#fine-grained-xml-overrides-50)), **with legacy's weight nodes** (the crown 0 → 5, the Conserved shaelmaar trophy 2 → 5: WGT-05's nodes, written here; WGT skips the two names), NG+ copies (PT2, PT3, PT5) |
| Port status | signed off (2026-11-02) |
| Open checks | — |
| Save impact | none (expected) |
| NG+ counterpart | legacy's NG+ abilities (equal), untested |

**What it does** (code only; the changelist does not list Hearts of Stone's trophies): the King of Swineherd's crown (the pig race's prize) gives +35% bonus gold (1.32: +15%), the Conserved shaelmaar trophy +50% (1.32: +5%), the two largest gold bonuses of any trophy.

**Implementation (legacy):** `pig_contest_trophy_stats` and `q603_sharley_trophy_stats` in `dlc/ep1/data/gameplay/items/def_item_trophies.xml` and NG+; their weight nodes (0 → 5, 2 → 5) and the crown item's `EncumbranceOff` are WGT's.

**5.x:** 1.32's.

**Port:** `gen_trph.py`, the two abilities whole with `replace`, legacy's weight nodes included (5; WGT's generators skip the two names, so the abilities are defined once; `gen_all.py --verify` checks it after merging areas whose generators skip each other's names).

**Decisions:** legacy's code (PT5; an omission of the changelist, recorded in [open-questions.md](../open-questions.md#legacy-data-vs-changelist)). The crown's weight, legacy's random 5 to 10 per copy (its `max="5"` without a `min`, on top of `base_trophy_stats`' 5; [WGT](wgt.md#wgt-05-other-item-weights)), is kept: **decided** by the owner (2026-11-02). With 5.x's loot merge the two trophies' bonus gold counts on every merged corpse (TRPH-01's deviation).

**Slices:**

1. **Hearts of Stone trophies.** Verified 2026-11-02, both trees (scripted, the regression): the abilities read their values after `replace`, and 100 crowns in a spawned container become 135 with the crown and 150 with the Conserved shaelmaar trophy.

### TRPH-04 Trophies no longer auto-equipped

| | |
|---|---|
| Kind | system |
| Pillars | P8 (vanilla's trophy slot; the player chooses what Roach carries) |
| 5.x class | clean |
| Flags | — |
| Depends on | LOOT (the corpse containers) |
| Skill trees | n/a |
| Port form | `trph/looting.ws`: `@replaceMethod(W3ActorRemains)` `OnItemTaken` and `FinalizeLooting`, 5.x's bodies without the trophy queue and the equip block (marked); `@replaceMethod ProcessMonsterHuntTrophyQuest` with an empty body (PT7) |
| Port status | signed off (2026-11-02), the contract path by compile and code only |
| Open checks | A contract's trophy through its scene: nothing equipped, Roach not moved, the quest goes on (`ProcessMonsterHuntTrophyQuest` cannot be run by script; needs a save at a contract's end) |
| Save impact | none (expected) |
| NG+ counterpart | none (scripts) |

**What it does** (changelist 911): a trophy Geralt takes from a monster's remains goes into his inventory and stays there; in 1.32 and 5.x it is equipped on Roach at once when the loot window closes, replacing the trophy she carries. A contract's trophy, which quests hand over through `ProcessMonsterHuntTrophyQuest` after the trophy scene, is also left in the inventory, and Roach is no longer teleported next to Geralt (1.32 and 5.x bring her there to show the trophy on the saddle). The player equips a trophy himself, in the inventory's horse slots. With 5.x's "Auto-loot" option on, a trophy taken from a corpse also stays in the inventory.

**Implementation (legacy):** `W3ActorRemains.OnItemTaken` (the trophy's name is not queued), `FinalizeLooting` (the equip loop commented out), `ProcessMonsterHuntTrophyQuest` (the whole body, its `Sleep(0.5)` included, commented out).

**5.x:** 1.32's three functions, unchanged.

**Port:** `trph/looting.ws`: `@replaceMethod(W3ActorRemains)` of `OnItemTaken` (the trophy no longer queued) and `FinalizeLooting` (the queued trophies' equip loop and its locals removed), and `@replaceMethod ProcessMonsterHuntTrophyQuest` with an empty body (declared as a plain `function`: it compiles, and the compiler still treats it as a quest function, so a call from a script fails with the quest-block error). Every 5.x looting path (the loot window, Auto-loot, the loot merge's `TakeAllItems` on each remains) goes through `OnItemTaken` and `FinalizeLooting`; the only other code that equips horse items is a quest's re-equip of items it marked (`ReequipMarkedItems`) and the standalone starts' horse gear.

**Decisions:** legacy's (PT7). The Roach teleport's removal is not in the changelist (an omission, recorded in open-questions.md).

**Slices:**

1. **No auto-equipping.** Verified 2026-11-02, both trees (scripted, `gmtest_trph_loot`): a monster's remains holding a trophy, looted as the loot window does and through 5.x's Auto-loot: the trophy lands in Geralt's inventory and Roach's trophy slot stays empty. The contract path is checked by compile and code only (its body is empty).

---

### Dependencies on other areas

- **Done areas TRPH builds on:** DMG (the damage formula reading attack power, crit, armor piercing, resistance reduction, resistances), STAM-04 (stamina regen), SKL-07 and SKL-18 (adrenaline gain from hits, Razor Focus, Adrenaline Burst in both trees), SKL-11 and the Sign skills (Sign intensity), SKL-13 and ALCH (potion duration, maximum toxicity, the bomb bonus removed), EFX (effect resistances), XP-04 (no gear experience bonus left once TRPH removes the trophies'), ECON (bonus gold, the trophies' prices, PE11), LOOT-06 (crowns in containers), UI-05 to UI-07 (the panel's bonus gold line, the trophy tooltip, the rows and names), FIX-03 (`FixQuestItems`), `item_layer.py` and `gen_item.py` (the two item tags).
- **Shared with WGT:** `base_trophy_stats`' weight and the crown's `EncumbranceOff` are WGT's; the weight nodes inside the two Hearts of Stone abilities are written by `gen_trph.py` (PT3), so WGT's generators skip the two names. The Wight trophy's +20 maximum weight meets legacy's weights.
- **Shared with OPT:** the Noonwraith trophy's +5 Vitality regen in and out of combat is scaled by legacy's Vitality regen options (`W3Effect_AutoVitalityRegen`).

### Save impact

None expected: the trophies' abilities are given to Geralt by name and read from the definitions; tags are read from the item definitions; the looting changes act at the next loot. A trophy already on Roach keeps its slot and gives its legacy bonus. The mod is installed at the start of a playthrough ([save compatibility](../feature-mapping.md#save-compatibility)).

### Area decisions

**Decided by the owner (2026-11-02), as recommended:** the code's values. Each is a contradiction between legacy's code and its changelist (the rule: the code is the better guide, and every contradiction goes to the owner, [feature-mapping.md](../feature-mapping.md#legacy-behaviour-first)); legacy's design sheet `trophies.ods` agrees with the changelist on all three, the code's tooltip shows the code's value in play.

| # | Question | Decision |
|---|---|---|
| DT1 | The Grave hag trophy's adrenaline gain (TRPH-01). Code `focus_gain` +0.1: +10% adrenaline from each hit (0.11 per hit instead of 0.1); changelist and design sheet "+5%". For scale: Adrenaline Burst gives +5%, Razor Focus +25% at its top level | The code's +10%: legacy as played (the tooltip showed +10%); a level 10 trophy, small either way. Not a deviation |
| DT2 | The Ekimmara trophy's crit chance (TRPH-01). Code +10%; changelist and design sheet "+15%". The Chort trophy (level 20) gives +25% crit damage, the Ekimmara trophy (level 22) crit chance | The code's +10%: legacy as played; crit chance is the scarcer stat in Ghost Mode's damage model. Not a deviation |
| DT3 | The Wild Hunt hound trophy's frost resistance (TRPH-01). Code +50%; the changelist's trophy list and the design sheet "+25%", but its Wild Hunt section says "monster hunt trophy (+50% resistance to frost)" against the Hunt's frost damage (AI-15) | The code's +50%: the code and the changelist's own Wild Hunt line agree. It also halves the frost slowdown on Geralt (EFX-05). Not a deviation |

### Porter's calls

Each follows legacy or has no play effect; confirmed by the owner (2026-11-02).

| # | Call |
|---|---|
| PT1 | TRPH is ported as one area (90 units) with one audit at the end |
| PT2 | The trophy abilities go whole from legacy with `on_conflict="replace"` (they drop 1.32's nodes, so `extend` cannot express them; Hearts of Stone's need `replace` anyway), written by `tools/gen_trph.py` into `gm_trph.xml` in the DLC's `items/` and `items_plus/` (abilities defined with items load from the `items` folders, as `gm_ench.xml` and `gm_xbow.xml`), with `--check` and `--verify`; NG+ from legacy's `items_plus` files (equal to the regular ones); the four unused abilities emptied as legacy (no item names them) |
| PT3 | The weight inside the two Hearts of Stone abilities is written by `gen_trph.py` as legacy's (the abilities are given whole; WGT's generators skip the names), and `base_trophy_stats` and the crown's `EncumbranceOff` stay WGT's; not a deviation |
| PT4 | The two item tags as legacy: the Camerlengo's Seal and NG+'s Wyvern trophy (`mq1051`) lose `Quest` (the Seal can be sold for 250 and dropped); through `item_layer.py` as a TRPH field, written as a short `extend` entry with `<tags>-Quest</tags>` for the Seal's regular entry (a Blood and Wine item, tags only: the allowed form) and whole for the NG+ entries |
| PT5 | Hearts of Stone's two gold trophies take legacy's code values, +35% and +50% bonus gold, although the changelist does not list them (an omission, the code is the guide) |
| PT6 | The Umbra trophy (+100% herbs) and Blood and Wine's Griffin trophy (+5% attack power) take the bonus of the ability they share with Grottore's and the prologue griffin's trophies, as legacy's code does, although the changelist does not list them |
| PT7 | TRPH-04 as legacy: `@replaceMethod`s of `W3ActorRemains.OnItemTaken` and `FinalizeLooting` (5.x's bodies, the trophy lines removed and marked), and of `ProcessMonsterHuntTrophyQuest` with an empty body, which also drops 5.x's teleport of Roach next to Geralt (in legacy's code; not in the changelist); the replacement of a latent quest function is declared without `latent` ([development.md](../development.md)) |
| PT8 | The game's own trophy texts stay 5.x's, including 5.x's new common description "Strap trophies to your saddle to receive a bonus." (1.32's "Trophies can be turned in for a reward."): legacy changed no trophy string, and 5.x's text describes legacy's trophies better; not a deviation (a vanilla text, as ECON kept 5.x's haggling tutorial) |
| PT9 | No code for the bonuses themselves: 5.x's horse manager gives a trophy's abilities to Geralt as 1.32's did, and every bonus attribute is read by code the port already has (DMG, STAM-04, SKL-07, SKL-13, ALCH, EFX, ECON's containers, the herb plants) |
