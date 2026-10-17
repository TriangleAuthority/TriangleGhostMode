// SKL-18: Wolf School (perk_26, new tree only), a new design by the project owner (D61): an
// alchemy-themed medium-armor perk in which bombs help sword attacks. After an enemy takes bomb damage
// from Geralt, his melee hits against it with the right oil on the blade get +5% crit chance and +15% crit
// damage per medium armor piece (+20% and +60% with four); bombs deal +7.5% weapon damage per piece (+30%)
// to poisoned enemies (a pool term for a bomb's impact, damage/pool.ws). The window lasts 10 s, restarted
// by further bomb damage. 5.x's armor-piece count adds the perk's ability once per medium piece, so the
// values are Geralt's attribute totals (gm_skills.xml; 5.x's +2% attack power and intensity per piece
// are gone). The crit damage is added in the crit step (damage/formula.ws).
// See docs/features/skl.md.

@addField(CActor)
public var gmWolfWindowEnd : float;

@addMethod(CActor)
function GMSetWolfWindow(endTime : float)
{
	gmWolfWindowEnd = endTime;
}

// Whether a melee hit by Geralt on the target gets the crit bonus: the window is open and the blade has
// the oil for the target's category.
@addMethod(W3PlayerWitcher)
function GMWolfSchoolActive(target : CActor, weaponId : SItemUniqueId, category : EMonsterCategory) : bool
{
	return CanUseSkill(S_Perk_26) && target && theGame.GetEngineTimeAsSeconds() < target.gmWolfWindowEnd
		&& inv.IsIdValid(weaponId) && inv.ItemHasActiveOilApplied(weaponId, category);
}

@addMethod(W3PlayerWitcher)
function GMWolfSchoolValue(attributeName : name) : float
{
	if(!CanUseSkill(S_Perk_26))
		return 0;
	return CalculateAttributeValue(GetAttributeValue(attributeName));
}

// The crit damage for a melee crit (called by the crit step).
@addMethod(W3PlayerWitcher)
function GMWolfSchoolCritDamage(target : CActor, weaponId : SItemUniqueId, category : EMonsterCategory) : float
{
	if(!GMWolfSchoolActive(target, weaponId, category))
		return 0;
	return GMWolfSchoolValue('gm_wolf_crit_damage');
}

// The pool term for a bomb's impact on a poisoned enemy.
@addMethod(W3PlayerWitcher)
function GMWolfSchoolBombBonus(victim : CActor) : float
{
	if(!victim || !(victim.HasBuff(EET_Poison) || victim.HasBuff(EET_PoisonCritical)))
		return 0;
	return GMWolfSchoolValue('gm_wolf_bomb_damage');
}

@wrapMethod(W3PlayerWitcher)
function GetCriticalHitChance(isLightAttack : bool, isHeavyAttack : bool, target : CActor, victimMonsterCategory : EMonsterCategory, isBolt : bool) : float
{
	var chance : float;

	chance = wrappedMethod(isLightAttack, isHeavyAttack, target, victimMonsterCategory, isBolt);
	if(!isBolt && (isLightAttack || isHeavyAttack) && GMWolfSchoolActive(target, GetHeldSword(), victimMonsterCategory))
		chance += GMWolfSchoolValue('gm_wolf_crit_chance');
	return chance;
}

// Bomb damage opens or restarts the window on the enemy.
@wrapMethod(W3PlayerWitcher)
function OnProcessActionPost(action : W3DamageAction)
{
	wrappedMethod(action);
	if(CanUseSkill(S_Perk_26) && (W3Petard)action.causer && action.attacker == this && (CActor)action.victim && action.victim != this && action.DealsAnyDamage())
		((CActor)action.victim).GMSetWolfWindow(theGame.GetEngineTimeAsSeconds() + 10);
}
