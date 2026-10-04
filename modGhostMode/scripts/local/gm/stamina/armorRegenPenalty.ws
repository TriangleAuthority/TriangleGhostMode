// STAM-05: armor does not change stamina regen (vanilla: light armor +10%, heavy -10%, ...);
// armor classes affect stamina costs instead (ARM). The option "Enable stamina regen penalty
// for armors" restores the vanilla behaviour. With the option off, the armor regen modifier
// is also hidden from item tooltips.
// See docs/features/stam.md.

function GMIsArmorRegenPenaltyEnabled() : bool
{
	return GMGetOptionBool('GMGameplayOptions', 'GMArmorRegenPenalty');
}

// The armor regen bonus used by the stamina regen effect and shown in the character panel.
@wrapMethod(W3PlayerWitcher)
function CalculatedArmorStaminaRegenBonus() : float
{
	if(!GMIsArmorRegenPenaltyEnabled())
		return 0;
	return wrappedMethod();
}

function GMRemoveArmorRegenStat(out itemStats : array<SAttributeTooltip>)
{
	var i : int;

	if(GMIsArmorRegenPenaltyEnabled())
		return;
	for(i = itemStats.Size() - 1; i >= 0; i -= 1)
	{
		if(itemStats[i].originName == 'staminaRegen_armor_mod')
			itemStats.Erase(i);
	}
}

// Item stats for tooltips (GetItemStats, GetItemBaseStats) and by item name (shops, crafting).
// Tooltips only list attributes that have a row in tooltip_settings.csv; vanilla has none for
// staminaRegen_armor_mod, Ghost Mode adds one (to be ported with its other tooltip rows), and
// this filter keeps the line out while the option is off.
@wrapMethod(CInventoryComponent)
function GetItemTooltipAttributes(itemId : SItemUniqueId, attributes : array<name>, out itemStats : array<SAttributeTooltip>, optional respectAttributeOrder : bool)
{
	wrappedMethod(itemId, attributes, itemStats, respectAttributeOrder);
	GMRemoveArmorRegenStat(itemStats);
}

@wrapMethod(CInventoryComponent)
function GetItemStatsFromName(itemName : name, out itemStats : array<SAttributeTooltip>)
{
	wrappedMethod(itemName, itemStats);
	GMRemoveArmorRegenStat(itemStats);
}
