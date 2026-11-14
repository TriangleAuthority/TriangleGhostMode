// The classic tree as a straight port of legacy Ghost Mode (SKL-02, STAM-10, docs/features/skl.md): with the classic
// profile in force, the tree the menu draws holds only classic-tree skills in legacy's layout, the skills 5.x shares
// between the trees (Rend) and the classic Whirl carry the classic definitions, 5.x's new-tree skills cannot be bought,
// and the new tree's own rules are off (STAM-10's exhaustion even with its option on).
//   GMTest_classic_tree()        in gmtest_regress(): data checks; in the new tree only an INFO line
//   gmtest_classic_tree()        the same on its own
//   gmtest_classic_tree_menu()   with the character menu open (dupemenu() in an earlier call): each tab's entries
//                                as the menu builds them against the classic tree's skills of that path

exec function gmtest_classic_tree()
{
	thePlayer.GMTestCount(true, true);
	GMTest_classic_tree();
	LogChannel('GMTest', "SUMMARY classic tree: " + thePlayer.gmTestPassed + " passed, " + thePlayer.gmTestFailed + " failed");
}

function GMTestClassicPathName(path : ESkillPath) : string
{
	switch(path)
	{
		case ESP_Sword:		return "combat";
		case ESP_Signs:		return "signs";
		case ESP_Alchemy:	return "alchemy";
		case ESP_Perks:		return "general";
	}
	return "?";
}

function GMTestClassicPath(i : int) : ESkillPath
{
	if(i == 0) return ESP_Sword;
	if(i == 1) return ESP_Signs;
	if(i == 2) return ESP_Alchemy;
	return ESP_Perks;
}

// The classic tree's skills of a path, as the menu lists them (GMIsClassicTreeSkill).
function GMTestClassicSkills(path : ESkillPath) : array<ESkill>
{
	var pam : W3PlayerAbilityManager;
	var all : array<SSkill>;
	var res : array<ESkill>;
	var i : int;

	pam = (W3PlayerAbilityManager)thePlayer.abilityManager;
	all = pam.GetPlayerSkills();
	for(i = 1; i < all.Size(); i += 1)
	{
		if(all[i].skillPath == path && pam.GMIsClassicTreeSkill(all[i].skillType))
			res.PushBack(all[i].skillType);
	}
	return res;
}

function GMTest_classic_tree()
{
	var pam : W3PlayerAbilityManager;
	var w : W3PlayerWitcher;
	var skills : array<ESkill>;
	var cells : array<int>;
	var newOnly : array<ESkill>;
	var sk, rend, whirl : SSkill;
	var p, i, cell, row, col, dup, reworked, badCol, total : int;
	var counts, problems, prevOn : string;
	var cfg : CInGameConfigWrapper;
	var stamina, focus : float;

	if(!GMIsClassicProfileInForce())
	{
		LogChannel('GMTest', "INFO classic tree: not in force (new tree's profile " + GMIsNewTreeProfileInForce() + "), checks skipped");
		return;
	}
	w = GetWitcherPlayer();
	pam = (W3PlayerAbilityManager)w.abilityManager;

	// the tree as drawn: classic skills only, a column per branch, no two skills in one cell
	for(p = 0; p < 4; p += 1)
	{
		skills = GMTestClassicSkills(GMTestClassicPath(p));
		cells.Clear();
		for(i = 0; i < skills.Size(); i += 1)
		{
			sk = pam.GetPlayerSkill(skills[i]);
			if(sk.isReworked)
				reworked += 1;
			col = GMGetClassicTreeColumn(sk.skillSubPath);
			row = pam.GMGetClassicTreeRow(skills[i]);
			if(col > 12 || col % 3 != 0)
				badCol += 1;
			cell = row * 100 + col;
			if(cells.Contains(cell))
			{
				dup += 1;
				problems += " " + SkillEnumToName(skills[i]) + "(" + row + "," + col + ")";
			}
			cells.PushBack(cell);
		}
		total += skills.Size();
		counts += " " + GMTestClassicPathName(GMTestClassicPath(p)) + " " + skills.Size();
	}
	GMTestReport(total > 0 && reworked == 0 && dup == 0 && badCol == 0, "classic tree as drawn: " + total + " skills (" + counts + " ), none of 5.x's new-tree skills, each in a cell of its own" + problems);

	// 5.x's new-tree skills: not in the classic tree, cannot be bought (Whirl sword_s35, Muscle Memory to Crushing
	// Blows sword_s22 to s25, Cold Blood sword_s34; the new tree's own designs)
	newOnly.PushBack(S_Sword_s35); newOnly.PushBack(S_Sword_s22); newOnly.PushBack(S_Sword_s23);
	newOnly.PushBack(S_Sword_s24); newOnly.PushBack(S_Sword_s25); newOnly.PushBack(S_Sword_s34);
	w.AddPoints(ESkillPoint, 60, false);
	problems = "";
	for(i = 0; i < newOnly.Size(); i += 1)
	{
		if(pam.GMIsClassicTreeSkill(newOnly[i]) || pam.CanLearnSkill(newOnly[i]))
			problems += " " + SkillEnumToName(newOnly[i]) + "(drawn " + pam.GMIsClassicTreeSkill(newOnly[i]) + ", buyable " + pam.CanLearnSkill(newOnly[i]) + ")";
	}
	GMTestReport(problems == "", "classic tree: the new tree's Whirl, Muscle Memory, Strength Training, Precise Blows, Crushing Blows and Cold Blood are not drawn and cannot be bought with 60 points free" + problems);
	w.levelManager.GMTestRemoveFreeSkillPoints(60);

	// Rend (shared by 5.x's two trees) and Whirl: legacy's classic definitions, drawn in the combat tree
	rend = pam.GetPlayerSkill(S_Sword_s02);
	whirl = pam.GetPlayerSkill(S_Sword_s01);
	skills = GMTestClassicSkills(ESP_Sword);
	GMTestReport(skills.Contains(S_Sword_s02) && rend.maxLevel == 5 && rend.requiredPointsSpent == 8 && rend.abilityName == 'GM_C_sword_s2' && !rend.isUnchangedLegacy && rend.requiredSkills.Size() == 0,
		"classic tree: Rend drawn " + skills.Contains(S_Sword_s02) + ", max level " + rend.maxLevel + " (5), tier " + rend.requiredPointsSpent + " (8), ability " + rend.abilityName + ", shared " + rend.isUnchangedLegacy + ", prerequisites " + rend.requiredSkills.Size());
	GMTestReport(skills.Contains(S_Sword_s01) && whirl.maxLevel == 5 && whirl.requiredPointsSpent == 8 && whirl.requiredSkills.Size() == 0 && !skills.Contains(S_Sword_s35),
		"classic tree: Whirl sword_s1 drawn " + skills.Contains(S_Sword_s01) + ", max level " + whirl.maxLevel + " (5), tier " + whirl.requiredPointsSpent + " (8), prerequisites " + whirl.requiredSkills.Size() + "; sword_s35 drawn " + skills.Contains(S_Sword_s35));

	// STAM-10 (new tree only): off in the classic tree even with its option on
	cfg = theGame.GetInGameConfigWrapper();
	prevOn = cfg.GetVarValue('GMGameplayOptions', 'GMExhaustion');
	stamina = w.GetStat(BCS_Stamina);
	focus = w.GetStat(BCS_Focus);
	cfg.SetVarValue('GMGameplayOptions', 'GMExhaustion', "true");
	GMTestStam10Off(w, "the classic tree in force, the option on");
	cfg.SetVarValue('GMGameplayOptions', 'GMExhaustion', prevOn);
	w.GMExhClear();
	w.ForceSetStat(BCS_Focus, focus);
	w.ForceSetStat(BCS_Stamina, stamina);
	w.ResumeStaminaRegen(StaminaActionTypeToName(ESAT_FixedValue));

	// XP-09 (new tree only): the classic tree's levels give legacy's skill point on every level
	GMTestReport(w.levelManager.GMGetLevelSkillPoints(true) == w.levelManager.GMGetVanillaLevelSkillPoints() && !GMIsNewTreeInForce(),
		"classic tree: points from levels " + w.levelManager.GMGetLevelSkillPoints(true) + " at level " + w.GetLevel() + " (legacy's one per level: " + w.levelManager.GMGetVanillaLevelSkillPoints() + "), new tree's rules in force " + GMIsNewTreeInForce());
}

// Takes back free skill points a check gave (never below 0).
@addMethod(W3LevelManager)
function GMTestRemoveFreeSkillPoints(n : int)
{
	points[ESkillPoint].free = Max(0, points[ESkillPoint].free - n);
}

exec function gmtest_classic_tree_menu()
{
	var common : CR4CommonMenu;
	var menu : CR4CharacterDupeMenu;
	var skills : array<ESkill>;
	var p, built : int;
	var ok : bool;
	var entries : string;

	common = (CR4CommonMenu)theGame.GetGuiManager().GetRootMenu();
	if(common)
		menu = (CR4CharacterDupeMenu)common.GetSubMenu();
	if(!menu || !GMIsClassicProfileInForce())
	{
		LogChannel('GMTest', "FAIL classic tree menu: character menu open " + (bool)menu + ", classic profile " + GMIsClassicProfileInForce());
		return;
	}
	ok = true;
	for(p = 0; p < 4; p += 1)
	{
		skills = GMTestClassicSkills(GMTestClassicPath(p));
		built = menu.GMBuildTreeTab(GMTestClassicPath(p), true).GetLength();
		entries += " " + GMTestClassicPathName(GMTestClassicPath(p)) + " " + built + "/" + skills.Size();
		if(built == 0 || built != skills.Size())
			ok = false;
	}
	LogChannel('GMTest', (ok ? "PASS" : "FAIL") + " classic tree menu: each tab's entries as built, of the classic skills of its path:" + entries);
}
