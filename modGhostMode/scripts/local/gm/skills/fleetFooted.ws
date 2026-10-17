// DEF-02, SKL-05: Fleet Footed, legacy's in both trees (project owner, 2026-10-08). A hit that lands
// while Geralt dodges or rolls without being dodged (a graze: dodging roughly into the attack, too
// close to a stomp, or an attack that cannot be dodged) has its Vitality damage reduced by
// s9_damage_reduction per level, at most 95% (applied in W3PlayerWitcher.ReduceDamage, before
// Quen; defense/dodge.ws). Classic sword_s9 (5 levels, 10% per level), new tree sword_s36 (3 levels,
// 16.67% per level): 50% at the maximum level. 5.x's full dodge at the maximum level and its free
// dodges while the target attacks are gone, so a graze never counts as a dodge.
// See docs/features/def.md and docs/features/skl.md.

// The graze reduction of a hit (0: not a graze).
@addField(W3DamageAction)
var gmGrazeReduction : float;

@addMethod(W3DamageAction)
function GMSetGrazeReduction(reduction : float)
{
	gmGrazeReduction = reduction;
}

@addMethod(W3DamageAction)
function GMGetGrazeReduction() : float
{
	return gmGrazeReduction;
}

@wrapMethod(W3DamageAction)
function Clear()
{
	wrappedMethod();
	gmGrazeReduction = 0;
}

// Fleet Footed's reduction for the skill the player has (classic first, as legacy reads sword_s9).
@addMethod(W3PlayerWitcher)
function GMFleetFootedReduction() : float
{
	var skill : ESkill;

	if(CanUseSkill(S_Sword_s09))
		skill = S_Sword_s09;
	else if(CanUseSkill(S_Sword_s36))
		skill = S_Sword_s36;
	else
		return 0;
	return CalculateAttributeValue(GetSkillAttributeValue(skill, 's9_damage_reduction', false, true)) * GetSkillLevel(skill);
}

// No free dodges or rolls while the target attacks (5.x gave them with either Fleet Footed).
@replaceMethod(CR4PlayerStateCombat)
function SkipStaminaDodgeEvadeCost() : bool
{
	return false;	//modSigns: SKL-05, Fleet Footed no longer makes dodges free (legacy)
}
