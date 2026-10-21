// In-game tests for ALCH's potions (ALCH-02 to ALCH-08). See docs/features/alch.md.

// Drinks a potion through DrinkPreparedPotion (adds one if Geralt has none); returns the effect.
function GMTestAlchDrink(itemName : name) : CBaseGameplayEffect
{
	var witcher : W3PlayerWitcher;
	var ids : array<SItemUniqueId>;
	var effectType : EEffectType;
	var abilityName : name;

	witcher = GetWitcherPlayer();
	ids = witcher.inv.GetItemsByName(itemName);
	if(ids.Size() == 0)
		ids = witcher.inv.AddAnItem(itemName, 1);
	witcher.inv.SingletonItemSetAmmo(ids[0], witcher.inv.SingletonItemGetMaxAmmo(ids[0]));
	witcher.DrainToxicity(witcher.GetStat(BCS_Toxicity, true));
	witcher.SetToxicityOffset(0);
	witcher.inv.GetPotionItemBuffData(ids[0], effectType, abilityName);
	witcher.DrinkPreparedPotion(EES_InvalidSlot, ids[0]);
	return witcher.GetBuff(effectType);
}

function GMTestAlchItemValue(itemName : name, attributeName : name) : float
{
	var witcher : W3PlayerWitcher;
	var ids : array<SItemUniqueId>;
	var value : float;

	witcher = GetWitcherPlayer();
	ids = witcher.inv.AddAnItem(itemName, 1);
	value = CalculateAttributeValue(witcher.inv.GetItemAttributeValue(ids[0], attributeName));
	witcher.inv.RemoveItem(ids[0], 1);
	return value;
}

function GMTestAlchItemCheck(itemName : name, attributeName : name, expected : float, label : string)
{
	var value : float;

	value = GMTestAlchItemValue(itemName, attributeName);
	GMTestReport(AbsF(value - expected) < 0.001, label + " " + itemName + " " + attributeName + " " + NoTrailZeros(value) + " (expected " + NoTrailZeros(expected) + ")");
}

// ALCH-02, ALCH-03, ALCH-08 (situation-free; drinks by script, restores toxicity and removes the effects).
function GMTest_alch02()
{
	var witcher : W3PlayerWitcher;
	var buff : CBaseGameplayEffect;
	var d1, d2 : float;
	var tox : float;

	witcher = GetWitcherPlayer();
	tox = witcher.GetStat(BCS_Toxicity, true);

	// ALCH-03 and ALCH-08 values, as held items read them (DL3: legacy's data).
	GMTestAlchItemCheck('Thunderbolt 1', 'duration', 30, "ALCH-03"); GMTestAlchItemCheck('Thunderbolt 3', 'duration', 90, "ALCH-03");
	GMTestAlchItemCheck('Thunderbolt 1', 'toxicity', 20, "ALCH-03");
	GMTestAlchItemCheck('Petri Philtre 2', 'duration', 60, "ALCH-03"); GMTestAlchItemCheck('Petri Philtre 1', 'toxicity', 20, "ALCH-03");
	GMTestAlchItemCheck('Full Moon 1', 'duration', 90, "ALCH-03"); GMTestAlchItemCheck('Full Moon 3', 'duration', 150, "ALCH-03");
	GMTestAlchItemCheck('Full Moon 1', 'toxicity', 30, "ALCH-03");
	GMTestAlchItemCheck('Black Blood 1', 'toxicity', 30, "ALCH-03"); GMTestAlchItemCheck('Black Blood 3', 'duration', 120, "ALCH-03");
	GMTestAlchItemCheck('Cat 1', 'toxicity', 10, "ALCH-03"); GMTestAlchItemCheck('Cat 3', 'duration', 480, "ALCH-03");
	GMTestAlchItemCheck('Tawny Owl 1', 'toxicity', 15, "ALCH-03"); GMTestAlchItemCheck('Tawny Owl 3', 'duration', 60, "ALCH-03");
	GMTestAlchItemCheck('Killer Whale 1', 'toxicity', 10, "ALCH-08"); GMTestAlchItemCheck('Killer Whale 1', 'duration', 180, "ALCH-08");
	GMTestAlchItemCheck('Pheromone Potion Bear 1', 'toxicity', 10, "ALCH-08"); GMTestAlchItemCheck('Pheromone Potion Nekker 1', 'duration', 120, "ALCH-08");
	GMTestAlchItemCheck('Pheromone Potion Drowner 1', 'quality', 4, "ALCH-08");
	GMTestAlchItemCheck('Pops Antidote', 'toxicity', 10, "ALCH-08");
	GMTestReport(GMIsPheromoneRecipe('Recipe for Bear Pheromone Potion 1') && !GMIsPheromoneRecipe('Recipe for Swallow 1'), "ALCH-08 pheromone formulas not counted by Acquired Tolerance");

	// ALCH-02: a second dose adds its duration.
	witcher.RemoveAllBuffsOfType(EET_Thunderbolt);
	buff = GMTestAlchDrink('Thunderbolt 1');
	d1 = buff.GetDurationLeft();
	buff = GMTestAlchDrink('Thunderbolt 1');
	d2 = buff.GetDurationLeft();
	GMTestReport(AbsF(d2 - 2 * d1) < 1, "ALCH-02 Thunderbolt 1 twice stacks: " + NoTrailZeros(RoundTo(d1, 1)) + " s -> " + NoTrailZeros(RoundTo(d2, 1)) + " s");
	// Equal strength (Thunderbolt's tiers too): a higher tier raises the effect, the durations add up (legacy).
	buff = GMTestAlchDrink('Thunderbolt 3');
	GMTestReport(buff.GetBuffLevel() == 3 && AbsF(buff.GetDurationLeft() - d2 - 90) < 1, "ALCH-02 Thunderbolt 3 on 1 raises it and adds its time: level " + buff.GetBuffLevel() + ", " + NoTrailZeros(RoundTo(buff.GetDurationLeft(), 1)) + " s");
	d1 = buff.GetDurationLeft();
	buff = GMTestAlchDrink('Thunderbolt 1');
	GMTestReport(buff.GetBuffLevel() == 3 && witcher.HasAbility('ThunderboltEffect_Level3') && !witcher.HasAbility('ThunderboltEffect_Level1') && AbsF(buff.GetDurationLeft() - d1 - 30) < 1,
		"ALCH-02 DL12 Thunderbolt 1 on 3 keeps tier 3 and adds its time: level " + buff.GetBuffLevel() + ", " + NoTrailZeros(RoundTo(buff.GetDurationLeft(), 1)) + " s");
	witcher.RemoveAllBuffsOfType(EET_Thunderbolt);

	// DL12: Cat (no main value: equal strength) 3, then 1: the durations add up and tier 3 stays.
	witcher.RemoveAllBuffsOfType(EET_Cat);
	buff = GMTestAlchDrink('Cat 3');
	d1 = buff.GetDurationLeft();
	buff = GMTestAlchDrink('Cat 1');
	GMTestReport(buff.GetBuffLevel() == 3 && buff.GetDurationLeft() > d1 + 200 && witcher.HasAbility('CatEffect_Level3') && !witcher.HasAbility('CatEffect_Level1'),
		"ALCH-02 DL12 Cat 1 on Cat 3 keeps tier 3 (" + buff.GetBuffLevel() + ") and adds its time: " + NoTrailZeros(RoundTo(d1, 1)) + " s -> " + NoTrailZeros(RoundTo(buff.GetDurationLeft(), 1)) + " s");
	witcher.RemoveAllBuffsOfType(EET_Cat);
	GMTestAlchDrink('Cat 1');
	buff = GMTestAlchDrink('Cat 3');
	GMTestReport(buff.GetBuffLevel() == 3 && witcher.HasAbility('CatEffect_Level3') && !witcher.HasAbility('CatEffect_Level1'), "ALCH-02 Cat 3 on Cat 1 raises it to tier 3 (" + buff.GetBuffLevel() + ")");
	witcher.RemoveAllBuffsOfType(EET_Cat);

	// Decoctions refresh instead of stacking.
	witcher.RemoveAllBuffsOfType(EET_Mutagen03);
	buff = GMTestAlchDrink('Mutagen 3');
	d1 = buff.GetDurationLeft();
	buff = GMTestAlchDrink('Mutagen 3');
	GMTestReport(AbsF(buff.GetDurationLeft() - d1) < 1, "ALCH-02 a second Cockatrice decoction refreshes: " + NoTrailZeros(RoundTo(d1, 1)) + " s -> " + NoTrailZeros(RoundTo(buff.GetDurationLeft(), 1)) + " s");
	witcher.RemoveAllBuffsOfType(EET_Mutagen03);
	witcher.SetToxicityOffset(0);

	// ALCH-08: the bear pheromone befriends grizzly bears while it lasts.
	witcher.RemoveAllBuffsOfType(EET_PheromoneBear);
	GMTestAlchDrink('Pheromone Potion Bear 1');
	GMTestReport(theGame.GetGlobalAttitude('AG_grizzly_bear', 'player') == AIA_Friendly, "ALCH-08 bear pheromone: grizzly bears friendly");
	witcher.RemoveAllBuffsOfType(EET_PheromoneBear);
	GMTestReport(theGame.GetGlobalAttitude('AG_grizzly_bear', 'player') == AIA_Hostile, "ALCH-08 bear pheromone ended: grizzly bears hostile");

	GMTestReport(!witcher.GMCannotDrinkNow(), "ALCH-02 drinking allowed outside special attacks and channelled signs");
	witcher.ForceSetStat(BCS_Toxicity, tox);
}

// ALCH-02: during a special attack or a channelled sign (start one first) drinking is refused.
exec function gmtest_alch02_cannot(expected : bool)
{
	GMTestReport(GetWitcherPlayer().GMCannotDrinkNow() == expected, "ALCH-02 drinking refused " + expected + " (combat action " + (int)thePlayer.GetBehaviorVariable('combatActionType') + ", in action " + thePlayer.IsInCombatAction() + ")");
}

// ALCH-04, ALCH-05 (situation-free; drinks by script, restores what it changes).
function GMTest_alch04()
{
	var witcher : W3PlayerWitcher;
	var buff : CBaseGameplayEffect;
	var maxVit, vit, tox : float;

	witcher = GetWitcherPlayer();
	tox = witcher.GetStat(BCS_Toxicity, true);
	maxVit = witcher.GetStatMax(BCS_Vitality);

	GMTestAlchItemCheck('Swallow 1', 'toxicity', 15, "ALCH-04"); GMTestAlchItemCheck('Swallow 1', 'duration', 30, "ALCH-04");
	GMTestAlchCheck('SwallowEffect_Level3', 'bleeding_resistance_perc', 0.5, "ALCH-04");
	GMTestAlchItemCheck('White Raffards Decoction 3', 'ammo', 2, "ALCH-04");
	GMTestAlchItemCheck('White Honey 3', 'ammo', 4, "ALCH-04");
	GMTestAlchItemCheck('Golden Oriole 1', 'toxicity', 15, "ALCH-05");
	GMTestAlchCheck('GoldenOrioleEffect_Level2', 'poison_resistance_perc', 0.35, "ALCH-05");
	GMTestAlchCheck('GoldenOrioleEffect_Level3', 'poison_immunity_duration', 5, "ALCH-05");

	// Swallow stops bleeding, on every dose.
	witcher.RemoveAllBuffsOfType(EET_Swallow);
	witcher.AddEffectDefault(EET_Bleeding, witcher, 'gmtest');
	GMTestAlchDrink('Swallow 1');
	GMTestReport(!witcher.HasBuff(EET_Bleeding), "ALCH-04 Swallow stops bleeding");
	witcher.AddEffectDefault(EET_Bleeding, witcher, 'gmtest');
	GMTestAlchDrink('Swallow 1');
	GMTestReport(!witcher.HasBuff(EET_Bleeding), "ALCH-04 a second Swallow stops bleeding again");

	// White Raffard heals 35% at T1 without raising maximum Vitality, every dose, and keeps Swallow.
	witcher.ForceSetStat(BCS_Vitality, maxVit * 0.2);
	vit = witcher.GetStat(BCS_Vitality);
	buff = GMTestAlchDrink('White Raffards Decoction 1');
	GMTestReport(AbsF(witcher.GetStat(BCS_Vitality) - vit - 0.35 * maxVit) < 2 && AbsF(witcher.GetStatMax(BCS_Vitality) - maxVit) < 0.5,
		"ALCH-04 White Raffard 1 heals 35%: " + NoTrailZeros(RoundTo(vit, 1)) + " -> " + NoTrailZeros(RoundTo(witcher.GetStat(BCS_Vitality), 1)) + " of " + NoTrailZeros(witcher.GetStatMax(BCS_Vitality)) + " (max before " + NoTrailZeros(maxVit) + ")");
	GMTestReport(witcher.HasBuff(EET_Swallow), "ALCH-04 White Raffard does not cancel Swallow");
	vit = witcher.GetStat(BCS_Vitality);
	witcher.AddEffectDefault(EET_Bleeding, witcher, 'gmtest');
	GMTestAlchDrink('White Raffards Decoction 1');
	GMTestReport(witcher.GetStat(BCS_Vitality) > vit + 0.3 * maxVit && !witcher.HasBuff(EET_Bleeding), "ALCH-04 a second White Raffard heals again and stops bleeding: " + NoTrailZeros(RoundTo(vit, 1)) + " -> " + NoTrailZeros(RoundTo(witcher.GetStat(BCS_Vitality), 1)));
	witcher.RemoveAllBuffsOfType(EET_WhiteRaffardDecoction);
	witcher.RemoveAllBuffsOfType(EET_Swallow);

	// White Honey clears toxicity on every dose.
	witcher.RemoveAllBuffsOfType(EET_WhiteHoney);
	GMTestAlchDrink('White Honey 1');
	witcher.ForceSetStat(BCS_Toxicity, 30);
	witcher.AddToxicityOffset(20);
	GMTestAlchDrinkKeepTox('White Honey 1');
	GMTestReport(witcher.HasBuff(EET_WhiteHoney) && witcher.GetStat(BCS_Toxicity) == 0, "ALCH-04 a second White Honey clears toxicity and the locked toxicity again: " + witcher.GetStat(BCS_Toxicity));
	witcher.RemoveAllBuffsOfType(EET_WhiteHoney);

	// Golden Oriole: every tier cures poison; T3 gives a short immunity; no healing from poison.
	witcher.RemoveAllBuffsOfType(EET_GoldenOriole);
	witcher.AddEffectDefault(EET_Poison, witcher, 'gmtest');
	GMTestReport(witcher.HasBuff(EET_Poison), "ALCH-05 poison applied (setup)");
	GMTestAlchDrink('Golden Oriole 1');
	GMTestReport(!witcher.HasBuff(EET_Poison), "ALCH-05 Golden Oriole 1 cures poison");
	witcher.AddEffectDefault(EET_Poison, witcher, 'gmtest');
	GMTestReport(witcher.HasBuff(EET_Poison), "ALCH-05 Golden Oriole 1: no poison immunity");
	witcher.RemoveAllBuffsOfType(EET_GoldenOriole);
	witcher.RemoveAllBuffsOfType(EET_Poison);
	GMTestAlchDrink('Golden Oriole 3');
	witcher.AddEffectDefault(EET_Poison, witcher, 'gmtest');
	GMTestReport(!witcher.HasBuff(EET_Poison), "ALCH-05 Golden Oriole 3: poison immunity right after drinking");
	witcher.RemoveAllBuffsOfType(EET_GoldenOriole);
	witcher.AddEffectDefault(EET_Poison, witcher, 'gmtest');
	GMTestReport(witcher.HasBuff(EET_Poison), "ALCH-05 Golden Oriole 3 ended: the immunity is gone");
	witcher.RemoveAllBuffsOfType(EET_Poison);

	witcher.ForceSetStat(BCS_Vitality, maxVit);
	witcher.ForceSetStat(BCS_Toxicity, tox);

	// Audit F1: Swallow 1 stays on; GMTest_alch04_after() (in gmtest_panel(), the regression's next call)
	// drinks the next doses once it has run its updates.
	witcher.RemoveAllBuffsOfType(EET_Swallow);
	GMTestAlchDrink('Swallow 1');
	witcher.ForceSetStat(BCS_Toxicity, tox);
	witcher.gmTestSwallowPending = true;
}

exec function gmtest_alch04()
{
	GMTest_alch04();
}

@addField(CR4Player)
var gmTestSwallowPending : bool;

// ALCH-04, audit F1: doses of Swallow drunk in a later call than the running one (whose own regen value its
// updates have zeroed) stack as DL12 says: Swallow 3 on 1 raises it to tier 3 and adds its time, Swallow 1 on
// 3 adds its time and tier 3 stays. Does nothing unless GMTest_alch04() ran before.
function GMTest_alch04_after()
{
	var witcher : W3PlayerWitcher;
	var buff : CBaseGameplayEffect;
	var val : SAbilityAttributeValue;
	var tox, left, added : float;

	witcher = GetWitcherPlayer();
	if(!witcher.gmTestSwallowPending)
		return;
	witcher.gmTestSwallowPending = false;
	tox = witcher.GetStat(BCS_Toxicity, true);
	buff = witcher.GetBuff(EET_Swallow);
	val = buff.GetEffectValue();
	GMTestReport(buff && CalculateAttributeValue(val) == 0, "ALCH-04 audit F1 the running Swallow 1 has updated (its own regen value " + NoTrailZeros(CalculateAttributeValue(val)) + ")");
	left = buff.GetDurationLeft();
	added = GMTestAlchItemValue('Swallow 3', 'duration');
	buff = GMTestAlchDrink('Swallow 3');
	GMTestReport(buff.GetBuffLevel() == 3 && witcher.HasAbility('SwallowEffect_Level3') && !witcher.HasAbility('SwallowEffect_Level1') && AbsF(buff.GetDurationLeft() - left - added) < 1,
		"ALCH-04 audit F1 Swallow 3 on a running Swallow 1 raises it and adds its time: level " + buff.GetBuffLevel() + ", " + NoTrailZeros(RoundTo(left, 1)) + " s -> " + NoTrailZeros(RoundTo(buff.GetDurationLeft(), 1)) + " s");
	left = buff.GetDurationLeft();
	added = GMTestAlchItemValue('Swallow 1', 'duration');
	buff = GMTestAlchDrink('Swallow 1');
	GMTestReport(buff.GetBuffLevel() == 3 && witcher.HasAbility('SwallowEffect_Level3') && !witcher.HasAbility('SwallowEffect_Level1') && AbsF(buff.GetDurationLeft() - left - added) < 1,
		"ALCH-04 audit F1 DL12 Swallow 1 on a running Swallow 3 keeps tier 3 and adds its time: level " + buff.GetBuffLevel() + ", " + NoTrailZeros(RoundTo(left, 1)) + " s -> " + NoTrailZeros(RoundTo(buff.GetDurationLeft(), 1)) + " s");
	witcher.RemoveAllBuffsOfType(EET_Swallow);
	witcher.ForceSetStat(BCS_Toxicity, tox);
}

exec function gmtest_alch04_after()
{
	GMTest_alch04_after();
}

// Drinks without clearing toxicity first (refills the potion's charges).
function GMTestAlchDrinkKeepTox(itemName : name) : CBaseGameplayEffect
{
	var witcher : W3PlayerWitcher;
	var ids : array<SItemUniqueId>;
	var effectType : EEffectType;
	var abilityName : name;

	witcher = GetWitcherPlayer();
	ids = witcher.inv.GetItemsByName(itemName);
	if(ids.Size() == 0)
		ids = witcher.inv.AddAnItem(itemName, 1);
	witcher.inv.SingletonItemSetAmmo(ids[0], witcher.inv.SingletonItemGetMaxAmmo(ids[0]));
	witcher.inv.GetPotionItemBuffData(ids[0], effectType, abilityName);
	witcher.DrinkPreparedPotion(EES_InvalidSlot, ids[0]);
	return witcher.GetBuff(effectType);
}

// Regen in time: gmtest_alch_regen_a('Swallow 1', true) drinks (an empty name: none), sets Vitality (true) or
// stamina (false) to 20%; gmtest_alch_regen_b(true) a few seconds later reports the regen per second.
exec function gmtest_alch_regen_a(itemName : name, vitality : bool)
{
	var stat : EBaseCharacterStats;

	if(IsNameValid(itemName))
		GMTestAlchDrink(itemName);
	if(vitality) stat = BCS_Vitality; else stat = BCS_Stamina;
	thePlayer.ForceSetStat(stat, 0.2 * thePlayer.GetStatMax(stat));
	if(vitality) thePlayer.StartVitalityRegen(); else thePlayer.StartStaminaRegen();
	thePlayer.GMTestAlchMarkStat(stat);
	LogChannel('GMTest', "INFO ALCH regen start " + itemName + ": " + NoTrailZeros(RoundTo(thePlayer.gmTestAlchTox, 1)) + " of " + NoTrailZeros(thePlayer.GetStatMax(stat)) + ", combat " + thePlayer.IsInCombat());
}

exec function gmtest_alch_regen_b(vitality : bool)
{
	var stat : EBaseCharacterStats;
	var dt : float;

	if(vitality) stat = BCS_Vitality; else stat = BCS_Stamina;
	dt = theGame.GetEngineTimeAsSeconds() - thePlayer.gmTestAlchTime;
	LogChannel('GMTest', "INFO ALCH regen " + NoTrailZeros(RoundTo((thePlayer.GetStat(stat) - thePlayer.gmTestAlchTox) / dt, 2)) + "/s over " + NoTrailZeros(RoundTo(dt, 1)) + " s, combat " + thePlayer.IsInCombat());
}

@addMethod(CR4Player)
function GMTestAlchMarkStat(stat : EBaseCharacterStats)
{
	gmTestAlchTime = theGame.GetEngineTimeAsSeconds();
	gmTestAlchTox = GetStat(stat);
}

// The regen values in play: Geralt's own stamina and Vitality regen effects and the regen potions' own effects.
exec function gmtest_alch_regenvals()
{
	var types : array<EEffectType>;
	var buff : CBaseGameplayEffect;
	var v : SAbilityAttributeValue;
	var i : int;

	types.PushBack(EET_AutoStaminaRegen); types.PushBack(EET_AutoVitalityRegen); types.PushBack(EET_TawnyOwl);
	types.PushBack(EET_ReinaldPhiltre); types.PushBack(EET_Swallow);
	for(i = 0; i < types.Size(); i += 1)
	{
		buff = thePlayer.GetBuff(types[i]);
		if(buff)
		{
			v = buff.GetEffectValue();
			LogChannel('GMTest', "INFO ALCH regen value " + types[i] + ": add " + NoTrailZeros(v.valueAdditive) + " mult " + NoTrailZeros(v.valueMultiplicative) + " (stamina max " + NoTrailZeros(thePlayer.GetStatMax(BCS_Stamina)) + ")");
		}
		else
			LogChannel('GMTest', "INFO ALCH regen value " + types[i] + ": no effect");
	}
}

// ALCH-05 in time: Golden Oriole 3's poison immunity lasts 5 s while the potion runs on.
exec function gmtest_alch05_timer_a()
{
	thePlayer.RemoveAllBuffsOfType(EET_GoldenOriole);
	GMTestAlchDrink('Golden Oriole 3');
	thePlayer.AddEffectDefault(EET_Poison, thePlayer, 'gmtest');
	GMTestReport(!thePlayer.HasBuff(EET_Poison), "ALCH-05 Golden Oriole 3: immune to poison at once");
}

exec function gmtest_alch05_timer_b()
{
	thePlayer.AddEffectDefault(EET_Poison, thePlayer, 'gmtest');
	GMTestReport(thePlayer.HasBuff(EET_GoldenOriole) && thePlayer.HasBuff(EET_Poison), "ALCH-05 Golden Oriole 3 after 5 s: still active (" + thePlayer.HasBuff(EET_GoldenOriole) + "), poison takes again (" + thePlayer.HasBuff(EET_Poison) + ")");
	thePlayer.RemoveAllBuffsOfType(EET_Poison);
	thePlayer.RemoveAllBuffsOfType(EET_GoldenOriole);
}

// ALCH-04, audit F1, real drinks: gmtest_alch04_slot('Swallow 3') puts the potion in the first potion slot and
// drinks it from there (OnPotionDrinkKeyboardsInput, what the slot key calls); call again later with another tier.
exec function gmtest_alch04_slot(itemName : name)
{
	var witcher : W3PlayerWitcher;
	var ids : array<SItemUniqueId>;
	var buff : CBaseGameplayEffect;
	var before : float;

	witcher = GetWitcherPlayer();
	buff = witcher.GetBuff(EET_Swallow);
	if(buff)
		before = buff.GetDurationLeft();
	ids = witcher.inv.AddAnItem(itemName, 1);
	witcher.inv.SingletonItemSetAmmo(ids[0], witcher.inv.SingletonItemGetMaxAmmo(ids[0]));
	witcher.DrainToxicity(witcher.GetStat(BCS_Toxicity, true));
	witcher.EquipItemInGivenSlot(ids[0], EES_Potion1, false);
	witcher.OnPotionDrinkKeyboardsInput(EES_Potion1);
	buff = witcher.GetBuff(EET_Swallow);
	LogChannel('GMTest', "INFO ALCH-04 drank " + itemName + " from the slot: Swallow level " + buff.GetBuffLevel() + ", " + NoTrailZeros(RoundTo(before, 1)) + " s -> " + NoTrailZeros(RoundTo(buff.GetDurationLeft(), 1)) + " s, tier 3 ability " + witcher.HasAbility('SwallowEffect_Level3') + ", tier 1 ability " + witcher.HasAbility('SwallowEffect_Level1'));
}
