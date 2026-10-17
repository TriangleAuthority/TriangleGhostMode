// STAM-01: sign cooldowns. After a sign is cast it cannot be cast again for a while:
// 5 s after a normal cast, 7.5 s after an alternate cast. Each sign has its own cooldown,
// implemented as a negative effect on the player.
// See docs/features/stam.md.

// ---- durations: options "Sign cooldown" and "Alternate Sign cooldown" (OPT-01) ----

@addMethod(W3GameParams)
function GMGetSignCooldownDuration() : float
{
	return GMGetOptionFloat('GMGameplayOptions', 'GMSignCooldown');
}

@addMethod(W3GameParams)
function GMGetAltSignCooldownDuration() : float
{
	return GMGetOptionFloat('GMGameplayOptions', 'GMAltSignCooldown');
}

// ---- effects ----

abstract class W3GMEffect_SignCooldown extends CBaseGameplayEffect
{
	default isNegative = true;
	default dontAddAbilityOnTarget = true;

	protected function CalculateDuration(optional setInitialDuration : bool)
	{
		if(!isOnPlayer)
			return;
		if(sourceName == "alt_cast")
			duration = theGame.params.GMGetAltSignCooldownDuration();
		else
			duration = theGame.params.GMGetSignCooldownDuration();
		if(setInitialDuration)
			initialDuration = duration;
	}
}

class W3GMEffect_AardCooldown extends W3GMEffect_SignCooldown
{
	default effectType = EET_GMAardCooldown;
}

class W3GMEffect_AxiiCooldown extends W3GMEffect_SignCooldown
{
	default effectType = EET_GMAxiiCooldown;
}

class W3GMEffect_IgniCooldown extends W3GMEffect_SignCooldown
{
	default effectType = EET_GMIgniCooldown;
}

class W3GMEffect_QuenCooldown extends W3GMEffect_SignCooldown
{
	default effectType = EET_GMQuenCooldown;
}

class W3GMEffect_YrdenCooldown extends W3GMEffect_SignCooldown
{
	default effectType = EET_GMYrdenCooldown;
}

// ---- helpers ----

function GMSignCooldownType(signType : ESignType) : EEffectType
{
	switch(signType)
	{
		case ST_Aard :	return EET_GMAardCooldown;
		case ST_Axii :	return EET_GMAxiiCooldown;
		case ST_Igni :	return EET_GMIgniCooldown;
		case ST_Quen :	return EET_GMQuenCooldown;
		case ST_Yrden :	return EET_GMYrdenCooldown;
	}
	return EET_Undefined;
}

function GMIsSignCooldown(effect : EEffectType) : bool
{
	return effect == EET_GMAardCooldown || effect == EET_GMAxiiCooldown || effect == EET_GMIgniCooldown
		|| effect == EET_GMQuenCooldown || effect == EET_GMYrdenCooldown;
}

function GMIsSignOnCooldown(signType : ESignType) : bool
{
	var effect : EEffectType;

	effect = GMSignCooldownType(signType);
	return effect != EET_Undefined && thePlayer.HasBuff(effect);
}

// alt: alternate cast (longer cooldown). Only the player gets cooldowns. A duration of 0
// (the option set to 0) turns the cooldown off.
function GMAddSignCooldown(signType : ESignType, alt : bool)
{
	var effect : EEffectType;
	var duration : float;

	effect = GMSignCooldownType(signType);
	if(effect == EET_Undefined)
		return;
	if(alt)
		duration = theGame.params.GMGetAltSignCooldownDuration();
	else
		duration = theGame.params.GMGetSignCooldownDuration();
	if(duration <= 0)
		return;
	if(alt)
		thePlayer.AddEffectDefault(effect, NULL, "alt_cast");
	else
		thePlayer.AddEffectDefault(effect, NULL, "normal_cast");
}

// ---- applying cooldowns ----

// Normal casts: every sign pays its stamina here, on the player's normal casts only (free casts,
// e.g. Quen from the Bear set or Yrden not cast by the player, skip it).
@wrapMethod(W3SignEntity)
function ManagePlayerStamina()
{
	wrappedMethod();

	if(owner.GetActor() == thePlayer && !IsAlternateCast())
	{
		GMAddSignCooldown(GetSignType(), false);
	}
}

// Alternate casts.
@wrapMethod(W3AardEntityStateAardCircleCast)
function OnThrowing()
{
	var ret : bool;

	ret = wrappedMethod();
	if(caster.IsPlayer())
		GMAddSignCooldown(ST_Aard, true);
	return ret;
}

@wrapMethod(W3AxiiEntityStateAxiiChanneled)
function OnEnded(optional isEnd : bool)
{
	var ret : bool;

	if(caster.IsPlayer())
		GMAddSignCooldown(ST_Axii, true);
	ret = wrappedMethod(isEnd);
	return ret;
}

// Igni's channel ends through OnEnded when released, but through OnSignAborted when stamina
// runs out (W3PlayerAbilityManager.DrainStamina aborts the current sign at 0 stamina), which a
// flame stream usually does. Catch the state's exit instead, as legacy Ghost Mode did.
// IgniChanneled has no OnLeaveState of its own, so wrap the base Channeling state's.
@wrapMethod(W3SignEntityStateChanneling)
function OnLeaveState(nextStateName : name)
{
	if((W3IgniEntity)parent && caster.IsPlayer())
		GMAddSignCooldown(ST_Igni, true);
	wrappedMethod(nextStateName);
}

// Life Leech's free Quen starts no cooldown (MUT-12; legacy skipped it for every alternate Quen while
// Life Leech or its cooldown was on Geralt).
@wrapMethod(W3QuenEntityStateQuenChanneled)
function OnLeaveState(nextStateName : name)
{
	var ret : bool;

	if(caster.IsPlayer() && !parent.gmFreeCast)
		GMAddSignCooldown(ST_Quen, true);
	ret = wrappedMethod(nextStateName);
	return ret;
}

@wrapMethod(W3YrdenEntityStateYrdenShock)
function OnEnterState(prevStateName : name)
{
	var ret : bool;

	ret = wrappedMethod(prevStateName);
	if(caster.IsPlayer())
		GMAddSignCooldown(ST_Yrden, true);
	return ret;
}

// ---- blocking casts ----

@wrapMethod(CPlayerInput)
function OnCastSign(action : SInputAction)
{
	if(IsPressed(action) && GMIsSignOnCooldown(thePlayer.GetEquippedSign()))
	{
		thePlayer.SoundEvent("gui_no_adrenaline");
		return false;
	}
	return wrappedMethod(action);
}

@wrapMethod(CPlayerInput)
function AltCastSign(signType : ESignType)
{
	if(GMIsSignOnCooldown(signType))
	{
		thePlayer.SoundEvent("gui_no_adrenaline");
		return;
	}
	wrappedMethod(signType);
}

// The exception from buff immunities is in gmEffectRegistration.ws (IsImmuneToBuff).
