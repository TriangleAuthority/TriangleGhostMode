// SKL-18: Attack is the Best Defense, legacy's in both trees (D49; classic perk_21, the new tree's
// perk_31): Geralt regains stamina instead of 5.x's adrenaline for parries, counters, dodges and rolls:
// 15% of his maximum stamina when he kills an enemy, 5% for a crit or a counter, with a 2.5 s cooldown
// that a kill ignores (Perk21InternalCooldownEffect; values in gm_skill_trees.xml, gm_skills.xml).
// Triggers: a crit that deals damage by a melee, ranged or sign action (OnProcessActionPost), a kill by
// one of those or a finisher (CNewNPC.OnDeath), a counter (PerformCounterCheck, defense/counter.ws).
// See docs/features/skl.md.

@addMethod(W3PlayerWitcher)
function GMPerk21Skill() : ESkill
{
	if(CanUseSkill(S_Perk_21))
		return S_Perk_21;
	if(CanUseSkill(S_Perk_31))
		return S_Perk_31;
	return S_SUndefined;
}

// Legacy's Perk21GainStamina: 'kill', 'crit' or 'counter'.
@addMethod(W3PlayerWitcher)
function GMPerk21GainStamina(trigger : name)
{
	var skill : ESkill;
	var share : SAbilityAttributeValue;

	skill = GMPerk21Skill();
	if(skill == S_SUndefined || HasBuff(EET_Perk21InternalCooldown) && trigger != 'kill')
		return;
	if(trigger == 'kill')
		share = GetSkillAttributeValue(skill, 'stamina_kill', false, false);
	else
		share = GetSkillAttributeValue(skill, 'stamina_other', false, false);
	GainStat(BCS_Stamina, share.valueMultiplicative * GetStatMax(BCS_Stamina));
	AddEffectDefault(EET_Perk21InternalCooldown, this, "Perk21");
}

// 5.x's adrenaline for parries, counters, dodges and rolls: gone.
@replaceMethod(W3PlayerWitcher)
function GainAdrenalineFromPerk21( n : name )
{
	//modSigns: removed 5.x's Attack is the Best Defense adrenaline (SKL-18: legacy's stamina, GMPerk21GainStamina)
}

@replaceMethod(W3PlayerWitcher)
function GainAdrenalineFromPerk31( n : name )
{
	//modSigns: removed 5.x's new-tree Attack is the Best Defense adrenaline (SKL-18: legacy's stamina, GMPerk21GainStamina)
}

@wrapMethod(W3PlayerWitcher)
function OnProcessActionPost(action : W3DamageAction)
{
	var crit : bool;

	crit = action.IsCriticalHit() && action.DealsAnyDamage() && (CActor)action.victim && (action.IsActionMelee() || action.IsActionRanged() || action.IsActionWitcherSign());
	wrappedMethod(action);
	if(crit && action.attacker == this)
		GMPerk21GainStamina('crit');
}

@wrapMethod(CNewNPC)
function OnDeath( damageAction : W3DamageAction )
{
	var killer : W3PlayerWitcher;
	var ret : bool;

	killer = (W3PlayerWitcher)damageAction.attacker;
	if(killer && killer == GetWitcherPlayer() && (damageAction.IsActionMelee() || damageAction.IsActionRanged() || damageAction.IsActionWitcherSign() || damageAction.GetBuffSourceName() == "Kill" || damageAction.GetBuffSourceName() == "Finisher" || damageAction.GetBuffSourceName() == "AutoFinisher"))
		killer.GMPerk21GainStamina('kill');
	ret = wrappedMethod(damageAction);
	return ret;
}

// The internal cooldown stays 5.x's neutral effect (project owner, 2026-10-16: a buff, not a debuff;
// legacy: negative, SKL audit F32): no debuff icon, and Undying's start and its immunity to negative
// effects leave it alone.
