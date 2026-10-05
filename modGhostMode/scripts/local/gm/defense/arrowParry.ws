// DEF-08: arrows can be parried with the guard up, no skill needed ("Arrows can be parried",
// changelist; vanilla needs Deflection S_Sword_s10 or the new tree's S_Sword_s33). Deflection's and
// S_Sword_s33's extra effects (reflecting, deflecting) stay as 5.x until SKL (project owner,
// 2026-10-03). The parry goes through PerformParryCheck, so it costs stamina (STAM-03) and, without
// stamina, still parries the arrow fully (arrows have no partial parry). See docs/features/def.md.

// 5.x body; changes marked //modSigns. Legacy's other changes here (collision groups, Glyphword 1,
// the sq108 bounce ability, Deflection's damage) belong to FIX, ENCH and SKL.
@replaceMethod(W3ArrowProjectile)
function OnProjectileCollision( pos, normal : Vector, collidingComponent : CComponent, hitCollisionsGroups : array< name >, actorIndex : int, shapeIndex : int )
{
	
	var actorVictim	: CActor;
	var parryInfo 	: SParryInfo;
	var arrowHitPos : Vector;
	var bounce		: bool;
	var abs 		: array<name>;
	var isRolling	: bool;
	var template 	: CEntityTemplate;
	
	var meshComponent 	: CMeshComponent;
	var boundingBox 	: Box;
	var arrowSize 		: Vector;
	var hitPos 			: Vector;

	if ( yrdenAlternate )
	{
		return true;
	}
	
	SetShouldBeAttachedToVictim( true );
	
	if ( !isActive )
	{
		return true;
	}
	
	if(collidingComponent)
		victim = (CGameplayEntity)collidingComponent.GetEntity();
	
	if ( collidingComponent || !hitCollisionsGroups.Contains( 'Water' ) )
		RemoveTimer( 'CheckIfInfWaterLoop' );
	
	super.OnProjectileCollision(pos, normal, collidingComponent, hitCollisionsGroups, actorIndex, shapeIndex);
	
	if( collidingComponent && !hitCollisionsGroups.Contains( 'Static' ) )
	{	
		if ( !victim || collidedEntities.Contains(victim) || victim == caster )
			return false;
		
		actorVictim = (CActor)victim;
		
		if ( hitCollisionsGroups.Contains( 'Ragdoll' ) && actorVictim )
		{
			boneName = ((CMovingPhysicalAgentComponent)actorVictim.GetMovingAgentComponent()).GetRagdollBoneName(actorIndex);
		}
		
	}
	else if ( hitCollisionsGroups.Contains( 'Terrain' ) || hitCollisionsGroups.Contains( 'Static' ) || hitCollisionsGroups.Contains( 'Foliage' ) )	 
	{
		StopProjectile();
		isActive = false;
		StopActiveTrail();
		
		
		AddTimer('TimeDestroy', 5, false);
		isScheduledForDestruction = true;
		
		
		arrowHitPos = pos + RotForward( this.GetWorldRotation() ) * 0.5f; 
		Teleport( arrowHitPos );
		
		this.SoundEvent("cmb_arrow_impact_dirt");
		return true;
	}
	else if ( hitCollisionsGroups.Contains( 'Water' ) )
	{
		if ( isUnderwater )
		{
			return false;
		}
		
		
		SoundEvent("cmb_arrow_impact_water");
		
		CheckIfInfWater();
		return true;
	}	
	else 
	{
		return false;
	}
	
	if ( !actorVictim ) 
	{
		StopProjectile();
		isActive = false;
		StopActiveTrail();
		
		
		AddTimer('TimeDestroy', 5, false);
		isScheduledForDestruction = true;
		
		
		if( StrFindFirst( this.GetName(), "bolt" ) != -1 )
		{
			
			meshComponent = (CMeshComponent)GetComponentByClassName('CMeshComponent');
			if( meshComponent )
			{
				boundingBox = meshComponent.GetBoundingBox();
				arrowSize = boundingBox.Max - boundingBox.Min;
				
				hitPos = pos;
				hitPos -= RotForward(  this.GetWorldRotation() ) * arrowSize.X * 0.7f; 
				
				Teleport( hitPos );
			}
		}
		
		ProcessDamageAction(victim, pos, boneName);
		
		this.SoundEvent("cmb_arrow_impact_wood");
		
		return true;
	}		
	else if (victim == thePlayer)
	{
		bounce = false;
		
		if ( thePlayer.IsCurrentlyDodging() && thePlayer.GetBehaviorVariable( 'isRolling' ) == 1.f )
		{
			isRolling = true;
		}
		else if(thePlayer.HasAbility( 'Glyphword 1 _Stats', true ))
		{
			
			thePlayer.PlayEffect('glyphword_reflection');
			
			
			template = (CEntityTemplate)LoadResource('glyphword_1');
			theGame.CreateEntity(template, GetWorldPosition(), thePlayer.GetWorldRotation(), , , true);
		
			if(ProcessCombat_ArrowDeflection())
				return true;

			this.SoundEvent( "cmb_arrow_bounce" );
			bounce = true;
		}
		else if(thePlayer.CanParryAttack())	//modSigns: arrows can be parried with the guard up, no skill needed (vanilla: Deflection S_Sword_s10 or S_Sword_s33)
		{			
			
			parryInfo = thePlayer.ProcessParryInfo(((CActor)caster),((CActor)victim),AST_Jab,ASD_NotSet,'attack_light',((CActor)caster).GetInventory().GetItemFromSlot('l_weapon'), true);
			
			if ( thePlayer.PerformParryCheck(parryInfo) )
			{
				if(ProcessCombat_ArrowDeflection())
					return true;

				
				GetWitcherPlayer().GainAdrenalineFromPerk31( 'parry' );
					
				bounce = true;
			}
		}
		
		
		if(!bounce)
		{
			thePlayer.GetCharacterStats().GetAbilities(abs, true);				
			bounce = abs.Contains(theGame.params.BOUNCE_ARROWS_ABILITY);
			
			if(bounce)
			{
				FactsAdd("sq108_arrow_deflected");
				thePlayer.PlayEffect( 'bolt_bump' );
			}
		}
		
		if(bounce)
		{	
			this.bounceOfVelocityPreserve = 0.7;
			this.BounceOff(normal,pos);
			this.Init(thePlayer);
			ActivateTrail('arrow_trail_orange');
			return false;
		}
		else if ( !isRolling )
		{
			thePlayer.SetIsDodgingProjectile( false );

			if( actorVictim.IsAlive() )
				ProcessDamageAction( actorVictim, pos, boneName );
			
			this.SoundEvent( "cmb_arrow_impact_body" );
			
			if( IsNameValid( boneName ) )
				AttachArrowToRagdoll( actorVictim, pos, boneName );
			else
			{
				StopProjectile();
				StopActiveTrail();
				isActive = false;
				SmartDestroy();
			}
		}
	}
	else if ( (CNewNPC)victim && ((CNewNPC)victim).IsShielded(caster) ) 
	{
		((CNewNPC)victim).SignalGameplayEvent('PerformAdditiveParry');
		
		this.SoundEvent("cmb_arrow_impact_wood");
		
		AttachArrowToShield(actorVictim, pos);

		if(caster == thePlayer)
		{
			GetWitcherPlayer().ResetCripplingShot();
		}
	}
	else
	{
		if(actorVictim.IsAlive())
		{
			if ( actorVictim.HasAbility( 'BounceBoltsWildhunt' ))
			{
				if(caster == thePlayer)
				{
					GetWitcherPlayer().ResetCripplingShot();
				}

				this.bounceOfVelocityPreserve = 0.1;
				this.BounceOff(normal, pos);
				this.Init(actorVictim);
				this.PlayEffect('sparks');
				this.SoundEvent("cmb_arrow_impact_metal");
				ActivateTrail('arrow_trail_orange');
				return false;
			}
			else
			{
				ProcessDamageAction(actorVictim, pos, boneName);
			}
		}
		else if ( actorVictim.IsInAgony() )
		{
			
			actorVictim.SignalGameplayEvent('AbandonAgony');
			
			actorVictim.SetKinematic(false);
		}
		
		this.SoundEvent("cmb_arrow_impact_body");
		
		if( ShouldPierceVictim( actorVictim ) ) 
		{
			Mutation9HitFX( actorVictim );
		}
		else if(IsNameValid(boneName))
		{
			AttachArrowToRagdoll(actorVictim,pos,boneName);
		}
		else
		{
			StopProjectile();
			StopActiveTrail();
			isActive = false;
			SmartDestroy();
		}
	}
	return true;
}
