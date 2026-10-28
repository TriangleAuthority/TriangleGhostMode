// XBOW-08 (NPC bows and crossbows): an NPC's arrow or bolt deals the damage of the bow or crossbow
// it was shot from (legacy: "proper bow/crossbow damage"), not the damage set in the projectile's
// entity. The bows' values are legacy's (items/gm_xbow.xml, gen_xbow.py). A reflected arrow
// (Deflection) has Geralt as its caster, who holds no bow, so it keeps its own damage, as in legacy.
// See docs/features/xbow.md.

// Legacy's GetHeldWeaponDamage: the damage of the caster's held bow or crossbow (0 when none).
@addMethod(W3ArrowProjectile)
function GMGetHeldWeaponDamage(damageTypeName : name) : float
{
	var itemCategory : name;
	var heldWeapons : array<SItemUniqueId>;
	var i : int;
	var inv : CInventoryComponent;
	var actorAttacker : CActor;

	actorAttacker = (CActor)caster;
	if(!actorAttacker)
		return 0;
	inv = actorAttacker.GetInventory();
	heldWeapons = inv.GetHeldWeapons();
	for(i = 0; i < heldWeapons.Size(); i += 1)
	{
		itemCategory = inv.GetItemCategory(heldWeapons[i]);
		if(itemCategory == 'bow' || itemCategory == 'crossbow')
			return actorAttacker.GetTotalWeaponDamage(heldWeapons[i], damageTypeName, GetInvalidUniqueId());
	}
	return 0;
}

// The arrow's damage taken from the held bow before 5.x's body builds the hit.
@wrapMethod(W3ArrowProjectile)
function ProcessDamageAction(victim : CGameplayEntity, pos : Vector, boneName : name)
{
	var heldWeaponPiercingDmg, heldWeaponSilverDmg : float;

	heldWeaponPiercingDmg = GMGetHeldWeaponDamage(theGame.params.DAMAGE_NAME_PIERCING);
	heldWeaponSilverDmg = GMGetHeldWeaponDamage(theGame.params.DAMAGE_NAME_SILVER);
	if(heldWeaponPiercingDmg > 0)
		projDMG = heldWeaponPiercingDmg;
	if(heldWeaponSilverDmg > 0)
		projSilverDMG = heldWeaponSilverDmg;
	wrappedMethod(victim, pos, boneName);
}
