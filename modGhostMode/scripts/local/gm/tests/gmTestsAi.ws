// In-game tests for AI-A (enemy stats): AI-01 (level bonuses), AI-02 (NPC templates) and DA4's
// thresholds. See docs/features/ai.md.
//   gmtest_ai01()            the definitions and thresholds (in the regression run)
//   gmtest_ai01_spawn()      spawns a set of frozen hostile enemies (humans at several levels, a guard,
//                            a wolf, a bear, monsters); then, in a later call (bonuses come by timer):
//   gmtest_ai01_read()       each one's level, level abilities, High/Deadly, health and attack power
//                            against legacy's formula, the HUD level colour (UI-12); then
//   gmtest_dummy_clear()
//   gmtest_ai01_recalc()     recomputes the spawned enemies' bonuses (after setlevel), read again
//   gmtest_ai01_guards(r)    real guards within r m: their level against Geralt's + 16
//   gmtest_ai01_fin_a(d) / gmtest_ai01_fin_b()   SKL-12's finisher rule at d levels above Geralt

// The entity's own level (CNewNPC.level, a private field).
@addMethod(CNewNPC)
function GMTestEntityLevel() : int
{
	return level;
}

function GMTestAiAbl(abl : name, attr : name, out base : float, out mult : float, out add : float)
{
	var min, max : SAbilityAttributeValue;

	theGame.GetDefinitionsManager().GetAbilityAttributeValue(abl, attr, min, max);
	base = min.valueBase;
	mult = min.valueMultiplicative;
	add = min.valueAdditive;
}

function GMTestAiAblIs(abl : name, attr : name, base : float, mult : float, add : float) : bool
{
	var b, m, a : float;

	GMTestAiAbl(abl, attr, b, m, a);
	return AbsF(b - base) < 0.0001 && AbsF(m - mult) < 0.0001 && AbsF(a - add) < 0.0001;
}

function GMTestAiAblText(abl : name, attr : name) : string
{
	var b, m, a : float;

	GMTestAiAbl(abl, attr, b, m, a);
	return abl + "." + attr + " " + NoTrailZeros(b) + "/" + NoTrailZeros(m) + "/" + NoTrailZeros(a);
}

exec function gmtest_ai01()
{
	thePlayer.GMTestCount(true, true);
	GMTest_ai01();
	LogChannel('GMTest', "SUMMARY ai01: " + thePlayer.gmTestPassed + " passed, " + thePlayer.gmTestFailed + " failed");
}

// AI-01, AI-02, DA4: legacy's level abilities and templates as the game reads them (base/mult/add),
// and the thresholds. 5.x: NPCLevelBonus +55 Vitality and +1 level, MonsterLevelBonus +270 Essence,
// ConDefault 25 Vitality and 50% fire resistance, ConWitcher 800 and +100% attack power, MiniBoss and
// Boss x1.5 and x2.5 health; thresholds 10 and 20.
function GMTest_ai01()
{
	var dm : CDefinitionsManagerAccessor;

	dm = theGame.GetDefinitionsManager();
	GMTestReport(theGame.params.LEVEL_DIFF_HIGH == 6 && theGame.params.LEVEL_DIFF_DEADLY == 15,
		"AI-01 thresholds: high " + theGame.params.LEVEL_DIFF_HIGH + ", deadly " + theGame.params.LEVEL_DIFF_DEADLY + " (6, 15; 5.x 10, 20)");
	GMTestReport(GMTestAiAblIs('NPCLevelBonus', 'vitality', 8, 0.15, 0) && GMTestAiAblIs('NPCLevelBonus', 'attack_power', 11, 0.01, 1)
		&& GMTestAiAblIs('NPCLevelBonus', 'level', 0, 0, 0) && GMTestAiAblIs('NPCLevelBonus', 'force_resistance_perc', 0, 0, 0),
		"AI-01 " + GMTestAiAblText('NPCLevelBonus', 'vitality') + ", " + GMTestAiAblText('NPCLevelBonus', 'attack_power') + ", "
		+ GMTestAiAblText('NPCLevelBonus', 'level') + " (8/0.15/0, 11/0.01/1, no level, no resistance)");
	GMTestReport(GMTestAiAblIs('MonsterLevelBonus', 'essence', 20, 0.15, 0) && GMTestAiAblIs('MonsterLevelBonusArmored', 'essence', 20, 0.15, 0)
		&& GMTestAiAblIs('MonsterLevelBonusArmored', 'force_resistance_perc', 0, 0, 0)
		&& GMTestAiAblIs('MonsterLevelBonusGroup', 'essence', 10, 0.15, 0) && GMTestAiAblIs('MonsterLevelBonusGroup', 'attack_power', 11, 0.005, 1)
		&& GMTestAiAblIs('MonsterLevelBonusGroupArmored', 'essence', 10, 0.15, 0) && GMTestAiAblIs('MonsterLevelBonus', 'level', 0, 0, 0),
		"AI-01 " + GMTestAiAblText('MonsterLevelBonus', 'essence') + ", " + GMTestAiAblText('MonsterLevelBonusGroup', 'essence') + ", "
		+ GMTestAiAblText('MonsterLevelBonusGroup', 'attack_power') + " (20/0.15/0 solo, 10/0.15/0 and 11/0.005/1 in groups; armored alike, no resistances)");
	GMTestReport(GMTestAiAblIs('AnimalLevelBonus', 'vitality', 8, 0.15, 0) && GMTestAiAblIs('AnimalLevelBonus', 'attack_power', 11, 0, 1)
		&& GMTestAiAblIs('DisplayedLevelAbl', 'level', 0, 0, 1),
		"AI-01 " + GMTestAiAblText('AnimalLevelBonus', 'vitality') + ", " + GMTestAiAblText('AnimalLevelBonus', 'attack_power') + ", "
		+ GMTestAiAblText('DisplayedLevelAbl', 'level') + " (8/0.15/0, 11/0/1, +1 level)");
	GMTestReport(GMTestAiAblIs('NPCLevelBonusHigh', 'bleeding_DoT_damage_resistance_perc', 0, 0, 0.33) && GMTestAiAblIs('NPCLevelBonusHigh', 'vitality', 0, 0, 0)
		&& GMTestAiAblIs('NPCLevelBonusDeadly', 'burning_DoT_damage_resistance_perc', 0, 0, 0.5) && GMTestAiAblIs('NPCLevelBonusDeadly', 'attack_power', 0, 0, 0)
		&& GMTestAiAblIs('MonsterLevelBonusHigh', 'poison_DoT_damage_resistance_perc', 0, 0, 0.33) && GMTestAiAblIs('MonsterLevelBonusDeadly', 'poison_DoT_damage_resistance_perc', 0, 0, 0.5)
		&& dm.AbilityHasTag('MonsterLevelBonusHigh', 'InstantKillImmune') && dm.AbilityHasTag('MonsterLevelBonusDeadly', 'InstantKillImmune')
		&& !dm.AbilityHasTag('NPCLevelBonusHigh', 'InstantKillImmune') && !dm.AbilityHasTag('MonsterLevelBonusDeadly', 'CannotBeAttackedFromBehind'),
		"AI-01 High/Deadly: " + GMTestAiAblText('NPCLevelBonusHigh', 'bleeding_DoT_damage_resistance_perc') + ", "
		+ GMTestAiAblText('MonsterLevelBonusDeadly', 'poison_DoT_damage_resistance_perc') + ", monsters' InstantKillImmune "
		+ dm.AbilityHasTag('MonsterLevelBonusDeadly', 'InstantKillImmune') + " (+33%/+50% damage over time only; instant-kill immunity for monsters)");
	GMTestReport(GMTestAiAblIs('ConDefault', 'vitality', 80, 0, 0) && GMTestAiAblIs('ConDefault', 'fire_resistance_perc', 0, 0, 0)
		&& GMTestAiAblIs('ConDefault', 'light_attack_damage_vitality', 0, 0, 0) && GMTestAiAblIs('ConDefault', 'staminaRegen', 0, 0.25, 0)
		&& GMTestAiAblIs('ConAverage', 'vitality', 160, 0, 0) && GMTestAiAblIs('ConAthletic', 'vitality', 320, 0, 0)
		&& GMTestAiAblIs('ConFrail', 'vitality', 50, 0, 0) && GMTestAiAblIs('ConFrail', 'attack_power', 0, 0, 0)
		&& GMTestAiAblIs('ConFat', 'vitality', 100, 0, 0) && GMTestAiAblIs('ConPudzian', 'vitality', 150, 0, 0)
		&& GMTestAiAblIs('ConWitcher', 'vitality', 500, 0, 0) && GMTestAiAblIs('ConWitcher', 'attack_power', 0, 0, 0)
		&& GMTestAiAblIs('ConHumanoidMonster', 'essence', 500, 0, 0) && GMTestAiAblIs('ConHumanoidMonster', 'vitality', 0, 0, 0),
		"AI-02 " + GMTestAiAblText('ConDefault', 'vitality') + ", " + GMTestAiAblText('ConDefault', 'fire_resistance_perc') + ", "
		+ GMTestAiAblText('ConAthletic', 'vitality') + ", " + GMTestAiAblText('ConWitcher', 'vitality') + ", " + GMTestAiAblText('ConWitcher', 'attack_power') + ", "
		+ GMTestAiAblText('ConHumanoidMonster', 'essence') + " (80, no fire resistance; 320; 500, no attack power bonus; 500 Essence)");
	GMTestReport(GMTestAiAblIs('MiniBoss', 'vitality', 500, 0, 0) && GMTestAiAblIs('MiniBoss', 'attack_power', 0, 0.25, 50)
		&& GMTestAiAblIs('MiniBoss', 'slashing_resistance_perc', 0, 0, 0.1) && GMTestAiAblIs('MiniBoss', 'will_resistance_perc', 0, 0, 0.2)
		&& GMTestAiAblIs('Boss', 'vitality', 1000, 0, 0) && GMTestAiAblIs('Boss', 'attack_power', 0, 0.5, 100)
		&& GMTestAiAblIs('Boss', 'force_resistance_perc', 0, 0, 0.3) && GMTestAiAblIs('Boss', 'bleeding_DoT_damage_resistance_perc', 0, 0, 0.5),
		"AI-02 " + GMTestAiAblText('MiniBoss', 'vitality') + ", " + GMTestAiAblText('MiniBoss', 'attack_power') + ", "
		+ GMTestAiAblText('Boss', 'vitality') + ", " + GMTestAiAblText('Boss', 'attack_power') + " (+500 and +50/+25%; +1000 and +100/+50%)");
}

// The set of enemies gmtest_ai01_spawn() places: kind, level set (0: the entity's own), guard.
@addField(CR4Player)
var gmTestAiKinds : array<string>;
@addField(CR4Player)
var gmTestAiSet : array<int>;
@addField(CR4Player)
var gmTestAiGuard : array<bool>;
@addField(CR4Player)
var gmTestAiPlayerLevel : int;

@addMethod(CR4Player)
function GMTestAi01Reset(p : int)
{
	gmTestAiKinds.Clear();
	gmTestAiSet.Clear();
	gmTestAiGuard.Clear();
	gmTestAiPlayerLevel = p;
}

@addMethod(CR4Player)
function GMTestAi01Add(kind : string, setLevel : int, guard : bool)
{
	gmTestAiKinds.PushBack(kind);
	gmTestAiSet.PushBack(setLevel);
	gmTestAiGuard.PushBack(guard);
}

@addMethod(CR4Player)
function GMTestAiFinisherSet(res : int, diff : int)
{
	gmTestAiFinisher = res;
	gmTestAiFinisherDiff = diff;
}

function GMTestAiSpawn(kind : string, setLevel : int, guard : bool, distance : float)
{
	var npc : CNewNPC;

	npc = GMTestDummySpawn(kind, setLevel, distance);
	if(!npc)
		return;
	if(guard)
		npc.SetNPCType(ENGT_Guard);
	thePlayer.GMTestAi01Add(kind, setLevel, guard);
}

exec function gmtest_ai01_spawn()
{
	var p : int;

	p = thePlayer.GetLevel();
	thePlayer.GMTestDummyClearAll();
	thePlayer.GMTestAi01Reset(p);
	GMTestAiSpawn("human", 0, false, 3);			// the entity's own level
	GMTestAiSpawn("human", p + 5, false, 4);		// normal (UI-12: green)
	GMTestAiSpawn("human", p + 6, false, 5);		// high (red)
	GMTestAiSpawn("human", p + 14, false, 6);		// high
	GMTestAiSpawn("human", p + 15, false, 7);		// deadly
	GMTestAiSpawn("human", 1, false, 8);			// raised to Geralt's level - 6 (soft upscaling, DIFF-04's default)
	GMTestAiSpawn("human", 1, true, 9);				// a guard: Geralt's level + 16
	GMTestAiSpawn("wolf", 0, false, 10);
	GMTestAiSpawn("wolf", p + 8, false, 11);
	GMTestAiSpawn("bear", 0, false, 12);
	GMTestAiSpawn("drowner", 0, false, 13);
	GMTestAiSpawn("nekker", p + 6, false, 14);
	GMTestAiSpawn("arachas", 0, false, 15);
	GMTestAiSpawn("werewolf", p + 15, false, 16);
	GMTestAiSpawn("wraith", 0, false, 17);
	LogChannel('GMTest', "INFO AI-01 " + thePlayer.gmTestAiKinds.Size() + " enemies spawned at Geralt's level " + p + "; read them in a later call");
}

// The level legacy's AddLevelBonuses gives under the scaling options in use (DIFF-04's rule, gmTestsDiff04.ws;
// the random types are not predicted: run gmtest_ai01 with another type).
function GMTestAiExpectedLevel(npc : CNewNPC, setLevel : int, guard : bool, p : int) : int
{
	var lvl : int;

	if(setLevel > 0)
		lvl = setLevel - npc.gmCurrentNGPLevel;	// a set level already includes it
	else
		lvl = npc.GMTestEntityLevel();
	if(npc.HasAbility('NPCDoNotGainBoost'))
		return 1;
	return GMTestDiff04Expected(npc, lvl, p, GMGetEnemyScalingOption(), GMGetNoAnimalUpscaling(), GMGetNoAdditionalLevelsForGuards());
}

function GMTestAiLevelAbls() : array<name>
{
	var a : array<name>;

	a.PushBack('NPCLevelBonus');
	a.PushBack('AnimalLevelBonus');
	a.PushBack('MonsterLevelBonus');
	a.PushBack('MonsterLevelBonusGroup');
	a.PushBack('MonsterLevelBonusArmored');
	a.PushBack('MonsterLevelBonusGroupArmored');
	return a;
}

exec function gmtest_ai01_read()
{
	var i, j, n, p, expected, count, total, lvlDiff : int;
	var npc : CNewNPC;
	var abls : array<name>;
	var kindAbl, wantAbl, healthAttr : name;
	var hAttr, apAttr, fAttr : SAbilityAttributeValue;
	var b, m, a, hb0, hm0, ha0, pb0, pm0, pa0, predicted, maxHealth : float;
	var humanSet : bool;
	var hHb0, hHm0, hHa0, hPb0, hPm0, hPa0 : float;
	var high, deadly, wantHigh, wantDeadly, hostile : bool;
	var strLevel, levelKind, wantKind : string;
	var noTags : array<name>;

	thePlayer.GMTestCount(true, true);
	p = thePlayer.GetLevel();
	abls = GMTestAiLevelAbls();
	for(i = 0; i < thePlayer.gmTestDummies.Size() && i < thePlayer.gmTestAiKinds.Size(); i += 1)
	{
		npc = thePlayer.gmTestDummies[i];
		if(!npc)
			continue;
		expected = GMTestAiExpectedLevel(npc, thePlayer.gmTestAiSet[i], thePlayer.gmTestAiGuard[i], p);
		n = expected - 1;
		// the per-level abilities: one kind, one per level above 1
		kindAbl = '';
		total = 0;
		for(j = 0; j < abls.Size(); j += 1)
		{
			count = npc.GetAbilityCount(abls[j]);
			total += count;
			if(count > 0)
				kindAbl = abls[j];
		}
		// the shown level is the template's level attribute (1, but monsters' own abilities may add to it:
		// 5.x's wolf +4, legacy's +0, AI-03) plus DisplayedLevelAbl's
		GMTestReport(npc.currentLevel == expected && npc.GetAbilityCount('DisplayedLevelAbl') == n && total == n
			&& (npc.GetLevel() == expected || thePlayer.gmTestAiKinds[i] != "human")
			&& (n == 0 || npc.GetAbilityCount(kindAbl) == n),
			"AI-01 " + thePlayer.gmTestAiKinds[i] + " (entity level " + npc.GMTestEntityLevel() + ", set " + thePlayer.gmTestAiSet[i] + ", guard " + thePlayer.gmTestAiGuard[i]
			+ ") at Geralt " + p + ": level " + npc.currentLevel + ", shown " + npc.GetLevel() + " (expected " + expected + "); " + n + " x " + kindAbl
			+ ", DisplayedLevelAbl x " + npc.GetAbilityCount('DisplayedLevelAbl'));
		// the kind legacy picks: wolves and boars; Vitality users; Essence users by armor and group
		if((npc.HasAbility('mon_wolf_base') || npc.HasAbility('mon_boar_base') || npc.HasAbility('mon_boar_ep2_base')) && npc.GetStatMax(BCS_Vitality) > 0)
			wantAbl = 'AnimalLevelBonus';
		else if(npc.GetStatMax(BCS_Vitality) > 0)
			wantAbl = 'NPCLevelBonus';
		else if(CalculateAttributeValue(npc.GetTotalArmor()) > 0 && npc.GetIsMonsterTypeGroup())
			wantAbl = 'MonsterLevelBonusGroupArmored';
		else if(CalculateAttributeValue(npc.GetTotalArmor()) > 0)
			wantAbl = 'MonsterLevelBonusArmored';
		else if(npc.GetIsMonsterTypeGroup())
			wantAbl = 'MonsterLevelBonusGroup';
		else
			wantAbl = 'MonsterLevelBonus';
		GMTestReport(n == 0 || kindAbl == wantAbl, "AI-01 " + thePlayer.gmTestAiKinds[i] + "'s per-level ability " + kindAbl + " (" + wantAbl
			+ "; Vitality " + NoTrailZeros(npc.GetStatMax(BCS_Vitality)) + ", armor " + NoTrailZeros(CalculateAttributeValue(npc.GetTotalArmor())) + ", group " + npc.GetIsMonsterTypeGroup() + ")");
		// High and Deadly
		lvlDiff = npc.currentLevel - p;
		hostile = GetAttitudeBetween(npc, thePlayer) == AIA_Hostile && !npc.HasTag('HideHealthBarModule');
		high = npc.HasAbility('NPCLevelBonusHigh') || npc.HasAbility('MonsterLevelBonusHigh');
		deadly = npc.HasAbility('NPCLevelBonusDeadly') || npc.HasAbility('MonsterLevelBonusDeadly');
		wantDeadly = hostile && n > 0 && wantAbl != 'AnimalLevelBonus' && lvlDiff >= 15;	// none for wolves and boars (legacy)
		wantHigh = hostile && n > 0 && wantAbl != 'AnimalLevelBonus' && !wantDeadly && lvlDiff >= 6;
		GMTestReport(high == wantHigh && deadly == wantDeadly,
			"AI-01 " + thePlayer.gmTestAiKinds[i] + " " + lvlDiff + " levels above Geralt: High " + high + ", Deadly " + deadly + " (" + wantHigh + ", " + wantDeadly + ")");
		// health and attack power: legacy's formula, template part + n x the per-level ability
		if(npc.GetStatMax(BCS_Vitality) > 0)
			healthAttr = 'vitality';
		else
			healthAttr = 'essence';
		// the character stats' own reading (the ability manager's GetAttributeValue refuses stat
		// attributes such as vitality and attack_power: -9999, mult 100)
		hAttr = npc.GetCharacterStats().GetAttributeValue(healthAttr, noTags);
		apAttr = npc.GetCharacterStats().GetAttributeValue('attack_power', noTags);
		hb0 = hAttr.valueBase; hm0 = hAttr.valueMultiplicative; ha0 = hAttr.valueAdditive;
		pb0 = apAttr.valueBase; pm0 = apAttr.valueMultiplicative; pa0 = apAttr.valueAdditive;
		if(n > 0)
		{
			GMTestAiAbl(kindAbl, healthAttr, b, m, a);
			hb0 -= n * b; hm0 -= n * m; ha0 -= n * a;
			GMTestAiAbl(kindAbl, 'attack_power', b, m, a);
			pb0 -= n * b; pm0 -= n * m; pa0 -= n * a;
		}
		if(healthAttr == 'vitality')
			maxHealth = npc.GetStatMax(BCS_Vitality);
		else
			maxHealth = npc.GetStatMax(BCS_Essence);
		// 5.x's difficulty multiplier on top (difficulty_Common*'s health_final_multiplier, DIFF's)
		fAttr = npc.GetCharacterStats().GetAttributeValue('health_final_multiplier', noTags);
		predicted = CalculateAttributeValue(hAttr) * MaxF(fAttr.valueAdditive, 0.0001);
		GMTestReport(AbsF(maxHealth - predicted) < 0.5,
			"AI-01 " + thePlayer.gmTestAiKinds[i] + " level " + npc.currentLevel + ": max " + healthAttr + " " + NoTrailZeros(maxHealth)
			+ " = (template " + NoTrailZeros(hb0) + " + " + n + " x per level) x (" + NoTrailZeros(hm0) + " + " + n + " x per level) + " + NoTrailZeros(ha0)
			+ " = " + NoTrailZeros(CalculateAttributeValue(hAttr)) + ", x " + NoTrailZeros(MaxF(fAttr.valueAdditive, 0.0001)) + " (difficulty) = " + NoTrailZeros(predicted) + "; attack power base " + NoTrailZeros(apAttr.valueBase) + ", mult " + NoTrailZeros(apAttr.valueMultiplicative)
			+ ", add " + NoTrailZeros(apAttr.valueAdditive) + " (template " + NoTrailZeros(pb0) + "/" + NoTrailZeros(pm0) + "/" + NoTrailZeros(pa0) + ")");
		// the humans share one template: its part must be the same at every level (no other level term)
		if(thePlayer.gmTestAiKinds[i] == "human")
		{
			if(!humanSet)
			{
				hHb0 = hb0; hHm0 = hm0; hHa0 = ha0; hPb0 = pb0; hPm0 = pm0; hPa0 = pa0;
				humanSet = true;
			}
			else
				GMTestReport(AbsF(hb0 - hHb0) < 0.01 && AbsF(hm0 - hHm0) < 0.001 && AbsF(ha0 - hHa0) < 0.01
					&& AbsF(pb0 - hPb0) < 0.01 && AbsF(pm0 - hPm0) < 0.001 && AbsF(pa0 - hPa0) < 0.01,
					"AI-01 human at level " + npc.currentLevel + ": the template's part equals the first human's (" + NoTrailZeros(hHb0) + "/" + NoTrailZeros(hHm0)
					+ "/" + NoTrailZeros(hHa0) + ", attack power " + NoTrailZeros(hPb0) + "/" + NoTrailZeros(hPm0) + "/" + NoTrailZeros(hPa0) + ")");
			// UI-12 with DA4: red from 6 levels up
			levelKind = npc.GetExperienceDifferenceLevelName(strLevel);
			if(lvlDiff >= 6)
				wantKind = "highLevel";
			else if(lvlDiff > -6)
				wantKind = "normalLevel";
			else
				wantKind = "lowLevel";
			GMTestReport(levelKind == wantKind, "UI-12 a human " + lvlDiff + " levels above Geralt: " + levelKind + " '" + strLevel + "' (" + wantKind + ")");
		}
	}
	LogChannel('GMTest', "SUMMARY ai01_read: " + thePlayer.gmTestPassed + " passed, " + thePlayer.gmTestFailed + " failed");
}

// Recomputes the spawned enemies' bonuses at Geralt's current level (as combat start does).
exec function gmtest_ai01_recalc()
{
	var i : int;

	for(i = 0; i < thePlayer.gmTestDummies.Size(); i += 1)
		if(thePlayer.gmTestDummies[i])
			thePlayer.gmTestDummies[i].RecalcLevel();
	LogChannel('GMTest', "INFO AI-01 bonuses recomputed at Geralt's level " + thePlayer.GetLevel());
}

// Real guards (the world's own NPCs) within range: their level against Geralt's + 16. Each is
// recomputed first (RecalcLevel, as combat start or the HUD's focus does).
exec function gmtest_ai01_guards(optional range : float)
{
	var actors : array<CActor>;
	var npc : CNewNPC;
	var i, found : int;

	if(range <= 0)
		range = 100;
	thePlayer.GMTestCount(true, true);
	actors = thePlayer.GetNPCsAndPlayersInRange(range, 1000, , FLAG_OnlyAliveActors);
	for(i = 0; i < actors.Size(); i += 1)
	{
		npc = (CNewNPC)actors[i];
		if(!npc || npc.GetNPCType() != ENGT_Guard)
			continue;
		found += 1;
		npc.RecalcLevel();
		GMTestReport(npc.currentLevel == thePlayer.GetLevel() + 16 || npc.HasAbility('NPCDoNotGainBoost'),
			"AI-01 guard " + npc.GetDisplayName() + " (" + npc.GetReadableName() + ", " + NoTrailZeros(VecDistance(npc.GetWorldPosition(), thePlayer.GetWorldPosition()))
			+ " m): level " + npc.currentLevel + ", shown " + npc.GetLevel() + " (Geralt " + thePlayer.GetLevel() + " + 16), NPCLevelBonus x " + npc.GetAbilityCount('NPCLevelBonus'));
	}
	LogChannel('GMTest', "SUMMARY ai01_guards: " + found + " guards; " + thePlayer.gmTestPassed + " passed, " + thePlayer.gmTestFailed + " failed");
}

// SKL-12's finisher on death with DA4's threshold: a lone hostile human d levels above Geralt killed by
// his sword gets a finisher below 15 levels (a lone enemy: always) and never from 15 (5.x: 20).
// gmtest_ai01_fin_a(d) draws the steel sword and spawns the human with 1 Vitality; gmtest_ai01_fin_b()
// kills it with a scripted sword hit of Geralt's and reports what CanPerformFinisher decided (probe).
@addField(CR4Player)
var gmTestAiFinisher : int;	// -1 not asked, 0 no, 1 yes
@addField(CR4Player)
var gmTestAiFinisherDiff : int;

@wrapMethod(W3DamageManagerProcessor)
function CanPerformFinisher( actorVictim : CActor ) : bool
{
	var res : bool;
	var npc : CNewNPC;
	var r : int;

	res = wrappedMethod(actorVictim);
	npc = (CNewNPC)actorVictim;
	if(GMTestProbes() && npc && !npc.IsAlive())
	{
		r = 0;
		if(res)
			r = 1;
		thePlayer.GMTestAiFinisherSet(r, npc.currentLevel - thePlayer.GetLevel());
		LogChannel('GMTest', "INFO finisher check on " + npc.GetDisplayName() + " " + (npc.currentLevel - thePlayer.GetLevel()) + " levels above Geralt: " + res);
	}
	return res;
}

exec function gmtest_ai01_fin_a(d : int)
{
	var i, best : int;
	var pos, dir, here : Vector;
	var z, dz, bestDz : float;

	thePlayer.GMTestDummyClearAll();
	thePlayer.OnEquipMeleeWeapon(PW_Steel, true);
	// the finisher needs the victim within 0.4 m of Geralt's height: face the flattest of 16 directions
	bestDz = 100;
	best = 0;
	here = thePlayer.GetWorldPosition();
	for(i = 0; i < 16; i += 1)
	{
		dir = VecFromHeading(i * 22.5);
		pos = thePlayer.GetWorldPosition() + dir * 1.8;
		if(theGame.GetWorld().NavigationComputeZ(pos, pos.Z - 2, pos.Z + 2, z) && theGame.GetWorld().NavigationCircleTest(pos, 2.f))
		{
			dz = AbsF(z - here.Z);
			if(dz < bestDz)
			{
				bestDz = dz;
				best = i;
			}
		}
	}
	thePlayer.TeleportWithRotation(thePlayer.GetWorldPosition(), EulerAngles(0, best * 22.5, 0));
	LogChannel('GMTest', "INFO finisher test: heading " + NoTrailZeros(best * 22.5) + ", ground " + NoTrailZeros(bestDz) + " m from Geralt's height");
	GMTestDummySpawn("human", thePlayer.GetLevel() + d, 1.8);
}

exec function gmtest_ai01_fin_b(d : int)
{
	var npc : CNewNPC;
	var want : int;

	thePlayer.GMTestCount(true, true);
	thePlayer.GMTestSetProbes(true);
	thePlayer.GMTestAiFinisherSet(-1, -999);
	want = 0;
	if(d < theGame.params.LEVEL_DIFF_DEADLY)
		want = 1;
	npc = GMTestDummy();
	if(npc)
	{
		npc.SetAnimationSpeedMultiplier(1);
		npc.ForceSetStat(BCS_Vitality, 1);
		GMTestAlchSwordHitKeep(npc);
	}
	GMTestReport(npc && thePlayer.gmTestAiFinisher == want && thePlayer.gmTestAiFinisherDiff == d,
		"SKL-12 finisher on a lone human " + thePlayer.gmTestAiFinisherDiff + " levels above Geralt: " + thePlayer.gmTestAiFinisher
		+ " (expected " + want + ": none from 15 levels up, DA4; -1: not asked)");
	thePlayer.GMTestSetProbes(false);
	LogChannel('GMTest', "SUMMARY ai01_fin: " + thePlayer.gmTestPassed + " passed, " + thePlayer.gmTestFailed + " failed");
}

// A scripted light sword hit of Geralt's (drawn steel sword) that keeps the result (no heal afterwards).
function GMTestAlchSwordHitKeep(npc : CActor)
{
	var w : W3PlayerWitcher;
	var action : W3Action_Attack;
	var id : SItemUniqueId;

	w = GetWitcherPlayer();
	w.GetItemEquippedOnSlot(EES_SteelSword, id);
	action = new W3Action_Attack in theGame.damageMgr;
	action.Init(w, npc, NULL, id, 'attack_light', w.GetName(), EHRT_Light, false, false, 'attack_light', AST_Jab, ASD_UpDown, true, false, false, false);
	action.SetSuppressHitSounds(true);
	theGame.damageMgr.ProcessAction(action);
	delete action;
}

// The finisher rule's preconditions on the latest dummy (to read why CanPerformFinisher refused).
exec function gmtest_ai01_fin_why()
{
	var npc : CNewNPC;
	var item : SItemUniqueId;
	var v : Vector;
	var targets : array<CActor>;

	npc = GMTestDummy();
	targets = thePlayer.GetMoveTargets();
	if(!npc)
		return;
	item = thePlayer.inv.GetItemFromSlot('l_weapon');
	v = npc.GetWorldPosition() - thePlayer.GetWorldPosition();
	LogChannel('GMTest', "INFO finisher preconditions: steel held " + thePlayer.IsWeaponHeld('steelsword') + ", secondary " + thePlayer.IsSecondaryWeaponHeld()
		+ ", l_weapon " + thePlayer.inv.IsIdValid(item) + ", in finisher " + thePlayer.isInFinisher + ", in air " + thePlayer.IsInAir()
		+ ", vehicle " + thePlayer.IsUsingVehicle() + ", channel " + thePlayer.IsCurrentSignChanneled() + ", DisableFinishers " + npc.HasAbility('DisableFinishers')
		+ ", human " + npc.IsHuman() + ", woman " + npc.IsWoman() + ", alive " + npc.IsAlive() + ", attitude " + npc.GetAttitude(thePlayer)
		+ ", move targets " + targets.Size() + ", dz " + NoTrailZeros(v.Z) + ", nav " + theGame.GetWorld().NavigationCircleTest(npc.GetWorldPosition(), 2.f)
		+ ", ForceFinisher " + npc.HasAbility('ForceFinisher') + ", state " + thePlayer.GetCurrentStateName());
}
