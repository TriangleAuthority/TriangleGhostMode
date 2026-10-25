// EFX slice 3's tests (docs/features/efx.md): EFX-04 damage-over-time ticks, EFX-06 critical
// effects end on time. GMTest_efx04() runs in gmtest_regress().
//
// In play (the neutral test dummy, see gmTestsEfx.ws):
//   gmtest_efx04_calc()        the tick on the dummy (a Vitality or an Essence body), with made-up
//                              maximums of the other stat
//   gmtest_efx01_apply(...)    a whole effect, its ticks and its end (gmTestsEfx.ws)
//   gmtest_efx06_watch()       then real casts (autocast(ST_Aard)): follows every critical effect the
//                              dummy gets and reports how long each lasted against its time

// The tick of a damage-over-time effect, as its OnUpdate computes it (damage entry i).
@addMethod(W3DamageOverTimeEffect)
function GMTestCalcDamage(i : int, maxVit : float, maxEss : float, dt : float) : float
{
	return CalculateDamage(i, maxVit, maxEss, dt);
}

@addMethod(W3DamageOverTimeEffect)
function GMTestDamageFlags(i : int) : string
{
	if(i >= damages.Size())
		return "none";
	return "" + damages[i].damageTypeName + " vitality " + damages[i].hitsVitality + " essence " + damages[i].hitsEssence;
}

// One tick of dt, with the time left set first (0: expired).
@addMethod(W3DamageOverTimeEffect)
function GMTestTick(left : float, dt : float)
{
	var keep : float;

	keep = timeLeft;
	timeLeft = left;
	OnUpdate(dt);
	timeLeft = keep;
}

@addMethod(W3EffectManager)
function GMTestCachedDamages() : int
{
	return cachedDamages.Size();
}

// Drops the cached damages from index from on (a test tick's, before the manager deals them).
@addMethod(W3EffectManager)
function GMTestDropCachedDamages(from : int)
{
	while(cachedDamages.Size() > from)
		cachedDamages.Erase(cachedDamages.Size() - 1);
}

// The ticks of one effect on target, for a target using vitality (or essence): only the used stat's
// maximum counts, at least 1 per second.
function GMTestEfx04Ticks(target : CActor, dot : W3DamageOverTimeEffect, rate : float, label : string)
{
	var used, other, got, expected : float;

	used = 1000;
	other = 5000;	// a larger maximum of the stat the target does not use: 1.32 and 5.x took it
	if(target.UsesEssence())
		got = dot.GMTestCalcDamage(0, other, used, 1);
	else
		got = dot.GMTestCalcDamage(0, used, other, 1);
	expected = rate * used;
	GMTestReport(AbsF(got - expected) < 0.001, "EFX-04 " + label + ": a 1 s tick with max " + NoTrailZeros(used) + " of the stat it uses and " + NoTrailZeros(other)
		+ " of the other deals " + NoTrailZeros(got) + " (expected " + NoTrailZeros(expected) + "; 5.x: " + NoTrailZeros(rate * other) + ")");

	used = 50;	// rate x 50 < 1 per second
	if(target.UsesEssence())
		got = dot.GMTestCalcDamage(0, 0, used, 1);
	else
		got = dot.GMTestCalcDamage(0, used, 0, 1);
	GMTestReport(AbsF(got - 1) < 0.001, "EFX-04 " + label + ": max health 50, a 1 s tick deals " + NoTrailZeros(got) + " (raw " + NoTrailZeros(rate * used) + "; at least 1 per second)");
	if(target.UsesEssence())
		got = dot.GMTestCalcDamage(0, 0, used, 0.25);
	else
		got = dot.GMTestCalcDamage(0, used, 0, 0.25);
	GMTestReport(AbsF(got - 0.25) < 0.001, "EFX-04 " + label + ": max health 50, a 0.25 s tick deals " + NoTrailZeros(got) + " (expected 0.25)");
	used = 5000;
	if(target.UsesEssence())
		got = dot.GMTestCalcDamage(0, 0, used, 0.1);
	else
		got = dot.GMTestCalcDamage(0, used, 0, 0.1);
	expected = rate * used * 0.1;
	GMTestReport(AbsF(got - expected) < 0.001, "EFX-04 " + label + ": max health 5000, a 0.1 s tick deals " + NoTrailZeros(got) + " (expected " + NoTrailZeros(expected) + ": the floor does not raise larger ticks)");
}

exec function gmtest_efx04()
{
	GMTest_efx04();
}

// EFX-04 and EFX-06's tick check, on a bleeding added to Geralt and removed in the same frame
// (situation-free).
function GMTest_efx04()
{
	var params : SCustomEffectParams;
	var dot : W3DamageOverTimeEffect;
	var mgr : W3EffectManager;
	var before, after : int;
	var types : array<EEffectType>;
	var kept : array<SGMTestEfxSavedBuff>;

	types.PushBack(EET_Bleeding); types.PushBack(EET_DoTHPRegenReduce);
	kept = GMTestEfxSaveBuffs(types);
	thePlayer.RemoveAllBuffsOfType(EET_Bleeding);
	params.effectType = EET_Bleeding;
	params.creator = thePlayer;
	params.sourceName = "GMTest";
	thePlayer.AddEffectCustom(params);
	dot = (W3DamageOverTimeEffect)thePlayer.GetBuff(EET_Bleeding);
	if(!dot)
	{
		GMTestReport(false, "EFX-04 a bleeding on Geralt for the tick checks: did not take");
		GMTestEfxRestoreBuffs(types, kept);
		return;
	}
	LogChannel('GMTest', "INFO EFX-04 bleeding on Geralt: " + dot.GMTestDamageFlags(0) + "; Geralt uses vitality " + thePlayer.UsesVitality() + ", essence " + thePlayer.UsesEssence());
	GMTestEfx04Ticks(thePlayer, dot, 0.01, "bleeding on Geralt (Vitality)");

	// EFX-06: an expired damage over time deals nothing; one with time left caches its tick.
	mgr = thePlayer.GMTestEffectManager();
	before = mgr.GMTestCachedDamages();
	dot.GMTestTick(0, 0.5);
	after = mgr.GMTestCachedDamages();
	GMTestReport(after == before, "EFX-06 an expired bleeding's tick caches no damage (" + (after - before) + " cached)");
	dot.GMTestTick(5, 0.5);
	after = mgr.GMTestCachedDamages();
	GMTestReport(after == before + 1, "EFX-06 control: a bleeding with time left caches its tick (" + (after - before) + " cached)");
	mgr.GMTestDropCachedDamages(before);
	GMTestEfxRestoreBuffs(types, kept);
}

// EFX-04 on the dummy (a human for Vitality, a monster for Essence): the first damage-over-time
// kind that takes on it.
exec function gmtest_efx04_calc()
{
	var npc : CNewNPC;
	var params : SCustomEffectParams;
	var dot : W3DamageOverTimeEffect;
	var v : SAbilityAttributeValue;
	var types : array<EEffectType>;
	var i : int;

	npc = GMTestDummy();
	if(!npc)
	{
		GMTestReport(false, "EFX-04 calc: no test dummy");
		return;
	}
	types.PushBack(EET_Bleeding);
	types.PushBack(EET_Poison);
	types.PushBack(EET_Burning);
	params.creator = thePlayer;
	params.sourceName = "GMTest";
	for(i = 0; i < types.Size() && !dot; i += 1)
	{
		npc.RemoveAllBuffsOfType(types[i]);
		params.effectType = types[i];
		npc.AddEffectCustom(params);
		dot = (W3DamageOverTimeEffect)npc.GetBuff(types[i]);
	}
	if(!dot)
	{
		GMTestReport(false, "EFX-04 calc: no damage over time takes on " + npc.GetDisplayName());
		return;
	}
	v = dot.GMTestEffectValue();
	LogChannel('GMTest', "INFO EFX-04 " + dot.GetEffectType() + " on " + npc.GetDisplayName() + ": " + dot.GMTestDamageFlags(0) + "; uses vitality " + npc.UsesVitality() + ", essence " + npc.UsesEssence()
		+ "; max vitality " + NoTrailZeros(npc.GetStatMax(BCS_Vitality)) + ", max essence " + NoTrailZeros(npc.GetStatMax(BCS_Essence)));
	GMTestEfx04Ticks(npc, dot, v.valueMultiplicative, "" + dot.GetEffectType() + " on " + npc.GetDisplayName());
	npc.RemoveAllBuffsOfType(dot.GetEffectType());
	npc.RemoveAllBuffsOfType(EET_DoTHPRegenReduce);
	GMTestDummyHeal(npc);
	GMTestDummyFreeze(npc);
}

// EFX-06 with real casts: every critical effect the dummy gets is followed until it ends.
@addField(W3PlayerWitcher)
var gmTestEfx6Types : array<EEffectType>;
@addField(W3PlayerWitcher)
var gmTestEfx6Start : array<float>;
@addField(W3PlayerWitcher)
var gmTestEfx6Duration : array<float>;
@addField(W3PlayerWitcher)
var gmTestEfx6Seen : array<float>;
@addField(W3PlayerWitcher)
var gmTestEfx6Until : float;

exec function gmtest_efx06_watch(optional seconds : float)
{
	var w : W3PlayerWitcher;

	w = GetWitcherPlayer();
	if(seconds <= 0)
		seconds = 30;
	w.gmTestEfx6Types.Clear();
	w.gmTestEfx6Start.Clear();
	w.gmTestEfx6Duration.Clear();
	w.gmTestEfx6Seen.Clear();
	w.gmTestEfx6Until = theGame.GetEngineTimeAsSeconds() + seconds;
	w.RemoveTimer('GMTestEfx6Watch');
	w.AddTimer('GMTestEfx6Watch', 0.1, true);
	LogChannel('GMTest', "INFO EFX-06 watching the dummy's critical effects for " + NoTrailZeros(seconds) + " s");
}

@addMethod(W3PlayerWitcher)
timer function GMTestEfx6Watch(dt : float, id : int)
{
	var npc : CNewNPC;
	var buffs : array<CBaseGameplayEffect>;
	var now, lasted : float;
	var i, j : int;
	var found : bool;

	npc = GMTestDummy();
	now = theGame.GetEngineTimeAsSeconds();
	if(!npc)
	{
		RemoveTimer('GMTestEfx6Watch');
		return;
	}
	buffs = npc.GetBuffs();
	for(i = 0; i < buffs.Size(); i += 1)
	{
		if(!IsCriticalEffect(buffs[i]) || buffs[i].GetEffectType() == EET_Frozen || buffs[i].GetEffectType() == EET_KnockdownTypeApplicator)
			continue;
		found = false;
		for(j = 0; j < gmTestEfx6Types.Size(); j += 1)
			if(gmTestEfx6Types[j] == buffs[i].GetEffectType() && gmTestEfx6Seen[j] >= 0)
				found = true;
		if(!found)
		{
			gmTestEfx6Types.PushBack(buffs[i].GetEffectType());
			gmTestEfx6Start.PushBack(now);
			gmTestEfx6Duration.PushBack(buffs[i].GetInitialDurationAfterResists());
			gmTestEfx6Seen.PushBack(0);
			LogChannel('GMTest', "INFO EFX-06 " + buffs[i].GetEffectType() + " on the dummy, its time " + NoTrailZeros(buffs[i].GetInitialDurationAfterResists()) + " s (source " + buffs[i].GetSourceName() + ")");
		}
	}
	for(j = 0; j < gmTestEfx6Types.Size(); j += 1)
	{
		if(gmTestEfx6Seen[j] < 0)
			continue;
		lasted = now - gmTestEfx6Start[j];
		if(npc.HasBuff(gmTestEfx6Types[j]) && lasted < gmTestEfx6Duration[j] + 1)
		{
			gmTestEfx6Seen[j] = lasted;
			continue;
		}
		if(npc.HasBuff(gmTestEfx6Types[j]))
		{
			GMTestReport(false, "EFX-06 " + gmTestEfx6Types[j] + " from a real cast: still active at " + NoTrailZeros(RoundTo(lasted, 2)) + " s of " + NoTrailZeros(gmTestEfx6Duration[j]) + " s; removed");
			npc.RemoveAllBuffsOfType(gmTestEfx6Types[j]);
		}
		else
			GMTestReport(AbsF(gmTestEfx6Seen[j] - gmTestEfx6Duration[j]) <= 0.4, "EFX-06 " + gmTestEfx6Types[j] + " from a real cast: active for "
				+ NoTrailZeros(RoundTo(gmTestEfx6Seen[j], 2)) + " s (expected " + NoTrailZeros(gmTestEfx6Duration[j]) + " s)");
		gmTestEfx6Seen[j] = -1;
	}
	if(now > gmTestEfx6Until)
	{
		RemoveTimer('GMTestEfx6Watch');
		LogChannel('GMTest', "INFO EFX-06 watch ended");
		GMTestDummyFreeze(npc);
	}
}
