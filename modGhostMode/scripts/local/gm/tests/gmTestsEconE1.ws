// ECON slice E1 (ECON-05 to ECON-08's table, PE5): the prices merchants show, compared with the measured
// formula (docs/game-5.0-changes.md, "Prices") and legacy's economy_tagmodifiers.csv (GMTestEconFactor):
//   list  = the item's price in the merchant's inventory: Geralt's own list price × mod_legendary's factor
//           for the merchant's type when the item has the tag;
//   buy   = ceil(list × Π over the item's trading tags (|type factor| × region factor));
//   sale  = trunc(buy × mod_sale's type factor × its region factor), negative (refused) when any trading
//           factor is negative;
//   bolts = buy and sale ÷ 10;
//   fees  = ceil(list × the service row's type × region factors) (crafting, dismantling, removing an upgrade);
//   repair = per missing durability point ceil(Geralt's own list × mod_repair's type × region factors ÷ 100);
//   socket = ceil((293 + list × mod_addslot's type × region factors) × (the item's sockets + 1));
//   funds modifier = mod_funds's type × region factors.
// Ten merchants of seven types in four regions are spawned from their entity files, read and removed: since
// the ECON audit (F4) also the Hearts of Stone enchanter and a blacksmith with Beauclair's columns.

function GMTestEconItemsE1() : array<name>
{
	var items : array<name>;

	items.PushBack('Long Steel Sword');
	items.PushBack('Bear Armor 1');
	items.PushBack('Bear Armor 4');	// ECON audit F4: a dear armor (the enchanter's repair factor shows in its fee per point)
	items.PushBack('Drowner brain');
	items.PushBack('Arachas eyes');
	items.PushBack('Ruby');
	items.PushBack('Steel ingot');
	items.PushBack('Tracking Bolt');
	items.PushBack('Viziman Champion');
	items.PushBack('Dye Black');
	return items;
}

function GMTestEconIsSpecial(t : name) : bool
{
	return t == 'mod_legendary' || t == 'mod_collectible' || t == 'mod_default' || t == 'mod_noprice';
}

// One item at one merchant: list, buy, sale and (at craftsmen) the three fees against the formula.
function GMTestEconE1Item(npc : CNewNPC, label : string, ty : name, ar : name, item : name, fees : bool) : bool
{
	var minv, pinv : CInventoryComponent;
	var mids, pids : array<SItemUniqueId>;
	var tags : array<name>;
	var i, own, list, buy, sale, craft, dis, unup, eList, eBuy, eSale, eCraft, eDis, eUnup, div : int;
	var fx, t, a : float;
	var refused, ok : bool;
	var s : string;

	minv = npc.GetInventory();
	pinv = thePlayer.GetInventory();
	mids = minv.AddAnItem(item, 1, true, true, false);
	pids = pinv.AddAnItem(item, 1, true, true, false);
	if(mids.Size() == 0 || pids.Size() == 0)
	{
		GMTestReport(false, "ECON-05 " + label + " " + item + ": not added");
		return false;
	}
	own = pinv.GetItemPrice(pids[0]);
	list = minv.GetItemPrice(mids[0]);
	buy = minv.GetItemPriceModified(mids[0], false);
	sale = minv.GetInventoryItemPriceModified(pinv.GetItem(pids[0]), true);
	craft = minv.GetItemPriceCrafting(minv.GetItem(mids[0]));
	dis = minv.GetItemPriceDisassemble(pinv.GetItem(pids[0]));
	unup = minv.GetItemPriceRemoveUpgrade(pinv.GetItem(pids[0]));
	minv.GetItemTags(mids[0], tags);

	eList = own;
	if(minv.ItemHasTag(mids[0], 'mod_legendary'))
		eList = (int)(own * GMTestEconFactor('mod_legendary', ty));
	fx = 1.0f;
	refused = false;
	for(i = 0; i < tags.Size(); i += 1)
	{
		if(!StrBeginsWith(NameToString(tags[i]), "mod_") || GMTestEconIsSpecial(tags[i]))
			continue;
		t = GMTestEconFactor(tags[i], ty);
		a = GMTestEconFactor(tags[i], ar);
		if(t < 0)
			refused = true;
		fx *= AbsF(t) * a;
	}
	div = 1;
	if(minv.GetItemCategory(mids[0]) == 'bolt')
		div = 10;
	eBuy = CeilF(eList * fx);
	eSale = (int)(eBuy * (GMTestEconFactor('mod_sale', ty) * GMTestEconFactor('mod_sale', ar)));
	if(refused)
		eSale = -eSale;
	eBuy /= div;
	eSale /= div;
	eCraft = CeilF(eList * (GMTestEconFactor('mod_craftitem', ty) * GMTestEconFactor('mod_craftitem', ar)));
	eDis = CeilF(eList * (GMTestEconFactor('mod_disassemble', ty) * GMTestEconFactor('mod_disassemble', ar)));
	eUnup = CeilF(eList * (GMTestEconFactor('mod_removeupgrade', ty) * GMTestEconFactor('mod_removeupgrade', ar)));
	ok = list == eList && buy == eBuy && sale == eSale;
	s = "list " + list + " (" + eList + "), buy " + buy + " (" + eBuy + "), sale " + sale + " (" + eSale + ")";
	if(fees)
	{
		ok = ok && craft == eCraft && dis == eDis && unup == eUnup;
		s += ", crafting " + craft + " (" + eCraft + "), dismantling " + dis + " (" + eDis + "), removing an upgrade " + unup + " (" + eUnup + ")";
		// ECON audit F4: the repair fee and adding a socket (the formulas measured, ECON-07), for swords and armor
		if(GMTestEconIsGear(pinv.GetItemCategory(pids[0])))
		{
			ok = GMTestEconE1Repair(minv, pinv, pids[0], own, ty, ar, s) && ok;
			ok = GMTestEconE1Socket(minv, pinv, pids[0], eList, ty, ar, s) && ok;
		}
	}
	GMTestReport(ok, "ECON-05 " + label + " " + item + ": " + s);
	minv.RemoveItem(mids[0], 1);
	pinv.RemoveItem(pids[0], 1);
	return ok;
}

function GMTestEconIsGear(cat : name) : bool
{
	return cat == 'steelsword' || cat == 'silversword' || cat == 'armor' || cat == 'boots' || cat == 'pants' || cat == 'gloves';
}

// Repair (ECON-07, measured 2026-11-01, ECON audit F4): per missing durability point
// ceil(Geralt's own list price × mod_repair's type × region factors ÷ 100), the total that times the missing
// points; read at half durability.
function GMTestEconE1Repair(minv, pinv : CInventoryComponent, id : SItemUniqueId, own : int, ty, ar : name, out s : string) : bool
{
	var maxd : float;
	var rp, rt, ePoint, eTotal, missing : int;

	maxd = pinv.GetItemMaxDurability(id);
	pinv.SetItemDurabilityScript(id, maxd * 0.5);
	minv.GetItemPriceRepair(pinv.GetItem(id), rp, rt);
	missing = (int)(maxd - pinv.GetItemDurability(id));
	ePoint = CeilF(own * (GMTestEconFactor('mod_repair', ty) * GMTestEconFactor('mod_repair', ar)) / 100.0f);
	eTotal = ePoint * missing;
	pinv.SetItemDurabilityScript(id, maxd);
	s += ", repair " + rt + "/" + rp + " (" + eTotal + "/" + ePoint + ", " + missing + " points)";
	return maxd > 0 && rp == ePoint && rt == eTotal;
}

// The socket fee's fixed part (measured 2026-11-01, ECON audit F4: the same for every item at a blacksmith,
// the enchanter and a merchant without columns; not a row of the price table).
function GMTestEconSocketBase() : float
{
	return 293.0f;
}

// Adding a socket (ECON-07, measured 2026-11-01, ECON audit F4): ceil((293 + the item's list price at the merchant ×
// mod_addslot's type × region factors) × (the item's sockets + 1)); read, a socket added, read again.
function GMTestEconE1Socket(minv, pinv : CInventoryComponent, id : SItemUniqueId, list : int, ty, ar : name, out s : string) : bool
{
	var n, got, e : int;
	var f : float;
	var ok : bool;

	f = GMTestEconFactor('mod_addslot', ty) * GMTestEconFactor('mod_addslot', ar);
	n = pinv.GetItemEnhancementSlotsCount(id);
	got = minv.GetItemPriceAddSlot(pinv.GetItem(id));
	e = CeilF((GMTestEconSocketBase() + list * f) * (n + 1));
	ok = got == e;
	s += ", socket " + got + " (" + e + ", " + n + " sockets)";
	if(n < 2 && pinv.AddSlot(id))
	{
		got = minv.GetItemPriceAddSlot(pinv.GetItem(id));
		e = CeilF((GMTestEconSocketBase() + list * f) * (n + 2));
		ok = ok && got == e;
		s += ", then " + got + " (" + e + ")";
	}
	return ok;
}

function GMTestEconE1Merchant(path : string, label : string, ty : name, ar : name, fees : bool, dist : float, optional retag : bool)
{
	var template : CEntityTemplate;
	var npc : CNewNPC;
	var items, cols : array<name>;
	var i : int;
	var eFunds : float;

	template = (CEntityTemplate)LoadResource(path, true);
	npc = (CNewNPC)theGame.CreateEntity(template, thePlayer.GetWorldPosition() - thePlayer.GetHeadingVector() * dist, thePlayer.GetWorldRotation());
	if(!npc)
	{
		GMTestReport(false, "ECON-05 " + label + ": not spawned (" + path + ")");
		return;
	}
	// The price columns are the merchant inventory's tags (GMTestEconInvColumns). Blood and Wine's merchants
	// are placed in its world; their spawnable templates carry no columns. A Beauclair merchant is a spawned
	// one with its inventory's columns set to Beauclair's (ECON audit F4)
	if(retag)
	{
		cols.PushBack(ty);
		cols.PushBack(ar);
		npc.GetInventory().SetTags(cols);
	}
	GMTestReport(npc.GetInventory().HasTag(ty) && npc.GetInventory().HasTag(ar), "ECON-05 " + label + " columns:" + GMTestEconInvColumns(npc.GetInventory()));
	eFunds = GMTestEconFactor('mod_funds', ty) * GMTestEconFactor('mod_funds', ar);
	GMTestReport(AbsF(npc.GetInventory().GetFundsModifier() - eFunds) < 0.001,
		"ECON-08 " + label + " funds modifier " + npc.GetInventory().GetFundsModifier() + " (" + eFunds + ")");
	items = GMTestEconItemsE1();
	for(i = 0; i < items.Size(); i += 1)
		GMTestEconE1Item(npc, label, ty, ar, items[i], fees);
	npc.Destroy();
}

function GMTest_econ_e1()
{
	var g : string;

	g = "living_world\dialogue\generic_merchants\entities\shop_generic_merchant_";
	GMTestEconE1Merchant(g + "novigrad_weapons.w2ent", "Novigrad blacksmith", 'type_blacksmith', 'area_novigrad', true, 6);
	GMTestEconE1Merchant(g + "novigrad_armor.w2ent", "Novigrad armorer", 'type_armorer', 'area_novigrad', true, 7);
	GMTestEconE1Merchant(g + "novigrad_herbalist.w2ent", "Novigrad herbalist", 'type_herbalist', 'area_novigrad', false, 8);
	GMTestEconE1Merchant(g + "novigrad_merchant.w2ent", "Novigrad general merchant", 'type_general', 'area_novigrad', false, 9);
	GMTestEconE1Merchant("gameplay\community\shops_and_craftsmen\novigrad\temple_district\novi_temple_dist_alchemist_01.w2ent", "Novigrad alchemist", 'type_alchemist', 'area_novigrad', false, 10);
	GMTestEconE1Merchant(g + "skellige_weapons.w2ent", "Skellige blacksmith", 'type_blacksmith', 'area_skellige', true, 11);
	GMTestEconE1Merchant(g + "nomansland_armor.w2ent", "No Man's Land armorer", 'type_armorer', 'area_nml', true, 12);
	GMTestEconE1Merchant(g + "nomansland_innkeeper.w2ent", "No Man's Land innkeeper", 'type_inn', 'area_nml', false, 13);
	// ECON audit F4: the enchanter's column (crafting, dismantling, removing an upgrade, repair, sockets) and
	// Beauclair's (a spawned blacksmith with Beauclair's columns: no spawnable Blood and Wine merchant carries them)
	GMTestEconE1Merchant("dlc\ep1\data\gameplay\community\shops_and_craftsmen\enchanter\enchanter_01_lvl_1.w2ent", "Hearts of Stone enchanter", 'type_enchanter', 'area_novigrad', true, 14);
	GMTestEconE1Merchant(g + "novigrad_weapons.w2ent", "Beauclair blacksmith", 'type_blacksmith', 'area_beauclair', true, 15, true);
}

exec function gmtest_econ_e1()
{
	thePlayer.GMTestCount(true, true);
	GMTest_econ_e1();
	LogChannel('GMTest', "SUMMARY econ_e1: " + thePlayer.gmTestPassed + " passed, " + thePlayer.gmTestFailed + " failed");
}

// Legacy Ghost Mode's economy_tagmodifiers.csv (legacy-GM): the factor of a price tag (row) for a merchant type
// or region (column), for the columns the ECON checks use. Written once from legacy's file.
function GMTestEconFactor(row : name, col : name) : float
{
	switch(row)
	{
		case 'mod_nosale':
			switch(col)
			{
				case 'type_general': return -1.0f;
				case 'type_alchemist': return -1.0f;
				case 'type_armorer': return -1.0f;
				case 'type_blacksmith': return -1.0f;
				case 'type_herbalist': return -1.0f;
				case 'type_inn': return -1.0f;
				case 'type_enchanter': return -1.0f;
				case 'area_novigrad': return 1.0f;
				case 'area_skellige': return 1.0f;
				case 'area_nml': return 1.0f;
				case 'area_beauclair': return 1.0f;
			}
			break;
		case 'mod_default':
			switch(col)
			{
				case 'type_general': return 1.0f;
				case 'type_alchemist': return 1.0f;
				case 'type_armorer': return 1.0f;
				case 'type_blacksmith': return 1.0f;
				case 'type_herbalist': return 1.0f;
				case 'type_inn': return 1.0f;
				case 'type_enchanter': return 1.0f;
				case 'area_novigrad': return 1.0f;
				case 'area_skellige': return 1.0f;
				case 'area_nml': return 1.0f;
				case 'area_beauclair': return 1.0f;
			}
			break;
		case 'mod_collectible':
			switch(col)
			{
				case 'type_general': return 1.0f;
				case 'type_alchemist': return 1.5f;
				case 'type_armorer': return 1.0f;
				case 'type_blacksmith': return 1.0f;
				case 'type_herbalist': return 1.0f;
				case 'type_inn': return 1.0f;
				case 'type_enchanter': return 1.0f;
				case 'area_novigrad': return 1.0f;
				case 'area_skellige': return 1.0f;
				case 'area_nml': return 1.0f;
				case 'area_beauclair': return 1.0f;
			}
			break;
		case 'mod_legendary':
			switch(col)
			{
				case 'type_general': return 1.2f;
				case 'type_alchemist': return 1.2f;
				case 'type_armorer': return 1.2f;
				case 'type_blacksmith': return 1.2f;
				case 'type_herbalist': return 1.2f;
				case 'type_inn': return 1.2f;
				case 'type_enchanter': return 1.2f;
				case 'area_novigrad': return 1.0f;
				case 'area_skellige': return 1.0f;
				case 'area_nml': return 1.0f;
				case 'area_beauclair': return 1.0f;
			}
			break;
		case 'mod_funds':
			switch(col)
			{
				case 'type_general': return 1.0f;
				case 'type_alchemist': return 1.2f;
				case 'type_armorer': return 1.8f;
				case 'type_blacksmith': return 1.8f;
				case 'type_herbalist': return 1.1f;
				case 'type_inn': return 1.2f;
				case 'type_enchanter': return 1.8f;
				case 'area_novigrad': return 1.1f;
				case 'area_skellige': return 1.0f;
				case 'area_nml': return 0.8f;
				case 'area_beauclair': return 1.15f;
			}
			break;
		case 'mod_enchantment':
			switch(col)
			{
				case 'type_general': return 1.0f;
				case 'type_alchemist': return 1.0f;
				case 'type_armorer': return 1.0f;
				case 'type_blacksmith': return 1.0f;
				case 'type_herbalist': return 1.0f;
				case 'type_inn': return 1.0f;
				case 'type_enchanter': return 0.45f;
				case 'area_novigrad': return 1.0f;
				case 'area_skellige': return 1.0f;
				case 'area_nml': return 1.0f;
				case 'area_beauclair': return 1.0f;
			}
			break;
		case 'mod_craftitem':
			switch(col)
			{
				case 'type_general': return 1.0f;
				case 'type_alchemist': return 1.0f;
				case 'type_armorer': return 0.45f;
				case 'type_blacksmith': return 0.45f;
				case 'type_herbalist': return 1.0f;
				case 'type_inn': return 1.0f;
				case 'type_enchanter': return 0.45f;
				case 'area_novigrad': return 1.1f;
				case 'area_skellige': return 1.0f;
				case 'area_nml': return 0.8f;
				case 'area_beauclair': return 1.15f;
			}
			break;
		case 'mod_removeenchantment':
			switch(col)
			{
				case 'type_general': return 1.0f;
				case 'type_alchemist': return 1.0f;
				case 'type_armorer': return 1.0f;
				case 'type_blacksmith': return 1.0f;
				case 'type_herbalist': return 1.0f;
				case 'type_inn': return 1.0f;
				case 'type_enchanter': return 0.35f;
				case 'area_novigrad': return 1.0f;
				case 'area_skellige': return 1.0f;
				case 'area_nml': return 1.0f;
				case 'area_beauclair': return 1.0f;
			}
			break;
		case 'mod_removeupgrade':
			switch(col)
			{
				case 'type_general': return 1.0f;
				case 'type_alchemist': return 1.0f;
				case 'type_armorer': return 0.3f;
				case 'type_blacksmith': return 0.3f;
				case 'type_herbalist': return 1.0f;
				case 'type_inn': return 1.0f;
				case 'type_enchanter': return 0.3f;
				case 'area_novigrad': return 1.1f;
				case 'area_skellige': return 1.0f;
				case 'area_nml': return 0.8f;
				case 'area_beauclair': return 1.15f;
			}
			break;
		case 'mod_addslot':
			switch(col)
			{
				case 'type_general': return 1.0f;
				case 'type_alchemist': return 1.0f;
				case 'type_armorer': return 1.0f;
				case 'type_blacksmith': return 1.0f;
				case 'type_herbalist': return 1.0f;
				case 'type_inn': return 1.0f;
				case 'type_enchanter': return 0.35f;
				case 'area_novigrad': return 1.0f;
				case 'area_skellige': return 1.0f;
				case 'area_nml': return 1.0f;
				case 'area_beauclair': return 1.0f;
			}
			break;
		case 'mod_repair':
			switch(col)
			{
				case 'type_general': return 1.0f;
				case 'type_alchemist': return 1.0f;
				case 'type_armorer': return 0.25f;
				case 'type_blacksmith': return 0.25f;
				case 'type_herbalist': return 1.0f;
				case 'type_inn': return 1.0f;
				case 'type_enchanter': return 0.25f;
				case 'area_novigrad': return 1.1f;
				case 'area_skellige': return 1.0f;
				case 'area_nml': return 0.8f;
				case 'area_beauclair': return 1.15f;
			}
			break;
		case 'mod_disassemble':
			switch(col)
			{
				case 'type_general': return 1.0f;
				case 'type_alchemist': return 1.0f;
				case 'type_armorer': return 0.2f;
				case 'type_blacksmith': return 0.2f;
				case 'type_herbalist': return 1.0f;
				case 'type_inn': return 1.0f;
				case 'type_enchanter': return 0.2f;
				case 'area_novigrad': return 1.1f;
				case 'area_skellige': return 1.0f;
				case 'area_nml': return 0.8f;
				case 'area_beauclair': return 1.15f;
			}
			break;
		case 'mod_sale':
			switch(col)
			{
				case 'type_general': return 0.2f;
				case 'type_alchemist': return 0.25f;
				case 'type_armorer': return 0.25f;
				case 'type_blacksmith': return 0.25f;
				case 'type_herbalist': return 0.25f;
				case 'type_inn': return 0.25f;
				case 'type_enchanter': return 0.25f;
				case 'area_novigrad': return 1.0f;
				case 'area_skellige': return 1.0f;
				case 'area_nml': return 1.0f;
				case 'area_beauclair': return 1.0f;
			}
			break;
		case 'mod_alchemy':
			switch(col)
			{
				case 'type_general': return 1.0f;
				case 'type_alchemist': return 1.0f;
				case 'type_armorer': return -1.0f;
				case 'type_blacksmith': return -1.0f;
				case 'type_herbalist': return 1.0f;
				case 'type_inn': return -1.0f;
				case 'type_enchanter': return -1.0f;
				case 'area_novigrad': return 1.1f;
				case 'area_skellige': return 1.0f;
				case 'area_nml': return 1.0f;
				case 'area_beauclair': return 1.15f;
			}
			break;
		case 'mod_alcohol':
			switch(col)
			{
				case 'type_general': return 1.0f;
				case 'type_alchemist': return 1.1f;
				case 'type_armorer': return -1.0f;
				case 'type_blacksmith': return -1.0f;
				case 'type_herbalist': return 1.1f;
				case 'type_inn': return 1.0f;
				case 'type_enchanter': return -1.0f;
				case 'area_novigrad': return 1.1f;
				case 'area_skellige': return 1.0f;
				case 'area_nml': return 0.9f;
				case 'area_beauclair': return 0.85f;
			}
			break;
		case 'mod_armor':
			switch(col)
			{
				case 'type_general': return 1.0f;
				case 'type_alchemist': return -1.0f;
				case 'type_armorer': return 1.0f;
				case 'type_blacksmith': return 0.9f;
				case 'type_herbalist': return -1.0f;
				case 'type_inn': return -1.0f;
				case 'type_enchanter': return 0.9f;
				case 'area_novigrad': return 1.05f;
				case 'area_skellige': return 1.0f;
				case 'area_nml': return 0.9f;
				case 'area_beauclair': return 1.1f;
			}
			break;
		case 'mod_book':
			switch(col)
			{
				case 'type_general': return 1.0f;
				case 'type_alchemist': return 1.1f;
				case 'type_armorer': return -1.0f;
				case 'type_blacksmith': return -1.0f;
				case 'type_herbalist': return -1.0f;
				case 'type_inn': return -1.0f;
				case 'type_enchanter': return -1.0f;
				case 'area_novigrad': return 1.1f;
				case 'area_skellige': return 1.0f;
				case 'area_nml': return 0.8f;
				case 'area_beauclair': return 1.15f;
			}
			break;
		case 'mod_crafting':
			switch(col)
			{
				case 'type_general': return 1.0f;
				case 'type_alchemist': return -1.0f;
				case 'type_armorer': return 1.1f;
				case 'type_blacksmith': return 1.1f;
				case 'type_herbalist': return -1.0f;
				case 'type_inn': return -1.0f;
				case 'type_enchanter': return 1.0f;
				case 'area_novigrad': return 1.05f;
				case 'area_skellige': return 1.0f;
				case 'area_nml': return 1.0f;
				case 'area_beauclair': return 1.1f;
			}
			break;
		case 'mod_dye':
			switch(col)
			{
				case 'type_general': return 1.0f;
				case 'type_alchemist': return -1.0f;
				case 'type_armorer': return 1.1f;
				case 'type_blacksmith': return 1.1f;
				case 'type_herbalist': return -1.0f;
				case 'type_inn': return -1.0f;
				case 'type_enchanter': return 0.9f;
				case 'area_novigrad': return 1.1f;
				case 'area_skellige': return 1.0f;
				case 'area_nml': return 0.8f;
				case 'area_beauclair': return 1.0f;
			}
			break;
		case 'mod_food':
			switch(col)
			{
				case 'type_general': return 1.0f;
				case 'type_alchemist': return -1.0f;
				case 'type_armorer': return -1.0f;
				case 'type_blacksmith': return -1.0f;
				case 'type_herbalist': return 1.0f;
				case 'type_inn': return 1.0f;
				case 'type_enchanter': return -1.0f;
				case 'area_novigrad': return 0.9f;
				case 'area_skellige': return 1.0f;
				case 'area_nml': return 1.5f;
				case 'area_beauclair': return 0.85f;
			}
			break;
		case 'mod_horse':
			switch(col)
			{
				case 'type_general': return 1.0f;
				case 'type_alchemist': return -1.0f;
				case 'type_armorer': return 1.0f;
				case 'type_blacksmith': return 1.0f;
				case 'type_herbalist': return -1.0f;
				case 'type_inn': return -1.0f;
				case 'type_enchanter': return 0.9f;
				case 'area_novigrad': return 1.1f;
				case 'area_skellige': return 1.0f;
				case 'area_nml': return 0.9f;
				case 'area_beauclair': return 1.1f;
			}
			break;
		case 'mod_upgrade':
			switch(col)
			{
				case 'type_general': return 1.0f;
				case 'type_alchemist': return 1.0f;
				case 'type_armorer': return 1.0f;
				case 'type_blacksmith': return 1.0f;
				case 'type_herbalist': return -1.0f;
				case 'type_inn': return -1.0f;
				case 'type_enchanter': return 1.0f;
				case 'area_novigrad': return 1.05f;
				case 'area_skellige': return 1.0f;
				case 'area_nml': return 1.0f;
				case 'area_beauclair': return 1.1f;
			}
			break;
		case 'mod_weapon':
			switch(col)
			{
				case 'type_general': return 1.0f;
				case 'type_alchemist': return -1.0f;
				case 'type_armorer': return 0.9f;
				case 'type_blacksmith': return 1.0f;
				case 'type_herbalist': return -1.0f;
				case 'type_inn': return -1.0f;
				case 'type_enchanter': return 0.9f;
				case 'area_novigrad': return 1.05f;
				case 'area_skellige': return 1.0f;
				case 'area_nml': return 0.9f;
				case 'area_beauclair': return 1.1f;
			}
			break;
		case 'mod_secondary':
			switch(col)
			{
				case 'type_general': return 1.0f;
				case 'type_alchemist': return -1.0f;
				case 'type_armorer': return 0.9f;
				case 'type_blacksmith': return 1.0f;
				case 'type_herbalist': return -1.0f;
				case 'type_inn': return -1.0f;
				case 'type_enchanter': return 0.9f;
				case 'area_novigrad': return 1.05f;
				case 'area_skellige': return 1.0f;
				case 'area_nml': return 0.9f;
				case 'area_beauclair': return 1.1f;
			}
			break;
		case 'mod_junk':
			switch(col)
			{
				case 'type_general': return 1.0f;
				case 'type_alchemist': return -1.0f;
				case 'type_armorer': return -1.0f;
				case 'type_blacksmith': return -1.0f;
				case 'type_herbalist': return -1.0f;
				case 'type_inn': return -1.0f;
				case 'type_enchanter': return -1.0f;
				case 'area_novigrad': return 0.8f;
				case 'area_skellige': return 1.0f;
				case 'area_nml': return 1.0f;
				case 'area_beauclair': return 0.8f;
			}
			break;
		case 'mod_valuable':
			switch(col)
			{
				case 'type_general': return 1.0f;
				case 'type_alchemist': return 1.0f;
				case 'type_armorer': return 1.0f;
				case 'type_blacksmith': return 1.0f;
				case 'type_herbalist': return 1.0f;
				case 'type_inn': return 1.0f;
				case 'type_enchanter': return 1.0f;
				case 'area_novigrad': return 1.1f;
				case 'area_skellige': return 1.05f;
				case 'area_nml': return 1.05f;
				case 'area_beauclair': return 1.2f;
			}
			break;
		case 'mod_precious':
			switch(col)
			{
				case 'type_general': return 1.0f;
				case 'type_alchemist': return 1.0f;
				case 'type_armorer': return 1.0f;
				case 'type_blacksmith': return 1.0f;
				case 'type_herbalist': return 1.0f;
				case 'type_inn': return 1.0f;
				case 'type_enchanter': return 1.0f;
				case 'area_novigrad': return 1.2f;
				case 'area_skellige': return 1.15f;
				case 'area_nml': return 1.15f;
				case 'area_beauclair': return 1.3f;
			}
			break;
		case 'mod_origin_nml':
			switch(col)
			{
				case 'type_general': return 1.0f;
				case 'type_alchemist': return 1.0f;
				case 'type_armorer': return 1.0f;
				case 'type_blacksmith': return 1.0f;
				case 'type_herbalist': return 1.0f;
				case 'type_inn': return 1.0f;
				case 'type_enchanter': return 1.0f;
				case 'area_novigrad': return 0.9f;
				case 'area_skellige': return 1.05f;
				case 'area_nml': return 1.0f;
				case 'area_beauclair': return 1.1f;
			}
			break;
		case 'mod_origin_nonhuman':
			switch(col)
			{
				case 'type_general': return 1.0f;
				case 'type_alchemist': return 1.0f;
				case 'type_armorer': return 1.0f;
				case 'type_blacksmith': return 1.0f;
				case 'type_herbalist': return 1.0f;
				case 'type_inn': return 1.0f;
				case 'type_enchanter': return 1.0f;
				case 'area_novigrad': return 1.2f;
				case 'area_skellige': return 1.2f;
				case 'area_nml': return 1.2f;
				case 'area_beauclair': return 1.2f;
			}
			break;
		case 'mod_origin_skellige':
			switch(col)
			{
				case 'type_general': return 1.0f;
				case 'type_alchemist': return 1.0f;
				case 'type_armorer': return 1.0f;
				case 'type_blacksmith': return 1.0f;
				case 'type_herbalist': return 1.0f;
				case 'type_inn': return 1.0f;
				case 'type_enchanter': return 1.0f;
				case 'area_novigrad': return 1.1f;
				case 'area_skellige': return 1.0f;
				case 'area_nml': return 1.1f;
				case 'area_beauclair': return 1.2f;
			}
			break;
		case 'mod_origin_novigraad':
			switch(col)
			{
				case 'type_general': return 1.0f;
				case 'type_alchemist': return 1.0f;
				case 'type_armorer': return 1.0f;
				case 'type_blacksmith': return 1.0f;
				case 'type_herbalist': return 1.0f;
				case 'type_inn': return 1.0f;
				case 'type_enchanter': return 1.0f;
				case 'area_novigrad': return 1.0f;
				case 'area_skellige': return 1.1f;
				case 'area_nml': return 1.05f;
				case 'area_beauclair': return 1.1f;
			}
			break;
		case 'mod_origin_nilfgaard':
			switch(col)
			{
				case 'type_general': return 1.0f;
				case 'type_alchemist': return 1.0f;
				case 'type_armorer': return 1.0f;
				case 'type_blacksmith': return 1.0f;
				case 'type_herbalist': return 1.0f;
				case 'type_inn': return 1.0f;
				case 'type_enchanter': return 1.0f;
				case 'area_novigrad': return 1.05f;
				case 'area_skellige': return 1.05f;
				case 'area_nml': return 1.0f;
				case 'area_beauclair': return 1.0f;
			}
			break;
		case 'mod_origin_ofir':
			switch(col)
			{
				case 'type_general': return 1.0f;
				case 'type_alchemist': return 1.0f;
				case 'type_armorer': return 1.0f;
				case 'type_blacksmith': return 1.0f;
				case 'type_herbalist': return 1.0f;
				case 'type_inn': return 1.0f;
				case 'type_enchanter': return 1.0f;
				case 'area_novigrad': return 1.2f;
				case 'area_skellige': return 1.2f;
				case 'area_nml': return 1.2f;
				case 'area_beauclair': return 1.2f;
			}
			break;
	}
	return 1.0f;
}
