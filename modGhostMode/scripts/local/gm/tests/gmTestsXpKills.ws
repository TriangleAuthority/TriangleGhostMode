// XP-04 and XP-06 checks (slice X3; docs/features/xp.md). They change Geralt (level, experience, crowns) and spawn
// enemies: run them from a freshly loaded test save, outside the regression, and quit without saving.
//
//   gmtest_xp04_spawn()   Geralt raised to 10, the samples spawned frozen and friendly behind him
//   gmtest_xp04()         each sample's kill counts set by script, made hostile and killed by a scripted hit through
//                         the damage manager (the game's own death path, OnDeath); the experience gained, the kill
//                         counter and the combat log line compared with legacy's formula worked by hand
//   gmtest_xp06_a()       a nekker nest spawned and blown up (GMTestNestBlowUp: its Explosion state); the
//                         dialogue payments and the Axii choice through their own PerformAction
//   gmtest_xp06_b()       (5 s later) the nest's 25 XP, its boss's 25 more, the nest rebuilt and blown up again
//   gmtest_xp06_c()       (5 s later) the second destruction gave nothing (once per nest)

@addField(W3PlayerWitcher)
var gmTestXpLog : array<string>;
@addField(W3PlayerWitcher)
var gmTestXpLogOn : bool;
@addField(W3PlayerWitcher)
var gmTestXpNpcs : array<CNewNPC>;
@addField(W3PlayerWitcher)
var gmTestXpLabels : array<string>;
@addField(W3PlayerWitcher)
var gmTestXpNest : CMonsterNestEntity;
@addField(W3PlayerWitcher)
var gmTestXpBefore : int;

@addMethod(W3PlayerWitcher)
function GMTestXpLogStart(on : bool)
{
	if(on)
		gmTestXpLog.Clear();
	gmTestXpLogOn = on;
}

@addMethod(W3PlayerWitcher)
function GMTestXpAddNpc(npc : CNewNPC, label : string)
{
	gmTestXpNpcs.PushBack(npc);
	gmTestXpLabels.PushBack(label);
}

@addMethod(W3PlayerWitcher)
function GMTestXpClear()
{
	var i : int;

	for(i = 0; i < gmTestXpNpcs.Size(); i += 1)
		if(gmTestXpNpcs[i])
			gmTestXpNpcs[i].Destroy();
	gmTestXpNpcs.Clear();
	gmTestXpLabels.Clear();
}

@addMethod(W3PlayerWitcher)
function GMTestXpSetBefore(v : int)
{
	gmTestXpBefore = v;
}

@addMethod(W3PlayerWitcher)
function GMTestXpSetNest(n : CMonsterNestEntity)
{
	gmTestXpNest = n;
}

// Test-only: the HUD console's messages (the combat log) while a check listens.
@wrapMethod(W3GameLog)
function AddMessage(m : string)
{
	var w : W3PlayerWitcher;

	w = GetWitcherPlayer();
	if(w && w.gmTestXpLogOn)
		w.gmTestXpLog.PushBack(m);
	wrappedMethod(m);
}

function GMTestXpPoints() : int
{
	return GetWitcherPlayer().levelManager.GetPointsTotal(EExperiencePoint);
}

// The sample NPCs (label, entity path).
function GMTestXp04Samples(out labels : array<string>) : array<string>
{
	var p : array<string>;
	var i : int;

	for(i = 0; i < 8; i += 1)
	{
		p.PushBack("characters\npc_entities\monsters\drowner_lvl1.w2ent");						labels.PushBack("drowner " + i);
	}
	p.PushBack("characters\npc_entities\monsters\wolf_lvl1.w2ent");								labels.PushBack("wolf");
	p.PushBack("living_world\enemy_templates\baron_renegade_axe.w2ent");						labels.PushBack("bandit");
	p.PushBack("characters\npc_entities\monsters\gryphon_lvl1.w2ent");							labels.PushBack("griffin 0");
	p.PushBack("characters\npc_entities\monsters\gryphon_lvl1.w2ent");							labels.PushBack("griffin 1");
	p.PushBack("quests\minor_quests\no_mans_land\quest_files\mq1051_monster_hunt_nilfgaard1\characters\mq1051_wyvern.w2ent");	labels.PushBack("contract wyvern 0");
	p.PushBack("quests\minor_quests\no_mans_land\quest_files\mq1051_monster_hunt_nilfgaard1\characters\mq1051_wyvern.w2ent");	labels.PushBack("contract wyvern 1");
	p.PushBack("dlc\ep1\data\quests\quest_files\q604_mansion\characters\q604_caretaker.w2ent");	labels.PushBack("boss 0");
	p.PushBack("dlc\ep1\data\quests\quest_files\q604_mansion\characters\q604_caretaker.w2ent");	labels.PushBack("boss 1");
	p.PushBack("characters\npc_entities\crowd_npc\novigrad_soldier\community\novigrad_guard_lvl2_community.w2ent");	labels.PushBack("guard");
	p.PushBack("quests\minor_quests\no_mans_land\quest_files\mq1060_devils_pit\characters\mq1060_witcher.w2ent");	labels.PushBack("Reinald");
	p.PushBack("quests\minor_quests\no_mans_land\quest_files\mq1060_devils_pit\characters\mq1060_evil_spirit.w2ent");	labels.PushBack("red-plague creature");
	p.PushBack("quests\minor_quests\no_mans_land\quest_files\mq1060_devils_pit\characters\mq1060_plague_victim_hostile.w2ent");	labels.PushBack("plague victim");
	return p;
}

exec function gmtest_xp04_spawn()
{
	var w : W3PlayerWitcher;
	var paths, labels : array<string>;
	var npc : CNewNPC;
	var i : int;

	w = GetWitcherPlayer();
	w.GMTestXpClear();
	GMTestXpRaiseTo(10);
	paths = GMTestXp04Samples(labels);
	for(i = 0; i < paths.Size(); i += 1)
	{
		npc = GMTestAi06Spawn(paths[i], 30 + 5 * i);
		if(!npc)
			LogChannel('GMTest', "INFO XP-04 " + labels[i] + " not spawned: " + paths[i]);
		w.GMTestXpAddNpc(npc, labels[i]);
	}
	LogChannel('GMTest', "INFO XP-04 Geralt level " + w.GetLevel() + ", " + w.gmTestXpNpcs.Size() + " samples spawned; kill them in a later call");
}

function GMTestXp04Npc(label : string) : CNewNPC
{
	var w : W3PlayerWitcher;
	var i : int;

	w = GetWitcherPlayer();
	i = w.gmTestXpLabels.FindFirst(label);
	if(i < 0)
		return NULL;
	return w.gmTestXpNpcs[i];
}

// One kill: the NPC at `lvl` (-1: its own level), the kills of its type set to `kills` (-1: as they are), made hostile
// and killed by a scripted hit with Geralt as the attacker. `want` is the experience shown (legacy's formula, by
// hand), `wantGain` what Geralt gains (the same but in NG+), `wantType` its enemy type (-1: not checked).
function GMTestXp04Kill(label : string, lvl : int, kills : int, want : int, wantGain : int, wantType : int, note : string, optional notCounted : bool)
{
	var w : W3PlayerWitcher;
	var npc : CNewNPC;
	var action : W3DamageAction;
	var et : EGMEnemyType;
	var before, gained, kBefore, kAfter, npcLevel, i : int;
	var line, logText, prefix : string;
	var probe : array<int>;
	var params : array<int>;
	var logged, other : bool;

	w = GetWitcherPlayer();
	npc = GMTestXp04Npc(label);
	if(!npc || !npc.IsAlive())
	{
		GMTestReport(false, "XP-04 " + label + " present and alive");
		return;
	}
	if(label == "guard")
		npc.SetNPCType(ENGT_Guard);	// the community guard spawns as a commoner; a guard's group type, as the world's guards
	et = GMGetEnemyTypeByAbility(npc);
	if(npc.GetNPCType() == ENGT_Guard)
		et = GMENT_HUMAN;
	if(lvl >= 0)
		npc.SetLevel(lvl);
	npcLevel = npc.GMTestXpLevel();
	if(kills >= 0)
		w.GMTestKillsAdd(et, kills - w.GMGetKills(et));
	kBefore = w.GMGetKills(et);
	npc.ResetTemporaryAttitudeGroup(AGP_Default);
	npc.SetImmortalityMode(AIM_None, AIC_Default, true);	// quest and community NPCs spawn immortal or unconscious
	npc.SetAttitude(thePlayer, AIA_Hostile);
	before = GMTestXpPoints();
	w.GMTestXpLogStart(true);
	action = new W3DamageAction in theGame.damageMgr;
	action.Initialize(thePlayer, npc, NULL, "gmtest_xp04", EHRT_None, CPS_Undefined, false, false, false, false);
	action.AddDamage(theGame.params.DAMAGE_NAME_DIRECT, npc.GetMaxHealth() * 10 + 1000000);
	theGame.damageMgr.ProcessAction(action);
	delete action;
	w.GMTestXpLogStart(false);
	gained = GMTestXpPoints() - before;
	kAfter = w.GMGetKills(et);
	params.PushBack(want);
	line = GetLocStringByKeyExtWithParams("hud_combat_log_gained_experience", params);
	probe.PushBack(12345);
	prefix = StrBeforeFirst(GetLocStringByKeyExtWithParams("hud_combat_log_gained_experience", probe), "12345");
	logged = false;
	other = false;
	for(i = 0; i < w.gmTestXpLog.Size(); i += 1)
	{
		logText += " [" + w.gmTestXpLog[i] + "]";
		if(w.gmTestXpLog[i] == line)
			logged = true;
		else if(StrFindFirst(w.gmTestXpLog[i], prefix) >= 0)
			other = true;
	}
	if(want == 0)
		logged = !other && !logged;	// a kill without experience logs none
	GMTestReport((!npc.IsAlive() || label == "guard") && gained == wantGain && logged && kAfter == kBefore + 1 - (int)notCounted && (wantType < 0 || (int)et == wantType),
		"XP-04 " + label + " (" + npc.GetDisplayName(false) + ", type " + et + ", level " + npcLevel + ", Geralt " + w.GetLevel() + ", " + kBefore
		+ " earlier kills" + note + "; alive " + npc.IsAlive() + "): +" + gained + " XP (want " + wantGain + "), kills " + kBefore + " -> " + kAfter + ", log:" + logText);
}

exec function gmtest_xp04()
{
	var w : W3PlayerWitcher;
	var counts : array<int>;
	var i, p, ngp : int;

	w = GetWitcherPlayer();
	thePlayer.GMTestCount(true, true);
	for(i = 0; i < (int)GMENT_MAX_TYPES; i += 1)
		counts.PushBack(w.GMGetKills(i));
	p = w.GetLevel();
	GMTestReport(p == 10, "XP-04 Geralt at level 10 (" + p + ")");
	// base x clamp(1 + 0.16 x (enemy level - Geralt's), 0, 1.5) x (1 - min(kills, 100) / 100), rounded, at least 1
	GMTestXp04Kill("drowner 0", p, 0, 5, 5, (int)GMENT_DROWNER, "");					// 5 x 1 x 1
	GMTestXp04Kill("drowner 1", p, 50, 2, 2, (int)GMENT_DROWNER, "");					// 5 x 0.5 = 2.5, truncated (RoundF)
	GMTestXp04Kill("drowner 2", p, 100, 1, 1, (int)GMENT_DROWNER, "");					// 0, the minimum
	GMTestXp04Kill("drowner 3", p + 5, 0, 7, 7, (int)GMENT_DROWNER, ", 5 levels up");	// 5 x 1.5 (cap; 1.8) = 7.5, truncated
	GMTestXp04Kill("drowner 4", p - 3, 0, 2, 2, (int)GMENT_DROWNER, ", 3 levels down");	// 5 x 0.52 = 2.6, truncated
	GMTestXp04Kill("drowner 5", p - 7, 0, 1, 1, (int)GMENT_DROWNER, ", 7 levels down");	// 5 x 0 (-0.12), the minimum
	GMTestXp04Kill("wolf", p, 0, 1, 1, (int)GMENT_WOLF, "");							// 1
	GMTestXp04Kill("bandit", p, 0, 5, 5, (int)GMENT_HUMAN, "");							// 5
	GMTestXp04Kill("griffin 0", p + 3, 0, 14, 14, (int)GMENT_GRYPHON, ", 3 levels up");	// 10 x 1.48 = 14.8, truncated
	GMTestXp04Kill("griffin 1", p, 50, 5, 5, (int)GMENT_GRYPHON, "");					// 10 x 0.5
	GMTestXp04Kill("contract wyvern 0", p, 0, 15, 15, (int)GMENT_WYVERN, ", contract");	// 15 (a wyvern alone 5)
	GMTestXp04Kill("contract wyvern 1", p, 40, 9, 9, (int)GMENT_WYVERN, ", contract");	// 15 x 0.6, the wyverns' kills
	GMTestXp04Kill("boss 0", p, 50, 20, 20, (int)GMENT_BOSS, "");						// 20, never cut
	GMTestXp04Kill("boss 1", p + 3, 100, 29, 29, (int)GMENT_BOSS, ", 3 levels up");		// 20 x 1.48 = 29.6, truncated
	// the community guard stays knocked out (its unconscious mode holds) but its OnDeath runs (the counter shows it)
	GMTestXp04Kill("guard", p, 0, 0, 0, (int)GMENT_HUMAN, ", a guard");					// none; counted as a human
	// DX4: 5.x's new enemies, the type of their creature
	GMTestXp04Kill("Reinald", p, 0, 0, 0, -1, ", 5.x", true);							// his entity grants no kill experience (5.x's too): none, not counted
	GMTestXp04Kill("red-plague creature", p, 0, 15, 15, (int)GMENT_BOSS, ", 5.x");		// a contract monster (15) with the Hym's boss ability (mon_him): never cut
	GMTestXp04Kill("plague victim", p, 0, 5, 5, (int)GMENT_HUMAN, ", 5.x");				// ConDefaultSilver: a human
	// DIFF's default soft upscaling: a level-1 drowner lifted to 6 below Geralt, then the minimum (legacy's)
	GMTestXp04Kill("drowner 6", -1, 0, 1, 1, (int)GMENT_DROWNER, ", its own level after scaling");	// 5 x 0.04 = 0.2
	// DX3: NG+ (the facts set and taken back here, nothing saved): the NG+ level off the enemy's level only, so an
	// enemy at Geralt's level is 30 levels "below" him: 1 XP, doubled by 5.x's AddPoints in NG+ below level 50
	ngp = theGame.params.GetNewGamePlusLevel();
	FactsAdd("NewGamePlus", 1);
	theGame.params.GMTestSetNGPLevel(30);
	GMTestXp04Kill("drowner 7", p, 0, 1, 2, (int)GMENT_DROWNER, ", NG+ level 30");		// 5 x 0 (1 - 0.16 x 30), the minimum
	FactsRemove("NewGamePlus");
	theGame.params.GMTestSetNGPLevel(ngp);
	GMTestReport(FactsQuerySum("NewGamePlus") == 0 && theGame.params.GetNewGamePlusLevel() == ngp, "XP-04 NG+ facts back (" + ngp + ")");
	// the counts back as they were
	for(i = 0; i < (int)GMENT_MAX_TYPES; i += 1)
		w.GMTestKillsAdd(i, counts[i] - w.GMGetKills(i));
	GMTestReport(w.GMGetKills(GMENT_DROWNER) == counts[(int)GMENT_DROWNER] && w.GMGetKills(GMENT_HUMAN) == counts[(int)GMENT_HUMAN], "XP-04 kill counts back");
	w.GMTestXpClear();
	LogChannel('GMTest', "SUMMARY xp04: " + thePlayer.gmTestPassed + " passed, " + thePlayer.gmTestFailed + " failed");
}

@addMethod(W3GameParams)
function GMTestSetNGPLevel(l : int)
{
	newGamePlusLevel = l;
}

@addMethod(CNewNPC)
function GMTestXpLevel() : int
{
	return currentLevel;
}

// What decides a sample's kill experience: class, the no-experience flags, group type, attitude, abilities.
@addMethod(CNewNPC)
function GMTestXpProbe() : string
{
	var abls : array<name>;
	var s : string;
	var i : int;

	GetCharacterStats().GetAbilities(abls, false);
	for(i = 0; i < abls.Size(); i += 1)
		s += NameToString(abls[i]) + ",";
	return "contract " + (bool)((W3MonsterHuntNPC)this) + ", grantNoExperienceAfterKill " + grantNoExperienceAfterKill
		+ ", npc type " + GetNPCType() + ", attitude " + GetAttitudeBetween(thePlayer, this) + ", currentLevel " + currentLevel + ", abilities " + s;
}

exec function gmtest_xp04_probe()
{
	var w : W3PlayerWitcher;
	var i : int;

	w = GetWitcherPlayer();
	for(i = 0; i < w.gmTestXpNpcs.Size(); i += 1)
		if(w.gmTestXpNpcs[i])
			LogChannel('GMTest', "INFO XP-04 probe " + w.gmTestXpLabels[i] + ": " + w.gmTestXpNpcs[i].GMTestXpProbe());
}

// ---- XP-06 ----

@addMethod(CMonsterNestEntity)
function GMTestNestInfo() : string
{
	return "interactionOnly " + interactionOnly + ", entity values: nest " + expOnNestDestroyed + ", boss " + bonusExpOnBossKilled + ", once " + addExpOnlyOnce + "; expWasAdded " + expWasAdded + ", state " + GetCurrentStateName();
}

@addMethod(CMonsterNestEntity)
function GMTestNestRebuild()
{
	wasExploded = false;
	if(interactionComponent)
		interactionComponent.SetEnabled(true);
	GotoState('Intact');
}

// The nest blown up: by fire (OnFireHit, what a bomb's explosion calls) unless the nest takes only a placed bomb
// (interactionOnly); then as OnInteraction does once Geralt has a bomb, with the bomb placed (SettingExplosives' end,
// without Geralt's animation and the bomb item): the Explosion state, which adds the experience.
@addMethod(CMonsterNestEntity)
function GMTestNestBlowUp() : string
{
	if(!interactionOnly)
	{
		OnFireHit(thePlayer);
		return "fire (OnFireHit)";
	}
	wasExploded = true;
	GetEncounter();
	if(interactionComponent)
		interactionComponent.SetEnabled(false);
	GotoState('Explosion');
	return "a placed bomb (the Explosion state)";
}

@addMethod(CMonsterNestEntity)
function GMTestNestMapName() : name
{
	return entityName;
}

@addMethod(CPayStorySceneChoiceAction)
function GMTestSet(m : int)
{
	money = m;
}

@addMethod(CPayFactBasedStorySceneChoiceAction)
function GMTestSet(f : string)
{
	valueFact = f;
}

// A choice action's experience: Geralt's experience before and after its PerformAction, as a scene calls it.
function GMTestXp06Choice(kind : string, want : int, label : string)
{
	var pay : CPayStorySceneChoiceAction;
	var fact : CPayFactBasedStorySceneChoiceAction;
	var axii : CAxiiStorySceneChoiceAction;
	var before, money : int;

	before = GMTestXpPoints();
	money = thePlayer.GetMoney();
	if(kind == "pay")
	{
		pay = new CPayStorySceneChoiceAction in thePlayer;
		pay.GMTestSet(300);
		pay.PerformAction();
	}
	else if(kind == "fact")
	{
		FactsAdd("gmtest_xp06_bribe", 120);
		fact = new CPayFactBasedStorySceneChoiceAction in thePlayer;
		fact.GMTestSet("gmtest_xp06_bribe");
		fact.PerformAction();
		FactsRemove("gmtest_xp06_bribe");
	}
	else
	{
		axii = new CAxiiStorySceneChoiceAction in thePlayer;
		axii.PerformAction();
	}
	GMTestReport(GMTestXpPoints() - before == want, "XP-06 " + label + ": +" + (GMTestXpPoints() - before) + " XP (want " + want + "), crowns " + money + " -> " + thePlayer.GetMoney());
}

exec function gmtest_xp06_a()
{
	var w : W3PlayerWitcher;
	var template : CEntityTemplate;
	var nest : CMonsterNestEntity;
	var pos : Vector;
	var money : int;

	w = GetWitcherPlayer();
	thePlayer.GMTestCount(true, true);
	money = thePlayer.GetMoney();
	thePlayer.AddMoney(1000);
	GMTestXp06Choice("pay", 5, "a dialogue payment of 300 crowns (CPayStorySceneChoiceAction; 5.x 30)");
	GMTestXp06Choice("fact", 5, "a bribe of 120 crowns from a fact (CPayFactBasedStorySceneChoiceAction; 5.x 12)");
	GMTestXp06Choice("axii", 5 * w.GetAxiiLevel(), "an Axii choice at Axii level " + w.GetAxiiLevel() + " (CAxiiStorySceneChoiceAction; 5.x " + (20 + 5 * w.GetAxiiLevel()) + ")");
	thePlayer.RemoveMoney(thePlayer.GetMoney() - money);
	GMTestReport(thePlayer.GetMoney() == money, "XP-06 crowns back (" + money + ")");

	template = (CEntityTemplate)LoadResource("gameplay\interactive_objects\monster_nest\monster_nest_nekker.w2ent", true);
	pos = thePlayer.GetWorldPosition() - thePlayer.GetHeadingVector() * 15;
	nest = (CMonsterNestEntity)theGame.CreateEntity(template, pos, thePlayer.GetWorldRotation());
	if(!nest)
	{
		GMTestReport(false, "XP-06 nest spawned");
		return;
	}
	w.GMTestXpSetNest(nest);
	nest.AddTag('AchievementFireInTheHoleExcluded');	// no destroyed-nest statistic for the test
	if(FactsQuerySum(nest.GMTestNestMapName() + "_nest_destr") == 0)
		FactsAdd(nest.GMTestNestMapName() + "_nest_destr");	// no achievement check for the test
	LogChannel('GMTest', "INFO XP-06 nest " + nest.GMTestNestMapName() + ": " + nest.GMTestNestInfo());
	w.GMTestXpSetBefore(GMTestXpPoints());
	LogChannel('GMTest', "INFO XP-06 nest blown up by " + nest.GMTestNestBlowUp() + "; read in a later call (gmtest_xp06_b)");
}

exec function gmtest_xp06_b()
{
	var w : W3PlayerWitcher;
	var nest : CMonsterNestEntity;
	var before : int;

	w = GetWitcherPlayer();
	nest = w.gmTestXpNest;
	if(!nest)
	{
		GMTestReport(false, "XP-06 nest present");
		return;
	}
	GMTestReport(GMTestXpPoints() - w.gmTestXpBefore == 25, "XP-06 the nest destroyed: +" + (GMTestXpPoints() - w.gmTestXpBefore) + " XP (want 25; 5.x the entity's value); " + nest.GMTestNestInfo());
	before = GMTestXpPoints();
	nest.SetBossKilled(true);
	GMTestReport(GMTestXpPoints() - before == 25, "XP-06 its boss killed (SetBossKilled): +" + (GMTestXpPoints() - before) + " XP (want 25)");
	nest.GMTestNestRebuild();
	w.GMTestXpSetBefore(GMTestXpPoints());
	LogChannel('GMTest', "INFO XP-06 nest rebuilt and blown up again by " + nest.GMTestNestBlowUp() + "; read in a later call (gmtest_xp06_c)");
}

exec function gmtest_xp06_c()
{
	var w : W3PlayerWitcher;
	var nest : CMonsterNestEntity;

	w = GetWitcherPlayer();
	nest = w.gmTestXpNest;
	if(nest)
	{
		GMTestReport(GMTestXpPoints() - w.gmTestXpBefore == 0, "XP-06 the same nest destroyed again: +" + (GMTestXpPoints() - w.gmTestXpBefore) + " XP (want 0, once per nest); " + nest.GMTestNestInfo());
		FactsRemove(nest.GMTestNestMapName() + "_nest_destr");
		nest.Destroy();
	}
	LogChannel('GMTest', "SUMMARY xp06: " + thePlayer.gmTestPassed + " passed, " + thePlayer.gmTestFailed + " failed");
}
