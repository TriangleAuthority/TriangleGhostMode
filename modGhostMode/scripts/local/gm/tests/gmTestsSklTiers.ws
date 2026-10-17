// D59 tests: the new tree's tier gates (docs/skill-trees/skl-decisions.md, D59). Every new-tree skill
// is gated by points spent in its path at its legacy counterpart's tier, scaled x3/5 (sword
// 0/5/12/18, signs 0/4/11/17, alchemy 0/5/12/17), has no prerequisites and is drawn a column per
// legacy branch, a row per tier; the general skills have no gate.

// The new tree's skills of a path, branch by branch (legacy's branch order), each branch by tier.
function GMTestNewTreeTable(path : ESkillPath, out names : array<name>, out points : array<int>)
{
	names.Clear();
	points.Clear();
	if(path == ESP_Sword)
	{
		names.PushBack('sword_s22'); names.PushBack('sword_s35'); names.PushBack('sword_s24'); names.PushBack('sword_s29');
		names.PushBack('sword_s23'); names.PushBack('sword_s2'); names.PushBack('sword_s25'); names.PushBack('sword_s28');
		names.PushBack('sword_s33'); names.PushBack('sword_s36'); names.PushBack('sword_s31'); names.PushBack('sword_s30');
		names.PushBack('sword_s32'); names.PushBack('sword_s34'); names.PushBack('sword_s26'); names.PushBack('sword_s27');
		names.PushBack('sword_s16'); names.PushBack('sword_s18'); names.PushBack('sword_s20'); names.PushBack('sword_s19');
		points.PushBack(0); points.PushBack(5); points.PushBack(12); points.PushBack(18);
	}
	else if(path == ESP_Signs)
	{
		names.PushBack('magic_s20'); names.PushBack('magic_s1'); names.PushBack('magic_s39'); names.PushBack('magic_s33');
		names.PushBack('magic_s8'); names.PushBack('magic_s28'); names.PushBack('magic_s35'); names.PushBack('magic_s41');
		names.PushBack('magic_s42'); names.PushBack('magic_s3'); names.PushBack('magic_s37'); names.PushBack('magic_s11');
		names.PushBack('magic_s13'); names.PushBack('magic_s4'); names.PushBack('magic_s38'); names.PushBack('magic_s40');
		names.PushBack('magic_s17'); names.PushBack('magic_s31'); names.PushBack('magic_s36'); names.PushBack('magic_s19');
		points.PushBack(0); points.PushBack(4); points.PushBack(11); points.PushBack(17);
	}
	else if(path == ESP_Alchemy)
	{
		names.PushBack('alchemy_s24'); names.PushBack('alchemy_s2'); names.PushBack('alchemy_s4'); names.PushBack('alchemy_s3');
		names.PushBack('alchemy_s12'); names.PushBack('alchemy_s5'); names.PushBack('alchemy_s25'); names.PushBack('alchemy_s27');
		names.PushBack('alchemy_s23'); names.PushBack('alchemy_s10'); names.PushBack('alchemy_s8'); names.PushBack('alchemy_s11');
		names.PushBack('alchemy_s18'); names.PushBack('alchemy_s13'); names.PushBack('alchemy_s14'); names.PushBack('alchemy_s26');
		names.PushBack('alchemy_s16'); names.PushBack('alchemy_s20'); names.PushBack('alchemy_s15'); names.PushBack('alchemy_s22');
		points.PushBack(0); points.PushBack(5); points.PushBack(12); points.PushBack(17);
	}
}

function GMTestSklPathName(path : ESkillPath) : string
{
	switch(path)
	{
		case ESP_Sword:		return "combat";
		case ESP_Signs:		return "signs";
		case ESP_Alchemy:	return "alchemy";
	}
	return "general";
}

// Situation-free (regression): the new tree's profile block holds every skill's tier and position.
function GMTest_skl_tiers_xml()
{
	var dm : CDefinitionsManagerAccessor;
	var sks, node : SCustomNode;
	var names : array<name>;
	var points : array<int>;
	var p, i, j, k, found, bad, rps, row, col : int;
	var tmpName : name;
	var problems : string;
	var path : ESkillPath;

	dm = theGame.GetDefinitionsManager();
	sks = dm.GetCustomDefinition('skills');
	for(p = 0; p < 3; p += 1)
	{
		if(p == 0) path = ESP_Sword;
		else if(p == 1) path = ESP_Signs;
		else path = ESP_Alchemy;
		GMTestNewTreeTable(path, names, points);
		for(k = 0; k < names.Size(); k += 1)
		{
			for(i = 0; i < sks.subNodes.Size(); i += 1)
			{
				if(!dm.GetCustomNodeAttributeValueName(sks.subNodes[i], 'def_name', tmpName) || tmpName != 'GMNewTreeSkills')
					continue;
				for(j = 0; j < sks.subNodes[i].subNodes.Size(); j += 1)
				{
					node = sks.subNodes[i].subNodes[j];
					dm.GetCustomNodeAttributeValueName(node, 'skill_name', tmpName);
					if(tmpName != names[k])
						continue;
					found += 1;
					rps = -1; row = -1; col = -1;
					dm.GetCustomNodeAttributeValueInt(node, 'requiredPointsSpent', rps);
					dm.GetCustomNodeAttributeValueInt(node, 'gridRow', row);
					dm.GetCustomNodeAttributeValueInt(node, 'gridColumn', col);
					if(rps != points[k % 4] || row != (k % 4) * 6 || col != (k / 4) * 3)
					{
						bad += 1;
						problems += " " + names[k] + "(" + rps + "," + row + "," + col + ")";
					}
				}
			}
		}
	}
	GMTestReport(found == 60 && bad == 0, "D59 new-tree profile: " + found + " of 60 skills with their scaled tier points and tier positions" + problems);
}

// Buys one level of the first skill of a lower tier that can be bought (a filler, to raise the
// points spent in the path).
function GMTestBuyFiller(witcher : W3PlayerWitcher, names : array<name>, belowTier : int) : bool
{
	var pam : W3PlayerAbilityManager;
	var k : int;
	var skill : ESkill;

	pam = (W3PlayerAbilityManager)witcher.abilityManager;
	for(k = 0; k < names.Size(); k += 1)
	{
		if(k % 4 >= belowTier)
			continue;
		skill = SkillNameToEnum(names[k]);
		if(pam.CanLearnSkill(skill))
		{
			witcher.AddSkill(skill);
			return true;
		}
	}
	return false;
}

// With the new tree's profile in force (option off, then gmreset()), on a character with nothing
// learned: the definitions in force, then for each path every tier refused one point below its
// tier points and allowed at them (bought through the menu's own check, CanLearnSkill, and
// AddSkill), the lock the menu shows (IsSkillUnlockedByDependency), the general skills without a
// gate, and a skill owned above its tier (bought with AddSkill, as an older character may have).
// Spends skill points: gmreset() afterwards.
exec function gmtest_skl_tiers()
{
	var witcher : W3PlayerWitcher;
	var pam : W3PlayerAbilityManager;
	var all : array<SSkill>;
	var names : array<name>;
	var points : array<int>;
	var p, k, tier, bad, refused, allowed : int;
	var skill, owned : ESkill;
	var path : ESkillPath;
	var problems : string;
	var ok : bool;

	witcher = GetWitcherPlayer();
	pam = (W3PlayerAbilityManager)witcher.abilityManager;
	GMTestReport(GMIsNewTreeProfileInForce() && !GMIsClassicProfileInForce(), "D59: the new tree's profile in force");
	if(!GMIsNewTreeProfileInForce())
		return;
	witcher.AddPoints(ESkillPoint, 200, false);

	// the definitions in force
	all = pam.GetPlayerSkills();
	for(p = 0; p < 3; p += 1)
	{
		if(p == 0) path = ESP_Sword;
		else if(p == 1) path = ESP_Signs;
		else path = ESP_Alchemy;
		GMTestNewTreeTable(path, names, points);
		for(k = 0; k < names.Size(); k += 1)
		{
			skill = SkillNameToEnum(names[k]);
			if(all[skill].requiredPointsSpent != points[k % 4] || all[skill].requiredSkills.Size() != 0 || all[skill].gridRow != (k % 4) * 6 || all[skill].gridColumn != (k / 4) * 3 || all[skill].maxLevel != 3 || !pam.GMIsNewTreeSkill(skill))
			{
				bad += 1;
				problems += " " + names[k];
			}
		}
	}
	for(k = 0; k < all.Size(); k += 1)
	{
		if(all[k].skillPath == ESP_Perks && pam.GMIsNewTreeSkill(all[k].skillType) && (all[k].requiredSkills.Size() != 0 || all[k].requiredPointsSpent != 0))
		{
			bad += 1;
			problems += " " + all[k].abilityName;
		}
	}
	GMTestReport(bad == 0, "D59: the 60 skills at their tier points and positions, 3 levels, no prerequisites; general skills without gate or prerequisites" + problems);

	// general skills: a 5.x chain's end can be bought with nothing spent
	GMTestReport(pam.GetPathPointsSpent(ESP_Perks) == 0 && pam.CanLearnSkill(S_Perk_43) && pam.CanLearnSkill(S_Perk_30) && pam.IsSkillUnlockedByDependency(S_Perk_43), "D59: general skills open with nothing spent (perk_43, perk_30: 5.x prerequisites dropped)");

	// a skill owned above its tier stays open (shown unlocked) but gets no further level
	owned = SkillNameToEnum('alchemy_s22');
	witcher.AddSkill(owned);
	GMTestReport(pam.GetSkillLevel(owned) == 1 && pam.GetPathPointsSpent(ESP_Alchemy) == 1 && !pam.CanLearnSkill(owned) && pam.IsSkillUnlockedByDependency(owned), "D59: alchemy_s22 owned at level 1 below its tier (1 of 17 points): shown unlocked, no further level");
	ok = witcher.EquipSkill(owned, witcher.GetFreeSkillSlot());
	GMTestReport(witcher.IsSkillEquipped(owned), "D59: the owned skill can still be equipped");
	witcher.UnequipSkill(witcher.GetSkillSlotID(owned));

	for(p = 0; p < 3; p += 1)
	{
		if(p == 0) path = ESP_Sword;
		else if(p == 1) path = ESP_Signs;
		else path = ESP_Alchemy;
		GMTestNewTreeTable(path, names, points);

		// tier 1 open with nothing spent in the path (alchemy: 1, the owned skill)
		allowed = 0;
		for(k = 0; k < names.Size(); k += 4)
		{
			if(pam.CanLearnSkill(SkillNameToEnum(names[k])) && pam.IsSkillUnlockedByDependency(SkillNameToEnum(names[k])))
				allowed += 1;
		}
		GMTestReport(allowed == 5, "D59 " + GMTestSklPathName(path) + ": the 5 tier-1 skills open with " + pam.GetPathPointsSpent(path) + " points spent");

		for(tier = 1; tier < 4; tier += 1)
		{
			while(pam.GetPathPointsSpent(path) < points[tier] - 1)
			{
				if(!GMTestBuyFiller(witcher, names, tier))
					break;
			}
			refused = 0;
			for(k = tier; k < names.Size(); k += 4)
			{
				skill = SkillNameToEnum(names[k]);
				if(skill == owned)
					continue;
				if(!pam.CanLearnSkill(skill) && !pam.IsSkillUnlockedByDependency(skill))
					refused += 1;
			}
			GMTestBuyFiller(witcher, names, tier);
			allowed = 0;
			for(k = tier; k < names.Size(); k += 4)
			{
				skill = SkillNameToEnum(names[k]);
				if(skill == owned)
					continue;
				if(pam.CanLearnSkill(skill) && pam.IsSkillUnlockedByDependency(skill))
					allowed += 1;
			}
			if(path == ESP_Alchemy && tier == 3)
				ok = refused == 4 && allowed == 4 && pam.CanLearnSkill(owned);
			else
				ok = refused == 5 && allowed == 5;
			GMTestReport(ok && pam.GetPathPointsSpent(path) == points[tier], "D59 " + GMTestSklPathName(path) + ": tier " + (tier + 1) + " refused with " + (points[tier] - 1) + " points (" + refused + " skills), open with " + pam.GetPathPointsSpent(path) + " (" + allowed + " skills)");
		}
	}
	LogChannel('GMTest', "INFO D59: skill points used " + witcher.levelManager.GetPointsUsed(ESkillPoint) + " free " + witcher.levelManager.GetPointsFree(ESkillPoint) + "; run gmreset()");
}

exec function gmtest_skl_tiers_xml()
{
	GMTest_skl_tiers_xml();
}
