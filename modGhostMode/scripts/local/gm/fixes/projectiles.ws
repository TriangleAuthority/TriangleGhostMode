// FIX-01: enemy projectiles stop at solid objects ("A fix for a bug with NPC projectiles ignoring certain solid
// obstacles like trees (credits to Reaper)", changelist 46; W3EE's "collisions fix"). Human archers' arrows and bolts
// (CBTTaskShoot) and monster projectiles (CBTTaskProjectileAttack and its subclasses) also collide with debris, physics
// objects, foliage, doors and fences (bow shots also destructibles and platforms); the arrow's stop list is in
// DEF-08's OnProjectileCollision replacement (defense/arrowParry.ws), marked FIX-01. See docs/features/fix.md.

// FIX-01: the groups legacy adds to an archer's shot after 1.32's Ragdoll, Terrain and Static (5.x adds Foliage
// itself, later in the body: a duplicate, no effect). A global function, so a test can read the list.
function GMFixShotCollisionGroups(out groups : array<name>)
{
	groups.PushBack('Debris');
	groups.PushBack('Destructible');
	groups.PushBack('RigidBody');
	groups.PushBack('Foliage');
	groups.PushBack('Door');
	groups.PushBack('Platforms');
	groups.PushBack('Fence');
}

// FIX-01: the groups legacy adds to a monster projectile's, after the default groups and after Static in a task's
// custom groups.
function GMFixMonsterProjectileCollisionGroups(out groups : array<name>)
{
	groups.PushBack('Debris');
	groups.PushBack('RigidBody');
	groups.PushBack('Foliage');
	groups.PushBack('Door');
	groups.PushBack('Fence');
}

// 5.x body; changed lines marked //modSigns.
@replaceMethod(CBTTaskShoot)
function ShootProjectile()
{
	var npc 					: CNewNPC = GetNPC();
	var target 					: CNode;
	var targetEntity			: CGameplayEntity;
	var desiredHeadingVec 		: Vector;
	var distanceToTarget 		: float;
	var projectileFlightTime 	: float;
	var targetPos 				: Vector;
	var collisionGroups 		: array<name>;
	var headBoneIdx 			: int;
	var entMat					: Matrix;
	var targetMAC				: CMovingPhysicalAgentComponent;
	var yrdenShockEntity		: W3YrdenEntityStateYrdenShock;

	collisionGroups.PushBack('Ragdoll');
	collisionGroups.PushBack('Terrain');
	collisionGroups.PushBack('Static');
	GMFixShotCollisionGroups(collisionGroups);	//modSigns: FIX-01, debris, destructibles, physics objects, foliage, doors, platforms and fences (legacy, W3EE)

	if ( this.useCombatTarget )
	{
		target = GetCombatTarget();
		targetPos = npc.GetBehaviorVectorVariable('lookAtTarget');
	}
	else
	{
		target = GetActionTarget();
		if ( (CActor)target )
		{
			headBoneIdx = ((CActor)target).GetHeadBoneIndex();
			if ( headBoneIdx >= 0 )
			{
				targetPos = MatrixGetTranslation( ((CActor)target).GetBoneWorldMatrixByIndex( headBoneIdx ) );
			}
			else
			{
				targetPos = target.GetWorldPosition();
				targetPos.Z += ((CMovingPhysicalAgentComponent)((CActor)target).GetMovingAgentComponent()).GetCapsuleHeight() * 0.75;
			}
		}
		else if ( (CGameplayEntity)target )
		{
			targetEntity = (CGameplayEntity)target;
			if ( !( targetEntity.aimVector.X == 0 && targetEntity.aimVector.Y == 0 && targetEntity.aimVector.Z == 0 ) )
			{
				entMat = targetEntity.GetLocalToWorld();
				targetPos = VecTransform( entMat, targetEntity.aimVector );
			}
			else
			{
				targetPos = targetEntity.GetWorldPosition();
			}
		}
		else
		{
			targetPos = target.GetWorldPosition();
		}
	}

	distanceToTarget = VecDistance(npc.GetWorldPosition(),targetPos);


	desiredHeadingVec = arrow.GetHeadingVector();


	if ( targetPos == Vector(0,0,0) || distanceToTarget < 6.f )
	{
		targetPos = npc.GetWorldPosition();

		if ( (CActor)target )
		{
			targetMAC = (CMovingPhysicalAgentComponent)((CActor)target).GetMovingAgentComponent();
			if ( targetMAC )
				targetPos.Z += 0.8 * targetMAC.GetCapsuleHeight();
		}
		targetPos = targetPos +  desiredHeadingVec*distanceToTarget;
	}

	arrow.BreakAttachment();
	arrow.Init( npc );

	if ( arrow.yrdenAlternate )
	{
		yrdenShockEntity = (W3YrdenEntityStateYrdenShock)arrow.yrdenAlternate.GetCurrentState();
		if( yrdenShockEntity )
			yrdenShockEntity.ShootDownProjectile( arrow );
		projShot = false;
	}
	else
	{
		collisionGroups.PushBack('Foliage');
		arrow.ShootProjectileAtPosition( 7, arrow.projSpeed, targetPos, attackRange, collisionGroups );
		projShot = true;
	}

	if ( projShot && dodgeable )
	{
		((CPlayer) GetCombatTarget()).SetPlayerUnderAttack( true );

		projectileFlightTime = distanceToTarget / arrow.projSpeed;

		((CActor)target).SignalGameplayEventParamFloat('Time2DodgeProjectile', projectileFlightTime );
	}
	npc.SetCounterWindowStartTime(theGame.GetEngineTime());
	npc.BlinkWeapon();
}

// 5.x body; changed lines marked //modSigns. Inherited by CBTTaskProjectileAttackWithPrepare and Caranthir's meteor.
@replaceMethod(CBTTaskProjectileAttack)
function Initialize()
{
	if( !useCustomCollisionGroups )
	{
		collisionGroups.PushBack('Ragdoll');
		collisionGroups.PushBack('Terrain');
		collisionGroups.PushBack('Static');
		collisionGroups.PushBack('Water');
		GMFixMonsterProjectileCollisionGroups(collisionGroups);	//modSigns: FIX-01, debris, physics objects, foliage, doors and fences (legacy, W3EE)
	}
	else
	{
		if( collideWithRagdoll )
		{
			collisionGroups.PushBack('Ragdoll');
		}
		if( collideWithTerrain )
		{
			collisionGroups.PushBack('Terrain');
		}
		if( collideWithStatic )
		{
			collisionGroups.PushBack('Static');
			GMFixMonsterProjectileCollisionGroups(collisionGroups);	//modSigns: FIX-01, with static collision also debris, physics objects, foliage, doors and fences (legacy, W3EE)
		}
		if( collideWithWater )
		{
			collisionGroups.PushBack('Water');
		}
	}
}
