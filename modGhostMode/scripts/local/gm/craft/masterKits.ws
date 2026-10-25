// Ghost Mode: Yoana's master stock (CRAFT-10 with LOOT-04, legacy, changelist 611, 633). Once Geralt has
// helped her (fact sq108_master_bsmith_helped), Yoana's shop also stocks the list
// _store__Master_Armorsmith_Yoana: the master armorsmith tools and her master schematics (the four
// craftable quest armors' among them, CRAFT-04). The other master kits are in the shop lists of Hattori,
// the Hearts of Stone enchanter and Blood and Wine's archmaster (the whole-file loot overrides, LOOT-04).
// See docs/features/craft.md and loot.md.

// Legacy's CInventoryComponent.AddMasterArmorerItems, which queued the list with AddItemsFromLootDefinition
// at every opening of her shop. On 5.x that engine call, repeated on one inventory, crashes the game
// (her shop at about its 15th opening in one launch, 2026-10-24), so the port adds the list's entries
// itself: each entry's item, from its level gate (player_level_min; every entry has chance -1, always),
// except a schematic Geralt knows (the engine's list skips those, seen 2026-10-24), topped up to the
// entry's quantity (quantity_min to quantity_max) when she holds fewer than quantity_min.
// Her stock is the stock one roll of legacy's list gives and no longer grows at each opening (a deviation
// confirmed by the owner, 2026-10-24). The list stays in def_loot_shops.xml (items and items_plus, the same
// entries) with LOOT-04; keep the two in step.
@addMethod(CInventoryComponent)
function GMAddMasterArmorerItems()
{
	if(FactsDoesExist("sq108_master_bsmith_helped"))
	{
		GMAddMasterStockEntry('Horse Blinder 2', 10, 1, 1);
		GMAddMasterStockEntry('Horse Bag 2', 10, 1, 1);
		GMAddMasterStockEntry('Light Armor 5 schematic', 18, 1, 1);
		GMAddMasterStockEntry('Thyssen Armor schematic', 13, 1, 1);
		GMAddMasterStockEntry('Oathbreaker Armor schematic', 14, 1, 1);
		GMAddMasterStockEntry('Relic Heavy 3 schematic', 13, 1, 1);
		GMAddMasterStockEntry('Gloves 4 schematic', 12, 1, 1);
		GMAddMasterStockEntry('Heavy Gloves 4 schematic', 15, 1, 1);
		GMAddMasterStockEntry('Pants 4 schematic', 13, 1, 1);
		GMAddMasterStockEntry('Heavy Pants 4 schematic', 14, 1, 1);
		GMAddMasterStockEntry('Boots 7 schematic', 14, 1, 1);
		GMAddMasterStockEntry('Heavy Boots 7 schematic', 13, 1, 1);
		GMAddMasterStockEntry('Heavy Boots 8 schematic', 16, 1, 1);
		GMAddMasterStockEntry('q108 Light Armor 9 schematic', 0, 1, 1);
		GMAddMasterStockEntry('q108 Medium Armor 3 schematic', 0, 1, 1);
		GMAddMasterStockEntry('q108 Heavy Armor 4 schematic', 0, 1, 1);
		GMAddMasterStockEntry('armor_repair_kit_4', 0, 10, 20);
		GMAddMasterStockEntry('gear_dismantle_kit_1', 0, 10, 20);
	}
}

// One entry of _store__Master_Armorsmith_Yoana.
@addMethod(CInventoryComponent)
function GMAddMasterStockEntry(item : name, levelMin : int, quantityMin : int, quantityMax : int)
{
	var held, quantity : int;
	var known : array<name>;

	if(thePlayer.GetLevel() < levelMin)
		return;
	if(GetWitcherPlayer())
	{
		known = GetWitcherPlayer().GetCraftingSchematicsNames();
		if(known.Contains(item))
			return;
	}
	held = GetItemQuantityByName(item);
	if(held >= quantityMin)
		return;
	quantity = RandRange(quantityMax + 1, quantityMin);
	AddAnItem(item, quantity - held);
}

// Legacy called it in the storyscene function ShowMeGoods for the merchant tagged sq108_blacksmith_woman,
// right before the shop's AutoBalanaceItemsWithPlayerLevel; ShowMeGoods (a latent storyscene function)
// stays 5.x's and this wrapper adds the call for Yoana's inventory. The only other caller, a container's
// OnInteraction, never runs on Yoana.
@wrapMethod(CInventoryComponent)
function AutoBalanaceItemsWithPlayerLevel()
{
	var owner : CEntity;

	owner = GetEntity();
	if(owner && owner.HasTag('sq108_blacksmith_woman'))
	{
		GMAddMasterArmorerItems();
	}
	wrappedMethod();
}
