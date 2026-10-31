// DIFF-05 (slice D6): every enemy shows its real level. The level the HUD shows is read through the function
// the HUD calls (GetExperienceDifferenceLevelName: the enemy focus module and the threat list), with the enemy
// made hostile for the read and Geralt's level set by the test override (gmTestsAi06.ws), under soft upscaling
// and with scaling off (options recorded and set back in the same call).
//   gmtest_diff05_a()          spawn the 5.x entities that carry a fake level addon, and one without (frozen, neutral)
//   gmtest_diff05_read()       a later call: the addon zeroed, and the level shown at Geralt 10 and 30, soft and off
//   gmtest_diff05_synth()      the addon, the NG+ addon and the cap set by hand on a bandit: none of them shown
//   gmtest_diff05_ngplus()     a bandit spawned with the NewGamePlus fact set (removed in the same call)
//   gmtest_diff05_b()          remove the samples
// In the regression: GMTest_diff05() (Gerd and the q305 guard, the synthetic case; samples removed at once).

// The 5.x entity files with a fake level addon that Ghost Mode's files do not set to 0 (the scan of every 5.x
// entity, docs/features/diff.md), plus the sergeant (AI-06 made its addon a real level) and a plain bandit.
function GMTestDiff05Path(i : int) : string
{
	switch(i)
	{
		case 0: return "quests\minor_quests\no_mans_land\quest_files\mq1028_courier\characters\mq1028_gerd.w2ent";
		case 1: return "quests\part_1\quest_files\q305_blanka\characters\q305_thug_guard2.w2ent";
		case 2: return "dlc\bob\data\quests\main_quests\quest_files\q702_hunt\characters\q702_mill_worker_1h_blunt.w2ent";
		case 3: return "quests\minor_quests\no_mans_land\quest_files\mq1000_enter_mage\wraith.w2ent";
		case 4: return "quests\minor_quests\no_mans_land\quest_files\mq1060_devils_pit\characters\mq1060_witcher.w2ent";
		case 5: return "quests\secondary_npcs\sergeant.w2ent";
		case 6: return GMTestDummyTemplate("human");
	}
	return "";
}

function GMTestDiff05Label(i : int) : string
{
	switch(i)
	{
		case 0: return "Gerd (mq1028)";
		case 1: return "q305 thug guard";
		case 2: return "q702 mill worker";
		case 3: return "mq1000 wraith";
		case 4: return "Reinald (mq1060)";
		case 5: return "sergeant";
		case 6: return "bandit (no addon)";
	}
	return "?";
}

// The addon each file carries in 5.x (the sergeant's: the port's file, AI-06).
function GMTestDiff05Addon(i : int) : int
{
	switch(i)
	{
		case 0: return 1;
		case 1: return 11;
		case 2: return 2;
		case 3: return 50;
		case 4: return 5;
	}
	return 0;
}

@addMethod(CNewNPC)
function GMTestSetFakeAddon(a : int, ngp : bool)
{
	levelFakeAddon = a;
	newGamePlusFakeLevelAddon = ngp;
}

@addMethod(CNewNPC)
function GMTestNGPFakeAddon() : bool
{
	return newGamePlusFakeLevelAddon;
}

@addField(CR4Player)
var gmTestD05Npcs : array<CNewNPC>;

@addField(CR4Player)
var gmTestD05Idx : array<int>;

@addMethod(CR4Player)
function GMTestD05Add(npc : CNewNPC, i : int)
{
	gmTestD05Npcs.PushBack(npc);
	gmTestD05Idx.PushBack(i);
}

@addMethod(CR4Player)
function GMTestD05Clear()
{
	var i : int;

	for(i = 0; i < gmTestD05Npcs.Size(); i += 1)
		if(gmTestD05Npcs[i])
			gmTestD05Npcs[i].Destroy();
	gmTestD05Npcs.Clear();
	gmTestD05Idx.Clear();
}

function GMTestDiff05Spawn(i : int, distance : float) : CNewNPC
{
	var npc : CNewNPC;

	return GMTestAi15Spawn(GMTestDiff05Path(i), distance, -4 + i * 1.5);	// neutral, frozen
}

// What the HUD shows for this NPC with Geralt at level p: the level name and the coloured level string.
function GMTestDiff05Show(npc : CNewNPC, p : int, out strLevel : string) : string
{
	var lvlName : string;

	GetWitcherPlayer().GMTestSetLevelOverride(p);
	npc.SetAttitude(thePlayer, AIA_Hostile);
	strLevel = "";
	lvlName = npc.GetExperienceDifferenceLevelName(strLevel);
	npc.SetAttitude(thePlayer, AIA_Neutral);
	GetWitcherPlayer().GMTestSetLevelOverride(0);
	return lvlName;
}

// Legacy's rule: the real level, red from 6 levels above Geralt, grey from 6 below, else green.
function GMTestDiff05Want(lvl : int, p : int, out strLevel : string) : string
{
	if(lvl - p >= theGame.params.LEVEL_DIFF_HIGH)
	{
		strLevel = "<font color=\"#FF1919\">" + lvl + "</font>";
		return "highLevel";
	}
	if(lvl - p > -theGame.params.LEVEL_DIFF_HIGH)
	{
		strLevel = "<font color=\"#66FF66\">" + lvl + "</font>";
		return "normalLevel";
	}
	strLevel = "<font color=\"#E6E6E6\">" + lvl + "</font>";
	return "lowLevel";
}

// 5.x's (and the port's before D6) number: level + the file's addon, capped at the maximum level + 5.
function GMTestDiff05Vanilla(lvl : int, addon : int) : int
{
	return Min(lvl + addon, theGame.params.GetPlayerMaxLevel() + 5);
}

// One NPC at Geralt p: the addon zeroed and the HUD's name and string legacy's. Returns ok; s gets the line.
function GMTestDiff05Check(npc : CNewNPC, i : int, p : int, out s : string) : bool
{
	var lvlName, wantName, strLevel, wantStr : string;
	var ok : bool;

	lvlName = GMTestDiff05Show(npc, p, strLevel);
	wantName = GMTestDiff05Want(npc.GetLevel(), p, wantStr);
	ok = npc.levelFakeAddon == 0 && !npc.GMTestNGPFakeAddon() && lvlName == wantName && strLevel == wantStr;
	s = GMTestDiff05Label(i) + " level " + npc.GetLevel() + " (file " + npc.level + "), addon " + npc.levelFakeAddon + ": " + lvlName + " " + strLevel;
	if(!ok)
		s += " (want " + wantName + " " + wantStr + ")";
	if(GMTestDiff05Addon(i) > 0)
		s += " [5.x: " + GMTestDiff05Vanilla(npc.GetLevel(), GMTestDiff05Addon(i)) + "]";
	return ok;
}

exec function gmtest_diff05_a()
{
	var i : int;
	var npc : CNewNPC;

	thePlayer.GMTestD05Clear();
	for(i = 0; i < 7; i += 1)
	{
		npc = GMTestDiff05Spawn(i, 12);
		if(npc)
			thePlayer.GMTestD05Add(npc, i);
		else
			LogChannel('GMTest', "FAIL DIFF-05 " + GMTestDiff05Label(i) + " did not spawn");
	}
	LogChannel('GMTest', "INFO DIFF-05 " + thePlayer.gmTestD05Npcs.Size() + " samples spawned (frozen, neutral); read them in a later call");
}

exec function gmtest_diff05_b()
{
	thePlayer.GMTestD05Clear();
}

exec function gmtest_diff05_read()
{
	var prevOpts : array<string>;
	var t, k, p, j : int;
	var npc : CNewNPC;
	var s : string;

	prevOpts = GMTestDiff04Record();
	thePlayer.GMTestCount(true, true);
	for(k = 0; k < 2; k += 1)
	{
		p = 10 + 20 * k;
		for(t = 0; t <= 3; t += 3)	// off, soft upscaling
		{
			GMTestDiff04Set(t, 0, 0, false, false);
			for(j = 0; j < thePlayer.gmTestD05Npcs.Size(); j += 1)
			{
				npc = thePlayer.gmTestD05Npcs[j];
				GMTestDiff04Recalc(npc, p, true);
				GMTestReport(GMTestDiff05Check(npc, thePlayer.gmTestD05Idx[j], p, s), "DIFF-05 " + GMTestDiff04TypeName(t) + " at Geralt " + p + ": " + s);
			}
		}
	}
	GMTestDiff04Restore(prevOpts);
	GMTestReport(GMTestDiff04Text(GMTestDiff04Record()) == GMTestDiff04Text(prevOpts), "DIFF-05 options restored: " + GMTestDiff04Text(prevOpts));
}

// The addon, the NG+ addon flag and a level above the cap set by hand: the HUD shows the level alone.
function GMTestDiff05Synth(npc : CNewNPC) : bool
{
	var prevOpts : array<string>;
	var lvlName, strLevel, wantStr : string;
	var ok, all : bool;
	var maxL : int;

	prevOpts = GMTestDiff04Record();
	GMTestDiff04Set(0, 0, 0, false, false);
	maxL = theGame.params.GetPlayerMaxLevel();
	all = true;

	npc.GMTestSetBaseLevel(20);
	GMTestDiff04Recalc(npc, 10, true);
	npc.GMTestSetFakeAddon(7, true);
	lvlName = GMTestDiff05Show(npc, 10, strLevel);
	ok = lvlName == GMTestDiff05Want(20, 10, wantStr) && strLevel == wantStr;
	all = all && ok;
	GMTestReport(ok, "DIFF-05 a level-20 bandit with a fake addon of 7 and the NG+ addon flag, Geralt 10: " + lvlName + " " + strLevel
		+ " [5.x: " + (20 + 7 + theGame.params.GetNewGamePlusLevel()) + "]");

	npc.GMTestSetBaseLevel(maxL + 20);
	GMTestDiff04Recalc(npc, 10, true);
	npc.GMTestSetFakeAddon(0, false);
	lvlName = GMTestDiff05Show(npc, 10, strLevel);
	ok = npc.GetLevel() == maxL + 20 && lvlName == GMTestDiff05Want(maxL + 20, 10, wantStr) && strLevel == wantStr;
	all = all && ok;
	GMTestReport(ok, "DIFF-05 a bandit at the maximum level + 20 (" + (maxL + 20) + "), Geralt 10: no cap: " + lvlName + " " + strLevel + " [5.x: " + (maxL + 5) + "]");

	GMTestDiff04Restore(prevOpts);
	return all;
}

exec function gmtest_diff05_synth()
{
	var npc : CNewNPC;

	thePlayer.GMTestCount(true, true);
	npc = GMTestDiff05Spawn(6, 14);
	if(npc)
	{
		GMTestDiff05Synth(npc);
		npc.Destroy();
	}
	else
		GMTestReport(false, "DIFF-05 the bandit spawned");
}

// Test only: the NG+ level as an NG+ start sets it (in memory only; no FinalNewGamePlusLevel fact).
@addMethod(W3GameParams)
function GMTestSetNGPLevelRaw(l : int)
{
	newGamePlusLevel = l;
}

// NG+: a bandit spawned with the NewGamePlus fact and an NG+ level of 30 gets the NG+ level as a real level
// (AI-01), no fake addon, and the HUD shows that level, with scaling off at Geralt 40. The fact and the NG+
// level are set back in the same call.
exec function gmtest_diff05_ngplus()
{
	var prevOpts : array<string>;
	var npc : CNewNPC;
	var had, prevNgp : int;
	var s : string;
	var ok : bool;

	thePlayer.GMTestCount(true, true);
	had = FactsQuerySum("NewGamePlus");
	prevNgp = theGame.params.GetNewGamePlusLevel();
	if(had <= 0)
		FactsAdd("NewGamePlus", 1);
	theGame.params.GMTestSetNGPLevelRaw(30);
	npc = GMTestDiff05Spawn(6, 14);
	if(had <= 0)
		FactsRemove("NewGamePlus");
	if(npc)
	{
		prevOpts = GMTestDiff04Record();
		GMTestDiff04Set(0, 0, 0, false, false);
		GMTestDiff04Recalc(npc, 40, true);
		ok = GMTestDiff05Check(npc, 6, 40, s);
		GMTestDiff04Restore(prevOpts);
		GMTestReport(ok && npc.gmCurrentNGPLevel == 30 && npc.GetLevel() == npc.level + 30,
			"DIFF-05 NG+ (fact set for the spawn, NG+ level 30), scaling off, Geralt 40: NG+ level " + npc.gmCurrentNGPLevel + "; " + s + " [5.x: the same, NG+ levels are real ones since AI-01]");
		npc.Destroy();
	}
	else
		GMTestReport(false, "DIFF-05 NG+ bandit spawned");
	theGame.params.GMTestSetNGPLevelRaw(prevNgp);
	GMTestReport(FactsQuerySum("NewGamePlus") == had && theGame.params.GetNewGamePlusLevel() == prevNgp, "DIFF-05 NewGamePlus fact back to " + had + ", NG+ level back to " + prevNgp
		+ ": " + FactsQuerySum("NewGamePlus") + ", " + theGame.params.GetNewGamePlusLevel());
}

// The regression: Gerd and the q305 guard (no DLC needed) zeroed at spawn and shown at their real level under
// soft upscaling at Geralt 10, a bandit without an addon, and the synthetic addon and cap.
function GMTest_diff05()
{
	var prevOpts : array<string>;
	var npcs : array<CNewNPC>;
	var npc : CNewNPC;
	var i : int;
	var ok : bool;
	var s, all : string;

	prevOpts = GMTestDiff04Record();
	GMTestDiff04Set(3, 0, 0, false, false);
	ok = true;
	for(i = 0; i < 2; i += 1)
	{
		npc = GMTestDiff05Spawn(i, 34);
		if(!npc)
		{
			ok = false;
			all += GMTestDiff05Label(i) + " did not spawn; ";
			continue;
		}
		npcs.PushBack(npc);
		GMTestDiff04Recalc(npc, 10, true);
		ok = GMTestDiff05Check(npc, i, 10, s) && ok;
		all += s + "; ";
	}
	GMTestDiff04Restore(prevOpts);
	GMTestReport(ok, "DIFF-05 real levels on the HUD, soft upscaling at Geralt 10: " + all);
	npc = GMTestDiff05Spawn(6, 36);
	if(npc)
	{
		npcs.PushBack(npc);
		GMTestDiff05Synth(npc);
	}
	else
		GMTestReport(false, "DIFF-05 the bandit spawned");
	GMTestReport(GMTestDiff04Text(GMTestDiff04Record()) == GMTestDiff04Text(prevOpts), "DIFF-05 options restored");
	for(i = 0; i < npcs.Size(); i += 1)
		npcs[i].Destroy();
}
