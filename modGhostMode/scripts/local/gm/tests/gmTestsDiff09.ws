// DIFF-09 (owner, 2026-10-31): "Ciri's sections: difficulty" caps the mode while Ciri is the player. Played with
// vanilla's Ciri() and Geralt() (exec --wait 3000 each) on the test-only slot. State kept across the swap lives on
// CR4Game (CR4Player fields belong to each player object; GetWitcherPlayer() is NULL while Ciri plays).
// Expected modes are written here: "Story and Sword!" caps "Death March!" to "Story and Sword!", "Just the Story!"
// to "Just the Story!", "Same as game" leaves it. The modifiers are +50% health and damage, so every NPC's
// multipliers are the owner's (1 + mode) x 1.5 (F3).
//   gmtest_diff09_a(cap)       as Geralt: "Death March!", the option set to cap (0, 1, 2), +50% / +50%; a friendly
//                              frozen bandit and drowner; their state as Geralt
//   exec --wait 3000 "Ciri()"
//   gmtest_diff09_b()          as Ciri: the spawn mode, the NPCs' difficulty ability, multipliers and Death March
//                              adjustment, Ice Armor's bonus, Ciri's own difficulty abilities; a ghoul spawned
//   gmtest_diff09_check()      the state again (any player), the ghoul included
//   ingamemenu(), gmtest_diff09_menu(v), resume, gmtest_diff09_check(): the option changed through the menu's path
//   exec --wait 3000 "Geralt()"
//   gmtest_diff09_end()        as Geralt: back on "Death March!"; samples removed, options and mode set back
// A load into a Ciri section (the test-only slot only):
//   gmtest_diff09_ls_a()       as Ciri, the option "Same as game": a persistent friendly frozen bandit
//   gmtest_diff09_ls_b()       its state (Death March), then gmtest_diff04_lsave_save(key)
//   gmtest_diff09_setopt(2)    the option to "Just the Story!" in memory only, then game.py load <the slot>
//   gmtest_diff09_ls_c()       as loaded: Ciri the player, the restored bandit on "Just the Story!"
//   exec --wait 3000 "Geralt()", gmtest_diff09_ls_d(): as Geralt on "Death March!", the bandit removed

@addField(CR4Game)
var gmTestD09Npcs : array<CNewNPC>;
@addField(CR4Game)
var gmTestD09Opts : array<string>;
@addField(CR4Game)
var gmTestD09Mode : EDifficultyMode;

@addMethod(CR4Game)
function GMTestD09Set(npcs : array<CNewNPC>, opts : array<string>, mode : EDifficultyMode)
{
	gmTestD09Npcs = npcs;
	gmTestD09Opts = opts;
	gmTestD09Mode = mode;
}

@addMethod(CR4Game)
function GMTestD09Add(npc : CNewNPC)
{
	gmTestD09Npcs.PushBack(npc);
}

function GMTestD09CapName(c : int) : string
{
	switch(c)
	{
		case 0: return "Same as game";
		case 1: return "Story and Sword!";
		case 2: return "Just the Story!";
	}
	return "?" + c;
}

// The expected mode, written out: the option's value read from the config, not through the code under test.
function GMTestD09Want() : EDifficultyMode
{
	var c : string;
	var mode : EDifficultyMode;

	mode = theGame.GetDifficultyMode();
	if(!((W3ReplacerCiri)thePlayer))
		return mode;
	c = theGame.GetInGameConfigWrapper().GetVarValue('GMScalingOptions', 'Virtual_GMCiriDifficulty');
	if(c == "1" && (int)mode > (int)EDM_Medium)
		return EDM_Medium;
	if(c == "2")
		return EDM_Easy;
	return mode;
}

function GMTestD09Who() : string
{
	if((W3ReplacerCiri)thePlayer)
		return "Ciri";
	return "Geralt";
}

// One NPC on the expected mode: that mode's difficulty ability alone, its multipliers x1.5 (one set of steps, the
// maximum health), no level reset pending, Ciri's Death March adjustment only for her on an effective "Death March!".
function GMTestD09Npc(npc : CNewNPC, label : string)
{
	var want : EDifficultyMode;
	var baseHp, baseDmg : float;
	var okM, adj, wantAdj : bool;
	var s : string;

	want = GMTestD09Want();
	GMTestDiffWant(want, baseHp, baseDmg);
	s = GMTestD04bCheckMods(npc, baseHp, baseDmg, okM);
	adj = npc.HasAbility('CiriHardcoreDebuffHuman') || npc.HasAbility('CiriHardcoreDebuffMonster');
	wantAdj = (W3ReplacerCiri)thePlayer && want == EDM_Hardcore;
	GMTestReport(okM && adj == wantAdj && !npc.GMTestLevelPending() && GMTestD04DiffAbls(npc) == GMTestD04DiffAblWant(want),
		"DIFF-09 " + label + " as " + GMTestD09Who() + " (mode " + GMTestDiffModeName(theGame.GetDifficultyMode()) + ", option " + theGame.GetInGameConfigWrapper().GetVarValue('GMScalingOptions', 'Virtual_GMCiriDifficulty')
		+ "): want " + GMTestDiffModeName(want) + ", difficulty abilities " + GMTestD04DiffAbls(npc) + ", Ciri's adjustment " + adj + " (" + wantAdj + "), reset pending " + npc.GMTestLevelPending() + ", level " + npc.currentLevel + "; " + s);
}

function GMTestD09Check()
{
	var i : int;

	GMTestReport(theGame.GetSpawnDifficultyMode() == GMTestD09Want(), "DIFF-09 as " + GMTestD09Who() + ": the spawn mode " + GMTestDiffModeName(theGame.GetSpawnDifficultyMode())
		+ " (want " + GMTestDiffModeName(GMTestD09Want()) + ")");
	for(i = 0; i < theGame.gmTestD09Npcs.Size(); i += 1)
	{
		if(theGame.gmTestD09Npcs[i])
			GMTestD09Npc(theGame.gmTestD09Npcs[i], theGame.gmTestD09Npcs[i].GetDisplayName());
		else
			GMTestReport(false, "DIFF-09 sample " + i + " lost");
	}
}

exec function gmtest_diff09_a(cap : int)
{
	var npcs : array<CNewNPC>;
	var npc : CNewNPC;
	var i : int;

	thePlayer.GMTestCount(true, true);
	theGame.GMTestD09Set(npcs, GMTestDiff04Record(), theGame.GetDifficultyMode());
	GMTestDiffSetMode(EDM_Hardcore);
	theGame.GetInGameConfigWrapper().SetVarValue('GMScalingOptions', 'Virtual_GMCiriDifficulty', IntToString(cap));
	GMTestD04bSetMods(0.5, 0.5, 0, 0);
	npc = GMTestDummySpawn("human", 0, 5, true);
	if(npc) npcs.PushBack(npc);
	npc = GMTestDummySpawn("drowner", 0, 7, true);
	if(npc) npcs.PushBack(npc);
	for(i = 0; i < npcs.Size(); i += 1)
	{
		npcs[i].GMTestFreshLevel();
		npcs[i].RecalcLevel();
	}
	theGame.GMTestD09Set(npcs, theGame.gmTestD09Opts, theGame.gmTestD09Mode);
	GMTestD09Check();
	LogChannel('GMTest', "SUMMARY diff09 a (option " + GMTestD09CapName(cap) + "): " + thePlayer.gmTestPassed + " passed, " + thePlayer.gmTestFailed + " failed; now Ciri()");
}

// Ciri's own abilities that carry a difficulty tag (the per-mode abilities an ability manager swaps).
function GMTestD09CiriDiffAbls() : string
{
	var abls : array<name>;
	var dm : CDefinitionsManagerAccessor;
	var i : int;
	var s : string;

	dm = theGame.GetDefinitionsManager();
	thePlayer.GetCharacterStats().GetAbilities(abls, true);
	for(i = 0; i < abls.Size(); i += 1)
		if(dm.AbilityHasTag(abls[i], theGame.params.DIFFICULTY_TAG_DIFF_ABILITY))
			s += NameToString(abls[i]) + " ";
	return s;
}

// AI-15's Ice Armor bonus on a hit of the player on an NPC holding IceArmor: none on an effective "Just the Story!".
function GMTestD09IceArmor(npc : CNewNPC)
{
	var action : W3DamageAction;
	var had : bool;
	var bonus, want : float;

	had = npc.HasAbility('IceArmor');
	if(!had)
		npc.AddAbility('IceArmor');
	action = new W3DamageAction in theGame.damageMgr;
	action.Initialize(thePlayer, npc, NULL, "gmtest_diff09", EHRT_Light, CPS_AttackPower, false, false, false, false);
	bonus = GMIceArmorResistBonus(action, thePlayer, npc);
	delete action;
	if(!had)
		npc.RemoveAbility('IceArmor');
	want = 0.3;
	if(GMTestD09Want() == EDM_Easy)
		want = 0;
	GMTestReport(AbsF(bonus - want) < 0.0001, "DIFF-09 Ice Armor's bonus as " + GMTestD09Who() + " (want mode " + GMTestDiffModeName(GMTestD09Want()) + "): " + NoTrailZeros(bonus) + " (want " + NoTrailZeros(want) + ")");
}

exec function gmtest_diff09_b()
{
	var npc : CNewNPC;

	thePlayer.GMTestCount(true, true);
	GMTestReport((W3ReplacerCiri)thePlayer && !GetWitcherPlayer(), "DIFF-09 Ciri is the player (GetWitcherPlayer() " + (GetWitcherPlayer() ? "set" : "NULL") + ")");
	GMTestD09Check();
	if(theGame.gmTestD09Npcs.Size() > 0 && theGame.gmTestD09Npcs[0])
		GMTestD09IceArmor(theGame.gmTestD09Npcs[0]);
	LogChannel('GMTest', "INFO DIFF-09 Ciri's abilities with a difficulty tag: '" + GMTestD09CiriDiffAbls() + "'; Ciri_Q205 " + thePlayer.HasAbility('Ciri_Q205') + ", Ciri_Q305 " + thePlayer.HasAbility('Ciri_Q305'));
	npc = GMTestDummySpawn("ghoul", 0, 9, true);
	if(npc)
		theGame.GMTestD09Add(npc);
	LogChannel('GMTest', "SUMMARY diff09 b: " + thePlayer.gmTestPassed + " passed, " + thePlayer.gmTestFailed + " failed; a ghoul spawned near Ciri, read it in a later call");
}

exec function gmtest_diff09_check()
{
	thePlayer.GMTestCount(true, true);
	GMTestD09Check();
	if(theGame.gmTestD09Npcs.Size() > 0 && theGame.gmTestD09Npcs[0])
		GMTestD09IceArmor(theGame.gmTestD09Npcs[0]);
	LogChannel('GMTest', "SUMMARY diff09 check: " + thePlayer.gmTestPassed + " passed, " + thePlayer.gmTestFailed + " failed");
}

// With the options menu open: the option set and the menu's own change event called, as its Flash does.
exec function gmtest_diff09_menu(v : int)
{
	var menu : CR4IngameMenu;

	menu = GMTestDiff04Menu();
	if(!menu)
	{
		LogChannel('GMTest', "FAIL DIFF-09 the options menu is not open");
		return;
	}
	theGame.GetInGameConfigWrapper().SetVarValue('GMScalingOptions', 'Virtual_GMCiriDifficulty', IntToString(v));
	menu.OnOptionValueChanged(theGame.GetInGameConfigWrapper().GetGroupIdx('GMScalingOptions'), 'Virtual_GMCiriDifficulty', IntToString(v));
	LogChannel('GMTest', "INFO DIFF-09 the option set to " + GMTestD09CapName(v) + " through the menu's event; close the menu to apply");
}

// The option in memory only (nothing applied).
exec function gmtest_diff09_setopt(v : int)
{
	theGame.GetInGameConfigWrapper().SetVarValue('GMScalingOptions', 'Virtual_GMCiriDifficulty', IntToString(v));
	LogChannel('GMTest', "INFO DIFF-09 the option set to " + GMTestD09CapName(v) + " in memory");
}

exec function gmtest_diff09_end()
{
	var i : int;
	var npcs : array<CNewNPC>;

	thePlayer.GMTestCount(true, true);
	GMTestReport(!((W3ReplacerCiri)thePlayer), "DIFF-09 Geralt is the player again");
	GMTestD09Check();
	for(i = 0; i < theGame.gmTestD09Npcs.Size(); i += 1)
		if(theGame.gmTestD09Npcs[i])
			theGame.gmTestD09Npcs[i].Destroy();
	if(theGame.gmTestD09Opts.Size() > 0)
		GMTestDiff04Restore(theGame.gmTestD09Opts);
	if(theGame.GetDifficultyMode() != theGame.gmTestD09Mode)
		GMTestDiffSetMode(theGame.gmTestD09Mode);
	GMOnScalingOptionsChanged();
	LogChannel('GMTest', "SUMMARY diff09 end: " + thePlayer.gmTestPassed + " passed, " + thePlayer.gmTestFailed + " failed; samples removed, options " + GMTestDiff04Text(GMTestDiff04Record())
		+ ", mode " + GMTestDiffModeName(theGame.GetDifficultyMode()));
	theGame.GMTestD09Set(npcs, theGame.gmTestD09Opts, theGame.gmTestD09Mode);
}

// ---- a load into a Ciri section ----

exec function gmtest_diff09_ls_a()
{
	var npc : CNewNPC;

	npc = (CNewNPC)theGame.GetEntityByTag('gmtest_d09_ls');
	if(npc)
		npc.Destroy();
	theGame.GetInGameConfigWrapper().SetVarValue('GMScalingOptions', 'Virtual_GMCiriDifficulty', "0");
	GMOnCiriDifficultyChanged();
	GMTestLsaveSpawn(GMTestDummyTemplate("human"), 5, 'gmtest_d09_ls');
	LogChannel('GMTest', "INFO DIFF-09 load check: as " + GMTestD09Who() + ", option Same as game, mode " + GMTestDiffModeName(theGame.GetDifficultyMode()) + "; a persistent bandit spawned, read it in a later call");
}

function GMTestD09LsNpc(label : string)
{
	var npc : CNewNPC;

	npc = (CNewNPC)theGame.GetEntityByTag('gmtest_d09_ls');
	if(npc)
		GMTestD09Npc(npc, "load check, " + label + ": the persistent bandit (restored " + npc.gmTestSpawnRestored + ")");
	else
		GMTestReport(false, "DIFF-09 load check, " + label + ": the persistent bandit not found");
}

exec function gmtest_diff09_ls_b()
{
	thePlayer.GMTestCount(true, true);
	GMTestReport((W3ReplacerCiri)thePlayer, "DIFF-09 load check: Ciri is the player before the save");
	GMTestD09LsNpc("before the save");
	LogChannel('GMTest', "SUMMARY diff09 ls before: " + thePlayer.gmTestPassed + " passed, " + thePlayer.gmTestFailed + " failed");
}

exec function gmtest_diff09_ls_c()
{
	thePlayer.GMTestCount(true, true);
	GMTestReport((W3ReplacerCiri)thePlayer, "DIFF-09 load check: Ciri is the player as loaded");
	GMTestReport(theGame.GetSpawnDifficultyMode() == GMTestD09Want() && GMTestD09Want() == EDM_Easy, "DIFF-09 load check: the spawn mode " + GMTestDiffModeName(theGame.GetSpawnDifficultyMode())
		+ " (want Just the Story!; mode " + GMTestDiffModeName(theGame.GetDifficultyMode()) + ")");
	GMTestD09LsNpc("as loaded");
	LogChannel('GMTest', "SUMMARY diff09 ls after: " + thePlayer.gmTestPassed + " passed, " + thePlayer.gmTestFailed + " failed");
}

exec function gmtest_diff09_ls_d()
{
	var npc : CNewNPC;

	thePlayer.GMTestCount(true, true);
	GMTestReport(!((W3ReplacerCiri)thePlayer), "DIFF-09 load check: Geralt is the player again");
	GMTestD09LsNpc("back as Geralt");
	npc = (CNewNPC)theGame.GetEntityByTag('gmtest_d09_ls');
	if(npc)
		npc.Destroy();
	LogChannel('GMTest', "SUMMARY diff09 ls Geralt: " + thePlayer.gmTestPassed + " passed, " + thePlayer.gmTestFailed + " failed");
}

// ---- in the regression: the cap computed for the current mode for each value, none while Geralt plays ----
function GMTest_diff09()
{
	var prev, s : string;
	var mode, wantM, wantE : EDifficultyMode;
	var ok : bool;
	var c : int;

	prev = theGame.GetInGameConfigWrapper().GetVarValue('GMScalingOptions', 'Virtual_GMCiriDifficulty');
	mode = theGame.GetDifficultyMode();
	wantM = mode;
	if((int)mode > (int)EDM_Medium)
		wantM = EDM_Medium;
	wantE = EDM_Easy;
	ok = true;
	for(c = 0; c <= 2; c += 1)
	{
		theGame.GetInGameConfigWrapper().SetVarValue('GMScalingOptions', 'Virtual_GMCiriDifficulty', IntToString(c));
		ok = ok && theGame.GetSpawnDifficultyMode() == mode;
		if(c == 0) ok = ok && theGame.GMCiriSectionsMode() == mode;
		if(c == 1) ok = ok && theGame.GMCiriSectionsMode() == wantM;
		if(c == 2) ok = ok && theGame.GMCiriSectionsMode() == wantE;
		s += GMTestD09CapName(c) + ": Ciri's " + GMTestDiffModeName(theGame.GMCiriSectionsMode()) + ", spawn " + GMTestDiffModeName(theGame.GetSpawnDifficultyMode()) + "; ";
	}
	theGame.GetInGameConfigWrapper().SetVarValue('GMScalingOptions', 'Virtual_GMCiriDifficulty', prev);
	GMTestReport(ok && theGame.GetInGameConfigWrapper().GetVarValue('GMScalingOptions', 'Virtual_GMCiriDifficulty') == prev,
		"DIFF-09 on " + GMTestDiffModeName(mode) + " as Geralt: " + s + "option restored to '" + prev + "'");
}
