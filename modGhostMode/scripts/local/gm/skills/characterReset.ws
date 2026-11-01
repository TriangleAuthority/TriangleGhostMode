// SKL-01 (D44): the character reset. Resets Geralt's development so it can be rebuilt at the
// same level under the rules now in force (a tree switch, a changed skill or progression rule):
// every skill point refunded, mutation research refunded (skill points and greater mutagens),
// skills and skill slots reset, toxicity cleared; level, experience and inventory are kept.
// Built on 5.x's own respec (the Potion of Clearance and the Restoring Potion), not on legacy's
// rebuild of the level, ability and effect managers.
// See docs/features/skl.md.

// The tree chosen in Ghost Mode's options (SKL-02); a character gets it when it is created or
// reset. 5.x's own hidden setting (RemasterCombat/UseLegacySkillTree) is not used: it opens 5.x's
// classic character menu, whose skill grid does not work.
function GMIsClassicSkillTree() : bool
{
	return GMGetOptionBool('GMGameplayOptions', 'GMClassicSkillTree');
}

// Greater mutagens spent on mutation research: red, blue, green.
@addMethod(W3PlayerAbilityManager)
function GMGetMutationsUsedMutagens() : array<int>
{
	var total : array<int>;
	var i : int;

	total.Resize(3);
	for(i = 0; i < mutations.Size(); i += 1)
	{
		total[0] += mutations[i].progress.redUsed;
		total[1] += mutations[i].progress.blueUsed;
		total[2] += mutations[i].progress.greenUsed;
	}
	return total;
}

// Skill points the level definitions give for reaching the current level (5.x: 1 per level).
@addMethod(W3LevelManager)
function GMGetVanillaLevelSkillPoints() : int
{
	var i, total : int;
	var levelDef : SLevelDefinition;

	for(i = 2; i <= level; i += 1)
	{
		levelDef = GetLevelDefinition(i);
		total += levelDef.addedSkillPoints;
	}
	return total;
}

// Skill points the current level is worth in the given tree: the classic tree 1 per level (the level
// definitions), the new tree none on every level divisible by 3 (XP-09, xp/levelUp.ws).
@addMethod(W3LevelManager)
function GMGetLevelSkillPoints(classicTree : bool) : int
{
	var i, total : int;
	var levelDef : SLevelDefinition;

	if(classicTree)
		return GMGetVanillaLevelSkillPoints();
	for(i = 2; i <= level; i += 1)
	{
		levelDef = GetLevelDefinition(i);
		if(!GMIsNewTreeNoPointLevel(i))
			total += levelDef.addedSkillPoints;
	}
	return total;
}

// Sets the level-based skill points and the level abilities (XP-08, XP-09: the Vitality per
// level) to what the tree in force gives for the current level; points from other sources (Places
// of Power, quest items) are kept. The points the levels gave are counted by the rule each level was
// gained under (GMGetGainedLevelSkillPoints). Call with nothing spent.
@addMethod(W3LevelManager)
function GMRecomputeLevelSkillPoints(classicTree : bool)
{
	var other : int;

	other = GetPointsTotal(ESkillPoint) - GMGetGainedLevelSkillPoints();
	if(other < 0)
		return;
	owner.GMSwapLevelAbilities(classicTree);
	points[ESkillPoint].free = other + GMGetLevelSkillPoints(classicTree) - points[ESkillPoint].used;
	LogChannel('GMSkills', "level points recomputed: classic tree " + classicTree + ", " + GMGetLevelSkillPoints(classicTree) + " from levels, " + other + " from other sources");
}

@addMethod(W3PlayerWitcher)
function GMResetCharacter() : bool
{
	var pam : W3PlayerAbilityManager;
	var mutagens : array<int>;

	pam = (W3PlayerAbilityManager)abilityManager;
	// an equipped mutation cannot be removed in combat
	if(!pam || !pam.IsInitialized() || IsInCombat())
		return false;

	mutagens = pam.GMGetMutationsUsedMutagens();

	ResetMutationsDev();
	ResetCharacterDev();

	if(mutagens[0] > 0) inv.AddAnItem('Greater mutagen red', mutagens[0]);
	if(mutagens[1] > 0) inv.AddAnItem('Greater mutagen blue', mutagens[1]);
	if(mutagens[2] > 0) inv.AddAnItem('Greater mutagen green', mutagens[2]);

	// the profile of the tree chosen in the settings: this is how trees are switched
	pam.GMApplySkillTreeProfile(GMIsClassicSkillTree());
	levelManager.GMRecomputeLevelSkillPoints(GMIsClassicSkillTree());
	return true;
}

// Every respec (gmreset(), the Potion of Clearance, 5.x's other callers) empties every skill slot by its ID
// first, locked slots included: 5.x's ResetCharacterDev unequips through GetSkillSlotID, which skips a
// locked slot, and ResetMutationsDev passes slot indexes where UnequipSkill takes IDs, so it misses the
// fourth mutation slot; a skill left there kept its bonuses at level 0.
@addMethod(W3PlayerAbilityManager)
function GMUnequipAllSkillSlots()
{
	var i : int;

	for(i = 0; i < skillSlots.Size(); i += 1)
	{
		if(skillSlots[i].socketedSkill != S_SUndefined)
			UnequipSkill(skillSlots[i].id);	// skills/skillSlots.ws: locked slots too
	}
}

@wrapMethod(W3PlayerAbilityManager)
function ResetCharacterDev()
{
	GMUnequipAllSkillSlots();
	wrappedMethod();
}

// A respec sets toxicity to 0 (legacy), also for the Potion of Clearance.
@wrapMethod(W3PlayerWitcher)
function ResetCharacterDev()
{
	ForceSetStat(BCS_Toxicity, 0);
	wrappedMethod();
}

exec function gmreset()
{
	var witcher : W3PlayerWitcher;

	witcher = GetWitcherPlayer();
	if(witcher && witcher.GMResetCharacter())
	{
		theGame.GetGuiManager().ShowNotification(GetLocStringByKeyExt("panel_character_popup_character_cleared"));
		LogChannel('GMSkills', "character reset: " + witcher.levelManager.GetPointsFree(ESkillPoint) + " skill points free");
	}
	else
		LogChannel('GMSkills', "character reset refused: not Geralt, or in combat");
}
