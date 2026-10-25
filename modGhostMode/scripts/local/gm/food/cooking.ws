// FOOD-07: cooking (the owner's DF8). Legacy's 27 cooking recipes (gm_food.xml, tools/gen_food.py) are
// alchemy recipes of a type of their own, "edibles": the alchemy menu lists them in their own group, titled
// by the item category "Edibles"; a dish is cooked in its recipe's quantity. Innkeepers and Blood and Wine's
// butcher sell the recipes (legacy's shop lists, gen_loot.py). Acquired Tolerance and 5.x's recipe counters
// do not count them (SKL-16's whitelist, 5.x's named types).
// See docs/features/food.md.

enum EAlchemyCookedItemType
{
	EACIT_Edibles
}

@wrapMethod
function AlchemyCookedItemTypeStringToEnum(nam : string) : EAlchemyCookedItemType
{
	if(nam == "edibles")
		return EACIT_Edibles;
	return wrappedMethod(nam);
}

@wrapMethod
function AlchemyCookedItemTypeEnumToName( type : EAlchemyCookedItemType) : name
{
	if(type == EACIT_Edibles)
		return 'edibles';
	return wrappedMethod(type);
}

@wrapMethod
function AlchemyCookedItemTypeToLocKey( type : EAlchemyCookedItemType ) : string
{
	if(type == EACIT_Edibles)
		return "item_category_edibles";
	return wrappedMethod(type);
}

// 5.x body (its oil re-applied to the sword kept: ALCH); changes marked //modSigns.
@replaceMethod(W3AlchemyManager)
function CookItem(recipeName : name)
{
	var i, j, quantity, removedIngQuantity, maxAmmo : int;
	var recipe : SAlchemyRecipe;
	var dm : CDefinitionsManagerAccessor;
	var crossbowID, sword : SItemUniqueId; 
	var min, max : SAbilityAttributeValue;
	var uiStateAlchemy : W3TutorialManagerUIHandlerStateAlchemy;
	var uiStateAlchemyMutagens : W3TutorialManagerUIHandlerStateAlchemyMutagens;
	var ids : array<SItemUniqueId>;
	var items, alchIngs  : array<SItemUniqueId>;
	var isPotion, isSingletonItem : bool;
	var witcher : W3PlayerWitcher;
	var equippedOnSlot : EEquipmentSlots;
	var itemName:name;
	
	GetRecipe(recipeName, recipe);
	
	witcher = GetWitcherPlayer(); 
	
	
	equippedOnSlot = EES_InvalidSlot;
	dm = theGame.GetDefinitionsManager();
	dm.GetItemAttributeValueNoRandom(recipe.cookedItemName, true, 'ammo', min, max);
	quantity = (int)CalculateAttributeValue(GetAttributeRandomizedValue(min, max));
	
	if(recipe.cookedItemType == EACIT_Bomb && GetWitcherPlayer().CanUseSkill(S_Alchemy_s08))
		quantity += GetWitcherPlayer().GetSkillLevel(S_Alchemy_s08);
	if( recipe.cookedItemType == EACIT_Edibles )	//modSigns: FOOD-07, a dish is cooked in its recipe's quantity (food has no ammo)
		quantity = recipe.cookedItemQuantity;	//modSigns
	
	
	isSingletonItem = dm.IsItemSingletonItem(recipe.cookedItemName);
	if(isSingletonItem && thePlayer.inv.GetItemQuantityByName(recipe.cookedItemName) > 0 )
	{
		items = thePlayer.inv.GetItemsByName(recipe.cookedItemName);
		
		if (items.Size() == 1 && thePlayer.inv.ItemHasTag(items[0], 'NoShow'))
		{
			thePlayer.inv.RemoveItemTag(items[i], 'NoShow');
		}
	}
	else
	{
		ids = thePlayer.inv.AddAnItem(recipe.cookedItemName, quantity);
		if(isSingletonItem)
		{
			maxAmmo = thePlayer.inv.SingletonItemGetMaxAmmo(ids[0]);
			for(i=0; i<ids.Size(); i+=1)
				thePlayer.inv.SingletonItemSetAmmo(ids[i], maxAmmo);
		}
	}
	
	
	for(i=0; i<recipe.requiredIngredients.Size(); i+=1)
	{
		itemName = recipe.requiredIngredients[i].itemName;
		
		
		
		if( dm.ItemHasTag( itemName, 'MutagenIngredient' ) )
		{
			thePlayer.inv.RemoveUnusedMutagensCount( itemName, recipe.requiredIngredients[i].quantity);
		}
		else if( dm.IsItemAlchemyItem( itemName ))
		{
			removedIngQuantity = 0;
			alchIngs = thePlayer.inv.GetItemsByName(itemName);
			
			for(j=0; j<alchIngs.Size(); j+=1)
			{
				equippedOnSlot = witcher.GetItemSlot(alchIngs[j]);
				
				if(equippedOnSlot != EES_InvalidSlot)
				{
					witcher.UnequipItem(alchIngs[j]);
				}
				
				removedIngQuantity += 1;
				witcher.inv.RemoveItem(alchIngs[j], 1);
				
				if(removedIngQuantity >= recipe.requiredIngredients[i].quantity)
					break;
			}
		}
		else
		{
			
			thePlayer.inv.RemoveItemByName(itemName, recipe.requiredIngredients[i].quantity);
		}
		
		
		if(recipe.cookedItemType == EACIT_Oil && recipe.level > 1 && thePlayer.inv.IsItemOil(ids[0]))
		{
			if( witcher.IsEquippedSwordUpgradedWithOil( false, recipe.requiredIngredients[i].itemName ) )
			{
				sword = thePlayer.GetEquippedSword( false );
				thePlayer.ApplyOil(ids[0], sword);
			}
			else if( witcher.IsEquippedSwordUpgradedWithOil( true, recipe.requiredIngredients[i].itemName ) )
			{
				sword = thePlayer.GetEquippedSword( true );
				thePlayer.ApplyOil(ids[0], sword);
			}
		}
		
	}
	
	RemoveLowerLevelItems(recipe);
	
	if( ids.Size() > 0  && thePlayer.inv.IsItemPotion( ids[0] ) )
	{
		isPotion = true;
	}
	else if( items.Size() > 0  && thePlayer.inv.IsItemPotion( items[0] ) )
	{
		isPotion = true;
	}
	else
	{
		isPotion = false;
	}
	
	if( isPotion )
	{
		theTelemetry.LogWithLabelAndValue( TE_ITEM_COOKED, recipe.cookedItemName, 1 );
	}
	else
	{
		theTelemetry.LogWithLabelAndValue( TE_ITEM_COOKED, recipe.cookedItemName, 0 );
	}
	
	
	if(equippedOnSlot != EES_InvalidSlot)
	{
		witcher.EquipItemInGivenSlot(ids[0], equippedOnSlot, false);
	}
	
	LogAlchemy("Item <<" + recipe.cookedItemName + ">> cooked x" + recipe.cookedItemQuantity);
	
	
	if(ShouldProcessTutorial('TutorialAlchemyCook'))
	{
		uiStateAlchemy = (W3TutorialManagerUIHandlerStateAlchemy)theGame.GetTutorialSystem().uiHandler.GetCurrentState();
		if(uiStateAlchemy)
		{
			uiStateAlchemy.CookedItem(recipeName);
		}
		else
		{
			uiStateAlchemyMutagens = (W3TutorialManagerUIHandlerStateAlchemyMutagens)theGame.GetTutorialSystem().uiHandler.GetCurrentState();
			if(uiStateAlchemyMutagens)
				uiStateAlchemyMutagens.CookedItem(recipeName);
		}
	}
}

// Legacy's debug command addrecipesedibles: every cooking recipe item (Butter Bandalura's left out, DF8).
exec function gmaddrecipesedibles()
{
	thePlayer.inv.AddAnItem('Recipe for Baked apple', 1);
	thePlayer.inv.AddAnItem('Recipe for Baked potato', 1);
	thePlayer.inv.AddAnItem('Recipe for Chicken leg', 1);
	thePlayer.inv.AddAnItem('Recipe for Gutted fish', 1);
	thePlayer.inv.AddAnItem('Recipe for Roasted chicken', 1);
	thePlayer.inv.AddAnItem('Recipe for Roasted chicken leg', 1);
	thePlayer.inv.AddAnItem('Recipe for Chicken sandwich', 1);
	thePlayer.inv.AddAnItem('Recipe for Grilled chicken sandwich', 1);
	thePlayer.inv.AddAnItem('Recipe for Fried fish', 1);
	thePlayer.inv.AddAnItem('Recipe for Fried meat', 1);
	thePlayer.inv.AddAnItem('Recipe for Fondue', 1);
	thePlayer.inv.AddAnItem('Recipe for Grilled pork', 1);
	thePlayer.inv.AddAnItem('Recipe for Ham sandwich', 1);
	thePlayer.inv.AddAnItem('Recipe for Mutton curry', 1);
	thePlayer.inv.AddAnItem('Recipe for Sausages', 1);
	thePlayer.inv.AddAnItem('Recipe for Scrambled egg', 1);
	thePlayer.inv.AddAnItem('Recipe for Apple juice', 1);
	thePlayer.inv.AddAnItem('Recipe for Raspberry juice', 1);
	thePlayer.inv.AddAnItem('Recipe for Chocolate souffle', 1);
	thePlayer.inv.AddAnItem('Recipe for Crossaint honey', 1);
	thePlayer.inv.AddAnItem('Recipe for Flamiche', 1);
	thePlayer.inv.AddAnItem('Recipe for Onion soup', 1);
	thePlayer.inv.AddAnItem('Recipe for Ratatouille', 1);
	thePlayer.inv.AddAnItem('Recipe for Tarte tatin', 1);
	thePlayer.inv.AddAnItem('Recipe for Baguette camembert', 1);
	thePlayer.inv.AddAnItem('Recipe for Boeuf bourguignon', 1);
	thePlayer.inv.AddAnItem('Recipe for Fish tarte', 1);
}
