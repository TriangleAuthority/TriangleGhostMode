// ITEM-11: repair kits and the master kits, as legacy. See docs/features/item.md. The kits' values
// (10/20/30%, quality 1/2/3) and the master kits (weapon_repair_kit_4, armor_repair_kit_4: quality 4,
// a full repair and one more level's damage or armor) are data (gm_item.xml). Any item with durability
// takes a kit, at full durability too; an item whose new level is above Geralt's is unequipped, in combat
// too. Where the master kits are sold is CRAFT's and LOOT's (DI6).

@replaceMethod(W3PlayerWitcher)
function RepairItem (  rapairKitId : SItemUniqueId, usedOnItem : SItemUniqueId )
{
	var itemMaxDurablity 		: float;
	var itemCurrDurablity 		: float;
	var baseRepairValue		  	: float;
	var reapirValue				: float;
	var itemAttribute			: SAbilityAttributeValue;

	itemMaxDurablity = inv.GetItemMaxDurability(usedOnItem);
	itemCurrDurablity = inv.GetItemDurability(usedOnItem);
	itemAttribute = inv.GetItemAttributeValue ( rapairKitId, 'repairValue' );

	//modSigns: removed the refusal at full durability (a master kit still adds a level)

	if ( inv.IsItemAnyArmor ( usedOnItem )|| inv.IsItemWeapon( usedOnItem ) )
	{

		baseRepairValue = itemMaxDurablity * itemAttribute.valueMultiplicative;
		reapirValue = MinF( itemCurrDurablity + baseRepairValue, itemMaxDurablity );

		inv.SetItemDurabilityScript ( usedOnItem, MinF ( reapirValue, itemMaxDurablity ));
		if( inv.ItemHasTag( rapairKitId, 'ArmorReapairKit_Master' ) || inv.ItemHasTag( rapairKitId, 'WeaponReapairKit_Master' ) )	//modSigns: master kits raise the item's level
			inv.GMAddItemLevelAbility( usedOnItem );	//modSigns
	}

	inv.RemoveItem ( rapairKitId, 1 );

}

@replaceMethod(W3PlayerWitcher)
function IsItemRepairAble ( item : SItemUniqueId ) : bool
{
	return inv.HasItemDurability(item);	//modSigns: any item with durability, at full durability too
}

@replaceMethod(CR4InventoryMenu)
function ApplyRepairKit(itemId : SItemUniqueId,  targetSlot : int) : void
{
	var curItemInSlot : SItemUniqueId;
	
	OnPlaySoundEvent("gui_inventory_repair");
	
	if (_inv.GetItemEquippedOnSlot(targetSlot, curItemInSlot))
	{
		GetWitcherPlayer().RepairItem (itemId, curItemInSlot);
		if (_inv.IsIdValid(itemId) && _inv.GetItemQuantity( itemId ) > 0)
		{
			InventoryUpdateItem(itemId);
		}
		else
		{
			InventoryRemoveItem(itemId);
		}
		if( !thePlayer.HasRequiredLevelToEquipItem( curItemInSlot ) )	//modSigns: unequip an item now above Geralt's level, in combat too
		{	//modSigns
			gmForceUnequip = true;	//modSigns
			UnequipItem( curItemInSlot, -1 );	//modSigns
			gmForceUnequip = false;	//modSigns
		}	//modSigns
		else	//modSigns
		{	//modSigns
		PaperdollUpdateItem(curItemInSlot);
		}	//modSigns
	}
	else
	{
		return;
	}
}

// ITEM-11: legacy's forced unequip. Legacy gave UnequipItem an optional forceUnequip that skips the
// combat refusal, and ApplyRepairKit passed it; here a field does it (a replaced method keeps its
// signature). 5.x's quest lock (AreManualEquipmentChangesBlocked), which legacy did not have, still
// refuses (porter's call).
@addField(CR4InventoryMenu)
var gmForceUnequip : bool;

@replaceMethod(CR4InventoryMenu)
function UnequipItem( item : SItemUniqueId, moveToIndex : int ) : bool
{
	var forceInvAllUpdate : bool;
	var isSetBonusActive  : bool;
	
	var filterType 	   : EInventoryFilterType;
	var itemOnSlot 	   : SItemUniqueId;
	var crossbowOnSlot : SItemUniqueId;
	var horseItem 	   : SItemUniqueId;
	var slot 		   : EEquipmentSlots;
	var itemsList      : array<SItemUniqueId>;
	var gridUpdateList : array<SItemUniqueId>;
	var abls	       : array<name>;
	var i, targetSlot  : int;
	
	forceInvAllUpdate = false;

	if (AreManualEquipmentChangesBlocked())
	{
		ShowEquipmentChangeBlockedFeedback();
		return false;
	}
	
	if (thePlayer.IsInCombat() && !gmForceUnequip)	//modSigns: ITEM-11, a master kit's forced unequip passes in combat (legacy's forceUnequip)
	{
		showNotification(GetLocStringByKeyExt("menu_cannot_perform_action_combat"));
		OnPlaySoundEvent("gui_global_denied");
		return false;
	}
	
	if ( _horsePaperdollInv.GetInventoryComponent().IsIdValid(item) && _horsePaperdollInv.isHorseItem(item))
	{
		slot = _horsePaperdollInv.GetInventoryComponent().GetSlotForItemId(item);
		horseItem = GetWitcherPlayer().GetHorseManager().UnequipItem(slot);
		
		PlayItemUnequipSound( _inv.GetItemCategory(horseItem) );
		
		m_fxInventoryUpdateFilter.InvokeSelfOneArg( FlashArgUInt( GetTabIndexForSlot(slot) ));
		
		InventoryUpdateItem(horseItem);
		
		PaperdollUpdateAll(); 
		
		UpdateEncumbranceInfo();
		
		
		
		
		PlayItemUnequipSound( _horsePaperdollInv.GetInventoryComponent().GetItemCategory(item) );
		
		return true; 
	}
	
	if( _containerInv )
	{
		GiveItem(item, 1);
		UpdateContainer();
		
		InventoryUpdateItem(item);
		PaperdollRemoveItem(item);
		UpdatePlayerStatisticsData();
	}
	else if (_inv.IsIdValid(item))
	{
		if (_inv.IsItemBolt(item) && _inv.ItemHasTag(item,theGame.params.TAG_INFINITE_AMMO))
		{
			return false;
		}
		
		LogChannel('ITEMDRAG'," OnUnequipItem "+_playerInv.GetItemName(item)+" moveToIndex "+moveToIndex);
		if( moveToIndex > -1 )
		{
			_playerInv.MoveItem( item , moveToIndex );
		}
		
		PlayItemUnequipSound( _inv.GetItemCategory(item) );
		
		if (_inv.IsItemCrossbow(item) && GetWitcherPlayer().GetItemEquippedOnSlot(EES_Bolt,itemOnSlot))
		{
			_playerInv.UnequipItem( itemOnSlot );
			PaperdollRemoveItem(itemOnSlot);

			if (!_inv.ItemHasTag(itemOnSlot,theGame.params.TAG_INFINITE_AMMO))
			{
				forceInvAllUpdate = true;
			}
		}

		
		isSetBonusActive = GetWitcherPlayer().IsSetBonusActive( EISB_RedWolf_2 );
		
		targetSlot = _inv.GetSlotForItemId( item );
		ResetDisplayPreviewCache( item, slot, gridUpdateList );
		
		_playerInv.UnequipItem( item );
		filterType = _playerInv.GetFilterTypeByItem(item);
		_playerInv.SetFilterType( filterType );
		UpdateInventoryFilter(filterType);


		
		if (_inv.IsItemSetItem(item) && isSetBonusActive)
		{
			PushIfItemEquipped(itemsList, EES_Petard1);
			PushIfItemEquipped(itemsList, EES_Petard2);
			PushIfItemEquipped(itemsList, EES_Quickslot1);
			PushIfItemEquipped(itemsList, EES_Quickslot2);
			PushIfItemEquipped(itemsList, EES_Potion1);
			PushIfItemEquipped(itemsList, EES_Potion2);
			PushIfItemEquipped(itemsList, EES_Potion3);
			PushIfItemEquipped(itemsList, EES_Potion4);
			
			PopulateTabData(InventoryMenuTab_Potions);
		}
		
		if (forceInvAllUpdate)
		{
			PopulateTabData(getTabFromItem(item));
		}
		else
		{
			gridUpdateList.PushBack( item );
		}
		
		if (_inv.GetEnchantment(item) == 'Runeword 6')
		{
			AddEquippedPotionsToList(itemsList);
		}
		
		PaperdollRemoveItem(item);
		
		if(_inv.IsItemBolt(item) && GetWitcherPlayer().GetItemEquippedOnSlot(EES_Bolt, itemOnSlot))
		{
			itemsList.PushBack(itemOnSlot);
		}
		
		PaperdollUpdateItemsList(itemsList);
		
		UpdatePlayerStatisticsData();
	}
	
	if( gridUpdateList.Size() > 0 )
	{
		InventoryUpdateItems( gridUpdateList );
	}
	
	UpdateEncumbranceInfo();
	UpdateGuiSceneEntityItems();
	
		
	switch (_inv.GetItemCategory( item ))
		{
		case 'steelsword':
			m_player.RaiseEvent('RemoveSteelSword_Inv');
			break;
		case 'silversword':
			m_player.RaiseEvent('RemoveSilverSword_Inv');
			break;
		case 'crossbow':
			m_player.RaiseEvent('RemoveCrossbow_Inv');
			break;
		default:
			break;
		}
	
	return true;
}
