// ARM-11: the Viper set (Hearts of Stone) as legacy: with 3 pieces (armor and swords), poison damage
// is cancelled and heals 10% of it per piece (60% at 6), in DMG's ProcessActionDamage
// (damage/pipeline.ws); the armor's +5 maximum toxicity per piece is ARM-01's item stats. 5.x's Golden
// Oriole absorption, which legacy removed, stays until ALCH and comes first. Legacy's text; the set
// shown in item tooltips again (armor/setTooltips.ws). See docs/features/arm.md.

// The share of poison damage that heals, 0 without the set.
@addMethod(W3PlayerWitcher)
function GMViperPoisonHealRate() : float
{
	var min, max : SAbilityAttributeValue;

	if(!IsSetBonusActive(EISB_Viper))
		return 0;
	theGame.GetDefinitionsManager().GetAbilityAttributeValue('setBonusAbilityViper_1', 'per_viper_piece_poison_healing_rate', min, max);
	return CalculateAttributeValue(min) * GetSetPartsEquipped(EIST_Viper);
}
