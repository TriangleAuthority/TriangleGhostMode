# LOOT: merchants' stock, containers, monster drops and quest rewards

Where Geralt gets things: what each merchant sells (smiths, armorers, alchemists, herbalists, innkeepers, general traders and the special merchants), what chests, corpses, ore veins and other containers hold, what monsters drop, what quests give, which recipes and schematics are gated by Geralt's level, and what the standalone expansion starts give. Ghost Mode reworked all of it for scarcity (P6, "Loot and money are scarce"): "Free ingredients and upgrades were removed from easily accessible places. Loot tables are area-dependent, so mines have coal and ore, rich houses have silver and jewelry, etc. Merchants no longer sell monster parts" (changelist 913–919); dismantle kits at armorers, blacksmiths, alchemists and herbalists (864–865, 688–690); "You can now buy all the alchemy recipes and rare ingredients (like doppler or succubus mutagen) from master alchemist after completing his quest" (685–686); master kits at Yoana, Hattori, the enchanter and the grandmaster (611, 633); "Missing lore books ... were added" (868–869); "Food and drinks reworked in terms of quality and availability in loot and shops" (841); bugfix 145 (the Nekker Warrior decoction recipe in random loot). Sources: those lines, what ARM, ENCH, SWD, ITEM and ALCH left to LOOT, legacy's design notes (`design-docs/loot-*.xml`, `crafting.ods` on `legacy-GM`), and the data, which has much more than the changelist (the level gates, the binary loot edits, the quest reward swaps, the standalone inventories).

What crafting needs (schematics, recipes, ingredients, dismantling, the kits themselves) is [CRAFT](craft.md); the two areas were mapped together and share the master kits (LOOT-04 with CRAFT-10).

**What 5.x did in this area** (from `vanilla-5.x`). Nothing to the loot lists legacy changed: every shop, container, living-world, monster and quest list legacy touched is 1.32's in 5.x (5.x rewrote the opening tag of all 322 base-game quest lists: `respawn_time="0"` added, `chance="100"` dropped, `player_level_max` 100 → 0, i.e. no cap; 17 of them are lists legacy changed), and so are the merchants' and monsters' loot parameters in the binary entity files. 5.x added: new lists for its new gear (`_unique_loot_dol_blathanna`, `_unique_loot_chinese_and_korean`, `top_notch_swords`, `nilfgaardian_armor_netflix`, `nilfgaardian_helmet`, `candle_lantern` in `def_loot_unique.xml`, placed by the world or quests), the free Wolf school DLC's treasure hunt lists (`dlc10_def_loot_quests.xml`, 23 lists of the Wolf schematics), a Blood and Wine and a Hearts of Stone quest list; platform rewards (`rewardsmap.csv`: Dol Blathanna, White Tiger, Vixen, Scarlet Crest, horse gear, given to linked or owned accounts); the Netflix schematics as the reward of its new quest `mq1060`; raised gold on a few quest rewards (ECON). Containers: an Accessibility option to loot corpses without the loot window and merge nearby corpses (`W3Container`), loot from horseback, a grouped loot window and a loot feed (UI).

**How legacy Ghost Mode implements it.** Data: the loot lists (`def_loot_shops.xml`, `def_loot_containers.xml`, `def_loot_livingworld.xml` and Blood and Wine's `def_loot_living_world.xml`, `def_loot_monsters.xml`, `def_loot_quests.xml`, `def_loot_unique.xml`, with the Hearts of Stone and Blood and Wine counterparts), all with NG+ copies; 16 new merchant lists; the `<items>` of 78 quest rewards (`rewards.xml`, base and three DLCs). Binary: the `CR4LootParam` of 39 merchant entities (two new lists each) and of about 160 monster and quest entities (the lesser mutagen add-on removed), the inventories of 16 quest and enemy entities. Scripts: the standalone starts' inventories (`StandaloneEp1_1`, `StandaloneEp2_1` and their timers), the Balisse fruit fix (`BalisseFruitTempFix`, `W3RefillableContainer.Refill`), Yoana's master stock (`AddMasterArmorerItems`, CRAFT-10).

Unit lists: [attribution.csv](attribution.csv): 1,472 units carry a LOOT feature (13 script units, 663 XML units and their 585 NG+ copies, 211 binary files); 14 of them are shared with other features. The rewards' experience, level and gold are XP's and ECON's, the binary files' other properties (enemy stats, abilities) AI's and DIFF's.

**Status:** every feature ported and verified in game, the binary edits of LOOT-02, LOOT-06 and LOOT-07 included. Signed off by the owner (2026-10-23, with CRAFT).

**How it is built:** `tools/gen_loot.py` writes whole-file overrides of 23 loot and reward files (`--verify`) and 211 entity files, each 5.x's with exactly legacy's loot edits (applied with `cr2w_patch.py`, `--verify`). Scripts: `gm/craft/masterKits.ws` (LOOT-04 with CRAFT-10), `gm/loot/balisse.ws` (LOOT-05), `gm/loot/standalone.ws` (LOOT-09). Tests: `tests/gmTestsLoot.ws` (`gmtest_loot()`, run once in a launch of its own, outside the regression: rolling lists into a spawned merchant with `AddItemsFromLootDefinition` repeatedly on one inventory crashes 5.x's engine after a varying number of rolls, while a merchant's normal restock, a different path, held 240 restocks in one launch, [game-automation.md](../game-automation.md#setting-up-geralt-and-the-world); `gmtest_loot07`, `gmtest_loot09` by hand), `tests/gmTestsPlay.ws` (real NPCs, shops and kills). Shops were tested on merchants spawned from their entity files, each shop opened as the dialogue's `ShowMeGoods` does (the restock rolls the entity's lists), items bought through the shop menu's buy event; containers in an area not loaded before; monster drops by scripted kills through the death path; rewards through `GiveReward` (the dialogue's function).

## Scope

**LOOT covers** every loot list Ghost Mode changed or added (shops, containers, living world, monsters, quests, unique), the merchants' and monsters' loot parameters and the quest NPCs' inventories in binary entities, the item part of quest rewards, the recipe and schematic level gates, the special merchants' stock (with CRAFT-10 for the master kits), the lore books and notes placed, the Balisse fruit fix, and the standalone starts' inventories.

**Not LOOT** (confirmed by the owner with DT9, 2026-10-21):

| Subject | Area | Why |
|---|---|---|
| What the sold and found items are and need (schematics, recipes, ingredients, kits, dismantling) | CRAFT | |
| Prices, merchants' funds, price factors, the rewards' gold, the monster-hunt reward haggling, the Hearts of Stone tax quest's sum (`mq6003_taxes.w2phase`: 35,000 → 10,000 crowns) and the other quest money condition | ECON | Money |
| The rewards' experience and quest levels | XP | |
| Food and drink items, their quality and the cooking recipes | FOOD | LOOT carries the food entries of the lists it ports; FOOD decides the items |
| Trophies no longer auto-equipped on looting (`W3ActorRemains.OnItemTaken`, `FinalizeLooting`) | TRPH | Changelist 911, the Trophies section |
| Enemy stats, abilities and levels in the binary entities that also carry loot edits | AI, DIFF | One file, two areas |
| The weapons NPCs carry and their scabbards (`bound_items`) | AI | as SWD |
| Loot window, loot feed, the item tooltips | UI | |

## Changes at a glance

### What Ghost Mode changed

| # | Feature | Vanilla 1.32 | Legacy GM | Units (main) |
|---|---|---|---|---|
| LOOT-01 | Merchants' stock | Merchants sell monster parts; herbalists sell a few herbs | No monster parts (81 entries removed from 59 lists); kits at the trades (dismantle kits at 31 lists, repair kits); herbalists and alchemists stock the alchemy bases and the new alcohol recipes, innkeepers and butchers cooking recipes and more food; stock sizes and quantities reworked | 162 lists of `def_loot_shops.xml` (3 folders) |
| LOOT-02 | Runes, glyphs and schematics as separate merchant lists | Runes and schematics mixed into the smiths' and armorers' regional lists (44–67 items rolled) | 16 new lists (runes, glyphs, schematics by region), the trade lists cut to 10–15 items; 39 merchant entities get the two new lists | 16 new lists, 8 changed, 39 binary entities |
| LOOT-03 | Recipe and schematic level gates | Uneven gates | Potion, oil and bomb recipes T2 from levels 8–12, T3 from 16–20; schematics from levels 2–30 by tier | entries in shop and container lists |
| LOOT-04 | Special merchants | — | The Master Alchemist sells every recipe and rare mutagens; Hattori and Yoana sell master schematics and the master kits (Yoana after her quest); the enchanter and the archmaster smith the master kits; pheromone recipes at four more herbalists | `_store__Master_Alchemist`, the master smiths' lists, `AddMasterArmorerItems` |
| LOOT-05 | Containers and world loot | Generous chests, corpses and ore; free runes and upgrades in common chests | Area-dependent lists (ore and coal in mines, valuables in rich houses), fewer materials, upgrades out of common chests, more food; the Balisse fruit fix | `def_loot_containers.xml`, the living-world lists (3 folders), `Refill`, `BalisseFruitTempFix` |
| LOOT-06 | Monster drops | A generic lesser-mutagen add-on on most monsters; generous monster parts | The add-on removed from 158 monster entities; lesser mutagens on 39 specific tables, named mutagens at 10–20%; fewer parts per kill | `def_loot_monsters.xml` (3 folders), 159 binary entities |
| LOOT-07 | Quest loot and rewards | 1.32's rewards | 78 rewards give different gear, schematics and runes (e.g. Skjall's: Skellige sword 3, its level 4 schematic and heavy boots instead of sword 2 and a leather schematic); quest chests reworked; quest NPCs carry other items | `rewards.xml` (4 folders), `def_loot_quests.xml`, `def_loot_unique.xml`, 16 binary entities |
| LOOT-08 | Lore books and notes | Unused lore books; notices and contracts not kept | Lore books placed in quest chests and rewards (Witcher Book Collection); notices, contracts and notes given with the quests that use them | reward and loot entries, `mh208_contract` |
| LOOT-09 | Standalone starts | Hearts of Stone: 40,000 crowns, piles of materials; Blood and Wine: 20,000 | Hearts of Stone 4,000 crowns, Blood and Wine 5,000; fewer mutagens, materials, bolts (20 instead of 100), kits and food; given once the inventory exists | `StandaloneEp1_1`, `StandaloneEp2_1`, 2 timers, `StandaloneEp1_2`, `StandaloneEp2_2` |

### What 5.x changed

| # | Feature | 5.x change (from code and data) |
|---|---|---|
| LOOT-01 | Merchants' stock | None |
| LOOT-02 | Merchant lists | None (the 39 entities' loot parameters are 1.32's) |
| LOOT-03 | Level gates | None |
| LOOT-04 | Special merchants | None |
| LOOT-05 | Containers | None to the lists; auto-loot and corpse merging options, loot from horseback |
| LOOT-06 | Monster drops | None (lists and entities) |
| LOOT-07 | Quest loot and rewards | the opening tag of every base-game quest list (17 of them legacy's): `respawn_time` added, `chance` removed, `player_level_max` 100 → 0 (formatting); rewards' gold raised on a few (ECON); new rewards (`mq1060`'s Netflix schematics, two small ones) and platform rewards |
| LOOT-08 | Lore books | None |
| LOOT-09 | Standalone starts | `StandaloneEp1_2` and `StandaloneEp2_2` changed (5.x's own fixes); `StandaloneEp1_1`, `StandaloneEp2_1` unchanged |

### Classification and action

| # | Feature | Class | Action |
|---|---|---|---|
| LOOT-01 | Merchants' stock | clean; conflict (port form, DT1) | Legacy's lists |
| LOOT-02 | Merchant lists | clean (lists), conflict (binary entities, QT1) | Legacy's lists and merchant edits |
| LOOT-03 | Level gates | clean | Legacy's data (DT2) |
| LOOT-04 | Special merchants | clean | Port with CRAFT-10 |
| LOOT-05 | Containers | clean | Legacy's lists; Balisse fix (DT7) |
| LOOT-06 | Monster drops | clean (lists), conflict (binary entities, QT1) | Legacy's lists and entity edits |
| LOOT-07 | Quest loot and rewards | clean, overlap (17 quest lists, formatting) | Legacy's items (DT4, DT8) |
| LOOT-08 | Lore books | clean | Port with LOOT-07 and LOOT-05 |
| LOOT-09 | Standalone starts | clean, overlap (5.x's `_2` functions) | Legacy's inventories (DT6) |

---

### LOOT-01 Merchants' stock

| | |
|---|---|
| Kind | content |
| Pillars | P6, P8 |
| 5.x class | clean (data); conflict (port form) |
| Flags | balance |
| Depends on | CRAFT-07, CRAFT-09 (the items sold), ITEM-02 (level-scaled stock, restock), ECON (prices, funds), FOOD (food items) |
| Skill trees | n/a |
| Port form | whole-file overrides of the shop files (DT1: a DLC `<loot>` list merges into vanilla's list of that name and cannot remove entries): 5.x's files with legacy's lists, `tools/gen_loot.py` (`--verify`), regular and NG+ |
| Port status | **signed off** (2026-10-23); verified (2026-10-22): a spawned White Orchard herbalist stocks the Alchemy dismantle kit, Mandrake cordial and the Mahakam spirit recipe and no monster parts; both bought in the shop |
| Open checks | a merchant met in play after a restock |
| Save impact | none for a new game; a merchant's rolled stock is saved and renews at restock |
| NG+ counterpart | applied (legacy's NG+ files), untested |

**What it does** (changelist 919, 864–865, 841): merchants no longer sell monster parts (81 entries removed from 59 lists, e.g. Water essence, Bear pelt, Elemental essence, Venom extract at herbalists); armorers and blacksmiths sell the Item dismantle kit (13 lists) and repair kits, alchemists and herbalists the Alchemy dismantle kit (18 lists), the alchemy bases (Alcohest, Dwarven spirit, Empty bottle, Mahakam spirit, Mandrake cordial) and the two alcohol recipes; innkeepers and butchers sell cooking recipes and more food; general traders and the wandering merchants sell materials by region; stock sizes and quantities reworked (e.g. Toussaint's herbalist rolls 250 items instead of 107–110). Area-dependent trade lists follow legacy's design notes (`design-docs/loot-shops.xml`: innkeepers edibles and drinks, general stores junk and common materials).

**Implementation (legacy):** 144 lists of `def_loot_shops.xml` (16 of them new) (with LOOT-02's and LOOT-04's), 3 of Hearts of Stone, 15 of Blood and Wine, regular and NG+.

**5.x:** unchanged; no override form for `<loot>` is verified (the mod.io guide's list of `on_conflict` types does not name it).

**Decisions:** legacy's lists; whole-file overrides (DT1): a DLC `<loot>` entry with a vanilla list's name adds its entries to that list, also with `on_conflict="replace"` (probed in game: vanilla's entries and quantity kept, the DLC's added), so it cannot express legacy's removals. Innkeepers and Blood and Wine's butcher sell legacy's 27 cooking recipes, whose items are FOOD-07's ([food.md](food.md#food-07-cooking)).

### LOOT-02 Runes, glyphs and schematics as separate merchant lists

| | |
|---|---|
| Kind | content |
| Pillars | P6 |
| 5.x class | clean (lists); conflict (binary entities) |
| Flags | — |
| Depends on | LOOT-01, CRAFT-01 to CRAFT-03 (the schematics), ENCH-16 (runes and glyphs) |
| Skill trees | n/a |
| Port form | the 16 new and 8 changed lists in the whole-file overrides of the shop files (DT1, `gen_loot.py`); the 39 merchants' `CR4LootParam` edited in 5.x's entity files (QT1: `gen_loot.py` derives legacy's edits and applies them with `cr2w_patch.py`, `--verify`) |
| Port status | **signed off** (2026-10-23); verified (2026-10-22): a spawned Novigrad market smith's entity file carries the five lists; at level 20 his shop stocks runes and rune and repair-kit schematics, the Novigrad rich-district armorer glyphs; a rune, a schematic and a glyph bought |
| Open checks | — |
| Save impact | none for a new game |
| NG+ counterpart | applied, untested |

**What it does:** smiths and armorers stock runes, glyphs and schematics from separate regional lists (prologue, No Man's Land, Novigrad, Skellige: `loot_include_smith_<region>_runes` and `_schematics`, `loot_include_armor_<region>_glyphs` and `_schematics`), so a merchant always rolls some of each instead of a few among 135 mixed items: e.g. a Novigrad smith rolls 10–15 of 47 trade items (1.32: 44–55 of 135), 5–10 runes of 21 and 10–15 schematics of 47. The prologue smith gets his own armor list. The Midcotts blacksmith also becomes a Master craftsman (CRAFT-01).

**Implementation (legacy):** 16 new and 8 changed lists in `def_loot_shops.xml`; `CR4LootParam` of 39 entity files (regional smiths and armorers in `gameplay/community/shops_and_craftsmen/`, the generic merchants in `living_world/dialogue/generic_merchants/entities/`, the prologue smith): `containers` + 2 names, `usedContainersMin/Max` 3 → 5. The same files lose an attack range and some cooked effects in the dump, which looks like W3Edit re-save noise (not ported).

**5.x:** the 39 entities' loot parameters are 1.32's (5.x re-saved the files only).

**Decisions:** legacy's lists; the entity edits per QT1 (each file 5.x's with exactly legacy's loot edits, including Yoana's own store list at chance 0 (as legacy, confirmed by the owner, 2026-10-21), her master stock coming from CRAFT-10's script, and the prologue smith's armor list swapped for `loot_include_armor_prologue`).

### LOOT-03 Recipe and schematic level gates

| | |
|---|---|
| Kind | content |
| Pillars | P6, P10 |
| 5.x class | clean |
| Flags | balance |
| Depends on | LOOT-01, LOOT-05 (the lists holding the entries), CRAFT-06 |
| Skill trees | n/a |
| Port form | the `player_level_min` of the entries, with their lists |
| Port status | **signed off** (2026-10-23); verified (2026-10-22): the gates hold at level 1 (the Novigrad smith's runes and most schematics absent) and open at level 20 |
| Open checks | a herbalist's recipes below and above a gate in play |
| Save impact | none |
| NG+ counterpart | applied, untested |

**What it does:** recipes and schematics appear in shops and random loot only from a level of Geralt's: potion, oil and bomb recipes of tier 2 from levels 8 to 12 (8: 47 entries, 9: 41, 10: 50, 12: 14), tier 3 from 16 to 20 (16: 34, 18: 45, 20: 57), a few tier 1 from level 4, a few left ungated (the Druid herbalist, Toussaint's herbalist); schematics from levels 2 to 30 by tier (most at 5 and 10). Not in the changelist; ALCH's hand-off and the alchemy ledger called them "L10 and L20" (the ledger is corrected); bugfix 145 puts the Nekker Warrior decoction recipe in random loot.

**Implementation (legacy):** `player_level_min` on recipe and schematic entries of 44 lists (shops and `_everywhere_recipes`, `_unique_oils`, `_everywhere_schematics`), regular and NG+.

**5.x:** unchanged.

**Decisions:** legacy's gates (DT2).

### LOOT-04 Special merchants

| | |
|---|---|
| Kind | content |
| Pillars | P6 |
| 5.x class | clean |
| Flags | — |
| Depends on | CRAFT-10 (the master kits, `AddMasterArmorerItems`), CRAFT-04 (the quest armor schematics), ITEM-11 |
| Skill trees | n/a |
| Port form | the lists with LOOT-01 (`gen_loot.py`); `GMAddMasterArmorerItems` and its call with CRAFT-10 (`gm/craft/masterKits.ws`) |
| Port status | **signed off** (2026-10-23); verified (2026-10-22, with CRAFT-10): Hattori (spawned) stocks the master weaponsmith tools; Yoana's master list (kits, the quest-armor schematics) appears after her quest's fact and is bought from; Blood and Wine's archmaster's list holds both kits (`GMTest_loot04`); the Hearts of Stone enchanter (spawned from `enchanter_01_lvl_3.w2ent`) stocks both kits, also after a restock (below) |
| Open checks | buying from the Master Alchemist after his quest in play |
| Save impact | none (expected) |
| NG+ counterpart | applied, untested |

**What it does** (changelist 685–686, 611, 633): the Master Alchemist (Skellige) sells 114 recipes (every potion, oil and bomb tier with their level gates, the pheromones), the alchemy bases and rare ingredients (Doppler, Succubus, Troll and Ancient Leshen mutagens, Cave Troll liver, Berserker pelt); Hattori sells relic sword schematics (Arbitrator, Beannshie, Black Unicorn, Harpy, Longclaw, Negotiator, Weeper, from their levels), the Item dismantle kit and the master weaponsmith tools; Yoana, after her quest, adds her master stock (armor schematics, Thyssen and the four quest armors' schematics, the master armorsmith tools); the Hearts of Stone enchanter and Blood and Wine's archmaster sell both master kits; the bear and nekker pheromone recipes are sold by the Druid herbalist, Guslar, the Oxenfurt herbalist and the Master Alchemist.

**Implementation (legacy):** `_store__Master_Alchemist`, `_store__Hattori_Master_Blacksmith`, `_store__Master_Blacksmith`, `_store__Master_Armorsmith`, `_store__Master_Armorsmith_Yoana`, `_store__LW_DLC_EnchanterMaster`, `_EP2_store_grandmaster`, `_EP2_store_archmaster`; `AddMasterArmorerItems` (fact `sq108_master_bsmith_helped`) called from `ShowMeGoods` for `sq108_blacksmith_woman`.

**5.x:** unchanged.

**Decisions:** port as legacy (DT5). Yoana's master list is added by CRAFT-10's script as one roll's stock, topped up at each opening rather than queued again, so her stock no longer grows with each visit ([CRAFT-10's deviation](craft.md#craft-10-master-kits-at-the-master-craftsmen), owner, 2026-10-24).

**Long lists** (checked in game): a merchant's restock stocks every entry of its list it may sell at Geralt's level, however long the list: the Hearts of Stone enchanter 120 kinds with both master kits at the end of his list, the Master Alchemist 185 of his 276 entries, the Whitebridge herbalist (`_store__Oxenfurt_Herbalist`) 79 of 94 (the rest level-gated or recipes Geralt knows). Only a list queued with `AddItemsFromLootDefinition` is cut at 62 kinds (the test roll; the one queued list a shop uses, Yoana's master list, has 18 entries). The calls and the balancing are native in 1.32 and 5.x alike, so the scripts hold no cap. Legacy's list order is kept.

### LOOT-05 Containers and world loot

| | |
|---|---|
| Kind | content, fix |
| Pillars | P6 |
| 5.x class | clean |
| Flags | balance |
| Depends on | CRAFT-07 (materials), FOOD (food), LOOT-03 |
| Skill trees | n/a |
| Port form | the lists in whole-file overrides (`gen_loot.py`); `gm/loot/balisse.ws`: `@addMethod W3MerchantNPC.GMBalisseFruitFix` (legacy's `BalisseFruitTempFix`) with wrappers of `OnSpawned` and `OnInteraction` (at a restock, as ITEM-02's), `@replaceMethod W3RefillableContainer.Refill` (the Balisse branch) |
| Port status | **signed off** (2026-10-23); verified (2026-10-22): containers in an area loaded for the first time (the bandit camp in White Orchard) rolled from legacy's lists (e.g. Glass, which only legacy's container lists hold); the herbalist keeps 10 Balisse fruit; the mine's and common chest's lists rolled (`GMTest_loot05`) |
| Open checks | does 5.x still have the Balisse fruit bug; a mine's and a rich house's chests in play |
| Save impact | none for a new game; a container keeps what it rolled until it renews |
| NG+ counterpart | applied, untested |

**What it does** (changelist 915–918): containers hold what their place suggests and less of it: 259 lists changed (base and Blood and Wine containers and living-world lists), about 1,900 entries removed and 3,400 added; e.g. Toussaint's ore lists give 1–3 minerals instead of 3–8, a point of interest's reward 50–100 florens instead of 200–300, bandit corpses food and a razor instead of crafting materials; free runes and glyphs leave the common chests (`_generic chest_everywhere`); `_everywhere_recipes` and `_everywhere_schematics` get LOOT-03's gates. The Balisse fruit fix: Balisse fruit bushes refill and always hold a fruit, and herbalists keep 10 fruit in stock.

**Implementation (legacy):** 87 lists of `def_loot_containers.xml`, 47 of `def_loot_livingworld.xml`, Blood and Wine's 72 and 53, regular and NG+; `W3RefillableContainer.Refill`, `W3MerchantNPC.BalisseFruitTempFix` (called from `OnSpawned` and `OnInteraction`; ITEM's note had sent it to FOOD).

**5.x:** the lists unchanged; `Refill` unchanged in substance; the auto-loot and merge options do not touch the lists.

**Decisions:** legacy's lists; the Balisse fix ported without checking whether 5.x still has the bug (DT7; confirmed by the owner, 2026-10-21).

### LOOT-06 Monster drops

| | |
|---|---|
| Kind | content |
| Pillars | P6 |
| 5.x class | clean (lists); conflict (binary entities) |
| Flags | balance |
| Depends on | ALCH (mutagens and decoctions), CRAFT-08 (named mutagens dismantled into lesser ones) |
| Skill trees | n/a |
| Port form | the lists in the whole-file overrides of the monster loot files (DT1, `gen_loot.py`); the 159 entities' `CR4LootParam` edited in 5.x's files (QT1, as LOOT-02) |
| Port status | **signed off** (2026-10-23); verified (2026-10-22): 12 nekkers spawned from the patched entity file and killed through the death path dropped one part each (bone, brain, liver, tongue, claw, heart) and no lesser mutagen |
| Open checks | kills of other monster types in play |
| Save impact | none for a new game; a monster's loot is rolled when it dies |
| NG+ counterpart | applied, untested |

**What it does:** monsters drop fewer parts and fewer generic mutagens: the lesser-mutagen add-on list (`_monster_add__Mutagens_lesser`) is removed from 158 monster and quest-monster entities (with the Ice Giant's own list on the ice elemental, and the Endriaga list on the spectral spiders); lesser mutagens are added instead to 39 specific monster tables, named mutagens get 10–20% drop chances where they were unset (Wraith, Nightwraith, Noonwraith 10%, Protofleder 20%; Werewolf 25 → 10%); monster tables roll fewer items (e.g. a Garkain 1–2 instead of 4–6) with higher odds for their signature parts; nests drop greater mutagens. Combined with CRAFT-08 (named mutagens dismantle into lesser ones), lesser mutagens come mostly from specific monsters and from dismantling.

**Implementation (legacy):** 85 lists of `def_loot_monsters.xml`, 5 of Hearts of Stone, 37 of Blood and Wine, regular and NG+; `CR4LootParam` of 159 binary entities (`characters/npc_entities/monsters/`, quest monsters, Blood and Wine's and Hearts of Stone's monsters); the inventories of Blood and Wine's enemy templates (`living_world/enemy_templates`, lesser mutagens removed).

**5.x:** unchanged, lists and entities.

**Decisions:** legacy's lists; the entities per QT1: the add-on removed from 158 entities (with `usedContainersMin/Max` where legacy removed them), the Ice Giant list from the ice elemental, and the spectral spiders' loot parameter left with no list (`overrideInherited`, 0 containers; confirmed by the owner, 2026-10-21), all as legacy.

### LOOT-07 Quest loot and rewards

| | |
|---|---|
| Kind | content |
| Pillars | P6 |
| 5.x class | clean, overlap (17 quest lists) |
| Flags | balance |
| Depends on | ITEM-02 (reward items' level, inert as in legacy), SWD, ARM (the items given), XP and ECON (the same rewards' experience and gold) |
| Skill trees | n/a |
| Port form | rewards: whole-file overrides of the four `rewards.xml` files legacy changed, 5.x's rewards with legacy's `<items>` (their experience and level legacy's since XP's slice X2, which adds the free DLCs' `dlc12` and `dlc15` files; gold legacy's since ECON's slice E4, ECON-10); quest lists in whole-file overrides with 5.x's list attributes and only the ones legacy changed (its quantity) taken from legacy (DT8); all by `gen_loot.py`; the 16 quest NPCs' inventories edited in 5.x's entity files (QT1, as LOOT-02) |
| Port status | **signed off** (2026-10-23); verified (2026-10-22): Avallac'h's and Yennefer's notes roll legacy's quantity with 5.x's list attributes (`GMTest_loot07_lists`); Tauler's killer's reward and the Undvik giant's give legacy's items (`gmtest_loot07`, `GiveReward` as the dialogue's reward function); quest NPCs spawned from their patched files carry legacy's items (the mq1046 scavenger's heavy boots, the border troll's single Fox pelt) |
| Open checks | a Wild Hunt warrior's sword in the Kaer Morhen battle |
| Save impact | none for a new game; a reward is given once |
| NG+ counterpart | applied to the quest lists; rewards have no NG+ copy |

**What it does:** quests give other gear, schematics and runes, usually smaller or later: e.g. Skjall's reward gives Skellige sword 3, the Skellige sword 4 schematic and heavy boots (1.32: Skellige sword 2 and a leather schematic); Tauler's killer gets heavy boots, heavy gloves and a Rune of Triglav (1.32: a silver sword schematic and a lesser rune); the Undvik giant's reward Arainne instead of Silver sword 3; Eredin's a greater Aard glyph instead of a lesser one; the Cleaver's reward a Silver sword 8 and a medium armor. Quest chests change (e.g. Skjall's body holds the Longclaw schematic). Quest NPCs carry other items (the Fairy Tale wolf a greater mutagen, a scavenger heavy boots).

**Implementation (legacy):** the `<items>` of 78 rewards (`rewards.xml`: 66 base, 10 Blood and Wine, 1 Hearts of Stone, 1 free DLC); 17 lists of `def_loot_quests.xml`, 5 of Hearts of Stone, 3 of Blood and Wine, 11 of `def_loot_unique.xml`, regular and NG+; `CInventoryInitializerUniform`, `CInventoryDefinitionEntry` of 16 quest entities.

**5.x:** the 17 quest lists legacy changed (with the other 305 base-game quest lists) got `respawn_time="0"`, lost `chance="100"` and have `player_level_max` 0 instead of 100 on the list (formatting, DT8; on the 13 lists whose quantity legacy changed, the port takes legacy's quantity into 5.x's tag); new rewards and lists for 5.x's content (DT3, QT2).

**Decisions:** legacy's items (DT4), 5.x's list attributes (DT8). Legacy's data names a few items no definition has, in legacy too (`Skellige sword 3` in `q105_4_info_witches`, `Heavy Boots 6 schematic` in `mq2008_reward_in_chest`, `Crossbow 1 q1` in a container list; `Heavy boots 3 schematic` differs from the item's name in case): kept as legacy has them (they give nothing, as in legacy; confirmed by the owner, 2026-10-21). Four quest monsters (the Blood and Wine katakan-type entities) keep the inventory slot whose item legacy removed, empty, as legacy's files have it (confirmed by the owner, 2026-10-21).
- **Deviation:** every loot list legacy changed keeps 5.x's opening tag, with only the attributes legacy changed against 1.32 taken from legacy (`gen_loot.py`, `head_merged`): on the 17 quest lists 5.x's `respawn_time="0"`, no `chance="100"` and `player_level_max` 0 stay, with legacy's quantity where legacy changed it; DT8 named the 17 quest lists, the rule covers every list ([audit](craft.md#craft-and-loot-audit-2026-10-22) F4; porter's call, confirmed by the owner, 2026-10-23).

### LOOT-08 Lore books and notes

| | |
|---|---|
| Kind | content |
| Pillars | P8 |
| 5.x class | clean |
| Flags | — |
| Depends on | LOOT-07, LOOT-05 (the entries' lists) |
| Skill trees | n/a |
| Port form | with their lists and rewards; `mh208_contract` as a new item entry |
| Port status | **signed off** (2026-10-23); verified (2026-10-22): Urskar's journals with the Undvik giant's reward (`gmtest_loot07`) |
| Open checks | a lore book found in play |
| Save impact | none |
| NG+ counterpart | applied, untested |

**What it does** (changelist 868–869): lore books the game defines but never places (Witcher Book Collection by KasparsBITELV) are placed in quest chests and given by rewards (e.g. Urskar's journals with Folan's and Vigi's rescue, the oneiromancy treatise with the dreamer's quest); notices, contracts and notes are given with the quests that use them (the fistfight notices, the monster hunt contracts, Blood and Wine's points-of-interest notes). A new contract item `mh208_contract` is defined but placed by no list in the data.

**Implementation (legacy):** entries in 61 reward and loot units (`lore_*`, `*_note`, `*_notice`, `*_contract`), `mh208_contract` in `def_item_notices.xml`.

**5.x:** unchanged.

**Decisions:** port as legacy.

### LOOT-09 Standalone starts

| | |
|---|---|
| Kind | content, fix |
| Pillars | P6 |
| 5.x class | clean; overlap (`StandaloneEp1_2`, `StandaloneEp2_2`) |
| Flags | — |
| Depends on | ITEM-05 (the standalone gear, ported), ALCH (mutagens), XBOW (bolts) |
| Skill trees | n/a |
| Port form | `gm/loot/standalone.ws`: `@replaceMethod` of `StandaloneEp1_1`, `StandaloneEp1_2`, `StandaloneEp2_1`, `StandaloneEp2_2` (5.x's bodies with legacy's changes merged three-way, every change marked), `@addMethod` timers `GMGiveStandaloneEp1Items`, `GMGiveStandaloneEp2Items`, a wrapper of `OnSpawned` |
| Port status | **signed off** (2026-10-23); verified (2026-10-22): `gmtest_loot09(1)` and `(2)` on the test save (reloaded after each): Hearts of Stone 4,000 crowns, 20 split bolts, 5 dumplings, 1 greater mutagen, no bear pelt; Blood and Wine 5,000 crowns, 1 greater and 2 lesser mutagens |
| Open checks | a standalone start from the main menu |
| Save impact | none (the inventory is given once, fact-guarded) |
| NG+ counterpart | none (scripts) |

**What it does:** the Hearts of Stone and Blood and Wine standalone starts (started from the main menu) get smaller inventories: 4,000 crowns (Hearts of Stone; 1.32: 40,000) and 5,000 (Blood and Wine; 20,000); 1 greater and 2 regular mutagens of each colour (and 2 lesser in Blood and Wine) instead of 4 and more; fewer hides and ingots (some removed), 20 of each bolt instead of 100, 3 + 2 repair kits instead of 5 + 3, less food (5 dumplings instead of 44). The inventory is given by a timer once the inventory exists, behind the facts `standalone_ep1_inv` and `standalone_ep2_inv`, and the start facts are added only once.

**Implementation (legacy):** `W3PlayerWitcher.StandaloneEp1_1`, `StandaloneEp2_1`, `GiveStandAloneEP1Items`, `GiveStandAloneEP2Items` (new timers), `StandaloneEp1_2`, `StandaloneEp2_2`, `OnSpawned`.

**5.x:** `StandaloneEp1_1` and `StandaloneEp2_1` unchanged; `StandaloneEp1_2` and `StandaloneEp2_2` changed by 5.x: they no longer activate the Focus Clues tutorial entry (merge legacy's one-line fact guards into them).

**Decisions:** port as legacy (DT6).
- **Deviation:** the standalone starts no longer activate the Focus Clues tutorial entry, as 5.x's `StandaloneEp1_2` and `StandaloneEp2_2`; legacy's (1.32's) did: legacy's changes are merged into 5.x's bodies (the owner's DT6, 2026-10-21; recorded by the [audit](craft.md#craft-and-loot-audit-2026-10-22) F8).

### Dependencies on other areas

- **Areas LOOT builds on:** ITEM (level-scaled stock, the restock rule, `GiveReward` levels, ITEM-05's standalone gear, ITEM-11's kits), ALCH (the potions, decoctions and mutagens placed), ENCH (runes and glyphs), ARM and SWD (the gear placed), UI (the loot window).
- **Areas LOOT shares with:** CRAFT (the items and kits; CRAFT-10 with LOOT-04), ECON (prices, funds, the rewards' gold), XP (the rewards' experience and levels), FOOD (food in the lists), AI and DIFF (the same binary entities), TRPH (looted trophies).

### Save impact

None expected for a new playthrough: lists are read when a merchant restocks, a container fills or a monster dies. Facts for the port and the release notes:
- A merchant's rolled stock, a container's contents and dropped loot are saved: a save made before the port keeps them until the merchant restocks or the container renews; quest rewards already given stay given.
- The standalone inventory is given once (facts `standalone_ep1_inv`, `standalone_ep2_inv`).
- Adding or removing the mod mid-playthrough is not supported ([save compatibility](../feature-mapping.md#save-compatibility)).

### Area decisions

**Decided** by the project owner (2026-10-21): DT1 a DLC override if it works, otherwise whole-file overrides (a DLC list merges into vanilla's, so whole-file overrides); DT2 legacy's level gates; DT3 5.x's sources for its new items kept; DT4 legacy's reward items; DT5 master kits sold as legacy; DT6 legacy's standalone inventories; DT7 the Balisse fix ported unless 5.x already fixed it; DT8 legacy's items with 5.x's attribute cleanup on the 17 quest lists (applied to every list legacy changed: 5.x's list header plus only the header values legacy changed; porter's call, confirmed by the owner, 2026-10-23); DT9 the boundary as mapped; QT2 5.x's platform-reward gear kept as it is (the owner considers reward armours outside the normal flow of the game, so they may be awkward next to normal gear); QT1 extend the tools: `cr2w_patch.py` adds and removes list entries, and patches the 39 merchants (LOOT-02) and the 158 monsters (LOOT-06), each patched file equal to 5.x's plus exactly legacy's list changes, proved by a `--verify`/`--check` as ALCH's Dimeritium patch.

**Later:** rewrite `gmtest_loot()`'s rolls to restock a real merchant's own entity (spawned, emptied, then `AutoBalanaceItemsWithPlayerLevel` and `UpdateLoot`, as `gmtest_merchantroll` does), which avoids the crashing queued path and its 62-kind limit; once a few launches confirm them, they can rejoin the regression.
