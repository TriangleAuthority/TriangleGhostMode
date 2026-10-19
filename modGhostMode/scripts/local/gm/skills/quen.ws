// SKL-11: Quen, legacy's in both trees (docs/features/skl.md).
// - Quen absorbs raw damage before armor, attack power and resistances (legacy's
//   ProcessDamageDecrease, called by ProcessActionDamage after the raw-damage pool,
//   damage/pipeline.ws); 5.x absorbed processed damage in W3PlayerWitcher.ReduceDamage.
// - The sign's stats (W3QuenEntity.GetSignStats, replaced): read from Quen's own ability (magic_4) for
//   both casts; shield health (250 + Quen Intensity, classic magic_s15 +30 per level, the new tree's
//   magic_s38 +50 per level (D58)) x (1 + the intensity bonus); absorption 100% of each damage type that
//   hits Vitality (or Essence), direct damage excepted; Quen Discharge (classic magic_s14, 5% per level;
//   the new tree's magic_s40, 8.33% per level, D58) returns that share of the absorbed damage; Exploding Shield's level and Active Shield's healing cached. 5.x's Fortify Signs
//   (magic_s36) and supercharged-sign flag are gone.
// - The shield (ShieldActive.OnTargetHit, replaced): legacy's absorption of raw damage up to the
//   shield's health; at 0 the shield breaks, with Exploding Shield's impulse.
// - The active shield, the impulse and the effect rules: below.

// Writes the action's damage types (legacy's W3DamageAction.SetDTs).
@addMethod(W3DamageAction)
function GMSetDTs(dmgTypes : array< SRawDamage >) : int
{
	dmgInfos.Clear();
	dmgInfos = dmgTypes;
	return dmgInfos.Size();
}

// Legacy's ProcessDamageDecrease: Geralt's Quen against the raw damage, after the pool and before the
// crit check and armor. Eredin's frost slowdown and lightning's paralysis do not get through Quen.
@addMethod(W3DamageManagerProcessor)
function GMProcessDamageDecrease(out dmgInfos : array< SRawDamage >)
{
	var quen : W3QuenEntity;

	if(playerVictim != GetWitcherPlayer())
		return;
	quen = (W3QuenEntity)GetWitcherPlayer().GetSignEntity(ST_Quen);
	if(!quen || !quen.IsAnyQuenActive())
		return;
	action.RemoveBuffsByType(EET_SlowdownFrost);
	action.RemoveBuffsByType(EET_Paralyzed);
	action.GMSetDTs(dmgInfos);
	quen.OnTargetHit(action);
	action.GetDTs(dmgInfos);
}

@addField(W3QuenEntity)
var gmDmgAbsorptionPrc : float;
@addField(W3QuenEntity)
var gmImpulseLevel : int;
@addField(W3QuenEntity)
var gmQuenPower : SAbilityAttributeValue;
@addField(W3QuenEntity)
var gmHealingFactor : float;

// Quen Intensity: the classic magic_s15 or the new tree's magic_s38 (D58); S_SUndefined if none.
@addMethod(W3QuenEntity)
function GMQuenIntensitySkill() : ESkill
{
	if(owner.CanUseSkill(S_Magic_s15))
		return S_Magic_s15;
	if(owner.CanUseSkill(S_Magic_s38))
		return S_Magic_s38;
	return S_SUndefined;
}

// Quen Discharge: the classic magic_s14 or the new tree's magic_s40 (D58); S_SUndefined if none.
@addMethod(W3QuenEntity)
function GMQuenDischargeSkill() : ESkill
{
	if(owner.CanUseSkill(S_Magic_s14))
		return S_Magic_s14;
	if(owner.CanUseSkill(S_Magic_s40))
		return S_Magic_s40;
	return S_SUndefined;
}

@replaceMethod(W3QuenEntity)
function GetSignStats()
{
	var min, max : SAbilityAttributeValue;	//modSigns: removed fortifiedSignsAtt
	var skillBonus : float;	//modSigns
	//modSigns: removed fortifiedSignsAtt, player

	super.GetSignStats();

	//modSigns: removed 5.x's supercharged-sign flag

	gmQuenPower = owner.GetActor().GetTotalSignSpellPower(S_Magic_4);	//modSigns: Quen's own intensity for both casts
	//modSigns: legacy's Mutagen 19 and Glyphword 17 intensity bonuses come with ALCH and ENCH
	if(owner.CanUseSkill(S_Magic_s13))	//modSigns: Exploding Shield's level, cached
		gmImpulseLevel = owner.GetSkillLevel(S_Magic_s13);	//modSigns
	else	//modSigns
		gmImpulseLevel = 0;	//modSigns
	gmDmgAbsorptionPrc = CalculateAttributeValue(owner.GetSkillAttributeValue(S_Magic_4, 'max_dmg_absorption', false, false));	//modSigns

	shieldDuration = CalculateAttributeValue(owner.GetSkillAttributeValue(S_Magic_4, 'shield_duration', true, true));	//modSigns: from magic_4 for both casts
	//modSigns: legacy's Petri Philtre level 3 duration comes with ALCH
	shieldHealth = CalculateAttributeValue(owner.GetSkillAttributeValue(S_Magic_4, 'shield_health', false, true));	//modSigns

	if ( GMQuenDischargeSkill() != S_SUndefined)	//modSigns: either tree
	{
		dischargePercent = CalculateAttributeValue(owner.GetSkillAttributeValue(GMQuenDischargeSkill(), 'discharge_percent', false, true)) * owner.GetSkillLevel(GMQuenDischargeSkill());	//modSigns
		//modSigns: removed the Bear set's boost (ARM-08, legacy; legacy's Glyphword 5 boost comes with ENCH)
	}
	else
	{
		dischargePercent = 0;
	}

	if(GMQuenIntensitySkill() != S_SUndefined)	//modSigns: Quen Intensity's absorption, either tree
		skillBonus = CalculateAttributeValue(owner.GetSkillAttributeValue(GMQuenIntensitySkill(), 'shield_health_bonus', false, true)) * owner.GetSkillLevel(GMQuenIntensitySkill());	//modSigns
	shieldHealth += skillBonus;	//modSigns
	shieldHealth *= 1 + GMSignPowerStatToPowerBonus(gmQuenPower.valueMultiplicative);	//modSigns: scales with intensity
	initialShieldHealth = shieldHealth;	//modSigns: after the bonuses

	if(owner.CanUseSkill(S_Magic_s04))	//modSigns: Active Shield's healing
		gmHealingFactor = CalculateAttributeValue(owner.GetSkillAttributeValue(S_Magic_s04, 'shield_healing_factor', false, true)) * owner.GetSkillLevel(S_Magic_s04);	//modSigns
	else	//modSigns
		gmHealingFactor = 0;	//modSigns

	//modSigns: removed 5.x's Fortify Signs (magic_s36)
}

@addMethod(W3QuenEntity)
function GMGetShieldHealth() : float
{
	return shieldHealth;
}

// The shield as legacy: raw damage absorbed up to the shield's health.
@replaceMethod(W3QuenEntityStateShieldActive)
function OnTargetHit( out damageData : W3DamageAction )
{
	//modSigns: removed pos, drainedHealth, skillBonus, incomingDamage, directDamage, spellPower, physX
	var inAttackAction : W3Action_Attack;
	var action : W3DamageAction;
	var casterActor : CActor;
	//modSigns: removed effectTypes, isBleeding, min, max
	var damageTypes : array<SRawDamage>;
	var i : int;
	var reducedDamage, totalDamage, dmgVal : float;	//modSigns
	var size : int;	//modSigns
	var dmgType : name;	//modSigns

	if( damageData.WasDodged() ||
		damageData.GetHitReactionType() == EHRT_Reflect )
	{
		return true;
	}

	if(damageData.GetBuffSourceName() == "FallingDamage")	//modSigns: falling damage is not absorbed
		return true;	//modSigns
	if(damageData.IsDoTDamage() && (CBaseGameplayEffect)damageData.causer)	//modSigns: nor damage over time from effects
		return true;	//modSigns

	parent.OnTargetHit(damageData);

	inAttackAction = (W3Action_Attack)damageData;
	if(inAttackAction && inAttackAction.CanBeParried() && (inAttackAction.IsParried() || inAttackAction.IsCountered()) )
		return true;

	casterActor = caster.GetActor();
	reducedDamage = 0;
	totalDamage = 0;	//modSigns

	//modSigns: removed 5.x's absorption of processed Vitality damage (and its bleeding special case)
	size = damageData.GetDTs(damageTypes);	//modSigns: legacy: the raw damage types
	for(i = 0; i < size; i += 1)	//modSigns
	{	//modSigns
		dmgType = damageTypes[i].dmgType;	//modSigns
		if(casterActor.UsesVitality() && !DamageHitsVitality(dmgType))	//modSigns
			continue;	//modSigns
		if(casterActor.UsesEssence() && !DamageHitsEssence(dmgType))	//modSigns
			continue;	//modSigns
		dmgVal = damageTypes[i].dmgVal;	//modSigns
		totalDamage += dmgVal;	//modSigns
		if(dmgType == theGame.params.DAMAGE_NAME_DIRECT || parent.shieldHealth <= 0)	//modSigns: direct damage goes through
			continue;	//modSigns
		dmgVal *= parent.gmDmgAbsorptionPrc;	//modSigns
		if(dmgVal > parent.shieldHealth)	//modSigns
			dmgVal = parent.shieldHealth;	//modSigns
		damageTypes[i].dmgVal -= dmgVal;	//modSigns
		reducedDamage += dmgVal;	//modSigns
		parent.shieldHealth -= dmgVal;	//modSigns
	}	//modSigns
	for(i = size - 1; i >= 0; i -= 1)	//modSigns
	{	//modSigns
		if(damageTypes[i].dmgVal <= 0)	//modSigns
			damageTypes.EraseFast(i);	//modSigns
	}	//modSigns
	if(damageTypes.Size() > 0)	//modSigns
		damageData.GMSetDTs(damageTypes);	//modSigns
	else	//modSigns
		damageData.ClearDamage();	//modSigns

	if ( theGame.CanLog() )	//modSigns: moved after the absorption
	{	//modSigns
		LogDMHits("Quen ShieldActive.OnTargetHit: absorbed " + reducedDamage + " of " + totalDamage, damageData );	//modSigns
	}	//modSigns

	if(reducedDamage > 0)	//modSigns
	{	//modSigns
		casterActor.PlayEffect( 'quen_lasting_shield_hit' );	//modSigns: the hit effects when something was absorbed
		GCameraShake( parent.effects[parent.fireMode].cameraShakeStranth, true, parent.GetWorldPosition(), 30.0f );	//modSigns

		//modSigns: removed 5.x's shield drain by intensity and its supercharged bonus
		if (!damageData.IsDoTDamage() && casterActor == thePlayer && damageData.attacker != casterActor && parent.dischargePercent > 0 && !damageData.IsActionRanged() && VecDistanceSquared( casterActor.GetWorldPosition(), damageData.attacker.GetWorldPosition() ) <= 13 )	//modSigns: Quen Discharge (no supercharged branch)
		{
			action = new W3DamageAction in theGame.damageMgr;
			action.Initialize( casterActor, damageData.attacker, parent, 'quen', EHRT_Light, CPS_SpellPower, false, false, true, false, 'hit_shock' );
			parent.InitSignDataForDamageAction( action );
			action.AddDamage( theGame.params.DAMAGE_NAME_SHOCK, parent.dischargePercent * reducedDamage );	//modSigns: a share of the absorbed damage (5.x: of the incoming)
			action.SetCanPlayHitParticle(true);
			action.SetHitEffect('hit_electric_quen');
			action.SetHitEffect('hit_electric_quen', true);
			action.SetHitEffect('hit_electric_quen', false, true);
			action.SetHitEffect('hit_electric_quen', true, true);

			theGame.damageMgr.ProcessAction( action );
			delete action;

			casterActor.PlayEffect('quen_force_discharge');
		}
	}

	if(totalDamage <= reducedDamage)	//modSigns: all absorbed: no hit animation or particle
	{	//modSigns
		parent.SetBlockedAllDamage(true);
		damageData.SetHitAnimationPlayType( EAHA_ForceNo );	//modSigns
		damageData.SetCanPlayHitParticle( false );	//modSigns
	}	//modSigns
	else
		parent.SetBlockedAllDamage(false);
	if(totalDamage - reducedDamage >= 20)	//modSigns
		casterActor.RaiseForceEvent( 'StrongHitTest' );	//modSigns

	if( parent.shieldHealth <= 0 )
	{
		if ( parent.gmImpulseLevel > 0 )	//modSigns: Exploding Shield (no supercharged branch)
		{
			casterActor.PlayEffect( 'lasting_shield_impulse' );
			caster.GetPlayer().QuenImpulse( false, parent, "quen_impulse", parent.gmImpulseLevel );	//modSigns
		}

		damageData.SetEndsQuen(true);
	}
}

// Active Shield (legacy, both trees): its health is the shield's x magic_s4's shield_health_factor (2)
// x Geralt's stamina share (or his adrenaline, cast with Rage Management); it absorbs raw damage up to
// that, heals the absorbed damage x 33.4% per level, drains stamina (or adrenaline) by the share of its
// health used, returns Quen Discharge's share of the absorbed damage, and breaks at 0 stamina (or
// adrenaline), with Exploding Shield's impulse. 5.x's version (processed damage, intensity-based drain
// and healing, supercharged branches) is gone.
@replaceMethod(W3QuenEntityStateQuenChanneled)
function OnTargetHit( out damageData : W3DamageAction )
{
	var reducedDamage, shieldFactor : float;	//modSigns
	var casterActor : CActor;
	var attackerVictimEuler : EulerAngles;
	var action : W3DamageAction;
	var shieldHP : float;
	var staminaPrc, adrenalinePrc, totalDamage, dmgVal, reducedDamagePrc, drainedStamina, drainedAdrenaline : float;	//modSigns
	var damageTypes : array<SRawDamage>;	//modSigns
	var i, size : int;	//modSigns
	var dmgType : name;	//modSigns
	var usesAdrenaline : bool;	//modSigns
	//modSigns: removed skillBonus, reducibleDamage, directDamage, spellPower, drainAllStamina, isBleeding, min, max

	if(damageData.GetBuffSourceName() == "FallingDamage")	//modSigns: falling damage is not absorbed
		return true;	//modSigns
	if(damageData.IsDoTDamage() && (CBaseGameplayEffect)damageData.causer)	//modSigns: nor damage over time from effects
		return true;	//modSigns

	parent.OnTargetHit(damageData);

	casterActor = caster.GetActor();

	//modSigns: removed vanilla lines (reordered)
	if( !( (CBaseGameplayEffect) damageData.causer ) )
	{
		attackerVictimEuler = VecToRotation(damageData.attacker.GetWorldPosition() - casterActor.GetWorldPosition());
		attackerVictimEuler.Pitch = 0;
		attackerVictimEuler.Roll = 0;
	}	//modSigns: the hit effects only when something is absorbed (below)

	if( casterActor.HasBuff( EET_Mutation11Buff ) )	//modSigns: Mutation 11's immortality: everything absorbed, nothing drained
	{	//modSigns
		ShowHitFX(damageData, attackerVictimEuler);	//modSigns
		damageData.ClearDamage();	//modSigns
		parent.SetBlockedAllDamage(true);	//modSigns
		damageData.SetHitAnimationPlayType(EAHA_ForceNo);	//modSigns
		damageData.SetCanPlayHitParticle(false);	//modSigns
		return true;	//modSigns
	}	//modSigns

	shieldFactor = CalculateAttributeValue( caster.GetSkillAttributeValue( S_Magic_s04, 'shield_health_factor', false, true ) );
	usesAdrenaline = (W3PlayerWitcher)casterActor && ((W3PlayerWitcher)casterActor).GMHasRageManagement() && parent.usedFocus;	//modSigns: cast with Rage Management, either tree
	if(usesAdrenaline)	//modSigns
		adrenalinePrc = casterActor.GetStat(BCS_Focus);	//modSigns
	else	//modSigns
		staminaPrc = casterActor.GetStat(BCS_Stamina) / casterActor.GetStatMax(BCS_Stamina);	//modSigns
	shieldHP = parent.shieldHealth * shieldFactor * (staminaPrc + adrenalinePrc);	//modSigns

	size = damageData.GetDTs(damageTypes);	//modSigns: legacy: the raw damage types
	for(i = 0; i < size; i += 1)	//modSigns
	{	//modSigns
		dmgType = damageTypes[i].dmgType;	//modSigns
		if(casterActor.UsesVitality() && !DamageHitsVitality(dmgType))	//modSigns
			continue;	//modSigns
		if(casterActor.UsesEssence() && !DamageHitsEssence(dmgType))	//modSigns
			continue;	//modSigns
		dmgVal = damageTypes[i].dmgVal;	//modSigns
		totalDamage += dmgVal;	//modSigns
		if(dmgType == theGame.params.DAMAGE_NAME_DIRECT || shieldHP <= 0)	//modSigns
			continue;	//modSigns
		if(dmgVal > shieldHP)	//modSigns
			dmgVal = shieldHP;	//modSigns
		damageTypes[i].dmgVal -= dmgVal;	//modSigns
		reducedDamage += dmgVal;	//modSigns
		shieldHP -= dmgVal;	//modSigns
	}	//modSigns
	for(i = size - 1; i >= 0; i -= 1)	//modSigns
	{	//modSigns
		if(damageTypes[i].dmgVal <= 0)	//modSigns
			damageTypes.EraseFast(i);	//modSigns
	}	//modSigns
	if(damageTypes.Size() > 0)	//modSigns
		damageData.GMSetDTs(damageTypes);	//modSigns
	else	//modSigns
		damageData.ClearDamage();	//modSigns

	if ( reducedDamage > 0 )	//modSigns
	{
		if ( theGame.CanLog() )
		{
			LogDMHits("Quen QuenChanneled.OnTargetHit: absorbed " + reducedDamage + " of " + totalDamage, damageData );	//modSigns
		}
		if( !( (CBaseGameplayEffect) damageData.causer ) )	//modSigns
			ShowHitFX(damageData, attackerVictimEuler);	//modSigns
		if(!damageData.IsDoTDamage())
			GCameraShake( parent.effects[parent.fireMode].cameraShakeStranth, true, parent.GetWorldPosition(), 30.0f );

		caster.GetActor().Heal(reducedDamage * parent.gmHealingFactor);	//modSigns: Active Shield's healing (5.x: by intensity)

		if( casterActor == thePlayer && parent.dischargePercent > 0 && !damageData.IsDoTDamage() && !damageData.IsActionRanged() && VecDistanceSquared( casterActor.GetWorldPosition(), damageData.attacker.GetWorldPosition() ) <= 13 )	//modSigns: Quen Discharge (no supercharged branch)
		{
			action = new W3DamageAction in theGame.damageMgr;
			action.Initialize( casterActor, damageData.attacker, parent, 'quen', EHRT_Light, CPS_SpellPower, false, false, true, false, 'hit_shock' );
			parent.InitSignDataForDamageAction( action );
			action.AddDamage( theGame.params.DAMAGE_NAME_SHOCK, parent.dischargePercent * reducedDamage );	//modSigns: a share of the absorbed damage
			action.SetCanPlayHitParticle(true);
			action.SetHitEffect('hit_electric_quen');
			action.SetHitEffect('hit_electric_quen', true);
			action.SetHitEffect('hit_electric_quen', false, true);
			action.SetHitEffect('hit_electric_quen', true, true);
			theGame.damageMgr.ProcessAction( action );
			delete action;
			parent.PlayHitEffect('discharge', attackerVictimEuler);
		}
	}

	if(totalDamage <= reducedDamage)	//modSigns: all absorbed
	{	//modSigns
		parent.SetBlockedAllDamage(true);	//modSigns
		damageData.SetHitAnimationPlayType( EAHA_ForceNo );	//modSigns
		damageData.SetCanPlayHitParticle(false);	//modSigns
	}	//modSigns
	else	//modSigns
		parent.SetBlockedAllDamage(false);	//modSigns
	if(totalDamage - reducedDamage >= 20)	//modSigns
		casterActor.RaiseForceEvent( 'StrongHitTest' );	//modSigns

	if(reducedDamage > 0)	//modSigns: drain by the share of the shield's health used
	{	//modSigns
		reducedDamagePrc = reducedDamage / (parent.shieldHealth * shieldFactor);	//modSigns
		if(usesAdrenaline)	//modSigns
		{	//modSigns
			drainedAdrenaline = MinF(reducedDamagePrc, casterActor.GetStat(BCS_Focus));	//modSigns
			if(drainedAdrenaline > 0)	//modSigns
				((W3PlayerWitcher)casterActor).DrainFocus(drainedAdrenaline * parent.GMFoaMult());	//modSigns: x Flood of Anger's multiplier
		}	//modSigns
		else	//modSigns
		{	//modSigns
			drainedStamina = reducedDamagePrc * casterActor.GetStatMax(BCS_Stamina);	//modSigns
			casterActor.DrainStamina(ESAT_FixedValue, drainedStamina, casterActor.GetStaminaActionDelay(ESAT_Ability, caster.GetSkillAbilityName(S_Magic_s04)));	//modSigns
		}	//modSigns
		if(usesAdrenaline && casterActor.GetStat(BCS_Focus) <= 0 || !usesAdrenaline && casterActor.GetStat(BCS_Stamina) <= 0)	//modSigns: breaks at 0
		{
			if ( parent.gmImpulseLevel > 0 )	//modSigns
			{
				parent.PlayHitEffect( 'quen_rebound_sphere_impulse', attackerVictimEuler );
				caster.GetPlayer().QuenImpulse( true, parent, "quen_impulse", parent.gmImpulseLevel );	//modSigns
			}
			damageData.SetEndsQuen(true);
		}
	}	//modSigns
}

// The alternate Quen's end: Exploding Shield's impulse only when the shield ends with stamina (or
// adrenaline, cast with Rage Management) above 0, as legacy's QuenChanneled.OnLeaveState: a shield broken
// by a hit has fired it already (OnTargetHit, above), and one whose channel ran dry fires none. The
// level is the cached one. 5.x fired it on every end with the skill known (twice on a break; SKL audit
// F13). 5.x body; changes marked //modSigns.
@replaceMethod(W3QuenEntityStateQuenChanneled)
function OnEnded(optional isEnd : bool)
{
	var casterActor : CActor;
	
	if(!HAXXOR_LeavingState)
		super.OnEnded();
		
	casterActor = caster.GetActor();
	casterActor.GetMovingAgentComponent().ResetVirtualRadius();
	casterActor.StopEffect('quen_shield');		
	casterActor.StopEffect( 'quen_lasting_shield_bear_abl2' );
	
	parent.RemoveBuffImmunities();		
	
	parent.StopAllEffects();
	
	parent.RemoveHitDoTEntities();
	
	
	
	
	if ( isEnd )
	{
		//modSigns: removed 5.x's supercharged-sign impulse (no supercharged signs, SKL-11)
		if ( parent.gmImpulseLevel > 0 && ( parent.GetUsedFocus() && casterActor.GetStat(BCS_Focus) > 0 || !parent.GetUsedFocus() && casterActor.GetStat(BCS_Stamina) > 0 ) )	//modSigns: legacy's rule, the cached level
		{	//modSigns
			parent.PlayHitEffect('quen_rebound_sphere_impulse', parent.GetWorldRotation());	//modSigns
			caster.GetPlayer().QuenImpulse( true, parent, "quen_impulse", parent.gmImpulseLevel );	//modSigns
		}	//modSigns
	}	//modSigns
	
}

// A Quen restored after loading a save is free, as legacy's (freeCast): no stamina or adrenaline and no
// cooldown; 5.x's flag for the Bear set's free Quen skips both (ShieldActive.OnEnterState calls no
// ManagePlayerStamina). The alternate Quen pays its channel's start, as legacy's (SKL audit F16).
// 5.x body; changes marked //modSigns.
@replaceMethod(W3PlayerWitcher)
function RestoreQuen( quenHealth : float, quenDuration : float, optional alternate : bool ) : bool
{
	var restoredQuen 	: W3QuenEntity;

	if(quenHealth > 0.f && quenDuration >= 3.f)
	{
		restoredQuen = (W3QuenEntity)theGame.CreateEntity( signs[ST_Quen].template, GetWorldPosition(), GetWorldRotation() );
		restoredQuen.Init( signOwner, signs[ST_Quen].entity, true );

		if( alternate )
		{
			restoredQuen.SetAlternateCast( S_Magic_s04 );
		}

		restoredQuen.freeFromBearSetBonus = true;	//modSigns: free, as legacy's freeCast
		restoredQuen.OnStarted();
		restoredQuen.OnThrowing();

		if( !alternate )
		{
			restoredQuen.OnEnded();
		}

		restoredQuen.SetDataFromRestore(quenHealth, quenDuration);

		return true;
	}

	return false;
}

// Exploding Shield's impulse (legacy, both trees): hostile living enemies within 3 m (a box: 5.x's
// sphere with line of sight misses targets, legacy found), a light hit; from level 2 the ability's damage
// x (level - 1) (30, 60 shock damage); a stagger at levels 1 and 2, the knockdown roll at 3 (5.x: both,
// and damage not scaled by level).
@replaceMethod(W3PlayerWitcher)
function QuenImpulse( isAlternate : bool, signEntity : W3QuenEntity, source : string, optional forceSkillLevel : int )
{
	var level, i, j : int;
	var atts, damages : array<name>;
	var ents : array<CGameplayEntity>;
	var action : W3DamageAction;
	var dm : CDefinitionsManagerAccessor;
	var skillAbilityName : name;
	var dmg : float;
	var min, max : SAbilityAttributeValue;
	//modSigns: removed pos

	if( forceSkillLevel > 0 )
	{
		level = forceSkillLevel;
	}
	else
	{
		level = GetSkillLevel(S_Magic_s13);
	}

	dm = theGame.GetDefinitionsManager();
	skillAbilityName = GetSkillAbilityName(S_Magic_s13);

	if(level >= 2)
	{

		dm.GetAbilityAttributes(skillAbilityName, atts);
		for(i=0; i<atts.Size(); i+=1)
		{
			if(IsDamageTypeNameValid(atts[i]))
			{
				damages.PushBack(atts[i]);
			}
		}
	}

	FindGameplayEntitiesInRange(ents, this, 3, 100, , FLAG_OnlyAliveActors + FLAG_ExcludeTarget + FLAG_Attitude_Hostile, this);	//modSigns: legacy's box, hostiles only (5.x: a sphere with line of sight, neutrals too)

	for(i=0; i<ents.Size(); i+=1)
	{
		action = new W3DamageAction in theGame;
		action.Initialize(this, ents[i], signEntity, source, EHRT_Light, CPS_SpellPower, false, false, true, false);	//modSigns: a light hit
		action.SetSignSkill(S_Magic_s13);
		action.SetCannotReturnDamage(true);
		action.SetProcessBuffsIfNoDamage(true);

		if(level >= 2)	//modSigns
		{	//modSigns
			for(j=0; j<damages.Size(); j+=1)	//modSigns
			{	//modSigns
				dm.GetAbilityAttributeValue(skillAbilityName, damages[j], min, max);	//modSigns
				dmg = CalculateAttributeValue(GetAttributeRandomizedValue(min, max)) * (level - 1);	//modSigns: scales with the level
				if(dmg > 0)	//modSigns
				{	//modSigns
					action.SetHitEffect('hit_electric_quen');	//modSigns: the hit effect with damage, both casts
					action.SetHitEffect('hit_electric_quen', true);	//modSigns
					action.SetHitEffect('hit_electric_quen', false, true);	//modSigns
					action.SetHitEffect('hit_electric_quen', true, true);	//modSigns
					action.AddDamage(damages[j], dmg);
				}	//modSigns
			}
		}	//modSigns
		if(level == 3)	//modSigns: the knockdown roll at level 3, a stagger below
			action.AddEffectInfo(EET_KnockdownTypeApplicator);	//modSigns
		else if(level >= 1)	//modSigns
			action.AddEffectInfo(EET_Stagger);	//modSigns

		theGame.damageMgr.ProcessAction( action );
		delete action;
	}

	if(isAlternate)
	{
		signEntity.PlayHitEffect('quen_impulse_explode', signEntity.GetWorldRotation());
		signEntity.EraseFirstTimeStamp();

		if(level >= 2)
		{
			signEntity.PlayHitEffect('quen_electric_explode', signEntity.GetWorldRotation());	//modSigns: not the Bear set's effect (ARM-08, legacy)
		}
	}
	else
	{
		signEntity.PlayEffect('lasting_shield_impulse');
	}
}

// Quen's effect rules (legacy's W3EffectManager.InternalAddEffect), before 5.x's:
// - an NPC with alternate Quen: a knockdown is denied and ends its Quen, a stagger is denied;
// - Geralt with alternate Quen: a knockdown is denied and breaks the shield, a stagger, long stagger or
//   counter hit is denied without breaking it; with the basic shield those are denied and break it;
// - Geralt with either shield: damage-over-time effects (burning, bleeding, poison, ...) are denied, the
//   basic shield breaks (5.x: 0.1 s of their damage dealt, and after any hit taken with Quen up).
// Effects Geralt is immune to anyway do not touch the shield.
function GMIsDoTEffectType(effectType : EEffectType) : bool
{
	switch(effectType)
	{
		case EET_Burning :
		case EET_Bleeding :
		case EET_Bleeding1 :
		case EET_Bleeding2 :
		case EET_Bleeding3 :
		case EET_BleedingTracking :
		case EET_Poison :
		case EET_PoisonCritical :
		case EET_Swarm :
		case EET_Snowstorm :
		case EET_Acid :
		case EET_Choking :
		case EET_Drowning :
		case EET_VitalityDrain :
			return true;
	}
	return false;
}

@addMethod(W3QuenEntity)
function GMShowHitFX()
{
	owner.GetActor().PlayEffect('quen_lasting_shield_hit');
	GCameraShake( effects[fireMode].cameraShakeStranth, true, GetWorldPosition(), 30.0f );
}

@wrapMethod(W3EffectManager)
function InternalAddEffect(effectType : EEffectType, creat : CGameplayEntity, srcName : string, optional inDuration : float, optional customVal : SAbilityAttributeValue, optional customAbilityName : name, optional customFXName : name, optional signEffect : bool, optional powerStatValue : SAbilityAttributeValue, optional customParams : W3BuffCustomParams, optional vibratePadLowFreq : float, optional vibratePadHighFreq : float) : EEffectInteract
{
	var witcher : W3PlayerWitcher;
	var quen : W3QuenEntity;
	var isKnockdown, isStagger, hasAltQuen : bool;

	isKnockdown = effectType == EET_Knockdown || effectType == EET_HeavyKnockdown;
	isStagger = effectType == EET_Stagger || effectType == EET_LongStagger || effectType == EET_CounterStrikeHit;
	witcher = (W3PlayerWitcher)owner;
	if(owner && !owner.IsImmuneToBuff(effectType))
	{
		if(!witcher && owner != thePlayer && owner.HasAlternateQuen())
		{
			if(isKnockdown)
			{
				owner.FinishQuen(false);
				return EI_Deny;
			}
			if(effectType == EET_Stagger || effectType == EET_LongStagger)
				return EI_Deny;
		}
		if(witcher && witcher.IsAnyQuenActive())
		{
			hasAltQuen = witcher.HasAlternateQuen();
			quen = (W3QuenEntity)witcher.GetSignEntity(ST_Quen);
			if(hasAltQuen && isKnockdown)
			{
				quen.GMShowHitFX();
				witcher.FinishQuen(false);
				return EI_Deny;
			}
			if(isStagger)
			{
				quen.GMShowHitFX();
				if(!hasAltQuen)
					witcher.FinishQuen(false);
				return EI_Deny;
			}
			if(GMIsDoTEffectType(effectType))
			{
				quen.GMShowHitFX();
				if(!hasAltQuen)
					witcher.FinishQuen(false);
				return EI_Deny;
			}
		}
	}
	return wrappedMethod(effectType, creat, srcName, inDuration, customVal, customAbilityName, customFXName, signEffect, powerStatValue, customParams, vibratePadLowFreq, vibratePadHighFreq);
}

// SKL-11 (found with MUT-10): a save from 5.x play can still carry the player_had_quen fact, which
// makes 5.x's InternalAddEffect cut the next damage-over-time effect on Geralt to 0.1 s of damage
// (Ghost Mode no longer sets the fact). Legacy removed it on spawn too.
@wrapMethod(W3PlayerWitcher)
function OnSpawned(spawnData : SEntitySpawnData)
{
	wrappedMethod(spawnData);
	FactsRemove("player_had_quen");
}
