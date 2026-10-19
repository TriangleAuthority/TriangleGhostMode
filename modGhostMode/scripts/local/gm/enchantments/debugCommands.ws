// ENCH-02 (and ARM-01's armor pair): legacy's debug console commands that enchant or unenchant the
// equipped steel sword, silver sword or chest armor with a word ('Runeword 2', 'Glyphword 7', ...).
// Legacy's names (legacy temp.ws); like the enchanting menu, they remove an enchantment before adding one.

exec function enchantSteel(n : name)
{
	GMEnchantSlot(EES_SteelSword, n);
}

exec function enchantSilver(n : name)
{
	GMEnchantSlot(EES_SilverSword, n);
}

exec function enchantArmor(n : name)
{
	GMEnchantSlot(EES_Armor, n);
}

exec function unenchantSteel()
{
	GMEnchantSlot(EES_SteelSword, '');
}

exec function unenchantSilver()
{
	GMEnchantSlot(EES_SilverSword, '');
}

exec function unenchantArmor()
{
	GMEnchantSlot(EES_Armor, '');
}

// Enchants the item in the slot with the word n, or removes its enchantment when n is empty. Returns
// whether the game accepted it.
function GMEnchantSlot(slot : EEquipmentSlots, n : name) : bool
{
	var itemId : SItemUniqueId;

	if(!GetWitcherPlayer().GetItemEquippedOnSlot(slot, itemId))
		return false;
	thePlayer.inv.UnenchantItem(itemId);	// as the enchanting menu does (legacy's commands stacked a second word's ability)
	if(!IsNameValid(n))
		return !thePlayer.inv.IsItemEnchanted(itemId);
	return thePlayer.inv.EnchantItem(itemId, n, getEnchamtmentStatName(n));
}
