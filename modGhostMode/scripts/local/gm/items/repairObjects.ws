// ITEM-12: the Armorer's Table and grindstone buffs, as legacy. See docs/features/item.md. The table gives
// +5% to every damage resistance, the grindstone 10 armor penetration and 5% resistance reduction, each
// for 30 minutes (DI3; data: gm_item_effects.xml); they apply even with no gear equipped; an item's
// tooltip shows the active buff, its bonus and the time left (GMGetEnhancedBuffInfo).

@replaceMethod(W3PlayerWitcher)
function AddRepairObjectBuff(armor : bool, weapon : bool) : bool
{
	var added : bool;

	added = false;

	if(weapon)	//modSigns: no equipment condition
	{
		AddEffectDefault(EET_EnhancedWeapon, this, "repair_object", false);
		added = true;
	}

	if(armor)	//modSigns: no equipment condition
	{
		AddEffectDefault(EET_EnhancedArmor, this, "repair_object", false);
		added = true;
	}

	return added;
}

// The active table or grindstone buff for an item's tooltip: icon, name, time left and bonuses (legacy).
@addMethod(CInventoryComponent)
function GMGetEnhancedBuffInfo(item : SItemUniqueId) : string
{
	var dm							: CDefinitionsManagerAccessor;
	var min, max					: SAbilityAttributeValue;
	var attrs						: array<name>;
	var k							: int;
	var abilityName, attributeName	: name;
	var attributeColor				: string;
	var isPercentageValue			: bool;
	var attributeVal				: SAbilityAttributeValue;
	var statVal						: float;
	var descr						: string;

	if(GetEntity() != GetWitcherPlayer())
		return "";

	dm = theGame.GetDefinitionsManager();
	descr = "";

	if(thePlayer.HasBuff(EET_EnhancedWeapon) && IsItemWeapon(item) && !IsItemBolt(item))
	{
		descr += "<img src=\"img://icons/buffs/enhanced_sword.png\" width=\"25\" height=\"25\" align=\"top\" \">" + " " + GetLocStringByKey("effect_enhanced_weapon");
		descr += " (" + RoundMath(thePlayer.GetBuff(EET_EnhancedWeapon).GetDurationLeft()) + " " + GetLocStringByKeyExt("per_second") + "):";
		abilityName = EffectTypeToName(EET_EnhancedWeapon);
		dm.GetAbilityAttributes(abilityName, attrs);
		attrs.Remove('duration');
	}

	if(thePlayer.HasBuff(EET_EnhancedArmor) && IsItemAnyArmor(item))
	{
		descr += "<img src=\"img://icons/buffs/enhanced_armor.png\" width=\"25\" height=\"25\" align=\"top\" \">" + " " + GetLocStringByKey("effect_enhanced_armor");
		descr += " (" + RoundMath(thePlayer.GetBuff(EET_EnhancedArmor).GetDurationLeft()) + " " + GetLocStringByKeyExt("per_second") + "):";
		abilityName = EffectTypeToName(EET_EnhancedArmor);
		dm.GetAbilityAttributes(abilityName, attrs);
		attrs.Remove('duration');
		attrs.Remove('slashing_resistance_perc');
		attrs.Remove('piercing_resistance_perc');
		attrs.Remove('bludgeoning_resistance_perc');
		attrs.Remove('rending_resistance_perc');
		attrs.Remove('elemental_resistance_perc');
	}

	if(descr != "")
		descr += "<font color=\"#dbd8c5\">";

	for(k = 0; k < attrs.Size(); k += 1)
	{
		attributeName = attrs[k];
		if(GMFindAttrInTooltipSettings(attributeName, attributeColor, isPercentageValue))
		{
			dm.GetAbilityAttributeValue(abilityName, attributeName, min, max);
			attributeVal = GetAttributeRandomizedValue(min, max);
			if(attributeVal.valueBase != 0)
				statVal = attributeVal.valueBase;
			if(attributeVal.valueMultiplicative != 0)
			{
				statVal = attributeVal.valueMultiplicative;
				isPercentageValue = true;
			}
			if(attributeVal.valueAdditive != 0)
				statVal = attributeVal.valueAdditive;
			if(isPercentageValue)
				statVal = RoundMath(statVal * 100);
			if(statVal != 0)
			{
				descr += "<br>  ";
				if(statVal > 0)
					descr += "+";
				descr += NoTrailZeros(statVal);
				if(isPercentageValue)
					descr += " %";
				descr += "  " + GetAttributeNameLocStr(attributeName, false);
			}
		}
	}

	if(descr != "")
		descr += "</font><br><br>";

	return descr;
}

// An attribute's row in tooltip_settings.csv: its colour and whether it shows as a percentage (legacy's
// FindAttrInTooltipSettings, which 5.x's inventory component no longer has).
@addMethod(CInventoryComponent)
function GMFindAttrInTooltipSettings(attributeName : name, out attributeColor : string, out isPercentageValue : bool) : bool
{
	var i, settingsSize : int;

	if(!IsNameValid(attributeName))
		return false;
	settingsSize = theGame.tooltipSettings.GetNumRows();
	for(i = 0; i < settingsSize; i += 1)
	{
		if(theGame.tooltipSettings.GetValueAt(0, i) != NameToString(attributeName))
			continue;
		attributeColor = theGame.tooltipSettings.GetValueAt(1, i);
		isPercentageValue = theGame.tooltipSettings.GetValueAt(2, i) == "TRUE";
		return true;
	}
	return false;
}

// The buff's lines go at the top of an item's description (legacy's GetBaseItemData change); Iris's
// description wrapper (swords/iris.ws) keeps them too, whichever wrapper runs last.
@wrapMethod(W3TooltipComponent)
function GetBaseItemData( item : SItemUniqueId, itemInvComponent : CInventoryComponent, optional isShopItem : bool, optional compareWithItem : SItemUniqueId, optional compareItemInv : CInventoryComponent ) : CScriptedFlashObject
{
	var tooltipData : CScriptedFlashObject;
	var info, descr : string;

	tooltipData = wrappedMethod(item, itemInvComponent, isShopItem, compareWithItem, compareItemInv);
	if(tooltipData && itemInvComponent)
	{
		info = itemInvComponent.GMGetEnhancedBuffInfo(item);
		descr = tooltipData.GetMemberFlashString("Description");
		if(info != "" && !StrBeginsWith(descr, info))
			tooltipData.SetMemberFlashString("Description", info + descr);
	}
	return tooltipData;
}
