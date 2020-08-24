/***********************************************************************/
/** 	© 2015 CD PROJEKT S.A. All rights reserved.
/** 	THE WITCHER® is a trademark of CD PROJEKT S. A.
/** 	The Witcher game is based on the prose of Andrzej Sapkowski.
/***********************************************************************/




class W3Effect_KnockdownTypeApplicator extends W3ApplicatorEffect
{
	private saved var customEffectValue : SAbilityAttributeValue;		
	private saved var customDuration : float;							
	private saved var customAbilityName : name;							

	default effectType = EET_KnockdownTypeApplicator;
	default isNegative = true;
	default isPositive = false;
	
	
	//modSigns: redone
	event OnEffectAdded(optional customParams : W3BuffCustomParams)
	{
		var appliedType			: EEffectType;
		var sp, abl				: SAbilityAttributeValue;
		var params				: SCustomEffectParams;
		var witcher				: W3PlayerWitcher;
		var rawSP, aardPower	: float;
		var chance, startingChance : float;
		
		if(isOnPlayer)
		{
			thePlayer.OnRangedForceHolster( true, true, false );
		}
		
		//determine sign power: effectValue for environment, power stat for NPCs
		if(effectValue.valueMultiplicative + effectValue.valueAdditive > 0)
			sp = effectValue;
		else
			sp = creatorPowerStat;
		//raw sign power
		rawSP = sp.valueMultiplicative;
		//theGame.witcherLog.AddMessage("Raw sign power: " + rawSP);
		//sign power reduced by point resistance
		aardPower = SignPowerStatToPowerBonus(MaxF(0.0, rawSP - resistancePts/100));
		//theGame.witcherLog.AddMessage("Aard power: " + aardPower);
		//50% base chance and at least 10% chance after chance reduction by prc resistance
		//0% to 100% final chance
		witcher = (W3PlayerWitcher)GetCreator();
		if(witcher)
			startingChance = CalculateAttributeValue(witcher.GetSkillAttributeValue(S_Magic_1, 'starting_knockdown_chance', false, false));
		else
			startingChance = 0.5;
		chance = ClampF(startingChance * (1 + aardPower) * (1 - resistance), 0.1, 1.0);
		
		//Metamorphosis new bonus
		if(witcher && witcher.IsMutationActive(EPMT_Mutation12))
			chance *= MaxF(1.0f, 1.0f + witcher.Mutation12GetBonus());
		
		//theGame.witcherLog.AddMessage("Knockdown chance: " + chance);
		//first we roll for knockdown/stagger
		if(RandF() < chance)
		{
			//now we roll for heavy knockdown
			//base heavy knockdown chance is 15% plus up to 15% from Aard Power skill
			chance = 0.15;
			//theGame.witcherLog.AddMessage("Sign cast: " + witcher.GetCurrentlyCastSign());
			if(witcher && witcher.GetCurrentlyCastSign() == ST_Aard && witcher.CanUseSkill(S_Magic_s12))
			{
				//theGame.witcherLog.AddMessage("Casting aard!");
				abl = witcher.GetSkillAttributeValue(S_Magic_s12, 'heavy_knockdown_chance_bonus', false, false);
				chance += abl.valueMultiplicative * witcher.GetSkillLevel(S_Magic_s12);
			}
			//theGame.witcherLog.AddMessage("Heavy knockdown chance: " + chance);
			if(RandF() < chance)
				appliedType = EET_HeavyKnockdown;
			else
				appliedType = EET_Knockdown;
		}
		else
		{
			//now we roll for long stagger
			chance = 0.66;
			//theGame.witcherLog.AddMessage("Long stagger chance: " + chance);
			if(RandF() < chance)
				appliedType = EET_LongStagger;
			else
				appliedType = EET_Stagger;
		}
		//theGame.witcherLog.AddMessage("Severity: " + appliedType);
		//modify severity: here we check for weak to Aard ability, flying monsters,
		//huge monsters, shields, Quen, immunities, stamina, bosses
		appliedType = ModifyKnockdownSeverity(target, GetCreator(), appliedType);
		//theGame.witcherLog.AddMessage("Modified severity: " + appliedType);
		
		//set up custom effect params
		params.effectType = appliedType;
		params.creator = GetCreator();
		params.sourceName = sourceName;
		params.isSignEffect = isSignEffect;
		params.customPowerStatValue = creatorPowerStat;
		params.customAbilityName = customAbilityName;
		params.duration = customDuration;
		params.effectValue = customEffectValue;	
		
		//apply effect
		target.AddEffectCustom(params);
		
		isActive = true;
		duration = 0;
	}
			
	public function Init(params : SEffectInitInfo)
	{
		customDuration = params.duration;
		customEffectValue = params.customEffectValue;
		customAbilityName = params.customAbilityName;
		
		super.Init(params);
	}
}