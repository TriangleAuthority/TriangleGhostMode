// SKL-16: the Mutation skills, legacy's in both trees (D29, D33, D60, project owner, 2026-10-09).
// - Acquired Tolerance (alchemy_s18, 3 levels in both trees): every known potion, bomb, oil, substance and
//   decoction formula gives +1 maximum toxicity, up to 50 per level (5.x: 0.5 per formula of the skill's
//   level or lower). Recounted whenever a formula is learned, the skill changes or a save loads.
// - Tissue Transmutation (alchemy_s13; classic GM_C_alchemy_s13, 5 levels): +2 Vitality per level (new
//   tree 3.33) per point of toxicity offset of active decoctions (5.x: +300 per decoction). Recounted when
//   a decoction starts or ends, the skill changes or a save loads.
// - Adaptation (alchemy_s14; classic GM_C_alchemy_s14, 5 levels): decoction toxicity -4% per level (new
//   tree 6.67%), in the checks before drinking and in the offset applied (skills/metabolismBoosts.ws);
//   5.x's Adaptability (+33% decoction duration per level) is gone (skills/brewing.ws).
// - Synergy (classic alchemy_s19, 5 levels; the new tree's alchemy_s26 in place of Potent Sting): +10% of
//   the mutagen bonus per level (5.x: the classic skill's 3 levels, or the Synergy perk). 5.x adds one copy
//   of the bonus per level; the new tree's level counts as 2, 3 and 5 levels (gm_synergy_levels, rounded),
//   +50% at level 3. The level is applied in MutagensSyngergyBonusUpdate (below; 5.x's Synergy perk, perk_43,
//   passed its own level, and the new tree's perk_43 is Heavy Artillery, SKL-18), and the bonus is refreshed
//   for alchemy_s26 where 5.x refreshes it only for alchemy_s19 and perk_43.
// See docs/features/skl.md.

// Synergy's level for the mutagen bonus: alchemy_s19's, or alchemy_s26's scaled to legacy's 5 levels.
@addMethod(W3PlayerAbilityManager)
function GMSynergyLevel() : int
{
	var witcher : W3PlayerWitcher;

	witcher = (W3PlayerWitcher)owner;
	if(!witcher)
		return 0;
	if(CanUseSkill(S_Alchemy_s19))
		return GetSkillLevel(S_Alchemy_s19);
	if(CanUseSkill(S_Alchemy_s26))
		return RoundMath(GetSkillLevel(S_Alchemy_s26) * CalculateAttributeValue(witcher.GetSkillAttributeValue(S_Alchemy_s26, 'gm_synergy_levels', false, false)));
	return 0;
}

// 5.x's Synergy perk (perk_43) passed its own level to the mutagen bonus; the level is Synergy's
// (alchemy_s19, or the new tree's alchemy_s26), whatever the caller passes.
@wrapMethod(W3PlayerAbilityManager)
function MutagensSyngergyBonusUpdate( skillGroupID : int, skillLevel : int )
{
	wrappedMethod(skillGroupID, GMSynergyLevel());
}

// Whether a recipe counts for Acquired Tolerance (legacy's IsAlchemy18Recipe).
function GMIsAcquiredToleranceRecipe(type : EAlchemyCookedItemType) : bool
{
	return type == EACIT_Potion || type == EACIT_Bomb || type == EACIT_Oil || type == EACIT_Substance || type == EACIT_MutagenPotion;
}

// Acquired Tolerance: one copy of the skill's ability (+1 toxicity) per counted formula, up to 50 per level.
@addMethod(W3PlayerWitcher)
function GMRecalcAcquiredTolerance()
{
	var abilityName : name;
	var names : array<name>;
	var alchemyManager : W3AlchemyManager;
	var recipe : SAlchemyRecipe;
	var i, target, current, maxCount : int;

	abilityName = SkillEnumToName(S_Alchemy_s18);
	target = 0;
	if(CanUseSkill(S_Alchemy_s18))
	{
		maxCount = GetSkillLevel(S_Alchemy_s18) * RoundMath(CalculateAttributeValue(GetSkillAttributeValue(S_Alchemy_s18, 'max_abs_per_lvl_s18', false, false)));
		alchemyManager = new W3AlchemyManager in this;
		alchemyManager.Init();
		names = GetAlchemyRecipes();
		for(i = 0; i < names.Size() && target < maxCount; i += 1)
		{
			alchemyManager.GetRecipe(names[i], recipe);
			if(GMIsAcquiredToleranceRecipe(recipe.cookedItemType) && !GMIsPheromoneRecipe(names[i]))	// ALCH-08: the pheromone formulas are quest formulas in legacy
				target += 1;
		}
		delete alchemyManager;
	}
	current = GetAbilityCount(abilityName);
	if(target > current)
		AddAbilityMultiple(abilityName, target - current);
	else if(target < current)
		RemoveAbilityMultiple(abilityName, current - target);
}

// Tissue Transmutation: one copy of the skill's ability per level per point of toxicity offset.
@addMethod(W3PlayerWitcher)
function GMRecalcTransmutation()
{
	var abilityName : name;
	var target, current : int;

	abilityName = GetSkillAbilityName(S_Alchemy_s13);
	target = 0;
	if(CanUseSkill(S_Alchemy_s13))
		target = RoundMath(GetStat(BCS_Toxicity) - GetStat(BCS_Toxicity, true)) * GetSkillLevel(S_Alchemy_s13);
	current = GetAbilityCount(abilityName);
	if(target > current)
		AddAbilityMultiple(abilityName, target - current);
	else if(target < current)
		RemoveAbilityMultiple(abilityName, current - target);
}

// Adaptation: the share of a decoction's toxicity offset left.
@addMethod(W3PlayerWitcher)
function GMAdaptationMult() : float
{
	var attr : SAbilityAttributeValue;

	if(!CanUseSkill(S_Alchemy_s14))
		return 1;
	attr = GetSkillAttributeValue(S_Alchemy_s14, 'tox_off_bonus', false, false);
	return MaxF(0, 1 - attr.valueMultiplicative * GetSkillLevel(S_Alchemy_s14));
}

// The skill hooks: Acquired Tolerance and Tissue Transmutation recounted, the new tree's Synergy refreshed.
@addMethod(W3PlayerAbilityManager)
function GMMutationSkillChanged(skill : ESkill)
{
	var witcher : W3PlayerWitcher;

	witcher = (W3PlayerWitcher)owner;
	if(!witcher)
		return;
	if(skill == S_Alchemy_s18)
		witcher.GMRecalcAcquiredTolerance();
	else if(skill == S_Alchemy_s13)
		witcher.GMRecalcTransmutation();
	if(skill == S_Alchemy_s26 || CanUseSkill(S_Alchemy_s26))
		MutagensSyngergyBonusUpdate(-1, 0);
	witcher.GMGrassesSkillChanged(skill);	// SKL-17 (skills/grasses.ws)
}

@wrapMethod(W3PlayerAbilityManager)
function OnSkillEquip(skill : ESkill)
{
	wrappedMethod(skill);
	GMMutationSkillChanged(skill);
}

@wrapMethod(W3PlayerAbilityManager)
function OnSkillUnequip(skill : ESkill)
{
	wrappedMethod(skill);
	GMMutationSkillChanged(skill);
}

@wrapMethod(W3PlayerAbilityManager)
function OnSkillEquippedLevelChange(skill : ESkill, prevLevel : int, currLevel : int)
{
	wrappedMethod(skill, prevLevel, currLevel);
	GMMutationSkillChanged(skill);
}

// The new tree's Synergy when a mutagen goes into or out of a slot (5.x refreshes only for alchemy_s19 and
// perk_43).
@wrapMethod(W3PlayerAbilityManager)
function OnSkillMutagenEquipped(item : SItemUniqueId, slot : EEquipmentSlots, prevColor : ESkillColor)
{
	wrappedMethod(item, slot, prevColor);
	if(CanUseSkill(S_Alchemy_s26))
		MutagensSyngergyBonusUpdate(-1, 0);
}

@wrapMethod(W3PlayerAbilityManager)
function OnSkillMutagenUnequipped(out item : SItemUniqueId, slot : EEquipmentSlots, prevColor : ESkillColor, optional dontMerge : bool)
{
	wrappedMethod(item, slot, prevColor, dontMerge);
	if(CanUseSkill(S_Alchemy_s26))
		MutagensSyngergyBonusUpdate(-1, 0);
}

// Acquired Tolerance when a formula is learned.
@wrapMethod(W3PlayerWitcher)
function AddAlchemyRecipe(nam : name, optional isSilent : bool, optional skipTutorialUpdate : bool) : bool
{
	var ret : bool;

	ret = wrappedMethod(nam, isSilent, skipTutorialUpdate);
	GMRecalcAcquiredTolerance();
	return ret;
}

// Tissue Transmutation when a decoction starts or ends (after 5.x's own copies per decoction).
@wrapMethod(W3Mutagen_Effect)
function OnEffectAdded(optional customParams : W3BuffCustomParams)
{
	wrappedMethod(customParams);
	if(GetWitcherPlayer() && target == GetWitcherPlayer())
		GetWitcherPlayer().GMRecalcTransmutation();
}

@wrapMethod(W3Mutagen_Effect)
function OnEffectRemoved()
{
	wrappedMethod();
	if(GetWitcherPlayer() && target == GetWitcherPlayer())
		GetWitcherPlayer().GMRecalcTransmutation();
}

// Both recounted after a load (5.x's ApplyPatchFixes counts Tissue Transmutation per decoction).
@wrapMethod(W3PlayerWitcher)
function OnSpawned(spawnData : SEntitySpawnData)
{
	wrappedMethod(spawnData);
	GMRecalcAcquiredTolerance();
	GMRecalcTransmutation();
}
