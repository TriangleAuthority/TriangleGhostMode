// Character panel (CharacterStatsPopup.ws: the stats view of the inventory and the stats popup).
// STAM-03: the stamina section lists every action's cost; STAM-09: Whirl's and Rend's per second
// while the skill is equipped.
// STAM-04: the stamina regen lines include the regen options. STAM-05: with the armor regen
// penalty option on, a line shows the armor regen modifier (the regen line already includes
// it through CalculatedArmorStaminaRegenBonus, which is 0 while the option is off).
// The wrapper rewrites the value of the line vanilla just added.
// UI-05: the armor regen modifier line sits under Armor (DU3); Vitality regen with its multiplicative part;
// sign power as its raw value; the misc section's money bonus and adrenaline gain lines (legacy's).
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
	else if(varKey == 'vitalityRegen' || varKey == 'vitalityCombatRegen')
	{
		statObject.SetMemberFlashString("value", NoTrailZeros(RoundMath(GMPanelVitalityRegen(varKey))) + "/" + GetLocStringByKeyExt("per_second"));
	}
	else if(varKey == 'spell_power')
	{
		statObject.SetMemberFlashString("value", "+" + (string)RoundMath(GMPanelRawSignPower() * 100) + " %");
	}

	if(varKey == 'staminaRegen')
	{
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

// UI-02: the sword and crossbow sections of the stats popup and the inventory's stats view (legacy's),
// and the summary lines of both character menus and the inventory: "Damage per hit" for each sword (the
// average of the fast and strong expected hits, UI-01); per attack type attack power, damage, crit chance,
// crit power and crit damage; the effect chances with Crippling Strikes (either tree) and Metamorphosis;
// the crossbow's attack power, crit chance, crit damage, adrenaline gain per bolt (Cold Blood), the bolt's
// damage under its type's name and its elemental damage. Instant kill shows the larger sword's chance.
// The labels of 1.32's damage-per-second lines are legacy's (string rows by key hash).
// See docs/features/ui.md.
@replaceMethod
function GetPlayerStatsGFxData(parentFlashValueStorage : CScriptedFlashValueStorage) : CScriptedFlashObject
{ 
	var statsArray : CScriptedFlashArray;
	var gfxData    : CScriptedFlashObject;
	
	var gfxSilverDamage : CScriptedFlashObject;
	var gfxSteelDamage  : CScriptedFlashObject;
	var gfxArmor 		: CScriptedFlashObject;
	var gfxVitality 	: CScriptedFlashObject;
	var gfxSpellPower 	: CScriptedFlashObject;
	var gfxSpellPower2 	: CScriptedFlashObject;	//modSigns
	var gfxToxicity 	: CScriptedFlashObject;
	var gfxStamina 		: CScriptedFlashObject;
	var gfxCrossbow  	: CScriptedFlashObject;
	var gfxAdditional  	: CScriptedFlashObject;
	
	var gfxSilverDamageSub : CScriptedFlashArray;
	var gfxSteelDamageSub  : CScriptedFlashArray;
	var gfxArmorSub 	   : CScriptedFlashArray;
	var gfxVitalitySub 	   : CScriptedFlashArray;
	var gfxSpellPowerSub   : CScriptedFlashArray;
	var gfxSpellPowerSub2  : CScriptedFlashArray;	//modSigns
	var gfxToxicitySub 	   : CScriptedFlashArray;
	var gfxStaminaSub	   : CScriptedFlashArray;
	var gfxCrossbowSub     : CScriptedFlashArray;
	var gfxAdditionalSub   : CScriptedFlashArray;
	
	var gameTime		: GameTime;
	var gameTimeHours	: string;
	var gameTimeMinutes : string;
	
	gfxData = parentFlashValueStorage.CreateTempFlashObject();
	statsArray = parentFlashValueStorage.CreateTempFlashArray();
	
	
	
	
	
	
	
	
	
	

	
	
	//modSigns: UI-02, the sword sections reworked (legacy): per attack type attack power, damage, crit chance, crit power, crit damage, then the effect chances
	gfxSilverDamage = AddCharacterStatU("mainSilverStat", 'silverdamage', "panel_common_statistics_tooltip_silver_dph_gm", "attack_silver", statsArray, parentFlashValueStorage);	//modSigns: UI-02, damage per hit
	gfxSilverDamageSub = parentFlashValueStorage.CreateTempFlashArray();
	AddCharacterHeader("panel_common_statistics_tooltip_silver_dph_gm", gfxSilverDamageSub, parentFlashValueStorage, true, "Red");	//modSigns
	AddCharacterStatU("silverStat0", 'silverFastAP', "gm_combat_stats_fast_attack_power", "", gfxSilverDamageSub, parentFlashValueStorage);	//modSigns
	AddCharacterStatU("silverStat1", 'silverFastDmg', "panel_common_statistics_tooltip_silver_fast_dps", "", gfxSilverDamageSub, parentFlashValueStorage);	//modSigns
	AddCharacterStatU("silverStat2", 'silverFastCritChance', "panel_common_statistics_tooltip_silver_fast_crit_chance", "", gfxSilverDamageSub, parentFlashValueStorage);	//modSigns
	AddCharacterStatU("silverStat3", 'silverFastCritAP', "gm_combat_stats_fast_crit_attack_power", "", gfxSilverDamageSub, parentFlashValueStorage);	//modSigns
	AddCharacterStatU("silverStat4", 'silverFastCritDmg', "panel_common_statistics_tooltip_silver_fast_crit_dmg", "", gfxSilverDamageSub, parentFlashValueStorage);	//modSigns
	AddCharacterStatU("Dummy", '', "", "", gfxSilverDamageSub, parentFlashValueStorage);	//modSigns
	AddCharacterStatU("silverStat5", 'silverStrongAP', "gm_combat_stats_strong_attack_power", "", gfxSilverDamageSub, parentFlashValueStorage);	//modSigns
	AddCharacterStatU("silverStat6", 'silverStrongDmg', "panel_common_statistics_tooltip_silver_strong_dps", "", gfxSilverDamageSub, parentFlashValueStorage);	//modSigns
	AddCharacterStatU("silverStat7", 'silverStrongCritChance', "panel_common_statistics_tooltip_silver_strong_crit_chance", "", gfxSilverDamageSub, parentFlashValueStorage);	//modSigns
	AddCharacterStatU("silverStat8", 'silverStrongCritAP', "gm_combat_stats_strong_crit_attack_power", "", gfxSilverDamageSub, parentFlashValueStorage);	//modSigns
	AddCharacterStatU("silverStat9", 'silverStrongCritDmg', "panel_common_statistics_tooltip_silver_strong_crit_dmg", "", gfxSilverDamageSub, parentFlashValueStorage);	//modSigns
	AddCharacterStatU("Dummy", '', "", "", gfxSilverDamageSub, parentFlashValueStorage);	//modSigns
	AddCharacterStatU2("silverStat10", 'silver_desc_poinsonchance_mult', "attribute_name_desc_poinsonchance_mult", "", gfxSilverDamageSub, parentFlashValueStorage);	//modSigns
	AddCharacterStatU2("silverStat11", 'silver_desc_bleedingchance_mult', "attribute_name_desc_bleedingchance_mult", "", gfxSilverDamageSub, parentFlashValueStorage);	//modSigns
	AddCharacterStatU2("silverStat12", 'silver_desc_burningchance_mult', "attribute_name_desc_burningchance_mult", "", gfxSilverDamageSub, parentFlashValueStorage);	//modSigns
	AddCharacterStatU2("silverStat13", 'silver_desc_confusionchance_mult', "attribute_name_desc_confusionchance_mult", "", gfxSilverDamageSub, parentFlashValueStorage);	//modSigns
	AddCharacterStatU2("silverStat14", 'silver_desc_freezingchance_mult', "attribute_name_desc_freezingchance_mult", "", gfxSilverDamageSub, parentFlashValueStorage);	//modSigns
	AddCharacterStatU2("silverStat15", 'silver_desc_staggerchance_mult', "attribute_name_desc_staggerchance_mult", "", gfxSilverDamageSub, parentFlashValueStorage);	//modSigns
	gfxSilverDamage.SetMemberFlashArray("subStats", gfxSilverDamageSub);
	
	
	
	gfxSteelDamage = AddCharacterStatU("mainSteelStat", 'steeldamage', "panel_common_statistics_tooltip_steel_dph_gm", "attack_steel", statsArray, parentFlashValueStorage);	//modSigns: UI-02, damage per hit
	gfxSteelDamageSub = parentFlashValueStorage.CreateTempFlashArray();
	AddCharacterHeader("panel_common_statistics_tooltip_steel_dph_gm", gfxSteelDamageSub, parentFlashValueStorage, true, "Red");	//modSigns
	AddCharacterStatU("steelStat0", 'steelFastAP', "gm_combat_stats_fast_attack_power", "", gfxSteelDamageSub, parentFlashValueStorage);	//modSigns
	AddCharacterStatU("steelStat1", 'steelFastDmg', "panel_common_statistics_tooltip_steel_fast_dps", "", gfxSteelDamageSub, parentFlashValueStorage);	//modSigns
	AddCharacterStatU("steelStat2", 'steelFastCritChance', "panel_common_statistics_tooltip_steel_fast_crit_chance", "", gfxSteelDamageSub, parentFlashValueStorage);	//modSigns
	AddCharacterStatU("steelStat3", 'steelFastCritAP', "gm_combat_stats_fast_crit_attack_power", "", gfxSteelDamageSub, parentFlashValueStorage);	//modSigns
	AddCharacterStatU("steelStat4", 'steelFastCritDmg', "panel_common_statistics_tooltip_steel_fast_crit_dmg", "", gfxSteelDamageSub, parentFlashValueStorage);	//modSigns
	AddCharacterStatU("Dummy", '', "", "", gfxSteelDamageSub, parentFlashValueStorage);	//modSigns
	AddCharacterStatU("steelStat5", 'steelStrongAP', "gm_combat_stats_strong_attack_power", "", gfxSteelDamageSub, parentFlashValueStorage);	//modSigns
	AddCharacterStatU("steelStat6", 'steelStrongDmg', "panel_common_statistics_tooltip_steel_strong_dps", "", gfxSteelDamageSub, parentFlashValueStorage);	//modSigns
	AddCharacterStatU("steelStat7", 'steelStrongCritChance', "panel_common_statistics_tooltip_steel_strong_crit_chance", "", gfxSteelDamageSub, parentFlashValueStorage);	//modSigns
	AddCharacterStatU("steelStat8", 'steelStrongCritAP', "gm_combat_stats_strong_crit_attack_power", "", gfxSteelDamageSub, parentFlashValueStorage);	//modSigns
	AddCharacterStatU("steelStat9", 'steelStrongCritDmg', "panel_common_statistics_tooltip_steel_strong_crit_dmg", "", gfxSteelDamageSub, parentFlashValueStorage);	//modSigns
	AddCharacterStatU("Dummy", '', "", "", gfxSteelDamageSub, parentFlashValueStorage);	//modSigns
	AddCharacterStatU2("steelStat10", 'steel_desc_poinsonchance_mult', "attribute_name_desc_poinsonchance_mult", "", gfxSteelDamageSub, parentFlashValueStorage);	//modSigns
	AddCharacterStatU2("steelStat11", 'steel_desc_bleedingchance_mult', "attribute_name_desc_bleedingchance_mult", "", gfxSteelDamageSub, parentFlashValueStorage);	//modSigns
	AddCharacterStatU2("steelStat12", 'steel_desc_burningchance_mult', "attribute_name_desc_burningchance_mult", "", gfxSteelDamageSub, parentFlashValueStorage);	//modSigns
	AddCharacterStatU2("steelStat13", 'steel_desc_confusionchance_mult', "attribute_name_desc_confusionchance_mult", "", gfxSteelDamageSub, parentFlashValueStorage);	//modSigns
	AddCharacterStatU2("steelStat14", 'steel_desc_freezingchance_mult', "attribute_name_desc_freezingchance_mult", "", gfxSteelDamageSub, parentFlashValueStorage);	//modSigns
	AddCharacterStatU2("steelStat15", 'steel_desc_staggerchance_mult', "attribute_name_desc_staggerchance_mult", "", gfxSteelDamageSub, parentFlashValueStorage);	//modSigns
	gfxSteelDamage.SetMemberFlashArray("subStats", gfxSteelDamageSub);
	
	
	
	gfxArmor = AddCharacterStat("mainResStat", 'armor', "attribute_name_armor", "armor", statsArray, parentFlashValueStorage);
	gfxArmorSub = parentFlashValueStorage.CreateTempFlashArray();
	AddCharacterHeader("attribute_name_armor", gfxArmorSub, parentFlashValueStorage, true, "Red");
	AddCharacterStatF("defStat2", 'slashing_resistance_perc', "slashing_resistance_perc", "", gfxArmorSub, parentFlashValueStorage);
	AddCharacterStatF("defStat3", 'piercing_resistance_perc', "attribute_name_piercing_resistance_perc", "", gfxArmorSub, parentFlashValueStorage);
	AddCharacterStatF("defStat4", 'bludgeoning_resistance_perc', "bludgeoning_resistance_perc", "", gfxArmorSub, parentFlashValueStorage);
	AddCharacterStatF("defStat5", 'rending_resistance_perc', "attribute_name_rending_resistance_perc", "", gfxArmorSub, parentFlashValueStorage);
	AddCharacterStatF("defStat6", 'elemental_resistance_perc', "attribute_name_elemental_resistance_perc", "", gfxArmorSub, parentFlashValueStorage);
	AddCharacterStatU("defStat7", '', "", "", gfxArmorSub, parentFlashValueStorage);
	AddCharacterStatF("defStat8", 'poison_resistance_perc', "attribute_name_poison_resistance_perc", "", gfxArmorSub, parentFlashValueStorage);
	AddCharacterStatF("defStat9", 'bleeding_resistance_perc', "attribute_name_bleeding_resistance_perc", "", gfxArmorSub, parentFlashValueStorage);
	AddCharacterStatF("defStat10", 'burning_resistance_perc', "attribute_name_burning_resistance_perc", "", gfxArmorSub, parentFlashValueStorage);
	if(GMIsArmorRegenPenaltyEnabled())	//modSigns: UI-05, the armor regen modifier under Armor (DU3, legacy)
	{	//modSigns
		AddCharacterStatU("defStat11", '', "", "", gfxArmorSub, parentFlashValueStorage);	//modSigns
		AddCharacterStat("defStat16", 'staminaRegenArmorMod', "attribute_name_staminaRegen_armor_mod", "", gfxArmorSub, parentFlashValueStorage);	//modSigns
	}	//modSigns
	gfxArmor.SetMemberFlashArray("subStats", gfxArmorSub);
	
	
	
	gfxCrossbow = AddCharacterStat("majorStat4", 'crossbow', "item_category_crossbow", "crossbow", statsArray, parentFlashValueStorage);
	gfxCrossbowSub = parentFlashValueStorage.CreateTempFlashArray();
	AddCharacterHeader("item_category_crossbow", gfxCrossbowSub, parentFlashValueStorage, true, "Red");
	AddCharacterStatU("steelStat17", 'crossbowAttackPower', "attribute_name_attack_power", "", gfxCrossbowSub, parentFlashValueStorage);	//modSigns: UI-02, the crossbow section reworked (legacy)
	AddCharacterStatU("steelStat18", 'crossbowCritChance', "panel_common_statistics_tooltip_crossbow_crit_chance", "", gfxCrossbowSub, parentFlashValueStorage);	//modSigns
	AddCharacterStatU("steelStat19", 'crossbowCritDmgBonus', "attribute_name_critical_hit_damage_bonus", "", gfxCrossbowSub, parentFlashValueStorage);	//modSigns
	AddCharacterStatU("steelStat20", 'crossbow_adrenaline_gain', "gm_stat_adrenaline_gain", "", gfxCrossbowSub, parentFlashValueStorage);	//modSigns
	AddCharacterStatU("steelStat21", 'crossbowSteelDmg', "attribute_name_piercingdamage", "", gfxCrossbowSub, parentFlashValueStorage);	//modSigns: named by the bolt's damage type in AddCharacterStatU
	AddCharacterStatU("steelStat22", 'crossbowSilverDmg', "attribute_name_silverdamage", "", gfxCrossbowSub, parentFlashValueStorage);	//modSigns
	if(GetWitcherPlayer().GMCrossbowElementaDmgName() != '')	//modSigns
		AddCharacterStatU("steelStat23", 'crossbowElementaDmg', GetAttributeNameLocStr(GetWitcherPlayer().GMCrossbowElementaDmgName(), false), "", gfxCrossbowSub, parentFlashValueStorage);	//modSigns
	gfxCrossbow.SetMemberFlashArray("subStats", gfxCrossbowSub);
	
	
	
	gfxVitality =  AddCharacterStat("majorStat1", 'vitality', "vitality", "vitality", statsArray, parentFlashValueStorage);
	gfxVitalitySub = parentFlashValueStorage.CreateTempFlashArray();
	AddCharacterHeader("vitality", gfxVitalitySub, parentFlashValueStorage, true, "Green");
	AddCharacterStat("defStat12", 'vitalityRegen', "panel_common_statistics_tooltip_outofcombat_regen", "", gfxVitalitySub, parentFlashValueStorage);
	AddCharacterStat("defStat13", 'vitalityCombatRegen', "panel_common_statistics_tooltip_incombat_regen", "", gfxVitalitySub, parentFlashValueStorage);
	gfxVitality.SetMemberFlashArray("subStats", gfxVitalitySub);
	
	
	
	gfxToxicity = AddCharacterStat("majorStat2", 'toxicity', "attribute_name_toxicity", "toxicity", statsArray, parentFlashValueStorage);
	gfxToxicitySub = parentFlashValueStorage.CreateTempFlashArray();
	AddCharacterHeader("attribute_name_toxicity", gfxToxicitySub, parentFlashValueStorage, true, "Green");	
	AddCharacterStatToxicity("lockedToxicity", 'lockedToxicity', "toxicity_offset", "", gfxToxicitySub, parentFlashValueStorage);
	//modSigns: removed the current toxicity line (UI-04, legacy: the bar shows it)
	AddCharacterStatToxicity("avail_tox", 'avail_tox', "attribute_name_avail_tox", "", gfxToxicitySub, parentFlashValueStorage);	//modSigns: UI-04, legacy's toxicity lines
	AddCharacterStatToxicity("tox_dec_rate", 'tox_dec_rate', "attribute_name_tox_dec_rate", "", gfxToxicitySub, parentFlashValueStorage);	//modSigns
	AddCharacterStatToxicity("tox_overdose", 'tox_overdose', "attribute_name_tox_overdose", "", gfxToxicitySub, parentFlashValueStorage);	//modSigns
	AddCharacterStatToxicity("tox_hp_drain", 'tox_hp_drain', "attribute_name_tox_hp_drain", "", gfxToxicitySub, parentFlashValueStorage);	//modSigns
	gfxToxicity.SetMemberFlashArray("subStats", gfxToxicitySub);
	
	
	
	gfxSpellPower = AddCharacterStat("mainMagicStat", 'spell_power', "stat_signs", "spell_power", statsArray, parentFlashValueStorage);
	gfxSpellPowerSub = parentFlashValueStorage.CreateTempFlashArray();
	AddCharacterHeader("stat_signs", gfxSpellPowerSub, parentFlashValueStorage, true, "Blue");
	AddCharacterHeader("Aard", gfxSpellPowerSub, parentFlashValueStorage);
	AddCharacterStatSigns("aardStat1", 'aard_power', "aard_intensity", "", gfxSpellPowerSub, parentFlashValueStorage);	//modSigns: UI-03, the sign lines reworked (legacy): each sign's intensity and values
	AddCharacterStatSigns("aardStat2", 'aard_knockdownchance', "attribute_name_knockdown", "", gfxSpellPowerSub, parentFlashValueStorage);	//modSigns
	AddCharacterStatSigns("aardStat3", 'aard_heavyknockdownchance', "gm_sign_stats_heavy_knockdown", "", gfxSpellPowerSub, parentFlashValueStorage);	//modSigns
	AddCharacterStatSigns("aardStat4", 'aard_damage', "attribute_name_forcedamage", "", gfxSpellPowerSub, parentFlashValueStorage);	//modSigns
	AddCharacterHeader("Igni", gfxSpellPowerSub, parentFlashValueStorage);
	AddCharacterStatSigns("igniStat1", 'igni_power', "igni_intensity", "", gfxSpellPowerSub, parentFlashValueStorage);	//modSigns
	AddCharacterStatSigns("igniStat2", 'igni_burnchance', "effect_burning", "", gfxSpellPowerSub, parentFlashValueStorage);	//modSigns
	AddCharacterStatSigns("igniStat3", 'igni_damage', "attribute_name_firedamage", "", gfxSpellPowerSub, parentFlashValueStorage);	//modSigns
	AddCharacterStatSigns("igniStat3", 'igni_dmg_alt', "gm_sign_stats_channeling_damage_per_sec", "", gfxSpellPowerSub, parentFlashValueStorage);	//modSigns
	AddCharacterHeader("Quen", gfxSpellPowerSub, parentFlashValueStorage);
	AddCharacterStatSigns("quenStat1", 'quen_power', "quen_intensity", "", gfxSpellPowerSub, parentFlashValueStorage);	//modSigns
	AddCharacterStatSigns("quenStat1", 'quen_duration', "duration", "", gfxSpellPowerSub, parentFlashValueStorage);	//modSigns
	AddCharacterStatSigns("quenStat1", 'quen_discharge_pts', "gm_sign_stats_alt_quen_returned_damage", "", gfxSpellPowerSub, parentFlashValueStorage);	//modSigns
	AddCharacterStatSigns("quenStat1", 'quen_discharge_percent', "gm_sign_stats_alt_quen_returned_damage", "", gfxSpellPowerSub, parentFlashValueStorage);	//modSigns
	AddCharacterStatSigns("quenStat2", 'quen_damageabs', "gm_sign_stats_quen_dmg_absorption", "", gfxSpellPowerSub, parentFlashValueStorage);	//modSigns
	AddCharacterStatSigns("quenStat3", 'quen_damageabs_alt', "gm_sign_stats_alt_quen_dmg_absorption", "", gfxSpellPowerSub, parentFlashValueStorage);	//modSigns
	gfxSpellPower.SetMemberFlashArray("subStats", gfxSpellPowerSub);	//modSigns: moved; Yrden and Axii in a second section (legacy)
	gfxSpellPower2 = AddCharacterStat("mainMagicStat", 'spell_power', "stat_signs", "spell_power", statsArray, parentFlashValueStorage);	//modSigns
	gfxSpellPowerSub2 = parentFlashValueStorage.CreateTempFlashArray();	//modSigns
	AddCharacterHeader("stat_signs", gfxSpellPowerSub2, parentFlashValueStorage, true, "Blue");	//modSigns
	AddCharacterHeader("Yrden", gfxSpellPowerSub2, parentFlashValueStorage);	//modSigns
	AddCharacterStatSigns("yrdenStat1", 'yrden_power', "yrden_intensity", "", gfxSpellPowerSub2, parentFlashValueStorage);	//modSigns
	AddCharacterStatSigns("yrdenStat4", 'yrden_traps', "gm_sign_stats_yrden_traps", "", gfxSpellPowerSub2, parentFlashValueStorage);	//modSigns
	AddCharacterStatSigns("yrdenStat2", 'yrden_duration', "duration", "", gfxSpellPowerSub2, parentFlashValueStorage);	//modSigns
	AddCharacterStatSigns("yrdenStat2", 'yrden_range', "gm_sign_stats_yrden_range", "", gfxSpellPowerSub2, parentFlashValueStorage);	//modSigns
	AddCharacterStatSigns("yrdenStat3", 'yrden_slowdown', "SlowdownEffect", "", gfxSpellPowerSub2, parentFlashValueStorage);	//modSigns
	AddCharacterStatSigns("yrdenStat5", 'yrden_duration_alt', "gm_sign_stats_alt_yrden_duration", "", gfxSpellPowerSub2, parentFlashValueStorage);	//modSigns
	AddCharacterStatSigns("yrdenStat5", 'yrden_charges', "gm_sign_stats_alt_yrden_charges", "", gfxSpellPowerSub2, parentFlashValueStorage);	//modSigns
	AddCharacterStatSigns("yrdenStat6", 'yrden_damage', "gm_sign_stats_alt_yrden_damage", "", gfxSpellPowerSub2, parentFlashValueStorage);	//modSigns
	AddCharacterHeader("Axii", gfxSpellPowerSub2, parentFlashValueStorage);	//modSigns
	AddCharacterStatSigns("axiiStat1", 'axii_power', "axii_intensity", "", gfxSpellPowerSub2, parentFlashValueStorage);	//modSigns
	AddCharacterStatSigns("axiiStat3", 'axii_duration_confusion', "gm_sign_stats_axii_duration_confusion", "", gfxSpellPowerSub2, parentFlashValueStorage);	//modSigns
	AddCharacterStatSigns("axiiStat4", 'axii_instakill', "instant_kill_chance", "", gfxSpellPowerSub2, parentFlashValueStorage);	//modSigns
	AddCharacterStatSigns("axiiStat5", 'axii_duration_control', "gm_sign_stats_axii_duration_control", "", gfxSpellPowerSub2, parentFlashValueStorage);	//modSigns
	gfxSpellPower2.SetMemberFlashArray("subStats", gfxSpellPowerSub2);	//modSigns
	
	
	
	gfxStamina = AddCharacterStat("majorStat3", 'stamina', "stamina", "stamina", statsArray, parentFlashValueStorage);
	gfxStaminaSub = parentFlashValueStorage.CreateTempFlashArray();
	AddCharacterHeader("stamina", gfxStaminaSub, parentFlashValueStorage, true, "Blue");
	AddCharacterStat("defStat14", 'staminaOutOfCombatRegen', "attribute_name_staminaregen_out_of_combat", "", gfxStaminaSub, parentFlashValueStorage);
	AddCharacterStat("defStat15", 'staminaRegen', "attribute_name_staminaregen", "", gfxStaminaSub, parentFlashValueStorage);
	gfxStamina.SetMemberFlashArray("subStats", gfxStaminaSub);
	
	
	
	gfxAdditional = AddCharacterStat("majorStat5", 'additional', "panel_common_statistics_category_additional", "additional", statsArray, parentFlashValueStorage);
	gfxAdditionalSub = parentFlashValueStorage.CreateTempFlashArray();
	AddCharacterHeader("panel_common_statistics_category_additional", gfxAdditionalSub, parentFlashValueStorage, true, "Brown");
	AddCharacterStatF("extraStat0", 'bonus_money', "bonus_money", "", gfxAdditionalSub , parentFlashValueStorage);	//modSigns: UI-05, the money bonus (legacy)
	AddCharacterStatF("extraStat1", 'bonus_herb_chance', "bonus_herb_chance", "", gfxAdditionalSub, parentFlashValueStorage);
	AddCharacterStatU("extraStat2", 'instant_kill_chance_mult', "instant_kill_chance", "", gfxAdditionalSub , parentFlashValueStorage);
	//modSigns: removed the experience bonus lines (UI-05, legacy)
	AddCharacterStatU("extraStat4", 'adrenaline_gain', "gm_stat_adrenaline_gain", "", gfxAdditionalSub , parentFlashValueStorage);	//modSigns: UI-05, adrenaline gain per hit (legacy)
	if(GMPanelSkill(S_Sword_s21, S_Sword_s22) != S_SUndefined)	//modSigns: Muscle Memory, either tree
		AddCharacterStatU("extraStat4", 'adrenaline_gain_light', "gm_stat_adrenaline_gain_light", "", gfxAdditionalSub , parentFlashValueStorage);	//modSigns
	if(GMPanelSkill(S_Sword_s04, S_Sword_s23) != S_SUndefined)	//modSigns: Strength Training, either tree
		AddCharacterStatU("extraStat4", 'adrenaline_gain_heavy', "gm_stat_adrenaline_gain_heavy", "", gfxAdditionalSub , parentFlashValueStorage);	//modSigns
	gfxAdditional.SetMemberFlashArray("subStats", gfxAdditionalSub);
	
	
	
	gameTime =	theGame.CalculateTimePlayed();
	gameTimeHours = (string)(GameTimeDays(gameTime) * 24 + GameTimeHours(gameTime));
	gameTimeMinutes = (string)GameTimeMinutes(gameTime);
	
	gfxData.SetMemberFlashArray("stats", statsArray);
	gfxData.SetMemberFlashString("hoursPlayed", gameTimeHours);
	gfxData.SetMemberFlashString("minutesPlayed", gameTimeMinutes);
	
	return gfxData;
	
	
	
	
}

// A sword or crossbow line's value from Ghost Mode's list (legacy's formats); found tells whether the
// key is one of them.
function GMPanelOffenseValue(varKey : name, out found : bool) : string
{
	var w : W3PlayerWitcher;
	var s : SGMOffenseStats;
	var sp : SAbilityAttributeValue;
	var item : SItemUniqueId;
	var val1, val2, gain : float;

	w = GetWitcherPlayer();
	found = true;
	if(varKey == 'instant_kill_chance_mult')
	{
		if(w.GetItemEquippedOnSlot(EES_SteelSword, item))
			val1 = CalculateAttributeValue(w.inv.GetItemAttributeValue(item, varKey));
		if(w.GetItemEquippedOnSlot(EES_SilverSword, item))
			val2 = CalculateAttributeValue(w.inv.GetItemAttributeValue(item, varKey));
		return NoTrailZeros(RoundMath(MaxF(val1, val2) * 100)) + " %";
	}
	if(varKey == 'adrenaline_gain' || varKey == 'adrenaline_gain_light' || varKey == 'adrenaline_gain_heavy')
		return FloatToStringPrec(GMPanelAdrenalineGain(varKey), 2);
	if(varKey == 'crossbow_adrenaline_gain')
	{
		if(w.GMHasColdBlood())
		{
			sp = w.GetAttributeValue('focus_gain');
			if(w.CanUseSkill(S_Sword_s20))
				sp += w.GetSkillAttributeValue(S_Sword_s20, 'focus_gain', false, true) * w.GetSkillLevel(S_Sword_s20);
			gain = 0.1f * (1 + CalculateAttributeValue(sp)) * w.GMMutation7GainMult();
		}
		return FloatToStringPrec(gain, 2);
	}
	s = w.GMGetOffenseStats();
	switch(varKey)
	{
		case 'silverFastAP' :			return NoTrailZeros(RoundMath(s.silverFastAP * 100)) + " %";
		case 'silverFastDmg' :			return NoTrailZeros(RoundMath(s.silverFastDmg));
		case 'silverFastCritChance' :	return NoTrailZeros(RoundMath(s.silverFastCritChance)) + " %";
		case 'silverFastCritAP' :		return NoTrailZeros(RoundMath(s.silverFastCritAP * 100)) + " %";
		case 'silverFastCritDmg' :		return NoTrailZeros(RoundMath(s.silverFastCritDmg));
		case 'silverStrongAP' :			return NoTrailZeros(RoundMath(s.silverStrongAP * 100)) + " %";
		case 'silverStrongDmg' :		return NoTrailZeros(RoundMath(s.silverStrongDmg));
		case 'silverStrongCritChance' :	return NoTrailZeros(RoundMath(s.silverStrongCritChance)) + " %";
		case 'silverStrongCritAP' :		return NoTrailZeros(RoundMath(s.silverStrongCritAP * 100)) + " %";
		case 'silverStrongCritDmg' :	return NoTrailZeros(RoundMath(s.silverStrongCritDmg));
		case 'steelFastAP' :			return NoTrailZeros(RoundMath(s.steelFastAP * 100)) + " %";
		case 'steelFastDmg' :			return NoTrailZeros(RoundMath(s.steelFastDmg));
		case 'steelFastCritChance' :	return NoTrailZeros(RoundMath(s.steelFastCritChance)) + " %";
		case 'steelFastCritAP' :		return NoTrailZeros(RoundMath(s.steelFastCritAP * 100)) + " %";
		case 'steelFastCritDmg' :		return NoTrailZeros(RoundMath(s.steelFastCritDmg));
		case 'steelStrongAP' :			return NoTrailZeros(RoundMath(s.steelStrongAP * 100)) + " %";
		case 'steelStrongDmg' :			return NoTrailZeros(RoundMath(s.steelStrongDmg));
		case 'steelStrongCritChance' :	return NoTrailZeros(RoundMath(s.steelStrongCritChance)) + " %";
		case 'steelStrongCritAP' :		return NoTrailZeros(RoundMath(s.steelStrongCritAP * 100)) + " %";
		case 'steelStrongCritDmg' :		return NoTrailZeros(RoundMath(s.steelStrongCritDmg));
		case 'crossbowAttackPower' :	return NoTrailZeros(RoundMath(s.crossbowAttackPower * 100)) + " %";
		case 'crossbowCritDmgBonus' :	return NoTrailZeros(RoundMath(s.crossbowCritDmgBonus * 100)) + " %";
		case 'crossbowElementaDmg' :	return NoTrailZeros(RoundMath(s.crossbowElementaDmg));
	}
	found = false;
	return "";
}

@wrapMethod
function AddCharacterStatU(tag : string, varKey : name, locKey : string, iconTag : string, toArray : CScriptedFlashArray, flashMaster : CScriptedFlashValueStorage) : CScriptedFlashObject
{
	var statObject : CScriptedFlashObject;
	var value : string;
	var found : bool;

	statObject = wrappedMethod(tag, varKey, locKey, iconTag, toArray, flashMaster);
	value = GMPanelOffenseValue(varKey, found);
	if(found)
		statObject.SetMemberFlashString("value", value);
	if(varKey == 'silverdamage')
		statObject.SetMemberFlashString("name", GetLocStringByKeyExt("panel_common_statistics_tooltip_silver_dph_gm"));
	else if(varKey == 'steeldamage')
		statObject.SetMemberFlashString("name", GetLocStringByKeyExt("panel_common_statistics_tooltip_steel_dph_gm"));
	else if(statObject.GetMemberFlashString("name") == "" && locKey != "")	// legacy: a name without a string shows the text passed (the elemental bolt damage's localized name)
		statObject.SetMemberFlashString("name", locKey);
	return statObject;
}

// The effect chances: the sword's, Crippling Strikes' for bleeding (either tree), times Metamorphosis's
// factor (MUT-13), as legacy.
@wrapMethod
function AddCharacterStatU2(tag : string, varKey : name, locKey : string, iconTag : string, toArray : CScriptedFlashArray, flashMaster : CScriptedFlashValueStorage) : CScriptedFlashObject
{
	var statObject : CScriptedFlashObject;
	var w : W3PlayerWitcher;
	var item : SItemUniqueId;
	var attr : name;
	var silver, bleeding, has : bool;
	var chance : float;

	statObject = wrappedMethod(tag, varKey, locKey, iconTag, toArray, flashMaster);
	switch(varKey)
	{
		case 'silver_desc_poinsonchance_mult' :		silver = true;	attr = 'desc_poinsonchance_mult'; break;
		case 'silver_desc_bleedingchance_mult' :	silver = true;	attr = 'desc_bleedingchance_mult'; bleeding = true; break;
		case 'silver_desc_burningchance_mult' :		silver = true;	attr = 'desc_burningchance_mult'; break;
		case 'silver_desc_confusionchance_mult' :	silver = true;	attr = 'desc_confusionchance_mult'; break;
		case 'silver_desc_freezingchance_mult' :	silver = true;	attr = 'desc_freezingchance_mult'; break;
		case 'silver_desc_staggerchance_mult' :		silver = true;	attr = 'desc_staggerchance_mult'; break;
		case 'steel_desc_poinsonchance_mult' :		attr = 'desc_poinsonchance_mult'; break;
		case 'steel_desc_bleedingchance_mult' :		attr = 'desc_bleedingchance_mult'; bleeding = true; break;
		case 'steel_desc_burningchance_mult' :		attr = 'desc_burningchance_mult'; break;
		case 'steel_desc_confusionchance_mult' :	attr = 'desc_confusionchance_mult'; break;
		case 'steel_desc_freezingchance_mult' :		attr = 'desc_freezingchance_mult'; break;
		case 'steel_desc_staggerchance_mult' :		attr = 'desc_staggerchance_mult'; break;
		default : return statObject;
	}
	w = GetWitcherPlayer();
	if(silver)
		has = w.GetItemEquippedOnSlot(EES_SilverSword, item);
	else
		has = w.GetItemEquippedOnSlot(EES_SteelSword, item);
	if(has)
		chance = CalculateAttributeValue(w.inv.GetItemAttributeValue(item, attr));
	if(bleeding)
		chance += w.GMCripplingStrikesValue('sword_s5_chance', true);
	chance *= w.GMMutation12ChanceMult();
	statObject.SetMemberFlashString("value", NoTrailZeros(RoundMath(chance * 100)) + " %");
	return statObject;
}

// The crossbow's headline value: the bolt's average of physical and silver damage plus its elemental
// damage, from the list (legacy; 5.x's Water Hag and perk_2 terms gone: ALCH-10, SKL-06).
@replaceMethod
function GetEquippedCrossbowDamage():float
{
	var s : SGMOffenseStats;	//modSigns
	var bolt : SItemUniqueId;	//modSigns

	if(!GetWitcherPlayer().GetItemEquippedOnSlot(EES_Bolt, bolt))	//modSigns
		return 0;	//modSigns
	s = GetWitcherPlayer().GMGetOffenseStats();	//modSigns
	return (s.crossbowSteelDmg + s.crossbowSilverDmg) / 2 + s.crossbowElementaDmg;	//modSigns
}

// UI-04: the toxicity section's values (legacy's): the decay per second as the toxicity effect gets it
// (ToxicityEffect's toxicityRegen, the medium set, Fast Metabolism, Placation; Toxic Blood's slower decay),
// the available toxicity, the overdose threshold and the overdose Vitality drain (with Euphoria's factor).
function GMPanelToxicityDecay() : float
{
	var w : W3PlayerWitcher;
	var attr, min, max : SAbilityAttributeValue;
	var decay : float;

	w = GetWitcherPlayer();
	theGame.GetDefinitionsManager().GetAbilityAttributeValue('ToxicityEffect', 'toxicityRegen', min, max);
	attr = GetAttributeRandomizedValue(min, max);
	if(w.HasAbility('ArmorTypeMediumSetBonusAbility'))
	{
		theGame.GetDefinitionsManager().GetAbilityAttributeValue('ArmorTypeMediumSetBonusAbility', 'toxicityRegen', min, max);
		attr += min;
	}
	if(w.CanUseSkill(S_Alchemy_s15))
		attr += w.GetSkillAttributeValue(S_Alchemy_s15, 'toxicityRegen', false, true) * w.GetSkillLevel(S_Alchemy_s15);
	if(w.HasAbility('Runeword 8 Regen'))
		attr += w.GetAbilityAttributeValue('Runeword 8 Regen', 'toxicityRegen');
	decay = -(attr.valueAdditive + attr.valueMultiplicative * (attr.valueBase + w.GetStatMax(BCS_Toxicity)));
	if(w.IsMutationActive(EPMT_Mutation4))
		decay *= MaxF(0.01, 1 - GMMutation4DecayFactor());
	return decay;
}

@wrapMethod
function AddCharacterStatToxicity(tag : string, varKey : name, locKey : string, iconTag : string, toArray : CScriptedFlashArray, flashMaster : CScriptedFlashValueStorage) : CScriptedFlashObject
{
	var statObject : CScriptedFlashObject;
	var w : W3PlayerWitcher;

	statObject = wrappedMethod(tag, varKey, locKey, iconTag, toArray, flashMaster);
	w = GetWitcherPlayer();
	switch(varKey)
	{
		case 'avail_tox' :
			statObject.SetMemberFlashString("value", NoTrailZeros(RoundMath(w.GetStatMax(BCS_Toxicity) - w.GetStat(BCS_Toxicity))));
			break;
		case 'tox_dec_rate' :
			statObject.SetMemberFlashString("value", NoTrailZeros(RoundTo(GMPanelToxicityDecay(), 2)) + "/" + GetLocStringByKeyExt("per_second"));
			break;
		case 'tox_overdose' :
			statObject.SetMemberFlashString("value", NoTrailZeros(RoundMath(w.GetToxicityDamageThreshold() * w.GetStatMax(BCS_Toxicity))));
			break;
		case 'tox_hp_drain' :
			statObject.SetMemberFlashString("value", NoTrailZeros(RoundMath(w.GMGetToxicityDamage())) + "/" + GetLocStringByKeyExt("per_second"));
			break;
	}
	return statObject;
}

// UI-05: a Vitality regen line per second: the additive part plus the multiplicative part of maximum
// Vitality, as the regen effect gets it (5.x's line showed base x mult + add).
function GMPanelVitalityRegen(attributeName : name) : float
{
	var w : W3PlayerWitcher;
	var sp : SAbilityAttributeValue;

	w = GetWitcherPlayer();
	sp = w.GetAttributeValue(attributeName);
	return sp.valueAdditive + sp.valueMultiplicative * w.GetStatMax(BCS_Vitality);
}

// UI-05: sign power as its raw value (legacy), not 5.x's average of the five signs' totals.
function GMPanelRawSignPower() : float
{
	var sp : SAbilityAttributeValue;

	sp = GetWitcherPlayer().GetPowerStatValue(CPS_SpellPower);
	return MaxF(sp.valueMultiplicative - 1, 0);
}

// UI-05: adrenaline per melee hit, as the hit gets it: 0.1 x (1 + focus_gain with Razor Focus, plus Muscle
// Memory's on fast or Strength Training's on strong attacks, either tree), the Bear School's bonus, x
// Adrenaline Rush's factor.
function GMPanelAdrenalineGain(varKey : name) : float
{
	var w : W3PlayerWitcher;
	var sp : SAbilityAttributeValue;
	var gain : float;

	w = GetWitcherPlayer();
	sp = w.GetAttributeValue('focus_gain');
	if(w.CanUseSkill(S_Sword_s20))
		sp += w.GetSkillAttributeValue(S_Sword_s20, 'focus_gain', false, true) * w.GetSkillLevel(S_Sword_s20);
	gain = CalculateAttributeValue(sp);
	if(varKey == 'adrenaline_gain_light')
		gain += GMPanelSkillPerLevel(GMPanelSkill(S_Sword_s21, S_Sword_s22), 'light_focus_gain', true);
	else if(varKey == 'adrenaline_gain_heavy')
		gain += GMPanelSkillPerLevel(GMPanelSkill(S_Sword_s04, S_Sword_s23), 'heavy_focus_gain', true);
	gain = 0.1 * (1 + gain);
	if(w.CanUseSkill(S_Perk_07) || w.CanUseSkill(S_Perk_25))
		gain += CalculateAttributeValue(w.GetAttributeValue('bonus_focus_gain'));
	return gain * w.GMMutation7GainMult();
}

// UI-05: a header without a string shows its key (legacy). 5.x body; changes marked //modSigns.
@replaceMethod
function AddCharacterHeader(locKey:string, toArray : CScriptedFlashArray, flashMaster:CScriptedFlashValueStorage, optional isSuperHeader : bool, optional color : string):void
{
	var statObject : CScriptedFlashObject;
	var finalName : string;	//modSigns
	statObject = flashMaster.CreateTempFlashObject();

	finalName = GetLocStringByKeyExt(locKey);	//modSigns
	if(finalName == "#" || finalName == "")	//modSigns
		finalName = locKey;	//modSigns
	statObject.SetMemberFlashString("name", finalName);	//modSigns
	statObject.SetMemberFlashString("value", "");

	if (isSuperHeader)
	{
		statObject.SetMemberFlashString("tag", "SuperHeader");
		statObject.SetMemberFlashString("backgroundColor", color);
	}
	else
	{
		statObject.SetMemberFlashString("tag", "Header");
	}

	statObject.SetMemberFlashString("iconTag", "");
	toArray.PushBackFlashObject(statObject);
}
