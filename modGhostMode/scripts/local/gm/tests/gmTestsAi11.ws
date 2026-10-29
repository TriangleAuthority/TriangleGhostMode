// AI slice B2 tests (AI-11 targeting, AI-12 poise, AI-13 flyers forced to land); docs/features/ai.md.
//
// Regression: GMTest_ai11() (gmtest_regress) reads the targeting weights and spawns a bandit, a fiend, a golem, a harpy
// and a cave troll, friendly and frozen, far behind Geralt; GMTest_ai11_after() (gmtest_panel, a frame or more
// later) checks poise on crafted hits through DMG-01's GMZeroSubOneDamage, IsHuge, and the forced landing
// through the harpy's own ReactToBeingHit (its stance set to flying), and removes them.
//
// Real fights (the probes log "B2EV" lines in the script log, channel GMTestAI):
// - targeting: gmtest_ai11_a("<enemy path>", "<ally path>", puppet, distance) spawns an enemy hostile `distance` m
//   ahead and an ally next to it (puppet: Axii's puppet effect on it; otherwise friendly to Geralt and hostile
//   to the enemy), both immortal; Geralt immortal and idle. The enemy's target is sampled every 0.5 s and every
//   hit between the three logged. gmtest_ai11_b() sums up and removes them.
// - poise: gmtest_ai08_fight_a (B1's real light attacks) with the probes; each hit's severity before and after
//   AI-12 and the hit reaction played are logged; gmtest_ai11_poise() sums them up.
// - flyers: gmtest_ai13_a("<path>", swings, distance) spawns a flyer hostile (health refilled), Geralt immortal;
//   swings > 0 adds B1's real light attacks. Its flying state is sampled every 0.2 s (took off, landed), each
//   hit while flying logged with its cause and whether the knockdown applicator came; gmtest_ai13_b() sums up.

@addField(CR4Player)
var gmTestAi11Npcs : array<CNewNPC>;
@addField(CR4Player)
var gmTestAi11Enemy : CNewNPC;
@addField(CR4Player)
var gmTestAi11Ally : CNewNPC;
@addField(CR4Player)
var gmTestAi11Puppet : bool;
// Samples of the enemy's target: 0 Geralt, 1 the ally, 2 other, 3 none.
@addField(CR4Player)
var gmTestAi11Targets : array<int>;
@addField(CR4Player)
var gmTestAi11LastTarget : int;
// Hits: 0 ally on enemy, 1 enemy on ally, 2 enemy on Geralt.
@addField(CR4Player)
var gmTestAi11Hits : array<int>;
// Poise: per victim kind (0 small, 1 huge, 2 golem): hits, reactions lowered, hits with a hit reaction left.
@addField(CR4Player)
var gmTestAi12Hits : array<int>;
// Flyers: 0 hits while flying, 1 with the knockdown applicator, 2 landings, 3 take-offs, 4 burning ticks while flying.
@addField(CR4Player)
var gmTestAi13Counts : array<int>;
@addField(CR4Player)
var gmTestAi13Flyer : CNewNPC;
@addField(CR4Player)
var gmTestAi13WasFlying : bool;
@addField(CR4Player)
var gmTestAi13WasDown : bool;

function GMTestAi11Zero(n : int) : array<int>
{
	var a : array<int>;
	var i : int;

	for(i = 0; i < n; i += 1)
		a.PushBack(0);
	return a;
}

// Counters (fields cannot be assigned through thePlayer): which 0 targets (4), 1 hits (3), 2 poise (9), 3 flyers (5).
@addMethod(CR4Player)
function GMTestAi11Inc(which : int, idx : int)
{
	switch(which)
	{
		case 0: if(gmTestAi11Targets.Size() < 4) gmTestAi11Targets = GMTestAi11Zero(4); gmTestAi11Targets[idx] += 1; break;
		case 1: if(gmTestAi11Hits.Size() < 3) gmTestAi11Hits = GMTestAi11Zero(3); gmTestAi11Hits[idx] += 1; break;
		case 2: if(gmTestAi12Hits.Size() < 9) gmTestAi12Hits = GMTestAi11Zero(9); gmTestAi12Hits[idx] += 1; break;
		case 3: if(gmTestAi13Counts.Size() < 5) gmTestAi13Counts = GMTestAi11Zero(5); gmTestAi13Counts[idx] += 1; break;
	}
}

@addMethod(CR4Player)
function GMTestAi11ResetPoise()
{
	gmTestAi12Hits = GMTestAi11Zero(9);
}

// ---- probes ----

function GMTestAi11Watched(npc : CActor) : bool
{
	return GMTestProbes() && npc && ( npc == thePlayer.gmTestAi08Npc || npc == thePlayer.gmTestAi11Enemy || npc == thePlayer.gmTestAi11Ally
		|| npc == thePlayer.gmTestAi13Flyer );
}

function GMTestAi11Cause(action : W3DamageAction) : string
{
	if( (W3ArrowProjectile)action.causer )
		return "bolt";
	if( (W3YrdenEntityStateYrdenShock)action.causer )
		return "yrden_shock";
	if( (W3Effect_Burning)action.causer )
		return "burning";
	if( (CBaseGameplayEffect)action.causer )
		return "effect";
	if( (W3IgniProjectile)action.causer || (W3IgniEntity)action.causer )
		return "igni";
	if( action.IsActionMelee() )
		return "melee";
	return "other";
}

function GMTestAi11HasType(action : W3DamageAction, t : EEffectType) : bool
{
	var types : array<EEffectType>;

	action.GetEffectTypes(types);
	return types.Contains(t);
}

// AI-12: each hit's severity before and after the poise rule.
@wrapMethod
function GMModifyHitSeverityFromDamage( out damageData : W3DamageAction )
{
	var before : EHitReactionType;
	var npc : CActor;
	var share : float;
	var kind : int;

	before = damageData.GetHitReactionType();
	wrappedMethod(damageData);
	npc = (CActor)damageData.victim;
	if( GMTestAi11Watched(npc) )
	{
		share = 100 * damageData.GetDamageDealt() / npc.GetMaxHealth();
		kind = 0;
		if( npc.HasAbility('mon_golem_base') )
			kind = 2;
		else if( npc.GMGetCapsuleHeight() > 2 )
			kind = 1;
		thePlayer.GMTestAi11Inc(2, kind * 3);
		if( damageData.GetHitReactionType() != before )
			thePlayer.GMTestAi11Inc(2, kind * 3 + 1);
		if( damageData.GetHitReactionType() != EHRT_None && damageData.GetHitAnimationPlayType() != EAHA_ForceNo )
			thePlayer.GMTestAi11Inc(2, kind * 3 + 2);
		LogChannel('GMTestAI', "B2EV poise npc=" + npc.GetReadableName() + " melee=" + damageData.IsActionMelee() + " capsule=" + NoTrailZeros(npc.GMGetCapsuleHeight())
			+ " share=" + NoTrailZeros(share) + "% reaction " + before + " -> " + damageData.GetHitReactionType() + " anim=" + damageData.GetHitAnimationPlayType());
	}
}

@wrapMethod(CNewNPC)
function ReactToBeingHit(damageAction : W3DamageAction, optional buffNotApplied : bool) : bool
{
	var ret, flying, applicator : bool;
	var attacker : CActor;
	var cause : string;

	flying = IsFlying();
	ret = wrappedMethod(damageAction, buffNotApplied);
	if( GMTestAi11Watched(this) || GMTestAi11Watched((CActor)damageAction.attacker) )
	{
		attacker = (CActor)damageAction.attacker;
		cause = GMTestAi11Cause(damageAction);
		applicator = GMTestAi11HasType(damageAction, EET_KnockdownTypeApplicator);
		if( attacker && attacker == thePlayer.gmTestAi11Ally && this == thePlayer.gmTestAi11Enemy )
			thePlayer.GMTestAi11Inc(1, 0);
		if( attacker && attacker == thePlayer.gmTestAi11Enemy && this == thePlayer.gmTestAi11Ally )
			thePlayer.GMTestAi11Inc(1, 1);
		if( this == thePlayer.gmTestAi13Flyer && flying )
		{
			thePlayer.GMTestAi11Inc(3, 0);
			if( applicator )
				thePlayer.GMTestAi11Inc(3, 1);
			if( cause == "burning" )
				thePlayer.GMTestAi11Inc(3, 4);
		}
		LogChannel('GMTestAI', "B2EV hit victim=" + GetReadableName() + " attacker=" + (attacker ? attacker.GetReadableName() : "-") + " cause=" + cause
			+ " dot=" + damageAction.IsDoTDamage() + " dmg=" + NoTrailZeros(damageAction.GetDamageDealt()) + " flying=" + flying + " reaction=" + damageAction.GetHitReactionType()
			+ " anim=" + damageAction.GetHitAnimationPlayType() + " played=" + ret + " knockdownApplicator=" + applicator
			+ " knockdown=" + GMTestAi11HasType(damageAction, EET_Knockdown));
	}
	return ret;
}

// Hits on Geralt by the targeting test's enemy (W3PlayerWitcher overrides ReactToBeingHit: the probe sits on
// the damage manager instead).
@wrapMethod(W3DamageManager)
function ProcessAction( act : W3DamageAction )
{
	if( GMTestProbes() && act.victim == thePlayer && act.attacker && act.attacker == thePlayer.gmTestAi11Enemy && !act.IsDoTDamage() )
	{
		thePlayer.GMTestAi11Inc(1, 2);
	}
	wrappedMethod(act);
}

// ---- AI-11: targeting in a real fight ----

exec function gmtest_ai11_a(enemyPath : string, allyPath : string, puppet : bool, optional distance : float)
{
	var w : W3PlayerWitcher;
	var enemy, ally : CNewNPC;
	var template : CEntityTemplate;
	var pos : Vector;

	w = GetWitcherPlayer();
	GMTestAi11Clear();
	if( distance <= 0 )
		distance = 7;
	template = (CEntityTemplate)LoadResource(enemyPath, true);
	pos = thePlayer.GetWorldPosition() + thePlayer.GetHeadingVector() * distance;
	enemy = (CNewNPC)theGame.CreateEntity(template, pos, VecToRotation(-thePlayer.GetHeadingVector()));
	template = (CEntityTemplate)LoadResource(allyPath, true);
	ally = (CNewNPC)theGame.CreateEntity(template, pos + VecFromHeading(thePlayer.GetHeading() - 90) * 2, VecToRotation(thePlayer.GetHeadingVector()));
	if( !enemy || !ally )
	{
		LogChannel('GMTest', "INFO AI-11 fight: spawn failed (enemy " + (enemy ? "ok" : "none") + ", ally " + (ally ? "ok" : "none") + ")");
		return;
	}
	enemy.SetTemporaryAttitudeGroup('hostile_to_player', AGP_Default);
	w.GMTestAi11Start(enemy, ally, puppet);
}

@addMethod(W3PlayerWitcher)
function GMTestAi11Start(enemy : CNewNPC, ally : CNewNPC, puppet : bool)
{
	gmTestAi11Enemy = enemy;
	gmTestAi11Ally = ally;
	gmTestAi11Puppet = puppet;
	gmTestAi11Targets = GMTestAi11Zero(4);
	gmTestAi11Hits = GMTestAi11Zero(3);
	gmTestAi11LastTarget = -1;
	if( puppet )
		ally.AddEffectDefault(EET_AxiiGuardMe, this, "gmtest");
	else
	{
		ally.SetTemporaryAttitudeGroup('friendly_to_player', AGP_Default);
		ally.SetAttitude(enemy, AIA_Hostile);
		enemy.SetAttitude(ally, AIA_Hostile);
	}
	ally.SetImmortalityMode(AIM_Immortal, AIC_Default, true);
	SetImmortalityMode(AIM_Immortal, AIC_Default, true);
	GMTestSetProbes(true);
	AddTimer('GMTestAi11Sample', 0.5, true);
	LogChannel('GMTest', "INFO AI-11 fight: enemy " + enemy.GetReadableName() + " level " + enemy.GetLevel() + ", ally " + ally.GetReadableName()
		+ (puppet ? " (Axii's puppet effect)" : " (friendly, hostile to the enemy)") + ", Geralt " + NoTrailZeros(VecDistance(GetWorldPosition(), enemy.GetWorldPosition())) + " m away");
}

@addMethod(W3PlayerWitcher)
timer function GMTestAi11Sample(dt : float, id : int)
{
	var enemy, ally : CNewNPC;
	var target : CActor;
	var k : int;

	enemy = gmTestAi11Enemy;
	ally = gmTestAi11Ally;
	if( !enemy || !enemy.IsAlive() || !ally )
	{
		RemoveTimer('GMTestAi11Sample');
		return;
	}
	if( enemy.UsesEssence() )
		enemy.ForceSetStat(BCS_Essence, enemy.GetStatMax(BCS_Essence));
	else
		enemy.ForceSetStat(BCS_Vitality, enemy.GetStatMax(BCS_Vitality));
	if( ally.UsesEssence() )
		ally.ForceSetStat(BCS_Essence, ally.GetStatMax(BCS_Essence));
	else
		ally.ForceSetStat(BCS_Vitality, ally.GetStatMax(BCS_Vitality));
	if( gmTestAi11Puppet && !ally.HasBuff(EET_AxiiGuardMe) )
		ally.AddEffectDefault(EET_AxiiGuardMe, this, "gmtest");
	target = enemy.GetTarget();
	if( target == thePlayer )
		k = 0;
	else if( target == ally )
		k = 1;
	else if( target )
		k = 2;
	else
		k = 3;
	gmTestAi11Targets[k] += 1;
	if( k != gmTestAi11LastTarget )
		LogChannel('GMTestAI', "B2EV target sample=" + (gmTestAi11Targets[0] + gmTestAi11Targets[1] + gmTestAi11Targets[2] + gmTestAi11Targets[3])
			+ " enemy now targets " + (target ? target.GetReadableName() : "nobody") + " (ally hits on it so far " + gmTestAi11Hits[0] + ")");
	gmTestAi11LastTarget = k;
}

exec function gmtest_ai11_b()
{
	var t, h : array<int>;

	GetWitcherPlayer().RemoveTimer('GMTestAi11Sample');
	t = thePlayer.gmTestAi11Targets;
	h = thePlayer.gmTestAi11Hits;
	if( t.Size() == 4 && h.Size() == 3 )
		LogChannel('GMTest', "INFO AI-11 fight: enemy targets over " + (t[0] + t[1] + t[2] + t[3]) + " samples: Geralt " + t[0] + ", ally " + t[1] + ", other " + t[2]
			+ ", none " + t[3] + "; hits: ally on enemy " + h[0] + ", enemy on ally " + h[1] + ", enemy on Geralt " + h[2]);
	GMTestAi11Clear();
}

function GMTestAi11Clear()
{
	if( thePlayer.gmTestAi11Enemy )
		thePlayer.gmTestAi11Enemy.Destroy();
	if( thePlayer.gmTestAi11Ally )
		thePlayer.gmTestAi11Ally.Destroy();
	thePlayer.GMTestSetProbes(false);
	thePlayer.SetImmortalityMode(AIM_None, AIC_Default, true);
}

// ---- AI-12: poise in real fights (gmtest_ai08_fight_a/_b), summed up ----

exec function gmtest_ai11_poise(optional reset : bool)
{
	var p : array<int>;
	var i : int;

	p = thePlayer.gmTestAi12Hits;
	if( p.Size() == 9 )
		for( i = 0; i < 3; i += 1 )
			LogChannel('GMTest', "INFO AI-12 " + ((i == 0) ? "up to 2 m" : ((i == 1) ? "huge" : "golem")) + ": " + p[i * 3] + " hits, " + p[i * 3 + 1]
				+ " reactions lowered, " + p[i * 3 + 2] + " with a hit reaction left");
	if( reset )
		thePlayer.GMTestAi11ResetPoise();
}

// ---- AI-13: a flyer in a real fight ----

exec function gmtest_ai13_a(path : string, optional swings : int, optional distance : float)
{
	var template : CEntityTemplate;
	var npc : CNewNPC;

	if( distance <= 0 )
		distance = 8;
	template = (CEntityTemplate)LoadResource(path, true);
	npc = (CNewNPC)theGame.CreateEntity(template, thePlayer.GetWorldPosition() + thePlayer.GetHeadingVector() * distance, VecToRotation(-thePlayer.GetHeadingVector()));
	if( !npc )
	{
		LogChannel('GMTest', "INFO AI-13: no flyer from " + path);
		return;
	}
	npc.SetTemporaryAttitudeGroup('hostile_to_player', AGP_Default);
	GetWitcherPlayer().GMTestAi13Start(npc, swings);
}

@addMethod(W3PlayerWitcher)
function GMTestAi13Start(npc : CNewNPC, swings : int)
{
	gmTestAi13Flyer = npc;
	gmTestAi13Counts = GMTestAi11Zero(5);
	gmTestAi13WasFlying = npc.IsFlying();
	GMTestAi08Start(npc, swings, false);	// Geralt immortal, the probes on, B1's swings (none for 0)
	AddTimer('GMTestAi13Sample', 0.2, true);
}

@addMethod(W3PlayerWitcher)
timer function GMTestAi13Sample(dt : float, id : int)
{
	var npc : CNewNPC;
	var flying, down : bool;

	npc = gmTestAi13Flyer;
	if( !npc || !npc.IsAlive() )
	{
		RemoveTimer('GMTestAi13Sample');
		return;
	}
	if( npc.UsesEssence() )
		npc.ForceSetStat(BCS_Essence, npc.GetStatMax(BCS_Essence));
	else
		npc.ForceSetStat(BCS_Vitality, npc.GetStatMax(BCS_Vitality));
	flying = npc.IsFlying();
	down = npc.HasBuff(EET_Knockdown) || npc.HasBuff(EET_HeavyKnockdown);
	if( down != gmTestAi13WasDown )
		LogChannel('GMTestAI', "B2EV flyer knockdown " + (down ? "started" : "ended") + " (flying " + flying + ", " + NoTrailZeros(npc.GetDistanceFromGround(20)) + " m above ground, heavy "
			+ npc.HasBuff(EET_HeavyKnockdown) + ")");
	gmTestAi13WasDown = down;
	if( flying != gmTestAi13WasFlying )
	{
		if( flying )
			gmTestAi13Counts[3] += 1;
		else
			gmTestAi13Counts[2] += 1;
		LogChannel('GMTestAI', "B2EV flyer " + (flying ? "took off" : "landed") + " (" + NoTrailZeros(VecDistance(GetWorldPosition(), npc.GetWorldPosition())) + " m away, "
			+ "knockdown " + npc.HasBuff(EET_Knockdown) + ", heavy " + npc.HasBuff(EET_HeavyKnockdown) + ", burning " + npc.HasBuff(EET_Burning) + ")");
	}
	gmTestAi13WasFlying = flying;
}

// The flyer's state now (flying, distance, effects); `burn` sets it burning by script (the burning effect's real
// ticks; the real cause is Igni's).
exec function gmtest_ai13_state(optional burn : bool)
{
	var npc : CNewNPC;

	npc = thePlayer.gmTestAi13Flyer;
	if( !npc )
		return;
	if( burn )
		npc.AddEffectDefault(EET_Burning, thePlayer, "gmtest");
	LogChannel('GMTest', "INFO AI-13 flyer " + npc.GetReadableName() + ": flying " + npc.IsFlying() + ", " + NoTrailZeros(VecDistance(thePlayer.GetWorldPosition(), npc.GetWorldPosition()))
		+ " m away, " + NoTrailZeros(npc.GetDistanceFromGround(20)) + " m above ground, burning " + npc.HasBuff(EET_Burning) + ", knockdown " + npc.HasBuff(EET_Knockdown)
		+ "/" + npc.HasBuff(EET_HeavyKnockdown));
}

exec function gmtest_ai13_b()
{
	var c : array<int>;
	var npc : CNewNPC;

	GetWitcherPlayer().RemoveTimer('GMTestAi13Sample');
	GetWitcherPlayer().RemoveTimer('GMTestAi08Swing');
	c = thePlayer.gmTestAi13Counts;
	if( c.Size() == 5 )
		LogChannel('GMTest', "INFO AI-13 flyer: " + c[0] + " hits while flying (" + c[4] + " burning ticks), " + c[1] + " with the knockdown applicator; landed " + c[2]
			+ " times, took off " + c[3]);
	npc = thePlayer.gmTestAi13Flyer;
	if( npc )
		npc.Destroy();
	thePlayer.GMTestSetProbes(false);
	thePlayer.SetImmortalityMode(AIM_None, AIC_Default, true);
}

// ---- regression ----

exec function gmtest_ai11()
{
	thePlayer.GMTestCount(true, true);
	GMTest_ai11();
	LogChannel('GMTest', "SUMMARY ai11: " + thePlayer.gmTestPassed + " passed, " + thePlayer.gmTestFailed + " failed (run gmtest_ai11_after() next)");
}

exec function gmtest_ai11_after()
{
	thePlayer.GMTestCount(true, true);
	GMTest_ai11_after();
	LogChannel('GMTest', "SUMMARY ai11_after: " + thePlayer.gmTestPassed + " passed, " + thePlayer.gmTestFailed + " failed");
}

// AI-11: the weights; spawns the NPCs GMTest_ai11_after() reads (a bandit, a fiend, a golem, a harpy, a troll).
function GMTest_ai11()
{
	var mon : CAIMonsterCombatParams;
	var fly : CAIFlyingMonsterCombatParams;
	var hum : CAINpcCombatParams;
	var npcs : array<CNewNPC>;
	var w : W3PlayerWitcher;

	mon = new CAIMonsterCombatParams in theGame;
	fly = new CAIFlyingMonsterCombatParams in theGame;
	hum = new CAINpcCombatParams in theGame;
	GMTestReport(mon.playerWeight == 15 && mon.hitterWeight == 30 && mon.currentTargetWeight == 20 && fly.playerWeight == 15 && fly.hitterWeight == 30,
		"AI-11 monsters weigh Geralt " + mon.playerWeight + ", a hitter " + mon.hitterWeight + ", their target " + mon.currentTargetWeight + "; flyers " + fly.playerWeight
		+ ", " + fly.hitterWeight + " (15, 30, 20; 5.x 1000, 20, 9)");
	GMTestReport(hum.playerWeight == 15 && hum.hitterWeight == 30 && hum.currentTargetWeight == 20 && hum.monsterWeight == 25,
		"AI-11 humans weigh Geralt " + hum.playerWeight + ", a hitter " + hum.hitterWeight + ", their target " + hum.currentTargetWeight + ", a monster " + hum.monsterWeight
		+ " (15, 30, 20, 25; 5.x 100, 20, 9, 101)");

	w = GetWitcherPlayer();
	w.GMTestAi11SetNpcs(npcs);
	w.GMTestAi11AddNpc(GMTestAi06Spawn("dlc/dlc7/data/characters/sq107_bandit_lvl1_mortal.w2ent", 24));
	w.GMTestAi11AddNpc(GMTestAi06Spawn("characters/npc_entities/monsters/bies_lvl2.w2ent", 28));
	w.GMTestAi11AddNpc(GMTestAi06Spawn("characters/npc_entities/monsters/golem_lvl2.w2ent", 33));
	w.GMTestAi11AddNpc(GMTestAi06Spawn("characters/npc_entities/monsters/harpy_lvl1.w2ent", 37));
	w.GMTestAi11AddNpc(GMTestAi06Spawn("characters/npc_entities/monsters/troll_cave_lvl2.w2ent", 41));
}

@addMethod(W3PlayerWitcher)
function GMTestAi11SetNpcs(npcs : array<CNewNPC>)
{
	gmTestAi11Npcs = npcs;
}

@addMethod(W3PlayerWitcher)
function GMTestAi11AddNpc(npc : CNewNPC)
{
	gmTestAi11Npcs.PushBack(npc);
}

// A crafted hit of Geralt's taking `share` % of the NPC's health, through DMG-01's GMZeroSubOneDamage (where
// ReduceDamage calls it, and AI-12's rule with it); returns the action.
function GMTestAi12Hit(npc : CNewNPC, melee : bool, reaction : EHitReactionType, share : float) : W3DamageAction
{
	var action : W3DamageAction;
	var dmg : float;

	action = new W3DamageAction in theGame.damageMgr;
	action.Initialize(thePlayer, npc, NULL, "gmtest", reaction, CPS_AttackPower, melee, !melee, false, false);
	dmg = npc.GetMaxHealth() * share / 100;
	if( npc.UsesEssence() )
		action.processedDmg.essenceDamage = dmg;
	else
		action.processedDmg.vitalityDamage = dmg;
	GMZeroSubOneDamage(action);
	return action;
}

// A hit on the harpy through its own ReactToBeingHit while its stance reads flying (AI-13); returns the action.
function GMTestAi13Hit(npc : CNewNPC, causer : IScriptable, dot : bool, share : float) : W3DamageAction
{
	var action : W3DamageAction;
	var dmg : float;

	action = new W3DamageAction in theGame.damageMgr;
	action.Initialize(thePlayer, npc, causer, "gmtest", EHRT_Light, CPS_AttackPower, !dot, false, false, false);
	if( dot )
		action.SetIsDoTDamage(1);
	dmg = npc.GetMaxHealth() * share / 100;
	if( npc.UsesEssence() )
		action.processedDmg.essenceDamage = dmg;
	else
		action.processedDmg.vitalityDamage = dmg;
	npc.SetBehaviorVariable('npcStance', (int)NS_Fly);
	npc.ReactToBeingHit(action);
	return action;
}

function GMTestAi12Name(a : W3DamageAction) : string
{
	return a.GetHitReactionType() + "/" + a.GetHitAnimationPlayType();
}

// AI-12 and AI-13 on the NPCs GMTest_ai11() spawned; removes them.
function GMTest_ai11_after()
{
	var npcs : array<CNewNPC>;
	var bandit, fiend, golem, harpy, troll : CNewNPC;
	var a1, a2, a3, a4, a5 : W3DamageAction;
	var h, s : float;
	var i : int;
	var hugeOk : bool;
	var hugeText : string;
	var burning : W3Effect_Burning;
	var bleeding : W3Effect_Bleeding;

	npcs = thePlayer.gmTestAi11Npcs;
	if( npcs.Size() < 5 || !npcs[0] || !npcs[1] || !npcs[2] || !npcs[3] || !npcs[4] )
	{
		GMTestReport(false, "AI-12/AI-13 test NPCs spawned (" + npcs.Size() + ")");
		return;
	}
	bandit = npcs[0];
	fiend = npcs[1];
	golem = npcs[2];
	harpy = npcs[3];
	troll = npcs[4];
	// A frozen NPC still in its spawn animation can read the flying stance (the golem does), which exempts it
	// from the rule: the ground NPCs are set to the normal stance first.
	bandit.SetBehaviorVariable('npcStance', (int)NS_Normal);
	fiend.SetBehaviorVariable('npcStance', (int)NS_Normal);
	golem.SetBehaviorVariable('npcStance', (int)NS_Normal);

	// AI-12: an enemy up to 2 m: melee hits left alone, other hits lowered by the share they take.
	a1 = GMTestAi12Hit(bandit, true, EHRT_Heavy, 0.5);
	a2 = GMTestAi12Hit(bandit, false, EHRT_Heavy, 0.5);
	a3 = GMTestAi12Hit(bandit, false, EHRT_Heavy, 2);
	a4 = GMTestAi12Hit(bandit, false, EHRT_Heavy, 5);
	GMTestReport(a1.GetHitReactionType() == EHRT_Heavy && a2.GetHitReactionType() == EHRT_None && a2.GetHitAnimationPlayType() == EAHA_ForceNo
		&& a3.GetHitReactionType() == EHRT_Light && a4.GetHitReactionType() == EHRT_Heavy,
		"AI-12 a bandit (" + NoTrailZeros(bandit.GMGetCapsuleHeight()) + " m): heavy melee hit at 0.5% " + GMTestAi12Name(a1) + ", other hits at 0.5% " + GMTestAi12Name(a2)
		+ ", 2% " + GMTestAi12Name(a3) + ", 5% " + GMTestAi12Name(a4) + " (heavy kept; none and no animation, light, heavy; 5.x heavy every time)");

	// A huge enemy: melee hits lowered too, the thresholds scaled by its height over 2 m.
	h = fiend.GMGetCapsuleHeight();
	s = 1 + MaxF(0, h - 2);
	a1 = GMTestAi12Hit(fiend, true, EHRT_Heavy, 0.5 * s);
	a2 = GMTestAi12Hit(fiend, true, EHRT_Heavy, 2 * s);
	a3 = GMTestAi12Hit(fiend, true, EHRT_Heavy, 4 * s);
	GMTestReport(h > 2 && a1.GetHitReactionType() == EHRT_None && a2.GetHitReactionType() == EHRT_Light && a3.GetHitReactionType() == EHRT_Heavy,
		"AI-12 a fiend (" + NoTrailZeros(h) + " m, thresholds x" + NoTrailZeros(s) + "): heavy melee hits at " + NoTrailZeros(0.5 * s) + "% " + GMTestAi12Name(a1) + ", "
		+ NoTrailZeros(2 * s) + "% " + GMTestAi12Name(a2) + ", " + NoTrailZeros(4 * s) + "% " + GMTestAi12Name(a3) + " (taller than 2 m; none, light, heavy; 5.x heavy every time)");

	// Golems never react.
	a1 = GMTestAi12Hit(golem, true, EHRT_Heavy, 30);
	a2 = GMTestAi12Hit(golem, false, EHRT_Light, 30);
	GMTestReport(a1.GetHitReactionType() == EHRT_None && a1.GetHitAnimationPlayType() == EAHA_ForceNo && a2.GetHitReactionType() == EHRT_None,
		"AI-12 a golem hit for 30% of its health: melee heavy " + GMTestAi12Name(a1) + ", other light " + GMTestAi12Name(a2) + " (none and no animation; 5.x heavy, light)");

	// IsHuge: the capsule taller than 2 m (5.x: the mon_type_huge ability).
	hugeOk = true;
	hugeText = "";
	for( i = 0; i < 5; i += 1 )
	{
		hugeOk = hugeOk && ( npcs[i].IsHuge() == ( npcs[i].GMGetCapsuleHeight() > 2 ) );
		hugeText += npcs[i].GetReadableName() + " " + NoTrailZeros(npcs[i].GMGetCapsuleHeight()) + " m huge " + npcs[i].IsHuge() + " (mon_type_huge " + npcs[i].HasAbility('mon_type_huge') + "); ";
	}
	GMTestReport(hugeOk && fiend.IsHuge() && !troll.IsHuge() && !bandit.IsHuge(), "AI-12 huge means taller than 2 m (the fiend yes, the cave troll no; 5.x the reverse): " + hugeText);

	// AI-13: a flying harpy knocked down by a damaging hit, by burning; not by other damage over time or a hit
	// without damage (5.x: by any hit but an effect's, as its health-loss threshold is 0, with a plain knockdown).
	burning = new W3Effect_Burning in theGame;
	bleeding = new W3Effect_Bleeding in theGame;
	a1 = GMTestAi13Hit(harpy, NULL, false, 0.1);
	a2 = GMTestAi13Hit(harpy, burning, true, 0.1);
	a3 = GMTestAi13Hit(harpy, bleeding, true, 0.1);
	a4 = GMTestAi13Hit(harpy, NULL, false, 0);
	harpy.SetBehaviorVariable('npcStance', (int)NS_Normal);
	GMTestReport(GMTestAi11HasType(a1, EET_KnockdownTypeApplicator) && GMTestAi11HasType(a2, EET_KnockdownTypeApplicator) && !GMTestAi11HasType(a3, EET_KnockdownTypeApplicator)
		&& !GMTestAi11HasType(a4, EET_KnockdownTypeApplicator) && !GMTestAi11HasType(a4, EET_Knockdown),
		"AI-13 a flying harpy is knocked down by: a hit for 0.1% " + GMTestAi11HasType(a1, EET_KnockdownTypeApplicator) + ", a burning tick "
		+ GMTestAi11HasType(a2, EET_KnockdownTypeApplicator) + ", a bleeding tick " + GMTestAi11HasType(a3, EET_KnockdownTypeApplicator) + ", a hit without damage "
		+ GMTestAi11HasType(a4, EET_KnockdownTypeApplicator) + "/" + GMTestAi11HasType(a4, EET_Knockdown) + " (true, true, false, false/false; 5.x knockdown on the hits, not the burning)");

	for( i = 0; i < npcs.Size(); i += 1 )
		if( npcs[i] )
			npcs[i].Destroy();
	npcs.Clear();
	GetWitcherPlayer().GMTestAi11SetNpcs(npcs);
}

// The NPCs within `range` m: capsule height, IsHuge, the huge and golem abilities, their monster abilities.
exec function gmtest_ai12_info(optional range : float)
{
	var actors : array<CActor>;
	var npc : CNewNPC;
	var abls : array<name>;
	var i, j : int;
	var text : string;

	if( range <= 0 )
		range = 15;
	actors = thePlayer.GetNPCsAndPlayersInRange(range, 20, , FLAG_OnlyAliveActors);
	for( i = 0; i < actors.Size(); i += 1 )
	{
		npc = (CNewNPC)actors[i];
		if( !npc )
			continue;
		abls.Clear();
		npc.GetCharacterStats().GetAbilities(abls, false);
		text = "";
		for( j = 0; j < abls.Size(); j += 1 )
			if( StrBeginsWith(NameToString(abls[j]), "mon_") )
				text += NameToString(abls[j]) + " ";
		LogChannel('GMTest', "INFO AI-12 " + npc.GetReadableName() + ": capsule " + NoTrailZeros(npc.GMGetCapsuleHeight()) + " m, huge " + npc.IsHuge()
			+ ", mon_type_huge " + npc.HasAbility('mon_type_huge') + ", mon_golem_base " + npc.HasAbility('mon_golem_base') + "/" + npc.HasAbility('mon_golem_base', true)
			+ ", flying " + npc.IsFlying() + "; " + text);
	}
}
