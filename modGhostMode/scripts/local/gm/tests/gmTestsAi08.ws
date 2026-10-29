// AI slice B1 tests (AI-08 combat parameters, AI-09 dodging, AI-10 guarding and taunts); docs/features/ai.md.
//
// Regression (gmtest_regress): GMTest_ai08() reads the rolls' data and the changed defaults. Scripted checks
// in a game: gmtest_ai10_window_a/_b (the 2.5 s counter window), gmtest_ai10_shield (a broken shield in a fight);
// the window and a scripted shield break are also in the regression (GMTest_ai10, GMTest_ai10_after).
//
// Real fights: gmtest_ai08_fight_a("<entity path, forward slashes>", n) spawns a hostile enemy (health refilled at each swing)
// 3 m ahead and makes n real light attacks (the input handler, one every 1.4 s, Geralt immortal, both
// sides' stamina kept full so every roll is a roll); test probes log every decision the enemy's AI makes
// (dodge rolls, counter rolls, guard rolls, parries, taunts) as "AI08EV" lines in the script log;
// gmtest_ai08_fight_b() stops, sums them up and removes the enemy. Lock on (autolock()) after _a.

@addField(CR4Player)
var gmTestAi08Npc : CNewNPC;
@addField(CR4Player)
var gmTestAi08Shield : CNewNPC;
@addField(CR4Player)
var gmTestAi08Left : int;

@addMethod(CR4Player)
function GMTestAi08SetShield(npc : CNewNPC)
{
	gmTestAi08Shield = npc;
}
@addField(CR4Player)
var gmTestAi08Swings : int;
// Per kind (GMTestAi08Kind): rolls asked, rolls that said yes, chance sum (percent).
@addField(CR4Player)
var gmTestAi08Asked : array<int>;
@addField(CR4Player)
var gmTestAi08Yes : array<int>;
@addField(CR4Player)
var gmTestAi08Chance : array<float>;
@addField(CR4Player)
var gmTestAi08Attacking : int;

// 0 dodge roll (light attack), 1 dodge roll (other), 2 dodge-task counter, 3 parry-task counter,
// 4 parry (ShouldCounter), 5 hit-reaction guard or counter, 6 additive-hit guard or counter, 7 parry
// performed, 8 taunt roll, 9 dodge started
function GMTestAi08KindName(k : int) : string
{
	switch(k)
	{
		case 0: return "dodge roll vs light attack";
		case 1: return "dodge roll vs other";
		case 2: return "dodge-task counter roll";
		case 3: return "parry-task counter roll";
		case 4: return "counter after parries";
		case 5: return "hit reaction: guard or counter";
		case 6: return "additive hit: guard or counter";
		case 7: return "parry tried";
		case 8: return "taunt roll";
		case 9: return "dodge started";
	}
	return "?";
}

@addMethod(CR4Player)
function GMTestAi08Reset()
{
	var i : int;

	gmTestAi08Asked.Clear();
	gmTestAi08Yes.Clear();
	gmTestAi08Chance.Clear();
	for(i = 0; i < 10; i += 1)
	{
		gmTestAi08Asked.PushBack(0);
		gmTestAi08Yes.PushBack(0);
		gmTestAi08Chance.PushBack(0);
	}
	gmTestAi08Attacking = 0;
	gmTestAi08Swings = 0;
}

@addMethod(CR4Player)
function GMTestAi08Note(k : int, npc : CActor, chance : float, yes : bool, extra : string)
{
	if(gmTestAi08Asked.Size() < 10)
		GMTestAi08Reset();
	gmTestAi08Asked[k] += 1;
	if(yes)
		gmTestAi08Yes[k] += 1;
	gmTestAi08Chance[k] += chance;
	if(k == 8)
		return;	// taunt rolls come every tick once the delay has passed: counted, not logged
	LogChannel('GMTestAI', "AI08EV k=" + k + " npc=" + npc.GetReadableName() + " swing=" + gmTestAi08Swings + " chance=" + NoTrailZeros(chance)
		+ " yes=" + yes + " " + extra);
}

// The fight's enemy only (other NPCs around are not counted).
function GMTestAi08Probe(npc : CActor) : bool
{
	return GMTestProbes() && npc && npc == thePlayer.gmTestAi08Npc;
}

@wrapMethod(CBTTaskDodge)
function ChooseAndCheckDodge() : bool
{
	var ret, attacking : bool;
	var chance : int;

	ret = wrappedMethod();
	if(GMTestAi08Probe(GetNPC()))
	{
		switch (dodgeType)
		{
			case EDT_Attack_Light 	: chance = dodgeChanceAttackLight; 	break;
			case EDT_Attack_Heavy	: chance = dodgeChanceAttackHeavy; 	break;
			case EDT_Aard			: chance = dodgeChanceAard; 		break;
			case EDT_Igni			: chance = dodgeChanceIgni; 		break;
			case EDT_Bomb			: chance = dodgeChanceBomb; 		break;
			case EDT_Projectile		: chance = dodgeChanceProjectile; 	break;
			case EDT_Fear			: chance = dodgeChanceFear; 		break;
		}
		InitializeCombatDataStorage();
		attacking = combatDataStorage.GetIsAttacking();
		thePlayer.GMTestAi08Note(((dodgeType == EDT_Attack_Light) ? 0 : 1), GetNPC(), chance, ret, "type=" + dodgeType + " attacking=" + attacking + " task=dodge");
	}
	return ret;
}

@wrapMethod(CBTTaskCircularDodge)
function ChooseAndCheckDodge() : bool
{
	var ret : bool;
	var chance : int;

	ret = wrappedMethod();
	if(GMTestAi08Probe(GetNPC()))
	{
		switch (dodgeType)
		{
			case EDT_Attack_Light 	: chance = dodgeChanceAttackLight; 	break;
			case EDT_Attack_Heavy	: chance = dodgeChanceAttackHeavy; 	break;
			case EDT_Projectile		: chance = dodgeChanceProjectile; 	break;
		}
		thePlayer.GMTestAi08Note(((dodgeType == EDT_Attack_Light) ? 0 : 1), GetNPC(), chance, ret, "type=" + dodgeType + " task=circular");
	}
	return ret;
}

@wrapMethod(CBTTaskDodge)
function OnActivate() : EBTNodeStatus
{
	var ret : EBTNodeStatus;

	ret = wrappedMethod();
	if(GMTestAi08Probe(GetNPC()))
		thePlayer.GMTestAi08Note(9, GetNPC(), 0, ret != BTNS_Failed, "status=" + ret);
	return ret;
}

@wrapMethod(CBTTaskDodge)
function CheckCounter() : bool
{
	var ret : bool;

	ret = wrappedMethod();
	if(GMTestAi08Probe(GetNPC()))
		thePlayer.GMTestAi08Note(2, GetNPC(), counterChance, ret, "defends=" + GetNPC().GetDefendCounter() + " need=" + hitsToCounter);
	return ret;
}

@wrapMethod(CBTTaskPerformParry)
function CheckCounter() : bool
{
	var ret : bool;

	ret = wrappedMethod();
	if(GMTestAi08Probe(GetNPC()))
		thePlayer.GMTestAi08Note(3, GetNPC(), counterChance, ret, "defends=" + GetNPC().GetDefendCounter() + " need=" + hitsToCounter);
	return ret;
}

@wrapMethod(CBTTaskPerformParry)
function ShouldCounter(isHeavy : bool) : bool
{
	var ret : bool;

	ret = wrappedMethod(isHeavy);
	if(GMTestAi08Probe(GetNPC()))
		thePlayer.GMTestAi08Note(4, GetNPC(), counterChance, ret, "parries=" + ((CHumanAICombatStorage)combatDataStorage).GetParryCount() + " need=" + hitsToCounter + " heavy=" + isHeavy);
	return ret;
}

@wrapMethod(CBTTaskPerformParry)
function TryToParry(optional counter : bool) : bool
{
	var ret : bool;

	ret = wrappedMethod(counter);
	if(GMTestAi08Probe(GetNPC()))
		thePlayer.GMTestAi08Note(7, GetNPC(), parryChance, ret, "counter=" + counter);
	return ret;
}

@wrapMethod(CBTTaskHitReactionDecorator)
function CheckGuardOrCounter() : bool
{
	var ret : bool;

	ret = wrappedMethod();
	if(GMTestAi08Probe(GetNPC()))
		thePlayer.GMTestAi08Note(5, GetNPC(), raiseGuardChance, ret, "hits=" + GetNPC().GetHitCounter() + " guardNeed=" + hitsToRaiseGuard
			+ " counterChance=" + counterChance + " counterNeed=" + hitsToCounter + " guarded=" + GetNPC().IsGuarded());
	return ret;
}

@wrapMethod(BTTaskAdditiveHitListener)
function CheckGuardOrCounter() : bool
{
	var ret : bool;

	ret = wrappedMethod();
	if(GMTestAi08Probe(GetNPC()))
		thePlayer.GMTestAi08Note(6, GetNPC(), raiseGuardChance, ret, "hits=" + GetNPC().GetHitCounter() + " guardNeed=" + hitsToRaiseGuard
			+ " counterChance=" + counterChance + " counterNeed=" + hitsToCounter + " guarded=" + GetNPC().IsGuarded());
	return ret;
}

// Taunts: the task is asked every tick; only the asks past the taunt delay roll (5.x: no roll at all).
@wrapMethod(CBTTaskTaunt)
function IsAvailable() : bool
{
	var ret : bool;

	ret = wrappedMethod();
	// A roll happens once the taunt delay has passed (5.x's check above it); log those asks only.
	if(GMTestAi08Probe(GetActor()) && !( tauntDelay > 0 && timeStamp > 0 && ( timeStamp + tauntDelay > GetLocalTime() ) ))
		thePlayer.GMTestAi08Note(8, GetActor(), 100 * CalculateAttributeValue(GetActor().GetAttributeValue('taunt_chance')), ret, "type=" + tauntType);
	return ret;
}

// ---- real fights ----

exec function gmtest_ai08_fight_a(path : string, n : int, optional silver : bool)
{
	var template : CEntityTemplate;
	var npc : CNewNPC;
	var w : W3PlayerWitcher;

	w = GetWitcherPlayer();
	if(thePlayer.gmTestAi08Npc)
		thePlayer.gmTestAi08Npc.Destroy();
	template = (CEntityTemplate)LoadResource(path, true);
	if(!template)
	{
		LogChannel('GMTest', "INFO AI-08 fight: no template " + path);
		return;
	}
	npc = (CNewNPC)theGame.CreateEntity(template, thePlayer.GetWorldPosition() + thePlayer.GetHeadingVector() * 3, VecToRotation(-thePlayer.GetHeadingVector()));
	if(!npc)
		return;
	npc.SetTemporaryAttitudeGroup('hostile_to_player', AGP_Default);
	w.GMTestAi08Start(npc, n, silver);
}

@addMethod(W3PlayerWitcher)
function GMTestAi08Start(npc : CNewNPC, n : int, silver : bool)
{
	gmTestAi08Npc = npc;
	gmTestAi08Left = n;
	GMTestAi08Reset();
	SetImmortalityMode(AIM_Immortal, AIC_Default, true);
	GMTestSetProbes(true);
	if(silver)
		OnEquipMeleeWeapon(PW_Silver, true);
	else
		OnEquipMeleeWeapon(PW_Steel, true);
	AddTimer('GMTestAi08Swing', 1.4, true);
	LogChannel('GMTest', "INFO AI-08 fight: " + npc.GetReadableName() + " level " + npc.GetLevel() + ", " + n + " light attacks");
}

@addMethod(W3PlayerWitcher)
timer function GMTestAi08Swing(dt : float, id : int)
{
	var npc : CNewNPC;

	npc = gmTestAi08Npc;
	if(gmTestAi08Left <= 0 || !npc || !npc.IsAlive())
	{
		RemoveTimer('GMTestAi08Swing');
		return;
	}
	gmTestAi08Left -= 1;
	gmTestAi08Swings += 1;
	GainStat(BCS_Stamina, GetStatMax(BCS_Stamina));
	ForceSetStat(BCS_Vitality, GetStatMax(BCS_Vitality));
	npc.GainStat(BCS_Stamina, npc.GetStatMax(BCS_Stamina));
	if(npc.UsesEssence())
		npc.ForceSetStat(BCS_Essence, npc.GetStatMax(BCS_Essence));
	else
		npc.ForceSetStat(BCS_Vitality, npc.GetStatMax(BCS_Vitality));
	GMTestActInput(0, true);
	GMTestActInput(0, false);
}

exec function gmtest_ai08_fight_b()
{
	var i : int;
	var npc : CNewNPC;

	GetWitcherPlayer().RemoveTimer('GMTestAi08Swing');
	npc = thePlayer.gmTestAi08Npc;
	LogChannel('GMTest', "INFO AI-08 fight " + (npc ? npc.GetReadableName() : "(gone)") + ": " + thePlayer.gmTestAi08Swings + " swings");
	for(i = 0; i < thePlayer.gmTestAi08Asked.Size(); i += 1)
		if(thePlayer.gmTestAi08Asked[i] > 0)
			LogChannel('GMTest', "INFO AI-08   " + GMTestAi08KindName(i) + ": " + thePlayer.gmTestAi08Yes[i] + " of " + thePlayer.gmTestAi08Asked[i]
				+ ", mean chance " + NoTrailZeros(thePlayer.gmTestAi08Chance[i] / thePlayer.gmTestAi08Asked[i]) + "%");
	thePlayer.GMTestSetProbes(false);
	if(npc)
		npc.Destroy();
	thePlayer.SetImmortalityMode(AIM_None, AIC_Default, true);
}

// ---- AI-10: the hit and defend counters' window (2.5 s), scripted on a spawned NPC ----

@addField(CActor)
var gmTestAi10Samples : array<int>;

@addMethod(CActor)
timer function GMTestAi10Sample(dt : float, id : int)
{
	gmTestAi10Samples.PushBack(GetHitCounter());
	gmTestAi10Samples.PushBack(GetDefendCounter());
}

@addMethod(CActor)
timer function GMTestAi10Sample2(dt : float, id : int)
{
	gmTestAi10Samples.PushBack(GetHitCounter());
	gmTestAi10Samples.PushBack(GetDefendCounter());
}

@addMethod(CActor)
function GMTestAi10Start()
{
	gmTestAi10Samples.Clear();
	IncHitCounter();
	IncDefendCounter();
	AddTimer('GMTestAi10Sample', 2.25, false);
	AddTimer('GMTestAi10Sample2', 2.6, false);
}

exec function gmtest_ai10_window_a()
{
	var npc : CNewNPC;

	npc = GMTestAi06Spawn("living_world/enemy_templates/nilfgaardian_deserter_sword_hard.w2ent", 6);
	thePlayer.GMTestAi08SetShield(npc);
	npc.GMTestAi10Start();
	LogChannel('GMTest', "INFO AI-10 counters raised on " + npc.GetReadableName() + ": hits " + npc.GetHitCounter() + ", defends " + npc.GetDefendCounter());
}

exec function gmtest_ai10_window_b()
{
	var npc : CNewNPC;
	var s : array<int>;

	npc = thePlayer.gmTestAi08Shield;
	s = npc.gmTestAi10Samples;
	if(s.Size() < 4)
	{
		LogChannel('GMTest', "INFO AI-10 samples not taken yet (" + s.Size() + ")");
		return;
	}
	GMTestReport(s[0] == 1 && s[1] == 1, "AI-10 hit and defend counters still held at 2.25 s: " + s[0] + ", " + s[1] + " (1, 1; 5.x reset at 2 s)");
	GMTestReport(s[2] == 0 && s[3] == 0, "AI-10 hit and defend counters reset by 2.6 s: " + s[2] + ", " + s[3] + " (0, 0)");
	npc.Destroy();
}

// ---- AI-10 regression (AI-B audit F2): the counters' window and a broken shield on spawned NPCs ----

@addField(CR4Player)
var gmTestAi10Npcs : array<CNewNPC>;

@addMethod(W3PlayerWitcher)
function GMTestAi10Set(npcs : array<CNewNPC>)
{
	gmTestAi10Npcs = npcs;
}

// In gmtest_regress(): spawns a deserter (frozen, friendly, behind Geralt) and raises its hit and defend counters,
// sampled by its timers at 2.25 and 2.6 s (gmtest_regress() is run with --wait 3000 before the panel), and a
// shield bearer for the shield check. GMTest_ai10_after() (gmtest_panel()) reports and removes them.
function GMTest_ai10()
{
	var npcs : array<CNewNPC>;
	var window, shield : CNewNPC;

	window = GMTestAi06Spawn("living_world/enemy_templates/nilfgaardian_deserter_sword_hard.w2ent", 40);
	shield = GMTestAi06Spawn("living_world/enemy_templates/nilfgaardian_deserter_shield.w2ent", 43);
	if(window)
		window.GMTestAi10Start();
	npcs.PushBack(window);
	npcs.PushBack(shield);
	GetWitcherPlayer().GMTestAi10Set(npcs);
	GMTestReport(window && window.GetHitCounter() == 1 && window.GetDefendCounter() == 1 && shield,
		"AI-10 a deserter's hit and defend counters raised (" + (window ? window.GetHitCounter() + ", " + window.GetDefendCounter() : "no NPC") + "), a shield bearer spawned " + (bool)shield);
}

function GMTest_ai10_after()
{
	var npcs : array<CNewNPC>;
	var window, shield : CNewNPC;
	var s : array<int>;
	var guardUp : bool;

	npcs = thePlayer.gmTestAi10Npcs;
	if(npcs.Size() < 2 || !npcs[0] || !npcs[1])
	{
		GMTestReport(false, "AI-10 test NPCs spawned (" + npcs.Size() + ")");
		return;
	}
	window = npcs[0];
	shield = npcs[1];
	s = window.gmTestAi10Samples;
	if(s.Size() < 4)
		GMTestReport(false, "AI-10 counters' window: samples taken at 2.25 and 2.6 s (" + s.Size() / 2 + " of 2; run gmtest_regress() with --wait 3000)");
	else
	{
		GMTestReport(s[0] == 1 && s[1] == 1, "AI-10 hit and defend counters still held at 2.25 s: " + s[0] + ", " + s[1] + " (1, 1; 5.x reset at 2 s)");
		GMTestReport(s[2] == 0 && s[3] == 0, "AI-10 hit and defend counters reset by 2.6 s: " + s[2] + ", " + s[3] + " (0, 0; the window 2.5 s)");
	}

	// A broken shield (the function bombs, Axii, Iris and STAM-08's empty-stamina drop call), scripted. Neutral to
	// Geralt: 5.x's stagger names him as its creator, and negative effects from a friendly creator are refused.
	shield.SetAttitude(thePlayer, AIA_Neutral);
	shield.RaiseShield();
	guardUp = shield.GetBehaviorVariable('bShieldUp') == 1;
	shield.ProcessShieldDestruction();
	GMTestReport(!shield.HasBuff(EET_Stagger) && shield.GetBehaviorVariable('bShieldUp') == 0,
		"AI-10 a broken shield does not stagger and lowers the guard: staggered " + shield.HasBuff(EET_Stagger) + ", guard " + shield.GetBehaviorVariable('bShieldUp')
		+ " (false, 0; 5.x staggered; the guard read " + guardUp + " after raising it, a frozen NPC's graph may not take it: the guard is shown in the fight, gmtest_ai10_shield)");

	window.Destroy();
	shield.Destroy();
	npcs.Clear();
	GetWitcherPlayer().GMTestAi10Set(npcs);
}

// ---- regression ----

exec function gmtest_ai08()
{
	thePlayer.GMTestCount(true, true);
	GMTest_ai08();
	LogChannel('GMTest', "SUMMARY ai08: " + thePlayer.gmTestPassed + " passed, " + thePlayer.gmTestFailed + " failed");
}

function GMTestAi08Abl(abl : name, attr : name) : float
{
	var b, m, a : float;

	GMTestAiAbl(abl, attr, b, m, a);
	return b + a;
}

// AI-08: sample rolls (the full table is GMTest_ai03's generated one). AI-09, AI-10: the defaults the
// slice changes.
function GMTest_ai08()
{
	var dodgeDef : CBTTaskDodgeDef;
	var tauntDef : CBTTaskTauntDef;
	var taunt : CAIMonsterTauntParams;
	var npc : CNewNPC;
	var b, m, a : float;
	var minV, maxV : SAbilityAttributeValue;

	GMTestReport(AbsF(GMTestAi08Abl('mon_bear_base', 'dodge_melee_light_chance') - 0.2) < 0.001
		&& AbsF(GMTestAi08Abl('mon_endriaga_base', 'dodge_melee_light_chance') - 0.2) < 0.001,
		"AI-08 bears and endregas dodge light attacks 20%: " + GMTestAi08Abl('mon_bear_base', 'dodge_melee_light_chance') + ", "
		+ GMTestAi08Abl('mon_endriaga_base', 'dodge_melee_light_chance') + " (5.x 0.95)");
	GMTestReport(AbsF(GMTestAi08Abl('mon_golem_base', 'counter_chance') - 0.8) < 0.001 && GMTestAi08Abl('mon_golem_base', 'hits_to_roll_counter') == 0,
		"AI-08 golems counter 80% from the first hit: " + GMTestAi08Abl('mon_golem_base', 'counter_chance') + ", after " + GMTestAi08Abl('mon_golem_base', 'hits_to_roll_counter')
		+ " (5.x 1.0 after 2)");
	GMTestReport(GMTestAi08Abl('SkillPeasant', 'hits_to_raise_guard') == 0 && GMTestAi08Abl('SkillPeasant', 'hits_to_roll_counter') == 0
		&& AbsF(GMTestAi08Abl('SkillPeasant', 'raise_guard_chance_mult_per_hit') - 0.1) < 0.001 && AbsF(GMTestAi08Abl('SkillSoldier', 'raise_guard_chance') - 0.3) < 0.001,
		"AI-08 humans guard and counter from the first hit, +10% guard per hit: peasant guard after " + GMTestAi08Abl('SkillPeasant', 'hits_to_raise_guard')
		+ ", counter after " + GMTestAi08Abl('SkillPeasant', 'hits_to_roll_counter') + ", +" + GMTestAi08Abl('SkillPeasant', 'raise_guard_chance_mult_per_hit')
		+ " per hit; soldier guard " + GMTestAi08Abl('SkillSoldier', 'raise_guard_chance') + " (5.x after 3 and 2, 0.7)");
	GMTestReport(AbsF(GMTestAi08Abl('WildHunt_Eredin', 'counter_chance') - 0.6) < 0.001 && AbsF(GMTestAi08Abl('WildHunt_Eredin', 'essence') - 2500) < 0.001,
		"AI-08 Eredin's rolls legacy's, and since AI-15 (slice C1) his stats too: counter " + GMTestAi08Abl('WildHunt_Eredin', 'counter_chance')
		+ ", Essence " + GMTestAi08Abl('WildHunt_Eredin', 'essence') + " (0.6, 2500; 5.x 1.0, 8000)");
	theGame.GetDefinitionsManager().GetAbilityAttributeValue('SkillShield', 'counter_chance', minV, maxV);
	GMTestReport(AbsF(minV.valueAdditive - 0.4) < 0.001 && AbsF(maxV.valueAdditive - 0.4) < 0.001,
		"AI-08 shield bearers counter 40% (legacy kept 1.32's 0.4): " + NoTrailZeros(minV.valueAdditive) + " to " + NoTrailZeros(maxV.valueAdditive) + " (5.x 0.3 to 0.5)");
	GMTestAiAbl('ConDefault', 'moraleRegen', b, m, a);
	GMTestReport(AbsF(m - 0.1) < 0.0001, "AI-08 ConDefault's morale regen legacy's: x" + NoTrailZeros(m) + " (0.1; 5.x 0.08 to 0.12)");

	dodgeDef = new CBTTaskDodgeDef in theGame;
	GMTestReport(dodgeDef.maxDistanceFromTarget == 3, "AI-09 enemies dodge within " + dodgeDef.maxDistanceFromTarget + " m of their target (3; 5.x 5)");
	tauntDef = new CBTTaskTauntDef in theGame;
	GMTestReport(tauntDef.useXMLTauntChance, "AI-10 taunt task rolls the XML chance by default: " + tauntDef.useXMLTauntChance + " (true)");
	taunt = new CAIMonsterTauntParams in theGame;
	GMTestReport(taunt.tauntDelay == 5 && taunt.forceAttackDelay == 10, "AI-10 monsters taunt every " + taunt.tauntDelay + " s and attack after " + taunt.forceAttackDelay + " s (5, 10; 5.x 3, 20)");

}

// AI-10: a broken shield lowers the guard and does not stagger its holder (5.x: the guard stays up, a stagger).
// Scripted shield break (the function bombs, Axii, Iris and STAM-08's empty-stamina drop call) on the fight's
// enemy: a shield bearer in a real fight (gmtest_ai08_fight_a("living_world/enemy_templates/
// nilfgaardian_deserter_shield.w2ent", n), a few swings later, when it holds its shield up).
exec function gmtest_ai10_shield()
{
	var npc : CNewNPC;
	var inv : CInventoryComponent;
	var held, guardUp : bool;

	npc = thePlayer.gmTestAi08Npc;
	if(!npc)
		return;
	inv = npc.GetInventory();
	held = inv.IsIdValid(inv.GetItemFromSlot('l_weapon'));
	npc.RaiseShield();
	guardUp = npc.GetBehaviorVariable('bShieldUp') == 1;
	npc.ProcessShieldDestruction();
	GMTestReport(held && guardUp && !npc.HasBuff(EET_Stagger) && npc.GetBehaviorVariable('bShieldUp') == 0 && !inv.IsIdValid(inv.GetItemFromSlot('l_weapon')),
		"AI-10 broken shield: held " + held + ", guard up " + guardUp + "; then staggered " + npc.HasBuff(EET_Stagger) + ", guard " + npc.GetBehaviorVariable('bShieldUp')
		+ ", dropped " + !inv.IsIdValid(inv.GetItemFromSlot('l_weapon')) + " (true, true; false, 0, true; 5.x staggered, guard stays up)");
}

// Sets the fight enemy's armor (the test dummy's step abilities), so Geralt's hits at level 1 deal damage
// and play hit reactions (a hit below 1 plays none, DMG-01): golems.
exec function gmtest_ai08_armor(value : float)
{
	var npc : CNewNPC;
	var armor : SAbilityAttributeValue;
	var ok : bool;

	npc = thePlayer.gmTestAi08Npc;
	if(!npc)
		return;
	ok = GMTestDummySet(npc, 'armor', value);
	armor = npc.GetTotalArmor();
	LogChannel('GMTest', "INFO AI-08 fight enemy armor set " + ok + ": " + NoTrailZeros(armor.valueAdditive));
}

// AI-09: the air and ground guard on the NPCs within 30 m (e.g. a harpy in flight).
exec function gmtest_ai09_air()
{
	var actors : array<CActor>;
	var npc : CNewNPC;
	var i : int;

	actors = thePlayer.GetNPCsAndPlayersInRange(30, 20, , FLAG_OnlyAliveActors);
	for(i = 0; i < actors.Size(); i += 1)
	{
		npc = (CNewNPC)actors[i];
		if(npc)
			LogChannel('GMTest', "INFO AI-09 " + npc.GetReadableName() + ": in air " + npc.IsInAir() + ", on ground " + npc.IsOnGround()
				+ ", height above ground " + NoTrailZeros(npc.GetDistanceFromGround(10)) + ", no dodge (GMEnemyCannotDodge) " + GMEnemyCannotDodge(npc));
	}
}
