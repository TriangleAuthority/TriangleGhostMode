// SKL-04: Rend, legacy's in both trees (project owner, 2026-10-04 and 2026-10-08): weapon damage
// from its level, from the stamina spent charging and from every adrenaline point (fractions
// included), all pool terms (DMG-04); critical hit chance; it spends all adrenaline on the hit,
// knocks down every enemy it hits, and at 3 adrenaline sends a shock wave that hits every other
// enemy within 3 m for the sword's weapon damage and knocks them down. It ignores armor (the
// ability's armor_reduction). Classic tree: GM_C_sword_s2, 5 levels; new tree: sword_s2, legacy's
// level-5 totals at level 3 (gm_skill_trees.xml, gm_skills.xml).
// See docs/features/skl.md.

function GMIsRendAttack(attackAction : W3Action_Attack) : bool
{
	return attackAction && SkillNameToEnum(attackAction.GetAttackTypeName()) == S_Sword_s02;
}

// Legacy's GetRendPowerBonus: attack_damage_bonus per level, stamina_max_dmg_bonus per level per
// stamina point spent charging, adrenaline_final_damage_bonus per level per adrenaline point.
@addMethod(W3PlayerWitcher)
function GMGetRendPowerBonus() : float
{
	var level : int;
	var bonus, ratio, adrenaline : float;
	var attr : SAbilityAttributeValue;

	level = GetSkillLevel(S_Sword_s02);
	attr = GetSkillAttributeValue(S_Sword_s02, 'attack_damage_bonus', false, true);
	bonus = attr.valueMultiplicative * level;
	ratio = GetSpecialAttackTimeRatio();
	if(ratio > 0)
	{
		attr = GetSkillAttributeValue(S_Sword_s02, 'stamina_max_dmg_bonus', false, true);
		bonus += ratio * GetStatMax(BCS_Stamina) * attr.valueMultiplicative * level;
	}
	adrenaline = GetStat(BCS_Focus);
	if(adrenaline > 0)
	{
		attr = GetSkillAttributeValue(S_Sword_s02, 'adrenaline_final_damage_bonus', false, true);
		bonus += adrenaline * attr.valueMultiplicative * level;
	}
	return bonus;
}

@addMethod(W3PlayerWitcher)
function GMGetRendCritChanceBonus() : float
{
	return CalculateAttributeValue(GetSkillAttributeValue(S_Sword_s02, theGame.params.CRITICAL_HIT_CHANCE, false, true)) * GetSkillLevel(S_Sword_s02);
}

// Rend's critical hit chance, added to the player's (5.x dropped legacy's term from
// ProcessCriticalHitCheck): set for the duration of the check, read by GetCriticalHitChance.
@addField(W3PlayerWitcher)
var gmPendingCritChanceBonus : float;

@addMethod(W3PlayerWitcher)
function GMSetPendingCritChanceBonus(bonus : float)
{
	gmPendingCritChanceBonus = bonus;
}

@wrapMethod(W3DamageManagerProcessor)
function ProcessCriticalHitCheck()
{
	var witcher : W3PlayerWitcher;

	witcher = (W3PlayerWitcher)playerAttacker;
	if(witcher && GMIsRendAttack(attackAction))
		witcher.GMSetPendingCritChanceBonus(witcher.GMGetRendCritChanceBonus());
	wrappedMethod();
	if(witcher)
		witcher.GMSetPendingCritChanceBonus(0);
}

@wrapMethod(W3PlayerWitcher)
function GetCriticalHitChance(isLightAttack : bool, isHeavyAttack : bool, target : CActor, victimMonsterCategory : EMonsterCategory, isBolt : bool) : float
{
	return wrappedMethod(isLightAttack, isHeavyAttack, target, victimMonsterCategory, isBolt) + gmPendingCritChanceBonus;
}

// Every Rend hit knocks down (legacy ProcessOnBeforeHitChecks; a heavy knockdown where the roll
// gives one).
@wrapMethod(W3DamageManagerProcessor)
function ProcessOnBeforeHitChecks()
{
	wrappedMethod();
	if((W3PlayerWitcher)playerAttacker && GMIsRendAttack(attackAction) && !gmWeaponsAreNotDeadly)
		action.AddEffectInfo(EET_KnockdownTypeApplicator);
}

// The shock wave at 3 adrenaline (legacy RendAoE): every other hostile within 3 m of the victim
// takes the sword's weapon damage, scaled by attack power, and is knocked down. Returns the number
// of enemies hit.
@addMethod(W3PlayerWitcher)
function GMRendAoE(attackAction : W3Action_Attack) : int
{
	var dmgTypes : array<name>;
	var dmgValues : array<float>;
	var ents : array<CGameplayEntity>;
	var aoe : W3DamageAction;
	var i, j, hit : int;

	if(GetStat(BCS_Focus) < 3 || !attackAction.victim)
		return 0;
	inv.GetWeaponDTNames(attackAction.GetWeaponId(), dmgTypes);
	for(i = 0; i < dmgTypes.Size(); i += 1)
		dmgValues.PushBack(GetTotalWeaponDamage(attackAction.GetWeaponId(), dmgTypes[i], GetInvalidUniqueId()));
	FindGameplayEntitiesInCylinder(ents, attackAction.victim.GetWorldPosition(), 3, 10, 100, , FLAG_OnlyAliveActors + FLAG_ExcludeTarget + FLAG_Attitude_Hostile, this);
	for(i = 0; i < ents.Size(); i += 1)
	{
		if(ents[i] == attackAction.victim)
			continue;
		aoe = new W3DamageAction in theGame;
		aoe.Initialize(attackAction.attacker, ents[i], attackAction.causer, "RendAoE", EHRT_Heavy, CPS_AttackPower, false, false, false, false);
		aoe.SetCannotReturnDamage(true);
		aoe.SetProcessBuffsIfNoDamage(true);
		for(j = 0; j < dmgTypes.Size(); j += 1)
			aoe.AddDamage(dmgTypes[j], dmgValues[j]);
		aoe.AddEffectInfo(EET_KnockdownTypeApplicator);
		theGame.damageMgr.ProcessAction(aoe);
		ents[i].PlayEffect('yrden_shock');
		delete aoe;
		hit += 1;
	}
	gmLastRendAoEHits = hit;
	return hit;
}

// How many enemies the last shock wave hit, for the tests.
@addField(W3PlayerWitcher)
var gmLastRendAoEHits : int;

// After a Rend hit: the shock wave first (it needs the adrenaline), then all adrenaline is spent,
// fractions included (5.x spends only the whole points the charge reached).
@wrapMethod(W3PlayerWitcher)
function OnProcessActionPost(action : W3DamageAction)
{
	var attackAction : W3Action_Attack;
	var isRend : bool;

	attackAction = (W3Action_Attack)action;
	isRend = attackAction && attackAction.IsActionMelee() && GMIsRendAttack(attackAction);
	if(isRend)
		GMRendAoE(attackAction);
	wrappedMethod(action);
	if(isRend && GetStat(BCS_Focus) > 0)
		DrainFocus(GetStat(BCS_Focus));
}
