// XP-07: the experience options (docs/features/xp.md; legacy's W3GameParams getters, CR4Game.LoadQuestLevels and
// gmUserSettingsQuestLevels, PX9). The group GMExpOptions in menu/modGhostMode.xml (legacy's ids, labels and its one
// preset, "Default"); its defaults (off, 0) in options/gmOptions.ws, which reacts to a change of "Disable quest levels"
// when the menu closes (GMOnQuestLevelsOptionChanged). XP-01 (xp/questExperience.ws) and XP-04 (xp/killExperience.ws,
// enchantments/npcDeath.ws) read the hooks below at each reward and kill, so the other three options apply at once.

// "Disable quest levels": every reward's level reads 0 (its full experience, no level scaling), and no quest-level table
// is loaded (no level in the journal, the quest tracker or the contracts' tracking rule).
function GMXpNoQuestLevels() : bool
{
	return GMGetOptionBool('GMExpOptions', 'GMNoQuestLevels');
}

// "Fixed experience for quests and combat": no level scaling, no diminishing returns.
function GMXpFixedExp() : bool
{
	return GMGetOptionBool('GMExpOptions', 'GMUseXMLExp');
}

// "Quest experience modifier", -1 .. 1: experience x (1 + modifier), after the 5 XP minimum.
function GMXpQuestExpModifier() : float
{
	return GMGetOptionFloat('GMExpOptions', 'GMQuestExpModifier');
}

// "Combat experience modifier", -1 .. 1: a kill's experience x (1 + modifier), after the 1 XP minimum.
function GMXpCombatExpModifier() : float
{
	return GMGetOptionFloat('GMExpOptions', 'GMMonsterExpModifier');
}

// XP-07: while "Disable quest levels" is on, every call (the game's start, the DLCs' quest mounters) clears the
// quest-level tables and loads none (legacy's).
@replaceMethod(CR4Game)
function LoadQuestLevels( filePath: string ) : void
{
	var index : int;
	if( GMXpNoQuestLevels() )	//modSigns: XP-07 "Disable quest levels"
	{	//modSigns
		questLevelsFilePaths.Clear();	//modSigns
		questLevelsContainer.Clear();	//modSigns
		return;	//modSigns
	}	//modSigns
	index = questLevelsFilePaths.FindFirst( filePath );
	if( index == -1 )
	{
		questLevelsFilePaths.PushBack( filePath );
		questLevelsContainer.PushBack( LoadCSV( filePath ) );
	}
}

// XP-07: "Disable quest levels" changed in the menu (legacy's gmUserSettingsQuestLevels): turned on, the tables are
// cleared; turned off, only the base game's, Hearts of Stone's and Blood and Wine's tables come back. The free DLCs'
// tables (the Wolf School gear's, dlc3's, dlc12's, dlc15's) come back at the next load, a gap kept from legacy (PX9).
@addMethod(CR4Game)
function GMReloadQuestLevels()
{
	LoadQuestLevels( "gameplay\globals\quest_levels.csv" );
	if(GetDLCManager().IsEP1Enabled())
		LoadQuestLevels( "dlc\ep1\data\gameplay\globals\quest_levels.csv" );
	if(GetDLCManager().IsEP2Enabled())
		LoadQuestLevels( "dlc\bob\data\gameplay\globals\quest_levels.csv" );
}
