// Ghost Mode: Yoana's master stock (CRAFT-10 with LOOT-04, legacy, changelist 611, 633). Once Geralt has
// helped her (fact sq108_master_bsmith_helped), Yoana's shop also stocks the list
// _store__Master_Armorsmith_Yoana: the master armorsmith tools and her master schematics (the four
// craftable quest armors' among them, CRAFT-04). The other master kits are in the shop lists of Hattori,
// the Hearts of Stone enchanter and Blood and Wine's archmaster (the whole-file loot overrides, LOOT-04).
// See docs/features/craft.md and loot.md.

// Legacy's CInventoryComponent.AddMasterArmorerItems.
@addMethod(CInventoryComponent)
function GMAddMasterArmorerItems()
{
	if(FactsDoesExist("sq108_master_bsmith_helped"))
	{
		AddItemsFromLootDefinition('_store__Master_Armorsmith_Yoana');
	}
}

// Legacy called it in the storyscene function ShowMeGoods for the merchant tagged sq108_blacksmith_woman,
// right before the shop's AutoBalanaceItemsWithPlayerLevel; ShowMeGoods (a latent storyscene function)
// stays 5.x's and this wrapper adds the call for Yoana's inventory. The only other caller, a container's
// OnInteraction, never runs on Yoana.
@wrapMethod(CInventoryComponent)
function AutoBalanaceItemsWithPlayerLevel()
{
	var owner : CEntity;

	owner = GetEntity();
	if(owner && owner.HasTag('sq108_blacksmith_woman'))
	{
		GMAddMasterArmorerItems();
	}
	wrappedMethod();
}
