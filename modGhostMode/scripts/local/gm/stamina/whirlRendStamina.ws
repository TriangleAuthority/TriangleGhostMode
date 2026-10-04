// STAM-09: Whirl and Rend stamina costs. Whirl (the classic tree's sword_s1 or the new tree's
// sword_s35, whichever the player has; see GMWhirlSkill) drains
// stamina and adrenaline together and stops when stamina cannot pay for it (5.x: stamina, then
// adrenaline alone once stamina is empty); adrenaline gain is paused while it spins and for 1 s
// after. Starting Whirl or Rend needs half a second's stamina (5.x: any stamina or adrenaline
// for Whirl, a full second's for Rend), with the low-stamina warning. Costs and the reduction per
// level are XML (gm_skills.xml). See docs/features/stam.md.

// ---- adrenaline gain pause ----

@addField(CActor)
var gmFocusGainPausedUntil : float;

@addMethod(CActor)
function GMPauseFocusGain(duration : float)
{
	gmFocusGainPausedUntil = theGame.GetEngineTimeAsSeconds() + duration;
}

@wrapMethod(W3PlayerAbilityManager)
function GainStat(stat : EBaseCharacterStats, amount : float)
{
	if(stat == BCS_Focus && owner.gmFocusGainPausedUntil > theGame.GetEngineTimeAsSeconds())
		return;
	wrappedMethod(stat, amount);
}

// ---- Whirl ----

// The Whirl the player has: the classic tree's (S_Sword_s01) or the new tree's (S_Sword_s35).
// Vanilla checks the classic one first (W3PlayerWitcher.SpecialAttackLightSustainCost).
@addMethod(W3PlayerWitcher)
function GMWhirlSkill() : ESkill
{
	if(CanUseSkill(S_Sword_s01))
		return S_Sword_s01;
	return S_Sword_s35;
}

// Stamina cost of dt seconds of Whirl: its per-second cost, 15% less per level above 1.
@addMethod(W3PlayerWitcher)
function GMGetWhirlStaminaCost(dt : float) : float
{
	var cost : float;

	cost = GetStaminaActionCost(ESAT_Ability, GetSkillAbilityName(GMWhirlSkill()), dt);
	cost *= GMWhirlCostFactor();
	return cost;
}

@addMethod(W3PlayerWitcher)
function GMWhirlCostFactor() : float
{
	var skill : ESkill;

	skill = GMWhirlSkill();
	return 1 - CalculateAttributeValue(GetSkillAttributeValue(skill, 'stamina_cost_reduction_after_1', false, false)) * Max(GetSkillLevel(skill) - 1, 0);
}

@addMethod(W3PlayerWitcher)
function GMHasResourcesForWhirl(dt : float) : bool
{
	return GetStat(BCS_Stamina) >= GMGetWhirlStaminaCost(dt);
}

// Pays dt seconds of Whirl: the stamina cost, and adrenaline in proportion to the base cost
// (computed from the skill alone, so stamina cost modifiers do not change it).
@addMethod(W3PlayerWitcher)
function GMWhirlDrainResources(dt : float)
{
	var cost, delay : float;
	var skill : ESkill;

	skill = GMWhirlSkill();
	delay = GetStaminaActionDelay(ESAT_Ability, GetSkillAbilityName(skill), dt);
	DrainStamina(ESAT_FixedValue, GMGetWhirlStaminaCost(dt), GMFixedDrainDelay(delay), GetSkillAbilityName(skill));
	cost = CalculateAttributeValue(GetSkillAttributeValue(skill, 'stamina_cost_per_sec', false, false)) * GMWhirlCostFactor() * dt;
	DrainFocus(cost / GetStatMax(BCS_Stamina));
}

// Whirl's per-tick cost: Ghost Mode's body (legacy's model; 5.x body replaced).
@replaceMethod(W3PlayerWitcher)
function SpecialAttackLightSustainCost(dt : float, id : int)
{
	if(abilityManager && abilityManager.IsInitialized() && IsAlive() && GMHasResourcesForWhirl(dt))
	{
		PauseStaminaRegen('WhirlSkill');
		GMPauseFocusGain(1);
		GMWhirlDrainResources(dt);
	}
	else
	{
		OnPerformSpecialAttack(true, false);
	}
}

// Starting Whirl: 5.x body, the resource check changed.
@replaceMethod(W3PlayerWitcher)
function IsSpecialLightAttackInputHeld ( time : float, id : int )
{
	var hasResource : bool;

	if ( GetCurrentStateName() == 'CombatSteel' || GetCurrentStateName() == 'CombatSilver' )
	{
		if ( GetBIsCombatActionAllowed() && inputHandler.IsActionAllowed(EIAB_SwordAttack))
		{
			hasResource = GMHasResourcesForWhirl(0.5f);	//modSigns: half a second's stamina (5.x: any stamina, or adrenaline)

			if(hasResource)
			{
				SetupCombatAction( EBAT_SpecialAttack_Light, BS_Pressed );
				RemoveTimer('IsSpecialLightAttackInputHeld');
			}
			else if(!playedSpecialAttackMissingResourceSound)
			{
				SetShowToLowStaminaIndication(GMGetWhirlStaminaCost(0.5f));	//modSigns: was IndicateTooLowAdrenaline()
				SoundEvent("gui_no_stamina");									//modSigns
				playedSpecialAttackMissingResourceSound = true;
			}
		}
	}
	else
	{
		RemoveTimer('IsSpecialLightAttackInputHeld');
	}
}

// ---- Rend ----

// STAM-09: a Rend released early still costs at least half a second's stamina: when it ends with
// less charged than that, the difference is drained, with Rend's delay (legacy:
// W3PlayerWitcherStateCombatSword.PerformSpecialAttackHeavy; 5.x has no such rule).
@wrapMethod(W3PlayerWitcherStateCombatSword)
function OnPerformSpecialAttack(isLightAttack : bool, enableAttack : bool)
{
	var ending : bool;
	var ratio, minCost, maxStamina, delay : float;
	var ret : bool;

	ending = !isLightAttack && GMIsSpecialAttackEnding(isLightAttack, enableAttack);
	ratio = parent.GetSpecialAttackTimeRatio();
	ret = wrappedMethod(isLightAttack, enableAttack);
	if(ending)
	{
		minCost = parent.GetStaminaActionCost(ESAT_Ability, parent.GetSkillAbilityName(S_Sword_s02), 0.5f);
		maxStamina = parent.GetStatMax(BCS_Stamina);
		if(ratio < minCost / maxStamina)
		{
			delay = parent.GetStaminaActionDelay(ESAT_Ability, parent.GetSkillAbilityName(S_Sword_s02));
			parent.DrainStamina(ESAT_FixedValue, minCost - ratio * maxStamina, GMFixedDrainDelay(delay));
		}
	}
	return ret;
}

// Starting Rend: 5.x body, the stamina check changed.
@replaceMethod(W3PlayerWitcher)
function IsSpecialHeavyAttackInputHeld ( time : float, id : int )
{
	var cost : float;

	if ( GetCurrentStateName() == 'CombatSteel' || GetCurrentStateName() == 'CombatSilver' )
	{
		cost = GetStaminaActionCost(ESAT_Ability, GetSkillAbilityName(S_Sword_s02), 0.5f);	//modSigns: half a second's cost (5.x: a full second's, without cost modifiers)

		if( GetBIsCombatActionAllowed() && inputHandler.IsActionAllowed(EIAB_SwordAttack))
		{
			if(GetStat(BCS_Stamina) >= cost)
			{
				SetupCombatAction( EBAT_SpecialAttack_Heavy, BS_Pressed );
				RemoveTimer('IsSpecialHeavyAttackInputHeld');
				theGame.HapticStart( "haptic_rend_stop" );
			}
			else if(!playedSpecialAttackMissingResourceSound)
			{
				SetShowToLowStaminaIndication(cost);	//modSigns: was IndicateTooLowAdrenaline()
				SoundEvent("gui_no_stamina");			//modSigns
				playedSpecialAttackMissingResourceSound = true;
				theGame.HapticStart( "haptic_rend_stop" );
			}
		}
	}
	else
	{
		RemoveTimer('IsSpecialHeavyAttackInputHeld');
		theGame.HapticStart( "haptic_rend_stop" );
	}
}
