# WGT: item weights and encumbrance

What Geralt's items weigh and what carrying too much does: the weight of every item (gear, alchemy items and ingredients, food, junk, keys, books, trophies, horse gear), which items count towards the load and how much, how much a saddlebag adds to what Geralt can carry, and the consequences of being overburdened (the stamina cost of actions, fast travel, the horse's gallop, a boat sinking under him), with the one option that lightens every item. Ghost Mode's changelist has its own section, "Weight" (lines 921–935), the encumbrance lines of "Mod options" (lines 1226–1232; the menu entries are [OPT](opt.md)'s), the Wight trophy's carry bonus (line 906, TRPH's) and Strong Back (line 458, SKL's, ported); the mod description explains the intent in section 4, "Economy, looting and crafting", and in its list of combat changes.

**The player-visible texts first.** Legacy's changelist, quoted exactly: "All items have weight."; "Swords and armors (especially heavy armors) have the biggest weight, so you won't be able to carry much of these. Some weights might seem unrealistic and I'd rather implement inventory space restriction myself, but right now weight looks like the only way to somehow balance the economy."; "In general, alchemy items and ingredients have small weight, but some of the ingredients, like monster hides, weight more."; "You won't need to carry as much items as in vanilla because of changes to crafting and loot."; "Fast-travel and galloping while over-encumbered were disabled."; "Over encumbrance adds penalties to stamina cost for all actions."; "If your over encumbrance is too big (20% over the limit), the boat you're trying to board will sink (off by default, can be tweaked in options)."; the options "Sink the boat if overencumbered: enables boat sinking if Geralt is overencumbered.", "Overencumbrance threshold to sink the boat (%): defines overencumbrance threshold in percents relative to max carry weight at which boat sinking happens.", "Reduce item encumbrance (%): reduces item weight for all the items in percents.", and the preset line "Gameplay presets: recommended - enables boat sinking if overencumbered and cooldown for signs and special sword attacks". The mod description adds "Ingredients having zero weight take it even further as you can loot virtually everything, so you never run out of crafting components or money.", "all items have weight, so you can't carry hundreds of swords and armor anymore;", "weight limitation won't create issues with alchemy and crafting;", "you are no longer able to gallop and fast-travel while overencumbered;" and "being over encumbered adds severe penalties to sprinting, rolling and dodging actions, depending on how big your over encumbrance is;". Legacy's own strings (`localization/modGhostMode/<lang>.csv`): the boat's message "Your over encumbrance is too high" (2110992179, `gm_geralt_too_heavy`, WGT-10) and the three option labels "Sink the boat if over encumbered" (2110992180), "Over encumbrance threshold to sink the boat (%)" (2110992181) and "Reduce item encumbrance (%)" (2110992183) (OPT's). The game's texts involved (decoded from 1.32's and 5.x's `en.w3strings` with `w3strings.py`; legacy changed none): the status "Overburdened" (1065948) and "You are overburdened." (1066169); the tutorial "Overburdened" (1087318), whose text 5.x rewrote: 1.32 "You are overburdened – Geralt is carrying too many items! If you load yourself down with too much loot, you won't be able to run or sprint. …", 5.x "You're overburdened – Geralt is carrying too much. When overburdened, a … symbol will appear, and Geralt will lose his ability to run or sprint. Check your carry weight in the Inventory panel. Drop, sell, or dismantle items to reduce weight, or upgrade your horse's saddlebags to carry more." (1087319, markup left out); the saddlebags' "Saddlebags allow you to carry more weight." (1082351) and "Saddlebags increase the number of items you can carry without being overburdened." (1085649); Strong Back's "Increases the amount of weight the witcher can carry without being overburdened." (1063959); and 5.x's new accessibility option "Ignore Item Weight" (1446543, `WeightlessItems`), part of the preset "Bard's Ballad: Focus & Rest" (1446541). Neither the tutorial nor any game text mentions legacy's fast-travel, gallop, stamina or boat rules.

**What 5.x did in this area** (from `vanilla-5.x`, unverified in game). **No weight legacy changed**: all 3,287 item and ability entries whose weight legacy changed (1,568 regular, 1,719 NG+) have 1.32's weight in 5.x; Geralt's base carry capacity (`encumbrance` 60 in `geralt_stats.xml`) and every saddlebag's capacity are 1.32's; the encumbrance code (`W3PlayerWitcher.GetEncumbrance`, `GetMaxRunEncumbrance`, `UpdateEncumbrance`; `CInventoryComponent.GetItemEncumbrance`; `W3Effect_OverEncumbered`; `W3Boat.OnAreaEnter`; `CR4PlayerStateUnconscious.OnLeaveState`) is 1.32's, but for what follows. **New in 5.x:** the accessibility option **"Ignore Item Weight"** (`Accessibility`/`WeightlessItems`, a visible toggle, off unless the player or the "Bard's Ballad" preset turns it on): `IsItemEncumbranceItem` and `GetEncumbrance` return nothing while it is on, the loot window shows no weight, and changing it updates the encumbrance at once (`CR4IngameMenu`); the item tooltip hides its weight line when the weight is 0 (`W3TooltipComponent.AddItemStats`); the horse cannot canter or gallop while pulling a cart (`CanCanter`'s new `isCart` test); the new tree's Strong Back (`perk_35`, +20 per rank, 3 ranks) refreshes the encumbrance when equipped or ranked (`RefreshEncumbrance`; SKL gives both trees legacy's +40, ported); **175 new regular items** (203 NG+) with 1.32-scale weights: the Netflix set (armor 7.32 to 11.56, swords 4.3 to 4.81), Dol Blathanna, White Tiger, Scarlet Crest (its four pieces 8.2 in all), the Vixen and Top Notch swords, two Netflix copies of 1.32 gear, the Fire Horse saddle, bags and blinders (6.01, 1.56 + 1, 0.2), two potions, quest items and cosmetics (DW2).

**How legacy Ghost Mode implements it.** Scripts: `CInventoryComponent.GetItemEncumbrance` rewritten (every counted item weighs its full weight × quantity, at least 0.01 per item, × the option's reduction; vanilla counts gear at half its weight, junk, upgrades and usable items at a fifth, quest items and keys at 0.01, and alchemy items, ingredients, food and books at nothing), `W3GameParams.GetEncumbranceMult`, `GetBoatSinkOption`, `GetBoatSinkOverEncumbranceOption` (option readers), `W3PlayerAbilityManager.CalcStaminaOverEncumbrancePenalty` and its term in `GetStaminaActionCost`, `W3Effect_OverEncumbered.OnEffectAdded`/`OnEffectRemoved` (fast travel blocked), `W3HorseComponentStateExploration.CanCanter` (no canter or gallop while sprinting is blocked), `W3Boat.OnAreaEnter` and the new `CheckPlayerEncumbrance` (the boat sinks), `CR4PlayerStateUnconscious.OnLeaveState` (the encumbrance updated after a knockout), the debug command `togglezeroenc`, and the unused helper `CInventoryComponent.GetTotalArmorWeight`. Data: the `weight` attribute of 1,618 item entries (809 regular, 809 NG+, besides the items legacy added) and the `<weight>` node of 1,669 abilities (759 regular, 910 NG+), in 84 item files of the base game, both expansions and seven free DLCs and their 84 NG+ twins; the `encumbrance` of eight saddlebag abilities; the `EncumbranceOff` tag on the two foreign coins and off a Hearts of Stone trophy; the panic resistance of two blinders and the sprint cost of the base horse (horse gear, undocumented). Menu: three entries of the gameplay group (`GMSinkBoat`, `GMSinkBoatOverEnc`, `GMEncumbranceMultiplier`) with their defaults in `gmLoadDefaultSettings` and the presets (OPT's). No binary file.

Unit lists: [attribution.csv](attribution.csv): mapped 2026-11-02 from the changelist's sections and the mod description, every hand-off to WGT in the other areas' files (ALCH, ARM, SWD, CRAFT, FOOD, ITEM, ENCH, XBOW, AI, ECON, STAM, EFX, UI, DIFF, SKL), a comparison of every item's `weight` attribute and every ability's `<weight>` and `encumbrance` nodes in the three branches (`master`, `legacy-GM`, `vanilla-5.x`; every item and ability of the regular and NG+ item and ability folders, base game, expansions and free DLCs, not Ghost Mode's DLC), the `EncumbranceOff` tag changes, a script diff of every function legacy changed that reads or changes weight or encumbrance, and sweeps (`unit_sweep.py` for encumbr, weight, `GetItemWeight`, `OverEncumbered`, fast travel, gallop, `MaxRunEncumbrance`, `EncumbranceBoy`, carry, boat, heavy, burden; the remaining unattributed units checked for a weight, capacity or encumbrance change: none). **3,339 units carry a WGT feature**: 568 newly attributed, WGT added to 2,771 shared units (the item and ability entries ARM, SWD, ITEM, CRAFT, FOOD, ALCH, XBOW, AI, ENCH, UI and ECON hold, and `GetStaminaActionCost`). By type: 14 script units, 1,583 XML units, 1,733 NG+ XML units, 9 CSV rows (the boat message in nine languages). One more unit found by the sweeps goes to UI-17 (`IsItemEncumbranceItem`, whose only legacy change belongs to UI-17's unused stash code). Unattributed units: **1,115 before, 546 after** (569 newly attributed); none of those left carries a weight, capacity or encumbrance change (the trophies' bonuses, TRPH's, the Wight trophy's +20 carry capacity among them; hairstyles, quest fixes, engine re-declarations and strings already noted by other areas). The weights of the 193 items legacy added came with their features: the port has legacy's weight on 242 of the 265 such entries, the 21 missing ones are named otherwise in the port (MUT-12's Catalyst) or missing in NG+ (see [Surprises](#surprises-for-other-areas)), and Wolf liver, moved by legacy from the ingredients to the food, has 5.x's 0.9 instead of legacy's 0.1 (WGT-05 takes it). Port status: **ported** (slices W1 to W6, 2026-11-02, verified; integrated on 5.x-GM `fbb925eb`); **audited** 2026-11-02 ([WGT audit](#wgt-audit-2026-11-02): 6 findings, every one fixed, decided or recorded, [close-out](#wgt-audit-close-out)); **signed off** by the owner (2026-11-02); the [area decisions](#area-decisions) and the [porter's calls](#porters-calls) decided by the owner (2026-11-02). Open checks in play: a real overburdened ride (WGT-09), a real boat sinking (WGT-10), a real pick-up and the inventory's weight display (WGT-01).

**Size.** Mostly data, mechanical: about 3,300 weights and eight capacities through the item generators the other areas built, plus eight small script changes (one formula, one cost term, four one-line blocks or updates, the boat) and three menu entries. One area, one part, one audit at the end (PW1).

## Scope

**WGT covers** the weight of every item and how it counts, the carry capacity saddlebags add, the consequences of overencumbrance (stamina costs, fast travel, the horse's gait, boats), the weight-reduction option's effect, and the horse gear's other two stats legacy changed (PW9).

**Unchanged by legacy, and by 5.x** (from the data and code): Geralt's base carry capacity (60), the overencumbrance threshold (overburdened at the capacity + 1: `UpdateEncumbrance`), what "overburdened" itself does (no running or sprinting on foot: `W3Effect_OverEncumbered` blocks `EIAB_RunAndSprint`), the capacity counting the saddlebags of the horse wherever the horse is (`GetMaxRunEncumbrance`), equipped items counting towards the load, recipes, schematics and bodies never counting (`IsItemEncumbranceItem`), items tagged `EncumbranceForceYes`/`EncumbranceOff`, the inventory's weight display and the loot window's weight column (which, in both games and in legacy, shows 0 for quest items, ingredients and alchemy items whatever they weigh).

**Already ported by other areas** (nothing left for WGT):

| Subject | Ported by | What |
|---|---|---|
| Strong Back: +40 carry capacity in both trees (legacy 60 → 40; 5.x's new tree 20 per rank) | SKL-18 (signed off; `perk_22`, `perk_35`) | `gm_skill_trees.xml`, `gm_skills.xml` |
| The Thief armor's carry bonus (Hearts of Stone: chest +20, boots +6/+4, gloves +4/+3, trousers +8/+6) | ARM-01 (signed off) | `gm_arm_items.xml` |
| The Fiend decoction no longer adds 20 carry capacity (`Mutagen16Effect`), and Mutagen 2's resistance by encumbrance | ALCH-13 (signed off) | `gm_alch.xml`, `damage/formula.ws` |
| The weights of the 193 items legacy added (Kaer Morhen set, dismantle kits, master kits, cooking recipes, schematics, ...) | ARM-12, CRAFT-09, ITEM-11, FOOD-07, CRAFT-04, ... (signed off) | each with its definition, legacy's weight |
| The inventory and dismantling screens refreshing the weight after a dismantle or repair (`UpdateEncumbranceInfo`) | CRAFT-09, ITEM-11 (signed off) | `craft/dismantleKits.ws`, `items/repair.ws` |
| The armor class's share of an action's stamina cost (`GMStaminaArmorPenalty`), in the wrapper WGT-07 joins | ARM-02 (signed off) | `armor/armorClass.ws` |

**Not WGT:**

| Subject | Area | Why |
|---|---|---|
| The three option entries (`GMSinkBoat`, `GMSinkBoatOverEnc`, `GMEncumbranceMultiplier`), their labels (2110992180, 181, 183), defaults and presets | OPT | The menu; WGT's slices add them through OPT-01's framework, as each feature adds its options when ported (DW3 on the boat's default) |
| The Wight trophy's +20 carry capacity (`wight_trophy_stats`) and the trophies' other bonuses, also in the abilities whose weight WGT-05 changes (`pig_contest_trophy_stats`, `q603_sharley_trophy_stats`) | TRPH | A trophy bonus; the trophies' weights are WGT-05's |
| `camm_trophy` losing its `Quest` tag; `FixQuestItems` (the `Quest` tag removed from keys, notes and masks no longer needed) | FIX (or TRPH) | Lets the items be sold or dropped; not weight |
| The NG+ Censer's icon tag (`UI_OilLamp` → `UI_Censer`, NG+ only) in the unit whose weight WGT-05 changes | UI (or ITEM) | A display fix carried by the same entry |
| `NGP Red Wolf Pants 2 _Stats`: legacy's NG+-only rewrite of the piece's stats (armor, resistances, attack power, toxicity, potion duration, spell power) besides its weight | ARM | Armor stats; WGT-03 takes the weight |
| The debug commands `addallgloves`, `addallboots`, `addallpants` (unattributed, found by the sweep) | ITEM or (none) | Debug item lists, no weight |

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
| WGT-02, WGT-07, WGT-08, WGT-10 to WGT-12 | None |
| WGT-03 to WGT-05 | No weight of an existing item; 175 new regular items (203 NG+) at 1.32's scale (DW2) |
| WGT-06 | No capacity or horse gear stat; the Fire Horse gear (Blood and Wine's Toussaint gear's stats) |
| WGT-09 | `CanCanter` also refuses while the horse pulls a cart |

### Classification and proposed action

| # | Feature | Class | Proposed action |
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
| Flags | balance, needs-decision |
| Depends on | WGT-03 to WGT-06 (the weights it counts; slice W4 comes after them, so the formula never meets 5.x's heavy ingredient weights) |
| Skill trees | n/a |
| Port form | `@replaceMethod(CInventoryComponent) GetItemEncumbrance` with legacy's formula (5.x's body is 1.32's), in a new `scripts/local/gm/weight/encumbrance.ws`; `IsItemEncumbranceItem` and `GetEncumbrance` stay 5.x's (DW1) |
| Port status | ported (slice W4, verified on the area build 2026-11-02: `GMTest_wgt04`) |
| Open checks | a real pick-up and the inventory's weight display. Answered by slice W1's probe: `GetItemWeight` is the item's own `weight` attribute when it has one above 0, and the two are never added (Blood and Wine's Toussaint Crossbow 1: item 1.53, ability 2.39, weighs 1.53; Fire Horse Saddlebags 1.56 and 1: 1.56); without one, its abilities' `<weight>` nodes are summed (the pig contest trophy: 5 + 0 to 5); it is per item (a stack of 10 reads the one item's weight) |
| Save impact | none (expected: the load is recomputed from the definitions at every `UpdateEncumbrance`) |
| NG+ counterpart | the same code |

**What it does** (changelist 924, 931; mod description section 4): every item Geralt carries counts its full weight, so ingredients, food, potions and books, weightless in vanilla, now fill the load, and gear counts twice what it did. The weights themselves were cut to match (WGT-03 to WGT-05): 100 Drowner brains weigh 10 (vanilla 0), a Swallow 0.1, a heavy chest 15–20 (vanilla 22.1 counted as 11). Every item weighs at least 0.01, so a stack of weightless items still counts; items the game excludes (recipes, schematics, bodies, items tagged `EncumbranceOff`) still weigh nothing.

**Implementation (legacy):** `CInventoryComponent.GetItemEncumbrance`: when the item counts (`IsItemEncumbranceItem`), max(`GetItemWeight`, 0.01) × quantity × (1 − `GetEncumbranceMult`), 0 below 0.01; the category rules are commented out; the debug fact `modSigns_debug_zero_enc` returns 0 (WGT-12). `GetTotalArmorWeight` (the four armor pieces' weight) is never called.

**5.x:** 1.32's formula. New: "Ignore Item Weight" makes `IsItemEncumbranceItem` false and `GetEncumbrance` 0 while on, so with legacy's formula the option still empties the load (DW1). The loot window shows 0 for quest items, ingredients and alchemy items (1.32's and legacy's rule; 5.x adds the option). The tooltip hides a weight of 0 (only `EncumbranceOff` items and recipes, under legacy's formula).

**Decisions:** legacy's formula (PW3); `GetTotalArmorWeight` not ported (never called). DW1 for 5.x's option.

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
| Port form | the reader in `weight/encumbrance.ws` (OPT-01's `GMGetOptionFloat('GMGameplayOptions', 'GMEncumbranceMultiplier')`, clamped to 0–100 %), the entry and its label (2110992183) added to the gameplay group in slice W4 through OPT-01 |
| Port status | ported (slice W4, verified on the area build 2026-11-02: `GMTest_wgt04`) |
| Open checks | the option changed in the menu updates the load at once (legacy: at the next `UpdateEncumbrance`) |
| Save impact | none |
| NG+ counterpart | — |

**What it does** (changelist 1232): a slider from 0 to 100% that lowers every item's counted weight by that share (50%: a 15 chest counts 7.5); 0 in every preset and by default.

**Implementation (legacy):** `W3GameParams.GetEncumbranceMult`; the term in `GetItemEncumbrance`.

**5.x:** nothing like it; "Ignore Item Weight" is the all-or-nothing 100% (DW1).

**Decisions:** legacy's (PW3). Whether a change in the menu should update the load at once is an improvement for later (legacy waits for the next update: a pick-up, a drop, an equip).

### WGT-03 Armor and weapon weights

| | |
|---|---|
| Kind | tuning |
| Pillars | P4, P6 |
| 5.x class | clean |
| Flags | balance |
| Depends on | ARM, SWD, AI, XBOW, ITEM (the same entries, written whole by their generators); WGT-01 (how they count) |
| Skill trees | n/a |
| Port form | `item_layer.py`: WGT owns the `<weight>` node of its ability units and the `weight` attribute of its item units (PW2); the generators that write those entries whole take legacy's weight (`gen_arm_items.py`, `gen_swd_items.py`, `gen_ai.py` with WGT in `PORTED`, `gen_xbow.py`, `gen_item.py`); the rest by `tools/gen_wgt.py` (PW4) |
| Port status | items' `weight` attribute ported (slice W1, verified on the area build 2026-11-02: `GMTest_wgtdata`); the abilities' nodes ported (slice W2, verified on the area build 2026-11-02); 5.x's new gear by DW2 (slice W3, verified on the area build 2026-11-02) |
| Open checks | — |
| Save impact | none (an item's weight is read from its definition: the 30 items of the test save, a 5.x save from before the mod, weigh and count what fresh copies do; WGT audit A1) |
| NG+ counterpart | legacy's NG+ weights (equal to its regular ones but `Gnomish silver sword 2_crafted` 3 in NG+, 5 regular, and the NG+-only `NGP` pieces), whole entries |

**What it does** (changelist 925–928): armor and swords are the heaviest things Geralt carries, by a fixed weight per class and slot rather than 1.32's scattered values. Armor (regular, by class): heavy chests 15–20 (Bear School 15 at every tier; 1.32 8.36–22.7), boots 10–12, gloves 5–8, trousers 5–8; medium chests 10–15 (Gryphon and Wolf 10), boots 4–5, gloves 3–3.5, trousers 3–4; light chests 5–9 (Lynx 5; 1.32 6.52–17.0), boots 2–3, gloves 1–2, trousers 1–2; shirts and suits 0.5–1. Swords: every witcher school steel sword 4 and silver sword 2 (1.32 2.35–6.9), relics 3–6 (Aerondight of Blood and Wine 5.7 → 3), generic steel swords mostly 8 (Nilfgaardian sword 1 6.2 → 8, Long Steel Sword 3.45 → 4, short swords 6), generic silver swords 4–6, secondary weapons (maces, axes, the shield) 6–12 (Knight Mace 1 4.05 → 8, `q302_Mace` 3.5 → 12), the standalone starts' gear 2–8. Crossbows 1.5–3 (witcher crossbows 1.5, Crossbow 1 1.53 → 2, the free DLC's crossbows 8 → 2), bolts 0.05 (0.1–0.4). In the regular files: 731 abilities (armor 402, swords and other weapons 312, the standalone starts' gear 12, crossbows 5) and 29 items (15 crossbows, 14 bolts).

**Implementation (legacy):** the `<weight>` node of the `_Stats` abilities in `def_item_armor*.xml`, `def_item_boots/gloves/pants.xml`, `def_item_crafting_armor/boots/gloves/pants/weapons.xml`, `def_item_weapons*.xml`, `def_item_npcweapons.xml`, `def_item_weapons_secondary.xml`, `def_item_ep1/ep2_stand_alone.xml`, the free DLCs' item files (`dlc1`, `dlc5`, `dlc10`, `dlc12`, `dlc13`, `dlc14`, `dlc15`), base game and both expansions, regular and NG+; the `weight` attribute of crossbow and bolt items (`def_item_weapons_crossbow(s).xml`, `def_item_bolts.xml`, Hearts of Stone's `q603_circus_crossbow`). Blood and Wine's two Toussaint crossbows have their weight moved from the ability (removed) to the item (2 and 3).

**5.x:** 1.32's weights on every existing piece; 5.x's new gear at 1.32's scale (DW2).

**Decisions:** legacy's (PW2, PW4); 5.x's new gear by DW2.

**Balance values:** the per-class weights are the reference for DW2 (Wolf: 10 / 4 / 3 / 3, witcher swords 4 and 2).

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
| Port status | items' `weight` attribute ported (slice W1, verified on the area build 2026-11-02: `GMTest_wgtdata`); the abilities' nodes ported (slice W2, verified on the area build 2026-11-02); 5.x's new gear by DW2 (slice W3, verified on the area build 2026-11-02) |
| Open checks | — (a potion weighs `default_potion_stats`' 0.1: slice W4's Swallow check, `GMTest_wgt04`) |
| Save impact | none (WGT audit A1) |
| NG+ counterpart | legacy's NG+ weights (equal to the regular ones), whole entries |

**What it does** (changelist 929–930; mod description: "Ingredients having zero weight take it even further as you can loot virtually everything"): alchemy items and ingredients now count, at small weights. Potions, decoctions, oils and bombs weigh 0.1 each (1.32: 0; they share `default_potion_stats`, `ClearingPotion_stats`, `RestoringPotion_stats`, `default_oil_stats`, `default_bomb_stats`), mutagens 0.1 (1.32: 1, `CommonMutagenAbility`); alchemy ingredients mostly 0.05 (109 of 153: Nekker eye 0.7 → 0.05, Water essence 1.0 → 0.05, herbs 0.1 → 0.05) or 0.1 (Drowner brain 0.7 → 0.1, Dwarven spirit 1.0 → 0.1, Alcohest 0.8 → 0.1), a few 0.2 (Wyvern egg); crafting materials by bulk: monster hides and plates 1.1–1.5 (Monstrous hide 4.3 → 1.1, Wyvern plate 10.1 → 1.25, Czart hide 8.8 → 1.5), ingots 0.4–0.6 and plates 0.8–1.4 (Steel ingot 1.5 → 0.5, Dwimeryte plate 5.0 → 1.2), leather 0.5–1.4, ores 0.2–0.3, cloth 0.06–0.15, gems' dust 0.01; runes and glyphs 0.06 / 0.12 / 0.24 by grade (1.32 0.05 / 0.1 / 0.2; Hearts of Stone's 0.1 → 0.06); repair kits 0.1–0.6 (Weapon repair kit 1 0.5 → 0.1, Armor repair kit 3 1.4 → 0.6; the two kits' shared default abilities lose their 0.1); schematics 0.1 (Hearts of Stone's rune and glyph schematics; recipes and schematics never count, so this is inert). In the regular files: 283 items (alchemy ingredients 153, crafting ingredients 106, upgrades 14, schematics 10) and 20 abilities.

**Implementation (legacy):** `def_item_ingredients.xml`, `def_item_herbs.xml`, `def_item_upgrades.xml`, Hearts of Stone's `def_item_ep1_upgrades.xml` and `def_item_ep1_crafting_recipes.xml`, `def_item_alchemy_potion/oils/petards/mutagens.xml`, `def_item_alchemy_repair_kits.xml`, `def_item_misc.xml` (the kits' abilities); base game and both expansions, regular and NG+.

**5.x:** 1.32's weights; 5.x's two new potions (Reinald's Philtre, Signs Enhancement) carry `default_potion_stats`, so they take legacy's 0.1 with it (if the weights sum, slice W1).

**Decisions:** legacy's (PW2, PW4), the inert schematic weights included (PW4).

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
| Port status | items' `weight` attribute and the three `EncumbranceOff` changes ported (slice W1, verified on the area build 2026-11-02: `GMTest_wgtdata`; the razor's 0.3 by hand in `gm_ui.xml`); the abilities' nodes ported (slice W2, verified on the area build 2026-11-02); 5.x's new gear by DW2 (slice W3, verified on the area build 2026-11-02) |
| Open checks | — |
| Save impact | none (WGT audit A1) |
| NG+ counterpart | legacy's NG+ weights, whole entries |

**What it does** (changelist 924, 931): everything else gets a small weight that now counts: food and drink 0.05 or 0.1 (Bread 0.6 → 0.05, Fish 0.85 → 0.05, Pork 0.8 → 0.1, Beauclair White 1.0 → 0.1; 1.32 counts none of them); keys 0.05 (89 keys, 0.1); notes and letters 0.05 (`Default Note _Stats` 0.1 → 0.05, 61 base-game notices), books 0.2 (`Default Book _Stats` 0.5); junk by bulk (pelts and hides 0.4–1.1: Cow hide 4.6 → 0.6, Bear pelt 3.7 → 1.1; gems 0.05; Gold ore 1.0 → 0.1; 45 junk items at 0.05); Blood and Wine's 22 paintings and junk items 0.1 (20 of them weightless in 1.32) and its 23 notices 0.05 (0.1); torches and lamps 0.2 (0.5–0.9), quest items 0.05–0.2 (`q103_bell` 1 → 0.1, Potestaquisitor 0.64 → 0.1, the Censer 0.9 → 0.2); trophies 5 (`base_trophy_stats` 2 → 5, Hearts of Stone's two quest trophies' own abilities too); Shani's alcohols 0.1 and flowers 0.05 (0.5); the razor 0.3 (0.85). The Nilfgaardian florens and Redanian orens get `EncumbranceOff` (coins weigh nothing), and Hearts of Stone's pig contest trophy loses it (it weighs 5, like the other trophies). Wolf liver, which legacy moved from the ingredients to the food, weighs 0.1 (5.x 0.9; the port's FOOD entry has 5.x's). In the regular files: 471 items (junk 158, misc 120, food and drink 90, keys 89, usable 14) and 8 abilities.

**Implementation (legacy):** `def_item_edibles.xml`, `def_item_junk.xml`, `def_item_keys.xml`, `def_item_notices.xml`, `def_item_books.xml`, `def_item_misc.xml`, `def_item_quest.xml`, `def_item_trophies.xml`, `def_item_ingredients.xml` (the razor) and the free DLC's `def_item_dlc15_items.xml` (three quest items given 0.1); base game and both expansions, regular and NG+.

**5.x:** 1.32's weights; 5.x's new quest notes have none (they count 0.01 under WGT-01, as legacy's own weightless quest items do).

**Decisions:** legacy's (PW2, PW4). The trophies' weights go now, their bonuses with TRPH.

### WGT-06 Saddlebags and horse gear

| | |
|---|---|
| Kind | tuning |
| Pillars | P6 |
| 5.x class | clean |
| Flags | balance |
| Depends on | ECON-01 (the same items' prices, ported), WGT-01 |
| Skill trees | n/a |
| Port form | the items' `weight` through `item_layer.py` (`gen_econ.py`'s entries); the bag, blinder and horse abilities by `gen_wgt.py` (`extend` with the changed node for the base game's and Blood and Wine's; Hearts of Stone's and NG+ whole; the free DLCs' whole unless probed, PW4) |
| Port status | items' `weight` attribute ported (slice W1, verified on the area build 2026-11-02: `GMTest_wgtdata`); the abilities' nodes ported (slice W2, verified on the area build 2026-11-02); 5.x's new gear by DW2 (slice W3, verified on the area build 2026-11-02) |
| Open checks | a real gallop with the panic resistance (the capacity per bag is checked by slice W2's `GMTest_wgt_bags`) |
| Save impact | none (the horse's abilities come from the equipped item's definition; WGT audit A1) |
| NG+ counterpart | legacy's NG+ values, whole entries |

**What it does** (undocumented beyond the changelist's "Saddlebags"): saddlebags add a steadier capacity: the base game's three bags +40 / +60 / +80 (1.32 +30 / +70 / +100: the first bag better, the best one worse), Blood and Wine's Toussaint bag +100 (+110), Hearts of Stone's Ofir bag +90 (+100), the free DLCs' Temerian, Nilfgaardian and Skellige bags +40 / +60 / +80 (+30 / +70 / +100); so Geralt carries 100 / 120 / 140 with the base game's bags (1.32: 90 / 130 / 160), plus Strong Back's 40. Horse gear weighs less when carried: the base game's saddles 5–11 (10–17), bags 1–1.2 (2.5–3.5), blinders 0.3 (0.4); the free DLCs' saddles 5.5–10.5, bags 1–1.2 and blinders 0.1–0.3 (the Temerian set 17, 3.2, 0.4; the Nilfgaardian and Skellige sets weightless in 1.32); Blood and Wine's and Hearts of Stone's horse gear keeps 1.32's weights. Two blinders resist panic better (Toussaint 60 → 75, Ofir 55 → 70), and the base horse's sprint costs more stamina (`HorseLevel1` 5 → 7.5) (PW9).

**Implementation (legacy):** `def_item_horse.xml` (base game, Blood and Wine, Hearts of Stone), `dlc1_items.xml`, `dlc5_items.xml`, `dlc14_items.xml`: the bag abilities' `encumbrance`, the blinders' `panic`, `HorseLevel1`'s `sprint_stamina_cost`, the items' `weight`.

**5.x:** 1.32's; the Fire Horse gear copies Blood and Wine's Toussaint gear's stats (bag +110 is the Toussaint bag's 1.32 value; DW2).

**Decisions:** legacy's (PW2, PW9).

### WGT-07 Overencumbrance stamina penalty

| | |
|---|---|
| Kind | system |
| Pillars | P2, P6 |
| 5.x class | clean |
| Flags | balance |
| Depends on | ARM-02 (the wrapper whose factor it joins, signed off), STAM-03 (the cost functions, signed off), WGT-01 |
| Skill trees | n/a (the cost is the action's, whatever skill; Whirl and Rend have their own costs, STAM-09) |
| Port form | `GMOverEncumbrancePenalty()` in `weight/encumbrance.ws`; ARM-02's wrapper in `armor/armorClass.ws` changed from `cost × (1 + armor)` to `cost × (1 + armor + overencumbrance)` for melee and agility actions (PW5) |
| Port status | ported (slice W5), **verified** (2026-11-02; with the armor classes, attacks, the jump and the exclusions since the WGT audit's F2, in `GMTest_wgt05`) |
| Open checks | a real dodge and sprint while overburdened |
| Save impact | none |
| NG+ counterpart | the same code |

**What it does** (changelist 933; mod description: "being over encumbered adds severe penalties to sprinting, rolling and dodging actions, depending on how big your over encumbrance is"): while overburdened, every melee and agility action (light and heavy attacks, parries, counters, dodges, rolls, sprinting, jumping; not signs, not usable items) costs more by the share Geralt is over his limit, capped at double: 10% over, +10%; 50% over, +50%. The share adds to the armor class's (heavy armor +50% and 30% over: × 1.8; no armor −50% and 30% over: × 0.8).

**Implementation (legacy):** `W3PlayerAbilityManager.CalcStaminaOverEncumbrancePenalty` (with `EET_OverEncumbered`: clamp(load ÷ capacity − 1, 0, 1)), added to `CalcStaminaArmorPenalty` in `GetStaminaActionCost`'s melee branch: `cost *= 1 + penalty`.

**5.x:** nothing like it.

**Decisions:** legacy's (PW5): the port's ARM-02 multiplies the class term on its own (ARM's hand-off), so WGT-07 joins its term to that factor, as legacy.

### WGT-08 No fast travel while overburdened

| | |
|---|---|
| Kind | system |
| Pillars | P6 |
| 5.x class | clean |
| Flags | — |
| Depends on | — |
| Skill trees | n/a |
| Port form | scope-based override or `@wrapMethod` of `W3Effect_OverEncumbered.OnEffectAdded`/`OnEffectRemoved` (events: wrapped as STAM's were) adding `BlockAction(EIAB_FastTravel, 'OverEncumbered')`, in `weight/overEncumbered.ws` |
| Port status | ported (slice W5, verified on the area build 2026-11-02) |
| Open checks | the map's signposts refuse travel (a real attempt on screen; by script: `IsActionAllowed(EIAB_FastTravel)`) |
| Save impact | none with the mod installed at the start (the block comes and goes with the effect, and action locks are saved with the player); a save made overburdened before the mod gets the block only when Geralt next becomes overburdened: a load restores the effect without `OnEffectAdded`, and `UpdateEncumbrance` adds the effect only when it is missing (WGT audit F3) |
| NG+ counterpart | — |

**What it does** (changelist 932): while overburdened, fast travel is refused (`EIAB_FastTravel` blocked, as vanilla blocks it in combat).

**Implementation (legacy):** two lines in `W3Effect_OverEncumbered`.

**5.x:** 1.32's effect; the map refuses fast travel while the action is blocked (to check on screen).

**Decisions:** legacy's (PW6).

### WGT-09 No canter or gallop while overburdened

| | |
|---|---|
| Kind | system |
| Pillars | P6 |
| 5.x class | clean |
| Flags | — |
| Depends on | — |
| Skill trees | n/a |
| Port form | `@wrapMethod(W3HorseComponentStateExploration) CanCanter`: `wrappedMethod() && thePlayer.IsActionAllowed(EIAB_RunAndSprint)` (5.x's cart test kept), in `weight/overEncumbered.ws` |
| Port status | ported (slice W5), **verified** by script (WGT audit F2: Roach's own `CanCanter` follows the load, in `GMTest_wgt05`, both trees); the gait on screen not seen |
| Open checks | a real ride overburdened (Roach trots at most) |
| Save impact | none |
| NG+ counterpart | — |

**What it does** (changelist 932): while Geralt cannot sprint, Roach cannot canter or gallop (`OnCanGallop` also asks `CanCanter`). The rule tests the sprint block, not the encumbrance, so whatever else blocks Geralt's sprint (scenes, some quest areas, being on a boat) also holds Roach to a trot; whether that ever showed in legacy is on the [legacy test list](../open-questions.md#to-test-in-legacy-ghost-mode).

**Implementation (legacy):** `CanCanter` returns false unless `EIAB_RunAndSprint` is allowed.

**5.x:** `CanCanter` also refuses while the horse pulls a cart.

**Decisions:** legacy's rule on 5.x's body (PW6).

### WGT-10 Sinking boats

| | |
|---|---|
| Kind | system |
| Pillars | P6 |
| 5.x class | clean |
| Flags | needs-decision (DW3) |
| Depends on | OPT-01 (two entries, the defaults) |
| Skill trees | n/a |
| Port form | `@wrapMethod(W3Boat) OnAreaEnter`, or a scope-based override with 5.x's body and legacy's lines, in `weight/boat.ws`; `CheckPlayerEncumbrance` as an `@addMethod`; the readers through OPT-01; the string 2110992179 (`gm_geralt_too_heavy`) in nine languages; the two entries and labels (2110992180, 181) in the gameplay group |
| Port status | ported (slice W6, verified on the area build 2026-11-02 up to the sinking itself: open check) |
| Open checks | a real boarding overburdened (the boat sinks, the sound and the message); none after a save load on a boat (`GetLoadGameProgress`); boats that cannot be destroyed (quest boats) do not sink |
| Save impact | none (a boat already sunk stays sunk: 1.32's `HasDrowned`) |
| NG+ counterpart | — |

**What it does** (changelist 934–935, 1229–1231): when Geralt steps onto a boat while overburdened by more than the threshold (20% by default: carrying 145 with a 120 limit), the boat sinks under him (`TriggerDrowning`, the sinking sound) with "Your over encumbrance is too high"; boats that cannot be destroyed, and the boat he stands on as a save loads, are spared. "Sink the boat if overencumbered" turns it on or off, "Overencumbrance threshold to sink the boat (%)" sets the threshold (0 to 100).

**Implementation (legacy):** `W3Boat.OnAreaEnter` (the `OnBoatTrigger` branch), `W3Boat.CheckPlayerEncumbrance`, `W3GameParams.GetBoatSinkOption`, `GetBoatSinkOverEncumbranceOption`; defaults in `gmLoadDefaultSettings` (on, 20) and the presets ("Recommended" on and 20, the other two off and 0).

**5.x:** 1.32's `OnAreaEnter`, but the rule's test whether the boat can be destroyed (`GetCanBeDestroyed`) also reads 5.x's accessibility option "Unlimited Boat Durability" (`Accessibility`/`DisableDurabilityBoat`, also set by the "Bard's Ballad" preset): with it on, no boat sinks under Geralt, however overburdened (WGT audit F1).

**Decisions:** legacy's (PW7); the default, which the code and the changelist give differently, by DW3. 5.x's "Unlimited Boat Durability" keeps boats afloat, as the player's choice: an accessibility option off by default, like "Ignore Item Weight" (DW1); not a deviation, content legacy never had (owner, WGT audit F1, 2026-11-02).

### WGT-11 Encumbrance after a knockout (fix)

| | |
|---|---|
| Kind | fix |
| Pillars | P8 |
| 5.x class | clean |
| Flags | — |
| Depends on | DIFF-07 (the knockout and the guards' toll, signed off; its hand-off) |
| Skill trees | n/a |
| Port form | `@wrapMethod(CR4PlayerStateUnconscious) OnLeaveState`: after 5.x's body, `UpdateEncumbrance()` for Geralt, in `weight/overEncumbered.ws` |
| Port status | ported (slice W5, verified on the area build 2026-11-02) |
| Open checks | — |
| Save impact | none |
| NG+ counterpart | — |

**What it does** (not in the changelist): when Geralt comes to after being knocked out (a lost fist fight, the guards' toll), his load is recounted, so a change made while he was down (items or money taken) shows at once.

**Implementation (legacy):** one line in `OnLeaveState` (`//modSigns`). Found by DIFF's slice D4, handed to WGT (porter's call, confirmed by the owner, 2026-10-31).

**5.x:** 1.32's state.

**Decisions:** legacy's (PW6).

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
| Port status | not started (not to be ported, PW8) |
| Save impact | — |
| NG+ counterpart | — |

**What it does:** debug only. `togglezeroenc` sets or clears the fact `modSigns_debug_zero_enc`, which makes every item weigh 0 in `GetItemEncumbrance`.

**5.x:** the vanilla command `mule()` (`EncumbranceBoy`, the fact `DEBUG_EncumbranceBoy`) keeps the overburdened effect off, and "Ignore Item Weight" empties the load.

**Decisions:** not ported (PW8).

---

### Dependencies on other areas

- **Done areas WGT builds on:** the item layer (`item_layer.py`) and the item generators of ARM, SWD, ITEM, CRAFT, FOOD, ALCH, XBOW, AI, ENCH and ECON (the entries carrying the weights); `gen_econ.py`'s short `extend` entries; ARM-02's stamina wrapper; OPT-01's menu framework; DIFF-07's knockout.
- **Areas WGT shares with or waits for:** OPT (the three entries and their defaults: DW3), TRPH (the trophies: weights WGT's, bonuses TRPH's, the Wight trophy's capacity TRPH's), HORSE (not mapped; PW9 takes the horse gear's two other stats).

### Hand-offs received

| From | Item | WGT |
|---|---|---|
| ALCH (hand-off) | Alchemy item weights (`default_potion_stats`, `ClearingPotion_stats`, `RestoringPotion_stats`, `default_oil_stats`, `default_bomb_stats`, `CommonMutagenAbility`; potions, oils, bombs 0 → 0.1, mutagens 1 → 0.1) | WGT-04 |
| ARM (hand-off) | Armor weights (425 abilities); Scarlet Crest's 8.2 (DA4); the overencumbrance term added to the class term (`1 + armor + overencumbrance`) | WGT-03; DW2 (Scarlet Crest); WGT-07 (PW5) |
| SWD (hand-off) | Sword weights (every sword ability) | WGT-03 |
| AI (hand-off, `LATER`) | 21 weapon abilities with a weight change (Knight Mace 1 and 2 among them), `gen_ai.py`'s `LATER` `weight` | WGT-03 (WGT into `gen_ai.py`'s `PORTED`) |
| XBOW (hand-off) | Bolts 0.05, crossbows (items and the Toussaint, DLC13 and Ofir abilities' nodes) | WGT-03 |
| CRAFT (hand-off) | Weights of items, kits, ingredients and herbs; the rune and glyph schematics' weights | WGT-04, WGT-05 |
| FOOD (hand-off) | Food and drink weights (23 base and 2 Blood and Wine items changed only in weight or price; the Shani alcohols and flowers) | WGT-05 |
| ITEM (hand-off) | Kit weights (`def_item_misc.xml`'s repair kit abilities included) | WGT-04 |
| ENCH (hand-off) | Rune and glyph weights | WGT-04 |
| UI (hand-off) | The boat message (2110992179) and `W3Boat.OnAreaEnter`; the razor's weight (0.85 → 0.3) | WGT-10; WGT-05 (by hand in `gm_ui.xml`, PW2) |
| ECON (hand-off) | The 40 Blood and Wine paintings and other junk; every weight-only unit left unattributed (about 580) | WGT-05; all placed (568 newly attributed) |
| STAM (hand-off) | `CalcStaminaOverEncumbrancePenalty` | WGT-07 |
| EFX (hand-off) | `W3Effect_OverEncumbered` (no fast travel), the boat sinking (`W3Boat`) | WGT-08, WGT-10 |
| DIFF (hand-off, slice D4) | `CR4PlayerStateUnconscious.OnLeaveState`'s encumbrance update | WGT-11 |
| SKL (dependency) | Strong Back's weight | Ported by SKL-18 (+40 in both trees); nothing left |

**Temporary deviations "until WGT"** ([deviations.md](deviations.md)): none recorded. The 5.x weights other areas' generators keep (`NOT_ARM`, `NOT_SWD`, `SWD10_KEEP`, `gen_ai.py`'s `LATER`, `gen_xbow.py`, `gen_alch.py`, `gen_food.py`) are noted as WGT's, not as deviations.

### Hand-off to other areas

| Area | Changes |
|---|---|
| OPT | The gameplay group's `GMSinkBoat`, `GMSinkBoatOverEnc`, `GMEncumbranceMultiplier`: entries, labels (2110992180, 181, 183), defaults (code: on, 20, 0) and presets (DW3) |
| TRPH | `wight_trophy_stats`'s +20 carry capacity (unattributed); the bonuses in the trophy abilities WGT-05 shares (`pig_contest_trophy_stats`, `q603_sharley_trophy_stats`) |
| ARM | `NGP Red Wolf Pants 2 _Stats`'s NG+-only stats (WGT-03 takes its weight); the port's NG+ Kaer Morhen pieces name 16 `Base Kaer Morhen … _Stats` abilities that the DLC's `items_plus` never defines (see below) |
| FIX (or TRPH) | `camm_trophy`'s `Quest` tag removed (unattributed), with `FixQuestItems` |
| UI (or ITEM) | The NG+ Censer's `UI_Censer` tag (WGT-05 carries its weight) |
| HORSE | None: PW9 takes the blinders' panic and the base horse's sprint cost into WGT-06 (the alternative: HORSE, unmapped) |
| ITEM | `Body palms cut` (Hearts of Stone's NG+ `def_item_misc.xml`): legacy added the missing NG+ definition that NG+'s armour variants name; a Body item, never counted, so not WGT's; attributed to ITEM-01 as not ported, for ITEM (WGT audit F6) |
| AI (note) | Hearts of Stone's `Shovel _Stats` (both folders), whose weight 8 legacy removed when the Caretaker got his own `Caretaker Shovel _Stats`: attributed to AI-19 as not ported (the base game defines the same name; no play effect expected; WGT audit F4) |
| CRAFT (note) | CRAFT-08's whole entries of Blood and Wine's `poi_gor_d_06_note` and `poi_gor_d_06_note03` make them misc items weighing 0.01 (the copy legacy changed), and six Hearts of Stone notes take the second copy's icon; accepted by the owner (WGT audit F5) |

### Surprises for other areas

- **ARM-12, NG+:** legacy's NG+ Kaer Morhen pieces (`NGP Kaer Morhen Armor` and its 15 siblings) use `Base Kaer Morhen Armor _Stats` and 15 other `Base …` abilities that legacy defines only in `items_plus/def_item_crafting_*.xml`; the port's `items_plus/gm_arm_kaer_morhen.xml` names them but defines none, so in NG+ those pieces would lack their base stats (found by WGT's weight check of legacy's new items; NG+ untested by policy).
- **FOOD-04 / CRAFT-07:** Wolf liver's food entry in `gm_item.xml` has 5.x's weight 0.9 (legacy 0.1); WGT-05 takes it.

### Save impact

None expected: weights, capacities and the horse gear's stats are read from the definitions (to confirm on items and a bag the test save holds, slices W1 and W2); the load is recomputed at every `UpdateEncumbrance` (a pick-up, a drop, an equip, a load); the fast-travel block comes with the overburdened effect, re-added when the load is next recomputed. The mod is installed at the start of a playthrough ([save compatibility](../feature-mapping.md#save-compatibility)).

### Area decisions

**Decided by the owner (2026-11-02): every recommendation.** DW1 (a) 5.x's "Ignore Item Weight" kept as it is; DW2 (b) 5.x's new gear at the legacy weights of ECON's DE2 counterparts; DW3 (a) boats sink by default at 20% (the same decision as OPT's DO3). Porter's calls PW1 to PW10 confirmed.

| # | Question | Options | Recommendation |
|---|---|---|---|
| DW1 | 5.x's accessibility option "Ignore Item Weight" (WGT-01). Legacy had nothing like it; in 5.x, when the player turns it on (or picks the "Bard's Ballad" preset), nothing counts towards the load, so Geralt is never overburdened and WGT-07 to WGT-10 never trigger; off, Ghost Mode's weights apply. Legacy's own "Reduce item encumbrance" at 100% has the same effect | (a) keep 5.x's option working as it is (off by default; the player's explicit choice); (b) neutralise it while Ghost Mode is installed (a wrapper returning false for it in `IsItemEncumbranceItem` and `GetEncumbrance`), so weights always count; (c) keep it and also hide it, leaving only Ghost Mode's slider | **(a)**: an accessibility option the player sets on purpose, off by default, so the default game is legacy's; neutralising a visible option would make it lie. Not a deviation: content legacy never had (as ECON's PE12 kept 5.x's "Sell Junk") |
| DW2 | The weights of 5.x's new gear (WGT-03, WGT-06). 5.x added gear at 1.32's scattered weights, among legacy's per-class ones: Netflix Armor 7.32 / 8.57 / 11.56 (legacy's Wolf Armor, the set it copies: 10 at every tier), Netflix steel swords 4.64–4.81 (Wolf 4), Netflix silver swords 4.3–4.8 (Wolf 2), Scarlet Crest's four pieces 4.77 / 1.2 / 0.9 / 1.33 (8.2 in all; a medium set in legacy weighs 10–15 / 4 / 3 / 3), Dol Blathanna and White Tiger 9.52 / 3.4 / 3.6 / 2.7, the Vixen swords 5.8 and 4.8, Top Notch 3.2 and 2.05, Heavy armor 03 Netflix 26.92 (Heavy armor 03: 20.32 → 20), the Fire Horse saddle 6.01, bag 1.56 + 1, blinders 0.2 (Blood and Wine's Toussaint gear they copy: 10, 2.5, 0.4, which legacy left as 1.32's) | (a) 5.x's weights as they are; (b) by analogy: each piece at the legacy weight of the counterpart ECON's DE2 gave it (Netflix 10 / 4 / 3 / 3 and swords 4 and 2; Dol Blathanna and White Tiger 15 / 4.5 / 3.5 / 3.5; Scarlet Crest 15 / 5 / 2 / 3; the Vixen and Dol Blathanna swords 6 and 4; Top Notch 6 and 4; Heavy armor 03 Netflix 20, Heavy gloves 04 Netflix 8), and 5.x's own weight where legacy left the counterpart's at 1.32's (the Fire Horse gear); potions take `default_potion_stats`'s 0.1 by themselves; quest items and cosmetics 5.x's; (c) by class only: legacy's most common weight for the piece's class and slot (medium 10 / 4 / 3 / 3 for every medium set) | **(b)**: the counterparts are already chosen and confirmed for prices (DE2), and legacy's weights are per class, so the new gear weighs what its peers weigh (otherwise Scarlet Crest, a medium set, weighs 8.2 where every legacy medium set weighs 20–25 and counts twice what it did); same reasoning as DE2. Not a deviation: content legacy never had |
| DW3 | Whether boats sink by default (WGT-10; the default is set by OPT). The changelist says "off by default, can be tweaked in options"; legacy's code turns it on (20%) for a new install (`gmLoadDefaultSettings`) and in the "Recommended" preset, and the options text says the recommended preset "enables boat sinking". A contradiction between the changelist and the code | (a) the code: on, 20%, as `gmLoadDefaultSettings` and "Recommended"; (b) the changelist: off by default, 20% when turned on | **(a)**: the code is the better guide where they differ (feature-mapping's rule), and the preset text agrees with it; a contradiction, so it goes to the owner and the legacy test list. Not a deviation under (a); (b) would be one |

### Porter's calls

To confirm by the project owner; each follows legacy or has no play effect.

| # | Call |
|---|---|
| PW1 | WGT is ported as one area with one audit at the end, about 3,300 units, in the slices of the [port order](#port-order) |
| PW2 | **The form of the data:** `item_layer.py` gives WGT the `weight` attribute of its item units (`ATTRS`), the `<weight>` and `encumbrance` nodes, and the two horse stats, of its ability units (`NODES`, with `owns()`'s `"*"` still excluding the weight for other features), and the `EncumbranceOff` tag of its three items (`TAGS`); WGT's fields alone never make a tool write an entry whole (`item_layer.WHOLE`, as ECON's). Whichever generator already writes an entry whole applies them: `gen_item.py` (`gm_item.xml`: 454 regular items and 7 kit abilities), `gen_arm_items.py` (`gm_arm_items.xml`: 409 regular abilities, its `NOT_ARM` weight switched to WGT's when ported), `gen_swd_items.py` (`gm_swd_items.xml`: 256, `NOT_SWD`), `gen_ai.py` (`gm_ai_weapons.xml`: 21, WGT into `PORTED`), `gen_xbow.py` (`gm_xbow.xml`: 7), `gen_ench.py` (2 Hearts of Stone runes), `gen_econ.py` (149 items: 139 `extend` entries, which take the `weight` attribute next to the price, and 10 Hearts of Stone entries whole); the razor's hand-written entry in `gm_ui.xml` takes legacy's 0.3 by hand (as ECON's price) |
| PW3 | WGT-01 and WGT-02: legacy's `GetItemEncumbrance` as a `@replaceMethod`, its reduction read through OPT-01 (default 0); `IsItemEncumbranceItem` and `GetEncumbrance` stay 5.x's, so DW1 (a) needs no code |
| PW4 | **The entries no generator writes** (203 regular items, 59 regular abilities, and their NG+ twins) by a new `tools/gen_wgt.py`: items through `gen_econ.py`'s writer extended to WGT's units (one entry per name: an item with a price and a weight change gets one `extend` entry with both); abilities in `items/gm_wgt.xml` as `extend` entries with the `<weight>` node only for the base game's and Blood and Wine's, whole (`replace`) for Hearts of Stone's (`extend` empties them), the free DLCs' (not probed for abilities) and the abilities losing their weight node (the two repair kits' default abilities; a removal cannot be an `extend`); every NG+ entry whole (`items_plus`, as ECON's PE2); with `--check`, `--verify` (every WGT unit's weight as the game reads it, DLC over 5.x, against legacy's, both folders) and an in-game data test of every regular unit's weight read through the definitions. The inert schematic weights are ported with the rest (legacy's data; no play effect) |
| PW5 | WGT-07: the overencumbrance term added to ARM-02's factor (`1 + armor + overencumbrance`), as legacy, instead of a second factor: ARM-02's wrapper in `armor/armorClass.ws` takes the term (a change to a signed-off feature's code, recorded there) |
| PW6 | WGT-08, WGT-09, WGT-11: legacy's lines in wrappers of 5.x's functions (the fast-travel block in the effect's two events, the sprint test after 5.x's cart test in `CanCanter`, the update after `OnLeaveState`) |
| PW7 | WGT-10: legacy's boat rule in a wrapper or override of `W3Boat.OnAreaEnter` (5.x's body is 1.32's), its message (2110992179, nine languages) and the two entries (OPT's, with DW3's default) |
| PW8 | WGT-12: the debug command is not ported (debug only; 5.x's `mule()` and the tests' own setters do its work); `GetTotalArmorWeight` is not ported (never called) |
| PW9 | WGT-06 takes the horse gear's two undocumented changes that are not weight (Toussaint and Ofir blinders' panic 60 → 75 and 55 → 70, the base horse's sprint cost 5 → 7.5): they sit in the same horse entries, and HORSE (horse combat) is not mapped. The alternative: leave them unattributed for HORSE |
| PW10 | NG+: legacy's NG+ weights and capacities as written (they equal the regular ones but one sword, `Gnomish silver sword 2_crafted`, 3 against 5; legacy behaviour first), in whole entries; untested, as every NG+ change |

### Port order

Each slice compiles and is verified on its own by script (the regression in both trees; skills are not involved, so the per-tree checks are the regression's). Data before the formula: until slice W4 the game counts weights by 5.x's rule, so legacy's light ingredient weights never meet a full count of 5.x's heavy ones. One audit after the last (PW1).

| # | Slice | Verified by |
|---|---|---|
| W1 | **Probe and item weights** (done: verified on the area build, 2026-11-02) (WGT-03 to WGT-06, the items' `weight` attribute and tags): first a probe on the current port: `GetItemWeight` and `GetItemEncumbrance` of items with only an item weight (a Drowner brain, a key), only ability weights (a sword, an armor piece) and both (Blood and Wine's Toussaint crossbow, a potion with `default_potion_stats` and its own 0), to learn how the native weight combines them; an `extend` entry with only `weight="…"` on a base-game item. Then `item_layer.py`'s WGT fields for items, `gen_econ.py`'s writer for WGT's units, the generators' re-runs | The probe's answers recorded in development.md; a data test of every regular WGT item unit's weight through the definitions; the coins weightless, the pig trophy weighted (`IsItemEncumbranceItem` on spawned items) |
| W2 | **Ability weights and capacities** (done: verified on the area build, 2026-11-02) (WGT-03 to WGT-06, the `<weight>`, `encumbrance`, `panic` and `sprint_stamina_cost` nodes): the generators' switches (`NOT_ARM`, `NOT_SWD`, `gen_ai.py`'s `PORTED`, `gen_xbow.py`), `item_layer.NODES`, `tools/gen_wgt.py` for the rest; NG+ whole | The data test extended to every regular ability unit; `GetMaxRunEncumbrance` with each of the three base-game bags equipped on a spawned horse (60 + 40/60/80); a horse's panic resistance with Toussaint blinders |
| W3 | **5.x's new items** (DW2; done: verified on the area build, 2026-11-02): the counterparts' weights as `item_layer` fields that `gen_arm_new.py`, `gen_swd_items.py` and `gen_wgt.py` apply | The data test with the new items; `--verify` recomputes each from its counterpart |
| W4 | **The formula and the option** (WGT-01, WGT-02; done: verified on the area build, 2026-11-02): `weight/encumbrance.ws`, OPT-01's entry and label | Spawned stacks counted by `GetItemEncumbrance` against the definitions (100 Drowner brains 10, a Bear Armor 1 15, a key 0.05, a schematic 0); the option at 50% halves them; "Ignore Item Weight" on gives 0 (DW1); `GetEncumbrance` of the test save's inventory before and after |
| W5 | **Overburdened** (WGT-07, WGT-08, WGT-09, WGT-11; done: verified on the area build, 2026-11-02, the gallop an open check): the cost term in ARM-02's wrapper, the effect's block, `CanCanter`, the knockout's update | Overburdened by spawned weights: a dodge's and a sprint's cost read through `GetStaminaActionCost` at 0%, 20% and 120% over, with and without heavy armor (× (1 + armor + share)); `IsActionAllowed(EIAB_FastTravel)` false and back true after a drop; `CanCanter` through the horse state on a spawned, mounted horse (or the open check); `UpdateEncumbrance` after a scripted knockout (DIFF-07's test path) |
| W6 | **Boats** (WGT-10; done: verified on the area build, 2026-11-02, the sinking itself an open check): `weight/boat.ws`, the message, the two entries with DW3's default | `CheckPlayerEncumbrance` at 10% and 30% over with the threshold 20; the option off; a real boarding needs a boat by the test save (open check, as ECON's scenes) |

**Generator work:** `item_layer.py`'s WGT fields (W1, W2) and the counterparts (W3); `gen_econ.py`'s writer for WGT's item units (W1); `tools/gen_wgt.py` (W2) with `--check`, `--verify` and the data test `tests/gmTestsWgtData.ws`; the switches in `gen_arm_items.py`, `gen_swd_items.py`, `gen_ai.py`, `gen_xbow.py`; `gen_arm_new.py` and `gen_swd_items.py`'s `SWD10_KEEP` for DW2.

**Later:** the loot window showing each item's weight (WGT-01); the load recomputed when the reduction option changes (WGT-02).

### Slice W1 (2026-11-02)

- **The probe** (`gmtest_wgt_probe()`, `tests/gmTestsWgtProbe.ws`, on items spawned into Geralt's and the horse manager's inventories, both alike): `GetItemWeight` is the item's own `weight` attribute when it has one above 0, else its abilities' `<weight>` nodes (Long Steel Sword 3.45, Bear Armor 8.36 from the ability; Drowner brain 0.7, a key 0.1, Rune svarog 0.1 from the item); with both, the item's wins (Toussaint Crossbow 1: 1.53, not 1.53 + 2.39; Fire Horse Saddlebags 1.56, not 1.56 + 1); per item, whatever the stack. `GetItemAttributeValue(id, 'weight')` and the definitions' `GetItemAttributeValueNoRandom` read the abilities' nodes only. A `mult` weight node alone (NPC `Spear 1`: base 0, mult 1) weighs 0. So legacy's move of the Toussaint crossbows' weight from the ability to the item changes nothing the game reads beyond the item's own value, and an item that has a weight attribute ignores WGT-03's ability weights.
- **The items:** `item_layer.py`'s WGT lines (`PORTED` WGT-03 to WGT-06, `ATTRS` `weight`, `TAGS` WGT-05's `EncumbranceOff`), applied by the tools that write the entries (`gen_item.py`: 455 regular and 455 NG+ entries; `gen_ench.py`: 2 runes) and by `gen_econ.py` for the rest (352 regular: 329 short `extend` entries carrying the weight next to the price, 23 Hearts of Stone entries whole; 352 NG+ whole); the razor's 0.3 by hand in `gm_ui.xml`. `tools/gen_wgt.py --verify` checks every WGT item unit's weight and tag as the game reads them against legacy's (813 per folder, none unexplained); its data test `tests/gmTestsWgtData.ws` spawns each regular one into the horse manager's inventory and reads `GetItemWeight` and `IsItemEncumbranceItem` (`GMTest_wgtdata`, in `GMTest_wgt`: 812 items, all but 5.x's `Azurite mineral`, whose name holds a no-break space; on a throwaway build with 5.x's weights all 812 differed). Regression on the area build: +1 check in each tree (1,301 and 156 in both trees, all passing). Since the formula is still 5.x's until slice W4, the lighter weights change what the load counts only for gear, junk and upgrades (half or a fifth of the new weight).

### Slice W2 (2026-11-02)

- **The abilities:** `item_layer.py`'s WGT `NODES` (`weight` for WGT-03 to WGT-05; WGT-06 also `encumbrance`, `panic`, `sprint_stamina_cost`), applied by the tools that write an ability whole: `gen_arm_items.py` and `gen_swd_items.py` (through `item_layer.merge_nodes`, so `NOT_ARM` and `NOT_SWD` needed no change), `gen_ai.py` (`WGT` in its `PORTED`: its `LATER` weight now legacy's), `gen_xbow.py` (legacy's weight node once WGT's nodes are ported) and `gen_item.py` (which now writes an ability whole only for another area's change, `merge_nodes(..., area=WHOLE)`, as for items). `tools/gen_wgt.py` writes the rest into `items/gm_wgt.xml` (57 `extend` entries with the changed nodes, base game and Blood and Wine; 10 whole: Hearts of Stone, the free DLCs, the two repair kits' default abilities that lose their weight) and `items_plus/gm_wgt.xml` (65 whole), skipping any name another DLC file defines (TRPH's trophy abilities once integrated). `--verify` resolves `extend` entries over 5.x's and checks every WGT ability unit's owned nodes against legacy's: 767 regular and 917 NG+ units, none unexplained.
- **Checks:** the data test now also reads every regular WGT ability unit's changed nodes from the definitions (`GMTestWgtAblDef`: base, mult and add of `GetAbilityAttributeValue`), in `GMTest_wgtdata`; `gmtest_wgt_bags()` equips each base-game saddlebag on Geralt's horse (the horse manager's `EquipItem`) and reads `GetMaxRunEncumbrance` less Geralt's own capacity: +40, +60, +80 (the horse's own bag put back). The blinders' panic and the base horse's sprint cost are checked through the definitions only (a real gallop: open check). Both in `GMTest_wgt` (the regression). Three signed-off checks that read 5.x's weights "until WGT" now read legacy's (ARM-01's Feline armor 5, SWD-01's crafted Short sword 8, AI-03's data test with no weight left at 5.x's). On a throwaway build with slice W1's data, 765 data readings differed and the three bags read +30, +70, +100. Regression on the area build: 1,305 and 156 in both trees, all passing (+5 over 1,300 since slice W1).
- **Legacy's pig contest trophy weighs 5 to 10, rolled per copy** (seen in the data test): the item has no weight of its own, so `GetItemWeight` sums its abilities' (`base_trophy_stats` 5 and `pig_contest_trophy_stats`), and legacy wrote the latter's weight as `max="5"` with no `min` (1.32: `max="0"`), so each copy rolls 0 to 5 more. Ported as legacy has it, **decided** by the owner (2026-11-02, with the WGT audit): legacy's random 5 to 10 is kept (the entry is TRPH's); the data test accepts the range. Hearts of Stone's other quest trophy (`q603_sharley_trophy_stats`, `min="5"`) is a fixed 5 more. The TRPH audit read a crown at 8.2 (encumbrance 4.11), the Conserved shaelmaar trophy at 10 (5.01) and the other trophies at 5 (2.51).

### Slice W3 (2026-11-02)

- **DW2:** `item_layer.DW2` gives each new piece's `_Stats` ability the legacy weight of the counterpart ECON's DE2 gave it (as the game reads it): the Netflix set 10 / 4 / 3 / 3 at every tier and its swords 4 and 2 (Wolf School's), Dol Blathanna and White Tiger 15 / 4.5 / 3.5 / 3.5, Scarlet Crest 15 / 5 / 2 / 3, the Dol Blathanna and Vixen swords 6 and 4, Top Notch 6 and 4; their NG+ copies (`NGP `, `items_plus`) alike. Heavy armor 03 Netflix (20) and Heavy gloves 04 Netflix (8) share their counterparts' abilities, legacy's since slice W2. The Fire Horse gear keeps 5.x's 6.01, 1.56 and 0.2 (legacy left the Toussaint gear at 1.32's); potions, quest items and cosmetics keep 5.x's. Applied by the tools that already write these abilities whole: `gen_swd_items.py` (the SWD-10 swords' weight, until now `SWD10_KEEP`'s 5.x value) and `gen_arm_new.py` (the armor pieces). `gen_wgt.py --verify` recomputes every DE2 gear item's weight from its counterpart in 1.32 and legacy (both folders) and fails on a DW2 entry no DE2 item uses; the data test reads the new items' `GetItemWeight` and their abilities' weights (now 1,658 readings, 855 items; on a throwaway build with slice W2's data 74 differed). Regression on the area build: 1,305 and 156 in both trees, all passing (no new regression check: the data test grew).

### Slice W4 (2026-11-02)

- **The formula:** `@replaceMethod(CInventoryComponent) GetItemEncumbrance` in `scripts/local/gm/weight/encumbrance.ws`: every item that counts (`IsItemEncumbranceItem`, 5.x's) weighs `GetItemWeight` (at least 0.01) × quantity × (1 − the reduction), 0 below 0.01, as legacy; 5.x's category rules removed. The reduction is OPT's `GMEncumbranceMultiplier` (0 to 100, default 0) read with `GMGetOptionFloat` and clamped to 0–1 (`GMGetEncumbranceMult`). Legacy's debug fact not ported (PW8).
- **Checks** (`GMTest_wgt04`, in `GMTest_wgt`; options set in memory and put back in the same call): spawned stacks counted by `GetItemEncumbrance`: 100 Drowner brains 10, Bear Armor 15, a key 0.05, a Swallow 0.1, 10 florens 0, a schematic 0, the Fire Horse Saddle 6.01; at 50% the brains 5, the armor 7.5 and Geralt's whole load halved (22.36 → 11.18 on the test save); at 100% the armor 0 (the former OPT check O5); with "Ignore Item Weight" on, nothing counts and Geralt's load is 0 (DW1). On a throwaway build without the replacement, the nine checks of the new rule failed (5.x: the brains 0, the armor 7.51, the key 0.01, the saddle 3.015, the option ignored). Regression on the area build (on 5.x-GM 501a4d26): 1,496 and 156 in both trees, all passing (+13, W4's checks, over 1,483).

### Slice W5 (2026-11-02)

- **Code** (`scripts/local/gm/weight/overEncumbered.ws`): `GMOverEncumbrancePenalty()` (WGT-07: while `EET_OverEncumbered`, clamp(load ÷ limit − 1, 0, 1)), added to ARM-02's term in its `GetStaminaActionCost` wrapper (`armor/armorClass.ws`: `cost × (1 + armor + overencumbrance)` for melee and agility actions but usable items, PW5; ARM's own checks still pass); wrappers of `W3Effect_OverEncumbered.OnEffectAdded`/`OnEffectRemoved` blocking and unblocking `EIAB_FastTravel` (source `OverEncumbered`, WGT-08); a wrapper of the horse state's private `CanCanter` adding `IsActionAllowed(EIAB_RunAndSprint)` after 5.x's cart and settlement rules (WGT-09; it compiles); a wrapper of `CR4PlayerStateUnconscious.OnLeaveState` calling `UpdateEncumbrance` (WGT-11).
- **Checks:** `GMTest_wgt05` (in `GMTest_wgt`): Geralt overloaded by Drowner brain stacks in his inventory to 20% and 120% over his limit (read from the game: 60 on the test save): a dodge 5 → 6.005 and 10, the sprint 10/s → 12.01 and 20 (× (1 + armor + share), share capped at 1; the test save's armor term 0); fast travel blocked by the load (`IsActionBlockedBy(EIAB_FastTravel, 'OverEncumbered')`) and the block gone after the drop, costs back. The regression's own state can hold other fast-travel blocks, so the check reads the load's own block. `gmtest_wgt11()` (on its own: the state's code revives Geralt): the overburdened effect taken off by hand comes back when the Unconscious state is left. The gallop: Roach is spawned on the test save but not ridden, and her component refuses the gallop anyway, so WGT-09 is not checked by script (open check: a real ride overburdened). The ARM-02 interplay with heavy armor is checked by the formula on the save's own gear only. On a throwaway build without slice W5's code, the six overburdened checks and WGT-11's failed (costs unchanged, no fast-travel block, the effect not restored). Regression on the area build: 1,504 and 156 in both trees, all passing (+8 over 1,496).

### Slice W6 (2026-11-02)

- **Code** (`scripts/local/gm/weight/boat.ws`): the single `@replaceMethod(W3Boat) OnAreaEnter`, 5.x's body (1.32's) with legacy's lines: when Geralt steps onto a boat that has not sunk, with "Sink the boat if overencumbered" on (OPT's `GMSinkBoat`, on by default, DW3), the boat able to be destroyed (5.x's `GetCanBeDestroyed`, which is also false while 5.x's accessibility option `DisableDurabilityBoat` is on), no save loading and Geralt over the threshold, the boat drowns (`TriggerDrowning`, `boat_sinking`) with the message; `GMCheckPlayerEncumbrance` (`@addMethod`; overburdened by more than OPT's `GMSinkBoatOverEnc`, 0 to 100 %, default 20). The message 2110992179 (`gm_geralt_too_heavy`) in nine languages, legacy's texts, in `localization/modGhostMode/<lang>.csv`.
- **Checks** (`GMTest_wgt06`, in `GMTest_wgt`; options set in memory and put back): the message by key and id; a boat spawned behind Geralt (`gameplay_boat_base.w2ent`) boarded through its `OnBoatTrigger` area (`OnAreaEnter`, then `OnAreaExit`): not overburdened and 10% over (threshold 20) the boat holds; the same load with the threshold at 5% is over it; 30% over with "Sink the boat" off the boat holds (the former OPT check O4); 30% over with it on, every condition of the sinking holds. **The sinking itself is not run:** `TriggerDrowning` on a boat spawned on land crashed the game (seen once, 2026-11-02); a real boarding overburdened, on a boat in water, is the open check. On a throwaway build without the slice's code the three checks of the new rule failed. Regression on the area build: 1,510 and 156 in both trees, all passing (+6 over 1,504).

### WGT audit (2026-11-02)

Done by a fresh session ([audit](../feature-mapping.md#audit-signing-a-feature-off)) on the integrated 5.x-GM `fbb925eb` and master `3c3cac1e`, reading code and data, with game runs in both trees on 2026-11-02. Read: the slices' commits (W1 to W6 on 5.x-GM, `dd8958b3` to `fbb925eb`), `weight/encumbrance.ws`, `weight/overEncumbered.ws`, `weight/boat.ws`, ARM-02's wrapper in `armor/armorClass.ws`, STAM's wrapper of the same function, `gen_wgt.py`, the test files `gmTestsWgt.ws` and `gmTestsWgtProbe.ws`.

**How it was checked:**
- **Data, independent of the generators:** a resolver written for the audit (ElementTree, so any attribute order) read every `<item>` and `<ability>` of every definitions file in four sources: 1.32 (`master`), legacy (`legacy-GM`), 5.x (`vanilla-5.x`) and the port (5.x's files with Ghost Mode's DLC over them: a plain entry on a 5.x name ignored, `extend` merged node by node and tags added or removed, `replace` whole, `extend` on a Hearts of Stone name flagged). Both folders. For every item it worked out the weight as the game reads it (the item's own `weight` above 0, else its abilities' base `<weight>` nodes summed, a range where `max` is above `min`), with the `EncumbranceOff`/`EncumbranceForceYes` tags and the category; for every ability the four nodes WGT owns (`weight`, `encumbrance`, `panic`, `sprint_stamina_cost`). Then, by name rather than by unit: every item and ability whose value legacy changed from 1.32 against the port, every one legacy left alone against 5.x, and 5.x's new items one by one. A second pass compared, field by field, every entry Ghost Mode's DLC gives with 5.x's, to find whole entries (`replace`) that lost or changed something legacy did not change. `gen_all.py --verify` (with `gen_wgt.py --check` and `--verify`, `dlc_conflicts.py` and `check_modsigns.py`) and `deviations.py --check` were run on the integrated tree.
- **Code:** each legacy change (`GetItemEncumbrance`, `GetEncumbranceMult`, `CalcStaminaOverEncumbrancePenalty` and its place in `GetStaminaActionCost`, `W3Effect_OverEncumbered`, `CanCanter`, `W3Boat.OnAreaEnter` and `CheckPlayerEncumbrance`, `CR4PlayerStateUnconscious.OnLeaveState`, the option readers) line by line against the port and 5.x's body. Every reader of weight and encumbrance in 5.x's scripts against legacy's: the inventory grid and the tooltip (`GetItemEncumbrance`), the inventory and common menus' load line, the loot window, shops (the merchant's inventory through the same function), the crafting and alchemy previews (`GetItemAttributeValueNoRandom(…, 'weight')`, abilities only), the preparation menus, the quest and journal panels (`GetItemWeight`), the horse manager, the overburdened locomotion, Mutagen 2 (ALCH-13's, commented out in legacy). Every 5.x blocker of `EIAB_RunAndSprint` and `EIAB_FastTravel` against 1.32's, and 5.x's accessibility options (`GetVarValue('Accessibility', …)`).
- **Sweeps:** `unit_sweep.py --unattributed` for encumbr, weight, burden, carry, boat, sink, gallop, canter, fast travel, saddle, panic, sprint_stamina, zero_enc, horse.
- **In game** (scripted calls; throwaway probes on gm/wgtaudit `5cd764f6` (built and run as `d8ad3c72`, the same tree), `tests/gmTestsWgtAudit.ws`, not for integration): A1, every item the test save holds against a fresh copy of the same name (weight and counted weight); A2, a boat 30% over with 5.x's "Unlimited Boat Durability" on (boarded only once the boat read as indestructible); A3, a dodge, a heavy attack, a jump, Aard, a usable item and Whirl naked, in four light and four heavy pieces, each before and at 30% over, in both trees; A4, Roach's own `CanCanter` (the wrapped function, through a test method on her Exploration state) within the limit, 30% over and after the drop, in both trees.
- **Regression** on the integrated build `fbb925eb` (`regress.py --trees both`): classic 1,510 and 156 passed, new tree 1,510 and 156 passed, 0 failed.

**Checked and holding:**
- **Every weight legacy changed.** In the regular folder 2,168 items weigh, as the game reads them, something legacy changed (directly or through a shared ability: the notes', books', food's, potions' and trophies' shared abilities included), and 2,338 in NG+: every one weighs legacy's in the port, with legacy's `EncumbranceOff` and category, but the two Blood and Wine notes of F5. All 1,244 regular and 1,495 NG+ ability nodes legacy changed (weights, the saddlebags' capacities, the blinders' panic, `HorseLevel1`'s sprint cost, legacy's new abilities) are legacy's; no node legacy left alone differs from 5.x's. The base game's, both expansions' and every free DLC's files are covered, whichever generator writes the entry (`gen_item`, `gen_arm_items`, `gen_arm_new`, `gen_swd_items`, `gen_ai`, `gen_xbow`, `gen_ench`, `gen_econ`, `gen_wgt`, `gen_trph`, the razor by hand).
- **5.x's new items** (178 regular, 206 NG+): the DE2 gear at its counterparts' legacy weights as DW2 lists (Netflix 10 / 4 / 3 / 3, swords 4 and 2; Dol Blathanna and White Tiger 15 / 4.5 / 3.5 / 3.5; Scarlet Crest 15 / 5 / 2 / 3; Vixen, Dol Blathanna, Top Notch 6 and 4; Heavy armor 03 Netflix 20, Heavy gloves 04 Netflix 8; their `NGP` copies alike), the Fire Horse gear, quest items, cosmetics, scabbards and Gwent cards at 5.x's, the two new potions 0.1 through `default_potion_stats`.
- **Hearts of Stone's whole entries.** No `extend` entry of Ghost Mode's DLC lands on a Hearts of Stone item or ability (in either folder), and no item `extend` carries a child block but `<tags>`. Field by field, every Hearts of Stone entry the DLC gives whole differs from 5.x's only where legacy changed it or another area decided so (ENCH's runewords, SKL's `perk_18`), but six duplicated notes' icons (F5).
- **Items whose own weight shadows their abilities' weights.** Only Blood and Wine's two Toussaint crossbows' abilities (legacy removed the ability weights and gave the items 2 and 3) and the `Ravix of Fourhorn` and `Geralt of Rivia` crossbows sharing one of them: legacy's ability change is inert there in legacy too, and the items weigh legacy's. No item has an own weight in 5.x that it lacked in 1.32 where legacy changed an ability weight. The three other changed abilities no item reads (the two repair kits' defaults, `Skellige sword 3 _Stats`) are legacy's.
- **Duplicates and hidden entries.** No item or item-folder ability name is given twice in Ghost Mode's DLC (either folder), and no DLC entry without `on_conflict` sits on a 5.x name. Only `gm_arm_new.xml`'s abilities (24 regular, 44 NG+) put `on_conflict` before `name`; with the resolver reading any order, none hides a second entry. The abilities folder holds seven names with two or more `extend` entries (`attack_heavy`, `attack_heavy_special`, `attack_super_heavy`, `sword_s1`, `sword_s21`, `magic_s4`, `ConGeralt`): other areas', no weight node, noted only. Where vanilla itself defines a name twice (a base-game and an expansion copy), the port's `extend` overrides whichever copy the game keeps; legacy's bombs (`default_bomb_stats`, also defined at 0 in Blood and Wine's quest file) weigh 0.1, as the changelist says.
- **The formula and the readers.** `GetItemEncumbrance` is legacy's but its debug fact (PW8). Every reader of weight in 5.x reads it through `GetItemEncumbrance`, `GetEncumbrance` or `GetItemWeight`, as in legacy; the loot window's zero for quest items, ingredients and alchemy items is 1.32's, legacy's and 5.x's (5.x adds "Ignore Item Weight"); the crafting previews read the abilities' weight only, as in legacy. No other area's code reads encumbrance but ARM-02's wrapper.
- **The stamina term.** Melee and agility actions only, as legacy's `IsActionMelee` less usable items; Ciri and NPCs get none. 5.x's skill changes sit in `GetStaminaActionCostInternal`, below the wrapper, so the term multiplies the cost after every skill in both trees. Probe A3, both trees: naked (−0.5), four light (−0.3) and four heavy (+0.5) pieces at 30.1% over, a dodge, a heavy attack and a jump × (1 + armor + share) ÷ (1 + armor) exactly (dodge 2.5 → 4.005, 3.5 → 5.005, 7.5 → 9.009); Aard, a usable item and Whirl unchanged.
- **Fast travel, the gallop, the knockout.** The effect's block comes and goes with the effect; action locks are saved with the player, and the map's travel test reads `EIAB_FastTravel` (5.x's `mapMenu`); 5.x adds no way around it. 5.x adds one `EIAB_RunAndSprint` blocker (petting the dog), so WGT-09's side effect on Roach is legacy's. Probe A4, both trees: `CanCanter` true within the limit, false 30% over, true after the drop, so the wrapper of the state's private function runs. WGT-11 is legacy's line.
- **Boats.** `OnAreaEnter` is 5.x's body with legacy's lines; the option and threshold readers clamp what the menu already clamps.
- **"Ignore Item Weight"** (DW1): `IsItemEncumbranceItem` and `GetEncumbrance` are 5.x's, `GMTest_wgt04` covers it; with it on, WGT-07 to WGT-10 cannot trigger.
- **Save impact** (A1): the 30 items of the test save (a 5.x save from before the mod) weigh and count what fresh copies do; Geralt's load reads 22.36.
- **New Game+** (offline only): covered by the data checks above; NG+'s legacy weights equal the regular ones but `Gnomish silver sword 2_crafted` (PW10).
- **Other areas' checks.** Three signed-off checks read legacy's weights since slice W2 (recorded there); the regression passes in both trees; `GMTest_wgt05` refuses to run if an earlier check left Geralt overburdened, and no stamina check failed.
- **Conventions.** `//modSigns` markers in both replaced bodies; no leftovers, debug logging or absolute paths; `deviations.py --check` passes, and no deviation was found that should have been recorded (the guards against a zero limit and the clamped threshold change nothing in play).

**Findings:**

| # | Finding | Evidence | Severity | Kind |
|---|---|---|---|---|
| F1 | **5.x's "Unlimited Boat Durability" switches the sinking off.** With the accessibility option on (`Accessibility`/`DisableDurabilityBoat`, also set by the "Bard's Ballad" preset together with "Ignore Item Weight"), no boat sinks under Geralt however overburdened he is, because the rule asks the boat whether it can be destroyed and 5.x's answer includes the option. Legacy had no such option. The area's 5.x analysis lists "Ignore Item Weight" (DW1) but not this one; only slice W6's notes mention it. Options: (a) keep it (the player's explicit accessibility choice, off by default, as DW1 (a)), recorded in WGT-10's 5.x line and Decisions; (b) sink regardless: test the boat's own indestructible flag (quest boats) instead of `GetCanBeDestroyed()`. **Recommendation: (a)**, not a deviation (content legacy never had). | 5.x `vehicles/boat/boat.ws:155` (`GetCanBeDestroyed`: `canBeDestroyed && !…'DisableDurabilityBoat'`); `weight/boat.ws` (the condition); probe A2: option off, every condition holds 30% over; on, the boat reads indestructible and stays afloat | low | owner decision, doc correction |
| F2 | **Two of the open checks can be closed by script.** WGT-09 ("compiles; the gallop not seen") can be checked without riding: Roach's own `CanCanter`, called on her Exploration state, follows the load (probe A4, both trees). WGT-07's checks cover a dodge and the sprint on the test save's gear only; naked, light and heavy pieces, attacks, the jump and the exclusions (signs, usable items, Whirl) are checked by probe A3 (both trees). Adopting A3 and A4 into `GMTest_wgt05` would keep them in the regression; the real ride (the gait on screen) stays an open check. | probes A3, A4 (`tests/gmTestsWgtAudit.ws` on gm/wgtaudit `5cd764f6`): 7 and 1 passed per tree | low | clear fix (test gap) |
| F3 | **Stale or wrong lines in this entry** (not applied). (a) WGT-04's open check (a potion weighs 0.1 through `default_potion_stats`) is answered by slice W4's Swallow check. (b) WGT-06's first open check (the capacity per bag) is answered by slice W2's `gmtest_wgt_bags`; the real gallop with the blinders stays. (c) WGT-03 to WGT-06's save impact "to confirm in slice W1/W2" is answered by A1. (d) WGT-08's save impact says a save made overburdened before the mod "gets the block at the next update": `UpdateEncumbrance` adds the effect only when it is missing, and a load restores effects without `OnEffectAdded`, so the block comes only when Geralt next becomes overburdened (no effect with the mod installed at the start). (e) WGT-01's open-check line says the abilities' weights are "not a sum", the shared-docs line "the sum": the item's own weight wins over its abilities'; without one, its abilities' weights are summed (the pig contest trophy: 5 + 0 to 5). (f) WGT-10's "5.x: 1.32's `OnAreaEnter`" misses F1. | `playerWitcher.ws` 6970–6975 (5.x); `baseEffect.ws` `OnLoad`; `gmTestsWgt.ws` (`GMTest_wgt04`, `GMTest_wgt_bags`) | low | doc correction |
| F4 | **One weight change legacy made is unattributed: Hearts of Stone's `Shovel _Stats`** (both folders), whose weight 8 legacy removed when it gave the Caretaker his own `Caretaker Shovel _Stats` (AI-19, ported). The base game defines the same name (`def_item_npcweapons.xml`, weight 1), so which copy the game reads is unknown, and the only item still using it is the NPC `Shovel` (a secondary weapon): no play effect expected. Recommendation: attribute it to AI-19 (or WGT-03) as not ported, with this reason. | `unit_sweep.py weight --unattributed`; `legacy-GM` `dlc/ep1/…/def_item_weapons.xml` | low | clear fix (mapping) |
| F5 | **Vanilla items defined twice, pinned to one copy.** Blood and Wine defines `poi_gor_d_06_note` and `poi_gor_d_06_note03` twice: as books with `Default Book _Stats` (`def_item_books.xml`, legacy 0.2) and as misc items without abilities (`def_item_living_world.xml`). CRAFT-08's whole entries in `gm_item.xml` (legacy's change to the second copy) make them misc items weighing 0.01 in the port; which copy legacy's game read is not known. Six Hearts of Stone notes (`ep1_poi_03_note` and five more) are defined twice the same way and take the second copy's icon. Recommendation: accept (the entries follow the copy legacy changed); for CRAFT's information. | the resolver (both folders); `gm_item.xml` | low | owner decision (accept) |
| F6 | **For another area: legacy added Hearts of Stone's missing NG+ definition of `Body palms cut`** (`items_plus/def_item_misc.xml`), which NG+'s armour variants name; 5.x's NG+ lacks it too, the unit is unattributed and the port does not add it. A `Body` item, so not WGT's (it never counts). For ITEM or ARM (NG+, untested). | `unit_sweep.py weight --unattributed`; the resolver (NG+: absent in 1.32, 5.x and the port) | low | clear fix (hand-off) |

**Open checks** (need a cleared run or a later save): a real ride overburdened (Roach held to a trot on screen); a real boarding overburdened on a boat in water (the sinking, its sound and message; a save loaded on a boat); the map refusing fast travel on screen; the inventory's weight display and a real pick-up; a real dodge and sprint overburdened. NG+ untested by policy.

#### WGT audit close-out

**WGT signed off by the owner (2026-11-02).** The open checks on screen (a real ride, a real boarding and sinking, the map's refusal, a real pick-up and the weight display, a real dodge and sprint) wait for a cleared run or a playthrough; NG+ is checked offline only.

**The owner's decisions (2026-11-02), all as recommended; the porter's calls confirmed.** Every finding is fixed, decided or recorded.

| Finding | Outcome | How tested |
|---|---|---|
| F1 "Unlimited Boat Durability" switches the sinking off | **decided** (a): kept as the player's choice, like DW1; recorded in [WGT-10](#wgt-10-sinking-boats)'s 5.x line and Decisions; not a deviation | the audit's probe A2 |
| F2 Two open checks can be closed by script | **fixed**: the audit's probes A3 (the stamina term naked, in four light and four heavy pieces: a dodge, a heavy attack and a jump; Aard, a usable item and Whirl unchanged) and A4 (Roach's own `CanCanter` within the limit, 30% over and after the drop) adopted into `GMTest_wgt05` (`GMTestWgt05Classes`, `GMTestWgt05Canter`); WGT-07's and WGT-09's status updated | scripted, both trees, in the regression (+8 checks); failed first on the throwaway build (the costs unchanged, `CanCanter` true 30% over) |
| F3 Stale or wrong lines | **corrected**: (a) WGT-04's open check, (b) WGT-06's, (c) the save impacts of WGT-03 to WGT-06, (d) WGT-08's save impact, (e) WGT-01's weight rule (an item's own weight wins; without one its abilities' weights are summed), (f) WGT-10's 5.x line | read |
| F4 Hearts of Stone's `Shovel _Stats` unattributed | **attributed** to AI-19 as not ported, with the reason (both folders; `gen_ai.py`'s output unchanged) | `gen_all.py --verify` |
| F5 Vanilla items defined twice, pinned to one copy | **accepted**; noted in [CRAFT-08](craft.md#craft-08-dismantling) for information | — |
| F6 `Body palms cut` (NG+) | **handed off** to ITEM: attributed to ITEM-01 with a note, not ported ([hand-off](#hand-off-to-other-areas)) | — |
| The pig contest trophy's 5 to 10 ([slice W2](#slice-w2-2026-11-02)) | **decided**: legacy's random weight kept | the data test |

**Regression** (gm/fix2 `528540ef`, `regress.py --trees both`, `god()` off, a fresh launch per tree): `gmtest_regress()` 1,524 passed, 0 failed, and `gmtest_panel()` 156 passed, 0 failed, in each tree (+13 checks over 1,511: OPT 1, TRPH 4, WGT 8). Fail first: a throwaway build (gm/fix2-fail `74c94b7a`: the fixes, WGT-07's term and WGT-09's rule removed, the tests kept) failed every new check that tests a fix; the four "unchanged" checks (Aard, a usable item and Whirl per armor class; Roach's gear back) passed there too, as they test what stays. The saves: the releases found them clean (1,079 live and in the backup; none gone, new or changed).

**Deviations:** none new (F1 is content legacy never had).

## For the shared docs

Moved into the shared docs at integration (2026-11-02).
