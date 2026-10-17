// SKL: the skill tree profile (docs/features/balance.md, "Two skill trees: the plan"). Every
// skill stays one definition (geralt_skills.xml); while the classic tree is in force, the fields
// of Ghost Mode's definitions block GMClassicSkills (gm_skill_trees.xml) replace it, and the
// skills 5.x shares between the trees stop being shared: they are gated by tier points and read
// their values from their own abilities (GM_C_<skill>).
// The game keeps a skill's definition in the save: it reads the XML only for a new character.
// So the profile is applied by the character reset (gmreset), which is also how trees are
// switched, and to a character that has learned nothing yet and has no profile (a new game, or a
// save from before Ghost Mode with no skill bought). The facts gm_skill_tree_set and
// gm_skill_tree_classic record the profile in force.

function GMIsClassicProfileInForce() : bool
{
	return FactsQuerySum("gm_skill_tree_classic") > 0;
}

// The new tree's profile: set by the character reset or for a new character, without the classic
// tree. A character with no profile keeps 5.x's definitions, prerequisites included.
function GMIsNewTreeProfileInForce() : bool
{
	return FactsQuerySum("gm_skill_tree_set") > 0 && FactsQuerySum("gm_skill_tree_classic") < 1;
}

// A skill of 5.x's new tree: one of its new skills or of the skills it shares with the classic tree.
@addMethod(W3PlayerAbilityManager)
function GMIsNewTreeSkill(skill : ESkill) : bool
{
	if(skill <= S_SUndefined || skill >= skills.Size() || skills[skill].skillType != skill || skills[skill].isCoreSkill)
		return false;
	return skills[skill].isReworked || skills[skill].isUnchangedLegacy;
}

// The skills' definitions as the game's XML gives them (the new tree's profile, with the fields of
// Ghost Mode's GMNewTreeSkills block on top: its perks at 1 level, SKL-18). Only with no
// skill learned: levels are rebuilt from Geralt's abilities, as for a new character.
@addMethod(W3PlayerAbilityManager)
function GMRecacheSkillDefinitions()
{
	var skillDefs : array<name>;
	var i : int;

	charStats.GetAbilitiesWithTag('SkillDefinitionName', skillDefs);
	for(i = 0; i < skillDefs.Size(); i += 1)
		CacheSkills(skillDefs[i], skills);
	InitSkills();
	PrecacheModifierSkills();
}

// The classic tree's fields over the cached definitions.
@addMethod(W3PlayerAbilityManager)
function GMOverlayClassicProfile() : int
{
	var i : int;

	// no skill is shared in the classic tree: tier points gate it, the new tree's prerequisites do not
	for(i = 0; i < skills.Size(); i += 1)
	{
		if(skills[i].isUnchangedLegacy)
		{
			skills[i].isUnchangedLegacy = false;
			skills[i].requiredSkills.Clear();
		}
	}

	return GMOverlayProfileBlock('GMClassicSkills');
}

// D59: the new tree's fields over the cached definitions. The new tree drops 5.x's prerequisite tree:
// its skills are gated by tier points in their path instead, drawn by tier (GMNewTreeSkills sets
// both), and its general skills have no gate.
@addMethod(W3PlayerAbilityManager)
function GMOverlayNewTreeProfile() : int
{
	var i : int;

	for(i = 0; i < skills.Size(); i += 1)
	{
		if(GMIsNewTreeSkill(skills[i].skillType))
			skills[i].requiredSkills.Clear();
	}
	return GMOverlayProfileBlock('GMNewTreeSkills');
}

// The fields of one of Ghost Mode's definitions blocks (gm_skill_trees.xml) over the cached
// definitions: GMClassicSkills for the classic tree, GMNewTreeSkills for the new one.
@addMethod(W3PlayerAbilityManager)
function GMOverlayProfileBlock(defName : name) : int
{
	var dm : CDefinitionsManagerAccessor;
	var sks, node : SCustomNode;
	var i, j, applied, tmpInt : int;
	var tmpName : name;
	var tmpString : string;
	var skill : ESkill;

	dm = theGame.GetDefinitionsManager();
	sks = dm.GetCustomDefinition('skills');
	for(i = 0; i < sks.subNodes.Size(); i += 1)
	{
		if(!dm.GetCustomNodeAttributeValueName(sks.subNodes[i], 'def_name', tmpName) || tmpName != defName)
			continue;
		for(j = 0; j < sks.subNodes[i].subNodes.Size(); j += 1)
		{
			node = sks.subNodes[i].subNodes[j];
			dm.GetCustomNodeAttributeValueName(node, 'skill_name', tmpName);
			skill = SkillNameToEnum(tmpName);
			if(skill == S_SUndefined || skills[skill].skillType != skill)
				continue;
			if(dm.GetCustomNodeAttributeValueInt(node, 'maxLevel', tmpInt))
				skills[skill].maxLevel = tmpInt;
			if(dm.GetCustomNodeAttributeValueInt(node, 'requiredPointsSpent', tmpInt))
				skills[skill].requiredPointsSpent = tmpInt;
			if(dm.GetCustomNodeAttributeValueInt(node, 'guiPositionID', tmpInt))
				skills[skill].positionID = tmpInt;
			if(dm.GetCustomNodeAttributeValueInt(node, 'gridRow', tmpInt))
				skills[skill].gridRow = tmpInt;
			if(dm.GetCustomNodeAttributeValueInt(node, 'gridColumn', tmpInt))
				skills[skill].gridColumn = tmpInt;
			if(dm.GetCustomNodeAttributeValueString(node, 'localisationName', tmpString))
				skills[skill].localisationNameKey = tmpString;
			if(dm.GetCustomNodeAttributeValueString(node, 'localisationDescription', tmpString))
				skills[skill].localisationDescriptionKey = tmpString;
			if(dm.GetCustomNodeAttributeValueString(node, 'localisationDescriptionLevel2', tmpString))
				skills[skill].localisationDescriptionLevel2Key = tmpString;
			if(dm.GetCustomNodeAttributeValueString(node, 'localisationDescriptionLevel3', tmpString))
				skills[skill].localisationDescriptionLevel3Key = tmpString;
			if(dm.GetCustomNodeAttributeValueName(node, 'ability_name', tmpName) && IsNameValid(tmpName))
				skills[skill].abilityName = tmpName;
			applied += 1;
		}
	}
	return applied;
}

// Applies the profile of a tree. Call with no skill learned (the character reset does).
@addMethod(W3PlayerAbilityManager)
function GMApplySkillTreeProfile(classicTree : bool) : int
{
	var applied : int;

	GMRecacheSkillDefinitions();
	FactsRemove("gm_skill_tree_classic");
	if(FactsQuerySum("gm_skill_tree_set") < 1)
		FactsAdd("gm_skill_tree_set");
	if(classicTree)
	{
		applied = GMOverlayClassicProfile();
		FactsAdd("gm_skill_tree_classic");
	}
	else
		applied = GMOverlayNewTreeProfile();
	return applied;
}

@addMethod(W3PlayerAbilityManager)
function GMGetSkillAbilityName(skill : ESkill) : name
{
	if(skill > S_SUndefined && skill < skills.Size() && skills[skill].skillType == skill)
		return skills[skill].abilityName;
	return '';
}

// A character with no profile yet that has learned nothing gets the profile of the tree chosen
// in the options: a new game, or an older save with no skill bought. One that has skills keeps
// 5.x's definitions until the character reset.
@addMethod(W3PlayerAbilityManager)
function GMEnsureSkillTreeProfile()
{
	var witcher : W3PlayerWitcher;
	var i, applied : int;

	witcher = (W3PlayerWitcher)owner;
	if(!witcher || !witcher.levelManager || FactsQuerySum("gm_skill_tree_set") > 0)
		return;
	if(witcher.levelManager.GetPointsUsed(ESkillPoint) > 0)
		return;
	for(i = 0; i < skills.Size(); i += 1)
	{
		if(!skills[i].isCoreSkill && skills[i].level > 0)
			return;
	}
	applied = GMApplySkillTreeProfile(GMIsClassicSkillTree());
	LogChannel('GMSkills', "skill tree profile applied to a character without one: classic " + GMIsClassicSkillTree() + ", " + applied + " classic definitions");
}

// After each load 5.x copies the prerequisites, grid positions and string keys of the new and
// shared skills from the XML into the saved definitions: the profile in force goes back on top
// (the new tree's for its names, SKL-19, and its tiers without prerequisites, D59).
@wrapMethod(W3PlayerAbilityManager)
function RemasterCheckAndFixSkillStatsOnLoadedSave()
{
	wrappedMethod();
	if(GMIsClassicProfileInForce())
		GMOverlayClassicProfile();
	else if(FactsQuerySum("gm_skill_tree_set") > 0)
		GMOverlayNewTreeProfile();
}

// A skill's ability, for all code that asks by enum: the profile's ability where it sets one.
@wrapMethod
function SkillEnumToName(s : ESkill) : name
{
	var witcher : W3PlayerWitcher;
	var abilityName : name;

	abilityName = wrappedMethod(s);
	witcher = GetWitcherPlayer();
	if(witcher && witcher.abilityManager && GMIsClassicTreeAbility(witcher.GMGetSkillAbilityName(s)))
		return witcher.GMGetSkillAbilityName(s);
	return abilityName;
}

function GMIsClassicTreeAbility(abilityName : name) : bool
{
	return IsNameValid(abilityName) && StrBeginsWith(NameToString(abilityName), "GM_C_");
}

@addMethod(W3PlayerWitcher)
function GMGetSkillAbilityName(skill : ESkill) : name
{
	return ((W3PlayerAbilityManager)abilityManager).GMGetSkillAbilityName(skill);
}

// A classic-tree ability (GM_C_<skill>) is its skill: found through the definitions in force.
@addMethod(W3PlayerAbilityManager)
function GMGetSkillByAbilityName(abilityName : name) : ESkill
{
	var i : int;

	for(i = 0; i < skills.Size(); i += 1)
	{
		if(skills[i].abilityName == abilityName)
			return skills[i].skillType;
	}
	return S_SUndefined;
}

@wrapMethod
function SkillNameToEnum(n : name) : ESkill
{
	var witcher : W3PlayerWitcher;
	var skill : ESkill;

	skill = wrappedMethod(n);
	if(skill == S_SUndefined && GMIsClassicTreeAbility(n))
	{
		witcher = GetWitcherPlayer();
		if(witcher && witcher.abilityManager)
			return ((W3PlayerAbilityManager)witcher.abilityManager).GMGetSkillByAbilityName(n);
	}
	return skill;
}
