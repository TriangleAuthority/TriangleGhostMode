// DMG-10: non-deadly fights. A melee fight where both sides hold wooden swords or fists (not magic
// fists), or the scripted opponents Olaf (ff204), the ff205 troll, the club dwarves or the mq7011
// guards, is non-deadly: no raw damage bonuses, no crits, no attack power, no before-hit effects; outside
// the fistfight minigame each hit deals a share of the victim's maximum health (the final-damage step).
// Legacy NonDeadlyWeaponFight and its hunks; the formula, pool and final-damage hunks are in
// formula.ws, pool.ws and pipeline.ws. See docs/features/dmg.md.

@addField(W3DamageManagerProcessor)
var gmWeaponsAreNotDeadly : bool;

@wrapMethod(W3DamageManagerProcessor)
function InitializeActionVars(act : W3DamageAction)
{
	wrappedMethod(act);
	gmWeaponsAreNotDeadly = GMNonDeadlyWeaponFight();
}

@addMethod(W3DamageManagerProcessor)
function GMNonDeadlyWeaponFight() : bool
{
	var attackerNonDeadly, victimNonDeadly : bool;
	var attackerWeaponId, victimWeaponId : SItemUniqueId;
	var heldWeapons : array<SItemUniqueId>;
	var attackerInv, victimInv : CInventoryComponent;

	if(!attackAction || !attackAction.IsActionMelee() || !actorAttacker || !actorVictim)
		return false;

	attackerInv = actorAttacker.GetInventory();
	heldWeapons = attackerInv.GetHeldWeapons();
	if(heldWeapons.Size() > 0)
		attackerWeaponId = heldWeapons[0];
	if(attackerWeaponId == GetInvalidUniqueId())
		return false;

	victimInv = actorVictim.GetInventory();
	heldWeapons = victimInv.GetHeldWeapons();
	if(heldWeapons.Size() > 0)
		victimWeaponId = heldWeapons[0];
	if(victimWeaponId == GetInvalidUniqueId())
		return false;

	if(actorAttacker.HasAbility('mon_ff204olaf') || actorAttacker.HasAbility('mon_ff205troll') || actorAttacker.HasAbility('mon_EP2_clubDwarfs') || actorAttacker.HasTag('mq7011_guards'))
		attackerNonDeadly = true;
	else
		attackerNonDeadly = attackerInv.ItemHasTag(attackerWeaponId, 'Wooden') || attackerInv.ItemHasTag(attackerWeaponId, 'Fists') && !attackerInv.ItemHasTag(attackerWeaponId, 'MagicWeaponFX');

	if(actorVictim.HasAbility('mon_ff204olaf') || actorVictim.HasAbility('mon_ff205troll') || actorVictim.HasAbility('mon_EP2_clubDwarfs') || actorVictim.HasTag('mq7011_guards'))
		victimNonDeadly = true;
	else
		victimNonDeadly = victimInv.ItemHasTag(victimWeaponId, 'Wooden') || victimInv.ItemHasTag(victimWeaponId, 'Fists') && !victimInv.ItemHasTag(victimWeaponId, 'MagicWeaponFX');

	return attackerNonDeadly && victimNonDeadly;
}

// DMG-03, DMG-10: no crits for damage over time (it has no buffs) or in non-deadly fights.
@wrapMethod(W3DamageManagerProcessor)
function ProcessCriticalHitCheck()
{
	if(action.IsDoTDamage() || gmWeaponsAreNotDeadly)
		return;
	wrappedMethod();
}

// DMG-10: no before-hit effects (oils, skills) in non-deadly fights.
@wrapMethod(W3DamageManagerProcessor)
function ProcessOnBeforeHitChecks()
{
	if(gmWeaponsAreNotDeadly)
		return;
	wrappedMethod();
}
