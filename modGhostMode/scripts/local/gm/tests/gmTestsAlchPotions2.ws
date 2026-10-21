// In-game tests for ALCH-06 and ALCH-07 (Petri's Philtre level 3, Blizzard, Cat, Tawny Owl, Maribor Forest).
// See docs/features/alch.md.

// ALCH-06, ALCH-07 (situation-free; drinks by script, restores what it changes).
function GMTest_alch07()
{
	var witcher : W3PlayerWitcher;
	var blizzard : W3Potion_Blizzard;
	var cost, delay : float;
	var focus, stamina : float;

	witcher = GetWitcherPlayer();
	focus = witcher.GetStat(BCS_Focus);

	GMTestAlchItemCheck('Blizzard 1', 'toxicity', 25, "ALCH-07"); GMTestAlchItemCheck('Blizzard 3', 'duration', 30, "ALCH-07");
	GMTestAlchCheck('BlizzardEffect_Level1', 'slow_motion', 0.5, "ALCH-07"); GMTestAlchCheck('BlizzardEffect_Level3', 'slow_motion', 0.25, "ALCH-07");
	GMTestAlchCheck('CatEffect_Level3', 'critical_hit_chance', 0, "ALCH-07 DL4 no crit chance:");

	// Blizzard: no slow motion until a kill; a kill starts it.
	witcher.RemoveAllBuffsOfType(EET_Blizzard);
	blizzard = (W3Potion_Blizzard)GMTestAlchDrink('Blizzard 3');
	GMTestReport(blizzard && !blizzard.IsSlowMoActive(), "ALCH-07 Blizzard: no slow motion before a kill");
	witcher.ForceSetStat(BCS_Focus, 3);
	blizzard.KilledEnemy();
	GMTestReport(blizzard.IsSlowMoActive(), "ALCH-07 Blizzard: a kill starts the slow motion");
	GMTestReport(blizzard.GMTestScreenFxActive(), "ALCH-07 audit F5 Blizzard: 5.x's blue tint on during the slow motion");
	cost = witcher.GetStaminaActionCost(ESAT_LightAttack, '', 0);
	GMTestReport(cost == 0, "ALCH-07 Blizzard 3 with 3 adrenaline: a light attack costs " + cost + " during the slow motion (no Battle Trance needed)");
	// Audit F4: fixed drains are free too (Whirl's, Rend's, a blocked hit's: DrainStamina(ESAT_FixedValue, ...)).
	stamina = witcher.GetStatMax(BCS_Stamina);
	witcher.ForceSetStat(BCS_Stamina, stamina);
	witcher.DrainStamina(ESAT_FixedValue, 20, 1);
	GMTestReport(witcher.GetStat(BCS_Stamina) == stamina, "ALCH-07 audit F4 Blizzard 3 with 3 adrenaline: a fixed drain of 20 (a blocked hit's) costs " + NoTrailZeros(stamina - witcher.GetStat(BCS_Stamina)));
	witcher.GMWhirlDrainResources(0.5);
	GMTestReport(witcher.GetStat(BCS_Stamina) == stamina, "ALCH-07 audit F4 Blizzard 3 with 3 adrenaline: half a second of Whirl costs " + NoTrailZeros(stamina - witcher.GetStat(BCS_Stamina)) + " stamina");
	witcher.ForceSetStat(BCS_Focus, 2);
	cost = witcher.GetStaminaActionCost(ESAT_LightAttack, '', 0);
	GMTestReport(cost > 0, "ALCH-07 Blizzard 3 with 2 adrenaline: a light attack costs " + cost);
	witcher.ForceSetStat(BCS_Stamina, stamina);
	witcher.DrainStamina(ESAT_FixedValue, 20, 1);
	GMTestReport(AbsF(stamina - witcher.GetStat(BCS_Stamina) - 20) < 0.01, "ALCH-07 audit F4 Blizzard 3 with 2 adrenaline: a fixed drain of 20 costs " + NoTrailZeros(stamina - witcher.GetStat(BCS_Stamina)));
	witcher.ForceSetStat(BCS_Stamina, stamina);
	witcher.RemoveAllBuffsOfType(EET_Blizzard);
	GMTestReport(!blizzard.GMTestScreenFxActive(), "ALCH-07 audit F5 Blizzard: the tint off with the potion");
	witcher.ForceSetStat(BCS_Focus, focus);

	// Maribor Forest keeps Well Hydrated.
	witcher.RemoveAllBuffsOfType(EET_MariborForest);
	witcher.AddEffectDefault(EET_WellHydrated, witcher, 'gmtest');
	GMTestReport(witcher.HasBuff(EET_WellHydrated), "ALCH-07 Well Hydrated added (setup)");
	GMTestAlchDrink('Maribor Forest 1');
	GMTestReport(witcher.HasBuff(EET_WellHydrated) && witcher.HasBuff(EET_MariborForest), "ALCH-07 Maribor Forest and Well Hydrated together");
	witcher.RemoveAllBuffsOfType(EET_MariborForest);
	witcher.RemoveAllBuffsOfType(EET_WellHydrated);

	// Tawny Owl's own regen effect is empty (its ability feeds Geralt's regen).
	witcher.RemoveAllBuffsOfType(EET_TawnyOwl);
	GMTestAlchDrink('Tawny Owl 1');
	GMTestReport(witcher.HasBuff(EET_TawnyOwl) && witcher.HasAbility('TawnyOwlEffect_Level1'), "ALCH-07 Tawny Owl's ability on Geralt");
	witcher.RemoveAllBuffsOfType(EET_TawnyOwl);
	witcher.DrainToxicity(witcher.GetStat(BCS_Toxicity, true));
}

// Audit F5: whether Blizzard's screen effect (5.x's blue tint) is on.
@addMethod(W3Potion_Blizzard)
function GMTestScreenFxActive() : bool
{
	return isScreenFxActive;
}

// Blizzard in time: gmtest_alch07_blizzard_a() drinks Blizzard 1 and starts the slow motion as a kill
// would; gmtest_alch07_blizzard_b(false) about 7 s later: it is over (3 s at x0.5).
// gmtest_alch07_blizzard_kill() instead drinks Blizzard 1 and kills the test dummy with Geralt as the
// killer (the game's death path calls KilledEnemy): gmtest_alch07_blizzard_b(true) at once, (false) later.
exec function gmtest_alch07_blizzard_kill()
{
	var npc : CActor;

	npc = GMTestDummy();
	if(!npc)
	{
		LogChannel('GMTest', "FAIL ALCH-07 no test dummy (gmtest_dummy(\"human\") first)");
		return;
	}
	thePlayer.RemoveAllBuffsOfType(EET_Blizzard);
	GMTestAlchDrink('Blizzard 1');
	npc.Kill('gmtest', true, thePlayer);
	LogChannel('GMTest', "INFO ALCH-07 the dummy killed by Geralt: alive " + npc.IsAlive());
}

exec function gmtest_alch07_blizzard_a()
{
	var blizzard : W3Potion_Blizzard;

	thePlayer.RemoveAllBuffsOfType(EET_Blizzard);
	blizzard = (W3Potion_Blizzard)GMTestAlchDrink('Blizzard 1');
	blizzard.KilledEnemy();
	GMTestReport(blizzard.IsSlowMoActive(), "ALCH-07 Blizzard slow motion started, time scale " + theGame.GetTimeScale());
}

exec function gmtest_alch07_blizzard_b(expected : bool)
{
	var blizzard : W3Potion_Blizzard;

	blizzard = (W3Potion_Blizzard)thePlayer.GetBuff(EET_Blizzard);
	GMTestReport(blizzard && blizzard.IsSlowMoActive() == expected, "ALCH-07 Blizzard slow motion " + expected + " (time scale " + theGame.GetTimeScale() + ", potion " + thePlayer.HasBuff(EET_Blizzard) + ")");
	GMTestReport(blizzard && blizzard.GMTestScreenFxActive() == expected, "ALCH-07 audit F5 Blizzard's blue tint " + expected);
}

// Cat and hypnosis: gmtest_alch07_cat_a(level) drinks Cat <level> and hypnotizes Geralt (by script);
// gmtest_alch07_cat_b(expected) a moment later: whether he is still hypnotized.
exec function gmtest_alch07_cat_a(level : int)
{
	var params : SCustomEffectParams;

	thePlayer.RemoveAllBuffsOfType(EET_Cat);
	if(level == 2) GMTestAlchDrink('Cat 2'); else GMTestAlchDrink('Cat 3');
	params.effectType = EET_Hypnotized;
	params.creator = thePlayer;
	params.sourceName = "gmtest";
	params.duration = 10;
	thePlayer.AddEffectCustom(params);
	LogChannel('GMTest', "INFO ALCH-07 Cat " + level + " drunk, hypnotized " + thePlayer.HasBuff(EET_Hypnotized));
}

exec function gmtest_alch07_cat_b(expected : bool)
{
	GMTestReport(thePlayer.HasBuff(EET_Hypnotized) == expected, "ALCH-07 Cat " + GetWitcherPlayer().GetPotionBuffLevel(EET_Cat) + ": still hypnotized " + thePlayer.HasBuff(EET_Hypnotized));
	thePlayer.RemoveAllBuffsOfType(EET_Hypnotized);
	thePlayer.RemoveAllBuffsOfType(EET_Cat);
}

// ALCH-06: Petri's Philtre level 3 on a burning effect Geralt's sign puts on the test dummy (spawn one with
// gmtest_dummy("human") first), and on the last Quen and Yrden cast (cast them first).
exec function gmtest_alch06_burn(petri : bool)
{
	var npc : CNewNPC;
	var params : SCustomEffectParams;
	var buff : CBaseGameplayEffect;

	npc = GMTestDummy();
	thePlayer.RemoveAllBuffsOfType(EET_PetriPhiltre);
	if(petri)
		GMTestAlchDrink('Petri Philtre 3');
	npc.RemoveAllBuffsOfType(EET_Burning);
	params.effectType = EET_Burning;
	params.creator = thePlayer;
	params.sourceName = "gmtest";
	params.isSignEffect = true;
	npc.AddEffectCustom(params);
	buff = npc.GetBuff(EET_Burning);
	if(buff)
		LogChannel('GMTest', "INFO ALCH-06 burning from a sign, Petri 3 " + petri + ": " + NoTrailZeros(RoundTo(buff.GetDurationLeft(), 3)) + " s");
	else
		LogChannel('GMTest', "INFO ALCH-06 no burning applied");
	npc.RemoveAllBuffsOfType(EET_Burning);
}

exec function gmtest_alch06_signs()
{
	var quen : W3QuenEntity;
	var yrden : W3YrdenEntity;

	quen = (W3QuenEntity)GetWitcherPlayer().GetSignEntity(ST_Quen);
	yrden = (W3YrdenEntity)GetWitcherPlayer().GetSignEntity(ST_Yrden);
	LogChannel('GMTest', "INFO ALCH-06 Petri level " + GetWitcherPlayer().GetPotionBuffLevel(EET_PetriPhiltre) + ": Quen shield " + quen.GMTestShieldDuration() + " s, Yrden trap " + yrden.GMTestTrapDuration() + " s");
}

// ALCH-14 data and rules (situation-free; in the regression).
function GMTest_alch14()
{
	GMTestAlchCheck('Grapeshot_3', 'PhysicalDamage', 500, "ALCH-14 Grapeshot");
	GMTestAlchCheck('Grapeshot_3', 'FireDamage', 150, "ALCH-14 Grapeshot");
	GMTestAlchCheck('DragonsDream_3', 'FireDamage', 500, "ALCH-14 Dragon's Dream (DL7)");
	GMTestAlchCheck('DancingStar_3_loop', 'duration', 5, "ALCH-14 Dancing Star cloud");
	GMTestAlchCheck('BurningEffect_DancingStar_2', 'FireDamage', 0.01, "ALCH-14 Dancing Star burning 1% per tick");
	GMTestAlchCheck('BlindnessEffect_Samum_2', 'duration', 5, "ALCH-14 Samum DL11");
	GMTestAlchCheck('BlindnessEffect_Samum_3', 'critical_hit_chance', 1, "ALCH-14 Samum");
	GMTestAlchCheck('Samum_3', 'critical_hit_chance', 0, "ALCH-14 Samum: no crit on the item (5.x's T3 certain crit)");
	GMTestAlchCheck('SilverDustEffect_Level3', 'duration', 40, "ALCH-14 Silver Dust");
	GMTestAlchCheck('FrozenEffect_WhiteFrost3', 'hpPercDamageBonusPerHit', 0.5, "ALCH-14 Northern Wind");
	GMTestAlchCheck('PoisonEffect_DevilsPuffball_1', 'PoisonDamage', 0.01, "ALCH-14 Devil's Puffball 1% per tick");
	// Silver Dust never stays on Geralt.
	thePlayer.AddEffectDefault(EET_SilverDust, thePlayer, 'gmtest');
	GMTestReport(!thePlayer.HasBuff(EET_SilverDust), "ALCH-14 Silver Dust does not stay on Geralt");
}

// ALCH-14 Samum against the test dummy: the blindness ability stays off the enemy and gives Geralt its crit bonus.
exec function gmtest_alch14_samum(level : int)
{
	var npc : CActor;
	var params : SCustomEffectParams;
	var abl : name;

	npc = GMTestDummy();
	npc.RemoveAllBuffsOfType(EET_Blindness);
	if(level == 1) abl = 'BlindnessEffect_Samum_1'; else if(level == 2) abl = 'BlindnessEffect_Samum_2'; else abl = 'BlindnessEffect_Samum_3';
	params.effectType = EET_Blindness;
	params.creator = thePlayer;
	params.sourceName = "petard";
	params.customAbilityName = abl;
	npc.AddEffectCustom(params);
	GMTestReport(npc.HasBuff(EET_Blindness) && !npc.HasAbility(abl), "ALCH-14 Samum " + level + ": the dummy blinded, the crit ability not on it (" + npc.HasAbility(abl) + "), Geralt's bonus +" + RoundMath(100 * GMBlindnessCritBonus(npc)) + "%, duration " + NoTrailZeros(RoundTo(npc.GetBuff(EET_Blindness).GetDurationLeft(), 2)) + " s");
}
