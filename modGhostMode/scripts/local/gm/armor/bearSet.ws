// ARM-08: the Ursine (Bear) set as legacy (DA8; changelist 582-584, 601-602). Tier 1 (3 pieces, any
// tier): a hit taken gives +0.035 adrenaline per piece against SKL-07's loss (defense/processAction.ws);
// +3.5% attack power per piece per whole adrenaline point for melee and ranged attacks (DMG-03's
// GetAttackersPowerMod, damage/formula.ws). Tier 2 (6 grandmaster pieces): a strong attack or Rend that
// deals damage (not dodged, parried or countered) gives back 33.4% of its stamina. 5.x's Quen rules are
// gone (the free recast, the Quen damage boost: skills/quen.ws, ForceFinishQuen, the shield's
// knockdown rule); their effects play for Quen Discharge instead (OnStarted, ShowHitFX).
// Values: setBonusAbilityBear_1/2 in gm_armor_sets.xml. See docs/features/arm.md.

// Tier 1: the adrenaline a hit taken gives back (points).
@addMethod(W3PlayerWitcher)
function GMBearSetHitAdrenaline() : float
{
	var min, max : SAbilityAttributeValue;

	if(!IsSetBonusActive(EISB_Bear_1))
		return 0;
	theGame.GetDefinitionsManager().GetAbilityAttributeValue(GetSetBonusAbility(EISB_Bear_1), 'bonus_focus_gain', min, max);
	return min.valueAdditive * GetSetPartsEquipped(EIST_Bear);
}

// Tier 1: the attack power for melee and ranged attacks, per piece per whole adrenaline point.
@addMethod(W3PlayerWitcher)
function GMBearSetAttackPower() : float
{
	var min, max : SAbilityAttributeValue;

	if(!IsSetBonusActive(EISB_Bear_1))
		return 0;
	theGame.GetDefinitionsManager().GetAbilityAttributeValue(GetSetBonusAbility(EISB_Bear_1), 'attack_power', min, max);
	return min.valueMultiplicative * GetSetPartsEquipped(EIST_Bear) * FloorF(GetStat(BCS_Focus));
}

// Tier 2: the stamina a damaging strong attack or Rend gives back (legacy OnProcessActionPost). The Rend
// charge ratio is read before the wrapped event resets it.
@wrapMethod(W3PlayerWitcher)
function OnProcessActionPost(action : W3DamageAction)
{
	var attackAction : W3Action_Attack;
	var rendRatio, stamCost : float;
	var min, max : SAbilityAttributeValue;

	attackAction = (W3Action_Attack)action;
	rendRatio = GetSpecialAttackTimeRatio();
	wrappedMethod(action);
	if(attackAction && attackAction.IsActionMelee() && IsSetBonusActive(EISB_Bear_2) && attackAction.DealsAnyDamage() && !attackAction.WasDodged() && !attackAction.IsParried() && !attackAction.IsCountered())
	{
		if(GMIsRendAttack(attackAction))
			stamCost = rendRatio * GetStatMax(BCS_Stamina);
		else if(IsHeavyAttack(attackAction.GetAttackName()))
			stamCost = GetStaminaActionCost(ESAT_HeavyAttack, '', 0);
		if(stamCost > 0)
		{
			theGame.GetDefinitionsManager().GetAbilityAttributeValue(GetSetBonusAbility(EISB_Bear_2), 'stamina_attack', min, max);
			GainStat(BCS_Stamina, stamCost * min.valueAdditive);
		}
	}
}

// 5.x body; changes marked //modSigns.
@replaceMethod(W3QuenEntity)
function OnStarted() 
{
	var isAlternate		: bool;
	var witcherOwner	: W3PlayerWitcher;
	
	owner.ChangeAspect( this, S_Magic_s04 );
	isAlternate = IsAlternateCast();
	witcherOwner = owner.GetPlayer();
	
	if(isAlternate)
	{
		
		CreateAttachment( owner.GetActor(), 'quen_sphere' );
		
		if((CPlayer)owner.GetActor())
			GetWitcherPlayer().FailFundamentalsFirstAchievementCondition();
	}
	else
	{
		super.OnStarted();
	}
	
	
	if(owner.GetActor() == thePlayer && ShouldProcessTutorial('TutorialSelectQuen'))
	{
		FactsAdd("tutorial_quen_cast");
	}
	
	if((CPlayer)owner.GetActor())
		GetWitcherPlayer().FailFundamentalsFirstAchievementCondition();
			
	if( isAlternate || !owner.IsPlayer() )
	{
		if( owner.IsPlayer() && GetWitcherPlayer().HasBuff( EET_Mutation11Immortal ) )
		{
			PlayEffect( 'quen_second_life' );
		}
		else
		{
			PlayEffect( effects[1].castEffect );
		}
		
		if( witcherOwner && dischargePercent > 0 )	//modSigns: the Bear set's effect played for Quen Discharge, either tree (legacy; 5.x: the Bear set's second tier)
		{	//modSigns
			PlayEffect( 'default_fx_bear_abl2' );
			//modSigns: removed the Bear set's lasting effect on Geralt
		}	//modSigns
		
		CacheActionBuffsFromSkill();
		GotoState( 'QuenChanneled' );
	}
	else
	{
		PlayEffect( effects[0].castEffect );
		GotoState( 'QuenShield' );
	}
}

// 5.x body; changes marked //modSigns.
@replaceMethod(W3QuenEntity)
function ForceFinishQuen( skipVisuals : bool, optional forceNoBearSetBonus : bool )
{
	var min, max : SAbilityAttributeValue;
	var player : W3PlayerWitcher;
	
	player = owner.GetPlayer();
	
	//modSigns: removed the Bear set's free Quen recast (legacy)
		
	if(IsAlternateCast())
	{
		OnEnded();
		
		if(!skipVisuals)
			owner.GetActor().PlayEffect('hit_electric_quen');
	}
	else
	{
		showForceFinishedFX = !skipVisuals;
		GotoState('Expired');
	}
}

// 5.x body; changes marked //modSigns.
@replaceMethod(W3QuenEntityStateShieldActive)
function OnEnterState( prevStateName : name )
{
	var witcher			: W3PlayerWitcher;
	var params 			: SCustomEffectParams;
	
	super.OnEnterState( prevStateName );
	
	witcher = (W3PlayerWitcher)caster.GetActor();
	
	if(witcher)
	{
		witcher.SetUsedQuenInCombat();
		witcher.m_quenReappliedCount = 1;
		
		params.effectType = EET_BasicQuen;
		params.creator = witcher;
		params.sourceName = "sign cast";
		params.duration = parent.shieldDuration;
		
		witcher.AddEffectCustom( params );
	}
	
	caster.GetActor().PlayEffect(GetLastingFxName());
	
	//modSigns: removed the Bear set's armor effect (legacy)
	
	parent.AddTimer( 'Expire', parent.shieldDuration, false, , , true );
	
	parent.AddBuffImmunities();
	
	if( witcher )
	{
		if( !parent.freeFromBearSetBonus )
		{
			parent.ManagePlayerStamina();
			parent.ManageGryphonSetBonusBuff();
		}
	}
	else
	{
		caster.GetActor().DrainStamina( ESAT_Ability, 0, 0, SkillEnumToName( parent.skillEnum ) );
	}
	
	
	if( !witcher.HasBuff( EET_HeavyKnockdown ) && !witcher.HasBuff( EET_Knockdown ) )	//modSigns: not the Bear set's (legacy)
	{
		witcher.CriticalEffectAnimationInterrupted("basic quen cast");
	}
	
	
	witcher.AddTimer('HACK_QuenSaveStatus', 0, true);
	parent.shieldStartTime = theGame.GetEngineTime();
}

// 5.x body; changes marked //modSigns.
@replaceMethod(W3QuenEntityStateQuenChanneled)
function ShowHitFX(damageData : W3DamageAction, rot : EulerAngles)
{
	var movingAgent : CMovingPhysicalAgentComponent;
	var inWater, hasFireDamage, hasElectricDamage, hasPoisonDamage, isDoT, isBirds : bool;
	var witcher	: W3PlayerWitcher;
	
	isBirds = (CFlyingCrittersLairEntityScript)damageData.causer;
	witcher = parent.owner.GetPlayer();
	
	if (isBirds)
	{
		
		parent.PlayHitEffect('quen_rebound_sphere_constant', rot, true);
		parent.AddTimer('RemoveDoTFX', 0.3, false, , , , true);
	}
	else
	{			
		isDoT = damageData.IsDoTDamage();
	
		if(!isDoT)
		{
			hasFireDamage = damageData.GetDamageValue(theGame.params.DAMAGE_NAME_FIRE) > 0;
			hasPoisonDamage = damageData.GetDamageValue(theGame.params.DAMAGE_NAME_POISON) > 0;		
			hasElectricDamage = damageData.GetDamageValue(theGame.params.DAMAGE_NAME_SHOCK) > 0;
	
			
			
			if( witcher && parent.dischargePercent > 0 )	//modSigns: the Bear set's sphere for Quen Discharge, either tree (legacy)
			
			{
				parent.PlayHitEffect( 'quen_rebound_sphere_bear_abl2', rot );
			}
			else if (hasFireDamage)
			{
				parent.PlayHitEffect( 'quen_rebound_sphere_fire', rot );
			}
			else if (hasPoisonDamage)
			{
				parent.PlayHitEffect( 'quen_rebound_sphere_poison', rot );
			}
			else if (hasElectricDamage)
			{
				parent.PlayHitEffect( 'quen_rebound_sphere_electricity', rot );
			}
			else
			{
				parent.PlayHitEffect( 'quen_rebound_sphere', rot );
			}
		}
	}
	
	
	movingAgent = (CMovingPhysicalAgentComponent)caster.GetActor().GetMovingAgentComponent();
	inWater = movingAgent.GetSubmergeDepth() < 0;
	if(!inWater)
	{
		parent.PlayHitEffect( 'quen_rebound_ground', rot );
	}
}
