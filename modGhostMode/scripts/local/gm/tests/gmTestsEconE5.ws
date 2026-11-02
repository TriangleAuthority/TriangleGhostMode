// ECON slice E5: DE2 (5.x's new gear priced by analogy) and the binary edits of ECON-11 and ECON-12.
//
// In the regression: GMTest_econ_e5() (what a spawned Novigrad armorer asks and pays for a Netflix piece, a
// Netflix schematic and the Fire Horse saddle at DE2's list prices; the four patched scene and quest files load).
// DE2's definition prices of all 79 regular items are in the generated data test (GMTest_econdata, tools/gen_econ.py).
// The patched values themselves (Vivaldi's 390, the tax quest's 10,000, the Apiarian Phantom's reward name) are
// read only while the scene or quest phase runs: checked offline (gen_econ.py --verify, cr2w_dump.py).

// One item at a spawned merchant: its definition price (DE2's), Geralt's list price (the definition's plus 5.x's
// share from the copy's stats), what the merchant asks (ceil(list x the factors of the item's tags for his type and
// region)) and what he pays (trunc(asks x mod_sale's 0.25)), as slice E1 measured the formula; a legendary piece of gear
// first trunc(list x 1.2) (mod_legendary; seen in slice E5: a schematic tagged mod_legendary does not get it).
function GMTestEconE5Item(npc : CNewNPC, item : name, defPrice : int, legendary : bool, factors : float, label : string)
{
	var minv, pinv : CInventoryComponent;
	var mids, pids : array<SItemUniqueId>;
	var defP, list, base, buy, sale, eBuy, eSale : int;

	minv = npc.GetInventory();
	pinv = thePlayer.GetInventory();
	defP = theGame.GetDefinitionsManager().GetItemPrice(item);
	mids = minv.AddAnItem(item, 1, true, true, false);
	pids = pinv.AddAnItem(item, 1, true, true, false);
	if(mids.Size() == 0 || pids.Size() == 0)
	{
		GMTestReport(false, "DE2 " + item + ": not added");
		return;
	}
	list = pinv.GetItemPrice(pids[0]);
	buy = minv.GetItemPriceModified(mids[0], false);
	sale = minv.GetInventoryItemPriceModified(pinv.GetItem(pids[0]), true);
	base = list;
	if(legendary)
		base = FloorF((float)list * 1.2f + 0.001f);
	eBuy = CeilF((float)base * factors - 0.001f);
	eSale = FloorF((float)eBuy * 0.25f + 0.001f);
	GMTestReport(defP == defPrice && list >= defP && buy == eBuy && sale == eSale, "ECON-01 DE2 " + item + " at the Novigrad armorer: definition "
		+ defP + " (" + defPrice + "), list " + list + ", asks " + buy + " (" + eBuy + ", " + label + "), pays " + sale + " (" + eSale + ")");
	minv.RemoveItem(mids[0], 1);
	pinv.RemoveItem(pids[0], 1);
}

// The patched binary files load as resources (a file the engine could not read would come back NULL).
function GMTestEconE5Resource(path : string, label : string)
{
	var r : CResource;

	r = LoadResource(path, true);
	GMTestReport(r, label + ": " + path + " loads");
}

function GMTest_econ_e5()
{
	var npc : CNewNPC;

	npc = GMTestEconE2Spawn("living_world\dialogue\generic_merchants\entities\shop_generic_merchant_novigrad_armor.w2ent", 7);
	if(npc)
	{
		// trunc(list x 1.2) (mod_legendary), then mod_armor 1 (armorer) x 1.05 (Novigrad); 5.x's definition 4,458
		GMTestEconE5Item(npc, 'Netflix Armor 2', 5040, true, 1.05f, "legendary x 1.2, then x 1.05");
		// mod_crafting 1.1 (armorer) x 1.05 (Novigrad), no legendary factor on a schematic; DE2 the Wolf
		// counterpart's legacy price (ECON audit F3); 5.x's definition 538
		GMTestEconE5Item(npc, 'Netflix Armor schematic 2', 1027, false, 1.1f * 1.05f, "x 1.1 x 1.05");
		// mod_horse 1 (armorer) x 1.1 (Novigrad); 5.x's definition 150
		GMTestEconE5Item(npc, 'Fire Horse Saddle', 450, false, 1.1f, "x 1.1");
		npc.Destroy();
	}
	else
		GMTestReport(false, "DE2: the Novigrad armorer did not spawn");
	GMTestEconE5Resource("quests\secondary_npcs\default_dialogues\vimme_vivaldi_default.w2scene", "ECON-11 Vivaldi's repayment scene");
	GMTestEconE5Resource("dlc\ep1\data\quests\quest_files\mq6003_taxes\mq6003_taxes.w2phase", "ECON-11 the tax collector's quest phase");
	GMTestEconE5Resource("quests\generic_quests\novigrad\quest_files\mh307_minion\scenes\mh307_01_halflings.w2scene", "ECON-12 the Apiarian Phantom's opening scene");
	GMTestEconE5Resource("quests\generic_quests\novigrad\quest_files\mh307_minion\scenes\mh307_05_halflings_closing.w2scene", "ECON-12 the Apiarian Phantom's closing scene");
}

exec function gmtest_econ_e5()
{
	thePlayer.GMTestCount(true, true);
	GMTest_econ_e5();
	LogChannel('GMTest', "SUMMARY econ_e5: " + thePlayer.gmTestPassed + " passed, " + thePlayer.gmTestFailed + " failed");
}
