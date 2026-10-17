// SKL-19 in-game checks: the skill and perk descriptions. See gmTests.ws for the conventions.

// The menu's own tooltip text for a skill at a level (the wrapped 5.x function and Ghost Mode's
// wrapper), from the open character menu.
@addMethod(CR4CharacterDupeMenu)
function GMTestSkillTooltip(skill : ESkill, level : int) : string
{
	return GetSkillTooltipDescriptionForSkillLevel(thePlayer.GetPlayerSkill(skill), level);
}

// A skill of the tree in force (core skills included). perk_29 and perk_36 do not exist.
function GMTestSkl19InTree(s : SSkill) : bool
{
	var pam : W3PlayerAbilityManager;

	pam = (W3PlayerAbilityManager)GetWitcherPlayer().abilityManager;
	if(s.skillType == S_SUndefined || s.skillType == S_Perk_29 || s.skillType == S_Perk_36)
		return false;
	if(s.isCoreSkill)
		return true;
	if(GMIsClassicProfileInForce())
		return pam.GMIsClassicTreeSkill(s.skillType);
	return s.isReworked || s.isUnchangedLegacy;
}

function GMTestSkl19PathMatches(s : SSkill, path : name) : bool
{
	switch(path)
	{
		case 'sword':	return s.skillPath == ESP_Sword;
		case 'signs':	return s.skillPath == ESP_Signs;
		case 'alchemy':	return s.skillPath == ESP_Alchemy;
		case 'perks':	return s.skillPath == ESP_Perks;
	}
	return true;
}

// What is wrong with a tooltip text: "" if nothing.
function GMTestSkl19Problem(text : string) : string
{
	if(text == "")
		return "empty";
	if(StrFindFirst(text, "$I$") >= 0 || StrFindFirst(text, "$S$") >= 0 || StrFindFirst(text, "$F$") >= 0)
		return "raw argument";
	if(StrFindFirst(text, GetLocStringByKeyExt("focus_gain")) >= 0 || StrFindFirst(text, GetLocStringByKeyExt("attribute_name_staminaregen")) >= 0
		|| StrFindFirst(text, GetLocStringByKeyExt("attribute_potion_duration_time")) >= 0 || StrFindFirst(text, GetLocStringByKeyExt("skill_tree_buff_survival")) >= 0)
		return "passive line";
	if(StrFindFirst(text, "#") == 0)
		return "missing string";
	return "";
}

// With the character menu open (dupemenu()): every skill of the tree in force in one path ('sword',
// 'signs', 'alchemy', 'perks', or 'all'), each level, through the menu's tooltip function. Logs
// "SKL19 <ability> L<level> <name> | <text>" and a FAIL line for an empty text, a raw argument, a
// passive path line or a missing name.
exec function gmtest_skl19_menu(path : name)
{
	var common : CR4CommonMenu;
	var menu : CR4CharacterDupeMenu;
	var skills : array<SSkill>;
	var i, lvl, count, bad : int;
	var text, skillName, problem : string;

	common = (CR4CommonMenu)theGame.GetGuiManager().GetRootMenu();
	if(common)
		menu = (CR4CharacterDupeMenu)common.GetSubMenu();
	if(!menu)
	{
		LogChannel('GMTest', "INFO skl19: the character menu is not open (dupemenu())");
		return;
	}
	skills = thePlayer.GetPlayerSkills();
	for(i = 1; i < skills.Size(); i += 1)
	{
		if(skills[i].skillType != i || !GMTestSkl19InTree(skills[i]) || !GMTestSkl19PathMatches(skills[i], path))
			continue;
		skillName = GetLocStringByKeyExt(skills[i].localisationNameKey);
		for(lvl = 1; lvl <= Max(1, skills[i].maxLevel); lvl += 1)
		{
			text = menu.GMTestSkillTooltip(skills[i].skillType, lvl);
			LogChannel('GMTest', "SKL19 " + skills[i].abilityName + " L" + lvl + " " + skillName + " | " + text);
			problem = GMTestSkl19Problem(text);
			if(skillName == "")
				problem = "no name";
			count += 1;
			if(problem != "")
			{
				bad += 1;
				LogChannel('GMTest', "FAIL skl19 " + skills[i].abilityName + " L" + lvl + ": " + problem);
			}
		}
	}
	LogChannel('GMTest', "SUMMARY skl19 menu " + path + " (classic " + GMIsClassicProfileInForce() + "): " + count + " texts, " + bad + " with problems");
}

// For gmtest_regress(): every Ghost Mode description of the tree in force, each level, has no raw
// argument and every skill of the tree has a name (no menu needed: 5.x's own texts are not read).
function GMTest_skl19()
{
	var skills : array<SSkill>;
	var i, lvl, count, bad : int;
	var text, problems : string;

	skills = thePlayer.GetPlayerSkills();
	for(i = 1; i < skills.Size(); i += 1)
	{
		if(skills[i].skillType != i || !GMTestSkl19InTree(skills[i]))
			continue;
		if(GetLocStringByKeyExt(skills[i].localisationNameKey) == "")
		{
			bad += 1;
			problems += " " + skills[i].abilityName + "(no name)";
		}
		for(lvl = 1; lvl <= Max(1, skills[i].maxLevel); lvl += 1)
		{
			text = GMSkillDescription(skills[i].skillType, lvl);
			if(text == "")
				continue;
			count += 1;
			if(GMTestSkl19Problem(text) != "")
			{
				bad += 1;
				problems += " " + skills[i].abilityName + "(L" + lvl + " " + GMTestSkl19Problem(text) + ")";
			}
		}
	}
	GMTestReport(count > 0 && bad == 0, "SKL-19 descriptions: " + count + " Ghost Mode texts of the tree in force (classic " + GMIsClassicProfileInForce() + "), none with a raw argument, every skill named" + problems);
}

exec function gmtest_skl19()
{
	GMTest_skl19();
}
