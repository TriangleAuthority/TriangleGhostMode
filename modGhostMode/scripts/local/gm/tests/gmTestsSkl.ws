// SKL in-game checks. See gmTests.ws for the conventions.

// SKL-01 (D44), the character reset: gmtest_skl01_setup() builds a developed character (skills of
// both trees, a researched and equipped mutation, a skill mutagen, toxicity, skill points that do
// not come from levels) and remembers what the reset must give back; then gmreset(), then
// gmtest_skl01_check(). After a reload the snapshot is gone: the check still verifies the reset
// state and logs the numbers to compare.
@addField(CR4Player)
var gmTestSklSnapshot : bool;
@addField(CR4Player)
var gmTestSklLevel : int;
@addField(CR4Player)
var gmTestSklExp : int;
@addField(CR4Player)
var gmTestSklPoints : int;
@addField(CR4Player)
var gmTestSklMoney : int;
@addField(CR4Player)
var gmTestSklMutagens : array<int>;
@addField(CR4Player)
var gmTestSklSteel : SItemUniqueId;

@addMethod(CR4Player)
function GMTestSklSnapshot(level : int, experience : int, points : int, money : int, mutagens : array<int>, steel : SItemUniqueId)
{
	gmTestSklSnapshot = true;
	gmTestSklLevel = level;
	gmTestSklExp = experience;
	gmTestSklPoints = points;
	gmTestSklMoney = money;
	gmTestSklMutagens = mutagens;
	gmTestSklSteel = steel;
}

// Non-core skills with a level, filled skill slots.
@addMethod(W3PlayerAbilityManager)
function GMTestCountLearnedSkills(out equipped : int) : int
{
	var i, learned : int;

	for(i = 0; i < skills.Size(); i += 1)
	{
		if(!IsCoreSkill(skills[i].skillType) && skills[i].level > 0)
			learned += 1;
	}
	equipped = 0;
	for(i = 0; i < skillSlots.Size(); i += 1)
	{
		if(skillSlots[i].socketedSkill != S_SUndefined)
			equipped += 1;
	}
	return learned;
}

@addMethod(W3PlayerAbilityManager)
function GMTestCountMutationSlotsUnlocked() : int
{
	var i, unlocked : int;

	for(i = 0; i < mutationUnlockedSlotsIndexes.Size(); i += 1)
	{
		if(skillSlots[mutationUnlockedSlotsIndexes[i]].unlocked)
			unlocked += 1;
	}
	return unlocked;
}

function GMTestSklGreaterMutagens() : array<int>
{
	var counts : array<int>;

	counts.PushBack(thePlayer.inv.GetItemQuantityByName('Greater mutagen red'));
	counts.PushBack(thePlayer.inv.GetItemQuantityByName('Greater mutagen blue'));
	counts.PushBack(thePlayer.inv.GetItemQuantityByName('Greater mutagen green'));
	return counts;
}

// Researches a mutation the way the character menu does it (greater mutagens and skill points must be
// at hand); true when it is fully researched.
function GMTestResearchMutation(mut : EPlayerMutationType) : bool
{
	var witcher : W3PlayerWitcher;
	var mutationData : SMutation;
	var progress : SMutationProgress;
	var ids : array<SItemUniqueId>;

	witcher = GetWitcherPlayer();
	witcher.MutationSystemEnable(true);
	mutationData = witcher.GetMutation(mut);
	progress = mutationData.progress;
	if(progress.redRequired > 0)
	{
		ids = witcher.inv.GetItemsByName('Greater mutagen red');
		witcher.MutationResearchWithItem(mut, ids[0], progress.redRequired);
	}
	if(progress.blueRequired > 0)
	{
		ids = witcher.inv.GetItemsByName('Greater mutagen blue');
		witcher.MutationResearchWithItem(mut, ids[0], progress.blueRequired);
	}
	if(progress.greenRequired > 0)
	{
		ids = witcher.inv.GetItemsByName('Greater mutagen green');
		witcher.MutationResearchWithItem(mut, ids[0], progress.greenRequired);
	}
	if(progress.skillpointsRequired > 0)
		witcher.MutationResearchWithSkillPoints(mut, progress.skillpointsRequired);
	return witcher.GetMutationResearchProgress(mut) == 100;
}

exec function gmtest_skl01_setup(optional mutation : int)
{
	var witcher : W3PlayerWitcher;
	var pam : W3PlayerAbilityManager;
	var mut : EPlayerMutationType;
	var progress : SMutationProgress;
	var mutationData : SMutation;
	var ids : array<SItemUniqueId>;
	var steel : SItemUniqueId;
	var mutagens : array<int>;
	var equipped, learned : int;
	var researched : bool;

	witcher = GetWitcherPlayer();
	pam = (W3PlayerAbilityManager)witcher.abilityManager;
	if(mutation == 0)
		mutation = 1;
	mut = mutation;

	// skill points that do not come from levels, and the mutagens research will take
	witcher.AddPoints(ESkillPoint, 40, false);
	witcher.inv.AddAnItem('Greater mutagen red', 12);
	witcher.inv.AddAnItem('Greater mutagen blue', 12);
	witcher.inv.AddAnItem('Greater mutagen green', 12);

	witcher.GetItemEquippedOnSlot(EES_SteelSword, steel);
	mutagens = GMTestSklGreaterMutagens();
	witcher.GMTestSklSnapshot(witcher.GetLevel(), witcher.GetPointsTotal(EExperiencePoint), witcher.GetPointsTotal(ESkillPoint), witcher.inv.GetMoney(), mutagens, steel);

	// skills of both trees, a shared skill, a perk
	skilleq_internal(S_Sword_s21, 0, 3);
	skilleq_internal(S_Sword_s22, 0, 3);
	skilleq_internal(S_Sword_s02, 0, 2);
	skilleq_internal(S_Magic_s20, 0, 1);
	skilleq_internal(S_Alchemy_s01, 0, 1);
	skilleq_internal(S_Perk_01, 0, 1);

	// a mutation researched the way the menu does it, then equipped
	researched = GMTestResearchMutation(mut);
	witcher.SetEquippedMutation(mut);

	// a skill mutagen in a slot, and toxicity
	ids = witcher.inv.GetItemsByName('Greater mutagen red');
	if(ids.Size() > 0)
		witcher.EquipItem(ids[0], EES_SkillMutagen1);
	witcher.GainStat(BCS_Toxicity, 30);

	learned = pam.GMTestCountLearnedSkills(equipped);
	mutationData = witcher.GetMutation(mut);
	progress = mutationData.progress;
	GMTestReport(learned == 6 && equipped > 0, "SKL-01 setup: skills learned " + learned + ", equipped " + equipped);
	GMTestReport(researched && witcher.GetEquippedMutationType() == mut, "SKL-01 setup: mutation " + mut + " researched and equipped (mutagens " + progress.redUsed + "/" + progress.blueUsed + "/" + progress.greenUsed + ", points " + progress.skillpointsUsed + ")");
	GMTestReport(witcher.IsAnyItemEquippedOnSlot(EES_SkillMutagen1), "SKL-01 setup: skill mutagen equipped");
	GMTestReport(witcher.GetStat(BCS_Toxicity) > 0, "SKL-01 setup: toxicity " + witcher.GetStat(BCS_Toxicity));
	LogChannel('GMTest', "INFO SKL-01 setup: classic tree " + GMIsClassicSkillTree() + ", level " + witcher.GetLevel() + ", skill points used " + witcher.levelManager.GetPointsUsed(ESkillPoint) + " free " + witcher.levelManager.GetPointsFree(ESkillPoint) + ", level-based " + witcher.levelManager.GMGetVanillaLevelSkillPoints());
}

exec function gmtest_skl01_check()
{
	var witcher : W3PlayerWitcher;
	var pam : W3PlayerAbilityManager;
	var mutations : array<SMutation>;
	var mutagens : array<int>;
	var steel : SItemUniqueId;
	var i, learned, equipped, pathPoints, researchUsed : int;

	witcher = GetWitcherPlayer();
	pam = (W3PlayerAbilityManager)witcher.abilityManager;

	learned = pam.GMTestCountLearnedSkills(equipped);
	GMTestReport(learned == 0 && equipped == 0, "SKL-01 reset: no skill learned or equipped (" + learned + ", " + equipped + ")");
	pathPoints = pam.GetPathPointsSpent(ESP_Sword) + pam.GetPathPointsSpent(ESP_Signs) + pam.GetPathPointsSpent(ESP_Alchemy) + pam.GetPathPointsSpent(ESP_Perks);
	GMTestReport(pathPoints == 0, "SKL-01 reset: no points spent in any path (" + pathPoints + ")");
	GMTestReport(witcher.levelManager.GetPointsUsed(ESkillPoint) == 0, "SKL-01 reset: no skill point in use (" + witcher.levelManager.GetPointsUsed(ESkillPoint) + ")");

	mutations = pam.GetMutations();
	for(i = 0; i < mutations.Size(); i += 1)
		researchUsed += mutations[i].progress.redUsed + mutations[i].progress.blueUsed + mutations[i].progress.greenUsed + mutations[i].progress.skillpointsUsed;
	GMTestReport(researchUsed == 0 && pam.GetResearchedMutationsCount() == 0, "SKL-01 reset: no mutation research left (" + researchUsed + ", researched " + pam.GetResearchedMutationsCount() + ")");
	GMTestReport(witcher.GetEquippedMutationType() == EPMT_None, "SKL-01 reset: no mutation equipped");
	GMTestReport(pam.GMTestCountMutationSlotsUnlocked() == 0, "SKL-01 reset: mutation skill slots locked (" + pam.GMTestCountMutationSlotsUnlocked() + " unlocked)");
	GMTestReport(pam.IsMutationSystemEnabled(), "SKL-01 reset: mutation system still enabled");

	GMTestReport(!witcher.IsAnyItemEquippedOnSlot(EES_SkillMutagen1), "SKL-01 reset: skill mutagen slot empty");
	GMTestReport(witcher.GetStat(BCS_Toxicity) == 0, "SKL-01 reset: toxicity " + witcher.GetStat(BCS_Toxicity));

	mutagens = GMTestSklGreaterMutagens();
	witcher.GetItemEquippedOnSlot(EES_SteelSword, steel);
	if(thePlayer.gmTestSklSnapshot)
	{
		GMTestReport(witcher.levelManager.GetPointsFree(ESkillPoint) == thePlayer.gmTestSklPoints, "SKL-01 reset: every skill point free again (" + witcher.levelManager.GetPointsFree(ESkillPoint) + " of " + thePlayer.gmTestSklPoints + ")");
		GMTestReport(mutagens[0] == thePlayer.gmTestSklMutagens[0] && mutagens[1] == thePlayer.gmTestSklMutagens[1] && mutagens[2] == thePlayer.gmTestSklMutagens[2], "SKL-01 reset: greater mutagens back (" + mutagens[0] + "/" + mutagens[1] + "/" + mutagens[2] + ")");
		GMTestReport(witcher.GetLevel() == thePlayer.gmTestSklLevel && witcher.GetPointsTotal(EExperiencePoint) == thePlayer.gmTestSklExp, "SKL-01 reset: level and experience kept (" + witcher.GetLevel() + ", " + witcher.GetPointsTotal(EExperiencePoint) + ")");
		GMTestReport(witcher.inv.GetMoney() == thePlayer.gmTestSklMoney && steel == thePlayer.gmTestSklSteel, "SKL-01 reset: money and steel sword kept");
	}
	LogChannel('GMTest', "INFO SKL-01 reset: classic tree " + GMIsClassicSkillTree() + ", level " + witcher.GetLevel() + ", exp " + witcher.GetPointsTotal(EExperiencePoint) + ", skill points free " + witcher.levelManager.GetPointsFree(ESkillPoint) + " (level-based " + witcher.levelManager.GMGetVanillaLevelSkillPoints() + "), greater mutagens " + mutagens[0] + "/" + mutagens[1] + "/" + mutagens[2] + ", steel sword equipped " + witcher.inv.IsIdValid(steel));
}

// The reset is refused in combat (an equipped mutation cannot be removed there).
exec function gmtest_skl01_combat()
{
	var witcher : W3PlayerWitcher;
	var used : int;

	witcher = GetWitcherPlayer();
	used = witcher.levelManager.GetPointsUsed(ESkillPoint);
	if(!witcher.IsInCombat() || used == 0)
	{
		LogChannel('GMTest', "INFO SKL-01 combat: needs combat and spent skill points (combat " + witcher.IsInCombat() + ", used " + used + ")");
		return;
	}
	GMTestReport(!witcher.GMResetCharacter() && witcher.levelManager.GetPointsUsed(ESkillPoint) == used, "SKL-01 reset refused in combat, nothing changed");
}

// A manual save in a new slot, for the reload check.
exec function gmtest_save()
{
	theGame.SaveGame(SGT_Manual, -1);
	LogChannel('GMTest', "INFO manual save requested");
}

// SKL-01: skill slots unlock by level (0, 2, 4, 6, 8, 10, 12, 15, 18, 22, 26, 30), whatever the
// number of skill points. Run at any level, before and after gaining points and after a load.
@addMethod(W3PlayerAbilityManager)
function GMTestCountSkillSlots(level : int, out expected : int) : int
{
	var i, unlocked : int;

	expected = 0;
	for(i = 0; i < skillSlots.Size(); i += 1)
	{
		if(skillSlots[i].groupID == MUTATION_SKILL_GROUP_ID)
			continue;
		if(skillSlots[i].unlocked)
			unlocked += 1;
		if(level >= skillSlots[i].unlockedOnLevel)
			expected += 1;
	}
	return unlocked;
}

exec function gmtest_skl01_slots()
{
	var witcher : W3PlayerWitcher;
	var unlocked, expected : int;

	witcher = GetWitcherPlayer();
	unlocked = ((W3PlayerAbilityManager)witcher.abilityManager).GMTestCountSkillSlots(witcher.GetLevel(), expected);
	GMTestReport(unlocked == expected, "SKL-01 slots: " + unlocked + " unlocked at level " + witcher.GetLevel() + " with " + witcher.GetPointsTotal(ESkillPoint) + " skill points (expected " + expected + ")");
}

// SKL, the skill tree profile (Rend and Whirl): after gmreset() with the tree setting on classic
// (classic = true) or new (false). Checks the definitions in force, then buys Rend and Whirl to
// their maximum level the way the menu does (tier points first) and equips Rend.
exec function gmtest_skl_profile(classic : bool)
{
	var witcher : W3PlayerWitcher;
	var pam : W3PlayerAbilityManager;
	var all : array<SSkill>;
	var rend, whirl, crushing, precise : SSkill;
	var marker : SAbilityAttributeValue;
	var i, maxLevel, tier, rendTier, slot : int;
	var abilityName : name;
	var gated : bool;

	witcher = GetWitcherPlayer();
	pam = (W3PlayerAbilityManager)witcher.abilityManager;
	all = pam.GetPlayerSkills();
	rend = all[S_Sword_s02];
	whirl = all[S_Sword_s01];
	crushing = all[S_Sword_s08];
	precise = all[S_Sword_s17];

	GMTestReport(GMIsClassicProfileInForce() == classic, "SKL profile: classic profile in force " + GMIsClassicProfileInForce());
	if(classic)
	{
		maxLevel = 5;
		tier = 8;
		rendTier = 8;
		abilityName = 'GM_C_sword_s2';
	}
	else
	{
		maxLevel = 3;
		tier = 12;
		rendTier = 5; // D59: the new tree's Rend at legacy's tier 2, scaled
		abilityName = 'sword_s2';
	}
	GMTestReport(rend.maxLevel == maxLevel && rend.requiredPointsSpent == rendTier && rend.isUnchangedLegacy != classic && rend.requiredSkills.Size() == 0, "SKL profile: Rend max level " + rend.maxLevel + ", tier points " + rend.requiredPointsSpent + ", shared " + rend.isUnchangedLegacy + ", prerequisites " + rend.requiredSkills.Size() + ", position " + rend.positionID);
	GMTestReport(rend.abilityName == abilityName && SkillEnumToName(S_Sword_s02) == abilityName && SkillNameToEnum(abilityName) == S_Sword_s02, "SKL profile: Rend's ability " + rend.abilityName + " (by enum " + SkillEnumToName(S_Sword_s02) + ")");
	marker = witcher.GetSkillAttributeValue(S_Sword_s02, 'gm_classic_tree', false, false);
	GMTestReport((marker.valueAdditive == 1) == classic, "SKL profile: Rend's values read from the classic ability: " + (marker.valueAdditive == 1));
	GMTestReport(GetLocStringByKeyExt(rend.localisationNameKey) != "" && GetLocStringByKeyExt(rend.localisationDescriptionKey) != "", "SKL profile: Rend's strings " + rend.localisationNameKey + " = " + GetLocStringByKeyExt(rend.localisationNameKey));
	GMTestReport(whirl.maxLevel == maxLevel && whirl.requiredPointsSpent == tier, "SKL profile: classic Whirl max level " + whirl.maxLevel + ", tier points " + whirl.requiredPointsSpent + ", position " + whirl.positionID);
	if(classic)
		GMTestReport(crushing.maxLevel == 5 && precise.maxLevel == 5 && crushing.requiredPointsSpent == 20 && precise.requiredPointsSpent == 20 && crushing.positionID == 12 && precise.positionID == 31 && rend.positionID == 6 && whirl.positionID == 32, "SKL profile: Crushing Blows and Precise Blows at tier 3, positions swapped with Rend and Whirl");
	else
		GMTestReport(crushing.maxLevel == 3 && precise.maxLevel == 3 && crushing.requiredPointsSpent == 6 && precise.requiredPointsSpent == 6 && crushing.positionID == 6 && precise.positionID == 32 && rend.positionID == 12 && whirl.positionID == 31, "SKL profile: Crushing Blows, Precise Blows, Rend and Whirl as 5.x");

	// legacy's values per level for the classic-only skills
	marker = witcher.GetSkillAttributeValue(S_Sword_s17, 'critical_hit_chance', false, false);
	GMTestReport(AbsF(marker.valueAdditive - 0.02) < 0.0001, "SKL values: Precise Blows critical hit chance per level " + marker.valueAdditive);
	marker = witcher.GetSkillAttributeValue(S_Sword_s17, 'critical_hit_damage_bonus', false, false);
	GMTestReport(AbsF(marker.valueAdditive - 0.15) < 0.0001, "SKL values: Precise Blows critical hit damage per level " + marker.valueAdditive);
	marker = witcher.GetSkillAttributeValue(S_Sword_s08, 'critical_hit_chance', false, false);
	GMTestReport(AbsF(marker.valueAdditive - 0.02) < 0.0001, "SKL values: Crushing Blows critical hit chance per level " + marker.valueAdditive);
	marker = witcher.GetSkillAttributeValue(S_Sword_s08, 'critical_hit_damage_bonus', false, false);
	GMTestReport(AbsF(marker.valueAdditive - 0.15) < 0.0001, "SKL values: Crushing Blows critical hit damage per level " + marker.valueAdditive);
	marker = witcher.GetSkillAttributeValue(S_Sword_s01, 'whirl_dmg_reduction', false, false);
	GMTestReport(AbsF(marker.valueMultiplicative - 0.25) < 0.0001, "SKL values: Whirl damage reduction at level 1 " + marker.valueMultiplicative);

	// tier points gate Rend in both trees (the new tree's since D59)
	gated = !pam.CanLearnSkill(S_Sword_s02) && !pam.CanLearnSkill(S_Sword_s01);
	GMTestReport(gated, "SKL profile: Rend and Whirl cannot be bought with nothing spent");
	for(i = 0; i < 3; i += 1)
	{
		witcher.AddSkill(S_Sword_s21);
		witcher.AddSkill(S_Sword_s04);
		witcher.AddSkill(S_Sword_s16);
	}
	if(classic)
		GMTestReport(pam.GetPathPointsSpent(ESP_Sword) == 9 && pam.CanLearnSkill(S_Sword_s02) && pam.CanLearnSkill(S_Sword_s01), "SKL profile: with 9 points in the path both can be bought");
	else
		GMTestReport(pam.CanLearnSkill(S_Sword_s02) && !pam.CanLearnSkill(S_Sword_s01), "SKL profile: with 9 points in the path the new tree's Rend can be bought (tier 5), the classic Whirl cannot (5.x: 12)");

	for(i = 0; i < 6; i += 1)
	{
		if(pam.GetSkillLevel(S_Sword_s02) < pam.GetSkillMaxLevel(S_Sword_s02))
			witcher.AddSkill(S_Sword_s02);
		if(pam.GetSkillLevel(S_Sword_s01) < pam.GetSkillMaxLevel(S_Sword_s01))
			witcher.AddSkill(S_Sword_s01);
	}
	GMTestReport(pam.GetSkillLevel(S_Sword_s02) == maxLevel && pam.GetSkillLevel(S_Sword_s01) == maxLevel && !pam.CanLearnSkill(S_Sword_s02), "SKL profile: Rend level " + pam.GetSkillLevel(S_Sword_s02) + ", Whirl level " + pam.GetSkillLevel(S_Sword_s01) + ", no further level");
	slot = witcher.GetFreeSkillSlot();
	witcher.EquipSkill(S_Sword_s02, slot);
	GMTestReport(pam.GMTestCountSkillAbility(abilityName) == maxLevel && pam.GMTestCountSkillAbility('sword_s2') + pam.GMTestCountSkillAbility('GM_C_sword_s2') == maxLevel, "SKL profile: equipped Rend gives " + pam.GMTestCountSkillAbility(abilityName) + " x " + abilityName);
	LogChannel('GMTest', "INFO SKL profile: skill points used " + witcher.levelManager.GetPointsUsed(ESkillPoint) + " free " + witcher.levelManager.GetPointsFree(ESkillPoint));
}

// The same state read back, without buying anything (after a reload).
exec function gmtest_skl_profile_read()
{
	var witcher : W3PlayerWitcher;
	var all : array<SSkill>;
	var rend, whirl : SSkill;

	witcher = GetWitcherPlayer();
	all = ((W3PlayerAbilityManager)witcher.abilityManager).GetPlayerSkills();
	rend = all[S_Sword_s02];
	whirl = all[S_Sword_s01];
	LogChannel('GMTest', "INFO SKL profile read: classic " + GMIsClassicProfileInForce() + "; Rend level " + rend.level + "/" + rend.maxLevel + ", tier " + rend.requiredPointsSpent + ", shared " + rend.isUnchangedLegacy + ", prerequisites " + rend.requiredSkills.Size() + ", ability " + rend.abilityName + " x " + ((W3PlayerAbilityManager)witcher.abilityManager).GMTestCountSkillAbility(rend.abilityName) + ", name key " + rend.localisationNameKey + ", position " + rend.positionID + "; Whirl level " + whirl.level + "/" + whirl.maxLevel + ", tier " + whirl.requiredPointsSpent + ", position " + whirl.positionID);
}

// SKL-02, a new game's profile: Rend's definition matches the profile in force (gmreset() before, either tree).
function GMTestSkl02RendInProfile(pam : W3PlayerAbilityManager, label : string)
{
	var rend : SSkill;

	rend = pam.GetPlayerSkill(S_Sword_s02);
	if(GMIsClassicProfileInForce())
		GMTestReport(rend.maxLevel == 5 && rend.requiredPointsSpent == 8 && rend.positionID == 6 && rend.abilityName == 'GM_C_sword_s2' && !rend.isUnchangedLegacy && rend.requiredSkills.Size() == 0, "SKL-02 " + label + ": the classic profile's Rend (max level " + rend.maxLevel + ", tier " + rend.requiredPointsSpent + ", position " + rend.positionID + ", ability " + rend.abilityName + ", shared " + rend.isUnchangedLegacy + ", prerequisites " + rend.requiredSkills.Size() + ")");
	else
		GMTestReport(GMIsNewTreeProfileInForce() && rend.maxLevel == 3 && rend.requiredPointsSpent == 5 && rend.gridRow == 6 && rend.gridColumn == 3 && rend.requiredSkills.Size() == 0, "SKL-02 " + label + ": the new tree's profile in force " + GMIsNewTreeProfileInForce() + ", Rend tier " + rend.requiredPointsSpent + ", row " + rend.gridRow + ", column " + rend.gridColumn + ", prerequisites " + rend.requiredSkills.Size() + " (5.x: tier 12, row 18, 3 prerequisites)");
}

// Rend's definition as 5.x's XML gives it, its level kept: what a re-read of the XML leaves.
@addMethod(W3PlayerAbilityManager)
function GMTestSkl02RendFromXml()
{
	var skillDefs : array<name>;
	var fresh : array<SSkill>;
	var i, level : int;

	charStats.GetAbilitiesWithTag('SkillDefinitionName', skillDefs);
	for(i = 0; i < skillDefs.Size(); i += 1)
		CacheSkills(skillDefs[i], fresh);
	level = skills[S_Sword_s02].level;
	skills[S_Sword_s02] = fresh[S_Sword_s02];
	skills[S_Sword_s02].level = level;
}

// SKL-02, a new game's profile (2026-11-07): 5.x's one-time skill point fix (NGEFixSkillPoints), which runs
// 1 s after every new game's spawn, re-read the definitions from the XML after the profile was applied and
// kept its facts: a new character showed 5.x's tree. Called first in the regression, right after
// gmreset() (nothing learned: the fix re-adds learned skills capped at level 3). Then the load's recovery:
// Rend's definition set back to the XML's, and the spawn and load check (PostInit) lays the profile on again.
function GMTest_skl02_newgame()
{
	var witcher : W3PlayerWitcher;
	var pam : W3PlayerAbilityManager;
	var all : array<SSkill>;
	var i, learned, free, used : int;

	witcher = GetWitcherPlayer();
	pam = (W3PlayerAbilityManager)witcher.abilityManager;
	all = pam.GetPlayerSkills();
	for(i = 0; i < all.Size(); i += 1)
	{
		if(!all[i].isCoreSkill && all[i].level > 0)
			learned += 1;
	}
	if(learned > 0)
	{
		GMTestReport(false, "SKL-02 new game: not run, " + learned + " skills learned (run right after gmreset())");
		return;
	}
	free = witcher.levelManager.GetPointsFree(ESkillPoint);
	used = witcher.levelManager.GetPointsUsed(ESkillPoint);
	pam.NGEFixSkillPoints();
	GMTestSkl02RendInProfile(pam, "after 5.x's new-game skill point fix");
	GMTestReport(witcher.levelManager.GetPointsFree(ESkillPoint) == free && witcher.levelManager.GetPointsUsed(ESkillPoint) == used, "SKL-02 new game: skill points kept by the fix (free " + witcher.levelManager.GetPointsFree(ESkillPoint) + ", used " + witcher.levelManager.GetPointsUsed(ESkillPoint) + ")");

	pam.GMTestSkl02RendFromXml();
	pam.GMEnsureSkillTreeProfile();
	GMTestSkl02RendInProfile(pam, "a save with the profile's facts over 5.x's definitions, at load");
	if(!GMIsClassicProfileInForce())
		GMTest_skl02_tree_read();
}

// SKL-02, the new tree as the menu draws it, read only (for a player's save too: nothing bought, nothing
// changed): every new-tree skill of the three paths at its tier points, row and column, without
// prerequisites (D59), and the new tree's profile in force (the menu then builds its tabs by GMBuildTreeTab).
// With the character menu open (dupemenu() in an earlier call), also the entries of each tab it builds.
function GMTest_skl02_tree_read()
{
	var pam : W3PlayerAbilityManager;
	var common : CR4CommonMenu;
	var menu : CR4CharacterDupeMenu;
	var names : array<name>;
	var points : array<int>;
	var sk : SSkill;
	var p, k, found, bad : int;
	var problems, entries : string;
	var path : ESkillPath;

	if(!GMIsNewTreeProfileInForce())
	{
		GMTestReport(false, "SKL-02 the new tree as drawn: the new tree's profile is not in force (classic " + GMIsClassicProfileInForce() + ", set " + FactsQuerySum("gm_skill_tree_set") + ")");
		return;
	}
	pam = (W3PlayerAbilityManager)thePlayer.abilityManager;
	common = (CR4CommonMenu)theGame.GetGuiManager().GetRootMenu();
	if(common)
		menu = (CR4CharacterDupeMenu)common.GetSubMenu();
	for(p = 0; p < 3; p += 1)
	{
		if(p == 0) path = ESP_Sword;
		else if(p == 1) path = ESP_Signs;
		else path = ESP_Alchemy;
		GMTestNewTreeTable(path, names, points);
		for(k = 0; k < names.Size(); k += 1)
		{
			sk = pam.GetPlayerSkill(SkillNameToEnum(names[k]));
			found += 1;
			if(sk.requiredPointsSpent != points[k % 4] || sk.gridRow != (k % 4) * 6 || sk.gridColumn != (k / 4) * 3 || sk.requiredSkills.Size() > 0)
			{
				bad += 1;
				problems += " " + names[k] + "(" + sk.requiredPointsSpent + "," + sk.gridRow + "," + sk.gridColumn + "," + sk.requiredSkills.Size() + ")";
			}
		}
		if(menu)
			entries += " " + GMTestSklPathName(path) + " " + menu.GMBuildTreeTab(path, false).GetLength();
	}
	GMTestReport(found == 60 && bad == 0, "SKL-02 the new tree as drawn: " + (found - bad) + " of 60 skills at their tier points, row and column, without prerequisites" + problems);
	if(menu)
		GMTestReport(StrFindFirst(entries, " 0") < 0, "SKL-02 the new tree as drawn: the open menu's tabs (entries):" + entries);
}

exec function gmtest_skl02_tree_read()
{
	GMTest_skl02_tree_read();
}

exec function gmtest_skl02_newgame()
{
	GMTest_skl02_newgame();
}

// How often an equipped skill's ability is in the list of skill abilities (once per level).
@addMethod(W3PlayerAbilityManager)
function GMTestCountSkillAbility(abilityName : name) : int
{
	var i, count : int;

	for(i = 0; i < skillAbilities.Size(); i += 1)
	{
		if(skillAbilities[i] == abilityName)
			count += 1;
	}
	return count;
}

// Selects a tab of the open character menu by its colour, as the menu does after an action:
// "SC_Red" combat, "SC_Blue" signs, "SC_Green" alchemy, "SC_Yellow" general skills.
@addMethod(CR4CharacterDupeMenu)
function GMTestSelectTab(color : string)
{
	m_fxSelectTabByColor.InvokeSelfOneArg(FlashArgString(color));
}

exec function gmtest_menutab(color : string)
{
	var common : CR4CommonMenu;
	var menu : CR4CharacterDupeMenu;

	common = (CR4CommonMenu)theGame.GetGuiManager().GetRootMenu();
	if(common)
		menu = (CR4CharacterDupeMenu)common.GetSubMenu();
	if(!menu)
	{
		LogChannel('GMTest', "INFO menutab: the character menu is not open");
		return;
	}
	menu.GMTestSelectTab(color);
	LogChannel('GMTest', "INFO menutab: selected " + color);
}

// SKL-03, Whirl: its terms for the equipped Whirl (classic sword_s1 or new sword_s35) at its
// level, with the hostiles around. Run once standing, once while whirling with adrenaline
// (gmtest_stam02_press(false) in the same exec call).
exec function gmtest_skl03_whirl(expectWhirling : bool)
{
	var witcher : W3PlayerWitcher;
	var skill : ESkill;
	var level, hostiles, maxLevel : int;
	var perLevel, perLevelReduction, base, costCut : float;

	witcher = GetWitcherPlayer();
	skill = witcher.GMWhirlSkill();
	level = witcher.GetSkillLevel(skill);
	maxLevel = witcher.GetSkillMaxLevel(skill);
	hostiles = witcher.GMGetNumHostilesInRange();
	if(skill == S_Sword_s01)
	{
		perLevel = 0.01;
		base = 0.25;
		perLevelReduction = 0.0625;
		costCut = 0.15;
	}
	else
	{
		perLevel = 0.016667;
		base = 0.25;
		perLevelReduction = 0.125;
		costCut = 0.3;
	}
	GMTestReport(AbsF(witcher.GMGetWhirlDamageBonus() - perLevel * level * Clamp(hostiles - 1, 0, 5)) < 0.001, "SKL-03 Whirl " + skill + " level " + level + "/" + maxLevel + ": attack power +" + witcher.GMGetWhirlDamageBonus() + " with " + hostiles + " hostiles");
	GMTestReport(AbsF(witcher.GMGetWhirlDamageReduction() - (base + perLevelReduction * (level - 1))) < 0.001, "SKL-03 Whirl damage reduction " + witcher.GMGetWhirlDamageReduction());
	GMTestReport(AbsF(witcher.GMWhirlCostFactor() - (1 - costCut * (level - 1))) < 0.001 && AbsF(witcher.GMGetWhirlStaminaCost(1) - 50 * witcher.GMWhirlCostFactor()) < 0.01, "SKL-03 Whirl stamina cost " + witcher.GMGetWhirlStaminaCost(1) + "/s (factor " + witcher.GMWhirlCostFactor() + ")");
	GMTestReport(witcher.GMIsWhirlingWithAdrenaline() == expectWhirling, "SKL-03 whirling with adrenaline " + witcher.GMIsWhirlingWithAdrenaline() + " (adrenaline " + witcher.GetStat(BCS_Focus) + ")");
}

// Scripted physical hits on Geralt from the nearest hostile (DEF-05's helper: 5% of max Vitality,
// through ReduceDamage); logs the average Vitality taken, to compare hits while whirling with hits
// while standing.
exec function gmtest_skl03_hit(count : int)
{
	var action : W3Action_Attack;
	var npc : CActor;
	var ents : array<CGameplayEntity>;
	var i : int;
	var total : float;
	var whirling : bool;

	FindGameplayEntitiesInRange(ents, thePlayer, 30, 1, , FLAG_OnlyAliveActors + FLAG_Attitude_Hostile, thePlayer);
	if(ents.Size() == 0)
	{
		LogChannel('GMTest', "INFO SKL-03 hit: no hostile near");
		return;
	}
	npc = (CActor)ents[0];
	whirling = GetWitcherPlayer().GMIsWhirlingWithAdrenaline();
	for(i = 0; i < count; i += 1)
	{
		total += GMTestDefParryHit(npc, false, false, EET_Undefined, action);
		delete action;
	}
	GMTestDefClearHitEffects();
	LogChannel('GMTest', "INFO SKL-03 hit: average Vitality taken " + (total / count) + " over " + count + " hits, whirling " + whirling);
}

// SKL-04, Rend: its numbers for the Rend in force (classic GM_C_sword_s2 or new-tree sword_s2), with
// the adrenaline Geralt has and no charge.
exec function gmtest_skl04_rend()
{
	var witcher : W3PlayerWitcher;
	var level, maxLevel : int;
	var perLevel, perAdrenaline, crit, adrenaline : float;

	witcher = GetWitcherPlayer();
	level = witcher.GetSkillLevel(S_Sword_s02);
	maxLevel = witcher.GetSkillMaxLevel(S_Sword_s02);
	adrenaline = witcher.GetStat(BCS_Focus);
	if(maxLevel == 5)
	{
		perLevel = 0.1;
		perAdrenaline = 0.1;
		crit = 0.2;
	}
	else
	{
		perLevel = 0.166667;
		perAdrenaline = 0.166667;
		crit = 0.333333;
	}
	GMTestReport(AbsF(witcher.GMGetRendPowerBonus() - (perLevel * level + perAdrenaline * level * adrenaline)) < 0.001, "SKL-04 Rend level " + level + "/" + maxLevel + " (" + SkillEnumToName(S_Sword_s02) + "): weapon damage +" + witcher.GMGetRendPowerBonus() + " with " + adrenaline + " adrenaline, uncharged");
	GMTestReport(AbsF(witcher.GMGetRendCritChanceBonus() - crit * level) < 0.001, "SKL-04 Rend critical hit chance +" + witcher.GMGetRendCritChanceBonus());
}

// Records each Rend hit while the test probes are on: adrenaline before and after, the bonus, the
// crit, the damage, the victim's knockdown, the shock wave's hits.
@wrapMethod(W3PlayerWitcher)
function OnProcessActionPost(action : W3DamageAction)
{
	var attackAction : W3Action_Attack;
	var before, bonus : float;
	var victim : CActor;
	var log : bool;

	attackAction = (W3Action_Attack)action;
	log = GMTestProbes() && attackAction && GMIsRendAttack(attackAction);
	if(log)
	{
		before = GetStat(BCS_Focus);
		bonus = GMGetRendPowerBonus();
		gmLastRendAoEHits = 0;
	}
	wrappedMethod(action);
	if(log)
	{
		victim = (CActor)action.victim;
		LogChannel('GMTest', "INFO SKL-04 Rend hit on " + victim.GetDisplayName() + ": adrenaline " + before + " -> " + GetStat(BCS_Focus)
			+ ", bonus +" + bonus + " (charge " + GetSpecialAttackTimeRatio() + "), crit " + action.IsCriticalHit() + ", damage " + action.GetDamageDealt()
			+ ", knockdown " + (victim.HasBuff(EET_Knockdown) || victim.HasBuff(EET_HeavyKnockdown) || action.HasBuff(EET_KnockdownTypeApplicator))
			+ ", shock wave hit " + gmLastRendAoEHits);
	}
}

// SKL-03, SKL-04: Precise Blows' and Crushing Blows' critical hit damage only for melee hits (5.x gave
// it to bolt crits too). Two scripted critical hits of Geralt's on the nearest hostile, a melee one
// and a ranged one, otherwise alike; the probe records the attack power each gets. Needs Precise
// Blows (S_Sword_s17) learned and equipped, and a hostile (a test dummy) nearby.
function GMTestCritHitPower(victim : CActor, melee : bool) : float
{
	var action : W3Action_Attack;
	var step : SGMTestDmgStep;

	thePlayer.GMTestDmgReset();
	thePlayer.ForceSetStat(BCS_Focus, 0);
	action = new W3Action_Attack in theGame.damageMgr;
	action.Init(thePlayer, victim, NULL, GetInvalidUniqueId(), 'attack_light', thePlayer.GetName(), EHRT_Light,
		false, false, 'attack_light', AST_Jab, ASD_UpDown, melee, !melee, false, false);
	action.SetCriticalHit();
	action.AddDamage(theGame.params.DAMAGE_NAME_PHYSICAL, 100);
	action.SetSuppressHitSounds(true);
	action.SetHitAnimationPlayType(EAHA_ForceNo);
	theGame.damageMgr.ProcessAction(action);
	step = GMTestDmgStep0();
	delete action;
	if(victim.UsesEssence())
		victim.ForceSetStat(BCS_Essence, victim.GetStatMax(BCS_Essence));
	else
		victim.ForceSetStat(BCS_Vitality, victim.GetStatMax(BCS_Vitality));
	return step.mult;
}

exec function gmtest_skl_critmelee()
{
	var npc : CActor;
	var probes : bool;
	var melee, ranged, bonus : float;

	npc = GMTestHostileNpc();
	if(!npc)
	{
		GMTestReport(false, "SKL crit damage: no hostile NPC nearby (spawn one first)");
		return;
	}
	probes = GMTestProbes();
	thePlayer.GMTestSetProbes(true);
	melee = GMTestCritHitPower(npc, true);
	ranged = GMTestCritHitPower(npc, false);
	thePlayer.GMTestSetProbes(probes);
	bonus = CalculateAttributeValue(thePlayer.GetSkillAttributeValue(S_Sword_s17, theGame.params.CRITICAL_HIT_DAMAGE_BONUS, false, true)) * thePlayer.GetSkillLevel(S_Sword_s17);
	GMTestReport(thePlayer.CanUseSkill(S_Sword_s17) && bonus > 0 && AbsF(melee - ranged - bonus) < 0.01, "SKL crit damage: a melee crit's attack power x" + melee + ", a ranged crit's x" + ranged + " (Precise Blows +" + bonus + " for melee only)");
}

// SKL D47: Muscle Memory and Strength Training count once. A scripted melee hit of Geralt's with the
// given attack name on the dummy (100 physical damage, no weapon, so its damage is fixed), from 0 adrenaline, retried until it is not a crit; returns the
// attack power multiplier the probe recorded and, in gain, the adrenaline the hit gave.
function GMTestStyleHit(npc : CActor, attackName : name, out gain : float) : float
{
	var action : W3Action_Attack;
	var step : SGMTestDmgStep;
	var i : int;

	for(i = 0; i < 5; i += 1)
	{
		thePlayer.GMTestDmgReset();
		thePlayer.ForceSetStat(BCS_Focus, 0);
		action = new W3Action_Attack in theGame.damageMgr;
		action.Init(thePlayer, npc, NULL, GetInvalidUniqueId(), attackName, thePlayer.GetName(), EHRT_Light,
			false, false, attackName, AST_Jab, ASD_UpDown, true, false, false, false);
		action.AddDamage(theGame.params.DAMAGE_NAME_PHYSICAL, 100);
		action.SetSuppressHitSounds(true);
		action.SetHitAnimationPlayType(EAHA_ForceNo);
		theGame.damageMgr.ProcessAction(action);
		step = GMTestDmgStep0();
		gain = thePlayer.GetStat(BCS_Focus);
		if(!action.IsCriticalHit())
			i = 5;
		delete action;
	}
	npc.ForceSetStat(BCS_Vitality, npc.GetStatMax(BCS_Vitality));
	return step.mult;
}

@addField(CR4Player)
var gmTestStyleBase : array<float>;

@addMethod(CR4Player)
function GMTestSetStyleBase(values : array<float>)
{
	gmTestStyleBase = values;
}

// Run once without the skills (stores the baseline), then again with Muscle Memory and Strength
// Training learned and equipped (compares). Needs a neutral test dummy and a drawn sword.
exec function gmtest_skl_mmst(withSkills : bool)
{
	var npc : CActor;
	var names : array<name>;
	var values : array<float>;
	var i, level : int;
	var probes : bool;
	var gain, expected, expectedGain : float;
	var skill : ESkill;

	npc = GMTestHostileNpc();
	if(!npc)
	{
		GMTestReport(false, "SKL D47: no hostile NPC nearby");
		return;
	}
	names.PushBack('attack_light');
	names.PushBack('counter_attack_light');
	names.PushBack('attack_heavy');
	probes = GMTestProbes();
	thePlayer.GMTestSetProbes(true);
	for(i = 0; i < names.Size(); i += 1)
	{
		values.PushBack(GMTestStyleHit(npc, names[i], gain));
		values.PushBack(gain);
	}
	thePlayer.GMTestSetProbes(probes);
	if(!withSkills)
	{
		thePlayer.GMTestSetStyleBase(values);
		for(i = 0; i < names.Size(); i += 1)
			LogChannel('GMTest', "INFO SKL D47 baseline " + names[i] + ": attack power x" + values[2 * i] + ", adrenaline +" + values[2 * i + 1]);
		return;
	}
	for(i = 0; i < names.Size(); i += 1)
	{
		if(names[i] == 'attack_heavy')
			skill = S_Sword_s04;
		else
			skill = S_Sword_s21;
		level = thePlayer.GetSkillLevel(skill);
		expected = 0.1 * level;
		expectedGain = 0.1 * 0.03 * level;
		LogChannel('GMTest', "INFO SKL D47 " + names[i] + ": skill " + skill + " level " + level + ", light_focus_gain " + CalculateAttributeValue(thePlayer.GetSkillAttributeValue(skill, 'light_focus_gain', false, true)) + ", heavy_focus_gain " + CalculateAttributeValue(thePlayer.GetSkillAttributeValue(skill, 'heavy_focus_gain', false, true)) + ", focus_gain " + CalculateAttributeValue(thePlayer.GetAttributeValue('focus_gain')));
		GMTestReport(AbsF(values[2 * i] - thePlayer.gmTestStyleBase[2 * i] - expected) < 0.001, "SKL D47 " + names[i] + ": attack power x" + thePlayer.gmTestStyleBase[2 * i] + " -> x" + values[2 * i] + " (expected +" + expected + ", counted once)");
		// the hit's own gain is 0.1 x (1 + focus_gain); focus_gain includes 5.x's path passive (+0.01 per
		// level of each equipped combat skill) until SKL-01 removes it
		GMTestReport(AbsF(values[2 * i + 1] - 0.1 * (1 + CalculateAttributeValue(thePlayer.GetAttributeValue('focus_gain'))) - expectedGain) < 0.0005, "SKL D47 " + names[i] + ": adrenaline +" + values[2 * i + 1] + " (the hit's own 0.1 x (1 + focus_gain " + CalculateAttributeValue(thePlayer.GetAttributeValue('focus_gain')) + ") plus the skill's +" + expectedGain + ")");
	}
}

// SKL-03, Crippling Strikes: count scripted fast attacks (count of them) on the nearest hostile (a
// neutral test dummy: no bleeding resistance) that make it bleed, check that 5.x's own bleeding is
// gone, and compare a fast attack's final damage on the bleeding enemy with one on a clean enemy.
// Needs Crippling Strikes learned and equipped and a drawn sword.
exec function gmtest_skl03_crippling(count : int)
{
	var witcher : W3PlayerWitcher;
	var npc : CActor;
	var i, bled, vanillaBled : int;
	var gain, clean, bleeding, expectedChance, expectedBoost, duration : float;
	var probes : bool;
	var effect : CBaseGameplayEffect;
	var step : SGMTestDmgStep;

	witcher = GetWitcherPlayer();
	npc = GMTestHostileNpc();
	if(!npc || witcher.GMCripplingStrikesSkill() == S_SUndefined)
	{
		GMTestReport(false, "SKL-03 Crippling Strikes: needs a hostile nearby and the skill");
		return;
	}
	expectedChance = witcher.GMCripplingStrikesValue('sword_s5_chance', true);
	expectedBoost = witcher.GMCripplingStrikesValue('sword_s5_dmg_boost', true);
	probes = GMTestProbes();
	thePlayer.GMTestSetProbes(true);
	for(i = 0; i < count; i += 1)
	{
		npc.RemoveAllBuffsOfType(EET_Bleeding);
		GMTestStyleHit(npc, 'attack_light', gain);
		if(npc.HasBuff(EET_Bleeding))
		{
			effect = npc.GetBuff(EET_Bleeding, "GM_CripplingStrikes");
			if(effect)
			{
				bled += 1;
				duration = effect.GetDurationLeft();
			}
			if(npc.GetBuff(EET_Bleeding, "sword_s5"))
				vanillaBled += 1;
		}
	}
	GMTestReport(vanillaBled == 0, "SKL-03 Crippling Strikes " + witcher.GMCripplingStrikesSkill() + ": 5.x's bleeding gone (" + vanillaBled + " of " + count + ")");
	GMTestReport(bled > 0 && bled < count, "SKL-03 Crippling Strikes: " + bled + " of " + count + " fast attacks made it bleed (chance " + expectedChance + "), duration left " + duration);

	// each hit's final damage against its own damage before the final-damage step (the hit's base
	// damage varies from hit to hit)
	npc.RemoveAllBuffsOfType(EET_Bleeding);
	GMTestStyleHit(npc, 'attack_light', gain);
	npc.RemoveAllBuffsOfType(EET_Bleeding);
	GMTestStyleHit(npc, 'attack_light', gain);
	step = GMTestDmgStep0();
	clean = thePlayer.gmTestDmgFinal / step.result;
	for(i = 0; i < 20 && !npc.HasBuff(EET_Bleeding); i += 1)
		GMTestStyleHit(npc, 'attack_light', gain);
	GMTestStyleHit(npc, 'attack_light', gain);
	step = GMTestDmgStep0();
	bleeding = thePlayer.gmTestDmgFinal / step.result;
	thePlayer.GMTestSetProbes(probes);
	npc.RemoveAllBuffsOfType(EET_Bleeding);
	GMTestReport(AbsF(clean - 1) < 0.001 && AbsF(bleeding - (1 + expectedBoost)) < 0.001, "SKL-03 Crippling Strikes: final damage x" + clean + " of the formula's result on a clean enemy, x" + bleeding + " on a bleeding one (expected x" + (1 + expectedBoost) + ")");
}

// SKL-04, Sunder Armor: a scripted strong attack's physical damage on the nearest hostile (a neutral
// test dummy) after its physical resistance is set to 50%: the probe's recorded resistance must be
// 50% less Sunder Armor's reduction; a fast attack keeps the full 50%. Needs Sunder Armor learned
// and equipped.
exec function gmtest_skl04_sunder()
{
	var witcher : W3PlayerWitcher;
	var npc : CActor;
	var skill : ESkill;
	var reduction, heavyPerc, lightPerc, gain : float;
	var step : SGMTestDmgStep;
	var probes : bool;

	witcher = GetWitcherPlayer();
	npc = GMTestHostileNpc();
	if(witcher.CanUseSkill(S_Sword_s06))
		skill = S_Sword_s06;
	else
		skill = S_Sword_s28;
	if(!npc || !witcher.CanUseSkill(skill))
	{
		GMTestReport(false, "SKL-04 Sunder Armor: needs a hostile nearby and the skill");
		return;
	}
	reduction = CalculateAttributeValue(witcher.GetSkillAttributeValue(skill, 'armor_reduction_perc', false, true)) * witcher.GetSkillLevel(skill);
	GMTestDummySet((CNewNPC)npc, 'physical_resistance_perc', 0.5);
	probes = GMTestProbes();
	thePlayer.GMTestSetProbes(true);
	GMTestStyleHit(npc, 'attack_heavy', gain);
	step = GMTestDmgStep0();
	heavyPerc = step.perc;
	GMTestStyleHit(npc, 'attack_light', gain);
	step = GMTestDmgStep0();
	lightPerc = step.perc;
	thePlayer.GMTestSetProbes(probes);
	GMTestDummySet((CNewNPC)npc, 'physical_resistance_perc', 0);
	GMTestReport(AbsF(lightPerc - 0.5) < 0.001 && AbsF(heavyPerc - (0.5 - reduction)) < 0.001, "SKL-04 Sunder Armor " + skill + " level " + witcher.GetSkillLevel(skill) + ": physical resistance 50% -> " + heavyPerc + " for a strong attack, " + lightPerc + " for a fast attack (reduction " + reduction + ")");
}

// SKL-05, Deflection (classic sword_s10 or new sword_s33 at level 3). Needs a neutral test dummy
// (the nearest hostile) and, for the parry cost, at least one more hostile within 30 m.
// - partial parries: scripted physical hits from the dummy, count of them, parried partially (DEF-05's
//   helper) and not parried; the average Vitality taken (expected 1 - 0.5 - 0.1 per level of a full hit);
// - a reflected arrow: a scripted ranged hit of Geralt's on the dummy marked as a reflected arrow; the
//   probe's raw damage after the pool against before (expected x(1 + 0.5 per level above 1));
// - the parry cost with more than one enemy around (expected half).
exec function gmtest_skl05_deflection(count : int)
{
	var witcher : W3PlayerWitcher;
	var npc : CActor;
	var action : W3Action_Attack;
	var i : int;
	var full, partial, expectedShare, ratio, costCut, baseCost : float;
	var probes : bool;

	witcher = GetWitcherPlayer();
	npc = GMTestHostileNpc();
	if(!npc || witcher.GMDeflectionSkill() == S_SUndefined)
	{
		GMTestReport(false, "SKL-05 Deflection: needs a hostile nearby and the skill");
		return;
	}
	for(i = 0; i < count; i += 1)
	{
		full += GMTestDefParryHit(npc, true, false, EET_Undefined, action);
		delete action;
		partial += GMTestDefParryHit(npc, false, true, EET_Undefined, action);
		delete action;
	}
	GMTestDefClearHitEffects();
	expectedShare = 1 - 0.5 - witcher.GMDeflectionParryReduction();
	GMTestReport(full > 0 && AbsF(partial / full - expectedShare) < 0.08, "SKL-05 Deflection " + witcher.GMDeflectionSkill() + " level " + witcher.GetSkillLevel(witcher.GMDeflectionSkill()) + ": a partial parry takes " + (partial / full) + " of a full hit (expected " + expectedShare + "; averages over " + count + " hits)");

	probes = GMTestProbes();
	thePlayer.GMTestSetProbes(true);
	thePlayer.GMTestDmgReset();
	thePlayer.ForceSetStat(BCS_Focus, 0);
	action = new W3Action_Attack in theGame.damageMgr;
	action.Init(thePlayer, npc, NULL, GetInvalidUniqueId(), 'attack_light', thePlayer.GetName(), EHRT_Light,
		false, false, 'attack_light', AST_Jab, ASD_UpDown, false, true, false, false);
	action.SetBouncedArrow();
	action.AddDamage(theGame.params.DAMAGE_NAME_PHYSICAL, 100);
	action.SetSuppressHitSounds(true);
	action.SetHitAnimationPlayType(EAHA_ForceNo);
	theGame.damageMgr.ProcessAction(action);
	delete action;
	thePlayer.GMTestSetProbes(probes);
	npc.ForceSetStat(BCS_Vitality, npc.GetStatMax(BCS_Vitality));
	ratio = thePlayer.gmTestDmgRawAfter / thePlayer.gmTestDmgRawBefore;
	GMTestReport(AbsF(ratio - (1 + witcher.GMDeflectionDamageBonus())) < 0.001, "SKL-05 Deflection: a reflected arrow's raw damage x" + ratio + " after the pool (bonus +" + witcher.GMDeflectionDamageBonus() + ")");

	costCut = witcher.GMDeflectionParryCostCut();
	GMTestReport(witcher.GMGetNumHostilesInRange() > 1 && AbsF(costCut - 0.5) < 0.001, "SKL-05 Deflection: parry cost cut " + costCut + " with " + witcher.GMGetNumHostilesInRange() + " enemies around, parry cost " + witcher.GetStaminaActionCost(ESAT_Parry, '', 0));
}

// SKL-05, Counterattack (classic sword_s11 or new sword_s31 at level 3), on the nearest hostile (a
// neutral test dummy), scripted: a fast attack's attack power and Geralt's critical hit chance
// against it, plain and with its countered mark set (DEF-07), each with 5.x's "recently countered"
// flag on Geralt off and on (5.x's own bonuses must not apply); and the counter's knockdown chance.
function GMTestCounterattackPower(npc : CActor, countered : bool, recently : bool, out crit : float) : float
{
	var power : float;

	GetWitcherPlayer().SetRecentlyCountered(recently);
	npc.GMSetWasCountered(countered);
	crit = GetWitcherPlayer().GetCriticalHitChance(true, false, npc, MC_Human, false);
	power = GMTestCritHitPower(npc, true);	// a forced crit (a countered enemy is always critted at level 3), one hit: it uses the mark up
	npc.GMSetWasCountered(false);
	GetWitcherPlayer().SetRecentlyCountered(false);
	return power;
}

exec function gmtest_skl05_counterattack()
{
	var witcher : W3PlayerWitcher;
	var npc : CActor;
	var plain, countered, plainRecent, counteredRecent, critPlain, critCountered, critPlainRecent, critCounteredRecent : float;
	var probes : bool;

	witcher = GetWitcherPlayer();
	npc = GMTestHostileNpc();
	if(!npc || witcher.GMCounterattackSkill() == S_SUndefined)
	{
		GMTestReport(false, "SKL-05 Counterattack: needs a hostile nearby and the skill");
		return;
	}
	probes = GMTestProbes();
	thePlayer.GMTestSetProbes(true);
	plain = GMTestCounterattackPower(npc, false, false, critPlain);
	countered = GMTestCounterattackPower(npc, true, false, critCountered);
	plainRecent = GMTestCounterattackPower(npc, false, true, critPlainRecent);
	counteredRecent = GMTestCounterattackPower(npc, true, true, critCounteredRecent);
	thePlayer.GMTestSetProbes(probes);
	GMTestReport(AbsF(countered - plain - 0.334 * witcher.GMCounterattackLevel()) < 0.001 && AbsF(plainRecent - plain) < 0.001 && AbsF(counteredRecent - countered) < 0.001,
		"SKL-05 Counterattack " + witcher.GMCounterattackSkill() + " level " + witcher.GMCounterattackLevel() + ": attack power x" + plain + " plain, x" + countered + " on the countered enemy; with 5.x's flag x" + plainRecent + " and x" + counteredRecent);
	GMTestReport(AbsF(critCountered - critPlain - 0.25 - 0.35 * (witcher.GMCounterattackLevel() - 1)) < 0.001 && AbsF(critPlainRecent - critPlain) < 0.001 && AbsF(critCounteredRecent - critCountered) < 0.001,
		"SKL-05 Counterattack: critical hit chance " + critPlain + " plain, " + critCountered + " on the countered enemy (DEF-07's +0.25 and the skill's); with 5.x's flag " + critPlainRecent + " and " + critCounteredRecent);
	witcher.ForceSetStat(BCS_Focus, 3);
	GMTestReport(AbsF(witcher.GMCounterattackKnockdownChance() - 0.15) < 0.001, "SKL-05 Counterattack: knockdown chance " + witcher.GMCounterattackKnockdownChance() + " with 3 adrenaline");
	witcher.ForceSetStat(BCS_Focus, 0.5);
	GMTestReport(witcher.GMCounterattackKnockdownChance() == 0, "SKL-05 Counterattack: no knockdown chance below 1 adrenaline");
	witcher.ForceSetStat(BCS_Focus, 0);
}

// SKL-05, Deadly Precision (classic sword_s3 or new sword_s30 at level 3): the instant-kill chance
// it gives a scripted hit of Geralt's on the nearest hostile (a neutral test dummy, 100000 Vitality,
// so a hit deals damage without killing): melee on the countered enemy with 3, 1.5 and 0.5 adrenaline,
// melee on an enemy not countered, and a ranged hit on the countered enemy.
function GMTestDeadlyPrecisionChance(npc : CActor, melee : bool, countered : bool, focus : float) : float
{
	var action : W3Action_Attack;
	var chance : float;

	action = new W3Action_Attack in theGame.damageMgr;
	action.Init(thePlayer, npc, NULL, GetInvalidUniqueId(), 'attack_light', thePlayer.GetName(), EHRT_Light,
		false, false, 'attack_light', AST_Jab, ASD_UpDown, melee, !melee, false, false);
	action.AddDamage(theGame.params.DAMAGE_NAME_PHYSICAL, 100);
	action.SetSuppressHitSounds(true);
	action.SetHitAnimationPlayType(EAHA_ForceNo);
	thePlayer.ForceSetStat(BCS_Focus, 0);
	theGame.damageMgr.ProcessAction(action);
	npc.ForceSetStat(BCS_Vitality, npc.GetStatMax(BCS_Vitality));
	npc.GMSetWasCountered(countered);
	thePlayer.ForceSetStat(BCS_Focus, focus);
	chance = GetWitcherPlayer().GMDeadlyPrecisionChance(action, GetInvalidUniqueId(), npc);
	npc.GMSetWasCountered(false);
	thePlayer.ForceSetStat(BCS_Focus, 0);
	delete action;
	return chance;
}

exec function gmtest_skl05_deadlyprecision()
{
	var witcher : W3PlayerWitcher;
	var npc : CActor;
	var level : int;
	var full, half, low, plain, ranged : float;

	witcher = GetWitcherPlayer();
	npc = GMTestHostileNpc();
	if(!npc || witcher.GMDeadlyPrecisionSkill() == S_SUndefined)
	{
		GMTestReport(false, "SKL-05 Deadly Precision: needs a hostile nearby and the skill");
		return;
	}
	level = witcher.GetSkillLevel(witcher.GMDeadlyPrecisionSkill());
	full = GMTestDeadlyPrecisionChance(npc, true, true, 3);
	half = GMTestDeadlyPrecisionChance(npc, true, true, 1.5);
	low = GMTestDeadlyPrecisionChance(npc, true, true, 0.5);
	plain = GMTestDeadlyPrecisionChance(npc, true, false, 3);
	ranged = GMTestDeadlyPrecisionChance(npc, false, true, 3);
	GMTestReport(AbsF(full - 0.03 * level) < 0.0001 && AbsF(half - 0.015 * level) < 0.0001 && low == 0 && plain == 0 && ranged == 0,
		"SKL-05 Deadly Precision " + witcher.GMDeadlyPrecisionSkill() + " level " + level + ": instant-kill chance " + full + " with 3 adrenaline, " + half + " with 1.5, " + low + " with 0.5; " + plain + " on an enemy not countered, " + ranged + " for a ranged hit");
}

// SKL-06, the crossbow skills, read for the skills Geralt has (classic or new tree, any level):
// Lightning Reflexes' aiming speed (computed as each tree's code does), Anatomical Knowledge's
// crossbow crit chance (against a baseline stored by a first call without the skills) and crit damage,
// Crippling Shot's block duration.
@addField(CR4Player)
var gmTestBoltCritBase : float;

@addMethod(CR4Player)
function GMTestSetBoltCritBase(value : float)
{
	gmTestBoltCritBase = value;
}

exec function gmtest_skl06_values(withSkills : bool)
{
	var witcher : W3PlayerWitcher;
	var npc : CActor;
	var crit, speed, critDamage, duration, slowdown : float;
	var skill : ESkill;

	witcher = GetWitcherPlayer();
	npc = GMTestHostileNpc();
	crit = witcher.GetCriticalHitChance(false, false, npc, MC_Human, true);
	if(!withSkills)
	{
		thePlayer.GMTestSetBoltCritBase(crit);
		LogChannel('GMTest', "INFO SKL-06 baseline crossbow crit chance " + crit);
		return;
	}
	if(witcher.CanUseSkill(S_Sword_s13))
	{
		slowdown = CalculateAttributeValue(witcher.GetSkillAttributeValue(S_Sword_s13, 'slowdown_mod', false, true));
		speed = 0.6 - slowdown * witcher.GetSkillLevel(S_Sword_s13);
		skill = S_Sword_s13;
	}
	else
	{
		slowdown = CalculateAttributeValue(witcher.GetSkillAttributeValue(S_Sword_s32, 'slowdown_mod', false, true));
		speed = 0.6 - 0.6 * slowdown * witcher.GetSkillLevel(S_Sword_s32);
		skill = S_Sword_s32;
	}
	GMTestReport(AbsF(speed - 0.15) < 0.001, "SKL-06 Lightning Reflexes " + skill + " level " + witcher.GetSkillLevel(skill) + ": aiming speed " + speed + " (legacy at the maximum level: 0.15)");
	critDamage = CalculateAttributeValue(witcher.GMAnatomicalKnowledgeCritDamage());
	GMTestReport(AbsF(crit - thePlayer.gmTestBoltCritBase - 0.25) < 0.001 && AbsF(critDamage - 0.75) < 0.001,
		"SKL-06 Anatomical Knowledge " + witcher.GMAnatomicalKnowledgeSkill() + ": crossbow crit chance " + thePlayer.gmTestBoltCritBase + " -> " + crit + ", crit damage +" + critDamage);
	if(witcher.CanUseSkill(S_Sword_s12))
	{
		duration = CalculateAttributeValue(witcher.GetSkillAttributeValue(S_Sword_s12, 'duration', true, true)) * witcher.GetSkillLevel(S_Sword_s12);
		skill = S_Sword_s12;
	}
	else
	{
		duration = CalculateAttributeValue(witcher.GetSkillAttributeValue(S_Sword_s27, 'duration', true, true)) * witcher.GetSkillLevel(S_Sword_s27);
		skill = S_Sword_s27;
	}
	GMTestReport(AbsF(duration - 25) < 0.01, "SKL-06 Crippling Shot " + skill + ": a monster skill blocked for " + duration + " s");
}

// SKL-06 slice 2, Steady Shot and Cold Blood, read for the skills Geralt has at their maximum level
// (classic sword_s15 and perk_2, or the new tree's sword_s34): the flat bolt damage, 5.x's terms at 0,
// Cold Blood's adrenaline per bolt (a sword hit's), the classic tree's swapped names.
function GMTestColdBloodExpectedGain() : float
{
	var witcher : W3PlayerWitcher;
	var value : SAbilityAttributeValue;

	witcher = GetWitcherPlayer();
	value = witcher.GetAttributeValue('focus_gain');
	if(witcher.CanUseSkill(S_Sword_s20))
		value += witcher.GetSkillAttributeValue(S_Sword_s20, 'focus_gain', false, true) * witcher.GetSkillLevel(S_Sword_s20);
	return 0.1 * (1 + CalculateAttributeValue(value));
}

exec function gmtest_skl06_steadycold()
{
	var witcher : W3PlayerWitcher;
	var abilities : W3PlayerAbilityManager;
	var damage, oldGain, oldPower : float;
	var power : SAbilityAttributeValue;
	var classic : bool;

	witcher = GetWitcherPlayer();
	abilities = (W3PlayerAbilityManager)witcher.abilityManager;
	classic = witcher.CanUseSkill(S_Sword_s15);
	damage = witcher.GMSteadyShotDamage();
	if(classic)
	{
		oldGain = CalculateAttributeValue(witcher.GetSkillAttributeValue(S_Sword_s15, 'focus_gain', false, true));
		power = witcher.GetSkillAttributeValue(S_Perk_02, PowerStatEnumToName(CPS_AttackPower), false, true);
		oldPower = power.valueMultiplicative;
		GMTestReport(AbsF(damage - 50) < 0.01 && oldGain == 0, "SKL-06 Steady Shot sword_s15 level " + witcher.GetSkillLevel(S_Sword_s15) + ": bolt damage +" + damage + "; 5.x's adrenaline per bolt " + oldGain);
		GMTestReport(witcher.CanUseSkill(S_Perk_02) && oldPower == 0, "SKL-06 Cold Blood perk_2: equipped " + witcher.CanUseSkill(S_Perk_02) + "; 5.x's crossbow attack power " + oldPower);
		GMTestReport(abilities.GetSkillLocalisationKeyName(S_Sword_s15) == "skill_name_perk_2" && abilities.GetSkillLocalisationKeyName(S_Perk_02) == "skill_name_sword_s15",
			"SKL-06 names: sword_s15 " + GetLocStringByKeyExt(abilities.GetSkillLocalisationKeyName(S_Sword_s15)) + ", perk_2 " + GetLocStringByKeyExt(abilities.GetSkillLocalisationKeyName(S_Perk_02)));
	}
	else
	{
		oldGain = CalculateAttributeValue(witcher.GetSkillAttributeValue(S_Sword_s34, 'focus_gain_lvl3', false, true));
		GMTestReport(witcher.CanUseSkill(S_Sword_s34) && AbsF(damage - 50) < 0.01 && oldGain == 0, "SKL-06 Cold Blood sword_s34 level " + witcher.GetSkillLevel(S_Sword_s34) + ": bolt damage +" + damage + "; 5.x's adrenaline per bolt at level 3 " + oldGain);
	}
	GMTestReport(witcher.GMHasColdBlood(), "SKL-06 Cold Blood: adrenaline per bolt hit " + GMTestColdBloodExpectedGain() + " (a sword hit's)");
}

// Adrenaline around a real bolt hit: with reset, drains it to 0; then reads it back after the shot
// against Cold Blood's gain (one bolt).
exec function gmtest_skl06_focus(reset : bool)
{
	var witcher : W3PlayerWitcher;
	var focus, expected : float;

	witcher = GetWitcherPlayer();
	if(reset)
	{
		witcher.DrainFocus(witcher.GetStat(BCS_Focus));
		LogChannel('GMTest', "INFO SKL-06 adrenaline reset to " + witcher.GetStat(BCS_Focus));
		return;
	}
	focus = witcher.GetStat(BCS_Focus);
	if(witcher.GMHasColdBlood())
		expected = GMTestColdBloodExpectedGain();
	GMTestReport(AbsF(focus - expected) < 0.001, "SKL-06 Cold Blood " + witcher.GMHasColdBlood() + ": adrenaline after one bolt hit " + focus + ", expected " + expected);
}

// A quick crossbow shot through the combat action (as the throw button does): press, then release
// in a later call. Selects the crossbow first.
exec function gmtest_skl06_shoot(pressed : bool)
{
	if(pressed)
	{
		GMTestSelectItem('Crossbow 1', EES_RangedWeapon);
		thePlayer.SetupCombatAction(EBAT_ItemUse, BS_Pressed);
	}
	else
		thePlayer.SetupCombatAction(EBAT_ItemUse, BS_Released);
}

// A bolt or bomb throw, quick or aimed: press, then release in a later call (aimed: a second or more
// later). Aimed sets the throw-hold flag as the input handler does for a held key, so the throw
// enters aiming (CR4Player.OnAnimEvent_ThrowHoldTest); quick leaves it off, as a tap.
exec function gmtest_skl06_throw(pressed : bool, aimed : bool, optional bomb : bool)
{
	var ids : array<SItemUniqueId>;

	if(pressed)
	{
		if(bomb)
		{
			ids = thePlayer.inv.AddAnItem('Dancing Star 1', 1);
			GetWitcherPlayer().EquipItemInGivenSlot(ids[0], EES_Petard1, false);
			GetWitcherPlayer().SelectQuickslotItem(EES_Petard1);
		}
		else
			GMTestSelectItem('Crossbow 1', EES_RangedWeapon);
		thePlayer.GainStat(BCS_Stamina, thePlayer.GetStatMax(BCS_Stamina));
		thePlayer.SetThrowHold(aimed);
		thePlayer.SetupCombatAction(EBAT_ItemUse, BS_Pressed);
		LogChannel('GMTest', "INFO SKL-06 throw pressed: bomb " + bomb + ", hold " + aimed);
	}
	else
	{
		thePlayer.SetThrowHold(false);
		if(thePlayer.GetCurrentStateName() == 'AimThrow')
			thePlayer.GMTestBombThrowRelease();	// the aimed bomb: the combat action buffer is not processed while aiming
		else
			thePlayer.SetupCombatAction(EBAT_ItemUse, BS_Released);
		LogChannel('GMTest', "INFO SKL-06 throw released");
	}
}

@addMethod(CR4Player)
function GMTestBombThrowRelease()
{
	BombThrowRelease();
}

// The aimed flag of each bomb Geralt throws, logged when it explodes; with gmtest_skl06_forceaim(true)
// a bomb counts as aimed (to compare full and halved damage on one target).
@addField(CR4Player)
var gmTestForceAim : bool;

@addMethod(CR4Player)
function GMTestSetForceAim(on : bool)
{
	gmTestForceAim = on;
}

exec function gmtest_skl06_forceaim(on : bool)
{
	thePlayer.GMTestSetForceAim(on);
	LogChannel('GMTest', "INFO SKL-06 bombs forced aimed " + on);
}

@addMethod(CThrowable)
function GMTestSetFromAimThrow(on : bool)
{
	isFromAimThrow = on;
}

@wrapMethod(W3Petard)
function ProcessEffect(optional explosionPosition : Vector, optional collidedTarget : CGameplayEntity)
{
	if(GetOwner() == thePlayer && thePlayer.gmTestForceAim)
		GMTestSetFromAimThrow(true);
	if(GMTestProbes() && GetOwner() == thePlayer)
		LogChannel('GMTest', "INFO SKL-06 bomb explodes: aimed " + GMIsFromAimThrow());
	wrappedMethod(explosionPosition, collidedTarget);
}

// Logs each bolt hit of Geralt's while the test probes are on: crit, attack power, damage.
@wrapMethod(W3PlayerWitcher)
function OnProcessActionPost(action : W3DamageAction)
{
	var step : SGMTestDmgStep;

	wrappedMethod(action);
	if(GMTestProbes() && (W3BoltProjectile)action.causer)
	{
		step = GMTestDmgStep0();
		LogChannel('GMTest', "INFO SKL-06 bolt hit: crit " + action.IsCriticalHit() + ", aimed " + ((CThrowable)action.causer).GMIsFromAimThrow() + ", attack power x" + step.mult + ", damage " + action.GetDamageDealt());
	}
	else if(GMTestProbes() && (W3Petard)action.causer)
		LogChannel('GMTest', "INFO SKL-06 bomb hit on " + action.victim + ": aimed " + ((CThrowable)action.causer).GMIsFromAimThrow() + ", damage " + action.GetDamageDealt() + ", DoT " + action.IsDoTDamage());
}

// SKL-07 slice 1, adrenaline gain and loss (needs a neutral test dummy; scripted hits): a damaging
// light attack gives 0.1 x (1 + focus_gain); a dodged or parried one gives nothing; a hit taken
// costs the share of maximum Vitality it removed, reduced by Resolve when equipped.
function GMTestSkl07Hit(npc : CActor, dodged : bool, parried : bool) : float
{
	var action : W3Action_Attack;

	thePlayer.ForceSetStat(BCS_Focus, 0);
	action = new W3Action_Attack in theGame.damageMgr;
	action.Init(thePlayer, npc, NULL, GetInvalidUniqueId(), 'attack_light', thePlayer.GetName(), EHRT_Light,
		false, false, 'attack_light', AST_Jab, ASD_UpDown, true, false, false, false);
	action.AddDamage(theGame.params.DAMAGE_NAME_PHYSICAL, 100);
	action.SetSuppressHitSounds(true);
	action.SetHitAnimationPlayType(EAHA_ForceNo);
	if(dodged)
		action.SetWasDodged();
	if(parried)
		action.SetIsParried(true);
	theGame.damageMgr.ProcessAction(action);
	LogChannel('GMTest', "INFO SKL-07 hit: dealt " + action.GetDamageDealt() + ", dodged " + action.WasDodged() + ", parried " + action.IsParried());
	delete action;
	npc.ForceSetStat(BCS_Vitality, npc.GetStatMax(BCS_Vitality));
	return thePlayer.GetStat(BCS_Focus);
}

exec function gmtest_skl07_adrenaline()
{
	var witcher : W3PlayerWitcher;
	var npc : CActor;
	var gainAttr : SAbilityAttributeValue;
	var focusGain, expected, gain, dodgedGain, parriedGain, before, loss, expectedLoss, resolve : float;
	var action : W3Action_Attack;

	witcher = GetWitcherPlayer();
	npc = GMTestHostileNpc();
	if(!npc)
	{
		GMTestReport(false, "SKL-07 adrenaline: needs a hostile test dummy nearby");
		return;
	}
	gainAttr = witcher.GetAttributeValue('focus_gain');
	focusGain = CalculateAttributeValue(gainAttr);
	if(witcher.CanUseSkill(S_Sword_s20))
		focusGain += CalculateAttributeValue(witcher.GetSkillAttributeValue(S_Sword_s20, 'focus_gain', false, true)) * witcher.GetSkillLevel(S_Sword_s20);
	expected = 0.1 * (1 + focusGain);
	gain = GMTestSkl07Hit(npc, false, false);
	dodgedGain = GMTestSkl07Hit(npc, true, false);
	parriedGain = GMTestSkl07Hit(npc, false, true);
	GMTestReport(AbsF(gain - expected) < 0.0001, "SKL-07 a damaging light attack gives " + gain + " adrenaline (0.1 x (1 + focus_gain " + focusGain + "))");
	GMTestReport(dodgedGain == 0 && parriedGain == 0, "SKL-07 a dodged hit gives " + dodgedGain + ", a parried one " + parriedGain);

	witcher.ForceSetStat(BCS_Vitality, witcher.GetStatMax(BCS_Vitality));
	witcher.ForceSetStat(BCS_Focus, 3);
	before = witcher.GetStat(BCS_Focus);
	action = GMTestDefHit(npc, witcher, false, 0);
	loss = before - witcher.GetStat(BCS_Focus);
	if(witcher.CanUseSkill(S_Sword_s16))
		resolve = CalculateAttributeValue(witcher.GetSkillAttributeValue(S_Sword_s16, 'focus_drain_reduction', false, true)) * witcher.GetSkillLevel(S_Sword_s16);
	expectedLoss = ClampF(action.GetDamageDealt() / witcher.GetMaxHealth(), 0, 1) * (1 - resolve);
	GMTestReport(AbsF(loss - expectedLoss) < 0.0001, "SKL-07 a hit taken for " + action.GetDamageDealt() + " of " + witcher.GetMaxHealth() + " costs " + loss + " adrenaline (Resolve " + witcher.GetSkillLevel(S_Sword_s16) + ": -" + resolve + ")");
	witcher.ForceSetStat(BCS_Vitality, witcher.GetStatMax(BCS_Vitality));
	witcher.ForceSetStat(BCS_Focus, 0);
}

// SKL-07 slice 2, Razor Focus. Before combat: gmtest_skl07_razor(true) sets adrenaline to 0; spawn a
// hostile test dummy (combat starts), then gmtest_skl07_razor(false) reads the adrenaline combat
// started with (legacy: at least focus_add x level) and a damaging hit's gain (0.1 x (1 + focus_gain,
// Razor Focus's per level included)).
exec function gmtest_skl07_razor(reset : bool)
{
	var witcher : W3PlayerWitcher;
	var npc : CActor;
	var start, expectedStart, perLevel, focusGain, gain : float;
	var level : int;

	witcher = GetWitcherPlayer();
	if(reset)
	{
		witcher.ForceSetStat(BCS_Focus, 0);
		LogChannel('GMTest', "INFO SKL-07 adrenaline 0 before combat, in combat " + witcher.IsInCombat());
		return;
	}
	level = witcher.GetSkillLevel(S_Sword_s20);
	start = witcher.GetStat(BCS_Focus);
	expectedStart = CalculateAttributeValue(witcher.GetSkillAttributeValue(S_Sword_s20, 'focus_add', false, true)) * level;
	GMTestReport(witcher.CanUseSkill(S_Sword_s20) && AbsF(start - expectedStart) < 0.001, "SKL-07 Razor Focus " + witcher.GMGetSkillAbilityName(S_Sword_s20) + " level " + level + ": combat started with " + start + " adrenaline (expected " + expectedStart + "; 5.x: 1)");
	npc = GMTestHostileNpc();
	if(!npc)
		return;
	perLevel = CalculateAttributeValue(witcher.GetSkillAttributeValue(S_Sword_s20, 'focus_gain', false, true));
	focusGain = CalculateAttributeValue(witcher.GetAttributeValue('focus_gain')) + perLevel * level;
	gain = GMTestSkl07Hit(npc, false, false);
	GMTestReport(AbsF(gain - 0.1 * (1 + focusGain)) < 0.0001, "SKL-07 Razor Focus: a damaging hit gives " + gain + " adrenaline (gain +" + perLevel + " per level; focus_gain in all " + focusGain + ")");
}

// SKL-07 slice 3, Undying (a hostile test dummy nearby, the skill equipped). Phase 0: full Vitality,
// 3 adrenaline, a scripted hit from the dummy for twice Geralt's maximum Vitality: he lives at 1, the
// immortal effect runs, adrenaline is 0, the regen abilities are in place, a negative effect and an
// adrenaline gain are refused. Phase 1 (6 s later): Vitality healed over the 5 s, the cooldown running,
// Undying unavailable.
exec function gmtest_skl07_undying(phase : int)
{
	var witcher : W3PlayerWitcher;
	var npc : CActor;
	var action : W3Action_Attack;
	var regen, count, expectedCount, vitality, maxVitality, cooldown : float;
	var level : int;
	var buff : CBaseGameplayEffect;
	var regenValue : SAbilityAttributeValue;

	witcher = GetWitcherPlayer();
	level = witcher.GetSkillLevel(S_Sword_s18);
	maxVitality = witcher.GetStatMax(BCS_Vitality);
	if(phase == 0)
	{
		npc = GMTestHostileNpc();
		if(!npc || !witcher.CanUseSkill(S_Sword_s18))
		{
			GMTestReport(false, "SKL-07 Undying: needs a hostile nearby and the skill");
			return;
		}
		witcher.RemoveBuff(EET_GMUndyingCooldown);	// from an earlier run
		witcher.ForceSetStat(BCS_Vitality, maxVitality);
		witcher.ForceSetStat(BCS_Focus, 3);
		action = new W3Action_Attack in theGame.damageMgr;
		action.Init(npc, witcher, NULL, GetInvalidUniqueId(), 'attack_heavy', npc.GetName(), EHRT_Heavy,
			false, false, '', AST_Jab, ASD_UpDown, true, false, false, false);
		action.AddDamage(theGame.params.DAMAGE_NAME_DIRECT, maxVitality * 2);
		action.SetSuppressHitSounds(true);
		action.SetHitAnimationPlayType(EAHA_ForceNo);
		theGame.damageMgr.ProcessAction(action);
		count = witcher.GetAbilityCount(witcher.GMUndyingRegenAbility());
		expectedCount = 3 * level;
		GMTestReport(witcher.IsAlive() && witcher.GetStat(BCS_Vitality) < maxVitality * 0.05 && witcher.HasBuff(EET_GMUndyingImmortal) && witcher.GetStat(BCS_Focus) == 0 && count == expectedCount,
			"SKL-07 Undying " + witcher.GMGetSkillAbilityName(S_Sword_s18) + " level " + level + ": a hit for " + (maxVitality * 2) + " left Geralt alive at " + witcher.GetStat(BCS_Vitality) + ", immortal effect " + witcher.HasBuff(EET_GMUndyingImmortal) + ", adrenaline " + witcher.GetStat(BCS_Focus) + ", " + count + " x " + witcher.GMUndyingRegenAbility() + " (expected " + expectedCount + ")");
		witcher.AddEffectDefault(EET_Bleeding, npc, "GMTest");
		witcher.GainStat(BCS_Focus, 1);
		GMTestReport(!witcher.HasBuff(EET_Bleeding) && witcher.GetStat(BCS_Focus) == 0, "SKL-07 Undying: bleeding refused " + !witcher.HasBuff(EET_Bleeding) + ", adrenaline gain refused (" + witcher.GetStat(BCS_Focus) + ")");
		regenValue = witcher.GetAttributeValue('vitalityCombatRegen');
		LogChannel('GMTest', "INFO SKL-07 Undying vitalityCombatRegen base " + regenValue.valueBase + " mult " + regenValue.valueMultiplicative + " add " + regenValue.valueAdditive + ", in combat " + witcher.IsInCombat() + ", regen effect " + witcher.HasBuff(EET_AutoVitalityRegen));
		return;
	}
	vitality = witcher.GetStat(BCS_Vitality);
	buff = witcher.GetBuff(EET_GMUndyingCooldown);
	if(buff)
		cooldown = buff.GetDurationLeft();
	regen = 0.01 * 3 * level * 5;
	if(!GMIsClassicTreeAbility(witcher.GMGetSkillAbilityName(S_Sword_s18)))
		regen = 0.016667 * 3 * level * 5;
	GMTestReport(!witcher.HasBuff(EET_GMUndyingImmortal) && witcher.HasBuff(EET_GMUndyingCooldown) && !witcher.GMCanUseUndying() && cooldown > 110 && AbsF(vitality / maxVitality - regen) < 0.1,
		"SKL-07 Undying after 5 s: Vitality " + vitality + " (" + (vitality / maxVitality) + " of max; expected about " + regen + "), cooldown " + witcher.HasBuff(EET_GMUndyingCooldown) + " " + cooldown + " s left, available again " + witcher.GMCanUseUndying() + ", regen abilities left " + witcher.GetAbilityCount(witcher.GMUndyingRegenAbility()));
}

// SKL-08 slice 1, the knockdown roll: the knockdown applicator applied n times by Geralt to the hostile
// test dummy (full stamina, neutral stats) at the given power (sign intensity as a multiplier), counting
// the effects it gives; the expected shares follow legacy's roll (33% x (1 + intensity bonus) for a
// knockdown, 15% of those heavy; 66% of the rest long staggers). Then the severity steps on the dummy
// at 20% and 5% stamina.
function GMTestKnockdownRoll(npc : CActor, power : float, n : int, out heavy : float, out knock : float, out longStagger : float, out stagger : float)
{
	var params : SCustomEffectParams;
	var i : int;
	var result : EEffectInteract;

	heavy = 0; knock = 0; longStagger = 0; stagger = 0;
	for(i = 0; i < n; i += 1)
	{
		npc.RemoveAllBuffsOfType(EET_HeavyKnockdown);
		npc.RemoveAllBuffsOfType(EET_Knockdown);
		npc.RemoveAllBuffsOfType(EET_LongStagger);
		npc.RemoveAllBuffsOfType(EET_Stagger);
		npc.RemoveAllBuffsOfType(EET_KnockdownTypeApplicator);	// it ends on the next tick; a second one would stack on it
		npc.ForceSetStat(BCS_Stamina, npc.GetStatMax(BCS_Stamina));
		params.effectType = EET_KnockdownTypeApplicator;
		params.creator = thePlayer;
		params.sourceName = "GMTest";
		params.customPowerStatValue.valueMultiplicative = power;
		result = npc.AddEffectCustom(params);
		if(i == 0)
			LogChannel('GMTest', "INFO SKL-08 applicator added: " + result + ", buffs after: heavy " + npc.HasBuff(EET_HeavyKnockdown) + " knockdown " + npc.HasBuff(EET_Knockdown) + " long stagger " + npc.HasBuff(EET_LongStagger) + " stagger " + npc.HasBuff(EET_Stagger) + ", immune to applicator " + npc.IsImmuneToBuff(EET_KnockdownTypeApplicator) + ", to knockdown " + npc.IsImmuneToBuff(EET_Knockdown));
		if(npc.HasBuff(EET_HeavyKnockdown))		heavy += 1;
		else if(npc.HasBuff(EET_Knockdown))		knock += 1;
		else if(npc.HasBuff(EET_LongStagger))	longStagger += 1;
		else if(npc.HasBuff(EET_Stagger))		stagger += 1;
	}
	heavy /= n; knock /= n; longStagger /= n; stagger /= n;
	npc.RemoveAllBuffsOfType(EET_HeavyKnockdown);
	npc.RemoveAllBuffsOfType(EET_Knockdown);
	npc.RemoveAllBuffsOfType(EET_LongStagger);
	npc.RemoveAllBuffsOfType(EET_Stagger);
}

exec function gmtest_skl08_knockdown(optional n : int)
{
	var npc : CActor;
	var heavy, knock, longStagger, stagger, chance : float;
	var power : float;
	var i : int;
	var stamina : array<float>;
	var expected : array<EEffectType>;
	var got : EEffectType;

	npc = GMTestHostileNpc();
	if(!npc)
	{
		GMTestReport(false, "SKL-08 knockdown: needs a hostile test dummy");
		return;
	}
	if(n <= 0)
		n = 400;
	for(i = 0; i < 2; i += 1)
	{
		if(i == 0)
			power = 1;
		else
			power = 5;
		chance = ClampF(0.33 * (1 + GMSignPowerStatToPowerBonus(power)), 0.1, 1);
		GMTestKnockdownRoll(npc, power, n, heavy, knock, longStagger, stagger);
		GMTestReport(AbsF(heavy + knock - chance) < 0.07 && AbsF(heavy - chance * 0.15) < 0.05 && AbsF(longStagger - (1 - chance) * 0.66) < 0.07,
			"SKL-08 knockdown roll at intensity x" + power + " (" + n + " tries): heavy knockdown " + heavy + ", knockdown " + knock + ", long stagger " + longStagger + ", stagger " + stagger + " (expected: knocked down " + chance + ", heavy " + (chance * 0.15) + ", long stagger " + ((1 - chance) * 0.66) + ")");
	}
	stamina.PushBack(1.0);	expected.PushBack(EET_Stagger);
	stamina.PushBack(0.2);	expected.PushBack(EET_LongStagger);
	stamina.PushBack(0.05);	expected.PushBack(EET_Knockdown);
	for(i = 0; i < stamina.Size(); i += 1)
	{
		npc.ForceSetStat(BCS_Stamina, npc.GetStatMax(BCS_Stamina) * stamina[i]);
		got = GMModifyKnockdownSeverity(npc, thePlayer, EET_Stagger);
		GMTestReport(got == expected[i], "SKL-08 severity: a stagger on a target at " + stamina[i] * 100 + "% stamina becomes " + got);
	}
	npc.ForceSetStat(BCS_Stamina, npc.GetStatMax(BCS_Stamina));
}

// The knockdown-type effects on the hostile test dummy (after a real Aard cast); with gmtest_probes(true)
// the roll itself is logged (GMModifyKnockdownSeverity below).
exec function gmtest_skl08_effects()
{
	var npc : CActor;
	var sp : SAbilityAttributeValue;

	npc = GMTestHostileNpc();
	if(!npc)
		return;
	sp = thePlayer.GetTotalSignSpellPower(S_Magic_1);
	// INFO only: the frozen dummy ends knockdowns and long staggers early (the roll probe logs the result)
	LogChannel('GMTest', "INFO SKL-08 after the cast: heavy knockdown " + npc.HasBuff(EET_HeavyKnockdown) + ", knockdown " + npc.HasBuff(EET_Knockdown) + ", long stagger " + npc.HasBuff(EET_LongStagger) + ", stagger " + npc.HasBuff(EET_Stagger) + "; Geralt's Aard intensity x" + sp.valueMultiplicative);
}

// Logs each knockdown roll (rolled type, final type, the target's stamina) while the test probes are on.
@wrapMethod
function GMModifyKnockdownSeverity(target : CActor, attacker : CGameplayEntity, type : EEffectType) : EEffectType
{
	var result : EEffectType;

	result = wrappedMethod(target, attacker, type);
	if(GMTestProbes())
		LogChannel('GMTest', "INFO SKL-08 knockdown roll on " + target.GetDisplayName() + " by " + attacker + ": rolled " + type + ", applied " + result + ", target stamina " + target.GetStaminaPercents());
	return result;
}

// Classic Aard Intensity (magic_s12) at its level: the heavy knockdown chance it adds when casting
// Aard, and 5.x's sign intensity gone (Aard's intensity read with and without the skill: run once
// without it, then with it).
@addField(CR4Player)
var gmTestAardPowerBase : float;

@addMethod(CR4Player)
function GMTestSetAardPowerBase(value : float)
{
	gmTestAardPowerBase = value;
}

exec function gmtest_skl08_intensity(withSkill : bool)
{
	var witcher : W3PlayerWitcher;
	var skill : ESkill;
	var abl, sp : SAbilityAttributeValue;
	var bonus : float;

	witcher = GetWitcherPlayer();
	sp = witcher.GetTotalSignSpellPower(S_Magic_1);
	if(!withSkill)
	{
		thePlayer.GMTestSetAardPowerBase(sp.valueMultiplicative);
		LogChannel('GMTest', "INFO SKL-08 Aard intensity without Aard Intensity x" + sp.valueMultiplicative);
		return;
	}
	skill = witcher.GMAardIntensitySkill();
	abl = witcher.GetSkillAttributeValue(skill, 'heavy_knockdown_chance_bonus', false, false);
	bonus = abl.valueMultiplicative * witcher.GetSkillLevel(skill);
	GMTestReport(skill != S_SUndefined && AbsF(bonus - 0.15) < 0.001 && AbsF(sp.valueMultiplicative - thePlayer.gmTestAardPowerBase) < 0.001,
		"SKL-08 Aard Intensity " + SkillEnumToName(skill) + " level " + witcher.GetSkillLevel(skill) + ": heavy knockdown chance +" + bonus + " when casting Aard (0.15 + " + bonus + "); Aard intensity x" + sp.valueMultiplicative + " (without the skill x" + thePlayer.gmTestAardPowerBase + ")");
}

// SKL-08 slice 2. Aard Sweep's penalty at its current level (alternate Aard's intensity against
// Aard's: -0.4, -0.2, 0 at levels 1 to 3); no diminishing returns (three Aard and Igni registrations on
// the hostile dummy, all tier 1).
exec function gmtest_skl08_sweep()
{
	var witcher : W3PlayerWitcher;
	var aard, sweep : SAbilityAttributeValue;
	var level : int;
	var expected : float;

	witcher = GetWitcherPlayer();
	level = witcher.GetSkillLevel(S_Magic_s01);
	aard = witcher.GetTotalSignSpellPower(S_Magic_1);
	sweep = witcher.GetTotalSignSpellPower(S_Magic_s01);
	expected = -0.4 + 0.2 * Max(0, level - 1);
	GMTestReport(witcher.CanUseSkill(S_Magic_s01) && AbsF(sweep.valueMultiplicative - aard.valueMultiplicative - expected) < 0.001,
		"SKL-08 Aard Sweep level " + level + ": intensity x" + sweep.valueMultiplicative + " against Aard's x" + aard.valueMultiplicative + " (penalty " + (sweep.valueMultiplicative - aard.valueMultiplicative) + ", expected " + expected + ")");
}

exec function gmtest_skl08_dr()
{
	var npc : CNewNPC;
	var a1, a2, a3, i1, i2, i3 : int;

	npc = (CNewNPC)GMTestHostileNpc();
	if(!npc)
		return;
	a1 = npc.SignDRRegisterAard();	a2 = npc.SignDRRegisterAard();	a3 = npc.SignDRRegisterAard();
	i1 = npc.SignDRRegisterIgni(false);	i2 = npc.SignDRRegisterIgni(true);	i3 = npc.SignDRRegisterIgni(true);
	GMTestReport(a1 == 1 && a2 == 1 && a3 == 1 && i1 == 1 && i2 == 1 && i3 == 1 && npc.SignDRGetAardTier() == 1,
		"SKL-08 D18 no diminishing returns: Aard tiers " + a1 + ", " + a2 + ", " + a3 + "; Igni tiers " + i1 + ", " + i2 + ", " + i3 + "; Aard tier read " + npc.SignDRGetAardTier());
}

// Logs each Aard hit of Geralt's while the test probes are on: its force damage dealt.
@wrapMethod(W3PlayerWitcher)
function OnProcessActionPost(action : W3DamageAction)
{
	wrappedMethod(action);
	if(GMTestProbes() && (W3AardProjectile)action.causer)
		LogChannel('GMTest', "INFO SKL-08 Aard hit on " + ((CActor)action.victim).GetDisplayName() + ": damage " + action.GetDamageDealt() + ", Aard intensity x" + GMTestAardIntensity());
	else if(GMTestProbes() && action.IsActionWitcherSign() && StrContains(action.GetBuffSourceName(), "_sign_yrden_alt"))
		LogChannel('GMTest', "INFO SKL-10 turret hit on " + ((CActor)action.victim).GetDisplayName() + ": damage " + action.GetDamageDealt());
	else if(GMTestProbes() && (W3IgniProjectile)action.causer)
		LogChannel('GMTest', "INFO SKL-09 Igni hit on " + ((CActor)action.victim).GetDisplayName() + ": damage " + action.GetDamageDealt() + ", Igni intensity x" + GMTestSignIntensity(S_Magic_2) + ", burning " + ((CActor)action.victim).HasBuff(EET_Burning));
}

function GMTestSignIntensity(skill : ESkill) : float
{
	var sp : SAbilityAttributeValue;

	sp = GetWitcherPlayer().GetTotalSignSpellPower(skill);
	return sp.valueMultiplicative;
}

function GMTestAardIntensity() : float
{
	var sp : SAbilityAttributeValue;

	sp = GetWitcherPlayer().GetTotalSignSpellPower(S_Magic_1);
	return sp.valueMultiplicative;
}

// SKL-08 finishers: on the hostile bandit of gmtest_stam06_bandit(), phase 0 knocks it down
// (heavy: heavy knockdown); phase 1, a second later, reads whether it is in Geralt's finishable list
// (only after a heavy knockdown), then removes the effect.
exec function gmtest_skl08_finisher(phase : int, heavy : bool)
{
	var npc : CActor;
	var finishable : bool;

	npc = GMTestHostileNpc();
	if(!npc)
		return;
	if(phase == 0)
	{
		npc.RemoveAllBuffsOfType(EET_Knockdown);
		npc.RemoveAllBuffsOfType(EET_HeavyKnockdown);
		thePlayer.GMTestSetFinisherSeen(NULL);
		if(heavy)
			npc.AddEffectDefault(EET_HeavyKnockdown, thePlayer, "GMTest");
		else
			npc.AddEffectDefault(EET_Knockdown, thePlayer, "GMTest");
		LogChannel('GMTest', "INFO SKL-08 " + npc.GetDisplayName() + " knocked down, heavy " + heavy + ": heavy knockdown " + npc.HasBuff(EET_HeavyKnockdown) + ", knockdown " + npc.HasBuff(EET_Knockdown));
		return;
	}
	finishable = thePlayer.gmTestFinisherSeen == npc;	// the critical-state task enabled its finisher (it can end again within the knockdown)
	GMTestReport(finishable == heavy, "SKL-08 finisher: heavy knockdown " + heavy + ", finisher enabled " + finishable + ", in the finishable list now " + thePlayer.finishableEnemiesList.Contains(npc) + " (legacy: heavy knockdowns only)");
	npc.RemoveAllBuffsOfType(EET_Knockdown);
	npc.RemoveAllBuffsOfType(EET_HeavyKnockdown);
}

// Logs each critical-state task's finisher check while the test probes are on.
@wrapMethod(CBehTreeTaskCSEffect)
function EnableFinisher()
{
	if(GMTestProbes())
		LogChannel('GMTest', "INFO SKL-08 finisher check on " + GetActor().GetDisplayName() + ": state " + CSType + ", anim " + finisherAnimName + ", should " + ShouldEnableFinisher() + ", enabled " + finisherEnabled + ", disabled " + finisherDisabled + ", vulnerable " + GetActor().IsVulnerable());
	wrappedMethod();
	if(finisherEnabled)
		thePlayer.GMTestSetFinisherSeen(GetActor());
}

@addField(CR4Player)
var gmTestFinisherSeen : CActor;

@addMethod(CR4Player)
function GMTestSetFinisherSeen(actor : CActor)
{
	gmTestFinisherSeen = actor;
}

// SKL-09 slice 1, the sign effect test, called n times for Geralt on the hostile test dummy (neutral:
// no resistances): regular Igni's burning at 33% (+5% per Pyromaniac level), Aard's knockdown
// applicator and alternate Igni always (5.x: intensity / 2 - resistance).
@addMethod(W3EffectManager)
function GMTestSignBuffTest(signType : ESignType, effectType : EEffectType, isAlternate : bool, n : int) : float
{
	var sp : SAbilityAttributeValue;
	var i : int;
	var passed : float;

	sp = GetWitcherPlayer().GetTotalSignSpellPower(S_Magic_2);
	for(i = 0; i < n; i += 1)
	{
		if(GetSignApplyBuffTest(signType, effectType, sp, isAlternate, thePlayer, ""))
			passed += 1;
	}
	return passed / n;
}

@addMethod(CActor)
function GMTestEffectManager() : W3EffectManager
{
	return effectManager;
}

exec function gmtest_skl09_burn(optional n : int)
{
	var npc : CActor;
	var witcher : W3PlayerWitcher;
	var igni, alt, aard, expected : float;
	var level : int;
	var pyro : ESkill;

	witcher = GetWitcherPlayer();
	npc = GMTestHostileNpc();
	if(!npc)
	{
		GMTestReport(false, "SKL-09 burn test: needs a hostile test dummy");
		return;
	}
	if(n <= 0)
		n = 1000;
	pyro = witcher.GMPyromaniacSkill();
	level = witcher.GetSkillLevel(pyro);
	expected = 0.33;
	if(pyro != S_SUndefined)
		expected += CalculateAttributeValue(witcher.GetSkillAttributeValue(pyro, 'chance_bonus', false, true)) * level;
	else
		level = 0;
	igni = npc.GMTestEffectManager().GMTestSignBuffTest(ST_Igni, EET_Burning, false, n);
	alt = npc.GMTestEffectManager().GMTestSignBuffTest(ST_Igni, EET_Burning, true, n);
	aard = npc.GMTestEffectManager().GMTestSignBuffTest(ST_Aard, EET_KnockdownTypeApplicator, false, n);
	GMTestReport(AbsF(igni - expected) < 0.05 && alt == 1 && aard == 1,
		"SKL-09 sign effect test (" + n + " tries, Pyromaniac " + SkillEnumToName(pyro) + " level " + level + "): Igni burns " + igni + " (expected " + expected + "), alternate Igni " + alt + ", Aard's knockdown applicator " + aard);
}

// SKL-09 Melt Armor on the hostile dummy after a real Igni cast: the debuff, its stacks (level x
// round(1 + 7 x intensity bonus)), Geralt's timer.
exec function gmtest_skl09_melt()
{
	var witcher : W3PlayerWitcher;
	var npc : CActor;
	var stacks, expected : int;
	var sp : SAbilityAttributeValue;

	witcher = GetWitcherPlayer();
	npc = GMTestHostileNpc();
	if(!npc)
		return;
	sp = witcher.GetTotalSignSpellPower(S_Magic_2);
	stacks = npc.GetAbilityCount(witcher.GMMeltArmorStackAbility());
	expected = witcher.GetSkillLevel(S_Magic_s08) * RoundMath(1 + 7.0 * GMSignPowerStatToPowerBonus(sp.valueMultiplicative));
	GMTestReport(npc.HasBuff(EET_GMMeltArmorDebuff) && stacks == expected && witcher.HasBuff(EET_GMMeltArmorTimer),
		"SKL-09 Melt Armor " + witcher.GMGetSkillAbilityName(S_Magic_s08) + " level " + witcher.GetSkillLevel(S_Magic_s08) + ": debuff " + npc.HasBuff(EET_GMMeltArmorDebuff) + ", " + stacks + " x " + witcher.GMMeltArmorStackAbility() + " (expected " + expected + " at intensity x" + sp.valueMultiplicative + "), Geralt's timer " + witcher.HasBuff(EET_GMMeltArmorTimer));
}

// SKL-10 slice 1: the Yrden trap after a real cast near the hostile test dummy: Geralt's traps, the
// newest one's duration, the dummy's slowdown against legacy's starting value (25% x (1 + intensity
// bonus) at full strength, decaying after a third of the duration).
@addMethod(W3YrdenEntity)
function GMTestTrapDuration() : float
{
	return trapDuration;
}

exec function gmtest_skl10_trap()
{
	var witcher : W3PlayerWitcher;
	var npc : CActor;
	var slow, expected : float;
	var yrden : W3YrdenEntity;
	var power : SAbilityAttributeValue;
	var buff : W3Effect_Slowdown;

	witcher = GetWitcherPlayer();
	npc = GMTestHostileNpc();
	if(!npc || witcher.yrdenEntities.Size() == 0)
	{
		GMTestReport(false, "SKL-10 trap: needs a hostile test dummy and a Yrden trap");
		return;
	}
	yrden = witcher.yrdenEntities[witcher.yrdenEntities.Size() - 1];
	power = yrden.GMGetYrdenPower();
	expected = ClampF(0.25 * (1 + GMSignPowerStatToPowerBonus(power.valueMultiplicative)), 0.15, 0.75);
	buff = (W3Effect_Slowdown)npc.GetBuff(EET_Slowdown);
	if(buff)
		slow = buff.GMGetSlowdown();
	if(npc.HasBuff(EET_YrdenHealthDrain))
		LogChannel('GMTest', "INFO SKL-10 Supercharged Glyphs bonus on the target " + ((W3Effect_YrdenHealthDrain)npc.GetBuff(EET_YrdenHealthDrain)).GMGetDmgBonus() + " (" + witcher.GMGetSkillAbilityName(S_Magic_s11) + " level " + witcher.GetSkillLevel(S_Magic_s11) + ")");
	LogChannel('GMTest', "INFO SKL-10 t=" + theGame.GetEngineTimeAsSeconds() + " traps " + witcher.yrdenEntities.Size() + " (max " + yrden.GMGetMaxCount() + ", radius x" + yrden.GMSustainedGlyphsRangeMult() + "), duration " + yrden.GMTestTrapDuration() + " s, intensity x" + power.valueMultiplicative + "; dummy slowdown " + slow + " (full strength " + expected + ", decaying to 0.15 after a third of the duration), in the trap " + yrden.validTargetsInArea.Contains(npc));
}

// SKL-10 turret: the newest alternate Yrden's charges, duration and damage bonus (read from the entity).
@addMethod(W3YrdenEntity)
function GMTestCharges() : int
{
	return charges;
}

exec function gmtest_skl10_turret()
{
	var witcher : W3PlayerWitcher;
	var yrden : W3YrdenEntity;
	var i : int;

	witcher = GetWitcherPlayer();
	for(i = witcher.yrdenEntities.Size() - 1; i >= 0; i -= 1)
	{
		if(witcher.yrdenEntities[i].IsAlternateCast())
		{
			yrden = witcher.yrdenEntities[i];
			break;
		}
	}
	if(!yrden)
	{
		GMTestReport(false, "SKL-10 turret: no alternate Yrden");
		return;
	}
	LogChannel('GMTest', "INFO SKL-10 turret: Magic Trap level " + witcher.GetSkillLevel(S_Magic_s03) + ", Yrden Intensity " + SkillEnumToName(GMTestEitherSkill(S_Magic_s16, S_Magic_s37)) + " level " + witcher.GetSkillLevel(GMTestEitherSkill(S_Magic_s16, S_Magic_s37)) + ": charges " + yrden.GMTestCharges() + ", duration " + yrden.GMTestTrapDuration() + " s, damage bonus " + yrden.gmTurretDamageBonus + ", intensity x" + GMTestSignIntensity(S_Magic_s03));
}

// SKL-10 Supercharged Glyphs: n scripted light attacks of Geralt's (100 physical, no weapon) on the hostile
// target; logs the lowest damage dealt (no crit) and the bonus on the target. Run inside the trap and
// after it ends to compare.
exec function gmtest_skl10_super(optional n : int)
{
	var npc : CActor;
	var action : W3Action_Attack;
	var i : int;
	var lowest, dealt, bonus : float;

	npc = GMTestHostileNpc();
	if(!npc)
		return;
	if(n <= 0)
		n = 8;
	lowest = 1000000;
	if(npc.HasBuff(EET_YrdenHealthDrain))
		bonus = ((W3Effect_YrdenHealthDrain)npc.GetBuff(EET_YrdenHealthDrain)).GMGetDmgBonus();
	for(i = 0; i < n; i += 1)
	{
		thePlayer.ForceSetStat(BCS_Focus, 0);	// 5.x turns adrenaline into attack power
		action = new W3Action_Attack in theGame.damageMgr;
		action.Init(thePlayer, npc, NULL, GetInvalidUniqueId(), 'attack_light', thePlayer.GetName(), EHRT_Light,
			false, false, 'attack_light', AST_Jab, ASD_UpDown, true, false, false, false);
		action.AddDamage(theGame.params.DAMAGE_NAME_PHYSICAL, 100);
		action.SetSuppressHitSounds(true);
		action.SetHitAnimationPlayType(EAHA_ForceNo);
		theGame.damageMgr.ProcessAction(action);
		dealt = action.GetDamageDealt();
		if(dealt > 0 && dealt < lowest)
			lowest = dealt;
		delete action;
		npc.ForceSetStat(BCS_Vitality, npc.GetStatMax(BCS_Vitality));
	}
	LogChannel('GMTest', "INFO SKL-10 Supercharged: lowest of " + n + " hits " + lowest + ", bonus on the target " + bonus);
}

// SKL-11 Quen: a scripted hit from the hostile test dummy (100 physical, or the given amount) on Geralt
// with a Quen shield up: logs the shield's health before and after, the damage Geralt took, the shield's
// state. Absorbed before armor: with Geralt's armor, a hit the shield fully absorbs costs no Vitality.
exec function gmtest_skl11_hit(optional amount : float)
{
	var witcher : W3PlayerWitcher;
	var npc : CActor;
	var quen : W3QuenEntity;
	var action : W3Action_Attack;
	var before, after, vitality : float;

	witcher = GetWitcherPlayer();
	npc = GMTestHostileNpc();
	quen = (W3QuenEntity)witcher.GetSignEntity(ST_Quen);
	if(!npc || !quen)
	{
		GMTestReport(false, "SKL-11: needs a hostile and a Quen entity");
		return;
	}
	if(amount <= 0)
		amount = 100;
	witcher.ForceSetStat(BCS_Vitality, witcher.GetStatMax(BCS_Vitality));
	vitality = witcher.GetStat(BCS_Vitality);
	before = quen.GMGetShieldHealth();
	action = new W3Action_Attack in theGame.damageMgr;
	action.Init(npc, witcher, NULL, GetInvalidUniqueId(), 'attack_light', npc.GetName(), EHRT_Light,
		false, false, '', AST_Jab, ASD_UpDown, true, false, false, false);
	action.AddDamage(theGame.params.DAMAGE_NAME_PHYSICAL, amount);
	action.SetSuppressHitSounds(true);
	action.SetHitAnimationPlayType(EAHA_ForceNo);
	theGame.damageMgr.ProcessAction(action);
	after = quen.GMGetShieldHealth();
	LogChannel('GMTest', "INFO SKL-11 hit of " + amount + " physical: shield " + before + " -> " + after + ", Geralt lost " + (vitality - witcher.GetStat(BCS_Vitality)) + " Vitality, Quen active " + quen.IsAnyQuenActive() + ", Quen intensity x" + GMTestSignIntensity(S_Magic_4));
	delete action;
}

// SKL-11 active shield: while alternate Quen is held, a scripted hit of the given physical damage from the
// hostile test dummy on Geralt at half Vitality and full stamina: logs the stamina drained and the
// Vitality healed or lost (legacy: the absorbed share of 2 x the shield's health in stamina, 33.4% of
// the absorbed damage per Active Shield level healed).
exec function gmtest_skl11_active(amount : float)
{
	var witcher : W3PlayerWitcher;
	var npc : CActor;
	var quen : W3QuenEntity;
	var action : W3Action_Attack;
	var vitality, stamina : float;

	witcher = GetWitcherPlayer();
	npc = GMTestHostileNpc();
	quen = (W3QuenEntity)witcher.GetSignEntity(ST_Quen);
	if(!npc || !quen)
		return;
	witcher.ForceSetStat(BCS_Vitality, witcher.GetStatMax(BCS_Vitality) * 0.5);
	witcher.ForceSetStat(BCS_Stamina, witcher.GetStatMax(BCS_Stamina));
	vitality = witcher.GetStat(BCS_Vitality);
	stamina = witcher.GetStat(BCS_Stamina);
	action = new W3Action_Attack in theGame.damageMgr;
	action.Init(npc, witcher, NULL, GetInvalidUniqueId(), 'attack_light', npc.GetName(), EHRT_Light,
		false, false, '', AST_Jab, ASD_UpDown, true, false, false, false);
	action.AddDamage(theGame.params.DAMAGE_NAME_PHYSICAL, amount);
	action.SetSuppressHitSounds(true);
	action.SetHitAnimationPlayType(EAHA_ForceNo);
	theGame.damageMgr.ProcessAction(action);
	LogChannel('GMTest', "INFO SKL-11 active shield, hit of " + amount + ": state " + quen.GetCurrentStateName() + ", shield health " + quen.GMGetShieldHealth() + " (x2 at full stamina), stamina " + stamina + " -> " + witcher.GetStat(BCS_Stamina) + ", Vitality " + vitality + " -> " + witcher.GetStat(BCS_Vitality) + ", Quen active " + quen.IsAnyQuenActive());
	delete action;
}

// SKL-11 effect rules: adds the given effect to Geralt (from the hostile test dummy) with a Quen shield up;
// logs whether it was applied and whether the shield is still up.
exec function gmtest_skl11_effect(effectType : EEffectType)
{
	var witcher : W3PlayerWitcher;
	var npc : CActor;
	var before, after : bool;
	var result : EEffectInteract;

	witcher = GetWitcherPlayer();
	npc = GMTestHostileNpc();
	before = witcher.IsAnyQuenActive();
	result = witcher.AddEffectDefault(effectType, npc, "GMTest");
	after = witcher.IsAnyQuenActive();
	LogChannel('GMTest', "INFO SKL-11 " + effectType + " on Geralt with Quen " + before + " (alternate " + witcher.HasAlternateQuen() + "): " + result + ", has it " + witcher.HasBuff(effectType) + ", Quen still up " + after);
	witcher.RemoveAllBuffsOfType(effectType);
}

// SKL-12 Axii, after a real cast at the hostile test dummy: the confusion's duration (legacy: 5 s x (1 +
// Axii Intensity 10% per level) x (1 + intensity bonus), at least 3 s) and Geralt's crit chance against the
// dummy with and without it (+25%, + Delusion's 25% per level).
exec function gmtest_skl12_axii()
{
	var witcher : W3PlayerWitcher;
	var npc : CActor;
	var buff : CBaseGameplayEffect;
	var sp : SAbilityAttributeValue;
	var with, without, expected : float;

	witcher = GetWitcherPlayer();
	npc = GMTestHostileNpc();
	if(!npc)
		return;
	sp = witcher.GetTotalSignSpellPower(S_Magic_5);
	expected = 5 * (1 + GMSignPowerStatToPowerBonus(sp.valueMultiplicative));
	if(GMTestEitherSkill(S_Magic_s18, S_Magic_s36) != S_SUndefined)
		expected *= 1 + CalculateAttributeValue(witcher.GetSkillAttributeValue(GMTestEitherSkill(S_Magic_s18, S_Magic_s36), 'axii_duration_bonus', false, false)) * witcher.GetSkillLevel(GMTestEitherSkill(S_Magic_s18, S_Magic_s36));
	buff = npc.GetBuff(EET_Confusion);
	with = witcher.GetCriticalHitChance(true, false, npc, MC_Human, false);
	LogChannel('GMTest', "INFO SKL-12 confusion " + npc.HasBuff(EET_Confusion) + ", initial duration " + buff.GetInitialDuration() + " (expected " + expected + " at intensity x" + sp.valueMultiplicative + "), confused-target ability on it " + npc.HasAbility('ConfusionEffect') + ", crit chance " + with);
	without = witcher.GetCriticalHitChance(true, false, NULL, MC_Human, false);	// no target, so no confusion bonus (a removed confusion stays until the next update)
	LogChannel('GMTest', "INFO SKL-12 crit chance without confusion " + without + ": bonus " + (with - without) + " (Delusion level " + witcher.GetSkillLevel(S_Magic_s17) + ")");
}

// SKL-12 damage ends effects: gives the hostile test dummy the effect, then a scripted hit of Geralt's
// (100 physical, no weapon) and logs whether it still has it.
exec function gmtest_skl12_ends(effectType : EEffectType)
{
	var npc : CActor;
	var params : SCustomEffectParams;
	var before : bool;

	npc = GMTestHostileNpc();
	if(!npc)
		return;
	params.effectType = effectType;
	params.creator = thePlayer;
	params.sourceName = "GMTest";
	params.duration = 20;
	npc.AddEffectCustom(params);
	before = npc.HasBuff(effectType);
	GMTestSkl07Hit(npc, false, false);
	GMTestReport(before && !npc.HasBuff(effectType), "SKL-12 a damaging hit on a target with " + effectType + " (had it " + before + "): has it after " + npc.HasBuff(effectType) + ", alive " + npc.IsAlive());
	npc.RemoveAllBuffsOfType(effectType);
}

// SKL-12 instant kill: up to n scripted hits of Geralt's with his drawn sword (amount physical) on the
// hostile test dummy, confused by Geralt (a sign effect at Axii's intensity) and set to the given
// Vitality before each hit; stops when it dies. The chance of each roll is logged by the probe below.
exec function gmtest_skl12_instakill(n : int, amount : float, vitality : float)
{
	var npc : CActor;
	var params : SCustomEffectParams;
	var action : W3Action_Attack;
	var i : int;

	npc = GMTestHostileNpc();
	if(!npc)
		return;
	for(i = 0; i < n && npc.IsAlive(); i += 1)
	{
		npc.RemoveAllBuffsOfType(EET_Confusion);
		params.effectType = EET_Confusion;
		params.creator = thePlayer;
		params.sourceName = "axii_GMTest";
		params.isSignEffect = true;
		params.customPowerStatValue = thePlayer.GetTotalSignSpellPower(S_Magic_5);
		params.duration = 20;
		npc.AddEffectCustom(params);
		npc.ForceSetStat(BCS_Vitality, vitality);
		thePlayer.ForceSetStat(BCS_Focus, 0);
		action = GMTestPlayerAttack(npc, 'attack_light');
		action.AddDamage(theGame.params.DAMAGE_NAME_PHYSICAL, amount);
		action.SetSuppressHitSounds(true);
		theGame.damageMgr.ProcessAction(action);
		LogChannel('GMTest', "INFO SKL-12 hit " + (i + 1) + ": dealt " + action.GetDamageDealt() + ", alive " + npc.IsAlive() + ", confused " + npc.HasBuff(EET_Confusion));
		delete action;
	}
}

@wrapMethod(W3DamageManagerProcessor)
function GMGetAxiiInstakillChance() : int
{
	var chance : int;

	chance = wrappedMethod();
	if(GMTestProbes())
		LogChannel('GMTest', "INFO SKL-12 instant-kill roll on " + actorVictim.GetDisplayName() + ": chance " + chance + "%, dealt " + action.GetDamageDealt() + ", health left " + actorVictim.GetHealth());
	return chance;
}

// D58: the new tree's sign slots. For each of the legacy skills given a slot, the one Geralt has
// equipped (classic or new tree) at its current level: its total against legacy's maximum (reached at
// level 5 classic, 3 new tree; at a lower level only logged). Then 5.x's dropped skills: their buffs
// are refused (scripted adds) and their values on the slots are 0.
function GMTestD58Total(skill : ESkill, attributeName : name, expected : float, label : string)
{
	var witcher : W3PlayerWitcher;
	var abl : SAbilityAttributeValue;
	var total : float;
	var level : int;

	witcher = GetWitcherPlayer();
	if(skill == S_SUndefined)
	{
		LogChannel('GMTest', "INFO D58 " + label + ": not equipped");
		return;
	}
	level = witcher.GetSkillLevel(skill);
	abl = witcher.GetSkillAttributeValue(skill, attributeName, false, false);
	total = (abl.valueAdditive + abl.valueMultiplicative) * level;
	if(level < witcher.GetSkillMaxLevel(skill))
	{
		LogChannel('GMTest', "INFO D58 " + label + " " + SkillEnumToName(skill) + " level " + level + "/" + witcher.GetSkillMaxLevel(skill) + ": " + attributeName + " " + total);
		return;
	}
	GMTestReport(AbsF(total - expected) < 0.01, "D58 " + label + " " + SkillEnumToName(skill) + " level " + level + ": " + attributeName + " " + total + " (legacy " + expected + ")");
}

function GMTestD58Zero(skill : ESkill, attributeName : name, label : string)
{
	var min, max : SAbilityAttributeValue;

	theGame.GetDefinitionsManager().GetAbilityAttributeValue(SkillEnumToName(skill), attributeName, min, max);
	GMTestReport(min.valueAdditive == 0 && min.valueMultiplicative == 0 && min.valueBase == 0, "D58 5.x's " + label + " " + SkillEnumToName(skill) + " " + attributeName + " 0 (" + min.valueAdditive + ", " + min.valueMultiplicative + ")");
}

function GMTestD58Denied(effectType : EEffectType)
{
	thePlayer.AddEffectDefault(effectType, NULL, "GMTest");
	GMTestReport(!thePlayer.HasBuff(effectType), "D58 5.x's " + effectType + " is not added");
	thePlayer.RemoveAllBuffsOfType(effectType);
}

// The classic skill or the new tree's slot, whichever Geralt can use (as the signs' GM<Skill>Skill()).
function GMTestEitherSkill(classic : ESkill, newTree : ESkill) : ESkill
{
	if(thePlayer.CanUseSkill(classic))
		return classic;
	if(thePlayer.CanUseSkill(newTree))
		return newTree;
	return S_SUndefined;
}

exec function gmtest_d58()
{
	GMTest_d58();
}

function GMTest_d58()
{
	var witcher : W3PlayerWitcher;

	witcher = GetWitcherPlayer();
	GMTestD58Total(witcher.GMAardIntensitySkill(), 'heavy_knockdown_chance_bonus', 0.15, "Aard Intensity");
	GMTestD58Total(witcher.GMIgniIntensitySkill(), 'fire_damage_bonus', 150, "Igni Intensity");
	GMTestD58Total(witcher.GMIgniIntensitySkill(), 'channeling_damage_bonus', 75, "Igni Intensity");
	GMTestD58Total(witcher.GMPyromaniacSkill(), 'chance_bonus', 0.25, "Pyromaniac");
	GMTestD58Total(GMTestEitherSkill(S_Magic_s16, S_Magic_s37), 'turret_bonus_damage', 150, "Yrden Intensity");
	GMTestD58Total(GMTestEitherSkill(S_Magic_s15, S_Magic_s38), 'shield_health_bonus', 150, "Quen Intensity");
	GMTestD58Total(GMTestEitherSkill(S_Magic_s14, S_Magic_s40), 'discharge_percent', 0.25, "Quen Discharge");
	GMTestD58Total(GMTestEitherSkill(S_Magic_s18, S_Magic_s36), 'axii_duration_bonus', 0.5, "Axii Intensity");
	GMTestD58Zero(S_Magic_s35, 'spell_power_aard_igni', "Catalyst");
	GMTestD58Zero(S_Magic_s35, 'burn_chance_bonus', "Catalyst");
	GMTestD58Zero(S_Magic_s36, 'duration', "Fortified Signs");
	GMTestD58Zero(S_Magic_s37, 'damage_level3', "Convergence Theory");
	GMTestD58Zero(S_Magic_s38, 'spell_power', "Focus");
	GMTestD58Zero(S_Magic_s39, 'stamina_cost_reduction', "Avoidance");
	GMTestD58Zero(S_Magic_s40, 'ElementalDamage', "Overload");
	GMTestD58Zero(S_Magic_s41, 'sign_intensity_ratio', "Resonance");
	GMTestD58Denied(EET_Avoidance);
	GMTestD58Denied(EET_ConvergenceTheory);
	GMTestD58Denied(EET_Resonance);
	GMTestD58Denied(EET_OverloadCooldown);
	GMTestD58Denied(EET_Catalyst);
}

// SKL-01: no passive path bonuses. The four passive abilities' values are 0; with loaded, Geralt has
// none of them (right after a load, before equipping anything).
function GMTestPassiveZero(abilityName : name, attributeName : name)
{
	var min, max : SAbilityAttributeValue;

	theGame.GetDefinitionsManager().GetAbilityAttributeValue(abilityName, attributeName, min, max);
	GMTestReport(min.valueAdditive == 0 && min.valueMultiplicative == 0 && min.valueBase == 0, "SKL-01 passive " + abilityName + " " + attributeName + " 0 (" + min.valueAdditive + ", " + min.valueMultiplicative + ")");
}

exec function gmtest_skl01_passives(optional loaded : bool)
{
	GMTest_skl01_passives(loaded);
}

function GMTest_skl01_passives(loaded : bool)
{
	GMTestPassiveZero('sword_adrenalinegain', 'focus_gain');
	GMTestPassiveZero('magic_staminaregen', 'staminaRegen');
	GMTestPassiveZero('alchemy_potionduration', 'potion_duration');
	GMTestPassiveZero('survival_vitality', 'vitality');
	if(loaded)
		GMTestReport(thePlayer.GetAbilityCount('sword_adrenalinegain') + thePlayer.GetAbilityCount('magic_staminaregen') + thePlayer.GetAbilityCount('alchemy_potionduration') + thePlayer.GetAbilityCount('survival_vitality') == 0,
			"SKL-01 no passive abilities on Geralt after the load (" + thePlayer.GetAbilityCount('sword_adrenalinegain') + ", " + thePlayer.GetAbilityCount('magic_staminaregen') + ", " + thePlayer.GetAbilityCount('alchemy_potionduration') + ", " + thePlayer.GetAbilityCount('survival_vitality') + ")");
	else
		LogChannel('GMTest', "INFO SKL-01 passive abilities on Geralt: " + thePlayer.GetAbilityCount('sword_adrenalinegain') + ", " + thePlayer.GetAbilityCount('magic_staminaregen') + ", " + thePlayer.GetAbilityCount('alchemy_potionduration') + ", " + thePlayer.GetAbilityCount('survival_vitality') + " (inert copies added on equip)");
}

// SKL-18 Rage Management: sets Geralt's adrenaline and stamina (the stamina as a share of its maximum,
// drained through DrainStamina), then logs both; gmtest_skl18_state() logs them and whether a sign could
// be cast now (HasStaminaToUseSkill for Aard).
exec function gmtest_skl18_set(focus : float, optional staminaShare : float)
{
	var witcher : W3PlayerWitcher;

	witcher = GetWitcherPlayer();
	witcher.DrainFocus(witcher.GetStat(BCS_Focus));
	if(focus > 0)
		witcher.GainStat(BCS_Focus, focus);
	witcher.ForceSetStat(BCS_Stamina, witcher.GetStatMax(BCS_Stamina));
	if(staminaShare < 1)
		witcher.DrainStamina(ESAT_FixedValue, witcher.GetStatMax(BCS_Stamina) * (1 - staminaShare), 0);
	GMTestSkl18State();
}

exec function gmtest_skl18_state()
{
	GMTestSkl18State();
}

function GMTestSkl18State()
{
	var witcher : W3PlayerWitcher;

	witcher = GetWitcherPlayer();
	LogChannel('GMTest', "INFO SKL-18 t=" + theGame.GetEngineTimeAsSeconds() + " adrenaline " + witcher.GetStat(BCS_Focus) + ", stamina " + witcher.GetStat(BCS_Stamina) + "/" + witcher.GetStatMax(BCS_Stamina) + ", Rage Management " + witcher.GMHasRageManagement() + ", can cast Aard " + witcher.HasStaminaToUseSkill(S_Magic_1, false, true) + ", casting " + witcher.IsCastingSign());
}

// SKL-07 Flood of Anger: Geralt's adrenaline and stamina, Flood of Anger's level and ability copies, and
// some sign skills' levels (temporarily raised during a Flood of Anger cast, restored after it).
exec function gmtest_skl07_foa_state()
{
	var witcher : W3PlayerWitcher;

	witcher = GetWitcherPlayer();
	LogChannel('GMTest', "INFO SKL-07 FoA t=" + theGame.GetEngineTimeAsSeconds() + ": adrenaline " + witcher.GetStat(BCS_Focus) + ", stamina " + witcher.GetStat(BCS_Stamina) + ", Flood of Anger " + witcher.GetSkillAbilityName(S_Sword_s19) + " level " + witcher.GetSkillLevel(S_Sword_s19) + ", copies " + (witcher.GetAbilityCount('sword_s19') + witcher.GetAbilityCount('GM_C_sword_s19'))
		+ "; levels Igni Intensity s07 " + witcher.GetSkillLevel(S_Magic_s07) + "/s35 " + witcher.GetSkillLevel(S_Magic_s35) + ", Pyromaniac s09 " + witcher.GetSkillLevel(S_Magic_s09) + "/s41 " + witcher.GetSkillLevel(S_Magic_s41) + ", Shock Wave s06 " + witcher.GetSkillLevel(S_Magic_s06) + "/s33 " + witcher.GetSkillLevel(S_Magic_s33) + "; can use s07 " + witcher.CanUseSkill(S_Magic_s07) + ", s35 " + witcher.CanUseSkill(S_Magic_s35) + "; casting " + witcher.IsCastingSign() + "; " + GMTestFoaState(witcher));
}

function GMTestSignPower(witcher : W3PlayerWitcher, skill : ESkill) : float
{
	var power : SAbilityAttributeValue;

	power = witcher.GetTotalSignSpellPower(skill);
	return power.valueMultiplicative;
}

// Flood of Anger's live state: the temporary skills held, its sign active, the sign intensities.
function GMTestFoaState(witcher : W3PlayerWitcher) : string
{
	return "temp skills " + witcher.GetTempLearnedSignSkillsSize() + ", FoA sign active " + witcher.GMIsFoASignActive()
		+ ", intensity Igni " + GMTestSignPower(witcher, S_Magic_1) + " Quen " + GMTestSignPower(witcher, S_Magic_4) + " Yrden " + GMTestSignPower(witcher, S_Magic_3);
}

// SKL-07 Flood of Anger kept until the sign ends (legacy): during a Flood of Anger sign, a scripted hit
// on Geralt from the hostile test dummy (breakCast: with a hit animation, to break a channel) or 5.x's
// combat action end (actionEnd, called directly); logs the state before and after, and reports that the
// temporary skills and the intensity stayed (unless the sign ended).
exec function gmtest_skl07_foa_hit(breakCast : bool, optional actionEnd : bool)
{
	var witcher : W3PlayerWitcher;
	var npc : CActor;
	var action : W3Action_Attack;
	var skillsBefore, skillsAfter : int;
	var powerBefore, powerAfter : float;
	var what : string;

	witcher = GetWitcherPlayer();
	skillsBefore = witcher.GetTempLearnedSignSkillsSize();
	powerBefore = GMTestSignPower(witcher, S_Magic_1);
	LogChannel('GMTest', "INFO SKL-07 FoA before: casting " + witcher.IsCastingSign() + ", " + GMTestFoaState(witcher));
	if(actionEnd)
	{
		what = "a combat action end";
		witcher.OnCombatActionEnd();
	}
	else
	{
		npc = GMTestHostileNpc();
		if(!npc)
		{
			GMTestReport(false, "SKL-07 FoA hit: needs a hostile test dummy nearby");
			return;
		}
		what = "a hit (hit animation " + breakCast + ")";
		action = new W3Action_Attack in theGame.damageMgr;
		if(breakCast)
			action.Init(npc, witcher, NULL, GetInvalidUniqueId(), 'attack_heavy', npc.GetName(), EHRT_Heavy,
				false, false, '', AST_Jab, ASD_UpDown, true, false, false, false);
		else
			action.Init(npc, witcher, NULL, GetInvalidUniqueId(), 'attack_light', npc.GetName(), EHRT_Light,
				false, false, '', AST_Jab, ASD_UpDown, true, false, false, false);
		action.AddDamage(theGame.params.DAMAGE_NAME_DIRECT, witcher.GetStatMax(BCS_Vitality) * 0.05);
		action.SetSuppressHitSounds(true);
		if(breakCast)
			action.SetHitAnimationPlayType(EAHA_ForceYes);
		else
			action.SetHitAnimationPlayType(EAHA_ForceNo);
		theGame.damageMgr.ProcessAction(action);
		what += ", dealt " + action.GetDamageDealt();
		delete action;
	}
	skillsAfter = witcher.GetTempLearnedSignSkillsSize();
	powerAfter = GMTestSignPower(witcher, S_Magic_1);
	LogChannel('GMTest', "INFO SKL-07 FoA after " + what + ": casting " + witcher.IsCastingSign() + ", " + GMTestFoaState(witcher));
	if(witcher.GMIsFoASignActive())
		GMTestReport(skillsAfter == skillsBefore && AbsF(powerAfter - powerBefore) < 0.0001, "SKL-07 FoA kept after " + what + ": temp skills " + skillsBefore + " -> " + skillsAfter + ", Igni intensity " + powerBefore + " -> " + powerAfter);
	else
		GMTestReport(skillsAfter == 0 && witcher.GetAbilityCount('sword_s19') + witcher.GetAbilityCount('GM_C_sword_s19') == 0, "SKL-07 FoA sign ended by " + what + ": temp skills " + skillsAfter + ", Igni intensity " + powerBefore + " -> " + powerAfter);
}

// SKL-07: destroys the active Flood of Anger sign without its CleanUp (as 5.x does for some signs);
// gmtest_skl07_foa_state afterwards shows whether Flood of Anger was undone.
exec function gmtest_skl07_foa_destroy()
{
	var witcher : W3PlayerWitcher;

	witcher = GetWitcherPlayer();
	LogChannel('GMTest', "INFO SKL-07 FoA destroying sign " + witcher.gmFoaSign + ": " + GMTestFoaState(witcher));
	if(witcher.gmFoaSign)
		witcher.gmFoaSign.Destroy();
}

// SKL-07: aborts the active Flood of Anger sign (an interrupted cast, as 5.x's input or a hit does).
exec function gmtest_skl07_foa_abort()
{
	var witcher : W3PlayerWitcher;

	witcher = GetWitcherPlayer();
	LogChannel('GMTest', "INFO SKL-07 FoA aborting sign " + witcher.gmFoaSign + ": " + GMTestFoaState(witcher));
	if(witcher.gmFoaSign)
		witcher.gmFoaSign.OnSignAborted(true);
	LogChannel('GMTest', "INFO SKL-07 FoA after the abort: " + GMTestFoaState(witcher));
}

// SKL-03, SKL-04 new designs (D55, D57; revised 2026-11-07): the new tree's Precise Blows (crit chance) and
// Crushing Blows (crit damage), with stacks from non-crit fast or strong hits that a melee crit clears.
// A forced melee crit of Geralt's on the hostile test dummy (the probe records each crit's attack power).
function GMTestCritHitPowerNamed(victim : CActor, attackName : name) : float
{
	var action : W3Action_Attack;
	var step : SGMTestDmgStep;

	thePlayer.GMTestDmgReset();
	thePlayer.ForceSetStat(BCS_Focus, 0);
	action = new W3Action_Attack in theGame.damageMgr;
	action.Init(thePlayer, victim, NULL, GetInvalidUniqueId(), attackName, thePlayer.GetName(), EHRT_Light,
		false, false, attackName, AST_Jab, ASD_UpDown, true, false, false, false);
	action.SetCriticalHit();
	action.AddDamage(theGame.params.DAMAGE_NAME_PHYSICAL, 100);
	action.SetSuppressHitSounds(true);
	action.SetHitAnimationPlayType(EAHA_ForceNo);
	theGame.damageMgr.ProcessAction(action);
	step = GMTestDmgStep0();
	delete action;
	if(victim.UsesEssence())
		victim.ForceSetStat(BCS_Essence, victim.GetStatMax(BCS_Essence));
	else
		victim.ForceSetStat(BCS_Vitality, victim.GetStatMax(BCS_Vitality));
	return step.mult;
}

// A melee hit of Geralt's with the given attack name on the hostile test dummy, crit as rolled; true if
// it was a crit.
function GMTestBlowsRolledHit(victim : CActor, attackName : name) : bool
{
	var action : W3Action_Attack;
	var crit : bool;

	thePlayer.ForceSetStat(BCS_Focus, 0);
	action = new W3Action_Attack in theGame.damageMgr;
	action.Init(thePlayer, victim, NULL, GetInvalidUniqueId(), attackName, thePlayer.GetName(), EHRT_Light,
		false, false, attackName, AST_Jab, ASD_UpDown, true, false, false, false);
	action.AddDamage(theGame.params.DAMAGE_NAME_PHYSICAL, 100);
	action.SetSuppressHitSounds(true);
	action.SetHitAnimationPlayType(EAHA_ForceNo);
	theGame.damageMgr.ProcessAction(action);
	crit = action.IsCriticalHit();
	delete action;
	if(victim.UsesEssence())
		victim.ForceSetStat(BCS_Essence, victim.GetStatMax(BCS_Essence));
	else
		victim.ForceSetStat(BCS_Vitality, victim.GetStatMax(BCS_Vitality));
	return crit;
}

// Each scripted hit of one exec call runs at the same engine time: the tests start a new swing by hand.
@addMethod(W3PlayerWitcher)
function GMTestBlowsNewSwing()
{
	gmBlowsCritAt = 0;
	gmPreciseStackAt = 0;
	gmCrushingStackAt = 0;
}

// The skill's value at n stacks from its definition: Precise Blows' crit chance, Crushing Blows' crit damage.
function GMTestBlowsExpected(skill : ESkill, stacks : int) : float
{
	var w : W3PlayerWitcher;

	w = GetWitcherPlayer();
	if(skill == S_Sword_s24)
		return w.GMBlowsValue(skill, 'gm_crit_chance') + w.GMBlowsValue(skill, 'gm_stack_crit_chance') * stacks;
	return w.GMBlowsValue(skill, 'gm_crit_damage') + w.GMBlowsValue(skill, 'gm_stack_crit_damage') * stacks;
}

function GMTestBlowsRead(skill : ESkill) : float
{
	if(skill == S_Sword_s24)
		return GetWitcherPlayer().GMBlowsCritChance();
	return GetWitcherPlayer().GMBlowsCritDamage();
}

// heavy: Crushing Blows (strong attacks build its stacks), else Precise Blows (fast attacks). Needs the
// skill learned and equipped and the hostile test dummy. Checks: the value at 0 stacks and after each
// non-crit hit up to the cap and one past it (the owner's full values at every level, the cap by level:
// Precise Blows 2 / 3 / 4, Crushing Blows 1 / 2 / 3, revised 2026-11-07); the crit
// chance through GetCriticalHitChance for both attack types (Precise Blows); a forced crit at the cap
// gets the full stacked bonus (Crushing Blows: its attack power against a crit at 0 stacks) and clears
// both skills' stacks, while the rest of its swing still reads them; rolled hits stack or clear as
// they come out; combat's end clears the stacks.
function GMTestSklBlows(heavy : bool)
{
	var w : W3PlayerWitcher;
	var npc : CActor;
	var skill : ESkill;
	var attackName : name;
	var cap, i, n, expectedStacks, crits : int;
	var level, value, expected, first, second, light, strong, none : float;
	var ok, crit, probes : bool;
	var msg : string;

	w = GetWitcherPlayer();
	npc = GMTestHostileNpc();
	if(heavy)
	{
		skill = S_Sword_s25;
		attackName = 'attack_heavy';
	}
	else
	{
		skill = S_Sword_s24;
		attackName = 'attack_light';
	}
	if(!npc || !w.CanUseSkill(skill))
	{
		GMTestReport(false, "SKL blows: needs a hostile test dummy and the new tree's " + SkillEnumToName(skill) + " equipped");
		return;
	}
	level = w.GetSkillLevel(skill);
	cap = w.GMBlowsMaxStacks(skill);
	w.GMBlowsClear();

	// The stacks from non-crit hits, up to the cap.
	ok = w.GMBlowsStacks(skill) == 0 && AbsF(GMTestBlowsRead(skill) - GMTestBlowsExpected(skill, 0)) < 0.0005;
	msg = "0: " + GMTestBlowsRead(skill);
	for(i = 1; i <= cap + 1; i += 1)
	{
		w.GMTestBlowsNewSwing();
		w.GMBlowsOnHit(heavy);
		w.GMBlowsOnHit(heavy);	// a second enemy of the same swing adds none
		n = Min(i, cap);
		value = GMTestBlowsRead(skill);
		ok = ok && w.GMBlowsStacks(skill) == n && AbsF(value - GMTestBlowsExpected(skill, n)) < 0.0005;
		msg += ", " + w.GMBlowsStacks(skill) + ": " + value;
	}
	if(heavy)
		ok = ok && cap == RoundMath(level) && AbsF(GMTestBlowsExpected(skill, 0) - 0.5) < 0.0005 && AbsF(GMTestBlowsExpected(skill, 1) - 1.0) < 0.0005;
	else
		ok = ok && cap == RoundMath(level) + 1 && AbsF(GMTestBlowsExpected(skill, 0) - 0.05) < 0.0005 && AbsF(GMTestBlowsExpected(skill, 1) - 0.1) < 0.0005;
	GMTestReport(ok, "SKL blows " + SkillEnumToName(skill) + " level " + level + ": stacks: value " + msg + " (cap " + cap + ")");

	// Precise Blows' crit chance through 5.x's call, for fast and strong attacks, none for bolts and signs.
	if(!heavy)
	{
		none = w.GetCriticalHitChance(false, false, npc, MC_Human, false);
		light = w.GetCriticalHitChance(true, false, npc, MC_Human, false) - none;
		strong = w.GetCriticalHitChance(false, true, npc, MC_Human, false) - none;
		value = w.GetCriticalHitChance(true, false, npc, MC_Human, true) - w.GetCriticalHitChance(false, false, npc, MC_Human, true);
		expected = GMTestBlowsExpected(skill, cap);
		GMTestReport(AbsF(light - expected) < 0.0005 && AbsF(strong - expected) < 0.0005 && AbsF(value) < 0.0005,
			"SKL blows Precise Blows at " + cap + " stacks: crit chance fast +" + light + ", strong +" + strong + " (expected +" + expected + "), bolt +" + value);
	}

	// A forced crit at the cap: the full bonus, then both skills' stacks cleared; the rest of its swing
	// still reads them.
	probes = GMTestProbes();
	thePlayer.GMTestSetProbes(true);
	w.GMTestBlowsNewSwing();
	first = GMTestCritHitPowerNamed(npc, attackName);
	value = GMTestBlowsRead(skill);
	ok = AbsF(value - GMTestBlowsExpected(skill, cap)) < 0.0005 && w.gmPreciseStacks == 0 && w.gmCrushingStacks == 0;
	msg = "after the crit, same swing: " + value + ", stacks " + w.gmPreciseStacks + "/" + w.gmCrushingStacks;
	w.GMTestBlowsNewSwing();
	value = GMTestBlowsRead(skill);
	second = GMTestCritHitPowerNamed(npc, attackName);
	thePlayer.GMTestSetProbes(probes);
	ok = ok && AbsF(value - GMTestBlowsExpected(skill, 0)) < 0.0005;
	msg += "; next swing: " + value + "; crit attack power x" + first + " at " + cap + " stacks, x" + second + " at 0";
	if(heavy)
	{
		ok = ok && AbsF(first - second - (GMTestBlowsExpected(skill, cap) - GMTestBlowsExpected(skill, 0))) < 0.01;
		msg += " (+" + (GMTestBlowsExpected(skill, cap) - GMTestBlowsExpected(skill, 0)) + " expected)";
	}
	GMTestReport(ok, "SKL blows " + SkillEnumToName(skill) + " level " + level + ": " + msg);

	// The other skill's stacks: a crit of this attack type clears them too.
	if(w.CanUseSkill(S_Sword_s24) && w.CanUseSkill(S_Sword_s25))
	{
		w.GMTestBlowsNewSwing();
		w.GMBlowsOnHit(!heavy);
		ok = w.GMBlowsStacks(S_Sword_s24) + w.GMBlowsStacks(S_Sword_s25) == 1;
		w.GMTestBlowsNewSwing();
		GMTestCritHitPowerNamed(npc, attackName);
		w.GMTestBlowsNewSwing();
		GMTestReport(ok && w.GMBlowsStacks(S_Sword_s24) == 0 && w.GMBlowsStacks(S_Sword_s25) == 0,
			"SKL blows: a crit of a " + attackName + " clears the other skill's stack too");
	}

	// Rolled hits through the damage manager: a non-crit adds a stack, a crit clears them.
	w.GMBlowsClear();
	expectedStacks = 0;
	ok = true;
	msg = "";
	for(i = 0; i < 8; i += 1)
	{
		w.GMTestBlowsNewSwing();
		crit = GMTestBlowsRolledHit(npc, attackName);
		if(crit)
		{
			expectedStacks = 0;
			crits += 1;
		}
		else
			expectedStacks = Min(expectedStacks + 1, cap);
		w.GMTestBlowsNewSwing();
		ok = ok && w.GMBlowsStacks(skill) == expectedStacks;
		msg += " " + crit + ":" + w.GMBlowsStacks(skill);
	}
	GMTestReport(ok && crits < 8, "SKL blows " + SkillEnumToName(skill) + ": rolled " + attackName + " hits (crit:stacks)" + msg);

	// Combat's end clears them.
	w.GMTestBlowsNewSwing();
	w.GMBlowsOnHit(heavy);
	n = w.GMBlowsStacks(skill);
	w.OnCombatFinished();
	GMTestReport(n > 0 && w.GMBlowsStacks(skill) == 0 && w.gmPreciseStacks == 0 && w.gmCrushingStacks == 0,
		"SKL blows " + SkillEnumToName(skill) + ": combat's end clears the stacks (" + n + " -> " + w.GMBlowsStacks(skill) + ")");
	w.GMBlowsClear();
}

exec function gmtest_skl_blows(heavy : bool)
{
	GMTestSklBlows(heavy);
}

// The tooltip texts at levels 1 to 3 through the skill menu's tooltip function (English).
exec function gmtest_skl_blows_tooltips()
{
	var lvl : int;
	var text, expected : string;

	for(lvl = 1; lvl <= 3; lvl += 1)
	{
		text = GMSkillTooltip(S_Sword_s24, lvl, "");
		expected = "Increases critical hit chance by 5%, and by a further 5% for every Fast Attack until your next critical hit. Stacks up to " + IntToString(lvl + 1) + " times.";
		GMTestReport(text == expected, "SKL blows tooltip Precise Blows level " + lvl + ": " + text);
		text = GMSkillTooltip(S_Sword_s25, lvl, "");
		if(lvl == 1)
			expected = "Increases critical hit power by 50%, and by a further 50% for every Strong Attack until your next critical hit. Stacks once.";
		else
			expected = "Increases critical hit power by 50%, and by a further 50% for every Strong Attack until your next critical hit. Stacks up to " + IntToString(lvl) + " times.";
		GMTestReport(text == expected, "SKL blows tooltip Crushing Blows level " + lvl + ": " + text);
	}
}

// SKL-03, SKL-04: the new tree's Muscle Memory's and Strength Training's tooltips at each level (English):
// their bonuses 8/16/25 of 25 by level (owner, 2026-11-09).
exec function gmtest_skl04_st_tooltips()
{
	var lvl : int;
	var text, expected : string;
	var flat, dodge : array<string>;

	flat.PushBack("8"); flat.PushBack("16"); flat.PushBack("25");
	dodge.PushBack("16"); dodge.PushBack("32"); dodge.PushBack("50");
	for(lvl = 1; lvl <= 3; lvl += 1)
	{
		text = GMSkillTooltip(S_Sword_s23, lvl, "");
		expected = "Strong Attacks gain " + flat[lvl - 1] + "% Attack Power and increase the next strike's Attack Power by " + flat[lvl - 1]
			+ "%. Adrenaline gain for Strong Attacks is increased by " + IntToString(5 * lvl) + "%.";
		GMTestReport(text == expected, "SKL-04 Strength Training tooltip level " + lvl + ": " + text);
		text = GMSkillTooltip(S_Sword_s22, lvl, "");
		expected = "Fast Attacks gain " + flat[lvl - 1] + "% Attack Power. After a successful dodge or roll, your next 3 Fast Attacks, or your next Strong Attack, gain a further "
			+ dodge[lvl - 1] + "% Attack Power. Adrenaline gain for Fast Attacks is increased by " + IntToString(5 * lvl) + "%.";
		GMTestReport(text == expected, "SKL-03 Muscle Memory tooltip level " + lvl + ": " + text);
	}
}

// The stacks and the sword effects (fast_attack_buff, strong_attack_buff) now.
exec function gmtest_skl_blows_state()
{
	var w : W3PlayerWitcher;
	var sword : CWitcherSword;
	var s : string;

	w = GetWitcherPlayer();
	sword = w.GetHeldSwordEntity();
	if(sword)
		s = ", sword effects fast " + sword.IsEffectActive('fast_attack_buff') + ", strong " + sword.IsEffectActive('strong_attack_buff');
	else
		s = ", no sword held";
	LogChannel('GMTest', "INFO SKL blows t=" + theGame.GetEngineTimeAsSeconds() + ": Precise Blows stacks " + w.GMBlowsStacks(S_Sword_s24) + " (crit chance +" + w.GMBlowsCritChance() + "), Crushing Blows stacks " + w.GMBlowsStacks(S_Sword_s25) + " (crit damage +" + w.GMBlowsCritDamage() + ")" + s);
}

// Adds a stack as a non-crit hit of a new swing does (heavy: Crushing Blows).
exec function gmtest_skl_blows_hit(heavy : bool)
{
	var w : W3PlayerWitcher;

	w = GetWitcherPlayer();
	w.GMTestBlowsNewSwing();
	w.GMBlowsOnHit(heavy);
}

// SKL-04 Strength Training (D54): one scripted melee hit of Geralt's with the given attack name on the
// hostile test dummy (100 physical, no weapon), as a new swing: logs whether the next-strike bonus waited
// before and after, the raw damage after the pool and the attack power the probe recorded, and whether it
// was a crit.
exec function gmtest_skl04_st_hit(attackName : name)
{
	var witcher : W3PlayerWitcher;
	var npc : CActor;
	var action : W3Action_Attack;
	var step : SGMTestDmgStep;
	var probes : bool;
	var before : bool;

	witcher = GetWitcherPlayer();
	npc = GMTestHostileNpc();
	if(!npc)
		return;
	witcher.GMTestNewSwing();
	probes = GMTestProbes();
	thePlayer.GMTestSetProbes(true);
	thePlayer.GMTestDmgReset();
	witcher.ForceSetStat(BCS_Focus, 0);
	before = witcher.GMStrengthTrainingArmed();
	action = new W3Action_Attack in theGame.damageMgr;
	action.Init(thePlayer, npc, NULL, GetInvalidUniqueId(), attackName, thePlayer.GetName(), EHRT_Light,
		false, false, attackName, AST_Jab, ASD_UpDown, true, false, false, false);
	action.AddDamage(theGame.params.DAMAGE_NAME_PHYSICAL, 100);
	action.SetSuppressHitSounds(true);
	action.SetHitAnimationPlayType(EAHA_ForceNo);
	theGame.damageMgr.ProcessAction(action);
	step = GMTestDmgStep0();
	LogChannel('GMTest', "INFO SKL-04 Strength Training t=" + theGame.GetEngineTimeAsSeconds() + " " + attackName + ": next-strike bonus waiting " + before + " -> " + witcher.GMStrengthTrainingArmed() + ", raw after the pool " + step.rawIn + " (pool x" + (step.rawIn / thePlayer.gmTestDmgRawBefore) + "), attack power x" + step.mult + ", crit " + action.IsCriticalHit() + ", adrenaline " + witcher.GetStat(BCS_Focus));
	delete action;
	thePlayer.GMTestSetProbes(probes);
	npc.ForceSetStat(BCS_Vitality, npc.GetStatMax(BCS_Vitality));
}

// SKL-03 Muscle Memory (D53): a scripted attack of the hostile test dummy on Geralt that he dodged (5.x
// arms the skill in ReactToBeingHit), then the armed state.
exec function gmtest_skl03_mm_dodge()
{
	var witcher : W3PlayerWitcher;
	var npc : CActor;
	var action : W3Action_Attack;

	witcher = GetWitcherPlayer();
	npc = GMTestHostileNpc();
	if(!npc)
		return;
	action = new W3Action_Attack in theGame.damageMgr;
	action.Init(npc, witcher, NULL, GMTestNpcWeapon(npc), 'attack_light', npc.GetName(), EHRT_Light,
		false, false, 'attack_light', AST_Jab, ASD_UpDown, true, false, false, false);
	action.AddDamage(theGame.params.DAMAGE_NAME_PHYSICAL, 10);
	action.SetWasDodged();
	action.SetSuppressHitSounds(true);
	theGame.damageMgr.ProcessAction(action);
	delete action;
	LogChannel('GMTest', "INFO SKL-03 Muscle Memory t=" + theGame.GetEngineTimeAsSeconds() + " after a dodged attack: armed " + witcher.GMMuscleMemoryArmed() + ", boosts left " + witcher.gmMMRemaining);
}

// One scripted melee hit of Geralt's on the dummy (100 physical, no weapon): Muscle Memory's state before
// and after, the attack power and the final damage against the formula's result.
exec function gmtest_skl03_mm_hit(attackName : name)
{
	var witcher : W3PlayerWitcher;
	var npc : CActor;
	var action : W3Action_Attack;
	var step : SGMTestDmgStep;
	var probes : bool;
	var before : int;

	witcher = GetWitcherPlayer();
	npc = GMTestHostileNpc();
	if(!npc)
		return;
	probes = GMTestProbes();
	thePlayer.GMTestSetProbes(true);
	thePlayer.GMTestDmgReset();
	witcher.ForceSetStat(BCS_Focus, 0);
	before = witcher.gmMMRemaining;
	action = new W3Action_Attack in theGame.damageMgr;
	action.Init(thePlayer, npc, NULL, GetInvalidUniqueId(), attackName, thePlayer.GetName(), EHRT_Light,
		false, false, attackName, AST_Jab, ASD_UpDown, true, false, false, false);
	action.AddDamage(theGame.params.DAMAGE_NAME_PHYSICAL, 100);
	action.SetSuppressHitSounds(true);
	action.SetHitAnimationPlayType(EAHA_ForceNo);
	theGame.damageMgr.ProcessAction(action);
	step = GMTestDmgStep0();
	LogChannel('GMTest', "INFO SKL-03 Muscle Memory t=" + theGame.GetEngineTimeAsSeconds() + " " + attackName + ": boosts left " + before + " -> " + witcher.gmMMRemaining + " (armed " + witcher.GMMuscleMemoryArmed() + "), attack power x" + step.mult + ", dealt " + action.GetDamageDealt() + " / formula " + step.result + " = x" + (action.GetDamageDealt() / step.result) + ", crit " + action.IsCriticalHit() + ", adrenaline " + witcher.GetStat(BCS_Focus));
	delete action;
	thePlayer.GMTestSetProbes(probes);
	npc.ForceSetStat(BCS_Vitality, npc.GetStatMax(BCS_Vitality));
}

// SKL-03 Muscle Memory's own sword glow (gm_mm_buff, tools/gen_sword_glows.py): on the held sword while the
// skill is armed (expectArmed), off otherwise; 5.x's shared fast_attack_buff stays off unless Precise Blows
// has stacks. With checkPlay, also plays and stops gm_mm_buff once on the held sword when it is not armed
// (PlayEffect is false for an effect the sword's templates do not define).
exec function gmtest_skl03_mm_glow(expectArmed : bool, optional checkPlay : bool)
{
	var w : W3PlayerWitcher;
	var sword : CWitcherSword;
	var armed, mm, fast, played : bool;
	var which : string;

	w = GetWitcherPlayer();
	sword = w.GetHeldSwordEntity();
	if(!sword)
	{
		GMTestReport(false, "SKL-03 Muscle Memory glow: no sword held (gmtest_draw first)");
		return;
	}
	if(w.IsWeaponHeld('silversword'))
		which = "silver";
	else
		which = "steel";
	armed = w.GMMuscleMemoryArmed();
	mm = sword.IsEffectActive('gm_mm_buff');
	fast = sword.IsEffectActive('fast_attack_buff');
	GMTestReport(armed == expectArmed, "SKL-03 Muscle Memory glow (" + which + "): armed " + armed + ", expected " + expectArmed + " (boosts left " + w.gmMMRemaining + ")");
	GMTestReport(mm == expectArmed, "SKL-03 Muscle Memory glow (" + which + "): gm_mm_buff active " + mm + ", expected " + expectArmed);
	GMTestReport(!fast || w.GMBlowsStacks(S_Sword_s24) > 0, "SKL-03 Muscle Memory glow (" + which + "): fast_attack_buff active " + fast + " with Precise Blows stacks " + w.GMBlowsStacks(S_Sword_s24));
	if(checkPlay && !armed)
	{
		played = sword.PlayEffect('gm_mm_buff');
		mm = sword.IsEffectActive('gm_mm_buff');
		sword.StopEffect('gm_mm_buff');
		GMTestReport(played && mm, "SKL-03 Muscle Memory glow (" + which + "): the sword plays gm_mm_buff " + played + ", active " + mm + ", after StopEffect " + sword.IsEffectActive('gm_mm_buff'));
	}
}

// SKL-04 Strength Training's own sword glow (gm_st_buff, tools/gen_sword_glows.py): on the held sword while
// its next-strike bonus waits (expectArmed), off otherwise; 5.x's strong_attack_buff stays off unless
// Crushing Blows has stacks. With checkPlay, also plays and stops gm_st_buff once on the held sword when the
// bonus does not wait (PlayEffect is false for an effect the sword's templates do not define).
exec function gmtest_skl04_st_glow(expectArmed : bool, optional checkPlay : bool)
{
	var w : W3PlayerWitcher;
	var sword : CWitcherSword;
	var armed, st, strong, played : bool;
	var which : string;

	w = GetWitcherPlayer();
	sword = w.GetHeldSwordEntity();
	if(!sword)
	{
		GMTestReport(false, "SKL-04 Strength Training glow: no sword held (gmtest_draw first)");
		return;
	}
	if(w.IsWeaponHeld('silversword'))
		which = "silver";
	else
		which = "steel";
	armed = w.GMStrengthTrainingArmed();
	st = sword.IsEffectActive('gm_st_buff');
	strong = sword.IsEffectActive('strong_attack_buff');
	GMTestReport(armed == expectArmed, "SKL-04 Strength Training glow (" + which + "): armed " + armed + ", expected " + expectArmed);
	GMTestReport(st == expectArmed, "SKL-04 Strength Training glow (" + which + "): gm_st_buff active " + st + ", expected " + expectArmed);
	GMTestReport(!strong || w.GMBlowsStacks(S_Sword_s25) > 0, "SKL-04 Strength Training glow (" + which + "): strong_attack_buff active " + strong + " with Crushing Blows stacks " + w.GMBlowsStacks(S_Sword_s25));
	if(checkPlay && !armed)
	{
		played = sword.PlayEffect('gm_st_buff');
		st = sword.IsEffectActive('gm_st_buff');
		sword.StopEffect('gm_st_buff');
		GMTestReport(played && st, "SKL-04 Strength Training glow (" + which + "): the sword plays gm_st_buff " + played + ", active " + st + ", after StopEffect " + sword.IsEffectActive('gm_st_buff'));
	}
}

// SKL-18 perks: Geralt's stats the simple perks change and the perks' maximum levels.
exec function gmtest_skl18_perk_state()
{
	var witcher : W3PlayerWitcher;
	var regen, enc : SAbilityAttributeValue;

	witcher = GetWitcherPlayer();
	regen = witcher.GetAttributeValue('staminaRegen');
	enc = witcher.GetAttributeValue('encumbrance');
	LogChannel('GMTest', "INFO SKL-18 perks: max Vitality " + witcher.GetStatMax(BCS_Vitality) + ", max toxicity " + witcher.GetStatMax(BCS_Toxicity) + ", encumbrance " + CalculateAttributeValue(enc) + ", staminaRegen mult " + regen.valueMultiplicative + " (night " + theGame.envMgr.IsNight() + "), crit chance (light, no target) " + witcher.GetCriticalHitChance(true, false, NULL, MC_Human, false) + " at adrenaline " + witcher.GetStat(BCS_Focus)
		+ "; max levels perk_34 " + witcher.GetSkillMaxLevel(S_Perk_34) + ", perk_30 " + witcher.GetSkillMaxLevel(S_Perk_30) + ", perk_40 " + witcher.GetSkillMaxLevel(S_Perk_40) + ", perk_4 " + witcher.GetSkillMaxLevel(S_Perk_04) + "; classic profile " + GMIsClassicProfileInForce());
}

exec function gmtest_ability_count(abilityName : name)
{
	var min, max : SAbilityAttributeValue;

	LogChannel('GMTest', "INFO ability " + abilityName + ": on Geralt x" + thePlayer.GetAbilityCount(abilityName) + ", defined " + theGame.GetDefinitionsManager().IsAbilityDefined(abilityName));
}

// SKL-18 school perks and Adrenaline Burst: the perks' ability copies on Geralt (one per armor piece of
// the class), the attributes they give, the sign cost and the light-attack cost.
exec function gmtest_skl18_school()
{
	var witcher : W3PlayerWitcher;
	var cost, delay : float;

	witcher = GetWitcherPlayer();
	witcher.GetAbilityManager().GetStaminaActionCost(ESAT_LightAttack, cost, delay);
	LogChannel('GMTest', "INFO SKL-18 school: copies Cat " + (witcher.GetAbilityCount('perk_5') + witcher.GetAbilityCount('perk_23')) + ", Griffin " + (witcher.GetAbilityCount('perk_6') + witcher.GetAbilityCount('perk_24')) + ", Bear " + (witcher.GetAbilityCount('perk_7') + witcher.GetAbilityCount('perk_25'))
		+ "; crit chance " + CalculateAttributeValue(witcher.GetAttributeValue('critical_hit_chance')) + ", crit damage " + CalculateAttributeValue(witcher.GetAttributeValue('critical_hit_damage_bonus')) + ", Griffin cut " + witcher.GMGriffinSignCostCut() + ", bonus_focus_gain " + CalculateAttributeValue(witcher.GetAttributeValue('bonus_focus_gain'))
		+ ", max Vitality " + witcher.GetStatMax(BCS_Vitality) + "; Aard cost " + ((W3PlayerAbilityManager)witcher.GetAbilityManager()).GetSkillStaminaUseCost(S_Magic_1) + ", light attack cost " + cost + " at adrenaline " + witcher.GetStat(BCS_Focus) + " (Burst cut " + witcher.GMAdrenalineBurstCostCut() + "), focus_gain " + CalculateAttributeValue(witcher.GetAttributeValue('focus_gain')));
}

// SKL-18 Attack is the Best Defense: Geralt's stamina before and after one trigger on the hostile test
// dummy: 'crit' (a scripted melee crit), 'counter' (a scripted counter check) or 'kill' (the dummy at 1
// Vitality, a scripted hit); and the cooldown before and after.
exec function gmtest_skl18_aibd(trigger : name)
{
	var witcher : W3PlayerWitcher;
	var npc : CActor;
	var action : W3Action_Attack;
	var before, cost : float;
	var cdBefore : bool;
	var repel : int;

	witcher = GetWitcherPlayer();
	npc = GMTestHostileNpc();
	if(!npc)
		return;
	before = witcher.GetStat(BCS_Stamina);
	cdBefore = witcher.HasBuff(EET_Perk21InternalCooldown);
	if(trigger == 'crit')
		GMTestCritHitPowerNamed(npc, 'attack_light');
	else if(trigger == 'counter')
	{
		cost = witcher.GetStaminaActionCost(ESAT_Counterattack);
		witcher.GMTestCounterCheck(npc, true, 'attack_light', repel);
		npc.RemoveAllBuffsOfType(EET_CounterStrikeHit);
	}
	else if(trigger == 'kill')
	{
		npc.ForceSetStat(BCS_Vitality, 1);
		action = new W3Action_Attack in theGame.damageMgr;
		action.Init(thePlayer, npc, NULL, GetInvalidUniqueId(), 'attack_light', thePlayer.GetName(), EHRT_Light,
			false, false, 'attack_light', AST_Jab, ASD_UpDown, true, false, false, false);
		action.AddDamage(theGame.params.DAMAGE_NAME_PHYSICAL, 100);
		action.SetSuppressHitSounds(true);
		theGame.damageMgr.ProcessAction(action);
		delete action;
	}
	LogChannel('GMTest', "INFO SKL-18 Attack is the Best Defense, " + trigger + ": stamina " + before + " -> " + witcher.GetStat(BCS_Stamina) + " (counter cost " + cost + "), cooldown " + cdBefore + " -> " + witcher.HasBuff(EET_Perk21InternalCooldown) + ", dummy alive " + npc.IsAlive());
}

// SKL-18 Heavy Artillery: the maximum stack of a bomb in Geralt's inventory (added if missing), and
// whether Trick Shot is on.
exec function gmtest_skl18_ammo(itemName : name)
{
	var ids : array<SItemUniqueId>;

	ids = thePlayer.inv.GetItemsByName(itemName);
	if(ids.Size() == 0)
		ids = thePlayer.inv.AddAnItem(itemName, 1);
	LogChannel('GMTest', "INFO SKL-18 " + itemName + ": max stack " + thePlayer.inv.SingletonItemGetMaxAmmo(ids[0]) + ", Heavy Artillery " + SkillEnumToName(GetWitcherPlayer().GMHeavyArtillerySkill()) + ", Trick Shot " + GetWitcherPlayer().GMHasTrickShot());
}

// SKL-18 Metabolism Boosts: drinks a potion (added if missing) from 0 toxicity and logs the toxicity
// gained, the potion's own toxicity and the adrenaline before and after.
exec function gmtest_skl18_potion(itemName : name)
{
	var witcher : W3PlayerWitcher;
	var ids : array<SItemUniqueId>;
	var before, tox : float;

	witcher = GetWitcherPlayer();
	ids = witcher.inv.GetItemsByName(itemName);
	if(ids.Size() == 0)
		ids = witcher.inv.AddAnItem(itemName, 1);
	witcher.DrainToxicity(witcher.GetStat(BCS_Toxicity));
	witcher.RemoveAllBuffsOfType(EET_Swallow);
	before = witcher.GetStat(BCS_Focus);
	tox = CalculateAttributeValue(witcher.inv.GetItemAttributeValue(ids[0], 'toxicity'));
	witcher.DrinkPreparedPotion(EES_InvalidSlot, ids[0]);
	LogChannel('GMTest', "INFO SKL-18 Metabolism Boosts, " + itemName + " (toxicity " + tox + "): toxicity 0 -> " + witcher.GetStat(BCS_Toxicity) + ", adrenaline " + before + " -> " + witcher.GetStat(BCS_Focus));
}

// The check before drinking at the given toxicity: whether the potion may be drunk.
exec function gmtest_skl18_potion_check(itemName : name, toxicity : float)
{
	var witcher : W3PlayerWitcher;
	var ids : array<SItemUniqueId>;

	witcher = GetWitcherPlayer();
	ids = witcher.inv.GetItemsByName(itemName);
	if(ids.Size() == 0)
		ids = witcher.inv.AddAnItem(itemName, 1);
	witcher.DrainToxicity(witcher.GetStat(BCS_Toxicity));
	witcher.GainStat(BCS_Toxicity, toxicity);
	LogChannel('GMTest', "INFO SKL-18 Metabolism Boosts check, " + itemName + " at toxicity " + witcher.GetStat(BCS_Toxicity) + "/" + witcher.GetStatMax(BCS_Toxicity) + " and adrenaline " + witcher.GetStat(BCS_Focus) + ": may drink " + witcher.ToxicityLowEnoughToDrinkPotion(EES_InvalidSlot, ids[0]));
	witcher.DrainToxicity(witcher.GetStat(BCS_Toxicity));
}

// SKL-18 Gorged on Power: with add, gives Geralt Igni's Place of Power bonus; logs its time left and
// whether Gorged on Power counts (CanUseSkill(S_Perk_14)).
exec function gmtest_skl18_shrine(add : bool)
{
	var buff : CBaseGameplayEffect;

	if(add)
	{
		thePlayer.RemoveAllBuffsOfType(EET_ShrineIgni);
		thePlayer.AddEffectDefault(EET_ShrineIgni, thePlayer, "gmtest");
	}
	buff = thePlayer.GetBuff(EET_ShrineIgni);
	if(buff)
		LogChannel('GMTest', "INFO SKL-18 Gorged on Power t=" + theGame.GetEngineTimeAsSeconds() + ": shrine bonus time left " + buff.GetDurationLeft() + ", perk_14 counts " + thePlayer.CanUseSkill(S_Perk_14));
	else
		LogChannel('GMTest', "INFO SKL-18 Gorged on Power: no shrine bonus");
}

// SKL-18 Wolf School and Viper School (D61, revised 2026-11-07): gmtest_skl18_wolf_add(effect) gives the
// hostile test dummy one effect by name (stagger, longstagger, knockdown, heavyknockdown, counter, burning,
// confusion, blindness, wraithblindness, frozen, poison, bleeding; anything else: none) and reads ten times
// every 0.2 s; after its animation started, gmtest_skl18_wolf() logs the dummy's animated critical state,
// whether it counts as incapacitated or poisoned/bleeding, the crit chance against it (light, heavy, bolt)
// and without a target, each perk's crit chance and damage bonus, and a forced light crit's attack power.
exec function gmtest_skl18_wolf_add(effect : name)
{
	var npc : CActor;
	var type : EEffectType;

	npc = GMTestHostileNpc();
	if(!npc)
		return;
	switch(effect)
	{
		case 'stagger' :		type = EET_Stagger; break;
		case 'longstagger' :	type = EET_LongStagger; break;
		case 'knockdown' :		type = EET_Knockdown; break;
		case 'heavyknockdown' :	type = EET_HeavyKnockdown; break;
		case 'counter' :		type = EET_CounterStrikeHit; break;
		case 'burning' :		type = EET_Burning; break;
		case 'confusion' :		type = EET_Confusion; break;
		case 'blindness' :		type = EET_Blindness; break;
		case 'wraithblindness' :	type = EET_WraithBlindness; break;
		case 'frozen' :		type = EET_Frozen; break;
		case 'poison' :		type = EET_Poison; break;
		case 'bleeding' :		type = EET_Bleeding; break;
		default :				type = EET_Undefined;
	}
	if(type != EET_Undefined)
		npc.AddEffectDefault(type, GetWitcherPlayer(), "gmtest");
	LogChannel('GMTest', "INFO SKL-18 Wolf School: " + effect + " added " + npc.HasBuff(type));
	GetWitcherPlayer().GMTestWolfStartReads();
}

@addField(W3PlayerWitcher)
var gmTestWolfReads : int;

@addMethod(W3PlayerWitcher)
function GMTestWolfStartReads()
{
	gmTestWolfReads = 10;
	AddTimer('GMTestWolfRead', 0.2, true);
}

// Ten reads, one every 0.2 s.
@addMethod(W3PlayerWitcher)
timer function GMTestWolfRead(dt : float, id : int)
{
	var npc : CActor;

	npc = GMTestHostileNpc();
	if(npc)
	{
		LogChannel('GMTest', "INFO SKL-18 Wolf/Viper School read t=" + theGame.GetEngineTimeAsSeconds() + ": poisoned or bleeding " + GMIsPoisonedOrBleeding(npc) + ", confused " + npc.HasBuff(EET_Confusion) + ", blinded " + (npc.HasBuff(EET_Blindness) || npc.HasBuff(EET_WraithBlindness)) + ", frozen " + npc.HasBuff(EET_Frozen) + ", Wolf crit damage " + GMWolfSchoolBonus(npc, 'gm_wolf_crit_damage') + ", Viper crit damage " + GMViperSchoolBonus(npc, 'gm_viper_crit_damage'));
		LogChannel('GMTest', "INFO SKL-18 Wolf School read t=" + theGame.GetEngineTimeAsSeconds() + ": stagger " + npc.HasBuff(EET_Stagger) + ", long " + npc.HasBuff(EET_LongStagger) + ", knockdown " + npc.HasBuff(EET_Knockdown) + ", heavy " + npc.HasBuff(EET_HeavyKnockdown) + ", counter " + npc.HasBuff(EET_CounterStrikeHit) + ", burning " + npc.HasBuff(EET_Burning) + ", requested " + (bool)npc.GetNewRequestedCS() + ", incapacitated " + GMIsIncapacitated(npc) + ", crit chance " + GetCriticalHitChance(true, false, npc, MC_Human, false));
	}
	gmTestWolfReads -= 1;
	if(gmTestWolfReads <= 0)
		RemoveTimer('GMTestWolfRead');
}

exec function gmtest_skl18_wolf()
{
	GMTestWolfLog();
}

function GMTestWolfLog()
{
	var witcher : W3PlayerWitcher;
	var npc : CActor;
	var cs : CBaseGameplayEffect;
	var csName : string;

	witcher = GetWitcherPlayer();
	npc = GMTestHostileNpc();
	if(!npc)
		return;
	cs = npc.GetCurrentlyAnimatedCS();
	if(cs)
		csName = NameToString(EffectTypeToName(cs.GetEffectType()));
	else
		csName = "none";
	LogChannel('GMTest', "INFO SKL-18 Wolf/Viper School t=" + theGame.GetEngineTimeAsSeconds() + ": Wolf " + witcher.CanUseSkill(S_Perk_26) + " (copies " + witcher.GetAbilityCount('perk_26') + "), Viper " + witcher.CanUseSkill(S_Perk_28) + " (copies " + witcher.GetAbilityCount('perk_28') + "), animated state " + csName + ", incapacitated " + GMIsIncapacitated(npc) + ", poisoned or bleeding " + GMIsPoisonedOrBleeding(npc)
		+ "; crit chance vs dummy light " + witcher.GetCriticalHitChance(true, false, npc, MC_Human, false) + ", heavy " + witcher.GetCriticalHitChance(false, true, npc, MC_Human, false) + ", bolt " + witcher.GetCriticalHitChance(false, false, npc, MC_Human, true)
		+ ", light without target " + witcher.GetCriticalHitChance(true, false, NULL, MC_Human, false) + "; Wolf crit chance " + witcher.GMWolfSchoolBonus(npc, 'gm_wolf_crit_chance') + " damage " + witcher.GMWolfSchoolBonus(npc, 'gm_wolf_crit_damage') + ", Viper crit chance " + witcher.GMViperSchoolBonus(npc, 'gm_viper_crit_chance') + " damage " + witcher.GMViperSchoolBonus(npc, 'gm_viper_crit_damage')
		+ ", crit damage bonus " + witcher.GMWolfViperCritDamage(npc) + ", forced light crit attack power x" + GMTestCritHitPowerNamed(npc, 'attack_light'));
}

// SKL-18 Wolf School on a frozen enemy (project owner, 2026-11-07): forced light crits on the hostile test
// dummy (gmtest_probes(true) first): one clean, one that shatters a freeze added by script, the next one after
// the freeze is gone; their attack power and the dummy's state between them.
exec function gmtest_skl18_wolf_frozen()
{
	var witcher : W3PlayerWitcher;
	var npc : CActor;
	var clean, shatter, after : float;
	var frozenBefore, incapBefore, frozenAfter, incapAfter : bool;

	witcher = GetWitcherPlayer();
	npc = GMTestHostileNpc();
	if(!npc)
		return;
	npc.RemoveAllBuffsOfType(EET_Frozen);
	clean = GMTestCritHitPowerNamed(npc, 'attack_light');
	npc.AddEffectDefault(EET_Frozen, witcher, "gmtest");
	frozenBefore = npc.HasBuff(EET_Frozen);
	incapBefore = GMIsIncapacitated(npc);
	shatter = GMTestCritHitPowerNamed(npc, 'attack_light');
	frozenAfter = npc.HasBuff(EET_Frozen);
	after = GMTestCritHitPowerNamed(npc, 'attack_light');
	incapAfter = GMIsIncapacitated(npc);
	LogChannel('GMTest', "INFO SKL-18 Wolf School frozen: Wolf " + witcher.CanUseSkill(S_Perk_26) + ", clean crit attack power x" + clean + "; frozen " + frozenBefore + ", incapacitated " + incapBefore + ", shattering crit x" + shatter + ", frozen after it " + frozenAfter + "; next crit x" + after + ", incapacitated after it " + incapAfter);
}

// SKL-01 (D43), legacy's slot fixes, and the level sync of GlobalPassiveBonus skills. Test save at
// level 20 (below the last slots' level) for the slots, any level for the sync, with the profile of the tree under test in force. gmtest_skl01_slotfix(1), then dupemenu(),
// then gmtest_skl01_slotfix(2) with the menu open (it swaps through the menu's own event), then close
// it. gmtest_skl01_sync() on a fresh load.
@addMethod(W3PlayerAbilityManager)
function GMTestSetSkillMaxLevel(skill : ESkill, level : int)
{
	skills[skill].maxLevel = level;
}

@addMethod(W3PlayerAbilityManager)
function GMTestSetSlotUnlocked(slotID : int, unlocked : bool)
{
	var idx : int;

	idx = GetSkillSlotIndex(slotID, false);
	if(idx >= 0)
		skillSlots[idx].unlocked = unlocked;
}

// The slot outside the mutation group with the highest unlock level.
@addMethod(W3PlayerAbilityManager)
function GMTestLastLevelSlot() : int
{
	var i, best : int;

	best = -1;
	for(i = 0; i < skillSlots.Size(); i += 1)
	{
		if(skillSlots[i].groupID == MUTATION_SKILL_GROUP_ID)
			continue;
		if(best < 0 || skillSlots[i].unlockedOnLevel > skillSlots[best].unlockedOnLevel)
			best = i;
	}
	if(best < 0)
		return -1;
	return skillSlots[best].id;
}

// The slot a skill sits in (locked or not), or -1.
@addMethod(W3PlayerAbilityManager)
function GMTestSlotOf(skill : ESkill) : int
{
	var idx : int;

	idx = GetSkillSlotIndexFromSkill(skill);
	if(idx < 0)
		return -1;
	return skillSlots[idx].id;
}

// The test skills of the tree in force: 0 red, 1 blue, 2 green, 3 a second red, 4 Sun and Stars,
// 5 a GlobalPassiveBonus perk, 6 a second one (the new tree's: one 5.x tops up itself), 7 to 9 a
// second skill of each colour.
function GMTestSkl01Skill(kind : int) : ESkill
{
	var classic : bool;

	classic = GMIsClassicProfileInForce();
	switch(kind)
	{
		case 0:
			if(classic)
				return S_Sword_s21;
			return S_Sword_s22;
		case 1:
			if(classic)
				return S_Magic_s01;
			return S_Magic_s28;
		case 2:
			if(classic)
				return S_Alchemy_s01;
			return S_Alchemy_s24;
		case 3:
			if(classic)
				return S_Sword_s05;
			return S_Sword_s35;
		case 4:
			if(classic)
				return S_Perk_01;
			return S_Perk_38;
		case 5:
			if(classic)
				return S_Perk_04;
			return S_Perk_42;
		case 6:
			if(classic)
				return S_Perk_10;
			return S_Perk_30;
		case 7:
			if(classic)
				return S_Sword_s04;
			return S_Sword_s23;
		case 8:
			if(classic)
				return S_Magic_s02;
			return S_Magic_s31;
		case 9:
			if(classic)
				return S_Alchemy_s09;
			return S_Alchemy_s23;
	}
	return S_SUndefined;
}

function GMTestSkl01SkillOfColour(color : ESkillColor, notThis : ESkill) : ESkill
{
	var i : int;
	var skill : ESkill;

	for(i = 0; i < 10; i += 1)
	{
		if(i == 3)
			i = 7;
		skill = GMTestSkl01Skill(i);
		if(skill != notThis && thePlayer.GetSkillColor(skill) == color)
			return skill;
	}
	return S_SUndefined;
}

// Copies on Geralt of the abilities a skill's ability contains (Sun and Stars' day and night parts).
function GMTestContainedAbilityCount(skill : ESkill) : int
{
	var dm : CDefinitionsManagerAccessor;
	var abs : array<name>;
	var i, count : int;

	dm = theGame.GetDefinitionsManager();
	dm.GetContainedAbilities(thePlayer.GetSkillAbilityName(skill), abs);
	for(i = 0; i < abs.Size(); i += 1)
		count += thePlayer.GetAbilityCount(abs[i]);
	return count;
}

function GMTestOpenCharacterMenu() : CR4CharacterDupeMenu
{
	var common : CR4CommonMenu;

	common = (CR4CommonMenu)theGame.GetGuiManager().GetRootMenu();
	if(common)
		return (CR4CharacterDupeMenu)common.GetSubMenu();
	return NULL;
}

exec function gmtest_skl01_slotfix(phase : int)
{
	var witcher : W3PlayerWitcher;
	var pam : W3PlayerAbilityManager;
	var menu : CR4CharacterDupeMenu;
	var mutation : SMutation;
	var colour : ESkillColor;
	var lockedSkill, mutSkill, rightSkill, sunSkill, perkSkill : ESkill;
	var perkAbility : name;
	var lastSlot, slotA, slotB, sunBefore, sunAfter : int;
	var ok, researched : bool;

	witcher = GetWitcherPlayer();
	pam = (W3PlayerAbilityManager)witcher.abilityManager;
	lockedSkill = GMTestSkl01Skill(3);
	sunSkill = GMTestSkl01Skill(4);
	perkSkill = GMTestSkl01Skill(5);
	perkAbility = thePlayer.GetSkillAbilityName(perkSkill);
	mutation = witcher.GetMutation(EPMT_Mutation1);
	colour = mutation.colors[0];
	mutSkill = GMTestSkl01SkillOfColour(colour, lockedSkill);
	rightSkill = GMTestSkl01SkillOfColour(colour, mutSkill);
	LogChannel('GMTest', "INFO SKL-01 slotfix: classic profile " + GMIsClassicProfileInForce() + ", mutation 1 colour " + colour + ", skills locked " + lockedSkill + ", mutation slot " + mutSkill + ", second of its colour " + rightSkill + ", Sun and Stars " + sunSkill + ", perk " + perkSkill);

	if(phase == 1)
	{
		witcher.AddPoints(ESkillPoint, 40, false);
		witcher.inv.AddAnItem('Greater mutagen red', 12);
		witcher.inv.AddAnItem('Greater mutagen blue', 12);
		witcher.inv.AddAnItem('Greater mutagen green', 12);

		// a skill in a slot above Geralt's level (opened by 5.x's points rule in an older save), locked
		// on load (GMUpdateSkillSlotsByLevel(true), as PostInit does)
		lastSlot = pam.GMTestLastLevelSlot();
		pam.GMTestSetSlotUnlocked(lastSlot, true);
		skilleq_internal(lockedSkill, lastSlot, 1);
		pam.GMUpdateSkillSlotsByLevel(true);
		LogChannel('GMTest', "INFO SKL-01 slotfix: level " + witcher.GetLevel() + ", skill in slot " + pam.GMTestSlotOf(lockedSkill) + ", which is unlocked " + (pam.GetSkillSlotIndex(lastSlot, true) >= 0) + ", counts as equipped " + witcher.IsSkillEquipped(lockedSkill));
		ok = witcher.UnequipSkill(lastSlot);
		GMTestReport(ok && !witcher.IsSkillEquipped(lockedSkill) && pam.GMTestSlotOf(lockedSkill) < 0, "SKL-01 slotfix: a skill in a locked slot can be unequipped (slot " + lastSlot + ")");
		pam.GMTestSetSlotUnlocked(lastSlot, true);
		witcher.EquipSkill(lockedSkill, lastSlot);
		pam.GMUpdateSkillSlotsByLevel(true);

		// a skill in a mutation slot when the mutation is unequipped outside the menu: 5.x locks the slot
		// before it tries to unequip the skill (UpdateMutationSkillSlots), so the skill stays, locked
		researched = GMTestResearchMutation(EPMT_Mutation1);
		witcher.SetEquippedMutation(EPMT_Mutation1);
		pam.GMTestSetSlotUnlocked(BSS_SkillSlot1, true);
		witcher.AddSkill(mutSkill);
		witcher.EquipSkill(mutSkill, BSS_SkillSlot1);
		ok = pam.GMTestSlotOf(mutSkill) == BSS_SkillSlot1;
		witcher.SetEquippedMutation(EPMT_None);
		LogChannel('GMTest', "INFO SKL-01 slotfix: mutation researched " + researched + ", skill was in its slot " + ok + "; after the mutation was unequipped: in slot " + pam.GMTestSlotOf(mutSkill) + ", counts as equipped " + witcher.IsSkillEquipped(mutSkill));
		witcher.SetEquippedMutation(EPMT_Mutation1);
		skilleq_internal(sunSkill, 0, 1);
		skilleq_internal(perkSkill, 0, 1);
		if(rightSkill != S_SUndefined)
			skilleq_internal(rightSkill, 0, 1);
		LogChannel('GMTest', "INFO SKL-01 slotfix: slots: locked skill " + pam.GMTestSlotOf(lockedSkill) + ", mutation skill " + pam.GMTestSlotOf(mutSkill) + ", Sun and Stars " + pam.GMTestSlotOf(sunSkill) + " (parts " + GMTestContainedAbilityCount(sunSkill) + "), perk " + pam.GMTestSlotOf(perkSkill) + " (x" + witcher.GetAbilityCount(perkAbility) + "), second " + pam.GMTestSlotOf(rightSkill));
		return;
	}

	menu = GMTestOpenCharacterMenu();
	if(!menu)
	{
		LogChannel('GMTest', "FAIL SKL-01 slotfix: the character menu is not open");
		return;
	}

	// the menu removed the skills from the locked slots when it opened
	GMTestReport(pam.GMTestSlotOf(lockedSkill) < 0 && !witcher.IsSkillEquipped(lockedSkill), "SKL-01 slotfix: opening the menu unequips a skill from a locked slot");
	GMTestReport(pam.GMTestSlotOf(mutSkill) < 0 && !witcher.IsSkillEquipped(mutSkill), "SKL-01 slotfix: opening the menu unequips a skill from a locked mutation slot");
	pam.GMTestSetSlotUnlocked(BSS_SkillSlot1, true);
	witcher.EquipSkill(mutSkill, BSS_SkillSlot1);

	// a swap keeps each skill's bonuses
	slotA = pam.GMTestSlotOf(sunSkill);
	slotB = pam.GMTestSlotOf(perkSkill);
	sunBefore = GMTestContainedAbilityCount(sunSkill);
	menu.OnSwapSkill(sunSkill, slotB, perkSkill, slotA);
	sunAfter = GMTestContainedAbilityCount(sunSkill);
	GMTestReport(slotA > 0 && slotB > 0 && pam.GMTestSlotOf(sunSkill) == slotB && pam.GMTestSlotOf(perkSkill) == slotA, "SKL-01 slotfix: the swap moved Sun and Stars to slot " + pam.GMTestSlotOf(sunSkill) + " and the perk to " + pam.GMTestSlotOf(perkSkill) + " (from " + slotA + " and " + slotB + ")");
	GMTestReport(sunBefore > 0 && sunAfter == sunBefore && witcher.GetAbilityCount(perkAbility) == 1, "SKL-01 slotfix: after the swap Sun and Stars' parts " + sunAfter + " (before " + sunBefore + "), the perk's ability x" + witcher.GetAbilityCount(perkAbility));

	// no swap of a skill of the wrong colour into the mutation slot
	slotA = pam.GMTestSlotOf(perkSkill);
	menu.OnSwapSkill(perkSkill, BSS_SkillSlot1, mutSkill, slotA);
	GMTestReport(!mutation.colors.Contains(thePlayer.GetSkillColor(perkSkill)) && pam.GMTestSlotOf(perkSkill) == slotA && pam.GMTestSlotOf(mutSkill) == BSS_SkillSlot1, "SKL-01 slotfix: a perk (colour " + thePlayer.GetSkillColor(perkSkill) + ") cannot be swapped into the mutation slot");

	// a swap of the right colour goes through
	if(rightSkill != S_SUndefined)
	{
		slotA = pam.GMTestSlotOf(rightSkill);
		menu.OnSwapSkill(rightSkill, BSS_SkillSlot1, mutSkill, slotA);
		GMTestReport(pam.GMTestSlotOf(rightSkill) == BSS_SkillSlot1 && pam.GMTestSlotOf(mutSkill) == slotA && witcher.IsSkillEquipped(rightSkill) && witcher.IsSkillEquipped(mutSkill), "SKL-01 slotfix: a skill of the mutation's colour swaps into the mutation slot");
	}

	// for comparison, 5.x's swap (its OnSwapSkill's two EquipSkill calls) of Sun and Stars and the perk
	slotA = pam.GMTestSlotOf(sunSkill);
	slotB = pam.GMTestSlotOf(perkSkill);
	witcher.EquipSkill(sunSkill, slotB);
	witcher.EquipSkill(perkSkill, slotA);
	LogChannel('GMTest', "INFO SKL-01 slotfix: 5.x's swap sequence: Sun and Stars in slot " + pam.GMTestSlotOf(sunSkill) + " with parts " + GMTestContainedAbilityCount(sunSkill) + ", the perk in slot " + pam.GMTestSlotOf(perkSkill) + " x" + witcher.GetAbilityCount(perkAbility));
}

// The level sync: a GlobalPassiveBonus skill bought to level 3 while equipped (its maximum raised to 3
// for the test, as on 5.x's definitions) holds 3 copies; one 5.x tops up itself (perk_30) is not
// added twice.
exec function gmtest_skl01_sync()
{
	var witcher : W3PlayerWitcher;
	var pam : W3PlayerAbilityManager;
	var skill : ESkill;
	var abilityName : name;
	var i, k, before, after : int;
	var tagged : bool;

	witcher = GetWitcherPlayer();
	pam = (W3PlayerAbilityManager)witcher.abilityManager;
	witcher.AddPoints(ESkillPoint, 20, false);
	for(k = 5; k <= 6; k += 1)
	{
		skill = GMTestSkl01Skill(k);
		abilityName = thePlayer.GetSkillAbilityName(skill);
		tagged = theGame.GetDefinitionsManager().AbilityHasTag(abilityName, theGame.params.SKILL_GLOBAL_PASSIVE_TAG);
		pam.GMTestSetSkillMaxLevel(skill, 3);
		skilleq_internal(skill, 0, 1);
		before = witcher.GetAbilityCount(abilityName);
		for(i = 0; i < 2; i += 1)
			witcher.AddSkill(skill);
		after = witcher.GetAbilityCount(abilityName);
		GMTestReport(tagged && witcher.IsSkillEquipped(skill) && pam.GetSkillLevel(skill) == 3 && before == 1 && after == 3, "SKL-01 sync: " + abilityName + " (GlobalPassiveBonus " + tagged + ") x" + before + " at level 1, x" + after + " at level " + pam.GetSkillLevel(skill));
		pam.GMTestSetSkillMaxLevel(skill, 1);
	}
}

// SKL-01, situation-free (gmtest_regress): every skill of the profile in force whose ability is tagged
// GlobalPassiveBonus has one level (so the level sync has nothing to do in Ghost Mode's trees), and the
// swap's colour rule (no mutation equipped on the test save: nothing goes into a mutation slot).
@addMethod(W3PlayerAbilityManager)
function GMTestGlobalPassiveSkills(out multiLevel : string) : int
{
	var i, count : int;
	var dm : CDefinitionsManagerAccessor;

	dm = theGame.GetDefinitionsManager();
	multiLevel = "";
	for(i = 0; i < skills.Size(); i += 1)
	{
		if(skills[i].skillType == S_SUndefined || skills[i].isCoreSkill)
			continue;
		if(GMIsClassicProfileInForce() && skills[i].isReworked)
			continue;
		if(!dm.AbilityHasTag(skills[i].abilityName, theGame.params.SKILL_GLOBAL_PASSIVE_TAG))
			continue;
		count += 1;
		if(skills[i].maxLevel != 1)
			multiLevel += " " + skills[i].abilityName + "(" + skills[i].maxLevel + ")";
	}
	return count;
}

function GMTest_skl01_rules()
{
	var pam : W3PlayerAbilityManager;
	var count : int;
	var multiLevel : string;
	var noMutation : bool;

	pam = (W3PlayerAbilityManager)GetWitcherPlayer().abilityManager;
	count = pam.GMTestGlobalPassiveSkills(multiLevel);
	GMTestReport(count > 0 && multiLevel == "", "SKL-01 rules: " + count + " GlobalPassiveBonus skills in the profile in force, all of one level" + multiLevel);
	noMutation = GetWitcherPlayer().GetEquippedMutationType() == EPMT_None;
	GMTestReport(!noMutation || (!GMSwapSkillColoursAllowed(S_Sword_s21, BSS_SkillSlot1, S_Perk_01, 1) && GMSwapSkillColoursAllowed(S_Sword_s21, 2, S_Perk_01, 1)), "SKL-01 rules: without a mutation no swap into a mutation slot, a swap between other slots allowed");
}

exec function gmtest_skl01_rules()
{
	GMTest_skl01_rules();
}

// SKL audit F4: the ported values of the combat and sign skills and the perks (SKL-03 to SKL-12,
// SKL-18), situation-free (in gmtest_regress()), for the tree in force: each skill's ability and
// maximum level as the profile in force gives them, and every value Ghost Mode sets on that
// ability (5.x's terms it zeroes included), read from the definitions. Run it in both trees. The
// expected values are the port's XML (gm_skills.xml, gm_skill_trees.xml), which the SKL audit
// checked against legacy's; the alchemy skills are GMTest_alch's, the passives GMTest_skl01_passives'.
exec function gmtest_skl_values()
{
	GMTest_skl_values();
}

function GMTest_skl_values()
{
	var p, tree : string;
	var n : int;

	GMTest_skl07_trample();	// fix3 (data, read in both trees)
	GMTest_skl11_load();	// fix3: Quen not restored at a load
	GMTest_sklfix();	// the whole-port fix round (gmTestsSklFix.ws)
	if(GMIsClassicProfileInForce())
		tree = "classic";
	else if(GMIsNewTreeProfileInForce())
		tree = "new tree";
	else
	{
		LogChannel('GMTest', "INFO SKL values: no tree profile in force (gmreset() first), skipped");
		return;
	}
	GMTestSklValuesDefs(p, n);
	GMTestReport(p == "", "SKL values (" + tree + "): " + n + " skill definitions in force, ability and maximum level" + p);
	p = ""; n = 0;
	GMTestSklValues_sword(p, n);
	GMTestReport(p == "", "SKL values (" + tree + "): " + n + " values of the combat skills (SKL-03 to SKL-07)" + p);
	p = ""; n = 0;
	GMTestSklValues_magic(p, n);
	GMTestReport(p == "", "SKL values (" + tree + "): " + n + " values of the sign skills (SKL-08 to SKL-12)" + p);
	p = ""; n = 0;
	GMTestSklValues_perk(p, n);
	GMTestReport(p == "", "SKL values (" + tree + "): " + n + " values of the perks (SKL-18)" + p);
	p = ""; n = 0;
	GMTestSklIcons(p, n);
	GMTestReport(p == "", "SKL values (" + tree + "): " + n + " skill icons in force (SKL-18, SKL-19)" + p);
	p = ""; n = 0;
	GMTestSklValuesOther(p, n);
	GMTestReport(p == "", "SKL values: " + n + " values of the basic signs and the perks' effect abilities" + p);
}

// A skill's icon in force (GetSkillIconPath), by the end of its path (no backslashes in script strings): the
// classic tree's, the new tree's.
function GMTestSklIcon(out p : string, out n : int, skillName : name, classicIcon : string, newIcon : string)
{
	var expected, icon : string;

	if(GMIsClassicProfileInForce())
		expected = classicIcon;
	else
		expected = newIcon;
	icon = thePlayer.GetSkillIconPath(SkillNameToEnum(skillName));
	n += 1;
	if(!StrEndsWith(StrLower(icon), StrLower(expected)))
		p += "; " + skillName + " " + icon + " (expected ..." + expected + ")";
}

// SKL-18, SKL-19 (project owner, 2026-11-07): a new-tree slot that carries another skill than 5.x's shows that
// skill's classic icon while the new tree is in force (gm_skill_trees.xml); the classic tree keeps 5.x's. A
// few slots that keep 5.x's art, and classic skills, for comparison.
function GMTestSklIcons(out p : string, out n : int)
{
	GMTestSklIcon(p, n, 'perk_27', "manticore_school_techniques.png", "ico_trick_shot.png");
	GMTestSklIcon(p, n, 'perk_43', "synergy.png", "icon_perk_pyromaniac.png");
	GMTestSklIcon(p, n, 'perk_44', "element_of_surprise_2.png", "icon_perk_safe_hands.png");
	GMTestSklIcon(p, n, 'perk_37', "conjunction.png", "s_perk_16.png");
	GMTestSklIcon(p, n, 'perk_26', "wolven_school_techniques.png", "wolven_school_techniques.png");
	GMTestSklIcon(p, n, 'perk_28', "viper_school_techniques.png", "viper_school_techniques.png");
	GMTestSklIcon(p, n, 'alchemy_s22', "debilitating_poison.png", "alchemy_s17.png");
	GMTestSklIcon(p, n, 'alchemy_s23', "toxic_shock_2.png", "alchemy_s9.png");
	GMTestSklIcon(p, n, 'alchemy_s24', "heightened_tolerance.png", "alchemy_s1.png");
	GMTestSklIcon(p, n, 'alchemy_s25', "volatile_concoction.png", "alchemy_s6.png");
	GMTestSklIcon(p, n, 'alchemy_s26', "wyvern_sting.png", "alchemy_s19.png");
	GMTestSklIcon(p, n, 'magic_s35', "catalyst.png", "magic_s7.png");
	GMTestSklIcon(p, n, 'magic_s36', "fortified_signs.png", "magic_s18.png");
	GMTestSklIcon(p, n, 'magic_s37', "convergence_theory.png", "magic_s11.png");
	GMTestSklIcon(p, n, 'magic_s38', "focus.png", "magic_s13.png");
	GMTestSklIcon(p, n, 'magic_s39', "avoidance.png", "magic_s6.png");
	GMTestSklIcon(p, n, 'magic_s40', "overload.png", "magic_s15.png");
	GMTestSklIcon(p, n, 'magic_s41', "resonance.png", "magic_s9.png");
	GMTestSklIcon(p, n, 'perk_20', "icon_perk_pyromaniac.png", "icon_perk_pyromaniac.png");
	GMTestSklIcon(p, n, 'perk_17', "ico_trick_shot.png", "ico_trick_shot.png");
	GMTestSklIcon(p, n, 'alchemy_s19', "alchemy_s19.png", "alchemy_s19.png");
	GMTestSklIcon(p, n, 'magic_s12', "magic_s6.png", "magic_s6.png");
}

function GMTestSklAbilityValue(abilityName : name, attributeName : name, kind : name) : float
{
	var min, max : SAbilityAttributeValue;

	theGame.GetDefinitionsManager().GetAbilityAttributeValue(abilityName, attributeName, min, max);
	if(kind == 'add')
		return min.valueAdditive;
	if(kind == 'mult')
		return min.valueMultiplicative;
	if(kind == 'base' && min.valueMultiplicative != 0)
		return CalculateAttributeValue(min);	// with the definition's multiplier, as the game reads it
	if(kind == 'base')
		return min.valueBase + min.valueAdditive;
	return min.valueAdditive + min.valueMultiplicative + min.valueBase;
}

function GMTestSklDef(out p : string, out n : int, skillName : name, classicAbility : name, classicMax : int, newAbility : name, newMax : int)
{
	var witcher : W3PlayerWitcher;
	var skill : ESkill;
	var ability : name;
	var maxLevel : int;

	if(GMIsClassicProfileInForce())
	{
		ability = classicAbility;
		maxLevel = classicMax;
	}
	else
	{
		ability = newAbility;
		maxLevel = newMax;
	}
	if(!IsNameValid(ability))
		return;
	witcher = GetWitcherPlayer();
	skill = SkillNameToEnum(skillName);
	n += 1;
	if(witcher.GetSkillAbilityName(skill) != ability || witcher.GetSkillMaxLevel(skill) != maxLevel)
		p += "; " + skillName + ": " + witcher.GetSkillAbilityName(skill) + " " + witcher.GetSkillMaxLevel(skill) + " (expected " + ability + " " + maxLevel + ")";
}

function GMTestSklValue(out p : string, out n : int, skillName : name, attributeName : name, kind : name, classic : float, newTree : float)
{
	var expected, value : float;
	var ability : name;

	if(GMIsClassicProfileInForce())
		expected = classic;
	else
		expected = newTree;
	if(expected < -999999)
		return;
	ability = GetWitcherPlayer().GetSkillAbilityName(SkillNameToEnum(skillName));
	value = GMTestSklAbilityValue(ability, attributeName, kind);
	n += 1;
	if(AbsF(value - expected) >= 0.0001)
		p += "; " + ability + " " + attributeName + " " + value + " (expected " + expected + ")";
}

function GMTestSklAbility(out p : string, out n : int, abilityName : name, attributeName : name, kind : name, expected : float)
{
	var value : float;

	value = GMTestSklAbilityValue(abilityName, attributeName, kind);
	n += 1;
	if(AbsF(value - expected) >= 0.0001)
		p += "; " + abilityName + " " + attributeName + " " + value + " (expected " + expected + ")";
}

// The skill definitions in force: ability and maximum level of each skill of the tree in force (classic ability, levels, new-tree ability, levels; '' : not a skill of that tree).
function GMTestSklValuesDefs(out p : string, out n : int)
{
	GMTestSklDef(p, n, 'magic_s1', 'magic_s1', 3, 'magic_s1', 3);
	GMTestSklDef(p, n, 'magic_s10', 'magic_s10', 3, '', 0);
	GMTestSklDef(p, n, 'magic_s11', 'GM_C_magic_s11', 5, 'magic_s11', 3);
	GMTestSklDef(p, n, 'magic_s12', 'magic_s12', 5, '', 0);
	GMTestSklDef(p, n, 'magic_s13', 'magic_s13', 3, 'magic_s13', 3);
	GMTestSklDef(p, n, 'magic_s14', 'magic_s14', 5, '', 0);
	GMTestSklDef(p, n, 'magic_s15', 'magic_s15', 5, '', 0);
	GMTestSklDef(p, n, 'magic_s16', 'magic_s16', 5, '', 0);
	GMTestSklDef(p, n, 'magic_s17', 'magic_s17', 3, 'magic_s17', 3);
	GMTestSklDef(p, n, 'magic_s18', 'magic_s18', 5, '', 0);
	GMTestSklDef(p, n, 'magic_s19', 'magic_s19', 3, 'magic_s19', 3);
	GMTestSklDef(p, n, 'magic_s2', 'magic_s2', 3, '', 0);
	GMTestSklDef(p, n, 'magic_s28', '', 0, 'magic_s28', 3);
	GMTestSklDef(p, n, 'magic_s3', 'magic_s3', 3, 'magic_s3', 3);
	GMTestSklDef(p, n, 'magic_s31', '', 0, 'magic_s31', 3);
	GMTestSklDef(p, n, 'magic_s33', '', 0, 'magic_s33', 3);
	GMTestSklDef(p, n, 'magic_s35', '', 0, 'magic_s35', 3);
	GMTestSklDef(p, n, 'magic_s36', '', 0, 'magic_s36', 3);
	GMTestSklDef(p, n, 'magic_s37', '', 0, 'magic_s37', 3);
	GMTestSklDef(p, n, 'magic_s38', '', 0, 'magic_s38', 3);
	GMTestSklDef(p, n, 'magic_s39', '', 0, 'magic_s39', 3);
	GMTestSklDef(p, n, 'magic_s4', 'magic_s4', 3, 'magic_s4', 3);
	GMTestSklDef(p, n, 'magic_s40', '', 0, 'magic_s40', 3);
	GMTestSklDef(p, n, 'magic_s41', '', 0, 'magic_s41', 3);
	GMTestSklDef(p, n, 'magic_s42', '', 0, 'magic_s42', 3);
	GMTestSklDef(p, n, 'magic_s5', 'magic_s5', 3, '', 0);
	GMTestSklDef(p, n, 'magic_s6', 'magic_s6', 5, '', 0);
	GMTestSklDef(p, n, 'magic_s7', 'magic_s7', 5, '', 0);
	GMTestSklDef(p, n, 'magic_s8', 'GM_C_magic_s8', 5, 'magic_s8', 3);
	GMTestSklDef(p, n, 'magic_s9', 'magic_s9', 5, '', 0);
	GMTestSklDef(p, n, 'perk_1', 'perk_1', 1, '', 0);
	GMTestSklDef(p, n, 'perk_10', 'perk_10', 1, '', 0);
	GMTestSklDef(p, n, 'perk_11', 'perk_11', 1, '', 0);
	GMTestSklDef(p, n, 'perk_12', 'perk_12', 1, '', 0);
	GMTestSklDef(p, n, 'perk_18', 'perk_18', 1, '', 0);
	GMTestSklDef(p, n, 'perk_19', 'perk_19', 1, '', 0);
	GMTestSklDef(p, n, 'perk_2', 'perk_2', 1, '', 0);
	GMTestSklDef(p, n, 'perk_20', 'perk_20', 1, '', 0);
	GMTestSklDef(p, n, 'perk_21', 'perk_21', 1, '', 0);
	GMTestSklDef(p, n, 'perk_22', 'perk_22', 1, '', 0);
	GMTestSklDef(p, n, 'perk_23', '', 0, 'perk_23', 1);
	GMTestSklDef(p, n, 'perk_24', '', 0, 'perk_24', 1);
	GMTestSklDef(p, n, 'perk_25', '', 0, 'perk_25', 1);
	GMTestSklDef(p, n, 'perk_26', '', 0, 'perk_26', 1);
	GMTestSklDef(p, n, 'perk_27', '', 0, 'perk_27', 1);
	GMTestSklDef(p, n, 'perk_28', '', 0, 'perk_28', 1);
	GMTestSklDef(p, n, 'perk_30', '', 0, 'perk_30', 1);
	GMTestSklDef(p, n, 'perk_31', '', 0, 'perk_31', 1);
	GMTestSklDef(p, n, 'perk_32', '', 0, 'perk_32', 1);
	GMTestSklDef(p, n, 'perk_33', '', 0, 'perk_33', 1);
	GMTestSklDef(p, n, 'perk_35', '', 0, 'perk_35', 1);
	GMTestSklDef(p, n, 'perk_37', '', 0, 'perk_37', 1);
	GMTestSklDef(p, n, 'perk_38', '', 0, 'perk_38', 1);
	GMTestSklDef(p, n, 'perk_39', '', 0, 'perk_39', 1);
	GMTestSklDef(p, n, 'perk_4', 'perk_4', 1, '', 0);
	GMTestSklDef(p, n, 'perk_40', '', 0, 'perk_40', 1);
	GMTestSklDef(p, n, 'perk_42', '', 0, 'perk_42', 1);
	GMTestSklDef(p, n, 'perk_43', '', 0, 'perk_43', 1);
	GMTestSklDef(p, n, 'perk_44', '', 0, 'perk_44', 1);
	GMTestSklDef(p, n, 'perk_5', 'perk_5', 1, '', 0);
	GMTestSklDef(p, n, 'perk_6', 'perk_6', 1, '', 0);
	GMTestSklDef(p, n, 'perk_7', 'perk_7', 1, '', 0);
	GMTestSklDef(p, n, 'sword_s1', 'sword_s1', 5, '', 0);
	GMTestSklDef(p, n, 'sword_s10', 'sword_s10', 3, '', 0);
	GMTestSklDef(p, n, 'sword_s11', 'sword_s11', 3, '', 0);
	GMTestSklDef(p, n, 'sword_s12', 'sword_s12', 5, '', 0);
	GMTestSklDef(p, n, 'sword_s13', 'sword_s13', 3, '', 0);
	GMTestSklDef(p, n, 'sword_s15', 'sword_s15', 5, '', 0);
	GMTestSklDef(p, n, 'sword_s16', 'GM_C_sword_s16', 5, 'sword_s16', 3);
	GMTestSklDef(p, n, 'sword_s17', 'sword_s17', 5, '', 0);
	GMTestSklDef(p, n, 'sword_s18', 'GM_C_sword_s18', 5, 'sword_s18', 3);
	GMTestSklDef(p, n, 'sword_s19', 'GM_C_sword_s19', 5, 'sword_s19', 3);
	GMTestSklDef(p, n, 'sword_s2', 'GM_C_sword_s2', 5, 'sword_s2', 3);
	GMTestSklDef(p, n, 'sword_s20', 'GM_C_sword_s20', 5, 'sword_s20', 3);
	GMTestSklDef(p, n, 'sword_s21', 'sword_s21', 5, '', 0);
	GMTestSklDef(p, n, 'sword_s22', '', 0, 'sword_s22', 3);
	GMTestSklDef(p, n, 'sword_s23', '', 0, 'sword_s23', 3);
	GMTestSklDef(p, n, 'sword_s24', '', 0, 'sword_s24', 3);
	GMTestSklDef(p, n, 'sword_s25', '', 0, 'sword_s25', 3);
	GMTestSklDef(p, n, 'sword_s26', '', 0, 'sword_s26', 3);
	GMTestSklDef(p, n, 'sword_s27', '', 0, 'sword_s27', 3);
	GMTestSklDef(p, n, 'sword_s28', '', 0, 'sword_s28', 3);
	GMTestSklDef(p, n, 'sword_s29', '', 0, 'sword_s29', 3);
	GMTestSklDef(p, n, 'sword_s30', '', 0, 'sword_s30', 3);
	GMTestSklDef(p, n, 'sword_s31', '', 0, 'sword_s31', 3);
	GMTestSklDef(p, n, 'sword_s32', '', 0, 'sword_s32', 3);
	GMTestSklDef(p, n, 'sword_s33', '', 0, 'sword_s33', 3);
	GMTestSklDef(p, n, 'sword_s34', '', 0, 'sword_s34', 3);
	GMTestSklDef(p, n, 'sword_s35', '', 0, 'sword_s35', 3);
	GMTestSklDef(p, n, 'sword_s36', '', 0, 'sword_s36', 3);
	GMTestSklDef(p, n, 'sword_s4', 'sword_s4', 5, '', 0);
	GMTestSklDef(p, n, 'sword_s5', 'sword_s5', 5, '', 0);
	GMTestSklDef(p, n, 'sword_s6', 'sword_s6', 5, '', 0);
	GMTestSklDef(p, n, 'sword_s7', 'sword_s7', 5, '', 0);
	GMTestSklDef(p, n, 'sword_s8', 'sword_s8', 5, '', 0);
	GMTestSklDef(p, n, 'sword_s9', 'sword_s9', 5, '', 0);
}

// The combat skills (SKL-03 to SKL-07): every ported value per level of the skill's ability in force (the attribute's type; classic, new tree; -1000000: not a skill of that tree).
function GMTestSklValues_sword(out p : string, out n : int)
{
	GMTestSklValue(p, n, 'sword_s1', 'stamina_cost_per_sec', 'add', 50, -1000000);
	GMTestSklValue(p, n, 'sword_s1', 'stamina_delay', 'add', 1, -1000000);
	GMTestSklValue(p, n, 'sword_s1', 'stamina_cost_reduction_after_1', 'add', 0.15, -1000000);
	GMTestSklValue(p, n, 'sword_s1', 'whirl_dmg_bonus', 'mult', 0.01, -1000000);
	GMTestSklValue(p, n, 'sword_s1', 'whirl_dmg_reduction', 'mult', 0.25, -1000000);
	GMTestSklValue(p, n, 'sword_s1', 'whirl_dmg_reduction_bonus_after_1', 'mult', 0.0625, -1000000);
	GMTestSklValue(p, n, 'sword_s10', 's10_damage_reduction', 'add', 0.1, -1000000);
	GMTestSklValue(p, n, 'sword_s10', 'damage_increase', 'add', 0.5, -1000000);
	GMTestSklValue(p, n, 'sword_s10', 'parry_cost_decrease', 'add', 0.5, -1000000);
	GMTestSklValue(p, n, 'sword_s11', 'attack_power', 'mult', 0.334, -1000000);
	GMTestSklValue(p, n, 'sword_s11', 'critical_hit_chance', 'add', 0.35, -1000000);
	GMTestSklValue(p, n, 'sword_s11', 's11_knockdown_chance', 'add', 0.05, -1000000);
	GMTestSklValue(p, n, 'sword_s11', 'duration', 'add', 5, -1000000);
	GMTestSklValue(p, n, 'sword_s12', 'duration', 'add', 5, -1000000);
	GMTestSklValue(p, n, 'sword_s13', 'slowdown_mod', 'add', 0.15, -1000000);
	GMTestSklValue(p, n, 'sword_s15', 'focus_gain', 'add', 0, -1000000);
	GMTestSklValue(p, n, 'sword_s15', 'xbow_dmg_bonus', 'add', 10, -1000000);
	GMTestSklValue(p, n, 'sword_s16', 'focus_drain_reduction', 'add', 0.2, 0.333333);
	GMTestSklValue(p, n, 'sword_s17', 'critical_hit_chance', 'add', 0.02, -1000000);
	GMTestSklValue(p, n, 'sword_s17', 'critical_hit_damage_bonus', 'add', 0.15, -1000000);
	GMTestSklValue(p, n, 'sword_s18', 'trigger_delay', 'add', 120, 120);
	GMTestSklValue(p, n, 'sword_s19', 'spell_power', 'mult', 0.5, 0.833333);
	GMTestSklValue(p, n, 'sword_s2', 'armor_reduction', '', 1000, -1000000);
	GMTestSklValue(p, n, 'sword_s2', 'critical_hit_chance', 'add', 0.2, 0.333333);
	GMTestSklValue(p, n, 'sword_s2', 'attack_damage_bonus', 'mult', 0.1, 0.166667);
	GMTestSklValue(p, n, 'sword_s2', 'adrenaline_final_damage_bonus', 'mult', 0.1, 0.166667);
	GMTestSklValue(p, n, 'sword_s2', 'stamina_max_dmg_bonus', 'mult', 0.002, 0.003333);
	GMTestSklValue(p, n, 'sword_s2', 'stamina_cost', 'add', 0, -1000000);
	GMTestSklValue(p, n, 'sword_s2', 'stamina_cost_per_sec', 'add', 50, -1000000);
	GMTestSklValue(p, n, 'sword_s2', 'stamina_delay', 'add', 1, 1);
	GMTestSklValue(p, n, 'sword_s2', 'gm_classic_tree', 'add', 1, -1000000);
	GMTestSklValue(p, n, 'sword_s20', 'focus_add', 'add', 0.25, 0.416667);
	GMTestSklValue(p, n, 'sword_s20', 'focus_gain', 'add', 0.05, 0.083333);
	GMTestSklValue(p, n, 'sword_s21', 'light_focus_gain', 'add', 0.03, -1000000);
	GMTestSklValue(p, n, 'sword_s22', 'damage_increase', 'mult', -1000000, 0);
	GMTestSklValue(p, n, 'sword_s22', 'gm_mm_attack_power', 'add', -1000000, 0.25);
	GMTestSklValue(p, n, 'sword_s22', 'gm_mm_dodge_attack_power', 'add', -1000000, 0.5);
	GMTestSklValue(p, n, 'sword_s22', 'gm_mm_attacks', 'add', -1000000, 3);
	GMTestSklValue(p, n, 'sword_s22', 'gm_mm_window', 'add', -1000000, 6);
	GMTestSklValue(p, n, 'sword_s22', 'light_focus_gain', 'add', -1000000, 0.05);
	GMTestSklValue(p, n, 'sword_s23', 'damage_increase', 'mult', -1000000, 0);
	GMTestSklValue(p, n, 'sword_s23', 'gm_st_attack_power', 'add', -1000000, 0.25);
	GMTestSklValue(p, n, 'sword_s23', 'gm_st_next_attack_power', 'add', -1000000, 0.25);
	GMTestSklValue(p, n, 'sword_s23', 'gm_st_duration', 'add', -1000000, 6);
	GMTestSklValue(p, n, 'sword_s23', 'heavy_focus_gain', 'add', -1000000, 0.05);
	GMTestSklValue(p, n, 'sword_s24', 'damage_increase', 'mult', -1000000, 0);
	GMTestSklValue(p, n, 'sword_s24', 'gm_crit_chance', 'add', -1000000, 0.05);
	GMTestSklValue(p, n, 'sword_s24', 'gm_stack_crit_chance', 'add', -1000000, 0.05);
	GMTestSklValue(p, n, 'sword_s24', 'gm_max_stacks', 'add', -1000000, 4);
	GMTestSklValue(p, n, 'sword_s25', 'damage_increase', 'mult', -1000000, 0);
	GMTestSklValue(p, n, 'sword_s25', 'gm_crit_damage', 'add', -1000000, 0.5);
	GMTestSklValue(p, n, 'sword_s25', 'gm_stack_crit_damage', 'add', -1000000, 0.5);
	GMTestSklValue(p, n, 'sword_s25', 'gm_max_stacks', 'add', -1000000, 3);
	GMTestSklValue(p, n, 'sword_s26', 'critical_hit_chance', 'add', -1000000, 0.083333);
	GMTestSklValue(p, n, 'sword_s26', 'critical_hit_damage_bonus', 'add', -1000000, 0.25);
	GMTestSklValue(p, n, 'sword_s27', 'duration', 'add', -1000000, 8.333333);
	GMTestSklValue(p, n, 'sword_s28', 'armor_reduction_perc', 'add', -1000000, 0.083333);
	GMTestSklValue(p, n, 'sword_s29', 'sword_s5_chance', 'add', -1000000, 0.083333);
	GMTestSklValue(p, n, 'sword_s29', 'sword_s5_duration', 'add', -1000000, 8);
	GMTestSklValue(p, n, 'sword_s29', 'sword_s5_dmg_per_sec', 'add', -1000000, 0.01);
	GMTestSklValue(p, n, 'sword_s29', 'sword_s5_dmg_boost', 'add', -1000000, 0.083333);
	GMTestSklValue(p, n, 'sword_s30', 'instant_kill_chance', 'add', -1000000, 0.01);
	GMTestSklValue(p, n, 'sword_s31', 'attack_power', 'mult', -1000000, 0.334);
	GMTestSklValue(p, n, 'sword_s31', 'critical_hit_chance', 'add', -1000000, 0.35);
	GMTestSklValue(p, n, 'sword_s31', 's11_knockdown_chance', 'add', -1000000, 0.05);
	GMTestSklValue(p, n, 'sword_s31', 'duration', 'add', -1000000, 5);
	GMTestSklValue(p, n, 'sword_s32', 'slowdown_mod', 'add', -1000000, 0.25);
	GMTestSklValue(p, n, 'sword_s32', 'damage_increase', 'add', -1000000, 0);
	GMTestSklValue(p, n, 'sword_s32', 'instant_kill_chance', 'add', -1000000, 0);
	GMTestSklValue(p, n, 'sword_s33', 's10_damage_reduction', 'add', -1000000, 0.1);
	GMTestSklValue(p, n, 'sword_s33', 'damage_increase', 'add', -1000000, 0.5);
	GMTestSklValue(p, n, 'sword_s33', 'parry_cost_decrease', 'add', -1000000, 0.5);
	GMTestSklValue(p, n, 'sword_s33', 'instant_kill_chance', 'add', -1000000, 0);
	GMTestSklValue(p, n, 'sword_s34', 'focus_gain_lvl1', 'add', -1000000, 0);
	GMTestSklValue(p, n, 'sword_s34', 'focus_gain_lvl2', 'add', -1000000, 0);
	GMTestSklValue(p, n, 'sword_s34', 'focus_gain_lvl3', 'add', -1000000, 0);
	GMTestSklValue(p, n, 'sword_s34', 'xbow_dmg_bonus', 'add', -1000000, 16.666667);
	GMTestSklValue(p, n, 'sword_s35', 'stamina_cost_per_sec', 'add', -1000000, 50);
	GMTestSklValue(p, n, 'sword_s35', 'stamina_delay', 'add', -1000000, 1);
	GMTestSklValue(p, n, 'sword_s35', 'cost_reduction_desc_lvl2', 'mult', -1000000, 0.3);
	GMTestSklValue(p, n, 'sword_s35', 'cost_reduction_desc_lvl3', 'mult', -1000000, 0.6);
	GMTestSklValue(p, n, 'sword_s35', 'stamina_cost_reduction_after_1', 'add', -1000000, 0.3);
	GMTestSklValue(p, n, 'sword_s35', 'whirl_dmg_bonus', 'mult', -1000000, 0.016667);
	GMTestSklValue(p, n, 'sword_s35', 'whirl_dmg_reduction', 'mult', -1000000, 0.25);
	GMTestSklValue(p, n, 'sword_s35', 'whirl_dmg_reduction_bonus_after_1', 'mult', -1000000, 0.125);
	GMTestSklValue(p, n, 'sword_s36', 's9_damage_reduction', 'add', -1000000, 0.166667);
	GMTestSklValue(p, n, 'sword_s4', 'heavy_focus_gain', 'add', 0.03, -1000000);
	GMTestSklValue(p, n, 'sword_s5', 'sword_s5_chance', 'add', 0.05, -1000000);
	GMTestSklValue(p, n, 'sword_s5', 'sword_s5_duration', 'add', 8, -1000000);
	GMTestSklValue(p, n, 'sword_s5', 'sword_s5_dmg_per_sec', 'add', 0.01, -1000000);
	GMTestSklValue(p, n, 'sword_s5', 'sword_s5_dmg_boost', 'add', 0.05, -1000000);
	GMTestSklValue(p, n, 'sword_s6', 'armor_reduction_perc', 'add', 0.05, -1000000);
	GMTestSklValue(p, n, 'sword_s7', 'critical_hit_chance', 'add', 0.05, -1000000);
	GMTestSklValue(p, n, 'sword_s7', 'critical_hit_damage_bonus', 'add', 0.15, -1000000);
	GMTestSklValue(p, n, 'sword_s8', 'critical_hit_chance', 'add', 0.02, -1000000);
	GMTestSklValue(p, n, 'sword_s8', 'critical_hit_damage_bonus', 'add', 0.15, -1000000);
	GMTestSklValue(p, n, 'sword_s9', 's9_damage_reduction', 'add', 0.1, -1000000);
}

// The sign skills (SKL-08 to SKL-12): every ported value per level of the skill's ability in force (the attribute's type; classic, new tree; -1000000: not a skill of that tree).
function GMTestSklValues_magic(out p : string, out n : int)
{
	GMTestSklValue(p, n, 'magic_s1', 'spell_power', 'mult', -0.4, -0.4);
	GMTestSklValue(p, n, 'magic_s1', 'spell_power_penalty_reduction', 'add', 0.2, 0.2);
	GMTestSklValue(p, n, 'magic_s1', 'stamina_cost', 'add', 40, 40);
	GMTestSklValue(p, n, 'magic_s10', 'charge_count', 'add', 0, -1000000);
	GMTestSklValue(p, n, 'magic_s10', 'trap_duration', 'add', 0, -1000000);
	GMTestSklValue(p, n, 'magic_s10', 'trap_duration_bonus', 'add', 0.333, -1000000);
	GMTestSklValue(p, n, 'magic_s10', 'range_bonus', 'add', 0.3, -1000000);
	GMTestSklValue(p, n, 'magic_s11', 's11_dmg_bonus', 'add', 0.05, 0.083333);
	GMTestSklValue(p, n, 'magic_s12', 'spell_power', 'mult', 0, -1000000);
	GMTestSklValue(p, n, 'magic_s12', 'heavy_knockdown_chance_bonus', 'mult', 0.03, -1000000);
	GMTestSklValue(p, n, 'magic_s13', 'PhysicalDamage', 'add', 0, 0);
	GMTestSklValue(p, n, 'magic_s13', 'SilverDamage', 'add', 0, 0);
	GMTestSklValue(p, n, 'magic_s13', 'ShockDamage', 'add', 30, 30);
	GMTestSklValue(p, n, 'magic_s14', 'discharge_percent', 'add', 0.05, -1000000);
	GMTestSklValue(p, n, 'magic_s15', 'spell_power', 'mult', 0, -1000000);
	GMTestSklValue(p, n, 'magic_s15', 'shield_health_bonus', 'add', 30, -1000000);
	GMTestSklValue(p, n, 'magic_s16', 'spell_power', 'mult', 0, -1000000);
	GMTestSklValue(p, n, 'magic_s16', 'turret_bonus_damage', 'add', 30, -1000000);
	GMTestSklValue(p, n, 'magic_s17', 'duration_to_force_stagger', 'add', 0, 0);
	GMTestSklValue(p, n, 'magic_s17', 'slowdown_mod', 'add', 0.15, 0.15);
	GMTestSklValue(p, n, 'magic_s17', 'crit_chance_bonus', 'add', 0.25, 0.25);
	GMTestSklValue(p, n, 'magic_s18', 'spell_power', 'mult', 0, -1000000);
	GMTestSklValue(p, n, 'magic_s18', 'axii_duration_bonus', 'add', 0.1, -1000000);
	GMTestSklValue(p, n, 'magic_s19', 'duration', 'mult', 0.25, 0.25);
	GMTestSklValue(p, n, 'magic_s2', 'FireDamage', 'add', 0, -1000000);
	GMTestSklValue(p, n, 'magic_s2', 'channeling_damage', 'add', 40, -1000000);
	GMTestSklValue(p, n, 'magic_s2', 'channeling_damage_after_1', 'add', 30, -1000000);
	GMTestSklValue(p, n, 'magic_s2', 'stamina_cost_per_sec', 'add', 30, -1000000);
	GMTestSklValue(p, n, 'magic_s2', 'stamina_cost_reduction_after_1', 'mult', 0.167, -1000000);
	GMTestSklValue(p, n, 'magic_s28', 'FireDamage', 'add', -1000000, 0);
	GMTestSklValue(p, n, 'magic_s28', 'channeling_damage', 'add', -1000000, 40);
	GMTestSklValue(p, n, 'magic_s28', 'channeling_damage_after_1', 'add', -1000000, 30);
	GMTestSklValue(p, n, 'magic_s28', 'stamina_cost_per_sec', 'add', -1000000, 30);
	GMTestSklValue(p, n, 'magic_s28', 'stamina_cost_reduction_after_1', 'mult', -1000000, 0.167);
	GMTestSklValue(p, n, 'magic_s3', 'stamina_cost_per_sec', 'add', 26.8, 26.8);
	GMTestSklValue(p, n, 'magic_s3', 'charge_count', 'base', 4, 4);
	GMTestSklValue(p, n, 'magic_s3', 'trap_duration', 'base', 10, 10);
	GMTestSklValue(p, n, 'magic_s3', 'ShockDamage', 'add', 50, 50);
	GMTestSklValue(p, n, 'magic_s3', 'damage_bonus_flat_after_1', 'add', 25, 25);
	GMTestSklValue(p, n, 'magic_s3', 'duration_bonus_flat_after_1', 'add', 2.5, 2.5);
	GMTestSklValue(p, n, 'magic_s3', 'charge_bonus_flat_after_1', 'add', 1, 1);
	GMTestSklValue(p, n, 'magic_s31', 'duration', 'base', -1000000, 10);
	GMTestSklValue(p, n, 'magic_s31', 'duration_bonus_after1', 'base', -1000000, 5);
	GMTestSklValue(p, n, 'magic_s31', 'duration_animals', 'base', -1000000, 20);
	GMTestSklValue(p, n, 'magic_s31', 'armor_reduction', 'add', -1000000, 100);
	GMTestSklValue(p, n, 'magic_s31', 'alt_axii_level', 'add', -1000000, 1);
	GMTestSklValue(p, n, 'magic_s31', 'stamina_cost_per_sec', 'add', -1000000, 16);
	GMTestSklValue(p, n, 'magic_s31', 'stamina_delay', 'add', -1000000, 1);
	GMTestSklValue(p, n, 'magic_s33', 'damage_vitality_percent', 'add', -1000000, 0);
	GMTestSklValue(p, n, 'magic_s33', 'ForceDamage', 'add', -1000000, 100);
	GMTestSklValue(p, n, 'magic_s35', 'spell_power_aard_igni', 'mult', -1000000, 0);
	GMTestSklValue(p, n, 'magic_s35', 'burn_chance_bonus', 'add', -1000000, 0);
	GMTestSklValue(p, n, 'magic_s35', 'fire_damage_bonus', 'add', -1000000, 50);
	GMTestSklValue(p, n, 'magic_s35', 'channeling_damage_bonus', 'add', -1000000, 25);
	GMTestSklValue(p, n, 'magic_s36', 'duration', 'mult', -1000000, 0);
	GMTestSklValue(p, n, 'magic_s36', 'axii_duration_bonus', 'add', -1000000, 0.166667);
	GMTestSklValue(p, n, 'magic_s37', 'damage_level1', 'add', -1000000, 0);
	GMTestSklValue(p, n, 'magic_s37', 'damage_level2', 'add', -1000000, 0);
	GMTestSklValue(p, n, 'magic_s37', 'damage_level3', 'add', -1000000, 0);
	GMTestSklValue(p, n, 'magic_s37', 'turret_bonus_damage', 'add', -1000000, 50);
	GMTestSklValue(p, n, 'magic_s38', 'spell_power', 'mult', -1000000, 0);
	GMTestSklValue(p, n, 'magic_s38', 'shield_health_bonus', 'add', -1000000, 50);
	GMTestSklValue(p, n, 'magic_s39', 'stamina_cost_reduction', 'mult', -1000000, 0);
	GMTestSklValue(p, n, 'magic_s39', 'heavy_knockdown_chance_bonus', 'mult', -1000000, 0.05);
	GMTestSklValue(p, n, 'magic_s4', 'stamina_cost_per_sec', 'add', 20, 20);
	GMTestSklValue(p, n, 'magic_s4', 'stamina_delay', 'add', 1, 1);
	GMTestSklValue(p, n, 'magic_s4', 'shield_health_factor', 'add', 2, 2);
	GMTestSklValue(p, n, 'magic_s4', 'shield_healing_factor', 'add', 0.334, 0.334);
	GMTestSklValue(p, n, 'magic_s40', 'ElementalDamage', 'add', -1000000, 0);
	GMTestSklValue(p, n, 'magic_s40', 'discharge_percent', 'add', -1000000, 0.083333);
	GMTestSklValue(p, n, 'magic_s41', 'sign_intensity_ratio', 'add', -1000000, 0);
	GMTestSklValue(p, n, 'magic_s41', 'chance_bonus', 'add', -1000000, 0.083333);
	GMTestSklValue(p, n, 'magic_s42', 'charge_count', 'add', -1000000, 0);
	GMTestSklValue(p, n, 'magic_s42', 'trap_count', 'add', -1000000, 0);
	GMTestSklValue(p, n, 'magic_s42', 'trap_duration', 'add', -1000000, 0);
	GMTestSklValue(p, n, 'magic_s42', 'range', 'mult', -1000000, 0);
	GMTestSklValue(p, n, 'magic_s42', 'trap_duration_bonus', 'add', -1000000, 0.333);
	GMTestSklValue(p, n, 'magic_s42', 'range_bonus', 'add', -1000000, 0.3);
	GMTestSklValue(p, n, 'magic_s5', 'duration', 'base', 10, -1000000);
	GMTestSklValue(p, n, 'magic_s5', 'duration_bonus_after1', 'base', 5, -1000000);
	GMTestSklValue(p, n, 'magic_s5', 'duration_animals', 'base', 20, -1000000);
	GMTestSklValue(p, n, 'magic_s5', 'attack_power', 'mult', 0.334, -1000000);
	GMTestSklValue(p, n, 'magic_s5', 'armor_reduction', 'add', 100, -1000000);
	GMTestSklValue(p, n, 'magic_s5', 'alt_axii_level', 'add', 1, -1000000);
	GMTestSklValue(p, n, 'magic_s5', 'stamina_cost_per_sec', 'add', 16, -1000000);
	GMTestSklValue(p, n, 'magic_s5', 'stamina_delay', 'add', 1, -1000000);
	GMTestSklValue(p, n, 'magic_s6', 'ForceDamage', 'add', 60, -1000000);
	GMTestSklValue(p, n, 'magic_s7', 'spell_power', 'mult', 0, -1000000);
	GMTestSklValue(p, n, 'magic_s7', 'fire_damage_bonus', 'add', 30, -1000000);
	GMTestSklValue(p, n, 'magic_s7', 'channeling_damage_bonus', 'add', 15, -1000000);
	GMTestSklValue(p, n, 'magic_s8', 'max_armor_reduction', 'add', -1000000, 0);
	GMTestSklValue(p, n, 'magic_s8', 'burn_chance_bonus', 'add', -1000000, 0);
	GMTestSklValue(p, n, 'magic_s9', 'chance_bonus', 'add', 0.05, -1000000);
}

// The perks (SKL-18): every ported value per level of the skill's ability in force (the attribute's type; classic, new tree; -1000000: not a skill of that tree).
function GMTestSklValues_perk(out p : string, out n : int)
{
	GMTestSklValue(p, n, 'perk_1', 'staminaRegen_tooltip', 'mult', 0.05, -1000000);
	GMTestSklValue(p, n, 'perk_10', 'focus_gain', 'add', 0.05, -1000000);
	GMTestSklValue(p, n, 'perk_10', 'stamina_cost_reduction', 'add', 0.1, -1000000);
	GMTestSklValue(p, n, 'perk_11', 'spell_power', 'mult', 0.15, -1000000);
	GMTestSklValue(p, n, 'perk_12', 'toxicity', 'base', 40, -1000000);
	GMTestSklValue(p, n, 'perk_18', 'focus_gain', 'add', 0, -1000000);
	GMTestSklValue(p, n, 'perk_18', 'gm_bomb_focus_gain', 'add', 0.1, -1000000);
	GMTestSklValue(p, n, 'perk_19', 'critical_hit_chance', 'add', 0.1, -1000000);
	GMTestSklValue(p, n, 'perk_2', 'attack_power', 'mult', 0, -1000000);
	GMTestSklValue(p, n, 'perk_20', 'stack_multiplier', 'mult', 0.5, -1000000);
	GMTestSklValue(p, n, 'perk_20', 'dmg_multiplier', 'mult', 1, -1000000);
	GMTestSklValue(p, n, 'perk_21', 'stamina_kill', 'mult', 0.15, -1000000);
	GMTestSklValue(p, n, 'perk_21', 'stamina_other', 'mult', 0.05, -1000000);
	GMTestSklValue(p, n, 'perk_22', 'encumbrance', 'base', 40, -1000000);
	GMTestSklValue(p, n, 'perk_23', 'critical_hit_chance', 'add', -1000000, 0.05);
	GMTestSklValue(p, n, 'perk_23', 'critical_hit_damage_bonus', 'add', -1000000, 0.2);
	GMTestSklValue(p, n, 'perk_24', 'spell_power', 'mult', -1000000, 0.05);
	GMTestSklValue(p, n, 'perk_24', 'perk_6_stamina_cost_reduction', 'mult', -1000000, 0.05);
	GMTestSklValue(p, n, 'perk_25', 'vitality', 'mult', -1000000, 0.075);
	GMTestSklValue(p, n, 'perk_25', 'bonus_focus_gain', 'add', -1000000, 0.025);
	GMTestSklValue(p, n, 'perk_26', 'gm_wolf_crit_chance', 'add', -1000000, 0.1);
	GMTestSklValue(p, n, 'perk_26', 'gm_wolf_crit_damage', 'add', -1000000, 0.4);
	GMTestSklValue(p, n, 'perk_28', 'gm_viper_crit_chance', 'add', -1000000, 0.03);
	GMTestSklValue(p, n, 'perk_28', 'gm_viper_crit_damage', 'add', -1000000, 0.2);
	GMTestSklValue(p, n, 'perk_30', 'vitality', 'base', -1000000, 750);
	GMTestSklValue(p, n, 'perk_31', 'stamina_kill', 'mult', -1000000, 0.15);
	GMTestSklValue(p, n, 'perk_31', 'stamina_other', 'mult', -1000000, 0.05);
	GMTestSklValue(p, n, 'perk_32', 'cost_reduction', 'mult', -1000000, 0.334);
	GMTestSklValue(p, n, 'perk_33', 'toxicity', 'base', -1000000, 40);
	GMTestSklValue(p, n, 'perk_35', 'encumbrance', 'base', -1000000, 40);
	GMTestSklValue(p, n, 'perk_37', 'spell_power', 'mult', -1000000, 0.15);
	GMTestSklValue(p, n, 'perk_38', 'staminaRegen_tooltip', 'mult', -1000000, 0.05);
	GMTestSklValue(p, n, 'perk_39', 'free_bomb', 'add', -1000000, 0);
	GMTestSklValue(p, n, 'perk_39', 'gm_bomb_focus_gain', 'add', -1000000, 0.1);
	GMTestSklValue(p, n, 'perk_4', 'vitality', 'base', 750, -1000000);
	GMTestSklValue(p, n, 'perk_40', 'critical_hit_chance', 'add', -1000000, 0.1);
	GMTestSklValue(p, n, 'perk_42', 'focus_gain', 'add', -1000000, 0.05);
	GMTestSklValue(p, n, 'perk_42', 'stamina_cost_reduction', 'add', -1000000, 0.1);
	GMTestSklValue(p, n, 'perk_43', 'stack_multiplier', 'mult', -1000000, 0.5);
	GMTestSklValue(p, n, 'perk_43', 'dmg_multiplier', 'mult', -1000000, 1);
	GMTestSklValue(p, n, 'perk_5', 'critical_hit_chance', 'add', 0.05, -1000000);
	GMTestSklValue(p, n, 'perk_5', 'critical_hit_damage_bonus', 'add', 0.2, -1000000);
	GMTestSklValue(p, n, 'perk_6', 'spell_power', 'mult', 0.05, -1000000);
	GMTestSklValue(p, n, 'perk_6', 'perk_6_stamina_cost_reduction', 'mult', 0.05, -1000000);
	GMTestSklValue(p, n, 'perk_7', 'vitality', 'mult', 0.075, -1000000);
	GMTestSklValue(p, n, 'perk_7', 'bonus_focus_gain', 'add', 0.025, -1000000);
}

// Abilities that are not a skill's own (the basic signs, the perks' effect abilities): per level, the same in both trees.
function GMTestSklValuesOther(out p : string, out n : int)
{
	GMTestSklAbility(p, n, 'magic_1', 'stamina_cost', 'add', 40);
	GMTestSklAbility(p, n, 'magic_1', 'starting_knockdown_chance', 'add', 0.33);
	GMTestSklAbility(p, n, 'magic_2', 'stamina_cost', 'add', 40);
	GMTestSklAbility(p, n, 'magic_2', 'FireDamage', 'add', 150);
	GMTestSklAbility(p, n, 'magic_2', 'initial_burn_chance', 'add', 0.33);
	GMTestSklAbility(p, n, 'magic_3', 'stamina_cost', 'add', 40);
	GMTestSklAbility(p, n, 'magic_3', 'trap_duration', 'base', 7.5);
	GMTestSklAbility(p, n, 'magic_3', 'min_slowdown', 'add', 0.15);
	GMTestSklAbility(p, n, 'magic_3', 'max_slowdown', 'add', 0.75);
	GMTestSklAbility(p, n, 'magic_3', 'min_starting_slowdown', 'add', 0.25);
	GMTestSklAbility(p, n, 'magic_4', 'stamina_cost', 'add', 40);
	GMTestSklAbility(p, n, 'magic_4', 'shield_health', 'base', 250);
	GMTestSklAbility(p, n, 'magic_4', 'max_dmg_absorption', 'add', 1);
	GMTestSklAbility(p, n, 'magic_5', 'stamina_cost', 'add', 40);
	GMTestSklAbility(p, n, 'perk_38_night_ability', 'staminaRegen', 'mult', 0.05);
	GMTestSklAbility(p, n, 'perk_1_night_ability', 'staminaRegen', 'mult', 0.05);
	GMTestSklAbility(p, n, 'Perk21InternalCooldownEffect', 'duration', 'add', 2.5);
}

// SKL-07 Flood of Anger kept until its sign ends (regression, no cast): with no active Flood of Anger
// sign, 5.x's RemoveTemporarySkills (a combat action end) removes leftover temporary skills (the tree's
// sign skills raised as for a cast) and every level is back. That they stay while the sign is active is
// checked in game with real casts (gmtest_skl07_foa_hit).
exec function gmtest_skl07_foa_keep()
{
	GMTest_skl07_foa_keep();
}

function GMTest_skl07_foa_keep()
{
	var witcher : W3PlayerWitcher;
	var pam : W3PlayerAbilityManager;
	var levelBefore, held : int;

	witcher = GetWitcherPlayer();
	pam = (W3PlayerAbilityManager)witcher.abilityManager;
	if(witcher.GMIsFoASignActive() || witcher.GetTempLearnedSignSkillsSize() > 0)
	{
		LogChannel('GMTest', "INFO SKL-07 FoA leftovers: a Flood of Anger cast is running, skipped");
		return;
	}
	levelBefore = witcher.GetSkillLevel(S_Magic_s07) + witcher.GetSkillLevel(S_Magic_s35);
	witcher.GMTestSetTempSignSkills(pam.GMAddTempSignSkills());
	held = witcher.GetTempLearnedSignSkillsSize();
	witcher.RemoveTemporarySkills();
	GMTestReport(held > 0 && witcher.GetTempLearnedSignSkillsSize() == 0 && witcher.GetSkillLevel(S_Magic_s07) + witcher.GetSkillLevel(S_Magic_s35) == levelBefore, "SKL-07 FoA: with no active sign the leftovers are removed (" + held + " -> " + witcher.GetTempLearnedSignSkillsSize() + "), levels back");
}

@addMethod(W3PlayerWitcher)
function GMTestSetTempSignSkills(list : array<SSimpleSkill>)
{
	tempLearnedSignSkills = list;
}

// SKL-07 (fix3, sweep C gap 4): no adrenaline from horse trampling: the horse's collision attack's ability
// (attack_speed_based, horseComponent.ws) has no focus_gain (legacy; 5.x 0.025).
function GMTest_skl07_trample()
{
	var min, max : SAbilityAttributeValue;
	var gain : float;
	var tags : array<name>;

	theGame.GetDefinitionsManager().GetAbilityAttributeValue('attack_speed_based', 'focus_gain', min, max);
	gain = min.valueBase + min.valueAdditive;	// a base node: CalculateAttributeValue reads 0 without a multiplier
	theGame.GetDefinitionsManager().GetAbilityTags('attack_speed_based', tags);
	GMTestReport(gain == 0 && tags.Contains('attack_speed_based'), "SKL-07 horse trampling's attack (attack_speed_based) gives no adrenaline: focus_gain " + gain + " (legacy 0; 5.x 0.025), its tag kept " + tags.Contains('attack_speed_based'));
}

// SKL-11 (fix3, sweep D G4): an active Quen shield is not restored when a save loads (legacy). As a load runs it:
// the OnSpawned wrapper's rule (GMQuenNotRestoredOnLoad) on a Quen saved at 500 health and 20 s, then 5.x's
// RestoreQuen with the saved values, as 5.x's OnSpawned calls it for a restored player. 5.x: the shield comes back.
function GMTest_skl11_load()
{
	var w : W3PlayerWitcher;
	var restored, active : bool;
	var h, d : float;

	w = GetWitcherPlayer();
	h = w.savedQuenHealth;
	d = w.savedQuenDuration;
	w.FinishQuen(true);
	w.savedQuenHealth = 500;
	w.savedQuenDuration = 20;
	w.GMQuenNotRestoredOnLoad();
	restored = w.RestoreQuen(w.savedQuenHealth, w.savedQuenDuration);
	active = w.IsAnyQuenActive();
	GMTestReport(!restored && !active && w.savedQuenHealth == 0 && w.savedQuenDuration == 0,
		"SKL-11 a Quen active when the game was saved is not restored at the load: restored " + restored + ", shield up " + active + ", saved values " + w.savedQuenHealth + ", " + w.savedQuenDuration + " (legacy: false, false, 0, 0; 5.x restores it)");
	w.FinishQuen(true);
	w.RemoveAllBuffsOfType(EET_GMQuenCooldown);
	w.savedQuenHealth = h;
	w.savedQuenDuration = d;
}

// fix3's new checks on their own (each also runs in the regression: the SKL, SWD, OPT, FOOD and ARM ones in
// gmtest_regress(), AI-14's slam in gmtest_panel()), for a fail-first build and a quick re-run.
exec function gmtest_fix3()
{
	thePlayer.GMTestCount(true, true);
	GMTest_skl07_trample();
	GMTest_skl11_load();
	GMTest_swd03_shovel();
	GMTest_opt02_resist();
	GMTest_food04_liverslot();
	GMTest_arm01_hair();
	GMTest_ai14_slam();
	LogChannel('GMTest', "SUMMARY fix3: " + thePlayer.gmTestPassed + " passed, " + thePlayer.gmTestFailed + " failed");
}
