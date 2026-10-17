// SKL-18: Focus, legacy's in both trees (D40, D49; classic perk_11, the new tree's perk_37 in place of
// 5.x's Elemental Attunement, whose +3% non-physical damage per level is gone from the pool):
// - each adrenaline point held gives +15% sign intensity (the perk's ability once per point: 5.x's
//   Battle Trance does it for perk_11; for perk_37 the copies are kept in step below);
// - in combat, the stamina a sign costs earns adrenaline as a sword hit does, 0.1 x (1 + adrenaline gain,
//   Razor Focus's included); an alternate cast's per second (Quen's per stamina spent, as a share of a
//   regular cast's cost); none for a cast paid with adrenaline (Rage Management) or under Flood of Anger.
//   Called for each drain (W3PlayerAbilityManager.DrainStamina, stamina/channelStamina.ws), as legacy's
//   ManageFocusGain. Adrenaline Rush (Mutation 7) comes with MUT.
// See docs/features/skl.md.

@addMethod(W3SignEntity)
function GMManageFocusGain(cost : float, dt : float)
{
	var player : W3PlayerWitcher;
	var focus : SAbilityAttributeValue;
	var amount : float;

	player = owner.GetPlayer();
	if(!player || !player.IsInCombat() || !(player.CanUseSkill(S_Perk_11) || player.CanUseSkill(S_Perk_37)) || usedFocus || GMUsedFoA())
		return;
	focus = player.GetAttributeValue('focus_gain');
	if(player.CanUseSkill(S_Sword_s20))
		focus += player.GetSkillAttributeValue(S_Sword_s20, 'focus_gain', false, true) * player.GetSkillLevel(S_Sword_s20);
	amount = 0.1 * (1 + CalculateAttributeValue(focus));
	if(IsAlternateCast() && GetSignType() != ST_Aard)
	{
		if(GetSignType() == ST_Quen)
			amount *= cost / ((W3PlayerAbilityManager)player.GetAbilityManager()).GetSkillStaminaUseCost(S_Magic_4);
		else
			amount *= dt;
	}
	player.GainStat(BCS_Focus, amount);
}

// The new tree's Focus: one copy of its ability per adrenaline point while Battle Trance lasts.
function GMSyncFocusCopies(target : CActor, removeAll : bool)
{
	var witcher : W3PlayerWitcher;
	var abilityName : name;
	var wanted, have : int;

	witcher = (W3PlayerWitcher)target;
	if(!witcher)
		return;
	abilityName = witcher.GetSkillAbilityName(S_Perk_37);
	if(!IsNameValid(abilityName))
		return;
	if(!removeAll && witcher.CanUseSkill(S_Perk_37))
		wanted = FloorF(witcher.GetStat(BCS_Focus));
	have = witcher.GetAbilityCount(abilityName);
	if(wanted > have)
		witcher.AddAbilityMultiple(abilityName, wanted - have);
	else if(wanted < have)
		witcher.RemoveAbilityMultiple(abilityName, have - wanted);
}

@wrapMethod(W3Effect_BattleTrance)
function OnUpdate(deltaTime : float)
{
	var ret : bool;

	ret = wrappedMethod(deltaTime);
	GMSyncFocusCopies(target, false);
	return ret;
}

@wrapMethod(W3Effect_BattleTrance)
function OnEffectRemoved()
{
	var ret : bool;

	ret = wrappedMethod();
	GMSyncFocusCopies(target, true);
	return ret;
}
