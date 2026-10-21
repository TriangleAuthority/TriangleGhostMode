// SKL-14: Oil Preparation, legacy's in both trees (D30, D60, project owner, 2026-10-09).
// - An oil's bonuses wear off with its charges, down to 50% of their value when it is empty (legacy's
//   OIL_DECAY_FACTOR): attack power, resistance reduction (damage/formula.ws), critical hit chance (melee
//   attacks only, the held sword's oils) and critical hit damage are read from the oil effects
//   (GMOilBonus) instead of the sword's item attributes. An empty oil is removed (5.x kept it on the sword
//   and on Geralt).
// - Poisoned Blades (alchemy_s12; classic GM_C_alchemy_s12, 5 levels): a melee hit with the right oil
//   poisons with 3% per level (new tree 5%) plus 5% per oil level above 1, wearing off, resisted by the
//   victim's poison resistance (5.x: 5% per level plus 10% per oil level above 1, not resisted).
// - Protective Coating (alchemy_s5; classic GM_C_alchemy_s5, 5 levels): damage taken from the monster
//   type of the held sword's oil is cut by 3% per level (new tree 5%) plus 5% per oil level above 1,
//   wearing off, as a cut of final damage (W3PlayerWitcher.ReduceDamage, defense/dodge.ws; 5.x: a
//   resistance bonus of 5% per level).
// See docs/features/skl.md.

// The share of an oil's bonuses left when it is empty (legacy).
function GMOilDecayFactor() : float
{
	return 0.5;
}

// The share of the oil's bonuses left now: 100% when fresh, 50% when empty.
@addMethod(W3Effect_Oil)
function GMScaleFactor() : float
{
	return GetAmmoPercentage() * GMOilDecayFactor() + (1 - GMOilDecayFactor());
}

// The oil item's level (1 to 3).
@addMethod(W3Effect_Oil)
function GMOilLevel() : int
{
	var min, max : SAbilityAttributeValue;

	theGame.GetDefinitionsManager().GetItemAttributeValueNoRandom(oilItemName, true, 'level', min, max);
	return RoundMath(CalculateAttributeValue(min));
}

// One of the oil's attributes against the monster category, wearing off, with the Wolven set's tier 1
// (ARM-09); nothing for another category or an empty oil.
@addMethod(W3Effect_Oil)
function GMBonus(monsterCategory : EMonsterCategory, attributeName : name) : SAbilityAttributeValue
{
	var attrVal, min, max : SAbilityAttributeValue;
	var factor : float;

	if(GetMonsterCategory() != monsterCategory || GetAmmoCurrentCount() < 1 || !IsNameValid(attributeName))
		return attrVal;
	theGame.GetDefinitionsManager().GetAbilityAttributeValue(oilAbility, attributeName, min, max);
	attrVal = GetAttributeRandomizedValue(min, max);
	factor = GMScaleFactor() * GMWolfOilMult();	// ARM-09: the Wolven set's tier 1 (armor/wolfSet.ws)
	attrVal.valueBase *= factor;
	attrVal.valueAdditive *= factor;
	attrVal.valueMultiplicative *= factor;
	return attrVal;
}

// A skill's value for this oil against the monster category: per skill level plus per oil level above 1,
// wearing off (Poisoned Blades, Protective Coating).
@addMethod(W3Effect_Oil)
function GMSkillBonus(monsterCategory : EMonsterCategory, skill : ESkill, perLevelName : name, perOilLevelName : name) : float
{
	var witcher : W3PlayerWitcher;
	var bonus : float;

	witcher = GetWitcherPlayer();
	if(!witcher || GetMonsterCategory() != monsterCategory || GetAmmoCurrentCount() < 1 || !witcher.CanUseSkill(skill))
		return 0;
	bonus = witcher.GetSkillLevel(skill) * CalculateAttributeValue(witcher.GetSkillAttributeValue(skill, perLevelName, false, true))
		+ (GMOilLevel() - 1) * CalculateAttributeValue(witcher.GetSkillAttributeValue(skill, perOilLevelName, false, true));
	return bonus * GMScaleFactor();
}

// The sum over the oils on the item.
@addMethod(CInventoryComponent)
function GMOilBonus(weaponId : SItemUniqueId, monsterCategory : EMonsterCategory, attributeName : name) : SAbilityAttributeValue
{
	var oils : array<W3Effect_Oil>;
	var attrVal : SAbilityAttributeValue;
	var i : int;

	oils = GetOilsAppliedOnItem(weaponId);
	for(i = 0; i < oils.Size(); i += 1)
		attrVal += oils[i].GMBonus(monsterCategory, attributeName);
	return attrVal;
}

// Poisoned Blades' chance with the item's oils against the monster category.
@addMethod(CInventoryComponent)
function GMOilPoisonChance(weaponId : SItemUniqueId, monsterCategory : EMonsterCategory) : float
{
	var oils : array<W3Effect_Oil>;
	var chance : float;
	var i : int;

	oils = GetOilsAppliedOnItem(weaponId);
	for(i = 0; i < oils.Size(); i += 1)
		chance += oils[i].GMSkillBonus(monsterCategory, S_Alchemy_s12, 'skill_chance', 'oil_level_chance');
	return chance;
}

// Protective Coating's cut with the item's oils against the monster category.
@addMethod(CInventoryComponent)
function GMOilProtection(weaponId : SItemUniqueId, monsterCategory : EMonsterCategory) : float
{
	var oils : array<W3Effect_Oil>;
	var bonus : float;
	var i : int;

	oils = GetOilsAppliedOnItem(weaponId);
	for(i = 0; i < oils.Size(); i += 1)
		bonus += oils[i].GMSkillBonus(monsterCategory, S_Alchemy_s05, 'defence_bonus', 'oil_level_defence');
	return bonus;
}

// Protective Coating against the attacker of this hit, with the oils of Geralt's held sword (legacy);
// not for damage over time.
@addMethod(W3PlayerWitcher)
function GMProtectiveCoatingCut(damageData : W3DamageAction) : float
{
	var heldWeapons : array<SItemUniqueId>;
	var weapon : SItemUniqueId;
	var category : EMonsterCategory;
	var tmpName : name;
	var tmpBool : bool;
	var i : int;
	var attacker : CActor;

	attacker = (CActor)damageData.attacker;
	if(!attacker || damageData.IsDoTDamage() || !CanUseSkill(S_Alchemy_s05))
		return 0;
	heldWeapons = inv.GetHeldWeapons();
	for(i = 0; i < heldWeapons.Size(); i += 1)
	{
		if(!inv.IsItemFists(heldWeapons[i]))
		{
			weapon = heldWeapons[i];
			break;
		}
	}
	if(!inv.IsIdValid(weapon))
		return 0;
	theGame.GetMonsterParamsForActor(attacker, category, tmpName, tmpBool, tmpBool, tmpBool);
	return inv.GMOilProtection(weapon, category);
}

// The charge share as a fraction (5.x divides two integers).
@replaceMethod(W3Effect_Oil)
function GetAmmoPercentage() : float
{
	return ((float)currCount) / ((float)maxCount);	//modSigns: float division (legacy)
}

// The oil's attack power wears off (legacy): 5.x's full value read off the sword is swapped for the
// oils' own.
@wrapMethod(W3Action_Attack)
function GetPowerStatValue() : SAbilityAttributeValue
{
	var result : SAbilityAttributeValue;
	var actorVictim, actorAttacker : CActor;
	var category : EMonsterCategory;
	var tmpName : name;
	var tmpBool : bool;

	result = wrappedMethod();
	actorVictim = (CActor)victim;
	actorAttacker = (CActor)attacker;
	if(actorVictim && actorAttacker)
	{
		theGame.GetMonsterParamsForActor(actorVictim, category, tmpName, tmpBool, tmpBool, tmpBool);
		if(actorAttacker.GetInventory().ItemHasActiveOilApplied(weaponId, category))
		{
			result -= actorAttacker.GetInventory().GetItemAttributeValue(weaponId, MonsterCategoryToAttackPowerBonus(category));
			result += actorAttacker.GetInventory().GMOilBonus(weaponId, category, MonsterCategoryToAttackPowerBonus(category));
		}
	}
	return result;
}

// 5.x body; changes marked //modSigns.
@replaceMethod(CR4Player)
function GetCriticalHitChance( isLightAttack : bool, isHeavyAttack : bool, target : CActor, victimMonsterCategory : EMonsterCategory, isBolt : bool ) : float
{
	var critChance : float;
	var confusionCrit : float;	//modSigns: ALCH-14
	var oilChanceAttribute : name;
	var weapons : array< SItemUniqueId >;
	var i : int;
	var holdsCrossbow : bool;
	var critVal : SAbilityAttributeValue;
	
	critChance = 0;
	
	
	if( FactsQuerySum( 'debug_fact_critical_boy' ) > 0 )
	{
		critChance += 1;
	}
	
	if( IsInState( 'HorseRiding' ) && ( ( CActor )GetUsedVehicle() ).GetMovingAgentComponent().GetRelativeMoveSpeed() >= 4.0 )
	{
		critChance += 1;
	}
	
	
	critChance += CalculateAttributeValue( GetAttributeValue( theGame.params.CRITICAL_HIT_CHANCE ) );
	
	
	weapons = inv.GetHeldWeapons();
	for( i=0; i<weapons.Size(); i+=1 )
	{			
		holdsCrossbow = ( inv.IsItemCrossbow( weapons[i] ) || inv.IsItemBolt( weapons[i] ) );
		if( holdsCrossbow != isBolt )
		{
			critVal = inv.GetItemAttributeValue( weapons[i], theGame.params.CRITICAL_HIT_CHANCE );
			critChance -= CalculateAttributeValue( critVal );
		}			
	}
	
	
	if( isHeavyAttack && CanUseSkill( S_Sword_s08 ) )
	{
		critChance += CalculateAttributeValue( GetSkillAttributeValue( S_Sword_s08, theGame.params.CRITICAL_HIT_CHANCE, false, true ) ) * GetSkillLevel( S_Sword_s08 );
	}
	else if( isLightAttack && CanUseSkill( S_Sword_s17 ) )
	{
		critChance += CalculateAttributeValue( GetSkillAttributeValue( S_Sword_s17, theGame.params.CRITICAL_HIT_CHANCE, false, true ) ) * GetSkillLevel( S_Sword_s17 );
	}

	if( target && target.HasBuff( EET_Confusion ) )
	{
		confusionCrit = ( ( W3ConfuseEffect )target.GetBuff( EET_Confusion ) ).GetCriticalHitChanceBonus();	//modSigns: ALCH-14, the larger of the confusion and blindness bonuses (legacy)
	}
	critChance += MaxF(confusionCrit, GMBlindnessCritBonus(target));	//modSigns: ALCH-14, Samum's blindness +50/75/100% (legacy)
	
	
	oilChanceAttribute = MonsterCategoryToCriticalChanceBonus( victimMonsterCategory );
	if( ( isLightAttack || isHeavyAttack ) && !isBolt )	//modSigns: melee only (legacy)
	{
		critChance += CalculateAttributeValue( inv.GMOilBonus( inv.GetCurrentlyHeldSword(), victimMonsterCategory, oilChanceAttribute ) );	//modSigns: the held sword's oils, wearing off (legacy)
		critChance += inv.GMOilWolfCritBonus( inv.GetCurrentlyHeldSword(), 'per_oil_crit_chance_bonus' );	//modSigns: ARM-09, the Wolven set's tier 2 per oil
	}

	return critChance;
}

// 5.x body; changes marked //modSigns.
@replaceMethod(CR4Player)
function GetCriticalHitDamageBonus(weaponId : SItemUniqueId, victimMonsterCategory : EMonsterCategory, isStrikeAtBack : bool) : SAbilityAttributeValue
{
	var bonus, oilBonus : SAbilityAttributeValue;
	var vsAttributeName : name;

	bonus = super.GetCriticalHitDamageBonus(weaponId, victimMonsterCategory, isStrikeAtBack);
	
	
	if( inv.ItemHasActiveOilApplied( weaponId, victimMonsterCategory ) )
	{
		vsAttributeName = MonsterCategoryToCriticalDamageBonus(victimMonsterCategory);
		oilBonus = inv.GMOilBonus(weaponId, victimMonsterCategory, vsAttributeName);	//modSigns: wearing off (legacy)
		bonus += oilBonus;
	}
	bonus.valueAdditive += inv.GMOilWolfCritBonus( weaponId, 'per_oil_crit_power_bonus' );	//modSigns: ARM-09, the Wolven set's tier 2 per oil, whatever the enemy
	
	return bonus;
}

// 5.x body; changes marked //modSigns.
@replaceMethod(CR4Player)
function ReduceAllOilsAmmo( id : SItemUniqueId )
{
	var i : int;
	var oils : array< W3Effect_Oil >;

	if( GMFixativeNoWear() )	//modSigns: Fixative at level 3, checked here as legacy, so a finisher (btTaskSyncAnimation) wears no oil either
		return;	//modSigns

	oils = inv.GetOilsAppliedOnItem( id );

	for( i=0; i<oils.Size(); i+=1 )
	{
		oils[ i ].ReduceAmmo();
		if( oils[ i ].GetAmmoCurrentCount() < 1 )	//modSigns: an empty oil is removed (legacy)
			RemoveEffect( oils[ i ] );	//modSigns
	}

	if( oils.Size() > 0 && ShouldProcessTutorial('TutorialOilAmmo') )	//modSigns: moved here from the damage step (legacy)
		FactsAdd("tut_used_oil_in_combat");	//modSigns
}

// Poisoned Blades (legacy). 5.x body; changes marked //modSigns.
@replaceMethod(W3DamageManagerProcessor)
function ProcessOnBeforeHitChecks()
{
	var effectAbilityName, monsterBonusType : name;
	var effectType : EEffectType;
	var null, monsterBonusVal : SAbilityAttributeValue;
	var oilLevel, skillLevel, i : int;
	var baseChance, perOilLevelChance, chance : float;
	var buffs : array<name>;
	var resPt, resPrc : float;	//modSigns

	
	if( playerAttacker && actorVictim && attackAction && attackAction.IsActionMelee() && playerAttacker.CanUseSkill(S_Alchemy_s12) )	//modSigns: the chance from the oils (legacy)
	{
		//modSigns: removed 5.x's chance from the oil's level read off the sword
		chance = playerAttacker.inv.GMOilPoisonChance( weaponId, victimMonsterCategory );	//modSigns: skill and oil level, wearing off
		actorVictim.GetResistValue( theGame.effectMgr.GetBuffResistStat( EET_Poison ), resPt, resPrc );	//modSigns: resisted (legacy)
		chance = MaxF( 0, chance * ( 1 - resPrc ) );	//modSigns
		if( (W3PlayerWitcher)playerAttacker )	//modSigns: MUT-13, Metamorphosis
			chance *= ((W3PlayerWitcher)playerAttacker).GMMutation12ChanceMult();	//modSigns


		if( chance > 0 && RandF() < chance )	//modSigns
		{

			dm.GetContainedAbilities(playerAttacker.GetSkillAbilityName(S_Alchemy_s12), buffs);
			for(i=0; i<buffs.Size(); i+=1)
			{
				EffectNameToType(buffs[i], effectType, effectAbilityName);
				action.AddEffectInfo(effectType, , , effectAbilityName);
			}
		}
		//modSigns: removed the end of 5.x's check of the oil's attack power on the sword
	}


	if( playerAttacker && actorVictim && attackAction 
		&& !playerAttacker.GetInventory().IsItemFists(weaponId) 
		&& playerAttacker.IsLightAttack(attackAction.GetAttackName()) 
		&& playerAttacker.CanUseSkill(S_Sword_s29) && action.IsCriticalHit() )
	{
				ProcessNewSkill_CripplingStrikes();
	}
}

// SKL-14: Fixative (classic alchemy_s6, the new tree's alchemy_s25 in place of Volatile Compound; legacy's
// 3 levels in both): +33.4% oil charges per level, and oils do not wear off at level 3. A sword holds one
// oil at a time, as in legacy, three with the Wolven set's tier 2 (ARM-09, armor/wolfSet.ws; 5.x's
// Fixative kept one oil per level). Hunter Instinct (classic
// alchemy_s7, 5 levels; the new tree's alchemy_s27): with the right oil, critical hit damage +6.68% (new
// tree 11.13%) per level per adrenaline point, from 1 point, not spent (5.x: only at full adrenaline).
// 5.x's Volatile Compound (bomb damage by toxicity) is gone (damage/pool.ws). The HUD's charge display and
// the item tooltip still read only the classic Fixative.

// The Fixative the player has (classic first); S_SUndefined if none.
@addMethod(CR4Player)
function GMFixativeSkill() : ESkill
{
	if(CanUseSkill(S_Alchemy_s06))
		return S_Alchemy_s06;
	if(CanUseSkill(S_Alchemy_s25))
		return S_Alchemy_s25;
	return S_SUndefined;
}

// Whether oils do not wear off (Fixative at level 3).
@addMethod(CR4Player)
function GMFixativeNoWear() : bool
{
	var skill : ESkill;

	skill = GMFixativeSkill();
	return skill != S_SUndefined && GetSkillLevel(skill) >= 3;
}

// The Hunter Instinct the player has (classic first); S_SUndefined if none.
@addMethod(W3PlayerWitcher)
function GMHunterInstinctSkill() : ESkill
{
	if(CanUseSkill(S_Alchemy_s07))
		return S_Alchemy_s07;
	if(CanUseSkill(S_Alchemy_s27))
		return S_Alchemy_s27;
	return S_SUndefined;
}

// 5.x body; changes marked //modSigns.
@replaceMethod(CR4Player)
function ApplyOil( oilId : SItemUniqueId, usedOnItem : SItemUniqueId ) : bool
{
	var oilAbilities : array< name >;
	var ammo, ammoBonus : float;
	var dm : CDefinitionsManagerAccessor;		
	var buffParams : SCustomEffectParams;
	var oilParams : W3OilBuffParams;
	var oilName : name;
	var min, max : SAbilityAttributeValue;
	var i : int;
	var oils : array< W3Effect_Oil >;
	var existingOil : W3Effect_Oil;
			
	if( !CanApplyOilOnItem( oilId, usedOnItem ) )
	{
		return false;
	}
	
	dm = theGame.GetDefinitionsManager();
	inv.GetItemAbilitiesWithTag( oilId, theGame.params.OIL_ABILITY_TAG, oilAbilities );
	oilName = inv.GetItemName( oilId );
	oils = inv.GetOilsAppliedOnItem( usedOnItem );
	
	
	for( i=0; i<oils.Size(); i+=1 )
	{
		if( oils[ i ].GetOilItemName() == oilName )
		{
			existingOil = oils[ i ];
			break;
		}
	}
	
	
	if(CanUseSkill(S_Alchemy_s06))
		CheckForPreviousLevelOilExploit(oilName,oils);
	
	
	
	if( !existingOil )
	{
		
		
		if( !GetWitcherPlayer() || GMMaxOilsPerSword() <= 1 )	//modSigns: one oil at a time (legacy), but with the Wolven set's tier 2 (ARM-09)
		
		{
			inv.RemoveAllOilsFromItem( usedOnItem );
		}
		else
		{
			//modSigns: removed 5.x's Fixative keeping one oil per level
			if( inv.GetActiveOilsAppliedOnItemCount( usedOnItem ) >= GMMaxOilsPerSword() )	//modSigns: ARM-09, the Wolven set's tier 2: up to three oils, the oldest goes (legacy)
				inv.RemoveOldestOilFromItem( usedOnItem );	//modSigns
		}
	}
	
	
	ammo = CalculateAttributeValue(inv.GetItemAttributeValue(oilId, 'ammo'));
	if(GMFixativeSkill() != S_SUndefined)	//modSigns: Fixative in either tree
	{
		ammoBonus = CalculateAttributeValue(GetSkillAttributeValue(GMFixativeSkill(), 'ammo_bonus', false, false));	//modSigns
		ammo *= 1 + ammoBonus * GetSkillLevel(GMFixativeSkill());	//modSigns
	}
	
	
	if( existingOil )
	{
		existingOil.Reapply( RoundMath( ammo ) );
	}
	else
	{
		buffParams.effectType = EET_Oil;
		buffParams.creator = this;
		oilParams = new W3OilBuffParams in this;
		oilParams.iconPath = dm.GetItemIconPath( oilName );
		oilParams.localizedName = dm.GetItemLocalisationKeyName( oilName );
		oilParams.localizedDescription = dm.GetItemLocalisationKeyName( oilName );
		oilParams.sword = usedOnItem;
		oilParams.maxCount = RoundMath( ammo );
		oilParams.currCount = RoundMath( ammo );
		oilParams.oilAbilityName = oilAbilities[ 0 ];
		oilParams.oilItemName = oilName;
		buffParams.buffSpecificParams = oilParams;
		
		AddEffectCustom( buffParams );
		
		delete oilParams;
	}
	
	LogOils("Added oil <<" + oilName + ">> to <<" + inv.GetItemName( usedOnItem ) + ">>");
	
	
	SetFailedFundamentalsFirstAchievementCondition( true );		
	
	theGame.GetGlobalEventsManager().OnScriptedEvent( SEC_OnOilApplied );
	
	if( !inv.IsItemHeld( usedOnItem ) )
	{
		PauseOilBuffs( inv.IsItemSteelSwordUsableByPlayer( usedOnItem ) );
	}
	
	return true;
}

// 5.x body; changes marked //modSigns.
@replaceMethod(W3PlayerWitcher)
function GetCriticalHitDamageBonus(weaponId : SItemUniqueId, victimMonsterCategory : EMonsterCategory, isStrikeAtBack : bool) : SAbilityAttributeValue
{
	var min, max, bonus, null, oilBonus : SAbilityAttributeValue;
	var mutagen : CBaseGameplayEffect;
	var monsterBonusType : name;

	bonus = super.GetCriticalHitDamageBonus(weaponId, victimMonsterCategory, isStrikeAtBack);
	AccumulateHeightenedToleranceCritBonus(bonus);

	
	if( inv.ItemHasActiveOilApplied( weaponId, victimMonsterCategory ) && GetStat( BCS_Focus ) >= 1 && GMHunterInstinctSkill() != S_SUndefined )	//modSigns: from 1 adrenaline point, either tree (legacy)
	{
		monsterBonusType = MonsterCategoryToAttackPowerBonus( victimMonsterCategory );
		oilBonus = inv.GetItemAttributeValue( weaponId, monsterBonusType );
		if(oilBonus != null)
		{
			bonus += GetSkillAttributeValue(GMHunterInstinctSkill(), theGame.params.CRITICAL_HIT_DAMAGE_BONUS, false, false) * GetSkillLevel(GMHunterInstinctSkill()) * FloorF(GetStat(BCS_Focus));	//modSigns: per adrenaline point (legacy)
		}
	}

	
	if (isStrikeAtBack && HasBuff(EET_Mutagen11))
	{
		mutagen = GetBuff(EET_Mutagen11);
		theGame.GetDefinitionsManager().GetAbilityAttributeValue(mutagen.GetAbilityName(), 'damageIncrease', min, max);
		bonus += GetAttributeRandomizedValue(min, max);
	}

	return bonus;
}
