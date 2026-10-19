// ARM-14: the set bonus descriptions, legacy's texts with live values, set by set with each set's slice
// (ARM-06 Feline, ARM-07 Griffin, ARM-08 Bear, ARM-09 Wolven, ARM-10 Manticore, ARM-11 Viper, ARM-12 Kaer Morhen, ARM-13 Tesham Mutna, ARM-15 Netflix). Legacy's strings override the vanilla keys (same key hash, legacy's ids).
// See docs/features/arm.md.

// 5.x body; changes marked //modSigns.
@replaceMethod(W3PlayerWitcher)
function GetSetBonusTooltipDescription( bonus : EItemSetBonus ) : string
{
	var finalString : string;
	var arrString	: array<string>;
	var dm			: CDefinitionsManagerAccessor;
	var min, max 	: SAbilityAttributeValue;
	var tempString	: string;

	switch( bonus )
	{
		case EISB_Lynx_1:			tempString = "skill_desc_lynx_set_ability1"; break;
		case EISB_Lynx_2:			tempString = "skill_desc_lynx_set_ability2"; break;
		case EISB_Gryphon_1:		tempString = "skill_desc_gryphon_set_ability1"; break;
		case EISB_Gryphon_2:		tempString = "skill_desc_gryphon_set_ability2"; break;
		case EISB_Bear_1:			tempString = "skill_desc_bear_set_ability1"; break;
		case EISB_Bear_2:			tempString = "skill_desc_bear_set_ability2"; break;
		case EISB_Wolf_1:			tempString = "skill_desc_wolf_set_ability1"; break;	//modSigns: ARM-09, legacy's texts (5.x swapped them)
		case EISB_Wolf_2:			tempString = "skill_desc_wolf_set_ability2"; break;	//modSigns
		case EISB_RedWolf_1:		tempString = "skill_desc_red_wolf_set_ability1"; break;
		case EISB_RedWolf_2:		tempString = "skill_desc_red_wolf_set_ability2"; break;

		case EISB_Vampire:			tempString = "skill_desc_vampire_set_ability1"; break;
		case EISB_Netflix_1:		tempString = "skill_desc_netflix_set_ability1"; break;
		case EISB_Netflix_2:		tempString = "skill_desc_netflix_set_ability2"; break;
		case EISB_Viper:			tempString = "skill_desc_viper_set_ability1"; break;	//modSigns: ARM-11
		case EISB_KaerMorhen:		tempString = "skill_desc_kaer_morhen_set_ability1"; break;	//modSigns: ARM-12
		default:					tempString = ""; break;
	}

	dm = theGame.GetDefinitionsManager();

	switch( bonus )
	{
	case EISB_Lynx_1:
		dm.GetAbilityAttributeValue( 'LynxSetBonusEffect', 'lynx_ap_boost', min, max );	//modSigns: ARM-06, legacy's text: attack power per piece, its current total, the maximum
		arrString.PushBack( FloatToString( min.valueAdditive * 100 ) );	//modSigns
		arrString.PushBack( FloatToString( min.valueAdditive * 100 * GetSetPartsEquipped( EIST_Lynx ) ) );	//modSigns
		dm.GetAbilityAttributeValue( 'LynxSetBonusEffect', 'lynx_boost_max', min, max );	//modSigns
		arrString.PushBack( FloatToString( min.valueAdditive * 100 ) );	//modSigns
		finalString = GetLocStringByKeyExtWithParams( tempString,,,arrString );
		break;
	case EISB_Lynx_2:
		//modSigns: removed 5.x's rear attack values (ARM-06: legacy's text has none)
		finalString = GetLocStringByKeyExtWithParams( tempString,,,arrString );
		break;
	case EISB_Gryphon_1:
		dm.GetAbilityAttributeValue( 'GryphonSetBonusEffect', 'gryphon_tier1_bonus', min, max );	//modSigns: ARM-07, legacy's text: the cost cut per piece, its current total, the duration
		arrString.PushBack( FloatToString( min.valueAdditive * 100 ) );	//modSigns
		arrString.PushBack( FloatToString( min.valueAdditive * 100 * GetSetPartsEquipped( EIST_Gryphon ) ) );	//modSigns
		dm.GetAbilityAttributeValue( 'GryphonSetBonusEffect', 'duration', min, max );	//modSigns
		arrString.PushBack( FloatToString( min.valueAdditive ) );	//modSigns
		finalString = GetLocStringByKeyExtWithParams( tempString,,,arrString );
		break;
	case EISB_Gryphon_2:
		dm.GetAbilityAttributeValue( 'GryphonSetBonusYrdenEffect', 'trigger_scale', min, max );
		arrString.PushBack( FloatToString( ( min.valueAdditive - 1 )* 100) );
		//modSigns: removed the regen value (ARM-07: no regen inside Yrden)
		dm.GetAbilityAttributeValue( 'GryphonSetBonusYrdenEffect', 'spell_power', min, max );
		arrString.PushBack( FloatToString( min.valueMultiplicative * 100) );
		dm.GetAbilityAttributeValue( 'GryphonSetBonusYrdenEffect', 'slashing_resistance_perc', min, max );	//modSigns: ARM-07, resistances instead of the damage reduction
		arrString.PushBack( FloatToString( min.valueAdditive * 100) );
		finalString = GetLocStringByKeyExtWithParams( tempString,,,arrString );
		break;
	case EISB_Bear_1:
		dm.GetAbilityAttributeValue( 'setBonusAbilityBear_1', 'bonus_focus_gain', min, max );	//modSigns: ARM-08, legacy's text: adrenaline per piece on hits taken, attack power per piece per point
		arrString.PushBack( NoTrailZeros( min.valueAdditive ) );	//modSigns
		arrString.PushBack( NoTrailZeros( min.valueAdditive * GetSetPartsEquipped( EIST_Bear ) ) );	//modSigns
		dm.GetAbilityAttributeValue( 'setBonusAbilityBear_1', 'attack_power', min, max );	//modSigns
		arrString.PushBack( NoTrailZeros( min.valueMultiplicative * 100 ) );	//modSigns
		arrString.PushBack( NoTrailZeros( min.valueMultiplicative * 100 * GetSetPartsEquipped( EIST_Bear ) ) );	//modSigns
		finalString = GetLocStringByKeyExtWithParams( tempString,,,arrString );
		break;
	case EISB_Bear_2:
		dm.GetAbilityAttributeValue( 'setBonusAbilityBear_2', 'stamina_attack', min, max );	//modSigns: ARM-08, the stamina given back
		arrString.PushBack( NoTrailZeros( min.valueAdditive * 100 ) );	//modSigns
		finalString = GetLocStringByKeyExtWithParams( tempString,,,arrString );	//modSigns
		break;	//modSigns
	case EISB_RedWolf_1:	//modSigns: ARM-10, legacy's text: bomb crit chance and damage per piece and their current totals
		dm.GetAbilityAttributeValue( 'setBonusAbilityRedWolf_1', 'per_redwolf_piece_crit_chance_bonus', min, max );	//modSigns
		arrString.PushBack( NoTrailZeros( CalculateAttributeValue(min) * 100 ) );	//modSigns
		arrString.PushBack( NoTrailZeros( CalculateAttributeValue(min) * 100 * GetSetPartsEquipped( EIST_RedWolf ) ) );	//modSigns
		dm.GetAbilityAttributeValue( 'setBonusAbilityRedWolf_1', 'per_redwolf_piece_crit_power_bonus', min, max );	//modSigns
		arrString.PushBack( NoTrailZeros( CalculateAttributeValue(min) * 100 ) );	//modSigns
		arrString.PushBack( NoTrailZeros( CalculateAttributeValue(min) * 100 * GetSetPartsEquipped( EIST_RedWolf ) ) );	//modSigns
		finalString = GetLocStringByKeyExtWithParams( tempString,,,arrString );	//modSigns
		break;	//modSigns
	case EISB_KaerMorhen:	//modSigns: ARM-12, legacy's text: regen per additional enemy and its maximum
		dm.GetAbilityAttributeValue( 'GMKaerMorhenSetBonusEffect', 'staminaRegen', min, max );	//modSigns
		arrString.PushBack( NoTrailZeros( CalculateAttributeValue(min) ) );	//modSigns
		arrString.PushBack( NoTrailZeros( CalculateAttributeValue(min) * GMKaerMorhenMaxStacks() ) );	//modSigns
		finalString = GetLocStringByKeyExtWithParams( tempString,,,arrString );	//modSigns
		break;	//modSigns
	case EISB_Viper:	//modSigns: ARM-11, legacy's text: the healing share per piece and its current total
		dm.GetAbilityAttributeValue( 'setBonusAbilityViper_1', 'per_viper_piece_poison_healing_rate', min, max );	//modSigns
		arrString.PushBack( NoTrailZeros( CalculateAttributeValue(min) * 100 ) );	//modSigns
		arrString.PushBack( NoTrailZeros( CalculateAttributeValue(min) * 100 * GetSetPartsEquipped( EIST_Viper ) ) );	//modSigns
		finalString = GetLocStringByKeyExtWithParams( tempString,,,arrString );	//modSigns
		break;	//modSigns
	case EISB_Netflix_1:	//modSigns: ARM-15, potions only, per piece of every tier, and the current total
		arrString.PushBack( NoTrailZeros( GMNetflixPotionDurationPerPiece() * 100 ) );	//modSigns
		arrString.PushBack( NoTrailZeros( GMNetflixPotionDurationPerPiece() * 100 * GetSetPartsEquipped( EIST_Netflix ) ) );	//modSigns
		finalString = GetLocStringByKeyExtWithParams( tempString,,,arrString );	//modSigns
		break;	//modSigns
	case EISB_Netflix_2:	//modSigns: ARM-15, sign intensity against enemies inside Yrden
		arrString.PushBack( NoTrailZeros( GMNetflixYrdenIntensityBonus() * 100 ) );	//modSigns
		finalString = GetLocStringByKeyExtWithParams( tempString,,,arrString );	//modSigns
		break;	//modSigns
	case EISB_RedWolf_2:
		dm.GetAbilityAttributeValue( 'setBonusAbilityRedWolf_2', 'amount', min, max );
		arrString.PushBack( FloatToString( min.valueAdditive ) );
		finalString = GetLocStringByKeyExtWithParams( tempString,,,arrString );
		break;
	case EISB_Vampire:
		dm.GetAbilityAttributeValue( 'setBonusAbilityVampire', 'life_percent', min, max );
		arrString.PushBack( FloatToString( min.valueAdditive ) );
		arrString.PushBack( FloatToString( min.valueAdditive * GetSetPartsEquipped( EIST_Vampire ) ) );	//modSigns: ARM-13, legacy's text (string 2110992430)
		finalString = GetLocStringByKeyExtWithParams( tempString,,,arrString );
		break;
	
	case EISB_Wolf_1:
		dm.GetAbilityAttributeValue( 'SetBonusAbilityWolf_1', 'per_piece_oil_bonus', min, max );	//modSigns: ARM-09, legacy's text: the oil bonus per piece and its current total
		arrString.PushBack( RoundMath( CalculateAttributeValue(min) * 100 ) );	//modSigns
		arrString.PushBack( RoundMath( CalculateAttributeValue(min) * 100 * GetSetPartsEquipped( EIST_Wolf ) ) );	//modSigns
		finalString = GetLocStringByKeyExtWithParams( tempString,,,arrString );	//modSigns
		break;	//modSigns
	case EISB_Wolf_2:	//modSigns: ARM-09, legacy's text: crit chance and damage per oil
		dm.GetAbilityAttributeValue( 'SetBonusAbilityWolf_2', 'per_oil_crit_chance_bonus', min, max );	//modSigns
		arrString.PushBack( NoTrailZeros( CalculateAttributeValue(min) * 100 ) );	//modSigns
		dm.GetAbilityAttributeValue( 'SetBonusAbilityWolf_2', 'per_oil_crit_power_bonus', min, max );	//modSigns
		arrString.PushBack( NoTrailZeros( CalculateAttributeValue(min) * 100 ) );	//modSigns
		finalString = GetLocStringByKeyExtWithParams( tempString,,,arrString );	//modSigns
		break;	//modSigns
	
	default:
		finalString = GetLocStringByKeyExtWithParams( tempString );
	}

	return finalString;
}
