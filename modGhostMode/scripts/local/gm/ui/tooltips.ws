// UI-06: item tooltips (legacy's guiTooltipComponent.ws).
// - Armor and weapons show their item description (5.x shows none; DU4): the armor class texts state the
//   class's stamina rule (strings 2110992426-428). Swords with a description of their own (Aerondight,
//   Iris, 5.x's sq304 and q402 swords) keep it. The table and grindstone lines (ITEM-12) stay first.
// - Gwent cards show no item description (the card's own text stays).
// - An oil's tooltip lists every bonus as a percentage, with the Wolven set's tier 1 boost per piece
//   (legacy's AddOilStats); its charges count either tree's Fixative.
// - A sword's oil line is the oil's name and charges only (legacy's AddOilInfo); a used-up oil has none.
// - A negative value has no "+", and comparing negative modifiers shows better and worse the right way
//   round (CalculateStatsComparance); a potion's toxicity after Expert Brewer without "/max" and a
//   decoction's offset after Adaptation (the AddItemStats wrapper in alchemy/tooltips.ws).
// UI-07's rows are in tooltip_settings.csv. See docs/features/ui.md.

// Whether an armor piece or weapon shows its item description (swords with their own text keep it).
function GMShowsItemDescription(item : SItemUniqueId, inv : CInventoryComponent) : bool
{
	if(!inv.IsItemAnyArmor(item) && !inv.IsItemWeapon(item))
		return false;
	return !inv.ItemHasTag(item, 'Aerondight') && !inv.ItemHasTag(item, 'PhantomWeapon') && !inv.ItemHasTag(item, 'OlgierdSabre')
		&& !inv.ItemHasTag(item, 'sq304_unique_sword') && !inv.ItemHasTag(item, 'q402_unique_sword');
}

@wrapMethod(W3TooltipComponent)
function GetBaseItemData( item : SItemUniqueId, itemInvComponent : CInventoryComponent, optional isShopItem : bool, optional compareWithItem : SItemUniqueId, optional compareItemInv : CInventoryComponent ) : CScriptedFlashObject
{
	var tooltipData : CScriptedFlashObject;
	var statsList : CScriptedFlashArray;
	var stats : array<SAttributeTooltip>;
	var descr, itemDescr, info : string;
	var fixative : ESkill;
	var ammo, ammoBonus : float;

	tooltipData = wrappedMethod(item, itemInvComponent, isShopItem, compareWithItem, compareItemInv);
	if(!tooltipData || !itemInvComponent)
		return tooltipData;

	descr = tooltipData.GetMemberFlashString("Description");
	itemDescr = GetLocStringByKeyExt(itemInvComponent.GetItemLocalizedDescriptionByUniqueID(item));
	if(GMShowsItemDescription(item, itemInvComponent))
	{
		if(itemDescr != "" && StrFindFirst(descr, itemDescr) < 0)
		{
			info = itemInvComponent.GMGetEnhancedBuffInfo(item);
			if(info != "" && StrBeginsWith(descr, info))
				descr = info + itemDescr + StrRight(descr, StrLen(descr) - StrLen(info));
			else
				descr = itemDescr + descr;
			tooltipData.SetMemberFlashString("Description", descr);
		}
	}
	else if(itemInvComponent.GetItemCategory(item) == 'gwint')
	{
		if(itemDescr != "" && StrFindFirst(descr, itemDescr) >= 0)
			tooltipData.SetMemberFlashString("Description", StrReplace(descr, itemDescr, ""));
	}
	else if(itemInvComponent.IsItemOil(item))
	{
		itemInvComponent.GetItemBaseStats(item, stats);
		statsList = tooltipData.CreateFlashArray();
		GMAddOilStats(stats, statsList, tooltipData);
		tooltipData.SetMemberFlashArray("StatsList", statsList);
		// SKL-14: the charges with either tree's Fixative (5.x reads only the classic one).
		fixative = thePlayer.GMFixativeSkill();
		if(fixative != S_SUndefined && itemInvComponent.IsItemSingletonItem(item) && itemInvComponent.SingletonItemGetMaxAmmo(item) > 0)
		{
			ammo = CalculateAttributeValue(itemInvComponent.GetItemAttributeValue(item, 'ammo'));
			ammoBonus = CalculateAttributeValue(thePlayer.GetSkillAttributeValue(fixative, 'ammo_bonus', false, false));
			ammoBonus = ammo * (1 + ammoBonus * thePlayer.GetSkillLevel(fixative)) - ammo;
			tooltipData.SetMemberFlashString("charges", RoundF(ammo) + " ( +" + RoundF(ammoBonus) + " ) " + GetLocStringByKeyExt("inventory_tooltip_charges"));
		}
	}
	return tooltipData;
}

// Legacy's AddOilStats: every bonus of an oil as a percentage, the Wolven set's tier 1 boost included.
@addMethod(W3TooltipComponent)
function GMAddOilStats(itemStats : array<SAttributeTooltip>, out resultGFxArray : CScriptedFlashArray, rootGFxObject : CScriptedFlashObject) : void
{
	var l_flashObject : CScriptedFlashObject;
	var currentStat : SAttributeTooltip;
	var i : int;
	var wolfMult : float;

	wolfMult = GMWolfOilMult();
	for(i = 0; i < itemStats.Size(); i += 1)
	{
		currentStat = itemStats[i];
		currentStat.value *= wolfMult;
		l_flashObject = rootGFxObject.CreateFlashObject();
		l_flashObject.SetMemberFlashString("id", NameToString(currentStat.originName));
		l_flashObject.SetMemberFlashString("name", currentStat.attributeName);
		l_flashObject.SetMemberFlashString("color", currentStat.attributeColor);
		l_flashObject.SetMemberFlashString("value", NoTrailZeros(RoundMath(currentStat.value * 100)) + " %");
		l_flashObject.SetMemberFlashString("valuePrefix", "");
		l_flashObject.SetMemberFlashBool("isPercentageValue", currentStat.percentageValue);
		l_flashObject.SetMemberFlashNumber("floatValue", currentStat.value);
		resultGFxArray.PushBackFlashObject(l_flashObject);
	}
}

// Legacy's AddOilInfo: a sword's oil line is the oil's name and charges.
@replaceMethod(W3TooltipComponent)
function AddOilInfo(itemId : SItemUniqueId, itemInvComponent : CInventoryComponent, out flashDataObj : CScriptedFlashObject):void
{
	var oilName		  : name;
	var oilLocName	  : string;
	var oilCharges 	  : int;
	var oilMaxCharges : int;
	var oilBonus 	  : float;
	var oilStats 	  : array<SAttributeTooltip>;
	var oilStatFirst  : SAttributeTooltip;
	var oilBonusValue : string;
	var i, count	  : int;
	
	var appliedOilsList : array< W3Effect_Oil >;
	var appliedOil    	: W3Effect_Oil;
	
	appliedOilsList = itemInvComponent.GetOilsAppliedOnItem( itemId );
	count = appliedOilsList.Size();
	
	for( i = 0; i < count; i+=1 )
	{
		appliedOil = appliedOilsList[i];
		oilName = appliedOil.GetOilItemName();
		
		if (oilName != '')
		{
			oilLocName = GetLocStringByKeyExt( itemInvComponent.GetItemLocalizedNameByName( oilName ) );
			oilCharges = appliedOil.GetAmmoCurrentCount();
			oilMaxCharges = appliedOil.GetAmmoMaxCount();		
			itemInvComponent.GetItemStatsFromName( oilName, oilStats );
			
			//modSigns: removed the first bonus's value and name and the Fixative case: the line is the oil's name and its charges (the oil's tooltip lists every bonus)
			if( oilCharges < 1 )	//modSigns: no line for a used-up oil
				continue;	//modSigns
			oilBonusValue = oilLocName + " (" + oilCharges + "/" + oilMaxCharges + ")";	//modSigns
			
			flashDataObj.SetMemberFlashString("appliedOilInfo" +(string)(i + 1), oilBonusValue);
		}
	}
}

// Legacy's CalculateStatsComparance: negative values without "+", negative modifiers compared the right way round;
// the slow motion and breath names as in the item tooltip. (ALCH audit F11's wrapper adds the seconds.)
@replaceMethod
function CalculateStatsComparance(itemStats : array<SAttributeTooltip>, compareItemStats : array<SAttributeTooltip>, rootGFxObject : CScriptedFlashObject, out compResult : CScriptedFlashArray, optional ignorePrimStat : bool, optional dontCompare : bool, optional extendedData:bool)
{
	var l_flashObject	: CScriptedFlashObject;
	var attributeVal 	: SAbilityAttributeValue;
	
	var strDifference 	: string;
	var strDiffPrefix   : string;
	var strDiffPostfix  : string;
	var strDiffValue	: string;
	var strValue		: string;
	
	var percentDiff 	: float;
	var nDifference 	: float;
	var i, j, price 	: int;
	var statsCount		: int;
	var comparedStats 	: array<SAttributeTooltip>;

	var valuePrefix	  : string;
	var valuePostfix  : string;
	
	var diffValue : string;
	var statToCompareExist : bool;

	statsCount = itemStats.Size();
	for( i = 0; i < statsCount; i += 1 ) 
	{
		if (!(itemStats[i].primaryStat && ignorePrimStat))
		{
			if(itemStats[i].originName == 'slow_motion')	//modSigns: 5.x's names, as in the item tooltip
				itemStats[i].attributeName = GetLocStringByKey('attribute_name_SlowdownEffect');	//modSigns
			else if(itemStats[i].originName == 'air')	//modSigns
				itemStats[i].attributeName = GetLocStringByKey('panel_hud_breath');	//modSigns
			
			l_flashObject = rootGFxObject.CreateFlashObject();
			l_flashObject.SetMemberFlashString("name",itemStats[i].attributeName);
			l_flashObject.SetMemberFlashString("color",itemStats[i].attributeColor);
			
			strDifference = "better";
			strDiffPrefix = "";
			strDiffPostfix = "";
			strDiffValue = "";
			
			valuePrefix = "";
			valuePostfix = "";
			
			statToCompareExist = false;
			
			
			if (!dontCompare)
			{			
				for( j = 0; j < compareItemStats.Size(); j += 1 )
				{
					
					if( itemStats[i].attributeName == compareItemStats[j].attributeName )
					{
						statToCompareExist = true;
						
						if( itemStats[i].percentageValue )	
						{
							nDifference = RoundMath(itemStats[i].value * 100) - RoundMath(compareItemStats[j].value * 100);
							percentDiff = AbsF( nDifference / RoundMath(itemStats[i].value * 100) );
						}
						else
						{
							nDifference = RoundMath(itemStats[i].value) - RoundMath(compareItemStats[j].value);
							percentDiff = AbsF( nDifference / RoundMath(itemStats[i].value) );
						}
						
						
						if(nDifference > 0)
						{
							strDiffPrefix = "<font color=\"#19D900\"> +";
							strDiffPostfix = "</font>";
							
							strDifference = "better";
							
						}
						
						else if(nDifference < 0)
						{
							strDiffPrefix = "<font color=\"#E00000\"> ";
							strDiffPostfix = "</font>";
							
							strDifference = "worse";
							
						}
						else
						{
							strDifference = "none";
						}
						if (nDifference != 0)
						{
							if( itemStats[i].percentageValue )						
								strDiffValue = strDiffPrefix + RoundMath(nDifference) + " %" + strDiffPostfix;
							else
								strDiffValue = strDiffPrefix + RoundMath(nDifference) + strDiffPostfix;
						}
						
						else
						{
							strDiffPrefix = "";
							strDiffPostfix = "";
							strDiffValue = "";
						}
						compareItemStats.Remove(compareItemStats[j]);
						break;
					}
				}
				
				
				if (strDiffValue == "" && !statToCompareExist)
				{
					if( itemStats[i].value < 0 )	//modSigns: a negative modifier the other item lacks is worse
					{	//modSigns
						strDifference = "worse";	//modSigns
						strDiffPrefix = "<font color=\"#E00000\"> ";	//modSigns
					}	//modSigns
					else	//modSigns
					{	//modSigns
						strDifference = "better";	//modSigns
						strDiffPrefix = "<font color=\"#19D900\"> +";	//modSigns
					}	//modSigns
					strDiffPostfix = "</font>";
					if( itemStats[i].percentageValue )
					{
						strDiffValue = strDiffPrefix + RoundMath(itemStats[i].value *100) + " %" + strDiffPostfix;
					}
					else
					{
						strDiffValue = strDiffPrefix + RoundMath(itemStats[i].value) + strDiffPostfix;
					}
				}
			}
			else
			{
				strDifference = "none";
			}
			
			l_flashObject.SetMemberFlashString("icon", strDifference);
			l_flashObject.SetMemberFlashBool("primaryStat", itemStats[i].primaryStat);
			
			if (itemStats[i].originName == 'toxicity' || itemStats[i].originName == 'toxicity_offset')
			{
				valuePrefix = "";
				valuePostfix = "";
			}
			else
			if (itemStats[i].originName == 'duration')
			{
				valuePrefix = "";
				valuePostfix = " " + GetLocStringByKeyExt("per_second");
			}
			else
			if (ignorePrimStat) 
			{
				valuePrefix = "+";
				valuePostfix = "";
			}
			else
			{
				valuePrefix = "";
				valuePostfix = "";
			}
			
			if( itemStats[i].value < 0 && valuePrefix == "+" )	//modSigns: no "+" before a negative value
				valuePrefix = "";	//modSigns
			
			if( itemStats[i].percentageValue )
			{
				l_flashObject.SetMemberFlashString("value", valuePrefix + RoundMath( itemStats[i].value * 100 ) + " %" + valuePostfix );
			}
			
			else
			{
				l_flashObject.SetMemberFlashString("value", valuePrefix + RoundMath( itemStats[i].value ) + valuePostfix );
			}
			
			l_flashObject.SetMemberFlashString("diffValue", strDiffValue);
			
			compResult.PushBackFlashObject(l_flashObject);
		}
	}
	
	
	if (!dontCompare)
	{
		if (ignorePrimStat) 
		{
			valuePrefix = "+";
		}
		else
		{
			valuePrefix = "";
		}
		
		for( j = 0; j < compareItemStats.Size(); j += 1 )
		{
			if (!(compareItemStats[j].primaryStat && ignorePrimStat))
			{
				l_flashObject = rootGFxObject.CreateFlashObject();
				l_flashObject.SetMemberFlashString("name",compareItemStats[j].attributeName);
				l_flashObject.SetMemberFlashString("color",compareItemStats[j].attributeColor);
				if( compareItemStats[j].value < 0 )	//modSigns: losing a negative modifier is better
				{	//modSigns
					l_flashObject.SetMemberFlashString("icon", "better");	//modSigns
					diffValue = "<font color=\"#19D900\"> +";	//modSigns
					compareItemStats[j].value *= -1;	//modSigns
				}	//modSigns
				else	//modSigns
				{	//modSigns
					l_flashObject.SetMemberFlashString("icon", "worse");	//modSigns
					diffValue = "<font color=\"#E00000\"> -";	//modSigns
				}	//modSigns
				
				if( compareItemStats[j].percentageValue )
				{
					strValue = valuePrefix + "0 %";
					diffValue += RoundMath( compareItemStats[j].value * 100 ) + " %</font>";	//modSigns
				}
				else
				{
					strValue = valuePrefix + "0";
					diffValue += RoundMath(compareItemStats[j].value) + "</font>";	//modSigns
				}
				
				l_flashObject.SetMemberFlashString("value", strValue);
				l_flashObject.SetMemberFlashString("diffValue", diffValue);
				
				compResult.PushBackFlashObject(l_flashObject);
			}
		}
	}
}

