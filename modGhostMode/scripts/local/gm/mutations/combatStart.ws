// W3PlayerWitcher.OnCombatStart, replaced for the mutations' combat-start rules: MUT-05 Bloodbath's
// bonus starts; MUT-09 Euphoria starts only when overdosed; MUT-10 Mutated Skin has no buff. (MUT-07's Adrenaline Rush start is a wrapper in adrenalineRush.ws.)
// See docs/features/mut.md.

@replaceMethod(W3PlayerWitcher)
function OnCombatStart()
{
	var quenEntity, glyphQuen : W3QuenEntity;
	var focus, stamina : float;
	var glowTargets, moTargets, actors : array< CActor >;
	var delays : array< float >;
	var rand, i : int;
	var isHostile, isAlive, isUnconscious : bool;

	super.OnCombatStart();

	if ( IsInCombatActionFriendly() )
	{
		SetBIsCombatActionAllowed(true);
		SetBIsInputAllowed(true, 'OnCombatActionStart' );
	}

	
	if(HasBuff(EET_Mutagen14))
	{
		AddTimer('Mutagen14Timer', 2, true);
	}

	
	if(HasBuff(EET_Mutagen15))
	{
		AddAbility(GetBuff(EET_Mutagen15).GetAbilityName(), false);
	}

	
	mutation12IsOnCooldown = false;

	
	quenEntity = (W3QuenEntity)signs[ST_Quen].entity;

	
	if(quenEntity)
	{
		usedQuenInCombat = quenEntity.IsAnyQuenActive();
	}
	else
	{
		usedQuenInCombat = false;
	}

	if(usedQuenInCombat || HasPotionBuff() || IsEquippedSwordUpgradedWithOil(true) || IsEquippedSwordUpgradedWithOil(false))
	{
		SetFailedFundamentalsFirstAchievementCondition(true);
	}
	else
	{
		if(IsAnyItemEquippedOnSlot(EES_PotionMutagen1) || IsAnyItemEquippedOnSlot(EES_PotionMutagen2) || IsAnyItemEquippedOnSlot(EES_PotionMutagen3) || IsAnyItemEquippedOnSlot(EES_PotionMutagen4))
			SetFailedFundamentalsFirstAchievementCondition(true);
		else
			SetFailedFundamentalsFirstAchievementCondition(false);
	}

	if(CanUseSkill(S_Sword_s20) && IsThreatened())
	{
		focus = GetStat(BCS_Focus);
		if(focus < 1)
		{
			GainStat(BCS_Focus, 1 - focus);
		}
	}

	if ( HasAbility('Glyphword 17 _Stats', true) && RandF() < CalculateAttributeValue(GetAttributeValue('quen_apply_chance')) )
	{
		stamina = GetStat(BCS_Stamina);
		glyphQuen = (W3QuenEntity)theGame.CreateEntity( signs[ST_Quen].template, GetWorldPosition(), GetWorldRotation() );
		glyphQuen.Init( signOwner, signs[ST_Quen].entity, true );
		glyphQuen.OnStarted();
		glyphQuen.OnThrowing();
		glyphQuen.OnEnded();
		ForceSetStat(BCS_Stamina, stamina);
	}

	
	MeditationForceAbort(true);

	
	

	
	if( IsMutationActive( EPMT_Mutation3 ) )	//modSigns: MUT-05, Bloodbath's bonus for the equipped skills
	{	//modSigns
		AddEffectDefault( EET_Mutation3, this, "", false );	//modSigns
	}	//modSigns
	else if( IsMutationActive( EPMT_Mutation4 ) )	//modSigns
	{
		AddEffectDefault( EET_Mutation4, this, "combat start", false );
	}
	//modSigns: removed Mutated Skin's buff at combat start (MUT-10)
	
	else if( IsMutationActive( EPMT_Mutation7 ) )
	{
		
			
			RemoveTimer( 'Mutation7CombatStartHackFixGo' );

			
			AddTimer( 'Mutation7CombatStartHackFix', 1.f, true, , , , true );
		
	}
	else if( IsMutationActive( EPMT_Mutation8 ) )
	{
		theGame.MutationHUDFeedback( MFT_PlayRepeat );
	}
	
	else if( IsMutationActive( EPMT_Mutation10 ) )
	{
		if( !HasBuff( EET_Mutation10 ) && GetStatPercents( BCS_Toxicity ) >= GetToxicityDamageThreshold() )	//modSigns: MUT-09, only when overdosed
		{
			AddEffectDefault( EET_Mutation10, this, "Mutation 10" );
		}
		//modSigns: removed the FX without the effect (MUT-09: played when the effect starts)
	}
}

