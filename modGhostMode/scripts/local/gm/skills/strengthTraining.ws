// SKL-04: the new tree's Strength Training (sword_s23, D54), a new design by the project owner in place
// of 5.x's single bonus: each melee fast-attack swing that hits (dealt damage, not dodged, parried or
// countered; one per swing, however many enemies it hits) adds a stack, up to 1/2/3 by level, each
// worth half the one before: +35% attack power and +10% weapon damage, then +17.5%/+5%, then
// +8.75%/+2.5%. The next melee strong attack (Rend included) uses up every stack: the weapon damage is a
// pool term (damage/pool.ws), the attack power goes to the attack-power step (damage/formula.ws); every
// enemy that swing hits gets them. The stacks expire 6 s after the last one was added. While there are
// stacks the sword shows strong_attack_buff (shared with Crushing Blows, skills/critBlows.ws). Plus
// legacy's adrenaline gain for strong attacks, +5% per level (skills/muscleStrength.ws). Values in
// gm_skills.xml; 5.x's counter and bonus are no longer called.
// See docs/features/skl.md.

@addField(W3PlayerWitcher)
var gmSTStacks : int;
@addField(W3PlayerWitcher)
var gmSTEnd : float;
@addField(W3PlayerWitcher)
var gmSTLastStackAt : float;
@addField(W3PlayerWitcher)
var gmSTUsedAt : float;
@addField(W3PlayerWitcher)
var gmSTUsedAP : float;
@addField(W3PlayerWitcher)
var gmSTUsedWD : float;
@addField(W3PlayerWitcher)
var gmSTAction : W3Action_Attack;

// Hits of one swing on several enemies arrive within a frame or two; a new swing takes far longer.
function GMSameSwingTime() : float
{
	return 0.25;
}

@addMethod(W3PlayerWitcher)
function GMStrengthTrainingStacks() : int
{
	if(!CanUseSkill(S_Sword_s23) || theGame.GetEngineTimeAsSeconds() >= gmSTEnd)
		return 0;
	return gmSTStacks;
}

// The bonus of n stacks: the first stack's value, halved for each further one.
@addMethod(W3PlayerWitcher)
function GMStrengthTrainingBonus(attributeName : name, stacks : int) : float
{
	var value, bonus : float;
	var i : int;

	value = CalculateAttributeValue(GetSkillAttributeValue(S_Sword_s23, attributeName, false, false));
	for(i = 0; i < stacks; i += 1)
	{
		bonus += value;
		value *= 0.5;
	}
	return bonus;
}

// A melee fast attack's hit (after its damage): a stack for a new swing.
@addMethod(W3PlayerWitcher)
function GMStrengthTrainingOnFastHit()
{
	var now, duration : float;
	var sword : CWitcherSword;

	now = theGame.GetEngineTimeAsSeconds();
	duration = CalculateAttributeValue(GetSkillAttributeValue(S_Sword_s23, 'gm_st_duration', false, false));
	if(now >= gmSTEnd)
		gmSTStacks = 0;
	if(now - gmSTLastStackAt > GMSameSwingTime())
		gmSTStacks = Min(gmSTStacks + 1, GetSkillLevel(S_Sword_s23));
	gmSTLastStackAt = now;
	gmSTEnd = now + duration;
	sword = GetHeldSwordEntity();
	if(sword)
		sword.PlayEffect('strong_attack_buff');
	AddTimer('GMStrengthTrainingExpired', duration + 0.05, false);
}

@addMethod(W3PlayerWitcher)
timer function GMStrengthTrainingExpired(dt : float, id : int)
{
	var sword : CWitcherSword;

	if(theGame.GetEngineTimeAsSeconds() < gmSTEnd)
		return;
	gmSTStacks = 0;
	sword = GetHeldSwordEntity();
	if(sword && !GMSwordBuffInUse(true))
		sword.StopEffect('strong_attack_buff');
}

// A melee strong attack's damage step: uses up the stacks (also for the other enemies the same swing
// hits) and returns the weapon damage for the pool; the attack power is read by the formula.
@addMethod(W3PlayerWitcher)
function GMStrengthTrainingConsume(attackAction : W3Action_Attack) : float
{
	var now : float;
	var stacks : int;
	var sword : CWitcherSword;

	if(!CanUseSkill(S_Sword_s23))
		return 0;
	now = theGame.GetEngineTimeAsSeconds();
	if(gmSTUsedAt > 0 && now - gmSTUsedAt < GMSameSwingTime())
	{
		gmSTAction = attackAction;
		return gmSTUsedWD;
	}
	stacks = GMStrengthTrainingStacks();
	if(stacks <= 0)
		return 0;
	gmSTUsedAP = GMStrengthTrainingBonus('gm_st_attack_power', stacks);
	gmSTUsedWD = GMStrengthTrainingBonus('gm_st_weapon_damage', stacks);
	gmSTUsedAt = now;
	gmSTAction = attackAction;
	gmSTStacks = 0;
	gmSTEnd = 0;
	sword = GetHeldSwordEntity();
	if(sword && !GMSwordBuffInUse(true))
		sword.StopEffect('strong_attack_buff');
	return gmSTUsedWD;
}

@addMethod(W3PlayerWitcher)
function GMStrengthTrainingPowerFor(attackAction : W3Action_Attack) : float
{
	if(attackAction && attackAction == gmSTAction && theGame.GetEngineTimeAsSeconds() - gmSTUsedAt < GMSameSwingTime())
		return gmSTUsedAP;
	return 0;
}

@wrapMethod(W3PlayerWitcher)
function OnProcessActionPost(action : W3DamageAction)
{
	var attackAction : W3Action_Attack;
	var stack : bool;

	attackAction = (W3Action_Attack)action;
	stack = attackAction && attackAction.IsActionMelee() && IsLightAttack(attackAction.GetAttackName()) && !inv.IsItemFists(attackAction.GetWeaponId())
		&& CanUseSkill(S_Sword_s23) && (CActor)action.victim && IsRequiredAttitudeBetween(this, (CActor)action.victim, true) && GMAttackEarnsAdrenaline(attackAction);
	wrappedMethod(action);
	if(stack)
		GMStrengthTrainingOnFastHit();
}
