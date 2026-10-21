// ALCH-16: oils (legacy's, the owner's DL9). Data in gm_alch.xml (gen_alch.py): +25% attack power at
// every tier, +5% crit chance from tier 2, +25% crit damage at tier 3, no resistance reduction (0 in every
// version); Hanged Man's Venom on steel swords only (5.x's SilverOil tag dropped). The oil values are read
// with SKL-14's code (skills/oils.ws: wearing off; damage/formula.ws: resistance reduction). Here: the
// ogroid oil's crit and resistance attributes are named vsOgre_ (as its attack power; 1.32 and 5.x looked
// for vsTroll_, which no oil has), and the oils on a sword are removed when it moves to another inventory
// (legacy's stuck-oil fix). 5.x's automatic oiling and the re-apply of a brewed higher tier stay (DL9).
// See docs/features/alch.md.

// 5.x body; changes marked //modSigns.
@replaceMethod
function MonsterCategoryToCriticalChanceBonus(type : EMonsterCategory) : name
{
	switch(type)
	{
		case MC_Beast :				return 'vsBeast_critical_hit_chance';
		case MC_Cursed :			return 'vsCursed_critical_hit_chance';
		case MC_Draconide :			return 'vsDraconide_critical_hit_chance';
		case MC_Human :				return 'vsHuman_critical_hit_chance';
		case MC_Hybrid :			return 'vsHybrid_critical_hit_chance';
		case MC_Insectoid :			return 'vsInsectoid_critical_hit_chance';
		case MC_Magicals :			return 'vsMagicals_critical_hit_chance';
		case MC_Necrophage :		return 'vsNecrophage_critical_hit_chance';
		case MC_Relic :				return 'vsRelic_critical_hit_chance';
		case MC_Specter :			return 'vsSpecter_critical_hit_chance';
		case MC_Troll :				return 'vsOgre_critical_hit_chance';	//modSigns: the ogroid oil's attribute (legacy)
		case MC_Vampire :			return 'vsVampire_critical_hit_chance';
		
		default :				return '';
	}
}

// 5.x body; changes marked //modSigns.
@replaceMethod
function MonsterCategoryToCriticalDamageBonus(type : EMonsterCategory) : name
{
	switch(type)
	{
		case MC_Beast :				return 'vsBeast_critical_hit_damage_bonus';
		case MC_Cursed :			return 'vsCursed_critical_hit_damage_bonus';
		case MC_Draconide :			return 'vsDraconide_critical_hit_damage_bonus';
		case MC_Human :				return 'vsHuman_critical_hit_damage_bonus';
		case MC_Hybrid :			return 'vsHybrid_critical_hit_damage_bonus';
		case MC_Insectoid :			return 'vsInsectoid_critical_hit_damage_bonus';
		case MC_Magicals :			return 'vsMagicals_critical_hit_damage_bonus';
		case MC_Necrophage :		return 'vsNecrophage_critical_hit_damage_bonus';
		case MC_Relic :				return 'vsRelic_critical_hit_damage_bonus';
		case MC_Specter :			return 'vsSpecter_critical_hit_damage_bonus';
		case MC_Troll :				return 'vsOgre_critical_hit_damage_bonus';	//modSigns: the ogroid oil's attribute (legacy)
		case MC_Vampire :			return 'vsVampire_critical_hit_damage_bonus';
		
		default :				return '';
	}
}

// 5.x body; changes marked //modSigns.
@replaceMethod
function MonsterCategoryToResistReduction(type : EMonsterCategory) : name
{
	switch(type)
	{
		case MC_Beast :				return 'vsBeast_resist_reduction';
		case MC_Cursed :			return 'vsCursed_resist_reduction';
		case MC_Draconide :			return 'vsDraconide_resist_reduction';
		case MC_Human :				return 'vsHuman_resist_reduction';
		case MC_Hybrid :			return 'vsHybrid_resist_reduction';
		case MC_Insectoid :			return 'vsInsectoid_resist_reduction';
		case MC_Magicals :			return 'vsMagicals_resist_reduction';
		case MC_Necrophage :		return 'vsNecrophage_resist_reduction';
		case MC_Relic :				return 'vsRelic_resist_reduction';
		case MC_Specter :			return 'vsSpecter_resist_reduction';
		case MC_Troll :				return 'vsOgre_resist_reduction';	//modSigns: the ogroid oil's attribute (legacy)
		case MC_Vampire :			return 'vsVampire_resist_reduction';
		
		default :				return '';
	}
}

// Legacy's stuck-oil fix: a sword (not a singleton item) that moves to another inventory loses its oils
// and the oil abilities on the item (legacy's GiveItemTo; the checks before the transfer are 5.x's).
@wrapMethod(CInventoryComponent)
function GiveItemTo( otherInventory : CInventoryComponent, itemId : SItemUniqueId, optional quantity : int, optional refreshNewFlag : bool, optional forceTransferNoDrops : bool, optional informGUI : bool ) : SItemUniqueId
{
	var q : int;

	q = quantity;
	if(q == 0)
		q = 1;
	q = Clamp(q, 0, GetItemQuantity(itemId));
	if(q > 0 && !IsItemSingletonItem(itemId) && CanItemHaveOil(itemId)
		&& ( forceTransferNoDrops || !( ItemHasTag(itemId, 'NoDrop') && !ItemHasTag(itemId, 'Lootable') ) ))
	{
		RemoveAllOilsFromItem(itemId);
		GMRemoveAllOilAbilitiesFromItem(itemId);
	}
	return wrappedMethod(otherInventory, itemId, quantity, refreshNewFlag, forceTransferNoDrops, informGUI);
}

// Legacy's RemoveAllOilAbilitiesFromItem: every oil's ability off the item (an oil from an older save can
// stay on the sword as an ability after its effect is gone).
@addMethod(CInventoryComponent)
function GMRemoveAllOilAbilitiesFromItem( id : SItemUniqueId )
{
	RemoveItemCraftedAbility( id, 'BeastOil_1' );
	RemoveItemCraftedAbility( id, 'BeastOil_2' );
	RemoveItemCraftedAbility( id, 'BeastOil_3' );
	RemoveItemCraftedAbility( id, 'CursedOil_1' );
	RemoveItemCraftedAbility( id, 'CursedOil_2' );
	RemoveItemCraftedAbility( id, 'CursedOil_3' );
	RemoveItemCraftedAbility( id, 'HangedManVenom_1' );
	RemoveItemCraftedAbility( id, 'HangedManVenom_2' );
	RemoveItemCraftedAbility( id, 'HangedManVenom_3' );
	RemoveItemCraftedAbility( id, 'HybridOil_1' );
	RemoveItemCraftedAbility( id, 'HybridOil_2' );
	RemoveItemCraftedAbility( id, 'HybridOil_3' );
	RemoveItemCraftedAbility( id, 'InsectoidOil_1' );
	RemoveItemCraftedAbility( id, 'InsectoidOil_2' );
	RemoveItemCraftedAbility( id, 'InsectoidOil_3' );
	RemoveItemCraftedAbility( id, 'MagicalsOil_1' );
	RemoveItemCraftedAbility( id, 'MagicalsOil_2' );
	RemoveItemCraftedAbility( id, 'MagicalsOil_3' );
	RemoveItemCraftedAbility( id, 'NecrophageOil_1' );
	RemoveItemCraftedAbility( id, 'NecrophageOil_2' );
	RemoveItemCraftedAbility( id, 'NecrophageOil_3' );
	RemoveItemCraftedAbility( id, 'SpecterOil_1' );
	RemoveItemCraftedAbility( id, 'SpecterOil_2' );
	RemoveItemCraftedAbility( id, 'SpecterOil_3' );
	RemoveItemCraftedAbility( id, 'VampireOil_1' );
	RemoveItemCraftedAbility( id, 'VampireOil_2' );
	RemoveItemCraftedAbility( id, 'VampireOil_3' );
	RemoveItemCraftedAbility( id, 'DraconideOil_1' );
	RemoveItemCraftedAbility( id, 'DraconideOil_2' );
	RemoveItemCraftedAbility( id, 'DraconideOil_3' );
	RemoveItemCraftedAbility( id, 'OgreOil_1' );
	RemoveItemCraftedAbility( id, 'OgreOil_2' );
	RemoveItemCraftedAbility( id, 'OgreOil_3' );
	RemoveItemCraftedAbility( id, 'RelicOil_1' );
	RemoveItemCraftedAbility( id, 'RelicOil_2' );
	RemoveItemCraftedAbility( id, 'RelicOil_3' );
}
