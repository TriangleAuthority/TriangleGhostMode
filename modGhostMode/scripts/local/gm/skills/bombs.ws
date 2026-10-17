// SKL-15: the Bomb Creation skills, legacy's in both trees (D31, D32, D60, project owner, 2026-10-09;
// non-aimed bombs -50% with SKL-06).
// - Steady Aim (classic alchemy_s9, the new tree's alchemy_s23 in place of Toxic Shock; legacy's 3 levels
//   in both): time slowed a further 15% per level while aiming bombs (5.x: one level, 50%, and no slow
//   motion while aiming a bomb at all: restored below).
// - Pyrotechnics (alchemy_s10; classic GM_C_alchemy_s10, 5 levels): +50 physical and silver damage per
//   level on every bomb (new tree 83.33), by data (5.x's code).
// - Efficiency (alchemy_s8; classic GM_C_alchemy_s8, 5 levels): +1 bomb per slot per level (new tree +1/+3/
//   +5 at levels 1/2/3): gm_efficiency_base + gm_efficiency_per_level x level (the slot size in
//   CInventoryComponent.SingletonItemGetMaxAmmo, skills/heavyArtilleryTrickShot.ws).
// - Cluster Bombs (alchemy_s11; classic GM_C_alchemy_s11, 5 levels): level + 1 fragments (new tree 2 per
//   level), each dealing a full bomb's damage (5.x: level + 1 at 40%): gm_fragments_base +
//   gm_fragments_per_level x level.
// 5.x's Toxic Shock (a strong attack's poison burst) is gone (damage/pool.ws). See docs/features/skl.md.

// Bomb aiming slows time again (1.32 and legacy: after half a second of aiming, x0.6, less Steady Aim's
// slowdown; 5.x dropped the call from PlayerAimingStateAiming.Aim, which a wrapper cannot reach (an entry
// function), so a timer started on entering the state makes it).
@wrapMethod(PlayerAimingStateAiming)
function OnEnterState(prevStateName : name)
{
	wrappedMethod(prevStateName);
	if(parent.aimType == AT_Bomb && parent.owner)
		parent.owner.AddTimer('GMBombAimSloMo', 0.5, false);
}

@addMethod(PlayerAiming)
function GMIsAimingBomb() : bool
{
	return GetCurrentStateName() == 'Aiming' && aimType == AT_Bomb;
}

@addMethod(CR4Player)
timer function GMBombAimSloMo(dt : float, id : int)
{
	if(playerAiming && playerAiming.GMIsAimingBomb())
		playerAiming.OnAddAimingSloMo();
}

// The Steady Aim the player has (classic first); S_SUndefined if none.
@addMethod(CR4Player)
function GMSteadyAimSkill() : ESkill
{
	if(CanUseSkill(S_Alchemy_s09))
		return S_Alchemy_s09;
	if(CanUseSkill(S_Alchemy_s23))
		return S_Alchemy_s23;
	return S_SUndefined;
}

// A skill's base + per-level value (0 without the skill).
@addMethod(CR4Player)
function GMSkillBasePerLevel(skill : ESkill, baseName : name, perLevelName : name) : int
{
	if(!CanUseSkill(skill))
		return 0;
	return RoundMath(CalculateAttributeValue(GetSkillAttributeValue(skill, baseName, false, false))
		+ CalculateAttributeValue(GetSkillAttributeValue(skill, perLevelName, false, false)) * GetSkillLevel(skill));
}

// Efficiency's extra bombs per slot.
@addMethod(CR4Player)
function GMEfficiencyBonus() : int
{
	return GMSkillBasePerLevel(S_Alchemy_s08, 'gm_efficiency_base', 'gm_efficiency_per_level');
}

// Cluster Bombs' fragments (0 without the skill).
@addMethod(CR4Player)
function GMClusterFragments() : int
{
	return GMSkillBasePerLevel(S_Alchemy_s11, 'gm_fragments_base', 'gm_fragments_per_level');
}

// 5.x body; changes marked //modSigns.
@replaceMethod(PlayerAimingStateAiming)
function SloMo()
{
	var speed : float;
	
	if (!(parent.owner))
		return;



	speed = SLOWMO_SPEED;
	
	if ( (W3ThrowingKnife)( parent.throwable ) )
		speed = ((W3ThrowingKnife)(parent.throwable)).slomoStrength;
	
	RemoveSloMo();
	

		if (parent.aimType == AT_Bolt && parent.owner.CanUseSkill(S_Sword_s13) )
			speed -= CalculateAttributeValue( ((CR4Player)parent.owner).GetSkillAttributeValue(S_Sword_s13, 'slowdown_mod', false, true) ) * parent.owner.GetSkillLevel(S_Sword_s13);
		else if (parent.aimType == AT_Bomb && ((CR4Player)parent.owner).GMSteadyAimSkill() != S_SUndefined )	//modSigns: Steady Aim in either tree
			speed -= CalculateAttributeValue( ((CR4Player)parent.owner).GetSkillAttributeValue(((CR4Player)parent.owner).GMSteadyAimSkill(), 'slowdown_mod', false, true) ) * parent.owner.GetSkillLevel(((CR4Player)parent.owner).GMSteadyAimSkill());	//modSigns

		
		if(parent.aimType == AT_Bolt && parent.owner.CanUseSkill(S_Sword_s32))
			speed -= speed * CalculateAttributeValue( ((CR4Player)parent.owner).GetSkillAttributeValue(S_Sword_s32, 'slowdown_mod', false, true) ) * parent.owner.GetSkillLevel(S_Sword_s32);

	
	
	theSound.SoundEvent( "gui_slowmo_start" );
	theGame.SetTimeScale(speed, theGame.GetTimescaleSource(ETS_ThrowingAim), theGame.GetTimescalePriority(ETS_ThrowingAim), false );
	speedMultCasuserId = parent.owner.SetAnimationSpeedMultiplier( 1/speed * 0.5 );		
	
	if ( (W3ThrowingKnife)( parent.throwable ) )
		((W3ThrowingKnife)( parent.throwable )).SetMultCasuser( speedMultCasuserId );
	
	LogItems("CurrentSLOMO <" + speedMultCasuserId + ">>");
}


// 5.x body; changes marked //modSigns.
@replaceMethod(W3Petard)
function ProcessClusterBombs()
{
	var target : CActor = thePlayer.GetTarget();
	var i, j, clusterNbr : int;
	var cluster : W3Petard;
	var targetPosCluster, clusterInitPos : Vector;
	var angle, velocity, distLen : float;
	var clusterTemplate : CEntityTemplate;
	var dmgRaw : SRawDamage;
	var cachedDamages : array<SRawDamage>;
	var atts : array<name>;
	var distanceToTarget : float;
	var projectileFlightTime : float;
	var collisionGroups : array<name>;
	var clusterParams : SPetardParams;

	clusterInitPos = GetWorldPosition();
	clusterInitPos.Z += radius + 0.15;
	
	clusterNbr = GetWitcherPlayer().GMClusterFragments();	//modSigns: legacy's count in either tree
	
	for(i=0; i<clusterNbr; i+=1)
	{			
		cluster = (W3Petard)Duplicate();
		cluster.Init(GetOwner());
		cluster.isCluster = true;
		cluster.isProximity = false;					
		cluster.AddTimer('DelayedRestoreCollisions', 0.2);	
		
		
		targetPosCluster.X = SgnF(RandF()-0.5) * (1+RandF()*3);
		targetPosCluster.Y = SgnF(RandF()-0.5) * (1+RandF()*3);
		targetPosCluster.Z = 0;
		
		distLen = VecLength2D(targetPosCluster);	
		
		targetPosCluster += GetWorldPosition();		
		
		angle = (9 - distLen) * 10;					
		velocity = 4 + distLen/2;					
		
		
		//modSigns: removed 5.x's 40% damage per fragment (each deals a full bomb's damage, legacy)

		
		if( target.HasTag('AddRagdollCollision'))
		{
			collisionGroups.PushBack('Ragdoll');
			collisionGroups.PushBack('Terrain');
			collisionGroups.PushBack('Static');
			collisionGroups.PushBack('Water');
			collisionGroups.PushBack('Destructible');
			cluster.ShootProjectileAtPosition( angle, velocity, targetPosCluster, theGame.params.MAX_THROW_RANGE, collisionGroups );
		}
		else
		{
			cluster.ShootProjectileAtPosition( angle, velocity, targetPosCluster, theGame.params.MAX_THROW_RANGE );
		}
		cluster.PlayEffectSingle(FX_TRAIL);
		
		if ( dodgeable )
		{
			distanceToTarget = VecDistance( thePlayer.GetWorldPosition(), target.GetWorldPosition() );		
			
			
			projectileFlightTime = distanceToTarget / velocity;
			target.SignalGameplayEventParamFloat('Time2DodgeBomb', projectileFlightTime );
		}
	}
	
	
	PlayEffect(FX_CLUSTER);		
	justPlayingFXs.PushBack(FX_CLUSTER);
	
	AddTimer('DestroyWhenNoFXPlayed', 1, true, , , true);
	stopCollisions = true;
}
