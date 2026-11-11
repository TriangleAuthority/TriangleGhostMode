// SKL-03, SKL-04: the new tree's Precise Blows (sword_s24, D57) and Crushing Blows (sword_s25, D55), new
// designs by the project owner in place of 5.x's Three Strikes and Crushing Blow procs (revised
// 2026-11-07). Precise Blows: melee fast and strong attacks get +5% critical hit chance, and +5% more per
// stack; each melee fast attack that hits without a crit adds a stack, up to 4. Crushing Blows: melee
// fast and strong attacks' crits get +50% critical hit power, and +50% more per stack; each melee strong
// attack that hits without a crit adds a stack, up to 3. Any melee crit of Geralt's clears both skills'
// stacks after it got their bonus (every enemy that swing hits gets the same). The levels raise the
// maximum stacks, not the values (owner, 2026-11-07): Precise Blows 2 / 3 / 4, Crushing Blows 1 / 2 / 3
// (gm_max_stacks is the level-3 cap, one fewer per level below; porter's call). The stacks do not expire, but combat's end
// clears them, and they are not saved. While a skill has stacks the sword shows 5.x's effect
// (fast_attack_buff, strong_attack_buff); Muscle Memory and Strength Training show their own (gm_mm_buff,
// gm_st_buff; skills/muscleMemory.ws, skills/strengthTraining.ws). Values in gm_skills.xml (gm_crit_chance, gm_crit_damage,
// gm_stack_crit_chance, gm_stack_crit_damage, gm_max_stacks; own names, so the skills' tagged abilities
// do not add them again). The crit damage is added in the crit step (damage/formula.ws); 5.x's procs are
// no longer called (damage/pool.ws).
// See docs/features/skl.md.

@addField(W3PlayerWitcher)
public var gmPreciseStacks : int;
@addField(W3PlayerWitcher)
public var gmCrushingStacks : int;
@addField(W3PlayerWitcher)
var gmPreciseStackAt : float;
@addField(W3PlayerWitcher)
var gmCrushingStackAt : float;
@addField(W3PlayerWitcher)
var gmBlowsCritAt : float;
@addField(W3PlayerWitcher)
var gmPreciseCleared : int;
@addField(W3PlayerWitcher)
var gmCrushingCleared : int;

@addMethod(W3PlayerWitcher)
function GMBlowsValue(skill : ESkill, attributeName : name) : float
{
	return CalculateAttributeValue(GetSkillAttributeValue(skill, attributeName, false, false));
}

// A skill's stacks for the current hit: the swing of the crit that cleared them still uses them (its other
// enemies get the same bonus).
@addMethod(W3PlayerWitcher)
function GMBlowsStacks(skill : ESkill) : int
{
	var sameSwing : bool;

	if(!CanUseSkill(skill))
		return 0;
	sameSwing = gmBlowsCritAt > 0 && theGame.GetEngineTimeAsSeconds() - gmBlowsCritAt < GMSameSwingTime();
	if(skill == S_Sword_s24)
	{
		if(sameSwing)
			return gmPreciseCleared;
		return gmPreciseStacks;
	}
	if(skill == S_Sword_s25)
	{
		if(sameSwing)
			return gmCrushingCleared;
		return gmCrushingStacks;
	}
	return 0;
}

// Precise Blows' crit chance for melee fast and strong attacks.
@addMethod(W3PlayerWitcher)
function GMBlowsCritChance() : float
{
	if(!CanUseSkill(S_Sword_s24))
		return 0;
	return GMBlowsValue(S_Sword_s24, 'gm_crit_chance') + GMBlowsValue(S_Sword_s24, 'gm_stack_crit_chance') * GMBlowsStacks(S_Sword_s24);
}

// Crushing Blows' crit damage for melee fast and strong attacks.
@addMethod(W3PlayerWitcher)
function GMBlowsCritDamage() : float
{
	if(!CanUseSkill(S_Sword_s25))
		return 0;
	return GMBlowsValue(S_Sword_s25, 'gm_crit_damage') + GMBlowsValue(S_Sword_s25, 'gm_stack_crit_damage') * GMBlowsStacks(S_Sword_s25);
}

// The maximum stacks at a level: the level-3 cap (gm_max_stacks), one fewer per level below.
function GMBlowsStackCap(levelThreeCap : float, level : int) : int
{
	return Max(RoundMath(levelThreeCap) - 3 + level, 1);
}

@addMethod(W3PlayerWitcher)
function GMBlowsMaxStacks(skill : ESkill) : int
{
	return GMBlowsStackCap(GMBlowsValue(skill, 'gm_max_stacks'), GetSkillLevel(skill));
}

// The sword effect a skill's stacks show, and whether the skill still uses it.
function GMBlowsEffectName(isHeavy : bool) : name
{
	if(isHeavy)
		return 'strong_attack_buff';
	return 'fast_attack_buff';
}

@addMethod(W3PlayerWitcher)
function GMSwordBuffInUse(isHeavy : bool) : bool
{
	if(isHeavy)
		return gmCrushingStacks > 0 && CanUseSkill(S_Sword_s25);
	return gmPreciseStacks > 0 && CanUseSkill(S_Sword_s24);
}

@addMethod(W3PlayerWitcher)
function GMBlowsStopEffects()
{
	var sword : CWitcherSword;

	sword = GetHeldSwordEntity();
	if(!sword)
		return;
	if(!GMSwordBuffInUse(false))
		sword.StopEffect(GMBlowsEffectName(false));
	if(!GMSwordBuffInUse(true))
		sword.StopEffect(GMBlowsEffectName(true));
}

// A melee crit of Geralt's (after its bonus): clears both skills' stacks, once per swing.
@addMethod(W3PlayerWitcher)
function GMBlowsOnCrit()
{
	var now : float;

	now = theGame.GetEngineTimeAsSeconds();
	if(gmBlowsCritAt > 0 && now - gmBlowsCritAt < GMSameSwingTime())
		return;
	gmPreciseCleared = gmPreciseStacks;
	gmCrushingCleared = gmCrushingStacks;
	gmPreciseStacks = 0;
	gmCrushingStacks = 0;
	gmBlowsCritAt = now;
	GMBlowsStopEffects();
}

// A melee fast (Precise Blows) or strong attack (Crushing Blows) that hit without a crit: a stack for a new
// swing, unless a crit of the same swing cleared them.
@addMethod(W3PlayerWitcher)
function GMBlowsOnHit(isHeavy : bool)
{
	var skill : ESkill;
	var now : float;
	var sword : CWitcherSword;

	if(isHeavy)
		skill = S_Sword_s25;
	else
		skill = S_Sword_s24;
	if(!CanUseSkill(skill))
		return;
	now = theGame.GetEngineTimeAsSeconds();
	if(gmBlowsCritAt > 0 && now - gmBlowsCritAt < GMSameSwingTime())
		return;
	if(isHeavy)
	{
		if(now - gmCrushingStackAt <= GMSameSwingTime())
			return;
		gmCrushingStacks = Min(gmCrushingStacks + 1, GMBlowsMaxStacks(skill));
		gmCrushingStackAt = now;
	}
	else
	{
		if(now - gmPreciseStackAt <= GMSameSwingTime())
			return;
		gmPreciseStacks = Min(gmPreciseStacks + 1, GMBlowsMaxStacks(skill));
		gmPreciseStackAt = now;
	}
	sword = GetHeldSwordEntity();
	if(sword)
		sword.PlayEffect(GMBlowsEffectName(isHeavy));
}

// Combat's end clears the stacks.
@addMethod(W3PlayerWitcher)
function GMBlowsClear()
{
	gmPreciseStacks = 0;
	gmCrushingStacks = 0;
	gmPreciseCleared = 0;
	gmCrushingCleared = 0;
	gmBlowsCritAt = 0;
	gmPreciseStackAt = 0;
	gmCrushingStackAt = 0;
	GMBlowsStopEffects();
}

@wrapMethod(W3PlayerWitcher)
function OnCombatFinished()
{
	wrappedMethod();
	GMBlowsClear();
}

// Stacks from Geralt's melee hits on a hostile enemy that dealt damage (not dodged, parried or countered)
// and were not crits (a crit's own step cleared them, damage/formula.ws).
@wrapMethod(W3PlayerWitcher)
function OnProcessActionPost(action : W3DamageAction)
{
	var attackAction : W3Action_Attack;
	var hit, isHeavy : bool;

	attackAction = (W3Action_Attack)action;
	hit = attackAction && attackAction.IsActionMelee() && !action.IsCriticalHit() && (CanUseSkill(S_Sword_s24) || CanUseSkill(S_Sword_s25))
		&& (IsLightAttack(attackAction.GetAttackName()) || IsHeavyAttack(attackAction.GetAttackName()))
		&& (CActor)action.victim && IsRequiredAttitudeBetween(this, (CActor)action.victim, true) && GMAttackEarnsAdrenaline(attackAction);
	if(hit)
		isHeavy = IsHeavyAttack(attackAction.GetAttackName());
	wrappedMethod(action);
	if(hit)
		GMBlowsOnHit(isHeavy);
}

// The crit chance for melee fast and strong attacks.
@wrapMethod(W3PlayerWitcher)
function GetCriticalHitChance(isLightAttack : bool, isHeavyAttack : bool, target : CActor, victimMonsterCategory : EMonsterCategory, isBolt : bool) : float
{
	var chance : float;

	chance = wrappedMethod(isLightAttack, isHeavyAttack, target, victimMonsterCategory, isBolt);
	if(!isBolt && (isLightAttack || isHeavyAttack))
		chance += GMBlowsCritChance();
	return chance;
}
