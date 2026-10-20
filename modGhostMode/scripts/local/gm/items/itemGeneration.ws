// ITEM-02: the level a level-scaled item gets when it enters an inventory, as legacy. See
// docs/features/item.md. Found items: Geralt's level -1...+1 (quality 3 and 4), -1...0 (quality 1
// and 2), exactly (witcher gear); with a level range (AutogenUseLevelRange): Geralt's level -1...+1
// (exactly with AutogenForceLevel) clamped to the range; a merchant's stock: -1...+2, without 5.x's
// forced range tag; quest rewards: exactly Geralt's level (DI2; 5.x +1...+3); no standalone (-1) or
// NG+ (+1/+2) adjustment. When a merchant restocks, weapons more than 3 levels below Geralt leave its
// stock. Legacy returned the level; 5.x's signature is kept, so it is left in gmGeneratedLevel for the
// random bonuses (ITEM-06), and read back elsewhere with GetItemLevel.

@replaceMethod(CInventoryComponent)
function GenerateItemLevel( item : SItemUniqueId, rewardItem : bool )
{
	var stat : SAbilityAttributeValue;
	var playerLevel : int;
	var lvl, i : int;
	var quality : int;
	var ilMin, ilMax : int;

	gmGeneratedLevel = 0;	//modSigns: legacy returned 0 when it added nothing (ITEM-06 reads it)
	playerLevel = GetWitcherPlayer().GetLevel();

	lvl = playerLevel;	//modSigns: no dancing around levels (vanilla playerLevel - 1)


	if ( ( W3MerchantNPC )GetEntity() )
	{
		lvl = playerLevel + (int)(RandF()*3.9999) - 1;	//modSigns: -1...+2
		//modSigns: removed the forced AutogenUseLevelRange tag
	}
	else if ( rewardItem )
	{

		lvl = playerLevel;	//modSigns: exactly Geralt's level (DI2)
	}
	else if ( ItemHasTag( item, 'AutogenUseLevelRange') )
	{
		quality = RoundMath( CalculateAttributeValue( GetItemAttributeValue( item, 'quality' ) ) );
		ilMin = RoundMath(CalculateAttributeValue( GetItemAttributeValue( item, 'item_level_min' ) ));
		ilMax = RoundMath(CalculateAttributeValue( GetItemAttributeValue( item, 'item_level_max' ) ));

		//modSigns: removed lvl += 1 (no dancing around levels)
		if ( !ItemHasTag( item, 'AutogenForceLevel') )
			lvl = playerLevel + (int)(RandF()*2.9999) - 1;	//modSigns: -1...+1

		if ( FactsQuerySum("NewGamePlus") > 0 )
		{
			if ( lvl < ilMin + theGame.params.GetNewGamePlusLevel() ) lvl = ilMin + theGame.params.GetNewGamePlusLevel();
			if ( lvl > ilMax + theGame.params.GetNewGamePlusLevel() ) lvl = ilMax + theGame.params.GetNewGamePlusLevel();
		}
		else
		{
			if ( lvl < ilMin ) lvl = ilMin;
			if ( lvl > ilMax ) lvl = ilMax;
		}

		//modSigns: removed the witcher gear (+2), relic (+1) and Hearts of Stone (+1) bonuses
	}
	else if ( !ItemHasTag( item, 'AutogenForceLevel') )
	{
		quality = RoundMath( CalculateAttributeValue( GetItemAttributeValue( item, 'quality' ) ) );

		//modSigns: removed vanilla's spreads by quality; the level variance depends on quality
		switch( quality )	//modSigns
		{	//modSigns
		case 4:	//modSigns: relic and magic: -1...+1
		case 3:	//modSigns
			lvl = playerLevel + (int)(RandF()*2.9999) - 1;	//modSigns
			break;	//modSigns
		case 2:	//modSigns: masterwork and common: -1...0
		case 1:	//modSigns
			lvl = playerLevel + (int)(RandF()*1.9999) - 1;	//modSigns
			break;	//modSigns
		default:	//modSigns: witcher gear: exactly Geralt's level
			lvl = playerLevel;	//modSigns
			break;	//modSigns
		}	//modSigns
	}

	//modSigns: removed the standalone (-1) and NG+ (+2/+1) adjustments
	lvl = Clamp(lvl, 1, GetWitcherPlayer().GetMaxLevel());	//modSigns: no dancing around levels
	//modSigns: removed the separate clamps (in Clamp above)

	if ( ItemHasTag( item, 'PlayerSteelWeapon' ) && !( ItemHasAbility( item, 'autogen_steel_base' ) || ItemHasAbility( item, 'autogen_fixed_steel_base' ) )  ) 
	{
		if ( ItemHasTag(item, 'AutogenUseLevelRange') && ItemHasAbility(item, 'autogen_fixed_steel_base') )
			return;

		if ( ItemHasTag(item, 'AutogenUseLevelRange') )
			AddItemCraftedAbility(item, 'autogen_fixed_steel_base' );
		else
			AddItemCraftedAbility(item, 'autogen_steel_base' );

		for( i=0; i<lvl; i+=1 )
		{
			if (FactsQuerySum("StandAloneEP1") > 0)
			{
				AddItemCraftedAbility(item, 'autogen_fixed_steel_dmg', true );
				continue;
			}

			if ( ItemHasTag( item, 'AutogenForceLevel') || ItemHasTag(item, 'AutogenUseLevelRange') || FactsQuerySum("NewGamePlus") > 0 )
				AddItemCraftedAbility(item, 'autogen_fixed_steel_dmg', true );
			else
				AddItemCraftedAbility(item, 'autogen_steel_dmg', true );
		}
	}
	else if ( ItemHasTag( item, 'PlayerSilverWeapon' ) && !( ItemHasAbility( item, 'autogen_silver_base' ) || ItemHasAbility( item, 'autogen_fixed_silver_base' ) ) ) 
	{
		if ( ItemHasTag(item, 'AutogenUseLevelRange') && ItemHasAbility(item, 'autogen_fixed_silver_base') )
			return;

		if ( ItemHasTag(item, 'AutogenUseLevelRange') )
			AddItemCraftedAbility(item, 'autogen_fixed_silver_base' );
		else
			AddItemCraftedAbility(item, 'autogen_silver_base' );

		for( i=0; i<lvl; i+=1 )
		{
			if (FactsQuerySum("StandAloneEP1") > 0)
			{
				AddItemCraftedAbility(item, 'autogen_fixed_silver_dmg', true );
				continue;
			}

			if ( ItemHasTag( item, 'AutogenForceLevel') || ItemHasTag(item, 'AutogenUseLevelRange') || FactsQuerySum("NewGamePlus") > 0 )
				AddItemCraftedAbility(item, 'autogen_fixed_silver_dmg', true );
			else
				AddItemCraftedAbility(item, 'autogen_silver_dmg', true );
		}
	}
	else if ( GetItemCategory( item ) == 'armor' && !( ItemHasAbility( item, 'autogen_armor_base' ) || ItemHasAbility( item, 'autogen_fixed_armor_base' ) ) ) 
	{
		if ( ItemHasTag(item, 'AutogenUseLevelRange') && ItemHasAbility(item, 'autogen_fixed_armor_base') )
			return;

		if ( ItemHasTag(item, 'AutogenUseLevelRange') )
			AddItemCraftedAbility(item, 'autogen_fixed_armor_base' );
		else
			AddItemCraftedAbility(item, 'autogen_armor_base' );

		for( i=0; i<lvl; i+=1 )
		{
			if (FactsQuerySum("StandAloneEP1") > 0)
			{
				AddItemCraftedAbility(item, 'autogen_fixed_armor_armor', true );
				continue;
			}

			if ( ItemHasTag( item, 'AutogenForceLevel') || ItemHasTag( item, 'AutogenUseLevelRange') || FactsQuerySum("NewGamePlus") > 0 )
				AddItemCraftedAbility(item, 'autogen_fixed_armor_armor', true );
			else
				AddItemCraftedAbility(item, 'autogen_armor_armor', true );
		}
	}
	else if ( ( GetItemCategory( item ) == 'boots' || GetItemCategory( item ) == 'pants' ) && !( ItemHasAbility( item, 'autogen_pants_base' ) || ItemHasAbility( item, 'autogen_fixed_pants_base' ) ) ) 
	{
		if ( ItemHasTag(item, 'AutogenUseLevelRange') && ItemHasAbility(item, 'autogen_fixed_pants_base') )
			return;

		if ( ItemHasTag(item, 'AutogenUseLevelRange') )
			AddItemCraftedAbility(item, 'autogen_fixed_pants_base' );
		else
			AddItemCraftedAbility(item, 'autogen_pants_base' );

		for( i=0; i<lvl; i+=1 )
		{
			if (FactsQuerySum("StandAloneEP1") > 0)
			{
				AddItemCraftedAbility(item, 'autogen_fixed_pants_armor', true );
				continue;
			}

			if ( ItemHasTag( item, 'AutogenForceLevel') || ItemHasTag( item, 'AutogenUseLevelRange') || FactsQuerySum("NewGamePlus") > 0 )
				AddItemCraftedAbility(item, 'autogen_fixed_pants_armor', true );
			else
				AddItemCraftedAbility(item, 'autogen_pants_armor', true );
		}
	}
	else if ( GetItemCategory( item ) == 'gloves' && !( ItemHasAbility( item, 'autogen_gloves_base' ) || ItemHasAbility( item, 'autogen_fixed_gloves_base' ) ) ) 
	{
		if ( ItemHasTag(item, 'AutogenUseLevelRange') && ItemHasAbility(item, 'autogen_fixed_gloves_base') )
			return;

		if ( ItemHasTag(item, 'AutogenUseLevelRange') )
			AddItemCraftedAbility(item, 'autogen_fixed_gloves_base' );
		else
			AddItemCraftedAbility(item, 'autogen_gloves_base' );

		for( i=0; i<lvl; i+=1 )
		{
			if (FactsQuerySum("StandAloneEP1") > 0)
			{
				AddItemCraftedAbility(item, 'autogen_fixed_gloves_armor', true );
				continue;
			}

			if ( ItemHasTag( item, 'AutogenForceLevel') || ItemHasTag(item, 'AutogenUseLevelRange') || FactsQuerySum("NewGamePlus") > 0 )
				AddItemCraftedAbility(item, 'autogen_fixed_gloves_armor', true );
			else
				AddItemCraftedAbility(item, 'autogen_gloves_armor', true );
		}
	}
	gmGeneratedLevel = lvl;	//modSigns: legacy returned the level; the random bonuses read it (ITEM-06)
}

// ITEM-02: one more level's damage or armor on a level-scaled item (legacy; the master kits, ITEM-11).
@addMethod(CInventoryComponent)
function GMAddItemLevelAbility( item : SItemUniqueId )
{
	if ( ItemHasTag( item, 'PlayerSteelWeapon' ) )
	{
		if ( ItemHasAbility( item, 'autogen_fixed_steel_base' ) )
			AddItemCraftedAbility( item, 'autogen_fixed_steel_dmg', true );
		else
			AddItemCraftedAbility( item, 'autogen_steel_dmg', true );
	}
	else if ( ItemHasTag( item, 'PlayerSilverWeapon' ) )
	{
		if ( ItemHasAbility( item, 'autogen_fixed_silver_base' ) )
			AddItemCraftedAbility( item, 'autogen_fixed_silver_dmg', true );
		else
			AddItemCraftedAbility( item, 'autogen_silver_dmg', true );
	}
	else if ( GetItemCategory( item ) == 'armor' )
	{
		if ( ItemHasAbility( item, 'autogen_fixed_armor_base' ) )
			AddItemCraftedAbility( item, 'autogen_fixed_armor_armor', true );
		else
			AddItemCraftedAbility( item, 'autogen_armor_armor', true );
	}
	else if ( GetItemCategory( item ) == 'boots' || GetItemCategory( item ) == 'pants' )
	{
		if ( ItemHasAbility( item, 'autogen_fixed_pants_base' ) )
			AddItemCraftedAbility( item, 'autogen_fixed_pants_armor', true );
		else
			AddItemCraftedAbility( item, 'autogen_pants_armor', true );
	}
	else if ( GetItemCategory( item ) == 'gloves' )
	{
		if ( ItemHasAbility( item, 'autogen_fixed_gloves_base' ) )
			AddItemCraftedAbility( item, 'autogen_fixed_gloves_armor', true );
		else
			AddItemCraftedAbility( item, 'autogen_gloves_armor', true );
	}
}

// ITEM-02: removes the weapons more than 3 levels below Geralt's from the inventory (legacy; a merchant's
// stock when it restocks).
@addMethod(CInventoryComponent)
function GMClearLowLevelWeapons()
{
	var witcher : W3PlayerWitcher;
	var i : int;
	var allItems : array<SItemUniqueId>;
	var id : SItemUniqueId;
	var witcherLevel : int;

	witcher = GetWitcherPlayer();
	if(!witcher)
		return;
	allItems = GetAllWeapons();
	witcherLevel = witcher.GetLevel();
	for(i = allItems.Size() - 1; i >= 0; i -= 1)
	{
		id = allItems[i];
		if(witcherLevel - GetItemLevel(id) > 3)
			RemoveItem(id, GetItemQuantity(id));
	}
}

// ITEM-02: a merchant restocking (its funds refreshed: lastDayOfInteraction moved on) drops its
// low-level weapons, as legacy's OnInteraction did after IncreaseFunds.
@wrapMethod(W3MerchantNPC)
function OnInteraction( actionName : string, activator : CEntity )
{
	var day : int;
	var res : bool;

	day = lastDayOfInteraction;
	res = wrappedMethod( actionName, activator );
	if ( actionName == "Talk" && lastDayOfInteraction != day && GetInventory() )
		GetInventory().GMClearLowLevelWeapons();
	return res;
}
