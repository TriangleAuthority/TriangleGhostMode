// ITEM-01: item level from stats, as legacy. See docs/features/item.md.
// "Weapon level is determined by BASE damage value and armor level is determined by BASE armor
// reduction value" (legacy): level = Ceil((stat - base) / step), clamped to 1...max level; vanilla's
// level - 1 and its quality, Hearts of Stone, Iris and NG+ adjustments are gone. Crossbows read two more
// steps (34, 38). Bolts keep the name list, without vanilla's duplicate Blunt Bolt Legendary line.
// Bolts read legacy's levels (DI1, the owner, 2026-10-20): 5.x's quality-based bolt rule (a held bolt
// lowered by its quality, a bolt read by name at least Geralt's level) is removed.

@replaceMethod(W3GameParams)
function GetItemLevel(itemCategory : name, itemAttributes : array<SAbilityAttributeValue>, optional itemName : name, optional out baseItemLevel : int) : int
{
	var stat : SAbilityAttributeValue;
	var stat_f : float;
	var stat1,stat2,stat3,stat4,stat5,stat6,stat7 : SAbilityAttributeValue;
	var stat_min, stat_add : float;
	var level : int;

	if ( itemCategory == 'armor' )
	{
			stat_min = 25;
			stat_add = 5;
		stat = itemAttributes[0];
		level = CeilF( ( stat.valueBase - stat_min ) / stat_add );	//modSigns
	} else
	if ( itemCategory == 'boots' )
	{
			stat_min = 5;
			stat_add = 2;
		stat = itemAttributes[0];
		level = CeilF( ( stat.valueBase - stat_min ) / stat_add );	//modSigns
	} else
	if ( itemCategory == 'gloves' )
	{
			stat_min = 1;
			stat_add = 2;
		stat = itemAttributes[0];
		level = CeilF( ( stat.valueBase - stat_min ) / stat_add );	//modSigns
	} else
	if ( itemCategory == 'pants' )
	{
			stat_min = 5;
			stat_add = 2;
		stat = itemAttributes[0];
		level = CeilF( ( stat.valueBase - stat_min ) / stat_add );	//modSigns
	} else
	if ( itemCategory == 'silversword' )
	{
			stat_min = 90;
			stat_add = 10;
		stat1 = itemAttributes[0];
		stat2 = itemAttributes[1];
		stat3 = itemAttributes[2];
		stat4 = itemAttributes[3];
		stat5 = itemAttributes[4];
		stat6 = itemAttributes[5];
		stat_f = MaxF(0, stat1.valueBase - 1) + MaxF(0, stat2.valueBase - 1) + MaxF(0, stat3.valueBase - 1) + MaxF(0, stat4.valueBase - 1) + MaxF(0, stat5.valueBase - 1) + MaxF(0, stat6.valueBase - 1);	//modSigns
		level = CeilF( ( stat_f - stat_min ) / stat_add );	//modSigns
	} else
	if ( itemCategory == 'steelsword' )
	{
			stat_min = 25;
			stat_add = 8;
		stat1 = itemAttributes[0];
		stat2 = itemAttributes[1];
		stat3 = itemAttributes[2];
		stat4 = itemAttributes[3];
		stat5 = itemAttributes[4];
		stat6 = itemAttributes[5];
		stat7 = itemAttributes[6];
		stat_f = MaxF(0, stat1.valueBase - 1) + MaxF(0, stat2.valueBase - 1) + MaxF(0, stat3.valueBase - 1) + MaxF(0, stat4.valueBase - 1) + MaxF(0, stat5.valueBase - 1) + MaxF(0, stat6.valueBase - 1) + MaxF(0, stat7.valueBase - 1);	//modSigns
		level = CeilF( ( stat_f - stat_min ) / stat_add );	//modSigns
	} else
	if ( itemCategory == 'bolt' )
	{
		if ( itemName == 'Tracking Bolt' ) { level = 2; } else
		if ( itemName == 'Bait Bolt' ) { level = 2; }  else
		if ( itemName == 'Blunt Bolt' ) { level = 2; }  else
		if ( itemName == 'Broadhead Bolt' ) { level = 10; }  else
		if ( itemName == 'Target Point Bolt' ) { level = 5; }  else
		if ( itemName == 'Split Bolt' ) { level = 15; }  else
		if ( itemName == 'Explosive Bolt' ) { level = 20; }  else
		//modSigns: removed the duplicate Blunt Bolt Legendary line (level 5), so it reads 12 below
		if ( itemName == 'Broadhead Bolt Legendary' ) { level = 20; }  else
		if ( itemName == 'Target Point Bolt Legendary' ) { level = 15; }  else
		if ( itemName == 'Blunt Bolt Legendary' ) { level = 12; }  else
		if ( itemName == 'Split Bolt Legendary' ) { level = 24; }  else
		if ( itemName == 'Explosive Bolt Legendary' ) { level = 26; }

	}

	else if ( itemCategory == 'crossbow' )

	{
		stat = itemAttributes[0];
		level = 1;
		if ( stat.valueMultiplicative > 1.01 ) level = 2;
		if ( stat.valueMultiplicative > 1.1 ) level = 4;
		if ( stat.valueMultiplicative > 1.2 ) level = 8;
		if ( stat.valueMultiplicative > 1.3 ) level = 11;
		if ( stat.valueMultiplicative > 1.4 ) level = 15;
		if ( stat.valueMultiplicative > 1.5 ) level = 19;
		if ( stat.valueMultiplicative > 1.6 ) level = 22;
		if ( stat.valueMultiplicative > 1.7 ) level = 25;
		if ( stat.valueMultiplicative > 1.8 ) level = 27;
		if ( stat.valueMultiplicative > 1.9 ) level = 32;
		if ( stat.valueMultiplicative > 2.0 ) level = 34;	//modSigns
		if ( stat.valueMultiplicative > 2.1 ) level = 38;	//modSigns
	}


	//modSigns: no dancing around levels: removed level - 1 and the separate clamps
	level = Clamp(level, 1, GetWitcherPlayer().GetMaxLevel());	//modSigns
	baseItemLevel = level;
	//modSigns: removed the max level clamp (in Clamp above)

	return level;
}

@replaceMethod(CInventoryComponent)
function GetItemLevel(item : SItemUniqueId) : int
{
	var itemCategory : name;
	var itemAttributes : array<SAbilityAttributeValue>;
	var itemName : name;
	var level : int;	//modSigns: isWitcherGear, isRelicGear and baseLevel removed

	//modSigns: removed quality (only the adjustments and 5.x's bolt rule read it)

	itemCategory = GetItemCategory(item);
	itemName = GetItemName(item);
	//modSigns: removed the witcher and relic gear flags' reset

	//modSigns: removed the quality read and the witcher and relic gear flags (no quality adjustment, DI1: no bolt rule)

	switch(itemCategory)
	{
		case 'armor' :
		case 'boots' :
		case 'gloves' :
		case 'pants' :
			itemAttributes.PushBack( GetItemAttributeValue(item, 'armor') );
			break;

		case 'silversword' :
			itemAttributes.PushBack( GetItemAttributeValue(item, 'SilverDamage') );
			itemAttributes.PushBack( GetItemAttributeValue(item, 'BludgeoningDamage') );
			itemAttributes.PushBack( GetItemAttributeValue(item, 'RendingDamage') );
			itemAttributes.PushBack( GetItemAttributeValue(item, 'ElementalDamage') );
			itemAttributes.PushBack( GetItemAttributeValue(item, 'FireDamage') );
			itemAttributes.PushBack( GetItemAttributeValue(item, 'PiercingDamage') );
			break;

		case 'steelsword' :
			itemAttributes.PushBack( GetItemAttributeValue(item, 'SlashingDamage') );
			itemAttributes.PushBack( GetItemAttributeValue(item, 'BludgeoningDamage') );
			itemAttributes.PushBack( GetItemAttributeValue(item, 'RendingDamage') );
			itemAttributes.PushBack( GetItemAttributeValue(item, 'ElementalDamage') );
			itemAttributes.PushBack( GetItemAttributeValue(item, 'FireDamage') );
			itemAttributes.PushBack( GetItemAttributeValue(item, 'SilverDamage') );
			itemAttributes.PushBack( GetItemAttributeValue(item, 'PiercingDamage') );
			break;

		case 'crossbow' :
			itemAttributes.PushBack( GetItemAttributeValue(item, 'attack_power') );
			break;


		case 'bolt' :
			itemAttributes.PushBack( GetItemAttributeValue(item, 'SilverDamage') );
			break;


		default :
			break;
	}

	level = theGame.params.GetItemLevel(itemCategory, itemAttributes, itemName);	//modSigns

	//modSigns: no dancing around levels: removed NG+'s base level, the witcher gear (-2), relic (-1), Iris (-3) and Hearts of Stone (-1) adjustments and NG+'s clamp; the level is clamped by W3GameParams.GetItemLevel

	//modSigns: removed 5.x's bolt rule (a held bolt lowered by its quality; DI1, legacy's bolt levels)
	//modSigns: removed the witcher gear (-2) and relic (-1) adjustments
	if ( level < 1 ) level = 1;
	//modSigns: removed the Iris (-3) and Hearts of Stone relic and witcher gear (-1) adjustments

	return level;
}

@replaceMethod(CDefinitionsManagerAccessor)
function GetItemLevelFromName( itemName : name ) : int
{
	var itemCategory : name;
	var itemAttributes : array<SAbilityAttributeValue>;
	var min, max : SAbilityAttributeValue;
	var level : int;	//modSigns: isWitcherGear, isRelicGear, baseLevel and quality removed

	//modSigns: removed the witcher and relic gear flags and the quality read (no quality adjustment)

	itemCategory = GetItemCategory(itemName);

	switch(itemCategory)
	{
		case 'armor' :
		case 'boots' :
		case 'gloves' :
		case 'pants' :
			GetItemAttributeValueNoRandom(itemName, false, 'armor', min, max);
			itemAttributes.PushBack( max );
			break;

		case 'silversword' :
			GetItemAttributeValueNoRandom(itemName, false, 'SilverDamage', min, max);
			itemAttributes.PushBack( max );
			GetItemAttributeValueNoRandom(itemName, false, 'BludgeoningDamage', min, max);
			itemAttributes.PushBack( max );
			GetItemAttributeValueNoRandom(itemName, false, 'RendingDamage', min, max);
			itemAttributes.PushBack( max );
			GetItemAttributeValueNoRandom(itemName, false, 'ElementalDamage', min, max);
			itemAttributes.PushBack( max );
			GetItemAttributeValueNoRandom(itemName, false, 'FireDamage', min, max);
			itemAttributes.PushBack( max );
			GetItemAttributeValueNoRandom(itemName, false, 'PiercingDamage', min, max);
			itemAttributes.PushBack( max );
			break;

		case 'steelsword' :
			GetItemAttributeValueNoRandom(itemName, false, 'SlashingDamage', min, max);
			itemAttributes.PushBack( max );
			GetItemAttributeValueNoRandom(itemName, false, 'BludgeoningDamage', min, max);
			itemAttributes.PushBack( max );
			GetItemAttributeValueNoRandom(itemName, false, 'RendingDamage', min, max);
			itemAttributes.PushBack( max );
			GetItemAttributeValueNoRandom(itemName, false, 'ElementalDamage', min, max);
			itemAttributes.PushBack( max );
			GetItemAttributeValueNoRandom(itemName, false, 'FireDamage', min, max);
			itemAttributes.PushBack( max );
			GetItemAttributeValueNoRandom(itemName, false, 'SilverDamage', min, max);
			itemAttributes.PushBack( max );
			GetItemAttributeValueNoRandom(itemName, false, 'PiercingDamage', min, max);
			itemAttributes.PushBack( max );
			break;

		case 'crossbow' :
			GetItemAttributeValueNoRandom(itemName, false, 'attack_power', min, max);
			itemAttributes.PushBack( max );
			break;


		case 'bolt' :
			GetItemAttributeValueNoRandom(itemName, false, 'SilverDamage', min, max);
			itemAttributes.PushBack( max );
			break;


		default :
			break;
	}

	level = theGame.params.GetItemLevel(itemCategory, itemAttributes, itemName);	//modSigns

	//modSigns: no dancing around levels: removed NG+'s base level, the witcher gear (-2), relic (-1), Iris (-3) and Hearts of Stone (-1) adjustments and NG+'s clamp; the level is clamped by W3GameParams.GetItemLevel

	//modSigns: removed 5.x's bolt rule (a bolt read by name at least Geralt's level; DI1, legacy's bolt levels)
	//modSigns: removed the witcher gear (-2), relic (-1), Iris (-3) and Hearts of Stone (-1) adjustments and NG+'s clamp

	return level;
}
