// SKL-12: Axii, legacy's in both trees (docs/features/skl.md).
// - Casting (W3AxiiEntity): Delusion no longer switches the cast animation (Bugfix 58, it broke Puppet);
//   targets in a 120-degree cone with line of sight (D26; 5.x: 270 degrees without).
// - The effect (OnEnded, replaced): confusion 5 s (animals 30 s); Puppet (classic magic_s5, new tree
//   magic_s31) 10 s + 5 s per level above 1; Domination's penalty only with several targets; Axii
//   Intensity (classic magic_s18 +10% per level, the new tree's magic_s36 +16.67% per level, D58); x (1 + the intensity bonus of the power left after the
//   target's will resistance points); a hostile target resists with its will resistance %; a failed Axii
//   always staggers (5.x: only with Delusion at level 3). Confusion lasts at least 3 s, Puppet 8 s (5.x's
//   Puppet override by Axii Intensity's level is gone; its red-haze durations stay).
// - Confusion gives Geralt +25% crit chance against the target, + Delusion's 25% per level (legacy's
//   CacheCritChanceBonus; 5.x's GetCriticalHitChance reads it), and no longer adds its ability to the
//   target. Every cast of Geralt's slows time to 0.6 while casting, Delusion 0.15 more per level
//   (legacy's SloMo; 5.x slowed Delusion's targets instead).

@replaceMethod(W3AxiiEntity)
function Init( inOwner : W3SignOwner, prevInstance : W3SignEntity, optional skipCastingAnimation : bool, optional notPlayerCast : bool ) : bool
{
	var ownerActor : CActor;
	var prevSign : W3SignEntity;

	ownerActor = inOwner.GetActor();

	if( (CPlayer)ownerActor )
	{
		prevSign = GetWitcherPlayer().GetSignEntity(ST_Axii);
		if(prevSign)
			prevSign.OnSignAborted(true);
	}

	ownerActor.SetBehaviorVariable( 'bStopSign', 0.f );
	//modSigns: removed the Delusion cast upgrade (Bugfix 58: it broke Puppet)
	ownerActor.SetBehaviorVariable( 'bSignUpgrade', 0.f );	//modSigns

	return super.Init( inOwner, prevInstance, skipCastingAnimation );
}

@replaceMethod(W3AxiiEntity)
function SelectTargets()
{
	var projCount, i, j : int;
	var actors, finalActors : array<CActor>;
	var ownerPos : Vector;
	var ownerActor : CActor;
	var actor : CActor;

	if(owner.CanUseSkill(S_Magic_s19))
		projCount = 2;
	else
		projCount = 1;

	targets.Clear();
	actor = (CActor)thePlayer.slideTarget;

	if(actor && IsTargetValid(actor, false))
	{
		targets.PushBack(actor);
		projCount -= 1;

		if(projCount == 0)
			return;
	}

	ownerActor = owner.GetActor();
	ownerPos = ownerActor.GetWorldPosition();

	actors = ownerActor.GetNPCsAndPlayersInCone(15, VecHeading(ownerActor.GetHeadingVector()), 120, 20, , FLAG_OnlyAliveActors + FLAG_TestLineOfSight );	//modSigns: D26, legacy's cone (5.x: 270 degrees without line of sight)

	for(i=actors.Size()-1; i>=0; i-=1)
	{
		if(ownerActor == actors[i] || actor == actors[i] || !IsTargetValid(actors[i], true))
			actors.Erase(i);
	}

	if(actors.Size() > 0)
		finalActors.PushBack(actors[0]);

	for(i=1; i<actors.Size(); i+=1)
	{
		for(j=0; j<finalActors.Size(); j+=1)
		{
			if(VecDistance(ownerPos, actors[i].GetWorldPosition()) < VecDistance(ownerPos, finalActors[j].GetWorldPosition()))
			{
				finalActors.Insert(j, actors[i]);
				break;
			}
		}

		if(j == finalActors.Size())
			finalActors.PushBack(actors[i]);
	}

	if(finalActors.Size() > 0)
	{
		for(i=0; i<projCount; i+=1)
		{
			if(finalActors[i])
				targets.PushBack(finalActors[i]);
			else
				break;
		}
	}
}

// The slow motion while casting (legacy): 0.6 on every cast of Geralt's, Delusion 0.15 lower per level
// (SKL audit F15). Only the cast that set it removes it (legacy's RemoveSloMo ran for NPCs' casts too, and
// an animation multiplier's id can be 0, so the id cannot tell whether it is set).
@addField(W3AxiiEntity)
var gmSpeedMultCauserId : int;
@addField(W3AxiiEntity)
var gmSloMoOn : bool;

@addMethod(W3AxiiEntity)
function GMSloMo()
{
	var speed : float;

	GMRemoveSloMo();
	if(!owner.GetPlayer())
		return;
	speed = 0.6;
	if(owner.CanUseSkill(S_Magic_s17))
		speed -= CalculateAttributeValue(owner.GetSkillAttributeValue(S_Magic_s17, 'slowdown_mod', false, true)) * owner.GetSkillLevel(S_Magic_s17);
	theGame.SetTimeScale(speed, theGame.GetTimescaleSource(ETS_ThrowingAim), theGame.GetTimescalePriority(ETS_ThrowingAim), false);
	gmSpeedMultCauserId = owner.GetActor().SetAnimationSpeedMultiplier(1 / speed * 0.5);
	gmSloMoOn = true;
	theSound.SoundEvent("gui_slowmo_start");
}

@addMethod(W3AxiiEntity)
function GMRemoveSloMo()
{
	if(!gmSloMoOn)
		return;
	theGame.RemoveTimeScale(theGame.GetTimescaleSource(ETS_ThrowingAim));
	owner.GetActor().ResetAnimationSpeedMultiplier(gmSpeedMultCauserId);
	gmSloMoOn = false;
	theSound.SoundEvent("gui_slowmo_end");
}

// Delusion no longer slows the targets (legacy).
@replaceMethod(W3AxiiEntity)
function AddMagic17Effect(target : CActor)
{
	//modSigns: removed (Delusion slows time while casting instead, GMSloMo)
}

@wrapMethod(W3AxiiEntity)
function OnStarted()
{
	GMSloMo();
	wrappedMethod();
}

@wrapMethod(W3AxiiEntity)
function HAXX_AXII_ABORTED()
{
	wrappedMethod();
	GMRemoveSloMo();
}

// Axii Intensity: the classic magic_s18 or the new tree's magic_s36 (D58); S_SUndefined if none.
@addMethod(W3AxiiEntity)
function GMAxiiIntensitySkill() : ESkill
{
	if(owner.CanUseSkill(S_Magic_s18))
		return S_Magic_s18;
	if(owner.CanUseSkill(S_Magic_s36))
		return S_Magic_s36;
	return S_SUndefined;
}

@replaceMethod(W3AxiiEntity)
function OnEnded(optional isEnd : bool)
{
	var buff : EEffectInteract;
	//modSigns: removed conf
	var i : int;
	var duration, durationAnimal, axiiPower, targetPower : SAbilityAttributeValue;	//modSigns: removed fortifiedSignsAtt
	var casterActor : CActor;
	var dur, durAnimals : float;
	var params, staggerParams : SCustomEffectParams;
	var npcTarget : CNewNPC;
	var jobTreeType : EJobTreeType;
	var pts, prc, chance, currentDuration : float;	//modSigns
	//modSigns: removed conf

	casterActor = owner.GetActor();
	ProcessThrow();
	StopEffect(effects[fireMode].throwEffect);

	for(i=0; i<targets.Size(); i+=1)
	{
		RemoveMagic17Effect(targets[i]);
	}

	RemoveMagic17Effect(orientationTarget);

	if(IsAlternateCast())
	{
		thePlayer.LockToTarget( false );
		thePlayer.EnableManualCameraControl( true, 'AxiiEntity' );
	}

	if (targets.Size() > 0 )
	{
		duration = thePlayer.GetSkillAttributeValue(skillEnum, 'duration', false, true);
		durationAnimal = thePlayer.GetSkillAttributeValue(skillEnum, 'duration_animals', false, true);
		if(IsAlternateCast())	//modSigns: Puppet's duration per level above 1 (classic magic_s5, new tree magic_s31)
			duration += thePlayer.GetSkillAttributeValue(skillEnum, 'duration_bonus_after1', false, true) * (thePlayer.GetSkillLevel(skillEnum) - 1);	//modSigns

		duration.valueMultiplicative = 1.0f;
		durationAnimal.valueMultiplicative = 1.0f;

		//modSigns: removed 5.x's Fortify Signs (magic_s36, D58)

		if(owner.CanUseSkill(S_Magic_s19) && targets.Size() > 1)	//modSigns: Domination's penalty only with several targets; not for animals
		{
			duration -= owner.GetSkillAttributeValue(S_Magic_s19, 'duration', false, true) * (3 - owner.GetSkillLevel(S_Magic_s19));
		}

		//modSigns: removed the animals' Fortify Signs and Domination terms
		dur = CalculateAttributeValue(duration);
		durAnimals = CalculateAttributeValue(durationAnimal);
		if(GMAxiiIntensitySkill() != S_SUndefined)	//modSigns: Axii Intensity, either tree
			dur *= 1 + CalculateAttributeValue(owner.GetSkillAttributeValue(GMAxiiIntensitySkill(), 'axii_duration_bonus', false, false)) * owner.GetSkillLevel(GMAxiiIntensitySkill());	//modSigns
		axiiPower = casterActor.GetTotalSignSpellPower(skillEnum);	//modSigns

		params.creator = casterActor;
		params.sourceName = "axii_" + skillEnum;
		params.customPowerStatValue = axiiPower;	//modSigns
		params.isSignEffect = true;

		for(i=0; i<targets.Size(); i+=1)
		{
			npcTarget = (CNewNPC)targets[i];

			if( targets[i].IsAnimal() || npcTarget.IsHorse() )
			{
				currentDuration = durAnimals;	//modSigns
			}
			else
			{
				currentDuration = dur;	//modSigns
			}

			if( owner.GetActor() == thePlayer && GetAttitudeBetween(targets[i], owner.GetActor()) == AIA_Hostile )	//modSigns: a hostile resists with its will resistance %
			{	//modSigns
				targets[i].GetResistValue(CDS_WillRes, pts, prc);	//modSigns
				chance = ClampF(1 - prc, 0.0, 1.0);	//modSigns
			}	//modSigns
			else	//modSigns
			{	//modSigns
				pts = 0;	//modSigns
				chance = 1;	//modSigns
			}	//modSigns
			targetPower = axiiPower;	//modSigns: ARM-15, the Netflix set inside Yrden, per target
			targetPower.valueMultiplicative += GMNetflixYrdenIntensity(casterActor, targets[i], skillEnum);	//modSigns
			params.customPowerStatValue = targetPower;	//modSigns
			params.duration = currentDuration * (1 + GMSignPowerStatToPowerBonus(MaxF(0, targetPower.valueMultiplicative - pts / 100)));	//modSigns: the intensity bonus after will resistance points

			jobTreeType = npcTarget.GetCurrentJTType();

			if ( jobTreeType == EJTT_InfantInHand )
			{
				params.effectType = EET_AxiiGuardMe;
				chance = 1;	//modSigns
			}

			else if(IsAlternateCast() && owner.GetActor() == thePlayer && GetAttitudeBetween(targets[i], owner.GetActor()) == AIA_Friendly)
			{
				params.effectType = EET_Confusion;
				chance = 1;	//modSigns
			}
			else
			{
				params.effectType = actionBuffs[0].effectType;
			}

			RemoveMagic17Effect(targets[i]);

			if( params.duration > 0 && chance > 0 && RandF() < chance )	//modSigns
				buff = targets[i].AddEffectCustom(params);	//modSigns
			else	//modSigns
				buff = EI_Deny;	//modSigns
			if( buff == EI_Pass || buff == EI_Override || buff == EI_Cumulate )
			{
				targets[i].OnAxiied( casterActor );
				//modSigns: removed 5.x's stamina drain on exit with Axii Intensity
			}
			else
			{
				params.duration = 0.5;	//modSigns: a failed Axii always staggers (5.x: with Delusion at level 3)
				staggerParams = params;
				staggerParams.effectType = EET_Stagger;
				buff = targets[i].AddEffectCustom(staggerParams);	//modSigns
				if( buff == EI_Deny || buff == EI_Undefined )	//modSigns
					owner.GetActor().SetBehaviorVariable( 'axiiResisted', 1.f );
			}
		}
	}

	//modSigns: removed 5.x's Delusion-only stagger branch
	casterActor.OnSignCastPerformed(ST_Axii, fireMode);

	GMRemoveSloMo();	//modSigns: the casting slow motion ends with the cast

	super.OnEnded();
}

// Puppet lasts at least 8 s (legacy); 5.x's override by Axii Intensity's level is gone.
@replaceMethod(W3Effect_AxiiGuardMe)
function CalculateDuration(optional setInitialDuration : bool)
{
	super.CalculateDuration(setInitialDuration);

	if ( duration > 0 )
	{
		if (FactsQuerySum("used_red_haze") > 0)
		{
			duration = 8.f;
		}
		else if (FactsQuerySum("used_red_haze_2") > 0)
		{
			duration = 10.f;
		}
		else if (FactsQuerySum("used_red_haze_3") > 0)
		{
			duration = 12.f;
		}
		else	//modSigns: removed 5.x's duration by Axii Intensity's level
			duration = MaxF(8.f, duration);	//modSigns
	}
}

// Confusion: at least 3 s; Geralt's crit chance bonus against the target (legacy).
@wrapMethod(CBaseGameplayEffect)
function CalculateDuration(optional setInitialDuration : bool)
{
	wrappedMethod(setInitialDuration);
	if(effectType == EET_Confusion && duration > 0)
	{
		duration = MaxF(3, duration);
		if(setInitialDuration)
			initialDuration = duration;
	}
}

class W3ConfuseEffect extends W3CriticalEffect
{
	default dontAddAbilityOnTarget = true;	// the ability holds the crit bonus for Geralt, not for the target	//modSigns
}

@addMethod(W3ConfuseEffect)
function GMCacheCritChanceBonus()
{
	var dm : CDefinitionsManagerAccessor;
	var min, max : SAbilityAttributeValue;

	dm = theGame.GetDefinitionsManager();
	dm.GetAbilityAttributeValue(abilityName, 'critical_hit_chance', min, max);
	criticalHitBonus = CalculateAttributeValue(GetAttributeRandomizedValue(min, max));
	if(!isOnPlayer && GetCreator() == thePlayer && isSignEffect && thePlayer.CanUseSkill(S_Magic_s17))
		criticalHitBonus += CalculateAttributeValue(thePlayer.GetSkillAttributeValue(S_Magic_s17, 'crit_chance_bonus', false, true)) * thePlayer.GetSkillLevel(S_Magic_s17);
}

@wrapMethod(W3ConfuseEffect)
function OnEffectAdded(optional customParams : W3BuffCustomParams)
{
	wrappedMethod(customParams);
	if(criticalHitBonus <= 0)
		GMCacheCritChanceBonus();
}

// ---- Damage ends confusion and knockdowns; the instant kill on the confused (legacy) ----
// - A hit that deals damage (not damage over time) to a living NPC that is not finished or dismembered
//   ends its confusion and its knockdown or heavy knockdown, whatever their source, and Geralt's hits end
//   Puppet (5.x: nothing of it).
// - A confused or puppeted living enemy (not a contract monster, not immune to instant kills) hit by
//   Geralt can die at once: 1% + 33.4% x the share of its health the hit took, x (1 + the intensity bonus
//   of the confusion's caster), one roll per hit; a human dies by a finisher, anything else by
//   dismemberment (5.x: a 75% finisher chance on confused or puppeted humans, plus level difference).
// - Legacy's finisher rules on death: always on a lone enemy, a forced finisher or with Bloodbath, never on
//   a deadly-level enemy, always on a very low-level one, else the base chance; dismemberment needs a dead
//   victim but for the instant kill. Deadly Counter's kill (MUT-06) takes the same paths, mutations/deadlyCounter.ws.

@addField(W3DamageManagerProcessor)
var gmConfusionInstakillTested : bool;

@addMethod(W3DamageManagerProcessor)
function GMIsAxiiInstakillTarget() : bool
{
	return !playerVictim && actorVictim && !((W3MonsterHuntNPC)actorVictim) && !actorVictim.IsImmuneToInstantKill() && actorVictim.IsAlive() && attackAction && attackAction.DealsAnyDamage() && (actorVictim.HasBuff(EET_Confusion) || actorVictim.HasBuff(EET_AxiiGuardMe));
}

// 0 to 100 (%). The victim's health before the hit is its health now plus the damage dealt.
@addMethod(W3DamageManagerProcessor)
function GMGetAxiiInstakillChance() : int
{
	var chance : int;
	var victimHealth, damageSeverity : float;
	var sp : SAbilityAttributeValue;
	var conf : W3ConfuseEffect;

	if(!GMIsAxiiInstakillTarget())
		return 0;
	victimHealth = actorVictim.GetHealth() + action.GetDamageDealt();
	damageSeverity = 0;
	if(victimHealth > 0)
		damageSeverity = ClampF(action.GetDamageDealt() / victimHealth, 0.f, 1.f);
	chance = 1 + RoundMath(damageSeverity * 33.4);
	conf = (W3ConfuseEffect)actorVictim.GetBuff(EET_Confusion);
	if(conf && conf.IsSignEffect())
	{
		sp = conf.GetCreatorPowerStat();
		chance = RoundMath(chance * (1 + GMSignPowerStatToPowerBonus(sp.valueMultiplicative)));
	}
	return chance;
}

@addMethod(W3DamageManagerProcessor)
function GMCanDismemberAliveTarget( victim : CActor ) : bool
{
	return ( victim.HasBuff(EET_Confusion) || victim.HasBuff(EET_AxiiGuardMe) || gmMutation8Triggered )	// MUT-06, Deadly Counter
		&& victim.IsVulnerable()
		&& !victim.HasAbility('DisableDismemberment')
		&& !victim.HasAbility('InstantKillImmune');
}

@replaceMethod(W3DamageManagerProcessor)
function ProcessActionReaction(wasFrozen : bool, wasAlive : bool)
{
	var dismemberExplosion 			: bool;
	var damageName 					: name;
	var damage 						: array<SRawDamage>;
	var points, percents, hp, dmg 	: float;
	var counterAction 				: W3DamageAction;
	var moveTargets					: array<CActor>;
	var i 							: int;
	var canPerformFinisher			: bool;
	var canDismember : bool;	//modSigns
	var weaponName					: name;
	var npcVictim					: CNewNPC;
	var toxicCloud					: W3ToxicCloud;
	var playsNonAdditiveAnim		: bool;
	var bleedCustomEffect 			: SCustomEffectParams;


	var min, max 					: SAbilityAttributeValue;
	var minDmg 						: float;


	if(!actorVictim)
		return;

	gmConfusionInstakillTested = false;	//modSigns: one instant-kill roll per hit
	npcVictim = (CNewNPC)actorVictim;

	canPerformFinisher = CanPerformFinisher(actorVictim);
	canDismember = CanDismember(wasFrozen, dismemberExplosion, weaponName);	//modSigns: also a living victim (the instant kill)
	if(canPerformFinisher && thePlayer.HasBuff(EET_Blizzard) && ((W3Potion_Blizzard)thePlayer.GetBuff(EET_Blizzard)).IsSlowMoActive())	//modSigns: no finishers during Blizzard's slow motion
		canPerformFinisher = false;	//modSigns

	if( actorVictim.IsAlive() && !canPerformFinisher && !canDismember && !gmMutation8Triggered )	//modSigns: MUT-06, Deadly Counter's kill too
	{

		if(!action.IsDoTDamage() && action.DealtDamage())
		{
			if ( actorAttacker && npcVictim)
			{
				npcVictim.NoticeActorInGuardArea( actorAttacker );
			}	//modSigns
			if ( !playerVictim )	//modSigns: damage ends confusion and knockdowns, Geralt's hits end Puppet
			{	//modSigns
				actorVictim.RemoveAllBuffsOfType(EET_Confusion);	//modSigns
				actorVictim.RemoveAllBuffsOfType(EET_Knockdown);	//modSigns
				actorVictim.RemoveAllBuffsOfType(EET_HeavyKnockdown);	//modSigns
				if( playerAttacker )	//modSigns
					actorVictim.RemoveAllBuffsOfType(EET_AxiiGuardMe);	//modSigns
			}	//modSigns


			if(playerAttacker && action.IsActionMelee() && !playerAttacker.GetInventory().IsItemFists(weaponId) && playerAttacker.IsLightAttack(attackAction.GetAttackName()) && playerAttacker.CanUseSkill(S_Sword_s05))
			{
				bleedCustomEffect.effectType = EET_Bleeding;
				bleedCustomEffect.creator = playerAttacker;
				bleedCustomEffect.sourceName = SkillEnumToName(S_Sword_s05);



				theGame.GetDefinitionsManager().GetAbilityAttributeValue( 'BleedingEffect', 'DirectDamage', min, max );
				bleedCustomEffect.effectValue = min;
				minDmg = CalculateAttributeValue(playerAttacker.GetSkillAttributeValue(S_Sword_s05, 'dmg_per_sec', false, true)) * playerAttacker.GetSkillLevel(S_Sword_s05);
				dmg = bleedCustomEffect.effectValue.valueAdditive + (bleedCustomEffect.effectValue.valueMultiplicative * actorVictim.GetMaxHealth());

				if ( dmg < minDmg )
				{
					bleedCustomEffect.effectValue.valueAdditive += minDmg - dmg;
				}



				actorVictim.AddEffectCustom(bleedCustomEffect);
			}
		}


		if(actorVictim && wasAlive)
		{
			playsNonAdditiveAnim = actorVictim.ReactToBeingHit( action );
		}
	}
	else
	{

		if( actorVictim.IsAlive() && (canPerformFinisher || canDismember || gmMutation8Triggered) )	//modSigns: the instant kill and Deadly Counter (MUT-06): the living victim dies first
			actorVictim.Kill( 'Finisher', false, thePlayer );	//modSigns

		if( !canPerformFinisher && canDismember )	//modSigns
		{
			ProcessDismemberment(wasFrozen, dismemberExplosion);
			toxicCloud = (W3ToxicCloud)action.causer;

			if(toxicCloud && toxicCloud.HasExplodingTargetDamages())
				ProcessToxicCloudDismemberExplosion(toxicCloud.GetExplodingTargetDamages());


			if(IsRequiredAttitudeBetween(thePlayer, action.victim, true))
			{
				moveTargets = thePlayer.GetMoveTargets();
				for ( i = 0; i < moveTargets.Size(); i += 1 )
				{
					if ( moveTargets[i].IsHuman() )
						moveTargets[i].DrainMorale(20.f);
				}
			}
		}

		else if ( canPerformFinisher )
		{
			//modSigns: removed the kill here (done above)

			thePlayer.AddTimer( 'DelayedFinisherInputTimer', 0.1f );
			thePlayer.SetFinisherVictim( actorVictim );
			thePlayer.CleanCombatActionBuffer();
			thePlayer.OnBlockAllCombatTickets( true );

			if( actorVictim.WillBeUnconscious() )
			{
				actorVictim.SetBehaviorVariable( 'prepareForUnconsciousFinisher', 1.0f );
				actorVictim.ActionRotateToAsync( thePlayer.GetWorldPosition() );
			}

			moveTargets = thePlayer.GetMoveTargets();

			for ( i = 0; i < moveTargets.Size(); i += 1 )
			{
				if ( actorVictim != moveTargets[i] )
					moveTargets[i].SignalGameplayEvent( 'InterruptChargeAttack' );
			}

			if 	( 	theGame.GetInGameConfigWrapper().GetVarValue('Gameplay', 'AutomaticFinishersEnabled' ) == "true"
				|| ( (W3PlayerWitcher)playerAttacker && GetWitcherPlayer().IsMutationActive( EPMT_Mutation3 ) )

				)
			{
				actorVictim.AddAbility( 'ForceFinisher', false );
			}

			if ( actorVictim.HasTag( 'ForceFinisher' ) )
				actorVictim.AddAbility( 'ForceFinisher', false );

			actorVictim.SignalGameplayEvent( 'ForceFinisher' );
		}
		else if ( weaponName == 'fists' && npcVictim )
		{
			npcVictim.DisableAgony();
		}

		thePlayer.FindMoveTarget();
	}

	if( attackAction.IsActionMelee() )
	{
		actorAttacker.SignalGameplayEventParamObject( 'HitActionReaction', actorVictim );
		actorVictim.OnHitActionReaction( actorAttacker, weaponName );
	}


	actorVictim.ProcessHitSound(action, playsNonAdditiveAnim || !actorVictim.IsAlive());



	if(action.IsCriticalHit() && action.DealtDamage() && !actorVictim.IsAlive() && actorAttacker == thePlayer )
		GCameraShake( 0.5, true, actorAttacker.GetWorldPosition(), 10 );


	if( attackAction && npcVictim && npcVictim.IsShielded( actorAttacker ) && attackAction.IsParried() && attackAction.GetAttackName() == 'attack_heavy' &&  npcVictim.GetStaminaPercents() <= 0.1 )
	{
		npcVictim.ProcessShieldDestruction();
	}


	if( actorVictim && action.CanPlayHitParticle() && ( action.DealsAnyDamage() || (attackAction && attackAction.IsParried()) ) )
		actorVictim.PlayHitEffect(action);


	if( action.victim.HasAbility('mon_nekker_base') && !actorVictim.CanPlayHitAnim() && !((CBaseGameplayEffect) action.causer) )
	{

		actorVictim.PlayEffect(theGame.params.LIGHT_HIT_FX);
		actorVictim.SoundEvent("cmb_play_hit_light");
	}


	if(actorVictim && playerAttacker && action.IsActionMelee() && thePlayer.inv.IsItemFists(weaponId) )
	{
		actorVictim.SignalGameplayEvent( 'wasHitByFists' );

		if(MonsterCategoryIsMonster(victimMonsterCategory))
		{
			if(!victimCanBeHitByFists)
			{
				playerAttacker.ReactToReflectedAttack(actorVictim);
			}
			else
			{
				actorVictim.GetResistValue(CDS_PhysicalRes, points, percents);

				if(percents >= theGame.params.MONSTER_RESIST_THRESHOLD_TO_REFLECT_FISTS)
					playerAttacker.ReactToReflectedAttack(actorVictim);
			}
		}
	}


	ProcessSparksFromNoDamage();


	if(attackAction && attackAction.IsActionMelee() && actorAttacker && playerVictim && attackAction.IsCountered() && playerVictim == GetWitcherPlayer())
	{
		GetWitcherPlayer().SetRecentlyCountered(true);
	}

	if(attackAction && attackAction.IsActionMelee() && actorAttacker && playerVictim && attackAction.WasDodged() && playerVictim == GetWitcherPlayer())
	{
		GetWitcherPlayer().SetRecentlyDodged(true);
	}





}

@replaceMethod(W3DamageManagerProcessor)
function CanDismember( wasFrozen : bool, out dismemberExplosion : bool, out weaponName : name ) : bool
{
	var dismember			: bool;
	var dismemberChance 	: int;
	var petard 				: W3Petard;
	var bolt 				: W3BoltProjectile;
	var arrow 				: W3ArrowProjectile;
	var inv					: CInventoryComponent;
	var toxicCloud			: W3ToxicCloud;
	var witcher				: W3PlayerWitcher;
	var i					: int;
	var secondaryWeapon		: bool;

	petard = (W3Petard)action.causer;
	bolt = (W3BoltProjectile)action.causer;
	arrow = (W3ArrowProjectile)action.causer;
	toxicCloud = (W3ToxicCloud)action.causer;

	dismemberExplosion = false;

	if(playerAttacker)
	{
		secondaryWeapon = playerAttacker.inv.ItemHasTag( weaponId, 'SecondaryWeapon' ) || playerAttacker.inv.ItemHasTag( weaponId, 'Wooden' );
	}

	if( actorVictim.HasAbility( 'DisableDismemberment' ) )
	{
		dismember = false;
	}
	else if( actorVictim.HasTag( 'DisableDismemberment' ) )
	{
		dismember = false;
	}
	else if (actorVictim.WillBeUnconscious())
	{
		dismember = false;
	}
	else if (playerAttacker && secondaryWeapon )
	{
		dismember = false;
	}
	else if( actorVictim.IsAlive() && !GMCanDismemberAliveTarget( actorVictim ) )	//modSigns: a living victim only by the instant kill
	{	//modSigns
		dismember = false;	//modSigns
	}	//modSigns
	else if( arrow && !wasFrozen )
	{
		dismember = false;
	}
	else if( !actorVictim.IsAlive() && (actorAttacker.HasAbility( 'ForceDismemberment' )) )	//modSigns: dead victims only
	{
		dismember = true;
		dismemberExplosion = action.HasForceExplosionDismemberment();
	}
	else if( !actorVictim.IsAlive() && (wasFrozen) )	//modSigns: dead victims only
	{
		dismember = true;
		dismemberExplosion = action.HasForceExplosionDismemberment();
	}
	else if( !actorVictim.IsAlive() && ((petard && petard.DismembersOnKill()) || (bolt && bolt.DismembersOnKill())) )	//modSigns: dead victims only
	{
		dismember = true;
		dismemberExplosion = action.HasForceExplosionDismemberment();
	}
	else if( !actorVictim.IsAlive() && ((W3Effect_YrdenHealthDrain)action.causer) )	//modSigns: dead victims only
	{
		dismember = true;
		dismemberExplosion = true;
	}
	else if( !actorVictim.IsAlive() && (toxicCloud && toxicCloud.HasExplodingTargetDamages()) )	//modSigns: dead victims only
	{
		dismember = true;
		dismemberExplosion = true;
	}

	else
	{
		inv = actorAttacker.GetInventory();
		weaponName = inv.GetItemName( weaponId );

		if( attackAction
			&& !inv.IsItemSteelSwordUsableByPlayer(weaponId)
			&& !inv.IsItemSilverSwordUsableByPlayer(weaponId)
			&& weaponName != 'polearm'
			&& weaponName != 'fists_lightning'
			&& weaponName != 'fists_fire' )
		{
			dismember = false;
		}
		else if ( !actorVictim.IsAlive() && action.IsCriticalHit() )	//modSigns
		{
			dismember = true;
			dismemberExplosion = action.HasForceExplosionDismemberment();
		}
		else if ( !actorVictim.IsAlive() && action.HasForceExplosionDismemberment() )	//modSigns
		{
			dismember = true;
			dismemberExplosion = true;
		}

		else if ( !actorVictim.IsAlive() && (weaponName == 'fists_lightning' || weaponName == 'fists_fire') )	//modSigns
		{
			if(RandRange(100) > 75)
				dismember = true;
		}

		else if( gmMutation8Triggered )	//modSigns: MUT-06, Deadly Counter's kill
		{	//modSigns
			dismember = true;	//modSigns
		}	//modSigns
		else if( !gmConfusionInstakillTested && GMIsAxiiInstakillTarget() )	//modSigns: the instant kill on a confused living enemy
		{	//modSigns
			dismemberChance = GMGetAxiiInstakillChance();	//modSigns
			gmConfusionInstakillTested = true;	//modSigns
			dismember = RandRange(100) < Clamp(dismemberChance, 0, 100);	//modSigns
		}	//modSigns
		else if( !actorVictim.IsAlive() )	//modSigns
		{

			dismemberChance = theGame.params.DISMEMBERMENT_ON_DEATH_CHANCE;


			if(playerAttacker && playerAttacker.forceDismember)
			{
				dismemberChance = thePlayer.forceDismemberChance;
				dismemberExplosion = thePlayer.forceDismemberExplosion;
			}


			if(attackAction)
			{
				dismemberChance += RoundMath(100 * CalculateAttributeValue(inv.GetItemAttributeValue(weaponId, 'dismember_chance')));
				dismemberExplosion = attackAction.HasForceExplosionDismemberment();
			}


			witcher = (W3PlayerWitcher)actorAttacker;
			if(witcher && witcher.CanUseSkill(S_Perk_03))
				dismemberChance += RoundMath(100 * CalculateAttributeValue(witcher.GetSkillAttributeValue(S_Perk_03, 'dismember_chance', false, true)));


			if( ( W3PlayerWitcher )playerAttacker && attackAction.IsActionMelee() && GetWitcherPlayer().IsMutationActive(EPMT_Mutation3) )
			{
				if( thePlayer.inv.IsItemSteelSwordUsableByPlayer( weaponId ) || thePlayer.inv.IsItemSilverSwordUsableByPlayer( weaponId ) )
				{
					dismemberChance = 100;
				}
			}

			dismemberChance = Clamp(dismemberChance, 0, 100);

			if (RandRange(100) < dismemberChance)
				dismember = true;
			else
				dismember = false;
		}
		else	//modSigns: a living victim that is not an instant-kill target
			dismember = false;	//modSigns
	}

	return dismember;
}

@replaceMethod(W3DamageManagerProcessor)
function CanPerformFinisher( actorVictim : CActor ) : bool
{
	var finisherChance : int;	//modSigns: legacy's rules (SKL-12)
	var areEnemiesAttacking : bool;	//modSigns
	var i : int;	//modSigns
	var victimToPlayerVector, playerPos : Vector;	//modSigns
	var item : SItemUniqueId;	//modSigns
	var moveTargets : array<CActor>;	//modSigns
	var res : bool;	//modSigns
	var size : int;	//modSigns
	var npc : CNewNPC;	//modSigns

	if ( (W3ReplacerCiri)thePlayer || playerVictim || !playerAttacker || !thePlayer.IsAlive() || thePlayer.isInFinisher || thePlayer.IsInAir() || thePlayer.IsUsingVehicle() )	//modSigns
		return false;	//modSigns
	if ( thePlayer.IsCurrentSignChanneled() )	//modSigns
		return false;	//modSigns
	if ( !attackAction || !attackAction.IsActionMelee() )	//modSigns
		return false;	//modSigns
	if ( thePlayer.IsSecondaryWeaponHeld() || !thePlayer.IsWeaponHeld( 'steelsword') && !thePlayer.IsWeaponHeld( 'silversword') )	//modSigns
		return false;	//modSigns
	item = thePlayer.inv.GetItemFromSlot( 'l_weapon' );	//modSigns
	if ( thePlayer.inv.IsIdValid( item ) )	//modSigns
		return false;	//modSigns
	if ( actorVictim.HasAbility( 'DisableFinishers' ) )	//modSigns
		return false;	//modSigns
	if ( !actorVictim.IsHuman() || actorVictim.IsWoman() )	//modSigns
		return false;	//modSigns
	if ( actorVictim.WillBeUnconscious() && !theGame.GetDLCManager().IsEP2Available() )	//modSigns
		return false;	//modSigns
	if ( actorVictim.IsKnockedUnconscious() || actorVictim.HasBuff( EET_Knockdown ) || actorVictim.HasBuff( EET_Ragdoll ) || actorVictim.HasBuff( EET_Frozen ) )	//modSigns
		return false;	//modSigns
	if ( actorVictim.IsAlive() && !CanPerformFinisherOnAliveTarget(actorVictim) )	//modSigns
		return false;	//modSigns

	moveTargets = thePlayer.GetMoveTargets();	//modSigns
	size = moveTargets.Size();	//modSigns
	playerPos = thePlayer.GetWorldPosition();	//modSigns
	if ( size > 0 )	//modSigns
	{	//modSigns
		areEnemiesAttacking = false;	//modSigns
		for ( i = 0; i < size; i += 1 )	//modSigns
		{	//modSigns
			npc = (CNewNPC)moveTargets[i];	//modSigns
			if ( npc && VecDistanceSquared(playerPos, moveTargets[i].GetWorldPosition()) < 7 && npc.IsAttacking() && npc != actorVictim )	//modSigns
			{	//modSigns
				areEnemiesAttacking = true;	//modSigns
				break;	//modSigns
			}	//modSigns
		}	//modSigns
	}	//modSigns
	victimToPlayerVector = actorVictim.GetWorldPosition() - playerPos;	//modSigns

	npc = (CNewNPC)actorVictim;	//modSigns
	if( gmMutation8Triggered )	//modSigns: MUT-06, Deadly Counter's kill
		finisherChance = 100;	//modSigns
	else if( !gmConfusionInstakillTested && GMIsAxiiInstakillTarget() )	//modSigns: the instant kill on a confused living human (5.x: 75% + level difference)
	{	//modSigns
		finisherChance = GMGetAxiiInstakillChance();	//modSigns
		gmConfusionInstakillTested = true;	//modSigns
	}	//modSigns
	else if( !actorVictim.IsAlive() )	//modSigns
	{	//modSigns
		if( actorVictim.HasAbility('ForceFinisher') || GetWitcherPlayer().IsMutationActive(EPMT_Mutation3) )	//modSigns
			finisherChance = 100;	//modSigns
		else if( npc.currentLevel - thePlayer.GetLevel() >= theGame.params.LEVEL_DIFF_DEADLY )	//modSigns: never on a deadly-level enemy
			finisherChance = 0;	//modSigns
		else if( thePlayer.GetLevel() - npc.currentLevel >= theGame.params.LEVEL_DIFF_DEADLY )	//modSigns: always on a very low-level one
			finisherChance = 100;	//modSigns
		else if( size <= 1 )	//modSigns: always on a lone enemy
			finisherChance = 100;	//modSigns
		else	//modSigns
			finisherChance = theGame.params.FINISHER_ON_DEATH_CHANCE;	//modSigns
	}	//modSigns
	else	//modSigns
		finisherChance = 0;	//modSigns
	finisherChance = Clamp(finisherChance, 0, 100);	//modSigns

	if ( actorVictim.HasTag('ForceFinisher') )	//modSigns
	{	//modSigns
		finisherChance = 100;	//modSigns
		areEnemiesAttacking = false;	//modSigns
	}	//modSigns

	if ( thePlayer.forceFinisher )	//modSigns
		res = true;	//modSigns
	else	//modSigns
		res = ( RandRange(100) < finisherChance && actorVictim.GetAttitude( thePlayer ) == AIA_Hostile	//modSigns
				&& !areEnemiesAttacking && AbsF( victimToPlayerVector.Z ) < 0.4f	//modSigns
				&& ( theGame.GetWorld().NavigationCircleTest( actorVictim.GetWorldPosition(), 2.f ) || actorVictim.HasTag('ForceFinisher') ) );	//modSigns

	if ( res )	//modSigns
	{	//modSigns
		if ( !actorVictim.IsAlive() && !actorVictim.WillBeUnconscious() )	//modSigns
			actorVictim.AddAbility( 'DisableFinishers', false );	//modSigns
	}	//modSigns
	return res;	//modSigns
}
