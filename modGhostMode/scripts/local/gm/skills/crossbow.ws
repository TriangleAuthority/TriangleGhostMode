// SKL-06: the crossbow skills, legacy's in both trees (D14, project owner, 2026-10-08 and 2026-10-09).
// - Lightning Reflexes: slow motion while aiming the crossbow (classic sword_s13 0.15 per level, 3
//   levels; the new tree's sword_s32 by data alone: 5.x's code multiplies the aiming speed, 0.6, by
//   1 - 0.25 per level, which gives legacy's 0.6 - 0.15 per level exactly). 5.x's headshot damage and
//   instant kill are gone (damage/pool.ws, damage/formula.ws, skills/deadlyPrecision.ws).
// - Anatomical Knowledge: crossbow critical hit chance and damage (classic sword_s7: +5% and +15% per
//   level, 5 levels; new tree sword_s26: +8.33% and +25% per level). The chance of sword_s7 is
//   vanilla's (CR4Player.GetCriticalHitChance); the rest is added here and in the crit damage step.
//   5.x's new-tree silver sword damage on bolts is gone.
// - Crippling Shot: a crossbow critical hit blocks one random monster skill of the victim (classic
//   sword_s12, vanilla's code: 5 s per level, 5 levels; new tree sword_s27: 8.33 s per level). 5.x's
//   new-tree trigger (any critical hit arms the next bolt) is gone.
// - Steady Shot: flat damage added to every damage type of a bolt hit, before the raw-damage pool
//   (legacy's xbow_dmg_bonus: classic sword_s15, 10 per level, 5 levels; the new tree's Cold Blood
//   sword_s34 carries it, 16.67 per level, D13). The pool term is in damage/pool.ws.
// - Cold Blood: a bolt that deals damage gives a sword hit's adrenaline, 0.1 x (1 + adrenaline gain,
//   Razor Focus included), shared by split bolts (classic perk_2, the new tree's sword_s34; D13, D17).
//   5.x's flat adrenaline per bolt (classic sword_s15 0.1 per level, new tree 0.3/0.6/1.0) and
//   perk_2's crossbow attack power (5.x's Steady Shot) are 0 in the XML.
// - Bolts and bombs not thrown from aiming deal half damage (legacy, both trees; the final-damage
//   step, damage/pipeline.ws). 5.x keeps the aimed flag but has no getter for it.
// See docs/features/skl.md.

// Whether this bolt or bomb was thrown from aiming (5.x sets the flag when the aimed throw fires).
@addMethod(CThrowable)
function GMIsFromAimThrow() : bool
{
	return isFromAimThrow;
}

// The Anatomical Knowledge the player has (classic first); S_SUndefined if none.
@addMethod(W3PlayerWitcher)
function GMAnatomicalKnowledgeSkill() : ESkill
{
	if(CanUseSkill(S_Sword_s07))
		return S_Sword_s07;
	if(CanUseSkill(S_Sword_s26))
		return S_Sword_s26;
	return S_SUndefined;
}

// Its critical hit damage bonus for a bolt.
@addMethod(W3PlayerWitcher)
function GMAnatomicalKnowledgeCritDamage() : SAbilityAttributeValue
{
	var skill : ESkill;
	var none : SAbilityAttributeValue;

	skill = GMAnatomicalKnowledgeSkill();
	if(skill == S_SUndefined)
		return none;
	return GetSkillAttributeValue(skill, theGame.params.CRITICAL_HIT_DAMAGE_BONUS, false, true) * GetSkillLevel(skill);
}

// Steady Shot's flat bolt damage (classic sword_s15, or the new tree's Cold Blood sword_s34).
@addMethod(W3PlayerWitcher)
function GMSteadyShotDamage() : float
{
	var skill : ESkill;

	if(CanUseSkill(S_Sword_s15))
		skill = S_Sword_s15;
	else if(CanUseSkill(S_Sword_s34))
		skill = S_Sword_s34;
	else
		return 0;
	return CalculateAttributeValue(GetSkillAttributeValue(skill, 'xbow_dmg_bonus', false, true)) * GetSkillLevel(skill);
}

// Whether Geralt has Cold Blood (the classic perk_2, or the new tree's sword_s34).
@addMethod(W3PlayerWitcher)
function GMHasColdBlood() : bool
{
	return CanUseSkill(S_Perk_02) || CanUseSkill(S_Sword_s34);
}

// Cold Blood's adrenaline for a bolt hit (legacy): a sword hit's, for a bolt that dealt damage and was
// not dodged, parried or countered, nor damage over time; split bolts share it.
@addMethod(W3PlayerWitcher)
function GMColdBloodFocusGain(attackAction : W3Action_Attack) : float
{
	var value : SAbilityAttributeValue;
	var gain : float;
	var splitCount : int;

	if(!attackAction || !attackAction.IsActionRanged() || !GMHasColdBlood())
		return 0;
	if(attackAction.IsDoTDamage() || !attackAction.DealsAnyDamage() || attackAction.WasDodged() || attackAction.IsParried() || attackAction.IsCountered())
		return 0;
	value = GetAttributeValue('focus_gain');
	if(CanUseSkill(S_Sword_s20))
		value += GetSkillAttributeValue(S_Sword_s20, 'focus_gain', false, true) * GetSkillLevel(S_Sword_s20);
	gain = 0.1 * (1 + CalculateAttributeValue(value));
	splitCount = (int)CalculateAttributeValue(inv.GetItemAttributeValue(attackAction.GetWeaponId(), 'split_count'));
	if(splitCount > 0)
		gain /= splitCount;
	return gain;
}

// The new tree's critical hit chance for bolts (the classic skill's is vanilla's).
@wrapMethod(W3PlayerWitcher)
function GetCriticalHitChance(isLightAttack : bool, isHeavyAttack : bool, target : CActor, victimMonsterCategory : EMonsterCategory, isBolt : bool) : float
{
	var chance : float;

	chance = wrappedMethod(isLightAttack, isHeavyAttack, target, victimMonsterCategory, isBolt);
	if(isBolt && !CanUseSkill(S_Sword_s07) && CanUseSkill(S_Sword_s26))
		chance += CalculateAttributeValue(GetSkillAttributeValue(S_Sword_s26, theGame.params.CRITICAL_HIT_CHANCE, false, true)) * GetSkillLevel(S_Sword_s26);
	return chance;
}

// Cold Blood's adrenaline for bolts (both trees). Crippling Shot in the new tree: a crossbow
// critical hit blocks a monster skill, as the classic skill does. 5.x's arming (any critical hit
// arms the next bolt) is undone after each action, so its own block never fires.
@wrapMethod(W3PlayerWitcher)
function OnProcessActionPost(action : W3DamageAction)
{
	var attackAction : W3Action_Attack;
	var actorVictim : CActor;
	var abs : array<name>;
	var dm : CDefinitionsManagerAccessor;
	var i : int;
	var duration, focusGain : float;
	var bolt : W3BoltProjectile;

	wrappedMethod(action);
	ResetCripplingShot();
	attackAction = (W3Action_Attack)action;
	if(attackAction)
	{
		focusGain = GMColdBloodFocusGain(attackAction);
		if(focusGain > 0)
			GainStat(BCS_Focus, focusGain);
	}
	actorVictim = (CActor)action.victim;
	bolt = (W3BoltProjectile)action.causer;
	if(attackAction && actorVictim && attackAction.IsCriticalHit() && bolt && CanUseSkill(S_Sword_s27))
	{
		actorVictim.GetCharacterStats().GetAbilities(abs, false);
		dm = theGame.GetDefinitionsManager();
		for(i = abs.Size() - 1; i >= 0; i -= 1)
		{
			if(!dm.AbilityHasTag(abs[i], theGame.params.TAG_MONSTER_SKILL) || actorVictim.IsAbilityBlocked(abs[i]))
				abs.EraseFast(i);
		}
		if(abs.Size() > 0)
		{
			duration = CalculateAttributeValue(GetSkillAttributeValue(S_Sword_s27, 'duration', true, true)) * GetSkillLevel(S_Sword_s27);
			actorVictim.BlockAbility(abs[RandRange(abs.Size())], true, duration);
		}
	}
}
