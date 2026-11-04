// In-game tests for CRAFT (crafting, alchemy recipes, ingredients, dismantling). See docs/features/craft.md.

// CRAFT's situation-free checks (in gmtest_regress()).
function GMTest_craft()
{
	GMTest_craft01();
	GMTest_craft04();
	GMTest_craft06();
	GMTest_craft07();
	GMTest_craft08();
	GMTest_craft09();
}

exec function gmtest_craft()
{
	GMTest_craft();
}

// "<count> <part>, ..." of an item's dismantling parts, as the game reads them.
function GMTestCraftParts(itemName : name) : string
{
	var inv : CInventoryComponent;
	var ids : array<SItemUniqueId>;
	var parts : array<SItemParts>;
	var i : int;
	var s : string;

	inv = thePlayer.GetInventory();
	ids = inv.AddAnItem(itemName, 1, true, true, false);
	parts = inv.GetItemRecyclingParts(ids[0]);
	for(i = 0; i < parts.Size(); i += 1)
	{
		if(i > 0)
			s += ", ";
		s += parts[i].quantity + " " + NameToString(parts[i].itemName);
	}
	inv.RemoveItem(ids[0], 1);
	return s;
}

function GMTestCraftPartsIs(itemName : name, expected : string)
{
	var s : string;

	s = GMTestCraftParts(itemName);
	GMTestReport(s == expected, "CRAFT-08 parts of " + NameToString(itemName) + ": '" + s + "' ('" + expected + "')");
}

// CRAFT-08: legacy's parts (5.x has 1.32's), the rule (every craftsman returns every part), the junk texts.
function GMTest_craft08()
{
	var inv : CInventoryComponent;
	var ids : array<SItemUniqueId>;
	var silk, leather : int;

	GMTestCraftPartsIs('Guard Lvl1 Armor 1', "1 Silk, 1 Leather");
	GMTestCraftPartsIs('Guard Lvl1 steel sword 1', "1 Leather squares, 1 Steel ingot");
	GMTestCraftPartsIs('Cheesecutter', "1 Dwimeryte ingot, 1 Amber");
	GMTestCraftPartsIs('Nickel ore', "2 Nickel mineral");
	GMTestCraftPartsIs('Rune pierog', "1 Infused dust");
	GMTestCraftPartsIs('Katakan mutagen', "1 Lesser mutagen red");
	GMTestCraftPartsIs('Arachas mutagen', "1 Lesser mutagen green");
	GMTestCraftPartsIs('q701_hare_mask', "");
	GMTestCraftPartsIs('Razor', "1 Iron ore, 1 Timber");
	// 1.32 and 5.x have the ear's parts commented out; legacy's are read (CRAFT/LOOT audit F1)
	GMTestCraftPartsIs('Grave Hag ear', "1 Monstrous ear");
	// Geralt's starting gear (written by gen_arm_km.py; CRAFT/LOOT audit F2)
	GMTestCraftPartsIs('Starting Armor', "1 Leather, 1 Linen");
	GMTestCraftPartsIs('Starting Boots', "1 Leather squares");
	GMTestCraftPartsIs('Starting Gloves', "2 Leather straps");
	GMTestCraftPartsIs('Starting Pants', "1 Linen, 1 Leather squares");

	// A Journeyman returns every part (1.32 and 5.x: one of each).
	inv = thePlayer.GetInventory();
	silk = inv.GetItemQuantityByName('Silk');
	leather = inv.GetItemQuantityByName('Hardened leather');
	GMTestCraftPartsIs('Guard Lvl1 Armor 3', "2 Silk, 2 Hardened leather, 2 String");
	ids = inv.AddAnItem('Guard Lvl1 Armor 3', 1, true, true, false);
	inv.RecycleItem(ids[0], ECL_Journeyman);
	GMTestReport(inv.GetItemQuantityByName('Silk') - silk == 2 && inv.GetItemQuantityByName('Hardened leather') - leather == 2 && !inv.IsIdValid(ids[0]),
		"CRAFT-08 a Journeyman dismantles Guard Lvl1 Armor 3 into " + (inv.GetItemQuantityByName('Silk') - silk) + " Silk and " + (inv.GetItemQuantityByName('Hardened leather') - leather) + " Hardened leather (2, 2), the armor gone");
	inv.RemoveItemByName('Silk', inv.GetItemQuantityByName('Silk') - silk);
	inv.RemoveItemByName('Hardened leather', inv.GetItemQuantityByName('Hardened leather') - leather);
	inv.RemoveItemByName('String', 2);

	GMTestReport(GetLocStringByKeyExt("item_desc_junk") == GetLocStringById(2110992258) && GetLocStringByKeyExt("item_desc_valuable") == GetLocStringById(2110992260),
		"CRAFT-08 junk descriptions: '" + GetLocStringByKeyExt("item_desc_junk") + "', '" + GetLocStringByKeyExt("item_desc_valuable") + "' (Ghost Mode's rows)");
}

exec function gmtest_craft08()
{
	GMTest_craft08();
}

// CRAFT-07: an ingredient's category, kind tag, rarity and description follow legacy (Acid extract, a
// Blood and Wine crafting component in 5.x, is an alchemy ingredient of Magic rarity).
function GMTest_craft07()
{
	var inv : CInventoryComponent;
	var ids : array<SItemUniqueId>;

	inv = thePlayer.GetInventory();
	ids = inv.AddAnItem('Acid extract', 1, true, true, false);
	GMTestReport(inv.GetItemCategory(ids[0]) == 'alchemy_ingredient' && inv.ItemHasTag(ids[0], 'AlchemyIngredient') && !inv.ItemHasTag(ids[0], 'CraftingIngredient')
		&& inv.GetItemQuality(ids[0]) == 3,
		"CRAFT-07 Acid extract: category " + inv.GetItemCategory(ids[0]) + " (alchemy_ingredient), AlchemyIngredient " + inv.ItemHasTag(ids[0], 'AlchemyIngredient') + ", quality " + inv.GetItemQuality(ids[0]) + " (3, Magic)");
	inv.RemoveItem(ids[0], 1);

	// Local pepper vodka is the potion-refill alcohol, an alchemy ingredient; Free nilfgaardian lemon is a
	// drink (CRAFT/LOOT audit F3; 1.32 and 5.x have it the other way round)
	ids = inv.AddAnItem('Local pepper vodka', 1, true, true, false);
	GMTestReport(inv.GetItemCategory(ids[0]) == 'alchemy_ingredient' && inv.ItemHasTag(ids[0], theGame.params.TAG_ALCHEMY_REFILL_ALCO)
		&& inv.ItemHasTag(ids[0], 'AlchemyIngredient') && !inv.ItemHasTag(ids[0], 'Drinks') && !inv.IsItemFood(ids[0]),
		"CRAFT-07 Local pepper vodka: category " + inv.GetItemCategory(ids[0]) + " (alchemy_ingredient), refill alcohol " + inv.ItemHasTag(ids[0], theGame.params.TAG_ALCHEMY_REFILL_ALCO)
		+ ", AlchemyIngredient " + inv.ItemHasTag(ids[0], 'AlchemyIngredient') + ", Drinks " + inv.ItemHasTag(ids[0], 'Drinks') + " (true, true, false)");
	inv.RemoveItem(ids[0], 1);
	ids = inv.AddAnItem('Free nilfgaardian lemon', 1, true, true, false);
	GMTestReport(inv.GetItemCategory(ids[0]) == 'edibles' && !inv.ItemHasTag(ids[0], theGame.params.TAG_ALCHEMY_REFILL_ALCO)
		&& inv.ItemHasTag(ids[0], 'Drinks') && inv.ItemHasTag(ids[0], 'Alcohol') && !inv.ItemHasTag(ids[0], 'AlchemyIngredient'),
		"CRAFT-07 Free nilfgaardian lemon: category " + inv.GetItemCategory(ids[0]) + " (edibles), refill alcohol " + inv.ItemHasTag(ids[0], theGame.params.TAG_ALCHEMY_REFILL_ALCO)
		+ ", Drinks " + inv.ItemHasTag(ids[0], 'Drinks') + " (false, true)");
	inv.RemoveItem(ids[0], 1);
}

exec function gmtest_craft07()
{
	GMTest_craft07();
}

// CRAFT-07, in play: potions are refilled (as meditation and the alchemy menu do, SingletonItemsRefillAmmo)
// with Local pepper vodka, and not with Free nilfgaardian lemon. Geralt's own refill alcohols are put
// aside for the test and given back. Not in the regression: the refill fills every potion Geralt has.
exec function gmtest_craft07_refill()
{
	var inv : CInventoryComponent;
	var alcos, pot, lemon, vodka : array<SItemUniqueId>;
	var names : array<name>;
	var counts : array<int>;
	var i, before : int;
	var ok : bool;

	inv = thePlayer.GetInventory();
	alcos = inv.GetItemsByTag(theGame.params.TAG_ALCHEMY_REFILL_ALCO);
	for(i = 0; i < alcos.Size(); i += 1)
	{
		names.PushBack(inv.GetItemName(alcos[i]));
		counts.PushBack(inv.GetItemQuantity(alcos[i]));
	}
	for(i = 0; i < names.Size(); i += 1)
		inv.RemoveItemByName(names[i], counts[i]);
	LogChannel('GMTest', "refill alcohols put aside: " + names.Size());

	pot = inv.AddAnItem('Swallow 1', 1, true, true, false);
	lemon = inv.AddAnItem('Free nilfgaardian lemon', 1, true, true, false);
	inv.SingletonItemSetAmmo(pot[0], 0);
	ok = inv.SingletonItemsRefillAmmo();
	GMTestReport(!ok && inv.SingletonItemGetAmmo(pot[0]) == 0 && inv.GetItemQuantityByName('Free nilfgaardian lemon') == 1,
		"CRAFT-07 refill with only Free nilfgaardian lemon: refilled " + ok + ", Swallow ammo " + inv.SingletonItemGetAmmo(pot[0]) + ", lemons left " + inv.GetItemQuantityByName('Free nilfgaardian lemon') + " (false, 0, 1)");

	vodka = inv.AddAnItem('Local pepper vodka', 1, true, true, false);
	ok = inv.SingletonItemsRefillAmmo();
	GMTestReport(ok && inv.SingletonItemGetAmmo(pot[0]) == inv.SingletonItemGetMaxAmmo(pot[0]) && inv.GetItemQuantityByName('Local pepper vodka') == 0
		&& inv.GetItemQuantityByName('Free nilfgaardian lemon') == 1,
		"CRAFT-07 refill with Local pepper vodka: refilled " + ok + ", Swallow ammo " + inv.SingletonItemGetAmmo(pot[0]) + "/" + inv.SingletonItemGetMaxAmmo(pot[0])
		+ ", vodka left " + inv.GetItemQuantityByName('Local pepper vodka') + ", lemons left " + inv.GetItemQuantityByName('Free nilfgaardian lemon') + " (true, full, 0, 1)");

	inv.RemoveItem(pot[0], 1);
	inv.RemoveItemByName('Free nilfgaardian lemon', 1);
	inv.RemoveItemByName('Local pepper vodka', inv.GetItemQuantityByName('Local pepper vodka'));
	for(i = 0; i < names.Size(); i += 1)
		inv.AddAnItem(names[i], counts[i], true, true, false);
}

// CRAFT-09: which items a kit dismantles (GMDismantleKitFor, the condition of the "Dismantle" input).
function GMTest_craft09()
{
	var inv : CInventoryComponent;
	var junk, alch, armor, razor, kits : array<SItemUniqueId>;
	var noKit, gearKit, alchKit, alchNoKit, armorKit, razorKit : name;

	inv = thePlayer.GetInventory();
	inv.RemoveItemByName('gear_dismantle_kit_1', inv.GetItemQuantityByName('gear_dismantle_kit_1'));
	inv.RemoveItemByName('alchemy_dismantle_kit_1', inv.GetItemQuantityByName('alchemy_dismantle_kit_1'));
	junk = inv.AddAnItem('Dull meteorite axe', 1, true, true, false);
	alch = inv.AddAnItem('Katakan mutagen', 1, true, true, false);
	armor = inv.AddAnItem('Guard Lvl1 Armor 3', 1, true, true, false);
	razor = inv.AddAnItem('Razor', 1, true, true, false);
	noKit = inv.GMDismantleKitFor(junk[0]);
	kits = inv.AddAnItem('gear_dismantle_kit_1', 1, true, true, false);
	gearKit = inv.GMDismantleKitFor(junk[0]);
	alchNoKit = inv.GMDismantleKitFor(alch[0]);
	armorKit = inv.GMDismantleKitFor(armor[0]);
	razorKit = inv.GMDismantleKitFor(razor[0]);
	kits = inv.AddAnItem('alchemy_dismantle_kit_1', 1, true, true, false);
	alchKit = inv.GMDismantleKitFor(alch[0]);
	GMTestReport(noKit == '' && gearKit == 'gear_dismantle_kit_1' && alchNoKit == '' && alchKit == 'alchemy_dismantle_kit_1' && armorKit == '' && razorKit == '',
		"CRAFT-09 kits: junk without a kit '" + noKit + "', with the item kit '" + gearKit + "'; a named mutagen with only the item kit '" + alchNoKit + "', with the alchemy kit '" + alchKit + "'; armor '" + armorKit + "', the razor '" + razorKit + "' (none)");
	GMTestReport(inv.GetItemCategory(kits[0]) == 'misc' && GetLocStringByKeyExt("item_name_dismantle_kit_gear_1") == GetLocStringById(2110992330) && GetLocStringByKeyExt("item_name_dismantle_kit_alchemy_1") == GetLocStringById(2110992332) && GetLocStringById(2110992334) != "",
		"CRAFT-09 kit names: '" + GetLocStringByKeyExt("item_name_dismantle_kit_gear_1") + "', '" + GetLocStringByKeyExt("item_name_dismantle_kit_alchemy_1") + "', input '" + GetLocStringById(2110992334) + "'");
	inv.RemoveItem(junk[0], 1);
	inv.RemoveItem(alch[0], 1);
	inv.RemoveItem(armor[0], 1);
	inv.RemoveItem(razor[0], 1);
	inv.RemoveItemByName('gear_dismantle_kit_1', 1);
	inv.RemoveItemByName('alchemy_dismantle_kit_1', 1);
}

exec function gmtest_craft09()
{
	GMTest_craft09();
}

// CRAFT-09 in the inventory menu (scripted): gmtest_craft09_open() gives an item kit, an alchemy kit, a
// junk item and a named mutagen and opens the inventory; gmtest_craft09_menu() then dismantles both
// through the menu's dismantle function and checks the parts and the kits used; the menu is closed.
exec function gmtest_craft09_open()
{
	var inv : CInventoryComponent;

	inv = thePlayer.GetInventory();
	inv.AddAnItem('gear_dismantle_kit_1', 1);
	inv.AddAnItem('alchemy_dismantle_kit_1', 1);
	inv.AddAnItem('Dull meteorite axe', 1);
	inv.AddAnItem('Katakan mutagen', 1);
	theGame.RequestMenuWithBackground('InventoryMenu', 'CommonMenu');
}

exec function gmtest_craft09_menu()
{
	var menu : CR4InventoryMenu;
	var inv : CInventoryComponent;
	var ids : array<SItemUniqueId>;
	var ore, timber, lesser, gk, ak : int;

	menu = (CR4InventoryMenu)((CR4MenuBase)theGame.GetGuiManager().GetRootMenu()).GetLastChild();
	inv = thePlayer.GetInventory();
	if(!menu)
	{
		GMTestReport(false, "CRAFT-09 menu: the inventory is not open (run gmtest_craft09_open() first)");
		return;
	}
	ore = inv.GetItemQuantityByName('Meteorite ore');
	timber = inv.GetItemQuantityByName('Hardened timber');
	lesser = inv.GetItemQuantityByName('Lesser mutagen red');
	gk = inv.GetItemQuantityByName('gear_dismantle_kit_1');
	ak = inv.GetItemQuantityByName('alchemy_dismantle_kit_1');
	ids = inv.GetItemsByName('Dull meteorite axe');
	menu.GMPlayerDismantleItem(ids[0]);
	ids = inv.GetItemsByName('Katakan mutagen');
	menu.GMPlayerDismantleItem(ids[0]);
	GMTestReport(inv.GetItemQuantityByName('Meteorite ore') == ore + 1 && inv.GetItemQuantityByName('Hardened timber') == timber + 1 && inv.GetItemQuantityByName('Lesser mutagen red') == lesser + 1
		&& inv.GetItemQuantityByName('gear_dismantle_kit_1') == gk - 1 && inv.GetItemQuantityByName('alchemy_dismantle_kit_1') == ak - 1
		&& inv.GetItemQuantityByName('Dull meteorite axe') == 0 && inv.GetItemQuantityByName('Katakan mutagen') == 0,
		"CRAFT-09 menu: the axe gave " + (inv.GetItemQuantityByName('Meteorite ore') - ore) + " Meteorite ore and " + (inv.GetItemQuantityByName('Hardened timber') - timber) + " Hardened timber (1, 1), the Katakan mutagen "
		+ (inv.GetItemQuantityByName('Lesser mutagen red') - lesser) + " Lesser mutagen red (1); kits left " + inv.GetItemQuantityByName('gear_dismantle_kit_1') + " and " + inv.GetItemQuantityByName('alchemy_dismantle_kit_1') + " (one each used)");
	((CR4MenuBase)theGame.GetGuiManager().GetRootMenu()).CloseMenu();
}

// "<crafted item> | <craftsman level> | <n item>, ..." of a schematic as the crafting manager reads it.
function GMTestCraftSchem(schematic : name) : string
{
	var schem : SCraftingSchematic;
	var s : string;
	var i : int;

	schem = getCraftingSchematicFromName(schematic);
	s = NameToString(schem.craftedItemName) + " | " + (int)schem.requiredCraftsmanLevel + " |";
	for(i = 0; i < schem.ingredients.Size(); i += 1)
	{
		if(i > 0)
			s += ",";
		s += " " + schem.ingredients[i].quantity + " " + NameToString(schem.ingredients[i].itemName);
	}
	return s;
}

// How many <schematic> entries of a name the game reads (a whole-file override must not add a second).
function GMTestCraftSchemCount(schematic : name) : int
{
	var dm : CDefinitionsManagerAccessor;
	var main : SCustomNode;
	var tmpName : name;
	var i, n : int;

	dm = theGame.GetDefinitionsManager();
	main = dm.GetCustomDefinition('crafting_schematics');
	for(i = 0; i < main.subNodes.Size(); i += 1)
	{
		dm.GetCustomNodeAttributeValueName(main.subNodes[i], 'name_name', tmpName);
		if(tmpName == schematic)
			n += 1;
	}
	return n;
}

function GMTestCraftSchemIs(schematic : name, expected : string)
{
	var s : string;
	var n : int;

	s = GMTestCraftSchem(schematic);
	n = GMTestCraftSchemCount(schematic);
	GMTestReport(s == expected && n == 1, "CRAFT schematic " + NameToString(schematic) + ": '" + s + "' ('" + expected + "'), defined " + n + " time(s) (1)");
}

// CRAFT-01 to CRAFT-03 (and CRAFT-05's inert price): legacy's schematics from the whole-file overrides;
// the load-time grants (the Meteorite plate schematic, CRAFT-06's Tawny Owl recipe); 5.x's Netflix
// schematics kept (DC2; 5.x itself reads each of dlc18_recipes.xml's schematics twice, the mod does not touch
// that file). Craftsman levels: 1 Apprentice, 2 Journeyman, 3 Master, 4 Grand Master, 5 Arch Master.
function GMTest_craft01()
{
	var w : W3PlayerWitcher;
	var known : array<name>;
	var schem : SCraftingSchematic;

	w = GetWitcherPlayer();
	GMTestCraftSchemIs('Guard Lvl1 steel sword 3 schematic', "Guard lvl1 steel sword 3 | " + (int)ECL_Grand_Master + " | 1 Dwimeryte ingot, 1 Leather, 2 Wire rope, 1 Haft, 1 Amethyst dust");
	GMTestCraftSchemIs('Novigraadan sword 2 schematic', "Novigraadan sword 2_crafted | " + (int)ECL_Journeyman + " | 1 Iron ingot, 1 Leather straps, 1 Timber, 1 Wire rope");
	GMTestCraftSchemIs('Lynx School steel sword Upgrade schematic 4', "Lynx School steel sword 4 | " + (int)ECL_Arch_Master + " | 1 Lynx School steel sword 3, 1 Orichalcum ingot, 1 Green gold ingot, 1 Ruby dust, 1 Monstrous spore, 1 Monstrous blood");
	GMTestCraftSchemIs('Rune pierog schematic', "Rune pierog | " + (int)ECL_Master + " | 1 Runestone lesser, 1 Dumpling, 1 Amber dust");
	GMTestCraftSchemIs('Meteorite plate schematic', "Meteorite plate | " + (int)ECL_Master + " | 2 Meteorite ingot");
	schem = getCraftingSchematicFromName('Meteorite plate schematic');
	known = w.GetCraftingSchematicsNames();
	GMTestReport(known.Contains('Meteorite plate schematic') && FactsQuerySum("gm_craft_recipes_added") > 0 && GMTestCraftSchemCount('Netflix steel sword schematic') >= 1,
		"CRAFT-01 Geralt knows the Meteorite plate schematic (granted once at load); 5.x's Netflix schematics still read (DC2)");
	known = w.GetAlchemyRecipes();
	GMTestReport(known.Contains('Recipe for Tawny Owl 1'), "CRAFT-06 Geralt knows the Tawny Owl recipe (granted once at load)");
}

exec function gmtest_craft01()
{
	GMTest_craft01();
}

// CRAFT-04: the four craftable quest armors (legacy's items, schematics and armor-stand looks).
function GMTest_craft04()
{
	var dm : CDefinitionsManagerAccessor;

	dm = theGame.GetDefinitionsManager();
	GMTestCraftSchemIs('q108 Heavy Armor 4 schematic', "q108 Heavy armor 04_crafted | " + (int)ECL_Grand_Master + " | 1 Dwimeryte plate, 1 Leather, 1 String");
	GMTestCraftSchemIs('q108 Light Armor 9 schematic', "q108 Light armor 09_crafted | " + (int)ECL_Grand_Master + " | 2 Silk, 2 Hardened leather, 2 String, 1 Glowing ore");
	GMTestCraftSchemIs('q108 Medium Armor 3 schematic', "q108 Medium armor 03_crafted | " + (int)ECL_Grand_Master + " | 1 Meteorite plate, 1 Silver ingot, 1 Glowing ingot, 2 Hardened leather, 2 String");
	GMTestCraftSchemIs('Oathbreaker Armor schematic', "Oathbreaker armor crafted | " + (int)ECL_Master + " | 1 Meteorite plate, 1 Silver ingot, 1 Glowing ingot, 2 Hardened leather, 2 String");
	GMTestReport(dm.GetItemCategory('q108 Heavy armor 04_crafted') == 'armor' && dm.ItemHasTag('q108 Heavy armor 04_crafted', 'HeavyArmor') && dm.ItemHasTag('q108 Light armor 09_crafted', 'LightArmor')
		&& dm.ItemHasTag('q108 Medium armor 03_crafted', 'MediumArmor') && dm.GetItemCategory('Oathbreaker armor crafted') == 'armor' && dm.GetItemCategory('Oathbreaker Armor schematic') == 'crafting_schematic',
		"CRAFT-04 the crafted quest armors exist with their classes, and their schematic items");
}

exec function gmtest_craft04()
{
	GMTest_craft04();
}

// CRAFT-04 by hand (scripted set-up): the four schematics and every ingredient, to craft one at a Grand
// Master armorer (Yoana) and see it on the armor stand.
exec function gmtest_craft04_give()
{
	var w : W3PlayerWitcher;

	w = GetWitcherPlayer();
	w.AddCraftingSchematic('q108 Heavy Armor 4 schematic');
	w.AddCraftingSchematic('q108 Light Armor 9 schematic');
	w.AddCraftingSchematic('q108 Medium Armor 3 schematic');
	w.AddCraftingSchematic('Oathbreaker Armor schematic');
	w.inv.AddAnItem('Dwimeryte plate', 1);
	w.inv.AddAnItem('Leather', 1);
	w.inv.AddAnItem('String', 1);
	w.inv.AddMoney(5000);
}

// "<cooked item> | <n item>, ..." of an alchemy recipe as the game reads it.
function GMTestCraftRecipe(recipe : name) : string
{
	var rec : SAlchemyRecipe;
	var s : string;
	var i : int;

	rec = getAlchemyRecipeFromName(recipe);
	s = NameToString(rec.cookedItemName) + " |";
	for(i = 0; i < rec.requiredIngredients.Size(); i += 1)
	{
		if(i > 0)
			s += ",";
		s += " " + rec.requiredIngredients[i].quantity + " " + NameToString(rec.requiredIngredients[i].itemName);
	}
	return s;
}

function GMTestCraftRecipeIs(recipe : name, expected : string)
{
	var s : string;

	s = GMTestCraftRecipe(recipe);
	GMTestReport(s == expected, "CRAFT-06 recipe " + NameToString(recipe) + ": '" + s + "' ('" + expected + "')");
}

// CRAFT-06: legacy's alchemy recipes from the whole-file overrides, the two alcohol recipes; the
// nekker pheromone keeps 5.x's potion type (ALCH-08's confirmed deviation) with legacy's ingredients.
function GMTest_craft06()
{
	var rec : SAlchemyRecipe;
	var dm : CDefinitionsManagerAccessor;

	dm = theGame.GetDefinitionsManager();
	GMTestCraftRecipeIs('Recipe for Swallow 1', "Swallow 1 | 1 Dwarven spirit, 1 Drowner brain, 1 Celandine");
	GMTestCraftRecipeIs('Recipe for Grapeshot 1', "Grapeshot 1 | 1 Saltpetre, 1 Calcium equum, 1 Crows eye");
	GMTestCraftRecipeIs('Recipe for Mutagen red', "Mutagen red | 3 Lesser mutagen red");
	GMTestCraftRecipeIs('Recipe for Mandrake cordial 1', "Mandrake cordial | 1 Empty bottle, 1 Temerian Rye, 1 Redanian Herbal, 1 Mandrake root");
	GMTestCraftRecipeIs('Recipe for Nekker Pheromone Potion 1', "Pheromone Potion Nekker 1 | 1 Dwarven spirit, 1 Nekker blood, 1 Green mold, 1 Moleyarrow");
	rec = getAlchemyRecipeFromName('Recipe for Nekker Pheromone Potion 1');
	GMTestReport(rec.cookedItemType == EACIT_Quest && dm.GetItemCategory('Recipe for Mahakam spirit 1') == 'alchemy_recipe' && dm.GetItemCategory('Recipe for Mandrake cordial 1') == 'alchemy_recipe',
		"CRAFT-06 the nekker pheromone formula is a quest formula, as legacy (ALCH-08): " + rec.cookedItemType + "; the alcohol recipe items exist");
}

exec function gmtest_craft06()
{
	GMTest_craft06();
}

// CRAFT-06 by hand: the Mandrake cordial recipe and its ingredients, to brew it in the alchemy menu.
exec function gmtest_craft06_give()
{
	var w : W3PlayerWitcher;

	w = GetWitcherPlayer();
	w.AddAlchemyRecipe('Recipe for Mandrake cordial 1');
	w.inv.AddAnItem('Empty bottle', 1);
	w.inv.AddAnItem('Temerian Rye', 1);
	w.inv.AddAnItem('Redanian Herbal', 1);
	w.inv.AddAnItem('Mandrake root', 1);
}
