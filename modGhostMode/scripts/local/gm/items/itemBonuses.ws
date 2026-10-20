// ITEM-06: random item bonuses as legacy. See docs/features/item.md. When an item first enters an
// inventory (Geralt's, a merchant's, a container's) and has no DoNotEnhance: items of quality 1 to 4
// get their quality ability; witcher gear (5) nothing more; relics (4) nothing, except chest armor one
// common resistance; chest armor one common resistance (quality 1+), one masterwork bonus (2+) and one
// magical (3+), the last two repeated at levels 10, 20 and 30; gloves, trousers and boots one masterwork
// (2+) and one magical (3+); swords one common (1+), one masterwork (2+), one magical (3+), each repeated
// at levels 10, 20 and 30. The level is legacy's: when Geralt or a merchant receives a level-scaled item
// (OnItemAdded), the level GenerateItemLevel just gave it; otherwise (an item generated before, not
// level-scaled, a container's or a merchant's stock enhanced later) the item's level from its stats
// (GetItemLevel). The two differ for the level-scaled secondary weapons (axes, clubs, maces), whose
// fixed base damage reads 1 to 3 levels above the generated one (owner, 2026-10-20). The bonus lists
// are legacy's (W3GameParams.Init*Abilities), the values ITEM-07's (gm_item_quality.xml).

@addField(CInventoryComponent)
var gmInItemAdded : bool;	// ITEM-06: true while OnItemAdded runs (legacy's OnItemAdded passed the generated level)

@addField(CInventoryComponent)
var gmGeneratedLevel : int;	// ITEM-06: the level GenerateItemLevel last returned in legacy (0: none)

// ITEM-06: marks OnItemAdded, where legacy passed the level GenerateItemLevel had just generated.
@wrapMethod(CInventoryComponent)
function OnItemAdded(data : SItemChangedData)
{
	var res, prevIn : bool;
	var prevLevel : int;

	prevIn = gmInItemAdded;
	prevLevel = gmGeneratedLevel;
	gmInItemAdded = true;
	gmGeneratedLevel = 0;
	res = wrappedMethod(data);
	gmInItemAdded = prevIn;
	gmGeneratedLevel = prevLevel;
	return res;
}

@addField(W3GameParams)
var gmArmorCommonAbilities : array<name>;	// legacy's ARMOR_COMMON_ABILITIES: random resistances for all armor

@addField(W3GameParams)
var gmWeaponCommonAbilities : array<name>;	// legacy's WEAPON_COMMON_ABILITIES

@addMethod(W3GameParams)
function GMGetRandomCommonArmorAbility() : name
{
	return gmArmorCommonAbilities[RandRange(gmArmorCommonAbilities.Size())];
}

@addMethod(W3GameParams)
function GMGetRandomCommonWeaponAbility() : name
{
	return gmWeaponCommonAbilities[RandRange(gmWeaponCommonAbilities.Size())];
}

@replaceMethod(W3GameParams)
function InitArmorAbilities()
{

	gmArmorCommonAbilities.PushBack('MA_SlashingResistance');	//modSigns
	gmArmorCommonAbilities.PushBack('MA_PiercingResistance');	//modSigns
	gmArmorCommonAbilities.PushBack('MA_BludgeoningResistance');	//modSigns
	gmArmorCommonAbilities.PushBack('MA_RendingResistance');	//modSigns
	gmArmorCommonAbilities.PushBack('MA_ElementalResistance');	//modSigns
	
	//modSigns: removed ARMOR_MASTERWORK_ABILITIES.PushBack('MA_Armor');; ARMOR_MASTERWORK_ABILITIES.PushBack('MA_SlashingResistance');; ARMOR_MASTERWORK_ABILITIES.PushBack('
	ARMOR_MASTERWORK_ABILITIES.PushBack('MA_BurningResistance');
	ARMOR_MASTERWORK_ABILITIES.PushBack('MA_PoisonResistance');	//modSigns
	ARMOR_MASTERWORK_ABILITIES.PushBack('MA_BleedingResistance');	//modSigns
	ARMOR_MASTERWORK_ABILITIES.PushBack('MA_AdrenalineGain');	//modSigns
	ARMOR_MASTERWORK_ABILITIES.PushBack('MA_Vitality');	//modSigns
	
	//modSigns: removed ARMOR_MAGICAL_ABILITIES.PushBack('MA_PoisonResistance');; ARMOR_MAGICAL_ABILITIES.PushBack('MA_BleedingResistance');; ARMOR_MAGICAL_ABILITIES.PushBack
	ARMOR_MAGICAL_ABILITIES.PushBack('MA_AardIntensity');
	ARMOR_MAGICAL_ABILITIES.PushBack('MA_IgniIntensity');
	ARMOR_MAGICAL_ABILITIES.PushBack('MA_QuenIntensity');
	ARMOR_MAGICAL_ABILITIES.PushBack('MA_YrdenIntensity');
	ARMOR_MAGICAL_ABILITIES.PushBack('MA_AxiiIntensity');
}

@replaceMethod(W3GameParams)
function InitGlovesAbilities()
{
	//modSigns: removed GLOVES_MASTERWORK_ABILITIES.PushBack('MA_Armor');

	GLOVES_MASTERWORK_ABILITIES.PushBack('MA_BurningResistance');
	GLOVES_MASTERWORK_ABILITIES.PushBack('MA_PoisonResistance');	//modSigns
	GLOVES_MASTERWORK_ABILITIES.PushBack('MA_BleedingResistance');	//modSigns
	GLOVES_MASTERWORK_ABILITIES.PushBack('MA_AdrenalineGain');	//modSigns
	
	//modSigns: removed GLOVES_MAGICAL_ABILITIES.PushBack('MA_PoisonResistance');; GLOVES_MAGICAL_ABILITIES.PushBack('MA_BleedingResistance');
	GLOVES_MAGICAL_ABILITIES.PushBack('MA_AardIntensity');
	GLOVES_MAGICAL_ABILITIES.PushBack('MA_IgniIntensity');
	GLOVES_MAGICAL_ABILITIES.PushBack('MA_QuenIntensity');
	GLOVES_MAGICAL_ABILITIES.PushBack('MA_YrdenIntensity');
	GLOVES_MAGICAL_ABILITIES.PushBack('MA_AxiiIntensity');
	//modSigns: removed GLOVES_MAGICAL_ABILITIES.PushBack('MA_AttackPowerMult');; GLOVES_MAGICAL_ABILITIES.PushBack('MA_CriticalChance');; GLOVES_MAGICAL_ABILITIES.PushBack('
}

@replaceMethod(W3GameParams)
function InitPantsAbilities()
{
	//modSigns: removed PANTS_MASTERWORK_ABILITIES.PushBack('MA_Armor');; PANTS_MASTERWORK_ABILITIES.PushBack('MA_SlashingResistance');; PANTS_MASTERWORK_ABILITIES.PushBack('

	PANTS_MASTERWORK_ABILITIES.PushBack('MA_BurningResistance');
	PANTS_MASTERWORK_ABILITIES.PushBack('MA_PoisonResistance');	//modSigns
	PANTS_MASTERWORK_ABILITIES.PushBack('MA_BleedingResistance');	//modSigns
	PANTS_MASTERWORK_ABILITIES.PushBack('MA_AdrenalineGain');	//modSigns
	PANTS_MASTERWORK_ABILITIES.PushBack('MA_Vitality');	//modSigns
	
	PANTS_MAGICAL_ABILITIES.PushBack('MA_AardIntensity');	//modSigns
	PANTS_MAGICAL_ABILITIES.PushBack('MA_IgniIntensity');	//modSigns
	PANTS_MAGICAL_ABILITIES.PushBack('MA_QuenIntensity');	//modSigns
	PANTS_MAGICAL_ABILITIES.PushBack('MA_YrdenIntensity');	//modSigns
	PANTS_MAGICAL_ABILITIES.PushBack('MA_AxiiIntensity');	//modSigns
}

@replaceMethod(W3GameParams)
function InitBootsAbilities()
{
	//modSigns: removed BOOTS_MASTERWORK_ABILITIES.PushBack('MA_Armor');

	BOOTS_MASTERWORK_ABILITIES.PushBack('MA_BurningResistance');
	BOOTS_MASTERWORK_ABILITIES.PushBack('MA_PoisonResistance');	//modSigns
	BOOTS_MASTERWORK_ABILITIES.PushBack('MA_BleedingResistance');	//modSigns
	BOOTS_MASTERWORK_ABILITIES.PushBack('MA_AdrenalineGain');	//modSigns
	
	BOOTS_MAGICAL_ABILITIES.PushBack('MA_AardIntensity');	//modSigns
	BOOTS_MAGICAL_ABILITIES.PushBack('MA_IgniIntensity');	//modSigns
	BOOTS_MAGICAL_ABILITIES.PushBack('MA_QuenIntensity');	//modSigns
	BOOTS_MAGICAL_ABILITIES.PushBack('MA_YrdenIntensity');	//modSigns
	BOOTS_MAGICAL_ABILITIES.PushBack('MA_AxiiIntensity');	//modSigns
}

@replaceMethod(W3GameParams)
function InitWeaponAbilities()
{

	gmWeaponCommonAbilities.PushBack('MA_ArmorPenetration');	//modSigns
	gmWeaponCommonAbilities.PushBack('MA_ArmorPenetrationPerc');	//modSigns
	gmWeaponCommonAbilities.PushBack('MA_AttackPowerMult');	//modSigns
	gmWeaponCommonAbilities.PushBack('MA_CriticalChance');	//modSigns
	gmWeaponCommonAbilities.PushBack('MA_CriticalDamage');	//modSigns
	gmWeaponCommonAbilities.PushBack('MA_AdrenalineGain');	//modSigns
	
	WEAPON_MASTERWORK_ABILITIES.PushBack('MA_BleedingChance');
	WEAPON_MASTERWORK_ABILITIES.PushBack('MA_FreezingChance');	//modSigns
	WEAPON_MASTERWORK_ABILITIES.PushBack('MA_PoisonChance');	//modSigns
	WEAPON_MASTERWORK_ABILITIES.PushBack('MA_ConfusionChance');	//modSigns
	WEAPON_MASTERWORK_ABILITIES.PushBack('MA_BurningChance');	//modSigns
	WEAPON_MASTERWORK_ABILITIES.PushBack('MA_StaggerChance');	//modSigns
	
	//modSigns: removed WEAPON_MAGICAL_ABILITIES.PushBack('MA_AdrenalineGain');
	WEAPON_MAGICAL_ABILITIES.PushBack('MA_AardIntensity');
	WEAPON_MAGICAL_ABILITIES.PushBack('MA_IgniIntensity');
	WEAPON_MAGICAL_ABILITIES.PushBack('MA_QuenIntensity');
	WEAPON_MAGICAL_ABILITIES.PushBack('MA_YrdenIntensity');
	WEAPON_MAGICAL_ABILITIES.PushBack('MA_AxiiIntensity');
	//modSigns: removed WEAPON_MAGICAL_ABILITIES.PushBack('MA_PoisonChance');
}

@replaceMethod(CInventoryComponent)
function AddRandomEnhancementToItem(item : SItemUniqueId)
{

	var itemCategory 	: name;
	var itemQuality		: int;
	var craftedAbility	: name; 	//modSigns
	var itemLevel		: int;	//modSigns: legacy's argument
	//modSigns: removed var ability : name;; var ent : CGameplayEntity;
	
	SetItemModifierInt(item, 'ItemQualityModified', 1);	//modSigns

	if( ItemHasTag(item, 'DoNotEnhance') )
		return;	//modSigns
	
	if( gmInItemAdded && gmGeneratedLevel > 0 )	//modSigns: legacy's OnItemAdded: the level just generated
		itemLevel = gmGeneratedLevel;	//modSigns
	else	//modSigns
		itemLevel = GetItemLevel(item);	//modSigns: legacy's other callers: the level from the stats
	
	itemQuality = RoundMath(CalculateAttributeValue(GetItemAttributeValue(item, 'quality' )));	//modSigns
	
	if( itemQuality > 4 ) //do not process set items	//modSigns
		return;	//modSigns
	
	GMAddQualityAbilityToItem(item);	//modSigns
	
	itemCategory = GetItemCategory(item);	//modSigns

	if( itemQuality == 4 ) //relic items	//modSigns
	{
		//relic armor gets one common ability
		if ( itemCategory == 'armor' )	//modSigns
			AddItemCraftedAbility(item, theGame.params.GMGetRandomCommonArmorAbility(), true);	//modSigns
		return;
	}
		
	//modSigns: removed itemCategory = GetItemCategory(item);; itemQuality = RoundMath(CalculateAttributeValue(GetItemAttributeValue(item, 'quality' )));
	//add random abilities
	if ( itemCategory == 'armor' )
	{
		//chest armor gets one common ability + 1 master and magic ability per 10 levels
		if( itemQuality >= 1 )	//modSigns
		{
			AddItemCraftedAbility(item, theGame.params.GMGetRandomCommonArmorAbility(), true);	//modSigns
		}	//modSigns
		if( itemQuality >= 2 )	//modSigns
	//modSigns: removed case 2 :; ability = 'quality_masterwork_armor';; AddItemCraftedAbility(item, theGame.params.GetRandomMasterworkArmorAbility(), true);; break;; case 3 
		{
			//same ability multiplied
			craftedAbility = theGame.params.GetRandomMasterworkArmorAbility();	//modSigns
			AddItemCraftedAbility(item, craftedAbility, true);	//modSigns
			if(itemLevel >= 10)	//modSigns
				AddItemCraftedAbility(item, craftedAbility, true);	//modSigns
			if(itemLevel >= 20)	//modSigns
				AddItemCraftedAbility(item, craftedAbility, true);	//modSigns
			if(itemLevel >= 30)	//modSigns
				AddItemCraftedAbility(item, craftedAbility, true);	//modSigns
		}
		if( itemQuality >= 3 )	//modSigns
		{	//modSigns
			//same ability multiplied
			craftedAbility = theGame.params.GetRandomMagicalArmorAbility();	//modSigns
			AddItemCraftedAbility(item, craftedAbility, true);	//modSigns
			if(itemLevel >= 10)	//modSigns
				AddItemCraftedAbility(item, craftedAbility, true);	//modSigns
			if(itemLevel >= 20)	//modSigns
				AddItemCraftedAbility(item, craftedAbility, true);	//modSigns
			if(itemLevel >= 30)	//modSigns
				AddItemCraftedAbility(item, craftedAbility, true);	//modSigns
	//modSigns: removed if ( RandF() > 0.5 ); AddItemCraftedAbility(item, theGame.params.GetRandomMagicalArmorAbility(), true);; else; AddItemCraftedAbility(item, theGame.par
		}
	}
	else if ( itemCategory == 'gloves' )
	{
		//gloves get only one master + magic ability
		if( itemQuality >= 2 )	//modSigns
	//modSigns: removed switch ( itemQuality ); {; case 2 :; ability = 'quality_masterwork_gloves';
			AddItemCraftedAbility(item, theGame.params.GetRandomMasterworkGlovesAbility(), true);
		if( itemQuality >= 3 )	//modSigns
	//modSigns: removed break;; case 3 :; ability = 'quality_magical_gloves';; if ( ItemHasTag(item, 'EP1') ); {; AddItemCraftedAbility(item, theGame.params.GetRandomMagicalA
			AddItemCraftedAbility(item, theGame.params.GetRandomMagicalGlovesAbility(), true);
	//modSigns: removed else; AddItemCraftedAbility(item, theGame.params.GetRandomMasterworkGlovesAbility(), true);; if ( RandF() > 0.5 ); AddItemCraftedAbility(item, theGame
	}
	else if ( itemCategory == 'pants' )
	{
		//pants get only one master + magic ability
		if( itemQuality >= 2 )	//modSigns
	//modSigns: removed switch ( itemQuality ); {; case 2 :; ability = 'quality_masterwork_pants';
			AddItemCraftedAbility(item, theGame.params.GetRandomMasterworkPantsAbility(), true);
		if( itemQuality >= 3 )	//modSigns
	//modSigns: removed break;; case 3 :; ability = 'quality_magical_pants';; if ( ItemHasTag(item, 'EP1') ); {; AddItemCraftedAbility(item, theGame.params.GetRandomMagicalAr
			AddItemCraftedAbility(item, theGame.params.GetRandomMagicalPantsAbility(), true);
	//modSigns: removed else; AddItemCraftedAbility(item, theGame.params.GetRandomMasterworkPantsAbility(), true);; if ( RandF() > 0.5 ); AddItemCraftedAbility(item, theGame.
	}
	else if ( itemCategory == 'boots' )
	{
		//boots get only one master + magic ability
		if( itemQuality >= 2 )	//modSigns
			AddItemCraftedAbility(item, theGame.params.GetRandomMasterworkBootsAbility(), true);	//modSigns
		if( itemQuality >= 3 )	//modSigns
			AddItemCraftedAbility(item, theGame.params.GetRandomMagicalBootsAbility(), true);	//modSigns
	}	//modSigns
	else if ( itemCategory == 'steelsword' || itemCategory == 'silversword' )	//modSigns
	{
		//sword gets one ability per 10 levels
		if( itemQuality >= 1 )	//modSigns
	//modSigns: removed case 2 :; ability = 'quality_masterwork_boots';; AddItemCraftedAbility(item, theGame.params.GetRandomMasterworkBootsAbility(), true);; break;; case 3 
		{
			//same ability multiplied
			craftedAbility = theGame.params.GMGetRandomCommonWeaponAbility();	//modSigns
			AddItemCraftedAbility(item, craftedAbility, true);	//modSigns
			if(itemLevel >= 10)	//modSigns
				AddItemCraftedAbility(item, craftedAbility, true);	//modSigns
			if(itemLevel >= 20)	//modSigns
				AddItemCraftedAbility(item, craftedAbility, true);	//modSigns
			if(itemLevel >= 30)	//modSigns
				AddItemCraftedAbility(item, craftedAbility, true);	//modSigns
		}
		if( itemQuality >= 2 )	//modSigns
		{	//modSigns
			//same ability multiplied
			craftedAbility = theGame.params.GetRandomMasterworkWeaponAbility();	//modSigns
			AddItemCraftedAbility(item, craftedAbility, true);	//modSigns
			if(itemLevel >= 10)	//modSigns
				AddItemCraftedAbility(item, craftedAbility, true);	//modSigns
			if(itemLevel >= 20)	//modSigns
				AddItemCraftedAbility(item, craftedAbility, true);	//modSigns
			if(itemLevel >= 30)	//modSigns
				AddItemCraftedAbility(item, craftedAbility, true);	//modSigns
		}	//modSigns
		if( itemQuality >= 3 )	//modSigns
		{	//modSigns
			//same ability multiplied
			craftedAbility = theGame.params.GetRandomMagicalWeaponAbility();	//modSigns
			AddItemCraftedAbility(item, craftedAbility, true);	//modSigns
			if(itemLevel >= 10)	//modSigns
				AddItemCraftedAbility(item, craftedAbility, true);	//modSigns
			if(itemLevel >= 20)	//modSigns
				AddItemCraftedAbility(item, craftedAbility, true);	//modSigns
			if(itemLevel >= 30)	//modSigns
				AddItemCraftedAbility(item, craftedAbility, true);	//modSigns
		}
	}
	//modSigns: removed else if ( itemCategory == 'steelsword' ); {; switch ( itemQuality ); {; case 2 :; ability = 'quality_masterwork_steelsword';; AddItemCraftedAbility(it
}
	//modSigns: removed if ( RandF() > 0.5 ); AddItemCraftedAbility(item, theGame.params.GetRandomMagicalWeaponAbility(), true);; else; AddItemCraftedAbility(item, theGame.pa

// ITEM-06: the quality ability of an item of quality 1 to 4 (legacy's).
@addMethod(CInventoryComponent)
function GMAddQualityAbilityToItem(item : SItemUniqueId)
{
	var ability			: name;
	var itemCategory 	: name;
	var itemQuality		: int;
	
	itemQuality = RoundMath(CalculateAttributeValue(GetItemAttributeValue(item, 'quality' )));
	itemCategory = GetItemCategory(item);
	
	if ( itemCategory == 'armor' )
	{
		switch ( itemQuality )
		{
			case 1:
				ability = 'quality_common_armor';
				break;
			case 2 : 
				ability = 'quality_masterwork_armor'; 			
				break;
			case 3 : 
				ability = 'quality_magical_armor'; 	
				break;
			case 4:
				ability = 'quality_relic_armor';
				break;
			default : break;
		}
	}
	else if ( itemCategory == 'gloves' )
	{
		switch ( itemQuality )
		{
			case 1:
				ability = 'quality_common_gloves';
				break;
			case 2 : 
				ability = 'quality_masterwork_gloves'; 		
				break;
			case 3 : 
				ability = 'quality_magical_gloves'; 	
				break;
			case 4:
				ability = 'quality_relic_gloves';
				break;
			default : break;
		}
	}
	else if ( itemCategory == 'pants' )
	{
		switch ( itemQuality )
		{
			case 1:
				ability = 'quality_common_pants';
				break;
			case 2 : 
				ability = 'quality_masterwork_pants'; 			
				break;
			case 3 : 
				ability = 'quality_magical_pants'; 	
				break;
			case 4:
				ability = 'quality_relic_pants';
				break;
			default : break;
		}
	}
	else if ( itemCategory == 'boots' )
	{
		switch ( itemQuality )
		{
			case 1 : 
				ability = 'quality_common_boots'; 			
				break;
			case 2 : 
				ability = 'quality_masterwork_boots'; 			
				break;
			case 3 : 
				ability = 'quality_magical_boots'; 		
				break;
			case 4 : 
				ability = 'quality_relic_boots'; 			
				break;
			default : break;
		}
	}
	else if( itemCategory == 'steelsword' )
	{
		switch ( itemQuality )
		{
			case 1 : 
				ability = 'quality_common_steelsword'; 	
				break;
			case 2 : 
				ability = 'quality_masterwork_steelsword'; 	
				break;
			case 3 : 
				ability = 'quality_magical_steelsword'; 	
				break;
			case 4 : 
				ability = 'quality_relic_steelsword'; 	
				break;
			default : break;
		}
	}
	else if( itemCategory == 'silversword' )
	{
		switch ( itemQuality )
		{
			case 1 : 
				ability = 'quality_common_silversword';	
				break;
			case 2 : 
				ability = 'quality_masterwork_silversword';	
				break;
			case 3 : 
				ability = 'quality_magical_silversword'; 	
				break;
			case 4 : 
				ability = 'quality_relic_silversword';	
				break;
			default : break;
		}
	}
		
	if(IsNameValid(ability))
		AddItemCraftedAbility(item, ability, false);
}

// ITEM-06: an item's quality read from its definition is at least 1 (legacy; items without a quality
// count as common, so they get the common bonus).
@replaceMethod(CInventoryComponent)
function GetItemQualityFromName( itemName : name, out min : int, out max : int)
{
	var dm : CDefinitionsManagerAccessor;
	var attributeName : name;
	var attributes, itemAbilities : array<name>;
	var attributeMin, attributeMax : SAbilityAttributeValue;

	var tmpInt : int;
	var tmpArray : array<float>;

	dm = theGame.GetDefinitionsManager();
	min = 0;	//modSigns
	max = 0;	//modSigns

	dm.GetItemAbilitiesWithWeights(itemName, GetEntity() == thePlayer, itemAbilities, tmpArray, tmpInt, tmpInt);
	attributes = dm.GetAbilitiesAttributes(itemAbilities);
	for (tmpInt = 0; tmpInt < attributes.Size(); tmpInt += 1)
	{
		if (attributes[tmpInt] == 'quality')
		{
			dm.GetAbilitiesAttributeValue(itemAbilities, 'quality', attributeMin, attributeMax);
			min = RoundMath(CalculateAttributeValue(attributeMin));
			max = RoundMath(CalculateAttributeValue(attributeMax));
			break;
		}
	}
	min = Max(1, min);	//modSigns
	max = Max(min, max);	//modSigns
}
