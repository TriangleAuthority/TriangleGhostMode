// Helpers for in-game checks with real NPCs, menus and kills (CRAFT and LOOT verification): spawn a
// merchant, craftsman, monster or quest NPC from its entity file, open its shop, crafting or smith menu
// the way the dialogue scenes do (ShowMeGoods, ShowCraftingPanel), and act through the open menu's own
// events (what the menu's buttons call). See docs/features/craft.md and loot.md.

// Spawns an entity file (forward slashes) dist metres in front of Geralt and tags it.
exec function gmtest_spawnat(path : string, tag : name, optional dist : float)
{
	var template : CEntityTemplate;
	var ent : CEntity;
	var isNpc, isMerchant : bool;

	if(dist <= 0)
		dist = 2.5;
	template = (CEntityTemplate)LoadResource(path, true);
	if(!template)
	{
		LogChannel('GMTest', "FAIL spawn: no template " + path);
		return;
	}
	ent = theGame.CreateEntity(template, thePlayer.GetWorldPosition() + thePlayer.GetHeadingVector() * dist, thePlayer.GetWorldRotation());
	if(!ent)
	{
		LogChannel('GMTest', "FAIL spawn: " + path + " not created");
		return;
	}
	ent.AddTag(tag);
	isNpc = (CNewNPC)ent;
	isMerchant = (W3MerchantNPC)ent;
	LogChannel('GMTest', "INFO spawned " + path + " as " + tag + ": npc " + isNpc + ", merchant " + isMerchant + ", items " + ((CGameplayEntity)ent).GetInventory().GetItemCount());
}

function GMTestPlayCount(inv : CInventoryComponent, category : name) : int
{
	var ids : array<SItemUniqueId>;
	var i, n : int;

	inv.GetAllItems(ids);
	for(i = 0; i < ids.Size(); i += 1)
		if(inv.GetItemCategory(ids[i]) == category)
			n += 1;
	return n;
}

function GMTestPlayNames(inv : CInventoryComponent, category : name, max : int) : string
{
	var ids : array<SItemUniqueId>;
	var i, n : int;
	var s : string;

	inv.GetAllItems(ids);
	for(i = 0; i < ids.Size() && n < max; i += 1)
		if(category == '' || inv.GetItemCategory(ids[i]) == category)
		{
			s += NameToString(inv.GetItemName(ids[i])) + " x" + inv.GetItemQuantity(ids[i]) + "; ";
			n += 1;
		}
	return s;
}

// What an NPC (by tag) is and holds: craftsman levels, kinds of items, runes, glyphs, schematics, recipes,
// and whether it holds up to three named items.
exec function gmtest_npcinfo(tag : name, optional a : name, optional b : name, optional c : name)
{
	var ent : CGameplayEntity;
	var inv : CInventoryComponent;
	var cc : W3CraftsmanComponent;
	var ids : array<SItemUniqueId>;
	var s : string;

	ent = (CGameplayEntity)theGame.GetEntityByTag(tag);
	if(!ent)
	{
		LogChannel('GMTest', "FAIL npcinfo: no entity " + tag);
		return;
	}
	inv = ent.GetInventory();
	inv.GetAllItems(ids);
	cc = (W3CraftsmanComponent)ent.GetComponentByClassName('W3CraftsmanComponent');
	s = "INFO " + tag + ": " + ids.Size() + " kinds, money " + inv.GetMoney();
	if(cc)
		s += ", smith level " + cc.GetCraftsmanLevel(ECT_Smith) + ", armorer level " + cc.GetCraftsmanLevel(ECT_Armorer);
	s += "; schematics " + GMTestPlayCount(inv, 'crafting_schematic') + ", recipes " + GMTestPlayCount(inv, 'alchemy_recipe') + ", upgrades (runes, glyphs) " + GMTestPlayCount(inv, 'upgrade');
	if(IsNameValid(a))
		s += "; " + a + " " + inv.GetItemQuantityByName(a);
	if(IsNameValid(b))
		s += ", " + b + " " + inv.GetItemQuantityByName(b);
	if(IsNameValid(c))
		s += ", " + c + " " + inv.GetItemQuantityByName(c);
	LogChannel('GMTest', s);
}

// Lists items of a category (or all with '') an NPC holds, at most max (default 25).
exec function gmtest_npcitems(tag : name, optional category : name, optional max : int)
{
	var ent : CGameplayEntity;

	ent = (CGameplayEntity)theGame.GetEntityByTag(tag);
	if(!ent)
		return;
	if(max <= 0)
		max = 25;
	LogChannel('GMTest', "INFO " + tag + " " + category + ": " + GMTestPlayNames(ent.GetInventory(), category, max));
}

// Merchants (W3MerchantNPC) within range: name, tags count, position, distance, items.
exec function gmtest_merchants(optional range : float)
{
	var ents : array<CGameplayEntity>;
	var m : W3MerchantNPC;
	var i : int;

	if(range <= 0)
		range = 500;
	FindGameplayEntitiesInRange(ents, thePlayer, range, 200, '', 0, NULL, 'W3MerchantNPC');
	for(i = 0; i < ents.Size(); i += 1)
	{
		m = (W3MerchantNPC)ents[i];
		if(m)
			LogChannel('GMTest', "INFO merchant " + i + ": " + m.GetDisplayName(false) + " voice " + m.GetVoicetag() + " at " + VecToString(m.GetWorldPosition()) + ", " + RoundMath(VecDistance(m.GetWorldPosition(), thePlayer.GetWorldPosition())) + " m, items " + m.GetInventory().GetItemCount()
				+ ", herbalist " + m.GetInventory().HasTag('type_herbalist'));
	}
}

// Tags the index-th merchant of gmtest_merchants (same range) and brings Geralt 2 m in front of it.
exec function gmtest_merchantgo(index : int, tag : name, optional range : float)
{
	var ents : array<CGameplayEntity>;
	var m : CEntity;
	var pos : Vector;

	if(range <= 0)
		range = 500;
	FindGameplayEntitiesInRange(ents, thePlayer, range, 200, '', 0, NULL, 'W3MerchantNPC');
	if(index >= ents.Size())
		return;
	m = ents[index];
	m.AddTag(tag);
	pos = m.GetWorldPosition() + m.GetHeadingVector() * 2;
	thePlayer.TeleportWithRotation(pos, VecToRotation(m.GetWorldPosition() - pos));
	LogChannel('GMTest', "INFO tagged merchant " + index + " as " + tag);
}

// Opens the shop of an NPC as ShowMeGoods does (the Merchant tag, the inventory balanced, the inventory
// menu in shop mode).
exec function gmtest_shopopen(tag : name)
{
	var initData : W3InventoryInitData;
	var npc : CNewNPC;

	npc = theGame.GetNPCByTag(tag);
	if(!npc)
	{
		LogChannel('GMTest', "FAIL shopopen: no NPC " + tag);
		return;
	}
	if(!npc.HasTag('Merchant'))
		npc.AddTag('Merchant');
	npc.GetInventory().AutoBalanaceItemsWithPlayerLevel();
	initData = new W3InventoryInitData in theGame.GetGuiManager();
	initData.containerNPC = npc;
	theGame.GetGuiManager().SetLastOpenedCommonMenuName('None');
	theGame.RequestMenuWithBackground('InventoryMenu', 'CommonMenu', initData);
	LogChannel('GMTest', "INFO shop of " + tag + " opened: " + npc.GetInventory().GetItemCount() + " kinds after balancing");
}

// Opens the crafting menu of a craftsman as ShowCraftingPanel does.
exec function gmtest_craftopen(tag : name)
{
	var initData : W3InventoryInitData;
	var npc : W3MerchantNPC;

	npc = (W3MerchantNPC)theGame.GetNPCByTag(tag);
	if(!npc)
	{
		LogChannel('GMTest', "FAIL craftopen: no merchant " + tag);
		return;
	}
	npc.SetCraftingEnabled(true);
	initData = new W3InventoryInitData in theGame.GetGuiManager();
	initData.containerNPC = npc;
	theGame.GetGuiManager().SetLastOpenedCommonMenuName('None');
	theGame.RequestMenuWithBackground('CraftingMenu', 'CommonMenu', initData);
}

// Opens a smith's menu (repair, sockets, disassemble) with the given state.
exec function gmtest_smithopen(tag : name, optional menuState : name)
{
	var initData : W3InventoryInitData;
	var npc : CNewNPC;

	npc = theGame.GetNPCByTag(tag);
	if(!npc)
	{
		LogChannel('GMTest', "FAIL smithopen: no NPC " + tag);
		return;
	}
	if(!IsNameValid(menuState))
		menuState = 'Disassemble';
	initData = new W3InventoryInitData in theGame.GetGuiManager();
	initData.containerNPC = npc;
	initData.setDefaultState(menuState);
	theGame.GetGuiManager().SetLastOpenedCommonMenuName('None');
	theGame.RequestMenuWithBackground('BlacksmithMenu', 'CommonMenu', initData);
}

// Opens the alchemy menu (no NPC, as from the character's menus).
exec function gmtest_alchopen()
{
	theGame.RequestMenuWithBackground('AlchemyMenu', 'CommonMenu');
}

function GMTestPlayMenu() : CR4MenuBase
{
	var root : CR4MenuBase;

	root = (CR4MenuBase)theGame.GetGuiManager().GetRootMenu();
	if(!root)
		return NULL;
	return (CR4MenuBase)root.GetLastChild();
}

exec function gmtest_menuclose()
{
	var root : CR4MenuBase;

	root = (CR4MenuBase)theGame.GetGuiManager().GetRootMenu();
	if(root)
		root.CloseMenu();
}

// Crafts a schematic through the open crafting menu (its OnCraftItem event, what the Craft button calls).
exec function gmtest_menucraft(schematic : name)
{
	var menu : CR4CraftingMenu;
	var schem : SCraftingSchematic;
	var inv : CInventoryComponent;
	var before, money : int;

	menu = (CR4CraftingMenu)GMTestPlayMenu();
	if(!menu)
	{
		LogChannel('GMTest', "FAIL menucraft: the crafting menu is not open");
		return;
	}
	inv = thePlayer.GetInventory();
	schem = getCraftingSchematicFromName(schematic);
	before = inv.GetItemQuantityByName(schem.craftedItemName);
	money = inv.GetMoney();
	menu.OnCraftItem(schematic);
	GMTestReport(inv.GetItemQuantityByName(schem.craftedItemName) == before + 1,
		"crafting " + schematic + " in the menu: " + schem.craftedItemName + " " + before + " -> " + inv.GetItemQuantityByName(schem.craftedItemName) + ", crowns " + money + " -> " + inv.GetMoney());
}

// Brews a recipe through the open alchemy menu (its OnCraftItem event).
exec function gmtest_menubrew(recipe : name)
{
	var menu : CR4AlchemyMenu;
	var rec : SAlchemyRecipe;
	var inv : CInventoryComponent;
	var before, i : int;
	var s : string;

	menu = (CR4AlchemyMenu)GMTestPlayMenu();
	if(!menu)
	{
		LogChannel('GMTest', "FAIL menubrew: the alchemy menu is not open");
		return;
	}
	inv = thePlayer.GetInventory();
	rec = getAlchemyRecipeFromName(recipe);
	before = inv.GetItemQuantityByName(rec.cookedItemName);
	menu.OnCraftItem(recipe);
	for(i = 0; i < rec.requiredIngredients.Size(); i += 1)
		s += NameToString(rec.requiredIngredients[i].itemName) + " " + inv.GetItemQuantityByName(rec.requiredIngredients[i].itemName) + "; ";
	GMTestReport(inv.GetItemQuantityByName(rec.cookedItemName) > before,
		"brewing " + recipe + " in the menu: " + rec.cookedItemName + " " + before + " -> " + inv.GetItemQuantityByName(rec.cookedItemName) + "; ingredients left: " + s);
}

@addMethod(CR4BlacksmithMenu)
function GMTestSetDisassembleQuantity(q : int)
{
	m_lastConfirmedDisassembleQuantity = q;
}

// Dismantles one item of Geralt's through the open smith menu (OnDisassembleItem, what the confirmed
// Disassemble action calls, with no fee), logging every part received.
exec function gmtest_menudismantle(item : name)
{
	var menu : CR4BlacksmithMenu;
	var inv : CInventoryComponent;
	var ids : array<SItemUniqueId>;
	var parts : array<SItemParts>;
	var before : array<int>;
	var i : int;
	var s : string;

	menu = (CR4BlacksmithMenu)GMTestPlayMenu();
	if(!menu)
	{
		LogChannel('GMTest', "FAIL menudismantle: the smith menu is not open");
		return;
	}
	inv = thePlayer.GetInventory();
	ids = inv.GetItemsByName(item);
	if(ids.Size() == 0)
	{
		LogChannel('GMTest', "FAIL menudismantle: Geralt has no " + item);
		return;
	}
	parts = inv.GetItemRecyclingParts(ids[0]);
	for(i = 0; i < parts.Size(); i += 1)
		before.PushBack(inv.GetItemQuantityByName(parts[i].itemName));
	menu.GMTestSetDisassembleQuantity(1);
	menu.OnDisassembleItem(ids[0], 0);
	for(i = 0; i < parts.Size(); i += 1)
		s += NameToString(parts[i].itemName) + " +" + (inv.GetItemQuantityByName(parts[i].itemName) - before[i]) + " (of " + parts[i].quantity + "); ";
	LogChannel('GMTest', "INFO dismantled " + item + ": " + s + item + " left " + inv.GetItemQuantityByName(item));
}

// Buys one of an item from the open shop (the shop menu's OnBuyItem, what buying with a click calls).
exec function gmtest_menubuy(tag : name, item : name)
{
	var menu : CR4InventoryMenu;
	var npc : CNewNPC;
	var ids : array<SItemUniqueId>;
	var inv : CInventoryComponent;
	var before, money, stock : int;

	menu = (CR4InventoryMenu)GMTestPlayMenu();
	npc = theGame.GetNPCByTag(tag);
	if(!menu || !npc)
	{
		LogChannel('GMTest', "FAIL menubuy: no shop menu or no NPC " + tag);
		return;
	}
	ids = npc.GetInventory().GetItemsByName(item);
	if(ids.Size() == 0)
	{
		LogChannel('GMTest', "FAIL menubuy: " + tag + " has no " + item);
		return;
	}
	inv = thePlayer.GetInventory();
	before = inv.GetItemQuantityByName(item);
	money = inv.GetMoney();
	stock = npc.GetInventory().GetItemQuantityByName(item);
	menu.OnBuyItem(ids[0], 1, -1);
	GMTestReport(inv.GetItemQuantityByName(item) == before + 1 && inv.GetMoney() < money,
		"bought " + item + " from " + tag + ": Geralt " + before + " -> " + inv.GetItemQuantityByName(item) + ", crowns " + money + " -> " + inv.GetMoney() + ", merchant's stock " + stock + " -> " + npc.GetInventory().GetItemQuantityByName(item));
}

// Kills every NPC with the tag through the game's death path (Geralt the killer).
exec function gmtest_killtag(tag : name)
{
	var ents : array<CEntity>;
	var i, n : int;

	theGame.GetEntitiesByTag(tag, ents);
	for(i = 0; i < ents.Size(); i += 1)
		if((CNewNPC)ents[i] && ((CNewNPC)ents[i]).IsAlive())
		{
			((CNewNPC)ents[i]).Kill('GMTest', true, thePlayer);
			n += 1;
		}
	LogChannel('GMTest', "INFO killed " + n + " " + tag);
}

// The loot every NPC with the tag holds (dead monsters: their drop), summed over all of them.
exec function gmtest_loottag(tag : name)
{
	var ents : array<CEntity>;
	var ids : array<SItemUniqueId>;
	var names : array<name>;
	var counts : array<int>;
	var inv : CInventoryComponent;
	var i, k, idx, withLoot : int;
	var s : string;

	theGame.GetEntitiesByTag(tag, ents);
	for(i = 0; i < ents.Size(); i += 1)
	{
		inv = ((CGameplayEntity)ents[i]).GetInventory();
		if(!inv)
			continue;
		inv.GetAllItems(ids);
		if(ids.Size() > 0)
			withLoot += 1;
		for(k = 0; k < ids.Size(); k += 1)
		{
			idx = names.FindFirst(inv.GetItemName(ids[k]));
			if(idx < 0)
			{
				names.PushBack(inv.GetItemName(ids[k]));
				counts.PushBack(inv.GetItemQuantity(ids[k]));
			}
			else
				counts[idx] += inv.GetItemQuantity(ids[k]);
		}
	}
	for(i = 0; i < names.Size(); i += 1)
		s += NameToString(names[i]) + " x" + counts[i] + "; ";
	LogChannel('GMTest', "INFO loot of " + ents.Size() + " " + tag + " (" + withLoot + " holding items): " + s);
}

// Removes every entity with the tag.
exec function gmtest_cleartag(tag : name)
{
	var ents : array<CEntity>;
	var i : int;

	theGame.GetEntitiesByTag(tag, ents);
	for(i = 0; i < ents.Size(); i += 1)
		ents[i].Destroy();
}

// Containers (W3Container) within range, with what they hold now.
exec function gmtest_containers(optional range : float)
{
	var ents : array<CGameplayEntity>;
	var i : int;

	if(range <= 0)
		range = 60;
	FindGameplayEntitiesInRange(ents, thePlayer, range, 50, '', 0, NULL, 'W3Container');
	for(i = 0; i < ents.Size(); i += 1)
		LogChannel('GMTest', "INFO container " + i + ": " + ents[i].GetName() + " at " + VecToString(ents[i].GetWorldPosition()) + ", " + RoundMath(VecDistance(ents[i].GetWorldPosition(), thePlayer.GetWorldPosition())) + " m, items: "
			+ GMTestPlayNames(ents[i].GetInventory(), '', 12));
}

// Opens the index-th container of gmtest_containers as Geralt's interaction does, then lists it.
exec function gmtest_containeropen(index : int, optional range : float)
{
	var ents : array<CGameplayEntity>;
	var c : W3Container;
	var pos : Vector;

	if(range <= 0)
		range = 60;
	FindGameplayEntitiesInRange(ents, thePlayer, range, 50, '', 0, NULL, 'W3Container');
	if(index >= ents.Size())
		return;
	c = (W3Container)ents[index];
	c.AddTag('gmplay_container');
	pos = c.GetWorldPosition() + c.GetHeadingVector() * 1.2;
	thePlayer.TeleportWithRotation(pos, VecToRotation(c.GetWorldPosition() - pos));
	c.OnInteraction("Container", thePlayer);
	LogChannel('GMTest', "INFO opened container " + index + " (" + c.GetName() + "): " + GMTestPlayNames(c.GetInventory(), '', 20));
}

// Static map pins of the current world whose type contains the text (e.g. "Herbalist", "Blacksmith").
exec function gmtest_pins(pinType : string)
{
	var pins : array<SEntityMapPinInfo>;
	var i : int;

	pins = theGame.GetCommonMapManager().GetEntityMapPins(theGame.GetWorld().GetDepotPath());
	for(i = 0; i < pins.Size(); i += 1)
		if(StrFindFirst(NameToString(pins[i].entityType), pinType) >= 0)
			LogChannel('GMTest', "INFO pin " + pins[i].entityType + " " + pins[i].entityName + " at " + VecToString(pins[i].entityPosition));
}

// Adds a tag to the entity with a tag (e.g. the quest tag a spawned NPC carries in the world).
exec function gmtest_addtag(tag : name, newTag : name)
{
	var ent : CEntity;

	ent = theGame.GetEntityByTag(tag);
	if(ent)
		ent.AddTag(newTag);
	LogChannel('GMTest', "INFO " + tag + " tagged " + newTag + ": " + (ent && ent.HasTag(newTag)));
}

// Sends a navigation code to the open inventory as its Flash does for a key press (OnInputHandled), e.g.
// "enter-gamepad_A", the input of the selected item's primary action (E, Space).
exec function gmtest_menuinput(navCode : string)
{
	var menu : CR4InventoryMenu;

	menu = (CR4InventoryMenu)GMTestPlayMenu();
	if(!menu)
	{
		LogChannel('GMTest', "FAIL menuinput: the inventory is not open");
		return;
	}
	menu.OnInputHandled(navCode, 0, 0);
	LogChannel('GMTest', "INFO input " + navCode + " sent to the inventory");
}

// Restocks a spawned merchant (by tag) rolls times from its own loot lists, as a shop does (the inventory
// emptied, UpdateLoot, AutoBalanaceItemsWithPlayerLevel), and logs the kinds of each roll and every kind
// seen. Used for the 62-kinds-per-roll question (CRAFT/LOOT audit F6).
exec function gmtest_merchantroll(tag : name, optional rolls : int)
{
	var ent : CGameplayEntity;
	var inv : CInventoryComponent;
	var ids : array<SItemUniqueId>;
	var seen : array<name>;
	var i, k : int;
	var s : string;

	ent = (CGameplayEntity)theGame.GetEntityByTag(tag);
	if(!ent)
	{
		LogChannel('GMTest', "FAIL merchantroll: no entity " + tag);
		return;
	}
	if(rolls <= 0)
		rolls = 1;
	inv = ent.GetInventory();
	for(k = 0; k < rolls; k += 1)
	{
		inv.RemoveAllItems();
		inv.UpdateLoot();
		inv.AutoBalanaceItemsWithPlayerLevel();
		inv.GetAllItems(ids);
		LogChannel('GMTest', "INFO " + tag + " roll " + (k + 1) + ": " + ids.Size() + " kinds (level " + thePlayer.GetLevel() + ")");
		for(i = 0; i < ids.Size(); i += 1)
			if(!seen.Contains(inv.GetItemName(ids[i])))
				seen.PushBack(inv.GetItemName(ids[i]));
	}
	for(i = 0; i < seen.Size(); i += 1)
		s += NameToString(seen[i]) + "; ";
	LogChannel('GMTest', "INFO " + tag + " " + seen.Size() + " kinds in " + rolls + " rolls: " + s);
}
