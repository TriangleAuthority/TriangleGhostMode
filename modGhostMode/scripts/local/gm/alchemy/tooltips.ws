// ALCH-17: alchemy tooltips and descriptions (legacy's). Potions list every effect of their effect
// abilities, by item and by name (inventory, shops, the alchemy menu); bombs list their effects' values;
// a decoction's description carries its values ($I$/$S$ filled from the data) and the toxicity offset
// note; a potion's tooltip shows its duration as drunk (Prolonged Effects and gear included); a bomb's
// duration is its cloud's. The texts are legacy's strings (modGhostMode tables). Items other than armor and
// weapons get legacy's descriptions by name key (audit F6); the alchemy durations show in seconds and a
// decoction's toxicity offset under its own name (audit F11). The recipe book's text and the recipe items'
// tooltips are UI-08's (ui/recipes.ws).
// See docs/features/alch.md.

// 5.x body replaced by legacy's: by item name, every effect ability of the item (legacy).
@replaceMethod(CInventoryComponent)
function GetPotionAttributesForTooltip(potionId : SItemUniqueId, out tips : array<SAttributeTooltip>):void
{
	GMGetPotionAttributesByName(GetItemName(potionId), tips);	//modSigns: legacy's, by name
	//modSigns: removed 5.x's body (the first effect ability only, attributes of 5.x's decoctions, Cat's crit chance)
}

// Legacy's GetPotionAttributesByName: the attributes of a potion's (not a decoction's) effect abilities.
@addMethod(CInventoryComponent)
function GMGetPotionAttributesByName(itemName : name, out tips : array<SAttributeTooltip>)
{
	var dm			: CDefinitionsManagerAccessor = theGame.GetDefinitionsManager();
	var abs1, abs	: array<name>;
	var weights		: array<float>;
	var i, j, k		: int;
	var buffType	: EEffectType;
	var abilityName	: name;
	var attrs		: array<name>;
	var val			: SAbilityAttributeValue;
	var newAttr		: SAttributeTooltip;
	var min, max	: SAbilityAttributeValue;
	
	if(!dm.ItemHasTag(itemName, 'Potion') && !dm.ItemHasTag(itemName, 'Edibles') && !dm.ItemHasTag(itemName, 'Drinks'))
		return;
	
	if(dm.ItemHasTag(itemName, 'Mutagen'))
		return;
		
	dm.GetItemAbilitiesWithWeights(itemName, GetEntity() == thePlayer, abs1, weights, i, j);
	
	for(j = 0; j < abs1.Size(); j += 1)
	{
		abs.Clear();
		dm.GetContainedAbilities(abs1[j], abs);
			
		for(i = 0; i < abs.Size(); i += 1)
		{
			EffectNameToType(abs[i], buffType, abilityName);
			
			if(buffType != EET_Undefined)
			{
				attrs.Clear();
				dm.GetAbilityAttributes(abs[i], attrs);
				
				attrs.Remove('duration');
				attrs.Remove('level');
				
				if(buffType == EET_Cat)
				{
					attrs.Remove('highlightObjectsRange');
				}
				else if(buffType == EET_MariborForest)
				{
					attrs.Remove('focus_on_drink');
				}
				else if(buffType == EET_KillerWhale)
				{
					attrs.Remove('swimmingStamina');
					attrs.Remove('vision_strength');
				}
				else if(buffType == EET_Thunderbolt)
				{
					attrs.Remove('critical_hit_chance');
				}
				else if(buffType == EET_WhiteRaffardDecoction)
				{
					dm.GetAbilityAttributeValue(abs1[j], 'level', min, max);
					if(min.valueAdditive == 3)
						attrs.Insert(0, 'duration');
				}
				
				for(k = 0; k < attrs.Size(); k += 1)
				{
					dm.GetAbilityAttributeValue(abs[i], attrs[k], min, max);
					val = GetAttributeRandomizedValue(min, max);
					
					newAttr.originName = attrs[k];
					newAttr.attributeName = GetAttributeNameLocStr(attrs[k], false);
					
					if(buffType == EET_MariborForest && attrs[k] == 'focus_gain')
					{
						newAttr.value = val.valueAdditive;
						newAttr.percentageValue = true;
					}
					else if(buffType == EET_GoldenOriole && attrs[k] == 'poison_resistance_perc')
					{
						newAttr.value = val.valueAdditive;
						newAttr.percentageValue = true;
					}
					else if(buffType == EET_Swallow && attrs[k] == 'bleeding_resistance_perc')
					{
						newAttr.value = val.valueAdditive;
						newAttr.percentageValue = true;
					}
					else if(val.valueMultiplicative != 0)
					{
						newAttr.value = val.valueMultiplicative;
						newAttr.percentageValue = true;
					}
					else if(val.valueAdditive != 0)
					{
						if(buffType == EET_Thunderbolt)
						{
							newAttr.value = val.valueAdditive * 100;
							newAttr.percentageValue = true;
						}
						else if(buffType == EET_Blizzard)
						{
							newAttr.value = 1 - val.valueAdditive;
							newAttr.percentageValue = true;
						}
						else
						{
							newAttr.value = val.valueAdditive;
							newAttr.percentageValue = false;
						}
					}
					else
					{
						newAttr.value = val.valueBase;
						newAttr.percentageValue = false;
					}
					
					tips.PushBack(newAttr);
				}
			}
		}
	}
}

// Legacy's FillInMutagenDescription: a decoction item's description with its values.
@addMethod(CInventoryComponent)
function GMFillInMutagenDescription(potionId : SItemUniqueId, out uniqueDescription : string)
{
	var i			: int;
	var buffType	: EEffectType;
	var abilityName	: name;
	var abs			: array<name>;
	
	if(!ItemHasTag(potionId, 'Mutagen'))
		return;
		
	GetItemContainedAbilities(potionId, abs);
	
	for(i = 0; i < abs.Size(); i += 1)
	{
		EffectNameToType(abs[i], buffType, abilityName);
		
		if(buffType != EET_Undefined)
			break;
	}
	
	GMFillInMutagenDescriptionFromBuffType(buffType, GetItemLocalizedDescriptionByUniqueID(potionId), uniqueDescription);
}

// Legacy's FillInMutagenDescriptionByName (the alchemy menu).
@addMethod(CInventoryComponent)
function GMFillInMutagenDescriptionByName(potionName : name, out uniqueDescription : string)
{
	var i, j		: int;
	var buffType	: EEffectType;
	var abilityName	: name;
	var abs1, abs2	: array<name>;
	var dm			: CDefinitionsManagerAccessor;
	var weights		: array<float>;
	var tmpI, tmpJ	: int;
	
	dm = theGame.GetDefinitionsManager();
	
	if(!dm.ItemHasTag(potionName, 'Mutagen'))
		return;
		
	dm.GetItemAbilitiesWithWeights(potionName, GetEntity() == thePlayer, abs1, weights, tmpI, tmpJ);
	
	for(i = 0; i < abs1.Size(); i += 1)
	{
		dm.GetContainedAbilities(abs1[i], abs2);
			
		for(j = 0; j < abs2.Size(); j += 1)
		{
			EffectNameToType(abs2[j], buffType, abilityName);
			
			if(buffType != EET_Undefined)
				break;
		}
		
		if(buffType != EET_Undefined)
			break;
	}
	
	GMFillInMutagenDescriptionFromBuffType(buffType, GetItemLocalizedDescriptionByName(potionName), uniqueDescription);
}

// Legacy's FillInMutagenDescriptionFromBuffType: the description string filled with the decoction's values,
// then the toxicity offset note.
@addMethod(CInventoryComponent)
function GMFillInMutagenDescriptionFromBuffType(buffType : EEffectType, locKey : string, out uniqueDescription : string)
{
	var min, max	: SAbilityAttributeValue;
	var argsInt 	: array<int>;
	var argsFloat	: array<float>;
	var argsString	: array<string>;
	var dm			: CDefinitionsManagerAccessor;
	var floatVal	: float;
	
	dm = theGame.GetDefinitionsManager();
	
	switch(buffType)
	{
		case EET_Mutagen01:
			dm.GetAbilityAttributeValue('Mutagen01Effect', 'critical_hit_chance', min, max);
			argsInt.PushBack(RoundMath(min.valueAdditive * 100));
			dm.GetAbilityAttributeValue('Mutagen01Effect', 'mutagen01_max_stack', min, max);
			argsInt.PushBack(RoundMath(argsInt[0] * min.valueAdditive));
			dm.GetAbilityAttributeValue('KatakanBonusEffect', 'critical_hit_damage_bonus', min, max);
			argsInt.PushBack(RoundMath(min.valueAdditive * 100));
			uniqueDescription += GetLocStringByKeyExtWithParams(locKey, argsInt);
			break;
		case EET_Mutagen02:
			dm.GetAbilityAttributeValue('Mutagen02Effect', 'mutagen02_resist_reduction', min, max);
			argsInt.PushBack(RoundMath(min.valueAdditive * 100));
			dm.GetAbilityAttributeValue('Mutagen02Effect', 'mutagen02_max_stack', min, max);
			argsInt.PushBack(RoundMath(argsInt[0] * min.valueAdditive));
			uniqueDescription += GetLocStringByKeyExtWithParams(locKey, argsInt);
			break;
		case EET_Mutagen04:
			dm.GetAbilityAttributeValue('Mutagen04Effect', 'attackCostIncrease', min, max);
			argsString.PushBack(NoTrailZeros(min.valueAdditive * 100));
			dm.GetAbilityAttributeValue('Mutagen04Effect', 'healthReductionPerc', min, max);
			argsString.PushBack(NoTrailZeros(min.valueAdditive * 100));
			uniqueDescription += GetLocStringByKeyExtWithParams(locKey, , , argsString);
			break;
		case EET_Mutagen05:
			dm.GetAbilityAttributeValue('Mutagen05Effect', 'attack_power', min, max);
			floatVal = min.valueMultiplicative * 100;
			dm.GetAbilityAttributeValue('Mutagen05Effect', 'mutagen05_buff_rate', min, max);
			argsString.PushBack(NoTrailZeros(floatVal * min.valueAdditive));
			dm.GetAbilityAttributeValue('Mutagen05Effect', 'mutagen05_max_stack', min, max);
			argsString.PushBack(NoTrailZeros(floatVal * min.valueAdditive));
			dm.GetAbilityAttributeValue('Mutagen05Effect', 'mutagen05_debuff_rate', min, max);
			argsString.PushBack(NoTrailZeros(floatVal * min.valueAdditive));
			uniqueDescription += GetLocStringByKeyExtWithParams(locKey, , , argsString);
			break;
		case EET_Mutagen06:
			dm.GetAbilityAttributeValue('Mutagen06Effect', 'vitality', min, max);
			argsString.PushBack(NoTrailZeros(min.valueBase));
			uniqueDescription += GetLocStringByKeyExtWithParams(locKey, , , argsString);
			break;
		case EET_Mutagen07:
			dm.GetAbilityAttributeValue('Mutagen07Effect', 'lifeLeech', min, max);
			argsString.PushBack(NoTrailZeros(min.valueAdditive * 100));
			uniqueDescription += GetLocStringByKeyExtWithParams(locKey, , , argsString);
			break;
		case EET_Mutagen09:
			dm.GetAbilityAttributeValue('Mutagen09Effect', 'mutagen09_bonus_lesser', min, max);
			argsString.PushBack(NoTrailZeros(min.valueAdditive));
			dm.GetAbilityAttributeValue('Mutagen09Effect', 'mutagen09_bonus_medium', min, max);
			argsString.PushBack(NoTrailZeros(min.valueAdditive));
			dm.GetAbilityAttributeValue('Mutagen09Effect', 'mutagen09_bonus_greater', min, max);
			argsString.PushBack(NoTrailZeros(min.valueAdditive));
			uniqueDescription += GetLocStringByKeyExtWithParams(locKey, , , argsString);
			break;
		case EET_Mutagen10:
			dm.GetAbilityAttributeValue('Mutagen10Effect', 'attack_power', min, max);
			floatVal = min.valueMultiplicative;
			argsInt.PushBack(RoundMath(floatVal * 100));
			dm.GetAbilityAttributeValue('Mutagen10Effect', 'mutagen10_max_stack', min, max);
			argsInt.PushBack(RoundMath(floatVal * 100 * min.valueAdditive));
			uniqueDescription += GetLocStringByKeyExtWithParams(locKey, argsInt);
			break;
		case EET_Mutagen11:
			dm.GetAbilityAttributeValue('Mutagen11Effect', 'damageIncrease', min, max);
			argsInt.PushBack(RoundMath(min.valueAdditive * 100));
			uniqueDescription += GetLocStringByKeyExtWithParams(locKey, argsInt);
			break;
		case EET_Mutagen12:
			dm.GetAbilityAttributeValue('Mutagen12Effect', 'vitalityRegen', min, max);
			argsInt.PushBack(RoundMath(min.valueAdditive));
			dm.GetAbilityAttributeValue('Mutagen12Effect', 'vitalityCombatRegen', min, max);
			argsInt.PushBack(RoundMath(min.valueAdditive));
			dm.GetAbilityAttributeValue('Mutagen12Effect', 'm12_threshold', min, max);
			argsInt.PushBack(RoundMath(min.valueAdditive * 100));
			dm.GetAbilityAttributeValue('TrollBonusEffect', 'vitalityCombatRegen', min, max);
			argsInt.PushBack(RoundMath(min.valueAdditive));
			uniqueDescription += GetLocStringByKeyExtWithParams(locKey, argsInt);
			break;
		case EET_Mutagen13:
			dm.GetAbilityAttributeValue('Mutagen13Effect', 'staminaRegen', min, max);
			argsInt.PushBack(RoundMath(min.valueAdditive));
			dm.GetAbilityAttributeValue('Mutagen13Effect', 'mutagen13_max_stack', min, max);
			argsInt.PushBack(RoundMath(argsInt[0] * min.valueAdditive));
			uniqueDescription += GetLocStringByKeyExtWithParams(locKey, argsInt);
			break;
		case EET_Mutagen14:
			dm.GetAbilityAttributeValue('Mutagen14Effect', 'mutagen14_bonus', min, max);
			argsInt.PushBack(RoundMath(min.valueAdditive * 100));
			uniqueDescription += GetLocStringByKeyExtWithParams(locKey, argsInt);
			break;
		case EET_Mutagen15:
			dm.GetAbilityAttributeValue('Mutagen15Effect', 'focus_gain', min, max);
			floatVal = min.valueAdditive * 100;
			dm.GetAbilityAttributeValue('Mutagen15Effect', 'mutagen15_buff_rate', min, max);
			argsString.PushBack(NoTrailZeros(floatVal * min.valueAdditive));
			dm.GetAbilityAttributeValue('Mutagen15Effect', 'mutagen15_max_stack', min, max);
			argsString.PushBack(NoTrailZeros(floatVal * min.valueAdditive));
			dm.GetAbilityAttributeValue('Mutagen15Effect', 'mutagen15_debuff_rate', min, max);
			argsString.PushBack(NoTrailZeros(floatVal * min.valueAdditive));
			uniqueDescription += GetLocStringByKeyExtWithParams(locKey, , , argsString);
			break;
		case EET_Mutagen16:
			dm.GetAbilityAttributeValue('Mutagen16Effect', 'mutagen16_health_prc', min, max);
			argsInt.PushBack(RoundMath(min.valueAdditive * 100));
			uniqueDescription += GetLocStringByKeyExtWithParams(locKey, argsInt);
			break;
		case EET_Mutagen17:
			dm.GetAbilityAttributeValue('Mutagen17Effect', 'spell_power', min, max);
			argsInt.PushBack(RoundMath(min.valueMultiplicative * 100));
			dm.GetAbilityAttributeValue('Mutagen17Effect', 'mutagen17_max_stack', min, max);
			argsInt.PushBack(RoundMath(argsInt[0] * min.valueAdditive));
			uniqueDescription += GetLocStringByKeyExtWithParams(locKey, argsInt);
			break;
		case EET_Mutagen18:
			dm.GetAbilityAttributeValue('Mutagen18Effect', 'vitalityCombatRegen', min, max);
			argsInt.PushBack(RoundMath(min.valueAdditive));
			dm.GetAbilityAttributeValue('Mutagen18Effect', 'mutagen18_max_stack', min, max);
			argsInt.PushBack(RoundMath(argsInt[0] * min.valueAdditive));
			uniqueDescription += GetLocStringByKeyExtWithParams(locKey, argsInt);
			break;
		case EET_Mutagen19:
			dm.GetAbilityAttributeValue('Mutagen19Effect', 'quen_power_bonus', min, max);
			argsString.PushBack(NoTrailZeros(min.valueMultiplicative * 100));
			uniqueDescription += GetLocStringByKeyExtWithParams(locKey, , , argsString);
			break;
		case EET_Mutagen20:
			dm.GetAbilityAttributeValue('Mutagen20Effect', 'fire_resistance_perc', min, max);
			argsInt.PushBack(RoundMath(min.valueAdditive * 100));
			uniqueDescription += GetLocStringByKeyExtWithParams(locKey, argsInt);
			break;
		case EET_Mutagen21:
			dm.GetAbilityAttributeValue('Mutagen21Effect', 'healingRatio', min, max);
			argsString.PushBack(NoTrailZeros(min.valueAdditive * 100));
			uniqueDescription += GetLocStringByKeyExtWithParams(locKey, , , argsString);
			break;
		case EET_Mutagen22:
			dm.GetAbilityAttributeValue('Mutagen22Effect', 'spell_power', min, max);
			floatVal = min.valueMultiplicative * 100;
			dm.GetAbilityAttributeValue('Mutagen22Effect', 'mutagen22_buff_rate', min, max);
			argsString.PushBack(NoTrailZeros(floatVal * min.valueAdditive));
			dm.GetAbilityAttributeValue('Mutagen22Effect', 'mutagen22_max_stack', min, max);
			argsString.PushBack(NoTrailZeros(floatVal * min.valueAdditive));
			dm.GetAbilityAttributeValue('Mutagen22Effect', 'mutagen22_debuff_rate', min, max);
			argsString.PushBack(NoTrailZeros(floatVal * min.valueAdditive));
			uniqueDescription += GetLocStringByKeyExtWithParams(locKey, , , argsString);
			break;
		case EET_Mutagen23:
			dm.GetAbilityAttributeValue('Mutagen23Effect', 'vitalityCombatRegen', min, max);
			argsString.PushBack(NoTrailZeros(1*min.valueAdditive));
			argsString.PushBack(NoTrailZeros(2*min.valueAdditive));
			argsString.PushBack(NoTrailZeros(4*min.valueAdditive));
			uniqueDescription += GetLocStringByKeyExtWithParams(locKey, , , argsString);
			break;
		case EET_Mutagen24:
			dm.GetAbilityAttributeValue('Mutagen24Effect', 'attack_power', min, max);
			argsInt.PushBack(RoundMath(min.valueMultiplicative * 100));
			dm.GetAbilityAttributeValue('Mutagen24Effect', 'spell_power', min, max);
			argsInt.PushBack(RoundMath(min.valueMultiplicative * 100));
			dm.GetAbilityAttributeValue('Mutagen24Effect', 'staminaRegen', min, max);
			argsInt.PushBack(RoundMath(min.valueAdditive));
			dm.GetAbilityAttributeValue('Mutagen24Effect', 'focus_gain', min, max);
			argsInt.PushBack(RoundMath(min.valueAdditive * 100));
			dm.GetAbilityAttributeValue('Mutagen24Effect', 'm24_hp_threshold', min, max);
			argsInt.PushBack(RoundMath(min.valueAdditive * 100));
			dm.GetAbilityAttributeValue('Mutagen24Effect', 'm24_cooldown_time', min, max);
			argsInt.PushBack(RoundMath(min.valueAdditive));
			uniqueDescription += GetLocStringByKeyExtWithParams(locKey, argsInt);
			break;
		case EET_Mutagen25:
			dm.GetAbilityAttributeValue('Mutagen25Effect', 'mutagen25_bonus_lesser', min, max);
			argsString.PushBack(NoTrailZeros(min.valueAdditive*100));
			dm.GetAbilityAttributeValue('Mutagen25Effect', 'mutagen25_bonus_medium', min, max);
			argsString.PushBack(NoTrailZeros(min.valueAdditive*100));
			dm.GetAbilityAttributeValue('Mutagen25Effect', 'mutagen25_bonus_greater', min, max);
			argsString.PushBack(NoTrailZeros(min.valueAdditive*100));
			uniqueDescription += GetLocStringByKeyExtWithParams(locKey, , , argsString);
			break;
		case EET_Mutagen26:
			dm.GetAbilityAttributeValue('Mutagen26Effect', 'returned_damage', min, max);
			argsInt.PushBack(RoundMath(min.valueMultiplicative * 100));
			uniqueDescription += GetLocStringByKeyExtWithParams(locKey, argsInt);
			break;
		case EET_Mutagen27:
			dm.GetAbilityAttributeValue('Mutagen27Effect', 'mutagen27_dmg_window', min, max);
			argsString.PushBack(NoTrailZeros(min.valueAdditive));
			dm.GetAbilityAttributeValue('Mutagen27Effect', 'mutagen27_bonus_duration', min, max);
			argsString.PushBack(NoTrailZeros(min.valueAdditive));
			uniqueDescription += GetLocStringByKeyExtWithParams(locKey, , , argsString);
			break;
		case EET_Mutagen28:
			argsInt.PushBack(RoundMath(10));
			dm.GetAbilityAttributeValue('Mutagen28Effect', 'mutagen28_dmg_mult', min, max);
			argsInt.PushBack(RoundMath(min.valueAdditive * 100));
			dm.GetAbilityAttributeValue('Mutagen28Effect', 'mutagen28_dmg_reduction', min, max);
			argsInt.PushBack(RoundMath(min.valueAdditive * 100));
			uniqueDescription += GetLocStringByKeyExtWithParams(locKey, argsInt);
			break;
		default:
			uniqueDescription += GetLocStringByKeyExt(locKey);
			break;
	}
	
	uniqueDescription += "<br><br><font color=\"#FBEDCF\">" + GetLocStringByKeyExt( "gm_toxicity_offset_description" ) + "</font>";
}

// Legacy's GetBombAttributesForTooltipByName: the values of a bomb's effect abilities that have a tooltip row.
@addMethod(CInventoryComponent)
function GMGetBombAttributesForTooltipByName(itemName : name, out itemStats : array<SAttributeTooltip>)
{
	var dm							: CDefinitionsManagerAccessor = theGame.GetDefinitionsManager();
	var abs1, abs					: array<name>;
	var weights						: array<float>;
	var i, j, k						: int;
	var buffType					: EEffectType;
	var attrs						: array<name>;
	var abilityName, attributeName	: name;
	var attributeColor				: string;
	var isPercentageValue			: bool;
	var stat						: SAttributeTooltip;
	var attributeVal				: SAbilityAttributeValue;
	var min, max					: SAbilityAttributeValue;
	
	if(!dm.ItemHasTag(itemName, 'Petard'))
		return;
	
	dm.GetItemAbilitiesWithWeights(itemName, GetEntity() == thePlayer, abs1, weights, i, j);
	
	for(j = 0; j < abs1.Size(); j += 1)
	{
		abs.Clear();
		dm.GetContainedAbilities(abs1[j], abs);
			
		for(i = 0; i < abs.Size(); i += 1)
		{
			EffectNameToType(abs[i], buffType, abilityName);
			
			if(buffType != EET_Undefined)
			{
				attrs.Clear();
				dm.GetAbilityAttributes(abs[i], attrs);
				
				attrs.Remove('duration');
				attrs.Remove('level');
				
				for(k = 0; k < attrs.Size(); k += 1)
				{
					attributeName = attrs[k];
					if(GMFindAttrInTooltipSettings(attributeName, attributeColor, isPercentageValue))
					{
						dm.GetAbilityAttributeValue(abs[i], attributeName, min, max);
						attributeVal = GetAttributeRandomizedValue(min, max);
						stat.attributeColor = attributeColor;
						stat.percentageValue = isPercentageValue;			
						stat.primaryStat = false;
						stat.value = 0;
						stat.originName = attributeName;
						if(attributeVal.valueBase != 0)
						{
							stat.value = attributeVal.valueBase;
						}
						if(attributeVal.valueMultiplicative != 0)
						{				
							stat.value = attributeVal.valueMultiplicative;
							stat.percentageValue = true;
						}
						if(attributeVal.valueAdditive != 0)
						{				
							stat.value = attributeVal.valueAdditive;
						}
						if (stat.value != 0)
						{
							stat.attributeName = GetAttributeNameLocStr(attributeName, false);
							itemStats.PushBack(stat);
						}
					}
				}
			}
		}
	}
}

// The bomb's tooltip: its effects' values after the item's stats; a decoction's description with its values
// (5.x's text of the item replaced in the description, which other wrappers may have extended).
// Audit F6 (the owner, 2026-10-20): legacy's descriptions by name key (changelist 41): an item that is not
// armor, a weapon, horse gear, a decoction, a decoction's recipe or a Gwent card gets the text of the key
// item_desc_<x> of its name key item_name_<x> when there is one (the oils, Cat 3, books, keys, quest items),
// junk without recycling parts legacy's "Can be sold to merchants.", any other item 5.x's text.
@wrapMethod(W3TooltipComponent)
function GetBaseItemData( item : SItemUniqueId, itemInvComponent : CInventoryComponent, optional isShopItem : bool, optional compareWithItem : SItemUniqueId, optional compareItemInv : CInventoryComponent ) : CScriptedFlashObject
{
	var tooltipData : CScriptedFlashObject;
	var statsList : CScriptedFlashArray;
	var stats : array<SAttributeTooltip>;
	var descr, vanillaDescr, filled : string;
	var category : name;
	var recipe : SAlchemyRecipe;

	tooltipData = wrappedMethod(item, itemInvComponent, isShopItem, compareWithItem, compareItemInv);
	if(tooltipData && itemInvComponent)
	{
		if(itemInvComponent.IsItemBomb(item))
		{
			itemInvComponent.GMGetBombAttributesForTooltipByName(itemInvComponent.GetItemName(item), stats);
			if(stats.Size() > 0)
			{
				statsList = tooltipData.GetMemberFlashArray("StatsList");
				if(statsList)
				{
					AddItemStats(stats, statsList, tooltipData, false, "", false);
					tooltipData.SetMemberFlashArray("StatsList", statsList);
				}
			}
		}
		if(itemInvComponent.ItemHasTag(item, 'Mutagen'))
		{
			itemInvComponent.GMFillInMutagenDescription(item, filled);
			vanillaDescr = GetLocStringByKeyExt(itemInvComponent.GetItemLocalizedDescriptionByUniqueID(item));
			descr = tooltipData.GetMemberFlashString("Description");
			if(filled != "" && vanillaDescr != "" && StrFindFirst(descr, vanillaDescr) >= 0)
				tooltipData.SetMemberFlashString("Description", StrReplace(descr, vanillaDescr, filled));
			else if(filled != "")
				tooltipData.SetMemberFlashString("Description", filled + descr);
		}
		else if(!itemInvComponent.IsItemAnyArmor(item) && !itemInvComponent.IsItemWeapon(item))
		{
			category = itemInvComponent.GetItemCategory(item);
			if(category == 'alchemy_recipe')
				recipe = GetRecipeDataFromXML(itemInvComponent.GetItemName(item));
			if(category != 'gwint' && !(category == 'alchemy_recipe' && theGame.GetDefinitionsManager().ItemHasTag(recipe.cookedItemName, 'Mutagen')))
			{
				if(!itemInvComponent.IsItemHorseItem(item))
					filled = GetLocStringByKeyExt(StrReplaceAll(itemInvComponent.GetItemLocalizedNameByUniqueID(item), "item_name_", "item_desc_"));
				if(filled == "" && category == 'junk' && !itemInvComponent.GMItemHasRecyclingParts(item))
					filled = GetLocStringByKeyExt("item_desc_junk_no_ingr");
				vanillaDescr = GetLocStringByKeyExt(itemInvComponent.GetItemLocalizedDescriptionByUniqueID(item));
				descr = tooltipData.GetMemberFlashString("Description");
				if(filled != "" && filled != vanillaDescr)
				{
					if(vanillaDescr != "" && StrFindFirst(descr, vanillaDescr) >= 0)
						tooltipData.SetMemberFlashString("Description", StrReplace(descr, vanillaDescr, filled));
					else if(vanillaDescr == "")
						tooltipData.SetMemberFlashString("Description", filled + descr);
				}
			}
		}
	}
	return tooltipData;
}

// Legacy's CInventoryComponent.ItemHasRecyclingParts (audit F6).
@addMethod(CInventoryComponent)
function GMItemHasRecyclingParts(id : SItemUniqueId) : bool
{
	var parts : array<SItemParts>;

	parts = GetItemRecyclingParts(id);
	return parts.Size() > 0;
}

// Audit F11 (the owner, 2026-10-20): legacy's units in the item tooltip's stats (legacy's AddItemStats): the
// alchemy durations (a bomb's cloud, Dimeritium out of the cloud, Golden Oriole's immunity) in seconds, and
// a decoction's toxicity offset under its own name with no "/max" (5.x shows it as "Toxicity 70/max").
// UI-06 (legacy's AddItemStats): a potion's toxicity after Expert Brewer, without "/max"; a decoction's
// offset after Adaptation; a negative value without "+". A trophy counts as gear here, as legacy passed it
// (TRPH audit F2: the Arachas trophy's "Maximum Toxicity +40"; gmTipTrophy, set in ui/tooltips.ws).
// The rows AddItemStats adds are its stats in order, less the primary ones it skips.
@wrapMethod(W3TooltipComponent)
function AddItemStats(itemStats : array<SAttributeTooltip>, out resultGFxArray : CScriptedFlashArray, rootGFxObject : CScriptedFlashObject, ignorePrimaryStat : bool, defaultPrefix : string, isArmorOrWeapon : bool):void
{
	var row : CScriptedFlashObject;
	var i, idx : int;
	var witcher : W3PlayerWitcher;
	var value : string;

	if(gmTipTrophy)
		isArmorOrWeapon = true;
	witcher = GetWitcherPlayer();
	for(i = 0; i < itemStats.Size() && witcher && !isArmorOrWeapon; i += 1)
	{
		if(itemStats[i].originName == 'toxicity' && witcher.CanUseSkill(S_Alchemy_s03))
			itemStats[i].value = MaxF(0, itemStats[i].value - CalculateAttributeValue(witcher.GetSkillAttributeValue(S_Alchemy_s03, 'toxicityReduction', false, false)) * witcher.GetSkillLevel(S_Alchemy_s03));
		else if(itemStats[i].originName == 'toxicity_offset')
			itemStats[i].value *= witcher.GMAdaptationMult();
	}
	idx = resultGFxArray.GetLength();
	wrappedMethod(itemStats, resultGFxArray, rootGFxObject, ignorePrimaryStat, defaultPrefix, isArmorOrWeapon);
	for(i = 0; i < itemStats.Size(); i += 1)
	{
		if(ignorePrimaryStat && itemStats[i].primaryStat)
			continue;
		if(idx >= resultGFxArray.GetLength())
			break;
		row = resultGFxArray.GetElementFlashObject(idx);
		idx += 1;
		if(itemStats[i].value < 0 && row.GetMemberFlashString("valuePrefix") == "+")
		{
			value = row.GetMemberFlashString("value");
			if(StrBeginsWith(value, "+"))
				row.SetMemberFlashString("value", StrRight(value, StrLen(value) - 1));
			row.SetMemberFlashString("valuePrefix", "");
		}
		if(itemStats[i].originName == 'toxicity' && !isArmorOrWeapon)
		{
			row.SetMemberFlashString("valuePrefix", "");
			row.SetMemberFlashString("value", NoTrailZeros(RoundMath(itemStats[i].value)));
		}
		else if(GMIsAlchemyDurationStat(itemStats[i].originName))
		{
			row.SetMemberFlashString("valuePrefix", "");
			row.SetMemberFlashString("value", NoTrailZeros(RoundMath(itemStats[i].value)) + " " + GetLocStringByKeyExt("per_second"));
		}
		else if(itemStats[i].originName == 'toxicity_offset')
		{
			row.SetMemberFlashString("id", NameToString(itemStats[i].originName));
			row.SetMemberFlashString("name", itemStats[i].attributeName);
			row.SetMemberFlashString("valuePrefix", "");
			row.SetMemberFlashBool("isPercentageValue", false);
			row.SetMemberFlashString("value", NoTrailZeros(RoundMath(itemStats[i].value)));
		}
	}
}

// Audit F11: the same seconds in the comparison lists (the alchemy menu; legacy's CalculateStatsComparance).
@wrapMethod
function CalculateStatsComparance(itemStats : array<SAttributeTooltip>, compareItemStats : array<SAttributeTooltip>, rootGFxObject : CScriptedFlashObject, out compResult : CScriptedFlashArray, optional ignorePrimStat : bool, optional dontCompare : bool, optional extendedData:bool)
{
	var row : CScriptedFlashObject;
	var i, idx : int;

	idx = compResult.GetLength();
	wrappedMethod(itemStats, compareItemStats, rootGFxObject, compResult, ignorePrimStat, dontCompare, extendedData);
	for(i = 0; i < itemStats.Size(); i += 1)
	{
		if(itemStats[i].primaryStat && ignorePrimStat)
			continue;
		if(idx >= compResult.GetLength())
			break;
		row = compResult.GetElementFlashObject(idx);
		idx += 1;
		if(GMIsAlchemyDurationStat(itemStats[i].originName))
			row.SetMemberFlashString("value", RoundMath(itemStats[i].value) + " " + GetLocStringByKeyExt("per_second"));
	}
}

function GMIsAlchemyDurationStat(attr : name) : bool
{
	return attr == 'cloud_duration' || attr == 'duration_out_of_cloud' || attr == 'poison_immunity_duration';
}

// A potion's duration in its tooltip is the duration as drunk (CalculatePotionDuration: skills, gear;
// legacy); food and drinks keep 5.x's.
@wrapMethod(W3TooltipComponent)
function AddBuffStats(itemId : SItemUniqueId, itemInvComponent : CInventoryComponent, out resultGFxArray : CScriptedFlashArray, rootGFxObject : CScriptedFlashObject) : void
{
	var curFlashObject : CScriptedFlashObject;
	var buffDuration : float;
	var idx, len : int;
	var found : bool;
	var valueStr : string;

	wrappedMethod(itemId, itemInvComponent, resultGFxArray, rootGFxObject);
	if(!itemInvComponent || !itemInvComponent.ItemHasTag(itemId, 'Potion') || itemInvComponent.ItemHasTag(itemId, 'Edibles') || itemInvComponent.ItemHasTag(itemId, 'Drinks') || !GetWitcherPlayer())
		return;
	buffDuration = GetWitcherPlayer().CalculatePotionDuration(itemId, itemInvComponent.ItemHasTag(itemId, 'Mutagen'));
	if(buffDuration <= 0)
		return;
	valueStr = NoTrailZeros(RoundMath(buffDuration)) + " " + GetLocStringByKeyExt("per_second");
	len = resultGFxArray.GetLength();
	for(idx = 0; idx < len; idx += 1)
	{
		curFlashObject = resultGFxArray.GetElementFlashObject(idx);
		if(curFlashObject.GetMemberFlashString("id") == NameToString('duration'))
		{
			curFlashObject.SetMemberFlashString("value", valueStr);
			curFlashObject.SetMemberFlashNumber("floatValue", buffDuration);
			found = true;
			break;
		}
	}
	if(!found)
	{
		curFlashObject = rootGFxObject.CreateFlashObject();
		curFlashObject.SetMemberFlashString("name", GetAttributeNameLocStr('duration', false));
		curFlashObject.SetMemberFlashString("value", valueStr);
		curFlashObject.SetMemberFlashNumber("floatValue", buffDuration);
		resultGFxArray.PushBackFlashObject(curFlashObject);
	}
}

// A bomb's duration attribute is its cloud's: named "Cloud duration" (legacy).
// Whole-port audit C1-3 (2026-11-03): legacy's bomb damage lines (legacy GetItemBaseStats and
// GetItemTooltipAttributes): with Pyrotechnics (alchemy_s10, both trees) a bomb's physical and silver damage
// include the skill's damage per level, and the item tooltip (GetItemBaseStats) lists both lines even for a
// bomb without them; with Heavy Artillery (classic perk_20, new tree perk_43) every damage line is
// multiplied by 1 + its dmg_multiplier (x2). The Snow Ball gets no Pyrotechnics line: the skill does not
// raise its damage (legacy's tooltip showed it; a deviation).
@addField(CInventoryComponent)
var gmBombBaseStats : bool;

@wrapMethod(CInventoryComponent)
function GetItemBaseStats(itemId : SItemUniqueId, out itemStats : array<SAttributeTooltip>)
{
	gmBombBaseStats = true;
	wrappedMethod(itemId, itemStats);
	gmBombBaseStats = false;
}

@wrapMethod(CInventoryComponent)
function GetItemTooltipAttributes(itemId : SItemUniqueId, attributes : array<name>, out itemStats : array<SAttributeTooltip>, optional respectAttributeOrder : bool)
{
	var i : int;

	wrappedMethod(itemId, attributes, itemStats, respectAttributeOrder);
	if(!IsItemBomb(itemId))
		return;
	for(i = 0; i < itemStats.Size(); i += 1)
	{
		if(itemStats[i].originName == 'duration')
		{
			itemStats[i].originName = 'cloud_duration';
			itemStats[i].attributeName = GetAttributeNameLocStr('cloud_duration', false);
		}
	}
	GMAddBombSkillDamage(itemId, itemStats, gmBombBaseStats);
}

// Pyrotechnics' damage on a bomb's physical and silver lines (added when missing and addMissing), then Heavy
// Artillery's multiplier on every damage line (legacy's order: the skill's damage is multiplied too).
@addMethod(CInventoryComponent)
function GMAddBombSkillDamage(itemId : SItemUniqueId, out itemStats : array<SAttributeTooltip>, addMissing : bool)
{
	var witcher : W3PlayerWitcher;
	var pyro : array<name>;
	var bonus : float;
	var heavy : ESkill;
	var mult : SAbilityAttributeValue;
	var i, j : int;
	var found : bool;

	witcher = GetWitcherPlayer();
	if(!witcher)
		return;
	if(witcher.CanUseSkill(S_Alchemy_s10) && GetItemName(itemId) != 'Snow Ball')
	{
		pyro.PushBack('PhysicalDamage');
		pyro.PushBack('SilverDamage');
	}
	for(j = 0; j < pyro.Size(); j += 1)
	{
		bonus = CalculateAttributeValue(witcher.GetSkillAttributeValue(S_Alchemy_s10, pyro[j], false, false)) * witcher.GetSkillLevel(S_Alchemy_s10);
		if(bonus == 0)
			continue;
		found = false;
		for(i = 0; i < itemStats.Size(); i += 1)
		{
			if(itemStats[i].originName == pyro[j])
			{
				itemStats[i].value += bonus;
				found = true;
				break;
			}
		}
		if(!found && addMissing)
			GMInsertTooltipStat(itemId, pyro[j], bonus, itemStats);
	}
	heavy = witcher.GMHeavyArtillerySkill();
	if(heavy == S_SUndefined)
		return;
	mult = witcher.GetSkillAttributeValue(heavy, 'dmg_multiplier', false, false);
	for(i = 0; i < itemStats.Size(); i += 1)
	{
		if(IsDamageTypeNameValid(itemStats[i].originName))
			itemStats[i].value *= 1 + mult.valueMultiplicative;
	}
}

// A tooltip row for an attribute the item lacks, made as 5.x's GetItemTooltipAttributes makes one, put in
// tooltip_settings.csv's order among the item's rows.
@addMethod(CInventoryComponent)
function GMInsertTooltipStat(itemId : SItemUniqueId, attributeName : name, value : float, out itemStats : array<SAttributeTooltip>)
{
	var stat : SAttributeTooltip;
	var isPercentageValue, primaryStatLabel : string;
	var row, i : int;

	row = GMTooltipSettingsRow(attributeName);
	if(row < 0)
		return;
	stat.attributeColor = theGame.tooltipSettings.GetValueAt(1, row);
	isPercentageValue = theGame.tooltipSettings.GetValueAt(2, row);
	stat.percentageValue = isPercentageValue;
	stat.primaryStat = IsPrimaryStatById(itemId, attributeName, primaryStatLabel);
	stat.originName = attributeName;
	stat.value = value;
	stat.attributeName = GetAttributeNameLocStr(attributeName, false);
	for(i = 0; i < itemStats.Size(); i += 1)
	{
		if(GMTooltipSettingsRow(itemStats[i].originName) > row)
		{
			itemStats.Insert(i, stat);
			return;
		}
	}
	itemStats.PushBack(stat);
}

// An attribute's row in tooltip_settings.csv (-1 if none).
function GMTooltipSettingsRow(attributeName : name) : int
{
	var i, n : int;
	var s : string;

	s = NameToString(attributeName);
	n = theGame.tooltipSettings.GetNumRows();
	for(i = 0; i < n; i += 1)
	{
		if(theGame.tooltipSettings.GetValueAt(0, i) == s)
			return i;
	}
	return -1;
}

// Whole-port audit C1-5 (2026-11-03): a decoction's toxicity offset by name (the recipe book, the alchemy
// menu, shops) under its own name, "Toxicity offset", as legacy's GetItemStatsFromName (5.x names it
// "Toxicity").
@wrapMethod(CInventoryComponent)
function GetItemStatsFromName(itemName : name, out itemStats : array<SAttributeTooltip>)
{
	var i : int;

	wrappedMethod(itemName, itemStats);
	for(i = 0; i < itemStats.Size(); i += 1)
	{
		if(itemStats[i].originName == 'toxicity_offset')
			itemStats[i].attributeName = GetAttributeNameLocStr('toxicity_offset', false);
	}
}

// The alchemy menu: a potion's or bomb's effects by name, a decoction's description with its values.
@wrapMethod(W3GuiPlayerInventoryComponent)
function GetCraftedItemInfo(craftedItemName:name, targetObject:CScriptedFlashObject) : void
{
	var dm : CDefinitionsManagerAccessor;
	var attributes, noStats : array<SAttributeTooltip>;
	var attributesList : CScriptedFlashArray;
	var attributesStr, itemDesc, vanillaDesc, oldDesc, htmlNewline : string;
	var i : int;

	wrappedMethod(craftedItemName, targetObject);
	dm = theGame.GetDefinitionsManager();
	if(dm.ItemHasTag(craftedItemName, 'Mutagen'))
	{
		_inv.GMFillInMutagenDescriptionByName(craftedItemName, itemDesc);
		vanillaDesc = GetLocStringByKeyExt(_inv.GetItemLocalizedDescriptionByName(craftedItemName));
		oldDesc = targetObject.GetMemberFlashString("itemDescription");
		if(itemDesc != "" && vanillaDesc != "" && StrFindFirst(oldDesc, vanillaDesc) >= 0)
			targetObject.SetMemberFlashString("itemDescription", StrReplace(oldDesc, vanillaDesc, itemDesc));
		else if(itemDesc != "")
			targetObject.SetMemberFlashString("itemDescription", itemDesc);
	}
	if(!dm.ItemHasTag(craftedItemName, 'Potion') && !dm.ItemHasTag(craftedItemName, 'Petard'))
		return;
	_inv.GetItemStatsFromName(craftedItemName, attributes);
	_inv.GMGetPotionAttributesByName(craftedItemName, attributes);
	_inv.GMGetBombAttributesForTooltipByName(craftedItemName, attributes);
	attributesList = targetObject.CreateFlashArray();
	CalculateStatsComparance(attributes, noStats, targetObject, attributesList, true, true);
	htmlNewline = "&#10;";
	for(i = 0; i < attributes.Size(); i += 1)
	{
		attributesStr += "<font color=\"#" + attributes[i].attributeColor + "\">" + attributes[i].attributeName + ": ";
		if(attributes[i].percentageValue)
			attributesStr += RoundMath(attributes[i].value * 100) + " %";
		else
			attributesStr += RoundMath(attributes[i].value);
		attributesStr += "</font>" + htmlNewline;
	}
	targetObject.SetMemberFlashString("attributes", attributesStr);
	targetObject.SetMemberFlashArray("attributesList", attributesList);
}
