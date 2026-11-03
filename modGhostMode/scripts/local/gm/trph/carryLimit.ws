// TRPH-02: a trophy's carry bonus counts once (the Wight trophy's +20, wight_trophy_stats). The horse manager gives
// a trophy's abilities but base_trophy_stats to Geralt (EquipItem) and also keeps every ability of the item among the
// horse's (horseAbilities); GetMaxRunEncumbrance adds the horse's 'encumbrance' to Geralt's, so the +20 the tooltip
// and the changelist give raised the limit by 40 (1.32's, legacy's and 5.x's code). The horse's value leaves out what
// the trophy gives Geralt; saddlebags, which work through the horse, are unchanged. See docs/features/trph.md.
@wrapMethod(W3HorseManager)
function GetHorseAttributeValue(attributeName : name, excludeItems : bool) : SAbilityAttributeValue
{
	var val, mn, mx : SAbilityAttributeValue;
	var abls : array<name>;
	var trophy : SItemUniqueId;
	var dm : CDefinitionsManagerAccessor;
	var i : int;

	val = wrappedMethod(attributeName, excludeItems);
	if(attributeName != 'encumbrance' || excludeItems)
		return val;
	trophy = GetItemInSlot(EES_HorseTrophy);
	if(!inv.IsIdValid(trophy))
		return val;
	dm = theGame.GetDefinitionsManager();
	inv.GetItemAbilities(trophy, abls);
	for(i = 0; i < abls.Size(); i += 1)
	{
		if(abls[i] == 'base_trophy_stats' || !thePlayer.HasAbility(abls[i]))
			continue;
		dm.GetAbilityAttributeValue(abls[i], attributeName, mn, mx);
		val -= GetAttributeRandomizedValue(mn, mx);
	}
	return val;
}
