// In-game checks for the DEF features (dodging, parrying, countering). Reports as gmTests.ws.

@addMethod(CR4Player)
function GMTestSetEvadeHeading(heading : float)
{
	evadeHeading = heading;
}

@addMethod(CR4Player)
function GMTestGetEvadeHeading() : float
{
	return evadeHeading;
}

// The nearest hostile NPC within 20 m, or NULL.
function GMTestHostileNpc() : CActor
{
	var actors : array<CActor>;
	var i : int;

	actors = thePlayer.GetNPCsAndPlayersInRange(20, 20, , FLAG_OnlyAliveActors);
	for(i = 0; i < actors.Size(); i += 1)
		if(actors[i] != thePlayer && GetAttitudeBetween(thePlayer, actors[i]) == AIA_Hostile)
			return actors[i];
	return NULL;
}

// One scripted melee hit from attacker on victim through the damage manager (the path real hits
// take); returns the action, processed. kind: 0 normal, 1 environment, 2 damage over time.
function GMTestDefHit(attacker : CActor, victim : CActor, canDodge : bool, kind : int) : W3Action_Attack
{
	var action : W3Action_Attack;

	action = new W3Action_Attack in theGame.damageMgr;
	action.Init(attacker, victim, NULL, GetInvalidUniqueId(), 'attack_light', attacker.GetName(), EHRT_Light,
		false, canDodge, '', AST_Jab, ASD_UpDown, true, false, false, kind == 1);
	if(kind == 2)
		action.SetIsDoTDamage(0.1);
	action.AddDamage(theGame.params.DAMAGE_NAME_DIRECT, victim.GetStatMax(BCS_Vitality) * 0.05);
	action.SetSuppressHitSounds(true);
	action.SetHitAnimationPlayType(EAHA_ForceNo);
	theGame.damageMgr.ProcessAction(action);
	return action;
}

// One DEF-01 player case: Geralt dodging at the given angle between his dodge heading and the
// attacker's heading (0: straight away from the attack).
function GMTestDef01Player(npc : CActor, angle : float, canDodge : bool, kind : int, expectDodged : bool, label : string)
{
	var action : W3Action_Attack;
	var health : float;
	var dodged : bool;

	thePlayer.ForceSetStat(BCS_Vitality, thePlayer.GetStatMax(BCS_Vitality));
	thePlayer.SetIsCurrentlyDodging(true);
	thePlayer.GMTestSetEvadeHeading(AngleNormalize180(npc.GetHeading() + angle));
	health = thePlayer.GetStat(BCS_Vitality);
	action = GMTestDefHit(npc, thePlayer, canDodge, kind);
	dodged = action.WasDodged();
	if(expectDodged)
		GMTestReport(dodged && thePlayer.GetStat(BCS_Vitality) >= health, "DEF-01 " + label + ": dodged, no damage");
	else
		GMTestReport(!dodged && thePlayer.GetStat(BCS_Vitality) < health, "DEF-01 " + label + ": not dodged, "
			+ NoTrailZeros(health - thePlayer.GetStat(BCS_Vitality)) + " damage");
	delete action;
	thePlayer.SetIsCurrentlyDodging(false);
	thePlayer.ForceSetStat(BCS_Vitality, thePlayer.GetStatMax(BCS_Vitality));
}

// DEF-01: dodge resolution, by scripted hits through the damage manager. Needs a hostile NPC
// within 20 m (e.g. spawn(wolf, 1, 6, true)); Geralt's dodge state is set by script.
exec function gmtest_def01()
{
	GMTest_def01();
}

function GMTest_def01()
{
	var npc : CActor;
	var action : W3Action_Attack;
	var savedHeading, health : float;

	npc = GMTestHostileNpc();
	if(!npc)
	{
		LogChannel('GMTest', "INFO DEF-01: no hostile NPC within 20 m, checks skipped");
		return;
	}
	LogChannel('GMTest', "INFO DEF-01 attacker " + npc.GetDisplayName() + ", Fleet Footed usable: classic "
		+ GetWitcherPlayer().CanUseSkill(S_Sword_s09) + ", new " + GetWitcherPlayer().CanUseSkill(S_Sword_s36));
	savedHeading = thePlayer.GMTestGetEvadeHeading();

	GMTestDef01Player(npc, 0, true, 0, true, "dodging straight away (0 deg)");
	GMTestDef01Player(npc, 119, true, 0, true, "dodging at 119 deg");
	GMTestDef01Player(npc, 121, true, 0, false, "dodging at 121 deg");
	GMTestDef01Player(npc, 145, true, 0, false, "dodging at 145 deg (vanilla's 150 deg rule would dodge)");
	GMTestDef01Player(npc, 170, true, 0, false, "dodging at 170 deg");
	GMTestDef01Player(npc, 0, false, 0, false, "undodgeable attack at 0 deg");
	GMTestDef01Player(npc, 0, true, 1, false, "environment damage at 0 deg");
	GMTestDef01Player(npc, 0, true, 2, false, "damage over time at 0 deg");

	// not dodging: hit as usual
	thePlayer.ForceSetStat(BCS_Vitality, thePlayer.GetStatMax(BCS_Vitality));
	health = thePlayer.GetStat(BCS_Vitality);
	action = GMTestDefHit(npc, thePlayer, true, 0);
	GMTestReport(!action.WasDodged() && thePlayer.GetStat(BCS_Vitality) < health, "DEF-01 not dodging: hit");
	delete action;
	thePlayer.ForceSetStat(BCS_Vitality, thePlayer.GetStatMax(BCS_Vitality));
	thePlayer.GMTestSetEvadeHeading(savedHeading);

	// NPC dodge (vanilla's rule, now decided before damage)
	npc.SetIsCurrentlyDodging(true);
	health = npc.GetStat(BCS_Vitality);
	action = GMTestDefHit(thePlayer, npc, true, 0);
	GMTestReport(action.WasDodged() && npc.GetStat(BCS_Vitality) >= health, "DEF-01 NPC dodging: dodged, no damage");
	delete action;
	action = GMTestDefHit(thePlayer, npc, false, 0);
	GMTestReport(!action.WasDodged() && npc.GetStat(BCS_Vitality) < health, "DEF-01 NPC dodging an undodgeable attack: hit");
	delete action;
	npc.SetIsCurrentlyDodging(false);
	npc.ForceSetStat(BCS_Vitality, npc.GetStatMax(BCS_Vitality));
}

// DEF-03: rolling grants immunity to long stagger (and vanilla's knockdowns and stagger);
// a dodge that is not a roll does not; the immunity ends with the roll. Scripted dodge state.
exec function gmtest_def03()
{
	GMTest_def03();
}

function GMTest_def03()
{
	thePlayer.SetIsCurrentlyDodging(true, true);
	GMTestReport(thePlayer.IsImmuneToBuff(EET_LongStagger), "DEF-03 rolling: immune to long stagger");
	GMTestReport(thePlayer.IsImmuneToBuff(EET_Stagger) && thePlayer.IsImmuneToBuff(EET_Knockdown), "DEF-03 rolling: still immune to stagger and knockdown (vanilla)");
	thePlayer.SetIsCurrentlyDodging(false);
	GMTestReport(!thePlayer.IsImmuneToBuff(EET_LongStagger), "DEF-03 roll ended: long stagger immunity removed");
	thePlayer.SetIsCurrentlyDodging(true, false);
	GMTestReport(!thePlayer.IsImmuneToBuff(EET_LongStagger), "DEF-03 dodging (not rolling): no long stagger immunity");
	thePlayer.SetIsCurrentlyDodging(false);
}

// DEF-01 in a real fight: a probe logs every hit on Geralt as the dodge check sees it.
// gmtest_def01_real_a() switches it on; then dodge with gmtest_def_dodge(2) (scripted dodge input,
// real dodge; 3 rolls) while enemies attack; gmtest_def01_real_b() lists the hits and checks them.
@addField(CR4Player)
var gmTestDodgeLog : array<string>;
@addField(CR4Player)
var gmTestDodgeHits : int;
@addField(CR4Player)
var gmTestDodgeDodged : int;
@addField(CR4Player)
var gmTestDodgeWrong : int;

@addMethod(CR4Player)
function GMTestDodgeReset()
{
	gmTestDodgeLog.Clear();
	gmTestDodgeHits = 0;
	gmTestDodgeDodged = 0;
	gmTestDodgeWrong = 0;
	gmTestActStart = theGame.GetEngineTimeAsSeconds();
}

@addMethod(CR4Player)
function GMTestDodgeLogHit(logLine : string, dodging : bool, dodged : bool, expected : bool)
{
	gmTestDodgeLog.PushBack(logLine);
	gmTestDodgeHits += 1;
	if(dodged)
		gmTestDodgeDodged += 1;
	if(dodging && dodged != expected)
		gmTestDodgeWrong += 1;
}

@wrapMethod(W3PlayerWitcher)
function GMPlayerDodgeDamage(out damageData : W3DamageAction)
{
	var attacker : CActor;
	var dodging : bool;
	var angle : float;

	wrappedMethod(damageData);
	if(!GMTestProbes())
		return;
	attacker = (CActor)damageData.attacker;
	dodging = IsCurrentlyDodging() || IsInCombatAction()
		&& ((int)GetBehaviorVariable('combatActionType') == (int)CAT_Dodge || (int)GetBehaviorVariable('combatActionType') == (int)CAT_Roll);
	if(attacker)
		angle = AbsF(AngleDistance(evadeHeading, attacker.GetHeading()));
	GMTestDodgeLogHit("hit by " + attacker.GetDisplayName() + " at +" + NoTrailZeros(theGame.GetEngineTimeAsSeconds() - gmTestActStart)
		+ ": dodging " + dodging + " (IsCurrentlyDodging " + IsCurrentlyDodging() + ", combat action " + (int)GetBehaviorVariable('combatActionType')
		+ "), angle " + NoTrailZeros(angle) + ", can be dodged " + damageData.CanBeDodged() + ", dodged " + damageData.WasDodged(),
		dodging, damageData.WasDodged(), damageData.CanBeDodged() && !damageData.IsDoTDamage() && angle <= 120);
}

exec function gmtest_def01_real_a()
{
	thePlayer.GMTestSetProbes(true);
	thePlayer.GMTestDodgeReset();
	thePlayer.ForceSetStat(BCS_Vitality, thePlayer.GetStatMax(BCS_Vitality));
}

// One real dodge (2) or roll (3) through the input handler; tops up health and stamina first.
exec function gmtest_def_dodge(act : int)
{
	thePlayer.ForceSetStat(BCS_Vitality, thePlayer.GetStatMax(BCS_Vitality));
	thePlayer.GainStat(BCS_Stamina, thePlayer.GetStatMax(BCS_Stamina));
	GMTestActInput(act, true);
	GMTestActInput(act, false);
}

exec function gmtest_def01_real_b()
{
	var i : int;

	for(i = 0; i < thePlayer.gmTestDodgeLog.Size(); i += 1)
		LogChannel('GMTest', "INFO DEF-01 " + thePlayer.gmTestDodgeLog[i]);
	LogChannel('GMTest', "INFO DEF-01 real fight: " + thePlayer.gmTestDodgeHits + " hits, " + thePlayer.gmTestDodgeDodged + " dodged");
	GMTestReport(thePlayer.gmTestDodgeDodged > 0, "DEF-01 real fight: real hits dodged by real dodges");
	GMTestReport(thePlayer.gmTestDodgeWrong == 0, "DEF-01 real fight: every hit during a dodge decided by the 120 deg rule");
	thePlayer.GMTestSetProbes(false);
}

// DEF-04: Ciri's dodge, by scripted hits. Play as Ciri first (Ciri(); back with Geralt()) and
// spawn an enemy (e.g. spawn(wolf, 1, 6, true)); Ciri's dodge state is set by script.
exec function gmtest_def04()
{
	var npc : CActor;
	var action : W3Action_Attack;
	var savedHeading, health, stamina : float;
	var i : int;
	var angles : array<float>;
	var ciri : W3ReplacerCiri;

	ciri = (W3ReplacerCiri)thePlayer;
	if(!ciri)
	{
		LogChannel('GMTest', "INFO DEF-04: not playing as Ciri (run Ciri() first), checks skipped");
		return;
	}
	npc = GMTestHostileNpc();
	if(!npc)
	{
		LogChannel('GMTest', "INFO DEF-04: no hostile NPC within 20 m, checks skipped");
		return;
	}
	savedHeading = thePlayer.GMTestGetEvadeHeading();
	angles.PushBack(0);
	angles.PushBack(145);
	angles.PushBack(170);
	for(i = 0; i < angles.Size(); i += 1)
	{
		thePlayer.ForceSetStat(BCS_Vitality, thePlayer.GetStatMax(BCS_Vitality));
		thePlayer.ForceSetStat(BCS_Stamina, 0);
		thePlayer.SetIsCurrentlyDodging(true);
		thePlayer.GMTestSetEvadeHeading(AngleNormalize180(npc.GetHeading() + angles[i]));
		health = thePlayer.GetStat(BCS_Vitality);
		action = GMTestDefHit(npc, thePlayer, true, 0);
		GMTestReport(action.WasDodged() && thePlayer.GetStat(BCS_Vitality) >= health && action.GetEffectsCount() == 0,
			"DEF-04 Ciri dodging at " + NoTrailZeros(angles[i]) + " deg: dodged, no damage, no effects");
		LogChannel('GMTest', "INFO DEF-04 stamina gained by the dodge: " + NoTrailZeros(thePlayer.GetStat(BCS_Stamina)));
		delete action;
	}
	thePlayer.ForceSetStat(BCS_Vitality, thePlayer.GetStatMax(BCS_Vitality));
	health = thePlayer.GetStat(BCS_Vitality);
	action = GMTestDefHit(npc, thePlayer, false, 0);
	GMTestReport(!action.WasDodged() && thePlayer.GetStat(BCS_Vitality) < health, "DEF-04 Ciri dodging an undodgeable attack: hit");
	delete action;
	thePlayer.SetIsCurrentlyDodging(false);
	thePlayer.ForceSetStat(BCS_Vitality, thePlayer.GetStatMax(BCS_Vitality));
	health = thePlayer.GetStat(BCS_Vitality);
	action = GMTestDefHit(npc, thePlayer, true, 0);
	GMTestReport(!action.WasDodged() && thePlayer.GetStat(BCS_Vitality) < health, "DEF-04 Ciri not dodging: hit");
	delete action;
	thePlayer.ForceSetStat(BCS_Vitality, thePlayer.GetStatMax(BCS_Vitality));
	thePlayer.GMTestSetEvadeHeading(savedHeading);
}

// DEF-05: a probe records the player's damage before and after CActor.ReduceDamage, where the
// parry share is applied.
@addField(CR4Player)
var gmTestReduceBefore : float;
@addField(CR4Player)
var gmTestReduceAfter : float;

@addMethod(CR4Player)
function GMTestSetReduce(before : float, after : float)
{
	gmTestReduceBefore = before;
	gmTestReduceAfter = after;
}

@wrapMethod(CActor)
function ReduceDamage(out damageData : W3DamageAction)
{
	var before : float;

	before = damageData.processedDmg.vitalityDamage;
	wrappedMethod(damageData);
	if(GMTestProbes() && this == thePlayer && (W3Action_Attack)damageData)
	{
		thePlayer.GMTestSetReduce(before, damageData.processedDmg.vitalityDamage);
		if(damageData.IsParryStagger() && before > 0)
			LogChannel('GMTest', "INFO DEF-05 partial parry by " + damageData.attacker.GetDisplayName() + ": ReduceDamage " + NoTrailZeros(before)
				+ " -> " + NoTrailZeros(damageData.processedDmg.vitalityDamage) + " (" + NoTrailZeros(RoundMath(100 * damageData.processedDmg.vitalityDamage / before)) + "%)");
	}
}

// DEF-05: a scripted melee hit from attacker on Geralt through the damage manager, parried or not
// (the attacker's side sets the flag, as real attacks do), with bleeding and one extra effect
// (EET_Undefined: none). Physical damage, which goes through ReduceDamage (direct damage does not).
// Returns the damage taken; health is topped up before and after.
function GMTestDefParryHit(attacker : CActor, canParry : bool, parried : bool, effect : EEffectType, out action : W3Action_Attack, optional countered : bool) : float
{
	var health : float;

	thePlayer.ForceSetStat(BCS_Vitality, thePlayer.GetStatMax(BCS_Vitality));
	health = thePlayer.GetStat(BCS_Vitality);
	thePlayer.GMTestSetReduce(-1, -1);
	action = new W3Action_Attack in theGame.damageMgr;
	action.Init(attacker, thePlayer, NULL, GetInvalidUniqueId(), 'attack_light', attacker.GetName(), EHRT_Light,
		canParry, true, '', AST_Jab, ASD_UpDown, true, false, false, false);
	action.AddDamage(theGame.params.DAMAGE_NAME_PHYSICAL, thePlayer.GetStatMax(BCS_Vitality) * 0.05);
	action.AddEffectInfo(EET_Bleeding);
	if(effect != EET_Undefined)
		action.AddEffectInfo(effect);
	action.SetIsParried(parried);
	action.SetIsCountered(countered);
	action.SetSuppressHitSounds(true);
	action.SetHitAnimationPlayType(EAHA_ForceNo);
	theGame.damageMgr.ProcessAction(action);
	health -= thePlayer.GetStat(BCS_Vitality);
	thePlayer.ForceSetStat(BCS_Vitality, thePlayer.GetStatMax(BCS_Vitality));
	return health;
}

@addMethod(CR4Player)
function GMTestSetParryingWithNotEnoughStamina(b : bool)
{
	gmParryingWithNotEnoughStamina = b;
}

// Removes the effects a DEF test hit may leave on Geralt.
function GMTestDefClearHitEffects()
{
	thePlayer.RemoveAllBuffsOfType(EET_Stagger);
	thePlayer.RemoveAllBuffsOfType(EET_LongStagger);
	thePlayer.RemoveAllBuffsOfType(EET_Bleeding);
	thePlayer.RemoveAllBuffsOfType(EET_Bleeding1);
	thePlayer.RemoveAllBuffsOfType(EET_Bleeding2);
	thePlayer.RemoveAllBuffsOfType(EET_Bleeding3);
	thePlayer.RemoveAllBuffsOfType(EET_Knockdown);
}

// DEF-05, DEF-06: an attack that cannot be parried and knocks down or staggers, parried or countered: no
// damage (legacy; the hit's final processed damage), and its own effect applies.
function GMTestDefKept(npc : CActor, countered : bool, effect : EEffectType, label : string)
{
	var action : W3Action_Attack;
	var dmg : float;
	var applied : bool;

	GMTestDefClearHitEffects();
	if(countered)
		dmg = GMTestDefParryHit(npc, false, false, effect, action, true);
	else
		dmg = GMTestDefParryHit(npc, false, true, effect, action);
	applied = thePlayer.HasBuff(effect);
	LogChannel('GMTest', "INFO DEF-05/06 " + label + ": processed damage " + NoTrailZeros(action.processedDmg.vitalityDamage) + ", health lost "
		+ NoTrailZeros(dmg) + ", parry stagger " + action.IsParryStagger() + ", " + effect + " applied " + applied);
	GMTestReport(action.processedDmg.vitalityDamage == 0 && !action.IsParryStagger(), "DEF-05/06 " + label + ": no damage, not a partial parry (legacy)");
	GMTestReport(applied, "DEF-05/06 " + label + ": its effect applies");
	delete action;
	GMTestDefClearHitEffects();
}

// One DEF-05 parry case: the share of the damage ReduceDamage lets through (0: the hit takes no
// damage at all), and the effects left on Geralt.
function GMTestDef05Case(npc : CActor, canParry : bool, noStamina : bool, effect : EEffectType,
	expectShare : float, expectStagger : bool, label : string)
{
	var action : W3Action_Attack;
	var dmg, share : float;
	var stagger, longStagger, bleeding, bledBefore, ok : bool;

	GMTestDefClearHitEffects();
	bledBefore = thePlayer.HasBuff(EET_Bleeding);	// a real bite's bleed is removed only on the next tick
	thePlayer.GMTestSetParryingWithNotEnoughStamina(noStamina);
	dmg = GMTestDefParryHit(npc, canParry, true, effect, action);
	thePlayer.GMTestSetParryingWithNotEnoughStamina(false);
	stagger = thePlayer.HasBuff(EET_Stagger);
	longStagger = thePlayer.HasBuff(EET_LongStagger);
	bleeding = thePlayer.HasBuff(EET_Bleeding);
	share = -1;
	if(thePlayer.gmTestReduceBefore > 0)
		share = thePlayer.gmTestReduceAfter / thePlayer.gmTestReduceBefore;
	LogChannel('GMTest', "INFO DEF-05 " + label + ": damage taken " + NoTrailZeros(dmg) + ", ReduceDamage " + NoTrailZeros(thePlayer.gmTestReduceBefore)
		+ " -> " + NoTrailZeros(thePlayer.gmTestReduceAfter) + ", parry stagger " + action.IsParryStagger() + ", stagger " + stagger
		+ ", long stagger " + longStagger + ", bleeding " + bleeding);
	if(expectShare == 0)	// the probe, not health: a real bite between two calls must not count
		ok = thePlayer.gmTestReduceBefore > 0 && thePlayer.gmTestReduceAfter == 0;
	else
		ok = AbsF(share - expectShare) < 0.01 && dmg > 0;
	GMTestReport(ok, "DEF-05 " + label + ": " + NoTrailZeros(expectShare * 100) + "% of the damage");
	if(expectStagger)
		GMTestReport(stagger && !longStagger, "DEF-05 " + label + ": staggered briefly, no long stagger");
	else
		GMTestReport(!stagger && !longStagger, "DEF-05 " + label + ": not staggered");
	if(expectShare < 1 && bledBefore)
		LogChannel('GMTest', "INFO DEF-05 " + label + ": bleeding check skipped (Geralt was already bleeding)");
	else if(expectShare < 1)
		GMTestReport(!bleeding, "DEF-05 " + label + ": no bleeding");
	delete action;
	GMTestDefClearHitEffects();
}

// DEF-05: parrying, by scripted hits through the damage manager (the parry flag set as the
// attacker's side sets it; Geralt's stamina state set by script). Needs a hostile NPC within 20 m
// (e.g. spawn(wolf, 1, 6, true)).
exec function gmtest_def05()
{
	GMTest_def05();
}

function GMTest_def05()
{
	var npc : CActor;

	npc = GMTestHostileNpc();
	if(!npc)
	{
		LogChannel('GMTest', "INFO DEF-05: no hostile NPC within 20 m, checks skipped");
		return;
	}
	thePlayer.GMTestSetProbes(true);
	GMTestDef05Case(npc, true, false, EET_Undefined, 0, false, "parried");
	GMTestDef05Case(npc, false, false, EET_Undefined, 0.5, true, "attack that cannot be parried, parried");
	GMTestDefKept(npc, false, EET_LongStagger, "attack that cannot be parried and staggers long, parried");
	GMTestDef05Case(npc, true, true, EET_Undefined, 0.5, true, "parried without enough stamina (STAM-03)");
	GMTestDef05Case(npc, false, true, EET_Undefined, 0.5, true, "attack that cannot be parried, parried without enough stamina");
	// last: knocks Geralt down
	GMTestDefKept(npc, false, EET_Knockdown, "knockdown attack that cannot be parried, parried");
	thePlayer.GMTestSetProbes(false);
}

// DEF-05 slice 2: Geralt's parry check. An attacker with vanilla's BreakThroughParryOnHit (every
// 3rd parry in a row staggered Geralt instead of parrying; e.g. the sq703 panther) is parried as
// usual. Scripted: Geralt guarded, the defend counter set to 3 by script, PerformParryCheck called
// as an attacker's hit calls it. Needs a hostile NPC within 20 m (e.g. spawn(wolf, 1, 6, true)).
exec function gmtest_def05_parry()
{
	GMTest_def05_parry();
}

function GMTest_def05_parry()
{
	var npc : CActor;
	var parryInfo : SParryInfo;
	var parried, hadAbility, added : bool;
	var stamina, cost : float;
	var breakThrough : SAbilityAttributeValue;

	npc = GMTestHostileNpc();
	if(!npc)
	{
		LogChannel('GMTest', "INFO DEF-05 parry check: no hostile NPC within 20 m, checks skipped");
		return;
	}
	hadAbility = npc.HasAbility('BreakThroughParryOnHit');
	if(!hadAbility)
		added = npc.AddAbility('BreakThroughParryOnHit', false);
	breakThrough = npc.GetAttributeValue('break_through_parry_on_hit_counter');
	LogChannel('GMTest', "INFO DEF-05 BreakThroughParryOnHit: had " + hadAbility + ", added " + added + ", has " + npc.HasAbility('BreakThroughParryOnHit')
		+ ", break_through_parry_on_hit_counter base " + NoTrailZeros(breakThrough.valueBase));
	if(breakThrough.valueBase != 3)
	{
		GMTestReport(false, "DEF-05 the attacker has the break-through ability (every 3rd parry)");
		if(!hadAbility)
			npc.RemoveAbility('BreakThroughParryOnHit');
		return;
	}
	GMTestDefClearHitEffects();
	thePlayer.SetGuarded(true);
	thePlayer.GainStat(BCS_Stamina, thePlayer.GetStatMax(BCS_Stamina));
	while(thePlayer.GetDefendCounter() < 3)
		thePlayer.IncDefendCounter();
	parryInfo.attacker = npc;
	parryInfo.target = thePlayer;
	parryInfo.targetToAttackerDist = 1;
	parryInfo.attackSwingType = AST_Jab;
	parryInfo.attackSwingDir = ASD_UpDown;
	parryInfo.attackActionName = 'attack_light';
	parryInfo.canBeParried = true;
	cost = thePlayer.GetStaminaActionCost(ESAT_Parry);
	stamina = thePlayer.GetStat(BCS_Stamina);
	parried = thePlayer.PerformParryCheck(parryInfo);
	LogChannel('GMTest', "INFO DEF-05 parry check against " + npc.GetDisplayName() + ", defend counter after "
		+ thePlayer.GetDefendCounter() + ": parried " + parried + ", stagger " + thePlayer.HasBuff(EET_Stagger)
		+ ", stamina " + NoTrailZeros(stamina) + " -> " + NoTrailZeros(thePlayer.GetStat(BCS_Stamina)) + " (parry cost " + NoTrailZeros(cost) + ")");
	GMTestReport(parried && !thePlayer.HasBuff(EET_Stagger), "DEF-05 the 3rd parry in a row against a break-through attacker: parried, no stagger");
	GMTestReport(AbsF(stamina - thePlayer.GetStat(BCS_Stamina) - cost) < 0.5, "DEF-05 the parry cost is paid");
	GMTestDefClearHitEffects();
	thePlayer.SetGuarded(false);
	if(!hadAbility)
		npc.RemoveAbility('BreakThroughParryOnHit');
}

// DEF-06: Geralt's counter check, called as an attacker's hit calls it (TestParryAndCounter):
// the attacker's counter window opened now and one counter press recorded, attacker straight
// ahead, full stamina. Returns whether it countered; repel is the repel type Geralt chose.
@addMethod(CR4Player)
function GMTestCounterCheck(attacker : CActor, canParry : bool, attackName : name, out repel : int) : bool
{
	var parryInfo : SParryInfo;
	var now : EngineTime;
	var ret : bool;

	now = theGame.GetEngineTime();
	counterTimestamps.Clear();
	((CNewNPC)attacker).SetCounterWindowStartTime(now);
	AddCounterTimeStamp(now);
	parryInfo.attacker = attacker;
	parryInfo.target = this;
	parryInfo.targetToAttackerAngleAbs = 0;
	parryInfo.targetToAttackerDist = 1;
	parryInfo.attackSwingType = AST_Jab;
	parryInfo.attackSwingDir = ASD_UpDown;
	parryInfo.attackActionName = attackName;
	parryInfo.canBeParried = canParry;
	SetBehaviorVariable('repelType', -1);
	ret = PerformCounterCheck(parryInfo);
	repel = (int)GetBehaviorVariable('repelType');
	counterTimestamps.Clear();
	return ret;
}

// One DEF-06 counter: whether it counters and what it costs.
function GMTestDef06Counter(npc : CActor, canParry : bool, attackName : name, label : string)
{
	var countered : bool;
	var stamina, cost : float;
	var repel : int;

	thePlayer.GainStat(BCS_Stamina, thePlayer.GetStatMax(BCS_Stamina));
	cost = thePlayer.GetStaminaActionCost(ESAT_Counterattack);
	stamina = thePlayer.GetStat(BCS_Stamina);
	countered = thePlayer.GMTestCounterCheck(npc, canParry, attackName, repel);
	LogChannel('GMTest', "INFO DEF-06 " + label + ": countered " + countered + ", repel " + repel + ", stamina "
		+ NoTrailZeros(stamina) + " -> " + NoTrailZeros(thePlayer.GetStat(BCS_Stamina)) + " (counter cost " + NoTrailZeros(cost) + ")");
	GMTestReport(countered, "DEF-06 " + label + ": countered");
	GMTestReport(AbsF(stamina - thePlayer.GetStat(BCS_Stamina) - cost) < 0.5, "DEF-06 " + label + ": costs the counter cost, no multiplier");
	npc.RemoveAllBuffsOfType(EET_CounterStrikeHit);
}

// DEF-06: counters, by scripted counter checks (see GMTestCounterCheck). Needs a hostile NPC
// within 20 m (e.g. spawn(wolf, 1, 6, true)) and Geralt's sword drawn (combat).
exec function gmtest_def06()
{
	GMTest_def06();
}

function GMTest_def06()
{
	var npc : CNewNPC;
	var hadAbility : bool;

	npc = (CNewNPC)GMTestHostileNpc();
	if(!npc)
	{
		LogChannel('GMTest', "INFO DEF-06: no hostile NPC within 20 m, checks skipped");
		return;
	}
	LogChannel('GMTest', "INFO DEF-06 attacker " + npc.GetDisplayName());
	GMTestDef06Counter(npc, true, 'attack_light', "light attack");
	GMTestDef06Counter(npc, false, 'attack_light', "attack that cannot be parried (vanilla: no counter)");
	GMTestDef06Counter(npc, true, 'attack_heavy', "heavy attack (port before DEF-06: x1.25)");
	hadAbility = npc.HasAbility('CannotBeCountered');
	if(!hadAbility)
		npc.AddAbility('CannotBeCountered', false);
	GMTestDef06Counter(npc, true, 'attack_light', "attacker with CannotBeCountered (vanilla: no counter)");
	if(!hadAbility)
		npc.RemoveAbility('CannotBeCountered');
}

// DEF-06: the repel Geralt chooses, against the nearest hostile human (two-handed or not) or Grave
// Hag (tongue attack or not); scripted counter checks as gmtest_def06.
exec function gmtest_def06_repel()
{
	var npc : CNewNPC;
	var repel : int;
	var hadAbility : bool;

	npc = (CNewNPC)GMTestHostileNpc();
	if(!npc)
	{
		LogChannel('GMTest', "INFO DEF-06 repel: no hostile NPC within 20 m, checks skipped");
		return;
	}
	thePlayer.GainStat(BCS_Stamina, thePlayer.GetStatMax(BCS_Stamina));
	if(npc.HasAbility('mon_gravehag'))
	{
		LogChannel('GMTest', "INFO DEF-06 repel: Grave Hag, TongueAttack " + npc.HasAbility('TongueAttack'));
		npc.SetBehaviorVariable('AttackType', 6);
		thePlayer.GMTestCounterCheck(npc, true, 'attack_light', repel);
		GMTestReport(repel == (int)PRT_Slash && npc.HasBuff(EET_CounterStrikeHit), "DEF-06 Grave Hag tongue attack: special repel (slash), stunned (repel " + repel + ")");
		npc.RemoveAllBuffsOfType(EET_CounterStrikeHit);
		thePlayer.GainStat(BCS_Stamina, thePlayer.GetStatMax(BCS_Stamina));
		npc.SetBehaviorVariable('AttackType', 0);
		thePlayer.GMTestCounterCheck(npc, true, 'attack_light', repel);
		GMTestReport(repel == (int)PRT_SideStepSlash, "DEF-06 Grave Hag other attack: side-step like other monsters (vanilla: special repel) (repel " + repel + ")");
		npc.RemoveAllBuffsOfType(EET_CounterStrikeHit);
		return;
	}
	if(!npc.IsHuman())
	{
		LogChannel('GMTest', "INFO DEF-06 repel: " + npc.GetDisplayName() + " is neither human nor a Grave Hag, checks skipped");
		return;
	}
	hadAbility = npc.HasAbility('SkillTwoHanded');
	if(hadAbility)
		npc.RemoveAbility('SkillTwoHanded');
	thePlayer.GMTestCounterCheck(npc, true, 'attack_light', repel);
	GMTestReport((repel == (int)PRT_Bash || repel == (int)PRT_Kick) && (npc.HasBuff(EET_CounterStrikeHit) || npc.IsInAgony() || npc.HasBuff(EET_HeavyKnockdown) || npc.HasBuff(EET_Knockdown)),
		"DEF-06 human, one-handed: bash or kick, stunned or knocked down (repel " + repel + ")");
	npc.RemoveAllBuffsOfType(EET_CounterStrikeHit);
	thePlayer.GainStat(BCS_Stamina, thePlayer.GetStatMax(BCS_Stamina));
	npc.AddAbility('SkillTwoHanded', false);
	thePlayer.GMTestCounterCheck(npc, true, 'attack_light', repel);
	GMTestReport(repel == (int)PRT_SideStepSlash && !npc.HasBuff(EET_CounterStrikeHit), "DEF-06 human, two-handed: side-step, not stunned (vanilla: bash or kick) (repel " + repel + ")");
	npc.RemoveAllBuffsOfType(EET_CounterStrikeHit);
	if(!hadAbility)
		npc.RemoveAbility('SkillTwoHanded');
}

// DEF-06: a partial counter, by scripted hits as gmtest_def05 (the countered flag set as the
// attacker's side sets it). Needs a hostile NPC within 20 m (e.g. spawn(wolf, 1, 6, true)).
function GMTestDef06Hit(npc : CActor, canParry : bool, effect : EEffectType, expectShare : float, label : string)
{
	var action : W3Action_Attack;
	var dmg, share : float;
	var stagger, bleeding, bledBefore, ok : bool;

	GMTestDefClearHitEffects();
	bledBefore = thePlayer.HasBuff(EET_Bleeding);	// a real bite's bleed is removed only on the next tick
	dmg = GMTestDefParryHit(npc, canParry, false, effect, action, true);
	stagger = thePlayer.HasBuff(EET_Stagger) || thePlayer.HasBuff(EET_LongStagger);
	bleeding = thePlayer.HasBuff(EET_Bleeding);
	share = -1;
	if(thePlayer.gmTestReduceBefore > 0)
		share = thePlayer.gmTestReduceAfter / thePlayer.gmTestReduceBefore;
	LogChannel('GMTest', "INFO DEF-06 " + label + ": damage taken " + NoTrailZeros(dmg) + ", ReduceDamage " + NoTrailZeros(thePlayer.gmTestReduceBefore)
		+ " -> " + NoTrailZeros(thePlayer.gmTestReduceAfter) + ", parry stagger " + action.IsParryStagger() + ", staggered " + stagger + ", bleeding " + bleeding
		+ ", knocked down " + thePlayer.HasBuff(EET_Knockdown) + ", bled before " + bledBefore + ", deals damage " + action.DealsAnyDamage()
		+ ", buffs if no damage " + action.ProcessBuffsIfNoDamage() + ", dealt " + NoTrailZeros(action.GetDamageDealt()));
	if(expectShare == 0)	// the probe, not health: a real bite between two calls must not count
		ok = thePlayer.gmTestReduceBefore > 0 && thePlayer.gmTestReduceAfter == 0;
	else
		ok = AbsF(share - expectShare) < 0.01 && dmg > 0;
	GMTestReport(ok, "DEF-06 " + label + ": " + NoTrailZeros(expectShare * 100) + "% of the damage");
	if(expectShare < 1)
		GMTestReport(!stagger && (!bleeding || bledBefore), "DEF-06 " + label + ": no effects (no stagger, no bleeding)");
	else
		GMTestReport(thePlayer.HasBuff(EET_Knockdown), "DEF-06 " + label + ": knocked down");
	delete action;
	GMTestDefClearHitEffects();
}

exec function gmtest_def06_hit()
{
	GMTest_def06_hit();
}

function GMTest_def06_hit()
{
	var npc : CActor;

	npc = GMTestHostileNpc();
	if(!npc)
	{
		LogChannel('GMTest', "INFO DEF-06 hit: no hostile NPC within 20 m, checks skipped");
		return;
	}
	thePlayer.GMTestSetProbes(true);
	GMTestDef06Hit(npc, true, EET_Undefined, 0, "countered (vanilla: no damage, but its effects)");
	GMTestDef06Hit(npc, false, EET_Undefined, 0.5, "attack that cannot be parried, countered (partial counter)");
	GMTestDefKept(npc, true, EET_LongStagger, "attack that cannot be parried and staggers long, countered");
	// last: knocks Geralt down
	GMTestDefKept(npc, true, EET_Knockdown, "knockdown attack that cannot be parried, countered");
	thePlayer.GMTestSetProbes(false);
}

// DEF-06: the counter stun lasts 1 s (vanilla 0.5; DLC XML). Scripted: the stun added to the
// nearest hostile NPC as a counter adds it. Needs a hostile NPC within 20 m (e.g. spawn(wolf, 1, 6, true)).
exec function gmtest_def06_stun()
{
	var npc : CActor;
	var buff : CBaseGameplayEffect;

	npc = GMTestHostileNpc();
	if(!npc)
	{
		LogChannel('GMTest', "INFO DEF-06 stun: no hostile NPC within 20 m, checks skipped");
		return;
	}
	npc.RemoveAllBuffsOfType(EET_CounterStrikeHit);
	npc.AddEffectDefault(EET_CounterStrikeHit, thePlayer, "ReflexParryPerformed");
	buff = npc.GetBuff(EET_CounterStrikeHit);
	if(!buff)
	{
		GMTestReport(false, "DEF-06 the counter stun is applied to " + npc.GetDisplayName());
		return;
	}
	LogChannel('GMTest', "INFO DEF-06 counter stun on " + npc.GetDisplayName() + ": initial duration " + NoTrailZeros(buff.GetInitialDuration())
		+ ", left " + NoTrailZeros(buff.GetDurationLeft()));
	GMTestReport(AbsF(buff.GetInitialDuration() - 1.0) < 0.05, "DEF-06 the counter stun lasts 1 s");
}

// DEF-06: tournament contestants are side-stepped on a counter. Spawns the contestant template
// "sq701_<name>" (e.g. guy, horm_bow) 2 m in front of Geralt as a hostile enemy, then runs a
// scripted counter check against it (GMTestCounterCheck). expectContestant: whether the template is
// one of legacy's 12 marked contestants.
exec function gmtest_def06_contestant(who : string, expectContestant : bool)
{
	var template : CEntityTemplate;
	var npc : CNewNPC;
	var repel : int;
	var path : string;

	path = "dlc\bob\data\quests\sidequests\quest_files\sq701_tournament\characters\contestants" + "\sq701_" + who + ".w2ent";
	template = (CEntityTemplate)LoadResource(path, true);
	if(!template)
	{
		GMTestReport(false, "DEF-06 contestant template " + path + " found");
		return;
	}
	npc = (CNewNPC)theGame.CreateEntity(template, thePlayer.GetWorldPosition() + thePlayer.GetHeadingVector() * 2, thePlayer.GetWorldRotation());
	npc.SetTemporaryAttitudeGroup('hostile_to_player', AGP_Default);
	thePlayer.GainStat(BCS_Stamina, thePlayer.GetStatMax(BCS_Stamina));
	thePlayer.GMTestCounterCheck(npc, true, 'attack_light', repel);
	LogChannel('GMTest', "INFO DEF-06 contestant " + npc.GetReadableName() + ": human " + npc.IsHuman() + ", SkillTwoHanded "
		+ npc.HasAbility('SkillTwoHanded') + ", contestant " + GMIsTournamentContestant(npc) + ", repel " + repel);
	GMTestReport(GMIsTournamentContestant(npc) == expectContestant, "DEF-06 sq701_" + who + " recognised as a tournament contestant: " + expectContestant);
	if(expectContestant)
		GMTestReport(repel == (int)PRT_SideStepSlash, "DEF-06 tournament contestant sq701_" + who + " countered: side-step");
	npc.Destroy();
}

// DEF-07: a counter is a light attack: no -75% attack power, IsLightAttack is true for it (light-
// attack crit chance, Lynx set, combo skills), and it gets a light attack's attack power bonuses
// (Muscle Memory S_Sword_s21 by tag and per level, attack_power_fast_style): its attack power equals
// a light attack's. Scripted: attack actions of Geralt on the nearest hostile NPC, built as real attacks build them
// (the attack name also as skill name), their power read without processing them.
function GMTestPlayerAttack(npc : CActor, attackName : name) : W3Action_Attack
{
	var action : W3Action_Attack;

	action = new W3Action_Attack in theGame.damageMgr;
	action.Init(thePlayer, npc, NULL, thePlayer.GetInventory().GetItemFromSlot('r_weapon'), attackName, thePlayer.GetName(), EHRT_Light,
		true, true, attackName, AST_Jab, ASD_UpDown, true, false, false, false);
	return action;
}

// DEF-07's situation-free checks (in gmtest_regress()).
function GMTest_def07()
{
	var min, max : SAbilityAttributeValue;

	GMTestReport(thePlayer.IsLightAttack('counter_attack_light'), "DEF-07 a counter is a light attack");
	GMTestReport(thePlayer.IsLightAttack('attack_light_special'), "DEF-07 the special light attack is a light attack");
	GMTestReport(!thePlayer.IsLightAttack('attack_heavy'), "DEF-07 a heavy attack is not a light attack");
	theGame.GetDefinitionsManager().GetAbilityAttributeValue('counter_attack_light', 'attack_power', min, max);
	GMTestReport(min.valueMultiplicative == 0 && theGame.GetDefinitionsManager().AbilityHasTag('counter_attack_light', 'counter_attack_light'),
		"DEF-07 counter_attack_light: no attack power penalty (vanilla -0.75), tag kept (" + NoTrailZeros(min.valueMultiplicative) + ")");
	GMTestReport(theGame.GetDefinitionsManager().AbilityHasTag('sword_s21', 'counter_attack_light') && theGame.GetDefinitionsManager().AbilityHasTag('sword_s21', 'attack_light'),
		"DEF-07 Muscle Memory sword_s21 tagged for light attacks and counters");
}

exec function gmtest_def07()
{
	var npc : CActor;
	var light, counter : W3Action_Attack;
	var lightPower, counterPower, bonus, fast : SAbilityAttributeValue;

	GMTest_def07();
	npc = GMTestHostileNpc();
	if(!npc)
	{
		LogChannel('GMTest', "INFO DEF-07: no hostile NPC within 20 m, power check skipped");
		return;
	}
	light = GMTestPlayerAttack(npc, 'attack_light');
	counter = GMTestPlayerAttack(npc, 'counter_attack_light');
	lightPower = light.GetPowerStatValue();
	counterPower = counter.GetPowerStatValue();
	if(GetWitcherPlayer().CanUseSkill(S_Sword_s21))
		bonus = GetWitcherPlayer().GetSkillAttributeValue(S_Sword_s21, PowerStatEnumToName(CPS_AttackPower), false, true) * GetWitcherPlayer().GetSkillLevel(S_Sword_s21);
	fast = thePlayer.GetAttributeValue('attack_power_fast_style');
	LogChannel('GMTest', "INFO DEF-07 attack power (mult): light " + NoTrailZeros(lightPower.valueMultiplicative) + ", counter " + NoTrailZeros(counterPower.valueMultiplicative)
		+ " (Muscle Memory S_Sword_s21 " + GetWitcherPlayer().CanUseSkill(S_Sword_s21) + " +" + NoTrailZeros(bonus.valueMultiplicative)
		+ " per light attack, fast style +" + NoTrailZeros(fast.valueMultiplicative) + ")");
	GMTestReport(AbsF(counterPower.valueMultiplicative - lightPower.valueMultiplicative) < 0.001
		&& AbsF(counterPower.valueAdditive - lightPower.valueAdditive) < 0.001, "DEF-07 a counter has a light attack's attack power (vanilla -75%, no light bonuses)");
	delete light;
	delete counter;
}

// Probe: the attack name, attack type and attack power of Geralt's real melee hits, logged as the
// damage manager processes them (with gmtest_probes(true)). gmtest_light() makes one real light
// attack through the input handler (scripted input).
@wrapMethod(W3DamageManagerProcessor)
function ProcessAction(act : W3DamageAction)
{
	var attack : W3Action_Attack;
	var power : SAbilityAttributeValue;

	attack = (W3Action_Attack)act;
	if(GMTestProbes() && act.victim == thePlayer && act.IsActionRanged())
		LogChannel('GMTest', "INFO ranged hit on Geralt by " + act.attacker.GetDisplayName() + ", vitality " + NoTrailZeros(thePlayer.GetStat(BCS_Vitality)));
	if(GMTestProbes() && attack && act.attacker == thePlayer && attack.IsActionMelee())
	{
		power = attack.GetPowerStatValue();
		LogChannel('GMTest', "INFO hit by Geralt: attack " + attack.GetAttackName() + ", type " + attack.GetAttackTypeName()
			+ ", attack power mult " + NoTrailZeros(power.valueMultiplicative) + ", Muscle Memory S_Sword_s21 "
			+ GetWitcherPlayer().CanUseSkill(S_Sword_s21) + " level " + GetWitcherPlayer().GetSkillLevel(S_Sword_s21));
	}
	wrappedMethod(act);
}

exec function gmtest_light()
{
	thePlayer.GainStat(BCS_Stamina, thePlayer.GetStatMax(BCS_Stamina));
	GMTestActInput(0, true);
	GMTestActInput(0, false);
}

// DEF-07: the per-enemy "was countered" flag and its +25% critical hit chance. Scripted: a countered
// hit from the nearest hostile NPC on Geralt (as gmtest_def05), then crit chance read-backs and one
// scripted hit of Geralt's on it. gmtest_def07_flag_b(), called more than 3 s later, checks expiry.
exec function gmtest_def07_flag()
{
	var npc : CActor;
	var action : W3Action_Attack;
	var base, countered, bolt, other : float;

	npc = GMTestHostileNpc();
	if(!npc)
	{
		LogChannel('GMTest', "INFO DEF-07 flag: no hostile NPC within 20 m, checks skipped");
		return;
	}
	npc.GMSetWasCountered(false);
	base = GetWitcherPlayer().GetCriticalHitChance(true, false, npc, MC_NotSet, false);
	GMTestDefParryHit(npc, true, false, EET_Undefined, action, true);
	delete action;
	GMTestDefClearHitEffects();
	GMTestReport(npc.GMWasCountered(), "DEF-07 a countered enemy is marked countered");
	GMTestReport(GetWitcherPlayer().HasRecentlyCountered(), "DEF-07 vanilla's recently-countered flag on Geralt still set (S_Sword_s31, Counterattack)");
	countered = GetWitcherPlayer().GetCriticalHitChance(true, false, npc, MC_NotSet, false);
	bolt = GetWitcherPlayer().GetCriticalHitChance(false, false, npc, MC_NotSet, true) - GetWitcherPlayer().GetCriticalHitChance(false, false, NULL, MC_NotSet, true);
	other = GetWitcherPlayer().GetCriticalHitChance(false, false, npc, MC_NotSet, false) - GetWitcherPlayer().GetCriticalHitChance(false, false, NULL, MC_NotSet, false);
	LogChannel('GMTest', "INFO DEF-07 crit chance against " + npc.GetDisplayName() + ": " + NoTrailZeros(base) + " -> " + NoTrailZeros(countered)
		+ " countered; bolt +" + NoTrailZeros(bolt) + ", neither light nor heavy +" + NoTrailZeros(other));
	GMTestReport(AbsF(countered - base - 0.25) < 0.001, "DEF-07 +25% crit chance against a countered enemy");
	GMTestReport(AbsF(bolt) < 0.001 && AbsF(other) < 0.001, "DEF-07 no bonus for bolts and other actions");
	action = GMTestDefHit(thePlayer, npc, true, 0);
	delete action;
	GMTestReport(!npc.GMWasCountered(), "DEF-07 Geralt's next hit uses the bonus up");
	GMTestDefParryHit(npc, true, false, EET_Undefined, action, true);
	delete action;
	GMTestDefClearHitEffects();
	LogChannel('GMTest', "INFO DEF-07 countered again (for gmtest_def07_flag_b after 3 s): " + npc.GMWasCountered());
}

exec function gmtest_def07_flag_b()
{
	var npc : CActor;

	npc = GMTestHostileNpc();
	if(npc)
		GMTestReport(!npc.GMWasCountered(), "DEF-07 the countered mark expires after 3 s");
}

// DEF-06: countered enemies' AI. Probes on the enemy defence tasks count, per state (blocked: stunned
// by a counter or countered within 3 s; free), how often the real AI asks them and how often they
// answer yes. gmtest_def06_ai_a(true) stuns the nearest hostile NPC and marks it countered (both by
// script) and resets the counts; gmtest_def06_ai_a(false) only resets them (control). Provoke with
// real attacks (gmtest_light()), then gmtest_def06_ai_b(blocked) reports.
@addField(CR4Player)
var gmTestAiAsked : array<int>;
@addField(CR4Player)
var gmTestAiYes : array<int>;

@addMethod(CR4Player)
function GMTestAiCount(task : int, blocked : bool, yes : bool)
{
	var i : int;

	if(gmTestAiAsked.Size() < 6)
	{
		gmTestAiAsked.Clear();
		gmTestAiYes.Clear();
		for(i = 0; i < 6; i += 1)
		{
			gmTestAiAsked.PushBack(0);
			gmTestAiYes.PushBack(0);
		}
	}
	i = task * 2;
	if(!blocked)
		i += 1;
	gmTestAiAsked[i] += 1;
	if(yes)
		gmTestAiYes[i] += 1;
}

@addMethod(CR4Player)
function GMTestAiReset()
{
	gmTestAiAsked.Clear();
	gmTestAiYes.Clear();
	GMTestAiCount(0, true, false);
	gmTestAiAsked[0] = 0;
}

@wrapMethod(CBTTaskDodge)
function IsAvailable() : bool
{
	var ret : bool;

	ret = wrappedMethod();
	if(GMTestProbes())
		thePlayer.GMTestAiCount(0, GMEnemyCannotDodge(GetNPC()), ret);
	return ret;
}

@wrapMethod(CBTTaskPerformParry)
function IsAvailable() : bool
{
	var ret : bool;

	ret = wrappedMethod();
	if(GMTestProbes())
		thePlayer.GMTestAiCount(1, GetNPC().HasBuff(EET_CounterStrikeHit), ret);
	return ret;
}

@wrapMethod(CBTTaskReaction)
function ChooseAndCheckDodge() : bool
{
	var ret : bool;

	ret = wrappedMethod();
	if(GMTestProbes())
		thePlayer.GMTestAiCount(2, GetNPC().HasBuff(EET_CounterStrikeHit), ret);
	return ret;
}

exec function gmtest_def06_ai_a(block : bool)
{
	var npc : CActor;

	npc = GMTestHostileNpc();
	if(!npc)
	{
		LogChannel('GMTest', "INFO DEF-06 AI: no hostile NPC within 20 m");
		return;
	}
	thePlayer.GMTestSetProbes(true);
	thePlayer.GMTestAiReset();
	if(block)
	{
		npc.AddEffectDefault(EET_CounterStrikeHit, thePlayer, "ReflexParryPerformed");
		npc.GMSetWasCountered(true);
	}
	LogChannel('GMTest', "INFO DEF-06 AI on " + npc.GetDisplayName() + ": stunned " + npc.HasBuff(EET_CounterStrikeHit) + ", countered " + npc.GMWasCountered());
}

exec function gmtest_def06_ai_b(blocked : bool)
{
	var labels : array<string>;
	var i, j, askedBlocked, yesBlocked : int;

	labels.PushBack("dodge task available");
	labels.PushBack("parry task available");
	labels.PushBack("reaction dodge");
	for(i = 0; i < 3; i += 1)
	{
		j = i * 2;
		LogChannel('GMTest', "INFO DEF-06 AI " + labels[i] + ": while blocked asked " + thePlayer.gmTestAiAsked[j] + ", yes " + thePlayer.gmTestAiYes[j]
			+ "; free asked " + thePlayer.gmTestAiAsked[j + 1] + ", yes " + thePlayer.gmTestAiYes[j + 1]);
		askedBlocked += thePlayer.gmTestAiAsked[j];
		yesBlocked += thePlayer.gmTestAiYes[j];
	}
	if(blocked)
	{
		GMTestReport(askedBlocked > 0, "DEF-06 AI asked its defence tasks while the enemy was stunned or countered");
		GMTestReport(yesBlocked == 0, "DEF-06 no dodge, parry or reaction dodge while stunned or countered");
	}
	thePlayer.GMTestSetProbes(false);
}

// Marks the nearest hostile NPC countered (and stunned when stun is true) without resetting the AI
// counts, then makes one real light attack: the AI decides on its defence during the swing.
exec function gmtest_def06_ai_swing(stun : bool)
{
	var npc : CActor;

	npc = GMTestHostileNpc();
	if(!npc)
		return;
	if(stun)
		npc.AddEffectDefault(EET_CounterStrikeHit, thePlayer, "ReflexParryPerformed");
	npc.GMSetWasCountered(true);
	thePlayer.GainStat(BCS_Stamina, thePlayer.GetStatMax(BCS_Stamina));
	GMTestActInput(0, true);
	GMTestActInput(0, false);
}

// DEF-08: spawns an enemy archer, living_world/enemy_templates/<who>.w2ent (e.g. skellige_bandit_bow,
// baron_renegade_bow), at the given distance in front of Geralt as a hostile enemy, to shoot at him.
exec function gmtest_def08_archer(who : string, distance : float)
{
	var template : CEntityTemplate;
	var npc : CNewNPC;
	var path : string;

	path = "living_world/enemy_templates/" + who + ".w2ent";
	template = (CEntityTemplate)LoadResource(path, true);
	if(!template)
	{
		LogChannel('GMTest', "INFO DEF-08 archer template not found: " + path);
		return;
	}
	npc = (CNewNPC)theGame.CreateEntity(template, thePlayer.GetWorldPosition() + thePlayer.GetHeadingVector() * distance, thePlayer.GetWorldRotation());
	npc.SetTemporaryAttitudeGroup('hostile_to_player', AGP_Default);
	LogChannel('GMTest', "INFO DEF-08 archer spawned: " + npc.GetReadableName() + ", Deflection usable: classic " + GetWitcherPlayer().CanUseSkill(S_Sword_s10)
		+ ", new S_Sword_s33 " + GetWitcherPlayer().CanUseSkill(S_Sword_s33));
}
