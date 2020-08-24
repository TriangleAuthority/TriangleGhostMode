/***********************************************************************/
/** 	© 2015 CD PROJEKT S.A. All rights reserved.
/** 	THE WITCHER® is a trademark of CD PROJEKT S. A.
/** 	The Witcher game is based on the prose of Andrzej Sapkowski.
/***********************************************************************/


//modSigns: reworked
class W3Mutagen27_Effect extends W3Mutagen_Effect
{
	default effectType = EET_Mutagen27;
	//default dontAddAbilityOnTarget = true;
	//default isPositive = false;
	//default isNeutral = true;
	
	protected var isMutagenEffectActive : bool;
	protected var bonusTimeLeft : float;
	protected var bonusDuration : float;
	protected var dmgWindow : float;
	protected var cachedNumHits : float;
	protected var cachedTime : float;
	
	public function ResetAccumulatedHits()
	{
		cachedNumHits = 0;
		cachedTime = 0;
	}
	
	public function AccumulateHits()
	{
		if(IsBonusActive())
			return;
		
		cachedNumHits += 1;
		
		if(cachedNumHits == 1) //first hit - cache current time and wait
		{
			cachedTime = theGame.GetEngineTimeAsSeconds();
			//theGame.witcherLog.AddMessage("Mutagen27: first hit.");
			return;
		}
		
		//lazy init
		if(dmgWindow <= 0)
		{
			dmgWindow = CalculateAttributeValue(thePlayer.GetAbilityAttributeValue('Mutagen27Effect', 'mutagen27_dmg_window'));
			//theGame.witcherLog.AddMessage("Mutagen27: dmgWindow = " + dmgWindow);
		}
		
		//second hit: check for time window
		if(theGame.GetEngineTimeAsSeconds() - cachedTime <= dmgWindow)
		{
			SetMutagenEffectActive(true);
			//theGame.witcherLog.AddMessage("Second hit: activating.");
			return;
		}
		
		//not inside the window: register the hit as first, cache current time
		cachedNumHits = 1;
		cachedTime = theGame.GetEngineTimeAsSeconds();
		//theGame.witcherLog.AddMessage("Second hit: too late, restarting.");
	}
	
	function SetMutagenEffectActive(a : bool)
	{
		isMutagenEffectActive = a;
		if(isMutagenEffectActive)
		{
			//lazy init
			if(bonusDuration <= 0)
			{
				bonusDuration = CalculateAttributeValue(thePlayer.GetAbilityAttributeValue('Mutagen27Effect', 'mutagen27_bonus_duration'));
				//theGame.witcherLog.AddMessage("Mutagen27: bonusDuration = " + bonusDuration);
			}
			bonusTimeLeft = bonusDuration;
			thePlayer.PlayEffect( 'power' ); // SoundEvent("magic_geralt_healing_oneshot")
		}
		else
		{
			ResetAccumulatedHits();
			//thePlayer.StopEffect( 'power' );
		}
		//ForceUpdateBuffsModule();
	}
	
	/*function ForceUpdateBuffsModule()
	{
		if(IsBonusActive())
		{
			isPositive = true;
			isNeutral = false;
		}
		else
		{
			isPositive = false;
			isNeutral = true;
		}
		((CR4HudModuleBuffs)((CR4ScriptedHud)theGame.GetHud()).GetHudModule("BuffsModule")).ForceUpdate();
	}*/
	
	public function IsBonusActive() : bool
	{
		return isMutagenEffectActive;
	}
	
	public function OnTimeUpdated(dt : float)
	{
		super.OnTimeUpdated(dt);
		
		if(IsBonusActive())
		{
			bonusTimeLeft -= dt;
			if(bonusTimeLeft <= 0)
			{
				SetMutagenEffectActive(false);
			}
		}
	}
	
	public function ReduceDamage(out damageData : W3DamageAction)
	{
		if(IsBonusActive())
		{
			damageData.SetAllProcessedDamageAs(0);
			damageData.SetWasDodged();
			//thePlayer.PlayEffect( 'glyphword_reflection' );
			thePlayer.PlayEffect( 'power_place_quen' );
			thePlayer.SoundEvent("sign_quen_discharge_short");
		}
	}
}