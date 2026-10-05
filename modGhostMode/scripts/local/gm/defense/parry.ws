// DEF-05: parrying rules. A parried hit takes no damage and no effects (vanilla). A partial parry
// (parrying an attack that cannot be parried, or parrying without enough stamina, STAM-03's
// parryStamina.ws) lets 50% of the damage through (vanilla 30% or 60% by the attacker's size),
// causes no bleeding (vanilla) and staggers briefly (vanilla: a long stagger, and none at all
// for a parry without stamina). Attacks that knock down are not parried partially (vanilla).
// Deflection's extra reduction is SKL's.
// See docs/features/def.md.

// DEF-05: the 50% share is set in W3GameParams's scope-based override block (staminaCosts.ws; a
// mod can declare a class's block only once).

// DEF-05: a parry without enough stamina of an attack that can be parried (STAM-03) staggers.
// Vanilla's ProcessActionBuffs applies none of the effects of such a hit (legacy had the same gap; fixed by
// the project owner's decision, 2026-10-04), so the stagger is put on Geralt directly; the attack's other
// effects stay blocked. (The partial parry itself is set in ProcessAction, defense/processAction.ws.)
@wrapMethod(W3DamageManagerProcessor)
function ProcessActionBuffs() : bool
{
	if(playerVictim && attackAction && attackAction.IsActionMelee() && attackAction.IsParried() && action.IsParryStagger()
		&& attackAction.CanBeParried() && !attackAction.ApplyBuffsIfParried() && actorVictim.IsAlive())
		actorVictim.AddEffectDefault(EET_Stagger, actorAttacker, "GMPartialParry");
	return wrappedMethod();
}
