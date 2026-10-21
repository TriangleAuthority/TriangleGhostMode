// ALCH-15 tests: the Dimeritium bomb and its effect.

// Adds the Dimeritium effect of a level to an actor, as the bomb's cloud does.
function GMTestAddDimeritium(target : CActor, level : int)
{
	var params : SCustomEffectParams;

	params.effectType = EET_GMDimeritium;
	params.creator = thePlayer;
	params.sourceName = "petard";
	if(level == 1) params.customAbilityName = 'GMDimeritiumEffect_Level1';
	else if(level == 2) params.customAbilityName = 'GMDimeritiumEffect_Level2';
	else params.customAbilityName = 'GMDimeritiumEffect_Level3';
	target.AddEffectCustom(params);
}

// Regression: the data, the name mapping, the effect on Geralt.
function GMTest_alch15()
{
	var type : EEffectType;
	var abl : name;
	var w : W3PlayerWitcher;
	var effect : CBaseGameplayEffect;
	var atts : array<name>;

	w = GetWitcherPlayer();
	GMTestAlchCheck('GMDimeritiumEffect_Level1', 'duration', 20, "ALCH-15 Dimeritium effect");
	GMTestAlchCheck('GMDimeritiumEffect_Level3', 'duration', 40, "ALCH-15 Dimeritium effect");
	GMTestAlchCheck('GMDimeritiumEffect_Level2', 'dbomb_armor_piercing', 75, "ALCH-15 Dimeritium effect");
	GMTestAlchCheck('GMDimeritiumEffect_Level3', 'dbomb_resist_reduction', 0.15, "ALCH-15 Dimeritium effect");
	GMTestAlchCheck('GMDimeritiumEffect_Level1', 'dbomb_dmg_reduction', 0.3, "ALCH-15 Dimeritium effect");
	GMTestAlchCheck('DwimeritiumBomb_3', 'duration', 15, "ALCH-15 Dimeritium cloud");
	theGame.GetDefinitionsManager().GetContainedAbilities('DwimeritiumBomb_1', atts);
	GMTestReport(atts.Contains('GMDimeritiumEffect_Level1') && !atts.Contains('ablMagic') && !atts.Contains('magic_1'),
		"ALCH-15 the bomb gives the effect and blocks nothing directly (DL7: no ablMagic; " + atts.Size() + " contained)");
	EffectNameToType('GMDimeritiumEffect_Level2', type, abl);
	GMTestReport(type == EET_GMDimeritium && abl == 'GMDimeritiumEffect_Level2' && IsEffectNameValid('GMDimeritiumEffect_Level2'),
		"ALCH-15 effect name with its level maps to the effect (" + type + ", " + abl + ")");
	GMTestReport(EffectTypeToName(EET_GMDimeritium) == 'GMDimeritiumEffect' && IsNegativeEffectType(EET_GMDimeritium), "ALCH-15 effect name and negative type");

	// On Geralt: every sign blocked for the effect's duration, unblocked when it ends.
	w.RemoveAllBuffsOfType(EET_GMDimeritium);
	GMTestAddDimeritium(w, 2);
	effect = w.GetBuff(EET_GMDimeritium);
	GMTestReport(effect && w.IsSkillBlocked(S_Magic_1) && w.IsSkillBlocked(S_Magic_2) && w.IsSkillBlocked(S_Magic_5) && w.IsSkillBlocked(S_Magic_s01) && w.IsSkillBlocked(S_Magic_s28),
		"ALCH-15 on Geralt: the signs blocked (classic and new tree), " + NoTrailZeros(RoundTo(effect.GetDurationLeft(), 1)) + " s");
	w.RemoveAllBuffsOfType(EET_GMDimeritium);
	GMTestReport(!w.IsSkillBlocked(S_Magic_1) && !w.IsSkillBlocked(S_Magic_4) && !w.IsSkillBlocked(S_Magic_s31), "ALCH-15 the signs unblocked when the effect ends");
	GMTestReport(!GMIsWildHuntMinion(w) && GMDimeritiumDamageMult(w, w) == 1, "ALCH-15 Geralt is no Wild Hunt minion; no damage cut without the effect");
}

exec function gmtest_alch15_regress()
{
	GMTest_alch15();
}

// Against the test dummy (spawned first: gmtest_dummy("golem") for a magic creature, gmtest_dummy("human")
// for a plain human and a mage, the latter by adding ablMagic): the effect's terms and the real damage.
exec function gmtest_alch15(optional mage : bool)
{
	var npc : CNewNPC;
	var w : W3PlayerWitcher;
	var cat : EMonsterCategory;
	var tmpName : name;
	var tmpBool : bool;
	var dmgOff, dmgOn, hitOff, hitOn : float;

	w = GetWitcherPlayer();
	npc = GMTestDummy();
	if(!npc)
	{
		GMTestReport(false, "ALCH-15 no test dummy");
		return;
	}
	theGame.GetMonsterParamsForActor(npc, cat, tmpName, tmpBool, tmpBool, tmpBool);
	npc.RemoveAllBuffsOfType(EET_GMDimeritium);
	if(mage)
		npc.AddAbility('ablMagic', false);

	if(cat == MC_Magicals)
	{
		// armor 100: Geralt's sword hit does (almost) nothing; with the level 3 effect the armor is gone
		GMTestDummySet(npc, 'armor', 100);
		dmgOff = GMTestAlch15SwordHit(npc);
		GMTestAddDimeritium(npc, 3);
		GMTestReport(npc.HasBuff(EET_GMDimeritium) && GMDimeritiumArmorPiercing(npc) == 100 && AbsF(GMDimeritiumResistReduction(npc) - 0.15) < 0.0001,
			"ALCH-15 magic creature (category " + cat + "): the level 3 effect stays, -" + NoTrailZeros(GMDimeritiumArmorPiercing(npc)) + " armor, -" + RoundMath(100 * GMDimeritiumResistReduction(npc)) + "% resistances");
		dmgOn = GMTestAlch15SwordHit(npc);
		GMTestReport(dmgOn > dmgOff + 5, "ALCH-15 a sword hit on 100 armor: " + NoTrailZeros(RoundTo(dmgOff, 1)) + " without, " + NoTrailZeros(RoundTo(dmgOn, 1)) + " with the effect");
		npc.RemoveAllBuffsOfType(EET_GMDimeritium);
		GMTestDummySet(npc, 'armor', 0);
		return;
	}

	GMTestAddDimeritium(npc, 3);
	if(!mage)
	{
		GMTestReport(!npc.HasBuff(EET_GMDimeritium) || !npc.GetBuff(EET_GMDimeritium).IsActive(),
			"ALCH-15 a plain human: nothing to block, the effect ends (" + npc.HasBuff(EET_GMDimeritium) + ")");
		npc.RemoveAllBuffsOfType(EET_GMDimeritium);
		return;
	}
	// a mage: its damage to Geralt cut by half at level 3
	npc.RemoveAllBuffsOfType(EET_GMDimeritium);
	hitOff = GMTestAlch15MageHit(npc);
	GMTestAddDimeritium(npc, 3);
	hitOn = GMTestAlch15MageHit(npc);
	GMTestReport(npc.HasBuff(EET_GMDimeritium) && GMDimeritiumArmorPiercing(npc) == 0 && hitOff > 0 && AbsF(hitOn / hitOff - 0.5) < 0.02,
		"ALCH-15 a mage (ablMagic): the effect stays, no armor cut, its hit on Geralt " + NoTrailZeros(RoundTo(hitOff, 1)) + " -> " + NoTrailZeros(RoundTo(hitOn, 1)) + " (x0.5 expected)");
	npc.RemoveAllBuffsOfType(EET_GMDimeritium);
	npc.RemoveAbility('ablMagic');
}

// Geralt's light steel sword hit on the NPC; returns the damage dealt (Vitality and Essence).
function GMTestAlch15SwordHit(npc : CActor) : float
{
	var w : W3PlayerWitcher;
	var action : W3Action_Attack;
	var id : SItemUniqueId;
	var dealt : float;

	w = GetWitcherPlayer();
	w.GetItemEquippedOnSlot(EES_SteelSword, id);
	action = new W3Action_Attack in theGame.damageMgr;
	action.Init(w, npc, NULL, id, 'attack_light', w.GetName(), EHRT_Light, false, false, 'attack_light', AST_Jab, ASD_UpDown, true, false, false, false);
	action.SetSuppressHitSounds(true);
	action.SetHitAnimationPlayType(EAHA_ForceNo);
	theGame.damageMgr.ProcessAction(action);
	dealt = action.processedDmg.vitalityDamage + action.processedDmg.essenceDamage;
	delete action;
	GMTestDummyHeal((CNewNPC)npc);
	return dealt;
}

// A non-melee physical hit (no random factor) of the NPC on Geralt; returns the Vitality lost.
function GMTestAlch15MageHit(npc : CActor) : float
{
	var action : W3DamageAction;
	var w : W3PlayerWitcher;
	var vitMax, lost : float;

	w = GetWitcherPlayer();
	vitMax = w.GetStatMax(BCS_Vitality);
	w.ForceSetStat(BCS_Vitality, vitMax);
	action = new W3DamageAction in theGame.damageMgr;
	action.Initialize(npc, w, NULL, "gmtest", EHRT_None, CPS_Undefined, false, false, false, false);
	action.AddDamage(theGame.params.DAMAGE_NAME_PHYSICAL, 400);
	action.SetSuppressHitSounds(true);
	action.SetHitAnimationPlayType(EAHA_ForceNo);
	theGame.damageMgr.ProcessAction(action);
	delete action;
	lost = vitMax - w.GetStat(BCS_Vitality);
	w.ForceSetStat(BCS_Vitality, vitMax);
	return lost;
}

// A real throw of a Dimeritium bomb at the dummy: gmtest_alch15_throw(level, true) selects and presses,
// gmtest_alch15_throw(level, false) releases; then gmtest_alch15_check() reads who carries the effect.
exec function gmtest_alch15_throw(level : int, pressed : bool)
{
	var ids : array<SItemUniqueId>;
	var item : name;

	if(pressed)
	{
		if(level == 1) item = 'Dwimeritium Bomb 1'; else if(level == 2) item = 'Dwimeritium Bomb 2'; else item = 'Dwimeritium Bomb 3';
		ids = thePlayer.inv.AddAnItem(item, 1);
		GetWitcherPlayer().EquipItemInGivenSlot(ids[0], EES_Petard1, false);
		GetWitcherPlayer().SelectQuickslotItem(EES_Petard1);
		thePlayer.GainStat(BCS_Stamina, thePlayer.GetStatMax(BCS_Stamina));
		thePlayer.SetThrowHold(false);
		thePlayer.SetupCombatAction(EBAT_ItemUse, BS_Pressed);
		LogChannel('GMTest', "INFO ALCH-15 throw pressed: " + item);
	}
	else
	{
		thePlayer.SetupCombatAction(EBAT_ItemUse, BS_Released);
		LogChannel('GMTest', "INFO ALCH-15 throw released");
	}
}

exec function gmtest_alch15_check(optional expectGeralt : bool)
{
	var npc : CNewNPC;
	var w : W3PlayerWitcher;
	var dist : float;

	w = GetWitcherPlayer();
	npc = GMTestDummy();
	dist = VecDistance(npc.GetWorldPosition(), w.GetWorldPosition());
	GMTestReport(npc.HasBuff(EET_GMDimeritium), "ALCH-15 real throw: the dummy carries the effect (" + npc.HasBuff(EET_GMDimeritium)
		+ ", " + NoTrailZeros(RoundTo(npc.GetBuff(EET_GMDimeritium).GetDurationLeft(), 1)) + " s left)");
	GMTestReport(w.HasBuff(EET_GMDimeritium) == expectGeralt, "ALCH-15 real throw: Geralt " + NoTrailZeros(RoundTo(dist, 1)) + " m from the dummy carries the effect: "
		+ w.HasBuff(EET_GMDimeritium) + " (expected " + expectGeralt + "), Igni blocked " + w.IsSkillBlocked(S_Magic_2));
}

exec function gmtest_alch15_clear()
{
	GetWitcherPlayer().RemoveAllBuffsOfType(EET_GMDimeritium);
	if(GMTestDummy())
		GMTestDummy().RemoveAllBuffsOfType(EET_GMDimeritium);
}

// ALCH-14, audit F2: Northern Wind's frozen bonus against the test dummy (spawn one first with
// gmtest_dummy("human"), then gmtest_dummy_neutral()): a frozen target's next hit deals +25/35/50% more
// (a pool term, legacy's), with no separate frost hit; the frozen effect ends with the hit. Checked with a
// fixed physical hit of Geralt's (no random factor) and a light sword hit, each without and with the effect.
exec function gmtest_alch14_frozen(level : int)
{
	var npc : CNewNPC;
	var abl : name;
	var bonus, base, frozen, lost, swordOff, swordOn : float;

	npc = GMTestDummy();
	if(!npc)
	{
		GMTestReport(false, "ALCH-14 no test dummy");
		return;
	}
	if(level == 1) { abl = 'FrozenEffect_WhiteFrost1'; bonus = 0.25; }
	else if(level == 2) { abl = 'FrozenEffect_WhiteFrost2'; bonus = 0.35; }
	else { abl = 'FrozenEffect_WhiteFrost3'; bonus = 0.5; }

	npc.RemoveAllBuffsOfType(EET_Frozen);
	base = GMTestAlch14FixedHit(npc, lost);
	GMTestAlch14Freeze(npc, abl);
	GMTestReport(npc.HasBuff(EET_Frozen), "ALCH-14 the dummy frozen with " + abl + " (setup)");
	frozen = GMTestAlch14FixedHit(npc, lost);
	GMTestAlch14Unknock(npc);
	GMTestReport(base > 0 && AbsF(frozen / base - 1 - bonus) < 0.01 && AbsF(lost - frozen) < 1 && !npc.HasBuff(EET_Frozen),
		"ALCH-14 audit F2 Northern Wind " + level + ": a frozen dummy's next hit " + NoTrailZeros(RoundTo(base, 1)) + " -> " + NoTrailZeros(RoundTo(frozen, 1))
		+ " (x" + NoTrailZeros(RoundTo(frozen / base, 3)) + ", expected x" + NoTrailZeros(1 + bonus) + "), health lost " + NoTrailZeros(RoundTo(lost, 1)) + " (no separate frost hit), frozen after the hit " + npc.HasBuff(EET_Frozen));

	// A light sword hit (melee: x0.9 to 1.1 at random each).
	swordOff = GMTestAlch15SwordHit(npc);
	GMTestAlch14Freeze(npc, abl);
	swordOn = GMTestAlch15SwordHit(npc);
	GMTestAlch14Unknock(npc);
	GMTestReport(swordOff > 0 && swordOn / swordOff > (1 + bonus) * 0.8 && swordOn / swordOff < (1 + bonus) * 1.25,
		"ALCH-14 audit F2 Northern Wind " + level + ": a light sword hit " + NoTrailZeros(RoundTo(swordOff, 1)) + " -> " + NoTrailZeros(RoundTo(swordOn, 1)) + " on the frozen dummy (x" + NoTrailZeros(RoundTo(swordOn / swordOff, 2)) + ")");
	npc.RemoveAllBuffsOfType(EET_Frozen);
}

// The knockdown a frozen target's hit gives (5.x's, kept), removed so the next hit meets a standing dummy.
function GMTestAlch14Unknock(npc : CActor)
{
	LogChannel('GMTest', "INFO ALCH-14 after the frozen hit: knockdown " + (npc.HasBuff(EET_Knockdown) || npc.HasBuff(EET_HeavyKnockdown) || npc.HasBuff(EET_KnockdownTypeApplicator)));
	npc.RemoveAllBuffsOfType(EET_Knockdown);
	npc.RemoveAllBuffsOfType(EET_HeavyKnockdown);
	npc.RemoveAllBuffsOfType(EET_KnockdownTypeApplicator);
	GMTestDummyFreeze((CNewNPC)npc);
}

function GMTestAlch14Freeze(npc : CActor, abl : name)
{
	var params : SCustomEffectParams;

	params.effectType = EET_Frozen;
	params.creator = thePlayer;
	params.sourceName = "petard";
	params.customAbilityName = abl;
	params.duration = 10;
	npc.AddEffectCustom(params);
}

// Geralt's fixed physical hit of 100 on the NPC (not melee: no random factor); returns the damage the action
// dealt, and in lost the health the NPC lost (both healed afterwards).
function GMTestAlch14FixedHit(npc : CNewNPC, out lost : float) : float
{
	var action : W3DamageAction;
	var before, dealt : float;

	GMTestDummyHeal(npc);
	before = npc.GetHealth();
	action = new W3DamageAction in theGame.damageMgr;
	action.Initialize(thePlayer, npc, NULL, "gmtest", EHRT_None, CPS_Undefined, false, false, false, false);
	action.AddDamage(theGame.params.DAMAGE_NAME_PHYSICAL, 100);
	action.SetSuppressHitSounds(true);
	action.SetHitAnimationPlayType(EAHA_ForceNo);
	theGame.damageMgr.ProcessAction(action);
	dealt = action.processedDmg.vitalityDamage + action.processedDmg.essenceDamage;
	delete action;
	lost = before - npc.GetHealth();
	GMTestDummyHeal(npc);
	return dealt;
}

// ALCH-15, audit F24: a Wild Hunt minion (the dummy given a minion's ability) keeps the Dimeritium effect.
exec function gmtest_alch15_minion()
{
	var npc : CNewNPC;

	npc = GMTestDummy();
	if(!npc)
	{
		GMTestReport(false, "ALCH-15 no test dummy");
		return;
	}
	npc.RemoveAllBuffsOfType(EET_GMDimeritium);
	npc.AddAbility('mon_wild_hunt_minion', false);
	GMTestAddDimeritium(npc, 3);
	GMTestReport(GMIsWildHuntMinion(npc) && npc.HasBuff(EET_GMDimeritium) && npc.GetBuff(EET_GMDimeritium).IsActive(),
		"ALCH-15 a Wild Hunt minion (ability mon_wild_hunt_minion): " + GMIsWildHuntMinion(npc) + ", the effect stays " + npc.HasBuff(EET_GMDimeritium));
	npc.RemoveAllBuffsOfType(EET_GMDimeritium);
	npc.RemoveAbility('mon_wild_hunt_minion');
	GMTestReport(!GMIsWildHuntMinion(npc), "ALCH-15 the minion ability removed");
}

// ALCH-14, audit F2, a real throw: gmtest_alch14_throw(level, true) selects Northern Wind and presses, (level,
// false) releases at the dummy; then gmtest_alch14_thrown(level): the dummy frozen by the bomb, its next fixed hit
// against the same hit unfrozen.
exec function gmtest_alch14_throw(level : int, pressed : bool)
{
	var ids : array<SItemUniqueId>;
	var item : name;

	if(pressed)
	{
		if(level == 1) item = 'White Frost 1'; else if(level == 2) item = 'White Frost 2'; else item = 'White Frost 3';
		ids = thePlayer.inv.AddAnItem(item, 1);
		GetWitcherPlayer().EquipItemInGivenSlot(ids[0], EES_Petard1, false);
		GetWitcherPlayer().SelectQuickslotItem(EES_Petard1);
		thePlayer.GainStat(BCS_Stamina, thePlayer.GetStatMax(BCS_Stamina));
		thePlayer.SetThrowHold(false);
		thePlayer.SetupCombatAction(EBAT_ItemUse, BS_Pressed);
		LogChannel('GMTest', "INFO ALCH-14 throw pressed: " + item);
	}
	else
	{
		thePlayer.SetupCombatAction(EBAT_ItemUse, BS_Released);
		LogChannel('GMTest', "INFO ALCH-14 throw released");
	}
}

exec function gmtest_alch14_thrown(level : int)
{
	var npc : CNewNPC;
	var frozenBuff : CBaseGameplayEffect;
	var bonus, frozen, base, lost : float;
	var abl : name;

	npc = GMTestDummy();
	frozenBuff = npc.GetBuff(EET_Frozen);
	if(frozenBuff)
		abl = frozenBuff.GetAbilityName();
	GMTestReport(frozenBuff, "ALCH-14 real throw: the dummy frozen by Northern Wind " + level + " (" + abl + ")");
	if(!frozenBuff)
		return;
	if(level == 1) bonus = 0.25; else if(level == 2) bonus = 0.35; else bonus = 0.5;
	frozen = GMTestAlch14FixedHit(npc, lost);
	GMTestAlch14Unknock(npc);
	base = GMTestAlch14FixedHit(npc, lost);
	GMTestReport(base > 0 && AbsF(frozen / base - 1 - bonus) < 0.01,
		"ALCH-14 audit F2 real throw, Northern Wind " + level + ": the frozen dummy's next hit " + NoTrailZeros(RoundTo(frozen, 1)) + ", the same hit unfrozen " + NoTrailZeros(RoundTo(base, 1)) + " (x" + NoTrailZeros(RoundTo(frozen / base, 3)) + ", expected x" + NoTrailZeros(1 + bonus) + ")");
}
