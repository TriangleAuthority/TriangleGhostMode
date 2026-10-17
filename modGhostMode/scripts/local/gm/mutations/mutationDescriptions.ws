// MUT-14: legacy Ghost Mode's mutation descriptions, with their live values, in both character
// menus (both call GetMutationLocalizedDescription), for all twelve mutations. Strings:
// gm_mutation_desc_<n> (legacy's rows and ids). See docs/features/mut.md.

// Legacy's text for a mutation, "" for anything else (5.x's text is then kept).
function GMMutationDescription(mutationType : EPlayerMutationType) : string
{
	var arrStr : array< string >;
	var dm : CDefinitionsManagerAccessor;
	var min, max, sp : SAbilityAttributeValue;
	var key : name;
	var val : float;

	dm = theGame.GetDefinitionsManager();
	switch(mutationType)
	{
		case EPMT_Mutation1 :	// MUT-02 Conductors of Magic
			dm.GetAbilityAttributeValue('Mutation1', 'dmg_bonus_factor', min, max);
			arrStr.PushBack(NoTrailZeros(RoundMath(100 * min.valueAdditive)));
			key = 'gm_mutation_desc_1';
			break;
		case EPMT_Mutation2 :	// MUT-03 Magic Sensibilities: at the current sign intensity
			sp = GetWitcherPlayer().GetPowerStatValue(CPS_SpellPower);
			arrStr.PushBack(NoTrailZeros(RoundMath(100 * ClampF(GMMutation2CritChance(sp), 0.f, 1.f))));
			arrStr.PushBack(NoTrailZeros(RoundMath(100 * GMMutation2CritDamage(sp))));
			key = 'gm_mutation_desc_2';
			break;
		case EPMT_Mutation6 :	// MUT-04 Piercing Cold: the damage at Aard's current intensity
			dm.GetAbilityAttributeValue('Mutation6', 'full_freeze_chance', min, max);
			arrStr.PushBack(RoundMath(100 * min.valueMultiplicative));
			dm.GetAbilityAttributeValue('Mutation6', 'ForceDamage', min, max);
			val = CalculateAttributeValue(min);
			arrStr.PushBack(RoundMath(val));
			sp = GetWitcherPlayer().GetTotalSignSpellPower(S_Magic_1);
			arrStr.PushBack(RoundMath(val * sp.valueMultiplicative));
			key = 'gm_mutation_desc_6';
			break;
		case EPMT_Mutation7 :	// MUT-07 Adrenaline Rush
			dm.GetAbilityAttributeValue('Mutation7BuffEffect', 'duration', min, max);
			arrStr.PushBack(NoTrailZeros(min.valueAdditive));
			dm.GetAbilityAttributeValue('Mutation7Buff', 'attack_power', min, max);
			arrStr.PushBack(NoTrailZeros(RoundMath(100 * min.valueMultiplicative)));
			dm.GetAbilityAttributeValue('Mutation7DebuffEffect', 'duration', min, max);
			arrStr.PushBack(NoTrailZeros(min.valueAdditive));
			dm.GetAbilityAttributeValue('Mutation7Debuff', 'attack_power', min, max);
			arrStr.PushBack(NoTrailZeros(RoundMath(-100 * min.valueMultiplicative)));
			key = 'gm_mutation_desc_7';
			break;
		case EPMT_Mutation12 :	// MUT-13 Metamorphosis
			dm.GetAbilityAttributeValue('Mutation12', 'maxcap', min, max);
			arrStr.PushBack(NoTrailZeros(min.valueAdditive));
			val = min.valueAdditive;
			dm.GetAbilityAttributeValue('Mutation12', 'mut12bonus', min, max);
			arrStr.PushBack(NoTrailZeros(min.valueAdditive * 100));
			arrStr.PushBack(NoTrailZeros(1 + min.valueAdditive * val));
			key = 'gm_mutation_desc_12';
			break;
		case EPMT_Mutation8 :	// MUT-06 Deadly Counter
			dm.GetAbilityAttributeValue('Mutation8', 'hp_perc_trigger', min, max);
			arrStr.PushBack(NoTrailZeros(100 * min.valueMultiplicative));
			dm.GetAbilityAttributeValue('Mutation8', 'dmg_bonus', min, max);
			arrStr.PushBack(FloatToStringPrec(100 * min.valueMultiplicative, 0));
			arrStr.PushBack(FloatToStringPrec(100 * min.valueMultiplicative * GetWitcherPlayer().GetStatMax(BCS_Focus), 0));
			key = 'gm_mutation_desc_8';
			break;
		case EPMT_Mutation9 :	// MUT-11 Cat Eyes
			dm.GetAbilityAttributeValue('Mutation9', 'mut9_damage', min, max);
			arrStr.PushBack(NoTrailZeros(100 * min.valueMultiplicative));
			dm.GetAbilityAttributeValue('Mutation9', 'health_reduction', min, max);
			arrStr.PushBack(NoTrailZeros(100 * min.valueMultiplicative));
			dm.GetAbilityAttributeValue('Mutation9', 'mut9_slowdown', min, max);
			arrStr.PushBack(NoTrailZeros(100 * min.valueAdditive));
			key = 'gm_mutation_desc_9';
			break;
		case EPMT_Mutation4 :	// MUT-08 Toxic Blood: the acid at the current and the maximum toxicity
			dm.GetAbilityAttributeValue('Mutation4', 'toxicityRegenFactor', min, max);
			arrStr.PushBack(NoTrailZeros(100 * min.valueAdditive));
			dm.GetAbilityAttributeValue('AcidEffect', 'DirectDamage', min, max);
			val = min.valueAdditive;
			arrStr.PushBack(NoTrailZeros(val));
			arrStr.PushBack(NoTrailZeros(RoundMath(val * GetWitcherPlayer().GetStat(BCS_Toxicity))));
			arrStr.PushBack(NoTrailZeros(RoundMath(val * GetWitcherPlayer().GetStatMax(BCS_Toxicity))));
			dm.GetAbilityAttributeValue('AcidEffect', 'duration', min, max);
			arrStr.PushBack(NoTrailZeros(min.valueAdditive));
			dm.GetAbilityAttributeValue('Mutation4BloodDebuff', 'staminaRegen', min, max);
			arrStr.PushBack(NoTrailZeros(AbsF(min.valueMultiplicative) * 100));
			key = 'gm_mutation_desc_4';
			break;
		case EPMT_Mutation10 :	// MUT-09 Euphoria: the drain now and at maximum toxicity
			dm.GetAbilityAttributeValue('Mutation10Effect', 'mutation10_factor', min, max);
			val = min.valueMultiplicative;
			arrStr.PushBack(NoTrailZeros(val));
			arrStr.PushBack(NoTrailZeros(RoundMath(GetWitcherPlayer().GMGetToxicityDamage())));
			dm.GetAbilityAttributeValue('ToxicityEffect', 'DirectDamage', min, max);
			arrStr.PushBack(NoTrailZeros(RoundMath(min.valueMultiplicative * GetWitcherPlayer().GetStatMax(BCS_Vitality) * (1 + val * GetWitcherPlayer().GetStatMax(BCS_Toxicity) / 100.0))));
			key = 'gm_mutation_desc_10';
			break;
		case EPMT_Mutation3 :	// MUT-05 Bloodbath
			dm.GetAbilityAttributeValue('Mutation3', 'attack_power', min, max);
			val = min.valueMultiplicative;
			dm.GetAbilityAttributeValue('Mutation3', 'mutation3_buff_rate_sword', min, max);
			arrStr.PushBack(NoTrailZeros(100 * val * min.valueAdditive));
			dm.GetAbilityAttributeValue('Mutation3', 'mutation3_buff_rate_other', min, max);
			arrStr.PushBack(NoTrailZeros(100 * val * min.valueAdditive));
			dm.GetAbilityAttributeValue('Mutation3', 'mutation3_debuff_rate', min, max);
			arrStr.PushBack(NoTrailZeros(100 * val * min.valueAdditive));
			dm.GetAbilityAttributeValue('Mutation3', 'mutation3_buff_rate_kill', min, max);
			arrStr.PushBack(NoTrailZeros(100 * val * min.valueAdditive));
			dm.GetAbilityAttributeValue('Mutation3', 'mutation3_maxcap', min, max);
			arrStr.PushBack(NoTrailZeros(100 * val * min.valueAdditive));
			key = 'gm_mutation_desc_3';
			break;
		case EPMT_Mutation5 :	// MUT-10 Mutated Skin
			dm.GetAbilityAttributeValue('Mutation5', 'mut5_duration_per_point', min, max);
			arrStr.PushBack(NoTrailZeros(min.valueAdditive));
			arrStr.PushBack(NoTrailZeros(min.valueAdditive * GetWitcherPlayer().GetStatMax(BCS_Focus)));
			arrStr.PushBack(NoTrailZeros(min.valueAdditive));
			key = 'gm_mutation_desc_5';
			break;
		case EPMT_Mutation11 :	// MUT-12 Life Leech: the drain per second at full adrenaline against one enemy
			dm.GetAbilityAttributeValue('Mutation11BuffEffect', 'duration', min, max);
			arrStr.PushBack(NoTrailZeros(min.valueAdditive));
			dm.GetAbilityAttributeValue('Mutation11DebuffEffect', 'duration', min, max);
			arrStr.PushBack(NoTrailZeros(min.valueAdditive));
			arrStr.PushBack(NoTrailZeros(MaxF(1, GetWitcherPlayer().GMMutation11GetBaseStrength()) * GetWitcherPlayer().GetStatMax(BCS_Focus)));
			key = 'gm_mutation_desc_11';
			break;
		default :
			return "";
	}
	return GetLocStringByKeyExtWithParams(key, , , arrStr);
}

@wrapMethod(W3PlayerWitcher)
function GetMutationLocalizedDescription(mutationType : EPlayerMutationType) : string
{
	var vanillaText, gmText : string;

	vanillaText = wrappedMethod(mutationType);
	gmText = GMMutationDescription(mutationType);
	if(gmText != "")
		return gmText;
	return vanillaText;
}
