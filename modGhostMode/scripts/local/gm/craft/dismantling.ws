// Ghost Mode: dismantling (CRAFT-08). The parts every item yields are data (the items' <recycling_parts>,
// generated into Ghost Mode's DLC by the item tools); this file holds the rule.

// CRAFT-08: every craftsman returns every part (1.32 and 5.x: a Journeyman one of each, a Master a
// random share, only a Grand Master all). Parts added to Geralt's own inventory are marked new, parts
// added elsewhere are not (legacy).
@replaceMethod(CInventoryComponent)
function RecycleItem( id : SItemUniqueId, level : ECraftsmanLevel ) :  array<SItemUniqueId>
{
	var itemsAdded : array<SItemUniqueId>;
	var currentAdded : array<SItemUniqueId>;

	var parts : array<SItemParts>;
	var i : int;
	var dontMarkAsNew : bool; //modSigns

	if( this == GetWitcherPlayer().GetInventory() ) //modSigns
		dontMarkAsNew = false; //modSigns
	else //modSigns
		dontMarkAsNew = true; //modSigns

	parts = GetItemRecyclingParts( id );

	for ( i = 0; i < parts.Size(); i += 1 )
	{
		//modSigns: removed the craftsman-level rule (Grand Master all parts, Master a random share, else 1 of each)
		currentAdded = AddAnItem( parts[i].itemName, parts[i].quantity, , dontMarkAsNew ); //modSigns: always every part
		itemsAdded.PushBack(currentAdded[0]);
	}

	RemoveItem(id);

	return itemsAdded;
}
