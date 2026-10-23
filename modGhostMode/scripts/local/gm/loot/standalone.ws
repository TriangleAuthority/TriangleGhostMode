// Ghost Mode: the standalone starts' inventories (LOOT-09, legacy; the owner's DT6). Hearts of Stone's
// and Blood and Wine's standalone starts (from the main menu) give smaller inventories: 4,000 and 5,000
// crowns, fewer mutagens, materials, bolts, kits and food. The inventory is given again by a timer once
// Geralt's inventory exists, once per save (facts standalone_ep1_inv, standalone_ep2_inv), and the start
// facts are added only once. The four functions are 5.x's with legacy's changes merged (5.x's own changes
// to StandaloneEp1_2 and StandaloneEp2_2 kept). See docs/features/loot.md.

@wrapMethod(W3PlayerWitcher)
function OnSpawned(spawnData : SEntitySpawnData)
{
	wrappedMethod(spawnData);
	if( FactsQuerySum("standalone_ep1") > 0 && FactsQuerySum("standalone_ep1_inv") < 1 )
	{
		AddTimer('GMGiveStandaloneEp1Items', 0.00001, true, , , true);
	}
	if( FactsQuerySum("standalone_ep2") > 0 && FactsQuerySum("standalone_ep2_inv") < 1 )
	{
		AddTimer('GMGiveStandaloneEp2Items', 0.00001, true, , , true);
	}
}

// Legacy's GiveStandAloneEP1Items: waits until the inventory holds items, then gives the start's inventory.
@addMethod(W3PlayerWitcher)
timer function GMGiveStandaloneEp1Items(dt : float, timerId : int)
{
	var items : array<SItemUniqueId>;

	if( !inv )
		return;
	inv.GetAllItems(items);
	if( items.Size() <= 0 )
		return;
	StandaloneEp1_1();
	FactsAdd("standalone_ep1_inv", 1);
	RemoveTimer('GMGiveStandaloneEp1Items');
}

@addMethod(W3PlayerWitcher)
timer function GMGiveStandaloneEp2Items(dt : float, timerId : int)
{
	var items : array<SItemUniqueId>;

	if( !inv )
		return;
	inv.GetAllItems(items);
	if( items.Size() <= 0 )
		return;
	StandaloneEp2_1();
	FactsAdd("standalone_ep2_inv", 1);
	RemoveTimer('GMGiveStandaloneEp2Items');
}

@replaceMethod(W3PlayerWitcher)
function StandaloneEp1_1()
{
	var i, inc, quantityLow, randLow, quantityMedium, randMedium, quantityHigh, randHigh, startingMoney : int;
	var pam : W3PlayerAbilityManager;
	var ids : array<SItemUniqueId>;
	var STARTING_LEVEL : int;

	FactsAdd("StandAloneEP1", 1);


	inv.RemoveAllItems();


	inv.AddAnItem('Illusion Medallion', 1, true, true, false);
	inv.AddAnItem('q103_safe_conduct', 1, true, true, false);


	theGame.GetGamerProfile().ClearAllAchievementsForEP1();


	STARTING_LEVEL = 32;
	inc = STARTING_LEVEL - GetLevel();
	for(i=0; i<inc; i+=1)
	{
		levelManager.AddPoints(EExperiencePoint, levelManager.GetTotalExpForNextLevel() - levelManager.GetPointsTotal(EExperiencePoint), false);
	}


	levelManager.ResetCharacterDev();
	pam = (W3PlayerAbilityManager)abilityManager;
	if(pam)
	{
		pam.ResetCharacterDev();
	}
	levelManager.SetFreeSkillPoints(levelManager.GetLevel() - 1 + 11);


	//modSigns: removed inv.AddAnItem('Mutagen red', 4);
	//modSigns: removed inv.AddAnItem('Mutagen green', 4);
	//modSigns: removed inv.AddAnItem('Mutagen blue', 4);
	//modSigns
	inv.AddAnItem('Greater mutagen red', 1); //modSigns
	inv.AddAnItem('Greater mutagen green', 1); //modSigns
	inv.AddAnItem('Greater mutagen blue', 1); //modSigns
	inv.AddAnItem('Mutagen red', 2); //modSigns
	inv.AddAnItem('Mutagen green', 2); //modSigns
	inv.AddAnItem('Mutagen blue', 2); //modSigns
	inv.AddAnItem('Lesser mutagen red', 2);
	inv.AddAnItem('Lesser mutagen green', 2);
	inv.AddAnItem('Lesser mutagen blue', 2);
	//modSigns: removed inv.AddAnItem('Greater mutagen green', 1);
	//modSigns: removed inv.AddAnItem('Greater mutagen blue', 2);


	//modSigns: removed startingMoney = 40000;
	startingMoney = 4000; //modSigns
	if(GetMoney() > startingMoney)
	{
		RemoveMoney(GetMoney() - startingMoney);
	}
	else
	{
		//modSigns: removed AddMoney( 40000 - GetMoney() );
		AddMoney( 4000 - GetMoney() ); //modSigns
	}





	ids.Clear();
	ids = inv.AddAnItem('EP1 Standalone Starting Armor');
	EquipItem(ids[0]);
	ids.Clear();
	ids = inv.AddAnItem('EP1 Standalone Starting Boots');
	EquipItem(ids[0]);
	ids.Clear();
	ids = inv.AddAnItem('EP1 Standalone Starting Gloves');
	EquipItem(ids[0]);
	ids.Clear();
	ids = inv.AddAnItem('EP1 Standalone Starting Pants');
	EquipItem(ids[0]);


	ids.Clear();
	ids = inv.AddAnItem('EP1 Standalone Starting Steel Sword');
	EquipItem(ids[0]);
	ids.Clear();
	ids = inv.AddAnItem('EP1 Standalone Starting Silver Sword');
	EquipItem(ids[0]);


	inv.AddAnItem('Torch', 1, true, true, false);


	//modSigns
	quantityLow = 1;
	//modSigns: removed randLow = 3;
	//modSigns: removed quantityMedium = 4;
	//modSigns: removed randMedium = 4;
	//modSigns: removed quantityHigh = 8;
	//modSigns: removed randHigh = 6;
	randLow = 2; //modSigns
	quantityMedium = 2; //modSigns
	randMedium = 2; //modSigns
	quantityHigh = 3; //modSigns
	randHigh = 2; //modSigns

	inv.AddAnItem('Alghoul bone marrow',quantityMedium+RandRange(randMedium));
	inv.AddAnItem('Amethyst dust',quantityLow+RandRange(randLow));
	inv.AddAnItem('Arachas eyes',quantityLow+RandRange(randLow));
	inv.AddAnItem('Arachas venom',quantityLow+RandRange(randLow));
	inv.AddAnItem('Basilisk hide',quantityLow+RandRange(randLow));
	inv.AddAnItem('Basilisk venom',quantityLow+RandRange(randLow));
	//modSigns: removed inv.AddAnItem('Bear pelt',quantityHigh+RandRange(randHigh));
	inv.AddAnItem('Berserker pelt',quantityLow+RandRange(randLow));
	inv.AddAnItem('Coal',quantityHigh+RandRange(randHigh));
	inv.AddAnItem('Cotton',quantityHigh+RandRange(randHigh));
	inv.AddAnItem('Dark iron ingot',quantityLow+RandRange(randLow));
	inv.AddAnItem('Dark iron ore',quantityLow+RandRange(randLow));
	//modSigns: removed inv.AddAnItem('Deer hide',quantityHigh+RandRange(randHigh));
	inv.AddAnItem('Diamond dust',quantityLow+RandRange(randLow));
	inv.AddAnItem('Draconide leather',quantityLow+RandRange(randLow));
	inv.AddAnItem('Drowned dead tongue',quantityLow+RandRange(randLow));
	inv.AddAnItem('Drowner brain',quantityMedium+RandRange(randMedium));
	inv.AddAnItem('Dwimeryte ingot',quantityLow+RandRange(randLow));
	inv.AddAnItem('Dwimeryte ore',quantityLow+RandRange(randLow));
	inv.AddAnItem('Emerald dust',quantityLow+RandRange(randLow));
	inv.AddAnItem('Endriag chitin plates',quantityMedium+RandRange(randMedium));
	inv.AddAnItem('Endriag embryo',quantityLow+RandRange(randLow));
	inv.AddAnItem('Ghoul blood',quantityMedium+RandRange(randMedium));
	//modSigns: removed inv.AddAnItem('Goat hide',quantityMedium+RandRange(randMedium));
	inv.AddAnItem('Hag teeth',quantityMedium+RandRange(randMedium));
	inv.AddAnItem('Hardened leather',quantityMedium+RandRange(randMedium));
	inv.AddAnItem('Hardened timber',quantityMedium+RandRange(randMedium));
	inv.AddAnItem('Harpy feathers',quantityMedium+RandRange(randMedium));
	//modSigns: removed inv.AddAnItem('Horse hide',quantityLow+RandRange(randLow));
	inv.AddAnItem('Iron ore',quantityHigh+RandRange(randHigh));
	inv.AddAnItem('Leather straps',quantityHigh+RandRange(randHigh));
	inv.AddAnItem('Leather',quantityHigh+RandRange(randHigh));
	inv.AddAnItem('Linen',quantityMedium+RandRange(randMedium));
	inv.AddAnItem('Meteorite ingot',quantityLow+RandRange(randLow));
	inv.AddAnItem('Meteorite ore',quantityMedium+RandRange(randMedium));
	inv.AddAnItem('Necrophage skin',quantityLow+RandRange(randLow));
	inv.AddAnItem('Nekker blood',quantityHigh+RandRange(randHigh));
	inv.AddAnItem('Nekker heart',quantityMedium+RandRange(randMedium));
	inv.AddAnItem('Oil',quantityHigh+RandRange(randHigh));
	inv.AddAnItem('Phosphorescent crystal',quantityLow+RandRange(randLow));
	//modSigns: removed inv.AddAnItem('Pig hide',quantityMedium+RandRange(randMedium));
	inv.AddAnItem('Pure silver',quantityMedium+RandRange(randMedium));
	//modSigns: removed inv.AddAnItem('Rabbit pelt',quantityMedium+RandRange(randMedium));
	inv.AddAnItem('Rotfiend blood',quantityMedium+RandRange(randMedium));
	inv.AddAnItem('Sapphire dust',quantityLow+RandRange(randLow));
	inv.AddAnItem('Silk',quantityHigh+RandRange(randHigh));
	inv.AddAnItem('Silver ingot',quantityMedium+RandRange(randMedium));
	inv.AddAnItem('Silver ore',quantityHigh+RandRange(randHigh));
	inv.AddAnItem('Specter dust',quantityMedium+RandRange(randMedium));
	inv.AddAnItem('Steel ingot',quantityHigh+RandRange(randHigh));
	//modSigns: removed inv.AddAnItem('Steel plate',quantityHigh+RandRange(randHigh));
	inv.AddAnItem('String',quantityHigh+RandRange(randHigh));
	inv.AddAnItem('Thread',quantityHigh+RandRange(randHigh));
	inv.AddAnItem('Timber',quantityHigh+RandRange(randHigh));
	inv.AddAnItem('Twine',quantityMedium+RandRange(randMedium));
	inv.AddAnItem('Venom extract',quantityMedium+RandRange(randMedium));
	inv.AddAnItem('Water essence',quantityMedium+RandRange(randMedium));
	inv.AddAnItem('Wolf liver',quantityHigh+RandRange(randHigh));
	//modSigns: removed inv.AddAnItem('Wolf pelt',quantityMedium+RandRange(randMedium));
	//modSigns: removed inv.AddAnItem('Alcohest', 5);
	//modSigns: removed inv.AddAnItem('Dwarven spirit', 5);
	inv.AddAnItem('Alcohest', 3); //modSigns
	inv.AddAnItem('Dwarven spirit', 4); //modSigns


	ids.Clear();
	ids = inv.AddAnItem('Crossbow 5');
	EquipItem(ids[0]);
	ids.Clear();
	//modSigns: removed ids = inv.AddAnItem('Blunt Bolt', 100);
	ids = inv.AddAnItem('Blunt Bolt', 20); //modSigns
	EquipItem(ids[0]);
	//modSigns: removed inv.AddAnItem('Broadhead Bolt', 100);
	//modSigns: removed inv.AddAnItem('Split Bolt', 100);
	inv.AddAnItem('Broadhead Bolt', 20); //modSigns
	inv.AddAnItem('Split Bolt', 20); //modSigns


	RemoveAllAlchemyRecipes();
	RemoveAllCraftingSchematics();




	AddAlchemyRecipe('Recipe for Cat 1');



	AddAlchemyRecipe('Recipe for Maribor Forest 1');
	AddAlchemyRecipe('Recipe for Petris Philtre 1');
	AddAlchemyRecipe('Recipe for Swallow 1');
	AddAlchemyRecipe('Recipe for Tawny Owl 1');

	AddAlchemyRecipe('Recipe for White Gull 1');
	AddAlchemyRecipe('Recipe for White Honey 1');
	AddAlchemyRecipe('Recipe for White Raffards Decoction 1');



	AddAlchemyRecipe('Recipe for Beast Oil 1');
	AddAlchemyRecipe('Recipe for Cursed Oil 1');
	AddAlchemyRecipe('Recipe for Hanged Man Venom 1');
	AddAlchemyRecipe('Recipe for Hybrid Oil 1');
	AddAlchemyRecipe('Recipe for Insectoid Oil 1');
	AddAlchemyRecipe('Recipe for Magicals Oil 1');
	AddAlchemyRecipe('Recipe for Necrophage Oil 1');
	AddAlchemyRecipe('Recipe for Specter Oil 1');
	AddAlchemyRecipe('Recipe for Vampire Oil 1');
	AddAlchemyRecipe('Recipe for Draconide Oil 1');
	AddAlchemyRecipe('Recipe for Ogre Oil 1');
	AddAlchemyRecipe('Recipe for Relic Oil 1');
	AddAlchemyRecipe('Recipe for Beast Oil 2');
	AddAlchemyRecipe('Recipe for Cursed Oil 2');
	AddAlchemyRecipe('Recipe for Hanged Man Venom 2');
	AddAlchemyRecipe('Recipe for Hybrid Oil 2');
	AddAlchemyRecipe('Recipe for Insectoid Oil 2');
	AddAlchemyRecipe('Recipe for Magicals Oil 2');
	AddAlchemyRecipe('Recipe for Necrophage Oil 2');
	AddAlchemyRecipe('Recipe for Specter Oil 2');
	AddAlchemyRecipe('Recipe for Vampire Oil 2');
	AddAlchemyRecipe('Recipe for Draconide Oil 2');
	AddAlchemyRecipe('Recipe for Ogre Oil 2');
	AddAlchemyRecipe('Recipe for Relic Oil 2');


	AddAlchemyRecipe('Recipe for Dancing Star 1');

	AddAlchemyRecipe('Recipe for Dwimeritum Bomb 1');

	AddAlchemyRecipe('Recipe for Grapeshot 1');
	AddAlchemyRecipe('Recipe for Samum 1');

	AddAlchemyRecipe('Recipe for White Frost 1');



	AddAlchemyRecipe('Recipe for Dwarven spirit 1');
	AddAlchemyRecipe('Recipe for Alcohest 1');
	AddAlchemyRecipe('Recipe for White Gull 1');


	AddStartingSchematics();


	ids.Clear();
	ids = inv.AddAnItem('Swallow 2');
	EquipItem(ids[0]);
	ids.Clear();
	ids = inv.AddAnItem('Thunderbolt 2');
	EquipItem(ids[0]);
	ids.Clear();
	ids = inv.AddAnItem('Tawny Owl 2');
	EquipItem(ids[0]);
	ids.Clear();

	ids = inv.AddAnItem('Grapeshot 2');
	EquipItem(ids[0]);
	ids.Clear();
	ids = inv.AddAnItem('Samum 2');
	EquipItem(ids[0]);

	inv.AddAnItem('Dwimeritum Bomb 1');
	inv.AddAnItem('Dragons Dream 1');
	inv.AddAnItem('Silver Dust Bomb 1');
	inv.AddAnItem('White Frost 2');
	inv.AddAnItem('Devils Puffball 2');
	inv.AddAnItem('Dancing Star 2');
	inv.AddAnItem('Beast Oil 1');
	inv.AddAnItem('Cursed Oil 1');
	inv.AddAnItem('Hanged Man Venom 2');
	inv.AddAnItem('Hybrid Oil 1');
	inv.AddAnItem('Insectoid Oil 1');
	inv.AddAnItem('Magicals Oil 1');
	inv.AddAnItem('Necrophage Oil 2');
	inv.AddAnItem('Specter Oil 1');
	inv.AddAnItem('Vampire Oil 1');
	inv.AddAnItem('Draconide Oil 1');
	inv.AddAnItem('Relic Oil 1');
	inv.AddAnItem('Black Blood 1');
	inv.AddAnItem('Blizzard 1');
	inv.AddAnItem('Cat 2');
	inv.AddAnItem('Full Moon 1');
	inv.AddAnItem('Maribor Forest 1');
	inv.AddAnItem('Petris Philtre 1');
	//modSigns: removed inv.AddAnItem('White Gull 1', 3);
	inv.AddAnItem('White Gull 1', 2); //modSigns
	inv.AddAnItem('White Honey 2');
	inv.AddAnItem('White Raffards Decoction 1');


	inv.AddAnItem('Mutagen 17');
	inv.AddAnItem('Mutagen 19');
	inv.AddAnItem('Mutagen 27');
	inv.AddAnItem('Mutagen 26');


	//modSigns: removed inv.AddAnItem('weapon_repair_kit_1', 5);
	//modSigns: removed inv.AddAnItem('weapon_repair_kit_2', 3);
	//modSigns: removed inv.AddAnItem('armor_repair_kit_1', 5);
	//modSigns: removed inv.AddAnItem('armor_repair_kit_2', 3);
	inv.AddAnItem('weapon_repair_kit_1', 3); //modSigns
	inv.AddAnItem('weapon_repair_kit_2', 2); //modSigns
	inv.AddAnItem('armor_repair_kit_1', 3); //modSigns
	inv.AddAnItem('armor_repair_kit_2', 2); //modSigns


	//modSigns: removed quantityMedium = 2;
	quantityMedium = 1; //modSigns
	quantityLow = 1;
	inv.AddAnItem('Rune stribog lesser', quantityMedium);
	inv.AddAnItem('Rune stribog', quantityLow);
	inv.AddAnItem('Rune dazhbog lesser', quantityMedium);
	inv.AddAnItem('Rune dazhbog', quantityLow);
	inv.AddAnItem('Rune devana lesser', quantityMedium);
	inv.AddAnItem('Rune devana', quantityLow);
	inv.AddAnItem('Rune zoria lesser', quantityMedium);
	inv.AddAnItem('Rune zoria', quantityLow);
	inv.AddAnItem('Rune morana lesser', quantityMedium);
	inv.AddAnItem('Rune morana', quantityLow);
	inv.AddAnItem('Rune triglav lesser', quantityMedium);
	inv.AddAnItem('Rune triglav', quantityLow);
	inv.AddAnItem('Rune svarog lesser', quantityMedium);
	inv.AddAnItem('Rune svarog', quantityLow);
	inv.AddAnItem('Rune veles lesser', quantityMedium);
	inv.AddAnItem('Rune veles', quantityLow);
	inv.AddAnItem('Rune perun lesser', quantityMedium);
	inv.AddAnItem('Rune perun', quantityLow);
	inv.AddAnItem('Rune elemental lesser', quantityMedium);
	inv.AddAnItem('Rune elemental', quantityLow);

	inv.AddAnItem('Glyph aard lesser', quantityMedium);
	inv.AddAnItem('Glyph aard', quantityLow);
	inv.AddAnItem('Glyph axii lesser', quantityMedium);
	inv.AddAnItem('Glyph axii', quantityLow);
	inv.AddAnItem('Glyph igni lesser', quantityMedium);
	inv.AddAnItem('Glyph igni', quantityLow);
	inv.AddAnItem('Glyph quen lesser', quantityMedium);
	inv.AddAnItem('Glyph quen', quantityLow);
	inv.AddAnItem('Glyph yrden lesser', quantityMedium);
	inv.AddAnItem('Glyph yrden', quantityLow);


	StandaloneEp1_2();
}

@replaceMethod(W3PlayerWitcher)
function StandaloneEp1_2()
{
	var horseId : SItemUniqueId;
	var ids : array<SItemUniqueId>;
	var ents : array< CJournalBase >;
	var i : int;
	var manager : CWitcherJournalManager;


	//modSigns: removed inv.AddAnItem( 'Cows milk', 20 );
	inv.AddAnItem( 'Cows milk', 5 ); //modSigns
	ids.Clear();
	//modSigns: removed ids = inv.AddAnItem( 'Dumpling', 44 );
	ids = inv.AddAnItem( 'Dumpling', 5 ); //modSigns
	EquipItem(ids[0]);


	inv.AddAnItem('Clearing Potion', 2, true, false, false);


	GetHorseManager().RemoveAllItems();

	ids.Clear();
	ids = inv.AddAnItem('Horse Bag 2');
	horseId = GetHorseManager().MoveItemToHorse(ids[0]);
	GetHorseManager().EquipItem(horseId);

	ids.Clear();
	ids = inv.AddAnItem('Horse Blinder 2');
	horseId = GetHorseManager().MoveItemToHorse(ids[0]);
	GetHorseManager().EquipItem(horseId);

	ids.Clear();
	ids = inv.AddAnItem('Horse Saddle 2');
	horseId = GetHorseManager().MoveItemToHorse(ids[0]);
	GetHorseManager().EquipItem(horseId);

	manager = theGame.GetJournalManager();


	manager.GetActivatedOfType( 'CJournalCreature', ents );
	for(i=0; i<ents.Size(); i+=1)
	{
		manager.ActivateEntry(ents[i], JS_Inactive, false, true);
	}


	ents.Clear();
	manager.GetActivatedOfType( 'CJournalCharacter', ents );
	for(i=0; i<ents.Size(); i+=1)
	{
		manager.ActivateEntry(ents[i], JS_Inactive, false, true);
	}


	ents.Clear();
	manager.GetActivatedOfType( 'CJournalQuest', ents );
	for(i=0; i<ents.Size(); i+=1)
	{

		if( StrStartsWith(ents[i].baseName, "q60"))
			continue;

		manager.ActivateEntry(ents[i], JS_Inactive, false, true);
	}


	manager.ActivateEntryByScriptTag('TutorialAard', JS_Active);
	manager.ActivateEntryByScriptTag('TutorialAdrenaline', JS_Active);
	manager.ActivateEntryByScriptTag('TutorialAxii', JS_Active);
	manager.ActivateEntryByScriptTag('TutorialAxiiDialog', JS_Active);
	manager.ActivateEntryByScriptTag('TutorialCamera', JS_Active);
	manager.ActivateEntryByScriptTag('TutorialCamera_pad', JS_Active);
	manager.ActivateEntryByScriptTag('TutorialCiriBlink', JS_Active);
	manager.ActivateEntryByScriptTag('TutorialCiriCharge', JS_Active);
	manager.ActivateEntryByScriptTag('TutorialCiriStamina', JS_Active);
	manager.ActivateEntryByScriptTag('TutorialCounter', JS_Active);
	manager.ActivateEntryByScriptTag('TutorialDialogClose', JS_Active);
	manager.ActivateEntryByScriptTag('TutorialFallingRoll', JS_Active);
	manager.ActivateEntryByScriptTag('TutorialFocus', JS_Active);
	manager.ActivateEntryByScriptTag('TutorialFocusClues', JS_Active);
	manager.ActivateEntryByScriptTag('TutorialHorseRoad', JS_Active);
	manager.ActivateEntryByScriptTag('TutorialHorseSpeed0', JS_Active);
	manager.ActivateEntryByScriptTag('TutorialHorseSpeed0_pad', JS_Active);
	manager.ActivateEntryByScriptTag('TutorialHorseSpeed1', JS_Active);
	manager.ActivateEntryByScriptTag('TutorialHorseSpeed2', JS_Active);
	manager.ActivateEntryByScriptTag('TutorialHorseSummon', JS_Active);
	manager.ActivateEntryByScriptTag('TutorialHorseSummon_pad', JS_Active);
	manager.ActivateEntryByScriptTag('TutorialIgni', JS_Active);
	manager.ActivateEntryByScriptTag('TutorialJournalAlternateSings', JS_Active);
	manager.ActivateEntryByScriptTag('TutorialJournalBoatDamage', JS_Active);
	manager.ActivateEntryByScriptTag('TutorialJournalBoatMount', JS_Active);
	manager.ActivateEntryByScriptTag('TutorialJournalBuffs', JS_Active);
	manager.ActivateEntryByScriptTag('TutorialJournalCharDevLeveling', JS_Active);
	manager.ActivateEntryByScriptTag('TutorialJournalCharDevSkills', JS_Active);
	manager.ActivateEntryByScriptTag('TutorialJournalCrafting', JS_Active);
	manager.ActivateEntryByScriptTag('TutorialJournalCrossbow', JS_Active);
	manager.ActivateEntryByScriptTag('TutorialJournalDialogGwint', JS_Active);
	manager.ActivateEntryByScriptTag('TutorialJournalDialogShop', JS_Active);
	manager.ActivateEntryByScriptTag('TutorialJournalDive', JS_Active);
	manager.ActivateEntryByScriptTag('TutorialJournalDodge', JS_Active);
	manager.ActivateEntryByScriptTag('TutorialJournalDodge_pad', JS_Active);
	manager.ActivateEntryByScriptTag('TutorialJournalDrawWeapon', JS_Active);
	manager.ActivateEntryByScriptTag('TutorialJournalDrawWeapon_pad', JS_Active);
	manager.ActivateEntryByScriptTag('TutorialJournalDurability', JS_Active);
	manager.ActivateEntryByScriptTag('TutorialJournalExplorations', JS_Active);
	manager.ActivateEntryByScriptTag('TutorialJournalExplorations_pad', JS_Active);
	manager.ActivateEntryByScriptTag('TutorialJournalFastTravel', JS_Active);
	manager.ActivateEntryByScriptTag('TutorialJournalFocusRedObjects', JS_Active);
	manager.ActivateEntryByScriptTag('TutorialJournalGasClouds', JS_Active);
	manager.ActivateEntryByScriptTag('TutorialJournalHeavyAttacks', JS_Active);
	manager.ActivateEntryByScriptTag('TutorialJournalHorse', JS_Active);
	manager.ActivateEntryByScriptTag('TutorialJournalHorseStamina', JS_Active);
	manager.ActivateEntryByScriptTag('TutorialJournalJump', JS_Active);
	manager.ActivateEntryByScriptTag('TutorialJournalLightAttacks', JS_Active);
	manager.ActivateEntryByScriptTag('TutorialJournalLightAttacks_pad', JS_Active);
	manager.ActivateEntryByScriptTag('TutorialJournalMeditation', JS_Active);
	manager.ActivateEntryByScriptTag('TutorialJournalMeditation_pad', JS_Active);
	manager.ActivateEntryByScriptTag('TutorialJournalMonsterThreatLevels', JS_Active);
	manager.ActivateEntryByScriptTag('TutorialJournalMovement', JS_Active);
	manager.ActivateEntryByScriptTag('TutorialJournalMovement_pad', JS_Active);
	manager.ActivateEntryByScriptTag('TutorialJournalMutagenIngredient', JS_Active);
	manager.ActivateEntryByScriptTag('TutorialJournalMutagenPotion', JS_Active);
	manager.ActivateEntryByScriptTag('TutorialJournalOils', JS_Active);
	manager.ActivateEntryByScriptTag('TutorialJournalPetards', JS_Active);
	manager.ActivateEntryByScriptTag('TutorialJournalPotions', JS_Active);
	manager.ActivateEntryByScriptTag('TutorialJournalPotions_pad', JS_Active);
	manager.ActivateEntryByScriptTag('TutorialJournalQuestArea', JS_Active);
	manager.ActivateEntryByScriptTag('TutorialJournalRadial', JS_Active);
	manager.ActivateEntryByScriptTag('TutorialJournalRifts', JS_Active);
	manager.ActivateEntryByScriptTag('TutorialJournalRun', JS_Active);
	manager.ActivateEntryByScriptTag('TutorialJournalShopDescription', JS_Active);
	manager.ActivateEntryByScriptTag('TutorialJournalSignCast', JS_Active);
	manager.ActivateEntryByScriptTag('TutorialJournalSignCast_pad', JS_Active);
	manager.ActivateEntryByScriptTag('TutorialJournalSpecialAttacks', JS_Active);
	manager.ActivateEntryByScriptTag('TutorialJournalStaminaExploration', JS_Active);
	manager.ActivateEntryByScriptTag('TutorialJumpHang', JS_Active);
	manager.ActivateEntryByScriptTag('TutorialLadder', JS_Active);
	manager.ActivateEntryByScriptTag('TutorialLadderMove', JS_Active);
	manager.ActivateEntryByScriptTag('TutorialLadderMove_pad', JS_Active);
	manager.ActivateEntryByScriptTag('TutorialObjectiveSwitching', JS_Active);
	manager.ActivateEntryByScriptTag('TutorialOxygen', JS_Active);
	manager.ActivateEntryByScriptTag('TutorialParry', JS_Active);
	manager.ActivateEntryByScriptTag('TutorialPOIUncovered', JS_Active);
	manager.ActivateEntryByScriptTag('TutorialQuen', JS_Active);
	manager.ActivateEntryByScriptTag('TutorialRoll', JS_Active);
	manager.ActivateEntryByScriptTag('TutorialRoll_pad', JS_Active);
	manager.ActivateEntryByScriptTag('TutorialSpeedPairing', JS_Active);
	manager.ActivateEntryByScriptTag('TutorialSprint', JS_Active);
	manager.ActivateEntryByScriptTag('TutorialStaminaSigns', JS_Active);
	manager.ActivateEntryByScriptTag('TutorialStealing', JS_Active);
	manager.ActivateEntryByScriptTag('TutorialSwimmingSpeed', JS_Active);
	manager.ActivateEntryByScriptTag('TutorialTimedChoiceDialog', JS_Active);
	manager.ActivateEntryByScriptTag('TutorialYrden', JS_Active);


	FactsAdd('kill_base_tutorials');


	theGame.GetTutorialSystem().RemoveAllQueuedTutorials();

	//modSigns: removed FactsAdd('standalone_ep1');
	if( FactsQuerySum("standalone_ep1") < 1 ) //modSigns
		FactsAdd("standalone_ep1"); //modSigns
	FactsRemove("StandAloneEP1");

	theGame.GetJournalManager().ForceUntrackingQuestForEP1Savegame();
}

@replaceMethod(W3PlayerWitcher)
function StandaloneEp2_1()
{
	var i, inc, quantityLow, randLow, quantityMedium, randMedium, quantityHigh, randHigh, startingMoney : int;
	var pam : W3PlayerAbilityManager;
	var ids : array<SItemUniqueId>;
	var STARTING_LEVEL : int;

	FactsAdd( "StandAloneEP2", 1 );


	inv.RemoveAllItems();


	inv.AddAnItem( 'Illusion Medallion', 1, true, true, false );
	inv.AddAnItem( 'q103_safe_conduct', 1, true, true, false );


	theGame.GetGamerProfile().ClearAllAchievementsForEP2();


	levelManager.Hack_EP2StandaloneLevelShrink( 35 );


	levelManager.ResetCharacterDev();
	pam = ( W3PlayerAbilityManager )abilityManager;
	if( pam )
	{
		pam.ResetCharacterDev();
	}
	levelManager.SetFreeSkillPoints( levelManager.GetLevel() - 1 + 11 );


	//modSigns: removed inv.AddAnItem( 'Mutagen red', 4 );
	//modSigns: removed inv.AddAnItem( 'Mutagen green', 4 );
	//modSigns: removed inv.AddAnItem( 'Mutagen blue', 4 );
	//modSigns: removed inv.AddAnItem( 'Lesser mutagen red', 2 );
	//modSigns: removed inv.AddAnItem( 'Lesser mutagen green', 2 );
	//modSigns: removed inv.AddAnItem( 'Lesser mutagen blue', 2 );
	//modSigns: removed inv.AddAnItem( 'Greater mutagen red', 2 );
	//modSigns: removed inv.AddAnItem( 'Greater mutagen green', 2 );
	//modSigns: removed inv.AddAnItem( 'Greater mutagen blue', 2 );
	//modSigns
	inv.AddAnItem('Greater mutagen red', 1); //modSigns
	inv.AddAnItem('Greater mutagen green', 1); //modSigns
	inv.AddAnItem('Greater mutagen blue', 1); //modSigns
	inv.AddAnItem('Mutagen red', 2); //modSigns
	inv.AddAnItem('Mutagen green', 2); //modSigns
	inv.AddAnItem('Mutagen blue', 2); //modSigns
	inv.AddAnItem('Lesser mutagen red', 2); //modSigns
	inv.AddAnItem('Lesser mutagen green', 2); //modSigns
	inv.AddAnItem('Lesser mutagen blue', 2); //modSigns


	//modSigns: removed startingMoney = 20000;
	startingMoney = 5000; //modSigns
	if( GetMoney() > startingMoney )
	{
		RemoveMoney( GetMoney() - startingMoney );
	}
	else
	{
		//modSigns: removed AddMoney( 20000 - GetMoney() );
		AddMoney( 5000 - GetMoney() ); //modSigns
	}


	ids.Clear();
	ids = inv.AddAnItem( 'EP2 Standalone Starting Armor' );
	EquipItem( ids[0] );
	ids.Clear();
	ids = inv.AddAnItem( 'EP2 Standalone Starting Boots' );
	EquipItem( ids[0] );
	ids.Clear();
	ids = inv.AddAnItem( 'EP2 Standalone Starting Gloves' );
	EquipItem( ids[0] );
	ids.Clear();
	ids = inv.AddAnItem( 'EP2 Standalone Starting Pants' );
	EquipItem( ids[0] );


	ids.Clear();
	ids = inv.AddAnItem( 'EP2 Standalone Starting Steel Sword' );
	EquipItem( ids[0] );
	ids.Clear();
	ids = inv.AddAnItem( 'EP2 Standalone Starting Silver Sword' );
	EquipItem( ids[0] );


	inv.AddAnItem( 'Torch', 1, true, true, false );


	//modSigns
	quantityLow = 1;
	//modSigns: removed randLow = 3;
	//modSigns: removed quantityMedium = 4;
	//modSigns: removed randMedium = 4;
	//modSigns: removed quantityHigh = 8;
	//modSigns: removed randHigh = 6;
	randLow = 2; //modSigns
	quantityMedium = 2; //modSigns
	randMedium = 2; //modSigns
	quantityHigh = 3; //modSigns
	randHigh = 2; //modSigns

	inv.AddAnItem( 'Alghoul bone marrow',quantityMedium+RandRange( randMedium ) );
	inv.AddAnItem( 'Amethyst dust',quantityLow+RandRange( randLow ) );
	inv.AddAnItem( 'Arachas eyes',quantityLow+RandRange( randLow ) );
	inv.AddAnItem( 'Arachas venom',quantityLow+RandRange( randLow ) );
	inv.AddAnItem( 'Basilisk hide',quantityLow+RandRange( randLow ) );
	inv.AddAnItem( 'Basilisk venom',quantityLow+RandRange( randLow ) );
	//modSigns: removed inv.AddAnItem( 'Bear pelt',quantityHigh+RandRange( randHigh ) );
	inv.AddAnItem( 'Berserker pelt',quantityLow+RandRange( randLow ) );
	inv.AddAnItem( 'Coal',quantityHigh+RandRange( randHigh ) );
	inv.AddAnItem( 'Cotton',quantityHigh+RandRange( randHigh ) );
	//modSigns: removed inv.AddAnItem( 'Deer hide',quantityHigh+RandRange( randHigh ) );
	inv.AddAnItem( 'Diamond dust',quantityLow+RandRange( randLow ) );
	inv.AddAnItem( 'Drowned dead tongue',quantityLow+RandRange( randLow ) );
	inv.AddAnItem( 'Drowner brain',quantityMedium+RandRange( randMedium ) );
	inv.AddAnItem( 'Endriag chitin plates',quantityMedium+RandRange( randMedium ) );
	inv.AddAnItem( 'Endriag embryo',quantityLow+RandRange( randLow ) );
	inv.AddAnItem( 'Ghoul blood',quantityMedium+RandRange( randMedium ) );
	//modSigns: removed inv.AddAnItem( 'Goat hide',quantityMedium+RandRange( randMedium ) );
	inv.AddAnItem( 'Hag teeth',quantityMedium+RandRange( randMedium ) );
	inv.AddAnItem( 'Hardened leather',quantityMedium+RandRange( randMedium ) );
	inv.AddAnItem( 'Hardened timber',quantityMedium+RandRange( randMedium ) );
	inv.AddAnItem( 'Harpy feathers',quantityMedium+RandRange( randMedium ) );
	//modSigns: removed inv.AddAnItem( 'Horse hide',quantityLow+RandRange( randLow ) );
	inv.AddAnItem( 'Necrophage skin',quantityLow+RandRange( randLow ) );
	inv.AddAnItem( 'Nekker blood',quantityHigh+RandRange( randHigh ) );
	inv.AddAnItem( 'Nekker heart',quantityMedium+RandRange( randMedium ) );
	inv.AddAnItem( 'Phosphorescent crystal',quantityLow+RandRange( randLow ) );
	//modSigns: removed inv.AddAnItem( 'Pig hide',quantityMedium+RandRange( randMedium ) );
	//modSigns: removed inv.AddAnItem( 'Rabbit pelt',quantityMedium+RandRange( randMedium ) );
	inv.AddAnItem( 'Rotfiend blood',quantityMedium+RandRange( randMedium ) );
	inv.AddAnItem( 'Sapphire dust',quantityLow+RandRange( randLow ) );
	inv.AddAnItem( 'Specter dust',quantityMedium+RandRange( randMedium ) );
	inv.AddAnItem( 'Water essence',quantityMedium+RandRange( randMedium ) );
	inv.AddAnItem( 'Wolf liver',quantityHigh+RandRange( randHigh ) );
	//modSigns: removed inv.AddAnItem( 'Wolf pelt',quantityMedium+RandRange( randMedium ) );
	//modSigns: removed inv.AddAnItem( 'Alcohest', 5 );
	//modSigns: removed inv.AddAnItem( 'Dwarven spirit', 5 );
	inv.AddAnItem( 'Alcohest', 3 ); //modSigns
	inv.AddAnItem( 'Dwarven spirit', 4 ); //modSigns


	ids.Clear();
	ids = inv.AddAnItem( 'Crossbow 5' );
	EquipItem( ids[0] );
	ids.Clear();
	//modSigns: removed ids = inv.AddAnItem( 'Blunt Bolt', 100 );
	ids = inv.AddAnItem( 'Blunt Bolt', 20 ); //modSigns
	EquipItem( ids[0] );
	//modSigns: removed inv.AddAnItem( 'Broadhead Bolt', 100 );
	//modSigns: removed inv.AddAnItem( 'Split Bolt', 100 );
	inv.AddAnItem( 'Broadhead Bolt', 20 ); //modSigns
	inv.AddAnItem( 'Split Bolt', 20 ); //modSigns


	RemoveAllAlchemyRecipes();
	RemoveAllCraftingSchematics();









	AddAlchemyRecipe( 'Recipe for Petris Philtre 2' );
	AddAlchemyRecipe( 'Recipe for Swallow 1' );
	AddAlchemyRecipe( 'Recipe for Tawny Owl 1' );

	AddAlchemyRecipe( 'Recipe for White Gull 1' );





	AddAlchemyRecipe( 'Recipe for Beast Oil 1' );
	AddAlchemyRecipe( 'Recipe for Cursed Oil 1' );
	AddAlchemyRecipe( 'Recipe for Hanged Man Venom 1' );
	AddAlchemyRecipe( 'Recipe for Hybrid Oil 1' );
	AddAlchemyRecipe( 'Recipe for Insectoid Oil 2' );
	AddAlchemyRecipe( 'Recipe for Magicals Oil 1' );
	AddAlchemyRecipe( 'Recipe for Necrophage Oil 1' );
	AddAlchemyRecipe( 'Recipe for Specter Oil 1' );
	AddAlchemyRecipe( 'Recipe for Vampire Oil 2' );
	AddAlchemyRecipe( 'Recipe for Draconide Oil 2' );
	AddAlchemyRecipe( 'Recipe for Ogre Oil 1' );
	AddAlchemyRecipe( 'Recipe for Relic Oil 1' );
	AddAlchemyRecipe( 'Recipe for Beast Oil 2' );
	AddAlchemyRecipe( 'Recipe for Cursed Oil 2' );
	AddAlchemyRecipe( 'Recipe for Hanged Man Venom 2' );
	AddAlchemyRecipe( 'Recipe for Hybrid Oil 2' );
	AddAlchemyRecipe( 'Recipe for Insectoid Oil 2' );
	AddAlchemyRecipe( 'Recipe for Magicals Oil 2' );
	AddAlchemyRecipe( 'Recipe for Necrophage Oil 2' );
	AddAlchemyRecipe( 'Recipe for Specter Oil 2' );
	AddAlchemyRecipe( 'Recipe for Vampire Oil 2' );
	AddAlchemyRecipe( 'Recipe for Draconide Oil 2' );
	AddAlchemyRecipe( 'Recipe for Ogre Oil 2' );
	AddAlchemyRecipe( 'Recipe for Relic Oil 2' );


	AddAlchemyRecipe( 'Recipe for Dancing Star 1' );

	AddAlchemyRecipe( 'Recipe for Dwimeritum Bomb 1' );

	AddAlchemyRecipe( 'Recipe for Grapeshot 1' );
	AddAlchemyRecipe( 'Recipe for Samum 1' );

	AddAlchemyRecipe( 'Recipe for White Frost 1' );



	AddAlchemyRecipe( 'Recipe for Dwarven spirit 1' );
	AddAlchemyRecipe( 'Recipe for Alcohest 1' );
	AddAlchemyRecipe( 'Recipe for White Gull 1' );


	AddStartingSchematics();


	ids.Clear();
	ids = inv.AddAnItem( 'Swallow 2' );
	EquipItem( ids[0] );
	ids.Clear();
	ids = inv.AddAnItem( 'Thunderbolt 2' );
	EquipItem( ids[0] );
	ids.Clear();
	ids = inv.AddAnItem( 'Tawny Owl 2' );
	EquipItem( ids[0] );
	ids.Clear();

	ids = inv.AddAnItem( 'Grapeshot 2' );
	EquipItem( ids[0] );
	ids.Clear();
	ids = inv.AddAnItem( 'Samum 2' );
	EquipItem( ids[0] );

	inv.AddAnItem( 'Dwimeritum Bomb 1' );
	inv.AddAnItem( 'Dragons Dream 1' );
	inv.AddAnItem( 'Silver Dust Bomb 1' );
	inv.AddAnItem( 'White Frost 2' );
	inv.AddAnItem( 'Devils Puffball 2' );
	inv.AddAnItem( 'Dancing Star 2' );
	inv.AddAnItem( 'Beast Oil 1' );
	inv.AddAnItem( 'Cursed Oil 1' );
	inv.AddAnItem( 'Hanged Man Venom 2' );
	inv.AddAnItem( 'Hybrid Oil 2' );
	inv.AddAnItem( 'Insectoid Oil 2' );
	inv.AddAnItem( 'Magicals Oil 1' );
	inv.AddAnItem( 'Necrophage Oil 2' );
	inv.AddAnItem( 'Ogre Oil 1' );
	inv.AddAnItem( 'Specter Oil 1' );
	inv.AddAnItem( 'Vampire Oil 2' );
	inv.AddAnItem( 'Draconide Oil 2' );
	inv.AddAnItem( 'Relic Oil 1' );
	inv.AddAnItem( 'Black Blood 1' );
	inv.AddAnItem( 'Blizzard 1' );
	inv.AddAnItem( 'Cat 2' );
	inv.AddAnItem( 'Full Moon 1' );
	inv.AddAnItem( 'Golden Oriole 1' );
	inv.AddAnItem( 'Killer Whale 1' );
	inv.AddAnItem( 'Maribor Forest 1' );
	inv.AddAnItem( 'Petris Philtre 2' );
	//modSigns: removed inv.AddAnItem( 'White Gull 1', 3 );
	inv.AddAnItem( 'White Gull 1', 2 ); //modSigns
	inv.AddAnItem( 'White Honey 2' );
	inv.AddAnItem( 'White Raffards Decoction 1' );


	inv.AddAnItem( 'Mutagen 17' );
	inv.AddAnItem( 'Mutagen 19' );
	inv.AddAnItem( 'Mutagen 27' );
	inv.AddAnItem( 'Mutagen 26' );


	//modSigns: removed inv.AddAnItem( 'weapon_repair_kit_1', 5 );
	//modSigns: removed inv.AddAnItem( 'weapon_repair_kit_2', 3 );
	//modSigns: removed inv.AddAnItem( 'armor_repair_kit_1', 5 );
	//modSigns: removed inv.AddAnItem( 'armor_repair_kit_2', 3 );
	inv.AddAnItem( 'weapon_repair_kit_1', 3 ); //modSigns
	inv.AddAnItem( 'weapon_repair_kit_2', 2 ); //modSigns
	inv.AddAnItem( 'armor_repair_kit_1', 3 ); //modSigns
	inv.AddAnItem( 'armor_repair_kit_2', 2 ); //modSigns


	//modSigns: removed quantityMedium = 2;
	quantityMedium = 1; //modSigns
	quantityLow = 1;
	inv.AddAnItem( 'Rune stribog lesser', quantityMedium );
	inv.AddAnItem( 'Rune stribog', quantityLow );
	inv.AddAnItem( 'Rune dazhbog lesser', quantityMedium );
	inv.AddAnItem( 'Rune dazhbog', quantityLow );
	inv.AddAnItem( 'Rune devana lesser', quantityMedium );
	inv.AddAnItem( 'Rune devana', quantityLow );
	inv.AddAnItem( 'Rune zoria lesser', quantityMedium );
	inv.AddAnItem( 'Rune zoria', quantityLow );
	inv.AddAnItem( 'Rune morana lesser', quantityMedium );
	inv.AddAnItem( 'Rune morana', quantityLow );
	inv.AddAnItem( 'Rune triglav lesser', quantityMedium );
	inv.AddAnItem( 'Rune triglav', quantityLow );
	inv.AddAnItem( 'Rune svarog lesser', quantityMedium );
	inv.AddAnItem( 'Rune svarog', quantityLow );
	inv.AddAnItem( 'Rune veles lesser', quantityMedium );
	inv.AddAnItem( 'Rune veles', quantityLow );
	inv.AddAnItem( 'Rune perun lesser', quantityMedium );
	inv.AddAnItem( 'Rune perun', quantityLow );
	inv.AddAnItem( 'Rune elemental lesser', quantityMedium );
	inv.AddAnItem( 'Rune elemental', quantityLow );

	inv.AddAnItem( 'Glyph aard lesser', quantityMedium );
	inv.AddAnItem( 'Glyph aard', quantityLow );
	inv.AddAnItem( 'Glyph axii lesser', quantityMedium );
	inv.AddAnItem( 'Glyph axii', quantityLow );
	inv.AddAnItem( 'Glyph igni lesser', quantityMedium );
	inv.AddAnItem( 'Glyph igni', quantityLow );
	inv.AddAnItem( 'Glyph quen lesser', quantityMedium );
	inv.AddAnItem( 'Glyph quen', quantityLow );
	inv.AddAnItem( 'Glyph yrden lesser', quantityMedium );
	inv.AddAnItem( 'Glyph yrden', quantityLow );


	StandaloneEp2_2();
}

@replaceMethod(W3PlayerWitcher)
function StandaloneEp2_2()
{
	var horseId : SItemUniqueId;
	var ids : array<SItemUniqueId>;
	var ents : array< CJournalBase >;
	var i : int;
	var manager : CWitcherJournalManager;


	//modSigns: removed inv.AddAnItem( 'Cows milk', 20 );
	inv.AddAnItem( 'Cows milk', 5 ); //modSigns
	ids.Clear();
	//modSigns: removed ids = inv.AddAnItem( 'Dumpling', 44 );
	ids = inv.AddAnItem( 'Dumpling', 5 ); //modSigns
	EquipItem( ids[0] );


	inv.AddAnItem( 'Clearing Potion', 2, true, false, false );


	GetHorseManager().RemoveAllItems();

	ids.Clear();
	ids = inv.AddAnItem( 'Horse Bag 2' );
	horseId = GetHorseManager( ).MoveItemToHorse( ids[0] );
	GetHorseManager().EquipItem( horseId );

	ids.Clear();
	ids = inv.AddAnItem( 'Horse Blinder 2' );
	horseId = GetHorseManager().MoveItemToHorse( ids[0] );
	GetHorseManager().EquipItem( horseId );

	ids.Clear();
	ids = inv.AddAnItem( 'Horse Saddle 2' );
	horseId = GetHorseManager().MoveItemToHorse( ids[0] );
	GetHorseManager().EquipItem( horseId );

	manager = theGame.GetJournalManager();


	manager.GetActivatedOfType( 'CJournalCreature', ents );
	for(i=0; i<ents.Size(); i+=1)
	{
		manager.ActivateEntry( ents[i], JS_Inactive, false, true );
	}


	ents.Clear();
	manager.GetActivatedOfType( 'CJournalCharacter', ents );
	for(i=0; i<ents.Size(); i+=1)
	{
		manager.ActivateEntry( ents[i], JS_Inactive, false, true );
	}


	ents.Clear();
	manager.GetActivatedOfType( 'CJournalQuest', ents );
	for(i=0; i<ents.Size(); i+=1)
	{

		if( StrStartsWith( ents[i].baseName, "q60" ) )
			continue;

		manager.ActivateEntry( ents[i], JS_Inactive, false, true );
	}


	manager.ActivateEntryByScriptTag( 'TutorialAard', JS_Active );
	manager.ActivateEntryByScriptTag( 'TutorialAdrenaline', JS_Active );
	manager.ActivateEntryByScriptTag( 'TutorialAxii', JS_Active );
	manager.ActivateEntryByScriptTag( 'TutorialAxiiDialog', JS_Active );
	manager.ActivateEntryByScriptTag( 'TutorialCamera', JS_Active );
	manager.ActivateEntryByScriptTag( 'TutorialCamera_pad', JS_Active );
	manager.ActivateEntryByScriptTag( 'TutorialCiriBlink', JS_Active );
	manager.ActivateEntryByScriptTag( 'TutorialCiriCharge', JS_Active );
	manager.ActivateEntryByScriptTag( 'TutorialCiriStamina', JS_Active );
	manager.ActivateEntryByScriptTag( 'TutorialCounter', JS_Active );
	manager.ActivateEntryByScriptTag( 'TutorialDialogClose', JS_Active );
	manager.ActivateEntryByScriptTag( 'TutorialFallingRoll', JS_Active );
	manager.ActivateEntryByScriptTag( 'TutorialFocus', JS_Active );
	manager.ActivateEntryByScriptTag( 'TutorialFocusClues', JS_Active );
	manager.ActivateEntryByScriptTag( 'TutorialHorseRoad', JS_Active );
	manager.ActivateEntryByScriptTag( 'TutorialHorseSpeed0', JS_Active );
	manager.ActivateEntryByScriptTag( 'TutorialHorseSpeed0_pad', JS_Active );
	manager.ActivateEntryByScriptTag( 'TutorialHorseSpeed1', JS_Active );
	manager.ActivateEntryByScriptTag( 'TutorialHorseSpeed2', JS_Active );
	manager.ActivateEntryByScriptTag( 'TutorialHorseSummon', JS_Active );
	manager.ActivateEntryByScriptTag( 'TutorialHorseSummon_pad', JS_Active );
	manager.ActivateEntryByScriptTag( 'TutorialIgni', JS_Active );
	manager.ActivateEntryByScriptTag( 'TutorialJournalAlternateSings', JS_Active );
	manager.ActivateEntryByScriptTag( 'TutorialJournalBoatDamage', JS_Active );
	manager.ActivateEntryByScriptTag( 'TutorialJournalBoatMount', JS_Active );
	manager.ActivateEntryByScriptTag( 'TutorialJournalBuffs', JS_Active );
	manager.ActivateEntryByScriptTag( 'TutorialJournalCharDevLeveling', JS_Active );
	manager.ActivateEntryByScriptTag( 'TutorialJournalCharDevSkills', JS_Active );
	manager.ActivateEntryByScriptTag( 'TutorialJournalCrafting', JS_Active );
	manager.ActivateEntryByScriptTag( 'TutorialJournalCrossbow', JS_Active );
	manager.ActivateEntryByScriptTag( 'TutorialJournalDialogGwint', JS_Active );
	manager.ActivateEntryByScriptTag( 'TutorialJournalDialogShop', JS_Active );
	manager.ActivateEntryByScriptTag( 'TutorialJournalDive', JS_Active );
	manager.ActivateEntryByScriptTag( 'TutorialJournalDodge', JS_Active );
	manager.ActivateEntryByScriptTag( 'TutorialJournalDodge_pad', JS_Active );
	manager.ActivateEntryByScriptTag( 'TutorialJournalDrawWeapon', JS_Active );
	manager.ActivateEntryByScriptTag( 'TutorialJournalDrawWeapon_pad', JS_Active );
	manager.ActivateEntryByScriptTag( 'TutorialJournalDurability', JS_Active );
	manager.ActivateEntryByScriptTag( 'TutorialJournalExplorations', JS_Active );
	manager.ActivateEntryByScriptTag( 'TutorialJournalExplorations_pad', JS_Active );
	manager.ActivateEntryByScriptTag( 'TutorialJournalFastTravel', JS_Active );
	manager.ActivateEntryByScriptTag( 'TutorialJournalFocusRedObjects', JS_Active );
	manager.ActivateEntryByScriptTag( 'TutorialJournalGasClouds', JS_Active );
	manager.ActivateEntryByScriptTag( 'TutorialJournalHeavyAttacks', JS_Active );
	manager.ActivateEntryByScriptTag( 'TutorialJournalHorse', JS_Active );
	manager.ActivateEntryByScriptTag( 'TutorialJournalHorseStamina', JS_Active );
	manager.ActivateEntryByScriptTag( 'TutorialJournalJump', JS_Active );
	manager.ActivateEntryByScriptTag( 'TutorialJournalLightAttacks', JS_Active );
	manager.ActivateEntryByScriptTag( 'TutorialJournalLightAttacks_pad', JS_Active );
	manager.ActivateEntryByScriptTag( 'TutorialJournalMeditation', JS_Active );
	manager.ActivateEntryByScriptTag( 'TutorialJournalMeditation_pad', JS_Active );
	manager.ActivateEntryByScriptTag( 'TutorialJournalMonsterThreatLevels', JS_Active );
	manager.ActivateEntryByScriptTag( 'TutorialJournalMovement', JS_Active );
	manager.ActivateEntryByScriptTag( 'TutorialJournalMovement_pad', JS_Active );
	manager.ActivateEntryByScriptTag( 'TutorialJournalMutagenIngredient', JS_Active );
	manager.ActivateEntryByScriptTag( 'TutorialJournalMutagenPotion', JS_Active );
	manager.ActivateEntryByScriptTag( 'TutorialJournalOils', JS_Active );
	manager.ActivateEntryByScriptTag( 'TutorialJournalPetards', JS_Active );
	manager.ActivateEntryByScriptTag( 'TutorialJournalPotions', JS_Active );
	manager.ActivateEntryByScriptTag( 'TutorialJournalPotions_pad', JS_Active );
	manager.ActivateEntryByScriptTag( 'TutorialJournalQuestArea', JS_Active );
	manager.ActivateEntryByScriptTag( 'TutorialJournalRadial', JS_Active );
	manager.ActivateEntryByScriptTag( 'TutorialJournalRifts', JS_Active );
	manager.ActivateEntryByScriptTag( 'TutorialJournalRun', JS_Active );
	manager.ActivateEntryByScriptTag( 'TutorialJournalShopDescription', JS_Active );
	manager.ActivateEntryByScriptTag( 'TutorialJournalSignCast', JS_Active );
	manager.ActivateEntryByScriptTag( 'TutorialJournalSignCast_pad', JS_Active );
	manager.ActivateEntryByScriptTag( 'TutorialJournalSpecialAttacks', JS_Active );
	manager.ActivateEntryByScriptTag( 'TutorialJournalStaminaExploration', JS_Active );
	manager.ActivateEntryByScriptTag( 'TutorialJumpHang', JS_Active );
	manager.ActivateEntryByScriptTag( 'TutorialLadder', JS_Active );
	manager.ActivateEntryByScriptTag( 'TutorialLadderMove', JS_Active );
	manager.ActivateEntryByScriptTag( 'TutorialLadderMove_pad', JS_Active );
	manager.ActivateEntryByScriptTag( 'TutorialObjectiveSwitching', JS_Active );
	manager.ActivateEntryByScriptTag( 'TutorialOxygen', JS_Active );
	manager.ActivateEntryByScriptTag( 'TutorialParry', JS_Active );
	manager.ActivateEntryByScriptTag( 'TutorialPOIUncovered', JS_Active );
	manager.ActivateEntryByScriptTag( 'TutorialQuen', JS_Active );
	manager.ActivateEntryByScriptTag( 'TutorialRoll', JS_Active );
	manager.ActivateEntryByScriptTag( 'TutorialRoll_pad', JS_Active );
	manager.ActivateEntryByScriptTag( 'TutorialSpeedPairing', JS_Active );
	manager.ActivateEntryByScriptTag( 'TutorialSprint', JS_Active );
	manager.ActivateEntryByScriptTag( 'TutorialStaminaSigns', JS_Active );
	manager.ActivateEntryByScriptTag( 'TutorialStealing', JS_Active );
	manager.ActivateEntryByScriptTag( 'TutorialSwimmingSpeed', JS_Active );
	manager.ActivateEntryByScriptTag( 'TutorialTimedChoiceDialog', JS_Active );
	manager.ActivateEntryByScriptTag( 'TutorialYrden', JS_Active );

	//modSigns
	inv.AddAnItem( 'Geralt Shirt', 1 );
	//modSigns: removed inv.AddAnItem( 'Thread', 13 );
	//modSigns: removed inv.AddAnItem( 'String', 9 );
	//modSigns: removed inv.AddAnItem( 'Linen', 4 );
	//modSigns: removed inv.AddAnItem( 'Silk', 6 );
	//modSigns: removed inv.AddAnItem( 'Nigredo', 3 );
	inv.AddAnItem( 'Thread', 3 ); //modSigns
	inv.AddAnItem( 'String', 3 ); //modSigns
	inv.AddAnItem( 'Linen', 2 ); //modSigns
	inv.AddAnItem( 'Silk', 1 ); //modSigns
	inv.AddAnItem( 'Nigredo', 1 ); //modSigns
	inv.AddAnItem( 'Albedo', 1 );
	inv.AddAnItem( 'Rubedo', 1 );
	inv.AddAnItem( 'Rebis', 1 );
	//modSigns: removed inv.AddAnItem( 'Dog tallow', 4 );
	//modSigns: removed inv.AddAnItem( 'Lunar shards', 3 );
	//modSigns: removed inv.AddAnItem( 'Quicksilver solution', 5 );
	inv.AddAnItem( 'Dog tallow', 3 ); //modSigns
	inv.AddAnItem( 'Lunar shards', 1 ); //modSigns
	inv.AddAnItem( 'Quicksilver solution', 1 ); //modSigns
	inv.AddAnItem( 'Aether', 1 );
	//modSigns: removed inv.AddAnItem( 'Optima mater', 3 );
	//modSigns: removed inv.AddAnItem( 'Fifth essence', 2 );
	//modSigns: removed inv.AddAnItem( 'Hardened timber', 6 );
	inv.AddAnItem( 'Optima mater', 1 ); //modSigns
	inv.AddAnItem( 'Fifth essence', 1 ); //modSigns
	inv.AddAnItem( 'Hardened timber', 2 ); //modSigns
	inv.AddAnItem( 'Fur square', 1 );
	//modSigns: removed inv.AddAnItem( 'Leather straps', 11 );
	//modSigns: removed inv.AddAnItem( 'Leather squares', 6 );
	//modSigns: removed inv.AddAnItem( 'Leather', 3 );
	//modSigns: removed inv.AddAnItem( 'Hardened leather', 14 );
	//modSigns: removed inv.AddAnItem( 'Chitin scale', 8 );
	//modSigns: removed inv.AddAnItem( 'Draconide leather', 5 );
	inv.AddAnItem( 'Leather straps', 4 ); //modSigns
	inv.AddAnItem( 'Leather squares', 1 ); //modSigns
	inv.AddAnItem( 'Leather', 2 ); //modSigns
	inv.AddAnItem( 'Hardened leather', 2 ); //modSigns
	inv.AddAnItem( 'Chitin scale', 2 ); //modSigns
	inv.AddAnItem( 'Draconide leather', 1 ); //modSigns
	inv.AddAnItem( 'Infused draconide leather', 0 );
	//modSigns: removed inv.AddAnItem( 'Steel ingot', 5 );
	inv.AddAnItem( 'Steel ingot', 2 ); //modSigns
	inv.AddAnItem( 'Dark iron ore', 2 );
	//modSigns: removed inv.AddAnItem( 'Dark iron ingot', 3 );
	//modSigns: removed inv.AddAnItem( 'Dark iron plate', 1 );
	//modSigns: removed inv.AddAnItem( 'Dark steel ingot', 10 );
	//modSigns: removed inv.AddAnItem( 'Dark steel plate', 6 );
	inv.AddAnItem( 'Dark iron ingot', 1 ); //modSigns
	inv.AddAnItem( 'Dark steel ingot', 1 ); //modSigns
	inv.AddAnItem( 'Silver ore', 2 );
	//modSigns: removed inv.AddAnItem( 'Silver ingot', 6 );
	//modSigns: removed inv.AddAnItem( 'Meteorite ore', 3 );
	//modSigns: removed inv.AddAnItem( 'Meteorite ingot', 3 );
	//modSigns: removed inv.AddAnItem( 'Meteorite plate', 2 );
	//modSigns: removed inv.AddAnItem( 'Meteorite silver ingot', 6 );
	//modSigns: removed inv.AddAnItem( 'Meteorite silver plate', 5 );
	//modSigns: removed inv.AddAnItem( 'Orichalcum ingot', 0 );
	//modSigns: removed inv.AddAnItem( 'Orichalcum plate', 1 );
	//modSigns: removed inv.AddAnItem( 'Dwimeryte ingot', 6 );
	//modSigns: removed inv.AddAnItem( 'Dwimeryte plate', 5 );
	//modSigns: removed inv.AddAnItem( 'Dwimeryte enriched ingot', 0 );
	//modSigns: removed inv.AddAnItem( 'Dwimeryte enriched plate', 0 );
	//modSigns: removed inv.AddAnItem( 'Emerald dust', 0 );
	//modSigns: removed inv.AddAnItem( 'Ruby dust', 4 );
	//modSigns: removed inv.AddAnItem( 'Ruby', 2 );
	//modSigns: removed inv.AddAnItem( 'Ruby flawless', 1 );
	//modSigns: removed inv.AddAnItem( 'Sapphire dust', 0 );
	//modSigns: removed inv.AddAnItem( 'Sapphire', 0 );
	//modSigns: removed inv.AddAnItem( 'Monstrous brain', 8 );
	//modSigns: removed inv.AddAnItem( 'Monstrous blood', 14 );
	//modSigns: removed inv.AddAnItem( 'Monstrous bone', 9 );
	//modSigns: removed inv.AddAnItem( 'Monstrous claw', 14 );
	//modSigns: removed inv.AddAnItem( 'Monstrous dust', 9 );
	//modSigns: removed inv.AddAnItem( 'Monstrous ear', 5 );
	//modSigns: removed inv.AddAnItem( 'Monstrous egg', 1 );
	//modSigns: removed inv.AddAnItem( 'Monstrous eye', 10 );
	//modSigns: removed inv.AddAnItem( 'Monstrous essence', 7 );
	//modSigns: removed inv.AddAnItem( 'Monstrous feather', 8 );
	//modSigns: removed inv.AddAnItem( 'Monstrous hair', 12 );
	//modSigns: removed inv.AddAnItem( 'Monstrous heart', 7 );
	//modSigns: removed inv.AddAnItem( 'Monstrous hide', 4 );
	//modSigns: removed inv.AddAnItem( 'Monstrous liver', 5 );
	inv.AddAnItem( 'Silver ingot', 2 ); //modSigns
	inv.AddAnItem( 'Meteorite ore', 2 ); //modSigns
	inv.AddAnItem( 'Meteorite ingot', 1 ); //modSigns
	inv.AddAnItem( 'Meteorite silver ingot', 1 ); //modSigns
	inv.AddAnItem( 'Dwimeryte ingot', 2 ); //modSigns
	inv.AddAnItem( 'Emerald dust', 2 ); //modSigns
	inv.AddAnItem( 'Ruby dust', 2 ); //modSigns
	inv.AddAnItem( 'Ruby', 1 ); //modSigns
	inv.AddAnItem( 'Sapphire dust', 2 ); //modSigns
	inv.AddAnItem( 'Sapphire', 1 ); //modSigns
	inv.AddAnItem( 'Monstrous brain', 4 ); //modSigns
	inv.AddAnItem( 'Monstrous blood', 3 ); //modSigns
	inv.AddAnItem( 'Monstrous bone', 4 ); //modSigns
	inv.AddAnItem( 'Monstrous claw', 3 ); //modSigns
	inv.AddAnItem( 'Monstrous dust', 3 ); //modSigns
	inv.AddAnItem( 'Monstrous ear', 4 ); //modSigns
	inv.AddAnItem( 'Monstrous egg', 2 ); //modSigns
	inv.AddAnItem( 'Monstrous eye', 2 ); //modSigns
	inv.AddAnItem( 'Monstrous essence', 3 ); //modSigns
	inv.AddAnItem( 'Monstrous feather', 4 ); //modSigns
	inv.AddAnItem( 'Monstrous hair', 3 ); //modSigns
	inv.AddAnItem( 'Monstrous heart', 2 ); //modSigns
	inv.AddAnItem( 'Monstrous hide', 3 ); //modSigns
	inv.AddAnItem( 'Monstrous liver', 2 ); //modSigns
	inv.AddAnItem( 'Monstrous plate', 1 );
	//modSigns: removed inv.AddAnItem( 'Monstrous saliva', 6 );
	//modSigns: removed inv.AddAnItem( 'Monstrous stomach', 3 );
	//modSigns: removed inv.AddAnItem( 'Monstrous tongue', 5 );
	//modSigns: removed inv.AddAnItem( 'Monstrous tooth', 9 );
	//modSigns: removed inv.AddAnItem( 'Venom extract', 0 );
	inv.AddAnItem( 'Monstrous saliva', 4 ); //modSigns
	inv.AddAnItem( 'Monstrous stomach', 2 ); //modSigns
	inv.AddAnItem( 'Monstrous tongue', 2 ); //modSigns
	inv.AddAnItem( 'Monstrous tooth', 3 ); //modSigns
	inv.AddAnItem( 'Venom extract', 1 ); //modSigns
	inv.AddAnItem( 'Siren vocal cords', 1 );


	SelectQuickslotItem( EES_RangedWeapon );


	FactsAdd( 'kill_base_tutorials' );


	theGame.GetTutorialSystem().RemoveAllQueuedTutorials();


	//modSigns: removed FactsAdd( 'standalone_ep2' );
	if( FactsQuerySum("standalone_ep2") < 1 ) //modSigns
		FactsAdd("standalone_ep2"); //modSigns
	FactsRemove( "StandAloneEP2" );

	theGame.GetJournalManager().ForceUntrackingQuestForEP1Savegame();
}
