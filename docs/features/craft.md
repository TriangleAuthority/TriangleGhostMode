# CRAFT: crafting, alchemy recipes, ingredients and dismantling

What Geralt needs to make things and what he gets back by taking them apart: the crafting schematics of swords, armor, crossbows, bolts, runes and glyphs (ingredients, the craftsman level they need, the crafting price), the alchemy recipes' ingredients, the crafting and alchemy ingredients themselves (category, rarity, tags), dismantling (the parts every item yields, who can dismantle, the new dismantle kits), the four quest armors Ghost Mode made craftable, and the master kits sold by the master craftsmen. Ghost Mode reworked crafting so that it serves scarce loot (P6): "Crafting was shifted earlier into the game, items require less of the same ingredient to craft (1-2 usually). Generic human items do not require magical and monster components. Witcher gear, glyphs and runes require magical and monster components. Crafted items now have non-random bonuses" (changelist 651–658); "Alchemy recipes were altered for more ingredients diversity. New recipes were added for brewing alcohol" (682–683); dismantle kits and dismantling named mutagens (688–693, 864–865). Sources: those changelist lines, bugfixes 87, 120 and 183, what ARM, ENCH, SWD, ITEM, ALCH and UI left to CRAFT, and the code, which has more than the changelist (the dismantling rule, the craftable quest armors, the alcohol recipes' details, the schematics granted at load).

Where things are sold and found (shop stock, containers, monster drops, quest rewards, the recipe level gates) is [LOOT](loot.md); the two areas were mapped together and share the master kits (CRAFT-10 with LOOT-04).

**What 5.x did in this area** (from `vanilla-5.x`). Almost nothing to 1.32's crafting data: every schematic, alchemy recipe, ingredient and dismantling list legacy changed is 1.32's in 5.x, except six Blood and Wine Wolf school upgrade schematics (they now consume the previous piece, the fix legacy made too) and Cheesecutter's parts (5.x adds a Cheese). The crafting code carries enchantments, dyes and slots over to the crafted item (kept, [ENCH-18](ench.md), DE4). 5.x added content: the Netflix set's 36 schematics (`dlc18_recipes.xml`, given by the new quest `mq1060`), the quest recipe "Signs Enhancement" (Reinald's Philtre, ALCH's DL10), and new gear (Dol Blathanna, White Tiger, Scarlet Crest, Vixen, Top Notch) with 5.x's dismantling parts. A crafting cost is still the crafted item's price through `GetItemPriceCrafting` and the `mod_craftitem` price factor, never the schematic's own `price` (in 1.32, legacy and 5.x).

**How legacy Ghost Mode implements it.** Data: the schematic files (`def_item_crafting_recipes.xml` and its Hearts of Stone, Blood and Wine and free-DLC Wolf school counterparts, `def_item_ep1_crafting_recipes.xml`, `def_item_crafting_recipes_bolts.xml`), the alchemy recipe files (`def_item_alchemy_recipes_*.xml`), the ingredient files (`def_item_ingredients.xml`, three folders) and the `<recycling_parts>` block of about 2,000 items in every item file, all with NG+ copies; two new kit items in `def_item_alchemy_repair_kits.xml`. Scripts: `CInventoryComponent.RecycleItem` (the dismantling rule), `CR4InventoryMenu.PlayerDismantleItem` and the inventory's primary action (dismantle kits), `CInventoryComponent.AddMasterArmorerItems` with its call in `ShowMeGoods` (Yoana's master stock), `W3PlayerWitcher.OnSpawned` (a recipe and a schematic granted once), and a signature-only change of `CalculateCostOfCrafting`. Strings: 8 rows in 9 languages. One binary edit: the Midcotts blacksmith becomes a Master.

Unit lists: [attribution.csv](attribution.csv): 5,700 units carry a CRAFT feature (10 script units, 2,672 XML units and their 2,945 NG+ copies, 1 binary file, 72 string rows: 8 strings × 9 languages); 1,179 of them are shared with other features (ARM, SWD, ALCH, ITEM, ENCH and UI hold the items; CRAFT adds its fields). Units whose only change is a price, a `mod_*` price tag or a weight are ECON's and WGT's.

**Status:** every feature ported and verified in game (no skill is involved; the regression runs in both trees). Signed off by the owner (2026-10-23, with LOOT).

**How it is built:** `tools/gen_craft.py` writes the whole-file overrides of the 12 schematic files and 12 alchemy recipe files that CRAFT changes (5.x's file, legacy's entry for every CRAFT unit, 5.x's own entries kept) and CRAFT-04's armor-stand looks (`gm_craft.xml`), with `--verify`. The item fields go through `item_layer.py` (`gen_item.py`, `gen_arm_items.py`, `gen_swd_items.py`, `gen_ench.py`, and `gen_arm_km.py` for Geralt's starting gear; `gen_alch.py` writes no CRAFT field); `item_layer.block_of` ignores blocks inside XML comments (1.32 comments out some items' parts that legacy restored). The Midcotts smith's craftsman level is patched in both copies of his entity file (`gen_loot.py`). Scripts: `gm/craft/dismantling.ws` (CRAFT-08), `dismantleKits.ws` (CRAFT-09), `grants.ws` (CRAFT-01, CRAFT-06), `masterKits.ws` (CRAFT-10). Tests: `tests/gmTestsCraft.ws` (`GMTest_craft` in the regression), `tests/gmTestsPlay.ws` (real NPCs and their menus, see [development.md](../development.md#testing-in-game)). Merchants and crafting menus were tested on NPCs spawned from their entity files, the menus opened as their scenes do and driven through the menus' own events.

## Scope

**CRAFT covers** every crafting schematic's ingredients, craftsman level and type, crafted quantity and crafting price; the schematic items' rarity; the alchemy recipes' ingredients and the new alcohol recipes; the recipe and schematic granted at load; the ingredient items' category, rarity, tags and description keys; every item's dismantling parts and the dismantling rule; the dismantle kits; the four craftable quest armors; the master kits' place with the master craftsmen (with LOOT-04).

**Not CRAFT** (confirmed by the owner with DC7, 2026-10-21):

| Subject | Area | Why |
|---|---|---|
| Where schematics, recipes, kits and ingredients are sold or found, recipe and schematic level gates | LOOT | Availability, not what crafting needs |
| Item prices, schematic and recipe item prices, `mod_*` price tags, the `mod_craftitem`, `mod_disassemble` and `mod_removeupgrade` price factors (the crafting and dismantling fees) | ECON | Money; a crafting fee is the crafted item's price times `mod_craftitem` (CRAFT-05) |
| Item weights | WGT | |
| Cooking recipes (27 new, sold by innkeepers), `EACIT_Edibles` and the cooked quantity (`W3AlchemyManager.CookItem`), the `addrecipesedibles` debug command, edible quality | FOOD | "Cooking recipes added: can be bought from innkeepers" (changelist 839) is the Edibles section; the alcohol recipes are CRAFT-06 with FOOD for the drinks |
| Crafted items' stats, set tags and `DoNotEnhance` ("Crafted items now have non-random bonuses") | ARM, SWD, ITEM (signed off) | Ported with their items (SWD-02, ARM-01, ITEM-08) |
| The Kaer Morhen schematics; the enchanter's runeword and glyphword schematics | ARM-12, ENCH-02 (signed off) | Ported |
| Repair kits' values, the master kits' effect | ITEM-11 (signed off) | CRAFT-10 places the kits with the craftsmen |
| Recipe and schematic texts and tooltips ("components needed", rarity shown) | UI-08 (signed off) | |
| Crossbows' and bolts' stats | XBOW | The bolt schematics' ingredients and quantities are CRAFT-01 |
| Dye quality, the junk items' `mod_valuable` tags, the vodka of Hearts of Stone (`Soltis Vodka`, drink abilities) | ECON, FOOD | Quality and price tags only |
| NG+'s replacement of Blood and Wine's vampire gear (`NewGamePlusReplaceEP2Items`, legacy removed it) | ITEM | Legacy moved that gear to level scaling; ported with [ITEM-04](item.md#item-04-items-moved-to-level-scaling) |
| The `QuestEP1` tag legacy adds to the Hearts of Stone note `ep1_poi_12_note_b` | FIX-03 | Belongs with legacy's `FixQuestItems`; the unit carries CRAFT-08 for its parts only |

## Changes at a glance

### What Ghost Mode changed

| # | Feature | Vanilla 1.32 | Legacy GM | Units (main) |
|---|---|---|---|---|
| CRAFT-01 | Generic gear schematics | Up to 6 of one ingredient, gems and monster parts on human swords | 1–2 of each (ingredient count −40%: 1,305 → 784 over 189 changed schematics; 95 → 5 schematics needing 3+ of one), no monster or magic parts; 27 craftsman levels moved; 7 new crafted-sword schematics and a Meteorite plate schematic; bolt quantities; the relic schematics' colour fix | `def_item_crafting_recipes.xml` (+ HoS, BaW, bolts), Midcotts smith binary |
| CRAFT-02 | Witcher gear schematics | Up to 6 of one ingredient | 1–2 of each (1,387 → 935 over 173 schematics; 67 → 0 needing 3+ of one), a monster component in each, upgrades consume the previous piece, 10 craftsman levels moved | the same files, `dlc10_wolf_recipes.xml` |
| CRAFT-03 | Rune and glyph schematics | Runestone plus one ingredient | 24 of 63 with an added magical component (e.g. Rune pierog: + Amber dust), Runestone greater and Glyph infusions reworked | the same files, `def_item_ep1_crafting_recipes.xml` |
| CRAFT-04 | Craftable quest armors | Freya's Warriors', the Redanian Halberdier's, the Hindarfjall Heavy and the Oathbreaker armor exist only as quest items | Craftable copies with schematics (Grand Master armorer; Oathbreaker: Master), sold by Yoana | items and abilities (ARM-01), 4 schematics, armor-stand looks |
| CRAFT-05 | Crafting prices | Schematic `price` read by no crafting code | 432 schematic prices changed (witcher gear ×2.4); the recipe-based fee line commented out: still inert | schematic `price`, `CalculateCostOfCrafting`, `GetCraftingCost` |
| CRAFT-06 | Alchemy recipes | Up to 4 of one herb | 118 recipes reworked (ingredient count 946 → 597); 2 new alcohol recipes (Mandrake cordial, Mahakam spirit); Tawny Owl 1 recipe granted once | `def_item_alchemy_recipes_*.xml`, `OnSpawned` |
| CRAFT-07 | Ingredients | Monster hides as alchemy ingredients; mixed rarity colours | 35 ingredients change category (e.g. Troll skin, Werewolf pelt to crafting), 19 crafting components become junk; rarity reworked (bugfix 120); description keys follow | `def_item_ingredients.xml` (3 folders) |
| CRAFT-08 | Dismantling | Many parts; a Journeyman returns 1 of each part, a Master a random share | Far fewer parts on gear (e.g. a Guard armor: 20 parts → 2); quest items, keys, notes and decorations yield nothing (about 900 items); named mutagens yield a lesser mutagen; every craftsman returns all parts | `recycling_parts` of ~2,000 items, `RecycleItem`, junk descriptions |
| CRAFT-09 | Dismantle kits | — | Item and Alchemy dismantle kits: dismantle junk, crafting or alchemy ingredients from the inventory (E) | 2 items, 4 abilities, `PlayerDismantleItem`, inventory input, 5 strings |
| CRAFT-10 | Master kits at the master craftsmen | — | Hattori, Yoana (after her quest), the Hearts of Stone enchanter and the Blood and Wine archmaster sell the master kits (ITEM-11) | `AddMasterArmorerItems`, `ShowMeGoods`, 4 shop lists (LOOT-04) |

### What 5.x changed

| # | Feature | 5.x change (from code and data) |
|---|---|---|
| CRAFT-01 | Generic schematics | None to the schematics legacy changed; the crafting code carries enchantment, dye and slots over (ENCH-18, kept) |
| CRAFT-02 | Witcher gear | Six Blood and Wine Wolf upgrade schematics now consume the previous piece (legacy's fix too, with legacy's own ingredients); 36 new Netflix schematics (`dlc18_recipes.xml`, Master to Arch Master, 1–3 of each, a monster part each) |
| CRAFT-03 | Runes and glyphs | None |
| CRAFT-04 | Quest armors | None (the four armors are 1.32's; legacy's crafted copies are new) |
| CRAFT-05 | Crafting prices | None: the fee is still the item's price |
| CRAFT-06 | Alchemy recipes | None to legacy's recipes; a new quest recipe, Signs Enhancement |
| CRAFT-07 | Ingredients | None (the mutagen synergy abilities in the same file are MUT's and ALCH's) |
| CRAFT-08 | Dismantling | `RecycleItem` unchanged; Cheesecutter also yields a Cheese; 5.x's new gear has 5.x's parts |
| CRAFT-09 | Dismantle kits | None (1.32's unused `Dismantle Kit` item and `IsItemDismantleKit` are still there) |
| CRAFT-10 | Master kits | None |

### Classification and action

| # | Feature | Class | Action |
|---|---|---|---|
| CRAFT-01 | Generic schematics | clean (data), conflict (port form: a DLC cannot override a schematic) | Legacy's data through DC1's form |
| CRAFT-02 | Witcher gear | clean, overlap (6 Wolf schematics) | Legacy's (DC4); 5.x's Netflix schematics per DC2 |
| CRAFT-03 | Runes and glyphs | clean | Legacy's |
| CRAFT-04 | Quest armors | clean | Port whole (ARM audit F1) |
| CRAFT-05 | Crafting prices | clean (inert) | Carry legacy's numbers with the schematics (DC3); no script change |
| CRAFT-06 | Alchemy recipes | clean, conflict (port form) | Legacy's through DC1's form |
| CRAFT-07 | Ingredients | clean | Port through the item layer (DC5) |
| CRAFT-08 | Dismantling | clean, overlap (Cheesecutter) | Port through the item layer; legacy's `RecycleItem` rule |
| CRAFT-09 | Dismantle kits | clean | Port |
| CRAFT-10 | Master kits | clean | Port with LOOT-04 |

---

### CRAFT-01 Generic gear schematics

| | |
|---|---|
| Kind | content |
| Pillars | P6, P8 |
| 5.x class | clean (data); conflict (port form) |
| Flags | balance |
| Depends on | ARM, SWD (the crafted items), ITEM (level and `DoNotEnhance`), CRAFT-07 (ingredient names), UI-08 (schematic texts) |
| Skill trees | n/a |
| Port form | the schematics in whole-file overrides of the schematic files (DC1): 5.x's files with legacy's entries, `tools/gen_craft.py` (`--verify`), regular and NG+; the schematic items' rarity through the item layer; the Meteorite plate schematic granted once at load (`gm/craft/grants.ws`, a wrapper of `OnSpawned`, fact `gm_craft_recipes_added`); the Midcotts smith's craftsman level in 5.x's entity file, both copies (`gen_loot.py` with LOOT-02's edits of the same file, `cr2w_patch.py`) |
| Port status | **signed off** (2026-10-23); verified (2026-10-22): the whole-file overrides load, each schematic defined once (`GMTest_craft01`); a spawned Midcotts smith reads Master and crafts the Meteorite plate through his crafting menu's craft event (scripted click) |
| Open checks | a reworked generic schematic crafted in play |
| Save impact | none (expected): schematics are read from the definitions; known schematics are saved by name |
| NG+ counterpart | applied (legacy's NG+ files), untested |

**What it does** (changelist 653–656): human swords, armor, crossbows, bolts, repair kits and crafting materials (ingots, plates) need fewer and more varied common materials: 189 changed schematics need 784 ingredients in all instead of 1,305, only 5 need three or more of one ingredient (1.32: 95), and gems and monster parts are gone from human gear (e.g. a Guard Lvl1 steel sword 3: 1.32's 2 dark iron ingots, a ruby, an amethyst, a monstrous eye and leather straps; legacy's dwimeryte ingot, leather, 2 wire ropes, a haft, amethyst dust). Craftsman levels: 15 schematics move from Journeyman to Master, 8 from Grand Master to Master, 4 from Master to Journeyman. New: crafted versions of the Novigraadan sword 2 and 3, Skellige sword 3 and 4, Scoia'tael sword 1 and 4 and Silver sword 5 (their `_crafted` items exist in 1.32's data without a schematic), and a Meteorite plate schematic (2 Meteorite ingots at a Master crafter) that every save learns once at load. Bolt schematics craft different quantities. Schematic items get rarities matching what they make; the Blood and Wine relic sword schematics lose the witcher-set colour (bugfix 183). The Midcotts blacksmith (Velen) becomes a Master craftsman (binary edit).

**Implementation (legacy):** the `<schematic>` entries and schematic `<item>` entries of `def_item_crafting_recipes.xml` (base, Hearts of Stone, Blood and Wine), `def_item_crafting_recipes_bolts.xml`, regular and NG+; `OnSpawned` (`AddCraftingSchematic('Meteorite plate schematic')` with the fact `ModSignsRecipesAdded`); `midcotts_blacksmith_01.w2ent` (`W3CraftsmanComponent.craftsmanData.level` Journeyman → Master, besides LOOT-02's lists).

**5.x:** the same 1.32 schematics. A DLC cannot override a schematic: the crafting manager reads both definitions (found by ARM-12, [arm.md](arm.md#arm-12-kaer-morhen-set)), and the mod.io guide lists `<crafting_schematics>` and `<alchemy_recipes>` among the entries `on_conflict` does not work on (unverified).

**Decisions:** port legacy's data (legacy behaviour first, 5.x unchanged) in whole-file overrides (DC1).

**Later:** —

### CRAFT-02 Witcher gear schematics

| | |
|---|---|
| Kind | content |
| Pillars | P6, P8 |
| 5.x class | clean; overlap (six Blood and Wine Wolf upgrades) |
| Flags | balance |
| Depends on | ARM-05 to ARM-11 (the sets), SWD-04 (school swords), CRAFT-07 |
| Skill trees | n/a |
| Port form | as CRAFT-01 |
| Port status | **signed off** (2026-10-23); verified (2026-10-22, as CRAFT-01) |
| Open checks | a witcher gear upgrade crafted in play |
| Save impact | none (expected) |
| NG+ counterpart | applied, untested (the NG+ files hold more witcher schematics than the regular ones: 294 units against 178) |

**What it does** (changelist 657): every school set's schematics (Feline, Griffin, Ursine, Wolven, the free DLC's Wolf school, Hearts of Stone's and Blood and Wine's witcher gear, the school crossbows) need magical and monster components and 1–2 of each ingredient: 935 ingredients over 173 schematics instead of 1,387, none needing three of one (1.32: 67). Example: Lynx School steel sword upgrade 4 needs the level 3 sword, an orichalcum ingot, a green gold ingot, ruby dust, a monstrous spore and monstrous blood (1.32: 2 leather squares, 2 dwimeryte enriched ingots, a sapphire, monstrous blood). Upgrade schematics consume the previous piece, Blood and Wine's included (1.32 forgot it on six Wolf upgrades). Craftsman levels: 6 schematics from Master to Journeyman, 3 from Master to Grand Master, 1 from Grand Master to Master.

**Implementation (legacy):** the witcher gear `<schematic>` and schematic `<item>` entries of the schematic files, `dlc10_wolf_recipes.xml` (48 schematics, 10 craftsman levels), regular and NG+.

**5.x:** the six Blood and Wine Wolf upgrade schematics (steel and silver sword 4, jacket 4, gloves, trousers and boots 5) consume the previous piece, with 1.32's other ingredients: legacy's version has the same fix, so porting legacy's entries keeps it. 5.x's Netflix set (ARM-15, SWD-10) has 36 new schematics given by `mq1060`: Master (base), Grand Master (tier 1) and Arch Master (tier 2), 4–5 ingredients each, 1–3 of each, a monster part or essence in each (DC2).

**Decisions:** legacy's entries (DC4); 5.x's Netflix schematics kept (DC2).

### CRAFT-03 Rune and glyph schematics

| | |
|---|---|
| Kind | content |
| Pillars | P6 |
| 5.x class | clean |
| Flags | — |
| Depends on | ENCH-16 (runes and glyphs), CRAFT-07 |
| Skill trees | n/a |
| Port form | as CRAFT-01 |
| Port status | **signed off** (2026-10-23); verified (2026-10-22, as CRAFT-01) |
| Open checks | a rune crafted in play |
| Save impact | none (expected) |
| NG+ counterpart | applied, untested |

**What it does** (changelist 657, 953–955 for the words): runes and glyphs need a magical component besides the runestone: 24 of the 63 rune and glyph schematics get one (e.g. Rune pierog: lesser runestone, dumplings and now amber dust); Runestone greater and the two Glyph infusions are reworked. The other 39 change only their crafting price (CRAFT-05).

**Implementation (legacy):** 49 schematics in `def_item_crafting_recipes.xml` and 14 in Hearts of Stone's `def_item_ep1_crafting_recipes.xml`, regular and NG+; their items' prices are ECON's.

**5.x:** unchanged.

**Decisions:** port as legacy. The enchanter's runeword schematics are ENCH-02's (ported).

### CRAFT-04 Craftable quest armors

| | |
|---|---|
| Kind | content |
| Pillars | P6, P8 |
| 5.x class | clean |
| Flags | — |
| Depends on | ARM-01 (their stats and class, mapped there), ITEM (level tags, durability), LOOT-04, LOOT-05 (where the schematics are) |
| Skill trees | n/a |
| Port form | the four items and their `_Stats` abilities as new DLC entries, legacy's whole (`gen_item.py`: legacy's new entries carry ARM-01's stats), the three armor-stand looks in `gm_craft.xml` (`gen_craft.py`), the schematics in the whole-file overrides (DC1) |
| Port status | **signed off** (2026-10-23); verified (2026-10-22): the Hindarfjall heavy armor crafted through a spawned Yoana's crafting menu (scripted click; schematic and ingredients given by `gmtest_craft04_give`); its schematics in her master stock after her quest |
| Open checks | the crafted armors on the armor stand |
| Save impact | none (new items); removing the mod: the crafted copies and their schematics become unknown items (unsupported) |
| NG+ counterpart | applied, untested |

**What it does** (not in the changelist; the owner's ARM audit decision F1, 2026-10-18, sends them whole to CRAFT): craftable copies of Freya's Warriors' Armor (`q108 Light armor 09_crafted`), the Redanian Halberdier's Armor (`q108 Medium armor 03_crafted`), the Hindarfjall Heavy Armor (`q108 Heavy armor 04_crafted`) and the Oathbreaker Armor (`Oathbreaker armor crafted`), chest pieces with legacy's stats. The three q108 schematics need a Grand Master armorer (e.g. the Hindarfjall: a dwimeryte plate, leather, string), the Oathbreaker a Master (a meteorite plate, a silver ingot, a glowing ingot, 2 hardened leather, 2 strings). Yoana sells all four schematics in her master stock (`_store__Master_Armorsmith_Yoana`, the Oathbreaker from level 14; CRAFT-10); the Oathbreaker schematic can also turn up in random container loot from level 14 (`_everywhere_schematics`) and lies in a living-world chest (`de30_chest`) (LOOT).

**Implementation (legacy):** 4 items and 4 abilities in `def_item_crafting_armor.xml` (and NG+), 4 schematics and 4 schematic items, 3 armor-stand looks in `_armor_stand_variants_extension.xml`.

**5.x:** none of it exists.

**Decisions:** port whole (ARM audit F1, owner, 2026-10-18).

### CRAFT-05 Crafting prices

| | |
|---|---|
| Kind | content |
| Pillars | P6 |
| 5.x class | clean (inert data) |
| Flags | — |
| Depends on | ECON (the real fee: item prices, `mod_craftitem`) |
| Skill trees | n/a |
| Port form | the `price` attribute carried in the schematic entries (DC1's form); no script |
| Port status | **signed off** (2026-10-23); verified (2026-10-22, with the schematics; the fee is the item's price, as legacy) |
| Open checks | — |
| Save impact | none |
| NG+ counterpart | applied (no effect) |

**What it does:** nothing in play. Legacy changed the `price` of 432 schematics (generic gear 47,168 → 61,868 in all, witcher gear 101,415 → 238,538, runes and glyphs 24,432 → 26,325), but the fee a craftsman asks is the crafted item's price through `GetItemPriceCrafting` and the `mod_craftitem` factor; the line that would have used the schematic's price is commented out in legacy ("recipe based crafting cost -> removed due to price modifier changes"). `CalculateCostOfCrafting` takes the schematic instead of its item name, with no change in behaviour. The fee is therefore ECON's (item prices, `mod_craftitem` in `economy_tagmodifiers.csv`).

**Implementation (legacy):** schematic `price` attributes; `W3CraftsmanComponent.CalculateCostOfCrafting`, `W3CraftingManager.GetCraftingCost` (signature only).

**5.x:** the same: `baseCraftingPrice` is read by the enchanting menu (the enchanter's runeword prices, ENCH-02) and an unused old tooltip component, not by crafting.

**Decisions:** legacy's prices carried (DC3). The script change is not ported (no behaviour).

### CRAFT-06 Alchemy recipes

| | |
|---|---|
| Kind | content |
| Pillars | P6, P8 |
| 5.x class | clean (data); conflict (port form) |
| Flags | balance |
| Depends on | ALCH (the brewed items), CRAFT-07, FOOD (the two alcohol drinks), UI-08 (recipe texts) |
| Skill trees | n/a |
| Port form | the recipes in the whole-file overrides of the recipe files (DC1, `gen_craft.py`); the three pheromone formulas legacy's whole, `cookedItemType` quest included (ALCH-08); the two new recipe items through `gen_item.py`; the Tawny Owl 1 recipe granted once at load (`gm/craft/grants.ws`, fact `gm_craft_recipes_added`, with CRAFT-01's grant) |
| Port status | **signed off** (2026-10-23); verified (2026-10-22): the recipes as legacy's and the load-time grants (`GMTest_craft01`, `GMTest_craft06`); Mandrake cordial brewed through the alchemy menu's craft event |
| Open checks | a reworked potion brewed in play |
| Save impact | none (expected): recipes are read from the definitions; known recipes are saved by name |
| NG+ counterpart | applied, untested |

**What it does** (changelist 682–683): 118 recipes (99 potions, oils, bombs and mutagen conversions of the base game, 3 alcohol, 14 of Blood and Wine with its dye, 1 of Hearts of Stone, and the Nekker pheromone, a quest formula as legacy's, [ALCH-08](alch.md#alch-08-pheromones-killer-whale-pops-antidote)) need more varied and fewer herbs: 597 ingredients in all instead of 946 (e.g. Mutagen red to green: 4 celandine → 1). Two new recipes brew alcohol, Mandrake cordial (empty bottle, Temerian rye, Redanian herbal, mandrake root) and Mahakam spirit (empty bottle, local pepper vodka, hop umbels, sewant mushrooms); herbalists sell them (LOOT-01). Every save learns the Tawny Owl 1 recipe once at load ("fix missing Tawny Owl recipe": 1.32 and 5.x give it only in the standalone starts).

**Implementation (legacy):** `<recipe>` entries of `def_item_alchemy_recipes_potions/oils/petards/mutagens/alcohol.xml` and the Blood and Wine and Hearts of Stone files, regular and NG+; 2 new recipe items in `def_item_alchemy_recipes_alcohol.xml`; `OnSpawned` (fact `ModSignsRecipesAdded`). `ClearKnownRecipes` only renames a local (nothing to port).

**5.x:** unchanged, plus 5.x's quest recipe Signs Enhancement (kept: ALCH's DL10). The Mutation Catalyst's recipe is MUT-12's (ported).

**Decisions:** port as legacy through DC1's form. The pheromone formulas' quest type is carried too (the owner's decision, 2026-11-03, whole-port audit C3-4: the file is overridden whole anyway).

### CRAFT-07 Ingredients

| | |
|---|---|
| Kind | content |
| Pillars | P6, P7 |
| 5.x class | clean |
| Flags | — |
| Depends on | CRAFT-08 (the same entries), UI (rarity colours, the crafting menu) |
| Skill trees | n/a |
| Port form | the ingredient items' `category`, `base_abilities` (with any `<a>` legacy wrote after the block), tags (not `mod_*`), `localisation_key_description`, `grid_size` and `icon_path` through the item layer (DC5): `item_layer.py`'s CRAFT fields, written by `gen_item.py` (no other tool writes ingredients) |
| Port status | **signed off** (2026-10-23); verified (2026-10-22, `GMTest_craft07`; the inventory's crafting and alchemy tabs seen); the two alcohols: a potion is refilled with the vodka and refused with the lemon (`gmtest_craft07_refill`, scripted call of `SingletonItemsRefillAmmo`) |
| Open checks | the crafting and alchemy menus list each moved ingredient on the right tab |
| Save impact | none (expected): item definitions are read live (ARM-01 verified this for item fields) |
| NG+ counterpart | applied, untested |

**What it does:** sorts ingredients for crafting with the reworked recipes: 12 alchemy ingredients become crafting components (monster hides and skins such as Necrophage skin, Troll skin, Werewolf pelt), 23 crafting components become alchemy ingredients, 19 become junk and one junk item a component (Haft); rarities reworked so the crafting menu's colours match (bugfix 120: e.g. 54 Magic → Relic, 26 Relic → Magic, hardened leather and timber Magic → Master); description keys follow the new category; 36 grid sizes change. Local pepper vodka becomes the alchemy ingredient potions are refilled with (`StrongAlcohol`, "alcohol for crafting and refilling") and Free nilfgaardian lemon, which 1.32 had in that role, a drink. Price tags (`mod_valuable`, `mod_precious`) are ECON's.

**Implementation (legacy):** about 190 `<item>` entries of `def_item_ingredients.xml` (base, Hearts of Stone, Blood and Wine), the two alcohols in `def_item_edibles.xml`, regular and NG+.

**5.x:** unchanged.

**Decisions:** port as legacy.

- Two of legacy's edits were added by the whole-port audit (C3-3, 2026-11-03): the Jug's icon (`glass_jug_64x64.png`; 5.x `junk_jug_64x64.png`; `icon_path` in CRAFT-07's fields), and Melitele figurine's `<a>Master _Stats</a>`, which legacy wrote after the item's empty `<base_abilities>` block. It is carried where legacy put it (`item_layer.stray_abilities`): harmless, since 5.x's own `Silver sword 2` has such a node and loads; the game ignores it (a spawned figurine reads quality 1 and no abilities), so it is inert, as legacy's most likely was. Verified 2026-11-03 in both trees (scripted: `GMTest_data_items` in the regression).

Free nilfgaardian lemon gets legacy's category, description and tags here; its drink abilities (Well Hydrated 3, strong alcohol) are FOOD-04's ([food.md](food.md#food-04-food-and-drink-items)).

### CRAFT-08 Dismantling

| | |
|---|---|
| Kind | content, system |
| Pillars | P6 |
| 5.x class | clean; overlap (Cheesecutter) |
| Flags | balance |
| Depends on | every item area (ARM, SWD, ALCH, ITEM, UI: the entries), CRAFT-07 |
| Skill trees | n/a |
| Port form | the `<recycling_parts>` blocks through the item layer (DC5, `item_layer.apply_item`): `gen_arm_items.py`, `gen_swd_items.py` and `gen_ench.py` apply them to the entries they write, `gen_item.py` writes every other item CRAFT changes (5.x's entry with ITEM's and CRAFT's fields), the razor's in `gm_ui.xml` by hand; `@replaceMethod CInventoryComponent.RecycleItem` (legacy's rule, `gm/craft/dismantling.ws`); strings 2110992257, 2110992258, 2110992260 (legacy's rows) |
| Port status | **signed off** (2026-10-23); verified (2026-10-22): a Guard armor, the Grave Hag ear and the starting armor and boots dismantled through a spawned Journeyman armorer's Dismantle menu (scripted click) gave legacy's parts, all of them; `GMTest_craft08` (the Grave Hag ear, the four starting pieces) in the regression |
| Open checks | — |
| Save impact | none (expected) |
| NG+ counterpart | applied, untested |

**What it does:** dismantling returns far fewer parts and nothing from things that are not gear or materials. Armor, weapons and crafted gear yield 1–3 simple parts (e.g. a Guard Lvl1 armor: 1.32's 5 linen, 2 leather straps, 4 thread, 6 dark iron ingots and 3 silk; legacy's 1 silk and 1 leather; a Lynx armor 4: a shirt, hardened leather, draconide infused leather); ores and minerals refine into fewer (Nickel ore: 5 → 2 minerals; 39 minerals and refined ingredients yield nothing); quest items (629), keys (88), Blood and Wine's notes (124) and decorations (60) yield nothing (1.32: a silver ingot from a victim's handkerchief); runes and glyphs yield one infused dust; the 27 named mutagens of the base game and Blood and Wine's Protofleder mutagen yield a lesser mutagen of their colour (changelist 692–693), a source of lesser mutagens now that monsters no longer drop them (LOOT-06). Any craftsman returns every part (1.32: a Journeyman one of each, a Master a random share, only a Grand Master all); parts from the player's own dismantling are not marked new. Two junk descriptions say "Can be sold to merchants or dismantled" (vanilla keys overridden); "Crafting components" (2110992257) is in legacy's table but no script reads it.

**Implementation (legacy):** `<recycling_parts>` of about 2,000 items across all item files (1,958 regular units, 2,115 NG+), `CInventoryComponent.RecycleItem`, 3 strings × 9 languages.

**5.x:** `RecycleItem` unchanged; Cheesecutter also yields a Cheese (DC4). 5.x's new items keep 5.x's parts. Each item is defined once ([tools.md](../tools.md), `gen_item.py`): the item tools that write an entry apply CRAFT's fields to it (`item_layer.apply_item`), `gen_item.py` writes the rest.

**Decisions:** port as legacy (DC4 for Cheesecutter, DC5 for the technique).

- Hearts of Stone's auctioned painting (`q603_auctioned_painting`) loses the `mq7024_picture` tag, as legacy (the owner's decision, 2026-11-03, whole-port audit A6-1): Blood and Wine's painting quest content keyed on that tag no longer counts it. Carried with the item's CRAFT-08 entry (`item_layer.TAGS`); in NG+ too, where 1.32 never had the tag and 5.x added it (`item_layer.NGP_TAGS`, the NG+ rule for a non-numeric change). Verified 2026-11-03 in both trees (scripted: `GMTest_data_items` in the regression).

**For information (WGT audit F5, accepted by the owner 2026-11-02):** Blood and Wine defines `poi_gor_d_06_note` and `poi_gor_d_06_note03` twice (as books with `Default Book _Stats` in `def_item_books.xml`, and as misc items without abilities in `def_item_living_world.xml`); CRAFT-08's whole entries in `gm_item.xml` follow the copy legacy changed (the second), so in the port they are misc items weighing 0.01. Six Hearts of Stone notes (`ep1_poi_03_note` and five more) are defined twice the same way and take the second copy's icon. Which copy legacy's game read is not known; the entries stay pinned to one copy.

**ECON's PE13:** legacy adds `mod_alchemy_table` to Blood and Wine's Protofleder Mutagen (both folders), the tag the dismantling station reads (`W3StandaloneDismantleComponent.ShouldShowItem`); CRAFT-08 owns that one tag (`item_layer.TAGS`, kept out of ECON's price tags by `ECON_KEEP`); **verified** by script in both trees (`GMTest_econ_e2`: the station's rule shows it, the Katakan mutagen as a control). Not a deviation: legacy's tag.

**Later:** legacy's parts of Knight Geralt Pants 3 and Knight Geralt A Pants 3 name "Silver Ingot" (the item is "Silver ingot"), carried as legacy's; if the game matches item names by case, that part is never given, in legacy too.

### CRAFT-09 Dismantle kits

| | |
|---|---|
| Kind | system, content |
| Pillars | P6 |
| 5.x class | clean |
| Flags | — |
| Depends on | CRAFT-08 (the parts), UI-15 (the inventory's primary action, wrapped there for the razor), LOOT-01 (the shops that sell the kits), ECON, WGT (their price and weight) |
| Skill trees | n/a |
| Port form | the 2 items and 4 abilities as new DLC entries (`gen_item.py`, legacy's whole); `gm/craft/dismantleKits.ws`: `@addMethod CInventoryComponent.GMDismantleKitFor` (legacy's conditions), `@addMethod CR4InventoryMenu.GMPlayerDismantleItem` (legacy's `PlayerDismantleItem`), wrappers of `W3InventoryGridContext.execurePrimaryAction` and `updateInputFeedback` (the razor keeps UI-15's input); strings 2110992330 to 2110992334 (legacy's rows) |
| Port status | **signed off** (2026-10-23); verified (2026-10-22): the E Dismantle prompt in the inventory on a junk item, a crafting component and an alchemy ingredient (selected with real keys); the dismantle through the inventory's primary-action input event (`gmtest_menuinput`) and with each kit (`gmtest_craft09_menu`): one kit used, the item's parts given |
| Open checks | a real E key press (the test harness's injected key does not reach the inventory's item actions, vanilla's Read neither) |
| Save impact | none; removing the mod: the kits become unknown items (unsupported) |
| NG+ counterpart | applied, untested |

**What it does** (changelist 688–690, 864–865): two consumable kits, "Item dismantle kit" ("Allows to dismantle junk items and crafting components") and "Alchemy dismantle kit" ("Allows to dismantle alchemy components"), sold by armorers and blacksmiths (13 shop lists) and by alchemists and herbalists (18) (LOOT-01). In the inventory, selecting a junk item or crafting component with parts and pressing E (Dismantle) with an item kit, or an alchemy ingredient (named mutagens among them) with an alchemy kit, dismantles one item, uses one kit and gives every part (CRAFT-08). Gear itself cannot be dismantled with a kit.

**Implementation (legacy):** `gear_dismantle_kit_1`, `alchemy_dismantle_kit_1`, `GearDismantleKit_1(_Stats)`, `AlchemyDismantleKit_1(_Stats)` in `def_item_alchemy_repair_kits.xml` (and NG+); `CR4InventoryMenu.PlayerDismantleItem`; `W3InventoryGridContext.execurePrimaryAction` and `updateInputFeedback` (shared with UI-15's razor); 5 strings × 9 languages.

**5.x:** none; 1.32's unused `Dismantle Kit` item (`NoShow`) is unrelated.

**Decisions:** port as legacy.

### CRAFT-10 Master kits at the master craftsmen

| | |
|---|---|
| Kind | content |
| Pillars | P6 |
| 5.x class | clean |
| Flags | — |
| Depends on | ITEM-11 (the kits), LOOT-04 (the four shop lists) |
| Skill trees | n/a |
| Port form | `@addMethod CInventoryComponent.GMAddMasterArmorerItems` (legacy's fact check; the list's 18 entries added by `AddAnItem` through `GMAddMasterStockEntry`, not by `AddItemsFromLootDefinition`: below), called by a wrapper of `CInventoryComponent.AutoBalanaceItemsWithPlayerLevel` for an inventory whose entity has the tag `sq108_blacksmith_woman` (legacy's call sat right before it in the storyscene function `ShowMeGoods`, which stays 5.x's; the function's only other caller is a container's), `gm/craft/masterKits.ws`; the shop entries with LOOT-04 |
| Port status | **signed off** (2026-10-23); verified (2026-10-22, with LOOT-04): Hattori's shop stocks the master weaponsmith tools; Yoana's shop stocks her master list after her quest's fact and a master armorsmith kit was bought from it; the stock added without the engine's list call verified 2026-10-24 in both trees: a spawned Yoana's shop opened over 40 times in one launch without a crash, the same stock at every opening, restocked when emptied, schematics Geralt knows skipped; `GMTest_loot04` (a second opening adds nothing) |
| Open checks | the Hearts of Stone enchanter (LOOT-04: his list never reaches the kits); Yoana's shop in play after her quest (her real entity's tag) |
| Save impact | none (expected); the shop lists are rolled when a merchant restocks |
| NG+ counterpart | applied, untested |

**What it does** (changelist 611, 633): the master weaponsmith tools (`weapon_repair_kit_4`) are sold by Hattori, the master armorsmith tools (`armor_repair_kit_4`) by Yoana after her quest (`sq108_master_bsmith_helped`; she then also sells legacy's master stock, with CRAFT-04's schematics), and both by the Hearts of Stone enchanter and Blood and Wine's archmaster smith.

**Implementation (legacy):** `CInventoryComponent.AddMasterArmorerItems`, its call in `ShowMeGoods`; entries in `_store__Hattori_Master_Blacksmith`, `_store__Master_Armorsmith_Yoana`, `_store__LW_DLC_EnchanterMaster`, `_EP2_store_archmaster` (LOOT-04).

**5.x:** none.

**Decisions:** port as legacy (DI6 left it to CRAFT and LOOT), apart from how Yoana's master list is added (below).

- **Deviation:** Yoana's master stock is the stock one roll of legacy's list `_store__Master_Armorsmith_Yoana` gives, added by the script without the engine's list call: at each opening of her shop after her quest, each of the list's entries from its level gate (`player_level_min`; every entry has chance -1), except a schematic Geralt knows (as the engine's list skips it), topped up to the entry's quantity (`quantity_min` to `quantity_max`) when she holds fewer than `quantity_min`. Legacy queued the list (`AddItemsFromLootDefinition`) at every opening, so her stock grew with each visit; on 5.x that call repeated on one inventory crashes the game (her shop at its 14th to 16th opening in one launch). The list stays in `def_loot_shops.xml` (LOOT-04) and its entries are repeated in `gm/craft/masterKits.ws`: keep the two in step. Replaces the call "Yoana's master list added on each shop open, as legacy" (confirmed by the owner, 2026-10-21). (Owner, 2026-10-24.)

---

### CRAFT and LOOT audit (2026-10-22)

One shared audit of both areas. Every finding was fixed, recorded or decided by the owner; the results are in the entries (CRAFT-07, CRAFT-08, LOOT-04, LOOT-07, LOOT-09). Signed off by the owner (2026-10-23).

### Dependencies on other areas

- **Areas CRAFT builds on:** ARM (the armor entries and `gen_arm_items.py`, ARM-12's schematic technique and its finding that a DLC cannot override a schematic), SWD (`gen_swd_items.py`), ALCH (`gen_alch.py`), ITEM (`item_layer.py`, `gen_item.py`, ITEM-11's kits), ENCH (runes and glyphs, ENCH-18's carry-over), UI (UI-08's recipe texts, UI-15's inventory wrappers).
- **Areas CRAFT shares with:** LOOT (where everything is sold and found; CRAFT-10 with LOOT-04), ECON (item prices and the crafting and dismantling fees), WGT (weights), FOOD (cooking, the two alcohols), XBOW (bolt and crossbow stats).

### Save impact

None expected for a new playthrough: schematics, recipes, ingredient fields and dismantling parts are read from the definitions when used. Facts for the port and the release notes:
- Known schematics and recipes are saved by name; the Meteorite plate schematic and the Tawny Owl 1 recipe are granted once at load, behind a fact.
- New items: the dismantle kits, the four crafted quest armors and their schematics, the two alcohol recipe items and the Meteorite plate schematic. Removing the mod (unsupported, [save compatibility](../feature-mapping.md#save-compatibility)) leaves them as unknown items.

### Area decisions

**Decided** by the project owner (2026-10-21):

| # | Question | Decision |
|---|---|---|
| DC1 | How to carry the reworked schematics and recipes (CRAFT-01 to CRAFT-06), which a DLC cannot override | Whole-file overrides of the schematic and recipe files: 5.x's files with legacy's entries merged by a generator (`gen_craft.py --verify`), regular and NG+. Legacy's data exactly, 5.x's own entries (Netflix, Signs Enhancement) kept by the merge, no script; another mod changing the same files conflicts with Ghost Mode |
| DC2 | 5.x's 36 Netflix schematics (CRAFT-02) | 5.x's lists kept: they already need a monster part and mostly 1–2 of each (two need 3 silver ingots); no legacy counterpart |
| DC3 | The schematics' `price` (CRAFT-05), read by no crafting code | Legacy's numbers carried (inert); the fee itself is ECON's (item prices, `mod_craftitem`) |
| DC4 | 5.x's changes to entries CRAFT changes: six Blood and Wine Wolf upgrade schematics, Cheesecutter's Cheese | Legacy's entries (the Wolf upgrades keep the previous-piece fix in legacy's version; Cheesecutter yields a dwimeryte ingot and an amber, without 5.x's Cheese) |
| DC5 | Technique for CRAFT's item fields (parts, ingredient fields), since each item is defined once | `item_layer.py` extended with CRAFT's fields (as ITEM did), applied by the item tools that write each entry and `gen_item.py` for the rest |
| DC6 | Dismantling rule (CRAFT-08) | Legacy's: every craftsman returns all parts |
| DC7 | The boundary | As in [Scope](#scope) |

**Later:** —
