// ALCH-15: the Dimeritium bomb (legacy's, the owner's DL7). Everything in the cloud gets the Dimeritium
// effect (EET_GMDimeritium, 20/30/40 s by the bomb's level; data in gm_alch.xml from gen_alch.py, the
// effect and its icon in gm_effects.xml): on Geralt it blocks every sign; on NPCs it blocks the magic
// abilities (wave, ground slam, spawned arena, fire throw, frost, witchers' sign attacks); magic creatures
// and Wild Hunt minions lose armor and resistances (damage/formula.ws), minions their essence regen; mages
// deal Geralt less damage (damage/pipeline.ws) but keep their magic; the djinn gets no rage while under it.
// The bomb's items no longer block abilities directly (5.x's list, ablMagic included, dropped with legacy's
// data); the cloud's range is smaller (petard_dimeritium_bomb.w2ent, binary edit).
// See docs/features/alch.md.

// Legacy's W3Effect_DimeritiumEffect, as a Ghost Mode effect type.
class W3GMEffect_Dimeritium extends CBaseGameplayEffect
{
	default isPositive = false;
	default isNeutral = false;
	default isNegative = true;
	default effectType = EET_GMDimeritium;

	private var gmIsWildHuntMinion : bool;
	private var gmMonsterCategory : EMonsterCategory;
	private var gmIsMage, gmIsMonster : bool;
	private var gmKindKnown : bool;

	// What the target is (legacy decided it when the effect was added; not saved, so worked out again
	// after a load).
	private function GMFindKind()
	{
		var tmpName : name;
		var tmpBool : bool;

		if(gmKindKnown || !target)
			return;
		gmKindKnown = true;
		theGame.GetMonsterParamsForActor(target, gmMonsterCategory, tmpName, tmpBool, tmpBool, tmpBool);
		gmIsWildHuntMinion = GMIsWildHuntMinion(target);
		gmIsMonster = gmIsWildHuntMinion || gmMonsterCategory == MC_Magicals;
		gmIsMage = target != thePlayer && GMIsDimeritiumMage(target);
	}

	// Mages: their damage to Geralt is cut by this share.
	public function GetDamageReduction() : float
	{
		var min, max : SAbilityAttributeValue;

		GMFindKind();
		if(gmIsMage)
		{
			theGame.GetDefinitionsManager().GetAbilityAttributeValue(abilityName, 'dbomb_dmg_reduction', min, max);
			return min.valueAdditive;
		}
		return 0;
	}

	// Magic creatures and Wild Hunt minions: armor lost.
	public function GetArmorPiercing() : float
	{
		var min, max : SAbilityAttributeValue;

		GMFindKind();
		if(gmIsMonster)
		{
			theGame.GetDefinitionsManager().GetAbilityAttributeValue(abilityName, 'dbomb_armor_piercing', min, max);
			return min.valueAdditive;
		}
		return 0;
	}

	// Magic creatures and Wild Hunt minions: resistance lost.
	public function GetResistReduction() : float
	{
		var min, max : SAbilityAttributeValue;

		GMFindKind();
		if(gmIsMonster)
		{
			theGame.GetDefinitionsManager().GetAbilityAttributeValue(abilityName, 'dbomb_resist_reduction', min, max);
			return min.valueAdditive;
		}
		return 0;
	}

	event OnEffectAdded(optional customParams : W3BuffCustomParams)
	{
		super.OnEffectAdded(customParams);

		GMFindKind();
		if(gmIsWildHuntMinion)
			target.PauseEffects(EET_AutoEssenceRegen, 'dimeritium_effect');
		BlockAbilities(true);
	}

	event OnEffectRemoved()
	{
		GMFindKind();
		if(gmIsWildHuntMinion)
			target.ResumeEffects(EET_AutoEssenceRegen, 'dimeritium_effect');
		BlockAbilities(false);

		super.OnEffectRemoved();
	}

	private final function BlockAbilities(block : bool)
	{
		var ret : bool;

		// Geralt's signs
		if(target == thePlayer)
		{
			ret = thePlayer.BlockSkill(S_Magic_1, block) || ret;
			ret = thePlayer.BlockSkill(S_Magic_2, block) || ret;
			ret = thePlayer.BlockSkill(S_Magic_3, block) || ret;
			ret = thePlayer.BlockSkill(S_Magic_4, block) || ret;
			ret = thePlayer.BlockSkill(S_Magic_5, block) || ret;
			ret = thePlayer.BlockSkill(S_Magic_s01, block) || ret;
			ret = thePlayer.BlockSkill(S_Magic_s02, block) || ret;
			ret = thePlayer.BlockSkill(S_Magic_s03, block) || ret;
			ret = thePlayer.BlockSkill(S_Magic_s04, block) || ret;
			ret = thePlayer.BlockSkill(S_Magic_s05, block) || ret;
			// the new tree's own alternate Igni and Axii (both trees)
			ret = thePlayer.BlockSkill(S_Magic_s28, block) || ret;
			ret = thePlayer.BlockSkill(S_Magic_s31, block) || ret;
		}
		// NPCs' magic abilities
		else
		{
			// elementals (dao, ifrit)
			ret = target.BlockAbility('Wave', block) || ret;
			ret = target.BlockAbility('GroundSlam', block) || ret;
			ret = target.BlockAbility('SpawnArena', block) || ret;
			ret = target.BlockAbility('ThrowFire', block) || ret;
			// Wild Hunt minions
			ret = target.BlockAbility('Frost', block) || ret;
			// witchers
			ret = target.BlockAbility('ablSignAttacks', block) || ret;
		}

		GMFindKind();
		if(gmIsMonster || gmIsMage)
			ret = true;

		if(block && !ret)
		{
			// nothing to block and no weakness: the effect ends
			isActive = false;
		}
		else if(block && ret)
		{
			target.PlayEffect('critical_poison');
		}
		else if(!block)
		{
			target.StopEffect('critical_poison');
		}
	}
}

// Legacy's GetEnemyTypeByAbility (a legacy helper the port does not have) found Wild Hunt minions by
// their abilities; the same abilities, read directly.
function GMIsWildHuntMinion(actor : CActor) : bool
{
	return actor && ( actor.HasAbility('mon_wild_hunt_minionMH') || actor.HasAbility('mon_wild_hunt_minion')
		|| actor.HasAbility('mon_wild_hunt_minion_lesser') || actor.HasAbility('mon_wild_hunt_minion_weak') );
}

// Legacy's mages: human spellcasters by their abilities.
function GMIsDimeritiumMage(actor : CActor) : bool
{
	return actor && ( actor.HasAbility('ablMagic') || actor.HasAbility('SkillSorceress')
		|| actor.HasAbility('SkillMage') || actor.HasAbility('SkillArchmage') );
}

// GetDamageResists' terms (damage/formula.ws): an NPC victim under the effect.
function GMDimeritiumArmorPiercing(victim : CActor) : float
{
	var effect : W3GMEffect_Dimeritium;

	if(!victim || victim == thePlayer || !victim.HasBuff(EET_GMDimeritium))
		return 0;
	effect = (W3GMEffect_Dimeritium)victim.GetBuff(EET_GMDimeritium);
	if(effect)
		return effect.GetArmorPiercing();
	return 0;
}

function GMDimeritiumResistReduction(victim : CActor) : float
{
	var effect : W3GMEffect_Dimeritium;

	if(!victim || victim == thePlayer || !victim.HasBuff(EET_GMDimeritium))
		return 0;
	effect = (W3GMEffect_Dimeritium)victim.GetBuff(EET_GMDimeritium);
	if(effect)
		return effect.GetResistReduction();
	return 0;
}

// GMProcessDamageModification's term (damage/pipeline.ws): a mage under the effect hitting Geralt.
function GMDimeritiumDamageMult(attacker : CActor, victim : CActor) : float
{
	var effect : W3GMEffect_Dimeritium;
	var witcher : W3PlayerWitcher;

	witcher = (W3PlayerWitcher)victim;
	if(!witcher || !attacker || !attacker.HasBuff(EET_GMDimeritium))
		return 1;
	effect = (W3GMEffect_Dimeritium)attacker.GetBuff(EET_GMDimeritium);
	if(effect)
		return 1 - effect.GetDamageReduction();
	return 1;
}

// The effect is negative (legacy added it to the list).
@wrapMethod
function IsNegativeEffectType(type : EEffectType) : bool
{
	if(type == EET_GMDimeritium)
		return true;
	return wrappedMethod(type);
}

// 5.x body; changes marked //modSigns. The affected-targets glow: a target counts when it carries the effect
// (legacy), not when the bomb blocked one of its abilities directly.
@replaceMethod(W3Dimeritium)
function LoopFunction(dt : float)
{
	var skill : ESkill;
	var i, j : int;
	var blocked, isPlayer : bool;
	var actor : CActor;

	super.LoopFunction(dt);


	disabledFxDT -= dt;
	if( disabledFxDT > 0.f )
	{
		return;
	}
	disabledFxDT = DISABLED_FX_CHECK_DELAY;


	//modSigns: removed the check of the bomb's directly blocked abilities on the targets
	blocked = false;
	for(i=0; i<targetsSinceLastCheck.Size(); i+=1)
	{
		actor = (CActor)targetsSinceLastCheck[i];
		if(actor && actor.HasBuff(EET_GMDimeritium))	//modSigns: the Dimeritium effect on the target (legacy)
		{	//modSigns
			blocked = true;	//modSigns
			break;
		}	//modSigns
	}


	if(blocked)
	{
		if(isCluster && IsNameValid(affectedFXCluster))
			PlayEffectInternal(affectedFXCluster);
		else
			PlayEffectInternal(affectedFX);

		RemoveTimer('DisableAffectedFx');
		disableTimerCalled = false;
	}
	else if(!disableTimerCalled)
	{
		disableTimerCalled = true;
		AddTimer('DisableAffectedFx', 0.5);
	}
}

// 5.x body; changes marked //modSigns. Legacy removed the bomb's own override and used W3Petard's (the
// effect's duration replaces level 3's blocks lasting out of the cloud).
@replaceMethod(W3Dimeritium)
function ProcessTargetOutOfArea(entity : CGameplayEntity)
{
	super.ProcessTargetOutOfArea(entity);	//modSigns: W3Petard's (legacy)
	//modSigns: removed 5.x's body (friendly targets unblocked, level 3's blocks for duration_out_of_cloud)
}

// 5.x body; changes marked //modSigns. The djinn under the Dimeritium effect leaves its rage and stays
// weakened (legacy).
@replaceMethod(BTTaskManageDjinnRage)
function Main() : EBTNodeStatus
{
	var l_owner		: CNewNPC = GetNPC();
	
	while ( true )
	{
		if(l_owner.HasBuff(EET_GMDimeritium))	//modSigns: ALCH-15, the Dimeritium bomb (legacy)
		{	//modSigns
			if(m_inRageState)	//modSigns
				RemoveRageState();	//modSigns
			if(!m_inWeakenedState)	//modSigns
				EnterWeakenedState();	//modSigns
			SleepOneFrame();	//modSigns
			continue;	//modSigns: legacy skipped the checks below while the effect lasts
		}	//modSigns
		
		if ( m_inRageState && GetLocalTime() >= m_enterRageTimeStamp + calmDownCooldown )
		{
			RemoveRageState();
		}
		
		if ( !m_inWeakenedState && l_owner.HasBuff( EET_Confusion ) || l_owner.HasBuff( EET_AxiiGuardMe ) )
		{
			RemoveRageState();
			EnterWeakenedState();
		}
		
		if ( m_inWeakenedState && !m_isInYrden && GetLocalTime() >= m_enterWeakendTimeStamp + calmDownCooldown )
			RemoveWeakenedState();
		
		SleepOneFrame();
	}
	
	return BTNS_Active;
}

// 5.x body; changes marked //modSigns. No rage from Igni or Aard, and the weakened state is kept on a
// counter, while the djinn is under the Dimeritium effect (legacy).
@replaceMethod(BTTaskManageDjinnRage)
function OnListenedGameplayEvent( eventName : name ) : bool
{
	var l_owner			: CNewNPC = GetNPC();

	if ( eventName == 'EntersYrden' )
	{
		m_isInYrden = true;
		EnterWeakenedState();
		return true;
	}
	else if ( eventName == 'LeavesYrden' )
	{
		m_isInYrden = false;

		return true;
	}
	else if ( removeWeakenedStateOnCounter && ( eventName == 'LaunchCounterAttack' || eventName == 'HitReactionTaskCompleted' ) )
	{
		if ( !m_isInYrden && !l_owner.HasBuff(EET_GMDimeritium) )	//modSigns: ALCH-15 (legacy)
			RemoveWeakenedState();
		return true;
	}
	else if ( eventName == 'IgniHitReceived' )
	{
		if ( !m_isInYrden && !l_owner.HasBuff( EET_Confusion ) && !l_owner.HasBuff( EET_AxiiGuardMe ) && !l_owner.HasBuff(EET_GMDimeritium) )	//modSigns: ALCH-15 (legacy)
		{
			EnterRageState();
			l_owner.PlayEffectSingle( playFXOnIgniHit );
			l_owner.PlayEffectSingle( playFXOnAardHit );
		}
		return true;
	}
	else if ( eventName == 'AardHitReceived' )
	{
		if ( !m_isInYrden && !l_owner.HasBuff( EET_Confusion ) && !l_owner.HasBuff( EET_AxiiGuardMe ) && !l_owner.HasBuff(EET_GMDimeritium) )	//modSigns: ALCH-15 (legacy)
		{
			EnterRageState();
			l_owner.PlayEffectSingle( playFXOnAardHit );
		}
		return true;
	}
	else if ( eventName == 'Death' )
	{
		l_owner.StopAllEffects();
		return true;
	}

	return false;
}
