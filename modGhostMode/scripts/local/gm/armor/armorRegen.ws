// ARM-03: the armor's stamina regen modifier with STAM-05's option on, legacy's calculation: the pieces'
// staminaRegen_armor_mod (legacy's per-piece values, ARM-01's item stats) plus +11/+2/+3/+4% regen for a
// missing chest, gloves, trousers, boots; the Hearts of Stone glyphwords (Levity, Balance, Heft) no longer
// replace it (their legacy stamina trades are ENCH's). With the option off STAM-05's wrapper returns 0
// (stamina/armorRegenPenalty.ws). See docs/features/arm.md.

// 5.x body; changes marked //modSigns.
@replaceMethod(W3PlayerWitcher)
function CalculatedArmorStaminaRegenBonus() : float
{
	var armorEq, glovesEq, pantsEq, bootsEq : bool;
	var tempItem : SItemUniqueId;
	var staminaRegenVal : float;
	var armorRegenVal : SAbilityAttributeValue;

	//modSigns: removed 5.x's glyphword cases (Levity, Balance, Heft replacing the armor's modifier; legacy)
	armorRegenVal = GetAttributeValue('staminaRegen_armor_mod');	//modSigns: the pieces' modifier always (5.x: only without the glyphwords)
	staminaRegenVal = armorRegenVal.valueMultiplicative;	//modSigns

	armorEq = inv.GetItemEquippedOnSlot( EES_Armor, tempItem );	//modSigns: regen for each missing piece (legacy)
	glovesEq = inv.GetItemEquippedOnSlot( EES_Gloves, tempItem );	//modSigns
	pantsEq = inv.GetItemEquippedOnSlot( EES_Pants, tempItem );	//modSigns
	bootsEq = inv.GetItemEquippedOnSlot( EES_Boots, tempItem );	//modSigns
	if ( !armorEq )	//modSigns
		staminaRegenVal += 0.11;	//modSigns
	if ( !glovesEq )	//modSigns
		staminaRegenVal += 0.02;	//modSigns
	if ( !pantsEq )	//modSigns
		staminaRegenVal += 0.03;	//modSigns
	if ( !bootsEq )	//modSigns
		staminaRegenVal += 0.04;	//modSigns

	return staminaRegenVal;
}
