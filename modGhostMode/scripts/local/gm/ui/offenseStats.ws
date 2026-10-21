// UI-01: the damage numbers behind the character panel, the inventory's stat hovers and the summary
// lines (legacy W3PlayerWitcher.GetOffenseStatsList, rewritten by Ghost Mode). Per sword and attack
// type: attack power, damage per hit against an enemy with no armor or resistance, crit chance, crit
// power (attack power plus the crit damage bonuses) and crit damage, and the expected damage per hit
// (normal and crit weighted by the crit chance), which replaces 1.32's damage per second. The sheathed
// sword's bonuses are read from the item, so each sword shows its own. The crossbow: attack power,
// crit chance, crit damage bonus, the bolt's damage by type and its elemental damage.
// Each term is the one Ghost Mode's formula uses for a hit (damage/formula.ws, damage/pool.ws), each
// skill read from either tree (DU1): Muscle Memory and Strength Training (classic sword_s21, sword_s4 by
// their abilities tagged with the attack; the new tree's sword_s22 and sword_s23 while armed or stacked),
// Precise Blows and Crushing Blows (classic sword_s17, sword_s8 per level; new sword_s24, sword_s25),
// the Feline chain (ARM-06), the Bear set's attack power (ARM-08), Thunderbolt 3, Heft (ENCH-10),
// Euphoria (MUT-09), the Wolven set's oil crit bonuses (ARM-09), sword_dmg_bonus (SWD-07), Strong
// Attack's +50% weapon damage (DMG-04); crossbow: Anatomical Knowledge (sword_s7 / sword_s26), Steady
// Shot (sword_s15 / Cold Blood sword_s34, SKL-06), Cat Eyes' doubled base damage (MUT-11).
// SPlayerOffenseStats is a struct (annotations cannot extend it): Ghost Mode's own struct holds
// legacy's fields, and GetOffenseStatsList fills 5.x's fields from it.
// See docs/features/ui.md.

struct SGMOffenseStats
{
	var steelFastAP : float;
	var steelFastDmg : float;
	var steelFastCritChance : float;
	var steelFastCritAP : float;
	var steelFastCritDmg : float;
	var steelFastDPS : float;

	var steelStrongAP : float;
	var steelStrongDmg : float;
	var steelStrongCritChance : float;
	var steelStrongCritAP : float;
	var steelStrongCritDmg : float;
	var steelStrongDPS : float;

	var silverFastAP : float;
	var silverFastDmg : float;
	var silverFastCritChance : float;
	var silverFastCritAP : float;
	var silverFastCritDmg : float;
	var silverFastDPS : float;

	var silverStrongAP : float;
	var silverStrongDmg : float;
	var silverStrongCritChance : float;
	var silverStrongCritAP : float;
	var silverStrongCritDmg : float;
	var silverStrongDPS : float;

	var crossbowCritChance : float;
	var crossbowSteelDmg : float;
	var crossbowSteelDmgType : name;
	var crossbowSilverDmg : float;
	var crossbowElementaDmgType : name;
	var crossbowElementaDmg : float;
	var crossbowAttackPower : float;
	var crossbowCritDmgBonus : float;
}

// The equipped bolt's physical damage type (legacy GetCrossbowSteelDmgName).
@addMethod(W3PlayerWitcher)
function GMCrossbowSteelDmgName() : name
{
	var bolt : SItemUniqueId;

	if(GetItemEquippedOnSlot(EES_Bolt, bolt))
	{
		if(CalculateAttributeValue(inv.GetItemAttributeValue(bolt, theGame.params.DAMAGE_NAME_PIERCING)) > 1)
			return theGame.params.DAMAGE_NAME_PIERCING;
		if(CalculateAttributeValue(inv.GetItemAttributeValue(bolt, theGame.params.DAMAGE_NAME_BLUDGEONING)) > 1)
			return theGame.params.DAMAGE_NAME_BLUDGEONING;
	}
	return theGame.params.DAMAGE_NAME_PIERCING;
}

// The equipped bolt's elemental damage type, '' if none (legacy GetCrossbowElementaDmgName).
@addMethod(W3PlayerWitcher)
function GMCrossbowElementaDmgName() : name
{
	var bolt : SItemUniqueId;

	if(GetItemEquippedOnSlot(EES_Bolt, bolt))
	{
		if(CalculateAttributeValue(inv.GetItemAttributeValue(bolt, theGame.params.DAMAGE_NAME_FIRE)) > 0)
			return theGame.params.DAMAGE_NAME_FIRE;
		if(CalculateAttributeValue(inv.GetItemAttributeValue(bolt, theGame.params.DAMAGE_NAME_FROST)) > 0)
			return theGame.params.DAMAGE_NAME_FROST;
		if(CalculateAttributeValue(inv.GetItemAttributeValue(bolt, theGame.params.DAMAGE_NAME_POISON)) > 0)
			return theGame.params.DAMAGE_NAME_POISON;
	}
	return '';
}

// The attack power of a melee attack type, as a hit gets it (W3DamageAction.GetPowerStatValue: the
// attack power plus the abilities tagged with the attack's name; W3Action_Attack.GetPowerStatValue:
// Strong Attack's own term and the style attributes) and its conditional terms (GetAttackersPowerMod):
// the Bear set, the Feline chain, the new tree's Muscle Memory while armed and Strength Training's
// stacks. Situational terms (headshots, backstabs, oils against a category, counters) are not shown.
@addMethod(W3PlayerWitcher)
function GMOffenseAttackPower(isHeavy : bool) : SAbilityAttributeValue
{
	var ap : SAbilityAttributeValue;
	var lynx : W3Effect_LynxSetBonus;

	ap = GetPowerStatValue(CPS_AttackPower);
	if(isHeavy)
	{
		ap += GetPowerStatValue(CPS_AttackPower, 'attack_heavy');
		if(CanUseSkill(S_Sword_2))
			ap += GetSkillAttributeValue(S_Sword_2, PowerStatEnumToName(CPS_AttackPower), false, true);
		ap += GetAttributeValue('attack_power_heavy_style');
		ap.valueMultiplicative += GMStrengthTrainingBonus('gm_st_attack_power', GMStrengthTrainingStacks());
	}
	else
	{
		ap += GetPowerStatValue(CPS_AttackPower, 'attack_light');
		ap += GetAttributeValue('attack_power_fast_style');
		if(GMMuscleMemoryArmed())
			ap.valueMultiplicative += GMMuscleMemoryValue('gm_mm_attack_power');
	}
	ap.valueMultiplicative += GMBearSetAttackPower();
	lynx = (W3Effect_LynxSetBonus)GetBuff(EET_LynxSetBonus);
	if(lynx)
		ap.valueMultiplicative += lynx.GMGetLynxBonus(isHeavy);
	return ap;
}

// One sword's stats (legacy's steel and silver blocks), into the four fields of each attack type.
@addMethod(W3PlayerWitcher)
function GMOffenseSwordStats(isSilver : bool, out stats : SGMOffenseStats)
{
	var fastAP, fastDmg, fastCritChance, fastCritAP, fastCritDmg, fastDPS, strongAP, strongDmg, strongCritChance, strongCritAP, strongCritDmg, strongDPS : float;
	var sword, other : SItemUniqueId;
	var swordDmg, elemental, critChance, critPower, swordCritChance, swordCritPower, dmgBonus, strongDmgMult, fastMult : float;
	var fastAPv, strongAPv, swordAP, fastCritAPv, strongCritAPv, value : SAbilityAttributeValue;
	var thunder : W3Potion_Thunderbolt;

	if(isSilver)
	{
		GetItemEquippedOnSlot(EES_SilverSword, sword);
		GetItemEquippedOnSlot(EES_SteelSword, other);
	}
	else
	{
		GetItemEquippedOnSlot(EES_SteelSword, sword);
		GetItemEquippedOnSlot(EES_SilverSword, other);
	}

	// general and attack type bonuses
	critChance = CalculateAttributeValue(GetAttributeValue(theGame.params.CRITICAL_HIT_CHANCE));
	critPower = CalculateAttributeValue(GetAttributeValue(theGame.params.CRITICAL_HIT_DAMAGE_BONUS));
	thunder = (W3Potion_Thunderbolt)GetBuff(EET_Thunderbolt);
	if(thunder && thunder.GetBuffLevel() == 3 && GetCurWeather() == EWE_Storm)	// Thunderbolt 3's crit chance in a storm (legacy's list added it to crit power)
		critChance += 1.0f;
	fastAPv = GMOffenseAttackPower(false);
	strongAPv = GMOffenseAttackPower(true);
	value = GetSkillAttributeValue(S_Sword_2, 'heavy_attack_dmg_boost', false, true);
	strongDmgMult = value.valueMultiplicative + GMStrengthTrainingBonus('gm_st_weapon_damage', GMStrengthTrainingStacks());
	if(GMMuscleMemoryArmed())
		fastMult = GMMuscleMemoryValue('gm_mm_total_damage');
	if(HasGlyphwordActive('Glyphword 4 _Stats'))	// Heft (ENCH-10)
		dmgBonus += GMHeftDamageBonusValue();

	// the sword's own bonuses: added on hold, so read from the item while it is sheathed; the drawn
	// other sword's taken back off
	if(inv.IsIdValid(sword))
	{
		if(isSilver)
		{
			swordDmg = GetTotalWeaponDamage(sword, theGame.params.DAMAGE_NAME_SILVER, GetInvalidUniqueId());
		}
		else
		{
			swordDmg = GetTotalWeaponDamage(sword, theGame.params.DAMAGE_NAME_SLASHING, GetInvalidUniqueId());
			swordDmg += GetTotalWeaponDamage(sword, theGame.params.DAMAGE_NAME_PIERCING, GetInvalidUniqueId());
			swordDmg += GetTotalWeaponDamage(sword, theGame.params.DAMAGE_NAME_BLUDGEONING, GetInvalidUniqueId());
		}
		elemental = CalculateAttributeValue(inv.GetItemAttributeValue(sword, theGame.params.DAMAGE_NAME_FIRE));
		elemental += CalculateAttributeValue(inv.GetItemAttributeValue(sword, theGame.params.DAMAGE_NAME_FROST));
		elemental += CalculateAttributeValue(inv.GetItemAttributeValue(sword, theGame.params.DAMAGE_NAME_POISON));
		if(!inv.IsItemHeld(sword))
		{
			swordCritChance += CalculateAttributeValue(inv.GetItemAttributeValue(sword, theGame.params.CRITICAL_HIT_CHANCE));
			swordCritPower += CalculateAttributeValue(inv.GetItemAttributeValue(sword, theGame.params.CRITICAL_HIT_DAMAGE_BONUS));
			swordAP += inv.GetItemAttributeValue(sword, 'attack_power');
			dmgBonus += CalculateAttributeValue(inv.GetItemAttributeValue(sword, 'sword_dmg_bonus'));	// SWD-07 (held: in Geralt's attribute below)
		}
		swordCritChance += inv.GMOilWolfCritBonus(sword, 'per_oil_crit_chance_bonus');	// ARM-09, the Wolven set's tier 2
		swordCritPower += inv.GMOilWolfCritBonus(sword, 'per_oil_crit_power_bonus');
	}
	if(inv.IsIdValid(other) && inv.IsItemHeld(other))
	{
		swordCritChance -= CalculateAttributeValue(inv.GetItemAttributeValue(other, theGame.params.CRITICAL_HIT_CHANCE));
		swordCritPower -= CalculateAttributeValue(inv.GetItemAttributeValue(other, theGame.params.CRITICAL_HIT_DAMAGE_BONUS));
		swordAP -= inv.GetItemAttributeValue(other, 'attack_power');
		dmgBonus -= CalculateAttributeValue(inv.GetItemAttributeValue(other, 'sword_dmg_bonus'));
	}
	dmgBonus += CalculateAttributeValue(GetAttributeValue('sword_dmg_bonus'));
	if(IsMutationActive(EPMT_Mutation10) && HasBuff(EET_Mutation10))	// Euphoria (MUT-09)
		swordDmg += GMGetToxicityDamage();

	fastAPv += swordAP;
	strongAPv += swordAP;
	fastCritAPv = fastAPv;
	fastCritAPv.valueMultiplicative += critPower + swordCritPower + GMOffenseBlowsCritPower(false);
	strongCritAPv = strongAPv;
	strongCritAPv.valueMultiplicative += critPower + swordCritPower + GMOffenseBlowsCritPower(true);

	fastAP = fastAPv.valueMultiplicative;
	strongAP = strongAPv.valueMultiplicative;
	fastCritAP = fastCritAPv.valueMultiplicative;
	strongCritAP = strongCritAPv.valueMultiplicative;
	fastCritChance = (critChance + swordCritChance + GMOffenseBlowsCritChance(false)) * 100;
	strongCritChance = (critChance + swordCritChance + GMOffenseBlowsCritChance(true)) * 100;
	if(swordDmg != 0)
	{
		fastDmg = (((swordDmg + elemental) * (1 + dmgBonus) + fastAPv.valueBase) * fastAPv.valueMultiplicative + fastAPv.valueAdditive) * (1 + fastMult);
		fastCritDmg = (((swordDmg + elemental) * (1 + dmgBonus) + fastCritAPv.valueBase) * fastCritAPv.valueMultiplicative + fastCritAPv.valueAdditive) * (1 + fastMult);
		fastDPS = fastDmg * (1 - ClampF(fastCritChance / 100, 0, 1)) + fastCritDmg * ClampF(fastCritChance / 100, 0, 1);
		strongDmg = ((swordDmg + elemental) * (1 + strongDmgMult + dmgBonus) + strongAPv.valueBase) * strongAPv.valueMultiplicative + strongAPv.valueAdditive;
		strongCritDmg = ((swordDmg + elemental) * (1 + strongDmgMult + dmgBonus) + strongCritAPv.valueBase) * strongCritAPv.valueMultiplicative + strongCritAPv.valueAdditive;
		strongDPS = strongDmg * (1 - ClampF(strongCritChance / 100, 0, 1)) + strongCritDmg * ClampF(strongCritChance / 100, 0, 1);
	}

	if(isSilver)
	{
		stats.silverFastAP = fastAP;			stats.silverStrongAP = strongAP;
		stats.silverFastDmg = fastDmg;			stats.silverStrongDmg = strongDmg;
		stats.silverFastCritChance = fastCritChance;	stats.silverStrongCritChance = strongCritChance;
		stats.silverFastCritAP = fastCritAP;		stats.silverStrongCritAP = strongCritAP;
		stats.silverFastCritDmg = fastCritDmg;		stats.silverStrongCritDmg = strongCritDmg;
		stats.silverFastDPS = fastDPS;			stats.silverStrongDPS = strongDPS;
	}
	else
	{
		stats.steelFastAP = fastAP;			stats.steelStrongAP = strongAP;
		stats.steelFastDmg = fastDmg;			stats.steelStrongDmg = strongDmg;
		stats.steelFastCritChance = fastCritChance;	stats.steelStrongCritChance = strongCritChance;
		stats.steelFastCritAP = fastCritAP;		stats.steelStrongCritAP = strongCritAP;
		stats.steelFastCritDmg = fastCritDmg;		stats.steelStrongCritDmg = strongCritDmg;
		stats.steelFastDPS = fastDPS;			stats.steelStrongDPS = strongDPS;
	}
}

// Precise Blows (fast) and Crushing Blows (strong) of either tree: crit chance and crit damage.
@addMethod(W3PlayerWitcher)
function GMOffenseBlowsCritChance(isHeavy : bool) : float
{
	var skill : ESkill;

	if(isHeavy)
		skill = S_Sword_s08;
	else
		skill = S_Sword_s17;
	if(CanUseSkill(skill))
		return CalculateAttributeValue(GetSkillAttributeValue(skill, theGame.params.CRITICAL_HIT_CHANCE, false, true)) * GetSkillLevel(skill);
	return GMBlowsCritChance(isHeavy);
}

@addMethod(W3PlayerWitcher)
function GMOffenseBlowsCritPower(isHeavy : bool) : float
{
	var skill : ESkill;
	var bonus : float;

	if(isHeavy)
		skill = S_Sword_s08;
	else
		skill = S_Sword_s17;
	if(CanUseSkill(skill))
		bonus = CalculateAttributeValue(GetSkillAttributeValue(skill, theGame.params.CRITICAL_HIT_DAMAGE_BONUS, false, true)) * GetSkillLevel(skill);
	return bonus + GMBlowsCritDamage(isHeavy);
}

// Heft's melee damage bonus (ENCH-10's value, without an action).
function GMHeftDamageBonusValue() : float
{
	var min, max : SAbilityAttributeValue;

	theGame.GetDefinitionsManager().GetAbilityAttributeValue('Glyphword 4 _Stats', 'glyphword4_mod', min, max);
	return CalculateAttributeValue(min);
}

// The whole list (legacy GetOffenseStatsList).
@addMethod(W3PlayerWitcher)
function GMGetOffenseStats() : SGMOffenseStats
{
	var stats : SGMOffenseStats;
	var crossbow, bolt : SItemUniqueId;
	var apCrossbow, value, min, max : SAbilityAttributeValue;
	var boltBonus : float;

	if(!abilityManager || !abilityManager.IsInitialized())
		return stats;

	GMOffenseSwordStats(false, stats);
	GMOffenseSwordStats(true, stats);

	// crossbow (legacy's, redone by Ghost Mode)
	stats.crossbowSteelDmgType = theGame.params.DAMAGE_NAME_PIERCING;
	stats.crossbowElementaDmgType = '';
	if(GetItemEquippedOnSlot(EES_RangedWeapon, crossbow))
	{
		apCrossbow = GetPowerStatValue(CPS_AttackPower) + inv.GetItemAttributeValue(crossbow, PowerStatEnumToName(CPS_AttackPower));
		apCrossbow.valueMultiplicative += GMBearSetAttackPower();	// ARM-08: ranged attacks too
		stats.crossbowAttackPower = apCrossbow.valueMultiplicative;
		stats.crossbowCritChance = GetCriticalHitChance(false, false, NULL, MC_NotSet, true);

		value = GetCriticalHitDamageBonus(crossbow, MC_NotSet, false) + inv.GetItemAttributeValue(crossbow, theGame.params.CRITICAL_HIT_DAMAGE_BONUS);
		value += GMAnatomicalKnowledgeCritDamage();	// SKL-06, either tree
		stats.crossbowCritDmgBonus = CalculateAttributeValue(value);

		if(GetItemEquippedOnSlot(EES_Bolt, bolt))
		{
			stats.crossbowSteelDmgType = GMCrossbowSteelDmgName();
			stats.crossbowSteelDmg = CalculateAttributeValue(inv.GetItemAttributeValue(bolt, stats.crossbowSteelDmgType));
			stats.crossbowSilverDmg = CalculateAttributeValue(inv.GetItemAttributeValue(bolt, theGame.params.DAMAGE_NAME_SILVER));
			stats.crossbowElementaDmgType = GMCrossbowElementaDmgName();
			if(IsNameValid(stats.crossbowElementaDmgType))
				stats.crossbowElementaDmg = CalculateAttributeValue(inv.GetItemAttributeValue(bolt, stats.crossbowElementaDmgType));
		}

		boltBonus = GMSteadyShotDamage();	// SKL-06: Steady Shot (classic sword_s15, new tree Cold Blood sword_s34)
		stats.crossbowSteelDmg += boltBonus;
		stats.crossbowSilverDmg += boltBonus;
		stats.crossbowElementaDmg += boltBonus;

		if(IsMutationActive(EPMT_Mutation9))	// MUT-11: Cat Eyes doubles a bolt's base damage
		{
			theGame.GetDefinitionsManager().GetAbilityAttributeValue('Mutation9', 'mut9_damage', min, max);
			stats.crossbowSteelDmg *= 1 + min.valueMultiplicative;
			stats.crossbowSilverDmg *= 1 + min.valueMultiplicative;
			stats.crossbowElementaDmg *= 1 + min.valueMultiplicative;
		}

		// no additive attack power for bolts (DMG-03)
		stats.crossbowSteelDmg = (stats.crossbowSteelDmg + apCrossbow.valueBase) * apCrossbow.valueMultiplicative;
		stats.crossbowSilverDmg = (stats.crossbowSilverDmg + apCrossbow.valueBase) * apCrossbow.valueMultiplicative;
		stats.crossbowElementaDmg = (stats.crossbowElementaDmg + apCrossbow.valueBase) * apCrossbow.valueMultiplicative;
	}
	return stats;
}

// Legacy's list into 5.x's struct: 5.x's readers (the stats popup, both character menus' summaries,
// the inventory) get legacy's values; the "DPS" fields hold the expected damage per hit (legacy). 5.x's
// own terms (its new-tree perks, Heightened Tolerance, Water Hag's damageIncrease, Runeword 4's overheal,
// perk_2's crossbow attack power, the 1.833 heavy multiplier and the /0.6 and /1.1 attack speeds) are gone
// (DU1). hackMode (5.x's Cat Eyes description) is ignored: the port's description reads no list.
@replaceMethod(W3PlayerWitcher)
function GetOffenseStatsList( optional hackMode : int ) : SPlayerOffenseStats
{
	var playerOffenseStats : SPlayerOffenseStats;	//modSigns
	var gm : SGMOffenseStats;	//modSigns

	gm = GMGetOffenseStats();	//modSigns
	playerOffenseStats.steelFastDmg = gm.steelFastDmg;	//modSigns
	playerOffenseStats.steelFastCritChance = gm.steelFastCritChance;	//modSigns
	playerOffenseStats.steelFastCritDmg = gm.steelFastCritDmg;	//modSigns
	playerOffenseStats.steelFastDPS = gm.steelFastDPS;	//modSigns
	playerOffenseStats.steelStrongDmg = gm.steelStrongDmg;	//modSigns
	playerOffenseStats.steelStrongCritChance = gm.steelStrongCritChance;	//modSigns
	playerOffenseStats.steelStrongCritDmg = gm.steelStrongCritDmg;	//modSigns
	playerOffenseStats.steelStrongDPS = gm.steelStrongDPS;	//modSigns
	playerOffenseStats.silverFastDmg = gm.silverFastDmg;	//modSigns
	playerOffenseStats.silverFastCritChance = gm.silverFastCritChance;	//modSigns
	playerOffenseStats.silverFastCritDmg = gm.silverFastCritDmg;	//modSigns
	playerOffenseStats.silverFastDPS = gm.silverFastDPS;	//modSigns
	playerOffenseStats.silverStrongDmg = gm.silverStrongDmg;	//modSigns
	playerOffenseStats.silverStrongCritChance = gm.silverStrongCritChance;	//modSigns
	playerOffenseStats.silverStrongCritDmg = gm.silverStrongCritDmg;	//modSigns
	playerOffenseStats.silverStrongDPS = gm.silverStrongDPS;	//modSigns
	playerOffenseStats.crossbowCritChance = gm.crossbowCritChance;	//modSigns
	playerOffenseStats.crossbowSteelDmg = gm.crossbowSteelDmg;	//modSigns
	playerOffenseStats.crossbowSteelDmgType = gm.crossbowSteelDmgType;	//modSigns
	playerOffenseStats.crossbowSilverDmg = gm.crossbowSilverDmg;	//modSigns
	return playerOffenseStats;	//modSigns
}
