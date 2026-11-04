// ALCH-13: 1.32's Werewolf free sprint removed. ALCH-07: Blizzard level 3 makes every stamina drain free during its slow
// motion with 3 adrenaline points, without 5.x's Battle Trance condition (legacy), fixed drains included (Whirl,
// Rend, blocked hits, Quen; audit F4): checked in W3PlayerAbilityManager.GetStaminaActionCost, before 5.x's
// cost and every Ghost Mode multiplier, as legacy did. See docs/features/alch.md.

// ALCH-07 (audit F4): legacy's override (legacy PlayerAbilityManager.ws GetStaminaActionCost): free, with only
// the "Stamina regen delay" option's pause (legacy added it in DrainStamina), while Blizzard 3's slow motion runs
// with 3 adrenaline points (5.x's Mutation 7 toxicity denial is gone: Delayed Recovery's threshold, which it
// read, can never be passed since SKL replaced the skill; whole-port audit A3-4).
class W3PlayerAbilityManager extends W3AbilityManager
{
	public function GetStaminaActionCost(action : EStaminaActionType, out cost : float, out delay : float, optional fixedCost : float, optional fixedDelay : float, optional abilityName : name, optional dt : float, optional costMult : float)	//modSigns
	{	//modSigns
		if(GMBlizzardFreeActions())	//modSigns
		{	//modSigns
			cost = 0;	//modSigns
			delay = MaxF(GMGetOptionFloat('GMGameplayOptions', 'GMStaminaDelay'), 0);	//modSigns
			return;	//modSigns
		}	//modSigns
		super.GetStaminaActionCost(action, cost, delay, fixedCost, fixedDelay, abilityName, dt, costMult);	//modSigns
	}	//modSigns
}

// Blizzard 3's free actions: its slow motion running, 3 adrenaline points.
@addMethod(W3PlayerAbilityManager)
function GMBlizzardFreeActions() : bool
{
	var witcher : W3PlayerWitcher;
	var blizzard : W3Potion_Blizzard;

	witcher = GetWitcherPlayer();
	if(!witcher || owner != witcher || witcher.GetPotionBuffLevel(EET_Blizzard) != 3 || witcher.GetStat(BCS_Focus) < 3)
		return false;
	blizzard = (W3Potion_Blizzard)witcher.GetBuff(EET_Blizzard);
	if(!blizzard)
		return false;
	return blizzard.IsSlowMoActive();
}

// 5.x body; changes marked //modSigns.
@replaceMethod(W3PlayerAbilityManager)
function GetStaminaActionCostInternal(action : EStaminaActionType, isPerSec : bool, out cost : SAbilityAttributeValue, out delay : SAbilityAttributeValue, optional abilityName : name)
{
	var attributeName : name;
	var skill : ESkill;
	//modSigns: removed blizzard, deny, toxicityThreshold (ALCH-07: Blizzard in GetStaminaActionCost)


	super.GetStaminaActionCostInternal(action, isPerSec, cost, delay, abilityName);

	if(isPerSec)
	{
		attributeName = theGame.params.STAMINA_COST_PER_SEC_DEFAULT;
	}
	else
	{
		attributeName = theGame.params.STAMINA_COST_DEFAULT;
	}

	if(action == ESAT_LightAttack && CanUseSkill(S_Sword_1) )
		cost += GetSkillAttributeValue(SkillEnumToName(S_Sword_1), attributeName, false, true);
	else if(action == ESAT_HeavyAttack && CanUseSkill(S_Sword_2) )
		cost += GetSkillAttributeValue(SkillEnumToName(S_Sword_2), attributeName, false, true);
	//modSigns: removed 1.32's Werewolf free sprint and jump out of combat (ALCH-13)



	//modSigns: removed Mutation 7's denial and Blizzard 3's free actions (ALCH-07, audit F4: in GetStaminaActionCost, for every drain)
}
