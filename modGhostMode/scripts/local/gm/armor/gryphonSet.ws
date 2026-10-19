// ARM-07: the Griffin set as legacy (DA1; changelist 576-577, 598-599). Tier 1: any sign cast starts a
// 2.5 s buff (not refreshed while it runs) during which sign, melee and agility stamina costs drop 5% per
// Griffin piece (lower tiers count). 5.x's free casts are gone: the buff no longer marks a sign as free
// (W3SignEntity.ManageGryphonSetBonusBuff, ManagePlayerStamina, HasStaminaToUseSkill, the sign's
// OnThrowing in skills/), nor blocks alternate casts below full stamina (ChangeAspect). Tier 2: inside a
// normal Yrden, intensity +50% and +15% resistances, no regen and no damage reduction
// (GryphonSetBonusYrdenEffect in gm_armor_sets.xml; the reduction in defense/dodge.ws removed).
// See docs/features/arm.md.

// The tier 1 cut: 5% per Griffin piece, any tier.
@addMethod(W3PlayerWitcher)
function GMGetGryphonSetTier1Bonus() : float
{
	var min, max : SAbilityAttributeValue;

	theGame.GetDefinitionsManager().GetAbilityAttributeValue('GryphonSetBonusEffect', 'gryphon_tier1_bonus', min, max);
	return min.valueAdditive * GetSetPartsEquipped(EIST_Gryphon);
}

// Tier 1: any sign cast starts the buff (legacy OnSignCastPerformed).
@wrapMethod(W3PlayerWitcher)
function OnSignCastPerformed(signType : ESignType, isAlternate : bool)
{
	wrappedMethod(signType, isAlternate);
	if(!HasBuff(EET_GryphonSetBonus) && IsSetBonusActive(EISB_Gryphon_1))
		AddEffectDefault(EET_GryphonSetBonus, NULL, "gryphonSetBonus");
}

// The buff does not survive a load (legacy OnSpawned).
@wrapMethod(W3PlayerWitcher)
function OnSpawned(spawnData : SEntitySpawnData)
{
	wrappedMethod(spawnData);
	if(HasBuff(EET_GryphonSetBonus))
		RemoveBuff(EET_GryphonSetBonus);
}

// Sign, melee and agility costs while the buff runs (legacy's cost sites in PlayerAbilityManager.ws).
@wrapMethod(W3AbilityManager)
function GetStaminaActionCost(action : EStaminaActionType, out cost : float, out delay : float, optional fixedCost : float, optional fixedDelay : float, optional abilityName : name, optional dt : float, optional costMult : float)
{
	wrappedMethod(action, cost, delay, fixedCost, fixedDelay, abilityName, dt, costMult);
	if(owner == GetWitcherPlayer() && cost > 0 && owner.HasBuff(EET_GryphonSetBonus))
	{
		if((action == ESAT_Ability && IsSkillSign(SkillNameToEnum(abilityName))) || GMIsMeleeStaminaAction(action))
			cost = ClampF(cost * (1 - GetWitcherPlayer().GMGetGryphonSetTier1Bonus()), 0, 100);
	}
}

@wrapMethod(W3PlayerAbilityManager)
function GetSkillStaminaUseCost(skill : ESkill, optional isPerSec : bool) : float
{
	var cost : float;

	cost = wrappedMethod(skill, isPerSec);
	if(owner == GetWitcherPlayer() && IsSkillSign(skill) && owner.HasBuff(EET_GryphonSetBonus))
		cost = ClampF(cost * (1 - GetWitcherPlayer().GMGetGryphonSetTier1Bonus()), 0, 100);
	return cost;
}

// 5.x's free-cast buff is no longer started or ended here (legacy: no longer used).
@replaceMethod(W3SignEntity)
function ManageGryphonSetBonusBuff()
{
	//modSigns: removed 5.x's free-cast buff: the Griffin buff starts at every cast (OnSignCastPerformed) and nothing ends it early (ARM-07)
}

// 5.x body; changes marked //modSigns.
@replaceMethod(W3SignOwnerPlayer)
function ChangeAspect( signEntity : W3SignEntity, newSkill : ESkill ) : bool
{
	var newTarget : CActor;
	var ret : bool;
	
	
	
	var shouldAltCast : bool;
	var shouldAltCastSelect : bool = false;
	var altInputPressed : bool;
	var mouserControllerScheme : MouserControllerScheme = theInput.GetMouserControllerScheme();

	if(!theInput.LastUsedPCInput() && thePlayer.GetInputHandler().GetIsAltSignCasting())
	{
		if (mouserControllerScheme == MouserControllerScheme_None) 
		{
			if( ((W3AardEntity)signEntity) && (theInput.IsActionPressed('Sprint') || theInput.IsActionPressed('CbtRoll')))
			{
				shouldAltCast = true;
			}
			else if( ((W3AxiiEntity)signEntity) && theInput.IsActionPressed('AttackLight') )
			{
				shouldAltCast = true;
			}
			else if( ((W3QuenEntity)signEntity) && (theInput.IsActionPressed('AltQuenCasting') || theInput.IsActionPressed('Dodge')))
			{
				shouldAltCast = true;
			}
			else if( ((W3YrdenEntity)signEntity) && theInput.IsActionPressed('AttackHeavy') )
			{
				shouldAltCast = true;
			}
			else if( ((W3IgniEntity)signEntity) && (theInput.IsActionPressed('LockAndGuard') || theInput.IsActionPressed('Focus')) )
			{
				shouldAltCast = true;
			}
		}
		else if (mouserControllerScheme == MouserControllerScheme_Comfort)
		{
			if( ((W3AardEntity)signEntity) && (theInput.IsActionPressed('Sprint') || theInput.IsActionPressed('CbtRoll')))
			{
				shouldAltCast = true;
			}
			else if( ((W3AxiiEntity)signEntity) && theInput.IsActionPressed('ThrowItem') )
			{
				shouldAltCast = true;
			}
			else if( ((W3QuenEntity)signEntity) && (theInput.IsActionPressed('AltQuenCasting') || theInput.IsActionPressed('Dodge')))
			{
				shouldAltCast = true;
			}
			else if( ((W3YrdenEntity)signEntity) && (theInput.IsActionPressed('LockAndGuard') || theInput.IsActionPressed('Focus')) )
			{
				shouldAltCast = true;
			}
			else if( ((W3IgniEntity)signEntity) && theInput.IsActionPressed('AttackHeavy') )
			{
				shouldAltCast = true;
			}
		}
		else if(mouserControllerScheme == MouserControllerScheme_Dynamic)
		{
			if( ((W3AardEntity)signEntity) && (theInput.IsActionPressed('SilverSword')) )
			{
				shouldAltCast = true;
			}
			else if( ((W3AxiiEntity)signEntity) && theInput.IsActionPressed('DrinkPotion1') )
			{
				shouldAltCast = true;
			}
			else if( ((W3QuenEntity)signEntity) && theInput.IsActionPressed('DrinkPotion2') )
			{
				shouldAltCast = true;
			}
			else if( ((W3YrdenEntity)signEntity) && theInput.IsActionPressed('SteelSword') )
			{
				shouldAltCast = true;
			}
			else if( ((W3IgniEntity)signEntity) && (theInput.IsActionPressed('LockAndGuard') || theInput.IsActionPressed('Focus')) )
			{
				shouldAltCast = true;
			}
		}
	}
	else if(theInput.LastUsedPCInput() && thePlayer.GetInputHandler().GetIsAltSignCasting())
	{
		if( ((W3AardEntity)signEntity) && (theInput.IsActionPressed('SelectAard') || theInput.IsActionPressed( 'CastSign' )) )
		{
			shouldAltCast = true;
			shouldAltCastSelect = !theInput.IsActionReleased('SelectAard');
			altInputPressed = theInput.IsActionPressed('SelectAard');
		} 
		else if( ((W3IgniEntity)signEntity) && (theInput.IsActionPressed('SelectIgni') || theInput.IsActionPressed( 'CastSign' )) )
		{
			shouldAltCast = true;
			shouldAltCastSelect = !theInput.IsActionReleased('SelectIgni');
			altInputPressed = theInput.IsActionPressed('SelectIgni');
		}
		else if( ((W3YrdenEntity)signEntity) && (theInput.IsActionPressed('SelectYrden') || theInput.IsActionPressed( 'CastSign' )) )
		{
			shouldAltCast = true;
			shouldAltCastSelect = !theInput.IsActionReleased('SelectYrden');
			altInputPressed = theInput.IsActionPressed('SelectYrden');
		}
		else if( ((W3QuenEntity)signEntity) && (theInput.IsActionPressed('SelectQuen') || theInput.IsActionPressed( 'CastSign' )) )
		{
			shouldAltCast = true;
			shouldAltCastSelect = !theInput.IsActionReleased('SelectQuen');
			altInputPressed = theInput.IsActionPressed('SelectQuen');
		}
		else if( ((W3AxiiEntity)signEntity) && (theInput.IsActionPressed('SelectAxii') || theInput.IsActionPressed( 'CastSign' )) )
		{
			shouldAltCast = true;
			shouldAltCastSelect = !theInput.IsActionReleased('SelectAxii');
			altInputPressed = theInput.IsActionPressed('SelectAxii');
		}
	}
	else
	{
		shouldAltCast = true;
	}
	
	if ( !player.CanUseSkill( newSkill ) )
	{
		ret = false;
	}	
	else if ( (theInput.IsActionPressed( 'CastSign' ) || theInput.GetActionValue( 'CastSignHold' ) > 0.f || altInputPressed) && shouldAltCast ) 
	{
		if ( !player.IsCombatMusicEnabled() && !player.CanAttackWhenNotInCombat( EBAT_CastSign, true, newTarget ) )
		{
			ret = false;
		}
		//modSigns: removed 5.x's Griffin set rule (no alternate cast below full stamina while its buff runs; ARM-07, legacy)
		else if( theInput.IsActionPressed( 'CastSign' ) && !altInputPressed && theInput.GetActionValue( 'CastSignHold' ) == 0.f )
		{
			ret = false;
		}
		else if( altInputPressed )
		{
			if (shouldAltCastSelect)
			{
				signEntity.SetAlternateCast( newSkill );
				player.SetBehaviorVariable( 'alternateSignCast', 1 );
				ret = true;
			}
			else
			{
				ret = false;
			}
		}
		else
		{
			signEntity.SetAlternateCast( newSkill );
			player.SetBehaviorVariable( 'alternateSignCast', 1 );
			ret = true;
		}
	}
	else 
	{
		ret = false;
	}
	
	if(!ret)
		signEntity.OnNormalCast();
	
	return ret;
}
