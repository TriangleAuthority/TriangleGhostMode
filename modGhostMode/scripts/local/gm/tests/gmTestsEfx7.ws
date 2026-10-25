// EFX-10 and EFX-11 tests. EFX-10: a real sign cast (the cast input, as a key press) caught by a
// scripted spider web (EET_Tangled added to Geralt): gmtest_efx10(sign, delay) presses the cast and
// adds the web after delay seconds; gmtest_efx10_web() adds it now (during a held channel started with
// autocast(sign, true)); each reports 0.3 s later whether the sign was aborted. EFX-11: GMTest_efx11, in
// the regression: the five Places of Power buffs, +20% sign intensity for 30 minutes.

@addField(W3PlayerWitcher)
var gmTestEfx10Entity : W3SignEntity;
@addField(W3PlayerWitcher)
var gmTestEfx10State : name;
@addField(W3PlayerWitcher)
var gmTestEfx10Aborts : int;
@addField(W3PlayerWitcher)
var gmTestEfx10Armed : bool;
@addField(W3PlayerWitcher)
var gmTestEfx10Phase : int;
@addField(W3PlayerWitcher)
var gmTestEfx10Release : bool;
@addField(W3PlayerWitcher)
var gmTestEfx10HadEntity : bool;
@addField(W3PlayerWitcher)
var gmTestEfx10Sign : ESignType;

@wrapMethod(CR4Player)
function AbortSign()
{
	var w : W3PlayerWitcher;
	var sign : W3SignEntity;

	w = GetWitcherPlayer();
	if(w && w.gmTestEfx10Armed)
	{
		w.gmTestEfx10Aborts += 1;
		sign = (W3SignEntity)w.GetCurrentSignEntity();
		if(sign)
			LogChannel('GMTest', "INFO EFX-10 AbortSign: the sign entity in state " + sign.GetCurrentStateName());
		else
			LogChannel('GMTest', "INFO EFX-10 AbortSign: no current sign entity");
	}
	wrappedMethod();
}

function GMTestEfx10Web()
{
	var w : W3PlayerWitcher;
	var result : EEffectInteract;
	var params : SCustomEffectParams;

	w = GetWitcherPlayer();
	w.gmTestEfx10Entity = (W3SignEntity)w.GetCurrentSignEntity();
	w.gmTestEfx10HadEntity = w.gmTestEfx10Entity;
	w.gmTestEfx10Sign = w.GetCurrentlyCastSign();
	if(w.gmTestEfx10Entity)
		w.gmTestEfx10State = w.gmTestEfx10Entity.GetCurrentStateName();
	else
		w.gmTestEfx10State = '';
	w.gmTestEfx10Aborts = 0;
	w.gmTestEfx10Armed = true;
	LogChannel('GMTest', "INFO EFX-10 web on Geralt: casting " + w.IsCastingSign() + ", sign " + w.GetCurrentlyCastSign() + ", entity in state " + w.gmTestEfx10State);
	// As an arachas's web projectile adds it (W3AdvancedProjectile, 5.x): its creator, 1 s; the
	// creator is the test dummy (gmtest_dummy("arachas")).
	params.effectType = EET_Tangled;
	params.creator = GMTestDummy();
	params.sourceName = "gmtest";
	params.duration = 1.f;
	result = w.AddEffectCustom(params);
	LogChannel('GMTest', "INFO EFX-10 web added: " + result + ", on Geralt " + w.HasBuff(EET_Tangled) + ", AbortSign calls " + w.gmTestEfx10Aborts);
	w.gmTestEfx10Phase = 2;
	w.RemoveTimer('GMTestEfx10Timer');
	w.AddTimer('GMTestEfx10Timer', 0.3, false);
}

@addMethod(W3PlayerWitcher)
timer function GMTestEfx10Timer(dt : float, id : int)
{
	var stateName : name;
	var gone : bool;

	if(gmTestEfx10Phase == 1)
	{
		GMTestEfx10Web();
		return;
	}
	gone = !gmTestEfx10Entity;
	if(!gone)
		stateName = gmTestEfx10Entity.GetCurrentStateName();
	LogChannel('GMTest', "INFO EFX-10 0.3 s later: web " + HasBuff(EET_Tangled) + ", casting " + IsCastingSign() + ", sign " + GetCurrentlyCastSign() + ", the entity destroyed " + gone + (gone ? "" : ", state " + stateName));
	if(gmTestEfx10Sign == ST_Quen)	// W3QuenEntity.OnSignAborted is empty in its cast (1.32, legacy and 5.x): the shield goes up
		GMTestReport(gmTestEfx10HadEntity && gmTestEfx10Aborts == 1 && !gone,
			"EFX-10 a spider web during a Quen cast calls AbortSign (" + gmTestEfx10Aborts + "); Quen's entity ignores it while it casts (its OnSignAborted is empty) and its shield goes up (state " + stateName + ")");
	else
	GMTestReport(gmTestEfx10HadEntity && gmTestEfx10Aborts == 1 && (gone || stateName == 'Finished'),
		"EFX-10 a spider web aborts the sign being cast (" + gmTestEfx10Sign + ", in state " + gmTestEfx10State + "): AbortSign called " + gmTestEfx10Aborts + " time(s), the sign entity destroyed " + gone + (gone ? "" : " (state " + stateName + ")"));
	gmTestEfx10Armed = false;
	if(gmTestEfx10Release)
		GMTestCastInput(false);
	gmTestEfx10Release = false;
	RemoveAllBuffsOfType(EET_Tangled);
}

exec function gmtest_efx10(sign : ESignType, delay : float)
{
	var w : W3PlayerWitcher;

	w = GetWitcherPlayer();
	thePlayer.RemoveAllBuffsOfType(EET_Tangled);
	w.SetEquippedSign(sign);
	w.GainStat(BCS_Stamina, 1000);
	GMTestCastInput(true);
	w.gmTestEfx10Release = true;
	w.gmTestEfx10Phase = 1;
	w.RemoveTimer('GMTestEfx10Timer');
	w.AddTimer('GMTestEfx10Timer', delay, false);
	LogChannel('GMTest', "INFO EFX-10 cast pressed: " + sign + ", casting " + w.IsCastingSign() + "; the web in " + NoTrailZeros(delay) + " s");
}

exec function gmtest_efx10_web()
{
	var w : W3PlayerWitcher;

	w = GetWitcherPlayer();
	w.gmTestEfx10Release = false;
	GMTestEfx10Web();
}

// ---- EFX-11 ---------------------------------------------------------------------------------------------

function GMTest_efx11()
{
	var dm : CDefinitionsManagerAccessor;
	var abilities : array<name>;
	var stats : array<name>;
	var i : int;
	var min, max : SAbilityAttributeValue;
	var power, duration : float;
	var types : array<EEffectType>;
	var buff : CBaseGameplayEffect;
	var kept : array<SGMTestEfxSavedBuff>;

	dm = theGame.GetDefinitionsManager();
	abilities.PushBack('ShrineAardEffect'); stats.PushBack('spell_power_aard');
	abilities.PushBack('ShrineAxiiEffect'); stats.PushBack('spell_power_axii');
	abilities.PushBack('ShrineIgniEffect'); stats.PushBack('spell_power_igni');
	abilities.PushBack('ShrineQuenEffect'); stats.PushBack('spell_power_quen');
	abilities.PushBack('ShrineYrdenEffect'); stats.PushBack('spell_power_yrden');
	types.PushBack(EET_ShrineAard); types.PushBack(EET_ShrineAxii); types.PushBack(EET_ShrineIgni); types.PushBack(EET_ShrineQuen); types.PushBack(EET_ShrineYrden);
	kept = GMTestEfxSaveBuffs(types);	// Geralt's own buffs are put back after the check (EFX audit F3)
	for(i = 0; i < abilities.Size(); i += 1)
	{
		thePlayer.RemoveAllBuffsOfType(types[i]);
		thePlayer.AddEffectDefault(types[i], NULL, "gmtest");
		buff = thePlayer.GetBuff(types[i]);
		if(buff)
		{
			GMTestReport(buff.GetAbilityName() == abilities[i] && AbsF(buff.GetDurationLeft() - 1800) < 1,
				"EFX-11 " + types[i] + " on Geralt: ability " + buff.GetAbilityName() + ", " + NoTrailZeros(RoundTo(buff.GetDurationLeft(), 1)) + " s left (expected " + abilities[i] + ", 1800 s)");
			thePlayer.RemoveAllBuffsOfType(types[i]);
		}
		else
			GMTestReport(false, "EFX-11 " + types[i] + " could not be added to Geralt");
		dm.GetAbilityAttributeValue(abilities[i], stats[i], min, max);
		power = min.valueMultiplicative;
		dm.GetAbilityAttributeValue(abilities[i], 'duration', min, max);
		duration = CalculateAttributeValue(min);
		GMTestReport(AbsF(power - 0.2) < 0.0001 && AbsF(duration - 1800) < 0.01,
			"EFX-11 " + abilities[i] + ": +" + NoTrailZeros(power * 100) + "% " + stats[i] + " for " + NoTrailZeros(duration) + " s (expected +20% for 1800 s, 30 min)");
	}
	GMTestEfxRestoreBuffs(types, kept);
}

exec function gmtest_efx11()
{
	GMTest_efx11();
}
