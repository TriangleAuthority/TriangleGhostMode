// SKL-05: Counterattack, legacy's in both trees, level for level (D9). Geralt's hits on the enemy he
// countered (CActor.GMWasCountered(), DEF-07: the counter strike first, at most 3 s) get +0.3333
// attack power per level (+100% at level 3) and +0.35 critical hit chance per level from level 2
// (+70% at level 3); at level 3 a counter has a 5% chance per adrenaline point to knock the attacker
// down (defense/counter.ws). Classic sword_s11, new tree sword_s31, 3 levels each. 5.x's versions are
// taken back off: Counterattack's bonuses on Geralt's next attack on anyone after a counter
// (HasRecentlyCountered; +100% crit at level 3), and the new tree's trigger on a counter or a dodge,
// its crossbow doubling and its unreachable crit.
// See docs/features/skl.md.

// The Counterattack the player has (classic first); S_SUndefined if none.
@addMethod(W3PlayerWitcher)
function GMCounterattackSkill() : ESkill
{
	if(CanUseSkill(S_Sword_s11))
		return S_Sword_s11;
	if(CanUseSkill(S_Sword_s31))
		return S_Sword_s31;
	return S_SUndefined;
}

@addMethod(W3PlayerWitcher)
function GMCounterattackLevel() : int
{
	if(GMCounterattackSkill() == S_SUndefined)
		return 0;
	return GetSkillLevel(GMCounterattackSkill());
}

// The knockdown chance of a counter: 5% per adrenaline point at level 3, from 1 point.
@addMethod(W3PlayerWitcher)
function GMCounterattackKnockdownChance() : float
{
	if(GMCounterattackLevel() < 3 || GetStat(BCS_Focus) < 1)
		return 0;
	return GetStat(BCS_Focus) * CalculateAttributeValue(GetSkillAttributeValue(GMCounterattackSkill(), 's11_knockdown_chance', false, true));
}

// Attack power: vanilla's shares taken off (5.x's GetPowerStatValue lines for sword_s11 and
// sword_s31), legacy's added on the countered enemy.
@wrapMethod(W3Action_Attack)
function GetPowerStatValue() : SAbilityAttributeValue
{
	var result, attr : SAbilityAttributeValue;
	var witcher : W3PlayerWitcher;
	var victimActor : CActor;

	result = wrappedMethod();
	witcher = (W3PlayerWitcher)attacker;
	if(!witcher)
		return result;
	if(witcher.HasRecentlyCountered() && witcher.CanUseSkill(S_Sword_s11))
		result += witcher.GetSkillAttributeValue(S_Sword_s11, PowerStatEnumToName(CPS_AttackPower), false, true) * (-witcher.GetSkillLevel(S_Sword_s11));
	if((witcher.HasRecentlyCountered() || witcher.HasRecentlyDodged()) && witcher.CanUseSkill(S_Sword_s31) && attackName != 'counter_attack_light')
	{
		attr = witcher.GetSkillAttributeValue(S_Sword_s31, PowerStatEnumToName(CPS_AttackPower), false, true) * witcher.GetSkillLevel(S_Sword_s31);
		if(attackName == 'bolt')
		{
			attr.valueMultiplicative *= CalculateAttributeValue(witcher.GetSkillAttributeValue(S_Sword_s31, 'crossbow_multiplier', false, true));
			attr.valueAdditive += result.valueAdditive;
		}
		result += attr * -1;
	}
	victimActor = (CActor)victim;
	if(victimActor && victimActor.GMWasCountered() && witcher.GMCounterattackSkill() != S_SUndefined && IsActionMelee())
		result += witcher.GetSkillAttributeValue(witcher.GMCounterattackSkill(), PowerStatEnumToName(CPS_AttackPower), false, true) * witcher.GMCounterattackLevel();
	return result;
}

// Critical hit chance: legacy's on the countered enemy; 5.x's sword_s11 term (its full value on any
// hit after a counter, at level 3) taken off. 5.x's sword_s31 term needs a level above 3 and never
// applies.
@addField(W3PlayerWitcher)
var gmCounterattackCritCut : float;

@addMethod(W3PlayerWitcher)
function GMSetCounterattackCritCut(cut : float)
{
	gmCounterattackCritCut = cut;
}

@wrapMethod(W3DamageManagerProcessor)
function ProcessCriticalHitCheck()
{
	var witcher : W3PlayerWitcher;

	witcher = (W3PlayerWitcher)playerAttacker;
	if(witcher && attackAction && !action.IsActionWitcherSign() && witcher.HasRecentlyCountered() && witcher.CanUseSkill(S_Sword_s11) && witcher.GetSkillLevel(S_Sword_s11) > 2)
		witcher.GMSetCounterattackCritCut(CalculateAttributeValue(witcher.GetSkillAttributeValue(S_Sword_s11, theGame.params.CRITICAL_HIT_CHANCE, false, true)));
	wrappedMethod();
	if(witcher)
		witcher.GMSetCounterattackCritCut(0);
}

@wrapMethod(W3PlayerWitcher)
function GetCriticalHitChance(isLightAttack : bool, isHeavyAttack : bool, target : CActor, victimMonsterCategory : EMonsterCategory, isBolt : bool) : float
{
	var chance : float;

	chance = wrappedMethod(isLightAttack, isHeavyAttack, target, victimMonsterCategory, isBolt) - gmCounterattackCritCut;
	if(target && target.GMWasCountered() && (isLightAttack || isHeavyAttack) && !isBolt && GMCounterattackLevel() > 1)
		chance += CalculateAttributeValue(GetSkillAttributeValue(GMCounterattackSkill(), theGame.params.CRITICAL_HIT_CHANCE, false, true)) * (GMCounterattackLevel() - 1);
	return chance;
}
