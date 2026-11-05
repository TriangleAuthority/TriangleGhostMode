// OPT's in-game checks (options, docs/features/opt.md). Pre-seeded empty for the parallel ports
// (docs/proposals/parallel-ports.md, section 5): gmtest_regress() and gmtest_panel() already call the two
// functions below, so OPT adds its checks here and never edits gmTests.ws's lists.
//   GMTest_opt()        in gmtest_regress(): checks that need no fight, input or menu, each restoring what it changes
//   GMTest_opt_after()  in gmtest_panel(): checks that need the pause menu open, or read the game a frame or more
//                        after gmtest_regress() (spawned samples, effects' first updates)

exec function gmtest_opt()
{
	thePlayer.GMTestCount(true, true);
	GMTest_opt();
	LogChannel('GMTest', "SUMMARY opt: " + thePlayer.gmTestPassed + " passed, " + thePlayer.gmTestFailed + " failed");
}

function GMTest_opt()
{
	GMTest_opt_o0();
	GMTest_opt_o1();
	GMTest_opt02_resist();	// fix3
	GMTest_opt_o2();
	GMTest_opt_o3();
}

// O0: WGT's three menu entries (boat sinking, its threshold, item weight reduction) in the gameplay group, in legacy's
// place (after the port's skill tree toggle, PO3), with legacy's ids, types, labels and the defaults OPT writes (DO3).
// GetVarDisplayType gives the type without the slider's range ("SLIDER"): the ranges (0 to 100) are read in the menu XML.
function GMTestOptEntry(index : int, option : name, displayType : string, labelId : int, wanted : string)
{
	var cfg : CInGameConfigWrapper;
	var display, value : string;

	cfg = theGame.GetInGameConfigWrapper();
	GMTestReport(cfg.GetVarNameByGroupName('GMGameplayOptions', index) == option, "OPT O0 " + NameToString(option) + " is gameplay option " + index + " (found " + NameToString(cfg.GetVarNameByGroupName('GMGameplayOptions', index)) + ")");
	GMTestReport(cfg.GetVarDisplayType('GMGameplayOptions', option) == displayType, "OPT O0 " + NameToString(option) + " type " + cfg.GetVarDisplayType('GMGameplayOptions', option));
	display = cfg.GetVarDisplayName('GMGameplayOptions', option);
	GMTestReport(display != "" && GetLocStringByKeyExt("option_" + display) == GetLocStringById(labelId) && GetLocStringById(labelId) != "", "OPT O0 " + NameToString(option) + " label '" + GetLocStringByKeyExt("option_" + display) + "' (string " + labelId + ")");
	GMTestReport(GMOptionDefault('GMGameplayOptions', option) == wanted, "OPT O0 " + NameToString(option) + " default " + GMOptionDefault('GMGameplayOptions', option));
	value = cfg.GetVarValue('GMGameplayOptions', option);
	GMTestReport(value == wanted, "OPT O0 " + NameToString(option) + " written at the load: '" + value + "'");
}

function GMTest_opt_o0()
{
	GMTestOptEntry(1, 'GMSinkBoat', "TOGGLE", 2110992180, "true");
	GMTestOptEntry(2, 'GMSinkBoatOverEnc', "SLIDER", 2110992181, "20");
	GMTestOptEntry(3, 'GMEncumbranceMultiplier', "SLIDER", 2110992183, "0");
	GMTestReport(GMGetOptionBool('GMGameplayOptions', 'GMSinkBoat') && GMGetOptionFloat('GMGameplayOptions', 'GMSinkBoatOverEnc') == 20 && GMGetOptionFloat('GMGameplayOptions', 'GMEncumbranceMultiplier') == 0, "OPT O0 the getters read on, 20, 0");
}

function GMTest_opt_after()
{
}

// ---- O1: Geralt's Vitality regeneration (OPT-02, OPT-03, DO1, DO2) ----

// The regen effect's value for an attribute, as SetEffectValue gives it (with the option and 5.x's boost).
@addMethod(W3Effect_AutoVitalityRegen)
function GMTestValueFor(attr : name) : float
{
	var keep : name;

	keep = attributeName;
	attributeName = attr;
	SetEffectValue();
	attributeName = keep;
	return effectValue.valueAdditive + effectValue.valueMultiplicative * target.GetStatMax(BCS_Vitality);
}

function GMTestOptSet(group : name, option : name, value : string)
{
	theGame.GetInGameConfigWrapper().SetVarValue(group, option, value);
}

function GMTestOptGet(group : name, option : name) : string
{
	return theGame.GetInGameConfigWrapper().GetVarValue(group, option);
}

function GMTestOptBool(b : bool) : string
{
	if(b)
		return "true";
	return "false";
}

function GMTestOptRegenOn() : bool
{
	return GetWitcherPlayer().HasBuff(EET_AutoVitalityRegen);
}

// Geralt's own Vitality regen per second for an attribute (food, potions, skills), without the options.
function GMTestOptOwnRegen(attr : name) : float
{
	var v : SAbilityAttributeValue;

	v = GetWitcherPlayer().GetAttributeValue(attr);
	return v.valueAdditive + v.valueMultiplicative * GetWitcherPlayer().GetStatMax(BCS_Vitality);
}

// One start case: the regen stopped, then started as the game starts it; whether it runs, and its value (the
// options on top of Geralt's own regen: in the regression earlier checks leave food and potions on him, which
// start the regen of their own, so a case expecting no start is checked only without them).
function GMTestOptO1Start(outOpt : string, combatOpt : string, boost : bool, wantStart : bool, label : string)
{
	var w : W3PlayerWitcher;
	var regen : W3Effect_AutoVitalityRegen;
	var started : bool;
	var vOut, vCombat, ownOut, ownCombat : float;

	w = GetWitcherPlayer();
	ownOut = GMTestOptOwnRegen('vitalityRegen');
	ownCombat = GMTestOptOwnRegen('vitalityCombatRegen');
	if((ownOut != 0 || ownCombat != 0) && !wantStart)
	{
		LogChannel('GMTest', "INFO OPT O1 " + label + ": not checked, Geralt has a Vitality regen of his own now (" + ownOut + "/s, " + ownCombat + "/s in combat; checked by gmtest_opt() on a fresh load)");
		return;
	}
	GMTestOptSet('GMGameplayOptions', 'GMOutOfCombatVitalityRegen', outOpt);
	GMTestOptSet('GMGameplayOptions', 'GMCombatVitalityRegen', combatOpt);
	GMTestOptSet('Accessibility', 'LowHPAutoHealOn', GMTestOptBool(boost));
	w.StopVitalityRegen();
	started = w.StartVitalityRegen();
	regen = (W3Effect_AutoVitalityRegen)w.GetBuff(EET_AutoVitalityRegen);
	GMTestReport(started == wantStart && GMTestOptRegenOn() == wantStart, "OPT O1 " + label + ": regen running " + GMTestOptRegenOn() + " (start " + started + ", expected " + wantStart + ")");
	if(regen && !boost)
	{
		vOut = regen.GMTestValueFor('vitalityRegen');
		vCombat = regen.GMTestValueFor('vitalityCombatRegen');
		GMTestReport(GMTestArmNear(vOut, ownOut + StringToFloat(outOpt)) && GMTestArmNear(vCombat, ownCombat + StringToFloat(combatOpt))
			&& GMTestArmNear(GMPanelVitalityRegen('vitalityRegen'), vOut) && GMTestArmNear(GMPanelVitalityRegen('vitalityCombatRegen'), vCombat),
			"OPT O1 " + label + ": " + vOut + "/s out of combat, " + vCombat + "/s in combat (his own " + ownOut + " and " + ownCombat + " + the options); the panel's lines " + GMPanelVitalityRegen('vitalityRegen') + " and " + GMPanelVitalityRegen('vitalityCombatRegen'));
	}
	w.StopVitalityRegen();
}

function GMTest_opt_o1()
{
	var w : W3PlayerWitcher;
	var cfg : CInGameConfigWrapper;
	var vMin, vMax, cMin, cMax : SAbilityAttributeValue;
	var prevOut, prevCombat, prevBoost : string;
	var vit : float;
	var wasRunning : bool;

	w = GetWitcherPlayer();
	cfg = theGame.GetInGameConfigWrapper();
	theGame.GetDefinitionsManager().GetAbilityAttributeValue('ConGeralt', 'vitalityRegen', vMin, vMax);
	theGame.GetDefinitionsManager().GetAbilityAttributeValue('ConGeralt', 'vitalityCombatRegen', cMin, cMax);
	GMTestReport(vMin.valueAdditive == 0 && vMin.valueMultiplicative == 0 && cMin.valueAdditive == 0 && cMin.valueMultiplicative == 0,
		"OPT-02 ConGeralt's Vitality regen 0 and 0 (vitalityRegen add " + vMin.valueAdditive + ", vitalityCombatRegen add " + cMin.valueAdditive + "; 5.x 1 and 1)");
	GMTestReport(GMOptionDefault('GMGameplayOptions', 'GMCombatVitalityRegen') == "0" && GMOptionDefault('GMGameplayOptions', 'GMOutOfCombatVitalityRegen') == "0"
		&& cfg.GetVarValue('GMGameplayOptions', 'GMCombatVitalityRegen') != "" && cfg.GetVarValue('GMGameplayOptions', 'GMOutOfCombatVitalityRegen') != "",
		"OPT-03 the two options default 0, written at the load (" + cfg.GetVarValue('GMGameplayOptions', 'GMCombatVitalityRegen') + ", " + cfg.GetVarValue('GMGameplayOptions', 'GMOutOfCombatVitalityRegen') + ")");
	GMTestReport(cfg.GetVarNameByGroupName('GMGameplayOptions', 7) == 'GMCombatVitalityRegen' && cfg.GetVarNameByGroupName('GMGameplayOptions', 8) == 'GMOutOfCombatVitalityRegen'
		&& GetLocStringByKeyExt("option_" + cfg.GetVarDisplayName('GMGameplayOptions', 'GMCombatVitalityRegen')) == GetLocStringById(2110992393)
		&& GetLocStringByKeyExt("option_" + cfg.GetVarDisplayName('GMGameplayOptions', 'GMOutOfCombatVitalityRegen')) == GetLocStringById(2110992394) && GetLocStringById(2110992393) != "",
		"OPT-03 the options after the stamina regen ones, labels '" + GetLocStringById(2110992393) + "', '" + GetLocStringById(2110992394) + "'");

	prevOut = cfg.GetVarValue('GMGameplayOptions', 'GMOutOfCombatVitalityRegen');
	prevCombat = cfg.GetVarValue('GMGameplayOptions', 'GMCombatVitalityRegen');
	prevBoost = cfg.GetVarValue('Accessibility', 'LowHPAutoHealOn');
	vit = w.GetStat(BCS_Vitality);
	wasRunning = GMTestOptRegenOn();
	w.ForceSetStat(BCS_Vitality, w.GetStatMax(BCS_Vitality) * 0.5);

	GMTestOptO1Start("0", "0", false, false, "the defaults (no regen of his own)");
	GMTestOptO1Start("10", "0", false, true, "out of combat 10");
	GMTestOptO1Start("0", "20", false, true, "combat 20 alone (DO2)");
	GMTestOptO1Start("0", "0", true, true, "Vitality Regeneration Boost on (DO1)");
	GMTestOptO1Tvarog();

	GMTestOptSet('GMGameplayOptions', 'GMOutOfCombatVitalityRegen', prevOut);
	GMTestOptSet('GMGameplayOptions', 'GMCombatVitalityRegen', prevCombat);
	GMTestOptSet('Accessibility', 'LowHPAutoHealOn', prevBoost);
	w.ForceSetStat(BCS_Vitality, vit);
	if(wasRunning)
		w.StartVitalityRegen();
}

// OPT audit F1: a combat regen of Geralt's own alone (the Tvarog rune's ability, +5 in combat, ENCH-16) starts the
// regen as the game starts it, with the options at 0 and the boost off (set by the caller). Geralt's effects that give
// him an out-of-combat regen (the regression's food and potions) are saved, removed and put back with their time left,
// so the start is the combat regen's; with another out-of-combat source (a skill, an item) the case is not checked.
function GMTestOptO1Tvarog()
{
	var w : W3PlayerWitcher;
	var dm : CDefinitionsManagerAccessor;
	var buffs : array<CBaseGameplayEffect>;
	var types : array<EEffectType>;
	var kept : array<SGMTestEfxSavedBuff>;
	var mn, mx : SAbilityAttributeValue;
	var regen : W3Effect_AutoVitalityRegen;
	var t : EEffectType;
	var i : int;
	var started : bool;
	var ownOut, ownCombat, vCombat : float;

	w = GetWitcherPlayer();
	GMTestOptSet('GMGameplayOptions', 'GMOutOfCombatVitalityRegen', "0");
	GMTestOptSet('GMGameplayOptions', 'GMCombatVitalityRegen', "0");
	GMTestOptSet('Accessibility', 'LowHPAutoHealOn', "false");
	dm = theGame.GetDefinitionsManager();
	buffs = w.GetBuffs(EET_Undefined);
	for(i = 0; i < buffs.Size(); i += 1)
	{
		t = buffs[i].GetEffectType();
		if(t == EET_AutoVitalityRegen || types.Contains(t))
			continue;
		dm.GetAbilityAttributeValue(buffs[i].GetAbilityName(), 'vitalityRegen', mn, mx);
		if(mn.valueAdditive != 0 || mn.valueMultiplicative != 0 || mx.valueAdditive != 0 || mx.valueMultiplicative != 0)
			types.PushBack(t);
	}
	kept = GMTestEfxSaveBuffs(types);
	for(i = 0; i < types.Size(); i += 1)
		w.RemoveAllBuffsOfType(types[i]);
	w.AddAbility('Rune tvarog _Stats', false);
	ownOut = GMTestOptOwnRegen('vitalityRegen');
	ownCombat = GMTestOptOwnRegen('vitalityCombatRegen');
	if(ownOut != 0)
		LogChannel('GMTest', "INFO OPT audit F1 not checked: Geralt has an out-of-combat Vitality regen of his own besides his effects (" + ownOut + "/s; checked by gmtest_opt() on a fresh load)");
	else
	{
		w.StopVitalityRegen();
		started = w.StartVitalityRegen();
		regen = (W3Effect_AutoVitalityRegen)w.GetBuff(EET_AutoVitalityRegen);
		if(regen)
			vCombat = regen.GMTestValueFor('vitalityCombatRegen');
		GMTestReport(started && GMTestOptRegenOn() && ownCombat > 0 && GMTestArmNear(vCombat, ownCombat) && GMTestArmNear(GMPanelVitalityRegen('vitalityCombatRegen'), vCombat),
			"OPT audit F1 a combat regen of Geralt's own alone (the Tvarog rune, " + ownCombat + "/s in combat, " + types.Size() + " effect types set aside) starts the regen: start "
			+ started + ", running " + GMTestOptRegenOn() + ", " + vCombat + "/s in combat, the panel's line " + GMPanelVitalityRegen('vitalityCombatRegen'));
		w.StopVitalityRegen();
	}
	w.RemoveAbility('Rune tvarog _Stats');
	GMTestEfxRestoreBuffs(types, kept);
}

// O1 in play, measured (separate exec calls, so time passes; not in the regression):
//   gmtest_opt_o1_a(out, combat, boost, food)   options set as given (saved), Vitality at 50%, the regen stopped,
//                                               then a 1-point drain (DrainVitality starts the regen, as a real hit
//                                               does); food: a Bread's Well Fed (WellFedEffect_Level1) added
//   gmtest_opt_o1_b(extra)                      the rate since the last sample against the panel's line for the regen
//                                               in force, plus the boost (which the panel leaves out, PO5), + extra
//   gmtest_opt_o1_end()                         the options and the boost back to the values before the first
//                                               gmtest_opt_o1_a, food removed, Vitality full
@addField(CR4Player)
var gmTestO1Time : float;

@addField(CR4Player)
var gmTestO1Vit : float;

// The player's two Vitality options and 5.x's boost before the first gmtest_opt_o1_a, put back by gmtest_opt_o1_end.
@addField(CR4Player)
var gmTestO1Saved : bool;

@addField(CR4Player)
var gmTestO1OldOut : string;

@addField(CR4Player)
var gmTestO1OldCombat : string;

@addField(CR4Player)
var gmTestO1OldBoost : string;

@addMethod(CR4Player)
function GMTestO1Sample()
{
	gmTestO1Time = theGame.GetEngineTimeAsSeconds();
	gmTestO1Vit = GetStat(BCS_Vitality);
}

exec function gmtest_opt_o1_a(outOpt : int, combatOpt : int, optional boost : bool, optional food : bool)
{
	var w : W3PlayerWitcher;
	var cfg : CInGameConfigWrapper;

	w = GetWitcherPlayer();
	if(!w.gmTestO1Saved)
	{
		cfg = theGame.GetInGameConfigWrapper();
		w.gmTestO1OldOut = cfg.GetVarValue('GMGameplayOptions', 'GMOutOfCombatVitalityRegen');
		w.gmTestO1OldCombat = cfg.GetVarValue('GMGameplayOptions', 'GMCombatVitalityRegen');
		w.gmTestO1OldBoost = cfg.GetVarValue('Accessibility', 'LowHPAutoHealOn');
		w.gmTestO1Saved = true;
	}
	GMTestOptSet('GMGameplayOptions', 'GMOutOfCombatVitalityRegen', IntToString(outOpt));
	GMTestOptSet('GMGameplayOptions', 'GMCombatVitalityRegen', IntToString(combatOpt));
	GMTestOptSet('Accessibility', 'LowHPAutoHealOn', GMTestOptBool(boost));
	GMTestFoodClear();
	w.StopVitalityRegen();
	w.ForceSetStat(BCS_Vitality, w.GetStatMax(BCS_Vitality) * 0.5 + 1);
	w.DrainVitality(1);
	if(food)
		GMTestFoodAdd(EET_WellFed, 'WellFedEffect_Level1');
	w.GMTestO1Sample();
	LogChannel('GMTest', "INFO OPT O1 set: out " + outOpt + ", combat " + combatOpt + ", boost " + boost + ", food " + food + "; Vitality " + w.GetStat(BCS_Vitality) + " of " + w.GetStatMax(BCS_Vitality)
		+ ", regen " + GMTestOptRegenOn() + ", in combat " + w.IsInCombat());
}

// 5.x's "Vitality Regeneration Boost" at a Vitality fraction, as W3Effect_AutoVitalityRegen.OnUpdate gives it (0 when off).
function GMTestOptBoost(perc : float) : float
{
	var cfg : CInGameConfigWrapper;
	var ratio : float;

	cfg = theGame.GetInGameConfigWrapper();
	if(cfg.GetVarValue('Accessibility', 'LowHPAutoHealOn') != "true")
		return 0;
	ratio = perc / (0.01f * StringToFloat(cfg.GetVarValue('Accessibility', 'LowHPAutoHealThreshold')));
	if(ratio >= 1)
		return 1;
	return (ClampF(1 - ratio, 0, 1) + 0.1) * StringToInt(cfg.GetVarValue('Accessibility', 'LowHPAutoHealMultiplier'));
}

exec function gmtest_opt_o1_b(optional extra : float)
{
	var w : W3PlayerWitcher;
	var dt, rate, want : float;
	var attr : name;
	var where : string;

	w = GetWitcherPlayer();
	dt = theGame.GetEngineTimeAsSeconds() - w.gmTestO1Time;
	rate = (w.GetStat(BCS_Vitality) - w.gmTestO1Vit) / dt;
	attr = 'vitalityRegen';
	where = "out of combat";
	if(w.IsInCombat())
	{
		attr = 'vitalityCombatRegen';
		where = "in combat";
	}
	extra += GMTestOptBoost(w.gmTestO1Vit / w.GetStatMax(BCS_Vitality));
	want = GMPanelVitalityRegen(attr) + extra;
	GMTestReport(dt > 1 && AbsF(rate - want) <= MaxF(0.15 * want, 0.2), "OPT O1 measured " + NoTrailZeros(RoundTo(rate, 2)) + "/s over " + NoTrailZeros(RoundTo(dt, 1)) + " s " + where
		+ " (expected " + NoTrailZeros(want) + ": the panel's line " + NoTrailZeros(GMPanelVitalityRegen(attr)) + " + " + NoTrailZeros(extra) + "); regen " + GMTestOptRegenOn());
	w.GMTestO1Sample();
}

// OPT audit F1 in a fight: the Tvarog rune's ability on Geralt (on) or off, for gmtest_opt_o1_a(0, 0) and
// gmtest_opt_o1_b() with a frozen hostile test dummy (gmtest_dummy("human")) keeping him in combat: 5/s expected.
exec function gmtest_opt_tvarog(on : bool)
{
	var w : W3PlayerWitcher;

	w = GetWitcherPlayer();
	if(on && !w.HasAbility('Rune tvarog _Stats'))
		w.AddAbility('Rune tvarog _Stats', false);
	else if(!on)
		w.RemoveAbility('Rune tvarog _Stats');
	LogChannel('GMTest', "INFO OPT Tvarog " + on + ": Geralt's own Vitality regen " + GMTestOptOwnRegen('vitalityRegen') + "/s out of combat, "
		+ GMTestOptOwnRegen('vitalityCombatRegen') + "/s in combat; in combat " + w.IsInCombat() + ", regen running " + GMTestOptRegenOn());
}

exec function gmtest_opt_o1_end()
{
	var w : W3PlayerWitcher;

	w = GetWitcherPlayer();
	if(w.gmTestO1Saved)
	{
		GMTestOptSet('GMGameplayOptions', 'GMOutOfCombatVitalityRegen', w.gmTestO1OldOut);
		GMTestOptSet('GMGameplayOptions', 'GMCombatVitalityRegen', w.gmTestO1OldCombat);
		GMTestOptSet('Accessibility', 'LowHPAutoHealOn', w.gmTestO1OldBoost);
		w.gmTestO1Saved = false;
	}
	GMTestFoodClear();
	w.ForceSetStat(BCS_Vitality, w.GetStatMax(BCS_Vitality));
	LogChannel('GMTest', "INFO OPT O1 options back to out " + GMTestOptGet('GMGameplayOptions', 'GMOutOfCombatVitalityRegen')
		+ ", combat " + GMTestOptGet('GMGameplayOptions', 'GMCombatVitalityRegen') + ", boost " + GMTestOptGet('Accessibility', 'LowHPAutoHealOn')
		+ "; food removed, Vitality full");
}

// O1 through the menu's code path: gmtest_opt_o1_stop() (Vitality 50%, regen stopped), ingamemenu(),
// gmtest_opt_o1_menu(group, option, value) (the option set and the menu's change event called as its Flash does),
// game.py resume (SaveChangedSettings and the regen start), then gmtest_opt_o1_running(true).
exec function gmtest_opt_o1_stop()
{
	var w : W3PlayerWitcher;

	w = GetWitcherPlayer();
	w.ForceSetStat(BCS_Vitality, w.GetStatMax(BCS_Vitality) * 0.5);
	w.StopVitalityRegen();
	w.GMTestO1Sample();
	LogChannel('GMTest', "INFO OPT O1 Vitality at 50%, regen " + GMTestOptRegenOn());
}

exec function gmtest_opt_o1_menu(group : name, option : name, value : string)
{
	var menu : CR4IngameMenu;
	var cfg : CInGameConfigWrapper;

	menu = GMTestDiff04Menu();
	if(!menu)
	{
		LogChannel('GMTest', "FAIL OPT O1 the options menu is not open");
		return;
	}
	cfg = theGame.GetInGameConfigWrapper();
	cfg.SetVarValue(group, option, value);
	menu.OnOptionValueChanged(cfg.GetGroupIdx(NameToString(group)), option, value);
	LogChannel('GMTest', "INFO OPT O1 " + NameToString(option) + "=" + value + " through the menu's event; regen " + GMTestOptRegenOn() + "; close the menu to apply");
}

exec function gmtest_opt_o1_running(want : bool)
{
	GMTestReport(GMTestOptRegenOn() == want, "OPT O1 regen running: " + GMTestOptRegenOn() + " (expected " + want + ")");
}

// ---- O2: the gameplay and QoL presets and legacy's order of the gameplay group (OPT-07, PO3, PO8, DO4) ----

// The gameplay group in legacy's order, after the port's skill tree toggle (PO3).
function GMTestOptGameplayOrder(out vars : array<name>)
{
	vars.Clear();
	vars.PushBack('GMClassicSkillTree');
	vars.PushBack('GMSinkBoat');
	vars.PushBack('GMSinkBoatOverEnc');
	vars.PushBack('GMEncumbranceMultiplier');
	vars.PushBack('GMArmorRegenPenalty');
	vars.PushBack('GMCombatStaminaRegen');
	vars.PushBack('GMOutOfCombatStaminaRegen');
	vars.PushBack('GMCombatVitalityRegen');
	vars.PushBack('GMOutOfCombatVitalityRegen');
	vars.PushBack('GMAgilityStaminaCostMultiplier');
	vars.PushBack('GMMeleeStaminaCostMultiplier');
	vars.PushBack('GMSignStaminaCostMultiplier');
	vars.PushBack('GMStaminaDelay');
	vars.PushBack('GMMeleeSpecialCooldown');
	vars.PushBack('GMSignCooldown');
	vars.PushBack('GMAltSignCooldown');
	// STAM-10 (not legacy's; after legacy's options)
	vars.PushBack('GMExhaustion');
	vars.PushBack('GMExhaustionMaxRegen');
	vars.PushBack('GMExhaustionAdrenaline');
	vars.PushBack('GMExhaustionFloor');
}

// Legacy's preset values for the gameplay group (from GMSinkBoat on, the order above): 0 "Recommended",
// 1 "Vanilla(ish)", 2 "Off".
function GMTestOptGameplayPreset(idx : int, out vals : array<string>)
{
	vals.Clear();
	if(idx == 0)
	{
		vals.PushBack("true"); vals.PushBack("20"); vals.PushBack("0"); vals.PushBack("false"); vals.PushBack("0"); vals.PushBack("0");
		vals.PushBack("0"); vals.PushBack("0"); vals.PushBack("0"); vals.PushBack("0"); vals.PushBack("0"); vals.PushBack("0");
		vals.PushBack("7.5"); vals.PushBack("5"); vals.PushBack("7.5");
		vals.PushBack("true"); vals.PushBack("0.4"); vals.PushBack("0.03"); vals.PushBack("40");	// STAM-10
	}
	else if(idx == 1)
	{
		vals.PushBack("false"); vals.PushBack("0"); vals.PushBack("0"); vals.PushBack("true"); vals.PushBack("-5"); vals.PushBack("0");
		vals.PushBack("1"); vals.PushBack("1"); vals.PushBack("0"); vals.PushBack("-1"); vals.PushBack("1.5"); vals.PushBack("0");
		vals.PushBack("0"); vals.PushBack("0"); vals.PushBack("0");
		vals.PushBack("false"); vals.PushBack("0.4"); vals.PushBack("0.03"); vals.PushBack("40");	// STAM-10
	}
	else
	{
		vals.PushBack("false"); vals.PushBack("0"); vals.PushBack("0"); vals.PushBack("false"); vals.PushBack("0"); vals.PushBack("0");
		vals.PushBack("0"); vals.PushBack("0"); vals.PushBack("0"); vals.PushBack("0"); vals.PushBack("0"); vals.PushBack("0");
		vals.PushBack("0"); vals.PushBack("0"); vals.PushBack("0");
		vals.PushBack("false"); vals.PushBack("0.4"); vals.PushBack("0.03"); vals.PushBack("40");	// STAM-10
	}
}

function GMTestOptQoLVars(out vars : array<name>)
{
	vars.Clear();
	vars.PushBack('GMLowStaminaSFX');
	vars.PushBack('GMLowStaminaSFXVolume');
	vars.PushBack('GMLowStaminaSFXDynamicVolume');
	vars.PushBack('GMLowStaminaSFXRate');
	vars.PushBack('GMLowStaminaSFXDynamicRate');
}

function GMTestOptQoLPreset(idx : int, out vals : array<string>)
{
	vals.Clear();
	if(idx == 0)
	{
		vals.PushBack("50"); vals.PushBack("100"); vals.PushBack("true"); vals.PushBack("0"); vals.PushBack("true");
	}
	else
	{
		vals.PushBack("0"); vals.PushBack("0"); vals.PushBack("false"); vals.PushBack("0"); vals.PushBack("false");
	}
}

// The values a group's variables hold, compared with a list (as floats for numbers, so "7.5" equals "7.50").
function GMTestOptValuesAre(group : name, vars : array<name>, first : int, vals : array<string>, out diff : string) : bool
{
	var cfg : CInGameConfigWrapper;
	var i : int;
	var v : string;
	var ok : bool;

	cfg = theGame.GetInGameConfigWrapper();
	ok = true;
	for(i = 0; i < vals.Size(); i += 1)
	{
		v = cfg.GetVarValue(group, vars[first + i]);
		if(v != vals[i] && !(vals[i] != "true" && vals[i] != "false" && StringToFloat(v) == StringToFloat(vals[i]) && v != ""))
		{
			ok = false;
			diff += " " + NameToString(vars[first + i]) + "=" + v + " (expected " + vals[i] + ")";
		}
	}
	return ok;
}

// What the gameplay options do under the preset in force: cooldowns, a sign's cost (40 base), a melee cost (10 base),
// the combat stamina regen added, the Vitality regen options, the armor penalty and boat sinking.
function GMTestOptGameplayEffects(idx : int)
{
	var signCost, meleeCost : float;
	var stam : SAbilityAttributeValue;
	var label : string;
	var ok : bool;

	signCost = 40;
	GMModStaminaCost(ESAT_Ability, true, signCost);
	meleeCost = 10;
	GMModStaminaCost(ESAT_LightAttack, false, meleeCost);
	GMModStaminaRegenValue('staminaRegen', stam);
	if(idx == 0)
	{
		label = "Recommended";
		ok = theGame.params.GMGetSignCooldownDuration() == 5 && theGame.params.GMGetAltSignCooldownDuration() == 7.5 && theGame.params.GMGetMeleeSpecialCooldownDuration() == 7.5 && signCost == 40 && meleeCost == 10
			&& stam.valueAdditive == 0 && GMVitalityRegenOption('vitalityRegen') == 0 && GMVitalityRegenOption('vitalityCombatRegen') == 0 && !GMIsArmorRegenPenaltyEnabled()
			&& GMGetOptionBool('GMGameplayOptions', 'GMSinkBoat');
	}
	else if(idx == 1)
	{
		label = "Vanilla(ish)";
		ok = theGame.params.GMGetSignCooldownDuration() == 0 && theGame.params.GMGetAltSignCooldownDuration() == 0 && theGame.params.GMGetMeleeSpecialCooldownDuration() == 0 && signCost == 100 && meleeCost == 0
			&& stam.valueAdditive == -5 && GMVitalityRegenOption('vitalityRegen') == 1 && GMVitalityRegenOption('vitalityCombatRegen') == 1 && GMIsArmorRegenPenaltyEnabled()
			&& !GMGetOptionBool('GMGameplayOptions', 'GMSinkBoat');
	}
	else
	{
		label = "Off";
		ok = theGame.params.GMGetSignCooldownDuration() == 0 && theGame.params.GMGetAltSignCooldownDuration() == 0 && theGame.params.GMGetMeleeSpecialCooldownDuration() == 0 && signCost == 40 && meleeCost == 10
			&& stam.valueAdditive == 0 && GMVitalityRegenOption('vitalityRegen') == 0 && GMVitalityRegenOption('vitalityCombatRegen') == 0 && !GMIsArmorRegenPenaltyEnabled()
			&& !GMGetOptionBool('GMGameplayOptions', 'GMSinkBoat');
	}
	GMTestReport(ok, "OPT O2 \"" + label + "\" in play: cooldowns " + theGame.params.GMGetMeleeSpecialCooldownDuration() + ", " + theGame.params.GMGetSignCooldownDuration() + ", " + theGame.params.GMGetAltSignCooldownDuration()
		+ "; sign cost 40 -> " + signCost + ", light attack 10 -> " + meleeCost + "; combat stamina regen " + stam.valueAdditive + "; Vitality regen +" + GMVitalityRegenOption('vitalityRegen')
		+ " and +" + GMVitalityRegenOption('vitalityCombatRegen') + "; armor penalty " + GMIsArmorRegenPenaltyEnabled() + "; boat sinking " + GMGetOptionBool('GMGameplayOptions', 'GMSinkBoat'));
}

function GMTest_opt_o2()
{
	var cfg : CInGameConfigWrapper;
	var gvars, qvars : array<name>;
	var gkeep, qkeep, vals : array<string>;
	var i : int;
	var orderOk : bool;
	var diff, found : string;

	cfg = theGame.GetInGameConfigWrapper();
	GMTestOptGameplayOrder(gvars);
	GMTestOptQoLVars(qvars);
	orderOk = cfg.GetVarsNumByGroupName('GMGameplayOptions') == gvars.Size();
	for(i = 0; i < gvars.Size(); i += 1)
	{
		found += " " + NameToString(cfg.GetVarNameByGroupName('GMGameplayOptions', i));
		orderOk = orderOk && cfg.GetVarNameByGroupName('GMGameplayOptions', i) == gvars[i];
	}
	GMTestReport(orderOk, "OPT O2 the gameplay group in legacy's order (PO3):" + found);

	GMTestReport(cfg.GetGroupPresetsNum('GMGameplayOptions') == 3 && cfg.GetGroupPresetsNum('GMQOLOptions') == 2
		&& cfg.GetGroupPresetDisplayName('GMGameplayOptions', 1) == "gm_old_ver"
		&& GetLocStringByKeyExt("preset_value_gm_old_ver") == GetLocStringById(2110992459) && GetLocStringById(2110992459) != ""
		&& GetLocStringByKeyExt("preset_Mods_ghost_mode_gm_gameplay_options") == GetLocStringById(2110992450) && GetLocStringById(2110992450) != ""
		&& GetLocStringByKeyExt("preset_Mods_ghost_mode_gm_qol_options") == GetLocStringById(2110992447) && GetLocStringById(2110992447) != "",
		"OPT O2 presets: gameplay " + cfg.GetGroupPresetsNum('GMGameplayOptions') + " ('" + GetLocStringByKeyExt("preset_value_gm_recommended") + "', '" + GetLocStringByKeyExt("preset_value_gm_old_ver") + "', '"
		+ GetLocStringByKeyExt("preset_value_gm_turn_off") + "'), QoL " + cfg.GetGroupPresetsNum('GMQOLOptions') + "; headers '" + GetLocStringByKeyExt("preset_Mods_ghost_mode_gm_gameplay_options") + "', '"
		+ GetLocStringByKeyExt("preset_Mods_ghost_mode_gm_qol_options") + "'");

	for(i = 0; i < gvars.Size(); i += 1)
		gkeep.PushBack(cfg.GetVarValue('GMGameplayOptions', gvars[i]));
	for(i = 0; i < qvars.Size(); i += 1)
		qkeep.PushBack(cfg.GetVarValue('GMQOLOptions', qvars[i]));

	for(i = 0; i < 3; i += 1)
	{
		cfg.ApplyGroupPreset('GMGameplayOptions', i);
		GMTestOptGameplayPreset(i, vals);
		diff = "";
		GMTestReport(GMTestOptValuesAre('GMGameplayOptions', gvars, 1, vals, diff) && cfg.GetVarValue('GMGameplayOptions', 'GMClassicSkillTree') == gkeep[0],
			"OPT O2 gameplay preset " + i + " sets legacy's values, the skill tree toggle untouched (PO8)" + diff);
		GMTestOptGameplayEffects(i);
	}
	for(i = 0; i < 2; i += 1)
	{
		cfg.ApplyGroupPreset('GMQOLOptions', i);
		GMTestOptQoLPreset(i, vals);
		diff = "";
		GMTestReport(GMTestOptValuesAre('GMQOLOptions', qvars, 0, vals, diff), "OPT O2 QoL preset " + i + " sets legacy's values (without GMSignInstantCast, DO5)" + diff);
	}
	// DO4: with the menu untouched the QoL group has "Recommended"'s values (legacy: none, no heartbeat)
	GMTestOptQoLPreset(0, vals);
	diff = "";
	for(i = 0; i < qvars.Size(); i += 1)
		if(GMOptionDefault('GMQOLOptions', qvars[i]) != vals[i])
			diff += " " + NameToString(qvars[i]) + "=" + GMOptionDefault('GMQOLOptions', qvars[i]);
	GMTestReport(diff == "", "OPT O2 the QoL defaults are \"Recommended\"'s (DO4)" + diff);
	GMTestOptGameplayPreset(0, vals);
	diff = "";
	for(i = 1; i < gvars.Size(); i += 1)
		if(StringToFloat(GMOptionDefault('GMGameplayOptions', gvars[i])) != StringToFloat(vals[i - 1]) || (vals[i - 1] == "true") != (GMOptionDefault('GMGameplayOptions', gvars[i]) == "true"))
			diff += " " + NameToString(gvars[i]) + "=" + GMOptionDefault('GMGameplayOptions', gvars[i]);
	GMTestReport(diff == "", "OPT O2 the gameplay defaults are \"Recommended\"'s (legacy's gmLoadDefaultSettings)" + diff);

	for(i = 0; i < gvars.Size(); i += 1)
		cfg.SetVarValue('GMGameplayOptions', gvars[i], gkeep[i]);
	for(i = 0; i < qvars.Size(); i += 1)
		cfg.SetVarValue('GMQOLOptions', qvars[i], qkeep[i]);
}

// O2 through the menu's code path: with the options menu open (ingamemenu()), a preset applied through the menu's
// OnPresetApplied as its Flash calls it; closing the menu (game.py resume) runs the group's reaction.
//   gmtest_opt_o2_prep()             Vitality at 50% with the regen stopped, stamina at 20% held for 30 s
//   gmtest_opt_o2_preset(group, i)   with the menu open
//   gmtest_opt_o2_after(group, i)    after the menu closed: the values, the regen running (gameplay), the heartbeat
//                                    playing or not (QoL)
exec function gmtest_opt_o2_prep()
{
	var w : W3PlayerWitcher;

	w = GetWitcherPlayer();
	w.ForceSetStat(BCS_Vitality, w.GetStatMax(BCS_Vitality) * 0.5);
	w.StopVitalityRegen();
	w.GMTestO1Sample();
	w.DrainStamina(ESAT_FixedValue, w.GetStat(BCS_Stamina) - w.GetStatMax(BCS_Stamina) * 0.2, 30);
	LogChannel('GMTest', "INFO OPT O2 Vitality 50% (regen " + GMTestOptRegenOn() + "), stamina " + NoTrailZeros(RoundTo(w.GetStatPercents(BCS_Stamina) * 100, 1)) + "%, heartbeat " + thePlayer.gmLowStaminaSFXPlaying);
}

exec function gmtest_opt_o2_preset(group : name, idx : int)
{
	var menu : CR4IngameMenu;

	menu = GMTestDiff04Menu();
	if(!menu)
	{
		LogChannel('GMTest', "FAIL OPT O2 the options menu is not open");
		return;
	}
	menu.OnPresetApplied(group, idx);
	LogChannel('GMTest', "INFO OPT O2 " + NameToString(group) + " preset " + idx + " applied through the menu's event; close the menu to apply");
}

exec function gmtest_opt_o2_after(group : name, idx : int)
{
	var gvars : array<name>;
	var vals : array<string>;
	var diff : string;

	if(group == 'GMGameplayOptions')
	{
		GMTestOptGameplayOrder(gvars);
		GMTestOptGameplayPreset(idx, vals);
		GMTestReport(GMTestOptValuesAre(group, gvars, 1, vals, diff), "OPT O2 gameplay preset " + idx + " through the menu: values" + diff);
		GMTestOptGameplayEffects(idx);
		GMTestReport(GMTestOptRegenOn() == (idx == 1), "OPT O2 gameplay preset " + idx + " through the menu: Vitality regen running " + GMTestOptRegenOn() + " (expected " + (idx == 1) + ")");
	}
	else
	{
		GMTestOptQoLVars(gvars);
		GMTestOptQoLPreset(idx, vals);
		GMTestReport(GMTestOptValuesAre(group, gvars, 0, vals, diff), "OPT O2 QoL preset " + idx + " through the menu: values" + diff);
		GMTestReport(thePlayer.gmLowStaminaSFXPlaying == (idx == 0), "OPT O2 QoL preset " + idx + " through the menu: heartbeat at " + NoTrailZeros(RoundTo(thePlayer.GetStatPercents(BCS_Stamina) * 100, 1))
			+ "% stamina playing " + thePlayer.gmLowStaminaSFXPlaying + " (expected " + (idx == 0) + ")");
	}
}

// Both groups back to "Recommended" (the defaults), Vitality and stamina full.
exec function gmtest_opt_o2_end()
{
	var cfg : CInGameConfigWrapper;
	var w : W3PlayerWitcher;

	cfg = theGame.GetInGameConfigWrapper();
	cfg.ApplyGroupPreset('GMGameplayOptions', 0);
	cfg.ApplyGroupPreset('GMQOLOptions', 0);
	theGame.SaveUserSettings();
	w = GetWitcherPlayer();
	w.ForceSetStat(BCS_Vitality, w.GetStatMax(BCS_Vitality));
	w.ForceSetStat(BCS_Stamina, w.GetStatMax(BCS_Stamina));
	LogChannel('GMTest', "INFO OPT O2 both groups back to \"Recommended\", Vitality and stamina full");
}

// ---- O3: instant sign casting is 5.x's "Quick Sign Casting" (OPT-06, DO5, PO13) ----

// Situation-free: legacy's toggle is not in the QoL group (DO5); 5.x's setting is in its Gameplay group.
function GMTest_opt_o3()
{
	var cfg : CInGameConfigWrapper;

	cfg = theGame.GetInGameConfigWrapper();
	// an undeclared variable reads as type "NONE" (seen in OPT slice O0's failing build)
	GMTestReport(cfg.GetVarDisplayType('GMQOLOptions', 'GMSignInstantCast') == "NONE" && cfg.GetVarDisplayType('Gameplay', 'EnableAlternateSignCasting') == "OPTIONS",
		"OPT O3 no instant-casting toggle in Ghost Mode's QoL group (type " + cfg.GetVarDisplayType('GMQOLOptions', 'GMSignInstantCast') + "); 5.x's Quick Sign Casting in its Gameplay settings ('" + cfg.GetVarDisplayName('Gameplay', 'EnableAlternateSignCasting') + "', value '"
		+ cfg.GetVarValue('Gameplay', 'EnableAlternateSignCasting') + "')");
}

@addField(CR4Player)
var gmTestWebReleases : int;

@addMethod(CR4Player)
function GMTestWebReleasesAdd(n : int)
{
	gmTestWebReleases += n;
}

// Counts the web's release of the select keys (a test wrapper of the global function).
@wrapMethod
function GMWebReleaseSignSelectKeys()
{
	thePlayer.GMTestWebReleasesAdd(1);
	wrappedMethod();
}

function GMTestOptSelectInput(sign : ESignType, pressed : bool)
{
	var action : SInputAction;

	switch(sign)
	{
		case ST_Aard :	action.aName = 'SelectAard'; break;
		case ST_Igni :	action.aName = 'SelectIgni'; break;
		case ST_Yrden :	action.aName = 'SelectYrden'; break;
		case ST_Quen :	action.aName = 'SelectQuen'; break;
		default :	action.aName = 'SelectAxii'; break;
	}
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
	thePlayer.GetInputHandler().OnSelectSign(action);
}

@addField(CR4Player)
var gmTestO3Stamina : float;

@addField(CR4Player)
var gmTestO3Casting : bool;

@addField(CR4Player)
var gmTestO3CooldownBefore : bool;

@addMethod(CR4Player)
function GMTestO3SetStamina(v : float)
{
	gmTestO3Stamina = v;
}

@addMethod(CR4Player)
function GMTestO3SetPress(casting : bool, cooldownBefore : bool)
{
	gmTestO3Casting = casting;
	gmTestO3CooldownBefore = cooldownBefore;
}

// gmtest_opt_o3_select(sign, mode): a select key pressed by script through CPlayerInput.OnSelectSign, as the key
// does. Before it: another sign equipped, no sign cooldowns; mode 0 stamina full, 1 the sign on cooldown, 2 no
// stamina. gmtest_opt_o3_after(sign, wantCast) in a later call: cast (the cast started at the press, the sign
// equipped, its cooldown started by the cast; stamina regenerates too fast out of combat to read the cost) or not
// (with Quick Sign Casting off the key only selects the sign); then the key released.
exec function gmtest_opt_o3_select(sign : ESignType, mode : int)
{
	var w : W3PlayerWitcher;
	var other : ESignType;

	w = GetWitcherPlayer();
	other = ST_Aard;
	if(sign == ST_Aard)
		other = ST_Igni;
	w.SetEquippedSign(other);
	w.RemoveAllBuffsOfType(GMSignCooldownType(sign));
	w.RemoveAllBuffsOfType(GMSignCooldownType(other));
	w.ForceSetStat(BCS_Stamina, w.GetStatMax(BCS_Stamina));
	if(mode == 1)
		GMAddSignCooldown(sign, false);
	if(mode == 2)
		w.DrainStamina(ESAT_FixedValue, w.GetStatMax(BCS_Stamina), 30);
	w.GMTestO3SetStamina(w.GetStat(BCS_Stamina));
	GMTestOptSelectInput(sign, true);
	w.GMTestO3SetPress(w.IsCastingSign(), mode == 1);
	LogChannel('GMTest', "INFO OPT O3 select " + sign + " pressed (mode " + mode + ", Quick Sign Casting " + thePlayer.GetInputHandler().GetIsAltSignCasting() + "): equipped " + w.GetEquippedSign()
		+ ", casting " + w.IsCastingSign() + ", stamina " + NoTrailZeros(w.GetStat(BCS_Stamina)));
}

exec function gmtest_opt_o3_after(sign : ESignType, wantCast : bool)
{
	var w : W3PlayerWitcher;
	var cast : bool;

	w = GetWitcherPlayer();
	cast = w.gmTestO3Casting && GMIsSignOnCooldown(sign) && !w.gmTestO3CooldownBefore;
	GMTestReport(cast == wantCast && (!wantCast || w.GetEquippedSign() == sign),
		"OPT O3 select " + sign + " (Quick Sign Casting " + thePlayer.GetInputHandler().GetIsAltSignCasting() + "): cast " + cast + " (expected " + wantCast + "); equipped " + w.GetEquippedSign()
		+ ", stamina " + NoTrailZeros(w.gmTestO3Stamina) + " -> " + NoTrailZeros(w.GetStat(BCS_Stamina)) + ", cooldown " + GMIsSignOnCooldown(sign));
	GMTestOptSelectInput(sign, false);
	w.RemoveAllBuffsOfType(GMSignCooldownType(sign));
	w.ResumeStaminaRegen(StaminaActionTypeToName(ESAT_FixedValue));
	w.ForceSetStat(BCS_Stamina, w.GetStatMax(BCS_Stamina));
}

// gmtest_opt_o3_web(want): a spider web on Geralt as an arachas's projectile adds it; the select keys are released
// (PO13) only while Quick Sign Casting is on.
exec function gmtest_opt_o3_web(want : bool)
{
	var params : SCustomEffectParams;
	var before : int;

	before = thePlayer.gmTestWebReleases;
	params.effectType = EET_Tangled;
	params.creator = thePlayer;
	params.sourceName = "gmtest";
	params.duration = 1;
	thePlayer.AddEffectCustom(params);
	GMTestReport(thePlayer.HasBuff(EET_Tangled) && (thePlayer.gmTestWebReleases > before) == want,
		"OPT O3 a spider web on Geralt (Quick Sign Casting " + thePlayer.GetInputHandler().GetIsAltSignCasting() + "): the select keys released " + (thePlayer.gmTestWebReleases - before) + " time(s) (expected " + want + ")");
	thePlayer.RemoveAllBuffsOfType(EET_Tangled);
}

exec function gmtest_opt_o3_state()
{
	LogChannel('GMTest', "INFO OPT O3 Quick Sign Casting: setting '" + theGame.GetInGameConfigWrapper().GetVarValue('Gameplay', 'EnableAlternateSignCasting') + "', input handler " + thePlayer.GetInputHandler().GetIsAltSignCasting());
}

// OPT-02, Geralt's base stats (fix3, sweep D G8): no natural poison or bleeding resistance (legacy 0; 5.x 25% each), as
// ConGeralt gives it, the other ConGeralt nodes (OPT-02's regen 0, STAM-04's stamina regen) kept.
function GMTest_opt02_resist()
{
	var dm : CDefinitionsManagerAccessor;
	var min, max : SAbilityAttributeValue;
	var poison, bleeding, regen : float;

	dm = theGame.GetDefinitionsManager();
	dm.GetAbilityAttributeValue('ConGeralt', 'poison_resistance_perc', min, max);
	poison = min.valueBase + min.valueAdditive;	// base nodes: CalculateAttributeValue reads 0 without a multiplier
	dm.GetAbilityAttributeValue('ConGeralt', 'bleeding_resistance_perc', min, max);
	bleeding = min.valueBase + min.valueAdditive;
	dm.GetAbilityAttributeValue('ConGeralt', 'staminaRegen', min, max);
	regen = min.valueMultiplicative;
	GMTestReport(poison == 0 && bleeding == 0 && AbsF(regen - 0.15) < 0.0001,
		"OPT-02 Geralt's base poison and bleeding resistance: " + poison + ", " + bleeding + " (legacy 0, 0; 5.x 0.25 each), ConGeralt's other nodes kept (stamina regen multiplier " + regen + ", 0.15)");
}
