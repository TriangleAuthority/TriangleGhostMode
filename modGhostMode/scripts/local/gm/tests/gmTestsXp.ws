// XP: experience and levels (docs/features/xp.md).
//
// In the regression: GMTest_xpdata() (the generated data table, tests/gmTestsXpData.ws, tools/gen_xp.py: XP-08's
// level abilities and XP-05's experience nodes as the game reads them) and GMTest_xp05() (no script reads an NPC's
// experience attribute: a kill's experience is the same with +1000 experience on the NPC).
//
// Not in the regression (they change Geralt): gmtest_xp08_levels(to) levels Geralt up from his level to `to` through
// the level manager's own path (W3LevelManager.AddPoints with the experience the next level needs, which adds each
// level's Lvl<n> ability) and checks what each level adds; gmtest_xp08_parts() reads what Geralt's level abilities
// give him now (for a loaded save). Quit without saving afterwards.

function GMTestXpNode(abl : name, attr : name, base : float, mult : float, add : float, out checks : int) : int
{
	var b, m, a : float;

	checks += 1;
	GMTestAiAbl(abl, attr, b, m, a);
	if(AbsF(b - base) < 0.001 && AbsF(m - mult) < 0.0001 && AbsF(a - add) < 0.001)
		return 0;
	LogChannel('GMTest', "FAIL XP data " + abl + "." + attr + " reads " + NoTrailZeros(b) + "/" + NoTrailZeros(m) + "/" + NoTrailZeros(a)
		+ " (legacy's " + NoTrailZeros(base) + "/" + NoTrailZeros(mult) + "/" + NoTrailZeros(add) + ")");
	return 1;
}

exec function gmtest_xpdata()
{
	thePlayer.GMTestCount(true, true);
	GMTest_xpdata();
	GMTest_xp05();
	LogChannel('GMTest', "SUMMARY xpdata: " + thePlayer.gmTestPassed + " passed, " + thePlayer.gmTestFailed + " failed");
}

// XP-08, XP-05: the definitions as the game reads them. 5.x: Lvl2 to Lvl50 Vitality 100 falling to 25, attack power
// +4 to +1, spell power +2% to +0.1%; its experience nodes (MonsterMHBoss 50, sq201_werewolf 44, ConAthletic +10, ...).
function GMTest_xpdata()
{
	var f, checks : int;

	f = GMTestXpDataAll(checks);
	GMTestReport(f == 0 && checks == GMTestXpDataLevelChecks() + GMTestXpDataExpChecks(), "XP-08/XP-05 data: " + checks
		+ " attributes read as legacy's (" + GMTestXpDataLevelChecks() + " of the level abilities: Lvl2 to Lvl50 Vitality 50, no attack or spell power; XP-09's GMLvlNew2 to GMLvlNew100 150 on levels 3 to 48 divisible by 3, else 0; "
		+ GMTestXpDataExpChecks() + " enemy experience nodes); " + f + " differ");
}

// The experience attribute an NPC has, summed over its abilities.
function GMTestXpNpcExp(npc : CNewNPC) : float
{
	var tags : array<name>;

	return CalculateAttributeValue(npc.GetCharacterStats().GetAttributeValue('experience', tags));
}

// XP-05 (PX7): no script reads the experience node. A frozen friendly bandit and drowner 30 m behind Geralt: their
// kill experience (CalculateExperiencePoints with skipLog: XP-04 counts no kill) with and without a test ability that
// adds +1000 experience and nothing else; the attribute itself moves by 1000.
function GMTest_xp05()
{
	var paths : array<string>;
	var npc : CNewNPC;
	var i, before, after : int;
	var e0, e1 : float;

	paths.PushBack("dlc\dlc7\data\characters\sq107_bandit_lvl1_mortal.w2ent");
	paths.PushBack("characters\npc_entities\monsters\drowner_lvl1.w2ent");
	for(i = 0; i < paths.Size(); i += 1)
	{
		npc = GMTestAi06Spawn(paths[i], 30 + 3 * i);
		if(!npc)
		{
			GMTestReport(false, "XP-05 sample " + paths[i] + " spawned");
			continue;
		}
		npc.SetLevel(GetWitcherPlayer().GetLevel() + 10);	// a kill worth more than the minimum
		npc.RecalcLevel();
		e0 = GMTestXpNpcExp(npc);
		before = npc.CalculateExperiencePoints(true);
		npc.AddAbility('GMTD_experience_p1000', true);
		e1 = GMTestXpNpcExp(npc);
		after = npc.CalculateExperiencePoints(true);
		npc.RemoveAbility('GMTD_experience_p1000');
		GMTestReport(AbsF(e1 - e0 - 1000) < 0.01 && before == after && before > 1, "XP-05 " + npc.GetDisplayName(false)
			+ " (level " + npc.GetLevel() + "): experience attribute " + NoTrailZeros(e0) + " -> " + NoTrailZeros(e1)
			+ ", kill experience " + before + " -> " + after + " (unchanged: nothing reads the node)");
		npc.Destroy();
	}
}

// What Geralt's level abilities give him: each Lvl<n> he holds is taken away and given back, and the change in his
// maximum Vitality, attack power and spell power is read. Vitality is put back as it was.
function GMTestXpLevelParts(out vit : float, out ap : SAbilityAttributeValue, out sp : SAbilityAttributeValue, out held : int, out missing : string)
{
	var w : W3PlayerWitcher;
	var stats : CCharacterStats;
	var counts : array<int>;
	var names : array<name>;
	var i, lvl : int;
	var v0, cur : float;
	var a0, s0, a1, s1 : SAbilityAttributeValue;

	w = GetWitcherPlayer();
	stats = w.GetCharacterStats();
	lvl = w.GetLevel();
	cur = w.GetStat(BCS_Vitality);
	v0 = w.GetStatMax(BCS_Vitality);
	a0 = w.GetPowerStatValue(CPS_AttackPower);
	s0 = w.GetPowerStatValue(CPS_SpellPower);
	held = 0;
	missing = "";
	for(i = 2; i <= 100; i += 1)
	{
		names.PushBack(w.GetLevelupAbility(i));
		counts.PushBack(stats.GetAbilityCount(names[i - 2]));
		if(counts[i - 2] > 0)
			held += 1;
		else if(i <= lvl && names[i - 2] != '')
			missing += " " + names[i - 2];
		if(counts[i - 2] > 0)
			stats.RemoveAbilityAll(names[i - 2]);
	}
	vit = v0 - w.GetStatMax(BCS_Vitality);
	a1 = w.GetPowerStatValue(CPS_AttackPower);
	s1 = w.GetPowerStatValue(CPS_SpellPower);
	ap.valueBase = a0.valueBase - a1.valueBase;
	ap.valueMultiplicative = a0.valueMultiplicative - a1.valueMultiplicative;
	ap.valueAdditive = a0.valueAdditive - a1.valueAdditive;
	sp.valueBase = s0.valueBase - s1.valueBase;
	sp.valueMultiplicative = s0.valueMultiplicative - s1.valueMultiplicative;
	sp.valueAdditive = s0.valueAdditive - s1.valueAdditive;
	for(i = 0; i < names.Size(); i += 1)
		if(counts[i] > 0)
			stats.AddAbilityMultiple(names[i], counts[i]);
	GMTestReport(AbsF(w.GetStatMax(BCS_Vitality) - v0) < 0.01, "XP-08 maximum Vitality " + NoTrailZeros(v0)
		+ " as the definitions give it (recomputed after taking the level abilities away and back: " + NoTrailZeros(w.GetStatMax(BCS_Vitality)) + ")");
	w.ForceSetStat(BCS_Vitality, MinF(cur, w.GetStatMax(BCS_Vitality)));
}

function GMTestXpValText(v : SAbilityAttributeValue) : string
{
	return NoTrailZeros(v.valueBase) + "/" + NoTrailZeros(v.valueMultiplicative) + "/" + NoTrailZeros(v.valueAdditive);
}

function GMTestXpZero(v : SAbilityAttributeValue) : bool
{
	return AbsF(v.valueBase) < 0.0001 && AbsF(v.valueMultiplicative) < 0.0001 && AbsF(v.valueAdditive) < 0.0001;
}

function GMTestXpTree() : string
{
	if(GMIsClassicSkillTree())
		return "classic tree";
	return "new tree";
}

// XP-08 on a loaded save with the classic tree's level abilities (gmtest_xp09_load for the new tree's): Geralt holds Lvl2 to Lvl<his level> by name, and they give legacy's values now: +50
// Vitality each (950 at level 20), no attack power, no spell power.
exec function gmtest_xp08_parts()
{
	var vit : float;
	var ap, sp : SAbilityAttributeValue;
	var held, lvl : int;
	var missing : string;

	thePlayer.GMTestCount(true, true);
	lvl = GetWitcherPlayer().GetLevel();
	GMTestXpLevelParts(vit, ap, sp, held, missing);
	GMTestReport(missing == "" && held == Min(lvl, 50) - 1, "XP-08 level " + lvl + " (" + GMTestXpTree() + "): Geralt holds " + held + " level abilities (Lvl2 to Lvl" + Min(lvl, 50) + ")" + missing);
	GMTestReport(AbsF(vit - GMTestXp09LevelVit(lvl, false)) < 0.01, "XP-08 level " + lvl + ": the level abilities give " + NoTrailZeros(vit) + " maximum Vitality (legacy " + NoTrailZeros(GMTestXp09LevelVit(lvl, false)) + ")");
	GMTestReport(GMTestXpZero(ap) && GMTestXpZero(sp), "XP-08 level " + lvl + ": they give no attack power (" + GMTestXpValText(ap) + ") and no spell power (" + GMTestXpValText(sp) + ")");
	GMTestXpLogStats("now");
	LogChannel('GMTest', "SUMMARY xp08_parts: " + thePlayer.gmTestPassed + " passed, " + thePlayer.gmTestFailed + " failed");
}

function GMTestXpLogStats(label : string)
{
	var w : W3PlayerWitcher;

	w = GetWitcherPlayer();
	LogChannel('GMTest', "INFO XP-08 " + label + ": level " + w.GetLevel() + ", maximum Vitality " + NoTrailZeros(w.GetStatMax(BCS_Vitality))
		+ ", attack power " + GMTestXpValText(w.GetPowerStatValue(CPS_AttackPower)) + ", spell power " + GMTestXpValText(w.GetPowerStatValue(CPS_SpellPower))
		+ ", skill points " + w.levelManager.GetPointsTotal(ESkillPoint));
}

// XP-08: level-ups by the level manager's path, from Geralt's level to `to` (at most 100): each level from 2 to 50
// adds 50 to his maximum Vitality, every level past 50 nothing, and no level changes his attack power or spell power.
// Logs his stats at levels 10, 20 and 50.
exec function gmtest_xp08_levels(to : int)
{
	var w : W3PlayerWitcher;
	var lm : W3LevelManager;
	var lvl, need, badVit, badPow, n : int;
	var v0, v1, want : float;
	var a0, s0, a1, s1 : SAbilityAttributeValue;
	var bad : string;

	thePlayer.GMTestCount(true, true);
	w = GetWitcherPlayer();
	lm = w.levelManager;
	GMTestXpLogStats("start");
	while(lm.GetLevel() < Min(to, lm.GetMaxLevel()))
	{
		lvl = lm.GetLevel();
		v0 = w.GetStatMax(BCS_Vitality);
		a0 = w.GetPowerStatValue(CPS_AttackPower);
		s0 = w.GetPowerStatValue(CPS_SpellPower);
		need = lm.GetTotalExpForNextLevel() - lm.GetPointsTotal(EExperiencePoint);
		lm.AddPoints(EExperiencePoint, Max(1, need), false);
		if(lm.GetLevel() != lvl + 1)
		{
			GMTestReport(false, "XP-08 one level-up from " + lvl + " (now " + lm.GetLevel() + ")");
			break;
		}
		n += 1;
		v1 = w.GetStatMax(BCS_Vitality);
		a1 = w.GetPowerStatValue(CPS_AttackPower);
		s1 = w.GetPowerStatValue(CPS_SpellPower);
		want = GMTestXp09Vit(lvl + 1, GMTestXp09NewRule());	// XP-09: the new tree's rule
		if(AbsF(v1 - v0 - want) > 0.01)
		{
			badVit += 1;
			bad += " " + (lvl + 1) + ":+" + NoTrailZeros(v1 - v0);
		}
		if(AbsF(a1.valueBase - a0.valueBase) > 0.0001 || AbsF(a1.valueMultiplicative - a0.valueMultiplicative) > 0.0001 || AbsF(a1.valueAdditive - a0.valueAdditive) > 0.0001
			|| AbsF(s1.valueBase - s0.valueBase) > 0.0001 || AbsF(s1.valueMultiplicative - s0.valueMultiplicative) > 0.0001 || AbsF(s1.valueAdditive - s0.valueAdditive) > 0.0001)
		{
			badPow += 1;
			if(badPow <= 3)
				LogChannel('GMTest', "INFO XP-08 level " + (lvl + 1) + ": attack power " + GMTestXpValText(a0) + " -> " + GMTestXpValText(a1) + ", spell power " + GMTestXpValText(s0) + " -> " + GMTestXpValText(s1));
		}
		if(lvl + 1 == 10 || lvl + 1 == 20 || lvl + 1 == 50)
			GMTestXpLogStats("reached");
	}
	GMTestXpLogStats("end");
	GMTestReport(n > 0 && badVit == 0, "XP-08 (" + GMTestXp09TreeName(GMTestXp09NewRule()) + ") " + n + " level-ups to " + lm.GetLevel() + ": maximum Vitality per level by the tree (classic +50 to 50; new +150 on 3, 6, ..., 48), none past 50; " + badVit + " differ" + bad);
	GMTestReport(n > 0 && badPow == 0, "XP-08 (" + GMTestXpTree() + ") " + n + " level-ups: attack power and spell power unchanged by every level; " + badPow + " differ");
	LogChannel('GMTest', "SUMMARY xp08_levels: " + thePlayer.gmTestPassed + " passed, " + thePlayer.gmTestFailed + " failed");
}
