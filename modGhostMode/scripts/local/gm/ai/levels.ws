// AI-01 (level bonuses) and AI-02 (NPC templates): legacy's enemy level model ("Levelup bonuses for
// NPCs redone", changelist 1106-1113). Per level an enemy gains only a little health and attack power
// (NPCLevelBonus, MonsterLevelBonus*, AnimalLevelBonus: abilities/gm_ai_levels.xml, gen_ai.py), so its
// armor and resistances stay those of its kind at any level; its displayed level comes from
// DisplayedLevelAbl. Enemies 6+ and 15+ levels above Geralt (LEVEL_DIFF_HIGH/DEADLY, DA4) get only
// legacy's damage-over-time resistances. Wolves, boars, rats and the djinn are levelled like the
// rest (PA5). Guards stand 16 levels above Geralt (PA4). New Game+ adds its level to every
// non-animal's level instead of 5.x's fake addon.
// The scaling itself follows Ghost Mode's enemy scaling options (DIFF-04, difficulty/scaling.ws; default
// soft upscaling, DD1), and so do the progressive level-up and the health and damage modifiers (slice D5b).
// 5.x's own upscaling option is off, as in legacy.
// AI-06's two level fixes (the Blood and Wine nekker warrior, the deserters at one encounter) are here
// too, as in legacy, and AI-14's cyclops and arachas lines (GMMonsterFixes, ai/monsters.ws).
// See docs/features/ai.md.

// AI-01: the New Game+ level added to this NPC's level (legacy's currentNGPLevel).
@addField(CNewNPC)
var gmCurrentNGPLevel : int;

// AI-01: vanilla's upscaling option no longer recomputes levels (legacy: the body commented out).
@replaceMethod(CNewNPC)
function OnLevelUpscalingChanged()
{
	//modSigns: removed levelBonusesComputedAtPlayerLevel = -1;
	//modSigns: removed AddTimer('AddLevelBonuses', RandRangeF(0.05,0.2), true, false, , true);
	return true;	//modSigns
}

// AI-01: a level set by script (summons, quests) is kept: the bonuses are recomputed from it, not from
// the entity's level (legacy; 5.x's -1 reset it to the entity's level in legacy's AddLevelBonuses).
@replaceMethod(CNewNPC)
function SetLevel( _level : int )
{
	currentLevel = _level;
	gmSavedRandomLevel = 0;	//modSigns: DIFF-04, a new random level
	levelBonusesComputedAtPlayerLevel = 0;	//modSigns: was -1
	AddTimer('AddLevelBonuses', 0.1, true, false, , true);
}

// AI-01: legacy's ResetLevel: recompute the level and bonuses from the entity's level.
@addMethod(CNewNPC)
function GMResetLevel()
{
	levelBonusesComputedAtPlayerLevel = -1;
	gmKeepRandomLevel = false;	// DIFF-04: an option change rolls the random level again, also right after a load
	AddTimer('AddLevelBonuses', RandRangeF(0.05,0.2), true, false, , true);
}

// AI-01: legacy's ManageNGPLevels, run after 5.x's OnSpawned, whose New Game+ block it overrides: the
// NG+ level is added to the level of every NPC but animals, Ciri's enemies and NPCs with
// NoAdaptBalance or NPCDoNotGainBoost, with no cap (5.x: capped at the maximum level + 5, and an NPC
// with NPCDoNotGainBoost or NewGamePlusFakeLevel shows the NG+ level as a fake addon instead).
// DIFF-05: the entity's own fake level (levelFakeAddon) is zeroed, as legacy ("just in case"): no
// level shown or used comes from it.
@wrapMethod(CNewNPC)
function OnSpawned(spawnData : SEntitySpawnData)
{
	var ret : bool;

	ret = wrappedMethod(spawnData);
	GMManageNGPLevels();
	gmKeepRandomLevel = spawnData.restored;	// DIFF-04: a restored NPC keeps its saved random level
	return ret;
}

@addMethod(CNewNPC)
function GMManageNGPLevels()
{
	gmCurrentNGPLevel = 0;
	if( !HasAbility('NoAdaptBalance') && !((W3ReplacerCiri)thePlayer) )
	{
		if( theGame.IsActive() )
		{
			if( FactsQuerySum("NewGamePlus") > 0 && !HasTag('animal') && !HasAbility('NPCDoNotGainBoost') )
				gmCurrentNGPLevel = theGame.params.GetNewGamePlusLevel();
		}
	}
	currentLevel = level + gmCurrentNGPLevel;
	levelFakeAddon = 0;	//modSigns: DIFF-05, legacy's "just in case": fake levels removed
	newGamePlusFakeLevelAddon = false;
}

// AI-01: legacy's AddLevelBonuses (5.x's rewritten body replaced): every bonus removed, the
// constitution template fixed (AI-02), DMG-15's armor fix, then the level: NPCDoNotGainBoost stops
// here; the scaling options (DIFF-04); guards at Geralt's level + 16; level 1 gets nothing; else the
// per-level abilities by kind. Called by timer and directly (RecalcLevel).
@replaceMethod(CNewNPC)
function AddLevelBonuses(dt : float, id : int)
{
	var playerLevel : int;	//modSigns

	RemoveTimer('AddLevelBonuses');	//modSigns

	playerLevel = thePlayer.GetLevel();	//modSigns

	if(levelBonusesComputedAtPlayerLevel == playerLevel && !fistFightForcedFromQuest)	//modSigns
		return;	//modSigns

	if(levelBonusesComputedAtPlayerLevel == -1 || fistFightForcedFromQuest)	//modSigns
	{	//modSigns
		currentLevel = level + gmCurrentNGPLevel;	//modSigns: reset and recalculate the level
		if(!gmKeepRandomLevel)	//modSigns: DIFF-04, kept after a load (legacy rolled it again)
			gmSavedRandomLevel = 0;	//modSigns: DIFF-04, a new random level
	}	//modSigns
	gmKeepRandomLevel = false;	//modSigns

	levelBonusesComputedAtPlayerLevel = playerLevel;	//modSigns
	fistFightForcedFromQuest = false;	//modSigns

	GMMonsterFixes();	//modSigns: AI-14, the cyclops's ablIgnoreSigns, the arachas's speed

	GMFixEntityLevel();	//modSigns: AI-06, the nekker warrior's and the deserters' levels

	GMCheckConstitutionAbility();	//modSigns: AI-02, one constitution template
	GMRemoveAllLevelBonuses();	//modSigns
	GMLazyArmorFix(this);	//modSigns: DMG-15, an armor ability for humans without one

	GMAddOptionBonuses();	//modSigns: DIFF-04, the menu's health and damage modifiers (every NPC, as legacy)

	if( HasAbility('NPCDoNotGainBoost') )	//modSigns
		return;	//modSigns

	// guards are level 80 by default: brought down to Geralt's level before scaling	//modSigns
	if( GetNPCType() == ENGT_Guard )	//modSigns
		currentLevel = playerLevel;	//modSigns

	// level scaling by the options, for Geralt only (DIFF-04)	//modSigns
	if( (W3PlayerWitcher)thePlayer )	//modSigns
		GMApplyLevelScaling(playerLevel);	//modSigns

	// guards at least at Geralt's level, and above it (PA4) unless the option says not (DIFF-04)	//modSigns
	if( GetNPCType() == ENGT_Guard )	//modSigns
	{	//modSigns
		if( currentLevel < playerLevel )	//modSigns
			currentLevel = playerLevel;	//modSigns
		if( !GMGetNoAdditionalLevelsForGuards() )	//modSigns
			currentLevel += theGame.params.LEVEL_DIFF_DEADLY + 1;	//modSigns
	}	//modSigns
	currentLevel = Max(1, currentLevel);	//modSigns
	// level 1 enemies have no additional abilities	//modSigns
	if( currentLevel < 2 )	//modSigns
		return;	//modSigns
	GMInternalAddLevelBonuses();	//modSigns
}

// AI-01: legacy's RemoveAllLevelBonuses (health kept as a share of the maximum); DIFF-04's health and damage
// modifiers too (legacy's removal of its older modifier names, never defined in 5.x or legacy's files, left out).
@addMethod(CNewNPC)
function GMRemoveAllLevelBonuses()
{
	var savedHealthPerc : float;

	if(GetStatMax( BCS_Vitality ) > 0)
		savedHealthPerc = GetStatPercents( BCS_Vitality );
	else if(GetStatMax( BCS_Essence ) > 0)
		savedHealthPerc = GetStatPercents( BCS_Essence );
	GMRemoveScalingSteps();	// DIFF-04's step abilities (difficulty/scaling.ws)
	RemoveAbility(theGame.params.ENEMY_BONUS_DEADLY);
	RemoveBuffImmunity(EET_Blindness, 'DeadlyEnemy');
	RemoveBuffImmunity(EET_WraithBlindness, 'DeadlyEnemy');
	RemoveAbility(theGame.params.ENEMY_BONUS_HIGH);
	RemoveAbility(theGame.params.ENEMY_BONUS_LOW);
	RemoveAbility(theGame.params.MONSTER_BONUS_DEADLY);
	RemoveAbility(theGame.params.MONSTER_BONUS_HIGH);
	RemoveAbility(theGame.params.MONSTER_BONUS_LOW);
	RemoveAbilityAll('AnimalLevelBonus');
	RemoveAbilityAll(theGame.params.ENEMY_BONUS_PER_LEVEL);
	RemoveAbilityAll(theGame.params.MONSTER_BONUS_PER_LEVEL_GROUP_ARMORED);
	RemoveAbilityAll(theGame.params.MONSTER_BONUS_PER_LEVEL_ARMORED);
	RemoveAbilityAll(theGame.params.MONSTER_BONUS_PER_LEVEL_GROUP);
	RemoveAbilityAll(theGame.params.MONSTER_BONUS_PER_LEVEL);
	RemoveAbilityAll('DisplayedLevelAbl');
	RemoveAbility('CiriHardcoreDebuffHuman');
	RemoveAbility('CiriHardcoreDebuffMonster');
	GMRestoreHealthPerc(savedHealthPerc);
}

// AI-01: max health recomputed after the abilities changed, the current health kept as a share of it.
@addMethod(CNewNPC)
function GMRestoreHealthPerc(perc : float)
{
	if(GetStatMax( BCS_Vitality ) > 0)
	{
		UpdateStatMax(BCS_Vitality);
		ForceSetStat(BCS_Vitality, GetStatMax(BCS_Vitality) * perc);
	}
	else if(GetStatMax( BCS_Essence ) > 0)
	{
		UpdateStatMax(BCS_Essence);
		ForceSetStat(BCS_Essence, GetStatMax(BCS_Essence) * perc);
	}
}

// AI-06: legacy's two level fixes in AddLevelBonuses: Blood and Wine's nekker warrior (sq107) at level 8,
// and the Nilfgaardian deserters at the Novigrad encounter gr13 at level 7 (their templates' levels suit
// their other encounters).
@addMethod(CNewNPC)
function GMFixEntityLevel()
{
	var templatePath : string;

	if( HasTag('sq107_monster_heavy') )
	{
		level = 8;
		currentLevel = level + gmCurrentNGPLevel;
	}

	templatePath = GetReadableName();
	if( IsHuman() && ( StrEndsWith( templatePath, "nilfgaardian_deserter_bow.w2ent" ) || StrEndsWith( templatePath, "nilfgaardian_deserter_shield.w2ent" ) || StrEndsWith( templatePath, "nilfgaardian_deserter_sword_hard.w2ent" ) ) )
	{
		if( GMIsAtLWGR13( this ) )
		{
			level = 7;
			currentLevel = level + gmCurrentNGPLevel;
		}
	}
}

// AI-06: legacy's IsAtLWGR13: the actor is within 50 m of the No Man's Land map pin nml_mp_gr13 (5.x names
// areas by CName).
function GMIsAtLWGR13( actor : CActor ) : bool
{
	var mapManager : CCommonMapManager;
	var entityMapPins : array< SEntityMapPinInfo >;
	var i : int;

	mapManager = theGame.GetCommonMapManager();

	if( mapManager.GetCurrentArea() != 'AN_NMLandNovigrad' )
		return false;

	entityMapPins = mapManager.GetEntityMapPins( mapManager.GetWorldPathFromAreaType( 'AN_NMLandNovigrad' ) );

	for( i = 0; i < entityMapPins.Size(); i += 1 )
	{
		if( entityMapPins[i].entityName == 'nml_mp_gr13' && VecDistanceSquared( entityMapPins[i].entityPosition, actor.GetWorldPosition() ) <= 2500 )
			return true;
	}

	return false;
}

// AI-02: legacy's CheckConstitutionAbility: an NPC keeps one constitution template
// (ConHumanoidMonster over ConAthletic over ConDefault).
@addMethod(CNewNPC)
function GMCheckConstitutionAbility()
{
	if( HasAbility('ConHumanoidMonster') )
	{
		RemoveAbility('ConDefault');
		RemoveAbility('ConAthletic');
	}
	else if( HasAbility('ConAthletic') && HasAbility('ConDefault') )
	{
		RemoveAbility('ConDefault');
	}
}

// AI-01: legacy's InternalAddLevelBonuses: the displayed level, then one per-level ability per level
// above 1 by kind (wolves and boars; Vitality users; Essence users armored or not, in groups or
// solo), and for a hostile non-boss 6+ or 15+ levels above Geralt the High or Deadly ability.
// With DIFF-04's progressive level bonuses, more per-level abilities above the level delta (GMLevelBonusCount).
@addMethod(CNewNPC)
function GMInternalAddLevelBonuses()
{
	var numAbls, lvlDiff : int;
	var ciriEntity : W3ReplacerCiri;
	var savedHealthPerc : float;

	lvlDiff = currentLevel - thePlayer.GetLevel();
	ciriEntity = (W3ReplacerCiri)thePlayer;
	if(GetStatMax( BCS_Vitality ) > 0)
		savedHealthPerc = GetStatPercents( BCS_Vitality );
	else if(GetStatMax( BCS_Essence ) > 0)
		savedHealthPerc = GetStatPercents( BCS_Essence );
	AddAbilityMultiple('DisplayedLevelAbl', currentLevel - 1);
	numAbls = GMLevelBonusCount(currentLevel);	// DIFF-04: progressive level bonuses (legacy's count)
	if ( ( HasAbility('mon_wolf_base') || HasAbility('mon_boar_base') || HasAbility('mon_boar_ep2_base') ) && GetStatMax( BCS_Vitality ) > 0 )
	{
		AddAbilityMultiple('AnimalLevelBonus', numAbls);
	}
	else if ( GetStatMax( BCS_Vitality ) > 0 )
	{
		AddAbilityMultiple(theGame.params.ENEMY_BONUS_PER_LEVEL, numAbls);
		if ( ciriEntity )
		{
			if(theGame.GetSpawnDifficultyMode() == EDM_Hardcore) AddAbility('CiriHardcoreDebuffHuman');	// DIFF-09: her sections' mode (legacy: GetDifficultyMode, the same without the option)
		}
		else if ( GetAttitudeBetween(this, thePlayer) == AIA_Hostile && !HasTag('HideHealthBarModule') )
		{
			// bosses already have 50% damage-over-time resistances: nothing on top
			if( lvlDiff >= theGame.params.LEVEL_DIFF_DEADLY )
				AddAbility(theGame.params.ENEMY_BONUS_DEADLY, true);
			else if( lvlDiff >= theGame.params.LEVEL_DIFF_HIGH )
				AddAbility(theGame.params.ENEMY_BONUS_HIGH, true);
		}
	}
	else if ( GetStatMax( BCS_Essence ) > 0 )
	{
		if ( CalculateAttributeValue(GetTotalArmor()) > 0.f )
		{
			if ( GetIsMonsterTypeGroup() )
				AddAbilityMultiple(theGame.params.MONSTER_BONUS_PER_LEVEL_GROUP_ARMORED, numAbls);
			else
				AddAbilityMultiple(theGame.params.MONSTER_BONUS_PER_LEVEL_ARMORED, numAbls);
		}
		else
		{
			if ( GetIsMonsterTypeGroup() )
				AddAbilityMultiple(theGame.params.MONSTER_BONUS_PER_LEVEL_GROUP, numAbls);
			else
				AddAbilityMultiple(theGame.params.MONSTER_BONUS_PER_LEVEL, numAbls);
		}
		if ( ciriEntity )
		{
			if ( theGame.GetSpawnDifficultyMode() == EDM_Hardcore ) AddAbility('CiriHardcoreDebuffMonster');	// DIFF-09: her sections' mode
		}
		else if ( GetAttitudeBetween(this, thePlayer) == AIA_Hostile && !HasTag('HideHealthBarModule') )
		{
			if( lvlDiff >= theGame.params.LEVEL_DIFF_DEADLY )
				AddAbility(theGame.params.MONSTER_BONUS_DEADLY, true);
			else if( lvlDiff >= theGame.params.LEVEL_DIFF_HIGH )
				AddAbility(theGame.params.MONSTER_BONUS_HIGH, true);
		}
	}
	GMRestoreHealthPerc(savedHealthPerc);
}
