// DIFF-04 (slice D5b): the health and damage modifiers, the boss modifiers, progressive level bonuses, the
// presets, the instant re-level of D5b's options and their DD1 defaults. Expected values follow legacy's rules,
// computed here from the options without the code under test (the modifiers: the owner's (1 + mode) x (1 + enemy
// + boss) of DIFF audit F3, floored at x0.01 health and x0 damage, replacing legacy's sum; the progressive
// count of InternalAddLevelBonuses, the preset table of modSignsConfig.xml). Options are set in memory and set
// back (GMTestDiff04Record and GMTestDiff04Restore cover all twelve scaling options).
//   gmtest_diff04b_a()          spawn the samples: a bandit, a drowner (Essence), a wolf and a contract monster with
//                               the boss bar (mh102's arachas), frozen and hostile; then in later calls:
//   gmtest_diff04b_mods()       each modifier and the boss modifiers: multipliers, step abilities, maximum health
//   gmtest_diff04b_hits()       scripted hits of each sample on Geralt under the "Hardcore" modifiers and under none
//   gmtest_diff04b_prog()       progressive level bonuses at levels 8, 20 and 30
//   gmtest_diff04b_default()    DD1: the seven options unset read as the "Recommended" preset (nothing added)
//   gmtest_diff04_b()           remove the samples (D5a's)
// Through the menu's code path (the pause menu open with ingamemenu(), closed with game.py resume):
//   gmtest_diff04b_menu_a()     records the options, holds Geralt at level 20, spawns the samples
//   gmtest_diff04b_preset(i)    applies preset i through the menu's own OnPresetApplied (menu open)
//   gmtest_diff04b_preset_check(i)   after closing: the options are the preset's, every sample re-levelled by it
//   gmtest_diff04b_relevel_start()   Match, progressive off with LD 10 and AD 5, no modifiers (in memory), all re-levelled
//   gmtest_diff04b_relevel_set(k)    sets D5b's option k to a new value through the menu's OnOptionValueChanged (menu open)
//   gmtest_diff04b_relevel_check(k)  after closing: every sample carries the new value's bonuses already
//   gmtest_diff04b_menu_c()     restores the options and Geralt's level, re-levels everything, removes the samples
// In the regression: part of GMTest_diff04 (GMTestDiff04bRegress).
// Across a save and a load into the test-only slot: gmtest_diff04_lsave_* (at the end of this file).

// ---- helpers ----

function GMTestD04bCfg(option : name) : string
{
	return theGame.GetInGameConfigWrapper().GetVarValue('GMScalingOptions', option);
}

function GMTestD04bSetCfg(option : name, value : string)
{
	theGame.GetInGameConfigWrapper().SetVarValue('GMScalingOptions', option, value);
}

function GMTestD04bSetMods(h : float, d : float, bh : float, bd : float)
{
	GMTestD04bSetCfg('GMHealthMultiplier', FloatToString(h));
	GMTestD04bSetCfg('GMDamageMultiplier', FloatToString(d));
	GMTestD04bSetCfg('GMBossHealthMultiplier', FloatToString(bh));
	GMTestD04bSetCfg('GMBossDamageMultiplier', FloatToString(bd));
}

function GMTestD04bSetProg(on : bool, ld : int, ad : int)
{
	if(on) GMTestD04bSetCfg('GMNonlinearLevelup', "true"); else GMTestD04bSetCfg('GMNonlinearLevelup', "false");
	GMTestD04bSetCfg('GMNonlinearLevelDelta', IntToString(ld));
	GMTestD04bSetCfg('GMNonlinearAbilitiesDelta', IntToString(ad));
}

// The option as legacy's getter reads it (StringToFloat; an unset option reads 0, as DD1's defaults).
function GMTestD04bF(option : name) : float
{
	return StringToFloat(GMTestD04bCfg(option));
}

// Legacy's boss rule, read here directly: the boss-bar tag.
function GMTestD04bBoss(npc : CNewNPC) : bool
{
	return npc.HasTag('HideHealthBarModule');
}

// The multiplier the modifier m (enemy + boss) gives on top of the mode's base multiplier, by the owner's rule
// (DIFF audit F3, 2026-10-31): base x (1 + m), health at least x0.01, damage at least x0 (legacy: base + m).
function GMTestD04bWant(base : float, m : float, health : bool) : float
{
	var w : float;

	w = base * (1 + m);
	if(health && w < 0.01)
		w = 0.01;
	if(!health && w < 0)
		w = 0;
	return w;
}

// The sum of the NPC's step abilities for health or damage, by their counts and values as written in
// gm_diff.xml (legacy's 0.1 steps and the port's 1, 0.01 and 0.001 ones).
function GMTestD04bStepSum(npc : CNewNPC, health : bool) : float
{
	if(health)
		return npc.GetAbilityCount('GM_ScalingHealth_p1') - npc.GetAbilityCount('GM_ScalingHealth_n1')
			+ 0.1 * (npc.GetAbilityCount('ModSignsAdditionalHealth') - npc.GetAbilityCount('ModSignsAdditionalHealthNegative'))
			+ 0.01 * (npc.GetAbilityCount('GM_ScalingHealth_p0.01') - npc.GetAbilityCount('GM_ScalingHealth_n0.01'))
			+ 0.001 * (npc.GetAbilityCount('GM_ScalingHealth_p0.001') - npc.GetAbilityCount('GM_ScalingHealth_n0.001'))
			- 0.99 * npc.GetAbilityCount('ModSignsMaxHealthNegative');
	return npc.GetAbilityCount('GM_ScalingDamage_p1') - npc.GetAbilityCount('GM_ScalingDamage_n1')
		+ 0.1 * (npc.GetAbilityCount('ModSignsAdditionalDamage') - npc.GetAbilityCount('ModSignsAdditionalDamageNegative'))
		+ 0.01 * (npc.GetAbilityCount('GM_ScalingDamage_p0.01') - npc.GetAbilityCount('GM_ScalingDamage_n0.01'))
		+ 0.001 * (npc.GetAbilityCount('GM_ScalingDamage_p0.001') - npc.GetAbilityCount('GM_ScalingDamage_n0.001'));
}

// The step abilities held, for the report: "+units/+tenths/+hundredths/+thousandths" (negative steps with -).
function GMTestD04bStepText(npc : CNewNPC, health : bool) : string
{
	if(health)
		return "+" + npc.GetAbilityCount('GM_ScalingHealth_p1') + "/" + npc.GetAbilityCount('ModSignsAdditionalHealth') + "/" + npc.GetAbilityCount('GM_ScalingHealth_p0.01') + "/" + npc.GetAbilityCount('GM_ScalingHealth_p0.001')
			+ " -" + npc.GetAbilityCount('GM_ScalingHealth_n1') + "/" + npc.GetAbilityCount('ModSignsAdditionalHealthNegative') + "/" + npc.GetAbilityCount('GM_ScalingHealth_n0.01') + "/" + npc.GetAbilityCount('GM_ScalingHealth_n0.001')
			+ GMTestD04If(npc.GetAbilityCount('ModSignsMaxHealthNegative') > 0, " max-" + npc.GetAbilityCount('ModSignsMaxHealthNegative'));
	return "+" + npc.GetAbilityCount('GM_ScalingDamage_p1') + "/" + npc.GetAbilityCount('ModSignsAdditionalDamage') + "/" + npc.GetAbilityCount('GM_ScalingDamage_p0.01') + "/" + npc.GetAbilityCount('GM_ScalingDamage_p0.001')
		+ " -" + npc.GetAbilityCount('GM_ScalingDamage_n1') + "/" + npc.GetAbilityCount('ModSignsAdditionalDamageNegative') + "/" + npc.GetAbilityCount('GM_ScalingDamage_n0.01') + "/" + npc.GetAbilityCount('GM_ScalingDamage_n0.001');
}

// The NPC's multipliers as the game uses them (gmTestsDiff.ws).
function GMTestD04bRead(npc : CNewNPC, out hp : float, out dmg : float)
{
	GMTestDiffRead(npc, hp, dmg);
}

// The NPC's maximum health against its health attribute x the multiplier.
function GMTestD04bMaxHealthOk(npc : CNewNPC, hp : float, out maxH : float, out predicted : float) : bool
{
	var noTags : array<name>;
	var h : SAbilityAttributeValue;

	if(npc.UsesEssence())
	{
		h = npc.GetCharacterStats().GetAttributeValue('essence', noTags);
		maxH = npc.GetStatMax(BCS_Essence);
	}
	else
	{
		h = npc.GetCharacterStats().GetAttributeValue('vitality', noTags);
		maxH = npc.GetStatMax(BCS_Vitality);
	}
	predicted = CalculateAttributeValue(h) * hp;
	return AbsF(maxH - predicted) < 0.5 + 0.0005 * predicted;
}

// The per-level bonus abilities the NPC holds (any kind).
function GMTestD04bLevelAbls(npc : CNewNPC) : int
{
	return npc.GetAbilityCount('AnimalLevelBonus') + npc.GetAbilityCount(theGame.params.ENEMY_BONUS_PER_LEVEL)
		+ npc.GetAbilityCount(theGame.params.MONSTER_BONUS_PER_LEVEL_GROUP_ARMORED) + npc.GetAbilityCount(theGame.params.MONSTER_BONUS_PER_LEVEL_ARMORED)
		+ npc.GetAbilityCount(theGame.params.MONSTER_BONUS_PER_LEVEL_GROUP) + npc.GetAbilityCount(theGame.params.MONSTER_BONUS_PER_LEVEL);
}

// Legacy's progressive count for level lvl with the options as set (0 below level 2).
function GMTestD04bWantAbls(lvl : int) : int
{
	var ld, ad : float;
	var n : int;

	if(lvl < 2)
		return 0;
	if(GMTestD04bCfg('GMNonlinearLevelup') != "true")
		return lvl - 1;
	ld = (int)GMTestD04bF('GMNonlinearLevelDelta');
	ad = (int)GMTestD04bF('GMNonlinearAbilitiesDelta');
	if(ld > 0 && lvl > ld)
		n = RoundMath((1 + ad / ld) * lvl - ad);
	else
		n = lvl;
	return n - 1;
}

// Checks one NPC's modifiers against the options as set: its step abilities and multipliers (baseHp, baseDmg: its
// multipliers with no modifier, the mode's) and its maximum health. Returns a description; ok is the verdict.
function GMTestD04bCheckMods(npc : CNewNPC, baseHp : float, baseDmg : float, out ok : bool) : string
{
	var h, d, hp, dmg, wantHp, wantDmg, maxH, predicted, sumH, sumD : float;
	var boss, healthOk : bool;

	boss = GMTestD04bBoss(npc);
	h = GMTestD04bF('GMHealthMultiplier');
	d = GMTestD04bF('GMDamageMultiplier');
	if(boss)
	{
		h += GMTestD04bF('GMBossHealthMultiplier');
		d += GMTestD04bF('GMBossDamageMultiplier');
	}
	wantHp = GMTestD04bWant(baseHp, h, true);
	wantDmg = GMTestD04bWant(baseDmg, d, false);
	GMTestD04bRead(npc, hp, dmg);
	sumH = GMTestD04bStepSum(npc, true);
	sumD = GMTestD04bStepSum(npc, false);
	healthOk = GMTestD04bMaxHealthOk(npc, hp, maxH, predicted);
	// one set of steps: their sum is the multiplier's change from the mode's (a second set would double it)
	ok = AbsF(hp - wantHp) < 0.002 && AbsF(dmg - wantDmg) < 0.002 && AbsF(sumH - (wantHp - baseHp)) < 0.002 && AbsF(sumD - (wantDmg - baseDmg)) < 0.002
		&& npc.GetAbilityCount('ModSignsMaxHealthNegative') == 0 && healthOk;
	return npc.GetDisplayName() + GMTestD04If(boss, " (boss)") + ": health x" + NoTrailZeros(hp) + " (want " + NoTrailZeros(wantHp) + "), damage x" + NoTrailZeros(dmg)
		+ " (want " + NoTrailZeros(wantDmg) + "), health steps " + GMTestD04bStepText(npc, true) + " (sum " + NoTrailZeros(sumH) + "), damage steps " + GMTestD04bStepText(npc, false)
		+ " (sum " + NoTrailZeros(sumD) + "), maximum health " + NoTrailZeros(maxH) + " (" + NoTrailZeros(predicted) + ")";
}

// ---- the samples ----

function GMTestD04bBossPath() : string
{
	return "quests\generic_quests\no_mans_land\quest_files\mh102_arachas\characters\mh102_arachas.w2ent";
}

// Spawns the four samples into D5a's sample list (base levels recorded: their entity's); hostile for the hit
// checks (DMG-05's step is for hostile NPCs), friendly for the menu checks (frozen samples can still drift and
// strike: a hostile level-20 sample killed Geralt during a menu run).
function GMTestD04bSpawn(optional friendly : bool)
{
	var npc : CNewNPC;

	thePlayer.GMTestDummyClearAll();
	thePlayer.GMTestD04Clear();
	npc = GMTestDummySpawn("human", 0, 4, friendly);
	if(npc) thePlayer.GMTestD04Add(npc, npc.GMTestEntityLevel(), "bandit");
	npc = GMTestDummySpawn("drowner", 0, 6, friendly);
	if(npc) thePlayer.GMTestD04Add(npc, npc.GMTestEntityLevel(), "drowner");
	npc = GMTestDummySpawn("wolf", 0, 8, friendly);
	if(npc) thePlayer.GMTestD04Add(npc, npc.GMTestEntityLevel(), "wolf");
	npc = GMTestDummySpawn(GMTestD04bBossPath(), 0, 12, friendly);
	if(npc) thePlayer.GMTestD04Add(npc, npc.GMTestEntityLevel(), "mh102 arachas");
}

exec function gmtest_diff04b_a()
{
	GMTestD04bSpawn();
	LogChannel('GMTest', "INFO DIFF-04 " + thePlayer.gmTestD04Npcs.Size() + " samples spawned (frozen, hostile); read them in a later call");
}

// The tag of each sample (the boss bar is given at spawn to contract monsters, W3MonsterHuntNPC.displayBossBar).
exec function gmtest_diff04b_info()
{
	var i : int;
	var npc : CNewNPC;
	var s : string;

	for(i = 0; i < thePlayer.gmTestD04Npcs.Size(); i += 1)
	{
		npc = thePlayer.gmTestD04Npcs[i];
		if(npc)
			s += thePlayer.gmTestD04Label[i] + " (" + npc.GetReadableName() + ") entity level " + thePlayer.gmTestD04Base[i] + ", level " + npc.currentLevel + ", boss bar " + GMTestD04bBoss(npc)
				+ ", monster hunt " + ((W3MonsterHuntNPC)npc) + ", essence " + npc.UsesEssence() + "; ";
	}
	LogChannel('GMTest', "INFO DIFF-04 samples: " + s);
}

// ---- the modifiers ----

// Every sample's multipliers with no modifier (the mode's), for the checks to add to.
@addField(CR4Player)
var gmTestD04bBaseHp : array<float>;
@addField(CR4Player)
var gmTestD04bBaseDmg : array<float>;

@addMethod(CR4Player)
function GMTestD04bSetBase(hp : array<float>, dmg : array<float>)
{
	gmTestD04bBaseHp = hp;
	gmTestD04bBaseDmg = dmg;
}

// Recomputes every sample's level and bonuses at Geralt level p and records the multipliers with no modifier.
function GMTestD04bRecordBase(p : int)
{
	var i : int;
	var hp, dmg : float;
	var hps, dmgs : array<float>;

	GMTestD04bSetMods(0, 0, 0, 0);
	for(i = 0; i < thePlayer.gmTestD04Npcs.Size(); i += 1)
	{
		GMTestDiff04Recalc(thePlayer.gmTestD04Npcs[i], p, true);
		GMTestD04bRead(thePlayer.gmTestD04Npcs[i], hp, dmg);
		hps.PushBack(hp);
		dmgs.PushBack(dmg);
	}
	thePlayer.GMTestD04bSetBase(hps, dmgs);
}

// One setting of the four modifiers on every sample: one PASS/FAIL line.
function GMTestD04bModsCase(h : float, d : float, bh : float, bd : float, label : string) : bool
{
	var i : int;
	var ok, all : bool;
	var s : string;

	GMTestD04bSetMods(h, d, bh, bd);
	all = true;
	for(i = 0; i < thePlayer.gmTestD04Npcs.Size(); i += 1)
	{
		GMTestDiff04Recalc(thePlayer.gmTestD04Npcs[i], 10, true);
		s += GMTestD04bCheckMods(thePlayer.gmTestD04Npcs[i], thePlayer.gmTestD04bBaseHp[i], thePlayer.gmTestD04bBaseDmg[i], ok) + "; ";
		all = all && ok;
	}
	GMTestReport(all && thePlayer.gmTestD04Npcs.Size() >= 4, "DIFF-04 " + label + " (health " + NoTrailZeros(h) + ", damage " + NoTrailZeros(d) + ", bosses +" + NoTrailZeros(bh) + " / +" + NoTrailZeros(bd) + "): " + s);
	return all;
}

exec function gmtest_diff04b_mods()
{
	var prevOpts : array<string>;
	var bossSeen : bool;
	var i : int;

	prevOpts = GMTestDiff04Record();
	thePlayer.GMTestCount(true, true);
	GMTestDiff04Set(0, 0, 0, false, false);
	GMTestD04bSetProg(false, 0, 0);
	GMTestD04bRecordBase(10);
	for(i = 0; i < thePlayer.gmTestD04Npcs.Size(); i += 1)
		bossSeen = bossSeen || GMTestD04bBoss(thePlayer.gmTestD04Npcs[i]);
	GMTestReport(bossSeen, "DIFF-04 a sample carries the boss bar tag (HideHealthBarModule): the contract monster");
	GMTestD04bModsCase(0, 0, 0, 0, "no modifier");
	GMTestD04bModsCase(0.5, 0, 0, 0, "health modifier");
	GMTestD04bModsCase(0, 0.5, 0, 0, "damage modifier");
	GMTestD04bModsCase(0.5, 0.5, 0.5, 0.5, "the Hardcore preset's modifiers");
	GMTestD04bModsCase(0, 0, 1, -0.5, "boss modifiers alone");
	GMTestD04bModsCase(-0.5, -0.3, 0, 0, "negative modifiers");
	GMTestD04bModsCase(-1, -1, 0, 0, "-100% (health -99%)");
	GMTestD04bModsCase(-0.6, 0, -0.5, 0, "boss health below -90% in sum");
	GMTestD04bModsCase(5, 5, 0, 0, "+500%");
	GMTestDiff04Restore(prevOpts);
	for(i = 0; i < thePlayer.gmTestD04Npcs.Size(); i += 1)
		GMTestDiff04Recalc(thePlayer.gmTestD04Npcs[i], 10, true);
	GMTestReport(GMTestDiff04Text(GMTestDiff04Record()) == GMTestDiff04Text(prevOpts), "DIFF-04 options restored: " + GMTestDiff04Text(prevOpts));
	LogChannel('GMTest', "SUMMARY diff04b mods: " + thePlayer.gmTestPassed + " passed, " + thePlayer.gmTestFailed + " failed");
}

// Scripted hits (200 slashing) of every sample on Geralt through the damage manager: the final-damage step
// multiplies by the mode's multiplier plus the modifiers (DMG-05's step, hostile NPCs on Geralt).
function GMTestD04bHitsCase(h : float, d : float, bh : float, bd : float, label : string)
{
	var i, j, n : int;
	var npc : CNewNPC;
	var want, got, dm, before : float;
	var ok : bool;

	GMTestD04bSetMods(h, d, bh, bd);
	for(i = 0; i < thePlayer.gmTestD04Npcs.Size(); i += 1)
	{
		npc = thePlayer.gmTestD04Npcs[i];
		GMTestDiff04Recalc(npc, 10, true);
		dm = d;
		if(GMTestD04bBoss(npc))
			dm += bd;
		want = GMTestD04bWant(thePlayer.gmTestD04bBaseDmg[i], dm, false);
		thePlayer.GMTestDiffHitsClear();
		GetWitcherPlayer().SetImmortalityMode(AIM_Immortal, AIC_Default, true);
		GMTestDmgCustom(npc, thePlayer, theGame.params.DAMAGE_NAME_SLASHING, 200, 0);
		GetWitcherPlayer().SetImmortalityMode(AIM_None, AIC_Default, true);
		thePlayer.ForceSetStat(BCS_Vitality, thePlayer.GetStatMax(BCS_Vitality));
		n = thePlayer.gmTestDiffHitWho.Size();
		ok = n > 0;
		got = 0;
		before = 0;
		for(j = 0; j < n; j += 1)
		{
			before = thePlayer.gmTestDiffHitBefore[j];
			got = thePlayer.gmTestDiffHitAfter[j] / MaxF(before, 0.0001);
			ok = ok && AbsF(got - want) < 0.001;
		}
		GMTestReport(ok, "DIFF-04 " + label + ": a hit of the " + thePlayer.gmTestD04Label[i] + GMTestD04If(GMTestD04bBoss(npc), " (boss)") + " on Geralt: " + NoTrailZeros(before)
			+ " before the difficulty step, x" + NoTrailZeros(got) + " (want x" + NoTrailZeros(want) + ", " + n + " hit)");
	}
}

exec function gmtest_diff04b_hits()
{
	var prevOpts : array<string>;
	var probes : bool;
	var i : int;

	prevOpts = GMTestDiff04Record();
	thePlayer.GMTestCount(true, true);
	probes = GMTestProbes();
	thePlayer.GMTestSetProbes(true);
	GMTestDiff04Set(0, 0, 0, false, false);
	GMTestD04bSetProg(false, 0, 0);
	GMTestD04bRecordBase(10);
	GMTestD04bHitsCase(0, 0, 0, 0, "no modifier");
	GMTestD04bHitsCase(0.5, 0.5, 0.5, 0.5, "the Hardcore preset's modifiers");
	GMTestD04bHitsCase(-0.5, -0.5, 0, 0, "-50%");
	GMTestD04bHitsCase(-1, -1, 0, 0, "-100% (damage x0, DIFF audit F3's floor)");
	thePlayer.GMTestSetProbes(probes);
	GMTestDiff04Restore(prevOpts);
	for(i = 0; i < thePlayer.gmTestD04Npcs.Size(); i += 1)
		GMTestDiff04Recalc(thePlayer.gmTestD04Npcs[i], 10, true);
	GMTestReport(GMTestDiff04Text(GMTestDiff04Record()) == GMTestDiff04Text(prevOpts), "DIFF-04 options restored: " + GMTestDiff04Text(prevOpts));
	LogChannel('GMTest', "SUMMARY diff04b hits: " + thePlayer.gmTestPassed + " passed, " + thePlayer.gmTestFailed + " failed");
}

// ---- progressive level bonuses ----

// Every sample matched to Geralt level p (Match) with the progressive options given: its level, its displayed
// level abilities (always level - 1) and its per-level abilities against legacy's count (and against a fixed
// figure when one is given).
function GMTestD04bProgCase(p : int, on : bool, ld : int, ad : int, fixed : int)
{
	var i, want, got : int;
	var npc : CNewNPC;
	var ok, all : bool;
	var s : string;

	GMTestDiff04Set(2, 0, 0, false, false);
	GMTestD04bSetProg(on, ld, ad);
	all = true;
	for(i = 0; i < thePlayer.gmTestD04Npcs.Size(); i += 1)
	{
		npc = thePlayer.gmTestD04Npcs[i];
		GMTestDiff04Recalc(npc, p, true);
		want = GMTestD04bWantAbls(p);
		got = GMTestD04bLevelAbls(npc);
		ok = npc.currentLevel == p && got == want && npc.GetAbilityCount('DisplayedLevelAbl') == p - 1 && (fixed <= 0 || got == fixed);
		all = all && ok;
		s += thePlayer.gmTestD04Label[i] + " " + got + GMTestD04If(!ok, " (level " + npc.currentLevel + ", displayed " + npc.GetAbilityCount('DisplayedLevelAbl') + ")") + "; ";
	}
	GMTestReport(all && thePlayer.gmTestD04Npcs.Size() >= 3, "DIFF-04 level " + p + ", progressive " + on + " LD " + ld + " AD " + ad + ": per-level bonuses, want " + GMTestD04bWantAbls(p)
		+ GMTestD04If(fixed > 0, " (legacy's figure " + fixed + ")") + ": " + s);
}

exec function gmtest_diff04b_prog()
{
	var prevOpts : array<string>;
	var i : int;

	prevOpts = GMTestDiff04Record();
	thePlayer.GMTestCount(true, true);
	GMTestD04bSetMods(0, 0, 0, 0);
	GMTestD04bProgCase(20, false, 10, 5, 19);
	GMTestD04bProgCase(30, false, 10, 5, 29);
	GMTestD04bProgCase(20, true, 10, 5, 24);
	GMTestD04bProgCase(30, true, 10, 5, 39);
	GMTestD04bProgCase(8, true, 10, 5, 7);
	GMTestD04bProgCase(10, true, 10, 5, 9);
	GMTestD04bProgCase(20, true, 0, 5, 19);
	GMTestD04bProgCase(20, true, 5, 10, 49);
	GMTestD04bProgCase(30, true, 20, 20, 39);
	GMTestDiff04Restore(prevOpts);
	for(i = 0; i < thePlayer.gmTestD04Npcs.Size(); i += 1)
		GMTestDiff04Recalc(thePlayer.gmTestD04Npcs[i], 10, true);
	GMTestReport(GMTestDiff04Text(GMTestDiff04Record()) == GMTestDiff04Text(prevOpts), "DIFF-04 options restored: " + GMTestDiff04Text(prevOpts));
	LogChannel('GMTest', "SUMMARY diff04b prog: " + thePlayer.gmTestPassed + " passed, " + thePlayer.gmTestFailed + " failed");
}

// ---- DD1 ----

// D5b's seven options cleared in memory: the samples get no modifier and level-1 per-level bonuses, as under the
// "Recommended" preset; and the options as the game reads them now.
exec function gmtest_diff04b_default()
{
	var prevOpts : array<string>;
	var o : array<name>;
	var i, want : int;
	var npc : CNewNPC;
	var ok, all : bool;
	var s, s2 : string;

	prevOpts = GMTestDiff04Record();
	thePlayer.GMTestCount(true, true);
	LogChannel('GMTest', "INFO DIFF-04 options as read before the check: " + GMTestDiff04Text(prevOpts));
	GMTestD04bRecordBase(20);
	o = GMTestDiff04Options();
	for(i = 5; i < o.Size(); i += 1)
		GMTestD04bSetCfg(o[i], "");
	for(i = 5; i < o.Size(); i += 1)
		s2 += NameToString(o[i]) + " '" + GMTestD04bCfg(o[i]) + "' default '" + GMOptionDefault('GMScalingOptions', o[i]) + "'; ";
	GMTestReport(GMOptionDefault('GMScalingOptions', 'GMNonlinearLevelup') == "false" && GMOptionDefault('GMScalingOptions', 'GMNonlinearLevelDelta') == "0"
		&& GMOptionDefault('GMScalingOptions', 'GMNonlinearAbilitiesDelta') == "0" && GMOptionDefault('GMScalingOptions', 'GMHealthMultiplier') == "0"
		&& GMOptionDefault('GMScalingOptions', 'GMDamageMultiplier') == "0" && GMOptionDefault('GMScalingOptions', 'GMBossHealthMultiplier') == "0"
		&& GMOptionDefault('GMScalingOptions', 'GMBossDamageMultiplier') == "0", "DIFF-04 DD1 the seven options' defaults are the Recommended preset's: " + s2);
	all = true;
	for(i = 0; i < thePlayer.gmTestD04Npcs.Size(); i += 1)
	{
		npc = thePlayer.gmTestD04Npcs[i];
		GMTestDiff04Recalc(npc, 20, true);
		s += GMTestD04bCheckMods(npc, thePlayer.gmTestD04bBaseHp[i], thePlayer.gmTestD04bBaseDmg[i], ok);
		want = npc.currentLevel - 1;
		ok = ok && GMTestD04bLevelAbls(npc) == want;
		s += ", per-level bonuses " + GMTestD04bLevelAbls(npc) + " (want " + want + "); ";
		all = all && ok;
	}
	GMTestReport(all && thePlayer.gmTestD04Npcs.Size() > 0, "DIFF-04 DD1 the seven options unset: no modifier, no progressive bonus: " + s);
	GMTestDiff04Restore(prevOpts);
	for(i = 0; i < thePlayer.gmTestD04Npcs.Size(); i += 1)
		GMTestDiff04Recalc(thePlayer.gmTestD04Npcs[i], 10, true);
	GMTestReport(GMTestDiff04Text(GMTestDiff04Record()) == GMTestDiff04Text(prevOpts), "DIFF-04 options restored: " + GMTestDiff04Text(prevOpts));
	LogChannel('GMTest', "SUMMARY diff04b default: " + thePlayer.gmTestPassed + " passed, " + thePlayer.gmTestFailed + " failed");
}

// ---- through the menu: presets and the instant re-level ----

exec function gmtest_diff04b_menu_a()
{
	var i : int;

	thePlayer.GMTestD04SetSaved(GMTestDiff04Record());
	LogChannel('GMTest', "INFO DIFF-04 options recorded: " + GMTestDiff04Text(thePlayer.gmTestD04Saved));
	GMTestD04bSpawn(true);
	for(i = 0; i < thePlayer.gmTestD04Npcs.Size(); i += 1)
		thePlayer.gmTestD04Npcs[i].GMTestSetBaseLevel(thePlayer.gmTestD04Base[i]);
	GetWitcherPlayer().GMTestSetLevelOverride(20);
	GetWitcherPlayer().SetImmortalityMode(AIM_Immortal, AIC_Default, true);
	LogChannel('GMTest', "INFO DIFF-04 Geralt held at level 20 and immortal; " + thePlayer.gmTestD04Npcs.Size() + " samples spawned (friendly, frozen)");
}

// Legacy's preset table: 0 Recommended, 1 Hardcore, 2 Off (modSignsConfig.xml).
function GMTestD04bPresetText(i : int) : string
{
	switch(i)
	{
		case 0: return "scaling=3 min=0 max=0 prog=false LD=0 AD=0 animals=false guards=false health=0 damage=0 bossHealth=0 bossDamage=0";
		case 1: return "scaling=1 min=0 max=0 prog=true LD=10 AD=5 animals=false guards=false health=0.5 damage=0.5 bossHealth=0.5 bossDamage=0.5";
		case 2: return "scaling=0 min=0 max=0 prog=false LD=0 AD=0 animals=false guards=false health=0 damage=0 bossHealth=0 bossDamage=0";
	}
	return "?";
}

function GMTestD04bPresetName(i : int) : string
{
	switch(i)
	{
		case 0: return "Recommended";
		case 1: return "Hardcore";
		case 2: return "Off";
	}
	return "?";
}

// The options as the preset table writes them (the numbers as the sliders store them).
function GMTestD04bOptionsText() : string
{
	return "scaling=" + GMTestD04bCfg('Virtual_GMScaling') + " min=" + GMTestD04bCfg('GMRandomScalingMinLevel') + " max=" + GMTestD04bCfg('GMRandomScalingMaxLevel')
		+ " prog=" + GMTestD04bCfg('GMNonlinearLevelup') + " LD=" + GMTestD04bCfg('GMNonlinearLevelDelta') + " AD=" + GMTestD04bCfg('GMNonlinearAbilitiesDelta')
		+ " animals=" + GMTestD04bCfg('GMNoAnimalUpscaling') + " guards=" + GMTestD04bCfg('GMNoAddLevelsGuards')
		+ " health=" + NoTrailZeros(GMTestD04bF('GMHealthMultiplier')) + " damage=" + NoTrailZeros(GMTestD04bF('GMDamageMultiplier'))
		+ " bossHealth=" + NoTrailZeros(GMTestD04bF('GMBossHealthMultiplier')) + " bossDamage=" + NoTrailZeros(GMTestD04bF('GMBossDamageMultiplier'));
}

// With the pause menu open: the preset applied through the menu's own event, as its Flash does.
exec function gmtest_diff04b_preset(i : int)
{
	var menu : CR4IngameMenu;

	menu = GMTestDiff04Menu();
	if(!menu)
	{
		LogChannel('GMTest', "FAIL DIFF-04 the options menu is not open");
		return;
	}
	menu.OnPresetApplied('GMScalingOptions', i);
	LogChannel('GMTest', "INFO DIFF-04 preset " + GMTestD04bPresetName(i) + " applied through the menu's event; options now " + GMTestD04bOptionsText() + "; close the menu to apply");
}

// Every sample at its level under the options as set, Geralt held at 20: level, per-level bonuses and modifiers.
function GMTestD04bSamplesOk(label : string) : bool
{
	var i, want, wantA, got : int;
	var npc : CNewNPC;
	var ok, okM, all : bool;
	var s : string;

	all = true;
	for(i = 0; i < thePlayer.gmTestD04Npcs.Size(); i += 1)
	{
		npc = thePlayer.gmTestD04Npcs[i];
		if(!npc)
			continue;
		want = GMTestDiff04Expected(npc, thePlayer.gmTestD04Base[i], 20, (int)GMTestD04bF('Virtual_GMScaling'), GMTestD04bCfg('GMNoAnimalUpscaling') == "true", GMTestD04bCfg('GMNoAddLevelsGuards') == "true");
		wantA = GMTestD04bWantAbls(want);
		got = GMTestD04bLevelAbls(npc);
		s += thePlayer.gmTestD04Label[i] + " level " + npc.currentLevel + " (want " + want + "), per-level bonuses " + got + " (want " + wantA + "), "
			+ GMTestD04bCheckMods(npc, thePlayer.gmTestD04bBaseHp[i], thePlayer.gmTestD04bBaseDmg[i], okM) + "; ";
		ok = okM && npc.currentLevel == want && got == wantA && !npc.GMTestLevelPending();
		all = all && ok;
	}
	GMTestReport(all && thePlayer.gmTestD04Npcs.Size() >= 4, "DIFF-04 " + label + ": " + s);
	return all;
}

// After the menu closed: the options are the preset's, and every sample was re-levelled by them at once.
exec function gmtest_diff04b_preset_check(i : int)
{
	thePlayer.GMTestCount(true, true);
	GMTestReport(GMTestD04bOptionsText() == GMTestD04bPresetText(i), "DIFF-04 preset " + GMTestD04bPresetName(i) + ": options " + GMTestD04bOptionsText() + " (legacy's table: " + GMTestD04bPresetText(i) + ")");
	GMTestD04bSamplesOk("after the preset " + GMTestD04bPresetName(i) + " at Geralt 20");
	LogChannel('GMTest', "SUMMARY diff04b preset: " + thePlayer.gmTestPassed + " passed, " + thePlayer.gmTestFailed + " failed");
}

// The baseline for the presets and the re-level checks: each sample's multipliers with no modifier (the mode's),
// read once with the samples spawned (Geralt held at 20).
exec function gmtest_diff04b_menu_base()
{
	var prev : array<string>;
	var i : int;

	prev = GMTestDiff04Record();
	GMTestD04bRecordBase(20);
	GMTestDiff04Restore(prev);
	for(i = 0; i < thePlayer.gmTestD04Npcs.Size(); i += 1)
		GMTestDiff04Recalc(thePlayer.gmTestD04Npcs[i], 20, true);
	GetWitcherPlayer().GMTestSetLevelOverride(20);	// GMTestDiff04Recalc clears it
	LogChannel('GMTest', "INFO DIFF-04 baseline multipliers recorded (" + thePlayer.gmTestD04bBaseHp.Size() + " samples)");
}

// The start of the re-level checks: Match, progressive off with LD 10 and AD 5, no modifiers (in memory); every
// sample recomputed at Geralt 20.
exec function gmtest_diff04b_relevel_start()
{
	var i : int;

	GMTestDiff04Set(2, 0, 0, false, false);
	GMTestD04bSetProg(false, 10, 5);
	GMTestD04bSetMods(0, 0, 0, 0);
	for(i = 0; i < thePlayer.gmTestD04Npcs.Size(); i += 1)
		GMTestDiff04Recalc(thePlayer.gmTestD04Npcs[i], 20, true);
	GetWitcherPlayer().GMTestSetLevelOverride(20);	// GMTestDiff04Recalc clears it
	thePlayer.GMTestCount(true, true);
	GMTestD04bSamplesOk("re-level start (Match, progressive off, LD 10, AD 5, no modifiers)");
	LogChannel('GMTest', "SUMMARY diff04b relevel start: " + thePlayer.gmTestPassed + " passed, " + thePlayer.gmTestFailed + " failed");
}

function GMTestD04bRelevelOption(k : int, out value : string) : name
{
	switch(k)
	{
		case 0: value = "true";	return 'GMNonlinearLevelup';
		case 1: value = "5";	return 'GMNonlinearLevelDelta';
		case 2: value = "10";	return 'GMNonlinearAbilitiesDelta';
		case 3: value = "0.3";	return 'GMHealthMultiplier';
		case 4: value = "0.2";	return 'GMDamageMultiplier';
		case 5: value = "0.5";	return 'GMBossHealthMultiplier';
		case 6: value = "-0.5";	return 'GMBossDamageMultiplier';
	}
	value = "";
	return '';
}

// With the pause menu open: option k set to its new value and the menu's own change event called.
exec function gmtest_diff04b_relevel_set(k : int)
{
	var menu : CR4IngameMenu;
	var option : name;
	var value : string;

	menu = GMTestDiff04Menu();
	if(!menu)
	{
		LogChannel('GMTest', "FAIL DIFF-04 the options menu is not open");
		return;
	}
	option = GMTestD04bRelevelOption(k, value);
	GMTestD04bSetCfg(option, value);
	menu.OnOptionValueChanged(theGame.GetInGameConfigWrapper().GetGroupIdx('GMScalingOptions'), option, value);
	LogChannel('GMTest', "INFO DIFF-04 " + NameToString(option) + " set to " + value + " through the menu's event; close the menu to apply");
}

exec function gmtest_diff04b_relevel_check(k : int)
{
	var option : name;
	var value : string;

	thePlayer.GMTestCount(true, true);
	option = GMTestD04bRelevelOption(k, value);
	GMTestReport(AbsF(GMTestD04bF(option) - StringToFloat(value)) < 0.001 || GMTestD04bCfg(option) == value, "DIFF-04 " + NameToString(option) + " reads the new value " + value + " ('" + GMTestD04bCfg(option) + "')");
	GMTestD04bSamplesOk("at once after " + NameToString(option) + " changed to " + value + " (" + GMTestD04bOptionsText() + ")");
	LogChannel('GMTest', "SUMMARY diff04b relevel " + k + ": " + thePlayer.gmTestPassed + " passed, " + thePlayer.gmTestFailed + " failed");
}

exec function gmtest_diff04b_menu_c()
{
	GMTestDiff04Restore(thePlayer.gmTestD04Saved);
	theGame.SaveUserSettings();
	GetWitcherPlayer().GMTestSetLevelOverride(0);
	GetWitcherPlayer().SetImmortalityMode(AIM_None, AIC_Default, true);
	thePlayer.GMTestDummyClearAll();
	thePlayer.GMTestD04Clear();
	GMOnScalingOptionsChanged();
	LogChannel('GMTest', "INFO DIFF-04 options restored (" + GMTestDiff04Text(GMTestDiff04Record()) + "), Geralt back at " + thePlayer.GetLevel() + ", mortal, NPCs re-levelled");
}

// ---- in the regression (called by GMTest_diff04 with its bandit, options set back by the caller) ----

// The bandit matched to Geralt 20 under the Hardcore preset's modifiers and progressive bonuses: 24 per-level
// bonuses, the mode's multipliers x1.5; with the boss tag added, x2; the tag removed again.
function GMTestDiff04bRegress(bandit : CNewNPC)
{
	var hp0, dmg0 : float;
	var ok, okBoss : bool;
	var s, sBoss : string;

	GMTestDiff04Set(2, 0, 0, false, false);
	GMTestD04bSetProg(false, 0, 0);
	GMTestD04bSetMods(0, 0, 0, 0);
	bandit.GMTestSetBaseLevel(2);
	GMTestDiff04Recalc(bandit, 20, true);
	GMTestD04bRead(bandit, hp0, dmg0);
	GMTestD04bSetProg(true, 10, 5);
	GMTestD04bSetMods(0.5, 0.5, 0.5, 0.5);
	GMTestDiff04Recalc(bandit, 20, true);
	s = GMTestD04bCheckMods(bandit, hp0, dmg0, ok);
	ok = ok && GMTestD04bLevelAbls(bandit) == 24 && bandit.currentLevel == 20;
	bandit.AddTag('HideHealthBarModule');
	GMTestDiff04Recalc(bandit, 20, true);
	sBoss = GMTestD04bCheckMods(bandit, hp0, dmg0, okBoss);
	okBoss = okBoss && AbsF(GMTestD04bStepSum(bandit, true) - hp0) < 0.002;	// x(1 + 0.5 + 0.5): the steps add the mode's multiplier once more
	bandit.RemoveTag('HideHealthBarModule');
	GMTestReport(ok, "DIFF-04 Hardcore modifiers and progressive bonuses on a bandit at Geralt 20: per-level bonuses " + GMTestD04bLevelAbls(bandit) + " (24); " + s);
	GMTestReport(okBoss, "DIFF-04 the same bandit with the boss bar tag: " + sBoss);
}

// ---- the modifiers and progressive bonuses across a save and a load (DIFF audit F4) ----
// Only into the test-only slot whose file name contains the key given (ManualSave_8559a_7ea4f400_...): never
// another save. Load the slot (Geralt at level 20; setlevel(20) in the test save wrote an autosave), then:
//   gmtest_diff04_lsave_a()          the "Hardcore" preset's values in memory (Upscale, progressive 10 and 5, +50%
//                                    health and damage, +50% more for bosses); a persistent friendly frozen bandit and
//                                    mh102's arachas (boss bar from its spawn); their levels come by timer
//   gmtest_diff04_lsave_b()          each holds one set of step abilities and its per-level count; both recorded in facts
//   gmtest_diff04_lsave_save(key)    saves over the one manual save whose name contains key (none or several: nothing)
//   (game.py load <the slot's new name>)
//   gmtest_diff04_lsave_c()          as loaded, at the fight's start (RecalcLevel) and at a full recompute (as a level-up
//                                    or an option change): one set each time, the recorded counts
//   gmtest_diff04_lsave_d()          removes them and their facts, restores the options (recorded on CR4Game)

@addField(CR4Game)
var gmTestLsaveOpts : array<string>;

@addMethod(CR4Game)
function GMTestLsaveSetOpts(v : array<string>)
{
	gmTestLsaveOpts = v;
}

function GMTestLsaveTag(i : int) : name
{
	if(i == 0)
		return 'gmtest_d04_ls0';
	return 'gmtest_d04_ls1';
}

function GMTestLsaveSpawn(path : string, distance : float, tag : name)
{
	var template : CEntityTemplate;
	var npc : CNewNPC;
	var tags : array<name>;

	template = (CEntityTemplate)LoadResource(path, true);
	tags.PushBack(tag);
	npc = (CNewNPC)theGame.CreateEntity(template, thePlayer.GetWorldPosition() + thePlayer.GetHeadingVector() * distance, VecToRotation(-thePlayer.GetHeadingVector()), true, false, false, PM_Persist, tags);
	if(npc)
	{
		npc.SetTemporaryAttitudeGroup('friendly_to_player', AGP_Default);
		npc.SetAnimationSpeedMultiplier(0.001);
	}
	else
		LogChannel('GMTest', "FAIL DIFF-04 save check: " + path + " did not spawn");
}

exec function gmtest_diff04_lsave_a()
{
	var npc : CNewNPC;
	var i : int;

	for(i = 0; i < 2; i += 1)	// an earlier run's samples, kept by the slot
	{
		npc = (CNewNPC)theGame.GetEntityByTag(GMTestLsaveTag(i));
		if(npc)
			npc.Destroy();
	}
	theGame.GMTestLsaveSetOpts(GMTestDiff04Record());
	GMTestDiff04Set(1, 0, 0, false, false);
	GMTestD04bSetProg(true, 10, 5);
	GMTestD04bSetMods(0.5, 0.5, 0.5, 0.5);
	GMTestLsaveSpawn(GMTestDummyTemplate("human"), 5, GMTestLsaveTag(0));
	GMTestLsaveSpawn(GMTestD04bBossPath(), 10, GMTestLsaveTag(1));
	LogChannel('GMTest', "INFO DIFF-04 save check: Hardcore values set in memory (options before: " + GMTestDiff04Text(theGame.gmTestLsaveOpts) + "), Geralt " + thePlayer.GetLevel()
		+ ", a persistent bandit and arachas spawned; read them in a later call");
}

// One sample against the options as set and the mode: one set of step abilities (GMTestD04bCheckMods) and the
// per-level count wantAbls.
function GMTestLsaveCheck(npc : CNewNPC, wantAbls : int, label : string)
{
	var baseHp, baseDmg : float;
	var okMods : bool;
	var s : string;

	GMTestDiffWant(theGame.GetSpawnDifficultyMode(), baseHp, baseDmg);
	s = GMTestD04bCheckMods(npc, baseHp, baseDmg, okMods);
	GMTestReport(okMods && GMTestD04bLevelAbls(npc) == wantAbls && wantAbls > 0, "DIFF-04 save check, " + label + ": per-level " + GMTestD04bLevelAbls(npc) + " (" + wantAbls + "), level "
		+ npc.currentLevel + ", shown " + npc.GetLevel() + ", restored " + npc.gmTestSpawnRestored + "; " + s);
}

exec function gmtest_diff04_lsave_b()
{
	var npc : CNewNPC;
	var i : int;

	thePlayer.GMTestCount(true, true);
	for(i = 0; i < 2; i += 1)
	{
		npc = (CNewNPC)theGame.GetEntityByTag(GMTestLsaveTag(i));
		if(!npc)
		{
			GMTestReport(false, "DIFF-04 save check: sample " + i + " not found");
			continue;
		}
		GMTestLsaveCheck(npc, GMTestD04bWantAbls(npc.currentLevel), "before the save");
		FactsRemove("gmtest_d04_ls_abls" + i);
		FactsAdd("gmtest_d04_ls_abls" + i, GMTestD04bLevelAbls(npc));
		FactsRemove("gmtest_d04_ls_lvl" + i);
		FactsAdd("gmtest_d04_ls_lvl" + i, npc.currentLevel);
	}
	LogChannel('GMTest', "SUMMARY diff04 lsave before: " + thePlayer.gmTestPassed + " passed, " + thePlayer.gmTestFailed + " failed");
}

exec function gmtest_diff04_lsave_save(key : string)
{
	var saves : array<SSavegameInfo>;
	var i, n, found : int;

	theGame.ListSavedGames(saves);
	for(i = 0; i < saves.Size(); i += 1)
		if(StrFindFirst(saves[i].filename, key) >= 0 && saves[i].slotType == SGT_Manual)
		{
			n += 1;
			found = i;
		}
	if(n != 1 || StrLen(key) < 8)
	{
		LogChannel('GMTest', "FAIL DIFF-04 save check: " + n + " manual saves match '" + key + "' (one needed); nothing saved");
		return;
	}
	LogChannel('GMTest', "INFO DIFF-04 save check: saving over the test-only slot " + saves[found].filename + " (slot " + saves[found].slotIndex + ")");
	theGame.SaveGame(SGT_Manual, saves[found].slotIndex);
}

exec function gmtest_diff04_lsave_c()
{
	var npc : CNewNPC;
	var i, wantAbls, wantLvl : int;

	thePlayer.GMTestCount(true, true);
	LogChannel('GMTest', "INFO DIFF-04 save check after the load: options " + GMTestDiff04Text(GMTestDiff04Record()) + ", Geralt " + thePlayer.GetLevel());
	for(i = 0; i < 2; i += 1)
	{
		npc = (CNewNPC)theGame.GetEntityByTag(GMTestLsaveTag(i));
		wantAbls = FactsQuerySum("gmtest_d04_ls_abls" + i);
		wantLvl = FactsQuerySum("gmtest_d04_ls_lvl" + i);
		if(!npc)
		{
			GMTestReport(false, "DIFF-04 save check: sample " + i + " not found after the load");
			continue;
		}
		GMTestReport(npc.gmTestSpawnRestored == 1, "DIFF-04 save check: sample " + i + " restored from the save (" + npc.gmTestSpawnRestored + ")");
		GMTestLsaveCheck(npc, wantAbls, "as loaded");
		npc.RecalcLevel();	// the fight's start
		GMTestLsaveCheck(npc, wantAbls, "at the fight's start");
		GMTestReport(npc.currentLevel == wantLvl, "DIFF-04 save check: level at the fight's start " + npc.currentLevel + " (before the save " + wantLvl + ")");
		npc.GMTestFreshLevel();	// a full recompute, as Geralt's level-up or an option change
		npc.RecalcLevel();
		GMTestLsaveCheck(npc, wantAbls, "at a full recompute");
	}
	LogChannel('GMTest', "SUMMARY diff04 lsave after: " + thePlayer.gmTestPassed + " passed, " + thePlayer.gmTestFailed + " failed");
}

exec function gmtest_diff04_lsave_d()
{
	var npc : CNewNPC;
	var i : int;

	for(i = 0; i < 2; i += 1)
	{
		npc = (CNewNPC)theGame.GetEntityByTag(GMTestLsaveTag(i));
		if(npc)
			npc.Destroy();
		FactsRemove("gmtest_d04_ls_abls" + i);
		FactsRemove("gmtest_d04_ls_lvl" + i);
	}
	if(theGame.gmTestLsaveOpts.Size() > 0)
		GMTestDiff04Restore(theGame.gmTestLsaveOpts);
	GMOnScalingOptionsChanged();
	LogChannel('GMTest', "INFO DIFF-04 save check: samples removed, options " + GMTestDiff04Text(GMTestDiff04Record()) + " (recorded " + theGame.gmTestLsaveOpts.Size() + ")");
}
