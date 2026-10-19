// In-game tests for ENCH's sign glyphwords (ENCH-12 to ENCH-15). See docs/features/ench.md.

// ENCH-12 and ENCH-15, situation-free: legacy's values (vanilla's reflection chance and Protection's
// apply chance gone); Retribution's boost only from the chest armor; the description values.
function GMTest_ench12_15()
{
	var w : W3PlayerWitcher;
	var ints : array<int>;
	var fl : array<float>;
	var strs : array<string>;
	var min, max : SAbilityAttributeValue;

	w = GetWitcherPlayer();
	theGame.GetDefinitionsManager().GetAbilityAttributeValue('Glyphword 5 _Stats', 'glyphword5_dmg_boost', min, max);
	GMTestReport(GMTestArmNear(min.valueMultiplicative, 1) && GMTestArmAbl('Glyphword 5 _Stats', 'glyphword5_chance') == 0, "ENCH-12 Retribution: +" + min.valueMultiplicative * 100 + "% (expected 100), no reflection chance (" + GMTestArmAbl('Glyphword 5 _Stats', 'glyphword5_chance') + ")");
	GMTestReport(GMTestArmNear(GMTestArmAbl('Glyphword 15 _Stats', 'glyphword15_slow_cap'), 0.35) && GMTestArmNear(GMTestArmAbl('Glyphword 15 _Stats', 'glyphword15_duration'), 5) && GMTestArmNear(GMTestArmAbl('Glyphword 15 _Stats', 'glyphword15_range'), 2.5),
		"ENCH-15 Entanglement: slowdown " + GMTestArmAbl('Glyphword 15 _Stats', 'glyphword15_slow_cap') + ", " + GMTestArmAbl('Glyphword 15 _Stats', 'glyphword15_duration') + " s, " + GMTestArmAbl('Glyphword 15 _Stats', 'glyphword15_range') + " yd (expected 0.35, 5, 2.5)");
	GMTestReport(GMTestArmNear(GMTestArmAbl('Glyphword 17 _Stats', 'glyphword17_quen_buff'), 1) && GMTestArmAbl('Glyphword 17 _Stats', 'quen_apply_chance') == 0, "ENCH-15 Protection: +" + GMTestArmAbl('Glyphword 17 _Stats', 'glyphword17_quen_buff') * 100 + "% intensity (expected 100), no apply chance");
	GMTestEnchant(EES_Armor, '');
	w.AddAbility('Glyphword 5 _Stats', false);
	GMTestReport(GMRetributionBoost(w) == 0, "ENCH-12 Retribution: its ability on Geralt but not on the chest armor gives no boost");
	w.RemoveAbility('Glyphword 5 _Stats');
	GMTestEnchant(EES_Armor, 'Glyphword 5');
	GMTestReport(GMTestArmNear(GMRetributionBoost(w), 1), "ENCH-12 Retribution on the chest armor: boost +" + GMRetributionBoost(w));
	GMTestEnchant(EES_Armor, '');
	w.GetInventory().GetParamsForRunewordTooltip('Glyphword 15', ints, fl, strs);
	GMTestReport(strs.Size() == 3 && strs[0] == "2.5" && strs[1] == "5" && strs[2] == "35", "ENCH-15: Entanglement's description values " + strs[0] + " yd, " + strs[1] + " s, " + strs[2] + "%");
	w.GetInventory().GetParamsForRunewordTooltip('Glyphword 17', ints, fl, strs);
	GMTestReport(ints.Size() == 1 && ints[0] == 100, "ENCH-15: Protection's description value " + ints[0] + "%");
}

// Test helpers: a new Quen entity of Geralt's, set up without a cast; its discharge share and intensity.
@addMethod(W3PlayerWitcher)
function GMTestNewQuen() : W3QuenEntity
{
	var quen : W3QuenEntity;

	quen = (W3QuenEntity)theGame.CreateEntity(signs[ST_Quen].template, GetWorldPosition(), GetWorldRotation());
	quen.Init(signOwner, signs[ST_Quen].entity, true);
	return quen;
}

@addMethod(W3QuenEntity)
function GMTestDischargeNow() : float
{
	GetSignStats();
	return dischargePercent;
}

@addMethod(W3QuenEntity)
function GMTestQuenPower() : float
{
	return gmQuenPower.valueMultiplicative;
}

function GMTestEnchImpulse(npc : CActor) : float
{
	var before : float;

	if(npc.UsesEssence())
		before = npc.GetStat(BCS_Essence);
	else
		before = npc.GetStat(BCS_Vitality);
	GetWitcherPlayer().QuenImpulse(false, (W3QuenEntity)GetWitcherPlayer().GetSignEntity(ST_Quen), "quen_impulse", 3);
	if(npc.UsesEssence())
		return before - npc.GetStat(BCS_Essence);
	return before - npc.GetStat(BCS_Vitality);
}

// ENCH-12 Retribution, scripted, with Quen Discharge equipped (classic skilleq(S_Magic_s14); the new
// tree's slot holder per D58): the discharge share without and with Retribution on the chest armor; and,
// with a neutral hostile test dummy in front of Geralt, Exploding Shield's impulse at level 3 (forced
// level), its damage without and with Retribution.
exec function gmtest_ench12()
{
	var w : W3PlayerWitcher;
	var npc : CActor;
	var quen : W3QuenEntity;
	var a, b : float;

	w = GetWitcherPlayer();
	npc = GMTestHostileNpc();
	GMTestEnchant(EES_Armor, '');
	quen = w.GMTestNewQuen();
	a = quen.GMTestDischargeNow();
	GMTestEnchant(EES_Armor, 'Glyphword 5');
	b = quen.GMTestDischargeNow();
	quen.Destroy();
	GMTestReport(a > 0 && AbsF(b / a - 2) < 0.01, "ENCH-12 Retribution: Quen Discharge share " + a + " -> " + b + " (expected x2)");
	if(!npc)
	{
		GMTestReport(false, "ENCH-12 Retribution: no hostile NPC for Exploding Shield");
		GMTestEnchant(EES_Armor, '');
		return;
	}
	GMTestEnchant(EES_Armor, '');
	a = GMTestEnchImpulse(npc);
	GMTestEnchant(EES_Armor, 'Glyphword 5');
	b = GMTestEnchImpulse(npc);
	GMTestEnchant(EES_Armor, '');
	GMTestReport(a > 0 && AbsF(b / a - 2) < 0.01, "ENCH-12 Retribution: Exploding Shield level 3 damage " + a + " -> " + b + " (expected x2)");
}

// ENCH-15 Protection, scripted combat starts (OnCombatStart called directly, out of combat): with the
// word on the chest armor and no Quen up, a free Quen with +100% intensity; a second start with that
// Quen up casts none.
exec function gmtest_ench15_protection()
{
	var w : W3PlayerWitcher;
	var quen, quen2 : W3QuenEntity;
	var stamina, expected : float;
	var sp : SAbilityAttributeValue;

	w = GetWitcherPlayer();
	if(w.IsAnyQuenActive())
		w.FinishQuen(false);
	GMTestEnchant(EES_Armor, 'Glyphword 17');
	w.DrainStamina(ESAT_FixedValue, 30, 30);
	stamina = w.GetStat(BCS_Stamina);
	sp = w.GetTotalSignSpellPower(S_Magic_4);
	expected = sp.valueMultiplicative + 1;
	w.OnCombatStart();
	quen = (W3QuenEntity)w.GetSignEntity(ST_Quen);
	GMTestReport(w.IsAnyQuenActive() && w.GetStat(BCS_Stamina) >= stamina && quen && AbsF(quen.GMTestQuenPower() - expected) < 0.001, "ENCH-15 Protection: Quen up " + w.IsAnyQuenActive() + ", stamina " + stamina + " -> " + w.GetStat(BCS_Stamina) + " (free), intensity x" + quen.GMTestQuenPower() + " (expected x" + expected + ")");
	w.OnCombatStart();
	quen2 = (W3QuenEntity)w.GetSignEntity(ST_Quen);
	GMTestReport(quen2 == quen && w.IsAnyQuenActive(), "ENCH-15 Protection: no second Quen while one is up");
	w.FinishQuen(false);
	GMTestEnchant(EES_Armor, '');
}

// ENCH-15 Entanglement, after a real Magic Turret cast (skilleq(S_Magic_s03); autocast(ST_Yrden, true),
// release) near a neutral hostile test dummy, with the word on the chest armor (enchantArmor('Glyphword 15')):
// the trap the turret's hit placed: 5 s, 2.5 yd, the dummy slowed by 35%.
@addMethod(W3YrdenEntity)
function GMTestRange() : float
{
	return baseModeRange;
}

exec function gmtest_ench15_entangle()
{
	var ents : array<CGameplayEntity>;
	var yrden : W3YrdenEntity;
	var npc : CActor;
	var buff : W3Effect_Slowdown;
	var i : int;
	var slow : float;

	npc = GMTestHostileNpc();
	FindGameplayEntitiesInRange(ents, thePlayer, 30, 100, , , , 'W3YrdenEntity');
	for(i = 0; i < ents.Size(); i += 1)
	{
		if(((W3YrdenEntity)ents[i]).gmIsEntanglement)
			yrden = (W3YrdenEntity)ents[i];
	}
	if(npc)
		buff = (W3Effect_Slowdown)npc.GetBuff(EET_Slowdown);
	if(buff)
		slow = buff.GMGetSlowdown();
	if(!yrden)
	{
		GMTestReport(false, "ENCH-15 Entanglement: no trap from a turret hit (" + ents.Size() + " Yrden entities)");
		return;
	}
	GMTestReport(GMTestArmNear(yrden.GMTestTrapDuration(), 5) && GMTestArmNear(yrden.GMTestRange(), 2.5), "ENCH-15 Entanglement: a trap from the turret's hit, " + yrden.GMTestTrapDuration() + " s, " + yrden.GMTestRange() + " yd (expected 5, 2.5)");
	GMTestReport(AbsF(slow - 0.35) < 0.001, "ENCH-15 Entanglement: the dummy slowed by " + slow + " (expected 0.35 at full strength, decaying after a third of the duration)");
}

// ENCH-13, situation-free: legacy's values; Depletion and Rotation from the chest armor only; the
// description values; Rotation's burning chance (GetSignApplyBuffTest, 4000 tries on Geralt's own effect
// manager: no resistance).
function GMTest_ench13()
{
	var w : W3PlayerWitcher;
	var ints : array<int>;
	var fl : array<float>;
	var strs : array<string>;
	var plain, rotation, expected, pts, res : float;

	w = GetWitcherPlayer();
	GMTestReport(GMTestArmNear(GMTestArmAbl('Glyphword 6 _Stats', 'glyphword6_stamina_drain_perc'), 0.5) && GMTestArmNear(GMRotationValue('glyphword7_dmg_buff'), 150) && GMTestArmNear(GMRotationValue('glyphword7_burnchance_debuff'), -0.333),
		"ENCH-13: Depletion " + GMTestArmAbl('Glyphword 6 _Stats', 'glyphword6_stamina_drain_perc') + ", Rotation +" + GMRotationValue('glyphword7_dmg_buff') + " damage, " + GMRotationValue('glyphword7_burnchance_debuff') + " burning chance (expected 0.5, 150, -0.333)");
	GMTestReport(GMTestArmNear(GMTestArmAbl('Glyphword 12 _Stats', 'glyphword12_chance'), 0.5) && GMTestArmNear(GMTestArmAbl('Glyphword 12 _Stats', 'glyphword12_range'), 2) && GMTestArmNear(GMTestArmAbl('Glyphword 20 _Stats', 'FireDamage'), 300),
		"ENCH-13: Ignition " + GMTestArmAbl('Glyphword 12 _Stats', 'glyphword12_chance') + " within " + GMTestArmAbl('Glyphword 12 _Stats', 'glyphword12_range') + " yd, Eruption " + GMTestArmAbl('Glyphword 20 _Stats', 'FireDamage') + " (expected 0.5, 2, 300)");
	GMTestEnchant(EES_Armor, '');
	w.AddAbility('Glyphword 6 _Stats', false);
	GMTestReport(GMDepletionDrain(w) == 0, "ENCH-13 Depletion: its ability on Geralt but not on the chest armor drains nothing");
	w.RemoveAbility('Glyphword 6 _Stats');
	plain = w.GMTestEffectManager().GMTestSignBuffTest(ST_Igni, EET_Burning, false, 4000);
	GMTestEnchant(EES_Armor, 'Glyphword 6');
	GMTestReport(GMTestArmNear(GMDepletionDrain(w), 0.5), "ENCH-13 Depletion on the chest armor: drain " + GMDepletionDrain(w));
	GMTestEnchant(EES_Armor, 'Glyphword 7');
	rotation = w.GMTestEffectManager().GMTestSignBuffTest(ST_Igni, EET_Burning, false, 4000);
	w.GetResistValue(theGame.effectMgr.GetBuffResistStat(EET_Burning), pts, res);
	expected = MaxF(0, plain - 0.333 * (1 - res) * w.GMMutation12ChanceMult());
	GMTestReport(AbsF(rotation - expected) < 0.04, "ENCH-13 Rotation: Igni's burning chance " + plain + " -> " + rotation + " (expected about " + expected + ")");
	GMTestEnchant(EES_Armor, '');
	w.GetInventory().GetParamsForRunewordTooltip('Glyphword 7', ints, fl, strs);
	GMTestReport(ints.Size() == 2 && ints[0] == 150 && (ints[1] == 33 || ints[1] == 34), "ENCH-13: Rotation's description values " + ints[0] + ", " + ints[1] + "%");
	w.GetInventory().GetParamsForRunewordTooltip('Glyphword 20', ints, fl, strs);
	GMTestReport(ints.Size() == 2 && ints[0] == 300 && ints[1] == 3, "ENCH-13: Eruption's description values " + ints[0] + " damage, " + ints[1] + " yd");
	GMTest_ench13_igniDesc();
}

// ENCH-13, audit F3: Igni's skill description (shared by both trees) shows Rotation's +150 damage and its
// 33.3 points less burning chance (floored at 0) with the word on the chest armor, as legacy's tooltip.
function GMTest_ench13_igniDesc()
{
	var ai : array<int>;
	var dmg, chance : float;
	var plain, rotation : string;

	dmg = GMSkillVal(S_Magic_2, theGame.params.DAMAGE_NAME_FIRE) + GMEquippedSkillVal(GMTreeSkill(S_Magic_s07, S_Magic_s35), 'fire_damage_bonus');
	chance = GMSkillVal(S_Magic_2, 'initial_burn_chance') + GMEquippedSkillVal(GMTreeSkill(S_Magic_s09, S_Magic_s41), 'chance_bonus');
	GMTestEnchant(EES_Armor, '');
	plain = GMSignSkillDescription(S_Magic_2, 1);
	ai.PushBack(RoundMath(dmg));
	ai.PushBack(RoundMath(chance * 100));
	GMTestReport(plain == GetLocStringByKeyExtWithParams("gm_skill_desc_igni", ai), "ENCH-13 Igni's description without Rotation: " + ai[0] + " damage, " + ai[1] + "% (" + plain + ")");
	GMTestEnchant(EES_Armor, 'Glyphword 7');
	rotation = GMSignSkillDescription(S_Magic_2, 1);
	ai.Clear();
	ai.PushBack(RoundMath(dmg + 150));
	ai.PushBack(RoundMath(MaxF(0, chance - 0.333) * 100));
	GMTestReport(rotation == GetLocStringByKeyExtWithParams("gm_skill_desc_igni", ai) && rotation != plain, "ENCH-13 Igni's description with Rotation: " + ai[0] + " damage, " + ai[1] + "% (" + rotation + ")");
	GMTestEnchant(EES_Armor, '');
}

// ENCH-13 Depletion, after a real Aard cast at a neutral hostile test dummy with the word on the chest
// armor (enchantArmor('Glyphword 6'); gmtest_ench13_depl_a() first sets the dummy's stamina full): the
// dummy lost half its stamina plus 1, and its regen waits.
exec function gmtest_ench13_depl_a()
{
	var npc : CActor;

	npc = GMTestHostileNpc();
	if(npc)
		npc.ForceSetStat(BCS_Stamina, npc.GetStatMax(BCS_Stamina));
	LogChannel('GMTest', "INFO ENCH-13 Depletion: dummy stamina " + npc.GetStat(BCS_Stamina) + "/" + npc.GetStatMax(BCS_Stamina));
}

exec function gmtest_ench13_depl_b()
{
	var npc : CActor;
	var max, now : float;

	npc = GMTestHostileNpc();
	max = npc.GetStatMax(BCS_Stamina);
	now = npc.GetStat(BCS_Stamina);
	GMTestReport(max > 0 && now <= max * 0.5 - 1 + max * 0.05, "ENCH-13 Depletion: after a real Aard cast the dummy's stamina " + now + "/" + max + " (expected at most half less 1, plus a little regen)");
}

// ENCH-13 Rotation, a real Igni cast at the neutral hostile test dummy (call before and after enchanting
// the chest armor with Rotation; the sign cooldown runs between casts): logs the cast's fire mode and the
// hit's raw damage and pool (test probes on). With Rotation, raw damage = (base + 150) x (1 + pool).
@addMethod(W3IgniEntity)
function GMTestFireMode() : int
{
	return fireMode;
}

@addField(CR4Player)
public var gmTestIgniRaw : float;

@addMethod(CR4Player)
function GMTestSetIgniRaw(v : float)
{
	gmTestIgniRaw = v;
}

exec function gmtest_ench13_igni_a()
{
	thePlayer.GMTestSetProbes(true);
	thePlayer.GMTestDmgReset();
	thePlayer.GMTestSetIgniRaw(0);
}

exec function gmtest_ench13_igni_b()
{
	var step : SGMTestDmgStep;
	var igni : W3IgniEntity;

	igni = (W3IgniEntity)GetWitcherPlayer().GetSignEntity(ST_Igni);
	step = GMTestDmgStep0();
	LogChannel('GMTest', "INFO ENCH-13 Igni: fire mode " + igni.GMTestFireMode() + ", first step " + step.dmgType + " raw " + step.rawIn + ", pool " + thePlayer.gmTestPoolAll + ", Rotation active " + GetWitcherPlayer().HasGlyphwordActive('Glyphword 7 _Stats'));
}

// ENCH-13 Ignition, scripted, with two neutral hostile test dummies at the same spot (gmtest_dummy twice)
// and the word on the chest armor: n times, the first dummy gets Igni's burning (a sign effect from
// Geralt); a moment later (gmtest_ench13_ign_b) the second one is alight or not, with the default
// burning from 'glyphword 12'. Legacy's roll: about half the time.
exec function gmtest_ench13_ign_a()
{
	var params : SCustomEffectParams;
	var a, b : CNewNPC;

	a = thePlayer.gmTestDummies[0];
	b = thePlayer.gmTestDummies[1];
	a.RemoveAllBuffsOfType(EET_Burning);
	b.RemoveAllBuffsOfType(EET_Burning);
	params.effectType = EET_Burning;
	params.creator = thePlayer;
	params.sourceName = "igni";
	params.isSignEffect = true;
	params.duration = 3;
	a.AddEffectCustom(params);
}

@addMethod(W3Effect_Burning)
function GMTestG12() : string
{
	return "with Ignition " + isWithGlyphword12 + ", chance " + glyphword12BurningChance;
}

exec function gmtest_ench13_ign_b()
{
	var b : CNewNPC;
	var buff : CBaseGameplayEffect;
	var buffs : array<CBaseGameplayEffect>;

	b = thePlayer.gmTestDummies[1];
	buff = b.GetBuff(EET_Burning);
	buffs = thePlayer.gmTestDummies[0].GetBuffs(EET_Burning);
	LogChannel('GMTest', "INFO ENCH-13 Ignition: first dummy's burning effects " + buffs.Size() + ", " + ((W3Effect_Burning)thePlayer.gmTestDummies[0].GetBuff(EET_Burning)).GMTestG12());
	if(buff)
		LogChannel('GMTest', "INFO ENCH-13 Ignition: second dummy alight from " + buff.GetSourceName() + ", sign effect " + buff.IsSignEffect() + " (chance attribute " + CalculateAttributeValue(thePlayer.GetAttributeValue('glyphword12_chance')) + ")");
	else
		LogChannel('GMTest', "INFO ENCH-13 Ignition: second dummy not alight (" + VecDistance(b.GetWorldPosition(), thePlayer.gmTestDummies[0].GetWorldPosition()) + " m from the first, which burns " + thePlayer.gmTestDummies[0].HasBuff(EET_Burning) + ")");
}

// ENCH-13 Eruption, scripted, with two neutral hostile test dummies at the same spot and the word on the
// chest armor: the first dummy, burning from Igni (a sign effect from Geralt), is killed by a hit whose
// causer is that burning; (b) the second one took the explosion's damage and is alight, and the
// explosion's raw damage (test probe) is Glyphword 20's 300 fire only: no weapon term (audit F2; 5.x
// added the dying enemy's weapon damage x5, minimum 50).
@addField(CR4Player)
public var gmTestEruptionDmg : array<SRawDamage>;

@addMethod(CR4Player)
function GMTestSetEruptionDmg(d : array<SRawDamage>)
{
	gmTestEruptionDmg = d;
}

@wrapMethod(W3DamageManagerProcessor)
function ProcessAction(act : W3DamageAction)
{
	var d : array<SRawDamage>;

	if(GMTestProbes() && act.GetBuffSourceName() == "Glyphword 20")
	{
		act.GetDTs(d);
		thePlayer.GMTestSetEruptionDmg(d);
	}
	wrappedMethod(act);
}

exec function gmtest_ench13_erupt_a()
{
	var params : SCustomEffectParams;
	var a, b : CNewNPC;
	var action : W3DamageAction;
	var none : array<SRawDamage>;

	a = thePlayer.gmTestDummies[0];
	b = thePlayer.gmTestDummies[1];
	b.RemoveAllBuffsOfType(EET_Burning);
	b.ForceSetStat(BCS_Vitality, b.GetStatMax(BCS_Vitality));
	thePlayer.GMTestSetEruptionDmg(none);
	thePlayer.GMTestSetProbes(true);
	params.effectType = EET_Burning;
	params.creator = thePlayer;
	params.sourceName = "igni";
	params.isSignEffect = true;
	params.duration = 5;
	a.AddEffectCustom(params);
	a.ForceSetStat(BCS_Vitality, 1);
	action = new W3DamageAction in theGame.damageMgr;
	action.Initialize(thePlayer, a, a.GetBuff(EET_Burning), "igni", EHRT_None, CPS_SpellPower, false, false, true, false);
	action.AddDamage(theGame.params.DAMAGE_NAME_FIRE, 1000);
	action.SetIsDoTDamage(0.1);
	theGame.damageMgr.ProcessAction(action);
	delete action;
	thePlayer.GMTestSetProbes(false);
	LogChannel('GMTest', "INFO ENCH-13 Eruption: first dummy alive " + a.IsAlive() + ", its weapon " + a.GetInventory().GetItemName(a.GetInventory().GetItemFromSlot('r_weapon')));
}

exec function gmtest_ench13_erupt_b()
{
	var b : CNewNPC;
	var d : array<SRawDamage>;
	var i : int;
	var total : float;
	var types : string;
	var fireOnly : bool;

	b = thePlayer.gmTestDummies[1];
	GMTestReport(!thePlayer.gmTestDummies[0].IsAlive() && b.GetStat(BCS_Vitality) < b.GetStatMax(BCS_Vitality) && b.HasBuff(EET_Burning), "ENCH-13 Eruption: the second dummy lost " + (b.GetStatMax(BCS_Vitality) - b.GetStat(BCS_Vitality)) + " Vitality to the explosion and is alight " + b.HasBuff(EET_Burning));
	d = thePlayer.gmTestEruptionDmg;
	fireOnly = d.Size() > 0;
	for(i = 0; i < d.Size(); i += 1)
	{
		total += d[i].dmgVal;
		types += " " + d[i].dmgType + " " + d[i].dmgVal;
		if(d[i].dmgType != theGame.params.DAMAGE_NAME_FIRE)
			fireOnly = false;
	}
	GMTestReport(fireOnly && GMTestArmNear(total, 300), "ENCH-13 Eruption: the explosion's raw damage" + types + " (expected FireDamage 300 only, no weapon term)");
}

// ENCH-14, situation-free: legacy's values and descriptions.
function GMTest_ench14()
{
	var w : W3PlayerWitcher;
	var ints : array<int>;
	var fl : array<float>;
	var strs : array<string>;
	var min, max : SAbilityAttributeValue;
	var ap, sp, cc, cd : float;

	w = GetWitcherPlayer();
	theGame.GetDefinitionsManager().GetAbilityAttributeValue('Glyphword 10 abl', 'attack_power', min, max);
	ap = min.valueMultiplicative;
	theGame.GetDefinitionsManager().GetAbilityAttributeValue('Glyphword 10 abl', 'spell_power', min, max);
	sp = min.valueMultiplicative;
	cc = GMTestArmAbl('Glyphword 14 abl', 'critical_hit_chance');
	cd = GMTestArmAbl('Glyphword 14 abl', 'critical_hit_damage_bonus');
	GMTestReport(GMTestArmNear(ap, 0.25) && GMTestArmNear(sp, 0.25) && GMTestArmNear(GMTestArmAbl('Glyphword 10 abl', 'g10_max_stacks'), 4), "ENCH-14 Usurpation: +" + ap + " attack power, +" + sp + " intensity per puppet, max " + GMTestArmAbl('Glyphword 10 abl', 'g10_max_stacks') + " (expected 0.25, 0.25, 4)");
	GMTestReport(GMTestArmNear(cc, 0.25) && GMTestArmNear(cd, 0.25) && GMTestArmNear(GMTestArmAbl('Glyphword 14 abl', 'g14_max_stacks'), 4), "ENCH-14 Beguilement: +" + cc + " crit chance, +" + cd + " crit power per confused enemy, max " + GMTestArmAbl('Glyphword 14 abl', 'g14_max_stacks') + " (expected 0.25, 0.25, 4)");
	GMTestReport(GMTestArmNear(GMTestArmAbl('Glyphword 18 _Stats', 'increas_duration'), 2) && GMTestArmNear(GMTestArmAbl('Glyphword 18 _Stats', 'glyphword_range'), 15), "ENCH-14 Possession: +" + GMTestArmAbl('Glyphword 18 _Stats', 'increas_duration') + " s per hit, " + GMTestArmAbl('Glyphword 18 _Stats', 'glyphword_range') + " m (expected 2, 15)");
	w.GetInventory().GetParamsForRunewordTooltip('Glyphword 10', ints, fl, strs);
	GMTestReport(ints.Size() == 2 && ints[0] == 25 && ints[1] == 100, "ENCH-14: Usurpation's description values " + ints[0] + "%, " + ints[1] + "%");
	w.GetInventory().GetParamsForRunewordTooltip('Glyphword 14', ints, fl, strs);
	GMTestReport(ints.Size() == 2 && ints[0] == 25 && ints[1] == 100, "ENCH-14: Beguilement's description values " + ints[0] + "%, " + ints[1] + "%");
	GMTest_ench14_rule();
}

// ENCH-14, situation-free: a stack needs its word on the chest armor (the changelist's rule, the owner's
// decision): GMAddAxiiWordStack as the Axii effects call it, for an effect Geralt's sign put on an enemy.
function GMTest_ench14_rule()
{
	var w : W3PlayerWitcher;
	var off10, off14, on10, on14, wrong : bool;
	var n10, n14 : int;

	w = GetWitcherPlayer();
	w.RemoveAbilityAll('Glyphword 10 abl');
	w.RemoveAbilityAll('Glyphword 14 abl');
	GMTestEnchant(EES_Armor, '');
	off10 = GMAddAxiiWordStack('Glyphword 10 _Stats', 'Glyphword 10 abl', 'g10_max_stacks', false, w, true);
	off14 = GMAddAxiiWordStack('Glyphword 14 _Stats', 'Glyphword 14 abl', 'g14_max_stacks', false, w, true);
	n10 = w.GetAbilityCount('Glyphword 10 abl');
	n14 = w.GetAbilityCount('Glyphword 14 abl');
	GMTestReport(!off10 && !off14 && n10 == 0 && n14 == 0, "ENCH-14: without the words an Axii puppet and confusion give no stacks (" + n10 + ", " + n14 + ")");
	GMTestEnchant(EES_Armor, 'Glyphword 14');
	wrong = GMAddAxiiWordStack('Glyphword 10 _Stats', 'Glyphword 10 abl', 'g10_max_stacks', false, w, true);
	on14 = GMAddAxiiWordStack('Glyphword 14 _Stats', 'Glyphword 14 abl', 'g14_max_stacks', false, w, true);
	GMTestReport(!wrong && on14 && w.GetAbilityCount('Glyphword 14 abl') == 1 && w.GetAbilityCount('Glyphword 10 abl') == 0, "ENCH-14: with Beguilement on the chest armor a confusion gives a Beguilement stack (" + w.GetAbilityCount('Glyphword 14 abl') + "), a puppet no Usurpation stack (" + w.GetAbilityCount('Glyphword 10 abl') + ")");
	GMTestEnchant(EES_Armor, 'Glyphword 10');
	on10 = GMAddAxiiWordStack('Glyphword 10 _Stats', 'Glyphword 10 abl', 'g10_max_stacks', false, w, true);
	GMTestReport(on10 && w.GetAbilityCount('Glyphword 10 abl') == 1, "ENCH-14: with Usurpation on the chest armor a puppet gives a stack (" + w.GetAbilityCount('Glyphword 10 abl') + ")");
	w.RemoveAbilityAll('Glyphword 10 abl');
	w.RemoveAbilityAll('Glyphword 14 abl');
	GMTestEnchant(EES_Armor, '');
}

// Puts Geralt's Axii effect (confusion or the puppet) on an NPC, as his sign does.
function GMTestEnchAxii(npc : CActor, puppet : bool)
{
	var params : SCustomEffectParams;

	if(puppet)
		params.effectType = EET_AxiiGuardMe;
	else
		params.effectType = EET_Confusion;
	params.creator = thePlayer;
	params.sourceName = "axii";
	params.isSignEffect = true;
	params.duration = 20;
	npc.AddEffectCustom(params);
}

// ENCH-14 Usurpation and Beguilement, scripted, with two neutral hostile test dummies: Axii's puppet and
// confusion put on them as Geralt's sign does, with and without the word on the chest armor; the stacks
// on Geralt, their cap, and their removal with the effects.
exec function gmtest_ench14_stacks()
{
	var w : W3PlayerWitcher;
	var a, b : CNewNPC;
	var i, n0, n1, n2, n3 : int;

	w = GetWitcherPlayer();
	a = thePlayer.gmTestDummies[0];
	b = thePlayer.gmTestDummies[1];
	GMTestEnchant(EES_Armor, '');
	GMTestEnchAxii(a, false);
	n0 = w.GetAbilityCount('Glyphword 14 abl');
	a.RemoveAllBuffsOfType(EET_Confusion);
	GMTestEnchant(EES_Armor, 'Glyphword 14');
	GMTestEnchAxii(a, false);
	GMTestEnchAxii(b, false);
	n1 = w.GetAbilityCount('Glyphword 14 abl');
	a.RemoveAllBuffsOfType(EET_Confusion);
	n2 = w.GetAbilityCount('Glyphword 14 abl');
	b.RemoveAllBuffsOfType(EET_Confusion);
	n3 = w.GetAbilityCount('Glyphword 14 abl');
	GMTestReport(n0 == 0 && n1 == 2 && n2 == 1 && n3 == 0, "ENCH-14 Beguilement: stacks without the word " + n0 + ", two confused enemies " + n1 + ", one " + n2 + ", none " + n3 + " (expected 0, 2, 1, 0)");
	for(i = 0; i < 4; i += 1)
		w.AddAbility('Glyphword 14 abl', true);
	GMTestEnchAxii(a, false);
	n1 = w.GetAbilityCount('Glyphword 14 abl');
	a.RemoveAllBuffsOfType(EET_Confusion);
	GMTestReport(n1 == 4, "ENCH-14 Beguilement: capped at 4 stacks (" + n1 + ")");
	w.RemoveAbilityAll('Glyphword 14 abl');

	GMTestEnchant(EES_Armor, '');
	GMTestEnchAxii(a, true);
	n0 = w.GetAbilityCount('Glyphword 10 abl');
	a.RemoveAllBuffsOfType(EET_AxiiGuardMe);
	GMTestEnchant(EES_Armor, 'Glyphword 10');
	GMTestEnchAxii(a, true);
	n1 = w.GetAbilityCount('Glyphword 10 abl');
	a.RemoveAllBuffsOfType(EET_AxiiGuardMe);
	n2 = w.GetAbilityCount('Glyphword 10 abl');
	GMTestReport(n0 == 0 && n1 == 1 && n2 == 0, "ENCH-14 Usurpation: a puppet without the word gives " + n0 + " stacks, with it " + n1 + ", removed with it (" + n2 + ")");
	GMTestEnchant(EES_Armor, '');
}

// ENCH-14 Possession, scripted, with two neutral hostile test dummies and the word on the chest armor:
// (a) the first dummy, Geralt's puppet, hits the second: its Axii lasts 2 s longer; then it is killed:
// (b) its Axii moved to the second dummy.
exec function gmtest_ench14_poss_a()
{
	var a, b : CNewNPC;
	var before, after : float;
	var action : W3DamageAction;
	var buff : CBaseGameplayEffect;

	a = thePlayer.gmTestDummies[0];
	b = thePlayer.gmTestDummies[1];
	b.RemoveAllBuffsOfType(EET_AxiiGuardMe);
	GMTestEnchant(EES_Armor, 'Glyphword 18');
	GMTestEnchAxii(a, true);
	buff = a.GetBuff(EET_AxiiGuardMe);
	before = buff.GetTimeLeft();
	action = new W3DamageAction in theGame.damageMgr;
	action.Initialize(a, b, NULL, "test", EHRT_None, CPS_Undefined, true, false, false, false);
	action.AddDamage(theGame.params.DAMAGE_NAME_PHYSICAL, 10);
	theGame.damageMgr.ProcessAction(action);
	delete action;
	after = buff.GetTimeLeft();
	GMTestReport(AbsF(after - before - 2) < 0.2, "ENCH-14 Possession: the puppet's hit extends its Axii " + before + " -> " + after + " s (expected +2)");
	a.Kill('Debug', true, thePlayer);
}

exec function gmtest_ench14_poss_b()
{
	var b : CNewNPC;

	b = thePlayer.gmTestDummies[1];
	GMTestReport(!thePlayer.gmTestDummies[0].IsAlive() && b.HasBuff(EET_AxiiGuardMe), "ENCH-14 Possession: the dead puppet's Axii moved to the other enemy (" + b.HasBuff(EET_AxiiGuardMe) + ")");
	b.RemoveAllBuffsOfType(EET_AxiiGuardMe);
	GMTestEnchant(EES_Armor, '');
}

// ENCH-11 Deflection against a real archer (gmtest_def08_archer("skellige_bandit_bow", 12)), audit F1:
// (a) records Geralt's Vitality and the archer's, draws the steel sword and, with guard true, raises the
// guard (thePlayer.SetGuarded); counts parries (test probes) and the arrows that reach the reflection
// check (ProcessCombat_ArrowDeflection, after a parry only); with perfect true, a parry press is stamped
// at each arrow's impact, as a perfectly timed parry would (the counter-spam check needs one); (b) some
// seconds later, by the case:
// - Deflection on the chest armor, unguarded: no arrow hurt Geralt (they bounce), none parried, none
//   reached the reflection check, none came back at the archer, with or without the Deflection skill
//   (5.x's branch before the parry sent every arrow to it, guard or not);
// - Deflection on, guarded: the arrows are parried as without the word (each parry costs stamina, logged
//   by the parry probe) and reach the reflection check; with the Deflection skill and a perfect parry
//   they are reflected at the archer;
// - without the word: unguarded, arrows land; guarded, they are parried.
@addField(CR4Player)
public var gmTestEnch11 : array<float>;
@addField(CR4Player)
public var gmTestDeflChecks : int;
@addField(CR4Player)
public var gmTestPerfectParry : bool;

@addMethod(CR4Player)
function GMTestEnch11Set(a : float, b : float, guard : bool, perfect : bool)
{
	gmTestEnch11.Clear();
	gmTestEnch11.PushBack(a);
	gmTestEnch11.PushBack(b);
	if(guard)
		gmTestEnch11.PushBack(1);
	else
		gmTestEnch11.PushBack(0);
	gmTestDeflChecks = 0;
	gmTestPerfectParry = perfect;
}

@addMethod(CR4Player)
function GMTestDeflCheck()
{
	gmTestDeflChecks += 1;
	if(gmTestPerfectParry)
		AddCounterTimeStamp(theGame.GetEngineTime());
}

@wrapMethod(W3DeflectableAdvancedProjectile)
function ProcessCombat_ArrowDeflection() : bool
{
	if(GMTestProbes())
		thePlayer.GMTestDeflCheck();
	return wrappedMethod();
}

exec function gmtest_ench11_a(optional guard : bool, optional perfect : bool)
{
	var npc : CActor;

	npc = GMTestHostileNpc();
	GetWitcherPlayer().OnEquipMeleeWeapon(PW_Steel, true);
	thePlayer.SetGuarded(guard);
	thePlayer.ForceSetStat(BCS_Vitality, thePlayer.GetStatMax(BCS_Vitality));
	npc.ForceSetStat(BCS_Vitality, npc.GetStatMax(BCS_Vitality));
	thePlayer.GMTestParryReset();
	thePlayer.GMTestEnch11Set(thePlayer.GetStat(BCS_Vitality), npc.GetStat(BCS_Vitality), guard, perfect);
	LogChannel('GMTest', "INFO ENCH-11 start: guard " + guard + ", perfect parries " + perfect + ", Deflection on the armor " + GetWitcherPlayer().HasGlyphwordActive('Glyphword 1 _Stats')
		+ ", Deflection skill " + GetWitcherPlayer().GMDeflectionSkill() + ", adrenaline " + thePlayer.GetStat(BCS_Focus));
}

exec function gmtest_ench11_b()
{
	var npc : CActor;
	var lost, archerLost : float;
	var active, guard, skill : bool;
	var parries, checks : int;
	var what : string;

	npc = GMTestHostileNpc();
	lost = thePlayer.gmTestEnch11[0] - thePlayer.GetStat(BCS_Vitality);
	archerLost = thePlayer.gmTestEnch11[1] - npc.GetStat(BCS_Vitality);
	guard = thePlayer.gmTestEnch11[2] > 0;
	parries = thePlayer.gmTestParries + thePlayer.gmTestPartialParries;
	checks = thePlayer.gmTestDeflChecks;
	active = GetWitcherPlayer().HasGlyphwordActive('Glyphword 1 _Stats');
	skill = GetWitcherPlayer().GMDeflectionSkill() != S_SUndefined;
	what = "guard " + guard + ", perfect " + thePlayer.gmTestPerfectParry + ", Deflection skill " + skill + ": Geralt lost " + lost + " Vitality, the archer " + archerLost + ", " + parries + " parries, " + checks + " reflection checks, adrenaline " + thePlayer.GetStat(BCS_Focus);
	if(active && !guard)
		GMTestReport(lost == 0 && archerLost == 0 && parries == 0 && checks == 0, "ENCH-11 Deflection, " + what + " (expected 0, 0, 0, 0: arrows bounce, none parried or reflected)");
	else if(active && skill && thePlayer.gmTestPerfectParry)
		GMTestReport(lost == 0 && parries > 0 && checks == parries && archerLost > 0, "ENCH-11 Deflection, " + what + " (expected 0, more than 0, parried, as many checks: arrows parried and reflected)");
	else if(active)
		GMTestReport(lost == 0 && parries > 0 && checks == parries && (skill || archerLost == 0), "ENCH-11 Deflection, " + what + " (expected no loss, arrows parried, as many checks; none reflected without the skill)");
	else if(guard)
		GMTestReport(lost == 0 && parries > 0, "ENCH-11 without Deflection, " + what + " (expected no loss, arrows parried)");
	else
		GMTestReport(lost > 0 && checks == 0, "ENCH-11 without Deflection, " + what + " (expected a loss, no reflection check: arrows land)");
	thePlayer.SetGuarded(false);
	thePlayer.GMTestEnch11Set(0, 0, false, false);
	thePlayer.GMTestSetProbes(false);
	thePlayer.ForceSetStat(BCS_Vitality, thePlayer.GetStatMax(BCS_Vitality));
}

// ENCH-03 and ENCH-04, situation-free: legacy's values and descriptions.
function GMTest_ench03_04()
{
	var w : W3PlayerWitcher;
	var ints : array<int>;
	var fl : array<float>;
	var strs : array<string>;
	var min, max : SAbilityAttributeValue;

	w = GetWitcherPlayer();
	GMTestReport(GMTestArmNear(GMTestArmAbl('Runeword 1 _Stats', 'runeword1_confusion_duration'), 5) && GMTestArmNear(GMTestArmAbl('Runeword 1 _Stats', 'runeword1_yrden_duration'), 5),
		"ENCH-03 Replenishment: Axii's confusion " + GMTestArmAbl('Runeword 1 _Stats', 'runeword1_confusion_duration') + " s, Yrden's slowdown " + GMTestArmAbl('Runeword 1 _Stats', 'runeword1_yrden_duration') + " s (expected 5, 5)");
	GMTestReport(GMTestArmNear(GMTestArmAbl('Runeword 2 _Stats', 'runeword2_damage_debuff'), 0.334), "ENCH-04 Severance: Whirl and Rend final damage -" + GMTestArmAbl('Runeword 2 _Stats', 'runeword2_damage_debuff') + " (expected 0.334)");
	w.GetInventory().GetParamsForRunewordTooltip('Runeword 1', ints, fl, strs);
	GMTestReport(strs.Size() == 4 && strs[0] == "100" && strs[1] == "5" && strs[2] == "50" && strs[3] == "5", "ENCH-03: Replenishment's description values " + strs[0] + "%, " + strs[1] + " s, " + strs[2] + "%, " + strs[3] + " s");
	w.GetInventory().GetParamsForRunewordTooltip('Runeword 2', ints, fl, strs);
	GMTestReport(strs.Size() == 3 && strs[2] == "33.4", "ENCH-04: Severance's description values +" + strs[0] + ", +" + strs[1] + " yd, -" + strs[2] + "%");
}

// ENCH-03 Replenishment, scripted sign casts (OnSignCastPerformed called as a cast calls it) with the
// steel sword enchanted: (a) sheathed: no adrenaline spent, no charge; draws the sword; (b) drawn: one
// adrenaline point spent, Axii's charge; a scripted light hit with the sword on the hostile test dummy
// confuses it for 5 s and spends the charge.
exec function gmtest_ench03_a()
{
	var w : W3PlayerWitcher;
	var before : float;

	w = GetWitcherPlayer();
	GMTestEnchant(EES_SteelSword, 'Runeword 1');
	w.OnEquipMeleeWeapon(PW_None, true);
	w.ForceSetStat(BCS_Focus, 2);
	before = w.GetStat(BCS_Focus);
	w.OnSignCastPerformed(ST_Axii, false);
	GMTestReport(w.GetStat(BCS_Focus) == before && w.GetRunewordInfusionType() == ST_None, "ENCH-03 Replenishment: a cast with the sword sheathed spends nothing (" + before + " -> " + w.GetStat(BCS_Focus) + "), no charge");
	w.OnEquipMeleeWeapon(PW_Steel, true);
}

exec function gmtest_ench03_b()
{
	var w : W3PlayerWitcher;
	var npc : CActor;
	var before : float;
	var buff : CBaseGameplayEffect;

	w = GetWitcherPlayer();
	npc = GMTestHostileNpc();
	w.ForceSetStat(BCS_Focus, 2);
	before = w.GetStat(BCS_Focus);
	w.OnSignCastPerformed(ST_Axii, false);
	GMTestReport(GMTestEnchHeld(EES_SteelSword) && w.GetStat(BCS_Focus) == before - 1 && w.GetRunewordInfusionType() == ST_Axii, "ENCH-03 Replenishment: a cast with the sword drawn spends 1 adrenaline (" + before + " -> " + w.GetStat(BCS_Focus) + ") and charges Axii");
	if(!npc)
		return;
	npc.RemoveAllBuffsOfType(EET_Confusion);
	GMTestDmgHit(thePlayer, npc, thePlayer.GetInventory().GetItemFromSlot('r_weapon'), 'attack_light');
	buff = npc.GetBuff(EET_Confusion);
	GMTestReport(buff && AbsF(buff.GetDurationLeft() - 5) < 0.3 && w.GetRunewordInfusionType() == ST_None, "ENCH-03 Replenishment: the charged hit confuses for " + buff.GetDurationLeft() + " s (expected 5) and spends the charge");
	npc.RemoveAllBuffsOfType(EET_Confusion);
	GMTestEnchant(EES_SteelSword, '');
}

// ENCH-04 Severance, a real Whirl or Rend on the neutral hostile test dummy (equip Whirl or Rend,
// adrenaline, the sword drawn): gmtest_ench04_set(word) enchants the steel sword with Severance or not and
// turns the test probes on; press, then gmtest_ench04_check(heavy) while whirling (or after Rend's hit):
// the last recorded hit's final damage is its formula's result x0.666 with Severance active, x1 without
// (the changelist's rule, the owner's decision; legacy's code cut every Whirl and Rend hit).
exec function gmtest_ench04_set(word : bool)
{
	if(word)
		GMTestEnchant(EES_SteelSword, 'Runeword 2');
	else
		GMTestEnchant(EES_SteelSword, '');
	thePlayer.GMTestSetProbes(true);
	thePlayer.GMTestDmgReset();
	LogChannel('GMTest', "INFO ENCH-04: Severance on the steel sword " + word + ", active " + GetWitcherPlayer().HasRunewordActive('Runeword 2 _Stats'));
}

exec function gmtest_ench04_check(optional heavy : bool)
{
	var i : int;
	var result, expected : float;
	var active : bool;

	for(i = 0; i < thePlayer.gmTestDmgSteps.Size(); i += 1)
		if(thePlayer.gmTestDmgSteps[i].hitsStat)
			result = thePlayer.gmTestDmgSteps[i].result;
	active = GetWitcherPlayer().HasRunewordActive('Runeword 2 _Stats');
	if(active)
		expected = 1 - 0.334;
	else
		expected = 1;
	GMTestReport(result > 0 && AbsF(thePlayer.gmTestDmgFinal / result - expected) < 0.01, "ENCH-04: the last " + GMTestSpecialAttackName(heavy) + " hit dealt " + thePlayer.gmTestDmgFinal + " of its formula's " + result + " (x" + (thePlayer.gmTestDmgFinal / result) + ", expected x" + expected + ", Severance active " + active + "), special attack " + thePlayer.IsDoingSpecialAttack(heavy));
}
