// ALCH-17 and ALCH-18 tests: alchemy tooltips, descriptions and debug commands.

function GMTestAlchTipValue(tips : array<SAttributeTooltip>, attr : name) : float
{
	var i : int;

	for(i = 0; i < tips.Size(); i += 1)
		if(tips[i].originName == attr)
			return tips[i].value;
	return -1;
}

function GMTestAlchTipList(tips : array<SAttributeTooltip>) : string
{
	var i : int;
	var s : string;

	for(i = 0; i < tips.Size(); i += 1)
		s += tips[i].originName + "=" + NoTrailZeros(RoundTo(tips[i].value, 3)) + " ";
	return s;
}

// Regression: the potion, bomb and decoction texts from the data.
function GMTest_alch17()
{
	var inv : CInventoryComponent;
	var tips : array<SAttributeTooltip>;
	var ids : array<SItemUniqueId>;
	var desc, missing : string;
	var i, held : int;
	var names : array<name>;

	inv = thePlayer.inv;
	inv.GMGetPotionAttributesByName('Golden Oriole 3', tips);
	GMTestReport(AbsF(GMTestAlchTipValue(tips, 'poison_resistance_perc') - 0.5) < 0.001, "ALCH-17 Golden Oriole 3's tooltip lists its poison resistance (" + GMTestAlchTipList(tips) + ")");
	tips.Clear();
	inv.GMGetPotionAttributesByName('Mutagen 1', tips);
	GMTestReport(tips.Size() == 0, "ALCH-17 a decoction lists no attributes (its description has the values)");
	tips.Clear();
	ids = inv.AddAnItem('Petri Philtre 2', 1);
	inv.GetPotionAttributesForTooltip(ids[0], tips);
	inv.RemoveItem(ids[0], 1);
	GMTestReport(tips.Size() > 0 && GMTestAlchTipValue(tips, 'spell_power') > 0.29, "ALCH-17 an item's potion tooltip is the by-name one (" + GMTestAlchTipList(tips) + ")");
	tips.Clear();
	inv.GMGetBombAttributesForTooltipByName('Dwimeritium Bomb 3', tips);
	GMTestReport(GMTestAlchTipValue(tips, 'dbomb_armor_piercing') == 100 && AbsF(GMTestAlchTipValue(tips, 'dbomb_dmg_reduction') - 0.5) < 0.001,
		"ALCH-17 the Dimeritium bomb's tooltip lists its effect (" + GMTestAlchTipList(tips) + ")");
	tips.Clear();
	inv.GMGetBombAttributesForTooltipByName('Samum 3', tips);
	GMTestReport(AbsF(GMTestAlchTipValue(tips, 'critical_hit_chance') - 1) < 0.001, "ALCH-17 Samum 3's tooltip lists its crit chance (" + GMTestAlchTipList(tips) + ")");
	// every decoction's description filled, with the toxicity offset note
	names = GMTestDecoctionItems();
	for(i = 0; i < names.Size(); i += 1)
	{
		desc = "";
		inv.GMFillInMutagenDescriptionByName(names[i], desc);
		if(desc == "" || StrFindFirst(desc, "$") >= 0 || StrFindFirst(desc, GetLocStringByKeyExt("gm_toxicity_offset_description")) < 0)
			missing += NameToString(names[i]) + " ";
	}
	desc = "";
	inv.GMFillInMutagenDescriptionByName('Mutagen 1', desc);
	GMTestReport(missing == "" && GetLocStringByKeyExt("gm_toxicity_offset_description") != "", "ALCH-17 28 decoction descriptions filled (unfilled: '" + missing + "'); Katakan: " + StrLeft(desc, 90));
	GMTest_alch17_texts();
	GMTestReport(GetLocStringByKeyExt("attribute_name_vsOgre_critical_hit_chance") != "" && GetLocStringByKeyExt("attribute_name_cloud_duration") != "" && GetLocStringByKeyExt("effect_dimeritium") != "",
		"ALCH-17 attribute names: " + GetLocStringByKeyExt("attribute_name_vsOgre_critical_hit_chance") + "; " + GetLocStringByKeyExt("attribute_name_cloud_duration"));
}

// Audit F6 to F12: the texts by key (language-neutral: each key against the string row that must win).
function GMTest_alch17_texts()
{
	var dm : CDefinitionsManagerAccessor;
	var oils : array<name>;
	var i : int;
	var bad, key : string;

	GMTestReport(GetLocStringByKeyExt("item_desc_cat_1") == GetLocStringById(2110992633) && GetLocStringByKeyExt("effect_CatEffect_desc") == GetLocStringById(2110992634),
		"ALCH-07 audit F7 Cat 1's and Cat's buff text without crit chance: " + GetLocStringByKeyExt("item_desc_cat_1") + " / " + GetLocStringByKeyExt("effect_CatEffect_desc"));
	GMTestReport(GetLocStringByKeyExt("item_desc_blizzard_1") == GetLocStringById(2110992635) && GetLocStringByKeyExt("item_desc_blizzard_2") == GetLocStringById(2110992471)
		&& GetLocStringByKeyExt("item_desc_blizzard_3") == GetLocStringById(2110992636), "ALCH-07 audit F8 Blizzard 1/2/3: " + GetLocStringByKeyExt("item_desc_blizzard_1") + " / " + GetLocStringByKeyExt("item_desc_blizzard_3"));
	GMTestReport(GetLocStringByKeyExt("item_desc_swallow_3") == GetLocStringById(2110992539), "ALCH-04 audit F9 Swallow 3: " + GetLocStringByKeyExt("item_desc_swallow_3"));
	GMTestReport(GetLocStringByKeyExt("item_desc_samum_3") == GetLocStringById(2110992637) && GetLocStringByKeyExt("effect_GoldenOrioleEffect_desc") == GetLocStringById(2110992638),
		"ALCH-14, ALCH-05 audit F12 Samum 3 / Golden Oriole's buff: " + GetLocStringByKeyExt("item_desc_samum_3") + " / " + GetLocStringByKeyExt("effect_GoldenOrioleEffect_desc"));
	GMTestReport(GetLocStringByKeyExt("item_desc_cat_3") == GetLocStringById(2110992235) && GetLocStringByKeyExt("item_desc_junk_no_ingr") == GetLocStringById(2110992259) && GetLocStringById(2110992259) != "",
		"ALCH-17 audit F6 Cat 3 by its name key: " + GetLocStringByKeyExt("item_desc_cat_3") + "; junk: " + GetLocStringByKeyExt("item_desc_junk_no_ingr"));
	dm = theGame.GetDefinitionsManager();
	oils = GMTestOilItems();
	for(i = 0; i < oils.Size(); i += 1)
	{
		key = StrReplaceAll(dm.GetItemLocalisationKeyName(oils[i]), "item_name_", "item_desc_");
		if(GetLocStringByKeyExt(key) == "" || GetLocStringByKeyExt(key) == GetLocStringByKeyExt("item_desc_oil"))
			bad += NameToString(oils[i]) + " ";
	}
	GMTestReport(oils.Size() == 36 && bad == "", "ALCH-16 audit F6 the 36 oils have their own texts by name key (missing: '" + bad + "')");
}

function GMTestOilItems() : array<name>
{
	var a : array<name>;

	a.PushBack('Beast Oil 1'); a.PushBack('Beast Oil 2'); a.PushBack('Beast Oil 3');
	a.PushBack('Cursed Oil 1'); a.PushBack('Cursed Oil 2'); a.PushBack('Cursed Oil 3');
	a.PushBack('Draconide Oil 1'); a.PushBack('Draconide Oil 2'); a.PushBack('Draconide Oil 3');
	a.PushBack('Hanged Man Venom 1'); a.PushBack('Hanged Man Venom 2'); a.PushBack('Hanged Man Venom 3');
	a.PushBack('Hybrid Oil 1'); a.PushBack('Hybrid Oil 2'); a.PushBack('Hybrid Oil 3');
	a.PushBack('Insectoid Oil 1'); a.PushBack('Insectoid Oil 2'); a.PushBack('Insectoid Oil 3');
	a.PushBack('Magicals Oil 1'); a.PushBack('Magicals Oil 2'); a.PushBack('Magicals Oil 3');
	a.PushBack('Necrophage Oil 1'); a.PushBack('Necrophage Oil 2'); a.PushBack('Necrophage Oil 3');
	a.PushBack('Ogre Oil 1'); a.PushBack('Ogre Oil 2'); a.PushBack('Ogre Oil 3');
	a.PushBack('Relic Oil 1'); a.PushBack('Relic Oil 2'); a.PushBack('Relic Oil 3');
	a.PushBack('Specter Oil 1'); a.PushBack('Specter Oil 2'); a.PushBack('Specter Oil 3');
	a.PushBack('Vampire Oil 1'); a.PushBack('Vampire Oil 2'); a.PushBack('Vampire Oil 3');
	return a;
}

function GMTestDecoctionItems() : array<name>
{
	var a : array<name>;

	a.PushBack('Mutagen 1'); a.PushBack('Mutagen 2'); a.PushBack('Mutagen 3'); a.PushBack('Mutagen 4'); a.PushBack('Mutagen 5');
	a.PushBack('Mutagen 6'); a.PushBack('Mutagen 7'); a.PushBack('Mutagen 8'); a.PushBack('Mutagen 9'); a.PushBack('Mutagen 10');
	a.PushBack('Mutagen 11'); a.PushBack('Mutagen 12'); a.PushBack('Mutagen 13'); a.PushBack('Mutagen 14'); a.PushBack('Mutagen 15');
	a.PushBack('Mutagen 16'); a.PushBack('Mutagen 17'); a.PushBack('Mutagen 18'); a.PushBack('Mutagen 19'); a.PushBack('Mutagen 20');
	a.PushBack('Mutagen 21'); a.PushBack('Mutagen 22'); a.PushBack('Mutagen 23'); a.PushBack('Mutagen 24'); a.PushBack('Mutagen 25');
	a.PushBack('Mutagen 26'); a.PushBack('Mutagen 27'); a.PushBack('Mutagen 28');
	return a;
}

exec function gmtest_alch17_regress()
{
	GMTest_alch17();
}

// The item tooltips as the inventory builds them (W3TooltipComponent.GetBaseItemData; needs the HUD):
// a bomb's stats list, a decoction's description, a potion's duration as drunk.
exec function gmtest_alch17_tooltips()
{
	var w : W3PlayerWitcher;
	var tc : W3TooltipComponent;
	var data, line : CScriptedFlashObject;
	var stats : CScriptedFlashArray;
	var ids : array<SItemUniqueId>;
	var i : int;
	var s, desc : string;
	var found : bool;
	var dur : string;

	w = GetWitcherPlayer();
	tc = new W3TooltipComponent in w;
	tc.initialize(w.inv, theGame.GetHud().GetHudFlashValueStorage());
	tc.setCurrentInventory(w.inv);

	ids = w.inv.AddAnItem('Dwimeritium Bomb 2', 1);
	data = tc.GetBaseItemData(ids[0], w.inv);
	stats = data.GetMemberFlashArray("StatsList");
	s = "";
	for(i = 0; i < stats.GetLength(); i += 1)
	{
		line = stats.GetElementFlashObject(i);
		s += line.GetMemberFlashString("name") + " " + line.GetMemberFlashString("value") + "; ";
		if(line.GetMemberFlashString("id") == "dbomb_armor_piercing")
			found = true;
	}
	w.inv.RemoveItem(ids[0], 1);
	GMTestReport(found, "ALCH-17 the Dimeritium bomb's tooltip: " + s);

	ids = w.inv.AddAnItem('Mutagen 24', 1);
	data = tc.GetBaseItemData(ids[0], w.inv);
	desc = data.GetMemberFlashString("Description");
	w.inv.RemoveItem(ids[0], 1);
	GMTestReport(StrFindFirst(desc, "$") < 0 && StrFindFirst(desc, "50") >= 0, "ALCH-17 the Werewolf decoction's tooltip: " + StrLeft(desc, 160));

	ids = w.inv.AddAnItem('Thunderbolt 3', 1);
	dur = NoTrailZeros(RoundMath(w.CalculatePotionDuration(ids[0], false)));
	data = tc.GetBaseItemData(ids[0], w.inv);
	stats = data.GetMemberFlashArray("StatsList");
	s = "";
	for(i = 0; i < stats.GetLength(); i += 1)
	{
		line = stats.GetElementFlashObject(i);
		s += line.GetMemberFlashString("name") + " " + line.GetMemberFlashString("value") + "; ";
	}
	w.inv.RemoveItem(ids[0], 1);
	GMTestReport(StrFindFirst(s, dur) >= 0, "ALCH-17 Thunderbolt 3's tooltip (duration as drunk " + dur + " s): " + s);
	delete tc;
}

// Audit F6 to F12: the descriptions and stats as the inventory builds them (needs the HUD).
function GMTestAlchTooltipText(tc : W3TooltipComponent, itemName : name, out stats : string) : string
{
	var w : W3PlayerWitcher;
	var data : CScriptedFlashObject;
	var ids : array<SItemUniqueId>;
	var desc : string;

	w = GetWitcherPlayer();
	ids = w.inv.AddAnItem(itemName, 1);
	data = tc.GetBaseItemData(ids[0], w.inv);
	desc = data.GetMemberFlashString("Description");
	stats = GMTestAlchFlashListText(data.GetMemberFlashArray("StatsList"));
	w.inv.RemoveItem(ids[0], 1);
	LogChannel('GMTest', "INFO " + NameToString(itemName) + ": '" + desc + "' | " + stats);
	return desc;
}

function GMTestAlchFlashListText(list : CScriptedFlashArray) : string
{
	var i : int;
	var s : string;
	var line : CScriptedFlashObject;

	for(i = 0; i < list.GetLength(); i += 1)
	{
		line = list.GetElementFlashObject(i);
		s += line.GetMemberFlashString("name") + " " + line.GetMemberFlashString("value") + "; ";
	}
	return s;
}

exec function gmtest_alch17_texts()
{
	var w : W3PlayerWitcher;
	var tc : W3TooltipComponent;
	var d, st, sec : string;
	var comp : W3GuiPlayerInventoryComponent;
	var obj : CScriptedFlashObject;

	w = GetWitcherPlayer();
	tc = new W3TooltipComponent in w;
	tc.initialize(w.inv, theGame.GetHud().GetHudFlashValueStorage());
	tc.setCurrentInventory(w.inv);
	sec = " " + GetLocStringByKeyExt("per_second");

	d = GMTestAlchTooltipText(tc, 'Beast Oil 1', st);
	GMTestReport(StrFindFirst(d, GetLocStringByKeyExt("item_desc_beast_oil_1")) >= 0 && StrFindFirst(d, GetLocStringByKeyExt("item_desc_oil")) < 0, "ALCH-16 audit F6 Beast Oil 1's own text: " + d);
	d = GMTestAlchTooltipText(tc, 'Hanged Man Venom 3', st);
	GMTestReport(GetLocStringByKeyExt("item_desc_hanged_man_venom_3") != "" && StrFindFirst(d, GetLocStringByKeyExt("item_desc_hanged_man_venom_3")) >= 0, "ALCH-16 audit F6 Hanged Man's Venom 3's own text: " + d);
	d = GMTestAlchTooltipText(tc, 'Cat 3', st);
	GMTestReport(StrFindFirst(d, GetLocStringById(2110992235)) >= 0, "ALCH-07 audit F6 Cat 3 with its hypnosis line: " + d);
	d = GMTestAlchTooltipText(tc, 'Cat 1', st);
	GMTestReport(StrFindFirst(d, GetLocStringById(2110992633)) >= 0, "ALCH-07 audit F7 Cat 1 without crit chance: " + d);
	d = GMTestAlchTooltipText(tc, 'Blizzard 1', st);
	GMTestReport(StrFindFirst(d, GetLocStringById(2110992635)) >= 0, "ALCH-07 audit F8 Blizzard 1: " + d);
	d = GMTestAlchTooltipText(tc, 'Blizzard 3', st);
	GMTestReport(StrFindFirst(d, GetLocStringById(2110992636)) >= 0, "ALCH-07 audit F8 Blizzard 3: " + d);
	d = GMTestAlchTooltipText(tc, 'Swallow 3', st);
	GMTestReport(StrFindFirst(d, GetLocStringById(2110992539)) >= 0, "ALCH-04 audit F9 Swallow 3: " + d);
	d = GMTestAlchTooltipText(tc, 'Samum 3', st);
	GMTestReport(StrFindFirst(d, GetLocStringById(2110992637)) >= 0, "ALCH-14 audit F12 Samum 3: " + d);
	GMTestReport(StrFindFirst(st, sec) >= 0, "ALCH-14 audit F11 Samum 3's cloud in seconds: " + st);
	d = GMTestAlchTooltipText(tc, 'Golden Oriole 3', st);
	GMTestReport(StrFindFirst(st, "5" + sec) >= 0, "ALCH-05 audit F11 Golden Oriole 3's immunity in seconds: " + st);
	d = GMTestAlchTooltipText(tc, 'Dwimeritium Bomb 2', st);
	GMTestReport(StrFindFirst(st, GetLocStringByKeyExt("attribute_name_cloud_duration") + " 10" + sec) >= 0 && StrFindFirst(st, "30" + sec) >= 0, "ALCH-15 audit F11 Dimeritium bomb 2's durations in seconds: " + st);
	d = GMTestAlchTooltipText(tc, 'Mutagen 1', st);
	GMTestReport(StrFindFirst(st, GetLocStringByKeyExt("attribute_name_toxicity_offset") + " 70;") >= 0 && StrFindFirst(st, "/") < 0, "ALCH-09 audit F11 a decoction's offset: " + st);
	d = GMTestAlchTooltipText(tc, 'Thunderbolt 3', st);
	GMTestReport(StrFindFirst(st, sec) >= 0, "ALCH-17 a potion's duration in seconds (5.x's): " + st);
	delete tc;
	LogChannel('GMTest', "INFO effect texts: Cat '" + GetLocStringByKeyExt("effect_CatEffect_desc") + "', Golden Oriole '" + GetLocStringByKeyExt("effect_GoldenOrioleEffect_desc") + "'");

	// The alchemy menu's list (CalculateStatsComparance): the cloud's duration in seconds.
	comp = new W3GuiPlayerInventoryComponent in thePlayer;
	comp.Initialize(thePlayer.inv);
	obj = theGame.GetHud().GetHudFlashValueStorage().CreateTempFlashObject();
	comp.GetCraftedItemInfo('Dwimeritium Bomb 2', obj);
	st = GMTestAlchFlashListText(obj.GetMemberFlashArray("attributesList"));
	GMTestReport(StrFindFirst(st, "10" + sec) >= 0, "ALCH-17 audit F11 alchemy menu, Dimeritium bomb 2: " + st);
	obj = theGame.GetHud().GetHudFlashValueStorage().CreateTempFlashObject();
	comp.GetCraftedItemInfo('Golden Oriole 3', obj);
	st = GMTestAlchFlashListText(obj.GetMemberFlashArray("attributesList"));
	GMTestReport(StrFindFirst(st, "5" + sec) >= 0, "ALCH-17 audit F11 alchemy menu, Golden Oriole 3's immunity in seconds: " + st);
	delete comp;
}

// After addalchemy3() and adddecoctions() (legacy's debug commands): the items are there.
exec function gmtest_alch18()
{
	var inv : CInventoryComponent;

	inv = thePlayer.inv;
	GMTestReport(inv.HasItem('Thunderbolt 3') && inv.HasItem('Ogre Oil 3') && inv.HasItem('Dwimeritium Bomb 3') && inv.HasItem('Grapeshot 3') && inv.HasItem('Mutagen 28') && inv.HasItem('Mutagen 1'),
		"ALCH-18 addalchemy3 and adddecoctions gave the items (Thunderbolt 3 " + inv.GetItemQuantityByName('Thunderbolt 3') + ", Grapeshot 3 " + inv.GetItemQuantityByName('Grapeshot 3') + ", Mutagen 28 " + inv.GetItemQuantityByName('Mutagen 28') + ")");
}

// The alchemy menu's item panel (W3GuiPlayerInventoryComponent.GetCraftedItemInfo, by item name): a bomb's
// and a potion's effects, a decoction's description with its values.
exec function gmtest_alch17_crafted()
{
	var comp : W3GuiPlayerInventoryComponent;
	var obj : CScriptedFlashObject;
	var a, d : string;

	comp = new W3GuiPlayerInventoryComponent in thePlayer;
	comp.Initialize(thePlayer.inv);
	obj = theGame.GetHud().GetHudFlashValueStorage().CreateTempFlashObject();
	comp.GetCraftedItemInfo('Dwimeritium Bomb 3', obj);
	a = obj.GetMemberFlashString("attributes");
	GMTestReport(StrFindFirst(a, "100") >= 0, "ALCH-17 alchemy menu, Dimeritium bomb 3: " + StrReplaceAll(a, "&#10;", " | "));
	obj = theGame.GetHud().GetHudFlashValueStorage().CreateTempFlashObject();
	comp.GetCraftedItemInfo('Golden Oriole 3', obj);
	a = obj.GetMemberFlashString("attributes");
	GMTestReport(StrFindFirst(a, "50 %") >= 0, "ALCH-17 alchemy menu, Golden Oriole 3: " + StrReplaceAll(a, "&#10;", " | "));
	obj = theGame.GetHud().GetHudFlashValueStorage().CreateTempFlashObject();
	comp.GetCraftedItemInfo('Mutagen 12', obj);
	d = obj.GetMemberFlashString("itemDescription");
	GMTestReport(StrFindFirst(d, "$") < 0 && StrFindFirst(d, "80") >= 0, "ALCH-17 alchemy menu, Troll decoction: " + StrLeft(d, 160));
	delete comp;
}
