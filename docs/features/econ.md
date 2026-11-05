# ECON: prices, money and trade

What things cost and what money Geralt gets: the list price of every item (gear, materials, food, trophies, runes, schematics and recipes), the price tags that tell merchants how to price an item, the merchants' buy and sell factors by merchant type and region, the fees of craftsmen (crafting, repair, dismantling, removing upgrades, adding sockets), how much money merchants have and how fast it comes back, haggling over monster contracts, the gold of quest rewards, and the quest scenes that take or pay a sum. Ghost Mode's changelist has its own section, "Money and economy" (lines 937–945), and touches money in the Crossbow section (line 671), the known issues (lines 20–22), the Enchantments section (line 950, ENCH-02) and the bugfixes (lines 37–38, the generic merchants fix); the mod description's section 4, "Economy, looting and crafting", explains the intent.

**The player-visible texts first.** Legacy's changelist, quoted exactly: "Double randomization in monster hunt price negotiation dialog was removed and now you can get up to 70% more reward if you're lucky. It's still random, but you should be getting about 30% more money overall."; "Prices were significantly reworked."; "Price modifiers were altered, so you are no longer charged an astronomical sum for generic sword or a piece of wood."; "Bolts no longer cost a fortune, you can sell them and buy them for a reasonable price, but you can't dismantle them. Crafting price is roughly the same."; "Enchanter upgrades cost reduced to 3000/6000/9000 crowns for levels 1/2/3 respectively." (ENCH-02); and two known issues legacy did not fix: "Price modifiers for certain Blood and Wine quest are not applied (vanilla bug)." and "Certain merchants in Blood and Wine don't have price modifiers (vanilla bug)." The mod description adds "merchant price modifiers were changed, so items no longer have 400% extra charge;", "negotiating monster contract price can now increase your reward up to 70% (if you're very lucky, average number will be around 30%);" and "rare monster parts cost more than generic alchemy ingredients, so you can kill monsters and sell these ingredients for money." Legacy has no economy options in its menu and no strings of its own on money. The game's own texts involved (decoded from 1.32's and 5.x's `en.w3strings` with `w3strings.py`): the negotiation popup's title "Negotiate" (1066142, `panel_hud_dialogue_title_negotiation`) and the haggling tutorial "Haggling" (1083712), whose text 5.x rewrote: 1.32 "To haggle for a higher reward, choose an amount using … and confirm your choice by pressing … If your counterparty accepts your offer, you've made a deal! If your offer is too high, your counterparty will grow annoyed. Push too hard, and he or she will break off negotiations!", 5.x "To haggle for a higher reward, set your desired amount using … and confirm with …. Demanding too much may annoy your counterparty or end negotiations." (1083713, markup left out); the item tooltip's "Price" (593320); 5.x's shop button "Sell Junk" (1087827, `panel_button_inventory_sell_junk`, a 1.32 string 5.x now uses); Vimme Vivaldi's loan lines "How might I help, friend? Do you need to swap currencies? Or perhaps a small loan at a reasonable rate?" (1135519), "Wanna pay back my loan." (1032416), "Splendid. I see you as even more credit worthy than before." (1032418); the contract names "Contract: The Apiarian Phantom" (1075660, `mh307`) and "Contract: The White Lady" (1072856, `mh308`). Legacy changed none of them.

**What 5.x did in this area** (from `vanilla-5.x`, unverified in game). Next to nothing in what legacy touched: **no item price** changed (every one of the 9,657 item entries 1.32 and 5.x share, 4,754 of them regular, has 1.32's price), no price tag on those items, **`economy_tagmodifiers.csv` is 1.32's** row for row, and the money code is 1.32's (`W3MerchantNPC`, the funds functions and defaults of `CInventoryComponent`, the haggling in `CR4HudModuleDialog`, the crafting fee in `W3CraftsmanComponent.CalculateCostOfCrafting`, the native price functions `GetItemPriceModified`, `GetItemPriceCrafting`, `GetItemPriceRepair`, `GetItemPriceDisassemble`, `GetItemPriceRemoveUpgrade`, `GetItemPriceAddSlot` and their callers), as are the Vivaldi scene, the Hearts of Stone tax quest and the `mh307` scenes (re-save noise only). What 5.x added or moved: **gold in 7 rewards** (Emhyr's payment for Ciri `q110_1b_accepted_emhyrs_reward` 2,000 → 4,000; Hearts of Stone's `q605_mirror_finale_cash` 5,000 → 10,000; the baron's `q107_4_reward_baron` 100 → 150; `q103_06_find_daughter` 50 → 200; and three raises legacy made too: the prologue griffin `q002_3_griffin_dead_reward` 150 → 250, `q304_02_rosa_pays` 50 → 100, `mq0001_01_reunite_brothers` 0 → 25) and 5 new rewards (`sq106_3_hammond_killed_crach` 200, `mq1060_priest_reward` 200, `q504_horse_returned` 15, three `mq1060` schematic rewards without gold); **378 new items** (175 regular) with their own prices at 1.32's scale: the Netflix set (armor, swords and 36 schematics), Dol Blathanna, White Tiger, Vixen, Scarlet Crest, Top Notch and the Fire Horse gear, three Gwent cards, two potions, `mq1060`'s quest items; the shop's **"Sell Junk"** button (`CR4InventoryMenu.OnSellAllJunk`: every junk item sold at the shop's price, as much as the merchant can pay); **transmogrification** with its own fee (`transmogMenu.ws`: 100 crowns × a category factor × a rarity factor, independent of item prices); a fact per Gwent card a merchant has given (`merchant_card_<card>_already_given`); and the guards' toll by difficulty with caps (already the port's legacy rule, DIFF-07). **Nothing in 5.x scales a price by difficulty:** no script reads the difficulty next to a price, a fee, funds or a reward's gold (`OnGiveReward` reads it for experience only, XP's), and the price table has no difficulty column; the only money rule by difficulty is the guards' toll (DIFF-07).

**How legacy Ghost Mode implements it.** Data: the `price` attribute of 3,683 item entries (1,769 regular, 1,914 NG+) and the `mod_*` price tags of 604 (291 regular, 313 NG+), in 164 item files (regular and NG+) of the base game, both expansions and seven free DLCs; 31 of the 33 rows of `economy_tagmodifiers.csv`, two of them ENCH-02's and ported (the shipped file equals legacy's design sheet `design-docs/price_modifiers.csv`); the `gold` of 188 rewards in five `rewards.xml` files. Scripts: `CInventoryComponent`'s default `daysToIncreaseFunds` 5 → 3, `W3MerchantNPC.OnSpawned` (funds set up again below 100 crowns, 1.32: at 0), `CR4HudModuleDialog.OpenMonsterHuntNegotiationPopup` (the haggling range). Binary files: `vimme_vivaldi_default.w2scene` (the loan's repayment), `mq6003_taxes.w2phase` (when the Hearts of Stone tax quest starts), `mh307_01_halflings.w2scene` and `mh307_05_halflings_closing.w2scene` (a fix of the contract's reward name). The native price code is untouched: legacy works through data alone.

Unit lists: [attribution.csv](attribution.csv): mapped 2026-11-01 from the changelist's sections, the mod description, legacy's design sheet, every hand-off to ECON in the other areas' files, a comparison of every item's price and price tags and every reward's gold in the three branches (`tools/econ_prices.py`, `vanilla-1.32`, `legacy-GM`, `vanilla-5.x`, regular and NG+ folders), the price table row by row, a script diff of every function legacy changed that names money, prices, funds, merchants or rewards, `bindiff.py` over every binary file legacy changed (money amounts, quantities, funds, price properties), and sweeps (`unit_sweep.py` for price, money, funds, gold, crowns, merchant, shop, reward, haggle, bribe, `AddMoney`, `RemoveMoney`; the remaining unattributed units checked for a price, tag or gold change: none). **3,935 units carry an ECON feature**: 1,108 newly attributed, ECON added to 2,827 shared units (the item entries ARM, SWD, ITEM, CRAFT, FOOD, ALCH, XBOW, AI and ENCH hold; LOOT's and XP's rewards). By type: 3 script units, 1,971 XML units and 1,928 NG+ XML units (of the XML units 187 rewards and the Vivaldi loan reward), 29 CSV rows, 4 binary files. Unattributed units: 2,223 before, 1,115 after; none of those left carries a money change (weights, WGT's; the trophies' abilities, TRPH's; engine class re-declarations and strings already noted). The 193 items legacy added (cooking recipes, the Kaer Morhen set, the master kits, the dismantle kits, ...) are not ECON's: their prices came with their features, and the port has legacy's price for every one of them (checked against the DLC). Port status: **mapped** (2026-11-01), analysed against 5.x from the code and data (unverified in game); the [area decisions](#area-decisions) made and the porter's calls confirmed by the owner (2026-11-01); slice E1 **verified** by script in both trees (2026-11-01, master `6931c39a`): the native price formula measured, `extend` on an item's price probed, legacy's price table installed; slice E2 **verified** by script in both trees (2026-11-01, master `26e66189`): legacy's list prices and price tags on all 3,711 ECON item entries (regular and NG+) and PE13; DE2 left for slice E5; slice E3 **verified** by script in both trees (2026-11-01, master `b6c61d57`): merchants restock their money every 3 days and get it set up again below 100 crowns, and a contract's haggling bar goes up to double the reward (the employer accepts up to 1.2–1.7 ×) ([ECON-08](#econ-08-merchants-money), [ECON-09](#econ-09-contract-haggling)); slice E4 **verified** by script in both trees (2026-11-01, master `d44d60c1`): legacy's gold on the 187 ECON-10 rewards and the loan's reward, DE1's four at legacy's gold, 5.x's new rewards at 5.x's (PE9) ([ECON-10](#econ-10-quest-reward-gold)); slice E5 **verified** by script in both trees (2026-11-01, master `4cd642be`): Vivaldi's repayment 390, the tax collector at 10,000 crowns, the Apiarian Phantom's own reward name (ECON-11, ECON-12, binary edits of 5.x's files, checked offline; the scenes in play need saves at those points in the story), 5.x's 79 new priced items by DE2 (the Netflix set by Wolf, the owner's choice; the other sets by hand, porter's calls) ([slice E5](#slice-e5-scenes-and-5xs-new-items-2026-11-01)). **All of ECON is ported and audited** ([ECON audit](#econ-audit-2026-11-01), 2026-11-01: 8 findings; next the clear fixes F1, F4 and F6 and the owner's decisions F2 and F3).

**Size.** Mostly data, mechanical: about 3,700 item prices and 600 tag sets through the item layer the other areas built, one price table, 188 reward amounts through `gen_loot.py`, three small script changes and four binary edits. One area, one part, one audit at the end (PE1).

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

Prices are list prices (the item's `price`); a shop multiplies them by the factors of the item's price tags for the merchant's type and region (ECON-05), Geralt's sale by the sale factor (ECON-06), a craftsman's fee by the service's factor (ECON-07). How the native code combines them was measured in slice E1 (**verified**, [game-5.0-changes.md](../game-5.0-changes.md#gameplay-systems-from-the-official-patch-notes), "Prices"): a merchant asks ceil(list × the product of his factors for the item's tags), `mod_legendary`'s factor already in the list; he pays Geralt `mod_sale`'s share **of that asking price**, not of the list price; a fee is ceil(list × the service's factors); a bolt costs a tenth of its list price; gear's list price in play is its definition's plus a share from its stats (Long Steel Sword 27 → 32). The table below gives list prices and factors as the data has them.

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
| Port form | `item_layer.py`: ECON owns the `price` attribute of its units (`ATTRS`), applied by whichever tool writes the entry whole for another area (`item_layer.apply_item`: `gen_arm_items.py`, `gen_swd_items.py`, `gen_arm_km.py`, `gen_ench.py`, `gen_item.py`; the razor's hand-written `gm_ui.xml`); the rest by `tools/gen_econ.py` in `gm_econ.xml`, in the [form the owner chose](#the-form-of-the-item-entries-the-owners-decision-2026-11-01): short `extend` entries, Hearts of Stone, block changes and NG+ whole (PE2, PE3) |
| Port status | **verified** by script in both trees (slice E2, 2026-11-01, master `26e66189`); 5.x's new gear (DE2) **verified** by script in both trees (slice E5, 2026-11-01, master `4cd642be`; Top Notch at its counterparts' legacy prices since the ECON audit's F3, master `a255d35d`) |
| Open checks | none for the base game's gear: a real sale and purchase **verified** on screen ([cleared run](#cleared-run-on-screen-2026-11-01), 2026-11-01). 5.x's new gear (DE2): its sale prices **verified** on screen; a purchase from a merchant met in play not seen (no merchant stocks it on the test save) |
| Save impact | none (the list price is read from the definition: the test save's items price at legacy's) |
| NG+ counterpart | legacy's NG+ prices (equal to its regular ones but for six Red Wolf tier-1 pieces), in whole entries; checked by `gen_econ.py --verify`, untested in game |

**What it does** (changelist 943–945, 671; mod description section 4): gear is priced so that a merchant's price stays about what 1.32 charged while Geralt's sale pays more. A generic sword's list price roughly takes 1.32's merchant factor into itself (Long Steel Sword 27 → 57, which a smith sold at about 27 × 2.2 in 1.32 and sells at 57 × 1 in legacy); witcher gear, relics and expansion gear rise most (Bear Armor 1 455 → 1,851, Aerondight 484 → 1,155, Aerondight of Blood and Wine 700 → 1,750, Wolf Armor 2 of the free DLC 640 → 1,875, the Wolf DLC swords ×3.4 to ×4.1); cheap generic armor falls (Heavy armor 01 736 → 284, Medium armor 01 198 → 145, Light armor 01 96 → 82); horse gear rises (Blood and Wine's saddles 100 → 450, the Devil Saddle 100 → 1,000); bolts are priced to be bought and sold (Tracking and Bait 86 → 70, Broadhead 80 → 120, Explosive 132 → 170, Explosive Legendary 218 → 200). In the regular files, 781 gear entries: steel swords 187 (×1.57 in all, median ×1.93; NPC and secondary weapons among them, AI's and SWD's hand-offs), silver swords 105 (×1.54), armor 155 (×1.10), boots 104 and gloves 86 (×2.51 each), trousers 91 (×1.92), crossbows 19, bolts 13, horse gear 20, a staff 1.

**Implementation (legacy):** the `price` attribute of the item entries in `def_item_weapons*.xml`, `def_item_crafting_weapons.xml`, `def_item_armor*.xml`, `def_item_boots/gloves/pants.xml`, `def_item_crafting_armor/boots/gloves/pants.xml`, `def_item_bolts.xml`, `def_item_weapons_crossbow(s).xml`, `def_item_horse.xml`, the standalone starts' files and the free DLCs' item files (`dlc1`, `dlc5`, `dlc10`, `dlc12`, `dlc13`, `dlc14`, `dlc15`), regular and NG+.

**5.x:** 1.32's prices on every existing item. In the port the entries ARM, SWD, ITEM and XBOW give whole (2,641 entries in all areas) carry 5.x's price, so XBOW's sellable bolts sell at 5.x's prices today (PB3).

**Decisions:** legacy's prices (PE2, PE3). 5.x's new gear and horse gear priced by analogy (DE2 (b), owner, 2026-11-01): each piece at the ratio legacy applied to the 1.32 item it copies or matches by class and tier (Heavy armor 03 Netflix 824 → 856, as Heavy armor 03; the Netflix set like Wolf School's piece of the same tier, the owner's choice of counterpart (2026-11-01): Netflix Armor 842 / 3,240 / about 5,040; the Fire Horse saddle 150 → 450, as legacy's saddles), each item's counterpart in [slice E5's table](#de2-the-counterparts). With the price, each item takes its counterpart's legacy price tags (owner, 2026-11-03, whole-port audit A6-2), so it trades as its counterpart: `mod_legendary` (×1.2 at a merchant) added to the Netflix steel and silver swords (all tiers, Reinald's too), the Dol Blathanna and White Tiger armor (all four pieces), the Dol Blathanna longsword, the White Widow, both Vixens and both Top Notch swords, and removed from the six top-tier Netflix schematics (their Wolf counterparts have none; a schematic's `mod_legendary` has no effect at a merchant anyway, slice E5), regular and NG+ (`NGP` copies too); the Netflix armor, Scarlet Crest and the Fire Horse gear already carried their counterparts' tags. Not a deviation: content legacy never had. Ported in slice E5 (`item_layer.DE2`), the tags on 2026-11-03 (Verified on the area build (fx-data, 2026-11-03, both trees; scripted: `GMTest_data_items` in the regression, failing first on a throwaway build with the old data); `gen_econ.py --verify` checks every DE2 item's tags against its counterpart's).

### ECON-02 Material, consumable and loot prices

| | |
|---|---|
| Kind | tuning |
| Pillars | P6 |
| 5.x class | clean |
| Flags | balance |
| Depends on | CRAFT-07 (the ingredients' entries), FOOD-04 (food and drink), ENCH (rune and glyph items), ITEM-11 (kits), TRPH (trophies, not mapped) |
| Skill trees | n/a |
| Port form | as ECON-01; BaW's dyes also lose `Relic _Stats` (their rarity, CRAFT's hand-off) through ECON-02's `base_abilities` block (`item_layer.BLOCKS`; the dyes whole, a block cannot go in an `extend` entry); NG+'s Gwent Almanac's `stackable` with its price (`ATTRS`) |
| Port status | **verified** by script in both trees (slice E2, 2026-11-01, master `26e66189`); the trophies' prices now, their bonuses TRPH's (PE11) |
| Open checks | none: "Sell Junk" at legacy's prices **verified** on screen ([cleared run](#cleared-run-on-screen-2026-11-01), 2026-11-01) |
| Save impact | none |
| NG+ counterpart | legacy's NG+ prices, whole entries, `--verify` only |

**What it does** (mod description: "rare monster parts cost more than generic alchemy ingredients, so you can kill monsters and sell these ingredients for money"): common alchemy ingredients get cheaper (Drowner brain 30 → 15, Nekker eye 30 → 19, Water essence 60 → 19, Fifth essence 60 → 30, Wyvern egg 70 → 38), mutagens dearer (Mutagen red 20 → 30, Greater mutagen red 20 → 90); gems and precious junk cheaper (Ruby 200 → 140, Pearl 100 → 40, Gold ore 100 → 32), basic materials sorted by worth (Steel ingot 6 → 16, Iron ore 2 → 4, Cotton 2 → 1, Linen 16 → 10, Hardened leather 66 → 54); food and drink a little dearer (Viziman Champion 7 → 9); trophies ×1.28; runes and glyphs ×1.07 (Rune svarog 220 → 366, Glyph aard lesser 239 → 192); repair kits cheaper (armor repair kits 60/120 → 30/50); Blood and Wine's dyes 191 → 50 and no longer of Relic rarity; Blood and Wine's paintings and other junk items ×2.5 (10 → 25); Blood and Wine's vampire masks 1 → 300; the quest item `q106_magic_communicator` 100 → 1; the auctioned painting of Hearts of Stone 150 → 500; three quest notes given a price of 1. In the regular files 583 entries: ingredients 200 (alchemy 104, crafting 96), junk 171, food and drink 80, runes and glyphs 59, trophies 28, Blood and Wine's misc junk 20, dyes 14, kits 4, quest items 7.

**Implementation (legacy):** `def_item_ingredients.xml`, `def_item_edibles.xml`, `def_item_junk.xml`, `def_item_dye.xml`, `def_item_trophies.xml`, `def_item_upgrades.xml` and Hearts of Stone's `def_item_ep1_upgrades.xml`, `def_item_alchemy_repair_kits.xml`, `def_item_quest.xml`, `def_item_books.xml` (NG+'s Gwent Almanac 1 → 10 and stack 1, as the regular entry), `def_item_misc.xml`, the free DLC's `def_item_dlc15_items.xml`; base game and both expansions, regular and NG+.

**5.x:** 1.32's prices. The "Sell Junk" button sells every junk item at the shop's price (ECON-06), so junk prices matter more to the player in 5.x.

**Decisions:** legacy's (PE2, PE3). The trophies' prices go now, with ECON; their bonuses stay TRPH's (PE11).

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
| Port status | **verified** by script in both trees (slice E2, 2026-11-01, master `26e66189`); the Netflix schematics (DE2) **verified** by script in both trees (slice E5, 2026-11-01, master `4cd642be`; at their Wolf counterparts' legacy prices since the ECON audit's F3, master `a255d35d`) |
| Open checks | — |
| Save impact | none |
| NG+ counterpart | legacy's NG+ prices, whole entries, `--verify` only |

**What it does:** schematics cost more, in step with the gear they make (Bear Armor schematic 67 → 239, EP1 Viper School steel sword schematic 77 → 280, Crafted Burning Rose Sword schematic 81 → 250); the free Wolf DLC's schematics ×3.25; bolt schematics about the same (Explosive Bolt schematic 26 → 34); Blood and Wine's dye recipes ×1.07 and mutagen recipes ×1.15. Regular: 384 schematics (×1.81 in all) and 21 alchemy recipes.

**Implementation (legacy):** the schematic and recipe items of `def_item_crafting_recipes.xml` (base, Hearts of Stone, Blood and Wine), `def_item_ep1_crafting_recipes.xml`, `def_item_crafting_recipes_bolts.xml`, `dlc10_wolf_recipes.xml`, `def_item_alchemy_recipes_dye.xml` and `_mutagens.xml`, regular and NG+. Not the `price` of the `<schematic>` entries, which no code reads (CRAFT's DC3, ported).

**5.x:** 1.32's; 36 new Netflix schematics (29 to 2,563 crowns, their NG+ tiers included; DE2).

**Decisions:** legacy's (PE2); the 36 Netflix schematics by analogy (DE2 (b), owner, 2026-11-01), each at the legacy price of the Wolf School schematic that crafts its item's counterpart (the owner's decision on the ECON audit's F3, 2026-11-01; Netflix Armor schematic 173 / 638 / 1,027). Not a deviation: content legacy never had.

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
| Port status | **verified** by script in both trees (slice E2, 2026-11-01, master `26e66189`) |
| Open checks | — |
| Save impact | none (tags are read from the definition) |
| NG+ counterpart | legacy's NG+ tags, whole entries, `--verify` only |

**What it does:** the tags choose the rows of the price table a merchant applies, and whether he trades the item at all. Legacy marks the best gear `mod_legendary` (×1.2 in legacy's table: relic armor, the free Wolf DLC's swords, crafted and relic swords, Hearts of Stone's Burning Rose gear, the Ofir Crossbow R) and takes it off the Split and Explosive Legendary bolts; most materials keep one kind tag instead of two (Arachas eyes: `mod_alchemy, mod_valuable` → `mod_alchemy`; Ruby: `mod_crafting, mod_precious` → `mod_precious`; Monstrous tooth: `mod_crafting, mod_precious` → `mod_alchemy`), so alchemists and herbalists buy monster parts and smiths buy metals; Wolf liver and the Free nilfgaardian lemon become `mod_food`, Local pepper vodka `mod_alchemy` (FOOD's moved items). Three of 1.32's tags are misspelt and match no row: `mod_weapo` (Hearts of Stone's Plank), `mod_legendar` (NG+ EP1 Crafted Witcher Silver Sword) and `mod_valuable EP1` (a missing comma, NG+ Crafted Burning Rose Sword); legacy fixes them. Regular: 278 entries (in all regular entries: `mod_legendary` +110, `mod_valuable` −80 and +30, `mod_precious` −48 and +5, `mod_crafting` −41 and +14, `mod_alchemy` +23 and −15, `mod_junk` −14 and +3, `mod_armor` +7, others 1 or 2).

**Implementation (legacy):** the `<tags>` of the same entries as ECON-01 to ECON-03.

**5.x:** 1.32's tags, the misspellings included.

**Decisions:** legacy's tags, the misspellings fixed with them (PE4).

### Slice E2: item prices and tags (2026-11-01)

#### The form of the item entries (the owner's decision, 2026-11-01)

The project owner approved short `extend` entries for item prices and tags (2026-11-01): `<item name="…" price="…" on_conflict="extend">` with a `<tags>` node that adds tags and removes those written `-mod_…`, for items of the base game, Blood and Wine and the free DLCs; Hearts of Stone's items whole (`replace`: `extend` empties them); an item another area already writes whole keeps its whole entry, with ECON's price and tags set inside it; NG+ (`items_plus`) by `extend` if a probe shows it works there, else whole. The rule is in [development.md](../development.md#fine-grained-xml-overrides-50). Not a deviation: the same data either way.

**What the slice ships** (master `26e66189`, `tools/gen_econ.py`, `tools/item_layer.py`): legacy's price and price tags on all 3,711 ECON item units (1,783 regular, 1,928 NG+; 5.x changed none of those prices or tags, so no 5.x change is kept), in these forms:

| Form | Regular | NG+ |
|---|---|---|
| Inside an entry another area writes whole (`gm_arm_items.xml`, `gm_swd_items.xml`, `gm_item.xml`, `gm_arm_kaer_morhen.xml`, `gm_ench.xml`, the razor in `gm_ui.xml`) | 1,202 | 1,461 |
| `extend`, `gm_econ.xml` (the price; 28 also with tags) | 531 | — |
| `replace`, `gm_econ.xml`: Hearts of Stone | 36 | — |
| `replace`, `gm_econ.xml`: Blood and Wine's dyes (their `base_abilities`, a block) | 14 | — |
| `replace`, `gm_econ.xml`: NG+ (Hearts of Stone's among them) | — | 467 |

The 1.32 misspellings come out as legacy's (`Plank` `mod_weapo` → `mod_weapon`, NG+'s `EP1 Crafted Witcher Silver Sword` `mod_legendar` → `mod_legendary`, NG+'s Crafted Burning Rose Sword `mod_valuable EP1` → `mod_legendary` with ITEM-03's `EP1`). PE13: Protofleder Mutagen gets `mod_alchemy_table` (CRAFT-08, in its `gm_item.xml` entry, both folders). **NG+ `extend` could not be probed:** NG+ definitions are read only in an NG+ game, and neither test save is one; so NG+ takes whole entries ([open question](../open-questions.md)).

Porter's calls of slice E2 (none is a deviation; all confirmed by the owner, 2026-11-01, the ECON audit's F2):
- **NG+ entries whole.** No probe was possible, so every NG+ entry ECON writes is 5.x's NG+ entry whole with legacy's price and tags (467 entries, about 250 KB). No play effect (the same data). The alternative: NG+ `extend` entries, smaller but untested, with the risk of emptied NG+ items nobody sees until an NG+ playthrough.
- **DE2 left for slice E5.** 5.x's new gear keeps 5.x's prices for now (Netflix Armor 2 4,458, the Fire Horse saddle 150). The analogy does not fit one rule: 5.x copied Wolf School's 1.32 prices and stats onto its Netflix set (medium armor: Netflix Boots 1 216 = Wolf Boots 4 216, Netflix Gloves 2 549 = Wolf Gloves 5 549), while the decision's example pairs Netflix Armor 2 with Bear Armor 4 (×1.36, about 6,060); Bear's 1.32 prices are uneven, so its ratios run wild (Netflix Pants 1 287 × Bear Pants 4's ×13.96 = 4,007, against legacy's Bear Pants 4 at 2,388). **Decided by the owner (2026-11-01): Wolf**, as proposed: Wolf's piece of the same tier for the Netflix set (Netflix Armor 842, 3,240, about 5,040; Boots 634, 1,660, 2,620; Gloves 570, 1,410, 2,298; Pants 604, 1,665, 3,272) and its schematics at the Wolf schematics' ratios. Dol Blathanna, White Tiger, Vixen, Scarlet Crest and Top Notch copy no 1.32 item (no price or stat matches) and need a counterpart chosen by hand (slice E5, listed for the owner to check). The alternative was Bear for every Netflix piece, as the decision's first example.
- **The razor by hand.** Its entry is UI-15's hand-written `gm_ui.xml`; its price is set to legacy's 6 there, and `gen_econ.py --verify` checks it.
- **`gen_ench.py --verify`'s price-table check** expected 5.x's table with ENCH-02's two rows and had failed since slice E1 made the table legacy's; it now expects legacy's file (PE5).

**Verification (slice E2, 2026-11-01, both trees; master `26e66189`; `tests/gmTestsEconE2.ws`, the generated `tests/gmTestsEconData.ws`).** `gen_econ.py --verify`: the 4,314 regular and 4,757 NG+ prices and price tags of the 3,711 units equal legacy's, none differs, none comes out empty, no name is defined twice; `gen_item.py`, `gen_arm_items.py`, `gen_swd_items.py`, `gen_xbow.py` and `gen_ench.py --verify` read the `extend` entries over 5.x's (`gen_arm_items.dlc_entries`), 0 unexplained. Both new checks first ran on a throwaway build with slice E1's data (5.x's list prices; deleted afterwards): the data test failed 2,168 of its 4,529 readings, the merchant check 9 of 10 (only the Katakan mutagen control passed). Launches loaded the test save, saves locked (`gmtest_nosave`).

| Check | How | Classic tree | New tree |
|---|---|---|---|
| Every regular ECON unit (1,783 items: base game, Blood and Wine, Hearts of Stone, the free DLCs): its definition's price, category and name key (none emptied) and each 1.32, legacy or 5.x price tag present or absent, as Ghost Mode's DLC gives them | scripted: the definitions manager (`GetItemPrice`, `GetItemCategory`, `GetItemLocalisationKeyName`, `ItemHasTag`), `GMTest_econdata`, in the regression | 4,529 of 4,529 | 4,529 of 4,529 |
| Asking and paying prices worked from legacy's list prices and table: Bear Armor 1 and Ruby at the Novigrad armorer, Long Steel Sword, Steel ingot and Tracking Bolt at the Novigrad weaponsmith, Drowner brain and Arachas eyes at the Novigrad herbalist, Viziman Champion at the No Man's Land innkeeper | scripted: native price functions on spawned merchants, `GMTest_econ_e2`, in the regression | 8 of 8 | 8 of 8 |
| PE13: Protofleder Mutagen (and the Katakan mutagen as a control) shown by the dismantling station's rule | scripted: `ShouldShowItem`'s condition on Geralt's copy, `GMTest_econ_e2` | 2 of 2 | 2 of 2 |
| Slice E1's check (the formula) on the new list prices | scripted, `gmtest_econ_e1` | 80 of 80 | 80 of 80 |

Prices before and after (read in game; asking / paying, crowns; "E1" is 5.x's list prices with legacy's table):

| Item (list in play: 5.x → legacy) | Merchant | 5.x | E1 | E2 (legacy's) |
|---|---|---|---|---|
| Bear Armor 1 (541 → 1,937, legendary) | Novigrad armorer | 2,619 / 432 | 682 / 170 | 2,441 / 610 |
| Bear Armor 1 | Skellige weaponsmith | 2,420 / 363 | 585 / 146 | 2,092 / 523 |
| Long Steel Sword (32 → 62) | Novigrad weaponsmith | 74 / 12 | 34 / 8 | 66 / 16 |
| Ruby (200 → 140) | Novigrad armorer | — | 278 / 69 | 168 / 42 |
| Drowner brain (30 → 15) | Novigrad herbalist | 75 / 11 | 33 / 8 | 17 / 4 |
| Arachas eyes (45 → 38) | Novigrad herbalist | 227 / 34 | 55 / 13 | 42 / 10 |
| Steel ingot (6 → 16) | Novigrad weaponsmith | — | 7 / 1 | 19 / 4 |
| Tracking Bolt (86 → 70, a bolt) | Novigrad weaponsmith | 19 / 3 | 9 / 2 | 7 / 1 |
| Viziman Champion (7 → 9) | No Man's Land innkeeper | 29 / 3 | 11 / 2 | 14 / 3 |
| Crafting a Bear Armor 1 | Novigrad armorer | 417 | 322 | 1,151 |

Slice E1 had predicted about 2,770 / 690 for Bear Armor 1 at the Novigrad armorer, scaling the stat share with the price; the share is added (1,851 + 86), so 2,441 / 610 ([game-5.0-changes.md](../game-5.0-changes.md#gameplay-systems-from-the-official-patch-notes), "Prices"). The regression: `gmtest_regress()` 1,209 passed, 0 failed, and `gmtest_panel()` 145 passed, 0 failed, in each tree (E1's 1,198 and 145: +11, the two new checks' reports). A real purchase, sale and "Sell Junk" at legacy's list prices on screen: **verified** in the [cleared run](#cleared-run-on-screen-2026-11-01) (2026-11-01).

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
| Port status | **verified** by script in both trees (slice E1, 2026-11-01, master `6931c39a`): legacy's table; the formula measured |
| Open checks | the Blood and Wine merchants of legacy's known issues (Later). A real purchase **verified** on screen ([cleared run](#cleared-run-on-screen-2026-11-01), 2026-11-01) |
| Save impact | none (expected) |
| NG+ counterpart | none (one table) |

**What it does** (changelist 944: "Price modifiers were altered, so you are no longer charged an astronomical sum for generic sword or a piece of wood"; mod description: "items no longer have 400% extra charge"): `economy_tagmodifiers.csv` holds a factor for each price tag (rows) by merchant type (11 columns: general, alchemist, armorer, barber, blacksmith, book, collector, dye, enchanter, herbalist, inn) and by region (Beauclair, No Man's Land, nonhuman, Skellige, Novigrad, Nilfgaard, and five bonus columns); a negative factor means the merchant does not trade items with that tag. In 1.32 a merchant who trades an item type applies about ×2.0–2.2 for it (`mod_weapon` at a blacksmith 2.2, `mod_alchemy` at an herbalist 2.15, `mod_food` at an inn 2.07) and ×2 for `mod_legendary`, so a legendary armor at an armorer meets ×2.2 × 2 = ×4.4 (the "400% extra charge"); legacy sets the type factors to 1 (0.9 at specialists for their own trade, 1.1 for collectors and a few), `mod_legendary` to 1.2, `mod_collectible` to 1.5 at alchemists and collectors (1 at herbalists, 1.32: 2), retunes the region factors (food in No Man's Land 2 → 1.5, upgrades in Nilfgaard 1.3 → 1, origin rows: a Nilfgaardian item among nonhumans 0.2 → 1, a Novigrad one 0.5 → 0.9) and keeps "does not trade" as −1. Example, measured (slice E1, Novigrad merchants spawned by script): a Bear Armor 1 (list in play 541, ×2 for `mod_legendary` = 1,082) at the Novigrad armorer cost ceil(1,082 × 2.2 × 1.1) = 2,619 crowns with 5.x's table and costs ceil(649 × 1 × 1.05) = 682 with legacy's, on 5.x's list price; with legacy's list price (slice E2: 1,851 in the definition, 1,937 in play) 2,441 (measured); a Drowner brain at the Novigrad herbalist 75 → 33 (ceil(30 × 1 × 1.1)), with legacy's list price 15 17 (measured).

**Implementation (legacy):** 22 rows: the item-type rows `mod_alchemy`, `mod_alcohol`, `mod_armor`, `mod_book`, `mod_crafting`, `mod_dye`, `mod_food`, `mod_horse`, `mod_upgrade`, `mod_weapon`, `mod_secondary`, `mod_junk`, `mod_valuable`, `mod_precious`; `mod_collectible`, `mod_legendary`; the six `mod_origin_*` rows. Legacy's design sheet (`design-docs/price_modifiers.csv`) equals the file.

**5.x:** 1.32's table. The native price code is presumed 1.32's (no script changed around it).

**Decisions:** legacy's table (PE5). Legacy's known issues (some Blood and Wine merchants and quest bonuses without factors) are vanilla's and stay; whether 5.x fixed them is for Later.

Porter's calls of slice E1 (none is a deviation; all confirmed by the owner, 2026-11-01, the ECON audit's F2):
- **Legacy's table now, legacy's list prices in E2.** Until slice E2 the port has legacy's factors on 5.x's list prices, a mix neither game had: merchants ask about half of what 5.x asked (a Long Steel Sword at the Novigrad weaponsmith 74 → 34, a Ruby 1,082 → 278) and, because the sale is a share of the asking price, pay Geralt less too (a Bear Armor 1 at the Novigrad armorer 432 → 170, a Ruby at the weaponsmith 178 → 69); E2's list prices (gear about ×1.5 to ×4) bring both back up to legacy's design. Not recorded as a deviation: an intermediate state inside the area, ended by E2 before ECON is signed off. The alternative, holding the table back until E2: the same end state, one slice later.
- **The form of E2's item entries.** E1 shows `extend` sets an item's price and edits its tags (`-tag` removes) for the base game, Blood and Wine and the free DLCs, and empties Hearts of Stone's items. Recommended for E2, as PE2 foresaw: the 986 entries no generator writes yet as small `extend` entries (price and changed tags), the 67 Hearts of Stone ones whole (`replace`), after probing NG+ `extend` in E2's first build. No play effect (the same data either way). The alternative: all 1,053 whole with `replace` from `gen_item.py` (about 1,050 more whole entries in the DLC, every 5.x change to those items merged by hand); this session's rule was `replace` only for slice E1's own data, so the owner picks.
- **The check reads list prices and tags live.** `gmtest_econ_e1` takes each item's list price and tags from the game and only the factors from legacy's table (written into the test), so it stays right when E2 changes list prices and tags. No play effect. The alternative, fixed crown amounts: simpler to read, rewritten at E2.
- **The repair fee and adding a socket are read, not checked.** Ended by the ECON audit (F4): both are checked since, by their measured formulas ([ECON-07](#econ-07-craftsmens-fees)).

**Verification (slice E1, 2026-11-01, both trees; master `6931c39a`; `tests/gmTestsEcon.ws`, `tests/gmTestsEconE1.ws`).** Merchants spawned from their entity files in White Orchard (the test save): the generic Novigrad weaponsmith (`type_blacksmith`), armorer, herbalist and general merchant, the Novigrad temple alchemist, the generic Skellige weaponsmith and herbalist, the generic No Man's Land weaponsmith, armorer and innkeeper. Their prices were read through the inventory's native price functions as the shop, crafting and smith menus call them (scripted calls, no menu opened): first with 5.x's table (106 readings of buy, sale and three fees, Heavy armor 01's random copies left out), which gave the formula ([game-5.0-changes.md](../game-5.0-changes.md#gameplay-systems-from-the-official-patch-notes), "Prices"); then the same reads with legacy's table (100 readings), every one as the formula gives it. The check `gmtest_econ_e1` first ran on a throwaway build with 5.x's table and failed 79 of 80 (only the Novigrad general merchant's funds modifier, 1.1 in both tables, passed); the throwaway build was then deleted. The `extend` probe ran on another throwaway build (deleted too). Launches loaded the test save and locked saves for the session (`gmtest_nosave`).

| Check | How | Classic tree | New tree |
|---|---|---|---|
| Eight merchants (six types, three regions): the funds modifier (`mod_funds`'s type × region) and, for nine items (Long Steel Sword, Bear Armor 1, Drowner brain, Arachas eyes, Ruby, Steel ingot, Tracking Bolt, Viziman Champion, Dye Black), the list price (legendary ×1.2), what the merchant asks, what he pays, and at the four craftsmen the crafting, dismantling and upgrade-removal fees, against the formula and legacy's table | scripted: native price functions on spawned merchants (`gmtest_econ_e1`, in the regression) | 80 of 80 | 80 of 80 |
| The same items at ten merchants, before and after the table (buy, sale, three fees) fit the formula exactly | scripted: `gmtest_econ_probe`, compared offline | 106 and 100 readings, no exception | (the table does not depend on the tree) |
| The game reads the mod's table: every changed factor moved the prices by its ratio (asking ×1/2.2 for a smith's weapon, legendary ×1.2/2, the sale share 0.165 → 0.25 of the asking price at the Novigrad weaponsmith) | scripted (as above) | seen | — |

Prices before and after (5.x's list prices, read in game; asking / paying, crowns):

| Item (list in play) | Merchant | 5.x's table | Legacy's table |
|---|---|---|---|
| Long Steel Sword (32) | Novigrad weaponsmith | 74 / 12 | 34 / 8 |
| Long Steel Sword (32) | No Man's Land weaponsmith | 57 / 6 | 29 / 7 |
| Bear Armor 1 (541, legendary) | Novigrad armorer | 2,619 / 432 | 682 / 170 |
| Bear Armor 1 | Skellige weaponsmith | 2,420 / 363 | 585 / 146 |
| Drowner brain (30) | Novigrad herbalist | 75 / 11 | 33 / 8 |
| Arachas eyes (45) | Novigrad herbalist | 227 / 34 | 55 / 13 |
| Ruby (200) | Novigrad weaponsmith | 1,082 / 178 | 278 / 69 |
| Viziman Champion (7) | No Man's Land innkeeper | 29 / 3 | 11 / 2 |
| Tracking Bolt (86, a bolt) | Novigrad weaponsmith | 19 / 3 | 9 / 2 |
| Crafting a Bear Armor 1 | Novigrad armorer | 417 | 322 |
| Crafting a Long Steel Sword | Novigrad weaponsmith | 13 | 16 |

The regression: `gmtest_regress()` 1,198 passed, 0 failed, and `gmtest_panel()` 145 passed, 0 failed, in each tree (XP's totals were 1,118 and 145: +80, the new check). A real purchase, sale, "Sell Junk" and crafting fee in the shop and smith menus: **verified** on screen in the [cleared run](#cleared-run-on-screen-2026-11-01) (2026-11-01).

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
| Port status | **verified** by script in both trees (slice E1, 2026-11-01, master `6931c39a`) |
| Open checks | the bonus columns (`area_*_bonus`, `quest_bonus`, `bonus_mq7018_*`) applied at no merchant tested: where they apply is not known (Later, with legacy's known issues). A real sale and "Sell Junk" **verified** on screen ([cleared run](#cleared-run-on-screen-2026-11-01), 2026-11-01) |
| Save impact | none (expected) |
| NG+ counterpart | none |

**What it does:** the `mod_sale` row is the share of an item's price a merchant pays Geralt. 1.32: 0.10 (general merchants) to 0.15 (smiths, armorers, inns), × 1.1 in Beauclair and Novigrad, × 0.8 in No Man's Land, × 0.9 among nonhumans; legacy: 0.20 for general merchants and 0.25 for every specialist, no region factor, and 1.11 in the four bonus columns (`area_nml_bonus`, `area_skellige_bonus`, `area_novigrad_bonus`, `quest_bonus`, where 1.32 has 1) and 0.91 in Blood and Wine's two `bonus_mq7018` columns. The sale is a share of the merchant's asking price (measured, slice E1), so legacy's larger share meets a lower asking price: Geralt selling a Long Steel Sword (list in play 32) to the No Man's Land weaponsmith got trunc(57 × 0.15 × 0.8) = 6 crowns with 5.x's table and gets trunc(29 × 0.25) = 7 with legacy's; a Bear Armor 1 to the Novigrad armorer 432 → 170 (trunc(682 × 0.25)) on 5.x's list price, 610 with legacy's list price (slice E2, measured); a Drowner brain to the Novigrad herbalist 11 → 8, with legacy's list price 15 4 (measured).

**Implementation (legacy):** the one row.

**5.x:** 1.32's row; the "Sell Junk" button uses it for all junk at once. XBOW's measurement in 5.x (a Tracking bolt of list price 86 sold for 3 crowns at a spawned Novigrad weaponsmith, an Explosive Legendary bolt of 218 for 16; Geralt's own inventory prices them 8 and 21) is explained by slice E1: a bolt is priced at a tenth of its list price, and the sale is a share of the asking price (asking ceil(86 × 2.2 × 1.05) = 199, a bolt 19; sale trunc(199 × 0.15 × 1.1) = 32, a bolt 3; the Explosive Legendary bolt's list 436 with `mod_legendary`'s ×2: asking 1,008, a bolt 100, sale 16).

**Decisions:** legacy's row (PE5).

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
| Port status | **verified** by script in both trees (slice E1, 2026-11-01, master `6931c39a`): crafting, dismantling and removing an upgrade; since the ECON audit (F4) also repair and adding a socket, and the enchanter's and Beauclair's columns |
| Open checks | Beauclair's column read on a spawned merchant given Beauclair's columns, not on a merchant placed in Toussaint; dismantling and removing an upgrade not seen on screen (scripted only). The crafting, repair and socket fees **verified** on screen ([cleared run](#cleared-run-on-screen-2026-11-01), 2026-11-01) |
| Save impact | none (expected) |
| NG+ counterpart | none |

**What it does:** a craftsman's fee is the item's price times the service's row (`GetItemPriceCrafting` and the others, native): crafting (`mod_craftitem`) 0.35 at armorers, blacksmiths and dye makers, 0.4 at the enchanter in 1.32 → 0.45 for all four in legacy, with Beauclair 1.25 → 1.15 and No Man's Land 0.95 → 0.8; removing an upgrade (`mod_removeupgrade`) the enchanter 0.35 → 0.3 and the same region changes (nonhumans 0.95 → 0.9); adding a socket (`mod_addslot`) the enchanter 0.3 → 0.35 and no Novigrad surcharge (1.1 → 1); repair (`mod_repair`) the enchanter 0.28 → 0.25 and the regions as removing upgrades; dismantling (`mod_disassemble`) the enchanter 0.25 → 0.2 and the regions as crafting. Measured (slice E1): a fee is ceil(list in play × the row's type × region factors), the list with `mod_legendary`'s factor: crafting a Bear Armor 1 at the Novigrad armorer ceil(1,082 × 0.35 × 1.1) = 417 crowns with 5.x's table, ceil(649 × 0.45 × 1.1) = 322 with legacy's on 5.x's list price, 1,151 with legacy's list price (slice E2, measured). **Repair** (measured, ECON audit F4): per missing durability point ceil(Geralt's own list price × `mod_repair`'s type × region factors ÷ 100), the total that times the missing points (a Bear Armor 4 at half durability at the Hearts of Stone enchanter: 18 a point, 900 crowns; 20 and 1,000 with 5.x's table). **Adding a socket** (measured, ECON audit F4): ceil((293 + the list in play × `mod_addslot`'s type × region factors) × (the item's sockets + 1)); the 293 is the same for every item, at every merchant and with either table, and is not a row of the table (a Long Steel Sword without sockets: 315 at the enchanter, 630 for its second; 314 with 5.x's table; 355 at the Novigrad weaponsmith, 362 with 5.x's Novigrad surcharge).

**Implementation (legacy):** the five rows. The enchanter's `mod_enchantment` and `mod_removeenchantment` are ENCH-02's (ported).

**5.x:** 1.32's rows and code; the blacksmith's repair panel rebuilt around the same `GetItemPriceRepair` (ITEM's note); the new transmogrification fee is its own formula (100 × category × rarity factors), not a row of the table.

**Decisions:** legacy's rows (PE5); 5.x's transmogrification fee as it is (PE12).

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
| Port status | **verified** by script in both trees: the `mod_funds` row (slice E1, 2026-11-01, master `6931c39a`); the restock interval and the reset below 100 (slice E3, 2026-11-01, master `b6c61d57`) |
| Open checks | a merchant met in play restocking after 3 game days (tested on spawned merchants with the last restock moved back by script; no game time passed). Not done in the cleared run (2026-11-01): it needs 3 game days to pass, a time skip the test save must not take; needs a play session or a save made for it |
| Save impact | none (expected: a merchant's money is in the save and the new rules act at the next spawn or restock) |
| NG+ counterpart | none |

**What it does:** a merchant starts with an amount by class (poor 200, average 500, rich 1,000, quick-start 5,000) and, when Geralt talks to him after the interval, gains a restock (100, 150, 1,000, 1,000 + 2,500), the setup and the restock each times the funds factor (`mod_funds` by merchant type and region), while his money is below a ceiling (2,500, 5,000, 7,500, 15,000), which is not multiplied by the factor; `IncreaseFunds` only checks that the money is below it, so a restock can take a merchant over it. Legacy raises the factor for alchemists (1.08 → 1.2), collectors (0.97 → 1.5), inns (1.05 → 1.2), herbalists (1.02 → 1.1), smiths and the enchanter (1.7 → 1.8), lowers it a little for armorers (1.85 → 1.8) and dye makers (1.65 → 1.6), and sets barbers and booksellers to 1; restocks every 3 days instead of 5 (`daysToIncreaseFunds`); and sets a merchant's money up again when he has less than 100 crowns at spawn, not only at 0. Example: an average Novigrad smith gains 150 × 1.7 × 1.1 (about 280) every 5 days in 1.32, 150 × 1.8 × 1.1 (about 297) every 3 days in legacy; an alchemist found with 60 crowns gets his 500 × factor again.

**Implementation (legacy):** `mod_funds`; `CInventoryComponent`'s `default daysToIncreaseFunds = 3`; `W3MerchantNPC.OnSpawned`'s `GetMoney() < 100`. `OnInteraction`'s other changes are ITEM-02's and LOOT-05's.

**5.x:** 1.32's code and row.

**Decisions:** legacy's (PE5, PE6). No deviation: 5.x's `OnSpawned` already sets the funds up at 0, and with legacy's factors (at least 0.8) a merchant set up there holds at least 160 crowns, so the wrapper's check adds nothing then; between 1 and 99 crowns it sets them up as legacy's `< 100` did.

**Verification (slice E3, 2026-11-01, both trees; master `b6c61d57`; `tests/gmTestsEconE3.ws`).** Eight merchants spawned from their entity files in White Orchard (the test save), slice E1's: the generic Novigrad weaponsmith, armorer, herbalist and general merchant, the Novigrad temple alchemist, the generic Skellige weaponsmith, the generic No Man's Land armorer and innkeeper; all of the poor class but the alchemist (average). Scripted calls throughout, no menu opened, no game time passed. On a throwaway build without `merchants.ws` and `haggling.ws` (the tests kept; deleted) the checks failed 19 of 37: the interval and the reset at all eight merchants, the bar, the accept range and the always-successful deal; the money at spawn and a restock's amount (slice E1's factors) and the two mechanics checks passed there; the restock on talking after 3 days failed (no restock).

| Check | How | Classic tree | New tree |
|---|---|---|---|
| Eight merchants: the money at spawn (the class's 200, 500, ... × `mod_funds`'s type × region), the restock interval (3 days), a restock's amount (`IncreaseFunds`: 100, 150, ... × the factor), and at a spawn restored from a save (`OnSpawned` called again with `restored = true`) 60 crowns set up again (60 + the starting money), 150 kept, 0 set up | scripted: spawned merchants (`GMTest_econ_e3_money`, in the regression) | 32 of 32 | 32 of 32 |
| Talking to a Novigrad weaponsmith 2 and 3 days after his last restock: no restock, then +198 | scripted: `OnInteraction("Talk")` called with the last day moved back (`gmtest_econ_e3_restock()`, then `_end()`; it starts the merchant's scene, so it is not in the regression, as ITEM-02's restock) | 2 of 2 | 2 of 2 |

Money before and after (crowns; 5.x's computed from its table and code, Ghost Mode's measured):

| Merchant (class) | Money at spawn | Restock | Every | Found with 60 at a restored spawn |
|---|---|---|---|---|
| Novigrad weaponsmith (poor) | 374 → 396 | +187 → +198 | 5 → 3 days | 60 → 456 |
| Novigrad alchemist (average) | 594 → 660 | +178 → +198 | 5 → 3 days | 60 → 720 |
| Novigrad herbalist (poor) | 224 → 242 | +112 → +121 | 5 → 3 days | 60 → 302 |
| No Man's Land innkeeper (poor) | 168 → 192 | +84 → +96 | 5 → 3 days | 60 → 252 |
| No Man's Land armorer (poor) | 296 → 288 | +148 → +144 | 5 → 3 days | 60 → 348 |

Porter's calls of slice E3 (none is a deviation; all confirmed by the owner, 2026-11-01, the ECON audit's F2):
- **A wrapper, not a replacement, for the reset below 100** (as PE6 foresaw): the same money in play as legacy's one changed line; `OnSpawned` stays 5.x's, so CDPR changes to it need no merge. The alternative: `@replaceMethod OnSpawned` with legacy's line, exact by construction but one more replaced body.
- **The restock on talking is an exec check outside the regression**, as ITEM-02's: calling `OnInteraction("Talk")` starts the merchant's scene, and the game reports a scene playing until it quits, so the check runs at the end of a launch. The regression checks the interval that code reads (`GetDaysToIncreaseFunds`) and a restock's amount. No play effect. The alternative: the talk in the regression and its end in `gmtest_panel()`, with a scene running through the pause menu.

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
| Port status | **verified** by script in both trees (slice E3, 2026-11-01, master `b6c61d57`) |
| Open checks | a real negotiation in a contract's scene on screen (legacy's gold for the contracts came with slice E4, ECON-10). Not doable from the test save (cleared run, 2026-11-01): no contract is reachable in White Orchard's opening; needs a save at a contract's giver |
| Save impact | none |
| NG+ counterpart | none |

**What it does** (changelist 940–942): when Geralt haggles over a contract, the bar goes from the offered reward to reward × (1 + the upper limit), and the employer accepts up to reward × (1 + a random 20–70% of the upper limit). 1.32 draws the upper limit at random between 35% and 50%, so a deal pays at most 7% to 35% more (the "double randomization"); legacy fixes it at 100%, so a deal pays up to 20% to 70% more, a random ceiling the player feels out with the employer's "pretty close" answers (each costing patience), and a contract that is always successful (`alwaysSuccessful`) accepts up to double. Example: Contract: The White Lady (`mh308_final`, legacy 250 crowns): 1.32 (246 crowns) up to 263–332; legacy up to 300–425, and an employer who always agrees up to 500. The same multiplier applies to an item reward's count (`isItemReward`).

**Implementation (legacy):** one line of `OpenMonsterHuntNegotiationPopup` (`maxMult = RandRangeF(0.5, 0.35)` → `maxMult = 1`).

**5.x:** 1.32's code; the tutorial text rewritten (no numbers).

**Decisions:** legacy's (PE7). No deviation.

**Verification (slice E3, 2026-11-01, both trees; master `b6c61d57`; `tests/gmTestsEconE3.ws`).** The negotiation popup opened by script on the HUD's dialog module for Contract: The White Lady (`mh308_final`, 5.x's 246 crowns until slice E4) and closed again at once (`theGame.CloseMenu('PopupMenu')`); the bar and the employer's borders read from the module's fields; offers made through the popup's result function (`DialogueSliderDataPopupResult`, which the accept button calls), the reward multiplier a deal sets removed again. No scene played.

| Check | How | Classic tree | New tree |
|---|---|---|---|
| 60 openings: the bar from 246 to 492 every time; the employer's limit between 1.2 and 1.7 × the reward (seen 1.21 to 1.70: 297 to 418 crowns), "too much" 0.3 above it | scripted (`GMTest_econ_e3_haggle`, in the regression) | 60 of 60 | 60 of 60 |
| 60 offers at the limit a deal, 60 offers 2 crowns above it not | scripted (as above) | 60 of 60 | 60 of 60 |
| An always-successful negotiation: 492 (double) a deal | scripted (as above) | 10 of 10 | 10 of 10 |
| No reward multiplier and no popup left behind | scripted (as above) | seen | seen |

Contract: The White Lady (246 crowns): 5.x's bar up to 332–369 and a deal up to 263–332 (an always-successful one up to the bar's end); with slice E3 alone the bar up to 492 and a deal up to 295–418, an always-successful one up to 492. Since slice E4 she pays legacy's 250 crowns, and the same check (it reads the reward live) shows the changelist's example: the bar up to 500, a deal up to 300–423 seen (legacy 300–425), 500 when the employer always agrees.

The regression (slice E3's checks added): `gmtest_regress()` 1,246 passed, 0 failed, and `gmtest_panel()` 145 passed, 0 failed, in each tree (E2's 1,209 and 145: +37, the new check's reports). In the new tree's first launch the panel's AI-18 stone check found no knockdown (the known intermittent, [development.md](../development.md#testing-in-game)): 144 passed, 1 failed; 145 on the next fresh launch.

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
| Port status | **verified** by script in both trees (slice E4, 2026-11-01, master `d44d60c1`) |
| Open checks | a reward paid by a real quest on screen (tested through `GiveReward`, the function quests' reward blocks and scenes call). Not doable from the test save without advancing the story (cleared run, 2026-11-01); needs a save just before a quest's reward |
| Save impact | none (expected: rewards are read when given) |
| NG+ counterpart | none (one reward table) |

**What it does** (mod description section 6: "optional quests like horse races, fistfights and gwent give less experience and more items/money"): 187 rewards' gold retuned, 163 raised and 24 cut, 27,843 → 37,175 crowns over them (all reward gold 45,938 → 55,470, +21%). Contracts are set on round sums (31: 7,042 → 7,050 in all; Contract: The White Lady 246 → 250, `mh102_final_reward` 280 → 300, `mh104_father_reward` 210 → 100, `mh202_2_final_reward` 520 → 250, the free DLC troll `mh201_troll_left_alone` 50 → 150); side and minor quests raised (`sq108_griffon_killed` 25 → 250, `mq2024_final_reward` 20 → 250, `mq3002_3_chest` 50 → 300, `sq202_pirate_treasure` 60 → 250, `sq310_coins` 150 → 300, Blood and Wine's `sq701_champion` 200 → 500, `q705_beast_slayer` 5,000 → 6,000); horse races (`hr*`) and fistfights (`ff*`) doubled (`ff701_br_reward` 100 → 200); a few cut (Blood and Wine's wine-war rewards 700–900 → 600). Base game 143, Blood and Wine 36, Hearts of Stone 4, `dlc3` 3, `dlc15` 1; 31 of them change only gold.

**Implementation (legacy):** the `gold` attribute of the rewards in the `rewards.xml` files.

**5.x:** 7 rewards' gold changed (DE1; three of them to legacy's own amount: the prologue griffin 250, Rosa's payment 100, `mq0001_01_reunite_brothers` 25) and 5 new rewards, 3 of them with gold (PE9).

**Decisions:** legacy's gold (PE8). The four rewards 5.x raised on its own pay legacy's gold (DE1 (a), owner, 2026-11-01): Emhyr's payment for finding Ciri (`q110_1b_accepted_emhyrs_reward`) 2,000, Hearts of Stone's finale purse (`q605_mirror_finale_cash`) 5,000, the baron's payment (`q107_4_reward_baron`) 100, `q103_06_find_daughter` 100. Not a deviation: legacy's amounts. 5.x's new rewards keep 5.x's gold (PE9).

**Port (slice E4):** `gen_loot.py` sets legacy's `gold` on every ECON-10 unit, on the loan's reward (`vivaldis_loan`, ECON-11's one XML unit) and on DE1's three rewards that are not ECON-10 units (its `DE1` list; the fourth, `q103_06_find_daughter`, is one), in the same whole-file reward overrides LOOT-07 and XP-02 write. 188 `gold` values change (191 rewards, three of 5.x's raises already legacy's). `--verify` compares every reward of the six files with legacy's gold: 891 legacy's, 3 of 5.x's new rewards with 5.x's gold (PE9), 4 new ones without gold, 0 unexplained; it also checks that `DE1` lists exactly the rewards 5.x raised where legacy kept 1.32's gold. Over the 187: 1.32 27,843, 5.x 28,168, legacy and the port 37,175 crowns; over all rewards legacy 55,470, the port 55,885 (PE9's 415 more), 5.x 53,728.

**Verification (slice E4, 2026-11-01, both trees; master `d44d60c1`; `tests/gmTestsEconE4.ws`, `tests/gmTestsEconRewards.ws` generated by `gen_loot.py`).** All by script. On a throwaway build with 5.x's reward files (the tests kept; deleted) 14 of the 18 checks failed; the PE9 checks, the haggled reward (a deal at 300 pays 300 on any base) and the clean-up passed there.

| Check | How | Classic tree | New tree |
|---|---|---|---|
| Every reward ECON decides, as `GetReward` reads it: the 187 ECON-10 rewards 37,175 crowns, the loan 300, DE1's three 7,100, PE9's three 415; every one equal to its expected gold | scripted: the generated table (`GMTest_econrewards`, in `gmtest_regress()`) | 7 of 7 | 7 of 7 |
| Rewards given through `theGame.GiveReward` and the crowns gained: Emhyr's payment +2,000, the sq108 griffin +250 (and Heavy boots 06), the loan +300, a horse race (`hr101_2_item`) +50, a repeated race (`hr201_regular_reward_repeat`) +50, a fistfight (`ff104_1_victory`) +125, Hearts of Stone's purse +5,000; crowns, items and experience put back | scripted (`GMTest_econ_e4_give`, in `gmtest_panel()`) | 7 of 7 | 7 of 7 |
| Contract: The White Lady on 250 crowns: the negotiation popup's bar 250–500, the employer's limit seen 307–422 over 20 openings (legacy 300–425); a deal at 300 through the popup's result function sets the multiplier 1.2, and giving the reward then pays +300; no multiplier or popup left | scripted (as above) | 4 of 4 | 4 of 4 |

Money before and after, for the reward named (crowns; 5.x → the port): Emhyr's payment for finding Ciri 4,000 → 2,000; Hearts of Stone's finale purse 10,000 → 5,000; the baron's payment 150 → 100; `q103_06_find_daughter` 200 → 100; the sq108 griffin 25 → 250; Contract: The White Lady 246 → 250; `mh202_2_final_reward` 520 → 250; a horse race prize (`hr101_2_item`) 20 → 50; the fistfight `ff104` 80 → 125; Blood and Wine's fistfights 100 → 200; the Toussaint champion 200 → 500; Belgaard's wine-war reward 900 → 600; Vivaldi's loan 100 → 300 (repaid with legacy's 390 since slice E5); Killbill's new branch 200, the `mq1060` priest 200, the returned horse 15 unchanged.

Porter's calls of slice E4 (none is a deviation; all confirmed by the owner, 2026-11-01, the ECON audit's F2):
- **The loan's reward ships in E4, its repayment in E5** (the port order's split): until slice E5 patched Vivaldi's scene, he lent legacy's 300 and was repaid 1.32's 130 (ended by slice E5). The alternative: hold the loan's reward back to E5, so the loan and its repayment change together.
- **The rewards with experience are given with Geralt's level held at 100** (the test-only `GMTestSetLevelOverride`): such a reward gives 5 XP (one with a level) or its own experience (10, one without), taken back after, and the check runs only when Geralt is more than 50 XP from his next level, so no reward levels him up (a level-up asks for an autosave). No play effect. The alternative: give only rewards without experience.

### ECON-11 Quest money in scenes

| | |
|---|---|
| Kind | tuning |
| Pillars | P6 |
| 5.x class | clean |
| Flags | — |
| Depends on | ECON-10 (the loan is the reward `vivaldis_loan`) |
| Skill trees | n/a |
| Port form | `cr2w_patch.py` on 5.x's two files (`CPayStorySceneChoiceAction.money=130:390`; the two `CQCItemQuantity.quantity=35000:10000`), shipped in the bundle as ENCH-02's scenes are; the loan's gold through `gen_loot.py` (PE10) |
| Port status | **complete**: the loan's reward (`vivaldis_loan` 300) **verified** by script with ECON-10 (slice E4, 2026-11-01, master `d44d60c1`); the two files patched (slice E5, 2026-11-01, master `4cd642be`): checked offline (5.x's files with exactly legacy's edits, shipped in the bundle) and loaded by script in both trees |
| Open checks | the values in play (Vivaldi's repay choice showing 390, the tax collector arriving at 10,000 crowns): the game reads them only while the scene or the quest phase runs. Not doable from the test save (cleared run, 2026-11-01); needs saves at the loan and at the tax collector's quest |
| Save impact | none for the loan (expected); the tax quest's condition is read while its phase waits, so a save past it keeps its state |
| NG+ counterpart | none |

**What it does:** not in the changelist (omissions). Vimme Vivaldi's loan in Novigrad pays 300 crowns instead of 100 and is repaid with 390 instead of 130 (the same 30% interest); in Hearts of Stone, the tax collector's quest (`mq6003`, its quest phase waits "only if the player has 35000+ gold") starts once Geralt holds 10,000 crowns instead of 35,000, so a Geralt with legacy's scarcer money still meets it.

**Implementation (legacy):** `quests/secondary_npcs/default_dialogues/vimme_vivaldi_default.w2scene` (`CPayStorySceneChoiceAction.money` 130 → 390, behind `vivaldi_loan_taken`), the reward `vivaldis_loan` (gold 100 → 300), `dlc/ep1/data/quests/quest_files/mq6003_taxes/mq6003_taxes.w2phase` (two `CQCItemQuantity` on `Crowns`, 35,000 → 10,000).

**5.x:** 1.32's files (re-save noise only).

**Decisions:** legacy's amounts in 5.x's files (PE10).

### ECON-12 The Apiarian Phantom's reward name (fix)

| | |
|---|---|
| Kind | fix |
| Pillars | P6 |
| 5.x class | clean (5.x keeps the bug) |
| Flags | — |
| Depends on | ECON-09 |
| Skill trees | n/a |
| Port form | `cr2w_patch.py` on 5.x's two scenes: each `CStorySceneScript` call's `rewardName` parameter (`CStorySceneScript.@rewardName=mh308_final:mh307_02_minion_killed_completed`, the tool's new `@` edit of a call's parameters) and its editor comment, as legacy; the name added to each file's name table (PE10) |
| Port status | **verified** offline and loaded by script in both trees (slice E5, 2026-11-01, master `4cd642be`): the four edited script blocks byte for byte as legacy's |
| Open checks | the negotiation in play (its bar on 250 crowns, the haggled sum paid by the contract). Not doable from the test save (cleared run, 2026-11-01); needs a save at the Apiarian Phantom's giver |
| Save impact | none (expected) |
| NG+ counterpart | none |

**What it does:** not in the changelist (an omission). In Contract: The Apiarian Phantom (Novigrad, the halfling beekeepers), the opening scene's `SetRewardModifierScene` and `NegotiateMonsterHunt` and the closing scene's name the White Lady's reward, `mh308_final`, instead of the contract's own `mh307_02_minion_killed_completed`: the haggle reads the White Lady's sum as its base and stores the agreed multiplier under her reward, so the Apiarian Phantom pays its plain 249 crowns (legacy: 250) whatever Geralt agreed, and the White Lady's contract later finds a multiplier already set. The two scenes also set a 0.5 reward modifier in some branches (`SetRewardModifierScene` 0.5, three blocks; which branches is not identified): in 5.x that half pay too landed on the White Lady's reward; with the fix it lands on the Apiarian Phantom's own. Legacy points both scenes at the contract's own reward.

**Implementation (legacy):** `quests/generic_quests/novigrad/quest_files/mh307_minion/scenes/mh307_01_halflings.w2scene` and `mh307_05_halflings_closing.w2scene`: the `CStorySceneScript` blocks' comment and their `rewardName` parameter.

**5.x:** the bug is still there (the scenes are 1.32's).

**Decisions:** legacy's fix (PE10).

### Slice E5: scenes and 5.x's new items (2026-11-01)

**What the slice ships** (master `4cd642be`):

- **ECON-11, ECON-12:** the four binary files, 5.x's with legacy's edits made by `cr2w_patch.py` (`gen_econ.py`'s `BINARIES`, checked by `--verify`): `vimme_vivaldi_default.w2scene` (`CPayStorySceneChoiceAction.money` 130 → 390), `mq6003_taxes.w2phase` (both `CQCItemQuantity.quantity` 35,000 → 10,000), `mh307_01_halflings.w2scene` and `mh307_05_halflings_closing.w2scene` (two script blocks each: `SetRewardModifierScene`, and in the opening scene `NegotiateMonsterHunt`; their `rewardName` parameter and editor comment `mh308_final` → `mh307_02_minion_killed_completed`). `cr2w_patch.py` gained the edit of a script call's parameters (`@name`) and of String values ([tools.md](../tools.md)); `cr2w_dump.py` shows those parameters, so diffs show them.
- **DE2:** the list price of 5.x's 79 new priced items of the regular folder (gear, schematics, horse gear) and of their 109 NG+ entries (the same price; 5.x's `NGP` copies as their regular item), as `item_layer.DE2` fields that the tool writing each entry applies: `gen_arm_new.py` (the eight lower Netflix armor pieces), `gen_swd_items.py` (SWD-10's fourteen swords), `gen_econ.py` the rest (short `extend` entries; NG+ whole). Since 2026-11-03 also the counterpart's legacy price tags (`item_layer.de2_tags`, the owner's decision on the whole-port audit's A6-2): the item trades as its counterpart does, `mod_legendary`'s ×1.2 included. Category and texts stay 5.x's. Gwent cards, potions and quest items keep 5.x's prices. `gen_econ.py --verify` recomputes every price from its counterpart in 1.32 and legacy, and fails on a new priced 5.x gear, schematic or horse item left out.

#### DE2: the counterparts

The rule (DE2 (b)): 5.x's price × the ratio legacy applied to the counterpart (legacy ÷ 1.32), rounded; for gear with a 1.32 item's stats but another price (the Fire Horse gear), that item's legacy price. The **Netflix set** follows the owner's choice (2026-11-01): the Wolf School piece of the same tier, Netflix's three tiers matching Wolf's second, fourth and fifth (armor: the first, third and fourth upgrade); each Netflix schematic at the legacy price of the Wolf schematic that crafts its item's counterpart, and Top Notch at its counterparts' legacy prices (the owner's decision on the ECON audit's F3, 2026-11-01: 5.x's prices there are above Wolf's 1.32 placeholders or placeholders themselves, so a ratio put them out of line); Reinald's swords as the first tier; 5.x's `NGP Netflix … schematic` items (in the regular folder) as the regular schematics. Crowns are list prices (a merchant's asking price multiplies them by his factors, [ECON-05](#econ-05-merchants-buy-factors)).

| Item | 5.x | Counterpart | Legacy's ratio | Port | Why |
|---|---|---|---|---|---|
| Netflix Armor / 1 / 2 | 327 / 751 / 4,458 | Wolf Armor 1 / 3 / 4 | ×2.57 / ×4.31 / ×1.13 | 842 / 3,240 / 5,040 | the owner's choice: Wolf's piece of the same tier |
| Netflix Boots / 1 / 2 | 203 / 216 / 1,030 | Wolf Boots 2 / 4 / 5 | ×3.12 / ×7.69 / ×2.54 | 634 / 1,660 / 2,620 | as above |
| Netflix Gloves / 1 / 2 | 186 / 196 / 549 | Wolf Gloves 2 / 4 / 5 | ×3.06 / ×7.19 / ×4.19 | 570 / 1,410 / 2,298 | as above |
| Netflix Pants / 1 / 2 | 234 / 287 / 356 | Wolf Pants 2 / 4 / 5 | ×2.58 / ×5.80 / ×9.19 | 604 / 1,665 / 3,272 | as above; 604 and 3,272 are the owner's figures (the ratio gives 605 and 3,273) |
| Netflix steel sword / 1 / 2 (Reinald's = the first) | 130 / 689 / 1,958 | Wolf School steel sword 1 / 3 / 4 | ×4.18 / ×2.03 / ×0.87 | 544 / 1,402 / 1,709 | as above |
| Netflix silver sword / 1 / 2 (Reinald's = the first) | 167 / 229 / 1,973 | Wolf School silver sword 1 / 3 / 4 | ×3.78 / ×7.21 / ×1.29 | 631 / 1,650 / 2,540 | as above |
| Netflix Armor schematic / 1 / 2 | 80 / 151 / 538 | Witcher Wolf Jacket Upgrade schematic 1 / 3 / 4 | (its legacy price) | 173 / 638 / 1,027 | the legacy price of the schematic of the item's counterpart (the owner, F3) |
| Netflix Boots schematic / 1 / 2 | 30 / 58 / 213 | Witcher Wolf Boots Upgrade schematic 1 / 3 / 5 | (its legacy price) | 65 / 332 / 524 | as above |
| Netflix Gloves schematic / 1 / 2 | 29 / 46 / 116 | Witcher Wolf Gloves Upgrade schematic 1 / 3 / 5 | (its legacy price) | 114 / 267 / 460 | as above |
| Netflix Pants schematic / 1 / 2 | 31 / 89 / 276 | Witcher Wolf Pants Upgrade schematic 1 / 3 / 5 | (its legacy price) | 122 / 328 / 520 | as above |
| Netflix steel sword schematic / 1 / 2 | 37 / 123 / 253 | Wolf School steel sword Upgrade schematic 1 / 3 / 4 | (its legacy price) | 100 / 270 / 345 | as above |
| Netflix silver sword schematic / 1 / 2 | 57 / 147 / 245 | Wolf School silver sword Upgrade schematic 1 / 3 / 4 | (its legacy price) | 114 / 322 / 505 | as above |
| Heavy armor 03 Netflix | 824 | Heavy armor 03 | ×1.04 | 856 | a copy of it (price and stats) |
| Heavy gloves 04 Netflix | 140 | Heavy gloves 04 | ×3.36 | 470 | a copy of it |
| Dol Blathanna Armor, White Tiger Armor | 457 | Medium armor 10r | ×1.56 | 714 | **porter's pick, confirmed by the owner (F2):** relic medium armor (levels 8 and 12, the same 5.x prices); the relic medium chest nearest in 1.32 price (512) |
| Dol Blathanna Boots, White Tiger Boots | 141 | Heavy boots 07_crafted | ×2.04 | 288 | **porter's pick, confirmed by the owner (F2):** the relic medium boots nearest in 1.32 price (140) |
| Dol Blathanna Gloves, White Tiger Gloves | 93 | Guard Lvl2 Gloves 3 | ×3.01 | 280 | **porter's pick, confirmed by the owner (F2):** the relic medium gloves nearest in 1.32 price (94) |
| Dol Blathanna Pants, White Tiger Pants | 178 | Guard Lvl2 Pants 3 | ×1.93 | 343 | **porter's pick, confirmed by the owner (F2):** the relic medium trousers nearest in 1.32 price (210) |
| Scarlet Crest Armor | 730 | Medium armor 11r | ×1.03 | 755 | **porter's pick, confirmed by the owner (F2):** relic medium armor (level 41); the relic medium chest nearest in 1.32 price (774) |
| Scarlet Crest Boots | 177 | Heavy boots 07 | ×1.81 | 320 | **porter's pick, confirmed by the owner (F2):** the same rule (158) |
| Scarlet Crest Gauntlets | 220 | Thief Gloves | ×2.56 | 563 | **porter's pick, confirmed by the owner (F2):** the same rule (100; no relic medium gloves cost more in 1.32) |
| Scarlet Crest Trousers | 90 | Thief Pants | ×2.58 | 232 | **porter's pick, confirmed by the owner (F2):** the same rule (114) |
| Dol Blathanna longsword, Steel Vixen | 689 | Lune | ×1.66 | 1,145 | **porter's pick, confirmed by the owner (F2):** relic steel swords; the relic steel sword nearest in 1.32 price (582), an Aard sword like Dol Blathanna's |
| White Widow of Dol Blathanna, Silver Vixen | 891 | Harpy | ×1.45 | 1,289 | **porter's pick, confirmed by the owner (F2):** relic silver swords; the relic silver sword nearest in 1.32 price (895), a bleeding sword like the Vixen |
| Top Notch Steel | 16 | Eredin Sword | (its legacy price) | 1,500 | the counterpart picked by the porter, its legacy price set by the owner (F3): a level-scaled relic whose 5.x price is a placeholder (16, the generic steel swords' 1.32 price); the level-scaled relic steel sword nearest in 1.32 price (20), itself a placeholder legacy priced like its relics |
| Top Notch Silver | 102 | Breathofthenorth | (its legacy price) | 1,050 | as above: a level-scaled relic (102, the generic silver swords' price); the relic silver sword nearest in 1.32 price (203), crit damage and dismemberment like it |
| Fire Horse Saddle | 150 | Toussaint saddle | (its stats) | 450 | the Toussaint saddle's stats (stamina 90); the decision's example |
| Fire Horse Blinders | 150 | Toussaint horse blinders | (its stats) | 250 | the Toussaint blinders' stats (panic 60) |
| Fire Horse Saddlebags | 200 | Toussaint horsebag | (its stats) | 450 | the Toussaint bag's stats (encumbrance 110) |

**Verification (slice E5, 2026-11-01, both trees; master `4cd642be`; `tests/gmTestsEconE5.ws`, the generated `tests/gmTestsEconData.ws`).** Offline: `cr2w_patch.py --selftest` (the String round trip; ECON-12's edits on 5.x's scenes come out byte for byte as legacy's script blocks); the dumps of the four shipped files against 5.x's differ only in the edited values, and the change equals legacy's against 1.32 (legacy also re-saved `mq6003_taxes.w2phase` as CR2W 162); the built `blob0.bundle` holds the four files byte for byte; `gen_econ.py --verify`: the files are 5.x's with exactly these edits (CRCs valid), every DE2 price follows its rule, 79 regular and 109 NG+ DE2 entries read as DE2 gives them, 0 unexplained (corrected by the ECON audit, F1: `--verify` read the entries as written; 69 of the NG+ ones had no `on_conflict`, so the game ignored them and only 40 read as DE2 gives them; fixed in the close-out). In game (the test save, saves locked): on a throwaway build with E4's data and E5's tests (deleted afterwards) the data test failed exactly the 79 DE2 items and the merchant check 3 of 3 (5.x's 4,458, 538 and 150); the load checks passed there too (they pass with 5.x's files as well: they only guard against a file the engine cannot read).

| Check | How | Classic tree | New tree |
|---|---|---|---|
| Every regular ECON unit and DE2 item (1,862 items): definition price, category and name key, each price tag present or absent | scripted: the definitions manager (`GMTest_econdata`, in the regression) | 4,740 of 4,740 | 4,740 of 4,740 |
| At a spawned Novigrad armorer: Netflix Armor 2 (definition 5,040, list 5,181, asks 6,528, pays 1,632; 5.x 5,794 / 1,448), Netflix Armor schematic 2 (1,031: asks 1,191, pays 297; 5.x 622 / 155), the Fire Horse Saddle (450: asks 495, pays 123; 5.x 165 / 41), each against the formula | scripted: native price functions on a spawned merchant (`GMTest_econ_e5`, in the regression) | 3 of 3 | 3 of 3 |
| The four patched files load | scripted: `LoadResource` (as above) | 4 of 4 | 4 of 4 |

The regression: `gmtest_regress()` 1,260 passed, 0 failed, and `gmtest_panel()` 156 passed, 0 failed, in each tree (E4's 1,253 and 156: +7, the new check's reports; the data test's one report covers its 211 new readings); AI-18's stone check passed on the first launch in both trees. Needs saves at those points in the story (the cleared run, 2026-11-01, could not reach them from the test save): Vivaldi's repay choice (390) and the tax collector's arrival at 10,000 crowns in play; a real negotiation of Contract: The Apiarian Phantom (the bar on its 250 crowns, the haggled sum paid by it, no multiplier left on the White Lady's reward). A Netflix piece's and the Fire Horse saddle's sale prices on screen, the saddle sold: **verified** in the [cleared run](#cleared-run-on-screen-2026-11-01).

Porter's calls of slice E5 (none is a deviation; all confirmed by the owner, 2026-11-01, the ECON audit's F2):
- **The hand-picked counterparts** (the table's picks; Top Notch's prices then set by the owner, F3): for Dol Blathanna, White Tiger, Scarlet Crest, the Vixen and Top Notch, the legacy relic of the same kind and slot nearest in 1.32 price, so the ratio lands near what legacy charges for such relics (chests 714–755, swords 1,145–1,289). In play: the Dol Blathanna and White Tiger chests list at 714 (5.x 457), the swords at 1,145 and 1,289 (689, 891); Top Notch Steel at 1,500 (16) and Silver at 1,050 (102) since F3. The alternatives: by bonus theme instead of price (Top Notch Steel as Headtaker, SWD-10's match: 159; the White Widow as Loathen, fire and burning: 2,011), or a class median ratio (White Tiger Armor ×1.74: 795, the decision's example).
- **The owner's two figures kept** (Netflix Pants 604, Netflix Pants 2 3,272) where the ratio gives 605 and 3,273: one crown each. The alternative: the ratio's result.
- **The NG+ copies at the regular price** (5.x prices them alike; legacy's NG+ prices equal its regular ones, PE3). No play effect outside NG+. The alternative: the counterparts' NG+ ratios (the same numbers today).
- **The scenes are checked offline and by loading.** The game reads the values only while the scene or quest phase runs, and playing them from a script needs their actors: listed for a cleared run. The alternative: a scripted scene playback (untried).

### Cleared run on screen (2026-11-01)

The first checks with the game in front and real input (master `a255d35d`, classic tree; the test save, no story progress, nothing saved). Merchants and craftsmen spawned from their entity files in White Orchard, their menus opened by script as the dialogue scenes open them (`gmtest_shopopen`, `gmtest_craftopen`, `gmtest_smithopen`: the `ShowMeGoods` path); every purchase, sale, craft and repair then made with the real mouse and keyboard, and the amounts read off the screen. Each was compared with the native price functions read on the same merchant (`gmtest_econ_probe`, `gmtest_econ_dur`), which slice E1's formula and slice E2's data test check against legacy.

| Check | On screen | Expected (read in game) | Result |
|---|---|---|---|
| Sale of a Long Steel Sword (5.x's English name "Witcher's Steel Sword") at the generic Novigrad weaponsmith | 16 crowns; Geralt 250 → 266, the smith 396 → 380 | 16 (slice E2's table) | **verified** |
| Its purchase back from the smith | 66 crowns; Geralt 266 → 200, the smith 380 → 446 | 66 | **verified** |
| "Sell Junk" (Space held) at the generic Novigrad general merchant: 3 Axe heads, 2 Bags of weed | 4 a piece (12 for the 3) and 3 a piece (6 for the 2); Geralt 200 → 218, the merchant 220 → 202; both stacks gone | 4 and 3 (list 25 and 21); the weaponsmith refuses junk (sale −5) | **verified** |
| Crafting a Gildorf sword (`Novigraadan sword 2`) at the Novigrad market smith (`novigrad_market_smith_01`; the generic weaponsmith has no craftsman component and shows no fee) | Price 98; "Successfully created: Gildorf sword"; Geralt 218 → 120, the smith 990 → 1,088 | 98 (list 196 × 0.45 × 1.1, rounded up) | **verified** |
| Repair at the same smith | the Witcher Silver Sword at "96 %" 5 crowns, paid (120 → 115, the smith 1,088 → 1,093); the Long Steel Sword at "96 %" 4 | 1 crown per missing durability point at these list prices (5 read at exactly 96.0; the screen rounds the percentage) | **verified** |
| Adding a socket at the Hearts of Stone enchanter ("Amateur Runewright") | Witcher Silver Sword 331, Long Steel Sword 315 (shown red: Geralt had 115; not bought) | 331 and 315 | **verified** (the fee; no socket added) |
| 5.x's new gear (DE2) at the generic Novigrad armorer | Netflix Armor 2 ("Grandmaster Forgotten Wolven Armor") sale price 1,632 (refused: the armorer had 396); the Fire Horse Saddle 123, sold (115 → 238, the armorer 396 → 273) | 1,632 (Geralt's list 5,181, legendary), 123 (list 450) | **verified** |

Not done (each needs a save at that point in the story, or game time to pass): a merchant met in play restocking after 3 game days; a contract negotiation; Vivaldi's and the tax collector's scenes; a real quest's reward; a Netflix piece bought (no merchant on the test save stocks one). Dismantling and removing an upgrade were not opened on screen.

### ECON audit (2026-11-01)

Done by a fresh session ([audit](../feature-mapping.md#audit-signing-a-feature-off)) on master `4cd642be` (port) and `0b1c9903` (docs), reading code and data, with game runs in both trees on 2026-11-01. The five slices' commits (master `6931c39a`, `26e66189`, `b6c61d57`, `d44d60c1`, `4cd642be`) and the master docs commits from `162b9c80` to `0b1c9903` were read. The methods the port replaces or wraps were each read against legacy (`legacy-GM`), 1.32 (`vanilla-1.32`) and 5.x (`vanilla-5.x`):
- `CR4HudModuleDialog.OpenMonsterHuntNegotiationPopup` (compared line by line with 5.x's body);
- `W3MerchantNPC.OnSpawned`;
- `CInventoryComponent`'s `daysToIncreaseFunds` and the funds functions (`SetupFunds`, `IncreaseFunds`, `GetFundsMax`);
- `W3MerchantNPC.OnInteraction`, with the two other areas' wrappers of the same events (LOOT-05's Balisse fruit, ITEM-02's low-level weapons);
- XP's `OnGiveReward` (the gold × the haggled multiplier).

Every 5.x caller was listed:
- `NegotiateMonsterHunt` (`scene_functions.ws`), the popup's only caller;
- the other popups of the same module, which legacy did not touch: the reverse haggling `OpenLowerPriceNegotiationPopup` and the bet popup;
- every `SetupFunds`, `IncreaseFunds` and `GetDaysToIncreaseFunds` (only `W3MerchantNPC`);
- every `AddMoney` and `RemoveMoney` in 5.x's scripts: shops, the smith menu's fees, transmogrification, rewards, scenes, containers, the crafting tutorial and debug functions;
- "Sell Junk" (`CR4InventoryMenu.OnSellAllJunk`);
- `ShowMeGoods`, the scene function that opens a shop.

**Data** was checked by scripts written for this audit, independent of `gen_econ.py` and `gen_loot.py` (each tool's `--verify` was run once, for comparison):
- every `<item>` of every definition file in the regular and NG+ folders of the three branches, and Ghost Mode's DLC over 5.x, resolved as the game does (`extend`, `replace`, plain entries);
- every `<reward>` of the six reward files in four sources: 1.32, legacy, 5.x and the port;
- the price table against legacy's, byte for byte;
- the four binary files, dumped with `cr2w_dump.py` from all four sources;
- every scene, quest phase and quest file of the installed 5.x game and the local 1.32 copy (6,222 scenes, 873 phases and 168 quests extracted read-only with `unbundle.py`), searched for the rewards, facts and thresholds ECON-11 and ECON-12 touch and for every contract negotiation.

**Checked and holding:**

**Data**
- **Item prices and price tags.**
  - Legacy changed the price of 1,769 regular and 1,914 NG+ entries (the mapping's counts) and the `mod_*` tags of 290 and 312. The mapping says 291 and 313: `Ofir Armor B`'s only change is a duplicate `mod_armor` dropped, which leaves its set of tags the same.
  - The ECON units are exactly the items whose price or tags legacy changed, minus the two whose only change is another area's tag: XBOW-03's quest bolt and CRAFT-08's Protofleder Mutagen. That is 1,783 regular and 1,928 NG+, and **no unattributed item was missed**.
  - Every one resolves to legacy's price and tags in both folders. The other areas' tags equal legacy's too: `mod_nosale` off the bolts and `mod_nosalem` (XBOW-03), `mod_alchemy_table` (CRAFT-08). No item has both a 5.x change and a legacy change to its price or tags.
  - Spot checks (port = legacy):

    | Item | 1.32 | Port |
    |---|---|---|
    | Long Steel Sword | 27 | 57 |
    | Bear Armor 1 | 455 | 1,851 |
    | Aerondight | 484 | 1,155 |
    | Explosive Bolt | 132 | 170 |
    | Drowner brain | 30 | 15 |
    | Ruby | 200 | 140 (`mod_precious` only) |
    | Steel ingot | 6 | 16 |
    | Dye Black | 191 | 50 |
    | Greater mutagen red | 20 | 90 |
    | Rune svarog | 220 | 366 |
    | the razor | 5 | 6 |
    | Heavy armor 01 | 736 | 284 |

    Other spot checks: Hearts of Stone's Plank keeps `mod_weapon` (the misspelling fixed, a whole entry), and NG+'s Gwent Almanac is stack 1 (legacy).
- **Entries.**
  - No `extend` entry on a Hearts of Stone item: all 501 Hearts of Stone entries in the DLC are `replace`.
  - No name is defined twice in one folder's DLC files, and no `-tag` appears outside an `extend` entry.
  - `gm_econ.xml`'s `extend` entries carry only `price` and `mod_*` tags. Its whole entries equal 5.x's but for price and tags, Blood and Wine's dyes' `Relic _Stats` (ECON-02) and NG+ Gwent Almanac's `stackable`.
  - No resolved item lost its category, texts or base abilities.
  - The remaining differences from legacy in those entries belong to other areas: weights (WGT, not ported; `gm_econ.xml`'s whole entries carry 5.x's weights too), and the recorded AI, ARM-12 and SWD-10 deviations.
- **DE2.** All 188 prices (79 regular, 109 NG+) equal the counterparts table, recomputed from 1.32 and legacy. No priced 5.x gear, schematic or horse item is left out, and 5.x's new potions, Gwent cards, quest items and masks keep 5.x's prices. For NG+, see F1.
- **The price table** (`economy_tagmodifiers.csv`) is legacy's byte for byte (MD5 equal). `economy_damagecurves.csv` is the same in all three branches.
- **Reward gold.**
  - All 898 rewards are as expected, none twice and none missing:
    - legacy's gold where legacy changed it: 188 rewards, the 187 and the loan;
    - DE1's four at 2,000, 5,000, 100 and 100;
    - PE9's three at 5.x's 200, 200 and 15;
    - 5.x's gold elsewhere.
  - Totals: 1.32 45,938, legacy 55,470, 5.x 53,728, the port 55,885. Over the 187: 27,843 → 37,175.
  - Beyond gold, the port's reward entries differ from 5.x's only in experience, level and items (LOOT-07's and XP-02's). 5.x changed nothing but gold on existing rewards, so the whole-file overrides revert none of 5.x's changes.
- **The binary files.**
  - In the dumps, the port differs from 5.x in exactly the values legacy changed against 1.32:
    - Vivaldi's `CPayStorySceneChoiceAction.money` 130 → 390 (the scene's only payment);
    - `mq6003_taxes`' two `CQCItemQuantity` 35,000 → 10,000;
    - in the `mh307` scenes, the four `CStorySceneScript` blocks that name a reward (opening scene: `SetRewardModifierScene` and `NegotiateMonsterHunt`; closing scene: two `SetRewardModifierScene`), their `rewardName` and comment.
  - Every opaque section blob is unchanged.
  - Legacy's other money edits to binary files are ported elsewhere: the enchanter's (ENCH-02) and a loot quantity (LOOT).
- **Other references** (the whole extracted game):
  - `vivaldis_loan` is given in two places, the Hearts of Stone auction scene and Novigrad's shops phase. Both read the reward's gold (300) and hold no amount of their own.
  - The only `CQCItemQuantity` on Crowns besides `mq6003` is `th700_red_wolf`'s 10.
  - The Apiarian Phantom's payment (`mh307_minion.w2phase`) gives `mh307_02_minion_killed_completed`, the name the fixed scenes now store the multiplier under. The White Lady's payment gives `mh308_final`.
  - Every other base-game contract haggles under the reward its own phase pays, and Blood and Wine's contracts do the same through their scenes' reward events. The 5.x bug is the Apiarian Phantom's alone, as legacy's fix assumes.

**Code**
- **Haggling.** The replaced body is 5.x's with one line changed (`maxMult = 1`). 5.x's body is 1.32's, and legacy's change is the same one line. `NegotiateMonsterHunt` takes the base from the reward's gold, so legacy's round sums set the bar (Contract: The White Lady 250 → 500).
- **Merchants' money.**
  - `daysToIncreaseFunds` is a private, non-editable variable, so no entity overrides the scope-based default of 3, and `OnInteraction` reads it through `GetDaysToIncreaseFunds` only.
  - `OnSpawned`'s wrapper gives legacy's money. 5.x's body sets the funds up at 0, and with legacy's `mod_funds` (lowest: a general merchant in No Man's Land, 1 × 0.8) a poor merchant gets at least 160 crowns there. The wrapper then sets up again a merchant holding 1 to 99, as legacy's `< 100` did.
  - The wrapper chain on `W3MerchantNPC` (ECON-08, LOOT-05, ITEM-02) has no ordering effect on money.
- **Paths outside the port**, all legacy's too (legacy changed none of them):
  - a shop opened by a quest scene (`ShowMeGoods`) restocks nothing;
  - only `W3MerchantNPC` sets up or restocks funds;
  - "Sell Junk" sells category `junk` at the shop's price, as far as the merchant's money goes;
  - transmogrification pays its fee into the merchant's money (PE12);
  - the bet and reverse-haggling popups keep 1.32's ranges;
  - `IncreaseFunds` stops only once the money reaches the class's ceiling (2,500 to 15,000, not scaled by the funds factor).
- **Both skill trees.** No skill, perk or mutation in either tree reads or changes a price, a fee, funds or a reward's gold (5.x's scripts searched: the shop, smith, transmogrification and inventory menus, `W3MerchantNPC`, `OnGiveReward`). The Doppler trophy's bonus money is TRPH's. ECON is tree-independent, and the regression ran in both.
- **Tests' expected values** were worked from legacy's data, not the port's:
  - `gmtest_econ_e1`'s 297 embedded factors equal legacy's CSV;
  - E2's and E5's data tests agree with the independent item resolution;
  - E3's money and haggling expectations follow legacy's factors and `maxMult = 1` (bar ×2, a deal at 1.2–1.7);
  - E4's reward table agrees with the independent reward parse.
- **Interactions.**
  - DIFF-07's toll (a quarter of the money) reads only Geralt's money.
  - CRAFT-05's crafting fee is the crafted item's price × legacy's `mod_craftitem`.
  - UI's tooltips and shop read the native price functions; no Ghost Mode script computes a price.
  - ITEM's durability halves only the stat share of a price (native, the same in legacy).
  - FOOD's food and drink prices are ECON-02's units (checked with them).
  - XP's quest data test was regenerated with E4's gold.
  - LOOT's merchant stock lists are untouched by ECON.

**Tool checks:** `gen_econ.py --verify` passes ("no difference"; it misses F1, which it does not test for); `gen_loot.py --verify` agrees with the independent parse.

**In game** (scripted only, through exec calls: no real input, no screen):
- The probes ran on a throwaway build: master `4cd642be` plus `tests/gmAuditEcon.ws` and a probe item file. It was deleted afterwards and the real build of `4cd642be` reinstalled.
- Every launch used the test save with saves locked (`gmtest_nosave()`).

| Check | How | Result |
|---|---|---|
| What the game does with a DLC item entry that has no `on_conflict` on a name 5.x defines (F1): `Jar of Honey` given whole at 777 with no attribute, `Rose of memories` at 778 with `replace` as a control | scripted: the definitions manager (`gmaudit_dup()`) | Jar of Honey 50 (5.x's: **the plain entry is ignored**, no error in the script log); Rose of memories 778 |
| AI-18's stone check, reproduced (F5): ten fresh deserters each, the panel check's sequence (Ifryt's burning, the burning removed, the stone), the stone alone, and the same split over two exec calls | scripted: `GMTestAi17Collide` (`gmaudit_ai18_*`) | knockdown on 7 of 10, 9 of 10, 7 of 10; the 200 damage on every one |

**Regression** (master `4cd642be`, `god()` off, `exec --wait 6000 "gmtest_regress()" "ingamemenu()" "gmtest_panel()"`; one fresh launch per tree, the new tree by the option and `gmreset()`, then set back to the classic tree): `gmtest_regress()` 1,260 passed, 0 failed, and `gmtest_panel()` 156 passed, 0 failed, in each tree. AI-18's stone check passed in both.

**Findings:**

1. **The NG+ copies of 69 of 5.x's new items keep 5.x's prices** (medium, NG+ only; clear fix).
   - **Feature:** DE2 prices 5.x's new gear, schematics and horse gear by analogy (the owner's decision), in both folders.
   - **Which entries:** `gen_econ.py` writes 69 of the NG+ entries whole in `items_plus/gm_econ.xml`, but without `on_conflict="replace"`:
     - Heavy armor 03 Netflix and Heavy gloves 04 Netflix;
     - the Dol Blathanna, White Tiger and Scarlet Crest armor;
     - the top Netflix armor tier and its NGP copies;
     - the 36 Netflix schematics;
     - the Fire Horse gear.
   - **Why:** the generator's `re.sub(r'^<item', …)` misses entries that start with a tab.
   - **What the game does:** this audit's probe shows the game ignores such an entry and keeps 5.x's definition.
   - **The other 40 NG+ DE2 entries are right:** those written by `gen_arm_new.py` and `gen_swd_items.py` have `replace`. The regular folder is right too.
   - **Play effect:** in a New Game+ playthrough, these items sell and craft at 5.x's prices, a third to a half of their peers. For example:
     - Netflix Armor 2 lists at 4,458, not 5,040;
     - the Fire Horse Saddle at 150, not 450;
     - White Tiger Armor at 457, not 714;
     - Netflix Armor schematic 2 at 538, not 1,031.
   - **Why it went unseen:**
     - `--verify` reads the DLC's entries as written, not as the game resolves them, so it passed;
     - the data test reads the regular folder only;
     - slice E5's docs say the 109 NG+ entries "read as DE2 gives them".
   - **Fix:**
     - add the attribute (the regex to allow leading whitespace) and regenerate;
     - make `gen_econ.py --verify` fail on any DLC entry without `on_conflict` on a name 5.x defines, in every `gm_*.xml` of both folders (today there are no others);
     - record the probe's rule in development.md (done with this audit).
   - **Tested:** the rule by a scripted probe in the regular folder. NG+ cannot be read in a regular game.
2. **Porter's calls of slices E1 to E5 waiting for the owner's confirmation** (owner decision; each follows legacy or has no play effect).
   - E1: legacy's table before E2's prices (an intermediate state, ended by E2); the check reads list prices and tags live; the repair fee and adding a socket are read, not checked (F4).
   - E2: NG+ entries whole (F1 is in this form's NG+ entries); the razor's price by hand in UI-15's entry; `gen_ench.py --verify` now expects legacy's table.
   - E3: a wrapper, not a replacement, for the reset below 100; the restock on talking is an exec check outside the regression.
   - E4: the loan's reward in E4 and its repayment in E5 (ended); the rewards with experience given with Geralt's level held at 100.
   - E5: the owner's two figures kept (Netflix Pants 604, Netflix Pants 2 3,272: one crown each off the ratio); the NG+ copies at the regular price; the scenes checked offline and by loading; the hand-picked counterparts (F3).
   - Recommendation: confirm all; each entry gives its alternative.
3. **DE2: the hand-picked counterparts and the schematics' ratios** (owner decision; the auditor's view, not a defect).
   - **The hand-picked sets hold together by tier and type.** Rule: the legacy relic of the same kind and slot nearest in 1.32 price.
     - Dol Blathanna and White Tiger (levels 8 and 12): chest 714, boots 288, gloves 280, trousers 343.
     - Scarlet Crest (level 41): chest 755, boots 320, gauntlets 563, trousers 232.
     - The Vixen and Dol Blathanna swords: steel 1,145, silver 1,289.
     - The slots follow legacy's own pattern (gloves and boots about ×2.5, chests about ×1.1), and the prices land among legacy's relics.
     - One weakness: the rule ignores level, so the level-41 Scarlet Crest chest (755) costs barely more than the level-8 Dol Blathanna one (714). In 5.x they were 730 and 457, so the gap was already small. Keep.
   - **Top Notch is the inconsistent pair.**
     - Top Notch Steel 1,200 (16 × Eredin Sword's ×75) against Top Notch Silver 528 (102 × Breathofthenorth's ×5.17).
     - The silver sword costs less than half the steel. Every other pair has silver at or above steel (the Vixen 1,145 / 1,289).
     - The cause: both 5.x prices are placeholders, so the ratios are the placeholders' ratios.
     - Suggested: price both at their counterparts' legacy prices directly, as the Fire Horse gear takes its counterpart's price: Steel 1,500 (Eredin Sword), Silver 1,050 (Breathofthenorth). Or keep Steel at 1,200 and set Silver to 1,050.
   - **The Netflix schematics at the Wolf schematics' ratios** (the owner's rule) give some prices out of line, because 5.x priced its Netflix schematics above Wolf's 1.32 placeholders (for example 58 and 147 against Wolf's 43 and 45):
     - Netflix Boots schematic 1 at 448 costs more than Netflix Boots schematic 2 at 394;
     - Netflix silver sword schematic 1 at 1,052 costs twice Netflix silver sword schematic 2 at 497, and about two thirds of the sword it crafts (1,650). Legacy's Wolf schematics cost about a fifth of their swords: Wolf School silver sword Upgrade schematic 3 is 322 against the sword's 1,614.
     - The gear does not have this problem: 5.x copied Wolf's 1.32 gear prices, so the ratio gives back about legacy's Wolf price.
     - Option: price each Netflix schematic at its Wolf counterpart's legacy price:
       - Armor 173 / 638 / 1,027
       - Boots 65 / 332 / 524
       - Gloves 114 / 267 / 460
       - Pants 122 / 328 / 520
       - steel sword 100 / 270 / 345
       - silver sword 114 / 322 / 505

       All rise with the tier and keep Wolf's schematic-to-gear proportion.
     - The schematic counterparts are Wolf's schematics 1, 3 and 5 (4 for the chest and swords), while the gear counterparts are tiers 2, 4 and 5 (1, 3 and 4). Aligning them would also be the owner's call.
   - **Recommendation:**
     - keep the hand-picked armor and swords;
     - give Top Notch its counterparts' legacy prices;
     - price the Netflix schematics at their Wolf counterparts' legacy prices.

     All three follow the owner's choice of Wolf's piece of the same tier more closely than the ratio does.
4. **Gaps in the checks** (low, test-only; clear fix).
   - The repair fee and adding a socket are read but not checked, and the enchanter's columns (`mod_addslot`, `mod_repair`, `mod_disassemble`, `mod_removeupgrade` at `type_enchanter`, all changed by legacy) are exercised by no check.
     - Example: removing an upgrade at the Hearts of Stone enchanter is 0.35 → 0.3 of the item's price, and adding a socket 0.3 → 0.35.
     - Fix: an enchanter (`enchanter_01_lvl_*.w2ent`) and a damaged item in `gmtest_econ_e1`.
   - Beauclair's region column (legacy changed it on crafting 1.25 → 1.15 and on other rows) is exercised by no check: E1's merchants are from Novigrad, Skellige and No Man's Land. Fix: one Toussaint merchant in the same check.
   - `gen_econ.py --verify` does not resolve `on_conflict` (F1's fix).
5. **AI-18's stone knockdown check is random per hit** (low, test-only, AI's; the auditor's bounded look, not fixed).
   - **What the check tests:** the panel's AI-18 check hits a neutral Nilfgaardian deserter with an elemental's stone through its real collision and expects a knockdown. During E4 it failed on about half the launches.
   - **Reproduced:** the stone's 200 bludgeoning damage arrived every time, but the knockdown came on only some of the deserters:
     - 9 of 10 with the stone alone;
     - 7 of 10 after Ifryt's burning on the same deserter (the panel's order);
     - 7 of 10 when the burning and the stone were a frame apart.
   - **Excluded as causes:**
     - a leftover burning (removed every time, no critical-state animation running);
     - the attitude (neutral);
     - the `ResistCriticalStates` random immunity (absent);
     - the effect's apply chance (1);
     - an NPC dodge (the damage arrived).
   - **Likely cause:** the knockdown is refused or overridden after `InternalAddEffect` at random. A critical effect landing on an actor that has just had another (the hit reaction, or the burning's critical state) is refused more often.
   - **Why it fails per launch:** the panel's single deserter fails about 1 run in 3 to 10 for that reason alone. Nothing points at ECON's checks.
   - **Fix (AI's call):**
     - hit three fresh deserters with the stone alone and require a knockdown on at least one; or
     - check what the port controls: the damage action carries `EET_Knockdown` (the class default).

     Either removes the intermittent without losing the check. To find the native cause, run the probe with the game's damage log (`LogDMHits`) enabled.
   - **Tested:** scripted; development.md's note updated with the result.
6. **Doc corrections** (doc-only; clear fix).
   - Slice E5: "109 NG+ DE2 entries read as DE2 gives them" holds for 40 (F1).
   - ECON-08's "What it does": the ceiling (2,500 / 5,000 / 7,500 / 15,000) is not multiplied by the funds factor, and a restock can overshoot it (`IncreaseFunds` only checks that the money is below the ceiling).
   - ECON-12's "What it does": the two scenes also set a 0.5 reward modifier in some branches (`SetRewardModifierScene` 0.5, three blocks). In 5.x, that half pay too landed on the White Lady's reward; with the fix, it lands on the Apiarian Phantom's. The scene branches that set it are not identified.
   - development.md: the `on_conflict` table's "(none)" row was "error on redefinition (per the changelog), unverified"; it now says what the probe showed (the DLC entry is ignored; done with this audit).
7. **Noted, no action** (vanilla, not legacy's).
   - The free DLC quest `mq2052`'s giver scene (`mq2052_02_quest_giver.w2scene`) negotiates over `mh102_final_reward` (300 crowns) with `alwaysSuccessful`, while its own rewards pay no gold. This is in 1.32 and 5.x, and legacy left it.
   - With ECON-09 the popup there goes up to 600. Any deal stores a multiplier on mh102's reward, which reaches the mh102 contract's pay only if that contract has not paid out (inferred from the scripts; not tested).
   - Recommendation: list it for Later with legacy's Blood and Wine known issues.
8. **Not verified in game** (no action; open checks kept in the entries).
   - **Seen on screen in the [cleared run](#cleared-run-on-screen-2026-11-01)** (2026-11-01, real input): a real purchase, sale, "Sell Junk", crafting fee, repair and socket fees in the menus; a Netflix piece's and the Fire Horse saddle's sale prices, the saddle sold.
   - **Needs a save at that point in the story** (not reachable from the test save without time skips or story progress):
     - a met merchant restocking after 3 real game days;
     - a real contract negotiation, and the Apiarian Phantom's in its scenes;
     - Vivaldi's repay choice showing 390;
     - the tax collector arriving at 10,000 crowns;
     - a reward paid by a real quest;
     - a Netflix piece bought from a merchant who stocks it.
   - **Not run:**
     - the bonus columns (`area_*_bonus`, `quest_bonus`, `bonus_mq7018_*`), seen applied at no merchant;
     - Blood and Wine's merchants of legacy's known issues;
     - the enchanter's and Beauclair's columns (F4);
     - an item at 0 durability at a merchant (native, legacy's alike).
   - **NG+:** every ECON price and tag in `items_plus` (`--verify` and this audit's data scripts only), and DE2's NG+ prices (F1).

**Autosave:** none written. The live save folder holds the 1,079 saves it held at the start, the same as the backup; none is missing and none is new. The test save `<save name>` and the test-only slot were not saved over. The user settings were restored with the game closed: no scaling or experience group; the classic tree, sign cooldown 5, armour regen penalty off, combat stamina regen 5, difficulty 3.

**Not reviewed:** legacy's own behaviour in play; NG+ in game; the scene branches that set the `mh307` 0.5 modifiers.

**Suggested fix slices:**
- **C** (code and tests): F1, F4; F3 once decided.
- **W** (docs): F6's corrections to econ.md.
- **O** (owner): F2's confirmations, F3's choice; F5 goes to AI.

#### ECON audit close-out

**ECON signed off by the owner (2026-11-02).** The open checks that need a save further into the story wait until after the first playable version, when the owner runs them in a playthrough.

**Closed 2026-11-01.** Clear fixes (master `7109c6e5`): F1, F4 and F5 fixed and verified, F6's corrections and F7's Later entry made. **The owner's decisions (2026-11-01), all as the audit recommended:** F2, every porter's call confirmed; F3, Top Notch and the Netflix schematics at their counterparts' legacy prices, the hand-picked armor and swords kept (master `a255d35d`). Every finding is fixed, decided or recorded: ECON is ready for the owner's sign-off.

| Finding | Outcome | How tested |
|---|---|---|
| F1 NG+ copies of 69 new items at 5.x's prices | **fixed**: `gen_econ.py` writes `on_conflict="replace"` on 5.x's entries that start with whitespace too (`replace_entry`), and the 69 NG+ entries of `items_plus/gm_econ.xml` were regenerated with it; in a New Game+ playthrough the Netflix, Dol Blathanna, White Tiger, Scarlet Crest and Fire Horse gear and the Netflix schematics now take DE2's prices (Netflix Armor 2 5,040, not 4,458; the Fire Horse Saddle 450, not 150). **The guard:** `tools/dlc_conflicts.py` lists every DLC entry (`<item>`, `<ability>`, `<item_extension>`, every definition file of the four folders, whichever tool wrote it) without `on_conflict` on a name 5.x defines; `gen_econ.py --verify` fails on any. Not a deviation | offline: the guard on the old output listed exactly the 69 (all in `items_plus/gm_econ.xml`, nothing in any other tool's files) and `gen_econ.py --verify` failed ("69 DLC entries without it"); after the fix 0 and "no difference". In game: the audit's probe (a plain entry is ignored) stands, not repeated; NG+ definitions cannot be read in a regular game |
| F2 Porter's calls of E1 to E5 | **confirmed** by the owner (2026-11-01), each as made: E1's (legacy's table before E2's prices, the check reading list prices and tags live, the form of E2's entries); E2's NG+ entries written whole and the razor's price by hand; E3's wrapper for the reset below 100 and the restock-on-talk check outside the regression; E4's loan reward shipped before its repayment (complete since E5) and the rewards with experience given with Geralt's level held at 100; E5's owner figures 604 and 3,272 kept, the NG+ copies at the regular price, the scenes checked offline and by loading, and the hand-picked counterparts of the armor and of the Vixen and Dol Blathanna swords; the close-out's calls (below). The slices' lists say so | — |
| F3 DE2's counterparts and schematic ratios | **decided** by the owner (2026-11-01) and **fixed** (master `a255d35d`): Top Notch Steel 1,500 (Eredin Sword's legacy price; was 1,200) and Top Notch Silver 1,050 (Breathofthenorth's; was 528); each Netflix schematic at its Wolf counterpart's legacy price, read from `legacy-GM` (the same in both folders): armor 173 / 638 / 1,027, boots 65 / 332 / 524, gloves 114 / 267 / 460, trousers 122 / 328 / 520, steel sword 100 / 270 / 345, silver sword 114 / 322 / 505 (5.x's `NGP` copies alike; [the table](#de2-the-counterparts)). The hand-picked armor, the Vixen and Dol Blathanna swords and the Netflix gear unchanged. `item_layer.DE2`'s rule `copy` for these 38 regular items (`gen_econ.py --verify` recomputes each from legacy); both folders regenerated (`gm_econ.xml`, SWD-10's `gm_swd_items.xml`; NG+ entries `replace`, `dlc_conflicts.py` 0). Not a deviation: DE2 prices content legacy never had | scripted, both trees: the data test 4,740 of 4,740; E5's merchant check 7 of 7 (Netflix Armor schematic 2: definition and list 1,027, the Novigrad armorer asks 1,187, pays 296). On a throwaway build with the previous data and the new tests (deleted afterwards, the real build reinstalled) the data test failed exactly the 38 changed items (the 18 Netflix schematics, their 18 `NGP` copies, both Top Notch swords) and the merchant check 1 of 7 (1,031) |
| F4 Gaps in the checks | **fixed**: `gmtest_econ_e1` checks the repair fee and the socket fee at every craftsman by their measured formulas ([ECON-07](#econ-07-craftsmens-fees)) and two more merchants: the Hearts of Stone enchanter (`type_enchanter`, `area_novigrad`) and a blacksmith given Beauclair's columns (`area_beauclair`; no spawnable Blood and Wine merchant carries columns); the embedded factor table has both columns, legacy's; Bear Armor 4 joined the items (at a dear item the enchanter's repair factor shows). 120 checks (80 before). Not a deviation | scripted, both trees: 120 of 120. On a throwaway build with 5.x's price table (deleted afterwards, the real build reinstalled) 11 of 120: every new check failed, also where the list price is the same in both tables (a Long Steel Sword): at the enchanter removing an upgrade 24 (legacy 21), dismantling 18 (14), a socket 314 (315); a socket at the Novigrad weaponsmith 362 (355, the Novigrad surcharge); crafting at Beauclair 28 (33); the repair per point of a Bear Armor 4 at the enchanter 20 (18) and at Beauclair 20 (19) |
| F5 AI-18's stone check random per hit | **fixed** (AI's check, [AI-18](ai.md#ai-18-special-attacks-and-monster-projectiles)): the stone alone on three fresh deserters; every hit must deal its 200 and its damage action carry `EET_Knockdown`; how many were knocked down is logged | the regression on six fresh launches (one classic, then two new-tree ones, then the same three again on the final build): passed every time, knockdowns landing on 2, 3, 1, 2, 3 and 2 of 3 |
| F6 Doc corrections | **corrected**: slice E5's NG+ claim; ECON-08's ceiling (not times the funds factor, a restock can overshoot it); ECON-12's 0.5 modifier branches; development.md's `on_conflict` row (with the audit) | read |
| F7 `mq2052`'s haggling | **listed** under [Later](#port-order) | — |
| F8 Not verified in game | **kept** as the entries' open checks | — |

Porter's calls of the close-out (none is a deviation; all confirmed by the owner, 2026-11-01, with F2):
- **Beauclair on a stand-in merchant** (F4): no spawnable Blood and Wine merchant carries price columns, so a blacksmith given Beauclair's columns stands in.
- **The stone check on the hit** (F5): AI-18's check requires the stone's 200 damage and `EET_Knockdown` on its damage action on each of three deserters and logs the knockdowns, instead of requiring a knockdown.
- **The socket constant 293** (F4): the measured socket fee's fixed part, the same for every item and merchant with either table, checked as measured.
- **The guard's scope** (F1): `dlc_conflicts.py` covers `<item>`, `<ability>` and `<item_extension>` entries of every definition file in the four folders, whichever tool wrote them.

**Regression after F3** (master `a255d35d`, `god()` off, the same command, a fresh launch per tree, the new tree by the option and `gmreset()`, then set back to the classic tree): `gmtest_regress()` 1,300 passed, 0 failed, and `gmtest_panel()` 156 passed, 0 failed, in each tree (the same counts: F3 changes values, not checks). Saves: none written; the live folder holds the backup's 1,079, none missing, none new; the user settings restored with the game closed.

**Regression of the clear fixes** (master `7109c6e5`, `god()` off, `exec --wait 6000 "gmtest_regress()" "ingamemenu()" "gmtest_panel()"`, a fresh launch each): `gmtest_regress()` 1,300 passed, 0 failed, and `gmtest_panel()` 156 passed, 0 failed, in the classic tree and on two launches in the new tree (by the option and `gmreset()`, then set back to the classic tree). E5's 1,260 + 40: `gmtest_econ_e1` 120 checks, not 80 (two merchants with a columns check, a funds check and ten items each, and a columns check and Bear Armor 4 at the eight others). The panel stays 156: the stone check is still one report.

**Saves:** none written; the live folder holds the 1,079 saves of the backup, none missing, none new; the test save not saved over. The user settings were restored with the game closed (no scaling or experience group; the classic tree, sign cooldown 5, armour regen penalty off, combat stamina regen 5, difficulty 3).

**Deviations:** none new.

---

### Dependencies on other areas

- **Done areas ECON builds on:** the item layer (`item_layer.py`) and the item generators of ARM, SWD, ITEM, XBOW, CRAFT, FOOD, ALCH, AI and ENCH (the entries carrying the prices); LOOT-07 and XP-02 (`gen_loot.py`'s reward overrides); ENCH-02 (the price table's file copy, the enchanter's rows and scenes); CRAFT-05 (the fee code); DIFF-07 (the guards' toll).
- **Areas ECON shares with or waits for:** WGT (weights in the same entries), TRPH (the trophy items: price ECON's, bonuses TRPH's).

### Hand-offs received

| From | Item | ECON |
|---|---|---|
| CRAFT (hand-off) | Item, schematic-item and recipe-item prices; `mod_*` tags on ingredients and junk; `mod_craftitem`, `mod_disassemble`, `mod_removeupgrade`; dye quality (BaW's dyes lose their rarity); the junk items' `mod_valuable` | ECON-01 to ECON-04, ECON-07; the dyes' `Relic _Stats` with ECON-02 |
| LOOT (hand-off) | The rewards' gold (188) and 5.x's own raises; merchants' funds; price factors; contract haggling; the Hearts of Stone tax quest; "another quest money condition" | ECON-10 (187), ECON-11 (the loan, the tax quest: its starting threshold, not a sum), DE1, ECON-08, ECON-05 to ECON-07, ECON-09; the other condition is `mq6005_enchanter.w2phase`'s 3,000 crowns, ENCH-02's (ported) |
| FOOD (hand-off, audit F10) | Food, drink and cooking recipe prices; the `mod_food` rows; Wolf liver, the Free nilfgaardian lemon and Local pepper vodka's price tags | ECON-02, ECON-03 (the cooking recipes' prices are legacy's already, FOOD-07), ECON-05, ECON-04. The Shani alcohols and flowers FOOD listed change only weight (WGT) |
| XP (hand-off) | 31 gold-only rewards and every reward's gold; the Vivaldi payment; the Hearts of Stone taxes; the `mh307` reward name | ECON-10, ECON-11, ECON-12 |
| DIFF (DIFF-07) | Money is scarcer under ECON; the toll is DIFF's | — (DIFF-07 ported) |
| ENCH (hand-off, audit F6) | Prices of every rune and glyph item; the table's other rows | ECON-02 (`upgrade` items, 59 regular), ECON-05 to ECON-08 |
| SWD, ARM (hand-offs) | Prices of every sword and armor item, `mod_legendary`/`mod_valuable` | ECON-01, ECON-04 |
| XBOW (hand-off, PB3) | Bolt, crossbow and schematic prices; `mod_legendary` off two bolts and onto the Ofir Crossbow R | ECON-01, ECON-03, ECON-04 |
| AI (hand-off) | Weapon prices in the item entries | ECON-01 (the NPC and secondary weapons with a price change, e.g. Blood and Wine's `def_item_weapons_secondary.xml`) |
| ITEM (hand-off) | Item and kit prices, `mod_repair`, `daysToIncreaseFunds`, funds reset below 100, restock funds | ECON-02, ECON-07, ECON-08 |
| UI (hand-off) | `OpenMonsterHuntNegotiationPopup`; the razor's price (5 → 6) | ECON-09, ECON-02 |
| ALCH (hand-off) | Prices of alchemy items and recipes, `mod_alchemy`, `mod_alcohol` | ECON-02, ECON-03, ECON-05; legacy changed no potion, oil, bomb or decoction price |

**Temporary deviations "until ECON"** ([deviations.md](deviations.md)): none recorded. The 5.x-kept prices and tags other areas noted (XBOW's PB3, CRAFT-07's and FOOD's tags) ended with slice E2; LOOT-07's and XP-02's 5.x gold ended with slice E4. Not deviations.

### Hand-off to other areas

| Area | Changes |
|---|---|
| CRAFT | **A gap found here:** legacy adds `mod_alchemy_table` to Blood and Wine's Protofleder Mutagen (regular and NG+), the tag the dismantling station reads (`W3StandaloneDismantleComponent.ShouldShowItem`), so it can be dismantled like the other named mutagens (CRAFT-08); the port's entry lacks it (`item_layer.py`'s CRAFT tags skip every `mod_*` tag). CRAFT-08 owns the tag (PE13): **done** in slice E2 (2026-11-01, `item_layer.TAGS`, verified by script) |
| WGT | The weights in ECON's entries: the 40 Blood and Wine paintings and other junk (`def_item_junk.xml`, price and weight together, attributed to ECON with a WGT note), and every weight-only unit left unattributed (about 580) |
| TRPH | The trophies' abilities (93 units, unattributed); ECON-02 takes the 56 trophy items' prices |
| (ARM or MISC) | `Body palms cut` in Hearts of Stone's NG+ `def_item_misc.xml`, an item legacy defined where NG+ armor named it (unattributed) |

### Save impact

None expected: list prices and tags are read from the definitions, the price table and rewards when used, the haggling at each negotiation; a merchant's money is in the save and meets the new funds rules at his next spawn or restock; the tax quest's threshold is read while its phase waits (a save already past it keeps its state). The mod is installed at the start of a playthrough ([save compatibility](../feature-mapping.md#save-compatibility)).

### Area decisions

**Area decisions** (all decided by the project owner, 2026-11-01, each the recommendation):

| # | Question | Options | Recommendation | Decision |
|---|---|---|---|---|
| DE1 | 5.x's own raises of reward gold (ECON-10). Legacy kept 1.32's gold on three rewards that 5.x raised, and set a fourth lower than 5.x: Emhyr's payment for finding Ciri (`q110_1b_accepted_emhyrs_reward`) legacy 2,000, 5.x 4,000; Hearts of Stone's finale purse (`q605_mirror_finale_cash`) 5,000 against 10,000; the baron's payment (`q107_4_reward_baron`) 100 against 150; `q103_06_find_daughter` legacy 100 (1.32 50), 5.x 200. On three more 5.x made legacy's own raise (the prologue griffin 250, Rosa's payment 100, `mq0001_01_reunite_brothers` 25): no question there | (a) legacy's gold on all four (2,000, 5,000, 100, 100); (b) 5.x's raise where legacy kept 1.32's (4,000, 10,000, 150) and legacy's 100 where it changed the reward itself; (c) the larger of the two everywhere (4,000, 10,000, 150, 200) | **(a)**: legacy behaviour first and money scarce (P6); 5.x's raises are a vanilla rebalance legacy never saw, and Emhyr's 4,000 alone would match about fifteen of legacy's contracts (250–300 crowns each). Not a deviation | **(a)** (project owner, 2026-11-01): legacy's gold on all four: Emhyr's payment 2,000, the Hearts of Stone finale purse 5,000, the baron's payment 100, `q103_06_find_daughter` 100. Not a deviation: legacy's amounts |
| DE2 | The prices of 5.x's new items (ECON-01, ECON-03). 5.x added 175 regular items (203 NG+) priced at 1.32's scale, among legacy's re-priced ones: e.g. "Heavy armor 03 Netflix" 824 (a copy of Heavy armor 03, which legacy prices 856), Netflix Armor 2 4,458 (a tier like the Bear Armor 4 legacy raised 4,546 → 6,182), White Tiger Armor 457, Dol Blathanna longsword 689, the 36 Netflix schematics 29–2,563 (their NG+ tiers included), the Fire Horse saddle 150 (legacy's saddles 450), three Gwent cards 10–50 | (a) 5.x's prices as they are; (b) by analogy: each new piece of gear, schematic and horse gear at the ratio legacy applied to the 1.32 item it copies or matches (its class and tier: Heavy armor 03 Netflix 856, Netflix Armor 2 about 6,060, White Tiger Armor like a relic armor ×1.74, about 795, the Fire Horse saddle 450), the slice listing each item's counterpart; quest items, potions and Gwent cards 5.x's; (c) a flat ratio per category (legacy's median for that category) | **(b)**: otherwise the new gear sells and crafts at a third or half of its legacy peers (the Netflix steel sword schematic 2 costs 253, where Blood and Wine's Bear School silver sword Upgrade schematic 4, 214 in 1.32, costs legacy's 544), the same reasoning as XP's DX4 (5.x's new content placed by analogy); Gwent cards and quest items have no re-priced peers. Not a deviation: content legacy never had | **(b)** (project owner, 2026-11-01): 5.x's new gear, schematics and horse gear by analogy, at the ratio legacy applied to the item each copies or matches (Heavy armor 03 Netflix 856, Netflix Armor 2 about 6,060, the Fire Horse saddle 450); Gwent cards, potions and quest items keep 5.x's prices. Not a deviation: content legacy never had. **Counterparts** (owner, 2026-11-01): the Netflix set is priced like the Wolf School piece of the same tier, not like Bear (Netflix Armor 842 / 3,240 / about 5,040; Boots 634 / 1,660 / 2,620; Gloves 570 / 1,410 / 2,298; Pants 604 / 1,665 / 3,272), its schematics at the Wolf schematics' ratios; the other new sets (Dol Blathanna, White Tiger, Vixen, Scarlet Crest, Top Notch) get counterparts picked by hand in slice E5, listed for the owner to check. Ported in slice E5 |

### Porter's calls

Each follows legacy or has no play effect; all confirmed by the project owner (2026-11-01).

| # | Call |
|---|---|
| PE1 | ECON is ported as one area with one audit at the end, about 3,900 units, in the slices of the [port order](#port-order) |
| PE2 | Item prices and tags go through `item_layer.py`: ECON owns the `price` attribute and the `mod_*` tags (but XBOW-03's and CRAFT-08's) of its units, applied by whichever generator writes the entry; the 1,053 entries no generator writes yet are written by `gen_item.py` as 5.x's entry whole with legacy's price and tags (about 1,050 more entries in the DLC, regular and NG+), unless slice E1 shows that an `extend` entry with only a `price` attribute sets it, which would keep the DLC smaller. **Slice E1's answer** (verified 2026-11-01, [development.md](../development.md#fine-grained-xml-overrides-50)): it does for the base game's, Blood and Wine's and the free DLCs' items (everything else kept), a `<tags>` node in it adds its tags and removes those written `-mod_…`, and it empties Hearts of Stone's items. So the 1,053 can be 986 small `extend` entries (price and changed tags; 547 regular, 439 NG+) and 67 Hearts of Stone entries whole with `replace` (36, 31); NG+ `extend` is untried, probed first in E2 (the form is E2's porter's call, see slice E1's calls). Checked by `econ_prices.py`'s successor with `--verify` against legacy, item by item. **Port form** ([the owner's decision](#the-form-of-the-item-entries-the-owners-decision-2026-11-01), 2026-11-01; slice E2): `extend` entries for the base game's, Blood and Wine's and the free DLCs' items (531), Hearts of Stone's (36) and the dyes (14) whole, NG+ whole (467: NG+ `extend` could not be probed), and ECON's fields inside the 2,663 entries other areas write whole; `tools/gen_econ.py` with `--verify` |
| PE3 | NG+: legacy's NG+ entries' prices and tags (they equal its regular ones but for six Red Wolf tier-1 pieces, legacy's own NG+ values); untested, as every NG+ change |
| PE4 | The three misspelt 1.32 tags (`mod_weapo`, `mod_legendar`, `mod_valuable EP1`) are fixed as legacy fixed them (part of its tags; where `mod_valuable EP1` becomes `mod_legendary, EP1` on NG+'s Crafted Burning Rose Sword, the `EP1` level tag is ITEM-03's, carried with the same entry) |
| PE5 | `economy_tagmodifiers.csv`: legacy's other 29 changed rows in the whole-file copy ENCH-02 ships (its two rows already legacy's): the file becomes legacy's exactly |
| PE6 | ECON-08: the restock interval 3 and the reset below 100 in a small script (`econ/merchants.ws`): a scope-based default for `daysToIncreaseFunds` if the import class takes one, else a wrapper of `GetDaysToIncreaseFunds`; a `@wrapMethod(W3MerchantNPC) OnSpawned` that sets funds up after 5.x's body when the merchant has less than 100 (5.x's body already sets them up at 0, so the result equals legacy's) |
| PE7 | ECON-09: `@replaceMethod OpenMonsterHuntNegotiationPopup` with 5.x's body and legacy's `maxMult = 1` (always-successful negotiations accept up to double, as legacy) |
| PE8 | ECON-10: legacy's gold for its 187 rewards through `gen_loot.py`'s merge (the `gold` attribute for ECON-10 units), with DE1's choice for the four overlaps |
| PE9 | 5.x's new rewards keep 5.x's gold (Killbill's new branch `sq106_3_hammond_killed_crach` 200, the `mq1060` priest 200, `q504_horse_returned` 15): content legacy never had, sums already in legacy's range for such quests |
| PE10 | ECON-11 and ECON-12 as binary edits of 5.x's files with `cr2w_patch.py` (legacy's amounts and reward name), shipped in the bundle as ENCH-02's scenes; `cr2w_patch.py` gains the edit of a scene script call's name parameter (the raw part after the properties) for ECON-12 |
| PE11 | The trophy items' prices go with ECON (ECON-02), before TRPH; TRPH later ports the bonuses on the same entries |
| PE12 | 5.x's transmogrification fee and "Sell Junk" button stay 5.x's (services legacy never had; the fee does not read item prices; "Sell Junk" pays the legacy sale price) |
| PE13 | The CRAFT gap (Protofleder Mutagen's `mod_alchemy_table`) is fixed under CRAFT-08 in slice E2, through the same item entry (a one-line `item_layer.py` ownership) |

### Port order

Each slice compiles and is verified on its own (the regression in both trees; skills are not involved, so the per-tree checks are the regression's). One audit after the last (PE1).

| # | Slice | Verified by |
|---|---|---|
| E1 | **Done** (master `6931c39a`, 2026-11-01): the formula measured, `extend` probed, legacy's table (verification under [ECON-05](#econ-05-merchants-buy-factors)). **Probe and price table.** First a measurement on the current port (5.x's prices): buy, sale, crafting, repair and dismantling prices of a few reference items (Long Steel Sword, Bear Armor 1, Drowner brain, Ruby, a Tracking bolt) at spawned merchants of four types in two regions, read through the shop's own functions (`GetInventoryItemPriceModified`, `GetItemPriceCrafting`, `GetItemPriceRepair`, ...), to learn how the native code combines the factors; a probe of `<item … price=… on_conflict="extend"/>`. Then ECON-05 to ECON-07 and ECON-08's row: legacy's `economy_tagmodifiers.csv` | The same reads again: each changed factor moves the prices by its ratio (e.g. a merchant's buy price of a legendary armor ÷ 4.4 × 1.2); the probe's answers recorded in development.md |
| E2 | **Done** (master `26e66189`, 2026-11-01; [verification](#slice-e2-item-prices-and-tags-2026-11-01)); DE2 moved to E5. **Item prices and tags** (ECON-01 to ECON-04): `item_layer.py` (`price`, `mod_*`), `gen_item.py` for the entries no generator writes, `gen_ngplus.py`; a data test of every regular item's list price and tags (`GetItemPrice` and the tags through the definitions manager) against legacy's; with PE13 | The data test (about 2,000 items); a few items bought and sold through the shop menu's events at a spawned merchant |
| E3 | **Done** (master `b6c61d57`, 2026-11-01; verification under [ECON-08](#econ-08-merchants-money) and [ECON-09](#econ-09-contract-haggling)). **Merchants and haggling** (ECON-08, ECON-09): `econ/merchants.ws`, the haggling method | A spawned merchant with 60 crowns set up again at spawn; a restock after 3 game days and none after 2; the negotiation popup opened by script on a contract reward, its bar maximum (double) and accept limit (1.2 to 1.7) read over many openings |
| E4 | **Done** (master `d44d60c1`, 2026-11-01; verification under [ECON-10](#econ-10-quest-reward-gold)). **Reward gold** (ECON-10, the loan's reward): `gen_loot.py` with ECON-10, DE1 | A data test of every reward's gold; rewards given through `GiveReward` (a contract, a race, the Vivaldi loan) and the money gained compared; a haggled multiplier applied |
| E5 | **Done** (master `4cd642be`, 2026-11-01; [verification](#slice-e5-scenes-and-5xs-new-items-2026-11-01)). **Scenes and the 5.x items** (ECON-11, ECON-12, DE2): the binary edits (with the `cr2w_patch.py` extension); 5.x's new items by DE2, with the Netflix set at Wolf's prices (the owner's decision, 2026-11-01, [DE2](#area-decisions)) and the other new sets' counterparts picked by hand and listed for the owner to check, as `item_layer.py` fields so the tools that write those entries whole (`gen_swd_items.py`'s SWD-10 swords, `gen_arm_new.py`) carry them | `cr2w_dump.py` of the shipped files; the new items' prices in the data test; their sale prices on screen in the cleared run (2026-11-01); the scenes in play need saves at those points |

**Generator work:** `tools/gen_econ.py` and `item_layer.py`'s ECON ownership (done, slice E2); `gen_loot.py`'s `gold` for ECON-10 (done, slice E4); `item_layer.DE2`, `gen_econ.py`'s `BINARIES` and `cr2w_patch.py`'s `@` parameter edit (done, slice E5).

**Later:**
- whether 5.x applies the Blood and Wine price factors legacy's known issues say vanilla misses (some Toussaint merchants, the `mq7018` bonus columns);
- the free DLC quest `mq2052`'s haggling (vanilla, in 1.32 and 5.x; legacy left it; ECON audit F7): its giver scene (`mq2052_02_quest_giver.w2scene`) negotiates over `mh102_final_reward` (300 crowns, up to 600 with ECON-09) with `alwaysSuccessful`, while its own rewards pay no gold; a deal stores a multiplier on mh102's reward, which reaches the mh102 contract's pay only if that contract has not paid out (inferred from the scripts; not tested).
