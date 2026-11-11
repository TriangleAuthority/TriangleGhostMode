// SKL-18: Wolf School (perk_26) and Viper School (perk_28), the new tree's, new designs by the project owner
// (D61, revised 2026-11-07), per medium armor piece like the other school perks. Geralt's melee hits (fast,
// strong, counters) and crossbow bolts get:
// - Wolf School, against an incapacitated enemy: +10% crit chance and +40% crit damage per piece (+40% and
//   +160% with four);
// - Viper School, against a poisoned or bleeding enemy: +3% and +20% per piece (+12% and +80% with four).
// The two are independent and add up. Incapacitated: the enemy is playing the animation of a stagger, long
// stagger, knockdown, heavy knockdown, ragdoll, a counter's stun or burning (an enemy that burns without that
// animation still acts, and does not count), or is confused by Axii, blinded (Samum, the wraiths' blindness;
// as long as the effect lasts) or frozen (project owner, 2026-11-07). The hit that shatters a freeze removes
// it in the pool step (damage/pool.ws), before the crit roll and the crit damage: the pool records the
// engine time on the victim (gmFrozenShatterTime), and the victim counts as frozen until the next action on
// it starts (the pool resets the mark first) and within 0.1 s (the shattering hit is processed in one go), so
// the shattering hit gets the bonus and the next one does not. 5.x adds a school perk's ability once
// per armor piece of its class, so the values are Geralt's attribute totals (gm_skills.xml). The crit damage
// is added in the crit step (damage/formula.ws).
// See docs/features/skl.md.

@addField(CActor)
var gmFrozenShatterTime : float;

function GMIsIncapacitated(target : CActor) : bool
{
	var cs : CBaseGameplayEffect;

	if(!target)
		return false;
	if(target.HasBuff(EET_Confusion) || target.HasBuff(EET_Blindness) || target.HasBuff(EET_WraithBlindness) || target.HasBuff(EET_Frozen))
		return true;
	if(target.gmFrozenShatterTime >= 0 && theGame.GetEngineTimeAsSeconds() - target.gmFrozenShatterTime < 0.1)
		return true;
	cs = target.GetCurrentlyAnimatedCS();
	if(!cs)
		return false;
	switch(cs.GetEffectType())
	{
		case EET_Stagger :
		case EET_LongStagger :
		case EET_Knockdown :
		case EET_HeavyKnockdown :
		case EET_Ragdoll :
		case EET_CounterStrikeHit :
		case EET_Burning :
			return true;
	}
	return false;
}

function GMIsPoisonedOrBleeding(target : CActor) : bool
{
	return target && (target.HasBuff(EET_Poison) || target.HasBuff(EET_PoisonCritical) || target.HasBuff(EET_Bleeding)
		|| target.HasBuff(EET_Bleeding1) || target.HasBuff(EET_Bleeding2) || target.HasBuff(EET_Bleeding3));
}

// Wolf School's bonus against the target: the attribute's total over the medium pieces, if incapacitated.
@addMethod(W3PlayerWitcher)
function GMWolfSchoolBonus(target : CActor, attributeName : name) : float
{
	if(!CanUseSkill(S_Perk_26) || !GMIsIncapacitated(target))
		return 0;
	return CalculateAttributeValue(GetAttributeValue(attributeName));
}

// Viper School's bonus against the target: the attribute's total over the medium pieces, if poisoned or
// bleeding.
@addMethod(W3PlayerWitcher)
function GMViperSchoolBonus(target : CActor, attributeName : name) : float
{
	if(!CanUseSkill(S_Perk_28) || !GMIsPoisonedOrBleeding(target))
		return 0;
	return CalculateAttributeValue(GetAttributeValue(attributeName));
}

// The crit damage of both perks for a melee or bolt crit (called by the crit step).
@addMethod(W3PlayerWitcher)
function GMWolfViperCritDamage(target : CActor) : float
{
	return GMWolfSchoolBonus(target, 'gm_wolf_crit_damage') + GMViperSchoolBonus(target, 'gm_viper_crit_damage');
}

@wrapMethod(W3PlayerWitcher)
function GetCriticalHitChance(isLightAttack : bool, isHeavyAttack : bool, target : CActor, victimMonsterCategory : EMonsterCategory, isBolt : bool) : float
{
	var chance : float;

	chance = wrappedMethod(isLightAttack, isHeavyAttack, target, victimMonsterCategory, isBolt);
	if(isBolt || isLightAttack || isHeavyAttack)
		chance += GMWolfSchoolBonus(target, 'gm_wolf_crit_chance') + GMViperSchoolBonus(target, 'gm_viper_crit_chance');
	return chance;
}
