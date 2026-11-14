# FOOD: food, drinks, alcohol and cooking

What Geralt eats and drinks and what it does for him: the Well Fed and Well Hydrated effects (their length and regeneration), which item gives which (food tier, drink tier, rarity, tags, stack size), alcohol and raw food (toxicity, drunkenness), the Connoisseur perk (classic `perk_15`, new tree `perk_41`), cooking (27 recipes brewed in the alchemy menu) and the edible tooltip. Ghost Mode reworked food so it serves paced healing (P8) and scarce loot (P6): "Cooking recipes added: can be bought from innkeepers. Food and drinks reworked in terms of quality and availability in loot and shops. Well hydrated separate effect was restored. Well fed and well hydrated effects have fixed 60 sec duration for all tiers. Food of tier 1/2/3 now restore 10/20/30 hp/sec out of combat and 1/5/10 hp/sec in combat. Drinks now restore 5/10/20 hp/sec out of combat, 1/5/10 hp/sec in combat and 1/2/3 stamina/sec" (changelist 836–845); Connoisseur (461–462); Dumplings (959). Sources: those changelist lines, what SKL, ALCH, CRAFT, LOOT, ENCH, STAM, UI and ITEM left to FOOD, and the code, which has more than the changelist (toxicity amounts, the refusal when Geralt is too toxic, drunkenness, the regeneration model, the item tiers, the cooked quantities).

**What 5.x did in this area** (from `vanilla-5.x`). Well Fed's values changed (tiers 30/60/60 s, 10/10/15 Vitality per second in and out of combat; 1.32: 5/10/10 s, 50/50/80); Well Hydrated, drunkenness, the food and drink items, the cooking file and the toxicity code are 1.32's (two item edits: the Tirnalia potion tagged a drink, the Bell pepper's name and icon). The new tree's Gourmand (`perk_41`) makes food last 5 minutes per level and ends Well Fed when unequipped; the classic Gourmet (`perk_15`) makes it last 20 minutes. Dumplings (`Runeword 6`) also multiplies food and drink regeneration (removed by [ENCH-06](ench.md), DE2). 5.x's `ConsumeItem` refuses food while diving and has a branch for a Cat perk (`perk_29`) that no skill data defines (inert).

**How legacy Ghost Mode implements it.** Data: `def_item_edibles.xml` (base and Blood and Wine) and two Hearts of Stone quest items (`def_item_quest.xml`: Soltis Vodka, Cornucopia), the food effects in `effects.xml` (base and Hearts of Stone), the cooking recipes in `def_item_cooking_recipes.xml`, the Connoisseur ability (`geralt_skills_ep2.xml`, SKL-18), all with NG+ copies equal to the regular ones. Scripts: the food effect classes (`wellFed.ws`, `wellHydrated.ws`, `edible.ws`), `W3AbilityManager.OnAbilityChanged`, `CR4Player.ConsumeItem`, `W3PlayerWitcher.DrinkPotionFromSlot`, `W3InventoryItemContext.HandleUserFeedback`, `W3PlayerAbilityManager.OnSkillUnequip`, `W3TooltipComponent.AddBuffStats`, `W3AlchemyManager.CookItem` and `alchemyTypes.ws` (`EACIT_Edibles`), the debug command `addrecipesedibles`. Strings: Connoisseur's name and description (9 languages, SKL-19's rows) and one unused attribute name.

Unit lists: [attribution.csv](attribution.csv): **367 units** carry a FOOD feature (18 script units, 161 XML units and their 161 NG+ copies, 27 string rows); 33 of them are shared with SKL-18, SKL-19, ENCH-06, ALCH-02, ALCH-17, CRAFT-07 and CRAFT-08. Units whose only change is a price or a weight (23 food and drink items, the Shani alcohols and flowers, the `mod_food` price tag rows) are ECON's and WGT's. Three class declarations changed by legacy have no unit (the tool sees members, not a class's parent): `W3Effect_WellFed`, `W3Effect_WellHydrated` and `W3Effect_Edible` extend `CBaseGameplayEffect` instead of `W3RegenEffect` (FOOD-03).

**Status:** every feature ported and verified in both trees; the owner decided DF1 to DF10, Q1 and Q2 ([area decisions](#area-decisions)). Signed off by the owner (2026-10-24). Real actions were done through the drink key's input event for quick slot 1 (`gmtest_quickslot`); merchants were spawned from their entity files.

## Scope

**FOOD covers** the food effects (Well Fed, Well Hydrated, the Hearts of Stone Cornucopia's Well Fed) and how they regenerate; which item gives which effect (food and drink tiers), the food items' rarity, tags and stack size; alcohol and raw-food toxicity, the refusal to eat or drink when too toxic, drunkenness; Connoisseur in both trees; the cooking recipes, their items, the cooked item type and quantities; the edible tooltip.

**Not FOOD** (confirmed by the owner with DF10, 2026-10-24):

| Subject | Area | Why |
|---|---|---|
| Food, drink and cooking recipe prices, the `mod_food` price tag and its modifier rows (`economy_tagmodifiers.csv`) | ECON | Money (the new items carry legacy's price as part of their definition) |
| Food and drink weights | WGT | |
| Where food, drinks and recipes are sold and found ("availability in loot and shops", changelist 841) | LOOT | The lists are ported (LOOT-01, LOOT-05) |
| The refill alcohols (Local pepper vodka, Alcohest, Dwarven spirit, Mahakam spirit, Mandrake cordial, ...) and their recipes | CRAFT | Alchemy ingredients without a drink effect in 1.32, legacy and 5.x (CRAFT-06, CRAFT-07) |
| The general Vitality regen options (`GetCombatVitalityRegen`, `GetOutOfCombatVitalityRegen`) | OPT, GEN | Geralt's base regen, not food (OPT-02, OPT-03) |
| `enabledeletedscene` (a debug command setting `q401_cooking_enabled`, a cut Kaer Morhen scene) | MISC-03 (dropped) | A quest scene's debug command, not the food system |
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

### Classification and action

| # | Feature | Class | Action |
|---|---|---|---|
| FOOD-01 | Values | overlap (5.x retuned Well Fed) | Legacy's (DF1) |
| FOOD-02 | Drinks | clean | Legacy's (DF2); makes ENCH-06's drink rule and ALCH-07's Maribor rule act |
| FOOD-03 | Regen model | conflict (a class's parent cannot change by annotation) | Legacy's behaviour (DF3), re-implemented on 5.x's classes |
| FOOD-04 | Items | clean | Legacy's through the item layer (DF4, DF9) |
| FOOD-05 | Toxicity | clean (data), conflict (5.x's `ConsumeItem`) | Legacy's (DF5) |
| FOOD-06 | Connoisseur | rethink (new tree), clean (classic) | Legacy's in both trees (D41, DF7) |
| FOOD-07 | Cooking | clean | Legacy's (DF8) |
| FOOD-08 | Tooltip | clean | Legacy's |

---

### FOOD-01 Well Fed and Well Hydrated values

| | |
|---|---|
| Kind | tuning |
| Pillars | P8, P2 |
| 5.x class | overlap |
| Flags | balance |
| Depends on | FOOD-02 (drinks give Well Hydrated), FOOD-03 (how the values act) |
| Skill trees | n/a |
| Port form | the effect abilities in Ghost Mode's DLC (`on_conflict="replace"`, `gm_food.xml` written by `tools/gen_food.py`), regular and NG+ (legacy's NG+ values equal its regular ones) |
| Port status | **signed off** (2026-10-24); verified in both trees (with FOOD-03) |
| Open checks | a real fight with food (the combat values read from the attribute only); Cornucopia in play |
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
| Flags | — |
| Depends on | FOOD-01, ALCH-07 (Maribor Forest no longer cancels Well Hydrated), ENCH-06 (Dumplings on drinks) |
| Skill trees | n/a |
| Port form | `BeverageQuality_1` to `_3` in Ghost Mode's DLC (`replace`, `gen_food.py`), regular and NG+ |
| Port status | **signed off** (2026-10-24); verified in both trees (with FOOD-03) |
| Open checks | a real drink with Dumplings (ENCH-06's open check) |
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
| Flags | — |
| Depends on | FOOD-01, STAM-04 (stamina regen), ENCH-06's replaced `SetEffectValue` and `W3Effect_WellHydrated.CalculateDuration` (merged here) |
| Skill trees | n/a |
| Port form | `food/foodEffects.ws`: `W3Effect_WellFed` and `W3Effect_WellHydrated` keep 5.x's parent `W3RegenEffect` (a mod cannot change a class's parent) and override the inherited `OnUpdate` to clear their own regen value before the regen effect's update (ALCH's Tawny Owl pattern: the effect still ticks, counts down and keeps its ability on Geralt); a wrapper of `W3AbilityManager.OnAbilityChanged` that, when an ability with a Vitality or stamina regen stat changes on Geralt, restarts both auto regens through a timer (`GMRestartRegen`); DF6's rule in the replaced `CBaseGameplayEffect.CumulateWith` (`alchemy/potionRules.ws`, beside ALCH's DL12); 5.x's `W3Effect_WellHydrated.GetSelfInteraction` kept (the effect definitions give no level, so every drink cumulates); `W3Effect_Edible` left 5.x's (no item gives it) |
| Port status | **signed off** (2026-10-24); verified in both trees |
| Open checks | — |
| Save impact | none (expected): the effects are saved with their class, the methods read live |
| NG+ counterpart | none (scripts) |

**What it does:** food and drinks raise Geralt's own regeneration rates for their duration instead of running a regeneration of their own ("boosts existing autoregen effect instead of adding another one to avoid conflicts", legacy's comment). The auto regen reads the out-of-combat value out of combat and the combat value in combat, so the changelist's two numbers both act. In 1.32 (and 5.x, from the code) a food effect is a regen effect: it regenerates its first regen value (out of combat's, in combat too) and also adds its ability to Geralt, whose auto regen counts it again. When an ability changes a regen stat, legacy restarts the Vitality or stamina regen: legacy sets Geralt's base regen values to 0 (`geralt_stats.xml`, with its regen options: GEN, OPT), so the auto regen may not be running until food, or anything else, gives some. Legacy's Well Hydrated borrows Well Fed's level rule but casts the other effect to `W3Effect_WellFed`, which a Well Hydrated effect is not: from the code, every new drink replaces the Well Hydrated already active, a lower tier included (Well Fed refuses a lower tier while a higher one lasts and refreshes on an equal or higher one).

**Implementation (legacy):** the parent of `W3Effect_WellFed`, `W3Effect_WellHydrated` and `W3Effect_Edible` (no unit; `EdibleEffect` is given by no item, so the last is inert); `W3AbilityManager.OnAbilityChanged`; `W3Effect_WellHydrated.GetSelfInteraction` and its removed `CacheSettings`.

**5.x:** 1.32's classes; `SetEffectValue` added on both effects (Dumplings' multiplier, removed by ENCH-06); Well Fed's `Init` sets the length from Gourmand (FOOD-06).

**Decisions:** legacy's model, food adding to Geralt's regen with no separate heal (DF3, project owner, 2026-10-24). DF6 changed from the mapping's recommendation (project owner, 2026-10-24): legacy's bug fixed as ALCH's potion stacking (DL12). In that branch the stronger tier is kept but the source name and initial length become the new drink's and the summed length, so after water tops up a wine lengthened by Connoisseur, unequipping Connoisseur no longer shortens it (as ALCH's DL12; no player-visible cost).

- **Deviation:** a weaker drink drunk while a stronger Well Hydrated lasts adds its time and the stronger tier stays; an equal or stronger drink refreshes it to the new drink (60 s, its tier). Legacy's code let every new drink replace the running one, a weaker one included, so water drunk after a wine lowered Well Hydrated to tier 1 (the owner's DF6, confirmed by the owner, 2026-10-24). How it played in legacy stays on the [list to test](../open-questions.md#to-test-in-legacy-ghost-mode).
- **Deviation:** the restart of the auto regen when a regen ability changes applies to Geralt only and happens a frame later (a timer); legacy restarted it at once for every actor. Geralt is the only actor whose base regen Ghost Mode zeroes, the timer keeps the restart out of the effect manager's own update (an effect with a regen ability ending), and a frame's delay is invisible in play (confirmed by the owner, 2026-10-24; audit F6).

**Slices:**

1. **Values and regen model** (FOOD-01 to FOOD-03). Verified 2026-10-24 in both trees. Scripted (`GMTest_food`, `GMTest_food_after`, in the regression; `GMTest_food03_model` runs last so the panel's checks find its setup): the effect values; Bottled water gives Well Hydrated and Bread Well Fed; Well Fed's and Well Hydrated's stacking rules (DF6); with both effects on, their abilities are on Geralt, his stamina regen +2% and the effects' own regen value 0. Real actions: a Bread eaten from the quick slot gave Well Fed 1 for 60 s and raised Geralt's regen by its values, nothing from the effect itself; a drink added Well Hydrated with its stamina regen.

### FOOD-04 Food and drink items

| | |
|---|---|
| Kind | content |
| Pillars | P6, P8 |
| 5.x class | clean |
| Flags | balance |
| Depends on | FOOD-01, FOOD-02, FOOD-05 (the toxicity abilities), CRAFT-07 (the two alcohols' roles), ITEM (`item_layer.py`, `gen_item.py`) |
| Skill trees | n/a |
| Port form | FOOD-04's fields in `item_layer.py` (tags other than `mod_*`, `base_abilities`, `stackable`; Wolf liver's category, description and dismantling parts, which legacy changed by moving it from the ingredients to the food: its ingredient unit, CRAFT-07's and CRAFT-08's, shares the name with its food unit, so FOOD-04 carries them), written by `gen_item.py` into `gm_item.xml`, each item defined once (DF9); the toxicity abilities the items name in `gm_food.xml` (FOOD-05's data); the two new dishes are written with FOOD-07 |
| Port status | **signed off** (2026-10-24); verified in both trees |
| Open checks | Soltis Vodka and Cornucopia in play |
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

**Decisions:** legacy's tiers, rarities, tags and stacks (DF4), through the item layer (DF9) (project owner, 2026-10-24).

- **Wolf liver stays in its quick slot after a load** (owner, 2026-11-02): 5.x's `HACK_UnequipWolfLiver`, which every load runs from `OnSpawned`, took Wolf liver out of the potion and food quick slots together with whatever was in the paired slot (1 and 3, or 2 and 4); legacy disabled it once Wolf liver became food. An empty `@replaceMethod` (`food/foodEffects.ws`). Verified 2026-11-02 in both trees (`GMTest_food04_liverslot`, in the regression, scripted).

**Slices:**

1. **Items.** Verified 2026-10-24 in both trees. `gen_item.py --verify` 0 unexplained (stack sizes checked there only). Scripted (`GMTest_food04`, in the regression): 13 items read as legacy's (effect and tier, toxicity, quality, a tag). `GMTest_food04eat` (in the regression): all 109 of legacy's foods and drinks pass `ConsumeItem`'s category test and give their effect when eaten through it; a Wolf liver eaten gives Well Fed 2, 5 toxicity, no drunkenness. Real actions: Est Est raised a running Well Hydrated 2 to tier 3; a Wolf liver eaten from the quick slot gave Well Fed 2 and 5 toxicity.

### FOOD-05 Alcohol, raw food and drunkenness

| | |
|---|---|
| Kind | system, tuning |
| Pillars | P8, P2 |
| 5.x class | clean (data); conflict (5.x's `ConsumeItem`) |
| Flags | balance |
| Depends on | ALCH-01 (legacy's toxicity, threshold and decay), SKL-18 (Metabolism Boosts' `ToxicityLowEnoughToDrinkPotion`), ALCH-02 (the drinking wrapper), FOOD-04, FOOD-06 |
| Skill trees | n/a (Connoisseur's exemption is FOOD-06) |
| Port form | the three toxicity abilities and `DrunkennessEffect` in `gm_food.xml` (`gen_food.py`); `food/toxicity.ws`: `@replaceMethod CR4Player.ConsumeItem` (5.x's body, its diving check and inert Cat branch kept, legacy's lines), `GMHasConnoisseur` (`perk_15` or `perk_41`) and `GMFoodTooToxic` on `W3PlayerWitcher`, a wrapper of `W3InventoryItemContext.HandleUserFeedback` that refuses before the menu's use; ALCH-02's `DrinkPotionFromSlot` wrapper (`alchemy/potionRules.ws`) extended with the quick slot's refusal |
| Port status | **signed off** (2026-10-24); verified in both trees |
| Open checks | the inventory's refusal on screen (the wrapper of the context menu's use) |
| Save impact | none (expected) |
| NG+ counterpart | applied, untested |

**What it does:** alcohol and raw food cost toxicity: beer and other mild alcohol 5 (`alco_toxicity`; 1.32: 0), wine and spirits 10 (`alco_toxicity_strong`), raw meat and fish 5 (`food_toxicity`, items tagged `Uncooked`); the Poison Apple 20 (its own 15 plus 5). With too little free toxicity Geralt refuses them, from the quick slot ("toxicity too high") and from the inventory (the current toxicity shown), as for potions. Alcohol makes Geralt drunk for 60 s (1.32: 30 s); raw food does not. The changelist names none of this except through Connoisseur (461–462).

**Implementation (legacy):** `alco_toxicity` (5, duration 0), `alco_toxicity_strong`, `food_toxicity`, `DrunkennessEffect`; `ConsumeItem` (toxicity and drunkenness without Connoisseur, `Uncooked` added, the buff source `"alcohol"` for FOOD-06), `DrinkPotionFromSlot` (the refusal; its no-drinking-mid-attack check is ALCH-02's, ported), `HandleUserFeedback` (the inventory's refusal).

**5.x:** 1.32's: alcohol adds its (zero) toxicity and makes Geralt drunk; no raw-food toxicity.

**Decisions:** legacy's toxicity and 60 s drunkenness (DF5, project owner, 2026-10-24). The inventory's refusal skips the context menu's base handling for that key press (the wrapper returns before 5.x's method; legacy refused after it, past the base class's empty call and an armor and weapon branch no edible reaches): nothing else is done on a refused press in either, so it is not a deviation.

**Slices:**

1. **Toxicity and drunkenness.** Verified 2026-10-24 in both trees. Scripted (`GMTest_food05`, in the regression, through `ConsumeItem`): drunkenness 60 s; raw food costs 5 toxicity without drunkenness; a wine costs 10 and makes Geralt drunk, its effect from the source "alcohol"; a Bread costs nothing; at 99 toxicity alcohol is refused and a Bread is not. Real actions from the quick slot: at 99 toxicity a wine and raw meat were refused and kept, a Bread eaten; at 0 a beer gave Well Hydrated 2, 5 toxicity, drunk 60 s.

### FOOD-06 Connoisseur

| | |
|---|---|
| Kind | system |
| Pillars | P8, P7 |
| 5.x class | clean (classic `perk_15`); rethink (new tree: Gourmand `perk_41`) |
| Flags | — |
| Depends on | SKL-18 (perk slots, tree profiles), SKL-19 (descriptions), FOOD-03, FOOD-05, FOOD-08 |
| Skill trees | both: classic `perk_15` (5.x: Gourmet), new `perk_41` (5.x: Gourmand), 1 level in both (D41, D49) |
| Port form | `perk_15` and `perk_41` given whole as legacy's ability (`duration_bonus` 1.0, `on_conflict="replace"`) in `gm_skill_trees.xml`, `perk_41` named Connoisseur in the new tree (`localisationName`); `food/connoisseur.ws`: `GMConnoisseurDurationBonus` (the equipped one's), `W3Effect_WellFed`'s `Init` (Gourmand's length removed), `CalculateDuration` (an alcohol's effects +100%), `OnPerk15Unequipped` (the share of time kept), `OnPerk41Updated` (nothing) and `OnPerk41Unequipped` (as `perk_15`) replaced, a wrapper of `W3PlayerAbilityManager.OnSkillUnequip` for Well Hydrated's share; Well Hydrated's `CalculateDuration` (ENCH-06's replacement in `enchantments/preservationDumplings.ws`) with the bonus; `GMHasConnoisseur` (FOOD-05) for the toxicity rules; the description on both perks (`skillDescriptions.ws`); legacy's strings 2110992462 and 2110992463 (keys `skill_name_perk_15`, `skill_desc_perk_15`), 9 languages |
| Port status | **signed off** (2026-10-24); verified in both trees |
| Open checks | the perk equipped and its text read in the character menu on screen |
| Save impact | none (expected): skill abilities are read live; a 5.x save with a running Gourmet or Gourmand Well Fed keeps its saved length until it ends |
| NG+ counterpart | applied (legacy's NG+ ability), untested |

**What it does** (changelist 461–462): "Reduces alcohol and toxic food toxicity to zero. Removes drunken effect from alcohol. After drinking an alcoholic beverage, its bonuses last longer by 100%." It replaces Gourmet (food lasting 20 minutes). Only alcohol's effects last longer (the buff source `"alcohol"`); unequipping it keeps the share of time left of the active Well Fed and Well Hydrated (1.32 reset Well Fed to its initial length).

**Implementation (legacy):** `perk_15` (`duration` 1200 → `duration_bonus` 1.0), `W3Effect_WellFed` and `W3Effect_WellHydrated` `CalculateDuration` and `OnPerk15Unequipped`, `OnSkillUnequip`'s Perk 15 branch, the checks of FOOD-05, the tooltip of FOOD-08, the strings (SKL-19's rows).

**5.x:** classic Gourmet (20 minutes) and the new tree's Gourmand (300 s per level, ending Well Fed when unequipped).

**Decisions:** legacy's Connoisseur in both trees (D41, project owner, 2026-10-11), 1 level, 5.x's Gourmet and Gourmand mechanics removed (DF7, project owner, 2026-10-24). 5.x's `W3Effect_WellFed.OnEffectRemoved` still removes a `GourmetEffect` ability no data gives (inert, left).

**Slices:**

1. **Connoisseur.** Verified 2026-10-24 in both trees. Scripted (`GMTest_food06`, in the regression; the perk of the tree in force equipped by script and taken off): the data and the text; with it equipped alcohol and raw food cost no toxicity and no drunkenness, an alcohol's effect lasts 120 s and food's 60 s; taken off, the effects keep their share of time. Real actions (the perk equipped with the console's `skilleq`, drinks from the quick slot): classic `perk_15` and new tree `perk_41` each gave an alcohol's Well Hydrated 120 s at 0 toxicity.

### FOOD-07 Cooking

| | |
|---|---|
| Kind | content, system |
| Pillars | P8, P6 |
| 5.x class | clean |
| Flags | balance |
| Depends on | FOOD-04 (the dishes), LOOT-01 (the shop lists), CRAFT (the alchemy menu and recipe handling), SKL-16 (Acquired Tolerance counts only potion, bomb, oil, substance and mutagen recipes: legacy's rule, ported, so cooking recipes do not count) |
| Skill trees | n/a |
| Port form | the 27 recipe items and their `<alchemy_recipes>` entries as new entries in `gm_food.xml` (`gen_food.py`; a DLC can add alchemy recipes; the recipe items take Q1's names), the names in a generated string table (`localization/modGhostModeFood`, ids 2110992639–2110992665); the two new dishes through `gen_item.py` (`item_layer.ELSEWHERE` leaves the recipe items to `gen_food.py`); `food/cooking.ws`: `EACIT_Edibles` (enum extension), wrappers of `AlchemyCookedItemTypeStringToEnum`, `...EnumToName`, `...ToLocKey`, `@replaceMethod W3AlchemyManager.CookItem` (5.x's body with its oil re-application, legacy's quantity line), `gmaddrecipesedibles` (legacy's `addrecipesedibles` with the project's prefix, without Butter Bandalura); the shop lists by `gen_loot.py` |
| Port status | **signed off** (2026-10-24); verified in both trees |
| Open checks | a White Orchard or Novigrad inn's stock (their lists come from the same generator) |
| Save impact | none (expected): recipes are read from the definitions; known recipes are saved by name |
| NG+ counterpart | applied, untested |

**What it does** (changelist 839–840, "original idea by FreeSergey, recipes by delamer"): 27 cooking recipes, bought from innkeepers (16 inn and tavern lists, from White Orchard to Skellige and Blood and Wine) and Blood and Wine's butcher, cooked in the alchemy menu under their own group ("Edibles"), each in one level: raw to cooked (Chicken leg ×2 from a Chicken; Gutted fish from a Fish; Roasted chicken, Fried fish, Fried meat, Grilled pork from the raw meat with an Onion and a Pepper; Mutton curry with a Bell pepper), sandwiches ×2 (Chicken, Grilled chicken, Ham), Fondue (Cheese and Dijkstra Dry), Baked apple, Baked potato, Sausages ×3 (Chicken, Wolf liver, Raw meat, Onion, Pepper), Scrambled eggs (2 Eggs, Cheese), Apple and Raspberry juice (2 fruits and an Empty bottle), and Blood and Wine's Chocolate souffle, Crossaint honey, Flamiche ×2, Onion soup ×2, Ratatouille ×2, Tarte tatin, Baguette camembert, Boeuf bourguignon, Fish tarte. Cooking turns tier 2 raw food (toxic) into tier 3 dishes. A 28th recipe, Butter Bandalura, is commented out in legacy's data (the debug command still names it). The recipe items use the dish's own name key and the food description (Q1).

**Implementation (legacy):** `def_item_cooking_recipes.xml`: 27 recipe items (`alchemy_recipe`, prices 10 and 20) and an `<alchemy_recipes>` block of 27 recipes (`cookedItemType="edibles"`), regular and NG+; `EAlchemyCookedItemType` (`EACIT_Edibles`) and `AlchemyCookedItemTypeStringToEnum`, `...EnumToName`, `...ToLocKey` (`item_category_edibles`); `CookItem` (the cooked quantity: 1.32 reads the item's `ammo`, which food lacks); `addrecipesedibles`.

**5.x:** the cooking file unchanged (the two quest recipes); the alchemy menu groups recipes by `AlchemyCookedItemTypeEnumToName` and titles the group by `AlchemyCookedItemTypeToLocKey`; 5.x's recipe counters for achievements count named types only, and Acquired Tolerance counts legacy's whitelist in the port (SKL-16), so cooking recipes count for neither.

**Decisions:** cooking as legacy, its own alchemy group, sold where legacy's lists say, Butter Bandalura left out (DF8, project owner, 2026-10-24).

- **Deviation:** the cooking recipe items are named "Recipe: <dish>" (vanilla's pattern for its two quest cooking recipes, `item_name_recipe_for_scrambled_eggs`: "Recipe: Scrambled eggs"; the prefix and the dish's casing taken from vanilla's tables in each of the 9 languages) with vanilla's recipe description (`item_desc_recipe_food`); legacy's recipe items used the dish's own name and the food description, so a shop listed "Baked apple" with a recipe icon (the owner's Q1, confirmed by the owner, 2026-10-24).

**Slices:**

1. **Cooking.** Verified 2026-10-24 in both trees. `gen_food.py --verify` (27 recipes per folder equal to legacy's, Q1's names), `gen_item.py --verify` and `gen_loot.py --verify` 0 unexplained. Scripted (`GMTest_food07`, in the regression): 27 recipes of the type edibles, the right quantities and group, no Butter Bandalura recipe, the recipe item's name; cooking through the alchemy manager gives the recipe's quantity. Real actions: a spawned Blood and Wine innkeeper stocked cooking recipes; one bought through the shop menu's buy event and read; a mouse click on Craft Item in the alchemy menu's "Food and drink" group cooked it. The alchemy menu's info panel for a dish shows only its description (5.x's panel).

### FOOD-08 Edible tooltip

| | |
|---|---|
| Kind | ui |
| Pillars | P7 |
| 5.x class | clean |
| Flags | — |
| Depends on | FOOD-06, ENCH-06, ALCH-17's `AddBuffStats` wrapper |
| Skill trees | n/a |
| Port form | `food/tooltip.ws`: `@replaceMethod W3TooltipComponent.AddBuffStats` (5.x's body: Connoisseur's +100% on an alcohol, Dumplings on every edible, the in-combat regen row's label through `GMFoodCombatRegenLabel`); ALCH-17's wrapper of the same method still sets a potion's duration |
| Port status | **signed off** (2026-10-24); verified in both trees (scripted) |
| Open checks | the in-combat regen label on screen |
| Save impact | none |
| NG+ counterpart | none |

**What it does:** a food or drink tooltip shows its effect's length: with Dumplings, the longer length in orange on every edible (1.32 and 5.x: only for one in a quick slot); with Connoisseur, an alcohol's length doubled. Its in-combat regen row reads "Vitality regeneration during combat" (legacy's string 2110992157, key `attribute_name_vitalityCombatRegen`, added by legacy with the row: UI-07); 5.x shows the game's label for that attribute, which counts per enemy killed. Legacy's string `attribute_name_staminaRestore` (2110992352, "Stamina") is read by no script or data of legacy: dropped (UI's hand-off).

**Implementation (legacy):** `W3TooltipComponent.AddBuffStats` (its potion part is ALCH-17's, ported).

**5.x:** 1.32's.

**Decisions:** port as legacy. The in-combat regen row named by legacy's string (audit F4, project owner, 2026-10-24): legacy added the string and the row, but its tooltip looked the label up under other keys (`AddItemStats` names `vitalityCombatRegen` by `panel_common_statistics_tooltip_incombat_regen`; `GetAttributeNameLocStr` lower-cases the key), so legacy's label most likely never showed; the port shows it on food and drink tooltips (potions and gear keep the game's label).

**Slices:**

1. **Tooltip.** Verified 2026-10-24 in both trees (`gmtest_food08`, scripted: the tooltips as the inventory builds them, `GetBaseItemData`, with the HUD; not a regression check): Connoisseur doubles an alcohol's length; with Dumplings every edible in the bag shows the longer length in orange; the in-combat regen row reads legacy's label. A wine's and a recipe's tooltips were seen on screen in the shop.

### Dependencies on other areas

- **Areas FOOD builds on:** ALCH (toxicity, the drinking wrapper, the potion tooltip wrapper, ALCH-07's Maribor rule), SKL (Connoisseur's slots and profiles, Metabolism Boosts' toxicity check, SKL-16's recipe whitelist, SKL-19's descriptions), ENCH-06 (Dumplings' replaced methods), CRAFT (`item_layer.py`, CRAFT-07's alcohols and Wolf liver), LOOT (`gen_loot.py`, the shop lists), ITEM (`gen_item.py`), STAM-04 (regen).
- **Areas FOOD shares with:** ECON (prices; the price tags of Wolf liver, the Free nilfgaardian lemon and Local pepper vodka follow their new roles there), WGT (weights), OPT and GEN (Geralt's base Vitality regen and its options, OPT-02 and OPT-03), MISC (`enabledeletedscene`, MISC-03, dropped).

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

**Later:** —
