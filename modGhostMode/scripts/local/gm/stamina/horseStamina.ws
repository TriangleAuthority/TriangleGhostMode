// STAM-03 (horseback): a sword attack from horseback costs the light-attack cost times the
// horseback multiplier and is refused without it; bombs and the crossbow are refused without
// the usable-item stamina (they are paid when used, see actionStamina.ws).
// See docs/features/stam.md.

// STAM-03, HORSE: horseback attacks cost this many light attacks (legacy
// W3VehicleCombatManager.ON_HORSEBACK_STAMINA_MULTIPLIER).
function GMHorsebackStaminaMult() : float
{
	return 3.0;
}

// Bombs and the crossbow are refused without stamina (the horse's combat manager uses its own
// input events, not CPlayerInput's). Legacy refused the whole event, sound on press.
@wrapMethod(W3VehicleCombatManagerStateNull)
function OnItemAction(action : SInputAction)
{
	if(rider == GetWitcherPlayer() && GMRefuseItemForStamina(action))
		return false;
	return wrappedMethod(action);
}

// A sword attack is refused without the stamina for it; drawing the sword is not.
@wrapMethod(W3VehicleCombatManagerStateNull)
function StartAttackAction()
{
	if(rider == GetWitcherPlayer() && rider.GetWeaponHolster().IsMeleeWeaponReady()
		&& (rider.IsWeaponHeld('steelsword') || rider.IsWeaponHeld('silversword'))
		&& !rider.HasStaminaToUseAction(ESAT_LightAttack, , , GMHorsebackStaminaMult()))
	{
		rider.GMRefuseForStamina();
		return;
	}
	wrappedMethod();
}

// The attack is paid when the swing is released (quick or held), hit or miss; an aborted swing
// is free. Legacy paid on the release event, which missed quick swings.
@wrapMethod(W3VehicleCombatManagerStateSwordAttack)
function DoAttack()
{
	if(rider == GetWitcherPlayer())
		rider.DrainStamina(ESAT_LightAttack, , , , , GMHorsebackStaminaMult());
	wrappedMethod();
}
