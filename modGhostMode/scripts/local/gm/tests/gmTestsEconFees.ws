// ECON-07 (ECON audit F4): the fees the slice E1 check left out, measured here first.
// gmtest_econ_fees_probe() spawns the Hearts of Stone enchanter and a Beauclair blacksmith, logs their tags and,
// for a few items, the list price, the repair fee at several durabilities and the socket price with 0 and 1
// sockets already added.

function GMTestEconFeesItems() : array<name>
{
	var items : array<name>;

	items.PushBack('Long Steel Sword');
	items.PushBack('Bear Armor 1');
	items.PushBack('Heavy armor 01');
	items.PushBack('Viper School steel sword');
	return items;
}

function GMTestEconFeesSpawn(path : string, dist : float) : CNewNPC
{
	var template : CEntityTemplate;

	template = (CEntityTemplate)LoadResource(path, true);
	return (CNewNPC)theGame.CreateEntity(template, thePlayer.GetWorldPosition() - thePlayer.GetHeadingVector() * dist, thePlayer.GetWorldRotation());
}

function GMTestEconFeesProbeOne(npc : CNewNPC, label : string)
{
	var minv, pinv : CInventoryComponent;
	var pids : array<SItemUniqueId>;
	var items : array<name>;
	var i, rp, rt, s0, s1, s2 : int;
	var maxd : float;
	var s : string;

	minv = npc.GetInventory();
	pinv = thePlayer.GetInventory();
	LogChannel('GMTest', "INFO ECON fees " + label + " tags:" + GMTestEconNpcTags(npc));
	items = GMTestEconFeesItems();
	for(i = 0; i < items.Size(); i += 1)
	{
		pids = pinv.AddAnItem(items[i], 1, true, true, false);
		if(pids.Size() == 0)
			continue;
		maxd = pinv.GetItemMaxDurability(pids[0]);
		s = items[i] + " list " + pinv.GetItemPrice(pids[0]) + " maxdur " + maxd + " slots " + pinv.GetItemEnhancementSlotsCount(pids[0]);
		pinv.SetItemDurabilityScript(pids[0], maxd * 0.5);
		minv.GetItemPriceRepair(pinv.GetItem(pids[0]), rp, rt);
		s += " | repair at " + pinv.GetItemDurability(pids[0]) + ": " + rt + "/" + rp;
		pinv.SetItemDurabilityScript(pids[0], maxd * 0.1);
		minv.GetItemPriceRepair(pinv.GetItem(pids[0]), rp, rt);
		s += ", at " + pinv.GetItemDurability(pids[0]) + ": " + rt + "/" + rp;
		pinv.SetItemDurabilityScript(pids[0], maxd - 1);
		minv.GetItemPriceRepair(pinv.GetItem(pids[0]), rp, rt);
		s += ", at " + pinv.GetItemDurability(pids[0]) + ": " + rt + "/" + rp;
		pinv.SetItemDurabilityScript(pids[0], maxd);
		s0 = minv.GetItemPriceAddSlot(pinv.GetItem(pids[0]));
		pinv.AddSlot(pids[0]);
		s1 = minv.GetItemPriceAddSlot(pinv.GetItem(pids[0]));
		pinv.AddSlot(pids[0]);
		s2 = minv.GetItemPriceAddSlot(pinv.GetItem(pids[0]));
		s += " | socket " + s0 + ", " + s1 + ", " + s2 + " (slots now " + pinv.GetItemEnhancementSlotsCount(pids[0]) + ")";
		LogChannel('GMTest', "INFO ECON fees " + label + " " + s);
		pinv.RemoveItem(pids[0], 1);
	}
}

exec function gmtest_econ_fees_probe()
{
	var npc : CNewNPC;

	npc = GMTestEconFeesSpawn("dlc\ep1\data\gameplay\community\shops_and_craftsmen\enchanter\enchanter_01_lvl_1.w2ent", 6);
	if(npc)
	{
		GMTestEconFeesProbeOne(npc, "enchanter");
		npc.Destroy();
	}
	else
		LogChannel('GMTest', "INFO ECON fees: no enchanter");
	npc = GMTestEconFeesSpawn("dlc\bob\data\characters\npc_entities\crowd_npc\bob_craftsman\bob_blacksmith.w2ent", 7);
	if(npc)
	{
		GMTestEconFeesProbeOne(npc, "Beauclair blacksmith");
		npc.Destroy();
	}
	else
		LogChannel('GMTest', "INFO ECON fees: no Beauclair blacksmith");
	npc = GMTestEconFeesSpawn("living_world\dialogue\generic_merchants\entities\shop_generic_merchant_novigrad_weapons.w2ent", 8);
	if(npc)
	{
		GMTestEconFeesProbeOne(npc, "Novigrad blacksmith");
		npc.Destroy();
	}
}

// The price columns a spawned NPC's inventory carries (the shop menus read them with invComponent.HasTag).
function GMTestEconInvColumns(inv : CInventoryComponent) : string
{
	var cols : array<name>;
	var i : int;
	var s : string;

	cols.PushBack('type_general'); cols.PushBack('type_alchemist'); cols.PushBack('type_armorer'); cols.PushBack('type_barber');
	cols.PushBack('type_blacksmith'); cols.PushBack('type_book'); cols.PushBack('type_collector'); cols.PushBack('type_dye');
	cols.PushBack('type_enchanter'); cols.PushBack('type_herbalist'); cols.PushBack('type_inn'); cols.PushBack('area_beauclair');
	cols.PushBack('area_nml'); cols.PushBack('area_nonhuman'); cols.PushBack('area_skellige'); cols.PushBack('area_novigrad');
	cols.PushBack('area_nilfgaard'); cols.PushBack('area_nml_bonus'); cols.PushBack('area_skellige_bonus'); cols.PushBack('area_novigrad_bonus');
	cols.PushBack('quest_bonus'); cols.PushBack('bonus_mq7018_1'); cols.PushBack('bonus_mq7018_2');
	for(i = 0; i < cols.Size(); i += 1)
		if(inv.HasTag(cols[i]))
			s += " " + cols[i];
	return s;
}

function GMTestEconTagsOne(path : string)
{
	var npc : CNewNPC;

	npc = GMTestEconFeesSpawn(path, 6);
	if(!npc)
	{
		LogChannel('GMTest', "INFO ECON tags " + path + ": not spawned");
		return;
	}
	LogChannel('GMTest', "INFO ECON tags " + path + ": entity" + GMTestEconNpcTags(npc) + " | inventory" + GMTestEconInvColumns(npc.GetInventory())
		+ " | funds modifier " + npc.GetInventory().GetFundsModifier() + " | merchant " + ((W3MerchantNPC)npc));
	npc.Destroy();
}

exec function gmtest_econ_tags_probe()
{
	GMTestEconTagsOne("dlc\ep1\data\gameplay\community\shops_and_craftsmen\enchanter\enchanter_01_lvl_1.w2ent");
	GMTestEconTagsOne("dlc\bob\data\gameplay\community\community_npcs\craftsmen\blacksmith.w2ent");
	GMTestEconTagsOne("dlc\bob\data\gameplay\community\community_npcs\craftsmen\barber.w2ent");
	GMTestEconTagsOne("dlc\bob\data\gameplay\community\community_npcs\craftsmen\innkeeper.w2ent");
	GMTestEconTagsOne("dlc\bob\data\characters\npc_entities\crowd_npc\bob_craftsman\bob_blacksmith.w2ent");
	GMTestEconTagsOne("dlc\bob\data\characters\npc_entities\crowd_npc\bob_craftsman\bob_merchant.w2ent");
	GMTestEconTagsOne("dlc\bob\data\characters\npc_entities\crowd_npc\bob_craftsman\bob_merchant_rich.w2ent");
	GMTestEconTagsOne("dlc\bob\data\characters\npc_entities\crowd_npc\bob_craftsman\bob_herbalist.w2ent");
	GMTestEconTagsOne("dlc\bob\data\characters\npc_entities\crowd_npc\bob_craftsman\community\bob_merchant_community.w2ent");
	GMTestEconTagsOne("living_world\dialogue\generic_merchants\entities\shop_generic_merchant_novigrad_weapons.w2ent");
}
