// Checks added for the XP audit's findings (docs/features/xp.md, "XP audit close-out"). Outside the regression but for
// the kill-earner check: they change Geralt (level, experience, effects) and spawn NPCs. Run them from a freshly loaded save with saves locked
// (gmtest_nosave()), and quit without saving.
//
//   gmtest_xp04_who_spawn()   F4/F1: Geralt raised to 10; four drowners spawned frozen at 10, 6, 8 and 45 m behind him,
//                             a friendly renegade and a friendly Novigrad guard (given the guard group type)
//   gmtest_xp04_who()         each drowner made hostile and killed by a scripted hit through the damage manager
//                             (OnDeath): by Geralt, by the renegade (6 m), by the guard (8 m), by the renegade (45 m).
//                             Legacy's (1.32's) rule: only Geralt's kill gives experience and counts (F1's fix,
//                             xp/killEarner.ws). Also in the regression: the samples spawned by gmtest_regress(), the
//                             kills in gmtest_panel()
//   gmtest_skl01_tooltip()    F2: with the character menu open (dupemenu() in an earlier call), its two locked-slot
//                             events called as its Flash does; the tooltip text is "Slot unlocked at level: N"
//   gmtest_xp08_vit_a()       F4: Blood and Wine's "Well rested" given (+500 maximum Vitality)
//   gmtest_xp08_vit_b()       (a later call) its Vitality checked, Geralt set to 60%, the values kept in facts, the save
//                             lock lifted and a new manual slot saved; lock saves again with gmtest_nosave() afterwards
//   gmtest_xp08_vit_c()       after loading that slot: the effect was back when XP-08's load recompute ran, and the
//                             maximum and current Vitality are the saved ones

// ---- F4/F1: who earns a kill's experience ----

// The samples: four drowners frozen at 10, 6, 8 and 45 m behind Geralt, a friendly renegade and a friendly Novigrad
// guard (given the guard group type). In the regression (GMTest_xp04_who_spawn(false)) at Geralt's level as it is;
// the kills follow in gmtest_panel() (GMTest_xp04_who_after).
function GMTest_xp04_who_spawn(raise : bool)
{
	var w : W3PlayerWitcher;
	var npc : CNewNPC;
	var dist : array<float>;
	var i : int;

	w = GetWitcherPlayer();
	w.GMTestXpClear();
	if(raise)
		GMTestXpRaiseTo(10);
	dist.PushBack(10); dist.PushBack(6); dist.PushBack(8); dist.PushBack(45);
	for(i = 0; i < dist.Size(); i += 1)
	{
		npc = GMTestAi06Spawn("characters\npc_entities\monsters\drowner_lvl1.w2ent", dist[i]);
		w.GMTestXpAddNpc(npc, "who drowner " + i);
	}
	npc = GMTestAi06Spawn("living_world\enemy_templates\baron_renegade_axe.w2ent", 14);
	w.GMTestXpAddNpc(npc, "who renegade");
	npc = GMTestAi06Spawn("characters\npc_entities\crowd_npc\novigrad_soldier\community\novigrad_guard_lvl2_community.w2ent", 16);
	if(npc)
		npc.SetNPCType(ENGT_Guard);
	w.GMTestXpAddNpc(npc, "who guard");
	LogChannel('GMTest', "INFO XP-04 who: Geralt level " + w.GetLevel() + ", " + w.gmTestXpNpcs.Size() + " NPCs spawned; the kills in a later call");
}

exec function gmtest_xp04_who_spawn()
{
	GMTest_xp04_who_spawn(true);
}

// Test-only: experience a check gave taken back (the regression restores what it changes).
@addMethod(W3LevelManager)
function GMTestTakeExp(n : int)
{
	if(n > 0 && points[EExperiencePoint].free >= n)
		points[EExperiencePoint].free -= n;
}

// One kill of drowner i (at Geralt's level, no earlier drowner kills: 5 XP) by `attacker`, made hostile to Geralt and
// killed by a scripted hit through the damage manager (OnDeath). Legacy's rule: `want` XP and `wantCount` kills more.
function GMTestXpWhoKill(i : int, attacker : CActor, who : string, want : int, wantCount : int)
{
	var w : W3PlayerWitcher;
	var npc : CNewNPC;
	var action : W3DamageAction;
	var before, gained, kBefore, kAfter : int;
	var dist : float;

	w = GetWitcherPlayer();
	npc = GMTestXp04Npc("who drowner " + i);
	if(!npc || !npc.IsAlive() || !attacker)
	{
		GMTestReport(false, "XP-04 who: drowner " + i + " and " + who + " present");
		return;
	}
	npc.SetLevel(w.GetLevel());
	w.GMTestKillsAdd(GMENT_DROWNER, -w.GMGetKills(GMENT_DROWNER));
	kBefore = w.GMGetKills(GMENT_DROWNER);
	npc.ResetTemporaryAttitudeGroup(AGP_Default);
	npc.SetAttitude(thePlayer, AIA_Hostile);
	dist = VecDistance(thePlayer.GetWorldPosition(), npc.GetWorldPosition());
	before = GMTestXpPoints();
	action = new W3DamageAction in theGame.damageMgr;
	action.Initialize(attacker, npc, NULL, "gmtest_xp04_who", EHRT_None, CPS_Undefined, false, false, false, false);
	action.AddDamage(theGame.params.DAMAGE_NAME_DIRECT, npc.GetMaxHealth() * 10 + 1000000);
	theGame.damageMgr.ProcessAction(action);
	delete action;
	gained = GMTestXpPoints() - before;
	kAfter = w.GMGetKills(GMENT_DROWNER);
	w.levelManager.GMTestTakeExp(gained);
	GMTestReport(!npc.IsAlive() && gained == want && kAfter == kBefore + wantCount,
		"XP-04 who: a drowner at Geralt's level " + NoTrailZeros(RoundMath(dist * 10) / 10.0) + " m from him killed by " + who + " (attitude to Geralt "
		+ GetAttitudeBetween(thePlayer, attacker) + "): +" + gained + " XP (legacy " + want + "), drowner kills " + kBefore + " -> " + kAfter
		+ " (legacy +" + wantCount + "); alive " + npc.IsAlive());
}

// XP audit F1 (owner's decision (a)): 1.32's and legacy's CNewNPC.ShouldGiveExp: the player's own kill; within 20 m a
// non-actor's, a party companion's or an Axii'd NPC's, never a guard's. 5.x also gave any NPC friendly to Geralt within
// 30 m. Experience and kill counts put back.
function GMTest_xp04_who_after()
{
	var w : W3PlayerWitcher;
	var renegade, guard : CNewNPC;
	var kills, exp : int;

	w = GetWitcherPlayer();
	exp = GMTestXpPoints();
	w.GMIncKills(GMENT_DROWNER);	// sizes an empty counter (a save without kills); taken back below
	kills = w.GMGetKills(GMENT_DROWNER) - 1;
	renegade = GMTestXp04Npc("who renegade");
	guard = GMTestXp04Npc("who guard");
	GMTestReport(guard && guard.GetNPCType() == ENGT_Guard, "XP-04 who: the guard has the guard group type (Geralt level " + w.GetLevel() + ")");
	GMTestXpWhoKill(0, thePlayer, "Geralt", 5, 1);
	GMTestXpWhoKill(1, renegade, "a friendly renegade", 0, 0);
	GMTestXpWhoKill(2, guard, "a friendly guard", 0, 0);
	GMTestXpWhoKill(3, renegade, "a friendly renegade far away", 0, 0);
	w.GMTestKillsAdd(GMENT_DROWNER, kills - w.GMGetKills(GMENT_DROWNER));
	GMTestReport(w.GMGetKills(GMENT_DROWNER) == kills && GMTestXpPoints() == exp, "XP-04 who: drowner kills (" + kills + ") and experience (" + exp + ") back");
	w.GMTestXpClear();
}

exec function gmtest_xp04_who()
{
	thePlayer.GMTestCount(true, true);
	GMTest_xp04_who_after();
	LogChannel('GMTest', "SUMMARY xp04_who: " + thePlayer.gmTestPassed + " passed, " + thePlayer.gmTestFailed + " failed");
}

// ---- F2: the locked-slot tooltips of the new character menu ----

@addField(W3PlayerWitcher)
var gmTestSlotText : array<string>;

// Test-only: the texts the tooltips get.
@wrapMethod
function GMLockedSlotDescription(mutagen : bool, unlockedAtLevel : int) : string
{
	var s : string;
	var w : W3PlayerWitcher;

	s = wrappedMethod(mutagen, unlockedAtLevel);
	w = GetWitcherPlayer();
	if(w)
		w.gmTestSlotText.PushBack(s);
	return s;
}

@addMethod(W3PlayerWitcher)
function GMTestSlotTextClear()
{
	gmTestSlotText.Clear();
}

exec function gmtest_skl01_tooltip()
{
	var w : W3PlayerWitcher;
	var menu : CR4CharacterDupeMenu;
	var skillText, mutText, points : string;
	var params : array<int>;

	w = GetWitcherPlayer();
	thePlayer.GMTestCount(true, true);
	// the strings: 1.32's and legacy's, by id and by key alike, in the game's language
	GMTestReport(GetLocStringById(1070951) != "" && GetLocStringByKeyExt("panel_character_tooltip_skill_locked_desc") == GetLocStringById(1070951),
		"SKL-01 tooltip: string 1070951 (panel_character_tooltip_skill_locked_desc) reads \"" + GetLocStringById(1070951) + "\"");
	GMTestReport(GetLocStringById(1070952) != "" && GetLocStringByKeyExt("panel_character_tooltip_mutagen_locked_desc") == GetLocStringById(1070952),
		"SKL-01 tooltip: string 1070952 (panel_character_tooltip_mutagen_locked_desc) reads \"" + GetLocStringById(1070952) + "\"");
	params.PushBack(28);
	points = GetLocStringByKeyExtWithParams("skill_slot_unlock_description", params);
	LogChannel('GMTest', "INFO SKL-01 tooltip: 5.x's text with 28: \"" + points + "\"");

	menu = GMTestOpenCharacterMenu();
	if(!menu)
	{
		GMTestReport(false, "SKL-01 tooltip: the new character menu is open (dupemenu() in an earlier call)");
		LogChannel('GMTest', "SUMMARY skl01_tooltip: " + thePlayer.gmTestPassed + " passed, " + thePlayer.gmTestFailed + " failed");
		return;
	}
	skillText = GetLocStringById(1070951) + ": 12";
	mutText = GetLocStringById(1070952) + ": 28";
	w.GMTestSlotTextClear();
	menu.OnGetLockedTooltipData(12);
	GMTestReport(w.gmTestSlotText.Size() == 1 && w.gmTestSlotText[0] == skillText,
		"SKL-01 tooltip: a locked skill slot (level 12) gets \"" + skillText + "\" (" + w.gmTestSlotText.Size() + " texts set" + GMTestSlotTextList(w) + ")");
	w.GMTestSlotTextClear();
	menu.OnGetMutagenLockedTooltipData(28);
	GMTestReport(w.gmTestSlotText.Size() == 1 && w.gmTestSlotText[0] == mutText,
		"SKL-01 tooltip: a locked skill mutagen slot (level 28) gets \"" + mutText + "\" (" + w.gmTestSlotText.Size() + " texts set" + GMTestSlotTextList(w) + ")");
	w.GMTestSlotTextClear();
	LogChannel('GMTest', "SUMMARY skl01_tooltip: " + thePlayer.gmTestPassed + " passed, " + thePlayer.gmTestFailed + " failed");
}

function GMTestSlotTextList(w : W3PlayerWitcher) : string
{
	var i : int;
	var s : string;

	for(i = 0; i < w.gmTestSlotText.Size(); i += 1)
		s += ": \"" + w.gmTestSlotText[i] + "\"";
	return s;
}

// ---- F4: XP-08's load recompute with a Vitality effect active ----

@addField(W3PlayerWitcher)
var gmTestVitProbe : string;
@addField(W3PlayerWitcher)
var gmTestVitBefore : float;
@addField(W3PlayerWitcher)
var gmTestVitRan : bool;
@addField(W3PlayerWitcher)
var gmTestVitChanged : bool;

// Test-only: the state when the load recompute runs.
@wrapMethod(W3PlayerWitcher)
function GMRecomputeVitalityAtLoad() : bool
{
	var oldMax : float;
	var changed : bool;

	oldMax = GetStatMax(BCS_Vitality);
	gmTestVitProbe = "effect " + HasBuff(EET_WellRested) + ", its ability " + HasAbility('WellRestedEffect') + ", stored maximum " + NoTrailZeros(oldMax)
		+ ", current " + NoTrailZeros(GetStat(BCS_Vitality, true));
	changed = wrappedMethod();
	gmTestVitRan = true;
	gmTestVitChanged = changed;
	gmTestVitProbe += "; recomputed maximum changed " + changed + "; after: maximum " + NoTrailZeros(GetStatMax(BCS_Vitality)) + ", current " + NoTrailZeros(GetStat(BCS_Vitality, true));
	return changed;
}

@addMethod(W3PlayerWitcher)
function GMTestVitSetBefore(v : float)
{
	gmTestVitBefore = v;
}

@addMethod(W3PlayerWitcher)
function GMTestUnlockSaves()
{
	theGame.ReleaseNoSaveLock(gmTestNoSaveLock);
}

function GMTestWellRestedVit() : float
{
	var dm : CDefinitionsManagerAccessor;
	var min, max : SAbilityAttributeValue;

	dm = theGame.GetDefinitionsManager();
	dm.GetAbilityAttributeValue('WellRestedEffect', 'vitality', min, max);
	return min.valueAdditive;
}

exec function gmtest_xp08_vit_a()
{
	var w : W3PlayerWitcher;

	w = GetWitcherPlayer();
	w.GMTestVitSetBefore(w.GetStatMax(BCS_Vitality));
	w.AddEffectDefault(EET_WellRested, w, "gmtest");
	// the base effect's OnEffectAdded adds the effect's ability (seen: +500 at once); added here only if it did not
	if(!w.HasAbility('WellRestedEffect'))
		w.AddAbility('WellRestedEffect', true);
	LogChannel('GMTest', "INFO XP-08 vit: maximum Vitality " + NoTrailZeros(w.gmTestVitBefore) + " before; effect " + w.HasBuff(EET_WellRested) + ", ability " + w.HasAbility('WellRestedEffect')
		+ " (definition +" + NoTrailZeros(GMTestWellRestedVit()) + "); check in a later call");
}

exec function gmtest_xp08_vit_b(save : bool)
{
	var w : W3PlayerWitcher;
	var vmax, cur : float;

	w = GetWitcherPlayer();
	thePlayer.GMTestCount(true, true);
	vmax = w.GetStatMax(BCS_Vitality);
	GMTestReport(w.HasBuff(EET_WellRested) && w.HasAbility('WellRestedEffect') && AbsF(vmax - w.gmTestVitBefore - GMTestWellRestedVit()) < 0.5,
		"XP-08 vit: \"Well rested\" active, maximum Vitality " + NoTrailZeros(w.gmTestVitBefore) + " -> " + NoTrailZeros(vmax) + " (+" + NoTrailZeros(GMTestWellRestedVit()) + ")");
	w.ForceSetStat(BCS_Vitality, vmax * 0.6);
	cur = w.GetStat(BCS_Vitality, true);
	FactsRemove("gmtest_xp08v_max");
	FactsRemove("gmtest_xp08v_cur");
	FactsAdd("gmtest_xp08v_max", RoundMath(vmax));
	FactsAdd("gmtest_xp08v_cur", RoundMath(cur));
	LogChannel('GMTest', "INFO XP-08 vit: before the save: maximum " + NoTrailZeros(vmax) + ", current " + NoTrailZeros(cur) + " (60%), level " + w.GetLevel());
	if(save)
	{
		w.GMTestUnlockSaves();
		LogChannel('GMTest', "INFO XP-08 vit: save lock lifted (" + theGame.AreSavesLocked() + "); saving a new manual slot");
		theGame.SaveGame(SGT_Manual, -1);
	}
	LogChannel('GMTest', "SUMMARY xp08_vit_b: " + thePlayer.gmTestPassed + " passed, " + thePlayer.gmTestFailed + " failed");
}

exec function gmtest_xp08_vit_c()
{
	var w : W3PlayerWitcher;
	var vmax, cur, wantMax, wantCur : float;

	w = GetWitcherPlayer();
	thePlayer.GMTestCount(true, true);
	wantMax = FactsQuerySum("gmtest_xp08v_max");
	wantCur = FactsQuerySum("gmtest_xp08v_cur");
	vmax = w.GetStatMax(BCS_Vitality);
	cur = w.GetStat(BCS_Vitality, true);
	LogChannel('GMTest', "INFO XP-08 vit: at the load recompute: " + w.gmTestVitProbe);
	GMTestReport(wantMax > 0 && w.gmTestVitRan, "XP-08 vit: a save made with \"Well rested\" (saved maximum " + NoTrailZeros(wantMax) + ", current " + NoTrailZeros(wantCur) + "), the load recompute ran");
	GMTestReport(StrFindFirst(w.gmTestVitProbe, "effect true, its ability true") == 0, "XP-08 vit: the effect and its ability were back when the recompute ran (" + w.gmTestVitProbe + ")");
	GMTestReport(w.gmTestVitRan && !w.gmTestVitChanged, "XP-08 vit: the recompute found the saved maximum (the effect's +500 counted; changed " + w.gmTestVitChanged + ")");
	GMTestReport(w.HasBuff(EET_WellRested) && w.HasAbility('WellRestedEffect'), "XP-08 vit: the effect is active after the load");
	GMTestReport(AbsF(vmax - wantMax) < 1, "XP-08 vit: maximum Vitality after the load " + NoTrailZeros(vmax) + " (saved " + NoTrailZeros(wantMax) + ")");
	GMTestReport(AbsF(cur - wantCur) < 1, "XP-08 vit: Vitality after the load " + NoTrailZeros(cur) + " (saved " + NoTrailZeros(wantCur) + ")");
	LogChannel('GMTest', "SUMMARY xp08_vit_c: " + thePlayer.gmTestPassed + " passed, " + thePlayer.gmTestFailed + " failed");
}
