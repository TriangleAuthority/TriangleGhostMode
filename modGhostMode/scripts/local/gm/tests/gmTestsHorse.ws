// HORSE's in-game checks (horse combat, docs/features/horse.md). gmtest_regress() and gmtest_panel() call the two
// functions GMTest_horse() and GMTest_horse_after(), so HORSE adds its checks here and never edits gmTests.ws's lists.
//   GMTest_horse()        in gmtest_regress(): checks that need no fight, input or menu, each restoring what it changes
//   GMTest_horse_after()  in gmtest_panel(): checks that need the pause menu open, or read the game a frame or more
//                        after gmtest_regress() (spawned samples, effects' first updates)

exec function gmtest_horse()
{
	thePlayer.GMTestCount(true, true);
	GMTest_horse();
	LogChannel('GMTest', "SUMMARY horse: " + thePlayer.gmTestPassed + " passed, " + thePlayer.gmTestFailed + " failed");
}

// HORSE-01: the hits read the weapon in Geralt's hand ('r_weapon'). With a sword in hand they run here; without
// one the regression draws the steel sword and GMTest_horse_after() runs them, then sheathes it again. (Seen
// 2026-11-03: with the hits always in the panel, the classic tree's run found no sword in hand there.)
function GMTest_horse()
{
	var w : W3PlayerWitcher;

	w = GetWitcherPlayer();
	GMTestHorse02Resources();
	GMTestHorse02Drain();
	w.GMTestHorseSetDrew(false);
	if(w.GetInventory().IsIdValid(w.GetInventory().GetItemFromSlot('r_weapon')))
	{
		GMTestHorse01Hits("regression, on foot");
	}
	else
	{
		LogChannel('GMTest', "INFO HORSE-01: no sword in hand in gmtest_regress(); drawn for gmtest_panel()");
		w.GMTestHorseSetDrew(true);
		w.OnEquipMeleeWeapon(PW_Steel, true);
	}
}

function GMTest_horse_after()
{
	var w : W3PlayerWitcher;
	var horse : CNewNPC;

	w = GetWitcherPlayer();
	if(w.gmTestHorseDrew)
	{
		GMTestHorse01Hits("regression (panel), on foot");
		w.OnEquipMeleeWeapon(PW_None, true);
	}
	GMTestHorse03("regression");
	horse = thePlayer.GetHorseWithInventory();
	if(horse && !thePlayer.GetUsedHorseComponent())
		GMTestHorse04Riders(horse.GetHorseComponent(), horse);
}

// ---- HORSE-01: horseback hits ----
// A probe records what each horseback hit carries: the attack's damage list right after its Init (the weapon's
// damage) and as it reaches the damage manager (after the speed bonus), its knockdown, and the speed the hit
// function was called with. On only while gmTestHorseRec is set (and the test probes are on).
//   gmtest_horse01()           the hits at speeds 0 to 4 and two enemies in one call (DH1), through the
//                              combat manager of the horse Geralt rides, or one made for the test on foot;
//                              needs the sword in hand (gmtest_draw(), or on horseback the first attack press)
//   gmtest_horse01_swing_a()   on horseback, sword drawn: hostile frozen dummies 1.8 m to Geralt's left and right,
//                              then a real sword attack through the combat manager's input event
//   gmtest_horse01_swing_b()   a second or more later: what the swing's hits carried

struct SGMTestHorseHit
{
	var victim : CActor;
	var initSum : float;		// the damage list's sum after Init (the weapon's damage)
	var finalSum : float;		// its sum as the damage manager receives it
	var minRatio : float;		// per damage type: received / after Init
	var maxRatio : float;
	var direct : bool;			// direct damage in the list
	var knockdown : bool;		// the knockdown applicator among its effects
	var phys : float;			// physical damage added after Init (trampling's bonus)
	var force : bool;			// force damage in the list (5.x's trampling)
};

@addField(CR4Player)
var gmTestHorseRec : bool;
@addField(CR4Player)
var gmTestHorseInit : array<SRawDamage>;
@addField(CR4Player)
var gmTestHorseHits : array<SGMTestHorseHit>;
@addField(CR4Player)
var gmTestHorseSpeeds : array<float>;
@addField(CR4Player)
var gmTestHorseDrew : bool;

@addMethod(CR4Player)
function GMTestHorseSetDrew(drew : bool)
{
	gmTestHorseDrew = drew;
}

@addMethod(CR4Player)
function GMTestHorseRecord(on : bool)
{
	gmTestHorseRec = on;
	if(on)
	{
		gmTestHorseInit.Clear();
		gmTestHorseHits.Clear();
		gmTestHorseSpeeds.Clear();
	}
}

@addMethod(CR4Player)
function GMTestHorseSetInit(dts : array<SRawDamage>)
{
	gmTestHorseInit = dts;
}

@addMethod(CR4Player)
function GMTestHorseAddSpeed(speed : float)
{
	gmTestHorseSpeeds.PushBack(speed);
}

@addMethod(CR4Player)
function GMTestHorseAddHit(act : W3DamageAction)
{
	var hit : SGMTestHorseHit;
	var dts : array<SRawDamage>;
	var i, j : int;
	var r : float;

	act.GetDTs(dts);
	hit.victim = (CActor)act.victim;
	hit.minRatio = 1000;
	hit.maxRatio = -1;
	hit.knockdown = act.HasBuff(EET_KnockdownTypeApplicator);
	for(i = 0; i < gmTestHorseInit.Size(); i += 1)
		hit.initSum += gmTestHorseInit[i].dmgVal;
	for(i = 0; i < dts.Size(); i += 1)
	{
		hit.finalSum += dts[i].dmgVal;
		if(dts[i].dmgType == theGame.params.DAMAGE_NAME_DIRECT && dts[i].dmgVal > 0)
			hit.direct = true;
		if(dts[i].dmgType == theGame.params.DAMAGE_NAME_FORCE && dts[i].dmgVal > 0)
			hit.force = true;
		if(dts[i].dmgType == theGame.params.DAMAGE_NAME_PHYSICAL)
			hit.phys += dts[i].dmgVal;
		for(j = 0; j < gmTestHorseInit.Size(); j += 1)
		{
			if(gmTestHorseInit[j].dmgType == dts[i].dmgType && gmTestHorseInit[j].dmgVal > 0)
			{
				if(dts[i].dmgType == theGame.params.DAMAGE_NAME_PHYSICAL)
					hit.phys -= gmTestHorseInit[j].dmgVal;
				r = dts[i].dmgVal / gmTestHorseInit[j].dmgVal;
				hit.minRatio = MinF(hit.minRatio, r);
				hit.maxRatio = MaxF(hit.maxRatio, r);
			}
		}
	}
	gmTestHorseHits.PushBack(hit);
}

function GMTestHorseRecording() : bool
{
	return GMTestProbes() && thePlayer.gmTestHorseRec;
}

@wrapMethod(W3Action_Attack)
function Init( attackr : CGameplayEntity, victm : CGameplayEntity, causr : IScriptable, weapId : SItemUniqueId, attName : name, src :string, hrt : EHitReactionType, canParry : bool, canDodge : bool, skillName : name, swType : EAttackSwingType, swDir : EAttackSwingDirection, isM : bool, isR : bool, isW : bool, isE : bool, optional hitFX_ : name, optional hitBackFX_ : name, optional hitParriedFX_ : name, optional hitBackParriedFX_ : name, optional crossId : SItemUniqueId)
{
	var dts : array<SRawDamage>;

	wrappedMethod(attackr, victm, causr, weapId, attName, src, hrt, canParry, canDodge, skillName, swType, swDir, isM, isR, isW, isE, hitFX_, hitBackFX_, hitParriedFX_, hitBackParriedFX_, crossId);
	if(GMTestHorseRecording() && (attackr == thePlayer && attName == 'attack_heavy' || attName == 'attack_speed_based'))
	{
		GetDTs(dts);
		thePlayer.GMTestHorseSetInit(dts);
	}
}

@wrapMethod(W3DamageManager)
function ProcessAction( act : W3DamageAction )
{
	if(GMTestHorseRecording() && act && (W3Action_Attack)act && (act.attacker == thePlayer || ((W3Action_Attack)act).GetAttackName() == 'attack_speed_based'))
		thePlayer.GMTestHorseAddHit(act);
	wrappedMethod(act);
}

@wrapMethod(W3VehicleCombatManagerStateSwordAttack)
function DealDamageToHostiles( entities : array<CGameplayEntity>, speed : float, baseDamage : float )
{
	if(GMTestHorseRecording())
		thePlayer.GMTestHorseAddSpeed(speed);
	wrappedMethod(entities, speed, baseDamage);
}

@addMethod(W3VehicleCombatManager)
function GMTestHorseSetRider(r : CR4Player)
{
	rider = r;
}

// Calls the state's hit function as DoAttack does (the state's rider taken from the manager, as its OnEnterState does).
@addMethod(W3VehicleCombatManagerStateSwordAttack)
function GMTestHorseDeal(entities : array<CGameplayEntity>, speed : float)
{
	rider = parent.rider;
	DealDamageToHostiles(entities, speed, BASE_DAMAGE);
}

// A hostile frozen human at Geralt's position + forward and right (metres), immortal, not in the dummy list.
function GMTestHorseSpawn(forward : float, right : float) : CNewNPC
{
	var template : CEntityTemplate;
	var npc : CNewNPC;
	var pos : Vector;

	template = (CEntityTemplate)LoadResource(GMTestDummyTemplate("human"), true);
	pos = thePlayer.GetWorldPosition() + thePlayer.GetHeadingVector() * forward + thePlayer.GetWorldRight() * right;
	npc = (CNewNPC)theGame.CreateEntity(template, pos, VecToRotation(thePlayer.GetWorldPosition() - pos));
	if(!npc)
		return NULL;
	npc.SetTemporaryAttitudeGroup('hostile_to_player', AGP_Default);
	npc.SetImmortalityMode(AIM_Immortal, AIC_Default, true);
	npc.SetAnimationSpeedMultiplier(0.001);
	return npc;
}

// The held weapon's damage, summed over its damage types (what Init puts in the list, before the random 0.9 to 1.1).
function GMTestHorseWeaponDamage() : float
{
	var inv : CInventoryComponent;
	var id : SItemUniqueId;
	var types : array<name>;
	var i : int;
	var sum : float;

	inv = thePlayer.GetInventory();
	id = inv.GetItemFromSlot('r_weapon');
	inv.GetWeaponDTNames(id, types);
	for(i = 0; i < types.Size(); i += 1)
		sum += thePlayer.GetTotalWeaponDamage(id, types[i], GetInvalidUniqueId());
	return sum;
}

function GMTestHorseHitText(hit : SGMTestHorseHit) : string
{
	return "after Init " + NoTrailZeros(hit.initSum) + ", received " + NoTrailZeros(hit.finalSum) + " (x" + NoTrailZeros(hit.minRatio)
		+ " to x" + NoTrailZeros(hit.maxRatio) + " per type), direct " + hit.direct + ", knockdown " + hit.knockdown;
}

// Each of the hit's damage types got speed/4 more (the added share is itself randomised 0.9 to 1.1 as a melee hit's).
function GMTestHorseRatioOk(hit : SGMTestHorseHit, speed : float) : bool
{
	var share : float;

	share = ClampF(speed / 4.0, 0, 1);
	return hit.maxRatio > 0 && hit.minRatio >= 1 + share * 0.9 - 0.001 && hit.maxRatio <= 1 + share * 1.1 + 0.001;
}

function GMTestHorseInitOk(hit : SGMTestHorseHit, weapon : float) : bool
{
	return hit.initSum >= weapon * 0.88 && hit.initSum <= weapon * 1.12;
}

function GMTestHorse01Hits(label : string)
{
	var mgr : W3VehicleCombatManager;
	var st : W3VehicleCombatManagerStateSwordAttack;
	var a, b : CNewNPC;
	var ents : array<CGameplayEntity>;
	var hit, hitB : SGMTestHorseHit;
	var weapon, staminaBefore, sp : float;
	var s : int;
	var made, probes, ok : bool;

	if(!thePlayer.GetInventory().IsIdValid(thePlayer.GetInventory().GetItemFromSlot('r_weapon')))
	{
		GMTestReport(false, "HORSE-01 (" + label + "): no sword in hand");
		return;
	}
	mgr = GMTestHorseCombatManager();
	if(!mgr)
	{
		mgr = new W3VehicleCombatManager in theGame;
		mgr.GMTestHorseSetRider(thePlayer);
		made = true;
	}
	st = (W3VehicleCombatManagerStateSwordAttack)mgr.GetState('SwordAttack');
	if(!st)
	{
		GMTestReport(false, "HORSE-01 (" + label + "): no SwordAttack state");
		return;
	}
	a = GMTestHorseSpawn(3, 0);
	b = GMTestHorseSpawn(4, 1);
	if(!a || !b)
	{
		GMTestReport(false, "HORSE-01 (" + label + "): the dummies did not spawn");
		return;
	}
	weapon = GMTestHorseWeaponDamage();
	probes = GMTestProbes();
	thePlayer.GMTestSetProbes(true);
	LogChannel('GMTest', "INFO HORSE-01 (" + label + "): weapon damage " + NoTrailZeros(weapon) + ", dummy stamina "
		+ NoTrailZeros(a.GetStat(BCS_Stamina)) + " of " + NoTrailZeros(a.GetStatMax(BCS_Stamina)));
	ents.PushBack(a);
	for(s = 0; s <= 4; s += 1)
	{
		sp = s;
		staminaBefore = a.GetStat(BCS_Stamina);
		thePlayer.GMTestHorseRecord(true);
		st.GMTestHorseDeal(ents, sp);
		thePlayer.GMTestHorseRecord(false);
		if(thePlayer.gmTestHorseHits.Size() != 1)
		{
			GMTestReport(false, "HORSE-01 (" + label + ") speed " + s + ": " + thePlayer.gmTestHorseHits.Size() + " hits recorded, 1 expected");
			continue;
		}
		hit = thePlayer.gmTestHorseHits[0];
		GMTestReport(GMTestHorseRatioOk(hit, sp) && !hit.direct && hit.knockdown == (s >= 4) && GMTestHorseInitOk(hit, weapon),
			"HORSE-01 (" + label + ") speed " + s + ": the weapon's damage x" + NoTrailZeros(1 + sp / 4.0) + ", no direct damage, knockdown "
			+ (s >= 4) + ": " + GMTestHorseHitText(hit));
		GMTestReport(a.GetStat(BCS_Stamina) >= staminaBefore - 0.5,
			"HORSE-01 (" + label + ") speed " + s + ": the enemy's stamina not drained (" + NoTrailZeros(staminaBefore) + " -> "
			+ NoTrailZeros(a.GetStat(BCS_Stamina)) + ")");
	}

	// DH1 (a): two enemies in one swing at full gallop, each the weapon's damage x2.
	ents.PushBack(b);
	thePlayer.GMTestHorseRecord(true);
	st.GMTestHorseDeal(ents, 4);
	thePlayer.GMTestHorseRecord(false);
	if(thePlayer.gmTestHorseHits.Size() != 2)
	{
		GMTestReport(false, "HORSE-01 DH1 (" + label + "): " + thePlayer.gmTestHorseHits.Size() + " hits recorded, 2 expected");
	}
	else
	{
		hit = thePlayer.gmTestHorseHits[0];
		hitB = thePlayer.gmTestHorseHits[1];
		ok = hit.victim == a && hitB.victim == b;
		ok = ok && GMTestHorseRatioOk(hit, 4) && GMTestHorseRatioOk(hitB, 4);
		ok = ok && GMTestHorseInitOk(hit, weapon) && GMTestHorseInitOk(hitB, weapon);
		GMTestReport(ok, "HORSE-01 DH1 (" + label + "): two enemies in one swing at full gallop, each the weapon's damage x2: first "
			+ GMTestHorseHitText(hit) + "; second " + GMTestHorseHitText(hitB));
	}
	thePlayer.GMTestSetProbes(probes);
	a.Destroy();
	b.Destroy();
	if(made)
		delete mgr;
}

exec function gmtest_horse01()
{
	var label : string;

	thePlayer.GMTestCount(true, true);
	if(GMTestHorseCombatManager())
		label = "on horseback";
	else
		label = "on foot";
	GMTestHorse01Hits(label);
	LogChannel('GMTest', "SUMMARY horse01: " + thePlayer.gmTestPassed + " passed, " + thePlayer.gmTestFailed + " failed");
}

@addField(CR4Player)
var gmTestHorseSwing : array<CNewNPC>;
@addField(CR4Player)
var gmTestHorseSwingStam : array<float>;

@addMethod(CR4Player)
function GMTestHorseSwingSet(npcs : array<CNewNPC>, stam : array<float>)
{
	gmTestHorseSwing = npcs;
	gmTestHorseSwingStam = stam;
}

exec function gmtest_horse01_swing_a()
{
	var mgr : W3VehicleCombatManager;
	var npcs : array<CNewNPC>;
	var stam : array<float>;
	var i : int;
	var act : SInputAction;

	mgr = GMTestHorseCombatManager();
	if(!mgr)
	{
		LogChannel('GMTest', "FAIL HORSE-01 swing: not on a horse");
		return;
	}
	npcs.PushBack(GMTestHorseSpawn(0.3, 1.8));
	npcs.PushBack(GMTestHorseSpawn(0.3, -1.8));
	for(i = 0; i < npcs.Size(); i += 1)
		stam.PushBack(npcs[i].GetStat(BCS_Stamina));
	thePlayer.GMTestHorseSwingSet(npcs, stam);
	thePlayer.GainStat(BCS_Stamina, thePlayer.GetStatMax(BCS_Stamina));
	thePlayer.GMTestSetProbes(true);
	thePlayer.GMTestHorseRecord(true);
	act.aName = 'VehicleAttack';
	act.value = 1;
	act.lastFrameValue = 0;
	mgr.OnAttack(act);
	LogChannel('GMTest', "INFO HORSE-01 swing: attack pressed, combat manager in " + mgr.GMTestStateName() + ", sword ready "
		+ thePlayer.GetWeaponHolster().IsMeleeWeaponReady());
}

exec function gmtest_horse01_swing_b()
{
	var i, j, n : int;
	var hit : SGMTestHorseHit;
	var npc : CNewNPC;
	var speed : float;

	thePlayer.GMTestCount(true, true);
	thePlayer.GMTestHorseRecord(false);
	for(i = 0; i < thePlayer.gmTestHorseSpeeds.Size(); i += 1)
		LogChannel('GMTest', "INFO HORSE-01 swing: hit function called at speed " + NoTrailZeros(thePlayer.gmTestHorseSpeeds[i]));
	if(thePlayer.gmTestHorseSpeeds.Size() > 0)
		speed = thePlayer.gmTestHorseSpeeds[0];
	for(i = 0; i < thePlayer.gmTestHorseHits.Size(); i += 1)
	{
		hit = thePlayer.gmTestHorseHits[i];
		for(j = 0; j < thePlayer.gmTestHorseSwing.Size(); j += 1)
		{
			npc = thePlayer.gmTestHorseSwing[j];
			if(hit.victim == npc)
			{
				n += 1;
				GMTestReport(GMTestHorseRatioOk(hit, speed) && !hit.direct && hit.knockdown == (speed >= 4),
					"HORSE-01 real swing (speed " + NoTrailZeros(speed) + "): " + GMTestHorseHitText(hit));
				GMTestReport(npc.GetStat(BCS_Stamina) >= thePlayer.gmTestHorseSwingStam[j] - 0.5,
					"HORSE-01 real swing: the enemy's stamina not drained (" + NoTrailZeros(thePlayer.gmTestHorseSwingStam[j]) + " -> "
					+ NoTrailZeros(npc.GetStat(BCS_Stamina)) + ")");
			}
		}
	}
	GMTestReport(n > 0, "HORSE-01 real swing hit a dummy (" + n + " hits)");
	for(j = 0; j < thePlayer.gmTestHorseSwing.Size(); j += 1)
		if(thePlayer.gmTestHorseSwing[j])
			thePlayer.gmTestHorseSwing[j].Destroy();
	thePlayer.GMTestSetProbes(false);
	LogChannel('GMTest', "SUMMARY horse01_swing: " + thePlayer.gmTestPassed + " passed, " + thePlayer.gmTestFailed + " failed");
}

// ---- HORSE-02: horse Axii ----
// The horse Axii key is read through GMHorseAxiiHeld() (horse/horseAxii.ws); a test wrapper holds it while
// gmTestHorseAxiiHold is set. A wrapper on the state's drain records each 0.1 s tick (time, stamina and adrenaline
// before it, the cost), which also shows that the replaced entry function StartCastingSign runs (PH2).
//   gmtest_horse02_a(stamina, adrenaline, perk, hold)  on Roach: Axii selected, Adrenaline Burst of the tree in force
//                                  (classic perk_10, new tree perk_42) equipped or not, stamina and adrenaline set
//                                  (regen paused 30 s), the key held or not, then the horse cast pressed
//   gmtest_horse02_b(expect, release)  what happened since: 0 refused, 1 running (held), 2 ended at no resources,
//                                  3 running on adrenaline (Adrenaline Burst, stamina spent), 4 refused by
//                                  Axii's own cost; release lets the key go
//   gmtest_horse02_threat(n)       n hostile frozen dummies 4 m ahead (Roach's panic rises), gmtest_horse02_clear()

@addField(CR4Player)
var gmTestHorseAxiiHold : bool;
@addField(CR4Player)
var gmTestHorseAxiiTicks : int;
@addField(CR4Player)
var gmTestHorseAxiiPaid : float;
@addField(CR4Player)
var gmTestHorseAxiiFirst : float;		// engine time of the first tick
@addField(CR4Player)
var gmTestHorseAxiiLast : float;
@addField(CR4Player)
var gmTestHorseAxiiStam0 : float;		// stamina before the first tick's drain
@addField(CR4Player)
var gmTestHorseAxiiFocus0 : float;
@addField(CR4Player)
var gmTestHorseAxiiFocusDrop : int;	// ticks that took adrenaline
@addField(CR4Player)
var gmTestHorseAxiiStart : array<float>;	// stamina, adrenaline, time, panic at the press
@addField(CR4Player)
var gmTestHorseThreats : array<CNewNPC>;
@addField(CR4Player)
var gmTestHorseAxiiArmed : bool;		// set at the press: the next CastSign is recorded
@addField(CR4Player)
var gmTestHorseAxiiCasts : int;		// CastSign calls since the press that cast the sign
@addField(CR4Player)
var gmTestHorseAxiiFailed : int;		// and those that did not

@addMethod(CR4Player)
function GMTestHorseAxiiReset(hold : bool, stam : float, focus : float, panic : float)
{
	gmTestHorseAxiiHold = hold;
	gmTestHorseAxiiTicks = 0;
	gmTestHorseAxiiPaid = 0;
	gmTestHorseAxiiFocusDrop = 0;
	gmTestHorseAxiiStam0 = 0;
	gmTestHorseAxiiArmed = true;
	gmTestHorseAxiiCasts = 0;
	gmTestHorseAxiiFailed = 0;
	gmTestHorseAxiiStart.Clear();
	gmTestHorseAxiiStart.PushBack(stam);
	gmTestHorseAxiiStart.PushBack(focus);
	gmTestHorseAxiiStart.PushBack(theGame.GetEngineTimeAsSeconds());
	gmTestHorseAxiiStart.PushBack(panic);
}

@addMethod(CR4Player)
function GMTestHorseAxiiSetHold(hold : bool)
{
	gmTestHorseAxiiHold = hold;
}

@addMethod(CR4Player)
function GMTestHorseAxiiTick(cost : float, focusBefore : float, focusAfter : float)
{
	if(gmTestHorseAxiiTicks == 0)
	{
		gmTestHorseAxiiFirst = theGame.GetEngineTimeAsSeconds();
		gmTestHorseAxiiFocus0 = focusBefore;
	}
	gmTestHorseAxiiTicks += 1;
	gmTestHorseAxiiPaid += cost;
	gmTestHorseAxiiLast = theGame.GetEngineTimeAsSeconds();
	if(focusAfter < focusBefore)
		gmTestHorseAxiiFocusDrop += 1;
}

@addMethod(CR4Player)
function GMTestHorseAxiiCast(ok : bool)
{
	if(ok)
		gmTestHorseAxiiCasts += 1;
	else
		gmTestHorseAxiiFailed += 1;
}

// The sign cast the horse's CastSign state makes (W3PlayerWitcher.CastSign): whether horse Axii was cast at all.
@wrapMethod(W3PlayerWitcher)
function CastSign( optional skipCastingAnimation : bool ) : bool
{
	var ok : bool;

	ok = wrappedMethod(skipCastingAnimation);
	if(gmTestHorseAxiiArmed && IsUsingHorse())
		GMTestHorseAxiiCast(ok);
	return ok;
}

@addMethod(CR4Player)
function GMTestHorseAxiiSetStam0(s : float)
{
	gmTestHorseAxiiStam0 = s;
}

@addMethod(CR4Player)
function GMTestHorseThreatsSet(npcs : array<CNewNPC>)
{
	gmTestHorseThreats = npcs;
}

@wrapMethod
function GMHorseAxiiHeld() : bool
{
	var held : bool;

	held = wrappedMethod();
	if(thePlayer.gmTestHorseAxiiHold)
		return true;
	return held;
}

@wrapMethod(W3VehicleCombatManagerStateCastSign)
function GMDrainResourcesForAxii(cost : float)
{
	var focusBefore : float;

	focusBefore = thePlayer.GetStat(BCS_Focus);
	if(thePlayer.gmTestHorseAxiiTicks == 0)
		thePlayer.GMTestHorseAxiiSetStam0(thePlayer.GetStat(BCS_Stamina));
	wrappedMethod(cost);
	thePlayer.GMTestHorseAxiiTick(cost, focusBefore, thePlayer.GetStat(BCS_Focus));
}

@addMethod(W3VehicleCombatManager)
event OnCastSign(action : SInputAction) {}

// Adrenaline Burst of the tree in force: classic perk_10, new tree perk_42 (the other tree's taken off).
function GMTestHorseBurst(on : bool) : ESkill
{
	var w : W3PlayerWitcher;
	var s, other : ESkill;

	w = GetWitcherPlayer();
	if(GMIsClassicProfileInForce())
	{
		s = S_Perk_10;
		other = S_Perk_42;
	}
	else
	{
		s = S_Perk_42;
		other = S_Perk_10;
	}
	if(w.IsSkillEquipped(other))
		w.UnequipSkill(w.GetSkillSlotID(other));
	if(on)
	{
		if(!w.HasLearnedSkill(s))
			w.AddSkill(s);
		if(!w.IsSkillEquipped(s))
			w.EquipSkill(s, w.GetFreeSkillSlot());
	}
	else if(w.IsSkillEquipped(s))
	{
		w.UnequipSkill(w.GetSkillSlotID(s));
	}
	return s;
}

function GMTestHorsePanic() : float
{
	var comp : W3HorseComponent;

	comp = thePlayer.GetUsedHorseComponent();
	if(!comp)
		return -1;
	return comp.GetPanicPercent();
}

exec function gmtest_horse02_a(stamina : float, adrenaline : float, perk : bool, hold : bool)
{
	var mgr : W3VehicleCombatManager;
	var w : W3PlayerWitcher;
	var a : SInputAction;
	var s : ESkill;

	w = GetWitcherPlayer();
	mgr = GMTestHorseCombatManager();
	if(!mgr)
	{
		LogChannel('GMTest', "FAIL HORSE-02: not on a horse");
		return;
	}
	w.SetEquippedSign(ST_Axii);
	s = GMTestHorseBurst(perk);
	w.DrainFocus(w.GetStat(BCS_Focus));
	if(adrenaline > 0)
		w.GainStat(BCS_Focus, adrenaline);
	w.DrainStamina(ESAT_FixedValue, w.GetStatMax(BCS_Stamina), 30);
	w.GainStat(BCS_Stamina, stamina);
	w.GMTestHorseAxiiReset(hold, w.GetStat(BCS_Stamina), w.GetStat(BCS_Focus), GMTestHorsePanic());
	a.aName = 'VehicleCastSign';
	a.value = 1;
	a.lastFrameValue = 0;
	mgr.OnCastSign(a);
	LogChannel('GMTest', "INFO HORSE-02 pressed: stamina " + NoTrailZeros(w.GetStat(BCS_Stamina)) + " of " + NoTrailZeros(w.GetStatMax(BCS_Stamina))
		+ ", adrenaline " + NoTrailZeros(w.GetStat(BCS_Focus)) + " of " + NoTrailZeros(w.GetStatMax(BCS_Focus)) + ", " + s + " usable " + w.CanUseSkill(s)
		+ ", held " + hold + ", combat manager in " + mgr.GMTestStateName() + ", panic " + NoTrailZeros(GMTestHorsePanic()) + ", sign " + w.GetEquippedSign());
}

exec function gmtest_horse02_b(expect : int, release : bool)
{
	var mgr : W3VehicleCombatManager;
	var w : W3PlayerWitcher;
	var horse : CActor;
	var stateName : name;
	var ticks : int;
	var stam, focus, elapsed, rate, interval, expected : float;
	var confused, inCast : bool;
	var label : string;

	thePlayer.GMTestCount(true, true);
	w = GetWitcherPlayer();
	mgr = GMTestHorseCombatManager();
	if(mgr)
		stateName = mgr.GMTestStateName();
	inCast = stateName == 'CastSign';
	horse = (CActor)thePlayer.GetUsedVehicle();
	if(horse)
		confused = horse.HasBuff(EET_Confusion);
	ticks = w.gmTestHorseAxiiTicks;
	stam = w.GetStat(BCS_Stamina);
	focus = w.GetStat(BCS_Focus);
	if(ticks > 1)
	{
		elapsed = w.gmTestHorseAxiiLast - w.gmTestHorseAxiiFirst;
		interval = elapsed / (ticks - 1);
		rate = w.gmTestHorseAxiiPaid / (elapsed + interval);
	}
	label = "casts " + w.gmTestHorseAxiiCasts + " (failed " + w.gmTestHorseAxiiFailed + "); start stamina " + NoTrailZeros(w.gmTestHorseAxiiStart[0]) + ", adrenaline " + NoTrailZeros(w.gmTestHorseAxiiStart[1]) + "; " + ticks + " ticks, "
		+ NoTrailZeros(w.gmTestHorseAxiiPaid) + " paid, a tick every " + NoTrailZeros(interval) + " s (" + NoTrailZeros(rate) + " a second); stamina "
		+ NoTrailZeros(w.gmTestHorseAxiiStam0) + " at the first tick, " + NoTrailZeros(stam) + " now; adrenaline " + NoTrailZeros(focus) + " (" + w.gmTestHorseAxiiFocusDrop
		+ " ticks paid with it); state " + stateName + ", horse confused " + confused + ", panic " + NoTrailZeros(w.gmTestHorseAxiiStart[3]) + " -> " + NoTrailZeros(GMTestHorsePanic());
	LogChannel('GMTest', "INFO HORSE-02 " + label);
	switch(expect)
	{
		case 0:
			GMTestReport(ticks == 0 && !inCast && w.gmTestHorseAxiiCasts == 0, "HORSE-02 horse Axii refused (no sign cast): " + label);
			break;
		case 1:
			// held: a tick every 0.1 s at 0.5 stamina, no regen in between (stamina = stamina at the first tick - 0.5 x ticks)
			expected = w.gmTestHorseAxiiStam0 - 0.5 * ticks;
			GMTestReport(w.gmTestHorseAxiiCasts == 1 && ticks >= 5 && inCast && AbsF(w.gmTestHorseAxiiPaid - 0.5 * ticks) < 0.01 && interval >= 0.08 && interval <= 0.15
				&& stam <= expected + 0.6 && stam >= expected - 0.6 && confused,
				"HORSE-02 horse Axii held: 0.5 stamina every 0.1 s, no regen, the horse confused (stamina " + NoTrailZeros(expected) + " expected): " + label);
			break;
		case 2:
			GMTestReport(ticks >= 1 && !inCast && stam < 0.5 && (w.gmTestHorseAxiiStart[1] < 1 || focus < w.gmTestHorseAxiiStart[1]),
				"HORSE-02 horse Axii ended when its resources ran out: " + label);
			break;
		case 4:
			GMTestReport(ticks == 0 && !inCast && w.gmTestHorseAxiiCasts == 0 && w.gmTestHorseAxiiFailed >= 1,
				"HORSE-02 horse Axii refused by Axii's own cost (the threshold met, the cast failed): " + label);
			break;
		case 3:
			GMTestReport(ticks >= 5 && inCast && stam < 0.5 && w.gmTestHorseAxiiFocusDrop >= 1 && focus < w.gmTestHorseAxiiFocus0,
				"HORSE-02 horse Axii held on adrenaline once the stamina ran out (Adrenaline Burst): " + label);
			break;
	}
	if(release)
		w.GMTestHorseAxiiSetHold(false);
	LogChannel('GMTest', "SUMMARY horse02: " + thePlayer.gmTestPassed + " passed, " + thePlayer.gmTestFailed + " failed");
}

exec function gmtest_horse02_threat(n : int)
{
	var npcs : array<CNewNPC>;
	var i : int;

	for(i = 0; i < n; i += 1)
		npcs.PushBack(GMTestHorseSpawn(4, 2 * i - n + 1));
	thePlayer.GMTestHorseThreatsSet(npcs);
	LogChannel('GMTest', "INFO HORSE-02 " + n + " threats spawned, panic " + NoTrailZeros(GMTestHorsePanic()));
}

exec function gmtest_horse02_clear()
{
	var i : int;

	for(i = 0; i < thePlayer.gmTestHorseThreats.Size(); i += 1)
		if(thePlayer.gmTestHorseThreats[i])
			thePlayer.gmTestHorseThreats[i].Destroy();
	GetWitcherPlayer().GMTestHorseAxiiSetHold(false);
	GMTestHorseBurst(false);
	LogChannel('GMTest', "INFO HORSE-02 cleared, panic " + NoTrailZeros(GMTestHorsePanic()));
}

// HORSE-02 in the regression: the CastSign state's resource rule on a combat manager made for the test (no horse,
// no input): the 50 to start, a tick's 0.5, and Adrenaline Burst of the tree in force (classic perk_10, new tree
// perk_42) counting adrenaline as stamina. Stamina, adrenaline and the perk are put back.
@addMethod(W3VehicleCombatManagerStateCastSign)
function GMTestHorseAxiiHas(w : W3PlayerWitcher, cost : float) : bool
{
	witcher = w;
	return GMHasResourcesForAxii(cost);
}

function GMTestHorse02Has(st : W3VehicleCombatManagerStateCastSign, stam : float, focus : float, cost : float) : bool
{
	var w : W3PlayerWitcher;

	w = GetWitcherPlayer();
	w.ForceSetStat(BCS_Stamina, stam);
	w.ForceSetStat(BCS_Focus, focus);
	return st.GMTestHorseAxiiHas(w, cost);
}

function GMTest_horse02_resources()
{
	thePlayer.GMTestCount(true, true);
	GMTestHorse02Resources();
	LogChannel('GMTest', "SUMMARY horse02_resources: " + thePlayer.gmTestPassed + " passed, " + thePlayer.gmTestFailed + " failed");
}

exec function gmtest_horse02_resources()
{
	GMTest_horse02_resources();
}

function GMTestHorse02Resources()
{
	var w : W3PlayerWitcher;
	var mgr : W3VehicleCombatManager;
	var st : W3VehicleCombatManagerStateCastSign;
	var stam, focus : float;
	var s : ESkill;
	var had, eq : bool;
	var a49, a50, b45, c45, c30, d01, d02 : bool;

	w = GetWitcherPlayer();
	mgr = new W3VehicleCombatManager in theGame;
	st = (W3VehicleCombatManagerStateCastSign)mgr.GetState('CastSign');
	if(!st)
	{
		GMTestReport(false, "HORSE-02 resources: no CastSign state");
		return;
	}
	if(GMIsClassicProfileInForce())
		s = S_Perk_10;
	else
		s = S_Perk_42;
	had = w.HasLearnedSkill(s);
	eq = w.IsSkillEquipped(s);
	stam = w.GetStat(BCS_Stamina);
	focus = w.GetStat(BCS_Focus);
	if(eq)
		w.UnequipSkill(w.GetSkillSlotID(s));
	a49 = GMTestHorse02Has(st, 49, 0, GMHorseAxiiCost());
	a50 = GMTestHorse02Has(st, 50, 0, GMHorseAxiiCost());
	b45 = GMTestHorse02Has(st, 45, 1, GMHorseAxiiCost());
	if(!had)
		w.AddSkill(s);
	w.EquipSkill(s, w.GetFreeSkillSlot());
	c45 = GMTestHorse02Has(st, 45, 1, GMHorseAxiiCost());
	c30 = GMTestHorse02Has(st, 10, 1, GMHorseAxiiCost());
	d01 = GMTestHorse02Has(st, 0, 0.016, GMHorseAxiiCost() * 0.01);
	d02 = GMTestHorse02Has(st, 0, 0.013, GMHorseAxiiCost() * 0.01);
	GMTestReport(GMHorseAxiiCost() == 50 && !a49 && a50 && !b45 && c45 && !c30 && d01 && !d02,
		"HORSE-02 horse Axii's resources (" + s + "): 49 stamina " + a49 + ", 50 " + a50 + ", 45 and 1 adrenaline without the perk " + b45
		+ ", with it " + c45 + ", 10 and 1 adrenaline with it " + c30 + "; a tick (0.5) from 0.016 adrenaline " + d01 + ", from 0.013 " + d02
		+ " (expected false, true, false, true, false, true, false)");
	w.UnequipSkill(w.GetSkillSlotID(s));
	if(eq)
		w.EquipSkill(s, w.GetFreeSkillSlot());
	w.ForceSetStat(BCS_Stamina, stam);
	w.ForceSetStat(BCS_Focus, focus);
	delete mgr;
}

// ---- HORSE-03: trampling ----
// The horse component's collision rule called as a collision calls it (ShouldDealDamageToActor), with the speed it reads
// set for the call (GMTrampleSpeed, wrapped) and 5.x's distance-based speed set to a moving horse's (so a build without
// the port shows 5.x's rule); the 1 s per-victim memory cleared first. The probe above records the hit's damage.
//   gmtest_horse03()   on Roach or beside her: a hostile frozen human ahead, a neutral goat; the cases of GMTestHorse03Cases

@addField(CR4Player)
var gmTestTrampleSpeed : float;

@addField(CR4Player)
var gmTestTrampleRider : bool;

@addMethod(CR4Player)
function GMTestSetTrampleSpeed(speed : float)
{
	gmTestTrampleSpeed = speed;
}

@addMethod(CR4Player)
function GMTestSetTrampleRider(on : bool)
{
	gmTestTrampleRider = on;
}

// The regression's checks run with Roach riderless: Geralt stands in as her rider for the collision rule.
@wrapMethod(W3HorseComponent)
function GetCurrentUser() : CActor
{
	var u : CActor;

	u = wrappedMethod();
	if(!u && thePlayer.gmTestTrampleRider)
		return thePlayer;
	return u;
}

// The speed trampling reads: the test's while it sets one (above 0).
@wrapMethod(W3HorseComponent)
function GMTrampleSpeed() : float
{
	var speed : float;

	speed = wrappedMethod();
	if(thePlayer.gmTestTrampleSpeed > 0)
		return thePlayer.gmTestTrampleSpeed;
	return speed;
}

@addMethod(W3HorseComponent)
function GMTestTrample(victim : CActor, side : bool, speed : float)
{
	collidedActors.Clear();
	thePlayer.GMTestSetTrampleSpeed(speed);
	SetDistanceBasedSpeed(1.0);
	ShouldDealDamageToActor(victim, side);
	thePlayer.GMTestSetTrampleSpeed(0);
	SetDistanceBasedSpeed(0);
	collidedActors.Clear();
}

function GMTestHorse03Spawn(path : string, forward : float, right : float, hostile : bool) : CNewNPC
{
	var template : CEntityTemplate;
	var npc : CNewNPC;
	var pos : Vector;

	template = (CEntityTemplate)LoadResource(path, true);
	pos = thePlayer.GetWorldPosition() + thePlayer.GetHeadingVector() * forward + thePlayer.GetWorldRight() * right;
	npc = (CNewNPC)theGame.CreateEntity(template, pos, VecToRotation(thePlayer.GetWorldPosition() - pos));
	if(!npc)
		return NULL;
	if(hostile)
		npc.SetTemporaryAttitudeGroup('hostile_to_player', AGP_Default);
	npc.SetImmortalityMode(AIM_Immortal, AIC_Default, true);
	npc.SetAnimationSpeedMultiplier(0.001);
	return npc;
}

// One collision: hit expected or not; a hit carries 50 x speed physical and no force damage. (The horse weapon adds
// nothing to a ridden horse's hit: the attack reads the weapon from the attacker's inventory, the rider's, which does
// not hold it; seen 2026-11-03, logged as "weapon".)
function GMTestHorse03Case(comp : W3HorseComponent, victim : CActor, side : bool, speed : float, expectHit : bool, label : string)
{
	var hit : SGMTestHorseHit;
	var n : int;
	var ok : bool;
	var text : string;

	thePlayer.GMTestHorseRecord(true);
	comp.GMTestTrample(victim, side, speed);
	thePlayer.GMTestHorseRecord(false);
	n = thePlayer.gmTestHorseHits.Size();
	if(n > 0)
	{
		hit = thePlayer.gmTestHorseHits[0];
		text = "; hit: weapon " + NoTrailZeros(hit.initSum) + ", physical added " + NoTrailZeros(hit.phys) + ", force " + hit.force + ", received " + NoTrailZeros(hit.finalSum);
	}
	if(expectHit)
		ok = n == 1 && hit.victim == victim && !hit.force && hit.phys >= 45 * speed - 0.01 && hit.phys <= 55 * speed + 0.01;
	else
		ok = n == 0;
	GMTestReport(ok, "HORSE-03 trampling " + label + " at speed " + NoTrailZeros(speed) + ": " + n + " hits (expected " + expectHit + ")" + text);
}

function GMTestHorse03Cases(comp : W3HorseComponent, label : string)
{
	var human, goat : CNewNPC;
	var probes : bool;

	human = GMTestHorse03Spawn(GMTestDummyTemplate("human"), 3, 0, true);
	goat = GMTestHorse03Spawn("characters\npc_entities\animals\goat.w2ent", 4, 2, false);
	if(!human || !goat)
	{
		GMTestReport(false, "HORSE-03 (" + label + "): the samples did not spawn");
		return;
	}
	probes = GMTestProbes();
	thePlayer.GMTestSetProbes(true);
	LogChannel('GMTest', "INFO HORSE-03 (" + label + "): rider " + (bool)comp.GetCurrentUser() + ", goat is an animal " + goat.IsAnimal()
		+ ", attitude to the goat " + GetAttitudeBetween(thePlayer, goat));
	GMTestHorse03Case(comp, human, false, 2, false, "(" + label + ") a hostile head-on");
	GMTestHorse03Case(comp, human, false, 3, true, "(" + label + ") a hostile head-on");
	GMTestHorse03Case(comp, human, false, 4, true, "(" + label + ") a hostile head-on");
	GMTestHorse03Case(comp, human, true, 4, false, "(" + label + ") a standing hostile from the side");
	GMTestHorse03Case(comp, goat, false, 4, false, "(" + label + ") a neutral goat head-on");
	human.AddEffectDefault(EET_Knockdown, thePlayer, "HORSE-03 test");
	GMTestHorse03Case(comp, human, true, 4, human.HasBuff(EET_Knockdown), "(" + label + ") a knocked-down hostile (" + human.HasBuff(EET_Knockdown) + ") from the side");
	thePlayer.GMTestSetProbes(probes);
	human.Destroy();
	goat.Destroy();
}

// Ridden: Roach's own component; riderless (the regression): Geralt stands in as her rider for the call.
function GMTestHorse03(label : string)
{
	var comp : W3HorseComponent;
	var horse : CNewNPC;

	comp = thePlayer.GetUsedHorseComponent();
	if(!comp)
	{
		horse = thePlayer.GetHorseWithInventory();
		if(horse)
			comp = horse.GetHorseComponent();
		label = label + ", riderless, Geralt as her rider";
		thePlayer.GMTestSetTrampleRider(true);
	}
	if(!comp)
		GMTestReport(false, "HORSE-03: no horse");
	else
		GMTestHorse03Cases(comp, label);
	thePlayer.GMTestSetTrampleRider(false);
}

exec function gmtest_horse03()
{
	thePlayer.GMTestCount(true, true);
	GMTestHorse03("ridden");
	LogChannel('GMTest', "SUMMARY horse03: " + thePlayer.gmTestPassed + " passed, " + thePlayer.gmTestFailed + " failed");
}

// PH6: 5.x's horse kick and rearing (the HorseKick key on Roach) deal no damage: frozen hostile humans 1.5 m ahead and
// behind Roach, the key's event called on her Exploration state, then every hit recorded for the next seconds and the
// humans' health read.
//   gmtest_horse03_kick_a()   on Roach: spawns the humans, presses the kick
//   gmtest_horse03_kick_b()   a second or two later: no hit, health unchanged
@addField(CR4Player)
var gmTestHorseKick : array<CNewNPC>;
@addField(CR4Player)
var gmTestHorseKickHp : array<float>;

@addMethod(CR4Player)
function GMTestHorseKickSet(npcs : array<CNewNPC>, hp : array<float>)
{
	gmTestHorseKick = npcs;
	gmTestHorseKickHp = hp;
}

exec function gmtest_horse03_kick_a()
{
	var comp : W3HorseComponent;
	var st : W3HorseComponentStateExploration;
	var npcs : array<CNewNPC>;
	var hp : array<float>;
	var i : int;
	var a : SInputAction;

	comp = thePlayer.GetUsedHorseComponent();
	if(comp)
		st = (W3HorseComponentStateExploration)comp.GetState('Exploration');
	if(!st)
	{
		LogChannel('GMTest', "FAIL HORSE-03 kick: not on Roach in her Exploration state");
		return;
	}
	npcs.PushBack(GMTestHorse03Spawn(GMTestDummyTemplate("human"), 1.5, 0, true));
	npcs.PushBack(GMTestHorse03Spawn(GMTestDummyTemplate("human"), -2.5, 0, true));
	for(i = 0; i < npcs.Size(); i += 1)
		hp.PushBack(npcs[i].GetHealth());
	thePlayer.GMTestHorseKickSet(npcs, hp);
	thePlayer.GMTestSetProbes(true);
	thePlayer.GMTestHorseRecord(true);
	a.aName = 'HorseKick';
	a.value = 1;
	a.lastFrameValue = 0;
	st.OnHorseKick(a);
	LogChannel('GMTest', "INFO HORSE-03 kick pressed, horse state " + comp.GetCurrentStateName());
}

exec function gmtest_horse03_kick_b()
{
	var i, n : int;
	var npc : CNewNPC;
	var same : bool;
	var text : string;

	thePlayer.GMTestCount(true, true);
	thePlayer.GMTestHorseRecord(false);
	same = true;
	for(i = 0; i < thePlayer.gmTestHorseKick.Size(); i += 1)
	{
		npc = thePlayer.gmTestHorseKick[i];
		text += " " + NoTrailZeros(thePlayer.gmTestHorseKickHp[i]) + " -> " + NoTrailZeros(npc.GetHealth()) + ";";
		if(npc.GetHealth() < thePlayer.gmTestHorseKickHp[i])
			same = false;
	}
	n = thePlayer.gmTestHorseHits.Size();
	GMTestReport(n == 0 && same, "HORSE-03 PH6: the horse kick or rearing deals no damage: " + n + " hits, health" + text);
	for(i = 0; i < thePlayer.gmTestHorseKick.Size(); i += 1)
		if(thePlayer.gmTestHorseKick[i])
			thePlayer.gmTestHorseKick[i].Destroy();
	thePlayer.GMTestSetProbes(false);
	LogChannel('GMTest', "SUMMARY horse03_kick: " + thePlayer.gmTestPassed + " passed, " + thePlayer.gmTestFailed + " failed");
}

// ---- HORSE audit F5, F6 (slice H4): the regression's checks of the drain, the trample's attacker and the kick sound ----

// F5: horse Axii's drain on a test CastSign state: at 0.3 stamina and 1 adrenaline a 0.5 tick takes the stamina to 0
// and, with the tree's Adrenaline Burst, the rest from adrenaline at max adrenaline / max stamina (0.006 at 100 and
// 3); without the perk the adrenaline stays. Stamina, adrenaline and the perk are put back.
function GMTestHorse02Drain()
{
	var w : W3PlayerWitcher;
	var mgr : W3VehicleCombatManager;
	var st : W3VehicleCombatManagerStateCastSign;
	var stam, focus, want, s0, f0, s1, f1 : float;
	var s : ESkill;
	var had, eq : bool;

	w = GetWitcherPlayer();
	mgr = new W3VehicleCombatManager in theGame;
	st = (W3VehicleCombatManagerStateCastSign)mgr.GetState('CastSign');
	if(!st)
	{
		GMTestReport(false, "HORSE-02 drain: no CastSign state");
		return;
	}
	st.GMTestHorseAxiiHas(w, 0);
	if(GMIsClassicProfileInForce())
		s = S_Perk_10;
	else
		s = S_Perk_42;
	had = w.HasLearnedSkill(s);
	eq = w.IsSkillEquipped(s);
	stam = w.GetStat(BCS_Stamina);
	focus = w.GetStat(BCS_Focus);
	if(eq)
		w.UnequipSkill(w.GetSkillSlotID(s));
	w.ForceSetStat(BCS_Stamina, 0.3);
	w.ForceSetStat(BCS_Focus, 1);
	st.GMDrainResourcesForAxii(GMHorseAxiiCost() * 0.01);
	s0 = w.GetStat(BCS_Stamina);
	f0 = w.GetStat(BCS_Focus);
	if(!had)
		w.AddSkill(s);
	w.EquipSkill(s, w.GetFreeSkillSlot());
	w.ForceSetStat(BCS_Stamina, 0.3);
	w.ForceSetStat(BCS_Focus, 1);
	st.GMDrainResourcesForAxii(GMHorseAxiiCost() * 0.01);
	s1 = w.GetStat(BCS_Stamina);
	f1 = w.GetStat(BCS_Focus);
	want = 1 - (GMHorseAxiiCost() * 0.01 - 0.3) * w.GetStatMax(BCS_Focus) / w.GetStatMax(BCS_Stamina);
	GMTestReport(s0 < 0.001 && AbsF(f0 - 1) < 0.0001 && s1 < 0.001 && AbsF(f1 - want) < 0.0001,
		"HORSE-02 drain of a tick at 0.3 stamina and 1 adrenaline (" + s + "): without the perk stamina " + NoTrailZeros(s0) + ", adrenaline " + NoTrailZeros(f0)
		+ " (expected 0, 1); with it " + NoTrailZeros(s1) + ", " + NoTrailZeros(f1) + " (expected 0, " + NoTrailZeros(want) + ")");
	w.UnequipSkill(w.GetSkillSlotID(s));
	if(eq)
		w.EquipSkill(s, w.GetFreeSkillSlot());
	w.ForceSetStat(BCS_Stamina, stam);
	w.ForceSetStat(BCS_Focus, focus);
	delete mgr;
}

exec function gmtest_horse04_drain()
{
	thePlayer.GMTestCount(true, true);
	GMTestHorse02Drain();
	LogChannel('GMTest', "SUMMARY horse04_drain: " + thePlayer.gmTestPassed + " passed, " + thePlayer.gmTestFailed + " failed");
}

@addField(CR4Player)
var gmTestTrampleSounds : int;

@addMethod(CR4Player)
function GMTestTrampleSoundInc(reset : bool)
{
	if(reset)
		gmTestTrampleSounds = 0;
	else
		gmTestTrampleSounds += 1;
}

@wrapMethod(W3HorseComponent)
function GMTrampleKickSound(victim : CActor)
{
	thePlayer.GMTestTrampleSoundInc(false);
	wrappedMethod(victim);
}

// One collision as DealDamageToCollidedActor gets it, with the attacker given and the test's speed.
@addMethod(W3HorseComponent)
function GMTestTrampleDeal(owner : CActor, victim : CActor, side : bool, speed : float)
{
	collidedActors.Clear();
	thePlayer.GMTestSetTrampleSpeed(speed);
	DealDamageToCollidedActor(owner, victim, side);
	thePlayer.GMTestSetTrampleSpeed(0);
	collidedActors.Clear();
}

// The horse's own weapon damage (what a riderless horse's trample carries from it, before the melee roll).
function GMTestHorseOwnWeapon(horse : CNewNPC) : float
{
	var inv : CInventoryComponent;
	var id : SItemUniqueId;
	var types : array<name>;
	var i : int;
	var sum : float;

	inv = horse.GetInventory();
	id = inv.GetItemFromSlot('r_weapon');
	inv.GetWeaponDTNames(id, types);
	for(i = 0; i < types.Size(); i += 1)
		sum += horse.GetTotalWeaponDamage(id, types[i], GetInvalidUniqueId());
	return sum;
}

// F5: who the trample names as attacker. An enemy rider's horse on Geralt (the rider as attacker): no horse-weapon
// damage, 1.32's 50 x speed physical; a riderless horse on Geralt (the horse as attacker): its weapon's damage added.
// F6: 5.x's kick sound only for a living victim; a dead one still takes 1.32's hit. Geralt immortal for the calls,
// his Vitality put back.
function GMTestHorse04Riders(comp : W3HorseComponent, horse : CNewNPC)
{
	var human, dead : CNewNPC;
	var hit : SGMTestHorseHit;
	var vit, weapon : float;
	var probes, ok : bool;
	var n, soundsLive, soundsDead : int;

	human = GMTestHorse03Spawn(GMTestDummyTemplate("human"), 3, 0, true);
	dead = GMTestHorse03Spawn(GMTestDummyTemplate("human"), 4, 2, true);
	if(!human || !dead)
	{
		GMTestReport(false, "HORSE-03 riders: the samples did not spawn");
		return;
	}
	probes = GMTestProbes();
	thePlayer.GMTestSetProbes(true);
	vit = thePlayer.GetStat(BCS_Vitality);
	thePlayer.SetImmortalityMode(AIM_Immortal, AIC_Default, true);
	weapon = GMTestHorseOwnWeapon(horse);

	thePlayer.GMTestHorseRecord(true);
	comp.GMTestTrampleDeal(human, thePlayer, false, 4);
	thePlayer.GMTestHorseRecord(false);
	n = thePlayer.gmTestHorseHits.Size();
	if(n > 0)
		hit = thePlayer.gmTestHorseHits[0];
	ok = n == 1 && hit.initSum == 0 && hit.phys >= 180 - 0.01 && hit.phys <= 220 + 0.01 && !hit.force;
	GMTestReport(ok, "HORSE-03 an enemy rider's horse on Geralt at speed 4 (the rider as attacker): " + n + " hits, horse-weapon part "
		+ NoTrailZeros(hit.initSum) + " (expected 0), physical " + NoTrailZeros(hit.phys) + " (expected 200 within the melee roll), force " + hit.force);
	thePlayer.ForceSetStat(BCS_Vitality, vit);

	thePlayer.GMTestHorseRecord(true);
	comp.GMTestTrampleDeal(horse, thePlayer, false, 4);
	thePlayer.GMTestHorseRecord(false);
	n = thePlayer.gmTestHorseHits.Size();
	if(n > 0)
		hit = thePlayer.gmTestHorseHits[0];
	ok = n == 1 && weapon > 0 && hit.initSum >= weapon * 0.88 && hit.initSum <= weapon * 1.12 && hit.phys >= 180 - 0.01 && hit.phys <= 220 + 0.01 && !hit.force;
	GMTestReport(ok, "HORSE-03 a riderless horse on Geralt at speed 4 (the horse as attacker): " + n + " hits, horse-weapon part "
		+ NoTrailZeros(hit.initSum) + " (her weapon " + NoTrailZeros(weapon) + "), physical " + NoTrailZeros(hit.phys) + ", force " + hit.force);
	thePlayer.ForceSetStat(BCS_Vitality, vit);
	thePlayer.SetImmortalityMode(AIM_None, AIC_Default, true);

	thePlayer.GMTestTrampleSoundInc(true);
	comp.GMTestTrampleDeal(thePlayer, human, false, 4);
	soundsLive = thePlayer.gmTestTrampleSounds;
	dead.SetImmortalityMode(AIM_None, AIC_Default, true);
	dead.Kill('GMTest', true, thePlayer);
	thePlayer.GMTestTrampleSoundInc(true);
	thePlayer.GMTestHorseRecord(true);
	comp.GMTestTrampleDeal(thePlayer, dead, false, 4);
	thePlayer.GMTestHorseRecord(false);
	soundsDead = thePlayer.gmTestTrampleSounds;
	n = thePlayer.gmTestHorseHits.Size();
	GMTestReport(soundsLive == 1 && soundsDead == 0 && !dead.IsAlive() && n == 1,
		"HORSE-03 F6: the kick sound for a living enemy " + soundsLive + " (expected 1), for a dead one " + soundsDead + " (expected 0; dead "
		+ !dead.IsAlive() + ", still hit " + n + " times, 1.32's rule)");
	thePlayer.GMTestSetProbes(probes);
	human.Destroy();
	dead.Destroy();
}

exec function gmtest_horse04_riders()
{
	var horse : CNewNPC;
	var comp : W3HorseComponent;

	thePlayer.GMTestCount(true, true);
	horse = thePlayer.GetHorseWithInventory();
	if(horse)
		comp = horse.GetHorseComponent();
	if(!comp)
		GMTestReport(false, "HORSE-03 riders: no horse");
	else
		GMTestHorse04Riders(comp, horse);
	LogChannel('GMTest', "SUMMARY horse04_riders: " + thePlayer.gmTestPassed + " passed, " + thePlayer.gmTestFailed + " failed");
}
