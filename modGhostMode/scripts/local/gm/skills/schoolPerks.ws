// SKL-18: the school perks, legacy's in both trees (D49; classic perk_5, perk_6, perk_7, the new tree's
// perk_23, perk_24, perk_25), per armor piece of their class (5.x's piece count adds the ability once per
// piece; the armor classes themselves are ARM's):
// - Cat School: +5% crit chance and +20% crit damage per light piece (XML only);
// - Griffin School: +5% sign intensity and -5% sign stamina cost per medium piece (the cost below);
// - Bear School: +7.5% maximum Vitality and +0.025 adrenaline per melee hit per heavy piece (the gain
//   below).
// 5.x's values (fast-attack crit chance and attack power, stamina regeneration, strong-attack attack
// power) are gone (gm_skill_trees.xml, gm_skills.xml).
// See docs/features/skl.md.

// Griffin School's share off sign costs: perk_6_stamina_cost_reduction of the pieces' abilities.
@addMethod(W3PlayerWitcher)
function GMGriffinSignCostCut() : float
{
	var abl : SAbilityAttributeValue;

	if(!CanUseSkill(S_Perk_06) && !CanUseSkill(S_Perk_24))
		return 0;
	abl = GetAttributeValue('perk_6_stamina_cost_reduction');
	return ClampF(abl.valueMultiplicative, 0, 1);
}

@wrapMethod(W3AbilityManager)
function GetStaminaActionCost(action : EStaminaActionType, out cost : float, out delay : float, optional fixedCost : float, optional fixedDelay : float, optional abilityName : name, optional dt : float, optional costMult : float)
{
	wrappedMethod(action, cost, delay, fixedCost, fixedDelay, abilityName, dt, costMult);
	if(owner == GetWitcherPlayer() && action == ESAT_Ability && IsSkillSign(SkillNameToEnum(abilityName)))
		cost *= 1 - GetWitcherPlayer().GMGriffinSignCostCut();
}

@wrapMethod(W3PlayerAbilityManager)
function GetSkillStaminaUseCost(skill : ESkill, optional isPerSec : bool) : float
{
	var cost : float;

	cost = wrappedMethod(skill, isPerSec);
	if(owner == GetWitcherPlayer() && IsSkillSign(skill))
		cost *= 1 - GetWitcherPlayer().GMGriffinSignCostCut();
	return cost;
}

// Bear School: extra adrenaline for a melee hit on a hostile that earns adrenaline, not with fists
// (legacy adds bonus_focus_gain to the hit's gain).
@wrapMethod(W3PlayerWitcher)
function OnProcessActionPost(action : W3DamageAction)
{
	var attackAction : W3Action_Attack;
	var gain : float;

	attackAction = (W3Action_Attack)action;
	if((CanUseSkill(S_Perk_07) || CanUseSkill(S_Perk_25)) && attackAction && attackAction.IsActionMelee() && !inv.IsItemFists(attackAction.GetWeaponId())
		&& (CActor)action.victim && IsRequiredAttitudeBetween(this, (CActor)action.victim, true) && GMAttackEarnsAdrenaline(attackAction))
		gain = CalculateAttributeValue(GetAttributeValue('bonus_focus_gain'));
	wrappedMethod(action);
	if(gain > 0)
		GainStat(BCS_Focus, gain);
}
