// DIFF-10 (owner, 2026-10-31): the "Interpolated" enemy scaling type: an enemy below Geralt's level gains
// floor((Geralt's level - its level) / 2) levels; at or above his level it keeps its own (porter's assumption).
// Expected levels are the owner's figures written here (Geralt 20, an enemy at 4: 12; Geralt 19: 11), not computed
// by the code under test. Samples are frozen and friendly; Geralt's level is held by AI-06's test override.
//   gmtest_diff10_a()        spawn the samples, then in a later call:
//   gmtest_diff10_levels()   Interpolated at Geralt 19 and 20; with "Do not upscale animals"; with "No additional
//                            levels for guards"; NPCDoNotGainBoost and the banshee summons' ability; options set back
//   gmtest_diff04_b()        remove the samples
// Through the menu's code path: gmtest_diff04_change_a(), ingamemenu(), gmtest_diff04_change_menu(6), resume,
// gmtest_diff04_change_b(); after a relaunch gmtest_diff10_persist() reads the value back.

exec function gmtest_diff10_a()
{
	thePlayer.GMTestDummyClearAll();
	thePlayer.GMTestD04Clear();
	GMTestDiff04Spawn("human", 4, 4, false, "bandit 4");
	GMTestDiff04Spawn("drowner", 4, 5, false, "drowner 4");
	GMTestDiff04Spawn("wolf", 4, 6, false, "wolf 4");
	GMTestDiff04Spawn("wolf", 15, 7, false, "wolf 15");
	GMTestDiff04Spawn("human", 1, 8, true, "guard");
	GMTestDiff04Spawn("human", 25, 9, false, "bandit 25");
	GMTestDiff04Spawn("human", 1, 10, false, "bandit 1");
	LogChannel('GMTest', "INFO DIFF-10 " + thePlayer.gmTestD04Npcs.Size() + " samples spawned (frozen, friendly); read them in a later call");
}

// The owner's figures per sample label at Geralt p, by option.
function GMTestDiff10Want(label : string, p : int, noAnimal : bool, noGuard : bool) : int
{
	if(label == "bandit 4" || label == "drowner 4")
	{
		if(p == 20) return 12;	// 16 below: +8
		return 11;		// 15 below: +7
	}
	if(label == "wolf 4")
	{
		if(noAnimal) return 4;	// not upscaled, below half Geralt's level
		if(p == 20) return 12;
		return 11;
	}
	if(label == "wolf 15")
	{
		if(noAnimal) return p / 2;	// above half Geralt's level: lowered to it (DD4)
		if(p == 20) return 17;	// 5 below: +2
		return 17;		// 4 below: +2
	}
	if(label == "guard")
	{
		if(noGuard) return p;	// at Geralt's level
		return p + 16;
	}
	if(label == "bandit 25")
		return 25;		// above Geralt: its own
	if(label == "bandit 1")
	{
		if(p == 20) return 10;	// 19 below: +9
		return 10;		// 18 below: +9
	}
	return -1;
}

function GMTestDiff10Case(p : int, noAnimal : bool, noGuard : bool)
{
	var i, want : int;
	var npc : CNewNPC;
	var ok, all : bool;
	var s : string;

	GMTestDiff04Set(6, 0, 0, noGuard, noAnimal);
	all = thePlayer.gmTestD04Npcs.Size() == 7;
	for(i = 0; i < thePlayer.gmTestD04Npcs.Size(); i += 1)
	{
		npc = thePlayer.gmTestD04Npcs[i];
		npc.GMTestSetBaseLevel(thePlayer.gmTestD04Base[i]);
		GMTestDiff04Recalc(npc, p, true);
		want = GMTestDiff10Want(thePlayer.gmTestD04Label[i], p, noAnimal, noGuard);
		ok = npc.currentLevel == want && GMTestDiff04Abls(npc)
			&& want == GMTestDiff04Expected(npc, thePlayer.gmTestD04Base[i], p, 6, noAnimal, noGuard);	// the figures agree with the rule
		all = all && ok;
		s += thePlayer.gmTestD04Label[i] + " " + npc.currentLevel + GMTestD04If(!ok, " (want " + want + ", rule " + GMTestDiff04Expected(npc, thePlayer.gmTestD04Base[i], p, 6, noAnimal, noGuard)
			+ ", DisplayedLevelAbl " + npc.GetAbilityCount('DisplayedLevelAbl') + ")") + "; ";
	}
	GMTestReport(all, "DIFF-10 Interpolated at Geralt " + p + GMTestD04If(noAnimal, ", animals not upscaled") + GMTestD04If(noGuard, ", no guard levels") + ": " + s);
}

// An ability that stops scaling (NPCDoNotGainBoost, banshee_summons) on the level-4 bandit: it keeps its level 4.
function GMTestDiff10Stop(abl : name)
{
	var npc : CNewNPC;
	var had : bool;

	npc = thePlayer.gmTestD04Npcs[0];
	GMTestDiff04Set(6, 0, 0, false, false);
	had = npc.HasAbility(abl);
	if(!had)
		npc.AddAbility(abl);
	npc.GMTestSetBaseLevel(4);
	GMTestDiff04Recalc(npc, 20, true);
	GMTestReport(npc.HasAbility(abl) && npc.currentLevel == 4, "DIFF-10 Interpolated at Geralt 20, a level-4 bandit with " + NameToString(abl) + " (held " + npc.HasAbility(abl) + "): level " + npc.currentLevel + " (want 4)");
	if(!had)
		npc.RemoveAbility(abl);
	npc.GMTestSetBaseLevel(4);
	GMTestDiff04Recalc(npc, 20, true);
}

exec function gmtest_diff10_levels()
{
	var prevOpts : array<string>;

	prevOpts = GMTestDiff04Record();
	thePlayer.GMTestCount(true, true);
	GMTestDiff10Case(20, false, false);
	GMTestDiff10Case(19, false, false);
	GMTestDiff10Case(20, true, false);
	GMTestDiff10Case(19, true, false);
	GMTestDiff10Case(20, false, true);
	GMTestDiff10Case(19, false, true);
	GMTestDiff10Stop('NPCDoNotGainBoost');
	GMTestDiff10Stop('banshee_summons');
	GMTestDiff04Restore(prevOpts);
	GMTestReport(GMTestDiff04Text(GMTestDiff04Record()) == GMTestDiff04Text(prevOpts), "DIFF-10 options restored: " + GMTestDiff04Text(prevOpts));
	LogChannel('GMTest', "SUMMARY diff10 levels: " + thePlayer.gmTestPassed + " passed, " + thePlayer.gmTestFailed + " failed");
}

// After a relaunch: the value the menu saved is read back (the virtual option and the getter).
exec function gmtest_diff10_persist()
{
	thePlayer.GMTestCount(true, true);
	GMTestReport(GMGetEnemyScalingOption() == 6 && theGame.GetInGameConfigWrapper().GetVarValue('GMScalingOptions', 'Virtual_GMScaling') == "6",
		"DIFF-10 the scaling type after a relaunch: '" + theGame.GetInGameConfigWrapper().GetVarValue('GMScalingOptions', 'Virtual_GMScaling') + "', read as " + GMTestDiff04TypeName(GMGetEnemyScalingOption()));
	LogChannel('GMTest', "SUMMARY diff10 persist: " + thePlayer.gmTestPassed + " passed, " + thePlayer.gmTestFailed + " failed");
}
