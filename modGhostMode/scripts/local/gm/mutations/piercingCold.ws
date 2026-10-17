// MUT-04 Piercing Cold (Mutation 6), as legacy (DM2, DM3): Aard freezes a hostile with a chance of
// 30% x (1 - its frost resistance), not in mid-air and not if immune to instant kills; frozen and
// knocked down, it dies (no boss exclusion); otherwise, not frozen, it takes 250 force damage scaled
// by sign intensity in a separate action, with a new knockdown roll. Shock Wave's damage stays in the
// Aard hit itself (SKL-08). Replaces 5.x's adrenaline-based chance, its frost slowdown, the Wild Hunt
// generals' exclusion, its Shock Wave in this path and its frost hit (OnFrostHit).
// A Flood of Anger Aard is a normal Aard with raised intensity (no supercharged rule).
// See docs/features/mut.md.

@replaceMethod(W3AardProjectile)
function ProcessCollision( collider : CGameplayEntity, pos, normal : Vector )
{
	var dmgVal : float;
	var sp : SAbilityAttributeValue;
	var isMutation6 : bool;
	var victimNPC : CNewNPC;
	var aardDRTier : int;



	if ( hitEntities.FindFirst( collider ) != -1 )
	{
		return;
	}


	hitEntities.PushBack( collider );

	super.ProcessCollision( collider, pos, normal );

	victimNPC = (CNewNPC) collider;

	aardDRTier = 1;

	if( owner.IsPlayer() && victimNPC )
	{
		aardDRTier = victimNPC.SignDRRegisterAard();
	}



	if( IsRequiredAttitudeBetween(victimNPC, caster, true ) )
	{
		isMutation6 = ( ( W3PlayerWitcher )owner.GetPlayer() && GetWitcherPlayer().IsMutationActive( EPMT_Mutation6 ) );
		//modSigns: MUT-04, the Aard hit stays a normal hit under Piercing Cold (legacy: no "Mutation6" source)
		if ( owner.CanUseSkill( S_Magic_s33 ) )	//modSigns: also with Piercing Cold (legacy: Shock Wave in the Aard hit)
		{
			action.AddDamage( theGame.params.DAMAGE_NAME_DIRECT, GetWitcherPlayer().CalcMagic33Damage() );
		}
	}
	else
	{
		isMutation6 = false;
	}

	action.SetHitAnimationPlayType(EAHA_ForceNo);
	action.SetProcessBuffsIfNoDamage(true);


	if ( !owner.IsPlayer() )
	{
		action.AddEffectInfo( EET_KnockdownTypeApplicator );
	}






	if( owner.IsPlayer() && victimNPC )
	{
		if( aardDRTier == 2 )
		{
			action.RemoveBuffsByType( EET_KnockdownTypeApplicator );
			action.RemoveBuffsByType( EET_Knockdown );
			action.RemoveBuffsByType( EET_HeavyKnockdown );
			action.RemoveBuffsByType( EET_LongStagger );
			action.RemoveBuffsByType( EET_Stagger );
			action.RemoveBuffsByType( EET_Ragdoll );

			action.AddEffectInfo( EET_LongStagger );
		}
		else if( aardDRTier == 3 )
		{
			action.RemoveBuffsByType( EET_KnockdownTypeApplicator );
			action.RemoveBuffsByType( EET_Knockdown );
			action.RemoveBuffsByType( EET_HeavyKnockdown );
			action.RemoveBuffsByType( EET_LongStagger );
			action.RemoveBuffsByType( EET_Stagger );
			action.RemoveBuffsByType( EET_Ragdoll );

			action.AddEffectInfo( EET_Stagger );
		}
		else if( aardDRTier >= 4 )
		{
			action.RemoveBuffsByType( EET_KnockdownTypeApplicator );
			action.RemoveBuffsByType( EET_Knockdown );
			action.RemoveBuffsByType( EET_HeavyKnockdown );
			action.RemoveBuffsByType( EET_LongStagger );
			action.RemoveBuffsByType( EET_Stagger );
			action.RemoveBuffsByType( EET_Ragdoll );

			action.SetHitReactionType( EHRT_None, false );
			action.SetHitAnimationPlayType( EAHA_ForceNo );
		}
	}


	theGame.damageMgr.ProcessAction( action );

	//modSigns: MUT-04, removed 5.x's frost hit with Piercing Cold (CheckFrostEffect; legacy has none)

	collider.OnAardHit( this );



	if( isMutation6 && victimNPC && victimNPC.IsAlive() )
	{
		ProcessMutation6( victimNPC );
	}
}

@replaceMethod(W3AardProjectile)
function ProcessMutation6( victimNPC : CNewNPC )
{
	var result : EEffectInteract;
	var mutationAction : W3DamageAction;
	var min, max : SAbilityAttributeValue;
	//modSigns: removed sp (5.x's Shock Wave in this path)
	var dmgVal : float;
	var instaKill, hasKnockdown : bool;	//modSigns: no slowdown branch
	var freezingChance, pts, prc : float;	//modSigns

	instaKill = false;
	hasKnockdown = victimNPC.HasBuff( EET_Knockdown ) || victimNPC.HasBuff( EET_HeavyKnockdown ) || victimNPC.GetIsRecoveringFromKnockdown();

	theGame.GetDefinitionsManager().GetAbilityAttributeValue( 'Mutation6', 'full_freeze_chance', min, max );	//modSigns: legacy's chance: 30% x (1 - frost resistance)
	victimNPC.GetResistValue( CDS_FrostRes, pts, prc );	//modSigns
	freezingChance = ClampF( min.valueMultiplicative * ( 1 - prc ), 0.0, 1.0 );	//modSigns

	result = EI_Deny;	//modSigns
	if( RandF() < freezingChance && !victimNPC.IsInAir() && !victimNPC.IsImmuneToInstantKill() )	//modSigns: not in mid-air (5.x: adrenaline x 10%, no freeze with a supercharged Aard)
	{
		result = victimNPC.AddEffectDefault( EET_Frozen, this, "Mutation 6", true );
	}

	if( EffectInteractionSuccessfull( result ) && hasKnockdown )	//modSigns: no exclusion of Eredin, Imlerith and Caranthir (DM2)
	{
		mutationAction = new W3DamageAction in theGame.damageMgr;
		mutationAction.Initialize( action.attacker, victimNPC, this, "Mutation 6", EHRT_None, CPS_Undefined, false, false, true, false );
		mutationAction.SetInstantKill();
		mutationAction.SetForceExplosionDismemberment();
		mutationAction.SetIgnoreInstantKillCooldown();
		theGame.damageMgr.ProcessAction( mutationAction );
		delete mutationAction;
		instaKill = true;
	}

	//modSigns: removed 5.x's frost slowdown and its Shock Wave in this path (Shock Wave is in the Aard hit, SKL-08)

	if( !instaKill && !victimNPC.HasBuff( EET_Frozen ) )	//modSigns: not frozen: force damage in its own action, scaled by sign intensity
	{
		victimNPC.RemoveAllBuffsOfType( EET_Stagger );	//modSigns: the Aard hit's own reaction is replaced by the new knockdown roll
		victimNPC.RemoveAllBuffsOfType( EET_LongStagger );	//modSigns
		victimNPC.RemoveAllBuffsOfType( EET_Knockdown );	//modSigns
		victimNPC.RemoveAllBuffsOfType( EET_HeavyKnockdown );	//modSigns

		mutationAction = new W3DamageAction in theGame.damageMgr;	//modSigns
		mutationAction.Initialize( action.attacker, victimNPC, this, "Mutation 6", EHRT_None, CPS_SpellPower, false, false, true, false );	//modSigns
		theGame.GetDefinitionsManager().GetAbilityAttributeValue( 'Mutation6', 'ForceDamage', min, max );
		dmgVal = CalculateAttributeValue( min );
		mutationAction.AddDamage( theGame.params.DAMAGE_NAME_FORCE, dmgVal );	//modSigns
		mutationAction.ClearEffects();	//modSigns
		mutationAction.SetProcessBuffsIfNoDamage( true );	//modSigns
		mutationAction.SetForceExplosionDismemberment();	//modSigns
		mutationAction.SetIgnoreInstantKillCooldown();	//modSigns
		mutationAction.SetBuffSourceName( "Mutation 6" );	//modSigns
		mutationAction.AddEffectInfo( EET_KnockdownTypeApplicator );	//modSigns: a new knockdown roll
		theGame.damageMgr.ProcessAction( mutationAction );	//modSigns
		delete mutationAction;	//modSigns
	}
}
