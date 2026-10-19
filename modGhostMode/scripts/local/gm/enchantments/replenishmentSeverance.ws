// ENCH-03 Replenishment (Runeword 1) and ENCH-04 Severance (Runeword 2) as legacy (changelist 962-963,
// 970-974), from the drawn sword (ENCH-01).
// - Replenishment: a sign cast with an adrenaline point charges the next sword hit with it; Axii's charge
//   confuses for 5 s, Yrden's slows for 5 s (data). 5.x calls OnSignCastPerformed when a channelled sign
//   (Firestream, active Quen) starts, legacy when it ended (deviation, recorded).
// - Severance: Whirl's and Rend's range (OnPreAttackEvent) and their final damage -33.4% while it is
//   active (damage/pipeline.ws, GMProcessDamageModification; legacy's code cut every Whirl and Rend hit,
//   the owner chose the changelist's rule: deviation, recorded).
// 5.x bodies; changes marked //modSigns. See docs/features/ench.md.

@replaceMethod(W3PlayerWitcher)
function OnSignCastPerformed(signType : ESignType, isAlternate : bool)
{
	var items : array<SItemUniqueId>;
	var weaponEnt : CEntity;
	var fxName : name;
	var pos : Vector;

	super.OnSignCastPerformed(signType, isAlternate);

	if(HasRunewordActive('Runeword 1 _Stats') && GetStat(BCS_Focus) >= 1.0f)	//modSigns: ENCH-01, from the drawn sword
	{
		DrainFocus(1.0f);
		runewordInfusionType = signType;
		items = inv.GetHeldWeapons();
		weaponEnt = inv.GetItemEntityUnsafe(items[0]);

		
		weaponEnt.StopEffect('runeword_aard');
		weaponEnt.StopEffect('runeword_axii');
		weaponEnt.StopEffect('runeword_igni');
		weaponEnt.StopEffect('runeword_quen');
		weaponEnt.StopEffect('runeword_yrden');

		
		if(signType == ST_Aard)
			fxName = 'runeword_aard';
		else if(signType == ST_Axii)
			fxName = 'runeword_axii';
		else if(signType == ST_Igni)
			fxName = 'runeword_igni';
		else if(signType == ST_Quen)
			fxName = 'runeword_quen';
		else if(signType == ST_Yrden)
			fxName = 'runeword_yrden';

		weaponEnt.PlayEffect(fxName);
	}

	
	if( IsMutationActive( EPMT_Mutation6 ) && signType == ST_Aard && !isAlternate )
	{
		pos = GetWorldPosition() + GetWorldForward() * 2;

		theGame.GetSurfacePostFX().AddSurfacePostFXGroup( pos, 0.f, 3.f, 2.f, 5.f, 0 );
	}
}

// A hit with the other sword drawn leaves a pending charge for the Replenishment sword (legacy: the
// runeword is inactive then; 5.x's OnProcessActionPost would spend the charge).
@wrapMethod(W3PlayerWitcher)
function OnProcessActionPost(action : W3DamageAction)
{
	var stash : ESignType;

	stash = ST_None;
	if(runewordInfusionType != ST_None && !HasRunewordActive('Runeword 1 _Stats'))
	{
		stash = runewordInfusionType;
		runewordInfusionType = ST_None;
	}
	wrappedMethod(action);
	if(stash != ST_None)
		runewordInfusionType = stash;
}

@replaceMethod(W3DamageManagerProcessor)
function ProcessPreHitModifications()
{
	var fireDamage, totalDmg, maxHealth, currHealth : float;
	var attribute, min, max : SAbilityAttributeValue;
	var infusion : ESignType;
	var hack : array< SIgniEffects >;
	var dmgValTemp : float;
	var igni : W3IgniEntity;
	var quen : W3QuenEntity;

	if( actorVictim.HasAbility( 'HitWindowOpened' ) && !action.IsDoTDamage() )
	{
		if( actorVictim.HasTag( 'fairytale_witch' ) )
		{
			
			
			
			
			
			
				((CNewNPC)actorVictim).SetBehaviorVariable( 'shouldBreakFlightLoop', 1.0 );
			
		}
		else
		{
			quen = (W3QuenEntity)action.causer; 
		
			if( !quen )
			{
				if( actorVictim.HasTag( 'dettlaff_vampire' ) )
				{
					actorVictim.StopEffect( 'shadowdash' );
				}
				
				action.ClearDamage();
				if( action.IsActionMelee() )
				{
					actorVictim.PlayEffect( 'special_attack_break' );
				}
				actorVictim.SetBehaviorVariable( 'repelType', 0 );
				
				actorVictim.AddEffectDefault( EET_CounterStrikeHit, thePlayer ); 
				action.RemoveBuffsByType( EET_KnockdownTypeApplicator );
			}
		}
		
		((CNewNPC)actorVictim).SetHitWindowOpened( false );
	}
	
	
	
	if(playerAttacker && attackAction && attackAction.IsActionMelee() && (W3PlayerWitcher)thePlayer && GetWitcherPlayer().HasRunewordActive('Runeword 1 _Stats'))	//modSigns: ENCH-01, from the drawn sword
	{
		infusion = GetWitcherPlayer().GetRunewordInfusionType();
		
		switch(infusion)
		{
			case ST_Aard:
				action.AddEffectInfo(EET_KnockdownTypeApplicator);
				action.SetProcessBuffsIfNoDamage(true);
				attackAction.SetApplyBuffsIfParried(true);
				actorVictim.CreateFXEntityAtPelvis( 'runeword_1_aard', false );
				break;
			case ST_Axii:
				attribute = thePlayer.GetAttributeValue('runeword1_confusion_duration');	//modSigns: ENCH-03, Replenishment's Axii: its own confusion duration (legacy)
				action.AddEffectInfo(EET_Confusion, attribute.valueAdditive);	//modSigns
				action.SetProcessBuffsIfNoDamage(true);
				attackAction.SetApplyBuffsIfParried(true);
				break;
			case ST_Igni:
				
				totalDmg = action.GetDamageValueTotal();
				attribute = thePlayer.GetAttributeValue('runeword1_fire_dmg');
				fireDamage = totalDmg * attribute.valueMultiplicative;
				action.AddDamage(theGame.params.DAMAGE_NAME_FIRE, fireDamage);
				
				
				action.SetCanPlayHitParticle(false);					
				action.victim.AddTimer('Runeword1DisableFireFX', 1.f);
				action.SetHitReactionType(EHRT_Heavy);	
				action.victim.PlayEffect('critical_burning');
				break;
			case ST_Yrden:
				attribute = thePlayer.GetAttributeValue('runeword1_yrden_duration');
				action.AddEffectInfo(EET_Slowdown, attribute.valueAdditive);
				action.SetProcessBuffsIfNoDamage(true);
				attackAction.SetApplyBuffsIfParried(true);
				break;
			default:		
				break;
		}
	}
	
	
	if( playerAttacker && actorVictim && (W3PlayerWitcher)playerAttacker && GetWitcherPlayer().IsMutationActive( EPMT_Mutation9 ) && (W3BoltProjectile)action.causer )
	{
		maxHealth = actorVictim.GetMaxHealth();
		currHealth = actorVictim.GetHealth();
		
		
		if( AbsF( maxHealth - currHealth ) < 1.f )
		{
			theGame.GetDefinitionsManager().GetAbilityAttributeValue('Mutation9', 'health_reduction', min, max);
			actorVictim.ForceSetStat( actorVictim.GetUsedHealthType(), maxHealth * ( 1 - min.valueMultiplicative ) );
		}
		
		
		action.AddEffectInfo( EET_KnockdownTypeApplicator, 0.1f, , , , 1.f );
	}
}

@replaceMethod(CR4PlayerStateCombat)
function OnPreAttackEvent(animEventName : name, animEventType : EAnimationEventType, data : CPreAttackEventData, animInfo : SAnimationEventAnimInfo )
{
	var res				: bool;
	var weaponEntity	: CItemEntity;
	var aerondight		: W3Effect_Aerondight;
	var weaponId		: SItemUniqueId;
	
	if((W3PlayerWitcher)parent && ((W3PlayerWitcher)parent).HasRunewordActive('Runeword 2 _Stats'))	//modSigns: ENCH-01, from the drawn sword
	{
		if(data.attackName == 'attack_heavy_special')
		{
			data.rangeName = 'runeword2_heavy';		
			weaponEntity = thePlayer.inv.GetItemEntityUnsafe(thePlayer.inv.GetItemFromSlot(data.weaponSlot));
			weaponEntity.PlayEffectSingle('heavy_trail_extended_fx');
		}
		else if(data.attackName == 'attack_light_special')
		{
			data.rangeName = 'runeword2_light';		
			weaponEntity = thePlayer.inv.GetItemEntityUnsafe(thePlayer.inv.GetItemFromSlot(data.weaponSlot));
			weaponEntity.PlayEffectSingle('light_trail_extended_fx');
		}
	}
	else if((W3PlayerWitcher)parent && ((W3PlayerWitcher)parent).HasRunewordActive('Runeword 1 _Stats') && GetWitcherPlayer().GetRunewordInfusionType() == ST_Igni)	//modSigns: ENCH-01, from the drawn sword
	{
		weaponEntity = thePlayer.inv.GetItemEntityUnsafe(thePlayer.inv.GetItemFromSlot(data.weaponSlot));
		weaponEntity.PlayEffectSingle('runeword1_fire_trail');
	}
	else if( parent.HasBuff( EET_Aerondight ) )
	{
		weaponId = thePlayer.inv.GetCurrentlyHeldSword();
		if( thePlayer.inv.ItemHasTag( weaponId, 'Aerondight' ) )
		{			
			aerondight = (W3Effect_Aerondight)thePlayer.GetBuff( EET_Aerondight );
			
			if( aerondight.IsFullyCharged() )
			{
				weaponEntity.PlayEffectSingle( 'aerondight_special_trail' );
			}
		}
	}
	
	res = virtual_parent.OnPreAttackEvent( animEventName, animEventType, data, animInfo );
	
	if ( animEventType == AET_DurationEnd && parent.HasHitTarget() )
	{
		comboPlayer.PlayHit();
	}
	return res;
}
