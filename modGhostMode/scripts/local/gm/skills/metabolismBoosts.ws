// SKL-18: Metabolism Boosts, legacy's in both trees (D49; classic perk_13, the new tree's perk_32, which 5.x
// calls Metabolic Boost): each adrenaline point held cuts a potion's toxicity by 33.4% (cost_reduction),
// and the points are spent when it is drunk; decoctions are not affected, as the descriptions say (5.x:
// perk_13 also cut decoctions, perk_32 10% per level, also off a decoction's toxicity offset, and spent
// the points for decoctions too). The check before drinking counts the cut too (legacy's fix of
// ToxicityLowEnoughToDrinkPotion). W3PlayerWitcher.DrinkPreparedPotion spends the adrenaline returned here.
// See docs/features/skl.md.

// The toxicity left after the cut, and the adrenaline points to spend (0 without the perk or for a
// decoction).
@addMethod(W3PlayerWitcher)
function GMMetabolismBoostsCut(effectType : EEffectType, toxicity : float, out adrenaline : float) : float
{
	var skill : ESkill;
	var costReduction : SAbilityAttributeValue;

	adrenaline = 0;
	if(effectType >= EET_Mutagen01 && effectType <= EET_Mutagen28)
		return toxicity;
	if(CanUseSkill(S_Perk_13))
		skill = S_Perk_13;
	else if(CanUseSkill(S_Perk_32))
		skill = S_Perk_32;
	else
		return toxicity;
	adrenaline = FloorF(GetStat(BCS_Focus));
	costReduction = GetSkillAttributeValue(skill, 'cost_reduction', false, true) * adrenaline;
	return MaxF(0, (toxicity - costReduction.valueBase) * (1 - costReduction.valueMultiplicative) - costReduction.valueAdditive);
}

// 5.x body; changes marked //modSigns.
@replaceMethod(W3PlayerWitcher)
function HasFreeToxicityToDrinkPotion( item : SItemUniqueId, effectType : EEffectType, out finalPotionToxicity : float, out toxicityOffset : float, out adrenaline : float ) : bool
{
	var i : int;
	var maxTox : float;
	//modSigns: removed costReduction, isDecoction


	if( effectType == EET_WhiteHoney )
	{
		return true;
	}


	maxTox = abilityManager.GetStatMax(BCS_Toxicity);
	finalPotionToxicity = CalculateAttributeValue(inv.GetItemAttributeValue(item, 'toxicity'));
	toxicityOffset = CalculateAttributeValue(inv.GetItemAttributeValue(item, 'toxicity_offset'));
	toxicityOffset *= GMAdaptationMult();	//modSigns: SKL-16, Adaptation (legacy)
	if(GMMutation12FreeDecoction())	//modSigns: MUT-13, a free decoction under Metamorphosis
		toxicityOffset = 0;	//modSigns

	finalPotionToxicity = GMExpertBrewerCut(effectType, finalPotionToxicity);	//modSigns: Expert Brewer (SKL-13, legacy), potions only
	finalPotionToxicity = GMMetabolismBoostsCut(effectType, finalPotionToxicity, adrenaline);	//modSigns: Metabolism Boosts in either tree (legacy), not for decoctions
	//modSigns: removed 5.x's perk_13 and perk_32 branches


	if(abilityManager.GetStat(BCS_Toxicity, false) + finalPotionToxicity + toxicityOffset > maxTox )
	{
		return false;
	}

	return true;
}

// 5.x body; changes marked //modSigns.
@replaceMethod(W3PlayerWitcher)
function ToxicityLowEnoughToDrinkPotion( slotid : EEquipmentSlots, optional itemId : SItemUniqueId ) : bool
{
	var item 				: SItemUniqueId;
	var maxTox 				: float;
	var potionToxicity 		: float;
	var toxicityOffset 		: float;
	var effectType 			: EEffectType;
	var customAbilityName 	: name;
	var adrenaline			: float;	//modSigns

	if(itemId != GetInvalidUniqueId())
		item = itemId;
	else
		item = itemSlots[slotid];

	inv.GetPotionItemBuffData(item, effectType, customAbilityName);
	maxTox = abilityManager.GetStatMax(BCS_Toxicity);
	potionToxicity = CalculateAttributeValue(inv.GetItemAttributeValue(item, 'toxicity'));
	potionToxicity = GMExpertBrewerCut(effectType, potionToxicity);	//modSigns: Expert Brewer (SKL-13, legacy), potions only
	potionToxicity = GMMetabolismBoostsCut(effectType, potionToxicity, adrenaline);	//modSigns: Metabolism Boosts counts (legacy)
	toxicityOffset = CalculateAttributeValue(inv.GetItemAttributeValue(item, 'toxicity_offset'));
	toxicityOffset *= GMAdaptationMult();	//modSigns: SKL-16, Adaptation (legacy)
	if(GMMutation12FreeDecoction())	//modSigns: MUT-13, a free decoction under Metamorphosis
		toxicityOffset = 0;	//modSigns

	if(effectType != EET_WhiteHoney)
	{
		if(abilityManager.GetStat(BCS_Toxicity, false) + potionToxicity + toxicityOffset > maxTox )
		{
			return false;
		}
	}

	return true;
}
