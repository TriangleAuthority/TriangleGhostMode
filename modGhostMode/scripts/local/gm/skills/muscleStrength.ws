// SKL-03, SKL-04: the classic tree's Muscle Memory (sword_s21) and Strength Training (sword_s4),
// D47. Their attack power counts once: +0.1 per level (+50% at level 5) for fast or strong attacks,
// counters included as fast attacks (DEF-07). Vanilla counts it twice, as legacy and 1.32 did: once
// from the skill abilities tagged with the attack's name (the ability is held once per level), and
// again per level in W3Action_Attack.GetPowerStatValue; the second share is removed here. Plus
// legacy's adrenaline gain for fast or strong attacks, +0.03 per level (light_focus_gain,
// heavy_focus_gain; gm_skill_trees.xml), which 5.x dropped.
// See docs/features/skl.md.

// The explicit share vanilla adds per level (5.x's GetPowerStatValue: a strong attack type with
// sword_s4, a fast attack type with sword_s21), taken back off.
@wrapMethod(W3Action_Attack)
function GetPowerStatValue() : SAbilityAttributeValue
{
	var result : SAbilityAttributeValue;
	var witcher : W3PlayerWitcher;

	result = wrappedMethod();
	witcher = (W3PlayerWitcher)attacker;
	if(witcher)
	{
		if(witcher.IsHeavyAttack(attackTypeName) && witcher.CanUseSkill(S_Sword_s04))
			result += witcher.GetSkillAttributeValue(S_Sword_s04, PowerStatEnumToName(CPS_AttackPower), false, true) * (-witcher.GetSkillLevel(S_Sword_s04));
		if(witcher.IsLightAttack(attackTypeName) && witcher.CanUseSkill(S_Sword_s21))
			result += witcher.GetSkillAttributeValue(S_Sword_s21, PowerStatEnumToName(CPS_AttackPower), false, true) * (-witcher.GetSkillLevel(S_Sword_s21));
	}
	return result;
}

// Legacy's extra adrenaline for a melee fast or strong attack that hits a hostile, not with fists:
// the skill's gain per level on top of the hit's 0.1 (0.1 x (1 + gain), as the hit's own).
@addMethod(W3PlayerWitcher)
function GMGetStyleFocusGain(attackAction : W3Action_Attack) : float
{
	var gain : float;

	if(!attackAction || !attackAction.IsActionMelee() || inv.IsItemFists(attackAction.GetWeaponId()) || !GMAttackEarnsAdrenaline(attackAction))
		return 0;
	if(IsLightAttack(attackAction.GetAttackName()) && CanUseSkill(S_Sword_s21))
		gain = CalculateAttributeValue(GetSkillAttributeValue(S_Sword_s21, 'light_focus_gain', false, true)) * GetSkillLevel(S_Sword_s21);
	else if(IsLightAttack(attackAction.GetAttackName()) && CanUseSkill(S_Sword_s22))	// the new tree's Muscle Memory (D53)
		gain = CalculateAttributeValue(GetSkillAttributeValue(S_Sword_s22, 'light_focus_gain', false, true)) * GetSkillLevel(S_Sword_s22);
	else if(IsHeavyAttack(attackAction.GetAttackName()) && CanUseSkill(S_Sword_s04))
		gain = CalculateAttributeValue(GetSkillAttributeValue(S_Sword_s04, 'heavy_focus_gain', false, true)) * GetSkillLevel(S_Sword_s04);
	else if(IsHeavyAttack(attackAction.GetAttackName()) && CanUseSkill(S_Sword_s23))	// the new tree's Strength Training (D54)
		gain = CalculateAttributeValue(GetSkillAttributeValue(S_Sword_s23, 'heavy_focus_gain', false, true)) * GetSkillLevel(S_Sword_s23);
	return 0.1 * gain;
}

// Given where vanilla gives a hit's adrenaline (W3PlayerWitcher.OnProcessActionPost: a melee hit on
// a hostile, not Rend).
@wrapMethod(W3PlayerWitcher)
function OnProcessActionPost(action : W3DamageAction)
{
	var attackAction : W3Action_Attack;
	var actorVictim : CActor;
	var gain : float;

	attackAction = (W3Action_Attack)action;
	actorVictim = (CActor)action.victim;
	if(attackAction && attackAction.IsActionMelee() && !GMIsRendAttack(attackAction) && actorVictim && IsRequiredAttitudeBetween(this, actorVictim, true))
		gain = GMGetStyleFocusGain(attackAction);
	wrappedMethod(action);
	if(gain > 0)
		GainStat(BCS_Focus, gain);
}
