// TRPH-04: trophies are no longer equipped on Roach by themselves (legacy; docs/features/trph.md). A trophy taken
// from a monster's remains stays in Geralt's inventory (also with 5.x's "Auto-loot" option, which loots through the
// same functions), and a contract's trophy too, without Roach being brought next to Geralt. The player straps a
// trophy to the saddle himself, in the inventory's horse slots.

// 5.x body; changes marked //modSigns.
@replaceMethod(W3ActorRemains)
function OnItemTaken(itemId : SItemUniqueId, quantity : int)
{
	var itemName : name;
	
	super.OnItemTaken(itemId, quantity);
	
	//modSigns: removed the trophy's name queued for FinalizeLooting's equip (TRPH-04)
	if(!HasQuestItem())
		StopEffect('quest_highlight_fx');
}

// 5.x body; changes marked //modSigns.
@replaceMethod(W3ActorRemains)
function FinalizeLooting ()
{
	var commonMapManager : CCommonMapManager;
	
	//modSigns: removed the queued trophies moved to Roach and equipped (TRPH-04), and their locals
	
	if(IsEmpty())
	{
		commonMapManager = theGame.GetCommonMapManager();
		commonMapManager.DeleteQuestLootContainer( this );
		UnhighlightEntity();
		Enable(false);
		Destroy();
	}
}

// A contract's trophy, which the quest hands over after the trophy scene: left in the inventory (TRPH-04).
// 5.x's latent quest function, replaced without `latent` (development.md).
@replaceMethod
function ProcessMonsterHuntTrophyQuest( trophyName : name, dontTeleportHorse : bool)
{
	//modSigns: removed Roach's teleport next to Geralt, the trophy's equip on her and the half-second wait (TRPH-04)
}
