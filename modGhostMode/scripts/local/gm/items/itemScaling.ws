// ITEM-04: items legacy moved to level scaling (the Autogen tags and the fixed values removed are data,
// tools/item_layer.py). Starting New Game+ keeps Iris (level-scaled) instead of swapping it for
// NGP Olgierd Sabre, and Blood and Wine's vampire gear for its NG+ copies, as legacy. See docs/features/item.md.

@replaceMethod(W3PlayerWitcher)
function NewGamePlusReplaceEP1(out inv : CInventoryComponent)
{
	NewGamePlusReplaceItem('Ofir Armor', 'NGP Ofir Armor', inv);
	NewGamePlusReplaceItem('Ofir Sabre 2', 'NGP Ofir Sabre 2', inv);

	NewGamePlusReplaceItem('Crafted Burning Rose Armor', 'NGP Crafted Burning Rose Armor', inv);
	NewGamePlusReplaceItem('Crafted Burning Rose Gloves', 'NGP Crafted Burning Rose Gloves', inv);
	NewGamePlusReplaceItem('Crafted Burning Rose Sword', 'NGP Crafted Burning Rose Sword', inv);

	NewGamePlusReplaceItem('Crafted Ofir Armor', 'NGP Crafted Ofir Armor', inv);
	NewGamePlusReplaceItem('Crafted Ofir Boots', 'NGP Crafted Ofir Boots', inv);
	NewGamePlusReplaceItem('Crafted Ofir Gloves', 'NGP Crafted Ofir Gloves', inv);
	NewGamePlusReplaceItem('Crafted Ofir Pants', 'NGP Crafted Ofir Pants', inv);
	NewGamePlusReplaceItem('Crafted Ofir Steel Sword', 'NGP Crafted Ofir Steel Sword', inv);

	NewGamePlusReplaceItem('EP1 Crafted Witcher Silver Sword', 'NGP EP1 Crafted Witcher Silver Sword', inv);
	//modSigns: removed the swap of Iris for NGP Olgierd Sabre (Iris is level-scaled, ITEM-04)

	NewGamePlusReplaceItem('EP1 Witcher Armor', 'NGP EP1 Witcher Armor', inv);
	NewGamePlusReplaceItem('EP1 Witcher Boots', 'NGP EP1 Witcher Boots', inv);
	NewGamePlusReplaceItem('EP1 Witcher Gloves', 'NGP EP1 Witcher Gloves', inv);
	NewGamePlusReplaceItem('EP1 Witcher Pants', 'NGP EP1 Witcher Pants', inv);
	NewGamePlusReplaceItem('EP1 Viper School steel sword', 'NGP EP1 Viper School steel sword', inv);
	NewGamePlusReplaceItem('EP1 Viper School silver sword', 'NGP EP1 Viper School silver sword', inv);
}


// ITEM-04: starting New Game+ keeps Blood and Wine's vampire armor, gloves, pants, boots and steel sword
// (level-scaled) instead of swapping them for their NG+ copies, as legacy (CRAFT/LOOT audit F5).
@replaceMethod(W3PlayerWitcher)
function NewGamePlusReplaceEP2Items(out inv : CInventoryComponent)
{
	NewGamePlusReplaceItem('Guard Lvl1 Armor 3', 'NGP Guard Lvl1 Armor 3', inv);
	NewGamePlusReplaceItem('Guard Lvl1 A Armor 3', 'NGP Guard Lvl1 A Armor 3', inv);
	NewGamePlusReplaceItem('Guard Lvl2 Armor 3', 'NGP Guard Lvl2 Armor 3', inv);
	NewGamePlusReplaceItem('Guard Lvl2 A Armor 3', 'NGP Guard Lvl2 A Armor 3', inv);
	NewGamePlusReplaceItem('Knight Geralt Armor 3', 'NGP Knight Geralt Armor 3', inv);
	NewGamePlusReplaceItem('Knight Geralt A Armor 3', 'NGP Knight Geralt A Armor 3', inv);
	//modSigns: removed the swap of q702_vampire_armor for its NG+ copy (level-scaled, ITEM-04)

	NewGamePlusReplaceItem('Guard Lvl1 Gloves 3', 'NGP Guard Lvl1 Gloves 3', inv);
	NewGamePlusReplaceItem('Guard Lvl1 A Gloves 3', 'NGP Guard Lvl1 A Gloves 3', inv);
	NewGamePlusReplaceItem('Guard Lvl2 Gloves 3', 'NGP Guard Lvl2 Gloves 3', inv);
	NewGamePlusReplaceItem('Guard Lvl2 A Gloves 3', 'NGP Guard Lvl2 A Gloves 3', inv);
	NewGamePlusReplaceItem('Knight Geralt Gloves 3', 'NGP Knight Geralt Gloves 3', inv);
	NewGamePlusReplaceItem('Knight Geralt A Gloves 3', 'NGP Knight Geralt A Gloves 3', inv);
	//modSigns: removed the swap of q702_vampire_gloves for its NG+ copy (level-scaled, ITEM-04)

	NewGamePlusReplaceItem('Guard Lvl1 Pants 3', 'NGP Guard Lvl1 Pants 3', inv);
	NewGamePlusReplaceItem('Guard Lvl1 A Pants 3', 'NGP Guard Lvl1 A Pants 3', inv);
	NewGamePlusReplaceItem('Guard Lvl2 Pants 3', 'NGP Guard Lvl2 Pants 3', inv);
	NewGamePlusReplaceItem('Guard Lvl2 A Pants 3', 'NGP Guard Lvl2 A Pants 3', inv);
	NewGamePlusReplaceItem('Knight Geralt Pants 3', 'NGP Knight Geralt Pants 3', inv);
	NewGamePlusReplaceItem('Knight Geralt A Pants 3', 'NGP Knight Geralt A Pants 3', inv);
	//modSigns: removed the swap of q702_vampire_pants for its NG+ copy (level-scaled, ITEM-04)

	NewGamePlusReplaceItem('Guard Lvl1 Boots 3', 'NGP Guard Lvl1 Boots 3', inv);
	NewGamePlusReplaceItem('Guard Lvl1 A Boots 3', 'NGP Guard Lvl1 A Boots 3', inv);
	NewGamePlusReplaceItem('Guard Lvl2 Boots 3', 'NGP Guard Lvl2 Boots 3', inv);
	NewGamePlusReplaceItem('Guard Lvl2 A Boots 3', 'NGP Guard Lvl2 A Boots 3', inv);
	NewGamePlusReplaceItem('Knight Geralt Boots 3', 'NGP Knight Geralt Boots 3', inv);
	NewGamePlusReplaceItem('Knight Geralt A Boots 3', 'NGP Knight Geralt A Boots 3', inv);
	//modSigns: removed the swap of q702_vampire_boots for its NG+ copy (level-scaled, ITEM-04)

	NewGamePlusReplaceItem('Serpent Steel Sword 1', 'NGP Serpent Steel Sword 1', inv);
	NewGamePlusReplaceItem('Serpent Steel Sword 2', 'NGP Serpent Steel Sword 2', inv);
	NewGamePlusReplaceItem('Serpent Steel Sword 3', 'NGP Serpent Steel Sword 3', inv);
	NewGamePlusReplaceItem('Guard lvl1 steel sword 3', 'NGP Guard lvl1 steel sword 3', inv);
	NewGamePlusReplaceItem('Guard lvl2 steel sword 3', 'NGP Guard lvl2 steel sword 3', inv);
	NewGamePlusReplaceItem('Knights steel sword 3', 'NGP Knights steel sword 3', inv);
	NewGamePlusReplaceItem('Hanza steel sword 3', 'NGP Hanza steel sword 3', inv);
	NewGamePlusReplaceItem('Toussaint steel sword 3', 'NGP Toussaint steel sword 3', inv);
	//modSigns: removed the swap of q702 vampire steel sword for its NG+ copy (level-scaled, ITEM-04)

	NewGamePlusReplaceItem('Serpent Silver Sword 1', 'NGP Serpent Silver Sword 1', inv);
	NewGamePlusReplaceItem('Serpent Silver Sword 2', 'NGP Serpent Silver Sword 2', inv);
	NewGamePlusReplaceItem('Serpent Silver Sword 3', 'NGP Serpent Silver Sword 3', inv);
}
