// In-game tests for LOOT (merchants' stock, containers, rewards, standalone starts). See docs/features/loot.md.

// LOOT's situation-free checks (in gmtest_regress()).
function GMTest_loot()
{
	GMTest_loot01();
	GMTest_loot04();
	GMTest_loot05();
	GMTest_loot07_lists();
}

exec function gmtest_loot()
{
	GMTest_loot();
}

// The test merchant that loot lists are rolled into (the generic Novigrad weaponsmith, ITEM's test merchant,
// tag gmtest_lootroller): spawned once per session, restocked once at once (so its own stock does not come
// back into a roll), and kept: spawning, restocking and removing merchants again and again crashed the game
// (2026-10-22).
function GMTestLootRoller() : W3MerchantNPC
{
	var m : W3MerchantNPC;

	m = (W3MerchantNPC)theGame.GetEntityByTag('gmtest_lootroller');
	if(m)
		return m;
	m = GMTestItemSpawnMerchant();
	if(!m)
		return NULL;
	m.AddTag('gmtest_lootroller');
	m.GetInventory().AutoBalanaceItemsWithPlayerLevel();
	return m;
}

// The items a loot list gives, rolled into the test merchant's emptied inventory. Rolls follow Geralt's
// level (LOOT-03's gates). AddItemsFromLootDefinition only queues the list: its items appear when the
// inventory is balanced (AutoBalanaceItemsWithPlayerLevel, as a shop does after it). A list queued this way
// gives at most 62 kinds of items, the first ones of a long list (an engine limit of this path, seen
// 2026-10-22); a merchant's restock from its own entity's lists is not limited (gmtest_merchantroll: 79, 120
// and 185 kinds, CRAFT/LOOT audit F6).
function GMTestLootRoll(list : name, rolls : int) : array<name>
{
	var m : W3MerchantNPC;
	var inv : CInventoryComponent;
	var ids : array<SItemUniqueId>;
	var got : array<name>;
	var i, k : int;

	m = GMTestLootRoller();
	if(!m)
		return got;
	inv = m.GetInventory();
	for(k = 0; k < rolls; k += 1)
	{
		inv.RemoveAllItems();
		inv.AddItemsFromLootDefinition(list);
		inv.AutoBalanaceItemsWithPlayerLevel();
		inv.GetAllItems(ids);
		for(i = 0; i < ids.Size(); i += 1)
			if(!got.Contains(inv.GetItemName(ids[i])))
				got.PushBack(inv.GetItemName(ids[i]));
	}
	inv.RemoveAllItems();
	return got;
}

// LOOT-01 (and LOOT-03's gates): legacy's shop lists from the whole-file overrides. The White Orchard
// herbalist (_store__Prolog_Herbalist) sells the Alchemy dismantle kit and the Mahakam spirit recipe, and
// no longer Bear pelt, Water essence or Elemental essence (merchants sell no monster parts).
function GMTest_loot01()
{
	var names : array<name>;

	names = GMTestLootRoll('_store__Prolog_Herbalist', 2);
	GMTestReport(names.Size() > 0 && names.Contains('alchemy_dismantle_kit_1') && names.Contains('Recipe for Mahakam spirit 1') && names.Contains('Mandrake cordial')
		&& !names.Contains('Bear pelt') && !names.Contains('Water essence') && !names.Contains('Elemental essence'),
		"LOOT-01 the White Orchard herbalist's stock (" + names.Size() + " kinds): Alchemy dismantle kit " + names.Contains('alchemy_dismantle_kit_1') + ", Mahakam spirit recipe "
		+ names.Contains('Recipe for Mahakam spirit 1') + ", Mandrake cordial " + names.Contains('Mandrake cordial') + "; Bear pelt " + names.Contains('Bear pelt') + ", Water essence " + names.Contains('Water essence') + " (false)");
}

exec function gmtest_loot01()
{
	GMTest_loot01();
}

// LOOT-04 with CRAFT-10: the master kits at Hattori (master weaponsmith tools), the Hearts of Stone
// enchanter and Blood and Wine's archmaster (both kits); Yoana's master stock (the master armorsmith tools,
// the craftable quest armors' schematics) added to her inventory once the fact of her quest is set.
function GMTest_loot04()
{
	var names : array<name>;
	var m : W3MerchantNPC;
	var inv : CInventoryComponent;
	var had : bool;
	var before, after, noFact : int;

	names = GMTestLootRoll('_store__Hattori_Master_Blacksmith', 1);
	GMTestReport(names.Contains('weapon_repair_kit_4'), "LOOT-04 Hattori sells the master weaponsmith tools: " + names.Contains('weapon_repair_kit_4'));
	// The enchanter's list holds both kits after 128 runes, glyphs and schematics: a queued roll gives the
	// first 62 kinds only (this path's limit); his real shop, restocked from his entity file, stocks them
	// (CRAFT/LOOT audit F6).
	names = GMTestLootRoll('_store__LW_DLC_EnchanterMaster', 1);
	GMTestReport(names.Size() == 62 && !names.Contains('weapon_repair_kit_4') && !names.Contains('armor_repair_kit_4'),
		"LOOT-04 the Hearts of Stone enchanter's list, queued, rolls its first 62 kinds (" + names.Size() + "), not the master kits at its end (the queued path's limit)");
	names = GMTestLootRoll('_EP2_store_archmaster', 1);
	GMTestReport(names.Contains('weapon_repair_kit_4') && names.Contains('armor_repair_kit_4'), "LOOT-04 Blood and Wine's archmaster sells both master kits");

	// Yoana: the test merchant tagged as her, before and after her quest's fact.
	m = GMTestLootRoller();
	if(!m)
	{
		GMTestReport(false, "LOOT-04 Yoana: no test merchant");
		return;
	}
	inv = m.GetInventory();
	m.AddTag('sq108_blacksmith_woman');
	had = FactsDoesExist("sq108_master_bsmith_helped");
	inv.RemoveAllItems();
	if(had)
		FactsRemove("sq108_master_bsmith_helped");
	inv.AutoBalanaceItemsWithPlayerLevel();
	noFact = inv.GetItemQuantityByName('armor_repair_kit_4');
	FactsAdd("sq108_master_bsmith_helped");
	inv.AutoBalanaceItemsWithPlayerLevel();
	after = inv.GetItemQuantityByName('armor_repair_kit_4');
	GMTestReport(noFact == 0 && after > 0 && inv.HasItem('q108 Heavy Armor 4 schematic') && inv.HasItem('Oathbreaker Armor schematic') == (thePlayer.GetLevel() >= 14),
		"LOOT-04 Yoana's master stock: before her quest " + noFact + " master armorsmith tools, after " + after + "; Hindarfjall schematic " + inv.HasItem('q108 Heavy Armor 4 schematic')
		+ ", Oathbreaker schematic " + inv.HasItem('Oathbreaker Armor schematic') + " (from level 14)");
	if(!had)
		FactsRemove("sq108_master_bsmith_helped");
	m.RemoveTag('sq108_blacksmith_woman');
	inv.RemoveAllItems();
}

exec function gmtest_loot04()
{
	GMTest_loot04();
}

// LOOT-05: area-dependent containers (legacy's lists from the whole-file overrides): a mine holds ore and
// tools, no hides or pelts; a common chest no alchemy bases; the Balisse fix gives a herbalist 10 fruit and
// nothing to other merchants. One roll each: rolls in one call pick the same entries, and rolling the common
// chest's list into the test merchant a few times crashed the game (2026-10-22; real chests roll natively).
function GMTest_loot05()
{
	var names : array<name>;
	var m : W3MerchantNPC;

	names = GMTestLootRoll('_mine_everywhere', 1);
	GMTestReport(names.Size() > 0 && !names.Contains('Bear pelt') && !names.Contains('Deer hide') && !names.Contains('Dark steel plate') && !names.Contains('Draconide leather'),
		"LOOT-05 a mine's chest (" + names.Size() + " kinds in a roll): Bear pelt " + names.Contains('Bear pelt') + ", Deer hide " + names.Contains('Deer hide') + ", Dark steel plate " + names.Contains('Dark steel plate') + " (false)");
	names = GMTestLootRoll('_generic chest_everywhere', 1);
	GMTestReport(names.Size() > 0 && !names.Contains('Alcohest') && !names.Contains('Alchemists powder') && !names.Contains('Amethyst dust'),
		"LOOT-05 a common chest (" + names.Size() + " kinds in a roll): Alcohest " + names.Contains('Alcohest') + ", Amethyst dust " + names.Contains('Amethyst dust') + " (false)");
	m = GMTestLootRoller();
	if(m)
	{
		m.GetInventory().RemoveAllItems();
		m.GMBalisseFruitFix();
		GMTestReport(m.GetInventory().GetItemQuantityByName('Balisse fruit') == 0, "LOOT-05 the Balisse fix leaves a weaponsmith without fruit");
	}
}

exec function gmtest_loot05()
{
	GMTest_loot05();
}

// LOOT-07 and LOOT-08: legacy's reward items. Tauler's killer's reward (sq106_4_tauler_killed): heavy boots 05, heavy
// gloves 03 and a Rune of Triglav; the Undvik giant's (q202_3_killed_giant): Arainne and three of Urskar's
// journals (lore books, LOOT-08). The items given are removed again (the reward's experience and gold stay:
// run it on a save not kept; not in the regression, as the experience can level Geralt up).
function GMTest_loot07()
{
	var w : W3PlayerWitcher;
	var b1, b2, b3, a1, a2, a3, money : int;

	w = GetWitcherPlayer();
	b1 = w.inv.GetItemQuantityByName('Heavy boots 05');
	b2 = w.inv.GetItemQuantityByName('Heavy gloves 03');
	b3 = w.inv.GetItemQuantityByName('Rune triglav');
	money = w.GetMoney();
	theGame.GiveReward('sq106_4_tauler_killed', w);
	GMTestReport(w.inv.GetItemQuantityByName('Heavy boots 05') == b1 + 1 && w.inv.GetItemQuantityByName('Heavy gloves 03') == b2 + 1 && w.inv.GetItemQuantityByName('Rune triglav') == b3 + 1,
		"LOOT-07 Tauler's killer's reward: heavy boots 05 +" + (w.inv.GetItemQuantityByName('Heavy boots 05') - b1) + ", heavy gloves 03 +" + (w.inv.GetItemQuantityByName('Heavy gloves 03') - b2)
		+ ", Rune of Triglav +" + (w.inv.GetItemQuantityByName('Rune triglav') - b3) + " (1 each)");
	w.inv.RemoveItemByName('Heavy boots 05', 1);
	w.inv.RemoveItemByName('Heavy gloves 03', 1);
	w.inv.RemoveItemByName('Rune triglav', 1);
	a1 = w.inv.GetItemQuantityByName('Arainne');
	a2 = w.inv.GetItemQuantityByName('lore_journals_from_urskar_5');
	theGame.GiveReward('q202_3_killed_giant', w);
	GMTestReport(w.inv.GetItemQuantityByName('Arainne') == a1 + 1 && w.inv.GetItemQuantityByName('lore_journals_from_urskar_5') == a2 + 1,
		"LOOT-07 and LOOT-08 the Undvik giant's reward: Arainne +" + (w.inv.GetItemQuantityByName('Arainne') - a1) + ", Urskar's journal 5 +" + (w.inv.GetItemQuantityByName('lore_journals_from_urskar_5') - a2) + " (1 each)");
	w.inv.RemoveItemByName('Arainne', 1);
	w.inv.RemoveItemByName('lore_journals_from_urskar_5', 1);
	w.inv.RemoveItemByName('lore_journals_from_urskar_6', 1);
	w.inv.RemoveItemByName('lore_journals_from_urskar_7', 1);
	if(w.GetMoney() > money)
		w.RemoveMoney(w.GetMoney() - money);
}

exec function gmtest_loot07()
{
	GMTest_loot07();
}

// LOOT-09 (destructive: it empties Geralt's inventory, as a standalone start does; reload the save
// afterwards, do not save): the Hearts of Stone start's inventory, then the Blood and Wine one's.
exec function gmtest_loot09(ep : int)
{
	var w : W3PlayerWitcher;

	w = GetWitcherPlayer();
	if(ep == 2)
	{
		w.StandaloneEp2_1();
		GMTestReport(w.GetMoney() == 5000 && w.inv.GetItemQuantityByName('Greater mutagen red') == 1 && w.inv.GetItemQuantityByName('Lesser mutagen red') == 2,
			"LOOT-09 Blood and Wine's start: " + w.GetMoney() + " crowns (5000), greater mutagen red " + w.inv.GetItemQuantityByName('Greater mutagen red') + " (1), lesser " + w.inv.GetItemQuantityByName('Lesser mutagen red') + " (2)");
		return;
	}
	w.StandaloneEp1_1();
	GMTestReport(w.GetMoney() == 4000 && w.inv.GetItemQuantityByName('Split Bolt') == 20 && w.inv.GetItemQuantityByName('Dumpling') == 5 && w.inv.GetItemQuantityByName('Greater mutagen red') == 1
		&& w.inv.GetItemQuantityByName('Bear pelt') == 0 && FactsQuerySum("standalone_ep1") == 1,
		"LOOT-09 Hearts of Stone's start: " + w.GetMoney() + " crowns (4000), Split Bolts " + w.inv.GetItemQuantityByName('Split Bolt') + " (20), Dumplings " + w.inv.GetItemQuantityByName('Dumpling')
		+ " (5), greater mutagen red " + w.inv.GetItemQuantityByName('Greater mutagen red') + " (1), Bear pelt " + w.inv.GetItemQuantityByName('Bear pelt') + " (0)");
}

// Diagnostic: the items one roll of a loot list gives (into the test merchant, balanced), up to max names.
exec function gmtest_lootlist(list : name, optional max : int, optional rolls : int)
{
	var names : array<name>;
	var i : int;
	var s : string;

	if(max <= 0)
		max = 60;
	if(rolls <= 0)
		rolls = 1;
	names = GMTestLootRoll(list, rolls);
	for(i = 0; i < names.Size() && i < max; i += 1)
		s += NameToString(names[i]) + "; ";
	LogChannel('GMTest', "INFO " + list + " (" + names.Size() + " kinds in " + rolls + " rolls): " + s);
}

// LOOT-07 (DT8): a quest list legacy gave more items keeps 5.x's attributes with legacy's quantity
// (CRAFT/LOOT audit F4): Avallac'h's notes give all four of legacy's notes, Yennefer's notes both.
function GMTest_loot07_lists()
{
	var names : array<name>;
	var yen : array<name>;

	names = GMTestLootRoll('q210_avallach_lover_notes', 1);
	yen = GMTestLootRoll('q002_yennefer_notes', 1);
	GMTestReport(names.Size() == 4 && names.Contains('lore_elven_legends') && yen.Size() == 2 && yen.Contains('lore_inteligence_report_about_ciri'),
		"LOOT-07 quest lists with 5.x's attributes and legacy's quantity: Avallac'h's notes give " + names.Size() + " kinds (4), Yennefer's notes " + yen.Size() + " (2)");
}

exec function gmtest_loot07_lists()
{
	GMTest_loot07_lists();
}
