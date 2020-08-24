/***********************************************************************/
/** 	© 2015 CD PROJEKT S.A. All rights reserved.
/** 	THE WITCHER® is a trademark of CD PROJEKT S. A.
/** 	The Witcher game is based on the prose of Andrzej Sapkowski.
/***********************************************************************/





class CharacterStatsPopupData extends TextPopupData
{	
	var m_flashValueStorage : CScriptedFlashValueStorage;
	
	protected  function GetContentRef() : string 
	{
		return "StatisticsFullRef";
	}
	
	protected  function DefineDefaultButtons():void
	{
		AddButtonDef("panel_button_common_exit", "escape-gamepad_B", IK_Escape);
		AddButtonDef("input_feedback_scroll_text", "gamepad_R_Scroll");
	}
	
	public function  OnUserFeedback( KeyCode:string ) : void
	{
		if (KeyCode == "escape-gamepad_B") 
		{
			ClosePopup();
		}
	}
	
	public  function GetGFxData(parentFlashValueStorage : CScriptedFlashValueStorage) : CScriptedFlashObject 
	{
		var gfxData : CScriptedFlashObject;
		
		m_flashValueStorage = parentFlashValueStorage;
		
		gfxData = parentFlashValueStorage.CreateTempFlashObject();
		GetPlayerStatsGFxData(parentFlashValueStorage);
		gfxData.SetMemberFlashString("ContentRef", GetContentRef());
		
		return gfxData;
	}
}

function GetPlayerStatsGFxData(parentFlashValueStorage : CScriptedFlashValueStorage) : CScriptedFlashObject
{ 
	var statsArray : CScriptedFlashArray;
	var gfxData    : CScriptedFlashObject;
	
	var gfxSilverDamage : CScriptedFlashObject;
	var gfxSteelDamage  : CScriptedFlashObject;
	var gfxArmor 		: CScriptedFlashObject;
	var gfxVitality 	: CScriptedFlashObject;
	var gfxSpellPower 	: CScriptedFlashObject;
	var gfxSpellPower2 	: CScriptedFlashObject; //modSigns
	var gfxToxicity 	: CScriptedFlashObject;
	var gfxStamina 		: CScriptedFlashObject;
	var gfxCrossbow  	: CScriptedFlashObject;
	var gfxAdditional  	: CScriptedFlashObject;
	
	var gfxSilverDamageSub : CScriptedFlashArray;
	var gfxSteelDamageSub  : CScriptedFlashArray;
	var gfxArmorSub 	   : CScriptedFlashArray;
	var gfxVitalitySub 	   : CScriptedFlashArray;
	var gfxSpellPowerSub   : CScriptedFlashArray;
	var gfxSpellPowerSub2  : CScriptedFlashArray; //modSigns
	var gfxToxicitySub 	   : CScriptedFlashArray;
	var gfxStaminaSub	   : CScriptedFlashArray;
	var gfxCrossbowSub     : CScriptedFlashArray;
	var gfxAdditionalSub   : CScriptedFlashArray;
	
	var gameTime		: GameTime;
	var gameTimeHours	: string;
	var gameTimeMinutes : string;
	
	gfxData = parentFlashValueStorage.CreateTempFlashObject();
	statsArray = parentFlashValueStorage.CreateTempFlashArray();
	
	//modSigns: silver stats reworked
	gfxSilverDamage = AddCharacterStatU("mainSilverStat", 'silverdamage', "panel_common_statistics_tooltip_silver_dph_gm", "attack_silver", statsArray, parentFlashValueStorage);
	gfxSilverDamageSub = parentFlashValueStorage.CreateTempFlashArray();
	AddCharacterHeader("panel_common_statistics_tooltip_silver_dph_gm", gfxSilverDamageSub, parentFlashValueStorage, true, "Red");
	AddCharacterStatU("silverStat0", 'silverFastAP', "gm_combat_stats_fast_attack_power", "", gfxSilverDamageSub, parentFlashValueStorage);
	AddCharacterStatU("silverStat1", 'silverFastDmg', "panel_common_statistics_tooltip_silver_fast_dps", "", gfxSilverDamageSub, parentFlashValueStorage);
	AddCharacterStatU("silverStat2", 'silverFastCritChance', "panel_common_statistics_tooltip_silver_fast_crit_chance", "", gfxSilverDamageSub, parentFlashValueStorage); 
	AddCharacterStatU("silverStat3", 'silverFastCritAP', "gm_combat_stats_fast_crit_attack_power", "", gfxSilverDamageSub, parentFlashValueStorage);
	AddCharacterStatU("silverStat4", 'silverFastCritDmg', "panel_common_statistics_tooltip_silver_fast_crit_dmg", "", gfxSilverDamageSub, parentFlashValueStorage); 
	AddCharacterStatU("Dummy", '', "", "", gfxSilverDamageSub, parentFlashValueStorage); //modSigns
	AddCharacterStatU("silverStat5", 'silverStrongAP', "gm_combat_stats_strong_attack_power", "", gfxSilverDamageSub, parentFlashValueStorage);
	AddCharacterStatU("silverStat6", 'silverStrongDmg', "panel_common_statistics_tooltip_silver_strong_dps", "", gfxSilverDamageSub, parentFlashValueStorage);
	AddCharacterStatU("silverStat7", 'silverStrongCritChance', "panel_common_statistics_tooltip_silver_strong_crit_chance", "", gfxSilverDamageSub, parentFlashValueStorage); 
	AddCharacterStatU("silverStat8", 'silverStrongCritAP', "gm_combat_stats_strong_crit_attack_power", "", gfxSilverDamageSub, parentFlashValueStorage);
	AddCharacterStatU("silverStat9", 'silverStrongCritDmg', "panel_common_statistics_tooltip_silver_strong_crit_dmg", "", gfxSilverDamageSub, parentFlashValueStorage); 
	AddCharacterStatU("Dummy", '', "", "", gfxSilverDamageSub, parentFlashValueStorage);
	AddCharacterStatU2("silverStat10", 'silver_desc_poinsonchance_mult', "attribute_name_desc_poinsonchance_mult", "", gfxSilverDamageSub, parentFlashValueStorage); 
	AddCharacterStatU2("silverStat11", 'silver_desc_bleedingchance_mult', "attribute_name_desc_bleedingchance_mult", "", gfxSilverDamageSub, parentFlashValueStorage); 
	AddCharacterStatU2("silverStat12", 'silver_desc_burningchance_mult', "attribute_name_desc_burningchance_mult", "", gfxSilverDamageSub, parentFlashValueStorage); 
	AddCharacterStatU2("silverStat13", 'silver_desc_confusionchance_mult', "attribute_name_desc_confusionchance_mult", "", gfxSilverDamageSub, parentFlashValueStorage); 
	AddCharacterStatU2("silverStat14", 'silver_desc_freezingchance_mult', "attribute_name_desc_freezingchance_mult", "", gfxSilverDamageSub, parentFlashValueStorage); 
	AddCharacterStatU2("silverStat15", 'silver_desc_staggerchance_mult', "attribute_name_desc_staggerchance_mult", "", gfxSilverDamageSub, parentFlashValueStorage);
	gfxSilverDamage.SetMemberFlashArray("subStats", gfxSilverDamageSub);
	
	//modSigns: steel stats reworked
	gfxSteelDamage = AddCharacterStatU("mainSteelStat", 'steeldamage', "panel_common_statistics_tooltip_steel_dph_gm", "attack_steel", statsArray, parentFlashValueStorage); //modSigns
	gfxSteelDamageSub = parentFlashValueStorage.CreateTempFlashArray();
	AddCharacterHeader("panel_common_statistics_tooltip_steel_dph_gm", gfxSteelDamageSub, parentFlashValueStorage, true, "Red"); //modSigns
	AddCharacterStatU("steelStat0", 'steelFastAP', "gm_combat_stats_fast_attack_power", "", gfxSteelDamageSub, parentFlashValueStorage);
	AddCharacterStatU("steelStat1", 'steelFastDmg', "panel_common_statistics_tooltip_steel_fast_dps", "", gfxSteelDamageSub, parentFlashValueStorage);
	AddCharacterStatU("steelStat2", 'steelFastCritChance', "panel_common_statistics_tooltip_steel_fast_crit_chance", "", gfxSteelDamageSub, parentFlashValueStorage); 
	AddCharacterStatU("steelStat3", 'steelFastCritAP', "gm_combat_stats_fast_crit_attack_power", "", gfxSteelDamageSub, parentFlashValueStorage);
	AddCharacterStatU("steelStat4", 'steelFastCritDmg', "panel_common_statistics_tooltip_steel_fast_crit_dmg", "", gfxSteelDamageSub, parentFlashValueStorage); 
	AddCharacterStatU("Dummy", '', "", "", gfxSteelDamageSub, parentFlashValueStorage); //modSigns
	AddCharacterStatU("steelStat5", 'steelStrongAP', "gm_combat_stats_strong_attack_power", "", gfxSteelDamageSub, parentFlashValueStorage);
	AddCharacterStatU("steelStat6", 'steelStrongDmg', "panel_common_statistics_tooltip_steel_strong_dps", "", gfxSteelDamageSub, parentFlashValueStorage);
	AddCharacterStatU("steelStat7", 'steelStrongCritChance', "panel_common_statistics_tooltip_steel_strong_crit_chance", "", gfxSteelDamageSub, parentFlashValueStorage); 
	AddCharacterStatU("steelStat8", 'steelStrongCritAP', "gm_combat_stats_strong_crit_attack_power", "", gfxSteelDamageSub, parentFlashValueStorage);
	AddCharacterStatU("steelStat9", 'steelStrongCritDmg', "panel_common_statistics_tooltip_steel_strong_crit_dmg", "", gfxSteelDamageSub, parentFlashValueStorage); 
	AddCharacterStatU("Dummy", '', "", "", gfxSteelDamageSub, parentFlashValueStorage);
	AddCharacterStatU2("steelStat10", 'steel_desc_poinsonchance_mult', "attribute_name_desc_poinsonchance_mult", "", gfxSteelDamageSub, parentFlashValueStorage); 
	AddCharacterStatU2("steelStat11", 'steel_desc_bleedingchance_mult', "attribute_name_desc_bleedingchance_mult", "", gfxSteelDamageSub, parentFlashValueStorage); 
	AddCharacterStatU2("steelStat12", 'steel_desc_burningchance_mult', "attribute_name_desc_burningchance_mult", "", gfxSteelDamageSub, parentFlashValueStorage); 
	AddCharacterStatU2("steelStat13", 'steel_desc_confusionchance_mult', "attribute_name_desc_confusionchance_mult", "", gfxSteelDamageSub, parentFlashValueStorage); 
	AddCharacterStatU2("steelStat14", 'steel_desc_freezingchance_mult', "attribute_name_desc_freezingchance_mult", "", gfxSteelDamageSub, parentFlashValueStorage); 
	AddCharacterStatU2("steelStat15", 'steel_desc_staggerchance_mult', "attribute_name_desc_staggerchance_mult", "", gfxSteelDamageSub, parentFlashValueStorage);
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
	//modSigns: armor stamina regen modifier
	if(theGame.params.IsArmorRegenPenaltyEnabled())
	{
		AddCharacterStatU("defStat11", '', "", "", gfxArmorSub, parentFlashValueStorage);
		AddCharacterStat("defStat16", 'staminaRegenArmorMod', "attribute_name_staminaRegen_armor_mod", "", gfxArmorSub, parentFlashValueStorage);
	}
	//AddCharacterStat("defStat17", 'chanceToIgnoreHitAnim', "attribute_name_chanceToIgnoreHitAnim", "", gfxArmorSub, parentFlashValueStorage);
	gfxArmor.SetMemberFlashArray("subStats", gfxArmorSub);
	
	
	
	//modSigns: crossbow stats reworked
	gfxCrossbow = AddCharacterStat("majorStat4", 'crossbow', "item_category_crossbow", "crossbow", statsArray, parentFlashValueStorage);
	gfxCrossbowSub = parentFlashValueStorage.CreateTempFlashArray();
	AddCharacterHeader("item_category_crossbow", gfxCrossbowSub, parentFlashValueStorage, true, "Red");
	AddCharacterStatU("steelStat17", 'crossbowAttackPower', "attribute_name_attack_power", "", gfxCrossbowSub, parentFlashValueStorage);
	AddCharacterStatU("steelStat18", 'crossbowCritChance', "panel_common_statistics_tooltip_crossbow_crit_chance", "", gfxCrossbowSub, parentFlashValueStorage);
	AddCharacterStatU("steelStat19", 'crossbowCritDmgBonus', "attribute_name_critical_hit_damage_bonus", "", gfxCrossbowSub, parentFlashValueStorage);
	AddCharacterStatU("steelStat20", 'crossbow_adrenaline_gain', "gm_stat_adrenaline_gain", "", gfxCrossbowSub, parentFlashValueStorage);
	AddCharacterStatU("steelStat21", 'crossbowSteelDmg', GetAttributeNameLocStr(GetCrossbowSteelDmgName(), false), "", gfxCrossbowSub, parentFlashValueStorage);
	AddCharacterStatU("steelStat22", 'crossbowSilverDmg', "attribute_name_silverdamage", "", gfxCrossbowSub, parentFlashValueStorage);
	if(GetCrossbowElementaDmgName() != '')
		AddCharacterStatU("steelStat23", 'crossbowElementaDmg', GetAttributeNameLocStr(GetCrossbowElementaDmgName(), false), "", gfxCrossbowSub, parentFlashValueStorage);
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
	//AddCharacterStatToxicity("toxicity", 'toxicity', "toxicity", "", gfxToxicitySub, parentFlashValueStorage);
	AddCharacterStatToxicity("lockedToxicity", 'lockedToxicity', "toxicity_offset", "", gfxToxicitySub, parentFlashValueStorage);
	AddCharacterStatToxicity("avail_tox", 'avail_tox', "attribute_name_avail_tox", "", gfxToxicitySub, parentFlashValueStorage);
	AddCharacterStatToxicity("tox_dec_rate", 'tox_dec_rate', "attribute_name_tox_dec_rate", "", gfxToxicitySub, parentFlashValueStorage);
	AddCharacterStatToxicity("tox_overdose", 'tox_overdose', "attribute_name_tox_overdose", "", gfxToxicitySub, parentFlashValueStorage);
	AddCharacterStatToxicity("tox_hp_drain", 'tox_hp_drain', "attribute_name_tox_hp_drain", "", gfxToxicitySub, parentFlashValueStorage);
	//AddCharacterStatToxicity("nonres_tox", 'nonres_tox', "attribute_name_nonres_tox", "", gfxToxicitySub, parentFlashValueStorage);
	gfxToxicity.SetMemberFlashArray("subStats", gfxToxicitySub);
	
	
	
	gfxSpellPower = AddCharacterStat("mainMagicStat", 'spell_power', "stat_signs", "spell_power", statsArray, parentFlashValueStorage);
	gfxSpellPowerSub = parentFlashValueStorage.CreateTempFlashArray();
	AddCharacterHeader("stat_signs", gfxSpellPowerSub, parentFlashValueStorage, true, "Blue");
	AddCharacterHeader("Aard", gfxSpellPowerSub, parentFlashValueStorage);
	AddCharacterStatSigns("aardStat1", 'aard_power', "aard_intensity", "", gfxSpellPowerSub, parentFlashValueStorage); //modSigns
	AddCharacterStatSigns("aardStat2", 'aard_knockdownchance', "attribute_name_knockdown", "", gfxSpellPowerSub, parentFlashValueStorage); //modSigns
	AddCharacterStatSigns("aardStat3", 'aard_heavyknockdownchance', "gm_sign_stats_heavy_knockdown", "", gfxSpellPowerSub, parentFlashValueStorage); //modSigns
	AddCharacterStatSigns("aardStat4", 'aard_damage', "attribute_name_forcedamage", "", gfxSpellPowerSub, parentFlashValueStorage); //modSigns
	AddCharacterHeader("Igni", gfxSpellPowerSub, parentFlashValueStorage);
	AddCharacterStatSigns("igniStat1", 'igni_power', "igni_intensity", "", gfxSpellPowerSub, parentFlashValueStorage); //modSigns
	AddCharacterStatSigns("igniStat2", 'igni_burnchance', "effect_burning", "", gfxSpellPowerSub, parentFlashValueStorage); //modSigns
	AddCharacterStatSigns("igniStat3", 'igni_damage', "attribute_name_firedamage", "", gfxSpellPowerSub, parentFlashValueStorage); //modSigns
	AddCharacterStatSigns("igniStat3", 'igni_dmg_alt', "gm_sign_stats_channeling_damage_per_sec", "", gfxSpellPowerSub, parentFlashValueStorage); //modSigns
	AddCharacterHeader("Quen", gfxSpellPowerSub, parentFlashValueStorage);
	AddCharacterStatSigns("quenStat1", 'quen_power', "quen_intensity", "", gfxSpellPowerSub, parentFlashValueStorage); //modSigns
	AddCharacterStatSigns("quenStat1", 'quen_duration', "duration", "", gfxSpellPowerSub, parentFlashValueStorage); //modSigns
	AddCharacterStatSigns("quenStat1", 'quen_discharge_pts', "gm_sign_stats_alt_quen_returned_damage", "", gfxSpellPowerSub, parentFlashValueStorage); //modSigns
	AddCharacterStatSigns("quenStat1", 'quen_discharge_percent', "gm_sign_stats_alt_quen_returned_damage", "", gfxSpellPowerSub, parentFlashValueStorage); //modSigns
	AddCharacterStatSigns("quenStat2", 'quen_damageabs', "gm_sign_stats_quen_dmg_absorption", "", gfxSpellPowerSub, parentFlashValueStorage); //modSigns
	AddCharacterStatSigns("quenStat3", 'quen_damageabs_alt', "gm_sign_stats_alt_quen_dmg_absorption", "", gfxSpellPowerSub, parentFlashValueStorage); //modSigns
	//modSigns: moved
	gfxSpellPower.SetMemberFlashArray("subStats", gfxSpellPowerSub);
	//modSigns
	gfxSpellPower2 = AddCharacterStat("mainMagicStat", 'spell_power', "stat_signs", "spell_power", statsArray, parentFlashValueStorage);
	gfxSpellPowerSub2 = parentFlashValueStorage.CreateTempFlashArray();
	AddCharacterHeader("stat_signs", gfxSpellPowerSub2, parentFlashValueStorage, true, "Blue");
	AddCharacterHeader("Yrden", gfxSpellPowerSub2, parentFlashValueStorage);
	AddCharacterStatSigns("yrdenStat1", 'yrden_power', "yrden_intensity", "", gfxSpellPowerSub2, parentFlashValueStorage); //modSigns
	AddCharacterStatSigns("yrdenStat4", 'yrden_traps', "gm_sign_stats_yrden_traps", "", gfxSpellPowerSub2, parentFlashValueStorage); //modSigns
	AddCharacterStatSigns("yrdenStat2", 'yrden_duration', "duration", "", gfxSpellPowerSub2, parentFlashValueStorage); //modSigns
	AddCharacterStatSigns("yrdenStat2", 'yrden_range', "gm_sign_stats_yrden_range", "", gfxSpellPowerSub2, parentFlashValueStorage); //modSigns
	AddCharacterStatSigns("yrdenStat3", 'yrden_slowdown', "SlowdownEffect", "", gfxSpellPowerSub2, parentFlashValueStorage); //modSigns
	//AddCharacterStatSigns("yrdenStat7", 'yrden_health_drain', "gm_sign_stats_yrden_damage", "", gfxSpellPowerSub2, parentFlashValueStorage); //modSigns
	AddCharacterStatSigns("yrdenStat5", 'yrden_duration_alt', "gm_sign_stats_alt_yrden_duration", "", gfxSpellPowerSub2, parentFlashValueStorage); //modSigns
	AddCharacterStatSigns("yrdenStat5", 'yrden_charges', "gm_sign_stats_alt_yrden_charges", "", gfxSpellPowerSub2, parentFlashValueStorage); //modSigns
	AddCharacterStatSigns("yrdenStat6", 'yrden_damage', "gm_sign_stats_alt_yrden_damage", "", gfxSpellPowerSub2, parentFlashValueStorage); //modSigns
	AddCharacterHeader("Axii", gfxSpellPowerSub2, parentFlashValueStorage);
	AddCharacterStatSigns("axiiStat1", 'axii_power', "axii_intensity", "", gfxSpellPowerSub2, parentFlashValueStorage); //modSigns
	//AddCharacterStatSigns("axiiStat2", 'axii_chance', "gm_sign_stats_alt_axii_chance", "", gfxSpellPowerSub2, parentFlashValueStorage); //modSigns
	AddCharacterStatSigns("axiiStat3", 'axii_duration_confusion', "gm_sign_stats_axii_duration_confusion", "", gfxSpellPowerSub2, parentFlashValueStorage); //modSigns
	AddCharacterStatSigns("axiiStat4", 'axii_instakill', "instant_kill_chance", "", gfxSpellPowerSub2, parentFlashValueStorage); //modSigns
	AddCharacterStatSigns("axiiStat5", 'axii_duration_control', "gm_sign_stats_axii_duration_control", "", gfxSpellPowerSub2, parentFlashValueStorage); //modSigns
	gfxSpellPower2.SetMemberFlashArray("subStats", gfxSpellPowerSub2);
	
	
	gfxStamina = AddCharacterStat("majorStat3", 'stamina', "stamina", "stamina", statsArray, parentFlashValueStorage);
	gfxStaminaSub = parentFlashValueStorage.CreateTempFlashArray();
	AddCharacterHeader("stamina", gfxStaminaSub, parentFlashValueStorage, true, "Blue");
	AddCharacterStat("defStat14", 'staminaOutOfCombatRegen', "attribute_name_staminaregen_out_of_combat", "", gfxStaminaSub, parentFlashValueStorage);
	AddCharacterStat("defStat15", 'staminaRegen', "attribute_name_staminaregen", "", gfxStaminaSub, parentFlashValueStorage);
	AddCharacterStat("defStat18", 'staminaCostLight', "attribute_name_stamina_cost_light", "", gfxStaminaSub, parentFlashValueStorage);
	AddCharacterStat("defStat19", 'staminaCostHeavy', "attribute_name_stamina_cost_heavy", "", gfxStaminaSub, parentFlashValueStorage);
	AddCharacterStat("defStat20", 'staminaCostCounter', "attribute_name_stamina_cost_counter", "", gfxStaminaSub, parentFlashValueStorage);
	AddCharacterStat("defStat21", 'staminaCostParry', "attribute_name_stamina_cost_parry", "", gfxStaminaSub, parentFlashValueStorage);
	AddCharacterStat("defStat22", 'staminaCostDodge', "attribute_name_stamina_cost_dodge", "", gfxStaminaSub, parentFlashValueStorage);
	AddCharacterStat("defStat23", 'staminaCostRoll', "attribute_name_stamina_cost_roll", "", gfxStaminaSub, parentFlashValueStorage);
	AddCharacterStat("defStat24", 'staminaCostSprint', "attribute_name_stamina_cost_sprint", "", gfxStaminaSub, parentFlashValueStorage);
	AddCharacterStat("defStat25", 'staminaCostJump', "attribute_name_stamina_cost_jump", "", gfxStaminaSub, parentFlashValueStorage);
	AddCharacterStat("defStat26", 'staminaCostItem', "attribute_name_stamina_cost_item", "", gfxStaminaSub, parentFlashValueStorage);
	AddCharacterStat("defStat27", 'staminaCostAard', "attribute_name_stamina_cost_aard", "", gfxStaminaSub, parentFlashValueStorage);
	AddCharacterStat("defStat28", 'staminaCostIgni', "attribute_name_stamina_cost_igni", "", gfxStaminaSub, parentFlashValueStorage);
	AddCharacterStat("defStat29", 'staminaCostYrden', "attribute_name_stamina_cost_yrden", "", gfxStaminaSub, parentFlashValueStorage);
	AddCharacterStat("defStat30", 'staminaCostQuen', "attribute_name_stamina_cost_quen", "", gfxStaminaSub, parentFlashValueStorage);
	AddCharacterStat("defStat31", 'staminaCostAxii', "attribute_name_stamina_cost_axii", "", gfxStaminaSub, parentFlashValueStorage);
	if(GetWitcherPlayer().CanUseSkill(S_Sword_s01))
		AddCharacterStat("defStat32", 'staminaCostWhirl', "attribute_name_stamina_cost_whirl", "", gfxStaminaSub, parentFlashValueStorage);
	if(GetWitcherPlayer().CanUseSkill(S_Sword_s02))
		AddCharacterStat("defStat33", 'staminaCostRend', "attribute_name_stamina_cost_rend", "", gfxStaminaSub, parentFlashValueStorage);
	gfxStamina.SetMemberFlashArray("subStats", gfxStaminaSub);
	
	
	
	gfxAdditional = AddCharacterStat("majorStat5", 'additional', "panel_common_statistics_category_additional", "additional", statsArray, parentFlashValueStorage);
	gfxAdditionalSub = parentFlashValueStorage.CreateTempFlashArray();
	AddCharacterHeader("panel_common_statistics_category_additional", gfxAdditionalSub, parentFlashValueStorage, true, "Brown");
	AddCharacterStatF("extraStat0", 'bonus_money', "bonus_money", "", gfxAdditionalSub , parentFlashValueStorage); //modSigns
	AddCharacterStatF("extraStat1", 'bonus_herb_chance', "bonus_herb_chance", "", gfxAdditionalSub, parentFlashValueStorage);
	AddCharacterStatU("extraStat2", 'instant_kill_chance_mult', "instant_kill_chance", "", gfxAdditionalSub , parentFlashValueStorage);
	//AddCharacterStatU("extraStat3", 'human_exp_bonus_when_fatal', "human_exp_bonus_when_fatal", "", gfxAdditionalSub , parentFlashValueStorage);
	//AddCharacterStatU("extraStat4", 'nonhuman_exp_bonus_when_fatal', "nonhuman_exp_bonus_when_fatal", "", gfxAdditionalSub , parentFlashValueStorage);
	AddCharacterStatU("extraStat4", 'adrenaline_gain', "gm_stat_adrenaline_gain", "", gfxAdditionalSub , parentFlashValueStorage); //modSigns
	if( thePlayer.CanUseSkill(S_Sword_s21) ) //modSigns
		AddCharacterStatU("extraStat4", 'adrenaline_gain_light', "gm_stat_adrenaline_gain_light", "", gfxAdditionalSub , parentFlashValueStorage);
	if( thePlayer.CanUseSkill(S_Sword_s04) ) //modSigns
		AddCharacterStatU("extraStat4", 'adrenaline_gain_heavy', "gm_stat_adrenaline_gain_heavy", "", gfxAdditionalSub , parentFlashValueStorage);
	//AddCharacterStatU("extraStat5", 'attack_power_levelup_bonus', "gm_stat_attack_power_levelup_bonus", "", gfxAdditionalSub , parentFlashValueStorage); //modSigns
	gfxAdditional.SetMemberFlashArray("subStats", gfxAdditionalSub);
	
	
	
	gameTime =	theGame.CalculateTimePlayed();
	gameTimeHours = (string)(GameTimeDays(gameTime) * 24 + GameTimeHours(gameTime));
	gameTimeMinutes = (string)GameTimeMinutes(gameTime);
	
	gfxData.SetMemberFlashArray("stats", statsArray);
	gfxData.SetMemberFlashString("hoursPlayed", gameTimeHours);
	gfxData.SetMemberFlashString("minutesPlayed", gameTimeMinutes);
	
	return gfxData;
	
	
	
	
}

function AddCharacterHeader(locKey:string, toArray : CScriptedFlashArray, flashMaster:CScriptedFlashValueStorage, optional isSuperHeader : bool, optional color : string):void
{
	var statObject : CScriptedFlashObject;
	var final_name : string;

	//modSigns: allows using of non-localized text
	final_name = GetLocStringByKeyExt(locKey); if ( final_name == "#" || final_name == "" ) { final_name = locKey; }
	statObject = flashMaster.CreateTempFlashObject();
	statObject.SetMemberFlashString("name", final_name);
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

function AddCharacterStat(tag : string, varKey:name, locKey:string, iconTag:string, toArray : CScriptedFlashArray, flashMaster:CScriptedFlashValueStorage):CScriptedFlashObject
{
	var statObject 		: CScriptedFlashObject;
	var valueStr 		: string;
	var valueMaxStr 	: string;
	var valueAbility 	: float;
	var final_name 		: string;
	var sp 				: SAbilityAttributeValue;
	var itemColor		: string;
	
	var gameTime		: GameTime;
	var gameTimeDays	: string;
	var gameTimeHours	: string;
	var gameTimeMinutes	: string;
	var gameTimeSeconds	: string;
	
	statObject			= 	flashMaster.CreateTempFlashObject();
	
	gameTime			=	theGame.CalculateTimePlayed();
	gameTimeDays 		= 	(string)GameTimeDays(gameTime);
	gameTimeHours 		= 	(string)GameTimeHours(gameTime);
	gameTimeMinutes 	= 	(string)GameTimeMinutes(gameTime);
	gameTimeSeconds 	= 	(string)GameTimeSeconds(gameTime);
	
	valueMaxStr = "";
	itemColor = "";

	if ( varKey == 'vitality' )
	{
		valueStr = (string)RoundMath(thePlayer.GetStat(BCS_Vitality, true));
		valueMaxStr = (string)RoundMath(thePlayer.GetStatMax(BCS_Vitality));
		itemColor = "Green";
	}
	else if ( varKey == 'toxicity' )
	{
		valueStr = (string)RoundMath(thePlayer.GetStat(BCS_Toxicity, false));
		valueMaxStr = (string)RoundMath(thePlayer.GetStatMax(BCS_Toxicity));
		itemColor = "Green";
	}
	else if ( varKey == 'stamina' ) 	
	{ 
		valueStr = (string)RoundMath(thePlayer.GetStat(BCS_Stamina, true));
		valueMaxStr = (string)RoundMath(thePlayer.GetStatMax(BCS_Stamina)); 
		itemColor = "Blue";
	}
	else if ( varKey == 'focus' )
	{
		valueStr = (string)FloorF(thePlayer.GetStat(BCS_Focus, true));
		valueMaxStr = (string)RoundMath(thePlayer.GetStatMax(BCS_Focus));
		itemColor = "Blue";
	}
	else if ( varKey == 'spell_power' )
	{
		//sp += GetWitcherPlayer().GetTotalSignSpellPower(S_Magic_1);
		//sp += GetWitcherPlayer().GetTotalSignSpellPower(S_Magic_2);
		//sp += GetWitcherPlayer().GetTotalSignSpellPower(S_Magic_3);
		//sp += GetWitcherPlayer().GetTotalSignSpellPower(S_Magic_4);
		//sp += GetWitcherPlayer().GetTotalSignSpellPower(S_Magic_5);
		
		//valueAbility = sp.valueMultiplicative / 5 - 1;
		//modSigns: show raw spell power
		sp = GetWitcherPlayer().abilityManager.GetAttributeValueUnsafe('spell_power');
		//GetWitcherPlayer().ApplyMutation10StatBoost( sp ); //modSigns: reworked
		valueAbility = MaxF(sp.valueMultiplicative - 1, 0);
		valueStr = "+" + (string)RoundMath(valueAbility * 100) + " %";
		
		itemColor = "Blue";
	}
	else if ( varKey == 'vitalityRegen' ) 
	{ 
		//modSigns
		sp = GetWitcherPlayer().GetAttributeValue( varKey );
		gmModRegenValue('vitalityRegen', sp);
		//valueAbility = CalculateAttributeValue( sp );
		valueAbility = sp.valueAdditive + sp.valueMultiplicative * GetWitcherPlayer().GetStatMax(BCS_Vitality);
		valueStr = NoTrailZeros(RoundMath(valueAbility)) + "/" + GetLocStringByKeyExt("per_second");
	}
	else if ( varKey == 'vitalityCombatRegen' ) 
	{ 
		//modSigns
		sp = GetWitcherPlayer().GetAttributeValue( varKey );
		gmModRegenValue('vitalityCombatRegen', sp);
		//valueAbility = CalculateAttributeValue( sp );
		valueAbility = sp.valueAdditive + sp.valueMultiplicative * GetWitcherPlayer().GetStatMax(BCS_Vitality);
		valueStr = NoTrailZeros(RoundMath(valueAbility)) + "/" + GetLocStringByKeyExt("per_second");
	}
	else if ( varKey == 'staminaRegen' ) 
	{
		sp = GetWitcherPlayer().GetAttributeValue(varKey);
		gmModRegenValue('staminaRegen', sp); //modSigns
		valueAbility = sp.valueAdditive + sp.valueMultiplicative * GetWitcherPlayer().GetStatMax(BCS_Stamina);
		
		if(theGame.params.IsArmorRegenPenaltyEnabled()) //modSigns
			valueAbility *= 1 + GetWitcherPlayer().CalculatedArmorStaminaRegenBonus();
		valueStr = NoTrailZeros(RoundMath(valueAbility)) + "/" + GetLocStringByKeyExt("per_second"); 
	}
	else if ( varKey == 'staminaRegenArmorMod' ) //modSigns: armor stamina modifier
	{
		valueAbility = GetWitcherPlayer().CalculatedArmorStaminaRegenBonus();
		valueStr = "";
		valueStr += NoTrailZeros(RoundMath(valueAbility * 100)) + " %";
	}
	/*else if ( varKey == 'chanceToIgnoreHitAnim' ) //modSigns: chance to ignore hit anim
	{
		valueAbility = GetWitcherPlayer().GetChanceToIgnoreHitAnim();
		valueStr = "";
		valueStr += NoTrailZeros(RoundMath(valueAbility)) + " %";
	}*/
	else if ( varKey == 'staminaOutOfCombatRegen' ) 
	{
		sp = GetWitcherPlayer().GetAttributeValue(varKey);
		gmModRegenValue('staminaOutOfCombatRegen', sp); //modSigns
		
		valueAbility = GetWitcherPlayer().GetStatMax(BCS_Stamina) * sp.valueMultiplicative + sp.valueAdditive;
		if(theGame.params.IsArmorRegenPenaltyEnabled()) //modSigns
			valueAbility *= 1 + GetWitcherPlayer().CalculatedArmorStaminaRegenBonus();
		valueStr = NoTrailZeros(RoundMath(valueAbility)) + "/" + GetLocStringByKeyExt("per_second"); 
	}
	//modSigns begin
	else if ( varKey == 'staminaCostLight' )
	{
		valueStr = NoTrailZeros(RoundTo(GetWitcherPlayer().GetStaminaActionCost(ESAT_LightAttack), 2));
	}
	else if ( varKey == 'staminaCostHeavy' )
	{
		valueStr = NoTrailZeros(RoundTo(GetWitcherPlayer().GetStaminaActionCost(ESAT_HeavyAttack), 2));
	}
	else if ( varKey == 'staminaCostParry' )
	{
		valueStr = NoTrailZeros(RoundTo(GetWitcherPlayer().GetStaminaActionCost(ESAT_Parry), 2));
	}
	else if ( varKey == 'staminaCostCounter' )
	{
		valueStr = NoTrailZeros(RoundTo(GetWitcherPlayer().GetStaminaActionCost(ESAT_Counterattack), 2));
	}
	else if ( varKey == 'staminaCostDodge' )
	{
		valueStr = NoTrailZeros(RoundTo(GetWitcherPlayer().GetStaminaActionCost(ESAT_Dodge), 2));
	}
	else if ( varKey == 'staminaCostRoll' )
	{
		valueStr = NoTrailZeros(RoundTo(GetWitcherPlayer().GetStaminaActionCost(ESAT_Roll), 2));
	}
	else if ( varKey == 'staminaCostSprint' )
	{
		valueStr = NoTrailZeros(RoundTo(GetWitcherPlayer().GetStaminaActionCost(ESAT_Sprint, , 1.0f), 2)) + "/" + GetLocStringByKeyExt("per_second");
	}
	else if ( varKey == 'staminaCostJump' )
	{
		valueStr = NoTrailZeros(RoundTo(GetWitcherPlayer().GetStaminaActionCost(ESAT_Jump), 2));
	}
	else if ( varKey == 'staminaCostItem' )
	{
		valueStr = NoTrailZeros(RoundTo(GetWitcherPlayer().GetStaminaActionCost(ESAT_UsableItem), 2));
	}
	else if ( varKey == 'staminaCostAard' )
	{
		valueStr = NoTrailZeros(RoundTo(((W3PlayerAbilityManager)GetWitcherPlayer().GetAbilityManager()).GetSkillStaminaUseCost(S_Magic_1), 2));
	}
	else if ( varKey == 'staminaCostIgni' )
	{
		valueStr = NoTrailZeros(RoundTo(((W3PlayerAbilityManager)GetWitcherPlayer().GetAbilityManager()).GetSkillStaminaUseCost(S_Magic_2), 2));
	}
	else if ( varKey == 'staminaCostYrden' )
	{
		valueStr = NoTrailZeros(RoundTo(((W3PlayerAbilityManager)GetWitcherPlayer().GetAbilityManager()).GetSkillStaminaUseCost(S_Magic_3), 2));
	}
	else if ( varKey == 'staminaCostQuen' )
	{
		valueStr = NoTrailZeros(RoundTo(((W3PlayerAbilityManager)GetWitcherPlayer().GetAbilityManager()).GetSkillStaminaUseCost(S_Magic_4), 2));
	}
	else if ( varKey == 'staminaCostAxii' )
	{
		valueStr = NoTrailZeros(RoundTo(((W3PlayerAbilityManager)GetWitcherPlayer().GetAbilityManager()).GetSkillStaminaUseCost(S_Magic_5), 2));
	}
	else if ( varKey == 'staminaCostWhirl' )
	{
		valueStr = NoTrailZeros(RoundTo(GetWitcherPlayer().GetWhirlStaminaCost(1.0f), 2)) + "/" + GetLocStringByKeyExt("per_second");
	}
	else if ( varKey == 'staminaCostRend' )
	{
		valueStr = NoTrailZeros(RoundTo(GetWitcherPlayer().GetRendStaminaCost(1.0f), 2)) + "/" + GetLocStringByKeyExt("per_second");
	}
	//modSigns end
	else if( varKey == 'armor')
	{	
		valueAbility =  CalculateAttributeValue( GetWitcherPlayer().GetTotalArmor() );
		valueStr = IntToString( RoundMath(  valueAbility ) );
		itemColor = "Red";
	}
	else if (varKey == 'crossbow')
	{
		valueStr = NoTrailZeros(RoundMath(GetEquippedCrossbowDamage()));
		itemColor = "Red";
	}	
	else if (varKey == 'additional')
	{
		valueStr = "";
		itemColor = "Brown";
	}
	else
	{	
		valueAbility =  CalculateAttributeValue( GetWitcherPlayer().GetAttributeValue( varKey ) );
		valueStr = IntToString( RoundMath(  valueAbility ) );
	}
	//modSigns: allows using of non-localized text
	final_name = GetLocStringByKeyExt(locKey); if ( final_name == "#" || final_name == "" ) { final_name = locKey; }
	statObject.SetMemberFlashString("name", final_name);
	statObject.SetMemberFlashString("value", valueStr);
	statObject.SetMemberFlashString("maxValue", valueMaxStr);
	statObject.SetMemberFlashString("tag", tag);
	statObject.SetMemberFlashString("iconTag", iconTag);
	statObject.SetMemberFlashString("itemColor", itemColor);
	toArray.PushBackFlashObject(statObject);
	
	return statObject;
}

function AddCharacterStatToxicity(tag : string, varKey:name, locKey:string, iconTag:string, toArray : CScriptedFlashArray, flashMaster:CScriptedFlashValueStorage):CScriptedFlashObject
{
	var statObject : CScriptedFlashObject;
	var valueStr : string;
	var valueAbility : float;
	
	var toxicityLocked : float;
	var toxicityNoLock : float;
	
	var sp : SAbilityAttributeValue;
	var final_name 		: string;
	var itemColor		: string;
	
	var attrVal, min, max : SAbilityAttributeValue; //modSigns
	
	statObject = flashMaster.CreateTempFlashObject();
	
	toxicityNoLock = GetWitcherPlayer().GetStat(BCS_Toxicity, true);
	toxicityLocked = GetWitcherPlayer().GetStat(BCS_Toxicity) - toxicityNoLock;
	
	if ( varKey == 'lockedToxicity' )	
	{
		valueStr = NoTrailZeros(RoundMath(toxicityLocked));
	}
	//modSigns begin
	//else if( varKey == 'toxicity' )
	//{
	//	valueStr = NoTrailZeros(RoundMath(toxicityNoLock));
	//}
	//else if( varKey == 'nonres_tox' )
	//{
	//	valueStr = NoTrailZeros(RoundMath(GetWitcherPlayer().GetStatMax(BCS_Toxicity) - toxicityLocked));
	//}
	else if( varKey == 'avail_tox' )
	{
		valueStr = NoTrailZeros(RoundMath(GetWitcherPlayer().GetStatMax(BCS_Toxicity) - GetWitcherPlayer().GetStat(BCS_Toxicity)));
	}
	else if( varKey == 'tox_dec_rate' )
	{
		theGame.GetDefinitionsManager().GetAbilityAttributeValue('ToxicityEffect', 'toxicityRegen', min, max);
		attrVal = GetAttributeRandomizedValue(min, max);
		if(thePlayer.HasAbility('ArmorTypeMediumSetBonusAbility'))
		{
			theGame.GetDefinitionsManager().GetAbilityAttributeValue('ArmorTypeMediumSetBonusAbility', 'toxicityRegen', min, max);
			attrVal += min;
		}
		if(thePlayer.CanUseSkill(S_Alchemy_s15))
		{
			attrVal += thePlayer.GetSkillAttributeValue(S_Alchemy_s15, 'toxicityRegen', false, true) * thePlayer.GetSkillLevel(S_Alchemy_s15);
		}
		if(thePlayer.HasAbility('Runeword 8 Regen'))
		{
			attrVal += thePlayer.GetAbilityAttributeValue('Runeword 8 Regen', 'toxicityRegen');
		}
		if(GetWitcherPlayer().IsMutationActive(EPMT_Mutation4))
		{
			theGame.GetDefinitionsManager().GetAbilityAttributeValue('Mutation4', 'toxicityRegenFactor', min, max);
			attrVal.valueAdditive *= 1 - min.valueAdditive;
		}
		valueStr = NoTrailZeros(RoundTo(-1 * attrVal.valueAdditive, 2)) + "/" + GetLocStringByKeyExt("per_second");
	}
	else if( varKey == 'tox_overdose' )
	{
		valueStr = NoTrailZeros(RoundMath(GetWitcherPlayer().GetToxicityDamageThreshold() * GetWitcherPlayer().GetStatMax(BCS_Toxicity)));
	}
	else if( varKey == 'tox_hp_drain' )
	{
		//theGame.GetDefinitionsManager().GetAbilityAttributeValue('ToxicityEffect', 'DirectDamage', min, max);
		//valueStr = NoTrailZeros(RoundMath(min.valueMultiplicative * thePlayer.GetStatMax(BCS_Vitality))) + "/" + GetLocStringByKeyExt("per_second");
		valueStr = NoTrailZeros(RoundMath(GetWitcherPlayer().GetToxicityDamage())) + "/" + GetLocStringByKeyExt("per_second");
	}
	//modSigns end
	
	final_name = GetLocStringByKeyExt(locKey); if ( final_name == "#" ) { final_name = ""; }
	statObject.SetMemberFlashString("name", final_name);
	statObject.SetMemberFlashString("value", valueStr);
	statObject.SetMemberFlashString("tag", tag);
	statObject.SetMemberFlashString("iconTag", iconTag);
	statObject.SetMemberFlashString("itemColor", itemColor);
	toArray.PushBackFlashObject(statObject);
	
	return statObject;
}

function AddCharacterStatSigns(tag : string, varKey:name, locKey:string, iconTag:string, toArray : CScriptedFlashArray, flashMaster:CScriptedFlashValueStorage):CScriptedFlashObject
{
	var statObject : CScriptedFlashObject;
	var valueStr : string;
	var valueAbility : float;
	var final_name : string;
	//var min, max : float;
	var fVal : float;
	var mutagen09Bonus : float; //modSigns
	var sp, mutDmgMod, min, max : SAbilityAttributeValue;
	var sword : SItemUniqueId;
	
	statObject = flashMaster.CreateTempFlashObject();
	
	if( GetWitcherPlayer().IsMutationActive( EPMT_Mutation1 ) )
	{
		sword = thePlayer.inv.GetCurrentlyHeldSword();
			
		if( thePlayer.inv.GetItemCategory(sword) == 'steelsword' )
		{
			mutDmgMod += thePlayer.inv.GetItemAttributeValue(sword, theGame.params.DAMAGE_NAME_SLASHING);
		}
		else if( thePlayer.inv.GetItemCategory(sword) == 'silversword' )
		{
			mutDmgMod += thePlayer.inv.GetItemAttributeValue(sword, theGame.params.DAMAGE_NAME_SILVER);
		}
		theGame.GetDefinitionsManager().GetAbilityAttributeValue('Mutation1', 'dmg_bonus_factor', min, max);
			
		mutDmgMod.valueBase *= CalculateAttributeValue(min);
	}
	
	//modSigns: Euphoria damage buff
	if(GetWitcherPlayer().HasBuff(EET_Mutation10))
		mutDmgMod.valueBase += GetWitcherPlayer().GetToxicityDamage();
	
	//modSigns
	if(GetWitcherPlayer().HasBuff(EET_Mutagen09))
		mutagen09Bonus = ((W3Mutagen09_Effect)GetWitcherPlayer().GetBuff(EET_Mutagen09)).GetM09Bonus();
	
	if ( varKey == 'aard_knockdownchance' )	
	{ 
		sp = GetWitcherPlayer().GetTotalSignSpellPower(S_Magic_1);
		//valueAbility = sp.valueMultiplicative / theGame.params.MAX_SPELLPOWER_ASSUMED;// - 4 * theGame.params.NPC_RESIST_PER_LEVEL;  
		//modSigns
		valueAbility = SignPowerStatToPowerBonus(sp.valueMultiplicative);
		valueAbility = CalculateAttributeValue(GetWitcherPlayer().GetSkillAttributeValue(S_Magic_1, 'starting_knockdown_chance', false, false)) * (1 + valueAbility);
		//Metamorphosis new bonus
		if(GetWitcherPlayer().IsMutationActive(EPMT_Mutation12))
			valueAbility *= MaxF(1.0f, 1.0f + GetWitcherPlayer().Mutation12GetBonus());
		valueAbility = ClampF(valueAbility, 0.0f, 1.0f);
		valueStr = (string)RoundMath( valueAbility * 100 ) + " %";
	}
	else if ( varKey == 'aard_heavyknockdownchance' )	
	{ 
		sp = GetWitcherPlayer().GetTotalSignSpellPower(S_Magic_1);
		//valueAbility = sp.valueMultiplicative / theGame.params.MAX_SPELLPOWER_ASSUMED;// - 4 * theGame.params.NPC_RESIST_PER_LEVEL;  
		//modSigns
		valueAbility = SignPowerStatToPowerBonus(sp.valueMultiplicative);
		fVal = 0.15;
		if( GetWitcherPlayer().CanUseSkill(S_Magic_s12) )
		{
			sp = GetWitcherPlayer().GetSkillAttributeValue(S_Magic_s12, 'heavy_knockdown_chance_bonus', false, false);
			fVal += sp.valueMultiplicative * GetWitcherPlayer().GetSkillLevel(S_Magic_s12);
		}
		valueAbility = CalculateAttributeValue(GetWitcherPlayer().GetSkillAttributeValue(S_Magic_1, 'starting_knockdown_chance', false, false)) * (1 + valueAbility);
		fVal *= valueAbility;
		valueStr = (string)RoundMath( fVal * 100 ) + " %";
	}
	else if ( varKey == 'aard_damage' ) 	
	{  
		if ( GetWitcherPlayer().CanUseSkill(S_Magic_s06) )
		{
			//modSigns
			sp = GetWitcherPlayer().GetTotalSignSpellPower(S_Magic_1);
			valueAbility = GetWitcherPlayer().GetSkillLevel(S_Magic_s06) * CalculateAttributeValue( GetWitcherPlayer().GetSkillAttributeValue( S_Magic_s06, theGame.params.DAMAGE_NAME_FORCE, false, true ) );
			valueAbility += mutDmgMod.valueBase; //Mutation1 damage increase
			valueAbility += mutagen09Bonus; //modSigns: mutagen09 bonus damage
			valueAbility *= 1 + CalculateAttributeValue(GetWitcherPlayer().GetAttributeValue( 'spell_dmg_bonus' ));
			valueAbility *= sp.valueMultiplicative;
			valueStr = (string)RoundMath( valueAbility );
		}
		else
			valueStr = "0";
	}
	else if ( varKey == 'aard_power' ) 	//modSigns
	{  
		sp = GetWitcherPlayer().GetTotalSignSpellPower(S_Magic_1);
		valueAbility = MaxF(sp.valueMultiplicative - 1, 0);
		valueStr = (string)RoundMath(valueAbility * 100) + " %";
	}
	else if ( varKey == 'igni_damage' ) 	
	{  
		sp = GetWitcherPlayer().GetTotalSignSpellPower(S_Magic_2);
		valueAbility = CalculateAttributeValue( GetWitcherPlayer().GetSkillAttributeValue( S_Magic_2, theGame.params.DAMAGE_NAME_FIRE, false, true ) );
		//modSigns: damage bonus
		if(GetWitcherPlayer().CanUseSkill(S_Magic_s07))
			valueAbility += CalculateAttributeValue(GetWitcherPlayer().GetSkillAttributeValue(S_Magic_s07, 'fire_damage_bonus', false, false)) * GetWitcherPlayer().GetSkillLevel(S_Magic_s07);
		//valueAbility *= 1 + (sp.valueMultiplicative-1) * theGame.params.IGNI_SPELL_POWER_MILT;
		valueAbility += mutDmgMod.valueBase; //Mutation1 damage increase
		//Rotation damage increase
		if(GetWitcherPlayer().HasGlyphwordActive('Glyphword 7 _Stats'))
		{
			theGame.GetDefinitionsManager().GetAbilityAttributeValue('Glyphword 7 _Stats', 'glyphword7_dmg_buff', min, max);
			valueAbility += CalculateAttributeValue(min);
		}
		valueAbility += mutagen09Bonus; //modSigns: mutagen09 bonus damage
		valueAbility *= 1 + CalculateAttributeValue(GetWitcherPlayer().GetAttributeValue( 'spell_dmg_bonus' ));
		valueAbility *= sp.valueMultiplicative; // no actual change, but less unnecessary noise
		valueStr = (string)RoundMath( valueAbility );
	}
	else if ( varKey == 'igni_burnchance' ) 	
	{  
		//modSigns
		//sp = GetWitcherPlayer().GetTotalSignSpellPower(S_Magic_2);
		//valueAbility = sp.valueMultiplicative / theGame.params.MAX_SPELLPOWER_ASSUMED;// - 4 * theGame.params.NPC_RESIST_PER_LEVEL;
		valueAbility = CalculateAttributeValue(GetWitcherPlayer().GetSkillAttributeValue(S_Magic_2, 'initial_burn_chance', false, true));
		//modSigns: pyromaniac
		if(GetWitcherPlayer().CanUseSkill(S_Magic_s09))
			valueAbility += CalculateAttributeValue(GetWitcherPlayer().GetSkillAttributeValue(S_Magic_s09, 'chance_bonus', false, true)) * GetWitcherPlayer().GetSkillLevel(S_Magic_s09);
		//modSigns: Rotation
		if(GetWitcherPlayer().HasGlyphwordActive('Glyphword 7 _Stats'))
			valueAbility += CalculateAttributeValue(GetWitcherPlayer().GetAbilityAttributeValue('Glyphword 7 _Stats', 'glyphword7_burnchance_debuff'));
		valueAbility = MaxF(0, valueAbility);
		//Metamorphosis new bonus
		if(GetWitcherPlayer().IsMutationActive(EPMT_Mutation12))
			valueAbility *= MaxF(1.0f, 1.0f + GetWitcherPlayer().Mutation12GetBonus());
		valueStr = (string)RoundMath(valueAbility * 100) + " %";
	}
	else if ( varKey == 'igni_power' ) 	//modSigns
	{  
		sp = GetWitcherPlayer().GetTotalSignSpellPower(S_Magic_2);
		valueAbility = MaxF(sp.valueMultiplicative - 1, 0);
		valueStr = (string)RoundMath(valueAbility * 100) + " %";
	}
	else if ( varKey == 'igni_dmg_alt' ) //modSigns
	{  
		if(GetWitcherPlayer().CanUseSkill(S_Magic_s02))
		{
			sp = GetWitcherPlayer().GetSkillAttributeValue(S_Magic_s02, 'channeling_damage', false, false);
			sp += GetWitcherPlayer().GetSkillAttributeValue(S_Magic_s02, 'channeling_damage_after_1', false, false) * (GetWitcherPlayer().GetSkillLevel(S_Magic_s02) - 1);
			valueAbility = sp.valueAdditive;
			if(GetWitcherPlayer().CanUseSkill(S_Magic_s07))
				valueAbility += CalculateAttributeValue(GetWitcherPlayer().GetSkillAttributeValue(S_Magic_s07, 'channeling_damage_bonus', false, false)) * GetWitcherPlayer().GetSkillLevel(S_Magic_s07);
			valueAbility += mutDmgMod.valueBase; //Mutation1 damage increase
			valueAbility += mutagen09Bonus; //modSigns: mutagen09 bonus damage
			valueAbility *= 1 + CalculateAttributeValue(GetWitcherPlayer().GetAttributeValue( 'spell_dmg_bonus' ));
			sp = GetWitcherPlayer().GetTotalSignSpellPower(S_Magic_2);
			valueAbility *= sp.valueMultiplicative;
		}
		valueStr = (string)RoundMath(valueAbility);
	}
	else if ( varKey == 'yrden_slowdown' )
	{
		//modSigns
		sp = GetWitcherPlayer().GetTotalSignSpellPower(S_Magic_3);
		//min = CalculateAttributeValue(GetWitcherPlayer().GetSkillAttributeValue(S_Magic_3, 'min_slowdown', false, true));
		//max = CalculateAttributeValue(GetWitcherPlayer().GetSkillAttributeValue(S_Magic_3, 'max_slowdown', false, true));
		//valueAbility = sp.valueMultiplicative / 4;
		//valueAbility =  min + (max - min) * valueAbility;
		//valueAbility = ClampF( valueAbility, min, max );
		//valueAbility *= 1 - ClampF(4 * theGame.params.NPC_RESIST_PER_LEVEL, 0, 1) ;
		valueAbility = CalculateAttributeValue(GetWitcherPlayer().GetSkillAttributeValue(S_Magic_3, 'min_starting_slowdown', false, false));
		valueAbility *= 1 + SignPowerStatToPowerBonus(sp.valueMultiplicative); //modded
		valueStr = (string)RoundMath( valueAbility * 100 ) + " %";
	}
	else if ( varKey == 'yrden_damage' )
	{
		if (GetWitcherPlayer().CanUseSkill(S_Magic_s03))
		{
			//modSigns
			sp = GetWitcherPlayer().GetTotalSignSpellPower(S_Magic_3);
			valueAbility = CalculateAttributeValue( GetWitcherPlayer().GetSkillAttributeValue( S_Magic_s03, theGame.params.DAMAGE_NAME_SHOCK, false, true ) );
			valueAbility += CalculateAttributeValue(GetWitcherPlayer().GetSkillAttributeValue(S_Magic_s03, 'damage_bonus_flat_after_1', false, true)) * (GetWitcherPlayer().GetSkillLevel(S_Magic_s03) - 1);
			if( GetWitcherPlayer().CanUseSkill(S_Magic_s16) )
				valueAbility += CalculateAttributeValue( GetWitcherPlayer().GetSkillAttributeValue( S_Magic_s16, 'turret_bonus_damage', false, true ) ) * GetWitcherPlayer().GetSkillLevel(S_Magic_s16);
			valueAbility += mutDmgMod.valueBase; //Mutation1 damage increase
			valueAbility += mutagen09Bonus; //modSigns: mutagen09 bonus damage
			valueAbility *= 1 + CalculateAttributeValue(GetWitcherPlayer().GetAttributeValue( 'spell_dmg_bonus' ));
			valueAbility *= sp.valueMultiplicative;
			valueStr = (string)RoundMath( valueAbility );
		}
		else
			valueStr = "0";
	}
	else if ( varKey == 'yrden_duration' )
	{
		//modSigns
		//sp += GetWitcherPlayer().GetTotalSignSpellPower(S_Magic_3);
		//sp.valueMultiplicative -= 1;
		valueAbility = CalculateAttributeValue(GetWitcherPlayer().GetSkillAttributeValue(S_Magic_3, 'trap_duration', false, false));
		if(GetWitcherPlayer().CanUseSkill(S_Magic_s10))
			valueAbility *= 1 + CalculateAttributeValue(GetWitcherPlayer().GetSkillAttributeValue(S_Magic_s10, 'trap_duration_bonus', false, false)) * GetWitcherPlayer().GetSkillLevel(S_Magic_s10);
		valueStr = FloatToStringPrec( valueAbility, 1 ) + GetLocStringByKeyExt("per_second");
	}
	else if ( varKey == 'yrden_range' )
	{
		valueAbility = 1;
		if(GetWitcherPlayer().CanUseSkill(S_Magic_s10) && GetWitcherPlayer().GetSkillLevel(S_Magic_s10) >= 2)
			valueAbility += CalculateAttributeValue(GetWitcherPlayer().GetSkillAttributeValue(S_Magic_s10, 'range_bonus', false, false));
		if(GetWitcherPlayer().IsSetBonusActive( EISB_Gryphon_2 ))
		{
			theGame.GetDefinitionsManager().GetAbilityAttributeValue('GryphonSetBonusYrdenEffect', 'trigger_scale', min, max);
			valueAbility += min.valueAdditive - 1;
		}
		valueAbility *= CalculateAttributeValue(GetWitcherPlayer().GetSkillAttributeValue(S_Magic_3, 'range', false, false));
		valueStr = FloatToStringPrec( valueAbility, 1 );
	}
	else if ( varKey == 'yrden_duration_alt' )  //modSigns
	{
		if (GetWitcherPlayer().CanUseSkill(S_Magic_s03))
		{
			valueAbility = CalculateAttributeValue(GetWitcherPlayer().GetSkillAttributeValue(S_Magic_s03, 'trap_duration', false, false));
			valueAbility += CalculateAttributeValue(GetWitcherPlayer().GetSkillAttributeValue(S_Magic_s03, 'duration_bonus_flat_after_1', false, false))*(GetWitcherPlayer().GetSkillLevel(S_Magic_s03) - 1);
		}
		valueStr = FloatToStringPrec( valueAbility, 1 ) + GetLocStringByKeyExt("per_second");
	}
	else if ( varKey == 'yrden_traps' ) //modSigns
	{
		valueAbility = 1;
		if (GetWitcherPlayer().CanUseSkill(S_Magic_s10) && GetWitcherPlayer().GetSkillLevel(S_Magic_s10) >= 2)
		{
			valueAbility += 1;
		}
		valueStr = (string)RoundMath( valueAbility );
	}
	else if ( varKey == 'yrden_charges' ) //modSigns
	{
		if (GetWitcherPlayer().CanUseSkill(S_Magic_s03))
		{
			//valueAbility = CalculateAttributeValue(GetWitcherPlayer().GetSkillAttributeValue(S_Magic_3, 'charge_count', false, true));
			valueAbility = CalculateAttributeValue(GetWitcherPlayer().GetSkillAttributeValue(S_Magic_s03, 'charge_count', false, false));
			valueAbility += CalculateAttributeValue(GetWitcherPlayer().GetSkillAttributeValue(S_Magic_s03, 'charge_bonus_flat_after_1', false, false))*(GetWitcherPlayer().GetSkillLevel(S_Magic_s03) - 1);
		}
		valueStr = (string)RoundMath( valueAbility );
	}
	//else if ( varKey == 'yrden_health_drain' ) //modSigns
	//{
	//	if (GetWitcherPlayer().CanUseSkill(S_Magic_s11))
	//	{
	//		sp = GetWitcherPlayer().GetSkillAttributeValue( S_Magic_s11, 'direct_damage_per_sec', false, true );
	//		valueAbility = sp.valueMultiplicative * (float)GetWitcherPlayer().GetSkillLevel(S_Magic_s11);
	//		valueStr = FloatToStringPrec( valueAbility * 100, 1 ) + " %";
	//	}
	//	else
	//		valueStr = "0 %";
	//}
	else if ( varKey == 'yrden_power' ) //modSigns
	{  
		sp = GetWitcherPlayer().GetTotalSignSpellPower(S_Magic_3);
		valueAbility = MaxF(sp.valueMultiplicative - 1, 0);
		valueStr = (string)RoundMath(valueAbility * 100) + " %";
	}
	else if ( varKey == 'quen_damageabs' )
	{
		//modSigns
		valueAbility = CalculateAttributeValue(GetWitcherPlayer().GetSkillAttributeValue(S_Magic_4, 'shield_health', false, false));
		if( GetWitcherPlayer().CanUseSkill(S_Magic_s15) )
			valueAbility += CalculateAttributeValue(GetWitcherPlayer().GetSkillAttributeValue(S_Magic_s15, 'shield_health_bonus', false, true)) * GetWitcherPlayer().GetSkillLevel(S_Magic_s15);
		sp = GetWitcherPlayer().GetTotalSignSpellPower(S_Magic_4);
		valueAbility *= 1 + SignPowerStatToPowerBonus(sp.valueMultiplicative);
		valueStr = (string)RoundMath( valueAbility );
	}
	else if ( varKey == 'quen_damageabs_alt' ) //modSigns
	{
		if (GetWitcherPlayer().CanUseSkill(S_Magic_s04))
		{
			valueAbility = CalculateAttributeValue(GetWitcherPlayer().GetSkillAttributeValue(S_Magic_4, 'shield_health', false, false));
			if( GetWitcherPlayer().CanUseSkill(S_Magic_s15) )
				valueAbility += CalculateAttributeValue(GetWitcherPlayer().GetSkillAttributeValue(S_Magic_s15, 'shield_health_bonus', false, true)) * GetWitcherPlayer().GetSkillLevel(S_Magic_s15);
			sp = GetWitcherPlayer().GetTotalSignSpellPower(S_Magic_4);
			valueAbility *= 1 + SignPowerStatToPowerBonus(sp.valueMultiplicative);
			valueAbility *= CalculateAttributeValue(GetWitcherPlayer().GetSkillAttributeValue(S_Magic_s04, 'shield_health_factor', false, true));
		}
		valueStr = (string)RoundMath( valueAbility );
	}
	else if ( varKey == 'quen_power' ) //modSigns
	{  
		sp = GetWitcherPlayer().GetTotalSignSpellPower(S_Magic_4);
		if(GetWitcherPlayer().HasBuff(EET_Mutagen19))
			sp += ((W3Mutagen19_Effect)GetWitcherPlayer().GetBuff(EET_Mutagen19)).GetQuenPowerBonus();
		valueAbility = MaxF(sp.valueMultiplicative - 1, 0);
		valueStr = (string)RoundMath(valueAbility * 100) + " %";
	}
	else if ( varKey == 'quen_duration' ) //modSigns
	{  
		valueAbility = CalculateAttributeValue(GetWitcherPlayer().GetSkillAttributeValue(S_Magic_4, 'shield_duration', true, true));
		valueStr = (string)RoundMath(valueAbility) + GetLocStringByKeyExt("per_second");
	}
	else if ( varKey == 'quen_discharge_pts' ) //modSigns
	{  
		if (GetWitcherPlayer().CanUseSkill(S_Magic_s13))
		{
			sp = GetWitcherPlayer().GetTotalSignSpellPower(S_Magic_4);
			valueAbility = CalculateAttributeValue(GetWitcherPlayer().GetSkillAttributeValue(S_Magic_s13, 'ShockDamage', false, true)) * (GetWitcherPlayer().GetSkillLevel(S_Magic_s13) - 1);
			valueAbility += mutDmgMod.valueBase; //Mutation1 damage increase
			valueAbility += mutagen09Bonus; //modSigns: mutagen09 bonus damage
			if(GetWitcherPlayer().HasGlyphwordActive('Glyphword 5 _Stats'))
			{
				theGame.GetDefinitionsManager().GetAbilityAttributeValue( 'Glyphword 5 _Stats', 'glyphword5_dmg_boost', min, max );
				valueAbility *= 1 + min.valueMultiplicative;
			}
			valueAbility *= sp.valueMultiplicative;
		}
		valueStr = (string)RoundMath(valueAbility);
	}
	else if ( varKey == 'quen_discharge_percent' ) //modSigns
	{  
		if (GetWitcherPlayer().CanUseSkill(S_Magic_s14))
		{			
			valueAbility = CalculateAttributeValue(GetWitcherPlayer().GetSkillAttributeValue(S_Magic_s14, 'discharge_percent', false, true)) * GetWitcherPlayer().GetSkillLevel(S_Magic_s14);
			if(GetWitcherPlayer().HasGlyphwordActive('Glyphword 5 _Stats'))
			{
				theGame.GetDefinitionsManager().GetAbilityAttributeValue( 'Glyphword 5 _Stats', 'glyphword5_dmg_boost', min, max );
				valueAbility *= 1 + min.valueMultiplicative;
			}
		}
		valueStr = (string)RoundMath(valueAbility * 100) + " %";
	}
	else if ( varKey == 'axii_duration_confusion' )
	{
		//modSigns
		sp = GetWitcherPlayer().GetSkillAttributeValue(S_Magic_5, 'duration', false, true);
		valueAbility = sp.valueBase;
		sp = GetWitcherPlayer().GetTotalSignSpellPower(S_Magic_5);
		if(GetWitcherPlayer().CanUseSkill(S_Magic_s18))
			valueAbility *= 1 + CalculateAttributeValue(GetWitcherPlayer().GetSkillAttributeValue(S_Magic_s18, 'axii_duration_bonus', false, false)) * GetWitcherPlayer().GetSkillLevel(S_Magic_s18);
		valueAbility *= 1 + SignPowerStatToPowerBonus(sp.valueMultiplicative);
		valueStr = FloatToStringPrec(valueAbility, 1) + GetLocStringByKeyExt("per_second");
	}
	else if ( varKey == 'axii_instakill' ) //modSigns
	{
		sp = GetWitcherPlayer().GetTotalSignSpellPower(S_Magic_5);
		valueAbility = 1 * (1 + SignPowerStatToPowerBonus(sp.valueMultiplicative));
		valueStr = FloatToStringPrec(valueAbility, 1) + " %";
	}
	else if ( varKey == 'axii_duration_control' ) //modSigns
	{
		if(GetWitcherPlayer().CanUseSkill(S_Magic_s05))
		{
			sp = GetWitcherPlayer().GetSkillAttributeValue(S_Magic_s05, 'duration', false, true);
			sp += GetWitcherPlayer().GetSkillAttributeValue(S_Magic_s05, 'duration_bonus_after1', false, true) * (GetWitcherPlayer().GetSkillLevel(S_Magic_s05) - 1);
			valueAbility = sp.valueBase;
			sp = GetWitcherPlayer().GetTotalSignSpellPower(S_Magic_5);
			if(GetWitcherPlayer().CanUseSkill(S_Magic_s18))
				valueAbility *= 1 + CalculateAttributeValue(GetWitcherPlayer().GetSkillAttributeValue(S_Magic_s18, 'axii_duration_bonus', false, false)) * GetWitcherPlayer().GetSkillLevel(S_Magic_s18);
			valueAbility *= 1 + SignPowerStatToPowerBonus(sp.valueMultiplicative);
			valueStr = FloatToStringPrec(valueAbility, 1) + GetLocStringByKeyExt("per_second");
		}
		else
			valueStr = "0" + GetLocStringByKeyExt("per_second");
	}
	else if ( varKey == 'axii_power' ) //modSigns
	{  
		sp = GetWitcherPlayer().GetTotalSignSpellPower(S_Magic_5);
		valueAbility = MaxF(sp.valueMultiplicative - 1, 0);
		valueStr = (string)RoundMath(valueAbility * 100) + " %";
	}
	else
	{	
		valueAbility =  CalculateAttributeValue( GetWitcherPlayer().GetAttributeValue( varKey ) );
		valueStr = IntToString( RoundF(  valueAbility ) );
	}
	//modSigns: allows using of non-localized text
	final_name = GetLocStringByKeyExt(locKey); if ( final_name == "#" || final_name == "" ) { final_name = locKey; }
	statObject.SetMemberFlashString("name", final_name);
	statObject.SetMemberFlashString("value", valueStr);
	statObject.SetMemberFlashString("tag", tag);
	statObject.SetMemberFlashString("iconTag", iconTag);
	statObject.SetMemberFlashString("itemColor", "Blue");
	
	toArray.PushBackFlashObject(statObject);
	
	return statObject;
}

function AddCharacterStatF(tag : string, varKey:name, locKey:string, iconTag:string, toArray : CScriptedFlashArray, flashMaster:CScriptedFlashValueStorage):CScriptedFlashObject
{
	var statObject : CScriptedFlashObject;
	var valueStr : string;
	var valueAbility, pts, perc : float;
	var final_name : string;
	var witcher : W3PlayerWitcher;
	var isPointResist : bool;
	var stat : EBaseCharacterStats;
	var resist : ECharacterDefenseStats;
	var attributeValue : SAbilityAttributeValue;
	var powerStat : ECharacterPowerStats;
	
	statObject = flashMaster.CreateTempFlashObject();
		
	
	witcher = GetWitcherPlayer();
	stat = StatNameToEnum(varKey);
	if(stat != BCS_Undefined)
	{
		valueAbility = witcher.GetStat(stat);
	}
	else
	{
		resist = ResistStatNameToEnum(varKey, isPointResist);
		if(resist != CDS_None)
		{
			witcher.GetResistValue(resist, pts, perc);
			
			if(isPointResist)
				valueAbility = pts;
			else
				valueAbility = perc;
		}
		else
		{
			powerStat = PowerStatNameToEnum(varKey);
			if(powerStat != CPS_Undefined)
			{
				attributeValue = witcher.GetPowerStatValue(powerStat);
			}
			else
			{
				attributeValue = witcher.GetAttributeValue(varKey);
			}
			
			valueAbility = CalculateAttributeValue( attributeValue );
		}
	}
	
	
	valueStr = NoTrailZeros( RoundMath(valueAbility * 100) );
	//modSigns: allows using of non-localized text
	final_name = GetLocStringByKeyExt(locKey); if ( final_name == "#" || final_name == "" ) { final_name = locKey; }
	statObject.SetMemberFlashString("name", final_name);
	statObject.SetMemberFlashString("value", valueStr + " %");
	statObject.SetMemberFlashString("tag", tag);
	statObject.SetMemberFlashString("iconTag", iconTag);
	
	toArray.PushBackFlashObject(statObject);
	
	return statObject;
}

function AddCharacterStatU(tag : string, varKey:name, locKey:string, iconTag:string, toArray : CScriptedFlashArray, flashMaster:CScriptedFlashValueStorage):CScriptedFlashObject
{
	var curStats:SPlayerOffenseStats;
	var statObject : CScriptedFlashObject;
	var valueStr : string;
	var valueAbility, maxHealth, curHealth, val1, val2 : float; //modSigns
	var sp : SAbilityAttributeValue;
	var final_name : string;
	var item : SItemUniqueId;

	statObject = flashMaster.CreateTempFlashObject();
	
	
	
	
	
	
	if(varKey != 'instant_kill_chance_mult' && varKey != 'human_exp_bonus_when_fatal' && varKey != 'nonhuman_exp_bonus_when_fatal' && varKey != 'adrenaline_gain' && varKey != 'adrenaline_gain_ligh' && varKey != 'adrenaline_gain_heavy' && varKey != 'attack_power_levelup_bonus' && varKey != 'crossbow_adrenaline_gain' && varKey != 'area_nml' && varKey != 'area_novigrad' && varKey != 'area_skellige') //modSigns
	{
		curStats = GetWitcherPlayer().GetOffenseStatsList();
	}
	
	//modSigns: reworked sword stats
	if		( varKey == 'silverdamage' )			valueStr = NoTrailZeros(RoundMath((curStats.silverFastDPS+curStats.silverStrongDPS)/2));
	else if ( varKey == 'silverFastAP' )			valueStr = NoTrailZeros(RoundMath(curStats.silverFastAP * 100)) + " %";
	else if ( varKey == 'silverFastDmg' ) 			valueStr = NoTrailZeros(RoundMath(curStats.silverFastDmg));	
	else if ( varKey == 'silverFastCritChance' )	valueStr = NoTrailZeros(RoundMath(curStats.silverFastCritChance))+" %";
	else if ( varKey == 'silverFastCritAP' )		valueStr = NoTrailZeros(RoundMath(curStats.silverFastCritAP * 100)) + " %";
	else if ( varKey == 'silverFastCritDmg' ) 		valueStr = NoTrailZeros(RoundMath(curStats.silverFastCritDmg));	
	else if ( varKey == 'silverStrongAP' )			valueStr = NoTrailZeros(RoundMath(curStats.silverStrongAP * 100)) + " %";
	else if ( varKey == 'silverStrongDmg' ) 		valueStr = NoTrailZeros(RoundMath(curStats.silverStrongDmg));	
	else if ( varKey == 'silverStrongCritChance' )	valueStr = NoTrailZeros(RoundMath(curStats.silverStrongCritChance))+" %";
	else if ( varKey == 'silverStrongCritAP' )		valueStr = NoTrailZeros(RoundMath(curStats.silverStrongCritAP * 100)) + " %";
	else if ( varKey == 'silverStrongCritDmg' )		valueStr = NoTrailZeros(RoundMath(curStats.silverStrongCritDmg));	
	else if ( varKey == 'steeldamage' ) 			valueStr = NoTrailZeros(RoundMath((curStats.steelFastDPS+curStats.steelStrongDPS)/2));
	else if ( varKey == 'steelFastAP' )				valueStr = NoTrailZeros(RoundMath(curStats.steelFastAP * 100)) + " %";
	else if ( varKey == 'steelFastDmg' ) 			valueStr = NoTrailZeros(RoundMath(curStats.steelFastDmg));	
	else if ( varKey == 'steelFastCritChance' )		valueStr = NoTrailZeros(RoundMath(curStats.steelFastCritChance))+" %";
	else if ( varKey == 'steelFastCritAP' )			valueStr = NoTrailZeros(RoundMath(curStats.steelFastCritAP * 100)) + " %";
	else if ( varKey == 'steelFastCritDmg' ) 		valueStr = NoTrailZeros(RoundMath(curStats.steelFastCritDmg));	
	else if ( varKey == 'steelStrongAP' )			valueStr = NoTrailZeros(RoundMath(curStats.steelStrongAP * 100)) + " %";
	else if ( varKey == 'steelStrongDmg' ) 			valueStr = NoTrailZeros(RoundMath(curStats.steelStrongDmg));	
	else if ( varKey == 'steelStrongCritChance' )	valueStr = NoTrailZeros(RoundMath(curStats.steelStrongCritChance))+" %";
	else if ( varKey == 'steelStrongCritAP' )		valueStr = NoTrailZeros(RoundMath(curStats.steelStrongCritAP * 100)) + " %";
	else if ( varKey == 'steelStrongCritDmg' ) 		valueStr = NoTrailZeros(RoundMath(curStats.steelStrongCritDmg));	
	//modSigns: reworked crossbow stats
	else if ( varKey == 'crossbowAttackPower' )		valueStr = NoTrailZeros(RoundMath(curStats.crossbowAttackPower * 100))+" %";
	else if ( varKey == 'crossbowCritChance' )		valueStr = NoTrailZeros(RoundMath(curStats.crossbowCritChance * 100))+" %";
	else if ( varKey == 'crossbowCritDmgBonus' )	valueStr = NoTrailZeros(RoundMath(curStats.crossbowCritDmgBonus * 100))+" %";
	else if ( varKey == 'crossbowDmg' )				valueStr = "";
	else if ( varKey == 'crossbowSteelDmg' )		valueStr = NoTrailZeros(RoundMath(curStats.crossbowSteelDmg));
	else if ( varKey == 'crossbowSilverDmg' )		valueStr = NoTrailZeros(RoundMath(curStats.crossbowSilverDmg));
	else if ( varKey == 'crossbowElementaDmg' )		valueStr = NoTrailZeros(RoundMath(curStats.crossbowElementaDmg));
	//other stats
	else if ( varKey == 'instant_kill_chance_mult') 
	{
		valueAbility = 0;
		//if (thePlayer.CanUseSkill(S_Sword_s03))
		//{
		//	sp += GetWitcherPlayer().GetSkillAttributeValue(S_Sword_s03, 'instant_kill_chance', false, true);
		//	valueAbility = CalculateAttributeValue(sp);
		//	valueAbility *= thePlayer.GetSkillLevel(S_Sword_s03);
		//	valueAbility *= RoundF(thePlayer.GetStat(BCS_Focus));
		//}
		if (GetWitcherPlayer().GetItemEquippedOnSlot(EES_SteelSword, item))
			val1 = CalculateAttributeValue(thePlayer.inv.GetItemAttributeValue(item, varKey)); 
		if (GetWitcherPlayer().GetItemEquippedOnSlot(EES_SilverSword, item))
			val2 = CalculateAttributeValue(thePlayer.inv.GetItemAttributeValue(item, varKey)); 
		valueAbility = MaxF(val1, val2); //modSigns
		valueStr = NoTrailZeros(RoundMath(valueAbility * 100)) + " %";
	} 
	else if (varKey == 'human_exp_bonus_when_fatal' || varKey == 'nonhuman_exp_bonus_when_fatal') 
	{
		sp = thePlayer.GetAttributeValue(varKey);

		valueStr = NoTrailZeros(RoundMath(CalculateAttributeValue(sp) * 100)) + " %";
	}
	else if (varKey == 'adrenaline_gain') //modSigns
	{
		sp = thePlayer.GetAttributeValue('focus_gain');
		
		if ( thePlayer.CanUseSkill(S_Sword_s20) )
		{
			sp += GetWitcherPlayer().GetSkillAttributeValue(S_Sword_s20, 'focus_gain', false, true) * GetWitcherPlayer().GetSkillLevel(S_Sword_s20);
		}
		
		valueAbility = 0.1f * (1 + CalculateAttributeValue(sp));
		
		sp = thePlayer.GetAttributeValue('bonus_focus_gain');
		valueAbility += CalculateAttributeValue(sp);
		
		if(thePlayer.HasBuff(EET_Mutation7Buff))
			valueAbility *= 2;
		else if(thePlayer.HasBuff(EET_Mutation7Debuff))
			valueAbility /= 2;
		
		valueStr = FloatToStringPrec(valueAbility,2);
	}
	else if (varKey == 'adrenaline_gain_light') //modSigns
	{
		sp = thePlayer.GetAttributeValue('focus_gain');
		if ( thePlayer.CanUseSkill(S_Sword_s20) )
			sp += GetWitcherPlayer().GetSkillAttributeValue(S_Sword_s20, 'focus_gain', false, true) * GetWitcherPlayer().GetSkillLevel(S_Sword_s20);
		if ( thePlayer.CanUseSkill(S_Sword_s21) )
			sp += GetWitcherPlayer().GetSkillAttributeValue(S_Sword_s21, 'light_focus_gain', false, true) * GetWitcherPlayer().GetSkillLevel(S_Sword_s21);
		valueAbility = 0.1f * (1 + CalculateAttributeValue(sp));
		sp = thePlayer.GetAttributeValue('bonus_focus_gain');
		valueAbility += CalculateAttributeValue(sp);
		
		if(thePlayer.HasBuff(EET_Mutation7Buff))
			valueAbility *= 2;
		else if(thePlayer.HasBuff(EET_Mutation7Debuff))
			valueAbility /= 2;
		
		valueStr = FloatToStringPrec(valueAbility,2);
	}
	else if (varKey == 'adrenaline_gain_heavy') //modSigns
	{
		sp = thePlayer.GetAttributeValue('focus_gain');
		if ( thePlayer.CanUseSkill(S_Sword_s20) )
			sp += GetWitcherPlayer().GetSkillAttributeValue(S_Sword_s20, 'focus_gain', false, true) * GetWitcherPlayer().GetSkillLevel(S_Sword_s20);
		if ( thePlayer.CanUseSkill(S_Sword_s04) )
			sp += GetWitcherPlayer().GetSkillAttributeValue(S_Sword_s04, 'heavy_focus_gain', false, true) * GetWitcherPlayer().GetSkillLevel(S_Sword_s04);
		valueAbility = 0.1f * (1 + CalculateAttributeValue(sp));
		sp = thePlayer.GetAttributeValue('bonus_focus_gain');
		valueAbility += CalculateAttributeValue(sp);
		
		if(thePlayer.HasBuff(EET_Mutation7Buff))
			valueAbility *= 2;
		else if(thePlayer.HasBuff(EET_Mutation7Debuff))
			valueAbility /= 2;
		
		valueStr = FloatToStringPrec(valueAbility,2);
	}
	else if (varKey == 'attack_power_levelup_bonus') //modSigns
	{
		sp = GetWitcherPlayer().abilityManager.GetAttributeValueUnsafe('attack_power');
		valueAbility = sp.valueAdditive;
		valueStr = NoTrailZeros(RoundMath(valueAbility));
	}
	else if (varKey == 'crossbow_adrenaline_gain') //modSigns
	{
		valueAbility = 0;
		if ( thePlayer.CanUseSkill(S_Perk_02) )
		{				
			//sp = GetWitcherPlayer().GetSkillAttributeValue(S_Perk_02, 'focus_gain', false, true);
			//valueAbility = CalculateAttributeValue(sp);
			sp = thePlayer.GetAttributeValue('focus_gain');
			if ( thePlayer.CanUseSkill(S_Sword_s20) )
				sp += GetWitcherPlayer().GetSkillAttributeValue(S_Sword_s20, 'focus_gain', false, true) * GetWitcherPlayer().GetSkillLevel(S_Sword_s20);
			valueAbility = 0.1f * (1 + CalculateAttributeValue(sp));
		}
		
		if(thePlayer.HasBuff(EET_Mutation7Buff))
			valueAbility *= 2;
		else if(thePlayer.HasBuff(EET_Mutation7Debuff))
			valueAbility /= 2;
		
		valueStr = FloatToStringPrec(valueAbility,2);
	}
	else if (varKey == 'area_nml') 
	{
		if (!thePlayer.HasAbility(varKey))
			locKey = "";
		else
		{
			
			
		}
	}
	else if (varKey == 'area_novigrad') 
	{
		if (!thePlayer.HasAbility(varKey))
			locKey = "";
		else
		{
			
			
		}
	}
	else if (varKey == 'area_skellige') 
	{
		if (!thePlayer.HasAbility(varKey))
			locKey = "";
		else
		{
			
			
		}
	}
	//modSigns: allows using of non-localized text
	final_name = GetLocStringByKeyExt(locKey); if ( final_name == "#" || final_name == "" ) { final_name = locKey; }
	statObject.SetMemberFlashString("name", final_name);
	statObject.SetMemberFlashString("value", valueStr );
	statObject.SetMemberFlashString("tag", tag);
	statObject.SetMemberFlashString("iconTag", iconTag);
	statObject.SetMemberFlashString("itemColor", "Red");
	
	toArray.PushBackFlashObject(statObject);
	
	return statObject;
}

function AddCharacterStatU2(tag : string, varKey:name, locKey:string, iconTag:string, toArray : CScriptedFlashArray, flashMaster:CScriptedFlashValueStorage):CScriptedFlashObject
{
	var curStats:SPlayerOffenseStats;
	var statObject : CScriptedFlashObject;
	var valueStr : string;
	var valueAbility, maxHealth, curHealth : float;
	var sp : SAbilityAttributeValue;
	var final_name : string;
	var item : SItemUniqueId;

	statObject = flashMaster.CreateTempFlashObject();
	
	if ( varKey == 'silver_desc_poinsonchance_mult') 
	{
		valueAbility = 0;
		if (GetWitcherPlayer().GetItemEquippedOnSlot(EES_SilverSword, item))
			valueAbility += CalculateAttributeValue(thePlayer.GetInventory().GetItemAttributeValue(item, 'desc_poinsonchance_mult')); 
		//valueStr = NoTrailZeros(RoundMath(valueAbility * 100)) + " %";
	} 
	else if ( varKey == 'silver_desc_bleedingchance_mult') 
	{
		valueAbility = 0;
		if (GetWitcherPlayer().GetItemEquippedOnSlot(EES_SilverSword, item))
			valueAbility += CalculateAttributeValue(thePlayer.GetInventory().GetItemAttributeValue(item, 'desc_bleedingchance_mult')); 
		//valueStr = NoTrailZeros(RoundMath(valueAbility * 100)) + " %";
		if (GetWitcherPlayer().CanUseSkill(S_Sword_s05))
			valueAbility += CalculateAttributeValue(GetWitcherPlayer().GetSkillAttributeValue(S_Sword_s05, 'sword_s5_chance', false, true)) * GetWitcherPlayer().GetSkillLevel(S_Sword_s05);
	} 
	else if ( varKey == 'silver_desc_burningchance_mult') 
	{
		valueAbility = 0;
		if (GetWitcherPlayer().GetItemEquippedOnSlot(EES_SilverSword, item))
			valueAbility += CalculateAttributeValue(thePlayer.GetInventory().GetItemAttributeValue(item, 'desc_burningchance_mult')); 
		//valueStr = NoTrailZeros(RoundMath(valueAbility * 100)) + " %";
	} 
	else if ( varKey == 'silver_desc_confusionchance_mult') 
	{
		valueAbility = 0;
		if (GetWitcherPlayer().GetItemEquippedOnSlot(EES_SilverSword, item))
			valueAbility += CalculateAttributeValue(thePlayer.GetInventory().GetItemAttributeValue(item, 'desc_confusionchance_mult')); 
		//valueStr = NoTrailZeros(RoundMath(valueAbility * 100)) + " %";
	} 
	else if ( varKey == 'silver_desc_freezingchance_mult') 
	{
		valueAbility = 0;
		if (GetWitcherPlayer().GetItemEquippedOnSlot(EES_SilverSword, item))
			valueAbility += CalculateAttributeValue(thePlayer.GetInventory().GetItemAttributeValue(item, 'desc_freezingchance_mult')); 
		//valueStr = NoTrailZeros(RoundMath(valueAbility * 100)) + " %";
	} 
	else if ( varKey == 'silver_desc_staggerchance_mult') 
	{
		valueAbility = 0;
		if (GetWitcherPlayer().GetItemEquippedOnSlot(EES_SilverSword, item))
			valueAbility += CalculateAttributeValue(thePlayer.GetInventory().GetItemAttributeValue(item, 'desc_staggerchance_mult')); 
		//valueStr = NoTrailZeros(RoundMath(valueAbility * 100)) + " %";
	}
	else if ( varKey == 'steel_desc_poinsonchance_mult') 
	{
		valueAbility = 0;
		if (GetWitcherPlayer().GetItemEquippedOnSlot(EES_SteelSword, item))
			valueAbility += CalculateAttributeValue(thePlayer.GetInventory().GetItemAttributeValue(item, 'desc_poinsonchance_mult')); 
		//valueStr = NoTrailZeros(RoundMath(valueAbility * 100)) + " %";
	} 
	else if ( varKey == 'steel_desc_bleedingchance_mult') 
	{
		valueAbility = 0;
		if (GetWitcherPlayer().GetItemEquippedOnSlot(EES_SteelSword, item))
			valueAbility += CalculateAttributeValue(thePlayer.GetInventory().GetItemAttributeValue(item, 'desc_bleedingchance_mult')); 
		//valueStr = NoTrailZeros(RoundMath(valueAbility * 100)) + " %";
		if (GetWitcherPlayer().CanUseSkill(S_Sword_s05))
			valueAbility += CalculateAttributeValue(GetWitcherPlayer().GetSkillAttributeValue(S_Sword_s05, 'sword_s5_chance', false, true)) * GetWitcherPlayer().GetSkillLevel(S_Sword_s05);
	} 
	else if ( varKey == 'steel_desc_burningchance_mult') 
	{
		valueAbility = 0;
		if (GetWitcherPlayer().GetItemEquippedOnSlot(EES_SteelSword, item))
			valueAbility += CalculateAttributeValue(thePlayer.GetInventory().GetItemAttributeValue(item, 'desc_burningchance_mult')); 
		//valueStr = NoTrailZeros(RoundMath(valueAbility * 100)) + " %";
	} 
	else if ( varKey == 'steel_desc_confusionchance_mult') 
	{
		valueAbility = 0;
		if (GetWitcherPlayer().GetItemEquippedOnSlot(EES_SteelSword, item))
			valueAbility += CalculateAttributeValue(thePlayer.GetInventory().GetItemAttributeValue(item, 'desc_confusionchance_mult')); 
		//valueStr = NoTrailZeros(RoundMath(valueAbility * 100)) + " %";
	} 
	else if ( varKey == 'steel_desc_freezingchance_mult') 
	{
		valueAbility = 0;
		if (GetWitcherPlayer().GetItemEquippedOnSlot(EES_SteelSword, item))
			valueAbility += CalculateAttributeValue(thePlayer.GetInventory().GetItemAttributeValue(item, 'desc_freezingchance_mult')); 
		//valueStr = NoTrailZeros(RoundMath(valueAbility * 100)) + " %";
	} 
	else if ( varKey == 'steel_desc_staggerchance_mult') 
	{
		valueAbility = 0;
		if (GetWitcherPlayer().GetItemEquippedOnSlot(EES_SteelSword, item))
			valueAbility += CalculateAttributeValue(thePlayer.GetInventory().GetItemAttributeValue(item, 'desc_staggerchance_mult')); 
		//valueStr = NoTrailZeros(RoundMath(valueAbility * 100)) + " %";
	}
	//modSigns: Metamorphosis new bonus
	if(GetWitcherPlayer().IsMutationActive(EPMT_Mutation12))
		valueAbility *= MaxF(1.0f, 1.0f + GetWitcherPlayer().Mutation12GetBonus());
	valueStr = NoTrailZeros(RoundMath(valueAbility * 100)) + " %";
	//modSigns: allows using of non-localized text
	final_name = GetLocStringByKeyExt(locKey); if ( final_name == "#" || final_name == "" ) { final_name = locKey; }
	statObject.SetMemberFlashString("name", final_name);
	statObject.SetMemberFlashString("value", valueStr );
	statObject.SetMemberFlashString("tag", tag);
	statObject.SetMemberFlashString("iconTag", iconTag);
	
	toArray.PushBackFlashObject(statObject);
	
	return statObject;
}

function GetEquippedCrossbowDamage():float
{
	//modSigns: reworked
	var curStats:SPlayerOffenseStats;
	if(IsBoltEquipped())
	{
		curStats = GetWitcherPlayer().GetOffenseStatsList();
		return (curStats.crossbowSteelDmg + curStats.crossbowSilverDmg)/2 + curStats.crossbowElementaDmg;
	}
	else
		return 0;
}

//modSigns
function GetCrossbowSteelDmgName() : name
{
	var equippedBolt			: SItemUniqueId;
	var equippedBoltName		: name;
	var primaryStatValue		: float;
	
	GetWitcherPlayer().GetItemEquippedOnSlot(EES_Bolt, equippedBolt);
	if (thePlayer.inv.IsIdValid(equippedBolt))
	{
		equippedBoltName = thePlayer.inv.GetItemName(equippedBolt);
		thePlayer.inv.GetItemStatByName(equippedBoltName, 'PiercingDamage', primaryStatValue);
		if(primaryStatValue > 1)
			return 'PiercingDamage';
		thePlayer.inv.GetItemStatByName(equippedBoltName, 'BludgeoningDamage', primaryStatValue);
		if(primaryStatValue > 1)
			return 'BludgeoningDamage';
	}
	return 'PiercingDamage';
}

function GetCrossbowElementaDmgName() : name
{
	var equippedBolt			: SItemUniqueId;
	var equippedBoltName		: name;
	var elementaStatValue		: float;
	
	GetWitcherPlayer().GetItemEquippedOnSlot(EES_Bolt, equippedBolt);
	if (thePlayer.inv.IsIdValid(equippedBolt))
	{
		equippedBoltName = thePlayer.inv.GetItemName(equippedBolt);
		thePlayer.inv.GetItemStatByName(equippedBoltName, 'FireDamage', elementaStatValue);
		if(elementaStatValue > 0)
			return 'FireDamage';
		thePlayer.inv.GetItemStatByName(equippedBoltName, 'FrostDamage', elementaStatValue);
		if(elementaStatValue > 0)
			return 'FrostDamage';
		thePlayer.inv.GetItemStatByName(equippedBoltName, 'PoisonDamage', elementaStatValue);
		if(elementaStatValue > 0)
			return 'PoisonDamage';
	}
	return '';
}

//modSigns
function IsBoltEquipped() : bool
{
	var equippedBolt			: SItemUniqueId;
	var equippedBoltName		: name;
	
	GetWitcherPlayer().GetItemEquippedOnSlot(EES_Bolt, equippedBolt);
	if (thePlayer.inv.IsIdValid(equippedBolt))
	{
		return true;
	}
	return false;
}
