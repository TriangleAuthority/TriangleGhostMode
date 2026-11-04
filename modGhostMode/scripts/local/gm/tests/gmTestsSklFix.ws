// In-game tests for the whole-port fix round's SKL findings (2026-11-03; docs/features/skl.md):
// C1-1 Focus credits the sign charged, C1-2 no Quen strip of a hit's effects, C1-4 the basic Quen's HUD
// rounding, C2-1 Rend's full charge above 99%, C2-3 Undying ends at a load, A1-1 the active Quen's regen
// delay counted once, A3-3 Entanglement's trap keeps its radius with Sustained Glyphs.
// GMTest_sklfix() runs in gmtest_regress() (from GMTest_skl_values); the exec functions below it are the
// real-cast checks.

// --- probes (on only while a check runs) ---

@addField(W3PlayerWitcher)
var gmTestFocusProbe : bool;
@addField(W3PlayerWitcher)
var gmTestFocusCredited : W3SignEntity;
@addField(W3PlayerWitcher)
var gmTestDelayProbe : bool;
@addField(W3PlayerWitcher)
var gmTestFixedDelay : float;
@addField(W3PlayerWitcher)
var gmTestFixedDelays : int;
@addField(W3PlayerWitcher)
var gmTestSustainedOverride : bool;

@wrapMethod(W3SignEntity)
function GMManageFocusGain(cost : float, dt : float)
{
	var w : W3PlayerWitcher;

	w = GetWitcherPlayer();
	if(w && w.gmTestFocusProbe)
		w.gmTestFocusCredited = this;
	wrappedMethod(cost, dt);
}

@wrapMethod(W3AbilityManager)
function DrainStamina(action : EStaminaActionType, optional fixedCost : float, optional fixedDelay : float, optional abilityName : name, optional dt : float, optional costMult : float) : float
{
	var w : W3PlayerWitcher;

	w = GetWitcherPlayer();
	if(w && w.gmTestDelayProbe && owner == w && action == ESAT_FixedValue && fixedCost > 0)
	{
		w.gmTestFixedDelay = fixedDelay;
		w.gmTestFixedDelays += 1;
	}
	return wrappedMethod(action, fixedCost, fixedDelay, abilityName, dt, costMult);
}

// Sustained Glyphs at level 2 of the tree in force, for a check (no skill equipped).
@wrapMethod(W3YrdenEntity)
function GMSustainedGlyphsSkill() : ESkill
{
	var s : ESkill;

	s = wrappedMethod();
	if(GetWitcherPlayer() && GetWitcherPlayer().gmTestSustainedOverride)
	{
		if(GMIsClassicProfileInForce())
			return S_Magic_s10;
		return S_Magic_s42;
	}
	return s;
}

@wrapMethod(W3YrdenEntity)
function GMSustainedGlyphsLevel(sustained : ESkill) : int
{
	var l : int;

	l = wrappedMethod(sustained);
	if(GetWitcherPlayer() && GetWitcherPlayer().gmTestSustainedOverride)
		return 2;
	return l;
}

// A sign entity of Geralt's, set up as a non-player cast (not his current sign).
@addMethod(W3PlayerWitcher)
function GMTestFixSign(sign : ESignType) : W3SignEntity
{
	var e : W3SignEntity;

	e = (W3SignEntity)theGame.CreateEntity(signs[sign].template, GetWorldPosition(), GetWorldRotation());
	if(e)
		e.Init(signOwner, NULL, true, true);
	return e;
}

// Geralt's current sign and sign entities, saved before a check that sets them and put back after.
@addField(W3PlayerWitcher)
var gmTestSavedCurrent : ESignType;
@addField(W3PlayerWitcher)
var gmTestSavedSigns : array<W3SignEntity>;

@addMethod(W3PlayerWitcher)
function GMTestSaveSigns()
{
	var i : int;

	gmTestSavedCurrent = GetCurrentlyCastSign();
	gmTestSavedSigns.Clear();
	for(i = 0; i < signs.Size(); i += 1)
		gmTestSavedSigns.PushBack(signs[i].entity);
}

@addMethod(W3PlayerWitcher)
function GMTestRestoreSigns()
{
	var i : int;

	for(i = 0; i < signs.Size() && i < gmTestSavedSigns.Size(); i += 1)
		signs[i].entity = gmTestSavedSigns[i];
	currentlyCastSign = gmTestSavedCurrent;
}

@addMethod(W3SignEntity)
function GMTestSetFireMode(m : int)
{
	fireMode = m;
}

@addMethod(W3DamageManagerProcessor)
function GMTestQuenStrip(act : W3DamageAction, victim : CActor)
{
	action = act;
	actorVictim = victim;
	ApplyQuenBuffChanges();
}

@addMethod(W3PlayerWitcher)
function GMTestFixQuenTemplate() : CEntityTemplate
{
	return signs[ST_Quen].template;
}

@addMethod(W3QuenEntity)
function GMTestSetShieldHealth(h : float, initial : float)
{
	shieldHealth = h;
	initialShieldHealth = initial;
}

@addMethod(W3Effect_BasicQuen)
function GMTestSetQuenEntity(q : W3QuenEntity)
{
	quenEntity = q;
}

// --- the regression's checks ---

function GMTest_sklfix()
{
	GMTest_sklfix_focus();
	GMTest_sklfix_quenhit();
	GMTest_sklfix_hud();
	GMTest_sklfix_rend();
	GMTest_sklfix_undying();
	GMTest_sklfix_entangle();
}

exec function gmtest_sklfix()
{
	thePlayer.GMTestCount(true, true);
	GMTest_sklfix();
	LogChannel('GMTest', "SUMMARY sklfix: " + thePlayer.gmTestPassed + " passed, " + thePlayer.gmTestFailed + " failed");
}

// C1-1: a sign charged after the cast state cleared Geralt's current sign (a normal Quen, Yrden or Axii)
// gets Focus's adrenaline credit: the stamina drain of its charge credits that sign.
function GMTest_sklfix_focus()
{
	var w : W3PlayerWitcher;
	var q : W3SignEntity;
	var stamina : float;

	w = GetWitcherPlayer();
	w.GMTestSaveSigns();
	q = w.GMTestFixSign(ST_Quen);
	if(!q)
	{
		w.GMTestRestoreSigns();
		GMTestReport(false, "SKL-18 Focus (fx C1-1): no Quen entity created");
		return;
	}
	stamina = w.GetStat(BCS_Stamina);
	w.SetCurrentlyCastSign(ST_None, NULL);	// as a normal Quen at its charge: the cast state has cleared it
	w.ForceSetStat(BCS_Stamina, w.GetStatMax(BCS_Stamina));
	w.gmTestFocusCredited = NULL;
	w.gmTestFocusProbe = true;
	q.GMPaySignCost(w, true);
	w.gmTestFocusProbe = false;
	GMTestReport(w.gmTestFocusCredited == q && w.GetCurrentSignEntity() != q && !w.GMHasRageManagement(),
		"SKL-18 Focus (fx C1-1): a Quen charged when it is not Geralt's current sign earns Focus's credit for itself: credited " + (w.gmTestFocusCredited == q) + " (none " + !w.gmTestFocusCredited + "), its current sign " + (w.GetCurrentSignEntity() == q) + ", Rage Management " + w.GMHasRageManagement());
	w.gmTestFocusCredited = NULL;
	w.ForceSetStat(BCS_Stamina, stamina);
	w.GMTestRestoreSigns();
	q.Destroy();
}

// C1-2: an effect of a hit Geralt's alternate Quen fully absorbs is kept (legacy; 5.x stripped every effect
// but knockdowns): 5.x's rule run on a hit with blindness, Geralt's current sign a test Quen set as an
// alternate cast that absorbed all damage. A1-1: with the "Stamina regen delay" option at +2 the active
// shield's absorb drain gets the delay without the option (the drain adds it once).
function GMTest_sklfix_quenhit()
{
	var w : W3PlayerWitcher;
	var cfg : CInGameConfigWrapper;
	var prev : string;
	var action : W3DamageAction;
	var proc : W3DamageManagerProcessor;
	var q : W3QuenEntity;
	var types : array<EEffectType>;
	var read, passed : float;
	var kept, alt : bool;

	w = GetWitcherPlayer();
	w.GMTestSaveSigns();
	q = (W3QuenEntity)w.GMTestFixSign(ST_Quen);
	if(!q)
	{
		w.GMTestRestoreSigns();
		GMTestReport(false, "SKL-11 (fx C1-2): no Quen entity created");
		return;
	}
	q.GMTestSetFireMode(1);
	q.SetBlockedAllDamage(true);
	w.SetCurrentlyCastSign(ST_Quen, q);
	alt = w.HasAlternateQuen();
	action = new W3DamageAction in theGame.damageMgr;
	action.Initialize(w, w, NULL, "GMTestSklFix", EHRT_None, CPS_Undefined, false, false, false, false);
	action.AddEffectInfo(EET_Blindness, 2);
	proc = new W3DamageManagerProcessor in theGame.damageMgr;
	proc.GMTestQuenStrip(action, w);
	action.GetEffectTypes(types);
	kept = types.Contains(EET_Blindness);
	GMTestReport(alt && kept,
		"SKL-11 (fx C1-2): a hit the alternate Quen fully absorbs keeps its blindness: kept " + kept + " (5.x: stripped), alternate Quen " + alt);
	delete proc;
	delete action;
	w.GMTestRestoreSigns();
	q.Destroy();

	cfg = theGame.GetInGameConfigWrapper();
	prev = cfg.GetVarValue('GMGameplayOptions', 'GMStaminaDelay');
	cfg.SetVarValue('GMGameplayOptions', 'GMStaminaDelay', "2");
	read = w.GetStaminaActionDelay(ESAT_Ability, w.GetSkillAbilityName(S_Magic_s04));
	passed = GMQuenAbsorbDelay(w, w.GetSkillAbilityName(S_Magic_s04));
	cfg.SetVarValue('GMGameplayOptions', 'GMStaminaDelay', prev);
	GMTestReport(AbsF(passed + 2 - read) < 0.001,
		"SKL-11 (fx A1-1): the active Quen's absorb drain counts the regen delay option (+2) once: drain delay " + passed + " + option 2, expected " + read);
}

// C1-2 and A1-1 in play: with a real alternate Quen held (autocast(ST_Quen, true)), a scripted hit of 50
// physical with blindness from the hostile test dummy: the hit is fully absorbed, Geralt is blinded, and with
// the option at +2 the absorb drain's delay plus the option is Active Shield's delay read with it.
exec function gmtest_sklfix_quenlive()
{
	var w : W3PlayerWitcher;
	var npc : CActor;
	var cfg : CInGameConfigWrapper;
	var prev : string;
	var action : W3Action_Attack;
	var types : array<EEffectType>;
	var read : float;

	w = GetWitcherPlayer();
	npc = GMTestHostileNpc();
	if(!npc)
		return;
	w.RemoveAllBuffsOfType(EET_Blindness);
	w.ForceSetStat(BCS_Stamina, w.GetStatMax(BCS_Stamina));
	cfg = theGame.GetInGameConfigWrapper();
	prev = cfg.GetVarValue('GMGameplayOptions', 'GMStaminaDelay');
	cfg.SetVarValue('GMGameplayOptions', 'GMStaminaDelay', "2");
	read = w.GetStaminaActionDelay(ESAT_Ability, w.GetSkillAbilityName(S_Magic_s04));
	w.gmTestFixedDelays = 0;
	w.gmTestDelayProbe = true;
	action = new W3Action_Attack in theGame.damageMgr;
	action.Init(npc, w, NULL, GetInvalidUniqueId(), 'attack_light', npc.GetName(), EHRT_Light,
		false, false, '', AST_Jab, ASD_UpDown, true, false, false, false);
	action.AddDamage(theGame.params.DAMAGE_NAME_PHYSICAL, 50);
	action.AddEffectInfo(EET_Blindness, 2);
	action.SetSuppressHitSounds(true);
	action.SetHitAnimationPlayType(EAHA_ForceNo);
	theGame.damageMgr.ProcessAction(action);
	w.gmTestDelayProbe = false;
	cfg.SetVarValue('GMGameplayOptions', 'GMStaminaDelay', prev);
	action.GetEffectTypes(types);
	GMTestReport(w.HasAlternateQuen() && !action.DealsAnyDamage() && types.Contains(EET_Blindness),
		"SKL-11 (fx C1-2) in play: a hit the held alternate Quen fully absorbs keeps its blindness: in the hit " + types.Contains(EET_Blindness) + ", Geralt blinded " + w.HasBuff(EET_Blindness) + ", deals damage " + action.DealsAnyDamage() + ", alternate Quen " + w.HasAlternateQuen());
	GMTestReport(w.gmTestFixedDelays == 1 && AbsF(w.gmTestFixedDelay + 2 - read) < 0.001,
		"SKL-11 (fx A1-1) in play: the absorb drain's delay " + w.gmTestFixedDelay + " + option 2, expected " + read + " (" + w.gmTestFixedDelays + " drain)");
	delete action;
	w.RemoveAllBuffsOfType(EET_Blindness);
}

// C1-4: the basic Quen's HUD percentage rounds to the nearest: 0.4 of 100 shows 0 (5.x: 1), 0.6 shows 1.
function GMTest_sklfix_hud()
{
	var q : W3QuenEntity;
	var eff : W3Effect_BasicQuen;
	var a, b : int;

	q = (W3QuenEntity)theGame.CreateEntity(GetWitcherPlayer().GMTestFixQuenTemplate(), thePlayer.GetWorldPosition(), thePlayer.GetWorldRotation());
	eff = new W3Effect_BasicQuen in thePlayer;
	if(!q || !eff)
	{
		GMTestReport(false, "SKL-11 Quen HUD (fx C1-4): no Quen entity or effect");
		return;
	}
	eff.GMTestSetQuenEntity(q);
	q.GMTestSetShieldHealth(0.4, 100);
	a = eff.GetStacks();
	q.GMTestSetShieldHealth(0.6, 100);
	b = eff.GetStacks();
	GMTestReport(a == 0 && b == 1, "SKL-11 Quen HUD (fx C1-4): the basic shield at 0.4% shows " + a + "%, at 0.6% " + b + "% (legacy 0 and 1; 5.x 1 and 1)");
	q.Destroy();
	delete eff;
}

// C2-1: Rend's charge snaps to full above 99% of the charge time (legacy), not above 95% (5.x).
function GMTest_sklfix_rend()
{
	var a, b, c : float;

	a = GMRendChargeRatio(0.97);
	b = GMRendChargeRatio(0.99);
	c = GMRendChargeRatio(0.995);
	GMTestReport(a == 0.97 && b == 0.99 && c == 1, "SKL-04 Rend (fx C2-1): a charge of 0.97 takes " + a + ", 0.99 " + b + ", 0.995 " + c + " (legacy 0.97, 0.99, 1; 5.x 1 from 0.95)");
}

// C2-3: Undying's immortality ends when a save loads (the load's rule run on the effect added by script);
// its removal starts the cooldown, removed afterwards.
function GMTest_sklfix_undying()
{
	var w : W3PlayerWitcher;
	var focus, vitality : float;
	var during, after : bool;

	w = GetWitcherPlayer();
	focus = w.GetStat(BCS_Focus);
	vitality = w.GetStat(BCS_Vitality);
	w.AddEffectDefault(EET_GMUndyingImmortal, NULL, "gmtest");
	during = w.HasBuff(EET_GMUndyingImmortal);
	w.GMUndyingOnLoad();
	after = w.HasBuff(EET_GMUndyingImmortal);
	GMTestReport(during && !after && !w.IsImmortal(), "SKL-07 Undying (fx C2-3): its immortality ends at a load: before " + during + ", after " + after + ", immortal " + w.IsImmortal() + ", cooldown started " + w.HasBuff(EET_GMUndyingCooldown));
	w.RemoveAllBuffsOfType(EET_GMUndyingImmortal);
	w.RemoveAllBuffsOfType(EET_GMUndyingCooldown);
	w.ForceSetStat(BCS_Vitality, vitality);
	if(focus > 0)
		w.GainStat(BCS_Focus, focus);
}

// A3-3: with Sustained Glyphs at level 2 (the tree in force, by a test override), a trap gets its +30%
// radius and Entanglement's trap does not (legacy: the glyphword's radius).
function GMTest_sklfix_entangle()
{
	var w : W3PlayerWitcher;
	var y : W3YrdenEntity;
	var normal, entangle : float;

	w = GetWitcherPlayer();
	y = (W3YrdenEntity)w.GMTestFixSign(ST_Yrden);
	if(!y)
	{
		GMTestReport(false, "SKL-10 (fx A3-3): no Yrden entity created");
		return;
	}
	w.gmTestSustainedOverride = true;
	y.gmIsEntanglement = false;
	normal = y.GMSustainedGlyphsRangeMult();
	y.gmIsEntanglement = true;
	entangle = y.GMSustainedGlyphsRangeMult();
	w.gmTestSustainedOverride = false;
	GMTestReport(normal > 1.29 && normal < 1.31 && entangle == 1, "SKL-10 (fx A3-3): Sustained Glyphs 2 scales a trap by " + normal + " and Entanglement's trap by " + entangle + " (legacy 1.3 and 1)");
	y.Destroy();
}

// --- real casts ---

// C1-1 in play: Focus's adrenaline from real casts of every sign, normal and alternate, in combat (a frozen
// hostile test dummy). Before each cast gmtest_sklfix_fpre() sets adrenaline 0 and stamina full; after it
// gmtest_sklfix_fpost("<sign>") checks adrenaline was earned. Focus (classic perk_11, new tree perk_37)
// must be equipped, Rage Management not.
@addField(W3PlayerWitcher)
var gmTestFocusBefore : float;

exec function gmtest_sklfix_fpre()
{
	var w : W3PlayerWitcher;

	w = GetWitcherPlayer();
	w.RemoveAllBuffsOfType(EET_GMQuenCooldown);
	w.ForceSetStat(BCS_Focus, 0);
	w.ForceSetStat(BCS_Stamina, w.GetStatMax(BCS_Stamina));
	w.gmTestFocusBefore = w.GetStat(BCS_Focus);
	LogChannel('GMTest', "INFO fx C1-1 before the cast: adrenaline " + w.gmTestFocusBefore + ", stamina " + w.GetStat(BCS_Stamina) + ", in combat " + w.IsInCombat() + ", Focus " + (w.CanUseSkill(S_Perk_11) || w.CanUseSkill(S_Perk_37)) + ", Rage Management " + w.GMHasRageManagement());
}

exec function gmtest_sklfix_fpost(label : string)
{
	var w : W3PlayerWitcher;
	var gain : float;

	w = GetWitcherPlayer();
	gain = w.GetStat(BCS_Focus) - w.gmTestFocusBefore;
	GMTestReport(gain > 0.05, "SKL-18 Focus (fx C1-1): a real " + label + " cast in combat earned " + gain + " adrenaline (stamina " + w.GetStat(BCS_Stamina) + ")");
}

// C2-1 in play: the last charge ratio Rend set below a full charge, while a real Rend charges to full
// (gmtest_stam02_press(true), about 3 s, gmtest_stam02_release(true)): above 0.95 (legacy snaps above
// 0.99; 5.x's snap leaves at most 0.95).
@addField(CR4Player)
var gmTestRendPrev : float;
@addField(CR4Player)
var gmTestRendSnapFrom : float;

@wrapMethod(CR4Player)
function SetSpecialAttackTimeRatio(f : float)
{
	if(f >= 1 && gmTestRendPrev > 0 && gmTestRendPrev < 1)
		gmTestRendSnapFrom = gmTestRendPrev;
	gmTestRendPrev = f;
	wrappedMethod(f);
}

exec function gmtest_sklfix_rend(phase : int)
{
	var p : CR4Player;

	p = thePlayer;
	if(phase == 0)
	{
		p.gmTestRendPrev = 0;
		p.gmTestRendSnapFrom = 0;
		LogChannel('GMTest', "INFO fx C2-1: Rend probe reset, Rend equipped " + p.CanUseSkill(S_Sword_s02));
		return;
	}
	GMTestReport(p.gmTestRendSnapFrom > 0.95 && p.gmTestRendSnapFrom <= 0.99, "SKL-04 Rend (fx C2-1): a real Rend reached a full charge from a charge of " + p.gmTestRendSnapFrom + " (legacy above 0.95, at most 0.99; 5.x at most 0.95)");
}

// A3-3 in play: after a real Magic Turret's hit with Entanglement (the hostile test dummy, the glyphword on
// the chest armor, Sustained Glyphs at level 2 or more): each Yrden entity's trigger scale and radius.
@addMethod(W3YrdenEntity)
function GMTestTriggerScale() : float
{
	var c : CComponent;
	var v : Vector;

	c = GetComponent("Slowdown");
	if(!c)
		return -1;
	v = c.GetLocalScale();
	return v.X;
}

exec function gmtest_sklfix_ent()
{
	var ents : array<CGameplayEntity>;
	var y : W3YrdenEntity;
	var i, n : int;

	FindGameplayEntitiesInRange(ents, thePlayer, 30, 100, , , , 'W3YrdenEntity');
	for(i = 0; i < ents.Size(); i += 1)
	{
		y = (W3YrdenEntity)ents[i];
		LogChannel('GMTest', "INFO fx A3-3: Yrden entity " + i + ": Entanglement " + y.gmIsEntanglement + ", alternate " + y.IsAlternateCast() + ", state " + y.GetCurrentStateName() + ", trigger scale " + y.GMTestTriggerScale() + ", radius " + y.GMTestRange());
		if(y.gmIsEntanglement)
		{
			n += 1;
			GMTestReport(AbsF(y.GMTestTriggerScale() - 2.5) < 0.01, "SKL-10 (fx A3-3): Entanglement's trap's trigger scale " + y.GMTestTriggerScale() + " with Sustained Glyphs at level " + (GetWitcherPlayer().GetSkillLevel(S_Magic_s10) + GetWitcherPlayer().GetSkillLevel(S_Magic_s42)) + " (legacy: the template's 2.5, as the turret's; a normal trap 3.25)");
		}
	}
	if(n == 0)
		GMTestReport(false, "SKL-10 (fx A3-3): no Entanglement trap (" + ents.Size() + " Yrden entities)");
}
