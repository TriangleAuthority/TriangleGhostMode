// W3PlayerWitcher.OnCombatStart, replaced for the mutations' combat-start rules (and ENCH-15's Protection): MUT-05 Bloodbath's
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

	
	//modSigns: removed 1.32's Succubus attack power timer (ALCH-11: legacy's Succubus strengthens Axii puppets)

	
	//modSigns: removed 1.32's Alghoul ability at combat start (ALCH-10: legacy's Alghoul builds up on melee hits)

	
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

	if ( HasGlyphwordActive('Glyphword 17 _Stats') && !IsAnyQuenActive() )	//modSigns: ENCH-15, Protection: always, only without a Quen up (legacy)
	{
		//modSigns: removed the stamina read (the Quen is free)
		glyphQuen = (W3QuenEntity)theGame.CreateEntity( signs[ST_Quen].template, GetWorldPosition(), GetWorldRotation() );
		glyphQuen.GMSetGlyphword17Cast();	//modSigns: +100% intensity (legacy)
		glyphQuen.Init( signOwner, signs[ST_Quen].entity, true );
		glyphQuen.freeFromBearSetBonus = true;	//modSigns: free, as legacy's freeCast (no stamina, adrenaline or cooldown)
		glyphQuen.OnStarted();
		glyphQuen.OnThrowing();
		glyphQuen.OnEnded();
		//modSigns: removed the stamina restore
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

