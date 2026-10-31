// DIFF-04 (slice D5a): the enemy scaling options. Spawned samples are levelled at a set Geralt level (the
// test override of GetLevel, gmTestsAi06.ws) under each scaling type and option, and compared with legacy's
// rules computed here independently of the code under test. Options are set in memory (SetVarValue, not
// prevOpts) and set back in the same call, except where a check needs them across calls (the re-level and the
// save checks, which record and restore them).
//   gmtest_diff04_a()          spawn the samples (frozen, neutral), then in a later call:
//   gmtest_diff04_levels()     every scaling type at Geralt 10 and 20, the guards' and animals' options
//   gmtest_diff04_random()     the random types: bounds, no downscaling, kept while in bounds, rolled again outside
//   gmtest_diff04_default()    DD1: the options unset read as the "Recommended" preset (soft upscaling)
//   gmtest_diff04_b()          remove the samples
// The re-level on a change and the save checks: see the exec functions further down.
// In the regression: GMTest_diff04() (spawns its own two samples, levels them under each type, removes them).
// In the panel: GMTest_diff04_after() (a mode change under the modifiers, the random level rolled again by a mode
// and an option change after a load), on the bandit GMTest_diff04_spawn() leaves in the regression.

// ---- helpers ----

function GMTestD04If(b : bool, s : string) : string
{
	if(b)
		return s;
	return "";
}

// Test only: give this NPC a base level as if its entity had it, and make its next level computation a
// fresh one (as at spawn or after an option change).
@addMethod(CNewNPC)
function GMTestSetBaseLevel(l : int)
{
	level = l;
	currentLevel = l + gmCurrentNGPLevel;
	gmSavedRandomLevel = 0;
	levelBonusesComputedAtPlayerLevel = -1;
}

@addMethod(CNewNPC)
function GMTestFreshLevel()
{
	levelBonusesComputedAtPlayerLevel = -1;
}

// The NPC's level computed with Geralt at level p (fresh: as after a reset, a new random level).
function GMTestDiff04Recalc(npc : CNewNPC, p : int, fresh : bool)
{
	var w : W3PlayerWitcher;

	w = GetWitcherPlayer();
	if(fresh)
		npc.GMTestFreshLevel();
	w.GMTestSetLevelOverride(p);
	npc.RecalcLevel();
	w.GMTestSetLevelOverride(0);
}

// Wolves, boars and other animals or beasts on Vitality (legacy's IsAnimal() || IsBeast(), read here from
// the monster category directly).
function GMTestDiff04IsAnimal(npc : CNewNPC) : bool
{
	var cat : EMonsterCategory;
	var tmpName : name;
	var tmpBool : bool;

	theGame.GetMonsterParamsForActor(npc, cat, tmpName, tmpBool, tmpBool, tmpBool);
	return (cat == MC_Animal || cat == MC_Beast) && npc.GetStat(BCS_Vitality, true) > 0;
}

// Legacy's rule for the non-random types: the level an NPC of base level `base` gets at Geralt's level p.
function GMTestDiff04Expected(npc : CNewNPC, base : int, p : int, scalingType : int, noAnimal : bool, noGuard : bool) : int
{
	var lvl : int;
	var guard : bool;

	lvl = base + npc.gmCurrentNGPLevel;
	if(npc.HasAbility('NPCDoNotGainBoost'))
		return lvl;
	guard = npc.GetNPCType() == ENGT_Guard;
	if(guard)
		lvl = p;
	if(npc.HasAbility('banshee_summons'))
		scalingType = -1;
	if(noAnimal && GMTestDiff04IsAnimal(npc))
	{
		if(lvl * 2 > p && scalingType > 0)
			lvl = Max(1, p / 2);
		scalingType = -1;
	}
	if(scalingType == 1 && lvl < p)
		lvl = p;
	else if(scalingType == 2)
		lvl = p;
	else if(scalingType == 3 && lvl < p - 6)
		lvl = p - 6;
	if(guard)
	{
		if(lvl < p)
			lvl = p;
		if(!noGuard)
			lvl += 16;
	}
	return Max(1, lvl);
}

// The NPC's level and its displayed-level abilities agree (level 1: none).
function GMTestDiff04Abls(npc : CNewNPC) : bool
{
	if(npc.HasAbility('NPCDoNotGainBoost'))
		return true;
	if(npc.currentLevel < 2)
		return npc.GetAbilityCount('DisplayedLevelAbl') == 0;
	return npc.GetAbilityCount('DisplayedLevelAbl') == npc.currentLevel - 1;
}

function GMTestDiff04TypeName(t : int) : string
{
	switch(t)
	{
		case 0: return "None";
		case 1: return "Upscale";
		case 2: return "Match";
		case 3: return "Soft";
		case 4: return "Random";
		case 5: return "Random no downscaling";
	}
	return "?" + t;
}

// The scaling options (D5a's five, D5b's seven): record, set, restore.
@addField(CR4Player)
var gmTestD04Saved : array<string>;

@addMethod(CR4Player)
function GMTestD04SetSaved(v : array<string>)
{
	gmTestD04Saved = v;
}

function GMTestDiff04Options() : array<name>
{
	var o : array<name>;

	o.PushBack('Virtual_GMScaling');
	o.PushBack('GMRandomScalingMinLevel');
	o.PushBack('GMRandomScalingMaxLevel');
	o.PushBack('GMNoAddLevelsGuards');
	o.PushBack('GMNoAnimalUpscaling');
	o.PushBack('GMNonlinearLevelup');
	o.PushBack('GMNonlinearLevelDelta');
	o.PushBack('GMNonlinearAbilitiesDelta');
	o.PushBack('GMHealthMultiplier');
	o.PushBack('GMDamageMultiplier');
	o.PushBack('GMBossHealthMultiplier');
	o.PushBack('GMBossDamageMultiplier');
	return o;
}

function GMTestDiff04Record() : array<string>
{
	var o : array<name>;
	var v : array<string>;
	var i : int;

	o = GMTestDiff04Options();
	for(i = 0; i < o.Size(); i += 1)
		v.PushBack(theGame.GetInGameConfigWrapper().GetVarValue('GMScalingOptions', o[i]));
	return v;
}

function GMTestDiff04Restore(v : array<string>)
{
	var o : array<name>;
	var i : int;

	o = GMTestDiff04Options();
	for(i = 0; i < o.Size() && i < v.Size(); i += 1)
		theGame.GetInGameConfigWrapper().SetVarValue('GMScalingOptions', o[i], v[i]);
}

function GMTestDiff04Text(v : array<string>) : string
{
	var o : array<name>;
	var i : int;
	var s : string;

	o = GMTestDiff04Options();
	for(i = 0; i < o.Size() && i < v.Size(); i += 1)
		s += NameToString(o[i]) + "='" + v[i] + "' ";
	return s;
}

function GMTestDiff04Set(scalingType : int, minB : int, maxB : int, noGuard : bool, noAnimal : bool)
{
	var cfg : CInGameConfigWrapper;

	cfg = theGame.GetInGameConfigWrapper();
	cfg.SetVarValue('GMScalingOptions', 'Virtual_GMScaling', IntToString(scalingType));
	cfg.SetVarValue('GMScalingOptions', 'GMRandomScalingMinLevel', IntToString(minB));
	cfg.SetVarValue('GMScalingOptions', 'GMRandomScalingMaxLevel', IntToString(maxB));
	if(noGuard) cfg.SetVarValue('GMScalingOptions', 'GMNoAddLevelsGuards', "true"); else cfg.SetVarValue('GMScalingOptions', 'GMNoAddLevelsGuards', "false");
	if(noAnimal) cfg.SetVarValue('GMScalingOptions', 'GMNoAnimalUpscaling', "true"); else cfg.SetVarValue('GMScalingOptions', 'GMNoAnimalUpscaling', "false");
}

// ---- the samples ----

@addField(CR4Player)
var gmTestD04Npcs : array<CNewNPC>;

@addField(CR4Player)
var gmTestD04Base : array<int>;

@addField(CR4Player)
var gmTestD04Label : array<string>;

@addMethod(CR4Player)
function GMTestD04Add(npc : CNewNPC, base : int, label : string)
{
	gmTestD04Npcs.PushBack(npc);
	gmTestD04Base.PushBack(base);
	gmTestD04Label.PushBack(label);
}

@addMethod(CR4Player)
function GMTestD04Clear()
{
	gmTestD04Npcs.Clear();
	gmTestD04Base.Clear();
	gmTestD04Label.Clear();
}

function GMTestDiff04Spawn(kind : string, base : int, distance : float, guard : bool, label : string)
{
	var npc : CNewNPC;

	npc = GMTestDummySpawn(kind, 0, distance, true);
	if(!npc)
		return;
	if(guard)
		npc.SetNPCType(ENGT_Guard);
	thePlayer.GMTestD04Add(npc, base, label);
}

exec function gmtest_diff04_a()
{
	thePlayer.GMTestDummyClearAll();
	thePlayer.GMTestD04Clear();
	GMTestDiff04Spawn("human", 2, 4, false, "bandit 2");
	GMTestDiff04Spawn("human", 15, 5, false, "bandit 15");
	GMTestDiff04Spawn("human", 30, 6, false, "bandit 30");
	GMTestDiff04Spawn("human", 1, 7, true, "guard");
	GMTestDiff04Spawn("wolf", 3, 8, false, "wolf 3");
	GMTestDiff04Spawn("wolf", 15, 9, false, "wolf 15");
	GMTestDiff04Spawn("bear", 12, 10, false, "bear 12");
	GMTestDiff04Spawn("drowner", 3, 11, false, "drowner 3");
	GMTestDiff04Spawn("drowner", 25, 12, false, "drowner 25");
	LogChannel('GMTest', "INFO DIFF-04 " + thePlayer.gmTestD04Npcs.Size() + " samples spawned (frozen, friendly); read them in a later call");
}

exec function gmtest_diff04_b()
{
	thePlayer.GMTestDummyClearAll();
	thePlayer.GMTestD04Clear();
}

// One scaling setting on every sample at Geralt level p: one PASS/FAIL line.
function GMTestDiff04Case(scalingType : int, p : int, noGuard : bool, noAnimal : bool) : bool
{
	var i, want : int;
	var npc : CNewNPC;
	var ok, all : bool;
	var s : string;

	GMTestDiff04Set(scalingType, 0, 0, noGuard, noAnimal);
	all = true;
	for(i = 0; i < thePlayer.gmTestD04Npcs.Size(); i += 1)
	{
		npc = thePlayer.gmTestD04Npcs[i];
		npc.GMTestSetBaseLevel(thePlayer.gmTestD04Base[i]);
		GMTestDiff04Recalc(npc, p, true);
		want = GMTestDiff04Expected(npc, thePlayer.gmTestD04Base[i], p, scalingType, noAnimal, noGuard);
		ok = npc.currentLevel == want && GMTestDiff04Abls(npc);
		all = all && ok;
		s += thePlayer.gmTestD04Label[i] + " " + npc.currentLevel;
		if(!ok) s += " (want " + want + ", DisplayedLevelAbl " + npc.GetAbilityCount('DisplayedLevelAbl') + ")";
		s += "; ";
	}
	GMTestReport(all && thePlayer.gmTestD04Npcs.Size() > 0, "DIFF-04 " + GMTestDiff04TypeName(scalingType) + " at Geralt " + p + GMTestD04If(noGuard, ", no guard levels") + GMTestD04If(noAnimal, ", animals not upscaled") + ": " + s);
	return all;
}

exec function gmtest_diff04_levels()
{
	var prevOpts : array<string>;
	var t, k, p : int;

	prevOpts = GMTestDiff04Record();
	thePlayer.GMTestCount(true, true);
	for(k = 0; k < 2; k += 1)
	{
		p = 10 + 10 * k;
		for(t = 0; t <= 3; t += 1)
			GMTestDiff04Case(t, p, false, false);
		// "No additional levels for guards"
		GMTestDiff04Case(0, p, true, false);
		GMTestDiff04Case(2, p, true, false);
		// "Do not upscale animals" (DD4: lowered to half Geralt's level when above it, with scaling on)
		GMTestDiff04Case(0, p, false, true);
		GMTestDiff04Case(1, p, false, true);
		GMTestDiff04Case(3, p, false, true);
	}
	GMTestDiff04Restore(prevOpts);
	GMTestReport(GMTestDiff04Text(GMTestDiff04Record()) == GMTestDiff04Text(prevOpts), "DIFF-04 options restored: " + GMTestDiff04Text(prevOpts));
	LogChannel('GMTest', "SUMMARY diff04 levels: " + thePlayer.gmTestPassed + " passed, " + thePlayer.gmTestFailed + " failed");
}

// The random types: every non-animal sample in [p + min, p + max] (guards then raised to Geralt + 16);
// "no downscaling" never below the base level; the level kept when Geralt's level changes while it stays in
// the bounds and rolled again when it falls out; many fresh rolls cover the range.
function GMTestDiff04RandomCase(scalingType : int, p : int, minB : int, maxB : int)
{
	var i, base, lo, hi, lvl, first : int;
	var npc : CNewNPC;
	var ok, inB, all, kept, allKept : bool;
	var s, s2 : string;

	GMTestDiff04Set(scalingType, minB, maxB, false, false);
	all = true; allKept = true;
	lo = Max(1, p + minB);
	hi = Max(lo, p + maxB);
	for(i = 0; i < thePlayer.gmTestD04Npcs.Size(); i += 1)
	{
		npc = thePlayer.gmTestD04Npcs[i];
		base = thePlayer.gmTestD04Base[i];
		npc.GMTestSetBaseLevel(base);
		GMTestDiff04Recalc(npc, p, true);
		lvl = npc.currentLevel;
		if(npc.GetNPCType() == ENGT_Guard)
			ok = lvl >= p + 16 && lvl <= Max(p, hi) + 16;
		else if(scalingType == 5 && base > hi)
			ok = lvl == base;
		else if(scalingType == 5)
			ok = lvl >= Max(lo, base) && lvl <= hi;
		else
			ok = lvl >= lo && lvl <= hi;
		ok = ok && GMTestDiff04Abls(npc);
		all = all && ok;
		s += thePlayer.gmTestD04Label[i] + " " + lvl + GMTestD04If(!ok, " (out)") + "; ";
		// Geralt one level up: kept while in the new bounds, else a new level in them
		first = npc.gmSavedRandomLevel;
		GMTestDiff04Recalc(npc, p + 1, false);
		inB = first >= Max(1, p + 1 + minB) && first <= Max(Max(1, p + 1 + minB), p + 1 + maxB);
		if(npc.GetNPCType() == ENGT_Guard || (scalingType == 5 && base > hi))
			kept = true;	// not a plain random level
		else if(inB)
			kept = npc.gmSavedRandomLevel == first && npc.currentLevel == first;
		else
			kept = npc.gmSavedRandomLevel >= Max(1, p + 1 + minB) && npc.gmSavedRandomLevel <= p + 1 + maxB;
		allKept = allKept && kept;
		s2 += thePlayer.gmTestD04Label[i] + " " + first + "->" + npc.gmSavedRandomLevel + GMTestD04If(inB, " (in bounds)") + GMTestD04If(!inB, " (out)") + "; ";
	}
	GMTestReport(all, "DIFF-04 " + GMTestDiff04TypeName(scalingType) + " " + minB + ".." + maxB + " at Geralt " + p + " (" + lo + " to " + hi + "): " + s);
	GMTestReport(allKept, "DIFF-04 " + GMTestDiff04TypeName(scalingType) + " at Geralt " + (p + 1) + ": random level kept in bounds, rolled again outside: " + s2);
}

exec function gmtest_diff04_random()
{
	var prevOpts : array<string>;
	var i, j, lvl, lo, hi : int;
	var seen : array<int>;
	var npc : CNewNPC;
	var ok : bool;

	prevOpts = GMTestDiff04Record();
	thePlayer.GMTestCount(true, true);
	GMTestDiff04RandomCase(4, 10, -3, 3);
	GMTestDiff04RandomCase(4, 20, -3, 3);
	GMTestDiff04RandomCase(5, 10, -3, 3);
	GMTestDiff04RandomCase(5, 20, -3, 3);
	GMTestDiff04RandomCase(4, 20, 0, 0);
	GMTestDiff04RandomCase(4, 10, -12, -10);
	// many fresh rolls of the first sample (bandit 2) at Geralt 20, bounds -5..5: all in 15..25, most values seen
	GMTestDiff04Set(4, -5, 5, false, false);
	npc = thePlayer.gmTestD04Npcs[0];
	lo = 15; hi = 25; ok = true;
	for(i = 0; i < 100; i += 1)
	{
		npc.GMTestSetBaseLevel(2);
		GMTestDiff04Recalc(npc, 20, true);
		lvl = npc.currentLevel;
		ok = ok && lvl >= lo && lvl <= hi;
		if(!seen.Contains(lvl))
			seen.PushBack(lvl);
	}
	GMTestReport(ok && seen.Size() >= 8, "DIFF-04 100 fresh rolls at Geralt 20, bounds -5..5: all in 15..25 " + ok + ", " + seen.Size() + " of 11 values seen");
	GMTestDiff04Restore(prevOpts);
	GMTestReport(GMTestDiff04Text(GMTestDiff04Record()) == GMTestDiff04Text(prevOpts), "DIFF-04 options restored: " + GMTestDiff04Text(prevOpts));
	LogChannel('GMTest', "SUMMARY diff04 random: " + thePlayer.gmTestPassed + " passed, " + thePlayer.gmTestFailed + " failed");
}

// DD1: with every scaling option unset (as before the menu was ever opened), the getters read the
// "Recommended" preset's values and the samples level as under soft upscaling.
exec function gmtest_diff04_default()
{
	var prevOpts, now : array<string>;
	var o : array<name>;
	var i, want : int;
	var npc : CNewNPC;
	var all : bool;
	var s : string;

	prevOpts = GMTestDiff04Record();
	thePlayer.GMTestCount(true, true);
	o = GMTestDiff04Options();
	for(i = 0; i < o.Size(); i += 1)
		theGame.GetInGameConfigWrapper().SetVarValue('GMScalingOptions', o[i], "");
	now = GMTestDiff04Record();
	LogChannel('GMTest', "INFO DIFF-04 options cleared, read back: " + GMTestDiff04Text(now));
	// the virtual variable cannot be cleared in game (SetVarValue "" keeps its value); unset, it reads "-1",
	// which only a settings file without the group gives (checked at a load): here its fallback is checked
	GMTestReport(GMOptionUnset('Virtual_GMScaling', "-1") && GMOptionUnset('Virtual_GMScaling', "") && !GMOptionUnset('Virtual_GMScaling', "0")
		&& !GMOptionUnset('GMRandomScalingMinLevel', "-1") && GMOptionDefault('GMScalingOptions', 'Virtual_GMScaling') == "3",
		"DIFF-04 DD1 the scaling type unset (read as -1 or empty) falls back to its default " + GMOptionDefault('GMScalingOptions', 'Virtual_GMScaling') + "; 0 (None) is a value");
	for(i = 1; i < o.Size(); i += 1)
		if(!GMOptionUnset(o[i], now[i]))
			GMTestReport(false, "DIFF-04 DD1 " + NameToString(o[i]) + " could not be cleared: '" + now[i] + "'");
	GMTestReport(GMGetEnemyScalingOption() == 3 && GMGetRandomScalingMinLevel() == 0 && GMGetRandomScalingMaxLevel() == 0 && !GMGetNoAdditionalLevelsForGuards() && !GMGetNoAnimalUpscaling(),
		"DIFF-04 DD1 unset options read as the Recommended preset: scaling " + GMGetEnemyScalingOption() + " (3), bounds " + GMGetRandomScalingMinLevel() + ".." + GMGetRandomScalingMaxLevel()
		+ ", no guard levels " + GMGetNoAdditionalLevelsForGuards() + ", animals not upscaled " + GMGetNoAnimalUpscaling());
	all = true;
	for(i = 0; i < thePlayer.gmTestD04Npcs.Size(); i += 1)
	{
		npc = thePlayer.gmTestD04Npcs[i];
		npc.GMTestSetBaseLevel(thePlayer.gmTestD04Base[i]);
		GMTestDiff04Recalc(npc, 20, true);
		want = GMTestDiff04Expected(npc, thePlayer.gmTestD04Base[i], 20, 3, false, false);
		all = all && npc.currentLevel == want;
		s += thePlayer.gmTestD04Label[i] + " " + npc.currentLevel + "/" + want + "; ";
	}
	GMTestReport(all && thePlayer.gmTestD04Npcs.Size() > 0, "DIFF-04 DD1 unset options at Geralt 20 level as soft upscaling: " + s);
	GMTestDiff04Restore(prevOpts);
	GMTestReport(GMTestDiff04Text(GMTestDiff04Record()) == GMTestDiff04Text(prevOpts), "DIFF-04 options restored: " + GMTestDiff04Text(prevOpts));
	LogChannel('GMTest', "SUMMARY diff04 default: " + thePlayer.gmTestPassed + " passed, " + thePlayer.gmTestFailed + " failed");
}

exec function gmtest_diff04_opts()
{
	LogChannel('GMTest', "INFO DIFF-04 options: " + GMTestDiff04Text(GMTestDiff04Record()) + "; GMScaling='" + theGame.GetInGameConfigWrapper().GetVarValue('GMScalingOptions', 'GMScaling')
		+ "'; read: scaling " + GMGetEnemyScalingOption() + ", bounds " + GMGetRandomScalingMinLevel() + ".." + GMGetRandomScalingMaxLevel() + ", no guard levels " + GMGetNoAdditionalLevelsForGuards() + ", animals " + GMGetNoAnimalUpscaling());
}

// ---- re-levelling on an option change ----
// gmtest_diff04_change_a(): records the options, sets soft upscaling, holds Geralt at level 20 (the test
// override, until _c), spawns a hostile bandit of base level 2 and a wolf of base 15, and records every NPC
// within 100 m (the world's included); their levels are computed by the timer at Geralt 20.
// Then the option is changed through the options menu (by hand: ingamemenu(), Options, Mods, Ghost Mode,
// Enemy scaling; or gmtest_diff04_change_menu(type) with the menu open, which calls the menu's own event),
// and the menu closed (game.py resume: the menu's SaveChangedSettings runs on closing).
// gmtest_diff04_change_b(): every recorded NPC has the level of the new type (the re-level ran at once).
// gmtest_diff04_change_c(): restores the options and Geralt's level, re-levels everything, removes the samples.

@addField(CR4Player)
var gmTestD04Near : array<CNewNPC>;

@addField(CR4Player)
var gmTestD04NearLevel : array<int>;

exec function gmtest_diff04_change_a()
{
	var w : W3PlayerWitcher;
	var all : array<CActor>;
	var npc : CNewNPC;
	var i : int;

	w = GetWitcherPlayer();
	thePlayer.GMTestD04SetSaved(GMTestDiff04Record());
	LogChannel('GMTest', "INFO DIFF-04 options recorded: " + GMTestDiff04Text(thePlayer.gmTestD04Saved));
	theGame.GetInGameConfigWrapper().SetVarValue('GMScalingOptions', 'Virtual_GMScaling', "3");
	thePlayer.GMTestDummyClearAll();
	thePlayer.GMTestD04Clear();
	GMTestDiff04Spawn("human", 2, 4, false, "bandit 2");
	GMTestDiff04Spawn("wolf", 15, 6, false, "wolf 15");
	for(i = 0; i < thePlayer.gmTestD04Npcs.Size(); i += 1)
	{
		thePlayer.gmTestD04Npcs[i].SetTemporaryAttitudeGroup('hostile_to_player', AGP_Default);
		thePlayer.gmTestD04Npcs[i].GMTestSetBaseLevel(thePlayer.gmTestD04Base[i]);
	}
	w.GMTestSetLevelOverride(20);
	thePlayer.gmTestD04Near.Clear();
	thePlayer.gmTestD04NearLevel.Clear();
	all = GetActorsInRange(thePlayer, 100, 200, '', true);
	for(i = 0; i < all.Size(); i += 1)
	{
		npc = (CNewNPC)all[i];
		if(npc)
		{
			npc.GMResetLevel();
			thePlayer.gmTestD04Near.PushBack(npc);
			thePlayer.gmTestD04NearLevel.PushBack(npc.GMTestEntityLevel());
		}
	}
	LogChannel('GMTest', "INFO DIFF-04 Geralt held at level 20, soft upscaling; " + thePlayer.gmTestD04Near.Size() + " NPCs within 100 m recorded");
}

// Logs every recorded NPC's level against the type's rule; with check, one PASS/FAIL line.
function GMTestDiff04Near(scalingType : int, check : bool, label : string)
{
	var i, want, n, bad : int;
	var npc : CNewNPC;
	var s : string;

	for(i = 0; i < thePlayer.gmTestD04Near.Size(); i += 1)
	{
		npc = thePlayer.gmTestD04Near[i];
		if(!npc || !npc.IsAlive())
			continue;
		n += 1;
		want = GMTestDiff04Expected(npc, thePlayer.gmTestD04NearLevel[i], 20, scalingType, GMGetNoAnimalUpscaling(), GMGetNoAdditionalLevelsForGuards());
		if(npc.currentLevel != want)
			bad += 1;
		s += npc.GetReadableName() + " " + thePlayer.gmTestD04NearLevel[i] + "->" + npc.currentLevel + GMTestD04If(npc.currentLevel != want, " (want " + want + ")") + "; ";
	}
	LogChannel('GMTest', "INFO DIFF-04 " + label + ": " + s);
	if(check)
		GMTestReport(bad == 0 && n > 0, "DIFF-04 " + label + ": " + (n - bad) + " of " + n + " NPCs within 100 m at the level of " + GMTestDiff04TypeName(scalingType) + " at Geralt 20");
}

exec function gmtest_diff04_change_mid()
{
	GMTestDiff04Near(3, true, "before the change (soft upscaling)");
}

// With the options menu open: the option set and the menu's own change event called, as its Flash does.
exec function gmtest_diff04_change_menu(t : int)
{
	var menu : CR4IngameMenu;
	var root : CR4MenuBase;

	root = (CR4MenuBase)theGame.GetGuiManager().GetRootMenu();
	if(root)
		menu = (CR4IngameMenu)root.GetLastChild();
	if(!menu)
	{
		LogChannel('GMTest', "FAIL DIFF-04 the options menu is not open");
		return;
	}
	theGame.GetInGameConfigWrapper().SetVarValue('GMScalingOptions', 'Virtual_GMScaling', IntToString(t));
	menu.OnOptionValueChanged(theGame.GetInGameConfigWrapper().GetGroupIdx('GMScalingOptions'), 'Virtual_GMScaling', IntToString(t));
	LogChannel('GMTest', "INFO DIFF-04 scaling set to " + GMTestDiff04TypeName(t) + " through the menu's event; close the menu to apply");
}

exec function gmtest_diff04_change_b()
{
	thePlayer.GMTestCount(true, true);
	GMTestDiff04Near(GMGetEnemyScalingOption(), true, "after the change to " + GMTestDiff04TypeName(GMGetEnemyScalingOption()));
	LogChannel('GMTest', "SUMMARY diff04 change: " + thePlayer.gmTestPassed + " passed, " + thePlayer.gmTestFailed + " failed");
}

exec function gmtest_diff04_change_c()
{
	GMTestDiff04Restore(thePlayer.gmTestD04Saved);
	theGame.SaveUserSettings();
	GetWitcherPlayer().GMTestSetLevelOverride(0);
	thePlayer.GMTestDummyClearAll();
	thePlayer.GMTestD04Clear();
	GMOnScalingOptionsChanged();
	LogChannel('GMTest', "INFO DIFF-04 options restored (" + GMTestDiff04Text(GMTestDiff04Record()) + "), Geralt back at " + thePlayer.GetLevel() + ", NPCs re-levelled");
}

// ---- the random level across a save and a load ----
// Set the random type first (autoconfigset GMScalingOptions Virtual_GMScaling 4, bounds -12 and 12).
// gmtest_diff04_save_a(): four friendly bandits spawned persistent, tagged; their random levels are rolled at
// Geralt's own level by the timer. gmtest_diff04_save_b(): records their levels in facts (saved with the
// game). Then gmtest_save() (a new manual slot) and the save loaded.
// gmtest_diff04_save_c(): each bandit has the level it had, and its OnSpawned ran as restored (where
// legacy rolled the level again).

@addField(CNewNPC)
var gmTestSpawnRestored : int;

@wrapMethod(CNewNPC)
function OnSpawned(spawnData : SEntitySpawnData)
{
	var ret : bool;

	ret = wrappedMethod(spawnData);
	if(spawnData.restored) gmTestSpawnRestored = 1; else gmTestSpawnRestored = 2;
	return ret;
}

function GMTestDiff04SaveTag(i : int) : name
{
	switch(i)
	{
		case 0: return 'gmtest_d04_rnd0';
		case 1: return 'gmtest_d04_rnd1';
		case 2: return 'gmtest_d04_rnd2';
		case 3: return 'gmtest_d04_rnd3';
	}
	return 'gmtest_d04_rnd';
}

function GMTestDiff04SaveFact(i : int) : string
{
	return "gmtest_d04_rnd" + i;
}

exec function gmtest_diff04_save_a()
{
	var template : CEntityTemplate;
	var npc : CNewNPC;
	var tags : array<name>;
	var pos : Vector;
	var i : int;

	template = (CEntityTemplate)LoadResource(GMTestDummyTemplate("human"), true);
	for(i = 0; i < 4; i += 1)
	{
		tags.Clear();
		tags.PushBack(GMTestDiff04SaveTag(i));
		pos = thePlayer.GetWorldPosition() + thePlayer.GetHeadingVector() * (4 + 2 * i);
		npc = (CNewNPC)theGame.CreateEntity(template, pos, VecToRotation(-thePlayer.GetHeadingVector()), true, false, false, PM_Persist, tags);
		if(npc)
		{
			npc.SetTemporaryAttitudeGroup('friendly_to_player', AGP_Default);
			npc.SetAnimationSpeedMultiplier(0.001);
		}
	}
	LogChannel('GMTest', "INFO DIFF-04 four persistent bandits spawned; scaling " + GMTestDiff04TypeName(GMGetEnemyScalingOption()) + " " + GMGetRandomScalingMinLevel() + ".." + GMGetRandomScalingMaxLevel());
}

exec function gmtest_diff04_save_b()
{
	var npc : CNewNPC;
	var i : int;
	var s : string;

	for(i = 0; i < 4; i += 1)
	{
		npc = (CNewNPC)theGame.GetEntityByTag(GMTestDiff04SaveTag(i));
		if(!npc)
		{
			LogChannel('GMTest', "FAIL DIFF-04 bandit " + i + " not found");
			continue;
		}
		FactsRemove(GMTestDiff04SaveFact(i));
		FactsAdd(GMTestDiff04SaveFact(i), npc.gmSavedRandomLevel);
		s += i + ": level " + npc.currentLevel + ", saved random level " + npc.gmSavedRandomLevel + "; ";
	}
	LogChannel('GMTest', "INFO DIFF-04 before the save, Geralt " + thePlayer.GetLevel() + ": " + s);
}

exec function gmtest_diff04_save_c()
{
	var npc : CNewNPC;
	var i, want, same, shown : int;
	var s : string;
	var restored, cleared : bool;

	thePlayer.GMTestCount(true, true);
	restored = true;
	for(i = 0; i < 4; i += 1)
	{
		npc = (CNewNPC)theGame.GetEntityByTag(GMTestDiff04SaveTag(i));
		want = FactsQuerySum(GMTestDiff04SaveFact(i));
		if(!npc)
		{
			s += i + ": not found; ";
			restored = false;
			continue;
		}
		restored = restored && npc.gmTestSpawnRestored == 1;
		shown = npc.GetLevel();
		// the level is computed again at the start of a fight (as in legacy: not at the load itself)
		npc.RecalcLevel();
		if(npc.currentLevel == want && npc.gmSavedRandomLevel == want && want > 0 && shown == want)
			same += 1;
		s += i + ": shown after the load " + shown + ", level at the fight's start " + npc.currentLevel + ", saved " + npc.gmSavedRandomLevel + " (before the save " + want + ", restored spawn " + (npc.gmTestSpawnRestored == 1) + "); ";
	}
	GMTestReport(same == 4, "DIFF-04 random levels kept across a save and a load, Geralt " + thePlayer.GetLevel() + ", " + GMTestDiff04TypeName(GMGetEnemyScalingOption()) + " " + GMGetRandomScalingMinLevel() + ".." + GMGetRandomScalingMaxLevel() + ": " + same + " of 4: " + s);
	GMTestReport(restored, "DIFF-04 their OnSpawned ran as a restore (legacy reset the random level here)");
	// an option change or a mode change right after a load rolls again (the keep flag is cleared)
	npc = (CNewNPC)theGame.GetEntityByTag(GMTestDiff04SaveTag(0));
	if(npc)
	{
		npc.gmKeepRandomLevel = true;
		npc.GMResetLevel();
		cleared = !npc.gmKeepRandomLevel;
		npc.gmKeepRandomLevel = true;
		npc.OnGameDifficultyChanged(theGame.GetDifficultyLevel(), theGame.GetDifficultyLevel());
		GMTestReport(cleared && !npc.gmKeepRandomLevel, "DIFF-04 an option change and a mode change after a load roll the random level again (keep flag cleared: " + cleared + ", " + !npc.gmKeepRandomLevel + ")");
	}
	LogChannel('GMTest', "SUMMARY diff04 save: " + thePlayer.gmTestPassed + " passed, " + thePlayer.gmTestFailed + " failed");
}

// Removes the persistent bandits and their facts.
exec function gmtest_diff04_save_d()
{
	var npc : CNewNPC;
	var i : int;

	for(i = 0; i < 4; i += 1)
	{
		npc = (CNewNPC)theGame.GetEntityByTag(GMTestDiff04SaveTag(i));
		if(npc)
			npc.Destroy();
		FactsRemove(GMTestDiff04SaveFact(i));
	}
}

// Every NPC within 100 m: its level, saved random level and whether it was restored (an older save's NPCs).
exec function gmtest_diff04_world()
{
	var all : array<CActor>;
	var npc : CNewNPC;
	var i : int;
	var s : string;

	all = GetActorsInRange(thePlayer, 100, 100, '', true);
	for(i = 0; i < all.Size(); i += 1)
	{
		npc = (CNewNPC)all[i];
		if(npc)
			s += npc.GetReadableName() + " entity " + npc.GMTestEntityLevel() + " level " + npc.currentLevel + " random " + npc.gmSavedRandomLevel + " restored " + npc.gmTestSpawnRestored + " hostile " + (npc.GetAttitude(thePlayer) == AIA_Hostile) + "; ";
	}
	LogChannel('GMTest', "INFO DIFF-04 Geralt " + thePlayer.GetLevel() + ", scaling " + GMTestDiff04TypeName(GMGetEnemyScalingOption()) + ": " + s);
}

// ---- in the regression ----

// A friendly frozen bandit at the given distance, not in the test dummies' list (removed by the caller).
function GMTestDiff04SpawnLoose(distance : float) : CNewNPC
{
	var template : CEntityTemplate;
	var npc : CNewNPC;

	template = (CEntityTemplate)LoadResource(GMTestDummyTemplate("human"), true);
	npc = (CNewNPC)theGame.CreateEntity(template, thePlayer.GetWorldPosition() + thePlayer.GetHeadingVector() * distance, VecToRotation(-thePlayer.GetHeadingVector()));
	if(npc)
	{
		npc.SetTemporaryAttitudeGroup('friendly_to_player', AGP_Default);
		npc.SetAnimationSpeedMultiplier(0.001);
	}
	return npc;
}
// Two samples (a bandit of base 2, a guard) levelled at Geralt 20 under each non-random type and a random one,
// and the guards' option; the options set back. Spawns cost a little game time; the samples are removed at once.
function GMTest_diff04()
{
	var prevOpts : array<string>;
	var bandit, guard : CNewNPC;
	var t, want, wantG : int;
	var ok : bool;
	var s : string;

	prevOpts = GMTestDiff04Record();
	bandit = GMTestDiff04SpawnLoose(30);
	guard = GMTestDiff04SpawnLoose(32);
	if(!bandit || !guard)
	{
		GMTestReport(false, "DIFF-04 the regression samples did not spawn");
		return;
	}
	guard.SetNPCType(ENGT_Guard);
	ok = true;
	for(t = 0; t <= 3; t += 1)
	{
		GMTestDiff04Set(t, 0, 0, t == 2, false);
		bandit.GMTestSetBaseLevel(2);
		guard.GMTestSetBaseLevel(1);
		GMTestDiff04Recalc(bandit, 20, true);
		GMTestDiff04Recalc(guard, 20, true);
		want = GMTestDiff04Expected(bandit, 2, 20, t, false, t == 2);
		wantG = GMTestDiff04Expected(guard, 1, 20, t, false, t == 2);
		ok = ok && bandit.currentLevel == want && guard.currentLevel == wantG;
		s += GMTestDiff04TypeName(t) + " " + bandit.currentLevel + "/" + want + ", guard " + guard.currentLevel + "/" + wantG + "; ";
	}
	GMTestDiff04Set(4, -2, 2, false, false);
	bandit.GMTestSetBaseLevel(2);
	GMTestDiff04Recalc(bandit, 20, true);
	ok = ok && bandit.currentLevel >= 18 && bandit.currentLevel <= 22 && bandit.gmSavedRandomLevel == bandit.currentLevel;
	s += "Random -2..2 " + bandit.currentLevel;
	GMTestDiff04bRegress(bandit);	// slice D5b: the modifiers, the boss rule, progressive level bonuses
	GMTestDiff04Restore(prevOpts);
	GMTestReport(ok, "DIFF-04 scaling types at Geralt 20 (a bandit of level 2, a guard; Match without guard levels): " + s);
	GMTestReport(GMTestDiff04Text(GMTestDiff04Record()) == GMTestDiff04Text(prevOpts), "DIFF-04 options restored: " + GMTestDiff04Text(prevOpts));
	bandit.Destroy();
	guard.Destroy();
}

// ---- in the panel: mode and option changes through the game's own paths (DIFF audit F4) ----
// The regression spawns a friendly frozen bandit (GMTest_diff04_spawn); GMTest_diff04_after(), last in
// gmtest_panel(), changes the mode through the game's path (SetDifficultyLevel, OnDifficultyChanged) and the
// options through the change hook (GMOnScalingOptionsChanged), and reads what the bandit's next level computation
// gives (RecalcLevel: what the mode change's and the hook's timer run). Last in the panel because a mode change
// rebuilds every NPC's stats, which undid the AI-06 samples' set levels inside the regression (development.md).

@addField(CR4Player)
var gmTestD04ModeNpc : CNewNPC;

@addMethod(CR4Player)
function GMTestD04SetModeNpc(npc : CNewNPC)
{
	gmTestD04ModeNpc = npc;
}

function GMTest_diff04_spawn()
{
	var ok : bool;

	if(thePlayer.gmTestD04ModeNpc)
		thePlayer.gmTestD04ModeNpc.Destroy();
	thePlayer.GMTestD04SetModeNpc(GMTestDiff04SpawnLoose(36));
	if(thePlayer.gmTestD04ModeNpc)
		ok = true;
	GMTestReport(ok, "DIFF-04 the bandit for the panel's mode and option changes spawned");
}

// The difficulty abilities the NPC holds, with their counts (E, M, H, DM).
function GMTestD04DiffAbls(npc : CNewNPC) : string
{
	var s : string;

	if(npc.HasAbility('difficulty_CommonEasy')) s += "E" + npc.GetAbilityCount('difficulty_CommonEasy');
	if(npc.HasAbility('difficulty_CommonMedium')) s += "M" + npc.GetAbilityCount('difficulty_CommonMedium');
	if(npc.HasAbility('difficulty_CommonHard')) s += "H" + npc.GetAbilityCount('difficulty_CommonHard');
	if(npc.HasAbility('difficulty_CommonHardcore')) s += "DM" + npc.GetAbilityCount('difficulty_CommonHardcore');
	return s;
}

function GMTestD04DiffAblWant(mode : EDifficultyMode) : string
{
	switch(mode)
	{
		case EDM_Easy:		return "E1";
		case EDM_Medium:	return "M1";
		case EDM_Hard:		return "H1";
		case EDM_Hardcore:	return "DM1";
	}
	return "?";
}

// After a mode change under the "Hardcore" modifiers (set by the caller): exactly one set of step abilities for
// the options, the mode's multipliers under them, the mode's difficulty ability alone, the per-level count.
function GMTestD04ModeCase(npc : CNewNPC, label : string, pending : bool)
{
	var mode : EDifficultyMode;
	var baseHp, baseDmg : float;
	var okMods, ok : bool;
	var s : string;

	mode = theGame.GetSpawnDifficultyMode();
	GMTestDiffWant(mode, baseHp, baseDmg);
	GMTestDiff04Recalc(npc, 20, false);	// what the mode change's timer runs, at Geralt 20
	s = GMTestD04bCheckMods(npc, baseHp, baseDmg, okMods);
	ok = pending && okMods && GMTestD04DiffAbls(npc) == GMTestD04DiffAblWant(mode) && npc.currentLevel == 20 && GMTestD04bLevelAbls(npc) == 24;
	GMTestReport(ok, "DIFF-04 " + label + " under the Hardcore modifiers: re-level pending " + pending + ", level " + npc.currentLevel + " (20), per-level " + GMTestD04bLevelAbls(npc)
		+ " (24), difficulty abilities " + GMTestD04DiffAbls(npc) + " (" + GMTestD04DiffAblWant(mode) + "); " + s);
}

function GMTest_diff04_after()
{
	var npc : CNewNPC;
	var prevOpts : array<string>;
	var mode, other : EDifficultyMode;
	var pending, okKeep, okMode, okOpt : bool;
	var s : string;

	npc = thePlayer.gmTestD04ModeNpc;
	if(!npc)
	{
		GMTestReport(false, "DIFF-04 the panel's bandit is missing (run gmtest_regress() first)");
		return;
	}
	prevOpts = GMTestDiff04Record();
	mode = theGame.GetDifficultyMode();
	other = EDM_Hardcore;
	if(mode == EDM_Hardcore)
		other = EDM_Hard;

	// A mode change with the "Hardcore" preset's values: one set of step abilities after each change.
	GMTestDiff04Set(1, 0, 0, false, false);
	GMTestD04bSetProg(true, 10, 5);
	GMTestD04bSetMods(0.5, 0.5, 0.5, 0.5);
	npc.GMTestSetBaseLevel(2);
	GMTestDiff04Recalc(npc, 20, true);
	GMTestDiffSetMode(other);
	GMTestD04ModeCase(npc, "a change to " + GMTestDiffModeName(other), npc.GMTestLevelPending());
	GMTestDiffSetMode(EDM_Easy);
	GMTestDiffSetMode(EDM_Medium);
	GMTestD04ModeCase(npc, "two changes before a re-level (Just the Story!, then Story and Sword!)", npc.GMTestLevelPending());
	GMTestDiffSetMode(mode);
	GMTestD04ModeCase(npc, "the change back to " + GMTestDiffModeName(mode), npc.GMTestLevelPending() || mode == EDM_Medium);

	// The random level of an NPC restored from a save (kept at its first computation) is rolled again by a mode
	// change and by an option change. Random without downscaling, -2..2, at Geralt 20, a bandit of base 24 with
	// a saved level of 18: kept, it stays 18; rolled again, the roll (18 to 22) is raised to its own 24.
	GMTestDiff04Set(5, -2, 2, false, false);
	GMTestD04bSetProg(false, 0, 0);
	GMTestD04bSetMods(0, 0, 0, 0);
	npc.GMTestSetBaseLevel(24);
	npc.gmSavedRandomLevel = 18;
	npc.gmKeepRandomLevel = true;
	GMTestDiff04Recalc(npc, 20, true);
	okKeep = npc.currentLevel == 18 && npc.gmSavedRandomLevel == 18;
	s = "as restored: level " + npc.currentLevel + " (18, kept); ";
	npc.gmKeepRandomLevel = true;
	GMTestDiffSetMode(other);
	pending = npc.GMTestLevelPending();
	GMTestDiff04Recalc(npc, 20, false);
	okMode = pending && npc.currentLevel == 24 && npc.gmSavedRandomLevel == 24;
	GMTestReport(okKeep && okMode, "DIFF-04 a mode change after a load rolls the random level again (Random no downscaling -2..2, Geralt 20, base 24, saved 18): " + s
		+ "after the change to " + GMTestDiffModeName(other) + ": re-level pending " + pending + ", level " + npc.currentLevel + ", saved " + npc.gmSavedRandomLevel + " (24)");
	GMTestDiffSetMode(mode);
	npc.GMTestSetBaseLevel(24);
	npc.gmSavedRandomLevel = 18;
	npc.gmKeepRandomLevel = true;
	npc.GMTestLevelDone(20);
	GMOnScalingOptionsChanged();
	pending = npc.GMTestLevelPending();
	GMTestDiff04Recalc(npc, 20, false);
	okOpt = pending && npc.currentLevel == 24 && npc.gmSavedRandomLevel == 24;
	GMTestReport(okOpt, "DIFF-04 an option change after a load rolls the random level again (the change hook, GMOnScalingOptionsChanged): re-level pending " + pending
		+ ", level " + npc.currentLevel + ", saved " + npc.gmSavedRandomLevel + " (24)");

	GMTestDiff04Restore(prevOpts);
	if(theGame.GetDifficultyMode() != mode)
		GMTestDiffSetMode(mode);
	GMTestReport(GMTestDiff04Text(GMTestDiff04Record()) == GMTestDiff04Text(prevOpts) && theGame.GetDifficultyMode() == mode,
		"DIFF-04 options and mode restored after the panel's changes: " + GMTestDiff04Text(prevOpts) + ", " + GMTestDiffModeName(mode));
	npc.Destroy();
	thePlayer.GMTestD04SetModeNpc(NULL);
	GMOnScalingOptionsChanged();	// every NPC near Geralt back to the restored options
}

// ---- the change hook for every scaling option name (D5a's five and D5b's, PD6) ----

@addMethod(CNewNPC)
function GMTestLevelPending() : bool
{
	return levelBonusesComputedAtPlayerLevel == -1;
}

@addMethod(CNewNPC)
function GMTestLevelDone(p : int)
{
	levelBonusesComputedAtPlayerLevel = p;
}

// Test only: what the menu runs when it closes (and when a difficulty change is confirmed).
@addMethod(CR4IngameMenu)
function GMTestSaveChanged()
{
	SaveChangedSettings();
}

function GMTestDiff04Menu() : CR4IngameMenu
{
	var root : CR4MenuBase;

	root = (CR4MenuBase)theGame.GetGuiManager().GetRootMenu();
	if(root)
		return (CR4IngameMenu)root.GetLastChild();
	return NULL;
}

// With the options menu open (ingamemenu()) and gmtest_diff04_change_a()'s samples spawned: for each name the
// menu's change event is called with the option's current value (nothing changes), then what the menu runs on
// closing; every recorded NPC must then be waiting for a new level computation (legacy's ResetLevel), and a
// non-scaling option (GMSignCooldown) must leave them alone. That a change of each D5b option also applies its
// effect at once is gmtest_diff04b_relevel_* (gmTestsDiff04b.ws).
exec function gmtest_diff04_hook_names()
{
	var menu : CR4IngameMenu;
	var names : array<name>;
	var i, j, n, pending : int;
	var npc : CNewNPC;
	var cfg : CInGameConfigWrapper;
	var s : string;
	var want : bool;

	thePlayer.GMTestCount(true, true);
	menu = GMTestDiff04Menu();
	if(!menu)
	{
		GMTestReport(false, "DIFF-04 the options menu is not open");
		return;
	}
	cfg = theGame.GetInGameConfigWrapper();
	names.PushBack('Virtual_GMScaling'); names.PushBack('GMScaling'); names.PushBack('GMRandomScalingMinLevel'); names.PushBack('GMRandomScalingMaxLevel');
	names.PushBack('GMNoAnimalUpscaling'); names.PushBack('GMNoAddLevelsGuards'); names.PushBack('GMHealthMultiplier'); names.PushBack('GMDamageMultiplier');
	names.PushBack('GMNonlinearLevelup'); names.PushBack('GMNonlinearLevelDelta'); names.PushBack('GMNonlinearAbilitiesDelta');
	names.PushBack('GMBossHealthMultiplier'); names.PushBack('GMBossDamageMultiplier'); names.PushBack('GMSignCooldown');
	for(i = 0; i < names.Size(); i += 1)
	{
		for(j = 0; j < thePlayer.gmTestD04Near.Size(); j += 1)
			if(thePlayer.gmTestD04Near[j])
				thePlayer.gmTestD04Near[j].GMTestLevelDone(20);
		if(names[i] == 'GMSignCooldown')
			menu.OnOptionValueChanged(cfg.GetGroupIdx('GMGameplayOptions'), names[i], cfg.GetVarValue('GMGameplayOptions', names[i]));
		else
			menu.OnOptionValueChanged(cfg.GetGroupIdx('GMScalingOptions'), names[i], cfg.GetVarValue('GMScalingOptions', names[i]));
		menu.GMTestSaveChanged();
		n = 0; pending = 0;
		for(j = 0; j < thePlayer.gmTestD04Near.Size(); j += 1)
		{
			npc = thePlayer.gmTestD04Near[j];
			if(!npc || !npc.IsAlive())
				continue;
			n += 1;
			if(npc.GMTestLevelPending())
				pending += 1;
		}
		want = names[i] != 'GMSignCooldown';
		GMTestReport(n > 0 && ((want && pending == n) || (!want && pending == 0)), "DIFF-04 the menu's change of " + NameToString(names[i]) + " (value '"
			+ cfg.GetVarValue('GMScalingOptions', names[i]) + "', in the scaling list " + GMIsScalingOption(names[i]) + "): " + pending + " of " + n + " NPCs re-levelled");
	}
	LogChannel('GMTest', "SUMMARY diff04 hook: " + thePlayer.gmTestPassed + " passed, " + thePlayer.gmTestFailed + " failed");
}

// Every NPC within range: its monster category, IsAnimal, GMIsBeast, Vitality and Essence (who counts as an
// animal for "Do not upscale animals").
exec function gmtest_diff04_kinds(optional range : float)
{
	var all : array<CActor>;
	var npc : CNewNPC;
	var i : int;
	var cat : EMonsterCategory;
	var tmpName : name;
	var tmpBool : bool;

	if(range <= 0)
		range = 30;
	all = GetActorsInRange(thePlayer, range, 100, '', true);
	for(i = 0; i < thePlayer.gmTestDummies.Size(); i += 1)	// hostile dummies are not always listed
		if(thePlayer.gmTestDummies[i] && !all.Contains(thePlayer.gmTestDummies[i]))
			all.PushBack(thePlayer.gmTestDummies[i]);
	for(i = 0; i < all.Size(); i += 1)
	{
		npc = (CNewNPC)all[i];
		if(!npc)
			continue;
		theGame.GetMonsterParamsForActor(npc, cat, tmpName, tmpBool, tmpBool, tmpBool);
		LogChannel('GMTest', "INFO DIFF-04 kind: " + npc.GetReadableName() + " category " + cat + " animal " + npc.IsAnimal() + " beast " + npc.GMIsBeast()
			+ " Vitality " + npc.GetStat(BCS_Vitality, true) + " Essence " + npc.GetStat(BCS_Essence, true));
	}
}

// Saves into a new manual slot (never over another save); remove hostile NPCs first.
exec function gmtest_diff04_save_mk()
{
	LogChannel('GMTest', "INFO DIFF-04 saving into a new manual slot");
	theGame.SaveGame(SGT_Manual, -1);
}
