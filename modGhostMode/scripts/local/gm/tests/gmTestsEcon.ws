// ECON's price checks (docs/features/econ.md): what a merchant asks for an item and pays for it, and the
// craftsmen's fees, read through the inventory's native price functions as the shop, crafting and smith
// menus call them (the merchant's inventory pricing its own item for a purchase, Geralt's item for a sale
// or a service).

// One item's prices at a merchant: a copy added to the merchant (what he asks: GetItemPriceModified(id,
// false), as the shop's quantity popup and the alchemy and crafting menus read it) and one added to
// Geralt (what he pays: GetInventoryItemPriceModified(item, true), the sell path of CR4InventoryMenu; and
// the fees: crafting, repair, dismantling, removing an upgrade, adding a socket). Returns a log line.
function GMTestEconLine(npc : CNewNPC, item : name, out list : int, out buy : int, out sell : int, out craft : int, out repair : int, out dis : int) : string
{
	var minv, pinv : CInventoryComponent;
	var mids, pids : array<SItemUniqueId>;
	var tags : array<name>;
	var t : string;
	var i, rp, rt, rem, slot, own, ownBuy : int;

	minv = npc.GetInventory();
	pinv = thePlayer.GetInventory();
	mids = minv.AddAnItem(item, 1, true, true, false);
	pids = pinv.AddAnItem(item, 1, true, true, false);
	if(mids.Size() == 0 || pids.Size() == 0)
		return "no item " + item;
	list = minv.GetItemPrice(mids[0]);
	buy = minv.GetItemPriceModified(mids[0], false);
	sell = minv.GetInventoryItemPriceModified(pinv.GetItem(pids[0]), true);
	craft = minv.GetItemPriceCrafting(minv.GetItem(mids[0]));
	minv.GetItemPriceRepair(pinv.GetItem(pids[0]), rp, rt);
	repair = rt;
	dis = minv.GetItemPriceDisassemble(pinv.GetItem(pids[0]));
	rem = minv.GetItemPriceRemoveUpgrade(pinv.GetItem(pids[0]));
	slot = minv.GetItemPriceAddSlot(pinv.GetItem(pids[0]));
	own = pinv.GetInventoryItemPriceModified(pinv.GetItem(pids[0]), true);
	ownBuy = pinv.GetItemPriceModified(pids[0], false);
	minv.GetItemTags(mids[0], tags);
	t = "";
	for(i = 0; i < tags.Size(); i += 1)
		if(StrBeginsWith(NameToString(tags[i]), "mod_"))
			t += " " + tags[i];
	t = item + " list " + list + " buy " + buy + " sell " + sell + " craft " + craft + " repair " + rt + "/" + rp
		+ " dismantle " + dis + " unupgrade " + rem + " socket " + slot + " | Geralt's own: buy " + ownBuy + " sell " + own
		+ " | quality " + minv.GetItemQuality(mids[0]) + " level " + minv.GetItemLevel(mids[0])
		+ " dur " + pinv.GetItemDurability(pids[0]) + "/" + pinv.GetItemMaxDurability(pids[0]) + " tags" + t;
	minv.RemoveItem(mids[0], 1);
	pinv.RemoveItem(pids[0], 1);
	return t;
}

function GMTestEconNpcTags(npc : CNewNPC) : string
{
	var tags : array<name>;
	var s : string;
	var i : int;

	tags = npc.GetTags();
	for(i = 0; i < tags.Size(); i += 1)
		s += " " + tags[i];
	return s;
}

function GMTestEconItems() : array<name>
{
	var items : array<name>;

	items.PushBack('Long Steel Sword');
	items.PushBack('Bear Armor 1');
	items.PushBack('Heavy armor 01');
	items.PushBack('Drowner brain');
	items.PushBack('Arachas eyes');
	items.PushBack('Ruby');
	items.PushBack('Steel ingot');
	items.PushBack('Tracking Bolt');
	items.PushBack('Explosive Bolt Legendary');
	items.PushBack('Viziman Champion');
	items.PushBack('Dye Black');
	return items;
}

// Logs the prices of the reference items at a spawned merchant (gmtest_spawnat first).
exec function gmtest_econ_probe(tag : name, optional item : name)
{
	var npc : CNewNPC;
	var items : array<name>;
	var i, l, b, s, c, r, d : int;

	npc = theGame.GetNPCByTag(tag);
	if(!npc)
	{
		LogChannel('GMTest', "FAIL econ probe: no NPC " + tag);
		return;
	}
	LogChannel('GMTest', "INFO ECON " + tag + " tags:" + GMTestEconNpcTags(npc) + " | funds modifier " + npc.GetInventory().GetFundsModifier()
		+ " | money " + npc.GetInventory().GetMoney() + " | merchant " + ((W3MerchantNPC)npc));
	if(IsNameValid(item))
		items.PushBack(item);
	else
		items = GMTestEconItems();
	for(i = 0; i < items.Size(); i += 1)
		LogChannel('GMTest', "INFO ECON " + tag + " " + GMTestEconLine(npc, items[i], l, b, s, c, r, d));
}

// A sale at a given durability (fraction of the maximum).
exec function gmtest_econ_dur(tag : name, item : name, frac : float)
{
	var npc : CNewNPC;
	var minv, pinv : CInventoryComponent;
	var pids : array<SItemUniqueId>;
	var rp, rt : int;

	npc = theGame.GetNPCByTag(tag);
	if(!npc)
		return;
	minv = npc.GetInventory();
	pinv = thePlayer.GetInventory();
	pids = pinv.AddAnItem(item, 1, true, true, false);
	pinv.SetItemDurabilityScript(pids[0], pinv.GetItemMaxDurability(pids[0]) * frac);
	minv.GetItemPriceRepair(pinv.GetItem(pids[0]), rp, rt);
	LogChannel('GMTest', "INFO ECON " + tag + " " + item + " durability " + pinv.GetItemDurability(pids[0]) + "/" + pinv.GetItemMaxDurability(pids[0])
		+ " sell " + minv.GetInventoryItemPriceModified(pinv.GetItem(pids[0]), true) + " repair " + rt + "/" + rp);
	pinv.RemoveItem(pids[0], 1);
}

// Several copies of an item in Geralt's inventory: the definition's price, the inventory's list price,
// the item's level, quality, stats total and abilities (what the list price follows).
exec function gmtest_econ_samples(item : name, optional n : int)
{
	var pinv : CInventoryComponent;
	var pids : array<SItemUniqueId>;
	var abls : array<name>;
	var i, j : int;
	var s : string;

	if(n <= 0)
		n = 4;
	pinv = thePlayer.GetInventory();
	for(i = 0; i < n; i += 1)
	{
		pids = pinv.AddAnItem(item, 1, true, true, false);
		abls.Clear();
		pinv.GetItemAbilities(pids[0], abls);
		s = "";
		for(j = 0; j < abls.Size(); j += 1)
			s += " " + abls[j];
		LogChannel('GMTest', "INFO ECON sample " + item + " def " + theGame.GetDefinitionsManager().GetItemPrice(item) + " list " + pinv.GetItemPrice(pids[0])
			+ " level " + pinv.GetItemLevel(pids[0]) + " quality " + pinv.GetItemQuality(pids[0]) + " stats " + pinv.TotalItemStats(pinv.GetItem(pids[0])) + " abilities" + s);
		pinv.RemoveItem(pids[0], 1);
	}
}

// An item's definition as the game reads it (price, category, weight, tags, abilities, texts, slots): to see
// what a DLC entry changed (the price probe of slice E1: an `extend` entry with only a price attribute).
exec function gmtest_econ_def(item : name)
{
	var dm : CDefinitionsManagerAccessor;
	var pinv : CInventoryComponent;
	var pids : array<SItemUniqueId>;
	var tags, abls : array<name>;
	var i : int;
	var t, a : string;

	dm = theGame.GetDefinitionsManager();
	pinv = thePlayer.GetInventory();
	pids = pinv.AddAnItem(item, 1, true, true, false);
	if(pids.Size() == 0)
	{
		LogChannel('GMTest', "INFO ECON def " + item + ": not added");
		return;
	}
	pinv.GetItemTags(pids[0], tags);
	for(i = 0; i < tags.Size(); i += 1)
		t += " " + tags[i];
	pinv.GetItemAbilities(pids[0], abls);
	for(i = 0; i < abls.Size(); i += 1)
		a += " " + abls[i];
	LogChannel('GMTest', "INFO ECON def " + item + " price " + dm.GetItemPrice(item) + " list " + pinv.GetItemPrice(pids[0]) + " category " + dm.GetItemCategory(item)
		+ " weight " + pinv.GetItemWeight(pids[0]) + " key " + dm.GetItemLocalisationKeyName(item) + " desc " + dm.GetItemLocalisationKeyDesc(item)
		+ " icon " + dm.GetItemIconPath(item) + " hold " + dm.GetItemHoldSlot(item, true) + " template " + dm.GetItemEquipTemplate(item)
		+ " | tags" + t + " | abilities" + a);
	pinv.RemoveItem(pids[0], 1);
}
