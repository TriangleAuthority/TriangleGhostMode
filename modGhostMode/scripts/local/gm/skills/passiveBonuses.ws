// SKL-01: the passive path bonuses are removed in both trees (legacy; project owner, 2026-10-04): 5.x
// gives every equipped skill +1% adrenaline gain (sword), +0.5% stamina regeneration (signs), +2%
// potion duration (alchemy, which 5.x also reads for bomb and damage-over-time damage) or +1% maximum
// Vitality (perks) per level. Their abilities' values are 0 (gm_skills.xml), so the copies 5.x still
// adds on equip do nothing; this removes them from Geralt on every load (legacy's OnSpawned cleanup).
// See docs/features/skl.md.

@wrapMethod(W3PlayerWitcher)
function OnSpawned(spawnData : SEntitySpawnData)
{
	wrappedMethod(spawnData);
	RemoveAbilityAll('sword_adrenalinegain');
	RemoveAbilityAll('magic_staminaregen');
	RemoveAbilityAll('alchemy_potionduration');
	RemoveAbilityAll('survival_vitality');
}

// SKL-01, the level sync (legacy): a skill ability tagged GlobalPassiveBonus sits on Geralt once per
// level of the equipped skill. 5.x adds the copies on equip only, so a level bought while the skill is
// equipped added nothing, except for perk_30, 33 and 35, which 5.x tops up itself
// (AdjustAbilitiesOnLevelChange). This sets the count to the level after 5.x's handling, so those
// three are not added twice. In Ghost Mode's profiles every such skill has one level (D49), so this
// matters for a character still on 5.x's definitions (3-level new-tree perks until gmreset()).
@wrapMethod(W3PlayerAbilityManager)
function OnSkillEquippedLevelChange(skill : ESkill, prevLevel : int, currLevel : int)
{
	wrappedMethod(skill, prevLevel, currLevel);
	GMSyncGlobalPassiveSkill(skill, currLevel);
}

@addMethod(W3PlayerAbilityManager)
function GMSyncGlobalPassiveSkill(skill : ESkill, level : int)
{
	var abilityName : name;
	var count : int;

	if(skill == S_SUndefined || IsCoreSkill(skill))
		return;
	abilityName = skills[skill].abilityName;
	if(!theGame.GetDefinitionsManager().AbilityHasTag(abilityName, theGame.params.SKILL_GLOBAL_PASSIVE_TAG))
		return;
	count = owner.GetAbilityCount(abilityName);
	if(count < level)
		owner.AddAbilityMultiple(abilityName, level - count);
	else if(count > level)
		owner.RemoveAbilityMultiple(abilityName, count - level);
}
