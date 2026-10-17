// SKL-02: the classic skill tree in the character menu. 5.x's own classic menu draws no skill
// grid, so the classic tree is shown in the new character menu (CR4CharacterDupeMenu): while the
// classic profile is in force, each skill tab lists the classic tree's skills in legacy's layout
// (a column per branch, a row per tier), without the new tree's connection lines, and locked by
// tier points. The technique is the one of the mod Skill Tree Reforged (invaliduser231, MIT).
// D59: the new tree is drawn the same way, at the positions its profile sets.
// See docs/features/skl.md.

// A skill of the classic tree: every skill that is not one of 5.x's new-tree skills.
@addMethod(W3PlayerAbilityManager)
function GMIsClassicTreeSkill(skill : ESkill) : bool
{
	if(skill == S_SUndefined || skills[skill].skillType != skill || skills[skill].isCoreSkill || skills[skill].isReworked)
		return false;
	return skills[skill].skillSubPath != ESSP_NotSet && skills[skill].skillSubPath != ESSP_Core;
}

// The classic tree's column of a branch, in the new menu's grid units (3 per column).
function GMGetClassicTreeColumn(subPath : ESkillSubPath) : int
{
	switch(subPath)
	{
		case ESSP_Sword_StyleFast:
		case ESSP_Signs_Aard:
		case ESSP_Alchemy_Potions:
		case ESSP_Perks_col1:
			return 0;
		case ESSP_Sword_StyleStrong:
		case ESSP_Signs_Igni:
		case ESSP_Alchemy_Oils:
		case ESSP_Perks_col2:
			return 3;
		case ESSP_Sword_Utility:
		case ESSP_Signs_Yrden:
		case ESSP_Alchemy_Bombs:
		case ESSP_Perks_col3:
			return 6;
		case ESSP_Sword_Crossbow:
		case ESSP_Signs_Quen:
		case ESSP_Alchemy_Mutagens:
		case ESSP_Perks_col4:
			return 9;
	}
	return 12;
}

// The classic tree's row of a skill, in grid units (6 per row): its place among its branch's
// skills, by tier points (general skills: by their menu position).
@addMethod(W3PlayerAbilityManager)
function GMGetClassicTreeRow(skill : ESkill) : int
{
	var i, rank : int;
	var before : bool;

	for(i = 0; i < skills.Size(); i += 1)
	{
		if(i == skill || skills[i].skillSubPath != skills[skill].skillSubPath || !GMIsClassicTreeSkill(skills[i].skillType))
			continue;
		if(skills[skill].skillPath == ESP_Perks)
			before = skills[i].positionID < skills[skill].positionID;
		else
			before = skills[i].requiredPointsSpent < skills[skill].requiredPointsSpent || (skills[i].requiredPointsSpent == skills[skill].requiredPointsSpent && i < skill);
		if(before)
			rank += 1;
	}
	return rank * 6;
}

function GMGetMenuTabSkillPath(tabIndex : int) : ESkillPath
{
	switch(tabIndex)
	{
		case CharacterMenuTab_Sword:	return ESP_Sword;
		case CharacterMenuTab_Signs:	return ESP_Signs;
		case CharacterMenuTab_Alchemy:	return ESP_Alchemy;
		case CharacterMenuTab_Perks:	return ESP_Perks;
	}
	return ESP_NotSet;
}

// A skill tab of the tree in force, without connection lines and locked by tier: the classic
// tree's skills in legacy's layout (SKL-02), or the new tree's at the positions its profile sets
// (D59: a column per legacy branch, a row per tier).
@addMethod(CR4CharacterDupeMenu)
function GMBuildTreeTab(path : ESkillPath, classic : bool) : CScriptedFlashArray
{
	var pam : W3PlayerAbilityManager;
	var playerSkills : array<SSkill>;
	var gfxSkills : CScriptedFlashArray;
	var gfxSkill : CScriptedFlashObject;
	var i : int;

	pam = (W3PlayerAbilityManager)GetWitcherPlayer().abilityManager;
	gfxSkills = m_flashValueStorage.CreateTempFlashArray();
	playerSkills = thePlayer.GetPlayerSkills();

	for(i = 1; i < playerSkills.Size(); i += 1)
	{
		if(playerSkills[i].skillPath != path)
			continue;
		if(classic && !pam.GMIsClassicTreeSkill(playerSkills[i].skillType))
			continue;
		if(!classic && (!pam.GMIsNewTreeSkill(playerSkills[i].skillType) || playerSkills[i].skillSubPath == ESSP_NotSet || playerSkills[i].skillSubPath == ESSP_Core))
			continue;

		gfxSkill = m_flashValueStorage.CreateTempFlashObject();
		GetSkillGFxObject(playerSkills[i], true, gfxSkill);
		if(classic)
		{
			gfxSkill.SetMemberFlashNumber('gridRow', pam.GMGetClassicTreeRow(playerSkills[i].skillType));
			gfxSkill.SetMemberFlashNumber('gridColumn', GMGetClassicTreeColumn(playerSkills[i].skillSubPath));
		}
		gfxSkill.SetMemberFlashArray('skillDependencyRequirements', gfxSkill.CreateFlashArray());
		gfxSkill.SetMemberFlashBool('isUsingSkillDependency', true);
		gfxSkill.SetMemberFlashInt('requiredPointsSpent', playerSkills[i].requiredPointsSpent);
		gfxSkill.SetMemberFlashString('skillPathPoints', IntToString(pam.GetPathPointsSpent(path)));
		if(classic)
			gfxSkill.SetMemberFlashBool('hasRequiredPointsSpent', pam.HasSpentEnoughPoints(playerSkills[i].skillType));
		else
			gfxSkill.SetMemberFlashBool('hasRequiredPointsSpent', pam.GMIsNewTreeTierReached(playerSkills[i].skillType));
		if(path == ESP_Perks)
			gfxSkill.SetMemberFlashInt('perkPosition', playerSkills[i].positionID);
		gfxSkills.PushBackFlashObject(gfxSkill);
	}
	return gfxSkills;
}

@wrapMethod(CR4CharacterDupeMenu)
function PopulateDataForTab(tabIndex : int, entriesArray : CScriptedFlashArray) : void
{
	var entries : CScriptedFlashArray;
	var path : ESkillPath;

	entries = entriesArray;
	path = GMGetMenuTabSkillPath(tabIndex);
	if(path != ESP_NotSet && GMIsClassicProfileInForce())
		entries = GMBuildTreeTab(path, true);
	else if(path != ESP_NotSet && GMIsNewTreeProfileInForce())
		entries = GMBuildTreeTab(path, false);
	wrappedMethod(tabIndex, entries);
}

// With the classic profile in force, 5.x's new-tree skills cannot be bought. With the new tree's
// profile, its skills are gated by tier points in their path (D59; 5.x checks them only for
// classic-only skills).
@wrapMethod(W3PlayerAbilityManager)
function CanLearnSkill(skill : ESkill) : bool
{
	if(skill != S_SUndefined && skills[skill].isReworked && GMIsClassicProfileInForce())
		return false;
	if(GMIsNewTreeProfileInForce() && GMIsNewTreeSkill(skill) && !HasSpentEnoughPoints(skill))
		return false;
	return wrappedMethod(skill);
}

// D59: a new-tree skill is shown unlocked once its tier is reached, or while it has levels (a
// character that bought it before the tier gates keeps it, and can equip it, but buys no further
// level below the tier).
@addMethod(W3PlayerAbilityManager)
function GMIsNewTreeTierReached(skill : ESkill) : bool
{
	return HasSpentEnoughPoints(skill) || skills[skill].level > 0;
}

// The new menu shows a skill as locked through this check: for a classic-tree skill, its tier; for
// a new-tree skill with the new tree's profile, its tier too (D59).
@wrapMethod(W3PlayerAbilityManager)
function IsSkillUnlockedByDependency(skill : ESkill) : bool
{
	if(GMIsClassicProfileInForce() && GMIsClassicTreeSkill(skill))
		return HasSpentEnoughPoints(skill);
	if(GMIsNewTreeProfileInForce() && GMIsNewTreeSkill(skill))
		return GMIsNewTreeTierReached(skill);
	return wrappedMethod(skill);
}
