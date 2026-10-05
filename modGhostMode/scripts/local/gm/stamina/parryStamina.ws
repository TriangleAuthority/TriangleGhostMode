// STAM-03 slice B: parrying and countering cost stamina, and a parry without enough stamina is
// a partial parry: Geralt still parries but is hurt and staggered (defense/processAction.ws), instead
// of vanilla's stagger without a parry. Parrying a heavy attack costs x1.25 the parry cost
// (HEAVY_STRIKE_COST_MULTIPLIER, staminaCosts.ws), a super-heavy one x1.5; vanilla charged
// no multiplier on the parry itself. A counter needs enough stamina.
// Ciri is not affected: her stamina checks always pass (vanilla).
// DEF-05 (in the PerformParryCheck replacement): no break-through stagger, and a parry in a
// fistfight minigame costs the parry cost (vanilla: the attacker's stamina_damage).
// See docs/features/stam.md and def.md.

function GMParryCostMult(attacker : CActor, attackName : name) : float
{
	if(attacker.IsSuperHeavyAttack(attackName))
		return 1.5;
	if(attacker.IsHeavyAttack(attackName))
		return theGame.params.HEAVY_STRIKE_COST_MULTIPLIER;
	return 0;	// no multiplier
}

@addField(CR4Player)
var gmParryingWithNotEnoughStamina : bool;

@addMethod(CR4Player)
function GMIsParryingWithNotEnoughStamina() : bool
{
	return gmParryingWithNotEnoughStamina;
}

// 5.x body; changes marked //modSigns.
@replaceMethod(CR4Player)
function PerformParryCheck( parryInfo : SParryInfo) : bool
{
	var mult 					: float;
	var parryType 				: EParryType;
	var parryDir 				: EPlayerParryDirection;
	var parryHeading			: float;
	var fistFightParry 			: bool;
	var action					: W3DamageAction;
	//modSigns: removed xmlStaminaDamage, xmlStaminaDamageName, counter, onHitCounter (DEF-05: their uses are removed below)

	if(CanParryAttack() &&  FistFightCheck( parryInfo.target, parryInfo.attacker, fistFightParry ) )
	{
		parryHeading = GetParryHeading( parryInfo, parryDir ) ;

		SetBehaviorVariable( 'parryDirection', (float)( (int)( parryDir ) ) );
		SetBehaviorVariable( 'parryDirectionOverlay', (float)( (int)( parryDir ) ) );
		SetBehaviorVariable( 'parryType', ChooseParryTypeIndex( parryInfo ) );

		if ( IsInCombatActionFriendly() )
			RaiseEvent('CombatActionFriendlyEnd');

		//modSigns begin: parry cost multiplier for heavy and super-heavy attacks; without
		//enough stamina the parry still happens but is partial (see ProcessAction, defense/processAction.ws)
		mult = GMParryCostMult(parryInfo.attacker, parryInfo.attackActionName);	//modSigns
		gmParryingWithNotEnoughStamina = !HasStaminaToUseAction(ESAT_Parry, '', 0, mult);	//modSigns
		if(gmParryingWithNotEnoughStamina)	//modSigns
			SoundEvent("gui_no_stamina");	//modSigns
		//modSigns end

		//modSigns: was "if ( HasStaminaToParry(parryInfo.attackActionName) ) { ... } else { stagger }"
		this.SetBehaviorVariable( 'combatActionType', (int)CAT_Parry );

		if ( parryInfo.targetToAttackerDist > 3.f && !bLAxisReleased && !thePlayer.IsCiri() )
		{
			if ( !RaiseForceEvent( 'PerformParryOverlay' ) )
				return false;
			else
			{
				ClearCustomOrientationInfoStack();
				IncDefendCounter();
			}
		}
		else
		{
			//modSigns: removed the break-through stagger (DEF-05: every Nth parry in a row against an attacker with break_through_parry_on_hit_counter staggered)
			if ( RaiseForceEvent( 'PerformParry' ) )	//modSigns: was else if
			{
				OnCombatActionStart();
				ClearCustomOrientationInfoStack();
				SetSlideTarget( parryInfo.attacker );
				SetCustomRotation( 'Parry', parryHeading, 1080.f, 0.1f, false );
				IncDefendCounter();
			}
			else
				return false;
		}
		//modSigns: removed vanilla's else branch (no stamina: stagger instead of parrying)

		if ( parryInfo.attacker.IsWeaponHeld( 'fist' ) && !parryInfo.target.IsWeaponHeld( 'fist' ) )
		{
			parryInfo.attacker.ReactToReflectedAttack(parryInfo.target);
		}
		else
		{
			//modSigns: removed the fistfight minigame's drain of the attacker's stamina_damage (DEF-05: a parry costs the parry cost there too)
			DrainStamina(ESAT_Parry, 0, 0, '', 0, mult);	//modSigns: was in an else branch
			if(IsLightAttack(parryInfo.attackActionName))
				parryInfo.target.PlayEffectOnHeldWeapon('light_block');
			else
				parryInfo.target.PlayEffectOnHeldWeapon('heavy_block');
		}
		return true;
	}

	return false;
}

// A counter needs enough stamina (vanilla: counters were free).
@wrapMethod(W3PlayerWitcher)
function PerformCounterCheck(parryInfo : SParryInfo) : bool
{
	if(!HasStaminaToUseAction(ESAT_Counterattack))
		return false;
	return wrappedMethod(parryInfo);
}

// STAM-03: whether an actor has the stamina to parry, without vanilla's heavy-attack multiplier
// (legacy removed it here; callers that want one pass it to the cost). Used by the NPC parry
// decision (CNewNPC.PerformParryCheck) and STAM-08's shield rule; Geralt's parry check is
// replaced above. 5.x body, changed line marked.
@replaceMethod(CActor)
function HasStaminaToParry( attActionName : name ) : bool
{
	return HasStaminaToUseAction( ESAT_Parry, '', 0, 0 );	//modSigns: no heavy-attack multiplier
}
