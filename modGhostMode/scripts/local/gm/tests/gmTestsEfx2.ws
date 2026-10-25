// EFX slice 2's tests (docs/features/efx.md): EFX-02 (hitting a frozen enemy) and EFX-03 (freezing
// pauses damage over time). GMTest_efx02() runs in gmtest_regress().
//
// In play (the neutral test dummy: gmtest_dummy("human"), then gmtest_dummy_neutral()):
//   gmtest_efx02_scripted()            scripted fixed hits on the dummy frozen by the generic freeze
//                                      and by Northern Wind 1: the bonus, no knockdown, the freeze ends
//   gmtest_efx02_aard_a(freeze)        a real Aard cast follows (autocast(ST_Aard)); freeze: 0 none,
//                                      1 the generic freeze (as Piercing Cold adds it), 3 Northern Wind 3,
//                                      -1 leave the dummy as it is (frozen by a real Piercing Cold cast)
//   gmtest_efx02_aard_b()              reads the cast's first hit (the hit probe below)
//   gmtest_efx02_light_a(freeze)       a real light attack follows (gmtest_efx02_light_b, then
//                                      gmtest_efx02_light_c after its hit)
//   exec --wait 15000 "gmtest_efx03(kind, thaw)"  bleeding or poison (or burning), then a freeze at 1 s,
//                                      thawed at 4 s (thaw true: removed; false: left to end), followed
//                                      to the end of the damage over time

@addField(W3PlayerWitcher)
var gmTestEfx2Armed : bool;
@addField(W3PlayerWitcher)
var gmTestEfx2Seen : bool;
@addField(W3PlayerWitcher)
var gmTestEfx2Aard : bool;
@addField(W3PlayerWitcher)
var gmTestEfx2Frozen : bool;
@addField(W3PlayerWitcher)
var gmTestEfx2Bonus : float;
@addField(W3PlayerWitcher)
var gmTestEfx2ForceBefore : float;
@addField(W3PlayerWitcher)
var gmTestEfx2ForceAfter : float;
@addField(W3PlayerWitcher)
var gmTestEfx2RawBefore : float;
@addField(W3PlayerWitcher)
var gmTestEfx2RawAfter : float;
@addField(W3PlayerWitcher)
var gmTestEfx2Knockdowns : int;		// knockdown applicators in the hit's effects, after the increase steps
@addField(W3PlayerWitcher)
var gmTestEfx2KnockdownsIn : int;	// before them (the attack's own)
@addField(W3PlayerWitcher)
var gmTestEfx2MaxHealth : float;
@addField(W3PlayerWitcher)
var gmTestEfx2Health : float;
@addField(W3PlayerWitcher)
var gmTestEfx2Mode : int;

function GMTestEfx2Force(dmgInfos : array< SRawDamage >, out sum : float) : float
{
	var i : int;
	var force : float;

	sum = 0;
	for(i = 0; i < dmgInfos.Size(); i += 1)
	{
		sum += dmgInfos[i].dmgVal;
		if(dmgInfos[i].dmgType == theGame.params.DAMAGE_NAME_FORCE)
			force += dmgInfos[i].dmgVal;
	}
	return force;
}

function GMTestEfx2Knockdowns(action : W3DamageAction) : int
{
	var effects : array< SEffectInfo >;
	var i, n : int;

	action.GetEffects(effects);
	for(i = 0; i < effects.Size(); i += 1)
		if(effects[i].effectType == EET_KnockdownTypeApplicator || effects[i].effectType == EET_Knockdown || effects[i].effectType == EET_HeavyKnockdown)
			n += 1;
	return n;
}

// The hit probe: the first hit of Geralt's on the test dummy after arming (gmtest_efx02_*_a), before and
// after the increase steps (the pool, the frozen bonus, Aard's force damage).
@wrapMethod(W3DamageManagerProcessor)
function ProcessDamageIncrease(out dmgInfos : array< SRawDamage >)
{
	var w : W3PlayerWitcher;
	var frozenBuff : W3Effect_Frozen;
	var sum : float;
	var record : bool;

	w = GetWitcherPlayer();
	record = w && w.gmTestEfx2Armed && !w.gmTestEfx2Seen && playerAttacker && actorVictim && actorVictim == GMTestDummy();
	if(record)
	{
		w.gmTestEfx2Aard = false;
		if((W3AardProjectile)action.causer || (W3AardEntity)action.causer)
			w.gmTestEfx2Aard = true;
		w.gmTestEfx2Frozen = actorVictim.HasBuff(EET_Frozen);
		frozenBuff = (W3Effect_Frozen)actorVictim.GetBuff(EET_Frozen);
		w.gmTestEfx2Bonus = 0;
		if(frozenBuff)
			w.gmTestEfx2Bonus = frozenBuff.GetAdditionalDamagePercents();
		w.gmTestEfx2ForceBefore = GMTestEfx2Force(dmgInfos, sum);
		w.gmTestEfx2RawBefore = sum;
		w.gmTestEfx2KnockdownsIn = GMTestEfx2Knockdowns(action);
		w.gmTestEfx2MaxHealth = actorVictim.GetMaxHealth();
	}
	wrappedMethod(dmgInfos);
	if(record)
		w.gmTestEfx2Seen = true;
}

@wrapMethod(W3DamageManagerProcessor)
function ProcessNewSkills_Combat(out dmgInfos : array< SRawDamage >)
{
	var w : W3PlayerWitcher;
	var sum : float;

	wrappedMethod(dmgInfos);
	w = GetWitcherPlayer();
	if(w && w.gmTestEfx2Armed && w.gmTestEfx2Seen)
	{
		w.gmTestEfx2Armed = false;
		w.gmTestEfx2ForceAfter = GMTestEfx2Force(dmgInfos, sum);
		w.gmTestEfx2RawAfter = sum;
		w.gmTestEfx2Knockdowns = GMTestEfx2Knockdowns(action);
	}
}

function GMTestEfx2Arm()
{
	var w : W3PlayerWitcher;

	w = GetWitcherPlayer();
	w.gmTestEfx2Armed = true;
	w.gmTestEfx2Seen = false;
	w.gmTestEfx2ForceBefore = 0;
	w.gmTestEfx2ForceAfter = 0;
	w.gmTestEfx2RawBefore = 0;
	w.gmTestEfx2RawAfter = 0;
	w.gmTestEfx2Knockdowns = 0;
	w.gmTestEfx2KnockdownsIn = 0;
}

// The generic freeze as Piercing Cold adds it (AddEffectDefault: the FrozenEffect ability).
function GMTestEfx2FreezeGeneric(npc : CActor) : CBaseGameplayEffect
{
	npc.RemoveAllBuffsOfType(EET_Frozen);
	npc.AddEffectDefault(EET_Frozen, thePlayer, "Mutation 6", true);
	return npc.GetBuff(EET_Frozen);
}

function GMTestEfx2Freeze(npc : CNewNPC, freeze : int)
{
	if(freeze == 1)
		GMTestEfx2FreezeGeneric(npc);
	else if(freeze > 1)
	{
		npc.RemoveAllBuffsOfType(EET_Frozen);
		GMTestAlch14Freeze(npc, 'FrozenEffect_WhiteFrost3');
	}
	else if(freeze == 0)
		npc.RemoveAllBuffsOfType(EET_Frozen);
}

function GMTestEfx2FrozenName(npc : CActor) : name
{
	var buff : CBaseGameplayEffect;

	buff = npc.GetBuff(EET_Frozen);
	if(buff)
		return buff.GetAbilityName();
	return '';
}

function GMTestEfx2NoKnockdown(npc : CActor) : bool
{
	return !npc.HasBuff(EET_Knockdown) && !npc.HasBuff(EET_HeavyKnockdown) && !npc.HasBuff(EET_KnockdownTypeApplicator);
}

exec function gmtest_efx02()
{
	GMTest_efx02();
}

// EFX-02's data and EFX-03's pause on Geralt's own effect manager (situation-free).
function GMTest_efx02()
{
	var w : W3PlayerWitcher;
	var buff : CBaseGameplayEffect;
	var vit, left1, left2 : float;
	var params : SCustomEffectParams;
	var types : array<EEffectType>;
	var kept : array<SGMTestEfxSavedBuff>;

	types.PushBack(EET_Bleeding); types.PushBack(EET_SlowdownFrost); types.PushBack(EET_DoTHPRegenReduce);
	kept = GMTestEfxSaveBuffs(types);
	GMTestEfxMinMax('FrozenEffect', 'duration', 5, "EFX-02 the generic freeze");
	GMTestAbilityValue('FrozenEffect', 'hpPercDamageBonusPerHit', 0.5);
	GMTestAbilityValue('FrozenEffect_WhiteFrost3', 'hpPercDamageBonusPerHit', 0.5);	// Northern Wind's own (ALCH-14), untouched
	GMTestEfxMinMax('FrozenEffect_WhiteFrost1', 'duration', 4, "EFX-02 Northern Wind 1's freeze (5.x's, untouched)");

	// EFX-03: PauseAllDoTEffects pauses a damage over time by its source and ResumeAllDoTEffects lifts it;
	// a non-damage effect is left alone.
	w = GetWitcherPlayer();
	vit = w.GetStat(BCS_Vitality);
	w.RemoveAllBuffsOfType(EET_Bleeding);
	params.effectType = EET_Bleeding;
	params.creator = thePlayer;
	params.sourceName = "GMTest";
	params.duration = 20;
	w.AddEffectCustom(params);
	w.AddEffectDefault(EET_SlowdownFrost, thePlayer, "GMTest");
	buff = w.GetBuff(EET_Bleeding);
	if(!buff)
		GMTestReport(false, "EFX-03 a bleeding on Geralt (setup)");
	else
	{
		w.GMTestEffectManager().PauseAllDoTEffects('GMTestEfx03');
		GMTestReport(buff.IsPaused('GMTestEfx03') && !w.GetBuff(EET_SlowdownFrost).IsPaused('GMTestEfx03'),
			"EFX-03 PauseAllDoTEffects: Geralt's bleeding paused " + buff.IsPaused('GMTestEfx03') + ", his frost slowdown (not damage over time) paused " + w.GetBuff(EET_SlowdownFrost).IsPaused('GMTestEfx03'));
		w.GMTestEffectManager().ResumeAllDoTEffects('GMTestEfx03');
		GMTestReport(!buff.IsPaused('GMTestEfx03') && !buff.IsPaused(), "EFX-03 ResumeAllDoTEffects: the bleeding paused " + buff.IsPaused());
	}
	GMTestEfxRestoreBuffs(types, kept);
	w.ForceSetStat(BCS_Vitality, vit);
}

// Scripted fixed hits (physical 100, not melee: no random factor) on the frozen dummy.
exec function gmtest_efx02_scripted()
{
	var npc : CNewNPC;
	var buff : CBaseGameplayEffect;
	var base, frozen, lost : float;
	var i : int;
	var label : string;
	var bonus : float;

	npc = GMTestDummy();
	if(!npc)
	{
		GMTestReport(false, "EFX-02 no test dummy");
		return;
	}
	GMTestDummyFreeze(npc);
	npc.RemoveBuffImmunity(EET_Knockdown, 'gmtest');
	npc.RemoveBuffImmunity(EET_HeavyKnockdown, 'gmtest');
	npc.RemoveAllBuffsOfType(EET_Frozen);
	base = GMTestAlch14FixedHit(npc, lost);
	for(i = 0; i < 2; i += 1)
	{
		if(i == 0)
		{
			label = "the generic freeze";
			bonus = 0.5;
			buff = GMTestEfx2FreezeGeneric(npc);
			GMTestReport(buff && buff.GetAbilityName() == 'FrozenEffect' && AbsF(buff.GetInitialDurationAfterResists() - 5) < 0.01,
				"EFX-02 the generic freeze (as Piercing Cold adds it): ability " + buff.GetAbilityName() + ", lasts " + NoTrailZeros(buff.GetInitialDurationAfterResists()) + " s (expected 5; 5.x: 4)");
		}
		else
		{
			label = "Northern Wind 1";
			bonus = 0.25;
			GMTestAlch14Freeze(npc, 'FrozenEffect_WhiteFrost1');
		}
		frozen = GMTestAlch14FixedHit(npc, lost);
		GMTestReport(base > 0 && AbsF(frozen / base - 1 - bonus) < 0.01 && !npc.HasBuff(EET_Frozen),
			"EFX-02 " + label + ": the shattering hit " + NoTrailZeros(RoundTo(base, 1)) + " -> " + NoTrailZeros(RoundTo(frozen, 1)) + " (x" + NoTrailZeros(RoundTo(frozen / base, 3))
			+ ", expected x" + NoTrailZeros(1 + bonus) + "), frozen after it " + npc.HasBuff(EET_Frozen));
		GMTestReport(GMTestEfx2NoKnockdown(npc), "EFX-02 " + label + ": no knockdown after the shattering hit (knockdown " + npc.HasBuff(EET_Knockdown) + ", heavy " + npc.HasBuff(EET_HeavyKnockdown) + "; 5.x: a knockdown roll)");
		npc.RemoveAllBuffsOfType(EET_Knockdown);
		npc.RemoveAllBuffsOfType(EET_HeavyKnockdown);
		GMTestDummyFreeze(npc);
	}
}

// A real Aard cast at the dummy: setup, then autocast(ST_Aard), then gmtest_efx02_aard_b(). The dummy is
// made immune to knockdowns (Aard's own roll would floor it, which on the frozen dummy never ends, and a
// knocked-down dummy that Piercing Cold freezes dies); the probe counts the knockdowns in the hit instead.
exec function gmtest_efx02_aard_a(freeze : int)
{
	var w : W3PlayerWitcher;
	var npc : CNewNPC;

	w = GetWitcherPlayer();
	npc = GMTestDummy();
	if(!npc)
	{
		GMTestReport(false, "EFX-02 no test dummy");
		return;
	}
	npc.RemoveAllBuffsOfType(EET_Knockdown);
	npc.RemoveAllBuffsOfType(EET_HeavyKnockdown);
	npc.AddBuffImmunity(EET_Knockdown, 'gmtest', false);
	npc.AddBuffImmunity(EET_HeavyKnockdown, 'gmtest', false);
	GMTestDummyFreeze(npc);
	GMTestDummyHeal(npc);
	GMTestEfx2Freeze(npc, freeze);
	w.gmTestEfx2Health = npc.GetHealth();
	w.GainStat(BCS_Stamina, 1000);
	GMTestEfx2Arm();
	thePlayer.GMTestSetProbes(true);
	thePlayer.GMTestDmgReset();
	LogChannel('GMTest', "INFO EFX-02 Aard setup: frozen " + npc.HasBuff(EET_Frozen) + " (" + GMTestEfx2FrozenName(npc) + "), Piercing Cold " + w.IsMutationActive(EPMT_Mutation6) + ", health " + NoTrailZeros(RoundTo(w.gmTestEfx2Health, 1)));
}

exec function gmtest_efx02_aard_b()
{
	var w : W3PlayerWitcher;
	var npc : CNewNPC;
	var expected : float;
	var steps : array<SGMTestDmgStep>;
	var i, forceIdx : int;

	w = GetWitcherPlayer();
	npc = GMTestDummy();
	forceIdx = -1;
	LogChannel('GMTest', "INFO EFX-02 Aard hit: seen " + w.gmTestEfx2Seen + ", Aard " + w.gmTestEfx2Aard + ", frozen " + w.gmTestEfx2Frozen + " (bonus " + NoTrailZeros(w.gmTestEfx2Bonus)
		+ "), force " + NoTrailZeros(RoundTo(w.gmTestEfx2ForceBefore, 2)) + " -> " + NoTrailZeros(RoundTo(w.gmTestEfx2ForceAfter, 2)) + ", all raw " + NoTrailZeros(RoundTo(w.gmTestEfx2RawBefore, 2)) + " -> " + NoTrailZeros(RoundTo(w.gmTestEfx2RawAfter, 2))
		+ ", knockdowns in the hit " + w.gmTestEfx2KnockdownsIn + " -> " + w.gmTestEfx2Knockdowns + ", max health " + NoTrailZeros(w.gmTestEfx2MaxHealth) + ", health lost " + NoTrailZeros(RoundTo(w.gmTestEfx2Health - npc.GetHealth(), 1))
		+ "; now frozen " + npc.HasBuff(EET_Frozen));
	if(!w.gmTestEfx2Seen || !w.gmTestEfx2Aard)
	{
		GMTestReport(false, "EFX-02 Aard: no Aard hit on the dummy recorded");
		return;
	}
	if(w.gmTestEfx2Frozen)
		expected = w.gmTestEfx2ForceBefore * (1 + w.gmTestEfx2Bonus) + 0.05 * w.gmTestEfx2MaxHealth;
	else
		expected = w.gmTestEfx2ForceBefore;
	GMTestReport(AbsF(w.gmTestEfx2ForceAfter - expected) < 0.5 && (!w.gmTestEfx2Frozen || w.gmTestEfx2Bonus > 0),
		"EFX-02 a real Aard on the dummy, frozen " + w.gmTestEfx2Frozen + ": force damage " + NoTrailZeros(RoundTo(w.gmTestEfx2ForceBefore, 2)) + " -> " + NoTrailZeros(RoundTo(w.gmTestEfx2ForceAfter, 2))
		+ " (expected " + NoTrailZeros(RoundTo(expected, 2)) + ": x(1 + " + NoTrailZeros(w.gmTestEfx2Bonus) + ") + 5% of " + NoTrailZeros(w.gmTestEfx2MaxHealth) + " when frozen)");
	GMTestReport(w.gmTestEfx2Knockdowns == w.gmTestEfx2KnockdownsIn,
		"EFX-02 a real Aard, frozen " + w.gmTestEfx2Frozen + ": knockdowns in the hit " + w.gmTestEfx2Knockdowns + ", Aard's own " + w.gmTestEfx2KnockdownsIn + " (5.x: one more on a frozen target)");
	// The damage probe's steps: the first force step is the Aard hit's (Piercing Cold's own hit comes later).
	steps = thePlayer.gmTestDmgSteps;
	for(i = 0; i < steps.Size(); i += 1)
	{
		LogChannel('GMTest', "INFO step " + i + ": " + steps[i].dmgType + " raw " + NoTrailZeros(RoundTo(steps[i].rawIn, 2)) + ", resistance " + NoTrailZeros(steps[i].pts) + " pts " + NoTrailZeros(steps[i].perc)
			+ ", power x" + NoTrailZeros(steps[i].mult) + " + " + NoTrailZeros(steps[i].add) + " base " + NoTrailZeros(steps[i].base) + " -> " + NoTrailZeros(RoundTo(steps[i].result, 2)) + " (hits the stat " + steps[i].hitsStat + ")");
		if(forceIdx < 0 && steps[i].dmgType == theGame.params.DAMAGE_NAME_FORCE)
			forceIdx = i;
	}
	if(w.gmTestEfx2Frozen)
		GMTestReport(forceIdx >= 0 && AbsF(steps[forceIdx].rawIn - w.gmTestEfx2ForceAfter) < 0.5 && steps[forceIdx].result > 0,
			"EFX-02 a real Aard shattering the freeze: its force damage " + NoTrailZeros(RoundTo(steps[forceIdx].rawIn, 1)) + " reaches the formula, deals " + NoTrailZeros(RoundTo(steps[forceIdx].result, 1)) + " (power x" + NoTrailZeros(steps[forceIdx].mult) + "); the dummy lost " + NoTrailZeros(RoundTo(w.gmTestEfx2Health - npc.GetHealth(), 1)));
	thePlayer.GMTestSetProbes(false);
	npc.RemoveBuffImmunity(EET_Knockdown, 'gmtest');
	npc.RemoveBuffImmunity(EET_HeavyKnockdown, 'gmtest');
	GMTestDummyFreeze(npc);
}

// A real light attack at the dummy (sword drawn, locked on): setup, gmtest_efx02_light_b() presses and
// releases the attack, gmtest_efx02_light_c() after its hit reads it.
exec function gmtest_efx02_light_a(freeze : int)
{
	var w : W3PlayerWitcher;
	var npc : CNewNPC;

	w = GetWitcherPlayer();
	npc = GMTestDummy();
	npc.RemoveAllBuffsOfType(EET_Knockdown);
	npc.RemoveAllBuffsOfType(EET_HeavyKnockdown);
	npc.RemoveBuffImmunity(EET_Knockdown, 'gmtest');
	npc.RemoveBuffImmunity(EET_HeavyKnockdown, 'gmtest');
	GMTestDummyFreeze(npc);
	GMTestDummyHeal(npc);
	GMTestEfx2Freeze(npc, freeze);
	w.gmTestEfx2Health = npc.GetHealth();
	w.GainStat(BCS_Stamina, 1000);
	GMTestEfx2Arm();
	LogChannel('GMTest', "INFO EFX-02 light attack setup: frozen " + npc.HasBuff(EET_Frozen) + " (" + GMTestEfx2FrozenName(npc) + ")");
}

exec function gmtest_efx02_light_b()
{
	GMTestActInput(0, true);
	GMTestActInput(0, false);
}

exec function gmtest_efx02_light_c(freeze : int)
{
	var w : W3PlayerWitcher;
	var npc : CNewNPC;
	var ratio, bonus : float;

	w = GetWitcherPlayer();
	npc = GMTestDummy();
	if(w.gmTestEfx2RawBefore > 0)
		ratio = w.gmTestEfx2RawAfter / w.gmTestEfx2RawBefore;
	LogChannel('GMTest', "INFO EFX-02 light attack: seen " + w.gmTestEfx2Seen + ", frozen " + w.gmTestEfx2Frozen + " (bonus " + NoTrailZeros(w.gmTestEfx2Bonus) + "), raw " + NoTrailZeros(RoundTo(w.gmTestEfx2RawBefore, 2)) + " -> " + NoTrailZeros(RoundTo(w.gmTestEfx2RawAfter, 2))
		+ ", knockdowns in the hit " + w.gmTestEfx2KnockdownsIn + " -> " + w.gmTestEfx2Knockdowns + ", health lost " + NoTrailZeros(RoundTo(w.gmTestEfx2Health - npc.GetHealth(), 1)) + "; knockdown now " + !GMTestEfx2NoKnockdown(npc) + ", frozen " + npc.HasBuff(EET_Frozen));
	if(freeze == 1) bonus = 0.5; else if(freeze > 1) bonus = 0.5; else bonus = 0;
	GMTestReport(w.gmTestEfx2Seen && w.gmTestEfx2Frozen == (freeze != 0) && AbsF(w.gmTestEfx2Bonus - bonus) < 0.001 && ratio >= 1 + bonus - 0.001,
		"EFX-02 a real light attack, frozen " + w.gmTestEfx2Frozen + ": raw damage x" + NoTrailZeros(RoundTo(ratio, 3)) + " by the increase steps (the frozen bonus " + NoTrailZeros(w.gmTestEfx2Bonus) + ", expected " + NoTrailZeros(bonus) + ")");
	GMTestReport(w.gmTestEfx2Knockdowns == w.gmTestEfx2KnockdownsIn && GMTestEfx2NoKnockdown(npc) && !npc.HasBuff(EET_Frozen),
		"EFX-02 a real light attack, frozen " + w.gmTestEfx2Frozen + ": no knockdown (in the hit " + w.gmTestEfx2Knockdowns + ", on the dummy " + !GMTestEfx2NoKnockdown(npc) + "), the freeze ended " + !npc.HasBuff(EET_Frozen));
	GMTestDummyHeal(npc);
	GMTestDummyFreeze(npc);
}

// ---- EFX-03 --------------------------------------------------------------------------------------------

@addField(W3PlayerWitcher)
var gmTestEfx3Type : EEffectType;
@addField(W3PlayerWitcher)
var gmTestEfx3Start : float;
@addField(W3PlayerWitcher)
var gmTestEfx3Phase : int;
@addField(W3PlayerWitcher)
var gmTestEfx3Thaw : bool;
@addField(W3PlayerWitcher)
var gmTestEfx3MaxHealth : float;
@addField(W3PlayerWitcher)
var gmTestEfx3Rate : float;
@addField(W3PlayerWitcher)
var gmTestEfx3Duration : float;
@addField(W3PlayerWitcher)
var gmTestEfx3FreezeAt : float;
@addField(W3PlayerWitcher)
var gmTestEfx3ThawAt : float;
@addField(W3PlayerWitcher)
var gmTestEfx3LostFreeze : float;
@addField(W3PlayerWitcher)
var gmTestEfx3LeftFreeze : float;
@addField(W3PlayerWitcher)
var gmTestEfx3LostLast : float;
@addField(W3PlayerWitcher)
var gmTestEfx3LeftLast : float;
@addField(W3PlayerWitcher)
var gmTestEfx3Seen : float;
@addField(W3PlayerWitcher)
var gmTestEfx3Lost : float;

function GMTestEfx3Lost(npc : CNewNPC) : float
{
	var w : W3PlayerWitcher;

	w = GetWitcherPlayer();
	if(npc.UsesEssence())
		return w.gmTestEfx3MaxHealth - npc.GetStat(BCS_Essence);
	return w.gmTestEfx3MaxHealth - npc.GetStat(BCS_Vitality);
}

exec function gmtest_efx03(kind : string, thaw : bool)
{
	var w : W3PlayerWitcher;
	var npc : CNewNPC;
	var params : SCustomEffectParams;
	var buff : CBaseGameplayEffect;
	var v : SAbilityAttributeValue;

	w = GetWitcherPlayer();
	npc = GMTestDummy();
	if(!npc)
	{
		GMTestReport(false, "EFX-03 no test dummy");
		return;
	}
	w.RemoveTimer('GMTestEfx3Watch');
	GMTestDummyFreeze(npc);
	npc.RemoveAllBuffsOfType(EET_Frozen);
	params.creator = thePlayer;
	params.sourceName = "GMTest";
	if(kind == "bleeding")
		params.effectType = EET_Bleeding;
	else if(kind == "poison")
		params.effectType = EET_Poison;
	else if(kind == "burning")
		params.effectType = EET_Burning;
	else
	{
		GMTestReport(false, "EFX-03 unknown kind " + kind);
		return;
	}
	npc.RemoveAllBuffsOfType(params.effectType);
	npc.RemoveAllBuffsOfType(EET_DoTHPRegenReduce);
	GMTestDummyHeal(npc);
	w.gmTestEfx3MaxHealth = npc.GetMaxHealth();
	npc.AddEffectCustom(params);
	buff = npc.GetBuff(params.effectType);
	if(!buff)
	{
		GMTestReport(false, "EFX-03 " + kind + ": the effect did not take on the dummy");
		return;
	}
	v = buff.GMTestEffectValue();
	w.gmTestEfx3Type = params.effectType;
	w.gmTestEfx3Start = theGame.GetEngineTimeAsSeconds();
	w.gmTestEfx3Phase = 0;
	w.gmTestEfx3Thaw = thaw;
	w.gmTestEfx3Rate = v.valueMultiplicative;
	w.gmTestEfx3Duration = buff.GetInitialDurationAfterResists();
	w.gmTestEfx3Seen = 0;
	LogChannel('GMTest', "INFO EFX-03 " + kind + " on the dummy: " + NoTrailZeros(w.gmTestEfx3Rate * 100) + "% per second for " + NoTrailZeros(w.gmTestEfx3Duration) + " s; freeze at 1 s, " + thaw + " (thawed at 4 s) / false (left to end)");
	w.AddTimer('GMTestEfx3Watch', 0.1, true);
}

@addMethod(W3PlayerWitcher)
timer function GMTestEfx3Watch(dt : float, id : int)
{
	var npc : CNewNPC;
	var buff, frozen : CBaseGameplayEffect;
	var elapsed, lost, expected, frozenTime : float;

	npc = GMTestDummy();
	if(!npc)
	{
		RemoveTimer('GMTestEfx3Watch');
		return;
	}
	elapsed = theGame.GetEngineTimeAsSeconds() - gmTestEfx3Start;
	buff = npc.GetBuff(gmTestEfx3Type);
	lost = GMTestEfx3Lost(npc);
	if(gmTestEfx3Phase == 0 && elapsed >= 1)
	{
		gmTestEfx3Phase = 1;
		frozen = GMTestEfx2FreezeGeneric(npc);
		gmTestEfx3FreezeAt = elapsed;
		gmTestEfx3LostFreeze = lost;
		buff = npc.GetBuff(gmTestEfx3Type);
		if(gmTestEfx3Type == EET_Burning)
		{
			// FrozenEffect overrides BurningEffect (effects.xml, 1.32 and legacy alike): the freeze ends it.
			GMTestReport(frozen && !buff, "EFX-03 burning: the freeze ends it (FrozenEffect overrides BurningEffect, 1.32's and legacy's data): frozen " + npc.HasBuff(EET_Frozen) + ", burning left " + npc.HasBuff(EET_Burning));
			RemoveTimer('GMTestEfx3Watch');
			npc.RemoveAllBuffsOfType(EET_Frozen);
			GMTestDummyHeal(npc);
			GMTestDummyFreeze(npc);
			return;
		}
		gmTestEfx3LeftFreeze = buff.GetDurationLeft();
		gmTestEfx3LostLast = lost;
		gmTestEfx3LeftLast = gmTestEfx3LeftFreeze;
		GMTestReport(frozen && buff && buff.IsPaused('FrozenEffect'), "EFX-03 the freeze pauses the " + gmTestEfx3Type + ": paused " + buff.IsPaused('FrozenEffect') + " at " + NoTrailZeros(RoundTo(elapsed, 2)) + " s, " + NoTrailZeros(RoundTo(gmTestEfx3LeftFreeze, 2)) + " s left");
	}
	else if(gmTestEfx3Phase == 1)
	{
		frozen = npc.GetBuff(EET_Frozen);
		if(frozen && buff)
		{
			// the last sample while still frozen (a freeze that ends on its own is seen a frame late)
			gmTestEfx3LostLast = lost;
			gmTestEfx3LeftLast = buff.GetDurationLeft();
		}
		if((gmTestEfx3Thaw && elapsed >= 4) || !frozen || elapsed >= 10)
		{
			gmTestEfx3Phase = 2;
			gmTestEfx3ThawAt = elapsed;
			frozenTime = elapsed - gmTestEfx3FreezeAt;
			GMTestReport(buff && gmTestEfx3LostLast - gmTestEfx3LostFreeze < gmTestEfx3MaxHealth * 0.001 && AbsF(gmTestEfx3LeftLast - gmTestEfx3LeftFreeze) < 0.05,
				"EFX-03 while frozen " + NoTrailZeros(RoundTo(frozenTime, 2)) + " s: the " + gmTestEfx3Type + " dealt " + NoTrailZeros(RoundTo(gmTestEfx3LostLast - gmTestEfx3LostFreeze, 1)) + " (max health " + NoTrailZeros(gmTestEfx3MaxHealth) + "), time left " + NoTrailZeros(RoundTo(gmTestEfx3LeftFreeze, 2)) + " -> " + NoTrailZeros(RoundTo(gmTestEfx3LeftLast, 2)) + " s (the last sample while frozen)");
			if(frozen && gmTestEfx3Thaw)
				npc.RemoveAllBuffsOfType(EET_Frozen);
			else if(frozen)
			{
				LogChannel('GMTest', "INFO EFX-03 the freeze did not end on its own by " + NoTrailZeros(RoundTo(elapsed, 2)) + " s (" + NoTrailZeros(RoundTo(frozen.GetDurationLeft(), 2)) + " s left: a long freeze, or a critical effect outlasting its time on the frozen dummy, EFX-06); removed");
				npc.RemoveAllBuffsOfType(EET_Frozen);
			}
			else
				LogChannel('GMTest', "INFO EFX-03 the freeze ended on its own after " + NoTrailZeros(RoundTo(frozenTime, 2)) + " s");
			GMTestDummyFreeze(npc);
			buff = npc.GetBuff(gmTestEfx3Type);
			GMTestReport(buff && !buff.IsPaused(), "EFX-03 the thaw resumes the " + gmTestEfx3Type + ": paused " + (buff && buff.IsPaused()));
		}
	}
	else if(gmTestEfx3Phase == 2)
	{
		if(buff && elapsed < 30)
		{
			gmTestEfx3Seen = elapsed;
			gmTestEfx3Lost = lost;
			return;
		}
		RemoveTimer('GMTestEfx3Watch');
		frozenTime = gmTestEfx3ThawAt - gmTestEfx3FreezeAt;
		expected = gmTestEfx3Rate * gmTestEfx3Duration * gmTestEfx3MaxHealth;
		GMTestReport(AbsF(lost - expected) < expected * 0.05, "EFX-03 the " + gmTestEfx3Type + " in all: " + NoTrailZeros(RoundTo(lost, 1)) + " = " + NoTrailZeros(RoundTo(lost / gmTestEfx3MaxHealth * 100, 2)) + "% of max health (expected " + NoTrailZeros(RoundTo(gmTestEfx3Rate * gmTestEfx3Duration * 100, 2)) + "%: nothing lost to the freeze)");
		GMTestReport(AbsF(gmTestEfx3Seen - gmTestEfx3Duration - frozenTime) < 0.5, "EFX-03 the " + gmTestEfx3Type + " active until " + NoTrailZeros(RoundTo(gmTestEfx3Seen, 2)) + " s (expected its " + NoTrailZeros(gmTestEfx3Duration) + " s plus the " + NoTrailZeros(RoundTo(frozenTime, 2)) + " s frozen)");
		npc.RemoveAllBuffsOfType(EET_DoTHPRegenReduce);
		GMTestDummyHeal(npc);
		GMTestDummyFreeze(npc);
	}
}
