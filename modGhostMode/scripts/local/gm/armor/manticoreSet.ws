// ARM-10: the Manticore (Red Wolf) set as legacy.
// - Tier 1 (3 pieces): bombs thrown without delay (5.x already, also its throwing knives) and able to
//   crit (5.x already), with +5% bomb crit chance and +10% bomb crit damage per piece (legacy). The
//   crit damage is a term in DMG's GetAttackersPowerMod (damage/formula.ws).
// - Tier 2 (6 pieces): +1 charge per alchemy item, unchanged (skills/heavyArtilleryTrickShot.ws).
// - The gear's toxicity is legacy's 25 (DA6, ARM-01's item stats); its potion duration is ALCH's.
// See docs/features/arm.md.

// A tier 1 value per piece times the pieces worn; 0 without tier 1.
@addMethod(W3PlayerWitcher)
function GMManticoreBombBonus(attributeName : name) : float
{
	var min, max : SAbilityAttributeValue;

	if(!IsSetBonusActive(EISB_RedWolf_1))
		return 0;
	theGame.GetDefinitionsManager().GetAbilityAttributeValue(GetSetBonusAbility(EISB_RedWolf_1), attributeName, min, max);
	return CalculateAttributeValue(min) * GetSetPartsEquipped(EIST_RedWolf);
}

// A bomb's crit chance with tier 1: Geralt's crit chance as 5.x reads it for bombs, plus the set's.
@addMethod(W3PlayerWitcher)
function GMManticoreBombCritChance(victim : CActor, victimMonsterCategory : EMonsterCategory) : float
{
	return GetCriticalHitChance(false, false, victim, victimMonsterCategory, false) + GMManticoreBombBonus('per_redwolf_piece_crit_chance_bonus');
}

// Tier 1's bombs roll legacy's crit chance here (5.x's roll in ProcessCriticalHitCheck has no per-piece
// term); every other hit goes on to it.
@wrapMethod(W3DamageManagerProcessor)
function ProcessCriticalHitCheck()
{
	var witcher : W3PlayerWitcher;
	var critChance : float;
	var arrStr : array<string>;

	witcher = (W3PlayerWitcher)actorAttacker;
	if(witcher && actorVictim && (W3Petard)action.causer && !action.IsDoTDamage() && !gmWeaponsAreNotDeadly && witcher.IsSetBonusActive(EISB_RedWolf_1)
		&& !(action.IsActionWitcherSign() && witcher.IsMutationActive(EPMT_Mutation2)))
	{
		critChance = witcher.GMManticoreBombCritChance(actorVictim, victimMonsterCategory);
		// Samum's blindness bonus is in GetCriticalHitChance (ALCH-14, legacy's; 5.x's certain crit at level 3 is gone)
		if(RandF() < critChance)
		{
			action.SetCriticalHit();
			arrStr.PushBack(action.attacker.GetDisplayName());
			theGame.witcherLog.AddCombatMessage(theGame.witcherLog.COLOR_GOLD_BEGIN + GetLocStringByKeyExtWithParams("hud_combat_log_critical_hit",,,arrStr) + theGame.witcherLog.COLOR_GOLD_END, action.attacker, NULL);
		}
		return;
	}
	wrappedMethod();
}
