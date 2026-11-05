// STAM-10 Exhaustion: paying from max stamina (stamina/exhaustion.ws, exhaustionHud.ws; docs/features/stam.md).
//   GMTest_stam10()   in gmtest_regress(): scripted checks, no fight or input; each restores what it changes. In the
//                     new tree the feature's rules, in the classic tree that it is off.
// In-game checks with real actions (scripted input; new tree, a frozen hostile dummy in front, sword drawn):
//   gmtest_stam10_arm(focus, stamina, debt)   stamina and adrenaline set, max stamina owed, regen paused 30 s
//   gmtest_stam10_act_a(act)                  0 light, 1 heavy, 2 dodge, 3 roll: press and release
//   gmtest_stam10_act_b(act, expect)          expect: 0 refused, 1 paid from max, 2 paid by stamina alone
//   gmtest_stam10_regen_a(debt, full) / _b()  max stamina regen measured (stamina full or at half)
//   gmtest_stam10_meditate()                  MeditationRestoring clears it
//   gmtest_stam10_jump_a() / _b()             a scripted jump: does it cost stamina (STAM-03's jump cost)?
//   gmtest_stam10_hud()                       the HUD hold, the icon function, the panel line
//   gmtest_stam10_clear()                     stacks cleared, stamina and regen back

exec function gmtest_stam10()
{
	thePlayer.GMTestCount(true, true);
	GMTest_stam10();
	LogChannel('GMTest', "SUMMARY stam10: " + thePlayer.gmTestPassed + " passed, " + thePlayer.gmTestFailed + " failed");
}

function GMTestStam10Near(a : float, b : float) : bool
{
	return AbsF(a - b) < 0.01;
}

function GMTest_stam10()
{
	var w : W3PlayerWitcher;
	var stamina, focus, debt : float;
	var prevOn : string;
	var cfg : CInGameConfigWrapper;

	w = GetWitcherPlayer();
	cfg = theGame.GetInGameConfigWrapper();
	stamina = w.GetStat(BCS_Stamina);
	focus = w.GetStat(BCS_Focus);
	debt = w.GMExhDebt();
	prevOn = cfg.GetVarValue('GMGameplayOptions', 'GMExhaustion');
	w.GMExhClear();

	GMTestStam10Data(w);
	if(GMIsNewTreeInForce())
	{
		cfg.SetVarValue('GMGameplayOptions', 'GMExhaustion', "true");
		GMTestStam10Check(w);
		GMTestStam10Drain(w);
		GMTestStam10Gains(w);
		GMTestStam10Regen(w);
		GMTestStam10Load(w, true);
		GMTestStam10Cross(w);
		GMTestStam10Hud(w);
		GMTestStam10HorseAxii(w);
		cfg.SetVarValue('GMGameplayOptions', 'GMExhaustion', "false");
		GMTestStam10Off(w, "the option off");
		GMTestStam10Load(w, false);
	}
	else
	{
		GMTestStam10Off(w, "the classic tree in force");
		GMTestStam10Load(w, false);
	}

	cfg.SetVarValue('GMGameplayOptions', 'GMExhaustion', prevOn);
	w.GMExhClear();
	if(debt > 0)
		w.GMExhSetDebt(debt);
	w.ForceSetStat(BCS_Focus, focus);
	w.ForceSetStat(BCS_Stamina, stamina);
	w.SetShowToLowStaminaIndication(0);
	w.ResumeStaminaRegen(StaminaActionTypeToName(ESAT_FixedValue));
	w.StartStaminaRegen();
}

// Stamina 0, adrenaline set, nothing owed, regen not ticking within the call.
function GMTestStam10Set(w : W3PlayerWitcher, stamina : float, focus : float, debt : float)
{
	w.GMExhClear();
	if(debt > 0)
		w.GMExhSetDebt(debt);
	w.ForceSetStat(BCS_Focus, focus);
	w.ForceSetStat(BCS_Stamina, stamina);
	w.SetShowToLowStaminaIndication(0);
}

// The ability and the defaults.
function GMTestStam10Data(w : W3PlayerWitcher)
{
	var full, before : float;

	full = w.GetStatMax(BCS_Stamina);
	w.ForceSetStat(BCS_Stamina, full);
	w.AddAbilityMultiple(GMExhaustionAbility(), 30);
	GMTestReport(w.GMExhStacks() == 30 && GMTestStam10Near(w.GetStatMax(BCS_Stamina), full - 30) && GMTestStam10Near(w.GetStat(BCS_Stamina), full - 30) && GMTestStam10Near(w.GMFullMaxStamina(), full),
		"STAM-10 30 stacks of " + NameToString(GMExhaustionAbility()) + ": max " + NoTrailZeros(full) + " -> " + NoTrailZeros(w.GetStatMax(BCS_Stamina)) + ", stamina " + NoTrailZeros(w.GetStat(BCS_Stamina)) + ", full max read " + NoTrailZeros(w.GMFullMaxStamina()));
	w.UpdateStatMax(BCS_Stamina);
	GMTestReport(GMTestStam10Near(w.GetStatMax(BCS_Stamina), full - 30), "STAM-10 the stacks hold through UpdateStatMax: " + NoTrailZeros(w.GetStatMax(BCS_Stamina)));
	before = w.GetStat(BCS_Stamina);
	w.GMExhClear();
	GMTestReport(w.GMExhStacks() == 0 && GMTestStam10Near(w.GetStatMax(BCS_Stamina), full) && w.GetStat(BCS_Stamina) >= before,
		"STAM-10 cleared: max " + NoTrailZeros(w.GetStatMax(BCS_Stamina)) + ", stamina " + NoTrailZeros(w.GetStat(BCS_Stamina)));
	GMTestReport(GMOptionDefault('GMGameplayOptions', 'GMExhaustion') == "true" && GMOptionDefault('GMGameplayOptions', 'GMExhaustionMaxRegen') == "0.4"
		&& GMOptionDefault('GMGameplayOptions', 'GMExhaustionAdrenaline') == "0.03" && GMOptionDefault('GMGameplayOptions', 'GMExhaustionFloor') == "40",
		"STAM-10 option defaults on, 0.4, 0.03, 40; read " + NoTrailZeros(GMExhaustionMaxRegenMult()) + ", " + NoTrailZeros(GMExhaustionAdrenalineRate()) + ", " + NoTrailZeros(GMExhaustionFloor()));
}

// The check at the press.
function GMTestStam10Check(w : W3PlayerWitcher)
{
	var dodge, light : float;

	dodge = w.GetStaminaActionCost(ESAT_Dodge, '', 0);
	light = w.GetStaminaActionCost(ESAT_LightAttack, '', 0);

	GMTestStam10Set(w, 0, 3, 0);
	GMTestReport(w.HasStaminaToUseAction(ESAT_Dodge) && w.HasStaminaToUseAction(ESAT_Roll) && w.HasStaminaToUseAction(ESAT_LightAttack)
		&& w.HasStaminaToUseAction(ESAT_HeavyAttack) && w.HasStaminaToUseAction(ESAT_Counterattack) && w.HasStaminaToUseAction(ESAT_Evade)
		&& w.HasStaminaToUseAction(ESAT_LightAttack, , , GMHorsebackStaminaMult()),
		"STAM-10 at 0 stamina with 3 adrenaline: dodge, roll, light, heavy, counter, evade and the horseback swing pass the check");
	GMTestReport(w.GetShowToLowStaminaIndication() == 0, "STAM-10 no \"stamina needed\" indication for them");
	// sprint is per second: its check passes dt (0 would ask a cost of 0)
	GMTestReport(!w.HasStaminaToUseAction(ESAT_Parry) && !w.HasStaminaToUseAction(ESAT_Sprint, '', 1) && !w.HasStaminaToUseAction(ESAT_Jump)
		&& !w.HasStaminaToUseAction(ESAT_UsableItem) && !w.HasStaminaToUseSkill(S_Magic_1, false) && !w.HasStaminaToUseSkill(S_Magic_2, false)
		&& !w.GMHasResourcesForWhirl(0.5),
		"STAM-10 not covered at 0 stamina: parry " + w.HasStaminaToUseAction(ESAT_Parry) + ", sprint " + w.HasStaminaToUseAction(ESAT_Sprint, '', 1) + ", jump " + w.HasStaminaToUseAction(ESAT_Jump)
		+ ", items " + w.HasStaminaToUseAction(ESAT_UsableItem) + ", Aard " + w.HasStaminaToUseSkill(S_Magic_1, false) + ", Igni " + w.HasStaminaToUseSkill(S_Magic_2, false) + ", Whirl " + w.GMHasResourcesForWhirl(0.5));
	w.SetShowToLowStaminaIndication(0);

	// adrenaline for the whole shortfall: a dodge needs cost x 0.03
	GMTestStam10Set(w, 0, dodge * GMExhaustionAdrenalineRate() - 0.01, 0);
	GMTestReport(!w.HasStaminaToUseAction(ESAT_Dodge) && w.GetShowToLowStaminaIndication() > 0,
		"STAM-10 refused with adrenaline " + NoTrailZeros(w.GetStat(BCS_Focus)) + " short of " + NoTrailZeros(dodge * GMExhaustionAdrenalineRate()) + " (indication " + NoTrailZeros(w.GetShowToLowStaminaIndication()) + ")");
	GMTestStam10Set(w, 2, (dodge - 2) * GMExhaustionAdrenalineRate() + 0.001, 0);
	GMTestReport(w.HasStaminaToUseAction(ESAT_Dodge), "STAM-10 with 2 stamina, adrenaline for the rest only: passes");

	// max stamina above the floor for the whole shortfall
	GMTestStam10Set(w, 0, 3, w.GMFullMaxStamina() - GMExhaustionFloor() - dodge + 0.5);
	GMTestReport(!w.HasStaminaToUseAction(ESAT_Dodge), "STAM-10 refused with " + NoTrailZeros(w.GMExhMaxAvailable()) + " max stamina above the floor for a " + NoTrailZeros(dodge) + " dodge");
	GMTestStam10Set(w, 0, 3, w.GMFullMaxStamina() - GMExhaustionFloor());
	GMTestReport(!w.HasStaminaToUseAction(ESAT_Dodge) && GMTestStam10Near(w.GetStatMax(BCS_Stamina), GMExhaustionFloor()),
		"STAM-10 at the floor (max " + NoTrailZeros(w.GetStatMax(BCS_Stamina)) + "): refused");
	w.SetShowToLowStaminaIndication(0);
}

// The payment at the drain.
function GMTestStam10Drain(w : W3PlayerWitcher)
{
	var dodge, light, full, f0 : float;

	dodge = w.GetStaminaActionCost(ESAT_Dodge, '', 0);
	light = w.GetStaminaActionCost(ESAT_LightAttack, '', 0);
	full = w.GMFullMaxStamina();

	GMTestStam10Set(w, 0, 3, 0);
	w.DrainStamina(ESAT_Dodge);
	GMTestReport(GMTestStam10Near(w.GMExhDebt(), dodge) && w.GMExhStacks() == CeilF(dodge - 0.0001) && GMTestStam10Near(w.GetStat(BCS_Focus), 3 - dodge * 0.03)
		&& GMTestStam10Near(w.GetStatMax(BCS_Stamina), full - CeilF(dodge - 0.0001)) && w.GetStat(BCS_Stamina) == 0,
		"STAM-10 a dodge at 0 stamina: max " + NoTrailZeros(full) + " -> " + NoTrailZeros(w.GetStatMax(BCS_Stamina)) + " (owed " + NoTrailZeros(w.GMExhDebt()) + "), adrenaline 3 -> " + NoTrailZeros(w.GetStat(BCS_Focus)));

	w.ForceSetStat(BCS_Stamina, 2);
	f0 = w.GetStat(BCS_Focus);
	w.DrainStamina(ESAT_LightAttack);
	GMTestReport(GMTestStam10Near(w.GMExhDebt(), dodge + light - 2) && w.GMExhStacks() == CeilF(dodge + light - 2 - 0.0001) && GMTestStam10Near(f0 - w.GetStat(BCS_Focus), (light - 2) * 0.03)
		&& w.GetStat(BCS_Stamina) == 0,
		"STAM-10 a light attack with 2 stamina: stamina pays 2, max the rest (owed " + NoTrailZeros(w.GMExhDebt()) + ", " + w.GMExhStacks() + " stacks), adrenaline -" + NoTrailZeros(f0 - w.GetStat(BCS_Focus)));

	// at the hit frame only what can still be paid: here 1 point above the floor, the rest free
	GMTestStam10Set(w, 0, 3, full - GMExhaustionFloor() - 1);
	w.DrainStamina(ESAT_Roll);
	GMTestReport(GMTestStam10Near(w.GMExhDebt(), full - GMExhaustionFloor()) && GMTestStam10Near(w.GetStatMax(BCS_Stamina), GMExhaustionFloor()) && GMTestStam10Near(w.GetStat(BCS_Focus), 3 - 0.03),
		"STAM-10 at payment only 1 point above the floor: 1 paid, the rest free (max " + NoTrailZeros(w.GetStatMax(BCS_Stamina)) + ", adrenaline " + NoTrailZeros(w.GetStat(BCS_Focus)) + ")");
	GMTestStam10Set(w, 0, 0.06, 0);
	w.DrainStamina(ESAT_HeavyAttack);
	GMTestReport(GMTestStam10Near(w.GMExhDebt(), 2) && w.GetStat(BCS_Focus) < 0.0001,
		"STAM-10 at payment adrenaline for 2 points only: 2 paid (owed " + NoTrailZeros(w.GMExhDebt()) + "), adrenaline " + NoTrailZeros(w.GetStat(BCS_Focus)));

	// not covered: no stacks
	GMTestStam10Set(w, 0, 3, 0);
	w.DrainStamina(ESAT_Parry);
	w.DrainStamina(ESAT_Sprint, , , , 1);
	w.DrainStamina(ESAT_Jump);
	w.DrainStamina(ESAT_UsableItem);
	w.DrainStamina(ESAT_Ability, 0, 0, SkillEnumToName(S_Magic_1));
	w.DrainStamina(ESAT_FixedValue, 50, 0);
	GMTestReport(w.GMExhStacks() == 0 && GMTestStam10Near(w.GetStat(BCS_Focus), 3), "STAM-10 parry, sprint, jump, item, sign and fixed drains at 0: nothing from max");
	// the input buffer's suppressed attack drain costs 0: nothing from max
	w.GMSetSuppressAttackDrain(true);
	w.DrainStamina(ESAT_LightAttack);
	w.GMSetSuppressAttackDrain(false);
	GMTestReport(w.GMExhStacks() == 0, "STAM-10 the buffer's suppressed attack drain: nothing from max");
	w.SetShowToLowStaminaIndication(0);
}

// No adrenaline from an attack paid from max.
function GMTestStam10Gains(w : W3PlayerWitcher)
{
	var f0 : float;
	var n : int;

	GMTestStam10Set(w, 0, 1, 0);
	w.DrainStamina(ESAT_LightAttack);
	f0 = w.GetStat(BCS_Focus);
	w.GMExhAttackContext(true);
	w.GainStat(BCS_Focus, 0.5);
	GMTestReport(GMTestStam10Near(w.GetStat(BCS_Focus), f0), "STAM-10 in the paid attack's hits: +0.5 adrenaline cancelled");
	// a loss reaches the wrapped GainStat (vanilla's GainStat itself ignores amounts below 0)
	n = w.gmExhNullified;
	w.GainStat(BCS_Focus, -0.2);
	GMTestReport(w.gmExhNullified == n, "STAM-10 a loss is not cancelled");
	w.GMExhAttackContext(false);
	w.GainStat(BCS_Focus, 0.3);
	GMTestReport(GMTestStam10Near(w.GetStat(BCS_Focus), f0 + 0.3), "STAM-10 outside the attack's processing gains pass");
	w.GMExhAttackEnded(false);
	w.GMExhOwnActionContext(true);
	w.GainStat(BCS_Focus, 0.3);
	w.GMExhOwnActionContext(false);
	GMTestReport(GMTestStam10Near(w.GetStat(BCS_Focus), f0 + 0.6), "STAM-10 after the attack ended Geralt's next hit gains");
	// Phantom Weapon's delayed heavy hit (a timer the next frame) is still in the window
	w.DrainStamina(ESAT_HeavyAttack);
	w.GMExhAttackEnded(true);
	f0 = w.GetStat(BCS_Focus);
	w.GMExhOwnActionContext(true);
	w.GainStat(BCS_Focus, 0.3);
	w.GMExhOwnActionContext(false);
	GMTestReport(GMTestStam10Near(w.GetStat(BCS_Focus), f0), "STAM-10 Phantom Weapon's delayed hit of a paid heavy attack gains nothing");
	w.GMExhAttackEnded(false);
	// an attack paid by stamina alone gains
	w.ForceSetStat(BCS_Stamina, w.GetStatMax(BCS_Stamina));
	w.DrainStamina(ESAT_LightAttack);
	f0 = w.GetStat(BCS_Focus);
	w.GMExhAttackContext(true);
	w.GainStat(BCS_Focus, 0.3);
	w.GMExhAttackContext(false);
	GMTestReport(GMTestStam10Near(w.GetStat(BCS_Focus), f0 + 0.3), "STAM-10 an attack paid by stamina gains as before");
}

// Max stamina regen, by a direct call of the regen effect's step.
function GMTestStam10Regen(w : W3PlayerWitcher)
{
	var eff : W3Effect_AutoStaminaRegen;
	var v : SAbilityAttributeValue;
	var expected, d0 : float;

	GMTestStam10Set(w, 0, 3, 20);
	w.StartStaminaRegen();
	eff = (W3Effect_AutoStaminaRegen)w.GetBuff(EET_AutoStaminaRegen);
	GMTestReport(eff && GMExhaustionKeepsRegen(w), "STAM-10 the regen runs while max stamina is lowered");
	if(!eff)
		return;
	d0 = w.GMExhDebt();
	eff.GMExhaustionRegen(1.0);
	GMTestReport(GMTestStam10Near(w.GMExhDebt(), d0), "STAM-10 stamina not full: no max stamina regen (owed " + NoTrailZeros(w.GMExhDebt()) + ")");
	w.ForceSetStat(BCS_Stamina, w.GetStatMax(BCS_Stamina));
	// the combat regen, in combat or not: the combat attribute and option (not guarded here), the armor modifier
	v = w.GetAttributeValue('staminaRegen');
	expected = (v.valueAdditive + GMGetOptionFloat('GMGameplayOptions', 'GMCombatStaminaRegen') + v.valueMultiplicative * w.GetStatMax(BCS_Stamina))
		* (1 + w.CalculatedArmorStaminaRegenBonus()) * GMExhaustionMaxRegenMult() * 0.5;
	eff.GMExhaustionRegen(0.5);
	GMTestReport(!w.IsGuarded() && expected > 0 && GMTestStam10Near(d0 - w.GMExhDebt(), MinF(expected, d0)),
		"STAM-10 stamina full (in combat " + w.IsInCombat() + "): 0.5 s of max stamina regen " + NoTrailZeros(d0 - w.GMExhDebt()) + " (expected " + NoTrailZeros(expected) + " = combat regen x " + NoTrailZeros(GMExhaustionMaxRegenMult()) + ")");
	GMTestReport(w.GMExhStacks() == CeilF(w.GMExhDebt() - 0.0001) && GMTestStam10Near(w.GetStat(BCS_Stamina), w.GetStatMax(BCS_Stamina)),
		"STAM-10 the stacks follow (" + w.GMExhStacks() + "), stamina still full (" + NoTrailZeros(w.GetStat(BCS_Stamina)) + " of " + NoTrailZeros(w.GetStatMax(BCS_Stamina)) + ")");
}

// The load rule: kept (regen started) in force; cleared with the option off or the classic tree.
function GMTestStam10Load(w : W3PlayerWitcher, inForce : bool)
{
	GMTestStam10Set(w, 0, 3, 10);
	w.GMExhOnLoad();
	if(inForce)
		GMTestReport(w.GMExhStacks() == 10, "STAM-10 at a load in force: the stacks stay (" + w.GMExhStacks() + ")");
	else
		GMTestReport(w.GMExhStacks() == 0, "STAM-10 at a load not in force: cleared (" + w.GMExhStacks() + ")");
	w.GMExhClear();
}

// What reads the full max: the heartbeat's share, the panel line; Whirl's adrenaline divisor.
function GMTestStam10Cross(w : W3PlayerWitcher)
{
	var full : float;

	full = w.GMFullMaxStamina();
	GMTestStam10Set(w, 0, 3, 30);
	w.ForceSetStat(BCS_Stamina, w.GetStatMax(BCS_Stamina));
	GMTestReport(GMTestStam10Near(w.GMFullMaxStamina(), full) && GMExhaustionPanelMax() == (string)RoundMath(full - 30) + " (" + (string)RoundMath(full) + ")",
		"STAM-10 full max " + NoTrailZeros(w.GMFullMaxStamina()) + " with 30 owed; panel max '" + GMExhaustionPanelMax() + "'");
	w.GMExhClear();
}

// The HUD: the hold and the icon function (no screenshots: what Flash shows is not seen).
function GMTestStam10Hud(w : W3PlayerWitcher)
{
	var hud : CR4ScriptedHud;
	var wolf : CR4HudModuleWolfHead;
	var expected : int;

	hud = (CR4ScriptedHud)theGame.GetHud();
	if(hud)
		wolf = (CR4HudModuleWolfHead)hud.GetHudModule("WolfHeadModule");
	if(!wolf)
	{
		GMTestReport(false, "STAM-10 HUD: no wolf head module");
		return;
	}
	GMTestReport(wolf.GMExhAmountSprite() && wolf.GMExhSignIconDimmedFn(), "STAM-10 HUD: mcStaminaBar.mcAmount and setSignIconDimmed reached");
	GMTestStam10Set(w, 0, 3, 30);
	wolf.gmExhNeededUntil = 0;
	wolf.UpdateStamina();
	expected = FloorF(w.GetStatMax(BCS_Stamina) / w.GMFullMaxStamina() * 100);
	GMTestReport(wolf.gmExhHeldFrame == expected, "STAM-10 HUD: the red stretch held at frame " + wolf.gmExhHeldFrame + " (expected " + expected + ")");
	wolf.gmExhIconUndimmed = 0;
	w.ForceSetStat(BCS_Stamina, w.GetStatMax(BCS_Stamina));
	wolf.UpdateStamina();
	GMTestReport(wolf.gmExhIconUndimmed == 1, "STAM-10 HUD: stamina at the lowered max un-dims the sign icon (" + wolf.gmExhIconUndimmed + ")");
	w.SetShowToLowStaminaIndication(20);
	wolf.UpdateStamina();
	GMTestReport(wolf.gmExhNeededUntil > theGame.GetEngineTimeAsSeconds() && wolf.gmExhHeldFrame == -1, "STAM-10 HUD: vanilla's indication wins for its 2 s");
	wolf.gmExhNeededUntil = 0;
	w.GMExhClear();
	wolf.UpdateStamina();
	GMTestReport(wolf.gmExhHeldFrame == 0, "STAM-10 HUD: without stacks the stretch is let go (" + wolf.gmExhHeldFrame + ")");
}

// Off: the rules of STAM-03 alone.
function GMTestStam10Off(w : W3PlayerWitcher, why : string)
{
	GMTestStam10Set(w, 0, 3, 0);
	GMTestReport(!GMExhaustionOn() && !w.HasStaminaToUseAction(ESAT_Dodge) && !w.HasStaminaToUseAction(ESAT_LightAttack), "STAM-10 off (" + why + "): a dodge and a light attack at 0 stamina refused");
	w.DrainStamina(ESAT_Dodge);
	GMTestReport(w.GMExhStacks() == 0 && GMTestStam10Near(w.GetStat(BCS_Focus), 3), "STAM-10 off (" + why + "): a dodge drain at 0 takes nothing from max or adrenaline");
	w.SetShowToLowStaminaIndication(0);
}

// ---- in-game checks with real actions ----

@addField(W3PlayerWitcher)
var gmTestExhFocus0 : float;
@addField(W3PlayerWitcher)
var gmTestExhDebt0 : float;
@addField(W3PlayerWitcher)
var gmTestExhPaid0 : float;
@addField(W3PlayerWitcher)
var gmTestExhNull0 : int;
@addField(W3PlayerWitcher)
var gmTestExhStam0 : float;
@addField(W3PlayerWitcher)
var gmTestExhT0 : float;

exec function gmtest_stam10_arm(focus : float, optional stamina : float, optional debt : float)
{
	var w : W3PlayerWitcher;

	w = GetWitcherPlayer();
	if(!w.IsWeaponHeld('steelsword') && !w.IsWeaponHeld('silversword'))
		w.OnEquipMeleeWeapon(PW_Steel, true);
	GMTestStam10Set(w, stamina, focus, debt);
	w.PauseStaminaRegen('GMTestStam10', 30);
	LogChannel('GMTest', "INFO STAM-10 armed: stamina " + NoTrailZeros(w.GetStat(BCS_Stamina)) + " of " + NoTrailZeros(w.GetStatMax(BCS_Stamina)) + " (full " + NoTrailZeros(w.GMFullMaxStamina())
		+ "), adrenaline " + NoTrailZeros(w.GetStat(BCS_Focus)) + ", in force " + GMExhaustionOn() + ", combat " + w.IsInCombat() + ", state " + w.GetCurrentStateName());
}

exec function gmtest_stam10_act_a(act : int)
{
	var w : W3PlayerWitcher;

	w = GetWitcherPlayer();
	w.gmTestExhFocus0 = w.GetStat(BCS_Focus);
	w.gmTestExhDebt0 = w.GMExhDebt();
	w.gmTestExhPaid0 = w.gmExhPaid;
	w.gmTestExhNull0 = w.gmExhNullified;
	w.gmTestExhStam0 = w.GetStat(BCS_Stamina);
	thePlayer.GMTestActReset();
	GMTestActInput(act, true);
	GMTestActInput(act, false);
	LogChannel('GMTest', "INFO STAM-10 " + GMTestActName(act) + " pressed: stamina " + NoTrailZeros(w.GetStat(BCS_Stamina)) + ", owed " + NoTrailZeros(w.GMExhDebt()) + ", state " + w.GetCurrentStateName());
}

exec function gmtest_stam10_act_b(act : int, expect : int)
{
	var w : W3PlayerWitcher;
	var i : int;
	var cost, shortfall, paid, focusDrop : float;
	var label : string;

	w = GetWitcherPlayer();
	for(i = 0; i < thePlayer.gmTestDrainLog.Size(); i += 1)
		LogChannel('GMTest', "INFO STAM-10 drain " + thePlayer.gmTestDrainLog[i]);
	label = "STAM-10 real " + GMTestActName(act);
	cost = w.GetStaminaActionCost(GMTestActStaminaAction(act), '', 0);
	shortfall = cost - w.gmTestExhStam0;
	paid = w.gmExhPaid - w.gmTestExhPaid0;
	focusDrop = w.gmTestExhFocus0 - w.GetStat(BCS_Focus);
	LogChannel('GMTest', "INFO " + label + ": cost " + NoTrailZeros(cost) + ", stamina before " + NoTrailZeros(w.gmTestExhStam0) + ", paid from max " + NoTrailZeros(paid)
		+ ", owed " + NoTrailZeros(w.gmTestExhDebt0) + " -> " + NoTrailZeros(w.GMExhDebt()) + ", max " + NoTrailZeros(w.GetStatMax(BCS_Stamina)) + " of " + NoTrailZeros(w.GMFullMaxStamina())
		+ ", adrenaline " + NoTrailZeros(w.gmTestExhFocus0) + " -> " + NoTrailZeros(w.GetStat(BCS_Focus)) + ", gains cancelled " + (w.gmExhNullified - w.gmTestExhNull0)
		+ ", refusals " + (thePlayer.gmStaminaRefusals - thePlayer.gmTestRefusalsBefore) + " (" + thePlayer.gmStaminaRefusalSound + ")");
	if(expect == 0)
	{
		GMTestReport(thePlayer.gmStaminaRefusals > thePlayer.gmTestRefusalsBefore && paid == 0 && GMTestStam10Near(focusDrop, 0), label + " refused, nothing paid from max");
	}
	else if(expect == 1)
	{
		GMTestReport(thePlayer.gmStaminaRefusals == thePlayer.gmTestRefusalsBefore && thePlayer.gmTestPaid.Contains(GMTestActStaminaAction(act)), label + " made and paid");
		GMTestReport(GMTestStam10Near(paid, shortfall) && GMTestStam10Near(w.GMExhDebt() - w.gmTestExhDebt0, shortfall)
			&& GMTestStam10Near(w.GetStatMax(BCS_Stamina), w.GMFullMaxStamina() - CeilF(w.GMExhDebt() - 0.0001)),
			label + ": max stamina lowered by the shortfall " + NoTrailZeros(shortfall));
		GMTestReport(GMTestStam10Near(focusDrop, shortfall * GMExhaustionAdrenalineRate()), label + ": adrenaline drained " + NoTrailZeros(focusDrop) + " = shortfall x " + NoTrailZeros(GMExhaustionAdrenalineRate()) + " (no gain from the hit)");
	}
	else
	{
		GMTestReport(thePlayer.gmStaminaRefusals == thePlayer.gmTestRefusalsBefore && paid == 0, label + " paid by stamina alone, nothing from max");
	}
}

// Max stamina regen measured: debt owed, stamina full (or at half), sampled in _b.
exec function gmtest_stam10_regen_a(debt : float, full : bool)
{
	var w : W3PlayerWitcher;

	w = GetWitcherPlayer();
	GMTestStam10Set(w, 0, 3, debt);
	w.ResumeStaminaRegen('GMTestStam10');
	if(full)
		w.ForceSetStat(BCS_Stamina, w.GetStatMax(BCS_Stamina));
	else
		w.ForceSetStat(BCS_Stamina, w.GetStatMax(BCS_Stamina) * 0.5);
	w.StartStaminaRegen();
	w.gmTestExhDebt0 = w.GMExhDebt();
	w.gmTestExhStam0 = w.GetStat(BCS_Stamina);
	w.gmTestExhT0 = theGame.GetEngineTimeAsSeconds();
	LogChannel('GMTest', "INFO STAM-10 regen sample start: owed " + NoTrailZeros(w.GMExhDebt()) + ", stamina " + NoTrailZeros(w.GetStat(BCS_Stamina)) + " of " + NoTrailZeros(w.GetStatMax(BCS_Stamina))
		+ ", combat " + w.IsInCombat() + ", regen on " + w.HasBuff(EET_AutoStaminaRegen));
}

exec function gmtest_stam10_regen_b()
{
	var w : W3PlayerWitcher;
	var eff : W3Effect_AutoStaminaRegen;
	var v : SAbilityAttributeValue;
	var dt, rate, normal : float;

	w = GetWitcherPlayer();
	dt = theGame.GetEngineTimeAsSeconds() - w.gmTestExhT0;
	rate = (w.gmTestExhDebt0 - w.GMExhDebt()) / dt;
	normal = GMExhaustionRegenPoints(w);	// the combat regen, in combat or not
	LogChannel('GMTest', "INFO STAM-10 regen sample after " + NoTrailZeros(dt) + " s: owed " + NoTrailZeros(w.gmTestExhDebt0) + " -> " + NoTrailZeros(w.GMExhDebt()) + " (" + NoTrailZeros(rate)
		+ "/s), stamina " + NoTrailZeros(w.gmTestExhStam0) + " -> " + NoTrailZeros(w.GetStat(BCS_Stamina)) + " of " + NoTrailZeros(w.GetStatMax(BCS_Stamina))
		+ ", the combat regen " + NoTrailZeros(normal) + "/s x " + NoTrailZeros(GMExhaustionMaxRegenMult()) + " = " + NoTrailZeros(normal * GMExhaustionMaxRegenMult()) + "/s, combat " + w.IsInCombat());
}

exec function gmtest_stam10_meditate()
{
	var w : W3PlayerWitcher;

	w = GetWitcherPlayer();
	GMTestStam10Set(w, 0, 3, 25);
	w.MeditationRestoring(0);
	GMTestReport(w.GMExhStacks() == 0 && GMTestStam10Near(w.GetStatMax(BCS_Stamina), w.GMFullMaxStamina()), "STAM-10 meditation (MeditationRestoring) restores max stamina: " + w.GMExhStacks() + " stacks, max " + NoTrailZeros(w.GetStatMax(BCS_Stamina)));
}

exec function gmtest_stam10_jump_a()
{
	var w : W3PlayerWitcher;

	w = GetWitcherPlayer();
	w.ForceSetStat(BCS_Stamina, w.GetStatMax(BCS_Stamina) * 0.5);
	w.PauseStaminaRegen('GMTestStam10', 10);
	w.gmTestExhStam0 = w.GetStat(BCS_Stamina);
	thePlayer.GMTestActReset();
	w.substateManager.QueueStateExternal('Jump');
	LogChannel('GMTest', "INFO STAM-10 jump queued: stamina " + NoTrailZeros(w.GetStat(BCS_Stamina)) + ", jump cost " + NoTrailZeros(w.GetStaminaActionCost(ESAT_Jump, '', 0)) + ", state " + w.substateManager.GetStateCur());
}

exec function gmtest_stam10_jump_b()
{
	var w : W3PlayerWitcher;
	var i : int;

	w = GetWitcherPlayer();
	for(i = 0; i < thePlayer.gmTestDrainLog.Size(); i += 1)
		LogChannel('GMTest', "INFO STAM-10 drain " + thePlayer.gmTestDrainLog[i]);
	LogChannel('GMTest', "INFO STAM-10 after the jump: stamina " + NoTrailZeros(w.gmTestExhStam0) + " -> " + NoTrailZeros(w.GetStat(BCS_Stamina)) + ", jump drains " + thePlayer.gmTestPaid.Contains(ESAT_Jump)
		+ ", state " + w.substateManager.GetStateCur());
	w.ResumeStaminaRegen('GMTestStam10');
}

exec function gmtest_stam10_hud()
{
	thePlayer.GMTestCount(true, true);
	GMTestStam10Hud(GetWitcherPlayer());
	GMTestStam10Set(GetWitcherPlayer(), GetWitcherPlayer().GetStatMax(BCS_Stamina), GetWitcherPlayer().GetStat(BCS_Focus), 0);
}

exec function gmtest_stam10_clear()
{
	var w : W3PlayerWitcher;

	w = GetWitcherPlayer();
	w.GMExhClear();
	w.ResumeStaminaRegen('GMTestStam10');
	w.ForceSetStat(BCS_Stamina, w.GetStatMax(BCS_Stamina));
	LogChannel('GMTest', "INFO STAM-10 cleared: max " + NoTrailZeros(w.GetStatMax(BCS_Stamina)) + ", stacks " + w.GMExhStacks());
}

exec function gmtest_stam10_info()
{
	var w : W3PlayerWitcher;

	w = GetWitcherPlayer();
	LogChannel('GMTest', "INFO STAM-10 stamina " + NoTrailZeros(w.GetStat(BCS_Stamina)) + " of " + NoTrailZeros(w.GetStatMax(BCS_Stamina)) + " (full " + NoTrailZeros(w.GMFullMaxStamina())
		+ ", owed " + NoTrailZeros(w.GMExhDebt()) + ", " + w.GMExhStacks() + " stacks), adrenaline " + NoTrailZeros(w.GetStat(BCS_Focus)) + ", in force " + GMExhaustionOn()
		+ ", new tree " + GMIsNewTreeInForce() + ", combat " + w.IsInCombat() + ", regen " + w.HasBuff(EET_AutoStaminaRegen));
}

// Horse Axii is a sign, outside STAM-10: with Adrenaline Burst its adrenaline counts against the full max
// stamina, as without exhaustion (owner, 2026-11-04). On a combat manager made for the test (HORSE-02's).
function GMTestStam10HorseAxii(w : W3PlayerWitcher)
{
	var mgr : W3VehicleCombatManager;
	var st : W3VehicleCombatManagerStateCastSign;
	var s : ESkill;
	var had, eq, can : bool;
	var stam, focus, full, want, f1 : float;

	mgr = new W3VehicleCombatManager in theGame;
	st = (W3VehicleCombatManagerStateCastSign)mgr.GetState('CastSign');
	if(!st)
	{
		GMTestReport(false, "STAM-10 horse Axii: no CastSign state");
		return;
	}
	s = S_Perk_42;
	had = w.HasLearnedSkill(s);
	eq = w.IsSkillEquipped(s);
	stam = w.GetStat(BCS_Stamina);
	focus = w.GetStat(BCS_Focus);
	if(!eq)
	{
		if(!had)
			w.AddSkill(s);
		w.EquipSkill(s, w.GetFreeSkillSlot());
	}
	full = w.GMFullMaxStamina();
	w.GMExhSetDebt(30);
	// 1.6 adrenaline is worth 53 stamina against a full max of 100, 37 against the lowered 70
	w.ForceSetStat(BCS_Stamina, 0);
	w.ForceSetStat(BCS_Focus, 1.6);
	can = st.GMTestHorseAxiiHas(w, 1.6 * full / w.GetStatMax(BCS_Focus) - 0.5);
	w.ForceSetStat(BCS_Stamina, 0.3);
	w.ForceSetStat(BCS_Focus, 1);
	st.GMDrainResourcesForAxii(GMHorseAxiiCost() * 0.01);
	f1 = w.GetStat(BCS_Focus);
	want = 1 - (GMHorseAxiiCost() * 0.01 - 0.3) * w.GetStatMax(BCS_Focus) / full;
	GMTestReport(w.GMExhStacks() == 30 && can && AbsF(f1 - want) < 0.0001,
		"STAM-10 horse Axii with 30 owed (max " + NoTrailZeros(w.GetStatMax(BCS_Stamina)) + " of " + NoTrailZeros(full) + "): starts on adrenaline worth the full max " + can
		+ "; a tick at 0.3 stamina leaves adrenaline " + NoTrailZeros(f1) + " (expected " + NoTrailZeros(want) + ")");
	w.GMExhClear();
	if(!eq)
		w.UnequipSkill(w.GetSkillSlotID(s));
	w.ForceSetStat(BCS_Stamina, stam);
	w.ForceSetStat(BCS_Focus, focus);
	delete mgr;
}
