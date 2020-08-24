/***********************************************************************/
/** 	© 2015 CD PROJEKT S.A. All rights reserved.
/** 	THE WITCHER® is a trademark of CD PROJEKT S. A.
/** 	The Witcher game is based on the prose of Andrzej Sapkowski.
/***********************************************************************/



//class W3Effect_YrdenHealthDrain extends W3DamageOverTimeEffect
class W3Effect_YrdenHealthDrain extends CBaseGameplayEffect
{
	//private var hitFxDelay : float;
	
	default effectType = EET_YrdenHealthDrain;
	default isPositive = false;
	default isNeutral = false;
	default isNegative = true;
	
	//modSigns: new skill mechanic - it's no longer drain, but damage bonus,
	//too lazy to rename/create a separate new effect
	
	private var dmgBonus : float;
	private var lastPlayedTime : float;
	
	public function SetDmgBonus(b : float)
	{
		dmgBonus = b;
	}
	
	public function GetDmgBonus() : float
	{
		return dmgBonus;
	}
	
	public function PlayFX()
	{
		if(theGame.GetEngineTimeAsSeconds() - lastPlayedTime > 1.f)
		{
			target.PlayEffect('yrden_shock');
			lastPlayedTime = theGame.GetEngineTimeAsSeconds();
		}
	}
	
	//modSigns: old drain mechanic as it worked in GM before the skill was redone
	//event OnEffectAdded(optional customParams : W3BuffCustomParams)
	//{
	//	super.OnEffectAdded(customParams);
	//	
	//	hitFxDelay = 0;
	//}
	//
	//public function ResetHealthDrainEffect(newVal : SAbilityAttributeValue)
	//{
	//	effectValue = newVal;
	//	timeLeft = initialDuration;
	//}
	//
	//event OnUpdate(dt : float)
	//{
	//	super.OnUpdate(dt);
	//	
	//	hitFxDelay -= dt;
	//	if(hitFxDelay <= 0)
	//	{
	//		hitFxDelay = 0.9 + RandF() / 5;	//0.9-1.1
	//		target.PlayEffect('yrden_shock');
	//	}
	//}
}