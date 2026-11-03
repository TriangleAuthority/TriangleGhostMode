// FIX-05: a hit cancels Geralt's bomb throw or crossbow aim only while he is throwing or aiming, and only when the hit
// plays a hit reaction (legacy; no changelist line). 1.32 and 5.x run the abort on every damaging hit that is not damage
// over time, throwing or not. Called from ENCH-16's ReactToBeingHit replacement (enchantments/runesGlyphs.ws), one
// line marked FIX-05. See docs/features/fix.md.
@addMethod(W3PlayerWitcher)
function GMFixHitAbortsThrow(damageAction : W3DamageAction) : bool
{
	if(!IsThrowingItem() && !IsThrowingItemWithAim())
		return false;
	return !damageAction.IsDoTDamage() && damageAction.DealsAnyDamage() && damageAction.GetHitAnimationPlayType() != EAHA_ForceNo;
}
