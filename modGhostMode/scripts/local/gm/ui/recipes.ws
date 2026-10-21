// UI-08: recipe and schematic texts (legacy's guiTooltipComponent.ws and guiBaseInventoryComponent.ws; DU5).
// - A recipe item shows what it brews (GetRecipeDataFromXML read the misspelt node 'alchemy_recipies', so
//   recipe items showed nothing, bugfix 87), with the potion's or bomb's effects (ALCH-17's lists by name)
//   and a decoction's description with its values.
// - Schematic, recipe and enchantment schematic tooltips list the ingredients as "have / need", red when
//   short (legacy's addComponentsInfo).
// - The extended texts (E when buying: GetAlchemyBookText, GetSchematicBookText): type and rarity, the effects
//   as "value name", the description (a decoction's with its values), the level required (schematics), the
//   ingredients as "have / need"; no weight and no "random attributes" lines (crafted gear has no random
//   bonus), also in the crafting menu (GetCraftedItemInfo).
// See docs/features/ui.md.

// Legacy's addComponentsInfo: the ingredients of a schematic, recipe or enchantment schematic as have / need.
@addMethod(W3TooltipComponent)
function GMAddComponentsInfo(item : SItemUniqueId, itemInvComponent : CInventoryComponent, out description : string)
{
	var schematic : SCraftingSchematic;
	var recipe : SAlchemyRecipe;
	var enchantment : SEnchantmentSchematic;
	var itemName : name;
	var ingredients : array<SItemParts>;
	var i, itemQuantity : int;

	itemName = itemInvComponent.GetItemName(item);
	schematic = getCraftingSchematicFromName(itemName);
	if(schematic.schemName != '')
		ingredients = schematic.ingredients;
	else
	{
		recipe = getAlchemyRecipeFromName(itemName);
		if(recipe.recipeName != '')
			ingredients = recipe.requiredIngredients;
		else
		{
			enchantment = getEnchantmentSchematicFromName(itemName);
			if(enchantment.schemName != '')
				ingredients = enchantment.ingredients;
		}
	}
	for(i = 0; i < ingredients.Size(); i += 1)
	{
		itemQuantity = m_playerInv.GetItemQuantityByName(ingredients[i].itemName);
		description += "<br/>" + GMHaveNeedColor(itemQuantity, ingredients[i].quantity) + itemQuantity + " / " + ingredients[i].quantity + " " + GetLocStringByKeyExt(m_playerInv.GetItemLocalizedNameByName(ingredients[i].itemName)) + "</font>";
	}
}

// The names the item tooltip gives (AddItemStats) to the stats that have no attribute name, and the
// default colour for a stat without one: the book texts print the names as they come (a slowdown showed
// as a bare "50 %").
function GMFixBookStatNames(out stats : array<SAttributeTooltip>)
{
	var i : int;

	for(i = 0; i < stats.Size(); i += 1)
	{
		if(stats[i].originName == 'slow_motion')
			stats[i].attributeName = GetLocStringByKey('attribute_name_SlowdownEffect');
		else if(stats[i].originName == 'air')
			stats[i].attributeName = GetLocStringByKey('panel_hud_breath');
		else if(stats[i].originName == 'focus')
			stats[i].attributeName = GetLocStringByKey('focus');
		if(stats[i].attributeColor == "")
			stats[i].attributeColor = "BAADA0";
	}
}

function GMHaveNeedColor(have : int, need : int) : string
{
	if(need > have)
		return "<font color=\"#FF0000\">";
	return "<font color=\"#00FF00\">";
}

@wrapMethod(W3TooltipComponent)
function GetBaseItemData( item : SItemUniqueId, itemInvComponent : CInventoryComponent, optional isShopItem : bool, optional compareWithItem : SItemUniqueId, optional compareItemInv : CInventoryComponent ) : CScriptedFlashObject
{
	var tooltipData : CScriptedFlashObject;
	var statsList : CScriptedFlashArray;
	var stats : array<SAttributeTooltip>;
	var descr, comps, filled, vanillaDescr : string;
	var category : name;
	var recipe : SAlchemyRecipe;

	tooltipData = wrappedMethod(item, itemInvComponent, isShopItem, compareWithItem, compareItemInv);
	if(!tooltipData || !itemInvComponent)
		return tooltipData;
	category = itemInvComponent.GetItemCategory(item);
	if(category != 'alchemy_recipe' && category != 'crafting_schematic')
		return tooltipData;

	descr = tooltipData.GetMemberFlashString("Description");
	if(category == 'alchemy_recipe')
	{
		recipe = GetRecipeDataFromXML(itemInvComponent.GetItemName(item));
		if(recipe.cookedItemName != '')
		{
			// The potion's or bomb's effects (ALCH-17's lists by name) after the item's stats.
			itemInvComponent.GMGetPotionAttributesByName(recipe.cookedItemName, stats);
			itemInvComponent.GMGetBombAttributesForTooltipByName(recipe.cookedItemName, stats);
			statsList = tooltipData.GetMemberFlashArray("StatsList");
			if(stats.Size() > 0 && statsList)
			{
				AddItemStats(stats, statsList, tooltipData, false, "", false);
				tooltipData.SetMemberFlashArray("StatsList", statsList);
			}
			// A decoction's recipe: the decoction's description with its values instead of the recipe's text.
			if(theGame.GetDefinitionsManager().ItemHasTag(recipe.cookedItemName, 'Mutagen'))
			{
				itemInvComponent.GMFillInMutagenDescriptionByName(recipe.cookedItemName, filled);
				vanillaDescr = GetLocStringByKeyExt(itemInvComponent.GetItemLocalizedDescriptionByUniqueID(item));
				if(filled != "" && vanillaDescr != "" && StrFindFirst(descr, vanillaDescr) >= 0)
					descr = StrReplace(descr, vanillaDescr, filled);
				else if(filled != "" && StrFindFirst(descr, filled) < 0)
					descr = filled + descr;
			}
		}
	}
	GMAddComponentsInfo(item, itemInvComponent, comps);
	if(comps != "" && StrFindFirst(descr, comps) < 0)
	{
		if(StrEndsWith(descr, "<br>"))
			descr = StrLeft(descr, StrLen(descr) - 4);
		descr = StrReplace(descr, "</font><br><br/>", "</font><br/>");	// no blank line after the level (legacy)
		descr += comps;
	}
	tooltipData.SetMemberFlashString("Description", descr);
	return tooltipData;
}

// The crafting menu: no "random attributes" line (crafted gear has no random bonus).
@wrapMethod(W3GuiPlayerInventoryComponent)
function GetCraftedItemInfo(craftedItemName:name, targetObject:CScriptedFlashObject) : void
{
	wrappedMethod(craftedItemName, targetObject);
	targetObject.SetMemberFlashString("additionalDescription", "");
}

// Legacy's GetAlchemyBookText: the effects as "value name", the description (a decoction's with its values),
// the ingredients as have / need; no weight line.
@replaceMethod(W3GuiBaseInventoryComponent)
function GetAlchemyBookText(item : SItemUniqueId):string
{
	var dm 					: CDefinitionsManagerAccessor;
	var finalString			: string;
	var tempString			: string;
	var recipe				: SAlchemyRecipe;
	var currentIngredient	: SItemParts;
	var htmlNewline			: string;
	var itemType 			: EInventoryFilterType;
	var i					: int;
	var craftedItemName		: name;
	var color				: string;
	var attributes			: array<SAttributeTooltip>;
	var minWeightAttribute 	: SAbilityAttributeValue;
	var maxWeightAttribute 	: SAbilityAttributeValue;
	var minQuality 			: int;
	var maxQuality 			: int;
	var itemDesc			: string;	//modSigns
	var itemQuantity		: int;	//modSigns

	htmlNewline = "&#10;";
	finalString = "";	//modSigns

	recipe = getAlchemyRecipeFromName(_inv.GetItemName(item));
	dm = theGame.GetDefinitionsManager();
	craftedItemName = recipe.cookedItemName;
	_inv.GetItemStatsFromName(craftedItemName, attributes);
	_inv.GMGetPotionAttributesByName(craftedItemName, attributes);	//modSigns: the potion's effects (ALCH-17)
	_inv.GMGetBombAttributesForTooltipByName(craftedItemName, attributes);	//modSigns: the bomb's effects (ALCH-17)
	GMFixBookStatNames(attributes);	//modSigns: the item tooltip's names and colour for every effect
	_inv.GetItemQualityFromName(craftedItemName, minQuality, maxQuality);
	dm.GetItemAttributeValueNoRandom(craftedItemName, true, 'weight', minWeightAttribute, maxWeightAttribute);
	itemType = dm.GetFilterTypeByItem(craftedItemName);

	//modSigns: removed the "book" heading, the rarity and the name lines (the extended view's header shows the name)

	tempString = GetLocStringByKeyExt(GetFilterTypeName( itemType )) + " / " + GetLocStringByKeyExt("item_category_" + dm.GetItemCategory(craftedItemName));
	finalString += "<font color=\"#FF8832\">" + tempString + "</font>";	//modSigns
	finalString += htmlNewline + GetItemRarityDescriptionFromInt(minQuality);	//modSigns

	//modSigns: removed the description here (it follows the effects)
	if (attributes.Size() > 0)	//modSigns
		finalString += htmlNewline;	//modSigns
	for (i = 0; i < attributes.Size(); i += 1)
	{

		color = attributes[i].attributeColor;
		tempString = htmlNewline + "<font color=\"#" + color + "\">";	//modSigns
		//modSigns: removed the name before the value
		if( attributes[i].percentageValue )
		{
			tempString += NoTrailZeros(attributes[i].value * 100 ) +" %";
		}
		else
		{
			tempString += NoTrailZeros(attributes[i].value);
		}
		tempString += " " + attributes[i].attributeName + "</font>";	//modSigns: "value name"
		finalString += tempString;
	}

	//modSigns: removed the weight line
	if(dm.ItemHasTag(craftedItemName, 'Mutagen'))	//modSigns: a decoction's description with its values (ALCH-17)
		_inv.GMFillInMutagenDescriptionByName(craftedItemName, itemDesc);	//modSigns
	else	//modSigns
		itemDesc = GetLocStringByKeyExt(_inv.GetItemLocalizedDescriptionByName(craftedItemName));	//modSigns
	finalString += htmlNewline;	//modSigns
	finalString += htmlNewline + "<font color=\"#C49560\">" + itemDesc + "</font>";	//modSigns

	finalString += htmlNewline;	//modSigns
	finalString += htmlNewline + GetLocStringByKeyExt("panel_crafting_ingredients_start") + ":";	//modSigns

	for (i = 0; i < recipe.requiredIngredients.Size(); i += 1)
	{
		currentIngredient = recipe.requiredIngredients[i];
		itemQuantity = thePlayer.inv.GetItemQuantityByName(currentIngredient.itemName);	//modSigns: have / need
		finalString += htmlNewline + GMHaveNeedColor(itemQuantity, currentIngredient.quantity) + itemQuantity + " / " + currentIngredient.quantity + " " + GetLocStringByKeyExt(_inv.GetItemLocalizedNameByName(currentIngredient.itemName)) + "</font>";	//modSigns
	}

	return finalString;
}

// Legacy's GetSchematicBookText: the effects as "value name", the description, the level required, the
// ingredients as have / need; no "random attributes" and no weight lines.
@replaceMethod(W3GuiBaseInventoryComponent)
function GetSchematicBookText(item : SItemUniqueId):string
{
	var dm 					: CDefinitionsManagerAccessor;
	var finalString			: string;
	var tempString			: string;
	var htmlNewline			: string;
	var craftingSchematic	: SCraftingSchematic;
	var craftedItemName		: name;
	var currentIngredient	: SItemParts;
	var i					: int;
	var color				: string;
	var attributes			: array<SAttributeTooltip>;
	var minWeightAttribute 	: SAbilityAttributeValue;
	var maxWeightAttribute 	: SAbilityAttributeValue;
	var minQuality 			: int;
	var maxQuality 			: int;
	var itemType 			: EInventoryFilterType;
	var itemQuantity		: int;	//modSigns

	var delimiter			: string;
	var prefix				: string;
	var language 	  		: string;
	var audioLanguage 		: string;

	theGame.GetGameLanguageName(audioLanguage,language);
	if (language == "AR")
	{
		delimiter = "";
		prefix = "&nbsp;";
	}
	else
	{
		delimiter = ": ";
		prefix = "";
	}

	htmlNewline = "&#10;";
	finalString = "";	//modSigns
	dm = theGame.GetDefinitionsManager();
	craftingSchematic = getCraftingSchematicFromName(_inv.GetItemName(item));
	craftedItemName = craftingSchematic.craftedItemName;
	_inv.GetItemStatsFromName(craftedItemName, attributes);
	GMFixBookStatNames(attributes);	//modSigns: the item tooltip's names and colour for every effect
	_inv.GetItemQualityFromName(craftedItemName, minQuality, maxQuality);
	itemType = dm.GetFilterTypeByItem(craftedItemName);
	dm.GetItemAttributeValueNoRandom(craftedItemName, true, 'weight', minWeightAttribute, maxWeightAttribute);

	//modSigns: removed the "book" heading, the name and rarity lines (the extended view's header shows the name)

	tempString = GetLocStringByKeyExt(GetFilterTypeName( itemType )) + " / " + GetLocStringByKeyExt("item_category_" + dm.GetItemCategory(craftedItemName));
	finalString += "<font color=\"#FF8832\">" + tempString + "</font>";	//modSigns
	finalString += htmlNewline + GetItemRarityDescriptionFromInt(minQuality);	//modSigns

	//modSigns: removed the description and the level here (they follow the effects)
	if (attributes.Size() > 0)	//modSigns
		finalString += htmlNewline;	//modSigns
	for (i = 0; i < attributes.Size(); i += 1)
	{

		color = attributes[i].attributeColor;
		tempString = htmlNewline + "<font color=\"#" + color + "\">";	//modSigns
		//modSigns: removed the name before the value
		if( attributes[i].percentageValue )
		{
			tempString += (NoTrailZeros(attributes[i].value * 100 ) +"%" + prefix);	//modSigns
		}
		else
		{
			tempString += (NoTrailZeros(attributes[i].value) + prefix);
		}
		tempString += " " + attributes[i].attributeName + "</font>";	//modSigns: "value name"
		finalString += tempString;
	}

	//modSigns: removed the "random attributes" and weight lines (crafted gear has no random bonus)
	finalString += htmlNewline;	//modSigns
	finalString += htmlNewline + "<font color=\"#C49560\">" + GetLocStringByKeyExt(_inv.GetItemLocalizedDescriptionByName(craftedItemName)) + "</font>";	//modSigns
	finalString += htmlNewline;	//modSigns
	finalString += htmlNewline + _inv.GetItemLevelColor( dm.GetItemLevelFromName( craftedItemName ) ) + GetLocStringByKeyExt( 'panel_inventory_item_requires_level' ) + delimiter + dm.GetItemLevelFromName( craftedItemName ) + "</font>";	//modSigns
	finalString += htmlNewline;	//modSigns
	finalString += htmlNewline + GetLocStringByKeyExt("panel_crafting_ingredients_start") + ":";	//modSigns

	for (i = 0; i < craftingSchematic.ingredients.Size(); i += 1)
	{
		currentIngredient = craftingSchematic.ingredients[i];
		itemQuantity = thePlayer.inv.GetItemQuantityByName(currentIngredient.itemName);	//modSigns: have / need
		finalString += htmlNewline + GMHaveNeedColor(itemQuantity, currentIngredient.quantity) + itemQuantity + " / " + currentIngredient.quantity + " " + GetLocStringByKeyExt(_inv.GetItemLocalizedNameByName(currentIngredient.itemName)) + "</font>";	//modSigns
	}

	return finalString;
}

// The recipes' node is 'alchemy_recipes'.
@replaceMethod(W3TooltipComponent)
function GetRecipeDataFromXML(recipeName:name):SAlchemyRecipe
{
	var dm : CDefinitionsManagerAccessor;
	var main, ingredients : SCustomNode;
	var tmpBool : bool;
	var tmpName : name;
	var tmpString : string;
	var tmpInt : int;
	var ing : SItemParts;
	var i,k : int;
	var rec : SAlchemyRecipe;
	
	dm = theGame.GetDefinitionsManager();
	main = dm.GetCustomDefinition('alchemy_recipes');	//modSigns: the node's name (5.x's typo found no recipe, bugfix 87)
	
	for(i=0; i<main.subNodes.Size(); i+=1)
	{
		dm.GetCustomNodeAttributeValueName(main.subNodes[i], 'name_name', tmpName);
		
		if (tmpName == recipeName)
		{
			if(dm.GetCustomNodeAttributeValueName(main.subNodes[i], 'cookedItem_name', tmpName))
				rec.cookedItemName = tmpName;
			if(dm.GetCustomNodeAttributeValueName(main.subNodes[i], 'type_name', tmpName))
				rec.typeName = tmpName;
			if(dm.GetCustomNodeAttributeValueInt(main.subNodes[i], 'level', tmpInt))
				rec.level = tmpInt;	
			if(dm.GetCustomNodeAttributeValueString(main.subNodes[i], 'cookedItemType', tmpString))
				rec.cookedItemType = AlchemyCookedItemTypeStringToEnum(tmpString);
			if(dm.GetCustomNodeAttributeValueInt(main.subNodes[i], 'cookedItemQuantity', tmpInt))
				rec.cookedItemQuantity = tmpInt;
			
			
			ingredients = dm.GetCustomDefinitionSubNode(main.subNodes[i],'ingredients');					
			for(k=0; k<ingredients.subNodes.Size(); k+=1)
			{		
				ing.itemName = '';
				ing.quantity = -1;
			
				if(dm.GetCustomNodeAttributeValueName(ingredients.subNodes[k], 'item_name', tmpName))						
					ing.itemName = tmpName;
				if(dm.GetCustomNodeAttributeValueInt(ingredients.subNodes[k], 'quantity', tmpInt))
					ing.quantity = tmpInt;
					
				rec.requiredIngredients.PushBack(ing);						
			}
			
			rec.recipeName = recipeName;
			
			
			rec.cookedItemIconPath			= dm.GetItemIconPath( rec.cookedItemName );
			rec.recipeIconPath				= dm.GetItemIconPath( rec.recipeName );
			break;
		}
	}
	return rec;
}
