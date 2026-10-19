// ARM-02: armor classes and stamina costs. A piece's class is the item's own (Levity, Balance and
// Heft no longer change it, DA7; their legacy stamina trades are ENCH-10's). Geralt's melee and
// agility actions (attacks, parries, counters, dodges, rolls, sprint, jump; not usable items) cost
// -7.5% per light piece, +12.5% per heavy piece and -12.5% per missing piece (4 light -30%, 4 heavy
// +50%, naked -50%); signs cost +12.5% per heavy piece. See docs/features/arm.md.

// ARM-02: the class is the item's (DA7: the glyphwords no longer change it).
@replaceMethod(CInventoryComponent)
function GetArmorType(item : SItemUniqueId) : EArmorType
{
	//modSigns: removed isItemEquipped and the class change of Glyphwords 2, 3 and 4 (Levity, Balance, Heft)

	if(ItemHasTag(item, 'LightArmor'))
		return EAT_Light;
	else if(ItemHasTag(item, 'MediumArmor'))
		return EAT_Medium;
	else if(ItemHasTag(item, 'HeavyArmor'))
		return EAT_Heavy;

	return EAT_Undefined;
}

// ARM-02: the class of an item definition (legacy's GetArmorTypeByName, for tooltips).
@addMethod(CInventoryComponent)
public function GMGetArmorTypeByName(itemName : name) : EArmorType
{
	if(theGame.GetDefinitionsManager().ItemHasTag(itemName, 'LightArmor'))
		return EAT_Light;
	else if(theGame.GetDefinitionsManager().ItemHasTag(itemName, 'MediumArmor'))
		return EAT_Medium;
	else if(theGame.GetDefinitionsManager().ItemHasTag(itemName, 'HeavyArmor'))
		return EAT_Heavy;

	return EAT_Undefined;
}

// ARM-02: the armor pieces worn (chest, boots, trousers, gloves) by class: [light, medium, heavy].
@addMethod(CInventoryComponent)
public function GMCountArmorPieces(out pieces : array<int>)
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
		if(GetItemEquippedOnSlot(slots[i], item))
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

// ARM-02: the share added to a melee or agility action's cost (negative: cheaper).
function GMStaminaArmorPenalty() : float
{
	var pieces : array<int>;

	GetWitcherPlayer().GetInventory().GMCountArmorPieces(pieces);
	return -pieces[0] * 0.075 + pieces[2] * 0.125 - (4 - pieces[0] - pieces[1] - pieces[2]) * 0.125;
}

// ARM-02: the share added to a sign's cost.
function GMSignCastingArmorPenalty() : float
{
	var pieces : array<int>;

	GetWitcherPlayer().GetInventory().GMCountArmorPieces(pieces);
	return pieces[2] * 0.125;
}

@wrapMethod(W3AbilityManager)
function GetStaminaActionCost(action : EStaminaActionType, out cost : float, out delay : float, optional fixedCost : float, optional fixedDelay : float, optional abilityName : name, optional dt : float, optional costMult : float)
{
	wrappedMethod(action, cost, delay, fixedCost, fixedDelay, abilityName, dt, costMult);
	if(owner == GetWitcherPlayer() && cost > 0)
	{
		if(action == ESAT_Ability && IsSkillSign(SkillNameToEnum(abilityName)))
			cost = ClampF(cost * (1 + GMSignCastingArmorPenalty()), 0, 100);
		else if(GMIsMeleeStaminaAction(action) && action != ESAT_UsableItem)
			cost = ClampF(cost * (1 + GMStaminaArmorPenalty()), 0, 100);
	}
}

@wrapMethod(W3PlayerAbilityManager)
function GetSkillStaminaUseCost(skill : ESkill, optional isPerSec : bool) : float
{
	var cost : float;

	cost = wrappedMethod(skill, isPerSec);
	if(owner == GetWitcherPlayer() && IsSkillSign(skill))
		cost = ClampF(cost * (1 + GMSignCastingArmorPenalty()), 0, 100);
	return cost;
}
