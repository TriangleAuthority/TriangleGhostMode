# ITEM: item level, random bonuses, durability and repair

The rules every weapon and armor piece shares: what level an item has and needs, the level a level-scaled item gets when Geralt finds, buys or is given it, its quality (rarity), the random bonuses a found or bought item rolls, durability and its penalty, repair kits, and the Armorer's Table and grindstone buffs. Ghost Mode reworked all of them around one idea, "no dancing around levels": **an item's level is read straight from its damage or armor** (the rule SWD-01 and ARM-01 built the numbers on), level-scaled items get Geralt's own level with a small spread, Blood and Wine's and Hearts of Stone's gear scales with Geralt instead of sitting in fixed level bands, and random bonuses depend on quality and level: higher quality gives more kinds of bonus, every 10 levels repeats each one (changelist 630–631, "Random weapons get additional bonuses depending on their quality and level"). Durability matters more (a penalty of up to 20 to 50% by difficulty), repair kits restore less, new master kits raise an item's level by one (changelist 12–14, 611, 633), and the Armorer's Table and grindstone give resistances and armor penetration for 30 minutes (changelist 857–858). Sources: the changelist's Armor and Swords sections (lines 546, 611, 618–633), Effects (857–858), the known bugs (12–14), and the code (most of ITEM is not in the changelist: the level code, the level tags, the quality changes and durability are omissions).

**What 5.x did in this area.** Almost nothing to 1.32's rules: `GenerateItemLevel`, `AddRandomEnhancementToItem`, the random bonus lists and values (`def_item_quality.xml`), durability and repair are 1.32's. 5.x's changes: quest reward items are generated 1 to 3 levels above Geralt (1.32: 0 to 1); bolts got a level rule of their own (a bolt Geralt holds is lowered by its quality, a bolt read by name, as on a schematic, is never below Geralt's level; [ITEM-01](#item-01-item-level-from-stats)); the Armorer's Table and grindstone buffs last 60 minutes (1.32: 15); an Accessibility option, "Disable item durability" (`DisableDurabilityItem`, read by the engine, not by any script; unverified what it covers); the blacksmith's repair panel was rebuilt (prices are ECON's). 5.x's new gear (the Netflix, Dol Blathanna, Vixen, Top Notch, White Tiger and Scarlet Crest items) goes through the same item code.

**How legacy Ghost Mode implements it.** Scripts: `W3GameParams.GetItemLevel` (the formula), `CInventoryComponent.GetItemLevel` and `CDefinitionsManagerAccessor.GetItemLevelFromName` (the adjustments), `CInventoryComponent.GenerateItemLevel` (now returns the level), `OnItemAdded`, `AddItemLevelAbility` (new), `AddRandomEnhancementToItem` (now takes the level), `AddQualityAbilityToItem` (new), the bonus lists in `W3GameParams.Init*Abilities` with new common lists, `GetDurabilityMultiplier` and the durability constants, `W3PlayerWitcher.RepairItem`, `IsItemRepairAble`, `AddRepairObjectBuff`, `CR4InventoryMenu.ApplyRepairKit` and `UnequipItem`, `GetEnhancedBuffInfo` (new, the buff's line in tooltips), merchants' `ClearLowLevelWeapons` (new). Data: the level tags (`Autogen`, `AutogenUseLevelRange`, `AutogenForceLevel`) and level ranges (`item_level_min/max`) of about 130 items and abilities, the fixed damage or armor removed from items moved to level scaling, `DoNotEnhance` removed from 52 items, armor quality, `def_item_quality.xml` (the random bonus values), the repair kits (`def_item_alchemy_repair_kits.xml`), `EnhancedArmorEffect` and `EnhancedWeaponEffect` (`effects.xml`), all with their NG+ copies.

Unit lists: [attribution.csv](attribution.csv): 901 units carry an ITEM feature (33 script units, 409 XML units and their 413 NG+ copies, 46 CSV rows: 1 tooltip row and 5 strings × 9 languages); 563 of them are shared with other features (an item entry whose stats are ARM's or SWD's and whose level tags, level range, quality or `DoNotEnhance` are ITEM's). Units whose only change is the price, the weight, the dismantling parts or an NPC or secondary weapon's stats belong to ECON, WGT, CRAFT and AI ([scope](#scope)). The 80 crafted armor units whose only change besides price and parts is legacy's `DoNotEnhance` are ARM-01's (`gen_arm_items.py` carries them).

Port status: **signed off** by the owner (2026-10-20), ITEM-01 to ITEM-12, verified in both trees (mostly by script; ITEM touches no skill). Open checks are listed per entry.

## Scope

**ITEM covers** item level (how it is read from the stats, how a level-scaled item gets one, the level tags and ranges in the item data, the items legacy moved to level scaling), item quality of armor, random item bonuses (the rules and the values), `DoNotEnhance` where legacy removed it, durability and its penalty, repair kits including the master kits that raise an item's level, and the Armorer's Table and grindstone buffs with their tooltip line.

**Not ITEM** (confirmed by the owner with DI6):

| Subject | Area | Why |
|---|---|---|
| A weapon's or armor piece's own stats, slots, class and set tags, `DoNotEnhance` where legacy added it, the swords' quality | SWD, ARM (signed off) | Ported with their items; ITEM adds its fields to the same entries (one entry per item) |
| Prices, `mod_*` price tags, `mod_repair` (repair prices), merchants' funds (`daysToIncreaseFunds`, the reset below 100 in `W3MerchantNPC.OnSpawned`, restock funds in `OnInteraction`) | ECON | as ARM and SWD |
| Dismantle kits (`gear_dismantle_kit_1`, `alchemy_dismantle_kit_1`, their abilities and strings 2110992330–2110992333), repair kit schematics, where the master kits are sold (`AddMasterArmorerItems` and its call in `scene_functions.ws`; the shops' loot in `def_loot_shops.xml`, both folders: `_store__Hattori_Master_Blacksmith`, `_store__Master_Armorsmith_Yoana`, Hearts of Stone's `_store__LW_DLC_EnchanterMaster`, Blood and Wine's `_EP2_store_archmaster`) | CRAFT, LOOT | The kits' effect on an item is ITEM-11 |
| Weights of kits and items (`def_item_misc.xml` repair kit abilities included) | WGT | |
| The standalone starts' inventories (`StandaloneEp1_1`, `StandaloneEp2_1`: mutagens, money, bolts, food, ingredients) | LOOT | Starting stock, not item rules; the standalone starting gear itself is ITEM-05 |
| NPC, secondary and monster weapons' quality and damage (`def_item_weapons_secondary.xml`, `def_item_npcweapons.xml`), the Caretaker's shovel items | AI | as SWD |
| Bolts' and crossbows' stats and quality, the bolt level list's fix (`Blunt Bolt Legendary` 5 → 12) | XBOW | The crossbow and bolt branches of `GetItemLevel` sit in ITEM-01's function and are carried with it |
| The debug level reset (`fb1`, `fb2`, `fb3_internal`, `resetLevels`, `resetLevels_internal`, `cleanupInv`, `SetGeraltLevel`, `resetme`) | XP | Level reset; their level-scaled gear helper (`addAutogenEquipment`) is ITEM-02's and is not ported |
| The generic merchants fix by Wolfmark in `W3MerchantNPC.OnSpawned` (changelist 37) | FIX | |
| Pheromone potions' and Killer Whale's quality; the Balisse fruit fix (`BalisseFruitTempFix`), drinks' quality abilities | ALCH, FOOD | |
| The Places of Power's enhanced sign effects (changelist 859) | EFX | Not items |
| Recipe and schematic tooltip layout (`GetSchematicBookText`, `GetAlchemyBookText`) | UI | as ENCH |

## Changes at a glance

### What Ghost Mode changed

| # | Feature | Vanilla 1.32 | Legacy GM | Units (main) |
|---|---|---|---|---|
| ITEM-01 | Item level from stats | Level = `Floor(1 + (stat - base) / step) - 1` (swords `Ceil(...)`), then -2 for witcher gear (quality 5), -1 for relics (quality 4), -1 more for Hearts of Stone relic and witcher gear, -3 for Iris | Level = `Ceil((stat - base) / step)`, no quality, expansion or Iris adjustment, clamped to 1…max: a sword's or armor piece's level is the one its damage or armor was built for (crafted Short sword 33 → 1, grandmaster school swords 345/490 → 40); crossbows read up to level 38 | `W3GameParams.GetItemLevel`, `CInventoryComponent.GetItemLevel`, `GetItemLevelFromName` |
| ITEM-02 | Level of a level-scaled item | Found: by quality, witcher gear +0…+2, relics -2…+1, magic -3…-1, masterwork -5…-2, common -8…-2 below Geralt; bought: +0…+2 (and a level range forced); quest rewards +0…+1; standalone -1, NG+ +1/+2 | Found: Geralt's level -1…+1 (quality 3–4), -1…0 (quality 1–2), exactly (witcher gear); bought: -1…+2; rewards: exactly Geralt's level; no standalone or NG+ bumps; merchants drop weapons more than 3 levels below Geralt when they restock; the level is passed on to the random bonuses | `GenerateItemLevel`, `OnItemAdded`, `AddItemLevelAbility`, `ClearLowLevelWeapons`, `W3MerchantNPC.OnInteraction` |
| ITEM-03 | Level tags and ranges in item data | Blood and Wine's and Hearts of Stone's gear tagged `AutogenUseLevelRange` with ranges (`item_level_min/max`), some `AutogenForceLevel` | Ranges and range tags removed from 109 items (Blood and Wine's guard, knight, Toussaint, Hanza, squire, Thief, vampire and tournament gear, Burning Rose, Ofir, the Kontusz, the Blood and Wine silver swords, Remorse) so they scale with Geralt; `AutogenForceLevel` removed from 22 (Aerondight, Remorse, the unique and Gwent swords, Ofir Sabre 1, the Caretaker's spade, Thief and vampire gear) and added to the laundry stick and pole; some minimum levels moved (17); `EP1` removed from Blood and Wine gear | about 260 item and ability units (and NG+) |
| ITEM-04 | Items moved to level scaling | Fixed damage or armor | `Autogen` added, the fixed value removed: Iris (363 slashing), Ofir armor and Ofir Sabre 2, Blood and Wine's first vampire armor set and steel sword (`q702`), Yoana's reward armor, the free DLC's Nekker boots, Damien's sword; fixed damage dropped from the laundry stick, the Iron Poker, the free DLC quest's Feline sword (`mq1058`), the Burning Rose armor; NG+ keeps Iris instead of swapping it for `NGP Olgierd Sabre` | 26 units and NG+ copies, `NewGamePlusReplaceEP1` |
| ITEM-05 | Standalone starting gear | Hearts of Stone and Blood and Wine standalone starts: fixed armor 175/65/61/65 and 195/73/69/73, swords 265/395 and 297/435 | All twelve pieces level-scaled at Geralt's level (`Autogen`, `AutogenForceLevel`), the swords' XP bonuses gone (SWD-02) | 48 units (24 and NG+) |
| ITEM-06 | Random bonus rules | Quality 2: one masterwork bonus; quality 3: two (magical or masterwork), Hearts of Stone items one magical; quality 1 and 4 none | Quality 1 and up: one common bonus (chest armor: a resistance; swords: armor penetration, attack power, crit chance or damage, adrenaline); 2 and up: one masterwork; 3 and up: one magical; on chest armor and swords each repeated once per 10 levels (×1 to ×4); gloves, trousers and boots one masterwork and one magical; relic chest armor one common; witcher gear none; lists reshuffled (flat armor and stamina regen out, signs on trousers and boots) | `AddRandomEnhancementToItem`, `AddQualityAbilityToItem`, `Init*Abilities`, `GetRandomCommon*`, `RebalanceItems`, `W3MerchantNPC.OnSpawned` |
| ITEM-07 | Random bonus values | Resistances 1–4%, Vitality 10–50, attack power +5–8% or +10–40, crit chance 1–4%, crit damage 1–10%, armor penetration 10–40, effect chances 1–5%, sign intensity 1–5%, stamina regen | Resistances 3–5% (poison, bleeding, burning 5–10%), Vitality 200–400, attack power +3–5% (the flat one 0), crit chance 5–10%, crit damage 10–20%, armor penetration 10–20 and a new 3–5% resistance reduction, effect chances 3–5%, sign intensity 3–5%, adrenaline 3–5%, stamina regen 0 | `def_item_quality.xml` `MA_*` (30 and NG+) |
| ITEM-08 | `DoNotEnhance` removed | Blood and Wine's guard, knight, tournament and Thief `B` gear, Ofir armor, the Toussaint, Cianfanelli, elven, tournament and bonus silver swords never roll a random bonus | They roll ITEM-06's bonuses | 52 items and NG+ |
| ITEM-09 | Armor quality | Crafted armor quality 3; loot armor random quality 1–3; tournament armor 2; Kontusz 2; Kaer Morhen's starting piece 5 | Crafted armor by tier: 1, 2, then 3 (relic crafts 4); loot armor fixed or narrowed by tier (e.g. Light armor 04 3, Medium armor 01 1); tournament armor 4; Kontusz 1; the starting armor 1 | 57 abilities and NG+ |
| ITEM-10 | Durability | Penalty in steps: at most -5 to -20% at half durability by difficulty; armor loses 0.6, a weapon 0.26 (Death March 0.1) per hit; "damaged" below 50% | Penalty linear, `1 - (1 - durability)/4` on easy and normal (at most -20% and -25%: legacy's clamp of -30% on normal is never reached), `/2` on hard and Death March (-40%, -50%), on weapon damage and armor; armor loses 0.5, a weapon 0.05 per hit; "damaged" below 75%; two Beauclair pants start at full durability | `GetDurabilityMultiplier`, `W3GameParams.<members>` |
| ITEM-11 | Repair kits and master kits | Kits restore 15/40/90%; refused at full durability | Kits restore 10/20/30%, quality 1/2/3; master kits (weapon and armor, quality 4) restore 100% and add one level's damage or armor (+8 steel, +10 silver, +5 chest, +2 the rest), usable at full durability; an item whose level then exceeds Geralt's is unequipped | repair kit items and abilities, `RepairItem`, `IsItemRepairAble`, `ApplyRepairKit`, 4 strings × 9 |
| ITEM-12 | Armorer's Table and grindstone buffs | 15 min, armor +20% (table), attack power +20% (grindstone); only with gear equipped | 30 min, damage resistances +5% (table), armor penetration 10 and 5% resistance reduction (grindstone); no equipment condition; item tooltips show the buff and its time left | `EnhancedArmorEffect`, `EnhancedWeaponEffect`, `AddRepairObjectBuff`, `GetEnhancedBuffInfo`, tooltip row, string × 9 |

### What 5.x changed

| # | Feature | 5.x change (from code and data) |
|---|---|---|
| ITEM-01 | Level from stats | 1.32's formula and adjustments; new bolt rule (a held bolt's level lowered by 14/10/6/4 for quality 5/4/3/2; read by name, never below Geralt's level) |
| ITEM-02 | Level generation | Quest rewards +1…+3 above Geralt (1.32: +0…+1); otherwise 1.32's |
| ITEM-03 | Level tags and ranges | none (1.32's tags and ranges) |
| ITEM-04 | Moved to level scaling | none (1.32's fixed values); `NewGamePlusReplaceEP1` 1.32's |
| ITEM-05 | Standalone gear | none |
| ITEM-06 | Random bonus rules | none (1.32's code and lists) |
| ITEM-07 | Random bonus values | none |
| ITEM-08 | `DoNotEnhance` | none |
| ITEM-09 | Armor quality | none to 1.32's armor; 5.x's new armor and swords carry their own quality (the Netflix gear 5, Dol Blathanna, Vixen and Top Notch swords 4) |
| ITEM-10 | Durability | the same penalty and constants; an Accessibility option to disable item durability (engine side, unverified) |
| ITEM-11 | Repair | the same kits and rules; the blacksmith's repair panel rebuilt (ECON) |
| ITEM-12 | Armorer's Table and grindstone | 60 minutes (1.32: 15), the same +20% armor and attack power |

### Classification and action

| # | Feature | Class | Action |
|---|---|---|---|
| ITEM-01 | Level from stats | clean (5.x's bolt lines overlap) | Legacy's formula with legacy's bolt levels (DI1) |
| ITEM-02 | Level generation | overlap (rewards) | Legacy's (DI2) |
| ITEM-03 | Level tags and ranges | clean | Ported with the item generators |
| ITEM-04 | Moved to level scaling | clean | Ported with the generators |
| ITEM-05 | Standalone gear | clean | Ported |
| ITEM-06 | Random bonus rules | clean | Legacy's code |
| ITEM-07 | Random bonus values | clean | Given whole, DLC override |
| ITEM-08 | `DoNotEnhance` removed | clean | Ported with ITEM-06 |
| ITEM-09 | Armor quality | clean | Ported with the generators |
| ITEM-10 | Durability | clean, overlap (5.x's option) | Legacy's penalty and constants (DI4 for the option) |
| ITEM-11 | Repair and master kits | clean | Ported; the kits' shops are CRAFT's and LOOT's (DI6) |
| ITEM-12 | Armorer's Table and grindstone | overlap (duration) | Legacy's values (DI3) |

---

### ITEM-01 Item level from stats

| | |
|---|---|
| Kind | system |
| Pillars | P8, P10 |
| 5.x class | clean; overlap on bolts |
| Flags | DI1 decided (legacy's bolt levels) |
| Depends on | SWD-01, ARM-01 (damage and armor by level, signed off), XBOW (bolts, crossbows) |
| Skill trees | n/a |
| Port form | `@replaceMethod` of `W3GameParams.GetItemLevel`, `CInventoryComponent.GetItemLevel`, `CDefinitionsManagerAccessor.GetItemLevelFromName` (`gm/items/itemLevel.ws`: legacy's bodies; 5.x's bolt rule removed, DI1); the NG+ XML units through `item_layer.py` |
| Port status | **signed off** (2026-10-20), verified in both trees |
| Open checks | an item equipped by hand at its new level; the bolts in the crossbow quick menu and on the crafting screen on screen (read by script); the visible effect of NG+'s `Body palms cut`; NG+ (by policy, untested) |
| Save impact | none: the level is computed when read, so owned items show and need the new level at once |
| NG+ counterpart | none (scripts); two NG+ XML units (slice 3) |

**What it does:** "weapon level is determined by BASE damage value and armor level is determined by BASE armor reduction value" (legacy's comment). The level is `Ceil((stat - base) / step)`: chest armor 25 + 5 per level, boots and trousers 5 + 2, gloves 1 + 2, steel swords 25 + 8 (sum of all base damage types, each less 1), silver swords 90 + 10; clamped between 1 and the maximum level. Vanilla's `level - 1`, the -2 for witcher gear, -1 for relics, -1 for Hearts of Stone relic and witcher gear and -3 for Iris are gone, and so are NG+'s adjustments. Crossbows read their level from attack power with two more steps (34 and 38); bolts keep 1.32's list by name. The level decides whether Geralt can equip an item, and is shown in its tooltip and on schematics. Not in the changelist (an omission).

**Implementation (legacy):** `W3GameParams.GetItemLevel` (the formula, `Ceil`, clamp), `CInventoryComponent.GetItemLevel` and `CDefinitionsManagerAccessor.GetItemLevelFromName` (the adjustments commented out).

**5.x:** 1.32's formula and adjustments, with a bolt rule added (read from `vanilla-5.x`). `W3GameParams.GetItemLevel` still gives a bolt the level of 1.32's name list (less 1, at least 1). Then:
- a bolt Geralt or a merchant holds (`CInventoryComponent.GetItemLevel`: the level the inventory shows, the radial menu's bolt list and the equip check compare with Geralt's level) is lowered by its quality: 14 for quality 5, 10 for 4, 6 for 3, 4 for 2, and is at least 1. All bolts are quality 2 except Split and Explosive bolts (3) and their Legendary versions (4); the infinite bolts are quality 1;
- a bolt read by name (`CDefinitionsManagerAccessor.GetItemLevelFromName`: the level the crafting menu and schematic tooltips show as required) is raised to Geralt's level when it is lower: never below Geralt's level.

| Bolt (quality) | 1.32 | 5.x held | Legacy | Port (held and by name) |
|---|---|---|---|---|
| Tracking, Bait, Blunt (2) | 1 | 1 | 2 | 2 |
| Target Point (2) | 4 | 1 | 5 | 5 |
| Broadhead (2) | 9 | 5 | 10 | 10 |
| Split (3) | 14 | 8 | 15 | 15 |
| Explosive (3) | 19 | 13 | 20 | 20 |
| Blunt Legendary (2) | 4 | 1 | 12 | 12 |
| Target Point Legendary (2) | 14 | 10 | 15 | 15 |
| Broadhead Legendary (2) | 19 | 15 | 20 | 20 |
| Split Legendary (4) | 23 | 13 | 24 | 24 |
| Explosive Legendary (4) | 25 | 15 | 26 | 26 |

Legacy reads the name list without vanilla's -1 and drops the duplicate `Blunt Bolt Legendary` line that made it 5 instead of 12 (carried with the function; the bolts' stats stay XBOW's). As in 1.32, legacy and 5.x, the crossbow quick menu lists a bolt only up to Geralt's level (`hudModuleRadialMenu`) and the inventory refuses to equip one above it, so at level 1 none of these bolts is listed (all are level 2 or more).

**Decisions:** port as legacy; bolts: legacy's levels, 5.x's quality-based bolt rule removed, "an important balance point" (DI1 (b), the owner, 2026-10-20). `W3GameParams.GetItemLevel` still fills 5.x's `baseItemLevel` (legacy dropped the parameter); only the two replaced callers pass it and they ignore it (no effect).

**Slices:**

1. **The level formula.** Verified 2026-10-19, both trees (scripted, `GMTest_item01`, in the regression): levels by name and of new copies held equal legacy's formula, e.g. the crafted Short sword 1 (5.x 2), the grandmaster Griffin swords 40 (5.x 37). Not real: no item equipped by hand.
2. **Legacy's bolt levels (DI1).** Verified 2026-10-20, both trees (scripted, `GMTest_item01`, also at level 20): all twelve bolts read legacy's level held and by name, as in the table; the quick menu's filter read by script. Not real: the quick menu and the crafting screen were not opened.
3. **NG+ item units** (fix round 3, 2026-11-02, the owner's decision; offline checks). Hearts of Stone's NG+ `Body palms cut` (the bare-hands Body item the NG+ wedding suit's variants name, which 5.x's NG+ never defines) as legacy's new entry in `items_plus/gm_item.xml`, and the NG+ Censer's `UI_OilLamp` → `UI_Censer`, as the regular Censer (the whole NG+ entry, with WGT's weight and ECON's price, in `gm_item.xml`). `gen_item.py --verify` finds both as legacy's; `dlc_conflicts.py` clean.

**Later:** —

### ITEM-02 Level of a level-scaled item

| | |
|---|---|
| Kind | system |
| Pillars | P6, P10 |
| 5.x class | overlap (quest rewards) |
| Flags | balance, DI2 decided |
| Depends on | ITEM-01, ITEM-03 (the tags it reads), ITEM-06 (takes the level) |
| Skill trees | n/a |
| Port form | `gm/items/itemGeneration.ws`: `@replaceMethod CInventoryComponent.GenerateItemLevel` (legacy's rules, 5.x's signature: the level is read back with `GetItemLevel`); `@addMethod` `GMAddItemLevelAbility`, `GMClearLowLevelWeapons`; `@wrapMethod W3MerchantNPC.OnInteraction` (clears after a restock, seen as `lastDayOfInteraction` moving on); `OnItemAdded`'s change is the level passed to the random bonuses (ITEM-06); the debug command `addAutogenEquipment` dropped (tests add items directly) |
| Port status | **signed off** (2026-10-20), verified in both trees |
| Open checks | a merchant met in play (stock and restock tested on a spawned merchant); a real quest's reward (the reward rule is inert, see below) |
| Save impact | none for a new playthrough; items already owned keep the level they were generated with (stored on the item as per-level abilities, as 1.32) |
| NG+ counterpart | legacy's NG+ branch (range shifted by the NG+ level, the fixed per-level abilities) is in the same function |

**What it does:** a level-scaled item (`Autogen`) gets its level when it enters an inventory: found items Geralt's level -1 to +1 (quality 3 and 4), -1 to 0 (quality 1 and 2), exactly Geralt's (witcher gear); items with a range (`AutogenUseLevelRange`, ITEM-03) Geralt's level ±1 (exactly with `AutogenForceLevel`) clamped to the range; items in a merchant's stock Geralt's level -1 to +2, without vanilla's forced range tag; quest rewards exactly Geralt's level; no standalone (-1) or NG+ (+1/+2 for relics and witcher gear) adjustment; clamped between 1 and the maximum level. The level is added as per-level abilities (ARM-01's and SWD-01's `autogen_*`), returned, and passed to the random bonuses (ITEM-06); an item already generated returns 0 and the level is read with `GetItemLevel`. When a merchant restocks (`OnInteraction`), weapons more than 3 levels below Geralt are removed from the stock. `AddItemLevelAbility` adds one level's ability (the master kits, ITEM-11). Not in the changelist (an omission).

The reward rule never takes effect, in 1.32, legacy, 5.x and the port alike: the level is generated inside `AddAnItem` (`OnItemAdded`), so the reward code's later `GenerateItemLevel(id, true)` (`r4Game.ws`) finds the item already generated (each branch requires it to have no `autogen_*_base` ability yet) and adds nothing. A reward gets the found-item level.

Bolts carry `WeaponTab`, not `Weapon`, so `ClearLowLevelWeapons` (`GetAllWeapons`) never removes them, in legacy as in the port; crossbows and secondary weapons are removed.

**Implementation (legacy):** `GenerateItemLevel`, `OnItemAdded`, `AddItemLevelAbility`, `ClearLowLevelWeapons`, `W3MerchantNPC.OnInteraction`; the debug commands `addAutogenEquipment`, `addAutogenEquipment_internal`.

**5.x:** 1.32's rules, except quest rewards at Geralt's level +1 to +3 (1.32: +0 to +1).

**Decisions:** port as legacy; rewards: DI2 (legacy's rule, inert as in legacy, accepted). Merchant restock as legacy (owner, 2026-10-20). The port's restock clearing runs after `OnInteraction` (legacy's just before `IncreaseFunds`, which only adds money; no effect).

**Slices:**

1. **Level generation.** Verified 2026-10-19, both trees (scripted, `GMTest_item02`, also at level 20): new copies get legacy's level by quality, witcher gear exactly Geralt's, a range item clamped to its range.
2. **Merchants and rewards.** Verified 2026-10-20, both trees (scripted, `GMTest_item02_merchant`, `GMTest_item02_reward`, in the regression; `gmtest_item02_restock` calls `OnInteraction` "Talk" by script): a spawned weapon merchant's stock at Geralt's level -1 to +2, its restock removes weapons more than 3 levels below and keeps every bolt; a reward through `theGame.GiveReward` gets the found-item level. Not tested: a merchant met in play, a real quest's reward.

### ITEM-03 Level tags and ranges in item data

| | |
|---|---|
| Kind | content |
| Pillars | P6, P10 |
| 5.x class | clean |
| Flags | balance |
| Depends on | ITEM-02 (reads them), ARM-01, SWD-01 to SWD-04 (the same entries) |
| Skill trees | n/a |
| Port form | the item tools: `tools/item_layer.py` holds ITEM's fields by feature (tags, ability nodes) and merges them three-way; `gen_arm_items.py` and `gen_swd_items.py` apply it to the entries they write; `gen_item.py` writes the other ITEM entries (`gm_item.xml`; run it after the other item tools) and `--verify` checks every ITEM field against legacy's and that no name is defined twice |
| Port status | **signed off** (2026-10-20), verified in both trees |
| Open checks | NG+ (by policy, untested) |
| Save impact | none for a new playthrough; an item already owned keeps its generated level |
| NG+ counterpart | applied, untested (legacy's own `items_plus` changes; `gen_item.py --verify` checks them) |

**What it does:** Blood and Wine's and Hearts of Stone's gear no longer sits in level bands. Legacy removed `AutogenUseLevelRange` (and the matching `item_level_min/max`) from 109 items: the guard, knight, Toussaint, Hanza and squire gear, the Thief (Borsody) armor, the second vampire set (`q704`), the tournament (`sq701`) gear, the Burning Rose and Ofir gear, the Kontusz, the Blood and Wine bonus silver swords, Remorse; such an item now gets Geralt's level when found or bought (ITEM-02). `AutogenForceLevel` (an exact level) is removed from 22 items (Aerondight, Remorse, the unique and Gwent swords, Ofir Sabre 1, the Caretaker's spade, the Feline sword of the free DLC quest, the Thief and second vampire gear, Toussaint armor 3, the Cianfanelli and tournament swords) and added to the laundry stick and pole; 17 minimum levels change (e.g. the unique swords and the second vampire swords 40 → 45, Gwent sword 40 → 36); `EP1` is removed from 36 Blood and Wine pieces (under 1.32's code it lowered their level and limited their random bonus; under legacy's code it has no effect). Not in the changelist (an omission).

**Implementation (legacy):** the tags of about 130 items and the ranges of about 127 abilities (regular, and their NG+ copies) in the base game, Hearts of Stone, Blood and Wine and the free DLC item files.

**5.x:** 1.32's tags and ranges.

**Decisions:** port as legacy; Blood and Wine's gear at Geralt's level confirmed by the owner (2026-10-19). `DoNotEnhancem` (1.32's misspelt tag on the `sq701` gloves, which legacy removed) goes with ITEM-08. Remorse's `1handedWeapon` tag, also in legacy's change, is not ITEM's.

**Slices:**

1. **Tags and ranges** (with ITEM-02). Verified 2026-10-19, both trees: `gen_item.py`, `gen_arm_items.py` and `gen_swd_items.py --verify` 0 unexplained; in game (scripted, `GMTest_item02`, `GMTest_swd03`) sample items carry legacy's tags and ranges.

### ITEM-04 Items moved to level scaling

| | |
|---|---|
| Kind | content |
| Pillars | P8, P10 |
| 5.x class | clean |
| Flags | balance |
| Depends on | ITEM-02, ITEM-03, ARM-01, SWD-01, SWD-06 (Iris) |
| Skill trees | n/a |
| Port form | the item tools (`item_layer.py`: the `Autogen` tag and the fixed armor or damage nodes); `@replaceMethod W3PlayerWitcher.NewGamePlusReplaceEP1` and `NewGamePlusReplaceEP2Items` (`gm/items/itemScaling.ws`, the Iris and the vampire gear swaps removed) |
| Port status | **signed off** (2026-10-20), verified in both trees; the NG+ vampire gear swap added after the sign-off (compiles) |
| Open checks | NG+'s start keeping Iris and the vampire gear; a save holding an Iris obtained before (expected to need reacquiring) |
| Save impact | reacquire items (expected): an owned item that had fixed damage or armor and was never generated loses its fixed value and has no per-level abilities until it is obtained again (Iris in a save made before; unsupported mid-playthrough, matters for test saves) |
| NG+ counterpart | applied, untested |

**What it does:** items with a fixed damage or armor become level-scaled (`Autogen`, the fixed value removed): Iris (363 slashing; about 300 at level 35), Ofir armor (200) and Ofir Sabre 2 (308), Blood and Wine's first vampire set (`q702`: armor 230/87/84/87) and its steel sword (356, which also loses its fixed armor penetration, crit and confusion bonuses), Yoana's reward armor (166), the free DLC's Nekker boots (64), Damien's sword (an NPC's); the laundry stick, the Iron Poker, the Feline sword of the free DLC quest and the Burning Rose armor lose the fixed value they had next to their level scaling. In NG+ legacy keeps Iris and Blood and Wine's vampire armor, gloves, pants, boots and steel sword (level-scaled) instead of swapping them for their NG+ copies. Not in the changelist (an omission).

**Implementation (legacy):** the items' tags and their `_Stats` abilities (26 units and NG+), `NewGamePlusReplaceEP1`, `NewGamePlusReplaceEP2Items` (the five `q702` swaps commented out).

**5.x:** 1.32's fixed values.

**Decisions:** port as legacy.

- **Deviation:** at the start of New Game+, Ofir Armor and Ofir Sabre 2 are swapped for 5.x's `NGP Ofir Armor` and `NGP Ofir Sabre 2` (5.x's fixed NG+ stats, not this feature's level scaling). Legacy deleted both `NGP` definitions but kept the swap, and its `NewGamePlusReplaceItem` removes the item before adding the replacement, so in legacy both items most likely vanished at the start of NG+; a DLC cannot delete an entry, and the owner keeps 5.x's items (owner, 2026-11-03; whole-port audit C3-5).

**Slices:**

1. **Level scaling and the NG+ Iris swap** (with ITEM-05). Verified 2026-10-19, both trees (scripted, `GMTest_item04`, also at level 25): the tags and fixed values gone; new copies of Iris and Ofir armor at Geralt's level -1 to +1, their level from stats equal to the generated one; Iris equipped at level 25 (`gmtest_swd_equip`). The vampire gear's NG+ swap (2026-10-22): compiles; NG+ untested by policy.

### ITEM-05 Standalone starting gear

| | |
|---|---|
| Kind | content |
| Pillars | P8, P10 |
| 5.x class | clean |
| Flags | — |
| Depends on | ITEM-02, ITEM-04; SWD-02 (the swords' XP bonuses, ported) |
| Skill trees | n/a |
| Port form | the item tools (`item_layer.py`: the tags, the fixed armor and damage, Blood and Wine's armor quality) |
| Port status | **signed off** (2026-10-20), verified in both trees (data and a new copy; no standalone start played) |
| Open checks | a standalone start (Hearts of Stone or Blood and Wine) |
| Save impact | none (the gear is given at the start) |
| NG+ counterpart | applied, untested |

**What it does:** the Hearts of Stone and Blood and Wine standalone starts (a new game begun at an expansion) give Geralt level-scaled gear at his level (`Autogen`, `AutogenForceLevel`) instead of fixed armor (175/65/61/65, 195/73/69/73) and swords (265/395, 297/435); the gear keeps `DoNotEnhance`.

**Implementation (legacy):** `def_item_ep1_stand_alone.xml`, `def_item_ep2_stand_alone.xml` (items and abilities, 24 and NG+): 32 armor units and 16 sword units (the swords' other changes are SWD-02's).

**5.x:** unchanged.

**Decisions:** port as legacy. ARM-01 carries the standalone armor's resistances (legacy's), so ITEM-05 adds the level tags, removes the fixed armor and damage and sets Blood and Wine's standalone armor to quality 3.

**Slices:**

1. **Standalone gear** (with ITEM-04). Verified 2026-10-19, both trees (scripted, `GMTest_item04`): the tags and values; a new Blood and Wine standalone armor has exactly Geralt's level. Not tested: a standalone start.

### ITEM-06 Random bonus rules

| | |
|---|---|
| Kind | system |
| Pillars | P6, P8 |
| 5.x class | clean |
| Flags | balance |
| Depends on | ITEM-02 (the level), ITEM-07 (the values), ITEM-09 (armor quality), ITEM-08 |
| Skill trees | n/a |
| Port form | `gm/items/itemBonuses.ws`: `@replaceMethod` of `AddRandomEnhancementToItem` (legacy's body; the callers stay 5.x's, so legacy's level argument is found as legacy's callers passed it: inside `OnItemAdded`, marked by a `@wrapMethod` (`gmInItemAdded`), the level the replaced `GenerateItemLevel` just generated (`gmGeneratedLevel`, ITEM-02's file; legacy returned it), otherwise `GetItemLevel`, as legacy's container and merchant callers), of the five `W3GameParams.Init*Abilities` and of `GetItemQualityFromName`; `@addMethod` `GMAddQualityAbilityToItem`, `GMGetRandomCommonArmorAbility`, `GMGetRandomCommonWeaponAbility`; the two common lists as `@addField` (`gmArmorCommonAbilities`, `gmWeaponCommonAbilities`) |
| Port status | **signed off** (2026-10-20), verified in both trees |
| Open checks | a merchant's and a container's stock (the same function, called by 5.x's code); an axe looted or bought in play |
| Save impact | none for a new playthrough; an owned item keeps the bonuses it rolled (stored on the item, `ItemQualityModified`) |
| NG+ counterpart | none (scripts) |

**What it does:** changelist 630–631: "bigger quality means more bonuses, bigger level means bigger values". When an item first enters Geralt's, a merchant's or a container's inventory (unless it has `DoNotEnhance`): items of quality 1 to 4 get their quality ability; witcher gear (5) nothing more; relics (4) nothing, except chest armor one common resistance; chest armor one common resistance (quality 1+), one masterwork bonus (2+) and one magical (3+), the masterwork and magical ones repeated at levels 10, 20 and 30 (the same bonus up to 4 times); gloves, trousers and boots one masterwork (2+) and one magical (3+); swords one common (1+), one masterwork (2+), one magical (3+), each repeated at levels 10, 20, 30. The lists: common armor = the five physical and elemental resistances; masterwork armor and gear = burning, poison, bleeding resistance, adrenaline gain, Vitality (no flat armor); magical = the five sign intensities (now also on trousers and boots; attack power, crits and stamina regen gone); common weapon = armor penetration (flat or %), attack power, crit chance, crit damage, adrenaline; masterwork weapon = bleeding, freezing, poison, confusion, burning or stagger chance; magical weapon = sign intensities. So a level 30 magical sword can carry the same crit chance bonus four times (20 to 40%). The level counted is the one the item was given: when Geralt or a merchant receives a level-scaled item, the level it was just generated at; for an item generated before, one that is not level-scaled, or a container's stock, its level from its stats. They differ only for the level-scaled secondary weapons (axes, clubs, maces, the pickaxe and poker), whose fixed base damage reads 1 to 3 levels above the generated level: an axe given level 19 repeats its bonus twice, though it shows level 20 to 22. A legacy quirk kept as legacy: such a weapon found at Geralt's level shows a level above his and cannot be equipped at once.

**Implementation (legacy):** `AddRandomEnhancementToItem`, `AddQualityAbilityToItem`, `GetItemQualityFromName` (quality at least 1), `W3GameParams.Init*Abilities`, `GetRandomCommon*`, the two common lists in `W3GameParams.<members>`, `OnItemAdded`, `RebalanceItems`, `W3MerchantNPC.OnSpawned`.

**5.x:** 1.32's rules (quality 2 one masterwork bonus; 3 two, each magical or masterwork; Hearts of Stone items one magical; 1 and 4 none; lists with flat armor, attack power and stamina regen).

**Decisions:** port as legacy; the stacking ported as legacy (owner, 2026-10-19; [to test in legacy](../open-questions.md#to-test-in-legacy-ghost-mode), balance pass). 5.x's new gear follows the rules by its quality: the Netflix gear (5) gets none; the Dol Blathanna, Vixen and Top Notch swords (4) none; 5.x's new relic armor (Dol Blathanna, White Tiger, Scarlet Crest) one common resistance on the chest piece, as legacy's relic armor (DI5, owner, 2026-10-19). The bonuses count the level the item was given at generation, as legacy (the owner, 2026-10-20). `GetItemQualityFromName`'s minimum of 1 also reaches 5.x's transmog menu, which clamps to 1 itself (no effect).

**Slices:**

1. **Bonus rules** (with ITEM-07). Verified 2026-10-19, both trees (scripted, `GMTest_item06`, in the regression; also at level 31): new copies' bonuses counted by rule, quality and level (e.g. quality 3 chest armor three at level 1, nine at level 32; witcher gear none). Not tested: a merchant's or a container's stock.
2. **Legacy's bonus level.** Verified 2026-10-20, both trees (scripted, `GMTest_item06`, `gmtest_item06_axe` at levels 19 to 30): `W_Axe01` and `W_Mace01` roll one bonus per 10 levels of the level they were given, not of their level from damage; swords and armor unchanged. Not tested: an axe looted or bought in play.

### ITEM-07 Random bonus values

| | |
|---|---|
| Kind | tuning |
| Pillars | P6, P8 |
| 5.x class | clean |
| Flags | balance |
| Depends on | ITEM-06 |
| Skill trees | n/a |
| Port form | `gm_item.xml` in the DLC's `items/` and `items_plus/` (`gen_item.py`; `item_layer.py` gives ITEM-07 every node): legacy's `MA_*` abilities on 5.x's entries given whole (`on_conflict="replace"`), `MA_ArmorPenetrationPerc` new |
| Port status | **signed off** (2026-10-20), verified in both trees |
| Open checks | an owned item's rolled bonus on an old save (read by name, expected to take the new range) |
| Save impact | none (expected: the bonus abilities are read by name, so an owned item's rolled bonus takes the new range, as SWD-10's owned Top Notch sword showed for a range) |
| NG+ counterpart | applied, untested (legacy's `items_plus` copy) |

**What it does:** the values of the random bonuses: physical and elemental resistances 3–5% (1–4%), poison, bleeding and burning resistance 5–10% (1–4%), Vitality 200–400 (10–50), adrenaline gain 3–5% (1–4%), sign intensity 3–5% (1–5%), armor penetration 10–20 (10–40) and a new 3–5% resistance reduction, attack power +3–5% (+5–8%), crit chance 5–10% (1–4%), crit damage +10–20% (+1–10%), effect chances 3–5% (1–5%); the flat attack power (+10–40) and stamina regen bonuses emptied; `MA_Precision` and `MA_Gore` read the attributes the game uses (`instant_kill_chance`, `dismember_chance`, vanilla's `_mult` names do nothing).

**5.x:** unchanged from 1.32.

**Decisions:** port as legacy.

**Slices:**

1. **Bonus values** (with ITEM-06). Verified 2026-10-19, both trees: `gen_item.py --verify` 0 unexplained; in game (scripted, `GMTest_item06`) rolled values within legacy's ranges (e.g. crit chance from 0.05, flat attack power and stamina regen 0). Not checked on an old save.

### ITEM-08 `DoNotEnhance` removed

| | |
|---|---|
| Kind | content |
| Pillars | P6 |
| 5.x class | clean |
| Flags | balance |
| Depends on | ITEM-06, ITEM-07 (the bonuses they then roll), ARM-01, SWD-02 (the same entries) |
| Skill trees | n/a |
| Port form | the item tools (`item_layer.py`, ITEM-08: `DoNotEnhance` and 1.32's misspelt `DoNotEnhancem` merged as legacy) |
| Port status | **signed off** (2026-10-20), verified in both trees |
| Open checks | a Blood and Wine guard or knight piece bought or looted in play |
| Save impact | none for a new playthrough; an owned item does not roll later (the roll happens once, on receipt) |
| NG+ counterpart | applied, untested |

**What it does:** 52 items of the expansions roll random bonuses again: Blood and Wine's guard and knight gear (first tier), the `B` versions of the Thief and Burning Rose gear and the Thief gear without the medallion, Ofir armor and its `B` pieces, the tournament (`sq701`) armor and swords, the Toussaint, Cianfanelli and elven (`mq7007`) swords, the Blood and Wine bonus silver swords and their `R` copies. Not in the changelist (an omission; legacy's rework of the random bonuses).

**5.x:** 1.32's tags. Where legacy added the tag (crafted gear), ARM-01 and SWD-02 carry it.

**Decisions:** port as legacy, after ITEM-06. The `sq701` tournament gloves carried 1.32's misspelt `DoNotEnhancem`, which did nothing and legacy removed: removed with ITEM-08 (confirmed by the owner, 2026-10-20).

**Slices:**

1. **`DoNotEnhance` removed** (with ITEM-09). Verified 2026-10-19, both trees (scripted, `GMTest_item08`, in the regression): the tag gone from the sample pieces, crafted armor keeping legacy's; new Blood and Wine guard armor 1 rolls its bonuses. The three item tools' `--verify`: 0 unexplained.

### ITEM-09 Armor quality

| | |
|---|---|
| Kind | content |
| Pillars | P6, P8 |
| 5.x class | clean |
| Flags | balance |
| Depends on | ARM-01, ARM-12 (the same entries), ITEM-06 (quality decides the bonuses) |
| Skill trees | n/a |
| Port form | the item tools (`item_layer.py`, ITEM-09: `quality` in the armor abilities ARM writes) |
| Port status | **signed off** (2026-10-20), verified in both trees |
| Open checks | — |
| Save impact | none (expected: quality is read from the definitions; an owned item's random bonuses stay as rolled) |
| NG+ counterpart | applied, untested |

**What it does:** armor quality (its rarity colour, and with ITEM-06 how many random bonuses it rolls) follows the tier: crafted armor quality 1 for the first tier, 2 for the second, 3 from the third (relic crafts 4; vanilla 3 for all), loot armor's random ranges narrowed or fixed by tier (e.g. Light armor 04 1–2 → 3, Medium armor 01 1–3 → 1, Heavy armor 03 1–3 → 3), the tournament armor 2 → 4, the Kontusz 2 → 1, Kaer Morhen's starting armor 5 → 1. The swords' quality is SWD-02's. Not in the changelist (an omission).

**Implementation (legacy):** `quality` in 57 armor `_Stats` abilities and their NG+ copies.

**5.x:** unchanged from 1.32. Kaer Morhen's starting armor gets legacy's quality 1 from `gen_arm_km.py` (ARM-12).

**Decisions:** port as legacy.

**Slices:**

1. **Armor quality** (with ITEM-08). Verified 2026-10-19, both trees (scripted, `GMTest_item08`): sample crafted and loot armor and the Kontusz carry legacy's quality; `gen_item.py --verify` checks all 57 and their NG+ copies.

### ITEM-10 Durability

| | |
|---|---|
| Kind | tuning, system |
| Pillars | P1, P8 |
| 5.x class | clean; overlap with 5.x's option |
| Flags | balance, DI4 decided |
| Depends on | DMG (`GetTotalWeaponDamage` and the armor term read the penalty, signed off) |
| Skill trees | n/a |
| Port form | `@replaceMethod W3GameParams.GetDurabilityMultiplier` (`gm/items/durability.ws`); the constants as `default` lines in W3GameParams' scope-based override block (`gm/stamina/staminaCosts.ws`: one block per class in the mod); the two Beauclair trousers' `initial_durability` through `item_layer.py` (`ATTRS`, opening-tag attributes) |
| Port status | **signed off** (2026-10-20), verified in both trees |
| Open checks | wear in a real fight; the other difficulties (the test reads the current one); what 5.x's "Disable item durability" option covers |
| Save impact | none |
| NG+ counterpart | none (scripts); the two pants' NG+ copies |

**What it does:** "durability penalties were redone" (the mod description; not in the changelist). The penalty on weapon damage and armor is linear in lost durability: `1 - (1 - durability)/4` on easy and normal (at most -20% on easy and -25% on normal: the formula never goes below 0.75, so legacy's clamp of 0.7 on normal never acts; legacy's code is the same, so play matches legacy; whole-port audit A4-1), `1 - (1 - durability)/2` on hard and Death March (at most -40% and -50%); vanilla's steps give at most -5 to -20% at half durability. Gear wears slower (armor 0.5 instead of 0.6 per hit; weapons 0.05 instead of 0.26, Death March 0.1), and counts as damaged below 75% (50%). Torlara and Torzirael lose their indestructibility (`MA_Indestructible`), ported with SWD-03 (confirmed by the owner, 2026-10-19).

**Implementation (legacy):** `GetDurabilityMultiplier`, the constants in `W3GameParams.<members>`.

**5.x:** 1.32's penalty and constants; the port's `GetTotalWeaponDamage` (DMG-08) calls the penalty. 5.x adds an Accessibility option "Disable item durability" (`DisableDurabilityItem`, off by default; part of the accessibility preset); no script reads it, so the engine applies it (what it covers is unverified).

**Decisions:** port as legacy; 5.x's option stays available (DI4, owner, 2026-10-19).

**Slices:**

1. **Durability.** Verified 2026-10-19, both trees (scripted, `GMTest_item10`, in the regression): legacy's penalty on Hard (0.75 at half durability), threshold and wear constants; DMG-08's weapon damage reads the penalty; the two Beauclair trousers start at full durability. Not tested: wear in a real fight, the other difficulties, what 5.x's option covers.

### ITEM-11 Repair kits and master kits

| | |
|---|---|
| Kind | content, system |
| Pillars | P6, P8 |
| 5.x class | clean |
| Flags | balance |
| Depends on | ITEM-01, ITEM-02 (`AddItemLevelAbility`), ITEM-10; CRAFT, LOOT (where the kits are sold) |
| Skill trees | n/a |
| Port form | `gm_item.xml` through `item_layer.py` (ITEM-11: every node of the kit abilities but the weight, the kits' `base_abilities`, the master kits' items and abilities new as legacy's); `@replaceMethod` of `RepairItem`, `IsItemRepairAble`, `CR4InventoryMenu.ApplyRepairKit` and `CR4InventoryMenu.UnequipItem` with an `@addField` `gmForceUnequip` that skips its combat refusal (legacy's `forceUnequip` parameter; a replaced method keeps its signature) (`gm/items/repair.ws`); strings 2110992266 to 2110992269 (9 languages, legacy's rows) |
| Port status | **signed off** (2026-10-20), verified in both trees (scripted) |
| Open checks | a kit used in the inventory menu by hand (drag and drop, E; the menu's handler was run by script); the unequip under a quest's equipment lock |
| Save impact | none |
| NG+ counterpart | applied, untested |

**What it does:** the three repair kit tiers restore 10/20/30% (15/40/90%) and have quality 1/2/3. New master kits, "Master weaponsmith tools" and "Master armorsmith tools" (quality 4), restore 100% and permanently add one level's damage or armor to the item they are used on (+8 steel, +10 silver damage; +5 chest armor, +2 for the other pieces): "You can level up your armors (weapons) with mastercrafted kits" (changelist 611, 633), sold by Yoana after her quest, Hattori after his, the Hearts of Stone enchanter and the Blood and Wine grandmaster smiths ([LOOT-04](loot.md#loot-04-special-merchants), CRAFT-10). Any item with durability takes a kit, at full durability too (vanilla refuses); the changelist's known bug (12–14): drag and drop only works below 100%, use (E) always. If the new level is above Geralt's, the item is unequipped, in combat too.

**Implementation (legacy):** `def_item_alchemy_repair_kits.xml` (the six kits and two master kits, their abilities, regular and NG+), `RepairItem`, `IsItemRepairAble`, `ApplyRepairKit`, `CR4InventoryMenu.UnequipItem` (`forceUnequip`), `AddItemLevelAbility` (ITEM-02), 4 strings.

**5.x:** unchanged; `UnequipItem` refuses in combat and has no force parameter; the blacksmith's repair panel rebuilt (repair prices ECON).

**Decisions:** port as legacy; ITEM takes the kits and their effect, where they are sold stays CRAFT's and LOOT's (DI6, owner, 2026-10-19). `RepairItem` adds the master tools' level after repairing (legacy before; neither step reads the other).
- **Deviation:** 5.x's quest lock on equipment changes (`AreManualEquipmentChangesBlocked`, set by quests) also stops the master kits' forced unequip: while a quest blocks equipment changes, an item a master kit raises above Geralt's level stays equipped; legacy had no such lock (porter's call, the auditor's suggestion; confirmed by the owner, 2026-10-20).

**Slices:**

1. **Kits and master kits.** Verified 2026-10-19, both trees (scripted through `RepairItem`, `GMTest_item11`, in the regression): kit values and qualities; a full sword takes a kit; the master tools raise a sword's or armor's level by one. Not tested: a kit used in the inventory menu by hand.
2. **Forced unequip.** Verified 2026-10-20, both trees (scripted in the inventory menu through its handler `OnApplyRepairKit`, `gmtest_item11_unequip_prep`, `gmtest_item11_unequip`): an equipped sword raised above Geralt's level is unequipped out of and in combat. Not tested: drag and drop or E by hand, the quest lock.

### ITEM-12 Armorer's Table and grindstone buffs

| | |
|---|---|
| Kind | tuning, ui |
| Pillars | P6, P7 |
| 5.x class | overlap (duration) |
| Flags | DI3 decided |
| Depends on | DMG (resistances and armor penetration in the formula, signed off), ENCH-06 (Preservation keeps them, signed off) |
| Skill trees | n/a |
| Port form | `EnhancedArmorEffect`, `EnhancedWeaponEffect` given whole in `abilities/gm_item_effects.xml` (NG+ by `gen_ngplus.py`); `gm/items/repairObjects.ws`: `@replaceMethod W3PlayerWitcher.AddRepairObjectBuff`, `@addMethod CInventoryComponent.GMGetEnhancedBuffInfo` and `GMFindAttrInTooltipSettings` (legacy's helper, gone from 5.x), a `@wrapMethod` of `W3TooltipComponent.GetBaseItemData` that puts the lines first (Iris's description wrapper keeps them); `tooltip_settings.csv` row `resistance_perc_bonus_descr`; string 2110992483 (9 languages) |
| Port status | **signed off** (2026-10-20), verified in both trees (scripted) |
| Open checks | a real Armorer's Table and grindstone; the tooltip line on screen; the grindstone's armor penetration in a real hit; ENCH-06's Armorer's Table check (Preservation) |
| Save impact | none (a buff active on load keeps its old values until it runs out) |
| NG+ counterpart | applied, untested |

**What it does:** changelist 857–858: the Armorer's Table gives +5% to all damage resistances, the grindstone 10 armor penetration and 5% resistance reduction, each for 30 minutes (vanilla: +20% armor, +20% attack power, 15 minutes); they apply even with no gear equipped; an item's tooltip shows the active buff, its bonus and the time left. Preservation (ENCH-06) keeps them from expiring; `W3RepairObjectEnhancement`'s timer change is ENCH-06's.

**Implementation (legacy):** `effects.xml` (both folders), `AddRepairObjectBuff`, `GetEnhancedBuffInfo`, `GetBaseItemData`, the tooltip row and string; `W3RepairObjectEnhancement.OnTimeUpdated` and its field (ENCH-06).

**5.x:** 60 minutes, +20% armor and attack power; the code unchanged.

**Decisions:** port as legacy's values and duration (DI3, owner, 2026-10-19).

**Slices:**

1. **Buffs and tooltip line.** Verified 2026-10-19 and 2026-10-20, both trees (scripted through `AddRepairObjectBuff`, `GMTest_item12`, and `GMTest_item12_after` in the regression's `gmtest_panel()` call): both buffs at 1800 s, the steel sword's tooltip line, Geralt's slashing resistance +0.05 with the table's buff. Not tested: a real table or grindstone, the tooltip on screen, the grindstone's armor penetration in a real hit, Preservation (ENCH-06's check).

---

### Dependencies on other areas

- **Done areas ITEM builds on:** ARM and SWD (the item entries and their generators; ITEM's fields join their entries: one entry per item), DMG (the durability penalty's two callers, resistances and armor penetration), ENCH-06 (Preservation), ENCH-17 (the item tooltip).
- **Areas ITEM shares with:** XBOW (bolt and crossbow levels), CRAFT and LOOT (where kits are sold, dismantle kits), ECON (prices, repair prices), WGT (weights), UI (the tooltip and character panel beyond ITEM-12's line), XP (the debug level reset). What each owns is in the [scope](#scope).

### Save impact

None for a new playthrough. What is stored on an owned item stays as it was: its generated level (per-level abilities), its random bonuses and the `ItemQualityModified` flag; so items received before the mod keep 5.x's level and bonuses, and an item ITEM-04 moves to level scaling that was received with fixed damage (Iris in a save made before) loses the fixed value and has no level until obtained again (`reacquire items`). Values read from the definitions (the item level, the bonus values, quality, durability, the buffs) apply to owned items at once. Adding or removing the mod mid-playthrough is not supported ([save compatibility](../feature-mapping.md#save-compatibility)); as facts: after removing the mod, the level-scaled Iris and the other ITEM-04 items keep only their per-level damage or armor, master kits become unknown items, and armor rolled with legacy's bonus lists keeps them.

### Area decisions

Decided by the owner on 2026-10-19; DI1 on 2026-10-20. Legacy behaviour first applies to ITEM-03 to ITEM-09 and ITEM-11 (5.x did not change them).

| # | Question | Decision |
|---|---|---|
| DI1 | Bolt levels in legacy's level code (ITEM-01): (a) legacy's functions with 5.x's bolt lines kept; (b) legacy's functions as they are (bolts by the name list only) | (b), legacy's bolt levels (owner, 2026-10-20: 5.x's quality-based bolt rule is removed, "an important balance point") |
| DI2 | Quest reward level (ITEM-02) | Legacy: exactly Geralt's level (owner, 2026-10-19). The rule never takes effect, in legacy too: a reward's level is set when it enters the inventory, so rewards get the found-item level (Geralt's level -1 to +1); accepted as it is, no code change (owner, 2026-10-20) |
| DI3 | Armorer's Table and grindstone duration (ITEM-12) | Legacy: 30 minutes (owner, 2026-10-19) |
| DI4 | 5.x's Accessibility option "Disable item durability" (ITEM-10) | Stays available (owner, 2026-10-19) |
| DI5 | Random bonuses on 5.x's new relic armor (Dol Blathanna, White Tiger, Scarlet Crest; ITEM-06) | One random resistance on the chest piece, like legacy's relic armor (owner, 2026-10-19) |
| DI6 | The boundary | ITEM takes the repair and master kits and their effect; where they are sold stays with CRAFT and LOOT (owner, 2026-10-19) |

Also decided (owner, 2026-10-19):

- **Stacked random bonuses (ITEM-06):** ported as legacy (a level 30 magical sword can roll its crit chance bonus four times, 20 to 40%). How it played in legacy is [to test in legacy](../open-questions.md#to-test-in-legacy-ghost-mode); its balance is for the balance pass.
- **Blood and Wine gear at Geralt's level (ITEM-03):** confirmed as legacy intended: found or bought early, Blood and Wine's guard, knight, Toussaint and Thief gear has Geralt's level.

Also decided (owner, 2026-10-20):

- **Merchant restock (ITEM-02):** legacy's behaviour stays: a restock drops the weapons more than 3 levels below Geralt (`ClearLowLevelWeapons`). Bolts carry `WeaponTab`, not the `Weapon` tag the function selects, in legacy as in the port, so no restock removes bolts.
- **Bonus level (ITEM-06):** legacy's rule: the random bonuses count the level the item was given at generation.
- **Porter's calls confirmed:** the master kits' forced unequip respects 5.x's quest lock (ITEM-11's deviation); the tournament gloves' misspelt `DoNotEnhancem` removed (ITEM-08).
