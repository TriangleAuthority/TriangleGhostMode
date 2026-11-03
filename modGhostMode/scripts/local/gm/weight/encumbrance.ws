// WGT: what items weigh towards Geralt's load (docs/features/wgt.md).

// WGT-02: "Reduce item encumbrance (%)" (OPT's menu entry, 0 to 100, default 0) as a share, 0 to 1.
function GMGetEncumbranceMult() : float
{
	return ClampF(GMGetOptionFloat('GMGameplayOptions', 'GMEncumbranceMultiplier') / 100, 0, 1);
}

// WGT-01: every item that counts towards the load (IsItemEncumbranceItem, 5.x's: also false while "Ignore Item
// Weight" is on, DW1) weighs its full weight x quantity, at least 0.01 per item, less WGT-02's reduction; 1.32's
// and 5.x's category rules (gear at half, junk at a fifth, alchemy items, ingredients, food and books at 0) are
// gone. Legacy's debug fact (WGT-12) is not ported (PW8).
@replaceMethod(CInventoryComponent)
function GetItemEncumbrance(item : SItemUniqueId) : float
{
	var itemCategory : name;
	var weight : float; //modSigns
	if ( IsItemEncumbranceItem( item ) )
	{
		weight = GetItemWeight( item ); //modSigns
		if( weight < 0.01 ) //modSigns
			weight = 0.01; //modSigns
		weight *= GetItemQuantity( item ) * ( 1 - GMGetEncumbranceMult() ); //modSigns
		if( weight < 0.01 ) //modSigns
			weight = 0; //modSigns
		return weight; //modSigns
		//modSigns: removed 1.32's category rules (quest and key 0.01, usable, upgrade and junk a fifth, alchemy items, ingredients, food and books 0, the rest half)
	}
	return 0;
}
