// DIFF-04 and DIFF-06: the owner's decisions on the DIFF audit's F1 to F3 (2026-10-31). Expected values are the
// owner's figures, written here, not computed by the code under test.
// F3, how the modifiers combine: (1 + mode) x (1 + enemy + boss), health at least x0.01, damage at least x0.
//   gmtest_diff04b_a()          spawn D5b's four samples (a bandit, a drowner, a wolf, mh102's arachas with the boss
//                               bar from its spawn), then in a later call:
//   gmtest_diff04c_f3()         each mode in turn through the game's path with a setting of the modifiers: the
//                               mode change asks for a re-level, which gives the owner's multipliers; mode and
//                               options set back
// F2, the boss modifiers follow the boss bar:
//   gmtest_diff04c_f2_a()       a hostile frozen bandit of level 30 at Geralt 10 (Deadly), the "Hardcore" values
//   gmtest_diff04c_f2_bar(true), then gmtest_diff04c_f2_check(true): the boss bar shown for it after its spawn
//                               through the quest's path (RunEvent_BossFocusModule_ShowBossIndicator,
//                               ShowBossFightIndicator's body); gmtest_diff04c_f2_bar(false), _check(false): hidden
//   gmtest_diff04c_f2_b()       the quest function HealthBarVisiblityQuest both ways; all set back
//                               (each step: its modifiers, its Deadly ability and its share of health)
// F1, a player change re-levels every NPC near the new player (on the test-only slot, Geralt at level 20):
//   gmtest_diff04c_f1_a(dm)     the "Hardcore" values (Upscale, progressive 10 and 5, +50%, +50% for bosses), on
//                               "Death March!" when dm; a friendly frozen bandit and drowner at Geralt's level
//   exec --wait 3000 "Ciri()"
//   gmtest_diff04c_f1_b()       as Ciri: each at its own level (no scaling for her), its per-level count, the
//                               mode's modifiers, her Death March adjustment on "Death March!"
//   exec --wait 3000 "Geralt()"
//   gmtest_diff04c_f1_c()       as Geralt: back at his level 20 with 24 per-level bonuses, no adjustment; then the
//                               samples removed, options and mode set back

// ---- F3 ----

// One setting on every sample after a change to mode: [bandit, drowner, wolf] health and damage, and the boss's.
function GMTestD04cF3Case(mode : EDifficultyMode, h : float, d : float, bh : float, bd : float, wH : float, wD : float, wBH : float, wBD : float)
{
	var i : int;
	var npc : CNewNPC;
	var hp, dmg, maxH, predicted, wantH, wantD : float;
	var ok, all, pending, boss : bool;
	var s : string;

	GMTestD04bSetMods(h, d, bh, bd);
	GMTestDiffSetMode(mode);
	all = thePlayer.gmTestD04Npcs.Size() >= 4;
	for(i = 0; i < thePlayer.gmTestD04Npcs.Size(); i += 1)
	{
		npc = thePlayer.gmTestD04Npcs[i];
		pending = npc.GMTestLevelPending();	// the mode change's re-level (vanilla's OnGameDifficultyChanged)
		GMTestDiff04Recalc(npc, 10, false);	// what its timer runs
		boss = GMTestD04bBoss(npc);
		wantH = wH; wantD = wD;
		if(boss) { wantH = wBH; wantD = wBD; }
		GMTestD04bRead(npc, hp, dmg);
		ok = pending && AbsF(hp - wantH) < 0.002 && AbsF(dmg - wantD) < 0.002 && GMTestD04bMaxHealthOk(npc, hp, maxH, predicted) && npc.IsAlive() && npc.GetHealth() > 0;
		all = all && ok;
		s += thePlayer.gmTestD04Label[i] + GMTestD04If(boss, " (boss)") + " x" + NoTrailZeros(hp) + " / x" + NoTrailZeros(dmg) + " (want " + NoTrailZeros(wantH) + " / " + NoTrailZeros(wantD)
			+ GMTestD04If(!pending, ", no re-level asked by the mode change") + ", health " + NoTrailZeros(npc.GetHealth()) + ", maximum health " + NoTrailZeros(maxH) + " of " + NoTrailZeros(predicted) + "); ";
	}
	GMTestReport(all, "DIFF-04 F3 " + GMTestDiffModeName(mode) + ", health " + NoTrailZeros(h) + ", damage " + NoTrailZeros(d) + ", bosses " + NoTrailZeros(bh) + " / " + NoTrailZeros(bd) + ": " + s);
}

exec function gmtest_diff04c_f3()
{
	var prevOpts : array<string>;
	var mode : EDifficultyMode;
	var i : int;

	prevOpts = GMTestDiff04Record();
	mode = theGame.GetDifficultyMode();
	thePlayer.GMTestCount(true, true);
	GMTestDiff04Set(0, 0, 0, false, false);
	GMTestD04bSetProg(false, 0, 0);
	// mode, enemy health, damage, boss health, damage; want: health, damage, the boss's health, damage
	// no mode twice in a row: each case's mode change asks for its own re-level
	GMTestD04cF3Case(EDM_Hardcore, 0.5, 0.5, 0.5, 0.5, 3.75, 5.25, 5, 7);	// Death March + the Hardcore preset
	GMTestD04cF3Case(EDM_Medium, 0.5, 0, 0, 0, 1.5, 1, 1.5, 1);
	GMTestD04cF3Case(EDM_Easy, -0.5, 0, 0, 0, 0.25, 0.75, 0.25, 0.75);
	GMTestD04cF3Case(EDM_Hard, -1, -1, 0, 0, 0.01, 0, 0.01, 0);	// the floors
	GMTestD04cF3Case(EDM_Easy, -1, -1, 0, 0, 0.01, 0, 0.01, 0);
	GMTestD04cF3Case(EDM_Hardcore, -0.5, -0.5, 0, 0, 1.25, 1.75, 1.25, 1.75);
	GMTestD04cF3Case(EDM_Easy, 0, 0, -0.5, -1, 0.5, 0.75, 0.25, 0);	// the boss modifiers alone
	GMTestD04cF3Case(EDM_Hard, 5, 5, 0, 0, 12, 12, 12, 12);
	GMTestD04cF3Case(EDM_Easy, 0, 0, 0, 0, 0.5, 0.75, 0.5, 0.75);
	GMTestDiff04Restore(prevOpts);
	GMTestDiffSetMode(mode);
	for(i = 0; i < thePlayer.gmTestD04Npcs.Size(); i += 1)
		GMTestDiff04Recalc(thePlayer.gmTestD04Npcs[i], 10, true);
	GMTestReport(GMTestDiff04Text(GMTestDiff04Record()) == GMTestDiff04Text(prevOpts) && theGame.GetDifficultyMode() == mode,
		"DIFF-04 F3 options and mode restored: " + GMTestDiff04Text(prevOpts) + ", " + GMTestDiffModeName(mode));
	LogChannel('GMTest', "SUMMARY diff04c f3: " + thePlayer.gmTestPassed + " passed, " + thePlayer.gmTestFailed + " failed");
}

// ---- F2 ----

function GMTestD04cDeadly(npc : CNewNPC) : bool
{
	return npc.HasAbility(theGame.params.ENEMY_BONUS_DEADLY);
}

// The bandit's state: boss tag, multipliers (the mode's x1.5, or x2 as a boss), Deadly (not as a boss), its share
// of health kept at 0.5, level 30.
function GMTestD04cF2Check(npc : CNewNPC, baseHp : float, baseDmg : float, wantBoss : bool, label : string)
{
	var hp, dmg, perc, maxH, predicted, f : float;
	var boss, deadly, ok : bool;

	boss = GMTestD04bBoss(npc);
	deadly = GMTestD04cDeadly(npc);
	GMTestD04bRead(npc, hp, dmg);
	perc = npc.GetStatPercents(BCS_Vitality);
	f = 1.5;
	if(wantBoss)
		f = 2;
	ok = boss == wantBoss && deadly == !wantBoss && AbsF(hp - baseHp * f) < 0.002 && AbsF(dmg - baseDmg * f) < 0.002 && AbsF(perc - 0.5) < 0.01
		&& npc.currentLevel == 30 && GMTestD04bMaxHealthOk(npc, hp, maxH, predicted);
	GMTestReport(ok, "DIFF-04 F2 " + label + ": boss tag " + boss + " (" + wantBoss + "), Deadly " + deadly + " (" + !wantBoss + "), health x" + NoTrailZeros(hp) + " (" + NoTrailZeros(baseHp * f)
		+ "), damage x" + NoTrailZeros(dmg) + " (" + NoTrailZeros(baseDmg * f) + "), health " + NoTrailZeros(perc * 100) + "% of " + NoTrailZeros(maxH) + " (50%), level " + npc.currentLevel + " (30)"
		+ ", health steps " + GMTestD04bStepText(npc, true) + ", damage steps " + GMTestD04bStepText(npc, false));
}

@addField(CR4Player)
var gmTestD04cBoss : CNewNPC;
@addField(CR4Player)
var gmTestD04cBossOpts : array<string>;

@addMethod(CR4Player)
function GMTestD04cSetBoss(npc : CNewNPC, opts : array<string>)
{
	gmTestD04cBoss = npc;
	gmTestD04cBossOpts = opts;
}

function GMTestD04cF2Now(wantBoss : bool, label : string)
{
	var baseHp, baseDmg : float;

	GMTestDiffWant(theGame.GetSpawnDifficultyMode(), baseHp, baseDmg);
	if(thePlayer.gmTestD04cBoss)
		GMTestD04cF2Check(thePlayer.gmTestD04cBoss, baseHp, baseDmg, wantBoss, label);
	else
		GMTestReport(false, "DIFF-04 F2 the bandit is missing (gmtest_diff04c_f2_a first)");
}

// The bandit and the options; its state before any bar.
exec function gmtest_diff04c_f2_a()
{
	var npc : CNewNPC;
	var w : W3PlayerWitcher;

	thePlayer.GMTestCount(true, true);
	w = GetWitcherPlayer();
	thePlayer.GMTestD04cSetBoss(NULL, GMTestDiff04Record());
	// no other boss bar up: the module keeps the NPC it shows (a contract monster's own bar, D5b's arachas sample)
	thePlayer.GMTestDummyClearAll();
	theGame.GetGuiManager().GetHudEventController().RunEvent_BossFocusModule_ShowBossIndicator(false, '');
	GMTestDiff04Set(0, 0, 0, false, false);
	GMTestD04bSetProg(false, 0, 0);
	GMTestD04bSetMods(0.5, 0.5, 0.5, 0.5);
	npc = GMTestDummySpawn("human", 0, 5, false);
	if(!npc)
		return;
	npc.AddTag('gmtest_d04c_boss');
	thePlayer.GMTestD04cSetBoss(npc, thePlayer.gmTestD04cBossOpts);
	w.SetImmortalityMode(AIM_Immortal, AIC_Default, true);
	w.GMTestSetLevelOverride(10);	// held across the boss bar's recomputes, cleared by gmtest_diff04c_f2_b()
	npc.GMTestSetBaseLevel(30);
	npc.RecalcLevel();
	npc.ForceSetStat(BCS_Vitality, npc.GetStatMax(BCS_Vitality) * 0.5);
	GMTestD04cF2Now(false, "a hostile bandit of level 30 at Geralt 10, before the bar");
}

// The boss bar shown (show) or hidden through the quest's path, as ShowBossFightIndicator does; read in a later call.
exec function gmtest_diff04c_f2_bar(show : bool)
{
	if(show)
		theGame.GetGuiManager().GetHudEventController().RunEvent_BossFocusModule_ShowBossIndicator(true, 'gmtest_d04c_boss');
	else
		theGame.GetGuiManager().GetHudEventController().RunEvent_BossFocusModule_ShowBossIndicator(false, '');
	LogChannel('GMTest', "INFO DIFF-04 F2 boss bar " + show + " requested (ShowBossFightIndicator's body)");
}

exec function gmtest_diff04c_f2_check(wantBoss : bool)
{
	thePlayer.GMTestCount(true, true);
	if(wantBoss)
	{
		GMTestD04cF2Now(true, "the boss bar shown for it after its spawn (ShowBossFightIndicator's path)");
		thePlayer.gmTestD04cBoss.RecalcLevel();	// the fight's start: no second set
		GMTestD04cF2Now(true, "then its fight's start (RecalcLevel)");
	}
	else
		GMTestD04cF2Now(false, "the boss bar hidden");
	LogChannel('GMTest', "SUMMARY diff04c f2 bar " + wantBoss + ": " + thePlayer.gmTestPassed + " passed, " + thePlayer.gmTestFailed + " failed");
}

// The quest function both ways, then everything set back.
exec function gmtest_diff04c_f2_b()
{
	var w : W3PlayerWitcher;

	thePlayer.GMTestCount(true, true);
	w = GetWitcherPlayer();
	HealthBarVisiblityQuest('gmtest_d04c_boss', false);
	GMTestD04cF2Now(true, "the quest function HealthBarVisiblityQuest tagging it");
	HealthBarVisiblityQuest('gmtest_d04c_boss', true);
	GMTestD04cF2Now(false, "HealthBarVisiblityQuest untagging it");
	w.GMTestSetLevelOverride(0);
	w.SetImmortalityMode(AIM_None, AIC_Default, true);
	GMTestDiff04Restore(thePlayer.gmTestD04cBossOpts);
	if(thePlayer.gmTestD04cBoss)
		thePlayer.gmTestD04cBoss.Destroy();
	GMTestReport(GMTestDiff04Text(GMTestDiff04Record()) == GMTestDiff04Text(thePlayer.gmTestD04cBossOpts), "DIFF-04 F2 options restored: " + GMTestDiff04Text(thePlayer.gmTestD04cBossOpts));
	thePlayer.GMTestD04cSetBoss(NULL, thePlayer.gmTestD04cBossOpts);
	LogChannel('GMTest', "SUMMARY diff04c f2 quest function: " + thePlayer.gmTestPassed + " passed, " + thePlayer.gmTestFailed + " failed");
}

// ---- F1 ----

@addField(CR4Game)
var gmTestD04cNpcs : array<CNewNPC>;
@addField(CR4Game)
var gmTestD04cOpts : array<string>;
@addField(CR4Game)
var gmTestD04cMode : EDifficultyMode;

@addMethod(CR4Game)
function GMTestD04cSet(npcs : array<CNewNPC>, opts : array<string>, mode : EDifficultyMode)
{
	gmTestD04cNpcs = npcs;
	gmTestD04cOpts = opts;
	gmTestD04cMode = mode;
}

exec function gmtest_diff04c_f1_a(dm : bool)
{
	var npcs : array<CNewNPC>;
	var npc : CNewNPC;
	var i : int;
	var s : string;

	theGame.GMTestD04cSet(npcs, GMTestDiff04Record(), theGame.GetDifficultyMode());
	if(dm)
		GMTestDiffSetMode(EDM_Hardcore);
	GMTestDiff04Set(1, 0, 0, false, false);
	GMTestD04bSetProg(true, 10, 5);
	GMTestD04bSetMods(0.5, 0.5, 0.5, 0.5);
	npc = GMTestDummySpawn("human", 0, 5, true);
	if(npc) npcs.PushBack(npc);
	npc = GMTestDummySpawn("drowner", 0, 7, true);
	if(npc) npcs.PushBack(npc);
	for(i = 0; i < npcs.Size(); i += 1)
	{
		npcs[i].GMTestFreshLevel();
		npcs[i].RecalcLevel();
		s += npcs[i].GetDisplayName() + " entity level " + npcs[i].GMTestEntityLevel() + ", level " + npcs[i].currentLevel + "; ";
	}
	theGame.GMTestD04cSet(npcs, theGame.gmTestD04cOpts, theGame.gmTestD04cMode);
	LogChannel('GMTest', "INFO DIFF-06 F1: the Hardcore values, mode " + GMTestDiffModeName(theGame.GetDifficultyMode()) + ", Geralt " + thePlayer.GetLevel() + "; " + s + "now Ciri()");
}

// Every sample: re-levelled since the change (no reset pending, computed at the new player's level), at want
// (its own level for Ciri, Geralt's for him), the per-level count, the mode's difficulty ability and the
// modifiers under it, Ciri's Death March adjustment only for her on "Death March!".
function GMTestD04cF1Check(asCiri : bool)
{
	var i, want : int;
	var npc : CNewNPC;
	var baseHp, baseDmg : float;
	var okM, ok, wantAdj, adj, isCiri : bool;
	var s, who : string;

	thePlayer.GMTestCount(true, true);
	who = "Geralt";
	if((W3ReplacerCiri)thePlayer)
	{
		who = "Ciri";
		isCiri = true;
	}
	GMTestReport(asCiri == isCiri, "DIFF-06 F1 the player is " + who);
	GMTestDiffWant(theGame.GetSpawnDifficultyMode(), baseHp, baseDmg);
	wantAdj = asCiri && theGame.GetDifficultyMode() == EDM_Hardcore;
	for(i = 0; i < theGame.gmTestD04cNpcs.Size(); i += 1)
	{
		npc = theGame.gmTestD04cNpcs[i];
		if(!npc)
		{
			GMTestReport(false, "DIFF-06 F1 sample " + i + " lost");
			continue;
		}
		want = 20;
		if(asCiri)
			want = npc.GMTestEntityLevel();
		adj = npc.HasAbility('CiriHardcoreDebuffHuman') || npc.HasAbility('CiriHardcoreDebuffMonster');
		s = GMTestD04bCheckMods(npc, baseHp, baseDmg, okM);
		ok = okM && !npc.GMTestLevelPending() && npc.currentLevel == want && GMTestD04bLevelAbls(npc) == GMTestD04bWantAbls(want) && adj == wantAdj
			&& GMTestD04DiffAbls(npc) == GMTestD04DiffAblWant(theGame.GetDifficultyMode());
		GMTestReport(ok, "DIFF-06 F1 as " + who + " on " + GMTestDiffModeName(theGame.GetDifficultyMode()) + ": " + npc.GetDisplayName() + " level " + npc.currentLevel + " (want " + want + "), per-level "
			+ GMTestD04bLevelAbls(npc) + " (" + GMTestD04bWantAbls(want) + "), reset pending " + npc.GMTestLevelPending() + ", Ciri's adjustment " + adj + " (" + wantAdj + "), difficulty abilities "
			+ GMTestD04DiffAbls(npc) + "; " + s);
	}
	LogChannel('GMTest', "SUMMARY diff06 f1 as " + who + ": " + thePlayer.gmTestPassed + " passed, " + thePlayer.gmTestFailed + " failed");
}

exec function gmtest_diff04c_f1_b()
{
	GMTestD04cF1Check(true);
}

exec function gmtest_diff04c_f1_c()
{
	var i : int;
	var npcs : array<CNewNPC>;

	GMTestD04cF1Check(false);
	for(i = 0; i < theGame.gmTestD04cNpcs.Size(); i += 1)
		if(theGame.gmTestD04cNpcs[i])
			theGame.gmTestD04cNpcs[i].Destroy();
	if(theGame.gmTestD04cOpts.Size() > 0)
		GMTestDiff04Restore(theGame.gmTestD04cOpts);
	if(theGame.GetDifficultyMode() != theGame.gmTestD04cMode)
		GMTestDiffSetMode(theGame.gmTestD04cMode);
	GMOnScalingOptionsChanged();
	LogChannel('GMTest', "INFO DIFF-06 F1: samples removed, options " + GMTestDiff04Text(GMTestDiff04Record()) + ", mode " + GMTestDiffModeName(theGame.GetDifficultyMode()));
	theGame.GMTestD04cSet(npcs, theGame.gmTestD04cOpts, theGame.gmTestD04cMode);
}
