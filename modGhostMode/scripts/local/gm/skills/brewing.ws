// SKL-13: the Brewing skills, legacy's in both trees (D27, D28, D29, project owner, 2026-10-09). They
// affect potions, not decoctions.
// - Refreshment: each potion dose restores 10% of maximum stamina per level (classic alchemy_s1, the new
//   tree's alchemy_s24 in place of 5.x's High Tolerance; 3 levels).
// - Restoration (alchemy_s2, shared): each potion dose heals 5% of maximum Vitality per level (5.x: 10%).
// - Prolonged Effects (alchemy_s4, in place of 5.x's Side Effects): potion duration +20% per level over 5
//   levels (classic, GM_C_alchemy_s4), +33.3% per level in the new tree; legacy's GlobalPassiveBonus is
//   read here from the skill instead, so it follows the skill's level.
// - Expert Brewer (alchemy_s3, in place of 5.x's Delayed Recovery): potion toxicity -1 point per level over
//   5 levels (classic, GM_C_alchemy_s3), -1.67 per level in the new tree (skills/metabolismBoosts.ws calls
//   GMExpertBrewerCut where a potion's toxicity is read).
// No skill raises the overdose threshold (5.x's Heightened Tolerance on alchemy_s1 is gone), and 5.x's High
// Tolerance (alchemy_s24: more damage taken and crit damage at high toxicity), Delayed Recovery and Side
// Effects are gone. See docs/features/skl.md.

// The Refreshment the player has (classic first); S_SUndefined if none.
@addMethod(W3PlayerWitcher)
function GMRefreshmentSkill() : ESkill
{
	if(CanUseSkill(S_Alchemy_s01))
		return S_Alchemy_s01;
	if(CanUseSkill(S_Alchemy_s24))
		return S_Alchemy_s24;
	return S_SUndefined;
}

// Whether the effect type is a mutagen decoction's.
function GMIsDecoctionEffect(effectType : EEffectType) : bool
{
	return effectType >= EET_Mutagen01 && effectType <= EET_Mutagen28;
}

// A potion's toxicity after Expert Brewer (decoctions unchanged; not below 0).
@addMethod(W3PlayerWitcher)
function GMExpertBrewerCut(effectType : EEffectType, toxicity : float) : float
{
	if(GMIsDecoctionEffect(effectType) || !CanUseSkill(S_Alchemy_s03))
		return toxicity;
	return MaxF(0, toxicity - CalculateAttributeValue(GetSkillAttributeValue(S_Alchemy_s03, 'toxicityReduction', false, false)) * GetSkillLevel(S_Alchemy_s03));
}

// Prolonged Effects' potion duration bonus (0.2 = +20%).
@addMethod(W3PlayerWitcher)
function GMProlongedEffectsBonus() : float
{
	if(!CanUseSkill(S_Alchemy_s04))
		return 0;
	return CalculateAttributeValue(GetSkillAttributeValue(S_Alchemy_s04, 'gm_potion_duration', false, false)) * GetSkillLevel(S_Alchemy_s04);
}

// Refreshment and Restoration after a potion dose (not a decoction).
@addMethod(W3PlayerWitcher)
function GMBrewingAfterDrink()
{
	var skill : ESkill;
	var value : float;

	skill = GMRefreshmentSkill();
	if(skill != S_SUndefined)
	{
		value = ClampF(GMFullMaxStamina() * CalculateAttributeValue(GetSkillAttributeValue(skill, 'stamina_gain_perc', false, true)) * GetSkillLevel(skill), 0, GetStatMax(BCS_Stamina));	// STAM-10: a share of the full max
		GainStat(BCS_Stamina, value);
	}
	if(CanUseSkill(S_Alchemy_s02))
	{
		value = ClampF(GetStatMax(BCS_Vitality) * CalculateAttributeValue(GetSkillAttributeValue(S_Alchemy_s02, 'vitality_gain_perc', false, true)) * GetSkillLevel(S_Alchemy_s02), 0, GetStatMax(BCS_Vitality));
		GainStat(BCS_Vitality, value);
	}
}

// 5.x body; changes marked //modSigns.
@replaceMethod(W3PlayerWitcher)
function GetToxicityDamageThreshold() : float
{
	var ret : float;

	ret = theGame.params.TOXICITY_DAMAGE_THRESHOLD;

	//modSigns: removed Heightened Tolerance (alchemy_s1 is Refreshment; no skill raises the threshold)

	return ret;
}

// 5.x body; changes marked //modSigns.
@replaceMethod(W3PlayerWitcher)
function CalculatePotionDuration(item : SItemUniqueId, isMutagenPotion : bool, optional itemName : name) : float
{
	var duration, skillPassiveMod, mutagenSkillMod : float;
	var val, min, max : SAbilityAttributeValue;


	if(inv.IsIdValid(item))
	{
		duration = CalculateAttributeValue(inv.GetItemAttributeValue(item, 'duration'));
	}
	else
	{
		theGame.GetDefinitionsManager().GetItemAttributeValueNoRandom(itemName, true, 'duration', min, max);
		duration = CalculateAttributeValue(GetAttributeRandomizedValue(min, max));
	}

	skillPassiveMod = CalculateAttributeValue(GetAttributeValue('potion_duration'));

	//modSigns: removed 5.x's Adaptability (alchemy_s14 is Adaptation: decoction toxicity, SKL-16)

	if(isMutagenPotion)	//modSigns: Brewing affects potions, not decoctions (legacy)
		duration = duration * (1 + mutagenSkillMod);	//modSigns
	else	//modSigns
		duration = duration * (1 + skillPassiveMod + GMProlongedEffectsBonus());	//modSigns: Prolonged Effects


	if( !isMutagenPotion && IsSetBonusActive( EISB_Netflix_1 ) )	//modSigns: ARM-15, potions only (DA3)
	{
		duration += duration * GetSetPartsEquipped( EIST_Netflix ) * GMNetflixPotionDurationPerPiece();	//modSigns: every tier's pieces (DA3); the value from the set's ability
	}

	return duration;
}

// 5.x's Delayed Recovery is gone: its toxicity threshold is never reached (the callers check the current
// toxicity against it: the potion duration increase, Mutation 7's stamina rule).
@replaceMethod(W3PlayerWitcher)
function GetAlchemyS03Threshold( optional skillLevel : int ) : float
{
	//modSigns: removed the threshold by level (toxicity_threshold_lvl1 to 3)
	return 2;	//modSigns: Delayed Recovery removed (alchemy_s3 is Expert Brewer)
}

// 5.x's High Tolerance is gone (alchemy_s24 is Refreshment).
@replaceMethod(W3PlayerWitcher)
function AccumulateHeightenedToleranceCritBonus(out attributeValue : SAbilityAttributeValue)
{
	//modSigns: removed High Tolerance's critical hit damage
}

// SKL-13: Refreshment and Restoration after a potion dose; 5.x's Side Effects and Delayed Recovery gone.
// 5.x body; changes marked //modSigns.
@replaceMethod(W3PlayerWitcher)
function DrinkPreparedPotion( slotid : EEquipmentSlots, optional itemId : SItemUniqueId )
{
	var potParams : W3PotionParams;
	var potionParams : SCustomEffectParams;
	var factPotionParams : W3Potion_Fact_Params;
	var adrenaline, hpGainValue, duration, finalPotionToxicity, toxicityOffset, toxicityThreshold : float;
	var ret : EEffectInteract;
	var effectType : EEffectType;
	var item : SItemUniqueId;
	var customAbilityName, factId : name;
	var atts : array<name>;
	var i : int;
	var mutagenParams : W3MutagenBuffCustomParams;
	var buffs : array<CBaseGameplayEffect>;

	
	if(itemId != GetInvalidUniqueId())
		item = itemId;
	else
		item = itemSlots[slotid];

	
	if(!inv.IsIdValid(item))
		return;

	
	if( inv.SingletonItemGetAmmo(item) == 0 )
		return;

	
	inv.GetPotionItemBuffData(item, effectType, customAbilityName);

	
	if( !HasFreeToxicityToDrinkPotion( item, effectType, finalPotionToxicity, toxicityOffset, adrenaline ) )
	{
		return;
	}

	
	if(effectType == EET_Fact)
	{
		inv.GetItemAttributes(item, atts);

		for(i=0; i<atts.Size(); i+=1)
		{
			if(StrBeginsWith(NameToString(atts[i]), "fact_"))
			{
				factId = atts[i];
				break;
			}
		}

		factPotionParams = new W3Potion_Fact_Params in theGame;
		factPotionParams.factName = factId;
		factPotionParams.potionItemName = inv.GetItemName(item);

		potionParams.buffSpecificParams = factPotionParams;
	}
	
	else if(inv.ItemHasTag( item, 'Mutagen' ))
	{
		mutagenParams = new W3MutagenBuffCustomParams in theGame;
		mutagenParams.toxicityOffset = toxicityOffset;
		if( GMMutation12FreeDecoction() )	//modSigns: MUT-13, a free decoction under Metamorphosis (its offset is 0)
		{	//modSigns
			potionParams.sourceName = "Mutation12";	//modSigns
			theGame.MutationHUDFeedback( MFT_PlayOnce );	//modSigns
		}	//modSigns
		mutagenParams.potionItemName = inv.GetItemName(item);
		
		finalPotionToxicity += 0.001f;

		potionParams.buffSpecificParams = mutagenParams;

		//modSigns: removed Euphoria's start on a decoction (MUT-09: only while overdosed)
	}
	
	else
	{
		potParams = new W3PotionParams in theGame;
		potParams.potionItemName = inv.GetItemName(item);

		potionParams.buffSpecificParams = potParams;
	}

	
	duration = CalculatePotionDuration(item, inv.ItemHasTag( item, 'Mutagen' ));

	
	potionParams.effectType = effectType;
	potionParams.creator = this;
	if( potionParams.sourceName != "Mutation12" )	//modSigns: MUT-13
		potionParams.sourceName = "drank_potion";
	potionParams.duration = duration;
	potionParams.customAbilityName = customAbilityName;
	ret = AddEffectCustom(potionParams);

	
	if(factPotionParams)
		delete factPotionParams;

	if(mutagenParams)
		delete mutagenParams;

	
	inv.SingletonItemRemoveAmmo(item);

	
	if(ret == EI_Pass || ret == EI_Override || ret == EI_Cumulate)
	{
		if( finalPotionToxicity > 0.f )
		{
			abilityManager.GainStat(BCS_Toxicity, finalPotionToxicity );
		}

		
		if( CanUseSkill( S_Perk_13 ) && !inv.ItemHasTag( item, 'Mutagen' ) )
		{
			abilityManager.DrainFocus(adrenaline);
		}

		
		if ( CanUseSkill( S_Perk_32 ) )
		{
			abilityManager.DrainFocus(adrenaline);
		}

		if (!IsEffectActive('invisible'))
		{
			PlayEffect('use_potion');
		}

		if ( inv.ItemHasTag( item, 'Mutagen' ) )
		{
			
			theGame.GetGamerProfile().CheckTrialOfGrasses();

			
			SetFailedFundamentalsFirstAchievementCondition(true);
		}

		
		if( !inv.ItemHasTag( item, 'Mutagen' ) )	//modSigns: Refreshment and Restoration, potions only (legacy)
			GMBrewingAfterDrink();	//modSigns
		//modSigns: removed Restoration's 5.x block (in GMBrewingAfterDrink), Side Effects and Delayed Recovery

		theGame.GetGamerProfile().SetStat(ES_ActivePotions, effectManager.GetPotionBuffsCount());
	}

	theTelemetry.LogWithLabel(TE_ELIXIR_USED, inv.GetItemName(item));

	if(ShouldProcessTutorial('TutorialPotionAmmo'))
	{
		FactsAdd("tut_used_potion");
	}
	if ( inv.ItemHasTag( item, 'WivesTears' ) && thePlayer.HasBuff( EET_Drunkenness ) )
	{
		thePlayer.RemoveBuff( EET_Drunkenness );
	}
	SetFailedFundamentalsFirstAchievementCondition(true);
}
