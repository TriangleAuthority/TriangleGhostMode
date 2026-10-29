// EFX-09: killing a frozen rotfiend (docs/features/efx.md). Monsters with the LastBreath ability (rotfiends)
// cannot be killed by a hit: at low health they start their death explosion. The hit that shatters
// their freeze is not held back (CActor.ReduceDamage, damage/pipeline.ws): it can kill one outright,
// and the one it kills gets the tag ExplodeNoDamage (CActor.OnTakeDamage, mutations/takeDamage.ws),
// so its death explosion deals no damage (legacy's changelist, Enemy AI: "Killing a frozen rotfiend
// now prevents the explosion"). AI-17: the explosion deals the damage of the monster's weapon in the
// task's slot, 300 without one (legacy; 5.x: 100 + 3x the weapon's heavy frost damage on Normal, 50 + 2x
// on Easy, 150 + 4x on Hard, 200 + 5x on Death March), its attack power and the victims' armor applying.
// 5.x's Northern Wind blocks PoisonDeath, so a rotfiend frozen by it does not explode at all (ALCH-14, kept).

// 5.x body; changes marked //modSigns.
@replaceMethod(BTTaskExplodeAtDeath)
function Explode()
{
	var l_actor 				: CActor;	
	var l_dismembermentComp 	: CDismembermentComponent;
	var l_wounds				: array< name >;
	var l_actors				: array< CActor >;
	var l_usedWound				: name;
	var i						: int;
	var l_damageAction			: W3DamageAction;
	
	var l_damageAttr 			: SAbilityAttributeValue;
	var l_inv					: CInventoryComponent;
	var l_weaponId 				: SItemUniqueId;
	var l_damageNames			: array < CName >;
	var l_attribute				: name;
	
	l_actor = GetNPC();
	
	l_dismembermentComp = (CDismembermentComponent)(l_actor.GetComponentByClassName( 'CDismembermentComponent' ));
	if(!l_dismembermentComp) return;
	
	l_dismembermentComp.GetWoundsNames( l_wounds, WTF_Explosion );
	
	if ( l_wounds.Size() > 0 )
					l_usedWound = l_wounds[ RandRange( l_wounds.Size() ) ];
					
	l_actor.SetDismembermentInfo( l_usedWound, Vector( 0, 0, 10 ), false );
	l_actor.AddTimer( 'DelayedDismemberTimer', 0.05f );
	
	m_hasExploded = true;
	
	l_actor.GetVisualDebug().AddSphere( 'ExplosionRange', damageRadius, Vector(0,0,0),,,5 );
	
	if( damageRadius > 0 && !l_actor.HasTag('ExplodeNoDamage') )	//modSigns: EFX-09, no damage from a rotfiend killed by a frozen hit
	{
		l_actors = GetActorsInRange(  GetNPC(), damageRadius, -1,, true );
		
		if( l_actors.Size() > 0 )
		{
			l_damageAction = new W3DamageAction in this;
			
			if( IsNameValid( weaponSlot ) )
			{
				l_inv 		= l_actor.GetInventory();		
				l_weaponId 	= l_inv.GetItemFromSlot( weaponSlot );
				l_inv.GetWeaponDTNames( l_weaponId, l_damageNames );
				//modSigns: removed the weapon's heavy frost damage attribute (AI-17)
				l_damageAttr.valueAdditive = 0;	//modSigns
				l_damageAttr.valueMultiplicative = 1;	//modSigns
				l_damageAttr.valueBase  =l_actor.GetTotalWeaponDamage( l_weaponId, l_damageNames[0], GetInvalidUniqueId() );
				
				//modSigns: removed 5.x's damage by difficulty (AI-17)
				damageValue = CalculateAttributeValue(l_damageAttr);	//modSigns: AI-17, the weapon's damage (legacy)
			}
			if ( damageValue < 1 )	//modSigns: AI-17, 300 without a weapon (legacy)
			{	//modSigns
				damageValue = 300;	//modSigns
			}	//modSigns
			
			for	( i = 0; i < l_actors.Size(); i += 1 )
			{
				if( l_actors[i] == GetNPC() ) 
					continue;
					
				l_damageAction.Initialize( l_actor, l_actors[i], NULL, "Explosion", EHRT_Heavy, CPS_AttackPower, false, true, false, false );
				l_damageAction.SetCannotReturnDamage( true );
				
				l_damageAction.AddDamage(  theGame.params.DAMAGE_NAME_PHYSICAL, damageValue );
				l_damageAction.AddDamage(  theGame.params.DAMAGE_NAME_SILVER, damageValue );
				l_damageAction.AddEffectInfo( EET_Stagger, 1.0f );
				theGame.damageMgr.ProcessAction( l_damageAction );
				
			}
			
			delete( l_damageAction );
		}
	}		
}
