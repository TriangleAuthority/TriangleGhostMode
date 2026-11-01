// XP-06: monster nests and dialogue choices (docs/features/xp.md; legacy's monsterNestEntity.ws and choiceActions.ws,
// PX8). A nest gives 25 XP, once per nest, and its boss 25 more (5.x: the entity's values every time, the script
// defaults 20 and 0); a bribe or dialogue payment 5 XP (5.x: a tenth of the money); an Axii choice 5 XP per Axii level
// (1 + Delusion's level, 5 to 20; 5.x: 20 more). Legacy's values as constants, without its three new nest fields.

// 5.x body; changes marked //modSigns.
@replaceMethod(CMonsterNestEntity)
function AddExp ()
{
	if ( expWasAdded )	//modSigns: once per nest (legacy's addExpOnlyOnceMod; 5.x: the entity's addExpOnlyOnce)
	{
		return;
	}

	expWasAdded = true;
	GetWitcherPlayer().AddPoints(EExperiencePoint, 25, true );	//modSigns: legacy's expOnNestDestroyedMod

}

// 5.x body; changes marked //modSigns.
@replaceMethod(CMonsterNestEntity)
function AddBonusExp ()
{
	GetWitcherPlayer().AddPoints(EExperiencePoint, 25, true );	//modSigns: legacy's bonusExpOnBossKilledMod
}

// 5.x body; changes marked //modSigns.
@replaceMethod(CPayFactBasedStorySceneChoiceAction)
function PerformAction()
{
	thePlayer.RemoveMoney( FactsQuerySum( valueFact ) );
	GetWitcherPlayer().AddPoints( EExperiencePoint, 5, true );	//modSigns: fixed experience for a bribe
	theSound.SoundEvent("gui_bribe");
}

// 5.x body; changes marked //modSigns.
@replaceMethod(CPayStorySceneChoiceAction)
function PerformAction()
{
	thePlayer.RemoveMoney( money );

	if( !dontGrantExp )
	{
		GetWitcherPlayer().AddPoints( EExperiencePoint, 5, true );	//modSigns: fixed experience for a bribe
	}

	theSound.SoundEvent("gui_bribe");
}

// 5.x body; changes marked //modSigns.
@replaceMethod(CAxiiStorySceneChoiceAction)
function PerformAction()
{
	GetWitcherPlayer().AddPoints( EExperiencePoint, GetWitcherPlayer().GetAxiiLevel() * 5, true );	//modSigns: less experience for Axii (legacy: no 20)
}
