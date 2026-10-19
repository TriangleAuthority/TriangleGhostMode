// ENCH-10: Levity, Balance and Heft (Glyphwords 2, 3, 4) as legacy (changelist 985-986, 994-995,
// 1006-1007; legacy PlayerAbilityManager.GetGlyphword234Mod). From the worn chest armor (ENCH-01):
// Levity: physical actions (attacks, item use, parry, counter, dodge, roll, evade, sprint, jump; legacy's
// IsActionMelee) cost 20% less stamina, signs 20% more. Balance: signs 20% less, physical actions 20%
// more. Heft: light, strong and counter attacks cost 20% more and melee hits deal 20% more damage (a
// pool term, damage/pool.ws), special attacks (Whirl, Rend) excluded. The class change of vanilla's
// glyphwords is gone (ARM-02). See docs/features/ench.md.

// The share added to the action's cost (negative: cheaper); legacy's GetGlyphword234Mod.
function GMGetGlyphword234Mod(action : EStaminaActionType, optional isSign : bool) : float
{
	var min, max : SAbilityAttributeValue;
	var modifier : float;
	var w : W3PlayerWitcher;

	w = GetWitcherPlayer();
	if(!w)
		return 0;
	if(w.HasGlyphwordActive('Glyphword 2 _Stats'))
	{
		theGame.GetDefinitionsManager().GetAbilityAttributeValue('Glyphword 2 _Stats', 'glyphword2_mod', min, max);
		modifier = CalculateAttributeValue(min);
		if(action == ESAT_Ability && isSign)
			return modifier;
		else if(GMIsMeleeStaminaAction(action))
			return -modifier;
	}
	else if(w.HasGlyphwordActive('Glyphword 3 _Stats'))
	{
		theGame.GetDefinitionsManager().GetAbilityAttributeValue('Glyphword 3 _Stats', 'glyphword3_mod', min, max);
		modifier = CalculateAttributeValue(min);
		if(action == ESAT_Ability && isSign)
			return -modifier;
		else if(GMIsMeleeStaminaAction(action))
			return modifier;
	}
	else if(w.HasGlyphwordActive('Glyphword 4 _Stats'))
	{
		theGame.GetDefinitionsManager().GetAbilityAttributeValue('Glyphword 4 _Stats', 'glyphword4_mod', min, max);
		modifier = CalculateAttributeValue(min);
		if(action == ESAT_LightAttack || action == ESAT_HeavyAttack || action == ESAT_Counterattack)
			return modifier;
	}
	return 0;
}

// Heft's damage bonus for a melee hit by Geralt (0 without Heft or in a special attack).
function GMHeftDamageBonus(action : W3DamageAction) : float
{
	var min, max : SAbilityAttributeValue;
	var w : W3PlayerWitcher;

	w = (W3PlayerWitcher)action.attacker;
	if(!w || !action.IsActionMelee() || !w.HasGlyphwordActive('Glyphword 4 _Stats') || w.IsDoingSpecialAttack(true) || w.IsDoingSpecialAttack(false))
		return 0;
	theGame.GetDefinitionsManager().GetAbilityAttributeValue('Glyphword 4 _Stats', 'glyphword4_mod', min, max);
	return CalculateAttributeValue(min);
}

// Sign and physical action costs (legacy's cost sites in GetStaminaActionCost).
@wrapMethod(W3AbilityManager)
function GetStaminaActionCost(action : EStaminaActionType, out cost : float, out delay : float, optional fixedCost : float, optional fixedDelay : float, optional abilityName : name, optional dt : float, optional costMult : float)
{
	wrappedMethod(action, cost, delay, fixedCost, fixedDelay, abilityName, dt, costMult);
	if(owner == GetWitcherPlayer() && cost > 0)
	{
		if(action == ESAT_Ability && IsSkillSign(SkillNameToEnum(abilityName)))
			cost = ClampF(cost * (1 + GMGetGlyphword234Mod(ESAT_Ability, true)), 0, 100);
		else if(GMIsMeleeStaminaAction(action))
			cost = ClampF(cost * (1 + GMGetGlyphword234Mod(action)), 0, 100);
	}
}

// Sign costs read per skill (legacy's GetSkillStaminaUseCost), per cast and per second.
@wrapMethod(W3PlayerAbilityManager)
function GetSkillStaminaUseCost(skill : ESkill, optional isPerSec : bool) : float
{
	var cost : float;

	cost = wrappedMethod(skill, isPerSec);
	if(owner == GetWitcherPlayer() && IsSkillSign(skill))
		cost = ClampF(cost * (1 + GMGetGlyphword234Mod(ESAT_Ability, true)), 0, 100);
	return cost;
}
