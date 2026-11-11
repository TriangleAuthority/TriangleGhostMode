// SKL-03: the new tree's Muscle Memory (sword_s22, D1, D53), a new design by the project owner (revised
// 2026-11-09): melee fast attacks get +25% attack power (8/16/25% by level). 5.x's trigger (a successful
// dodge or roll, which 5.x arms in CR4Player.ReactToBeingHit and CheckSkillActivationOnProjectileDodgeRoll
// by playing fast_attack_buff on the sword) arms a further +50% attack power (16/32/50% by level) for the
// next 3 attacks: each basic fast attack gets it and uses one, a basic strong attack gets it and ends it
// (owner, 2026-11-09). Only basic attacks (attack_light, attack_heavy; fists included) get the boost and
// count: counters, Whirl and Rend neither get it nor use it (owner, 2026-11-09). The first must come within
// 6 s of the dodge, each further one within 6 s of the one before; every enemy a boosted swing hits gets it. All in the attack-power step (damage/formula.ws). The sword shows
// Muscle Memory's own glow while it is armed: gm_mm_buff, a green copy of 5.x's fast_attack_buff (the blue
// glow Precise Blows and the Feline set show) that the mod adds to the sword fx templates
// (tools/gen_sword_glows.py; owner's request, 2026-11-09). Plus legacy's
// adrenaline gain for fast attacks, +5% per level (skills/muscleStrength.ws). Values (level 3) in
// gm_skills.xml. 5.x's own count (CR4Player.DoAttack) finds no effect of its own and does nothing.
// See docs/features/skl.md.

@addField(W3PlayerWitcher)
public var gmMMRemaining : int;
@addField(W3PlayerWitcher)
var gmMMEnd : float;
@addField(W3PlayerWitcher)
var gmMMBoostAt : float;
@addField(W3PlayerWitcher)
var gmMMAction : W3Action_Attack;
@addField(W3PlayerWitcher)
var gmMMSword : CWitcherSword;

// Muscle Memory's own sword effect (tools/gen_sword_glows.py writes it into the sword fx templates).
function GMMuscleMemoryEffect() : name
{
	return 'gm_mm_buff';
}

@addMethod(W3PlayerWitcher)
function GMMuscleMemoryArmed() : bool
{
	return CanUseSkill(S_Sword_s22) && gmMMRemaining > 0 && theGame.GetEngineTimeAsSeconds() < gmMMEnd;
}

// The share of the level-3 value at a level of the new tree's Muscle Memory and Strength Training: 8/16/25
// of 25 (owner, 2026-11-09).
function GMNewTreeLevelShare(level : int) : float
{
	if(level >= 3)
		return 1;
	return 0.32 * Max(level, 0);
}

// A value of the skill: its bonuses at Geralt's level, the window and the count as they are.
@addMethod(W3PlayerWitcher)
function GMMuscleMemoryValue(attributeName : name) : float
{
	var v : float;

	v = CalculateAttributeValue(GetSkillAttributeValue(S_Sword_s22, attributeName, false, false));
	if(attributeName == 'gm_mm_attack_power' || attributeName == 'gm_mm_dodge_attack_power')
		v *= GMNewTreeLevelShare(GetSkillLevel(S_Sword_s22));
	return v;
}

@addMethod(W3PlayerWitcher)
function GMMuscleMemoryArm()
{
	var sword : CWitcherSword;
	var window : float;

	if(!CanUseSkill(S_Sword_s22))
		return;
	window = GMMuscleMemoryValue('gm_mm_window');
	gmMMRemaining = RoundMath(GMMuscleMemoryValue('gm_mm_attacks'));
	gmMMEnd = theGame.GetEngineTimeAsSeconds() + window;
	sword = GetHeldSwordEntity();
	if(gmMMSword && gmMMSword != sword)
		gmMMSword.StopEffect(GMMuscleMemoryEffect());
	gmMMSword = sword;
	if(sword)
		sword.PlayEffect(GMMuscleMemoryEffect());
	AddTimer('GMMuscleMemoryExpired', window + 0.05, false);
}

@addMethod(W3PlayerWitcher)
function GMMuscleMemoryEnd()
{
	var sword : CWitcherSword;

	gmMMRemaining = 0;
	gmMMEnd = 0;
	// the sword it was armed on (it may have been sheathed or swapped since), and the one held now
	if(gmMMSword)
		gmMMSword.StopEffect(GMMuscleMemoryEffect());
	gmMMSword = NULL;
	sword = GetHeldSwordEntity();
	if(sword)
		sword.StopEffect(GMMuscleMemoryEffect());
}

@addMethod(W3PlayerWitcher)
timer function GMMuscleMemoryExpired(dt : float, id : int)
{
	if(theGame.GetEngineTimeAsSeconds() >= gmMMEnd)
		GMMuscleMemoryEnd();
}

// Geralt's basic fast and strong attacks: the only ones that get and use up Muscle Memory's dodge boost and
// Strength Training's next-strike bonus (owner, 2026-11-09); not counters (counter_attack_light), Whirl
// or Rend.
function GMBasicAttack(attackName : name) : bool
{
	return attackName == theGame.params.ATTACK_NAME_LIGHT || attackName == theGame.params.ATTACK_NAME_HEAVY;
}

// A melee attack's damage step: a boost for a new basic swing while armed (also for the other enemies the
// same swing hits); a fast attack uses one boost, a strong attack every boost left.
@addMethod(W3PlayerWitcher)
function GMMuscleMemoryOnAttack(attackAction : W3Action_Attack)
{
	var now, window : float;

	if(!GMBasicAttack(attackAction.GetAttackName()))
		return;
	now = theGame.GetEngineTimeAsSeconds();
	if(gmMMBoostAt > 0 && now - gmMMBoostAt < GMSameSwingTime())
	{
		gmMMAction = attackAction;
		return;
	}
	if(!GMMuscleMemoryArmed())
		return;
	window = GMMuscleMemoryValue('gm_mm_window');
	if(attackAction.GetAttackName() == theGame.params.ATTACK_NAME_HEAVY)
		gmMMRemaining = 0;
	else
		gmMMRemaining -= 1;
	gmMMEnd = now + window;
	gmMMBoostAt = now;
	gmMMAction = attackAction;
	if(gmMMRemaining <= 0)
		GMMuscleMemoryEnd();
	else
		AddTimer('GMMuscleMemoryExpired', window + 0.05, false);
}

@addMethod(W3PlayerWitcher)
function GMMuscleMemoryBoosted(attackAction : W3Action_Attack) : bool
{
	return attackAction && attackAction == gmMMAction && GMBasicAttack(attackAction.GetAttackName()) && theGame.GetEngineTimeAsSeconds() - gmMMBoostAt < GMSameSwingTime();
}

// The attack power a melee hit gets: the fast attacks' own, and the dodge's boost.
@addMethod(W3PlayerWitcher)
function GMMuscleMemoryPowerFor(attackAction : W3Action_Attack) : float
{
	var power : float;

	if(!attackAction || !attackAction.IsActionMelee() || !CanUseSkill(S_Sword_s22))
		return 0;
	if(IsLightAttack(attackAction.GetAttackName()))
		power += GMMuscleMemoryValue('gm_mm_attack_power');
	if(GMMuscleMemoryBoosted(attackAction))
		power += GMMuscleMemoryValue('gm_mm_dodge_attack_power');
	return power;
}

// 5.x arms its Muscle Memory by playing fast_attack_buff on the sword after a successful dodge or roll:
// that arms the new design instead (5.x's effect and count are not started).
@wrapMethod(W3PlayerWitcher)
function PlaySkillComboEffect(skill : ESkill, entity : CEntity, effectName : name)
{
	if(skill == S_Sword_s22 && effectName == 'fast_attack_buff')
	{
		GMMuscleMemoryArm();
		return;
	}
	wrappedMethod(skill, entity, effectName);
}
