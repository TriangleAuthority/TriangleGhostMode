// SKL-18: In Combat's Fires and Advanced Pyrotechnics, legacy's in both trees (D38, D39, D61; classic perk_16
// and perk_18, the new tree's perk_44 in place of 5.x's Element of Surprise, whose pool terms are gone, and
// perk_39):
// - In Combat's Fires: Geralt ignores his own bombs' impacts and their effects (5.x gave the impact
//   immunity to perk_39 instead: W3Petard.ProcessEffect, replaced), his own gas clouds, nest explosions and
//   special bolts (5.x's code for perk_16, taken for perk_44 below), and takes half the damage of his own
//   bombs and bolts (the final-damage step, damage/pipeline.ws; legacy also halved their damage to enemies,
//   D38's deviation). Without the perk they deal him full damage (5.x's halving in
//   CR4Player.ReduceDamage is removed below, as legacy).
// - Advanced Pyrotechnics: 0.1 adrenaline per enemy a bomb's impact damages (not damage over time),
//   unaffected by adrenaline-gain bonuses, divided by Cluster Bombs' fragment count (gm_bomb_focus_gain;
//   5.x's focus_gain on perk_18, read by its own code, is 0). 5.x's new-tree free bomb (free_bomb 0) and
//   immunity to Geralt's own bombs are gone. Adrenaline Rush (Mutation 7) doubles or halves the gain
//   (MUT-07, mutations/adrenalineRush.ws).
// See docs/features/skl.md.

@addMethod(W3PlayerWitcher)
function GMHasInCombatsFires() : bool
{
	return CanUseSkill(S_Perk_16) || CanUseSkill(S_Perk_44);
}

// The final-damage multiplier on Geralt for his own bomb or bolt (W3DamageManagerProcessor's final step).
function GMInCombatsFiresDamageMult(attacker : CActor, victim : CActor, causer : IScriptable) : float
{
	var witcher : W3PlayerWitcher;

	witcher = (W3PlayerWitcher)victim;
	if(witcher && attacker == victim && (CThrowable)causer && witcher.GMHasInCombatsFires())
		return 0.5;
	return 1;
}

// Without In Combat's Fires, Geralt's own bombs deal him full damage (legacy removed vanilla's 50% cut,
// "make Perk_16 more valuable"). 5.x body; changes marked //modSigns.
@replaceMethod(CR4Player)
function ReduceDamage( out damageData : W3DamageAction)
{
	super.ReduceDamage(damageData);

	//modSigns: removed 5.x's halving of the damage of Geralt's own bombs (legacy; In Combat's Fires halves it in the final-damage step)
}

// Advanced Pyrotechnics' adrenaline for a bomb's impact damage dealt by Geralt.
@wrapMethod(W3PlayerWitcher)
function OnProcessActionPost(action : W3DamageAction)
{
	var gain : float;
	var skill : ESkill;

	if((W3Petard)action.causer && action.attacker == this && action.victim != this && action.DealsAnyDamage() && !action.IsDoTDamage())
	{
		if(CanUseSkill(S_Perk_18))
			skill = S_Perk_18;
		else if(CanUseSkill(S_Perk_39))
			skill = S_Perk_39;
		else
			skill = S_SUndefined;
		if(skill != S_SUndefined)
		{
			gain = CalculateAttributeValue(GetSkillAttributeValue(skill, 'gm_bomb_focus_gain', false, false));
			if(CanUseSkill(S_Alchemy_s11))
				gain /= GMClusterFragments();	// SKL-15: Cluster Bombs' fragments in either tree (skills/bombs.ws)
		}
	}
	wrappedMethod(action);
	if(gain > 0)
		GainStat(BCS_Focus, gain);
}

// 5.x body; changes marked //modSigns.
@replaceMethod(W3Petard)
function ProcessEffect( optional explosionPosition : Vector, optional collidedTarget : CGameplayEntity )
{
	var targets, additionalTargets : array< CGameplayEntity >;
	var i : int;
	var victimTags, attackerTags : array<name>;
	var dist, camShakeStr, camShakeStrFrac : float;
	var temp, isImmuneToBombDamageBySkill : bool;
	var phantom : CPhantomComponent;
	var meshes : array<CComponent>;
	var mesh : CMeshComponent;
	var npc : CNewNPC;


	if(isInDeepWater || (noLoopEffectIfHitWater && isInWater) )
	{
		Destroy();
		return;
	}


	stopCollisions = true;


	meshes = GetComponentsByClassName('CMeshComponent');
	for(i=0; i<meshes.Size(); i+=1)
	{
		mesh = (CMeshComponent)meshes[i];
		if( !mesh )
		{
			continue;
		}

		mesh.SetVisible(false);
		mesh.SetEnabled(false);
	}



	if(!isCluster && !ignoreBombSkills && (W3PlayerWitcher)GetOwner() && GetWitcherPlayer().CanUseSkill(S_Alchemy_s11) && !HasTag('Snowball') )

	{
		ProcessClusterBombs();
		return;
	}

	if ( explosionPosition == Vector( 0, 0, 0 ) )
	{
		explosionPosition = this.GetWorldPosition();
	}


	explosionPosition = explosionPosition + Vector( 0.0f, 0.0f, 0.1f );
	FindGameplayEntitiesInSphere(targets, explosionPosition, impactParams.range, 1000, '', FLAG_TestLineOfSight);

	if( targets.Size() == 0 )
	{
		explosionPosition = explosionPosition - Vector( 0.0f, 0.0f, 0.2f );
		FindGameplayEntitiesInSphere(targets, explosionPosition, impactParams.range, 1000, '', FLAG_TestLineOfSight);
	}


	if ( itemName == 'Silver Dust Bomb 1' || itemName == 'Silver Dust Bomb 2' || itemName == 'Silver Dust Bomb 3' )
	{
		FindGameplayEntitiesInSphere(additionalTargets, explosionPosition, impactParams.range * 1.5, 1000, 'vampire', FLAG_TestLineOfSight);
	}

	if ( additionalTargets.Size() > 0 )
	{
		for ( i = 0 ; i < additionalTargets.Size() ; i += 1 )
		{
			if ( !targets.Contains( additionalTargets[i] ) )
			{
				targets.PushBack( additionalTargets[i] );
			}
		}
	}

	if(collidedTarget && !targets.Contains(collidedTarget))
		targets.PushBack(collidedTarget);

	if( caster == GetWitcherPlayer() && GetWitcherPlayer().GMHasInCombatsFires() )	//modSigns: In Combat's Fires in either tree (5.x moved this to Advanced Pyrotechnics, perk_39)
	{
		isImmuneToBombDamageBySkill = true;
	}

	for( i=targets.Size() - 1; i >= 0; i -= 1)
	{
		if( !targets[ i ].IsAlive() )
		{
			npc = (CNewNPC)targets[i];

			if(npc)
			{

				npc.SignalGameplayEvent('AbandonAgony');





				if( !npc.HasAbility( 'mon_bear_base' )
					&& !npc.HasAbility( 'mon_golem_base' )
					&& !npc.HasAbility( 'mon_endriaga_base' )
					&& !npc.HasAbility( 'mon_gryphon_base' )
					&& !npc.HasAbility( 'q604_shades' )
					&& !npc.IsAnimal()	)
				{
					npc.SetKinematic(false);
				}
			}
			else
			{

				if( !targets[i].HasTag( 'TargetableByBomb' ) )
				{
					targets.EraseFast(i);
				}
			}

		}

		if ( targets[i] == GetWitcherPlayer() && isImmuneToBombDamageBySkill )
		{
			targets.EraseFast( i );
		}
		else if ( targets[ i ] == this )
		{
			targets.EraseFast(i);
		}

		else if( targets[i] == thePlayer && GetOwner() == thePlayer && (W3WhiteFrost)this )
		{
			targets.EraseFast(i);
		}
	}


	SnapComponents(true);


	ProcessMechanicalEffect(targets, true);


	if(cameraShakeStrMin + cameraShakeStrMax > 0)
	{
		dist = VecDistance(GetOwner().GetWorldPosition(), GetWorldPosition());

		if(dist <= cameraShakeRange)
		{
			camShakeStrFrac = (cameraShakeRange - dist) / cameraShakeRange;
			camShakeStr = cameraShakeStrMin + camShakeStrFrac * (cameraShakeStrMax - cameraShakeStrMin);


			GCameraShake(camShakeStr, true, GetWorldPosition(), impactParams.range * 2);
		}
	}


	theGame.GetBehTreeReactionManager().CreateReactionEventIfPossible( this, 'BombExplosionAction', 10.0, 50.0f, -1, -1, true);


	ProcessEffectPlayFXs(true);

	if(loopDuration > 0)
	{
		ProcessLoopEffect();
	}
	else
	{
		OnTimeEndedFunction(0);
	}
}

// 5.x body; changes marked //modSigns.
@replaceMethod(W3Petard)
function LoopFunction(dt : float)
{
	var i : int;
	var targets : array<CGameplayEntity>;
	var pos : Vector;

	pos = GetWorldPosition();
	pos.Z += loopParams.cylinderOffsetZ;
	targetsSinceLastCheck.Clear();
	FindGameplayEntitiesInCylinder(targets, pos, loopParams.range, loopParams.cylinderHeight, 100000);


	targets.Remove(this);


	if( GetOwner() == thePlayer && GetWitcherPlayer().GMHasInCombatsFires() )	//modSigns: either tree
	{
		targets.Remove( thePlayer );
	}


	targetsSinceLastCheck.Resize(targets.Size());
	for(i=0; i<targetsSinceLastCheck.Size(); i+=1)
	{
		targetsSinceLastCheck[i] = targets[i];
	}


	ProcessMechanicalEffect( targetsSinceLastCheck, false, dt );


	for(i=0; i<previousTargets.Size(); i+=1)
	{
		if(!targetsSinceLastCheck.Contains( previousTargets[i] ))
		{
			ProcessTargetOutOfArea( previousTargets[i] );
		}
	}

	previousTargets.Clear();
	previousTargets = targetsSinceLastCheck;



}

// 5.x body; changes marked //modSigns.
@replaceMethod(CMonsterNestEntityStateExplosion)
function ProcessExplosionDamage()
{
	var damage : W3DamageAction;
	var entitiesInRange : array<CGameplayEntity>;
	var explosionRadius : float = 3.0;
	var damageVal : float = 50.0;
	var i : int;

	FindGameplayEntitiesInSphere( entitiesInRange, parent.GetWorldPosition(), explosionRadius, 100 );
	entitiesInRange.Remove( parent );
	for( i = 0; i < entitiesInRange.Size(); i += 1 )
	{
		if( entitiesInRange[ i ] == thePlayer && GetWitcherPlayer().GMHasInCombatsFires() )	//modSigns: either tree
		{
			continue;
		}

		if( (CActor)entitiesInRange[i] )
		{
			damage = new W3DamageAction in parent;

			damage.Initialize( parent, entitiesInRange[i], NULL, parent, EHRT_None, CPS_Undefined, false, false, false, true );
			damage.AddDamage( theGame.params.DAMAGE_NAME_FIRE, damageVal );
			damage.AddEffectInfo( EET_Burning );
			damage.AddEffectInfo( EET_Stagger );
			theGame.damageMgr.ProcessAction( damage );

			delete damage;
		}
		else
		{
			entitiesInRange[i].OnFireHit( parent );
		}
	}
}

// 5.x body; changes marked //modSigns.
@replaceMethod(W3ExplosiveBolt)
function OnProjectileCollision( pos, normal : Vector, collidingComponent : CComponent, hitCollisionsGroups : array< name >, actorIndex : int, shapeIndex : int )
{
	var ents : array<CGameplayEntity>;
	var i : int;
	var waterZ : float;
	var victim, actor : CActor;
	var shouldPierce : bool;
	var drawableComponent : CDrawableComponent;


	if(wasShotUnderWater && hitCollisionsGroups.Contains( 'Water' ) )
		return true;

	victim = (CActor)collidingComponent.GetEntity();
	SetVictim( victim );

	if ( !CanCollideWithVictim( victim ) )
		return true;

	if( victim.HasTag('AddRagdollCollision') && (CMovingAgentComponent)collidingComponent && !thePlayer.GetDisplayTarget())
	{
		return false;
	}
	if ( !ProcessProjectileRepulsion( pos, normal ) )
	{

		if(wasShotUnderWater)
		{
			waterZ = theGame.GetWorld().GetWaterLevel(pos, true);
			if(waterZ >= pos.Z)
			{

				if(victim)
				{
					super.OnProjectileCollision(pos, normal, collidingComponent, hitCollisionsGroups, actorIndex, shapeIndex);
				}
				else
				{
					StopProjectile();
					isActive = false;
					DestroyAfter(20);
				}

				return true;
			}
		}

		shouldPierce = ShouldPierceVictim( victim );

		if( shouldPierce )
		{
			Mutation9HitFX( victim );
		}
		else
		{
			StopProjectile();
			isActive = false;
		}


		if ( hitCollisionsGroups.Contains( 'Water' ) && ! hitCollisionsGroups.Contains( 'Terrain' ) )
			PlayEffect('explode_water');
		else
			PlayEffect('explosion');


		pos.Z += 0.1f;
		FindGameplayEntitiesInSphere(ents, pos, explosionRange, 100000, , FLAG_TestLineOfSight);


		if(ents.Size() == 0)
		{
			pos.Z -= 0.2f;
			FindGameplayEntitiesInSphere(ents, pos, explosionRange, 100000, , FLAG_TestLineOfSight);
		}


		for( i = ents.Size() - 1 ; i>=0 ; i-=1)
		{
			if(ents[i] == this)
				continue;

			actor = (CActor)ents[i];
			if(actor && !actor.IsAlive())
			{
				continue;
			}

			if( GetAttitudeBetween( thePlayer, actor ) != AIA_Hostile && !actor.IsAnimal() )
			{
				continue;
			}

			if( ents[i] == GetWitcherPlayer() && caster == GetWitcherPlayer() && GetWitcherPlayer().GMHasInCombatsFires()  )	//modSigns: either tree
			{
				continue;
			}

			super.ProcessDamageAction(ents[i], Vector(0,0,0), '');
		}


		theGame.GetBehTreeReactionManager().CreateReactionEventIfPossible( this, 'BombExplosionAction', 10.0, 50.0f, -1, -1, true);


		for(i=0; i<insideToxicClouds.Size(); i+=1)
		{
			if(insideToxicClouds[i] && insideToxicClouds[i].GetCurrentStateName() == 'Armed')
			{
				((W3ToxicCloudStateArmed)(insideToxicClouds[i].GetCurrentState())).Explode(this);
			}
		}

		if( !shouldPierce )
		{
			drawableComponent = (CDrawableComponent)GetComponentByClassName('CDrawableComponent');
			if( drawableComponent )
			{
				drawableComponent.SetVisible(false);
			}

			DestroyAfter(5);
		}
	}
}
