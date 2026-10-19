// ARM-04: generic armor sets. Four pieces of one class (chest, boots, trousers, gloves) that are not
// witcher set pieces and not tagged gm_NoSetBonuses give a bonus: light +30 degrees of safe dodge
// angle (read by DEF-01, defense/dodge.ws), medium +0.25 toxicity decay per second, heavy +10% to
// every damage resistance (the abilities ArmorType<Class>SetBonusAbility, gm_armor.xml). Item
// tooltips show the generic set line. See docs/features/arm.md.

// ARM-04: whether a piece counts towards a generic set (legacy: without Blood and Wine, witcher
// set pieces count too).
@addMethod(CInventoryComponent)
public function GMIsSetArmorType(item : SItemUniqueId) : bool
{
	return IsItemAnyArmor(item) && !ItemHasTag(item, 'gm_NoSetBonuses') &&
			(!theGame.GetDLCManager().IsEP2Enabled() || !ItemHasTag(item, theGame.params.ITEM_SET_TAG_BONUS));
}

@addMethod(CInventoryComponent)
public function GMIsSetArmorTypeByName(itemName : name) : bool
{
	var dm : CDefinitionsManagerAccessor;

	dm = theGame.GetDefinitionsManager();
	return dm.ItemHasTag(itemName, theGame.params.TAG_ARMOR) && !dm.ItemHasTag(itemName, 'gm_NoSetBonuses') &&
			(!theGame.GetDLCManager().IsEP2Enabled() || !dm.ItemHasTag(itemName, theGame.params.ITEM_SET_TAG_BONUS));
}

// ARM-04: the generic set pieces worn by class: [light, medium, heavy].
@addMethod(CInventoryComponent)
public function GMCountSetArmorPieces(out pieces : array<int>)
{
	var item : SItemUniqueId;
	var slots : array<EEquipmentSlots>;
	var i : int;
	var armorType : EArmorType;

	slots.PushBack(EES_Armor);
	slots.PushBack(EES_Boots);
	slots.PushBack(EES_Pants);
	slots.PushBack(EES_Gloves);
	pieces.Clear();
	pieces.Resize(3);
	for(i = 0; i < slots.Size(); i += 1)
	{
		if(GetItemEquippedOnSlot(slots[i], item) && GMIsSetArmorType(item))
		{
			armorType = GetArmorType(item);
			if(armorType == EAT_Light)
				pieces[0] += 1;
			else if(armorType == EAT_Medium)
				pieces[1] += 1;
			else if(armorType == EAT_Heavy)
				pieces[2] += 1;
		}
	}
}

// ARM-04: the generic set worn, if any.
@addMethod(CInventoryComponent)
public function GMGetSetArmorType() : EArmorType
{
	var pieces : array<int>;

	GMCountSetArmorPieces(pieces);
	if( pieces[0] == 4 )
		return EAT_Light;
	if( pieces[1] == 4 )
		return EAT_Medium;
	if( pieces[2] == 4 )
		return EAT_Heavy;
	return EAT_Undefined;
}

// ARM-04: the tooltip line of a piece: its count of the set ("2/4") and the bonus text; returns the count.
@addMethod(CInventoryComponent)
public function GMGetSetArmorItemDescription(item : SItemUniqueId, out counterText : string, out descrText : string) : int
{
	var armorType : EArmorType;
	var pieces : array<int>;
	var count : int;

	if(!GMIsSetArmorType(item))
		return 0;
	GMCountSetArmorPieces(pieces);
	armorType = GetArmorType(item);
	switch(armorType)
	{
		case EAT_Heavy:		count = pieces[2]; break;
		case EAT_Medium:	count = pieces[1]; break;
		case EAT_Light:		count = pieces[0]; break;
	}
	counterText = count + "/4";
	descrText = GMGetSetArmorDescriptionByType(armorType);
	return count;
}

// ARM-04: the generic set's bonus text for a class.
function GMGetSetArmorDescriptionByType(armorType : EArmorType) : string
{
	var paramsInt : array<int>;
	var paramsString : array<string>;
	var min, max : SAbilityAttributeValue;
	var dm : CDefinitionsManagerAccessor;

	dm = theGame.GetDefinitionsManager();
	switch(armorType)
	{
		case EAT_Heavy:
			dm.GetAbilityAttributeValue('ArmorTypeHeavySetBonusAbility', 'slashing_resistance_perc', min, max);
			paramsInt.PushBack(RoundMath(min.valueAdditive * 100));
			return GetLocStringByKeyExtWithParams("item_desc_armor_type_heavy_set_bonus", paramsInt);
		case EAT_Medium:
			dm.GetAbilityAttributeValue('ArmorTypeMediumSetBonusAbility', 'toxicityRegen', min, max);
			paramsString.PushBack(NoTrailZeros(-min.valueAdditive));
			return GetLocStringByKeyExtWithParams("item_desc_armor_type_medium_set_bonus", , , paramsString);
		case EAT_Light:
			dm.GetAbilityAttributeValue('ArmorTypeLightSetBonusAbility', 'dodge_safe_ange_dist_deg', min, max);
			paramsInt.PushBack(RoundMath(min.valueAdditive));
			return GetLocStringByKeyExtWithParams("item_desc_armor_type_light_set_bonus", paramsInt);
	}
	return "";
}

// ARM-04: gives Geralt the bonus of the generic set he wears (legacy's ManageSetArmorTypeBonus).
@addMethod(W3PlayerAbilityManager)
public function GMManageSetArmorTypeBonus()
{
	var toxicity : W3Effect_Toxicity;
	var hadAbl : bool;

	hadAbl = charStats.HasAbility('ArmorTypeMediumSetBonusAbility');

	charStats.RemoveAbility('ArmorTypeHeavySetBonusAbility');
	charStats.RemoveAbility('ArmorTypeMediumSetBonusAbility');
	charStats.RemoveAbility('ArmorTypeLightSetBonusAbility');
	switch( owner.GetInventory().GMGetSetArmorType() )
	{
		case EAT_Heavy:
			charStats.AddAbility('ArmorTypeHeavySetBonusAbility', false);
			break;
		case EAT_Medium:
			charStats.AddAbility('ArmorTypeMediumSetBonusAbility', false);
			break;
		case EAT_Light:
			charStats.AddAbility('ArmorTypeLightSetBonusAbility', false);
			break;
	}
	if(hadAbl || charStats.HasAbility('ArmorTypeMediumSetBonusAbility'))
	{
		toxicity = (W3Effect_Toxicity)owner.GetBuff(EET_Toxicity);
		if(toxicity)
			toxicity.RecalcEffectValue();
	}
}

function GMIsArmorSlot(slot : EEquipmentSlots) : bool
{
	return slot == EES_Armor || slot == EES_Boots || slot == EES_Pants || slot == EES_Gloves;
}

@wrapMethod(W3PlayerWitcher)
function EquipItemInGivenSlot(item : SItemUniqueId, slot : EEquipmentSlots, ignoreMounting : bool, optional toHand : bool) : bool
{
	var ret : bool;

	ret = wrappedMethod(item, slot, ignoreMounting, toHand);
	if(GMIsArmorSlot(slot))
		((W3PlayerAbilityManager)abilityManager).GMManageSetArmorTypeBonus();
	return ret;
}

@wrapMethod(W3PlayerWitcher)
function UnequipItemFromSlot(slot : EEquipmentSlots, optional reequipped : bool) : bool
{
	var ret : bool;

	ret = wrappedMethod(slot, reequipped);
	if(GMIsArmorSlot(slot))
		((W3PlayerAbilityManager)abilityManager).GMManageSetArmorTypeBonus();
	return ret;
}

// ARM-04: the medium set's faster toxicity decay.
@wrapMethod(W3Effect_Toxicity)
function RecalcEffectValue()
{
	var min, max : SAbilityAttributeValue;

	wrappedMethod();
	if(IsNameValid(abilityName) && thePlayer.HasAbility('ArmorTypeMediumSetBonusAbility'))
	{
		theGame.GetDefinitionsManager().GetAbilityAttributeValue('ArmorTypeMediumSetBonusAbility', 'toxicityRegen', min, max);
		effectValue += min;
	}
}
