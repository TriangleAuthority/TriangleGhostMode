// ECON slice E2 (ECON-01 to ECON-04, PE13): legacy's list prices and price tags.
//
// In the regression: GMTest_econdata() (the generated table tests/gmTestsEconData.ws, tools/gen_econ.py: every
// regular ECON unit's definition price, category, name key and mod_ price tags as Ghost Mode's DLC gives them),
// GMTest_econ_e2() (what spawned merchants ask and pay for reference items, crown amounts worked from legacy's list
// prices and price table; Protofleder Mutagen at the dismantling station, PE13).

// One item's definition: price, category and name key (an item emptied by an `extend` reads price 0, category
// 'default' and no key: the Hearts of Stone pitfall).
function GMTestEconDef(item : name, price : int, category : name, key : string, out checks : int) : int
{
	var dm : CDefinitionsManagerAccessor;
	var p : int;
	var c : name;
	var k : string;

	checks += 1;
	dm = theGame.GetDefinitionsManager();
	p = dm.GetItemPrice(item);
	c = dm.GetItemCategory(item);
	k = dm.GetItemLocalisationKeyName(item);
	if(p == price && c == category && k == key)
		return 0;
	LogChannel('GMTest', "FAIL ECON data " + item + " reads price " + p + ", category " + c + ", key " + k
		+ " (expected " + price + ", " + category + ", " + key + ")");
	return 1;
}

// One price tag present or absent on an item's definition.
function GMTestEconTag(item : name, tag : name, has : bool, out checks : int) : int
{
	checks += 1;
	if(theGame.GetDefinitionsManager().ItemHasTag(item, tag) == has)
		return 0;
	LogChannel('GMTest', "FAIL ECON data " + item + " tag " + tag + (has ? " missing" : " present"));
	return 1;
}

function GMTest_econdata()
{
	var f, checks : int;

	f = GMTestEconDataAll(checks);
	GMTestReport(f == 0 && checks == GMTestEconDataChecks(), "ECON-01 to ECON-04 data: " + checks + " readings of "
		+ GMTestEconDataItems() + " items (price, category and name key, each 1.32, legacy or 5.x price tag present or absent) as Ghost Mode's DLC gives them; "
		+ f + " differ");
}

exec function gmtest_econdata()
{
	thePlayer.GMTestCount(true, true);
	GMTest_econdata();
	LogChannel('GMTest', "SUMMARY econdata: " + thePlayer.gmTestPassed + " passed, " + thePlayer.gmTestFailed + " failed");
}

// One item at a spawned merchant: Geralt's list price (the inventory's), what the merchant asks (his copy) and
// pays (Geralt's copy), against crown amounts.
function GMTestEconE2Item(npc : CNewNPC, label : string, item : name, eList : int, eBuy : int, eSale : int)
{
	var minv, pinv : CInventoryComponent;
	var mids, pids : array<SItemUniqueId>;
	var list, buy, sale : int;

	minv = npc.GetInventory();
	pinv = thePlayer.GetInventory();
	mids = minv.AddAnItem(item, 1, true, true, false);
	pids = pinv.AddAnItem(item, 1, true, true, false);
	if(mids.Size() == 0 || pids.Size() == 0)
	{
		GMTestReport(false, "ECON-01 " + label + " " + item + ": not added");
		return;
	}
	list = pinv.GetItemPrice(pids[0]);
	buy = minv.GetItemPriceModified(mids[0], false);
	sale = minv.GetInventoryItemPriceModified(pinv.GetItem(pids[0]), true);
	GMTestReport(list == eList && buy == eBuy && sale == eSale, "ECON-01 " + label + " " + item + ": list " + list + " (" + eList
		+ "), asks " + buy + " (" + eBuy + "), pays " + sale + " (" + eSale + ")");
	minv.RemoveItem(mids[0], 1);
	pinv.RemoveItem(pids[0], 1);
}

function GMTestEconE2Spawn(path : string, dist : float) : CNewNPC
{
	var template : CEntityTemplate;

	template = (CEntityTemplate)LoadResource(path, true);
	return (CNewNPC)theGame.CreateEntity(template, thePlayer.GetWorldPosition() - thePlayer.GetHeadingVector() * dist, thePlayer.GetWorldRotation());
}

// PE13 (CRAFT-08): the dismantling station lists an item when it has mod_alchemy_table and is no quest item and
// not shown-hidden (W3StandaloneDismantleComponent.ShouldShowItem, its condition read on Geralt's copy).
function GMTestEconE2Dismantle(item : name, want : bool)
{
	var pinv : CInventoryComponent;
	var pids : array<SItemUniqueId>;
	var tags : array<name>;
	var show : bool;

	pinv = thePlayer.GetInventory();
	pids = pinv.AddAnItem(item, 1, true, true, false);
	if(pids.Size() == 0)
	{
		GMTestReport(false, "PE13 " + item + ": not added");
		return;
	}
	pinv.GetItemTags(pids[0], tags);
	show = !tags.Contains(theGame.params.TAG_DONT_SHOW) && !tags.Contains(theGame.params.TAG_DONT_SHOW_ONLY_IN_PLAYERS)
		&& tags.Contains('mod_alchemy_table') && !pinv.IsItemQuest(pids[0]);
	GMTestReport(show == want, "CRAFT-08 (PE13) " + item + " at the dismantling station: " + show + " (" + want + ")");
	pinv.RemoveItem(pids[0], 1);
}

// The crowns are worked from legacy's list prices and price table by slice E1's formula (asks ceil(list x the
// tags' type x region factors), pays trunc(asks x mod_sale's share), a bolt a tenth): Ruby 140 at the Novigrad
// armorer ceil(140 x 1 (mod_precious, armorer) x 1.2 (Novigrad)) = 168, pays 42; gear's list in play is its definition's plus 5.x's
// share from its stats (Bear Armor 1 1,851 + 86 = 1,937, x 1.2 mod_legendary = 2,324, asks ceil(2,324 x 1.05) =
// 2,441, pays 610; Long Steel Sword 57 + 5 = 62). With 5.x's list prices (a throwaway build) every amount differs.
function GMTest_econ_e2()
{
	var npc : CNewNPC;
	var g : string;

	g = "living_world\dialogue\generic_merchants\entities\shop_generic_merchant_";
	npc = GMTestEconE2Spawn(g + "novigrad_armor.w2ent", 7);
	if(npc)
	{
		GMTestEconE2Item(npc, "Novigrad armorer", 'Bear Armor 1', 1937, 2441, 610);
		GMTestEconE2Item(npc, "Novigrad armorer", 'Ruby', 140, 168, 42);
		npc.Destroy();
	}
	npc = GMTestEconE2Spawn(g + "novigrad_weapons.w2ent", 6);
	if(npc)
	{
		GMTestEconE2Item(npc, "Novigrad blacksmith", 'Long Steel Sword', 62, 66, 16);
		GMTestEconE2Item(npc, "Novigrad blacksmith", 'Steel ingot', 16, 19, 4);
		GMTestEconE2Item(npc, "Novigrad blacksmith", 'Tracking Bolt', 70, 7, 1);
		npc.Destroy();
	}
	npc = GMTestEconE2Spawn(g + "novigrad_herbalist.w2ent", 8);
	if(npc)
	{
		GMTestEconE2Item(npc, "Novigrad herbalist", 'Drowner brain', 15, 17, 4);
		GMTestEconE2Item(npc, "Novigrad herbalist", 'Arachas eyes', 38, 42, 10);
		npc.Destroy();
	}
	npc = GMTestEconE2Spawn(g + "nomansland_innkeeper.w2ent", 13);
	if(npc)
	{
		GMTestEconE2Item(npc, "No Man's Land innkeeper", 'Viziman Champion', 9, 14, 3);
		npc.Destroy();
	}
	GMTestEconE2Dismantle('Protofleder Mutagen', true);
	GMTestEconE2Dismantle('Katakan mutagen', true);
}

exec function gmtest_econ_e2()
{
	thePlayer.GMTestCount(true, true);
	GMTest_econ_e2();
	LogChannel('GMTest', "SUMMARY econ_e2: " + thePlayer.gmTestPassed + " passed, " + thePlayer.gmTestFailed + " failed");
}
