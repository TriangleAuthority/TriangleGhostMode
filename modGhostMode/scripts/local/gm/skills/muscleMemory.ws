// SKL-03: the new tree's Muscle Memory (sword_s22, D1, D53), a new design by the project owner: 5.x's
// trigger (a successful dodge or roll, which 5.x arms in CR4Player.ReactToBeingHit and
// CheckSkillActivationOnProjectileDodgeRoll by playing fast_attack_buff on the sword) arms 1/2/3 boosted
// melee fast attacks by level (5.x's count boosted one fewer: D53). The first must come within 6 s of
// the dodge, each further one within 6 s of the one before; a melee strong attack ends them. Each boosted
// attack (every enemy its swing hits) gets +60% attack power (damage/formula.ws) and +10% total damage
// (the final-damage step, damage/pipeline.ws), in place of 5.x's raw-damage multiplier. The sword shows
// fast_attack_buff while it is armed (shared with Precise Blows, skills/critBlows.ws). Plus legacy's
// adrenaline gain for fast attacks, +5% per level (skills/muscleStrength.ws). Values in gm_skills.xml.
// 5.x's own count (CR4Player.DoAttack) finds no effect of its own and does nothing.
// See docs/features/skl.md.

@addField(W3PlayerWitcher)
public var gmMMRemaining : int;
@addField(W3PlayerWitcher)
var gmMMEnd : float;
@addField(W3PlayerWitcher)
var gmMMBoostAt : float;
@addField(W3PlayerWitcher)
var gmMMAction : W3Action_Attack;

@addMethod(W3PlayerWitcher)
function GMMuscleMemoryArmed() : bool
{
	return CanUseSkill(S_Sword_s22) && gmMMRemaining > 0 && theGame.GetEngineTimeAsSeconds() < gmMMEnd;
}

@addMethod(W3PlayerWitcher)
function GMMuscleMemoryValue(attributeName : name) : float
{
	return CalculateAttributeValue(GetSkillAttributeValue(S_Sword_s22, attributeName, false, false));
}

@addMethod(W3PlayerWitcher)
function GMMuscleMemoryArm()
{
	var sword : CWitcherSword;
	var window : float;

	if(!CanUseSkill(S_Sword_s22))
		return;
	window = GMMuscleMemoryValue('gm_mm_window');
	gmMMRemaining = GetSkillLevel(S_Sword_s22);
	gmMMEnd = theGame.GetEngineTimeAsSeconds() + window;
	sword = GetHeldSwordEntity();
	if(sword)
		sword.PlayEffect('fast_attack_buff');
	AddTimer('GMMuscleMemoryExpired', window + 0.05, false);
}

@addMethod(W3PlayerWitcher)
function GMMuscleMemoryEnd()
{
	var sword : CWitcherSword;

	gmMMRemaining = 0;
	gmMMEnd = 0;
	sword = GetHeldSwordEntity();
	if(sword && !GMSwordBuffInUse(false))
		sword.StopEffect('fast_attack_buff');
}

@addMethod(W3PlayerWitcher)
timer function GMMuscleMemoryExpired(dt : float, id : int)
{
	if(theGame.GetEngineTimeAsSeconds() >= gmMMEnd)
		GMMuscleMemoryEnd();
}

// A melee fast attack's damage step: a boost for a new swing while armed (also for the other enemies
// the same swing hits).
@addMethod(W3PlayerWitcher)
function GMMuscleMemoryOnFastAttack(attackAction : W3Action_Attack)
{
	var now, window : float;

	now = theGame.GetEngineTimeAsSeconds();
	if(gmMMBoostAt > 0 && now - gmMMBoostAt < GMSameSwingTime())
	{
		gmMMAction = attackAction;
		return;
	}
	if(!GMMuscleMemoryArmed())
		return;
	window = GMMuscleMemoryValue('gm_mm_window');
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
	return attackAction && attackAction == gmMMAction && theGame.GetEngineTimeAsSeconds() - gmMMBoostAt < GMSameSwingTime();
}

@addMethod(W3PlayerWitcher)
function GMMuscleMemoryPowerFor(attackAction : W3Action_Attack) : float
{
	if(GMMuscleMemoryBoosted(attackAction))
		return GMMuscleMemoryValue('gm_mm_attack_power');
	return 0;
}

// The final-damage multiplier of a boosted attack.
function GMMuscleMemoryDamageMult(player : CR4Player, attackAction : W3Action_Attack) : float
{
	var witcher : W3PlayerWitcher;

	witcher = (W3PlayerWitcher)player;
	if(!witcher || !witcher.GMMuscleMemoryBoosted(attackAction))
		return 1;
	return 1 + witcher.GMMuscleMemoryValue('gm_mm_total_damage');
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
