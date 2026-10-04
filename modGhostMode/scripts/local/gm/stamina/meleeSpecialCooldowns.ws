// STAM-02: Whirl and Rend cooldowns. After Whirl ends, Whirl cannot be used again for a while;
// the same for Rend (each has its own cooldown). Duration: option "Melee special cooldown"
// (default 7.5 s; 0 turns the cooldowns off). Covers both trees' Whirl (S_Sword_s01 classic,
// S_Sword_s35 new), since both go through the same input event and attack state.
// See docs/features/stam.md.

@addMethod(W3GameParams)
function GMGetMeleeSpecialCooldownDuration() : float
{
	return GMGetOptionFloat('GMGameplayOptions', 'GMMeleeSpecialCooldown');
}

// ---- effects ----

abstract class W3GMEffect_MeleeSpecialCooldown extends CBaseGameplayEffect
{
	default isNegative = true;
	default dontAddAbilityOnTarget = true;

	protected function CalculateDuration(optional setInitialDuration : bool)
	{
		if(!isOnPlayer)
			return;
		duration = theGame.params.GMGetMeleeSpecialCooldownDuration();
		if(setInitialDuration)
			initialDuration = duration;
	}
}

class W3GMEffect_WhirlCooldown extends W3GMEffect_MeleeSpecialCooldown
{
	default effectType = EET_GMWhirlCooldown;
}

class W3GMEffect_RendCooldown extends W3GMEffect_MeleeSpecialCooldown
{
	default effectType = EET_GMRendCooldown;
}

function GMIsMeleeSpecialCooldown(effect : EEffectType) : bool
{
	return effect == EET_GMWhirlCooldown || effect == EET_GMRendCooldown;
}

// A duration of 0 (the option set to 0) turns the cooldowns off.
function GMAddMeleeSpecialCooldown(effect : EEffectType)
{
	if(theGame.params.GMGetMeleeSpecialCooldownDuration() <= 0)
		return;
	thePlayer.AddEffectDefault(effect, NULL, "melee_special");
}

// ---- applying: when the special attack ends ----

// The attack ends in the state's entry functions PerformSpecialAttackLight/Heavy(false), but a
// wrapper on an entry function never runs (it compiles), so wrap the event that calls them.
// The conditions are those of the vanilla branch that ends the attack.
// True when this call of OnPerformSpecialAttack ends the attack (read before the call).
// Also used by STAM-09's Rend minimum cost (whirlRendStamina.ws).
@addMethod(W3PlayerWitcherStateCombatSword)
function GMIsSpecialAttackEnding(isLightAttack : bool, enableAttack : bool) : bool
{
	var ending : bool;

	ending = !enableAttack
		&& parent.GetBehaviorVariable('isPerformingSpecialAttack') != 0.f
		&& parent.GetBehaviorVariable('combatActionType') == (int)CAT_SpecialAttack;
	if(isLightAttack)
		return ending && parent.GetBehaviorVariable('playerAttackType') == 0;
	return ending && parent.IsInCombatAction() && parent.GetBehaviorVariable('playerAttackType') == 1;
}

// STAM-02: the cooldown when Whirl or Rend ends.
@wrapMethod(W3PlayerWitcherStateCombatSword)
function OnPerformSpecialAttack(isLightAttack : bool, enableAttack : bool)
{
	var ending : bool;
	var ret : bool;

	ending = GMIsSpecialAttackEnding(isLightAttack, enableAttack);
	ret = wrappedMethod(isLightAttack, enableAttack);
	if(ending)
	{
		if(isLightAttack)
			GMAddMeleeSpecialCooldown(EET_GMWhirlCooldown);
		else
			GMAddMeleeSpecialCooldown(EET_GMRendCooldown);
	}
	return ret;
}

// ---- blocking: refuse the press while the cooldown runs (releases still pass) ----

@wrapMethod(CPlayerInput)
function OnCbtSpecialAttackLight(action : SInputAction)
{
	if(IsPressed(action) && thePlayer.HasBuff(EET_GMWhirlCooldown))
	{
		thePlayer.SoundEvent("gui_no_adrenaline");
		return false;
	}
	return wrappedMethod(action);
}

@wrapMethod(CPlayerInput)
function OnCbtSpecialAttackHeavy(action : SInputAction)
{
	if(IsPressed(action) && thePlayer.HasBuff(EET_GMRendCooldown))
	{
		thePlayer.SoundEvent("gui_no_adrenaline");
		return false;
	}
	return wrappedMethod(action);
}
