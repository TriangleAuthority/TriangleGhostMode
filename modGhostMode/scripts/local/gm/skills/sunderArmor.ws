// SKL-04: Sunder Armor, legacy's in both trees (D56): melee strong attacks (Rend included) reduce the
// victim's resistance to the physical damage types by armor_reduction_perc per level (-25% at the
// maximum level), in W3DamageManagerProcessor.GetDamageResists (damage/formula.ws). Classic sword_s6
// (5 levels), new tree sword_s28 (3 levels). 5.x's new-tree stacks (a growing reduction per strong
// hit on the same target, 3 to 6 s) are replaced by the flat reduction.
// See docs/features/skl.md.

@replaceMethod(W3DamageManagerProcessor)
function ProcessNewSkill_SunderArmor()
{
	//modSigns: removed 5.x's Sunder Armor stacks (SKL-04, D56): the flat reduction in GetDamageResists instead
}
