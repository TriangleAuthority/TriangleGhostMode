// ARM-14 (with ARM-05): the set lines of item tooltips. The counter shows the pieces of the item's
// own tier group; with lower-tier and grandmaster pieces mixed, the first bonus line shows the
// set's total; the set is read by item name, so items in the stash and in shops show it too
// (legacy's fix, changelist 106). The Viper set is shown since ARM-11 gave it its bonus (5.x hid it).
// ARM-04: a piece of a generic set shows the set's line with its count (legacy returns false then too).
@replaceMethod(W3TooltipComponent)
function AddSetAttributes( itemId : SItemUniqueId, itemInvComponent : CInventoryComponent, out flashDataObj : CScriptedFlashObject ):bool
{
	var setAttributesList : CScriptedFlashArray;
	var setAttribute  	  : CScriptedFlashObject;
	var currentCount	  : int;
	var requiredCount	  : int;
	var activationCount	  : int;	//modSigns
	var desc1			  : string;
	var desc2			  : string;
	var counterText		  : string;
	var isActive1		  : bool;
	var isActive2		  : bool;
	var setType			  : EItemSetType;

	setType = GetWitcherPlayer().GetSetBonusStatusByName( itemInvComponent.GetItemName( itemId ), desc1, desc2, isActive1, isActive2 );	//modSigns: by name

	if( setType != EIST_Undefined && itemInvComponent.ItemHasTag( itemId, theGame.params.ITEM_SET_TAG_BONUS ) )	//modSigns: ARM-11, the Viper set shown (it has a bonus); ARM-14, set lines only on set pieces (legacy, changelist 183)
	{
		currentCount = GetWitcherPlayer().GMGetSetPartsEquippedRaw( setType );	//modSigns
		requiredCount = GMGetNumItemsRequiredForFullSet( setType );	//modSigns
		activationCount = GMGetNumItemsRequiredForSetActivation( setType );	//modSigns

		counterText = currentCount + "/" + requiredCount;

		flashDataObj.SetMemberFlashString( "SetCounter", counterText);

		setAttributesList = flashDataObj.CreateFlashArray();

		//modSigns: removed the "not available yet" line (ARM-14: items without SetBonusPiece show no set block, legacy)

		if( isActive1 && GetWitcherPlayer().GMHasMixedSetsEquipped() )	//modSigns
			desc1 = "(" + GetWitcherPlayer().GetSetPartsEquipped( setType ) + "/" + requiredCount + ") " + desc1;	//modSigns

		setAttribute = flashDataObj.CreateFlashObject();
		setAttribute.SetMemberFlashString( "value", activationCount );	//modSigns
		setAttribute.SetMemberFlashString( "name", desc1 );
		setAttribute.SetMemberFlashBool( "active", isActive1 );
		setAttributesList.PushBackFlashObject( setAttribute );

		if( desc2 != "" && requiredCount != activationCount )	//modSigns
		{

			setAttribute = flashDataObj.CreateFlashObject();
			setAttribute.SetMemberFlashString( "value", requiredCount );	//modSigns
			setAttribute.SetMemberFlashString( "name", desc2 );
			setAttribute.SetMemberFlashBool( "active", isActive2 );
			setAttributesList.PushBackFlashObject( setAttribute );
		}

		flashDataObj.SetMemberFlashArray( "SetStatsList", setAttributesList );

		return true;
	}
	else if( itemInvComponent.GMIsSetArmorType( itemId ) )	//modSigns: ARM-04, the generic set line of an armor piece
	{	//modSigns
		activationCount = 4;	//modSigns
		currentCount = itemInvComponent.GMGetSetArmorItemDescription( itemId, counterText, desc1 );	//modSigns
		flashDataObj.SetMemberFlashString( "SetCounter", counterText );	//modSigns
		setAttributesList = flashDataObj.CreateFlashArray();	//modSigns
		setAttribute = flashDataObj.CreateFlashObject();	//modSigns
		setAttribute.SetMemberFlashString( "value", activationCount );	//modSigns
		setAttribute.SetMemberFlashString( "name", desc1 );	//modSigns
		setAttribute.SetMemberFlashBool( "active", currentCount == activationCount );	//modSigns
		setAttributesList.PushBackFlashObject( setAttribute );	//modSigns
		flashDataObj.SetMemberFlashArray( "SetStatsList", setAttributesList );	//modSigns
	}	//modSigns

	return false;
}

// ARM-14: the lower tiers of the school sets and the Kaer Morhen set are set items (legacy), so item
// tooltips and crafting show their set lines. 5.x body; changes marked //modSigns.
@replaceMethod(CInventoryComponent)
function IsItemSetItem(item : SItemUniqueId) : bool
{
	return
		ItemHasTag(item, theGame.params.ITEM_SET_TAG_BEAR) ||
		ItemHasTag(item, theGame.params.ITEM_SET_TAG_GRYPHON) ||
		ItemHasTag(item, theGame.params.ITEM_SET_TAG_LYNX) ||
		ItemHasTag(item, theGame.params.ITEM_SET_TAG_WOLF) ||
		ItemHasTag(item, theGame.params.ITEM_SET_TAG_RED_WOLF) ||
		ItemHasTag(item, theGame.params.ITEM_SET_TAG_VAMPIRE ) ||
		ItemHasTag(item, theGame.params.ITEM_SET_TAG_VIPER) ||
		ItemHasTag(item, 'KaerMorhenSet') ||	//modSigns
		ItemHasTag(item, 'BearSetMinor') ||	//modSigns
		ItemHasTag(item, 'GryphonSetMinor') ||	//modSigns
		ItemHasTag(item, 'LynxSetMinor') ||	//modSigns
		ItemHasTag(item, 'WolfSetMinor') ||	//modSigns

		ItemHasTag(item, theGame.params.ITEM_SET_TAG_NETFLIX);
}

// ARM-14: the same by item name. 5.x body; changes marked //modSigns.
@replaceMethod(CDefinitionsManagerAccessor)
function IsItemSetItem( itemName : name ) : bool
{
	return
		ItemHasTag(itemName, theGame.params.ITEM_SET_TAG_BEAR) ||
		ItemHasTag(itemName, theGame.params.ITEM_SET_TAG_GRYPHON) ||
		ItemHasTag(itemName, theGame.params.ITEM_SET_TAG_LYNX) ||
		ItemHasTag(itemName, theGame.params.ITEM_SET_TAG_WOLF) ||
		ItemHasTag(itemName, theGame.params.ITEM_SET_TAG_RED_WOLF) ||
		ItemHasTag(itemName, theGame.params.ITEM_SET_TAG_VAMPIRE ) ||
		ItemHasTag(itemName, theGame.params.ITEM_SET_TAG_VIPER) ||
		ItemHasTag(itemName, 'KaerMorhenSet') ||	//modSigns
		ItemHasTag(itemName, 'BearSetMinor') ||	//modSigns
		ItemHasTag(itemName, 'GryphonSetMinor') ||	//modSigns
		ItemHasTag(itemName, 'LynxSetMinor') ||	//modSigns
		ItemHasTag(itemName, 'WolfSetMinor') ||	//modSigns
		ItemHasTag(itemName, theGame.params.ITEM_SET_TAG_NETFLIX)

		;

}

// ARM-14 (ARM-04): a generic set's armor piece gets its set line too (5.x calls AddSetAttributes only
// for witcher set items; legacy's condition adds the generic sets).
// ARM-02 (DA7, audit F8): an armor piece's class is never shown as changed by Levity, Balance or Heft
// (5.x flags it for equipped pieces while one of them is on Geralt; legacy sets the flag false).
@wrapMethod(W3TooltipComponent)
function GetBaseItemData( item : SItemUniqueId, itemInvComponent : CInventoryComponent, optional isShopItem : bool, optional compareWithItem : SItemUniqueId, optional compareItemInv : CInventoryComponent ) : CScriptedFlashObject
{
	var tooltipData : CScriptedFlashObject;
	var category : name;

	tooltipData = wrappedMethod(item, itemInvComponent, isShopItem, compareWithItem, compareItemInv);
	if( tooltipData && itemInvComponent && !itemInvComponent.IsItemSetItem( item ) && itemInvComponent.GMIsSetArmorType( item ) )
		AddSetAttributes( item, itemInvComponent, tooltipData );
	if( tooltipData && itemInvComponent )
	{
		category = itemInvComponent.GetItemCategory( item );
		if( category == 'armor' || category == 'pants' || category == 'boots' || category == 'gloves' )
			tooltipData.SetMemberFlashBool( "hasEnchantedType", false );
	}
	return tooltipData;
}

// ARM-14: the set lines of a crafting schematic's item, as legacy: only set pieces (SetBonusPiece; the
// Blood and Wine relic sword schematics showed set colours, changelist 183), the first bonus alone when
// the set has one (Viper, Kaer Morhen), no "not available yet" line, and the generic set's line for a
// generic armor piece. Vanilla's lines are overwritten (they are flash members it has just set).
@wrapMethod(W3GuiPlayerInventoryComponent)
function GetCraftedItemInfo(craftedItemName:name, targetObject:CScriptedFlashObject) : void
{
	var dm : CDefinitionsManagerAccessor;
	var desc1, desc2, text1, text2 : string;
	var active1, active2 : bool;
	var params : array<string>;

	wrappedMethod(craftedItemName, targetObject);
	dm = theGame.GetDefinitionsManager();
	if( dm.IsItemSetItem( craftedItemName ) && dm.ItemHasTag( craftedItemName, 'SetBonusPiece' ) )
	{
		GetWitcherPlayer().GetSetBonusStatusByName( craftedItemName, desc1, desc2, active1, active2 );
		if( desc1 != "" )
		{
			params.PushBack( "3" );
			text1 = "<font color='#b7ae8c'>" + StrUpperUTF( GetLocStringByKeyExt( "crafting_bonus_title" ) ) + "</font><br/><br/>"
				+ "<font color='#9f977a'>" + GetLocStringByKeyExtWithParams( "crafting_bonus_set_title",,, params ) + ":</font><br/>"
				+ "<font color='#818181'>" + desc1 + "</font>";
			if( desc2 != "" )
			{
				params.Clear();
				params.PushBack( "6" );
				text2 = "<font color='#9f977a'>" + GetLocStringByKeyExtWithParams( "crafting_bonus_set_title",,, params ) + ":</font><br/>"
					+ "<font color='#818181'>" + desc2 + "</font>";
			}
		}
	}
	else if( _inv.GMIsSetArmorTypeByName( craftedItemName ) )
	{
		params.PushBack( "4" );
		text1 = "<font color='#b7ae8c'>" + StrUpperUTF( GetLocStringByKeyExt( "gm_crafting_bonus_title" ) ) + "</font><br/><br/>"
			+ "<font color='#9f977a'>" + GetLocStringByKeyExtWithParams( "crafting_bonus_set_title",,, params ) + ":</font><br/>"
			+ "<font color='#818181'>" + GMGetSetArmorDescriptionByType( _inv.GMGetArmorTypeByName( craftedItemName ) ) + "</font>";
	}
	targetObject.SetMemberFlashString( "SetBonusDescription", text1 );
	targetObject.SetMemberFlashString( "SetBonusDescription2", text2 );
}
