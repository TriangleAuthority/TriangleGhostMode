// ITEM-04: items legacy moved to level scaling (the Autogen tags and the fixed values removed are data,
// tools/item_layer.py). Starting New Game+ keeps Iris (level-scaled) instead of swapping it for
// NGP Olgierd Sabre, as legacy. See docs/features/item.md.

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
