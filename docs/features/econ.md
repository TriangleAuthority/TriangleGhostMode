# ECON: prices, money and trade

What things cost and what money Geralt gets: the list price of every item (gear, materials, food, trophies, runes, schematics and recipes), the price tags that tell merchants how to price an item, the merchants' buy and sell factors by merchant type and region, the fees of craftsmen (crafting, repair, dismantling, removing upgrades, adding sockets), how much money merchants have and how fast it comes back, haggling over monster contracts, the gold of quest rewards, and the quest scenes that take or pay a sum. Ghost Mode's changelist has its own section, "Money and economy" (lines 937–945), and touches money in the Crossbow section (line 671), the known issues (lines 20–22), the Enchantments section (line 950, ENCH-02) and the bugfixes (lines 37–38, the generic merchants fix); the mod description's section 4, "Economy, looting and crafting", explains the intent.

**The player-visible texts first.** Legacy's changelist, quoted exactly: "Double randomization in monster hunt price negotiation dialog was removed and now you can get up to 70% more reward if you're lucky. It's still random, but you should be getting about 30% more money overall."; "Prices were significantly reworked."; "Price modifiers were altered, so you are no longer charged an astronomical sum for generic sword or a piece of wood."; "Bolts no longer cost a fortune, you can sell them and buy them for a reasonable price, but you can't dismantle them. Crafting price is roughly the same."; "Enchanter upgrades cost reduced to 3000/6000/9000 crowns for levels 1/2/3 respectively." (ENCH-02); and two known issues legacy did not fix: "Price modifiers for certain Blood and Wine quest are not applied (vanilla bug)." and "Certain merchants in Blood and Wine don't have price modifiers (vanilla bug)." The mod description adds "merchant price modifiers were changed, so items no longer have 400% extra charge;", "negotiating monster contract price can now increase your reward up to 70% (if you're very lucky, average number will be around 30%);" and "rare monster parts cost more than generic alchemy ingredients, so you can kill monsters and sell these ingredients for money." Legacy has no economy options in its menu and no strings of its own on money. The game's own texts involved (decoded from 1.32's and 5.x's `en.w3strings` with `w3strings.py`): the negotiation popup's title "Negotiate" (1066142, `panel_hud_dialogue_title_negotiation`) and the haggling tutorial "Haggling" (1083712), whose text 5.x rewrote: 1.32 "To haggle for a higher reward, choose an amount using … and confirm your choice by pressing … If your counterparty accepts your offer, you've made a deal! If your offer is too high, your counterparty will grow annoyed. Push too hard, and he or she will break off negotiations!", 5.x "To haggle for a higher reward, set your desired amount using … and confirm with …. Demanding too much may annoy your counterparty or end negotiations." (1083713, markup left out); the item tooltip's "Price" (593320); 5.x's shop button "Sell Junk" (1087827, `panel_button_inventory_sell_junk`, a 1.32 string 5.x now uses); Vimme Vivaldi's loan lines "How might I help, friend? Do you need to swap currencies? Or perhaps a small loan at a reasonable rate?" (1135519), "Wanna pay back my loan." (1032416), "Splendid. I see you as even more credit worthy than before." (1032418); the contract names "Contract: The Apiarian Phantom" (1075660, `mh307`) and "Contract: The White Lady" (1072856, `mh308`). Legacy changed none of them.

**What 5.x did in this area** (from `vanilla-5.x`, unverified in game). Next to nothing in what legacy touched: **no item price** changed (every one of the 9,657 item entries 1.32 and 5.x share, 4,754 of them regular, has 1.32's price), no price tag on those items, **`economy_tagmodifiers.csv` is 1.32's** row for row, and the money code is 1.32's (`W3MerchantNPC`, the funds functions and defaults of `CInventoryComponent`, the haggling in `CR4HudModuleDialog`, the crafting fee in `W3CraftsmanComponent.CalculateCostOfCrafting`, the native price functions `GetItemPriceModified`, `GetItemPriceCrafting`, `GetItemPriceRepair`, `GetItemPriceDisassemble`, `GetItemPriceRemoveUpgrade`, `GetItemPriceAddSlot` and their callers), as are the Vivaldi scene, the Hearts of Stone tax quest and the `mh307` scenes (re-save noise only). What 5.x added or moved: **gold in 7 rewards** (Emhyr's payment for Ciri `q110_1b_accepted_emhyrs_reward` 2,000 → 4,000; Hearts of Stone's `q605_mirror_finale_cash` 5,000 → 10,000; the baron's `q107_4_reward_baron` 100 → 150; `q103_06_find_daughter` 50 → 200; and three raises legacy made too: the prologue griffin `q002_3_griffin_dead_reward` 150 → 250, `q304_02_rosa_pays` 50 → 100, `mq0001_01_reunite_brothers` 0 → 25) and 5 new rewards (`sq106_3_hammond_killed_crach` 200, `mq1060_priest_reward` 200, `q504_horse_returned` 15, three `mq1060` schematic rewards without gold); **378 new items** (175 regular) with their own prices at 1.32's scale: the Netflix set (armor, swords and 36 schematics), Dol Blathanna, White Tiger, Vixen, Scarlet Crest, Top Notch and the Fire Horse gear, three Gwent cards, two potions, `mq1060`'s quest items; the shop's **"Sell Junk"** button (`CR4InventoryMenu.OnSellAllJunk`: every junk item sold at the shop's price, as much as the merchant can pay); **transmogrification** with its own fee (`transmogMenu.ws`: 100 crowns × a category factor × a rarity factor, independent of item prices); a fact per Gwent card a merchant has given (`merchant_card_<card>_already_given`); and the guards' toll by difficulty with caps (already the port's legacy rule, DIFF-07). **Nothing in 5.x scales a price by difficulty:** no script reads the difficulty next to a price, a fee, funds or a reward's gold (`OnGiveReward` reads it for experience only, XP's), and the price table has no difficulty column; the only money rule by difficulty is the guards' toll (DIFF-07).

**How legacy Ghost Mode implements it.** Data: the `price` attribute of 3,683 item entries (1,769 regular, 1,914 NG+) and the `mod_*` price tags of 604 (291 regular, 313 NG+), in 164 item files (regular and NG+) of the base game, both expansions and seven free DLCs; 31 of the 33 rows of `economy_tagmodifiers.csv`, two of them ENCH-02's and ported (the shipped file equals legacy's design sheet `design-docs/price_modifiers.csv`); the `gold` of 188 rewards in five `rewards.xml` files. Scripts: `CInventoryComponent`'s default `daysToIncreaseFunds` 5 → 3, `W3MerchantNPC.OnSpawned` (funds set up again below 100 crowns, 1.32: at 0), `CR4HudModuleDialog.OpenMonsterHuntNegotiationPopup` (the haggling range). Binary files: `vimme_vivaldi_default.w2scene` (the loan's repayment), `mq6003_taxes.w2phase` (when the Hearts of Stone tax quest starts), `mh307_01_halflings.w2scene` and `mh307_05_halflings_closing.w2scene` (a fix of the contract's reward name). The native price code is untouched: legacy works through data alone.

Unit lists: [attribution.csv](attribution.csv), mapped from the changelist's sections, the mod description, legacy's design sheet, the other areas' hand-offs, a comparison of every item's price and price tags and every reward's gold in 1.32, legacy and 5.x (`tools/econ_prices.py`, regular and NG+), the price table row by row, a script diff, `bindiff.py` over legacy's binary files and keyword sweeps. **3,935 units carry an ECON feature** (1,108 attributed to ECON alone; ECON added to 2,827 units shared with ARM, SWD, ITEM, CRAFT, FOOD, ALCH, XBOW, AI, ENCH, LOOT and XP): 3 script units, 1,971 XML and 1,928 NG+ XML units (187 rewards and the Vivaldi loan among them), 29 CSV rows, 4 binary files. No unattributed unit left carries a money change. The 193 items legacy added (cooking recipes, the Kaer Morhen set, the master kits, the dismantle kits, ...) are not ECON's: their prices came with their features, and the port has legacy's price for each.

**Status:** all twelve features **ported** and verified by script in both trees (slices E1 to E5, 2026-11-01); the [area decisions](#area-decisions) made and every porter's call confirmed by the owner (2026-11-01). Signed off by the owner (2026-11-02). The open checks that need a save further into the story wait for the owner's playthrough after the first playable version.

## Scope

**ECON covers** item list prices and price tags, the merchants' buy, sell, fee and funds factors, merchants' money and restocking, contract haggling, reward gold and the quest scenes that take or pay money.

**Unchanged by legacy, and by 5.x** (from the data): the price formula itself (native), the funds amounts per merchant class (`SetupFunds`, `IncreaseFunds`, `GetFundsMax`: 200/500/1,000/5,000 at setup and 100/150/1,000/1,000 + 2,500 per restock for poor, average, rich and quick-start merchants), `priceRepair` and `priceRepairMult`, Gwent card prices (legacy changed none; 5.x added three cards at 10, 20 and 50 crowns), potion, oil, bomb and decoction prices, the money in corpses (`def_loot_actors.xml`), bets (`PlaceBet`), the reverse haggling of a price Geralt pays (`OpenLowerPriceNegotiationPopup`), the reputation code (unused in both games).

**Already ported by other areas** (nothing left for ECON):

| Subject | Ported by | What |
|---|---|---|
| The enchanter's upgrades (3,000/6,000/9,000 crowns, three Hearts of Stone scenes and `mq6005_enchanter.w2phase`'s 3,000-crown condition), the `mod_enchantment` and `mod_removeenchantment` rows | ENCH-02 (signed off) | `economy_tagmodifiers.csv` is already a whole-file override in the port: ECON edits the same copy |
| The guards' toll (a quarter of Geralt's money on every mode) | DIFF-07 (signed off) | `difficulty/guards.ws` |
| Experience for bribes and dialogue payments (5 XP) | XP-06 (signed off) | |
| Bolts sellable (`mod_nosale` off twelve bolts, the quest bolt's `mod_nosalem` fixed) | XBOW-03 (signed off, PB3: "at 5.x's prices until ECON") | the tags; their prices are ECON-01's |
| Crowns in loot lists (containers, chests, ore veins) | LOOT-06 (signed off) | whole lists from legacy, their `Crowns` entries included |
| The standalone starts' money (Hearts of Stone 4,000, 1.32 40,000; Blood and Wine 5,000, 1.32 20,000) | LOOT-09 (signed off) | `loot/standalone.ws` |
| The crafting fee's code (`CalculateCostOfCrafting`: the crafted item's crafting price; the schematic-based line commented out) and the schematics' own `price` in `<schematic>` entries (inert) | CRAFT-05 (DC3, signed off) | the fee's numbers are ECON-01 to ECON-03 (the item's price) and ECON-07 (`mod_craftitem`) |
| Buying ingredients in the alchemy menu | UI-09 (signed off) | reads the shop's prices live |
| The prices of the items legacy added (193) | FOOD-07, ARM-12, CRAFT-04, CRAFT-09, ITEM-11, MUT-12, ... (signed off) | each with its definition; all legacy's in the port |

**Not ECON:**

| Subject | Area | Why |
|---|---|---|
| Weights (the BaW paintings' weight, the Shani alcohols and flowers, the herbs, notices and others: about 580 units, unattributed) | WGT | The weight next to a price: the 40 paintings carry ECON (price) and their weight is WGT's (hand-off) |
| The trophies' bonuses (their abilities, 93 units, unattributed) | TRPH | ECON takes the trophy items' prices (ECON-02) |
| `mod_alchemy_table` on Protofleder Mutagen (lets the dismantling station take it: `W3StandaloneDismantleComponent`) | CRAFT-08 | A dismantling tag, not a price tag; found missing in the port (hand-off) |
| The "Trophies no longer auto-equipped" quest function (`ProcessMonsterHuntTrophyQuest`) | TRPH | Found by the money sweep (contract trophies) |
| `Body palms cut`, an NG+ item legacy added where NG+ armor named it without a definition | (ARM or MISC) | Not money; noted for whoever picks it up |
| The Doppler trophy's "+25% to bonus money" | TRPH | A trophy bonus |

## Changes at a glance

### What Ghost Mode changed

Prices are list prices (the item's `price`); a shop multiplies them by the factors of the item's price tags for the merchant's type and region (ECON-05), Geralt's sale by the sale factor (ECON-06), a craftsman's fee by the service's factor (ECON-07). How the native code combines them (**verified** by measurement, [game-5.0-changes.md](../game-5.0-changes.md#gameplay-systems-from-the-official-patch-notes), "Prices"): a merchant asks ceil(list × the product of his factors for the item's tags), `mod_legendary`'s factor already in the list; he pays Geralt `mod_sale`'s share **of that asking price**, not of the list price; a fee is ceil(list × the service's factors); a bolt costs a tenth of its list price; gear's list price in play is its definition's plus a share from its stats (Long Steel Sword 27 → 32). The table below gives list prices and factors as the data has them.

| # | Feature | Vanilla 1.32 (and 5.x) | Legacy GM | Units (main) |
|---|---|---|---|---|
| ECON-01 | Gear prices | 1.32's (Long Steel Sword 27, Bear Armor 1 455, Aerondight 484, Toussaint saddle 100, Explosive Bolt 132) | Gear mostly dearer, cheap generic pieces cheaper (57, 1,851, 1,155, 450, 170): steel swords ×1.57 in all, silver ×1.54, armor ×1.10, boots and gloves ×2.5, trousers ×1.9, saddles ×4.5 | 1,712 (781 regular, 931 NG+) |
| ECON-02 | Material, consumable and loot prices | 1.32's (Drowner brain 30, Water essence 60, Ruby 200, Steel ingot 6, Dye Black 191, Viziman Champion 7) | Alchemy ingredients ×0.78 in all, junk and gems ×0.93, crafting materials ×1.21, food ×1.14, trophies ×1.28, runes and glyphs ×1.07 (15, 19, 140, 16, 50, 9); greater mutagens dearer (Greater mutagen red 20 → 90); BaW's dyes lose their Relic rarity | 1,167 (583, 584) |
| ECON-03 | Schematic and recipe prices | 1.32's (Bear Armor schematic 67, Wolf DLC schematics, BaW dye and mutagen recipes) | Schematics ×1.81 in all (239), free Wolf DLC schematics ×3.25, BaW recipes ×1.07–1.15 | 804 (405, 399) |
| ECON-04 | Price tags | `mod_legendary` on witcher sets and relic swords, `mod_valuable`/`mod_precious`/`mod_crafting` on most materials, three misspelt tags | `mod_legendary` added to 110 regular entries (relic armor, Wolf DLC swords, crafted and relic swords, Ofir Crossbow R), taken off two Legendary bolts; most materials keep one kind tag (`mod_alchemy`, `mod_crafting`, `mod_junk`, `mod_precious`); `mod_weapo`, `mod_legendar`, `mod_valuable EP1` fixed | 578 (278, 300) |
| ECON-05 | Merchants' buy factors | About ×2 (2.0–2.2) for an item type a merchant trades, ×2 more for `mod_legendary`; region factors 0.4–2 | ×1 (0.9–1.1 for specialists), `mod_legendary` ×1.2; region factors 0.8–1.5 | 22 CSV rows |
| ECON-06 | Selling to merchants | Sale factor 0.10–0.15 by merchant type, × a region factor 0.8–1.1 | 0.20–0.25, no region factor; the quest-bonus columns 1.11 (Blood and Wine's two `mq7018` columns 0.91) | 1 CSV row |
| ECON-07 | Craftsmen's fees | Crafting 0.35 of the item's price at smiths and armorers (0.4 enchanter), repair 0.25, dismantling 0.2, removing upgrades 0.3, sockets 0.3 at the enchanter; Beauclair ×1.25, No Man's Land ×0.95 | Crafting 0.45, the enchanter's column aligned (repair 0.25, dismantling 0.2, upgrades 0.3, sockets 0.35), Beauclair ×1.15, No Man's Land ×0.8, no Novigrad surcharge on sockets | 5 CSV rows |
| ECON-08 | Merchants' money | Funds factor by type (armorer 1.85, smith 1.7, alchemist 1.08, collector 0.97, inn 1.05); restock every 5 days; set up when a merchant has none | Armorer and smith 1.8, alchemist 1.2, collector 1.5, inn 1.2; restock every 3 days; set up when below 100 crowns | 1 CSV row, 2 script units |
| ECON-09 | Contract haggling | Bar up to +35–50% (random); a deal up to +7–35% (a second random roll) | Bar up to +100%; a deal up to +20–70% | 1 script unit |
| ECON-10 | Reward gold | 1.32's (45,938 crowns in all rewards) | 187 rewards retuned (27,843 → 37,175 over them; 55,470 in all): contracts on round sums (Contract: The White Lady 246 → 250), side and minor quests raised (sq108 griffin 25 → 250, the Toussaint champion 200 → 500), a few cut (Belgaard's 900 → 600) | 187 rewards |
| ECON-11 | Quest money in scenes | Vivaldi's loan 100, repaid with 130; the Hearts of Stone tax collector comes when Geralt has 35,000 crowns | Loan 300, repaid with 390; the tax collector at 10,000 | 2 binary files, 1 reward |
| ECON-12 | The Apiarian Phantom's reward name (fix) | Its two scenes set the haggling multiplier and negotiate under the White Lady's reward (`mh308_final`), so the haggled sum never reaches the Apiarian Phantom's payment | Both scenes use its own reward (`mh307_02_minion_killed_completed`) | 2 binary files |

### What 5.x changed

| # | 5.x change (from code and data) |
|---|---|
| ECON-01 to ECON-03 | No price of an existing item; 175 new regular items (203 NG+) with their own prices, at 1.32's scale (DE2) |
| ECON-04 | None on existing items |
| ECON-05 to ECON-07 | None (the table is 1.32's; the native price functions and their callers unchanged); the transmogrification fee is new and independent of prices |
| ECON-06 | The "Sell Junk" button sells every junk item at the sale price |
| ECON-08, ECON-09, ECON-11, ECON-12 | None (the haggling tutorial text rewritten; the `mh307` bug kept) |
| ECON-10 | Gold in 7 rewards (4 collide with legacy: DE1), 5 new rewards with gold |

### Classification and proposed action

| # | Feature | Class | Proposed action |
|---|---|---|---|
| ECON-01 | Gear prices | clean | Legacy's (PE2, PE3); 5.x's new gear by DE2 |
| ECON-02 | Materials and loot | clean | Legacy's (PE2, PE3) |
| ECON-03 | Schematics and recipes | clean | Legacy's (PE2); 5.x's new schematics by DE2 |
| ECON-04 | Price tags | clean | Legacy's, the misspelt tags fixed (PE2, PE4) |
| ECON-05 | Buy factors | clean | Legacy's table (PE5) |
| ECON-06 | Sale factors | clean | Legacy's table (PE5) |
| ECON-07 | Fees | clean | Legacy's table (PE5) |
| ECON-08 | Merchants' money | clean | Legacy's (PE5, PE6) |
| ECON-09 | Haggling | clean | Legacy's (PE7) |
| ECON-10 | Reward gold | clean, 4 overlaps | Legacy's (PE8); 5.x's raises by DE1; 5.x's new rewards 5.x's (PE9) |
| ECON-11 | Scenes | clean | Legacy's amounts in 5.x's files (PE10) |
| ECON-12 | Contract fix | clean (5.x keeps the bug) | Legacy's fix (PE10) |

---

### ECON-01 Gear prices

| | |
|---|---|
| Kind | tuning |
| Pillars | P6 |
| 5.x class | clean |
| Flags | balance |
| Depends on | ARM, SWD, ITEM, XBOW, AI (the same item entries, written by their generators), ECON-05 (the factors the prices meet) |
| Skill trees | n/a |
| Port form | `item_layer.py`: ECON owns the `price` attribute of its units (`ATTRS`), applied by whichever tool writes the entry whole for another area (`item_layer.apply_item`: `gen_arm_items.py`, `gen_swd_items.py`, `gen_arm_km.py`, `gen_ench.py`, `gen_item.py`; the razor's hand-written `gm_ui.xml`); the rest by `tools/gen_econ.py` in `gm_econ.xml`, in the [form the owner chose](#item-entries-in-the-port): short `extend` entries, Hearts of Stone, block changes and NG+ whole (PE2, PE3); 5.x's new gear by DE2 (`item_layer.DE2`, [counterparts](#de2-the-counterparts)) |
| Port status | signed off (2026-11-02); **verified** by script in both trees |
| Open checks | 5.x's new gear (DE2): a purchase from a merchant met in play (its sale prices **verified** on screen; no merchant stocks it on the test save). NG+ prices: `gen_econ.py --verify` only |
| Save impact | none (the list price is read from the definition: the test save's items price at legacy's) |
| NG+ counterpart | legacy's NG+ prices (equal to its regular ones but for six Red Wolf tier-1 pieces), in whole entries; checked by `gen_econ.py --verify`, untested in game |

**What it does** (changelist 943–945, 671; mod description section 4): gear is priced so that a merchant's price stays about what 1.32 charged while Geralt's sale pays more. A generic sword's list price roughly takes 1.32's merchant factor into itself (Long Steel Sword 27 → 57, which a smith sold at about 27 × 2.2 in 1.32 and sells at 57 × 1 in legacy); witcher gear, relics and expansion gear rise most (Bear Armor 1 455 → 1,851, Aerondight 484 → 1,155, Aerondight of Blood and Wine 700 → 1,750, Wolf Armor 2 of the free DLC 640 → 1,875, the Wolf DLC swords ×3.4 to ×4.1); cheap generic armor falls (Heavy armor 01 736 → 284, Medium armor 01 198 → 145, Light armor 01 96 → 82); horse gear rises (Blood and Wine's saddles 100 → 450, the Devil Saddle 100 → 1,000); bolts are priced to be bought and sold (Tracking and Bait 86 → 70, Broadhead 80 → 120, Explosive 132 → 170, Explosive Legendary 218 → 200). In the regular files, 781 gear entries: steel swords 187 (×1.57 in all, median ×1.93; NPC and secondary weapons among them, AI's and SWD's hand-offs), silver swords 105 (×1.54), armor 155 (×1.10), boots 104 and gloves 86 (×2.51 each), trousers 91 (×1.92), crossbows 19, bolts 13, horse gear 20, a staff 1.

**Implementation (legacy):** the `price` attribute of the item entries in `def_item_weapons*.xml`, `def_item_crafting_weapons.xml`, `def_item_armor*.xml`, `def_item_boots/gloves/pants.xml`, `def_item_crafting_armor/boots/gloves/pants.xml`, `def_item_bolts.xml`, `def_item_weapons_crossbow(s).xml`, `def_item_horse.xml`, the standalone starts' files and the free DLCs' item files (`dlc1`, `dlc5`, `dlc10`, `dlc12`, `dlc13`, `dlc14`, `dlc15`), regular and NG+.

**5.x:** 1.32's prices on every existing item; new gear with its own prices at 1.32's scale (DE2).

**Decisions:** legacy's prices (PE2, PE3). 5.x's new gear and horse gear priced by analogy (DE2 (b), owner, 2026-11-01): each piece at the ratio legacy applied to the 1.32 item it copies or matches by class and tier (Heavy armor 03 Netflix 824 → 856, as Heavy armor 03; the Netflix set like Wolf School's piece of the same tier, the owner's choice of counterpart (2026-11-01): Netflix Armor 842 / 3,240 / about 5,040; the Fire Horse saddle 150 → 450, as legacy's saddles), each item's counterpart in [the counterparts table](#de2-the-counterparts). With the price, each item takes its counterpart's legacy price tags (owner, 2026-11-03, whole-port audit A6-2), so it trades as its counterpart: `mod_legendary` (×1.2 at a merchant) added to the Netflix steel and silver swords (all tiers, Reinald's too), the Dol Blathanna and White Tiger armor (all four pieces), the Dol Blathanna longsword, the White Widow, both Vixens and both Top Notch swords, and removed from the six top-tier Netflix schematics (their Wolf counterparts have none; a schematic's `mod_legendary` has no effect at a merchant anyway), regular and NG+ (`NGP` copies too); the Netflix armor, Scarlet Crest and the Fire Horse gear already carried their counterparts' tags. Not a deviation: content legacy never had. The razor's price (legacy's 6) is set by hand in UI-15's `gm_ui.xml` entry and checked by `gen_econ.py --verify` (porter's call, confirmed by the owner, 2026-11-01).

**Slices:** E2 (legacy's prices, with ECON-02 to ECON-04) and E5 (DE2), both verified 2026-11-01 in both trees; the DE2 tags verified 2026-11-03 (scripted: `GMTest_econdata` and `GMTest_data_items` in the regression, failing first on a throwaway build with the old data; `gen_econ.py --verify` checks every DE2 item's price and tags against its counterpart). A real sale and purchase at legacy's list prices, and the sale prices of Netflix Armor 2 and the Fire Horse Saddle, **verified** on screen with real input (merchants spawned and their menus opened by script).

### ECON-02 Material, consumable and loot prices

| | |
|---|---|
| Kind | tuning |
| Pillars | P6 |
| 5.x class | clean |
| Flags | balance |
| Depends on | CRAFT-07 (the ingredients' entries), FOOD-04 (food and drink), ENCH (rune and glyph items), ITEM-11 (kits), TRPH (trophies) |
| Skill trees | n/a |
| Port form | as ECON-01; BaW's dyes also lose `Relic _Stats` (their rarity, CRAFT's hand-off) through ECON-02's `base_abilities` block (`item_layer.BLOCKS`; the dyes whole, a block cannot go in an `extend` entry); NG+'s Gwent Almanac's `stackable` with its price (`ATTRS`) |
| Port status | signed off (2026-11-02); **verified** by script in both trees; the trophies' prices here, their bonuses TRPH's (PE11) |
| Open checks | — |
| Save impact | none |
| NG+ counterpart | legacy's NG+ prices, whole entries, `--verify` only |

**What it does** (mod description: "rare monster parts cost more than generic alchemy ingredients, so you can kill monsters and sell these ingredients for money"): common alchemy ingredients get cheaper (Drowner brain 30 → 15, Nekker eye 30 → 19, Water essence 60 → 19, Fifth essence 60 → 30, Wyvern egg 70 → 38), mutagens dearer (Mutagen red 20 → 30, Greater mutagen red 20 → 90); gems and precious junk cheaper (Ruby 200 → 140, Pearl 100 → 40, Gold ore 100 → 32), basic materials sorted by worth (Steel ingot 6 → 16, Iron ore 2 → 4, Cotton 2 → 1, Linen 16 → 10, Hardened leather 66 → 54); food and drink a little dearer (Viziman Champion 7 → 9); trophies ×1.28; runes and glyphs ×1.07 (Rune svarog 220 → 366, Glyph aard lesser 239 → 192); repair kits cheaper (armor repair kits 60/120 → 30/50); Blood and Wine's dyes 191 → 50 and no longer of Relic rarity; Blood and Wine's paintings and other junk items ×2.5 (10 → 25); Blood and Wine's vampire masks 1 → 300; the quest item `q106_magic_communicator` 100 → 1; the auctioned painting of Hearts of Stone 150 → 500; three quest notes given a price of 1. In the regular files 583 entries: ingredients 200 (alchemy 104, crafting 96), junk 171, food and drink 80, runes and glyphs 59, trophies 28, Blood and Wine's misc junk 20, dyes 14, kits 4, quest items 7.

**Implementation (legacy):** `def_item_ingredients.xml`, `def_item_edibles.xml`, `def_item_junk.xml`, `def_item_dye.xml`, `def_item_trophies.xml`, `def_item_upgrades.xml` and Hearts of Stone's `def_item_ep1_upgrades.xml`, `def_item_alchemy_repair_kits.xml`, `def_item_quest.xml`, `def_item_books.xml` (NG+'s Gwent Almanac 1 → 10 and stack 1, as the regular entry), `def_item_misc.xml`, the free DLC's `def_item_dlc15_items.xml`; base game and both expansions, regular and NG+.

**5.x:** 1.32's prices. The "Sell Junk" button sells every junk item at the shop's price (ECON-06), so junk prices matter more to the player in 5.x.

**Decisions:** legacy's (PE2, PE3). The trophies' prices go now, with ECON; their bonuses stay TRPH's (PE11).

**Slices:** E2, verified 2026-11-01 in both trees (scripted, `GMTest_econdata`). "Sell Junk" at legacy's prices **verified** on screen with real input.

### ECON-03 Schematic and recipe prices

| | |
|---|---|
| Kind | tuning |
| Pillars | P6 |
| 5.x class | clean |
| Flags | balance |
| Depends on | CRAFT-01 to CRAFT-03, CRAFT-06 (the schematic and recipe items), LOOT-01 to LOOT-03 (where they are sold) |
| Skill trees | n/a |
| Port form | as ECON-01 |
| Port status | signed off (2026-11-02); **verified** by script in both trees, the Netflix schematics (DE2) included |
| Open checks | — |
| Save impact | none |
| NG+ counterpart | legacy's NG+ prices, whole entries, `--verify` only |

**What it does:** schematics cost more, in step with the gear they make (Bear Armor schematic 67 → 239, EP1 Viper School steel sword schematic 77 → 280, Crafted Burning Rose Sword schematic 81 → 250); the free Wolf DLC's schematics ×3.25; bolt schematics about the same (Explosive Bolt schematic 26 → 34); Blood and Wine's dye recipes ×1.07 and mutagen recipes ×1.15. Regular: 384 schematics (×1.81 in all) and 21 alchemy recipes.

**Implementation (legacy):** the schematic and recipe items of `def_item_crafting_recipes.xml` (base, Hearts of Stone, Blood and Wine), `def_item_ep1_crafting_recipes.xml`, `def_item_crafting_recipes_bolts.xml`, `dlc10_wolf_recipes.xml`, `def_item_alchemy_recipes_dye.xml` and `_mutagens.xml`, regular and NG+. Not the `price` of the `<schematic>` entries, which no code reads (CRAFT's DC3, ported).

**5.x:** 1.32's; 36 new Netflix schematics (29 to 2,563 crowns, their NG+ tiers included; DE2).

**Decisions:** legacy's (PE2); the 36 Netflix schematics by analogy (DE2 (b), owner, 2026-11-01), each at the legacy price of the Wolf School schematic that crafts its item's counterpart (the owner's decision, 2026-11-01: a ratio on 5.x's prices, which sit above Wolf's 1.32 placeholders, put some tiers out of order; Netflix Armor schematic 173 / 638 / 1,027). Not a deviation: content legacy never had.

**Slices:** E2 and E5, verified 2026-11-01 in both trees (scripted, `GMTest_econdata`; the Netflix Armor schematic 2 at a spawned merchant, `GMTest_econ_e5`).

### ECON-04 Price tags

| | |
|---|---|
| Kind | tuning, fix |
| Pillars | P6 |
| 5.x class | clean |
| Flags | — |
| Depends on | ECON-05 (the factors the tags select) |
| Skill trees | n/a |
| Port form | `item_layer.py`: ECON owns the `mod_*` tags (`TAGS`, `"mod_*"`), but `mod_nosale`/`mod_nosalem` (XBOW-03) and `mod_alchemy_table` (CRAFT-08, PE13) (`ECON_KEEP`); in `extend` entries a `<tags>` node adds tags and removes those written `-mod_…` |
| Port status | signed off (2026-11-02); **verified** by script in both trees |
| Open checks | — |
| Save impact | none (tags are read from the definition) |
| NG+ counterpart | legacy's NG+ tags, whole entries, `--verify` only |

**What it does:** the tags choose the rows of the price table a merchant applies, and whether he trades the item at all. Legacy marks the best gear `mod_legendary` (×1.2 in legacy's table: relic armor, the free Wolf DLC's swords, crafted and relic swords, Hearts of Stone's Burning Rose gear, the Ofir Crossbow R) and takes it off the Split and Explosive Legendary bolts; most materials keep one kind tag instead of two (Arachas eyes: `mod_alchemy, mod_valuable` → `mod_alchemy`; Ruby: `mod_crafting, mod_precious` → `mod_precious`; Monstrous tooth: `mod_crafting, mod_precious` → `mod_alchemy`), so alchemists and herbalists buy monster parts and smiths buy metals; Wolf liver and the Free nilfgaardian lemon become `mod_food`, Local pepper vodka `mod_alchemy` (FOOD's moved items). Three of 1.32's tags are misspelt and match no row: `mod_weapo` (Hearts of Stone's Plank), `mod_legendar` (NG+ EP1 Crafted Witcher Silver Sword) and `mod_valuable EP1` (a missing comma, NG+ Crafted Burning Rose Sword); legacy fixes them. Regular: 278 entries (in all regular entries: `mod_legendary` +110, `mod_valuable` −80 and +30, `mod_precious` −48 and +5, `mod_crafting` −41 and +14, `mod_alchemy` +23 and −15, `mod_junk` −14 and +3, `mod_armor` +7, others 1 or 2).

**Implementation (legacy):** the `<tags>` of the same entries as ECON-01 to ECON-03.

**5.x:** 1.32's tags, the misspellings included.

**Decisions:** legacy's tags, the misspellings fixed with them (PE4): `Plank` `mod_weapo` → `mod_weapon`, NG+'s `EP1 Crafted Witcher Silver Sword` `mod_legendar` → `mod_legendary`, NG+'s Crafted Burning Rose Sword `mod_valuable EP1` → `mod_legendary` with ITEM-03's `EP1`.

**Slices:** E2, verified 2026-11-01 in both trees (scripted, `GMTest_econdata`: each 1.32, legacy or 5.x price tag present or absent on every regular ECON unit, as the definitions manager reads it).

### Item entries in the port

The project owner approved short `extend` entries for item prices and tags (2026-11-01): `<item name="…" price="…" on_conflict="extend">` with a `<tags>` node that adds tags and removes those written `-mod_…`, for items of the base game, Blood and Wine and the free DLCs; Hearts of Stone's items whole (`replace`: `extend` empties them); an item another area already writes whole keeps its whole entry, with ECON's price and tags set inside it. The rule is in [development.md](../development.md#fine-grained-xml-overrides-50). Not a deviation: the same data either way.

`tools/gen_econ.py` and `tools/item_layer.py` give legacy's price and price tags to all 3,711 ECON item units (1,783 regular, 1,928 NG+; 5.x changed none of those prices or tags):

| Form | Regular | NG+ |
|---|---|---|
| Inside an entry another area writes whole (`gm_arm_items.xml`, `gm_swd_items.xml`, `gm_item.xml`, `gm_arm_kaer_morhen.xml`, `gm_ench.xml`, the razor in `gm_ui.xml`) | 1,202 | 1,461 |
| `extend`, `gm_econ.xml` (the price; 28 also with tags) | 531 | — |
| `replace`, `gm_econ.xml`: Hearts of Stone | 36 | — |
| `replace`, `gm_econ.xml`: Blood and Wine's dyes (their `base_abilities`, a block) | 14 | — |
| `replace`, `gm_econ.xml`: NG+ (Hearts of Stone's among them) | — | 467 |

- **NG+ entries whole** (porter's call, confirmed by the owner, 2026-11-01): NG+ definitions are read only in an NG+ game, so NG+ `extend` could not be probed ([open question](../open-questions.md)); every NG+ entry ECON writes is 5.x's NG+ entry whole with legacy's price and tags (about 250 KB). No play effect.
- **The `on_conflict` guard:** a DLC entry without `on_conflict` on a name 5.x defines is ignored by the game (probed, [development.md](../development.md#fine-grained-xml-overrides-50)). `tools/dlc_conflicts.py` lists every such `<item>`, `<ability>` or `<item_extension>` entry in every definition file of the four folders, whichever tool wrote it, and `gen_econ.py --verify` fails on any.
- `gen_econ.py --verify` checks every regular and NG+ price and tag of the 3,711 units against legacy's (none differs, none comes out empty, no name defined twice); the other generators' `--verify` read the `extend` entries over 5.x's.

### ECON-05 Merchants' buy factors

| | |
|---|---|
| Kind | tuning |
| Pillars | P6 |
| 5.x class | clean |
| Flags | balance |
| Depends on | ENCH-02 (the same file, already a whole-file override) |
| Skill trees | n/a |
| Port form | `files/gameplay/globals/economy_tagmodifiers.csv` in the port: legacy's rows (PE5) |
| Port status | signed off (2026-11-02); **verified** by script in both trees: legacy's table; the formula measured |
| Open checks | the Blood and Wine merchants of legacy's known issues (Later) |
| Save impact | none (expected) |
| NG+ counterpart | none (one table) |

**What it does** (changelist 944: "Price modifiers were altered, so you are no longer charged an astronomical sum for generic sword or a piece of wood"; mod description: "items no longer have 400% extra charge"): `economy_tagmodifiers.csv` holds a factor for each price tag (rows) by merchant type (11 columns: general, alchemist, armorer, barber, blacksmith, book, collector, dye, enchanter, herbalist, inn) and by region (Beauclair, No Man's Land, nonhuman, Skellige, Novigrad, Nilfgaard, and five bonus columns); a negative factor means the merchant does not trade items with that tag. In 1.32 a merchant who trades an item type applies about ×2.0–2.2 for it (`mod_weapon` at a blacksmith 2.2, `mod_alchemy` at an herbalist 2.15, `mod_food` at an inn 2.07) and ×2 for `mod_legendary`, so a legendary armor at an armorer meets ×2.2 × 2 = ×4.4 (the "400% extra charge"); legacy sets the type factors to 1 (0.9 at specialists for their own trade, 1.1 for collectors and a few), `mod_legendary` to 1.2, `mod_collectible` to 1.5 at alchemists and collectors (1 at herbalists, 1.32: 2), retunes the region factors (food in No Man's Land 2 → 1.5, upgrades in Nilfgaard 1.3 → 1, origin rows: a Nilfgaardian item among nonhumans 0.2 → 1, a Novigrad one 0.5 → 0.9) and keeps "does not trade" as −1. Example (measured): a Bear Armor 1 at the Novigrad armorer asks 2,619 crowns in 5.x (list in play 541, ×2 legendary, × 2.2 × 1.1) and 2,441 in the port (legacy's list 1,937 in play × 1.2 legendary, × 1 × 1.05); a Drowner brain at the Novigrad herbalist 75 → 17.

**Implementation (legacy):** 22 rows: the item-type rows `mod_alchemy`, `mod_alcohol`, `mod_armor`, `mod_book`, `mod_crafting`, `mod_dye`, `mod_food`, `mod_horse`, `mod_upgrade`, `mod_weapon`, `mod_secondary`, `mod_junk`, `mod_valuable`, `mod_precious`; `mod_collectible`, `mod_legendary`; the six `mod_origin_*` rows. Legacy's design sheet (`design-docs/price_modifiers.csv`) equals the file.

**5.x:** 1.32's table. The native price code is presumed 1.32's (no script changed around it).

**Decisions:** legacy's table (PE5). Legacy's known issues (some Blood and Wine merchants and quest bonuses without factors) are vanilla's and stay; whether 5.x fixed them is for Later.

**Slices:** E1, verified 2026-11-01 in both trees (scripted, `gmtest_econ_e1`: ten merchants spawned from their entity files, six types in three regions plus the Hearts of Stone enchanter and a blacksmith given Beauclair's columns; every list price, asking price, sale price, fee and funds factor against the formula and legacy's table; failing first on a throwaway build with 5.x's table). A real purchase **verified** on screen with real input.

### ECON-06 Selling to merchants

| | |
|---|---|
| Kind | tuning |
| Pillars | P6 |
| 5.x class | clean |
| Flags | balance |
| Depends on | ECON-05 |
| Skill trees | n/a |
| Port form | the `mod_sale` row (PE5) |
| Port status | signed off (2026-11-02); **verified** by script in both trees |
| Open checks | the bonus columns (`area_*_bonus`, `quest_bonus`, `bonus_mq7018_*`) applied at no merchant tested: where they apply is not known (Later, with legacy's known issues) |
| Save impact | none (expected) |
| NG+ counterpart | none |

**What it does:** the `mod_sale` row is the share of an item's price a merchant pays Geralt. 1.32: 0.10 (general merchants) to 0.15 (smiths, armorers, inns), × 1.1 in Beauclair and Novigrad, × 0.8 in No Man's Land, × 0.9 among nonhumans; legacy: 0.20 for general merchants and 0.25 for every specialist, no region factor, and 1.11 in the four bonus columns (`area_nml_bonus`, `area_skellige_bonus`, `area_novigrad_bonus`, `quest_bonus`, where 1.32 has 1) and 0.91 in Blood and Wine's two `bonus_mq7018` columns. The sale is a share of the merchant's asking price (measured), so legacy's larger share meets a lower asking price: Geralt selling a Long Steel Sword (list in play 32) to the No Man's Land weaponsmith got trunc(57 × 0.15 × 0.8) = 6 crowns with 5.x's table and gets trunc(29 × 0.25) = 7 with legacy's; a Bear Armor 1 to the Novigrad armorer 432 in 5.x, 610 in the port.

**Implementation (legacy):** the one row.

**5.x:** 1.32's row; the "Sell Junk" button uses it for all junk at once. XBOW's measurement in 5.x (a Tracking bolt of list price 86 sold for 3 crowns at a spawned Novigrad weaponsmith, an Explosive Legendary bolt of 218 for 16) follows from the formula: a bolt is priced at a tenth of its list price, and the sale is a share of the asking price (asking ceil(86 × 2.2 × 1.05) = 199, a bolt 19; sale trunc(199 × 0.15 × 1.1) = 32, a bolt 3).

**Decisions:** legacy's row (PE5).

**Slices:** E1 (as ECON-05). A real sale and "Sell Junk" **verified** on screen with real input.

### ECON-07 Craftsmen's fees

| | |
|---|---|
| Kind | tuning |
| Pillars | P6 |
| 5.x class | clean |
| Flags | balance |
| Depends on | CRAFT-05 (the fee code), ITEM-11 (repair), CRAFT-08 (dismantling), ENCH-02 (the enchanter's own rows) |
| Skill trees | n/a |
| Port form | the five rows (PE5) |
| Port status | signed off (2026-11-02); **verified** by script in both trees: crafting, dismantling, removing an upgrade, repair and adding a socket, with the enchanter's and Beauclair's columns |
| Open checks | Beauclair's column read on a spawned merchant given Beauclair's columns (no spawnable Blood and Wine merchant carries columns), not on a merchant placed in Toussaint; dismantling and removing an upgrade not seen on screen (scripted only) |
| Save impact | none (expected) |
| NG+ counterpart | none |

**What it does:** a craftsman's fee is the item's price times the service's row (`GetItemPriceCrafting` and the others, native): crafting (`mod_craftitem`) 0.35 at armorers, blacksmiths and dye makers, 0.4 at the enchanter in 1.32 → 0.45 for all four in legacy, with Beauclair 1.25 → 1.15 and No Man's Land 0.95 → 0.8; removing an upgrade (`mod_removeupgrade`) the enchanter 0.35 → 0.3 and the same region changes (nonhumans 0.95 → 0.9); adding a socket (`mod_addslot`) the enchanter 0.3 → 0.35 and no Novigrad surcharge (1.1 → 1); repair (`mod_repair`) the enchanter 0.28 → 0.25 and the regions as removing upgrades; dismantling (`mod_disassemble`) the enchanter 0.25 → 0.2 and the regions as crafting. Measured: a fee is ceil(list in play × the row's type × region factors), the list with `mod_legendary`'s factor (crafting a Bear Armor 1 at the Novigrad armorer 417 crowns in 5.x, 1,151 in the port). **Repair:** per missing durability point ceil(Geralt's own list price × `mod_repair`'s type × region factors ÷ 100), the total that times the missing points (a Bear Armor 4 at half durability at the Hearts of Stone enchanter: 18 a point, 900 crowns; 20 and 1,000 with 5.x's table). **Adding a socket:** ceil((293 + the list in play × `mod_addslot`'s type × region factors) × (the item's sockets + 1)); the 293 is the same for every item, at every merchant and with either table, and is not a row of the table (a Long Steel Sword without sockets: 315 at the enchanter, 630 for its second; 355 at the Novigrad weaponsmith, 362 with 5.x's Novigrad surcharge).

**Implementation (legacy):** the five rows. The enchanter's `mod_enchantment` and `mod_removeenchantment` are ENCH-02's (ported).

**5.x:** 1.32's rows and code; the blacksmith's repair panel rebuilt around the same `GetItemPriceRepair` (ITEM's note); the new transmogrification fee is its own formula (100 × category × rarity factors), not a row of the table.

**Decisions:** legacy's rows (PE5); 5.x's transmogrification fee as it is (PE12).

**Slices:** E1 (as ECON-05; repair and sockets by their measured formulas). The crafting, repair and socket fees **verified** on screen with real input (a Gildorf sword crafted at the Novigrad market smith for 98 crowns, list 196 × 0.45 × 1.1).

### ECON-08 Merchants' money

| | |
|---|---|
| Kind | tuning |
| Pillars | P6 |
| 5.x class | clean |
| Flags | balance |
| Depends on | LOOT-05, ITEM-02, ITEM-06 (the same `W3MerchantNPC` events: the Balisse fruit, the restock's level cut, the random bonuses) |
| Skill trees | n/a |
| Port form | the `mod_funds` row (PE5); `gm/econ/merchants.ws` (PE6): a scope-based `default daysToIncreaseFunds = 3` on the import class `CInventoryComponent` (5.x's `OnInteraction` reads it through `GetDaysToIncreaseFunds`), and `@wrapMethod(W3MerchantNPC) OnSpawned`, which calls `SetupFunds` after 5.x's body when the merchant holds less than 100 crowns |
| Port status | signed off (2026-11-02); **verified** by script in both trees |
| Open checks | a merchant met in play restocking after 3 game days (tested on spawned merchants with the last restock moved back by script; no game time passed): needs a play session or a save made for it |
| Save impact | none (expected: a merchant's money is in the save and the new rules act at the next spawn or restock) |
| NG+ counterpart | none |

**What it does:** a merchant starts with an amount by class (poor 200, average 500, rich 1,000, quick-start 5,000) and, when Geralt talks to him after the interval, gains a restock (100, 150, 1,000, 1,000 + 2,500), the setup and the restock each times the funds factor (`mod_funds` by merchant type and region), while his money is below a ceiling (2,500, 5,000, 7,500, 15,000), which is not multiplied by the factor; `IncreaseFunds` only checks that the money is below it, so a restock can take a merchant over it. Legacy raises the factor for alchemists (1.08 → 1.2), collectors (0.97 → 1.5), inns (1.05 → 1.2), herbalists (1.02 → 1.1), smiths and the enchanter (1.7 → 1.8), lowers it a little for armorers (1.85 → 1.8) and dye makers (1.65 → 1.6), and sets barbers and booksellers to 1; restocks every 3 days instead of 5 (`daysToIncreaseFunds`); and sets a merchant's money up again when he has less than 100 crowns at spawn, not only at 0. Example: an average Novigrad smith gains 150 × 1.7 × 1.1 (about 280) every 5 days in 1.32, 150 × 1.8 × 1.1 (about 297) every 3 days in legacy; an alchemist found with 60 crowns gets his 500 × factor again.

**Implementation (legacy):** `mod_funds`; `CInventoryComponent`'s `default daysToIncreaseFunds = 3`; `W3MerchantNPC.OnSpawned`'s `GetMoney() < 100`. `OnInteraction`'s other changes are ITEM-02's and LOOT-05's.

**5.x:** 1.32's code and row.

**Decisions:** legacy's (PE5, PE6). No deviation: 5.x's `OnSpawned` already sets the funds up at 0, and with legacy's factors (at least 0.8) a merchant set up there holds at least 160 crowns, so the wrapper's check adds nothing then; between 1 and 99 crowns it sets them up as legacy's `< 100` did.

**Slices:** E1 (the row) and E3 (the interval and the reset), verified 2026-11-01 in both trees: eight merchants spawned from their entity files, the money at spawn, the interval, a restock's amount and the reset of a restored spawn holding 60 crowns (scripted, `GMTest_econ_e3_money`, in the regression); talking to a Novigrad weaponsmith 2 and 3 days after his last restock, no restock and then +198 (scripted, `gmtest_econ_e3_restock()`, outside the regression because it starts the merchant's scene). Example: the Novigrad weaponsmith (poor) 374 → 396 at spawn, +187 every 5 days → +198 every 3.

### ECON-09 Contract haggling

| | |
|---|---|
| Kind | tuning |
| Pillars | P6 |
| 5.x class | clean |
| Flags | balance |
| Depends on | — |
| Skill trees | n/a |
| Port form | `gm/econ/haggling.ws`: `@replaceMethod(CR4HudModuleDialog) OpenMonsterHuntNegotiationPopup`, 5.x's body (1.32's, line for line) with legacy's `maxMult = 1` (PE7) |
| Port status | signed off (2026-11-02); **verified** by script in both trees |
| Open checks | a real negotiation in a contract's scene on screen: needs a save at a contract's giver |
| Save impact | none |
| NG+ counterpart | none |

**What it does** (changelist 940–942): when Geralt haggles over a contract, the bar goes from the offered reward to reward × (1 + the upper limit), and the employer accepts up to reward × (1 + a random 20–70% of the upper limit). 1.32 draws the upper limit at random between 35% and 50%, so a deal pays at most 7% to 35% more (the "double randomization"); legacy fixes it at 100%, so a deal pays up to 20% to 70% more, a random ceiling the player feels out with the employer's "pretty close" answers (each costing patience), and a contract that is always successful (`alwaysSuccessful`) accepts up to double. Example: Contract: The White Lady (`mh308_final`, legacy 250 crowns): 1.32 (246 crowns) up to 263–332; legacy up to 300–425, and an employer who always agrees up to 500. The same multiplier applies to an item reward's count (`isItemReward`).

**Implementation (legacy):** one line of `OpenMonsterHuntNegotiationPopup` (`maxMult = RandRangeF(0.5, 0.35)` → `maxMult = 1`).

**5.x:** 1.32's code; the tutorial text rewritten (no numbers).

**Decisions:** legacy's (PE7). No deviation.

**Slices:** E3, verified 2026-11-01 in both trees (scripted, `GMTest_econ_e3_haggle`, in the regression: the negotiation popup opened by script on Contract: The White Lady 60 times, offers made through the popup's result function). On legacy's 250 crowns: the bar up to 500, the employer's limit seen 1.21–1.70 × the reward, an always-successful negotiation accepts 500; no multiplier or popup left behind.

### ECON-10 Quest reward gold

| | |
|---|---|
| Kind | tuning |
| Pillars | P6, P10 |
| 5.x class | clean, with 4 overlaps |
| Flags | balance |
| Depends on | LOOT-07, XP-02 (the same reward overrides, `gen_loot.py`) |
| Skill trees | n/a |
| Port form | `gen_loot.py`'s reward merge takes legacy's `gold` for ECON-10's units (the six overridden reward files: base, Hearts of Stone, Blood and Wine, `dlc3`, `dlc12`, `dlc15`), 5.x's raises by DE1 (PE8, PE9) |
| Port status | signed off (2026-11-02); **verified** by script in both trees |
| Open checks | a reward paid by a real quest on screen (tested through `GiveReward`, the function quests' reward blocks and scenes call): needs a save just before a quest's reward |
| Save impact | none (expected: rewards are read when given) |
| NG+ counterpart | none (one reward table) |

**What it does** (mod description section 6: "optional quests like horse races, fistfights and gwent give less experience and more items/money"): 187 rewards' gold retuned, 163 raised and 24 cut, 27,843 → 37,175 crowns over them (all reward gold 45,938 → 55,470, +21%). Contracts are set on round sums (31: 7,042 → 7,050 in all; Contract: The White Lady 246 → 250, `mh102_final_reward` 280 → 300, `mh104_father_reward` 210 → 100, `mh202_2_final_reward` 520 → 250, the free DLC troll `mh201_troll_left_alone` 50 → 150); side and minor quests raised (`sq108_griffon_killed` 25 → 250, `mq2024_final_reward` 20 → 250, `mq3002_3_chest` 50 → 300, `sq202_pirate_treasure` 60 → 250, `sq310_coins` 150 → 300, Blood and Wine's `sq701_champion` 200 → 500, `q705_beast_slayer` 5,000 → 6,000); horse races (`hr*`) and fistfights (`ff*`) doubled (`ff701_br_reward` 100 → 200); a few cut (Blood and Wine's wine-war rewards 700–900 → 600). Base game 143, Blood and Wine 36, Hearts of Stone 4, `dlc3` 3, `dlc15` 1; 31 of them change only gold.

**Implementation (legacy):** the `gold` attribute of the rewards in the `rewards.xml` files.

**5.x:** 7 rewards' gold changed (DE1; three of them to legacy's own amount: the prologue griffin 250, Rosa's payment 100, `mq0001_01_reunite_brothers` 25) and 5 new rewards, 3 of them with gold (PE9).

**Decisions:** legacy's gold (PE8). The four rewards 5.x raised on its own pay legacy's gold (DE1 (a), owner, 2026-11-01): Emhyr's payment for finding Ciri (`q110_1b_accepted_emhyrs_reward`) 2,000, Hearts of Stone's finale purse (`q605_mirror_finale_cash`) 5,000, the baron's payment (`q107_4_reward_baron`) 100, `q103_06_find_daughter` 100. Not a deviation: legacy's amounts. 5.x's new rewards keep 5.x's gold (PE9).

**Port:** `gen_loot.py` sets legacy's `gold` on every ECON-10 unit, on the loan's reward (`vivaldis_loan`, ECON-11's one XML unit) and on DE1's three rewards that are not ECON-10 units (its `DE1` list; the fourth, `q103_06_find_daughter`, is one), in the same whole-file reward overrides LOOT-07 and XP-02 write. `--verify` compares every reward of the six files with legacy's gold (891 legacy's, 3 of 5.x's new rewards with 5.x's gold, 4 new ones without gold, 0 unexplained) and checks that `DE1` lists exactly the rewards 5.x raised where legacy kept 1.32's gold. Totals over all rewards: 1.32 45,938, legacy 55,470, 5.x 53,728, the port 55,885 (PE9's 415 more).

**Slices:** E4, verified 2026-11-01 in both trees: every reward ECON decides read as `GetReward` reads it (scripted, `GMTest_econrewards`, in the regression); rewards given through `theGame.GiveReward` and the crowns gained (Emhyr's payment +2,000, the sq108 griffin +250, the loan +300, a horse race +50, a fistfight +125, Hearts of Stone's purse +5,000) and a haggled White Lady deal at 300 paying +300 (scripted, `GMTest_econ_e4_give`, in `gmtest_panel()`; rewards with experience given with Geralt's level held at 100 by a test-only override, so none levels him up).

### ECON-11 Quest money in scenes

| | |
|---|---|
| Kind | tuning |
| Pillars | P6 |
| 5.x class | clean |
| Flags | — |
| Depends on | ECON-10 (the loan is the reward `vivaldis_loan`) |
| Skill trees | n/a |
| Port form | `cr2w_patch.py` on 5.x's two files (`CPayStorySceneChoiceAction.money=130:390`; the two `CQCItemQuantity.quantity=35000:10000`), shipped in the bundle as ENCH-02's scenes are (`gen_econ.py`'s `BINARIES`, checked by `--verify`); the loan's gold through `gen_loot.py` (PE10) |
| Port status | signed off (2026-11-02); the loan's reward **verified** by script with ECON-10; the two files checked offline and loaded by script in both trees |
| Open checks | the values in play (Vivaldi's repay choice showing 390, the tax collector arriving at 10,000 crowns): the game reads them only while the scene or the quest phase runs; needs saves at the loan and at the tax collector's quest |
| Save impact | none for the loan (expected); the tax quest's condition is read while its phase waits, so a save past it keeps its state |
| NG+ counterpart | none |

**What it does:** not in the changelist (omissions). Vimme Vivaldi's loan in Novigrad pays 300 crowns instead of 100 and is repaid with 390 instead of 130 (the same 30% interest); in Hearts of Stone, the tax collector's quest (`mq6003`, its quest phase waits "only if the player has 35000+ gold") starts once Geralt holds 10,000 crowns instead of 35,000, so a Geralt with legacy's scarcer money still meets it.

**Implementation (legacy):** `quests/secondary_npcs/default_dialogues/vimme_vivaldi_default.w2scene` (`CPayStorySceneChoiceAction.money` 130 → 390, behind `vivaldi_loan_taken`), the reward `vivaldis_loan` (gold 100 → 300), `dlc/ep1/data/quests/quest_files/mq6003_taxes/mq6003_taxes.w2phase` (two `CQCItemQuantity` on `Crowns`, 35,000 → 10,000).

**5.x:** 1.32's files (re-save noise only).

**Decisions:** legacy's amounts in 5.x's files (PE10).

**Slices:** E5, verified 2026-11-01: offline, the shipped files are 5.x's with exactly legacy's edits (`cr2w_dump.py` against 5.x's and legacy's against 1.32, CRCs valid, the built bundle holds them byte for byte; `gen_econ.py --verify`); in game both trees, each file loads (scripted, `LoadResource`, `GMTest_econ_e5`). The other `vivaldis_loan` givers (the Hearts of Stone auction scene, Novigrad's shops phase) read the reward's gold and hold no amount of their own; the only other `CQCItemQuantity` on Crowns in the game is `th700_red_wolf`'s 10.

### ECON-12 The Apiarian Phantom's reward name (fix)

| | |
|---|---|
| Kind | fix |
| Pillars | P6 |
| 5.x class | clean (5.x keeps the bug) |
| Flags | — |
| Depends on | ECON-09 |
| Skill trees | n/a |
| Port form | `cr2w_patch.py` on 5.x's two scenes: each `CStorySceneScript` call's `rewardName` parameter (`CStorySceneScript.@rewardName=mh308_final:mh307_02_minion_killed_completed`, the tool's `@` edit of a call's parameters) and its editor comment, as legacy; the name added to each file's name table (PE10) |
| Port status | signed off (2026-11-02); **verified** offline and loaded by script in both trees: the four edited script blocks byte for byte as legacy's |
| Open checks | the negotiation in play (its bar on 250 crowns, the haggled sum paid by the contract, no multiplier left on the White Lady's reward): needs a save at the Apiarian Phantom's giver |
| Save impact | none (expected) |
| NG+ counterpart | none |

**What it does:** not in the changelist (an omission). In Contract: The Apiarian Phantom (Novigrad, the halfling beekeepers), the opening scene's `SetRewardModifierScene` and `NegotiateMonsterHunt` and the closing scene's name the White Lady's reward, `mh308_final`, instead of the contract's own `mh307_02_minion_killed_completed`: the haggle reads the White Lady's sum as its base and stores the agreed multiplier under her reward, so the Apiarian Phantom pays its plain 249 crowns (legacy: 250) whatever Geralt agreed, and the White Lady's contract later finds a multiplier already set. The two scenes also set a 0.5 reward modifier in some branches (`SetRewardModifierScene` 0.5, three blocks; which branches is not identified): in 5.x that half pay too landed on the White Lady's reward; with the fix it lands on the Apiarian Phantom's own. Legacy points both scenes at the contract's own reward.

**Implementation (legacy):** `quests/generic_quests/novigrad/quest_files/mh307_minion/scenes/mh307_01_halflings.w2scene` and `mh307_05_halflings_closing.w2scene`: the `CStorySceneScript` blocks' comment and their `rewardName` parameter.

**5.x:** the bug is still there (the scenes are 1.32's).

**Decisions:** legacy's fix (PE10).

The Apiarian Phantom's payment (`mh307_minion.w2phase`) gives `mh307_02_minion_killed_completed`, the name the fixed scenes store the multiplier under; every other base-game contract haggles under the reward its own phase pays, and Blood and Wine's contracts do the same through their scenes' reward events, so the bug is the Apiarian Phantom's alone.

**Slices:** E5 (as ECON-11).

---

### DE2: the counterparts

The rule (DE2 (b)): 5.x's price × the ratio legacy applied to the counterpart (legacy ÷ 1.32), rounded; for gear with a 1.32 item's stats but another price (the Fire Horse gear), that item's legacy price. The **Netflix set** follows the owner's choice (2026-11-01): the Wolf School piece of the same tier, Netflix's three tiers matching Wolf's second, fourth and fifth (armor: the first, third and fourth upgrade); each Netflix schematic at the legacy price of the Wolf schematic that crafts its item's counterpart, and Top Notch at its counterparts' legacy prices (the owner's decision, 2026-11-01: 5.x's prices there are above Wolf's 1.32 placeholders or placeholders themselves, so a ratio put them out of line); Reinald's swords as the first tier; 5.x's `NGP Netflix … schematic` items (in the regular folder) as the regular schematics. Crowns are list prices (a merchant's asking price multiplies them by his factors, [ECON-05](#econ-05-merchants-buy-factors)). Category and texts stay 5.x's; Gwent cards, potions, quest items and masks keep 5.x's prices. `gen_econ.py --verify` recomputes every price from its counterpart in 1.32 and legacy, and fails on a new priced 5.x gear, schematic or horse item left out. The NG+ copies take the regular price (5.x prices them alike; legacy's NG+ prices equal its regular ones, PE3; porter's call, confirmed by the owner, 2026-11-01).

| Item | 5.x | Counterpart | Legacy's ratio | Port | Why |
|---|---|---|---|---|---|
| Netflix Armor / 1 / 2 | 327 / 751 / 4,458 | Wolf Armor 1 / 3 / 4 | ×2.57 / ×4.31 / ×1.13 | 842 / 3,240 / 5,040 | the owner's choice: Wolf's piece of the same tier |
| Netflix Boots / 1 / 2 | 203 / 216 / 1,030 | Wolf Boots 2 / 4 / 5 | ×3.12 / ×7.69 / ×2.54 | 634 / 1,660 / 2,620 | as above |
| Netflix Gloves / 1 / 2 | 186 / 196 / 549 | Wolf Gloves 2 / 4 / 5 | ×3.06 / ×7.19 / ×4.19 | 570 / 1,410 / 2,298 | as above |
| Netflix Pants / 1 / 2 | 234 / 287 / 356 | Wolf Pants 2 / 4 / 5 | ×2.58 / ×5.80 / ×9.19 | 604 / 1,665 / 3,272 | as above; 604 and 3,272 are the owner's figures (the ratio gives 605 and 3,273) |
| Netflix steel sword / 1 / 2 (Reinald's = the first) | 130 / 689 / 1,958 | Wolf School steel sword 1 / 3 / 4 | ×4.18 / ×2.03 / ×0.87 | 544 / 1,402 / 1,709 | as above |
| Netflix silver sword / 1 / 2 (Reinald's = the first) | 167 / 229 / 1,973 | Wolf School silver sword 1 / 3 / 4 | ×3.78 / ×7.21 / ×1.29 | 631 / 1,650 / 2,540 | as above |
| Netflix Armor schematic / 1 / 2 | 80 / 151 / 538 | Witcher Wolf Jacket Upgrade schematic 1 / 3 / 4 | (its legacy price) | 173 / 638 / 1,027 | the legacy price of the schematic of the item's counterpart (the owner, 2026-11-01) |
| Netflix Boots schematic / 1 / 2 | 30 / 58 / 213 | Witcher Wolf Boots Upgrade schematic 1 / 3 / 5 | (its legacy price) | 65 / 332 / 524 | as above |
| Netflix Gloves schematic / 1 / 2 | 29 / 46 / 116 | Witcher Wolf Gloves Upgrade schematic 1 / 3 / 5 | (its legacy price) | 114 / 267 / 460 | as above |
| Netflix Pants schematic / 1 / 2 | 31 / 89 / 276 | Witcher Wolf Pants Upgrade schematic 1 / 3 / 5 | (its legacy price) | 122 / 328 / 520 | as above |
| Netflix steel sword schematic / 1 / 2 | 37 / 123 / 253 | Wolf School steel sword Upgrade schematic 1 / 3 / 4 | (its legacy price) | 100 / 270 / 345 | as above |
| Netflix silver sword schematic / 1 / 2 | 57 / 147 / 245 | Wolf School silver sword Upgrade schematic 1 / 3 / 4 | (its legacy price) | 114 / 322 / 505 | as above |
| Heavy armor 03 Netflix | 824 | Heavy armor 03 | ×1.04 | 856 | a copy of it (price and stats) |
| Heavy gloves 04 Netflix | 140 | Heavy gloves 04 | ×3.36 | 470 | a copy of it |
| Dol Blathanna Armor, White Tiger Armor | 457 | Medium armor 10r | ×1.56 | 714 | **porter's pick, confirmed by the owner (2026-11-01):** relic medium armor (levels 8 and 12, the same 5.x prices); the relic medium chest nearest in 1.32 price (512) |
| Dol Blathanna Boots, White Tiger Boots | 141 | Heavy boots 07_crafted | ×2.04 | 288 | **porter's pick, confirmed by the owner (2026-11-01):** the relic medium boots nearest in 1.32 price (140) |
| Dol Blathanna Gloves, White Tiger Gloves | 93 | Guard Lvl2 Gloves 3 | ×3.01 | 280 | **porter's pick, confirmed by the owner (2026-11-01):** the relic medium gloves nearest in 1.32 price (94) |
| Dol Blathanna Pants, White Tiger Pants | 178 | Guard Lvl2 Pants 3 | ×1.93 | 343 | **porter's pick, confirmed by the owner (2026-11-01):** the relic medium trousers nearest in 1.32 price (210) |
| Scarlet Crest Armor | 730 | Medium armor 11r | ×1.03 | 755 | **porter's pick, confirmed by the owner (2026-11-01):** relic medium armor (level 41); the relic medium chest nearest in 1.32 price (774) |
| Scarlet Crest Boots | 177 | Heavy boots 07 | ×1.81 | 320 | **porter's pick, confirmed by the owner (2026-11-01):** the same rule (158) |
| Scarlet Crest Gauntlets | 220 | Thief Gloves | ×2.56 | 563 | **porter's pick, confirmed by the owner (2026-11-01):** the same rule (100; no relic medium gloves cost more in 1.32) |
| Scarlet Crest Trousers | 90 | Thief Pants | ×2.58 | 232 | **porter's pick, confirmed by the owner (2026-11-01):** the same rule (114) |
| Dol Blathanna longsword, Steel Vixen | 689 | Lune | ×1.66 | 1,145 | **porter's pick, confirmed by the owner (2026-11-01):** relic steel swords; the relic steel sword nearest in 1.32 price (582), an Aard sword like Dol Blathanna's |
| White Widow of Dol Blathanna, Silver Vixen | 891 | Harpy | ×1.45 | 1,289 | **porter's pick, confirmed by the owner (2026-11-01):** relic silver swords; the relic silver sword nearest in 1.32 price (895), a bleeding sword like the Vixen |
| Top Notch Steel | 16 | Eredin Sword | (its legacy price) | 1,500 | the counterpart picked by the porter, its legacy price set by the owner (2026-11-01): a level-scaled relic whose 5.x price is a placeholder (16, the generic steel swords' 1.32 price); the level-scaled relic steel sword nearest in 1.32 price (20), itself a placeholder legacy priced like its relics |
| Top Notch Silver | 102 | Breathofthenorth | (its legacy price) | 1,050 | as above: a level-scaled relic (102, the generic silver swords' price); the relic silver sword nearest in 1.32 price (203), crit damage and dismemberment like it |
| Fire Horse Saddle | 150 | Toussaint saddle | (its stats) | 450 | the Toussaint saddle's stats (stamina 90); the decision's example |
| Fire Horse Blinders | 150 | Toussaint horse blinders | (its stats) | 250 | the Toussaint blinders' stats (panic 60) |
| Fire Horse Saddlebags | 200 | Toussaint horsebag | (its stats) | 450 | the Toussaint bag's stats (encumbrance 110) |

The hand-picked counterparts (porter's calls, confirmed by the owner, 2026-11-01) follow one rule: the legacy relic of the same kind and slot nearest in 1.32 price, so the ratio lands near what legacy charges for such relics. The rule ignores level (the level-41 Scarlet Crest chest 755 against the level-8 Dol Blathanna one 714; 5.x's 730 and 457 were already close): kept. The owner's two figures (Netflix Pants 604 and Netflix Pants 2 3,272, one crown each off the ratio) are kept.

### Save impact

None expected: list prices and tags are read from the definitions, the price table and rewards when used, the haggling at each negotiation; a merchant's money is in the save and meets the new funds rules at his next spawn or restock; the tax quest's threshold is read while its phase waits (a save already past it keeps its state). The mod is installed at the start of a playthrough ([save compatibility](../feature-mapping.md#save-compatibility)).

### Dependencies on other areas

- **ECON builds on:** the item layer (`item_layer.py`) and the item generators of ARM, SWD, ITEM, XBOW, CRAFT, FOOD, ALCH, AI and ENCH (the entries carrying the prices); LOOT-07 and XP-02 (`gen_loot.py`'s reward overrides); ENCH-02 (the price table's file copy, the enchanter's rows and scenes); CRAFT-05 (the fee code); DIFF-07 (the guards' toll).
- **Shared entries:** WGT (weights in the same entries), TRPH (the trophy items: price ECON's, bonuses TRPH's), CRAFT-08 (Protofleder Mutagen's `mod_alchemy_table`, PE13).
- **Both skill trees:** no skill, perk or mutation in either tree reads or changes a price, a fee, funds or a reward's gold (the Doppler trophy's bonus money is TRPH's): ECON is tree-independent, and its checks run in the regression of both trees.

### Area decisions

**Area decisions** (all decided by the project owner, 2026-11-01, each the recommendation):

| # | Question | Options | Recommendation | Decision |
|---|---|---|---|---|
| DE1 | 5.x's own raises of reward gold (ECON-10). Legacy kept 1.32's gold on three rewards that 5.x raised, and set a fourth lower than 5.x: Emhyr's payment for finding Ciri (`q110_1b_accepted_emhyrs_reward`) legacy 2,000, 5.x 4,000; Hearts of Stone's finale purse (`q605_mirror_finale_cash`) 5,000 against 10,000; the baron's payment (`q107_4_reward_baron`) 100 against 150; `q103_06_find_daughter` legacy 100 (1.32 50), 5.x 200. On three more 5.x made legacy's own raise (the prologue griffin 250, Rosa's payment 100, `mq0001_01_reunite_brothers` 25): no question there | (a) legacy's gold on all four (2,000, 5,000, 100, 100); (b) 5.x's raise where legacy kept 1.32's (4,000, 10,000, 150) and legacy's 100 where it changed the reward itself; (c) the larger of the two everywhere (4,000, 10,000, 150, 200) | **(a)**: legacy behaviour first and money scarce (P6); 5.x's raises are a vanilla rebalance legacy never saw, and Emhyr's 4,000 alone would match about fifteen of legacy's contracts (250–300 crowns each). Not a deviation | **(a)** (project owner, 2026-11-01): legacy's gold on all four: Emhyr's payment 2,000, the Hearts of Stone finale purse 5,000, the baron's payment 100, `q103_06_find_daughter` 100. Not a deviation: legacy's amounts |
| DE2 | The prices of 5.x's new items (ECON-01, ECON-03). 5.x added 175 regular items (203 NG+) priced at 1.32's scale, among legacy's re-priced ones: e.g. "Heavy armor 03 Netflix" 824 (a copy of Heavy armor 03, which legacy prices 856), Netflix Armor 2 4,458 (a tier like the Bear Armor 4 legacy raised 4,546 → 6,182), White Tiger Armor 457, Dol Blathanna longsword 689, the 36 Netflix schematics 29–2,563 (their NG+ tiers included), the Fire Horse saddle 150 (legacy's saddles 450), three Gwent cards 10–50 | (a) 5.x's prices as they are; (b) by analogy: each new piece of gear, schematic and horse gear at the ratio legacy applied to the 1.32 item it copies or matches (its class and tier: Heavy armor 03 Netflix 856, Netflix Armor 2 about 6,060, White Tiger Armor like a relic armor ×1.74, about 795, the Fire Horse saddle 450), the slice listing each item's counterpart; quest items, potions and Gwent cards 5.x's; (c) a flat ratio per category (legacy's median for that category) | **(b)**: otherwise the new gear sells and crafts at a third or half of its legacy peers (the Netflix steel sword schematic 2 costs 253, where Blood and Wine's Bear School silver sword Upgrade schematic 4, 214 in 1.32, costs legacy's 544), the same reasoning as XP's DX4 (5.x's new content placed by analogy); Gwent cards and quest items have no re-priced peers. Not a deviation: content legacy never had | **(b)** (project owner, 2026-11-01): 5.x's new gear, schematics and horse gear by analogy, at the ratio legacy applied to the item each copies or matches (Heavy armor 03 Netflix 856, Netflix Armor 2 about 6,060, the Fire Horse saddle 450); Gwent cards, potions and quest items keep 5.x's prices. Not a deviation: content legacy never had. **Counterparts** (owner, 2026-11-01): the Netflix set is priced like the Wolf School piece of the same tier, not like Bear (Netflix Armor 842 / 3,240 / about 5,040; Boots 634 / 1,660 / 2,620; Gloves 570 / 1,410 / 2,298; Pants 604 / 1,665 / 3,272), its schematics at the Wolf schematics' ratios; the other new sets (Dol Blathanna, White Tiger, Vixen, Scarlet Crest, Top Notch) get counterparts picked by hand, confirmed by the owner. **Refined** (owner, 2026-11-01): the Netflix schematics and Top Notch at their counterparts' legacy prices instead of a ratio ([the counterparts](#de2-the-counterparts)) |

### Porter's calls

Each follows legacy or has no play effect; all confirmed by the project owner (2026-11-01).

| # | Call |
|---|---|
| PE1 | ECON is ported as one area with one audit at the end, about 3,900 units, in five slices (E1 the price table, E2 item prices and tags, E3 merchants and haggling, E4 reward gold, E5 scenes and 5.x's new items) |
| PE2 | Item prices and tags go through `item_layer.py`: ECON owns the `price` attribute and the `mod_*` tags (but XBOW-03's and CRAFT-08's) of its units, applied by whichever generator writes the entry; the entries no generator writes are short `extend` entries where the game takes them (the base game, Blood and Wine, the free DLCs: an `extend` entry sets the price and its `<tags>` node adds tags and removes those written `-mod_…`, [development.md](../development.md#fine-grained-xml-overrides-50)) and whole `replace` entries elsewhere (Hearts of Stone, whose items `extend` empties; the dyes; NG+), in the [form the owner chose](#item-entries-in-the-port); `tools/gen_econ.py` with `--verify` against legacy, item by item |
| PE3 | NG+: legacy's NG+ entries' prices and tags (they equal its regular ones but for six Red Wolf tier-1 pieces, legacy's own NG+ values); untested, as every NG+ change |
| PE4 | The three misspelt 1.32 tags (`mod_weapo`, `mod_legendar`, `mod_valuable EP1`) are fixed as legacy fixed them (part of its tags; where `mod_valuable EP1` becomes `mod_legendary, EP1` on NG+'s Crafted Burning Rose Sword, the `EP1` level tag is ITEM-03's, carried with the same entry) |
| PE5 | `economy_tagmodifiers.csv`: legacy's other 29 changed rows in the whole-file copy ENCH-02 ships (its two rows already legacy's): the file becomes legacy's exactly |
| PE6 | ECON-08: the restock interval 3 and the reset below 100 in a small script (`econ/merchants.ws`): a scope-based default for `daysToIncreaseFunds`; a `@wrapMethod(W3MerchantNPC) OnSpawned` that sets funds up after 5.x's body when the merchant has less than 100 (5.x's body already sets them up at 0, so the result equals legacy's) |
| PE7 | ECON-09: `@replaceMethod OpenMonsterHuntNegotiationPopup` with 5.x's body and legacy's `maxMult = 1` (always-successful negotiations accept up to double, as legacy) |
| PE8 | ECON-10: legacy's gold for its 187 rewards through `gen_loot.py`'s merge (the `gold` attribute for ECON-10 units), with DE1's choice for the four overlaps |
| PE9 | 5.x's new rewards keep 5.x's gold (Killbill's new branch `sq106_3_hammond_killed_crach` 200, the `mq1060` priest 200, `q504_horse_returned` 15): content legacy never had, sums already in legacy's range for such quests |
| PE10 | ECON-11 and ECON-12 as binary edits of 5.x's files with `cr2w_patch.py` (legacy's amounts and reward name), shipped in the bundle as ENCH-02's scenes; `cr2w_patch.py` gains the edit of a scene script call's name parameter (the raw part after the properties) for ECON-12 |
| PE11 | The trophy items' prices go with ECON (ECON-02), before TRPH; TRPH later ports the bonuses on the same entries |
| PE12 | 5.x's transmogrification fee and "Sell Junk" button stay 5.x's (services legacy never had; the fee does not read item prices; "Sell Junk" pays the legacy sale price) |
| PE13 | The CRAFT gap (Protofleder Mutagen's `mod_alchemy_table`) is fixed under CRAFT-08, through the same item entry (a one-line `item_layer.py` ownership) |

**Later:**
- whether 5.x applies the Blood and Wine price factors legacy's known issues say vanilla misses (some Toussaint merchants, the `mq7018` bonus columns);
- the free DLC quest `mq2052`'s haggling (vanilla, in 1.32 and 5.x; legacy left it): its giver scene (`mq2052_02_quest_giver.w2scene`) negotiates over `mh102_final_reward` (300 crowns, up to 600 with ECON-09) with `alwaysSuccessful`, while its own rewards pay no gold; a deal stores a multiplier on mh102's reward, which reaches the mh102 contract's pay only if that contract has not paid out (inferred from the scripts; not tested).
