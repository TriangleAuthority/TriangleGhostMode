// XBOW-05: the bolt hit fixes (legacy's bugfixes 161 and 162).
// - The last bolt of a stack: the bolt item leaves Geralt's inventory when the shot is released
//   (ReleaseProjectiles2), before it hits, so the hit had no bolt to read (no damage types, no effect:
//   0 damage, seen in game 2026-10-25). The bolt's name is kept at the throw and the bolt is added back
//   for the hit and removed after it, as legacy does.
// - One hit per target: a bolt that already hit a victim does not hit it again (with Cat Eyes, an
//   explosive bolt pierces and explodes again on whatever it hits next, hitting the same enemies again:
//   seen in game 2026-10-25).

@addField(W3BoltProjectile)
var gmBoltItemName : name;

// XBOW-05: the bolt's name, read while the item is still in the inventory, on every projectile of the
// shot (a split bolt's two copies too; legacy set it on the first one only).
@wrapMethod(W3BoltProjectile)
function ThrowProjectile(targetPosIn : Vector)
{
	var boltName : name;
	var i : int;

	boltName = GetOwner().GetInventory().GetItemName(itemId);
	wrappedMethod(targetPosIn);
	for(i = 0; i < projectiles.Size(); i += 1)
		if(projectiles[i])
			projectiles[i].GMSetBoltItemName(boltName);
}

@addMethod(W3BoltProjectile)
function GMSetBoltItemName(boltName : name)
{
	gmBoltItemName = boltName;
}

// XBOW-05: a victim this bolt already hit is skipped; the last bolt of a stack is added back for the hit.
@wrapMethod(W3BoltProjectile)
function ProcessDamageAction(victim : CGameplayEntity, pos : Vector, boneName : name)
{
	var inv : CInventoryComponent;
	var ids : array<SItemUniqueId>;
	var boltAdded : bool;

	if(collidedEntities.Contains(victim))
		return;

	inv = GetOwner().GetInventory();
	if(inv && inv.GetItemQuantity(itemId) <= 0 && IsNameValid(gmBoltItemName))
	{
		ids = inv.AddAnItem(gmBoltItemName, 1, true, true);
		if(ids.Size() > 0)
		{
			itemId = ids[0];
			boltAdded = true;
		}
	}

	wrappedMethod(victim, pos, boneName);

	if(boltAdded)
		inv.RemoveItemByName(gmBoltItemName, 1);
}

// XBOW-05: a projectile starts with no victims (legacy).
@wrapMethod(W3BoltProjectile)
function OnProjectileInit()
{
	collidedEntities.Clear();
	return wrappedMethod();
}
