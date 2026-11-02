// XP slice X2: quest experience, rewards and quest levels (docs/features/xp.md, XP-01, XP-02, XP-03).
//
// In the regression: GMTest_xpquestdata() (the generated table, tests/gmTestsXpQuestData.ws, tools/gen_xp.py): every
// XP-02 reward's experience, level and gold as GetReward reads it, and the level the journal finds for every quest-level
// row legacy changed and 5.x's own mq1060_devils_pit, read as journalQuestMenu.ws reads it.
//
// Not in the regression (it changes Geralt): gmtest_xp01() raises Geralt from his level to 8, 10, 12, 16 and 17 through
// the level manager's path and gives rewards through the game's own GiveReward at each, comparing the experience
// gained with legacy's rule. Run it once per difficulty mode (gmtest_diff_mode in its own exec call before it), from a
// freshly loaded save, and quit or reload without saving.

function GMTestXpReward(rname : name, exp : int, lvl : int, gold : int, out checks : int) : int
{
	var r : SReward;

	checks += 1;
	if(theGame.GetReward(rname, r) && r.experience == exp && r.level == lvl && r.gold == gold)
		return 0;
	LogChannel('GMTest', "FAIL XP data reward " + rname + " reads experience " + r.experience + ", level " + r.level + ", gold " + r.gold
		+ " (expected " + exp + ", " + lvl + ", " + gold + ")");
	return 1;
}

// A quest's level as the journal reads it (CR4JournalQuestMenu: every loaded table, the last row of the name wins;
// none: 0). `found` counts the rows of the name, `agree` is false if two of them have different levels (legacy's base-game
// rows for mh201 and mq2052 repeat dlc3's and dlc12's at the same level). The row name is a string: some contain an
// apostrophe.
function GMTestXpJournalLevel(row : string, out found : int, out agree : bool) : int
{
	var tables : array<C2dArray>;
	var t, j, lvl, v : int;

	tables = theGame.questLevelsContainer;
	found = 0;
	agree = true;
	for(t = 0; t < tables.Size(); t += 1)
		for(j = 0; j < tables[t].GetNumRows(); j += 1)
			if(NameToString(tables[t].GetValueAtAsName(0, j)) == row)
			{
				v = NameToInt(tables[t].GetValueAtAsName(1, j));
				if(found > 0 && v != lvl)
					agree = false;
				lvl = v;
				found += 1;
			}
	return lvl;
}

function GMTestXpQuestLevel(row : string, lvl : int, out checks : int) : int
{
	var got, found : int;
	var agree : bool;

	checks += 1;
	got = GMTestXpJournalLevel(row, found, agree);
	if(got == lvl && agree && (found > 0) == (lvl > 0))
		return 0;
	LogChannel('GMTest', "FAIL XP data quest level " + row + " reads " + got + " (" + found + " rows; expected " + lvl + ")");
	return 1;
}

@addMethod(CR4Game)
function GMTestQuestLevelPaths() : string
{
	var s : string;
	var i : int;

	for(i = 0; i < questLevelsFilePaths.Size(); i += 1)
		s += " " + questLevelsFilePaths[i] + " (" + questLevelsContainer[i].GetNumRows() + " rows)";
	return s;
}

exec function gmtest_xpquestdata()
{
	thePlayer.GMTestCount(true, true);
	GMTest_xpquestdata();
	LogChannel('GMTest', "SUMMARY xpquestdata: " + thePlayer.gmTestPassed + " passed, " + thePlayer.gmTestFailed + " failed");
}

// XP-02, XP-03 as the game reads them. 5.x: 1.32's rewards (finding Ciri 4,000 XP at level 22, Killbill's at level 11)
// and quest levels (the Fistfight Championship 11, mq2040_trial_of_power 16).
function GMTest_xpquestdata()
{
	var f, checks : int;

	LogChannel('GMTest', "INFO XP-03 quest-level tables loaded:" + theGame.GMTestQuestLevelPaths());
	f = GMTestXpRewardsAll(checks);
	GMTestReport(f == 0 && checks == GMTestXpRewardChecks(), "XP-02 data: " + checks + " rewards read with legacy's experience and level and ECON's gold (legacy's)"
		+ " (5.x's new rewards 5.x's, the Killbill branch at level 16); " + f + " differ");
	checks = 0;
	f = GMTestXpQuestLevelsAll(checks);
	GMTestReport(f == 0 && checks == GMTestXpQuestLevelChecks(), "XP-03 data: " + checks + " quest levels as the journal reads them, legacy's"
		+ " (mq2040_trial_of_power none, 5.x's mq1060_devils_pit 15); " + f + " differ");
}

// Geralt up to `lvl` by the level manager's path, at exactly the experience that level starts at. False if he is above it.
function GMTestXpRaiseTo(lvl : int) : bool
{
	var lm : W3LevelManager;
	var need : int;

	lm = GetWitcherPlayer().levelManager;
	while(lm.GetLevel() < lvl)
	{
		need = lm.GetTotalExpForNextLevel() - lm.GetPointsTotal(EExperiencePoint);
		lm.AddPoints(EExperiencePoint, Max(1, need), false);
	}
	return lm.GetLevel() == lvl;
}

// One reward through the game's own path (theGame.GiveReward, as a quest's reward block or a scene's reward function),
// the experience Geralt gains compared with `want`.
function GMTestXpGive(rname : name, want : int, label : string)
{
	var lm : W3LevelManager;
	var r : SReward;
	var before, lvl, got : int;

	lm = GetWitcherPlayer().levelManager;
	theGame.GetReward(rname, r);
	lvl = lm.GetLevel();
	before = lm.GetPointsTotal(EExperiencePoint);
	theGame.GiveReward(rname, thePlayer);
	got = lm.GetPointsTotal(EExperiencePoint) - before;
	GMTestReport(got == want, "XP-01 " + label + rname + " (level " + r.level + ", " + r.experience + " XP) at Geralt " + lvl + " on "
		+ GMTestDiffModeName(theGame.GetDifficultyMode()) + ": +" + got + " XP (legacy " + want + ")");
}

// XP-01 with XP-02's data. Legacy's rule, worked by hand from legacy's OnGiveReward: max(5, round(XP x clamp(1 + 0.16 x
// (quest level - Geralt's), 0, 1.5))). 5.x (at the port's thresholds 6/15): the reward's XP on the two lower modes, x0.9
// and x0.8 on the higher ones, 5% from 6 levels below, Hearts of Stone's q60* scaled alone, half after the story.
exec function gmtest_xp01()
{
	var levels, triss, olgierd, small, crach : array<int>;
	var i, had : int;

	thePlayer.GMTestCount(true, true);
	levels.PushBack(8); levels.PushBack(10); levels.PushBack(12); levels.PushBack(16); levels.PushBack(17);
	// q301_2_helped_triss: level 10, 250 XP (5.x: 250 at Geralt 8 to 12 on "Just the Story!" and "Story and Sword!", 13 at 16 and 17)
	triss.PushBack(330); triss.PushBack(250); triss.PushBack(170); triss.PushBack(10); triss.PushBack(5);
	// q601_olgierd_met (Hearts of Stone): level 32, 200 XP, at the 150% cap below level 29 (5.x: 200, not scaled 6+ levels up)
	olgierd.PushBack(300); olgierd.PushBack(300); olgierd.PushBack(300); olgierd.PushBack(300); olgierd.PushBack(300);
	// mq1045_encounter_02_exp: level 10, 25 XP; at 16 and 17 the 5 XP minimum (5.x: 25, then 1)
	small.PushBack(33); small.PushBack(25); small.PushBack(17); small.PushBack(5); small.PushBack(5);
	// sq106_3_hammond_killed_crach (Killbill's 5.x branch, DX4): level 16, 50 XP (5.x: level 11, 50 XP; 3 at 17)
	crach.PushBack(75); crach.PushBack(75); crach.PushBack(75); crach.PushBack(50); crach.PushBack(42);
	for(i = 0; i < levels.Size(); i += 1)
	{
		if(!GMTestXpRaiseTo(levels[i]))
		{
			GMTestReport(false, "XP-01 Geralt raised to level " + levels[i] + " (he is " + GetWitcherPlayer().GetLevel() + ")");
			break;
		}
		GMTestXpGive('q301_2_helped_triss', triss[i], "");
		GMTestXpGive('q601_olgierd_met', olgierd[i], "Hearts of Stone ");
		GMTestXpGive('mq1045_encounter_02_exp', small[i], "");
		GMTestXpGive('sq106_3_hammond_killed_crach', crach[i], "DX4 ");
		if(levels[i] == 10)
		{
			// the post-story halving (5.x: FactsQuerySum("witcher3_game_finished") > 1, base-game quests at half)
			had = FactsQuerySum("witcher3_game_finished");
			FactsAdd("witcher3_game_finished", 2 - had);
			GMTestXpGive('q301_2_helped_triss', 250, "after the main story (witcher3_game_finished " + FactsQuerySum("witcher3_game_finished") + ") ");
			FactsRemove("witcher3_game_finished");
			if(had > 0)
				FactsAdd("witcher3_game_finished", had);
			GMTestReport(FactsQuerySum("witcher3_game_finished") == had, "XP-01 witcher3_game_finished back to " + had);
		}
	}
	LogChannel('GMTest', "SUMMARY xp01: " + thePlayer.gmTestPassed + " passed, " + thePlayer.gmTestFailed + " failed");
}
