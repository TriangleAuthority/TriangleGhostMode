/***********************************************************************/
/** 	© 2015 CD PROJEKT S.A. All rights reserved.
/** 	THE WITCHER® is a trademark of CD PROJEKT S. A.
/** 	The Witcher game is based on the prose of Andrzej Sapkowski.
/***********************************************************************/



class W3Effect_Toxicity extends CBaseGameplayEffect
{
	
	default effectType = EET_Toxicity;
	default attributeName = 'toxicityRegen';
	default isPositive = false;
	default isNeutral = true;
	default isNegative = false;	
		
	
	private saved var dmgTypeName 			: name;							
	private saved var toxThresholdEffect	: int;
	private var delayToNextVFXUpdate		: float;
	
	private var mutation4factor				: float; //modSigns
		
	
	public function CacheSettings()
	{
		dmgTypeName = theGame.params.DAMAGE_NAME_DIRECT;
		
		super.CacheSettings();
	}
	
	
	event OnEffectAdded(optional customParams : W3BuffCustomParams)
	{	
		var witcher : W3PlayerWitcher;
	
		if( !((W3PlayerWitcher)target) )
		{
			LogAssert(false, "W3Effect_Toxicity.OnEffectAdded: effect added on non-CR4Player object - aborting!");
			return false;
		}
		
		witcher = GetWitcherPlayer();
	
		
		if( witcher.GetStatPercents(BCS_Toxicity) >= witcher.GetToxicityDamageThreshold())
			switchCameraEffect = true;
		else
			switchCameraEffect = false;
			
		
		super.OnEffectAdded(customParams);	
	}
	
	
	private var playerHadQuen : bool; //modSigns
	
	event OnUpdate(deltaTime : float)
	{
		var min, max : SAbilityAttributeValue; //modSigns
		var dmg, /*maxStat,*/ toxicity, threshold, drainVal : float;
		//var dmgValue, min, max : SAbilityAttributeValue;
		var currentStateName 	: name;
		var currentThreshold	: int;
	
		super.OnUpdate(deltaTime);
		
		toxicity = GetWitcherPlayer().GetStat(BCS_Toxicity, false) / GetWitcherPlayer().GetStatMax(BCS_Toxicity);
		threshold = GetWitcherPlayer().GetToxicityDamageThreshold();
		
		if( toxicity >= threshold && !isPlayingCameraEffect)
			switchCameraEffect = true;
		else if(toxicity < threshold && isPlayingCameraEffect)
			switchCameraEffect = true;

		
		if( delayToNextVFXUpdate <= 0 )
		{		
			//modSigns begin
			//Quen playing effects on the player breaks toxicity effects
			UpdateHeadEffect(toxThresholdEffect, ToxPrc2EffectIdx(toxicity), GetWitcherPlayer().IsAnyQuenActive() || playerHadQuen);
			delayToNextVFXUpdate = 2;
			playerHadQuen = GetWitcherPlayer().IsAnyQuenActive();
			//modSigns end
		}
		else
		{
			delayToNextVFXUpdate -= deltaTime;
		}
				
		
		if(toxicity >= threshold)
		{
			currentStateName = thePlayer.GetCurrentStateName();
			if(currentStateName != 'Meditation' && currentStateName != 'MeditationWaiting')
			{
				//modSigns: rework
				//theGame.GetDefinitionsManager().GetAbilityAttributeValue(abilityName, dmgTypeName, min, max);	
			
				//if(DamageHitsVitality(dmgTypeName))
				//	maxStat = target.GetStatMax(BCS_Vitality);
				//else
				//	maxStat = target.GetStatMax(BCS_Essence);
				
				//dmgValue = GetAttributeRandomizedValue(min, max);
				//dmg = MaxF(0, deltaTime * ( dmgValue.valueAdditive + (dmgValue.valueMultiplicative * (maxStat + dmgValue.valueBase) ) ));
				dmg = GetWitcherPlayer().GetToxicityDamage();
				dmg = MaxF(0, deltaTime * dmg);
				
				
				
				
				
				
			
				if(dmg > 0)
					effectManager.CacheDamage(dmgTypeName,dmg,NULL,this,deltaTime,true,CPS_Undefined,false);
				else
					LogAssert(false, "W3Effect_Toxicity: should deal damage but deals 0 damage!");
			}
			
			
			if(thePlayer.CanUseSkill(S_Alchemy_s20) && !target.HasBuff(EET_IgnorePain))
				target.AddEffectDefault(EET_IgnorePain, target, 'IgnorePain');
			
			//modSigns: Frenzy
			if(thePlayer.CanUseSkill(S_Alchemy_s16) && !thePlayer.HasAbility(SkillEnumToName(S_Alchemy_s16)))
				thePlayer.AddAbilityMultiple(SkillEnumToName(S_Alchemy_s16), thePlayer.GetSkillLevel(S_Alchemy_s16));
			
			//modSigns: new Euphoria mutation
			if(GetWitcherPlayer().IsMutationActive(EPMT_Mutation10) && !thePlayer.HasBuff(EET_Mutation10) && thePlayer.IsInCombat())
				thePlayer.AddEffectDefault(EET_Mutation10, NULL, "Mutation 10");
		}
		else
		{
			
			target.RemoveBuff(EET_IgnorePain);
			
			//modSigns: Frenzy
			thePlayer.RemoveAbilityAll(SkillEnumToName(S_Alchemy_s16));
			
			//modSigns: new Euphoria mutation
			thePlayer.RemoveBuff(EET_Mutation10);
		}
			
		if(GetWitcherPlayer().GetStat(BCS_Toxicity, true) > 0) //modSigns
		{
			drainVal = deltaTime * (effectValue.valueAdditive + (effectValue.valueMultiplicative * (effectValue.valueBase + target.GetStatMax(BCS_Toxicity)) ) );
			
		
			if(GetWitcherPlayer().IsMutationActive(EPMT_Mutation4)) //modSigns: Toxic Blood mutation
			{
				if(mutation4factor <= 0)
				{
					theGame.GetDefinitionsManager().GetAbilityAttributeValue('Mutation4', 'toxicityRegenFactor', min, max);
					mutation4factor = min.valueAdditive;
				}
				drainVal *= MaxF(0.01, 1 - mutation4factor);
			}
			
			//if(!target.IsInCombat())
			//	drainVal *= 2; //modSigns - removed
				
			effectManager.CacheStatUpdate(BCS_Toxicity, drainVal);
		}
	}
	
	//modSigns begin
	function ToxPrc2EffectIdx(toxPrc : float) : int
	{
		if(toxPrc < 0.25f)		return 0;
		else if(toxPrc < 0.5f)	return 1;
		else if(toxPrc < 0.75f)	return 2;
		else					return 3;
	}
	
	function EffectIdx2EffectName(effectIdx : int) : name
	{
		switch(effectIdx)
		{
			case 0: return 'toxic_000_025';
			case 1: return 'toxic_025_050';
			case 2: return 'toxic_050_075';
			case 3: return 'toxic_075_100';
		}
		return '';
	}
	
	function UpdateHeadEffect( prevEffectIdx : int, nextEffectIdx : int, forceUpdate : bool )
	{
		var prevEffect, nextEffect : name;
		
		if(target.IsEffectActive('invisible') || (prevEffectIdx == nextEffectIdx && !forceUpdate))
			return;
		
		prevEffect = EffectIdx2EffectName(prevEffectIdx);
		nextEffect = EffectIdx2EffectName(nextEffectIdx);
	
		if(prevEffect != '') PlayHeadEffect(prevEffect, true);
		if(nextEffect != '') PlayHeadEffect(nextEffect);
		
		toxThresholdEffect = nextEffectIdx;
	}
	//modSigns end
	
	function PlayHeadEffect( effect : name, optional stop : bool )
	{
		var inv : CInventoryComponent;
		var headIds : array<SItemUniqueId>;
		var headId : SItemUniqueId;
		var head : CItemEntity;
		var i : int;
		
		inv = target.GetInventory();
		headIds = inv.GetItemsByCategory('head');
		
		for ( i = 0; i < headIds.Size(); i+=1 )
		{
			if ( !inv.IsItemMounted( headIds[i] ) )
			{
				continue;
			}
			
			headId = headIds[i];
					
			if(!inv.IsIdValid( headId ))
			{
				LogAssert(false, "W3Effect_Toxicity : Can't find head item");
				return;
			}
			
			head = inv.GetItemEntityUnsafe( headId );
			
			if( !head )
			{
				LogAssert(false, "W3Effect_Toxicity : head item is null");
				return;
			}

			if ( stop )
			{
				head.StopEffect( effect );
			}
			else
			{
				head.PlayEffectSingle( effect );
			}
		}
	}
	
	public function OnLoad(t : CActor, eff : W3EffectManager)
	{
		super.OnLoad(t, eff);
		
		toxThresholdEffect = -1;
	}
	
	event OnEffectRemoved()
	{
		super.OnEffectRemoved();
		
		
		if(/*thePlayer.CanUseSkill(S_Alchemy_s20) &&*/ target.HasBuff(EET_IgnorePain))
			target.RemoveBuff(EET_IgnorePain);
			
		//modSigns: Frenzy
		if(thePlayer.HasAbility(SkillEnumToName(S_Alchemy_s16)))
			thePlayer.RemoveAbilityAll(SkillEnumToName(S_Alchemy_s16));
			
		
		
		
		
		PlayHeadEffect( 'toxic_000_025', true );
		PlayHeadEffect( 'toxic_025_050', true );
		PlayHeadEffect( 'toxic_050_075', true );
		PlayHeadEffect( 'toxic_075_100', true );
		
		PlayHeadEffect( 'toxic_025_000', true );
		PlayHeadEffect( 'toxic_050_025', true );
		PlayHeadEffect( 'toxic_075_050', true );
		PlayHeadEffect( 'toxic_100_075', true );
		
		toxThresholdEffect = 0;
	}
	
	protected function SetEffectValue()
	{
		RecalcEffectValue();
	}
	
	public function RecalcEffectValue()
	{
		var min, max : SAbilityAttributeValue;
		var dm : CDefinitionsManagerAccessor;
	
		if(!IsNameValid(abilityName))
			return;
	
		
		dm = theGame.GetDefinitionsManager();
		dm.GetAbilityAttributeValue(abilityName, attributeName, min, max);
		effectValue = GetAttributeRandomizedValue(min, max);
		
		
		if(thePlayer.CanUseSkill(S_Alchemy_s15))
			effectValue += thePlayer.GetSkillAttributeValue(S_Alchemy_s15, attributeName, false, true) * thePlayer.GetSkillLevel(S_Alchemy_s15);
			
		if(thePlayer.HasAbility('ArmorTypeMediumSetBonusAbility')) //modSigns
		{
			dm.GetAbilityAttributeValue('ArmorTypeMediumSetBonusAbility', 'toxicityRegen', min, max);
			effectValue += min;
		}
		
		if(thePlayer.HasAbility('Runeword 8 Regen'))
			effectValue += thePlayer.GetAbilityAttributeValue('Runeword 8 Regen', 'toxicityRegen');
	}
}
