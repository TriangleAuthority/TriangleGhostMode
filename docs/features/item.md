# ITEM: item level, random bonuses, durability and repair

The rules every weapon and armor piece shares: what level an item has and needs, the level a level-scaled item gets when Geralt finds, buys or is given it, its quality (rarity), the random bonuses a found or bought item rolls, durability and its penalty, repair kits, and the Armorer's Table and grindstone buffs. Ghost Mode reworked all of them around one idea, "no dancing around levels": **an item's level is read straight from its damage or armor** (the rule SWD-01 and ARM-01 built the numbers on), level-scaled items get Geralt's own level with a small spread, Blood and Wine's and Hearts of Stone's gear scales with Geralt instead of sitting in fixed level bands, and random bonuses depend on quality and level: higher quality gives more kinds of bonus, every 10 levels repeats each one (changelist 630–631, "Random weapons get additional bonuses depending on their quality and level"). Durability matters more (a penalty of up to 20 to 50% by difficulty), repair kits restore less, new master kits raise an item's level by one (changelist 12–14, 611, 633), and the Armorer's Table and grindstone give resistances and armor penetration for 30 minutes (changelist 857–858). Sources: the changelist's Armor and Swords sections (lines 546, 611, 618–633), Effects (857–858), the known bugs (12–14), and the code (most of ITEM is not in the changelist: the level code, the level tags, the quality changes and durability are omissions).

**What 5.x did in this area.** Almost nothing to 1.32's rules: `GenerateItemLevel`, `AddRandomEnhancementToItem`, the random bonus lists and values (`def_item_quality.xml`), durability and repair are 1.32's. 5.x's changes: quest reward items are generated 1 to 3 levels above Geralt (1.32: 0 to 1); bolts got a level rule of their own (a bolt Geralt holds is lowered by its quality, a bolt read by name, as on a schematic, is never below Geralt's level; [ITEM-01](#item-01-item-level-from-stats)); the Armorer's Table and grindstone buffs last 60 minutes (1.32: 15); an Accessibility option, "Disable item durability" (`DisableDurabilityItem`, read by the engine, not by any script; unverified what it covers); the blacksmith's repair panel was rebuilt (prices are ECON's). 5.x's new gear (the Netflix, Dol Blathanna, Vixen, Top Notch, White Tiger and Scarlet Crest items) goes through the same item code.

**How legacy Ghost Mode implements it.** Scripts: `W3GameParams.GetItemLevel` (the formula), `CInventoryComponent.GetItemLevel` and `CDefinitionsManagerAccessor.GetItemLevelFromName` (the adjustments), `CInventoryComponent.GenerateItemLevel` (now returns the level), `OnItemAdded`, `AddItemLevelAbility` (new), `AddRandomEnhancementToItem` (now takes the level), `AddQualityAbilityToItem` (new), the bonus lists in `W3GameParams.Init*Abilities` with new common lists, `GetDurabilityMultiplier` and the durability constants, `W3PlayerWitcher.RepairItem`, `IsItemRepairAble`, `AddRepairObjectBuff`, `CR4InventoryMenu.ApplyRepairKit`, `GetEnhancedBuffInfo` (new, the buff's line in tooltips), merchants' `ClearLowLevelWeapons` (new). Data: the level tags (`Autogen`, `AutogenUseLevelRange`, `AutogenForceLevel`) and level ranges (`item_level_min/max`) of about 130 items and abilities, the fixed damage or armor removed from items moved to level scaling, `DoNotEnhance` removed from 52 items, armor quality, `def_item_quality.xml` (the random bonus values), the repair kits (`def_item_alchemy_repair_kits.xml`), `EnhancedArmorEffect` and `EnhancedWeaponEffect` (`effects.xml`), all with their NG+ copies.

Unit lists: [attribution.csv](attribution.csv): mapped 2026-10-19 from the changelist, the hand-offs of DMG, STAM, ARM, ENCH and SWD, and sweeps (`unit_sweep.py` for `autogen`, `item_level`, `GetItemLevel`, `GenerateItemLevel`, `RandomEnhancement`, `quality`, `DoNotEnhance`, `durab`, `repair`, `enhancedarmor`/`enhancedweapon`; a field-by-field comparison of every item and ability unit in the item files, master against `legacy-GM`): 901 units carry an ITEM feature (33 script units, 409 XML units and their 413 NG+ copies, 46 CSV rows: 1 tooltip row and 5 strings × 9 languages); 563 of them are shared with other features (an item entry whose stats are ARM's or SWD's and whose level tags, level range, quality or `DoNotEnhance` are ITEM's). Units whose only change is the price, the weight, the dismantling parts or an NPC or secondary weapon's stats are left to ECON, WGT, CRAFT and AI ([hand-off](#hand-off-to-other-areas)). The same comparison found 80 crafted armor units (20 items, their NG+ copies and NG+-only pieces) whose only change besides price and parts is legacy's `DoNotEnhance`, which `gen_arm_items.py` already carries (ARM-01, SWD audit F4): attributed to ARM-01. Port status: **ported** (ITEM-01 to ITEM-12, 2026-10-19, 5.x-GM `945f0616` to `79d88d0d`, verified in both trees, mostly by script); [area decisions](#area-decisions) made by the owner (2026-10-19; DI1, legacy's bolt levels, 2026-10-20); audited 2026-10-20 ([ITEM audit](#item-audit-2026-10-20): F1 to F13); the owner decided DI1, DI2 and the audit's questions (2026-10-20); fix slice A done and verified in both trees (5.x-GM `db879f91`: F1, F5, F11, F13); F2 fixed as the owner decided (5.x-GM `2a8cfc7c`, legacy's bonus level), verified in both trees; the audit closed ([close-out](#audit-close-out)); **signed off** by the project owner (2026-10-20).

## Scope

**ITEM covers** item level (how it is read from the stats, how a level-scaled item gets one, the level tags and ranges in the item data, the items legacy moved to level scaling), item quality of armor, random item bonuses (the rules and the values), `DoNotEnhance` where legacy removed it, durability and its penalty, repair kits including the master kits that raise an item's level, and the Armorer's Table and grindstone buffs with their tooltip line.

**Not ITEM** (porter's call from the docs, for the owner to confirm with DI6):

| Subject | Area | Why |
|---|---|---|
| A weapon's or armor piece's own stats, slots, class and set tags, `DoNotEnhance` where legacy added it, the swords' quality | SWD, ARM (signed off) | Ported with their items; ITEM adds its fields to the same entries (one entry per item) |
| Prices, `mod_*` price tags, `mod_repair` (repair prices), merchants' funds | ECON | as ARM and SWD |
| Dismantle kits (the two new kit items, their strings), repair kit schematics, where the master kits are sold (`AddMasterArmorerItems`, Yoana's store, Hattori, the enchanter, the grandmaster smiths) | CRAFT, LOOT | ARM handed "mastercrafted kits (`AddMasterArmorerItems`, master repair kits)" to CRAFT; the kits' effect on an item is ITEM-11 |
| Weights of kits and items | WGT | |
| The standalone starts' inventories (`StandaloneEp1_1`, `StandaloneEp2_1`: mutagens, money, bolts, food, ingredients) | LOOT | Starting stock, not item rules; the standalone starting gear itself is ITEM-05 |
| NPC, secondary and monster weapons' quality and damage | AI | as SWD |
| Bolts' and crossbows' stats, the bolt level list's fix (`Blunt Bolt Legendary`) | XBOW | The crossbow and bolt branches of `GetItemLevel` sit in ITEM-01's function and are carried with it |
| The debug level reset (`fb1`, `fb2`, `fb3_internal`, `resetLevels`, `cleanupInv`, `SetGeraltLevel`, `resetme`) | XP | Level reset; only their level-scaled gear helper (`addAutogenEquipment`) is ITEM-02 |
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
| ITEM-10 | Durability | Penalty in steps: at most -5 to -20% at half durability by difficulty; armor loses 0.6, a weapon 0.26 (Death March 0.1) per hit; "damaged" below 50% | Penalty linear, `1 - (1 - durability)/4` on easy and normal (at most -20%, -30%), `/2` on hard and Death March (-40%, -50%), on weapon damage and armor; armor loses 0.5, a weapon 0.05 per hit; "damaged" below 75%; two Beauclair pants start at full durability | `GetDurabilityMultiplier`, `W3GameParams.<members>` |
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

### Classification and proposed action

| # | Feature | Class | Proposed action |
|---|---|---|---|
| ITEM-01 | Level from stats | clean (5.x's bolt lines overlap) | Port legacy's formula with legacy's bolt levels (DI1); ends SWD-01's level deviation |
| ITEM-02 | Level generation | overlap (rewards) | Port legacy's (DI2) |
| ITEM-03 | Level tags and ranges | clean | Port with the item generators; ends SWD-01's level-tag deviation |
| ITEM-04 | Moved to level scaling | clean | Port with the generators; ends ARM-01's, SWD-01's and SWD-06's two deviations |
| ITEM-05 | Standalone gear | clean | Port (the 32 units SWD deferred, with the swords' 16) |
| ITEM-06 | Random bonus rules | clean | Port legacy's code; ends STAM's and ENCH's hand-offs |
| ITEM-07 | Random bonus values | clean | Port (given whole, DLC override) |
| ITEM-08 | `DoNotEnhance` removed | clean | Port with ITEM-06 (the tag goes on rules legacy wrote for it); ends SWD-02's and ARM-01's deviations |
| ITEM-09 | Armor quality | clean | Port with the generators |
| ITEM-10 | Durability | clean, overlap (5.x's option) | Port legacy's penalty and constants (DI4 for the option); ends DMG-09's hand-off |
| ITEM-11 | Repair and master kits | clean | Port; the kits' shops stay CRAFT's (DI6) |
| ITEM-12 | Armorer's Table and grindstone | overlap (duration) | Port legacy's values (DI3); ends ARM's hand-off (ENCH-06's Armorer's Table check stays open: it needs a real table) |

---

### ITEM-01 Item level from stats

| | |
|---|---|
| Kind | system |
| Pillars | P8, P10 |
| 5.x class | clean; overlap on bolts |
| Flags | DI1 decided (legacy's bolt levels), done |
| Depends on | SWD-01, ARM-01 (damage and armor by level, signed off), XBOW (bolts, crossbows) |
| Skill trees | n/a |
| Port form | `@replaceMethod` of `W3GameParams.GetItemLevel`, `CInventoryComponent.GetItemLevel`, `CDefinitionsManagerAccessor.GetItemLevelFromName` (`gm/items/itemLevel.ws`: legacy's bodies; 5.x's bolt rule removed, DI1) |
| Port status | **signed off** (2026-10-20); **ported** (slice 1, 5.x-GM `945f0616`; legacy's bolt levels with the audit's fix slice A, 5.x-GM `db879f91`), verified in both trees |
| Open checks | an item equipped by hand at its new level; the bolts in the crossbow quick menu and on the crafting screen on screen (read by script); NG+ (by policy, untested) |
| Save impact | none: the level is computed when read, so owned items show and need the new level at once (the test save's items read legacy's levels) |
| NG+ counterpart | none (scripts) |

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

Legacy reads the name list without vanilla's -1 and drops the duplicate `Blunt Bolt Legendary` line that made it 5 instead of 12 (carried with the function; the bolts' stats stay XBOW's). The port shows legacy's levels, held and by name (DI1). As in 1.32, legacy and 5.x, the crossbow quick menu lists a bolt only up to Geralt's level (`hudModuleRadialMenu`) and the inventory refuses to equip one above it, so at level 1 none of these bolts is listed (all are level 2 or more).

So in the port before ITEM-01 a sword or armor piece showed and needed 5.x's level: the crafted Short sword (33) showed 2 for legacy's 1; the grandmaster Griffin steel sword 37 for 40 (read in game, SWD-01); witcher armor 2 levels and relic armor 1 level below the level ARM-01's armor was built for, other armor its `Floor` (from the code).

**Decisions:** port as legacy; bolts: legacy's levels, 5.x's quality-based bolt rule removed, "an important balance point" (DI1 (b), the owner, 2026-10-20); done with the [audit](#item-audit-2026-10-20)'s fix slice A (F13, 5.x-GM `db879f91`).

**Verification (slice 1, 2026-10-19, both trees):** scripted (`GMTest_item01`, in the regression): levels by name and of new copies held: the crafted Short sword 1 (5.x 2), the crafted silver sword 1, the grandmaster Griffin steel and silver swords 40 (5.x 37), the grandmaster Griffin trousers 34 (5.x 32), the Griffin armor, gloves and boots, a crafted heavy armor and Bear armor 1 against legacy's formula from their base armor. Not real: no item equipped by hand.

**Verification (audit fix slice A, 2026-10-20, both trees):** scripted (`GMTest_item01`, in the regression; also at level 20): all twelve bolts at legacy's level held (a new copy: what the inventory, the equip check and the crossbow quick menu read) and by name (what the crafting menu and schematic tooltips read): Tracking, Bait and Blunt 2, Target Point 5, Broadhead 10, Split 15, Explosive 20, Blunt Legendary 12, Target Point Legendary 15, Broadhead Legendary 20, Split Legendary 24, Explosive Legendary 26; the quick menu's filter (up to Geralt's level) read by script: none of them at level 1, all but Split and Explosive Legendary at level 20. Not real: the quick menu and the crafting screen were not opened.

**Later:** —

### ITEM-02 Level of a level-scaled item

| | |
|---|---|
| Kind | system |
| Pillars | P6, P10 |
| 5.x class | overlap (quest rewards) |
| Flags | balance, needs-decision (DI2) |
| Depends on | ITEM-01, ITEM-03 (the tags it reads), ITEM-06 (takes the level) |
| Skill trees | n/a |
| Port form | `gm/items/itemGeneration.ws`: `@replaceMethod CInventoryComponent.GenerateItemLevel` (legacy's rules, 5.x's signature: the level is read back with `GetItemLevel`); `@addMethod` `GMAddItemLevelAbility`, `GMClearLowLevelWeapons`; `@wrapMethod W3MerchantNPC.OnInteraction` (clears after a restock, seen as `lastDayOfInteraction` moving on); `OnItemAdded`'s change is the level passed to the random bonuses (ITEM-06); the debug command `addAutogenEquipment` dropped (tests add items directly) |
| Port status | **signed off** (2026-10-20); **ported** (slice 2, 5.x-GM `4b864e76`), verified in both trees |
| Open checks | a merchant met in play (stock and restock tested on a spawned merchant); a real quest's reward (the reward rule is inert, [audit](#item-audit-2026-10-20) F3) |
| Save impact | none for a new playthrough; items already owned keep the level they were generated with (stored on the item as per-level abilities, as 1.32) |
| NG+ counterpart | legacy's NG+ branch (range shifted by the NG+ level, the fixed per-level abilities) is in the same function |

**What it does:** a level-scaled item (`Autogen`) gets its level when it enters an inventory: found items Geralt's level -1 to +1 (quality 3 and 4), -1 to 0 (quality 1 and 2), exactly Geralt's (witcher gear); items with a range (`AutogenUseLevelRange`, ITEM-03) Geralt's level ±1 (exactly with `AutogenForceLevel`) clamped to the range; items in a merchant's stock Geralt's level -1 to +2, without vanilla's forced range tag; quest rewards exactly Geralt's level; no standalone (-1) or NG+ (+1/+2 for relics and witcher gear) adjustment; clamped between 1 and the maximum level. The level is added as per-level abilities (ARM-01's and SWD-01's `autogen_*`), returned, and passed to the random bonuses (ITEM-06); an item already generated returns 0 and the level is read with `GetItemLevel`. When a merchant restocks (`OnInteraction`), weapons more than 3 levels below Geralt are removed from the stock. `AddItemLevelAbility` adds one level's ability (the master kits, ITEM-11). Not in the changelist (an omission).

**Implementation (legacy):** `GenerateItemLevel`, `OnItemAdded`, `AddItemLevelAbility`, `ClearLowLevelWeapons`, `W3MerchantNPC.OnInteraction`; the debug commands `addAutogenEquipment`, `addAutogenEquipment_internal`.

**5.x:** 1.32's rules, except quest rewards at Geralt's level +1 to +3 (1.32: +0 to +1).

**Decisions:** port as legacy; rewards: DI2 (legacy's, decided).

**Verification (slice 2, 2026-10-19, both trees):** scripted (`GMTest_item02`, in the regression; also at Geralt's level 20): new copies added to Geralt's inventory get legacy's level: Blood and Wine's guard armor 1 (quality 2) 19 to 20 at level 20, guard armor 2 (quality 3) 19 to 21, the free DLC's Feline sword (witcher gear) exactly 20; Toussaint armor 3 (range 40 to 100) 40.

**Verification (audit fix slice A, 2026-10-20, both trees):** scripted (`GMTest_item02_merchant`, `GMTest_item02_reward`, in the regression; also at level 20): a spawned generic weapon merchant (`shop_generic_merchant_novigrad_weapons.w2ent`): new stock at Geralt's level -1 to +2 (1 to 3 at level 1, 19 to 22 at level 20); its restock clearing at level 20 removes the weapons more than 3 levels below him, keeps the rest and every bolt; talking to it with its funds due (`gmtest_item02_restock()`: `OnInteraction` "Talk" called by script, the last interaction moved back 100 days) removes a crafted Short sword (level 1) and keeps its bolts; a reward given with `theGame.GiveReward('sq108_special_armor', ...)` (Yoana's armor, quality 4) gets the found-item level (1 at level 1, 21 at level 20) and the reward code's `GenerateItemLevel(id, true)` adds nothing (F3). Not tested: a merchant met in play, a real quest's reward.

A finding from the test: the level is generated inside `AddAnItem` (`OnItemAdded`), so the quest-reward call in `r4Game.ws` (`GenerateItemLevel(id, true)`) finds the item already generated and adds nothing, for an item with a level range too (each branch requires the item to have no `autogen_*_base` ability yet); in 1.32, 5.x and legacy alike, a reward gets the found-item level. DI2's rule is ported as decided, but it never takes effect in play (from the code and the scripted add; no real reward tested; [audit](#item-audit-2026-10-20) F3).

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
| Port status | **signed off** (2026-10-20); **ported** (slice 2, 5.x-GM `4b864e76`), verified in both trees |
| Open checks | NG+ (by policy, untested) |
| Save impact | none for a new playthrough; an item already owned keeps its generated level |
| NG+ counterpart | applied, untested (legacy's own `items_plus` changes; `gen_item.py --verify` checks them) |

**What it does:** Blood and Wine's and Hearts of Stone's gear no longer sits in level bands. Legacy removed `AutogenUseLevelRange` (and the matching `item_level_min/max`) from 109 items: the guard, knight, Toussaint, Hanza and squire gear, the Thief (Borsody) armor, the second vampire set (`q704`), the tournament (`sq701`) gear, the Burning Rose and Ofir gear, the Kontusz, the Blood and Wine bonus silver swords, Remorse; such an item now gets Geralt's level when found or bought (ITEM-02). `AutogenForceLevel` (an exact level) is removed from 22 items (Aerondight, Remorse, the unique and Gwent swords, Ofir Sabre 1, the Caretaker's spade, the Feline sword of the free DLC quest, the Thief and second vampire gear, Toussaint armor 3, the Cianfanelli and tournament swords) and added to the laundry stick and pole; 17 minimum levels change (e.g. the unique swords and the second vampire swords 40 → 45, Gwent sword 40 → 36); `EP1` is removed from 36 Blood and Wine pieces (under 1.32's code it lowered their level and limited their random bonus; under legacy's code it has no effect). Not in the changelist (an omission).

**Implementation (legacy):** the tags of about 130 items and the ranges of about 127 abilities (regular, and their NG+ copies) in the base game, Hearts of Stone, Blood and Wine and the free DLC item files.

**5.x:** 1.32's tags and ranges. SWD-01 records the swords' share as a deviation until ITEM (confirmed by the owner, 2026-10-19); the armor's share is not recorded as a deviation (ARM-01 lists `item_level_min/max` and the tags as ITEM's).

**Decisions:** port as legacy; Blood and Wine's gear at Geralt's level confirmed by the owner (2026-10-19). `DoNotEnhancem` (1.32's misspelt tag on the `sq701` gloves, which legacy removed) goes with ITEM-08. Remorse's `1handedWeapon` tag, also in legacy's change, is not ITEM's.

**Verification (slice 2, 2026-10-19, both trees):** `gen_item.py --verify`: 0 unexplained differences (523 tags and 294 nodes regular, 530 and 298 NG+; differences counted only for slices not ported yet); `gen_arm_items.py` and `gen_swd_items.py --verify` 0 unexplained. In game (scripted, `GMTest_item02`): the guard armor without its range, its boots without `EP1`, the second vampire armor and Toussaint armor 3 without the forced level, the laundry stick with it, Toussaint armor 3 keeping its range; the Blood and Wine unique silver sword's range from 45 (`GMTest_swd03`).

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
| Port status | **signed off** (2026-10-20); **ported** (slice 3, 5.x-GM `038ddd65`), verified in both trees; the NG+ vampire gear swap added after the sign-off (5.x-GM `9b8e16a3`, compiles) |
| Open checks | NG+'s start keeping Iris and the vampire gear; a save holding an Iris obtained before (expected to need reacquiring) |
| Save impact | reacquire items (expected): an owned item that had fixed damage or armor and was never generated loses its fixed value and has no per-level abilities until it is obtained again (Iris in a save made before; unsupported mid-playthrough, matters for test saves) |
| NG+ counterpart | applied, untested |

**What it does:** items with a fixed damage or armor become level-scaled (`Autogen`, the fixed value removed): Iris (363 slashing; about 300 at level 35), Ofir armor (200) and Ofir Sabre 2 (308), Blood and Wine's first vampire set (`q702`: armor 230/87/84/87) and its steel sword (356, which also loses its fixed armor penetration, crit and confusion bonuses), Yoana's reward armor (166), the free DLC's Nekker boots (64), Damien's sword (an NPC's); the laundry stick, the Iron Poker, the Feline sword of the free DLC quest and the Burning Rose armor lose the fixed value they had next to their level scaling. In NG+ legacy keeps Iris and Blood and Wine's vampire armor, gloves, pants, boots and steel sword (level-scaled) instead of swapping them for their NG+ copies. Not in the changelist (an omission).

**Implementation (legacy):** the items' tags and their `_Stats` abilities (26 units and NG+), `NewGamePlusReplaceEP1`, `NewGamePlusReplaceEP2Items` (the five `q702` swaps commented out; found by CRAFT's mapping after ITEM's sign-off, ported after the [CRAFT and LOOT audit](craft.md#craft-and-loot-audit-2026-10-22), F5).

**5.x:** 1.32's fixed values. In the port they stay as deviations until ITEM: ARM-01's (Ofir armor, the `q702` vampire armor, Yoana's armor, the standalone gear; its text named the vampire armor Hearts of Stone's, corrected with this mapping), SWD-01's second (the standalone swords, Ofir Sabre 2, the Iron Poker, the laundry stick, the `q702` sword, the `mq1058` Feline sword, NG+'s crafted Burning Rose sword), SWD-06's two (Iris's fixed damage, the NG+ swap). The Nekker boots and Damien's sword are in no deviation (found by this mapping).

**Decisions:** port as legacy.

**Verification (slice 3, 2026-10-19, both trees):** scripted (`GMTest_item04`, in the regression; also at level 25): the `Autogen` tags and the fixed values gone from Iris, Ofir armor and Ofir Sabre 2, the first vampire armor and sword, Yoana's armor, the Nekker boots, Damien's sword; new copies of Iris and Ofir armor at Geralt's level -1 to +1, their level read from their damage or armor equal to the generated one; Iris equipped at level 25 with about 225 damage (`gmtest_swd_equip`). `gen_item.py`, `gen_arm_items.py` and `gen_swd_items.py --verify`: 0 unexplained. Not tested: NG+'s start (Iris kept), a save holding an Iris obtained before. The vampire gear's NG+ swap (2026-10-22, 5.x-GM `9b8e16a3`): compiles; `check_modsigns.py` 0 unmarked; NG+ untested by policy.

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
| Port status | **signed off** (2026-10-20); **ported** (slice 3, 5.x-GM `038ddd65`), verified in both trees (data and a new copy; no standalone start played) |
| Open checks | a standalone start (Hearts of Stone or Blood and Wine) |
| Save impact | none (the gear is given at the start) |
| NG+ counterpart | applied, untested |

**What it does:** the Hearts of Stone and Blood and Wine standalone starts (a new game begun at an expansion) give Geralt level-scaled gear at his level (`Autogen`, `AutogenForceLevel`) instead of fixed armor (175/65/61/65, 195/73/69/73) and swords (265/395, 297/435); the gear keeps `DoNotEnhance`.

**Implementation (legacy):** `def_item_ep1_stand_alone.xml`, `def_item_ep2_stand_alone.xml` (items and abilities, 24 and NG+): the 32 armor units SWD deferred to ITEM (the owner's decision, 2026-10-19) and the 16 sword units SWD-02 ported except their level tags.

**5.x:** unchanged; ARM-01's and SWD-01's deviations cover them.

**Decisions:** port as legacy. ARM-01 already carries the standalone armor's resistances (legacy's), so ITEM-05 adds the level tags, removes the fixed armor and damage and sets Blood and Wine's standalone armor to quality 3.

**Verification (slice 3, 2026-10-19, both trees):** scripted (`GMTest_item04`): the tags and values; a new Blood and Wine standalone armor has exactly Geralt's level (1 and 25). Not tested: a standalone start.

### ITEM-06 Random bonus rules

| | |
|---|---|
| Kind | system |
| Pillars | P6, P8 |
| 5.x class | clean |
| Flags | balance |
| Depends on | ITEM-02 (the level), ITEM-07 (the values), ITEM-09 (armor quality), ITEM-08 |
| Skill trees | n/a |
| Port form | `gm/items/itemBonuses.ws`: `@replaceMethod` of `AddRandomEnhancementToItem` (legacy's body; the callers stay 5.x's, so legacy's level argument is found as legacy's callers passed it: inside `OnItemAdded`, marked by a `@wrapMethod` (`gmInItemAdded`), the level the replaced `GenerateItemLevel` just generated (`gmGeneratedLevel`, ITEM-02's file; legacy returned it), otherwise `GetItemLevel`, as legacy's container and merchant callers; [audit](#item-audit-2026-10-20) F2), of the five `W3GameParams.Init*Abilities` and of `GetItemQualityFromName`; `@addMethod` `GMAddQualityAbilityToItem`, `GMGetRandomCommonArmorAbility`, `GMGetRandomCommonWeaponAbility`; the two common lists as `@addField` (`gmArmorCommonAbilities`, `gmWeaponCommonAbilities`) |
| Port status | **signed off** (2026-10-20); **ported** (slice 4, 5.x-GM `ddc21ca8`; legacy's bonus level with the audit's F2, 5.x-GM `2a8cfc7c`), verified in both trees |
| Open checks | a merchant's and a container's stock (the same function, called by 5.x's code) |
| Save impact | none for a new playthrough; an owned item keeps the bonuses it rolled (stored on the item, `ItemQualityModified`) |
| NG+ counterpart | none (scripts) |

**What it does:** changelist 630–631: "bigger quality means more bonuses, bigger level means bigger values". When an item first enters Geralt's, a merchant's or a container's inventory (unless it has `DoNotEnhance`): items of quality 1 to 4 get their quality ability; witcher gear (5) nothing more; relics (4) nothing, except chest armor one common resistance; chest armor one common resistance (quality 1+), one masterwork bonus (2+) and one magical (3+), the masterwork and magical ones repeated at levels 10, 20 and 30 (the same bonus up to 4 times); gloves, trousers and boots one masterwork (2+) and one magical (3+); swords one common (1+), one masterwork (2+), one magical (3+), each repeated at levels 10, 20, 30. The lists: common armor = the five physical and elemental resistances; masterwork armor and gear = burning, poison, bleeding resistance, adrenaline gain, Vitality (no flat armor); magical = the five sign intensities (now also on trousers and boots; attack power, crits and stamina regen gone); common weapon = armor penetration (flat or %), attack power, crit chance, crit damage, adrenaline; masterwork weapon = bleeding, freezing, poison, confusion, burning or stagger chance; magical weapon = sign intensities. So a level 30 magical sword can carry the same crit chance bonus four times (20 to 40%). The level counted is the one the item was given: when Geralt or a merchant receives a level-scaled item, the level it was just generated at; for an item generated before, one that is not level-scaled, or a container's stock, its level from its stats. They differ only for the level-scaled secondary weapons (axes, clubs, maces, the pickaxe and poker), whose fixed base damage reads 1 to 3 levels above the generated level: an axe given level 19 repeats its bonus twice, though it shows level 20 to 22.

**Implementation (legacy):** `AddRandomEnhancementToItem`, `AddQualityAbilityToItem`, `GetItemQualityFromName` (quality at least 1), `W3GameParams.Init*Abilities`, `GetRandomCommon*`, the two common lists in `W3GameParams.<members>`, `OnItemAdded`, `RebalanceItems`, `W3MerchantNPC.OnSpawned`.

**5.x:** 1.32's rules (quality 2 one masterwork bonus; 3 two, each magical or masterwork; Hearts of Stone items one magical; 1 and 4 none; lists with flat armor, attack power and stamina regen). STAM handed the stamina regen bonus here ([stam.md](stam.md#hand-off-to-other-areas)); ENCH handed the level argument.

**Decisions:** port as legacy; the stacking ported as legacy (owner, 2026-10-19; [to test in legacy](../open-questions.md#to-test-in-legacy-ghost-mode), balance pass). 5.x's new gear follows the rules by its quality: the Netflix gear (5) gets none; the Dol Blathanna, Vixen and Top Notch swords (4) none; 5.x's new relic armor (Dol Blathanna, White Tiger, Scarlet Crest) one common resistance on the chest piece, as legacy's relic armor (DI5, owner, 2026-10-19). STAM's (stamina regen out of the lists), DMG's and ENCH's (the level argument) hand-offs end here.
The bonuses count the level the item was given at generation, as legacy (the owner, 2026-10-20, [audit](#item-audit-2026-10-20) F2; it replaces the earlier call that they read the item's own level, which made level-scaled axes, clubs and maces repeat their bonuses one 10-level step early).

**Verification (slice 4, 2026-10-19, both trees):** scripted (`GMTest_item06`, in the regression; also at level 31): the common lists (20 draws each); new copies' bonuses counted by rule and level: chest armor quality 1 one, quality 3 three at level 1 and nine at level 32, relic chest armor one, Griffin armor none; gloves quality 3 two; swords quality 1, 2 and 3 one, two and three per 10 levels (twelve for quality 3 at level 32); each with its quality ability except witcher gear. Not tested: a merchant's or a container's stock (the same function, called by 5.x's code).

**Verification (audit F2, 2026-10-20, both trees):** scripted. In the regression (`GMTest_item06`): every copy's bonuses counted by its generated level, which for swords and armor must equal the level from their stats; `W_Axe01` (quality 1) generated 1, read 2 to 4, one bonus. At Geralt's levels 19, 20, 29 and 30 (classic tree; 19 and 29 new tree; `setlevel(N)`, then `gmtest_item06_axe(12)`): 12 new `W_Axe01` and 12 `W_Mace01` each roll one common bonus per 10 levels of the level they were given, not of their level from damage: given 18 or 19 (read 19 to 23) two bonuses, given 20 (read 21 to 24) three, given 28 or 29 (read 29 to 33) three, given 30 (read 31 to 33) four; a quality 3 sword, the laundry stick and quality 3 chest armor unchanged (generated level equal to the level from stats, 6/9/12, 2/3/4 and 5/7/9 bonuses by step). Not tested: an axe looted or bought in play.

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
| Port status | **signed off** (2026-10-20); **ported** (slice 4, 5.x-GM `ddc21ca8`), verified in both trees |
| Open checks | an owned item's rolled bonus on an old save (read by name, expected to take the new range) |
| Save impact | none (expected: the bonus abilities are read by name, so an owned item's rolled bonus takes the new range, as SWD-10's owned Top Notch sword showed for a range) |
| NG+ counterpart | applied, untested (legacy's `items_plus` copy) |

**What it does:** the values of the random bonuses: physical and elemental resistances 3–5% (1–4%), poison, bleeding and burning resistance 5–10% (1–4%), Vitality 200–400 (10–50), adrenaline gain 3–5% (1–4%), sign intensity 3–5% (1–5%), armor penetration 10–20 (10–40) and a new 3–5% resistance reduction, attack power +3–5% (+5–8%), crit chance 5–10% (1–4%), crit damage +10–20% (+1–10%), effect chances 3–5% (1–5%); the flat attack power (+10–40) and stamina regen bonuses emptied; `MA_Precision` and `MA_Gore` read the attributes the game uses (`instant_kill_chance`, `dismember_chance`, vanilla's `_mult` names do nothing). DMG handed these values here ([dmg.md](dmg.md#hand-off-to-other-areas)).

**5.x:** unchanged from 1.32.

**Decisions:** port as legacy.

**Verification (slice 4, 2026-10-19, both trees):** `gen_item.py --verify` 0 unexplained; in game (scripted, `GMTest_item06`): crit chance from 0.05, Vitality from 200, flat attack power and stamina regen 0, slashing resistance from 0.03, the new resistance reduction from 0.03. Save impact as expected: the values are read by name (an owned item's bonus takes the new range; not checked on an old save).

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
| Port status | **signed off** (2026-10-20); **ported** (slice 5, 5.x-GM `e9d7dc19`), verified in both trees |
| Open checks | a Blood and Wine guard or knight piece bought or looted in play |
| Save impact | none for a new playthrough; an owned item does not roll later (the roll happens once, on receipt) |
| NG+ counterpart | applied, untested |

**What it does:** 52 items of the expansions roll random bonuses again: Blood and Wine's guard and knight gear (first tier), the `B` versions of the Thief and Burning Rose gear and the Thief gear without the medallion, Ofir armor and its `B` pieces, the tournament (`sq701`) armor and swords, the Toussaint, Cianfanelli and elven (`mq7007`) swords, the Blood and Wine bonus silver swords and their `R` copies. Not in the changelist (an omission; legacy's rework of the random bonuses).

**5.x:** 1.32's tags. In the port they stay as two deviations until ITEM (ARM-01's 42 armor pieces, SWD-02's 10 swords; confirmed by the owner, 2026-10-19). Where legacy added the tag (crafted gear), ARM-01 and SWD-02 carry it already.

**Decisions:** port as legacy, after ITEM-06. The `sq701` tournament gloves carried 1.32's misspelt `DoNotEnhancem`, which did nothing and legacy removed: removed with ITEM-08 (attribution corrected; confirmed by the owner, 2026-10-20).

**Verification (slice 5, 2026-10-19, both trees):** scripted (`GMTest_item08`, in the regression): no `DoNotEnhance` on the guard boots, the knight trousers and Ofir armor, crafted armor keeping legacy's; new Blood and Wine guard armor 1 (quality 2) rolls one common and one masterwork bonus. `gen_item.py`, `gen_arm_items.py` and `gen_swd_items.py --verify`: 0 unexplained.

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
| Port status | **signed off** (2026-10-20); **ported** (slice 5, 5.x-GM `e9d7dc19`), verified in both trees |
| Open checks | — |
| Save impact | none (expected: quality is read from the definitions; an owned item's random bonuses stay as rolled) |
| NG+ counterpart | applied, untested |

**What it does:** armor quality (its rarity colour, and with ITEM-06 how many random bonuses it rolls) follows the tier: crafted armor quality 1 for the first tier, 2 for the second, 3 from the third (relic crafts 4; vanilla 3 for all), loot armor's random ranges narrowed or fixed by tier (e.g. Light armor 04 1–2 → 3, Medium armor 01 1–3 → 1, Heavy armor 03 1–3 → 3), the tournament armor 2 → 4, the Kontusz 2 → 1, Kaer Morhen's starting armor 5 → 1. The swords' quality is SWD-02's (ported). Not in the changelist (an omission).

**Implementation (legacy):** `quality` in 57 armor `_Stats` abilities and their NG+ copies.

**5.x:** unchanged from 1.32. Kaer Morhen's starting armor already has legacy's quality 1 from `gen_arm_km.py` (ARM-12).

**Decisions:** port as legacy.

**Verification (slice 5, 2026-10-19, both trees):** scripted (`GMTest_item08`): crafted heavy armor 1 quality 1 (5.x 3), crafted boots 2 and 4 quality 2 and 4, loot heavy armor 2 quality 2 (5.x 1 to 3), the Kontusz 1 (5.x 2); `gen_item.py --verify` checks all 57 and their NG+ copies.

### ITEM-10 Durability

| | |
|---|---|
| Kind | tuning, system |
| Pillars | P1, P8 |
| 5.x class | clean; overlap with 5.x's option |
| Flags | balance, needs-decision (DI4) |
| Depends on | DMG (`GetTotalWeaponDamage` and the armor term read the penalty, signed off) |
| Skill trees | n/a |
| Port form | `@replaceMethod W3GameParams.GetDurabilityMultiplier` (`gm/items/durability.ws`); the constants as `default` lines in W3GameParams' scope-based override block (`gm/stamina/staminaCosts.ws`: one block per class in the mod); the two Beauclair trousers' `initial_durability` through `item_layer.py` (`ATTRS`, opening-tag attributes) |
| Port status | **signed off** (2026-10-20); **ported** (slice 6, 5.x-GM `9e26dfb7`), verified in both trees |
| Open checks | wear in a real fight; the other difficulties (the test reads the current one); what 5.x's "Disable item durability" option covers |
| Save impact | none |
| NG+ counterpart | none (scripts); the two pants' NG+ copies |

**What it does:** "durability penalties were redone" (the mod description; not in the changelist). The penalty on weapon damage and armor is linear in lost durability: `1 - (1 - durability)/4` on easy and normal (at most -20% and -30%), `1 - (1 - durability)/2` on hard and Death March (at most -40% and -50%); vanilla's steps give at most -5 to -20% at half durability. Gear wears slower (armor 0.5 instead of 0.6 per hit; weapons 0.05 instead of 0.26, Death March 0.1), and counts as damaged below 75% (50%). Torlara and Torzirael lose their indestructibility (`MA_Indestructible`), ported with SWD-03 (confirmed by the owner, 2026-10-19).

**Implementation (legacy):** `GetDurabilityMultiplier`, the constants in `W3GameParams.<members>`; DMG-09 handed it here ([dmg.md](dmg.md#dmg-09-durability-scaling)).

**5.x:** 1.32's penalty and constants; the port's `GetTotalWeaponDamage` (DMG-08) calls 5.x's penalty. 5.x adds an Accessibility option "Disable item durability" (`DisableDurabilityItem`, off by default; part of the accessibility preset); no script reads it, so the engine applies it (what it covers is unverified).

**Decisions:** port as legacy; 5.x's option stays available (DI4, owner, 2026-10-19). DMG-09's hand-off ends here.

**Verification (slice 6, 2026-10-19, both trees):** scripted (`GMTest_item10`, in the regression): the penalty on Hard 0.75 at half durability and 0.6 at none; damaged below 75%, armor wear 0.5 and weapon wear 0.05 per hit; Geralt's steel sword at half durability deals 18 of 24 (DMG-08's weapon damage reads the penalty); the two Beauclair trousers start at full durability. Not tested: wear in a real fight, the other difficulties (the test reads the current one), what 5.x's option covers.

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
| Port status | **signed off** (2026-10-20); **ported** (slice 7, 5.x-GM `a5581556`; the forced unequip with the audit's fix slice A, 5.x-GM `db879f91`), verified in both trees (scripted) |
| Open checks | a kit used in the inventory menu by hand (drag and drop, E; the menu's handler was run by script); the unequip under a quest's equipment lock |
| Save impact | none |
| NG+ counterpart | applied, untested |

**What it does:** the three repair kit tiers restore 10/20/30% (15/40/90%) and have quality 1/2/3. New master kits, "Master weaponsmith tools" and "Master armorsmith tools" (quality 4), restore 100% and permanently add one level's damage or armor to the item they are used on (+8 steel, +10 silver damage; +5 chest armor, +2 for the other pieces): "You can level up your armors (weapons) with mastercrafted kits" (changelist 611, 633), sold by Yoana after her quest, Hattori after his, the Hearts of Stone enchanter and the Blood and Wine grandmaster smiths (CRAFT and LOOT). Any item with durability takes a kit, at full durability too (vanilla refuses); the changelist's known bug (12–14): drag and drop only works below 100%, use (E) always. If the new level is above Geralt's, the item is unequipped, in combat too.

**Implementation (legacy):** `def_item_alchemy_repair_kits.xml` (the six kits and two master kits, their abilities, regular and NG+), `RepairItem`, `IsItemRepairAble`, `ApplyRepairKit`, `AddItemLevelAbility` (ITEM-02), 4 strings.

**5.x:** unchanged; the blacksmith's repair panel rebuilt (repair prices ECON).

**Decisions:** port as legacy; ITEM takes the kits and their effect, where they are sold stays CRAFT's and LOOT's (DI6, owner, 2026-10-19): sold since CRAFT-10 and LOOT-04 (2026-10-22), below.
- **Deviation:** 5.x's quest lock on equipment changes (`AreManualEquipmentChangesBlocked`, set by quests) also stops the master kits' forced unequip: while a quest blocks equipment changes, an item a master kit raises above Geralt's level stays equipped; legacy had no such lock (porter's call, the auditor's suggestion; confirmed by the owner, 2026-10-20).
- Ended 2026-10-22 with CRAFT-10 and LOOT-04: the temporary deviation "no shop sells the master kits". Hattori, Yoana after her quest, the Hearts of Stone enchanter and Blood and Wine's archmaster sell them ([LOOT-04](loot.md#loot-04-special-merchants)).

**Verification (slice 7, 2026-10-19, both trees):** scripted (`GMTest_item11`, in the regression), through `RepairItem`, which using a kit calls: kit values 0.1/0.2/0.3 and 1, qualities; weapon kit 1 on a sword at 50% gives 60% and is used up; a full sword takes a kit; master weaponsmith tools on a full sword raise its level 1 to 2 (one more per-level ability); master armorsmith tools on armor at 20% repair it fully and add a level; the master kits' names. Not tested: using a kit in the inventory menu (drag and drop or E).

**Verification (audit fix slice A, 2026-10-20, both trees):** scripted in the inventory menu (`gmtest_item11_unequip_prep()`, `gmtest_item11_unequip()`: the menu opened by script, the master weaponsmith tools applied through its handler `OnApplyRepairKit`, which using a kit on an equipped item calls): an equipped sword at Geralt's level raised to level 2 is unequipped, out of combat and in combat (wolves spawned, `IsInCombat` true), the flag cleared afterwards; in the regression (`GMTest_item11`) the condition: the raised sword is no longer equippable. Not tested: drag and drop or E by hand, the quest lock.

### ITEM-12 Armorer's Table and grindstone buffs

| | |
|---|---|
| Kind | tuning, ui |
| Pillars | P6, P7 |
| 5.x class | overlap (duration) |
| Flags | needs-decision (DI3) |
| Depends on | DMG (resistances and armor penetration in the formula, signed off), ENCH-06 (Preservation keeps them, signed off) |
| Skill trees | n/a |
| Port form | `EnhancedArmorEffect`, `EnhancedWeaponEffect` given whole in `abilities/gm_item_effects.xml` (NG+ by `gen_ngplus.py`); `gm/items/repairObjects.ws`: `@replaceMethod W3PlayerWitcher.AddRepairObjectBuff`, `@addMethod CInventoryComponent.GMGetEnhancedBuffInfo` and `GMFindAttrInTooltipSettings` (legacy's helper, gone from 5.x), a `@wrapMethod` of `W3TooltipComponent.GetBaseItemData` that puts the lines first (Iris's description wrapper keeps them); `tooltip_settings.csv` row `resistance_perc_bonus_descr`; string 2110992483 (9 languages) |
| Port status | **signed off** (2026-10-20); **ported** (slice 8, 5.x-GM `79d88d0d`), verified in both trees (scripted) |
| Open checks | a real Armorer's Table and grindstone; the tooltip line on screen; the grindstone's armor penetration in a real hit; ENCH-06's Armorer's Table check (Preservation) |
| Save impact | none (a buff active on load keeps its old values until it runs out) |
| NG+ counterpart | applied, untested |

**What it does:** changelist 857–858: the Armorer's Table gives +5% to all damage resistances, the grindstone 10 armor penetration and 5% resistance reduction, each for 30 minutes (vanilla: +20% armor, +20% attack power, 15 minutes); they apply even with no gear equipped; an item's tooltip shows the active buff, its bonus and the time left. Preservation (ENCH-06, ported) keeps them from expiring; `W3RepairObjectEnhancement`'s timer change is ENCH-06's and ported.

**Implementation (legacy):** `effects.xml` (both folders), `AddRepairObjectBuff`, `GetEnhancedBuffInfo`, `GetBaseItemData`, the tooltip row and string; `W3RepairObjectEnhancement.OnTimeUpdated` and its field (ENCH-06).

**5.x:** 60 minutes, +20% armor and attack power; the code unchanged. ARM handed `AddRepairObjectBuff` here, ENCH the buffs Preservation keeps.

**Decisions:** port as legacy's values and duration (DI3, owner, 2026-10-19). ARM's `AddRepairObjectBuff` hand-off ends here; ENCH-06's open check (Preservation keeping the buffs) stays open.

**Verification (slice 8, 2026-10-19, both trees):** scripted (`GMTest_item12`, in the regression), through `AddRepairObjectBuff`, which using the table or grindstone calls: values and 1800 s; both buffs added (1800 s left; Geralt's slashing resistance is logged but read in the same frame and not asserted); the steel sword's tooltip line ("Enhanced Weapons (1800 s): +10 Armor penetration, +5 % Enemy damage resistance reduction"). Not tested: a real table or grindstone, the tooltip on screen, Preservation (ENCH-06's check).

**Verification (audit fix slice A, 2026-10-20, both trees):** scripted (`GMTest_item12` in the regression adds the buffs; `GMTest_item12_after`, in the regression's next call `gmtest_panel()`, reads Geralt once the buff's ability counts): slashing resistance 0.17 → 0.22 with the table's buff (+0.05), asserted. Not tested: the grindstone's armor penetration in a real hit.

### ITEM audit (2026-10-20)

Done by a fresh session ([audit](../feature-mapping.md#audit-signing-a-feature-off)) on 5.x-GM `79d88d0d` and master `506d6f4c` (regression 564 passed, 0 failed in each tree, as recorded by the port), reading code and data only; no game run (every finding below is plain in the code or the data, and F3 is confirmed by `GMTest_item02`'s own log line that a level-scaled item is generated inside `AddAnItem`). Every script unit [attribution.csv](attribution.csv) gives ITEM (`gm/items/itemLevel.ws`, `itemGeneration.ws`, `itemBonuses.ws`, `itemScaling.ws`, `durability.ws`, `repair.ws`, `repairObjects.ws`, the W3GameParams defaults in `gm/stamina/staminaCosts.ws`, the tooltip wrapper and Iris's) was read against legacy's code (`legacy-GM`: `gameParams.ws`, `inventoryComponent.ws`, `definitionsManager.ws`, `playerWitcher.ws`, `inventoryMenu.ws`, `merchantNPC.ws`, `container.ws`, `guiTooltipComponent.ws`, `r4Game.ws`), 1.32 and 5.x, and against the changelist (lines 12–14, 546, 611, 630–633, 857–858). The data was compared by an independent script (the auditor's, not `gen_item.py` or the area generators): every item and ability entry of every item and ability file, regular and NG+, as the game reads it (Ghost Mode's DLC over 5.x, `replace` and `extend` applied) against legacy's and 1.32's, values normalised (`max` defaulting to `min`, numbers as numbers); then every ITEM field over all entries (the level tags `Autogen`, `AutogenUseLevelRange`, `AutogenForceLevel`, `EP1`, `DoNotEnhance` and `DoNotEnhancem`; `item_level_min/max`; `quality`; `initial_durability`, `max_durability`) and every field of every ITEM unit and of every `MA_*`, `quality_*`, `autogen_*`, repair kit and `Enhanced*Effect` entry (prices, weights and dismantling parts left to ECON, WGT and CRAFT); the 5 strings in 9 languages against legacy's rows; the tooltip rows every random bonus and buff attribute reads.

**Checked and holding:** the data equals legacy's: 7,991 ITEM field comparisons over all entries agree, the only differences being the pheromone potions' and Killer Whale's quality (ALCH's, handed off); the 10,360 fields of the ITEM units and of the bonus, kit, autogen and buff entries agree with legacy's except child blocks and tags of other areas (5.x's scabbards and armor variants kept, ARM's NG+ set tag on the free DLC's Feline sword). That covers the level tags and ranges of every item (ITEM-03, ITEM-04, ITEM-05), the fixed damage and armor removed (Iris, Ofir, the vampire set, Yoana's armor, the Nekker boots, Damien's sword, the standalone gear), `DoNotEnhance` (ITEM-08, the tournament gloves' misspelt tag included), armor quality (ITEM-09), the bonus values with the new `MA_ArmorPenetrationPerc` (ITEM-07), the two Beauclair trousers (ITEM-10), the six kits and the two master kits with their abilities (ITEM-11), the two buffs (30 minutes, ITEM-12) and the per-level abilities (a fresh level-scaled sword or armor piece reads back exactly its generated level: `Ceil` of a base of 19–25 plus 8 per level, and the like). The 5 strings equal legacy's in all 9 tables; the tooltip rows equal legacy's. The code equals legacy's: `GetItemLevel` (all three; 5.x's bolt lines kept in the two `DI1` blocks), `GenerateItemLevel` (spreads by quality, merchants -1 to +2, rewards exactly, ranges ±1 clamped, no standalone or NG+ bumps), `AddItemLevelAbility`, `ClearLowLevelWeapons` and the restock, `AddRandomEnhancementToItem` with `AddQualityAbilityToItem` (but F2), the five bonus lists and the two common lists, `GetItemQualityFromName`, `GetDurabilityMultiplier` and the four constants, `RepairItem`, `IsItemRepairAble`, `ApplyRepairKit` (but F1), `NewGamePlusReplaceEP1`, `AddRepairObjectBuff`, `GetEnhancedBuffInfo` and its place at the top of the description. The owner's decisions hold as implemented: DI1 (a) kept as the porter's call in two isolated blocks; DI3 1800 s; DI4 nothing touches 5.x's option; DI5 by quality (Dol Blathanna, White Tiger and Scarlet Crest armor quality 4: one common resistance on the chest piece; the Netflix gear 5: none; the new swords 4: none); DI6 (no shop sells the master kits yet; their loot entries are LOOT's, F10); the stacked bonuses as legacy; DI2 as written but inert (F3). The temporary deviations until ITEM are all ended (none in [deviations.md](deviations.md) names ITEM; SWD-01's, SWD-02's, SWD-06's two and ARM-01's entries say so). No skill is involved (no per-tree code; the regression ran in both trees). No leftovers in the code; `//modSigns` markers in place. `check_modsigns.py` clean (274 bodies, 0 unmarked); `deviations.py --check` current (91; 14 unconfirmed, ITEM's one being DI1's); `gen_item.py --verify` (537 tags and 412 nodes, 544 and 418 NG+), `gen_arm_items.py --verify` and `gen_swd_items.py --verify` 0 unexplained; `gen_item.py`, `gen_arm_items.py`, `gen_swd_items.py`, `gen_arm_km.py`, `gen_arm_new.py`, `gen_ngplus.py` and `gen_ench.py --check` current; `gen_ench.py --verify` no difference. `unit_sweep.py` (`autogen`, `item_level`, `GetItemLevel`, `GenerateItemLevel`, `RandomEnhancement`, `ItemQuality`, `quality`, `DoNotEnhance`, `durab`, `repair`, `enhancedarmor`, `enhancedweapon`, `EnhancedBuff`, `AddItemLevelAbility`, `LowLevel`, `ReapairKit`) finds no unattributed ITEM unit; besides, `CR4InventoryMenu.UnequipItem` belongs to ITEM-11 (F1). The rest are in the hand-off table (dismantle kits, crossbows, NPC and secondary weapons' stats, weights, the debug level reset, the book tooltips, potion quality, food toxicity, the standalone inventories), or price and dismantling changes of the free DLC's Temerian and Skellige armor (ECON, CRAFT), or the sweep's line matching (`Aerondight_EP2_Stats`, `Shield_Stats`: weight only).

**Owner's decisions (2026-10-20):** DI1 (legacy's bolt levels: F13), F2 (legacy's rule: the level given at generation), F3 (DI2 accepted as it is), F4 (legacy's restock behaviour stays); the porter's calls listed in the [area decisions](#area-decisions) confirmed.

**Findings:**

1. **An item raised above Geralt's level by a master kit stays equipped in combat** (clear fix). Legacy gave `CR4InventoryMenu.UnequipItem` an optional `forceUnequip` that skips the "cannot do that in combat" refusal, and `ApplyRepairKit` calls it with `true` (legacy `inventoryMenu.ws:2380`, `2397`, `4075`), so the item comes off whenever its new level is above Geralt's. 5.x's `UnequipItem` has no such parameter and refuses in combat (5.x `inventoryMenu.ws:2498`, `2521`); the port calls it with two arguments (`gm/items/repair.ws:63`), so master tools used from the inventory during a fight leave the over-level item equipped. The legacy unit (`CR4InventoryMenu.UnequipItem`) was unattributed: attributed to ITEM-11 with this audit. Fix: unequip without the combat check in `ApplyRepairKit` (a GM helper doing what `UnequipItem` does for a paperdoll item, or a GM flag that a scope-based override of the check reads); keep 5.x's quest lock (`AreManualEquipmentChangesBlocked`, `:2515`, which legacy did not have) as a porter's call to record. Check: master tools on an equipped sword at Geralt's level, in and out of combat. **Fixed** (5.x-GM `db879f91`): `CR4InventoryMenu.UnequipItem` replaced with its combat refusal skipped while `gmForceUnequip` is set, which `ApplyRepairKit` sets around its call (legacy's change, through a field since a replaced method keeps its signature); 5.x's quest lock kept and recorded as a deviation in [ITEM-11](#item-11-repair-kits-and-master-kits) (porter's call, the auditor's suggestion); verified in both trees in the inventory menu, out of and in combat (ITEM-11, slice A).
2. **Level-scaled secondary weapons roll their repeated bonuses one threshold early** (owner decision). Legacy's `OnItemAdded` passed the level `GenerateItemLevel` had just generated (legacy `inventoryComponent.ws:5397-5414`); only its container and merchant callers passed `GetItemLevel` (legacy `container.ws:355`, `merchantNPC.ws:113`). The port reads `GetItemLevel` for every caller (`gm/items/itemBonuses.ws:149`; 5.x `inventoryComponent.ws:4675`, `4688`). For level-scaled swords and armor the two agree (their own abilities carry no base damage or armor beyond the 1 silver the formula subtracts; checked over every `Autogen` item), but the secondary weapons (`W_Axe01` to `W_Axe06`, `W_Club`, `W_Mace01`, `W_Mace02`, `W_Pickaxe`, `W_Poker`: `Autogen`, `PlayerSteelWeapon`, quality 1–4) keep a fixed base damage (`W_Axe 1 _Stats` 10–25 slashing, 5.x `def_item_weapons_secondary.xml:11`; up to 40–120 on `W_Axe 6`) on top of the per-level damage, so their level from damage is 1 to 3 above the generated one (more for the axes with higher bases). In play: an axe, club or mace of quality 1–3 that Geralt loots or buys around levels 7 to 9, 17 to 19 or 27 to 29 can get each of its bonuses one more time than in legacy. Not recorded as a deviation; ITEM-06's port form said the callers' level was the item's (corrected with this audit). Fix: when the item is Geralt's or a merchant's and level-scaled, use the number of its per-level abilities (what `GenerateItemLevel` added: legacy's level), `GetItemLevel` otherwise. Check: a scripted count over copies of `W_Axe01` at Geralt's level 9. **Decided** (project owner, 2026-10-20): legacy's rule, the bonuses count the level the item was given at generation. **Fixed** (5.x-GM `2a8cfc7c`): `AddRandomEnhancementToItem` reads, inside `OnItemAdded`, the level `GenerateItemLevel` just generated, `GetItemLevel` otherwise (legacy's callers); verified in both trees ([ITEM-06](#item-06-random-bonus-rules), audit F2).
3. **The quest-reward level (DI2) never takes effect** (owner decision; the port agent's finding, confirmed and corrected). A reward is added with `AddAnItem` (5.x `r4Game.ws:1134`), whose `OnItemAdded` generates the level at once (the found-item rule); the reward code's `GenerateItemLevel(id, true)` (`:1141`) then finds an `autogen_*_base` ability on the item and adds nothing, for items with a level range too (each branch requires the base ability to be missing: `gm/items/itemGeneration.ws:81`, `105`, `129`, `153`, `177`); ITEM-02 said the range items were clamped again (corrected with this audit). The same holds in 1.32 and legacy, whose code is the same (`GMTest_item02` logs the generation inside `AddAnItem`; the reward loop also reads `ids[i]` for `ids[itemCount]`, vanilla's slip, which would only matter if the call did anything). In play, legacy's rewards and the port's get the found-item level: Geralt's level -1 to +1 (quality 3–4), -1 to 0 (quality 1–2), exactly his (witcher gear), clamped to a range. Options: (a) keep it as legacy played (DI2's rule stays in the code, inert; no deviation, since the behaviour is legacy's); (b) make rewards exactly Geralt's level (re-generate a reward's per-level abilities; a deviation from how legacy played). Recommendation: (a). **Decided** (project owner, 2026-10-20): (a), accepted as it is; recorded in DI2.
4. **The merchant-restock question on bolts is answered** (no action; relevant to DI1). `ClearLowLevelWeapons` takes `GetAllWeapons`, which is `GetItemsByTag('Weapon')` (5.x `inventoryComponent.ws:4281`); bolts carry `WeaponTab`, not `Weapon`, in 1.32, legacy and 5.x (`def_item_bolts.xml`), so a restock never removes bolts and DI1 has no effect on merchants. Crossbows (`Weapon`, level from attack power) and secondary weapons are removed when more than 3 levels below Geralt, as in legacy. DI1 only changes the bolt levels Geralt sees (held: lowered by quality; by name, in the crafting menu: at least his level). **Decided** (project owner, 2026-10-20): legacy's restock behaviour stays (no change); the owner's note "bolts included" does not match the code: with legacy's bolt levels too, no restock removes bolts, since none carries the `Weapon` tag.
5. **Six added methods lack the `GM` prefix** (clear fix). `GetRandomCommonArmorAbility`, `GetRandomCommonWeaponAbility` (`gm/items/itemBonuses.ws:17`, `23`), `AddQualityAbilityToItem` (`:281`), `AddItemLevelAbility`, `ClearLowLevelWeapons` (`gm/items/itemGeneration.ws:205`, `247`), `GetEnhancedBuffInfo` (`gm/items/repairObjects.ws:30`) keep legacy's names, against [development.md](../development.md#conventions) ("prefix everything Ghost Mode adds"); the two fields and `GMFindAttrInTooltipSettings` are prefixed. Fix: rename them and their callers (`repair.ws:30`, `itemGeneration.ws:279`, `repairObjects.ws:144`, `swords/iris.ws:565`, `tests/gmTestsItem.ws:274`, `277`, `451`). ENCH's `HasGlyphwordActive` (signed off) has the same gap; noted for ENCH. **Fixed** (5.x-GM `db879f91`): renamed `GMGetRandomCommonArmorAbility`, `GMGetRandomCommonWeaponAbility`, `GMAddQualityAbilityToItem`, `GMAddItemLevelAbility`, `GMClearLowLevelWeapons`, `GMGetEnhancedBuffInfo`, with every caller; the port forms in this page name them.
6. **ITEM-02's reward note was wrong** (corrected with this audit): see F3.
7. **Open checks and labels** (corrected with this audit). Every entry's **Open checks** row said "—" while its slice listed what was not tested (now listed, as the SWD audit did); ITEM-12's verification said Geralt's slashing resistance rose by 0.05, which the test logs in the same frame and does not assert (now said); ITEM-12's classification and the port order said slice 8 ended ENCH-06's Armorer's Table check, which needs a real table and stays open in [ench.md](ench.md) (corrected); the unit-list status ("next: the audit").
8. **The status page was stale** (corrected with this audit): [README.md](README.md#where-the-port-stands) still described ITEM as mapped and "the next area", with DI1 to DI6 waiting for the owner, and listed "ITEM's area decisions" as waiting on the owner (now: ported, audited; DI1 and the audit's decisions waiting).
9. **The save-impact list missed ITEM** (corrected with this audit). [README.md](README.md#features-with-a-save-impact) said "none so far", while ITEM-04 is `reacquire items` (expected): an Iris, Ofir armor or Ofir Sabre 2, a piece of the first vampire set, Yoana's armor, the Nekker boots or standalone gear held from before keeps no fixed damage or armor and has no per-level abilities until obtained again; the removal facts (the master kits become unknown items; the level-scaled items keep only their per-level damage or armor) were missing too.
10. **Hand-offs** (corrected with this audit). The LOOT row did not name the master kits' shop entries legacy added (`def_loot_shops.xml`, both folders: Hattori's `_store__Hattori_Master_Blacksmith` and Yoana's `_store__Master_Armorsmith_Yoana` in the base game, `_store__LW_DLC_EnchanterMaster` in Hearts of Stone, `_EP2_store_archmaster` in Blood and Wine); CRAFT keeps `AddMasterArmorerItems` and its call. The other hand-offs are complete and placed: CRAFT, ECON, WGT, XBOW, AI, XP, FIX, ALCH, FOOD, EFX and UI as listed; DMG's, STAM's, ENCH's, ARM's and SWD's hand-offs to ITEM all land in a feature.
11. **Regression gaps** (clear fix, tests). Nothing exercises `ApplyRepairKit`'s unequip (F1, in and out of combat), `ClearLowLevelWeapons` on a merchant's inventory, a merchant's stock level (-1 to +2), the reward path (F3: a scripted run of the reward code on a level-scaled reward would document that it stays inert), a secondary weapon's bonus count (F2); `GMTest_item12` asserts neither the resistance gain (read in the same frame) nor that the grindstone's armor penetration reaches the damage formula; `GMTest_item10` covers only the running difficulty. Fix: scripted checks for each in `GMTest_item*`, the buff's effect read a frame later (a second exec call, as other tests do). **Fixed** (5.x-GM `db879f91`): in the regression, the master tools' unequip condition (`GMTest_item11`), a spawned merchant's stock levels and restock clearing with bolts kept (`GMTest_item02_merchant`), the reward path through `theGame.GiveReward` (`GMTest_item02_reward`), a secondary weapon's bonus count (`GMTest_item06`), the Armorer's Table's resistance gain asserted in the regression's next call (`GMTest_item12_after` in `gmtest_panel()`); as exec checks, the unequip in the inventory menu in and out of combat (`gmtest_item11_unequip_prep`, `gmtest_item11_unequip`) and the restock on talking (`gmtest_item02_restock`, `_end`). Regression 569 passed, 0 failed in each tree. Left as open checks: the grindstone's armor penetration in a real hit (ITEM-12), the other difficulties (ITEM-10).
12. **Small differences with no effect, kept** (no action): `RepairItem` adds the master tools' level after repairing (legacy before; neither step reads the other); `W3GameParams.GetItemLevel` still fills 5.x's `baseItemLevel` (legacy dropped the parameter; only the two replaced callers pass it, and they ignore it); the restock clearing runs after `OnInteraction` (legacy's ran just before `IncreaseFunds`, which only adds money); `GetItemQualityFromName`'s minimum of 1 also reaches 5.x's transmog menu, which clamps to 1 itself; the debug command `addAutogenEquipment` is not ported (tests add items directly). A legacy quirk kept as legacy: a secondary weapon's level from its damage is 1 to 3 above its generated level, so one found at Geralt's level shows a level above his and cannot be equipped at once (the same data and formula as legacy).
13. **DI1 decided: legacy's bolt levels** (clear fix; the owner's decision, 2026-10-20). The two `DI1` blocks (`gm/items/itemLevel.ws:183-190`, a held bolt lowered by 14/10/6/4 by quality; `:272-280`, a bolt by name at least Geralt's level) are 5.x's rule, which the owner removes. Fix: delete both blocks (and the `quality` read only they use, `:128`, `:134`), update `GMTest_item01`'s bolt expectations; the ITEM-01 deviation goes. Check against legacy's list, held and by name: Tracking, Bait and Blunt 2, Target Point 5, Broadhead 10, Split 15, Explosive 20, Blunt Legendary 12, Target Point Legendary 15, Broadhead Legendary 20, Split Legendary 24, Explosive Legendary 26. **Fixed** (5.x-GM `db879f91`): both blocks and the quality read deleted, ITEM-01's deviation removed; all twelve bolts read legacy's level held and by name, verified in both trees ([ITEM-01](#item-01-item-level-from-stats), slice A).

**Doc corrections made with the audit:** F6 to F10, the attribution of F1's unit, and the owner's decisions of 2026-10-20 (DI1, DI2, the restock, the confirmed calls; ITEM-11's deviations recorded, ITEM-01's made temporary): this page (unit-list status, every **Open checks** row, ITEM-02's reward note, ITEM-06's port form, ITEM-12's verification and classification, the port order, the LOOT hand-off), [README.md](README.md) (the status table, the ITEM paragraph, the owner's list, the index row, the save-impact list), [attribution.csv](attribution.csv) (`CR4InventoryMenu.UnequipItem` to ITEM-11) and the generated [coverage.md](coverage.md).

**Not reviewed:** the translations' wording beyond legacy's rows; the test functions' internals beyond what they report; NG+ in game (the policy: not tested); binary files (ITEM has none).

**Suggested fix slices** (verified in game in one tree, since no skill is involved, plus the regression in both):

- **A, scripts and tests** (`gm/items/itemLevel.ws`, `repair.ws`, `itemGeneration.ws`, `itemBonuses.ws`, `repairObjects.ws`, `gm/swords/iris.ws`, `gm/tests/gmTestsItem.ws`): F13 (DI1: the bolt blocks deleted), F1, F5 and F11 in one slice. **Done** (5.x-GM `db879f91`, 2026-10-20), verified in both trees.
- **B, F2** (`gm/items/itemBonuses.ws`, `itemGeneration.ws`, `gm/tests/gmTestsItem.ws`): legacy's bonus level, as the owner decided. **Done** (5.x-GM `2a8cfc7c`, 2026-10-20), verified in both trees.
- **Docs**: F6 to F10 done (2026-10-20); with A, ITEM-01's, ITEM-02's, ITEM-06's, ITEM-11's and ITEM-12's entries; F3's outcome in DI2 and ITEM-02.

#### Audit close-out

Closed 2026-10-20: every finding is fixed, recorded or decided by the owner. Fixed and verified in both trees: F1, F5, F11 and F13 (5.x-GM `db879f91`; F13 is the owner's DI1 decision), F2 (5.x-GM `2a8cfc7c`: the owner's decision, legacy's rule: the random bonuses count the level the item was given at generation, so level-scaled axes, clubs and maces no longer repeat them one 10-level step early; seen in the test, a `W_Axe01` given 19 and reading 21 rolls two bonuses, not three). Recorded: F6 to F10 (doc corrections made with the audit), F12 (no action). Decided by the owner (2026-10-20): F3 (DI2 accepted as it is: rewards get the found-item level, as in legacy; shown by `GMTest_item02_reward`), F4 (legacy's restock behaviour stays; the auditor's observation: no restock ever removes bolts, in legacy or the port, since bolts carry `WeaponTab`, not `Weapon`; shown by `GMTest_item02_merchant` and the restock on talking). Checks at close: regression 569 passed, 0 failed in each tree (plus the panel's and `GMTest_item12_after`'s checks); `check_modsigns.py` 0 unmarked (275 bodies); `deviations.py --check` current (92; 13 unconfirmed). Deviations: ITEM-01's temporary bolt deviation and ITEM-06's bonus-level deviation ended; ITEM-11's quest lock on the forced unequip confirmed by the owner (2026-10-20); ITEM-11's unsold master kits stay, confirmed, temporary until CRAFT and LOOT; no ITEM deviation is left unconfirmed (`python tools/deviations.py --unconfirmed`). No owner decision is left open. What stays open after the sign-off: the open checks listed in the entries (among them real kit, table and grindstone use, a merchant met in play, a real quest's reward, an axe looted or bought in play, the bolts and tooltips on screen, a standalone start, NG+); the master kits' shops (CRAFT, LOOT). **Signed off** by the project owner, 2026-10-20 (ITEM-01 to ITEM-12).

---

### Dependencies on other areas

- **Done areas ITEM builds on:** ARM and SWD (the item entries and their generators; ITEM's fields join their entries: one entry per item), DMG (the durability penalty's two callers, resistances and armor penetration), ENCH-06 (Preservation), ENCH-17 (the item tooltip).
- **Areas ITEM waits for or shares with:** XBOW (bolt and crossbow levels), CRAFT and LOOT (where kits are sold, dismantle kits), ECON (prices, repair prices), WGT (weights), UI (the tooltip and character panel beyond ITEM-12's line), XP (the debug level reset).

### Hand-offs received

Every item other areas handed to ITEM, and where it lands:

| From | Item | ITEM |
|---|---|---|
| SWD-01 deviation (until ITEM) | The level a sword shows and needs is 5.x's `GetItemLevel` | ITEM-01 (ends it) |
| ARM-01 (hand-off; no deviation recorded) | Item level code, the armor's level shown | ITEM-01, ITEM-02 |
| SWD-01 deviation (until ITEM) | The level-generation tags legacy removed or added (`AutogenForceLevel`, `AutogenUseLevelRange`; Damien's sword's `Autogen`) | ITEM-03, ITEM-04 (ends it) |
| ARM-01 (hand-off) | `item_level_min/max`, `Autogen*` tags on armor | ITEM-03 |
| ARM-01 deviation (until ITEM) | Armor legacy moved to armor by level: Ofir armor, the vampire armor, Yoana's armor, the standalone gear | ITEM-04, ITEM-05 (ends it) |
| SWD-01 deviation (until ITEM) | Swords legacy moved to damage by level: the standalone swords, Ofir Sabre 2, the Iron Poker, the laundry stick, the `q702` vampire sword, the `mq1058` Feline sword, NG+'s crafted Burning Rose sword | ITEM-04, ITEM-05 (ends it) |
| SWD-06 deviations (until ITEM, two) | Iris's fixed 363 damage; NG+ replacing Iris with `NGP Olgierd Sabre` | ITEM-04 (ends both) |
| SWD (owner's decision, 2026-10-19) | The standalone starting armor, 32 units | ITEM-05 |
| SWD-02, ARM-01 deviations (until ITEM) | `DoNotEnhance` kept where legacy removed it (10 swords, 42 armor pieces) | ITEM-08 (ends both) |
| SWD, ARM, ENCH, DMG (hand-offs) | Random enhancements by level and quality (`AddRandomEnhancementToItem`, `AddQualityAbilityToItem`, `InitWeaponAbilities`, `GetRandomCommonWeaponAbility`, the callers) | ITEM-06 |
| STAM (hand-off) | Stamina regen removed from random bonuses (`InitPantsAbilities`, `InitBootsAbilities`, `MA_StaminaRegeneration`) | ITEM-06, ITEM-07 |
| DMG (hand-off) | Random item modifiers (`def_item_quality.xml` `MA_*`) | ITEM-07 |
| ARM-01 (hand-off) | Armor `quality` | ITEM-09 |
| DMG-09, ARM, SWD (hand-offs) | Durability (`GetDurabilityMultiplier`, the constants) | ITEM-10 |
| SWD-03 (attributed there, ported) | Torlara's and Torzirael's indestructibility removed | ITEM-10 (recorded; nothing left to port) |
| ARM, SWD (hand-offs) | The Armorer's Table buff (`AddRepairObjectBuff`, changelist 857), the grindstone buff (858) | ITEM-12 |
| ENCH-06 (dependency, open check) | The Armorer's Table and grindstone buffs Preservation keeps | ITEM-12 |
| ARM, SWD (hand-offs to CRAFT) | Mastercrafted kits | ITEM-11 takes the kits and their effect; their shops stay CRAFT's (DI6) |
| feature-mapping (roadmap) | The `ITEM` area: other items | this file |

### Hand-off to other areas

| Area | Changes |
|---|---|
| CRAFT | The two dismantle kits (`gear_dismantle_kit_1`, `alchemy_dismantle_kit_1`, their abilities and strings 2110992330–2110992333), repair kit schematics, where master kits are sold (`AddMasterArmorerItems`, its call in `scene_functions.ws`, Yoana's store) |
| LOOT | The standalone starts' inventories (`StandaloneEp1_1`, `StandaloneEp2_1`); the master kits in the shops' loot (`def_loot_shops.xml`, both folders: `_store__Hattori_Master_Blacksmith`, `_store__Master_Armorsmith_Yoana` in the base game, `_store__LW_DLC_EnchanterMaster` in Hearts of Stone, `_EP2_store_archmaster` in Blood and Wine) |
| ECON | Item and kit prices, `mod_repair`, `daysToIncreaseFunds`, merchants' funds reset below 100 (`W3MerchantNPC.OnSpawned`), restock funds (`OnInteraction`) |
| WGT | Kit weights (`def_item_misc.xml` repair kit abilities included) |
| XBOW | The bolt level list's fix (`Blunt Bolt Legendary` 5 → 12), bolt quality changes |
| AI | Quality and damage changes of NPC and secondary weapons (`def_item_weapons_secondary.xml`, `def_item_npcweapons.xml`), the Caretaker's shovel items |
| XP | The debug level reset (`fb1`, `fb2`, `fb3_internal`, `resetLevels`, `resetLevels_internal`, `cleanupInv`, `SetGeraltLevel`, `resetme`) |
| FIX | The generic merchants fix by Wolfmark in `W3MerchantNPC.OnSpawned` (changelist 37) |
| ALCH, FOOD | Pheromone potions' quality; the Balisse fruit fix (`BalisseFruitTempFix`), drinks' quality abilities |
| EFX | The Places of Power's enhanced sign effects (changelist 859) |
| UI | Recipe and schematic tooltip layout (`GetSchematicBookText`, `GetAlchemyBookText`) |

### Save impact

None for a new playthrough. What is stored on an owned item stays as it was: its generated level (per-level abilities), its random bonuses and the `ItemQualityModified` flag; so items received before ITEM-02, ITEM-06 and ITEM-08 keep 5.x's level and bonuses, and an item ITEM-04 moves to level scaling that was received with fixed damage (Iris in a save made before) loses the fixed value and has no level until obtained again (`reacquire items`). Values read from the definitions (the item level, the bonus values, quality, durability, the buffs) apply to owned items at once. Adding or removing the mod mid-playthrough is not supported ([save compatibility](../feature-mapping.md#save-compatibility)); as facts: after removing the mod, the level-scaled Iris and the other ITEM-04 items keep only their per-level damage or armor, master kits become unknown items, and armor rolled with legacy's bonus lists keeps them.

### Area decisions

Decided by the owner on 2026-10-19; DI1 on 2026-10-20. Legacy behaviour first applies to ITEM-03 to ITEM-09 and ITEM-11 (5.x did not change them).

| # | Question | Decision |
|---|---|---|
| DI1 | Bolt levels in legacy's level code (ITEM-01): (a) legacy's functions with 5.x's bolt lines kept; (b) legacy's functions as they are (bolts by the name list only) | (b), legacy's bolt levels (owner, 2026-10-20: 5.x's quality-based bolt rule is removed, "an important balance point"). Done with the [audit](#item-audit-2026-10-20)'s fix slice A (F13, 5.x-GM `db879f91`) |
| DI2 | Quest reward level (ITEM-02) | Legacy: exactly Geralt's level (owner, 2026-10-19). The rule never takes effect, in legacy too: a reward's level is set when it enters the inventory, so rewards get the found-item level (Geralt's level -1 to +1); accepted as it is, no code change (owner, 2026-10-20; [audit](#item-audit-2026-10-20) F3) |
| DI3 | Armorer's Table and grindstone duration (ITEM-12) | Legacy: 30 minutes (owner, 2026-10-19) |
| DI4 | 5.x's Accessibility option "Disable item durability" (ITEM-10) | Stays available (owner, 2026-10-19) |
| DI5 | Random bonuses on 5.x's new relic armor (Dol Blathanna, White Tiger, Scarlet Crest; ITEM-06) | One random resistance on the chest piece, like legacy's relic armor (owner, 2026-10-19) |
| DI6 | The boundary | ITEM takes the repair and master kits and their effect; where they are sold stays with CRAFT and LOOT (owner, 2026-10-19) |

Also decided (owner, 2026-10-19):

- **Stacked random bonuses (ITEM-06):** ported as legacy (a level 30 magical sword can roll its crit chance bonus four times, 20 to 40%). How it played in legacy is [to test in legacy](../open-questions.md#to-test-in-legacy-ghost-mode); its balance is for the balance pass.
- **Blood and Wine gear at Geralt's level (ITEM-03):** confirmed as legacy intended: found or bought early, Blood and Wine's guard, knight, Toussaint and Thief gear has Geralt's level.

Also decided (owner, 2026-10-20, with the [audit](#item-audit-2026-10-20)):

- **Merchant restock (ITEM-02):** legacy's behaviour stays: a restock drops the weapons more than 3 levels below Geralt (`ClearLowLevelWeapons`). As a fact (F4): bolts carry `WeaponTab`, not the `Weapon` tag the function selects, in legacy as in the port, so no restock removes bolts.
- **F2 (ITEM-06):** legacy's rule: the random bonuses count the level the item was given at generation (replaces the porter's call, confirmed earlier the same day, that they read the item's own level). Done (5.x-GM `2a8cfc7c`).
- **Porter's calls confirmed:** the master kits' forced unequip respects 5.x's quest lock (ITEM-11's deviation, F1); the tournament gloves' misspelt `DoNotEnhancem` removed (ITEM-08); the master kits unsold until CRAFT and LOOT (ITEM-11's deviation); the two tool fixes made with the port: `check_modsigns.py` aligning code lines with names kept, and `gen_arm_items.py`'s ability pattern skipping self-closing abilities (outputs unchanged).

### Port order

All eight slices are ported (2026-10-19), each verified in both trees (the regression in both; ITEM touches no skill):

| # | Slice | Ends |
|---|---|---|
| 1 | ITEM-01, the level formula (scripts), with DI1 | SWD-01's deviation on the level a sword shows and needs (and the armor's unrecorded equivalent) |
| 2 | The item tooling: ITEM's fields joined to `gen_arm_items.py`, `gen_swd_items.py` and `gen_arm_km.py` entries, a `gen_item.py` for the other items, `--verify` over ITEM's fields; with ITEM-02 (level generation, DI2) and ITEM-03 (tags and ranges) | SWD-01's level-tag deviation |
| 3 | ITEM-04 and ITEM-05, the items moved to level scaling and the standalone gear | ARM-01's level-scaled armor deviation, SWD-01's level-scaled swords deviation, SWD-06's two Iris deviations; SWD's standalone armor hand-off |
| 4 | ITEM-06 and ITEM-07, the random bonus rules and values (DI5) | STAM's, DMG's and ENCH's hand-offs |
| 5 | ITEM-08 and ITEM-09, `DoNotEnhance` removed and armor quality | SWD-02's and ARM-01's `DoNotEnhance` deviations |
| 6 | ITEM-10, durability (DI4) | DMG-09's hand-off |
| 7 | ITEM-11, repair and master kits (DI6) | ARM's and SWD's kit hand-offs (the kits' effect) |
| 8 | ITEM-12, the Armorer's Table and grindstone (DI3) | ARM's `AddRepairObjectBuff` hand-off (ENCH-06's Armorer's Table check stays open) |
