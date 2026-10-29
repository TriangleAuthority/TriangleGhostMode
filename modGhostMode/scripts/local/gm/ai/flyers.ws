// AI-13 (flyers forced to land): a flying enemy is knocked out of the air (the knockdown applicator, also when
// the hit deals no damage) by any damaging hit that is not damage over time, by any bolt, by Yrden's shock
// (the alternate Yrden's turret) and by burning (Igni's, a bomb's or a rune's: the burning effect's ticks);
// 5.x (as 1.32) needed a hit taking a set share of its health (healthLossToForceLand_perc) and never counted
// damage over time. The Yrden trap's own grounding of flyers (W3YrdenEntity, BlockAbility 'Flying') is 5.x's,
// unchanged. See docs/features/ai.md.

// The causes that force a flyer to land (legacy's rule in CNewNPC.ReactToBeingHit).
function GMFlyerForcedToLand( damageAction : W3DamageAction ) : bool
{
	return ( damageAction.DealsAnyDamage() && !damageAction.IsDoTDamage() )
		|| (W3ArrowProjectile)damageAction.causer
		|| (W3YrdenEntityStateYrdenShock)damageAction.causer
		|| (W3Effect_Burning)damageAction.causer;
}

// 5.x body (its hit reaction aimed at a targeted part, its bomb signal kept); changes marked //modSigns.
// SKL-12: legacy also removed the Puppet's freeing here (5.x: any hit of Geralt's frees it below Puppet's
// level 3); SKL-12's rule frees it on Geralt's damaging hits (W3DamageManagerProcessor.ProcessActionReaction).
@replaceMethod(CNewNPC)
function ReactToBeingHit(damageAction : W3DamageAction, optional buffNotApplied : bool) : bool
{
	var ret 							: bool;
	var percentageLoss					: float;
	var totalHealth						: float;
	var damaveValue						: float;
	var healthLossToForceLand_perc		: SAbilityAttributeValue;
	var witcher							: W3PlayerWitcher;
	var node							: CNode;
	var boltCauser						: W3ArrowProjectile;
	var yrdenCauser 					: W3YrdenEntityStateYrdenShock;
	var bombCauser						: W3Petard;
	var attackAction					: W3Action_Attack;

	damaveValue 				 = damageAction.GetDamageDealt();
	totalHealth 				 = GetMaxHealth();
	percentageLoss 			 	= damaveValue / totalHealth;
	healthLossToForceLand_perc 	 = GetAttributeValue( 'healthLossToForceLand_perc' );


	//modSigns: removed the forced landing by the share of health a hit takes (AI-13: GMFlyerForcedToLand)
	if( IsFlying() && GMFlyerForcedToLand( damageAction ) )	//modSigns: AI-13
	{	//modSigns
		damageAction.AddEffectInfo( EET_KnockdownTypeApplicator );	//modSigns
		damageAction.SetProcessBuffsIfNoDamage( true );	//modSigns
	}	//modSigns


	boltCauser = (W3ArrowProjectile)( damageAction.causer );
	yrdenCauser = (W3YrdenEntityStateYrdenShock)( damageAction.causer );
	if( boltCauser || yrdenCauser )
	{
		if( HasAbility( 'AdditiveHits' ) )
		{
			SetUseAdditiveHit( true, GetCriticalCancelAdditiveHit(), true );
			ret = super.ReactToBeingHit(damageAction, buffNotApplied);

			if( ret || damageAction.DealsAnyDamage())
				SignalGameplayDamageEvent('BeingHit', damageAction );
		}
		else if( HasAbility( 'mon_wild_hunt_default' ) )
		{
			ret = false;
		}
		else if( !boltCauser.HasTag( 'bodkinbolt' ) || this.IsUsingHorse() || RandRange(100) < 75.f )
		{
			ret = super.ReactToBeingHit(damageAction, buffNotApplied);

			if( ret || damageAction.DealsAnyDamage())
				SignalGameplayDamageEvent('BeingHit', damageAction );
		}
		else
		{
			ret = false;
		}
	}
	else
	{
		ret = super.ReactToBeingHit(damageAction, buffNotApplied);

		if( ret || damageAction.DealsAnyDamage() )
			SignalGameplayDamageEvent('BeingHit', damageAction );
	}

	bombCauser = (W3Petard)( damageAction.causer );
	if ( bombCauser )
	{
		SignalGameplayDamageEvent('BombHit', damageAction );
	}

	if( damageAction.additiveHitReactionAnimRequested == true )
	{
		SetHitReaction( damageAction );
	}

	if(((CPlayer)damageAction.attacker || !((CNewNPC)damageAction.attacker)) && damageAction.DealsAnyDamage())
		theTelemetry.LogWithLabelAndValue( TE_FIGHT_ENEMY_GETS_HIT, damageAction.victim.ToString(), (int)damageAction.processedDmg.vitalityDamage + (int)damageAction.processedDmg.essenceDamage );


	witcher = GetWitcherPlayer();
	//modSigns: removed the Puppet's freeing by Geralt's hits (SKL-12's rule frees it on his damaging hits, as legacy)

	if(damageAction.attacker == thePlayer && damageAction.DealsAnyDamage() && !damageAction.IsDoTDamage())
	{
		attackAction = (W3Action_Attack) damageAction;



		if(SkillNameToEnum(attackAction.GetAttackTypeName()) == S_Sword_s02)



		if(attackAction && attackAction.UsedZeroStaminaPerk())
		{
			ForceSetStat(BCS_Stamina, 0.f);
		}
	}

	return ret;
}
