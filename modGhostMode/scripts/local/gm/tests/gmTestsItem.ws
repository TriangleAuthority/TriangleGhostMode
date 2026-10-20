// In-game tests for ITEM (item level, random bonuses, durability and repair). See docs/features/item.md.

// ITEM's situation-free checks (in gmtest_regress()).
function GMTest_item()
{
	GMTest_item01();
	GMTest_item02();
	GMTest_item02_merchant();
	GMTest_item02_reward();
	GMTest_item04();
	GMTest_item06();
	GMTest_item08();
	GMTest_item10();
	GMTest_item11();
	GMTest_item12();
}

exec function gmtest_item()
{
	GMTest_item();
}

// Legacy's level from an item's base armor: Ceil((armor - base) / step), 1 to the maximum level.
function GMTestItemArmorLevel(category : name, armor : float) : int
{
	var base, step : float;

	if(category == 'armor')		{ base = 25; step = 5; }
	else if(category == 'gloves')	{ base = 1; step = 2; }
	else				{ base = 5; step = 2; }
	return Clamp(CeilF((armor - base) / step), 1, GetWitcherPlayer().GetMaxLevel());
}

// The level of a new copy of an item (CInventoryComponent.GetItemLevel); the copy is removed.
function GMTestItemHeldLevel(itemName : name) : int
{
	var inv : CInventoryComponent;
	var ids : array<SItemUniqueId>;
	var level : int;

	inv = thePlayer.GetInventory();
	ids = inv.AddAnItem(itemName, 1, true, true, false);
	level = inv.GetItemLevel(ids[0]);
	inv.RemoveItem(ids[0], 1);
	return level;
}

// The held level of a fixed-armor piece against legacy's formula, read from its base armor.
function GMTestItemArmorCheck(itemName : name) : bool
{
	var inv : CInventoryComponent;
	var ids : array<SItemUniqueId>;
	var armor : SAbilityAttributeValue;
	var level, expected : int;

	inv = thePlayer.GetInventory();
	ids = inv.AddAnItem(itemName, 1, true, true, false);
	armor = inv.GetItemAttributeValue(ids[0], 'armor');
	level = inv.GetItemLevel(ids[0]);
	expected = GMTestItemArmorLevel(inv.GetItemCategory(ids[0]), armor.valueBase);
	inv.RemoveItem(ids[0], 1);
	GMTestReport(level == expected, "ITEM-01 " + itemName + ": base armor " + armor.valueBase + ", level " + level + " (expected " + expected + ", Ceil((armor - base) / step), no quality adjustment)");
	return level == expected;
}

// ITEM-01: item level from stats, legacy's formula; bolts by legacy's list (DI1).
function GMTest_item01()
{
	var dm : CDefinitionsManagerAccessor;
	var pl : int;

	dm = theGame.GetDefinitionsManager();
	pl = thePlayer.GetLevel();

	GMTestReport(dm.GetItemLevelFromName('Short sword 1_crafted') == 1 && GMTestItemHeldLevel('Short sword 1_crafted') == 1,
		"ITEM-01 crafted Short sword (33 slashing): level by name " + dm.GetItemLevelFromName('Short sword 1_crafted') + ", held " + GMTestItemHeldLevel('Short sword 1_crafted') + " (1; 5.x 2)");
	GMTestReport(dm.GetItemLevelFromName('Silver sword 1_crafted') == 1,
		"ITEM-01 crafted silver sword 1 (100 silver): level " + dm.GetItemLevelFromName('Silver sword 1_crafted') + " (1)");
	GMTestReport(dm.GetItemLevelFromName('Gryphon School steel sword 4') == 40 && GMTestItemHeldLevel('Gryphon School steel sword 4') == 40,
		"ITEM-01 grandmaster Griffin steel sword (345, witcher gear): by name " + dm.GetItemLevelFromName('Gryphon School steel sword 4') + ", held " + GMTestItemHeldLevel('Gryphon School steel sword 4') + " (40; 5.x 37)");
	GMTestReport(dm.GetItemLevelFromName('Gryphon School silver sword 4') == 40,
		"ITEM-01 grandmaster Griffin silver sword (490): level " + dm.GetItemLevelFromName('Gryphon School silver sword 4') + " (40)");
	GMTestReport(dm.GetItemLevelFromName('Gryphon Pants 4') == 34 && GMTestItemHeldLevel('Gryphon Pants 4') == 34,
		"ITEM-01 grandmaster Griffin trousers (73 armor, witcher gear): by name " + dm.GetItemLevelFromName('Gryphon Pants 4') + ", held " + GMTestItemHeldLevel('Gryphon Pants 4') + " (34; 5.x 32)");
	GMTestItemArmorCheck('Gryphon Armor 4');
	GMTestItemArmorCheck('Gryphon Gloves 4');
	GMTestItemArmorCheck('Gryphon Boots 4');
	GMTestItemArmorCheck('Heavy armor 01_crafted');
	GMTestItemArmorCheck('Bear Armor 1');

	// Bolts: legacy's list (no -1, Blunt Bolt Legendary 12), held and by name (DI1: 5.x's bolt rule removed).
	GMTestItemBolts();
}

// ITEM-01, DI1: every bolt's level held (a new copy: the inventory, the equip check and the crossbow
// quick menu, which lists a bolt only up to Geralt's level) and by name (the crafting menu and schematic
// tooltips) is legacy's list.
function GMTestItemBolts()
{
	var dm : CDefinitionsManagerAccessor;
	var bolts : array<name>;
	var want : array<int>;
	var i, held, byName, pl : int;
	var ok : bool;
	var log, menu : string;

	dm = theGame.GetDefinitionsManager();
	pl = thePlayer.GetLevel();
	bolts.PushBack('Tracking Bolt');		want.PushBack(2);
	bolts.PushBack('Bait Bolt');			want.PushBack(2);
	bolts.PushBack('Blunt Bolt');			want.PushBack(2);
	bolts.PushBack('Target Point Bolt');		want.PushBack(5);
	bolts.PushBack('Broadhead Bolt');		want.PushBack(10);
	bolts.PushBack('Split Bolt');			want.PushBack(15);
	bolts.PushBack('Explosive Bolt');		want.PushBack(20);
	bolts.PushBack('Blunt Bolt Legendary');		want.PushBack(12);
	bolts.PushBack('Target Point Bolt Legendary');	want.PushBack(15);
	bolts.PushBack('Broadhead Bolt Legendary');	want.PushBack(20);
	bolts.PushBack('Split Bolt Legendary');		want.PushBack(24);
	bolts.PushBack('Explosive Bolt Legendary');	want.PushBack(26);
	ok = true;
	for(i = 0; i < bolts.Size(); i += 1)
	{
		held = GMTestItemHeldLevel(bolts[i]);
		byName = dm.GetItemLevelFromName(bolts[i]);
		if(held != want[i] || byName != want[i])
			ok = false;
		log += " " + bolts[i] + " " + held + "/" + byName + " (" + want[i] + ")";
		if(held <= pl)
			menu += " " + bolts[i];
	}
	GMTestReport(ok, "ITEM-01 bolt levels, held/by name (legacy's):" + log);
	LogChannel('GMTest', "INFO ITEM-01 bolts the crossbow quick menu lists at Geralt's level " + pl + " (level up to his):" + menu);
}

// The number of per-level abilities (autogen_*_dmg, autogen_*_armor) of an item: its generated level.
function GMTestItemGenLevel(inv : CInventoryComponent, id : SItemUniqueId) : int
{
	var abls : array<name>;
	var i, n : int;
	var s : string;

	inv.GetItemAbilities(id, abls);
	for(i = 0; i < abls.Size(); i += 1)
	{
		s = NameToString(abls[i]);
		if(StrBeginsWith(s, "autogen_") && (StrEndsWith(s, "_dmg") || StrEndsWith(s, "_armor")))
			n += 1;
	}
	return n;
}

// Adds `count` copies of a level-scaled item (found: Geralt's inventory), checks each generated level
// lies in lo...hi, removes them.
function GMTestItemGenRange(itemName : name, count : int, lo : int, hi : int, what : string)
{
	var inv : CInventoryComponent;
	var ids : array<SItemUniqueId>;
	var i, lvl, mn, mx : int;
	var ok : bool;

	inv = thePlayer.GetInventory();
	ok = true;
	mn = 1000;
	mx = -1;
	for(i = 0; i < count; i += 1)
	{
		ids = inv.AddAnItem(itemName, 1, true, true, false);
		lvl = GMTestItemGenLevel(inv, ids[0]);
		if(lvl < lo || lvl > hi)
			ok = false;
		mn = Min(mn, lvl);
		mx = Max(mx, lvl);
		inv.RemoveItem(ids[0], 1);
	}
	GMTestReport(ok, "ITEM-02 " + itemName + " (" + what + "): generated levels " + mn + " to " + mx + " in " + count + " copies (expected " + lo + " to " + hi + ")");
}

// ITEM-02, ITEM-03: the level a level-scaled item gets when found; the tags and ranges legacy changed.
function GMTest_item02()
{
	var inv : CInventoryComponent;
	var ids : array<SItemUniqueId>;
	var pl, lo, hi, ilMin, ilMax : int;
	var dm : CDefinitionsManagerAccessor;
	var min, max : SAbilityAttributeValue;

	inv = thePlayer.GetInventory();
	dm = theGame.GetDefinitionsManager();
	pl = thePlayer.GetLevel();
	GMTestReport(!GMTestArmTag('Guard Lvl1 Armor 1', 'AutogenUseLevelRange') && !GMTestArmTag('Guard Lvl1 Boots 2', 'EP1') && !GMTestArmTag('q704_vampire_armor', 'AutogenForceLevel')
		&& !GMTestArmTag('Toussaint Armor 3', 'AutogenForceLevel') && GMTestArmTag('Laundry stick', 'AutogenForceLevel') && GMTestArmTag('Toussaint Armor 3', 'AutogenUseLevelRange'),
		"ITEM-03 level tags: no level range on Blood and Wine's guard armor, no EP1 on its boots, no forced level on the second vampire armor and Toussaint armor 3, a forced level on the laundry stick; Toussaint armor 3 keeps its range");
	dm.GetItemAttributeValueNoRandom('Toussaint Armor 3', false, 'item_level_min', min, max);
	ilMin = RoundMath(CalculateAttributeValue(min));
	dm.GetItemAttributeValueNoRandom('Toussaint Armor 3', false, 'item_level_max', min, max);
	ilMax = RoundMath(CalculateAttributeValue(min));
	LogChannel('GMTest', "INFO Toussaint Armor 3's range " + ilMin + " to " + ilMax + "; Geralt's level " + pl);

	GMTestItemGenRange('Guard Lvl1 Armor 1', 8, Max(1, pl - 1), pl, "quality 2, found: Geralt's level -1 to 0");
	GMTestItemGenRange('Guard Lvl1 Armor 2', 8, Max(1, pl - 1), pl + 1, "quality 3, found: -1 to +1");
	GMTestItemGenRange('mq1058_cat_school_sword', 4, pl, pl, "witcher gear, found: exactly Geralt's level");
	lo = Clamp(pl - 1, ilMin, ilMax);
	hi = Clamp(pl + 1, ilMin, ilMax);
	GMTestItemGenRange('Toussaint Armor 3', 6, lo, hi, "level range " + ilMin + " to " + ilMax + ": -1 to +1 clamped to it");
	ids = inv.AddAnItem('Guard Lvl1 Armor 2', 1, true, true, false);
	LogChannel('GMTest', "INFO a level-scaled item's level is generated within AddAnItem: " + (GMTestItemGenLevel(inv, ids[0]) > 0) + "; GetItemLevel " + inv.GetItemLevel(ids[0]) + ", generated " + GMTestItemGenLevel(inv, ids[0]));
	inv.RemoveItem(ids[0], 1);
}

exec function gmtest_item02()
{
	GMTest_item02();
}

// A found item's generated level range by its quality (ITEM-02): -1...+1 (3 and 4), -1...0 (1 and 2),
// exactly Geralt's (witcher gear).
function GMTestItemFoundRange(quality : int, out lo : int, out hi : int)
{
	var pl : int;

	pl = thePlayer.GetLevel();
	if(quality >= 5)		{ lo = pl; hi = pl; }
	else if(quality >= 3)		{ lo = pl - 1; hi = pl + 1; }
	else				{ lo = pl - 1; hi = pl; }
	lo = Clamp(lo, 1, GetWitcherPlayer().GetMaxLevel());
	hi = Clamp(hi, 1, GetWitcherPlayer().GetMaxLevel());
}

// A generic weapon merchant 3 m in front of Geralt (W3MerchantNPC), or NULL.
function GMTestItemSpawnMerchant() : W3MerchantNPC
{
	var template : CEntityTemplate;

	template = (CEntityTemplate)LoadResource("living_world\dialogue\generic_merchants\entities\shop_generic_merchant_novigrad_weapons.w2ent", true);
	if(!template)
		return NULL;
	return (W3MerchantNPC)theGame.CreateEntity(template, thePlayer.GetWorldPosition() + thePlayer.GetHeadingVector() * 3, thePlayer.GetWorldRotation());
}

// ITEM-02: a merchant's stock gets Geralt's level -1...+2; its restock clearing (GMClearLowLevelWeapons)
// removes the weapons more than 3 levels below Geralt and never a bolt (bolts carry WeaponTab, not the
// Weapon tag GetAllWeapons selects: audit F4). Removal needs Geralt at level 5 or more to be exercised
// (run it again after setlevel(20): gmtest_item02_merchant()).
function GMTest_item02_merchant()
{
	var m : W3MerchantNPC;
	var inv : CInventoryComponent;
	var ids, weapons : array<SItemUniqueId>;
	var i, lvl, pl, lo, hi, mn, mx, removedLow, keptLow, keptHigh, bolts, boltsAfter : int;
	var ok : bool;
	var lowNames : array<name>;
	var note : string;

	m = GMTestItemSpawnMerchant();
	GMTestReport(m && m.GetInventory(), "ITEM-02 merchant spawned (generic Novigrad weaponsmith)");
	if(!m || !m.GetInventory())
		return;
	inv = m.GetInventory();
	pl = thePlayer.GetLevel();
	lo = Max(1, pl - 1);
	hi = Min(pl + 2, GetWitcherPlayer().GetMaxLevel());
	ok = true;
	mn = 1000;
	mx = -1;
	for(i = 0; i < 12; i += 1)
	{
		ids = inv.AddAnItem('Guard Lvl1 Armor 2', 1, true, true, false);
		lvl = GMTestItemGenLevel(inv, ids[0]);
		if(lvl < lo || lvl > hi)
			ok = false;
		mn = Min(mn, lvl);
		mx = Max(mx, lvl);
		inv.RemoveItem(ids[0], 1);
	}
	GMTestReport(ok, "ITEM-02 a merchant's stock: generated levels " + mn + " to " + mx + " in 12 copies (expected " + lo + " to " + hi + ", Geralt's level -1 to +2)");

	inv.AddAnItem('Tracking Bolt', 5, true, true, false);
	inv.AddAnItem('Explosive Bolt', 5, true, true, false);
	inv.AddAnItem('Short sword 1_crafted', 1, true, true, false);
	inv.AddAnItem('Bear School steel sword 4', 1, true, true, false);
	bolts = inv.GetItemQuantityByName('Tracking Bolt') + inv.GetItemQuantityByName('Explosive Bolt');
	weapons = inv.GetAllWeapons();
	for(i = 0; i < weapons.Size(); i += 1)
		if(pl - inv.GetItemLevel(weapons[i]) > 3)
			lowNames.PushBack(inv.GetItemName(weapons[i]));
	inv.GMClearLowLevelWeapons();
	weapons = inv.GetAllWeapons();
	for(i = 0; i < weapons.Size(); i += 1)
	{
		if(pl - inv.GetItemLevel(weapons[i]) > 3)
			keptLow += 1;
		else
			keptHigh += 1;
	}
	for(i = 0; i < lowNames.Size(); i += 1)
		if(!inv.HasItem(lowNames[i]))
			removedLow += 1;
	boltsAfter = inv.GetItemQuantityByName('Tracking Bolt') + inv.GetItemQuantityByName('Explosive Bolt');
	if(pl < 5)
		note = "; removal not exercised below level 5";
	GMTestReport(keptLow == 0 && keptHigh > 0 && boltsAfter == bolts && !inv.ItemHasTag(inv.GetItemId('Tracking Bolt'), 'Weapon'),
		"ITEM-02 restock clearing at Geralt's level " + pl + ": " + lowNames.Size() + " weapons more than 3 levels below him before, " + keptLow + " after (" + removedLow + " names gone), " + keptHigh + " weapons kept; bolts " + bolts + " -> "
		+ boltsAfter + " (never removed: no Weapon tag)" + note);
	m.Destroy();
}

exec function gmtest_item02_merchant()
{
	GMTest_item02_merchant();
}

@addMethod(W3MerchantNPC)
function GMTestSetLastDay(day : int)
{
	lastDayOfInteraction = day;
}

@addField(CR4Player)
var gmTestItemMerchant : CEntity;

// ITEM-02: a merchant restocking when Geralt talks to it (OnInteraction "Talk" with its funds due, the
// last interaction moved 100 days back) drops its weapons more than 3 levels below Geralt (needs Geralt
// at level 5 or more: setlevel(20) first) and keeps its bolts. Starts the merchant's talk: run
// gmtest_item02_restock_end() afterwards, which reports and removes the merchant.
exec function gmtest_item02_restock()
{
	var m : W3MerchantNPC;
	var inv : CInventoryComponent;
	var w : W3PlayerWitcher;

	w = GetWitcherPlayer();
	m = GMTestItemSpawnMerchant();
	GMTestReport(m && m.GetInventory(), "ITEM-02 merchant spawned for the restock");
	if(!m)
		return;
	inv = m.GetInventory();
	inv.AddAnItem('Short sword 1_crafted', 1, true, true, false);
	inv.AddAnItem('Tracking Bolt', 5, true, true, false);
	LogChannel('GMTest', "INFO ITEM-02 restock: before, the crafted Short sword held " + inv.HasItem('Short sword 1_crafted') + " (level " + inv.GetItemLevel(inv.GetItemId('Short sword 1_crafted')) + "), Tracking bolts " + inv.GetItemQuantityByName('Tracking Bolt') + ", Geralt's level " + thePlayer.GetLevel());
	m.GMTestSetLastDay(GameTimeDays(theGame.GetGameTime()) - 100);
	w.gmTestItemMerchant = m;
	m.OnInteraction("Talk", thePlayer);
}

exec function gmtest_item02_restock_end()
{
	var m : W3MerchantNPC;
	var inv : CInventoryComponent;
	var low : bool;
	var w : W3PlayerWitcher;

	w = GetWitcherPlayer();
	m = (W3MerchantNPC)w.gmTestItemMerchant;
	if(!m)
	{
		GMTestReport(false, "ITEM-02 restock: run gmtest_item02_restock() first");
		return;
	}
	inv = m.GetInventory();
	low = thePlayer.GetLevel() - 1 > 3;
	GMTestReport(inv.HasItem('Short sword 1_crafted') != low && inv.GetItemQuantityByName('Tracking Bolt') == 5,
		"ITEM-02 restock on talking: the crafted Short sword (level 1) held " + inv.HasItem('Short sword 1_crafted') + " at Geralt's level " + thePlayer.GetLevel() + " (removed when more than 3 below), Tracking bolts " + inv.GetItemQuantityByName('Tracking Bolt') + " (5, kept)");
	m.StopAllScenes();
	thePlayer.StopAllScenes();
	m.Destroy();
	w.gmTestItemMerchant = NULL;
}

// ITEM-02, audit F3: a quest reward (theGame.GiveReward: sq108_special_armor, Yoana's level-scaled
// armor) gets the found-item level, since AddAnItem generates it before the reward code's
// GenerateItemLevel(id, true), which then adds nothing: DI2's "exactly Geralt's level" stays inert,
// as in legacy (accepted by the owner, 2026-10-20). The armor is removed afterwards.
function GMTest_item02_reward()
{
	var inv : CInventoryComponent;
	var before, after : array<SItemUniqueId>;
	var id : SItemUniqueId;
	var i, gen, lo, hi, q, gen2 : int;

	inv = thePlayer.GetInventory();
	before = inv.GetItemsByName('q108 Medium armor 10');
	theGame.GiveReward('sq108_special_armor', thePlayer);
	after = inv.GetItemsByName('q108 Medium armor 10');
	for(i = 0; i < after.Size(); i += 1)
		if(!before.Contains(after[i]))
			id = after[i];
	if(!inv.IsIdValid(id))
	{
		GMTestReport(false, "ITEM-02 reward: sq108_special_armor gave no new armor");
		return;
	}
	gen = GMTestItemGenLevel(inv, id);
	q = RoundMath(CalculateAttributeValue(inv.GetItemAttributeValue(id, 'quality')));
	GMTestItemFoundRange(q, lo, hi);
	inv.GenerateItemLevel(id, true);
	gen2 = GMTestItemGenLevel(inv, id);
	GMTestReport(gen >= lo && gen <= hi && gen2 == gen,
		"ITEM-02 a quest reward (Yoana's armor, quality " + q + "): generated level " + gen + " (found-item rule " + lo + " to " + hi + "; Geralt's level " + thePlayer.GetLevel() + "); the reward's GenerateItemLevel(id, true) adds nothing (" + gen + " -> " + gen2 + "): DI2 inert, as legacy");
	inv.RemoveItem(id, 1);
}

exec function gmtest_item02_reward()
{
	GMTest_item02_reward();
}

// A new copy's generated level and the level read from its stats (GetItemLevel); the copy is removed.
function GMTestItemNewLevels(itemName : name, out genLevel : int, out statLevel : int)
{
	var inv : CInventoryComponent;
	var ids : array<SItemUniqueId>;

	inv = thePlayer.GetInventory();
	ids = inv.AddAnItem(itemName, 1, true, true, false);
	genLevel = GMTestItemGenLevel(inv, ids[0]);
	statLevel = inv.GetItemLevel(ids[0]);
	inv.RemoveItem(ids[0], 1);
}

// ITEM-04, ITEM-05: items moved to level scaling and the standalone starting gear.
function GMTest_item04()
{
	var pl, g, l, g2, l2, g3, l3 : int;

	pl = thePlayer.GetLevel();
	GMTestReport(GMTestArmTag('Olgierd Sabre', 'Autogen') && GMTestArmTag('Ofir Armor', 'Autogen') && GMTestArmTag('q702_vampire_armor', 'Autogen') && GMTestArmTag('q702 vampire steel sword', 'Autogen')
		&& GMTestArmTag('Nekker Boots', 'Autogen') && GMTestArmTag('q108 Medium armor 10', 'Autogen') && GMTestArmTag('Ofir Sabre 2', 'Autogen') && GMTestArmTag('Damien sword', 'Autogen'),
		"ITEM-04 level-scaled (Autogen): Iris, Ofir armor, the first vampire armor and steel sword, the Nekker boots, Yoana's armor, Ofir Sabre 2, Damien's sword");
	GMTestReport(GMTestSwdAbl('PC Olgierd Sabre _Stats', 'SlashingDamage') == 0 && GMTestSwdAbl('Ofir Armor _Stats', 'armor') == 0 && GMTestSwdAbl('q702 vampire steel sword _Stats', 'SlashingDamage') == 0
		&& GMTestSwdAbl('q702_vampire_armor _Stats', 'armor') == 0 && GMTestSwdAbl('Ofir Sabre 2 _Stats', 'SlashingDamage') == 0 && GMTestSwdAbl('q108 Medium armor 10 _Stats', 'armor') == 0,
		"ITEM-04 fixed values removed: Iris slashing " + GMTestSwdAbl('PC Olgierd Sabre _Stats', 'SlashingDamage') + " (5.x 363), Ofir armor " + GMTestSwdAbl('Ofir Armor _Stats', 'armor') + " (200), first vampire sword " + GMTestSwdAbl('q702 vampire steel sword _Stats', 'SlashingDamage') + " (356), its armor " + GMTestSwdAbl('q702_vampire_armor _Stats', 'armor') + " (230), Ofir Sabre 2 " + GMTestSwdAbl('Ofir Sabre 2 _Stats', 'SlashingDamage') + ", Yoana's armor " + GMTestSwdAbl('q108 Medium armor 10 _Stats', 'armor'));
	GMTestReport(GMTestArmTag('EP1 Standalone Starting Armor', 'Autogen') && GMTestArmTag('EP1 Standalone Starting Armor', 'AutogenForceLevel') && GMTestArmTag('EP2 Standalone Starting Steel Sword', 'AutogenForceLevel')
		&& GMTestSwdAbl('EP1 Standalone Starting Armor _Stats', 'armor') == 0 && GMTestSwdAbl('EP2 Standalone Starting Pants _Stats', 'armor') == 0 && GMTestSwdAbl('EP2 Standalone Starting Silver Sword _Stats', 'SilverDamage') == 0
		&& GMTestSwdAbl('EP2 Standalone Starting Armor _Stats', 'quality') == 3,
		"ITEM-05 standalone gear level-scaled at Geralt's level: tags, fixed armor and damage removed, the Blood and Wine armor quality " + GMTestSwdAbl('EP2 Standalone Starting Armor _Stats', 'quality') + " (3)");
	GMTestItemNewLevels('Olgierd Sabre', g, l);
	GMTestReport(g >= Max(1, pl - 1) && g <= pl + 1 && l == g, "ITEM-04 a new Iris: generated level " + g + ", level from its damage " + l + " (Geralt's " + pl + ")");
	GMTestItemNewLevels('Ofir Armor', g2, l2);
	GMTestReport(g2 >= Max(1, pl - 1) && g2 <= pl + 1 && l2 == g2, "ITEM-04 a new Ofir armor: generated level " + g2 + ", level from its armor " + l2);
	GMTestItemNewLevels('EP2 Standalone Starting Armor', g3, l3);
	GMTestReport(g3 == pl && l3 == pl, "ITEM-05 a new Blood and Wine standalone armor: generated level " + g3 + ", level from its armor " + l3 + " (exactly Geralt's " + pl + ")");
}

exec function gmtest_item04()
{
	GMTest_item04();
}

// Adds `count` copies of an item and checks each one's random bonuses (MA_ abilities, repeats counted)
// against legacy's rule for its quality and level: common, masterwork and magical bonuses, `perLevel`
// of them repeated at levels 10, 20 and 30; and the quality ability (quality_*) when `qualityAbl`. The
// level is legacy's: the generated one for a level-scaled item, else the level from its stats; for
// swords and armor (`sameLevel`) the two must agree.
function GMTestItemBonuses(itemName : name, count : int, fixed : int, perLevel : int, qualityAbl : bool, what : string)
{
	GMTestItemBonusesLv(itemName, count, fixed, perLevel, qualityAbl, what, true);
}

function GMTestItemBonusesLv(itemName : name, count : int, fixed : int, perLevel : int, qualityAbl : bool, what : string, sameLevel : bool)
{
	var inv : CInventoryComponent;
	var ids : array<SItemUniqueId>;
	var abls : array<name>;
	var i, j, n, lvl, gen, stat, reps, want : int;
	var hasQ, ok : bool;
	var s, log, levels : string;

	inv = thePlayer.GetInventory();
	ok = true;
	for(i = 0; i < count; i += 1)
	{
		ids = inv.AddAnItem(itemName, 1, true, true, false);
		gen = GMTestItemGenLevel(inv, ids[0]);
		stat = inv.GetItemLevel(ids[0]);
		lvl = stat;
		if(gen > 0)
			lvl = gen;
		if(sameLevel && gen > 0 && gen != stat)
			ok = false;
		reps = 1;
		if(lvl >= 10) reps += 1;
		if(lvl >= 20) reps += 1;
		if(lvl >= 30) reps += 1;
		want = fixed + perLevel * reps;
		abls.Clear();
		inv.GetItemAbilities(ids[0], abls);
		n = 0;
		hasQ = false;
		for(j = 0; j < abls.Size(); j += 1)
		{
			s = NameToString(abls[j]);
			if(StrBeginsWith(s, "MA_"))
				n += 1;
			if(StrBeginsWith(s, "quality_"))
				hasQ = true;
		}
		if(n != want || hasQ != qualityAbl)
			ok = false;
		if(i == 0)
			log = "level " + lvl + ": " + n + " bonuses (expected " + want + "), quality ability " + hasQ;
		levels += " " + gen + "/" + stat + ":" + n;
		inv.RemoveItem(ids[0], 1);
	}
	GMTestReport(ok, "ITEM-06 " + itemName + " (" + what + "), " + count + " copies; first " + log + "; generated/from stats:bonuses" + levels);
}

// ITEM-06, ITEM-07: random bonus rules and values (legacy's).
function GMTest_item06()
{
	var i, g, l : int;
	var ok : bool;
	var a : name;

	ok = true;
	for(i = 0; i < 20; i += 1)
	{
		a = theGame.params.GMGetRandomCommonArmorAbility();
		if(a != 'MA_SlashingResistance' && a != 'MA_PiercingResistance' && a != 'MA_BludgeoningResistance' && a != 'MA_RendingResistance' && a != 'MA_ElementalResistance')
			ok = false;
		a = theGame.params.GMGetRandomCommonWeaponAbility();
		if(a != 'MA_ArmorPenetration' && a != 'MA_ArmorPenetrationPerc' && a != 'MA_AttackPowerMult' && a != 'MA_CriticalChance' && a != 'MA_CriticalDamage' && a != 'MA_AdrenalineGain')
			ok = false;
	}
	GMTestReport(ok, "ITEM-06 common bonus lists: armor resistances, weapon armor penetration, attack power, crits, adrenaline (20 draws each)");
	GMTestReport(GMTestSwdAbl('MA_CriticalChance', 'critical_hit_chance') == 0.05 && GMTestSwdAbl('MA_Vitality', 'vitality') == 200 && GMTestSwdAbl('MA_AttackPowerAdd', 'attack_power') == 0
		&& GMTestSwdAbl('MA_SlashingResistance', 'slashing_resistance_perc') == 0.03 && GMTestSwdAbl('MA_ArmorPenetrationPerc', 'armor_reduction_perc') == 0.03 && GMTestSwdAbl('MA_StaminaRegeneration', 'staminaRegen') == 0,
		"ITEM-07 bonus values (minimums): crit chance " + GMTestSwdAbl('MA_CriticalChance', 'critical_hit_chance') + " (0.05), Vitality " + GMTestSwdAbl('MA_Vitality', 'vitality') + " (200), flat attack power " + GMTestSwdAbl('MA_AttackPowerAdd', 'attack_power')
		+ " (0), slashing resistance " + GMTestSwdAbl('MA_SlashingResistance', 'slashing_resistance_perc') + " (0.03), resistance reduction " + GMTestSwdAbl('MA_ArmorPenetrationPerc', 'armor_reduction_perc') + " (0.03, new), stamina regen " + GMTestSwdAbl('MA_StaminaRegeneration', 'staminaRegen') + " (0)");
	GMTestItemBonuses('Light armor 01', 4, 1, 0, true, "chest armor, quality 1: one common");
	GMTestItemBonuses('Guard Lvl1 Armor 2', 4, 1, 2, true, "chest armor, quality 3: one common, masterwork and magical per 10 levels");
	GMTestItemBonuses('Guard Lvl1 Armor 3', 4, 1, 0, true, "chest armor, quality 4 (relic): one common");
	GMTestItemBonuses('Gryphon Armor 4', 2, 0, 0, false, "witcher gear: none");
	GMTestItemBonuses('Guard Lvl1 Gloves 2', 4, 2, 0, true, "gloves, quality 3: one masterwork and one magical");
	GMTestItemBonuses('Laundry stick', 4, 0, 1, true, "sword, quality 1: one common per 10 levels");
	GMTestItemBonuses('Guard Lvl1 steel sword 1', 4, 0, 2, true, "sword, quality 2: common and masterwork per 10 levels");
	GMTestItemBonuses('Guard Lvl1 steel sword 2', 4, 0, 3, true, "sword, quality 3: common, masterwork and magical per 10 levels");
	// Audit F2 (the owner's decision, 2026-10-20): a level-scaled secondary weapon's bonuses follow the
	// level it was given, as legacy (its fixed base damage reads 1 to 3 levels above it).
	GMTestItemNewLevels('W_Axe01', g, l);
	LogChannel('GMTest', "INFO ITEM-06 a new W_Axe01: generated level " + g + ", level from its damage " + l);
	GMTestItemBonusesLv('W_Axe01', 6, 0, 1, true, "secondary weapon (axe), quality 1: one common per 10 levels of the level it was given", false);
}

exec function gmtest_item06()
{
	GMTest_item06();
}

// Audit F2 at a chosen Geralt's level (setlevel(N) first; levels just below and at a 10-level step,
// e.g. 19, 20, 29, 30): `count` new W_Axe01 (quality 1, found: generated at Geralt's level -1 to 0) roll
// one common bonus per 10 levels of the generated level, not of the level from their damage; swords
// and armor unchanged (their two levels agree).
exec function gmtest_item06_axe(optional count : int)
{
	if(count <= 0)
		count = 10;
	LogChannel('GMTest', "INFO ITEM-06 at Geralt's level " + thePlayer.GetLevel());
	GMTestItemBonusesLv('W_Axe01', count, 0, 1, true, "axe, quality 1: one common per 10 levels of the level it was given", false);
	GMTestItemBonusesLv('W_Mace01', count, 0, 1, true, "mace: as the axe", false);
	GMTestItemBonuses('Guard Lvl1 steel sword 2', 4, 0, 3, true, "sword, quality 3: common, masterwork and magical per 10 levels");
	GMTestItemBonuses('Laundry stick', 4, 0, 1, true, "sword, quality 1: one common per 10 levels");
	GMTestItemBonuses('Guard Lvl1 Armor 2', 4, 1, 2, true, "chest armor, quality 3: one common, masterwork and magical per 10 levels");
}

// ITEM-08, ITEM-09: DoNotEnhance removed where legacy removed it; armor quality by tier.
function GMTest_item08()
{
	GMTestReport(!GMTestArmTag('Guard Lvl1 Boots 1', 'DoNotEnhance') && !GMTestArmTag('Ofir Armor', 'DoNotEnhance') && !GMTestArmTag('Knight Geralt Pants 1', 'DoNotEnhance')
		&& !GMTestArmTag('sq701_geralt_gloves', 'DoNotEnhancem') && GMTestArmTag('Heavy armor 01_crafted', 'DoNotEnhance'),
		"ITEM-08 no DoNotEnhance on Blood and Wine's guard and knight gear and Ofir armor, nor 1.32's misspelt tag on the tournament gloves; crafted armor keeps legacy's (ARM-01)");
	GMTestItemBonuses('Guard Lvl1 Armor 1', 4, 1, 1, true, "Blood and Wine guard armor, quality 2, DoNotEnhance removed: one common and one masterwork");
	GMTestReport(GMTestSwdAbl('Heavy armor 01_crafted _Stats', 'quality') == 1 && GMTestSwdAbl('Boots 02_crafted _Stats', 'quality') == 2 && GMTestSwdAbl('Boots 04_crafted _Stats', 'quality') == 4
		&& GMTestSwdAbl('Heavy armor 02 _Stats', 'quality') == 2 && GMTestSwdAbl('Geralt_kontusz _Stats', 'quality') == 1,
		"ITEM-09 armor quality: crafted heavy armor 1 " + GMTestSwdAbl('Heavy armor 01_crafted _Stats', 'quality') + " (1; 5.x 3), crafted boots 2 " + GMTestSwdAbl('Boots 02_crafted _Stats', 'quality') + " (2), crafted boots 4 " + GMTestSwdAbl('Boots 04_crafted _Stats', 'quality')
		+ " (4), loot heavy armor 2 " + GMTestSwdAbl('Heavy armor 02 _Stats', 'quality') + " (2; 5.x 1 to 3), the Kontusz " + GMTestSwdAbl('Geralt_kontusz _Stats', 'quality') + " (1; 5.x 2)");
}

exec function gmtest_item08()
{
	GMTest_item08();
}

// ITEM-10: durability penalty, wear and the damaged threshold (legacy's). The armor check equips a
// new piece at half durability and compares its armor with a full one (restored after).
function GMTest_item10()
{
	var p : W3GameParams;
	var d : EDifficultyMode;
	var cap, want, full, half : float;
	var inv : CInventoryComponent;
	var ids : array<SItemUniqueId>;
	var sword : SItemUniqueId;
	var dur : float;

	p = theGame.params;
	d = theGame.GetDifficultyMode();
	if(d == EDM_Easy)		{ cap = 0.8; want = 0.875; }
	else if(d == EDM_Medium)	{ cap = 0.7; want = 0.875; }
	else if(d == EDM_Hard)		{ cap = 0.6; want = 0.75; }
	else				{ cap = 0.5; want = 0.75; }
	GMTestReport(GMTestSwdNear(p.GetDurabilityMultiplier(0.5, true), want) && GMTestSwdNear(p.GetDurabilityMultiplier(0.5, false), want) && GMTestSwdNear(p.GetDurabilityMultiplier(0, true), cap) && GMTestSwdNear(p.GetDurabilityMultiplier(1, false), 1),
		"ITEM-10 durability penalty (difficulty " + d + "): at half durability " + p.GetDurabilityMultiplier(0.5, true) + " (" + want + "), at 0 " + p.GetDurabilityMultiplier(0, true) + " (" + cap + "), full 1");
	GMTestReport(p.ITEM_DAMAGED_DURABILITY == 75 && GMTestSwdNear(p.DURABILITY_ARMOR_LOSE_VALUE, 0.5) && GMTestSwdNear(p.GetWeaponDurabilityLoseValue(), 0.05),
		"ITEM-10 damaged below " + p.ITEM_DAMAGED_DURABILITY + "% (75), armor wear " + p.DURABILITY_ARMOR_LOSE_VALUE + " (0.5), weapon wear " + p.GetWeaponDurabilityLoseValue() + " (0.05) per hit");
	inv = thePlayer.GetInventory();
	if(GetWitcherPlayer().GetItemEquippedOnSlot(EES_SteelSword, sword))
	{
		dur = inv.GetItemDurability(sword);
		inv.SetItemDurabilityScript(sword, inv.GetItemMaxDurability(sword));
		full = GetWitcherPlayer().GetTotalWeaponDamage(sword, 'SlashingDamage', GetInvalidUniqueId());
		inv.SetItemDurabilityScript(sword, inv.GetItemMaxDurability(sword) * 0.5);
		half = GetWitcherPlayer().GetTotalWeaponDamage(sword, 'SlashingDamage', GetInvalidUniqueId());
		inv.SetItemDurabilityScript(sword, dur);
		GMTestReport(GMTestSwdNear(half / full, want), "ITEM-10 Geralt's steel sword at half durability: damage " + half + " of " + full + " (x" + want + ")");
	}
	GMTestReport(GMTestDurStart('Beauclair Prison Pants') && GMTestDurStart('Beauclair Casual Pants 01'), "ITEM-10 the two Beauclair trousers start at full durability");
}

function GMTestDurStart(itemName : name) : bool
{
	var inv : CInventoryComponent;
	var ids : array<SItemUniqueId>;
	var r : float;

	inv = thePlayer.GetInventory();
	ids = inv.AddAnItem(itemName, 1, true, true, false);
	r = inv.GetItemDurabilityRatio(ids[0]);
	inv.RemoveItem(ids[0], 1);
	LogChannel('GMTest', "INFO " + itemName + " durability ratio " + r);
	return r > 0.99;
}

exec function gmtest_item10()
{
	GMTest_item10();
}

// ITEM-11: repair kits and the master kits, through W3PlayerWitcher.RepairItem (what using a kit on an
// item calls) on a new level-scaled sword and armor piece.
function GMTest_item11()
{
	var w : W3PlayerWitcher;
	var inv : CInventoryComponent;
	var ids, kits : array<SItemUniqueId>;
	var before, after, max : float;
	var lvlBefore, lvlAfter, abBefore, abAfter : int;

	w = GetWitcherPlayer();
	inv = w.GetInventory();
	GMTestReport(GMTestSwdNear(GMTestSwdAbl('WeaponRepairKit_1', 'repairValue'), 0.1) && GMTestSwdNear(GMTestSwdAbl('WeaponRepairKit_2', 'repairValue'), 0.2) && GMTestSwdNear(GMTestSwdAbl('ArmorRepairKit_3', 'repairValue'), 0.3)
		&& GMTestSwdNear(GMTestSwdAbl('WeaponRepairKit_4', 'repairValue'), 1) && GMTestSwdAbl('WeaponRepairKit_4_Stats', 'quality') == 4 && GMTestSwdAbl('ArmorRepairKit_1_Stats', 'quality') == 1,
		"ITEM-11 kit values: weapon kits 1 and 2 " + GMTestSwdAbl('WeaponRepairKit_1', 'repairValue') + ", " + GMTestSwdAbl('WeaponRepairKit_2', 'repairValue') + " (0.1, 0.2), armor kit 3 " + GMTestSwdAbl('ArmorRepairKit_3', 'repairValue') + " (0.3), master kit " + GMTestSwdAbl('WeaponRepairKit_4', 'repairValue') + " (1), qualities 1 and 4");

	ids = inv.AddAnItem('Guard Lvl1 steel sword 1', 1, true, true, false);
	max = inv.GetItemMaxDurability(ids[0]);
	inv.SetItemDurabilityScript(ids[0], max * 0.5);
	kits = inv.AddAnItem('weapon_repair_kit_1', 1, true, true, false);
	w.RepairItem(kits[0], ids[0]);
	after = inv.GetItemDurability(ids[0]);
	GMTestReport(GMTestSwdNear(after / max, 0.6) && !inv.HasItem('weapon_repair_kit_1'), "ITEM-11 weapon kit 1 on a sword at 50%: " + (100 * after / max) + "% (60%), kit used up");

	inv.SetItemDurabilityScript(ids[0], max);
	GMTestReport(w.IsItemRepairAble(ids[0]), "ITEM-11 a sword at full durability takes a kit");
	lvlBefore = inv.GetItemLevel(ids[0]);
	abBefore = GMTestItemGenLevel(inv, ids[0]);
	kits = inv.AddAnItem('weapon_repair_kit_4', 1, true, true, false);
	w.RepairItem(kits[0], ids[0]);
	lvlAfter = inv.GetItemLevel(ids[0]);
	abAfter = GMTestItemGenLevel(inv, ids[0]);
	GMTestReport(lvlAfter == lvlBefore + 1 && abAfter == abBefore + 1 && inv.GetItemDurability(ids[0]) >= max - 0.01,
		"ITEM-11 master weaponsmith tools on a full sword: level " + lvlBefore + " -> " + lvlAfter + ", per-level abilities " + abBefore + " -> " + abAfter + ", durability full");
	inv.RemoveItem(ids[0], 1);

	// Audit F1: a sword at Geralt's level raised by the master tools needs more than his level, which makes
	// ApplyRepairKit unequip it (forced, in combat too; the inventory menu path: gmtest_item11_unequip()).
	ids[0] = GMTestItemAtLevel('Guard Lvl1 steel sword 1', w.GetLevel());
	lvlBefore = inv.GetItemLevel(ids[0]);
	kits = inv.AddAnItem('weapon_repair_kit_4', 1, true, true, false);
	w.RepairItem(kits[0], ids[0]);
	GMTestReport(lvlBefore == w.GetLevel() && !w.HasRequiredLevelToEquipItem(ids[0]),
		"ITEM-11 master tools on a sword at Geralt's level (" + lvlBefore + "): now level " + inv.GetItemLevel(ids[0]) + ", equippable " + w.HasRequiredLevelToEquipItem(ids[0]) + " (false: ApplyRepairKit unequips it)");
	inv.RemoveItem(ids[0], 1);

	ids = inv.AddAnItem('Guard Lvl1 Armor 2', 1, true, true, false);
	max = inv.GetItemMaxDurability(ids[0]);
	inv.SetItemDurabilityScript(ids[0], max * 0.2);
	lvlBefore = inv.GetItemLevel(ids[0]);
	kits = inv.AddAnItem('armor_repair_kit_4', 1, true, true, false);
	w.RepairItem(kits[0], ids[0]);
	GMTestReport(inv.GetItemLevel(ids[0]) == lvlBefore + 1 && inv.GetItemDurability(ids[0]) >= max - 0.01,
		"ITEM-11 master armorsmith tools on armor at 20%: level " + lvlBefore + " -> " + inv.GetItemLevel(ids[0]) + ", durability " + (100 * inv.GetItemDurability(ids[0]) / max) + "%");
	inv.RemoveItem(ids[0], 1);
	GMTestReport(GetLocStringByKeyExt("item_name_repair_kit_weapon_4") != "" && GetLocStringByKeyExt("item_name_repair_kit_armor_4") != "",
		"ITEM-11 master kit name: '" + GetLocStringByKeyExt("item_name_repair_kit_weapon_4") + "', '" + GetLocStringByKeyExt("item_name_repair_kit_armor_4") + "'");
}

exec function gmtest_item11()
{
	GMTest_item11();
}

// A new copy of a level-scaled item at exactly `level` (copies taken until one has it, at most 30).
function GMTestItemAtLevel(itemName : name, level : int) : SItemUniqueId
{
	var inv : CInventoryComponent;
	var ids : array<SItemUniqueId>;
	var tries : int;

	inv = thePlayer.GetInventory();
	ids = inv.AddAnItem(itemName, 1, true, true, false);
	while(tries < 30 && inv.GetItemLevel(ids[0]) != level)
	{
		inv.RemoveItem(ids[0], 1);
		ids = inv.AddAnItem(itemName, 1, true, true, false);
		tries += 1;
	}
	return ids[0];
}

@addField(CR4Player)
var gmTestItemSword : SItemUniqueId;
@addField(CR4Player)
var gmTestItemOldSword : SItemUniqueId;

// ITEM-11, audit F1: master tools used from the inventory menu on an equipped sword at Geralt's level
// unequip it, in combat too (legacy's forced unequip). Two calls: gmtest_item11_unequip_prep() equips a
// new sword at Geralt's level and opens the inventory; then gmtest_item11_unequip() uses the master
// weaponsmith tools on the steel sword slot through the menu (OnApplyRepairKit, what using a kit on an
// equipped item calls), reports, closes the menu and puts the old sword back. For the combat case spawn
// enemies first (spawn(wolf, 2, 6, true)).
exec function gmtest_item11_unequip_prep()
{
	var w : W3PlayerWitcher;
	var old : SItemUniqueId;

	w = GetWitcherPlayer();
	w.GetItemEquippedOnSlot(EES_SteelSword, old);
	w.gmTestItemOldSword = old;
	w.gmTestItemSword = GMTestItemAtLevel('Guard Lvl1 steel sword 1', w.GetLevel());
	w.EquipItem(w.gmTestItemSword);
	LogChannel('GMTest', "INFO ITEM-11 unequip prep: sword level " + w.GetInventory().GetItemLevel(w.gmTestItemSword) + ", equipped " + w.IsItemEquipped(w.gmTestItemSword) + ", Geralt's level " + w.GetLevel() + ", in combat " + w.IsInCombat());
	theGame.RequestMenuWithBackground('InventoryMenu', 'CommonMenu');
}

exec function gmtest_item11_unequip()
{
	var w : W3PlayerWitcher;
	var inv : CInventoryComponent;
	var root : CR4MenuBase;
	var menu : CR4InventoryMenu;
	var kits : array<SItemUniqueId>;
	var combat : bool;

	w = GetWitcherPlayer();
	inv = w.GetInventory();
	root = (CR4MenuBase)theGame.GetGuiManager().GetRootMenu();
	if(root)
		menu = (CR4InventoryMenu)root.GetLastChild();
	GMTestReport(menu && w.IsItemEquipped(w.gmTestItemSword), "ITEM-11 unequip: the inventory menu is open and the test sword equipped (run gmtest_item11_unequip_prep() first)");
	if(!menu)
		return;
	combat = w.IsInCombat();
	kits = inv.AddAnItem('weapon_repair_kit_4', 1, true, true, false);
	menu.OnApplyRepairKit(kits[0], (int)EES_SteelSword);
	GMTestReport(!w.IsItemEquipped(w.gmTestItemSword) && inv.GetItemLevel(w.gmTestItemSword) == w.GetLevel() + 1 && !menu.gmForceUnequip,
		"ITEM-11 master tools from the inventory on the equipped sword at Geralt's level, in combat " + combat + ": level now " + inv.GetItemLevel(w.gmTestItemSword) + ", still equipped " + w.IsItemEquipped(w.gmTestItemSword) + " (false), force flag reset " + !menu.gmForceUnequip);
	root.CloseMenu();
	if(inv.IsIdValid(w.gmTestItemOldSword))
		w.EquipItem(w.gmTestItemOldSword);
	inv.RemoveItem(w.gmTestItemSword, 1);
}

// ITEM-12: the Armorer's Table and grindstone buffs (AddRepairObjectBuff, what using them calls), their
// values and duration, the tooltip lines; the buffs are removed afterwards.
function GMTest_item12()
{
	var w : W3PlayerWitcher;
	var before, after, pts : float;
	var sword : SItemUniqueId;
	var info : string;
	var added : bool;

	w = GetWitcherPlayer();
	GMTestReport(GMTestSwdAbl('EnhancedArmorEffect', 'duration') == 1800 && GMTestSwdAbl('EnhancedWeaponEffect', 'duration') == 1800 && GMTestSwdNear(GMTestSwdAbl('EnhancedArmorEffect', 'slashing_resistance_perc'), 0.05)
		&& GMTestSwdAbl('EnhancedWeaponEffect', 'armor_reduction') == 10 && GMTestSwdNear(GMTestSwdAbl('EnhancedWeaponEffect', 'armor_reduction_perc'), 0.05),
		"ITEM-12 table and grindstone: " + GMTestSwdAbl('EnhancedArmorEffect', 'duration') + " s (1800; 5.x 3600), resistances +" + GMTestSwdAbl('EnhancedArmorEffect', 'slashing_resistance_perc') + ", armor penetration " + GMTestSwdAbl('EnhancedWeaponEffect', 'armor_reduction') + " and " + GMTestSwdAbl('EnhancedWeaponEffect', 'armor_reduction_perc'));
	w.RemoveBuff(EET_EnhancedArmor);
	w.RemoveBuff(EET_EnhancedWeapon);
	w.GetResistValue(CDS_SlashingRes, pts, before);
	added = w.AddRepairObjectBuff(true, true);
	w.GetResistValue(CDS_SlashingRes, pts, after);
	GMTestReport(added && w.HasBuff(EET_EnhancedArmor) && w.HasBuff(EET_EnhancedWeapon) && w.GetBuff(EET_EnhancedArmor).GetDurationLeft() > 1790,
		"ITEM-12 both buffs added, " + w.GetBuff(EET_EnhancedArmor).GetDurationLeft() + " s left; slashing resistance " + before + " -> " + after + " (read in the same frame; the ability counts from the next)");
	if(w.GetItemEquippedOnSlot(EES_SteelSword, sword))
	{
		info = w.GetInventory().GMGetEnhancedBuffInfo(sword);
		GMTestReport(StrFindFirst(info, "enhanced_sword") >= 0 && StrFindFirst(info, "10") >= 0, "ITEM-12 the steel sword's tooltip line: " + StrReplaceAll(StrReplaceAll(info, "<", "["), ">", "]"));
	}
	// The buffs stay on: GMTest_item12_after() (called by gmtest_panel(), the regression's next call)
	// asserts the resistance gain once the buff's ability counts, then removes them.
	w.gmTestItemResBefore = before;
	w.gmTestItemResPending = true;
}

exec function gmtest_item12()
{
	GMTest_item12();
}

@addField(CR4Player)
var gmTestItemResBefore : float;
@addField(CR4Player)
var gmTestItemResPending : bool;

// ITEM-12, audit F11: the Armorer's Table's +5% slashing resistance on Geralt, read after GMTest_item12()
// added the buffs (in a later call, so the buff's ability counts); then both buffs are removed. Does
// nothing unless GMTest_item12() ran before.
function GMTest_item12_after()
{
	var w : W3PlayerWitcher;
	var pts, after : float;

	w = GetWitcherPlayer();
	if(!w.gmTestItemResPending)
		return;
	w.gmTestItemResPending = false;
	w.GetResistValue(CDS_SlashingRes, pts, after);
	GMTestReport(w.HasBuff(EET_EnhancedArmor) && GMTestSwdNear(after - w.gmTestItemResBefore, 0.05),
		"ITEM-12 the Armorer's Table buff on Geralt: slashing resistance " + w.gmTestItemResBefore + " -> " + after + " (+0.05)");
	w.RemoveBuff(EET_EnhancedArmor);
	w.RemoveBuff(EET_EnhancedWeapon);
}

exec function gmtest_item12_after()
{
	GMTest_item12_after();
}

