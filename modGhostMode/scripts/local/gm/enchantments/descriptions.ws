// ENCH-17: the values in the reworked words' descriptions (legacy's GetParamsForRunewordTooltip
// cases). Each word's case comes with its port slice; the others keep 5.x's. The texts are in the
// string tables under the vanilla keys. See docs/features/ench.md.

// Fills the description values of a word Ghost Mode reworked; false for the others.
function GMRunewordTooltipParams(runewordName : name, out i : array<int>, out f : array<float>, out s : array<string>) : bool
{
	var min, max : SAbilityAttributeValue;
	var dm : CDefinitionsManagerAccessor;
	var attackRangeBase, attackRangeExt : CAIAttackRange;

	dm = theGame.GetDefinitionsManager();
	switch(runewordName)
	{
		case 'Runeword 1':	// ENCH-03: Replenishment
			dm.GetAbilityAttributeValue('Runeword 1 _Stats', 'runeword1_fire_dmg', min, max);
			s.PushBack( NoTrailZeros(min.valueMultiplicative * 100) );
			dm.GetAbilityAttributeValue('Runeword 1 _Stats', 'runeword1_yrden_duration', min, max);
			s.PushBack( NoTrailZeros(min.valueAdditive) );
			dm.GetAbilityAttributeValue('Runeword 1 _Stats', 'runeword1_quen_heal', min, max);
			s.PushBack( NoTrailZeros(min.valueMultiplicative * 100) );
			dm.GetAbilityAttributeValue('Runeword 1 _Stats', 'runeword1_confusion_duration', min, max);
			s.PushBack( NoTrailZeros(min.valueAdditive) );
			return true;
		case 'Runeword 2':	// ENCH-04: Severance
			attackRangeBase = theGame.GetAttackRangeForEntity(GetWitcherPlayer(), 'specialattacklight');
			attackRangeExt = theGame.GetAttackRangeForEntity(GetWitcherPlayer(), 'runeword2_light');
			s.PushBack( NoTrailZeros(attackRangeExt.rangeMax - attackRangeBase.rangeMax) );
			attackRangeBase = theGame.GetAttackRangeForEntity(GetWitcherPlayer(), 'slash_long');
			attackRangeExt = theGame.GetAttackRangeForEntity(GetWitcherPlayer(), 'runeword2_heavy');
			s.PushBack( NoTrailZeros(attackRangeExt.rangeMax - attackRangeBase.rangeMax) );
			dm.GetAbilityAttributeValue('Runeword 2 _Stats', 'runeword2_damage_debuff', min, max);
			s.PushBack( NoTrailZeros(CalculateAttributeValue(min) * 100) );
			return true;
		case 'Runeword 4':	// ENCH-05: Invigoration
			dm.GetAbilityAttributeValue('Runeword 4 _Stats', 'dmg_gain_rate', min, max);
			i.PushBack( RoundMath(max.valueMultiplicative) );
			dm.GetAbilityAttributeValue('Runeword 4 _Stats', 'max_bonus', min, max);
			i.PushBack( RoundMath(max.valueMultiplicative * 100) );
			return true;
		case 'Runeword 8':	// ENCH-07: Placation
			dm.GetAbilityAttributeValue('Runeword 8 Regen', 'focus_drain', min, max);
			s.PushBack( NoTrailZeros(min.valueMultiplicative) );
			dm.GetAbilityAttributeValue('Runeword 8 Regen', 'vitalityCombatRegen', min, max);
			s.PushBack( NoTrailZeros(min.valueMultiplicative * 100) );
			dm.GetAbilityAttributeValue('Runeword 8 Regen', 'staminaRegen', min, max);
			s.PushBack( NoTrailZeros(min.valueMultiplicative * 100) );
			dm.GetAbilityAttributeValue('Runeword 8 Regen', 'toxicityRegen', min, max);
			s.PushBack( NoTrailZeros(-1 * min.valueAdditive) );
			return true;
		case 'Runeword 10':	// ENCH-08: Rejuvenation
			dm.GetAbilityAttributeValue('Runeword 10 _Stats', 'health', min, max);
			i.PushBack( RoundMath(min.valueMultiplicative * 100) );
			return true;
		case 'Runeword 11':	// ENCH-09: Prolongation
			dm.GetAbilityAttributeValue('Runeword 11 _Stats', 'duration_gain_rate', min, max);
			s.PushBack( NoTrailZeros(max.valueMultiplicative) );
			dm.GetAbilityAttributeValue('Runeword 11 _Stats', 'max_bonus', min, max);
			s.PushBack( NoTrailZeros(max.valueMultiplicative * 100) );
			return true;
		case 'Runeword 12':	// ENCH-08: Elation
			dm.GetAbilityAttributeValue('Runeword 12 _Stats', 'focus', min, max);
			f.PushBack( min.valueAdditive );
			return true;
		case 'Glyphword 2':	// ENCH-10: Levity, Balance, Heft
		case 'Glyphword 3':
		case 'Glyphword 4':
			if(runewordName == 'Glyphword 2')
				dm.GetAbilityAttributeValue('Glyphword 2 _Stats', 'glyphword2_mod', min, max);
			else if(runewordName == 'Glyphword 3')
				dm.GetAbilityAttributeValue('Glyphword 3 _Stats', 'glyphword3_mod', min, max);
			else
				dm.GetAbilityAttributeValue('Glyphword 4 _Stats', 'glyphword4_mod', min, max);
			i.PushBack( RoundMath( CalculateAttributeValue(min) * 100) );
			i.PushBack( RoundMath( CalculateAttributeValue(min) * 100) );
			return true;
		case 'Glyphword 5':	// ENCH-12: Retribution
			dm.GetAbilityAttributeValue('Glyphword 5 _Stats', 'glyphword5_dmg_boost', min, max);
			i.PushBack( RoundMath(min.valueMultiplicative * 100) );
			return true;
		case 'Glyphword 7':	// ENCH-13: Rotation
			i.PushBack( RoundMath( GMRotationValue('glyphword7_dmg_buff') ) );
			i.PushBack( -1 * RoundMath( GMRotationValue('glyphword7_burnchance_debuff') * 100 ) );
			return true;
		case 'Glyphword 20':	// ENCH-13: Eruption
			dm.GetAbilityAttributeValue('Glyphword 20 _Stats', 'FireDamage', min, max);
			i.PushBack( RoundMath( CalculateAttributeValue(min) ) );
			dm.GetAbilityAttributeValue('Glyphword 20 _Stats', 'radius', min, max);
			i.PushBack( RoundMath( CalculateAttributeValue(min) ) );
			return true;
		case 'Glyphword 10':	// ENCH-14: Usurpation
			dm.GetAbilityAttributeValue('Glyphword 10 abl', 'attack_power', min, max);
			i.PushBack( RoundMath( min.valueMultiplicative * 100 ) );
			dm.GetAbilityAttributeValue('Glyphword 10 abl', 'g10_max_stacks', min, max);
			i.PushBack( RoundMath( i[0] * CalculateAttributeValue(min) ) );
			return true;
		case 'Glyphword 14':	// ENCH-14: Beguilement
			dm.GetAbilityAttributeValue('Glyphword 14 abl', 'critical_hit_chance', min, max);
			i.PushBack( RoundMath( min.valueAdditive * 100 ) );
			dm.GetAbilityAttributeValue('Glyphword 14 abl', 'g14_max_stacks', min, max);
			i.PushBack( RoundMath( i[0] * CalculateAttributeValue(min) ) );
			return true;
		case 'Glyphword 15':	// ENCH-15: Entanglement
			dm.GetAbilityAttributeValue('Glyphword 15 _Stats', 'glyphword15_range', min, max);
			s.PushBack( NoTrailZeros(CalculateAttributeValue(min)) );
			dm.GetAbilityAttributeValue('Glyphword 15 _Stats', 'glyphword15_duration', min, max);
			s.PushBack( NoTrailZeros(CalculateAttributeValue(min)) );
			dm.GetAbilityAttributeValue('Glyphword 15 _Stats', 'glyphword15_slow_cap', min, max);
			s.PushBack( NoTrailZeros(CalculateAttributeValue(min) * 100) );
			return true;
		case 'Glyphword 17':	// ENCH-15: Protection
			dm.GetAbilityAttributeValue('Glyphword 17 _Stats', 'glyphword17_quen_buff', min, max);
			i.PushBack( RoundMath(CalculateAttributeValue(min) * 100) );
			return true;
		default:
			return false;
	}
}

@wrapMethod(CInventoryComponent)
function GetParamsForRunewordTooltip(runewordName : name, out i : array<int>, out f : array<float>, out s : array<string>)
{
	var gi : array<int>;
	var gf : array<float>;
	var gs : array<string>;

	wrappedMethod(runewordName, i, f, s);
	if(GMRunewordTooltipParams(runewordName, gi, gf, gs))
	{
		i = gi;
		f = gf;
		s = gs;
	}
}

// ENCH-17: an item's tooltip shows the item's own stats; the runes and glyphs in its slots are listed
// apart, so their bonuses are taken out of the stat lines (legacy's ExcludeEnhancements, "item
// tooltips show base stats", changelist 104; 5.x adds them in).
@wrapMethod(CInventoryComponent)
function GetItemTooltipAttributes(itemId : SItemUniqueId, attributes : array<name>, out itemStats : array<SAttributeTooltip>, optional respectAttributeOrder : bool)
{
	wrappedMethod(itemId, attributes, itemStats, respectAttributeOrder);
	GMExcludeEnhancementStats(this, itemId, itemStats);
}

function GMExcludeEnhancementStats(inv : CInventoryComponent, itemId : SItemUniqueId, out itemStats : array<SAttributeTooltip>)
{
	var enhancements : array<name>;
	var dm : CDefinitionsManagerAccessor;
	var val, min, max : SAbilityAttributeValue;
	var i, k : int;
	var value : float;

	if(!inv.IsItemWeapon(itemId) && !inv.IsItemAnyArmor(itemId))
		return;
	inv.GetItemEnhancementItems(itemId, enhancements);
	if(enhancements.Size() == 0)
		return;
	dm = theGame.GetDefinitionsManager();
	for(k = itemStats.Size() - 1; k >= 0; k -= 1)
	{
		val = inv.GetItemAttributeValue(itemId, itemStats[k].originName);
		for(i = 0; i < enhancements.Size(); i += 1)
		{
			dm.GetItemAttributeValueNoRandom(enhancements[i], true, itemStats[k].originName, min, max);
			val -= min;
		}
		value = 0;
		if(val.valueBase != 0)
			value = val.valueBase;
		if(val.valueMultiplicative != 0)
			value = val.valueMultiplicative;
		if(val.valueAdditive != 0)
			value = val.valueAdditive;
		if(value == 0)
			itemStats.Erase(k);
		else
			itemStats[k].value = value;
	}
}
