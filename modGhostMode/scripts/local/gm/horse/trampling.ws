// HORSE-03: trampling, legacy's (1.32's) rule (DH2 (a)): the horse deals damage only to hostiles (not animals),
// only at a canter or full gallop (speed 3 and up), only head-on (from the side only to an enemy already knocked
// down): the horse weapon (AI-05's) plus 50 x speed physical, once a second per enemy. 5.x hit from the side and
// at any speed the horse moved, animals too, with 15 (head-on) or 5 (side) x speed force damage capped at 1/15
// of the victim's maximum health. 5.x's kick sound on the hit is kept.
// See docs/features/horse.md.

// The horse's speed as trampling reads it (a method, so the tests can set it: the horse's real speed comes from her
// movement).
@addMethod(W3HorseComponent)
function GMTrampleSpeed() : float
{
	return InternalGetSpeed();
}

// 5.x's kick sound on a trampled enemy (a method, so the tests can tell when it plays).
@addMethod(W3HorseComponent)
function GMTrampleKickSound(victim : CActor)
{
	victim.SoundEvent("cmb_play_horse_kick");
}

@replaceMethod(W3HorseComponent)
function ShouldDealDamageToActor( collidedActor : CActor, sideCollision : bool )
{
	var attacker : CActor;

	attacker = GetCurrentUser();

	if( !attacker )
		attacker = (CActor)GetEntity();

	if( IsRequiredAttitudeBetween( attacker, collidedActor, true ) ) //modSigns: hostiles only (5.x: animals too)
	{
		if( collidedActor.IsUsingHorse() || ((CNewNPC)collidedActor).IsHorse() )
		{
			return;
		}
		else
		{
			if( GMTrampleSpeed() >= 3.0 ) //modSigns: canter and up (5.x: any speed the horse moves, distanceBasedSpeed)
			{
				DealDamageToCollidedActor( attacker, collidedActor, sideCollision );
			}
		}
	}
}

@replaceMethod(W3HorseComponent)
function DealDamageToCollidedActor( owner, collidedActor : CActor, sideCollision : bool )
{
	var itemId : SItemUniqueId;
	var action : W3Action_Attack;
	var horse : CActor;
	var collisionData : CollsionActorStruct;
	//modSigns: removed damageVal

	if( !CanCollideWithThisActor( collidedActor ) )
		return;

	horse = (CActor)GetEntity();

	//modSigns: removed the living-victims check (1.32 hits a downed enemy whatever its state)
	if( !sideCollision || collidedActor.HasBuff( EET_Knockdown ) || collidedActor.HasBuff( EET_HeavyKnockdown ) ) //modSigns: head-on, or a downed enemy from the side
	{
		itemId = horse.GetInventory().GetItemFromSlot( 'r_weapon' );
		if( !horse.GetInventory().IsIdValid( itemId ) )
			return ;

		action = new W3Action_Attack in theGame.damageMgr;
		action.Init( owner, collidedActor, horse, itemId, 'attack_speed_based', horse.GetName(), EHRT_Heavy, false, false, 'attack_speed_based', AST_Jab, ASD_UpDown,true,false,false,false ); //modSigns: AST_Jab (1.32)
		//modSigns: removed the force damage (15 or 5 x speed, at most 1/15 of the victim's maximum health)
		if( collidedActor.IsAlive() ) //modSigns: HORSE audit F6, 5.x's kick sound for a living victim only (as 5.x's guard held it)
			GMTrampleKickSound( collidedActor ); //modSigns: 5.x's SoundEvent("cmb_play_horse_kick"), through a method the tests can see
		action.AddDamage( theGame.params.DAMAGE_NAME_PHYSICAL, 50.0 * MaxF( GMTrampleSpeed(), 1 ) ); //modSigns: 1.32's 50 x speed physical
		theGame.damageMgr.ProcessAction( action );
		delete action;
	}


	collisionData.actor = collidedActor;
	collisionData.timestamp = theGame.GetEngineTimeAsSeconds();
	collidedActors.PushBack( collisionData );
}
