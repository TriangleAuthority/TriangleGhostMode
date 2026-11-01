// XP-07 checks (slice X4; docs/features/xp.md): the experience options through the options menu's own code path.
//
// In the regression: GMTest_xp07() (the labels, the defaults, the getters following the options; options set in
// memory and set back).
//
// Not in the regression (they change Geralt, spawn enemies and change the options): from a freshly loaded test save,
// then quit without saving. Each case k (GMTestXp07Case):
//   gmtest_xp07_start()      records the four options and the kill counts, holds Geralt at level 12 (test override)
//   gmtest_xp07_spawn()      a drowner, a griffin and a wolf spawned frozen and friendly behind Geralt
//   ingamemenu()             the pause menu open
//   gmtest_xp07_set(k)       case k's values set and the menu's own OnOptionValueChanged called for each option that
//                            changes, as its Flash does (gmtest_xp07_preset(): the "Default" preset by OnPresetApplied)
//   game.py resume           the menu closed: SaveChangedSettings, Ghost Mode's change hooks, the settings saved
//   gmtest_xp07_check(k, j)  the options read back; three rewards through GiveReward and three scripted kills through
//                            the damage manager compared with legacy's rules worked by hand; the journal's quest levels
//                            (j: 0 every table loaded, 1 none, 2 the base game's, Hearts of Stone's and Blood and Wine's
//                            only: legacy's gap)
//   gmtest_xp07_unset()      the four options cleared in memory: they read legacy's defaults (off, 0); then set back
//   gmtest_xp07_end()        Geralt's level override off, the kill counts back, the samples removed
// The options are left as the last case set them (saved by the menu): put them back with case 0 through the menu, or
// restore the settings file with the game closed.

// ---- the cases ----
// Values: "Disable quest levels", "Fixed experience", quest modifier, combat modifier.
function GMTestXp07Case(k : int, out noQL : bool, out fixedExp : bool, out qm : float, out cm : float) : bool
{
	noQL = false; fixedExp = false; qm = 0; cm = 0;
	switch(k)
	{
		case 0: return true;							// the defaults
		case 1: qm = -1; cm = -1; return true;		// -100%
		case 2: qm = -0.5; cm = -0.5; return true;	// -50%
		case 3: qm = 0.5; cm = 0.5; return true;		// +50%
		case 4: qm = 1; cm = 1; return true;			// +100%
		case 5: fixedExp = true; return true;			// fixed experience
		case 6: noQL = true; return true;				// quest levels disabled
		case 7: return true;							// quest levels enabled again (the gap)
		case 8: noQL = true; fixedExp = true; qm = 0.2; cm = -0.4; return true;	// everything at once (the relaunch)
	}
	return false;
}

function GMTestXp07Bool(b : bool) : string
{
	if(b)
		return "true";
	return "false";
}

function GMTestXp07Cfg(option : name) : string
{
	return theGame.GetInGameConfigWrapper().GetVarValue('GMExpOptions', option);
}

function GMTestXp07Text() : string
{
	return "noQuestLevels='" + GMTestXp07Cfg('GMNoQuestLevels') + "' fixed='" + GMTestXp07Cfg('GMUseXMLExp') + "' quest='" + GMTestXp07Cfg('GMQuestExpModifier')
		+ "' combat='" + GMTestXp07Cfg('GMMonsterExpModifier') + "'";
}

@addField(W3PlayerWitcher)
var gmTestXp07Saved : array<string>;
@addField(W3PlayerWitcher)
var gmTestXp07Kills : array<int>;

@addMethod(W3PlayerWitcher)
function GMTestXp07Record()
{
	var i : int;

	gmTestXp07Saved.Clear();
	gmTestXp07Saved.PushBack(GMTestXp07Cfg('GMNoQuestLevels'));
	gmTestXp07Saved.PushBack(GMTestXp07Cfg('GMUseXMLExp'));
	gmTestXp07Saved.PushBack(GMTestXp07Cfg('GMQuestExpModifier'));
	gmTestXp07Saved.PushBack(GMTestXp07Cfg('GMMonsterExpModifier'));
	GMIncKills(GMENT_WOLF);	// sizes the counter (a save without kills has none; GMTestKillsAdd needs it)
	GMTestKillsAdd(GMENT_WOLF, -1);
	gmTestXp07Kills.Clear();
	for(i = 0; i < (int)GMENT_MAX_TYPES; i += 1)
		gmTestXp07Kills.PushBack(GMGetKills(i));
}

exec function gmtest_xp07_start()
{
	var w : W3PlayerWitcher;

	w = GetWitcherPlayer();
	w.GMTestXp07Record();
	w.GMTestSetLevelOverride(12);
	LogChannel('GMTest', "INFO XP-07 options recorded: " + GMTestXp07Text() + "; Geralt held at level " + w.GetLevel() + " (his own " + w.levelManager.GetLevel() + ")");
}

exec function gmtest_xp07_spawn()
{
	var w : W3PlayerWitcher;
	var npc : CNewNPC;

	w = GetWitcherPlayer();
	w.GMTestXpClear();
	npc = GMTestAi06Spawn("characters\npc_entities\monsters\drowner_lvl1.w2ent", 30);		w.GMTestXpAddNpc(npc, "drowner");
	npc = GMTestAi06Spawn("characters\npc_entities\monsters\gryphon_lvl1.w2ent", 40);		w.GMTestXpAddNpc(npc, "griffin");
	npc = GMTestAi06Spawn("characters\npc_entities\monsters\wolf_lvl1.w2ent", 50);			w.GMTestXpAddNpc(npc, "wolf");
	LogChannel('GMTest', "INFO XP-07 samples spawned: " + w.gmTestXpNpcs.Size());
}

// One option through the menu's event, if its value changes (the menu's Flash calls it only on a change).
function GMTestXp07SetOne(menu : CR4IngameMenu, option : name, value : string) : string
{
	var cfg : CInGameConfigWrapper;

	cfg = theGame.GetInGameConfigWrapper();
	if(cfg.GetVarValue('GMExpOptions', option) == value)
		return "";
	cfg.SetVarValue('GMExpOptions', option, value);
	menu.OnOptionValueChanged(cfg.GetGroupIdx('GMExpOptions'), option, value);
	return " " + NameToString(option) + "=" + value;
}

exec function gmtest_xp07_set(k : int)
{
	var menu : CR4IngameMenu;
	var noQL, fixedExp : bool;
	var qm, cm : float;
	var s : string;

	menu = GMTestDiff04Menu();
	if(!menu || !GMTestXp07Case(k, noQL, fixedExp, qm, cm))
	{
		LogChannel('GMTest', "FAIL XP-07 the options menu is not open, or no case " + k);
		return;
	}
	s += GMTestXp07SetOne(menu, 'GMNoQuestLevels', GMTestXp07Bool(noQL));
	s += GMTestXp07SetOne(menu, 'GMUseXMLExp', GMTestXp07Bool(fixedExp));
	s += GMTestXp07SetOne(menu, 'GMQuestExpModifier', NoTrailZeros(qm));
	s += GMTestXp07SetOne(menu, 'GMMonsterExpModifier', NoTrailZeros(cm));
	LogChannel('GMTest', "INFO XP-07 case " + k + " set through the menu's event:" + s + "; close the menu to apply");
}

exec function gmtest_xp07_preset()
{
	var menu : CR4IngameMenu;

	menu = GMTestDiff04Menu();
	if(!menu)
	{
		LogChannel('GMTest', "FAIL XP-07 the options menu is not open");
		return;
	}
	LogChannel('GMTest', "INFO XP-07 before the preset: " + GMTestXp07Text());
	menu.OnPresetApplied('GMExpOptions', 0);
	LogChannel('GMTest', "INFO XP-07 the \"Default\" preset applied through the menu's event: " + GMTestXp07Text() + "; close the menu to apply");
}

// ---- what each case gives ----

// A reward through the game's own GiveReward; the experience gained compared with `want`.
function GMTestXp07Give(rname : name, want : int, label : string)
{
	var before, got : int;

	before = GMTestXpPoints();
	theGame.GiveReward(rname, thePlayer);
	got = GMTestXpPoints() - before;
	GMTestReport(got == want, "XP-07 " + label + ": " + rname + " at Geralt " + thePlayer.GetLevel() + ": +" + got + " XP (want " + want + ")");
}

// A scripted kill (as XP-04's checks): the sample at `lvl` with `kills` earlier kills of its type, killed through the
// damage manager with Geralt as the attacker; the experience gained and the combat log line compared with `want`.
function GMTestXp07Kill(label : string, lvl : int, kills : int, want : int, caseLabel : string)
{
	var w : W3PlayerWitcher;
	var npc : CNewNPC;
	var action : W3DamageAction;
	var et : EGMEnemyType;
	var before, gained, i, kBefore : int;
	var line, logText : string;
	var params : array<int>;
	var logged : bool;

	w = GetWitcherPlayer();
	npc = GMTestXp04Npc(label);
	if(!npc || !npc.IsAlive())
	{
		GMTestReport(false, "XP-07 " + caseLabel + ": the " + label + " present and alive (gmtest_xp07_spawn first)");
		return;
	}
	et = GMGetEnemyTypeByAbility(npc);
	npc.SetLevel(lvl);
	w.GMTestKillsAdd(et, kills - w.GMGetKills(et));
	kBefore = w.GMGetKills(et);
	npc.ResetTemporaryAttitudeGroup(AGP_Default);
	npc.SetImmortalityMode(AIM_None, AIC_Default, true);
	npc.SetAttitude(thePlayer, AIA_Hostile);
	before = GMTestXpPoints();
	w.GMTestXpLogStart(true);
	action = new W3DamageAction in theGame.damageMgr;
	action.Initialize(thePlayer, npc, NULL, "gmtest_xp07", EHRT_None, CPS_Undefined, false, false, false, false);
	action.AddDamage(theGame.params.DAMAGE_NAME_DIRECT, npc.GetMaxHealth() * 10 + 1000000);
	theGame.damageMgr.ProcessAction(action);
	delete action;
	w.GMTestXpLogStart(false);
	gained = GMTestXpPoints() - before;
	params.PushBack(want);
	line = GetLocStringByKeyExtWithParams("hud_combat_log_gained_experience", params);
	for(i = 0; i < w.gmTestXpLog.Size(); i += 1)
	{
		logText += " [" + w.gmTestXpLog[i] + "]";
		if(w.gmTestXpLog[i] == line)
			logged = true;
	}
	GMTestReport(!npc.IsAlive() && gained == want && logged, "XP-07 " + caseLabel + ": a " + label + " (level " + lvl + ", Geralt " + thePlayer.GetLevel()
		+ ", type " + et + ", " + kills + " earlier kills, counter " + kBefore + " -> " + w.GMGetKills(et) + ") killed: +" + gained + " XP (want " + want + "), log:" + logText);
}

// The journal's quest levels: j 0 every table, 1 none, 2 the base game's, Hearts of Stone's and Blood and Wine's only.
function GMTestXp07Journal(j : int, caseLabel : string)
{
	var found, fist, ofir, belgard, wolf, n : int;
	var agree, ok : bool;
	var s : string;

	n = theGame.questLevelsContainer.Size();
	fist = GMTestXpJournalLevel("Fist Fight Championship", found, agree);
	ofir = GMTestXpJournalLevel("th1010ofirarmor", found, agree);
	belgard = GMTestXpJournalLevel("ww_belgard_secret", found, agree);
	wolf = GMTestXpJournalLevel("Wolf Set", found, agree);
	s = n + " tables (" + theGame.GMTestQuestLevelPaths() + " ), the Fistfight Championship " + fist + ", Ofieri's armor " + ofir + ", ww_belgard_secret "
		+ belgard + ", the Wolf School set " + wolf;
	if(j == 1)
		ok = n == 0 && fist == 0 && ofir == 0 && belgard == 0 && wolf == 0;
	else if(j == 2)
		ok = n == 3 && fist == 30 && ofir == 32 && belgard == 38 && wolf == 0;
	else
		ok = n == 7 && fist == 30 && ofir == 32 && belgard == 38 && wolf == 21;
	if(j == 1)
		s += " (want no table, no level)";
	else if(j == 2)
		s += " (want the three tables 30, 32, 38 and no Wolf School level: legacy's gap until the next load)";
	else
		s += " (want all seven tables: 30, 32, 38, 21)";
	GMTestReport(ok, "XP-07 " + caseLabel + ": the journal's quest levels: " + s);
}

// Case k's checks at Geralt 12. Quests (legacy's rule): q301_2_helped_triss (level 10, 250 XP) 170, q601_olgierd_met
// (level 32, 200 XP) 300 (the 150% cap), q001_1_after_dream (level 1, 200 XP) 5 (the minimum); fixed experience or no quest levels:
// the reward's own 250, 200, 200; then x (1 + quest modifier), rounded half up. Kills (legacy's formula): a drowner at
// Geralt's level after 50 drowners 2 (2.5, truncated), a griffin 3 levels up 14 (14.8), a wolf 1; fixed: 5, 10, 1;
// then x (1 + combat modifier), rounded half up.
function GMTestXp07CheckCase(k : int, j : int, caseLabel : string)
{
	var noQL, fixedExp : bool;
	var qm, cm : float;
	var triss, olgierd, dream, drowner, griffin, wolf : int;

	GMTestXp07Case(k, noQL, fixedExp, qm, cm);
	GMTestReport(GMXpNoQuestLevels() == noQL && GMXpFixedExp() == fixedExp && GMXpQuestExpModifier() == qm && GMXpCombatExpModifier() == cm,
		"XP-07 " + caseLabel + ": the options read " + GMTestXp07Text() + "; the hooks " + GMXpNoQuestLevels() + ", " + GMXpFixedExp() + ", "
		+ NoTrailZeros(GMXpQuestExpModifier()) + ", " + NoTrailZeros(GMXpCombatExpModifier()) + " (want " + noQL + ", " + fixedExp + ", " + NoTrailZeros(qm) + ", " + NoTrailZeros(cm) + ")");
	if(noQL || fixedExp)
	{
		triss = 250; olgierd = 200; dream = 200;
	}
	else
	{
		triss = 170; olgierd = 300; dream = 5;
	}
	if(fixedExp)
	{
		drowner = 5; griffin = 10; wolf = 1;
	}
	else
	{
		drowner = 2; griffin = 14; wolf = 1;
	}
	// the values below are worked by hand per case in the comments; the products here are exact (no float tie)
	switch(k)
	{
		case 1: triss = 0; olgierd = 0; dream = 0; drowner = 0; griffin = 0; wolf = 0; break;		// x0
		case 2: triss = 85; olgierd = 150; dream = 3; drowner = 1; griffin = 7; wolf = 1; break;	// x0.5: 2.5 -> 3, 0.5 -> 1
		case 3: triss = 255; olgierd = 450; dream = 8; drowner = 3; griffin = 21; wolf = 2; break;	// x1.5: 7.5 -> 8, 1.5 -> 2
		case 4: triss = 340; olgierd = 600; dream = 10; drowner = 4; griffin = 28; wolf = 2; break;	// x2
		case 8: triss = 300; olgierd = 240; dream = 240; drowner = 3; griffin = 6; wolf = 1; break;	// fixed, x1.2 and x0.6: 3, 6, 0.6 -> 1
	}
	GMTestXp07Give('q301_2_helped_triss', triss, caseLabel);
	GMTestXp07Give('q601_olgierd_met', olgierd, caseLabel);
	GMTestXp07Give('q001_1_after_dream', dream, caseLabel);
	GMTestXp07Kill("drowner", 12, 50, drowner, caseLabel);
	GMTestXp07Kill("griffin", 15, 0, griffin, caseLabel);
	GMTestXp07Kill("wolf", 12, 0, wolf, caseLabel);
	GMTestXp07Journal(j, caseLabel);
}

exec function gmtest_xp07_check(k : int, j : int)
{
	thePlayer.GMTestCount(true, true);
	GMTestXp07CheckCase(k, j, "case " + k);
	LogChannel('GMTest', "SUMMARY xp07 case " + k + ": " + thePlayer.gmTestPassed + " passed, " + thePlayer.gmTestFailed + " failed");
}

// After the "Default" preset (from case 8's values): everything off and 0, the quest levels reloaded (j).
exec function gmtest_xp07_preset_check(j : int)
{
	thePlayer.GMTestCount(true, true);
	GMTestReport(GMTestXp07Cfg('GMNoQuestLevels') == "false" && GMTestXp07Cfg('GMUseXMLExp') == "false" && StringToFloat(GMTestXp07Cfg('GMQuestExpModifier')) == 0
		&& StringToFloat(GMTestXp07Cfg('GMMonsterExpModifier')) == 0, "XP-07 the \"Default\" preset: options " + GMTestXp07Text() + " (legacy's table: false, false, 0, 0)");
	GMTestXp07CheckCase(0, j, "after the \"Default\" preset");
	LogChannel('GMTest', "SUMMARY xp07 preset: " + thePlayer.gmTestPassed + " passed, " + thePlayer.gmTestFailed + " failed");
}

// The four options cleared in memory, as before the menu or a load ever wrote them: they read "" and the hooks
// legacy's defaults (off, 0), so a reward and a kill give case 0's; then set back.
exec function gmtest_xp07_unset()
{
	var cfg : CInGameConfigWrapper;
	var w : W3PlayerWitcher;
	var prev : string;

	w = GetWitcherPlayer();
	cfg = theGame.GetInGameConfigWrapper();
	thePlayer.GMTestCount(true, true);
	prev = GMTestXp07Text();
	cfg.SetVarValue('GMExpOptions', 'GMNoQuestLevels', "");
	cfg.SetVarValue('GMExpOptions', 'GMUseXMLExp', "");
	cfg.SetVarValue('GMExpOptions', 'GMQuestExpModifier', "");
	cfg.SetVarValue('GMExpOptions', 'GMMonsterExpModifier', "");
	GMTestReport(GMTestXp07Text() == "noQuestLevels='' fixed='' quest='' combat=''", "XP-07 unset: the options cleared, read " + GMTestXp07Text() + " (were " + prev + ")");
	GMTestReport(GMOptionDefault('GMExpOptions', 'GMNoQuestLevels') == "false" && GMOptionDefault('GMExpOptions', 'GMUseXMLExp') == "false"
		&& GMOptionDefault('GMExpOptions', 'GMQuestExpModifier') == "0" && GMOptionDefault('GMExpOptions', 'GMMonsterExpModifier') == "0",
		"XP-07 unset: the defaults are legacy's \"Default\" preset (false, false, 0, 0)");
	GMTestXp07CheckCase(0, 0, "options unset");
	cfg.SetVarValue('GMExpOptions', 'GMNoQuestLevels', w.gmTestXp07Saved[0]);
	cfg.SetVarValue('GMExpOptions', 'GMUseXMLExp', w.gmTestXp07Saved[1]);
	cfg.SetVarValue('GMExpOptions', 'GMQuestExpModifier', w.gmTestXp07Saved[2]);
	cfg.SetVarValue('GMExpOptions', 'GMMonsterExpModifier', w.gmTestXp07Saved[3]);
	GMTestReport(GMTestXp07Cfg('GMNoQuestLevels') == w.gmTestXp07Saved[0] && GMTestXp07Cfg('GMMonsterExpModifier') == w.gmTestXp07Saved[3], "XP-07 unset: the options set back: " + GMTestXp07Text());
	LogChannel('GMTest', "SUMMARY xp07 unset: " + thePlayer.gmTestPassed + " passed, " + thePlayer.gmTestFailed + " failed");
}

// After a relaunch: the options and the quest levels as the load left them, logged.
exec function gmtest_xp07_info()
{
	LogChannel('GMTest', "INFO XP-07 options " + GMTestXp07Text() + "; hooks " + GMXpNoQuestLevels() + ", " + GMXpFixedExp() + ", " + NoTrailZeros(GMXpQuestExpModifier())
		+ ", " + NoTrailZeros(GMXpCombatExpModifier()) + "; quest-level tables " + theGame.questLevelsContainer.Size() + ":" + theGame.GMTestQuestLevelPaths());
}

exec function gmtest_xp07_end()
{
	var w : W3PlayerWitcher;
	var i : int;

	w = GetWitcherPlayer();
	w.GMTestSetLevelOverride(0);
	for(i = 0; i < w.gmTestXp07Kills.Size(); i += 1)
		w.GMTestKillsAdd(i, w.gmTestXp07Kills[i] - w.GMGetKills(i));
	w.GMTestXpClear();
	LogChannel('GMTest', "INFO XP-07 Geralt's level override off (" + w.GetLevel() + "), kill counts back, samples removed; options " + GMTestXp07Text());
}

// ---- in the regression ----
// The labels (this language's text by key and by legacy's id), legacy's defaults, and the hooks following the options
// (set in memory and set back).
function GMTest_xp07()
{
	var cfg : CInGameConfigWrapper;
	var keys : array<string>;
	var ids : array<int>;
	var prev : array<string>;
	var i, bad : int;
	var s : string;

	keys.PushBack("panel_gm_exp_options");					ids.PushBack(2110992328);
	keys.PushBack("preset_Mods_ghost_mode_gm_exp_options");	ids.PushBack(2110992452);
	keys.PushBack("preset_value_gm_default");				ids.PushBack(2110992451);
	keys.PushBack("option_gm_no_quest_levels_toggle");		ids.PushBack(2110992253);
	keys.PushBack("option_gm_use_xml_exp_toggle");			ids.PushBack(2110992300);
	keys.PushBack("option_gm_quest_exp_slider");			ids.PushBack(2110992270);
	keys.PushBack("option_gm_monster_exp_slider");			ids.PushBack(2110992271);
	for(i = 0; i < keys.Size(); i += 1)
	{
		if(GetLocStringByKeyExt(keys[i]) == "" || GetLocStringByKeyExt(keys[i]) != GetLocStringById(ids[i]))
			bad += 1;
		s += keys[i] + " '" + GetLocStringByKeyExt(keys[i]) + "'; ";
	}
	GMTestReport(bad == 0, "XP-07 the menu's 7 labels by key equal legacy's ids: " + s);
	GMTestReport(GMOptionDefault('GMExpOptions', 'GMNoQuestLevels') == "false" && GMOptionDefault('GMExpOptions', 'GMUseXMLExp') == "false"
		&& GMOptionDefault('GMExpOptions', 'GMQuestExpModifier') == "0" && GMOptionDefault('GMExpOptions', 'GMMonsterExpModifier') == "0",
		"XP-07 defaults: legacy's \"Default\" preset (false, false, 0, 0)");
	cfg = theGame.GetInGameConfigWrapper();
	prev.PushBack(GMTestXp07Cfg('GMNoQuestLevels'));
	prev.PushBack(GMTestXp07Cfg('GMUseXMLExp'));
	prev.PushBack(GMTestXp07Cfg('GMQuestExpModifier'));
	prev.PushBack(GMTestXp07Cfg('GMMonsterExpModifier'));
	cfg.SetVarValue('GMExpOptions', 'GMNoQuestLevels', "true");
	cfg.SetVarValue('GMExpOptions', 'GMUseXMLExp', "true");
	cfg.SetVarValue('GMExpOptions', 'GMQuestExpModifier', "0.5");
	cfg.SetVarValue('GMExpOptions', 'GMMonsterExpModifier', "-0.25");
	GMTestReport(GMXpNoQuestLevels() && GMXpFixedExp() && GMXpQuestExpModifier() == 0.5 && GMXpCombatExpModifier() == -0.25,
		"XP-07 the hooks read the options: " + GMXpNoQuestLevels() + ", " + GMXpFixedExp() + ", " + NoTrailZeros(GMXpQuestExpModifier()) + ", " + NoTrailZeros(GMXpCombatExpModifier())
		+ " (set true, true, 0.5, -0.25)");
	GMTestReport(GMQuestExperience(250, 10, 12) == 375, "XP-07 a level-10, 250-XP reward at Geralt 12 with those options: " + GMQuestExperience(250, 10, 12) + " XP (want 375: 250 unscaled, x1.5; 170 without the options)");
	cfg.SetVarValue('GMExpOptions', 'GMNoQuestLevels', prev[0]);
	cfg.SetVarValue('GMExpOptions', 'GMUseXMLExp', prev[1]);
	cfg.SetVarValue('GMExpOptions', 'GMQuestExpModifier', prev[2]);
	cfg.SetVarValue('GMExpOptions', 'GMMonsterExpModifier', prev[3]);
	GMTestReport(GMTestXp07Text() == "noQuestLevels='" + prev[0] + "' fixed='" + prev[1] + "' quest='" + prev[2] + "' combat='" + prev[3] + "'", "XP-07 options set back: " + GMTestXp07Text());
}

exec function gmtest_xp07()
{
	thePlayer.GMTestCount(true, true);
	GMTest_xp07();
	LogChannel('GMTest', "SUMMARY xp07: " + thePlayer.gmTestPassed + " passed, " + thePlayer.gmTestFailed + " failed");
}
