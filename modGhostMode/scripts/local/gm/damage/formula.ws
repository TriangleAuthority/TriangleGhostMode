// DMG slice 2: the damage formula (DMG-01 to DMG-03). Armor is subtracted before attack power
// counts, as legacy Ghost Mode: damage = (weapon damage - armor) * attack power * (1 - resistance).
// See docs/features/dmg.md.

// Headshots and backstabs add 25% attack power (legacy W3GameParams HEAD_SHOT_DAMAGE_BONUS,
// BACK_ATTACK_DAMAGE_BONUS; General player abilities).
function GMHeadShotDamageBonus() : float
{
	return 0.25;
}

function GMBackAttackDamageBonus() : float
{
	return 0.25;
}

// DMG-12: what an ally's hit on a hostile deals (legacy CalculateDamage's "friendly npc damage"):
// a random 2% to 4% of the victim's maximum health (at least 10 to 20); an Axii puppet 6% to 12% x
// Puppet's level / 3; the mq1041 soldiers and Redanians 10% to 15%. Resistances still apply. The
// modSigns_zero_ally_dmg fact makes allies deal nothing (debug, DMG-14).
@addMethod(W3DamageManagerProcessor)
function GMAllyDamage(finalDamage : float) : float
{
	var npcAttacker : CNewNPC;
	var maxAllowedDmg, minAllowedDmg, axiiLvl : float;

	npcAttacker = (CNewNPC)actorAttacker;
	if( npcAttacker.HasBuff( EET_AxiiGuardMe ) )
	{
		// the player's Puppet level, either tree (legacy read the puppet's alt_axii_level, which 5.x's XML lacks)
		axiiLvl = Max(GetWitcherPlayer().GetSkillLevel(S_Magic_s05), GetWitcherPlayer().GetSkillLevel(S_Magic_s31));
		maxAllowedDmg = MaxF(20, 0.12 * actorVictim.GetMaxHealth() * axiiLvl / 3.0);
		minAllowedDmg = MaxF(10, 0.06 * actorVictim.GetMaxHealth() * axiiLvl / 3.0);
	}
	else if( npcAttacker.HasTag('mq1041_soldier') || npcAttacker.HasTag('mq1041_redanian') )
	{
		maxAllowedDmg = MaxF(20, 0.15 * actorVictim.GetMaxHealth());
		minAllowedDmg = MaxF(10, 0.10 * actorVictim.GetMaxHealth());
	}
	else
	{
		maxAllowedDmg = MaxF(20, 0.04 * actorVictim.GetMaxHealth());
		minAllowedDmg = MaxF(10, 0.02 * actorVictim.GetMaxHealth());
	}
	finalDamage = MaxF(10, RandRangeF(maxAllowedDmg, minAllowedDmg));
	if( FactsQuerySum( "modSigns_zero_ally_dmg" ) > 0 )
		finalDamage = 0;
	return finalDamage;
}

// DMG-02: armor and resistance rules. Armor points (resistance points + armor - armor piercing)
// and resistance (minus resistance reduction) never go below 0 (5.x shrinks armor for a negative
// resistance: DD2, not applied). Headshots and fistfight minigames ignore both; damage over time,
// point-resist-ignoring actions and the player's shock damage skip armor. Fists outside the
// minigame no longer ignore resistances. Legacy GetDamageResists; the other areas' terms (oils,
// skills, mutagens, sets, swords) stay 5.x's until those areas are ported.
@replaceMethod(W3DamageManagerProcessor)
function GetDamageResists(dmgType : name, out resistPts : float, out resistPerc : float)
{
	var armorReduction, armorReductionPerc, skillArmorReduction : SAbilityAttributeValue;
	var bonusReduct, bonusResist : float;
	var mutagenBuff : W3Mutagen28_Effect;
	var appliedOilName, vsMonsterResistReduction : name;
	var oils : array< W3Effect_Oil >;
	var i : int;


	//modSigns: vanilla's "fists against a non-Essence victim ignore every resistance" removed
	if(thePlayer.IsFistFightMinigameEnabled())	//modSigns: resistances and armor ignored in fistfight minigames
	{	//modSigns
		resistPts = 0;	//modSigns
		resistPerc = 0;	//modSigns
		return;	//modSigns
	}	//modSigns
	if(action.GetIsHeadShot())	//modSigns: headshots ignore armor and resistances
	{	//modSigns
		resistPts = 0;	//modSigns
		resistPerc = 0;	//modSigns
		return;	//modSigns
	}	//modSigns


	if(actorVictim)
	{

		actorVictim.GetResistValue( GetResistForDamage(dmgType, action.IsDoTDamage()), resistPts, resistPerc );


		//modSigns: removed 5.x's Protective Coating resistance (SKL-14: a cut of final damage in ReduceDamage, legacy)


		//modSigns: removed 5.x's Debilitating Poison (alchemy_s22, now Killing Spree: SKL-17, D60)


		if(playerVictim && actorAttacker && playerVictim.HasBuff(EET_Mutagen28))
		{
			mutagenBuff = (W3Mutagen28_Effect)playerVictim.GetBuff(EET_Mutagen28);
			mutagenBuff.GetProtection(attackerMonsterCategory, dmgType, action.IsDoTDamage(), bonusResist, bonusReduct);
			resistPts += bonusReduct;
			resistPerc += bonusResist;
		}


		if(actorAttacker)
		{

			armorReduction = actorAttacker.GetAttributeValue('armor_reduction');
			armorReductionPerc = actorAttacker.GetAttributeValue('armor_reduction_perc');


			if(playerAttacker)
			{
				vsMonsterResistReduction = MonsterCategoryToResistReduction(victimMonsterCategory);
				armorReductionPerc += playerAttacker.inv.GMOilBonus( weaponId, victimMonsterCategory, vsMonsterResistReduction );	//modSigns: SKL-14, the oil's value, wearing off (legacy)
				//modSigns: removed 5.x's charge share added as a multiplier for an oil with the attribute
			}


			if(playerAttacker && action.IsActionMelee() && playerAttacker.IsHeavyAttack(attackAction.GetAttackName()) && playerAttacker.CanUseSkill(S_Sword_2))
				armorReduction += playerAttacker.GetSkillAttributeValue(S_Sword_2, 'armor_reduction', false, true);


			if ( playerAttacker &&
				 action.IsActionMelee() && playerAttacker.IsHeavyAttack(attackAction.GetAttackName()) &&
				 ( dmgType == theGame.params.DAMAGE_NAME_PHYSICAL ||
				   dmgType == theGame.params.DAMAGE_NAME_SLASHING ||
			       dmgType == theGame.params.DAMAGE_NAME_PIERCING ||
				   dmgType == theGame.params.DAMAGE_NAME_BLUDGEONING ||
				   dmgType == theGame.params.DAMAGE_NAME_RENDING ||
				   dmgType == theGame.params.DAMAGE_NAME_SILVER
				 )
			   )
			{
				if(playerAttacker.CanUseSkill(S_Sword_s06))
				{

					skillArmorReduction = playerAttacker.GetSkillAttributeValue(S_Sword_s06, 'armor_reduction_perc', false, true);
					armorReductionPerc += skillArmorReduction * playerAttacker.GetSkillLevel(S_Sword_s06);
				}
				if(playerAttacker.CanUseSkill(S_Sword_s28))	//modSigns: SKL-04 (D56), legacy's Sunder Armor in the new tree too: a flat reduction (5.x: per-target stacks)
				{
					//modSigns: removed 5.x's stacks (GetSunderArmorPercent)
					skillArmorReduction = playerAttacker.GetSkillAttributeValue(S_Sword_s28, 'armor_reduction_perc', false, true);	//modSigns
					armorReductionPerc += skillArmorReduction * playerAttacker.GetSkillLevel(S_Sword_s28);	//modSigns
				}
			}
		}
	}


	if(!action.GetIgnoreArmor())
		resistPts += CalculateAttributeValue( actorVictim.GetTotalArmor() );


	resistPerc -= CalculateAttributeValue(armorReductionPerc);


	resistPts = MaxF(0, resistPts - CalculateAttributeValue(armorReduction));	//modSigns: a negative resistance does not shrink armor (5.x: armor * (1 + resistance))

	if(action.IsPointResistIgnored() || action.IsDoTDamage())	//modSigns: damage over time and point-resist-ignoring actions skip armor
		resistPts = 0;	//modSigns
	if(playerAttacker && dmgType == theGame.params.DAMAGE_NAME_SHOCK)	//modSigns: the player's shock damage (signs) skips armor
		resistPts = 0;	//modSigns


	resistPerc = MaxF(0, resistPerc);
}


// DMG-01: armor before attack power. damage = (raw + attack power base - armor) * attack power
// multiplier + attack power additive, then * (1 - resistance); armor applies to every damage type
// (5.x lets elemental, fire and frost through), as GetDamageResists decides. Removed as legacy: the
// burning-sign attack power cap, the fist bonus by level, the per-monster Igni weakness, the player's
// heavy attack x1.833 (Strong Attack's +50% weapon damage is in the pool, DMG-04). DMG-12: allies'
// damage by legacy's rule (GMAllyDamage); 5.x's ally floor, clamps and Puppet multipliers off. Kept
// until ALCH: Mutagen 2's resistance. Legacy CalculateDamage.
@replaceMethod(W3DamageManagerProcessor)
function CalculateDamage(dmgInfo : SRawDamage, powerMod : SAbilityAttributeValue) : float
{
	var finalDamage : float;
	var resistPoints, resistPercents : float;
	var ptsString, percString : string;
	var mutagen : CBaseGameplayEffect;
	var min, max : SAbilityAttributeValue;
	var encumbranceBonus : float;
	var temp : bool;
	var fistfightDamageMult : float;
	var burning : W3Effect_Burning;
	var rawDamage : float;	//modSigns
	var armorApplied : bool;	//modSigns


	var weaponName 		: name;
	var dmgBonus 		: float;
	var playerStlDmg 	: float;
	var playerSlvDmg 	: float;
	var playerFastSlvDmg: float;
	var playerSlvCritDmg: float;
	var multBonus 		: float;
	var dmgLevel		: int;
	var curStats		: SPlayerOffenseStats;
	var inv				: CInventoryComponent;



	if( !thePlayer.IsFistFightMinigameEnabled() && gmWeaponsAreNotDeadly )	//modSigns: non-deadly fights: the final-damage step sets the damage (DMG-10)
		return 10;	//modSigns
	GetDamageResists(dmgInfo.dmgType, resistPoints, resistPercents);


	if( thePlayer.IsFistFightMinigameEnabled() && actorAttacker == thePlayer )
	{
		finalDamage = MaxF(0, (dmgInfo.dmgVal));
	}
	else
	{

		//modSigns: no cap on the attack power of burning from signs

		rawDamage = MaxF(0, dmgInfo.dmgVal + powerMod.valueBase - resistPoints);	//modSigns: armor first: it must be penetrated before attack power counts
		finalDamage = MaxF(0, rawDamage * powerMod.valueMultiplicative + powerMod.valueAdditive);	//modSigns
		armorApplied = true;	//modSigns
		if(rawDamage == 0 && resistPoints > 0 && dmgInfo.dmgVal + powerMod.valueBase > 0)	//modSigns
			action.SetArmorReducedDamageToZero( true );	//modSigns



		inv = actorAttacker.GetInventory();
		weaponName = inv.GetItemName( weaponId );
		if( thePlayer.IsCiri() )
		{
			dmgLevel = ( actorVictim.GetLevel() -2 ) * 10;
		}
		else
		{
			dmgLevel = Min( actorVictim.GetLevel(), GetWitcherPlayer().GetLevel() ) * 40;
		}

		if( false && !playerAttacker && actorVictim && GetAttitudeBetween( thePlayer, actorAttacker ) == AIA_Friendly && !action.IsDoTDamage() && !actorAttacker.HasTag( 'Yennefer' ) && !actorAttacker.HasTag( 'keira' )	//modSigns: 5.x's ally damage floor off (DMG-12)
			&& !actorAttacker.HasTag( 'Philippa' ) && ( actorAttacker.IsWeaponHeld( 'silversword' ) || actorAttacker.IsWeaponHeld( 'staff2h' ) || weaponName == 'fists_lightning' || weaponName == 'fists_fire'
			|| actorAttacker.HasAbility( 'SkillWitcher' ) || actorAttacker.HasTag( 'zoltan' ) || actorAttacker.HasTag( 'hjalmar' ) || actorAttacker.HasTag( 'regis' ) || actorAttacker.HasBuff(EET_AxiiGuardMe) ) && ( finalDamage < dmgLevel || thePlayer.IsCiri() ) )
		{
			dmgBonus += dmgLevel - finalDamage;
			finalDamage = MaxF(0, (dmgInfo.dmgVal + powerMod.valueBase + dmgBonus) * powerMod.valueMultiplicative + powerMod.valueAdditive);
			armorApplied = false;	//modSigns: unreachable: the branch is off (DMG-12)
		}

	}

	if(finalDamage > 0.f && !armorApplied)	//modSigns
	{

		if(!action.IsPointResistIgnored() && !(dmgInfo.dmgType == theGame.params.DAMAGE_NAME_ELEMENTAL || dmgInfo.dmgType == theGame.params.DAMAGE_NAME_FIRE || dmgInfo.dmgType == theGame.params.DAMAGE_NAME_FROST ))
		{
			finalDamage = MaxF(0, finalDamage - resistPoints);

			if(finalDamage == 0.f)
				action.SetArmorReducedDamageToZero( true );
		}
	}

	if( !action.IsDoTDamage() && (CNewNPC)actorAttacker && actorVictim && GetAttitudeBetween(actorAttacker, thePlayer) == AIA_Friendly && GetAttitudeBetween(actorVictim, thePlayer) == AIA_Hostile )	//modSigns: DMG-12: an ally's hit on a hostile deals a share of the victim's maximum health, before resistances
		finalDamage = GMAllyDamage(finalDamage);	//modSigns

	if(finalDamage > 0.f)
	{

		if (playerVictim == GetWitcherPlayer() && playerVictim.HasBuff(EET_Mutagen02))
		{
			encumbranceBonus = 1 - (GetWitcherPlayer().GetEncumbrance() / GetWitcherPlayer().GetMaxRunEncumbrance(temp));
			if (encumbranceBonus < 0)
				encumbranceBonus = 0;
			mutagen = playerVictim.GetBuff(EET_Mutagen02);
			dm.GetAbilityAttributeValue(mutagen.GetAbilityName(), 'resistGainRate', min, max);
			encumbranceBonus *= CalculateAttributeValue(GetAttributeRandomizedValue(min, max));
			resistPercents += encumbranceBonus;
		}
		finalDamage *= ClampF(1 - resistPercents, 0, 1);	//modSigns
	}	





	if( false && !playerAttacker && actorVictim && !action.IsDoTDamage() && !thePlayer.IsFistFightMinigameEnabled() && finalDamage <= actorVictim.GetMaxHealth() * 0.01 && (GetAttitudeBetween( thePlayer, actorAttacker ) == AIA_Friendly || actorAttacker.HasBuff(EET_AxiiGuardMe)) )	//modSigns: off (DMG-12)
	{
		dmgBonus += dmgLevel - finalDamage;
		if ( powerMod.valueMultiplicative < 1.0 )
		{
			multBonus = 1.0 - powerMod.valueMultiplicative;
		}
		finalDamage = MaxF(actorVictim.GetMaxHealth() * 0.01, (dmgInfo.dmgVal + powerMod.valueBase + dmgBonus) * ( powerMod.valueMultiplicative + multBonus ) + powerMod.valueAdditive);

		if(!action.IsPointResistIgnored() && !(dmgInfo.dmgType == theGame.params.DAMAGE_NAME_ELEMENTAL || dmgInfo.dmgType == theGame.params.DAMAGE_NAME_FIRE || dmgInfo.dmgType == theGame.params.DAMAGE_NAME_FROST ))
		{
			finalDamage = MaxF(actorVictim.GetMaxHealth() * 0.01, finalDamage - resistPoints);

			if(finalDamage == 0.f)
				action.SetArmorReducedDamageToZero( true );
			else
				action.SetArmorReducedDamageToZero( false );
		}

		finalDamage *= 1 - resistPercents;
	}


	curStats = GetWitcherPlayer().GetOffenseStatsList();
	playerStlDmg = MaxF(0, curStats.steelStrongDmg - resistPoints);
	playerStlDmg *= 1 - resistPercents;
	playerStlDmg /= 6;

	playerFastSlvDmg = MaxF(0, curStats.silverFastDmg - resistPoints);
	playerFastSlvDmg *= 1 - resistPercents;
	playerFastSlvDmg /= 6;

	playerSlvDmg = MaxF(0, curStats.silverStrongDmg - resistPoints);
	playerSlvDmg *= 1 - resistPercents;
	playerSlvDmg /= 6;

	playerSlvCritDmg = MaxF(0, curStats.silverStrongCritDmg - resistPoints);
	playerSlvCritDmg *= 1 - resistPercents;
	playerSlvCritDmg /= 6;

	if( false && !playerAttacker && actorVictim && !action.IsDoTDamage() && !thePlayer.IsFistFightMinigameEnabled() && (GetAttitudeBetween( thePlayer, actorAttacker ) == AIA_Friendly || actorAttacker.HasBuff(EET_AxiiGuardMe)) && !thePlayer.IsCiri()  )	//modSigns: off (DMG-12)
	{
		if(finalDamage > playerStlDmg && !actorAttacker.HasAbility( 'ForceInstantKill' ))
		{
			if ( actorAttacker.HasTag( 'regis' ) )
			{
				if ( finalDamage > playerSlvCritDmg * 2 )
				{
					finalDamage = ClampF( finalDamage, 0, playerSlvCritDmg * 2 );
					finalDamage = MaxF(actorVictim.GetMaxHealth() * 0.01, finalDamage);
				}
				if ( finalDamage < playerSlvCritDmg )
				{
					finalDamage = ClampF( finalDamage, playerSlvCritDmg, finalDamage );
				}
			}
			else if ( actorAttacker.IsWeaponHeld( 'staff2h' ) || weaponName == 'fists_lightning' || weaponName == 'fists_fire' || action.GetPowerStatType() == CPS_SpellPower )
			{
				if ( finalDamage > playerSlvDmg * 2 )
				{
					finalDamage = ClampF( finalDamage, 0, playerSlvDmg );
					finalDamage = MaxF(actorVictim.GetMaxHealth() * 0.01, finalDamage);
				}

				if ( finalDamage < playerFastSlvDmg && attackAction )
				{
					finalDamage = ClampF( finalDamage, playerFastSlvDmg, finalDamage );
				}
			}
			else if ( actorAttacker.IsWeaponHeld( 'silversword' ) || actorAttacker.HasAbility( 'SkillWitcher' ) || actorAttacker.HasBuff(EET_AxiiGuardMe) )
			{
				if ( finalDamage > playerSlvCritDmg )
				{
					finalDamage = ClampF( finalDamage, 0, playerSlvCritDmg );
					finalDamage = MaxF(actorVictim.GetMaxHealth() * 0.01, finalDamage);
				}
				if ( action.IsActionMelee() )
				{

					if ( finalDamage < playerSlvDmg && actorVictim.UsesEssence() )
					{
						finalDamage = ClampF( finalDamage, playerSlvDmg, finalDamage );
					}
					else if ( finalDamage < playerStlDmg )
					{
						finalDamage = ClampF( finalDamage, playerStlDmg, finalDamage );
					}
				}
			}
			else
			{
				finalDamage = ClampF( finalDamage, 0, playerStlDmg );
				finalDamage = MaxF(actorVictim.GetMaxHealth() * 0.01, finalDamage);
			}
		}


		if(thePlayer.GetBossTag() != '' || (W3MonsterHuntNPC)actorVictim || actorVictim.GetCharacterStats().HasAbilityWithTag('Boss') || actorVictim.HasAbility( 'Boss' ) || actorVictim.HasAbility( 'SkillBoss') )
		{
			finalDamage = ClampF(finalDamage, 0, actorVictim.GetMaxHealth() * 0.005);
		}
	}
	if( false && actorAttacker.HasBuff(EET_AxiiGuardMe))	//modSigns: 5.x's Puppet multipliers off: legacy's ally rule sets puppets' damage (DMG-12)
	{
		switch(GetWitcherPlayer().GetSkillLevel(S_Magic_s05))
		{
			case 3:
				finalDamage *= 1.6;
				break;
			case 2:
				finalDamage *= 1.4;
				break;
			case 1:
				finalDamage *= 1.2;
				break;
		}

		if ( thePlayer.CanUseSkill( S_Magic_s31 ) )
		{
			finalDamage *= 1 + thePlayer.GetSkillLevel( S_Magic_s31 ) * CalculateAttributeValue( thePlayer.GetSkillAttributeValue( S_Magic_s31, 'attack_power', false, true ) );
		}
	}



	if(dmgInfo.dmgType == theGame.params.DAMAGE_NAME_FIRE && finalDamage > 0)
		action.SetDealtFireDamage(true);

	//modSigns: no fist damage bonus by Geralt's level

	//modSigns: no x1.833 for the player's heavy attacks: Strong Attack adds +50% weapon damage to the pool instead (DMG-04)


	//modSigns: no per-monster Igni weakness (igni_damage_amplifier): weaknesses are resistances




	if ( theGame.CanLog() )
	{
		LogDMHits("Single hit damage: initial damage = " + NoTrailZeros(dmgInfo.dmgVal), action);
		LogDMHits("Single hit damage: attack_power = base: " + NoTrailZeros(powerMod.valueBase) + ", mult: " + NoTrailZeros(powerMod.valueMultiplicative) + ", add: " + NoTrailZeros(powerMod.valueAdditive), action );
		if(action.IsPointResistIgnored())
			LogDMHits("Single hit damage: resistance pts and armor = IGNORED", action);
		else
			LogDMHits("Single hit damage: resistance pts and armor = " + NoTrailZeros(resistPoints), action);
		LogDMHits("Single hit damage: resistance perc = " + NoTrailZeros(resistPercents * 100), action);
		LogDMHits("Single hit damage: final damage to sustain = " + NoTrailZeros(finalDamage), action);
	}


	if( playerVictim && actorAttacker && FactsQuerySum("NewGamePlus") > 0)
		finalDamage *= 1.1;


	return finalDamage;
}


// DMG-03: attack power. No attack power (x1) for damage over time and in fistfight minigames;
// headshots and backstabs +25%; signs keep their full intensity (5.x reduces Igni's and Aard's
// projectiles); no additive attack power for bolts; nothing negative; vanilla's crit chance added to
// crit damage removed; no heavy attack penalty; 5.x's damage boosts for weak allies off (DMG-12). Legacy GetAttackersPowerMod; the other areas' terms stay 5.x's until ported.
@replaceMethod(W3DamageManagerProcessor)
function GetAttackersPowerMod() : SAbilityAttributeValue
{
	var powerMod, criticalDamageBonus, min, max, critReduction, sp : SAbilityAttributeValue;
	var mutagen : CBaseGameplayEffect;
	var yrdenEnt : W3YrdenEntity;	//modSigns
	var totalBonus, tempBonus : float;


	var inv	: CInventoryComponent;
	var weaponName : name;



	if( thePlayer.IsFistFightMinigameEnabled() || gmWeaponsAreNotDeadly || action.IsDoTDamage() )	//modSigns: no attack power in fistfights, non-deadly fights (DMG-10) or for damage over time
	{	//modSigns
		powerMod.valueBase = 0;	//modSigns
		powerMod.valueMultiplicative = 1;	//modSigns
		powerMod.valueAdditive = 0;	//modSigns
		return powerMod;	//modSigns
	}	//modSigns

	powerMod = action.GetPowerStatValue();
	if ( powerMod.valueAdditive == 0 && powerMod.valueBase == 0 && powerMod.valueMultiplicative == 0 && theGame.CanLog() )
		LogDMHits("Attacker has power stat of 0!", action);

	// SKL-10: the Yrden turret's shots use the sign intensity cached at the cast, so a Flood of Anger cast
	// keeps its bonus after the cast's temporary skills are gone (legacy; skills/yrden.ws)
	if( (W3PlayerWitcher)playerAttacker && action.IsActionWitcherSign() && StrContains(action.GetBuffSourceName(), "_sign_yrden_alt") )	//modSigns
	{	//modSigns
		yrdenEnt = (W3YrdenEntity)((W3PlayerWitcher)playerAttacker).GetSignEntity(ST_Yrden);	//modSigns
		if( yrdenEnt )	//modSigns
		{	//modSigns
			sp = yrdenEnt.GMGetYrdenPower();	//modSigns
			if( !( sp.valueAdditive == 0 && sp.valueBase == 0 && sp.valueMultiplicative == 0 ) )	//modSigns
				powerMod = sp;	//modSigns
		}	//modSigns
	}	//modSigns


	//modSigns: no attack power penalty for heavy attacks (5.x -0.433, 1.32 -0.833)


	//modSigns: Igni's projectile keeps its full sign intensity


	//modSigns: Aard's projectile keeps its full sign intensity


	//modSigns: removed Lightning Reflexes' headshot damage (new tree sword_s32, SKL-06)



	inv = actorAttacker.GetInventory();
	weaponName = inv.GetItemName( weaponId );

	if( false && !playerAttacker && actorVictim && !thePlayer.IsInFistFightMiniGame() && GetAttitudeBetween( thePlayer, actorAttacker ) == AIA_Friendly && !actorAttacker.HasTag( 'keira' ) && !actorAttacker.HasTag( 'Yennefer' )	//modSigns: no damage boost abilities for weak allies (DMG-12)
		&& ( actorAttacker.IsWeaponHeld( 'silversword' ) || actorAttacker.IsWeaponHeld( 'staff2h' ) || weaponName == 'fists_lightning' || weaponName == 'fists_fire' || actorAttacker.HasAbility( 'SkillWitcher' ) || actorAttacker.HasTag( 'regis' )  || actorAttacker.HasBuff(EET_AxiiGuardMe) ) )
	{
		if ( powerMod.valueMultiplicative <= 0.1 )
		{
			actorAttacker.AddAbility( 'FCR3HighDamageBoost' );
			actorAttacker.AddAbility( 'FCR3LowDamageBoost');
		}
		else if ( powerMod.valueMultiplicative <= 0.4 )
		{
			actorAttacker.AddAbility( 'FCR3MedDamageBoost' );
			actorAttacker.AddAbility( 'FCR3LowDamageBoost' );
		}
		else if ( powerMod.valueMultiplicative <= 0.9 )
		{
			actorAttacker.AddAbility( 'FCR3MedDamageBoost' );
		}
		else if ( powerMod.valueMultiplicative <= 1.1 )
		{
			actorAttacker.AddAbility( 'FCR3LowDamageBoost' );
		}
	}



	if(action.GetIsHeadShot())	//modSigns: headshots +25% attack power (GEN)
		powerMod.valueMultiplicative += GMHeadShotDamageBonus();	//modSigns
	if(actorVictim && actorAttacker && actorVictim.IsAttackerAtBack(actorAttacker))	//modSigns: backstabs +25% attack power (GEN)
		powerMod.valueMultiplicative += GMBackAttackDamageBonus();	//modSigns
	if((W3PlayerWitcher)playerAttacker && attackAction)	//modSigns: SKL-04, the new tree's Strength Training's attack power (D54)
		powerMod.valueMultiplicative += ((W3PlayerWitcher)playerAttacker).GMStrengthTrainingPowerFor(attackAction) + ((W3PlayerWitcher)playerAttacker).GMMuscleMemoryPowerFor(attackAction);	//modSigns: and Muscle Memory's (SKL-03, D53)
	if((W3PlayerWitcher)playerAttacker && ((W3PlayerWitcher)playerAttacker).GMIsWhirlingWithAdrenaline())	//modSigns: SKL-03, Whirl's attack power per extra enemy
		powerMod.valueMultiplicative += ((W3PlayerWitcher)playerAttacker).GMGetWhirlDamageBonus();	//modSigns

	if(action.IsCriticalHit())
	{

		if( playerAttacker && action.IsActionWitcherSign() && GetWitcherPlayer().IsMutationActive(EPMT_Mutation2) )
		{
			//modSigns: removed the sign's own power stat: powerMod is set (legacy)

			theGame.GetDefinitionsManager().GetAbilityAttributeValue('Mutation2', 'crit_damage_factor', min, max);
			criticalDamageBonus.valueAdditive = min.valueAdditive + GMSignPowerStatToPowerBonus(powerMod.valueMultiplicative) * min.valueMultiplicative;	//modSigns: MUT-03, legacy's formula (intensity to power bonus)
		}
		else
		{
			criticalDamageBonus = actorAttacker.GetCriticalHitDamageBonus(weaponId, victimMonsterCategory, actorVictim.IsAttackerAtBack(playerAttacker));

			//modSigns: vanilla added critical_hit_chance_fast_style (a crit chance) to the crit damage

			if(attackAction && playerAttacker && attackAction.IsActionMelee())	//modSigns: SKL-03, SKL-04: melee only (5.x gave bolt crits Precise Blows' crit damage)
			{
				if(playerAttacker.IsHeavyAttack(attackAction.GetAttackName()) && playerAttacker.CanUseSkill(S_Sword_s08))
					criticalDamageBonus += playerAttacker.GetSkillAttributeValue(S_Sword_s08, theGame.params.CRITICAL_HIT_DAMAGE_BONUS, false, true) * playerAttacker.GetSkillLevel(S_Sword_s08);
				else if (!playerAttacker.IsHeavyAttack(attackAction.GetAttackName()) && playerAttacker.CanUseSkill(S_Sword_s17))
					criticalDamageBonus += playerAttacker.GetSkillAttributeValue(S_Sword_s17, theGame.params.CRITICAL_HIT_DAMAGE_BONUS, false, true) * playerAttacker.GetSkillLevel(S_Sword_s17);
				if((W3PlayerWitcher)playerAttacker)	//modSigns: the new tree's Crushing Blows and Precise Blows (D55, D57): their crit damage, then the crit starts their chain
				{	//modSigns
					criticalDamageBonus.valueAdditive += ((W3PlayerWitcher)playerAttacker).GMBlowsCritDamage(playerAttacker.IsHeavyAttack(attackAction.GetAttackName()));	//modSigns
					((W3PlayerWitcher)playerAttacker).GMBlowsOnCrit(playerAttacker.IsHeavyAttack(attackAction.GetAttackName()));	//modSigns
					criticalDamageBonus.valueAdditive += ((W3PlayerWitcher)playerAttacker).GMWolfSchoolCritDamage(actorVictim, weaponId, victimMonsterCategory);	//modSigns: SKL-18, Wolf School (D61)
				}	//modSigns
			}	//modSigns
			if((W3PlayerWitcher)playerAttacker && (W3BoltProjectile)action.causer)	//modSigns: SKL-06, Anatomical Knowledge's crossbow crit damage (legacy)
				criticalDamageBonus += ((W3PlayerWitcher)playerAttacker).GMAnatomicalKnowledgeCritDamage();	//modSigns
		}


		//modSigns: removed 5.x's new-tree Hunter Instinct at full adrenaline (SKL-14: legacy's rule for both trees in W3PlayerWitcher.GetCriticalHitDamageBonus)


		totalBonus = CalculateAttributeValue(criticalDamageBonus);
		critReduction = actorVictim.GetAttributeValue(theGame.params.CRITICAL_HIT_REDUCTION);
		totalBonus = totalBonus * ClampF(1 - critReduction.valueMultiplicative, 0.f, 1.f);


		powerMod.valueMultiplicative += totalBonus;
	}


	if (actorVictim && playerAttacker)
	{
		if ( playerAttacker.HasBuff(EET_Mutagen05) && (playerAttacker.GetStat(BCS_Vitality) == playerAttacker.GetStatMax(BCS_Vitality)) )
		{
			mutagen = playerAttacker.GetBuff(EET_Mutagen05);
			dm.GetAbilityAttributeValue(mutagen.GetAbilityName(), 'damageIncrease', min, max);
			powerMod += GetAttributeRandomizedValue(min, max);
		}
	}

	if( (W3PlayerWitcher)playerAttacker && action.IsActionRanged() && (W3BoltProjectile)action.causer )	//modSigns: no additive attack power for bolts
		powerMod.valueAdditive = 0;	//modSigns

	powerMod.valueBase = MaxF(powerMod.valueBase, 0);	//modSigns: no negative attack power
	powerMod.valueMultiplicative = MaxF(powerMod.valueMultiplicative, 0);	//modSigns
	powerMod.valueAdditive = MaxF(powerMod.valueAdditive, 0);	//modSigns

	return powerMod;
}

