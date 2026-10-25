// EFX's tests (docs/features/efx.md). GMTest_efx01() runs in gmtest_regress().
//
// In play (the neutral test dummy, 100000 health, no resistances):
//   gmtest_dummy("human") then gmtest_dummy_neutral()
//   exec --wait 12000 "gmtest_efx01_apply('bleeding')"   bleeding, tracking, broadhead, poisoncrit,
//                                                        poison, burning, frost, hypnosis, knockdown,
//                                                        heavyknockdown, ragdoll, stagger;
//                                                        optional resistance (0 to 1) set on the dummy
//                                                        first (the effect's own: bleeding, poison,
//                                                        burning, frost or will resistance; will counts
//                                                        for hypnosis since EFX-08); optional maximum health
//                                                        (EFX-04's floor of 1 damage per second)
// A timer follows the effect: its damage per second at mid-time, its total and how long it lasted
// (EFX-06: critical effects end at their time on the frozen dummy too).

@addField(W3PlayerWitcher)
var gmTestEfxType : EEffectType;
@addField(W3PlayerWitcher)
var gmTestEfxKind : string;
@addField(W3PlayerWitcher)
var gmTestEfxStart : float;
@addField(W3PlayerWitcher)
var gmTestEfxHealth : float;
@addField(W3PlayerWitcher)
var gmTestEfxRate : float;
@addField(W3PlayerWitcher)
var gmTestEfxDuration : float;
@addField(W3PlayerWitcher)
var gmTestEfxSeen : float;
@addField(W3PlayerWitcher)
var gmTestEfxMid : float;
@addField(W3PlayerWitcher)
var gmTestEfxHealth2 : float;	// the damage dealt at the last tick the effect was active
@addField(W3PlayerWitcher)
var gmTestEfxResStat : name;
@addField(W3PlayerWitcher)
var gmTestEfxPerSec : float;	// the expected damage per second after resistance (EFX-04)
@addField(W3PlayerWitcher)
var gmTestEfxLowHealth : bool;

// The regression's checks that add effects to Geralt keep the ones he already had (EFX audit F3): saved
// before the check, put back after it with their time left, length, value, source and creator.
struct SGMTestEfxSavedBuff
{
	var effectType : EEffectType;
	var creator : CGameplayEntity;
	var sourceName : string;
	var abilityName : name;
	var initialDuration : float;
	var duration : float;
	var timeLeft : float;
	var timeActive : float;
	var effectValue : SAbilityAttributeValue;
	var powerStat : SAbilityAttributeValue;
	var mutagen23 : bool;
}

@addMethod(CBaseGameplayEffect)
function GMTestEfxSave() : SGMTestEfxSavedBuff
{
	var s : SGMTestEfxSavedBuff;
	var shrine : W3Effect_Shrine;

	s.effectType = effectType;
	s.creator = GetCreator();
	s.sourceName = sourceName;
	s.abilityName = abilityName;
	s.initialDuration = initialDuration;
	s.duration = duration;
	s.timeLeft = timeLeft;
	s.timeActive = timeActive;
	s.effectValue = effectValue;
	s.powerStat = creatorPowerStat;
	shrine = (W3Effect_Shrine)this;
	if(shrine)
		s.mutagen23 = shrine.IsFromMutagen23();
	return s;
}

@addMethod(CBaseGameplayEffect)
function GMTestEfxRestore(s : SGMTestEfxSavedBuff)
{
	initialDuration = s.initialDuration;
	duration = s.duration;
	timeLeft = s.timeLeft;
	timeActive = s.timeActive;
	effectValue = s.effectValue;
}

// Geralt's effects of these types, as they are now.
function GMTestEfxSaveBuffs(types : array<EEffectType>) : array<SGMTestEfxSavedBuff>
{
	var kept : array<SGMTestEfxSavedBuff>;
	var buffs : array<CBaseGameplayEffect>;
	var i, j : int;

	for(i = 0; i < types.Size(); i += 1)
	{
		buffs = thePlayer.GetBuffs(types[i]);
		for(j = 0; j < buffs.Size(); j += 1)
			if(buffs[j].GetEffectType() == types[i])
				kept.PushBack(buffs[j].GMTestEfxSave());
	}
	return kept;
}

// Removes Geralt's effects of these types and puts back the saved ones; an effect a restored one adds
// by itself (a bleeding's regen block) is removed unless it was saved too.
function GMTestEfxRestoreBuffs(types : array<EEffectType>, kept : array<SGMTestEfxSavedBuff>)
{
	var params : SCustomEffectParams;
	var shrineParams : W3ShrineEffectParams;
	var buffs, restored : array<CBaseGameplayEffect>;
	var buff : CBaseGameplayEffect;
	var i, j : int;

	for(i = 0; i < types.Size(); i += 1)
		thePlayer.RemoveAllBuffsOfType(types[i]);
	for(i = 0; i < kept.Size(); i += 1)
	{
		params.effectType = kept[i].effectType;
		params.creator = kept[i].creator;
		params.sourceName = kept[i].sourceName;
		params.duration = kept[i].duration;
		params.effectValue = kept[i].effectValue;
		params.customAbilityName = kept[i].abilityName;
		params.customPowerStatValue = kept[i].powerStat;
		params.buffSpecificParams = NULL;
		shrineParams = NULL;
		if(kept[i].mutagen23)
		{
			shrineParams = new W3ShrineEffectParams in theGame;
			shrineParams.isFromMutagen23 = true;
			params.buffSpecificParams = shrineParams;
		}
		thePlayer.AddEffectCustom(params);
		if(shrineParams)
			delete shrineParams;
		buffs = thePlayer.GetBuffs(kept[i].effectType, kept[i].sourceName);
		buff = NULL;
		for(j = buffs.Size() - 1; j >= 0 && !buff; j -= 1)
			if(buffs[j].GetEffectType() == kept[i].effectType)
				buff = buffs[j];
		if(buff)
		{
			buff.GMTestEfxRestore(kept[i]);
			if(!restored.Contains(buff))
				restored.PushBack(buff);
		}
		else
			GMTestReport(false, "EFX could not put back Geralt's " + kept[i].effectType + " (source " + kept[i].sourceName + ")");
	}
	for(i = 0; i < types.Size(); i += 1)
	{
		buffs = thePlayer.GetBuffs(types[i]);
		for(j = 0; j < buffs.Size(); j += 1)
			if(buffs[j].GetEffectType() == types[i] && !restored.Contains(buffs[j]))
				thePlayer.RemoveEffect(buffs[j]);
	}
}

// Logs Geralt's Places of Power buffs, frost slowdown, bleeding and regen block (F3's checks).
exec function gmtest_efx_buffs()
{
	GMTestEfxLogBuffs();
}

function GMTestEfxLogBuffs()
{
	var buffs : array<CBaseGameplayEffect>;
	var v : SAbilityAttributeValue;
	var i : int;

	buffs = thePlayer.GetBuffs();
	for(i = 0; i < buffs.Size(); i += 1)
		switch(buffs[i].GetEffectType())
		{
			case EET_ShrineAard: case EET_ShrineAxii: case EET_ShrineIgni: case EET_ShrineQuen: case EET_ShrineYrden:
			case EET_SlowdownFrost: case EET_Bleeding: case EET_DoTHPRegenReduce:
				v = buffs[i].GetEffectValue();
				LogChannel('GMTest', "BUFF " + buffs[i].GetEffectType() + " source " + buffs[i].GetSourceName() + " ability " + buffs[i].GetAbilityName()
					+ " left " + NoTrailZeros(RoundTo(buffs[i].GetTimeLeft(), 2)) + " of " + NoTrailZeros(buffs[i].GetInitialDurationAfterResists())
					+ " value " + NoTrailZeros(v.valueMultiplicative) + " paused " + buffs[i].IsPaused());
				break;
		}
	LogChannel('GMTest', "BUFF end");
}

// F3's pre-condition: Geralt gets a Place of Power buff (Igni), a weak bleeding (about 1 damage per
// second, EFX-04's floor) and a frost slowdown, with odd times left, from a source no check uses.
// gmtest_efx_buffs_clear() takes them off.
exec function gmtest_efx_buffs_setup()
{
	var params : SCustomEffectParams;
	var buff : CBaseGameplayEffect;

	thePlayer.AddEffectDefault(EET_ShrineIgni, NULL, "GMTestPre");
	buff = thePlayer.GetBuff(EET_ShrineIgni, "GMTestPre");
	if(buff) buff.SetTimeLeft(1234.5);
	params.effectType = EET_Bleeding;
	params.creator = NULL;
	params.sourceName = "GMTestPre";
	params.duration = 900;
	params.effectValue.valueMultiplicative = 0.00001;
	thePlayer.AddEffectCustom(params);
	buff = thePlayer.GetBuff(EET_Bleeding, "GMTestPre");
	if(buff) buff.SetTimeLeft(543.25);
	params.effectType = EET_SlowdownFrost;
	params.effectValue.valueMultiplicative = 0;
	thePlayer.AddEffectCustom(params);
	buff = thePlayer.GetBuff(EET_SlowdownFrost, "GMTestPre");
	if(buff) buff.SetTimeLeft(432.75);
	GMTestEfxLogBuffs();
}

exec function gmtest_efx_buffs_clear()
{
	thePlayer.RemoveAllBuffsWithSource("GMTestPre");
	GMTestEfxLogBuffs();
}

function GMTestEfxMinMax(ability : name, attr : name, expected : float, label : string)
{
	var min, max : SAbilityAttributeValue;
	var vMin, vMax : float;

	theGame.GetDefinitionsManager().GetAbilityAttributeValue(ability, attr, min, max);
	vMin = min.valueBase + min.valueMultiplicative + min.valueAdditive;
	vMax = max.valueBase + max.valueMultiplicative + max.valueAdditive;
	GMTestReport(AbsF(vMin - expected) < 0.0001 && AbsF(vMax - expected) < 0.0001,
		label + ": " + ability + "." + attr + " " + NoTrailZeros(vMin) + " to " + NoTrailZeros(vMax) + " (expected " + NoTrailZeros(expected) + ")");
}

exec function gmtest_efx01()
{
	GMTest_efx01();
}

// EFX-01 and EFX-05's data, and frost slowdown's frost resistance on Geralt (situation-free).
function GMTest_efx01()
{
	var min, max : SAbilityAttributeValue;
	var buff : CBaseGameplayEffect;
	var pts, perc, expected : float;
	var types : array<EEffectType>;
	var kept : array<SGMTestEfxSavedBuff>;

	types.PushBack(EET_SlowdownFrost);
	kept = GMTestEfxSaveBuffs(types);
	GMTestEfxMinMax('BleedingEffect', 'DirectDamage', 0.01, "EFX-01 bleeding per second");
	GMTestEfxMinMax('BleedingEffect', 'duration', 8, "EFX-01 bleeding");
	GMTestEfxMinMax('BleedingEffect', 'hp_regen_reduction_strength', 200, "EFX-01 bleeding blocks health regen (5.x's kept)");
	GMTestEfxMinMax('BleedingTrackingEffect', 'DirectDamage', 0.005, "EFX-01 tracking bolt bleeding per second");
	GMTestEfxMinMax('BleedingTrackingEffect', 'duration', 16, "EFX-01 tracking bolt bleeding");
	GMTestEfxMinMax('BleedingEffect_BroadheadBolt', 'duration', 8, "EFX-01 broadhead bolt bleeding");
	GMTestEfxMinMax('BleedingEffect_BroadheadBolt', 'hp_regen_reduction_duration', 5, "EFX-01 broadhead bolt bleeding blocks regen");
	theGame.GetDefinitionsManager().GetAbilityAttributeValue('BleedingEffect_BroadheadBolt', 'DirectDamage', min, max);
	GMTestReport(AbsF(min.valueMultiplicative - 0.01) < 0.0001 && AbsF(max.valueMultiplicative - 0.01) < 0.0001 && min.valueAdditive == 0 && max.valueAdditive == 0,
		"EFX-01 broadhead bolt bleeding: x" + NoTrailZeros(min.valueMultiplicative) + " to x" + NoTrailZeros(max.valueMultiplicative) + " of max health per second, flat " + NoTrailZeros(min.valueAdditive) + " (5.x: 10 + 0.1 to 0.2%)");
	GMTestEfxMinMax('PoisonCriticalEffect', 'PoisonDamage', 0.016, "EFX-01 critical poison per second");
	GMTestEfxMinMax('PoisonCriticalEffect', 'duration', 5, "EFX-01 critical poison");
	GMTestEfxMinMax('PoisonEffect', 'PoisonDamage', 0.016, "EFX-01 plain poison per second (5.x's, unchanged)");
	GMTestEfxMinMax('BleedingEffect1', 'DirectDamage', 0.008, "EFX-01 5.x's unused BleedingEffect1 ability untouched (the Wolven types use BleedingEffect)");
	GMTestEfxMinMax('SlowdownFrostEffect', 'duration', 7.5, "EFX-05 frost slowdown");
	GMTestAbilityValue('SlowdownFrostEffect', 'slowdown', 0.35);
	GMTestAbilityValue('SlowdownFrostEffect', 'decay_per_sec', -1);	// extend keeps 5.x's other attributes
	GMTestEfxMinMax('HypnotizedEffect', 'duration', 5, "EFX-05 hypnosis default");

	// Frost slowdown on Geralt with +50% frost resistance (test step abilities): 7.5 x (1 - resistance).
	thePlayer.RemoveAllBuffsOfType(EET_SlowdownFrost);
	thePlayer.AddAbilityMultiple('GMTD_frost_resistance_perc_p0.1', 5);
	thePlayer.GetResistValue(CDS_FrostRes, pts, perc);
	thePlayer.AddEffectDefault(EET_SlowdownFrost, thePlayer, "GMTest");
	buff = thePlayer.GetBuff(EET_SlowdownFrost);
	expected = 7.5 * (1 - perc);
	GMTestReport(buff && perc > 0.3 && AbsF(buff.GetInitialDurationAfterResists() - expected) < 0.01,
		"EFX-05 frost slowdown on Geralt with frost resistance " + NoTrailZeros(perc) + ": lasts " + buff.GetInitialDurationAfterResists() + " s of " + buff.GetInitialDuration() + " (expected " + NoTrailZeros(expected) + ")");
	thePlayer.RemoveAllBuffsOfType(EET_SlowdownFrost);
	thePlayer.RemoveAbilityMultiple('GMTD_frost_resistance_perc_p0.1', 5);
	thePlayer.GetResistValue(CDS_FrostRes, pts, perc);
	thePlayer.AddEffectDefault(EET_SlowdownFrost, thePlayer, "GMTest");
	buff = thePlayer.GetBuff(EET_SlowdownFrost);
	expected = 7.5 * (1 - perc);
	GMTestReport(buff && AbsF(buff.GetInitialDurationAfterResists() - expected) < 0.01,
		"EFX-05 frost slowdown on Geralt, frost resistance back to " + NoTrailZeros(perc) + ": lasts " + buff.GetInitialDurationAfterResists() + " s (expected " + NoTrailZeros(expected) + ")");
	GMTestEfxRestoreBuffs(types, kept);
}

function GMTestEfxDefDuration(ability : name) : float
{
	var min, max : SAbilityAttributeValue;

	theGame.GetDefinitionsManager().GetAbilityAttributeValue(ability, 'duration', min, max);
	return CalculateAttributeValue(min);
}

// Applies one effect to the test dummy as its source does and follows it (see the top of the file).
exec function gmtest_efx01_apply(kind : string, optional resistance : float, optional health : float)
{
	var w : W3PlayerWitcher;
	var npc : CNewNPC;
	var params : SCustomEffectParams;
	var buff : CBaseGameplayEffect;
	var v : SAbilityAttributeValue;
	var maxHealth, expected, res : float;

	w = GetWitcherPlayer();
	npc = GMTestDummy();
	if(!npc)
	{
		GMTestReport(false, "EFX-01 apply: no test dummy (gmtest_dummy, then gmtest_dummy_neutral)");
		return;
	}
	w.RemoveTimer('GMTestEfxWatch');
	GMTestDummyFreeze(npc);
	params.creator = thePlayer;
	params.sourceName = "GMTest";
	w.gmTestEfxResStat = '';
	if(kind == "bleeding")
	{
		params.effectType = EET_Bleeding;
		w.gmTestEfxResStat = 'bleeding_resistance_perc';
	}
	else if(kind == "tracking")
	{
		params.effectType = EET_BleedingTracking;
		w.gmTestEfxResStat = 'bleeding_resistance_perc';
	}
	else if(kind == "broadhead")
	{
		params.effectType = EET_Bleeding;
		params.customAbilityName = 'BleedingEffect_BroadheadBolt';	// as the broadhead bolt names it
		w.gmTestEfxResStat = 'bleeding_resistance_perc';
	}
	else if(kind == "poisoncrit")
	{
		params.effectType = EET_PoisonCritical;
		w.gmTestEfxResStat = 'poison_resistance_perc';
	}
	else if(kind == "poison")
	{
		params.effectType = EET_Poison;
		w.gmTestEfxResStat = 'poison_resistance_perc';
	}
	else if(kind == "burning")
	{
		params.effectType = EET_Burning;
		w.gmTestEfxResStat = 'burning_resistance_perc';
	}
	else if(kind == "frost")
	{
		params.effectType = EET_SlowdownFrost;
		w.gmTestEfxResStat = 'frost_resistance_perc';
	}
	else if(kind == "hypnosis")
	{
		params.effectType = EET_Hypnotized;
		w.gmTestEfxResStat = 'will_resistance_perc';
	}
	else if(kind == "knockdown")
		params.effectType = EET_Knockdown;
	else if(kind == "heavyknockdown")
		params.effectType = EET_HeavyKnockdown;
	else if(kind == "ragdoll")
		params.effectType = EET_Ragdoll;
	else if(kind == "stagger")
		params.effectType = EET_Stagger;
	else
	{
		GMTestReport(false, "EFX-01 apply: unknown kind " + kind);
		return;
	}
	if(w.gmTestEfxResStat != '')
		GMTestDummySet(npc, w.gmTestEfxResStat, resistance);
	// EFX-04's floor: a low maximum health (Vitality or Essence, the one the dummy uses)
	w.gmTestEfxLowHealth = health > 0;
	if(health > 0)
	{
		if(npc.UsesEssence())
			GMTestDummySet(npc, 'essence', health);
		else
			GMTestDummySet(npc, 'vitality', health);
	}
	npc.RemoveAllBuffsOfType(params.effectType);
	npc.RemoveAllBuffsOfType(EET_DoTHPRegenReduce);
	GMTestDummyHeal(npc);
	if(npc.UsesEssence())
		maxHealth = npc.GetStatMax(BCS_Essence);
	else
		maxHealth = npc.GetStatMax(BCS_Vitality);

	npc.AddEffectCustom(params);
	buff = npc.GetBuff(params.effectType);
	if(!buff)
	{
		GMTestReport(false, "EFX-01 " + kind + ": the effect did not take on the dummy (" + npc.GetDisplayName() + ")");
		return;
	}
	v = buff.GMTestEffectValue();
	res = 0;
	if(w.gmTestEfxResStat != '')
		res = GMTestDummyRead(npc, w.gmTestEfxResStat);
	w.gmTestEfxType = params.effectType;
	w.gmTestEfxKind = kind;
	w.gmTestEfxStart = theGame.GetEngineTimeAsSeconds();
	w.gmTestEfxHealth = maxHealth;
	w.gmTestEfxRate = 0;
	w.gmTestEfxPerSec = 0;
	if((W3DamageOverTimeEffect)buff)
	{
		w.gmTestEfxRate = v.valueMultiplicative;
		// EFX-04: the raw tick, at least 1 per second. The effect's resistance shortens it but does not
		// reduce its ticks: their damage is resisted by the damage-over-time resistances (CDS_DoT*,
		// GetResistForDamage), 0 on the neutral dummy (seen 2026-10-24).
		w.gmTestEfxPerSec = MaxF(1, v.valueMultiplicative * maxHealth + v.valueAdditive);
	}
	w.gmTestEfxDuration = buff.GetInitialDurationAfterResists();
	w.gmTestEfxSeen = 0;
	w.gmTestEfxMid = -1;
	LogChannel('GMTest', "INFO EFX " + kind + " on " + npc.GetDisplayName() + " (max health " + NoTrailZeros(maxHealth) + "): ability " + buff.GetAbilityName()
		+ ", duration " + NoTrailZeros(buff.GetInitialDuration()) + " s, after resistance " + NoTrailZeros(w.gmTestEfxDuration) + " s (" + w.gmTestEfxResStat + " " + NoTrailZeros(res)
		+ "), value x" + NoTrailZeros(v.valueMultiplicative) + " + " + NoTrailZeros(v.valueAdditive) + " per second");
	// The effect's time: its ability's duration x (1 - the dummy's resistance as the game reads it).
	expected = GMTestEfxDefDuration(buff.GetAbilityName());
	// Hypnosis's effect entry names its resistance by the point name will_resistance, which 5.x's
	// ResistStatNameToEnum does not know (CDS_None, overriding the class's CDS_WillRes: not resisted,
	// seen 2026-10-24); EFX-08 names it, so will resistance shortens it (legacy).
	if(w.gmTestEfxResStat != '')
		expected *= 1 - res;
	if(kind != "knockdown" && kind != "heavyknockdown" && kind != "ragdoll" && kind != "stagger")
		GMTestReport(AbsF(w.gmTestEfxDuration - expected) < 0.01, "EFX " + kind + ": its time " + NoTrailZeros(w.gmTestEfxDuration) + " s (expected " + NoTrailZeros(expected) + ")");
	else	// knockdowns, stagger and the ragdoll: their time comes from the effect entry or the class (knockdown at least 1 s, the ragdoll's a range)
		LogChannel('GMTest', "INFO EFX " + kind + ": its time " + NoTrailZeros(w.gmTestEfxDuration) + " s");
	w.AddTimer('GMTestEfxWatch', 0.1, true);
}

@addMethod(W3PlayerWitcher)
timer function GMTestEfxWatch(dt : float, id : int)
{
	var npc : CNewNPC;
	var elapsed, health, lost, perSecond, expected : float;
	var label : string;
	var overran : bool;

	npc = GMTestDummy();
	if(!npc)
	{
		RemoveTimer('GMTestEfxWatch');
		return;
	}
	elapsed = theGame.GetEngineTimeAsSeconds() - gmTestEfxStart;
	if(npc.UsesEssence())
		health = npc.GetStat(BCS_Essence);
	else
		health = npc.GetStat(BCS_Vitality);
	lost = gmTestEfxHealth - health;
	label = "EFX " + gmTestEfxKind;
	if(npc.HasBuff(gmTestEfxType))
	{
		// Damage per second at mid-time (damage over time only).
		if(gmTestEfxPerSec > 0 && gmTestEfxMid < 0 && elapsed >= gmTestEfxDuration / 2)
		{
			gmTestEfxMid = elapsed;
			perSecond = lost / elapsed;
			GMTestReport(AbsF(perSecond - gmTestEfxPerSec) < gmTestEfxPerSec * 0.1,
				label + ": " + NoTrailZeros(RoundTo(lost, 2)) + " damage in " + NoTrailZeros(RoundTo(elapsed, 2)) + " s = " + NoTrailZeros(RoundTo(perSecond, 3)) + " per second, "
				+ NoTrailZeros(RoundTo(perSecond / gmTestEfxHealth * 100, 3)) + "% of max health (expected " + NoTrailZeros(RoundTo(gmTestEfxPerSec, 3)) + ")");
		}
		// EFX-06: a critical effect ends at its time, also on the frozen dummy whose animation never
		// ends (1.32's and 5.x's end rule waited for it); one still active is a failure, removed.
		if(elapsed >= gmTestEfxDuration + 1)
			overran = true;
		else
		{
			gmTestEfxSeen = elapsed;
			gmTestEfxHealth2 = lost;
			return;
		}
	}
	RemoveTimer('GMTestEfxWatch');
	if(overran)
	{
		GMTestReport(false, label + ": still active at " + NoTrailZeros(RoundTo(elapsed, 2)) + " s of " + NoTrailZeros(gmTestEfxDuration) + " s (critical: " + IsCriticalEffectType(gmTestEfxType) + "); removed");
		npc.RemoveAllBuffsOfType(gmTestEfxType);
		lost = gmTestEfxHealth2 * gmTestEfxDuration / gmTestEfxSeen;	// the damage up to its time
	}
	else
		GMTestReport(gmTestEfxSeen > 0 && AbsF(gmTestEfxSeen - gmTestEfxDuration) <= 0.4,
			label + ": active for " + NoTrailZeros(RoundTo(gmTestEfxSeen, 2)) + " s, gone by " + NoTrailZeros(RoundTo(elapsed, 2)) + " s (expected " + NoTrailZeros(gmTestEfxDuration) + " s; critical: " + IsCriticalEffectType(gmTestEfxType) + ")");
	if(gmTestEfxPerSec > 0)
	{
		expected = gmTestEfxPerSec * gmTestEfxDuration;
		GMTestReport(AbsF(lost - expected) < expected * 0.05,
			label + ": total " + NoTrailZeros(RoundTo(lost, 2)) + " damage = " + NoTrailZeros(RoundTo(lost / gmTestEfxHealth * 100, 2)) + "% of max health (expected " + NoTrailZeros(RoundTo(expected, 2)) + ", " + NoTrailZeros(RoundTo(expected / gmTestEfxHealth * 100, 2)) + "%)");
	}
	if(gmTestEfxResStat != '')
		GMTestDummySet(npc, gmTestEfxResStat, 0);
	if(gmTestEfxLowHealth)
	{
		if(npc.UsesEssence())
			GMTestDummySet(npc, 'essence', 100000);
		else
			GMTestDummySet(npc, 'vitality', 100000);
	}
	GMTestDummyHeal(npc);
	GMTestDummyFreeze(npc);	// frost slowdown's and the critical states' speed changes can free it
}

@addMethod(CBaseGameplayEffect)
function GMTestTargetEffectName() : name
{
	return targetEffectName;
}

// EFX-13 probe: every <effect> entry of the merged custom definition named effectName (in the order
// the game's CacheSettings reads them: the first valid targetEffectName wins), and the
// targetEffectName an immobilized effect added to the test dummy resolves to.
exec function gmtest_efx13_probe(optional effectName : name)
{
	var dm : CDefinitionsManagerAccessor;
	var main : SCustomNode;
	var i, count : int;
	var tmpName, target : name;
	var npc : CNewNPC;
	var buff : CBaseGameplayEffect;

	if(!IsNameValid(effectName))
		effectName = 'ImmobilizedEffect';
	dm = theGame.GetDefinitionsManager();
	main = dm.GetCustomDefinition('effects');
	for(i = 0; i < main.subNodes.Size(); i += 1)
	{
		dm.GetCustomNodeAttributeValueName(main.subNodes[i], 'name_name', tmpName);
		if(tmpName != effectName)
			continue;
		count += 1;
		target = '';
		dm.GetCustomNodeAttributeValueName(main.subNodes[i], 'targetEffectName_name', target);
		LogChannel('GMTest', "INFO EFX-13 " + effectName + " entry " + count + " (node " + i + " of " + main.subNodes.Size() + "): targetEffectName '" + target + "'");
	}
	LogChannel('GMTest', "INFO EFX-13 " + effectName + ": " + count + " entries in the merged <effects>");
	npc = GMTestDummy();
	if(npc && effectName == 'ImmobilizedEffect')
	{
		npc.AddEffectDefault(EET_Immobilized, thePlayer, "GMTest");
		buff = npc.GetBuff(EET_Immobilized);
		if(buff)
			LogChannel('GMTest', "INFO EFX-13 immobilized on the dummy: targetEffectName '" + buff.GMTestTargetEffectName() + "'");
		else
			LogChannel('GMTest', "INFO EFX-13 immobilized did not take on the dummy");
		npc.RemoveAllBuffsOfType(EET_Immobilized);
		GMTestDummyFreeze(npc);
	}
}
