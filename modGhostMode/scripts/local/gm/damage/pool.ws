// DMG slice 3a: the additive raw-damage pool (DMG-04). See docs/features/dmg.md.

@addField(W3DamageManagerProcessor)
var gmPoolAll : float;
@addField(W3DamageManagerProcessor)
var gmPoolNonPhysical : float;
@addField(W3DamageManagerProcessor)
var gmPoolPoison : float;

// Multiplies every damage type once by 1 + the pool (for non-physical types also their own terms,
// for poison too), then clears the pool.
@addMethod(W3DamageManagerProcessor)
function GMPoolApply(out dmgInfos : array< SRawDamage >)
{
	var i : int;
	var sum : float;

	for(i = 0; i < dmgInfos.Size(); i += 1)
	{
		sum = gmPoolAll;
		if(!IsDamageTypeAnyPhysicalType(dmgInfos[i].dmgType))
			sum += gmPoolNonPhysical;
		if(dmgInfos[i].dmgType == theGame.params.DAMAGE_NAME_POISON)
			sum += gmPoolPoison;
		if(sum != 0)
			dmgInfos[i].dmgVal *= 1 + sum;
	}
	gmPoolAll = 0;
	gmPoolNonPhysical = 0;
	gmPoolPoison = 0;
}

// DMG-04: the additive raw-damage pool. Every percentage bonus to raw damage is added to one sum
// that multiplies the weapon damage once, before armor and attack power ("remove damage stacking,
// make all multipliers additive", legacy; 5.x's multipliers too, DD1). Flat additions come first, so
// the pool scales them. DD1's exceptions: the underwater crossbow bonus stays a multiplier; Crippling
// Strike's bonus goes to final damage, as does the difficulty multiplier
// (GMProcessDamageModification). VulnerableFromFront is checked here, before the formula (legacy;
// 5.x checks it in ReduceDamage, too late). 5.x's own versions of legacy's other terms (Rend, Perk 20,
// Lynx, Aerondight, Runeword 4, Mutation 8) are pool terms until their areas port legacy's.
@replaceMethod(W3DamageManagerProcessor)
function ProcessDamageIncrease(out dmgInfos : array< SRawDamage >)
{
	var difficultyDamageMultiplier, rendLoad, rendBonus, overheal, rendRatio, focusCost, extraSignDamageMult, extraPoisonDamageMult, tempBonus : float;
	var i, j, dmgIdx, bonusCount, signSkillCatalystLevel, alchemySkillToxicShockLevel, meleeAttackCounterForResonanceSkill : int;
	var frozenBuff : W3Effect_Frozen;
	var frozenDmgInfo : SRawDamage;
	var hadFrostDamage, signSkillCatalystActive : bool;
	var mpac : CMovingPhysicalAgentComponent;
	var rendBonusPerPoint, staminaRendBonus, perk20Bonus, minCatalyst, maxCatalyst, minEnhanced, maxEnhanced : SAbilityAttributeValue;
	var witcherAttacker : W3PlayerWitcher;
	var bouncedPower : SAbilityAttributeValue;	//modSigns: SKL-05
	var damageVal, damageBonus, min, max			: SAbilityAttributeValue;
	var npcVictim : CNewNPC;
	var sword : SItemUniqueId;
	var actionFreeze : W3DamageAction;
	var aerondight	: W3Effect_Aerondight;
	var conjunctionDamageMult, spellPowerIgni : float;
	var toxicShockDamage : SRawDamage;
	var swordEntity: CWitcherSword;
	var inv			: CInventoryComponent;


	var aardDamage : SRawDamage;
	var yrdens : array<W3YrdenEntity>;
	var levelDiff : int;
	var aardDamageF : float;
	var spellPower, spellPowerAard, spellPowerYrden : float;
	var spNetflix : SAbilityAttributeValue;
	var poisonDamageValue : SAbilityAttributeValue;
	var attackPowerValue : SAbilityAttributeValue;



	var entities : array<CGameplayEntity>;
	var skillPassiveMod : float;



	var monsterBonusType : name;
	var null, tempAttribute : SAbilityAttributeValue;
	var resonanceDamage : SRawDamage;

	var elementOfSurpriseMult : float;
	var poolAll, poolNonPhysical, poolPoison : float;	//modSigns: the additive pool (applied by ProcessNewSkills_Combat)
	var survivalSkillElementOfSurpriseLevel : int;
	var minElementOfSurprise, maxElementOfSurprise : SAbilityAttributeValue;



	if( !thePlayer.IsFistFightMinigameEnabled() && gmWeaponsAreNotDeadly )	//modSigns: no raw damage bonuses in non-deadly fights (DMG-10)
		return;	//modSigns
	//modSigns: the difficulty multiplier applies to final damage, hostile NPCs hitting the player only (GMProcessDamageModification)
	if(action.IsActionMelee() && actorVictim && actorVictim.HasAbility( 'VulnerableFromFront' ) && actorAttacker && !actorVictim.IsAttackerAtBack(actorAttacker) )	//modSigns: moved from CActor.ReduceDamage: the hit ignores armor
		action.SetIgnoreArmor( true );	//modSigns




	if(actorVictim && playerAttacker && !action.IsDoTDamage() && actorVictim.HasBuff(EET_Frozen) && ( (W3AardProjectile)action.causer || (W3AardEntity)action.causer || action.DealsPhysicalOrSilverDamage()) )
	{

		action.SetWasFrozen();


		if( !( ( W3WhiteFrost )action.causer ) )
		{
			frozenBuff = (W3Effect_Frozen)actorVictim.GetBuff(EET_Frozen);
			frozenDmgInfo.dmgVal = frozenBuff.GetAdditionalDamagePercents() * actorVictim.GetHealth();
		}


		actorVictim.RemoveAllBuffsOfType(EET_Frozen);
		action.AddEffectInfo(EET_KnockdownTypeApplicator);


		if( !( ( W3WhiteFrost )action.causer ) )
		{
			actionFreeze = new W3DamageAction in theGame;
			actionFreeze.Initialize( actorAttacker, actorVictim, action.causer, action.GetBuffSourceName(), EHRT_None, CPS_Undefined, action.IsActionMelee(), action.IsActionRanged(), action.IsActionWitcherSign(), action.IsActionEnvironment() );
			actionFreeze.SetCannotReturnDamage( true );
			actionFreeze.SetCanPlayHitParticle( false );
			actionFreeze.SetHitAnimationPlayType( EAHA_ForceNo );
			actionFreeze.SetWasFrozen();
			actionFreeze.AddDamage( theGame.params.DAMAGE_NAME_FROST, frozenDmgInfo.dmgVal );
			theGame.damageMgr.ProcessAction( actionFreeze );
			delete actionFreeze;
		}
	}



	if(actorVictim && playerAttacker && GetWitcherPlayer().IsSetBonusActive( EISB_Netflix_2 ) && !action.IsDoTDamage() && ( (W3AardProjectile)action.causer || (W3AardEntity)action.causer))
	{
		yrdens = GetWitcherPlayer().yrdenEntities;

		if(yrdens.Size() > 0)
		{
			spellPowerAard = CalculateAttributeValue(GetWitcherPlayer().GetAttributeValue('spell_power_aard'));
			spellPowerYrden = CalculateAttributeValue(GetWitcherPlayer().GetAttributeValue('spell_power_yrden'));
			spellPower = ClampF(1 + spellPowerAard + spellPowerYrden + CalculateAttributeValue(GetWitcherPlayer().GetPowerStatValue(CPS_SpellPower)), 1, 3);

			for(i=0; i<yrdens.Size(); i+=1)
			{
				for(j=0; j<yrdens[i].validTargetsInArea.Size(); j+=1)
				{
					if(yrdens[i].validTargetsInArea[j] == actorVictim )
					{
						levelDiff = playerAttacker.GetLevel() - actorVictim.GetLevel();
						aardDamage.dmgType = theGame.params.DAMAGE_NAME_DIRECT;
						if( GetWitcherPlayer().CanUseSkill(S_Magic_s06) )
							aardDamageF = (RandRangeF(375.0, 325.0) + (playerAttacker.GetLevel() * 1.8f) + (GetWitcherPlayer().GetSkillLevel(S_Magic_s06) * 100) ) * spellPower;
						else
							aardDamageF = (RandRangeF(375.0, 325.0) + (playerAttacker.GetLevel() * 1.8f) ) * spellPower;

						if( actorVictim.GetCharacterStats().HasAbilityWithTag('Boss') || (W3MonsterHuntNPC)actorVictim || (levelDiff < 0 && Abs(levelDiff) > theGame.params.LEVEL_DIFF_HIGH))
						{
							aardDamage.dmgVal = aardDamageF * 0.75f;
						}
						else
						{
							aardDamage.dmgVal = aardDamageF;
						}

						spNetflix = action.GetPowerStatValue();
						aardDamage.dmgVal += 3 * actorVictim.GetHealth() * ( 0.01 + 0.03 * LogF( spNetflix.valueMultiplicative ) );
						dmgInfos.PushBack(aardDamage);
					}
				}
			}
		}
	}


	//modSigns: removed 5.x's Catalyst (magic_s35, D58): Aard and Igni damage to enemies inside Yrden




	//modSigns: removed 5.x's Toxic Shock (alchemy_s23, now Steady Aim: SKL-15, D60)


	//modSigns: removed 5.x's Elemental Attunement (perk_37, now Focus: SKL-18, D40)


	if(actorVictim)
	{
		mpac = (CMovingPhysicalAgentComponent)actorVictim.GetMovingAgentComponent();

		if(mpac && mpac.IsDiving())
		{
			mpac = (CMovingPhysicalAgentComponent)actorAttacker.GetMovingAgentComponent();

			if(mpac && mpac.IsDiving())
			{
				action.SetUnderwaterDisplayDamageHack();

				if(playerAttacker && attackAction && attackAction.IsActionRanged())
				{
					for(i=0; i<dmgInfos.Size(); i+=1)
					{
						if(FactsQuerySum("NewGamePlus"))
						{
							dmgInfos[i].dmgVal *= (1 + theGame.params.UNDERWATER_CROSSBOW_DAMAGE_BONUS_NGP);
						}
						else
						{
							dmgInfos[i].dmgVal *= (1 + theGame.params.UNDERWATER_CROSSBOW_DAMAGE_BONUS);
						}
					}
				}
			}
		}
	}


	if(playerAttacker && attackAction && SkillNameToEnum(attackAction.GetAttackTypeName()) == S_Sword_s02)
	{
		witcherAttacker = (W3PlayerWitcher)playerAttacker;

		//modSigns: removed 5.x's Rend terms (adrenaline up to the charge, rounded down; stamina by the charge ratio)
		poolAll += witcherAttacker.GMGetRendPowerBonus();	//modSigns: SKL-04, legacy's Rend bonus (GetRendPowerBonus), a pool term


		thePlayer.SetAttackActionName('');
	}

	if((W3PlayerWitcher)playerAttacker && action.IsActionRanged() && action.IsBouncedArrow() && actorVictim)	//modSigns: SKL-05, a reflected arrow: its archer's attack power base and Deflection's bonus (legacy)
	{	//modSigns
		bouncedPower = actorVictim.GetPowerStatValue(CPS_AttackPower);	//modSigns
		for(i = 0; i < dmgInfos.Size(); i += 1)	//modSigns
			dmgInfos[i].dmgVal += bouncedPower.valueBase;	//modSigns
		poolAll += ((W3PlayerWitcher)playerAttacker).GMDeflectionDamageBonus();	//modSigns: a pool term
	}	//modSigns
	if((W3PlayerWitcher)playerAttacker && action.IsActionRanged() && !action.IsDoTDamage() && (W3BoltProjectile)action.causer)	//modSigns: SKL-06, Steady Shot: flat damage on every type of a bolt hit (legacy's xbow_dmg_bonus), before the pool
	{	//modSigns
		tempBonus = ((W3PlayerWitcher)playerAttacker).GMSteadyShotDamage();	//modSigns
		for(i = 0; i < dmgInfos.Size(); i += 1)	//modSigns
			dmgInfos[i].dmgVal += tempBonus;	//modSigns
	}	//modSigns


	//modSigns: no extra damage for NPCs' ranged attacks above level 31


	if ( actorVictim && playerAttacker && attackAction && action.IsActionMelee() && thePlayer.HasAbility('Runeword 4 _Stats', true) && !attackAction.WasDodged() )
	{
		overheal = thePlayer.abilityManager.GetOverhealBonus() / thePlayer.GetStatMax(BCS_Vitality);

		if(overheal > 0.005f)
		{
			poolAll += overheal;	//modSigns: additive pool (5.x: a separate multiplier)

			thePlayer.abilityManager.ResetOverhealBonus();


			actorVictim.CreateFXEntityAtPelvis( 'runeword_4', true );
		}
	}


	if( playerAttacker && actorVictim && attackAction.IsActionMelee() && GetWitcherPlayer().IsSetBonusActive( EISB_Wolf_1 ) )
	{
		FindGameplayEntitiesInRange( entities, playerAttacker, 50, 1000, , FLAG_OnlyAliveActors );
		if( entities.Size() > 0 )
		{
			for( i=0; i<entities.Size(); i+=1 )
			{
				npcVictim = (CNewNPC) entities[i];
				if( npcVictim )
				{
					if( npcVictim.HasBuff( EET_Bleeding ) )  bonusCount += 1;
					if( npcVictim.HasBuff( EET_Bleeding1 ) ) bonusCount += 1;
					if( npcVictim.HasBuff( EET_Bleeding2 ) ) bonusCount += 1;
					if( npcVictim.HasBuff( EET_Bleeding3 ) ) bonusCount += 1;
				}
			}

			bonusCount *= ((W3PlayerWitcher)playerAttacker).GetSetPartsEquipped( EIST_Wolf );

			poolAll += bonusCount*0.01;	//modSigns: additive pool (5.x: a separate multiplier)
		}
	}



	//modSigns: removed 5.x's Element of Surprise (perk_44, now In Combat's Fires: SKL-18, D61)


	if( playerAttacker && playerAttacker.IsLightAttack( attackAction.GetAttackName() ) && playerAttacker.HasBuff( EET_LynxSetBonus ) && !attackAction.WasDodged() )
	{
		if( !attackAction.IsParried() && !attackAction.IsCountered() )
		{

			damageBonus = playerAttacker.GetAttributeValue( 'lynx_dmg_boost' );

			damageBonus.valueAdditive *= ((W3PlayerWitcher)playerAttacker).GetSetPartsEquipped( EIST_Lynx );

			poolAll += damageBonus.valueAdditive;	//modSigns: additive pool (5.x: a separate multiplier)
		}
	}


	if( playerAttacker && attackAction.IsActionMelee() && actorVictim.IsAttackerAtBack( playerAttacker ) && !actorVictim.HasAbility( 'CannotBeAttackedFromBehind' ) && ((W3PlayerWitcher)playerAttacker).IsSetBonusActive( EISB_Lynx_2 ) && !attackAction.WasDodged() && ( playerAttacker.inv.IsItemSteelSwordUsableByPlayer( attackAction.GetWeaponId() ) || playerAttacker.inv.IsItemSilverSwordUsableByPlayer( attackAction.GetWeaponId() ) ) )
	{
		if( !attackAction.IsParried() && !attackAction.IsCountered() && playerAttacker.GetStat(BCS_Focus) >= 1.0f )
		{
			theGame.GetDefinitionsManager().GetAbilityAttributeValue( GetSetBonusAbility( EISB_Lynx_2 ), 'lynx_2_dmg_boost', min, max );
			poolAll += min.valueAdditive;	//modSigns: additive pool (5.x: a separate multiplier)

			if ( !( thePlayer.IsInCombatAction() && ( thePlayer.GetCombatAction() == EBAT_SpecialAttack_Light || thePlayer.GetCombatAction() == EBAT_SpecialAttack_Heavy ) ) )
			{
				theGame.GetDefinitionsManager().GetAbilityAttributeValue( GetSetBonusAbility( EISB_Lynx_2 ), 'lynx_2_adrenaline_cost', min, max );
				focusCost = min.valueAdditive;
				if( GetWitcherPlayer().GetStat( BCS_Focus ) >= focusCost )
				{
					theGame.GetDefinitionsManager().GetAbilityAttributeValue( GetSetBonusAbility( EISB_Lynx_2 ), 'lynx_2_stun_duration', min, max );
					attackAction.AddEffectInfo( EET_Confusion, min.valueAdditive );
					playerAttacker.SoundEvent( "ep2_setskill_lynx_activate" );
					playerAttacker.DrainFocus( focusCost );
				}
			}
		}
	}




	if ( playerAttacker && action.IsActionRanged() && ((W3Petard)action.causer) )
	{
		skillPassiveMod = CalculateAttributeValue(GetWitcherPlayer().GetAttributeValue('potion_duration'));
		poolAll += skillPassiveMod;	//modSigns: additive pool (5.x: a separate multiplier)


		if ( GetWitcherPlayer().GMHeavyArtillerySkill() != S_SUndefined && !action.IsDoTDamage() )	//modSigns: Heavy Artillery, either tree (SKL-18)
		{
			perk20Bonus = GetWitcherPlayer().GetSkillAttributeValue( GetWitcherPlayer().GMHeavyArtillerySkill(), 'dmg_multiplier', false, false);	//modSigns
			poolAll += perk20Bonus.valueMultiplicative;	//modSigns: additive pool (5.x: a separate multiplier)
		}



		//modSigns: removed 5.x's Manticore School bomb term (perk_27, now Trick Shot: SKL-18, D61)
		if ( !action.IsDoTDamage() )	//modSigns: SKL-18, Wolf School's bomb damage against poisoned enemies (D61)
			poolAll += GetWitcherPlayer().GMWolfSchoolBombBonus(actorVictim);	//modSigns


		//modSigns: removed 5.x's Volatile Compound bomb term (alchemy_s25, now Fixative: SKL-14, D60)


		//modSigns: removed 5.x's Element of Surprise trigger (perk_44, now In Combat's Fires: SKL-18, D61)
	}


	if( playerAttacker && action.IsActionWitcherSign() && GetWitcherPlayer().IsMutationActive( EPMT_Mutation1 ) )
	{
		sword = playerAttacker.inv.GetCurrentlyHeldSword();

		damageVal.valueBase = 0;
		damageVal.valueMultiplicative = 0;
		damageVal.valueAdditive = 0;

		if( playerAttacker.inv.GetItemCategory(sword) == 'steelsword' )
		{
			damageVal += playerAttacker.inv.GetItemAttributeValue(sword, theGame.params.DAMAGE_NAME_SLASHING);
		}
		else if( playerAttacker.inv.GetItemCategory(sword) == 'silversword' )
		{
			damageVal += playerAttacker.inv.GetItemAttributeValue(sword, theGame.params.DAMAGE_NAME_SILVER);
		}
		theGame.GetDefinitionsManager().GetAbilityAttributeValue('Mutation1', 'dmg_bonus_factor', min, max);

		damageVal.valueBase *= CalculateAttributeValue(min);

		if( action.IsDoTDamage() )
		{
			damageVal.valueBase *= action.GetDoTdt();
		}

		for( i = 0 ; i < dmgInfos.Size() ; i+=1)
		{
			dmgInfos[i].dmgVal += damageVal.valueBase;
		}
	}


	npcVictim = (CNewNPC) actorVictim;
	if( playerAttacker && npcVictim && attackAction && action.IsActionMelee() && GetWitcherPlayer().IsMutationActive( EPMT_Mutation8 ) && ( victimMonsterCategory != MC_Human || npcVictim.IsImmuneToMutation8Finisher() ) && attackAction.GetWeaponId() == GetWitcherPlayer().GetHeldSword() )
	{
		dm.GetAbilityAttributeValue( 'Mutation8', 'dmg_bonus', min, max );

		poolAll += min.valueMultiplicative;	//modSigns: additive pool (5.x: a separate multiplier)
	}


	if( playerAttacker && actorVictim && attackAction && action.IsActionMelee() && playerAttacker.inv.ItemHasTag( attackAction.GetWeaponId(), 'Aerondight' ) )
	{
		aerondight = (W3Effect_Aerondight)playerAttacker.GetBuff( EET_Aerondight );

		if( aerondight )
		{
			min = playerAttacker.GetAbilityAttributeValue( 'AerondightEffect', 'dmg_bonus' );
			bonusCount = aerondight.GetCurrentCount();

			if( bonusCount > 0 )
			{
				min.valueMultiplicative *= bonusCount;

				poolAll += min.valueMultiplicative;	//modSigns: additive pool (5.x: a separate multiplier)
			}
		}
	}



	//modSigns: Crippling Strike's bonus applies to final damage (GMProcessDamageModification)


	//modSigns: removed 5.x's Viper School poison term (perk_28, now Heavy Artillery: SKL-18, D61)


	//modSigns: removed 5.x's High Tolerance damage taken (alchemy_s24, now Refreshment: SKL-13)


	//modSigns: removed 5.x's Potent Sting (alchemy_s26, now Synergy: SKL-16, D60)


	//modSigns: removed 5.x's Resonance (magic_s41, D58): melee damage after a sign


	//modSigns: removed 5.x's new-tree bolt terms (SKL-06): Anatomical Knowledge's silver sword damage and Lightning Reflexes' headshot damage



	if( actorAttacker && attackAction && actorAttacker.IsHeavyAttack(attackAction.GetAttackName()) )	//modSigns: heavy attacks: Strong Attack +50% weapon damage for the player, +25% for NPCs
	{	//modSigns
		if( playerAttacker == GetWitcherPlayer() )	//modSigns
		{	//modSigns
			damageBonus = GetWitcherPlayer().GetSkillAttributeValue(S_Sword_2, 'heavy_attack_dmg_boost', false, true);	//modSigns
			poolAll += damageBonus.valueMultiplicative;	//modSigns
		}	//modSigns
		else	//modSigns
			poolAll += 0.25;	//modSigns
	}	//modSigns

	gmPoolAll = poolAll;	//modSigns: applied once, after the new-tree combat skills add theirs
	gmPoolNonPhysical = poolNonPhysical;	//modSigns
	gmPoolPoison = poolPoison;	//modSigns
}

// DMG-04: 5.x runs this right after ProcessDamageIncrease: the new-tree combat skills add their
// bonuses to the pool (Muscle Memory, Strength Training, Precise Blows, Crushing Blows), then the pool
// is applied once.
@replaceMethod(W3DamageManagerProcessor)
function ProcessNewSkills_Combat(out dmgInfos : array< SRawDamage >)
{
	var witcherAttacker : W3PlayerWitcher;


	var perLevelDamageMultiplier:float;
	var damageIncreaseValue:SAbilityAttributeValue;
	var triggerChanceValue:SAbilityAttributeValue;
	var i:int;
	var triggerAtAttackCount:int;
	var cooldownSeconds:float;

	witcherAttacker = GetWitcherPlayer();



	if(witcherAttacker == playerAttacker
		&& attackAction)
	{
		if(!playerAttacker.GetInventory().IsItemFists(weaponId) && playerAttacker.IsLightAttack(attackAction.GetAttackName()))
		{
			if(witcherAttacker.CanUseSkill(S_Sword_s22))	//modSigns: the new tree's Muscle Memory (D53): a boosted attack's attack power and total damage, not raw damage
			{
				witcherAttacker.GMMuscleMemoryOnFastAttack(attackAction);	//modSigns
			}
			//modSigns: removed 5.x's Strength Training counter (D54: stacks per swing, skills/strengthTraining.ws)
			//modSigns: removed 5.x's Three Strikes on sword_s24 (Precise Blows, D57: skills/critBlows.ws)
		}
		else if( playerAttacker.IsHeavyAttack(attackAction.GetAttackName()))
		{
			gmPoolAll += witcherAttacker.GMStrengthTrainingConsume(attackAction);	//modSigns: Strength Training's weapon damage (D54; 5.x: its single bonus)
			if(witcherAttacker.GMMuscleMemoryArmed())	//modSigns: a strong attack ends Muscle Memory's boosts (D53)
				witcherAttacker.GMMuscleMemoryEnd();	//modSigns
			//modSigns: removed 5.x's Three Strikes and Crushing Blow procs on sword_s24 and sword_s25 (D55, D57: skills/critBlows.ws)
			if(witcherAttacker.CanUseSkill(S_Sword_s28))
			{
				ProcessNewSkill_SunderArmor();
			}
		}
	}
	GMPoolApply(dmgInfos);	//modSigns: the additive pool, once (DMG-04)
}


@replaceMethod(W3DamageManagerProcessor)
function ProcessNewSkill_MuscleMemory(out dmgInfos : array< SRawDamage >)
{
	var witcherAttacker : W3PlayerWitcher;

	var skillId:ESkill;
	var damageIncreaseMultiplier:float;
	var i:int;
	var comboCounter:int;

	skillId = S_Sword_s22;
	witcherAttacker = GetWitcherPlayer();
	comboCounter = witcherAttacker.GetSkillComboCounter(skillId);


	if(comboCounter > 0)
	{
		damageIncreaseMultiplier = 1.0 + GetDamageIncreaseBaseMultiplier(skillId, false);

		gmPoolAll += (damageIncreaseMultiplier) - 1;	//modSigns: additive pool (5.x: a separate multiplier)

		LogNewCombatSkill(skillId, "Damage Multiplier : " + damageIncreaseMultiplier);
	}
}


@replaceMethod(W3DamageManagerProcessor)
function ProcessNewSkill_StrengthTraining_Damage(out dmgInfos : array< SRawDamage >)
{
	var witcherAttacker : W3PlayerWitcher;
	var swordEntity:CWitcherSword;

	var skillId:ESkill;
	var damageIncreaseMultiplier:float;
	var i:int;

	skillId = S_Sword_s23;

	witcherAttacker = GetWitcherPlayer();
	swordEntity = witcherAttacker.GetHeldSwordEntity();

	LogNewCombatSkill(skillId, "Attack Num : " + witcherAttacker.GetSkillComboCounter(skillId));

	if (witcherAttacker.GetSkillComboCounter(skillId) >= GetTriggerAtAttackCount(skillId, false))
	{
		damageIncreaseMultiplier = 1.0 + GetDamageIncreaseBaseMultiplier(skillId, true);

		gmPoolAll += (damageIncreaseMultiplier) - 1;	//modSigns: additive pool (5.x: a separate multiplier)

		LogNewCombatSkill(skillId, "Damage Multiplier : " + damageIncreaseMultiplier);

		witcherAttacker.ResetSkillCombo(skillId);
	}
}


@replaceMethod(W3DamageManagerProcessor)
function ProcessNewSkill_PreciseBlows(out dmgInfos : array< SRawDamage >, variation:EPreciseBlowsCounterId)
{
	var witcherAttacker : W3PlayerWitcher;
	var swordEntity:CWitcherSword;
	var skillId:ESkill;
	var damageMultiplierValue:SAbilityAttributeValue;
	var i:int;
	var randVal:float;
	var triggerChance:float;
	var triggerAtAttackCount:int;
	var currentHitCount:int;
	var logMessage:string;
	var logMessageInGame:string;

	skillId = S_Sword_s24;

	witcherAttacker = GetWitcherPlayer();
	swordEntity = witcherAttacker.GetHeldSwordEntity();

	witcherAttacker.IncrementSkillComboCounterEx(skillId, GetSkillDuration(skillId), variation);

	if(variation == PreciseBlowsCounterId_Fast)
		LogNewCombatSkill(skillId, "(Fast) : Attack Num : " + witcherAttacker.GetSkillComboCounterEx(skillId, variation));
	else
		LogNewCombatSkill(skillId, "(Strong) : Attack Num : " + witcherAttacker.GetSkillComboCounterEx(skillId, variation));


	triggerAtAttackCount = GetTriggerAtAttackCount(skillId, false);
	currentHitCount = witcherAttacker.GetSkillComboCounterEx(skillId, variation);

	if (currentHitCount == triggerAtAttackCount - 1)
	{
		logMessageInGame = currentHitCount + " ... Ready";
	}
	else if (currentHitCount == triggerAtAttackCount)
	{
		randVal = RandF();
		triggerChance = GetTriggerChance(skillId);
		if (randVal < triggerChance)
		{
			logMessageInGame = "Power Strike !";
			if(swordEntity)
			{
				if(variation == PreciseBlowsCounterId_Fast)
					witcherAttacker.PlaySkillComboEffect(skillId, swordEntity, 'fast_attack_buff');
				else
					witcherAttacker.PlaySkillComboEffect(skillId, swordEntity, 'strong_attack_buff');

				thePlayer.AddTimer('SkillPreciseBlowsActiveBuffDurationReset', GetSkillDuration(skillId), false, false, TICK_Main, false, false);
			}

			damageMultiplierValue = witcherAttacker.GetSkillAttributeValue(skillId, 'damage_increase', false, true);
			gmPoolAll += damageMultiplierValue.valueMultiplicative;	//modSigns: additive pool (5.x: a separate multiplier)
			if(variation == PreciseBlowsCounterId_Fast)
				LogNewCombatSkill(skillId, "(Fast): Damage Multiplier : " + (1.0 + damageMultiplierValue.valueMultiplicative));
			else
				LogNewCombatSkill(skillId, "(Strong): Damage Multiplier : " + (1.0 + damageMultiplierValue.valueMultiplicative));
		}
		else
		{
			logMessageInGame = "Missed ...";
			if(variation == PreciseBlowsCounterId_Fast)
				LogNewCombatSkill(skillId, "(Fast) : Chance failed : " + randVal + " > chance:" + triggerChance);
			else
				LogNewCombatSkill(skillId, "(Strong) : Chance failed : " + randVal + " > chance:" + triggerChance);
		}

		witcherAttacker.ResetSkillComboEx(skillId, PreciseBlowsCounterId_Fast);
		witcherAttacker.ResetSkillComboEx(skillId, PreciseBlowsCounterId_Strong);
	}
	else
	{
		logMessageInGame = currentHitCount + " ...";

		if(swordEntity)
		{
			witcherAttacker.StopAllSkillComboEffectsEx(skillId, PreciseBlowsCounterId_Fast);
			witcherAttacker.StopAllSkillComboEffectsEx(skillId, PreciseBlowsCounterId_Strong);
		}
	}
}


@replaceMethod(W3DamageManagerProcessor)
function ProcessNewSkill_CrushingBlows(out dmgInfos : array< SRawDamage >)
{
	var witcherAttacker : W3PlayerWitcher;
	var swordEntity:CWitcherSword;
	var skillId:ESkill;
	var damageMultiplierValue:SAbilityAttributeValue;
	var triggerAtAttackCount:int;
	var firstPowerfulAttackCount:int;
	var attackCount:int;
	var i:int;
	var randVal:float;
	var triggerChance:float;
	var buffedAttackCount:int;
	var logMessage:string;
	var logMessageInGame:string;
	var resetCooldown:float;

	skillId = S_Sword_s25;

	resetCooldown = GetSkillDuration(skillId);

	witcherAttacker = GetWitcherPlayer();
	swordEntity = witcherAttacker.GetHeldSwordEntity();

	triggerAtAttackCount = GetTriggerAtAttackCount(skillId, false);
	firstPowerfulAttackCount = triggerAtAttackCount + 1;

	attackCount = witcherAttacker.GetSkillComboCounter(skillId);

	if(attackCount == 0)
		witcherAttacker.IncrementSkillComboCounter(skillId, resetCooldown);
	else
		witcherAttacker.IncrementSkillComboCounter(skillId, -1.0);

	attackCount += 1;

	if (attackCount >= triggerAtAttackCount)
	{
		buffedAttackCount = attackCount - triggerAtAttackCount;

		if(buffedAttackCount > 0)
		{




			damageMultiplierValue = witcherAttacker.GetSkillAttributeValue(skillId, 'damage_increase', false, true);
			gmPoolAll += damageMultiplierValue.valueMultiplicative;	//modSigns: additive pool (5.x: a separate multiplier)
			logMessage += "Attack Num : " + attackCount + " POWER STRIKE: Damage Multiplier : " + (1.0 + damageMultiplierValue.valueMultiplicative);
			logMessageInGame += "Power Strike !";
		}
		else
		{
			logMessage += "Attack Num : " + attackCount;
		}

		randVal = RandF();
		triggerChance = GetTriggerChance(skillId);

		if (randVal < triggerChance)
		{
			logMessage += " | SUCCESS";
			if(buffedAttackCount == 0)
				logMessageInGame += "Charging !";
			else
				logMessageInGame += " (Recharged)";

			if(swordEntity && buffedAttackCount == 0)
				witcherAttacker.PlaySkillComboEffect(skillId, swordEntity, 'strong_attack_buff');


			witcherAttacker.ResetSkillComboCounter(skillId);
			witcherAttacker.IncrementSkillComboCounter(skillId, resetCooldown);
		}
		else
		{
			logMessage += " | UNLUCKY : " + randVal + " > chance:" + triggerChance;


			if(buffedAttackCount == 0)
			{
				logMessageInGame = "Missed ...";
				witcherAttacker.ResetSkillComboCounter(skillId);
			}

			else if(buffedAttackCount == 2)
			{



			}
		}
	}
}

