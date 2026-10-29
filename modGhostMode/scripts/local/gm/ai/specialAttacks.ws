// AI-18: special attacks and monster projectiles (docs/features/ai.md). Special attacks deal set damage, with
// the attacker's attack power (spell power for eight projectile classes, as in legacy and 1.32: Ifryt's, Eredin's,
// poison, fireballs, the Dracolizard's, ice meteors, lightning strikes and bolts) and the victim's armor (DMG's
// rule), instead of reading the attacker's basic-attack stats or ignoring armor; their effects last 3 s (5.x: 2 s).
// Legacy's rules, ported on 5.x's code:
// - every projectile: no damage from Geralt's level (PA11: 5.x adds 2.5% of the damage per Geralt level, or per
//   the victim's level when playing Ciri, at each collision; legacy's code has none). Ends XBOW-08's deviation;
// - monster projectiles deal their projectile's damage, 200 by default (boulders, stones, the elementals', Eredin's
//   frost projectile, the environment's objects, fireballs, ice meteors, lightning), and their projectile's effect
//   for 3 s; ice spears' slowdown 3 s; boulders bludgeoning damage (5.x: rending);
// - boulders and debuff projectiles set to ignore armor ignore it on every victim (5.x: only on Vitality users;
//   owner, 2026-10-29);
// - the Hakland mage's debuff projectile hits once in 3 s (it hit three times);
// - ice spikes deal their own frost damage (100 when unset) with attack power (5.x: the summoner's weapon damage);
// - the leshen's roots 400 rending with attack power and a heavy reaction (5.x: a heavy attack of its weapon); the
//   red-plague creature's roots the same (DA5, owner, 2026-10-28); the leshen's birds deal nothing themselves
//   (the bird swarm does);
// - the witch's boiling water uses attack power on both of 5.x's paths (PA12; 5.x's new weapon-attack path below
//   101 damage already does); bird swarms ignore armor and attack power;
// - objects that strike back when hit deal their own damage type, and the larger of 500 and half Geralt's health
//   when no damage is set, with a heavy reaction; the toad's acid pool at least 20% of the victim's health in fire
//   (5.x: 5 per Geralt level), a heavy reaction;
// - the Blood and Wine tornado 2% of the victim's maximum health per tick, armor applying; the ground trap the
//   larger of 500 and 20% of the victim's health as direct damage, a light reaction;
// - magic fists (lightning, fire) count as ranged attacks.
// The projectiles' entity values (Blood and Wine's and Hearts of Stone's projectiles, the djinn's and the
// sorceresses' stones) are entity edits by tools/gen_ai_ent.py.

// ---- every projectile: no level term (PA11) ----

// 5.x body; changes marked //modSigns.
@replaceMethod(W3AdvancedProjectile)
function OnProjectileCollision( pos, normal : Vector, collidingComponent : CComponent, hitCollisionsGroups : array< name >, actorIndex : int, shapeIndex : int )
{
	var dmgMult : float;

	super.OnProjectileCollision(pos, normal, collidingComponent, hitCollisionsGroups, actorIndex, shapeIndex);

	if ( !dealDamageEvenIfDodging && victim == thePlayer && ( GetAttitudeBetween( victim, caster ) == AIA_Friendly || ( thePlayer.IsCurrentlyDodging() && ( thePlayer.IsCiri() || thePlayer.GetBehaviorVariable( 'isRolling' ) == 1.f ) ) ) )
	{
		victim = NULL;
		ignore = true;
	}


	//modSigns: removed 5.x's +2.5% damage per Geralt level (per the victim's level when playing Ciri) at each collision (AI-18, PA11)

}
// ---- monster projectiles: their damage and effect (200 and a 3 s effect by default) ----

class W3BoulderProjectile extends W3AdvancedProjectile
{
	default projDMG = 200.f;	//modSigns: AI-18
	default projEfect = EET_Stagger;	//modSigns: AI-18
}

// 5.x body; changes marked //modSigns. Boulders deal bludgeoning damage and their ignoreArmor applies to every victim
// (legacy, as 1.32; owner, 2026-10-29). 5.x's thrall boulder (W3ThrallBoulderProjectile, another class) keeps 5.x's rule.
@replaceMethod(W3BoulderProjectile)
function DealDamageToVictim( victim : CGameplayEntity )
{
	var action : W3DamageAction;

	this.SoundEvent( soundRockImpact );

	action = new W3DamageAction in this;
	action.Initialize((CGameplayEntity)caster,victim,this,caster.GetName(),EHRT_Heavy,CPS_AttackPower,false,true,false,false);
	if ( projEfect != EET_Undefined )
	{
		action.AddEffectInfo(projEfect);
	}
	action.AddDamage( theGame.params.DAMAGE_NAME_BLUDGEONING, projDMG );	//modSigns: AI-18, bludgeoning (legacy; 5.x: rending)
	//modSigns: removed 5.x's Essence check: ignoreArmor applies to every victim (legacy)
	action.SetIgnoreArmor( ignoreArmor );	//modSigns
	action.SetCanPlayHitParticle(false);
	theGame.damageMgr.ProcessAction( action );
	delete action;

	collidedEntities.PushBack(victim);
}

class W3ElementalIfrytProjectile extends W3TraceGroundProjectile
{
	default projDMG = 200.f;	//modSigns: AI-18
	default projEfect = EET_Burning;	//modSigns: AI-18
}

class W3EredinFrostProjectile extends W3TraceGroundProjectile
{
	default projDMG = 200.f;	//modSigns: AI-18 (AI-15: Eredin's frost projectile; 5.x: the base 20 and no effect)
	default projEfect = EET_SlowdownFrost;	//modSigns: AI-18
}

class W3ElementalDaoProjectile extends W3TraceGroundProjectile
{
	default projDMG = 200.f;	//modSigns: AI-18
	default projEfect = EET_Knockdown;	//modSigns: AI-18
}

class W3StoneProjectile extends W3AdvancedProjectile
{
	default projDMG = 200.f;	//modSigns: AI-18
	default projEfect = EET_Knockdown;	//modSigns: AI-18
}

class W3EnvironmentProjectile extends W3AdvancedProjectile
{
	default projDMG = 200.f;	//modSigns: AI-18
	default projEfect = EET_Stagger;	//modSigns: AI-18
}

class W3DracolizardFireball extends W3FireballProjectile
{
	default projDMG = 200.f;	//modSigns: AI-18
	default projEfect = EET_Burning;	//modSigns: AI-18
	default burningDur = 3.f;	//modSigns: AI-18
}

class W3IceMeteorProjectile extends W3MeteorProjectile
{
	default projDMG = 200.f;	//modSigns: AI-18
	default projEfect = EET_SlowdownFrost;	//modSigns: AI-18
}

class W3LightningStrikeProjectile extends W3MeteorProjectile
{
	default projDMG = 200.f;	//modSigns: AI-18
	default projEfect = EET_Paralyzed;	//modSigns: AI-18
}

class W3IceSpearProjectile extends W3AdvancedProjectile
{
	default customDuration = 3.0;	//modSigns: AI-18 (5.x: 2)
}

// 5.x body; changes marked //modSigns.
@replaceMethod(W3ElementalIfrytProjectile)
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

	if ( victim && !collidedEntities.Contains(victim) )
	{
		action = new W3DamageAction in this;
		action.Initialize((CGameplayEntity)caster,victim,this,caster.GetName(),EHRT_Light,CPS_SpellPower,false,true,false,false);
		action.AddDamage(theGame.params.DAMAGE_NAME_FIRE, projDMG );	//modSigns: AI-18, the projectile's damage (legacy)
		action.AddEffectInfo(projEfect, 3.0);	//modSigns: AI-18, the projectile's effect, 3 s (legacy; 5.x: 2 s)
		action.SetCanPlayHitParticle(false);
		theGame.damageMgr.ProcessAction( action );
		collidedEntities.PushBack(victim);
		if ( deactivateOnCollisionWithVictim )
		{
			isActive = false;
		}
		delete action;
	}

}
// 5.x body; changes marked //modSigns.
@replaceMethod(W3EredinFrostProjectile)
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

	if ( victim && !collidedEntities.Contains(victim) )
	{
		action = new W3DamageAction in this;
		action.Initialize((CGameplayEntity)caster,victim,this,caster.GetName(),EHRT_Heavy,CPS_SpellPower,false,true,false,false);
		action.AddDamage(theGame.params.DAMAGE_NAME_FROST, projDMG );
		action.AddEffectInfo( projEfect, 3.0 );	//modSigns: AI-18, 3 s (legacy; 5.x: 2 s)
		action.SetCanPlayHitParticle(false);
		theGame.damageMgr.ProcessAction( action );
		collidedEntities.PushBack(victim);
		if ( deactivateOnCollisionWithVictim )
		{
			isActive = false;
		}
		delete action;
	}

}
// 5.x body; changes marked //modSigns.
@replaceMethod(W3ElementalDaoProjectile)
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

	if ( victim && !collidedEntities.Contains(victim) )
	{
		action = new W3DamageAction in this;
		action.Initialize((CGameplayEntity)caster,victim,this,caster.GetName(),EHRT_None,CPS_AttackPower,false,true,false,false);
		action.AddEffectInfo(projEfect);	//modSigns: AI-18, the projectile's effect (legacy)
		action.AddDamage(theGame.params.DAMAGE_NAME_ELEMENTAL, projDMG );	//modSigns: AI-18, the projectile's damage (legacy)
		theGame.damageMgr.ProcessAction( action );
		collidedEntities.PushBack(victim);
		if ( deactivateOnCollisionWithVictim )
		{
			isActive = false;
		}
		delete action;
	}
}
// 5.x body; changes marked //modSigns.
@replaceMethod(W3StoneProjectile)
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


	if ( victim && !collidedEntities.Contains(victim) )
	{
		action = new W3DamageAction in this;
		action.Initialize((CGameplayEntity)caster,victim,this,caster.GetName(),EHRT_None,CPS_AttackPower,false,true,false,false);
		action.AddEffectInfo(projEfect);	//modSigns: AI-18, the projectile's effect (legacy)
		action.AddDamage(theGame.params.DAMAGE_NAME_BLUDGEONING, projDMG );	//modSigns: AI-18, the projectile's damage (legacy)
		theGame.damageMgr.ProcessAction( action );
		collidedEntities.PushBack(victim);
		isActive = false;
		this.PlayEffect(onCollisionFxName);
		this.StopEffect(initFxName);
		delete action;
	}

	return true;
}
// 5.x body; changes marked //modSigns.
@replaceMethod(W3EnvironmentProjectile)
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





	if ( victim && !collidedEntities.Contains(victim) && victim != caster )
	{
		action = new W3DamageAction in this;
		action.Initialize(( CGameplayEntity )caster, victim, this, caster.GetName(), EHRT_None, CPS_AttackPower, false, true, false, false );
		action.AddEffectInfo( projEfect );	//modSigns: AI-18, the projectile's effect (legacy)
		action.AddDamage( theGame.params.DAMAGE_NAME_BLUDGEONING, projDMG );	//modSigns: AI-18, the projectile's damage (legacy)
		theGame.damageMgr.ProcessAction( action );
		collidedEntities.PushBack(victim);
		if ( IsNameValid( onCollisionFxName ))
			this.PlayEffect( onCollisionFxName );
		if ( IsNameValid( initFxName ))
			this.StopEffect(initFxName);
		if ( IsNameValid( stopFxOnDeactivate ))
			this.StopEffect(stopFxOnDeactivate);
		delete action;

		bounceOfVelocityPreserve = 0.2;
		BounceOff(normal,pos);
		this.Init( victim );
		return true;
	}
	else if ( hitCollisionsGroups.Contains( 'Terrain' ) || hitCollisionsGroups.Contains( 'Static' ) )
	{
		StopProjectile();
		if ( IsNameValid( initFxName ))
			this.StopEffect(initFxName);
		if ( IsNameValid( stopFxOnDeactivate ))
			this.StopEffect(stopFxOnDeactivate);
		isActive = false;

		return true;
	}
}
// 5.x body; changes marked //modSigns.
@replaceMethod(PoisonProjectile)
function DealDamageToVictim( victim : CGameplayEntity )
{
	var action : W3DamageAction;
	var actorCaster, actorVictim : CActor;

	actorCaster = (CActor)caster;
	actorVictim = (CActor)victim;

	if( actorCaster && actorVictim && GetAttitudeBetween( actorCaster, actorVictim ) != AIA_Hostile )
	{
		return;
	}

	action = new W3DamageAction in theGame;
	action.Initialize((CGameplayEntity)caster,victim,this,caster.GetName(),EHRT_Light,CPS_SpellPower,false,true,false,false);
	action.AddDamage(theGame.params.DAMAGE_NAME_POISON, projDMG );
	action.AddEffectInfo(projEfect, 3.0);	//modSigns: AI-18, the projectile's effect, 3 s (legacy; 5.x: 2 s)
	action.SetCanPlayHitParticle(false);
	theGame.damageMgr.ProcessAction( action );
	delete action;

	collidedEntities.PushBack(victim);
}
// 5.x body; changes marked //modSigns.
@replaceMethod(W3FireballProjectile)
function DealDamageToVictim( victim : CGameplayEntity )
{
	var action : W3DamageAction;

	action = new W3DamageAction in theGame;
	action.Initialize((CGameplayEntity)caster,victim,this,caster.GetName(),EHRT_Light,CPS_SpellPower,false,true,false,false);

	if ( victim == thePlayer )
	{
		projDMG = projDMG - (projDMG * decreasePlayerDmgBy);
	}

	action.AddDamage(theGame.params.DAMAGE_NAME_FIRE, projDMG );
	action.AddEffectInfo(projEfect, 3.0);	//modSigns: AI-18, the projectile's effect, 3 s (legacy; 5.x: 2 s)
	action.SetCanPlayHitParticle(false);
	theGame.damageMgr.ProcessAction( action );
	delete action;

	collidedEntities.PushBack(victim);
}
// 5.x body; changes marked //modSigns.
@replaceMethod(W3DracolizardFireball)
function DealDamageToVictim( victim : CGameplayEntity )
{
	var action : W3DamageAction;

	action = new W3DamageAction in theGame;
	action.Initialize((CGameplayEntity)caster,victim,this,caster.GetName(),EHRT_Light,CPS_SpellPower,false,true,false,false);

	if ( victim == thePlayer )
	{
		projDMG = projDMG - (projDMG * decreasePlayerDmgBy);
	}

	action.AddDamage(theGame.params.DAMAGE_NAME_FIRE, projDMG );
	action.AddEffectInfo(projEfect, burningDur );	//modSigns: AI-18, the projectile's effect (legacy)
	action.SetCanPlayHitParticle(false);
	theGame.damageMgr.ProcessAction( action );
	delete action;

	collidedEntities.PushBack(victim);
}
// 5.x body; changes marked //modSigns.
@replaceMethod(W3IceMeteorProjectile)
function DealDamageToVictim( victim : CGameplayEntity )
{
	var action : W3DamageAction;

	action = new W3DamageAction in theGame;
	action.Initialize((CGameplayEntity)caster,victim,this,caster.GetName(),EHRT_Heavy,CPS_SpellPower,false,true,false,false);
	action.AddDamage(theGame.params.DAMAGE_NAME_FROST, projDMG );
	action.AddEffectInfo(projEfect, 3.0);	//modSigns: AI-18, the projectile's effect, 3 s (legacy; 5.x: 2 s)
	action.SetCanPlayHitParticle(false);
	theGame.damageMgr.ProcessAction( action );
	delete action;

	collidedEntities.PushBack(victim);
}
// 5.x body; changes marked //modSigns.
@replaceMethod(W3LightningStrikeProjectile)
function DealDamageToVictim( victim : CGameplayEntity )
{
	var action : W3DamageAction;

	action = new W3DamageAction in this;
	action.Initialize((CGameplayEntity)caster,victim,this,caster.GetName(),EHRT_Light,CPS_SpellPower,false,true,false,false);
	action.AddDamage(theGame.params.DAMAGE_NAME_SHOCK , projDMG );
	action.AddEffectInfo(projEfect, 3.0);	//modSigns: AI-18, the projectile's effect, 3 s (legacy; 5.x: 2 s)
	action.SetCanPlayHitParticle(false);
	theGame.damageMgr.ProcessAction( action );
	delete action;

	collidedEntities.PushBack(victim);
}
// 5.x body; changes marked //modSigns.
@replaceMethod(W3LightningBoltProjectile)
function DealDamageToVictim( victim : CGameplayEntity )
{
	var action : W3DamageAction;

	action = new W3DamageAction in this;
	action.Initialize((CGameplayEntity)caster,victim,this,caster.GetName(),EHRT_Light,CPS_SpellPower,false,true,false,false);
	action.AddDamage(theGame.params.DAMAGE_NAME_SHOCK , projDMG );
	action.AddEffectInfo(projEfect, 3.0);	//modSigns: AI-18, the projectile's effect, 3 s (legacy; 5.x: 2 s)
	action.SetCanPlayHitParticle(false);
	theGame.damageMgr.ProcessAction( action );
	delete action;

	collidedEntities.PushBack(victim);
}
// ---- the Hakland mage's debuff projectile: once in 3 s ----

@addField(CNewNPC)
var gmHaklandMageHack : float;

// True when the Hakland mage's debuff projectile hit within the last 3 s (its triple hit counts once; legacy's
// HaklandMageDebuffProjectileHack).
@addMethod(CNewNPC)
function GMHaklandMageDebuffProjectileHack() : bool
{
	var ret : bool;

	if( HasAbility('HaklandMage') )
	{
		if( theGame.GetEngineTimeAsSeconds() - gmHaklandMageHack < 3.0 )
			ret = true;
		gmHaklandMageHack = theGame.GetEngineTimeAsSeconds();
	}
	return ret;
}

// 5.x body; changes marked //modSigns.
@replaceMethod(DebuffProjectile)
function OnProjectileCollision( pos, normal : Vector, collidingComponent : CComponent, hitCollisionsGroups : array< name >, actorIndex : int, shapeIndex : int )
{
	var action : W3DamageAction;
	var params : SCustomEffectParams;


	if ( !isActive )
	{
		return true;
	}

	if(collidingComponent)
		victim = (CActor)collidingComponent.GetEntity();
	else
		victim = NULL;

	super.OnProjectileCollision(pos, normal, collidingComponent, hitCollisionsGroups, actorIndex, shapeIndex);


	if ( victim && !collidedEntities.Contains(victim) )
	{
		if( stopProjectileAfterCollision )
		{
			this.StopProjectile();
		}
		this.DestroyAfter( destroyAfterFloat );
		if( !persistFxAfterCollision )
		{
			this.StopEffect( initFxName );
		}
		this.PlayEffect(onCollisionFxName);

		if ( IsNameValid( sendGameplayEventToVicitm ) )
		{
			( (CActor)victim ).SignalGameplayEvent( sendGameplayEventToVicitm );
		}



		if( !((CNewNPC)caster && ((CNewNPC)caster).GMHaklandMageDebuffProjectileHack()) )	//modSigns: AI-18, the Hakland mage's triple hit counts once (legacy)
		{	//modSigns
		action = new W3DamageAction in this;
		action.Initialize((CGameplayEntity)caster,victim,this,caster.GetName(),hitReactionType,CPS_AttackPower, false, true, false, false);
		if ( this.projDMG > 0 )
		{
			//modSigns: removed 5.x's Essence check: ignoreArmor applies to every victim (AI-18, AI-C audit F1, owner, 2026-10-29; legacy)
			if ( ignoreArmor )	//modSigns
				action.SetIgnoreArmor(true);	//modSigns
			action.AddDamage(damageTypeName, projDMG );


			//modSigns: removed 5.x's second hit of rending damage for damage types that do not hit Essence (AI-18: one damage type, as legacy's numbers assume)

		}

		if ( customDuration > 0 && (CActor)victim )
		{
			if ( !destroyQuen && (W3PlayerWitcher)victim && (((W3PlayerWitcher)victim).IsQuenActive( false ) || ((W3PlayerWitcher)victim).IsQuenActive( true )) ) {}
			else
			{
				params.effectType = debuffType;
				params.creator = NULL;
				params.sourceName = "debuff_projectile";
				params.duration = customDuration;

				((CActor)victim).AddEffectCustom(params);
			}
		}
		else
		{
			action.AddEffectInfo(debuffType);
			action.SetProcessBuffsIfNoDamage(applyDebuffIfNoDmgWasDealt);
		}

		action.SetCanPlayHitParticle(false);
		theGame.damageMgr.ProcessAction( action );
		if ( signalDamageInstigatedEvent )
		{
			((CActor)caster).SignalGameplayEventParamObject( 'DamageInstigated', action );
		}
		if ( destroyQuen && ((W3PlayerWitcher)victim).IsQuenActive( false ) )
		{
			((W3PlayerWitcher)victim).FinishQuen( false );
		}

		delete action;


		if ( applyDebuffIfNoDmgWasDealt )
			victim.PlayEffect(specialFxOnVictimName);

		if ( bounceOnVictimHit )
		{
			this.BounceOff(normal,pos);
			this.Init(victim);
			return true;
		}
		}	//modSigns

		collidedEntities.PushBack(victim);
		isActive = false;
	}
	else if ( hitCollisionsGroups.Contains( 'Terrain' ) || hitCollisionsGroups.Contains( 'Static' ) || hitCollisionsGroups.Contains( 'Water' ) )
	{
		if( stopProjectileAfterCollision )
		{
			this.StopProjectile();
		}
		this.DestroyAfter( destroyAfterFloat );
		if( !persistFxAfterCollision )
		{
			this.StopEffect( initFxName );
		}
		this.PlayEffect(onCollisionFxName);
		isActive = false;
	}

	return false;
}
// ---- the leshen's roots and birds, the red-plague creature's roots ----

// 5.x body; changes marked //modSigns.
@replaceMethod(W3LeshyRootProjectile)
function DelayDamageTimer( delta : float , id : int)
{
	var attributeName 	: name;
	var victims 		: array<CGameplayEntity>;
	var rootDmg 		: float;
	var i 				: int;
	var damageAction	: W3DamageAction;	//modSigns

	//modSigns: removed the heavy attack's damage attribute (AI-18)
	rootDmg = 400;	//modSigns: AI-18, the roots' damage (legacy)


	//modSigns: removed the weapon attack (AI-18)


	FindGameplayEntitiesInRange( victims, fxEntity, 2, 99, , FLAG_OnlyAliveActors );

	if ( victims.Size() > 0 )
	{
		for ( i = 0 ; i < victims.Size() ; i += 1 )
		{
			if ( !((CActor)victims[i]).IsCurrentlyDodging() )
			{

				damageAction = new W3DamageAction in this;	//modSigns: AI-18, 400 rending with attack power and a heavy reaction (legacy; legacy's hit-animation and attacker lines before Initialize left out: Initialize clears them)
				damageAction.Initialize( (CGameplayEntity)caster, victims[i], this, caster.GetName()+"_"+"root_projectile", EHRT_Heavy, CPS_AttackPower, false, true, false, false);	//modSigns
				damageAction.AddDamage(theGame.params.DAMAGE_NAME_RENDING, rootDmg );	//modSigns
				theGame.damageMgr.ProcessAction( damageAction );	//modSigns
				delete damageAction;	//modSigns


				victims[i].OnRootHit();
			}
		}
	}

	//modSigns: removed the weapon attack's delete (AI-18)
}
// 5.x body; changes marked //modSigns.
@replaceMethod(W3LeshyBirdProjectile)
function OnProjectileCollision( pos, normal : Vector, collidingComponent : CComponent, hitCollisionsGroups : array< name >, actorIndex : int, shapeIndex : int )
{
	var victim : CGameplayEntity;
	var birdDmg : float;
	var attributeName : name;

	if(collidingComponent)
		victim = (CGameplayEntity)collidingComponent.GetEntity();
	else
		victim = NULL;

	if ( victim && victim == ((CActor)caster).GetTarget() )
	{
		projExpired = true;
		//modSigns: removed the bird's own hit (AI-18: the bird swarm deals the damage, legacy)

		AddTimer('TimeDestroy', 5.0, false);
	}
	delete action;
}
// DA5 (owner, 2026-10-28): the red-plague creature's roots follow the leshen's rule: 400 rending with attack power
// and a heavy reaction (5.x: 200 to 300 elemental, or the heavy attack's damage + 200, a light reaction). The body
// is rewritten: every line is marked.
@replaceMethod(W3RedPlagueProjectile)
function DelayDamageTimerNew( delta : float , id : int)
{
	var victims 		: array<CGameplayEntity>;	//modSigns
	var rootDmg 		: float;	//modSigns
	var i 				: int;	//modSigns

	rootDmg = 400;	//modSigns: AI-18, legacy's leshen roots
	FindGameplayEntitiesInRange( victims, fxEntity, 2, 99, , FLAG_OnlyAliveActors );	//modSigns
	for ( i = 0 ; i < victims.Size() ; i += 1 )	//modSigns
	{	//modSigns
		if ( !((CActor)victims[i]).IsCurrentlyDodging() )	//modSigns
		{	//modSigns
			damageAction = new W3DamageAction in this;	//modSigns
			damageAction.Initialize( (CGameplayEntity)caster, victims[i], this, caster.GetName()+"_"+"root_projectile", EHRT_Heavy, CPS_AttackPower, false, true, false, false);	//modSigns
			damageAction.AddDamage(theGame.params.DAMAGE_NAME_RENDING, rootDmg );	//modSigns
			theGame.damageMgr.ProcessAction( damageAction );	//modSigns
			delete damageAction;	//modSigns
			victims[i].OnRootHit();	//modSigns
		}	//modSigns
	}	//modSigns
}

// ---- ice spikes, the witch's boiling water, bird swarms, objects striking back, the toad's acid pool ----

// 5.x body; changes marked //modSigns.
@replaceMethod(W3IceSpike)
function DealDamage( optional _Delta : float, optional id : int)
{
	var i						: int;
	var l_actorsRange			: array <CActor>;
	var l_range					: float;
	var l_actor					: CActor;
	var none					: SAbilityAttributeValue;
	var l_damageAction			: W3DamageAction;
	var l_summonedEntityComp 	: W3SummonedEntityComponent;
	var	l_summoner				: CActor;
	var l_damageAttr 			: SAbilityAttributeValue;
	var l_inv					: CInventoryComponent;
	var l_weaponId 				: SItemUniqueId;
	var l_damageValue			: float;
	var l_damageNames			: array < CName >;
	var l_attribute				: name;


	l_summonedEntityComp = (W3SummonedEntityComponent) GetComponentByClassName('W3SummonedEntityComponent');

	if( !l_summonedEntityComp )
	{
		return;
	}

	l_summoner = l_summonedEntityComp.GetSummoner();

	l_range = 0.3f;
	l_actorsRange = GetActorsInRange( this, l_range, -1, , true );

	for	( i = 0; i < l_actorsRange.Size(); i += 1 )
	{
		l_actor = (CActor) l_actorsRange[i];

		if ( l_actor == l_summoner ) continue;

		l_damageAction = new W3DamageAction in this;
		l_damageAction.Initialize( l_summoner, l_actor, l_summoner, l_summoner.GetName(), EHRT_Heavy, CPS_AttackPower, false, false, false, true );	//modSigns: AI-18, attack power (legacy)

		l_summoner.GetVisualDebug().AddSphere('DetectionRange', l_range, GetWorldPosition(), true);
		l_summoner.GetVisualDebug().AddText('DetectionRangeText', "Ice", GetWorldPosition(), true);

		if ( damageValue < 1 )	//modSigns: AI-18, 100 when unset (legacy)
		{	//modSigns
			damageValue = 100;	//modSigns
		}	//modSigns
		//modSigns: removed the summoner's weapon damage and the physical damage (AI-18)
		l_damageAction.AddDamage( theGame.params.DAMAGE_NAME_FROST, damageValue );	//modSigns: AI-18, the spike's own frost damage (legacy)

		theGame.damageMgr.ProcessAction( l_damageAction );
		delete l_damageAction;
	}
}
// 5.x body; changes marked //modSigns. 5.x's new path (a weapon attack below 101 damage) uses attack power already.
@replaceMethod(W3WitchBoilingWaterObstacle)
function Appear( _Delta : float, optional id : int)
{
	var i						: int;
	var l_entitiesInRange		: array <CGameplayEntity>;
	var l_damage				: W3DamageAction;
	var l_action 				: W3Action_Attack;
	var l_actor					: CActor;
	var none					: SAbilityAttributeValue;
	var l_tempBool				: bool;

	if ( !l_tempBool )
	{
		if ( !SetParams() ) return;
		l_tempBool = true;
	}

	if ( IsNameValid(attackEffectName) && !playAttackEffectOnlyWhenHit )
	{
		if ( useSeperateAttackEffectEntity )
		{
			fxEntity = theGame.CreateEntity( useSeperateAttackEffectEntity, this.GetWorldPosition(), this.GetWorldRotation() );
			fxEntity.PlayEffect(attackEffectName);
			fxEntity.DestroyAfter( 5.0 );
		}
		else
		{
			PlayEffect(attackEffectName);
		}

		if ( onAttackEffectCameraShakeStrength > 0 )
		{
			GCameraShake( onAttackEffectCameraShakeStrength, true, l_actor.GetWorldPosition(), 30.0f );
		}
	}

	FindGameplayEntitiesInRange( l_entitiesInRange, this, attackRadius, 1000);

	for	( i = 0; i < l_entitiesInRange.Size(); i += 1 )
	{
		l_actor = (CActor) l_entitiesInRange[i];
		if ( !l_actor ) continue;

		if ( l_actor == summoner ) continue;

		if ( IsNameValid( ignoreVictimWithTag ) && l_actor.HasTag( ignoreVictimWithTag ) ) continue;

		if ( !l_actor.IsCurrentlyDodging() )
		{

			if( damageValue < 101 && !summoner.HasTag( 'q111_witch' ) )
			{
				if ( simpleDamageAction )
				{
					l_action = new W3Action_Attack in theGame.damageMgr;

					l_action.Init( (CGameplayEntity)summoner, l_actor, NULL, ((CGameplayEntity)summoner).GetInventory().GetItemFromSlot( 'r_weapon' ), 'attack_heavy', ((CGameplayEntity)summoner).GetName(), EHRT_Heavy, false, true, 'attack_heavy', AST_Jab, ASD_DownUp, false, false, false, true );
					l_action.GetDamageValueTotal();
					theGame.damageMgr.ProcessAction( l_action );

					if ( onHitCameraShakeStrength > 0 )
						GCameraShake( onHitCameraShakeStrength, true, l_actor.GetWorldPosition(), 30.0f );

					delete l_action;
				}
				if ( applyDebuffType != EET_Undefined )
				{
					l_actor.AddEffectCustom(params);
				}

				if ( IsNameValid(attackEffectName) && playAttackEffectOnlyWhenHit )
				{
					if ( useSeperateAttackEffectEntity )
					{
						fxEntity = theGame.CreateEntity( useSeperateAttackEffectEntity, l_actor.GetWorldPosition(), l_actor.GetWorldRotation() );
						fxEntity.PlayEffect(attackEffectName);
						fxEntity.DestroyAfter( 5.0 );
					}
					else
					{
						PlayEffect(attackEffectName);
					}
				}

			}
			else if ( damageValue > 0 )
			{
				if ( simpleDamageAction )
				{
					l_damage = new W3DamageAction in this;
					l_damage.Initialize( summoner, l_actor, summoner, summoner.GetName(), hitReactionType, CPS_AttackPower, false, false, false, true );	//modSigns: AI-18, attack power (PA12, legacy)
					l_damage.AddDamage( theGame.params.DAMAGE_NAME_PHYSICAL, damageValue );
					theGame.damageMgr.ProcessAction( l_damage );
					delete l_damage;

					if ( onHitCameraShakeStrength > 0 )
						GCameraShake( onHitCameraShakeStrength, true, l_actor.GetWorldPosition(), 30.0f );
				}
				if ( applyDebuffType != EET_Undefined )
				{
					l_actor.AddEffectCustom(params);
				}

				if ( IsNameValid(attackEffectName) && playAttackEffectOnlyWhenHit )
				{
					if ( useSeperateAttackEffectEntity )
					{
						fxEntity = theGame.CreateEntity( useSeperateAttackEffectEntity, l_actor.GetWorldPosition(), l_actor.GetWorldRotation() );
						fxEntity.PlayEffect(attackEffectName);
						fxEntity.DestroyAfter( 5.0 );
					}
					else
					{
						PlayEffect(attackEffectName);
					}
				}
			}
		}
	}
}
// 5.x body; changes marked //modSigns.
@replaceMethod(CFlyingCrittersLairEntityScript)
function OnBoidPointOfInterestReached( boidCount : int, entity : CEntity, deltaTime : float  )
{
	var action 				: W3DamageAction;
	var damageResistance 	: float;
	var damage			 	: float;
	var xmlDamageModifier	: float;


	if ( (CPlayer)entity || ( m_birdMaster && GetAttitudeBetween( m_birdMaster, entity ) == AIA_Hostile ))
	{
		LogChannel('swarmDebug', "swarm boidcount = " +  boidCount);

		xmlDamageModifier = CalculateAttributeValue( ((CActor)m_birdMaster).GetAttributeValue( 'swarm_attack_damage_vitality' ));
		damage = xmlDamageModifier * boidCount * deltaTime;

		if( damage > 0 )
		{
			action = new W3DamageAction in this;
			action.Initialize( this, (CGameplayEntity)entity, this, this.GetName()+"_"+"root_projectile", EHRT_None, CPS_Undefined,false,false,false,true);	//modSigns: AI-18, no attack power (legacy)


			action.SetIgnoreArmor( true );


			action.AddDamage(theGame.params.DAMAGE_NAME_RENDING, damage );



			LogCritical("About to apply new swarm effect");
			action.AddEffectInfo(EET_Swarm);

			theGame.damageMgr.ProcessAction( action );
			delete action;
			GCameraShake( 0.05, true, thePlayer.GetWorldPosition() );
		}
	}
}
// 5.x body; changes marked //modSigns.
@replaceMethod(W3ReactToBeingHitEntity)
function DealDamage( action : W3DamageAction )
{
	var attacker 		: CActor;
	var params 			: SCustomEffectParams;
	var damage 			: float;

	if ( !IsNameValid( attributeName ) )
	{
		attributeName = damageTypeName;	//modSigns: AI-18, its own damage type (legacy; 5.x: the heavy attack's physical damage)
	}
	attacker = (CActor) action.attacker;
	if ( attacker )
	{
		damage = CalculateAttributeValue( attacker.GetAttributeValue( attributeName ) );
		if ( damage < 1 )	//modSigns: AI-18, the larger of 500 and half Geralt's health when no damage is set (legacy)
		{	//modSigns
			damage = MaxF(500, 0.5 * thePlayer.GetMaxHealth());	//modSigns
		}	//modSigns
		if ( killOnHpBelowPerc > 0 && attacker.GetHealthPercents() <= killOnHpBelowPerc )
		{
			if ( IsNameValid( setBehVarOnKill ) )
			{
				attacker.SetBehaviorVariable( setBehVarOnKill, behVarValue );
			}
			attacker.Kill( 'W3ReactToBeingHitEntity' );
		}
		else
		{
			action = new W3DamageAction in this;

			if ( debuffType != EET_Undefined )
			{
				params.effectType = debuffType;
				params.creator = this;
				params.sourceName = this.GetName();
				if ( debuffDuration > 0 )
				{
					params.duration = debuffDuration;
				}
				((CActor)attacker).AddEffectCustom(params);
			}

			action.attacker = this;
			action.Initialize( this, attacker, NULL, this.GetName(), EHRT_Heavy, CPS_Undefined, false, false, false, true );	//modSigns: AI-18, a heavy reaction (legacy)
			action.AddDamage( damageTypeName, damage );
			theGame.damageMgr.ProcessAction( action );
			if ( IsNameValid( effectOnHitVictim ) )
			{
				PlayEffectSingle( effectOnHitVictim );
			}
			delete action;
		}
	}
}
// 5.x body; changes marked //modSigns.
@replaceMethod(CToadAcidPool)
function OnFireHit( source : CGameplayEntity )
{

	var i : int;


	if(! hasExploded)
	{
		hasExploded = true;

		StopAllEffects();
		PlayEffect( 'toxic_gas_explosion' );
		GCameraShake( 1.5, true, GetWorldPosition(), 20.0f );


		if ( thePlayer.IsCameraLockedToTarget() && thePlayer.GetDisplayTarget() == this )
		{
			thePlayer.OnForceSelectLockTarget();
		}

		FindGameplayEntitiesInSphere(entitiesInRange, this.GetWorldPosition(), explosionRange, 10);
		entitiesInRange.Remove(this);
		for( i = 0; i < entitiesInRange.Size(); i += 1 )
		{
			targetEntity = (CActor)entitiesInRange[i];

			if(targetEntity)
			{
				damage = new W3DamageAction in this;
				damage.Initialize( this, entitiesInRange[i], NULL, this, EHRT_Heavy, CPS_Undefined, false, false, false, true );	//modSigns: AI-18, a heavy reaction (legacy)
				//modSigns: removed the damage per level of the victim (AI-18)
				damage.AddDamage( theGame.params.DAMAGE_NAME_FIRE, MaxF(damageVal, 0.2 * ((CActor)targetEntity).GetMaxHealth()) );	//modSigns: AI-18, at least 20% of the victim's health (legacy)
				damage.AddEffectInfo(EET_KnockdownTypeApplicator);
				damage.SetProcessBuffsIfNoDamage(true);
				theGame.damageMgr.ProcessAction( damage );

				delete damage;
			}
			else
			{
				entitiesInRange[i].OnFireHit(this);
			}
		}

		super.OnFireHit(source);
		RemoveTimer( 'PoisonVictim' );
		this.StopEffect(fxOnSpawn);
		this.DestroyAfter(3.f);

	}
}
// ---- the Blood and Wine tornado and ground trap ----

// 5.x body; changes marked //modSigns.
@replaceMethod(CBTTaskTornadoAttack)
function Main() : EBTNodeStatus
{
	var npc						: CNewNPC = GetNPC();
	var targetNode 				: CNode;
	var targetPos 				: Vector;
	var params 					: SCustomEffectParams;
	var action 					: W3DamageAction;
	var movementAdjustor 		: CMovementAdjustor;
	var ticket 					: SMovementAdjustmentRequestTicket;
	var attributeName 			: name;
	var victims 				: array<CGameplayEntity>;
	var actorVictims 			: CActor;
	var damage 					: float;
	var lastShakeTime 			: float;
	var lastDebuffTime 			: float;
	var lastDamageTime 			: float;
	var timeStamp 				: float;
	var lastVictimsTestTime 	: float;
	var distToTarget 			: float;
	var camShakeStrength		: float;
	var res 					: bool;
	var i 						: int;


	//modSigns: removed the damage from the attacker's light attack (AI-18: 2% of each victim's health, below)
	action = new W3DamageAction in this;
	timeStamp = GetLocalTime();

	npc.SetBehaviorVariable( setBehVarOnDeactivation, 0 );
	res = false;

	if ( IsNameValid( activateOnAnimEvent ) )
	{
		while( !m_activated )
		{
			if ( timeStamp + castingLoopTime < GetLocalTime() && !res )
			{
				npc.SetBehaviorVariable( setBehVarOnDeactivation, setBehVarValueOnDeactivation );
				res = true;
			}
			SleepOneFrame();
		}
	}
	else
	{
		m_activated = true;
	}

	while( m_activated )
	{
		SleepOneFrame();

		if ( lastShakeTime + cameraShakeInterval < GetLocalTime() )
		{
			lastShakeTime = GetLocalTime();
			targetPos = GetCombatTarget().GetWorldPosition();
			distToTarget = VecDistance2D( targetPos, npc.GetWorldPosition() );
			camShakeStrength = ClampF( 1 - ( distToTarget / cameraShakeRange ), 0, 1 ) * ((  maxCameraShakeStrength - minCameraShakeStrength ) + minCameraShakeStrength );
			GCameraShake(camShakeStrength, true, npc.GetWorldPosition(), 30.0f);
		}

		if ( lastVictimsTestTime + victimTestInterval < GetLocalTime() )
		{
			lastVictimsTestTime = GetLocalTime();
			victims.Clear();
			FindGameplayEntitiesInRange( victims, npc, affectEnemiesInRangeMax, 99, , FLAG_OnlyAliveActors );
		}

		if ( ( debuffTypeInRangeMin != EET_Undefined || debuffTypeInRangeMax != EET_Undefined ) && lastDebuffTime + debuffInterval < GetLocalTime() )
		{
			lastDebuffTime = GetLocalTime();

			if ( victims.Size() > 0 )
			{
				for ( i = 0 ; i < victims.Size() ; i += 1 )
				{
					actorVictims = (CActor)victims[i];
					if ( actorVictims != npc )
					{
						if ( VecDistance( actorVictims.GetWorldPosition(), npc.GetWorldPosition() ) <= affectEnemiesInRangeMin )
						{
							if ( !actorVictims.HasBuff( debuffTypeInRangeMin ) )
							{
								params.effectType = debuffTypeInRangeMin;
								if ( debuffDurationInRangeMin > 0 )
									params.duration = debuffDurationInRangeMin;

								if ( IsNameValid( rotateToNodeByTagOnDebuffMin ) )
								{
									movementAdjustor = actorVictims.GetMovingAgentComponent().GetMovementAdjustor();
									ticket = movementAdjustor.CreateNewRequest( 'Tornado' );
									targetNode = theGame.GetNodeByTag( rotateToNodeByTagOnDebuffMin );
									movementAdjustor.RotateTowards( ticket, targetNode, 45 );
								}
							}
						}
						else
						{
							if ( !((W3PlayerWitcher)actorVictims).IsQuenActive( true ) && !((W3PlayerWitcher)actorVictims).IsQuenActive( false ) )
							{
								params.effectType = debuffTypeInRangeMax;
								if ( debuffDurationInRangeMax > 0 )
									params.duration = debuffDurationInRangeMax;
							}
						}
						params.creator = npc;
						params.sourceName = npc.GetName();

						actorVictims.AddEffectCustom(params);
					}
				}
			}
		}

		if ( lastDamageTime + damageInterval < GetLocalTime() )
		{
			lastDamageTime = GetLocalTime();
			if ( victims.Size() > 0 )
			{
				for ( i = 0 ; i < victims.Size() ; i += 1 )
				{
					actorVictims = (CActor)victims[i];

					if ( victims[i] != npc && !actorVictims.IsCurrentlyDodging() )
					{
						action.Initialize( npc, actorVictims, this, npc.GetName(), EHRT_None, CPS_Undefined, false, true, false, false );
						action.SetHitAnimationPlayType(EAHA_ForceNo);
						action.attacker = npc;
						action.SetSuppressHitSounds(true);
						action.SetHitEffect( '' );
						//modSigns: removed SetIgnoreArmor (AI-18: armor applies, legacy)
						damage = 0.02 * actorVictims.GetMaxHealth();	//modSigns: AI-18, 2% of the victim's health per tick (legacy)
						action.AddDamage(theGame.params.DAMAGE_NAME_PHYSICAL, damage );
						action.SetIsDoTDamage( damageInterval );
						theGame.damageMgr.ProcessAction( action );

						npc.SignalGameplayEventParamObject( 'DamageInstigated', action );

						if ( ((W3PlayerWitcher)actorVictims).IsQuenActive( false ) )
							((W3PlayerWitcher)actorVictims).FinishQuen( false );
					}
				}
			}
		}

		if ( timeStamp + castingLoopTime < GetLocalTime() && !res )
		{
			npc.SetBehaviorVariable( setBehVarOnDeactivation, setBehVarValueOnDeactivation );
			res = true;
		}
	}

	delete action;
	return BTNS_Active;
}
// 5.x body; changes marked //modSigns.
@replaceMethod(CBTTaskGroundTrapAttack)
function Main() : EBTNodeStatus
{
	var npc						: CNewNPC = GetNPC();
	var params 					: SCustomEffectParams;
	var action 					: W3DamageAction;
	var reactToHitEntity		: W3ReactToBeingHitEntity;
	var spawnPos 				: Vector;
	var attributeName 			: name;
	var victims 				: array<CGameplayEntity>;
	var damage 					: float;
	var timeStamp 				: float;
	var res1, res2, res3		: bool;
	var i 						: int;


	if ( !m_trapEntity )
	{
		m_trapEntity = (CEntityTemplate)LoadResourceAsync( trapResourceName );
	}

	if ( !m_trapEntity )
	{
		return BTNS_Failed;
	}

	//modSigns: removed the damage from the attacker's light attack (AI-18: by each victim's health, below)

	action = new W3DamageAction in this;
	//modSigns: removed EAHA_ForceNo (AI-18, legacy; a no-op: Initialize clears it. The light reaction comes from EHRT_Light below)

	if ( IsNameValid( activateOnAnimEvent ) )
	{
		while( !m_activated )
		{
			SleepOneFrame();
		}
	}
	else
	{
		m_activated = true;
	}

	while ( m_activated )
	{
		if ( timeStamp == 0 )
			timeStamp = GetLocalTime();

		SleepOneFrame();

		if ( !res3 )
		{
			if ( randomizePosition )
			{
				spawnPos = FindPosition();
				while( !IsPositionValid( spawnPos, guaranteedHit ) )
				{
					SleepOneFrame();
					spawnPos = FindPosition();
				}
				guaranteedHit = false;
			}
			else
			{
				spawnPos = GetCombatTarget().GetWorldPosition();
			}
			m_trap = (CGameplayEntity)theGame.CreateEntity( m_trapEntity, spawnPos, npc.GetWorldRotation() );
			if ( IsNameValid( playFxOnTrapSpawn ) && m_trap )
				m_trap.PlayEffect( playFxOnTrapSpawn );

			res3 = true;
		}

		if ( ( timeStamp + delayDamageFx ) < GetLocalTime() && !res1 )
		{
			res1 = true;

			if ( IsNameValid( playFxDamage ) )
				m_trap.PlayEffect( playFxDamage );
		}

		if ( ( timeStamp + delayDamage ) < GetLocalTime() && !res2 )
		{
			victims.Clear();
			FindGameplayEntitiesInRange( victims, m_trap, affectEnemiesInRange, 99 );

			if ( camShakeStrength > 0 )
				GCameraShake(camShakeStrength, true, m_trap.GetWorldPosition(), 30.0f);

			if ( victims.Size() > 0 )
			{
				for ( i = 0 ; i < victims.Size() ; i += 1 )
				{
					reactToHitEntity = (W3ReactToBeingHitEntity)victims[i];
					if ( reactToHitEntity )
					{
						reactToHitEntity.ActivateEntity();
					}
					if ( ( allowDamageSelf || victims[i] != npc ) && !((CActor)victims[i]).IsCurrentlyDodging() && !((CActor)victims[i]).IsInvulnerable()
						&& ((CActor)victims[i]).GetGameplayVisibility() && ((CActor)victims[i]).IsAlive() )
					{
						if ( debuffType != EET_Undefined )
						{
							params.effectType = debuffType;
							params.creator = m_trap;
							params.sourceName = m_trap.GetName();
							if ( debuffDuration > 0 )
								params.duration = debuffDuration;

							((CActor)victims[i]).AddEffectCustom(params);
						}

						action.attacker = m_trap;
						action.Initialize( m_trap, victims[i], NULL, m_trap.GetName(), EHRT_Light, CPS_Undefined, false, false, false, true);	//modSigns: AI-18, a light reaction (legacy)
						damage = MaxF(500, 0.2 * ((CActor)victims[i]).GetMaxHealth());	//modSigns: AI-18, the larger of 500 and 20% of the victim's health (legacy)
						action.AddDamage(theGame.params.DAMAGE_NAME_DIRECT, damage );	//modSigns: AI-18, direct damage (legacy)
						theGame.damageMgr.ProcessAction( action );
						if ( IsNameValid( playFxOnDamageVictim ) )
						{
							victims[i].PlayEffect( playFxOnDamageVictim );
						}
						if ( IsNameValid( raiseEventOnDamageNPC ) && victims[i] != thePlayer )
						{
							victims[i].RaiseEvent( raiseEventOnDamageNPC );
							((CActor)victims[i]).SignalGameplayEvent( 'CustomHit' );
						}
					}
				}
			}

			res2 = true;
			m_activated = false;
		}
	}

	victims.Clear();
	delete action;
	if ( completeAfterMain )
	{
		return BTNS_Completed;
	}
	else
	{
		return BTNS_Active;
	}
}
class CBTTaskGroundTrapAttackDef extends CBTTaskAttackDef
{
	default damageTypeName = 'DirectDamage';	//modSigns: AI-18 (5.x: RendingDamage; the task deals direct damage)
}

// ---- magic fists ----

// Lightning and fire fists deal ranged damage, not melee damage (legacy's fix in W3Action_Attack.Init).
@wrapMethod(W3Action_Attack)
function Init( attackr : CGameplayEntity, victm : CGameplayEntity, causr : IScriptable, weapId : SItemUniqueId, attName : name, src :string, hrt : EHitReactionType, canParry : bool, canDodge : bool, skillName : name, swType : EAttackSwingType, swDir : EAttackSwingDirection, isM : bool, isR : bool, isW : bool, isE : bool, optional hitFX_ : name, optional hitBackFX_ : name, optional hitParriedFX_ : name, optional hitBackParriedFX_ : name, optional crossId : SItemUniqueId)
{
	var weaponName : name;
	var actor : CActor;

	actor = (CActor)attackr;
	if( actor )
	{
		weaponName = actor.GetInventory().GetItemName(weapId);
		if( weaponName == 'fists_lightning' || weaponName == 'fists_fire' )
		{
			isM = false;
			isR = true;
		}
	}
	wrappedMethod(attackr, victm, causr, weapId, attName, src, hrt, canParry, canDodge, skillName, swType, swDir, isM, isR, isW, isE, hitFX_, hitBackFX_, hitParriedFX_, hitBackParriedFX_, crossId);
}
