// FOOD's tests (docs/features/food.md). GMTest_food() runs in gmtest_regress(), GMTest_food_after() in
// gmtest_panel() (an effect's ability counts from the next frame).

@addField(CR4Player)
var gmTestFoodBase : array<float>;

// Adds a food or drink effect as ConsumeItem does (its ability named) and returns it.
function GMTestFoodAdd(type : EEffectType, abl : name) : CBaseGameplayEffect
{
	var params : SCustomEffectParams;

	params.effectType = type;
	params.creator = thePlayer;
	params.sourceName = "edible";
	params.customAbilityName = abl;
	thePlayer.AddEffectCustom(params);
	return thePlayer.GetBuff(type);
}

function GMTestFoodClear()
{
	thePlayer.RemoveAllBuffsOfType(EET_WellFed);
	thePlayer.RemoveAllBuffsOfType(EET_WellHydrated);
}

// The effect type an item gives when consumed (EET_Undefined if none); the item is added and removed.
function GMTestFoodItemEffect(item : name, out abl : name) : EEffectType
{
	var ids : array<SItemUniqueId>;
	var buffs : array<SEffectInfo>;
	var inv : CInventoryComponent;
	var ret : EEffectType;

	inv = thePlayer.GetInventory();
	ids = inv.AddAnItem(item, 1, true, true);
	ret = EET_Undefined;
	if(ids.Size() > 0)
	{
		inv.GetItemBuffs(ids[0], buffs);
		if(buffs.Size() > 0)
		{
			ret = buffs[0].effectType;
			abl = buffs[0].effectAbilityName;
		}
		inv.RemoveItem(ids[0], 1);
	}
	return ret;
}

function GMTestFoodAttr(attr : name, mult : bool) : float
{
	var v : SAbilityAttributeValue;

	v = thePlayer.GetAttributeValue(attr);
	if(mult)
		return v.valueMultiplicative;
	return v.valueAdditive;
}

exec function gmtest_food()
{
	GMTest_food();
}

exec function gmtest_food_after()
{
	GMTest_food_after();
}

function GMTest_food()
{
	GMTest_food01();
	GMTest_food03();
	GMTest_food04();
	GMTest_food04eat();
	GMTest_food04_liverslot();	// fix3: Wolf liver kept in its quick slot at a load
	GMTest_food05();
	GMTest_food06();
	GMTest_food07();
	GMTest_food03_model();	// last: the later checks clear the food effects GMTest_food_after reads
}

// FOOD-01, FOOD-02: the effect values (DF1) and drinks giving Well Hydrated (DF2).
function GMTest_food01()
{
	var i : int;
	var fed, hyd : name;
	var abl : name;
	var t : EEffectType;
	var ok : bool;

	ok = true;
	for(i = 1; i <= 3; i += 1)
	{
		fed = GMTestFoodLevelName(true, i);
		hyd = GMTestFoodLevelName(false, i);
		ok = ok && GMTestArmNear(GMTestArmAbl(fed, 'duration'), 60) && GMTestArmNear(GMTestArmAbl(hyd, 'duration'), 60);
		ok = ok && GMTestArmNear(GMTestArmAbl(fed, 'vitalityRegen'), 10 * i) && GMTestArmNear(GMTestArmAbl(fed, 'vitalityCombatRegen'), GMTestFoodCombat(i));
		ok = ok && GMTestArmNear(GMTestArmAbl(hyd, 'vitalityRegen'), GMTestFoodDrinkRegen(i)) && GMTestArmNear(GMTestArmAbl(hyd, 'vitalityCombatRegen'), GMTestFoodCombat(i));
		ok = ok && GMTestArmNear(GMTestArmAblMult(hyd, 'staminaRegen'), 0.01 * i);
	}
	GMTestReport(ok, "FOOD-01 Well Fed and Well Hydrated: 60 s every tier; food 10/20/30 and 1/5/10 in combat; drinks 5/10/20, 1/5/10, stamina 1/2/3% (DF1)");
	GMTestReport(GMTestArmNear(GMTestArmAbl('WellFedEffect_Cornucopia', 'duration'), 30) && GMTestArmNear(GMTestArmAbl('WellFedEffect_Cornucopia', 'vitalityRegen'), 15)
		&& GMTestArmNear(GMTestArmAbl('WellFedEffect_Cornucopia', 'vitalityCombatRegen'), 15), "FOOD-01 Cornucopia's Well Fed: 30 s at 15 in and out of combat");
	t = GMTestFoodItemEffect('Bottled water', abl);
	GMTestReport(t == EET_WellHydrated, "FOOD-02 a drink (Bottled water) gives Well Hydrated (" + abl + ")");
	t = GMTestFoodItemEffect('Bread', abl);
	GMTestReport(t == EET_WellFed, "FOOD-02 food (Bread) gives Well Fed (" + abl + ")");
}

function GMTestFoodLevelName(fed : bool, level : int) : name
{
	if(fed)
	{
		if(level == 1) return 'WellFedEffect_Level1';
		if(level == 2) return 'WellFedEffect_Level2';
		return 'WellFedEffect_Level3';
	}
	if(level == 1) return 'WellHydratedEffect_Level1';
	if(level == 2) return 'WellHydratedEffect_Level2';
	return 'WellHydratedEffect_Level3';
}

function GMTestFoodCombat(level : int) : float
{
	if(level == 1) return 1;
	if(level == 2) return 5;
	return 10;
}

function GMTestFoodDrinkRegen(level : int) : float
{
	if(level == 1) return 5;
	if(level == 2) return 10;
	return 20;
}

// FOOD-03: Well Fed's level rule; DF6's Well Hydrated rule (the regeneration model: GMTest_food03_model).
function GMTest_food03()
{
	var e : CBaseGameplayEffect;
	var t0, t1 : float;

	GMTestFoodClear();
	e = GMTestFoodAdd(EET_WellFed, 'WellFedEffect_Level3');
	t0 = e.GetTimeLeft();
	e = GMTestFoodAdd(EET_WellFed, 'WellFedEffect_Level1');
	GMTestReport(e.GetAbilityName() == 'WellFedEffect_Level3' && GMTestArmNear(e.GetTimeLeft(), t0) && !thePlayer.HasAbility('WellFedEffect_Level1'),
		"FOOD-03 Well Fed: a weaker food is refused while a stronger lasts (" + e.GetAbilityName() + ", " + e.GetTimeLeft() + " s)");
	e = GMTestFoodAdd(EET_WellFed, 'WellFedEffect_Level3');
	GMTestReport(e.GetAbilityName() == 'WellFedEffect_Level3' && GMTestArmNear(e.GetTimeLeft(), 60), "FOOD-03 Well Fed: an equal food refreshes it (" + e.GetTimeLeft() + " s)");

	e = GMTestFoodAdd(EET_WellHydrated, 'WellHydratedEffect_Level3');
	t0 = e.GetTimeLeft();
	e = GMTestFoodAdd(EET_WellHydrated, 'WellHydratedEffect_Level1');
	GMTestReport(e.GetAbilityName() == 'WellHydratedEffect_Level3' && GMTestArmNear(e.GetTimeLeft(), t0 + 60) && thePlayer.HasAbility('WellHydratedEffect_Level3') && !thePlayer.HasAbility('WellHydratedEffect_Level1'),
		"FOOD-03 Well Hydrated (DF6): a weaker drink adds its time, the stronger tier stays (" + e.GetAbilityName() + ", " + t0 + " -> " + e.GetTimeLeft() + " s)");
	e = GMTestFoodAdd(EET_WellHydrated, 'WellHydratedEffect_Level2');
	GMTestReport(e.GetAbilityName() == 'WellHydratedEffect_Level3' && GMTestArmNear(e.GetTimeLeft(), t0 + 120), "FOOD-03 Well Hydrated (DF6): a second weaker drink adds its time too (" + e.GetTimeLeft() + " s)");
	GMTestFoodClear();
	e = GMTestFoodAdd(EET_WellHydrated, 'WellHydratedEffect_Level1');
	e = GMTestFoodAdd(EET_WellHydrated, 'WellHydratedEffect_Level2');
	GMTestReport(e.GetAbilityName() == 'WellHydratedEffect_Level2' && GMTestArmNear(e.GetTimeLeft(), 60) && !thePlayer.HasAbility('WellHydratedEffect_Level1'),
		"FOOD-03 Well Hydrated: a stronger drink replaces a weaker one (" + e.GetAbilityName() + ", " + e.GetTimeLeft() + " s)");
	GMTestFoodClear();
}

// FOOD-03's regeneration model: the baseline now, the effects added, read in the next frame
// (GMTest_food_after, in gmtest_panel()). Runs last in GMTest_food: FOOD-05 to FOOD-07's checks clear
// the food effects.
function GMTest_food03_model()
{
	var base : array<float>;
	var w : W3PlayerWitcher;

	w = GetWitcherPlayer();
	GMTestFoodClear();
	base.PushBack(0);
	base.PushBack(0);
	base.PushBack(GMTestFoodAttr('staminaRegen', true));
	w.gmTestFoodBase = base;
	GMTestFoodAdd(EET_WellFed, 'WellFedEffect_Level3');
	GMTestFoodAdd(EET_WellHydrated, 'WellHydratedEffect_Level2');
}

function GMTest_food_after()
{
	var w : W3PlayerWitcher;
	var b : array<float>;
	var e1, e2 : CBaseGameplayEffect;
	var v1, v2 : SAbilityAttributeValue;

	w = GetWitcherPlayer();
	b = w.gmTestFoodBase;
	if(b.Size() < 3)
	{
		GMTestReport(false, "FOOD-03 regeneration model: no baseline (run gmtest_regress() first)");
		return;
	}
	// The attribute values move with whatever else the regression's checks leave pending in the same frame:
	// the abilities on Geralt are checked here, the regen numbers in play (gmtest_foodlog).
	GMTestReport(thePlayer.HasAbility('WellFedEffect_Level3') && thePlayer.HasAbility('WellHydratedEffect_Level2'), "FOOD-03 the food and drink abilities are on Geralt (his regen reads them)");
	GMTestReport(GMTestArmNear(GMTestFoodAttr('staminaRegen', true) - b[2], 0.02), "FOOD-01 Geralt's stamina regen +" + (GMTestFoodAttr('staminaRegen', true) - b[2]) + " mult (expected 0.02: 2% a second)");
	e1 = thePlayer.GetBuff(EET_WellFed);
	e2 = thePlayer.GetBuff(EET_WellHydrated);
	if(e1) v1 = e1.GetEffectValue();
	if(e2) v2 = e2.GetEffectValue();
	GMTestReport(e1 && e2 && v1.valueAdditive == 0 && v1.valueMultiplicative == 0 && v2.valueAdditive == 0 && v2.valueMultiplicative == 0,
		"FOOD-03 the food effects regenerate nothing of their own (Well Fed " + v1.valueAdditive + ", Well Hydrated " + v2.valueAdditive + ")");
	GMTestFoodClear();
	b.Clear();
	w.gmTestFoodBase = b;
}

// Uses the item in quick slot 1 as the drink key does (the input event for its release, keyboard path),
// adding the item first if Geralt has none. Logs the effects and Geralt's toxicity afterwards.
exec function gmtest_quickslot(item : name)
{
	var action : SInputAction;
	var ids : array<SItemUniqueId>;
	var w : W3PlayerWitcher;
	var n0 : int;

	w = GetWitcherPlayer();
	ids = w.inv.GetItemsByName(item);
	if(ids.Size() == 0)
		ids = w.inv.AddAnItem(item, 1);
	w.EquipItemInGivenSlot(ids[0], EES_Potion1, false);
	n0 = w.inv.GetItemQuantityByName(item);
	action.aName = 'DrinkPotion1';
	action.value = 0;
	action.lastFrameValue = 1;
	w.GetInputHandler().OnCommDrinkPotion1(action);
	LogChannel('GMTest', "quickslot " + item + ": count " + n0 + " -> " + w.inv.GetItemQuantityByName(item));
	GMTestFoodLog();
}

exec function gmtest_foodlog()
{
	GMTestFoodLog();
}

function GMTestFoodLog()
{
	var e : CBaseGameplayEffect;

	e = thePlayer.GetBuff(EET_WellFed);
	if(e)
		LogChannel('GMTest', "Well Fed " + e.GetAbilityName() + " " + e.GetTimeLeft() + " s, source " + e.GetSourceName());
	e = thePlayer.GetBuff(EET_WellHydrated);
	if(e)
		LogChannel('GMTest', "Well Hydrated " + e.GetAbilityName() + " " + e.GetTimeLeft() + " s, source " + e.GetSourceName());
	e = thePlayer.GetBuff(EET_Drunkenness);
	if(e)
		LogChannel('GMTest', "Drunk " + e.GetTimeLeft() + " s");
	LogChannel('GMTest', "toxicity " + thePlayer.GetStat(BCS_Toxicity) + ", vitality " + thePlayer.GetStat(BCS_Vitality) + "/" + thePlayer.GetStatMax(BCS_Vitality)
		+ ", regen " + GMTestFoodAttr('vitalityRegen', false) + "/" + GMTestFoodAttr('vitalityCombatRegen', false) + " combat, stamina regen mult " + GMTestFoodAttr('staminaRegen', true));
}

// Sets Geralt's Vitality to a share of its maximum (play checks of regeneration).
exec function gmtest_setvit(share : float)
{
	thePlayer.ForceSetStat(BCS_Vitality, thePlayer.GetStatMax(BCS_Vitality) * share);
	LogChannel('GMTest', "vitality " + thePlayer.GetStat(BCS_Vitality) + " at " + theGame.GetEngineTimeAsSeconds());
}

// FOOD-04: one item's effect, ability, toxicity, quality and a tag (present or absent) as legacy has them.
function GMTestFoodItemCheck(item : name, type : EEffectType, abl : name, tox : float, quality : int, tag : name, hasTag : bool)
{
	var ids : array<SItemUniqueId>;
	var buffs : array<SEffectInfo>;
	var inv : CInventoryComponent;
	var t : EEffectType;
	var a : name;
	var x : float;
	var q : int;
	var tg : bool;

	inv = thePlayer.GetInventory();
	ids = inv.AddAnItem(item, 1, true, true);
	if(ids.Size() == 0)
	{
		GMTestReport(false, "FOOD-04 " + item + ": not added");
		return;
	}
	inv.GetItemBuffs(ids[0], buffs);
	if(buffs.Size() > 0)
	{
		t = buffs[0].effectType;
		a = buffs[0].effectAbilityName;
	}
	x = CalculateAttributeValue(inv.GetItemAttributeValue(ids[0], 'toxicity'));
	q = inv.GetItemQuality(ids[0]);
	tg = inv.ItemHasTag(ids[0], tag);
	GMTestReport(t == type && a == abl && GMTestArmNear(x, tox) && q == quality && tg == hasTag,
		"FOOD-04 " + item + ": " + a + ", toxicity " + x + ", quality " + q + ", " + tag + " " + tg + " (expected " + abl + ", " + tox + ", " + quality + ", " + hasTag + ")");
	inv.RemoveItem(ids[0], 1);
}

function GMTest_food04()
{
	GMTestFoodItemCheck('Apple', EET_WellFed, 'WellFedEffect_Level1', 0, 1, 'Uncooked', false);
	GMTestFoodItemCheck('Bread', EET_WellFed, 'WellFedEffect_Level2', 0, 2, 'Uncooked', false);
	GMTestFoodItemCheck('Chicken', EET_WellFed, 'WellFedEffect_Level2', 5, 2, 'Uncooked', true);
	GMTestFoodItemCheck('Wolf liver', EET_WellFed, 'WellFedEffect_Level2', 5, 2, 'Uncooked', true);
	GMTestFoodItemCheck('Roasted chicken', EET_WellFed, 'WellFedEffect_Level3', 0, 3, 'Uncooked', false);
	GMTestFoodItemCheck('Bottled water', EET_WellHydrated, 'WellHydratedEffect_Level1', 0, 1, 'Drinks', true);
	GMTestFoodItemCheck('Apple juice', EET_WellHydrated, 'WellHydratedEffect_Level2', 0, 2, 'Drinks', true);
	GMTestFoodItemCheck('Kaedwenian Stout', EET_WellHydrated, 'WellHydratedEffect_Level2', 5, 2, 'Potion', false);
	GMTestFoodItemCheck('Cows milk', EET_WellHydrated, 'WellHydratedEffect_Level3', 0, 3, 'Drinks', true);
	GMTestFoodItemCheck('Est Est', EET_WellHydrated, 'WellHydratedEffect_Level3', 10, 3, 'Alcohol', true);
	GMTestFoodItemCheck('Free nilfgaardian lemon', EET_WellHydrated, 'WellHydratedEffect_Level3', 10, 3, 'Drinks', true);
	GMTestFoodItemCheck('Soltis Vodka', EET_WellHydrated, 'WellHydratedEffect_Level3', 10, 4, 'Drinks', true);
	GMTestFoodItemCheck('Cornucopia', EET_WellFed, 'WellFedEffect_Cornucopia', 0, 4, 'Potion', false);
}

// Legacy's foods and drinks (every item of legacy's def_item_edibles.xml, base and Blood and Wine, with a
// food or drink quality ability, and Hearts of Stone's Soltis Vodka and Cornucopia: 109).
function GMTestFoodLegacyItems() : array<name>
{
	var n : array<name>;

	n.PushBack('Rivian Kriek'); n.PushBack('Viziman Champion'); n.PushBack('Kaedwenian Stout');
	n.PushBack('Redanian Lager'); n.PushBack('Dijkstra Dry'); n.PushBack('Beauclair White'); n.PushBack('Mettina Rose');
	n.PushBack('Erveluce'); n.PushBack('Est Est'); n.PushBack('Apple'); n.PushBack('Banana'); n.PushBack('Bell pepper');
	n.PushBack('Blueberries'); n.PushBack('Burned bread'); n.PushBack('Burned bun'); n.PushBack('Candy');
	n.PushBack('Cucumber'); n.PushBack('Egg'); n.PushBack('Fish'); n.PushBack('Grapes'); n.PushBack('Honeycomb');
	n.PushBack('Mushroom'); n.PushBack('Olive'); n.PushBack('Onion'); n.PushBack('Pear'); n.PushBack('Pepper');
	n.PushBack('Plum'); n.PushBack('Potatoes'); n.PushBack('Raspberries'); n.PushBack('Strawberries');
	n.PushBack('Toffee'); n.PushBack('Vinegar'); n.PushBack('Baked apple'); n.PushBack('Baked potato');
	n.PushBack('Bread'); n.PushBack('Bun'); n.PushBack('Butter Bandalura'); n.PushBack('Cheese'); n.PushBack('Chicken');
	n.PushBack('Chicken leg'); n.PushBack('Chips'); n.PushBack('Dried fruit'); n.PushBack('Dried fruit and nuts');
	n.PushBack('Dumpling'); n.PushBack('Gutted fish'); n.PushBack('Mutton leg'); n.PushBack('Pork');
	n.PushBack('Raw meat'); n.PushBack('Wolf liver'); n.PushBack('Roasted chicken'); n.PushBack('Roasted chicken leg');
	n.PushBack('Chicken sandwich'); n.PushBack('Grilled chicken sandwich'); n.PushBack('Fried fish');
	n.PushBack('Fried meat'); n.PushBack('Fondue'); n.PushBack('Grilled pork'); n.PushBack('Ham sandwich');
	n.PushBack('Mutton curry'); n.PushBack('Sausages Mod'); n.PushBack('Scrambled Eggs Mod');
	n.PushBack('Very good honey'); n.PushBack('Bottled water'); n.PushBack('Tirnalia potion'); n.PushBack('Apple juice');
	n.PushBack('Raspberry juice'); n.PushBack('Cows milk'); n.PushBack('Goats milk');
	n.PushBack('Free roasted chicken leg'); n.PushBack('Free nilfgaardian lemon'); n.PushBack('Bourgogne chardonnay');
	n.PushBack('Chateau mont valjean'); n.PushBack('Bourgogne pinot noir'); n.PushBack('Saint mathieu rouge');
	n.PushBack('Duke nicolas chardonnay'); n.PushBack('Uncle toms exquisite blanc');
	n.PushBack('Chevalier adam pinot blanc reserve'); n.PushBack('Prince john merlot');
	n.PushBack('Count var ochmann shiraz'); n.PushBack('Chateau de konrad cabernet'); n.PushBack('Geralt de rivia');
	n.PushBack('White Wolf'); n.PushBack('Butcher of Blaviken'); n.PushBack('Brioche'); n.PushBack('Cookies');
	n.PushBack('Ginger Bread'); n.PushBack('Tomato'); n.PushBack('Camembert'); n.PushBack('Chocolate souffle');
	n.PushBack('Crossaint honey'); n.PushBack('Flamiche'); n.PushBack('Herb toasts'); n.PushBack('Onion soup');
	n.PushBack('Pheasant gutted'); n.PushBack('Ratatouille'); n.PushBack('Tarte tatin'); n.PushBack('Baguette camembert');
	n.PushBack('Baguette fish paste'); n.PushBack('Boeuf bourguignon'); n.PushBack('Confit de canard');
	n.PushBack('Fish tarte'); n.PushBack('Ham roasted'); n.PushBack('Pate chicken livers'); n.PushBack('Rillettes porc');
	n.PushBack('Magic Mushrooms'); n.PushBack('Poison Apple'); n.PushBack('Magic food'); n.PushBack('Soltis Vodka');
	n.PushBack('Cornucopia');
	return n;
}

// Whether ConsumeItem feeds an item (its category test) and gives the effect the item names.
function GMTestFoodEats(item : name, out why : string) : bool
{
	var w : W3PlayerWitcher;
	var ids : array<SItemUniqueId>;
	var buffs : array<SEffectInfo>;
	var e : CBaseGameplayEffect;
	var cat : name;
	var ok : bool;

	w = GetWitcherPlayer();
	GMTestFoodClear();
	w.RemoveAllBuffsOfType(EET_Drunkenness);
	w.ForceSetStat(BCS_Toxicity, 0);
	ids = w.inv.AddAnItem(item, 1, true, true);
	if(ids.Size() == 0)
	{
		why = "not added";
		return false;
	}
	cat = w.inv.GetItemCategory(ids[0]);
	w.inv.GetItemBuffs(ids[0], buffs);
	if(!(cat == 'edibles' || w.inv.ItemHasTag(ids[0], 'Drinks') || (cat == 'alchemy_ingredient' && w.inv.ItemHasTag(ids[0], 'Alcohol'))))
		why = "category " + cat;
	else if(buffs.Size() == 0 || (buffs[0].effectType != EET_WellFed && buffs[0].effectType != EET_WellHydrated))
		why = "no food or drink effect";
	else
	{
		w.ConsumeItem(ids[0]);
		e = w.GetBuff(buffs[0].effectType);
		ok = e && e.GetAbilityName() == buffs[0].effectAbilityName;
		if(!ok)
			why = "effect " + buffs[0].effectAbilityName + " not given";
	}
	w.inv.RemoveItem(ids[0], 1);
	return ok;
}

// FOOD-04 (audit F1, F12): every legacy food and drink is eaten through ConsumeItem and gives its effect;
// Wolf liver is a raw food (legacy moved it from the ingredients): Well Fed 2, 5 toxicity, no dismantling parts.
function GMTest_food04eat()
{
	var w : W3PlayerWitcher;
	var items : array<name>;
	var ids : array<SItemUniqueId>;
	var i, eaten : int;
	var why, bad : string;
	var e : CBaseGameplayEffect;
	var cat, abl : name;
	var t : float;
	var parts : bool;

	w = GetWitcherPlayer();
	items = GMTestFoodLegacyItems();
	for(i = 0; i < items.Size(); i += 1)
	{
		why = "";
		if(GMTestFoodEats(items[i], why))
			eaten += 1;
		else
			bad += " " + items[i] + " (" + why + ")";
	}
	GMTestReport(eaten == 109 && items.Size() == 109, "FOOD-04 " + eaten + " of " + items.Size() + " legacy foods and drinks eaten through ConsumeItem, each giving its effect (expected 109)" + bad);

	GMTestFoodClear();
	w.RemoveAllBuffsOfType(EET_Drunkenness);
	w.ForceSetStat(BCS_Toxicity, 0);
	ids = w.inv.AddAnItem('Wolf liver', 1, true, true);
	cat = w.inv.GetItemCategory(ids[0]);
	parts = w.inv.GMItemHasRecyclingParts(ids[0]);
	w.ConsumeItem(ids[0]);
	w.inv.RemoveItem(ids[0], 1);
	e = w.GetBuff(EET_WellFed);
	if(e)
	{
		abl = e.GetAbilityName();
		t = e.GetTimeLeft();
	}
	GMTestReport(cat == 'edibles' && !parts && abl == 'WellFedEffect_Level2' && GMTestArmNear(t, 60) && GMTestArmNear(w.GetStat(BCS_Toxicity), 5) && !w.HasBuff(EET_Drunkenness),
		"FOOD-04 Wolf liver eaten: category " + cat + ", dismantling parts " + parts + ", " + abl + " " + t + " s, toxicity " + w.GetStat(BCS_Toxicity) + " (expected edibles, false, WellFedEffect_Level2 60 s, 5)");
	w.ForceSetStat(BCS_Toxicity, 0);
	w.RemoveAllBuffsOfType(EET_Drunkenness);
	GMTestFoodClear();
}

// Consumes one item as the inventory and the quick slot do (ConsumeItem), adding it first.
function GMTestFoodConsume(item : name) : bool
{
	var ids : array<SItemUniqueId>;

	ids = thePlayer.GetInventory().AddAnItem(item, 1, true, true);
	if(ids.Size() == 0)
		return false;
	return thePlayer.ConsumeItem(ids[0]);
}

// FOOD-05: raw food and alcohol cost toxicity, alcohol makes Geralt drunk for 60 s, its effects carry
// the source "alcohol"; too little free toxicity refuses them (not ordinary food).
function GMTest_food05()
{
	var w : W3PlayerWitcher;
	var e : CBaseGameplayEffect;
	var t0 : float;
	var ids : array<SItemUniqueId>;
	var refused, bread : bool;

	w = GetWitcherPlayer();
	GMTestFoodClear();
	w.RemoveAllBuffsOfType(EET_Drunkenness);
	w.ForceSetStat(BCS_Toxicity, 0);
	GMTestReport(GMTestArmNear(GMTestArmAbl('DrunkennessEffect', 'duration'), 60), "FOOD-05 drunkenness lasts " + GMTestArmAbl('DrunkennessEffect', 'duration') + " s (DF5)");
	GMTestFoodConsume('Chicken');
	GMTestReport(GMTestArmNear(w.GetStat(BCS_Toxicity), 5) && !w.HasBuff(EET_Drunkenness), "FOOD-05 a raw Chicken costs 5 toxicity (" + w.GetStat(BCS_Toxicity) + "), no drunkenness");
	w.ForceSetStat(BCS_Toxicity, 0);
	GMTestFoodConsume('Est Est');
	e = w.GetBuff(EET_WellHydrated);
	t0 = 0;
	if(w.GetBuff(EET_Drunkenness))
		t0 = w.GetBuff(EET_Drunkenness).GetTimeLeft();
	GMTestReport(GMTestArmNear(w.GetStat(BCS_Toxicity), 10) && GMTestArmNear(t0, 60) && e && e.GetSourceName() == "alcohol",
		"FOOD-05 Est Est costs 10 toxicity (" + w.GetStat(BCS_Toxicity) + "), drunk " + t0 + " s, its Well Hydrated from \"alcohol\"");
	GMTestFoodConsume('Bread');
	e = w.GetBuff(EET_WellFed);
	GMTestReport(e && e.GetSourceName() == "edible" && GMTestArmNear(w.GetStat(BCS_Toxicity), 10), "FOOD-05 Bread: no toxicity, source \"edible\"");

	w.ForceSetStat(BCS_Toxicity, w.GetStatMax(BCS_Toxicity) - 1);
	ids = w.inv.AddAnItem('Kaedwenian Stout', 1, true, true);
	refused = w.GMFoodTooToxic(ids[0]);
	w.inv.RemoveItem(ids[0], 1);
	ids = w.inv.AddAnItem('Bread', 1, true, true);
	bread = w.GMFoodTooToxic(ids[0]);
	w.inv.RemoveItem(ids[0], 1);
	GMTestReport(refused && !bread, "FOOD-05 at " + w.GetStat(BCS_Toxicity) + " toxicity a beer is refused (" + refused + "), a Bread is not (" + bread + ")");
	w.ForceSetStat(BCS_Toxicity, 0);
	w.RemoveAllBuffsOfType(EET_Drunkenness);
	GMTestFoodClear();
}

// Sets Geralt's toxicity (play checks of the refusals).
exec function gmtest_settox(value : float)
{
	thePlayer.ForceSetStat(BCS_Toxicity, value);
	LogChannel('GMTest', "toxicity " + thePlayer.GetStat(BCS_Toxicity) + " / " + thePlayer.GetStatMax(BCS_Toxicity));
}

// FOOD-06: Connoisseur in the tree in force (classic perk_15, new tree perk_41): equipped for the test and
// taken off again (it stays learnt: nothing removes a skill; the test save is not saved).
function GMTest_food06()
{
	var w : W3PlayerWitcher;
	var s : ESkill;
	var had, eq : bool;
	var slot : int;
	var e : CBaseGameplayEffect;
	var t1, t2, tox : float;
	var desc, nm : string;

	w = GetWitcherPlayer();
	if(GMIsNewTreeProfileInForce())
		s = S_Perk_41;
	else
		s = S_Perk_15;
	GMTestReport(GMTestArmNear(GMTestArmAblMult('perk_15', 'duration_bonus'), 1) && GMTestArmNear(GMTestArmAblMult('perk_41', 'duration_bonus'), 1)
		&& GMTestArmAbl('perk_15', 'duration') == 0 && GMTestArmAbl('perk_41', 'duration') == 0, "FOOD-06 Connoisseur's data: +100% on perk_15 and perk_41, no Gourmet or Gourmand duration");
	desc = GMPerkDescription(s, 1);
	nm = GetLocStringByKeyExt(w.GetSkillLocalisationKeyName(s));
	GMTestReport(desc == GetLocStringById(2110992463) || StrFindFirst(desc, "100") >= 0 && nm == GetLocStringById(2110992462),
		"FOOD-06 " + s + " is named '" + nm + "': " + desc);

	GMTestFoodClear();
	w.RemoveAllBuffsOfType(EET_Drunkenness);
	w.ForceSetStat(BCS_Toxicity, 0);
	had = w.HasLearnedSkill(s);
	eq = w.IsSkillEquipped(s);
	if(!had)
		w.AddSkill(s);
	if(!eq)
	{
		slot = w.GetFreeSkillSlot();
		w.EquipSkill(s, slot);
	}
	GMTestReport(w.CanUseSkill(s) && w.GMHasConnoisseur() && GMTestArmNear(w.GMConnoisseurDurationBonus(), 1), "FOOD-06 Connoisseur equipped on " + s + " (bonus " + w.GMConnoisseurDurationBonus() + ")");
	GMTestFoodConsume('Est Est');
	GMTestFoodConsume('Chicken');
	tox = w.GetStat(BCS_Toxicity);
	e = w.GetBuff(EET_WellHydrated);
	if(e) t1 = e.GetTimeLeft();
	GMTestReport(tox == 0 && !w.HasBuff(EET_Drunkenness) && GMTestArmNear(t1, 120), "FOOD-06 with Connoisseur: Est Est and a raw Chicken cost " + tox + " toxicity, drunk " + w.HasBuff(EET_Drunkenness) + ", the wine's Well Hydrated lasts " + t1 + " s (expected 0, false, 120)");
	e = w.GetBuff(EET_WellFed);
	if(e) t2 = e.GetTimeLeft();
	GMTestReport(GMTestArmNear(t2, 60), "FOOD-06 the raw Chicken's Well Fed (not alcohol) lasts " + t2 + " s");
	w.UnequipSkill(w.GetSkillSlotID(s));
	e = w.GetBuff(EET_WellHydrated);
	if(e) t1 = e.GetTimeLeft();
	e = w.GetBuff(EET_WellFed);
	if(e) t2 = e.GetTimeLeft();
	GMTestReport(!w.GMHasConnoisseur() && GMTestArmNear(t1, 60) && GMTestArmNear(t2, 60), "FOOD-06 Connoisseur taken off: the wine's Well Hydrated keeps its share, " + t1 + " s of 60; Well Fed " + t2 + " s (5.x's Gourmand ended it)");
	if(eq)
		w.EquipSkill(s, w.GetFreeSkillSlot());
	GMTestFoodClear();
	w.ForceSetStat(BCS_Toxicity, 0);
}

// FOOD-08: the duration row of an edible's tooltip as the inventory builds it (needs the HUD).
function GMTestFoodTooltipDuration(tc : W3TooltipComponent, item : name, out row : string) : string
{
	var w : W3PlayerWitcher;
	var data, line : CScriptedFlashObject;
	var list : CScriptedFlashArray;
	var ids : array<SItemUniqueId>;
	var i : int;
	var value : string;

	w = GetWitcherPlayer();
	ids = w.inv.AddAnItem(item, 1);
	data = tc.GetBaseItemData(ids[0], w.inv);
	list = data.GetMemberFlashArray("StatsList");
	for(i = 0; i < list.GetLength(); i += 1)
	{
		line = list.GetElementFlashObject(i);
		if(StrFindFirst(line.GetMemberFlashString("name"), GetAttributeNameLocStr('duration', false)) >= 0)
		{
			row = line.GetMemberFlashString("name") + " " + line.GetMemberFlashString("value");
			value = line.GetMemberFlashString("value");
		}
	}
	w.inv.RemoveItem(ids[0], 1);
	return value;
}

// The name of a row of an item's tooltip as the inventory builds it ("" if none; needs the HUD).
function GMTestFoodTooltipRowName(tc : W3TooltipComponent, item : name, id : string) : string
{
	var w : W3PlayerWitcher;
	var data, line : CScriptedFlashObject;
	var list : CScriptedFlashArray;
	var ids : array<SItemUniqueId>;
	var i : int;
	var ret : string;

	w = GetWitcherPlayer();
	ids = w.inv.AddAnItem(item, 1);
	data = tc.GetBaseItemData(ids[0], w.inv);
	list = data.GetMemberFlashArray("StatsList");
	for(i = 0; i < list.GetLength(); i += 1)
	{
		line = list.GetElementFlashObject(i);
		if(line.GetMemberFlashString("id") == id)
			ret = line.GetMemberFlashString("name");
	}
	w.inv.RemoveItem(ids[0], 1);
	return ret;
}

// FOOD-08 in play: a Bread's and Est Est's tooltip durations, then with Connoisseur (the tree in force's
// perk) and Dumplings on the sheathed silver sword (in the bag, not a quick slot). Restores the swords' words.
exec function gmtest_food08()
{
	var w : W3PlayerWitcher;
	var tc : W3TooltipComponent;
	var s : ESkill;
	var row, b0, e0, b1, e1 : string;
	var eq : bool;

	w = GetWitcherPlayer();
	tc = new W3TooltipComponent in w;
	tc.initialize(w.inv, theGame.GetHud().GetHudFlashValueStorage());
	tc.setCurrentInventory(w.inv);
	if(GMIsNewTreeProfileInForce())
		s = S_Perk_41;
	else
		s = S_Perk_15;
	w.OnEquipMeleeWeapon(PW_None, true);
	GMTestEnchant(EES_SilverSword, '');
	if(w.IsSkillEquipped(s))
		w.UnequipSkill(w.GetSkillSlotID(s));
	b0 = GMTestFoodTooltipDuration(tc, 'Bread', row);
	e0 = GMTestFoodTooltipDuration(tc, 'Est Est', row);
	GMTestReport(StrFindFirst(b0, "60") == 0 && StrFindFirst(e0, "60") == 0, "FOOD-08 plain: Bread '" + b0 + "', Est Est '" + e0 + "' (60 s each)");
	b1 = GMTestFoodTooltipRowName(tc, 'Bread', "vitalityCombatRegen");
	e1 = GMTestFoodTooltipRowName(tc, 'Est Est', "vitalityCombatRegen");
	GMTestReport(b1 != "" && b1 == GetLocStringById(2110992157) && e1 == b1, "FOOD-08 the in-combat regen row (audit F4): Bread '" + b1 + "', Est Est '" + e1 + "' (expected legacy's '" + GetLocStringById(2110992157) + "')");
	if(!w.HasLearnedSkill(s))
		w.AddSkill(s);
	w.EquipSkill(s, w.GetFreeSkillSlot());
	e1 = GMTestFoodTooltipDuration(tc, 'Est Est', row);
	b1 = GMTestFoodTooltipDuration(tc, 'Bread', row);
	GMTestReport(StrFindFirst(e1, "120") == 0 && StrFindFirst(b1, "60") == 0, "FOOD-08 Connoisseur (" + s + "): Est Est '" + e1 + "' (120), Bread '" + b1 + "' (60, not alcohol)");
	GMTestEnchant(EES_SilverSword, 'Runeword 6');
	e1 = GMTestFoodTooltipDuration(tc, 'Est Est', row);
	b1 = GMTestFoodTooltipDuration(tc, 'Bread', row);
	GMTestReport(StrFindFirst(b1, "120") >= 0 && StrFindFirst(b1, "E67E0B") >= 0 && StrFindFirst(e1, "240") >= 0, "FOOD-08 Dumplings (active " + w.HasRunewordActive('Runeword 6 _Stats') + ") on a Bread in the bag: '" + b1 + "'; Est Est with Connoisseur too: '" + e1 + "' (orange 120 and 240)");
	w.UnequipSkill(w.GetSkillSlotID(s));
	GMTestEnchant(EES_SilverSword, '');
}

// FOOD-07: the cooking recipes (data, type, group title, names) and cooking a dish in its recipe's
// quantity through the alchemy manager.
function GMTest_food07()
{
	var alch : W3AlchemyManager;
	var recipe : SAlchemyRecipe;
	var i, n, before, after : int;
	var found : bool;
	var nm, dish, sample, type : string;
	var dm : CDefinitionsManagerAccessor;
	var main : SCustomNode;
	var names : array<name>;

	dm = theGame.GetDefinitionsManager();
	main = dm.GetCustomDefinition('alchemy_recipes');
	for(i = 0; i < main.subNodes.Size(); i += 1)
		if(dm.GetCustomNodeAttributeValueString(main.subNodes[i], 'cookedItemType', type) && AlchemyCookedItemTypeStringToEnum(type) == EACIT_Edibles)
			n += 1;
	GMTestReport(n == 27, "FOOD-07 " + n + " cooking recipes of the type edibles (expected 27)");
	names.PushBack('Recipe for Chicken leg');
	alch = new W3AlchemyManager in theGame;
	alch.Init(names);
	found = alch.GetRecipe('Recipe for Chicken leg', recipe);
	GMTestReport(found && recipe.cookedItemName == 'Chicken leg' && recipe.cookedItemQuantity == 2 && AlchemyCookedItemTypeEnumToName(recipe.cookedItemType) == 'edibles'
		&& AlchemyCookedItemTypeToLocKey(recipe.cookedItemType) == "item_category_edibles", "FOOD-07 Recipe for Chicken leg: " + recipe.cookedItemName + " x" + recipe.cookedItemQuantity + ", group '" + GetLocStringByKeyExt(AlchemyCookedItemTypeToLocKey(recipe.cookedItemType)) + "'");
	GMTestReport(!alch.GetRecipe('Recipe for Butter Bandalura', recipe), "FOOD-07 no Butter Bandalura recipe (DF8)");
	nm = GetLocStringByKeyExt(theGame.GetDefinitionsManager().GetItemLocalisationKeyName('Recipe for Baked apple'));
	dish = GetLocStringByKeyExt("item_name_baked_apple");
	sample = GetLocStringByKeyExt("item_name_recipe_for_scrambled_eggs");
	GMTestReport(StrLen(nm) > StrLen(dish) && StrLower(StrRight(nm, StrLen(dish))) == StrLower(dish) && StrLeft(nm, StrFindFirst(sample, ":") + 1) == StrLeft(sample, StrFindFirst(sample, ":") + 1),
		"FOOD-07 the recipe item is named '" + nm + "' (vanilla's pattern: '" + sample + "', Q1)");
	thePlayer.inv.RemoveItemByName('Chicken leg', -1);
	thePlayer.inv.AddAnItem('Chicken', 1);
	before = thePlayer.inv.GetItemQuantityByName('Chicken');
	alch.CookItem('Recipe for Chicken leg');
	after = thePlayer.inv.GetItemQuantityByName('Chicken leg');
	GMTestReport(after == 2 && thePlayer.inv.GetItemQuantityByName('Chicken') == before - 1, "FOOD-07 cooking a Chicken gives " + after + " Chicken legs (the recipe's quantity)");
	thePlayer.inv.RemoveItemByName('Chicken leg', -1);
}

// Opens the inventory (screenshots of tooltips).
exec function gmtest_invopen()
{
	theGame.RequestMenuWithBackground('InventoryMenu', 'CommonMenu');
}

// Reads a recipe or schematic item Geralt has, as the inventory's use does (learns it).
exec function gmtest_readrecipe(item : name)
{
	var ids : array<SItemUniqueId>;
	var known : array<name>;

	ids = thePlayer.inv.GetItemsByName(item);
	if(ids.Size() > 0)
		thePlayer.inv.ReadSchematicsAndRecipes(ids[0]);
	known = GetWitcherPlayer().GetAlchemyRecipes();
	LogChannel('GMTest', "read " + item + ": known " + known.Contains(item));
}

// FOOD-04 (fix3, sweep D G6): a save loaded with Wolf liver in a food quick slot keeps it there, and keeps the food in
// the paired slot (5.x's load-time HACK_UnequipWolfLiver, which the load runs from OnSpawned, took both out; legacy
// disabled it). Wolf liver in quick slot 1 and a Bread in slot 3, then the load's call.
@addMethod(W3PlayerWitcher)
function GMTestFoodLoadHack()
{
	HACK_UnequipWolfLiver();
}

function GMTest_food04_liverslot()
{
	var w : W3PlayerWitcher;
	var liver, bread, old1, old3, now1, now3 : SItemUniqueId;
	var ids : array<SItemUniqueId>;
	var had1, had3 : bool;

	w = GetWitcherPlayer();
	had1 = w.GetItemEquippedOnSlot(EES_Potion1, old1);
	had3 = w.GetItemEquippedOnSlot(EES_Potion3, old3);
	ids = w.inv.AddAnItem('Wolf liver', 1, true, true);
	liver = ids[0];
	ids = w.inv.AddAnItem('Bread', 1, true, true);
	bread = ids[0];
	w.EquipItemInGivenSlot(liver, EES_Potion1, false);
	w.EquipItemInGivenSlot(bread, EES_Potion3, false);
	w.GMTestFoodLoadHack();
	w.GetItemEquippedOnSlot(EES_Potion1, now1);
	w.GetItemEquippedOnSlot(EES_Potion3, now3);
	GMTestReport(now1 == liver && now3 == bread,
		"FOOD-04 a load keeps Wolf liver in quick slot 1 (" + (now1 == liver) + ") and the Bread in the paired slot 3 (" + (now3 == bread) + "; 5.x's load took both out)");
	if(w.inv.IsItemMounted(liver) || now1 == liver)
		w.UnequipItem(liver);
	if(now3 == bread)
		w.UnequipItem(bread);
	w.inv.RemoveItem(liver, 1);
	w.inv.RemoveItem(bread, 1);
	if(had1 && w.inv.IsIdValid(old1))
		w.EquipItemInGivenSlot(old1, EES_Potion1, false);
	if(had3 && w.inv.IsIdValid(old3))
		w.EquipItemInGivenSlot(old3, EES_Potion3, false);
}
