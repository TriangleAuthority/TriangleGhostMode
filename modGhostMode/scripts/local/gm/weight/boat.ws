// WGT-10: a boat sinks under Geralt when he steps onto it overburdened by more than the threshold (OPT's options
// "Sink the boat if overencumbered", on by default, and "Overencumbrance threshold to sink the boat (%)", 20 by
// default: DW3), with "Your over encumbrance is too high" (2110992179). Boats that cannot be destroyed and the boat
// Geralt stands on as a save loads are spared (docs/features/wgt.md).
@replaceMethod(W3Boat)
function OnAreaEnter( area : CTriggerAreaComponent, activator : CComponent )
{
	var player : CR4Player;

	player = (CR4Player)activator.GetEntity();

	if( player )
	{
		if( area.GetName() == "FirstDiscoveryTrigger" )
		{
			area.SetEnabled( false );
		}
		else if( area.GetName() == "OnBoatTrigger" )
		{
			player.SetIsOnBoat( true );
			player.BlockAction( EIAB_RunAndSprint, 'OnBoatTrigger', false, false, true );
			player.BlockAction( EIAB_CallHorse, 'OnBoatTrigger', false, false, true );

			if( !HasDrowned() )
			{
				if( GMGetOptionBool('GMGameplayOptions', 'GMSinkBoat') && boatComp && theGame.GetLoadGameProgress() == 0 && GetCanBeDestroyed() && GMCheckPlayerEncumbrance((W3PlayerWitcher)player) ) //modSigns: sink the boat if the overencumbrance is too big
				{ //modSigns
					boatComp.TriggerDrowning( player.GetWorldPosition() ); //modSigns
					SetHasDrowned( true ); //modSigns
					SoundEvent( "boat_sinking" ); //modSigns
					thePlayer.DisplayHudMessage( GetLocStringByKeyExt( "gm_geralt_too_heavy" ) ); //modSigns
				} //modSigns
				else //modSigns
				{ //modSigns
					needEnableInteractions = true;

					if( mountInteractionComp )
						mountInteractionComp.SetEnabled( true );
					if( mountInteractionCompPassenger && boatComp.user )
						mountInteractionCompPassenger.SetEnabled( true );
				} //modSigns
			}
		}
	}
}

// WGT-10: whether Geralt is overburdened by more than the threshold, in % of his carry limit (legacy's
// W3Boat.CheckPlayerEncumbrance).
@addMethod(W3Boat)
function GMCheckPlayerEncumbrance(witcher : W3PlayerWitcher) : bool
{
	var horseBonus : bool;
	var limit : float;

	if( !witcher || !witcher.HasBuff(EET_OverEncumbered) )
		return false;
	limit = witcher.GetMaxRunEncumbrance(horseBonus);
	if( limit <= 0 )
		return false;
	return ClampF(witcher.GetEncumbrance() / limit - 1, 0, 1) * 100 > ClampF(GMGetOptionFloat('GMGameplayOptions', 'GMSinkBoatOverEnc'), 0, 100);
}
