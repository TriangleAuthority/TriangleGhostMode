// WGT slice W1's probe (docs/features/wgt.md): how the native GetItemWeight combines an item's own `weight`
// attribute with the `<weight>` nodes of its abilities, read on spawned items, in Geralt's inventory and in the
// horse manager's (a non-player inventory a data test can use without Geralt's OnItemAdded side effects).
// Test only: logs what it reads (channel GMTest, lines "WGTPROBE").

function GMTestWgtProbeAbl(dm : CDefinitionsManagerAccessor, abl : name) : string
{
	var mn, mx : SAbilityAttributeValue;

	dm.GetAbilityAttributeValue(abl, 'weight', mn, mx);
	return NameToString(abl) + "{b " + mn.valueBase + " m " + mn.valueMultiplicative + " a " + mn.valueAdditive + "}";
}

function GMTestWgtProbeItem(inv : CInventoryComponent, item : name, qty : int, where : string)
{
	var ids : array<SItemUniqueId>;
	var abls : array<name>;
	var dm : CDefinitionsManagerAccessor;
	var a, mn, mx : SAbilityAttributeValue;
	var s : string;
	var i : int;

	dm = theGame.GetDefinitionsManager();
	ids = inv.AddAnItem(item, qty, true, true);
	if(ids.Size() == 0)
	{
		LogChannel('GMTest', "WGTPROBE " + where + " " + item + ": not added");
		return;
	}
	a = inv.GetItemAttributeValue(ids[0], 'weight');
	dm.GetItemAttributeValueNoRandom(item, true, 'weight', mn, mx);
	inv.GetItemAbilities(ids[0], abls);
	s = "";
	for(i = 0; i < abls.Size(); i += 1)
		s += " " + GMTestWgtProbeAbl(dm, abls[i]);
	LogChannel('GMTest', "WGTPROBE " + where + " " + item + " x" + inv.GetItemQuantity(ids[0]) + " ids " + ids.Size()
		+ ": GetItemWeight " + inv.GetItemWeight(ids[0]) + ", GetItemEncumbrance " + inv.GetItemEncumbrance(ids[0])
		+ ", counts " + inv.IsItemEncumbranceItem(ids[0]) + ", category " + inv.GetItemCategory(ids[0])
		+ ", attr weight b " + a.valueBase + " m " + a.valueMultiplicative + " a " + a.valueAdditive
		+ ", definition (abilities) b " + mn.valueBase + " m " + mn.valueMultiplicative + " a " + mn.valueAdditive
		+ "; abilities:" + s);
	for(i = 0; i < ids.Size(); i += 1)
		inv.RemoveItem(ids[i], inv.GetItemQuantity(ids[i]));
}

// The samples: only an item weight (an ingredient, a key, a rune), only ability weights (a sword, an armor
// piece), both (Blood and Wine's Toussaint crossbow, the Fire Horse saddlebags), a potion whose ability weighs 0,
// a stack, the coins, and an NPC weapon with a `mult` weight node.
exec function gmtest_wgt_probe()
{
	var inv, hinv : CInventoryComponent;
	var names : array<name>;
	var i : int;
	var hb : bool;

	inv = thePlayer.GetInventory();
	hinv = GetWitcherPlayer().GetHorseManager().GetInventoryComponent();
	names.PushBack('Drowner brain');
	names.PushBack('q103_tamara_shrine_key');
	names.PushBack('Rune svarog');
	names.PushBack('Long Steel Sword');
	names.PushBack('Bear Armor');
	names.PushBack('Toussaint Crossbow 1');
	names.PushBack('Fire Horse Saddlebags');
	names.PushBack('Swallow 1');
	names.PushBack('Florens');
	names.PushBack('Spear 1');
	for(i = 0; i < names.Size(); i += 1)
	{
		GMTestWgtProbeItem(inv, names[i], 1, "geralt");
		GMTestWgtProbeItem(hinv, names[i], 1, "horse");
	}
	GMTestWgtProbeItem(inv, 'Drowner brain', 10, "geralt");
	GMTestWgtProbeItem(hinv, 'Drowner brain', 10, "horse");
	LogChannel('GMTest', "WGTPROBE done; Geralt's encumbrance " + GetWitcherPlayer().GetEncumbrance()
		+ " of " + GetWitcherPlayer().GetMaxRunEncumbrance(hb));
}
