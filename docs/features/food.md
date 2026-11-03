# FOOD: food, drinks, alcohol and cooking

What Geralt eats and drinks and what it does for him: the Well Fed and Well Hydrated effects (their length and regeneration), which item gives which (food tier, drink tier, rarity, tags, stack size), alcohol and raw food (toxicity, drunkenness), the Connoisseur perk (classic `perk_15`, new tree `perk_41`), cooking (27 recipes brewed in the alchemy menu) and the edible tooltip. Ghost Mode reworked food so it serves paced healing (P8) and scarce loot (P6): "Cooking recipes added: can be bought from innkeepers. Food and drinks reworked in terms of quality and availability in loot and shops. Well hydrated separate effect was restored. Well fed and well hydrated effects have fixed 60 sec duration for all tiers. Food of tier 1/2/3 now restore 10/20/30 hp/sec out of combat and 1/5/10 hp/sec in combat. Drinks now restore 5/10/20 hp/sec out of combat, 1/5/10 hp/sec in combat and 1/2/3 stamina/sec" (changelist 836–845); Connoisseur (461–462); Dumplings (959). Sources: those changelist lines, the hand-offs of SKL, ALCH, CRAFT, LOOT, ENCH, STAM, UI and ITEM ([hand-offs received](#hand-offs-received)), and the code, which has more than the changelist (toxicity amounts, the refusal when Geralt is too toxic, drunkenness, the regeneration model, the item tiers, the cooked quantities).

**What 5.x did in this area** (from `vanilla-5.x`, unverified in game). Well Fed's values changed (tiers 30/60/60 s, 10/10/15 Vitality per second in and out of combat; 1.32: 5/10/10 s, 50/50/80); Well Hydrated, drunkenness, the food and drink items, the cooking file and the toxicity code are 1.32's (two item edits: the Tirnalia potion tagged a drink, the Bell pepper's name and icon). The new tree's Gourmand (`perk_41`) makes food last 5 minutes per level and ends Well Fed when unequipped; the classic Gourmet (`perk_15`) makes it last 20 minutes. Dumplings (`Runeword 6`) also multiplies food and drink regeneration (removed by [ENCH-06](ench.md), DE2). 5.x's `ConsumeItem` refuses food while diving and has a branch for a Cat perk (`perk_29`) that no skill data defines (inert).

**How legacy Ghost Mode implements it.** Data: `def_item_edibles.xml` (base and Blood and Wine) and two Hearts of Stone quest items (`def_item_quest.xml`: Soltis Vodka, Cornucopia), the food effects in `effects.xml` (base and Hearts of Stone), the cooking recipes in `def_item_cooking_recipes.xml`, the Connoisseur ability (`geralt_skills_ep2.xml`, SKL-18), all with NG+ copies equal to the regular ones. Scripts: the food effect classes (`wellFed.ws`, `wellHydrated.ws`, `edible.ws`), `W3AbilityManager.OnAbilityChanged`, `CR4Player.ConsumeItem`, `W3PlayerWitcher.DrinkPotionFromSlot`, `W3InventoryItemContext.HandleUserFeedback`, `W3PlayerAbilityManager.OnSkillUnequip`, `W3TooltipComponent.AddBuffStats`, `W3AlchemyManager.CookItem` and `alchemyTypes.ws` (`EACIT_Edibles`), the debug command `addrecipesedibles`. Strings: Connoisseur's name and description (9 languages, SKL-19's rows) and one unused attribute name.

Unit lists: [attribution.csv](attribution.csv): mapped 2026-10-23 from the changelist, every hand-off to FOOD, a field-by-field comparison of every food, drink and effect entry (master against `legacy-GM` and `vanilla-5.x`: category, tags, `base_abilities`, stack size, description key; abilities whole), and sweeps (`unit_sweep.py` for edible, food, drink, alcohol, cook, wellfed, hydrat, drunk, uncooked, perk_15, beverage, EACIT, liver, gourmet, connoisseur, dumpling, cornucopia, soltis, vodka, wine, beer, meat, fish, the tags `Drinks`, `Edibles`, `Alcohol`, and `vitalityRegen`): **367 units** carry a FOOD feature (18 script units, 161 XML units and their 161 NG+ copies, 27 string rows); 33 of them are shared with SKL-18, SKL-19, ENCH-06, ALCH-02, ALCH-17, CRAFT-07 and CRAFT-08. Units whose only change is a price or a weight (23 food and drink items, the Shani alcohols and flowers, the `mod_food` price tag rows) are left to ECON and WGT ([hand-off](#hand-off-to-other-areas)). Three class declarations changed by legacy have no unit (the tool sees members, not a class's parent): `W3Effect_WellFed`, `W3Effect_WellHydrated` and `W3Effect_Edible` extend `CBaseGameplayEffect` instead of `W3RegenEffect` (FOOD-03). Port status: **signed off** by the project owner (2026-10-24); **ported** (2026-10-24): the owner decided DF1 to DF10, Q1 and Q2 ([area decisions](#area-decisions)); all six slices **verified** in both trees (5.x-GM `18b4bd41`, `8bbffd5a`, `fb15287b`, `155e22f4`, `ed2f7dc5`, `545e3d1e`); audited 2026-10-24 ([FOOD audit](#food-audit-2026-10-24): 13 findings, every one fixed, recorded or decided by the owner: [close-out](#audit-close-out), fix slice A in 5.x-GM `3c21723c`).

## Scope

**FOOD covers** the food effects (Well Fed, Well Hydrated, the Hearts of Stone Cornucopia's Well Fed) and how they regenerate; which item gives which effect (food and drink tiers), the food items' rarity, tags and stack size; alcohol and raw-food toxicity, the refusal to eat or drink when too toxic, drunkenness; Connoisseur in both trees; the cooking recipes, their items, the cooked item type and quantities; the edible tooltip.

**Not FOOD** (porter's call from the docs, for the owner to confirm with DF10):

| Subject | Area | Why |
|---|---|---|
| Food, drink and cooking recipe prices, the `mod_food` price tag and its modifier rows (`economy_tagmodifiers.csv`) | ECON | Money (the new items carry legacy's price as part of their definition) |
| Food and drink weights | WGT | |
| Where food, drinks and recipes are sold and found ("availability in loot and shops", changelist 841) | LOOT (signed off) | The lists are ported (LOOT-01, LOOT-05); FOOD-07 ends LOOT-01's cooking-recipe deviation |
| The refill alcohols (Local pepper vodka, Alcohest, Dwarven spirit, Mahakam spirit, Mandrake cordial, ...) and their recipes | CRAFT (signed off) | Alchemy ingredients without a drink effect in 1.32, legacy and 5.x (CRAFT-06, CRAFT-07) |
| The general Vitality regen options (`GetCombatVitalityRegen`, `GetOutOfCombatVitalityRegen`) | OPT, GEN | Geralt's base regen, not food (UI-05's temporary deviation) |
| `enabledeletedscene` (a debug command setting `q401_cooking_enabled`, a cut Kaer Morhen scene) | MISC (unattributed) | A quest scene, not the food system |
| Quest rewards naming food (`q605_mirror_finale_cornucopia`, `sq205_1_got_alcohol`, ...) | XP, LOOT | Their experience and items |

## Changes at a glance

### What Ghost Mode changed

| # | Feature | Vanilla 1.32 | Legacy GM | Units (main) |
|---|---|---|---|---|
| FOOD-01 | Well Fed and Well Hydrated values | Well Fed 5/10/10 s at 50/50/80 Vitality/s; Well Hydrated 15/20/30 s at 10/15/15; Cornucopia 5 s at 40 (25 in combat) | Both 60 s for every tier; food 10/20/30 Vitality/s out of combat and 1/5/10 in combat; drinks 5/10/20 and 1/5/10, plus 1/2/3% of maximum stamina per second; Cornucopia 30 s at 15/15 | `effects.xml` (base, Hearts of Stone) |
| FOOD-02 | Drinks give Well Hydrated | Every drink gives Well Fed (`BeverageQuality_*`: "no longer regenerates stamina but we need to keep it") | Drinks give Well Hydrated again ("separate effect was restored") | `BeverageQuality_1` to `_3` |
| FOOD-03 | Food raises Geralt's regeneration | Food is a regen effect of its own and also adds its ability to Geralt's regen rates (counted twice, from the code); the effect ignores the combat value | Food and drink effects only add to Geralt's regen rates: the out-of-combat value out of combat, the combat value in combat; a regen ability restarts the regen; a newer drink always replaces Well Hydrated | 3 class declarations, `OnAbilityChanged`, `W3Effect_WellHydrated` |
| FOOD-04 | Food and drink items | Tiers mixed (raw chicken, fish and pork tier 3; water tier 2), most drinks tier 1, small stacks | Raw produce tier 1, simple food and raw meat tier 2, cooked dishes tier 3; water tier 1, juices and beers tier 2, milk, wines and spirits tier 3; rarity colours by tier; stacks of 100; `Potion` tag off seven items; Soltis Vodka drinkable; Wolf liver a food; two new dishes | 91 items (54 base, 3 of them new; 35 Blood and Wine; 2 Hearts of Stone) |
| FOOD-05 | Alcohol, raw food and drunkenness | Alcohol: no toxicity, drunk 30 s | Beer 5 toxicity, wine and spirits 10, raw meat and fish 5 (tag `Uncooked`); refused when Geralt is too toxic; drunk 60 s (alcohol only) | 3 abilities, `DrunkennessEffect`, `ConsumeItem`, `DrinkPotionFromSlot`, `HandleUserFeedback` |
| FOOD-06 | Connoisseur | Gourmet `perk_15`: food lasts 20 minutes | Connoisseur: no alcohol or raw-food toxicity, no drunkenness, alcohol's effects last 100% longer | `perk_15`, the effects' `CalculateDuration`, `ConsumeItem`, 18 strings |
| FOOD-07 | Cooking | Two quest recipes only | 27 recipes (raw to cooked, juices) brewed in the alchemy menu as a new type, cooked in the recipe's quantity, sold by innkeepers and butchers | `def_item_cooking_recipes.xml`, `EACIT_Edibles`, `CookItem` |
| FOOD-08 | Edible tooltip | Dumplings' longer duration shown only for an equipped edible | Dumplings shown on every edible; Connoisseur's +100% on alcohol | `AddBuffStats` |

### What 5.x changed

| # | Feature | 5.x change (from code and data) |
|---|---|---|
| FOOD-01 | Values | Well Fed 30/60/60 s at 10/10/15 Vitality/s, in combat too; Well Hydrated, Cornucopia and drunkenness as 1.32 |
| FOOD-02 | Drinks | None: drinks give Well Fed |
| FOOD-03 | Regen model | Still a regen effect (counted twice); `SetEffectValue` multiplies the regen by Dumplings (removed by ENCH-06); Gourmand sets Well Fed's length in `Init` |
| FOOD-04 | Items | Tirnalia potion tagged `Drinks` (still Well Fed 1), Bell pepper's name key and icon (legacy fixed the icon too) |
| FOOD-05 | Toxicity | None (no food toxicity); food refused while diving; an inert Cat perk branch |
| FOOD-06 | Connoisseur | Classic Gourmet as 1.32; new tree Gourmand `perk_41`: food lasts 300 s per level, ended when unequipped |
| FOOD-07 | Cooking | None to the file; `CookItem` re-applies an oil brewed while on the sword (ALCH's auto-oil, kept) |
| FOOD-08 | Tooltip | None (1.32's) |

### Classification and proposed action

| # | Feature | Class | Proposed action |
|---|---|---|---|
| FOOD-01 | Values | overlap (5.x retuned Well Fed) | Legacy's (DF1) |
| FOOD-02 | Drinks | clean | Legacy's (DF2); makes ENCH-06's drink rule and ALCH-07's Maribor rule act |
| FOOD-03 | Regen model | conflict (a class's parent cannot change by annotation) | Legacy's behaviour (DF3), re-implemented on 5.x's classes |
| FOOD-04 | Items | clean | Legacy's through the item layer (DF4, DF9); ends CRAFT-07's lemon deviation |
| FOOD-05 | Toxicity | clean (data), conflict (5.x's `ConsumeItem`) | Legacy's (DF5) |
| FOOD-06 | Connoisseur | rethink (new tree), clean (classic) | Legacy's in both trees (D41, DF7); ends SKL-18's Gourmand deviation |
| FOOD-07 | Cooking | clean | Legacy's (DF8); ends LOOT-01's deviation |
| FOOD-08 | Tooltip | clean | Legacy's; ends ENCH-06's tooltip deviation |

---

### FOOD-01 Well Fed and Well Hydrated values

| | |
|---|---|
| Kind | tuning |
| Pillars | P8, P2 |
| 5.x class | overlap |
| Flags | balance, needs-decision (DF1) |
| Depends on | FOOD-02 (drinks give Well Hydrated), FOOD-03 (how the values act) |
| Skill trees | n/a |
| Port form | the effect abilities in Ghost Mode's DLC (`on_conflict="replace"`, `gm_food.xml` written by `tools/gen_food.py`), regular and NG+ (legacy's NG+ values equal its regular ones) |
| Port status | **signed off** (2026-10-24); verified (slice 1, 2026-10-24, both trees) |
| Open checks | — |
| Save impact | none (expected): ability values are read live |
| NG+ counterpart | applied (legacy's NG+ files), untested |

**What it does** (changelist 843–845): eating gives Well Fed for 60 s whatever the tier: 10/20/30 Vitality per second out of combat, 1/5/10 in combat; drinking gives Well Hydrated for 60 s: 5/10/20 out of combat, 1/5/10 in combat, and 1/2/3% of maximum stamina per second (the changelist says "1/2/3 stamina/sec": the same at 100 stamina). Hearts of Stone's Cornucopia (an endless food) gives its own Well Fed for 30 s at 15 per second in and out of combat (1.32: 5 s, 40 and 25). Food is a slow top-up between fights and a trickle in combat, not a heal.

**Implementation (legacy):** `WellFedEffect_Level1` to `3`, `WellHydratedEffect_Level1` to `3` (`staminaRegen` added), `WellFedEffect_Cornucopia`, regular and NG+.

**5.x:** Well Fed retuned (30/60/60 s; 10/10/15 per second, the same in combat), the rest 1.32's.

**Decisions:** legacy's numbers (DF1, project owner, 2026-10-24).

### FOOD-02 Drinks give Well Hydrated

| | |
|---|---|
| Kind | system |
| Pillars | P8, P2 |
| 5.x class | clean |
| Flags | needs-decision (DF2) |
| Depends on | FOOD-01, ALCH-07 (Maribor Forest no longer cancels Well Hydrated, signed off), ENCH-06 (Dumplings on drinks, signed off) |
| Skill trees | n/a |
| Port form | `BeverageQuality_1` to `_3` in Ghost Mode's DLC (`replace`, `gen_food.py`), regular and NG+ |
| Port status | **signed off** (2026-10-24); verified (slice 1, 2026-10-24, both trees) |
| Open checks | — |
| Save impact | none (expected) |
| NG+ counterpart | applied, untested |

**What it does** (changelist 842): drinks give Well Hydrated, a second effect beside Well Fed, so a meal and a drink stack; 1.32 gave every drink Well Fed (its comment: kept "for backward compatibility"). Food with both tags in 1.32 (Onion soup, Cookies, Ginger Bread) lose the drink part (FOOD-04).

**Implementation (legacy):** the three `BeverageQuality_*` abilities, regular and NG+ (`def_item_edibles.xml`).

**5.x:** drinks give Well Fed (1.32's data). The effect `WellHydratedEffect` exists and works (ENCH-06's test adds it by script); no item gives it.

**Decisions:** drinks give Well Hydrated (DF2, project owner, 2026-10-24).

### FOOD-03 Food raises Geralt's regeneration

| | |
|---|---|
| Kind | system, fix |
| Pillars | P8 |
| 5.x class | conflict |
| Flags | needs-decision (DF3, DF6) |
| Depends on | FOOD-01, STAM-04 (stamina regen, signed off), ENCH-06's replaced `SetEffectValue` and `W3Effect_WellHydrated.CalculateDuration` (merged here) |
| Skill trees | n/a |
| Port form | `food/foodEffects.ws`: `W3Effect_WellFed` and `W3Effect_WellHydrated` keep 5.x's parent `W3RegenEffect` (a mod cannot change a class's parent) and override the inherited `OnUpdate` to clear their own regen value before the regen effect's update (ALCH's Tawny Owl pattern: the effect still ticks, counts down and keeps its ability on Geralt); a wrapper of `W3AbilityManager.OnAbilityChanged` that, when an ability with a Vitality or stamina regen stat changes on Geralt, restarts both auto regens through a timer (`GMRestartRegen`); DF6's rule in the replaced `CBaseGameplayEffect.CumulateWith` (`alchemy/potionRules.ws`, beside ALCH's DL12); 5.x's `W3Effect_WellHydrated.GetSelfInteraction` kept (the effect definitions give no level, so every drink cumulates); `W3Effect_Edible` left 5.x's (no item gives it) |
| Port status | **signed off** (2026-10-24); verified (slice 1, 2026-10-24, both trees) |
| Open checks | — |
| Save impact | none (expected): the effects are saved with their class, the methods read live |
| NG+ counterpart | none (scripts) |

**What it does:** food and drinks raise Geralt's own regeneration rates for their duration instead of running a regeneration of their own ("boosts existing autoregen effect instead of adding another one to avoid conflicts", legacy's comment). The auto regen reads the out-of-combat value out of combat and the combat value in combat, so the changelist's two numbers both act. In 1.32 (and 5.x, from the code) a food effect is a regen effect: it regenerates its first regen value (out of combat's, in combat too) and also adds its ability to Geralt, whose auto regen counts it again. When an ability changes a regen stat, legacy restarts the Vitality or stamina regen: legacy sets Geralt's base regen values to 0 (`geralt_stats.xml`, with its regen options: GEN, OPT), so the auto regen may not be running until food, or anything else, gives some. Legacy's Well Hydrated borrows Well Fed's level rule but casts the other effect to `W3Effect_WellFed`, which a Well Hydrated effect is not: from the code, every new drink replaces the Well Hydrated already active, a lower tier included (Well Fed refuses a lower tier while a higher one lasts and refreshes on an equal or higher one).

**Implementation (legacy):** the parent of `W3Effect_WellFed`, `W3Effect_WellHydrated` and `W3Effect_Edible` (no unit; `EdibleEffect` is given by no item, so the last is inert); `W3AbilityManager.OnAbilityChanged`; `W3Effect_WellHydrated.GetSelfInteraction` and its removed `CacheSettings`.

**5.x:** 1.32's classes; `SetEffectValue` added on both effects (Dumplings' multiplier, removed by ENCH-06); Well Fed's `Init` sets the length from Gourmand (FOOD-06).

**Decisions:** legacy's model, food adding to Geralt's regen with no separate heal (DF3, project owner, 2026-10-24). DF6 changed from the mapping's recommendation (project owner, 2026-10-24): legacy's bug fixed as ALCH's potion stacking (DL12).

- **Deviation:** a weaker drink drunk while a stronger Well Hydrated lasts adds its time and the stronger tier stays; an equal or stronger drink refreshes it to the new drink (60 s, its tier). Legacy's code let every new drink replace the running one, a weaker one included, so water drunk after a wine lowered Well Hydrated to tier 1 (the owner's DF6, confirmed by the owner, 2026-10-24). How it played in legacy stays on the [list to test](../open-questions.md#to-test-in-legacy-ghost-mode).
- **Deviation:** the restart of the auto regen when a regen ability changes applies to Geralt only and happens a frame later (a timer); legacy restarted it at once for every actor. Geralt is the only actor whose base regen Ghost Mode zeroes, the timer keeps the restart out of the effect manager's own update (an effect with a regen ability ending), and a frame's delay is invisible in play (confirmed by the owner, 2026-10-24; audit F6).

**Verification (slice 1, 2026-10-24, both trees):** scripted (`GMTest_food`, `GMTest_food_after`, in the regression): the effect values (60 s every tier; food 10/20/30 and 1/5/10; drinks 5/10/20, 1/5/10 and 1/2/3% stamina; Cornucopia 30 s at 15); Bottled water gives Well Hydrated and Bread Well Fed (`GetItemBuffs`); Well Fed refuses a weaker food while a stronger lasts and an equal one refreshes it; Well Hydrated 3 then 1 then 2: 60 → 120 → 180 s, tier 3 kept, only its ability on Geralt; Well Hydrated 1 then 2: tier 2, 60 s; with Well Fed 3 and Well Hydrated 2 their abilities are on Geralt, his stamina regen +2% and the two effects' own regen value 0 after their updates. Real actions (the drink key's input event for quick slot 1, `gmtest_quickslot`, classic tree): a Bread eaten from the quick slot (4 → 3) gave Well Fed 1 for 60 s and raised Geralt's regen from 1/1 to 11/2 per second (out of combat/combat); at half Vitality it rose 11 per second (1763.9 → 1806.4 in 3.9 s: 10 from the bread, nothing from the effect itself); Bottled water (still 5.x's tier 2 until slice 2) added Well Hydrated 2 for 60 s, regen 21/7 and stamina regen mult 0.15 → 0.17. Not tested: a real fight with food (the combat value read only from the attribute), Cornucopia in play. The three regen-model checks in `gmtest_panel()` failed from slice 3 on (FOOD-05 to FOOD-07's checks cleared their setup) until the audit's fix (5.x-GM `296bde53`, [F2](#food-audit-2026-10-24)); they pass since, both trees.

### FOOD-04 Food and drink items

| | |
|---|---|
| Kind | content |
| Pillars | P6, P8 |
| 5.x class | clean |
| Flags | balance, needs-decision (DF4, DF9) |
| Depends on | FOOD-01, FOOD-02, FOOD-05 (the toxicity abilities), CRAFT-07 (the two alcohols' roles, Wolf liver's category, signed off), ITEM (`item_layer.py`, `gen_item.py`) |
| Skill trees | n/a |
| Port form | FOOD-04's fields in `item_layer.py` (tags other than `mod_*`, `base_abilities`, `stackable`; Wolf liver's category, description and dismantling parts, which legacy changed by moving it from the ingredients to the food: its ingredient unit, CRAFT-07's and CRAFT-08's, shares the name with its food unit, so FOOD-04 carries them, audit F1), written by `gen_item.py` into `gm_item.xml`, each item defined once (DF9); `KEEP_5X`'s Free nilfgaardian lemon entry removed; the toxicity abilities the items name in `gm_food.xml` (FOOD-05's data, added with the items); the two new dishes are written with FOOD-07 (`gen_item.py` writes a new item once all its features are ported) |
| Port status | **signed off** (2026-10-24); verified (slice 2, 2026-10-24, both trees; Wolf liver as food: audit fix slice A, 2026-10-24, both trees) |
| Open checks | — |
| Save impact | none (expected): item definitions are read live (verified for item fields by ARM-01) |
| NG+ counterpart | applied, untested |

**What it does** (changelist 841, "reworked in terms of quality"): every food and drink gets a tier by how prepared it is, and a matching rarity colour (tier 2 Master, tier 3 Magic):

| Effect | Legacy's items |
|---|---|
| Well Fed 1 | raw produce and sweets: Apple, Banana, Bell pepper, Blueberries, Candy, Cucumber, Egg, Grapes, Honeycomb, Mushroom, Olive, Onion, Pear, Pepper, Plum, Potatoes, Raspberries, Strawberries, Toffee, Vinegar, the burned bread and bun, Brioche, Cookies, Ginger Bread, Tomato, Magic food; Fish (raw, toxic) |
| Well Fed 2 | simple food: Baked apple, Baked potato, Bread, Bun, Butter Bandalura, Cheese, Chips, Dried fruit (and nuts), Dumpling, Camembert, Chocolate souffle, Crossaint honey, Flamiche, Herb toasts, Onion soup, Ratatouille, Tarte tatin; raw meat (toxic): Chicken, Chicken leg, Gutted fish, Mutton leg, Pork, Raw meat, Wolf liver, Pheasant gutted |
| Well Fed 3 | cooked dishes: Roasted chicken (and leg), the chicken, grilled chicken and ham sandwiches, Fried fish, Fried meat, Fondue, Grilled pork, Mutton curry, Very good honey, the free roasted chicken leg, Blood and Wine's Baguette camembert, Baguette fish paste, Boeuf bourguignon, Confit de canard, Fish tarte, Ham roasted, Pate chicken livers, Rillettes porc; the new Sausages and Scrambled eggs (cooked only, FOOD-07) |
| Well Hydrated 1 | Bottled water, Tirnalia potion; Magic Mushrooms and Poison Apple (alcohol) |
| Well Hydrated 2 | Apple juice, Raspberry juice; beers (alcohol): Kaedwenian Stout, Redanian Lager, Rivian Kriek, Viziman Champion |
| Well Hydrated 3 | Cows milk, Goats milk; wines and spirits (strong alcohol): Beauclair White, Dijkstra Dry, Erveluce, Est Est, Mettina Rose, Free nilfgaardian lemon, Soltis Vodka, Blood and Wine's 13 wines |

(1.32: 22 foods at tier 3 including raw chicken, fish and pork; 23 alcoholic drinks at tier 1, among them every wine but one.) Every drink stacks to 100 (1.32: 5 to 40). The `Potion` tag is removed from Kaedwenian Stout, Redanian Lager, Rivian Kriek, Raspberry juice, Magic Mushrooms, Poison Apple and Cornucopia (it made the tooltip treat them as potions). Hearts of Stone's Soltis Vodka (an endless carafe) becomes a drink (Well Hydrated 3, strong alcohol); the Free nilfgaardian lemon, which 1.32 had as the potion-refill alcohol, becomes a strong drink (CRAFT-07 made the swap, FOOD gives it its drink); Local pepper vodka loses its drink abilities (CRAFT-07, ported). Wolf liver moves from the ingredients to food (raw, Well Fed 2, the food description, no dismantling parts). Two new dishes, "Sausages" and "Scrambled eggs" (`Sausages Mod`, `Scrambled Eggs Mod`, Well Fed 3, cooking only).

**Implementation (legacy):** 54 items of `def_item_edibles.xml` (base, 3 of them new) and 35 of Blood and Wine, 2 Hearts of Stone quest items, regular and NG+ (items changed only in price or weight are ECON's and WGT's); the Bell pepper's icon fix (also 5.x's, nothing to port).

**5.x:** the items as 1.32 (Tirnalia potion's tag and Bell pepper's name and icon aside).

**Decisions:** legacy's tiers, rarities, tags and stacks (DF4), through the item layer (DF9) (project owner, 2026-10-24). Ends CRAFT-07's lemon deviation.

**Verification (slice 2, 2026-10-24, both trees):** `gen_item.py --verify` 0 unexplained (the 29 new cooking items counted as FOOD-07 not ported yet); scripted (`GMTest_food04`, in the regression): 13 items read as legacy's (effect and tier, toxicity, quality, a tag): Apple Well Fed 1, Bread 2, Chicken and Wolf liver 2 with 5 toxicity and `Uncooked`, Roasted chicken 3 (quality 3), Bottled water Well Hydrated 1, Apple juice 2, Kaedwenian Stout 2 with 5 toxicity and no `Potion` tag, Cows milk 3, Est Est, the Free nilfgaardian lemon and Soltis Vodka 3 with 10 toxicity (Soltis Vodka quality 4), Cornucopia without `Potion`. Real actions (quick slot 1 through the drink key's input event, classic tree): Est Est drunk on a running Well Hydrated 2 raised it to tier 3 for 60 s, cost 10 toxicity and made Geralt drunk (5.x's code and 30 s until slice 3); a raw Chicken eaten on a running Well Fed 3 was consumed and refused (Well Fed's rule). Stack sizes checked by `gen_item.py --verify` only.

**Verification (audit fix slice A, 2026-10-24, both trees; 5.x-GM `3c21723c`):** `gen_item.py --verify` 0 unexplained (Wolf liver's category, description and parts legacy's); scripted (`GMTest_food04eat`, in the regression): all 109 of legacy's foods and drinks (every item of legacy's `def_item_edibles.xml`, base and Blood and Wine, with a food or drink quality ability, Soltis Vodka and Cornucopia) pass `ConsumeItem`'s category test and give their effect when eaten through it; a Wolf liver eaten: category `edibles`, no dismantling parts, Well Fed 2 for 60 s, 5 toxicity, not drunk. Real action (quick slot 1 through the drink key's input event, classic tree): a Wolf liver eaten (1 → 0), Well Fed 2 for 60 s, 5 toxicity.

**Fix round fix3 (2026-11-02, sweep D G6; the owner's decision): Wolf liver stays in its quick slot after a load.** 5.x's `HACK_UnequipWolfLiver`, which every load runs from `OnSpawned`, took Wolf liver out of the potion and food quick slots together with whatever was in the paired slot (1 and 3, or 2 and 4); legacy disabled it once Wolf liver became food. An empty `@replaceMethod` (`food/foodEffects.ws`). **verified on the area build** (2026-11-02, gm/fix3 `51bce9eb`, both trees): `GMTest_food04_liverslot` (regression, scripted): Wolf liver in slot 1 and a Bread in slot 3, then the function the load calls: both stay; it failed first on a throwaway build with b3ec3609's code and data (gm/fix3-ff `efa40f24`, classic tree; the code checks also in the new tree) (both taken out).


### FOOD-05 Alcohol, raw food and drunkenness

| | |
|---|---|
| Kind | system, tuning |
| Pillars | P8, P2 |
| 5.x class | clean (data); conflict (5.x's `ConsumeItem`) |
| Flags | balance, needs-decision (DF5) |
| Depends on | ALCH-01 (legacy's toxicity, threshold and decay, signed off), SKL-18 (Metabolism Boosts' `ToxicityLowEnoughToDrinkPotion`, signed off), ALCH-02 (the drinking wrapper), FOOD-04, FOOD-06 |
| Skill trees | n/a (Connoisseur's exemption is FOOD-06) |
| Port form | the three toxicity abilities (with slice 2) and `DrunkennessEffect` in `gm_food.xml` (`gen_food.py`); `food/toxicity.ws`: `@replaceMethod CR4Player.ConsumeItem` (5.x's body, its diving check and inert Cat branch kept, legacy's lines), `GMHasConnoisseur` (`perk_15` or `perk_41`) and `GMFoodTooToxic` on `W3PlayerWitcher`, a wrapper of `W3InventoryItemContext.HandleUserFeedback` that refuses before the menu's use; ALCH-02's `DrinkPotionFromSlot` wrapper (`alchemy/potionRules.ws`) extended with the quick slot's refusal |
| Port status | **signed off** (2026-10-24); verified (slice 3, 2026-10-24, both trees; the inventory's refusal not seen) |
| Open checks | — |
| Save impact | none (expected) |
| NG+ counterpart | applied, untested |

**What it does:** alcohol and raw food cost toxicity: beer and other mild alcohol 5 (`alco_toxicity`; 1.32: 0), wine and spirits 10 (`alco_toxicity_strong`), raw meat and fish 5 (`food_toxicity`, items tagged `Uncooked`); the Poison Apple 20 (its own 15 plus 5). With too little free toxicity Geralt refuses them, from the quick slot ("toxicity too high") and from the inventory (the current toxicity shown), as for potions. Alcohol makes Geralt drunk for 60 s (1.32: 30 s); raw food does not. The changelist names none of this except through Connoisseur (461–462).

**Implementation (legacy):** `alco_toxicity` (5, duration 0), `alco_toxicity_strong`, `food_toxicity`, `DrunkennessEffect`; `ConsumeItem` (toxicity and drunkenness without Connoisseur, `Uncooked` added, the buff source `"alcohol"` for FOOD-06), `DrinkPotionFromSlot` (the refusal; its no-drinking-mid-attack check is ALCH-02's, ported), `HandleUserFeedback` (the inventory's refusal).

**5.x:** 1.32's: alcohol adds its (zero) toxicity and makes Geralt drunk; no raw-food toxicity.

**Decisions:** legacy's toxicity and 60 s drunkenness (DF5, project owner, 2026-10-24). The inventory's refusal skips the context menu's base handling for that key press (the wrapper returns before 5.x's method; legacy refused after it): nothing else is done on a refused press.

**Verification (slice 3, 2026-10-24, both trees):** scripted (`GMTest_food05`, in the regression, through `ConsumeItem`): drunkenness 60 s; a raw Chicken costs 5 toxicity, no drunkenness; Est Est costs 10 and makes Geralt drunk for 60 s, its Well Hydrated from the source "alcohol"; a Bread costs nothing (source "edible"); at 99 toxicity a beer is refused and a Bread is not. Real actions (quick slot 1 through the drink key's input event, classic tree): at 99 toxicity Est Est and Raw meat were refused (kept: 1 → 1) and a Bread eaten; at 0 a Kaedwenian Stout drunk: Well Hydrated 2 (source "alcohol"), 5 toxicity, drunk 60 s. Not tested: the inventory's refusal on screen (the wrapper of the context menu's use).

### FOOD-06 Connoisseur

| | |
|---|---|
| Kind | system |
| Pillars | P8, P7 |
| 5.x class | clean (classic `perk_15`); rethink (new tree: Gourmand `perk_41`) |
| Flags | needs-decision (DF7) |
| Depends on | SKL-18 (perk slots, tree profiles, signed off), SKL-19 (descriptions, signed off), FOOD-03, FOOD-05, FOOD-08 |
| Skill trees | both: classic `perk_15` (5.x: Gourmet), new `perk_41` (5.x: Gourmand), 1 level in both (D41, D49) |
| Port form | `perk_15` and `perk_41` given whole as legacy's ability (`duration_bonus` 1.0, `on_conflict="replace"`) in `gm_skill_trees.xml`, `perk_41` named Connoisseur in the new tree (`localisationName`); `food/connoisseur.ws`: `GMConnoisseurDurationBonus` (the equipped one's), `W3Effect_WellFed`'s `Init` (Gourmand's length removed), `CalculateDuration` (an alcohol's effects +100%), `OnPerk15Unequipped` (the share of time kept), `OnPerk41Updated` (nothing) and `OnPerk41Unequipped` (as `perk_15`) replaced, a wrapper of `W3PlayerAbilityManager.OnSkillUnequip` for Well Hydrated's share; Well Hydrated's `CalculateDuration` (ENCH-06's replacement in `enchantments/preservationDumplings.ws`) with the bonus; `GMHasConnoisseur` (slice 3) for the toxicity rules; the description on both perks (`skillDescriptions.ws`); legacy's strings 2110992462 and 2110992463 (keys `skill_name_perk_15`, `skill_desc_perk_15`), 9 languages |
| Port status | **signed off** (2026-10-24); verified (slice 4, 2026-10-24, both trees) |
| Open checks | — |
| Save impact | none (expected): skill abilities are read live |
| NG+ counterpart | applied (legacy's NG+ ability), untested |

**What it does** (changelist 461–462): "Reduces alcohol and toxic food toxicity to zero. Removes drunken effect from alcohol. After drinking an alcoholic beverage, its bonuses last longer by 100%." It replaces Gourmet (food lasting 20 minutes). Only alcohol's effects last longer (the buff source `"alcohol"`); unequipping it keeps the share of time left of the active Well Fed and Well Hydrated (1.32 reset Well Fed to its initial length).

**Implementation (legacy):** `perk_15` (`duration` 1200 → `duration_bonus` 1.0), `W3Effect_WellFed` and `W3Effect_WellHydrated` `CalculateDuration` and `OnPerk15Unequipped`, `OnSkillUnequip`'s Perk 15 branch, the checks of FOOD-05, the tooltip of FOOD-08, the strings (SKL-19's rows).

**5.x:** classic Gourmet (20 minutes) and the new tree's Gourmand (300 s per level, ending Well Fed when unequipped).

**Decisions:** legacy's Connoisseur in both trees (D41, project owner, 2026-10-11), 1 level, 5.x's Gourmet and Gourmand mechanics removed (DF7, project owner, 2026-10-24). Ends SKL-18's Gourmand deviation. 5.x's `W3Effect_WellFed.OnEffectRemoved` still removes a `GourmetEffect` ability no data gives (inert, left).

**Verification (slice 4, 2026-10-24, both trees):** scripted (`GMTest_food06`, in the regression; the perk of the tree in force, equipped by script and taken off): the data (+100% on both perks, no `duration`); the perk named "Connoisseur" with legacy's text and 100%; with it equipped Est Est and a raw Chicken cost no toxicity and no drunkenness, the wine's Well Hydrated lasts 120 s and the Chicken's Well Fed 60 s; taken off, the wine's Well Hydrated keeps its share (60 s of 60) and Well Fed stays (5.x's Gourmand ended it). Real actions (the perk equipped with the console's `skilleq`, the drinks from quick slot 1 through the drink key's input event): classic `perk_15`: a Kaedwenian Stout gave Well Hydrated 2 for 120 s at 0 toxicity, Raw meat Well Fed 2 for 60 s at 0; new tree `perk_41`: Est Est gave Well Hydrated 3 for 120 s at 0 toxicity. Not tested: the perk equipped and its text read in the character menu on screen.

### FOOD-07 Cooking

| | |
|---|---|
| Kind | content, system |
| Pillars | P8, P6 |
| 5.x class | clean |
| Flags | balance, needs-decision (DF8, Q1) |
| Depends on | FOOD-04 (the dishes), LOOT-01 (the shop lists, signed off), CRAFT (the alchemy menu and recipe handling), SKL-16 (Acquired Tolerance counts only potion, bomb, oil, substance and mutagen recipes: legacy's rule, ported, so cooking recipes do not count) |
| Skill trees | n/a |
| Port form | the 27 recipe items and their `<alchemy_recipes>` entries as new entries in `gm_food.xml` (`gen_food.py`; a DLC can add alchemy recipes; the recipe items take Q1's names), the names in a generated string table (`localization/modGhostModeFood`, ids 2110992639–2110992665); the two new dishes through `gen_item.py` (new items once FOOD-07 is ported; `item_layer.ELSEWHERE` leaves the recipe items to `gen_food.py`); `food/cooking.ws`: `EACIT_Edibles` (enum extension), wrappers of `AlchemyCookedItemTypeStringToEnum`, `...EnumToName`, `...ToLocKey`, `@replaceMethod W3AlchemyManager.CookItem` (5.x's body with its oil re-application, legacy's quantity line), `gmaddrecipesedibles`; the shop lists regenerated by `gen_loot.py` (its unknown-recipe rule now drops nothing) |
| Port status | **signed off** (2026-10-24); verified (slice 6, 2026-10-24, both trees) |
| Open checks | — |
| Save impact | none (expected): recipes are read from the definitions; known recipes are saved by name |
| NG+ counterpart | applied, untested |

**What it does** (changelist 839–840, "original idea by FreeSergey, recipes by delamer"): 27 cooking recipes, bought from innkeepers (16 inn and tavern lists, from White Orchard to Skellige and Blood and Wine) and Blood and Wine's butcher, cooked in the alchemy menu under their own group ("Edibles"), each in one level: raw to cooked (Chicken leg ×2 from a Chicken; Gutted fish from a Fish; Roasted chicken, Fried fish, Fried meat, Grilled pork from the raw meat with an Onion and a Pepper; Mutton curry with a Bell pepper), sandwiches ×2 (Chicken, Grilled chicken, Ham), Fondue (Cheese and Dijkstra Dry), Baked apple, Baked potato, Sausages ×3 (Chicken, Wolf liver, Raw meat, Onion, Pepper), Scrambled eggs (2 Eggs, Cheese), Apple and Raspberry juice (2 fruits and an Empty bottle), and Blood and Wine's Chocolate souffle, Crossaint honey, Flamiche ×2, Onion soup ×2, Ratatouille ×2, Tarte tatin, Baguette camembert, Boeuf bourguignon, Fish tarte. Cooking turns tier 2 raw food (toxic) into tier 3 dishes. A 28th recipe, Butter Bandalura, is commented out in legacy's data (the debug command still names it). The recipe items use the dish's own name key and the food description (Q1).

**Implementation (legacy):** `def_item_cooking_recipes.xml`: 27 recipe items (`alchemy_recipe`, prices 10 and 20) and an `<alchemy_recipes>` block of 27 recipes (`cookedItemType="edibles"`), regular and NG+; `EAlchemyCookedItemType` (`EACIT_Edibles`) and `AlchemyCookedItemTypeStringToEnum`, `...EnumToName`, `...ToLocKey` (`item_category_edibles`); `CookItem` (the cooked quantity: 1.32 reads the item's `ammo`, which food lacks); `addrecipesedibles`.

**5.x:** the cooking file unchanged (the two quest recipes); the alchemy menu groups recipes by `AlchemyCookedItemTypeEnumToName` and titles the group by `AlchemyCookedItemTypeToLocKey`; 5.x's recipe counters for achievements count named types only, and Acquired Tolerance counts legacy's whitelist in the port (SKL-16), so cooking recipes count for neither.

**Decisions:** cooking as legacy, its own alchemy group, sold where legacy's lists say, Butter Bandalura left out (DF8, project owner, 2026-10-24). Ends LOOT-01's deviation (innkeepers and butchers without the recipes).

- **Deviation:** the cooking recipe items are named "Recipe: <dish>" (vanilla's pattern for its two quest cooking recipes, `item_name_recipe_for_scrambled_eggs`: "Recipe: Scrambled eggs"; the prefix and the dish's casing taken from vanilla's tables in each of the 9 languages) with vanilla's recipe description (`item_desc_recipe_food`); legacy's recipe items used the dish's own name and the food description, so a shop listed "Baked apple" with a recipe icon (the owner's Q1, confirmed by the owner, 2026-10-24).

**Verification (slice 6, 2026-10-24, both trees):** `gen_food.py --verify` (27 recipes per folder equal to legacy's, the recipe items legacy's with Q1's two keys, the string tables current), `gen_item.py --verify` and `gen_loot.py --verify` 0 unexplained; scripted (`GMTest_food07`, in the regression): 27 recipes of the type edibles; Recipe for Chicken leg makes 2 Chicken legs, group "Food and drink"; no Butter Bandalura recipe; the recipe item named "Recipe: Baked apple"; cooking a Chicken through the alchemy manager gives 2 Chicken legs. Real actions (classic tree): Blood and Wine's crossing innkeeper (`shop_02_crossing_innkeeper.w2ent`, spawned) stocked 11 cooking recipes; Recipe for Onion soup bought through the shop menu's own buy event (250 → 240 crowns); read (`ReadSchematicsAndRecipes`, as the inventory's use does); the alchemy menu showed a "Food and drink" group with Onion soup, and a mouse click on Craft Item cooked 2 Onion soups from an Onion, Olives, a Brioche and Cheese. Screenshots: the shop's recipe tooltip ("Recipe: Apple juice", its Well Hydrated values and ingredients), a wine's tooltip (Duke Nicolas Chardonnay: 10 toxicity, regen, 60 s, Magic item), the cooking group in the alchemy menu. Not tested: a White Orchard or Novigrad inn's stock (their lists come from the same generator), the alchemy menu's info panel for a dish shows only its description (5.x's panel), the 62-kinds roll limit on the inn lists with the recipes added ([loot.md](loot.md) records the limit).

### FOOD-08 Edible tooltip

| | |
|---|---|
| Kind | ui |
| Pillars | P7 |
| 5.x class | clean |
| Flags | — |
| Depends on | FOOD-06, ENCH-06, ALCH-17's `AddBuffStats` wrapper (signed off) |
| Skill trees | n/a |
| Port form | `food/tooltip.ws`: `@replaceMethod W3TooltipComponent.AddBuffStats` (5.x's body: Connoisseur's +100% on an alcohol, Dumplings on every edible, the in-combat regen row's label through `GMFoodCombatRegenLabel`); ALCH-17's wrapper of the same method still sets a potion's duration |
| Port status | **signed off** (2026-10-24); verified (slice 5, 2026-10-24, both trees; scripted) |
| Open checks | — |
| Save impact | none |
| NG+ counterpart | none |

**What it does:** a food or drink tooltip shows its effect's length: with Dumplings, the longer length in orange on every edible (1.32 and 5.x: only for one in a quick slot); with Connoisseur, an alcohol's length doubled. Its in-combat regen row reads "Vitality regeneration during combat" (legacy's string 2110992157, key `attribute_name_vitalityCombatRegen`, added by legacy with the row: UI-07); 5.x shows the game's label for that attribute, which counts per enemy killed. Legacy's string `attribute_name_staminaRestore` (2110992352, "Stamina") is read by no script or data of legacy: dropped (UI's hand-off).

**Implementation (legacy):** `W3TooltipComponent.AddBuffStats` (its potion part is ALCH-17's, ported).

**5.x:** 1.32's.

**Decisions:** port as legacy; ends ENCH-06's temporary deviation (the tooltip only for a quick-slot edible). The in-combat regen row named by legacy's string (audit F4, project owner, 2026-10-24): legacy added the string and the row, but its tooltip looked the label up under other keys (`AddItemStats` names `vitalityCombatRegen` by `panel_common_statistics_tooltip_incombat_regen`; `GetAttributeNameLocStr` lower-cases the key), so legacy's label most likely never showed; the port shows it on food and drink tooltips (potions and gear keep the game's label).

**Verification (slice 5, 2026-10-24, both trees):** scripted (`gmtest_food08`, the tooltips as the inventory builds them, `GetBaseItemData`, with the HUD): a Bread and Est Est show 60 s; with Connoisseur (classic `perk_15`, new tree `perk_41`) Est Est 120 s and the Bread 60 s; with Dumplings on the sheathed silver sword a Bread in the bag (not a quick slot) shows an orange 120 s and Est Est 240 s. Not a regression check (it needs the HUD). The tooltip on screen: see FOOD-07's screenshots. Audit F4 (2026-10-24, both trees, scripted, `gmtest_food08`): a Bread's and Est Est's in-combat regen row reads "Vitality regeneration during combat" (legacy's string 2110992157); not seen on screen.

### FOOD audit (2026-10-24)

Done by a fresh session ([audit](../feature-mapping.md#audit-signing-a-feature-off)) on 5.x-GM `545e3d1e` (then `296bde53`, two test-only commits made with it) and master `2654490a`, reading code and data, with game runs for the regression and two checks. Every script unit [attribution.csv](attribution.csv) gives FOOD (18) was read against legacy's code (`legacy-GM`), 1.32 and 5.x. The final data as the game reads it was compared with legacy's by a script written for this audit, independently of `gen_food.py --verify`: every `<item>`, `<ability>` and `<recipe>` entry of legacy's `def_item_edibles.xml` (base and Blood and Wine), `def_item_cooking_recipes.xml` and Hearts of Stone's `def_item_quest.xml`, and the entries legacy changed in `effects.xml` (base and Hearts of Stone), both folders (790 entries), against the port's effective entry (Ghost Mode's DLC entry, else the game file's in 5.x-GM), attribute by attribute and child by child (comments dropped, attribute order ignored); Connoisseur's two abilities against legacy's `perk_15`.

**Checked and holding:** the food and drink items' tiers, rarities, tags other than `mod_*`, toxicity abilities, stack sizes and the seven `Potion` tags removed; Soltis Vodka and Cornucopia; every food, drink, toxicity and drunkenness ability (`FoodEdibleQuality_*`, `BeverageQuality_*`, `WellFedEffect_*`, `WellHydratedEffect_*`, `WellFedEffect_Cornucopia`, `alco_toxicity*`, `food_toxicity`, `DrunkennessEffect`); the 27 cooking recipes (30 per folder with 5.x's own, all equal to legacy's) and their items apart from Q1's names; `perk_15` and `perk_41` (`duration_bonus` 1.0). The differences by design: prices and weights (224 entries, ECON and WGT), the Bell pepper's name key (5.x's, kept), Q1's recipe names (a deviation confirmed by the owner); the other `effects.xml` and quest-item differences are other areas' (EFX, ALCH, SKL, ENCH; `ep1_poi_12_note_b`'s tag, CRAFT's hand-off). Apart from F1, nothing differs. Scripts: `ConsumeItem` (legacy's toxicity, drunkenness and source name on 5.x's body, its diving check kept, Connoisseur from either perk), the quick slot and inventory refusals, `CookItem` (legacy's quantity line on 5.x's body), the three cooked-type functions, the Connoisseur methods (duration, the unequip share for Well Fed and Well Hydrated, 5.x's Gourmand gone, `OnSkillUnequip`'s Well Hydrated branch), `AddBuffStats` (legacy's two changes on 5.x's body), DF6's branch in `CumulateWith`, the regen model (F6). Both trees: Connoisseur is read from the equipped perk everywhere (`GMHasConnoisseur`, `GMConnoisseurDurationBonus`); no tree-specific ID is hard-coded where the equipped one should be read; the checks ran in both trees. Owner's decisions as implemented: DF1 to DF10, Q1 and Q2 hold (DF4 apart from F1). The four temporary deviations FOOD ends are ended: SKL-18's Gourmand, CRAFT-07's lemon (`item_layer.KEEP_5X` empty, the lemon's drink abilities legacy's), LOOT-01's cooking recipes, ENCH-06's edible tooltip; [deviations.md](deviations.md) lists no deviation "until FOOD". Save impact as recorded: definitions and recipes are read live; a 5.x save with a running Gourmet or Gourmand Well Fed (20, or 5 to 15 minutes) keeps its saved length until it ends. `check_modsigns.py` 0 unmarked (410 bodies); `deviations.py --check` current (98); every generator's `--check` current (`gen_craft`, `gen_loot`, `gen_item`, `gen_arm_items`, `gen_swd_items`, `gen_ench`, `gen_alch`, `gen_arm_km`, `gen_arm_new`, `gen_ngplus`, `gen_npc_stamina`, `gen_food`); `gen_food`, `gen_item`, `gen_loot`, `gen_craft`, `gen_alch`, `gen_ench`, `gen_arm_items`, `gen_swd_items` `--verify` 0 unexplained. `unit_sweep.py --unattributed` (edible, food, drink, alcohol, cook, wellfed, hydrat, drunk, uncooked, perk_15, beverage, EACIT, gourmet, connoisseur, dumpling, cornucopia, soltis, vodka, toxicity, regen; scripts): no FOOD unit missing (the four hits are handed off: `enabledeletedscene` to MISC, the two Vitality regen options and `W3Effect_AutoVitalityRegen.SetEffectValue` to OPT and GEN). Regression after the audit's test fixes: 841 passed, 0 failed in each tree, ten runs in one launch with the panel's checks passing (F2, F3).

**Findings:**

1. **Wolf liver cannot be eaten** (clear fix; **fixed**, fix slice A, 5.x-GM `3c21723c`). Legacy moved it to the food file as `category="edibles"` with the food description (`legacy-GM` `gameplay/items/def_item_edibles.xml:1124`, both folders) and removed the ingredient entry; the port's entry (`gm_item.xml:19322`, both folders) has legacy's tags and abilities but 1.32's category `alchemy_ingredient`, description `item_desc_alchemy_ingredient` and dismantling parts (2 Raw meat; legacy: none). `ConsumeItem` gives effects and toxicity only to `edibles`, `Drinks` or an alcoholic ingredient, so a Wolf liver is used up for nothing. **Seen in game** (2026-10-24, classic tree, quick slot 1 through the drink key's input event, `gmtest_quickslot`): Wolf liver 1 → 0, no Well Fed, toxicity 0; a Raw meat right after gave Well Fed 2 for 60 s and 5 toxicity. As an alchemy ingredient with parts, the Alchemy dismantle kit (CRAFT-09) also turns one into 2 Raw meat. Cause: `item_layer.py` gives CRAFT-07 the category and description and CRAFT-08 the parts on the ingredient unit, which legacy deleted, so neither applies; FOOD-04's food unit owns only the abilities, tags and stack. The docs said CRAFT-07 moved the entry. Fix: FOOD-04 takes legacy's category, description and (no) parts for its food entry (`item_layer.py`), regenerate, a check that eats it through `ConsumeItem`.
2. **The panel's three FOOD-03 checks failed in every panel run** (clear fix, test-only; **made**). `GMTest_food_after` (in `gmtest_panel()`) reads the Well Fed 3 and Well Hydrated 2 that `GMTest_food03` set up, but FOOD-05 to FOOD-07's checks ran after it in `GMTest_food` and cleared them ("FAIL FOOD-03 the food and drink abilities are on Geralt", "FAIL FOOD-01 Geralt's stamina regen +0", seen after the regression and after the documented `gmtest_food()` order alike). 5.x-GM `296bde53`: the setup is `GMTest_food03_model`, run last; four panel runs passed, both trees.
3. **The game closing after the regression was LOOT's test rolls** (clear fix, test-only; **made**). Rolling loot lists into the spawned test merchant (`GMTestLootRoll`, Yoana's check) crashes the game with an access violation (exit code `0xC0000005`) seconds later, after about 8 to over 90 rolls in one launch; reproduced with `gmtest_loot()` alone and with a scratch roller, never with FOOD's checks. With Ghost Mode off, 45 rolls of 5.x's own lists did not crash (the lists differ, so a share of Ghost Mode's data or scripts is not ruled out; a real shop restocks once per visit from its own lists, and no crash in play has been seen). 5.x-GM `bbbbf9ee`: LOOT's checks left the regression (841 checks); `gmtest_loot()` runs once in a launch of its own (9 passed). Details: [game-automation.md](../game-automation.md#setting-up-geralt-and-the-world). FOOD's "one regression per launch" protocol is no longer needed.
4. **The food tooltips' combat regen label: legacy had a label of its own** (owner decision; **decided** 2026-10-24: legacy's string, made in FOOD-08's code, 5.x-GM `3c21723c`). Legacy added the tooltip row (`tooltip_settings.csv`) and the string 2110992157 `attribute_name_vitalityCombatRegen`, "Vitality regeneration during combat" (both UI-07, ported; `GMTest_ui06` reads the string by that key). The tooltip builds the key in lower case (`GetAttributeNameLocStr`: `attribute_name_vitalitycombatregen`) and shows the game's "per enemy killed during combat". So legacy meant its own label; whether legacy showed it depends on how the game matched the key, unknown. Recommendation: (b) of the [open question](../open-questions.md#legacy-design-intent), with legacy's existing string (no new strings), done with UI.
5. **A weaker drink over a stronger one takes the weaker drink's source** (no action). DF6's branch in `CumulateWith` keeps the stronger tier but sets `sourceName` to the new drink's and `initialDuration` to the summed length: after water tops up a wine lengthened by Connoisseur, unequipping Connoisseur no longer shortens it. ALCH's potion stacking (DL12) behaves the same. An edge without a player-visible cost.
6. **The regen restart deviation rests on a crash that LOOT's rolls may have caused** (owner decision; **decided** 2026-10-24: confirmed as it is, the crash dropped from its reason; FOOD-03). The recorded deviation (Geralt only, a frame later) and the code comment give as reason that legacy's immediate restart for every actor crashed the port's regression. The regression was crashing with the pre-FOOD build too (F3), so the evidence is doubtful. The port also starts both regens on any Vitality or stamina regen change (legacy: the matching one); starting a running regen does nothing and the auto regen stops itself at full, so nothing differs in play. Recommendation: confirm the deviation as it is (Geralt is the only actor whose base regen Ghost Mode zeroes; a frame's delay is invisible), and drop the crash from its reason unless a test shows it.
7. **The inventory refusal before 5.x's method** (no action; the porter's call answered, confirmed by the owner, 2026-10-24). The wrapper of `W3InventoryItemContext.HandleUserFeedback` refuses before the method; legacy refused inside it, after the base class's call (empty in 5.x) and the armor and weapon preview branch (no edible is armor or a weapon). Nothing else runs on a refused press in either, so it is not a deviation. The refusal was never seen on screen (F13).
8. **The slice order** (no action; the porter's call answered, confirmed by the owner, 2026-10-24). The two new dishes came with slice 6 instead of slice 2 (`gen_item.py` writes a new item once all its features are ported); FOOD-08 came before FOOD-07 as the port order says. No effect on the result.
9. **The debug command is `gmaddrecipesedibles`** (no action). Legacy's `addrecipesedibles` with the project's prefix, Butter Bandalura's recipe left out (DF8); recorded in FOOD-07's port form.
10. **Hand-offs** (doc corrections, made). ECON: Wolf liver and the Free nilfgaardian lemon keep 5.x's `mod_alchemy` price tag (legacy: `mod_food`), Local pepper vodka has `mod_food` (legacy: `mod_alchemy`); added to the [hand-off](#hand-off-to-other-areas) row. MISC: `enabledeletedscene` was handed to MISC but not listed there; added to [misc.md](misc.md). WGT: as recorded.
11. **Stale docs** (doc corrections, made). The status page had no FOOD row in its area table, still said FOOD is "being ported" and that CRAFT-07 made Wolf liver a food; FOOD-04's port form and the hand-offs table said CRAFT-07 moved Wolf liver; FOOD-03's verification did not say the panel checks failed; [development.md](../development.md#testing-in-game) and [game-automation.md](../game-automation.md) gave the one-call regression (LOOT's rolls inside, rw3d_cli's 500 ms wait); [loot.md](loot.md) put `GMTest_loot` in the regression.
12. **Regression gaps** (clear fix, with slice A; **fixed**, `GMTest_food04eat`, 5.x-GM `3c21723c`). Items are checked through `GetItemBuffs` (their abilities), not through `ConsumeItem`, so a food the game will not feed (F1) passes: a check that every legacy food and drink passes `ConsumeItem`'s category test, and one that eats Wolf liver. The panel's checks were broken unnoticed (F2): their FAIL lines come after the regression's SUMMARY, which does not count them, so read them. LOOT's checks now run outside the regression (F3).
13. **Not verified in game** (no action; open checks). As the entries list them: a real fight with food (the combat values read from the attribute only), Cornucopia and Soltis Vodka in play, the inventory's refusal on screen, a White Orchard or Novigrad inn's stock, Connoisseur in the character menu on screen, a real drink with Dumplings (ENCH-06's open check), NG+ (policy).

**Doc corrections made with the audit:** F3 ([game-automation.md](../game-automation.md#setting-up-geralt-and-the-world), [development.md](../development.md#testing-in-game), [loot.md](loot.md)), F10 (the [hand-off](#hand-off-to-other-areas) table, [misc.md](misc.md)), F11 (the [status page](README.md#where-the-port-stands), FOOD-03's verification, FOOD-04's port form, the hand-offs received, the port status line).

**Not reviewed:** nothing of FOOD. Out of scope: the other areas' entries in the shared files (EFX's and SKL's effects, the quest items), NG+ in game (the policy), prices and weights (ECON, WGT).

**Suggested fix slices** (each touching distinct files):

- **A, Wolf liver as food** (`tools/item_layer.py`, the `attribution.csv` notes of the two Wolf liver food units, the regenerated `gm_item.xml` in both folders, `tests/gmTestsFood.ws`): F1 and its checks (F12): legacy's category, description and no dismantling parts; a check eating it through `ConsumeItem` (Well Fed 2, 5 toxicity) and one over every legacy food and drink. No save impact (definitions are read live; a Wolf liver already held becomes edible).
- **Made with the audit** (tests only, 5.x-GM): `bbbbf9ee` (F3), `296bde53` (F2).
- **Owner decisions:** F4 (the tooltip label), F6 (the regen restart deviation): decided 2026-10-24.

#### Audit close-out

Closed 2026-10-24: every finding is fixed, recorded or decided by the owner. Fixed and verified in both trees: F1 and F12 (fix slice A: Wolf liver as food, `GMTest_food04eat` over all 109 of legacy's foods and drinks, 5.x-GM `3c21723c`), F2 and F3 (tests, 5.x-GM `296bde53`, `bbbbf9ee`). Recorded: F5, F9, F13 (no action), F10 and F11 (doc corrections). Decided by the owner (2026-10-24): F4 (the food and drink tooltips' in-combat regen row named by legacy's string 2110992157, made in FOOD's tooltip code, 5.x-GM `3c21723c`), F6 (the regen restart deviation confirmed as it is, Geralt only and a frame later, the crash dropped from its reason), F7 and F8 (the inventory refusal's order and the slice order confirmed, no change in play); legacy's every-actor regen restart is not to be re-tested in legacy. Checks at close: regression 843 passed, 0 failed in each tree, `gmtest_panel()`'s checks passing (LOOT's checks run apart); `gmtest_food08` 4 passed in each tree; `check_modsigns.py` 0 unmarked (410 bodies); every generator's `--check` current; `gen_item`, `gen_food`, `gen_loot`, `gen_craft`, `gen_alch`, `gen_ench`, `gen_arm_items`, `gen_swd_items` `--verify` 0 unexplained; no FOOD deviation left unconfirmed (`python tools/deviations.py --unconfirmed`). FOOD was **signed off** by the project owner (2026-10-24). What stays open: the open checks listed in the entries (F13: a real fight with food, Cornucopia and Soltis Vodka in play, the inventory's refusal and the in-combat regen label on screen, a White Orchard or Novigrad inn's stock, Connoisseur in the character menu on screen, a real drink with Dumplings, NG+).

### Dependencies on other areas

- **Done areas FOOD builds on:** ALCH (toxicity, the drinking wrapper, the potion tooltip wrapper, ALCH-07's Maribor rule), SKL (Connoisseur's slots and profiles, Metabolism Boosts' toxicity check, SKL-16's recipe whitelist, SKL-19's descriptions), ENCH-06 (Dumplings' replaced methods), CRAFT (`item_layer.py`, CRAFT-07's alcohols and Wolf liver), LOOT (`gen_loot.py`, the shop lists), ITEM (`gen_item.py`), STAM-04 (regen).
- **Areas FOOD shares with or waits for:** ECON (prices), WGT (weights), OPT and GEN (Geralt's base Vitality regen and its options).

### Hand-offs received

Every item other areas handed to FOOD, and where it lands:

| From | Item | FOOD |
|---|---|---|
| SKL-18, D41 (owner, 2026-10-11) | Connoisseur in both trees (`perk_15`, `perk_41`), its alcohol and raw-food toxicity | FOOD-06, FOOD-05 |
| SKL-18 deviation (until FOOD, owner 2026-10-16) | The new tree's Gourmand gives 5 minutes of Well Fed | FOOD-06 (ended 2026-10-24) |
| SKL-19 | Connoisseur's name and description | FOOD-06 |
| ALCH (hand-off) | Well Fed, Well Hydrated, drunkenness, alcohol and raw-food toxicity (`alco_toxicity*`, `food_toxicity`) | FOOD-01, FOOD-02, FOOD-05 |
| ALCH (hand-off) | `EACIT_Edibles`, `W3AlchemyManager.CookItem` | FOOD-07 |
| ALCH, CRAFT (hand-off) | The alcohol recipes (Mandrake cordial, Mahakam spirit) "with FOOD" | Nothing for FOOD: they brew refill alcohols, alchemy ingredients without a drink effect (CRAFT-06, ported) |
| CRAFT (hand-off) | The 27 cooking recipes and their items, `EACIT_Edibles` and its type functions, `CookItem`, `addrecipesedibles` | FOOD-07 |
| CRAFT (hand-off) | The two alcohols' drink effects; the Hearts of Stone vodka's drink abilities | FOOD-04 (the lemon and Soltis Vodka); Local pepper vodka has none (CRAFT-07) |
| CRAFT-07 deviation (until FOOD, owner 2026-10-23) | Free nilfgaardian lemon's drink abilities stay 5.x's (`KEEP_5X`) | FOOD-04 (ended 2026-10-24) |
| CRAFT-07 (found by this mapping) | Wolf liver with legacy's food tags and abilities in the port, `food_toxicity` undefined until FOOD (its category, description and parts had stayed 1.32's: audit F1, fixed) | FOOD-04 (since the audit, F1, also its category, description and no dismantling parts), FOOD-05 (defines it) |
| LOOT-01 deviation (until FOOD, owner 2026-10-21) | Innkeepers and butchers do not sell the cooking recipes | FOOD-07 (ended 2026-10-24) |
| LOOT (hand-off) | Food and drinks in the lists | Carried by LOOT (ported); FOOD decides the items (FOOD-04) |
| ENCH-06 deviation (until FOOD, owner 2026-10-19) | Dumplings' bonus only on a quick-slot edible's tooltip | FOOD-08 (ended 2026-10-24) |
| ENCH (hand-off) | Food and drink durations Dumplings multiplies; legacy's drinks giving Well Hydrated (needed for Dumplings' drink rule to act) | FOOD-01, FOOD-02 |
| ENCH (task list) | Preservation | Nothing for FOOD: Preservation (ENCH-06, ported) acts on the Armorer's Table and grindstone buffs |
| ENCH, SKL (hand-off) | `AddBuffStats`: Perk 15's alcohol duration, Runeword 6 on every edible | FOOD-08 |
| SKL (hand-off) | The `DrinkPotionFromSlot` alcohol and raw-food branch with Perk 15 | FOOD-05 |
| STAM (hand-off) | Drinks' stamina regen (`WellHydratedEffect_Level*`) | FOOD-01 |
| UI (hand-off) | `attribute_name_staminaRestore` (2110992352) | FOOD-08 (dropped: unused by legacy) |
| ITEM (hand-off "ALCH, FOOD") | Drinks' quality abilities | FOOD-04 (the Balisse fix went to LOOT-05) |
| feature-mapping (roadmap) | The `FOOD` area | this file |

### Hand-off to other areas

| Area | Changes |
|---|---|
| ECON | Food, drink and cooking recipe prices (the price-only units of `def_item_edibles.xml`, base and Blood and Wine, left unattributed; the new items' prices come with them), the `mod_food` tag and its modifier rows; the price tags of three moved items (audit F10): Wolf liver and the Free nilfgaardian lemon keep 5.x's `mod_alchemy` (legacy: `mod_food`), Local pepper vodka has `mod_food` (legacy: `mod_alchemy`) |
| WGT | Food and drink weights (0.05 to 0.1 for almost everything; 23 base and 2 Blood and Wine items changed only in price or weight; the Shani alcohols and flowers) |
| MISC | `enabledeletedscene` (debug command for a cut scene), unattributed; listed in [misc.md](misc.md) |

### Save impact

None expected: effect abilities, item definitions and recipes are read live; the food effects are saved with their 5.x classes, whose methods the port replaces. Facts for the release notes: the cooking recipe items and the two new dishes are new items; removing the mod (unsupported, [save compatibility](../feature-mapping.md#save-compatibility)) leaves them as unknown items and the learnt cooking recipes without a known type.

### Area decisions

**Decided** (project owner, 2026-10-24):

- **DF1:** legacy's food and drink numbers. **DF2:** drinks give Well Hydrated. **DF3:** food adds to Geralt's regen rates, with no separate heal. **DF4:** legacy's item tiers, rarities, tags and stacks. **DF5:** alcohol and raw-food toxicity, drunkenness for 60 s.
- **DF6, changed from the recommendation:** legacy's bug fixed: a weaker drink drunk over a stronger active Well Hydrated adds its time and keeps the stronger tier, matching ALCH's potion stacking (DL12); a deviation confirmed by the owner, the legacy test kept.
- **DF7:** Connoisseur at 1 level in both trees (classic `perk_15`, new tree `perk_41`), 5.x's Gourmet and Gourmand mechanics removed; ends SKL-18's 5-minute deviation.
- **DF8:** cooking as legacy: its own alchemy group, sold as legacy's lists say, Butter Bandalura left out; ends LOOT-01's cooking-recipe deviation.
- **DF9:** the item fields through `item_layer.py`, the rest by a new generator with `--verify` against legacy's data (`gen_food.py`). **DF10:** the boundary as mapped.
- **Q1:** the cooking recipe items are named "Recipe: <dish>" in all 9 languages (a deviation confirmed by the owner), reusing a vanilla recipe-name pattern if one exists.
- **Q2:** legacy's endless Soltis Vodka and Cornucopia kept; noted for the balance pass.

The questions as they were put (legacy behaviour first; where 5.x changed the same thing, the choice is named):

| # | Question | Options | Recommendation |
|---|---|---|---|
| DF1 | Well Fed's and Well Hydrated's numbers (FOOD-01); 5.x retuned Well Fed | (a) legacy's: 60 s for every tier, food 10/20/30 per second out of combat and 1/5/10 in combat, drinks 5/10/20 and 1/5/10 plus 1/2/3% stamina, Cornucopia 30 s at 15; (b) 5.x's Well Fed (30/60/60 s, 10/10/15 in and out of combat) with legacy's Well Hydrated | (a): legacy's tested balance; 5.x's version keeps food a strong in-combat heal |
| DF2 | Which effect drinks give (FOOD-02) | (a) legacy's: Well Hydrated, beside Well Fed; (b) 5.x's: Well Fed | (a): 5.x is 1.32 here; it gives drinks their stamina regen and makes ENCH-06's drink rule and ALCH-07's Maribor rule act |
| DF3 | How food regenerates (FOOD-03) | (a) legacy's: food raises Geralt's regen rates only (out-of-combat and combat values each in their mode), a regen ability restarts the regen; (b) 5.x's: a regen effect of its own, counted twice with the ability on Geralt | (a): legacy's fix of a double count; needed for the in-combat numbers of DF1 to mean anything |
| DF4 | The food and drink items (FOOD-04) | (a) legacy's tiers, rarities, tags, stacks for every item, Soltis Vodka a drink, Wolf liver a raw food, the two new dishes; (b) 5.x's items | (a): 5.x changed only the Tirnalia potion's tag (as legacy) and the Bell pepper's name and icon (kept) |
| DF5 | Alcohol and raw-food toxicity and drunkenness (FOOD-05) | (a) legacy's: 5 for beer, 10 for wine and spirits, 5 for raw meat and fish, refused when too toxic, drunk 60 s; (b) 5.x's (1.32's): no toxicity, drunk 30 s | (a): 5.x is 1.32 here; Connoisseur (D41) only means something with it |
| DF6 | A new drink while Well Hydrated lasts (FOOD-03) | (a) legacy's code: the newest drink always replaces it, a lower tier included; (b) Well Fed's rule: a lower tier is refused (and the item still consumed), an equal or higher one refreshes | (a): a side effect, not a defect that stops the feature; on the [list to test in legacy](../open-questions.md#to-test-in-legacy-ghost-mode) |
| DF7 | Connoisseur's details in both trees (FOOD-06; D41 decided) | (a) 5.x's Gourmand mechanics removed (food length per level, the unequip ending Well Fed), Connoisseur at 1 level in both trees, legacy's unequip rule (share of time kept); (b) Connoisseur's rules over 5.x's Gourmand hooks | (a): D41 and D49; ends SKL-18's deviation |
| DF8 | Cooking (FOOD-07) | (a) legacy's 27 recipes as a new alchemy type in the alchemy menu, cooked in the recipe's quantity, sold where legacy's lists say, Butter Bandalura left out as in legacy's data; (b) the recipes without the new type (e.g. as alcohol-type recipes) | (a): the port can extend the enum from its blob; (b) would mix food into the potion group |
| DF9 | Technique for FOOD's data | (a) FOOD's item fields in `item_layer.py` written by `gen_item.py` (each item defined once, CRAFT's DC5), the abilities, effects and recipes in a generated DLC file (`gen_food.py --verify` against legacy's data); (b) a separate DLC file with `extend` for the item fields | (a): the proven pattern; `extend` on `base_abilities` would collide with CRAFT's rarity blocks given whole |
| DF10 | The boundary | As in [Scope](#scope) | Confirm |

**Questions without a clear recommendation:**

| # | Question | Options | Notes |
|---|---|---|---|
| Q1 | The cooking recipe items' names and texts (FOOD-07) | (a) legacy's: each recipe item uses the dish's own name key and the food description, so a shop lists "Baked apple" with a recipe icon; (b) new "Recipe: <dish>" names and a recipe description (new strings in 9 languages) | Legacy first says (a); accurate texts (P7) say (b). The alchemy menu itself names the recipe by the dish either way |
| Q2 | Two endless items (FOOD-04, FOOD-06) | (a) legacy's: Soltis Vodka (endless) gives Well Hydrated 3 at 10 toxicity a sip, so with Connoisseur endless 120 s of Well Hydrated 3 at no cost; Cornucopia (endless) gives its 30 s Well Fed; (b) limit them (e.g. Soltis Vodka not a drink, as in 1.32 and 5.x) | Legacy's data; whether its author saw the Connoisseur combination is unknown. A balance question rather than a port one |

### Port order

Each slice compiles and is verified on its own, in both trees (the owner's instruction, 2026-10-24).

| # | Slice | Ends |
|---|---|---|
| 1 | FOOD-01, FOOD-02, FOOD-03: the effect values, drinks giving Well Hydrated, the regeneration model, `OnAbilityChanged`; `gen_food.py --verify` (**verified** 2026-10-24) | ENCH-06's open check (a real drink) becomes testable |
| 2 | FOOD-04: the items through the item layer (**verified** 2026-10-24; the two new dishes came with slice 6) | CRAFT-07's lemon deviation (`KEEP_5X`) |
| 3 | FOOD-05: toxicity, the refusals, drunkenness (**verified** 2026-10-24) | — (Wolf liver's `food_toxicity` defined) |
| 4 | FOOD-06: Connoisseur in both trees, its texts (**verified** 2026-10-24) | SKL-18's Gourmand deviation; SKL's last open item |
| 5 | FOOD-08: the edible tooltip (**verified** 2026-10-24) | ENCH-06's tooltip deviation |
| 6 | FOOD-07: cooking, the shop entries (`gen_loot.py`) (**verified** 2026-10-24) | LOOT-01's cooking-recipe deviation |

**Later:** —
