// SKL-08: Aard's knockdown, legacy's in both trees (docs/features/skl.md). The knockdown applicator
// (every knockdown source: Aard, Rend, counters, NPC charges) rolls as legacy:
// - first knockdown or stagger: the chance is 33% (Geralt; magic_1's starting_knockdown_chance) or 50%
//   (others), x (1 + the sign intensity bonus of the power left after the target's force resistance
//   points), x (1 - its force resistance %), between 10% and 100% (99% at 500% intensity);
// - then heavy knockdown (15%, plus Aard Intensity when Geralt casts Aard: classic magic_s12, 0.03 per
//   level, or the new tree's magic_s39, 0.05 per level, D58) or knockdown, or long stagger (66%) or
//   stagger;
// - then the severity rules (GMModifyKnockdownSeverity): weak to Aard and flying enemies are always
//   knocked down (heavily, but contract monsters), low-stamina targets one step (below 30%) or two (below
//   10%) up, shielded enemies and huge monsters two steps down to no less than a long stagger,
//   immunities step down, contract monsters never heavily.
// 5.x's thresholds by power and level difference, and its hit_severity reduction, are gone.

// Aard Intensity: the classic magic_s12 or the new tree's magic_s39 (D58); S_SUndefined if none.
@addMethod(W3PlayerWitcher)
function GMAardIntensitySkill() : ESkill
{
	if(CanUseSkill(S_Magic_s12))
		return S_Magic_s12;
	if(CanUseSkill(S_Magic_s39))
		return S_Magic_s39;
	return S_SUndefined;
}

// The target's resistance to this effect in points (legacy's resistancePts).
@addMethod(CBaseGameplayEffect)
function GMResistancePoints() : float
{
	var points, percents : float;

	target.GetResistValue(resistStat, points, percents);
	return points;
}

@replaceMethod(W3Effect_KnockdownTypeApplicator)
function OnEffectAdded(optional customParams : W3BuffCustomParams)
{
	var appliedType			: EEffectType;	//modSigns
	var sp, abl				: SAbilityAttributeValue;	//modSigns
	var params				: SCustomEffectParams;	//modSigns
	var witcher				: W3PlayerWitcher;	//modSigns
	var aardPower, chance, startingChance	: float;	//modSigns

	if(isOnPlayer)
	{
		thePlayer.OnRangedForceHolster( true, true, false );
	}

	//modSigns: removed 5.x's power thresholds (shields, huge monsters, weak to Aard, level difference)
	if(effectValue.valueMultiplicative + effectValue.valueAdditive > 0)	//modSigns: the power: the effect's value (environment) or the creator's power stat
		sp = effectValue;	//modSigns
	else	//modSigns
		sp = creatorPowerStat;	//modSigns
	aardPower = GMSignPowerStatToPowerBonus(MaxF(0.0, sp.valueMultiplicative - GMResistancePoints() / 100));	//modSigns: intensity bonus after resistance points
	witcher = (W3PlayerWitcher)GetCreator();	//modSigns
	if(witcher)	//modSigns
		startingChance = CalculateAttributeValue(witcher.GetSkillAttributeValue(S_Magic_1, 'starting_knockdown_chance', false, false));	//modSigns
	else	//modSigns
		startingChance = 0.5;	//modSigns
	chance = ClampF(startingChance * (1 + aardPower) * (1 - resistance), 0.1, 1.0);	//modSigns
	if(witcher)	//modSigns: MUT-13, Metamorphosis
		chance *= witcher.GMMutation12ChanceMult();	//modSigns
	if(RandF() < chance)	//modSigns: knockdown, then heavy knockdown
	{	//modSigns
		chance = 0.15;	//modSigns
		if(witcher && witcher.GetCurrentlyCastSign() == ST_Aard && witcher.GMAardIntensitySkill() != S_SUndefined)	//modSigns: Aard Intensity, either tree
		{	//modSigns
			abl = witcher.GetSkillAttributeValue(witcher.GMAardIntensitySkill(), 'heavy_knockdown_chance_bonus', false, false);	//modSigns
			chance += abl.valueMultiplicative * witcher.GetSkillLevel(witcher.GMAardIntensitySkill());	//modSigns
		}	//modSigns
		if(RandF() < chance)	//modSigns
			appliedType = EET_HeavyKnockdown;	//modSigns
		else	//modSigns
			appliedType = EET_Knockdown;	//modSigns
	}	//modSigns
	else if(RandF() < 0.66)	//modSigns: stagger, then long stagger
		appliedType = EET_LongStagger;	//modSigns
	else	//modSigns
		appliedType = EET_Stagger;	//modSigns

	appliedType = GMModifyKnockdownSeverity(target, GetCreator(), appliedType);	//modSigns: legacy's ModifyKnockdownSeverity (5.x: ModifyHitSeverityBuff)

	params.effectType = appliedType;
	params.creator = GetCreator();
	params.sourceName = sourceName;
	params.isSignEffect = isSignEffect;
	params.customPowerStatValue = creatorPowerStat;
	params.customAbilityName = customAbilityName;
	params.duration = customDuration;
	params.effectValue = customEffectValue;

	target.AddEffectCustom(params);

	isActive = true;
	duration = 0;
}

// Legacy's ModifyKnockdownSeverity, for the knockdown applicator only (alternate Quen is handled by
// the effect manager's rules, skills/quen.ws).
function GMModifyKnockdownSeverity(target : CActor, attacker : CGameplayEntity, type : EEffectType) : EEffectType
{
	var severity : int;
	var npcTarget : CNewNPC;
	var witcherTarget : W3PlayerWitcher;

	npcTarget = (CNewNPC)target;
	witcherTarget = (W3PlayerWitcher)target;

	// weak to Aard and flying enemies are knocked down
	if(target.HasAbility('WeakToAard') || (npcTarget && npcTarget.IsFlying()))
	{
		if((W3MonsterHuntNPC)npcTarget)
			return EET_Knockdown;
		return EET_HeavyKnockdown;
	}

	switch(type)
	{
		case EET_HeavyKnockdown :	severity = 4; break;
		case EET_Knockdown :		severity = 3; break;
		case EET_LongStagger :		severity = 2; break;
		case EET_Stagger :			severity = 1; break;
		default :					return EET_Undefined;
	}

	// low stamina: one step up below 30%, two below 10%
	if(target.GetStaminaPercents() < 0.3)
	{
		severity += 1;
		if(target.GetStaminaPercents() < 0.1)
			severity += 1;
	}


	// shields and huge monsters: two steps down, to no less than a long stagger
	if(npcTarget && npcTarget.IsShielded(attacker) && severity > 2)
		severity -= 2;
	if(target.HasAbility('mon_type_huge') && severity > 2)
		severity -= 2;

	// immunities
	if(severity >= 4 && target.IsImmuneToBuff(EET_HeavyKnockdown))		severity = 3;
	if(severity == 3 && target.IsImmuneToBuff(EET_Knockdown))			severity = 2;
	if(severity == 2 && target.IsImmuneToBuff(EET_LongStagger))			severity = 1;
	if(severity == 1 && target.IsImmuneToBuff(EET_Stagger))				severity = 0;

	// no heavy knockdown for contract monsters
	if((W3MonsterHuntNPC)target && severity >= 4)
		severity = 3;

	if(severity >= 4)
		return EET_HeavyKnockdown;
	else if(severity == 3)
		return EET_Knockdown;
	else if(severity == 2)
		return EET_LongStagger;
	else if(severity == 1)
		return EET_Stagger;
	return EET_Undefined;
}

// D18: no diminishing returns for repeated Aard or Igni hits (legacy; project owner, 2026-10-09). 5.x's
// tier is always the first: Aard's step-down (long stagger, stagger, nothing within 1 s) and Igni's
// burn-chance cut never apply.
@replaceMethod(CNewNPC)
function SignDRRegisterAard() : int
{
	return 1;	//modSigns: D18, no diminishing returns
}

@replaceMethod(CNewNPC)
function SignDRRegisterIgni( isChannel : bool ) : int
{
	return 1;	//modSigns: D18, no diminishing returns
}

// Shock Wave (D20): legacy's force damage on every hostile living enemy Aard hits, scaling with sign
// intensity through the damage formula: classic magic_s6 60 per level (5 levels), new tree magic_s33 100
// per level. Added to the Aard projectile's action as the parent sets it up; 5.x's new-tree direct
// damage (1% of Geralt's maximum Vitality per level) is 0 in the XML.
@wrapMethod(W3SignProjectile)
function ProcessCollision( collider : CGameplayEntity, pos, normal : Vector )
{
	var victim : CActor;
	var skill : ESkill;
	var damage : float;

	wrappedMethod(collider, pos, normal);
	victim = (CActor)collider;
	if((W3AardProjectile)this && action && victim && victim.IsAlive() && IsRequiredAttitudeBetween(victim, caster, true))
	{
		if(owner.CanUseSkill(S_Magic_s06))
			skill = S_Magic_s06;
		else if(owner.CanUseSkill(S_Magic_s33))
			skill = S_Magic_s33;
		if(skill != S_SUndefined)
		{
			damage = GetWitcherPlayer().GetSkillLevel(skill) * CalculateAttributeValue(owner.GetSkillAttributeValue(skill, theGame.params.DAMAGE_NAME_FORCE, false, true));
			action.AddDamage(theGame.params.DAMAGE_NAME_FORCE, damage);
		}
	}
}

// Aard Sweep (magic_s1, both trees, 3 levels): the intensity penalty is 40%, 20% and 0% by level
// (legacy's fix of the formula; 5.x: 30% cut by (level + 1) x 15% of itself).
@replaceMethod(W3PlayerWitcher)
function GetTotalSignSpellPower(signSkill : ESkill) : SAbilityAttributeValue
{
	var sp : SAbilityAttributeValue;
	var penalty : SAbilityAttributeValue;
	var penaltyReduction : float;
	var penaltyReductionLevel : int;
	var abilityFire	: SAbilityAttributeValue;
	var fireDmgMult : float;

	
	sp = GetSkillAttributeValue(signSkill, PowerStatEnumToName(CPS_SpellPower), true, true);

	
	if ( signSkill == S_Magic_s01 )
	{
		
		//modSigns: removed 5.x's reduction ((level + 1) x the attribute with its skill multipliers, of the penalty)
		penaltyReductionLevel = GetSkillLevel(S_Magic_s01) - 1;	//modSigns: SKL-08, legacy's fix: the penalty, already applied, is cut by the attribute per level above 1 (40/20/0%)
		if(penaltyReductionLevel > 0)
		{
			penaltyReduction = penaltyReductionLevel * CalculateAttributeValue(GetSkillAttributeValue(S_Magic_s01, 'spell_power_penalty_reduction', false, false));	//modSigns
			sp.valueMultiplicative += penaltyReduction;	//modSigns
		}
	}

	
	if(signSkill == S_Magic_1 || signSkill == S_Magic_s01)
	{
		sp += GetAttributeValue('spell_power_aard');
	}
	else if(signSkill == S_Magic_2 || signSkill == S_Magic_s02 || signSkill == S_Magic_s28)
	{
		sp += GetAttributeValue('spell_power_igni');
	}
	else if(signSkill == S_Magic_3 || signSkill == S_Magic_s03)
	{
		sp += GetAttributeValue('spell_power_yrden');
	}
	else if(signSkill == S_Magic_4 || signSkill == S_Magic_s04)
	{
		sp += GetAttributeValue('spell_power_quen');
	}
	else if(signSkill == S_Magic_5 || signSkill == S_Magic_s05 || signSkill == S_Magic_s31)
	{
		sp += GetAttributeValue('spell_power_axii');
	}

	
	ApplyMutation10StatBoost( sp );

	return sp;
}

// Finishers (legacy): only a heavy knockdown (or a forced activation) enables a finisher; the
// ResistFinisher rule (no finisher above 20% health) and the behaviour trees' DisableFinisher events
// (sirens excepted) are gone.
@replaceMethod(CBehTreeTaskCSEffect)
function ShouldEnableFinisher() : bool
{
	var actor : CActor;
	actor = GetActor();

	//modSigns: removed 5.x's check for knockdown, heavy knockdown and ragdoll
	if( (CSType == ECST_HeavyKnockdown || forceFinisherActivation) && GetWitcherPlayer() && GetAttitudeBetween( actor, thePlayer ) == AIA_Hostile && actor.IsVulnerable() && actor.GetComponent( "Finish" ) )	//modSigns: heavy knockdowns only
	{
		//modSigns: removed the ResistFinisher rule
		return true;
	}
	return false;
}

@wrapMethod(CBehTreeTaskCSEffect)
function OnGameplayEvent( eventName : name ) : bool
{
	if( eventName == 'DisableFinisher' )
		return true;
	return wrappedMethod( eventName );
}

// D25: Aard deflects boulders at 0.7 of their speed whatever the skills (legacy, as 1.32; 5.x: 0.1
// without Aard Sweep or Aard Intensity, 0.3/0.5/0.7 by their level).
@replaceMethod(W3BoulderProjectile)
function OnAardHit( sign : W3AardProjectile )
{
	var rigidMesh		 	: CMeshComponent;
	var randAngleOffset 	: float;
	//modSigns: removed var level

	super.OnAardHit(sign);

	StopProjectile();

	rigidMesh = (CMeshComponent)this.GetComponentByClassName('CRigidMeshComponent');

	if ( rigidMesh )
	{
		rigidMesh.SetEnabled( true );
	}
	else
	{
		randAngleOffset = RandRangeF( 10, -10 );
		//modSigns: removed 5.x's speed by the level of Aard Sweep or Aard Intensity
		this.bounceOfVelocityPreserve = 0.7;	//modSigns: D25
		this.BounceOff( VecFromHeading( thePlayer.GetHeading() + randAngleOffset ),this.GetWorldPosition() );
		this.Init( thePlayer );
	}
}

// Aard deflects stones (legacy's copy of the environment projectile's handler) and environment projectiles (1.32's,
// kept by legacy) at 0.7 of their speed whatever the skills, as boulders (D25; AI-C audit F5, owner, 2026-10-29;
// 5.x: 0.1 without Aard Sweep or Aard Intensity, 0.3/0.5/0.7 by their level).
@replaceMethod(W3StoneProjectile)
function OnAardHit( sign : W3AardProjectile )
{
	var rigidMesh		 	: CMeshComponent;
	var randAngleOffset 	: float;
	//modSigns: removed var level

	super.OnAardHit(sign);

	StopProjectile();

	rigidMesh = (CMeshComponent)this.GetComponentByClassName('CRigidMeshComponent');

	if ( rigidMesh )
	{
		rigidMesh.SetEnabled( true );
	}
	else
	{
		randAngleOffset = RandRangeF( 10, -10 );
		//modSigns: removed 5.x's speed by the level of Aard Sweep or Aard Intensity
		this.bounceOfVelocityPreserve = 0.7;	//modSigns: SKL-08 (AI-C audit F5)
		this.BounceOff( VecFromHeading( thePlayer.GetHeading() + randAngleOffset ),this.GetWorldPosition() );
		this.Init( thePlayer );
	}
}

// See W3StoneProjectile's above.
@replaceMethod(W3EnvironmentProjectile)
function OnAardHit( sign : W3AardProjectile )
{
	var rigidMesh		 	: CMeshComponent;
	var randAngleOffset 	: float;
	//modSigns: removed var level

	super.OnAardHit(sign);

	StopProjectile();

	rigidMesh = (CMeshComponent)this.GetComponentByClassName('CRigidMeshComponent');

	if ( rigidMesh )
	{
		rigidMesh.SetEnabled( true );
	}
	else
	{
		randAngleOffset = RandRangeF( 10, -10 );
		//modSigns: removed 5.x's speed by the level of Aard Sweep or Aard Intensity
		this.bounceOfVelocityPreserve = 0.7;	//modSigns: SKL-08 (AI-C audit F5)
		this.BounceOff( VecFromHeading( thePlayer.GetHeading() + randAngleOffset ),this.GetWorldPosition() );
		this.Init( thePlayer );
	}
}
