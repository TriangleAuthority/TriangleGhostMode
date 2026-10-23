// Ghost Mode: dismantle kits (CRAFT-09, legacy, changelist 688-690, 864-865). In Geralt's inventory, a
// junk item or crafting component with dismantling parts gets a "Dismantle" input (E) while he carries an
// Item dismantle kit, an alchemy ingredient (named mutagens among them) while he carries an Alchemy
// dismantle kit; dismantling gives every part (CRAFT-08) and uses one kit. Gear cannot be dismantled with
// a kit. The kits are items of Ghost Mode's DLC (gm_item.xml, from legacy's def_item_alchemy_repair_kits.xml).
// The razor keeps its own "Use" input (UI-15, ui/shaving.ws). See docs/features/craft.md.

// The kit that dismantles an item ('' if none applies or Geralt has none; legacy's conditions).
@addMethod(CInventoryComponent)
function GMDismantleKitFor(id : SItemUniqueId) : name
{
	var isAlchemy, isCrafting : bool;

	if(!IsIdValid(id) || GetItemName(id) == 'Razor' || !GMItemHasRecyclingParts(id))
		return '';
	isAlchemy = IsItemAlchemyIngredient(id);
	isCrafting = IsItemCraftingIngredient(id) || IsItemJunk(id);
	if(!isAlchemy && !isCrafting)
		return '';
	if(isAlchemy && GetItemQuantityByName('alchemy_dismantle_kit_1') < 1)
		return '';
	if(isCrafting && GetItemQuantityByName('gear_dismantle_kit_1') < 1)
		return '';
	if(isAlchemy)
		return 'alchemy_dismantle_kit_1';
	return 'gear_dismantle_kit_1';
}

@wrapMethod(W3InventoryGridContext)
function updateInputFeedback()
{
	wrappedMethod();
	if(invMenuRef && invComponentRef && invMenuRef.GetCurrentInventoryState() == IMS_Player && invComponentRef.GMDismantleKitFor(currentItemId) != '')
	{
		AddInputBinding("panel_button_hud_interaction_dismantle", "enter-gamepad_A", IK_E, true);
		m_managerRef.updateInputFeedback();
	}
}

@wrapMethod(W3InventoryGridContext)
function execurePrimaryAction()
{
	if(invMenuRef && invComponentRef && invMenuRef.GetCurrentInventoryState() == IMS_Player && invComponentRef.GMDismantleKitFor(currentItemId) != '')
	{
		invMenuRef.GMPlayerDismantleItem(currentItemId);
		UpdateContext();
		return;
	}
	wrappedMethod();
}

// Legacy's CR4InventoryMenu.PlayerDismantleItem: dismantles one item with the kit that applies (every
// part, as an Arch Master), uses the kit and refreshes the menu.
@addMethod(CR4InventoryMenu)
function GMPlayerDismantleItem(currentItemId : SItemUniqueId)
{
	var invComp : CInventoryComponent;
	var kit : name;

	invComp = _playerInv.GetInventoryComponent();
	kit = invComp.GMDismantleKitFor(currentItemId);
	if(kit == '')
		return;

	invComp.RecycleItem(currentItemId, ECL_Arch_Master);
	invComp.RemoveItemByName(kit, 1);

	UpdateItemsCounter();
	UpdatePlayerStatisticsData();
	UpdateEncumbranceInfo();
	PopulateTabData(InventoryMenuTab_Weapons);
	PopulateTabData(InventoryMenuTab_Potions);
	PopulateTabData(InventoryMenuTab_Ingredients);
	PopulateTabData(InventoryMenuTab_QuestItems);
	PopulateTabData(InventoryMenuTab_Default);
	PopulateTabData(InventoryMenuTab_Books);
}
