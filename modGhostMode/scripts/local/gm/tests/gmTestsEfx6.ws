// EFX-09 tests: killing a frozen rotfiend (docs/features/efx.md). A rotfiend spawned as the test dummy
// (gmtest_efx09_spawn), set up by gmtest_efx09_a (its health, frozen or not), hit for real
// (gmtest_efx02_light_b, a real light attack; or a real Aard), then gmtest_efx09_b reads what happened:
// was it killed or held back by LastBreath, did its death explosion run, and what did it deal to Geralt
// (made immortal for the test, so the damage is dealt and measured but cannot kill him).

@addField(W3PlayerWitcher)
var gmTestEfx9Armed : bool;
@addField(W3PlayerWitcher)
var gmTestEfx9Explosions : int;
@addField(W3PlayerWitcher)
var gmTestEfx9ExplodeTagged : bool;
@addField(W3PlayerWitcher)
var gmTestEfx9GeraltHits : int;
@addField(W3PlayerWitcher)
var gmTestEfx9GeraltDamage : float;
@addField(W3PlayerWitcher)
var gmTestEfx9GeraltHealth : float;
@addField(W3PlayerWitcher)
var gmTestEfx9NpcHealth : float;
@addField(W3PlayerWitcher)
var gmTestEfx9Start : float;
@addField(W3PlayerWitcher)
var gmTestEfx9OtherHits : int;
@addField(W3PlayerWitcher)
var gmTestEfx9Alive : bool;
@addField(W3PlayerWitcher)
var gmTestEfx9Health : float;
@addField(W3PlayerWitcher)
var gmTestEfx9OnLastBreath : int;
@addField(W3PlayerWitcher)
var gmTestEfx9LastBreathSeen : bool;
@addField(W3PlayerWitcher)
var gmTestEfx9FreezeAt : float;
@addField(W3PlayerWitcher)
var gmTestEfx9AttackAt : float;
@addField(W3PlayerWitcher)
var gmTestEfx9FirstHit : float;
@addField(W3PlayerWitcher)
var gmTestEfx9Frozen : bool;
@addField(W3PlayerWitcher)
var gmTestEfx9AttackRelease : bool;

// Logs the rotfiend's health changes and its death, for 20 s.
@addMethod(W3PlayerWitcher)
timer function GMTestEfx9Watch(dt : float, id : int)
{
	var npc : CNewNPC;
	var now : float;

	npc = GMTestDummy();
	now = theGame.GetEngineTimeAsSeconds() - gmTestEfx9Start;
	if(!npc || !gmTestEfx9Armed || now > 30)
	{
		RemoveTimer('GMTestEfx9Watch');
		return;
	}
	if(npc.HasBuff(EET_Frozen) != gmTestEfx9Frozen)
	{
		gmTestEfx9Frozen = !gmTestEfx9Frozen;
		LogChannel('GMTest', "INFO EFX-09 rotfiend frozen " + gmTestEfx9Frozen + " (" + GMTestEfx2FrozenName(npc) + ") at " + NoTrailZeros(RoundTo(now, 2)) + " s");
	}
	if(AbsF(npc.GetHealth() - gmTestEfx9Health) > 0.01 && gmTestEfx9FirstHit < 0)
	{
		gmTestEfx9FirstHit = npc.GetHealth();
		LogChannel('GMTest', "INFO EFX-09 rotfiend health " + NoTrailZeros(RoundTo(gmTestEfx9Health, 1)) + " -> " + NoTrailZeros(RoundTo(npc.GetHealth(), 1)) + " at " + NoTrailZeros(RoundTo(now, 2)) + " s, frozen " + npc.HasBuff(EET_Frozen));
	}
	gmTestEfx9Health = npc.GetHealth();
	if(!gmTestEfx9LastBreathSeen && npc.GMTestLastBreathTime() >= gmTestEfx9Start)
	{
		gmTestEfx9LastBreathSeen = true;
		LogChannel('GMTest', "INFO EFX-09 LastBreath at " + NoTrailZeros(RoundTo(now, 2)) + " s, health " + NoTrailZeros(RoundTo(npc.GetHealth(), 1)));
		if(gmTestEfx9OnLastBreath >= 1)
			npc.SetAnimationSpeedMultiplier(1);
		if(gmTestEfx9OnLastBreath == 2)
			gmTestEfx9FreezeAt = now + 0.6;
		if(gmTestEfx9OnLastBreath >= 2)
			gmTestEfx9AttackAt = now + 1.1;
	}
	if(gmTestEfx9AttackRelease)
	{
		gmTestEfx9AttackRelease = false;
		GMTestActInput(0, false);
	}
	if(gmTestEfx9AttackAt > 0 && now >= gmTestEfx9AttackAt && npc.IsAlive())
	{
		gmTestEfx9AttackAt = 0;
		GMTestActInput(0, true);
		gmTestEfx9AttackRelease = true;
		LogChannel('GMTest', "INFO EFX-09 a real light attack during its LastBreath at " + NoTrailZeros(RoundTo(now, 2)) + " s, frozen " + npc.HasBuff(EET_Frozen) + ", health " + NoTrailZeros(RoundTo(npc.GetHealth(), 1)));
	}
	if(gmTestEfx9FreezeAt > 0 && now >= gmTestEfx9FreezeAt && npc.IsAlive())
	{
		gmTestEfx9FreezeAt = 0;
		npc.RemoveBuffImmunity(EET_Frozen, 'gmtest');
		GMTestEfx2Freeze(npc, 1);
		LogChannel('GMTest', "INFO EFX-09 frozen during its LastBreath at " + NoTrailZeros(RoundTo(now, 2)) + " s: " + npc.HasBuff(EET_Frozen) + ", health " + NoTrailZeros(RoundTo(npc.GetHealth(), 1)));
	}
	if(gmTestEfx9Alive && !npc.IsAlive())
	{
		gmTestEfx9Alive = false;
		LogChannel('GMTest', "INFO EFX-09 rotfiend dead at " + NoTrailZeros(RoundTo(now, 2)) + " s, " + NoTrailZeros(RoundTo(VecDistance(GetWorldPosition(), npc.GetWorldPosition()), 2)) + " m from Geralt, frozen " + npc.HasBuff(EET_Frozen) + ", tag ExplodeNoDamage " + npc.HasTag('ExplodeNoDamage'));
	}
}

@addMethod(CActor)
function GMTestLastBreathTime() : float
{
	return lastBreathTime;
}

// The death explosion ran (and whether its rotfiend carried the no-damage tag).
@wrapMethod(BTTaskExplodeAtDeath)
function Explode()
{
	var w : W3PlayerWitcher;

	w = GetWitcherPlayer();
	if(w && w.gmTestEfx9Armed)
	{
		w.gmTestEfx9Explosions += 1;
		w.gmTestEfx9ExplodeTagged = GetNPC().HasTag('ExplodeNoDamage');
		LogChannel('GMTest', "INFO EFX-09 the death explosion runs, tag ExplodeNoDamage " + w.gmTestEfx9ExplodeTagged + ", radius " + NoTrailZeros(damageRadius) + ", at " + NoTrailZeros(RoundTo(theGame.GetEngineTimeAsSeconds() - w.gmTestEfx9Start, 2)) + " s");
	}
	wrappedMethod();
}

// Which events reach the explode task (it hears them only while active in the monster's tree).
@wrapMethod(BTTaskExplodeAtDeath)
function OnListenedGameplayEvent(eventName : name) : bool
{
	var w : W3PlayerWitcher;

	w = GetWitcherPlayer();
	if(w && w.gmTestEfx9Armed)
		LogChannel('GMTest', "INFO EFX-09 explode task hears " + eventName + " at " + NoTrailZeros(RoundTo(theGame.GetEngineTimeAsSeconds() - w.gmTestEfx9Start, 2)) + " s (required ability " + requiredAbility + " " + GetNPC().HasAbility(requiredAbility) + ")");
	return wrappedMethod(eventName);
}

// Damage Geralt takes from the rotfiend (its explosion).
@wrapMethod(W3PlayerWitcher)
function OnTakeDamage(action : W3DamageAction)
{
	var attack : W3Action_Attack;
	var attackName : name;

	if(gmTestEfx9Armed && !(action.attacker && action.attacker == GMTestDummy()) && action.processedDmg.vitalityDamage > 0)
		LogChannel('GMTest', "INFO EFX-09 Geralt hit by another source (" + action.GetBuffSourceName() + "): " + NoTrailZeros(RoundTo(action.processedDmg.vitalityDamage, 1)));
	if(gmTestEfx9Armed && action.attacker && action.attacker == GMTestDummy())
	{
		if(action.GetBuffSourceName() == "Explosion")
		{
			gmTestEfx9GeraltHits += 1;
			gmTestEfx9GeraltDamage += action.processedDmg.vitalityDamage;
		}
		else
			gmTestEfx9OtherHits += 1;
		attack = (W3Action_Attack)action;
		if(attack)
			attackName = attack.GetAttackName();
		LogChannel('GMTest', "INFO EFX-09 Geralt hit by the rotfiend (" + action.GetBuffSourceName() + ", attack " + attackName + "): " + NoTrailZeros(RoundTo(action.processedDmg.vitalityDamage, 1)) + " Vitality, at "
			+ NoTrailZeros(RoundTo(theGame.GetEngineTimeAsSeconds() - gmTestEfx9Start, 2)) + " s");
	}
	wrappedMethod(action);
}

function GMTestEfx9Template() : string
{
	return "characters\npc_entities\monsters\rotfiend_lvl1.w2ent";
}

exec function gmtest_efx09_spawn(optional distance : float)
{
	var npc : CNewNPC;

	thePlayer.GMTestDummyClearAll();
	npc = GMTestDummySpawn(GMTestEfx9Template(), 0, distance);
	if(!npc)
		return;
	LogChannel('GMTest', "INFO EFX-09 rotfiend spawned: LastBreath " + npc.HasAbility('LastBreath') + ", PoisonDeath " + npc.HasAbility('PoisonDeath') + ", uses Vitality " + npc.UsesVitality()
		+ ", lastbreath_threshold " + NoTrailZeros(CalculateAttributeValue(npc.GetAttributeValue('lastbreath_threshold'))));
}

// maxHealth: its Vitality; perc: its health as a share of it; freeze: 0 none, 1 the generic freeze (Piercing
// Cold's, by script), 3 Northern Wind 3 (by script), -1 leave as is (a real Piercing Cold Aard or Northern
// Wind throw freezes it next); frostRes: its frost resistance (-3: Piercing Cold always freezes).
exec function gmtest_efx09_a(maxHealth : float, perc : float, freeze : int, optional frostRes : float, optional animate : bool, optional onLastBreath : int)
{
	var w : W3PlayerWitcher;
	var npc : CNewNPC;

	w = GetWitcherPlayer();
	npc = GMTestDummy();
	if(!npc || !npc.IsAlive())
	{
		GMTestReport(false, "EFX-09 no living rotfiend");
		return;
	}
	GMTestDummyNeutral(npc);
	if(npc.UsesEssence())
		GMTestDummySet(npc, 'essence', maxHealth);
	else
		GMTestDummySet(npc, 'vitality', maxHealth);
	GMTestDummySet(npc, 'frost_resistance_perc', frostRes);
	if(npc.UsesEssence())
		npc.ForceSetStat(BCS_Essence, perc * npc.GetStatMax(BCS_Essence));
	else
		npc.ForceSetStat(BCS_Vitality, perc * npc.GetStatMax(BCS_Vitality));
	npc.RemoveTag('ExplodeNoDamage');
	npc.RemoveAllBuffsOfType(EET_Knockdown);
	npc.RemoveAllBuffsOfType(EET_HeavyKnockdown);
	GMTestDummyFreeze(npc);
	if(freeze >= 0)
		GMTestEfx2Freeze(npc, freeze);
	if(freeze == 0)
		npc.AddBuffImmunity(EET_Frozen, 'gmtest', false);
	else
		npc.RemoveBuffImmunity(EET_Frozen, 'gmtest');
	if(freeze == -1)
		GMTestPam().DEBUG_DevelopAndEquipMutation(EPMT_Mutation6);
	if(animate)
		npc.SetAnimationSpeedMultiplier(1);
	w.SetImmortalityMode(AIM_Immortal, AIC_Default, true);
	w.ForceSetStat(BCS_Vitality, w.GetStatMax(BCS_Vitality));
	w.GainStat(BCS_Stamina, 1000);
	w.gmTestEfx9Explosions = 0;
	w.gmTestEfx9ExplodeTagged = false;
	w.gmTestEfx9GeraltHits = 0;
	w.gmTestEfx9GeraltDamage = 0;
	w.gmTestEfx9OtherHits = 0;
	w.gmTestEfx9GeraltHealth = w.GetStat(BCS_Vitality);
	w.gmTestEfx9NpcHealth = npc.GetHealth();
	w.gmTestEfx9Start = theGame.GetEngineTimeAsSeconds();
	w.gmTestEfx9Armed = true;
	w.gmTestEfx9Alive = true;
	w.gmTestEfx9OnLastBreath = onLastBreath;
	w.gmTestEfx9LastBreathSeen = false;
	w.gmTestEfx9FreezeAt = 0;
	w.gmTestEfx9AttackAt = 0;
	w.gmTestEfx9FirstHit = -1;
	w.gmTestEfx9Frozen = npc.HasBuff(EET_Frozen);
	w.gmTestEfx9AttackRelease = false;
	w.gmTestEfx9Health = npc.GetHealth();
	w.RemoveTimer('GMTestEfx9Watch');
	w.AddTimer('GMTestEfx9Watch', 0.05, true);
	LogChannel('GMTest', "INFO EFX-09 setup: rotfiend health " + NoTrailZeros(RoundTo(npc.GetHealth(), 1)) + " of " + NoTrailZeros(RoundTo(npc.GetMaxHealth(), 1)) + " (Essence " + npc.UsesEssence() + ")"
		+ " (" + NoTrailZeros(RoundTo(100 * npc.GetHealthPercents(), 1)) + "%), frozen " + npc.HasBuff(EET_Frozen) + " (" + GMTestEfx2FrozenName(npc) + "), frost resistance " + NoTrailZeros(GMTestDummyRead(npc, 'frost_resistance_perc'))
		+ "; Geralt " + NoTrailZeros(RoundTo(w.GetStat(BCS_Vitality), 1)) + " Vitality, immortal " + w.IsImmortal() + ", distance " + NoTrailZeros(RoundTo(VecDistance(w.GetWorldPosition(), npc.GetWorldPosition()), 2)) + " m");
}

// After the hit (and its explosion): kill expected (the hit killed it), damage expected (its explosion hurt Geralt).
exec function gmtest_efx09_b(expectKill : bool, expectDamage : bool, label : string)
{
	var w : W3PlayerWitcher;
	var npc : CNewNPC;
	var lastBreath : bool;
	var lost : float;

	w = GetWitcherPlayer();
	npc = GMTestDummy();
	lastBreath = npc && npc.GMTestLastBreathTime() >= w.gmTestEfx9Start;
	lost = w.gmTestEfx9GeraltHealth - w.GetStat(BCS_Vitality);
	LogChannel('GMTest', "INFO EFX-09 " + label + ": rotfiend alive " + (npc && npc.IsAlive()) + ", health " + NoTrailZeros(RoundTo(w.gmTestEfx9NpcHealth, 1)) + " -> " + NoTrailZeros(RoundTo(npc.GetHealth(), 1))
		+ ", LastBreath held back a hit " + lastBreath + ", tag ExplodeNoDamage " + npc.HasTag('ExplodeNoDamage') + "; explosions " + w.gmTestEfx9Explosions + "; Geralt hit by its explosion " + w.gmTestEfx9GeraltHits + " times (by its attacks " + w.gmTestEfx9OtherHits + "), "
		+ NoTrailZeros(RoundTo(w.gmTestEfx9GeraltDamage, 1)) + " Vitality, health lost " + NoTrailZeros(RoundTo(lost, 1)));
	if(expectKill)
		GMTestReport(npc && !npc.IsAlive() && !lastBreath, "EFX-09 " + label + ": the hit killed the rotfiend outright (alive " + npc.IsAlive() + ", held back by LastBreath " + lastBreath + ")");
	else
		GMTestReport(lastBreath && w.gmTestEfx9FirstHit <= 0.25 * npc.GetMaxHealth() + 0.5 && w.gmTestEfx9FirstHit >= 0.23 * npc.GetMaxHealth(),
			"EFX-09 " + label + ": LastBreath held the hit back (to " + NoTrailZeros(RoundTo(w.gmTestEfx9FirstHit, 1)) + " of " + NoTrailZeros(RoundTo(npc.GetMaxHealth(), 1)) + ", its threshold 25%, less a first tick of its swelling's drain)");
	if(expectKill && expectDamage)
		GMTestReport(w.gmTestEfx9Explosions == 1 && w.gmTestEfx9GeraltHits > 0 && w.gmTestEfx9GeraltDamage > 0 && lost > 0,
			"EFX-09 " + label + ": its death explosion hurt Geralt (" + NoTrailZeros(RoundTo(w.gmTestEfx9GeraltDamage, 1)) + " Vitality, health lost " + NoTrailZeros(RoundTo(lost, 1)) + ")");
	else if(expectKill)
		GMTestReport(w.gmTestEfx9GeraltHits == 0 && lost <= 0.001 && npc.HasTag('ExplodeNoDamage'),
			"EFX-09 " + label + ": its death explosion (ran " + w.gmTestEfx9Explosions + " times) dealt no damage (Geralt hit " + w.gmTestEfx9GeraltHits + " times, health lost " + NoTrailZeros(RoundTo(lost, 1)) + "; tagged " + npc.HasTag('ExplodeNoDamage') + ")");
	w.gmTestEfx9Armed = false;
	w.SetImmortalityMode(AIM_None, AIC_Default, true);
	w.ForceSetStat(BCS_Vitality, w.GetStatMax(BCS_Vitality));
	if(npc)
		npc.RemoveBuffImmunity(EET_Frozen, 'gmtest');
}

// A freeze added by script mid-test (1 the generic freeze, 3 Northern Wind 3).
exec function gmtest_efx09_freeze(freeze : int)
{
	var npc : CNewNPC;

	npc = GMTestDummy();
	npc.RemoveBuffImmunity(EET_Frozen, 'gmtest');
	GMTestEfx2Freeze(npc, freeze);
	LogChannel('GMTest', "INFO EFX-09 frozen " + npc.HasBuff(EET_Frozen) + " (" + GMTestEfx2FrozenName(npc) + ") at " + NoTrailZeros(RoundTo(theGame.GetEngineTimeAsSeconds() - GetWitcherPlayer().gmTestEfx9Start, 2)) + " s, health " + NoTrailZeros(RoundTo(npc.GetHealth(), 1)));
}

// Restores Geralt (mortal, full health) and removes Mutation 6 and the dummies.
exec function gmtest_efx09_end()
{
	var w : W3PlayerWitcher;

	w = GetWitcherPlayer();
	w.gmTestEfx9Armed = false;
	w.SetImmortalityMode(AIM_None, AIC_Default, true);
	w.ForceSetStat(BCS_Vitality, w.GetStatMax(BCS_Vitality));
	GMTestPam().DEBUG_SetEquippedMutation(EPMT_None);
	thePlayer.GMTestDummyClearAll();
	LogChannel('GMTest', "INFO EFX-09 end: Geralt immortal " + w.IsImmortal() + ", mutation " + GMTestPam().GetEquippedMutationType());
}

// Lets the rotfiend's animations run again (its LastBreath swelling and explosion need them).
exec function gmtest_efx09_unfreeze()
{
	var npc : CNewNPC;
	var buffs : array<CBaseGameplayEffect>;
	var i : int;
	var line : string;

	npc = GMTestDummy();
	npc.SetAnimationSpeedMultiplier(1);
	buffs = npc.GetBuffs();
	for(i = 0; i < buffs.Size(); i += 1)
		line += " " + buffs[i].GetEffectType();
	LogChannel('GMTest', "INFO EFX-09 rotfiend animated at " + NoTrailZeros(RoundTo(theGame.GetEngineTimeAsSeconds() - GetWitcherPlayer().gmTestEfx9Start, 2)) + " s, health " + NoTrailZeros(RoundTo(npc.GetHealth(), 1)) + ", effects:" + line);
}

// Diagnostic: sends the rotfiend's behaviour tree a gameplay event (Death: what its explode task listens to).
// In 5.x the task did not hear Death at any real death in the tests; this is the one way seen to run it.
exec function gmtest_efx09_signal(eventName : name)
{
	var npc : CNewNPC;

	npc = GMTestDummy();
	npc.SignalGameplayEvent(eventName);
	LogChannel('GMTest', "INFO EFX-09 signalled " + eventName + " to the rotfiend (alive " + npc.IsAlive() + ")");
}

// The explosion itself (BTTaskExplodeAtDeath.Explode), run by sending its task Death on a living rotfiend
// (after gmtest_efx09_a), with or without the tag a frozen kill gives; gmtest_efx09_death_b reports.
exec function gmtest_efx09_death(tagged : bool)
{
	var npc : CNewNPC;

	npc = GMTestDummy();
	if(tagged)
		npc.AddTag('ExplodeNoDamage');
	else
		npc.RemoveTag('ExplodeNoDamage');
	npc.SignalGameplayEvent('Death');
}

exec function gmtest_efx09_death_b(tagged : bool)
{
	var w : W3PlayerWitcher;
	var lost : float;

	w = GetWitcherPlayer();
	lost = w.gmTestEfx9GeraltHealth - w.GetStat(BCS_Vitality);
	if(tagged)
		GMTestReport(w.gmTestEfx9Explosions == 1 && w.gmTestEfx9ExplodeTagged && w.gmTestEfx9GeraltHits == 0 && lost <= 0.001,
			"EFX-09 the explosion of a rotfiend tagged ExplodeNoDamage (a frozen kill's) runs (" + w.gmTestEfx9Explosions + ") and deals no damage (Geralt hit " + w.gmTestEfx9GeraltHits + " times, health lost " + NoTrailZeros(RoundTo(lost, 1)) + ")");
	else
		GMTestReport(w.gmTestEfx9Explosions == 1 && !w.gmTestEfx9ExplodeTagged && w.gmTestEfx9GeraltHits == 1 && lost > 0,
			"EFX-09 the explosion of an untagged rotfiend runs (" + w.gmTestEfx9Explosions + ") and hurts Geralt (" + NoTrailZeros(RoundTo(w.gmTestEfx9GeraltDamage, 1) ) + " Vitality, health lost " + NoTrailZeros(RoundTo(lost, 1)) + ")");
	w.gmTestEfx9Armed = false;
	w.SetImmortalityMode(AIM_None, AIC_Default, true);
	w.ForceSetStat(BCS_Vitality, w.GetStatMax(BCS_Vitality));
}
