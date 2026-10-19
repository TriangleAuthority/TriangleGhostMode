// DMG slice 3b: the order of damage steps and the final-damage step (DMG-05), the player's minimum
// damage removed (DMG-01), VulnerableFromFront before the formula (DMG-02). See docs/features/dmg.md.

// DMG-05: the order of damage steps. 5.x's body; the final-damage step (GMProcessDamageModification)
// runs after ReduceDamage, before 5.x's immortality clamp (moved here from ReduceDamage by 5.x) and
// before direct damage, which it does not touch. DEF-01's dodge check wraps this function.
@replaceMethod(W3DamageManagerProcessor)
function ProcessActionDamage() : bool
{
	var directDmgIndex, size, i : int;
	var dmgInfos : array< SRawDamage >;
	var immortalityMode : EActorImmortalityMode;
	var dmgValue : float;
	var anyDamageProcessed, fallingRaffard : bool;
	var victimHealthPercBeforeHit, frozenAdditionalDamage : float;
	//modSigns: removed debilitatingPoisonMin, debilitatingPoisonMax (unused: Killing Spree replaced Debilitating Poison, SKL)
	var powerMod : SAbilityAttributeValue;
	var witcher : W3PlayerWitcher;
	var canLog : bool;
	var immortalityChannels : array<EActorImmortalityChannel>;

	canLog = theGame.CanLog();


	action.SetAllProcessedDamageAs(0);
	size = action.GetDTs( dmgInfos );
	action.SetDealtFireDamage(false);


	if(!actorVictim || (!actorVictim.UsesVitality() && !actorVictim.UsesEssence()) )
	{

		for(i=0; i<size; i+=1)
		{
			if(dmgInfos[i].dmgType == theGame.params.DAMAGE_NAME_FIRE && dmgInfos[i].dmgVal > 0)
			{
				action.victim.OnFireHit( (CGameplayEntity)action.causer );
				break;
			}
		}

		if ( !actorVictim.abilityManager )
			actorVictim.OnDeath(action);

		return false;
	}


	if(actorVictim.UsesVitality())
		victimHealthPercBeforeHit = actorVictim.GetStatPercents(BCS_Vitality);
	else
		victimHealthPercBeforeHit = actorVictim.GetStatPercents(BCS_Essence);


	if ( actorVictim && playerAttacker && victimMonsterCategory == MC_Specter && playerAttacker.HasBuff(EET_Mutagen28) && !actorVictim.HasAbility( 'ShadowFormActive' ) && !action.GetSimulateOnly())
	{
		actorVictim.BlockAbility('ShadowForm', true);
		actorVictim.BlockAbility('Flashstep', true);
		actorVictim.BlockAbility('EssenceRegen', true);
		actorVictim.BlockAbility('Teleport', true);

		actorVictim.BlockAbility('Specter', true);
	}



	ProcessDamageIncrease( dmgInfos );


	ProcessNewSkills_Combat( dmgInfos );

	GMProcessDamageDecrease( dmgInfos );	//modSigns: SKL-11, Quen absorbs the raw damage before armor (legacy's ProcessDamageDecrease, skills/quen.ws)


	if ( canLog )
	{
		LogBeginning();
	}


	ProcessCriticalHitCheck();


	ProcessOnBeforeHitChecks();


	powerMod = GetAttackersPowerMod();


	anyDamageProcessed = false;
	directDmgIndex = -1;
	witcher = GetWitcherPlayer();
	size = dmgInfos.Size();
	for( i = 0; i < size; i += 1 )
	{

		if(dmgInfos[i].dmgVal == 0)
			continue;

		if(dmgInfos[i].dmgType == theGame.params.DAMAGE_NAME_DIRECT)
		{
			directDmgIndex = i;
			continue;
		}


		if(dmgInfos[i].dmgType == theGame.params.DAMAGE_NAME_POISON && witcher == actorVictim && witcher.HasBuff(EET_GoldenOriole) && witcher.GetPotionBuffLevel(EET_GoldenOriole) == 3)
		{

			witcher.GainStat(BCS_Vitality, dmgInfos[i].dmgVal);


			if ( canLog )
			{
				LogDMHits("", action);
				LogDMHits("*** Player absorbs poison damage from level 3 Golden Oriole potion: " + dmgInfos[i].dmgVal, action);
			}


			dmgInfos[i].dmgVal = 0;

			continue;
		}

		if(dmgInfos[i].dmgType == theGame.params.DAMAGE_NAME_POISON && witcher == actorVictim && witcher.IsSetBonusActive(EISB_Viper))	//modSigns: ARM-11, the Viper set cancels poison damage and heals a share of it (legacy)
		{	//modSigns
			witcher.GainStat(BCS_Vitality, dmgInfos[i].dmgVal * witcher.GMViperPoisonHealRate());	//modSigns
			if ( canLog )	//modSigns
				LogDMHits("*** Player absorbs poison damage from Viper Set ability: " + (dmgInfos[i].dmgVal * witcher.GMViperPoisonHealRate()), action);	//modSigns
			dmgInfos[i].dmgVal = 0;	//modSigns
			continue;	//modSigns
		}	//modSigns


		if ( canLog )
		{
			LogDMHits("", action);
			LogDMHits("*** Incoming " + NoTrailZeros(dmgInfos[i].dmgVal) + " " + dmgInfos[i].dmgType + " damage", action);
			if(action.IsDoTDamage())
				LogDMHits("DoT's current dt = " + NoTrailZeros(action.GetDoTdt()) + ", estimated dps = " + NoTrailZeros(dmgInfos[i].dmgVal / action.GetDoTdt()), action);
		}


		anyDamageProcessed = true;


		dmgValue = MaxF(0, CalculateDamage(dmgInfos[i], powerMod));


		if( DamageHitsEssence(  dmgInfos[i].dmgType ) )		action.processedDmg.essenceDamage  += dmgValue;
		if( DamageHitsVitality( dmgInfos[i].dmgType ) )		action.processedDmg.vitalityDamage += dmgValue;
		if( DamageHitsMorale(   dmgInfos[i].dmgType ) )		action.processedDmg.moraleDamage   += dmgValue;
		if( DamageHitsStamina(  dmgInfos[i].dmgType ) )		action.processedDmg.staminaDamage  += dmgValue;
	}

	if(size == 0 && canLog)
	{
		LogDMHits("*** There is no incoming damage set (probably only buffs).", action);
	}

	if(canLog)
	{
		LogDMHits("", action);
		LogDMHits("Processing block, parry, immortality, signs and other GLOBAL damage reductions...", action);
	}


	if(actorVictim)
	{
		actorVictim.ReduceDamage(action);
		GMProcessDamageModification();	//modSigns: final damage, after every other step and before the immortality clamp (DMG-05)


		if(!action.GetIgnoreImmortalityMode())
		{

			if( actorVictim.IsInvulnerable() )
			{
				if(theGame.CanLog())
				{
					LogDMHits("W3DamageManagerProcessor.ProcessActionDamage: victim Invulnerable - no damage will be dealt", action );
				}
				action.SetAllProcessedDamageAs(0);
			}

			else if(actorAttacker && action.DealsAnyDamage())
				actorAttacker.SignalGameplayEventParamObject( 'DamageInstigated', action );


			if(actorVictim.IsImmortal())
			{
				if(theGame.CanLog())
				{
					LogDMHits("W3DamageManagerProcessor.ProcessActionDamage: victim is Immortal, clamping damage", action );
				}
				action.processedDmg.vitalityDamage = ClampF(action.processedDmg.vitalityDamage, 0, actorVictim.GetStat(BCS_Vitality)-1 );
				action.processedDmg.essenceDamage  = ClampF(action.processedDmg.essenceDamage, 0, actorVictim.GetStat(BCS_Essence)-1 );
			}
		}
		else
		{

			if(actorAttacker && action.DealsAnyDamage())
				actorAttacker.SignalGameplayEventParamObject( 'DamageInstigated', action );
		}
	}


	if(directDmgIndex != -1)
	{
		anyDamageProcessed = true;


		immortalityChannels = actorVictim.GetImmortalityModeChannels(AIM_Invulnerable);
		fallingRaffard = immortalityChannels.Size() == 1 && immortalityChannels.Contains(AIC_WhiteRaffardsPotion) && action.GetBuffSourceName() == "FallingDamage";

		dmgValue = dmgInfos[directDmgIndex].dmgVal;

		if ( action.GetSignSkill() == S_Magic_1 )
			dmgValue = MaxF(0, CalculateDamage(dmgInfos[directDmgIndex], powerMod));

		if(action.GetIgnoreImmortalityMode() || (!actorVictim.IsImmortal() && !actorVictim.IsInvulnerable() && !actorVictim.IsKnockedUnconscious()) || fallingRaffard)
		{
			action.processedDmg.vitalityDamage += dmgValue;
			action.processedDmg.essenceDamage  += dmgValue;
		}
		else if( actorVictim.IsInvulnerable() )
		{

		}
		else if( actorVictim.IsImmortal() )
		{

			action.processedDmg.vitalityDamage += MinF(dmgValue, actorVictim.GetStat(BCS_Vitality)-1 );
			action.processedDmg.essenceDamage  += MinF(dmgValue, actorVictim.GetStat(BCS_Essence)-1 );
		}
	}


	if( actorVictim.HasAbility( 'OneShotImmune' ) )
	{
		if( action.processedDmg.vitalityDamage >= actorVictim.GetStatMax( BCS_Vitality ) )
		{
			action.processedDmg.vitalityDamage = actorVictim.GetStatMax( BCS_Vitality ) - 1;
		}
		else if( action.processedDmg.essenceDamage >= actorVictim.GetStatMax( BCS_Essence ) )
		{
			action.processedDmg.essenceDamage = actorVictim.GetStatMax( BCS_Essence ) - 1;
		}
	}



	if(action.HasDealtFireDamage())
		action.victim.OnFireHit( (CGameplayEntity)action.causer );


	ProcessInstantKill();


	ProcessActionDamage_DealDamage();


	if(playerAttacker && witcher && attackAction.GetAttackName() != 'counter_attack_light')
	{
		witcher.SetRecentlyCountered(false);
		witcher.SetRecentlyDodged(false);
	}


	if( attackAction && !attackAction.IsCountered() && playerVictim && attackAction.IsActionMelee())
		theGame.GetGamerProfile().ResetStat(ES_CounterattackChain);


	ProcessActionDamage_ReduceDurability();


	if(playerAttacker && actorVictim)
	{

		if( playerAttacker.inv.ItemHasAnyActiveOilApplied(weaponId) )
		{
			//modSigns: removed 5.x's Fixative check: SKL-14, in ReduceAllOilsAmmo (legacy; skills/oils.ws)
			playerAttacker.ReduceAllOilsAmmo( weaponId );
			//modSigns: removed the tutorial fact: in ReduceAllOilsAmmo (legacy)


			if( !playerAttacker.inv.ItemHasActiveOilApplied( weaponId, victimMonsterCategory ) )
			{
				thePlayer.ShouldAutoApplyOilImmediately( actorVictim );
			}
		}
		else
		{
			thePlayer.ShouldAutoApplyOilImmediately( actorVictim );
		}



		playerAttacker.inv.ReduceItemRepairObjectBonusCharge(weaponId);
	}


	if(actorVictim && actorAttacker && !action.GetCannotReturnDamage() && !action.GetSimulateOnly())
		ProcessActionReturnedDamage();

	return anyDamageProcessed;
}


// DMG-01: a hit that deals less than 1 to the stat the victim uses deals nothing and plays no hit
// animation (legacy ModifyHitSeverityReactionFromDamage, its damage half; the hit severity half is AI's).
// Called in CActor.ReduceDamage, before the final-damage step, so the difficulty multiplier cannot lift
// such a hit above 1. Damage over time, parried, countered and dodged hits and flying NPCs are left alone.
function GMZeroSubOneDamage( out damageData : W3DamageAction )
{
	var actorVictim : CActor;
	var npcVictim : CNewNPC;
	var attackAction : W3Action_Attack;

	if( damageData.IsDoTDamage() )
		return;
	attackAction = (W3Action_Attack)damageData;
	if( attackAction && ( attackAction.IsParried() || attackAction.IsCountered() || attackAction.WasDodged() ) )
		return;
	actorVictim = (CActor)damageData.victim;
	if( !actorVictim )
		return;
	npcVictim = (CNewNPC)actorVictim;
	if( npcVictim && npcVictim.IsFlying() )
		return;
	if( actorVictim.UsesEssence() && damageData.processedDmg.essenceDamage < 1 )
	{
		damageData.processedDmg.essenceDamage = 0;
		damageData.SetHitAnimationPlayType(EAHA_ForceNo);
		return;
	}
	if( actorVictim.UsesVitality() && damageData.processedDmg.vitalityDamage < 1 )
	{
		damageData.processedDmg.vitalityDamage = 0;
		damageData.SetHitAnimationPlayType(EAHA_ForceNo);
	}
}

// DMG-05: final damage, after armor, attack power, resistances and ReduceDamage (legacy
// ProcessDamageModification): "if something decreases or increases the damage received (or the final
// damage dealt), then it modifies the final damage value". Skipped when there is no damage, for
// dodged hits and for effects' damage over time. The generic rules: the player's signs deal less to
// Vitality at low levels; the difficulty multiplier applies to hostile NPCs hitting the player only
// (5.x: every NPC's raw damage); hits below 1 deal nothing. DD1's exception: Crippling Strike's
// bonus (5.x: a raw damage multiplier; 5.x's alchemy_s24 is gone, SKL-13). SKL-06: the player's bolts and
// bombs not thrown from aiming deal half damage. Severance (ENCH-04) and Supercharged Glyphs (SKL-10)
// are here; the other areas' terms (Perk 16, Dimeritium) come with their areas; Mutation 8 is MUT-06's; non-deadly fights (DMG-10) and NPC friendly fire (DMG-12) are here.
@addMethod(W3DamageManagerProcessor)
function GMProcessDamageModification()
{
	var min, max : SAbilityAttributeValue;
	var mult : float;
	var npcVictim : CNewNPC;
	var ignoreDifficultySettings : bool;

	if(!action.DealsAnyDamage() || action.WasDodged() || action.IsDoTDamage() && (CBaseGameplayEffect)action.causer)
		return;
	npcVictim = (CNewNPC)actorVictim;

	// SKL-06, SKL-15: the player's bolts and bombs deal half damage unless thrown from aiming (legacy);
	// arrows reflected by a parry are not throws
	if( (W3PlayerWitcher)playerAttacker && (CThrowable)action.causer && !((CThrowable)action.causer).GMIsFromAimThrow() && !action.IsBouncedArrow() )
	{
		action.processedDmg.vitalityDamage *= 0.5;
		action.processedDmg.essenceDamage *= 0.5;
	}

	// the player's signs against Vitality: x0.25 at level 1 to x0.75 from level 11
	if( (W3PlayerWitcher)playerAttacker && action.IsActionWitcherSign() && actorVictim.UsesVitality() )
	{
		mult = 0.75 - 0.5 * MaxF(0, 1 - 0.1 * (actorAttacker.GetLevel() - 1));
		action.processedDmg.vitalityDamage *= mult;
		action.processedDmg.essenceDamage *= mult;
	}

	// Severance (ENCH-04): Whirl and Rend hits of the player lose Runeword 2's runeword2_damage_debuff while
	// Severance is active (the changelist's rule, the owner's decision; legacy's code cut every Whirl and Rend
	// hit; enchantments/replenishmentSeverance.ws)
	if( (W3PlayerWitcher)playerAttacker && action.IsActionMelee() && ( thePlayer.IsDoingSpecialAttack(false) || thePlayer.IsDoingSpecialAttack(true) ) && ((W3PlayerWitcher)playerAttacker).HasRunewordActive('Runeword 2 _Stats') )
	{
		theGame.GetDefinitionsManager().GetAbilityAttributeValue('Runeword 2 _Stats', 'runeword2_damage_debuff', min, max);
		mult = CalculateAttributeValue(min);
		action.processedDmg.vitalityDamage *= 1 - mult;
		action.processedDmg.essenceDamage *= 1 - mult;
	}

	// Supercharged Glyphs (SKL-10): the player's hits on an enemy inside the trap (skills/yrden.ws)
	if( (W3PlayerWitcher)playerAttacker && actorVictim && actorVictim.HasBuff(EET_YrdenHealthDrain) )
	{
		mult = ((W3Effect_YrdenHealthDrain)actorVictim.GetBuff(EET_YrdenHealthDrain)).GMGetDmgBonus();
		action.processedDmg.vitalityDamage *= 1 + mult;
		action.processedDmg.essenceDamage *= 1 + mult;
		((W3Effect_YrdenHealthDrain)actorVictim.GetBuff(EET_YrdenHealthDrain)).GMPlayFX();
	}

	// Crippling Strikes (SKL-03, both trees): a fast attack on a bleeding enemy (5.x's new-tree crippled
	// mark is gone, skills/cripplingStrikes.ws)
	mult = GMCripplingStrikesDamageMult(playerAttacker, attackAction, actorVictim);
	if( mult != 1 )
	{
		action.processedDmg.vitalityDamage *= mult;
		action.processedDmg.essenceDamage *= mult;
	}

	// Deadly Counter (MUT-06): a melee hit on a countered enemy, +33.34% per adrenaline point
	// (mutations/deadlyCounter.ws)
	mult = GMMutation8DamageMult();
	if( mult != 1 )
	{
		action.processedDmg.vitalityDamage *= mult;
		action.processedDmg.essenceDamage *= mult;
	}

	// In Combat's Fires (SKL-18, both trees): Geralt takes half the damage of his own bombs and bolts
	// (skills/inCombatsFiresPyro.ws)
	mult = GMInCombatsFiresDamageMult(actorAttacker, actorVictim, action.causer);
	if( mult != 1 )
	{
		action.processedDmg.vitalityDamage *= mult;
		action.processedDmg.essenceDamage *= mult;
	}

	// Muscle Memory (SKL-03, the new tree's, D53): a boosted fast attack (skills/muscleMemory.ws)
	mult = GMMuscleMemoryDamageMult(playerAttacker, attackAction);
	if( mult != 1 )
	{
		action.processedDmg.vitalityDamage *= mult;
		action.processedDmg.essenceDamage *= mult;
	}

	// DMG-10: non-deadly fights outside the fistfight minigame: a hit deals 20% of the victim's maximum
	// health (x2 heavy), scaled: the player x1 (x0.5 against Olaf and the ff205 troll); the prologue's
	// fistfighters x0.25; other NPCs x(0.25 + 0.25 per difficulty above the second + 0.1 per level
	// difference, -10 to 10); no difficulty multiplier
	ignoreDifficultySettings = actorAttacker && actorAttacker.IgnoresDifficultySettings();
	if( !thePlayer.IsFistFightMinigameEnabled() && gmWeaponsAreNotDeadly )
	{
		if(playerAttacker)
		{
			if(actorVictim.HasAbility('mon_ff204olaf') || actorVictim.HasAbility('mon_ff205troll'))
				mult = 0.5;
			else
				mult = 1;
		}
		else if(actorAttacker.HasAbility('fistfight_q002'))
			mult = 0.25;
		else
			mult = 0.25 + MaxF(0, (int)theGame.GetSpawnDifficultyMode() - 1) * 0.25 + 0.1 * ClampF(actorAttacker.GetLevel() - actorVictim.GetLevel(), -10, 10);
		if(actorVictim.UsesEssence())
			action.processedDmg.essenceDamage = 0.2 * (1 + 1 * (int)actorAttacker.IsHeavyAttack(attackAction.GetAttackName())) * actorVictim.GetMaxHealth() * mult;
		else if(actorVictim.UsesVitality())
			action.processedDmg.vitalityDamage = 0.2 * (1 + 1 * (int)actorAttacker.IsHeavyAttack(attackAction.GetAttackName())) * actorVictim.GetMaxHealth() * mult;
		ignoreDifficultySettings = true;
	}

	// the difficulty multiplier: hostile NPCs hitting the player only
	if( actorAttacker && actorAttacker != thePlayer && !ignoreDifficultySettings && actorVictim && actorVictim == thePlayer
		&& GetAttitudeBetween(actorAttacker, thePlayer) == AIA_Hostile )
	{
		if(thePlayer.IsFistFightMinigameEnabled())
			mult = 1.0 + ((int)theGame.GetSpawnDifficultyMode() - 1) * 0.25 + 0.1 * ClampF(actorAttacker.GetLevel() - actorVictim.GetLevel(), -10, 10);
		else
			mult = CalculateAttributeValue(actorAttacker.GetAttributeValue(theGame.params.DIFFICULTY_DMG_MULTIPLIER));
		action.processedDmg.vitalityDamage *= mult;
		action.processedDmg.essenceDamage *= mult;
	}

	// DMG-12: NPCs hitting friendly NPCs deal x0.25
	if( (CNewNPC)actorAttacker && npcVictim && GetAttitudeBetween(actorAttacker, npcVictim) == AIA_Friendly )
	{
		action.processedDmg.vitalityDamage *= 0.25;
		action.processedDmg.essenceDamage *= 0.25;
	}

	// a hit below 1 deals nothing
	if( action.processedDmg.vitalityDamage < 1.f && !action.IsDoTDamage() )
		action.processedDmg.vitalityDamage = 0;
	if( action.processedDmg.essenceDamage < 1.f && !action.IsDoTDamage() )
		action.processedDmg.essenceDamage = 0;
}

// DMG-01, DMG-02: 5.x's CActor.ReduceDamage without the player's minimum damage (armor can stop a hit
// completely) and without the VulnerableFromFront check, which ProcessDamageIncrease makes before the
// formula (legacy). DMG-12: hostile hits on allies deal 1% to 2% of their maximum health (Axii
// puppets 10% to 15%; legacy); 5.x's x0.1 for Axii'd allies off. The rest is 5.x's until its areas
// (Ice Armor and Eredin: AI; Mutagen 28: ALCH).
@replaceMethod(CActor)
function ReduceDamage( out damageData : W3DamageAction )
{
	var actorAttacker 			: CActor;
	var id 						: SItemUniqueId;
	var attackAction 			: W3Action_Attack;
	var arrStr 					: array<string>;
	var l_percAboutToBeRemoved 	: float;
	var l_healthPerc			: float;
	var l_threshold				: float;
	var l_maxPercLossAllowed	: float;
	var l_maxDamageAllowed		: float;
	var l_maxHealth, mult		: float;
	var l_actorTarget			: CActor;
	var canLog					: bool;
	var hitsToKill				: SAbilityAttributeValue;
	var thisNPC					: CNewNPC;
	var minDamage				: float;
	var i						: int;
	var dmgTypes 				: array< SRawDamage >;
	var hasPoisonDamage			: bool;

	canLog = theGame.CanLog();




	if( false && damageData.victim == thePlayer && !damageData.IsDoTDamage() )	//modSigns: no minimum damage for the player (5% of the raw damage, at least 1): armor can stop a hit
	{
		damageData.GetDTs( dmgTypes );


		for( i=0; i<dmgTypes.Size(); i+=1 )
		{
			if( dmgTypes[i].dmgType == theGame.params.DAMAGE_NAME_DIRECT )
			{
				dmgTypes.EraseFast( i );
				break;
			}
		}

		if( dmgTypes.Size() > 0 )
		{
			hasPoisonDamage = false;
			for( i=0; i<dmgTypes.Size(); i+=1 )
			{
				if( dmgTypes[ i ].dmgType == theGame.params.DAMAGE_NAME_POISON )
				{
					hasPoisonDamage = true;
					break;
				}
			}

			if( !( hasPoisonDamage && this == GetWitcherPlayer() && HasBuff( EET_GoldenOriole ) && GetWitcherPlayer().GetPotionBuffLevel( EET_GoldenOriole ) == 3) )
			{
				minDamage = 0;
				for( i=0; i<dmgTypes.Size(); i+=1 )
				{
					if( DamageHitsVitality( dmgTypes[ i ].dmgType ) )
					{
						minDamage += dmgTypes[ i ].dmgVal;
					}
				}
				minDamage *= 0.05;
				if(minDamage < 1)
				{
					minDamage = 1;
				}
				if( damageData.processedDmg.vitalityDamage < minDamage )
				{
					damageData.processedDmg.vitalityDamage = minDamage;
				}
			}
		}
	}


	if(damageData.IsActionRanged() && damageData.attacker == thePlayer && (W3BoltProjectile)(damageData.causer) )
	{
		if(UsesEssence() && damageData.processedDmg.essenceDamage < 1)
		{
			damageData.processedDmg.essenceDamage = 1;

			if ( canLog )
			{
				LogDMHits("CActor.ReduceDamage: victim would take no damage but it's a bolt so we deal 1 pt of damage", damageData );
			}
		}
		else if(UsesVitality() && damageData.processedDmg.vitalityDamage < 1)
		{
			damageData.processedDmg.vitalityDamage = 1;

			if ( canLog )
			{
				LogDMHits("CActor.ReduceDamage: victim would take no damage but it's a bolt so we deal 1 pt of damage", damageData );
			}
		}
	}


	GMZeroSubOneDamage(damageData);	//modSigns: DMG-01: a hit below 1 deals nothing and plays no hit animation (after the bolts' minimum of 1)
	thisNPC = (CNewNPC)this;
	if( thisNPC && damageData.attacker == thePlayer && !HasBuff(EET_AxiiGuardMe) &&
		( GetAttitudeBetween( this, thePlayer ) == AIA_Friendly ||
		( GetAttitudeBetween( this, thePlayer ) == AIA_Neutral && thisNPC.GetNPCType() == ENGT_Guard ) ) )
	{
		if ( canLog )
		{
			LogDMHits("Player attacked friendly or neutral community npc - no damage dealt", damageData);
		}
		damageData.SetAllProcessedDamageAs(0);
		damageData.ClearEffects();
		return;
	}


	if( false && HasBuff(EET_AxiiGuardMe) && damageData.attacker != thePlayer )	//modSigns: no x0.1 for Axii'd allies: legacy's ally rule at the end (DMG-12)
	{
		damageData.processedDmg.vitalityDamage *= 0.1f;
		damageData.processedDmg.essenceDamage *= 0.1f;
	}



	if(damageData.IsActionMelee() && HasAbility( 'ReflectMeleeAttacks' ) )
	{
		if ( canLog )
		{
			LogDMHits("CActor.ReduceDamage: victim is heavily armored and attacker bounces of his armor", damageData );
		}
		damageData.SetAllProcessedDamageAs(0);
		((CActor)damageData.attacker).ReactToReflectedAttack( this );
		damageData.ClearEffects();
		return;
	}


	if( false && !damageData.DealsAnyDamage() && damageData.GetBuffSourceName() != "Mutation4")	//modSigns: no early return for hits without damage (legacy): the rest still applies, e.g. the ally rule below (DMG-12, audit F1)
		return;


	if(damageData.IsActionMelee() && HasAbility( 'CannotBeAttackedFromAllSides' ) )
	{
		if ( canLog )
		{
			LogDMHits("CActor.ReduceDamage: victim attacked from behind and immune to this type of strike - no damage will be done", damageData );
		}
		damageData.SetAllProcessedDamageAs(0);
		((CActor)damageData.attacker).ReactToReflectedAttack( this );
		damageData.ClearEffects();
		return;
	}


	if(damageData.IsActionMelee() && HasAbility( 'CannotBeAttackedFromBehind' ) && IsAttackerAtBack(damageData.attacker) )
	{
		if ( canLog )
		{
			LogDMHits("CActor.ReduceDamage: victim attacked from behind and immune to this type of strike - no damage will be done", damageData );
		}
		damageData.SetAllProcessedDamageAs(0);
		((CActor)damageData.attacker).ReactToReflectedAttack( this );
		damageData.ClearEffects();
		return;
	}


	if(damageData.IsActionMelee() && HasAbility( 'CannotBeAttackedFromFront' ) && IsAttackerInFront(damageData.attacker) )
	{
		if ( canLog )
		{
			LogDMHits("CActor.ReduceDamage: victim attacked from front and immune to this type of strike - no damage will be done", damageData );
		}
		damageData.SetAllProcessedDamageAs(0);
		((CActor)damageData.attacker).ReactToReflectedAttack( this );
		damageData.ClearEffects();
		return;
	}


	if( false && damageData.IsActionMelee() && HasAbility( 'VulnerableFromFront' ) && !IsAttackerAtBack(damageData.attacker) )	//modSigns: moved to ProcessDamageIncrease, before the formula (here it came too late)
	{
		if ( canLog )
		{
			LogDMHits("CActor.ReduceDamage: victim attacked from front and vulnerable to this type of strike - attack will ignor armor", damageData );
		}
		damageData.SetIgnoreArmor( true );
		damageData.SetPointResistIgnored( true );
		return;
	}


	if( this.HasAbility( 'EredinInvulnerable' ) && damageData.IsActionWitcherSign() )
	{
		if ( canLog )
		{
			LogDMHits("CActor.ReduceDamage: victim has EredinInvulnerable ability - no damage will be done", damageData );
		}
		damageData.SetAllProcessedDamageAs(0);
		return;
	}


	if(this != thePlayer && IsCurrentlyDodging() && damageData.CanBeDodged() && ( VecDistanceSquared(this.GetWorldPosition(),damageData.attacker.GetWorldPosition()) > 1.7
		|| this.HasAbility( 'IgnoreDodgeMinimumDistance' ) ))
	{
		if ( canLog )
		{
			LogDMHits("Non-player character dodge - no damage dealt", damageData);
		}
		damageData.SetWasDodged();
		damageData.SetAllProcessedDamageAs(0);
		damageData.ClearEffects();
		damageData.SetHitAnimationPlayType(EAHA_ForceNo);
		return;
	}


	if(this != thePlayer && FactsDoesExist("debug_fact_weak"))
	{
		if ( canLog )
		{
			LogDMHits("CActor.ReduceDamage: using 'weak' cheat - all damage set to 0.001", damageData );
		}
		damageData.processedDmg.essenceDamage = MinF(0.001, damageData.processedDmg.essenceDamage);
		damageData.processedDmg.vitalityDamage = MinF(0.001, damageData.processedDmg.vitalityDamage);
		damageData.processedDmg.staminaDamage = MinF(0.001, damageData.processedDmg.staminaDamage);
		damageData.processedDmg.moraleDamage = MinF(0.001, damageData.processedDmg.moraleDamage);
	}




	if(damageData.IsParryStagger())
	{
		actorAttacker = (CActor)damageData.attacker;

		if ( ((CMovingPhysicalAgentComponent)( actorAttacker ).GetMovingAgentComponent()).GetCapsuleHeight() > 2.f )
			mult = theGame.params.PARRY_STAGGER_REDUCE_DAMAGE_LARGE;
		else if ( actorAttacker.GetRadius() > 0.6 )
			mult = theGame.params.PARRY_STAGGER_REDUCE_DAMAGE_LARGE;
		else if ( this == thePlayer && thePlayer.GetBossTag() != '' )
			mult = theGame.params.PARRY_STAGGER_REDUCE_DAMAGE_LARGE;
		else if ( actorAttacker.HasAbility( 'mon_troll_base' ) )
			mult = theGame.params.PARRY_STAGGER_REDUCE_DAMAGE_LARGE;
		else
			mult = theGame.params.PARRY_STAGGER_REDUCE_DAMAGE_SMALL;

		damageData.MultiplyAllDamageBy(mult);

		if ( canLog )
		{
			LogDMHits("Stagger-Parry, reducing damage by " + NoTrailZeros((1-mult)*100) + "%");
		}
	}
	else
	{

		attackAction = (W3Action_Attack)damageData;
		if(attackAction && damageData.IsActionMelee() && attackAction.CanBeParried() && (attackAction.IsParried() || attackAction.IsCountered()))
		{
			arrStr.PushBack(GetDisplayName());
			if(attackAction.IsParried())
			{
				if ( canLog )
				{
					LogDMHits("Attack parried - no damage", damageData);
				}
				theGame.witcherLog.AddCombatMessage(GetLocStringByKeyExtWithParams("hud_combat_log_parries", , , arrStr), attackAction.attacker, this);
			}
			else
			{
				if ( canLog )
				{
					LogDMHits("Attack countered - no damage", damageData);
				}
				theGame.witcherLog.AddCombatMessage(GetLocStringByKeyExtWithParams("hud_combat_log_counters", , , arrStr), attackAction.attacker, this);
			}

			damageData.SetAllProcessedDamageAs(0);
			return;
		}
	}

	actorAttacker = (CActor)damageData.attacker;


	if((CPlayer)actorAttacker && !((CPlayer)damageData.victim) && FactsQuerySum('player_is_the_boss') > 0)
	{
		if ( canLog )
		{
			LogDMHits("Using 'like a boss' cheat - damage set to 40% of targets MAX health", damageData);
		}
		damageData.processedDmg.vitalityDamage = GetStatMax(BCS_Vitality) / 2.5;
		damageData.processedDmg.essenceDamage = GetStatMax(BCS_Essence) / 2.5;
	}


	if(attackAction && actorAttacker == thePlayer && thePlayer.inv.IsItemBolt(attackAction.GetWeaponId()) )
	{
		if(thePlayer.IsOnBoat())
		{
			hitsToKill = GetAttributeValue('extraDamageWhenPlayerOnBoat');
			if(hitsToKill.valueAdditive > 0)
			{
				damageData.processedDmg.vitalityDamage = CeilF(GetStatMax(BCS_Vitality) / hitsToKill.valueAdditive);
				damageData.processedDmg.essenceDamage = CeilF(GetStatMax(BCS_Essence) / hitsToKill.valueAdditive);

				if(theGame.CanLog())
				{
					LogDMHits("Target is getting killed by " + NoTrailZeros(hitsToKill.valueAdditive) + " hits when being shot from boat by default bolts", damageData);
					LogDMHits("Final hacked damage is now, vit: " + NoTrailZeros(damageData.processedDmg.vitalityDamage) + ", ess: " + NoTrailZeros(damageData.processedDmg.essenceDamage), damageData);
				}
			}
		}
	}



	if( HasAbility( 'ShadowFormActive' ) )
	{
		if ( canLog )
		{
			LogDMHits("CActor.ReduceDamage: victim has ShadowFormActive ability - damage reduced to 10% of base", damageData );
		}
		damageData.processedDmg.vitalityDamage *= 0.1f;
		damageData.processedDmg.essenceDamage *= 0.1f;
		damageData.SetCanPlayHitParticle( false );
		theGame.witcherLog.CombatMessageAddGlobalDamageMult(0.1f);
	}



	if( actorAttacker && HasAbility( 'IceArmor' ) && !actorAttacker.HasAbility( 'Ciri_Rage' ) )
	{
		if ( theGame.GetDifficultyMode() == EDM_Easy )
		{
			if ( canLog )
			{
				LogDMHits("CActor.ReduceDamage: victim has IceArmor ability - damage reduced by 5%", damageData );
			}
			damageData.processedDmg.vitalityDamage *= 0.95f;
			damageData.processedDmg.essenceDamage *= 0.95f;
			theGame.witcherLog.CombatMessageAddGlobalDamageMult(0.95f);
		}
		else
		{
			if ( canLog )
			{
				LogDMHits("CActor.ReduceDamage: victim has IceArmor ability - damage reduced by 50%", damageData );
			}
			damageData.processedDmg.vitalityDamage *= 0.5f;
			damageData.processedDmg.essenceDamage *= 0.5f;
			theGame.witcherLog.CombatMessageAddGlobalDamageMult(0.5f);
		}
	}




	if( HasAbility( 'LastBreath' ) )
	{
		l_threshold 	= CalculateAttributeValue( GetAttributeValue('lastbreath_threshold') );
		if( l_threshold == 0 ) l_threshold = 0.25f;
		l_healthPerc 	= GetHealthPercents();


		if( theGame.GetEngineTimeAsSeconds() - lastBreathTime < 1 )
		{
			if( damageData.processedDmg.vitalityDamage > 0 ) 	damageData.processedDmg.vitalityDamage 	= 0;
			if( damageData.processedDmg.essenceDamage > 0 ) 	damageData.processedDmg.essenceDamage 	= 0;

			if ( canLog )
			{
				LogDMHits("CActor.ReduceDamage: victim just activated LastBreath ability - reducing damage" );
			}
		}
		else if( l_healthPerc > l_threshold )
		{
			l_maxHealth 			= GetMaxHealth();
			l_percAboutToBeRemoved 	= MaxF( damageData.processedDmg.vitalityDamage, damageData.processedDmg.essenceDamage ) / l_maxHealth;

			l_maxPercLossAllowed 	= l_healthPerc - l_threshold;

			if( l_percAboutToBeRemoved > l_maxPercLossAllowed )
			{

				l_maxDamageAllowed = l_maxPercLossAllowed * l_maxHealth;
				if( damageData.processedDmg.vitalityDamage > 0 ) 	damageData.processedDmg.vitalityDamage 	= l_maxDamageAllowed;
				if( damageData.processedDmg.essenceDamage > 0 ) 	damageData.processedDmg.essenceDamage 	= l_maxDamageAllowed;
				if ( canLog )
				{
					LogDMHits("CActor.ReduceDamage: victim has LastBreath ability - reducing damage", damageData );
				}

				SignalGameplayEvent('LastBreath');
				lastBreathTime = theGame.GetEngineTimeAsSeconds();
				DisableHitAnimFor( 1 );
			}
		}
	}

	if( this != thePlayer && damageData.attacker && GetAttitudeBetween(this, thePlayer) == AIA_Friendly && GetAttitudeBetween((CActor)damageData.attacker, thePlayer) == AIA_Hostile )	//modSigns: DMG-12: hostile hits on allies deal a share of their maximum health
	{	//modSigns
		if( HasBuff( EET_AxiiGuardMe ) )	//modSigns: an Axii puppet 10% to 15%
		{	//modSigns
			l_maxDamageAllowed = MaxF(20, 0.15 * GetMaxHealth());	//modSigns
			mult = MaxF(10, 0.10 * GetMaxHealth());	//modSigns
		}	//modSigns
		else	//modSigns: other allies 1% to 2%
		{	//modSigns
			l_maxDamageAllowed = MaxF(20, 0.02 * GetMaxHealth());	//modSigns
			mult = MaxF(10, 0.01 * GetMaxHealth());	//modSigns
		}	//modSigns
		l_maxDamageAllowed = RandRangeF(l_maxDamageAllowed, mult);	//modSigns
		damageData.processedDmg.vitalityDamage = l_maxDamageAllowed;	//modSigns
		damageData.processedDmg.essenceDamage = l_maxDamageAllowed;	//modSigns
	}	//modSigns
}
