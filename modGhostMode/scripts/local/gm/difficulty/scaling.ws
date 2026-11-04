// DIFF-04: Ghost Mode's enemy scaling options (Options > Mods > Ghost Mode > Enemy scaling, the group
// GMScalingOptions with legacy's ids). How enemy levels follow Geralt's level, for Geralt's sections only:
// None, Upscale, Match, Soft upscaling (the default, DD1), Random and Random no downscaling between two
// bounds relative to Geralt's level (the level kept per NPC in a saved field until it falls outside them);
// guards without their 16 extra levels; animals not upscaled, and lowered to half Geralt's level when above
// it (legacy's code, DD4). Applied in AddLevelBonuses (ai/levels.ws). Changing any scaling option re-levels
// every NPC near Geralt at once (OPT's change hook, options/gmOptions.ws; the owner's change of PD6).
// Slice D5b: the health and damage modifiers for every NPC and the extra ones for bosses (the five ModSigns*
// step abilities, abilities/gm_diff.xml), progressive level bonuses, and the group's three presets
// ("Recommended", "Hardcore", "Off": the menu XML; applying one re-levels like an option change).
// DIFF audit F2 and F3 (owner, 2026-10-31; deviations): the modifiers combine as (1 + mode) x (1 + enemy + boss),
// floored; the boss modifiers follow the boss bar's tag at once.
// DIFF-10 (owner, 2026-10-31: new, not legacy): a seventh scaling type, Interpolated: an enemy below Geralt's level
// gains half the difference, rounded down.
// See docs/features/diff.md.

// ---- option getters (legacy: W3GameParams.GetEnemyScalingOption and the like) ----

// 0 None, 1 Upscale, 2 Match, 3 Soft upscaling, 4 Random, 5 Random no downscaling (legacy's), 6 Interpolated (DIFF-10).
function GMGetEnemyScalingOption() : int
{
	return (int)GMGetOptionFloat('GMScalingOptions', 'Virtual_GMScaling');
}

function GMGetRandomScalingMinLevel() : int
{
	return (int)GMGetOptionFloat('GMScalingOptions', 'GMRandomScalingMinLevel');
}

function GMGetRandomScalingMaxLevel() : int
{
	return (int)GMGetOptionFloat('GMScalingOptions', 'GMRandomScalingMaxLevel');
}

function GMGetNoAnimalUpscaling() : bool
{
	return GMGetOptionBool('GMScalingOptions', 'GMNoAnimalUpscaling');
}

function GMGetNoAdditionalLevelsForGuards() : bool
{
	return GMGetOptionBool('GMScalingOptions', 'GMNoAddLevelsGuards');
}

// "Enemy health modifier", "Enemy damage modifier" and the two boss modifiers: -1 to 5 (-100% to +500%).
function GMGetEnemyHealthMult() : float
{
	return GMGetOptionFloat('GMScalingOptions', 'GMHealthMultiplier');
}

function GMGetEnemyDamageMult() : float
{
	return GMGetOptionFloat('GMScalingOptions', 'GMDamageMultiplier');
}

function GMGetBossHealthMult() : float
{
	return GMGetOptionFloat('GMScalingOptions', 'GMBossHealthMultiplier');
}

function GMGetBossDamageMult() : float
{
	return GMGetOptionFloat('GMScalingOptions', 'GMBossDamageMultiplier');
}

// "Use progressive level bonuses", "Level delta" (LD), "Abilities per level delta" (AD).
function GMGetNonlinearLevelup() : bool
{
	return GMGetOptionBool('GMScalingOptions', 'GMNonlinearLevelup');
}

function GMGetNonlinearLevelDelta() : int
{
	return (int)GMGetOptionFloat('GMScalingOptions', 'GMNonlinearLevelDelta');
}

function GMGetNonlinearAbilitiesDelta() : int
{
	return (int)GMGetOptionFloat('GMScalingOptions', 'GMNonlinearAbilitiesDelta');
}

// Legacy's count of per-level bonuses for an NPC of level lvl (InternalAddLevelBonuses): level - 1, or with
// progressive level bonuses above level LD, round((1 + AD/LD) x level - AD) - 1 (LD 10, AD 5: 24 instead of
// 19 at level 20, 39 instead of 29 at level 30).
function GMLevelBonusCount(lvl : int) : int
{
	var numAbls : int;
	var dLvl, dAbs : float;

	if(GMGetNonlinearLevelup())
	{
		dLvl = GMGetNonlinearLevelDelta();
		dAbs = GMGetNonlinearAbilitiesDelta();
		if(dLvl > 0 && lvl > dLvl)
			numAbls = RoundMath((1 + dAbs/dLvl) * lvl - dAbs);
		else
			numAbls = lvl;
		return numAbls - 1;
	}
	return lvl - 1;
}

// Legacy's boss rule: an NPC tagged HideHealthBarModule (the tag that moves its health bar from above its head
// to the boss bar at the top of the screen) gets the boss modifiers on top of the others.
@addMethod(CNewNPC)
function GMIsScalingBoss() : bool
{
	return HasTag('HideHealthBarModule');
}

// Legacy's ModSignsAddBonuses, with the owner's combination (DIFF audit F3, 2026-10-31: a deviation): the
// difficulty mode multiplies, the menu's modifiers add to each other. For health (health_final_multiplier) and
// damage (damage_final_multiplier) separately:
//   multiplier = (1 + mode) x (1 + enemy modifier + boss modifier)    (the boss modifier for bosses only)
// with health at least x0.01 and damage at least x0 (legacy: 1 + mode + enemy + boss, which reached 0 and
// below on "Just the Story!"). (1 + mode) is read from the NPC (its multiplier with no step on: the base 1 and
// its difficulty ability), and the difference is added as step abilities of 1, 0.1 (legacy's ModSigns* steps),
// 0.01 and 0.001 (gm_diff.xml, tools/gen_diff.py). Every NPC gets them, Ciri's sections included (legacy's "for
// Geralt only" test is commented out), before NPCDoNotGainBoost stops the level bonuses; recomputed with the
// level (a mode change re-levels every NPC, vanilla's OnGameDifficultyChanged). GMRemoveAllLevelBonuses
// (ai/levels.ws) removes them.
@addMethod(CNewNPC)
function GMAddOptionBonuses()
{
	var savedHealthPerc, modifier, base, offset : float;

	GMRemoveScalingSteps();
	if(GetStatMax( BCS_Vitality ) > 0)
		savedHealthPerc = GetStatPercents( BCS_Vitality );
	else if(GetStatMax( BCS_Essence ) > 0)
		savedHealthPerc = GetStatPercents( BCS_Essence );
	modifier = GMGetEnemyHealthMult();
	if(GMIsScalingBoss())
		modifier += GMGetBossHealthMult();
	base = GMScalingMult('health_final_multiplier');
	offset = base * modifier;
	if(base + offset < 0.01)
		offset = 0.01 - base;
	GMAddScalingSteps(true, offset);
	GMRestoreHealthPerc(savedHealthPerc);
	modifier = GMGetEnemyDamageMult();
	if(GMIsScalingBoss())
		modifier += GMGetBossDamageMult();
	base = GMScalingMult('damage_final_multiplier');
	offset = base * modifier;
	if(base + offset < 0)
		offset = -base;
	GMAddScalingSteps(false, offset);
}

// The NPC's difficulty multiplier as the game uses it (the additive sum of every ability's node: 1 + the mode's).
@addMethod(CNewNPC)
function GMScalingMult(attr : name) : float
{
	var noTags : array<name>;
	var a : SAbilityAttributeValue;

	a = GetCharacterStats().GetAttributeValue(attr, noTags);
	return a.valueAdditive;
}

// Adds offset to the health or damage multiplier in steps of 1, 0.1, 0.01 and 0.001 (rounded to 0.001).
@addMethod(CNewNPC)
function GMAddScalingSteps(health : bool, offset : float)
{
	var n : int;
	var neg : bool;

	n = RoundMath(AbsF(offset) * 1000);
	neg = offset < 0;
	if(n <= 0)
		return;
	if(health)
	{
		if(neg)
		{
			GMAddSteps('GM_ScalingHealth_n1', n / 1000);
			GMAddSteps('ModSignsAdditionalHealthNegative', (n / 100) % 10);
			GMAddSteps('GM_ScalingHealth_n0.01', (n / 10) % 10);
			GMAddSteps('GM_ScalingHealth_n0.001', n % 10);
		}
		else
		{
			GMAddSteps('GM_ScalingHealth_p1', n / 1000);
			GMAddSteps('ModSignsAdditionalHealth', (n / 100) % 10);
			GMAddSteps('GM_ScalingHealth_p0.01', (n / 10) % 10);
			GMAddSteps('GM_ScalingHealth_p0.001', n % 10);
		}
	}
	else
	{
		if(neg)
		{
			GMAddSteps('GM_ScalingDamage_n1', n / 1000);
			GMAddSteps('ModSignsAdditionalDamageNegative', (n / 100) % 10);
			GMAddSteps('GM_ScalingDamage_n0.01', (n / 10) % 10);
			GMAddSteps('GM_ScalingDamage_n0.001', n % 10);
		}
		else
		{
			GMAddSteps('GM_ScalingDamage_p1', n / 1000);
			GMAddSteps('ModSignsAdditionalDamage', (n / 100) % 10);
			GMAddSteps('GM_ScalingDamage_p0.01', (n / 10) % 10);
			GMAddSteps('GM_ScalingDamage_p0.001', n % 10);
		}
	}
}

@addMethod(CNewNPC)
function GMAddSteps(abl : name, count : int)
{
	if(count > 0)
		AddAbilityMultiple(abl, count);
}

// Every step ability of the modifiers removed (legacy's five ModSigns* names and the port's finer steps).
@addMethod(CNewNPC)
function GMRemoveScalingSteps()
{
	RemoveAbilityAll('ModSignsAdditionalHealth');
	RemoveAbilityAll('ModSignsAdditionalHealthNegative');
	RemoveAbilityAll('ModSignsMaxHealthNegative');
	RemoveAbilityAll('ModSignsAdditionalDamage');
	RemoveAbilityAll('ModSignsAdditionalDamageNegative');
	RemoveAbilityAll('GM_ScalingHealth_p1');
	RemoveAbilityAll('GM_ScalingHealth_n1');
	RemoveAbilityAll('GM_ScalingHealth_p0.01');
	RemoveAbilityAll('GM_ScalingHealth_n0.01');
	RemoveAbilityAll('GM_ScalingHealth_p0.001');
	RemoveAbilityAll('GM_ScalingHealth_n0.001');
	RemoveAbilityAll('GM_ScalingDamage_p1');
	RemoveAbilityAll('GM_ScalingDamage_n1');
	RemoveAbilityAll('GM_ScalingDamage_p0.01');
	RemoveAbilityAll('GM_ScalingDamage_n0.01');
	RemoveAbilityAll('GM_ScalingDamage_p0.001');
	RemoveAbilityAll('GM_ScalingDamage_n0.001');
}

// ---- the boss modifiers follow the boss bar (DIFF audit F2, owner 2026-10-31: a deviation) ----
// Legacy read the boss tag only when the level was computed, so a boss whose bar appeared in the fight (story
// bosses: the quest's ShowBossFightIndicator) got no boss modifiers until Geralt's next level-up or an option or
// mode change. The port recomputes an NPC's level bonuses, at its current level, whenever the tag is added or
// removed by 5.x's paths: the boss-bar HUD module's OnShow and OnHide (the quest's ShowBossFightIndicator, contract
// monsters' bar, the delayed HUD event) and the quest function HealthBarVisiblityQuest. Contract monsters tagged
// at their spawn already have it at their first computation. The current health stays the same share of the
// maximum (GMRestoreHealthPerc); AI-01's rule that bosses get no "High" or "Deadly" ability follows the same
// recompute.

// The NPC's bonuses recomputed at its current level (the level a scaling type or a script gave it kept, as at
// Geralt's level-up); a pending full reset (-1) stays one. -2 is no player level (Ciri's reads 0).
@addMethod(CNewNPC)
function GMRecomputeLevelBonuses()
{
	if(!IsAlive())
		return;
	if(levelBonusesComputedAtPlayerLevel != -1)
		levelBonusesComputedAtPlayerLevel = -2;
	AddLevelBonuses(0, 0);
}

@wrapMethod(CR4HudModuleBossFocus)
function OnShow()
{
	var npc : CNewNPC;
	var had : bool;

	npc = (CNewNPC)m_bossEntity;
	if(npc)
		had = npc.HasTag('HideHealthBarModule');
	wrappedMethod();
	if(npc && !had && npc.HasTag('HideHealthBarModule'))
		npc.GMRecomputeLevelBonuses();
}

@wrapMethod(CR4HudModuleBossFocus)
function OnHide()
{
	var npc : CNewNPC;
	var had : bool;

	npc = (CNewNPC)m_bossEntity;
	if(npc)
		had = npc.HasTag('HideHealthBarModule');
	wrappedMethod();
	if(npc && had && !npc.HasTag('HideHealthBarModule'))
		npc.GMRecomputeLevelBonuses();
}

@wrapMethod
function HealthBarVisiblityQuest( npcTag : name, show : bool )
{
	var npcs : array<CNewNPC>;
	var had : array<bool>;
	var i : int;

	theGame.GetNPCsByTag(npcTag, npcs);
	for(i = 0; i < npcs.Size(); i += 1)
		had.PushBack(npcs[i].HasTag('HideHealthBarModule'));
	wrappedMethod(npcTag, show);
	for(i = 0; i < npcs.Size(); i += 1)
		if(npcs[i] && had[i] != npcs[i].HasTag('HideHealthBarModule'))
			npcs[i].GMRecomputeLevelBonuses();
}

// ---- the saved random level (legacy: CNewNPC.savedRandomLevel, saved) ----

// The level a random scaling type gave this NPC, kept until it falls outside the bounds; 0: none yet
// (legacy's -1; random levels are at least 1, and an older save without the field reads 0).
@addField(CNewNPC)
saved var gmSavedRandomLevel : int;

// Set when the NPC is restored from a save: its first level computation after the load (at the start of a
// fight, as in legacy) keeps the saved random level; legacy rolled it again there (a deviation, see diff.md).
// A scaling option or mode change before that rolls it again, as in legacy (GMResetLevel, below).
@addField(CNewNPC)
var gmKeepRandomLevel : bool;

@wrapMethod(CNewNPC)
function OnGameDifficultyChanged(previousDifficulty : int, currentDifficulty : int)
{
	var savedHealthPerc : float;

	gmKeepRandomLevel = false;
	// DIFF audit F3: the modifiers' steps were sized for the old mode; off before the mode's ability changes (the
	// re-level vanilla starts here adds the new mode's), so the new mode never meets the old steps (from a large
	// negative modifier the sum went below 0 and left a wolf with negative maximum health). The health share is kept.
	if(GetStatMax( BCS_Vitality ) > 0)
		savedHealthPerc = GetStatPercents( BCS_Vitality );
	else if(GetStatMax( BCS_Essence ) > 0)
		savedHealthPerc = GetStatPercents( BCS_Essence );
	GMRemoveScalingSteps();
	GMRestoreHealthPerc(savedHealthPerc);
	return wrappedMethod(previousDifficulty, currentDifficulty);
}

// legacy's CActor.IsBeast: the monster category is MC_Beast (bears and the like).
@addMethod(CActor)
function GMIsBeast() : bool
{
	var monsterCategory : EMonsterCategory;
	var tmpName : name;
	var tmpBool : bool;

	theGame.GetMonsterParamsForActor(this, monsterCategory, tmpName, tmpBool, tmpBool, tmpBool);
	return monsterCategory == MC_Beast;
}

// Legacy's scaling branches of AddLevelBonuses (Geralt's sections only): the scaling type changes
// currentLevel. The Blood and Wine banshee's summons never scale. With "Do not upscale animals", wolves,
// boars and other animals or beasts on Vitality skip scaling, and with any scaling type on, one above half
// Geralt's level is set to half of it (DD4).
@addMethod(CNewNPC)
function GMApplyLevelScaling(playerLevel : int)
{
	var scalingType, minLevel, maxLevel, baseLevel : int;

	scalingType = GMGetEnemyScalingOption();
	if(HasAbility('banshee_summons'))
		scalingType = -1;
	if(GMGetNoAnimalUpscaling() && (IsAnimal() || GMIsBeast()) && GetStat(BCS_Vitality, true) > 0)
	{
		if(currentLevel * 2 > playerLevel && scalingType > 0)
			currentLevel = Max(1, playerLevel / 2);
		scalingType = -1;
	}
	switch(scalingType)
	{
		case 1:	// upscale
			if(currentLevel < playerLevel)
				currentLevel = playerLevel;
			break;
		case 2:	// match
			currentLevel = playerLevel;
			break;
		case 3:	// soft: "gray" enemies raised to no more than 6 levels below Geralt
			if(currentLevel < playerLevel - 6)
				currentLevel = playerLevel - 6;
			break;
		case 4:	// random
		case 5:	// random, no downscaling
			minLevel = Max(1, playerLevel + GMGetRandomScalingMinLevel());
			maxLevel = Max(minLevel, playerLevel + GMGetRandomScalingMaxLevel());
			if(gmSavedRandomLevel <= 0 || gmSavedRandomLevel < minLevel || gmSavedRandomLevel > maxLevel)
			{
				gmSavedRandomLevel = RandRange(maxLevel + 1, minLevel);
				if(scalingType == 5 && gmSavedRandomLevel < currentLevel)
					gmSavedRandomLevel = currentLevel;
			}
			currentLevel = gmSavedRandomLevel;
			break;
		case 6:	// DIFF-10, interpolated: half the way up to Geralt's level, rounded down (Geralt 20, an enemy at 4:
			// +8, 12; Geralt 19: +7, 11); an enemy at or above his level keeps its own (porter's assumption).
			// From the NPC's own level (its entity's, or the one a script set), never from a level already raised,
			// so a recompute without a reset (Geralt's level-up, the boss bar) gives the rule's level again
			// (whole-port audit A2-1: it took half the remaining gap again each time)
			baseLevel = gmScriptLevel;
			if(baseLevel <= 0)
				baseLevel = level + gmCurrentNGPLevel;
			if(baseLevel < playerLevel)
				currentLevel = baseLevel + (playerLevel - baseLevel) / 2;
			break;
		default:
			break;
	}
}

// ---- re-levelling when an option changes (legacy: CR4Game.gmUserSettingsScaling) ----

// The options whose change re-levels the NPCs near Geralt (legacy's gmIsScalingOption, plus the five it
// missed: the owner's change of PD6). Applying one of the group's presets re-levels too (gmOptions.ws).
function GMIsScalingOption(option : name) : bool
{
	switch(option)
	{
		case 'Virtual_GMScaling' :
		case 'GMScaling' :
		case 'GMRandomScalingMinLevel' :
		case 'GMRandomScalingMaxLevel' :
		case 'GMNoAnimalUpscaling' :
		case 'GMNoAddLevelsGuards' :
		case 'GMHealthMultiplier' :
		case 'GMDamageMultiplier' :
		// PD6 (owner): legacy's list missed these five
		case 'GMNonlinearLevelup' :
		case 'GMNonlinearLevelDelta' :
		case 'GMNonlinearAbilitiesDelta' :
		case 'GMBossHealthMultiplier' :
		case 'GMBossDamageMultiplier' :
			return true;
	}
	return false;
}

// Every NPC near Geralt recomputes its level and bonuses from its own level (legacy's ResetLevel on every
// actor within 10,000 m, at most 10,000 of them).
function GMOnScalingOptionsChanged()
{
	var i : int;
	var all : array<CActor>;
	var npc : CNewNPC;

	all = GetActorsInRange(thePlayer, 10000.f, 10000, '', true);
	for(i = 0; i < all.Size(); i += 1)
	{
		npc = (CNewNPC)all[i];
		if(npc)
			npc.GMResetLevel();
	}
}
