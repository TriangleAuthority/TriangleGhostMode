// HORSE-01: the sword hit from horseback. No stamina drain on the enemy hit, and the bonus by speed is the
// weapon's own damage: each damage type of the hit gets speed/4 more (walk x1.25 to full gallop x2; none
// standing), through the damage formula like the rest of the hit (vanilla: a direct-damage bonus of 50,
// 50 x (1.1 + speed) from a trot up, which ignores armor and resistances). The knockdown at full gallop,
// the sound, the effects and the blood trail as vanilla. The baseDamage parameter is no longer read (PH1).
// DH1 (a), a deviation from legacy's code: a fresh attack for each enemy of the swing. Vanilla reuses one
// attack and W3Action_Attack.Clear keeps its damage list, so each enemy's hit carried the previous ones'.
// See docs/features/horse.md.

@replaceMethod(W3VehicleCombatManagerStateSwordAttack)
function DealDamageToHostiles( entities : array<CGameplayEntity>, speed : float, baseDamage : float )
{
	var damage : W3Action_Attack;
	var i : int;
	var actor : CActor;
	var horse : CNewNPC;
	var bloodTrailParam : CBloodTrailEffect;
	var weaponId : SItemUniqueId;
	var dmgInfos : array< SRawDamage >; //modSigns
	var dmgSize, k : int; //modSigns

	horse = (CNewNPC)(rider.GetUsedVehicle());
	//modSigns: removed damage = new W3Action_Attack in this; (DH1: one attack per enemy, below)

	for( i = 0 ; i < entities.Size() ; i += 1 )
	{
		actor = (CActor)entities[i];

		if ( actor == rider || actor == horse || GetAttitudeBetween( rider, actor ) != AIA_Hostile )
			continue;

		if( actor )
		{
			//modSigns: removed actor.DrainStamina(ESAT_FixedValue, 100, 1);
			damage = new W3Action_Attack in this; //modSigns: DH1, a fresh attack for each enemy

			damage.Init( rider, actor ,NULL, rider.GetInventory().GetItemFromSlot( 'r_weapon' ),'attack_heavy',rider.GetName(),EHRT_Heavy, false, false, 'attack_heavy', AST_Jab, ASD_NotSet, true, false, false, false );
			//modSigns: removed the direct-damage bonus (baseDamage, or baseDamage * MaxF(1.1 + speed, 1) from speed 2)
			if( speed > 0 ) //modSigns
			{ //modSigns
				dmgSize = damage.GetDTs( dmgInfos ); //modSigns
				for( k = 0; k < dmgSize; k += 1 ) //modSigns
				{ //modSigns
					if( dmgInfos[k].dmgVal > 0 ) //modSigns
					{ //modSigns
						damage.AddDamage( dmgInfos[k].dmgType, dmgInfos[k].dmgVal * ClampF( speed / 4.0, 0.0f, 1.0f ) ); //modSigns
					} //modSigns
				} //modSigns
			} //modSigns
			if( speed >= 4.0 )
				damage.AddEffectInfo( EET_KnockdownTypeApplicator );
			damage.SetSoundAttackType('wpn_slice')	;

			theGame.damageMgr.ProcessAction( damage );
			delete damage; //modSigns: DH1
			actor.PlayEffect( 'heavy_hit_horseriding' );

			bloodTrailParam = (CBloodTrailEffect)actor.GetGameplayEntityParam( 'CBloodTrailEffect' );
			if( bloodTrailParam )
			{
				weaponId = thePlayer.inv.GetItemFromSlot( 'r_weapon' );
				thePlayer.inv.PlayItemEffect( weaponId, 'blood_trail_horseriding' );
			}

		}
	}
	//modSigns: removed delete damage; (DH1: deleted after each enemy's hit)
}
