/***********************************************************************/
/** 	© 2015 CD PROJEKT S.A. All rights reserved.
/** 	THE WITCHER® is a trademark of CD PROJEKT S. A.
/** 	The Witcher game is based on the prose of Andrzej Sapkowski.
/***********************************************************************/
class W3Effect_Mutation5 extends W3DamageOverTimeEffect //modSigns: redone
{
	default effectType = EET_Mutation5;
	default isPositive = false;
	default isNeutral = false;
	default isNegative = true; //it drains HP, so it should be red
	default resistStat = CDS_None;
	default powerStatType = CPS_Undefined;
	
	function ActivateEffect()
	{
		var focus : float;
		
		theGame.MutationHUDFeedback(MFT_PlayOnce);
		
		focus = target.GetStat(BCS_Focus);
		if(focus >= 3.f)
			target.PlayEffect('mutation_5_stage_03');
		else if(focus >= 2.f)
			target.PlayEffect('mutation_5_stage_02');
		else
			target.PlayEffect('mutation_5_stage_01');
	}
	
	event OnEffectAdded(optional customParams : W3BuffCustomParams)
	{
		super.OnEffectAdded(customParams);
		
		ActivateEffect();
	}
	
	protected function GetSelfInteraction( e : CBaseGameplayEffect) : EEffectInteract
	{
		return EI_Cumulate;
	}
	
	public function CumulateWith(effect: CBaseGameplayEffect)
	{
		var prevDuration, prevDamage : float;
	
		prevDuration = timeLeft;
		prevDamage = effectValue.valueAdditive;
		
		super.CumulateWith(effect);
		
		ActivateEffect();
		
		//redistribute the remaining damage from the previous effect over the new duration
		effectValue.valueAdditive += prevDamage * prevDuration / timeLeft;
		
		//theGame.witcherLog.AddMessage("Mutated skin value total: " + effectValue.valueAdditive * timeLeft); //debug
		//theGame.witcherLog.AddMessage("Mutated skin value/sec: " + effectValue.valueAdditive); //debug
		//theGame.witcherLog.AddMessage("Mutated skin time: " + timeLeft); //debug
	}
	
	var focusDrainPerSec : float;
	
	event OnUpdate(dt : float)
	{
		var min, max : SAbilityAttributeValue;
		
		super.OnUpdate(dt);
		
		//the player has ran out of focus: deal the remaining damage and stop the effect
		if(target.GetStat(BCS_Focus) <= 0.0)
		{
			if(timeLeft > 0.0)
				target.DrainVitality(effectValue.valueAdditive * timeLeft);
			timeLeft = 0.0;
			isActive = false;
		}
		else //drain focus
		{
			if(focusDrainPerSec <= 0.0)
			{
				theGame.GetDefinitionsManager().GetAbilityAttributeValue('Mutation5', 'mut5_duration_per_point', min, max);
				focusDrainPerSec = 1.0 / min.valueAdditive;
			}
			((W3PlayerWitcher)target).DrainFocus(dt * focusDrainPerSec);
		}
	}
}