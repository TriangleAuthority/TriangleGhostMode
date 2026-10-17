// SKL-03, SKL-04: the new tree's Precise Blows (sword_s24, D57) and Crushing Blows (sword_s25, D55), new
// designs by the project owner in place of 5.x's Three Strikes and Crushing Blow procs: melee fast
// (Precise Blows) or strong attacks (Crushing Blows, Rend included) get +8% critical hit chance at
// every level and +20% critical hit damage per level; a crit of that attack type starts a chain for 4 s
// (Precise Blows) or 6 s (Crushing Blows): that type's attacks get a further +8% crit chance and +20%
// crit damage per level, not stacking, restarted by another crit of the type. While a chain lasts the
// sword shows 5.x's effect (fast_attack_buff, strong_attack_buff), shared with Muscle Memory and
// Strength Training: it is turned off only when no skill using it is active. Values in gm_skills.xml
// (gm_crit_chance, gm_crit_damage, gm_chain_crit_chance, gm_chain_crit_damage, gm_chain_duration;
// own names, so the skills' tagged abilities do not add them again). The crit damage is added in the
// crit step (damage/formula.ws); 5.x's procs are no longer called (damage/pool.ws).
// See docs/features/skl.md.

@addField(W3PlayerWitcher)
var gmPreciseChainEnd : float;
@addField(W3PlayerWitcher)
var gmCrushingChainEnd : float;

// The new tree's skill for a melee attack of this type, if Geralt has it: Crushing Blows for strong
// attacks, Precise Blows for fast ones; S_SUndefined otherwise.
@addMethod(W3PlayerWitcher)
function GMBlowsSkill(isHeavy : bool) : ESkill
{
	if(isHeavy && CanUseSkill(S_Sword_s25))
		return S_Sword_s25;
	if(!isHeavy && CanUseSkill(S_Sword_s24))
		return S_Sword_s24;
	return S_SUndefined;
}

@addMethod(W3PlayerWitcher)
function GMBlowsChainActive(skill : ESkill) : bool
{
	if(skill == S_Sword_s25)
		return theGame.GetEngineTimeAsSeconds() < gmCrushingChainEnd;
	if(skill == S_Sword_s24)
		return theGame.GetEngineTimeAsSeconds() < gmPreciseChainEnd;
	return false;
}

@addMethod(W3PlayerWitcher)
function GMBlowsValue(skill : ESkill, attributeName : name, perLevel : bool) : float
{
	var value : float;

	value = CalculateAttributeValue(GetSkillAttributeValue(skill, attributeName, false, false));
	if(perLevel)
		value *= GetSkillLevel(skill);
	return value;
}

@addMethod(W3PlayerWitcher)
function GMBlowsCritChance(isHeavy : bool) : float
{
	var skill : ESkill;
	var chance : float;

	skill = GMBlowsSkill(isHeavy);
	if(skill == S_SUndefined)
		return 0;
	chance = GMBlowsValue(skill, 'gm_crit_chance', false);
	if(GMBlowsChainActive(skill))
		chance += GMBlowsValue(skill, 'gm_chain_crit_chance', false);
	return chance;
}

@addMethod(W3PlayerWitcher)
function GMBlowsCritDamage(isHeavy : bool) : float
{
	var skill : ESkill;
	var bonus : float;

	skill = GMBlowsSkill(isHeavy);
	if(skill == S_SUndefined)
		return 0;
	bonus = GMBlowsValue(skill, 'gm_crit_damage', true);
	if(GMBlowsChainActive(skill))
		bonus += GMBlowsValue(skill, 'gm_chain_crit_damage', true);
	return bonus;
}

// The sword effect a chain shows, and whether a skill other than the chain still uses it (Muscle
// Memory's or Strength Training's bonus).
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
		return GMBlowsChainActive(S_Sword_s25) || GMStrengthTrainingStacks() > 0;
	return GMBlowsChainActive(S_Sword_s24) || GMMuscleMemoryArmed();
}

// A melee crit of Geralt's: starts or restarts the chain of its attack type.
@addMethod(W3PlayerWitcher)
function GMBlowsOnCrit(isHeavy : bool)
{
	var skill : ESkill;
	var duration : float;
	var sword : CWitcherSword;

	skill = GMBlowsSkill(isHeavy);
	if(skill == S_SUndefined)
		return;
	duration = GMBlowsValue(skill, 'gm_chain_duration', false);
	if(isHeavy)
		gmCrushingChainEnd = theGame.GetEngineTimeAsSeconds() + duration;
	else
		gmPreciseChainEnd = theGame.GetEngineTimeAsSeconds() + duration;
	sword = GetHeldSwordEntity();
	if(sword)
		sword.PlayEffect(GMBlowsEffectName(isHeavy));
	if(isHeavy)
		AddTimer('GMCrushingChainEnded', duration + 0.05, false);
	else
		AddTimer('GMPreciseChainEnded', duration + 0.05, false);
}

@addMethod(W3PlayerWitcher)
function GMBlowsChainEnded(isHeavy : bool)
{
	var sword : CWitcherSword;

	if(GMSwordBuffInUse(isHeavy))
		return;
	sword = GetHeldSwordEntity();
	if(sword)
		sword.StopEffect(GMBlowsEffectName(isHeavy));
}

@addMethod(W3PlayerWitcher)
timer function GMCrushingChainEnded(dt : float, id : int)
{
	GMBlowsChainEnded(true);
}

@addMethod(W3PlayerWitcher)
timer function GMPreciseChainEnded(dt : float, id : int)
{
	GMBlowsChainEnded(false);
}

// The crit chance for melee fast and strong attacks.
@wrapMethod(W3PlayerWitcher)
function GetCriticalHitChance(isLightAttack : bool, isHeavyAttack : bool, target : CActor, victimMonsterCategory : EMonsterCategory, isBolt : bool) : float
{
	var chance : float;

	chance = wrappedMethod(isLightAttack, isHeavyAttack, target, victimMonsterCategory, isBolt);
	if(!isBolt && (isLightAttack || isHeavyAttack))
		chance += GMBlowsCritChance(isHeavyAttack);
	return chance;
}
