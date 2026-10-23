# CRAFT: crafting, alchemy recipes, ingredients and dismantling

What Geralt needs to make things and what he gets back by taking them apart: the crafting schematics of swords, armor, crossbows, bolts, runes and glyphs (ingredients, the craftsman level they need, the crafting price), the alchemy recipes' ingredients, the crafting and alchemy ingredients themselves (category, rarity, tags), dismantling (the parts every item yields, who can dismantle, the new dismantle kits), the four quest armors Ghost Mode made craftable, and the master kits sold by the master craftsmen. Ghost Mode reworked crafting so that it serves scarce loot (P6): "Crafting was shifted earlier into the game, items require less of the same ingredient to craft (1-2 usually). Generic human items do not require magical and monster components. Witcher gear, glyphs and runes require magical and monster components. Crafted items now have non-random bonuses" (changelist 651–658); "Alchemy recipes were altered for more ingredients diversity. New recipes were added for brewing alcohol" (682–683); dismantle kits and dismantling named mutagens (688–693, 864–865). Sources: those changelist lines, bugfixes 87, 120 and 183, the [ARM](arm.md#hand-off-to-other-areas), [ENCH](ench.md#hand-off-to-other-areas), [SWD](swd.md#hand-off-to-other-areas), [ITEM](item.md#hand-off-to-other-areas), [ALCH](alch.md#hand-off-to-other-areas) and [UI](ui.md#hand-off-to-other-areas) hand-offs, and the code, which has more than the changelist (the dismantling rule, the craftable quest armors, the alcohol recipes' details, the schematics granted at load).

Where things are sold and found (shop stock, containers, monster drops, quest rewards, the recipe level gates) is [LOOT](loot.md); the two areas were mapped together and share the master kits (CRAFT-10 with LOOT-04).

**What 5.x did in this area** (from `vanilla-5.x`, unverified in game). Almost nothing to 1.32's crafting data: every schematic, alchemy recipe, ingredient and dismantling list legacy changed is 1.32's in 5.x, except six Blood and Wine Wolf school upgrade schematics (they now consume the previous piece, the fix legacy made too) and Cheesecutter's parts (5.x adds a Cheese). The crafting code carries enchantments, dyes and slots over to the crafted item (kept, [ENCH-18](ench.md), DE4). 5.x added content: the Netflix set's 36 schematics (`dlc18_recipes.xml`, given by the new quest `mq1060`), the quest recipe "Signs Enhancement" (Reinald's Philtre, ALCH's DL10), and new gear (Dol Blathanna, White Tiger, Scarlet Crest, Vixen, Top Notch) with 5.x's dismantling parts. A crafting cost is still the crafted item's price through `GetItemPriceCrafting` and the `mod_craftitem` price factor, never the schematic's own `price` (in 1.32, legacy and 5.x).

**How legacy Ghost Mode implements it.** Data: the schematic files (`def_item_crafting_recipes.xml` and its Hearts of Stone, Blood and Wine and free-DLC Wolf school counterparts, `def_item_ep1_crafting_recipes.xml`, `def_item_crafting_recipes_bolts.xml`), the alchemy recipe files (`def_item_alchemy_recipes_*.xml`), the ingredient files (`def_item_ingredients.xml`, three folders) and the `<recycling_parts>` block of about 2,000 items in every item file, all with NG+ copies; two new kit items in `def_item_alchemy_repair_kits.xml`. Scripts: `CInventoryComponent.RecycleItem` (the dismantling rule), `CR4InventoryMenu.PlayerDismantleItem` and the inventory's primary action (dismantle kits), `CInventoryComponent.AddMasterArmorerItems` with its call in `ShowMeGoods` (Yoana's master stock), `W3PlayerWitcher.OnSpawned` (a recipe and a schematic granted once), and a signature-only change of `CalculateCostOfCrafting`. Strings: 8 rows in 9 languages. One binary edit: the Midcotts blacksmith becomes a Master.

Unit lists: [attribution.csv](attribution.csv): mapped 2026-10-21 from the changelist, the hand-offs of ARM, ENCH, SWD, ITEM, ALCH, UI and STAM, and sweeps (a field-by-field comparison of every XML unit, master against `legacy-GM` and `vanilla-5.x`, by changed field: `recycling_parts`, `ingredients`, `craftsmanLevel_name`, `craftedItemQuantity`, schematic and recipe `price`, ingredient `category`, `base_abilities`, tags and description keys; `unit_sweep.py` for craft, recipe, schematic, dismantl, recycl, ingredient; the unattributed script and string units read one by one; `bindiff.py` for the binary units): 5,700 units carry a CRAFT feature (10 script units, 2,672 XML units and their 2,945 NG+ copies, 1 binary file, 72 string rows: 8 strings × 9 languages); 1,179 of them are shared with other features (ARM, SWD, ALCH, ITEM, ENCH and UI hold the items; CRAFT adds its fields). Units whose only change is a price, a `mod_*` price tag or a weight are left to ECON and WGT ([hand-off](#hand-off-to-other-areas)). Port status: **signed off** by the project owner (2026-10-23, CRAFT-01 to CRAFT-10); **ported and verified in game** (2026-10-22, 5.x-GM `f65a8365`, `81e3b5bc`, tests `ccab873f`; regression 804 passed, 0 failed in each skill tree); the owner's [area decisions](#area-decisions) are made (2026-10-21); **audited** 2026-10-22 with LOOT ([CRAFT and LOOT audit](#craft-and-loot-audit-2026-10-22)): every finding fixed, recorded or decided, the audit closed ([close-out](#audit-close-out), 2026-10-23). How each check was tested: [Port state](#port-state-2026-10-22).

## Scope

**CRAFT covers** every crafting schematic's ingredients, craftsman level and type, crafted quantity and crafting price; the schematic items' rarity; the alchemy recipes' ingredients and the new alcohol recipes; the recipe and schematic granted at load; the ingredient items' category, rarity, tags and description keys; every item's dismantling parts and the dismantling rule; the dismantle kits; the four craftable quest armors; the master kits' place with the master craftsmen (with LOOT-04).

**Not CRAFT** (porter's call from the docs, for the owner to confirm with DC7):

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
| Dye quality, the junk items' `mod_valuable` tags, the vodka of Hearts of Stone (`Soltis Vodka`, drink abilities) | ECON, FOOD | Found by the sweep: quality and price tags only |
| NG+'s replacement of Blood and Wine's vampire gear (`NewGamePlusReplaceEP2Items`, legacy removed it) | ITEM | Found by the sweep, unattributed: legacy moved that gear to level scaling (ITEM-04) |

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

### Classification and proposed action

| # | Feature | Class | Proposed action |
|---|---|---|---|
| CRAFT-01 | Generic schematics | clean (data), conflict (port form: a DLC cannot override a schematic) | Legacy's data through DC1's form |
| CRAFT-02 | Witcher gear | clean, overlap (6 Wolf schematics) | Legacy's (DC4); 5.x's Netflix schematics per DC2 |
| CRAFT-03 | Runes and glyphs | clean | Legacy's; ends ENCH's schematic hand-off |
| CRAFT-04 | Quest armors | clean | Port whole (ARM audit F1) |
| CRAFT-05 | Crafting prices | clean (inert) | Carry legacy's numbers with the schematics (DC3); no script change |
| CRAFT-06 | Alchemy recipes | clean, conflict (port form) | Legacy's through DC1's form; ends ALCH's recipe hand-off |
| CRAFT-07 | Ingredients | clean | Port through the item layer (DC5) |
| CRAFT-08 | Dismantling | clean, overlap (Cheesecutter) | Port through the item layer; legacy's `RecycleItem` rule |
| CRAFT-09 | Dismantle kits | clean | Port; ends ALCH's, ITEM's and UI's kit hand-offs |
| CRAFT-10 | Master kits | clean | Port with LOOT-04; ends ITEM-11's temporary deviation |

---

### CRAFT-01 Generic gear schematics

| | |
|---|---|
| Kind | content |
| Pillars | P6, P8 |
| 5.x class | clean (data); conflict (port form) |
| Flags | balance, needs-decision (DC1) |
| Depends on | ARM, SWD (the crafted items, signed off), ITEM (level and `DoNotEnhance`), CRAFT-07 (ingredient names), UI-08 (schematic texts) |
| Skill trees | n/a |
| Port form | the schematics in whole-file overrides of the schematic files (DC1): 5.x's files with legacy's entries, `tools/gen_craft.py` (`--verify`), regular and NG+; the schematic items' rarity through the item layer; the Meteorite plate schematic granted once at load (`gm/craft/grants.ws`, a wrapper of `OnSpawned`, fact `gm_craft_recipes_added`); the Midcotts smith's craftsman level in 5.x's entity file, both copies (`gen_loot.py` with LOOT-02's edits of the same file, `cr2w_patch.py`) |
| Port status | **signed off** (2026-10-23); verified (2026-10-22): the whole-file overrides load, each schematic defined once (`GMTest_craft01`); the Meteorite plate schematic crafted at the Midcotts smith, now a Master, in his crafting menu |
| Open checks | a reworked generic schematic crafted in play |
| Save impact | none (expected): schematics are read from the definitions; known schematics are saved by name |
| NG+ counterpart | applied (legacy's NG+ files), untested |

**What it does** (changelist 653–656): human swords, armor, crossbows, bolts, repair kits and crafting materials (ingots, plates) need fewer and more varied common materials: 189 changed schematics need 784 ingredients in all instead of 1,305, only 5 need three or more of one ingredient (1.32: 95), and gems and monster parts are gone from human gear (e.g. a Guard Lvl1 steel sword 3: 1.32's 2 dark iron ingots, a ruby, an amethyst, a monstrous eye and leather straps; legacy's dwimeryte ingot, leather, 2 wire ropes, a haft, amethyst dust). Craftsman levels: 15 schematics move from Journeyman to Master, 8 from Grand Master to Master, 4 from Master to Journeyman. New: crafted versions of the Novigraadan sword 2 and 3, Skellige sword 3 and 4, Scoia'tael sword 1 and 4 and Silver sword 5 (their `_crafted` items exist in 1.32's data without a schematic), and a Meteorite plate schematic (2 Meteorite ingots at a Master crafter) that every save learns once at load. Bolt schematics craft different quantities. Schematic items get rarities matching what they make; the Blood and Wine relic sword schematics lose the witcher-set colour (bugfix 183). The Midcotts blacksmith (Velen) becomes a Master craftsman (binary edit).

**Implementation (legacy):** the `<schematic>` entries and schematic `<item>` entries of `def_item_crafting_recipes.xml` (base, Hearts of Stone, Blood and Wine), `def_item_crafting_recipes_bolts.xml`, regular and NG+; `OnSpawned` (`AddCraftingSchematic('Meteorite plate schematic')` with the fact `ModSignsRecipesAdded`); `midcotts_blacksmith_01.w2ent` (`W3CraftsmanComponent.craftsmanData.level` Journeyman → Master, besides LOOT-02's lists).

**5.x:** the same 1.32 schematics. A DLC cannot override a schematic: the crafting manager reads both definitions (found by ARM-12, [arm.md](arm.md#arm-12-kaer-morhen-set)), and the mod.io guide lists `<crafting_schematics>` and `<alchemy_recipes>` among the entries `on_conflict` does not work on (unverified).

**Decisions:** port legacy's data (legacy behaviour first, 5.x unchanged); the port form waits for DC1.

**Later:** —

### CRAFT-02 Witcher gear schematics

| | |
|---|---|
| Kind | content |
| Pillars | P6, P8 |
| 5.x class | clean; overlap (six Blood and Wine Wolf upgrades) |
| Flags | balance, needs-decision (DC1, DC2, DC4) |
| Depends on | ARM-05 to ARM-11 (the sets, signed off), SWD-04 (school swords), CRAFT-07 |
| Skill trees | n/a |
| Port form | as CRAFT-01 |
| Port status | **signed off** (2026-10-23); verified (2026-10-22, as CRAFT-01) |
| Open checks | a witcher gear upgrade crafted in play |
| Save impact | none (expected) |
| NG+ counterpart | applied, untested (the NG+ files hold more witcher schematics than the regular ones: 294 units against 178) |

**What it does** (changelist 657): every school set's schematics (Feline, Griffin, Ursine, Wolven, the free DLC's Wolf school, Hearts of Stone's and Blood and Wine's witcher gear, the school crossbows) need magical and monster components and 1–2 of each ingredient: 935 ingredients over 173 schematics instead of 1,387, none needing three of one (1.32: 67). Example: Lynx School steel sword upgrade 4 needs the level 3 sword, an orichalcum ingot, a green gold ingot, ruby dust, a monstrous spore and monstrous blood (1.32: 2 leather squares, 2 dwimeryte enriched ingots, a sapphire, monstrous blood). Upgrade schematics consume the previous piece, Blood and Wine's included (1.32 forgot it on six Wolf upgrades). Craftsman levels: 6 schematics from Master to Journeyman, 3 from Master to Grand Master, 1 from Grand Master to Master.

**Implementation (legacy):** the witcher gear `<schematic>` and schematic `<item>` entries of the schematic files, `dlc10_wolf_recipes.xml` (48 schematics, 10 craftsman levels), regular and NG+.

**5.x:** the six Blood and Wine Wolf upgrade schematics (steel and silver sword 4, jacket 4, gloves, trousers and boots 5) consume the previous piece, with 1.32's other ingredients: legacy's version has the same fix, so porting legacy's entries keeps it. 5.x's Netflix set (ARM-15, SWD-10) has 36 new schematics given by `mq1060`: Master (base), Grand Master (tier 1) and Arch Master (tier 2), 4–5 ingredients each, 1–3 of each, a monster part or essence in each (DC2).

**Decisions:** legacy's entries (DC4); 5.x's Netflix schematics wait for DC2.

### CRAFT-03 Rune and glyph schematics

| | |
|---|---|
| Kind | content |
| Pillars | P6 |
| 5.x class | clean |
| Flags | — |
| Depends on | ENCH-16 (runes and glyphs, signed off), CRAFT-07 |
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
| Port status | **signed off** (2026-10-23); verified (2026-10-22): the Hindarfjall heavy armor crafted at Yoana (a spawned Yoana, her crafting menu; the schematic and ingredients given by `gmtest_craft04_give`); its schematics in her master stock after her quest |
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
| Flags | needs-decision (DC3) |
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

**Decisions:** DC3. The script change is not ported (no behaviour).

### CRAFT-06 Alchemy recipes

| | |
|---|---|
| Kind | content |
| Pillars | P6, P8 |
| 5.x class | clean (data); conflict (port form) |
| Flags | balance, needs-decision (DC1) |
| Depends on | ALCH (the brewed items, signed off), CRAFT-07, FOOD (the two alcohol drinks), UI-08 (recipe texts) |
| Skill trees | n/a |
| Port form | the recipes in the whole-file overrides of the recipe files (DC1, `gen_craft.py`); the nekker pheromone's keeps 5.x's `cookedItemType` (ALCH-08's confirmed deviation: the pheromone formulas stay potion formulas) with legacy's ingredients; the two new recipe items through `gen_item.py`; the Tawny Owl 1 recipe granted once at load (`gm/craft/grants.ws`, fact `gm_craft_recipes_added`, with CRAFT-01's grant) |
| Port status | **signed off** (2026-10-23); verified (2026-10-22): the recipes as legacy's and the load-time grants (`GMTest_craft01`, `GMTest_craft06`); Mandrake cordial brewed in the alchemy menu |
| Open checks | a reworked potion brewed in play |
| Save impact | none (expected): recipes are read from the definitions; known recipes are saved by name |
| NG+ counterpart | applied, untested |

**What it does** (changelist 682–683): 118 recipes (99 potions, oils, bombs and mutagen conversions of the base game, 3 alcohol, 14 of Blood and Wine with its dye, 1 of Hearts of Stone, and the Nekker pheromone, whose recipe type is ALCH-08's) need more varied and fewer herbs: 597 ingredients in all instead of 946 (e.g. Mutagen red to green: 4 celandine → 1). Two new recipes brew alcohol, Mandrake cordial (empty bottle, Temerian rye, Redanian herbal, mandrake root) and Mahakam spirit (empty bottle, local pepper vodka, hop umbels, sewant mushrooms); herbalists sell them (LOOT-01). Every save learns the Tawny Owl 1 recipe once at load ("fix missing Tawny Owl recipe": 1.32 and 5.x give it only in the standalone starts).

**Implementation (legacy):** `<recipe>` entries of `def_item_alchemy_recipes_potions/oils/petards/mutagens/alcohol.xml` and the Blood and Wine and Hearts of Stone files, regular and NG+; 2 new recipe items in `def_item_alchemy_recipes_alcohol.xml`; `OnSpawned` (fact `ModSignsRecipesAdded`). `ClearKnownRecipes` only renames a local (nothing to port).

**5.x:** unchanged, plus 5.x's quest recipe Signs Enhancement (kept: ALCH's DL10). The Mutation Catalyst's recipe is MUT-12's (ported).

**Decisions:** port as legacy through DC1's form; ends ALCH's recipe hand-off.

### CRAFT-07 Ingredients

| | |
|---|---|
| Kind | content |
| Pillars | P6, P7 |
| 5.x class | clean |
| Flags | — |
| Depends on | CRAFT-08 (the same entries), UI (rarity colours, the crafting menu) |
| Skill trees | n/a |
| Port form | the ingredient items' `category`, `base_abilities`, tags (not `mod_*`), `localisation_key_description` and `grid_size` through the item layer (DC5): `item_layer.py`'s CRAFT fields, written by `gen_item.py` (no other tool writes ingredients) |
| Port status | **signed off** (2026-10-23); verified (2026-10-22, `GMTest_craft07`; the inventory's crafting and alchemy tabs seen); the two alcohols verified 2026-10-22 (5.x-GM `9b8e16a3`: `GMTest_craft07`, a potion refilled with the vodka and refused with the lemon, `gmtest_craft07_refill`); the lemon's drink abilities stay 5.x's until FOOD (porter's call, confirmed by the owner, 2026-10-23) |
| Open checks | the crafting and alchemy menus list each moved ingredient on the right tab |
| Save impact | none (expected): item definitions are read live (ARM-01 verified this for item fields) |
| NG+ counterpart | applied, untested |

**What it does:** sorts ingredients for crafting with the reworked recipes: 12 alchemy ingredients become crafting components (monster hides and skins such as Necrophage skin, Troll skin, Werewolf pelt), 23 crafting components become alchemy ingredients, 19 become junk and one junk item a component (Haft); rarities reworked so the crafting menu's colours match (bugfix 120: e.g. 54 Magic → Relic, 26 Relic → Magic, hardened leather and timber Magic → Master); description keys follow the new category; 36 grid sizes change. Local pepper vodka becomes the alchemy ingredient potions are refilled with (`StrongAlcohol`, "alcohol for crafting and refilling") and Free nilfgaardian lemon, which 1.32 had in that role, a drink. Price tags (`mod_valuable`, `mod_precious`) are ECON's.

**Implementation (legacy):** about 190 `<item>` entries of `def_item_ingredients.xml` (base, Hearts of Stone, Blood and Wine), the two alcohols in `def_item_edibles.xml` (attributed after the [audit](#craft-and-loot-audit-2026-10-22), F3), regular and NG+.

**5.x:** unchanged.

**Decisions:** port as legacy.
- **Deviation:** Free nilfgaardian lemon gets legacy's category, description and tags, but its drink abilities stay 5.x's (`item_layer.KEEP_5X`): the drink's effect is FOOD's ([audit](#craft-and-loot-audit-2026-10-22) F3; temporary, until FOOD; porter's call, confirmed by the owner, 2026-10-23).

### CRAFT-08 Dismantling

| | |
|---|---|
| Kind | content, system |
| Pillars | P6 |
| 5.x class | clean; overlap (Cheesecutter) |
| Flags | balance, needs-decision (DC4, DC5) |
| Depends on | every item area (ARM, SWD, ALCH, ITEM, UI: the entries), CRAFT-07 |
| Skill trees | n/a |
| Port form | the `<recycling_parts>` blocks through the item layer (DC5, `item_layer.apply_item`): `gen_arm_items.py`, `gen_swd_items.py` and `gen_ench.py` apply them to the entries they write, `gen_item.py` writes every other item CRAFT changes (5.x's entry with ITEM's and CRAFT's fields), the razor's in `gm_ui.xml` by hand; `@replaceMethod CInventoryComponent.RecycleItem` (legacy's rule, `gm/craft/dismantling.ws`); strings 2110992257, 2110992258, 2110992260 (legacy's rows) |
| Port status | **signed off** (2026-10-23); verified (2026-10-22): a Guard armor dismantled at a Journeyman armorer (the White Orchard smith, spawned) in his Dismantle menu gave every part, 2 of each; after the [audit](#craft-and-loot-audit-2026-10-22) (F1, F2; 5.x-GM `9b8e16a3`) the Grave Hag ear and the starting armor and boots dismantled there too (a Monstrous ear; leather and linen; leather squares) |
| Open checks | — |
| Save impact | none (expected) |
| NG+ counterpart | applied, untested |

**What it does:** dismantling returns far fewer parts and nothing from things that are not gear or materials. Armor, weapons and crafted gear yield 1–3 simple parts (e.g. a Guard Lvl1 armor: 1.32's 5 linen, 2 leather straps, 4 thread, 6 dark iron ingots and 3 silk; legacy's 1 silk and 1 leather; a Lynx armor 4: a shirt, hardened leather, draconide infused leather); ores and minerals refine into fewer (Nickel ore: 5 → 2 minerals; 39 minerals and refined ingredients yield nothing); quest items (629), keys (88), Blood and Wine's notes (124) and decorations (60) yield nothing (1.32: a silver ingot from a victim's handkerchief); runes and glyphs yield one infused dust; the 27 named mutagens of the base game and Blood and Wine's Protofleder mutagen yield a lesser mutagen of their colour (changelist 692–693), a source of lesser mutagens now that monsters no longer drop them (LOOT-06). Any craftsman returns every part (1.32: a Journeyman one of each, a Master a random share, only a Grand Master all); parts from the player's own dismantling are not marked new. Two junk descriptions say "Can be sold to merchants or dismantled" (vanilla keys overridden); "Crafting components" (2110992257) is in legacy's table but no script reads it.

**Implementation (legacy):** `<recycling_parts>` of about 2,000 items across all item files (1,958 regular units, 2,115 NG+), `CInventoryComponent.RecycleItem`, 3 strings × 9 languages.

**5.x:** `RecycleItem` unchanged; Cheesecutter also yields a Cheese (DC4). 5.x's new items keep 5.x's parts. Each item is defined once ([tools.md](../tools.md), `gen_item.py`): the item tools that write an entry apply CRAFT's fields to it (`item_layer.apply_item`), `gen_item.py` writes the rest; `gen_arm_km.py` (ARM-12's starting gear) does not yet ([audit](#craft-and-loot-audit-2026-10-22) F2).

**Decisions:** port as legacy (DC4 for Cheesecutter, DC5 for the technique).

**Later:** legacy's parts of Knight Geralt Pants 3 and Knight Geralt A Pants 3 name "Silver Ingot" (the item is "Silver ingot"), carried as legacy's; if the game matches item names by case, that part is never given, in legacy too ([audit](#craft-and-loot-audit-2026-10-22) F9).

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
| Port status | **signed off** (2026-10-23); verified (2026-10-22): the E Dismantle prompt in the inventory on a junk item, a crafting component and an alchemy ingredient (selected with real keys); the dismantle through the inventory's primary-action input (`gmtest_menuinput`) and with each kit (`gmtest_craft09_menu`) |
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
| Depends on | ITEM-11 (the kits, signed off), LOOT-04 (the four shop lists) |
| Skill trees | n/a |
| Port form | `@addMethod CInventoryComponent.GMAddMasterArmorerItems` (legacy's body), called by a wrapper of `CInventoryComponent.AutoBalanaceItemsWithPlayerLevel` for an inventory whose entity has the tag `sq108_blacksmith_woman` (legacy's call sat right before it in the storyscene function `ShowMeGoods`, which stays 5.x's; the function's only other caller is a container's), `gm/craft/masterKits.ws`; the shop entries with LOOT-04 |
| Port status | **signed off** (2026-10-23); verified (2026-10-22, with LOOT-04): Hattori's shop stocks the master weaponsmith tools; Yoana's shop stocks her master list after her quest's fact and a master armorsmith kit was bought from it; ITEM-11's temporary deviation ended |
| Open checks | the Hearts of Stone enchanter (LOOT-04: his list never reaches the kits) |
| Save impact | none (expected); the shop lists are rolled when a merchant restocks |
| NG+ counterpart | applied, untested |

**What it does** (changelist 611, 633): the master weaponsmith tools (`weapon_repair_kit_4`) are sold by Hattori, the master armorsmith tools (`armor_repair_kit_4`) by Yoana after her quest (`sq108_master_bsmith_helped`; she then also sells legacy's master stock, with CRAFT-04's schematics), and both by the Hearts of Stone enchanter and Blood and Wine's archmaster smith. Ends ITEM-11's deviation ("no shop sells the master kits", temporary until CRAFT and LOOT).

**Implementation (legacy):** `CInventoryComponent.AddMasterArmorerItems`, its call in `ShowMeGoods`; entries in `_store__Hattori_Master_Blacksmith`, `_store__Master_Armorsmith_Yoana`, `_store__LW_DLC_EnchanterMaster`, `_EP2_store_archmaster` (LOOT-04).

**5.x:** none.

**Decisions:** port as legacy (DI6 left it to CRAFT and LOOT). Yoana's master list is added each time her shop opens, as legacy (confirmed by the owner, 2026-10-21).

---

### CRAFT and LOOT audit (2026-10-22)

One shared audit of both areas (the [LOOT audit](loot.md#loot-audit-2026-10-22) points here). Done by a fresh session ([audit](../feature-mapping.md#audit-signing-a-feature-off)) on 5.x-GM `ccab873f` and master `e0173a00`, reading code and data; no game run (every finding is plain in the data or code; the regression's 804 passed, 0 failed in each tree is the port's record, nothing was changed since). Every script unit [attribution.csv](attribution.csv) gives CRAFT or LOOT (20) was read against legacy's code (`legacy-GM`), 1.32 and 5.x. The final data as the game reads it was compared with legacy's by scripts written for this audit, independently of the generators' `--verify`: every `<schematic>`, `<recipe>`, `<loot>` and `<reward>` entry of every XML file in the four branches (5.x-GM's files, the overrides included, against `master`, `legacy-GM`, `vanilla-5.x`; entries parsed into trees, comments dropped, attribute order ignored, entry order kept); every item's CRAFT fields (recycling parts, category, description key, grid size, quality, tags other than `mod_*`, `base_abilities`) of legacy against the port's effective item (Ghost Mode's DLC entry, else 5.x's from a full extraction of 5.x's gameplay XML, `extract_vanilla.py`), both folders; every item name the lists, rewards, schematics, recipes and parts reference against the items the game defines; the `cr2w_dump` facts of all 630 entity files legacy changed (loot objects: `CR4LootParam`, `W3CraftsmanComponent`, the inventory classes), legacy's change against 1.32 compared with the port's change against 5.x; the 72 CRAFT string rows in nine languages.

**Checked and holding:** schematics, recipes, loot lists and rewards: 2,261 entries legacy changed are legacy's in the port; 3,224 legacy did not touch are 5.x's; the 162 entries only 5.x has (the Netflix schematics' file is not overridden; 5.x's new loot lists, Signs Enhancement) are unchanged, and outside their entries the 62 overridden files are 5.x's word for word. No schematic or recipe name is defined twice across the game's files and Ghost Mode's DLC (5.x: none either). All 78 reworked rewards give legacy's items; their experience, level and gold stay 5.x's (XP: 547 and 193 rewards, ECON: 186). The differences by design: the 27 cooking recipes and their shop entries (FOOD, LOOT-01's deviation), the Kaer Morhen, Mutation Trigger and enchanter word schematics (ARM-12, MUT-12, ENCH-02, in the DLC), the pheromone recipes' type (ALCH-08), and F4. The six Blood and Wine Wolf upgrades, Cheesecutter (DC4) and the NG+ Nickel ore schematic (5.x fixed the same typo legacy fixed) are legacy's. Items: 4,164 recycling-part comparisons and every category, description key, grid size, quality, tag and ability change of CRAFT's units are legacy's, apart from F1 to F3; the other differences are other areas' (ARM's set tags, FOOD's edibles, ALCH's DL9 oil tag). Binary: of the 630 entity files legacy changed, exactly the 211 the port patches carry loot edits; in 209 the port's change equals legacy's fact for fact, the Midcotts smith differs only in the size of his embedded compiled copy (names appended), and the sq106 ekimma only in an inventory component's editor graph position legacy moved (not ported, editor-only); no other property of a patched file changed. Scripts: `RecycleItem`, the dismantle kits (legacy's conditions; none of the 279 kit-dismantlable items is also a dye, painting, book, upgrade, repair kit, oil, food or drink, so the wrapper acting before the inventory's other primary actions changes nothing), the load-time grants, Yoana's master stock (legacy's order: her list queued before the shop's balancing), the Balisse fix, and the four standalone functions and two timers (legacy's bodies plus 5.x's one-line change, F8). The 72 string rows equal legacy's. Owner's decisions as implemented: DC1 to DC7, DT1 to DT7, DT9, QT1, QT2 and the eight confirmations hold; DT8 see F4. ITEM-11's temporary deviation is ended; the only deviation left "until" another area is LOOT-01's (until FOOD). `check_modsigns.py` 0 unmarked (397 bodies); `deviations.py --check` current (after this audit's edits, regenerated); every generator's `--check` current (`gen_craft`, `gen_loot`, `gen_item`, `gen_arm_items`, `gen_swd_items`, `gen_ench`, `gen_alch`, `gen_arm_km`, `gen_arm_new`, `gen_ngplus`, `gen_npc_stamina`); `gen_craft`, `gen_loot` (XML and binary), `gen_item`, `gen_arm_items`, `gen_swd_items`, `gen_ench`, `gen_alch` `--verify` 0 unexplained. `unit_sweep.py --unattributed` (recycl, dismantl, schematic, loot, merchant, reward, ingredient, recipe, craft, standalone, shop): no CRAFT or LOOT script unit missing (the hits are other areas': `FixQuestItems`, `OnGiveReward`, `CookItem`, `addrecipesedibles`, the new-game menu).

**Findings:**

1. **The Grave Hag ear dismantles into nothing** (clear fix). Legacy gives it a Monstrous ear (`legacy-GM` `gameplay/items/def_item_ingredients.xml:2563`, the block uncommented); 1.32 and 5.x have the block commented out (`master` same file `:4791`). `item_layer.block_of` (`tools/item_layer.py:223`) also matches blocks inside comments, so `merge_blocks` wrote legacy's block inside 1.32's comment (`gm_item.xml:15490`, both folders), and `gen_item.py --verify` compares with the same blind spot. The only such item in the comparison. Fix: `block_of` skips commented text, `--verify` too; regenerate; a check in `GMTest_craft08`. **Resolved** (5.x-GM `9b8e16a3`): `item_layer.block_of` ignores blocks inside comments (used by the item tools and `gen_item.py --verify`); regenerated, no other item changed; verified in game (below).
2. **Geralt's starting gear dismantles into 1.32's parts** (clear fix). Starting Armor, Boots, Gloves and Pants (both folders) yield 1.32's parts (the armor: 2 linen, leather, 2 leather squares, 2 leather straps, 2 iron ore) instead of legacy's (leather and linen; `legacy-GM` `gameplay/items/def_item_armor.xml:355`). Their units carry ARM-12 only, and `gen_arm_km.py`, which writes them whole (`gm_arm_kaer_morhen.xml:882`), applies no CRAFT field, so neither ARM's port nor CRAFT-08's caught them (ARM handed armor parts to CRAFT). Fix: add CRAFT-08 to the eight units and apply `item_layer.apply_item` in `gen_arm_km.py`. **Resolved** (5.x-GM `9b8e16a3`): as proposed; the armor gives leather and linen, the boots leather squares, the gloves 2 leather straps, the pants linen and leather squares; verified in game (below).
3. **Local pepper vodka and Free nilfgaardian lemon keep 1.32's roles** (clear fix). Legacy made Local pepper vodka an alchemy ingredient with `StrongAlcohol` (the alcohol potions are refilled with, `TAG_ALCHEMY_REFILL_ALCO`, and an ingredient of the Mahakam spirit recipe, sold by legacy's general traders as such) and the lemon, which 1.32 had as that alcohol, a drink (`legacy-GM` `gameplay/items/def_item_edibles.xml:104`, `:1514`, comment "alcohol for crafting and refilling"). The four units (both folders) are unattributed (`units.csv`), so the port keeps 1.32's: the vodka is a drink that cannot refill potions and the free lemon refills them. Brewing the Mahakam spirit works either way (recipes match by name). Fix: attribute the vodka to CRAFT-07 and the lemon to CRAFT-07 and FOOD (the drink's quality is FOOD's), carry category, description key, tags and abilities through the item layer, a check in `GMTest_craft07`. **Resolved** (5.x-GM `9b8e16a3`): both units attributed to CRAFT-07 (the notes name FOOD's, ECON's and WGT's parts); the vodka gets legacy's category, description, kind tags and no drink abilities; the lemon legacy's category, description and tags, its drink abilities stay 5.x's until FOOD (`item_layer.KEEP_5X`; porter's call, confirmed by the owner, 2026-10-23); price, `mod_*` tags and weight stay 5.x's (ECON, WGT). Verified in game (below).
4. **DT8 holds on 4 of the 17 quest lists, not 13** (clear fix; no behaviour change expected). 5.x rewrote the opening tag of all 322 base-game quest lists (`respawn_time="0"` added, `chance="100"` dropped, `player_level_max` 100 → 0, i.e. no cap). Where legacy changed a list's own attributes (13 lists, its quantity, e.g. `q002_yennefer_notes` 1 → 2 for an added note), `gen_loot.py` (`merged`, `:150`) takes legacy's whole tag, so 5.x's cleanup is lost there; the owner's DT8 asked for 5.x's attributes with legacy's items. Fix: 5.x's tag with only the attributes legacy changed. **Resolved** (5.x-GM `9b8e16a3`): `gen_loot.py` (`head_merged`) writes 5.x's tag with the attributes legacy changed against 1.32, for every list; the 13 quest lists now carry 5.x's attributes with legacy's quantity (the four `loot_include_smith_*` shop lists change only in whitespace); the rule applies to every list legacy changed, not only the 17 quest lists DT8 named (porter's call, confirmed by the owner, 2026-10-23); `--verify` 0 unexplained; verified in game (below).
5. **The NG+ swap of Blood and Wine's vampire gear was handed to ITEM and never placed** (clear fix; ITEM's, signed off). Legacy stops `NewGamePlusReplaceEP2Items` from swapping the q702 vampire armor, gloves, pants, boots and steel sword for their NG+ copies (`legacy-GM` `playerWitcher.ws:1498`–`1530`, five lines commented out): ITEM-04 put that gear on level scaling. CRAFT's mapping found the unit unattributed and handed it to ITEM after ITEM's sign-off; the port does 5.x's swap. Fix (NG+ policy: carried, not tested): attribute it to ITEM-04, `@replaceMethod` without the five swaps in ITEM's `gm/items/itemScaling.ws`, beside `NewGamePlusReplaceEP1`. **Resolved** (5.x-GM `9b8e16a3`, compiles; NG+ untested by policy): as proposed, recorded in [ITEM-04](item.md#item-04-armor-and-damage-by-item-level).
6. **The 62-kind roll limit reaches far beyond the enchanter** (owner decision, widens the open one). In the port, 46 shop lists have more than 62 entries; 417 entries legacy added to them lie past the 62nd, among them the Oxenfurt herbalist's Alchemy dismantle kit, the alcohol recipes at Guslar, Kaer Trolde and the Novigrad, Velen and Skellige herbalists, the Druid's pheromone and potion recipes, 47 of the Master Alchemist's recipes (his list has 276 entries, not 1.32's 207), the bolts of Blood and Wine's smiths, grandmaster and archmaster, and most of legacy's food and alcohol at Skellige's traders and Velen's market trader. If a real restock caps a list as the test roll does (the test calls the same balancing function, `gmTestsLoot.ws:97`), none of them is ever stocked, except where level gates skip earlier entries. 1.32's own lists exceed 62 too (Toussaint's alchemist: 225). Options: (a) keep legacy's order everywhere (legacy first; if 1.32 had the cap, legacy played this way); (b) reorder legacy's additions into each list's first 62 (a deviation over 46 lists); (c) move only the kits (the enchanter's master kits, Oxenfurt's dismantle kit). Recommendation: (a) until two checks: the cap on a real merchant with a long list in the port (Oxenfurt's herbalist), and in legacy. **Checked in game (2026-10-22): a real restock is not capped**, so no list misses its late entries and nothing needs deciding. A merchant spawned from its entity file and restocked from its own lists (as `ShowMeGoods` does, and again after `wait(3)` game days, three times) stocked every entry it may sell at Geralt's level: the Whitebridge herbalist (`whitebridge_herbalist_01.w2ent`, `_store__Oxenfurt_Herbalist`, 94 entries) 79 kinds each time, legacy's five entries past the 62nd among them (the Alchemy dismantle kit, Mahakam spirit, Mandrake cordial, blasting powder, black pearl dust); the Master Alchemist (`master_alchemist_gremista.w2ent`, 276 entries) 185 kinds, up to the list's last entry; the Hearts of Stone enchanter (`enchanter_01_lvl_3.w2ent`; `enchanter_01_lvl_0` has no shop) 120 kinds with both master kits, also after a restock. The entries missing are the level-gated ones and the recipes and schematics Geralt knows. The 62-kind limit belongs to a list queued with `AddItemsFromLootDefinition`, which the test roll uses (`GMTestLootRoll`); a shop's restock does not (the one queued list a shop uses, Yoana's master list, has 18 entries). The calls and the balancing are native in 1.32 and 5.x alike (`BalanceItemsWithPlayerLevel`, `AddItemsFromLootDefinition` and `UpdateLoot` are imports), so the scripts hold no cap. The legacy check is no longer needed. Test texts corrected: 5.x-GM `8f93e1d4`.
7. **A tag legacy added to a Hearts of Stone note is not CRAFT's** (no action for CRAFT; doc correction, made). `ep1_poi_12_note_b` gets `QuestEP1` in legacy (the expansion's quest-item label); the unit carries CRAFT-08 for its parts, and the tag belongs with legacy's `FixQuestItems` (`gm_bugfixes.ws`, which handles the same note), unattributed. Added to the [hand-off](#hand-off-to-other-areas) table.
8. **LOOT-09 keeps a 5.x change without a recorded deviation** (doc correction, made). 5.x's `StandaloneEp1_2` and `StandaloneEp2_2` no longer activate the Focus Clues tutorial entry; legacy's (1.32's) did. The port merged legacy's changes into 5.x's bodies, as DT6 says. Recorded as a deviation under DT6 in [LOOT-09](loot.md#loot-09-standalone-starts); [deviations.md](deviations.md) regenerated.
9. **Legacy misspells a part of the Toussaint knight pants** (no action; Later). Knight Geralt Pants 3 and Knight Geralt A Pants 3 yield "Silver Ingot" in legacy (`legacy-GM` `dlc/bob/.../def_item_crafting_pants.xml:666`, `:711`; the item is "Silver ingot"), carried as legacy's. Whether the game matches item names regardless of case is unknown; if not, the pants yield nothing for that part in legacy and the port alike. Noted under CRAFT-08's Later.
10. **Stale texts** (doc corrections, made). CRAFT-08's 5.x paragraph still said the item entries carry 5.x's parts "until CRAFT adds its field"; the port state named `gen_alch.py` among the tools applying CRAFT's fields (it writes no CRAFT field; its three oils have no parts); loot.md said 5.x changed "17 quest lists" (it rewrote 322; 17 are legacy's), without `player_level_max`; LOOT-09's 5.x line did not name 5.x's change; the open question on the enchanter's kits gave the Master Alchemist 1.32's 207 entries; ITEM-11's decision still said no merchant sells the master kits; the status page's area table and narrative still said CRAFT and LOOT wait for the owner's area decisions.
11. **Regression gaps** (clear fix). Nothing checks an item whose 1.32 parts are commented out (F1), the starting gear's parts (F2), the vodka's and lemon's category and refill tag (F3), or a quest list's attributes (F4). The patched entity files are checked only by hand (spawning merchants and monsters repeatedly crashed the game, 2026-10-22): no action there. Fix: the checks with slices A and B. **Resolved** (5.x-GM `9b8e16a3`): `GMTest_craft08` (the Grave Hag ear, the four starting pieces), `GMTest_craft07` (the vodka and the lemon), `GMTest_loot07_lists` (two quest lists roll legacy's quantity), all in the regression; `gmtest_craft07_refill` by hand.
12. **Not verified in game** (no action; open checks). As the entries list them: a real E key press, the crafted armors on the armor stand, a witcher upgrade or a rune crafted in play, a merchant met after a restock, the Master Alchemist, a standalone start from the main menu, the Kaer Morhen battle's Wild Hunt swords, whether 5.x still has the Balisse bug.

**Doc corrections made with the audit:** F7 (the [hand-off](#hand-off-to-other-areas) table), F8 ([LOOT-09](loot.md#loot-09-standalone-starts), [deviations.md](deviations.md)), F9 (CRAFT-08's Later), F10 (CRAFT-08's 5.x paragraph, the [port state](#port-state-2026-10-22), loot.md's 5.x summary, table and LOOT-07, LOOT-09, [open-questions.md](../open-questions.md#to-test-in-legacy-ghost-mode), [item.md](item.md#item-11-repair-kits-and-master-kits) ITEM-11, the [status page](README.md#where-the-port-stands)).

**Not reviewed:** nothing of CRAFT or LOOT. Out of scope: the enchanter's word schematics (ENCH-02, audited there), the item fields of other areas, NG+ in game (the policy).

**Suggested fix slices** (each touching distinct files):

- **A, item data** (`tools/item_layer.py`, `tools/gen_arm_km.py`, `docs/features/attribution.csv` rows for F2, F3 and F5, the regenerated `gm_item.xml` and `gm_arm_kaer_morhen.xml` in both folders, `tests/gmTestsCraft.ws`): F1, F2, F3 and their checks (F11). No save impact (definitions are read live).
- **B, quest list attributes** (`tools/gen_loot.py`, the regenerated `gameplay/items/def_loot_quests.xml`, `tests/gmTestsLoot.ws`): F4 and its check.
- **C, NG+ vampire gear** (`gm/items/itemScaling.ws`): F5, compiles; NG+ untested by policy.
- **Owner decisions:** F6 (with the open LOOT-04 decision): none needed, a real restock is not capped.

**Fixes verified** (2026-10-22, 5.x-GM `9b8e16a3`, test save, Geralt level 1): regression 812 passed, 0 failed in each skill tree (the new checks read item definitions and roll lists, the same in both trees). Dismantling at a real smith: a spawned White Orchard smith (Journeyman armorer), his Dismantle menu opened as the scene does, the Grave Hag ear, a Starting Armor and Starting Boots (given by script; the worn pieces kept) dismantled through the menu's dismantle event (scripted click): a Monstrous ear; leather and linen; leather squares. The refill: a Swallow emptied by script, then `SingletonItemsRefillAmmo` (what meditation and the alchemy menu call): with only the lemon it refuses and the lemon stays; with the vodka the Swallow is full and the vodka used (`gmtest_craft07_refill`, scripted call). Quest lists: rolled into the test merchant (`GMTest_loot07_lists`). Not tested: NG+ (F5).

#### Audit close-out

Closed 2026-10-23: every finding is fixed, recorded or decided by the owner. Fixed and verified (5.x-GM `9b8e16a3`, 2026-10-22): F1 to F4 and F11 (fix slices A and B: the Grave Hag ear's part, the starting gear's parts, the vodka's and lemon's roles, DT8's list header, their regression checks); F5 (fix slice C, ITEM's NG+ vampire gear: compiles, NG+ untested by policy). Answered in game: F6 (a real merchant's restock is not capped at 62 kinds; nothing to decide; test texts 5.x-GM `8f93e1d4`). Recorded: F7 to F10 (doc corrections made with the audit), F12 (the open checks, in the entries). Confirmed by the owner (2026-10-23): the lemon's drink abilities stay 5.x's until FOOD ([CRAFT-07](#craft-07-ingredients), a temporary deviation), and DT8's header rule (5.x's list header plus only the header values legacy changed) for every loot list legacy changed ([LOOT-07](loot.md#loot-07-quest-loot-and-rewards)). Checks at close: regression 812 passed, 0 failed in each tree; `deviations.py --check` current; no CRAFT or LOOT deviation left unconfirmed (`python tools/deviations.py --unconfirmed`); the only deviations left "until" another area are FOOD's (LOOT-01's cooking recipes, CRAFT-07's lemon). No owner decision is left open. What stays open after the sign-off: the open checks listed in the entries (among them a real E key press, the crafted armors on the armor stand, a witcher upgrade or a rune crafted in play, a merchant met in play after a restock, a standalone start from the main menu, the Kaer Morhen battle's Wild Hunt swords, the Balisse bug in 5.x, NG+). CRAFT and LOOT are **signed off** by the project owner (2026-10-23).

---

### Dependencies on other areas

- **Done areas CRAFT builds on:** ARM (the armor entries and `gen_arm_items.py`, ARM-12's schematic technique and its finding that a DLC cannot override a schematic), SWD (`gen_swd_items.py`), ALCH (`gen_alch.py`), ITEM (`item_layer.py`, `gen_item.py`, ITEM-11's kits), ENCH (runes and glyphs, ENCH-18's carry-over), UI (UI-08's recipe texts, UI-15's inventory wrappers).
- **Areas CRAFT waits for or shares with:** LOOT (where everything is sold and found; CRAFT-10 with LOOT-04), ECON (item prices and the crafting and dismantling fees), WGT (weights), FOOD (cooking, the two alcohols), XBOW (bolt and crossbow stats).

### Hand-offs received

Every item other areas handed to CRAFT, and where it lands:

| From | Item | CRAFT |
|---|---|---|
| ARM (hand-off) | Dismantling parts of armor items (448) | CRAFT-08 |
| ARM (hand-off) | Witcher gear schematics and their costs (about 180 units, Kaer Morhen excepted) | CRAFT-02, CRAFT-05 |
| ARM (hand-off) | Mastercrafted kits (`AddMasterArmorerItems`, master repair kits) | CRAFT-10 (the kits' effect is ITEM-11) |
| ARM audit F1 (owner, 2026-10-18) | The four craftable quest armors, whole: items, abilities, schematics, shop entries, armor-stand looks | CRAFT-04 (the shop and loot entries with LOOT-04, LOOT-05) |
| ENCH (hand-off) | Rune and glyph schematics (base and Hearts of Stone), Runestone and Glyph infusion items | CRAFT-03 (their schematics), CRAFT-08 (their parts); prices ECON, weights WGT |
| ENCH (hand-off) | 5.x's enchantment carry-over on crafting | ENCH-18 (kept, DE4): nothing left for CRAFT |
| SWD (hand-off) | Dismantling parts of swords | CRAFT-08 |
| SWD (hand-off) | Sword schematics, the NG+ Wolven schematics | CRAFT-01, CRAFT-02 |
| SWD (hand-off) | Mastercrafted weapon kits | CRAFT-10 |
| SWD (hand-off) | The Blood and Wine relic schematics' colour fix (bugfix 183) | CRAFT-01 (schematic item rarity) |
| ITEM (hand-off) | The two dismantle kits, their abilities and strings | CRAFT-09 |
| ITEM (hand-off) | Repair kit schematics | CRAFT-01 |
| ITEM-11 deviation (until CRAFT and LOOT) | No shop sells the master kits | CRAFT-10 with LOOT-04 (ends it) |
| ALCH (hand-off) | Recipe ingredients (117 recipes) | CRAFT-06 (118 with the Nekker pheromone's) |
| ALCH (hand-off) | The new alcohol recipes (with FOOD) | CRAFT-06 |
| ALCH (hand-off) | The Alchemy dismantle kit, `PlayerDismantleItem`, the dismantle input | CRAFT-09 |
| ALCH (hand-off) | Named mutagens dismantled into lesser ones (27 mutagens' `recycling_parts`) | CRAFT-08 (28 with Blood and Wine's Protofleder mutagen) |
| ALCH (hand-off) | The missing Tawny Owl recipe granted on load | CRAFT-06 |
| ALCH (hand-off) | Quest items' recycling parts | CRAFT-08 |
| ALCH (hand-off) | `def_item_ingredients.xml` category, recycling and quality changes | CRAFT-07, CRAFT-08 |
| ALCH (hand-off) | Recipe prices | ECON (passed on) |
| UI (hand-off) | Dismantling (`PlayerDismantleItem`, the inputs, strings 2110992257, 258, 260, 330–334) | CRAFT-08 (257, 258, 260), CRAFT-09 |
| UI (hand-off) | The crafting components' rarity colours (bugfix 120) | CRAFT-07 |
| UI (hand-off) | The razor's parts | CRAFT-08 |
| STAM (hand-off "ITEM, CRAFT") | Stamina regen removed from random magical items | ITEM-06, ITEM-07 (ported): nothing for CRAFT |
| feature-mapping (roadmap) | The `CRAFT` area | this file |

### Hand-off to other areas

| Area | Changes |
|---|---|
| LOOT | Where schematics, recipes, ingredients and kits are sold and found; the master stock lists (LOOT-04 with CRAFT-10); the four quest armors' schematic sources |
| ECON | Item, schematic-item and recipe-item prices (their price-only units left unattributed), `mod_*` price tags on ingredients and junk, the `mod_craftitem`, `mod_disassemble` and `mod_removeupgrade` factors (ENCH-02 edits the same file copy), dye quality (BaW's dyes lose their Magic rarity) |
| WGT | Weights of items, kits, ingredients and herbs |
| FOOD | The 27 cooking recipes and their items, `EACIT_Edibles` and its type functions, `W3AlchemyManager.CookItem` (cooked quantity), `addrecipesedibles`; the two alcohols' drink effects; the Hearts of Stone vodka's drink abilities |
| XBOW | Bolt and crossbow stats (the bolt schematics are CRAFT-01); the quest bolt's `mod_nosale` tag fix |
| ITEM | `NewGamePlusReplaceEP2Items` (legacy no longer swaps Blood and Wine's vampire gear for its NG+ copy), found by the sweep, unattributed; ITEM was signed off before it: ported with ITEM-04 after the [audit](#craft-and-loot-audit-2026-10-22) (F5, 5.x-GM `9b8e16a3`) |
| Quest-item fixes (`FixQuestItems`, unattributed) | The `QuestEP1` tag legacy adds to the Hearts of Stone note `ep1_poi_12_note_b` (the unit carries CRAFT-08 for its parts only; [audit](#craft-and-loot-audit-2026-10-22) F7) |

### Save impact

None expected for a new playthrough: schematics, recipes, ingredient fields and dismantling parts are read from the definitions when used. Facts for the port and the release notes:
- Known schematics and recipes are saved by name; the Meteorite plate schematic and the Tawny Owl 1 recipe are granted once at load, behind a fact.
- New items: the dismantle kits, the four crafted quest armors and their schematics, the two alcohol recipe items and the Meteorite plate schematic. Removing the mod (unsupported, [save compatibility](../feature-mapping.md#save-compatibility)) leaves them as unknown items.

### Area decisions

**Decided** by the project owner (2026-10-21): DC1 whole-file overrides are fine where needed; DC2 5.x's Netflix schematics kept; DC3 legacy's schematic prices carried (inert); DC4 legacy's six Wolf upgrade schematics, Cheesecutter without 5.x's Cheese; DC5 CRAFT's fields in `item_layer.py`, every item defined once; DC6 every smith returns all parts, as legacy; DC7 the boundary as mapped. The table keeps the questions as they were put.

| DC1 | How to carry the reworked schematics and recipes (CRAFT-01 to CRAFT-06), which a DLC cannot override | (a) Whole-file overrides of the schematic and recipe files: 5.x's files with legacy's entries merged by a generator (`gen_craft.py --verify`), regular and NG+; (b) a DLC with renamed copies and scripts that swap known schematics and recipes (ARM-12's technique, for ~650 entries); (c) a script that rewrites the crafting manager's lists at load | (a): legacy's data exactly, 5.x's own entries (Netflix, Signs Enhancement) kept by the merge, no script; the cost is that another mod changing the same files conflicts with Ghost Mode. The first slice checks the override loads |
| DC2 | 5.x's 36 Netflix schematics (CRAFT-02) | (a) 5.x's lists; (b) rewritten to Ghost Mode's rule (1–2 of each, like the comparable Griffin tiers ARM's DA3 used) | (a): they already need a monster part and mostly 1–2 of each (two need 3 silver ingots); no legacy counterpart |
| DC3 | The schematics' `price` (CRAFT-05), read by no crafting code | (a) carry legacy's numbers with the entries; (b) keep 5.x's | (a): the data equals legacy's at no cost; the fee itself is ECON's (item prices, `mod_craftitem`) |
| DC4 | 5.x's changes to entries CRAFT changes: six Blood and Wine Wolf upgrade schematics, Cheesecutter's Cheese | (a) legacy's entries (the Wolf upgrades keep the previous-piece fix in legacy's version; Cheesecutter yields a dwimeryte ingot and an amber); (b) legacy's with 5.x's Cheese added | (a), legacy first; (b) is a one-line deviation if the owner likes the joke |
| DC5 | Technique for CRAFT's item fields (parts, ingredient fields), since each item is defined once | (a) extend `item_layer.py` with CRAFT's fields (as ITEM did), applied by `gen_arm_items.py`, `gen_swd_items.py`, `gen_alch.py`, `gen_item.py`, plus `gen_craft.py` for the remaining items; (b) a separate DLC file for CRAFT's fields with `extend` | (a): the proven pattern; `extend` on a whole child block (`recycling_parts`) is untested and would collide with the entries given whole |
| DC6 | Dismantling rule (CRAFT-08) | (a) legacy's: every craftsman returns all parts; (b) 5.x's (1.32's) craftsman-level roll | (a), legacy first (5.x unchanged) |
| DC7 | The boundary | As in [Scope](#scope) | Confirm |

### Port order

Proposed, after the decisions; each slice compiles and is verified on its own (no skill is involved, so one tree suffices, with the regression in both):

| # | Slice | Ends |
|---|---|---|
| 1 | The item layer (DC5): CRAFT-07 ingredient fields and CRAFT-08 parts on every item, `RecycleItem`, the junk strings; `gen_craft.py --verify` | ARM's, SWD's, ALCH's, UI's parts hand-offs |
| 2 | CRAFT-09 dismantle kits (given by script for the test; sold with LOOT-01) | ALCH's, ITEM's and UI's kit hand-offs |
| 3 | The schematic files (DC1): CRAFT-01, CRAFT-02 (DC2, DC4), CRAFT-03, CRAFT-05 (DC3), the Midcotts smith, the Meteorite plate grant | ENCH's schematic hand-off |
| 4 | CRAFT-04 the craftable quest armors | ARM's F1 hand-off |
| 5 | CRAFT-06 the alchemy recipes, the alcohol recipes, the Tawny Owl grant | ALCH's recipe hand-off |
| 6 | CRAFT-10 with LOOT's first slice (the master stock lists) | ITEM-11's temporary deviation |

### Port state (2026-10-22)

Every slice is ported and verified in game (2026-10-22, 5.x-GM `f65a8365` data and scripts, `81e3b5bc` binary, `ccab873f` tests and play helpers; pushed). Regression: 804 passed, 0 failed in each skill tree, `GMTest_craft` included.

- **Data:** `tools/gen_craft.py` writes the whole-file overrides of the 12 schematic files and 12 alchemy recipe files that CRAFT changes (5.x's file, legacy's entry for every CRAFT unit, 5.x's own entries kept) and CRAFT-04's armor-stand looks (`gm_craft.xml`); `--verify`: 1,119 units legacy's, 0 unexplained. The item fields through `item_layer.py` (`gen_item.py`, `gen_arm_items.py`, `gen_swd_items.py`, `gen_ench.py`, each `--verify` 0 unexplained; `gen_arm_km.py` for the four starting pieces, [audit](#craft-and-loot-audit-2026-10-22) F2; `gen_alch.py` writes no CRAFT field). The Midcotts smith's craftsman level in both copies of his entity file (`gen_loot.py`, [loot.md](loot.md#port-state-2026-10-22)).
- **Scripts:** `gm/craft/dismantling.ws` (CRAFT-08), `dismantleKits.ws` (CRAFT-09), `grants.ws` (CRAFT-01, CRAFT-06), `masterKits.ws` (CRAFT-10). `check_modsigns.py`: 0 unmarked.
- **Tests:** `tests/gmTestsCraft.ws` (`GMTest_craft` in the regression), `tests/gmTestsPlay.ws` (real NPCs and their menus, see [development.md](../development.md#testing-in-game)).
- **How each check was tested** (2026-10-22, test save, Geralt level 1 unless said): crafting at a real craftsman: a spawned Yoana (her entity file), her crafting menu opened as the dialogue's `ShowCraftingPanel` does, the Hindarfjall heavy armor crafted through the menu's craft event (scripted click; schematic and ingredients given by script), fee 1,177 crowns; a spawned Midcotts smith reads Master and crafts the Meteorite plate (a Master schematic) the same way. Dismantling: a spawned White Orchard smith (Journeyman armorer), his Dismantle menu, a Guard armor dismantled through the menu's dismantle event: all parts, 2 of each (a Journeyman in vanilla returns one of each). The dismantle kit: the inventory opened, the junk axe selected with real arrow keys, the "E Dismantle" prompt seen; the injected E key press did nothing (vanilla's "E Read" on a book neither: a harness limit), so the dismantle ran through the inventory's input event with the same input (`gmtest_menuinput("enter-gamepad_A")`): one kit used, the axe gave its Meteorite ore and Hardened timber. Brewing: Mandrake cordial brewed through the alchemy menu's craft event. Screenshots for the owner: the crafting menu at Yoana, the Dismantle menu, the E prompt.
- **Audit fixes:** the [audit](#craft-and-loot-audit-2026-10-22)'s slices A to C are done (5.x-GM `9b8e16a3`, verified 2026-10-22; F5 compiles, NG+ untested); F6 needs no decision; the audit is closed ([close-out](#audit-close-out)) and CRAFT is **signed off** (2026-10-23). Not tested: the crafted armors on the armor stand, a real E key press, crafting a witcher upgrade or a rune in play.
