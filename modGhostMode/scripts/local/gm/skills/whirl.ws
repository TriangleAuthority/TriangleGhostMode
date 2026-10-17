// SKL-03: Whirl, legacy's in both trees (D3): attack power for each enemy beyond the first, and
// less damage taken while spinning with adrenaline. The classic tree's sword_s1 has legacy's 5
// levels; the new tree's sword_s35 reaches legacy's level-5 totals at level 3 (its values are in
// gm_skills.xml). The stamina cost is STAM-09's (stamina/whirlRendStamina.ws).
// See docs/features/skl.md.

// Hostile living actors within 30 m, Geralt excluded (FLAG_ExcludeTarget leaves out the entity
// passed, Geralt); the attack's target is counted (legacy GetNumHostilesInRange).
@addMethod(W3PlayerWitcher)
function GMGetNumHostilesInRange() : int
{
	var ents : array<CGameplayEntity>;

	FindGameplayEntitiesInRange(ents, this, 30, 100, , FLAG_OnlyAliveActors + FLAG_ExcludeTarget + FLAG_Attitude_Hostile, this);
	return ents.Size();
}

// Whirl's attack power bonus: whirl_dmg_bonus per level for each enemy beyond the first, at most 5
// (legacy GetWhirlDamageBonus).
@addMethod(W3PlayerWitcher)
function GMGetWhirlDamageBonus() : float
{
	var skill : ESkill;
	var ability : SAbilityAttributeValue;

	skill = GMWhirlSkill();
	ability = GetSkillAttributeValue(skill, 'whirl_dmg_bonus', false, true);
	return ability.valueMultiplicative * GetSkillLevel(skill) * Clamp(GMGetNumHostilesInRange() - 1, 0, 5);
}

// Whirl's share of damage taken that is removed: whirl_dmg_reduction at level 1, plus
// whirl_dmg_reduction_bonus_after_1 per level above 1.
@addMethod(W3PlayerWitcher)
function GMGetWhirlDamageReduction() : float
{
	var skill : ESkill;
	var reduction : SAbilityAttributeValue;

	skill = GMWhirlSkill();
	if(GetSkillLevel(skill) < 1)
		return 0;
	reduction = GetSkillAttributeValue(skill, 'whirl_dmg_reduction', false, true)
		+ GetSkillAttributeValue(skill, 'whirl_dmg_reduction_bonus_after_1', false, true) * (GetSkillLevel(skill) - 1);
	return ClampF(reduction.valueMultiplicative, 0, 1);
}

// Whirl's terms apply while Geralt is whirling with adrenaline (legacy: IsDoingSpecialAttack(false)
// and adrenaline above 0).
@addMethod(W3PlayerWitcher)
function GMIsWhirlingWithAdrenaline() : bool
{
	return IsDoingSpecialAttack(false) && GetStat(BCS_Focus) > 0;
}
