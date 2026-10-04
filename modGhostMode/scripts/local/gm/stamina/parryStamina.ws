// STAM-03 slice B: parrying and countering cost stamina, and a parry without enough stamina is
// a partial parry: Geralt still parries (the damage is blocked) but is staggered, instead of
// vanilla's stagger without a parry. Parrying a heavy attack costs x1.25 the parry cost
// (HEAVY_STRIKE_COST_MULTIPLIER, staminaCosts.ws), a super-heavy one x1.5; vanilla charged
// no multiplier on the parry itself. A counter needs enough stamina.
// Ciri is not affected: her stamina checks always pass (vanilla).
// See docs/features/stam.md.

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
	var xmlStaminaDamage 		: float;
	var xmlStaminaDamageName	: name = 'stamina_damage' ;
	var counter 				: int;
	var onHitCounter 			: SAbilityAttributeValue;

	if(CanParryAttack() &&  FistFightCheck( parryInfo.target, parryInfo.attacker, fistFightParry ) )
	{
		parryHeading = GetParryHeading( parryInfo, parryDir ) ;

		SetBehaviorVariable( 'parryDirection', (float)( (int)( parryDir ) ) );
		SetBehaviorVariable( 'parryDirectionOverlay', (float)( (int)( parryDir ) ) );
		SetBehaviorVariable( 'parryType', ChooseParryTypeIndex( parryInfo ) );

		if ( IsInCombatActionFriendly() )
			RaiseEvent('CombatActionFriendlyEnd');

		//modSigns begin: parry cost multiplier for heavy and super-heavy attacks; without
		//enough stamina the parry still happens but is partial (see ProcessAction below)
		mult = GMParryCostMult(parryInfo.attacker, parryInfo.attackActionName);
		gmParryingWithNotEnoughStamina = !HasStaminaToUseAction(ESAT_Parry, '', 0, mult);
		if(gmParryingWithNotEnoughStamina)
			SoundEvent("gui_no_stamina");
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
			counter = GetDefendCounter();
			onHitCounter = parryInfo.attacker.GetAttributeValue( 'break_through_parry_on_hit_counter' );
			if ( onHitCounter.valueBase > 0 && counter == onHitCounter.valueBase )
			{
				AddEffectDefault( EET_Stagger, parryInfo.attacker, "Break through parry" );
			}
			else if ( RaiseForceEvent( 'PerformParry' ) )
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

		if ( parryInfo.attacker.IsWeaponHeld( 'fist' ) && !parryInfo.target.IsWeaponHeld( 'fist' ) )
		{
			parryInfo.attacker.ReactToReflectedAttack(parryInfo.target);
		}
		else
		{
			if ( this.IsInFistFightMiniGame() && fistFightParry )
			{
				if ( IsNameValid(xmlStaminaDamageName) )
				{
					xmlStaminaDamage = CalculateAttributeValue(parryInfo.attacker.GetAttributeValue( xmlStaminaDamageName ));
					DrainStamina(ESAT_FixedValue, xmlStaminaDamage);
				}
			}
			else
			{
				DrainStamina(ESAT_Parry, 0, 0, '', 0, mult);
			}
			if(IsLightAttack(parryInfo.attackActionName))
				parryInfo.target.PlayEffectOnHeldWeapon('light_block');
			else
				parryInfo.target.PlayEffectOnHeldWeapon('heavy_block');
		}
		return true;
	}

	return false;
}

// A partial parry: the parried hit staggers the player (parry-stagger animation, no hit
// animation, no bleeding), unless it already knocks down or staggers.
@wrapMethod(W3DamageManagerProcessor)
function ProcessAction(act : W3DamageAction)
{
	var attackAction : W3Action_Attack;
	var playerVictim : CR4Player;
	var buffs : array<EEffectType>;

	attackAction = (W3Action_Attack)act;
	playerVictim = (CR4Player)act.victim;
	if(playerVictim && attackAction && attackAction.IsActionMelee() && attackAction.IsParried()
		&& playerVictim.GMIsParryingWithNotEnoughStamina())
	{
		act.GetEffectTypes(buffs);
		if(!buffs.Contains(EET_Knockdown) && !buffs.Contains(EET_HeavyKnockdown)
			&& !buffs.Contains(EET_Stagger) && !buffs.Contains(EET_LongStagger)
			&& !buffs.Contains(EET_KnockdownTypeApplicator))
		{
			act.SetParryStagger();
			act.SetHitAnimationPlayType(EAHA_ForceNo);
			act.SetCanPlayHitParticle(false);
			act.SetProcessBuffsIfNoDamage(true);
			act.RemoveBuffsByType(EET_Bleeding);
			act.AddEffectInfo(EET_Stagger);
		}
	}
	wrappedMethod(act);
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
