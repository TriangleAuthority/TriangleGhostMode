/***********************************************************************/
/** 	© 2015 CD PROJEKT S.A. All rights reserved.
/** 	THE WITCHER® is a trademark of CD PROJEKT S. A.
/** 	The Witcher game is based on the prose of Andrzej Sapkowski.
/***********************************************************************/



class W3ConfuseEffectCustomParams extends W3BuffCustomParams
{
	var criticalHitChanceBonus : float;
}

class W3ConfuseEffect extends W3CriticalEffect
{
	private saved var drainStaminaOnExit : bool;
	private var criticalHitBonus : float;

	default criticalStateType 	= ECST_Confusion;
	default effectType 			= EET_Confusion;
	default resistStat 			= CDS_WillRes;
	default drainStaminaOnExit 	= false;
	default attachedHandling 	= ECH_Abort;
	default onHorseHandling 	= ECH_Abort;
		
	default dontAddAbilityOnTarget = true; //modSigns: since the ability contains critical_hit_chance buff for the player and not for the affected NPC
	
	private saved var glyphwordAblAdded : bool;
	
	public function GetCriticalHitChanceBonus() : float
	{
		return criticalHitBonus;
	}
		
	private function CacheCritChanceBonus() //modSigns
	{
		var dm : CDefinitionsManagerAccessor;
		var min, max : SAbilityAttributeValue;
		
		//theGame.witcherLog.AddMessage("abilityName: " + abilityName);
	
		dm = theGame.GetDefinitionsManager();		
		dm.GetAbilityAttributeValue(abilityName, 'critical_hit_chance', min, max);
		criticalHitBonus = CalculateAttributeValue(GetAttributeRandomizedValue(min, max));
		
		if(!isOnPlayer && GetCreator() == thePlayer && isSignEffect)
		{
			if(thePlayer.CanUseSkill(S_Magic_s17))
				criticalHitBonus += CalculateAttributeValue(thePlayer.GetSkillAttributeValue(S_Magic_s17, 'crit_chance_bonus', false, true)) * thePlayer.GetSkillLevel(S_Magic_s17);
		}
	}
	
	private function AddGlyphwordBonuses() //modSigns
	{
		var dm : CDefinitionsManagerAccessor = theGame.GetDefinitionsManager();
		var min, max : SAbilityAttributeValue;
		var count, maxStacks : float;
		
		if(!isOnPlayer && GetCreator() == thePlayer && isSignEffect)
		{
			dm.GetAbilityAttributeValue('Glyphword 14 abl', 'g14_max_stacks', min, max);
			maxStacks = CalculateAttributeValue(min);
			//theGame.witcherLog.AddMessage("maxStacks = " + maxStacks);
			count = thePlayer.GetAbilityCount('Glyphword 14 abl');
			//theGame.witcherLog.AddMessage("count = " + count);
			if(count < maxStacks)
			{
				thePlayer.AddAbility('Glyphword 14 abl', true);
				glyphwordAblAdded = true;
			}
		}
	}
	
	private function RemoveGlyphwordBonuses() //modSigns
	{
		if(glyphwordAblAdded)
			thePlayer.RemoveAbility('Glyphword 14 abl');
	}
	
	event OnEffectAdded(optional customParams : W3BuffCustomParams)
	{
		var params : W3ConfuseEffectCustomParams;
		var npc : CNewNPC;
		
		super.OnEffectAdded(customParams);
		
		if(isOnPlayer)
		{
			thePlayer.HardLockToTarget( false );
		}
		
		
		params = (W3ConfuseEffectCustomParams)customParams;
		if(params)
		{
			criticalHitBonus = params.criticalHitChanceBonus;
		}
		
		//modSigns
		if(criticalHitBonus <= 0)
			CacheCritChanceBonus();
		
		AddGlyphwordBonuses(); //modSigns
		
		npc = (CNewNPC)target;
		
		if(npc)
		{
			
			npc.LowerGuard();
			
			if (npc.IsHorse())
			{
				if( npc.GetHorseComponent().IsDismounted() )
					npc.GetHorseComponent().ResetPanic();
				
				if ( IsSignEffect() &&  npc.IsHorse() )
				{
					npc.SetTemporaryAttitudeGroup('animals_charmed', AGP_Axii);
					npc.SignalGameplayEvent('NoticedObjectReevaluation');
				}
			}
		}
	}
	
	public function CacheSettings()
	{
		super.CacheSettings();
	
		blockedActions.PushBack(EIAB_Signs);
		blockedActions.PushBack(EIAB_DrawWeapon);
		blockedActions.PushBack(EIAB_CallHorse);
		blockedActions.PushBack(EIAB_Fists);
		blockedActions.PushBack(EIAB_Jump);
		blockedActions.PushBack(EIAB_RunAndSprint);
		blockedActions.PushBack(EIAB_ThrowBomb);
		blockedActions.PushBack(EIAB_Crossbow);
		blockedActions.PushBack(EIAB_UsableItem);
		blockedActions.PushBack(EIAB_SwordAttack);
		blockedActions.PushBack(EIAB_Parry);
		blockedActions.PushBack(EIAB_Sprint);
		blockedActions.PushBack(EIAB_Explorations);
		blockedActions.PushBack(EIAB_Counter);
		blockedActions.PushBack(EIAB_LightAttacks);
		blockedActions.PushBack(EIAB_HeavyAttacks);
		blockedActions.PushBack(EIAB_SpecialAttackLight);
		blockedActions.PushBack(EIAB_SpecialAttackHeavy);
		blockedActions.PushBack(EIAB_QuickSlots);
		
		
		
	}
		
	event OnEffectRemoved()
	{
		var npc : CNewNPC;
		super.OnEffectRemoved();
		
		RemoveGlyphwordBonuses(); //modSigns
		
		npc = (CNewNPC)target;
		
		if(npc)
		{
			npc.ResetTemporaryAttitudeGroup(AGP_Axii);
			npc.SignalGameplayEvent('NoticedObjectReevaluation');
		}
		
		if (npc && npc.IsHorse())
			npc.SignalGameplayEvent('WasCharmed');
			
		if(drainStaminaOnExit)
		{
			target.DrainStamina(ESAT_FixedValue, target.GetStat(BCS_Stamina));
		}
	}
	
	public function SetDrainStaminaOnExit()
	{
		drainStaminaOnExit = true;
	}
	
	//modSigns
	protected function CalculateDuration(optional setInitialDuration : bool)
	{
		super.CalculateDuration(setInitialDuration);
		
		if(duration > 0)
			duration = MaxF(3.f,duration);
	}
}