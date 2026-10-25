// ENCH-13: Depletion, Rotation, Ignition and Eruption (Glyphwords 6, 7, 12, 20) as legacy (changelist
// 987-990, 996-997, 1012-1013), from the chest armor (ENCH-01).
// - Depletion: an Aard hit drains 50% of the enemy's stamina (plus 1) with a 1 s regen delay, from the
//   projectile's collision before the hit is processed (mutations/piercingCold.ws; CNewNPC.OnAardHit's
//   drain removed).
// - Rotation: Igni's basic cast hits all around (OnStarted), deals +150 damage before the pool, scaled by
//   intensity (damage/pool.ws), and its burning chance is 33.3 points lower (skills/igni.ws).
// - Ignition: an enemy set alight by Igni can set others within 2 yd alight with the default burning,
//   a 50% roll (legacy's code skips an enemy when the roll is below the chance).
// - Eruption: an enemy killed by Igni explodes for 300 fire damage (data) and always sets others alight
//   (CNewNPC.OnDeath, enchantments/npcDeath.ws).
// EFX-07: W3Effect_Burning.OnUpdate below also drops 5.x's release of an NPC's hit reactions from half
// its burning (1.32's rule, effects/burningHits.ws).
// 5.x bodies; changes marked //modSigns. See docs/features/ench.md.

// Rotation's values (Glyphword 7 _Stats).
function GMRotationValue(attr : name) : float
{
	var min, max : SAbilityAttributeValue;

	theGame.GetDefinitionsManager().GetAbilityAttributeValue('Glyphword 7 _Stats', attr, min, max);
	return CalculateAttributeValue(min);
}

// Depletion's share of the enemy's stamina an Aard hit drains (0 without it on the caster's chest armor).
function GMDepletionDrain(caster : CActor) : float
{
	var min, max : SAbilityAttributeValue;
	var w : W3PlayerWitcher;

	w = (W3PlayerWitcher)caster;
	if(!w || !w.HasGlyphwordActive('Glyphword 6 _Stats'))
		return 0;
	theGame.GetDefinitionsManager().GetAbilityAttributeValue('Glyphword 6 _Stats', 'glyphword6_stamina_drain_perc', min, max);
	return CalculateAttributeValue(min);
}

@replaceMethod(CNewNPC)
function OnAardHit( sign : W3AardProjectile )
{
	//modSigns: removed staminaDrainPerc
	
	if( !sign.GetOwner().GetPlayer() || SignDRGetAardTier() == 1 )
	{
		SignalGameplayEvent( 'AardHitReceived' );
		aardedFlight = true; 
	}
	
	
	if( !sign.GetOwner().GetPlayer() || !GetWitcherPlayer().IsMutationActive( EPMT_Mutation6 ) )
	{
		RemoveAllBuffsOfType(EET_Frozen);
	}
	
	
	
	
	super.OnAardHit(sign);
	
	if ( HasTag('small_animal') )
	{
		Kill( 'Small Animal Aard Hit' );
	}
	if ( IsShielded(sign.GetCaster()) )
	{
		ToggleEffectOnShield('aard_cone_hit', true);
	}
	else if ( HasAbility('ablIgnoreSigns') )
	{
		this.SignalGameplayEvent( 'IgnoreSigns' );
		this.SetBehaviorVariable( 'bIgnoreSigns',1.f );
		AddTimer('IgnoreSignsTimeOut',0.2,false);
	}
	
	
	//modSigns: ENCH-13, removed Depletion's drain (legacy drains from the Aard projectile's collision, before the hit: mutations/piercingCold.ws)

	if ( !IsAlive() && deathTimestamp + 0.2 < theGame.GetEngineTimeAsSeconds() )
	{
		
		SignalGameplayEvent('AbandonAgony');
		
		
		
		if( !HasAbility( 'mon_bear_base' )
			&& !HasAbility( 'mon_golem_base' )
			&& !HasAbility( 'mon_endriaga_base' )
			&& !HasAbility( 'mon_gryphon_base' )
			&& !HasAbility( 'q604_shades' )
			&& !IsAnimal()	)
		{			
			
			SetKinematic( false );
		}
	}
}

@replaceMethod(W3IgniEntity)
function OnStarted()
{
	var player : CR4Player;
	
	Attach( true );
	
	channelBurnTestDT.Clear();
	
	player = (CR4Player)owner.GetActor();
	if(player)
	{
		GetWitcherPlayer().FailFundamentalsFirstAchievementCondition();
		player.AddTimer('ResetPadBacklightColorTimer', 2);
	}
	
	projectileCollision.Clear();
	projectileCollision.PushBack( 'Projectile' );
	projectileCollision.PushBack( 'Door' );
	projectileCollision.PushBack( 'Static' );		
	projectileCollision.PushBack( 'Character' );
	projectileCollision.PushBack( 'Terrain' );
	projectileCollision.PushBack( 'Ragdoll' );
	projectileCollision.PushBack( 'Destructible' );
	projectileCollision.PushBack( 'RigidBody' );
	projectileCollision.PushBack( 'Dangles' );
	projectileCollision.PushBack( 'Water' );
	projectileCollision.PushBack( 'Projectile' );
	projectileCollision.PushBack( 'Foliage' );
	projectileCollision.PushBack( 'Boat' );
	projectileCollision.PushBack( 'BoatDocking' );
	projectileCollision.PushBack( 'Platforms' );
	projectileCollision.PushBack( 'Corpse' );
	projectileCollision.PushBack( 'ParticleCollider' ); 

	if ( owner.ChangeAspect( this, S_Magic_s02 ) || owner.ChangeAspect( this, S_Magic_s28 ) )
	{
		CacheActionBuffsFromSkill();
		GotoState( 'IgniChanneled' );
	}
	else
	{
		if((W3PlayerWitcher)owner.GetActor() && ((W3PlayerWitcher)owner.GetActor()).HasGlyphwordActive('Glyphword 7 _Stats'))	//modSigns: ENCH-13, Rotation from the chest armor (ENCH-01)
			fireMode = 2;
			
		GotoState( 'IgniCast' );
	}
}

@replaceMethod(W3Effect_Burning)
function OnEffectAdded(optional customParams : W3BuffCustomParams)
{		
	var vec : Vector;
	var template : CEntityTemplate;
	var chance : SAbilityAttributeValue;
	var surface : CGameplayFXSurfacePost;
	var i : int;

	if ( this.IsOnPlayer() && thePlayer.IsUsingVehicle() )
	{
		if ( blockedActions.Contains( EIAB_Crossbow ) )
			blockedActions.Remove(EIAB_Crossbow);
	}
	else
		blockedActions.PushBack(EIAB_Crossbow);

	super.OnEffectAdded(customParams);
	cachedMPAC = ((CMovingPhysicalAgentComponent)target.GetMovingAgentComponent());
	
	if (isOnPlayer )
	{
		if ( thePlayer.playerAiming.GetCurrentStateName() == 'Waiting' )
			thePlayer.AddCustomOrientationTarget(OT_CustomHeading, 'BurningEffect');
	}
		
	
	if(!target.IsAlive())
		timeLeft = 10;
	
	
	if(EntityHandleGet(creatorHandle) == thePlayer && !isSignEffect)
		powerStatType = CPS_Undefined;
		
	
	if(!isOnPlayer && GetCreator() == GetWitcherPlayer() && GetWitcherPlayer().HasGlyphwordActive('Glyphword 12 _Stats') && isSignEffect && IsRequiredAttitudeBetween(thePlayer, target, true))	//modSigns: ENCH-13, Ignition from the chest armor (ENCH-01)
	{
		isWithGlyphword12 = true;
		template = (CEntityTemplate)LoadResource('glyphword_12');
		glyphword12Fx = (W3VisualFx)theGame.CreateEntity(template, target.GetWorldPosition(), target.GetWorldRotation(), , , true);
		glyphword12Fx.CreateAttachment(target, 'pelvis');
		chance = thePlayer.GetAttributeValue('glyphword12_chance');
		glyphword12BurningChance = chance.valueAdditive;
		
		
		surface = theGame.GetSurfacePostFX();
		surface.AddSurfacePostFXGroup(target.GetWorldPosition(), 1, timeLeft, 1, MaxF(5.f, CalculateAttributeValue(target.GetAttributeValue('glyphword12_range'))), 1);
	}
	else
	{
		isWithGlyphword12 = false;
	}
}

@replaceMethod(W3Effect_Burning)
function OnUpdate(deltaTime : float)
{
	var player : CR4Player = thePlayer;	
	var i : int;
	var range : float;
	var actor : CActor;
	var ents : array<CGameplayEntity>;
	//modSigns: removed params
	var min, max : SAbilityAttributeValue;

	if ( this.isOnPlayer )
	{
		if ( player.bLAxisReleased )
			player.SetOrientationTargetCustomHeading( player.GetHeading(), 'BurningEffect' );
		else if ( player.GetPlayerCombatStance() == PCS_AlertNear )
			player.SetOrientationTargetCustomHeading( VecHeading( player.moveTarget.GetWorldPosition() - player.GetWorldPosition() ), 'BurningEffect' );
		else
			player.SetOrientationTargetCustomHeading( VecHeading( theCamera.GetCameraDirection() ), 'BurningEffect' );
	}
	
	else if(isWithGlyphword12)
	{
		glyphword12Delay += deltaTime;
		
		if(glyphword12Delay <= CalculateAttributeValue(player.GetAttributeValue('glyphword12_burning_delay')) )
		{
			range = CalculateAttributeValue(player.GetAttributeValue('glyphword12_range'));
			theGame.GetDefinitionsManager().GetAbilityAttributeValue('Glyphword 12 _Stats', 'duration', min, max);
			FindGameplayEntitiesInCylinder(ents, target.GetWorldPosition(), range, 2.f, 10,,FLAG_OnlyAliveActors + FLAG_ExcludePlayer + FLAG_ExcludeTarget, target);
			
			//modSigns: removed params.effectType = EET_Burning; (default burning, legacy)
			//modSigns: removed params.creator = thePlayer; (default burning, legacy)
			//modSigns: removed params.sourceName = 'glyphword 12'; (default burning, legacy)
			//modSigns: removed params.duration = min.valueAdditive; (default burning, legacy)
			
			
			for(i=0; i<ents.Size(); i+=1)
			{
				actor = (CActor)ents[i];
				
				if(glyphword12NotBurnedEntities.Contains(ents[i]))
					continue;
				
				
				glyphword12NotBurnedEntities.PushBack(ents[i]);
				if(!IsRequiredAttitudeBetween(thePlayer, actor, true, false, false) || (RandF() < glyphword12BurningChance) || actor.HasBuff(EET_Burning))	//modSigns: ENCH-13, legacy's chance roll (as legacy's code: skipped when the roll is below the chance)
				{
					continue;
				}
				
				actor.AddEffectDefault(EET_Burning, thePlayer, 'glyphword 12');	//modSigns: ENCH-13, the default burning (legacy)
			}
			
			glyphword12Delay = 0.f;
		}
	}

	//modSigns: removed 5.x's release of an NPC's hit reactions from half its burning (EFX-07: allowed from the start, effects/burningHits.ws)

	
	if(cachedMPAC && cachedMPAC.GetSubmergeDepth() <= -1)
		target.RemoveAllBuffsOfType(effectType);
	else
		super.OnUpdate(deltaTime);
}
