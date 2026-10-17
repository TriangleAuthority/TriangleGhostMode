// SKL-10: Yrden, legacy's in both trees (docs/features/skl.md).
// - The sign's stats (W3YrdenEntity.GetSignStats, replaced): durations no longer scale with intensity;
//   Sustained Glyphs (classic magic_s10, new tree magic_s42): +33.3% trap duration per level, a second
//   trap at level 3; the turret's level bonuses (Magic Trap magic_s03) and Yrden Intensity's damage
//   (classic magic_s16, 30 per level; the new tree's magic_s37, 50 per level, D58),
//   Supercharged Glyphs' damage bonus and Yrden's intensity are cached for the trap and the turret.
//   5.x's Fortify Signs (magic_s36), its supercharged flag and its magic_s42 range are gone.
// - The trap's slowdown (YrdenSlowdown_Loop, replaced): 25% x (1 + the intensity bonus of the power left
//   after the target's shock resistance points) x (1 - shock resistance %), between 15% and 75%, every
//   0.1 s; after a third of the trap's duration it decays linearly to 15% at its end; none while the
//   target plays a critical-state animation (poison excepted) or gets up from a knockdown. The slowdown
//   effect (W3Effect_Slowdown) takes the value as given (the trap applies the resistance) and is reset
//   in place each tick (legacy's ResetSlowdownEffect).
// - The turret (state YrdenShock): its damage gets Magic Trap's per-level bonus and Yrden Intensity's
//   (cached by GetSignStats); legacy's source name; the hit reaction after the shot only (none on
//   entering the area); the shock area sized by the level cached at the cast (Flood of Anger's), and
//   non-actors in it no longer notified (legacy's OnEnterState); an actor leaving the area is no longer
//   shot (Bugfix 117). 5.x's AI signals on entering and leaving stay (AI).
// - Supercharged Glyphs (magic_s11; classic GM_C_magic_s11 5 levels, 5% per level; new tree 8.33%):
//   enemies inside the trap take +25% final damage from Geralt at the maximum level, reduced by shock
//   resistance and decaying with the slowdown (the bonus rides on 5.x's EET_YrdenHealthDrain, which no
//   longer drains; damage/pipeline.ws applies it). 5.x's drain is gone.

@addField(W3YrdenEntity)
var gmMaxCount : int;
@addField(W3YrdenEntity)
var gmYrdenPower : SAbilityAttributeValue;
@addField(W3YrdenEntity)
var gmTurretLevel : int;
@addField(W3YrdenEntity)
var gmTurretDamageBonus : float;
@addField(W3YrdenEntity)
var gmHasSupercharged : bool;
@addField(W3YrdenEntity)
var gmSuperchargedDmg : float;

// Sustained Glyphs: the classic magic_s10 or the new tree's magic_s42; S_SUndefined if none.
@addMethod(W3YrdenEntity)
function GMSustainedGlyphsSkill() : ESkill
{
	if(owner.CanUseSkill(S_Magic_s10))
		return S_Magic_s10;
	if(owner.CanUseSkill(S_Magic_s42))
		return S_Magic_s42;
	return S_SUndefined;
}

// Yrden Intensity: the classic magic_s16 or the new tree's magic_s37 (D58); S_SUndefined if none.
@addMethod(W3YrdenEntity)
function GMYrdenIntensitySkill() : ESkill
{
	if(owner.CanUseSkill(S_Magic_s16))
		return S_Magic_s16;
	if(owner.CanUseSkill(S_Magic_s37))
		return S_Magic_s37;
	return S_SUndefined;
}

// Sustained Glyphs' radius: x (1 + range_bonus) from level 2, for the trap (not the turret).
@addMethod(W3YrdenEntity)
function GMSustainedGlyphsRangeMult() : float
{
	var sustained : ESkill;

	sustained = GMSustainedGlyphsSkill();
	if(IsAlternateCast() || sustained == S_SUndefined || owner.GetSkillLevel(sustained) < 2)
		return 1;
	return 1 + CalculateAttributeValue(owner.GetSkillAttributeValue(sustained, 'range_bonus', false, false));
}

@addMethod(W3YrdenEntity)
function GMGetMaxCount() : int
{
	return gmMaxCount;
}

@addMethod(W3YrdenEntity)
function GMGetYrdenPower() : SAbilityAttributeValue
{
	return gmYrdenPower;
}

@replaceMethod(W3YrdenEntity)
function GetSignStats()
{
	var chargesAtt, trapDurationAtt : SAbilityAttributeValue;	//modSigns: removed fortifiedSignsAtt
	var sustained : ESkill;	//modSigns
	//modSigns: removed fortifiedSignsAtt, player, rangeAttr, rangeMult

	super.GetSignStats();

	//modSigns: removed 5.x's supercharged-sign flag

	chargesAtt = owner.GetSkillAttributeValue(skillEnum, 'charge_count', false, true);
	trapDurationAtt = owner.GetSkillAttributeValue(skillEnum, 'trap_duration', false, false);	//modSigns: without the skills' mods
	baseModeRange = CalculateAttributeValue( owner.GetSkillAttributeValue(skillEnum, 'range', false, false) );	//modSigns

	//modSigns: removed 5.x's magic_s42 range
	sustained = GMSustainedGlyphsSkill();	//modSigns: Sustained Glyphs, both trees
	gmMaxCount = 1;	//modSigns
	if(!IsAlternateCast() && sustained != S_SUndefined && owner.GetSkillLevel(sustained) >= 3)	//modSigns: a second trap at level 3
		gmMaxCount += 1;	//modSigns
	baseModeRange *= GMSustainedGlyphsRangeMult();	//modSigns: +30% radius from level 2 (the rune ring; Place scales the trigger)
	gmYrdenPower = owner.GetActor().GetTotalSignSpellPower(skillEnum);	//modSigns: cached for the trap and the turret
	gmHasSupercharged = owner.CanUseSkill(S_Magic_s11);	//modSigns
	gmSuperchargedDmg = 0;	//modSigns
	if(gmHasSupercharged && owner.GetPlayer())	//modSigns
		gmSuperchargedDmg = CalculateAttributeValue(owner.GetPlayer().GetSkillAttributeValue(S_Magic_s11, 's11_dmg_bonus', false, true)) * owner.GetPlayer().GetSkillLevel(S_Magic_s11);	//modSigns
	gmTurretLevel = 0;	//modSigns
	gmTurretDamageBonus = 0;	//modSigns
	if(owner.CanUseSkill(S_Magic_s03))	//modSigns: Magic Trap's bonuses per level above 1, Yrden Intensity's damage
	{	//modSigns
		gmTurretLevel = owner.GetSkillLevel(S_Magic_s03);	//modSigns
		gmTurretDamageBonus = CalculateAttributeValue(owner.GetSkillAttributeValue(S_Magic_s03, 'damage_bonus_flat_after_1', false, false)) * (gmTurretLevel - 1);	//modSigns
		trapDurationAtt.valueAdditive += CalculateAttributeValue(owner.GetSkillAttributeValue(S_Magic_s03, 'duration_bonus_flat_after_1', false, false)) * (gmTurretLevel - 1);	//modSigns
		chargesAtt.valueAdditive += CalculateAttributeValue(owner.GetSkillAttributeValue(S_Magic_s03, 'charge_bonus_flat_after_1', false, false)) * (gmTurretLevel - 1);	//modSigns
		if(GMYrdenIntensitySkill() != S_SUndefined)	//modSigns: either tree
			gmTurretDamageBonus += CalculateAttributeValue(owner.GetSkillAttributeValue(GMYrdenIntensitySkill(), 'turret_bonus_damage', false, true)) * owner.GetSkillLevel(GMYrdenIntensitySkill());	//modSigns
	}	//modSigns
	//modSigns: removed 5.x's duration scaling with intensity

	charges = (int)CalculateAttributeValue(chargesAtt);
	trapDuration = CalculateAttributeValue(trapDurationAtt);
	if(!IsAlternateCast() && sustained != S_SUndefined)	//modSigns: Sustained Glyphs' duration
		trapDuration *= 1 + CalculateAttributeValue(owner.GetSkillAttributeValue(sustained, 'trap_duration_bonus', false, false)) * owner.GetSkillLevel(sustained);	//modSigns
	//modSigns: removed 5.x's Fortify Signs (magic_s36)
	//modSigns: legacy's Glyphword 15 (Entanglement) comes with ENCH, its Petri Philtre level 3 bonus with ALCH
}

@replaceMethod(W3YrdenEntityStateYrdenSlowdown)
function YrdenSlowdown_Loop()
{
	var params : SCustomEffectParams;	//modSigns
	var casterActor, curTarget : CActor;	//modSigns
	var i : int;
	var min, max, pts, prc : float;	//modSigns: removed scale
	var casterPlayer : CR4Player;
	var npc : CNewNPC;
	var startingMin, slowPower, decayDelay, timePassed, inc, mult, slow : float;	//modSigns
	var dt : float;	//modSigns
	var currentlyAnimatedCS : CBaseGameplayEffect;	//modSigns
	var yrden : W3YrdenEntity;	//modSigns
	var power : SAbilityAttributeValue;	//modSigns
	var paramsDrain : SCustomEffectParams;	//modSigns: Supercharged Glyphs' marker
	var superchargedBonus, bonus : float;	//modSigns
	//modSigns: removed paramsDrain, scale, sp, multiplier

	casterActor = caster.GetActor();
	casterPlayer = caster.GetPlayer();
	yrden = (W3YrdenEntity)parent;	//modSigns
	dt = 0.1;	//modSigns

	min = CalculateAttributeValue(casterPlayer.GetSkillAttributeValue(S_Magic_3, 'min_slowdown', false, false));	//modSigns
	max = CalculateAttributeValue(casterPlayer.GetSkillAttributeValue(S_Magic_3, 'max_slowdown', false, false));	//modSigns
	startingMin = CalculateAttributeValue(casterPlayer.GetSkillAttributeValue(S_Magic_3, 'min_starting_slowdown', false, false));	//modSigns
	power = yrden.GMGetYrdenPower();	//modSigns
	slowPower = power.valueMultiplicative;	//modSigns

	params.effectType = EET_Slowdown;	//modSigns
	params.creator = casterActor;
	params.sourceName = "yrden_mode0";
	params.isSignEffect = true;
	params.customAbilityName = '';	//modSigns
	params.duration = 0.2;	//modSigns: renewed every tick inside the area
	//modSigns: removed 5.x's slowdown by intensity / 4 and its health drain
	if(yrden.gmHasSupercharged)	//modSigns: Supercharged Glyphs' damage bonus (legacy)
	{	//modSigns
		paramsDrain.effectType = EET_YrdenHealthDrain;	//modSigns
		paramsDrain.creator = casterActor;	//modSigns
		paramsDrain.sourceName = "yrden_mode0";	//modSigns
		paramsDrain.isSignEffect = true;	//modSigns
		paramsDrain.duration = 0.2;	//modSigns
		superchargedBonus = yrden.gmSuperchargedDmg;	//modSigns
	}	//modSigns

	timePassed = 0;	//modSigns
	mult = 0;	//modSigns
	decayDelay = parent.trapDuration / 3.0;	//modSigns: the slowdown decays after a third of the duration
	inc = dt / (parent.trapDuration - decayDelay);	//modSigns

	while(true)
	{

		for(i=parent.flyersInArea.Size()-1; i>=0; i-=1)
		{
			npc = parent.flyersInArea[i];
			if(!npc.IsFlying())
			{
				parent.validTargetsInArea.PushBack(npc);
				npc.BlockAbility('Flying', true);
				parent.flyersInArea.EraseFast(i);
			}
		}

		for(i=0; i<parent.validTargetsInArea.Size(); i+=1)
		{
			curTarget = parent.validTargetsInArea[i];	//modSigns
			curTarget.GetResistValue(CDS_ShockRes, pts, prc);	//modSigns
			if(prc < 1)
			{	//modSigns
				slow = MaxF(0, startingMin * (1 + GMSignPowerStatToPowerBonus(slowPower - pts / 100))) * (1 - prc);	//modSigns
				slow = ClampF(slow, min, max);	//modSigns
				bonus = MaxF(0, superchargedBonus * (1 - prc));	//modSigns
				if(timePassed >= decayDelay)	//modSigns
				{	//modSigns
					slow = min + (slow - min) * (1 - MinF(mult, 1));	//modSigns
					bonus *= 1 - MinF(mult, 1);	//modSigns
				}	//modSigns
				params.effectValue.valueAdditive = slow;	//modSigns
				currentlyAnimatedCS = curTarget.GetCurrentlyAnimatedCS();	//modSigns
				if(currentlyAnimatedCS && !((W3Effect_PoisonCritical)currentlyAnimatedCS) || curTarget.GetIsRecoveringFromKnockdown())	//modSigns: no slowdown of critical-state animations
				{	//modSigns
					if(curTarget.HasBuff(EET_Slowdown))	//modSigns
						curTarget.RemoveBuff(EET_Slowdown);	//modSigns
				}	//modSigns
				else if(!curTarget.HasBuff(EET_Slowdown))	//modSigns
					curTarget.AddEffectCustom(params);	//modSigns
				else	//modSigns
					((W3Effect_Slowdown)curTarget.GetBuff(EET_Slowdown)).GMResetSlowdownEffect(params.effectValue);	//modSigns
				if(yrden.gmHasSupercharged)	//modSigns: Supercharged Glyphs
				{	//modSigns
					if(!curTarget.HasBuff(EET_YrdenHealthDrain))	//modSigns
						curTarget.AddEffectCustom(paramsDrain);	//modSigns
					((W3Effect_YrdenHealthDrain)curTarget.GetBuff(EET_YrdenHealthDrain)).GMSetDmgBonus(bonus);	//modSigns
				}	//modSigns
			}	//modSigns
			//modSigns: removed 5.x's health drain

			curTarget.OnYrdenHit( casterActor );	//modSigns
		}	//modSigns

		timePassed += dt;	//modSigns
		if(timePassed >= decayDelay)	//modSigns
			mult += inc;	//modSigns
		Sleep(dt);	//modSigns: legacy's 0.1 s tick (5.x: every frame)
	}	//modSigns
}

// The slowdown effect as legacy: the value as given (the source applies the resistance), reset in
// place by the Yrden trap; a cumulated slowdown no longer restarts the decay delay.
@replaceMethod(W3Effect_Slowdown)
function OnEffectAdded(optional customParams : W3BuffCustomParams)
{
	var dm : CDefinitionsManagerAccessor;
	var min, max : SAbilityAttributeValue;
	//modSigns: removed prc, pts

	super.OnEffectAdded(customParams);

	dm = theGame.GetDefinitionsManager();

	dm.GetAbilityAttributeValue(abilityName, 'decay_per_sec', min, max);
	decayPerSec = CalculateAttributeValue(GetAttributeRandomizedValue(min, max));

	dm.GetAbilityAttributeValue(abilityName, 'decay_delay', min, max);
	decayDelay = CalculateAttributeValue(GetAttributeRandomizedValue(min, max));

	//modSigns: removed the shock resistance multiplier (the source applies it)
	GMRecalcSlowdown();	//modSigns
	delayTimer = 0;
}

@addMethod(W3Effect_Slowdown)
function GMResetSlowdownEffect(newVal : SAbilityAttributeValue)
{
	effectValue = newVal;
	GMRecalcSlowdown();
	timeLeft = initialDuration;
	delayTimer = 0;
}

@addMethod(W3Effect_Slowdown)
function GMRecalcSlowdown()
{
	slowdown = ClampF(CalculateAttributeValue(effectValue), 0, 1);
	if(slowdownCauserId)
		target.ResetAnimationSpeedMultiplier(slowdownCauserId);
	slowdownCauserId = target.SetAnimationSpeedMultiplier(1 - slowdown);
}

@addMethod(W3Effect_Slowdown)
function GMGetSlowdown() : float
{
	return slowdown;
}

@replaceMethod(W3Effect_Slowdown)
function CumulateWith(effect: CBaseGameplayEffect)
{
	super.CumulateWith(effect);
	//modSigns: removed the decay delay reset
}

// Sustained Glyphs: two traps at level 3 (5.x: at level 2, or one more per level of magic_s42).
@replaceMethod(W3YrdenEntity)
function DisablePreviousYrdens()
{
	var maxCount, i, size, currCount : int;
	var isAlternate : bool;
	var witcher : W3PlayerWitcher;

	isAlternate = IsAlternateCast();
	witcher = GetWitcherPlayer();
	size = witcher.yrdenEntities.Size();
	maxCount = gmMaxCount;	//modSigns: from GetSignStats (a second trap at level 3)
	currCount = 0;

	//modSigns: removed 5.x's counts (magic_s10 level 2, magic_s42 per level)

	for(i=size-1; i>=0; i-=1)
	{
		if(!witcher.yrdenEntities[i])
		{
			witcher.yrdenEntities.Erase(i);
			continue;
		}

		if(witcher.yrdenEntities[i].IsAlternateCast() == isAlternate)
		{
			currCount += 1;
			if(currCount > maxCount)
			{
				witcher.yrdenEntities[i].OnSignAborted(true);
			}
		}
	}
}

// Sustained Glyphs' +30% radius scales the trap's trigger (legacy moved only the rune ring; 5.x scales
// the trigger for its magic_s42).
@replaceMethod(W3YrdenEntity)
function Place(trapPos : Vector)
{
	var trapPosTest, trapPosResult, collisionNormal, scale : Vector;
	var rot : EulerAngles;
	var witcher : W3PlayerWitcher;
	var trigger : CComponent;
	var min, max : SAbilityAttributeValue;
	var rangeMult : float;	//modSigns: removed rangeAttr

	witcher = GetWitcherPlayer();
	witcher.yrdenEntities.PushBack(this);

	DisablePreviousYrdens();

	if( GetWitcherPlayer().IsSetBonusActive( EISB_Gryphon_2 ) )
	{
		theGame.GetDefinitionsManager().GetAbilityAttributeValue( 'GryphonSetBonusYrdenEffect', 'trigger_scale', min, max );
		trigger = GetComponent( "Slowdown" );
		scale = trigger.GetLocalScale() * min.valueAdditive;
		trigger.SetScale( scale );
	}

	rangeMult = GMSustainedGlyphsRangeMult();	//modSigns: Sustained Glyphs (5.x: magic_s42's range per level)
	if ( rangeMult != 1 )	//modSigns
	{
		trigger = GetComponent( "Slowdown" );
		scale = trigger.GetLocalScale() * rangeMult;
		trigger.SetScale( scale );
	}

	Detach();
	SleepOneFrame();

	trapPosTest = trapPos;
	trapPosTest.Z -= 0.5;
	rot = GetWorldRotation();
	rot.Pitch = 0;
	rot.Roll = 0;

	if(theGame.GetWorld().StaticTrace(trapPos, trapPosTest, trapPosResult, collisionNormal))
	{
		trapPosResult.Z += 0.1;
		TeleportWithRotation ( trapPosResult, rot );
	}
	else
	{
		TeleportWithRotation ( trapPos, rot );
	}

	SleepOneFrame();

	AddTimer('TimedCanceled', trapDuration, , , , true);

	if(!notFromPlayerCast)
		owner.GetActor().OnSignCastPerformed(ST_Yrden, fireMode);
}

// The turret's shock area by the level cached at the cast (legacy's turretLevel: Flood of Anger's level
// lasts with it); non-actors in the area are no longer notified (SKL audit F17).
@replaceMethod(W3YrdenEntityStateYrdenShock)
function OnEnterState( prevStateName : name )
{
	var skillLevel : int;

	super.OnEnterState( prevStateName );

	skillLevel = parent.gmTurretLevel;	//modSigns: cached by GetSignStats (5.x: the caster's live level)

	if(skillLevel == 1)
		usedShockAreaName = 'Shock_lvl_1';
	else if(skillLevel == 2)
		usedShockAreaName = 'Shock_lvl_2';
	else if(skillLevel == 3)
		usedShockAreaName = 'Shock_lvl_3';

	parent.GetComponent(usedShockAreaName).SetEnabled( true );

	ActivateShock();
	//modSigns: removed parent.NotifyGameplayEntitiesInArea( usedShockAreaName ) (legacy)
}

// The turret: no hit reaction on entering the area, only after each shot (YrdenTrapHitEnemy; SKL audit
// F17). The AI signal stays (AI).
@replaceMethod(W3YrdenEntityStateYrdenShock)
function OnAreaEnter( area : CTriggerAreaComponent, activator : CComponent )
{
	var target : CNewNPC;
	var projectile : CProjectileTrajectory;

	target = (CNewNPC)(activator.GetEntity());

	if( target && !parent.allActorsInArea.Contains( target ) )
	{
		parent.allActorsInArea.PushBack( target );
	}

	if ( parent.charges && parent.IsValidTarget( target ) && !parent.validTargetsInArea.Contains(target) )
	{
		if( parent.validTargetsInArea.Size() == 0 )
		{
			parent.PlayEffect( parent.effects[parent.fireMode].activateEffect );
		}

		parent.validTargetsInArea.PushBack( target );

		//modSigns: removed target.OnYrdenHit( caster.GetActor() ) (legacy: the hit reaction comes after each shot)

		target.SignalGameplayEventParamObject('EntersYrden', parent );
	}
	else if(parent.projDestroyFxEntTemplate)
	{
		projectile = (CProjectileTrajectory)activator.GetEntity();

		if(projectile && !((W3SignProjectile)projectile) && IsRequiredAttitudeBetween(caster.GetActor(), projectile.caster, true, true, false))
		{
			if(projectile.IsStopped())
			{

				projectile.SetIsInYrdenAlternateRange(parent);
			}
			else
			{
				ShootDownProjectile(projectile);
			}
		}
	}
}

// The turret: an actor that left the area is no longer a target (Bugfix 117).
@replaceMethod(W3YrdenEntityStateYrdenShock)
function OnAreaExit( area : CTriggerAreaComponent, activator : CComponent )
{
	var target : CNewNPC;
	var projectile : CProjectileTrajectory;

	target = (CNewNPC)(activator.GetEntity());

	if ( target && parent.charges && target.GetAttitude( thePlayer ) == AIA_Hostile )
	{
		parent.validTargetsInArea.Erase( parent.validTargetsInArea.FindFirst( target ) );
		target.SignalGameplayEventParamObject('LeavesYrden', parent );
	}

	if ( parent.validTargetsInArea.Size() <= 0 )
	{
		parent.StopEffect( parent.effects[parent.fireMode].activateEffect );
	}

	if( target && parent.allActorsInArea.Contains( target ) )	//modSigns: Bugfix 117, an actor that left is no longer shot (ActivateShock refills its targets from this list)
	{	//modSigns
		parent.allActorsInArea.Erase( parent.allActorsInArea.FindFirst( target ) );	//modSigns
	}	//modSigns
}

// The turret's shot: legacy's damage bonus and hit reaction.
@replaceMethod(W3YrdenEntityStateYrdenShock)
function YrdenTrapHitEnemy(entity : CEntity, hitPosition : Vector)
{
	var component : CComponent;
	var targetActor, casterActor : CActor;
	var action : W3DamageAction;
	var player : W3PlayerWitcher;
	var skillType : ESkill;
	var skillLevel, i : int;
	var damageBonusFlat : float;
	var damages : array<SRawDamage>;
	var glyphwordY : W3YrdenEntity;


	parent.StopEffect( parent.effects[parent.fireMode].castEffect );
	parent.PlayEffect( parent.effects[parent.fireMode].shootEffect );
	parent.PlayEffect( parent.effects[parent.fireMode].castEffect );

	targetActor = (CActor)entity;
	if(targetActor)
	{
		component = targetActor.GetComponent('torso3effect');
		if ( component )
		{
			parent.PlayEffect( parent.effects[parent.fireMode].shootEffect, component );
		}
	}

	if(!targetActor || !component)
	{
		parent.PlayEffect( parent.effects[parent.fireMode].shootEffect, entity );
	}



		parent.charges -= 1;


	casterActor = caster.GetActor();
	if ( casterActor && (CGameplayEntity)entity)
	{

		action =  new W3DamageAction in theGame.damageMgr;
		player = caster.GetPlayer();
		skillType = virtual_parent.GetSkill();
		//modSigns: removed the skill level read here (cached by GetSignStats)


		action.Initialize( casterActor, (CGameplayEntity)entity, this, casterActor.GetName()+"_sign_yrden_alt", EHRT_Light, CPS_SpellPower, false, false, true, false, 'yrden_shock', 'yrden_shock', 'yrden_shock', 'yrden_shock');	//modSigns: legacy's source name
		virtual_parent.InitSignDataForDamageAction(action);
		action.hitLocation = hitPosition;
		action.SetCanPlayHitParticle(true);


		if(parent.gmTurretDamageBonus > 0)	//modSigns: Magic Trap's levels and Yrden Intensity (GetSignStats)
		{
			action.GetDTs(damages);
			//modSigns: removed 5.x's damage_bonus_flat_after_1 read
			action.ClearDamage();

			for(i=0; i<damages.Size(); i+=1)
			{
				damages[i].dmgVal += parent.gmTurretDamageBonus;	//modSigns
				action.AddDamage(damages[i].dmgType, damages[i].dmgVal);
			}
		}


		theGame.damageMgr.ProcessAction( action );
		((CGameplayEntity)entity).OnYrdenHit( casterActor );	//modSigns: the hit reaction after the shot (legacy; 5.x on entering the area)
	}
	else
	{
		entity.PlayEffect( 'yrden_shock' );
	}

	if(casterActor.HasAbility('Glyphword 15 _Stats', true))
	{
		glyphwordY = (W3YrdenEntity)theGame.CreateEntity(GetWitcherPlayer().GetSignTemplate(ST_Yrden), entity.GetWorldPosition(), entity.GetWorldRotation() );
		glyphwordY.Init(caster, parent, true, true);
		glyphwordY.CacheActionBuffsFromSkill();
		glyphwordY.GotoState( 'YrdenSlowdown' );
	}
}

// Supercharged Glyphs' bonus on 5.x's drain effect, which no longer drains (legacy's rework).
@addField(W3Effect_YrdenHealthDrain)
var gmDmgBonus : float;
@addField(W3Effect_YrdenHealthDrain)
var gmLastFx : float;

@addMethod(W3Effect_YrdenHealthDrain)
function GMSetDmgBonus(b : float)
{
	gmDmgBonus = b;
	timeLeft = initialDuration;
}

@addMethod(W3Effect_YrdenHealthDrain)
function GMGetDmgBonus() : float
{
	return gmDmgBonus;
}

// The shock effect on a hit, at most once a second (legacy).
@addMethod(W3Effect_YrdenHealthDrain)
function GMPlayFX()
{
	if(theGame.GetEngineTimeAsSeconds() - gmLastFx > 1.f)
	{
		target.PlayEffect('yrden_shock');
		gmLastFx = theGame.GetEngineTimeAsSeconds();
	}
}

@replaceMethod(W3Effect_YrdenHealthDrain)
function SetEffectValue()
{
	effectValue.valueAdditive = 0;	//modSigns: no drain (5.x: 10/s + 0.1% of max health per level, x0.15 on bosses)
	effectValue.valueMultiplicative = 0;	//modSigns
	effectValue.valueBase = 0;	//modSigns
}

@replaceMethod(W3Effect_YrdenHealthDrain)
function OnUpdate(dt : float)
{
	super.OnUpdate(dt);
	//modSigns: removed the periodic shock effect (played on hits instead)
}
