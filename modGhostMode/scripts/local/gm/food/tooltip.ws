// FOOD-08: a food or drink tooltip shows its effect's length as eaten: Dumplings' longer length (orange) on
// every edible, not only one in a quick slot; Connoisseur's +100% on an alcohol (legacy). ALCH-17's wrapper
// of this method (alchemy/tooltips.ws) still sets a potion's duration.
// Audit F4 (the owner, 2026-10-24): a food or drink's in-combat regen row is named by legacy's string
// 2110992157 (key attribute_name_vitalityCombatRegen, "Vitality regeneration during combat", UI-07), which the
// game's lower-case key lookup never found.
// See docs/features/food.md.

// 5.x body; changes marked //modSigns.
@replaceMethod(W3TooltipComponent)
function AddBuffStats(itemId : SItemUniqueId, itemInvComponent : CInventoryComponent, out resultGFxArray : CScriptedFlashArray, rootGFxObject : CScriptedFlashObject) : void
{
	var min, max 		 : SAbilityAttributeValue;
	var curFlashObject   : CScriptedFlashObject;
	var buffDuration     : float;
	var idx, len         : int;
	var curBufValue      : float;
	var curBufValueStr   : string;
	var additionalBufStr : string;
	
	var isEdibles : bool;
	var isDrinks  : bool;
	
	var t1:int;
	var t2:int;
	
	isEdibles = itemInvComponent.ItemHasTag(itemId, 'Edibles');
	isDrinks = itemInvComponent.ItemHasTag(itemId, 'Drinks');
	
	if (isEdibles || isDrinks)	//modSigns: FOOD audit F4, legacy's in-combat regen label
		GMFoodCombatRegenLabel(resultGFxArray);	//modSigns
	
	if (isEdibles || isDrinks || itemInvComponent.IsItemBomb(itemId))
	{
		buffDuration = GetBuffDuration(itemId, itemInvComponent);
	}
	
	if (buffDuration > 0 )
	{
		len = resultGFxArray.GetLength();
		
		for (idx = 0; idx < len; idx+=1)
		{
			curFlashObject = resultGFxArray.GetElementFlashObject(idx);
			
			if (curFlashObject.GetMemberFlashString("id") == NameToString('duration'))
			{
				curBufValue = 0;
				
				if (isEdibles || isDrinks)
				{
					resultGFxArray.RemoveElement(idx);
					continue;
				}
				
				curBufValue = curFlashObject.GetMemberFlashNumber("floatValue");
				
				curBufValue += buffDuration;
				curBufValueStr = NoTrailZeros( RoundMath( curBufValue) ) + " " + GetLocStringByKeyExt("per_second");
				
				curFlashObject.SetMemberFlashString("value",  curBufValueStr);
				curFlashObject.SetMemberFlashNumber("floatValue", curBufValue);
				
				return;
			}
		}
		
		if(itemInvComponent.ItemHasTag(itemId, 'Alcohol'))	//modSigns: FOOD-08, Connoisseur lengthens an alcohol's effects
			buffDuration *= 1 + GetWitcherPlayer().GMConnoisseurDurationBonus();	//modSigns
		
		curFlashObject = rootGFxObject.CreateFlashObject();
		if (isEdibles && GetWitcherPlayer().HasRunewordActive('Runeword 6 _Stats'))	//modSigns: FOOD-08, Dumplings on every edible (5.x: only one in a quick slot)
		{
			theGame.GetDefinitionsManager().GetAbilityAttributeValue('Runeword 6 _Stats', 'runeword6_duration_bonus', min, max);
			curBufValueStr = "<font color='#E67E0B'>" + NoTrailZeros ( RoundMath( buffDuration * (1 + min.valueMultiplicative) )) + " " + GetLocStringByKeyExt("per_second") + "</font>";
			curFlashObject.SetMemberFlashString("name", "<font color='#E67E0B'>" + GetAttributeNameLocStr('duration', false) + "</font>");
			curFlashObject.SetMemberFlashBool("enchanted", true);
		}
		else
		{
			curBufValueStr = NoTrailZeros( RoundMath( buffDuration) ) + " " + GetLocStringByKeyExt("per_second");
			curFlashObject.SetMemberFlashString("name", GetAttributeNameLocStr('duration', false));
		}
		
		curFlashObject.SetMemberFlashString("value", curBufValueStr);
		curFlashObject.SetMemberFlashNumber("floatValue", buffDuration);
		resultGFxArray.PushBackFlashObject(curFlashObject);
	}

}

// The in-combat regen row of a food or drink tooltip named by legacy's string (audit F4).
function GMFoodCombatRegenLabel(rows : CScriptedFlashArray)
{
	var row : CScriptedFlashObject;
	var i : int;

	for(i = 0; i < rows.GetLength(); i += 1)
	{
		row = rows.GetElementFlashObject(i);
		if(row.GetMemberFlashString("id") == "vitalityCombatRegen")
			row.SetMemberFlashString("name", GetLocStringByKeyExt("attribute_name_vitalityCombatRegen"));
	}
}
