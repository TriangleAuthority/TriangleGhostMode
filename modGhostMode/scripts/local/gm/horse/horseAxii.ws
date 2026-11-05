// HORSE-02: calming the horse with Axii costs stamina (legacy's, code only). It starts only with 50 stamina
// (a threshold, not a cost), and holding it costs 0.5 stamina a tick, every 0.1 s plus up to a frame (about
// 4 a second, frame-bound, as legacy's same Sleep(0.1f); regen paused 0.5 s by each drain); it ends when the key is released or the resources run out. Each tick confuses the horse
// for 0.5 s (vanilla 0.1 s each frame). With Adrenaline Burst (classic perk_10, new tree perk_42; PH3)
// adrenaline counts as stamina at max stamina / max adrenaline per point, to start and while held (DH3 (a)); max
// stamina is the full one, not lowered by STAM-10 (a sign; owner, 2026-11-04).
// Legacy's leftovers (staminaSpent, a commented-out payment to 50 at the end) are not ported (PH4);
// 5.x's voice line on the cast is kept (PH5).
// See docs/features/horse.md.

// The stamina horse Axii needs to start; each 0.1 s tick of the hold costs 1% of it.
function GMHorseAxiiCost() : float
{
	return 50.0;
}

// Whether the horse Axii key is held (a function, so the tests can hold it: the game reads the real key).
function GMHorseAxiiHeld() : bool
{
	return theInput.IsActionPressed( 'VehicleCastSign' );
}

@addMethod(W3PlayerWitcher)
function GMHasAdrenalineBurst() : bool
{
	return CanUseSkill(S_Perk_10) || CanUseSkill(S_Perk_42);
}

// Legacy's HasResourcesForAxii: stamina, or with Adrenaline Burst stamina plus adrenaline as stamina.
@addMethod(W3VehicleCombatManagerStateCastSign)
function GMHasResourcesForAxii(cost : float) : bool
{
	var ret : bool;

	ret = (witcher.GetStat(BCS_Stamina) >= cost);
	if(!ret && witcher.GMHasAdrenalineBurst())
	{
		ret = ((witcher.GetStat(BCS_Stamina) + witcher.GetStat(BCS_Focus) * witcher.GMFullMaxStamina() / witcher.GetStatMax(BCS_Focus)) >= cost);
	}
	return ret;
}

// Legacy's DrainResourcesForAxii: stamina first (regen delayed 0.5 s), with Adrenaline Burst the rest from adrenaline.
@addMethod(W3VehicleCombatManagerStateCastSign)
function GMDrainResourcesForAxii(cost : float)
{
	var savedStamina : float;

	savedStamina = witcher.GetStat(BCS_Stamina);
	if(savedStamina > 0)
	{
		witcher.DrainStamina(ESAT_FixedValue, cost, 0.5);
	}
	if(cost > savedStamina && witcher.GMHasAdrenalineBurst())
	{
		witcher.DrainFocus((cost - savedStamina) * witcher.GetStatMax(BCS_Focus) / witcher.GMFullMaxStamina());
	}
}

@replaceMethod(W3VehicleCombatManagerStateCastSign)
function OnEnterState( prevStateName : name )
{
	parent.vehicle.OnCombatAction( EHCA_CastSign );

	witcher = (W3PlayerWitcher)parent.rider;
	horse = (CActor)(parent.vehicle.GetEntity());
	horseComp = (W3HorseComponent)parent.vehicle;

	if( witcher && GMHasResourcesForAxii( GMHorseAxiiCost() ) ) //modSigns
	{
		StartCastingSign();
	}
	else
	{
		CastingSignFailed();
	}
}

@replaceMethod(W3VehicleCombatManagerStateCastSign)
function StartCastingSign()
{
	if( witcher.GetBehaviorVariable( 'actionType' ) != (int)EHCA_CastSign )
	{
		witcher.SetBehaviorVariable( 'IsCastingSign', 1.0 );
		witcher.SetBehaviorVariable( 'actionType', (int)EHCA_CastSign );
		witcher.WaitForBehaviorNodeActivation( 'castSignActionOn', 0.5f );
	}

	if( !witcher.CastSign() )
	{
		CastingSignFailed();
	}

	while( true )
	{
		Sleep( 0.1f ); //modSigns: every 0.1 s, not every frame

		if( GMHorseAxiiHeld() && GMHasResourcesForAxii( GMHorseAxiiCost() * 0.01 ) ) //modSigns
		{
			ApplyEffectOnHorse( 0.5 ); //modSigns
			GMDrainResourcesForAxii( GMHorseAxiiCost() * 0.01 ); //modSigns
		}
		else
		{
			break;
		}
	}

	FinishCasting();
}
