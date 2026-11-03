// AI slice B3 tests (AI-14, monster fixes); docs/features/ai.md.
//
// Regression: GMTest_ai14() (gmtest_regress) spawns a cyclops (frozen) and an arachas (not frozen), friendly, far
// behind Geralt, and checks NPC Quen's stagger helper; GMTest_ai14_after() (gmtest_panel, after the level-bonus
// timer) checks the cyclops lost ablIgnoreSigns and the arachas moves at 75% animation speed, with one speed
// causer (never id 0) across a recompute, under Yrden's real slowdown effect and 5.x's frost slowdown and back at
// 0.75 after each, and removes them. Fight checks: gmTestsAi14Fights.ws.
//
// Real fights (probes log "B3EV" lines, channel GMTestAI): gmtest_ai14_a("<path>", distance) spawns an enemy
// hostile `distance` m ahead, Geralt immortal, the probes on, and samples it every 0.25 s (Axii's confusion and
// critical state, Yrden's lock, its animation speed and ground speed); gmtest_ai14_b() sums up and removes it.
// gmtest_ai14_speed(mult) sets the arachas's own speed causer (AI-14's) to compare speeds in one session.
//
// Checks in a real fight, automated, each with PASS/FAIL lines and a SUMMARY (not in gmtest_regress: they fight;
// run after it, god() off): gmtest_ai14_toad() (the toad stays in its Yrden task after a third hit: a real Yrden
// cast through the input handler, the hit counter raised by script) and gmtest_ai14_quen() (an NPC's Quen staggers
// Geralt for the default through CBTTaskCastQuen.ProcessAction: Reinald, real light attacks).

@addField(CR4Player)
var gmTestAi14Npcs : array<CNewNPC>;
@addField(CR4Player)
var gmTestAi14Npc : CNewNPC;
@addField(CR4Player)
var gmTestAi14LastPos : Vector;
@addField(CR4Player)
var gmTestAi14Last : string;
// 0 samples, 1 moving samples, 2 sum of speeds while moving (x1000), 3 samples confused, 4 samples in a critical
// state animation, 5 samples with Yrden's lock, 6 Yrden task activations, 7 hits taken while locked
@addField(CR4Player)
var gmTestAi14Counts : array<int>;
@addField(CR4Player)
var gmTestAi14ToadIn : bool;

// Test dummies stay frozen when AI-14 sets an arachas's speed (the last speed causer wins).
@wrapMethod(CNewNPC)
function GMMonsterFixes()
{
	var frozen : bool;

	frozen = GetAnimationTimeMultiplier() < 0.01;
	wrappedMethod();
	if( frozen && GetAnimationTimeMultiplier() >= 0.01 )
		SetAnimationSpeedMultiplier(0.001);
}

@addMethod(W3PlayerWitcher)
function GMTestAi14Inc(idx : int, n : int)
{
	if( gmTestAi14Counts.Size() < 8 )
		gmTestAi14Counts = GMTestAi11Zero(8);
	gmTestAi14Counts[idx] += n;
}

@addMethod(W3PlayerWitcher)
function GMTestAi14Set(npcs : array<CNewNPC>, npc : CNewNPC)
{
	gmTestAi14Npcs = npcs;
	gmTestAi14Npc = npc;
}

// ---- probes ----

@wrapMethod(CNewNPC)
function OnAxiiHit( sign : W3AxiiProjectile )
{
	var ignored : bool;

	ignored = HasAbility('ablIgnoreSigns');
	wrappedMethod(sign);
	if( GMTestProbes() && this == thePlayer.gmTestAi14Npc )
		LogChannel('GMTestAI', "B3EV axii hit " + GetReadableName() + " ablIgnoreSigns=" + ignored + " confusion=" + HasBuff(EET_Confusion) + " puppet=" + HasBuff(EET_AxiiGuardMe));
}

@wrapMethod(CBTTaskToadYrden)
function OnActivate(): EBTNodeStatus
{
	var ret : EBTNodeStatus;

	ret = wrappedMethod();
	if( GMTestProbes() )
	{
		GetWitcherPlayer().GMTestAi14Inc(6, 1);
		GetWitcherPlayer().GMTestAi14SetToad(true);
		LogChannel('GMTestAI', "B3EV toad yrden task started at " + NoTrailZeros(theGame.GetEngineTimeAsSeconds()) + " s, leaveAfter " + NoTrailZeros(leaveAfter) + " s, hit counter " + GetNPC().GetHitCounter());
	}
	return ret;
}

@wrapMethod(CBTTaskToadYrden)
function OnDeactivate()
{
	wrappedMethod();
	if( GMTestProbes() )
	{
		GetWitcherPlayer().GMTestAi14SetToad(false);
		GetWitcherPlayer().GMTestAi14ToadEnded(leftYrden, theGame.GetEngineTimeAsSeconds() - enterTimestamp);
		LogChannel('GMTestAI', "B3EV toad yrden task ended after " + NoTrailZeros(theGame.GetEngineTimeAsSeconds() - enterTimestamp) + " s: left Yrden " + leftYrden
			+ ", hit counter " + GetNPC().GetHitCounter());
	}
}

@addMethod(W3PlayerWitcher)
function GMTestAi14SetToad(on : bool)
{
	gmTestAi14ToadIn = on;
}

@wrapMethod(CNewNPC)
function ReactToBeingHit(damageAction : W3DamageAction, optional buffNotApplied : bool) : bool
{
	var ret : bool;

	ret = wrappedMethod(damageAction, buffNotApplied);
	if( GMTestProbes() && this == thePlayer.gmTestAi14Npc && thePlayer.gmTestAi14ToadIn && !damageAction.IsDoTDamage() )
	{
		GetWitcherPlayer().GMTestAi14Inc(7, 1);
		LogChannel('GMTestAI', "B3EV hit on " + GetReadableName() + " inside the Yrden task, hit counter " + GetHitCounter());
	}
	return ret;
}

@wrapMethod(CBTTaskCastQuen)
function ProcessAction( data : CDamageData )
{
	var attacker : CActor;
	var buff : CBaseGameplayEffect;

	wrappedMethod(data);
	attacker = (CActor)data.attacker;
	if( GMTestProbes() && attacker )
	{
		buff = attacker.GetBuff(EET_Stagger, "quen");
		if( attacker == thePlayer && data.isActionMelee )
			GetWitcherPlayer().GMTestAi14QuenSeen(buff ? buff.GetInitialDurationAfterResists() : 0.0);
		LogChannel('GMTestAI', "B3EV npc quen hit by " + attacker.GetReadableName() + " melee=" + data.isActionMelee + " stagger="
			+ (buff ? NoTrailZeros(buff.GetInitialDurationAfterResists()) + " s" : "none"));
	}
}

// ---- real fights ----

exec function gmtest_ai14_a(path : string, optional distance : float)
{
	var template : CEntityTemplate;
	var npc : CNewNPC;

	if( distance <= 0 )
		distance = 8;
	template = (CEntityTemplate)LoadResource(path, true);
	if( !template )
	{
		LogChannel('GMTest', "INFO AI-14: no template " + path);
		return;
	}
	npc = (CNewNPC)theGame.CreateEntity(template, thePlayer.GetWorldPosition() + thePlayer.GetHeadingVector() * distance, VecToRotation(-thePlayer.GetHeadingVector()));
	if( !npc )
		return;
	npc.SetTemporaryAttitudeGroup('hostile_to_player', AGP_Default);
	GetWitcherPlayer().GMTestAi14Start(npc);
}

@addMethod(W3PlayerWitcher)
function GMTestAi14Start(npc : CNewNPC)
{
	gmTestAi14Npc = npc;
	gmTestAi14Counts = GMTestAi11Zero(8);
	gmTestAi14LastPos = npc.GetWorldPosition();
	gmTestAi14Last = "";
	gmTestAi14ToadIn = false;
	SetImmortalityMode(AIM_Immortal, AIC_Default, true);
	GMTestSetProbes(true);
	AddTimer('GMTestAi14Sample', 0.25, true);
	LogChannel('GMTest', "INFO AI-14: " + npc.GetReadableName() + " level " + npc.GetLevel() + ", ablIgnoreSigns " + npc.HasAbility('ablIgnoreSigns') + ", mon_cyclops "
		+ npc.HasAbility('mon_cyclops') + ", mon_arachas_base " + npc.HasAbility('mon_arachas_base'));
}

@addMethod(W3PlayerWitcher)
timer function GMTestAi14Sample(dt : float, id : int)
{
	var npc : CNewNPC;
	var pos : Vector;
	var speed : float;
	var cs : CBaseGameplayEffect;
	var st : string;

	npc = gmTestAi14Npc;
	if( !npc || !npc.IsAlive() )
	{
		RemoveTimer('GMTestAi14Sample');
		return;
	}
	if( npc.UsesEssence() )
		npc.ForceSetStat(BCS_Essence, npc.GetStatMax(BCS_Essence));
	else
		npc.ForceSetStat(BCS_Vitality, npc.GetStatMax(BCS_Vitality));
	GainStat(BCS_Stamina, GetStatMax(BCS_Stamina));
	pos = npc.GetWorldPosition();
	speed = VecDistance2D(pos, gmTestAi14LastPos) / 0.25;
	gmTestAi14LastPos = pos;
	gmTestAi14Counts[0] += 1;
	if( speed > 0.3 )
	{
		gmTestAi14Counts[1] += 1;
		gmTestAi14Counts[2] += RoundF(speed * 1000);
	}
	cs = npc.GetCurrentlyAnimatedCS();
	if( npc.HasBuff(EET_Confusion) )
		gmTestAi14Counts[3] += 1;
	if( cs )
		gmTestAi14Counts[4] += 1;
	if( npc.IsEffectActive('yrden_lock') )
		gmTestAi14Counts[5] += 1;
	st = "confusion=" + npc.HasBuff(EET_Confusion) + " puppet=" + npc.HasBuff(EET_AxiiGuardMe) + " cs=" + (cs ? cs.GetEffectType() : EET_Undefined)
		+ " yrdenLock=" + npc.IsEffectActive('yrden_lock') + " animMult=" + NoTrailZeros(npc.GetAnimationTimeMultiplier());
	if( st != gmTestAi14Last )
		LogChannel('GMTestAI', "B3EV state " + npc.GetReadableName() + " " + st + " speed=" + NoTrailZeros(speed) + " m/s, " + NoTrailZeros(VecDistance(GetWorldPosition(), pos)) + " m away");
	gmTestAi14Last = st;
}

// Sets the arachas's AI-14 speed causer to `mult` (1: as 5.x), so speeds compare in one session; resets the counts.
exec function gmtest_ai14_speed(mult : float)
{
	var npc : CNewNPC;

	npc = thePlayer.gmTestAi14Npc;
	if( !npc )
		return;
	npc.GMTestAi14SetSpeed(mult);
	GetWitcherPlayer().GMTestAi14ResetCounts();
	LogChannel('GMTest', "INFO AI-14: " + npc.GetReadableName() + " speed causer set to " + NoTrailZeros(mult) + ", multiplier now " + NoTrailZeros(npc.GetAnimationTimeMultiplier()));
}

@addMethod(CNewNPC)
function GMTestAi14SetSpeed(mult : float)
{
	if( gmArachasSpeedSet )
		gmArachasSpeedId = SetAnimationSpeedMultiplier(mult, gmArachasSpeedId);
}

@addMethod(W3PlayerWitcher)
function GMTestAi14ResetCounts()
{
	gmTestAi14Counts = GMTestAi11Zero(8);
}

exec function gmtest_ai14_report()
{
	GMTestAi14Report();
}

function GMTestAi14Report()
{
	var c : array<int>;

	c = thePlayer.gmTestAi14Counts;
	if( c.Size() < 8 )
		return;
	LogChannel('GMTest', "INFO AI-14 " + (thePlayer.gmTestAi14Npc ? thePlayer.gmTestAi14Npc.GetReadableName() : "(gone)") + ": " + c[0] + " samples, moving in " + c[1]
		+ ", mean speed while moving " + (c[1] > 0 ? NoTrailZeros(c[2] / 1000.0 / c[1]) : "-") + " m/s; confused " + c[3] + ", critical state animation " + c[4] + ", Yrden lock " + c[5]
		+ "; toad Yrden task started " + c[6] + " times, hits taken inside it " + c[7]);
}

exec function gmtest_ai14_b()
{
	var npc : CNewNPC;

	GMTestAi14Report();
	GetWitcherPlayer().RemoveTimer('GMTestAi14Sample');
	GetWitcherPlayer().RemoveTimer('GMTestAi08Swing');
	npc = thePlayer.gmTestAi14Npc;
	if( npc )
		npc.Destroy();
	thePlayer.GMTestSetProbes(false);
	thePlayer.SetImmortalityMode(AIM_None, AIC_Default, true);
}

// Real light attacks on the AI-14 enemy (B1's swings, every 1.4 s), the sampler kept.
exec function gmtest_ai14_swing(n : int)
{
	var w : W3PlayerWitcher;

	w = GetWitcherPlayer();
	if( thePlayer.gmTestAi14Npc )
		w.GMTestAi14Swing(n);
}

@addMethod(W3PlayerWitcher)
function GMTestAi14Swing(n : int)
{
	gmTestAi08Npc = gmTestAi14Npc;
	gmTestAi08Left = n;
	AddTimer('GMTestAi08Swing', 1.4, true);
}

// ---- regression ----

exec function gmtest_ai14()
{
	thePlayer.GMTestCount(true, true);
	GMTest_ai14();
	LogChannel('GMTest', "SUMMARY ai14: " + thePlayer.gmTestPassed + " passed, " + thePlayer.gmTestFailed + " failed (run gmtest_ai14_after() next)");
}

exec function gmtest_ai14_after()
{
	thePlayer.GMTestCount(true, true);
	GMTest_ai14_after();
	LogChannel('GMTest', "SUMMARY ai14_after: " + thePlayer.gmTestPassed + " passed, " + thePlayer.gmTestFailed + " failed");
}

// AI-14: NPC Quen's stagger on a melee attacker (GMNpcQuenStagger, which the Quen task's ProcessAction calls; a
// task created by script crashes the game when it runs); spawns the cyclops and the arachas GMTest_ai14_after() reads.
function GMTest_ai14()
{
	var npcs : array<CNewNPC>;
	var bandit, cyclops, arachas : CNewNPC;
	var buff : CBaseGameplayEffect;
	var dur : float;
	var template : CEntityTemplate;

	bandit = GMTestAi06Spawn("dlc/dlc7/data/characters/sq107_bandit_lvl1_mortal.w2ent", 50);
	if( bandit )
	{
		GMNpcQuenStagger(bandit, NULL);	// what the task's ProcessAction calls on a melee hit (a real cast: gmtest_ai14_a)
		buff = bandit.GetBuff(EET_Stagger, "quen");
		dur = -1;
		if( buff )
			dur = buff.GetInitialDurationAfterResists();
		GMTestReport(buff && dur > 0.2, "AI-14 NPC Quen's stagger helper (GMNpcQuenStagger only; the task's ProcessAction: gmtest_ai14_quen) staggers a melee attacker for "+ NoTrailZeros(dur) + " s (the stagger's default, 0.5 s less the attacker's resistance; 5.x 0.1 s)");
		bandit.Destroy();
	}
	else
		GMTestReport(false, "AI-14 NPC Quen: the attacker spawned");

	cyclops = GMTestAi06Spawn("characters/npc_entities/monsters/cyclop_lvl1.w2ent", 30);
	template = (CEntityTemplate)LoadResource("characters/npc_entities/monsters/arachas_lvl1.w2ent", true);
	if( template )
		arachas = (CNewNPC)theGame.CreateEntity(template, thePlayer.GetWorldPosition() - thePlayer.GetHeadingVector() * 45, VecToRotation(thePlayer.GetHeadingVector()));
	if( arachas )
		arachas.SetTemporaryAttitudeGroup('friendly_to_player', AGP_Default);
	npcs.PushBack(cyclops);
	npcs.PushBack(arachas);
	GetWitcherPlayer().GMTestAi14Set(npcs, NULL);
	GMTestReport(cyclops && cyclops.HasAbility('mon_cyclops') && arachas && arachas.HasAbility('mon_arachas_base'), "AI-14 a cyclops and an arachas spawned");
}

// AI-14 on the NPCs GMTest_ai14() spawned (their level bonuses ran); removes them.
function GMTest_ai14_after()
{
	var npcs : array<CNewNPC>;
	var cyclops, arachas : CNewNPC;
	var id1, id2 : int;
	var m1, m2, m3, m4 : float;
	var params : SCustomEffectParams;
	var slow : W3Effect_Slowdown;
	var frost, found : bool;

	npcs = thePlayer.gmTestAi14Npcs;
	if( npcs.Size() < 2 || !npcs[0] || !npcs[1] )
	{
		GMTestReport(false, "AI-14 test NPCs spawned (" + npcs.Size() + ")");
		return;
	}
	cyclops = npcs[0];
	arachas = npcs[1];
	GMTestReport(cyclops.HasAbility('mon_cyclops') && !cyclops.HasAbility('ablIgnoreSigns'),
		"AI-14 a cyclops has no ablIgnoreSigns once its level bonuses ran: " + !cyclops.HasAbility('ablIgnoreSigns') + " (5.x: it ignores Axii's confusion and the other signs' critical states)");

	m1 = arachas.GetAnimationTimeMultiplier();
	id1 = arachas.gmArachasSpeedId;
	arachas.GMMonsterFixes();	// a recompute of the level bonuses
	id2 = arachas.gmArachasSpeedId;
	GMTestReport(AbsF(m1 - 0.75) < 0.001 && arachas.gmArachasSpeedSet && id1 == id2 && id1 != 0,
		"AI-14 an arachas moves at " + NoTrailZeros(m1) + " animation speed (0.75; 5.x 1), one causer across a recompute (id " + id1 + ", " + id2 + "; never 0)");

	// The real slowdown effects (AI-B audit F1): Yrden's EET_Slowdown, added and reset as the trap does, and 5.x's
	// frost slowdown. Inside, the most recent causer wins (the slow's value); after, the arachas is back at 0.75.
	params.effectType = EET_Slowdown;
	params.creator = NULL;	// negative effects from a friendly creator are refused
	params.sourceName = "yrden_mode0";
	params.duration = 5;
	params.effectValue.valueAdditive = 0.4;
	arachas.AddEffectCustom(params);
	m2 = arachas.GetAnimationTimeMultiplier();
	slow = (W3Effect_Slowdown)arachas.GetBuff(EET_Slowdown);
	params.effectValue.valueAdditive = 0.35;
	if( slow )
		found = true;
	if( slow )
		slow.GMResetSlowdownEffect(params.effectValue);	// a trap tick
	m3 = arachas.GetAnimationTimeMultiplier();
	arachas.RemoveBuff(EET_Slowdown);
	m4 = arachas.GetAnimationTimeMultiplier();
	GMTestReport(found && AbsF(m2 - 0.6) < 0.001 && AbsF(m3 - 0.65) < 0.001 && AbsF(m4 - 0.75) < 0.001 && arachas.gmArachasSpeedId == id1,
		"AI-14 an arachas under Yrden's slowdown effect: " + NoTrailZeros(m2) + ", " + NoTrailZeros(m3) + " after a trap tick, " + NoTrailZeros(m4)
		+ " after it ends (0.6, 0.65, 0.75: the slow's value inside, then the arachas's own; with the id-0 collision 1 after); the arachas's causer id "
		+ arachas.gmArachasSpeedId + " (" + id1 + "), effect found " + found);

	arachas.AddEffectDefault(EET_SlowdownFrost, NULL, "test");
	m2 = arachas.GetAnimationTimeMultiplier();
	frost = arachas.HasBuff(EET_SlowdownFrost);
	arachas.RemoveBuff(EET_SlowdownFrost);
	m3 = arachas.GetAnimationTimeMultiplier();
	GMTestReport(frost && AbsF(m2 - 0.7) < 0.001 && AbsF(m3 - 0.75) < 0.001,
		"AI-14 an arachas under 5.x's frost slowdown: " + NoTrailZeros(m2) + ", " + NoTrailZeros(m3) + " after it ends (0.7, 0.75; frost added " + frost + ")");

	cyclops.Destroy();
	arachas.Destroy();
	GMTest_ai14_slam();	// fix3: the golems' and elementals' slam radius
	npcs.Clear();
	GetWitcherPlayer().GMTestAi14Set(npcs, NULL);
}

// Raises the AI-14 enemy's hit counter n times (as n hits that played a hit reaction; AI-10 keeps it 2.5 s), for
// the toad in a real Yrden: 5.x's task ends at 3, legacy's stays until the toad leaves the trap or its time ends.
exec function gmtest_ai14_hits(n : int)
{
	var npc : CNewNPC;
	var i : int;

	npc = thePlayer.gmTestAi14Npc;
	if( !npc )
		return;
	for( i = 0; i < n; i += 1 )
		npc.IncHitCounter();
	LogChannel('GMTestAI', "B3EV " + npc.GetReadableName() + " hit counter raised to " + npc.GetHitCounter() + " (toad Yrden task running " + thePlayer.gmTestAi14ToadIn + ")");
	LogChannel('GMTest', "INFO AI-14 hit counter " + npc.GetHitCounter() + ", toad Yrden task running " + thePlayer.gmTestAi14ToadIn);
}

// The AI-14 enemy's state now (the toad's Yrden task, its hit counter).
exec function gmtest_ai14_state()
{
	var npc : CNewNPC;

	npc = thePlayer.gmTestAi14Npc;
	if( !npc )
		return;
	LogChannel('GMTest', "INFO AI-14 " + npc.GetReadableName() + ": " + NoTrailZeros(VecDistance(thePlayer.GetWorldPosition(), npc.GetWorldPosition())) + " m away, hit counter "
		+ npc.GetHitCounter() + ", Yrden lock " + npc.IsEffectActive('yrden_lock') + ", toad Yrden task running " + thePlayer.gmTestAi14ToadIn);
}

// Puts the AI-14 enemy `d` m in front of Geralt (into a Yrden trap he just placed: the toad jumps away).
exec function gmtest_ai14_bring(d : float)
{
	var npc : CNewNPC;
	var pos : Vector;

	npc = thePlayer.gmTestAi14Npc;
	if( !npc )
		return;
	pos = thePlayer.GetWorldPosition() + thePlayer.GetHeadingVector() * d;
	npc.TeleportWithRotation(pos, VecToRotation(thePlayer.GetWorldPosition() - pos));
	LogChannel('GMTest', "INFO AI-14 " + npc.GetReadableName() + " put " + NoTrailZeros(d) + " m in front of Geralt");
}

// AI-14 (fix3, sweep C gap 1, changelist 136): the all-round slam (the template's own `wide_arc` attack range) of every
// golem, earth elemental (Dao) and Ifryt reaches legacy's 3 m (5.x: 2 m for the Daos, 4 m for the golems, the Ifryts,
// q104's and q310's elementals), as the game reads it for a spawned NPC. In gmtest_panel() (heavy templates).
function GMTest_ai14_slam()
{
	var paths, labels : array<string>;
	var npc : CNewNPC;
	var range : CAIAttackRange;
	var r : float;
	var i : int;
	var ok : bool;
	var text : string;

	paths.PushBack("characters/npc_entities/monsters/golem_lvl1.w2ent");	labels.PushBack("golem (5.x 4)");
	paths.PushBack("characters/npc_entities/monsters/golem_lvl2__ifryt.w2ent");	labels.PushBack("Ifryt (5.x 4)");
	paths.PushBack("characters/npc_entities/monsters/elemental_dao_lvl1.w2ent");	labels.PushBack("earth elemental (5.x 2)");
	paths.PushBack("quests/generic_quests/novigrad/quest_files/mh306_dao/characters/mh306_dao.w2ent");	labels.PushBack("mh306's Dao (5.x 2)");
	paths.PushBack("quests/part_1/quest_files/q104_mine/characters/q104_dao.w2ent");	labels.PushBack("q104's Dao (5.x 4)");
	ok = true;
	for(i = 0; i < paths.Size(); i += 1)
	{
		r = -1;
		npc = GMTestAi06Spawn(paths[i], 40);
		if(npc)
		{
			range = theGame.GetAttackRangeForEntity(npc, 'wide_arc');
			if(range)
				r = range.rangeMax;
			npc.Destroy();
		}
		if(AbsF(r - 3) > 0.001)
			ok = false;
		text += ", " + labels[i] + " " + NoTrailZeros(r);
	}
	GMTestReport(ok, "AI-14 the all-round slam (wide_arc) reaches 3 m for every golem, elemental and Ifryt (legacy)" + text + " (-1: not spawned or no range)");
}
