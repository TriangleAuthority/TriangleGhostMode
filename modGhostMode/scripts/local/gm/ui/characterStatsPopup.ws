// Character panel (CharacterStatsPopup.ws: the stats view of the inventory and the stats popup).
// STAM-03: the stamina section lists every action's cost; STAM-09: Whirl's and Rend's per second
// while the skill is equipped.
// STAM-04: the stamina regen lines include the regen options. STAM-05: with the armor regen
// penalty option on, a line shows the armor regen modifier (the regen line already includes
// it through CalculatedArmorStaminaRegenBonus, which is 0 while the option is off).
// The wrapper rewrites the value of the line vanilla just added.
// See docs/features/stam.md.

function GMStaminaRegenPerSecond(attributeName : name) : float
{
	var value : SAbilityAttributeValue;
	var regen : float;

	value = GetWitcherPlayer().GetAttributeValue(attributeName);
	GMModStaminaRegenValue(attributeName, value);
	regen = value.valueAdditive + value.valueMultiplicative * GetWitcherPlayer().GetStatMax(BCS_Stamina);
	// The armor modifier applies to combat regen only, as in W3RegenEffect.OnUpdate.
	if(attributeName == 'staminaRegen')
		regen *= 1 + GetWitcherPlayer().CalculatedArmorStaminaRegenBonus();
	return regen;
}

function GMStaminaCostText(varKey : name) : string
{
	var witcher : W3PlayerWitcher;
	var abilities : W3PlayerAbilityManager;
	var cost : float;

	witcher = GetWitcherPlayer();
	abilities = (W3PlayerAbilityManager)witcher.abilityManager;
	switch(varKey)
	{
		case 'gmStaminaCostLight' :		cost = witcher.GetStaminaActionCost(ESAT_LightAttack, '', 0); break;
		case 'gmStaminaCostHeavy' :		cost = witcher.GetStaminaActionCost(ESAT_HeavyAttack, '', 0); break;
		case 'gmStaminaCostCounter' :	cost = witcher.GetStaminaActionCost(ESAT_Counterattack, '', 0); break;
		case 'gmStaminaCostParry' :		cost = witcher.GetStaminaActionCost(ESAT_Parry, '', 0); break;
		case 'gmStaminaCostDodge' :		cost = witcher.GetStaminaActionCost(ESAT_Dodge, '', 0); break;
		case 'gmStaminaCostRoll' :		cost = witcher.GetStaminaActionCost(ESAT_Roll, '', 0); break;
		case 'gmStaminaCostSprint' :	return NoTrailZeros(RoundTo(witcher.GetStaminaActionCost(ESAT_Sprint, '', 1), 2)) + "/" + GetLocStringByKeyExt("per_second");
		case 'gmStaminaCostJump' :		cost = witcher.GetStaminaActionCost(ESAT_Jump, '', 0); break;
		case 'gmStaminaCostItem' :		cost = witcher.GetStaminaActionCost(ESAT_UsableItem, '', 0); break;
		case 'gmStaminaCostAard' :		cost = abilities.GetSkillStaminaUseCost(S_Magic_1); break;
		case 'gmStaminaCostIgni' :		cost = abilities.GetSkillStaminaUseCost(S_Magic_2); break;
		case 'gmStaminaCostYrden' :		cost = abilities.GetSkillStaminaUseCost(S_Magic_3); break;
		case 'gmStaminaCostQuen' :		cost = abilities.GetSkillStaminaUseCost(S_Magic_4); break;
		case 'gmStaminaCostAxii' :		cost = abilities.GetSkillStaminaUseCost(S_Magic_5); break;
		case 'gmStaminaCostWhirl' :		return NoTrailZeros(RoundTo(witcher.GMGetWhirlStaminaCost(1), 2)) + "/" + GetLocStringByKeyExt("per_second");
		case 'gmStaminaCostRend' :		return NoTrailZeros(RoundTo(witcher.GetStaminaActionCost(ESAT_Ability, witcher.GetSkillAbilityName(S_Sword_s02), 1), 2)) + "/" + GetLocStringByKeyExt("per_second");
	}
	return NoTrailZeros(RoundTo(cost, 2));
}

@wrapMethod
function AddCharacterStat(tag : string, varKey : name, locKey : string, iconTag : string, toArray : CScriptedFlashArray, flashMaster : CScriptedFlashValueStorage) : CScriptedFlashObject
{
	var statObject : CScriptedFlashObject;

	statObject = wrappedMethod(tag, varKey, locKey, iconTag, toArray, flashMaster);
	if(varKey == 'staminaRegen' || varKey == 'staminaOutOfCombatRegen')
	{
		statObject.SetMemberFlashString("value", NoTrailZeros(RoundMath(GMStaminaRegenPerSecond(varKey))) + "/" + GetLocStringByKeyExt("per_second"));
	}
	else if(varKey == 'staminaRegenArmorMod')
	{
		statObject.SetMemberFlashString("value", NoTrailZeros(RoundMath(GetWitcherPlayer().CalculatedArmorStaminaRegenBonus() * 100)) + " %");
	}

	else if(StrStartsWith(NameToString(varKey), "gmStaminaCost"))
	{
		statObject.SetMemberFlashString("value", GMStaminaCostText(varKey));
	}

	if(varKey == 'staminaRegen')
	{
		// STAM-05: the armor modifier line, after the combat regen line.
		if(GMIsArmorRegenPenaltyEnabled())
			AddCharacterStat("defStat16", 'staminaRegenArmorMod', "attribute_name_staminaRegen_armor_mod", "", toArray, flashMaster);
		// STAM-03, STAM-09: every action's stamina cost (legacy Ghost Mode's lines and strings).
		AddCharacterStat("defStat18", 'gmStaminaCostLight', "attribute_name_stamina_cost_light", "", toArray, flashMaster);
		AddCharacterStat("defStat19", 'gmStaminaCostHeavy', "attribute_name_stamina_cost_heavy", "", toArray, flashMaster);
		AddCharacterStat("defStat20", 'gmStaminaCostCounter', "attribute_name_stamina_cost_counter", "", toArray, flashMaster);
		AddCharacterStat("defStat21", 'gmStaminaCostParry', "attribute_name_stamina_cost_parry", "", toArray, flashMaster);
		AddCharacterStat("defStat22", 'gmStaminaCostDodge', "attribute_name_stamina_cost_dodge", "", toArray, flashMaster);
		AddCharacterStat("defStat23", 'gmStaminaCostRoll', "attribute_name_stamina_cost_roll", "", toArray, flashMaster);
		AddCharacterStat("defStat24", 'gmStaminaCostSprint', "attribute_name_stamina_cost_sprint", "", toArray, flashMaster);
		AddCharacterStat("defStat25", 'gmStaminaCostJump', "attribute_name_stamina_cost_jump", "", toArray, flashMaster);
		AddCharacterStat("defStat26", 'gmStaminaCostItem', "attribute_name_stamina_cost_item", "", toArray, flashMaster);
		AddCharacterStat("defStat27", 'gmStaminaCostAard', "attribute_name_stamina_cost_aard", "", toArray, flashMaster);
		AddCharacterStat("defStat28", 'gmStaminaCostIgni', "attribute_name_stamina_cost_igni", "", toArray, flashMaster);
		AddCharacterStat("defStat29", 'gmStaminaCostYrden', "attribute_name_stamina_cost_yrden", "", toArray, flashMaster);
		AddCharacterStat("defStat30", 'gmStaminaCostQuen', "attribute_name_stamina_cost_quen", "", toArray, flashMaster);
		AddCharacterStat("defStat31", 'gmStaminaCostAxii', "attribute_name_stamina_cost_axii", "", toArray, flashMaster);
		if(GetWitcherPlayer().CanUseSkill(S_Sword_s01) || GetWitcherPlayer().CanUseSkill(S_Sword_s35))
			AddCharacterStat("defStat32", 'gmStaminaCostWhirl', "attribute_name_stamina_cost_whirl", "", toArray, flashMaster);
		if(GetWitcherPlayer().CanUseSkill(S_Sword_s02))
			AddCharacterStat("defStat33", 'gmStaminaCostRend', "attribute_name_stamina_cost_rend", "", toArray, flashMaster);
	}

	return statObject;
}
