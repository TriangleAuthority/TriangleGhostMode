// W3Effect_Toxicity.OnUpdate, replaced for the mutations' hunks: MUT-08 Toxic Blood's slower toxicity
// decay; MUT-09 Euphoria's start and stop, and its larger overdose drain. ALCH's own changes to this function (legacy's) go into this replacement when ALCH is ported.
// See docs/features/mut.md.

@replaceMethod(W3Effect_Toxicity)
function OnUpdate(deltaTime : float)
{
	var dmg, maxStat, toxicity, threshold, drainVal : float;
	var dmgValue, min, max : SAbilityAttributeValue;
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
		
		
		
		if(toxicity <= 0.0f)		currentThreshold = 0;
		else if(toxicity < 0.25f)	currentThreshold = 1;
		else if(toxicity < 0.5f)	currentThreshold = 2;
		else if(toxicity < 0.75f)	currentThreshold = 3;
		else if(toxicity >= 0.75f)	currentThreshold = 4;

		
		if(  toxThresholdEffect != currentThreshold &&  !target.IsEffectActive('invisible' ) )
		{
			
			
			
			if (toxThresholdEffect < 0) 
				toxThresholdEffect = 0;
			
			switch ( toxThresholdEffect )
			{
				case 0: 
					if (currentThreshold > toxThresholdEffect) 
					{ 
						PlayHeadEffect('toxic_000_025'); 
						toxThresholdEffect += 1; 							
					} 
					break;
				case 1: 
					if (currentThreshold > toxThresholdEffect) 
					{ 
						PlayHeadEffect('toxic_025_050'); 
						toxThresholdEffect += 1; 
					} 
					else 
					{ 
						PlayHeadEffect('toxic_025_000'); 
						toxThresholdEffect -= 1; 
					} 
					break;
				case 2: 
					if (currentThreshold > toxThresholdEffect) 
					{ 
						PlayHeadEffect('toxic_050_075'); 
						toxThresholdEffect += 1; 
					} 
					else 
					{ 
						PlayHeadEffect('toxic_050_025'); 
						toxThresholdEffect -= 1; 
					} 
					break;
				case 3: 
					if (currentThreshold > toxThresholdEffect) 
					{ 
						PlayHeadEffect('toxic_075_100'); 
						toxThresholdEffect += 1; 
					}
					else 
					{ 
						PlayHeadEffect('toxic_075_050'); 
						toxThresholdEffect -= 1; 
					} 
					break;
				case 4: 
					PlayHeadEffect('toxic_100_075'); 
					toxThresholdEffect -= 1; 
					break;
			}
			
			
			
			delayToNextVFXUpdate = 2;
		}		
		
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
			theGame.GetDefinitionsManager().GetAbilityAttributeValue(abilityName, dmgTypeName, min, max);	
		
			if(DamageHitsVitality(dmgTypeName))
				maxStat = target.GetStatMax(BCS_Vitality);
			else
				maxStat = target.GetStatMax(BCS_Essence);
			
			dmgValue = GetAttributeRandomizedValue(min, max);
			dmg = MaxF(0, deltaTime * GetWitcherPlayer().GMGetToxicityDamage());	//modSigns: MUT-09, the same drain (DirectDamage x max Vitality), x Euphoria's factor
			
			
			
			
			
			
		
			if(dmg > 0)
				effectManager.CacheDamage(dmgTypeName,dmg,NULL,this,deltaTime,true,CPS_Undefined,false);
			else
				LogAssert(false, "W3Effect_Toxicity: should deal damage but deals 0 damage!");
		}
		
		
		if(thePlayer.CanUseSkill(S_Alchemy_s20) && !target.HasBuff(EET_IgnorePain))
			target.AddEffectDefault(EET_IgnorePain, target, 'IgnorePain');
		if(GetWitcherPlayer().IsMutationActive(EPMT_Mutation10) && !thePlayer.HasBuff(EET_Mutation10) && thePlayer.IsInCombat())	//modSigns: MUT-09, Euphoria while overdosed in combat
			thePlayer.AddEffectDefault(EET_Mutation10, NULL, "Mutation 10");	//modSigns
	}
	else
	{

		target.RemoveBuff(EET_IgnorePain);
		thePlayer.RemoveBuff(EET_Mutation10);	//modSigns: MUT-09
	}
		
	
	drainVal = deltaTime * (effectValue.valueAdditive + (effectValue.valueMultiplicative * (effectValue.valueBase + target.GetStatMax(BCS_Toxicity)) ) );
	
	
	if(!target.IsInCombat())
		drainVal *= 1.1; 
		
	if(GetWitcherPlayer().IsMutationActive(EPMT_Mutation4))	//modSigns: MUT-08, Toxic Blood's slower decay
		drainVal *= MaxF(0.01, 1 - GMMutation4DecayFactor());	//modSigns
	effectManager.CacheStatUpdate(BCS_Toxicity, drainVal);
}
