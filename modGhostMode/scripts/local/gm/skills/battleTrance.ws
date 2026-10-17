// SKL-07: Battle Trance's adrenaline rules, legacy's in both trees (docs/features/skl.md).
// - Gain only from damage dealt: a melee hit on a hostile gives its adrenaline only if it dealt
//   damage and was not dodged, parried or countered (5.x gives it for any hit). The attack
//   abilities' own focus_gain (attack_light 0.05, the heavy attacks 0.1 and 0.025), which legacy
//   removed, are 0 in the XML (gm_adrenaline.xml), so a hit gives 0.1 x (1 + Razor Focus and the
//   skills' gain).
// - Loss: a hit taken costs the share of maximum Vitality it removed, up to 1 point, reduced by
//   Resolve (W3DamageManagerProcessor.ProcessAction, defense/processAction.ws).
// - Resolve: -100% at maximum level in both trees (classic GM_C_sword_s16, 5 levels, 0.2 per level;
//   the new tree's sword_s16 0.3333 per level).
// - Razor Focus: combat starts with at least focus_add x level adrenaline (1.25 at maximum level; a
//   top-up, not an addition; 5.x: 1 point at every level) and adrenaline gain +focus_gain per level
//   (+25% at maximum level, 5.x's own code: hits and Cold Blood's bolts). Classic GM_C_sword_s20, 5
//   levels (0.25, 0.05); new tree sword_s20 (0.4167, 0.0833).

// Whether an attack of Geralt's earns adrenaline: it dealt damage and was not dodged, parried or
// countered (legacy).
function GMAttackEarnsAdrenaline(attackAction : W3Action_Attack) : bool
{
	return attackAction && attackAction.DealsAnyDamage() && !attackAction.WasDodged() && !attackAction.IsParried() && !attackAction.IsCountered();
}

// 5.x's gain for a melee hit on a hostile (W3PlayerWitcher.OnProcessActionPost, not Rend) is taken
// back when the hit earned none.
@wrapMethod(W3PlayerWitcher)
function OnProcessActionPost(action : W3DamageAction)
{
	var attackAction : W3Action_Attack;
	var actorVictim : CActor;
	var before, gained : float;
	var takeBack : bool;

	attackAction = (W3Action_Attack)action;
	actorVictim = (CActor)action.victim;
	takeBack = attackAction && attackAction.IsActionMelee() && !GMIsRendAttack(attackAction) && actorVictim && IsRequiredAttitudeBetween(this, actorVictim, true) && !GMAttackEarnsAdrenaline(attackAction);
	before = GetStat(BCS_Focus);
	wrappedMethod(action);
	if(takeBack)
	{
		gained = GetStat(BCS_Focus) - before;
		if(gained > 0)
			DrainFocus(gained);
	}
}

// Razor Focus at the start of combat: 5.x's top-up to 1 point is taken back, legacy's to focus_add x
// level is made (the same condition as 5.x's: the skill, and Geralt threatened).
@wrapMethod(W3PlayerWitcher)
function OnCombatStart()
{
	var before, target : float;
	var razorFocus : bool;

	razorFocus = CanUseSkill(S_Sword_s20) && IsThreatened();
	before = GetStat(BCS_Focus);
	wrappedMethod();
	if(razorFocus)
	{
		if(before < 1)
			DrainFocus(1 - before);
		target = CalculateAttributeValue(GetSkillAttributeValue(S_Sword_s20, 'focus_add', false, true)) * GetSkillLevel(S_Sword_s20);
		if(GetStat(BCS_Focus) < target)
			GainStat(BCS_Focus, target - GetStat(BCS_Focus));
	}
}
