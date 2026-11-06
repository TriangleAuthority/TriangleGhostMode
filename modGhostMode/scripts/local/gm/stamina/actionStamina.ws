// STAM-03 (refusals and charge timing): Geralt cannot attack, dodge or use bombs, the crossbow
// or items without the stamina
// for it, and attacks are paid at the swing's hit frame instead of on the button press
// (a swing cancelled before it hits is free); finishers are free.
// See docs/features/stam.md.

@addField(CR4Player)
var gmStaminaRefusals : int;		// count of actions refused for lack of stamina (for tests)

@addField(CR4Player)
var gmSuppressAttackDrain : bool;	// set while the input buffer runs: its attack drains cost nothing

@addField(CR4Player)
var gmStaminaRefusalSound : string;	// the last refusal's sound (for tests)

// lowStaminaWarning: legacy's sound for bombs, the crossbow, items and horseback attacks
// (gui_ingame_low_stamina_warning); attacks, dodges and rolls on foot play gui_no_stamina.
@addMethod(CR4Player)
function GMRefuseForStamina(optional lowStaminaWarning : bool)
{
	gmStaminaRefusals += 1;
	if(lowStaminaWarning)
		gmStaminaRefusalSound = "gui_ingame_low_stamina_warning";
	else
		gmStaminaRefusalSound = "gui_no_stamina";
	SoundEvent(gmStaminaRefusalSound);
}

@addMethod(CR4Player)
function GMSetSuppressAttackDrain(b : bool)
{
	gmSuppressAttackDrain = b;
}

// STAM-03: light and heavy attacks are refused without enough stamina.
@wrapMethod(CR4Player)
function SetupCombatAction(action : EBufferActionType, stage : EButtonStage)
{
	if(this == GetWitcherPlayer())
	{
		if((action == EBAT_LightAttack && !HasStaminaToUseAction(ESAT_LightAttack))
			|| (action == EBAT_HeavyAttack && !HasStaminaToUseAction(ESAT_HeavyAttack)))
		{
			GMRefuseForStamina();
			return;
		}
	}
	wrappedMethod(action, stage);
}

// STAM-03: dodges and rolls are refused without enough stamina.
@wrapMethod(W3PlayerWitcher)
function EvadePressed(bufferAction : EBufferActionType)
{
	if((bufferAction == EBAT_Dodge && !HasStaminaToUseAction(ESAT_Dodge))
		|| (bufferAction == EBAT_Roll && !HasStaminaToUseAction(ESAT_Roll)))
	{
		GMRefuseForStamina();
		return;
	}
	wrappedMethod(bufferAction);
}

// STAM-03: vanilla pays light and heavy attacks when the input buffer starts them; those drains cost
// nothing (GMIsAttackDrainSuppressed, in the cost wrapper in staminaCosts.ws) and the attack pays in DoAttack instead.
@wrapMethod(W3PlayerWitcher)
function ProcessCombatActionBuffer() : bool
{
	var ret : bool;

	GMSetSuppressAttackDrain(true);
	ret = wrappedMethod();
	GMSetSuppressAttackDrain(false);
	return ret;
}

function GMIsAttackDrainSuppressed(owner : CActor, action : EStaminaActionType) : bool
{
	return owner == GetWitcherPlayer() && ((CR4Player)owner).gmSuppressAttackDrain
		&& (action == ESAT_LightAttack || action == ESAT_HeavyAttack);
}

// STAM-03: attacks pay at the swing's hit frame (pre-attack event), hit or miss; not during finishers.
@wrapMethod(CR4Player)
function DoAttack(animData : CPreAttackEventData, weaponId : SItemUniqueId, parried : bool, countered : bool, parriedBy : array<CActor>, attackAnimationName : name, hitTime : float)
{
	if(this == GetWitcherPlayer() && !IsPerformingFinisher())
	{
		if(animData.attackName == 'attack_light')
			DrainStamina(ESAT_LightAttack);
		else if(animData.attackName == 'attack_heavy')
			DrainStamina(ESAT_HeavyAttack);
	}
	wrappedMethod(animData, weaponId, parried, countered, parriedBy, attackAnimationName, hitTime);
}

// ---- bombs, crossbow and items ----

// STAM-03: bombs, crossbow and usable items are refused without the usable-item stamina (vanilla
// checks ordinary usable items only); legacy refuses the whole event, sound on press.
function GMRefuseItemForStamina(action : SInputAction) : bool
{
	if(thePlayer.HasStaminaToUseAction(ESAT_UsableItem))
		return false;
	if(IsPressed(action))
		thePlayer.GMRefuseForStamina(true);
	return true;
}

@wrapMethod(CPlayerInput)
function OnThrowBomb(action : SInputAction)
{
	if(GMRefuseItemForStamina(action))
		return false;
	return wrappedMethod(action);
}

@wrapMethod(CPlayerInput)
function OnThrowBombHold(action : SInputAction)
{
	if(GMRefuseItemForStamina(action))
		return false;
	return wrappedMethod(action);
}

@wrapMethod(CPlayerInput)
function OnCbtThrowItem(action : SInputAction)
{
	if(GMRefuseItemForStamina(action))
		return false;
	return wrappedMethod(action);
}

@wrapMethod(CPlayerInput)
function OnCbtThrowItemHold(action : SInputAction)
{
	if(GMRefuseItemForStamina(action))
		return false;
	return wrappedMethod(action);
}

// STAM-03: a bomb is paid when thrown, a crossbow shot when fired (split bolts are one shot).
@wrapMethod(W3Petard)
function ThrowProjectile(targetPosIn : Vector)
{
	wrappedMethod(targetPosIn);
	if(GetOwner() == thePlayer && thePlayer == GetWitcherPlayer())
		thePlayer.DrainStamina(ESAT_UsableItem);
}

@wrapMethod(W3BoltProjectile)
function ThrowProjectile(targetPosIn : Vector)
{
	wrappedMethod(targetPosIn);
	if(GetOwner() == thePlayer && thePlayer == GetWitcherPlayer())
		thePlayer.DrainStamina(ESAT_UsableItem);
}

// STAM-03: out of combat a sprint can start with any stamina (vanilla: above 90%).
// 5.x body; the changed line is marked //modSigns.
@replaceMethod(CR4Player)
function CanSprint( speed : float ) : bool
{
	if( speed <= 0.8f )
	{
		return false;
	}
	
	if ( thePlayer.GetIsSprintToggled() )
	{
	}
	
	else if(GetLeftStickSprint() && theInput.LastUsedGamepad())
	{		
		if(GetIsSprintToggled() && GetIsSprinting())
		{
		}
		else if(!GetIsSprintToggled())
			return false;
	}
	
	else if ( !sprintActionPressed )
	{
		return false;
	}
	else if( !theInput.IsActionPressed('Sprint') || ( theInput.LastUsedGamepad() && IsInsideInteraction() && GetHowLongSprintButtonWasPressed() < 0.12 ) )
	{
		return false;
	}
	
	if ( thePlayer.HasBuff( EET_OverEncumbered ) )
	{
		return false;
	}

	if ( !IsSwimming() )
	{
		if ( ShouldUseStaminaWhileSprinting() && !GetIsSprinting() && !IsInCombat() && GetStat(BCS_Stamina) <= 0 )	//modSigns: was GetStatPercents(BCS_Stamina) <= 0.9
		{
			return false;
		}
		if( ( !IsCombatMusicEnabled() || IsInFistFightMiniGame() ) && ( !IsActionAllowed(EIAB_RunAndSprint) || !IsActionAllowed(EIAB_Sprint) )  )
		{
			return false;
		}
		if( IsTerrainTooSteepToRunUp() )
		{
			return false;
		}
		if( IsInCombatAction() )
		{
			return false;
		}
		if( IsInAir() )
		{
			return false;
		}
		if( IsGuarded() )
		{
			return false;
		}
	}
	if( theGame.IsFocusModeActive() )
	{
		return false;
	}
	
	return true;
}

// STAM-03: after a sprint stops at 0 stamina, sprinting is blocked for 2 s (legacy
// W3PlayerWitcher.CanSprint; not in the changelist). Legacy set the time where 5.x stops the sprint
// at 0 stamina; the wrapper sets it on the same condition after 5.x's checks.
@addField(W3PlayerWitcher)
var gmBlockSprintTimestamp : float;

@wrapMethod(W3PlayerWitcher)
function CanSprint( speed : float ) : bool
{
	var ret : bool;

	if(theGame.GetEngineTimeAsSeconds() - gmBlockSprintTimestamp < 2)
		return false;
	ret = wrappedMethod(speed);
	if(GetCurrentStateName() != 'Swimming' && GetStat(BCS_Stamina) <= 0)
		gmBlockSprintTimestamp = theGame.GetEngineTimeAsSeconds();
	return ret;
}
