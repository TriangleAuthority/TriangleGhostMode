// SKL-03: Crippling Strikes, legacy's in both trees (D2): a melee fast attack that deals damage has a
// chance to make the enemy bleed (sword_s5_chance per level, 25% at the maximum level; reduced by
// the enemy's bleeding resistance), legacy's bleeding (1% of maximum health per second, 8 s); and fast
// attacks deal more total damage to bleeding enemies (sword_s5_dmg_boost per level, +25% at the
// maximum level), a final-damage multiplier (DMG-04's exception, GMProcessDamageModification).
// Classic sword_s5 (5 levels), new tree sword_s29 (3 levels); values in gm_skill_trees.xml and
// gm_skills.xml. 5.x's versions are dropped: the classic tree's guaranteed bleeding (50 x level per
// second) and the new tree's crit trigger (+10% damage taken per level for 3 to 6 s).
// See docs/features/skl.md.

// The Crippling Strikes the player has: the classic tree's or the new tree's; S_SUndefined if none.
@addMethod(W3PlayerWitcher)
function GMCripplingStrikesSkill() : ESkill
{
	if(CanUseSkill(S_Sword_s05))
		return S_Sword_s05;
	if(CanUseSkill(S_Sword_s29))
		return S_Sword_s29;
	return S_SUndefined;
}

@addMethod(W3PlayerWitcher)
function GMCripplingStrikesValue(attributeName : name, perLevel : bool) : float
{
	var skill : ESkill;
	var value : float;

	skill = GMCripplingStrikesSkill();
	if(skill == S_SUndefined)
		return 0;
	value = CalculateAttributeValue(GetSkillAttributeValue(skill, attributeName, false, true));
	if(perLevel)
		value *= GetSkillLevel(skill);
	return value;
}

// A melee fast attack of the player's, not with fists.
function GMIsFastMeleeAttack(player : CR4Player, attackAction : W3Action_Attack) : bool
{
	return player && attackAction && attackAction.IsActionMelee() && !player.GetInventory().IsItemFists(attackAction.GetWeaponId())
		&& player.IsLightAttack(attackAction.GetAttackName());
}

// The bleeding roll, after vanilla's reaction to the hit. Vanilla bleeds every classic Crippling
// Strikes hit (source 'sword_s5'); that bleeding is taken back off and legacy's roll made instead,
// under Ghost Mode's own source, so an earlier roll's bleeding is never the one removed.
@wrapMethod(W3DamageManagerProcessor)
function ProcessActionReaction(wasFrozen : bool, wasAlive : bool)
{
	var witcher : W3PlayerWitcher;
	var bleed : SCustomEffectParams;
	var chance, resPt, resPrc : float;

	wrappedMethod(wasFrozen, wasAlive);
	witcher = (W3PlayerWitcher)playerAttacker;
	if(!witcher || !actorVictim || !GMIsFastMeleeAttack(witcher, attackAction) || witcher.GMCripplingStrikesSkill() == S_SUndefined)
		return;
	actorVictim.RemoveBuff(EET_Bleeding, false, "sword_s5");
	if(!actorVictim.IsAlive() || action.IsDoTDamage() || !action.DealtDamage())
		return;
	chance = witcher.GMCripplingStrikesValue('sword_s5_chance', true);
	actorVictim.GetResistValue(theGame.effectMgr.GetBuffResistStat(EET_Bleeding), resPt, resPrc);
	chance *= MaxF(0, 1 - resPrc);
	chance *= witcher.GMMutation12ChanceMult();	// MUT-13, Metamorphosis
	if(RandF() >= chance)
		return;
	bleed.effectType = EET_Bleeding;
	bleed.creator = witcher;
	bleed.sourceName = "GM_CripplingStrikes";
	bleed.duration = witcher.GMCripplingStrikesValue('sword_s5_duration', false);
	bleed.effectValue.valueMultiplicative = witcher.GMCripplingStrikesValue('sword_s5_dmg_per_sec', false);
	actorVictim.AddEffectCustom(bleed);
}

// The final-damage multiplier: a fast attack on a bleeding enemy.
function GMCripplingStrikesDamageMult(player : CR4Player, attackAction : W3Action_Attack, victim : CActor) : float
{
	var witcher : W3PlayerWitcher;

	witcher = (W3PlayerWitcher)player;
	if(!witcher || !victim || !GMIsFastMeleeAttack(witcher, attackAction) || !victim.HasBuff(EET_Bleeding))
		return 1;
	return 1 + witcher.GMCripplingStrikesValue('sword_s5_dmg_boost', true);
}

// 5.x's new-tree Crippling Strike (a crit marks the enemy to take more damage) is replaced by the
// rule above.
@replaceMethod(W3DamageManagerProcessor)
function ProcessNewSkill_CripplingStrikes()
{
	//modSigns: removed 5.x's new-tree Crippling Strike (SKL-03, D2): legacy's Crippling Strikes in both trees
}
