// AI-20: fistfights (docs/features/ai.md). Fistfight opponents get no level-difference abilities and no New
// Game+ level cut (5.x removes NG+ levels' NPCLevelBonus at the fight's start; AI-01 adds the NG+ level to the
// real level instead); an opponent carrying several tier abilities (SkillFists*, StatsFists*) keeps only the
// lowest (legacy's fix of NPCs with duplicate tiers), and the sergeant's ability mix of old saves is cleaned
// up. Each tier adds flat fist damage (fist_dmg_bonus, the tiers' abilities: easy +50, medium +100, hard +150,
// the Baron -100), a flat addition before DMG-04's pool, to bludgeoning. Geralt's maximum Vitality is not
// clamped to 2,000 for the fight. The tiers' and quest fights' abilities are legacy's whole (gen_ai.py).

// 5.x body; changes marked //modSigns.
@replaceMethod(CNewNPC)
function OnStartFistfightMinigame()
{
	super.OnStartFistfightMinigame();

	thePlayer.ProcessLockTarget( this );
	SignalGameplayEventParamInt('ChangePreferedCombatStyle',(int)EBG_Combat_Fists );
	SetTemporaryAttitudeGroup( 'fistfight_opponent', AGP_Fistfight );
	ForceVulnerableImmortalityMode();
	if ( !thePlayer.IsFistFightMinigameToTheDeath() )
		SetImmortalityMode(AIM_Unconscious, AIC_Fistfight);
	//modSigns: removed the New Game+ level cut (FistFightNewGamePlusSetup)
	GMValidateFistfighterAbilities();	//modSigns: one tier only
	FistFightHealthSetup();
	RemoveFistFightLevelDiff();	//modSigns: no level-difference abilities

}

// 5.x body; changes marked //modSigns.
@replaceMethod(CNewNPC)
function RemoveFistFightLevelDiff()
{
	RemoveAbilityAll(theGame.params.ENEMY_BONUS_FISTFIGHT_LOW);	//modSigns: every one (5.x: 5)
	RemoveAbilityAll(theGame.params.ENEMY_BONUS_FISTFIGHT_HIGH);	//modSigns: every one (5.x: 5)
}

// Legacy's ValidateFistfighterAbilities: an opponent with several tiers keeps the lowest; the sergeant of old
// saves loses the mixed-up SkillBrigand and NPCDoNotGainBoost (and gets his level back).
@addMethod(CNewNPC)
function GMValidateFistfighterAbilities()
{
	if( HasAbility( 'SkillFistsEasy' ) )
	{
		RemoveAbilityAll( 'SkillFistsMedium' );
		RemoveAbilityAll( 'SkillFistsHard' );
	}
	else if( HasAbility( 'SkillFistsMedium' ) )
	{
		RemoveAbilityAll( 'SkillFistsHard' );
	}

	if( HasAbility( 'StatsFistsTutorial' ) )
	{
		RemoveAbilityAll( 'StatsFistsEasy' );
		RemoveAbilityAll( 'StatsFistsMedium' );
		RemoveAbilityAll( 'StatsFistsHard' );
	}
	else if( HasAbility( 'StatsFistsEasy' ) )
	{
		RemoveAbilityAll( 'StatsFistsMedium' );
		RemoveAbilityAll( 'StatsFistsHard' );
	}
	else if( HasAbility( 'StatsFistsMedium' ) )
	{
		RemoveAbilityAll( 'StatsFistsHard' );
	}
	if( HasAbility( 'qSergeantFistFIght' ) )
	{
		if( HasAbility( 'SkillBrigand' ) && HasAbility( 'SkillOfficer' ) )
			RemoveAbilityAll( 'SkillBrigand' );
		if( HasAbility( 'NPCDoNotGainBoost' ) )
		{
			RemoveAbilityAll( 'NPCDoNotGainBoost' );
			GMResetLevel();
		}
	}
}

// 5.x body; changes marked //modSigns.
@replaceMethod(CR4Player)
function FistFightHealthChange( val : bool )
{
	if( val == true )
	{
		//modSigns: removed the clamp of Geralt's maximum Vitality to 2,000 (and the saved maximum)
		SetHealthPerc( 100 );
	}
	else
	{
		//modSigns: removed the restore of the saved maximum Vitality
		SetHealthPerc( 100 );
	}

}

// The fist damage bonus (legacy's first flat addition in ProcessDamageIncrease, before the pool): a melee hit
// of an attacker holding fists gets its fist_dmg_bonus added to its bludgeoning damage, or as bludgeoning
// damage if it has none.
@addMethod(W3DamageManagerProcessor)
function GMAddFistDamageBonus(out dmgInfos : array< SRawDamage >)
{
	var i, idx : int;
	var bonus : float;
	var dmg : SRawDamage;

	if( !actorAttacker || !attackAction || !attackAction.IsActionMelee() || !actorAttacker.IsWeaponHeld( 'fist' ) )
		return;
	bonus = CalculateAttributeValue(actorAttacker.GetAttributeValue( 'fist_dmg_bonus' ));
	idx = -1;
	for( i = 0; i < dmgInfos.Size(); i += 1 )
	{
		if( dmgInfos[i].dmgType == theGame.params.DAMAGE_NAME_BLUDGEONING )
		{
			dmgInfos[i].dmgVal += bonus;
			idx = i;
		}
	}
	if( idx == -1 )
	{
		dmg.dmgVal = bonus;
		dmg.dmgType = theGame.params.DAMAGE_NAME_BLUDGEONING;
		dmgInfos.PushBack( dmg );
	}
}
