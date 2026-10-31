// DIFF slice D1 (docs/features/diff.md): DIFF-01, the difficulty modes' enemy health and damage multipliers
// (legacy's x0.5/x0.75, x1/x1, x2/x2, x2.5/x3.5; "Death March!" without 5.x's stamina regen and sign
// resistances), and DIFF-03, the prologue's attack-power cut emptied.
//
// In the regression: GMTest_diffdata() (the generated data table, tests/gmTestsDiffData.ws, tools/gen_diff.py).
// In game, on a mode the test sets through the game's own path (SetDifficultyLevel and OnDifficultyChanged,
// what the options menu's confirmation and vanilla's difflevel() call); the caller restores the mode:
//   gmtest_diff01_a()            spawns a frozen hostile bandit and wolf (read them in later calls)
//   gmtest_diff01_modes()        sets each of the four modes in turn and reads both NPCs' multipliers and sign
//                                resistances, then sets back the mode it found
//   gmtest_diff_mode(EDM_Hard)   sets one mode; gmtest_diff01_read() in a later call reads both NPCs'
//                                multipliers and maximum health on it
//   gmtest_diff01_hits()         scripted hits of the bandit and the wolf on Geralt on the current mode
//   gmtest_diff01_bite_a(), _b() a real wolf attack on Geralt (immortal), each hit's difficulty step checked
//   gmtest_diff03()              at Geralt's level 1 on "Just the Story!" or "Story and Sword!": spawned
//                                enemies' attack power with and without PrologModifier

function GMTestDiffNode(abl : name, attr : name, base : float, mult : float, add : float, out checks : int) : int
{
	var b, m, a : float;

	checks += 1;
	GMTestAiAbl(abl, attr, b, m, a);
	if(AbsF(b - base) < 0.001 && AbsF(m - mult) < 0.0001 && AbsF(a - add) < 0.001)
		return 0;
	LogChannel('GMTest', "FAIL DIFF data " + abl + "." + attr + " reads " + NoTrailZeros(b) + "/" + NoTrailZeros(m) + "/" + NoTrailZeros(a)
		+ " (legacy's " + NoTrailZeros(base) + "/" + NoTrailZeros(mult) + "/" + NoTrailZeros(add) + ")");
	return 1;
}

exec function gmtest_diffdata()
{
	thePlayer.GMTestCount(true, true);
	GMTest_diffdata();
	LogChannel('GMTest', "SUMMARY diffdata: " + thePlayer.gmTestPassed + " passed, " + thePlayer.gmTestFailed + " failed");
}

// DIFF-01, DIFF-02, DIFF-03: the abilities as the game reads them (the regression's data check; DIFF-02's
// variants since slice D2). 5.x: health and damage
// +0.1/+0.4, +0.2/+1.3, +0.8/+2.3 ("Just the Story!" -0.5 health, no damage change), Death March's staminaRegen
// x0.2 and +0.1 force, burning, will and shock resistance, PrologModifier attack power x-0.3.
function GMTest_diffdata()
{
	var f, checks : int;

	f = GMTestDiffDataAll(checks);
	GMTestReport(f == 0 && checks == GMTestDiffDataChecks(), "DIFF-01/02/03 data: " + GMTestDiffDataAbilities() + " abilities, " + checks + " attributes read as legacy's (the four modes' health and damage"
		+ " multipliers; Death March without stamina regen or sign resistances; PrologModifier empty; the expansions' per-enemy variants emptied or retuned); " + f + " differ");
}

// Legacy's multipliers per mode (health_final_multiplier and damage_final_multiplier, the 1 included).
function GMTestDiffWant(mode : EDifficultyMode, out hp : float, out dmg : float)
{
	switch(mode)
	{
		case EDM_Easy:		hp = 0.5;	dmg = 0.75;	break;
		case EDM_Medium:	hp = 1;		dmg = 1;	break;
		case EDM_Hard:		hp = 2;		dmg = 2;	break;
		case EDM_Hardcore:	hp = 2.5;	dmg = 3.5;	break;
	}
}

function GMTestDiffModeName(mode : EDifficultyMode) : string
{
	switch(mode)
	{
		case EDM_Easy:		return "Just the Story!";
		case EDM_Medium:	return "Story and Sword!";
		case EDM_Hard:		return "Blood and Broken Bones!";
		case EDM_Hardcore:	return "Death March!";
	}
	return "mode " + (int)mode;
}

// The game's own path for a difficulty change (the options menu's confirmation, vanilla's difflevel()).
function GMTestDiffSetMode(mode : EDifficultyMode)
{
	theGame.SetDifficultyLevel(mode);
	theGame.OnDifficultyChanged(mode);
}

exec function gmtest_diff_mode(mode : EDifficultyMode)
{
	GMTestDiffSetMode(mode);
	LogChannel('GMTest', "INFO DIFF mode set: " + GMTestDiffModeName(theGame.GetDifficultyMode()) + " (spawn mode " + GMTestDiffModeName(theGame.GetSpawnDifficultyMode()) + ")");
}

// The NPC's multipliers as the game uses them: health_final_multiplier's additive part (the maximum health's
// factor, AI-01's tests) and damage_final_multiplier through the ability manager (what DMG-05's final-damage
// step reads).
function GMTestDiffRead(npc : CNewNPC, out hp : float, out dmg : float)
{
	var noTags : array<name>;
	var a : SAbilityAttributeValue;

	a = npc.GetCharacterStats().GetAttributeValue('health_final_multiplier', noTags);
	hp = a.valueAdditive;
	dmg = CalculateAttributeValue(npc.GetAttributeValue(theGame.params.DIFFICULTY_DMG_MULTIPLIER));
}

// The four resistances 5.x's Death March raises by 0.1, summed (the NPC's own plus any ability's).
function GMTestDiffSignRes(npc : CNewNPC) : float
{
	var noTags : array<name>;
	var s : float;
	var a : SAbilityAttributeValue;

	a = npc.GetCharacterStats().GetAttributeValue('force_resistance_perc', noTags);		s += CalculateAttributeValue(a);
	a = npc.GetCharacterStats().GetAttributeValue('burning_resistance_perc', noTags);	s += CalculateAttributeValue(a);
	a = npc.GetCharacterStats().GetAttributeValue('will_resistance_perc', noTags);		s += CalculateAttributeValue(a);
	a = npc.GetCharacterStats().GetAttributeValue('shock_resistance_perc', noTags);		s += CalculateAttributeValue(a);
	return s;
}

function GMTestDiffAbilityOf(mode : EDifficultyMode) : name
{
	switch(mode)
	{
		case EDM_Easy:		return 'difficulty_CommonEasy';
		case EDM_Medium:	return 'difficulty_CommonMedium';
		case EDM_Hard:		return 'difficulty_CommonHard';
		case EDM_Hardcore:	return 'difficulty_CommonHardcore';
	}
	return '';
}

exec function gmtest_diff01_a()
{
	var p : int;

	p = thePlayer.GetLevel();
	thePlayer.GMTestDummyClearAll();
	GMTestDummySpawn("human", p, 4);
	GMTestDummySpawn("wolf", p, 6);
	LogChannel('GMTest', "INFO DIFF-01 " + thePlayer.gmTestDummies.Size() + " NPCs spawned (bandit, wolf) at Geralt's level " + p + " on "
		+ GMTestDiffModeName(theGame.GetDifficultyMode()) + "; read them in a later call");
}

// Each mode in turn, read at once on both NPCs: the mode's ability alone, legacy's multipliers, and the four
// sign resistances as on "Story and Sword!" (5.x's Death March: +0.1 each, +0.4 in all). Sets back the mode
// it found.
exec function gmtest_diff01_modes()
{
	var start, mode : EDifficultyMode;
	var npc : CNewNPC;
	var i, m, others, k : int;
	var hp, dmg, wantHp, wantDmg, res, resMedium : float;
	var modes : array<EDifficultyMode>;
	var resBase : array<float>;

	thePlayer.GMTestCount(true, true);
	start = theGame.GetDifficultyMode();
	modes.PushBack(EDM_Medium); modes.PushBack(EDM_Easy); modes.PushBack(EDM_Hard); modes.PushBack(EDM_Hardcore);
	for(m = 0; m < modes.Size(); m += 1)
	{
		mode = modes[m];
		GMTestDiffSetMode(mode);
		GMTestDiffWant(mode, wantHp, wantDmg);
		for(i = 0; i < thePlayer.gmTestDummies.Size(); i += 1)
		{
			npc = thePlayer.gmTestDummies[i];
			if(!npc)
				continue;
			others = 0;
			for(k = 0; k < modes.Size(); k += 1)
				if(modes[k] != mode && npc.HasAbility(GMTestDiffAbilityOf(modes[k])))
					others += 1;
			GMTestDiffRead(npc, hp, dmg);
			res = GMTestDiffSignRes(npc);
			if(m == 0)
				resBase.PushBack(res);
			GMTestReport(npc.HasAbility(GMTestDiffAbilityOf(mode)) && others == 0 && AbsF(hp - wantHp) < 0.001 && AbsF(dmg - wantDmg) < 0.001 && AbsF(res - resBase[i]) < 0.001,
				"DIFF-01 " + GMTestDiffModeName(mode) + ": the " + npc.GetDisplayName() + " has " + GMTestDiffAbilityOf(mode) + (others > 0 ? " and " + others + " other modes' abilities" : " alone")
				+ ", health x" + NoTrailZeros(hp) + ", damage x" + NoTrailZeros(dmg) + " (legacy's x" + NoTrailZeros(wantHp) + ", x" + NoTrailZeros(wantDmg)
				+ "), sign resistances " + NoTrailZeros(res) + " (as on Story and Sword!: " + NoTrailZeros(resBase[i]) + "; 5.x's Death March +0.4)");
		}
	}
	GMTestDiffSetMode(start);
	LogChannel('GMTest', "INFO DIFF-01 mode set back to " + GMTestDiffModeName(theGame.GetDifficultyMode()));
	LogChannel('GMTest', "SUMMARY diff01_modes: " + thePlayer.gmTestPassed + " passed, " + thePlayer.gmTestFailed + " failed");
}

// On the current mode (set in an earlier call): each NPC's multipliers and maximum health, which must be its
// health attribute x legacy's multiplier.
exec function gmtest_diff01_read()
{
	var npc : CNewNPC;
	var i : int;
	var hp, dmg, wantHp, wantDmg, maxH, predicted : float;
	var noTags : array<name>;
	var h : SAbilityAttributeValue;
	var mode : EDifficultyMode;

	thePlayer.GMTestCount(true, true);
	mode = theGame.GetDifficultyMode();
	GMTestDiffWant(mode, wantHp, wantDmg);
	for(i = 0; i < thePlayer.gmTestDummies.Size(); i += 1)
	{
		npc = thePlayer.gmTestDummies[i];
		if(!npc)
			continue;
		GMTestDiffRead(npc, hp, dmg);
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
		predicted = CalculateAttributeValue(h) * wantHp;
		GMTestReport(AbsF(hp - wantHp) < 0.001 && AbsF(dmg - wantDmg) < 0.001 && AbsF(maxH - predicted) < 0.5,
			"DIFF-01 " + GMTestDiffModeName(mode) + ": the " + npc.GetDisplayName() + " (level " + npc.GetLevel() + ") health x" + NoTrailZeros(hp) + ", damage x" + NoTrailZeros(dmg)
			+ "; maximum health " + NoTrailZeros(maxH) + " = " + NoTrailZeros(CalculateAttributeValue(h)) + " x " + NoTrailZeros(wantHp) + " (" + NoTrailZeros(predicted) + ")");
	}
	LogChannel('GMTest', "SUMMARY diff01_read: " + thePlayer.gmTestPassed + " passed, " + thePlayer.gmTestFailed + " failed");
}

// The difficulty step of hits on Geralt, recorded by the probe below: the attacker, the damage before and
// after DMG-05's final-damage step (GMProcessDamageModification).
@addField(CR4Player)
var gmTestDiffHitWho : array<string>;
@addField(CR4Player)
var gmTestDiffHitBefore : array<float>;
@addField(CR4Player)
var gmTestDiffHitAfter : array<float>;
@addField(CR4Player)
var gmTestDiffHitMult : array<float>;

@addMethod(CR4Player)
function GMTestDiffHitsClear()
{
	gmTestDiffHitWho.Clear();
	gmTestDiffHitBefore.Clear();
	gmTestDiffHitAfter.Clear();
	gmTestDiffHitMult.Clear();
}

@addMethod(CR4Player)
function GMTestDiffHitAdd(who : string, before : float, after : float, mult : float)
{
	gmTestDiffHitWho.PushBack(who);
	gmTestDiffHitBefore.PushBack(before);
	gmTestDiffHitAfter.PushBack(after);
	gmTestDiffHitMult.PushBack(mult);
}

@wrapMethod(W3DamageManagerProcessor)
function GMProcessDamageModification()
{
	var before, mult : float;
	var rec : bool;

	rec = GMTestProbes() && actorVictim == thePlayer && actorAttacker && actorAttacker != thePlayer && action.DealsAnyDamage() && !action.IsDoTDamage();
	if(rec)
		before = action.processedDmg.vitalityDamage;
	wrappedMethod();
	if(rec)
	{
		mult = CalculateAttributeValue(actorAttacker.GetAttributeValue(theGame.params.DIFFICULTY_DMG_MULTIPLIER));
		thePlayer.GMTestDiffHitAdd(actorAttacker.GetDisplayName(), before, action.processedDmg.vitalityDamage, mult);
	}
}

// Checks the recorded hits on the current mode: each one's final damage = its damage before the step x legacy's
// multiplier (hits that start below 1 are left out: DMG-05 zeroes them). Returns the hits checked.
function GMTestDiffCheckHits(label : string) : int
{
	var i, n : int;
	var wantHp, wantDmg : float;
	var mode : EDifficultyMode;
	var w : CR4Player;

	w = thePlayer;
	mode = theGame.GetDifficultyMode();
	GMTestDiffWant(mode, wantHp, wantDmg);
	for(i = 0; i < w.gmTestDiffHitWho.Size(); i += 1)
	{
		if(w.gmTestDiffHitBefore[i] * wantDmg < 1)
			continue;
		n += 1;
		GMTestReport(AbsF(w.gmTestDiffHitAfter[i] - w.gmTestDiffHitBefore[i] * wantDmg) < 0.01 + 0.0001 * w.gmTestDiffHitAfter[i],
			"DIFF-01 " + GMTestDiffModeName(mode) + ", " + label + " " + (i + 1) + " by the " + w.gmTestDiffHitWho[i] + ": " + NoTrailZeros(w.gmTestDiffHitBefore[i])
			+ " before the difficulty step, " + NoTrailZeros(w.gmTestDiffHitAfter[i]) + " after (x" + NoTrailZeros(w.gmTestDiffHitAfter[i] / MaxF(w.gmTestDiffHitBefore[i], 0.0001))
			+ "; legacy's x" + NoTrailZeros(wantDmg) + ", the attacker's multiplier x" + NoTrailZeros(w.gmTestDiffHitMult[i]) + ")");
	}
	return n;
}

// Scripted light attacks (200 slashing) of each spawned NPC on Geralt on the current mode, through the real
// damage manager; Geralt immortal for the hits, his Vitality refilled after each.
exec function gmtest_diff01_hits()
{
	var npc : CNewNPC;
	var i, n : int;
	var probes : bool;

	thePlayer.GMTestCount(true, true);
	probes = GMTestProbes();
	thePlayer.GMTestSetProbes(true);
	thePlayer.GMTestDiffHitsClear();
	GetWitcherPlayer().SetImmortalityMode(AIM_Immortal, AIC_Default, true);
	for(i = 0; i < thePlayer.gmTestDummies.Size(); i += 1)
	{
		npc = thePlayer.gmTestDummies[i];
		if(npc)
			GMTestDmgCustom(npc, thePlayer, theGame.params.DAMAGE_NAME_SLASHING, 200, 0);
	}
	GetWitcherPlayer().SetImmortalityMode(AIM_None, AIC_Default, true);
	thePlayer.GMTestSetProbes(probes);
	n = GMTestDiffCheckHits("scripted hit");
	GMTestReport(n >= 2, "DIFF-01 " + GMTestDiffModeName(theGame.GetDifficultyMode()) + ": " + n + " scripted hits checked");
	LogChannel('GMTest', "SUMMARY diff01_hits: " + thePlayer.gmTestPassed + " passed, " + thePlayer.gmTestFailed + " failed");
}

// A real wolf attack: the spawned wolf (gmtest_diff01_a) runs at normal speed, Geralt immortal and idle; the
// probe records every hit on him. gmtest_diff01_bite_b() some seconds later checks them and freezes the wolf.
exec function gmtest_diff01_bite_a()
{
	var npc : CNewNPC;

	if(thePlayer.gmTestDummies.Size() >= 2)
		npc = thePlayer.gmTestDummies[1];	// gmtest_diff01_a: the bandit, then the wolf
	if(!npc)
	{
		GMTestReport(false, "DIFF-01 bite: no spawned wolf (gmtest_diff01_a() first)");
		return;
	}
	GetWitcherPlayer().SetImmortalityMode(AIM_Immortal, AIC_Default, true);
	thePlayer.ForceSetStat(BCS_Vitality, thePlayer.GetStatMax(BCS_Vitality));
	thePlayer.GMTestDiffHitsClear();
	thePlayer.GMTestSetProbes(true);
	npc.SetAnimationSpeedMultiplier(1);
	LogChannel('GMTest', "INFO DIFF-01 the wolf unfrozen on " + GMTestDiffModeName(theGame.GetDifficultyMode()) + "; Geralt immortal");
}

exec function gmtest_diff01_bite_b()
{
	var i, n : int;

	thePlayer.GMTestCount(true, true);
	for(i = 0; i < thePlayer.gmTestDummies.Size(); i += 1)
		if(thePlayer.gmTestDummies[i])
			GMTestDummyFreeze(thePlayer.gmTestDummies[i]);
	thePlayer.GMTestSetProbes(false);
	n = GMTestDiffCheckHits("real hit");
	GMTestReport(n >= 1, "DIFF-01 " + GMTestDiffModeName(theGame.GetDifficultyMode()) + ": " + n + " real hits on Geralt checked (" + thePlayer.gmTestDiffHitWho.Size() + " recorded)");
	thePlayer.ForceSetStat(BCS_Vitality, thePlayer.GetStatMax(BCS_Vitality));
	GetWitcherPlayer().SetImmortalityMode(AIM_None, AIC_Default, true);
	LogChannel('GMTest', "SUMMARY diff01_bite: " + thePlayer.gmTestPassed + " passed, " + thePlayer.gmTestFailed + " failed");
}

// DIFF-03: 5.x's OnSpawned (1.32's) means to give every non-guard enemy whose own level is above 1
// PrologModifier (5.x: attack power x-0.3) at Geralt's level 1 on "Just the Story!" or "Story and Sword!", but
// tests a local playerLevel it never sets, so it never does (seen 2026-10-29). Enemies of several kinds spawned
// friendly 25 m away at their entity's own level: none got the ability, and each one's attack power with it
// (added by the test) and without it is equal: the ability is empty.
exec function gmtest_diff03()
{
	var npc : CNewNPC;
	var noTags : array<name>;
	var with, without : SAbilityAttributeValue;
	var had : bool;
	var mode : EDifficultyMode;
	var kinds : array<string>;
	var template : CEntityTemplate;
	var i, got : int;

	thePlayer.GMTestCount(true, true);
	mode = theGame.GetDifficultyMode();
	if(thePlayer.GetLevel() != 1 || (mode != EDM_Easy && mode != EDM_Medium))
	{
		GMTestReport(false, "DIFF-03 needs Geralt at level 1 on Just the Story! or Story and Sword! (level " + thePlayer.GetLevel() + ", " + GMTestDiffModeName(mode) + ")");
		return;
	}
	kinds.PushBack("human"); kinds.PushBack("ghoul"); kinds.PushBack("werewolf"); kinds.PushBack("golem"); kinds.PushBack("troll"); kinds.PushBack("endriaga");
	for(i = 0; i < kinds.Size(); i += 1)
	{
		template = (CEntityTemplate)LoadResource(GMTestDummyTemplate(kinds[i]), true);
		npc = (CNewNPC)theGame.CreateEntity(template, thePlayer.GetWorldPosition() + thePlayer.GetHeadingVector() * (25 + 3 * i), VecToRotation(-thePlayer.GetHeadingVector()));
		if(!npc)
		{
			GMTestReport(false, "DIFF-03 " + kinds[i] + " did not spawn");
			continue;
		}
		npc.SetTemporaryAttitudeGroup('friendly_to_player', AGP_Default);
		had = npc.HasAbility('PrologModifier');
		if(had)
			got += 1;
		else
			npc.AddAbility('PrologModifier');
		with = npc.GetCharacterStats().GetAttributeValue('attack_power', noTags);
		npc.RemoveAbility('PrologModifier');
		without = npc.GetCharacterStats().GetAttributeValue('attack_power', noTags);
		GMTestReport(AbsF(with.valueBase - without.valueBase) < 0.0001 && AbsF(with.valueMultiplicative - without.valueMultiplicative) < 0.0001 && AbsF(with.valueAdditive - without.valueAdditive) < 0.0001,
			"DIFF-03 " + GMTestDiffModeName(mode) + ", Geralt level 1: the " + npc.GetDisplayName() + " (entity level " + npc.currentLevel + (had ? ", given PrologModifier at spawn" : ", PrologModifier added by the test")
			+ ") attack power with it " + NoTrailZeros(with.valueBase) + "/" + NoTrailZeros(with.valueMultiplicative) + "/" + NoTrailZeros(with.valueAdditive)
			+ ", without " + NoTrailZeros(without.valueBase) + "/" + NoTrailZeros(without.valueMultiplicative) + "/" + NoTrailZeros(without.valueAdditive) + " (5.x: mult -0.3 with it)");
		npc.Destroy();
	}
	GMTestReport(got == 0, "DIFF-03 " + got + " of " + kinds.Size() + " spawned enemies got PrologModifier from 5.x's OnSpawned (expected none: its playerLevel is never set, so 1.32's and 5.x's"
		+ " cut never applied; the ability is emptied as legacy did)");
	LogChannel('GMTest', "SUMMARY diff03: " + thePlayer.gmTestPassed + " passed, " + thePlayer.gmTestFailed + " failed");
}
