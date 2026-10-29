// In-game tests for AI-A slice A3: AI-06 (enemy levels and flags), AI-07 (categories and weaknesses) and
// AI-02's template lists in the entity files (tools/gen_ai_ent.py; docs/features/ai.md).
//   gmtest_ai06()           spawns the sample entities (tests/gmTestsAiEntData.ws) and two nekker
//                           warriors, friendly and frozen, 20 m and more behind Geralt, and reads what
//                           the template gives at spawn: level, category, added abilities, weaknesses;
//   gmtest_ai06_after()     in a later call (the level bonuses come by timer): removed abilities gone
//                           (AI-02's template check included), the rats' missing level bonuses, the
//                           nekker warrior's level fix, humanoid monsters on Essence and human for the
//                           human rules; AI-01's level code (AI-A audit F4): a bandit far below and a
//                           drowner 6 above a set Geralt level, recomputed as combat start does; then
//                           removes them. Both run in the regression (gmtest_regress(), then gmtest_panel()).
//   gmtest_ai06_oil(i, oil, silver)   a real oil application on Geralt's steel or silver sword: the
//                           attack power it adds against sample i (+25% where the category matches)
//   gmtest_ai06_hit(i, silver)        scripted hits with the steel or the silver sword on sample i:
//                           health lost, from Vitality or Essence
//   gmtest_ai06_near(range, recalc)  the NPCs the save holds within range (not spawned by tests): template,
//                           levels, level abilities, constitution templates, health against legacy's formula;
//                           with recalc, only recomputes their bonuses as combat start does (read in a later call)

@addField(CR4Player)
var gmTestAi06Npcs : array<CNewNPC>;
@addField(CR4Player)
var gmTestAi06Idx : array<int>;

@addMethod(CR4Player)
function GMTestAi06Add(npc : CNewNPC, idx : int)
{
	gmTestAi06Npcs.PushBack(npc);
	gmTestAi06Idx.PushBack(idx);
}

@addMethod(CR4Player)
function GMTestAi06Clear()
{
	var i : int;

	for(i = 0; i < gmTestAi06Npcs.Size(); i += 1)
		if(gmTestAi06Npcs[i])
			gmTestAi06Npcs[i].Destroy();
	gmTestAi06Npcs.Clear();
	gmTestAi06Idx.Clear();
}

// A friendly frozen NPC from an entity path, `distance` m behind Geralt (out of the other checks' way).
function GMTestAi06Spawn(path : string, distance : float) : CNewNPC
{
	var template : CEntityTemplate;
	var npc : CNewNPC;
	var pos : Vector;

	template = (CEntityTemplate)LoadResource(path, true);
	if(!template)
		return NULL;
	pos = thePlayer.GetWorldPosition() - thePlayer.GetHeadingVector() * distance;
	npc = (CNewNPC)theGame.CreateEntity(template, pos, VecToRotation(thePlayer.GetHeadingVector()));
	if(!npc)
		return NULL;
	npc.SetTemporaryAttitudeGroup('friendly_to_player', AGP_Default);
	npc.SetAnimationSpeedMultiplier(0.001);
	return npc;
}

function GMTestAi06Category(npc : CActor) : int
{
	var cat : EMonsterCategory;
	var tmpName : name;
	var tmpBool : bool;

	theGame.GetMonsterParamsForActor(npc, cat, tmpName, tmpBool, tmpBool, tmpBool);
	return (int)cat;
}

function GMTestAi06Names(names : array<name>) : string
{
	var i : int;
	var s : string;

	for(i = 0; i < names.Size(); i += 1)
	{
		if(i > 0)
			s += ", ";
		s += NameToString(names[i]);
	}
	return s;
}

function GMTestAi06Weak(npc : CNewNPC) : array<name>
{
	var c : CCreatureDataComponent;
	var none : array<name>;

	c = (CCreatureDataComponent)npc.GetComponentByClassName('CCreatureDataComponent');
	if(c)
		return c.GetItemsUsedAgainstCreature();
	return none;
}

// The nekker warrior Fool's Gold's quest spawns with its tag (dlc7, sq107), and one without.
function GMTestAi06Nekker() : string
{
	return "characters/npc_entities/monsters/nekker_lvl3__warrior.w2ent";
}

exec function gmtest_ai06()
{
	thePlayer.GMTestCount(true, true);
	GMTest_ai06();
	LogChannel('GMTest', "SUMMARY ai06: " + thePlayer.gmTestPassed + " passed, " + thePlayer.gmTestFailed + " failed");
}

function GMTest_ai06()
{
	var i, j, level, category : int;
	var path : string;
	var has, hasNot, weak, got : array<name>;
	var npc : CNewNPC;
	var ok : bool;

	thePlayer.GMTestAi06Clear();
	for(i = 0; i < GMTestAiEntSamples(); i += 1)
	{
		GMTestAiEntSample(i, path, level, category, has, hasNot, weak);
		npc = GMTestAi06Spawn(path, 20 + 3 * i);
		if(!npc)
		{
			GMTestReport(false, "AI-06 sample " + path + " did not spawn");
			continue;
		}
		thePlayer.GMTestAi06Add(npc, i);
		if(level >= 0)
			GMTestReport(npc.GMTestEntityLevel() == level, "AI-06 " + path + ": level " + npc.GMTestEntityLevel() + " (the edited file's " + level + ")");
		if(category >= 0)
			GMTestReport(GMTestAi06Category(npc) == category, "AI-07 " + path + ": category " + GMTestAi06Category(npc) + " (" + category + ")");
		for(j = 0; j < has.Size(); j += 1)
			GMTestReport(npc.HasAbility(has[j]), "AI-02/06 " + path + " has " + has[j]);
		if(weak.Size() > 0)
		{
			got = GMTestAi06Weak(npc);
			ok = got.Size() == weak.Size();
			for(j = 0; j < weak.Size() && ok; j += 1)
				ok = got.Contains(weak[j]);
			GMTestReport(ok, "AI-07 " + path + ": weaknesses " + GMTestAi06Names(got) + " (" + GMTestAi06Names(weak) + ")");
		}
	}
	// AI-06's code fix: the sq107 nekker warrior (its tag) at level 8; one without the tag keeps its own
	npc = GMTestAi06Spawn(GMTestAi06Nekker(), 20 + 3 * GMTestAiEntSamples());
	if(npc)
	{
		npc.AddTag('sq107_monster_heavy');
		thePlayer.GMTestAi06Add(npc, -1);
	}
	npc = GMTestAi06Spawn(GMTestAi06Nekker(), 23 + 3 * GMTestAiEntSamples());
	if(npc)
		thePlayer.GMTestAi06Add(npc, -2);
	// AI-01's level code (audit F4): a bandit set to level 2 and a drowner set to 6 above the Geralt level
	// GMTest_ai06_after() sets (Geralt's + 20); spawned friendly, made hostile there before the recompute
	npc = GMTestAi06Spawn(GMTestDummyTemplate("human"), 26 + 3 * GMTestAiEntSamples());
	if(npc)
	{
		npc.SetLevel(2);
		thePlayer.GMTestAi06Add(npc, -3);
	}
	npc = GMTestAi06Spawn(GMTestDummyTemplate("drowner"), 29 + 3 * GMTestAiEntSamples());
	if(npc)
	{
		npc.SetLevel(GMTestAi06SetGeraltLevel() + 6);
		thePlayer.GMTestAi06Add(npc, -4);
	}
	LogChannel('GMTest', "INFO AI-06 " + thePlayer.gmTestAi06Npcs.Size() + " entities spawned; GMTest_ai06_after() reads them after their level bonuses");
}

exec function gmtest_ai06_after()
{
	thePlayer.GMTestCount(true, true);
	GMTest_ai06_after();
	LogChannel('GMTest', "SUMMARY ai06_after: " + thePlayer.gmTestPassed + " passed, " + thePlayer.gmTestFailed + " failed");
}

function GMTest_ai06_after()
{
	var i, j, k, level, category, nLevelAbls : int;
	var path : string;
	var has, hasNot, weak, levelAbls : array<name>;
	var npc, nekkerTagged, nekkerPlain, bandit, drowner : CNewNPC;
	var humanoid : bool;

	levelAbls = GMTestAiLevelAbls();
	levelAbls.PushBack('DisplayedLevelAbl');
	for(k = 0; k < thePlayer.gmTestAi06Npcs.Size(); k += 1)
	{
		npc = thePlayer.gmTestAi06Npcs[k];
		i = thePlayer.gmTestAi06Idx[k];
		if(!npc)
			continue;
		if(i == -1)
		{
			nekkerTagged = npc;
			continue;
		}
		if(i == -2)
		{
			nekkerPlain = npc;
			continue;
		}
		if(i == -3)
		{
			bandit = npc;
			continue;
		}
		if(i == -4)
		{
			drowner = npc;
			continue;
		}
		GMTestAiEntSample(i, path, level, category, has, hasNot, weak);
		for(j = 0; j < hasNot.Size(); j += 1)
			GMTestReport(!npc.HasAbility(hasNot[j]), "AI-02/06 " + path + " no longer has " + hasNot[j]);
		humanoid = npc.HasAbility('ConHumanoidMonster');
		// the crowd succubus has no health stats at all (5.x's too: a non-combat crowd NPC)
		if(humanoid && npc.GetStatMax(BCS_Vitality) <= 0 && npc.GetStatMax(BCS_Essence) <= 0)
			LogChannel('GMTest', "INFO AI-02 " + path + " has no health stats (a non-combat NPC, as in 5.x)");
		else if(humanoid)
		{
			GMTestReport(npc.GetStatMax(BCS_Vitality) <= 0 && npc.GetStatMax(BCS_Essence) > 0,
				"AI-02 " + path + " (ConHumanoidMonster) on Essence: Vitality " + NoTrailZeros(npc.GetStatMax(BCS_Vitality)) + ", Essence " + NoTrailZeros(npc.GetStatMax(BCS_Essence)));
			GMTestReport(npc.IsHuman(), "AI-07 " + path + " (ConHumanoidMonster, category " + GMTestAi06Category(npc) + ") counts as human");
		}
		if(npc.HasAbility('ConHumanoidMonster') || npc.HasAbility('ConAthletic'))
			GMTestReport(!(npc.HasAbility('ConDefault') && (npc.HasAbility('ConAthletic') || npc.HasAbility('ConHumanoidMonster'))),
				"AI-02 " + path + " keeps one constitution template: ConDefault " + npc.HasAbility('ConDefault') + ", ConAthletic " + npc.HasAbility('ConAthletic') + ", ConHumanoidMonster " + humanoid);
		if(npc.HasAbility('NPCDoNotGainBoost'))
		{
			nLevelAbls = 0;
			for(j = 0; j < levelAbls.Size(); j += 1)
				nLevelAbls += npc.GetAbilityCount(levelAbls[j]);
			GMTestReport(nLevelAbls == 0, "AI-06 " + path + " (NPCDoNotGainBoost) has no level bonuses: " + nLevelAbls + " level abilities, level " + npc.GetLevel());
		}
	}
	// AI-06's code fix: the tag moves the sq107 nekker warrior to level 8, from its template's level, which an
	// untagged one keeps (so the check fails without the fix, and if the template itself were at 8)
	if(nekkerTagged && nekkerPlain)
		GMTestReport(nekkerTagged.GMTestEntityLevel() == 8 && nekkerTagged.currentLevel == 8 && nekkerPlain.GMTestEntityLevel() != 8 && nekkerPlain.currentLevel == nekkerPlain.GMTestEntityLevel(),
			"AI-06 the sq107 nekker warrior (tagged sq107_monster_heavy) at level 8: entity " + nekkerTagged.GMTestEntityLevel() + ", current " + nekkerTagged.currentLevel
			+ "; one without the tag keeps its template's level " + nekkerPlain.GMTestEntityLevel() + " (current " + nekkerPlain.currentLevel + ")");
	else
		GMTestReport(false, "AI-06 the nekker warriors did not spawn");
	// AI-06: the deserters' fix applies only at gr13. A negative check only: it cannot see the fix work (that
	// needs the encounter, an open check); it fails only if the fix applied here
	GMTestReport(!GMIsAtLWGR13(thePlayer), "AI-06 (negative check only) the deserters' level fix does not apply away from the No Man's Land encounter gr13");
	// AI-01's level code at a set Geralt level (audit F4)
	GMTestAi06LevelCode(bandit, drowner);
	thePlayer.GMTestAi06Clear();
}

// AI-A audit F4: the Geralt level the level-code check sets (Geralt's own + 20, so the soft scaling and High
// both apply whatever level the regression runs at).
function GMTestAi06SetGeraltLevel() : int
{
	return thePlayer.GetLevel() + 20;
}

// Test only: the level W3PlayerWitcher.GetLevel() returns while set (0: his own). Set and cleared inside
// one function, so nothing else runs at the set level.
@addField(W3PlayerWitcher)
var gmTestLevelOverride : int;

@addMethod(W3PlayerWitcher)
function GMTestSetLevelOverride(lvl : int)
{
	gmTestLevelOverride = lvl;
}

@wrapMethod(W3PlayerWitcher)
function GetLevel() : int
{
	var lvl : int;

	lvl = wrappedMethod();
	if(gmTestLevelOverride > 0)
		return gmTestLevelOverride;
	return lvl;
}

// The per-level ability legacy's GMInternalAddLevelBonuses picks for this NPC.
function GMTestAiKindAbl(npc : CNewNPC) : name
{
	if((npc.HasAbility('mon_wolf_base') || npc.HasAbility('mon_boar_base') || npc.HasAbility('mon_boar_ep2_base')) && npc.GetStatMax(BCS_Vitality) > 0)
		return 'AnimalLevelBonus';
	if(npc.GetStatMax(BCS_Vitality) > 0)
		return 'NPCLevelBonus';
	if(CalculateAttributeValue(npc.GetTotalArmor()) > 0 && npc.GetIsMonsterTypeGroup())
		return 'MonsterLevelBonusGroupArmored';
	if(CalculateAttributeValue(npc.GetTotalArmor()) > 0)
		return 'MonsterLevelBonusArmored';
	if(npc.GetIsMonsterTypeGroup())
		return 'MonsterLevelBonusGroup';
	return 'MonsterLevelBonus';
}

// One sample of the level-code check: its level bonuses recomputed (RecalcLevel, as combat start does) with
// Geralt at level p, hostile; its level, per-level abilities, High/Deadly and maximum health against legacy's
// rules, the health predicted from what it had before the recompute plus the added per-level abilities'
// values read from the definitions (independent of the code under test).
function GMTestAi06LevelSample(npc : CNewNPC, label : string, p : int, wantLevel : int, wantHigh : bool)
{
	var kind, attrName : name;
	var noTags : array<name>;
	var h0, f, per : SAbilityAttributeValue;
	var n0, n1, added : int;
	var b, m, a, predicted, maxHealth : float;
	var high, deadly : bool;
	var w : W3PlayerWitcher;

	w = GetWitcherPlayer();
	npc.SetTemporaryAttitudeGroup('hostile_to_player', AGP_Default);
	kind = GMTestAiKindAbl(npc);
	if(npc.GetStatMax(BCS_Vitality) > 0) attrName = 'vitality'; else attrName = 'essence';
	n0 = npc.GetAbilityCount(kind);
	h0 = npc.GetCharacterStats().GetAttributeValue(attrName, noTags);

	w.GMTestSetLevelOverride(p);
	npc.RecalcLevel();
	w.GMTestSetLevelOverride(0);

	n1 = npc.GetAbilityCount(kind);
	added = (wantLevel - 1) - n0;
	GMTestAiAbl(kind, attrName, b, m, a);
	per = h0;
	per.valueBase += added * b;
	per.valueMultiplicative += added * m;
	per.valueAdditive += added * a;
	f = npc.GetCharacterStats().GetAttributeValue('health_final_multiplier', noTags);
	predicted = CalculateAttributeValue(per) * MaxF(f.valueAdditive, 0.0001);
	if(attrName == 'vitality') maxHealth = npc.GetStatMax(BCS_Vitality); else maxHealth = npc.GetStatMax(BCS_Essence);
	high = npc.HasAbility('NPCLevelBonusHigh') || npc.HasAbility('MonsterLevelBonusHigh');
	deadly = npc.HasAbility('NPCLevelBonusDeadly') || npc.HasAbility('MonsterLevelBonusDeadly');
	GMTestReport(npc.currentLevel == wantLevel && n1 == wantLevel - 1 && npc.GetAbilityCount('DisplayedLevelAbl') == wantLevel - 1,
		"AI-01 " + label + " at Geralt " + p + ": level " + npc.currentLevel + " (" + wantLevel + "), " + n1 + " x " + kind + ", DisplayedLevelAbl x " + npc.GetAbilityCount('DisplayedLevelAbl') + " (" + (wantLevel - 1) + ")");
	GMTestReport(AbsF(maxHealth - predicted) < 0.5,
		"AI-01 " + label + ": max " + attrName + " " + NoTrailZeros(maxHealth) + " (before the recompute " + n0 + " x " + kind + "; " + added + " more x " + NoTrailZeros(b) + "/" + NoTrailZeros(m) + "/" + NoTrailZeros(a) + " predicts " + NoTrailZeros(predicted) + ")");
	GMTestReport(high == wantHigh && !deadly, "AI-01 " + label + ", " + (npc.currentLevel - p) + " levels from Geralt: High " + high + ", Deadly " + deadly + " (" + wantHigh + ", false)");
}

// AI-A audit F4: the level code in the regression. At a set Geralt level P: a hostile bandit set to level 2 is
// raised to P - 6 (DA2's soft scaling) with P - 7 NPCLevelBonus and the health they give; a hostile drowner
// set to P + 6 keeps it and gets High (DA4: 6 levels), not Deadly.
function GMTestAi06LevelCode(bandit : CNewNPC, drowner : CNewNPC)
{
	var p : int;

	p = GMTestAi06SetGeraltLevel();
	if(!bandit || !drowner)
	{
		GMTestReport(false, "AI-01 the level-code samples did not spawn");
		return;
	}
	GMTestAi06LevelSample(bandit, "a bandit set to level 2", p, p - 6, false);
	GMTestAi06LevelSample(drowner, "a drowner set to level " + (p + 6), p, p + 6, true);
}

// Spawns the samples hostile (for gmtest_ai06_oil/hit and a look in game) without the checks: sample i at
// 3 + 3 i m in front of Geralt. gmtest_dummy_clear() removes them.
exec function gmtest_ai06_spawn()
{
	var i, level, category : int;
	var path : string;
	var has, hasNot, weak : array<name>;

	thePlayer.GMTestDummyClearAll();
	for(i = 0; i < GMTestAiEntSamples(); i += 1)
	{
		GMTestAiEntSample(i, path, level, category, has, hasNot, weak);
		GMTestDummySpawn(path, 0, 3 + 3 * i);
	}
	LogChannel('GMTest', "INFO AI-06 " + thePlayer.gmTestDummies.Size() + " samples spawned (hostile, frozen)");
}

// The i-th dummy (gmtest_ai06_spawn's sample i).
function GMTestAi06Dummy(i : int) : CNewNPC
{
	if(i < 0 || i >= thePlayer.gmTestDummies.Size())
		return NULL;
	return thePlayer.gmTestDummies[i];
}

// A real oil application (ApplyOil, the inventory's path) on the steel or silver sword: the attack power the
// oil adds against dummy i, +25% where the oil's category is the enemy's, 0 otherwise (expect: 1 or 0).
exec function gmtest_ai06_oil(i : int, oilName : name, silver : bool, expect : bool)
{
	var w : W3PlayerWitcher;
	var npc : CNewNPC;
	var ids : array<SItemUniqueId>;
	var sword : SItemUniqueId;
	var ap0, ap1 : float;
	var applied : bool;

	w = GetWitcherPlayer();
	npc = GMTestAi06Dummy(i);
	if(!npc)
		return;
	sword = w.GetEquippedSword(!silver);
	w.inv.RemoveAllOilsFromItem(sword);
	if(silver)
		w.OnEquipMeleeWeapon(PW_Silver, true);
	else
		w.OnEquipMeleeWeapon(PW_Steel, true);
	ap0 = GMTestOilAttackPower(npc);
	ids = w.inv.AddAnItem(oilName, 1);
	applied = w.ApplyOil(ids[0], sword);
	ap1 = GMTestOilAttackPower(npc);
	if(expect)
		GMTestReport(applied && AbsF(ap1 - ap0 - 0.25) < 0.005, "AI-07 " + oilName + " (real application) on " + npc.GetReadableName() + " (category " + GMTestAi06Category(npc) + "): +" + RoundMath(100 * (ap1 - ap0)) + "% attack power");
	else
		GMTestReport(applied && AbsF(ap1 - ap0) < 0.005, "AI-07 " + oilName + " (real application) does nothing on " + npc.GetReadableName() + " (category " + GMTestAi06Category(npc) + "): +" + RoundMath(100 * (ap1 - ap0)) + "% attack power");
	w.inv.RemoveAllOilsFromItem(sword);
}

// Scripted light hits with Geralt's held steel or silver sword on dummy i (draw it first): health lost, and
// from which stat.
exec function gmtest_ai06_hit(i : int, silver : bool)
{
	var w : W3PlayerWitcher;
	var npc : CNewNPC;
	var action : W3Action_Attack;
	var sword : SItemUniqueId;
	var v0, e0, v1, e1 : float;
	var kind : string;

	w = GetWitcherPlayer();
	npc = GMTestAi06Dummy(i);
	if(!npc)
		return;
	kind = "steel";
	if(silver)
	{
		kind = "silver";
		w.OnEquipMeleeWeapon(PW_Silver, true);
	}
	else
		w.OnEquipMeleeWeapon(PW_Steel, true);
	sword = w.GetEquippedSword(!silver);
	v0 = npc.GetStat(BCS_Vitality, true);
	e0 = npc.GetStat(BCS_Essence, true);
	action = new W3Action_Attack in theGame.damageMgr;
	action.Init(thePlayer, npc, NULL, sword, 'attack_light', thePlayer.GetName(), EHRT_Light, false, false, 'attack_light', AST_Jab, ASD_UpDown, true, false, false, false);
	theGame.damageMgr.ProcessAction(action);
	delete action;
	v1 = npc.GetStat(BCS_Vitality, true);
	e1 = npc.GetStat(BCS_Essence, true);
	LogChannel('GMTest', "INFO AI-06 " + kind + " sword hit on " + npc.GetReadableName() + ": Vitality " + NoTrailZeros(v0) + " -> " + NoTrailZeros(v1) + ", Essence " + NoTrailZeros(e0) + " -> " + NoTrailZeros(e1));
	GMTestReport(e0 - e1 > 0 || v0 - v1 > 0, "AI-06 the " + kind + " sword hurts " + npc.GetReadableName() + ": " + NoTrailZeros(v0 - v1 + e0 - e1) + " health lost");
}

// The NPCs the save holds within range of Geralt (not test dummies): template, entity and current level,
// level abilities, constitution template, max health and legacy's formula for it (A1's: attribute x
// health_final_multiplier), whether the level bonuses are legacy's (one per level above 1).
exec function gmtest_ai06_near(optional range : float, optional recalc : bool)
{
	var ents : array<CActor>;
	var npc : CNewNPC;
	var i, j, n, count : int;
	var abls, noTags : array<name>;
	var attrName : name;
	var hAttr, fAttr : SAbilityAttributeValue;
	var maxHealth, predicted : float;
	var cons, kinds : string;

	if(range <= 0)
		range = 60;
	abls = GMTestAiLevelAbls();
	ents = thePlayer.GetNPCsAndPlayersInRange(range, 1000, , FLAG_OnlyAliveActors);
	thePlayer.GMTestCount(true, true);
	for(i = 0; i < ents.Size(); i += 1)
	{
		npc = (CNewNPC)ents[i];
		if(!npc || thePlayer.gmTestDummies.Contains(npc) || thePlayer.gmTestAi06Npcs.Contains(npc) || npc.IsAnimal() && npc.GetStatMax(BCS_Vitality) <= 0)
			continue;
		count += 1;
		if(recalc)
		{
			npc.RecalcLevel();	// as combat start does: the level bonuses and maximum health recomputed
			continue;
		}
		kinds = "";
		n = 0;
		for(j = 0; j < abls.Size(); j += 1)
			if(npc.GetAbilityCount(abls[j]) > 0)
			{
				kinds += NameToString(abls[j]) + " x" + npc.GetAbilityCount(abls[j]) + " ";
				n += npc.GetAbilityCount(abls[j]);
			}
		cons = "";
		if(npc.HasAbility('ConDefault')) cons += "ConDefault ";
		if(npc.HasAbility('ConAverage')) cons += "ConAverage ";
		if(npc.HasAbility('ConAthletic')) cons += "ConAthletic ";
		if(npc.HasAbility('ConWitcher')) cons += "ConWitcher ";
		if(npc.HasAbility('ConHumanoidMonster')) cons += "ConHumanoidMonster ";
		if(npc.HasAbility('ConFrail')) cons += "ConFrail ";
		if(npc.HasAbility('ConFat')) cons += "ConFat ";
		if(npc.HasAbility('ConPudzian')) cons += "ConPudzian ";
		if(npc.GetStatMax(BCS_Vitality) > 0) attrName = 'vitality'; else attrName = 'essence';
		hAttr = npc.GetCharacterStats().GetAttributeValue(attrName, noTags);
		fAttr = npc.GetCharacterStats().GetAttributeValue('health_final_multiplier', noTags);
		predicted = CalculateAttributeValue(hAttr) * MaxF(fAttr.valueAdditive, 0.0001);
		if(attrName == 'vitality') maxHealth = npc.GetStatMax(BCS_Vitality); else maxHealth = npc.GetStatMax(BCS_Essence);
		LogChannel('GMTest', "INFO AI-06 near: " + npc.GetDisplayName() + " (" + npc.GetReadableName() + ", " + NoTrailZeros(VecDistance(npc.GetWorldPosition(), thePlayer.GetWorldPosition())) + " m) entity level " + npc.GMTestEntityLevel()
			+ ", level " + npc.currentLevel + ", shown " + npc.GetLevel() + "; " + kinds + "DisplayedLevelAbl x" + npc.GetAbilityCount('DisplayedLevelAbl') + "; templates " + cons + "; max " + attrName + " " + NoTrailZeros(maxHealth)
			+ " (formula " + NoTrailZeros(predicted) + "); NPCDoNotGainBoost " + npc.HasAbility('NPCDoNotGainBoost'));
		if(maxHealth > 0 && !npc.HasAbility('NPCDoNotGainBoost'))
		{
			GMTestReport(n == Max(0, npc.currentLevel - 1) && npc.GetAbilityCount('DisplayedLevelAbl') == Max(0, npc.currentLevel - 1),
				"AI-01 " + npc.GetReadableName() + " (in the save): " + n + " level abilities for level " + npc.currentLevel);
			GMTestReport(AbsF(maxHealth - predicted) < 0.5, "AI-01 " + npc.GetReadableName() + " (in the save): max " + attrName + " " + NoTrailZeros(maxHealth) + " = formula " + NoTrailZeros(predicted));
		}
	}
	LogChannel('GMTest', "SUMMARY ai06_near: " + count + " NPCs; " + thePlayer.gmTestPassed + " passed, " + thePlayer.gmTestFailed + " failed");
}
