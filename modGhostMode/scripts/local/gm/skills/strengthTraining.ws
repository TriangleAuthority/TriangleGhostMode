// SKL-04: the new tree's Strength Training (sword_s23, D54), a new design by the project owner in place
// of 5.x's single bonus (revised 2026-11-08 and 2026-11-09): melee strong attacks (Rend included, fists
// too) get +25% attack power (8/16/25% by level), and a strong attack's swing that hits (dealt damage, not
// dodged, parried or countered; Rend too) gives Geralt's next basic attack (fast or strong) as much again,
// so strong attacks in a row get both. Only a basic attack gets the next-strike bonus and uses it up:
// Rend, counters and Whirl leave it waiting (Rend refreshes it) (owner, 2026-11-09). The next-strike bonus lasts 6 s; every enemy the boosted swing hits gets it.
// While it waits the sword shows Strength Training's own glow: gm_st_buff, a yellow copy of 5.x's
// strong_attack_buff (the orange glow Crushing Blows shows) that the mod adds to the sword fx templates
// (tools/gen_sword_glows.py; owner's request, 2026-11-10).
// Both go to the attack-power step (damage/formula.ws). Plus legacy's adrenaline gain for strong
// attacks, +5% per level (skills/muscleStrength.ws). Values in gm_skills.xml; 5.x's counter and bonus
// are no longer called.
// See docs/features/skl.md.

@addField(W3PlayerWitcher)
var gmSTArmedEnd : float;
@addField(W3PlayerWitcher)
var gmSTLastHitAt : float;
@addField(W3PlayerWitcher)
var gmSTSwingBoosted : bool;
@addField(W3PlayerWitcher)
var gmSTAction : W3Action_Attack;
@addField(W3PlayerWitcher)
var gmSTSword : CWitcherSword;

// Strength Training's own sword effect (tools/gen_sword_glows.py writes it into the sword fx templates).
function GMStrengthTrainingEffect() : name
{
	return 'gm_st_buff';
}

// Hits of one swing on several enemies arrive within a frame or two; a new swing takes far longer.
function GMSameSwingTime() : float
{
	return 0.25;
}

// A bonus of the skill at Geralt's level (the xml holds the level-3 value; GMNewTreeLevelShare in
// skills/muscleMemory.ws).
@addMethod(W3PlayerWitcher)
function GMStrengthTrainingValue(attributeName : name) : float
{
	if(!CanUseSkill(S_Sword_s23))
		return 0;
	return CalculateAttributeValue(GetSkillAttributeValue(S_Sword_s23, attributeName, false, false)) * GMNewTreeLevelShare(GetSkillLevel(S_Sword_s23));
}

// The next-strike bonus is waiting.
@addMethod(W3PlayerWitcher)
function GMStrengthTrainingArmed() : bool
{
	return CanUseSkill(S_Sword_s23) && theGame.GetEngineTimeAsSeconds() < gmSTArmedEnd;
}

// A melee strong attack's hit (after its damage): arms the next-strike bonus.
@addMethod(W3PlayerWitcher)
function GMStrengthTrainingArm()
{
	var duration : float;
	var sword : CWitcherSword;

	duration = CalculateAttributeValue(GetSkillAttributeValue(S_Sword_s23, 'gm_st_duration', false, false));
	gmSTArmedEnd = theGame.GetEngineTimeAsSeconds() + duration;
	sword = GetHeldSwordEntity();
	if(gmSTSword && gmSTSword != sword)
		gmSTSword.StopEffect(GMStrengthTrainingEffect());
	gmSTSword = sword;
	if(sword)
		sword.PlayEffect(GMStrengthTrainingEffect());
	AddTimer('GMStrengthTrainingExpired', duration + 0.05, false);
}

@addMethod(W3PlayerWitcher)
function GMStrengthTrainingDisarm()
{
	var sword : CWitcherSword;

	gmSTArmedEnd = 0;
	// the sword it was armed on (it may have been sheathed or swapped since), and the one held now
	if(gmSTSword)
		gmSTSword.StopEffect(GMStrengthTrainingEffect());
	gmSTSword = NULL;
	sword = GetHeldSwordEntity();
	if(sword)
		sword.StopEffect(GMStrengthTrainingEffect());
}

@addMethod(W3PlayerWitcher)
timer function GMStrengthTrainingExpired(dt : float, id : int)
{
	if(theGame.GetEngineTimeAsSeconds() >= gmSTArmedEnd)
		GMStrengthTrainingDisarm();
}

// A basic attack's damage step: a new swing uses up the waiting bonus; the other enemies the same swing
// hits get what its first hit got.
@addMethod(W3PlayerWitcher)
function GMStrengthTrainingOnAttack(attackAction : W3Action_Attack)
{
	var now : float;

	if(!CanUseSkill(S_Sword_s23) || !GMBasicAttack(attackAction.GetAttackName()))
		return;
	now = theGame.GetEngineTimeAsSeconds();
	if(gmSTLastHitAt > 0 && now - gmSTLastHitAt < GMSameSwingTime())
	{
		gmSTLastHitAt = now;
		if(gmSTSwingBoosted)
			gmSTAction = attackAction;
		return;
	}
	gmSTLastHitAt = now;
	gmSTSwingBoosted = GMStrengthTrainingArmed();
	if(gmSTSwingBoosted)
	{
		gmSTAction = attackAction;
		GMStrengthTrainingDisarm();
	}
}

// The attack power a melee hit gets: the strong attack's own, and the next-strike bonus.
@addMethod(W3PlayerWitcher)
function GMStrengthTrainingPowerFor(attackAction : W3Action_Attack) : float
{
	var power : float;

	if(!attackAction || !attackAction.IsActionMelee() || !CanUseSkill(S_Sword_s23))
		return 0;
	if(IsHeavyAttack(attackAction.GetAttackName()))
		power += GMStrengthTrainingValue('gm_st_attack_power');
	if(gmSTSwingBoosted && attackAction == gmSTAction && GMBasicAttack(attackAction.GetAttackName()) && theGame.GetEngineTimeAsSeconds() - gmSTLastHitAt < GMSameSwingTime())
		power += GMStrengthTrainingValue('gm_st_next_attack_power');
	return power;
}

@wrapMethod(W3PlayerWitcher)
function OnProcessActionPost(action : W3DamageAction)
{
	var attackAction : W3Action_Attack;
	var arm : bool;

	attackAction = (W3Action_Attack)action;
	arm = attackAction && attackAction.IsActionMelee() && IsHeavyAttack(attackAction.GetAttackName())
		&& CanUseSkill(S_Sword_s23) && (CActor)action.victim && IsRequiredAttitudeBetween(this, (CActor)action.victim, true) && GMAttackEarnsAdrenaline(attackAction);
	wrappedMethod(action);
	if(arm)
		GMStrengthTrainingArm();
}
