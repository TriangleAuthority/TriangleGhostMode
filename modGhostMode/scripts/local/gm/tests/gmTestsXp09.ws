// XP-09: the new tree's skill-point income (docs/features/xp.md, DX1 (a), DX2 (a)). Not in the regression: they change
// Geralt; run them from a freshly loaded save and quit without saving.
//
// gmtest_xp09_levels(to): level-ups by the level manager's own path (AddPoints with the experience the next level
//   needs) from Geralt's level to `to`; after each level the skill points and the maximum Vitality it added, the skill
//   slots and the skill mutagen slots, against the rule of the tree whose profile Geralt has: the new tree no point
//   on every level divisible by 3 and +150 Vitality on 3, 6, ..., 48, nothing else; the classic tree a point every
//   level and +50 Vitality to 50. From level 1 also the totals at 20 and 50.
// gmtest_xp09_prep(other, pct): gives `other` skill points from another source and sets Vitality to pct % (before a
//   tree switch); gmtest_xp09_tree() after gmreset(): the level points and level abilities of the tree in force, the
//   other points kept, the Vitality percentage kept.
// gmtest_xp09_pop_a/b/c(): a Place of Power (place_of_power_quen.w2ent, spawned behind Geralt) activated through its
//   own state: +1 skill point whatever the level's rule.
// gmtest_xp09_load(): on a loaded save, which level abilities Geralt holds and what his points are.
//
// The checks only read the game and the definitions: they compile without XP-09's code (the throwaway build).

@addField(W3PlayerWitcher)
var gmTestXp09Other : int;
@addField(W3PlayerWitcher)
var gmTestXp09Pct : float;
@addField(W3PlayerWitcher)
var gmTestXp09Pop : CEntity;
@addField(W3PlayerWitcher)
var gmTestXp09Points : int;

// The rule the test expects: the tree whose profile Geralt has (SKL-02's facts), else the option.
function GMTestXp09NewRule() : bool
{
	if(FactsQuerySum("gm_skill_tree_set") > 0)
		return FactsQuerySum("gm_skill_tree_classic") < 1;
	return !GMIsClassicSkillTree();
}

function GMTestXp09TreeName(newRule : bool) : string
{
	if(newRule)
		return "new tree";
	return "classic tree";
}

// DX1 (a), DX2 (a), worked independently of the mod's code.
function GMTestXp09Point(lvl : int, newRule : bool) : int
{
	if(newRule && lvl % 3 == 0)
		return 0;
	return 1;
}

function GMTestXp09Vit(lvl : int, newRule : bool) : float
{
	if(lvl > 50)
		return 0;
	if(!newRule)
		return 50;
	if(lvl % 3 == 0)
		return 150;
	return 0;
}

function GMTestXp09LevelPoints(lvl : int, newRule : bool) : int
{
	var i, t : int;

	for(i = 2; i <= lvl; i += 1)
		t += GMTestXp09Point(i, newRule);
	return t;
}

function GMTestXp09LevelVit(lvl : int, newRule : bool) : float
{
	var i : int;
	var t : float;

	for(i = 2; i <= lvl; i += 1)
		t += GMTestXp09Vit(i, newRule);
	return t;
}

// Skill mutagen slots unlocked as the game says (IsSkillMutagenSlotUnlocked) and as the level says (1.32, legacy).
function GMTestXp09MutagenSlots(out expected : int) : int
{
	var w : W3PlayerWitcher;
	var pam : W3PlayerAbilityManager;
	var slots : array<SMutagenSlot>;
	var i, unlocked : int;

	w = GetWitcherPlayer();
	pam = (W3PlayerAbilityManager)w.abilityManager;
	slots = pam.GetPlayerSkillMutagens();
	expected = 0;
	for(i = 0; i < slots.Size(); i += 1)
	{
		if(pam.IsSkillMutagenSlotUnlocked(slots[i].equipmentSlot))
			unlocked += 1;
		if(w.GetLevel() >= slots[i].unlockedAtLevel)
			expected += 1;
	}
	return unlocked;
}

function GMTestXp09Row(label : string, newRule : bool, startLevel : int, gainedPoints : int, gainedVit : float)
{
	var w : W3PlayerWitcher;

	w = GetWitcherPlayer();
	LogChannel('GMTest', "INFO XP-09 " + label + " (" + GMTestXp09TreeName(newRule) + "): level " + w.GetLevel() + ", points from levels "
		+ startLevel + "->" + w.GetLevel() + " " + gainedPoints + ", level Vitality " + NoTrailZeros(gainedVit) + ", skill points total "
		+ w.levelManager.GetPointsTotal(ESkillPoint) + ", maximum Vitality " + NoTrailZeros(w.GetStatMax(BCS_Vitality)));
}

exec function gmtest_xp09_levels(to : int)
{
	var w : W3PlayerWitcher;
	var lm : W3LevelManager;
	var pam : W3PlayerAbilityManager;
	var newRule : bool;
	var start, lvl, need, n, p0, dp, gained, badPts, badVit, badSlots, badMut, sl, slExp, mu, muExp : int;
	var v0, dv, gainedVit : float;
	var bad, badP, badS : string;

	thePlayer.GMTestCount(true, true);
	w = GetWitcherPlayer();
	lm = w.levelManager;
	pam = (W3PlayerAbilityManager)w.abilityManager;
	newRule = GMTestXp09NewRule();
	start = lm.GetLevel();
	GMTestXp09Row("start", newRule, start, 0, 0);
	while(lm.GetLevel() < Min(to, lm.GetMaxLevel()))
	{
		lvl = lm.GetLevel() + 1;
		p0 = lm.GetPointsTotal(ESkillPoint);
		v0 = w.GetStatMax(BCS_Vitality);
		need = lm.GetTotalExpForNextLevel() - lm.GetPointsTotal(EExperiencePoint);
		lm.AddPoints(EExperiencePoint, Max(1, need), false);
		if(lm.GetLevel() != lvl)
		{
			GMTestReport(false, "XP-09 one level-up to " + lvl + " (now " + lm.GetLevel() + ")");
			break;
		}
		n += 1;
		dp = lm.GetPointsTotal(ESkillPoint) - p0;
		dv = w.GetStatMax(BCS_Vitality) - v0;
		gained += dp;
		gainedVit += dv;
		if(dp != GMTestXp09Point(lvl, newRule))
		{
			badPts += 1;
			badP += " " + lvl + ":+" + dp;
		}
		if(AbsF(dv - GMTestXp09Vit(lvl, newRule)) > 0.01)
		{
			badVit += 1;
			bad += " " + lvl + ":+" + NoTrailZeros(dv);
		}
		sl = pam.GMTestCountSkillSlots(lvl, slExp);
		mu = GMTestXp09MutagenSlots(muExp);
		if(sl != slExp || mu != muExp)
		{
			badSlots += 1;
			badS += " " + lvl + ":" + sl + "/" + slExp + "," + mu + "/" + muExp;
		}
		if(lvl == 10 || lvl == 20 || lvl == 30 || lvl == 50 || lvl == 60)
			GMTestXp09Row("reached", newRule, start, gained, gainedVit);
		if(start == 1 && (lvl == 20 || lvl == 50 || lvl == 60))
		{
			GMTestReport(gained == GMTestXp09LevelPoints(lvl, newRule) && AbsF(gainedVit - GMTestXp09LevelVit(lvl, newRule)) < 0.01,
				"XP-09 (" + GMTestXp09TreeName(newRule) + ") at level " + lvl + ": " + gained + " skill points and " + NoTrailZeros(gainedVit)
				+ " Vitality from levels (expected " + GMTestXp09LevelPoints(lvl, newRule) + " and " + NoTrailZeros(GMTestXp09LevelVit(lvl, newRule)) + ")");
		}
	}
	GMTestReport(n > 0 && badPts == 0, "XP-09 (" + GMTestXp09TreeName(newRule) + ") " + n + " level-ups to " + lm.GetLevel()
		+ ": skill points per level by the tree's rule; " + badPts + " differ" + badP);
	GMTestReport(n > 0 && badVit == 0, "XP-09 (" + GMTestXp09TreeName(newRule) + ") " + n + " level-ups: maximum Vitality per level by the tree's rule; "
		+ badVit + " differ" + bad);
	GMTestReport(n > 0 && badSlots == 0, "XP-09 (" + GMTestXp09TreeName(newRule) + ") " + n + " level-ups: skill slots and skill mutagen slots by level (SKL-01); "
		+ badSlots + " differ" + badS);
	LogChannel('GMTest', "SUMMARY xp09_levels: " + thePlayer.gmTestPassed + " passed, " + thePlayer.gmTestFailed + " failed");
}

function GMTestXp09Has(o : CObject) : bool
{
	if(o)
		return true;
	return false;
}

@addMethod(W3PlayerWitcher)
function GMTestXp09Set(other : int, pct : float, pop : CEntity, pts : int)
{
	gmTestXp09Other = other;
	gmTestXp09Pct = pct;
	gmTestXp09Pop = pop;
	gmTestXp09Points = pts;
}

// Points from another source (as a Place of Power gives them) and Vitality at pct % of its maximum, before a reset.
exec function gmtest_xp09_prep(other : int, pct : float)
{
	var w : W3PlayerWitcher;

	w = GetWitcherPlayer();
	if(other > 0)
		w.levelManager.AddPoints(ESkillPoint, other, false);
	w.ForceSetStat(BCS_Vitality, w.GetStatMax(BCS_Vitality) * pct / 100);
	w.GMTestXp09Set(w.gmTestXp09Other + other, 100 * w.GetStat(BCS_Vitality) / w.GetStatMax(BCS_Vitality), NULL, 0);
	LogChannel('GMTest', "INFO XP-09 prep: level " + w.GetLevel() + ", skill points " + w.levelManager.GetPointsFree(ESkillPoint) + " free, "
		+ w.levelManager.GetPointsUsed(ESkillPoint) + " used, " + w.gmTestXp09Other + " from other sources; Vitality " + NoTrailZeros(w.GetStat(BCS_Vitality))
		+ " of " + NoTrailZeros(w.GetStatMax(BCS_Vitality)));
}

// The level abilities Geralt holds for his levels: of the classic tree (Lvl<n>) and of the new tree (GMLvlNew<n>).
function GMTestXp09Held(out classic : int, out newTree : int, out wrong : string, newRule : bool)
{
	var w : W3PlayerWitcher;
	var stats : CCharacterStats;
	var i : int;
	var c, nt : name;

	w = GetWitcherPlayer();
	stats = w.GetCharacterStats();
	classic = 0;
	newTree = 0;
	wrong = "";
	for(i = 2; i <= 100; i += 1)
	{
		c = GMClassicLevelAbility(i);
		nt = GMNewTreeLevelAbility(i);
		if(c != '' && stats.GetAbilityCount(c) > 0)
		{
			classic += 1;
			if(newRule || i > w.GetLevel())
				wrong += " " + c;
		}
		if(nt != '' && stats.GetAbilityCount(nt) > 0)
		{
			newTree += 1;
			if(!newRule || i > w.GetLevel())
				wrong += " " + nt;
		}
	}
}

// What the level abilities Geralt holds give him: taken away and given back, the change in maximum Vitality.
function GMTestXp09HeldVit() : float
{
	var w : W3PlayerWitcher;
	var stats : CCharacterStats;
	var names : array<name>;
	var counts : array<int>;
	var i : int;
	var v0, cur, vit : float;

	w = GetWitcherPlayer();
	stats = w.GetCharacterStats();
	cur = w.GetStat(BCS_Vitality);
	v0 = w.GetStatMax(BCS_Vitality);
	for(i = 2; i <= 100; i += 1)
	{
		if(GMClassicLevelAbility(i) != '' && stats.GetAbilityCount(GMClassicLevelAbility(i)) > 0)
		{
			names.PushBack(GMClassicLevelAbility(i));
			counts.PushBack(stats.GetAbilityCount(GMClassicLevelAbility(i)));
		}
		if(stats.GetAbilityCount(GMNewTreeLevelAbility(i)) > 0)
		{
			names.PushBack(GMNewTreeLevelAbility(i));
			counts.PushBack(stats.GetAbilityCount(GMNewTreeLevelAbility(i)));
		}
	}
	for(i = 0; i < names.Size(); i += 1)
		stats.RemoveAbilityAll(names[i]);
	vit = v0 - w.GetStatMax(BCS_Vitality);
	for(i = 0; i < names.Size(); i += 1)
		stats.AddAbilityMultiple(names[i], counts[i]);
	w.ForceSetStat(BCS_Vitality, MinF(cur, w.GetStatMax(BCS_Vitality)));
	return vit;
}

// After gmreset(): the tree in force's level points plus the other sources' free, nothing used; its level abilities
// for every level, none of the other tree's; their Vitality; the Vitality percentage kept.
exec function gmtest_xp09_tree()
{
	var w : W3PlayerWitcher;
	var newRule : bool;
	var lvl, classic, newTree, want : int;
	var wrong : string;
	var vit, pct : float;

	thePlayer.GMTestCount(true, true);
	w = GetWitcherPlayer();
	newRule = GMTestXp09NewRule();
	lvl = w.GetLevel();
	want = GMTestXp09LevelPoints(lvl, newRule) + w.gmTestXp09Other;
	GMTestReport(w.levelManager.GetPointsFree(ESkillPoint) == want && w.levelManager.GetPointsUsed(ESkillPoint) == 0, "XP-09 reset to the "
		+ GMTestXp09TreeName(newRule) + " at level " + lvl + ": " + w.levelManager.GetPointsFree(ESkillPoint) + " skill points free, "
		+ w.levelManager.GetPointsUsed(ESkillPoint) + " used (expected " + GMTestXp09LevelPoints(lvl, newRule) + " from levels + " + w.gmTestXp09Other + " from other sources)");
	GMTestXp09Held(classic, newTree, wrong, newRule);
	GMTestReport(wrong == "" && ((newRule && newTree == lvl - 1) || (!newRule && classic == Min(lvl, 50) - 1)), "XP-09 reset to the "
		+ GMTestXp09TreeName(newRule) + " at level " + lvl + ": level abilities held, classic " + classic + ", new tree " + newTree + wrong);
	vit = GMTestXp09HeldVit();
	GMTestReport(AbsF(vit - GMTestXp09LevelVit(lvl, newRule)) < 0.01, "XP-09 reset to the " + GMTestXp09TreeName(newRule) + " at level " + lvl
		+ ": the level abilities give " + NoTrailZeros(vit) + " Vitality (expected " + NoTrailZeros(GMTestXp09LevelVit(lvl, newRule)) + ")");
	pct = 100 * w.GetStat(BCS_Vitality) / w.GetStatMax(BCS_Vitality);
	GMTestReport(AbsF(pct - w.gmTestXp09Pct) < 0.1, "XP-09 reset to the " + GMTestXp09TreeName(newRule) + " at level " + lvl
		+ ": Vitality " + NoTrailZeros(w.GetStat(BCS_Vitality)) + " of " + NoTrailZeros(w.GetStatMax(BCS_Vitality)) + " (" + NoTrailZeros(pct)
		+ "%, before the reset " + NoTrailZeros(w.gmTestXp09Pct) + "%)");
	GMTestXp09Row("after the reset", newRule, 1, GMTestXp09LevelPoints(lvl, newRule), vit);
	LogChannel('GMTest', "SUMMARY xp09_tree: " + thePlayer.gmTestPassed + " passed, " + thePlayer.gmTestFailed + " failed");
}

// A Place of Power, spawned 20 m behind Geralt in its idle state.
exec function gmtest_xp09_pop_a()
{
	var w : W3PlayerWitcher;
	var ent : CEntity;
	var pop : CMajorPlaceOfPowerEntity;
	var tmpl : CEntityTemplate;
	var pos : Vector;

	w = GetWitcherPlayer();
	tmpl = (CEntityTemplate)LoadResource("gameplay\interactive_objects\places_of_power\place_of_power_quen.w2ent", true);
	pos = w.GetWorldPosition() - 20 * w.GetHeadingVector();
	ent = theGame.CreateEntity(tmpl, pos, w.GetWorldRotation());
	w.GMTestXp09Set(w.gmTestXp09Other, w.gmTestXp09Pct, ent, w.levelManager.GetPointsTotal(ESkillPoint));
	pop = (CMajorPlaceOfPowerEntity)ent;
	LogChannel('GMTest', "INFO XP-09 Place of Power spawned " + GMTestXp09Has(pop) + ", state "
		+ pop.GetCurrentStateName() + "; level " + w.GetLevel() + ", skill points " + w.levelManager.GetPointsTotal(ESkillPoint));
}

// Its channelling done: the state that grants the point.
exec function gmtest_xp09_pop_b()
{
	var w : W3PlayerWitcher;
	var pop : CMajorPlaceOfPowerEntity;

	w = GetWitcherPlayer();
	pop = (CMajorPlaceOfPowerEntity)w.gmTestXp09Pop;
	if(pop)
		pop.GotoState('PlaceOfPower_Activated');
	LogChannel('GMTest', "INFO XP-09 Place of Power activated " + GMTestXp09Has(pop));
}

exec function gmtest_xp09_pop_c()
{
	var w : W3PlayerWitcher;
	var pop : CMajorPlaceOfPowerEntity;
	var got : int;

	thePlayer.GMTestCount(true, true);
	w = GetWitcherPlayer();
	pop = (CMajorPlaceOfPowerEntity)w.gmTestXp09Pop;
	got = w.levelManager.GetPointsTotal(ESkillPoint) - w.gmTestXp09Points;
	GMTestReport(pop && pop.skillPointGranted && got == 1, "XP-09 (" + GMTestXp09TreeName(GMTestXp09NewRule()) + ") a Place of Power at level " + w.GetLevel()
		+ " (a level with " + GMTestXp09Point(w.GetLevel(), GMTestXp09NewRule()) + " level point): +" + got + " skill point, state " + pop.GetCurrentStateName());
	if(got == 1)
		w.GMTestXp09Set(w.gmTestXp09Other + 1, w.gmTestXp09Pct, NULL, 0);
	w.RemoveAllBuffsOfType(EET_ShrineQuen);
	if(pop)
		pop.Destroy();
	LogChannel('GMTest', "SUMMARY xp09_pop: " + thePlayer.gmTestPassed + " passed, " + thePlayer.gmTestFailed + " failed");
}

// A loaded save as it comes: the tree whose profile it has, the level abilities held, the points.
exec function gmtest_xp09_load()
{
	var w : W3PlayerWitcher;
	var classic, newTree : int;
	var wrong : string;
	var newRule : bool;
	var vit : float;

	w = GetWitcherPlayer();
	newRule = GMTestXp09NewRule();	// a local: a call passed after out arguments left them unset
	GMTestXp09Held(classic, newTree, wrong, newRule);
	vit = GMTestXp09HeldVit();
	LogChannel('GMTest', "INFO XP-09 loaded save: " + GMTestXp09TreeName(newRule) + " profile (facts set " + FactsQuerySum("gm_skill_tree_set")
		+ ", classic " + FactsQuerySum("gm_skill_tree_classic") + ", option classic " + GMIsClassicSkillTree() + "), level " + w.GetLevel()
		+ ", level abilities held: classic " + classic + ", new tree " + newTree + "; skill points " + w.levelManager.GetPointsFree(ESkillPoint) + " free, "
		+ w.levelManager.GetPointsUsed(ESkillPoint) + " used; the level abilities give " + NoTrailZeros(vit) + " Vitality; maximum Vitality "
		+ NoTrailZeros(w.GetStatMax(BCS_Vitality)));
}

// Level-ups request an autosave ("level gained", W3PlayerWitcher.OnLevelGained), which the game writes when its last
// save is old enough: a lock for the session keeps tests that level Geralt from writing one. Released by quitting.
@addField(W3PlayerWitcher)
var gmTestNoSaveLock : int;

@addMethod(W3PlayerWitcher)
function GMTestLockSaves()
{
	theGame.CreateNoSaveLock("gmtest", gmTestNoSaveLock, true);
}

exec function gmtest_nosave()
{
	GetWitcherPlayer().GMTestLockSaves();
	LogChannel('GMTest', "INFO saves locked for this session: " + theGame.AreSavesLocked());
}

// A loaded classic-profile save made into one whose profile is the new tree's, as a save from before slice X5 would
// load (5.x-GM bacb86cc's reset set the profile but kept Lvl<n> and a point every level): only SKL-02's fact changes.
exec function gmtest_xp09_asnew()
{
	FactsRemove("gm_skill_tree_classic");
	LogChannel('GMTest', "INFO XP-09 profile fact set to the new tree's: classic " + FactsQuerySum("gm_skill_tree_classic") + ", set " + FactsQuerySum("gm_skill_tree_set"));
}
