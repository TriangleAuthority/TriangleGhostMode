# WGT: item weights and encumbrance

What Geralt's items weigh and what carrying too much does: the weight of every item (gear, alchemy items and ingredients, food, junk, keys, books, trophies, horse gear), which items count towards the load and how much, how much a saddlebag adds to what Geralt can carry, and the consequences of being overburdened (the stamina cost of actions, fast travel, the horse's gallop, a boat sinking under him), with the one option that lightens every item. Ghost Mode's changelist has its own section, "Weight" (lines 921–935), the encumbrance lines of "Mod options" (lines 1226–1232; the menu entries are [OPT](opt.md)'s), the Wight trophy's carry bonus (line 906, TRPH's) and Strong Back (line 458, SKL's, ported); the mod description explains the intent in section 4, "Economy, looting and crafting", and in its list of combat changes.

**The player-visible texts first.** Legacy's changelist, quoted exactly: "All items have weight."; "Swords and armors (especially heavy armors) have the biggest weight, so you won't be able to carry much of these. Some weights might seem unrealistic and I'd rather implement inventory space restriction myself, but right now weight looks like the only way to somehow balance the economy."; "In general, alchemy items and ingredients have small weight, but some of the ingredients, like monster hides, weight more."; "You won't need to carry as much items as in vanilla because of changes to crafting and loot."; "Fast-travel and galloping while over-encumbered were disabled."; "Over encumbrance adds penalties to stamina cost for all actions."; "If your over encumbrance is too big (20% over the limit), the boat you're trying to board will sink (off by default, can be tweaked in options)."; the options "Sink the boat if overencumbered: enables boat sinking if Geralt is overencumbered.", "Overencumbrance threshold to sink the boat (%): defines overencumbrance threshold in percents relative to max carry weight at which boat sinking happens.", "Reduce item encumbrance (%): reduces item weight for all the items in percents.", and the preset line "Gameplay presets: recommended - enables boat sinking if overencumbered and cooldown for signs and special sword attacks". The mod description adds "Ingredients having zero weight take it even further as you can loot virtually everything, so you never run out of crafting components or money.", "all items have weight, so you can't carry hundreds of swords and armor anymore;", "weight limitation won't create issues with alchemy and crafting;", "you are no longer able to gallop and fast-travel while overencumbered;" and "being over encumbered adds severe penalties to sprinting, rolling and dodging actions, depending on how big your over encumbrance is;". Legacy's own strings (`localization/modGhostMode/<lang>.csv`): the boat's message "Your over encumbrance is too high" (2110992179, `gm_geralt_too_heavy`, WGT-10) and the three option labels "Sink the boat if over encumbered" (2110992180), "Over encumbrance threshold to sink the boat (%)" (2110992181) and "Reduce item encumbrance (%)" (2110992183) (OPT's). The game's texts involved (decoded from 1.32's and 5.x's `en.w3strings` with `w3strings.py`; legacy changed none): the status "Overburdened" (1065948) and "You are overburdened." (1066169); the tutorial "Overburdened" (1087318), whose text 5.x rewrote: 1.32 "You are overburdened – Geralt is carrying too many items! If you load yourself down with too much loot, you won't be able to run or sprint. …", 5.x "You're overburdened – Geralt is carrying too much. When overburdened, a … symbol will appear, and Geralt will lose his ability to run or sprint. Check your carry weight in the Inventory panel. Drop, sell, or dismantle items to reduce weight, or upgrade your horse's saddlebags to carry more." (1087319, markup left out); the saddlebags' "Saddlebags allow you to carry more weight." (1082351) and "Saddlebags increase the number of items you can carry without being overburdened." (1085649); Strong Back's "Increases the amount of weight the witcher can carry without being overburdened." (1063959); and 5.x's new accessibility option "Ignore Item Weight" (1446543, `WeightlessItems`), part of the preset "Bard's Ballad: Focus & Rest" (1446541). Neither the tutorial nor any game text mentions legacy's fast-travel, gallop, stamina or boat rules.

**What 5.x did in this area** (from `vanilla-5.x`). **No weight legacy changed**: all 3,287 item and ability entries whose weight legacy changed (1,568 regular, 1,719 NG+) have 1.32's weight in 5.x; Geralt's base carry capacity (`encumbrance` 60 in `geralt_stats.xml`) and every saddlebag's capacity are 1.32's; the encumbrance code (`W3PlayerWitcher.GetEncumbrance`, `GetMaxRunEncumbrance`, `UpdateEncumbrance`; `CInventoryComponent.GetItemEncumbrance`; `W3Effect_OverEncumbered`; `W3Boat.OnAreaEnter`; `CR4PlayerStateUnconscious.OnLeaveState`) is 1.32's, but for what follows. **New in 5.x:** the accessibility option **"Ignore Item Weight"** (`Accessibility`/`WeightlessItems`, a visible toggle, off unless the player or the "Bard's Ballad" preset turns it on): `IsItemEncumbranceItem` and `GetEncumbrance` return nothing while it is on, the loot window shows no weight, and changing it updates the encumbrance at once (`CR4IngameMenu`); the accessibility option "Unlimited Boat Durability" (`DisableDurabilityBoat`, also in "Bard's Ballad") keeps every boat from being destroyed (WGT-10); the item tooltip hides its weight line when the weight is 0 (`W3TooltipComponent.AddItemStats`); the horse cannot canter or gallop while pulling a cart (`CanCanter`'s new `isCart` test); the new tree's Strong Back (`perk_35`, +20 per rank, 3 ranks) refreshes the encumbrance when equipped or ranked (`RefreshEncumbrance`; SKL gives both trees legacy's +40, ported); **175 new regular items** (203 NG+) with 1.32-scale weights: the Netflix set (armor 7.32 to 11.56, swords 4.3 to 4.81), Dol Blathanna, White Tiger, Scarlet Crest (its four pieces 8.2 in all), the Vixen and Top Notch swords, two Netflix copies of 1.32 gear, the Fire Horse saddle, bags and blinders (6.01, 1.56 + 1, 0.2), two potions, quest items and cosmetics (DW2).

**How legacy Ghost Mode implements it.** Scripts: `CInventoryComponent.GetItemEncumbrance` rewritten (every counted item weighs its full weight × quantity, at least 0.01 per item, × the option's reduction; vanilla counts gear at half its weight, junk, upgrades and usable items at a fifth, quest items and keys at 0.01, and alchemy items, ingredients, food and books at nothing), `W3GameParams.GetEncumbranceMult`, `GetBoatSinkOption`, `GetBoatSinkOverEncumbranceOption` (option readers), `W3PlayerAbilityManager.CalcStaminaOverEncumbrancePenalty` and its term in `GetStaminaActionCost`, `W3Effect_OverEncumbered.OnEffectAdded`/`OnEffectRemoved` (fast travel blocked), `W3HorseComponentStateExploration.CanCanter` (no canter or gallop while sprinting is blocked), `W3Boat.OnAreaEnter` and the new `CheckPlayerEncumbrance` (the boat sinks), `CR4PlayerStateUnconscious.OnLeaveState` (the encumbrance updated after a knockout), the debug command `togglezeroenc`, and the unused helper `CInventoryComponent.GetTotalArmorWeight`. Data: the `weight` attribute of 1,618 item entries (809 regular, 809 NG+, besides the items legacy added) and the `<weight>` node of 1,669 abilities (759 regular, 910 NG+), in 84 item files of the base game, both expansions and seven free DLCs and their 84 NG+ twins; the `encumbrance` of eight saddlebag abilities; the `EncumbranceOff` tag on the two foreign coins and off a Hearts of Stone trophy; the panic resistance of two blinders and the sprint cost of the base horse (horse gear, undocumented). Menu: three entries of the gameplay group (`GMSinkBoat`, `GMSinkBoatOverEnc`, `GMEncumbranceMultiplier`) with their defaults in `gmLoadDefaultSettings` and the presets (OPT's). No binary file.

Unit lists: [attribution.csv](attribution.csv). **3,339 units carry a WGT feature** (14 script units, 1,583 XML units, 1,733 NG+ XML units, 9 CSV rows: the boat message in nine languages); 2,771 of them are shared with the features whose item and ability entries carry the weights (ARM, SWD, ITEM, CRAFT, FOOD, ALCH, XBOW, AI, ENCH, UI, ECON) and `GetStaminaActionCost`. No unattributed unit carries a weight, capacity or encumbrance change. The weights of the 193 items legacy added came with their features.

**Status:** signed off by the owner (2026-11-02), WGT-01 to WGT-11 ported and verified by script in both trees, WGT-12 not ported (PW8); the [area decisions](#area-decisions) and the [porter's calls](#porters-calls) decided by the owner (2026-11-02). Open checks in play: a real overburdened ride (WGT-09), a real boat sinking (WGT-10), a real pick-up and the inventory's weight display (WGT-01), the map refusing fast travel (WGT-08), a real dodge and sprint overburdened (WGT-07). NG+ is checked offline only (the policy: not tested).

## Scope

**WGT covers** the weight of every item and how it counts, the carry capacity saddlebags add, the consequences of overencumbrance (stamina costs, fast travel, the horse's gait, boats), the weight-reduction option's effect, and the horse gear's other two stats legacy changed (PW9).

**Unchanged by legacy, and by 5.x** (from the data and code): Geralt's base carry capacity (60), the overencumbrance threshold (overburdened at the capacity + 1: `UpdateEncumbrance`), what "overburdened" itself does (no running or sprinting on foot: `W3Effect_OverEncumbered` blocks `EIAB_RunAndSprint`), the capacity counting the saddlebags of the horse wherever the horse is (`GetMaxRunEncumbrance`), equipped items counting towards the load, recipes, schematics and bodies never counting (`IsItemEncumbranceItem`), items tagged `EncumbranceForceYes`/`EncumbranceOff`, the inventory's weight display and the loot window's weight column (which, in both games and in legacy, shows 0 for quest items, ingredients and alchemy items whatever they weigh).

**Ported by other areas:**

| Subject | Ported by | What |
|---|---|---|
| Strong Back: +40 carry capacity in both trees (legacy 60 → 40; 5.x's new tree 20 per rank) | SKL-18 (`perk_22`, `perk_35`) | `gm_skill_trees.xml`, `gm_skills.xml` |
| The Thief armor's carry bonus (Hearts of Stone: chest +20, boots +6/+4, gloves +4/+3, trousers +8/+6) | ARM-01 | `gm_arm_items.xml` |
| The Fiend decoction no longer adds 20 carry capacity (`Mutagen16Effect`), and Mutagen 2's resistance by encumbrance | ALCH-13 | `gm_alch.xml`, `damage/formula.ws` |
| The weights of the 193 items legacy added (Kaer Morhen set, dismantle kits, master kits, cooking recipes, schematics, ...) | ARM-12, CRAFT-09, ITEM-11, FOOD-07, CRAFT-04, ... | each with its definition, legacy's weight |
| The inventory and dismantling screens refreshing the weight after a dismantle or repair (`UpdateEncumbranceInfo`) | CRAFT-09, ITEM-11 | `craft/dismantleKits.ws`, `items/repair.ws` |
| The armor class's share of an action's stamina cost (`GMStaminaArmorPenalty`), in the wrapper WGT-07 joins | ARM-02 | `armor/armorClass.ws` |
| `NGP Red Wolf Pants 2 _Stats`: legacy's NG+-only rewrite of the piece's stats besides its weight | ARM-10 | `gen_arm_items.py` writes the entry with WGT-03's weight; `gen_wgt.py` skips it |

**Not WGT:**

| Subject | Area | Why |
|---|---|---|
| The three option entries (`GMSinkBoat`, `GMSinkBoatOverEnc`, `GMEncumbranceMultiplier`), their labels (2110992180, 181, 183), defaults (on, 20, 0) and presets | OPT | The menu; WGT's code reads them through OPT-01's framework (DW3 on the boat's default) |
| The Wight trophy's +20 carry capacity (`wight_trophy_stats`) and the trophies' other bonuses, also in the abilities whose weight WGT-05 changes (`pig_contest_trophy_stats`, `q603_sharley_trophy_stats`) | TRPH | A trophy bonus; the trophies' weights are WGT-05's |
| `camm_trophy` losing its `Quest` tag; `FixQuestItems` (the `Quest` tag removed from keys, notes and masks no longer needed) | FIX, TRPH-02 | Lets the items be sold or dropped; not weight |
| The NG+ Censer's icon tag (`UI_OilLamp` → `UI_Censer`, NG+ only) in the unit whose weight WGT-05 changes | UI (or ITEM) | A display fix carried by the same entry |
| `Body palms cut` (Hearts of Stone's NG+ `def_item_misc.xml`): legacy added the missing NG+ definition that NG+'s armour variants name | ITEM | A `Body` item, never counted; attributed to ITEM-01 as not ported |
| Hearts of Stone's `Shovel _Stats` (both folders), whose weight 8 legacy removed when the Caretaker got his own `Caretaker Shovel _Stats` | AI | Attributed to AI-19 as not ported: the base game defines the same name, and the only item using it is the NPC `Shovel`; no play effect expected |
| The debug commands `addallgloves`, `addallboots`, `addallpants` | ITEM or (none) | Debug item lists, no weight |

## Changes at a glance

### What Ghost Mode changed

How the game counts weight decides what the numbers mean, so the table gives an item's **counted** weight (what it adds to the load) next to its definition: in 1.32 and 5.x, gear counts at half its weight + 0.01, junk, upgrades and usable items at a fifth + 0.01, keys and quest items at 0.01, alchemy items, ingredients, food and books at 0; in legacy every item counts its full weight, at least 0.01 (WGT-01).

| # | Feature | Vanilla 1.32 (and 5.x) | Legacy GM | Units (main) |
|---|---|---|---|---|
| WGT-01 | Every item counts its full weight | Gear half, junk a fifth, quest items 0.01, alchemy items, ingredients, food and books 0 (a pack of 100 Drowner brains: 0) | Every item its full weight × quantity, at least 0.01 per item (100 Drowner brains: 10) | 2 script units |
| WGT-02 | "Reduce item encumbrance (%)" | — | Every item's counted weight × (1 − the option, 0 to 100%); 0 by default | 1 script unit (+ OPT's entry) |
| WGT-03 | Armor and weapon weights | Bear Armor 1 10.9 (counts 5.46), Lynx Armor 3 17.0, Long Steel Sword 3.45, Nilfgaardian sword 1 6.2, Wolf School silver sword 3 5.6, Knight Mace 1 4.05, Crossbow 1 1.53, Explosive Bolt 0.2 | Weight by class and slot: heavy armor 15–20 / boots 10–12 / gloves 5–8 / trousers 5–8, medium 10–15 / 4 / 3 / 3, light 5–9 / 2–2.5 / 1–1.5 / 1–1.5 (Bear Armor 1 15, Lynx Armor 3 5); witcher steel swords 4, silver 2; generic steel swords 6–8, silver 4–6; secondary weapons 8–12; crossbows 1.5–3; bolts 0.05 | 1,670 (760 regular, 910 NG+) |
| WGT-04 | Alchemy and crafting weights | Potions, oils, bombs 0, mutagens 1; Drowner brain 0.7, Water essence 1.0, Monstrous hide 4.3, Wyvern plate 10.1, Steel ingot 1.5, Rune svarog 0.1, Weapon repair kit 1 0.5 (all ingredients count 0) | Potions, oils, bombs and mutagens 0.1; alchemy ingredients 0.05–0.2 (Drowner brain 0.1, Water essence 0.05), crafting materials 0.01–1.5 (Monstrous hide 1.1, Wyvern plate 1.25, Steel ingot 0.5), runes and glyphs 0.06/0.12/0.24, repair kits 0.1–0.6, schematics 0.1 (inert) | 606 (303 regular, 303 NG+) |
| WGT-05 | Other item weights | Food and drink 0.1–1.0 (count 0), keys 0.1 (count 0.01), notes and books 0.1/0.5 (count 0), junk (Cow hide 4.6, Ruby 0.1), trophies 2, torches and lamps 0.5–0.9, quest items 0.25–1, coins counted | Food and drink 0.05–0.1 (Bread 0.05, Viziman Champion 0.1), keys 0.05, notes 0.05, books 0.2, junk (Cow hide 0.6, Ruby 0.05), Blood and Wine's paintings 0.1, trophies 5, torches and lamps 0.2, quest items 0.05–0.2; Florens and Orens weightless; Hearts of Stone's pig trophy counted | 966 (483 regular, 483 NG+) |
| WGT-06 | Saddlebags and horse gear | Saddlebags +30/+70/+100 (base game), +110 Toussaint, +100 Ofir, +30/+70/+100 free DLCs; saddles 10–17, bags 2.5–3.5, blinders 0.4; blinders' panic 55–60; the base horse's sprint cost 5 | Saddlebags +40/+60/+80, +100 Toussaint, +90 Ofir, +40/+60/+80 free DLCs; saddles 5–11, bags 1–1.2, blinders 0.1–0.3; Toussaint and Ofir blinders' panic 75 and 70; the base horse's sprint cost 7.5 | 74 (37 regular, 37 NG+) |
| WGT-07 | Overencumbrance stamina penalty | None (overburdened: no running or sprinting) | Melee and agility actions (attacks, parries, counters, dodges, rolls, sprint, jump) cost more by the share over the limit, up to double (20% over: +20%), added to the armor class's share | 2 script units (1 shared) |
| WGT-08 | No fast travel while overburdened | Allowed | Blocked | 2 script units |
| WGT-09 | No canter or gallop while overburdened | Allowed | Roach trots at most while Geralt cannot sprint | 1 script unit |
| WGT-10 | Sinking boats | — | A boat sinks under Geralt when he boards it more than 20% over his limit (option, on by default in the code: DW3), with "Your over encumbrance is too high" | 4 script units, 9 CSV rows |
| WGT-11 | Encumbrance after a knockout (fix) | Not updated when Geralt comes to | Updated | 1 script unit |
| WGT-12 | Zero-encumbrance debug command | — | `togglezeroenc`: every item weighs 0 | 1 script unit |

### What 5.x changed

| # | 5.x change (from code and data) |
|---|---|
| WGT-01 | "Ignore Item Weight" (accessibility): while on, nothing counts (DW1); the formula otherwise 1.32's |
| WGT-02, WGT-07, WGT-08, WGT-11, WGT-12 | None |
| WGT-03 to WGT-05 | No weight of an existing item; 175 new regular items (203 NG+) at 1.32's scale (DW2) |
| WGT-06 | No capacity or horse gear stat; the Fire Horse gear (Blood and Wine's Toussaint gear's stats) |
| WGT-09 | `CanCanter` also refuses while the horse pulls a cart |
| WGT-10 | "Unlimited Boat Durability" (accessibility): while on, no boat can be destroyed, so none sinks |

### Classification and action

| # | Feature | Class | Action |
|---|---|---|---|
| WGT-01 | Full weight | clean, overlap (5.x's option) | Legacy's formula (PW3); 5.x's "Ignore Item Weight" by DW1 |
| WGT-02 | Weight reduction option | clean | Legacy's (PW3), the entry OPT's |
| WGT-03 | Armor and weapons | clean | Legacy's (PW2, PW4); 5.x's new gear by DW2 |
| WGT-04 | Alchemy and crafting | clean | Legacy's (PW2, PW4) |
| WGT-05 | Other items | clean | Legacy's (PW2, PW4) |
| WGT-06 | Saddlebags, horse gear | clean | Legacy's (PW2, PW9); the Fire Horse gear by DW2 |
| WGT-07 | Stamina penalty | clean | Legacy's, joined to ARM-02's term (PW5) |
| WGT-08 | Fast travel | clean | Legacy's (PW6) |
| WGT-09 | Canter and gallop | clean | Legacy's on 5.x's body (PW6) |
| WGT-10 | Boats | clean | Legacy's (PW7), the default by DW3 |
| WGT-11 | Knockout update | clean | Legacy's (PW6) |
| WGT-12 | Debug command | clean | Not ported (PW8) |

---

### WGT-01 Every item counts its full weight

| | |
|---|---|
| Kind | system |
| Pillars | P6, P8 |
| 5.x class | clean, overlap (DW1) |
| Flags | balance |
| Depends on | WGT-03 to WGT-06 (the weights it counts) |
| Skill trees | n/a |
| Port form | `@replaceMethod(CInventoryComponent) GetItemEncumbrance` with legacy's formula (5.x's body is 1.32's), in `scripts/local/gm/weight/encumbrance.ws`; `IsItemEncumbranceItem` and `GetEncumbrance` stay 5.x's (DW1) |
| Port status | **signed off** (2026-11-02); **ported** (slice W4), verified |
| Open checks | a real pick-up and the inventory's weight display |
| Save impact | none (the load is recomputed from the definitions at every `UpdateEncumbrance`) |
| NG+ counterpart | the same code |

**What it does** (changelist 924, 931; mod description section 4): every item Geralt carries counts its full weight, so ingredients, food, potions and books, weightless in vanilla, now fill the load, and gear counts twice what it did. The weights themselves were cut to match (WGT-03 to WGT-05): 100 Drowner brains weigh 10 (vanilla 0), a Swallow 0.1, a heavy chest 15–20 (vanilla 22.1 counted as 11). Every item weighs at least 0.01, so a stack of weightless items still counts; items the game excludes (recipes, schematics, bodies, items tagged `EncumbranceOff`) still weigh nothing.

**Implementation (legacy):** `CInventoryComponent.GetItemEncumbrance`: when the item counts (`IsItemEncumbranceItem`), max(`GetItemWeight`, 0.01) × quantity × (1 − `GetEncumbranceMult`), 0 below 0.01; the category rules are commented out; the debug fact `modSigns_debug_zero_enc` returns 0 (WGT-12). `GetTotalArmorWeight` (the four armor pieces' weight) is never called.

**5.x:** 1.32's formula. How the engine reads an item's weight (probed in game): `GetItemWeight` is the item's own `weight` attribute when it has one above 0; without one, its abilities' `<weight>` nodes are summed; the two are never added (Blood and Wine's Toussaint Crossbow 1: item 1.53, ability 2.39, weighs 1.53); it is per item, whatever the stack. `GetItemAttributeValue(id, 'weight')` and the definitions' `GetItemAttributeValueNoRandom` read the abilities' nodes only (the crafting previews read it so, in legacy too). A `mult` weight node alone (NPC `Spear 1`: base 0, mult 1) weighs 0. Every reader of weight in 5.x goes through `GetItemEncumbrance`, `GetEncumbrance` or `GetItemWeight`, as in legacy. "Ignore Item Weight" makes `IsItemEncumbranceItem` false and `GetEncumbrance` 0 while on, so with legacy's formula the option still empties the load (DW1). The loot window shows 0 for quest items, ingredients and alchemy items (1.32's and legacy's rule; 5.x adds the option). The tooltip hides a weight of 0 (only `EncumbranceOff` items and recipes, under legacy's formula).

**Decisions:** legacy's formula (PW3); `GetTotalArmorWeight` not ported (never called). DW1 for 5.x's option.

**Slices:**

W4. **The formula and the option** (with WGT-02). Verified 2026-11-02, both trees (`GMTest_wgt04` in the regression, scripted): spawned stacks counted by `GetItemEncumbrance` against the definitions (100 Drowner brains 10, a Bear Armor 15, a key 0.05, a Swallow 0.1, florens and a schematic 0); with "Ignore Item Weight" on nothing counts. Failed first on a build without the replacement.

**Later:** the loot window shows each item's weight (legacy shows 0 for ingredients and alchemy items although they weigh).

### WGT-02 "Reduce item encumbrance (%)"

| | |
|---|---|
| Kind | system |
| Pillars | P8 |
| 5.x class | clean |
| Flags | — |
| Depends on | WGT-01 (the formula reads it), OPT-01 (the entry, the default 0) |
| Skill trees | n/a |
| Port form | the reader `GMGetEncumbranceMult` in `weight/encumbrance.ws` (OPT-01's `GMGetOptionFloat('GMGameplayOptions', 'GMEncumbranceMultiplier')`, clamped to 0–100 %), the entry and its label (2110992183) in the gameplay group through OPT-01 |
| Port status | **signed off** (2026-11-02); **ported** (slice W4), verified |
| Open checks | the option changed in the menu updates the load at once (legacy: at the next `UpdateEncumbrance`) |
| Save impact | none |
| NG+ counterpart | — |

**What it does** (changelist 1232): a slider from 0 to 100% that lowers every item's counted weight by that share (50%: a 15 chest counts 7.5); 0 in every preset and by default.

**Implementation (legacy):** `W3GameParams.GetEncumbranceMult`; the term in `GetItemEncumbrance`.

**5.x:** nothing like it; "Ignore Item Weight" is the all-or-nothing 100% (DW1).

**Decisions:** legacy's (PW3).

**Slices:**

W4. **The option** (with WGT-01). Verified 2026-11-02, both trees (`GMTest_wgt04`, the option set in memory and put back): at 50% each count and Geralt's whole load halve; at 100% an armor piece counts 0.

**Later:** the load recomputed when the option changes in the menu (legacy waits for the next update: a pick-up, a drop, an equip).

### WGT-03 Armor and weapon weights

| | |
|---|---|
| Kind | tuning |
| Pillars | P4, P6 |
| 5.x class | clean |
| Flags | balance |
| Depends on | ARM, SWD, AI, XBOW, ITEM (the same entries, written whole by their generators); WGT-01 (how they count) |
| Skill trees | n/a |
| Port form | `item_layer.py`: WGT owns the `<weight>` node of its ability units and the `weight` attribute of its item units (PW2); the generators that write those entries whole take legacy's weight (`gen_arm_items.py`, `gen_swd_items.py`, `gen_ai.py` with WGT in `PORTED`, `gen_xbow.py`, `gen_item.py`); the rest by `tools/gen_wgt.py` (PW4); 5.x's new gear by `item_layer.DW2`, applied by `gen_arm_new.py` and `gen_swd_items.py` |
| Port status | **signed off** (2026-11-02); **ported** (slices W1 to W3), verified |
| Open checks | — |
| Save impact | none (an item's weight is read from its definition: the items of the test save, a 5.x save from before the mod, weigh and count what fresh copies do) |
| NG+ counterpart | legacy's NG+ weights (equal to its regular ones but `Gnomish silver sword 2_crafted` 3 in NG+, 5 regular, and the NG+-only `NGP` pieces), whole entries |

**What it does** (changelist 925–928): armor and swords are the heaviest things Geralt carries, by a fixed weight per class and slot rather than 1.32's scattered values. Armor (regular, by class): heavy chests 15–20 (Bear School 15 at every tier; 1.32 8.36–22.7), boots 10–12, gloves 5–8, trousers 5–8; medium chests 10–15 (Gryphon and Wolf 10), boots 4–5, gloves 3–3.5, trousers 3–4; light chests 5–9 (Lynx 5; 1.32 6.52–17.0), boots 2–3, gloves 1–2, trousers 1–2; shirts and suits 0.5–1. Swords: every witcher school steel sword 4 and silver sword 2 (1.32 2.35–6.9), relics 3–6 (Aerondight of Blood and Wine 5.7 → 3), generic steel swords mostly 8 (Nilfgaardian sword 1 6.2 → 8, Long Steel Sword 3.45 → 4, short swords 6), generic silver swords 4–6, secondary weapons (maces, axes, the shield) 6–12 (Knight Mace 1 4.05 → 8, `q302_Mace` 3.5 → 12), the standalone starts' gear 2–8. Crossbows 1.5–3 (witcher crossbows 1.5, Crossbow 1 1.53 → 2, the free DLC's crossbows 8 → 2), bolts 0.05 (0.1–0.4). In the regular files: 731 abilities (armor 402, swords and other weapons 312, the standalone starts' gear 12, crossbows 5) and 29 items (15 crossbows, 14 bolts).

**Implementation (legacy):** the `<weight>` node of the `_Stats` abilities in `def_item_armor*.xml`, `def_item_boots/gloves/pants.xml`, `def_item_crafting_armor/boots/gloves/pants/weapons.xml`, `def_item_weapons*.xml`, `def_item_npcweapons.xml`, `def_item_weapons_secondary.xml`, `def_item_ep1/ep2_stand_alone.xml`, the free DLCs' item files (`dlc1`, `dlc5`, `dlc10`, `dlc12`, `dlc13`, `dlc14`, `dlc15`), base game and both expansions, regular and NG+; the `weight` attribute of crossbow and bolt items (`def_item_weapons_crossbow(s).xml`, `def_item_bolts.xml`, Hearts of Stone's `q603_circus_crossbow`). Blood and Wine's two Toussaint crossbows have their weight moved from the ability (removed) to the item (2 and 3); since an item's own weight wins, the ability change is inert, in legacy too, for them and for the `Ravix of Fourhorn` and `Geralt of Rivia` crossbows that share one of the abilities.

**5.x:** 1.32's weights on every existing piece; 5.x's new gear at 1.32's scale (DW2).

**Decisions:** legacy's (PW2, PW4); 5.x's new gear by DW2: the Netflix set 10 / 4 / 3 / 3 at every tier and its swords 4 and 2, Dol Blathanna and White Tiger 15 / 4.5 / 3.5 / 3.5, Scarlet Crest 15 / 5 / 2 / 3, the Dol Blathanna and Vixen swords 6 and 4, Top Notch 6 and 4, Heavy armor 03 Netflix 20 and Heavy gloves 04 Netflix 8 (sharing their counterparts' abilities), their `NGP` copies alike.

**Slices:**

W1–W3. **Item weights, ability weights, 5.x's new gear.** Verified 2026-11-02, both trees. `gen_wgt.py --verify` checks every WGT unit's weight as the game reads it (DLC over 5.x, both folders) against legacy's, and recomputes every DW2 item from its counterpart; the data test (`GMTest_wgtdata`, `tests/gmTestsWgtData.ws`, in the regression) spawns each regular WGT item and reads its `GetItemWeight` and each WGT ability's changed nodes through the definitions. Failed first on builds with 5.x's weights.

**Balance values:** the per-class weights are the reference for DW2 (Wolf: 10 / 4 / 3 / 3, witcher swords 4 and 2).

**Later:** —

### WGT-04 Alchemy and crafting weights

| | |
|---|---|
| Kind | tuning |
| Pillars | P6 |
| 5.x class | clean |
| Flags | balance |
| Depends on | ALCH (the alchemy items), CRAFT-07 (the ingredients), ENCH (runes and glyphs), ITEM-11 (the kits), the same entries' generators; WGT-01 |
| Skill trees | n/a |
| Port form | as WGT-03: items' `weight` through `item_layer.py` (`gen_item.py`, `gen_econ.py`'s entries, `gen_ench.py`); the alchemy abilities and the kits' abilities by `gen_wgt.py` and `gen_item.py` |
| Port status | **signed off** (2026-11-02); **ported** (slices W1, W2), verified |
| Open checks | — |
| Save impact | none |
| NG+ counterpart | legacy's NG+ weights (equal to the regular ones), whole entries |

**What it does** (changelist 929–930; mod description: "Ingredients having zero weight take it even further as you can loot virtually everything"): alchemy items and ingredients now count, at small weights. Potions, decoctions, oils and bombs weigh 0.1 each (1.32: 0; they share `default_potion_stats`, `ClearingPotion_stats`, `RestoringPotion_stats`, `default_oil_stats`, `default_bomb_stats`), mutagens 0.1 (1.32: 1, `CommonMutagenAbility`); alchemy ingredients mostly 0.05 (109 of 153: Nekker eye 0.7 → 0.05, Water essence 1.0 → 0.05, herbs 0.1 → 0.05) or 0.1 (Drowner brain 0.7 → 0.1, Dwarven spirit 1.0 → 0.1, Alcohest 0.8 → 0.1), a few 0.2 (Wyvern egg); crafting materials by bulk: monster hides and plates 1.1–1.5 (Monstrous hide 4.3 → 1.1, Wyvern plate 10.1 → 1.25, Czart hide 8.8 → 1.5), ingots 0.4–0.6 and plates 0.8–1.4 (Steel ingot 1.5 → 0.5, Dwimeryte plate 5.0 → 1.2), leather 0.5–1.4, ores 0.2–0.3, cloth 0.06–0.15, gems' dust 0.01; runes and glyphs 0.06 / 0.12 / 0.24 by grade (1.32 0.05 / 0.1 / 0.2; Hearts of Stone's 0.1 → 0.06); repair kits 0.1–0.6 (Weapon repair kit 1 0.5 → 0.1, Armor repair kit 3 1.4 → 0.6; the two kits' shared default abilities lose their 0.1); schematics 0.1 (Hearts of Stone's rune and glyph schematics; recipes and schematics never count, so this is inert). In the regular files: 283 items (alchemy ingredients 153, crafting ingredients 106, upgrades 14, schematics 10) and 20 abilities.

**Implementation (legacy):** `def_item_ingredients.xml`, `def_item_herbs.xml`, `def_item_upgrades.xml`, Hearts of Stone's `def_item_ep1_upgrades.xml` and `def_item_ep1_crafting_recipes.xml`, `def_item_alchemy_potion/oils/petards/mutagens.xml`, `def_item_alchemy_repair_kits.xml`, `def_item_misc.xml` (the kits' abilities); base game and both expansions, regular and NG+. Legacy's bombs (`default_bomb_stats`, also defined at 0 in Blood and Wine's quest file) weigh 0.1 in the port, as the changelist says.

**5.x:** 1.32's weights; 5.x's two new potions (Reinald's Philtre, Signs Enhancement) carry `default_potion_stats`, so they take legacy's 0.1 with it.

**Decisions:** legacy's (PW2, PW4), the inert schematic weights included (PW4).

**Slices:**

W1–W2. As WGT-03 (`gen_wgt.py --verify`, `GMTest_wgtdata`); a potion weighs `default_potion_stats`' 0.1 (`GMTest_wgt04`'s Swallow).

**Later:** —

### WGT-05 Other item weights

| | |
|---|---|
| Kind | tuning |
| Pillars | P6 |
| 5.x class | clean |
| Flags | balance |
| Depends on | FOOD-04 (food and drink entries), CRAFT, ECON (junk entries), UI-15 (the razor), TRPH (the trophies' bonuses in the same abilities) |
| Skill trees | n/a |
| Port form | as WGT-03; the coins' and the pig trophy's `EncumbranceOff` as a WGT-05 tag in `item_layer.TAGS`; the razor's weight by hand in UI-15's `gm_ui.xml` (as ECON's price), checked by `gen_wgt.py --verify` |
| Port status | **signed off** (2026-11-02); **ported** (slices W1, W2), verified |
| Open checks | — |
| Save impact | none |
| NG+ counterpart | legacy's NG+ weights, whole entries |

**What it does** (changelist 924, 931): everything else gets a small weight that now counts: food and drink 0.05 or 0.1 (Bread 0.6 → 0.05, Fish 0.85 → 0.05, Pork 0.8 → 0.1, Beauclair White 1.0 → 0.1; 1.32 counts none of them); keys 0.05 (89 keys, 0.1); notes and letters 0.05 (`Default Note _Stats` 0.1 → 0.05, 61 base-game notices), books 0.2 (`Default Book _Stats` 0.5); junk by bulk (pelts and hides 0.4–1.1: Cow hide 4.6 → 0.6, Bear pelt 3.7 → 1.1; gems 0.05; Gold ore 1.0 → 0.1; 45 junk items at 0.05); Blood and Wine's 22 paintings and junk items 0.1 (20 of them weightless in 1.32) and its 23 notices 0.05 (0.1); torches and lamps 0.2 (0.5–0.9), quest items 0.05–0.2 (`q103_bell` 1 → 0.1, Potestaquisitor 0.64 → 0.1, the Censer 0.9 → 0.2); trophies 5 (`base_trophy_stats` 2 → 5, Hearts of Stone's two quest trophies' own abilities too); Shani's alcohols 0.1 and flowers 0.05 (0.5); the razor 0.3 (0.85). The Nilfgaardian florens and Redanian orens get `EncumbranceOff` (coins weigh nothing), and Hearts of Stone's pig contest trophy loses it (it weighs 5 to 10, like the other trophies and more). Wolf liver, which legacy moved from the ingredients to the food, weighs 0.1 (5.x 0.9). In the regular files: 471 items (junk 158, misc 120, food and drink 90, keys 89, usable 14) and 8 abilities.

**Implementation (legacy):** `def_item_edibles.xml`, `def_item_junk.xml`, `def_item_keys.xml`, `def_item_notices.xml`, `def_item_books.xml`, `def_item_misc.xml`, `def_item_quest.xml`, `def_item_trophies.xml`, `def_item_ingredients.xml` (the razor) and the free DLC's `def_item_dlc15_items.xml` (three quest items given 0.1); base game and both expansions, regular and NG+.

**5.x:** 1.32's weights; 5.x's new quest notes have none (they count 0.01 under WGT-01, as legacy's own weightless quest items do).

**Decisions:** legacy's (PW2, PW4). The trophies' weights are WGT's, their bonuses TRPH's. **The pig contest trophy weighs 5 to 10, rolled per copy:** the item has no weight of its own, so its weight is its abilities' sum (`base_trophy_stats` 5 and `pig_contest_trophy_stats`), and legacy wrote the latter's weight as `max="5"` with no `min` (1.32: `max="0"`), so each copy rolls 0 to 5 more; legacy's random weight is kept (owner, 2026-11-02). Hearts of Stone's other quest trophy (`q603_sharley_trophy_stats`, `min="5"`) is a fixed 5 more. **Vanilla items defined twice:** Blood and Wine defines `poi_gor_d_06_note` and `poi_gor_d_06_note03` as books (`def_item_books.xml`, legacy 0.2) and as misc items without abilities (`def_item_living_world.xml`); CRAFT-08's whole entries (legacy's change to the second copy) make them misc items weighing 0.01, and six Hearts of Stone notes defined twice the same way take the second copy's icon; which copy legacy's game read is unknown; accepted by the owner (2026-11-02; noted in [CRAFT-08](craft.md#craft-08-dismantling)).

**Slices:**

W1–W2. As WGT-03 (`gen_wgt.py --verify`, `GMTest_wgtdata`, which accepts the pig trophy's range); the coins weightless and the pig trophy counted (`IsItemEncumbranceItem` on spawned items).

**Later:** —

### WGT-06 Saddlebags and horse gear

| | |
|---|---|
| Kind | tuning |
| Pillars | P6 |
| 5.x class | clean |
| Flags | balance |
| Depends on | ECON-01 (the same items' prices), WGT-01 |
| Skill trees | n/a |
| Port form | the items' `weight` through `item_layer.py` (`gen_econ.py`'s entries); the bag, blinder and horse abilities by `gen_wgt.py` (`extend` with the changed node for the base game's and Blood and Wine's; Hearts of Stone's and NG+ whole; the free DLCs' whole, PW4) |
| Port status | **signed off** (2026-11-02); **ported** (slices W1, W2), verified |
| Open checks | a real gallop with the blinders' panic resistance (read through the definitions only) |
| Save impact | none (the horse's abilities come from the equipped item's definition) |
| NG+ counterpart | legacy's NG+ values, whole entries |

**What it does** (undocumented beyond the changelist's "Saddlebags"): saddlebags add a steadier capacity: the base game's three bags +40 / +60 / +80 (1.32 +30 / +70 / +100: the first bag better, the best one worse), Blood and Wine's Toussaint bag +100 (+110), Hearts of Stone's Ofir bag +90 (+100), the free DLCs' Temerian, Nilfgaardian and Skellige bags +40 / +60 / +80 (+30 / +70 / +100); so Geralt carries 100 / 120 / 140 with the base game's bags (1.32: 90 / 130 / 160), plus Strong Back's 40. Horse gear weighs less when carried: the base game's saddles 5–11 (10–17), bags 1–1.2 (2.5–3.5), blinders 0.3 (0.4); the free DLCs' saddles 5.5–10.5, bags 1–1.2 and blinders 0.1–0.3 (the Temerian set 17, 3.2, 0.4; the Nilfgaardian and Skellige sets weightless in 1.32); Blood and Wine's and Hearts of Stone's horse gear keeps 1.32's weights. Two blinders resist panic better (Toussaint 60 → 75, Ofir 55 → 70), and the base horse's sprint costs more stamina (`HorseLevel1` 5 → 7.5) (PW9).

**Implementation (legacy):** `def_item_horse.xml` (base game, Blood and Wine, Hearts of Stone), `dlc1_items.xml`, `dlc5_items.xml`, `dlc14_items.xml`: the bag abilities' `encumbrance`, the blinders' `panic`, `HorseLevel1`'s `sprint_stamina_cost`, the items' `weight`.

**5.x:** 1.32's; the Fire Horse gear copies Blood and Wine's Toussaint gear's stats (bag +110 is the Toussaint bag's 1.32 value; DW2: it keeps 5.x's weights 6.01, 1.56 and 0.2, as legacy left the Toussaint gear at 1.32's).

**Decisions:** legacy's (PW2, PW9).

**Slices:**

W2. **Capacities.** Verified 2026-11-02, both trees (`gmtest_wgt_bags()` in `GMTest_wgt`): each base-game saddlebag equipped on Geralt's horse adds +40, +60, +80 to `GetMaxRunEncumbrance`; the other nodes through the definitions (`GMTest_wgtdata`).

**Later:** —

### WGT-07 Overencumbrance stamina penalty

| | |
|---|---|
| Kind | system |
| Pillars | P2, P6 |
| 5.x class | clean |
| Flags | balance |
| Depends on | ARM-02 (the wrapper whose factor it joins), STAM-03 (the cost functions), WGT-01 |
| Skill trees | n/a (the cost is the action's, whatever skill; Whirl and Rend have their own costs, STAM-09) |
| Port form | `GMOverEncumbrancePenalty()` in `weight/overEncumbered.ws`; ARM-02's wrapper in `armor/armorClass.ws` changed from `cost × (1 + armor)` to `cost × (1 + armor + overencumbrance)` for melee and agility actions but usable items (PW5) |
| Port status | **signed off** (2026-11-02); **ported** (slice W5), **verified** |
| Open checks | a real dodge and sprint while overburdened |
| Save impact | none |
| NG+ counterpart | the same code |

**What it does** (changelist 933; mod description: "being over encumbered adds severe penalties to sprinting, rolling and dodging actions, depending on how big your over encumbrance is"): while overburdened, every melee and agility action (light and heavy attacks, parries, counters, dodges, rolls, sprinting, jumping; not signs, not usable items) costs more by the share Geralt is over his limit, capped at double: 10% over, +10%; 50% over, +50%. The share adds to the armor class's (heavy armor +50% and 30% over: × 1.8; no armor −50% and 30% over: × 0.8). Geralt only: Ciri and NPCs get none.

**Implementation (legacy):** `W3PlayerAbilityManager.CalcStaminaOverEncumbrancePenalty` (with `EET_OverEncumbered`: clamp(load ÷ capacity − 1, 0, 1)), added to `CalcStaminaArmorPenalty` in `GetStaminaActionCost`'s melee branch: `cost *= 1 + penalty`.

**5.x:** nothing like it. 5.x's skill changes sit in `GetStaminaActionCostInternal`, below the wrapper, so the term multiplies the cost after every skill in both trees.

**Decisions:** legacy's (PW5): ARM-02 multiplies the class term on its own, so WGT-07 joins its term to that factor, as legacy.

**Slices:**

W5. **The cost term.** Verified 2026-11-02, both trees (`GMTest_wgt05`, `GMTestWgt05Classes`, in the regression; Geralt overloaded by spawned stacks): a dodge's and the sprint's cost at 20% and 120% over (share capped at 1); naked, in four light and four heavy pieces a dodge, a heavy attack and a jump × (1 + armor + share) ÷ (1 + armor); Aard, a usable item and Whirl unchanged; costs back after the drop. Failed first on a build without the term.

**Later:** —

### WGT-08 No fast travel while overburdened

| | |
|---|---|
| Kind | system |
| Pillars | P6 |
| 5.x class | clean |
| Flags | — |
| Depends on | — |
| Skill trees | n/a |
| Port form | wrappers of `W3Effect_OverEncumbered.OnEffectAdded`/`OnEffectRemoved` blocking and unblocking `EIAB_FastTravel` (source `OverEncumbered`), in `weight/overEncumbered.ws` |
| Port status | **signed off** (2026-11-02); **ported** (slice W5), verified |
| Open checks | the map's signposts refuse travel (a real attempt on screen; by script: the action blocked) |
| Save impact | none with the mod installed at the start (the block comes and goes with the effect, and action locks are saved with the player); a save made overburdened before the mod gets the block only when Geralt next becomes overburdened: a load restores the effect without `OnEffectAdded`, and `UpdateEncumbrance` adds the effect only when it is missing |
| NG+ counterpart | — |

**What it does** (changelist 932): while overburdened, fast travel is refused (`EIAB_FastTravel` blocked, as vanilla blocks it in combat).

**Implementation (legacy):** two lines in `W3Effect_OverEncumbered`.

**5.x:** 1.32's effect; the map's travel test reads `EIAB_FastTravel` (`mapMenu`), and 5.x adds no way around it.

**Decisions:** legacy's (PW6).

**Slices:**

W5. **The block.** Verified 2026-11-02, both trees (`GMTest_wgt05`): overburdened, `IsActionBlockedBy(EIAB_FastTravel, 'OverEncumbered')` is true, and false after the drop (the check reads the load's own block, as other sources can block fast travel too).

**Later:** —

### WGT-09 No canter or gallop while overburdened

| | |
|---|---|
| Kind | system |
| Pillars | P6 |
| 5.x class | clean |
| Flags | — |
| Depends on | — |
| Skill trees | n/a |
| Port form | `@wrapMethod(W3HorseComponentStateExploration) CanCanter`: `wrappedMethod() && thePlayer.IsActionAllowed(EIAB_RunAndSprint)` (5.x's cart and settlement rules kept), in `weight/overEncumbered.ws` |
| Port status | **signed off** (2026-11-02); **ported** (slice W5), **verified** by script; the gait on screen not seen |
| Open checks | a real ride overburdened (Roach trots at most) |
| Save impact | none |
| NG+ counterpart | — |

**What it does** (changelist 932): while Geralt cannot sprint, Roach cannot canter or gallop (`OnCanGallop` also asks `CanCanter`). The rule tests the sprint block, not the encumbrance, so whatever else blocks Geralt's sprint (scenes, some quest areas, being on a boat) also holds Roach to a trot; whether that ever showed in legacy is on the [legacy test list](../open-questions.md#to-test-in-legacy-ghost-mode).

**Implementation (legacy):** `CanCanter` returns false unless `EIAB_RunAndSprint` is allowed.

**5.x:** `CanCanter` also refuses while the horse pulls a cart. 5.x adds one `EIAB_RunAndSprint` blocker (petting the dog), so the side effect on Roach is legacy's.

**Decisions:** legacy's rule on 5.x's body (PW6).

**Slices:**

W5. **The gait rule.** Verified 2026-11-02, both trees (`GMTestWgt05Canter` in `GMTest_wgt05`): Roach's own `CanCanter`, called on her Exploration state, is true within the limit, false 30% over and true after the drop.

**Later:** —

### WGT-10 Sinking boats

| | |
|---|---|
| Kind | system |
| Pillars | P6 |
| 5.x class | clean |
| Flags | — |
| Depends on | OPT-01 (two entries, the defaults) |
| Skill trees | n/a |
| Port form | `@replaceMethod(W3Boat) OnAreaEnter` (5.x's body, which is 1.32's, with legacy's lines) and `@addMethod GMCheckPlayerEncumbrance`, in `weight/boat.ws`; the readers through OPT-01 (`GMSinkBoat`, `GMSinkBoatOverEnc`); the string 2110992179 (`gm_geralt_too_heavy`) in nine languages |
| Port status | **signed off** (2026-11-02); **ported** (slice W6), verified up to the sinking itself (open check) |
| Open checks | a real boarding overburdened on a boat in water (the boat sinks, the sound and the message); none after a save load on a boat (`GetLoadGameProgress`); boats that cannot be destroyed (quest boats) do not sink |
| Save impact | none (a boat already sunk stays sunk: 1.32's `HasDrowned`) |
| NG+ counterpart | — |

**What it does** (changelist 934–935, 1229–1231): when Geralt steps onto a boat while overburdened by more than the threshold (20% by default: carrying 145 with a 120 limit), the boat sinks under him (`TriggerDrowning`, the sinking sound) with "Your over encumbrance is too high"; boats that cannot be destroyed, and the boat he stands on as a save loads, are spared. "Sink the boat if overencumbered" turns it on or off, "Overencumbrance threshold to sink the boat (%)" sets the threshold (0 to 100).

**Implementation (legacy):** `W3Boat.OnAreaEnter` (the `OnBoatTrigger` branch), `W3Boat.CheckPlayerEncumbrance`, `W3GameParams.GetBoatSinkOption`, `GetBoatSinkOverEncumbranceOption`; defaults in `gmLoadDefaultSettings` (on, 20) and the presets ("Recommended" on and 20, the other two off and 0).

**5.x:** 1.32's `OnAreaEnter`, but the rule's test whether the boat can be destroyed (`GetCanBeDestroyed`) also reads 5.x's accessibility option "Unlimited Boat Durability" (`Accessibility`/`DisableDurabilityBoat`, also set by the "Bard's Ballad" preset): with it on, no boat sinks under Geralt, however overburdened.

**Decisions:** legacy's (PW7); the default, which the code and the changelist give differently, by DW3. 5.x's "Unlimited Boat Durability" keeps boats afloat, as the player's choice: an accessibility option off by default, like "Ignore Item Weight" (DW1); not a deviation, content legacy never had (owner, WGT audit F1, 2026-11-02).

**Slices:**

W6. **Boats.** Verified 2026-11-02, both trees (`GMTest_wgt06` in `GMTest_wgt`, options set in memory and put back): the message by key and id; a boat spawned behind Geralt, boarded through its `OnBoatTrigger` area: it holds when not overburdened, 10% over with the threshold 20, and 30% over with the option off; the thresholds compare as set; 30% over with it on, every condition of the sinking holds. The sinking itself is not run by script: `TriggerDrowning` on a boat spawned on land crashed the game.

**Later:** —

### WGT-11 Encumbrance after a knockout (fix)

| | |
|---|---|
| Kind | fix |
| Pillars | P8 |
| 5.x class | clean |
| Flags | — |
| Depends on | DIFF-07 (the knockout and the guards' toll) |
| Skill trees | n/a |
| Port form | `@wrapMethod(CR4PlayerStateUnconscious) OnLeaveState`: after 5.x's body, `UpdateEncumbrance()` for Geralt, in `weight/overEncumbered.ws` |
| Port status | **signed off** (2026-11-02); **ported** (slice W5), verified |
| Open checks | — |
| Save impact | none |
| NG+ counterpart | — |

**What it does** (not in the changelist): when Geralt comes to after being knocked out (a lost fist fight, the guards' toll), his load is recounted, so a change made while he was down (items or money taken) shows at once.

**Implementation (legacy):** one line in `OnLeaveState` (`//modSigns`). Found by DIFF's slice D4 (porter's call, confirmed by the owner, 2026-10-31).

**5.x:** 1.32's state.

**Decisions:** legacy's (PW6).

**Slices:**

W5. **The update.** Verified 2026-11-02, both trees (`gmtest_wgt11()`, run on its own because the state's code revives Geralt): the overburdened effect taken off by hand comes back when the Unconscious state is left.

**Later:** —

### WGT-12 Zero-encumbrance debug command

| | |
|---|---|
| Kind | infra |
| Pillars | — |
| 5.x class | clean |
| Flags | — |
| Depends on | — |
| Skill trees | n/a |
| Port form | none (PW8) |
| Port status | **signed off** (2026-11-02); not ported (PW8) |
| Open checks | — |
| Save impact | — |
| NG+ counterpart | — |

**What it does:** debug only. `togglezeroenc` sets or clears the fact `modSigns_debug_zero_enc`, which makes every item weigh 0 in `GetItemEncumbrance`.

**5.x:** the vanilla command `mule()` (`EncumbranceBoy`, the fact `DEBUG_EncumbranceBoy`) keeps the overburdened effect off, and "Ignore Item Weight" empties the load.

**Decisions:** not ported (PW8).

**Later:** —

---

### Dependencies on other areas

- **Areas WGT builds on:** the item layer (`item_layer.py`) and the item generators of ARM, SWD, ITEM, CRAFT, FOOD, ALCH, XBOW, AI, ENCH and ECON (the entries carrying the weights); `gen_econ.py`'s short `extend` entries; ARM-02's stamina wrapper; OPT-01's menu framework; DIFF-07's knockout.
- **Areas WGT shares with:** OPT (the three entries and their defaults: DW3), TRPH (the trophies: weights WGT's, bonuses TRPH's, the Wight trophy's capacity TRPH's), HORSE (PW9 takes the horse gear's two other stats).

### Save impact

None: weights, capacities and the horse gear's stats are read from the definitions (verified: the items of the test save, a 5.x save from before the mod, weigh and count what fresh copies do); the load is recomputed at every `UpdateEncumbrance` (a pick-up, a drop, an equip, a load); the fast-travel block comes with the overburdened effect (WGT-08). The mod is installed at the start of a playthrough ([save compatibility](../feature-mapping.md#save-compatibility)).

### Area decisions

**Decided by the owner (2026-11-02): every recommendation.** DW1 (a) 5.x's "Ignore Item Weight" kept as it is; DW2 (b) 5.x's new gear at the legacy weights of ECON's DE2 counterparts; DW3 (a) boats sink by default at 20% (the same decision as OPT's DO3). Porter's calls PW1 to PW10 confirmed.

| # | Question | Options | Recommendation |
|---|---|---|---|
| DW1 | 5.x's accessibility option "Ignore Item Weight" (WGT-01). Legacy had nothing like it; in 5.x, when the player turns it on (or picks the "Bard's Ballad" preset), nothing counts towards the load, so Geralt is never overburdened and WGT-07 to WGT-10 never trigger; off, Ghost Mode's weights apply. Legacy's own "Reduce item encumbrance" at 100% has the same effect | (a) keep 5.x's option working as it is (off by default; the player's explicit choice); (b) neutralise it while Ghost Mode is installed (a wrapper returning false for it in `IsItemEncumbranceItem` and `GetEncumbrance`), so weights always count; (c) keep it and also hide it, leaving only Ghost Mode's slider | **(a)**: an accessibility option the player sets on purpose, off by default, so the default game is legacy's; neutralising a visible option would make it lie. Not a deviation: content legacy never had (as ECON's PE12 kept 5.x's "Sell Junk") |
| DW2 | The weights of 5.x's new gear (WGT-03, WGT-06). 5.x added gear at 1.32's scattered weights, among legacy's per-class ones: Netflix Armor 7.32 / 8.57 / 11.56 (legacy's Wolf Armor, the set it copies: 10 at every tier), Netflix steel swords 4.64–4.81 (Wolf 4), Netflix silver swords 4.3–4.8 (Wolf 2), Scarlet Crest's four pieces 4.77 / 1.2 / 0.9 / 1.33 (8.2 in all; a medium set in legacy weighs 10–15 / 4 / 3 / 3), Dol Blathanna and White Tiger 9.52 / 3.4 / 3.6 / 2.7, the Vixen swords 5.8 and 4.8, Top Notch 3.2 and 2.05, Heavy armor 03 Netflix 26.92 (Heavy armor 03: 20.32 → 20), the Fire Horse saddle 6.01, bag 1.56 + 1, blinders 0.2 (Blood and Wine's Toussaint gear they copy: 10, 2.5, 0.4, which legacy left as 1.32's) | (a) 5.x's weights as they are; (b) by analogy: each piece at the legacy weight of the counterpart ECON's DE2 gave it (Netflix 10 / 4 / 3 / 3 and swords 4 and 2; Dol Blathanna and White Tiger 15 / 4.5 / 3.5 / 3.5; Scarlet Crest 15 / 5 / 2 / 3; the Vixen and Dol Blathanna swords 6 and 4; Top Notch 6 and 4; Heavy armor 03 Netflix 20, Heavy gloves 04 Netflix 8), and 5.x's own weight where legacy left the counterpart's at 1.32's (the Fire Horse gear); potions take `default_potion_stats`'s 0.1 by themselves; quest items and cosmetics 5.x's; (c) by class only: legacy's most common weight for the piece's class and slot (medium 10 / 4 / 3 / 3 for every medium set) | **(b)**: the counterparts are already chosen and confirmed for prices (DE2), and legacy's weights are per class, so the new gear weighs what its peers weigh (otherwise Scarlet Crest, a medium set, weighs 8.2 where every legacy medium set weighs 20–25 and counts twice what it did); same reasoning as DE2. Not a deviation: content legacy never had |
| DW3 | Whether boats sink by default (WGT-10; the default is set by OPT). The changelist says "off by default, can be tweaked in options"; legacy's code turns it on (20%) for a new install (`gmLoadDefaultSettings`) and in the "Recommended" preset, and the options text says the recommended preset "enables boat sinking". A contradiction between the changelist and the code | (a) the code: on, 20%, as `gmLoadDefaultSettings` and "Recommended"; (b) the changelist: off by default, 20% when turned on | **(a)**: the code is the better guide where they differ (feature-mapping's rule), and the preset text agrees with it; a contradiction, so it goes to the owner and the legacy test list. Not a deviation under (a); (b) would be one |

### Porter's calls

Confirmed by the project owner (2026-11-02); each follows legacy or has no play effect.

| # | Call |
|---|---|
| PW1 | WGT is ported as one area with one audit at the end, about 3,300 units |
| PW2 | **The form of the data:** `item_layer.py` gives WGT the `weight` attribute of its item units (`ATTRS`), the `<weight>` and `encumbrance` nodes, and the two horse stats, of its ability units (`NODES`, with `owns()`'s `"*"` still excluding the weight for other features), and the `EncumbranceOff` tag of its three items (`TAGS`); WGT's fields alone never make a tool write an entry whole (`item_layer.WHOLE`, as ECON's). Whichever generator already writes an entry whole applies them: `gen_item.py` (`gm_item.xml`: 454 regular items and 7 kit abilities), `gen_arm_items.py` (`gm_arm_items.xml`: 409 regular abilities), `gen_swd_items.py` (`gm_swd_items.xml`: 256), `gen_ai.py` (`gm_ai_weapons.xml`: 21, WGT in `PORTED`), `gen_xbow.py` (`gm_xbow.xml`: 7), `gen_ench.py` (2 Hearts of Stone runes), `gen_econ.py` (149 items: 139 `extend` entries, which take the `weight` attribute next to the price, and 10 Hearts of Stone entries whole); the razor's hand-written entry in `gm_ui.xml` takes legacy's 0.3 by hand (as ECON's price) |
| PW3 | WGT-01 and WGT-02: legacy's `GetItemEncumbrance` as a `@replaceMethod`, its reduction read through OPT-01 (default 0); `IsItemEncumbranceItem` and `GetEncumbrance` stay 5.x's, so DW1 (a) needs no code |
| PW4 | **The entries no generator writes** (203 regular items, 59 regular abilities, and their NG+ twins) by `tools/gen_wgt.py`: items through `gen_econ.py`'s writer extended to WGT's units (one entry per name: an item with a price and a weight change gets one `extend` entry with both); abilities in `items/gm_wgt.xml` as `extend` entries with the `<weight>` node only for the base game's and Blood and Wine's, whole (`replace`) for Hearts of Stone's (`extend` empties them), the free DLCs' (not probed for abilities) and the abilities losing their weight node (the two repair kits' default abilities; a removal cannot be an `extend`); every NG+ entry whole (`items_plus`, as ECON's PE2); names another DLC file defines are skipped; with `--check`, `--verify` (every WGT unit's weight as the game reads it, DLC over 5.x, against legacy's, both folders) and an in-game data test of every regular unit's weight read through the definitions. The inert schematic weights are ported with the rest (legacy's data; no play effect) |
| PW5 | WGT-07: the overencumbrance term added to ARM-02's factor (`1 + armor + overencumbrance`), as legacy, instead of a second factor: ARM-02's wrapper in `armor/armorClass.ws` takes the term (a change to a signed-off feature's code) |
| PW6 | WGT-08, WGT-09, WGT-11: legacy's lines in wrappers of 5.x's functions (the fast-travel block in the effect's two events, the sprint test after 5.x's cart test in `CanCanter`, the update after `OnLeaveState`) |
| PW7 | WGT-10: legacy's boat rule in an override of `W3Boat.OnAreaEnter` (5.x's body is 1.32's), its message (2110992179, nine languages) and the two entries (OPT's, with DW3's default) |
| PW8 | WGT-12: the debug command is not ported (debug only; 5.x's `mule()` and the tests' own setters do its work); `GetTotalArmorWeight` is not ported (never called) |
| PW9 | WGT-06 takes the horse gear's two undocumented changes that are not weight (Toussaint and Ofir blinders' panic 60 → 75 and 55 → 70, the base horse's sprint cost 5 → 7.5): they sit in the same horse entries |
| PW10 | NG+: legacy's NG+ weights and capacities as written (they equal the regular ones but one sword, `Gnomish silver sword 2_crafted`, 3 against 5; legacy behaviour first), in whole entries; untested, as every NG+ change |
