// In-game tests for MUT (mutations). See docs/features/mut.md.

function GMTestPam() : W3PlayerAbilityManager
{
	return (W3PlayerAbilityManager)GetWitcherPlayer().abilityManager;
}

// MUT's situation-free checks (in gmtest_regress()).
function GMTest_mut()
{
	GMTest_mut01_costs();
	GMTest_mut02();
	GMTest_mut03();
	GMTest_mut04();
	GMTest_mut07();
	GMTest_mut13();
	GMTest_mut06();
	GMTest_mut11();
	GMTest_mut08();
	GMTest_mut09();
	GMTest_mut05();
	GMTest_mut10();
	GMTest_mut12();
	GMTest_mut12_quen();
	GMTest_mut14();
}

// MUT-11 Cat Eyes' values: bolt damage x2, 15% health loss, 25% slowdown; no flat damage or crit chance.
function GMTest_mut11()
{
	var dm : CDefinitionsManagerAccessor;
	var min, max : SAbilityAttributeValue;
	var dmgMult, health, slow, crit, flat : float;

	dm = theGame.GetDefinitionsManager();
	dm.GetAbilityAttributeValue('Mutation9', 'mut9_damage', min, max);
	dmgMult = min.valueMultiplicative;
	dm.GetAbilityAttributeValue('Mutation9', 'health_reduction', min, max);
	health = min.valueMultiplicative;
	dm.GetAbilityAttributeValue('Mutation9', 'mut9_slowdown', min, max);
	slow = min.valueAdditive;
	dm.GetAbilityAttributeValue('Mutation9', 'critical_hit_chance', min, max);
	crit = min.valueMultiplicative;
	dm.GetAbilityAttributeValue('Mutation9', 'damage', min, max);
	flat = min.valueAdditive;
	GMTestReport(dmgMult == 1 && AbsF(health - 0.15) < 0.0001 && AbsF(slow - 0.25) < 0.0001 && crit == 0 && flat == 0, "MUT-11 Cat Eyes: bolt damage +" + dmgMult + " x, health loss " + health + ", slowdown " + slow + ", crit chance " + crit + ", flat damage " + flat + " (expected 1, 0.15, 0.25, 0, 0)");
}

// MUT-06 Deadly Counter's values.
function GMTest_mut06()
{
	var min, max : SAbilityAttributeValue;
	var bonus, trigger : float;

	theGame.GetDefinitionsManager().GetAbilityAttributeValue('Mutation8', 'dmg_bonus', min, max);
	bonus = min.valueMultiplicative;
	theGame.GetDefinitionsManager().GetAbilityAttributeValue('Mutation8', 'hp_perc_trigger', min, max);
	trigger = min.valueMultiplicative;
	GMTestReport(AbsF(bonus - 0.3334) < 0.0001 && AbsF(trigger - 0.15) < 0.0001, "MUT-06 Deadly Counter: +" + bonus + " damage per adrenaline point (expected 0.3334), kill at " + trigger + " health (expected 0.15)");
}

// MUT-13 Metamorphosis's values; no bonus without the mutation.
function GMTest_mut13()
{
	var min, max : SAbilityAttributeValue;
	var maxcap, bonus, cooldown : float;

	theGame.GetDefinitionsManager().GetAbilityAttributeValue('Mutation12', 'maxcap', min, max);
	maxcap = min.valueAdditive;
	theGame.GetDefinitionsManager().GetAbilityAttributeValue('Mutation12', 'mut12bonus', min, max);
	bonus = min.valueAdditive;
	theGame.GetDefinitionsManager().GetAbilityAttributeValue('Mutation12', 'cooldown', min, max);
	cooldown = min.valueAdditive;
	GMTestReport(maxcap == 3 && AbsF(bonus - 0.1) < 0.0001 && cooldown == 0, "MUT-13 Metamorphosis: " + maxcap + " free decoctions (expected 3), +" + bonus + " each (expected 0.1), no random decoction (cooldown " + cooldown + ")");
	if(!GetWitcherPlayer().IsMutationActive(EPMT_Mutation12))
		GMTestReport(GetWitcherPlayer().GMMutation12ChanceMult() == 1, "MUT-13 no chance bonus without the mutation");
}

// MUT-07 Adrenaline Rush's values.
function GMTest_mut07()
{
	var min, max : SAbilityAttributeValue;
	var ok : bool;

	theGame.GetDefinitionsManager().GetAbilityAttributeValue('Mutation7Buff', 'attack_power', min, max);
	ok = AbsF(min.valueMultiplicative - 0.5) < 0.0001;
	theGame.GetDefinitionsManager().GetAbilityAttributeValue('Mutation7Buff', 'spell_power', min, max);
	ok = ok && AbsF(min.valueMultiplicative - 0.5) < 0.0001;
	theGame.GetDefinitionsManager().GetAbilityAttributeValue('Mutation7Debuff', 'attack_power', min, max);
	ok = ok && AbsF(min.valueMultiplicative + 0.5) < 0.0001;
	theGame.GetDefinitionsManager().GetAbilityAttributeValue('Mutation7Debuff', 'spell_power', min, max);
	ok = ok && AbsF(min.valueMultiplicative + 0.5) < 0.0001;
	GMTestReport(ok, "MUT-07 Adrenaline Rush: +50% attack power and sign intensity per point in the Rush, -50% in the Recovery");
}

// MUT-04 Piercing Cold's values.
function GMTest_mut04()
{
	var min, max : SAbilityAttributeValue;

	theGame.GetDefinitionsManager().GetAbilityAttributeValue('Mutation6', 'full_freeze_chance', min, max);
	GMTestReport(AbsF(min.valueMultiplicative - 0.3) < 0.0001, "MUT-04 Piercing Cold: freeze chance " + min.valueMultiplicative + " (expected 0.3)");
	theGame.GetDefinitionsManager().GetAbilityAttributeValue('Mutation6', 'ForceDamage', min, max);
	GMTestReport(AbsF(CalculateAttributeValue(min) - 250) < 0.0001, "MUT-04 Piercing Cold: force damage " + CalculateAttributeValue(min) + " (expected 250)");
}

// MUT-03 Magic Sensibilities' formula at sign power x1, x2 and x6 (intensity 0%, 100%, 500%).
function GMTest_mut03()
{
	var sp : SAbilityAttributeValue;
	var mults, chances, damages : array<float>;
	var i : int;

	mults.PushBack(1); chances.PushBack(0.05); damages.PushBack(0.25);
	mults.PushBack(2); chances.PushBack(0.35); damages.PushBack(1.65625);
	mults.PushBack(6); chances.PushBack(0.85); damages.PushBack(4.0);
	for(i = 0; i < mults.Size(); i += 1)
	{
		sp.valueMultiplicative = mults[i];
		GMTestReport(AbsF(GMMutation2CritChance(sp) - chances[i]) < 0.0001 && AbsF(GMMutation2CritDamage(sp) - damages[i]) < 0.0001, "MUT-03 Magic Sensibilities at sign power x" + mults[i] + ": crit chance " + GMMutation2CritChance(sp) + " (expected " + chances[i] + "), crit damage " + GMMutation2CritDamage(sp) + " (expected " + damages[i] + ")");
	}
}

// MUT-02 Conductors of Magic's value.
function GMTest_mut02()
{
	var min, max : SAbilityAttributeValue;

	theGame.GetDefinitionsManager().GetAbilityAttributeValue('Mutation1', 'dmg_bonus_factor', min, max);
	GMTestReport(AbsF(min.valueAdditive - 0.3) < 0.0001, "MUT-02 Conductors of Magic: " + min.valueAdditive + " of the sword's base damage (expected 0.3)");
}

exec function gmtest_mut()
{
	GMTest_mut();
}

// MUT-01: legacy's research costs, 29 skill points in all.
function GMTest_mut01_costs()
{
	var pam : W3PlayerAbilityManager;
	var i, required, used, total : int;
	var ok : bool;

	pam = GMTestPam();
	ok = true;
	total = 0;
	for(i = EPMT_Mutation1; i <= EPMT_Mutation12; i += 1)
	{
		if(!pam.GMGetMutationSkillPoints(i, required, used) || required != GMMutationResearchSkillPoints(i))
		{
			ok = false;
			LogChannel('GMTest', "INFO mutation " + i + " costs " + required + " skill points");
		}
		total += required;
	}
	GMTestReport(ok && total == 29, "MUT-01 research costs as legacy, " + total + " skill points in all (expected 29)");
}

// MUT-01: research with skill points as the mutation panel does (MutationResearchWithSkillPoints):
// Magic Sensibilities takes 1 point and refuses a second; Piercing Cold takes 2. Then the equipped
// mutation's sound bank, unloaded, is loaded again by the load-time function.
exec function gmtest_mut01_research()
{
	var pam : W3PlayerAbilityManager;
	var required, used : int;
	var bank : string;

	pam = GMTestPam();
	GetWitcherPlayer().MutationSystemEnable(true);
	GetWitcherPlayer().AddPoints(ESkillPoint, 5, false);
	pam.GMGetMutationSkillPoints(EPMT_Mutation2, required, used);
	if(used > 0)
		LogChannel('GMTest', "INFO Magic Sensibilities already has " + used + " points; reload the test save");
	GMTestReport(pam.MutationResearchWithSkillPoints(EPMT_Mutation2, 1), "MUT-01 Magic Sensibilities researched with 1 skill point");
	GMTestReport(!pam.MutationResearchWithSkillPoints(EPMT_Mutation2, 1), "MUT-01 Magic Sensibilities refuses a second point");
	GMTestReport(!pam.MutationResearchWithSkillPoints(EPMT_Mutation6, 3), "MUT-01 Piercing Cold refuses 3 points");
	GMTestReport(pam.MutationResearchWithSkillPoints(EPMT_Mutation6, 2), "MUT-01 Piercing Cold researched with 2 skill points");

	pam.DEBUG_DevelopAndEquipMutation(EPMT_Mutation1);
}

// After gmtest_mut01_research(), one call per step (sound banks load and unload asynchronously):
// 1 unloads Conductors of Magic's bank, 2 checks it is gone and runs the load-time reload, 3 checks
// it is loaded again.
exec function gmtest_mut01_bank(step : int)
{
	var bank : string;
	var i : int;

	bank = GMTestPam().GetMutationSoundBank(EPMT_Mutation1);
	if(step == 1)
	{
		// banks are counted per load: equipping loads it more than once
		for(i = 0; i < 5; i += 1)
			theSound.SoundUnloadBank(bank);
	}
	else if(step == 2)
	{
		GMTestReport(!theSound.SoundIsBankLoaded(bank), "MUT-01 Conductors of Magic's bank " + bank + " unloaded");
		GMTestPam().GMLoadCurrentMutationSoundBank();
	}
	else
		GMTestReport(theSound.SoundIsBankLoaded(bank), "MUT-01 Conductors of Magic's bank loaded again (load-time reload)");
}

// MUT-01: a save that paid 5.x's price (5 skill points for Conductors of Magic) gets the 2 points
// above legacy's 3 back when the costs are laid on at load.
@addMethod(W3PlayerAbilityManager)
function GMTestMutOverpay() : int
{
	var idx : int;

	idx = GetMutationIndex(EPMT_Mutation1);
	mutations[idx].progress.skillpointsUsed = 5;
	LoadMutationData();
	return mutations[idx].progress.skillpointsUsed;
}

exec function gmtest_mut01_overpay()
{
	var before, used : int;

	before = GetWitcherPlayer().levelManager.GetPointsFree(ESkillPoint);
	used = GMTestPam().GMTestMutOverpay();
	GMTestReport(used == 3 && GetWitcherPlayer().levelManager.GetPointsFree(ESkillPoint) == before + 2, "MUT-01 overpaid research: " + used + " points kept (expected 3), " + (GetWitcherPlayer().levelManager.GetPointsFree(ESkillPoint) - before) + " given back (expected 2)");
}

// Hit probe: the raw damage of the first non-DoT sign, melee or bolt hit after GMTestMutSignProbe(true),
// before and after ProcessDamageIncrease (where Conductors of Magic adds its damage).
@addField(CR4Player)
var gmTestMutSignOn : bool;
@addField(CR4Player)
var gmTestMutSignBefore : float;
@addField(CR4Player)
var gmTestMutSignAfter : float;
@addField(CR4Player)
var gmTestMutSignEntries : int;

@addMethod(CR4Player)
function GMTestMutSignProbe(on : bool)
{
	gmTestMutSignOn = on;
	gmTestMutSignBefore = -1;
	gmTestMutSignAfter = -1;
	gmTestMutSignEntries = 0;
}

@addMethod(CR4Player)
function GMTestMutSignRecord(before : float, after : float, entries : int)
{
	gmTestMutSignOn = false;
	gmTestMutSignBefore = before;
	gmTestMutSignAfter = after;
	gmTestMutSignEntries = entries;
}

@wrapMethod(W3DamageManagerProcessor)
function ProcessDamageIncrease(out dmgInfos : array< SRawDamage >)
{
	var i : int;
	var before, after : float;
	var record : bool;

	record = thePlayer.gmTestMutSignOn && (action.IsActionWitcherSign() || action.IsActionMelee() || (W3BoltProjectile)action.causer) && !action.IsDoTDamage() && playerAttacker;
	for(i = 0; i < dmgInfos.Size(); i += 1)
		before += dmgInfos[i].dmgVal;
	wrappedMethod(dmgInfos);
	for(i = 0; i < dmgInfos.Size(); i += 1)
		after += dmgInfos[i].dmgVal;
	if(record)
		thePlayer.GMTestMutSignRecord(before, after, dmgInfos.Size());
}

// MUT-02 setup, after gmtest_dummy("human") and gmtest_dummy_neutral(): Conductors of Magic
// equipped (on) or no mutation, the steel sword drawn, the sign probe armed. Cast Igni at the dummy
// next (autocast), then gmtest_mut02_read(on).
exec function gmtest_mut02_setup(on : bool)
{
	var ids : array<SItemUniqueId>;

	// a witcher sword (Conductors of Magic needs quality 3 or more; the test save's swords are lower)
	ids = thePlayer.inv.GetItemsByName('Viper School steel sword');
	if(ids.Size() == 0)
		ids = thePlayer.inv.AddAnItem('Viper School steel sword', 1);
	GetWitcherPlayer().EquipItem(ids[0]);
	if(on)
		GMTestPam().DEBUG_DevelopAndEquipMutation(EPMT_Mutation1);
	else
		GMTestPam().DEBUG_SetEquippedMutation(EPMT_None);	// also in combat
	thePlayer.OnEquipMeleeWeapon(PW_Steel, true);
	thePlayer.GMTestMutSignProbe(true);
	thePlayer.GainStat(BCS_Stamina, 1000);
}

exec function gmtest_mut02_read(on : bool)
{
	var sword : SItemUniqueId;
	var weaponDmg, bonus, expected : float;

	sword = thePlayer.inv.GetCurrentlyHeldSword();
	weaponDmg = GetWitcherPlayer().GetTotalWeaponDamage(sword, theGame.params.DAMAGE_NAME_SLASHING, GetInvalidUniqueId());
	bonus = thePlayer.gmTestMutSignAfter - thePlayer.gmTestMutSignBefore;
	if(on)
		expected = 0.3 * weaponDmg * thePlayer.gmTestMutSignEntries;
	LogChannel('GMTest', "INFO sign hit raw " + thePlayer.gmTestMutSignBefore + " -> " + thePlayer.gmTestMutSignAfter + " (" + thePlayer.gmTestMutSignEntries + " damage entries); sword base damage " + weaponDmg);
	GMTestReport(thePlayer.gmTestMutSignBefore > 0 && AbsF(bonus - expected) < 0.01, "MUT-02 Conductors of Magic " + on + ": sign raw damage +" + bonus + " (expected " + expected + ", 30% of the sword's base damage per entry)");
	GMTestReport(GetWitcherPlayer().GetMutationLocalizedDescription(EPMT_Mutation1) == "When drawn, magic, relic and witcher swords increase Sign base damage by 30% of their own base damage.", "MUT-02 description: " + GetWitcherPlayer().GetMutationLocalizedDescription(EPMT_Mutation1));
}

// MUT-03 setup, after gmtest_dummy("human") and gmtest_dummy_neutral(): Magic Sensibilities equipped
// (on) or no mutation, crits forced (vanilla's debug fact; with the mutation it forces the sign's
// roll), the damage probe reset. Cast Igni at the dummy next (autocast), then gmtest_mut03_read(on).
exec function gmtest_mut03_setup(on : bool)
{
	if(on)
		GMTestPam().DEBUG_DevelopAndEquipMutation(EPMT_Mutation2);
	else
		GMTestPam().DEBUG_SetEquippedMutation(EPMT_None);	// also in combat
	FactsAdd('debug_fact_critical_boy', 1);
	thePlayer.GMTestSetProbes(true);
	thePlayer.GMTestDmgReset();
	thePlayer.GainStat(BCS_Stamina, 1000);
}

exec function gmtest_mut03_read(on : bool)
{
	var step : SGMTestDmgStep;
	var sp : SAbilityAttributeValue;
	var expected : float;

	FactsRemove('debug_fact_critical_boy');
	step = GMTestDmgStep0();
	sp = GetWitcherPlayer().GetTotalSignSpellPower(S_Magic_2);
	expected = sp.valueMultiplicative;
	if(on)
		expected += GMMutation2CritDamage(sp);
	LogChannel('GMTest', "INFO Igni hit: power x" + step.mult + ", raw " + step.rawIn + " -> " + step.result + "; sign power x" + sp.valueMultiplicative);
	GMTestReport(step.dmgType != '' && AbsF(step.mult - expected) < 0.001, "MUT-03 Magic Sensibilities " + on + ": Igni's power x" + step.mult + " (expected x" + expected + ": intensity plus legacy's crit damage with the mutation, no crit without it)");
	GMTestReport(GetWitcherPlayer().GetMutationLocalizedDescription(EPMT_Mutation2) != "" && StrContains(GetWitcherPlayer().GetMutationLocalizedDescription(EPMT_Mutation2), NoTrailZeros(RoundMath(100 * GMMutation2CritDamage(GetWitcherPlayer().GetPowerStatValue(CPS_SpellPower))))), "MUT-03 description: " + GetWitcherPlayer().GetMutationLocalizedDescription(EPMT_Mutation2));
}

// MUT-04 setup, after gmtest_dummy("human") and gmtest_dummy_neutral(): Piercing Cold equipped, the
// dummy's frost resistance set (1: never frozen; -3: always), optionally knocked down, its effects
// cleared, the damage probe reset. Cast Aard at it next (autocast), then gmtest_mut04_read(case):
// 0 not frozen (force damage), 1 frozen and alive, 2 frozen and knocked down (dead).
// knockdown 1 knocks the dummy down first; -1 makes it immune to knockdowns (Aard's own roll would
// otherwise knock it down at random), 0 neither.
exec function gmtest_mut04_setup(frostRes : float, knockdown : int)
{
	var npc : CNewNPC;

	npc = GMTestDummy();
	GMTestPam().DEBUG_DevelopAndEquipMutation(EPMT_Mutation6);
	npc.RemoveAllBuffsOfType(EET_Frozen);
	npc.RemoveAllBuffsOfType(EET_Knockdown);
	npc.RemoveAllBuffsOfType(EET_HeavyKnockdown);
	GMTestReport(GMTestDummySet(npc, 'frost_resistance_perc', frostRes), "dummy frost resistance " + GMTestDummyRead(npc, 'frost_resistance_perc'));
	npc.RemoveBuffImmunity(EET_Knockdown, 'gmtest');
	npc.RemoveBuffImmunity(EET_HeavyKnockdown, 'gmtest');
	if(knockdown > 0)
		npc.AddEffectDefault(EET_Knockdown, thePlayer, "test");
	else if(knockdown < 0)
	{
		npc.AddBuffImmunity(EET_Knockdown, 'gmtest', false);
		npc.AddBuffImmunity(EET_HeavyKnockdown, 'gmtest', false);
	}
	thePlayer.GMTestSetProbes(true);
	thePlayer.GMTestDmgReset();
	thePlayer.GainStat(BCS_Stamina, 1000);
}

exec function gmtest_mut04_read(kind : int)
{
	var npc : CNewNPC;
	var i, forceSteps : int;
	var steps : array<SGMTestDmgStep>;
	var sp : SAbilityAttributeValue;
	var force : SGMTestDmgStep;
	var ok : bool;

	npc = GMTestDummy();
	steps = thePlayer.gmTestDmgSteps;
	for(i = 0; i < steps.Size(); i += 1)
		if(steps[i].dmgType == theGame.params.DAMAGE_NAME_FORCE && AbsF(steps[i].rawIn - 250) < 0.01)
		{
			force = steps[i];
			forceSteps += 1;
		}
	sp = GetWitcherPlayer().GetTotalSignSpellPower(S_Magic_1);
	LogChannel('GMTest', "INFO dummy alive " + (npc && npc.IsAlive()) + ", frozen " + (npc && npc.HasBuff(EET_Frozen)) + ", 250-force hits " + forceSteps + " (power x" + force.mult + ", Aard x" + sp.valueMultiplicative + ")");
	if(kind == 0)
		ok = npc.IsAlive() && !npc.HasBuff(EET_Frozen) && forceSteps == 1 && AbsF(force.mult - sp.valueMultiplicative) < 0.001;
	else if(kind == 1)
		ok = npc.IsAlive() && npc.HasBuff(EET_Frozen) && forceSteps == 0;
	else
		ok = !npc || !npc.IsAlive();
	GMTestReport(ok, "MUT-04 Piercing Cold case " + kind + " (0: not frozen, 250 force damage at Aard's intensity; 1: frozen; 2: frozen and knocked down, killed)");
	GMTestReport(StrContains(GetWitcherPlayer().GetMutationLocalizedDescription(EPMT_Mutation6), "250"), "MUT-04 description: " + GetWitcherPlayer().GetMutationLocalizedDescription(EPMT_Mutation6));
}

// MUT-07, with a neutral test dummy (in combat), in four calls (the Rush's update runs in between):
// gmtest_mut07(1) starts the cycle as combat start does (the event called by script) with 2 adrenaline
// points, and checks the Rush and a hit's doubled gain, then sets adrenaline to 0; (2) checks the
// bonuses followed it and sets 3 points; (3) ends the Rush: the Recovery by the 3 points gained, a
// halved gain, no immunity; (4): the Recovery's end starts the next Rush.
function GMTestMut07HitGain() : float
{
	var witcher : W3PlayerWitcher;
	var focusGain : float;

	witcher = GetWitcherPlayer();
	focusGain = CalculateAttributeValue(witcher.GetAttributeValue('focus_gain'));
	if(witcher.CanUseSkill(S_Sword_s20))
		focusGain += CalculateAttributeValue(witcher.GetSkillAttributeValue(S_Sword_s20, 'focus_gain', false, true)) * witcher.GetSkillLevel(S_Sword_s20);
	return 0.1 * (1 + focusGain);
}

// MUT-07 with a real cast (Focus, perk_11 or perk_37, equipped): gmtest_mut07_sign_a() sets
// adrenaline to 0, a cast follows (autocast), then gmtest_mut07_sign_b(mult) reads the gain against
// Focus's 0.1 x (1 + focus_gain) x mult (2 in the Rush, 1 without the mutation).
exec function gmtest_mut07_sign_a()
{
	GetWitcherPlayer().ForceSetStat(BCS_Focus, 0);
	GetWitcherPlayer().GainStat(BCS_Stamina, 1000);
}

exec function gmtest_mut07_sign_b(mult : float)
{
	var gain, base : float;

	gain = GetWitcherPlayer().GetStat(BCS_Focus);
	base = GMTestMut07HitGain();
	GMTestReport(AbsF(gain - mult * base) < 0.0001, "MUT-07 a sign cast's Focus gain " + gain + " (expected " + mult + " x " + base + "; Rush " + GetWitcherPlayer().HasBuff(EET_Mutation7Buff) + ")");
}

exec function gmtest_mut07(phase : int)
{
	var witcher : W3PlayerWitcher;
	var npc : CActor;
	var buff : W3Effect_Mutation7Buff;
	var debuff : W3Effect_Mutation7Debuff;
	var gain, base : float;
	var pts : int;

	witcher = GetWitcherPlayer();
	npc = GMTestHostileNpc();
	if(!npc || !witcher.IsInCombat())
	{
		GMTestReport(false, "MUT-07: needs a hostile test dummy nearby, in combat");
		return;
	}
	base = GMTestMut07HitGain();
	if(phase == 1)
	{
		GMTestPam().DEBUG_DevelopAndEquipMutation(EPMT_Mutation7);
		witcher.RemoveBuff(EET_Mutation7Buff);
		witcher.RemoveBuff(EET_Mutation7Debuff);
		witcher.ForceSetStat(BCS_Focus, 2);
		witcher.OnCombatStart();
		buff = (W3Effect_Mutation7Buff)witcher.GetBuff(EET_Mutation7Buff);
		GMTestReport(buff && witcher.GetAbilityCount('Mutation7Buff') == 2 && buff.GetStacks() == 100, "MUT-07 combat start: the Rush, " + witcher.GetAbilityCount('Mutation7Buff') + " bonuses for 2 adrenaline points, shown +" + buff.GetStacks() + "% (expected 2, 100)");
		gain = GMTestSkl07Hit(npc, false, false);
		GMTestReport(AbsF(gain - 2 * base) < 0.0001, "MUT-07 Rush: a hit gives " + gain + " adrenaline (expected 2 x " + base + ")");
		witcher.ForceSetStat(BCS_Focus, 0);
	}
	else if(phase == 2)
	{
		GMTestReport(witcher.GetAbilityCount('Mutation7Buff') == 0, "MUT-07 Rush at 0 adrenaline: " + witcher.GetAbilityCount('Mutation7Buff') + " bonuses (expected 0)");
		witcher.ForceSetStat(BCS_Focus, 3);
	}
	else if(phase == 3)
	{
		buff = (W3Effect_Mutation7Buff)witcher.GetBuff(EET_Mutation7Buff);
		pts = buff.gmAccumulatedFocusPts;
		witcher.RemoveBuff(EET_Mutation7Buff);
		debuff = (W3Effect_Mutation7Debuff)witcher.GetBuff(EET_Mutation7Debuff);
		GMTestReport(pts == 3 && debuff && witcher.GetAbilityCount('Mutation7Debuff') == pts && witcher.GetAbilityCount('Mutation7Buff') == 0 && debuff.GetStacks() == 50 * pts, "MUT-07 Rush ended: the Recovery with " + witcher.GetAbilityCount('Mutation7Debuff') + " penalties for " + pts + " points gained in the Rush (expected 3: from 0 to 3), shown -" + debuff.GetStacks() + "%");
		gain = GMTestSkl07Hit(npc, false, false);
		GMTestReport(AbsF(gain - 0.5 * base) < 0.0001, "MUT-07 Recovery: a hit gives " + gain + " adrenaline (expected 0.5 x " + base + ")");
		witcher.AddBuffImmunity_AllNegative('gmtest', true);
		GMTestReport(witcher.HasBuff(EET_Mutation7Debuff) && !witcher.IsImmuneToBuff(EET_Mutation7Debuff), "MUT-07 Recovery is not cleansed or blocked by an immunity to negative effects");
		witcher.RemoveBuffImmunity_AllNegative('gmtest');
	}
	else
	{
		witcher.RemoveBuff(EET_Mutation7Debuff);
		GMTestReport(witcher.HasBuff(EET_Mutation7Buff) && !witcher.HasBuff(EET_Mutation7Debuff), "MUT-07 Recovery ended in combat: the next Rush");
		GMTestReport(StrContains(witcher.GetMutationLocalizedDescription(EPMT_Mutation7), "50%"), "MUT-07 description: " + witcher.GetMutationLocalizedDescription(EPMT_Mutation7));
		witcher.RemoveBuff(EET_Mutation7Buff);
		witcher.RemoveBuff(EET_Mutation7Debuff);
		witcher.ForceSetStat(BCS_Focus, 0);
	}
}

// MUT-13: decoctions drunk under Metamorphosis (the drink function the inventory and quick slots
// call, by script): Mutagen 1 to 3 free (no toxicity offset, source "Mutation12"), the chance factor
// 1.1, 1.2, 1.3; Mutagen 4 paid.
exec function gmtest_mut13_drink()
{
	var witcher : W3PlayerWitcher;
	var ids : array<SItemUniqueId>;
	var names : array<name>;
	var i, free, all : int;
	var before, after : float;
	var buffs : array<CBaseGameplayEffect>;

	witcher = GetWitcherPlayer();
	GMTestPam().DEBUG_DevelopAndEquipMutation(EPMT_Mutation12);
	buffs = witcher.GetDrunkMutagens();
	for(i = 0; i < buffs.Size(); i += 1)
		witcher.RemoveEffect(buffs[i]);
	witcher.ForceSetStat(BCS_Toxicity, 0);
	names.PushBack('Mutagen 1'); names.PushBack('Mutagen 2'); names.PushBack('Mutagen 3'); names.PushBack('Mutagen 4');
	for(i = 0; i < names.Size(); i += 1)
	{
		ids = witcher.inv.AddAnItem(names[i], 1);
		before = witcher.GetStat(BCS_Toxicity, false);
		witcher.DrinkPreparedPotion(EES_InvalidSlot, ids[0]);
		after = witcher.GetStat(BCS_Toxicity, false);
		buffs = witcher.GetDrunkMutagens("Mutation12");
		free = buffs.Size();
		buffs = witcher.GetDrunkMutagens();
		all = buffs.Size();
		LogChannel('GMTest', "INFO " + names[i] + ": toxicity " + before + " -> " + after + ", free decoctions " + free + ", all decoctions " + all + ", chance x" + witcher.GMMutation12ChanceMult());
		if(i < 3)
			GMTestReport(free == i + 1 && after - before < 0.01 && AbsF(witcher.GMMutation12ChanceMult() - (1 + 0.1 * (i + 1))) < 0.0001, "MUT-13 decoction " + (i + 1) + " free: no toxicity, chance x" + witcher.GMMutation12ChanceMult());
		else
			GMTestReport(free == 3 && all == 4 && after - before > 1, "MUT-13 decoction 4 paid: toxicity +" + (after - before) + ", still 3 free");
	}
	GMTestReport(StrContains(witcher.GetMutationLocalizedDescription(EPMT_Mutation12), "1.3"), "MUT-13 description: " + witcher.GetMutationLocalizedDescription(EPMT_Mutation12));
}

// MUT-13: a non-sign effect (burning, a critical effect, applied with chance 1 by a scripted hit; legacy resists and raises only critical and other negative effects, not bleeding or poison) on the test dummy with
// 20% burning resistance: 20 hits; with 3 free decoctions (x1.3: 0.8 x 1.3 > 1) every hit burns,
// without them (x1, 80%) not all. Then 100% resistance: none.
function GMTestMut13Burns(npc : CNewNPC, hits : int) : int
{
	var action : W3Action_Attack;
	var i, n : int;

	for(i = 0; i < hits; i += 1)
	{
		npc.RemoveAllBuffsOfType(EET_Burning);
		action = new W3Action_Attack in theGame.damageMgr;
		action.Init(thePlayer, npc, NULL, GetInvalidUniqueId(), 'attack_light', thePlayer.GetName(), EHRT_Light,
			false, false, 'attack_light', AST_Jab, ASD_UpDown, true, false, false, false);
		action.AddDamage(theGame.params.DAMAGE_NAME_PHYSICAL, 10);
		action.AddEffectInfo(EET_Burning, 5);
		action.SetSuppressHitSounds(true);
		action.SetHitAnimationPlayType(EAHA_ForceNo);
		theGame.damageMgr.ProcessAction(action);
		delete action;
		if(npc.HasBuff(EET_Burning))
			n += 1;
	}
	npc.RemoveAllBuffsOfType(EET_Burning);
	npc.ForceSetStat(BCS_Vitality, npc.GetStatMax(BCS_Vitality));
	return n;
}

exec function gmtest_mut13_effect(withDecoctions : bool)
{
	var npc : CNewNPC;
	var n : int;

	var pts, prc : float;

	npc = GMTestDummy();
	GMTestDummySet(npc, 'burning_resistance_perc', 0.2);
	npc.GetResistValue(theGame.effectMgr.GetBuffResistStat(EET_Burning), pts, prc);
	LogChannel('GMTest', "INFO dummy burning resistance " + prc + " (" + theGame.effectMgr.GetBuffResistStat(EET_Burning) + "), negative effect " + IsNegativeEffectType(EET_Burning));
	n = GMTestMut13Burns(npc, 20);
	if(withDecoctions)
		GMTestReport(n == 20, "MUT-13 burning through 20% resistance with chance x" + GetWitcherPlayer().GMMutation12ChanceMult() + ": " + n + " of 20 hits (expected all)");
	else
		GMTestReport(n < 20 && n > 8, "MUT-13 burning through 20% resistance, chance x" + GetWitcherPlayer().GMMutation12ChanceMult() + ": " + n + " of 20 hits (expected about 16)");
	GMTestDummySet(npc, 'burning_resistance_perc', 1);
	n = GMTestMut13Burns(npc, 5);
	GMTestReport(n == 0, "MUT-13 burning through 100% resistance: " + n + " of 5 hits (non-sign effects resisted)");
	GMTestDummySet(npc, 'burning_resistance_perc', 0);
}

// MUT-06, with a neutral test dummy (any kind): gmtest_mut06_hits() equips Deadly Counter and makes
// scripted light hits (DEF-07's countered flag set by script): the damage factor with 3 adrenaline,
// the kill at 10% health when countered (not at 20%, not without the flag). The dummy dies: spawn a
// new one for the next call.
function GMTestMut06Hit(npc : CActor, countered : bool, healthPerc : float, focus : float) : float
{
	var action : W3Action_Attack;
	var dealt, formula : float;
	var i : int;

	npc.GMSetWasCountered(countered);
	if(npc.UsesEssence())
		npc.ForceSetStat(BCS_Essence, healthPerc * npc.GetStatMax(BCS_Essence));
	else
		npc.ForceSetStat(BCS_Vitality, healthPerc * npc.GetStatMax(BCS_Vitality));
	thePlayer.ForceSetStat(BCS_Focus, focus);
	action = new W3Action_Attack in theGame.damageMgr;
	action.Init(thePlayer, npc, NULL, GetInvalidUniqueId(), 'attack_light', thePlayer.GetName(), EHRT_Light,
		false, false, 'attack_light', AST_Jab, ASD_UpDown, true, false, false, false);
	action.AddDamage(theGame.params.DAMAGE_NAME_PHYSICAL, 100);
	action.SetSuppressHitSounds(true);
	action.SetHitAnimationPlayType(EAHA_ForceNo);
	thePlayer.GMTestSetProbes(true);
	thePlayer.GMTestDmgReset();
	theGame.damageMgr.ProcessAction(action);
	dealt = action.GetDamageDealt();
	delete action;
	npc.GMSetWasCountered(false);
	// the final-damage factor: damage dealt over the formula's result (the hit's raw damage is random)
	for(i = 0; i < thePlayer.gmTestDmgSteps.Size(); i += 1)
		formula += thePlayer.gmTestDmgSteps[i].result;
	if(formula > 0)
		return dealt / formula;
	return 0;
}

exec function gmtest_mut06_hits(kill : bool)
{
	var npc : CActor;
	var plain, countered, expected : float;
	var min, max : SAbilityAttributeValue;

	npc = GMTestHostileNpc();
	if(!npc)
	{
		GMTestReport(false, "MUT-06: needs a hostile test dummy nearby");
		return;
	}
	GMTestPam().DEBUG_DevelopAndEquipMutation(EPMT_Mutation8);
	GMTestDummySet((CNewNPC)npc, 'critical_hit_damage_reduction', 1);	// crits (a countered enemy takes +25% crit chance) add nothing
	if(!kill)
	{
		plain = GMTestMut06Hit(npc, false, 1, 3);
		countered = GMTestMut06Hit(npc, true, 1, 3);
		theGame.GetDefinitionsManager().GetAbilityAttributeValue('Mutation8', 'dmg_bonus', min, max);
		expected = 1 + 3 * min.valueMultiplicative;
		GMTestReport(plain > 0 && AbsF(countered / plain - expected) < 0.001, "MUT-06 a hit on a countered enemy with 3 adrenaline: final-damage factor x" + countered + " against x" + plain + " (ratio " + (countered / plain) + ", expected " + expected + ")");
		GMTestMut06Hit(npc, false, 0.1, 0);
		GMTestReport(npc.IsAlive(), "MUT-06 not countered, at 10% health: alive after the hit");
		GMTestMut06Hit(npc, true, 0.2, 0);
		GMTestReport(npc.IsAlive(), "MUT-06 countered, at 20% health: alive after the hit");
		if(npc.UsesEssence())
			npc.ForceSetStat(BCS_Essence, npc.GetStatMax(BCS_Essence));
		else
			npc.ForceSetStat(BCS_Vitality, npc.GetStatMax(BCS_Vitality));
		GMTestReport(StrContains(GetWitcherPlayer().GetMutationLocalizedDescription(EPMT_Mutation8), "15%"), "MUT-06 description: " + GetWitcherPlayer().GetMutationLocalizedDescription(EPMT_Mutation8));
	}
	else
	{
		GMTestMut06Hit(npc, true, 0.1, 0);
		GMTestReport(!npc.IsAlive(), "MUT-06 countered, at 10% health: " + npc.GetDisplayName() + " killed by the hit (human " + npc.IsHuman() + ")");
	}
}

// MUT-06: the counter check against a human dummy at 10% health with Deadly Counter: the repel to a
// finisher, first in the order; at full health a normal repel.
exec function gmtest_mut06_repel()
{
	var npc : CNewNPC;
	var repel : int;
	var ok : bool;

	npc = (CNewNPC)GMTestHostileNpc();
	GMTestPam().DEBUG_DevelopAndEquipMutation(EPMT_Mutation8);
	thePlayer.GainStat(BCS_Stamina, thePlayer.GetStatMax(BCS_Stamina));
	npc.ForceSetStat(BCS_Vitality, npc.GetStatMax(BCS_Vitality));
	thePlayer.GMTestCounterCheck(npc, true, 'attack_light', repel);
	GMTestReport(repel != (int)PRT_RepelToFinisher, "MUT-06 counter at full health: a normal repel (" + repel + ")");
	npc.RemoveAllBuffsOfType(EET_CounterStrikeHit);
	thePlayer.GainStat(BCS_Stamina, thePlayer.GetStatMax(BCS_Stamina));
	npc.ForceSetStat(BCS_Vitality, 0.1 * npc.GetStatMax(BCS_Vitality));
	GMTestReport(!npc.GMMutation8RepelToFinisherImmune(), "MUT-06 the human at 10% health can be repelled to a finisher");
	ok = thePlayer.GMTestCounterCheck(npc, true, 'attack_light', repel);
	LogChannel('GMTest', "INFO counter check " + ok + ", state " + thePlayer.GetCurrentStateName() + ", combat " + thePlayer.IsInCombat());
	GMTestReport(repel == (int)PRT_RepelToFinisher, "MUT-06 counter at 10% health: the repel to a finisher (" + repel + ", expected " + (int)PRT_RepelToFinisher + ")");
}

// MUT-11, a bolt (after gmtest_dummy("human") and gmtest_dummy_neutral()): gmtest_mut11_setup(on)
// equips Cat Eyes or no mutation and arms the probe; a quick crossbow shot follows
// (gmtest_skl06_throw(true, false), then (false, false)); gmtest_mut11_read(on) reads the bolt's raw
// damage before and after ProcessDamageIncrease: x2 with the mutation.
exec function gmtest_mut11_setup(on : bool)
{
	if(on)
		GMTestPam().DEBUG_DevelopAndEquipMutation(EPMT_Mutation9);
	else
		GMTestPam().DEBUG_SetEquippedMutation(EPMT_None);
	thePlayer.GMTestMutSignProbe(true);
}

exec function gmtest_mut11_read(on : bool)
{
	var ratio : float;

	if(thePlayer.gmTestMutSignBefore > 0)
		ratio = thePlayer.gmTestMutSignAfter / thePlayer.gmTestMutSignBefore;
	GMTestReport((on && AbsF(ratio - 2) < 0.001) || (!on && AbsF(ratio - 1) < 0.001), "MUT-11 Cat Eyes " + on + ": a bolt's raw damage " + thePlayer.gmTestMutSignBefore + " -> " + thePlayer.gmTestMutSignAfter + " (x" + ratio + ")");
	GMTestReport(StrContains(GetWitcherPlayer().GetMutationLocalizedDescription(EPMT_Mutation9), "25%"), "MUT-11 description: " + GetWitcherPlayer().GetMutationLocalizedDescription(EPMT_Mutation9));
}

@addMethod(PlayerAiming)
function GMTestSetAimType(t : EAimType)
{
	aimType = t;
}

// MUT-11, the aiming slow motion: while aiming a bomb (gmtest_skl06_throw(true, true, true), a second
// earlier), the aim is switched to the crossbow's and its slow motion started, with the given
// toxicity: x0.6 without Cat Eyes or toxicity, x0.35 with both. The bomb's aim is restored.
exec function gmtest_mut11_slomo(on : bool, toxicity : float)
{
	var scale : float;

	if(on)
		GMTestPam().DEBUG_DevelopAndEquipMutation(EPMT_Mutation9);
	else
		GMTestPam().DEBUG_SetEquippedMutation(EPMT_None);
	thePlayer.ForceSetStat(BCS_Toxicity, toxicity);
	if(thePlayer.playerAiming.GetCurrentStateName() != 'Aiming')
	{
		GMTestReport(false, "MUT-11 slow motion: not aiming (state " + thePlayer.playerAiming.GetCurrentStateName() + ")");
		return;
	}
	thePlayer.playerAiming.GMTestSetAimType(AT_Bolt);
	thePlayer.playerAiming.OnAddAimingSloMo();
	scale = theGame.GetTimeScale();
	thePlayer.playerAiming.GMTestSetAimType(AT_Bomb);
	if(on && toxicity > 0)
		GMTestReport(AbsF(scale - 0.35) < 0.001, "MUT-11 aiming the crossbow with Cat Eyes and toxicity: time x" + scale + " (expected 0.35)");
	else
		GMTestReport(AbsF(scale - 0.6) < 0.001, "MUT-11 aiming the crossbow, Cat Eyes " + on + ", toxicity " + toxicity + ": time x" + scale + " (expected 0.6)");
	thePlayer.ForceSetStat(BCS_Toxicity, 0);
}

// MUT-08 Toxic Blood's values: decay -50%; acid 1.5 per toxicity point per second for 5 s; the
// enemy's stamina regeneration -10% (given whole: the tag kept).
function GMTest_mut08()
{
	var dm : CDefinitionsManagerAccessor;
	var min, max : SAbilityAttributeValue;
	var decay, acid, dur, stam : float;
	var tag : bool;

	dm = theGame.GetDefinitionsManager();
	decay = GMMutation4DecayFactor();
	dm.GetAbilityAttributeValue('AcidEffect', 'DirectDamage', min, max);
	acid = min.valueAdditive;
	dm.GetAbilityAttributeValue('AcidEffect', 'duration', min, max);
	dur = min.valueAdditive;
	dm.GetAbilityAttributeValue('Mutation4BloodDebuff', 'staminaRegen', min, max);
	stam = min.valueMultiplicative;
	tag = dm.AbilityHasTag('Mutation4BloodDebuff', 'BlackBloodDebuff');
	GMTestReport(decay == 0.5 && acid == 1.5 && dur == 5 && AbsF(stam + 0.1) < 0.0001 && tag, "MUT-08 Toxic Blood: decay -" + decay + ", acid " + acid + "/s per toxicity point for " + dur + " s, enemy stamina regen " + stam + ", debuff tag " + tag + " (expected 0.5, 1.5, 5, -0.1, true)");
}

// MUT-08, with a neutral test dummy: gmtest_mut08_hit(on, tox) equips Toxic Blood (or no mutation),
// sets the toxicity and makes a scripted melee hit of the dummy's on Geralt: with the mutation and
// toxicity the dummy gets the acid (1.5 x toxicity per second, 5 s) and the stamina debuff, without
// either nothing; gmtest_mut08_read() 6 s later: the acid and the debuff gone, the health it took.
@addField(W3PlayerWitcher)
public var gmTestMut08Hp : float;
@addField(W3PlayerWitcher)
public var gmTestMut08Rate : float;
@addField(W3PlayerWitcher)
public var gmTestMut08Tox : float;
@addField(W3PlayerWitcher)
public var gmTestMut08Time : float;

@addMethod(W3PlayerWitcher)
function GMTestMut08Set(hp : float, rate : float, tox : float, time : float)
{
	if(hp >= 0) gmTestMut08Hp = hp;
	if(rate >= 0) gmTestMut08Rate = rate;
	if(tox >= 0) gmTestMut08Tox = tox;
	if(time >= 0) gmTestMut08Time = time;
}

function GMTestMut08Equip(on : bool, tox : float)
{
	if(on)
		GMTestPam().DEBUG_DevelopAndEquipMutation(EPMT_Mutation4);
	else
		GMTestPam().DEBUG_SetEquippedMutation(EPMT_None);
	thePlayer.ForceSetStat(BCS_Toxicity, tox);
	if(tox > 0 && !thePlayer.HasBuff(EET_Toxicity))
		thePlayer.AddEffectDefault(EET_Toxicity, thePlayer, 'toxicity_change');
}

exec function gmtest_mut08_hit(on : bool, tox : float)
{
	var npc : CActor;
	var action : W3Action_Attack;
	var acid : CBaseGameplayEffect;
	var hp, vit, val : float;
	var ev : SAbilityAttributeValue;

	npc = GMTestHostileNpc();
	if(!npc)
	{
		GMTestReport(false, "MUT-08: needs a hostile test dummy nearby");
		return;
	}
	GMTestMut08Equip(on, tox);
	npc.RemoveAllBuffsOfType(EET_Acid);
	npc.ForceSetStat(BCS_Vitality, npc.GetStatMax(BCS_Vitality));
	thePlayer.ForceSetStat(BCS_Vitality, thePlayer.GetStatMax(BCS_Vitality));
	vit = thePlayer.GetStat(BCS_Vitality);
	action = new W3Action_Attack in theGame.damageMgr;
	action.Init(npc, thePlayer, NULL, GMTestNpcWeapon(npc), 'attack_light', npc.GetName(), EHRT_Light,
		false, false, 'attack_light', AST_Jab, ASD_UpDown, true, false, false, false);
	action.AddDamage(theGame.params.DAMAGE_NAME_PHYSICAL, 100);
	action.SetSuppressHitSounds(true);
	action.SetHitAnimationPlayType(EAHA_ForceNo);
	theGame.damageMgr.ProcessAction(action);
	LogChannel('GMTest', "INFO MUT-08 the dummy's hit took " + (vit - thePlayer.GetStat(BCS_Vitality)) + " Vitality, Mutation 4 triggered " + action.GetMutation4Triggered());
	delete action;
	thePlayer.ForceSetStat(BCS_Vitality, thePlayer.GetStatMax(BCS_Vitality));
	acid = npc.GetBuff(EET_Acid);
	hp = npc.GetStat(BCS_Vitality);
	GetWitcherPlayer().GMTestMut08Set(hp, -1, tox, theGame.GetEngineTimeAsSeconds());
	if(acid)
	{
		ev = acid.GetEffectValue();
		val = ev.valueAdditive;
	}
	if(on && tox > 0)
	{
		GMTestReport(acid && AbsF(val - 1.5 * tox) < 0.01 && AbsF(acid.GetInitialDuration() - 5) < 0.01, "MUT-08 toxicity " + tox + ": the attacker's acid " + val + "/s for " + acid.GetInitialDuration() + " s (expected " + (1.5 * tox) + ", 5)");
		GMTestReport(npc.HasAbility('Mutation4BloodDebuff'), "MUT-08 the attacker's stamina debuff while the acid runs (staminaRegen x" + CalculateAttributeValue(npc.GetAttributeValue('staminaRegen')) + ")");
		GMTestReport(thePlayer.HasBuff(EET_Mutation4) == false || ((W3Effect_Mutation4)thePlayer.GetBuff(EET_Mutation4)).GetStacks() == RoundMath(1.5 * tox), "MUT-08 the HUD counter (if the effect runs): acid per second");
	}
	else
		GMTestReport(!acid && !npc.HasAbility('Mutation4BloodDebuff'), "MUT-08 Toxic Blood " + on + ", toxicity " + tox + ": no acid, no debuff");
	if(on)
		GMTestReport(StrContains(GetWitcherPlayer().GetMutationLocalizedDescription(EPMT_Mutation4), "50%"), "MUT-08 description: " + GetWitcherPlayer().GetMutationLocalizedDescription(EPMT_Mutation4));
}

exec function gmtest_mut08_read()
{
	var npc : CActor;
	var lost, expected : float;

	npc = GMTestHostileNpc();
	lost = GetWitcherPlayer().gmTestMut08Hp - npc.GetStat(BCS_Vitality);
	expected = 1.5 * GetWitcherPlayer().gmTestMut08Tox * 5;
	GMTestReport(!npc.HasBuff(EET_Acid) && !npc.HasAbility('Mutation4BloodDebuff'), "MUT-08 after " + (theGame.GetEngineTimeAsSeconds() - GetWitcherPlayer().gmTestMut08Time) + " s: the acid and the debuff are gone");
	GMTestReport(AbsF(lost - expected) <= 0.05 * expected, "MUT-08 the acid took " + lost + " health (expected about " + expected + ")");
}

// MUT-08, the decay: gmtest_mut08_decay_a(on) sets toxicity 60 with or without Toxic Blood;
// gmtest_mut08_decay_b(on) a few seconds later reads the decay per second; without the mutation it is
// kept as the baseline, with it compared: half the baseline.
exec function gmtest_mut08_decay_a(on : bool)
{
	GMTestMut08Equip(on, 60);
	GetWitcherPlayer().GMTestMut08Set(-1, -1, 60, theGame.GetEngineTimeAsSeconds());
}

exec function gmtest_mut08_decay_b(on : bool)
{
	var w : W3PlayerWitcher;
	var rate : float;

	w = GetWitcherPlayer();
	rate = (w.gmTestMut08Tox - w.GetStat(BCS_Toxicity)) / (theGame.GetEngineTimeAsSeconds() - w.gmTestMut08Time);
	if(!on)
	{
		w.GMTestMut08Set(-1, rate, -1, -1);
		GMTestReport(rate > 0, "MUT-08 toxicity decay without Toxic Blood: " + rate + "/s (in combat " + thePlayer.IsInCombat() + ")");
	}
	else
		GMTestReport(w.gmTestMut08Rate > 0 && AbsF(rate / w.gmTestMut08Rate - 0.5) < 0.05, "MUT-08 toxicity decay with Toxic Blood: " + rate + "/s, x" + (rate / w.gmTestMut08Rate) + " of " + w.gmTestMut08Rate + " (expected x0.5)");
	w.ForceSetStat(BCS_Toxicity, 0);
}

// Diagnostic: an ability's attributes as the game has them (e.g. an expansion's ability Ghost Mode's
// DLC extends or replaces), and whether it has a tag.
exec function gmtest_ability_probe(abl : name, tag : name)
{
	var attrs : array<name>;
	var i : int;
	var s : string;
	var min, max : SAbilityAttributeValue;

	theGame.GetDefinitionsManager().GetAbilityAttributes(abl, attrs);
	for(i = 0; i < attrs.Size(); i += 1)
	{
		theGame.GetDefinitionsManager().GetAbilityAttributeValue(abl, attrs[i], min, max);
		s += attrs[i] + "=" + min.valueBase + "/" + min.valueMultiplicative + "/" + min.valueAdditive + " ";
	}
	LogChannel('GMTest', "INFO " + abl + ": " + attrs.Size() + " attributes, tag " + tag + " " + theGame.GetDefinitionsManager().AbilityHasTag(abl, tag) + ": " + s);
}

// MUT-09 Euphoria's values: the drain factor 0.75; no attack power or sign intensity boost; the
// overdose drain without the effect is 5.x's (DirectDamage x max Vitality).
function GMTest_mut09()
{
	var dm : CDefinitionsManagerAccessor;
	var min, max : SAbilityAttributeValue;
	var factor, boost, drain, expected : float;

	dm = theGame.GetDefinitionsManager();
	dm.GetAbilityAttributeValue('Mutation10Effect', 'mutation10_factor', min, max);
	factor = min.valueMultiplicative;
	dm.GetAbilityAttributeValue('Mutation10Effect', 'mutation10_stat_boost', min, max);
	boost = min.valueMultiplicative;
	dm.GetAbilityAttributeValue('ToxicityEffect', 'DirectDamage', min, max);
	expected = min.valueMultiplicative * thePlayer.GetStatMax(BCS_Vitality);
	if(!thePlayer.HasBuff(EET_Mutation10))
		drain = GetWitcherPlayer().GMGetToxicityDamage();
	else
		drain = expected;
	GMTestReport(factor == 0.75 && boost == 0 && AbsF(drain - expected) < 0.001, "MUT-09 Euphoria: drain factor " + factor + ", stat boost " + boost + ", overdose drain " + drain + "/s (expected 0.75, 0, " + expected + ")");
}

// MUT-09, with a neutral test dummy (in combat), one call per phase (the toxicity effect's update runs
// in between): (1) Euphoria equipped, toxicity 30% of max (below the overdose threshold); (2) no
// effect; combat start by script: still none; toxicity at max; (3) the effect, the drain x1.75, the
// HUD counter, a scripted light hit's raw damage + the drain, the description; toxicity 30% again;
// (4) the effect gone; combat start by script at max toxicity: the effect.
exec function gmtest_mut09(phase : int)
{
	var w : W3PlayerWitcher;
	var npc : CActor;
	var action : W3Action_Attack;
	var maxTox, drain, base, bonus : float;
	var min, max : SAbilityAttributeValue;
	var stacks : int;

	w = GetWitcherPlayer();
	maxTox = w.GetStatMax(BCS_Toxicity);
	theGame.GetDefinitionsManager().GetAbilityAttributeValue('ToxicityEffect', 'DirectDamage', min, max);
	base = min.valueMultiplicative * w.GetStatMax(BCS_Vitality);
	if(phase == 1)
	{
		GMTestPam().DEBUG_DevelopAndEquipMutation(EPMT_Mutation10);
		w.RemoveBuff(EET_Mutation10);
		w.ForceSetStat(BCS_Toxicity, 0.3 * maxTox);
		if(!w.HasBuff(EET_Toxicity))
			w.AddEffectDefault(EET_Toxicity, w, 'toxicity_change');
		LogChannel('GMTest', "INFO MUT-09 toxicity " + w.GetStat(BCS_Toxicity) + " of " + maxTox + ", threshold " + w.GetToxicityDamageThreshold() + ", in combat " + w.IsInCombat());
	}
	else if(phase == 2)
	{
		GMTestReport(!w.HasBuff(EET_Mutation10), "MUT-09 below the overdose threshold: no Euphoria");
		w.OnCombatStart();
		GMTestReport(!w.HasBuff(EET_Mutation10), "MUT-09 combat start below the threshold: no Euphoria");
		w.ForceSetStat(BCS_Toxicity, maxTox);
	}
	else if(phase == 3)
	{
		GMTestReport(w.HasBuff(EET_Mutation10), "MUT-09 overdosed in combat: Euphoria");
		drain = w.GMGetToxicityDamage();
		GMTestReport(AbsF(drain - base * (1 + 0.75 * w.GetStat(BCS_Toxicity) / 100)) < 0.01, "MUT-09 the overdose drain " + drain + "/s (" + base + " x (1 + 0.75 x " + w.GetStat(BCS_Toxicity) + " / 100))");
		stacks = ((W3Effect_Mutation10)w.GetBuff(EET_Mutation10)).GetStacks();
		GMTestReport(stacks == RoundMath(drain), "MUT-09 the HUD counter " + stacks);
		npc = GMTestHostileNpc();
		thePlayer.GMTestMutSignProbe(true);
		action = new W3Action_Attack in theGame.damageMgr;
		action.Init(thePlayer, npc, NULL, thePlayer.inv.GetCurrentlyHeldSword(), 'attack_light', thePlayer.GetName(), EHRT_Light,
			false, false, 'attack_light', AST_Jab, ASD_UpDown, true, false, false, false);
		action.AddDamage(theGame.params.DAMAGE_NAME_PHYSICAL, 100);
		action.SetSuppressHitSounds(true);
		action.SetHitAnimationPlayType(EAHA_ForceNo);
		theGame.damageMgr.ProcessAction(action);
		delete action;
		bonus = thePlayer.gmTestMutSignAfter - thePlayer.gmTestMutSignBefore;
		GMTestReport(thePlayer.gmTestMutSignEntries > 0 && AbsF(bonus - drain * thePlayer.gmTestMutSignEntries) < 0.01, "MUT-09 a light hit's raw damage " + thePlayer.gmTestMutSignBefore + " -> " + thePlayer.gmTestMutSignAfter + " (+" + bonus + " over " + thePlayer.gmTestMutSignEntries + " damage entries; expected " + drain + " each)");
		GMTestReport(StrContains(w.GetMutationLocalizedDescription(EPMT_Mutation10), "0.75%"), "MUT-09 description: " + w.GetMutationLocalizedDescription(EPMT_Mutation10));
		w.ForceSetStat(BCS_Toxicity, 0.3 * maxTox);
	}
	else if(phase == 4)
	{
		GMTestReport(!w.HasBuff(EET_Mutation10), "MUT-09 back below the threshold: Euphoria gone");
		w.ForceSetStat(BCS_Toxicity, maxTox);
		w.OnCombatStart();
		GMTestReport(w.HasBuff(EET_Mutation10), "MUT-09 combat start when overdosed: Euphoria");
		thePlayer.GMTestMutSignProbe(true);
	}
	else
	{
		// after a real Igni cast in phase 4's state (toxicity decays a little meanwhile: 1%)
		drain = w.GMGetToxicityDamage();
		bonus = thePlayer.gmTestMutSignAfter - thePlayer.gmTestMutSignBefore;
		GMTestReport(thePlayer.gmTestMutSignEntries > 0 && AbsF(bonus - drain * thePlayer.gmTestMutSignEntries) < 0.01 * drain, "MUT-09 an Igni hit's raw damage " + thePlayer.gmTestMutSignBefore + " -> " + thePlayer.gmTestMutSignAfter + " (+" + bonus + " over " + thePlayer.gmTestMutSignEntries + " damage entries; expected " + drain + " each)");
		w.ForceSetStat(BCS_Toxicity, 0);
		w.RemoveBuff(EET_Mutation10);
	}
}

// MUT-09, the drain itself (god mode off; after gmtest_mut09(4), Euphoria running at max toxicity):
// gmtest_mut09_drain(false) fills Vitality, gmtest_mut09_drain(true) a few seconds later compares the
// Vitality lost per second with the drain.
exec function gmtest_mut09_drain(read : bool)
{
	var w : W3PlayerWitcher;
	var rate : float;

	w = GetWitcherPlayer();
	if(!read)
	{
		w.ForceSetStat(BCS_Toxicity, w.GetStatMax(BCS_Toxicity));
		w.ForceSetStat(BCS_Vitality, w.GetStatMax(BCS_Vitality));
		w.GMTestMut08Set(w.GetStat(BCS_Vitality), -1, -1, theGame.GetEngineTimeAsSeconds());
		return;
	}
	rate = (w.gmTestMut08Hp - w.GetStat(BCS_Vitality)) / (theGame.GetEngineTimeAsSeconds() - w.gmTestMut08Time);
	GMTestReport(w.HasBuff(EET_Mutation10) && AbsF(rate - w.GMGetToxicityDamage()) < 0.05 * w.GMGetToxicityDamage(), "MUT-09 Vitality lost while overdosed with Euphoria: " + rate + "/s (drain " + w.GMGetToxicityDamage() + "/s)");
	w.ForceSetStat(BCS_Toxicity, 0);
	w.RemoveBuff(EET_Mutation10);
	w.ForceSetStat(BCS_Vitality, w.GetStatMax(BCS_Vitality));
}

// MUT-05 Bloodbath's values: 0.5% attack power per stack, max 500 stacks (250%); 20 per sword skill,
// 10 per other skill, 40 per kill, 1 per 1% of max Vitality lost.
function GMTest_mut05()
{
	var dm : CDefinitionsManagerAccessor;
	var min, max : SAbilityAttributeValue;
	var ap, cap, sword, other, kill, debuff : float;

	dm = theGame.GetDefinitionsManager();
	dm.GetAbilityAttributeValue('Mutation3', 'attack_power', min, max);
	ap = min.valueMultiplicative;
	dm.GetAbilityAttributeValue('Mutation3', 'mutation3_maxcap', min, max);
	cap = min.valueAdditive;
	dm.GetAbilityAttributeValue('Mutation3', 'mutation3_buff_rate_sword', min, max);
	sword = min.valueAdditive;
	dm.GetAbilityAttributeValue('Mutation3', 'mutation3_buff_rate_other', min, max);
	other = min.valueAdditive;
	dm.GetAbilityAttributeValue('Mutation3', 'mutation3_buff_rate_kill', min, max);
	kill = min.valueAdditive;
	dm.GetAbilityAttributeValue('Mutation3', 'mutation3_debuff_rate', min, max);
	debuff = min.valueAdditive;
	GMTestReport(AbsF(ap - 0.005) < 0.00001 && cap == 500 && sword == 20 && other == 10 && kill == 40 && debuff == 1, "MUT-05 Bloodbath: " + ap + " attack power per stack, max " + cap + ", sword skill " + sword + ", other " + other + ", kill " + kill + ", per 1% Vitality lost " + debuff + " (expected 0.005, 500, 20, 10, 40, 1)");
}

function GMTestMut05Stacks() : int
{
	var e : W3Effect_Mutation3;

	e = (W3Effect_Mutation3)thePlayer.GetBuff(EET_Mutation3);
	if(!e)
		return -1;
	return e.GMGetBonusStacks();
}

// MUT-05, with a neutral human test dummy (in combat) and skills equipped (skilleq): (1, expected)
// Bloodbath equipped, combat start by script: the stacks for the equipped skills (expected given by
// the caller), as many Mutation3 abilities; (2) a scripted hit of the dummy's on Geralt (god mode
// off): 1 stack less per 1% of max Vitality lost; (3) the dummy at 1 health killed by a scripted
// sword hit: back to the peak + 40; the description.
exec function gmtest_mut05(phase : int, optional expected : int)
{
	var w : W3PlayerWitcher;
	var npc : CActor;
	var action : W3Action_Attack;
	var slots : array<SSkillSlot>;
	var i, before, after, lost : int;
	var s : string;
	var vit, dealt : float;

	w = GetWitcherPlayer();
	npc = GMTestHostileNpc();
	if(phase == 1)
	{
		slots = w.GetSkillSlots();
		for(i = 0; i < slots.Size(); i += 1)
			if(slots[i].unlocked && slots[i].socketedSkill != S_SUndefined)
				s += SkillEnumToName(slots[i].socketedSkill) + " (path " + w.GetSkillPathType(slots[i].socketedSkill) + ") ";
		LogChannel('GMTest', "INFO MUT-05 equipped: " + s + "; threatened " + w.IsThreatened() + ", in combat " + w.IsInCombat());
		GMTestPam().DEBUG_DevelopAndEquipMutation(EPMT_Mutation3);
		w.RemoveBuff(EET_Mutation3);
		w.OnCombatStart();
		after = GMTestMut05Stacks();
		GMTestReport(after == expected && w.GetAbilityCount('Mutation3') == after, "MUT-05 combat start: " + after + " stacks, " + w.GetAbilityCount('Mutation3') + " Mutation3 abilities, shown +" + ((W3Effect_Mutation3)w.GetBuff(EET_Mutation3)).GetStacks() + "% (expected " + expected + ")");
	}
	else if(phase == 2)
	{
		before = GMTestMut05Stacks();
		w.ForceSetStat(BCS_Vitality, w.GetStatMax(BCS_Vitality));
		vit = w.GetStat(BCS_Vitality);
		action = new W3Action_Attack in theGame.damageMgr;
		action.Init(npc, w, NULL, GMTestNpcWeapon(npc), 'attack_light', npc.GetName(), EHRT_Light,
			false, false, 'attack_light', AST_Jab, ASD_UpDown, true, false, false, false);
		action.AddDamage(theGame.params.DAMAGE_NAME_PHYSICAL, 300);
		action.SetSuppressHitSounds(true);
		action.SetHitAnimationPlayType(EAHA_ForceNo);
		theGame.damageMgr.ProcessAction(action);
		dealt = action.GetDamageDealt();
		delete action;
		lost = RoundMath(dealt / w.GetMaxHealth() * 100);
		after = GMTestMut05Stacks();
		GMTestReport(dealt > 0 && after == before - lost, "MUT-05 a hit took " + dealt + " of " + w.GetMaxHealth() + " Vitality (" + (vit - w.GetStat(BCS_Vitality)) + "): " + before + " -> " + after + " stacks (expected -" + lost + ")");
		w.ForceSetStat(BCS_Vitality, w.GetStatMax(BCS_Vitality));
	}
	else
	{
		before = GMTestMut05Stacks();
		npc.ForceSetStat(BCS_Vitality, 1);
		action = new W3Action_Attack in theGame.damageMgr;
		action.Init(w, npc, NULL, w.inv.GetItemFromSlot('r_weapon'), 'attack_light', w.GetName(), EHRT_Light,
			false, false, 'attack_light', AST_Jab, ASD_UpDown, true, false, false, false);
		action.AddDamage(theGame.params.DAMAGE_NAME_PHYSICAL, 100);
		action.SetSuppressHitSounds(true);
		action.SetHitAnimationPlayType(EAHA_ForceNo);
		theGame.damageMgr.ProcessAction(action);
		delete action;
		after = GMTestMut05Stacks();
		GMTestReport(!npc.IsAlive() && after == Min(expected + 40, 500), "MUT-05 a sword kill (dummy alive " + npc.IsAlive() + "): " + before + " -> " + after + " stacks (expected the peak " + expected + " + 40)");
		GMTestReport(StrContains(w.GetMutationLocalizedDescription(EPMT_Mutation3), "250%"), "MUT-05 description: " + w.GetMutationLocalizedDescription(EPMT_Mutation3));
	}
}

// MUT-10 Mutated Skin's values: 5 s per adrenaline point; no damage reduction; the DoT type registered.
function GMTest_mut10()
{
	var min, max : SAbilityAttributeValue;
	var dur, red : float;
	var type : EEffectType;
	var abl : name;

	EffectNameToType('GMMutation5Effect', type, abl);
	theGame.GetDefinitionsManager().GetAbilityAttributeValue('Mutation5', 'mut5_duration_per_point', min, max);
	dur = min.valueAdditive;
	theGame.GetDefinitionsManager().GetAbilityAttributeValue('Mutation5', 'mut5_dmg_red_perc', min, max);
	red = min.valueAdditive;
	GMTestReport(dur == 5 && red == 0 && type == EET_GMMutation5 && EffectTypeToName(EET_GMMutation5) == 'GMMutation5Effect', "MUT-10 Mutated Skin: " + dur + " s per adrenaline point, damage reduction " + red + ", DoT type " + EffectTypeToName(EET_GMMutation5) + " (expected 5, 0)");
}

// MUT-10, with a neutral test dummy, god mode off: gmtest_mut10(1, on) equips Mutated Skin (or no
// mutation), gives Geralt 2 adrenaline points and full Vitality, and makes a scripted hit of the
// dummy's on him: with the mutation no Vitality lost at once and the DoT for 10 s at the hit's
// damage / 10 per second; without it the damage at once. gmtest_mut10(2) a few seconds later: the
// Vitality lost and the adrenaline drained so far (0.2 per second); then adrenaline 0;
// gmtest_mut10(3): the rest landed at once, the DoT gone, the hit's whole damage lost.
exec function gmtest_mut10(phase : int, optional on : bool)
{
	var w : W3PlayerWitcher;
	var npc : CActor;
	var action : W3Action_Attack;
	var dot : W3GMEffect_Mutation5;
	var lost, dt, dealt : float;

	w = GetWitcherPlayer();
	npc = GMTestHostileNpc();
	if(phase == 1)
	{
		if(on)
			GMTestPam().DEBUG_DevelopAndEquipMutation(EPMT_Mutation5);
		else
			GMTestPam().DEBUG_SetEquippedMutation(EPMT_None);
		w.RemoveAllBuffsOfType(EET_GMMutation5);
		w.ForceSetStat(BCS_Focus, 2);
		w.ForceSetStat(BCS_Vitality, w.GetStatMax(BCS_Vitality));
		action = new W3Action_Attack in theGame.damageMgr;
		action.Init(npc, w, NULL, GMTestNpcWeapon(npc), 'attack_light', npc.GetName(), EHRT_Light,
			false, false, 'attack_light', AST_Jab, ASD_UpDown, true, false, false, false);
		action.AddDamage(theGame.params.DAMAGE_NAME_PHYSICAL, 300);
		action.SetSuppressHitSounds(true);
		action.SetHitAnimationPlayType(EAHA_ForceNo);
		theGame.damageMgr.ProcessAction(action);
		dealt = action.GetDamageDealt();
		delete action;
		lost = w.GetStatMax(BCS_Vitality) - w.GetStat(BCS_Vitality);
		dot = (W3GMEffect_Mutation5)w.GetBuff(EET_GMMutation5);
		w.GMTestMut08Set(dealt, -1, w.GetStat(BCS_Vitality), theGame.GetEngineTimeAsSeconds());
		if(on)
		{
			GMTestReport(dealt > 0 && lost < 1 && dot && AbsF(dot.GetInitialDuration() - 10) < 0.01 && AbsF(dot.GMGetDamagePerSec() - dealt / 10) < 0.01, "MUT-10 a hit of " + dealt + " with 2 adrenaline: " + lost + " Vitality lost at once, the DoT " + dot.GMGetDamagePerSec() + "/s for " + dot.GetInitialDuration() + " s (expected 0, " + (dealt / 10) + ", 10)");
			GMTestReport(StrContains(w.GetMutationLocalizedDescription(EPMT_Mutation5), "15 sec"), "MUT-10 description: " + w.GetMutationLocalizedDescription(EPMT_Mutation5));
		}
		else
			GMTestReport(dealt > 0 && AbsF(lost - dealt) < 1 && !dot, "MUT-10 without the mutation: " + lost + " Vitality lost at once of " + dealt + ", no DoT");
	}
	else if(phase == 2)
	{
		dt = theGame.GetEngineTimeAsSeconds() - w.gmTestMut08Time;
		lost = w.gmTestMut08Tox - w.GetStat(BCS_Vitality);
		dot = (W3GMEffect_Mutation5)w.GetBuff(EET_GMMutation5);
		GMTestReport(dot && AbsF(lost - w.gmTestMut08Hp / 10 * dt) < 0.1 * w.gmTestMut08Hp / 10 * dt, "MUT-10 after " + dt + " s: " + lost + " Vitality lost (expected about " + (w.gmTestMut08Hp / 10 * dt) + ")");
		GMTestReport(AbsF(w.GetStat(BCS_Focus) - (2 - 0.2 * dt)) < 0.15, "MUT-10 adrenaline drained to " + w.GetStat(BCS_Focus) + " (expected about " + (2 - 0.2 * dt) + ")");
		w.ForceSetStat(BCS_Focus, 0);
	}
	else if(phase == 4)
	{
		// a second hit while the DoT runs: the remainder and the new hit over the new duration
		dot = (W3GMEffect_Mutation5)w.GetBuff(EET_GMMutation5);
		dt = dot.GetDurationLeft() * dot.GMGetDamagePerSec();
		action = new W3Action_Attack in theGame.damageMgr;
		action.Init(npc, w, NULL, GMTestNpcWeapon(npc), 'attack_light', npc.GetName(), EHRT_Light,
			false, false, 'attack_light', AST_Jab, ASD_UpDown, true, false, false, false);
		action.AddDamage(theGame.params.DAMAGE_NAME_PHYSICAL, 300);
		action.SetSuppressHitSounds(true);
		action.SetHitAnimationPlayType(EAHA_ForceNo);
		theGame.damageMgr.ProcessAction(action);
		dealt = action.GetDamageDealt();
		delete action;
		dot = (W3GMEffect_Mutation5)w.GetBuff(EET_GMMutation5);
		lost = dot.GMGetDamagePerSec() * dot.GetDurationLeft();
		GMTestReport(AbsF(lost - (dt + dealt)) < 0.02 * (dt + dealt), "MUT-10 a second hit of " + dealt + " with " + dt + " still to come: " + lost + " over " + dot.GetDurationLeft() + " s (" + w.GetStat(BCS_Focus) + " adrenaline)");
		w.RemoveAllBuffsOfType(EET_GMMutation5);
		w.ForceSetStat(BCS_Vitality, w.GetStatMax(BCS_Vitality));
	}
	else
	{
		lost = w.gmTestMut08Tox - w.GetStat(BCS_Vitality) + (w.GetStatMax(BCS_Vitality) - w.gmTestMut08Tox);
		GMTestReport(!w.HasBuff(EET_GMMutation5) && AbsF(lost - w.gmTestMut08Hp) < 0.02 * w.gmTestMut08Hp, "MUT-10 out of adrenaline: the DoT ended, " + lost + " Vitality lost in all (the hit's " + w.gmTestMut08Hp + ")");
		w.ForceSetStat(BCS_Vitality, w.GetStatMax(BCS_Vitality));
	}
}

// MUT-12 Life Leech's values: 6 s, 90 s cooldown, 40 shock damage; the Catalyst: 3 charges, 20
// toxicity; its effect type registered.
function GMTest_mut12()
{
	var dm : CDefinitionsManagerAccessor;
	var min, max : SAbilityAttributeValue;
	var dur, cd, shock, force, ammo, tox : float;
	var type : EEffectType;
	var abl : name;

	dm = theGame.GetDefinitionsManager();
	dm.GetAbilityAttributeValue('Mutation11BuffEffect', 'duration', min, max);
	dur = min.valueAdditive;
	dm.GetAbilityAttributeValue('Mutation11DebuffEffect', 'duration', min, max);
	cd = min.valueAdditive;
	dm.GetAbilityAttributeValue('Mutation11', 'ShockDamage', min, max);
	shock = min.valueAdditive;
	dm.GetAbilityAttributeValue('Mutation11', 'ForceDamage', min, max);
	force = min.valueAdditive;
	dm.GetAbilityAttributeValue('gm_mutation_catalyst_stats', 'ammo', min, max);
	ammo = min.valueAdditive;
	dm.GetAbilityAttributeValue('gm_mutation_catalyst_stats', 'toxicity', min, max);
	tox = min.valueAdditive;
	EffectNameToType('GMMutationTriggerEffect', type, abl);
	GMTestReport(dur == 6 && cd == 90 && shock == 40 && force == 0 && ammo == 3 && tox == 20 && type == EET_GMMutationTrigger, "MUT-12 Life Leech: " + dur + " s, cooldown " + cd + " s, shock " + shock + ", force " + force + "; Catalyst " + ammo + " charges, toxicity " + tox + ", effect " + type + " (expected 6, 90, 40, 0, 3, 20, " + EET_GMMutationTrigger + ")");
}

@addField(W3PlayerWitcher)
public var gmTestMut12Npc : float;

@addMethod(W3PlayerWitcher)
function GMTestMut12Set(npcHp : float)
{
	gmTestMut12Npc = npcHp;
}

// MUT-12, with a neutral test dummy (in combat): gmtest_mut12(1, drink) researches and equips Life
// Leech (the recipe must come with it), gives the Catalyst, 3 adrenaline and half Vitality, and
// drinks it (the inventory's drink function): Life Leech starts, the dummy is drained at the base
// strength x 3 per second; (2) 7 s later: it ended, the cooldown runs, Geralt healed and the dummy
// lost about the drain x the duration; a second Catalyst does nothing during the cooldown.
exec function gmtest_mut12(phase : int)
{
	var w : W3PlayerWitcher;
	var npc : CActor;
	var ids : array<SItemUniqueId>;
	var buff : W3Effect_Mutation11Buff;
	var drain : CBaseGameplayEffect;
	var base, healed, lost, tox : float;
	var ev : SAbilityAttributeValue;
	var recipes : array<name>;

	w = GetWitcherPlayer();
	npc = GMTestHostileNpc();
	if(phase == 1)
	{
		w.RemoveBuff(EET_Mutation11Debuff);
		GMTestPam().DEBUG_DevelopAndEquipMutation(EPMT_Mutation11);
		recipes = w.GetAlchemyRecipes();
		GMTestReport(recipes.Contains('gm_recipe_mutation_catalyst'), "MUT-12 the Catalyst's recipe given with the research");
		ids = w.inv.AddAnItem('gm_mutation_catalyst', 1);
		GMTestReport(ids.Size() > 0 && w.inv.GetItemName(ids[0]) == 'gm_mutation_catalyst', "MUT-12 the Catalyst item: " + GetLocStringByKeyExt(w.inv.GetItemLocalizedNameByUniqueID(ids[0])) + ", " + w.inv.GetItemCategory(ids[0]));
		w.ForceSetStat(BCS_Focus, 3);
		w.ForceSetStat(BCS_Toxicity, 0);
		w.ForceSetStat(BCS_Vitality, 0.3 * w.GetStatMax(BCS_Vitality));
		npc.ForceSetStat(BCS_Vitality, npc.GetStatMax(BCS_Vitality));
		base = w.GMMutation11GetBaseStrength();
		w.DrinkPreparedPotion(EES_InvalidSlot, ids[0]);
		buff = (W3Effect_Mutation11Buff)w.GetBuff(EET_Mutation11Buff);
		drain = npc.GetBuff(EET_VitalityDrain);
		if(drain)
			ev = drain.GetEffectValue();
		tox = w.GetStat(BCS_Toxicity);
		GMTestReport(buff && w.HasBuff(EET_Mutation11Immortal) && AbsF(buff.GMGetDrainStrength() - MaxF(1, base * 3)) < 0.01, "MUT-12 the Catalyst drunk in combat: Life Leech " + w.HasBuff(EET_Mutation11Buff) + ", immortal " + w.HasBuff(EET_Mutation11Immortal) + ", drain " + buff.GMGetDrainStrength() + "/s (base " + base + " x 3 adrenaline, 1 enemy), toxicity +" + tox);
		GMTestReport(drain && AbsF(ev.valueAdditive - buff.GMGetDrainStrength()) < 0.01, "MUT-12 the dummy is drained: " + ev.valueAdditive + "/s for " + drain.GetInitialDuration() + " s");
		w.GMTestMut08Set(w.GetStat(BCS_Vitality), -1, -1, theGame.GetEngineTimeAsSeconds());
		w.GMTestMut12Set(npc.GetStat(BCS_Vitality));
		GMTestReport(StrContains(w.GetMutationLocalizedDescription(EPMT_Mutation11), "90"), "MUT-12 description: " + w.GetMutationLocalizedDescription(EPMT_Mutation11));
		GMTestReport(GetLocStringByKeyExt(GMTestPam().GetMutationNameLocalizationKey(EPMT_Mutation11)) == GetLocStringById(1188318), "MUT-12 the name: " + GetLocStringByKeyExt(GMTestPam().GetMutationNameLocalizationKey(EPMT_Mutation11)));
	}
	else
	{
		healed = w.GetStat(BCS_Vitality) - w.gmTestMut08Hp;
		lost = w.gmTestMut12Npc - npc.GetStat(BCS_Vitality);
		LogChannel('GMTest', "INFO MUT-12 after " + (theGame.GetEngineTimeAsSeconds() - w.gmTestMut08Time) + " s: Geralt healed " + healed + ", the dummy lost " + lost + ", knocked down " + npc.HasBuff(EET_Knockdown) + "/" + npc.HasBuff(EET_HeavyKnockdown));
		GMTestReport(!w.HasBuff(EET_Mutation11Buff) && !w.HasBuff(EET_Mutation11Immortal) && w.HasBuff(EET_Mutation11Debuff) && AbsF(w.GetBuff(EET_Mutation11Debuff).GetInitialDuration() - 90) < 0.1, "MUT-12 ended: the cooldown of " + w.GetBuff(EET_Mutation11Debuff).GetInitialDuration() + " s");
		// Geralt started at 30% Vitality: the heal stops at his maximum
		GMTestReport(healed > 0 && lost > 0 && healed >= 0.95 * MinF(lost, 0.7 * w.GetStatMax(BCS_Vitality)), "MUT-12 Geralt healed " + healed + " (up to his maximum, 70% missing) and the dummy lost " + lost);
		ids = w.inv.AddAnItem('gm_mutation_catalyst', 1);
		w.DrinkPreparedPotion(EES_InvalidSlot, ids[0]);
		GMTestReport(!w.HasBuff(EET_Mutation11Buff), "MUT-12 a Catalyst during the cooldown: no Life Leech");
		w.RemoveBuff(EET_Mutation11Debuff);
		w.ForceSetStat(BCS_Toxicity, 0);
		w.ForceSetStat(BCS_Vitality, w.GetStatMax(BCS_Vitality));
	}
}

// MUT-12: the Catalyst's recipe is known to the alchemy manager (from Ghost Mode's DLC items XML) and
// brews the potion from its ingredients (the alchemy menu's calls, by script).
exec function gmtest_mut12_brew()
{
	var alch : W3AlchemyManager;
	var recipe : SAlchemyRecipe;
	var found : bool;
	var before, after : int;
	var ex : EAlchemyExceptions;

	alch = new W3AlchemyManager in theGame;
	alch.Init();
	found = alch.GetRecipe('gm_recipe_mutation_catalyst', recipe);
	GMTestReport(found && recipe.cookedItemName == 'gm_mutation_catalyst' && recipe.requiredIngredients.Size() == 4, "MUT-12 the recipe: found " + found + ", makes " + recipe.cookedItemName + " from " + recipe.requiredIngredients.Size() + " ingredients");
	thePlayer.inv.AddAnItem('White Gull 1', 1);
	thePlayer.inv.AddAnItem('Rubedo', 1);
	thePlayer.inv.AddAnItem('Nigredo', 1);
	thePlayer.inv.AddAnItem('Vampire blood', 1);
	thePlayer.inv.RemoveItemByName('gm_mutation_catalyst', -1);	// a singleton potion: one is enough to refill
	before = thePlayer.inv.GetItemQuantityByName('gm_mutation_catalyst');
	ex = alch.CanCookRecipe('gm_recipe_mutation_catalyst', true);
	alch.CookItem('gm_recipe_mutation_catalyst');
	after = thePlayer.inv.GetItemQuantityByName('gm_mutation_catalyst');
	GMTestReport(ex == EAE_NoException && after > before, "MUT-12 brewed: can cook " + ex + ", Catalysts " + before + " -> " + after);
}

// MUT-14, the HUD counters (look at the buff list on screen): 4 shows Toxic Blood at 60 toxicity
// (90: the acid per second), 10 Euphoria at 100 toxicity (the damage per hit), 0 clears both.
exec function gmtest_mut14_hud(m : int)
{
	var w : W3PlayerWitcher;

	w = GetWitcherPlayer();
	w.RemoveBuff(EET_Mutation4);
	w.RemoveBuff(EET_Mutation10);
	if(m == 4)
	{
		GMTestMut08Equip(true, 60);
		w.AddEffectDefault(EET_Mutation4, w, "test", false);
		LogChannel('GMTest', "INFO MUT-14 Toxic Blood's counter should read " + ((W3Effect_Mutation4)w.GetBuff(EET_Mutation4)).GetStacks());
	}
	else if(m == 10)
	{
		GMTestPam().DEBUG_DevelopAndEquipMutation(EPMT_Mutation10);
		w.ForceSetStat(BCS_Toxicity, w.GetStatMax(BCS_Toxicity));
		if(!w.HasBuff(EET_Toxicity))
			w.AddEffectDefault(EET_Toxicity, w, 'toxicity_change');
		w.AddEffectDefault(EET_Mutation10, NULL, "Mutation 10");
		LogChannel('GMTest', "INFO MUT-14 Euphoria's counter should read " + ((W3Effect_Mutation10)w.GetBuff(EET_Mutation10)).GetStacks());
	}
	else
		w.ForceSetStat(BCS_Toxicity, 0);
}

// MUT-14 (audit F11): the mutation texts. Each of the twelve descriptions through the menus' call is
// Ghost Mode's text with its live values (no raw argument, no missing string, nothing empty);
// Mutation 11's name is Life Leech (string 1188318, Ghost Mode's row); the Catalyst's name and
// description; its recipe (four ingredients, one Catalyst).
// What is wrong with a text: "" if nothing.
function GMTestMut14Problem(text : string) : string
{
	if(text == "")
		return "empty";
	if(StrFindFirst(text, "$") >= 0)
		return "raw argument";
	if(StrFindFirst(text, "#") == 0)
		return "missing string";
	return "";
}

function GMTest_mut14()
{
	var w : W3PlayerWitcher;
	var muts : array<EPlayerMutationType>;
	var dm : CDefinitionsManagerAccessor;
	var recipe : SAlchemyRecipe;
	var text, problem, mutName, itemName, itemDesc : string;
	var english : bool;
	var i, ok : int;

	w = GetWitcherPlayer();
	english = GetCurrentTextLocCode() == "EN";
	muts.PushBack(EPMT_Mutation1);	muts.PushBack(EPMT_Mutation2);	muts.PushBack(EPMT_Mutation3);
	muts.PushBack(EPMT_Mutation4);	muts.PushBack(EPMT_Mutation5);	muts.PushBack(EPMT_Mutation6);
	muts.PushBack(EPMT_Mutation7);	muts.PushBack(EPMT_Mutation8);	muts.PushBack(EPMT_Mutation9);
	muts.PushBack(EPMT_Mutation10);	muts.PushBack(EPMT_Mutation11);	muts.PushBack(EPMT_Mutation12);
	for(i = 0; i < muts.Size(); i += 1)
	{
		text = w.GetMutationLocalizedDescription(muts[i]);
		problem = GMTestMut14Problem(text);
		if(problem == "" && text != GMMutationDescription(muts[i]))
			problem = "not Ghost Mode's text";
		if(problem == "")
			ok += 1;
		else
			GMTestReport(false, "MUT-14 Mutation " + (i + 1) + "'s description: " + problem + ": " + text);
	}
	GMTestReport(ok == 12, "MUT-14 the mutation descriptions: " + ok + " of 12 Ghost Mode's, with their values");
	mutName = GetLocStringByKeyExt(GMTestPam().GetMutationNameLocalizationKey(EPMT_Mutation11));
	GMTestReport(mutName == GetLocStringById(1188318) && GMTestMut14Problem(mutName) == "" && (!english || mutName == "Life Leech"), "MUT-14 Mutation 11's name: " + mutName);
	dm = theGame.GetDefinitionsManager();
	itemName = GetLocStringByKeyExt(dm.GetItemLocalisationKeyName('gm_mutation_catalyst'));
	itemDesc = GetLocStringByKeyExt(dm.GetItemLocalisationKeyDesc('gm_mutation_catalyst'));
	GMTestReport(GMTestMut14Problem(itemName) == "" && (!english || itemName == "Mutation Catalyst"), "MUT-14 the Catalyst's name: " + itemName);
	GMTestReport(GMTestMut14Problem(itemDesc) == "" && (!english || StrFindFirst(itemDesc, "Life Leech") >= 0), "MUT-14 the Catalyst's description: " + itemDesc);
	recipe = getAlchemyRecipeFromName('gm_recipe_mutation_catalyst');
	ok = 0;
	for(i = 0; i < recipe.requiredIngredients.Size(); i += 1)
	{
		if(recipe.requiredIngredients[i].quantity == 1)
		{
			switch(recipe.requiredIngredients[i].itemName)
			{
				case 'White Gull 1':
				case 'Rubedo':
				case 'Nigredo':
				case 'Vampire blood':
					ok += 1;
					break;
			}
		}
	}
	GMTestReport(recipe.cookedItemName == 'gm_mutation_catalyst' && recipe.cookedItemQuantity == 1 && recipe.typeName == 'GMMutationTriggerEffect' && recipe.requiredIngredients.Size() == 4 && ok == 4, "MUT-12 the Catalyst's recipe: " + recipe.cookedItemQuantity + " " + recipe.cookedItemName + " (" + recipe.typeName + ") from " + recipe.requiredIngredients.Size() + " ingredients, " + ok + " of White Gull, Rubedo, Nigredo, vampire blood x1");
}

@addField(W3PlayerWitcher)
public var gmTestMut12Base : float;
@addField(W3PlayerWitcher)
public var gmTestMut12CritChance : float;
@addField(W3PlayerWitcher)
public var gmTestMut12CritPower : float;

// Fast and strong crit chance and damage bonus of the Precise Blows and Crushing Blows of the tree in
// force (classic sword_s17 and sword_s08 per level, as legacy's character stats list; the new tree's
// sword_s24 and sword_s25), read without Life Leech's code.
function GMTestMut12Blows(isHeavy : bool, out chance : float, out power : float)
{
	var w : W3PlayerWitcher;
	var skill : ESkill;

	w = GetWitcherPlayer();
	chance = 0;
	power = 0;
	if(isHeavy)
		skill = S_Sword_s08;
	else
		skill = S_Sword_s17;
	if(w.CanUseSkill(skill))
	{
		chance += CalculateAttributeValue(w.GetSkillAttributeValue(skill, theGame.params.CRITICAL_HIT_CHANCE, false, true)) * w.GetSkillLevel(skill);
		power += CalculateAttributeValue(w.GetSkillAttributeValue(skill, theGame.params.CRITICAL_HIT_DAMAGE_BONUS, false, true)) * w.GetSkillLevel(skill);
	}
	if(isHeavy)
		skill = S_Sword_s25;
	else
		skill = S_Sword_s24;
	if(w.CanUseSkill(skill))
	{
		chance += CalculateAttributeValue(w.GetSkillAttributeValue(skill, 'gm_crit_chance', false, false));
		power += CalculateAttributeValue(w.GetSkillAttributeValue(skill, 'gm_crit_damage', false, false)) * w.GetSkillLevel(skill);
	}
}

// MUT-12 (audit F1), the drain's base strength with Precise Blows and Crushing Blows, either tree:
// gmtest_mut12_blows(1) without them records the base strength and the general crit chance and
// damage; equip the tree's two skills (classic S_Sword_s17 and S_Sword_s08, new tree S_Sword_s24 and
// S_Sword_s25), then gmtest_mut12_blows(2): the base strength rose by the average of the fast and
// strong attacks' crit term change, in %.
exec function gmtest_mut12_blows(phase : int)
{
	var w : W3PlayerWitcher;
	var cc, cp, fc, fp, sc, sp, before, after, expected : float;

	w = GetWitcherPlayer();
	cc = CalculateAttributeValue(w.GetAttributeValue(theGame.params.CRITICAL_HIT_CHANCE));
	cp = CalculateAttributeValue(w.GetAttributeValue(theGame.params.CRITICAL_HIT_DAMAGE_BONUS));
	GMTestMut12Blows(false, fc, fp);
	GMTestMut12Blows(true, sc, sp);
	if(phase == 1)
	{
		w.gmTestMut12Base = w.GMMutation11GetBaseStrength();
		w.gmTestMut12CritChance = cc;
		w.gmTestMut12CritPower = cp;
		GMTestReport(fc == 0 && sc == 0, "MUT-12 blows: base strength " + w.gmTestMut12Base + " without the skills (crit chance " + cc + ", damage " + cp + ")");
		return;
	}
	before = ClampF(w.gmTestMut12CritChance, 0, 1) * w.gmTestMut12CritPower;
	after = ( ClampF(cc + fc, 0, 1) * (cp + fp) + ClampF(cc + sc, 0, 1) * (cp + sp) ) / 2.0;
	expected = w.gmTestMut12Base + 100 * (after - before);
	GMTestReport((fc > 0 || fp > 0) && (sc > 0 || sp > 0) && AbsF(w.GMMutation11GetBaseStrength() - expected) < 0.01, "MUT-12 blows (classic tree " + GMIsClassicProfileInForce() + "): base strength " + w.gmTestMut12Base + " -> " + w.GMMutation11GetBaseStrength() + " (expected " + expected + "; fast +" + fc + " chance +" + fp + " damage, strong +" + sc + " chance +" + sp + " damage)");
}

// --- MUT-12 Life Leech's free Quen (legacy's; the owner's decisions of 2026-10-17) ---

@addMethod(W3QuenEntity)
function GMTestShieldDuration() : float
{
	return shieldDuration;
}

// Runs the shock wave as Life Leech's animation event does.
@addMethod(W3PlayerWitcher)
function GMTestMut11ShockWave()
{
	Mutation11ShockWave(false);
}

@addField(W3PlayerWitcher)
public var gmTestMut12Stamina : float;

@addField(W3PlayerWitcher)
public var gmTestMut12Focus : float;

// The free Quen as Life Leech gives it, by script: an alternate Quen of 1000000 health for 10 s, free
// (no stamina, adrenaline or Flood of Anger), flagged; outside Life Leech (nothing holds the channel)
// it ends at once, and starts no cooldown.
function GMTest_mut12_quen()
{
	var w : W3PlayerWitcher;
	var q : W3QuenEntity;
	var stamina, focus : float;
	var st : name;

	w = GetWitcherPlayer();
	w.RemoveAllBuffsOfType(EET_GMQuenCooldown);
	w.ForceSetStat(BCS_Stamina, w.GetStatMax(BCS_Stamina));
	w.DrainStamina(ESAT_FixedValue, 0.5 * w.GetStatMax(BCS_Stamina), 0);
	w.ForceSetStat(BCS_Focus, 2);
	stamina = w.GetStat(BCS_Stamina);
	focus = w.GetStat(BCS_Focus);
	w.gmLifeLeechQuen = NULL;
	w.GMTestMut11ShockWave();
	q = w.gmLifeLeechQuen;
	st = q.GetCurrentStateName();
	GMTestReport(q && q.gmFreeCast && q.IsAlternateCast() && q.GetShieldHealth() == 1000000 && q.GMTestShieldDuration() == 10 && q.GMFoaMult() == 1 && AbsF(w.GetStat(BCS_Stamina) - stamina) < 0.01 && w.GetStat(BCS_Focus) == focus,
		"MUT-12 Life Leech's Quen: free " + q.gmFreeCast + ", alternate " + q.IsAlternateCast() + ", health " + q.GetShieldHealth() + ", " + q.GMTestShieldDuration() + " s, Flood of Anger x" + q.GMFoaMult() + "; stamina " + stamina + " -> " + w.GetStat(BCS_Stamina) + ", adrenaline " + focus + " -> " + w.GetStat(BCS_Focus));
	GMTestReport(q && st != 'QuenChanneled' && !w.HasBuff(EET_GMQuenCooldown), "MUT-12 Life Leech's Quen outside Life Leech ended at once (" + st + "): Quen cooldown " + w.HasBuff(EET_GMQuenCooldown));
	w.ForceSetStat(BCS_Stamina, w.GetStatMax(BCS_Stamina));
	w.ForceSetStat(BCS_Focus, 0);
}

// MUT-12 in a fight (a neutral test dummy in combat; Rage Management equipped to show that no adrenaline
// is paid): gmtest_mut12_quen(1) drinks the Catalyst at 3 adrenaline and half stamina; (2) after the
// animation's shock wave: the free Quen is up and nothing was paid; (3) after Life Leech ended: the free
// Quen ended without a Quen cooldown; (4) logs the state and clears the Quen cooldown before a real
// alternate Quen of Geralt's (autocast); (6) logs that Quen during the cast; (7) starts a scripted
// alternate Quen that is not Life Leech's (RestoreQuen) during Life Leech; (5) after that Quen ended:
// Quen's cooldown runs.
exec function gmtest_mut12_quen(phase : int)
{
	var w : W3PlayerWitcher;
	var q, own : W3QuenEntity;
	var ids : array<SItemUniqueId>;
	var st : name;

	w = GetWitcherPlayer();
	q = w.gmLifeLeechQuen;
	own = (W3QuenEntity)w.GetSignEntity(ST_Quen);
	if(phase == 1)
	{
		w.RemoveBuff(EET_Mutation11Debuff);
		w.RemoveAllBuffsOfType(EET_GMQuenCooldown);
		GMTestPam().DEBUG_DevelopAndEquipMutation(EPMT_Mutation11);
		w.inv.RemoveItemByName('gm_mutation_catalyst', -1);	// a singleton potion: a fresh one has its charges
		ids = w.inv.AddAnItem('gm_mutation_catalyst', 1);
		w.ForceSetStat(BCS_Focus, 3);
		w.ForceSetStat(BCS_Toxicity, 0);
		w.ForceSetStat(BCS_Stamina, w.GetStatMax(BCS_Stamina));
		w.DrainStamina(ESAT_FixedValue, 0.5 * w.GetStatMax(BCS_Stamina), 0);
		w.gmTestMut12Stamina = w.GetStat(BCS_Stamina);
		w.gmTestMut12Focus = w.GetStat(BCS_Focus);
		w.gmLifeLeechQuen = NULL;
		w.DrinkPreparedPotion(EES_InvalidSlot, ids[0]);
		LogChannel('GMTest', "INFO MUT-12 Quen: Catalyst drunk, Life Leech " + w.HasBuff(EET_Mutation11Buff) + ", Rage Management " + w.GMHasRageManagement() + ", stamina " + w.gmTestMut12Stamina + ", adrenaline " + w.gmTestMut12Focus);
	}
	else if(phase == 2)
	{
		st = q.GetCurrentStateName();
		GMTestReport(q && q.gmFreeCast && q.IsAlternateCast() && st == 'QuenChanneled' && q.GetShieldHealth() == 1000000 && q.GMTestShieldDuration() == 10 && w.GetStat(BCS_Stamina) >= w.gmTestMut12Stamina - 0.01 && w.GetStat(BCS_Focus) >= w.gmTestMut12Focus - 0.01,
			"MUT-12 Life Leech's Quen in the fight: free " + q.gmFreeCast + ", alternate " + q.IsAlternateCast() + ", " + st + ", health " + q.GetShieldHealth() + ", " + q.GMTestShieldDuration() + " s, Flood of Anger x" + q.GMFoaMult() + ", used adrenaline " + q.GetUsedFocus() + "; stamina " + w.gmTestMut12Stamina + " -> " + w.GetStat(BCS_Stamina) + ", adrenaline " + w.gmTestMut12Focus + " -> " + w.GetStat(BCS_Focus) + "; Life Leech " + w.HasBuff(EET_Mutation11Buff));
	}
	else if(phase == 3)
	{
		GMTestReport(!w.HasBuff(EET_Mutation11Buff) && w.HasBuff(EET_Mutation11Debuff) && (!q || q.GetCurrentStateName() != 'QuenChanneled') && !w.HasBuff(EET_GMQuenCooldown),
			"MUT-12 after Life Leech: its cooldown " + w.HasBuff(EET_Mutation11Debuff) + ", the free Quen " + q.GetCurrentStateName() + " (gone " + !q + "), Quen cooldown " + w.HasBuff(EET_GMQuenCooldown) + ", stamina " + w.GetStat(BCS_Stamina) + ", adrenaline " + w.GetStat(BCS_Focus));
	}
	else if(phase == 4)
	{
		w.RemoveAllBuffsOfType(EET_GMQuenCooldown);
		LogChannel('GMTest', "INFO MUT-12 before Geralt's own alternate Quen: Life Leech " + w.HasBuff(EET_Mutation11Buff) + ", its cooldown " + w.HasBuff(EET_Mutation11Debuff) + ", Quen cooldown cleared");
	}
	else if(phase == 7)
	{
		// an alternate Quen that is not Life Leech's (5.x's restored one, as a load starts it) during Life Leech
		w.RemoveAllBuffsOfType(EET_GMQuenCooldown);
		w.RestoreQuen(1000, 10, true);
		own = (W3QuenEntity)w.GetSignEntity(ST_Quen);
		LogChannel('GMTest', "INFO MUT-12 a scripted alternate Quen during Life Leech " + w.HasBuff(EET_Mutation11Buff) + ": " + own.GetCurrentStateName() + ", alternate " + own.IsAlternateCast() + ", free " + own.gmFreeCast + "; Life Leech's Quen " + q.GetCurrentStateName() + ", Quen cooldown " + w.HasBuff(EET_GMQuenCooldown));
	}
	else if(phase == 6)
	{
		LogChannel('GMTest', "INFO MUT-12 Geralt's own Quen during the cast: " + own.GetCurrentStateName() + ", alternate " + own.IsAlternateCast() + ", free " + own.gmFreeCast + ", Life Leech " + w.HasBuff(EET_Mutation11Buff) + ", Quen cooldown " + w.HasBuff(EET_GMQuenCooldown));
	}
	else
	{
		GMTestReport(w.HasBuff(EET_GMQuenCooldown) && (!own || !own.gmFreeCast && own.GetCurrentStateName() != 'QuenChanneled'),
			"MUT-12 Geralt's own alternate Quen (Life Leech " + w.HasBuff(EET_Mutation11Buff) + ", its cooldown " + w.HasBuff(EET_Mutation11Debuff) + "): " + own.GetCurrentStateName() + ", alternate " + own.IsAlternateCast() + ", Quen cooldown " + w.HasBuff(EET_GMQuenCooldown) + " (" + w.GetBuff(EET_GMQuenCooldown).GetDurationLeft() + " s left)");
	}
}
