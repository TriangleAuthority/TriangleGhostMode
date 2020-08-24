/***********************************************************************/
/** 	© 2015 CD PROJEKT S.A. All rights reserved.
/** 	THE WITCHER® is a trademark of CD PROJEKT S. A.
/** 	The Witcher game is based on the prose of Andrzej Sapkowski.
/***********************************************************************/



//modSigns: boosts existing autoregen effect instead of adding another one
//to avoid conflicts.
class W3Potion_TawnyOwl extends CBaseGameplayEffect
{
	default effectType = EET_TawnyOwl;
	
	//modSigns begin
	//function AddStamina()
	//{
	//	var stamina : float;
	//	var staminaAtt, min, max : SAbilityAttributeValue;
	//	
	//	theGame.GetDefinitionsManager().GetAbilityAttributeValue(abilityName, 'staminaRestore', min, max);
	//	staminaAtt = GetAttributeRandomizedValue(min, max);
	//	stamina = target.GetStatMax(BCS_Stamina) * staminaAtt.valueMultiplicative + staminaAtt.valueAdditive;
	//	target.GainStat(BCS_Stamina, stamina);
	//	
	//	//theGame.witcherLog.AddMessage("stamina += " + stamina); //debug
	//}
	//
	//event OnEffectAdded(optional customParams : W3BuffCustomParams)
	//{
	//	super.OnEffectAdded(customParams);
	//	AddStamina();
	//}
	//
	//public function CumulateWith(effect: CBaseGameplayEffect)
	//{
	//	super.CumulateWith(effect);
	//	AddStamina();
	//}
	//modSigns end
	
	public function OnTimeUpdated(deltaTime : float)
	{
		var currentHour, level : int;
		//var toxicityThreshold : float;
		var freezeTime : bool; //modSigns
		var runeword11Bonus : float; //modSigns
		
		if( isActive && pauseCounters.Size() == 0)
		{
			timeActive += deltaTime;	
			if( duration != -1 )
			{
				//modSigns: logic rewritten
				freezeTime = false;
				
				level = GetBuffLevel();				
				currentHour = GameTimeHours(theGame.GetGameTime());
				if(level > 2 && (currentHour < GetHourForDayPart(EDP_Dawn) || currentHour >= GetHourForDayPart(EDP_Dusk)))
					freezeTime = true;
				
				//if(isOnPlayer && thePlayer.CanUseSkill(S_Alchemy_s04))
				//{
				//	toxicityThreshold = thePlayer.ToxicityThresholdPrcToPts((1 - CalculateAttributeValue( thePlayer.GetSkillAttributeValue(S_Alchemy_s04, 'toxicity_threshold', false, true) ) * thePlayer.GetSkillLevel(S_Alchemy_s04))); //modSigns
				//	if(thePlayer.GetStat(BCS_Toxicity) > toxicityThreshold)
				//	{
				//		freezeTime = true;
				//	}
				//}
				
				if(!freezeTime)
				{
					//modSigns: new Prolongation mechanic
					if(isOnPlayer && thePlayer.HasBuff(EET_Runeword11))
					{
						runeword11Bonus = ((W3Effect_Runeword11)thePlayer.GetBuff(EET_Runeword11)).GetExpirationBonus();
						if(runeword11Bonus > 0)
							timeLeft -= deltaTime * (1 - runeword11Bonus);
					}
					else
						timeLeft -= deltaTime;
				}
					
				if( timeLeft <= 0 )
				{
					isActive = false;		
				}
			}
			OnUpdate(deltaTime);	
		}
	}
}