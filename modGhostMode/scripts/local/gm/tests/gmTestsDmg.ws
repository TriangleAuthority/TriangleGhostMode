// DMG-14 slice 1: the damage probe. Test-only wrappers record each step of a hit as the damage
// manager processes it (raw damage before and after the increase steps, armor points and
// resistance, attack power, the formula's result per damage type, the final damage dealt), so
// every DMG slice can be measured against the formula it ports. They do nothing unless
// GMTestProbes() is on; gmtest_dmg() switches them on for its hits.
// See docs/features/dmg.md.

struct SGMTestDmgStep
{
	var dmgType : name;
	var rawIn : float;		// the damage type's value as CalculateDamage receives it
	var pts : float;		// armor and resistance points (GetDamageResists)
	var perc : float;		// resistance (GetDamageResists)
	var base : float;		// attack power (GetAttackersPowerMod)
	var mult : float;
	var add : float;
	var result : float;		// CalculateDamage's result
	var hitsStat : bool;	// the type damages the stat the victim uses
};

@addField(CR4Player)
var gmTestDmgSteps : array<SGMTestDmgStep>;
@addField(CR4Player)
var gmTestDmgRawBefore : float;	// sum of raw damage before ProcessDamageIncrease
@addField(CR4Player)
var gmTestDmgRawAfter : float;	// sum after ProcessDamageIncrease and ProcessNewSkills_Combat
@addField(CR4Player)
var gmTestDmgPts : float;
@addField(CR4Player)
var gmTestDmgPerc : float;
@addField(CR4Player)
var gmTestDmgFinal : float;		// the damage dealt to the victim's vitality or essence
@addField(CR4Player)
var gmTestDmgDealt : bool;
@addField(CR4Player)
var gmTestDmgAnim : EActionHitAnim;	// the hit's animation play type as it is dealt

@addMethod(CR4Player)
function GMTestDmgReset()
{
	gmTestDmgSteps.Clear();
	gmTestDmgRawBefore = 0;
	gmTestDmgRawAfter = 0;
	gmTestDmgPts = 0;
	gmTestDmgPerc = 0;
	gmTestDmgFinal = 0;
	gmTestDmgDealt = false;
}

@addMethod(CR4Player)
function GMTestDmgSetRaw(before : bool, dmgInfos : array<SRawDamage>)
{
	var i : int;
	var sum : float;

	for(i = 0; i < dmgInfos.Size(); i += 1)
		sum += dmgInfos[i].dmgVal;
	if(before)
		gmTestDmgRawBefore = sum;
	else
		gmTestDmgRawAfter = sum;
}

@addMethod(CR4Player)
function GMTestDmgSetResists(pts : float, perc : float)
{
	gmTestDmgPts = pts;
	gmTestDmgPerc = perc;
}

@addMethod(CR4Player)
function GMTestDmgAddStep(dmgInfo : SRawDamage, powerMod : SAbilityAttributeValue, result : float, hitsStat : bool)
{
	var step : SGMTestDmgStep;

	step.dmgType = dmgInfo.dmgType;
	step.rawIn = dmgInfo.dmgVal;
	step.pts = gmTestDmgPts;
	step.perc = gmTestDmgPerc;
	step.base = powerMod.valueBase;
	step.mult = powerMod.valueMultiplicative;
	step.add = powerMod.valueAdditive;
	step.result = result;
	step.hitsStat = hitsStat;
	gmTestDmgSteps.PushBack(step);
}

@addMethod(CR4Player)
function GMTestDmgSetFinal(dealt : float, anim : EActionHitAnim)
{
	gmTestDmgFinal = dealt;
	gmTestDmgAnim = anim;
	gmTestDmgDealt = true;
}

@wrapMethod(W3DamageManagerProcessor)
function ProcessDamageIncrease(out dmgInfos : array< SRawDamage >)
{
	if(GMTestProbes())
		thePlayer.GMTestDmgSetRaw(true, dmgInfos);
	wrappedMethod(dmgInfos);
}

// 5.x runs ProcessNewSkills_Combat right after ProcessDamageIncrease: the raw damage is final here.
@wrapMethod(W3DamageManagerProcessor)
function ProcessNewSkills_Combat(out dmgInfos : array< SRawDamage >)
{
	wrappedMethod(dmgInfos);
	if(GMTestProbes())
		thePlayer.GMTestDmgSetRaw(false, dmgInfos);
}

@wrapMethod(W3DamageManagerProcessor)
function GetDamageResists(dmgType : name, out resistPts : float, out resistPerc : float)
{
	wrappedMethod(dmgType, resistPts, resistPerc);
	if(GMTestProbes())
		thePlayer.GMTestDmgSetResists(resistPts, resistPerc);
}

@wrapMethod(W3DamageManagerProcessor)
function CalculateDamage(dmgInfo : SRawDamage, powerMod : SAbilityAttributeValue) : float
{
	var result : float;

	result = wrappedMethod(dmgInfo, powerMod);
	if(GMTestProbes())
		thePlayer.GMTestDmgAddStep(dmgInfo, powerMod, result, actorVictim && (actorVictim.UsesEssence() && DamageHitsEssence(dmgInfo.dmgType)
			|| !actorVictim.UsesEssence() && DamageHitsVitality(dmgInfo.dmgType)));
	return result;
}

@wrapMethod(W3DamageManagerProcessor)
function ProcessActionDamage_DealDamage()
{
	// a damage type that hits both stats fills both totals: count the one the victim uses
	if(GMTestProbes() && actorVictim)
	{
		if(actorVictim.UsesEssence())
			thePlayer.GMTestDmgSetFinal(action.processedDmg.essenceDamage, action.GetHitAnimationPlayType());
		else
			thePlayer.GMTestDmgSetFinal(action.processedDmg.vitalityDamage, action.GetHitAnimationPlayType());
	}
	wrappedMethod();
}

// What a recorded step should give. mode 0: 5.x's formula; 1: legacy Ghost Mode's; 2: the port as
// it stands (legacy's formula since DMG slice 3a). legacy: Ghost Mode's formula, (raw + base - armor) * mult + add,
// then the resistance; otherwise 5.x's, (raw + base) * mult + add - armor (elemental, fire and frost
// damage skip armor), then the resistance; the player's hits with fists x(1 + 0.05 per level) and
// heavy attacks x1.833 (the cases gmtest_dmg() builds: no fistfight minigame, no allies, no Igni).
function GMTestDmgExpected(step : SGMTestDmgStep, mode : int, playerHeavy : bool, optional playerFists : bool) : float
{
	var dmg : float;
	var skipsArmor, legacy : bool;

	legacy = mode != 0;

	if(legacy)
	{
		dmg = MaxF(0, step.rawIn + step.base - step.pts);
		dmg = MaxF(0, dmg * step.mult + step.add);
	}
	else
	{
		dmg = MaxF(0, (step.rawIn + step.base) * step.mult + step.add);
		skipsArmor = step.dmgType == theGame.params.DAMAGE_NAME_ELEMENTAL || step.dmgType == theGame.params.DAMAGE_NAME_FIRE
			|| step.dmgType == theGame.params.DAMAGE_NAME_FROST;
		if(dmg > 0 && !skipsArmor)
			dmg = MaxF(0, dmg - step.pts);
	}
	if(dmg > 0)
		dmg *= 1 - step.perc;
	if(mode == 0 && playerFists)
		dmg *= 1 + thePlayer.GetLevel() * 0.05;
	if(mode == 0 && playerHeavy)
		dmg *= 1.833;
	return dmg;
}

// finalMult: what the final-damage step multiplies the formula's sum by (the difficulty multiplier
// for a hostile NPC hitting the player; GMTestDmgFinalMult).
function GMTestDmgLogSteps(label : string, playerHeavy : bool, optional playerFists : bool, optional finalMult : float) : bool
{
	var i : int;
	var step : SGMTestDmgStep;
	var expected, legacyDmg, vanillaDmg, sum : float;
	var ok : bool;

	ok = thePlayer.gmTestDmgSteps.Size() > 0;
	LogChannel('GMTest', "INFO " + label + ": raw " + NoTrailZeros(thePlayer.gmTestDmgRawBefore) + " -> "
		+ NoTrailZeros(thePlayer.gmTestDmgRawAfter) + " after the increase steps, final " + NoTrailZeros(thePlayer.gmTestDmgFinal)
		+ (thePlayer.gmTestDmgDealt ? "" : " (not dealt)"));
	for(i = 0; i < thePlayer.gmTestDmgSteps.Size(); i += 1)
	{
		step = thePlayer.gmTestDmgSteps[i];
		expected = GMTestDmgExpected(step, 2, playerHeavy, playerFists);
		legacyDmg = GMTestDmgExpected(step, 1, playerHeavy, playerFists);
		vanillaDmg = GMTestDmgExpected(step, 0, playerHeavy, playerFists);
		if(step.hitsStat)
			sum += step.result;
		LogChannel('GMTest', "INFO   " + step.dmgType + ": raw " + NoTrailZeros(step.rawIn) + ", armor " + NoTrailZeros(step.pts)
			+ ", resistance " + NoTrailZeros(step.perc) + ", attack power base " + NoTrailZeros(step.base) + " mult " + NoTrailZeros(step.mult)
			+ " add " + NoTrailZeros(step.add) + " -> " + NoTrailZeros(step.result) + (step.hitsStat ? "" : " (not this victim's stat)") + " (port " + NoTrailZeros(expected)
			+ ", legacy " + NoTrailZeros(legacyDmg) + ", 5.x " + NoTrailZeros(vanillaDmg) + ")");
		if(AbsF(step.result - expected) > 0.01 + 0.001 * expected)
			ok = false;
	}
	GMTestReport(ok, "DMG-14 probe: " + label + " recorded, each damage type's result matches the port's formula from the recorded inputs");
	if(finalMult == 0)
		finalMult = 1;
	sum *= finalMult;
	if(sum < 1)
		sum = 0;
	GMTestReport(thePlayer.gmTestDmgDealt && AbsF(thePlayer.gmTestDmgFinal - sum) <= 0.01 + 0.001 * sum,
		"DMG-14 probe: " + label + " final damage dealt equals the sum of the formula's results for the victim's stat, x"
		+ NoTrailZeros(finalMult) + " final damage");
	return ok;
}

// The final-damage step's multiplier for a hit of attacker on victim, as far as the probe's hits go:
// the difficulty multiplier when a hostile NPC hits the player.
function GMTestDmgFinalMult(attacker : CActor, victim : CActor) : float
{
	if(attacker != thePlayer && victim == thePlayer && !attacker.IgnoresDifficultySettings() && GetAttitudeBetween(attacker, thePlayer) == AIA_Hostile)
		return CalculateAttributeValue(attacker.GetAttributeValue(theGame.params.DIFFICULTY_DMG_MULTIPLIER));
	return 1;
}

// One scripted hit through the damage manager, built as a real attack builds it (weapon damage from
// the attacker's weapon); cannot be parried or dodged, no hit animation. The victim is healed after.
function GMTestDmgHit(attacker : CActor, victim : CActor, weaponId : SItemUniqueId, attackName : name)
{
	var action : W3Action_Attack;

	thePlayer.GMTestDmgReset();
	action = new W3Action_Attack in theGame.damageMgr;
	action.Init(attacker, victim, NULL, weaponId, attackName, attacker.GetName(), EHRT_Light,
		false, false, attackName, AST_Jab, ASD_UpDown, true, false, false, false);
	action.SetSuppressHitSounds(true);
	action.SetHitAnimationPlayType(EAHA_ForceNo);
	theGame.damageMgr.ProcessAction(action);
	delete action;
	if(victim.UsesVitality())
		victim.ForceSetStat(BCS_Vitality, victim.GetStatMax(BCS_Vitality));
	if(victim.UsesEssence())
		victim.ForceSetStat(BCS_Essence, victim.GetStatMax(BCS_Essence));
}

// The NPC's held weapon (a monster's claws or teeth are a held 'monster_weapon' item), as its real
// attacks use; else its first weapon (a frozen test dummy never draws one); invalid if it has none.
function GMTestNpcWeapon(npc : CActor) : SItemUniqueId
{
	var ids : array<SItemUniqueId>;

	ids = npc.GetInventory().GetHeldWeapons();
	if(ids.Size() > 0)
		return ids[0];
	ids = npc.GetInventory().GetWeapons();
	if(ids.Size() > 0)
		return ids[0];
	return GetInvalidUniqueId();
}

// DMG-14: the probe records a light and a heavy hit of Geralt's on the nearest hostile NPC and a
// light hit of that NPC's on Geralt, and checks that the recorded steps reproduce the damage dealt.
// Scripted hits (the path real hits take). Needs a hostile NPC nearby (spawn one) and Geralt holding
// a sword. Each hit also logs what legacy's formula would give from the same inputs.
exec function gmtest_dmg()
{
	var npc : CActor;
	var weaponId : SItemUniqueId;
	var probes, fists : bool;

	npc = GMTestHostileNpc();
	if(!npc)
	{
		GMTestReport(false, "DMG-14 probe: no hostile NPC nearby (spawn one first)");
		return;
	}
	weaponId = thePlayer.GetInventory().GetItemFromSlot('r_weapon');
	if(!thePlayer.GetInventory().IsIdValid(weaponId))
	{
		GMTestReport(false, "DMG-14 probe: Geralt holds no weapon (draw a sword first)");
		return;
	}
	if(npc == GMTestDummy())
		GMTestDummyFreeze((CNewNPC)npc);	// specters blink even when frozen: back to its place
	fists = thePlayer.IsWeaponHeld('fist');
	probes = GMTestProbes();
	thePlayer.GMTestSetProbes(true);
	LogChannel('GMTest', "INFO victim " + npc.GetDisplayName() + " level " + npc.GetLevel() + ", weapon "
		+ thePlayer.GetInventory().GetItemName(weaponId) + (fists ? " (fists held)" : ""));

	if(fists)
		LogChannel('GMTest', "INFO Geralt holds fists: his hits are skipped (gmtest_draw() draws a sword; vanilla's fist rules, e.g. against specters, are not modelled)");
	else
	{
		GMTestDmgHit(thePlayer, npc, weaponId, 'attack_light');
		GMTestDmgLogSteps("Geralt's light attack", false);
		if(!npc.IsAlive())
		{
			LogChannel('GMTest', "INFO the victim died of the light attack: give it more health (a test dummy with gmtest_dummy_neutral())");
			thePlayer.GMTestSetProbes(probes);
			return;
		}
		GMTestDmgHit(thePlayer, npc, weaponId, 'attack_heavy');
		GMTestDmgLogSteps("Geralt's heavy attack", true);
		if(!npc.IsAlive())
		{
			LogChannel('GMTest', "INFO the victim died of the heavy attack: give it more health (a test dummy with gmtest_dummy_neutral())");
			thePlayer.GMTestSetProbes(probes);
			return;
		}
	}
	GMTestDmgHit(npc, thePlayer, GMTestNpcWeapon(npc), 'attack_light');
	LogChannel('GMTest', "INFO " + npc.GetDisplayName() + "'s weapon " + npc.GetInventory().GetItemName(GMTestNpcWeapon(npc)));
	GMTestDmgLogSteps(npc.GetDisplayName() + "'s light attack on Geralt", false, false, GMTestDmgFinalMult(npc, thePlayer));

	thePlayer.GMTestSetProbes(probes);
}

// One scripted hit of a single damage type and value (no weapon), through the damage manager; the
// probe records it. kind: 0 normal, 1 damage over time, 2 headshot, 3 point resistance ignored, 4 normal
// with the hit animation left to the game (the others force none).
// Returns whether it was a critical hit (crits change attack power: callers that compare attack
// power retry). The victim is healed after.
function GMTestDmgCustom(attacker : CActor, victim : CActor, dmgType : name, value : float, kind : int) : bool
{
	var action : W3Action_Attack;
	var crit : bool;

	thePlayer.GMTestDmgReset();
	if(attacker == thePlayer)
		thePlayer.ForceSetStat(BCS_Focus, 0);	// adrenaline raises attack power in 5.x: start every hit from 0
	action = new W3Action_Attack in theGame.damageMgr;
	action.Init(attacker, victim, NULL, GetInvalidUniqueId(), 'attack_light', attacker.GetName(), EHRT_Light,
		false, false, 'attack_light', AST_Jab, ASD_UpDown, true, false, false, false);
	if(kind == 1)
		action.SetIsDoTDamage(0.1);
	else if(kind == 2)
		action.SetHeadShot();
	else if(kind == 3)
		action.SetPointResistIgnored(true);
	action.AddDamage(dmgType, value);
	action.SetSuppressHitSounds(true);
	if(kind != 4)
		action.SetHitAnimationPlayType(EAHA_ForceNo);
	theGame.damageMgr.ProcessAction(action);
	crit = action.IsCriticalHit();
	delete action;
	if(victim.UsesEssence())
		victim.ForceSetStat(BCS_Essence, victim.GetStatMax(BCS_Essence));
	else
		victim.ForceSetStat(BCS_Vitality, victim.GetStatMax(BCS_Vitality));
	return crit;
}

// The first recorded step, or an empty one (dmgType '') when the hit recorded none.
function GMTestDmgStep0() : SGMTestDmgStep
{
	var empty : SGMTestDmgStep;

	if(thePlayer.gmTestDmgSteps.Size() > 0)
		return thePlayer.gmTestDmgSteps[0];
	return empty;
}

function GMTestDmgNear(a : float, b : float) : bool
{
	return AbsF(a - b) <= 0.01 + 0.001 * AbsF(b);
}

function GMTestDmgLogStep(label : string, step : SGMTestDmgStep)
{
	LogChannel('GMTest', "INFO " + label + ": " + step.dmgType + " raw " + NoTrailZeros(step.rawIn) + ", armor " + NoTrailZeros(step.pts)
		+ ", resistance " + NoTrailZeros(step.perc) + ", attack power base " + NoTrailZeros(step.base) + " mult " + NoTrailZeros(step.mult)
		+ " add " + NoTrailZeros(step.add) + " -> " + NoTrailZeros(step.result));
}

// The attack power multiplier of Geralt's light attack on npc as the action gives it, before the
// damage manager adds anything (adrenaline at 0, as GMTestDmgCustom sets it).
function GMTestDmgBasePower(npc : CActor) : float
{
	var action : W3Action_Attack;
	var power : SAbilityAttributeValue;

	thePlayer.ForceSetStat(BCS_Focus, 0);
	action = new W3Action_Attack in theGame.damageMgr;
	action.Init(thePlayer, npc, NULL, GetInvalidUniqueId(), 'attack_light', thePlayer.GetName(), EHRT_Light,
		false, false, 'attack_light', AST_Jab, ASD_UpDown, true, false, false, false);
	power = action.GetPowerStatValue();
	delete action;
	return power.valueMultiplicative;
}

// A hit of Geralt's on the dummy, repeated (up to 5 times) until it is not a critical hit.
function GMTestDmgNoCrit(npc : CActor, dmgType : name, value : float, kind : int) : SGMTestDmgStep
{
	var i : int;

	for(i = 0; i < 5; i += 1)
		if(!GMTestDmgCustom(thePlayer, npc, dmgType, value, kind))
			break;
	return GMTestDmgStep0();
}

// DMG slice 2 (DMG-01 to DMG-03): the formula against the test dummy, scripted hits of Geralt's of one
// damage type (no weapon). Needs a dummy: gmtest_dummy("human") in an earlier call. Sets its stats.
exec function gmtest_dmg02()
{
	var npc : CNewNPC;
	var step, front : SGMTestDmgStep;
	var probes : bool;
	var armor, pierce, expectedPts : float;

	npc = GMTestDummy();
	if(!npc)
	{
		GMTestReport(false, "DMG slice 2: no test dummy (gmtest_dummy(\"human\") first)");
		return;
	}
	probes = GMTestProbes();
	thePlayer.GMTestSetProbes(true);
	GMTestDummyFreeze(npc);
	GMTestReport(GMTestDummyNeutral(npc), "DMG slice 2: dummy set to neutral stats");
	armor = 40;
	GMTestDummySet(npc, 'armor', armor);
	pierce = CalculateAttributeValue(thePlayer.GetAttributeValue('armor_reduction'));
	expectedPts = MaxF(0, armor - pierce);
	LogChannel('GMTest', "INFO dummy armor " + NoTrailZeros(armor) + ", Geralt's armor piercing " + NoTrailZeros(pierce));

	// DMG-01: armor is subtracted from the raw damage before attack power counts
	step = GMTestDmgNoCrit(npc, theGame.params.DAMAGE_NAME_SLASHING, 100, 0);
	GMTestDmgLogStep("slashing 100", step);
	GMTestReport(GMTestDmgNear(step.pts, expectedPts) && GMTestDmgNear(step.result, MaxF(0, MaxF(0, step.rawIn + step.base - step.pts) * step.mult + step.add) * (1 - step.perc)),
		"DMG-01 armor before attack power: (raw + base - armor) * mult + add, armor " + NoTrailZeros(step.pts));
	front = step;

	// DMG-01: a hit armor stops completely deals only the additive attack power
	step = GMTestDmgNoCrit(npc, theGame.params.DAMAGE_NAME_SLASHING, expectedPts * 0.5, 0);
	GMTestDmgLogStep("slashing below armor", step);
	GMTestReport(GMTestDmgNear(step.result, step.add * (1 - step.perc)), "DMG-01 a hit below the armor deals only the additive attack power (" + NoTrailZeros(step.add) + ")");

	// DMG-01: elemental damage is reduced by armor too (5.x lets it through)
	step = GMTestDmgNoCrit(npc, theGame.params.DAMAGE_NAME_ELEMENTAL, 100, 0);
	GMTestDmgLogStep("elemental 100", step);
	GMTestReport(GMTestDmgNear(step.pts, expectedPts) && GMTestDmgNear(step.result, MaxF(0, MaxF(0, step.rawIn + step.base - step.pts) * step.mult + step.add) * (1 - step.perc)),
		"DMG-01 elemental damage is reduced by armor");

	// DMG-02: a negative resistance is clamped at 0 and does not shrink armor
	GMTestDummySet(npc, 'slashing_resistance_perc', -0.5);
	step = GMTestDmgNoCrit(npc, theGame.params.DAMAGE_NAME_SLASHING, 100, 0);
	GMTestDmgLogStep("slashing 100, resistance -50%", step);
	GMTestReport(GMTestDmgNear(step.pts, expectedPts) && step.perc == 0, "DMG-02 a negative resistance counts as 0 and leaves armor whole (5.x: armor x0.5)");
	GMTestDummySet(npc, 'slashing_resistance_perc', 0.3);
	step = GMTestDmgNoCrit(npc, theGame.params.DAMAGE_NAME_SLASHING, 100, 0);
	GMTestDmgLogStep("slashing 100, resistance 30%", step);
	GMTestReport(GMTestDmgNear(step.perc, 0.3) && GMTestDmgNear(step.result, MaxF(0, MaxF(0, step.rawIn + step.base - step.pts) * step.mult + step.add) * 0.7),
		"DMG-01 the resistance applies last: x(1 - 30%)");

	// DMG-02 and DMG-03: damage over time skips armor and gets no attack power
	step = GMTestDmgNoCrit(npc, theGame.params.DAMAGE_NAME_SLASHING, 100, 1);
	GMTestDmgLogStep("slashing 100 over time", step);
	GMTestReport(step.pts == 0 && step.base == 0 && step.mult == 1 && step.add == 0, "DMG-02/03 damage over time: no armor, no attack power");

	// DMG-02: the player's shock damage skips armor
	step = GMTestDmgNoCrit(npc, theGame.params.DAMAGE_NAME_SHOCK, 100, 0);
	GMTestDmgLogStep("shock 100", step);
	GMTestReport(step.pts == 0, "DMG-02 the player's shock damage skips armor");

	// DMG-02 and DMG-03: a headshot ignores armor and resistance and adds 25% attack power (crits add
	// no damage on the dummy for this check, so attack power compares exactly)
	GMTestDummySet(npc, 'critical_hit_damage_reduction', 1);
	step = GMTestDmgNoCrit(npc, theGame.params.DAMAGE_NAME_SLASHING, 100, 2);
	GMTestDmgLogStep("slashing 100, headshot", step);
	GMTestReport(step.pts == 0 && step.perc == 0 && GMTestDmgNear(step.mult, GMTestDmgBasePower(npc) + 0.25), "DMG-02/03 a headshot ignores armor and resistance, +25% attack power ("
		+ NoTrailZeros(GMTestDmgBasePower(npc)) + " before the damage manager -> " + NoTrailZeros(step.mult) + ")");

	GMTestDummyNeutral(npc);
	thePlayer.GMTestSetProbes(probes);
}

// DMG-03: a hit in the back adds 25% attack power. Turns the dummy away from Geralt; the hit follows in
// a later call (gmtest_dmg02_back), once the turn has taken effect.
exec function gmtest_dmg02_turn()
{
	var npc : CNewNPC;

	npc = GMTestDummy();
	if(npc)
		npc.TeleportWithRotation(npc.GetWorldPosition(), VecToRotation(npc.GetWorldPosition() - thePlayer.GetWorldPosition()));
}

exec function gmtest_dmg02_back()
{
	var npc : CNewNPC;
	var step : SGMTestDmgStep;
	var probes : bool;
	var front : float;

	npc = GMTestDummy();
	if(!npc)
		return;
	probes = GMTestProbes();
	thePlayer.GMTestSetProbes(true);
	GMTestDummySet(npc, 'critical_hit_damage_reduction', 1);
	step = GMTestDmgNoCrit(npc, theGame.params.DAMAGE_NAME_SLASHING, 100, 0);
	GMTestDmgLogStep("slashing 100, in the back", step);
	front = GMTestDmgBasePower(npc);
	GMTestReport(GMTestDmgNear(step.mult, front + 0.25), "DMG-03 a backstab adds 25% attack power ("
		+ NoTrailZeros(front) + " before the damage manager, " + NoTrailZeros(step.mult) + " in the back)");
	GMTestDummyFreeze(npc);	// faces Geralt again
	GMTestDummyNeutral(npc);
	thePlayer.GMTestSetProbes(probes);
}

// DMG slice 3a (DMG-04): the additive raw-damage pool and heavy attacks, against the test dummy with
// Geralt's sword (scripted attacks built as real ones). Needs a dummy (gmtest_dummy("human") in an
// earlier call); for the additivity check also the new tree's Strength Training (skilleq(S_Sword_s23, 0, 3)).
exec function gmtest_dmg03a()
{
	var npc : CNewNPC;
	var weaponId, npcWeapon : SItemUniqueId;
	var light, heavy : SGMTestDmgStep;
	var lightRatio, heavyRatio, ratio, eos : float;
	var min, max : SAbilityAttributeValue;
	var probes : bool;

	npc = GMTestDummy();
	weaponId = thePlayer.GetInventory().GetItemFromSlot('r_weapon');
	if(!npc || !thePlayer.GetInventory().IsIdValid(weaponId) || thePlayer.IsWeaponHeld('fist'))
	{
		GMTestReport(false, "DMG slice 3a: needs a test dummy and a drawn sword");
		return;
	}
	probes = GMTestProbes();
	thePlayer.GMTestSetProbes(true);
	GMTestDummyFreeze(npc);
	GMTestDummyNeutral(npc);
	GMTestDummySet(npc, 'armor', 250);
	GMTestDummySet(npc, 'critical_hit_damage_reduction', 1);

	// Geralt's light attack: no pool term
	thePlayer.ForceSetStat(BCS_Focus, 0);
	GMTestDmgHit(thePlayer, npc, weaponId, 'attack_light');
	light = GMTestDmgStep0();
	lightRatio = thePlayer.gmTestDmgRawAfter / MaxF(0.001, thePlayer.gmTestDmgRawBefore);
	GMTestDmgLogStep("light attack", light);
	GMTestReport(GMTestDmgNear(lightRatio, 1), "DMG-04 a light attack: raw damage unchanged by the pool (x" + NoTrailZeros(lightRatio) + ")");

	// Geralt's heavy attack: +50% weapon damage (Strong Attack), 200 armor piercing, no attack power change
	GetWitcherPlayer().GMTestSetSTStacks(0);	// the light attack gave the new tree's Strength Training a stack
	thePlayer.ForceSetStat(BCS_Focus, 0);
	GMTestDmgHit(thePlayer, npc, weaponId, 'attack_heavy');
	heavy = GMTestDmgStep0();
	heavyRatio = thePlayer.gmTestDmgRawAfter / MaxF(0.001, thePlayer.gmTestDmgRawBefore);
	GMTestDmgLogStep("heavy attack", heavy);
	GMTestReport(GMTestDmgNear(heavyRatio, 1.5), "DMG-04 Strong Attack: a heavy attack's raw damage x1.5 (x" + NoTrailZeros(heavyRatio) + ")");
	GMTestReport(GMTestDmgNear(light.pts - heavy.pts, 200), "DMG-04 Strong Attack pierces 200 armor (" + NoTrailZeros(light.pts) + " -> " + NoTrailZeros(heavy.pts) + ")");
	GMTestReport(GMTestDmgNear(heavy.mult, light.mult), "DMG-01 a heavy attack has a light attack's attack power (" + NoTrailZeros(light.mult) + ", "
		+ NoTrailZeros(heavy.mult) + "; 5.x: -0.433 + 0.333 + 0.15)");
	GMTestReport(GMTestDmgNear(heavy.result, MaxF(0, MaxF(0, heavy.rawIn + heavy.base - heavy.pts) * heavy.mult + heavy.add) * (1 - heavy.perc)),
		"DMG-01 a heavy attack follows the formula without 5.x's x1.833");

	// Pool terms add up: Strong Attack + the new tree's Strength Training at 3 stacks (5.x's Element of
	// Surprise, the former sample, is gone)
	if(thePlayer.CanUseSkill(S_Sword_s23))
	{
		GetWitcherPlayer().GMTestSetSTStacks(GetWitcherPlayer().GetSkillLevel(S_Sword_s23));
		eos = GetWitcherPlayer().GMStrengthTrainingBonus('gm_st_weapon_damage', GetWitcherPlayer().GetSkillLevel(S_Sword_s23));
		thePlayer.ForceSetStat(BCS_Focus, 0);
		GMTestDmgHit(thePlayer, npc, weaponId, 'attack_heavy');
		ratio = thePlayer.gmTestDmgRawAfter / MaxF(0.001, thePlayer.gmTestDmgRawBefore);
		GMTestReport(GMTestDmgNear(ratio, 1 + 0.5 + eos), "DMG-04 pool terms add up: Strong Attack +50% and Strength Training +" + NoTrailZeros(eos * 100)
			+ "% give x" + NoTrailZeros(ratio) + " (additive " + NoTrailZeros(1.5 + eos) + ", 5.x's stacking " + NoTrailZeros(1.5 * (1 + eos)) + ")");
	}
	else
		LogChannel('GMTest', "INFO DMG-04 additivity not checked: Geralt lacks the new tree's Strength Training (skilleq(S_Sword_s23, 0, 3))");

	// the dummy's heavy attack on Geralt: +25% weapon damage, no attack power bonus
	npcWeapon = GMTestNpcWeapon(npc);
	GMTestDmgHit(npc, thePlayer, npcWeapon, 'attack_light');
	light = GMTestDmgStep0();
	GMTestDmgHit(npc, thePlayer, npcWeapon, 'attack_heavy');
	heavy = GMTestDmgStep0();
	ratio = thePlayer.gmTestDmgRawAfter / MaxF(0.001, thePlayer.gmTestDmgRawBefore);
	GMTestDmgLogStep("dummy's heavy attack on Geralt", heavy);
	GMTestReport(GMTestDmgNear(ratio, 1.25), "DMG-04 an NPC's heavy attack: raw damage x1.25 (x" + NoTrailZeros(ratio) + ")");
	GMTestReport(GMTestDmgNear(heavy.mult, light.mult), "DMG-01 an NPC's heavy attack has its light attack's attack power (" + NoTrailZeros(light.mult)
		+ ", " + NoTrailZeros(heavy.mult) + "; 5.x: +0.15)");
	thePlayer.ForceSetStat(BCS_Vitality, thePlayer.GetStatMax(BCS_Vitality));

	GMTestDummyNeutral(npc);
	thePlayer.GMTestSetProbes(probes);
}

// Draws Geralt's steel sword (silver: true for the silver one), for the damage tests; takes a moment.
exec function gmtest_draw(optional silver : bool)
{
	if(silver)
		thePlayer.OnEquipMeleeWeapon(PW_Silver, true);
	else
		thePlayer.OnEquipMeleeWeapon(PW_Steel, true);
}

// DMG slice 3b (DMG-05, DMG-01, DMG-02): the final-damage step, the player's minimum damage removed,
// VulnerableFromFront before the formula. Scripted hits on and from the test dummy (gmtest_dummy("human")
// in an earlier call).
exec function gmtest_dmg03b()
{
	var npc : CNewNPC;
	var step : SGMTestDmgStep;
	var anim : EActionHitAnim;
	var dealt : float;
	var sum : float;
	var probes : bool;

	npc = GMTestDummy();
	if(!npc)
	{
		GMTestReport(false, "DMG slice 3b: no test dummy (gmtest_dummy(\"human\") first)");
		return;
	}
	probes = GMTestProbes();
	thePlayer.GMTestSetProbes(true);
	GMTestDummyFreeze(npc);
	GMTestDummyNeutral(npc);
	GMTestDummySet(npc, 'critical_hit_damage_reduction', 1);

	// the difficulty multiplier: in final damage, not raw damage
	GMTestDummySet(npc, 'damage_final_multiplier', 2);
	GMTestDmgCustom(npc, thePlayer, theGame.params.DAMAGE_NAME_SLASHING, 200, 0);
	step = GMTestDmgStep0();
	GMTestDmgLogStep("dummy's hit on Geralt, difficulty x2", step);
	GMTestReport(GMTestDmgNear(thePlayer.gmTestDmgRawAfter, thePlayer.gmTestDmgRawBefore) && GMTestDmgNear(thePlayer.gmTestDmgFinal, step.result * 2),
		"DMG-05 the difficulty multiplier applies to final damage (raw " + NoTrailZeros(thePlayer.gmTestDmgRawBefore) + " -> " + NoTrailZeros(thePlayer.gmTestDmgRawAfter)
		+ ", formula " + NoTrailZeros(step.result) + ", dealt " + NoTrailZeros(thePlayer.gmTestDmgFinal) + ")");
	GMTestDummySet(npc, 'damage_final_multiplier', 1);

	// no minimum damage: a hit Geralt's armor stops deals nothing (5.x: 5% of the raw damage, at least 1)
	GMTestDmgCustom(npc, thePlayer, theGame.params.DAMAGE_NAME_SLASHING, 10, 0);
	step = GMTestDmgStep0();
	GMTestDmgLogStep("dummy's weak hit on Geralt", step);
	GMTestReport(step.pts >= 10 * 1.1 && thePlayer.gmTestDmgFinal == 0, "DMG-01 a hit Geralt's armor stops deals nothing (armor " + NoTrailZeros(step.pts)
		+ ", dealt " + NoTrailZeros(thePlayer.gmTestDmgFinal) + "; 5.x: at least 1)");

	// a hit below 1 deals nothing
	GMTestDmgCustom(npc, thePlayer, theGame.params.DAMAGE_NAME_SLASHING, 0.6, 3);
	step = GMTestDmgStep0();
	GMTestDmgLogStep("dummy's hit of 0.6 ignoring armor", step);
	GMTestReport(step.result > 0 && step.result < 1 && thePlayer.gmTestDmgFinal == 0, "DMG-05 a hit below 1 deals nothing (formula " + NoTrailZeros(step.result)
		+ ", dealt " + NoTrailZeros(thePlayer.gmTestDmgFinal) + ")");

	// audit F2: a hit armor stops completely deals nothing and plays no hit animation (the dummy's hit on
	// Geralt, the animation left to the game); a hit that deals damage keeps its animation
	GMTestDmgCustom(npc, thePlayer, theGame.params.DAMAGE_NAME_SLASHING, 10, 4);
	anim = thePlayer.gmTestDmgAnim;
	dealt = thePlayer.gmTestDmgFinal;
	GMTestDmgCustom(npc, thePlayer, theGame.params.DAMAGE_NAME_SLASHING, 300, 4);
	GMTestReport(dealt == 0 && anim == EAHA_ForceNo && thePlayer.gmTestDmgFinal > 0 && thePlayer.gmTestDmgAnim != EAHA_ForceNo,
		"DMG-01 a hit armor stops: 0 damage and no hit animation (" + NoTrailZeros(dealt) + ", " + anim + "); a hit of 300: "
		+ NoTrailZeros(thePlayer.gmTestDmgFinal) + ", " + thePlayer.gmTestDmgAnim);
	thePlayer.ForceSetStat(BCS_Vitality, thePlayer.GetStatMax(BCS_Vitality));

	// Geralt's hit on the dummy: no difficulty multiplier, the damage dealt is the formula's
	GMTestDummySet(npc, 'armor', 40);
	GMTestDmgNoCrit(npc, theGame.params.DAMAGE_NAME_SLASHING, 100, 0);
	step = GMTestDmgStep0();
	GMTestReport(GMTestDmgNear(thePlayer.gmTestDmgFinal, step.result), "DMG-05 Geralt's hit: the damage dealt is the formula's (" + NoTrailZeros(step.result)
		+ ", dealt " + NoTrailZeros(thePlayer.gmTestDmgFinal) + ")");

	// VulnerableFromFront: a hit from the front ignores armor, decided before the formula
	npc.AddAbility('VulnerableFromFront', false);
	GMTestDmgNoCrit(npc, theGame.params.DAMAGE_NAME_SLASHING, 100, 0);
	step = GMTestDmgStep0();
	GMTestDmgLogStep("hit from the front, VulnerableFromFront", step);
	GMTestReport(step.pts == 0 && GMTestDmgNear(thePlayer.gmTestDmgFinal, step.result), "DMG-02 VulnerableFromFront: a hit from the front ignores armor (armor "
		+ NoTrailZeros(step.pts) + ")");
	npc.RemoveAbility('VulnerableFromFront');

	thePlayer.ForceSetStat(BCS_Vitality, thePlayer.GetStatMax(BCS_Vitality));
	GMTestDummyNeutral(npc);
	thePlayer.GMTestSetProbes(probes);
}

// The armor ability a human NPC's template includes, or 'none'.
function GMTestTemplateArmorAbility(npc : CNewNPC) : name
{
	var template : CEntityTemplate;
	var i : int;
	var a : name;

	template = (CEntityTemplate)LoadResource(npc.GetReadableName(), true);
	if(!template)
		return 'none';
	for(i = 0; i < template.includes.Size(); i += 1)
	{
		a = GMGetArmorAbilityFromPath(template.includes[i].GetPath());
		if(a != 'none')
			return a;
	}
	return 'none';
}

// DMG slice 4 (DMG-15, DMG-08). Human NPCs within 30 m (spawn some first, e.g. gmtest_dummy("human") or
// gmtest_dmg04_spawn()) have the armor ability their template includes; an NPC's weapon damage is its
// weapon's; Geralt's relic sword Caerme deals its fire damage (additem('Caerme', 1, true) first).
exec function gmtest_dmg04()
{
	var actors : array<CActor>;
	var npc : CNewNPC;
	var i, j, humans, withTemplateArmor, fixed : int;
	var a : name;
	var inv : CInventoryComponent;
	var weapons : array<SItemUniqueId>;
	var dts : array<name>;
	var item : SAbilityAttributeValue;
	var ok, checkedWeapon : bool;
	var ids : array<SItemUniqueId>;
	var fire, itemFire : float;

	// DMG-15
	actors = thePlayer.GetNPCsAndPlayersInRange(30, 50, , FLAG_OnlyAliveActors);
	ok = true;
	for(i = 0; i < actors.Size(); i += 1)
	{
		npc = (CNewNPC)actors[i];
		if(!npc || !npc.IsHuman())
			continue;
		humans += 1;
		a = GMTestTemplateArmorAbility(npc);
		LogChannel('GMTest', "INFO human " + npc.GetDisplayName() + " (" + npc.GetReadableName() + "): template armor " + a + ", has it "
			+ (a != 'none' && npc.HasAbility(a)) + ", armor " + NoTrailZeros(CalculateAttributeValue(npc.GetTotalArmor())));
		if(a != 'none')
		{
			withTemplateArmor += 1;
			if(npc.HasAbility(a))
				fixed += 1;
			else
				ok = false;
		}
	}
	GMTestReport(withTemplateArmor > 0 && ok, "DMG-15 every human NPC nearby has the armor ability its template includes (" + fixed + " of " + withTemplateArmor
		+ "; " + humans + " humans)");

	// DMG-08: an NPC's weapon damage is the weapon item's
	checkedWeapon = false;
	for(i = 0; i < actors.Size() && !checkedWeapon; i += 1)
	{
		npc = (CNewNPC)actors[i];
		if(!npc)
			continue;
		inv = npc.GetInventory();
		weapons = inv.GetWeapons();
		if(weapons.Size() == 0)
			continue;
		dts.Clear();
		inv.GetWeaponDTNames(weapons[0], dts);
		ok = dts.Size() > 0;
		for(j = 0; j < dts.Size(); j += 1)
		{
			item = inv.GetItemAttributeValue(weapons[0], dts[j]);
			item.valueMultiplicative = 1;
			if(!GMTestDmgNear(npc.GetTotalWeaponDamage(weapons[0], dts[j], GetInvalidUniqueId()), CalculateAttributeValue(item)))
				ok = false;
			LogChannel('GMTest', "INFO " + npc.GetDisplayName() + "'s " + inv.GetItemName(weapons[0]) + " " + dts[j] + ": "
				+ NoTrailZeros(npc.GetTotalWeaponDamage(weapons[0], dts[j], GetInvalidUniqueId())) + " (item " + NoTrailZeros(CalculateAttributeValue(item)) + ")");
		}
		GMTestReport(ok, "DMG-08 " + npc.GetDisplayName() + "'s weapon damage is its weapon's");
		checkedWeapon = true;
	}

	// DMG-08: a sword's fire damage counts (5.x: x0)
	ids = thePlayer.GetInventory().GetItemsByName('Caerme');
	if(ids.Size() > 0)
	{
		fire = GetWitcherPlayer().GetTotalWeaponDamage(ids[0], theGame.params.DAMAGE_NAME_FIRE, GetInvalidUniqueId());
		item = thePlayer.GetInventory().GetItemAttributeValue(ids[0], theGame.params.DAMAGE_NAME_FIRE);
		item.valueMultiplicative = 1;
		itemFire = CalculateAttributeValue(item);
		GMTestReport(itemFire > 0 && fire >= itemFire - 0.01, "DMG-08 Caerme's fire damage counts: " + NoTrailZeros(fire) + " (item " + NoTrailZeros(itemFire) + "; 5.x: 0)");
	}
	else
		LogChannel('GMTest', "INFO DMG-08 fire damage not checked: no Caerme (additem('Caerme', 1, true))");
}

// Spawns hostile humans of three templates 6 m in front of Geralt, frozen (test dummies), for gmtest_dmg04.
exec function gmtest_dmg04_spawn()
{
	GMTestDummySpawn("living_world\enemy_templates\nilfgaardian_deserter_bow.w2ent", 0, 6);
	GMTestDummySpawn("living_world\enemy_templates\baron_renegade_bow.w2ent", 0, 7);
	GMTestDummySpawn("living_world\enemy_templates\skellige_bandit_bow.w2ent", 0, 8);
}

// DMG slice 5 (DMG-06, DMG-07): the sign intensity curve (scripted values) and effect durations (a
// poison effect on the test dummy with a set duration and creator power). Needs a dummy
// (gmtest_dummy("human") in an earlier call).
exec function gmtest_dmg05()
{
	var npc : CNewNPC;
	var params : SCustomEffectParams;
	var effect : CBaseGameplayEffect;
	var d1, d2 : float;

	// DMG-06
	GMTest_dmg06();

	// DMG-07
	npc = GMTestDummy();
	if(!npc)
	{
		GMTestReport(false, "DMG slice 5: no test dummy (gmtest_dummy(\"human\") first)");
		return;
	}
	GMTestDummyFreeze(npc);
	GMTestDummyNeutral(npc);
	npc.RemoveBuff(EET_Poison);
	params.effectType = EET_Poison;
	params.creator = thePlayer;
	params.sourceName = "gmtest";
	params.duration = 10;
	params.customPowerStatValue.valueMultiplicative = 3;
	npc.AddEffectCustom(params);
	effect = npc.GetBuff(EET_Poison);
	if(!effect)
	{
		GMTestReport(false, "DMG-07 the poison effect was not applied to the dummy");
		return;
	}
	d1 = effect.GetInitialDurationAfterResists();
	GMTestReport(GMTestDmgNear(d1, 10), "DMG-07 a negative effect's duration ignores the creator's power: 10 s at power x3 (" + NoTrailZeros(d1) + "; 5.x: 30)");
	npc.RemoveBuff(EET_Poison);

	GMTestDummySet(npc, 'poison_resistance_perc', 0.5);
	npc.AddEffectCustom(params);
	effect = npc.GetBuff(EET_Poison);
	d1 = effect.GetInitialDurationAfterResists();
	effect.RecalcDuration();
	effect.RecalcDuration();
	d2 = effect.GetInitialDurationAfterResists();
	GMTestReport(GMTestDmgNear(d1, 5) && GMTestDmgNear(d2, 5), "DMG-07 resistance 50%: 5 s, and still 5 s after two recalculations (" + NoTrailZeros(d1)
		+ " -> " + NoTrailZeros(d2) + "; 5.x shrinks it each time)");
	npc.RemoveBuff(EET_Poison);
	GMTestDummyNeutral(npc);
}

// DMG-06's situation-free check (in gmtest_regress()).
function GMTest_dmg06()
{
	GMTestReport(GMSignPowerStatToPowerBonus(1) == 0 && GMTestDmgNear(GMSignPowerStatToPowerBonus(1.5), 0.40) && GMTestDmgNear(GMSignPowerStatToPowerBonus(2), 0.75)
		&& GMTestDmgNear(GMSignPowerStatToPowerBonus(3), 1.30) && GMTestDmgNear(GMSignPowerStatToPowerBonus(6), 2.0) && GMTestDmgNear(GMSignPowerStatToPowerBonus(10), 2.0),
		"DMG-06 sign intensity curve: 100% +0, 150% +0.40, 200% +0.75, 300% +1.30, 600% and more +2.0 ("
		+ NoTrailZeros(GMSignPowerStatToPowerBonus(1.5)) + ", " + NoTrailZeros(GMSignPowerStatToPowerBonus(2)) + ", " + NoTrailZeros(GMSignPowerStatToPowerBonus(3))
		+ ", " + NoTrailZeros(GMSignPowerStatToPowerBonus(6)) + ", " + NoTrailZeros(GMSignPowerStatToPowerBonus(10)) + ")");
	GMTest_dmg01_armorflag();
}

// One scripted hit of Geralt's (one damage type, no weapon, no hit animation) on victim; whether the hit was marked
// as stopped by armor (the flag that lets a parried or countered hit spark), and the damage it dealt.
function GMTestDmgArmorFlag(victim : CActor, dmgType : name, value : float, out dealt : bool) : bool
{
	var action : W3Action_Attack;
	var flag : bool;

	action = new W3Action_Attack in theGame.damageMgr;
	action.Init(thePlayer, victim, NULL, GetInvalidUniqueId(), 'attack_light', thePlayer.GetName(), EHRT_Light,
		false, false, 'attack_light', AST_Jab, ASD_UpDown, true, false, false, false);
	action.AddDamage(dmgType, value);
	action.SetSuppressHitSounds(true);
	action.SetHitAnimationPlayType(EAHA_ForceNo);
	theGame.damageMgr.ProcessAction(action);
	flag = action.DidArmorReduceDamageToZero();
	dealt = action.DealsAnyDamage();
	delete action;
	victim.ForceSetStat(BCS_Vitality, victim.GetStatMax(BCS_Vitality));
	return flag;
}

// DMG-01 (whole-port audit A2-5): legacy's CalculateDamage returns 0 at once for a damage type the victim's stat
// ignores and for a value of 0 or less, and a hit is marked stopped by armor only when it dealt damage up to the
// final-damage step and none after it (ProcessDamageModification), not per damage type. On a bandit (Vitality,
// armored), hostile for the call: 1 SilverDamage (Vitality ignores it) and 1 SlashingDamage (below its armor) deal
// nothing and are not marked [the port before: both marked, by the per-type rule].
function GMTest_dmg01_armorflag()
{
	var npc : CNewNPC;
	var armor : float;
	var flagSilver, flagSlash, dealtSilver, dealtSlash : bool;

	npc = GMTestDiff04SpawnLoose(34);
	if(!npc)
	{
		GMTestReport(false, "DMG-01 the armor-flag bandit did not spawn");
		return;
	}
	npc.RecalcLevel();	// its level bonuses and DMG-15's armor ability, as the spawn's timer gives them
	if(CalculateAttributeValue(npc.GetTotalArmor()) <= 1)
		GMTestDummySet(npc, 'armor', 20);
	npc.SetAttitude(thePlayer, AIA_Hostile);
	armor = CalculateAttributeValue(npc.GetTotalArmor());
	flagSilver = GMTestDmgArmorFlag(npc, theGame.params.DAMAGE_NAME_SILVER, 1, dealtSilver);
	flagSlash = GMTestDmgArmorFlag(npc, theGame.params.DAMAGE_NAME_SLASHING, 1, dealtSlash);
	npc.SetAttitude(thePlayer, AIA_Neutral);
	GMTestReport(armor > 1 && !flagSilver && !dealtSilver && !flagSlash && !dealtSlash, "DMG-01 no armor flag without the final-damage step (legacy), a bandit of armor " + NoTrailZeros(armor)
		+ ": 1 silver (Vitality ignores it) marked " + flagSilver + ", dealt " + dealtSilver + "; 1 slashing (stopped by armor) marked " + flagSlash + ", dealt " + dealtSlash
		+ " (want false each; the port before A2-5: marked)");
	npc.Destroy();
}

// Makes Geralt bare-handed (fists), for gmtest_dmg06a; takes a moment.
exec function gmtest_fists()
{
	thePlayer.OnEquipMeleeWeapon(PW_Fists, true);
}

// DMG slice 6a (DMG-10, DMG-11): a non-deadly fight and returned damage, scripted hits between Geralt
// and the test dummy. Needs a dummy (gmtest_dummy("human")) and Geralt bare-handed (gmtest_fists()),
// both in earlier calls.
exec function gmtest_dmg06a()
{
	var npc : CNewNPC;
	var npcWeapon, fists : SItemUniqueId;
	var expected, mult, before, loss, lo, hi, dealt : float;
	var power, min, max : SAbilityAttributeValue;
	var effect : CBaseGameplayEffect;
	var probes : bool;
	var npcInv : CInventoryComponent;
	var dts : array<name>;
	var params : SCustomEffectParams;
	var i : int;
	var ok : bool;

	npc = GMTestDummy();
	fists = thePlayer.GetInventory().GetItemFromSlot('r_weapon');
	if(!npc || !thePlayer.IsWeaponHeld('fist'))
	{
		GMTestReport(false, "DMG slice 6a: needs a test dummy and Geralt bare-handed (gmtest_fists())");
		return;
	}
	probes = GMTestProbes();
	thePlayer.GMTestSetProbes(true);
	GMTestDummyFreeze(npc);
	GMTestDummyNeutral(npc);
	GMTestDummySet(npc, 'critical_hit_damage_reduction', 1);
	npcInv = npc.GetInventory();
	npcWeapon = GMTestNpcWeapon(npc);
	npcInv.MountItem(npcWeapon, true);

	// DMG-10: Geralt's fists against an opponent fighting non-deadly (Olaf's ability, a weapon in hand):
	// 20% of its maximum health x0.5 (Olaf)
	npc.AddAbility('mon_ff204olaf', false);
	GMTestDmgHit(thePlayer, npc, fists, 'attack_light');
	expected = 0.2 * npc.GetMaxHealth() * 0.5;
	GMTestReport(GMTestDmgNear(thePlayer.gmTestDmgFinal, expected), "DMG-10 non-deadly fight, Geralt against Olaf: 20% of max health x0.5 ("
		+ NoTrailZeros(thePlayer.gmTestDmgFinal) + ", expected " + NoTrailZeros(expected) + "; weapon in hand " + npcInv.IsItemHeld(npcWeapon) + ")");

	// DMG-10: the opponent's hit on Geralt: x(0.25 + 0.25 per difficulty above the second + 0.1 per level difference), no difficulty multiplier
	GMTestDummySet(npc, 'damage_final_multiplier', 3);
	GMTestDmgHit(npc, thePlayer, npcWeapon, 'attack_light');
	mult = 0.25 + MaxF(0, (int)theGame.GetSpawnDifficultyMode() - 1) * 0.25 + 0.1 * ClampF(npc.GetLevel() - thePlayer.GetLevel(), -10, 10);
	expected = 0.2 * thePlayer.GetMaxHealth() * mult;
	GMTestReport(GMTestDmgNear(thePlayer.gmTestDmgFinal, expected), "DMG-10 non-deadly fight, Olaf's hit on Geralt: 20% of max health x" + NoTrailZeros(mult)
		+ ", no difficulty multiplier (" + NoTrailZeros(thePlayer.gmTestDmgFinal) + ", expected " + NoTrailZeros(expected) + ")");
	npc.RemoveAbility('mon_ff204olaf');
	GMTestDummySet(npc, 'damage_final_multiplier', 1);

	// DMG-11: Thorns on Geralt: 10% of the attacker's weapon damage, with Geralt's attack power
	thePlayer.AddAbility('Thorns', false);
	thePlayer.ForceSetStat(BCS_Focus, 0);
	GMTestDummyHeal(npc);
	before = npc.GetHealth();
	GMTestDmgHit(npc, thePlayer, npcWeapon, 'attack_light');
	loss = before - npc.GetHealth();
	npcInv.GetWeaponDTNames(npcWeapon, dts);
	power = thePlayer.GetPowerStatValue(CPS_AttackPower);
	expected = MaxF(0, npc.GetTotalWeaponDamage(npcWeapon, dts[0], GetInvalidUniqueId()) * 0.1 + power.valueBase) * power.valueMultiplicative + power.valueAdditive;
	GMTestReport(GMTestDmgNear(loss, expected), "DMG-11 Thorns: 10% of the attacker's weapon damage with attack power (" + NoTrailZeros(loss) + ", expected "
		+ NoTrailZeros(expected) + ")");
	thePlayer.RemoveAbility('Thorns');

	// DMG-11: Mutagen 26 (Leshen) on Geralt: a share of the damage dealt, no attack power
	params.effectType = EET_Mutagen26;
	params.creator = thePlayer;
	params.sourceName = "gmtest";
	params.duration = 60;
	params.customAbilityName = 'Mutagen26Effect';
	LogChannel('GMTest', "INFO Mutagen 26 added: " + thePlayer.AddEffectCustom(params));
	effect = thePlayer.GetBuff(EET_Mutagen26);
	if(effect)
	{
		theGame.GetDefinitionsManager().GetAbilityAttributeValue(effect.GetAbilityName(), 'returned_damage', min, max);
		GMTestDummyHeal(npc);
		before = npc.GetHealth();
		GMTestDmgHit(npc, thePlayer, npcWeapon, 'attack_light');
		loss = before - npc.GetHealth();
		// the dummy's hit records its weapon's damage types first, then the returned hit records its own
		dealt = 0;
		for(i = 0; i < thePlayer.gmTestDmgSteps.Size(); i += 1)
		{
			GMTestDmgLogStep("Mutagen 26 hit, step " + i, thePlayer.gmTestDmgSteps[i]);
			if(i < dts.Size() && thePlayer.gmTestDmgSteps[i].hitsStat)
				dealt += thePlayer.gmTestDmgSteps[i].result;
		}
		lo = min.valueAdditive + min.valueMultiplicative * dealt;
		hi = max.valueAdditive + max.valueMultiplicative * dealt;
		ok = thePlayer.gmTestDmgSteps.Size() > dts.Size();
		for(i = dts.Size(); i < thePlayer.gmTestDmgSteps.Size(); i += 1)
			if(thePlayer.gmTestDmgSteps[i].rawIn < lo - 0.01 || thePlayer.gmTestDmgSteps[i].rawIn > hi + 0.01 || thePlayer.gmTestDmgSteps[i].mult != 1 || thePlayer.gmTestDmgSteps[i].add != 0)
				ok = false;
		GMTestReport(dealt > 0 && ok && GMTestDmgNear(loss, thePlayer.gmTestDmgSteps[thePlayer.gmTestDmgSteps.Size() - 1].result), "DMG-11 Mutagen 26: returns "
			+ NoTrailZeros(thePlayer.gmTestDmgSteps[thePlayer.gmTestDmgSteps.Size() - 1].rawIn) + " for " + NoTrailZeros(dealt) + " dealt, no attack power (expected "
			+ NoTrailZeros(lo) + " to " + NoTrailZeros(hi) + "); the dummy loses " + NoTrailZeros(loss));
		thePlayer.RemoveBuff(EET_Mutagen26);
	}
	else
		GMTestReport(false, "DMG-11 Mutagen 26 could not be added");

	thePlayer.ForceSetStat(BCS_Vitality, thePlayer.GetStatMax(BCS_Vitality));
	GMTestDummyNeutral(npc);
	thePlayer.GMTestSetProbes(probes);
}

// Spawns the dummies gmtest_dmg06b uses: two hostile humans and a friendly one.
exec function gmtest_dmg06b_spawn()
{
	thePlayer.GMTestDummyClearAll();
	GMTestDummySpawn("human", 0, 3);
	GMTestDummySpawn("human", 0, 4);
	GMTestDummySpawn("human", 0, 5, true);
}

function GMTestDmgInRange(x : float, lo : float, hi : float) : bool
{
	return x >= lo - 0.01 && x <= hi + 0.01;
}

// DMG slice 6b (DMG-12): allied NPC damage, scripted hits between the dummies of gmtest_dmg06b_spawn
// (an earlier call): an ally's hit on a hostile, a hostile's hit on the ally, a hostile's hit on another
// hostile (friendly to each other), the same with the ally as an Axii puppet.
exec function gmtest_dmg06b()
{
	var a, a2, b : CNewNPC;
	var step : SGMTestDmgStep;
	var probes : bool;
	var lvl : float;
	var i : int;

	if(thePlayer.gmTestDummies.Size() < 3)
	{
		GMTestReport(false, "DMG slice 6b: gmtest_dmg06b_spawn() first");
		return;
	}
	a = thePlayer.gmTestDummies[0];
	a2 = thePlayer.gmTestDummies[1];
	b = thePlayer.gmTestDummies[2];
	probes = GMTestProbes();
	thePlayer.GMTestSetProbes(true);
	for(i = 0; i < 3; i += 1)
	{
		GMTestDummyFreeze(thePlayer.gmTestDummies[i]);
		GMTestDummyNeutral(thePlayer.gmTestDummies[i]);
		GMTestDummySet(thePlayer.gmTestDummies[i], 'critical_hit_damage_reduction', 1);
	}
	// the two temporary attitude groups are friendly to each other: in a real fight an ally and an enemy are hostile
	a.SetAttitude(b, AIA_Hostile);
	b.SetAttitude(a, AIA_Hostile);
	LogChannel('GMTest', "INFO attitudes: ally " + GetAttitudeBetween(b, thePlayer) + ", hostile " + GetAttitudeBetween(a, thePlayer) + ", hostiles to each other "
		+ GetAttitudeBetween(a, a2) + ", ally and hostile " + GetAttitudeBetween(a, b));

	GMTestDmgCustom(b, a, theGame.params.DAMAGE_NAME_SLASHING, 200, 0);
	GMTestReport(GMTestDmgInRange(thePlayer.gmTestDmgFinal, 0.02 * a.GetMaxHealth(), 0.04 * a.GetMaxHealth()), "DMG-12 an ally's hit on a hostile: 2% to 4% of its max health ("
		+ NoTrailZeros(thePlayer.gmTestDmgFinal) + " of " + NoTrailZeros(a.GetMaxHealth()) + ")");

	GMTestDmgCustom(a, b, theGame.params.DAMAGE_NAME_SLASHING, 200, 0);
	GMTestReport(GMTestDmgInRange(thePlayer.gmTestDmgFinal, 0.01 * b.GetMaxHealth(), 0.02 * b.GetMaxHealth()), "DMG-12 a hostile's hit on an ally: 1% to 2% of its max health ("
		+ NoTrailZeros(thePlayer.gmTestDmgFinal) + ")");

	// audit F1: a hostile's hit the ally's armor stops completely still costs it 1% to 2% (legacy: no early return)
	GMTestDummySet(b, 'armor', 5000);
	GMTestDmgCustom(a, b, theGame.params.DAMAGE_NAME_SLASHING, 200, 0);
	step = GMTestDmgStep0();
	GMTestReport(step.result == 0 && GMTestDmgInRange(thePlayer.gmTestDmgFinal, 0.01 * b.GetMaxHealth(), 0.02 * b.GetMaxHealth()),
		"DMG-12 a hostile's hit the ally's armor stops: still 1% to 2% of its max health (formula " + NoTrailZeros(step.result) + ", dealt "
		+ NoTrailZeros(thePlayer.gmTestDmgFinal) + "; 5.x's early return: 0)");
	GMTestDummySet(b, 'armor', 0);

	GMTestDmgCustom(a, a2, theGame.params.DAMAGE_NAME_SLASHING, 200, 0);
	step = GMTestDmgStep0();
	GMTestReport(GMTestDmgNear(thePlayer.gmTestDmgFinal, step.result * 0.25), "DMG-12 an NPC's hit on a friendly NPC: x0.25 (" + NoTrailZeros(thePlayer.gmTestDmgFinal)
		+ " of " + NoTrailZeros(step.result) + ")");

	b.AddEffectDefault(EET_AxiiGuardMe, thePlayer, "gmtest");
	if(b.HasBuff(EET_AxiiGuardMe))
	{
		lvl = Max(GetWitcherPlayer().GetSkillLevel(S_Magic_s05), GetWitcherPlayer().GetSkillLevel(S_Magic_s31));
		GMTestDmgCustom(b, a, theGame.params.DAMAGE_NAME_SLASHING, 200, 0);
		GMTestReport(GMTestDmgInRange(thePlayer.gmTestDmgFinal, MaxF(10, 0.06 * a.GetMaxHealth() * lvl / 3), MaxF(20, 0.12 * a.GetMaxHealth() * lvl / 3)),
			"DMG-12 an Axii puppet's hit (Puppet level " + NoTrailZeros(lvl) + "): 6% to 12% x level / 3 of its max health (" + NoTrailZeros(thePlayer.gmTestDmgFinal) + ")");
		GMTestDmgCustom(a, b, theGame.params.DAMAGE_NAME_SLASHING, 200, 0);
		GMTestReport(GMTestDmgInRange(thePlayer.gmTestDmgFinal, 0.10 * b.GetMaxHealth(), 0.15 * b.GetMaxHealth()), "DMG-12 a hostile's hit on an Axii puppet: 10% to 15% of its max health ("
			+ NoTrailZeros(thePlayer.gmTestDmgFinal) + "; 5.x: x0.1)");
		b.RemoveBuff(EET_AxiiGuardMe);
	}
	else
		GMTestReport(false, "DMG-12 the Axii puppet effect could not be added");

	for(i = 0; i < 3; i += 1)
		GMTestDummyNeutral(thePlayer.gmTestDummies[i]);
	thePlayer.GMTestSetProbes(probes);
}

// DMG-02's and DMG-12's XML (in gmtest_regress()): the resistance stats registered for NPCs and the
// player (audit F4), sword_2.
function GMTest_dmgxml()
{
	var dm : CDefinitionsManagerAccessor;
	var min, max : SAbilityAttributeValue;
	var ok : bool;

	dm = theGame.GetDefinitionsManager();
	ok = true;
	dm.GetAbilityAttributeValue('all_NPC_ability', 'will_resistance', min, max);	ok = ok && min.valueMultiplicative == 1;
	dm.GetAbilityAttributeValue('all_NPC_ability', 'burning_resistance', min, max);	ok = ok && min.valueMultiplicative == 1;
	dm.GetAbilityAttributeValue('all_NPC_ability', 'burning_DoT_damage_resistance_perc', min, max);	ok = ok && min.valueMultiplicative == 1;
	dm.GetAbilityAttributeValue('all_NPC_ability', 'poison_DoT_damage_resistance_perc', min, max);	ok = ok && min.valueMultiplicative == 1;
	dm.GetAbilityAttributeValue('all_NPC_ability', 'bleeding_DoT_damage_resistance_perc', min, max);	ok = ok && min.valueMultiplicative == 1;
	dm.GetAbilityAttributeValue('all_PC_ability', 'will_resistance', min, max);	ok = ok && min.valueMultiplicative == 1;
	dm.GetAbilityAttributeValue('all_PC_ability', 'burning_resistance', min, max);	ok = ok && min.valueMultiplicative == 1;
	GMTestReport(ok, "DMG-02 will, burning and damage-over-time resistances registered for NPCs and the player");
	dm.GetAbilityAttributeValue('sword_2', 'armor_reduction', min, max);
	ok = min.valueAdditive == 200;
	dm.GetAbilityAttributeValue('sword_2', 'heavy_attack_dmg_boost', min, max);
	GMTestReport(ok && min.valueMultiplicative == 0.5, "DMG-04 sword_2: 200 armor piercing, +50% heavy attack damage");
	// AI-A audit F1's side note: Hearts of Stone's attack_heavy_noparry, given whole (extend emptied it): its
	// attack_heavy tag and focus_hit_drain_mod, no attack power bonus (DMG-01), no focus_gain (SKL-07)
	dm.GetAbilityAttributeValue('attack_heavy_noparry', 'focus_hit_drain_mod', min, max);
	ok = dm.AbilityHasTag('attack_heavy_noparry', 'attack_heavy') && min.valueMultiplicative == 1.5;
	dm.GetAbilityAttributeValue('attack_heavy_noparry', 'attack_power', min, max);
	ok = ok && min.valueMultiplicative == 0;
	dm.GetAbilityAttributeValue('attack_heavy_noparry', 'focus_gain', min, max);
	GMTestReport(ok && min.valueBase == 0, "DMG-01 attack_heavy_noparry (Hearts of Stone): tag attack_heavy " + dm.AbilityHasTag('attack_heavy_noparry', 'attack_heavy')
		+ ", focus_hit_drain_mod x1.5, no attack power bonus, no focus_gain");
}

@addMethod(W3PlayerWitcher)
function GMTestSetSTStacks(n : int)
{
	gmSTStacks = n;
	gmSTEnd = theGame.GetEngineTimeAsSeconds() + 6;
	gmSTLastStackAt = theGame.GetEngineTimeAsSeconds();
	gmSTUsedAt = 0;
}
