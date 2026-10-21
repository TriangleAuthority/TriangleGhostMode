// ALCH-18: legacy's alchemy debug console commands (legacy's names, console_debug.ws): addalchemy1/2/3 give
// every potion, oil and bomb of a tier with full charges, adddecoctions every decoction. Legacy's
// toggledebugoils (a log of the oils' bonuses) is not ported: SKL-14's tests read the same values.
// See docs/features/alch.md.

// One item with its charges full.
function GMDebugAddAlchemyItem(itemName : name)
{
	var arr : array<SItemUniqueId>;

	arr = thePlayer.inv.AddAnItem(itemName, 1);
	if(arr.Size() > 0 && thePlayer.inv.IsItemSingletonItem(arr[0]))
		thePlayer.inv.SingletonItemSetAmmo(arr[0], thePlayer.inv.SingletonItemGetMaxAmmo(arr[0]));
}

exec function addalchemy1()
{
	GMDebugAddAlchemyItem('Black Blood 1');
	GMDebugAddAlchemyItem('Blizzard 1');
	GMDebugAddAlchemyItem('Cat 1');
	GMDebugAddAlchemyItem('Full Moon 1');
	GMDebugAddAlchemyItem('Golden Oriole 1');
	GMDebugAddAlchemyItem('Killer Whale 1');
	GMDebugAddAlchemyItem('Maribor Forest 1');
	GMDebugAddAlchemyItem('Petri Philtre 1');
	GMDebugAddAlchemyItem('Swallow 1');
	GMDebugAddAlchemyItem('Tawny Owl 1');
	GMDebugAddAlchemyItem('Thunderbolt 1');
	GMDebugAddAlchemyItem('White Honey 1');
	GMDebugAddAlchemyItem('White Raffards Decoction 1');
	GMDebugAddAlchemyItem('Beast Oil 1');
	GMDebugAddAlchemyItem('Cursed Oil 1');
	GMDebugAddAlchemyItem('Hanged Man Venom 1');
	GMDebugAddAlchemyItem('Hybrid Oil 1');
	GMDebugAddAlchemyItem('Insectoid Oil 1');
	GMDebugAddAlchemyItem('Magicals Oil 1');
	GMDebugAddAlchemyItem('Necrophage Oil 1');
	GMDebugAddAlchemyItem('Specter Oil 1');
	GMDebugAddAlchemyItem('Vampire Oil 1');
	GMDebugAddAlchemyItem('Draconide Oil 1');
	GMDebugAddAlchemyItem('Ogre Oil 1');
	GMDebugAddAlchemyItem('Relic Oil 1');
	GMDebugAddAlchemyItem('Samum 1');
	GMDebugAddAlchemyItem('Dwimeritium Bomb 1');
	GMDebugAddAlchemyItem('Dancing Star 1');
	GMDebugAddAlchemyItem('Devils Puffball 1');
	GMDebugAddAlchemyItem('Dragons Dream 1');
	GMDebugAddAlchemyItem('Silver Dust Bomb 1');
	GMDebugAddAlchemyItem('White Frost 1');
	GMDebugAddAlchemyItem('Grapeshot 1');
}

exec function addalchemy2()
{
	GMDebugAddAlchemyItem('Black Blood 2');
	GMDebugAddAlchemyItem('Blizzard 2');
	GMDebugAddAlchemyItem('Cat 2');
	GMDebugAddAlchemyItem('Full Moon 2');
	GMDebugAddAlchemyItem('Golden Oriole 2');
	GMDebugAddAlchemyItem('Maribor Forest 2');
	GMDebugAddAlchemyItem('Petri Philtre 2');
	GMDebugAddAlchemyItem('Swallow 2');
	GMDebugAddAlchemyItem('Tawny Owl 2');
	GMDebugAddAlchemyItem('Thunderbolt 2');
	GMDebugAddAlchemyItem('White Honey 2');
	GMDebugAddAlchemyItem('White Raffards Decoction 2');
	GMDebugAddAlchemyItem('Beast Oil 2');
	GMDebugAddAlchemyItem('Cursed Oil 2');
	GMDebugAddAlchemyItem('Hanged Man Venom 2');
	GMDebugAddAlchemyItem('Hybrid Oil 2');
	GMDebugAddAlchemyItem('Insectoid Oil 2');
	GMDebugAddAlchemyItem('Magicals Oil 2');
	GMDebugAddAlchemyItem('Necrophage Oil 2');
	GMDebugAddAlchemyItem('Specter Oil 2');
	GMDebugAddAlchemyItem('Vampire Oil 2');
	GMDebugAddAlchemyItem('Draconide Oil 2');
	GMDebugAddAlchemyItem('Ogre Oil 2');
	GMDebugAddAlchemyItem('Relic Oil 2');
	GMDebugAddAlchemyItem('Samum 2');
	GMDebugAddAlchemyItem('Dwimeritium Bomb 2');
	GMDebugAddAlchemyItem('Dancing Star 2');
	GMDebugAddAlchemyItem('Devils Puffball 2');
	GMDebugAddAlchemyItem('Dragons Dream 2');
	GMDebugAddAlchemyItem('Silver Dust Bomb 2');
	GMDebugAddAlchemyItem('White Frost 2');
	GMDebugAddAlchemyItem('Grapeshot 2');
}

exec function addalchemy3()
{
	GMDebugAddAlchemyItem('Black Blood 3');
	GMDebugAddAlchemyItem('Blizzard 3');
	GMDebugAddAlchemyItem('Cat 3');
	GMDebugAddAlchemyItem('Full Moon 3');
	GMDebugAddAlchemyItem('Golden Oriole 3');
	GMDebugAddAlchemyItem('Maribor Forest 3');
	GMDebugAddAlchemyItem('Petri Philtre 3');
	GMDebugAddAlchemyItem('Swallow 3');
	GMDebugAddAlchemyItem('Tawny Owl 3');
	GMDebugAddAlchemyItem('Thunderbolt 3');
	GMDebugAddAlchemyItem('White Honey 3');
	GMDebugAddAlchemyItem('White Raffards Decoction 3');
	GMDebugAddAlchemyItem('Beast Oil 3');
	GMDebugAddAlchemyItem('Cursed Oil 3');
	GMDebugAddAlchemyItem('Hanged Man Venom 3');
	GMDebugAddAlchemyItem('Hybrid Oil 3');
	GMDebugAddAlchemyItem('Insectoid Oil 3');
	GMDebugAddAlchemyItem('Magicals Oil 3');
	GMDebugAddAlchemyItem('Necrophage Oil 3');
	GMDebugAddAlchemyItem('Specter Oil 3');
	GMDebugAddAlchemyItem('Vampire Oil 3');
	GMDebugAddAlchemyItem('Draconide Oil 3');
	GMDebugAddAlchemyItem('Ogre Oil 3');
	GMDebugAddAlchemyItem('Relic Oil 3');
	GMDebugAddAlchemyItem('Samum 3');
	GMDebugAddAlchemyItem('Dwimeritium Bomb 3');
	GMDebugAddAlchemyItem('Dancing Star 3');
	GMDebugAddAlchemyItem('Devils Puffball 3');
	GMDebugAddAlchemyItem('Dragons Dream 3');
	GMDebugAddAlchemyItem('Silver Dust Bomb 3');
	GMDebugAddAlchemyItem('White Frost 3');
	GMDebugAddAlchemyItem('Grapeshot 3');
}

exec function adddecoctions()
{
	GMDebugAddAlchemyItem('Mutagen 1');
	GMDebugAddAlchemyItem('Mutagen 2');
	GMDebugAddAlchemyItem('Mutagen 3');
	GMDebugAddAlchemyItem('Mutagen 4');
	GMDebugAddAlchemyItem('Mutagen 5');
	GMDebugAddAlchemyItem('Mutagen 6');
	GMDebugAddAlchemyItem('Mutagen 7');
	GMDebugAddAlchemyItem('Mutagen 8');
	GMDebugAddAlchemyItem('Mutagen 9');
	GMDebugAddAlchemyItem('Mutagen 10');
	GMDebugAddAlchemyItem('Mutagen 11');
	GMDebugAddAlchemyItem('Mutagen 12');
	GMDebugAddAlchemyItem('Mutagen 13');
	GMDebugAddAlchemyItem('Mutagen 14');
	GMDebugAddAlchemyItem('Mutagen 15');
	GMDebugAddAlchemyItem('Mutagen 16');
	GMDebugAddAlchemyItem('Mutagen 17');
	GMDebugAddAlchemyItem('Mutagen 18');
	GMDebugAddAlchemyItem('Mutagen 19');
	GMDebugAddAlchemyItem('Mutagen 20');
	GMDebugAddAlchemyItem('Mutagen 21');
	GMDebugAddAlchemyItem('Mutagen 22');
	GMDebugAddAlchemyItem('Mutagen 23');
	GMDebugAddAlchemyItem('Mutagen 24');
	GMDebugAddAlchemyItem('Mutagen 25');
	GMDebugAddAlchemyItem('Mutagen 26');
	GMDebugAddAlchemyItem('Mutagen 27');
	GMDebugAddAlchemyItem('Mutagen 28');
}
