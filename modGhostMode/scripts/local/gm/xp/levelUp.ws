// XP-09: the new tree's skill-point income (docs/features/xp.md; the owner's rule, DX1 (a) and DX2 (a)).
// In the new tree every level divisible by 3 gives no skill point (3, 6, ..., 48, and past 50 51, 54, ...), and levels
// 3 to 48 give +150 Vitality each, the other levels none, no level past 50 any; the classic tree keeps legacy's point
// and +50 Vitality on every level to 50 (XP-08), a point and nothing else past 50. Places of Power, Imlerith's acorn
// and the golden egg give their points in both trees (they call AddPoints, not GainLevel).
//
// The rule follows the tree whose profile Geralt has (SKL-02: the facts the character reset sets), not the option
// alone: the option takes effect at the reset. A character with no profile yet follows the option.
//
// Which rule a level was gained under is recorded by the level ability Geralt holds for it: Lvl<n> (classic, to 50)
// or GMLvlNew<n> (new tree, to 100; abilities/gm_xp.xml, tools/gen_xp.py). The character reset reads them to separate
// the points from levels from the others, then gives the tree in force its own level abilities and level points.
// A save from before this slice holds Lvl<n> for every level: its levels count as classic ones until the reset.

// True while level-ups follow the new tree's rule.
function GMIsNewTreeIncome() : bool
{
	if(FactsQuerySum("gm_skill_tree_set") > 0)
		return !GMIsClassicProfileInForce();
	return !GMIsClassicSkillTree();
}

// XP-09: the levels that give no skill point in the new tree (DX1 (a), DX2 (a)).
function GMIsNewTreeNoPointLevel(lvl : int) : bool
{
	return lvl >= 3 && lvl % 3 == 0;
}

// XP-09: the new tree's level abilities.
@wrapMethod(W3PlayerWitcher)
function GetLevelupAbility(id : int) : name
{
	var ability : name;

	ability = wrappedMethod(id);
	if(id >= 2 && GMIsNewTreeIncome())
		return GMNewTreeLevelAbility(id);
	return ability;
}

// XP-09: in the new tree a level divisible by 3 takes back the point the level definitions just gave.
@wrapMethod(W3LevelManager)
function GainLevel(show : bool) : bool
{
	var gained : bool;
	var levelDef : SLevelDefinition;

	gained = wrappedMethod(show);
	if(gained && GMIsNewTreeIncome() && GMIsNewTreeNoPointLevel(level))
	{
		levelDef = GetLevelDefinition(level);
		if(levelDef.addedSkillPoints > 0)
			points[ESkillPoint].free -= Min(levelDef.addedSkillPoints, points[ESkillPoint].free);
	}
	return gained;
}

// Skill points the levels Geralt has gained gave him, by the rule each was gained under (the level ability he holds
// for it: GMLvlNew<n> for the new tree's).
@addMethod(W3LevelManager)
function GMGetGainedLevelSkillPoints() : int
{
	var i, total : int;
	var levelDef : SLevelDefinition;

	for(i = 2; i <= level; i += 1)
	{
		levelDef = GetLevelDefinition(i);
		if(GMIsNewTreeNoPointLevel(i) && owner.HasAbility(GMNewTreeLevelAbility(i)))
			continue;
		total += levelDef.addedSkillPoints;
	}
	return total;
}

// Gives Geralt the level abilities of the given tree for every level he has (the other tree's taken away), keeping
// his Vitality percentage.
@addMethod(W3PlayerWitcher)
function GMSwapLevelAbilities(classicTree : bool)
{
	var stats : CCharacterStats;
	var i, lvl : int;
	var wanted, other : name;
	var oldMax, cur : float;

	stats = GetCharacterStats();
	lvl = levelManager.GetLevel();
	oldMax = GetStatMax(BCS_Vitality);
	cur = GetStat(BCS_Vitality, true);
	for(i = 2; i <= levelManager.GetMaxLevel(); i += 1)
	{
		if(classicTree)
		{
			wanted = GMClassicLevelAbility(i);
			other = GMNewTreeLevelAbility(i);
		}
		else
		{
			wanted = GMNewTreeLevelAbility(i);
			other = GMClassicLevelAbility(i);
		}
		if(other != '' && stats.GetAbilityCount(other) > 0)
			stats.RemoveAbilityAll(other);
		if(i > lvl && wanted != '' && stats.GetAbilityCount(wanted) > 0)
			stats.RemoveAbilityAll(wanted);
		if(i <= lvl && wanted != '' && stats.GetAbilityCount(wanted) < 1)
			AddAbility(wanted, false);
	}
	UpdateStatMax(BCS_Vitality);
	if(oldMax > 0 && GetStatMax(BCS_Vitality) != oldMax)
		ForceSetStat(BCS_Vitality, MinF(cur * GetStatMax(BCS_Vitality) / oldMax, GetStatMax(BCS_Vitality)));
}
