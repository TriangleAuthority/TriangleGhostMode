// ENCH-11: Deflection (Glyphword 1) as legacy (changelist 984), from the chest armor (ENCH-01): the armor
// bounces every arrow Geralt does not parry and no longer reflects any (reflection is the Deflection
// skill's, through a parry: DEF-08, SKL-05). The owner's DE5: 5.x's thrown boulders follow the same rule
// (their parry stays 5.x's). Arrows: defense/arrowParry.ws. 5.x body; changes marked //modSigns.
// See docs/features/ench.md.

// Deflection's bounce of a projectile that hit Geralt: its effects and sound; false without the word on
// the chest armor.
function GMDeflectionBounce(projectile : CEntity) : bool
{
	var template : CEntityTemplate;

	if(!GetWitcherPlayer() || !GetWitcherPlayer().HasGlyphwordActive('Glyphword 1 _Stats'))
		return false;
	thePlayer.PlayEffect('glyphword_reflection');
	template = (CEntityTemplate)LoadResource('glyphword_1');
	theGame.CreateEntity(template, projectile.GetWorldPosition(), thePlayer.GetWorldRotation(), , , true);
	projectile.SoundEvent("cmb_arrow_bounce");
	return true;
}

@replaceMethod(W3ThrallBoulderProjectile)
function OnProjectileCollision( pos, normal : Vector, collidingComponent : CComponent, hitCollisionsGroups : array< name >, actorIndex : int, shapeIndex : int )
{
	if ( !isActive )
	{
		return true;
	}
	
	if(collidingComponent)
		victim = (CGameplayEntity)collidingComponent.GetEntity();
	else
		victim = NULL;
	
	super.OnProjectileCollision(pos, normal, collidingComponent, hitCollisionsGroups, actorIndex, shapeIndex);
	
	PlayEffect('boulder_hit'); 
	
	
	
	if ( victim == thePlayer )
	{
		bounce = false;
		
		//modSigns: ENCH-11, removed Deflection's branch before the parry (moved after it, legacy's rule)
		if(thePlayer.CanParryAttack() && (thePlayer.CanUseSkill(S_Sword_s10) || thePlayer.CanUseSkill(S_Sword_s33)) )	//modSigns: no longer an else branch
		{			

			
			parryInfo = thePlayer.ProcessParryInfo(((CActor)caster),((CActor)victim),AST_Jab,ASD_NotSet,'attack_light',((CActor)caster).GetInventory().GetItemFromSlot('r_weapon'), true);

			if ( thePlayer.PerformParryCheck(parryInfo) )
			{
				if(ProcessCombat_ArrowDeflection())
					return true;
					
				bounce = true;
			}
		}
		
		if(!bounce && GMDeflectionBounce(this))	//modSigns: ENCH-11, Deflection bounces what was not parried, from the chest armor (legacy; it no longer reflects)
			bounce = true;	//modSigns
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
			StopProjectile();
			ActivateTrail('arrow_trail_orange');
			
			
			casterPos = thePlayer.GetWorldPosition() + thePlayer.GetHeadingVector() * 1.5;
			casterPos.Z += 1.5;
			casterPos.Y += RandRangeF(0.5, -0.5);
			this.Init(thePlayer);
			this.ShootProjectileAtPosition(22,projSpeed*0.5,casterPos);
			return true;
		}
		else
		{
			VictimCollision(victim);
		}
	}
	else if ( victim && !hitCollisionsGroups.Contains( 'Static' ) && !projectileHitGround && !collidedEntities.Contains(victim) )
	{
		VictimCollision(victim);
	}
	else if ( hitCollisionsGroups.Contains( 'Terrain' ) || hitCollisionsGroups.Contains( 'Static' ) )
	{
		ProjectileHitGround();
	}
	else if ( hitCollisionsGroups.Contains( 'Water' ) )
	{
		ProjectileHitGround();
	}
}
