// DMG slice 3a: the additive raw-damage pool (DMG-04). See docs/features/dmg.md.

@addField(W3DamageManagerProcessor)
var gmPoolAll : float;
@addField(W3DamageManagerProcessor)
var gmPoolNonPhysical : float;
@addField(W3DamageManagerProcessor)
var gmPoolPoison : float;
@addField(W3DamageManagerProcessor)
var gmFrozenForceDamage : float;	// EFX-02: Aard's force damage on a frozen victim, added after the pool

// Multiplies every damage type once by 1 + the pool (for non-physical types also their own terms,
// for poison too), then clears the pool. EFX-02: then adds Aard's force damage on a frozen victim to the
// action's force damage, or as a new one (legacy's order: the frozen bonus does not multiply it).
@addMethod(W3DamageManagerProcessor)
function GMPoolApply(out dmgInfos : array< SRawDamage >)
{
	var i, forceIdx : int;
	var sum : float;
	var forceDmg : SRawDamage;

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
	if(gmFrozenForceDamage > 0)
	{
		forceIdx = -1;
		for(i = 0; i < dmgInfos.Size(); i += 1)
			if(dmgInfos[i].dmgType == theGame.params.DAMAGE_NAME_FORCE)
				forceIdx = i;
		if(forceIdx != -1)
			dmgInfos[forceIdx].dmgVal += gmFrozenForceDamage;
		else
		{
			forceDmg.dmgType = theGame.params.DAMAGE_NAME_FORCE;
			forceDmg.dmgVal = gmFrozenForceDamage;
			dmgInfos.PushBack(forceDmg);
		}
	}
	gmFrozenForceDamage = 0;
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
// 5.x checks it in ReduceDamage, too late). 5.x's own versions of legacy's other terms (Rend, Perk 20;
// the Lynx and Netflix sets' are gone, ARM-06, ARM-15, Runeword 4's ENCH-05, Aerondight's SWD-05) are pool terms until their areas port legacy's.
// SWD-07: the NG+ school swords' sword_dmg_bonus (melee) and spell_dmg_bonus (signs), legacy's pool terms.
// ALCH-14 (audit F2): a frozen target's bonus (hpPercDamageBonusPerHit: Northern Wind +25/35/50%, the
// generic FrozenEffect +50%, EFX-02) is a pool term, legacy's, instead of 5.x's separate frost hit.
// EFX-02: the shattering hit no longer knocks down (5.x's knockdown applicator removed), and an Aard hit
// adds 5% of the victim's maximum health as force damage after the pool (legacy).
@replaceMethod(W3DamageManagerProcessor)
function ProcessDamageIncrease(out dmgInfos : array< SRawDamage >)
{
	var difficultyDamageMultiplier, rendLoad, rendBonus, overheal, rendRatio, focusCost, extraSignDamageMult, extraPoisonDamageMult, tempBonus : float;
	var i, j, dmgIdx, bonusCount, signSkillCatalystLevel, alchemySkillToxicShockLevel, meleeAttackCounterForResonanceSkill : int;
	var frozenBuff : W3Effect_Frozen;
	//modSigns: removed frozenDmgInfo (5.x's frost hit)
	var hadFrostDamage, signSkillCatalystActive : bool;
	var mpac : CMovingPhysicalAgentComponent;
	var rendBonusPerPoint, staminaRendBonus, perk20Bonus, minCatalyst, maxCatalyst, minEnhanced, maxEnhanced : SAbilityAttributeValue;
	var witcherAttacker : W3PlayerWitcher;
	var bouncedPower : SAbilityAttributeValue;	//modSigns: SKL-05
	var damageVal, damageBonus, min, max			: SAbilityAttributeValue;
	var npcVictim : CNewNPC;
	var sword : SItemUniqueId;
	//modSigns: removed actionFreeze (5.x's frost hit)
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


		frozenBuff = (W3Effect_Frozen)actorVictim.GetBuff(EET_Frozen);	//modSigns: ALCH-14 (audit F2), legacy's frozen bonus: a pool term
		poolAll += frozenBuff.GetAdditionalDamagePercents();	//modSigns: hpPercDamageBonusPerHit (Northern Wind +25/35/50%), legacy's dmgBonusMult


		if( (W3AardProjectile)action.causer || (W3AardEntity)action.causer )	//modSigns: EFX-02, Aard: 5% of the victim's maximum health as force damage (legacy)
			gmFrozenForceDamage = 0.05 * actorVictim.GetMaxHealth();	//modSigns: added after the pool (GMPoolApply), so the bonus does not multiply it

		actorVictim.RemoveAllBuffsOfType(EET_Frozen);
		//modSigns: removed 5.x's knockdown on the shattering hit (EFX-02, legacy: "remove knockdown, make it to multiply the damage instead")


		//modSigns: removed 5.x's separate frost hit of the bonus x the victim's current health (ALCH-14, audit F2)
	}



	//modSigns: removed 5.x's Netflix set tier 2 (Aard damage to enemies inside Yrden; ARM-15, DA3: +0.5 sign intensity against them instead, armor/netflixSet.ws)


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
	poolAll += GMHeftDamageBonus(action);	//modSigns: ENCH-10, Heft's melee damage bonus (legacy), a pool term

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

	if( playerAttacker && action.IsActionWitcherSign() && playerAttacker.HasBuff(EET_Mutagen09) )	//modSigns: ALCH-11, Foglet: flat base damage to every sign hit per blue mutagen (per second for damage over time), before the pool (legacy)
	{	//modSigns
		tempBonus = ((W3Mutagen09_Effect)playerAttacker.GetBuff(EET_Mutagen09)).GMGetM09Bonus();	//modSigns
		if( action.IsDoTDamage() )	//modSigns
			tempBonus *= action.GetDoTdt();	//modSigns
		for( i = 0 ; i < dmgInfos.Size() ; i += 1 )	//modSigns
			dmgInfos[i].dmgVal += tempBonus;	//modSigns
	}	//modSigns


	//modSigns: no extra damage for NPCs' ranged attacks above level 31


	//modSigns: removed 5.x's Runeword 4 (Invigoration) term: legacy's bonus is on the weapon damage (ENCH-05, damage/weapon.ws)


	//modSigns: removed 5.x's Wolven set term: sword damage per Bleeding stack nearby (ARM-09: legacy's oil bonuses, armor/wolfSet.ws)



	//modSigns: removed 5.x's Element of Surprise (perk_44, now In Combat's Fires: SKL-18, D61)


	//modSigns: removed 5.x's Feline set terms: fast attacks after a strong one, rear attacks and their stun (ARM-06: attack power, damage/formula.ws)




	if ( playerAttacker && action.IsActionRanged() && ((W3Petard)action.causer) )
	{
		//modSigns: removed 5.x's potion duration bonus to bomb damage (ALCH-14, the owner's DL7)


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
			damageVal.valueBase += GetWitcherPlayer().GetTotalWeaponDamage(sword, theGame.params.DAMAGE_NAME_SLASHING, GetInvalidUniqueId());	//modSigns: MUT-02, the sword's total base damage (legacy)
		}
		else if( playerAttacker.inv.GetItemCategory(sword) == 'silversword' )
		{
			damageVal.valueBase += GetWitcherPlayer().GetTotalWeaponDamage(sword, theGame.params.DAMAGE_NAME_SILVER, GetInvalidUniqueId());	//modSigns: MUT-02, the sword's total base damage (legacy)
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



	if( playerAttacker && action.IsActionWitcherSign() && action.GetSignType() == ST_Igni && !action.IsDoTDamage() && GetWitcherPlayer().HasGlyphwordActive('Glyphword 7 _Stats') )	//modSigns: ENCH-13, Rotation: +150 flat damage on each type before the pool (legacy)
	{	//modSigns
		tempBonus = GMRotationValue('glyphword7_dmg_buff');	//modSigns
		for( i = 0 ; i < dmgInfos.Size() ; i += 1 )	//modSigns
			dmgInfos[i].dmgVal += tempBonus;	//modSigns
	}	//modSigns

	npcVictim = (CNewNPC) actorVictim;
	//modSigns: removed 5.x's Mutation 8 sword damage (MUT-06: legacy's final-damage factor against a countered enemy, GMProcessDamageModification)

	if( playerAttacker && attackAction && attackAction.IsActionRanged() && (W3BoltProjectile)action.causer && !action.IsDoTDamage() && GetWitcherPlayer().IsMutationActive( EPMT_Mutation9 ) )	//modSigns: MUT-11, Cat Eyes doubles a bolt's base damage (legacy)
	{	//modSigns
		theGame.GetDefinitionsManager().GetAbilityAttributeValue( 'Mutation9', 'mut9_damage', min, max );	//modSigns
		for( i = 0; i < dmgInfos.Size(); i += 1 )	//modSigns
			dmgInfos[i].dmgVal *= 1 + min.valueMultiplicative;	//modSigns
	}	//modSigns

	if( playerAttacker && ( action.IsActionMelee() || action.IsActionWitcherSign() ) && GetWitcherPlayer().IsMutationActive( EPMT_Mutation10 ) && GetWitcherPlayer().HasBuff( EET_Mutation10 ) )	//modSigns: MUT-09, Euphoria adds the overdose drain per second to the base damage (legacy)
	{	//modSigns
		damageVal.valueBase = GetWitcherPlayer().GMGetToxicityDamage();	//modSigns
		if( action.IsDoTDamage() )	//modSigns
			damageVal.valueBase *= action.GetDoTdt();	//modSigns
		for( i = 0; i < dmgInfos.Size(); i += 1 )	//modSigns
			dmgInfos[i].dmgVal += damageVal.valueBase;	//modSigns
	}	//modSigns


	//modSigns: removed 5.x's Aerondight pool term (dmg_bonus per charge): SWD-05, legacy's damage per enemy is in GetTotalWeaponDamage



	//modSigns: Crippling Strike's bonus applies to final damage (GMProcessDamageModification)


	//modSigns: removed 5.x's Viper School poison term (perk_28, now Heavy Artillery: SKL-18, D61)


	//modSigns: removed 5.x's High Tolerance damage taken (alchemy_s24, now Refreshment: SKL-13)


	//modSigns: removed 5.x's Potent Sting (alchemy_s26, now Synergy: SKL-16, D60)


	//modSigns: removed 5.x's Resonance (magic_s41, D58): melee damage after a sign


	//modSigns: removed 5.x's new-tree bolt terms (SKL-06): Anatomical Knowledge's silver sword damage and Lightning Reflexes' headshot damage



	if( (W3PlayerWitcher)playerAttacker )	//modSigns: SWD-07, the NG+ school swords' weapon and sign damage bonuses
	{	//modSigns
		if( action.IsActionMelee() )	//modSigns
			poolAll += CalculateAttributeValue( playerAttacker.GetAttributeValue( 'sword_dmg_bonus' ) );	//modSigns
		if( action.IsActionWitcherSign() )	//modSigns
			poolAll += CalculateAttributeValue( playerAttacker.GetAttributeValue( 'spell_dmg_bonus' ) );	//modSigns
	}	//modSigns

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

