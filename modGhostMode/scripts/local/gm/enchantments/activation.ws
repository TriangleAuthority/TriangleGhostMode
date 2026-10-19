// ENCH-01: when runewords and glyphwords are active (the owner's DE1, 2026-10-19: legacy's rule).
// A runeword works only from the drawn sword; Preservation and Dumplings (Runewords 5 and 6) from an
// equipped one. A glyphword works only from the worn chest armor. Each word's checks are switched to
// these functions with that word's port slice (docs/features/ench.md).

// ENCH-01: legacy's body (5.x's counted either equipped sword, drawn or not).
@replaceMethod(W3PlayerWitcher)
function HasRunewordActive(abilityName : name) : bool
{
	var item : SItemUniqueId;
	var hasRuneword : bool;

	hasRuneword = false;	//modSigns

	if(GetItemEquippedOnSlot(EES_SteelSword, item) && (IsItemHeld(item) || abilityName == 'Runeword 5 _Stats' || abilityName == 'Runeword 6 _Stats'))	//modSigns: only the drawn sword (or an equipped one, for Runewords 5 and 6)
	{
		hasRuneword = inv.ItemHasAbility(item, abilityName);
	}

	if(!hasRuneword)
	{
		if(GetItemEquippedOnSlot(EES_SilverSword, item) && (IsItemHeld(item) || abilityName == 'Runeword 5 _Stats' || abilityName == 'Runeword 6 _Stats'))	//modSigns: only the drawn sword (or an equipped one, for Runewords 5 and 6)
		{
			hasRuneword = inv.ItemHasAbility(item, abilityName);
		}
	}

	return hasRuneword;
}

// ENCH-01: legacy's glyphword check, the worn chest armor only.
@addMethod(W3PlayerWitcher)
public function HasGlyphwordActive(abilityName : name) : bool
{
	var item : SItemUniqueId;

	if(GetItemEquippedOnSlot(EES_Armor, item))
		return inv.ItemHasAbility(item, abilityName);
	return false;
}
