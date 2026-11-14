// Ghost Mode in-game checks: exec functions that report through LogChannel('GMTest', ...),
// for tools/game.py. Each prints one line per check, "PASS ..." or "FAIL ...".

// Counts for gmtest_regress()'s summary.
@addField(CR4Player)
var gmTestPassed : int;
@addField(CR4Player)
var gmTestFailed : int;

// Test probes: the wrappers below that log stamina drains, attacks, parries and NPC decisions do
// nothing until a test that reads their logs switches them on (its reset does), or
// gmtest_probes(true). Off by default, so a test build plays like a normal one.
@addField(CR4Player)
var gmTestProbesOn : bool;

@addMethod(CR4Player)
function GMTestSetProbes(on : bool)
{
	gmTestProbesOn = on;
}

function GMTestProbes() : bool
{
	return thePlayer && thePlayer.gmTestProbesOn;
}

exec function gmtest_probes(on : bool)
{
	thePlayer.GMTestSetProbes(on);
	LogChannel('GMTest', "INFO test probes " + on);
}

@addMethod(CR4Player)
function GMTestCount(ok : bool, optional reset : bool)
{
	if(reset)
	{
		gmTestPassed = 0;
		gmTestFailed = 0;
	}
	else if(ok)
		gmTestPassed += 1;
	else
		gmTestFailed += 1;
}

function GMTestReport(ok : bool, label : string)
{
	thePlayer.GMTestCount(ok);
	if(ok)
		LogChannel('GMTest', "PASS " + label);
	else
		LogChannel('GMTest', "FAIL " + label);
}

// STAM-01: sign cooldown effects register, last as long as configured, and block the sign.
// Works without casting (adds the cooldown directly), so it runs in any save.
exec function gmtest_stam01()
{
	GMTest_stam01();
}

function GMTest_stam01()
{
	var signs : array<ESignType>;
	var i : int;
	var effect : EEffectType;
	var buff : CBaseGameplayEffect;
	var effectName : name;
	var left : float;
	var label : string;
	var expected : float;

	signs.PushBack(ST_Aard);
	signs.PushBack(ST_Axii);
	signs.PushBack(ST_Igni);
	signs.PushBack(ST_Quen);
	signs.PushBack(ST_Yrden);

	for(i = 0; i < signs.Size(); i += 1)
	{
		effect = GMSignCooldownType(signs[i]);
		effectName = EffectTypeToName(effect);
		GMTestReport(IsNameValid(effectName), "STAM-01 effect name " + NameToString(effectName));

		thePlayer.RemoveBuff(effect);
		GMAddSignCooldown(signs[i], i % 2 == 1);
		buff = thePlayer.GetBuff(effect);
		left = 0;
		if(buff)
			left = buff.GetDurationLeft();
		GMTestReport(buff && GMIsSignOnCooldown(signs[i]), "STAM-01 " + NameToString(effectName) + " applied");
		if(i % 2 == 1)
			expected = theGame.params.GMGetAltSignCooldownDuration();
		else
			expected = theGame.params.GMGetSignCooldownDuration();
		GMTestReport(left > expected - 0.5f && left <= expected, "STAM-01 " + NameToString(effectName) + " duration " + FloatToString(left) + " (option " + FloatToString(expected) + ")");
		if(buff)
		{
			// HUD data from Ghost Mode's DLC XML (dlc\dlcghostmode\...\gm_effects.xml)
			GMTestReport(buff.ShowOnHUD(), "STAM-01 " + NameToString(effectName) + " shown on HUD");
			GMTestReport(StrFindFirst(buff.GetIcon(), "icons/Skills/core/magic_") == 0, "STAM-01 " + NameToString(effectName) + " icon " + buff.GetIcon());
			label = GetLocStringByKeyExt(buff.GetEffectNameLocalisationKey());
			GMTestReport(StrFindFirst(label, "cooldown") > 0, "STAM-01 " + NameToString(effectName) + " label '" + label + "'");
		}
		thePlayer.RemoveBuff(effect);
		GMTestReport(!GMIsSignOnCooldown(signs[i]), "STAM-01 " + NameToString(effectName) + " removed");
	}

	GMTestStam01CastGuard();
	GMTestStam01FinisherAard();
}

// ---- STAM-01 (whole-port fix round, C2-2): a cast press while Geralt is already casting ----

@addField(CR4Player)
var gmTestSignSetups : int;		// SetupCombatAction(EBAT_CastSign) calls while gmTestSignArm is on
@addField(CR4Player)
var gmTestSignArm : bool;
@addField(CR4Player)
var gmTestSignCasts : int;		// sign entities created (CastSignSpecific) while gmTestSignArm is on
@addField(CR4Player)
var gmTestDblEnd : float;
@addField(CR4Player)
var gmTestSignSwallow : bool;	// SetupCombatAction(EBAT_CastSign) is counted and not run (no cast starts)

@addMethod(CR4Player)
function GMTestSignArm(on : bool)
{
	gmTestSignArm = on;
	gmTestSignSetups = 0;
	gmTestSignCasts = 0;
}

@addMethod(CR4Player)
function GMTestSignCounted(setup : bool)
{
	if(setup)
		gmTestSignSetups += 1;
	else
		gmTestSignCasts += 1;
}

@wrapMethod(CR4Player)
function SetupCombatAction(action : EBufferActionType, stage : EButtonStage)
{
	if(gmTestSignArm && action == EBAT_CastSign)
	{
		GMTestSignCounted(true);
		if(gmTestSignSwallow)
			return;
	}
	wrappedMethod(action, stage);
}

@wrapMethod(W3PlayerWitcher)
function CastSignSpecific(sign : ESignType, optional skipCastingAnimation : bool) : bool
{
	var ok : bool;

	ok = wrappedMethod(sign, skipCastingAnimation);
	if(gmTestSignArm && ok)
	{
		GMTestSignCounted(false);
		LogChannel('GMTest', "INFO STAM-01 cast " + sign + " started at " + FloatToString(theGame.GetEngineTimeAsSeconds()) + " skipAnim " + skipCastingAnimation);
	}
	return ok;
}

@addMethod(CR4Player)
function GMTestSignSwallow(on : bool)
{
	gmTestSignSwallow = on;
}

@addMethod(CPlayerInput)
function GMTestAltCastSign(signType : ESignType)
{
	AltCastSign(signType);
}

// Situation-free: Geralt put in a combat action of the sign-cast kind with input allowed (the cast's
// recovery, after the throw: the state legacy's guard reads), then a cast press and an
// alternative-casting press (5.x's AltCastSign) must not set up a cast; with another combat action
// (an attack) the same press still does. SetupCombatAction is counted and not run, so no sign is
// cast. Everything is set back.
function GMTestStam01CastGuard()
{
	var witcher : W3PlayerWitcher;
	var prevCA : bool;
	var prevCat, prevJump, prevOverlay : float;
	var prevSign : ESignType;
	var pressSetups, altSetups, controlSetups : int;

	witcher = GetWitcherPlayer();
	if(!witcher)
		return;
	prevCA = witcher.IsInCombatAction();
	prevCat = witcher.GetBehaviorVariable('combatActionType');
	prevJump = witcher.GetBehaviorVariable('inJumpState');
	prevOverlay = witcher.GetBehaviorVariable('isInCombatActionForOverlay');
	prevSign = witcher.GetEquippedSign();
	GMTestReport(witcher.GetBIsInputAllowed() && !witcher.IsCastingSign(), "STAM-01 (C2-2) input allowed and no sign being cast before the check");
	thePlayer.RemoveBuff(EET_GMQuenCooldown);
	thePlayer.GainStat(BCS_Stamina, thePlayer.GetStatMax(BCS_Stamina));
	witcher.SetEquippedSign(ST_Quen);
	witcher.GMTestSignSwallow(true);
	witcher.SetBIsInCombatAction(true);

	// In a sign cast: refused.
	witcher.SetBehaviorVariable('combatActionType', (int)CAT_CastSign);
	witcher.GMTestSignArm(true);
	GMTestCastInput(true);
	GMTestCastInput(false);
	pressSetups = witcher.gmTestSignSetups;
	witcher.GMTestSignArm(true);
	thePlayer.GetInputHandler().GMTestAltCastSign(ST_Quen);
	altSetups = witcher.gmTestSignSetups;

	// Control: in an attack, a cast press is set up (buffered), as in vanilla and legacy.
	witcher.SetBehaviorVariable('combatActionType', (int)CAT_Attack);
	witcher.GMTestSignArm(true);
	GMTestCastInput(true);
	GMTestCastInput(false);
	controlSetups = witcher.gmTestSignSetups;
	witcher.GMTestSignArm(false);
	witcher.GMTestSignSwallow(false);

	witcher.SetBIsInCombatAction(prevCA);
	witcher.SetBehaviorVariable('combatActionType', prevCat);
	witcher.SetBehaviorVariable('inJumpState', prevJump);
	witcher.SetBehaviorVariable('isInCombatActionForOverlay', prevOverlay);
	witcher.SetEquippedSign(prevSign);

	GMTestReport(pressSetups == 0, "STAM-01 (C2-2) a cast press during a sign cast is refused (" + pressSetups + " set up)");
	GMTestReport(altSetups == 0, "STAM-01 (C2-2) an alternative-casting press during a sign cast is refused (" + altSetups + " set up)");
	GMTestReport(controlSetups == 1, "STAM-01 (C2-2) control: a cast press during an attack is set up (" + controlSetups + ")");
	GMTestReport(witcher.IsInCombatAction() == prevCA && witcher.GetEquippedSign() == prevSign && !witcher.IsCastingSign() && witcher.GetBIsInputAllowed(), "STAM-01 (C2-2) state set back, no sign cast");
}

// gmtest_stam01_dbl(sign, seconds) casts the sign through the input handler, then presses the cast
// input again every frame or so for that many seconds (each press logged with the state legacy's guard
// reads); gmtest_stam01_dbl_check() a moment later counts the casts: one cast is right, two are the
// double cast C2-2 is about. With the sign cooldown option at 5, 5.x's own input lock (until after the
// throw) and the cooldown refuse every press; with the option at 0 (autoconfigset, set back after), a
// press in the cast's recovery (input allowed again, still in the cast) casts again without the guard.
@addMethod(CR4Player)
timer function GMTestDblPress(dt : float, id : int)
{
	var witcher : W3PlayerWitcher;

	witcher = GetWitcherPlayer();
	if(theGame.GetEngineTimeAsSeconds() > gmTestDblEnd)
	{
		RemoveTimer('GMTestDblPress');
		LogChannel('GMTest', "INFO STAM-01 dbl presses ended: setups " + gmTestSignSetups + " casts " + gmTestSignCasts);
		return;
	}
	LogChannel('GMTest', "INFO STAM-01 dbl press t=" + FloatToString(theGame.GetEngineTimeAsSeconds())
		+ " inputAllowed=" + GetBIsInputAllowed() + " inCA=" + IsInCombatAction()
		+ " cat=" + FloatToString(GetBehaviorVariable('combatActionType')) + " casting=" + IsCastingSign()
		+ " cooldown=" + GMIsSignOnCooldown(witcher.GetEquippedSign()) + " buffer=" + BufferCombatAction
		+ " setups=" + gmTestSignSetups + " casts=" + gmTestSignCasts);
	GMTestCastInput(true);
	GMTestCastInput(false);
}

@addMethod(CR4Player)
function GMTestDblStart(seconds : float)
{
	gmTestDblEnd = theGame.GetEngineTimeAsSeconds() + seconds;
	AddTimer('GMTestDblPress', 0.05, true);
}

exec function gmtest_stam01_dbl(sign : ESignType, seconds : float)
{
	GetWitcherPlayer().SetEquippedSign(sign);
	thePlayer.GainStat(BCS_Stamina, thePlayer.GetStatMax(BCS_Stamina));
	thePlayer.GMTestSignArm(true);
	GMTestReport(!GMIsSignOnCooldown(sign), "STAM-01 dbl " + sign + " not on cooldown before the cast");
	GMTestCastInput(true);
	GMTestCastInput(false);
	GMTestReport(thePlayer.IsCastingSign(), "STAM-01 dbl " + sign + " first cast started");
	thePlayer.GMTestDblStart(seconds);
}

exec function gmtest_stam01_dbl_check()
{
	LogChannel('GMTest', "INFO STAM-01 dbl setups " + thePlayer.gmTestSignSetups + " casts " + thePlayer.gmTestSignCasts);
	GMTestReport(thePlayer.gmTestSignCasts == 1, "STAM-01 dbl one cast from a press and repeated presses during it (" + thePlayer.gmTestSignCasts + " casts)");
	thePlayer.GMTestSignArm(false);
}

// ---- STAM-01 (whole-port fix round, A1-2): 5.x's Aard finisher casts a free Aard ----

// Situation-free: an Aard entity of Geralt's whose cost is disabled (as 5.x's Aard finisher sets it,
// W3PlayerWitcher.OnAnimEvent_SignFinisher) pays its cast (ManagePlayerStamina, what the throw calls):
// no Aard cooldown, no sign-cast decoction hook (ALCH-10), no stamina. Control: the same entity
// with its cost on starts the cooldown. Nothing is thrown; the entity is removed.
@addField(CR4Player)
var gmTestDecoctionHooks : int;

@addMethod(CR4Player)
function GMTestDecoctionHook(reset : bool)
{
	if(reset)
		gmTestDecoctionHooks = 0;
	else
		gmTestDecoctionHooks += 1;
}

@wrapMethod
function GMDecoctionsOnSignCast()
{
	if(thePlayer)
		thePlayer.GMTestDecoctionHook(false);
	wrappedMethod();
}

@addMethod(W3PlayerWitcher)
function GMTestNewSignEntity(sign : ESignType) : W3SignEntity
{
	return (W3SignEntity)theGame.CreateEntity(signs[sign].template, GetWorldPosition() - Vector(0, 0, 50), GetWorldRotation());
}

@addMethod(W3PlayerWitcher)
function GMTestSignOwner() : W3SignOwner
{
	return signOwner;
}

@addMethod(W3SignEntity)
function GMTestSetOwner(o : W3SignOwner)
{
	owner = o;
}

function GMTestStam01FinisherAard()
{
	var witcher : W3PlayerWitcher;
	var entity : W3SignEntity;
	var stamina, focus : float;
	var cooldownOn, controlOn : bool;
	var hooks : int;

	witcher = GetWitcherPlayer();
	if(!witcher)
		return;
	entity = witcher.GMTestNewSignEntity(ST_Aard);
	GMTestReport(entity, "STAM-01 (A1-2) Aard entity created for the check");
	if(!entity)
		return;
	entity.GMTestSetOwner(witcher.GMTestSignOwner());
	focus = thePlayer.GetStat(BCS_Focus);
	thePlayer.RemoveBuff(EET_GMAardCooldown);
	thePlayer.GainStat(BCS_Stamina, thePlayer.GetStatMax(BCS_Stamina));
	stamina = thePlayer.GetStat(BCS_Stamina);

	thePlayer.GMTestDecoctionHook(true);
	entity.DisableStaminaCost(true);
	entity.ManagePlayerStamina();
	cooldownOn = thePlayer.HasBuff(EET_GMAardCooldown);
	hooks = thePlayer.gmTestDecoctionHooks;
	GMTestReport(!cooldownOn, "STAM-01 (A1-2) the Aard finisher's free Aard starts no Aard cooldown");
	GMTestReport(hooks == 0, "STAM-01 (A1-2) the Aard finisher's free Aard fires no sign-cast decoction hook (" + hooks + ")");
	GMTestReport(thePlayer.GetStat(BCS_Stamina) >= stamina, "STAM-01 (A1-2) the Aard finisher's free Aard costs no stamina");

	entity.DisableStaminaCost(false);
	entity.ManagePlayerStamina();
	controlOn = thePlayer.HasBuff(EET_GMAardCooldown);
	GMTestReport(controlOn && thePlayer.gmTestDecoctionHooks == hooks + 1, "STAM-01 (A1-2) control: a paid Aard starts the cooldown and the hook");

	entity.Destroy();
	thePlayer.RemoveBuff(EET_GMAardCooldown);
	thePlayer.GainStat(BCS_Stamina, thePlayer.GetStatMax(BCS_Stamina));
	thePlayer.ForceSetStat(BCS_Focus, focus);
}

// A real Aard finisher (5.x's man_finisher_aard_01_rp_remaster, normally drawn only with the new
// tree's Shock Wave): gmtest_stam01_fin_aard(true) forces that finisher animation; then
// gmtest_stam06_bandit(), ForceFinisher(true), gmtest_stam06_weaken(), autolock(),
// gmtest_stam06_fin_a() (the killing light attack), and some 4 s later gmtest_stam01_fin_check():
// the finisher cast its free Aard, with no Aard cooldown and no decoction hook.
@addField(CR4Player)
var gmTestForceAardFinisher : bool;

@addMethod(CR4Player)
function GMTestSetForceAardFinisher(on : bool)
{
	gmTestForceAardFinisher = on;
}

@wrapMethod(W3SyncAnimationManager)
function GetFinisherSynAnimName(optional nonLethalFinisher : bool) : name
{
	var n : name;

	n = wrappedMethod(nonLethalFinisher);
	if(thePlayer.gmTestForceAardFinisher)
	{
		LogChannel('GMTest', "INFO STAM-01 finisher " + NameToString(n) + " forced to man_finisher_aard_01_rp_remaster");
		return 'man_finisher_aard_01_rp_remaster';
	}
	return n;
}

exec function gmtest_stam01_fin_aard(on : bool)
{
	thePlayer.GMTestSetForceAardFinisher(on);
	thePlayer.RemoveBuff(EET_GMAardCooldown);
	thePlayer.GMTestDecoctionHook(true);
	thePlayer.GMTestSignArm(on);
	LogChannel('GMTest', "INFO STAM-01 Aard finisher forced " + on);
}

exec function gmtest_stam01_fin_check()
{
	LogChannel('GMTest', "INFO STAM-01 finisher check: casts " + thePlayer.gmTestSignCasts + " decoction hooks " + thePlayer.gmTestDecoctionHooks
		+ " Aard cooldown " + thePlayer.HasBuff(EET_GMAardCooldown));
	GMTestReport(thePlayer.gmTestSignCasts == 1, "STAM-01 (A1-2) the Aard finisher cast one Aard (" + thePlayer.gmTestSignCasts + ")");
	GMTestReport(!thePlayer.HasBuff(EET_GMAardCooldown), "STAM-01 (A1-2) no Aard cooldown after the Aard finisher");
	GMTestReport(thePlayer.gmTestDecoctionHooks == 0, "STAM-01 (A1-2) no sign-cast decoction hook from the Aard finisher (" + thePlayer.gmTestDecoctionHooks + ")");
	thePlayer.GMTestSetForceAardFinisher(false);
	thePlayer.GMTestSignArm(false);
}

// STAM-01: put all five sign cooldowns (7.5 s each) on the player, for a look at the HUD.
exec function gmtest_stam01_hud()
{
	GMAddSignCooldown(ST_Aard, true);
	GMAddSignCooldown(ST_Axii, true);
	GMAddSignCooldown(ST_Igni, true);
	GMAddSignCooldown(ST_Quen, true);
	GMAddSignCooldown(ST_Yrden, true);
	LogChannel('GMTest', "INFO STAM-01 all sign cooldowns applied for 7.5 s");
}

// OPT-01: Ghost Mode's options are registered, labelled, defaulted, and read by the features.
exec function gmtest_opt01()
{
	GMTest_opt01();
}

function GMTest_opt01()
{
	var cfg : CInGameConfigWrapper;
	var groups, options : array<name>;
	var i, idx : int;
	var display, previous : string;
	var buff : CBaseGameplayEffect;

	cfg = theGame.GetInGameConfigWrapper();
	idx = cfg.GetGroupIdx("GMGameplayOptions");
	GMTestReport(idx >= 0, "OPT-01 group GMGameplayOptions registered");
	if(idx < 0)
		return;
	GMTestReport(cfg.IsGroupVisible('GMGameplayOptions'), "OPT-01 group visible");
	GMTestReport(GetLocStringByKeyExt("panel_ghost_mode") == "Ghost Mode", "OPT-01 menu label '" + GetLocStringByKeyExt("panel_ghost_mode") + "'");

	GMOptionList(groups, options);
	for(i = 0; i < options.Size(); i += 1)
	{
		display = cfg.GetVarDisplayName(groups[i], options[i]);
		GMTestReport(display != "", "OPT-01 " + NameToString(options[i]) + " in menu, label '" + GetLocStringByKeyExt("option_" + display) + "'");
		GMTestReport(!GMOptionUnset(options[i], cfg.GetVarValue(groups[i], options[i])), "OPT-01 " + NameToString(options[i]) + " has a value: " + cfg.GetVarValue(groups[i], options[i]));
	}

	// Changing an option changes the feature (STAM-01 sign cooldown), and 0 turns it off.
	previous = cfg.GetVarValue('GMGameplayOptions', 'GMSignCooldown');
	cfg.SetVarValue('GMGameplayOptions', 'GMSignCooldown', "3");
	GMTestReport(theGame.params.GMGetSignCooldownDuration() == 3, "OPT-01 sign cooldown option read: " + FloatToString(theGame.params.GMGetSignCooldownDuration()));
	thePlayer.RemoveBuff(EET_GMAardCooldown);
	GMAddSignCooldown(ST_Aard, false);
	buff = thePlayer.GetBuff(EET_GMAardCooldown);
	GMTestReport(buff && buff.GetDurationLeft() > 2.5f && buff.GetDurationLeft() <= 3.0f, "OPT-01 cooldown follows the option (3 s)");
	thePlayer.RemoveBuff(EET_GMAardCooldown);
	cfg.SetVarValue('GMGameplayOptions', 'GMSignCooldown', "0");
	GMAddSignCooldown(ST_Aard, false);
	GMTestReport(!thePlayer.HasBuff(EET_GMAardCooldown), "OPT-01 option 0 turns the cooldown off");
	thePlayer.RemoveBuff(EET_GMAardCooldown);
	cfg.SetVarValue('GMGameplayOptions', 'GMSignCooldown', previous);
	GMTestReport(cfg.GetVarValue('GMGameplayOptions', 'GMSignCooldown') == previous, "OPT-01 option restored to " + previous);
}

// STAM-04: regen values. Run gmtest_stam04_a() then gmtest_stam04_b() (separate calls, so the
// regen effect updates in between). Out of combat only: combat and guarding need a fight.
@addMethod(W3AutoRegenEffect)
function GMTestGetEffectValue() : SAbilityAttributeValue
{
	return effectValue;
}

@addField(CR4Player)
var gmTestPreviousOption : string;

// STAM-04, situation-free: ConGeralt's regen values through the DLC.
function GMTest_stam04xml()
{
	var valMin, valMax : SAbilityAttributeValue;

	// XML: ConGeralt's staminaRegen through the DLC (on_conflict="extend" on a tag that occurs 3 times)
	theGame.GetDefinitionsManager().GetAbilityAttributeValue('ConGeralt', 'staminaRegen', valMin, valMax);
	LogChannel('GMTest', "INFO STAM-04 ConGeralt staminaRegen base=" + FloatToString(valMin.valueBase) + " add=" + FloatToString(valMin.valueAdditive) + " mult=" + FloatToString(valMin.valueMultiplicative));
	GMTestReport(valMin.valueMultiplicative == 0.15f, "STAM-04 staminaRegen mult 0.15");
	GMTestReport(valMin.valueBase == 1, "STAM-04 staminaRegen base kept (1)");
	theGame.GetDefinitionsManager().GetAbilityAttributeValue('ConGeralt', 'staminaRegenGuarded', valMin, valMax);
	GMTestReport(valMin.valueMultiplicative == 0.15f, "STAM-04 staminaRegenGuarded mult 0.15");
}

exec function gmtest_stam04_a()
{
	var cfg : CInGameConfigWrapper;

	GMTest_stam04xml();

	// Out-of-combat option: set it to -40 and drain stamina; _b checks the result.
	cfg = theGame.GetInGameConfigWrapper();
	thePlayer.GMTestSetPrevious(cfg.GetVarValue('GMGameplayOptions', 'GMOutOfCombatStaminaRegen'));
	cfg.SetVarValue('GMGameplayOptions', 'GMOutOfCombatStaminaRegen', "-40");
	thePlayer.DrainStamina(ESAT_FixedValue, thePlayer.GetStatMax(BCS_Stamina));
	LogChannel('GMTest', "INFO STAM-04 option set to -40, stamina drained to " + FloatToString(thePlayer.GetStat(BCS_Stamina)));
}

@addMethod(CR4Player)
function GMTestSetPrevious(value : string)
{
	gmTestPreviousOption = value;
}

exec function gmtest_stam04_b()
{
	var regen : W3AutoRegenEffect;
	var value, attribute : SAbilityAttributeValue;

	regen = (W3AutoRegenEffect)thePlayer.GetBuff(EET_AutoStaminaRegen);
	GMTestReport(regen, "STAM-04 regen effect present");
	GMTestReport(!thePlayer.IsInCombat(), "STAM-04 out of combat");
	if(regen)
	{
		value = regen.GMTestGetEffectValue();
		attribute = thePlayer.GetAttributeValue('staminaOutOfCombatRegen');
		LogChannel('GMTest', "INFO STAM-04 out-of-combat effect add=" + FloatToString(value.valueAdditive) + " mult=" + FloatToString(value.valueMultiplicative) + " (attribute add=" + FloatToString(attribute.valueAdditive) + ")");
		GMTestReport(value.valueAdditive == attribute.valueAdditive - 40, "STAM-04 out-of-combat option applied to the regen value");
	}
	LogChannel('GMTest', "INFO STAM-04 stamina now " + FloatToString(thePlayer.GetStat(BCS_Stamina)) + " / " + FloatToString(thePlayer.GetStatMax(BCS_Stamina)));
	theGame.GetInGameConfigWrapper().SetVarValue('GMGameplayOptions', 'GMOutOfCombatStaminaRegen', thePlayer.gmTestPreviousOption);
	LogChannel('GMTest', "INFO STAM-04 option restored to " + thePlayer.gmTestPreviousOption);
}

// STAM-04: regen rate in combat, measured. Needs a fight: load the test save, spawn enemies
// (spawn(wolf, 2, 6, true)), then run as separate calls, so time passes in between:
//   gmtest_stam04_c(guard, option)   guard: hold the guard; option: the combat regen option
//                                    (additive, per second) to set for the test. Drains stamina.
//   gmtest_stam04_d()                first sample (after the regen delay of the drain); checks
//                                    that the fight has started (it can take a second after spawning)
//   gmtest_stam04_e()                second sample; compares the rate with the expected one,
//                                    restores the option and the guard
// Expected rate = (staminaRegen add + option + staminaRegen mult * max stamina)
//                 * 0.5 when guarded * (1 + armor regen bonus).
// The guard is set by script (SetGuarded), not by holding the guard input; the regen code
// only reads IsGuarded(), so this covers it.
@addMethod(CBaseGameplayEffect)
function GMTestGetAttributeName() : name
{
	return attributeName;
}

@addField(CR4Player)
var gmTestSampleTime : float;

@addField(CR4Player)
var gmTestSampleStamina : float;

@addField(CR4Player)
var gmTestOption : float;

@addMethod(CR4Player)
function GMTestSetSample(t : float, stamina : float)
{
	gmTestSampleTime = t;
	gmTestSampleStamina = stamina;
}

@addMethod(CR4Player)
function GMTestSetOption(value : float)
{
	gmTestOption = value;
}

exec function gmtest_stam04_c(optional guard : bool, optional option : float)
{
	var cfg : CInGameConfigWrapper;

	GMTestReport(thePlayer.IsInCombat(), "STAM-04 in combat (spawn enemies first)");
	cfg = theGame.GetInGameConfigWrapper();
	thePlayer.GMTestSetPrevious(cfg.GetVarValue('GMGameplayOptions', 'GMCombatStaminaRegen'));
	thePlayer.GMTestSetOption(option);
	cfg.SetVarValue('GMGameplayOptions', 'GMCombatStaminaRegen', FloatToString(option));
	if(guard)
		thePlayer.SetGuarded(true);
	thePlayer.DrainStamina(ESAT_FixedValue, thePlayer.GetStatMax(BCS_Stamina));
	LogChannel('GMTest', "INFO STAM-04 guard=" + guard + " option=" + FloatToString(option)
		+ " stamina drained to " + FloatToString(thePlayer.GetStat(BCS_Stamina)));
}

exec function gmtest_stam04_d()
{
	thePlayer.GMTestSetSample(theGame.GetEngineTimeAsSeconds(), thePlayer.GetStat(BCS_Stamina));
	GMTestReport(thePlayer.IsInCombat(), "STAM-04 in combat at sample 1");
	LogChannel('GMTest', "INFO STAM-04 sample 1 stamina=" + FloatToString(thePlayer.gmTestSampleStamina));
}

exec function gmtest_stam04_e()
{
	var regen : W3AutoRegenEffect;
	var attr, value : SAbilityAttributeValue;
	var t, stamina, rate, expected, armorBonus, maxStamina : float;
	var guarded : bool;

	t = theGame.GetEngineTimeAsSeconds();
	stamina = thePlayer.GetStat(BCS_Stamina);
	maxStamina = thePlayer.GetStatMax(BCS_Stamina);
	guarded = thePlayer.IsGuarded();
	rate = (stamina - thePlayer.gmTestSampleStamina) / (t - thePlayer.gmTestSampleTime);

	attr = thePlayer.GetAttributeValue('staminaRegen');
	armorBonus = GetWitcherPlayer().CalculatedArmorStaminaRegenBonus();
	expected = (attr.valueAdditive + thePlayer.gmTestOption + attr.valueMultiplicative * maxStamina) * (1 + armorBonus);
	if(guarded)
		expected *= 0.5;

	regen = (W3AutoRegenEffect)thePlayer.GetBuff(EET_AutoStaminaRegen);
	if(regen)
	{
		value = regen.GMTestGetEffectValue();
		LogChannel('GMTest', "INFO STAM-04 effect attribute=" + NameToString(regen.GMTestGetAttributeName())
			+ " add=" + FloatToString(value.valueAdditive) + " mult=" + FloatToString(value.valueMultiplicative));
		GMTestReport(regen.GMTestGetAttributeName() == 'staminaRegen', "STAM-04 combat regen uses staminaRegen");
	}
	LogChannel('GMTest', "INFO STAM-04 stamina " + FloatToString(thePlayer.gmTestSampleStamina) + " -> " + FloatToString(stamina)
		+ " in " + FloatToString(t - thePlayer.gmTestSampleTime) + " s; staminaRegen add=" + FloatToString(attr.valueAdditive)
		+ " mult=" + FloatToString(attr.valueMultiplicative) + " armorBonus=" + FloatToString(armorBonus)
		+ " guarded=" + guarded + " combat=" + thePlayer.IsInCombat());
	LogChannel('GMTest', "INFO STAM-04 rate=" + FloatToString(rate) + "/s expected=" + FloatToString(expected) + "/s");
	GMTestReport(thePlayer.IsInCombat(), "STAM-04 still in combat");
	GMTestReport(stamina < maxStamina && thePlayer.gmTestSampleStamina > 0, "STAM-04 samples between empty and full");
	GMTestReport(AbsF(rate - expected) <= 0.1 * expected, "STAM-04 measured rate within 10% of expected");

	theGame.GetInGameConfigWrapper().SetVarValue('GMGameplayOptions', 'GMCombatStaminaRegen', thePlayer.gmTestPreviousOption);
	if(guarded)
		thePlayer.SetGuarded(false);
	LogChannel('GMTest', "INFO STAM-04 option restored to '" + thePlayer.gmTestPreviousOption + "'");
}

// STAM-01: casting through the real input handler (CPlayerInput.OnCastSign, called with a
// scripted key state). Run as separate calls:
//   gmtest_stam01_press(ST_Aard)          select the sign and press the cast input
//   gmtest_stam01_release()               release it
// For an alternate cast, use modAutomation's autocast(ST_Aard, true) and autocastrelease()
// instead of press and release (a script cannot hold the real key), with calls in between
// (e.g. autostatus()) for the hold time. Axii needs a hostile target in range.
//   gmtest_stam01_after(ST_Aard, alt)     the cooldown is on with the configured duration and
//                                         the cast was (alt) or was not an alternate cast;
//                                         with stamina full, a second press is refused
function GMTestCastInput(pressed : bool)
{
	var action : SInputAction;

	action.aName = 'CastSign';
	if(pressed)
	{
		action.value = 1;
		action.lastFrameValue = 0;
	}
	else
	{
		action.value = 0;
		action.lastFrameValue = 1;
	}
	thePlayer.GetInputHandler().OnCastSign(action);
}

exec function gmtest_stam01_press(sign : ESignType)
{
	GetWitcherPlayer().SetEquippedSign(sign);
	GMTestReport(!GMIsSignOnCooldown(sign), "STAM-01 " + sign + " not on cooldown before the cast");
	GMTestCastInput(true);
	GMTestReport(thePlayer.IsCastingSign(), "STAM-01 " + sign + " cast started");
}

exec function gmtest_stam01_release()
{
	GMTestCastInput(false);
	LogChannel('GMTest', "INFO STAM-01 cast input released");
}

exec function gmtest_stam01_after(sign : ESignType, alt : bool)
{
	var buff : CBaseGameplayEffect;
	var entity : W3SignEntity;
	var expected : float;

	buff = thePlayer.GetBuff(GMSignCooldownType(sign));
	GMTestReport(buff, "STAM-01 " + sign + " cooldown applied by the cast");
	entity = GetWitcherPlayer().GetSignEntity(sign);
	// Information only: channeled signs reset the flag when the channel ends. The cooldown
	// duration shows which kind of cast it was.
	if(entity)
		LogChannel('GMTest', "INFO STAM-01 " + sign + " sign entity alternate flag " + entity.IsAlternateCast());
	if(alt)
		expected = theGame.params.GMGetAltSignCooldownDuration();
	else
		expected = theGame.params.GMGetSignCooldownDuration();
	if(buff)
	{
		LogChannel('GMTest', "INFO STAM-01 " + sign + " cooldown duration " + FloatToString(buff.GetInitialDurationAfterResists())
			+ " left " + FloatToString(buff.GetDurationLeft()));
		GMTestReport(AbsF(buff.GetInitialDurationAfterResists() - expected) < 0.01, "STAM-01 " + sign + " cooldown duration = option " + FloatToString(expected));
	}

	// Second cast during the cooldown, with full stamina so only the cooldown can refuse it.
	thePlayer.GainStat(BCS_Stamina, thePlayer.GetStatMax(BCS_Stamina));
	GMTestCastInput(true);
	GMTestReport(!thePlayer.IsCastingSign(), "STAM-01 " + sign + " second cast refused during the cooldown");
	GMTestCastInput(false);
}

// STAM-05: armor regen modifier off by default, restored by the option. Equips
// "Heavy armor 01" (staminaRegen_armor_mod -10%) and checks the regen bonus and the item
// stats with the option off and on, then restores the option. For the effect on the regen
// rate, run gmtest_stam04_c/d/e in a fight with the option on and off.
function GMTestHasArmorRegenStat(itemStats : array<SAttributeTooltip>) : bool
{
	var i : int;

	for(i = 0; i < itemStats.Size(); i += 1)
	{
		if(itemStats[i].originName == 'staminaRegen_armor_mod')
			return true;
	}
	return false;
}

function GMTestStam05Check(enabled : bool, armor : SItemUniqueId)
{
	var stats : array<SAttributeTooltip>;
	var bonus : float;
	var attr : SAbilityAttributeValue;
	var label : string;

	if(enabled)
		label = "STAM-05 option on: ";
	else
		label = "STAM-05 option off: ";
	theGame.GetInGameConfigWrapper().SetVarValue('GMGameplayOptions', 'GMArmorRegenPenalty', enabled);
	bonus = GetWitcherPlayer().CalculatedArmorStaminaRegenBonus();
	attr = thePlayer.GetAttributeValue('staminaRegen_armor_mod');
	LogChannel('GMTest', "INFO " + label + "armor regen bonus " + FloatToString(bonus)
		+ " (staminaRegen_armor_mod mult " + FloatToString(attr.valueMultiplicative) + ")");
	if(enabled)
		GMTestReport(bonus < 0 && bonus == attr.valueMultiplicative, label + "heavy armor lowers regen (the item's value)");
	else
		GMTestReport(bonus == 0, label + "no armor regen bonus or penalty");

	// Tooltips list only the attributes in tooltip_settings.csv; vanilla has no row for
	// staminaRegen_armor_mod, Ghost Mode adds one (UI-07, whose tests check the line while on);
	// here only "absent while off" is checked.
	thePlayer.inv.GetItemStats(armor, stats);
	if(enabled)
		LogChannel('GMTest', "INFO " + label + "armor regen line in the item's tooltip stats: " + GMTestHasArmorRegenStat(stats));
	else
		GMTestReport(!GMTestHasArmorRegenStat(stats), label + "no armor regen line in the item's tooltip stats");
	stats.Clear();
	thePlayer.inv.GetItemStatsFromName('Heavy armor 01', stats);
	if(enabled)
		LogChannel('GMTest', "INFO " + label + "armor regen line in the stats by item name: " + GMTestHasArmorRegenStat(stats));
	else
		GMTestReport(!GMTestHasArmorRegenStat(stats), label + "no armor regen line in the stats by item name");
}

exec function gmtest_stam05()
{
	GMTest_stam05();
}

function GMTest_stam05()
{
	var ids : array<SItemUniqueId>;
	var previous : string;
	var old : SItemUniqueId;
	var hadOld : bool;

	hadOld = GetWitcherPlayer().GetItemEquippedOnSlot(EES_Armor, old);
	ids = thePlayer.inv.AddAnItem('Heavy armor 01', 1);
	while(ids.Size() > 0 && thePlayer.inv.GetItemLevel(ids[0]) > thePlayer.GetLevel())	// ITEM-02: a copy Geralt can wear
	{
		thePlayer.inv.RemoveItem(ids[0], 1);
		ids = thePlayer.inv.AddAnItem('Heavy armor 01', 1);
	}
	GMTestReport(ids.Size() > 0, "STAM-05 Heavy armor 01 added");
	if(ids.Size() == 0)
		return;
	thePlayer.EquipItem(ids[0]);
	GMTestReport(GetWitcherPlayer().IsItemEquipped(ids[0]), "STAM-05 Heavy armor 01 equipped");

	previous = theGame.GetInGameConfigWrapper().GetVarValue('GMGameplayOptions', 'GMArmorRegenPenalty');
	LogChannel('GMTest', "INFO STAM-05 option was '" + previous + "'");
	GMTestReport(!GMIsArmorRegenPenaltyEnabled(), "STAM-05 option off by default");
	GMTestStam05Check(false, ids[0]);
	GMTestStam05Check(true, ids[0]);
	theGame.GetInGameConfigWrapper().SetVarValue('GMGameplayOptions', 'GMArmorRegenPenalty', previous);
	// the chest worn before back on (ARM-02's class costs would change later checks)
	thePlayer.UnequipItem(ids[0]);
	thePlayer.inv.RemoveItem(ids[0], 1);
	if(hadOld)
		thePlayer.EquipItem(old);
}

// STAM-04, STAM-05: the character panel's stamina lines. Needs a menu open for its flash
// storage: run ingamemenu() first (autoresume() closes it). Sets the combat regen option to
// +5 and the armor regen penalty on for the check, then restores both. Equip an armor with a
// regen modifier (e.g. additem('Heavy armor 01', 1, true)) to see the armor line non-zero.
function GMTestPanelStaminaLines(label : string) : array<string>
{
	var menu : CR4Menu;
	var data, stat, line : CScriptedFlashObject;
	var stats, sub : CScriptedFlashArray;
	var i, j : int;
	var lines : array<string>;

	menu = theGame.GetGuiManager().GetRootMenu();
	if(!menu)
	{
		GMTestReport(false, label + "a menu is open (run ingamemenu() first)");
		return lines;
	}
	data = GetPlayerStatsGFxData(menu.GetMenuFlashValueStorage());
	stats = data.GetMemberFlashArray("stats");
	for(i = 0; i < stats.GetLength(); i += 1)
	{
		stat = stats.GetElementFlashObject(i);
		if(stat.GetMemberFlashString("tag") != "majorStat3")
			continue;
		sub = stat.GetMemberFlashArray("subStats");
		for(j = 0; j < sub.GetLength(); j += 1)
		{
			line = sub.GetElementFlashObject(j);
			lines.PushBack(line.GetMemberFlashString("tag") + "=" + line.GetMemberFlashString("value"));
			LogChannel('GMTest', "INFO " + label + "stamina line " + line.GetMemberFlashString("tag") + " '"
				+ line.GetMemberFlashString("name") + "' = '" + line.GetMemberFlashString("value") + "'");
		}
	}
	return lines;
}

function GMTestHasLine(lines : array<string>, prefix : string) : bool
{
	var i : int;

	for(i = 0; i < lines.Size(); i += 1)
		if(StrStartsWith(lines[i], prefix))
			return true;
	return false;
}

// The regression's second call (after gmtest_regress() and ingamemenu()): the character panel, and the
// regression checks that need time to pass after gmtest_regress() (ITEM-12's resistance gain, ALCH's later doses).
exec function gmtest_panel()
{
	GMTest_food_after();	// first: it ends the food effects, which raise the regen the panel shows
	GMTest_panel();
	GMTest_ui01_crit();
	GMTest_ui02();
	GMTest_ui03();
	GMTest_ui04();
	GMTest_ui05();
	GMTest_item12_after();
	GMTest_alchport_after();
	GMTest_ai06_after();
	GMTest_ai10_after();
	GMTest_ai11_after();
	GMTest_ai14_after();
	GMTest_ai15_after();
	GMTest_ai17_after();
	GMTest_ai19_after();
	GMTest_ai20_after();
	GMTest_xp04_who_after();	// XP-04 (XP audit F1): who earns a kill's experience: Geralt's kill, allies' and a guard's near him, an ally's far away
	GMTest_econ_e4_give();	// ECON-10 (slice E4): rewards given through GiveReward and the crowns gained (Emhyr's payment, the sq108 griffin, the loan, races, a fistfight, Hearts of Stone's purse, Contract: The White Lady after a haggled deal), put back; here, not in gmtest_regress()'s frame, where it made AI-18's stone check fail
	GMTest_wgt_after();	// WGT (tests/gmTestsWgt.ws)
	GMTest_opt_after();	// OPT (tests/gmTestsOpt.ws)
	GMTest_trph_after();	// TRPH (tests/gmTestsTrph.ws)
	GMTest_fix_after();	// FIX (tests/gmTestsFix.ws)
	GMTest_horse_after();	// HORSE (tests/gmTestsHorse.ws)
	GMTest_data_after();	// whole-port data checks (tests/gmTestsData.ws)
	GMTest_diff04_after();	// last: DIFF-04's mode and option changes on the bandit GMTest_diff04_spawn() left (a mode change rebuilds every NPC's stats)
}

function GMTest_panel()
{
	var cfg : CInGameConfigWrapper;
	var prevRegen, prevPenalty, perSecond : string;
	var lines : array<string>;
	var combat, outOfCombat : float;

	cfg = theGame.GetInGameConfigWrapper();
	prevRegen = cfg.GetVarValue('GMGameplayOptions', 'GMCombatStaminaRegen');
	prevPenalty = cfg.GetVarValue('GMGameplayOptions', 'GMArmorRegenPenalty');
	perSecond = "/" + GetLocStringByKeyExt("per_second");

	cfg.SetVarValue('GMGameplayOptions', 'GMCombatStaminaRegen', "5");
	cfg.SetVarValue('GMGameplayOptions', 'GMArmorRegenPenalty', "false");
	lines = GMTestPanelStaminaLines("panel, option off: ");
	combat = 15 + 5;
	outOfCombat = GMStaminaRegenPerSecond('staminaOutOfCombatRegen');
	GMTestReport(lines.Contains("defStat15=" + NoTrailZeros(RoundMath(combat)) + perSecond), "STAM-04 panel combat regen includes the option (" + NoTrailZeros(combat) + ")");
	GMTestReport(lines.Contains("defStat14=" + NoTrailZeros(RoundMath(outOfCombat)) + perSecond), "STAM-04 panel out-of-combat regen (" + NoTrailZeros(outOfCombat) + ")");
	GMTestReport(lines.Size() > 0 && GMTestPanelLine(GMTestPanelSection("mainResStat"), "defStat16") == "", "STAM-05 panel: no armor line while the option is off");

	cfg.SetVarValue('GMGameplayOptions', 'GMArmorRegenPenalty', "true");
	lines = GMTestPanelStaminaLines("panel, option on: ");
	combat = (15 + 5) * (1 + GetWitcherPlayer().CalculatedArmorStaminaRegenBonus());
	GMTestReport(lines.Contains("defStat15=" + NoTrailZeros(RoundMath(combat)) + perSecond), "STAM-05 panel combat regen includes the armor modifier (" + NoTrailZeros(combat) + ")");
	GMTestReport(GMTestPanelValue(GMTestPanelSection("mainResStat"), "defStat16") == NoTrailZeros(RoundMath(GetWitcherPlayer().CalculatedArmorStaminaRegenBonus() * 100)) + " %" && !GMTestHasLine(lines, "defStat16="), "STAM-05 panel armor line shows the modifier, under Armor (UI-05, DU3)");
	GMTestReport(lines.Contains("defStat18=6.66") && lines.Contains("defStat19=10") && lines.Contains("defStat27=40"), "STAM-03 panel cost lines (light 6.66, heavy 10, Aard 40; RoundTo truncates, as in legacy)");
	GMTestReport(lines.Contains("defStat24=10" + perSecond), "STAM-03 panel sprint cost per second");
	// STAM-09: present only with the skill equipped (skilleq(S_Sword_s35), skilleq(S_Sword_s02)).
	GMTestReport(lines.Contains("defStat32=" + NoTrailZeros(RoundTo(GetWitcherPlayer().GMGetWhirlStaminaCost(1), 2)) + perSecond) == (GetWitcherPlayer().CanUseSkill(S_Sword_s01) || GetWitcherPlayer().CanUseSkill(S_Sword_s35)),
		"STAM-09 panel Whirl line (" + NoTrailZeros(GetWitcherPlayer().GMGetWhirlStaminaCost(1)) + perSecond + ") shown exactly when Whirl is equipped (" + (GetWitcherPlayer().CanUseSkill(S_Sword_s01) || GetWitcherPlayer().CanUseSkill(S_Sword_s35)) + ")");
	GMTestReport(lines.Contains("defStat33=50" + perSecond) == GetWitcherPlayer().CanUseSkill(S_Sword_s02),
		"STAM-09 panel Rend line (50" + perSecond + ") shown exactly when Rend is equipped (" + GetWitcherPlayer().CanUseSkill(S_Sword_s02) + ")");

	cfg.SetVarValue('GMGameplayOptions', 'GMCombatStaminaRegen', prevRegen);
	cfg.SetVarValue('GMGameplayOptions', 'GMArmorRegenPenalty', prevPenalty);
}

// STAM-02: Whirl and Rend cooldown effects register, last as long as configured, show on the
// HUD, and the option 0 turns them off. Works without attacking.
exec function gmtest_stam02()
{
	GMTest_stam02();
}

function GMTest_stam02()
{
	var effects : array<EEffectType>;
	var i : int;
	var buff : CBaseGameplayEffect;
	var label, previous : string;
	var expected : float;

	effects.PushBack(EET_GMWhirlCooldown);
	effects.PushBack(EET_GMRendCooldown);
	expected = theGame.params.GMGetMeleeSpecialCooldownDuration();
	LogChannel('GMTest', "INFO STAM-02 melee special cooldown option " + FloatToString(expected));
	for(i = 0; i < effects.Size(); i += 1)
	{
		thePlayer.RemoveBuff(effects[i]);
		GMAddMeleeSpecialCooldown(effects[i]);
		buff = thePlayer.GetBuff(effects[i]);
		GMTestReport(buff, "STAM-02 " + EffectTypeToName(effects[i]) + " applied");
		if(!buff)
			continue;
		GMTestReport(AbsF(buff.GetInitialDurationAfterResists() - expected) < 0.01, "STAM-02 " + EffectTypeToName(effects[i]) + " duration " + FloatToString(buff.GetInitialDurationAfterResists()));
		GMTestReport(buff.ShowOnHUD(), "STAM-02 " + EffectTypeToName(effects[i]) + " shown on HUD");
		GMTestReport(StrFindFirst(buff.GetIcon(), "icons/Skills/Sword/sword_s") == 0, "STAM-02 " + EffectTypeToName(effects[i]) + " icon " + buff.GetIcon());
		label = GetLocStringByKeyExt(buff.GetEffectNameLocalisationKey());
		GMTestReport(StrFindFirst(label, "cooldown") > 0, "STAM-02 " + EffectTypeToName(effects[i]) + " label '" + label + "'");
		GMTestReport(!thePlayer.IsImmuneToBuff(effects[i]), "STAM-02 " + EffectTypeToName(effects[i]) + " not blocked by immunities");
		thePlayer.RemoveBuff(effects[i]);
	}

	previous = theGame.GetInGameConfigWrapper().GetVarValue('GMGameplayOptions', 'GMMeleeSpecialCooldown');
	theGame.GetInGameConfigWrapper().SetVarValue('GMGameplayOptions', 'GMMeleeSpecialCooldown', "0");
	GMAddMeleeSpecialCooldown(EET_GMWhirlCooldown);
	GMTestReport(!thePlayer.HasBuff(EET_GMWhirlCooldown), "STAM-02 option 0 turns the cooldowns off");
	theGame.GetInGameConfigWrapper().SetVarValue('GMGameplayOptions', 'GMMeleeSpecialCooldown', previous);
}

// STAM-02: Whirl (heavy = false) and Rend (heavy = true) through the input handler. Needs the
// skills (skilleq(S_Sword_s01), skilleq(S_Sword_s02)), a drawn sword in combat (spawn an
// enemy) and god() against interruptions. Separate calls, with time in between:
//   gmtest_stam02_press(heavy)     press the special attack input
//   gmtest_stam02_release(heavy)   release it: the attack ends
//   gmtest_stam02_after(heavy)     the cooldown is on with the configured duration; presses again
//   gmtest_stam02_refused(heavy)   the second press started no attack; releases
function GMTestSpecialAttackInput(heavy : bool, pressed : bool)
{
	var action : SInputAction;

	if(pressed)
	{
		action.value = 1;
		action.lastFrameValue = 0;
	}
	else
	{
		action.value = 0;
		action.lastFrameValue = 1;
	}
	if(heavy)
	{
		action.aName = 'SpecialAttackHeavy';
		thePlayer.GetInputHandler().OnCbtSpecialAttackHeavy(action);
	}
	else
	{
		action.aName = 'SpecialAttackLight';
		thePlayer.GetInputHandler().OnCbtSpecialAttackLight(action);
	}
}

function GMTestSpecialAttackName(heavy : bool) : string
{
	if(heavy)
		return "Rend";
	return "Whirl";
}

function GMTestSpecialAttackCooldown(heavy : bool) : EEffectType
{
	if(heavy)
		return EET_GMRendCooldown;
	return EET_GMWhirlCooldown;
}

function GMTestLogSpecialAttackState(label : string)
{
	LogChannel('GMTest', "INFO STAM-02 " + label + ": isPerformingSpecialAttack=" + thePlayer.GetBehaviorVariable('isPerformingSpecialAttack')
		+ " combatActionType=" + thePlayer.GetBehaviorVariable('combatActionType')
		+ " playerAttackType=" + thePlayer.GetBehaviorVariable('playerAttackType')
		+ " state=" + thePlayer.GetCurrentStateName()
		+ " stamina=" + FloatToString(thePlayer.GetStat(BCS_Stamina)));
}

exec function gmtest_stam02_press(heavy : bool)
{
	GMTestReport(!thePlayer.HasBuff(GMTestSpecialAttackCooldown(heavy)), "STAM-02 " + GMTestSpecialAttackName(heavy) + " not on cooldown before the attack");
	GMTestSpecialAttackInput(heavy, true);
	GMTestLogSpecialAttackState(GMTestSpecialAttackName(heavy) + " pressed");
}

exec function gmtest_stam02_release(heavy : bool)
{
	GMTestLogSpecialAttackState(GMTestSpecialAttackName(heavy) + " before release");
	GMTestReport(thePlayer.GetBehaviorVariable('isPerformingSpecialAttack') != 0, "STAM-02 " + GMTestSpecialAttackName(heavy) + " attack running while held");
	GMTestSpecialAttackInput(heavy, false);
}

exec function gmtest_stam02_after(heavy : bool)
{
	var buff : CBaseGameplayEffect;
	var attackName : string;

	attackName = GMTestSpecialAttackName(heavy);
	GMTestLogSpecialAttackState(attackName + " after release");
	buff = thePlayer.GetBuff(GMTestSpecialAttackCooldown(heavy));
	GMTestReport(buff, "STAM-02 " + attackName + " cooldown applied by the attack");
	if(buff)
	{
		LogChannel('GMTest', "INFO STAM-02 " + attackName + " cooldown duration " + FloatToString(buff.GetInitialDurationAfterResists()) + " left " + FloatToString(buff.GetDurationLeft()));
		GMTestReport(AbsF(buff.GetInitialDurationAfterResists() - theGame.params.GMGetMeleeSpecialCooldownDuration()) < 0.01, "STAM-02 " + attackName + " cooldown duration = option");
	}
	GMTestReport(!thePlayer.HasBuff(GMTestSpecialAttackCooldown(!heavy)), "STAM-02 " + attackName + " does not put " + GMTestSpecialAttackName(!heavy) + " on cooldown");
	thePlayer.GainStat(BCS_Stamina, thePlayer.GetStatMax(BCS_Stamina));
	GMTestSpecialAttackInput(heavy, true);
}

exec function gmtest_stam02_refused(heavy : bool)
{
	GMTestLogSpecialAttackState(GMTestSpecialAttackName(heavy) + " second press");
	GMTestReport(thePlayer.GetBehaviorVariable('isPerformingSpecialAttack') == 0, "STAM-02 " + GMTestSpecialAttackName(heavy) + " second attack refused during the cooldown");
	GMTestSpecialAttackInput(heavy, false);
}

// STAM-03: stamina costs. Checks each action's cost (XML base cost through 5.x's cost code and
// the options), the sign cost 40, an option multiplier, the cap at 100, the heavy-parry
// multiplier and an actual drain. Works without fighting.
function GMTestStam03Cost(action : EStaminaActionType, expected : float, label : string)
{
	var cost : float;

	cost = thePlayer.GetStaminaActionCost(action, '', 0);
	GMTestReport(AbsF(cost - expected) < 0.01, "STAM-03 " + label + " cost " + FloatToString(cost) + " (expected " + FloatToString(expected) + ")");
}

exec function gmtest_stam03()
{
	GMTest_stam03();
}

function GMTest_stam03()
{
	var cfg : CInGameConfigWrapper;
	var prevMelee, prevAgility, prevSign : string;
	var before, after : float;

	cfg = theGame.GetInGameConfigWrapper();
	prevMelee = cfg.GetVarValue('GMGameplayOptions', 'GMMeleeStaminaCostMultiplier');
	prevAgility = cfg.GetVarValue('GMGameplayOptions', 'GMAgilityStaminaCostMultiplier');
	prevSign = cfg.GetVarValue('GMGameplayOptions', 'GMSignStaminaCostMultiplier');
	LogChannel('GMTest', "INFO STAM-03 options melee '" + prevMelee + "' agility '" + prevAgility + "' sign '" + prevSign + "'");
	cfg.SetVarValue('GMGameplayOptions', 'GMMeleeStaminaCostMultiplier', "0");
	cfg.SetVarValue('GMGameplayOptions', 'GMAgilityStaminaCostMultiplier', "0");
	cfg.SetVarValue('GMGameplayOptions', 'GMSignStaminaCostMultiplier', "0");

	GMTestStam03Cost(ESAT_LightAttack, 6.666, "light attack");
	GMTestStam03Cost(ESAT_HeavyAttack, 10, "heavy attack");
	GMTestStam03Cost(ESAT_Parry, 5, "parry");
	GMTestStam03Cost(ESAT_Counterattack, 6.666, "counter");
	GMTestStam03Cost(ESAT_Dodge, 5, "dodge");
	GMTestStam03Cost(ESAT_Roll, 10, "roll");
	GMTestStam03Cost(ESAT_Jump, 10, "jump");
	GMTestStam03Cost(ESAT_UsableItem, 5, "usable item");
	GMTestReport(AbsF(thePlayer.GetStaminaActionCost(ESAT_Sprint, '', 1) - 10) < 0.01, "STAM-03 sprint cost per second " + FloatToString(thePlayer.GetStaminaActionCost(ESAT_Sprint, '', 1)));
	GMTestReport(AbsF(thePlayer.GetStaminaActionCost(ESAT_Ability, 'magic_1', 0) - 40) < 0.01, "STAM-03 Aard cast cost " + FloatToString(thePlayer.GetStaminaActionCost(ESAT_Ability, 'magic_1', 0)));
	GMTestReport(AbsF(((W3PlayerAbilityManager)thePlayer.abilityManager).GetSkillStaminaUseCost(S_Magic_5) - 40) < 0.01, "STAM-03 Axii skill cost (cast check) " + FloatToString(((W3PlayerAbilityManager)thePlayer.abilityManager).GetSkillStaminaUseCost(S_Magic_5)));
	GMTestReport(theGame.params.HEAVY_STRIKE_COST_MULTIPLIER == 1.25, "STAM-03 heavy strike parry multiplier " + FloatToString(theGame.params.HEAVY_STRIKE_COST_MULTIPLIER));
	GMTestReport(AbsF(thePlayer.GetStaminaActionCost(ESAT_Ability, 'magic_s1', 0) - 40) < 0.01, "STAM-03 Aard sweep cost " + FloatToString(thePlayer.GetStaminaActionCost(ESAT_Ability, 'magic_s1', 0)));
	GMTestReport(AbsF(thePlayer.GetStaminaActionCost(ESAT_Ability, 'magic_s2', 1) - 30) < 0.01, "STAM-03 Igni stream cost per second " + FloatToString(thePlayer.GetStaminaActionCost(ESAT_Ability, 'magic_s2', 1)));
	GMTestReport(AbsF(thePlayer.GetStaminaActionCost(ESAT_Ability, 'magic_s3', 1) - 26.8) < 0.01, "STAM-03 Yrden trap cost per second " + FloatToString(thePlayer.GetStaminaActionCost(ESAT_Ability, 'magic_s3', 1)));
	GMTestReport(AbsF(thePlayer.GetStaminaActionCost(ESAT_Ability, 'magic_s4', 1) - 20) < 0.01, "STAM-03 active Quen cost per second " + FloatToString(thePlayer.GetStaminaActionCost(ESAT_Ability, 'magic_s4', 1)));
	GMTestReport(AbsF(thePlayer.GetStaminaActionCost(ESAT_Ability, 'magic_s28', 1) - 30) < 0.01, "STAM-03 Firestream (new tree) cost per second " + FloatToString(thePlayer.GetStaminaActionCost(ESAT_Ability, 'magic_s28', 1)));
	GMTestReport(AbsF(thePlayer.GetStaminaActionCost(ESAT_Ability, 'magic_s31', 1) - 16) < 0.01, "STAM-03 Puppet (new tree) cost per second " + FloatToString(thePlayer.GetStaminaActionCost(ESAT_Ability, 'magic_s31', 1)));
	GMTestReport(AbsF(thePlayer.GetStaminaActionCost(ESAT_Ability, 'magic_s5', 1) - 16) < 0.01, "STAM-03 Axii puppet cost per second " + FloatToString(thePlayer.GetStaminaActionCost(ESAT_Ability, 'magic_s5', 1)));

	cfg.SetVarValue('GMGameplayOptions', 'GMMeleeStaminaCostMultiplier', "1");
	GMTestStam03Cost(ESAT_LightAttack, 13.332, "light attack with melee option +1");
	GMTestStam03Cost(ESAT_Jump, 10, "jump unaffected by the melee option");
	cfg.SetVarValue('GMGameplayOptions', 'GMAgilityStaminaCostMultiplier', "0.5");
	GMTestStam03Cost(ESAT_Jump, 15, "jump with agility option +0.5");
	cfg.SetVarValue('GMGameplayOptions', 'GMSignStaminaCostMultiplier', "3");
	GMTestReport(AbsF(thePlayer.GetStaminaActionCost(ESAT_Ability, 'magic_2', 0) - 100) < 0.01, "STAM-03 Igni cost with sign option +3 capped at 100: " + FloatToString(thePlayer.GetStaminaActionCost(ESAT_Ability, 'magic_2', 0)));
	cfg.SetVarValue('GMGameplayOptions', 'GMMeleeStaminaCostMultiplier', "0");
	cfg.SetVarValue('GMGameplayOptions', 'GMAgilityStaminaCostMultiplier', "0");
	cfg.SetVarValue('GMGameplayOptions', 'GMSignStaminaCostMultiplier', "0");

	thePlayer.GainStat(BCS_Stamina, thePlayer.GetStatMax(BCS_Stamina));
	before = thePlayer.GetStat(BCS_Stamina);
	thePlayer.DrainStamina(ESAT_HeavyAttack);
	after = thePlayer.GetStat(BCS_Stamina);
	GMTestReport(AbsF(before - after - 10) < 0.01, "STAM-03 heavy attack drains " + FloatToString(before - after));

	cfg.SetVarValue('GMGameplayOptions', 'GMMeleeStaminaCostMultiplier', prevMelee);
	cfg.SetVarValue('GMGameplayOptions', 'GMAgilityStaminaCostMultiplier', prevAgility);
	cfg.SetVarValue('GMGameplayOptions', 'GMSignStaminaCostMultiplier', prevSign);

	GMTestStam03RefusalSounds();
}

// C2-5: the refusal sounds as legacy: a bomb, crossbow or item press without stamina plays the
// low-stamina warning (gui_ingame_low_stamina_warning), a dodge on foot gui_no_stamina.
function GMTestStam03RefusalSounds()
{
	var action : SInputAction;
	var refused : bool;

	thePlayer.DrainStamina(ESAT_FixedValue, thePlayer.GetStatMax(BCS_Stamina), 0.001);
	action.aName = 'ThrowItem';
	action.value = 1;
	action.lastFrameValue = 0;
	refused = GMRefuseItemForStamina(action);
	GMTestReport(refused && thePlayer.gmStaminaRefusalSound == "gui_ingame_low_stamina_warning", "STAM-03 (C2-5) an item press without stamina plays the low-stamina warning ('" + thePlayer.gmStaminaRefusalSound + "')");
	GetWitcherPlayer().EvadePressed(EBAT_Dodge);
	GMTestReport(thePlayer.gmStaminaRefusalSound == "gui_no_stamina", "STAM-03 (C2-5) a dodge without stamina plays gui_no_stamina ('" + thePlayer.gmStaminaRefusalSound + "')");
	thePlayer.GainStat(BCS_Stamina, thePlayer.GetStatMax(BCS_Stamina));
}

// STAM-03 slice B: parries in a fight. Counts the player's parry checks through a wrapper.
// Load the test save, level up, spawn wolves near Geralt, then (separate calls, with time
// in between for the wolves to attack):
//   gmtest_stam03_parry_a(empty)   guard; empty: drain stamina and keep it at 0
//   gmtest_stam03_parry_b(empty)   report parries, partial parries, stamina; stop guarding
@addField(CR4Player)
var gmTestParries : int;
@addField(CR4Player)
var gmTestPartialParries : int;
@addField(CR4Player)
var gmTestParryStaggers : int;
@addField(CR4Player)
var gmTestVitality : float;

@addMethod(CR4Player)
function GMTestParryCount(full : int, partial : int, staggers : int)
{
	gmTestParries += full;
	gmTestPartialParries += partial;
	gmTestParryStaggers += staggers;
}

@addMethod(CR4Player)
function GMTestParryReset()
{
	gmTestProbesOn = true;
	gmTestParries = 0;
	gmTestPartialParries = 0;
	gmTestParryStaggers = 0;
	gmTestVitality = GetStat(BCS_Vitality);
}

@wrapMethod(W3PlayerWitcher)
function PerformParryCheck(parryInfo : SParryInfo) : bool
{
	var ret : bool;

	ret = wrappedMethod(parryInfo);
	if(ret && GMTestProbes())
	{
		if(GMIsParryingWithNotEnoughStamina())
			GMTestParryCount(0, 1, 0);
		else
			GMTestParryCount(1, 0, 0);
		LogChannel('GMTest', "INFO STAM-03 parry " + parryInfo.attackActionName + " partial=" + GMIsParryingWithNotEnoughStamina()
			+ " stamina=" + FloatToString(GetStat(BCS_Stamina)) + " mult=" + FloatToString(GMParryCostMult(parryInfo.attacker, parryInfo.attackActionName)));
	}
	return ret;
}

@wrapMethod(W3DamageManagerProcessor)
function ProcessAction(act : W3DamageAction)
{
	var attack : W3Action_Attack;

	wrappedMethod(act);
	if(!GMTestProbes())
		return;
	if(act.victim == thePlayer && act.IsParryStagger() && thePlayer.HasBuff(EET_Stagger))	// the effect, not just the flag
		thePlayer.GMTestParryCount(0, 0, 1);
	attack = (W3Action_Attack)act;
	if(act.victim == thePlayer && attack && attack.IsActionMelee())
		LogChannel('GMTest', "INFO STAM-03 hit on player: parried=" + attack.IsParried() + " parryStagger=" + act.IsParryStagger() + " staggered=" + thePlayer.HasBuff(EET_Stagger)
			+ " damage=" + FloatToString(act.GetDamageDealt()));
}

exec function gmtest_stam03_parry_a(optional empty : bool)
{
	thePlayer.GMTestParryReset();
	thePlayer.SetGuarded(true);
	if(empty)
		thePlayer.DrainStamina(ESAT_FixedValue, thePlayer.GetStatMax(BCS_Stamina), 60);
	else
		thePlayer.GainStat(BCS_Stamina, thePlayer.GetStatMax(BCS_Stamina));
	LogChannel('GMTest', "INFO STAM-03 guarding, stamina " + FloatToString(thePlayer.GetStat(BCS_Stamina)) + ", combat " + thePlayer.IsInCombat());
}

exec function gmtest_stam03_parry_b(optional empty : bool)
{
	LogChannel('GMTest', "INFO STAM-03 parries " + thePlayer.gmTestParries + ", partial " + thePlayer.gmTestPartialParries
		+ ", parry staggers " + thePlayer.gmTestParryStaggers + ", stamina " + FloatToString(thePlayer.GetStat(BCS_Stamina))
		+ ", vitality " + FloatToString(thePlayer.gmTestVitality) + " -> " + FloatToString(thePlayer.GetStat(BCS_Vitality)));
	if(empty)
	{
		GMTestReport(thePlayer.gmTestPartialParries > 0, "STAM-03 without stamina, attacks are parried partially");
		GMTestReport(thePlayer.gmTestParries == 0, "STAM-03 without stamina, no full parries");
		GMTestReport(thePlayer.gmTestParryStaggers > 0, "STAM-03 partial parries stagger");
	}
	else
	{
		GMTestReport(thePlayer.gmTestParries > 0, "STAM-03 with stamina, attacks are parried fully");
		GMTestReport(thePlayer.gmTestParryStaggers == 0, "STAM-03 full parries do not stagger");
	}
	thePlayer.SetGuarded(false);
	thePlayer.ResumeStaminaRegen(StaminaActionTypeToName(ESAT_FixedValue));
}

// STAM-03 refusals and charge timing. Logs every stamina drain of the player (action, cost,
// time), so a test can see when an attack is paid. Separate calls:
//   gmtest_stam03_act_a(action, empty)   action: 0 light attack, 1 heavy attack, 2 dodge, 3 roll;
//                                        empty: drain stamina to 0 first (refusal test). Presses
//                                        and releases the input (a long hold is not a heavy attack).
//   gmtest_stam03_act_b(action, empty)   reports drains since _a and refusals
@addField(CR4Player)
var gmTestDrainLog : array<string>;
@addField(CR4Player)
var gmTestActStart : float;
@addField(CR4Player)
var gmTestRefusalsBefore : int;
@addField(CR4Player)
var gmTestPaid : array<EStaminaActionType>;	// actions charged with a cost > 0 since the reset

@addField(CR4Player)
var gmTestLastDrainAt : float;		// time of the last paid drain since gmTestActStart
@addField(CR4Player)
var gmTestLastDrainLeft : float;	// stamina left after it

@addMethod(CR4Player)
function GMTestLogDrain(logLine : string, action : EStaminaActionType, cost : float)
{
	gmTestDrainLog.PushBack(logLine);
	if(cost > 0)
	{
		gmTestPaid.PushBack(action);
		gmTestLastDrainAt = theGame.GetEngineTimeAsSeconds() - gmTestActStart;
		gmTestLastDrainLeft = GetStat(BCS_Stamina);
	}
}

@addField(CR4Player)
var gmTestChanDrained : float;
@addField(CR4Player)
var gmTestChanDrains : int;
@addField(CR4Player)
var gmTestChanFirst : float;
@addField(CR4Player)
var gmTestChanLast : float;

@addMethod(CR4Player)
function GMTestSumChannelDrain(cost : float)
{
	if(gmTestChanDrains == 0)
		gmTestChanFirst = theGame.GetEngineTimeAsSeconds() - gmTestActStart;
	gmTestChanLast = theGame.GetEngineTimeAsSeconds() - gmTestActStart;
	gmTestChanDrains += 1;
	gmTestChanDrained += cost;
}

@addMethod(CR4Player)
function GMTestActReset()
{
	gmTestProbesOn = true;
	gmTestChanDrained = 0;
	gmTestChanDrains = 0;
	gmTestChanFirst = 0;
	gmTestChanLast = 0;
	gmTestDrainLog.Clear();
	gmTestPaid.Clear();
	gmTestActStart = theGame.GetEngineTimeAsSeconds();
	gmTestRefusalsBefore = gmStaminaRefusals;
}

@wrapMethod(W3AbilityManager)
function DrainStamina(action : EStaminaActionType, optional fixedCost : float, optional fixedDelay : float, optional abilityName : name, optional dt : float, optional costMult : float) : float
{
	var cost : float;

	cost = wrappedMethod(action, fixedCost, fixedDelay, abilityName, dt, costMult);
	if(!GMTestProbes())
		return cost;
	if(owner != thePlayer && action == ESAT_FixedValue && fixedCost == 0 && fixedDelay > 0)
		thePlayer.GMTestLogNpcPause(owner.GetDisplayName() + " paused " + NoTrailZeros(fixedDelay) + " s");
	if(owner != thePlayer && cost > 0)
		thePlayer.GMTestLogNpcPause(owner.GetDisplayName() + " paid " + NoTrailZeros(cost) + " (" + action + ", delay " + NoTrailZeros(fixedDelay) + ") at +"
			+ NoTrailZeros(theGame.GetEngineTimeAsSeconds() - thePlayer.gmTestActStart) + ", stamina left " + NoTrailZeros(owner.GetStat(BCS_Stamina)));
	if(owner == thePlayer && action == ESAT_Ability && dt > 0)
		thePlayer.GMTestSumChannelDrain(cost);		// per frame: summed, not logged
	else if(owner == thePlayer && action != ESAT_FixedValue)
		thePlayer.GMTestLogDrain(action + " " + NoTrailZeros(cost) + " at +" + NoTrailZeros(theGame.GetEngineTimeAsSeconds() - thePlayer.gmTestActStart), action, cost);
	return cost;
}

function GMTestActInput(act : int, pressed : bool)
{
	var a : SInputAction;

	if(pressed)
	{
		a.value = 1;
		a.lastFrameValue = 0;
	}
	else
	{
		a.value = 0;
		a.lastFrameValue = 1;
	}
	switch(act)
	{
		case 0: a.aName = 'AttackLight'; thePlayer.GetInputHandler().OnCbtAttackLight(a); break;
		// The sword heavy attack checks the real key's activation time (OnCbtAttackHeavy), so the
		// test enters at the next step, SetupCombatAction, where the stamina refusal sits.
		case 1: if(pressed) thePlayer.SetupCombatAction(EBAT_HeavyAttack, BS_Released); break;
		case 2: a.aName = 'Dodge'; thePlayer.GetInputHandler().OnCbtDodge(a); break;
		case 3: a.aName = 'CbtRoll'; thePlayer.GetInputHandler().OnCbtRoll(a); break;
	}
}

function GMTestActStaminaAction(act : int) : EStaminaActionType
{
	switch(act)
	{
		case 0: return ESAT_LightAttack;
		case 1: return ESAT_HeavyAttack;
		case 2: return ESAT_Dodge;
		case 3: return ESAT_Roll;
	}
	return ESAT_Undefined;
}

// Logs the attack names that reach DoAttack (where attacks are charged).
@wrapMethod(CR4Player)
function DoAttack(animData : CPreAttackEventData, weaponId : SItemUniqueId, parried : bool, countered : bool, parriedBy : array<CActor>, attackAnimationName : name, hitTime : float)
{
	if(this == thePlayer && GMTestProbes())
		GMTestLogDrain("DoAttack " + animData.attackName + " (" + attackAnimationName + ") at +" + NoTrailZeros(theGame.GetEngineTimeAsSeconds() - gmTestActStart), ESAT_Undefined, 0);
	wrappedMethod(animData, weaponId, parried, countered, parriedBy, attackAnimationName, hitTime);
}

function GMTestActName(act : int) : string
{
	switch(act)
	{
		case 0: return "light attack";
		case 1: return "heavy attack";
		case 2: return "dodge";
		case 3: return "roll";
	}
	return "?";
}

exec function gmtest_stam03_act_a(act : int, optional empty : bool)
{
	if(empty)
		thePlayer.DrainStamina(ESAT_FixedValue, thePlayer.GetStatMax(BCS_Stamina), 30);
	else
		thePlayer.GainStat(BCS_Stamina, thePlayer.GetStatMax(BCS_Stamina));
	thePlayer.GMTestActReset();
	GMTestActInput(act, true);
	GMTestActInput(act, false);
	LogChannel('GMTest', "INFO STAM-03 " + GMTestActName(act) + " pressed, stamina " + FloatToString(thePlayer.GetStat(BCS_Stamina))
		+ ", drains at press: " + thePlayer.gmTestDrainLog.Size() + ", state " + thePlayer.GetCurrentStateName());
}

exec function gmtest_stam03_act_b(act : int, optional empty : bool)
{
	var i : int;
	var actLabel : string;

	for(i = 0; i < thePlayer.gmTestDrainLog.Size(); i += 1)
		LogChannel('GMTest', "INFO STAM-03 drain " + thePlayer.gmTestDrainLog[i]);
	actLabel = GMTestActName(act);
	if(empty)
	{
		GMTestReport(thePlayer.gmStaminaRefusals > thePlayer.gmTestRefusalsBefore, "STAM-03 " + actLabel + " refused without stamina");
	}
	else
	{
		GMTestReport(thePlayer.gmStaminaRefusals == thePlayer.gmTestRefusalsBefore, "STAM-03 " + actLabel + " not refused with stamina");
		GMTestReport(thePlayer.gmTestPaid.Contains(GMTestActStaminaAction(act)), "STAM-03 " + actLabel + " paid stamina");
	}
	thePlayer.ResumeStaminaRegen(StaminaActionTypeToName(ESAT_FixedValue));
}

// STAM-03 bombs: selects a Samum bomb (added by the test) and presses/releases the bomb input
// through the input handler. Run gmtest_stam03_bomb_a(empty), wait, gmtest_stam03_bomb_release(),
// wait, gmtest_stam03_bomb_b(empty) (a throw is press, aim, release).
// The drain log of gmtest_stam03_act_* is reused.
exec function gmtest_stam03_bomb_a(optional empty : bool)
{
	var ids : array<SItemUniqueId>;
	var a : SInputAction;

	ids = thePlayer.inv.AddAnItem('Samum 1', 3);
	GetWitcherPlayer().EquipItemInGivenSlot(ids[0], EES_Petard1, false);
	GetWitcherPlayer().SelectQuickslotItem(EES_Petard1);
	if(empty)
		thePlayer.DrainStamina(ESAT_FixedValue, thePlayer.GetStatMax(BCS_Stamina), 30);
	else
		thePlayer.GainStat(BCS_Stamina, thePlayer.GetStatMax(BCS_Stamina));
	thePlayer.GMTestActReset();
	a.aName = 'ThrowItem';
	a.value = 1;
	a.lastFrameValue = 0;
	if(empty)
		thePlayer.GetInputHandler().OnCbtThrowItem(a);		// the refusal sits in the input event
	else
		thePlayer.SetupCombatAction(EBAT_ItemUse, BS_Pressed);	// the event depends on real key state
	LogChannel('GMTest', "INFO STAM-03 bomb input pressed, selected bomb " + thePlayer.inv.IsItemBomb(thePlayer.GetSelectedItemId())
		+ ", ammo " + thePlayer.inv.SingletonItemGetAmmo(ids[0]) + ", stamina " + FloatToString(thePlayer.GetStat(BCS_Stamina)));
}

exec function gmtest_stam03_bomb_release()
{
	var a : SInputAction;

	a.aName = 'ThrowItem';
	a.value = 0;
	a.lastFrameValue = 1;
	thePlayer.SetupCombatAction(EBAT_ItemUse, BS_Released);
	LogChannel('GMTest', "INFO STAM-03 bomb released");
}

exec function gmtest_stam03_bomb_b(optional empty : bool)
{
	var i : int;

	for(i = 0; i < thePlayer.gmTestDrainLog.Size(); i += 1)
		LogChannel('GMTest', "INFO STAM-03 drain " + thePlayer.gmTestDrainLog[i]);
	if(empty)
		GMTestReport(thePlayer.gmStaminaRefusals > thePlayer.gmTestRefusalsBefore, "STAM-03 bomb refused without stamina");
	else
		GMTestReport(thePlayer.gmTestPaid.Contains(ESAT_UsableItem), "STAM-03 bomb paid stamina when thrown");
	thePlayer.ResumeStaminaRegen(StaminaActionTypeToName(ESAT_FixedValue));
}

// STAM-03 horseback: mounts Roach and drives the horse combat manager's own input events.
//   gmtest_stam03_mount()                 mounts Roach (must be near), logs the state
//   gmtest_stam03_horse_a(act, empty)     act 0: sword attack (press; the first press with the
//                                         sword sheathed only draws it), 1: crossbow press,
//                                         2: crossbow release, 3: bomb press (refusal only: the
//                                         bomb event checks the real key); empty: drain stamina
//                                         to 0 first
//   gmtest_stam03_horse_b(act, empty)     reports drains since _a and refusals
// The combat manager's OnAttack/OnItemAction exist only in its states; these empty events
// let a script call them (the current state's event runs).
@addMethod(W3VehicleCombatManager)
event OnAttack(action : SInputAction) {}

@addMethod(W3VehicleCombatManager)
event OnItemAction(action : SInputAction) {}

@addMethod(W3VehicleCombatManager)
function GMTestStateName() : name
{
	return GetCurrentStateName();
}

function GMTestHorseCombatManager() : W3VehicleCombatManager
{
	var horseComp : W3HorseComponent;

	horseComp = thePlayer.GetUsedHorseComponent();
	if(!horseComp)
		return NULL;
	return horseComp.GetUserCombatManager();
}

function GMTestLogHorse(label : string)
{
	var mgr : W3VehicleCombatManager;
	var mgrState : name;

	mgr = GMTestHorseCombatManager();
	if(mgr)
		mgrState = mgr.GMTestStateName();
	LogChannel('GMTest', "INFO STAM-03 " + label + ": on horse " + thePlayer.IsUsingHorse() + ", combat manager " + (bool)mgr
		+ " in " + mgrState + ", sword ready " + thePlayer.GetWeaponHolster().IsMeleeWeaponReady()
		+ ", stamina " + FloatToString(thePlayer.GetStat(BCS_Stamina)) + ", player state " + thePlayer.GetCurrentStateName());
}

// Adds the item if missing, equips it into the slot and selects it.
function GMTestSelectItem(itemName : name, slot : EEquipmentSlots)
{
	var ids : array<SItemUniqueId>;

	ids = thePlayer.inv.GetItemsByName(itemName);
	if(ids.Size() == 0)
		ids = thePlayer.inv.AddAnItem(itemName, 3);
	GetWitcherPlayer().EquipItemInGivenSlot(ids[0], slot, false);
	GetWitcherPlayer().SelectQuickslotItem(slot);
	LogChannel('GMTest', "INFO STAM-03 selected " + thePlayer.inv.GetItemName(thePlayer.GetSelectedItemId()));
}

exec function gmtest_stam03_mount()
{
	var horse : CNewNPC;

	horse = thePlayer.GetHorseWithInventory();
	if(!horse)
	{
		LogChannel('GMTest', "FAIL STAM-03 no horse found");
		return;
	}
	LogChannel('GMTest', "INFO STAM-03 horse at " + NoTrailZeros(VecDistance(horse.GetWorldPosition(), thePlayer.GetWorldPosition())) + " m");
	horse.GetHorseComponent().Mount(thePlayer, VMT_ImmediateUse, EVS_driver_slot);
	GMTestLogHorse("mount requested");
}

exec function gmtest_stam03_horse_a(act : int, optional empty : bool)
{
	var mgr : W3VehicleCombatManager;
	var a : SInputAction;

	mgr = GMTestHorseCombatManager();
	if(!mgr)
	{
		LogChannel('GMTest', "FAIL STAM-03 not on a horse");
		return;
	}
	if(act == 1 || act == 2)
	{
		GMTestSelectItem('Crossbow 1', EES_RangedWeapon);
	}
	else if(act == 3)
	{
		GMTestSelectItem('Samum 1', EES_Petard1);
	}
	if(empty)
		thePlayer.DrainStamina(ESAT_FixedValue, thePlayer.GetStatMax(BCS_Stamina), 30);
	else if(act != 2)
		thePlayer.GainStat(BCS_Stamina, thePlayer.GetStatMax(BCS_Stamina));
	if(act != 2)
		thePlayer.GMTestActReset();
	if(act == 2)
	{
		a.value = 0;
		a.lastFrameValue = 1;
	}
	else
	{
		a.value = 1;
		a.lastFrameValue = 0;
	}
	if(act == 0)
	{
		a.aName = 'VehicleAttack';
		mgr.OnAttack(a);
	}
	else
	{
		a.aName = 'VehicleItemAction';
		mgr.OnItemAction(a);
	}
	GMTestLogHorse("horse input " + act + " sent");
}

exec function gmtest_stam03_horse_b(act : int, optional empty : bool)
{
	var i : int;
	var actLabel : string;

	for(i = 0; i < thePlayer.gmTestDrainLog.Size(); i += 1)
		LogChannel('GMTest', "INFO STAM-03 drain " + thePlayer.gmTestDrainLog[i]);
	if(act == 0)
		actLabel = "horseback attack";
	else if(act == 3)
		actLabel = "horseback bomb";
	else
		actLabel = "horseback crossbow";
	if(empty)
	{
		GMTestReport(thePlayer.gmStaminaRefusals > thePlayer.gmTestRefusalsBefore, "STAM-03 " + actLabel + " refused without stamina");
		GMTestReport(thePlayer.gmStaminaRefusalSound == "gui_ingame_low_stamina_warning", "STAM-03 (C2-5) " + actLabel + " refusal sound '" + thePlayer.gmStaminaRefusalSound + "'");
	}
	else
	{
		GMTestReport(thePlayer.gmStaminaRefusals == thePlayer.gmTestRefusalsBefore, "STAM-03 " + actLabel + " not refused with stamina");
		if(act == 0)
			GMTestReport(thePlayer.gmTestPaid.Contains(ESAT_LightAttack), "STAM-03 " + actLabel + " paid stamina");
		else
			GMTestReport(thePlayer.gmTestPaid.Contains(ESAT_UsableItem), "STAM-03 " + actLabel + " paid stamina when fired");
	}
	GMTestLogHorse("after");
	thePlayer.ResumeStaminaRegen(StaminaActionTypeToName(ESAT_FixedValue));
}

// STAM-03 channeled signs: measures a held cast. Run autocast(<sign>, true) (modAutomation)
// right after gmtest_stam03_chan_a, then gmtest_stam03_chan_b() while it runs and after
// autocastrelease().
//   gmtest_stam03_chan_a(stamina)   sets stamina (regen paused 30 s) and resets the drain log
//   gmtest_stam03_chan_b()          logs one-time drains, the per-frame channel drains (sum,
//                                   count, first and last time), stamina and the sign's state
exec function gmtest_stam03_chan_a(stamina : float)
{
	thePlayer.DrainStamina(ESAT_FixedValue, thePlayer.GetStatMax(BCS_Stamina), 30);
	thePlayer.GainStat(BCS_Stamina, stamina);
	thePlayer.GMTestActReset();
	LogChannel('GMTest', "INFO STAM-03 channel test: stamina " + NoTrailZeros(thePlayer.GetStat(BCS_Stamina)));
}

exec function gmtest_stam03_chan_b()
{
	var i : int;
	var sign : ESignType;
	var entity : W3SignEntity;
	var entityState : name;

	for(i = 0; i < thePlayer.gmTestDrainLog.Size(); i += 1)
		LogChannel('GMTest', "INFO STAM-03 drain " + thePlayer.gmTestDrainLog[i]);
	sign = GetWitcherPlayer().GetEquippedSign();
	entity = GetWitcherPlayer().GetSignEntity(sign);
	if(entity)
		entityState = entity.GetCurrentStateName();
	LogChannel('GMTest', "INFO STAM-03 channel " + sign + ": drained " + NoTrailZeros(thePlayer.gmTestChanDrained)
		+ " in " + thePlayer.gmTestChanDrains + " frames, +" + NoTrailZeros(thePlayer.gmTestChanFirst) + " to +" + NoTrailZeros(thePlayer.gmTestChanLast)
		+ " s; now +" + NoTrailZeros(theGame.GetEngineTimeAsSeconds() - thePlayer.gmTestActStart) + " s, stamina " + NoTrailZeros(thePlayer.GetStat(BCS_Stamina))
		+ ", focus " + NoTrailZeros(thePlayer.GetStat(BCS_Focus)) + ", casting " + thePlayer.IsCastingSign() + ", sign state " + entityState);
}

// STAM-03: empties Geralt's stamina in the middle of a held channel (regen paused 30 s) and logs
// whether the sign is still channelling: the alternate Yrden and Axii keep going (channelStamina.ws).
exec function gmtest_stam03_chan_empty()
{
	var entity : W3SignEntity;
	var entityState : name;

	thePlayer.DrainStamina(ESAT_FixedValue, thePlayer.GetStatMax(BCS_Stamina), 30);
	entity = GetWitcherPlayer().GetSignEntity(GetWitcherPlayer().GetEquippedSign());
	if(entity)
		entityState = entity.GetCurrentStateName();
	LogChannel('GMTest', "INFO STAM-03 stamina emptied mid-channel: stamina " + NoTrailZeros(thePlayer.GetStat(BCS_Stamina))
		+ ", casting " + thePlayer.IsCastingSign() + ", sign state " + entityState);
}

// Test probe: what an Axii cast applies when it ends (targets, alternate or not, their effects; the
// Beguilement and Usurpation stacks on Geralt then, for ENCH-14's gmtest_ench14_count).
@addField(CR4Player)
public var gmTestAxiiEnd : string;

@addMethod(CR4Player)
function GMTestSetAxiiEnd(s : string)
{
	gmTestAxiiEnd = s;
}

@wrapMethod(W3AxiiEntity)
function OnEnded(optional isEnd : bool)
{
	var i : int;
	var confused : bool;

	wrappedMethod(isEnd);
	for(i = 0; i < targets.Size(); i += 1)
		confused = confused || targets[i].HasBuff(EET_Confusion) || targets[i].HasBuff(EET_AxiiGuardMe);
	thePlayer.GMTestSetAxiiEnd("confused " + confused + ", Beguilement stacks " + thePlayer.GetAbilityCount('Glyphword 14 abl') + ", Usurpation stacks " + thePlayer.GetAbilityCount('Glyphword 10 abl'));
	if(GMTestProbes())
	{
		LogChannel('GMTest', "INFO Axii OnEnded: alternate " + IsAlternateCast() + ", skill " + skillEnum + ", targets " + targets.Size()
			+ ", effect " + actionBuffs[0].effectType + " (" + actionBuffs.Size() + " buffs)");
		for(i = 0; i < targets.Size(); i += 1)
			LogChannel('GMTest', "INFO Axii OnEnded target " + targets[i].GetDisplayName() + ": puppet " + targets[i].HasBuff(EET_AxiiGuardMe)
				+ ", confusion " + targets[i].HasBuff(EET_Confusion) + ", immune to puppet " + targets[i].IsImmuneToBuff(EET_AxiiGuardMe));
	}
}

@wrapMethod(W3AxiiEntity)
function OnSignAborted(optional force : bool)
{
	if(GMTestProbes())
		LogChannel('GMTest', "INFO Axii aborted (force " + force + ")");
	wrappedMethod(force);
}

// Logs the Axii effects and attitude of every living NPC within 10 m (after an Axii cast).
exec function gmtest_axii_targets()
{
	var actors : array<CActor>;
	var i : int;

	actors = thePlayer.GetNPCsAndPlayersInRange(10, 20, , FLAG_OnlyAliveActors);
	for(i = 0; i < actors.Size(); i += 1)
		if(actors[i] != thePlayer)
			LogChannel('GMTest', "INFO Axii target " + actors[i].GetDisplayName() + ": puppet (AxiiGuardMe) " + actors[i].HasBuff(EET_AxiiGuardMe)
				+ ", confusion " + actors[i].HasBuff(EET_Confusion) + ", attitude " + GetAttitudeBetween(thePlayer, actors[i]));
}

// STAM-06: regen pause after actions. gmtest_stam06() checks every delay through the cost
// function (and the delay option); gmtest_stam06_a/s/b measure a pause in a fight:
//   gmtest_stam06_a(act)   sets stamina to 50 without a pause, then drains the action:
//                          0 dodge, 1 light attack, 2 Aard, 3 Aard sweep, 4 fixed value (no pause),
//                          5 nothing (cast a sign for real right after, e.g. autocast(ST_Aard))
//   gmtest_stam06_s()      takes a sample (call it several times, about 0.5 s apart)
//   gmtest_stam06_b(expected)  estimates how long after the last paid drain regen restarted
function GMTestStam06Delay(action : EStaminaActionType, abilityName : name, expected : float, label : string)
{
	var cost, delay : float;

	thePlayer.abilityManager.GetStaminaActionCost(action, cost, delay, 0, 0, abilityName, 0);
	GMTestReport(AbsF(delay - expected) < 0.01, "STAM-06 " + label + " delay " + NoTrailZeros(delay) + " (expected " + NoTrailZeros(expected) + ")");
}

exec function gmtest_stam06()
{
	GMTest_stam06();
}

function GMTest_stam06()
{
	var cfg : CInGameConfigWrapper;
	var prev : string;

	cfg = theGame.GetInGameConfigWrapper();
	prev = cfg.GetVarValue('GMGameplayOptions', 'GMStaminaDelay');
	LogChannel('GMTest', "INFO STAM-06 option '" + prev + "'");
	cfg.SetVarValue('GMGameplayOptions', 'GMStaminaDelay', "0");
	GMTestStam06Delay(ESAT_LightAttack, '', 1, "light attack");
	GMTestStam06Delay(ESAT_HeavyAttack, '', 1, "heavy attack");
	GMTestStam06Delay(ESAT_Parry, '', 1, "parry");
	GMTestStam06Delay(ESAT_Counterattack, '', 1, "counter");
	GMTestStam06Delay(ESAT_Dodge, '', 1, "dodge");
	GMTestStam06Delay(ESAT_Evade, '', 1, "evade");
	GMTestStam06Delay(ESAT_Roll, '', 1, "roll");
	GMTestStam06Delay(ESAT_Sprint, '', 1, "sprint");
	GMTestStam06Delay(ESAT_Jump, '', 1, "jump");
	GMTestStam06Delay(ESAT_UsableItem, '', 1, "usable item");
	GMTestStam06Delay(ESAT_Swimming, '', 0.5, "swimming (vanilla)");
	GMTestStam06Delay(ESAT_Ability, 'magic_1', 1, "Aard");
	GMTestStam06Delay(ESAT_Ability, 'magic_2', 1, "Igni");
	GMTestStam06Delay(ESAT_Ability, 'magic_3', 1, "Yrden");
	GMTestStam06Delay(ESAT_Ability, 'magic_4', 1, "Quen");
	GMTestStam06Delay(ESAT_Ability, 'magic_5', 1, "Axii");
	GMTestStam06Delay(ESAT_Ability, 'magic_s1', 1, "Aard sweep");
	GMTestStam06Delay(ESAT_Ability, 'magic_s2', 1, "Igni stream");
	GMTestStam06Delay(ESAT_Ability, 'magic_s3', 1, "Yrden trap");
	GMTestStam06Delay(ESAT_Ability, 'magic_s4', 1, "active Quen");
	GMTestStam06Delay(ESAT_Ability, 'magic_s5', 1, "Axii puppet");
	GMTestStam06Delay(ESAT_Ability, 'magic_s28', 1, "Firestream (new tree)");
	GMTestStam06Delay(ESAT_Ability, 'magic_s31', 1, "Puppet (new tree)");
	GMTestStam06Delay(ESAT_Ability, 'sword_s1', 1, "Whirl (classic tree)");
	GMTestStam06Delay(ESAT_Ability, 'sword_s35', 1, "Whirl (new tree)");
	GMTestStam06Delay(ESAT_Ability, 'sword_s2', 1, "Rend");
	cfg.SetVarValue('GMGameplayOptions', 'GMStaminaDelay', "0.5");
	GMTestStam06Delay(ESAT_Dodge, '', 1.5, "dodge with option +0.5");
	GMTestStam06Delay(ESAT_Ability, 'magic_2', 1.5, "Igni with option +0.5");
	cfg.SetVarValue('GMGameplayOptions', 'GMStaminaDelay', "-1");
	GMTestStam06Delay(ESAT_Dodge, '', 0, "dodge with option -1");
	cfg.SetVarValue('GMGameplayOptions', 'GMStaminaDelay', prev);
	LogChannel('GMTest', "INFO STAM-06 option restored to '" + prev + "'");
}

@addField(CR4Player)
var gmTest06Times : array<float>;
@addField(CR4Player)
var gmTest06Stamina : array<float>;

@addMethod(CR4Player)
function GMTest06Sample(reset : bool)
{
	if(reset)
	{
		gmTest06Times.Clear();
		gmTest06Stamina.Clear();
		gmTestActStart = theGame.GetEngineTimeAsSeconds();
	}
	gmTest06Times.PushBack(theGame.GetEngineTimeAsSeconds() - gmTestActStart);
	gmTest06Stamina.PushBack(GetStat(BCS_Stamina));
}

exec function gmtest_stam06_a(act : int)
{
	GMTestReport(thePlayer.IsInCombat(), "STAM-06 in combat (spawn enemies first)");
	thePlayer.DrainStamina(ESAT_FixedValue, thePlayer.GetStatMax(BCS_Stamina), 0.001);
	thePlayer.GainStat(BCS_Stamina, 50);
	thePlayer.GMTest06Sample(true);
	thePlayer.GMTestSetLastDrain(-1, 0);
	switch(act)
	{
		case 0: thePlayer.DrainStamina(ESAT_Dodge); break;
		case 1: thePlayer.DrainStamina(ESAT_LightAttack); break;
		case 2: thePlayer.DrainStamina(ESAT_Ability, 0, 0, 'magic_1'); break;
		case 3: thePlayer.DrainStamina(ESAT_Ability, 0, 0, 'magic_s1'); break;
		case 4: thePlayer.DrainStamina(ESAT_FixedValue, 5, 0.001); thePlayer.GMTestSetLastDrain(0, thePlayer.GetStat(BCS_Stamina)); break;
	}
	LogChannel('GMTest', "INFO STAM-06 action " + act + " drained, stamina " + NoTrailZeros(thePlayer.GetStat(BCS_Stamina)));
}

@addMethod(CR4Player)
function GMTestSetLastDrain(t : float, left : float)
{
	gmTestLastDrainAt = t;
	gmTestLastDrainLeft = left;
}

@addField(CR4Player)
var gmTestNpcPauses : array<string>;

@addMethod(CR4Player)
function GMTestLogNpcPause(logLine : string)
{
	gmTestNpcPauses.PushBack(logLine);
}

@addMethod(CR4Player)
function GMTestClearNpcPausesOnly()
{
	gmTestNpcPauses.Clear();
	gmTestDrainLog.Clear();
}

@addMethod(CR4Player)
function GMTestClearNpcPauses()
{
	gmTestProbesOn = true;
	gmTestNpcPauses.Clear();
}

// STAM-06 damage pause on Geralt: sets stamina to 50 without a pause, then hits him for pct %
// of his max health (as the vanilla hitme), and logs the hit's severity. Sample with
// gmtest_stam06_s() and finish with gmtest_stam06_b(severity / 4).
exec function gmtest_stam06_hit(pct : float)
{
	var action : W3DamageAction;
	var severity : int;

	thePlayer.DrainStamina(ESAT_FixedValue, thePlayer.GetStatMax(BCS_Stamina), 0.001);
	thePlayer.GainStat(BCS_Stamina, 50);
	thePlayer.GMTest06Sample(true);
	action = new W3DamageAction in theGame.damageMgr;
	action.Initialize(NULL, thePlayer, NULL, 'console', EHRT_Light, CPS_Undefined, false, false, false, false);
	action.AddDamage(theGame.params.DAMAGE_NAME_DIRECT, thePlayer.GetStatMax(BCS_Vitality) * pct / 100);
	action.SetSuppressHitSounds(true);
	action.SetHitAnimationPlayType(EAHA_ForceNo);
	theGame.damageMgr.ProcessAction(action);
	severity = GMGetHitSeverity(action);
	thePlayer.GMTestSetLastDrain(theGame.GetEngineTimeAsSeconds() - thePlayer.gmTestActStart, thePlayer.GetStat(BCS_Stamina));
	LogChannel('GMTest', "INFO STAM-06 hit for " + NoTrailZeros(action.processedDmg.vitalityDamage) + " of " + NoTrailZeros(thePlayer.GetStatMax(BCS_Vitality))
		+ " health: severity " + severity + ", expected pause " + NoTrailZeros(severity / 4.0) + " s; in combat " + thePlayer.IsInCombat());
	delete action;
}

// STAM-06 damage pause on NPCs: run gmtest_stam06_npc_a(), hit an enemy (e.g. a light attack
// with gmtest_stam03_act_a(0)), then gmtest_stam06_npc_b() lists the NPC pauses since.
exec function gmtest_stam06_npc_a()
{
	thePlayer.GMTestClearNpcPauses();
}

exec function gmtest_stam06_npc_b()
{
	var i : int;

	for(i = 0; i < thePlayer.gmTestNpcPauses.Size(); i += 1)
		LogChannel('GMTest', "INFO STAM-06 NPC " + thePlayer.gmTestNpcPauses[i]);
	GMTestReport(thePlayer.gmTestNpcPauses.Size() > 0, "STAM-06 a hit NPC paused its stamina regen");
}

exec function gmtest_stam06_s()
{
	thePlayer.GMTest06Sample(false);
}

exec function gmtest_stam06_b(expected : float)
{
	var i, n : int;
	var rate, restart : float;

	n = thePlayer.gmTest06Times.Size();
	for(i = 0; i < n; i += 1)
		LogChannel('GMTest', "INFO STAM-06 +" + NoTrailZeros(thePlayer.gmTest06Times[i]) + " s stamina " + NoTrailZeros(thePlayer.gmTest06Stamina[i]));
	if(n < 3)
	{
		LogChannel('GMTest', "FAIL STAM-06 too few samples");
		return;
	}
	if(thePlayer.gmTestLastDrainAt < 0)
	{
		LogChannel('GMTest', "FAIL STAM-06 no paid drain since gmtest_stam06_a");
		return;
	}
	if(thePlayer.gmTest06Stamina[n-1] >= thePlayer.GetStatMax(BCS_Stamina) - 0.01)
	{
		// Out of combat the bar refills at once: regen restarted between the last sample at
		// the drained level and the first one above it.
		for(i = 1; i < n; i += 1)
			if(thePlayer.gmTest06Stamina[i] > thePlayer.gmTestLastDrainLeft + 0.01)
				break;
		restart = (thePlayer.gmTest06Times[i-1] + thePlayer.gmTest06Times[i]) / 2;
		LogChannel('GMTest', "INFO STAM-06 drain at +" + NoTrailZeros(thePlayer.gmTestLastDrainAt) + " s left " + NoTrailZeros(thePlayer.gmTestLastDrainLeft)
			+ "; regen restarted between +" + NoTrailZeros(thePlayer.gmTest06Times[i-1]) + " and +" + NoTrailZeros(thePlayer.gmTest06Times[i]) + " s: pause about " + NoTrailZeros(restart - thePlayer.gmTestLastDrainAt) + " s");
		GMTestReport(AbsF(restart - thePlayer.gmTestLastDrainAt - expected) <= 0.25, "STAM-06 regen restarted " + NoTrailZeros(expected) + " s after the drain (within 0.25 s)");
		return;
	}
	// The rate from the last two samples (regen running); regen restarted where that line
	// meets the stamina left after the last paid drain.
	rate = (thePlayer.gmTest06Stamina[n-1] - thePlayer.gmTest06Stamina[n-2]) / (thePlayer.gmTest06Times[n-1] - thePlayer.gmTest06Times[n-2]);
	restart = thePlayer.gmTest06Times[n-1] - (thePlayer.gmTest06Stamina[n-1] - thePlayer.gmTestLastDrainLeft) / rate;
	LogChannel('GMTest', "INFO STAM-06 drain at +" + NoTrailZeros(thePlayer.gmTestLastDrainAt) + " s left " + NoTrailZeros(thePlayer.gmTestLastDrainLeft)
		+ "; regen " + NoTrailZeros(rate) + "/s, restarted at +" + NoTrailZeros(restart) + " s: pause " + NoTrailZeros(restart - thePlayer.gmTestLastDrainAt) + " s");
	GMTestReport(thePlayer.gmTest06Stamina[n-1] < thePlayer.GetStatMax(BCS_Stamina), "STAM-06 not full at the last sample");
	GMTestReport(AbsF(restart - thePlayer.gmTestLastDrainAt - expected) <= 0.25, "STAM-06 regen restarted " + NoTrailZeros(expected) + " s after the drain (within 0.25 s)");
}

// STAM-06 finishers and Rend. Spawn a human (finishers need one), force finishers with the vanilla
// ForceFinisher(true), then:
//   gmtest_stam06_bandit()       spawns a hostile bandit 2 m ahead, with 1 health left
//   gmtest_stam06_fin_a()        sets stamina to 50 without a pause and presses a light attack
//   gmtest_stam06_s()            samples (several times)
//   gmtest_stam06_fin_b()        logs the samples, drains and finisher start and end
// For Rend: gmtest_stam06_rend_a() (stamina 100 without a pause, press), samples, then
// gmtest_stam02_release(true), samples, gmtest_stam06_b(1) measures from the last Rend drain.
@addField(CR4Player)
var gmTestFinisherStart : float;
@addField(CR4Player)
var gmTestFinisherEnd : float;

@addMethod(CR4Player)
function GMTestSetFinisher(start : bool, t : float)
{
	if(start)
		gmTestFinisherStart = t;
	else
		gmTestFinisherEnd = t;
}

@wrapMethod(CR4Player)
function OnFinisherStart()
{
	if(GMTestProbes())
		GMTestSetFinisher(true, theGame.GetEngineTimeAsSeconds() - gmTestActStart);
	return wrappedMethod();
}

@wrapMethod(CR4Player)
function OnFinisherEnd()
{
	if(GMTestProbes())
		GMTestSetFinisher(false, theGame.GetEngineTimeAsSeconds() - gmTestActStart);
	return wrappedMethod();
}

exec function gmtest_stam06_bandit()
{
	var template : CEntityTemplate;
	var ent : CEntity;
	var pos : Vector;
	var npc : CNewNPC;

	template = (CEntityTemplate)LoadResource("dlc\dlc7\data\characters\sq107_bandit_lvl1_mortal.w2ent", true);
	if(!template)
	{
		LogChannel('GMTest', "FAIL STAM-06 bandit template not found");
		return;
	}
	pos = thePlayer.GetWorldPosition() + thePlayer.GetHeadingVector() * 2;
	ent = theGame.CreateEntity(template, pos, thePlayer.GetWorldRotation());
	npc = (CNewNPC)ent;
	npc.SetTemporaryAttitudeGroup('hostile_to_player', AGP_Default);
	LogChannel('GMTest', "INFO STAM-06 bandit spawned: human " + npc.IsHuman() + ", woman " + npc.IsWoman() + ", health " + NoTrailZeros(npc.GetHealth()));
}

exec function gmtest_stam06_weaken()
{
	var actors : array<CActor>;
	var i : int;

	actors = thePlayer.GetNPCsAndPlayersInRange(10, 20, , FLAG_OnlyAliveActors);
	for(i = 0; i < actors.Size(); i += 1)
		if(actors[i] != thePlayer && actors[i].IsHuman() && GetAttitudeBetween(thePlayer, actors[i]) == AIA_Hostile)
		{
			actors[i].ForceSetStat(BCS_Vitality, 1);
			actors[i].TeleportWithRotation(thePlayer.GetWorldPosition() + thePlayer.GetHeadingVector() * 1.5, VecToRotation(-thePlayer.GetHeadingVector()));
			actors[i].AddEffectDefault(EET_Confusion, thePlayer, "gmtest");	// does not defend; finishers still allowed
			LogChannel('GMTest', "INFO STAM-06 " + actors[i].GetDisplayName() + " weakened to 1 health at " + NoTrailZeros(VecDistance(actors[i].GetWorldPosition(), thePlayer.GetWorldPosition())) + " m");
		}
}

exec function gmtest_stam06_fin_a()
{
	thePlayer.DrainStamina(ESAT_FixedValue, thePlayer.GetStatMax(BCS_Stamina), 0.001);
	thePlayer.GainStat(BCS_Stamina, 50);
	thePlayer.GMTest06Sample(true);
	thePlayer.GMTestActReset();
	thePlayer.GMTestSetFinisher(true, -1);
	thePlayer.GMTestSetFinisher(false, -1);
	GMTestActInput(0, true);
	GMTestActInput(0, false);
}

exec function gmtest_stam06_fin_b()
{
	var i : int;

	for(i = 0; i < thePlayer.gmTestDrainLog.Size(); i += 1)
		LogChannel('GMTest', "INFO STAM-06 drain " + thePlayer.gmTestDrainLog[i]);
	for(i = 0; i < thePlayer.gmTest06Times.Size(); i += 1)
		LogChannel('GMTest', "INFO STAM-06 +" + NoTrailZeros(thePlayer.gmTest06Times[i]) + " s stamina " + NoTrailZeros(thePlayer.gmTest06Stamina[i]));
	LogChannel('GMTest', "INFO STAM-06 finisher start +" + NoTrailZeros(thePlayer.gmTestFinisherStart) + " s, end +" + NoTrailZeros(thePlayer.gmTestFinisherEnd) + " s");
	GMTestReport(thePlayer.gmTestFinisherStart >= 0, "STAM-06 a finisher happened");
}

// Whirl: gmtest_stam06_whirl_a() (stamina 100 without a pause, press), samples, then
// gmtest_stam02_release(false), samples; read the restart off the samples.
exec function gmtest_stam06_whirl_a()
{
	thePlayer.DrainStamina(ESAT_FixedValue, thePlayer.GetStatMax(BCS_Stamina), 0.001);
	thePlayer.GainStat(BCS_Stamina, 100);
	thePlayer.GMTest06Sample(true);
	thePlayer.GMTestActReset();
	GMTestSpecialAttackInput(false, true);
}

exec function gmtest_stam06_rend_a()
{
	thePlayer.DrainStamina(ESAT_FixedValue, thePlayer.GetStatMax(BCS_Stamina), 0.001);
	thePlayer.GainStat(BCS_Stamina, 100);
	thePlayer.GMTest06Sample(true);
	thePlayer.GMTestActReset();
	thePlayer.GMTestSetLastDrain(-1, 0);
	GMTestSpecialAttackInput(true, true);
}

// STAM-09: Whirl and Rend. Equip skilleq(S_Sword_s35) / skilleq(S_Sword_s02), draw a sword in a
// fight (god() and staminaboy() against interruptions), then:
//   gmtest_stam09_a(heavy, stamina, adrenaline)   sets stamina (no regen pause) and adrenaline,
//                                                  then presses Whirl (heavy false) or Rend
//   gmtest_stam09_s()                              logs time, stamina, adrenaline, special attack
//   gmtest_stam02_release(heavy)                   releases
exec function gmtest_stam09_a(heavy : bool, stamina : float, adrenaline : float)
{
	thePlayer.DrainStamina(ESAT_FixedValue, thePlayer.GetStatMax(BCS_Stamina), 0.001);
	thePlayer.GainStat(BCS_Stamina, stamina);
	thePlayer.ForceSetStat(BCS_Focus, adrenaline);
	thePlayer.GMTest06Sample(true);
	thePlayer.GMTestActReset();
	LogChannel('GMTest', "INFO STAM-09 start: stamina " + NoTrailZeros(thePlayer.GetStat(BCS_Stamina)) + ", adrenaline " + NoTrailZeros(thePlayer.GetStat(BCS_Focus))
		+ ", Whirl " + GetWitcherPlayer().GMWhirlSkill() + " level " + thePlayer.GetSkillLevel(GetWitcherPlayer().GMWhirlSkill()) + ", Whirl cost/s " + NoTrailZeros(GetWitcherPlayer().GMGetWhirlStaminaCost(1)));
	GMTestSpecialAttackInput(heavy, true);
}

exec function gmtest_stam09_s()
{
	LogChannel('GMTest', "INFO STAM-09 +" + NoTrailZeros(theGame.GetEngineTimeAsSeconds() - thePlayer.gmTestActStart) + " s: stamina " + NoTrailZeros(thePlayer.GetStat(BCS_Stamina))
		+ ", adrenaline " + NoTrailZeros(thePlayer.GetStat(BCS_Focus)) + ", special attack " + NoTrailZeros(thePlayer.GetBehaviorVariable('isPerformingSpecialAttack'))
		+ ", refusals " + (thePlayer.gmStaminaRefusals - thePlayer.gmTestRefusalsBefore));
}

// STAM-08: NPC stamina. gmtest_stam08_a() clears the NPC drain log and starts the clock;
// gmtest_stam08_s() logs the stamina of hostile NPCs within 10 m; gmtest_stam06_npc_b() lists
// the NPC drains and pauses since.
exec function gmtest_stam08_a()
{
	thePlayer.GMTestClearNpcPauses();
	thePlayer.GMTest06Sample(true);
}

exec function gmtest_stam08_s()
{
	var actors : array<CActor>;
	var i : int;

	actors = thePlayer.GetNPCsAndPlayersInRange(10, 20, , FLAG_OnlyAliveActors);
	for(i = 0; i < actors.Size(); i += 1)
		if(actors[i] != thePlayer && GetAttitudeBetween(thePlayer, actors[i]) == AIA_Hostile)
			LogChannel('GMTest', "INFO STAM-08 +" + NoTrailZeros(theGame.GetEngineTimeAsSeconds() - thePlayer.gmTestActStart) + " s " + actors[i].GetDisplayName()
				+ " stamina " + NoTrailZeros(actors[i].GetStat(BCS_Stamina)) + "/" + NoTrailZeros(actors[i].GetStatMax(BCS_Stamina)) + " attacking " + ((CNewNPC)actors[i]).IsAttacking() + " waiting " + actors[i].gmWaitForStaminaRegen + " shielded " + ((CNewNPC)actors[i]).IsShielded(thePlayer));
}

// Sets the stamina of hostile NPCs within 10 m (regen not paused).
exec function gmtest_stam08_set(value : float)
{
	var actors : array<CActor>;
	var i : int;

	actors = thePlayer.GetNPCsAndPlayersInRange(10, 20, , FLAG_OnlyAliveActors);
	for(i = 0; i < actors.Size(); i += 1)
		if(actors[i] != thePlayer && GetAttitudeBetween(thePlayer, actors[i]) == AIA_Hostile)
			actors[i].ForceSetStat(BCS_Stamina, value);
}

// STAM-08 investigation: the lifecycle of NPC attack tasks (start, Main reached, end) and the hits
// they land on Geralt, logged into the NPC log (gmtest_stam08_a() clears it, gmtest_stam06_npc_b()
// lists it). Shows whether attack tasks start without attacking (the ghoul and bear workaround).
@addField(CBTTaskAttack)
var gmTestStartedAt : float;
@addField(CBTTaskAttack)
var gmTestMainAt : float;

@addMethod(CBTTaskAttack)
function GMTestSetTimes(started : float, main : float)
{
	gmTestStartedAt = started;
	gmTestMainAt = main;
}

function GMTestNow() : float
{
	return theGame.GetEngineTimeAsSeconds() - thePlayer.gmTestActStart;
}

@wrapMethod(CBTTaskAttack)
function OnActivate() : EBTNodeStatus
{
	var ret : EBTNodeStatus;

	ret = wrappedMethod();
	if(!((CBTTaskCastSign)this) && GMTestProbes())
	{
		GMTestSetTimes(GMTestNow(), -1);
		thePlayer.GMTestLogNpcPause(GetActor().GetDisplayName() + " attack task " + attackType + " start +" + NoTrailZeros(gmTestStartedAt)
			+ " (cost " + xmlStaminaCostName + ", charged at start " + drainStaminaOnUse + ", result " + ret + ")");
	}
	return ret;
}

@wrapMethod(CBTTaskAttack)
function Main() : EBTNodeStatus
{
	var ret : EBTNodeStatus;

	if(!((CBTTaskCastSign)this) && GMTestProbes())
	{
		GMTestSetTimes(gmTestStartedAt, GMTestNow());
		thePlayer.GMTestLogNpcPause(GetActor().GetDisplayName() + " attack task " + attackType + " Main +" + NoTrailZeros(gmTestMainAt));
	}
	ret = wrappedMethod();
	return ret;
}

@wrapMethod(CBTTaskAttack)
function OnDeactivate()
{
	if(!((CBTTaskCastSign)this) && GMTestProbes())
		thePlayer.GMTestLogNpcPause(GetActor().GetDisplayName() + " attack task " + attackType + " end +" + NoTrailZeros(GMTestNow())
			+ " (ran " + NoTrailZeros(GMTestNow() - gmTestStartedAt) + " s)");
	wrappedMethod();
}

@wrapMethod(W3PlayerWitcher)
function OnTakeDamage(action : W3DamageAction)
{
	if(GMTestProbes() && (CActor)action.attacker && action.attacker != this && !action.IsDoTDamage())
		GMTestLogNpcPause(((CActor)action.attacker).GetDisplayName() + " HIT Geralt +" + NoTrailZeros(GMTestNow()));
	return wrappedMethod(action);
}

// Logs each attack charge's outcome: refunded (false start) or kept.
@wrapMethod(CBTTaskAttack)
function GMSettleAttackCharge()
{
	var charged : float;
	var falseStart : bool;

	charged = gmCharged;
	falseStart = theGame.GetEngineTimeAsSeconds() - gmChargedAt < 0.0001;
	wrappedMethod();
	if(charged > 0 && GMTestProbes())
	{
		if(falseStart)
			thePlayer.GMTestLogNpcPause(GetActor().GetDisplayName() + " refunded " + NoTrailZeros(charged) + " at +" + NoTrailZeros(GMTestNow()) + ", stamina " + NoTrailZeros(GetActor().GetStat(BCS_Stamina)));
		else
			thePlayer.GMTestLogNpcPause(GetActor().GetDisplayName() + " kept " + NoTrailZeros(charged) + " at +" + NoTrailZeros(GMTestNow()) + ", stamina " + NoTrailZeros(GetActor().GetStat(BCS_Stamina)));
	}
}

// STAM-08 slice 2 probes: NPC parry attempts and guard decisions, into the NPC log.
@wrapMethod(CBTTaskPerformParry)
function TryToParry(optional counter : bool) : bool
{
	var ret : bool;
	var before : float;

	before = GetNPC().GetStat(BCS_Stamina);
	ret = wrappedMethod(counter);
	if(GMTestProbes())
		thePlayer.GMTestLogNpcPause(GetNPC().GetDisplayName() + " TryToParry counter=" + counter + " stamina " + NoTrailZeros(before) + " -> " + NoTrailZeros(GetNPC().GetStat(BCS_Stamina))
		+ " result " + ret + " at +" + NoTrailZeros(GMTestNow()));
	return ret;
}

@wrapMethod(CBTTaskHitReactionDecorator)
function CheckGuardOrCounter() : bool
{
	var ret : bool;

	ret = wrappedMethod();
	if(GMTestProbes())
		thePlayer.GMTestLogNpcPause(GetNPC().GetDisplayName() + " guard-or-counter (hit reaction) " + ret + ", guarded " + GetNPC().IsGuarded() + ", stamina " + NoTrailZeros(GetNPC().GetStat(BCS_Stamina)) + " at +" + NoTrailZeros(GMTestNow()));
	return ret;
}

@wrapMethod(BTTaskAdditiveHitListener)
function CheckGuardOrCounter() : bool
{
	var ret : bool;

	ret = wrappedMethod();
	if(GMTestProbes())
		thePlayer.GMTestLogNpcPause(GetNPC().GetDisplayName() + " guard-or-counter (additive) " + ret + ", guarded " + GetNPC().IsGuarded() + ", stamina " + NoTrailZeros(GetNPC().GetStat(BCS_Stamina)) + " at +" + NoTrailZeros(GMTestNow()));
	return ret;
}

// Makes hostile NPCs within 10 m immortal (they take hits but do not die), for defence tests.
exec function gmtest_stam08_tough()
{
	var actors : array<CActor>;
	var i : int;

	actors = thePlayer.GetNPCsAndPlayersInRange(10, 20, , FLAG_OnlyAliveActors);
	for(i = 0; i < actors.Size(); i += 1)
		if(actors[i] != thePlayer && GetAttitudeBetween(thePlayer, actors[i]) == AIA_Hostile)
		{
			actors[i].SetImmortalityMode(AIM_Immortal, AIC_Default);
			LogChannel('GMTest', "INFO STAM-08 " + actors[i].GetDisplayName() + " immortal");
		}
}

@wrapMethod(CBTTaskPerformParry)
function CanParry() : bool
{
	var ret : bool;

	ret = wrappedMethod();
	if(GMTestProbes())
		thePlayer.GMTestLogNpcPause(GetNPC().GetDisplayName() + " parry window " + ret + ", stamina " + NoTrailZeros(GetNPC().GetStat(BCS_Stamina)) + " at +" + NoTrailZeros(GMTestNow()));
	return ret;
}

// Spawns a hostile shielded test enemy 2 m ahead (vanilla test template).
exec function gmtest_stam08_shield()
{
	var template : CEntityTemplate;
	var npc : CNewNPC;

	template = (CEntityTemplate)LoadResource("gameplay\templates\characters\npcs\test_enemies\enemy_shield_easy.w2ent", true);
	if(!template)
	{
		LogChannel('GMTest', "FAIL STAM-08 shield template not found");
		return;
	}
	npc = (CNewNPC)theGame.CreateEntity(template, thePlayer.GetWorldPosition() + thePlayer.GetHeadingVector() * 2, thePlayer.GetWorldRotation());
	npc.SetTemporaryAttitudeGroup('hostile_to_player', AGP_Default);
	LogChannel('GMTest', "INFO STAM-08 shield enemy spawned: shielded ability " + npc.HasShieldedAbility() + ", parry cost " + NoTrailZeros(CalculateAttributeValue(npc.GetAttributeValue('parry_stamina_cost'))));
}

@wrapMethod(CNewNPC)
function ProcessShieldDestruction()
{
	if(GMTestProbes())
		LogChannel('GMTest', "INFO STAM-08 shield destroyed: stamina " + NoTrailZeros(GetStat(BCS_Stamina)) + "/" + NoTrailZeros(GetStatMax(BCS_Stamina)));
	wrappedMethod();
}

// STAM-08 investigation: attack ticket holds. Logs every change of an NPC's attack ticket
// (gained, lost) as seen by its attack ticket algorithm, with the importance it asks with.
@addField(CTicketAttackAlgorithm)
var gmTestHadTicket : bool;

@addMethod(CTicketAttackAlgorithm)
function GMTestSetHadTicket(b : bool)
{
	gmTestHadTicket = b;
}

@wrapMethod(CTicketAttackAlgorithm)
function CalculateTicketImportance() : float
{
	var ret : float;
	var has : bool;

	ret = wrappedMethod();
	has = HasTicket();
	if(GMTestProbes() && has != gmTestHadTicket)
	{
		GMTestSetHadTicket(has);
		thePlayer.GMTestLogNpcPause(GetActor().GetDisplayName() + " TICKET " + has + " (importance " + NoTrailZeros(ret) + ", waiting " + GetActor().gmWaitForStaminaRegen
			+ ", stamina " + NoTrailZeros(GetActor().GetStat(BCS_Stamina)) + ") at +" + NoTrailZeros(GMTestNow()));
	}
	return ret;
}

// STAM-08 slice 4: NPC stamina values from Ghost Mode's DLC (gm_npc_stamina.xml).
function GMTestAbilityValue(ability : name, attr : name, expected : float)
{
	var min, max : SAbilityAttributeValue;
	var v : float;

	theGame.GetDefinitionsManager().GetAbilityAttributeValue(ability, attr, min, max);
	v = min.valueBase + min.valueMultiplicative + min.valueAdditive;
	GMTestReport(AbsF(v - expected) < 0.001, "XML " + ability + "." + attr + " = " + NoTrailZeros(v) + " (expected " + NoTrailZeros(expected) + ")");
}

exec function gmtest_stam08_xml()
{
	GMTest_stam08_xml();
}

function GMTest_stam08_xml()
{
	var actors : array<CActor>;
	var i : int;

	GMTestAbilityValue('mon_wolf_base', 'light_action_stamina_cost', 20);
	GMTestAbilityValue('mon_wolf_base', 'counter_stamina_cost', 20);
	GMTestAbilityValue('mon_wolf_base', 'staminaRegen', 0.25);
	GMTestAbilityValue('mon_panther_base', 'light_action_stamina_cost', 20);
	GMTestAbilityValue('mon_panther_base', 'staminaRegen', 0.25);
	GMTestAbilityValue('mon_dettlaff_base', 'parry_stamina_cost', 10);
	GMTestAbilityValue('mon_wyvern', 'light_special_stamina_cost', 0);
	actors = thePlayer.GetNPCsAndPlayersInRange(15, 20, , FLAG_OnlyAliveActors);
	for(i = 0; i < actors.Size(); i += 1)
		if(actors[i] != thePlayer && GetAttitudeBetween(thePlayer, actors[i]) == AIA_Hostile)
			LogChannel('GMTest', "INFO STAM-08 " + actors[i].GetDisplayName() + ": light " + NoTrailZeros(CalculateAttributeValue(actors[i].GetAttributeValue('light_action_stamina_cost')))
				+ ", heavy " + NoTrailZeros(CalculateAttributeValue(actors[i].GetAttributeValue('heavy_action_stamina_cost')))
				+ ", parry " + NoTrailZeros(CalculateAttributeValue(actors[i].GetAttributeValue('parry_stamina_cost')))
				+ ", counter " + NoTrailZeros(CalculateAttributeValue(actors[i].GetAttributeValue('counter_stamina_cost')))
				+ ", dodge " + NoTrailZeros(CalculateAttributeValue(actors[i].GetAttributeValue('dodge_stamina_cost')))
				+ ", max " + NoTrailZeros(actors[i].GetStatMax(BCS_Stamina)));
}

// STAM-07: the heartbeat bank from the mod's soundspc.cache. Loads it (synchronously),
// reports whether the sound engine has it, and starts the loop with the given parameters
// (0-100, as legacy's options). gmtest_stam07_stop() ends it with legacy's fade.
exec function gmtest_stam07_play(optional volume : float, optional rate : float)
{
	if(!theSound.SoundIsBankLoaded("heartbeat02a.bnk"))
		theSound.SoundLoadBank("heartbeat02a.bnk", false);
	GMTestReport(theSound.SoundIsBankLoaded("heartbeat02a.bnk"), "STAM-07 bank heartbeat02a.bnk loaded");
	theSound.SoundEvent("play_heartbeat_02a_loop");
	theSound.SoundParameter("heartbeat_rate", rate);
	theSound.SoundParameter("heartbeat_volume", volume);
	LogChannel('GMTest', "INFO STAM-07 play_heartbeat_02a_loop volume " + volume + " rate " + rate);
}

exec function gmtest_stam07_param(volume : float, rate : float)
{
	theSound.SoundParameter("heartbeat_rate", rate);
	theSound.SoundParameter("heartbeat_volume", volume);
	LogChannel('GMTest', "INFO STAM-07 volume " + volume + " rate " + rate);
}

exec function gmtest_stam07_stop()
{
	theSound.SoundEvent("stop_heartbeat_02a_loop");
	LogChannel('GMTest', "INFO STAM-07 stop_heartbeat_02a_loop");
}

// STAM-07: bring Geralt's stamina to a percentage of its maximum, down through DrainStamina (the
// path that runs the check; ForceSetStat does not change the player's stamina), up with GainStat.
exec function gmtest_stam07_set(prc : float)
{
	var target : float;

	target = 0.01 * prc * thePlayer.GetStatMax(BCS_Stamina);
	if(target < thePlayer.GetStat(BCS_Stamina))
		thePlayer.DrainStamina(ESAT_FixedValue, thePlayer.GetStat(BCS_Stamina) - target, 0.001);
	else
		thePlayer.GainStat(BCS_Stamina, target - thePlayer.GetStat(BCS_Stamina));
	LogChannel('GMTest', "INFO STAM-07 stamina set to " + NoTrailZeros(prc) + "%");
}

// STAM-07: one sample of the heartbeat state: stamina, threshold, whether it plays, and the
// dynamic level it is driven with, (1 - stamina / threshold) x 100.
exec function gmtest_stam07_s(optional label : string)
{
	var prc, threshold, level : float;

	prc = thePlayer.GetStatPercents(BCS_Stamina);
	threshold = 0.01 * GMGetOptionFloat('GMQOLOptions', 'GMLowStaminaSFX');
	level = 0;
	if(thePlayer.gmLowStaminaSFXPlaying && threshold > 0)
		level = (1.0f - prc / threshold) * 100.0f;
	LogChannel('GMTest', "INFO STAM-07 " + label + " t=" + NoTrailZeros(theGame.GetEngineTimeAsSeconds()) + " stamina " + NoTrailZeros(RoundTo(prc * 100, 1)) + "% threshold " + NoTrailZeros(threshold * 100) + "% playing " + thePlayer.gmLowStaminaSFXPlaying + " level " + NoTrailZeros(RoundTo(level, 1)) + " combat " + thePlayer.IsInCombat());
}

// STAM-09, situation-free: both trees' Whirl carry Ghost Mode's cost and reduction (XML).
exec function gmtest_stam09()
{
	GMTest_stam09();
}

function GMTest_stam09()
{
	GMTestAbilityValue('sword_s1', 'stamina_cost_per_sec', 50);
	GMTestAbilityValue('sword_s1', 'stamina_cost_reduction_after_1', 0.15);
	GMTestAbilityValue('sword_s35', 'stamina_cost_per_sec', 50);
	GMTestAbilityValue('sword_s35', 'stamina_cost_reduction_after_1', 0.3);	// SKL-03: 30% per level in the new tree
}

// STAM-07, situation-free: the bank loads, and the check starts the heartbeat below the threshold
// and stops it at full stamina (scripted drain and check; out of combat the bank mutes it).
exec function gmtest_stam07()
{
	GMTest_stam07();
}

function GMTest_stam07()
{
	var threshold : float;

	GMTestReport(GMIsQoLOption('GMLowStaminaSFX') && !GMIsQoLOption('GMSignCooldown'), "STAM-07 QoL options recognised");
	if(!theSound.SoundIsBankLoaded("heartbeat02a.bnk"))
		theSound.SoundLoadBank("heartbeat02a.bnk", false);
	GMTestReport(theSound.SoundIsBankLoaded("heartbeat02a.bnk"), "STAM-07 bank heartbeat02a.bnk loaded");
	threshold = 0.01 * GMGetOptionFloat('GMQOLOptions', 'GMLowStaminaSFX');
	if(threshold <= 0)
	{
		LogChannel('GMTest', "INFO STAM-07 threshold option is 0 (heartbeat off): logic not checked");
		return;
	}
	thePlayer.DrainStamina(ESAT_FixedValue, thePlayer.GetStat(BCS_Stamina) - 0.5 * threshold * thePlayer.GetStatMax(BCS_Stamina), 0.001);
	GMTestReport(thePlayer.gmLowStaminaSFXPlaying, "STAM-07 heartbeat on at half the threshold");
	thePlayer.GainStat(BCS_Stamina, thePlayer.GetStatMax(BCS_Stamina));
	thePlayer.GMCheckForLowStamina();
	GMTestReport(!thePlayer.gmLowStaminaSFXPlaying, "STAM-07 heartbeat off at full stamina");
}

// Regression run, in one game session: every check that needs no particular situation (no fight,
// no input, no menu), each restoring what it changes. Run when a feature is finished, followed in
// the same session by the character panel check, which needs a menu open (its later checks report
// after the SUMMARY line: read them too):
//   python tools/game.py exec --wait 3000 "gmtest_regress()" "ingamemenu()" "gmtest_panel()"
//   python tools/game.py resume
// LOOT's checks roll loot lists into a spawned merchant and stay out of it: gmtest_loot() in a launch
// of its own (docs/game-automation.md).
exec function gmtest_regress()
{
	thePlayer.GMTestCount(true, true);
	GMTest_skl02_newgame();	// first: needs nothing learned (right after gmreset())
	GMTest_opt01();
	GMTest_stam01();
	GMTest_stam02();
	GMTest_stam03();
	GMTest_stam05();
	GMTest_stam06();
	GMTest_stam04xml();
	GMTest_stam07();
	GMTest_stam08_xml();
	GMTest_stam09();
	GMTest_stamaudit();
	GMTest_def03();
	GMTest_def07();
	GMTest_dmg06();
	GMTest_dmgxml();
	GMTest_annotations();
	GMTest_d58();
	GMTest_skl01_passives(false);
	GMTest_skl01_rules();
	GMTest_skl19();
	GMTest_skl_tiers_xml();
	GMTest_alch();
	GMTest_sklg_dot();
	GMTest_sklg_selfbomb();
	GMTest_skla_undying();
	GMTest_skla_perk21();
	GMTest_skla_cleanse();
	GMTest_skl07_foa_keep();
	GMTest_skld_effects();
	GMTest_skl_values();
	GMTest_mut();
	GMTest_arm();
	GMTest_ench();
	GMTest_swd();
	GMTest_item();
	GMTest_craft();
	// GMTest_loot() is not in the regression: its loot rolls into a spawned merchant crash the game
	// (access violation) after a varying number of rolls; run gmtest_loot() in a launch of its own.
	GMTest_alchport();
	GMTest_uiport();
	GMTest_food();
	GMTest_efx01();
	GMTest_efx02();
	GMTest_efx04();
	GMTest_efx08();
	GMTest_efx11();
	GMTest_xbow01();
	GMTest_xbow02();
	GMTest_xbow04();
	GMTest_xbow07();
	GMTest_xbow08();
	GMTest_xbow09();
	GMTest_ai01();
	GMTest_ai03();
	GMTest_ai06();	// spawns the sample entities; GMTest_ai06_after() in gmtest_panel() reads and removes them
	GMTest_ai08();
	GMTest_ai10();	// spawns a deserter and a shield bearer; GMTest_ai10_after() in gmtest_panel() reads the counters' window and breaks the shield
	GMTest_ai11();	// spawns the poise and flyer NPCs; GMTest_ai11_after() in gmtest_panel() reads and removes them
	GMTest_ai14();	// spawns a cyclops and an arachas; GMTest_ai14_after() in gmtest_panel() reads and removes them
	GMTest_ai15();	// spawns Wild Hunt warriors and Eredin, one warrior burning with Ice Armor; GMTest_ai15_after() in gmtest_panel() reads and removes them
	GMTest_ai17();	// spawns a contract monster, rotfiends and bandits, reads the projectile data; GMTest_ai17_after() in gmtest_panel() hits and removes them
	GMTest_ai19();	// spawns the Caretaker and four quest monsters, the CausesDamage value, the shovel, the spade text; GMTest_ai19_after() in gmtest_panel() reads their immunities and removes them
	GMTest_ai20();	// Geralt's maximum Vitality in a fistfight, the fist damage bonus, a fistfighter for GMTest_ai20_after() in gmtest_panel() (the fight's start)
	GMTest_diffdata();	// DIFF-01, DIFF-03: the difficulty abilities and PrologModifier as the game reads them
	GMTest_diff07();	// DIFF-07: the guards' toll on the current mode (a quarter, no cap); gmtest_diff07(true) for all four
	GMTest_diff04();	// DIFF-04: the scaling types and the guards' option on two spawned samples at Geralt 20, options set back
	GMTest_diff09();	// DIFF-09: the Ciri option's cap for each mode and value, none for Geralt (current mode only, no mode change)
	GMTest_diff05();	// DIFF-05: Gerd and the q305 guard at their real level on the HUD, a fake addon and the cap set by hand not shown
	GMTest_xpdata();	// XP-08, XP-05: the level abilities and the enemies' experience nodes as the game reads them
	GMTest_xp05();	// XP-05: a kill's experience the same with +1000 experience on the NPC (nothing reads the node)
	GMTest_xpquestdata();	// XP-02, XP-03: the rewards' experience, level and gold, and the quest levels the journal reads
	GMTest_xp07();	// XP-07: the experience options' labels, defaults and hooks (options set in memory and set back)
	GMTest_xp04_who_spawn(false);	// XP-04 (XP audit F1): drowners, a renegade and a guard for GMTest_xp04_who_after() in gmtest_panel()
	GMTest_diff04_spawn();	// DIFF-04: a bandit for GMTest_diff04_after() in gmtest_panel() (mode and option changes after a load)
	GMTest_econ_e1();	// ECON-05 to ECON-08 (slice E1): buy, sale and fee prices and funds at eight spawned merchants (six types, three regions) against the measured formula and legacy's price table
	GMTest_econdata();	// ECON-01 to ECON-04 (slice E2): every regular ECON item's price, category, name key and price tags as the game reads them
	GMTest_econ_e2();	// ECON-01 (slice E2): what spawned merchants ask and pay for reference items at legacy's list prices; CRAFT-08 (PE13): Protofleder Mutagen at the dismantling station
	GMTest_econ_e3();	// ECON-08, ECON-09 (slice E3): merchants' money at spawn, the 3-day restock and the reset below 100 at eight spawned merchants; the haggling bar (double) and accept limits (1.2 to 1.7, always-successful 2) over many openings of the popup
	GMTest_econrewards();	// ECON-10, DE1, PE9 (slice E4): every ECON reward's gold as GetReward reads it (the rewards given through GiveReward run in gmtest_panel(), GMTest_econ_e4_give)
	GMTest_econ_e5();	// ECON-01, ECON-03 DE2 (slice E5): what a spawned Novigrad armorer asks and pays for a Netflix piece, a Netflix schematic and the Fire Horse saddle at DE2's list prices; ECON-11, ECON-12: the four patched scene and quest files load
	GMTest_wgt();	// WGT (parallel ports: its checks go into tests/gmTestsWgt.ws)
	GMTest_opt();	// OPT (parallel ports: its checks go into tests/gmTestsOpt.ws)
	GMTest_trph();	// TRPH (parallel ports: its checks go into tests/gmTestsTrph.ws)
	GMTest_fix();	// FIX (parallel ports: its checks go into tests/gmTestsFix.ws)
	GMTest_horse();	// HORSE (parallel ports: its checks go into tests/gmTestsHorse.ws)
	GMTest_data();	// whole-port data checks (tests/gmTestsData.ws)
	GMTest_stam10();	// STAM-10: exhaustion, paying from max stamina (tests/gmTestsStam10.ws); in the classic tree that it is off
	GMTest_compat();	// forms that let sibling ports combine in any load order (tests/gmTestsCompat.ws)
	GMTest_classic_tree();	// the classic tree as legacy's: tree as drawn, Rend and Whirl, new-tree skills and rules off (tests/gmTestsClassic.ws); new tree: skipped
	LogChannel('GMTest', "SUMMARY regress: " + thePlayer.gmTestPassed + " passed, " + thePlayer.gmTestFailed + " failed");
}

// STAM audit fixes (2026-10-03), situation-free; the NPC checks run when a hostile NPC is within
// 20 m (spawn one first), and are skipped otherwise.
exec function gmtest_stamaudit()
{
	GMTest_stamaudit();
}

function GMTest_stamaudit()
{
	var actors : array<CActor>;
	var npc : CActor;
	var cost, delay, parryCost : float;
	var i : int;

	// Test probes are off until a test switches them on.
	thePlayer.GMTestSetProbes(false);
	thePlayer.GMTestClearNpcPausesOnly();
	thePlayer.DrainStamina(ESAT_Dodge);
	GMTestReport(thePlayer.gmTestDrainLog.Size() == 0, "audit X1 probes off: a dodge drain was not logged");
	GMTestReport(!GMTestProbes(), "audit X1 probes off by default after GMTestSetProbes(false)");

	// S3-2: costs are capped at 100 for every actor (fixed value 150 asked for).
	thePlayer.abilityManager.GetStaminaActionCost(ESAT_FixedValue, cost, delay, 150, 0);
	GMTestReport(AbsF(cost - 100) < 0.01, "audit S3-2 Geralt's fixed cost 150 capped to " + NoTrailZeros(cost));

	// S3-3: the sprint lockout. At 0 stamina CanSprint sets the time; with stamina back it still
	// refuses for 2 s.
	thePlayer.DrainStamina(ESAT_FixedValue, thePlayer.GetStatMax(BCS_Stamina), 0.001);
	GetWitcherPlayer().CanSprint(1);
	thePlayer.GainStat(BCS_Stamina, thePlayer.GetStatMax(BCS_Stamina));
	GMTestReport(!GetWitcherPlayer().CanSprint(1), "audit S3-3 sprint refused right after stopping at 0 stamina");

	actors = thePlayer.GetNPCsAndPlayersInRange(20, 20, , FLAG_OnlyAliveActors);
	for(i = 0; i < actors.Size(); i += 1)
		if(actors[i] != thePlayer && GetAttitudeBetween(thePlayer, actors[i]) == AIA_Hostile)
		{
			npc = actors[i];
			break;
		}
	if(!npc)
	{
		LogChannel('GMTest', "INFO audit: no hostile NPC within 20 m, NPC checks skipped");
		return;
	}
	npc.abilityManager.GetStaminaActionCost(ESAT_FixedValue, cost, delay, 150, 0);
	GMTestReport(AbsF(cost - 100) < 0.01, "audit S3-2 " + npc.GetDisplayName() + "'s fixed cost 150 capped to " + NoTrailZeros(cost));
	// S3-1: an NPC with 1.1x its parry cost can parry a heavy attack (vanilla needed 1.25x).
	parryCost = npc.GetStaminaActionCost(ESAT_Parry, '', 0);
	npc.ForceSetStat(BCS_Stamina, parryCost * 1.1);
	GMTestReport(npc.HasStaminaToParry('attack_heavy'), "audit S3-1 " + npc.GetDisplayName() + " can parry a heavy attack with 1.1x its parry cost (" + NoTrailZeros(parryCost) + "), stamina " + NoTrailZeros(npc.GetStat(BCS_Stamina)));
	npc.ForceSetStat(BCS_Stamina, npc.GetStatMax(BCS_Stamina));
}
