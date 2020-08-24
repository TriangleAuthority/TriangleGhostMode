/***********************************************************************/
/** 	© 2015 CD PROJEKT S.A. All rights reserved.
/** 	THE WITCHER® is a trademark of CD PROJEKT S. A.
/** 	The Witcher game is based on the prose of Andrzej Sapkowski.
/***********************************************************************/



class W3BlindnessEffect extends W3CriticalEffect
{
	default criticalStateType 	= ECST_Blindness;
	default effectType 			= EET_Blindness;
	default resistStat 			= CDS_WillRes;
	default attachedHandling 	= ECH_Abort;
	default onHorseHandling 	= ECH_Abort;
	
	default dontAddAbilityOnTarget = true; //modSigns: since the ability contains critical_hit_chance buff for the player and not for the affected NPC
	private var critBonus : float; //modSigns
	
	public function GetCritChanceBonus() : float //modSigns
	{
		return critBonus;
	}
	
	private function CacheCritChanceBonus() //modSigns
	{
		var dm : CDefinitionsManagerAccessor;
		var min, max : SAbilityAttributeValue;
		
		//theGame.witcherLog.AddMessage("abilityName: " + abilityName);
	
		dm = theGame.GetDefinitionsManager();		
		dm.GetAbilityAttributeValue(abilityName, 'critical_hit_chance', min, max);
		critBonus = CalculateAttributeValue(GetAttributeRandomizedValue(min, max));
	}
	
	public function CacheSettings()
	{
		super.CacheSettings();
		blockedActions.PushBack(EIAB_Fists);
		blockedActions.PushBack(EIAB_Jump);
		blockedActions.PushBack(EIAB_RunAndSprint);
		blockedActions.PushBack(EIAB_ThrowBomb);
		blockedActions.PushBack(EIAB_Crossbow);
		blockedActions.PushBack(EIAB_UsableItem);
		blockedActions.PushBack(EIAB_Parry);
		blockedActions.PushBack(EIAB_Sprint);
		blockedActions.PushBack(EIAB_Explorations);
		blockedActions.PushBack(EIAB_Counter);
		blockedActions.PushBack(EIAB_QuickSlots);
		
		
		
		
		
		
		
	}
	
	event OnEffectAdded(optional customParams : W3BuffCustomParams)
	{
		super.OnEffectAdded(customParams);
		
		CacheCritChanceBonus(); //modSigns
		
		if(isOnPlayer)
		{
			thePlayer.HardLockToTarget( false );
		}
	}
}