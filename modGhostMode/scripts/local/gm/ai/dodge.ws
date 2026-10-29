// AI-09 (dodging, changelist 1116: "AI should be better at dodging"): an enemy has 0.25 s (0.1) after an
// incoming attack's dodge signal to start its dodge, with no minimum delay between dodges, also out of its
// own attack, without overlapping dodges, and only within 3 m of its target (5 m); never in the air or off
// the ground (with DEF-06's counter guards, defense/enemyDefense.ws, which call GMEnemyNotGrounded).
// CBTTaskReaction.Main dodged when its dodge roll said no (a bug in 1.32 and 5.x): fixed, with DEF-06's
// stun guard on that roll (the DEF audit's F12 left both for AI).
// The dodge and counter chances come from the abilities (AI-08); 5.x's NG+ x1.15 stays (PA14).
// See docs/features/ai.md.

// AI-09: no dodge in the air or off the ground (legacy's lines next to DEF-06's counter guards).
function GMEnemyNotGrounded(npc : CNewNPC) : bool
{
	return npc && ( npc.IsInAir() || !npc.IsOnGround() );
}

// AI-09: dodges only within 3 m of the target (5 m).
class CBTTaskDodgeDef extends CBTTaskPlayAnimationEventDecoratorDef
{
	default maxDistanceFromTarget = 3;	//modSigns: 5 -> 3 m
}

// 5.x body; changed line marked //modSigns.
@replaceMethod(CBTTaskDodge)
function IsAvailable() : bool
{
	var npc : CNewNPC = GetNPC();

	if(instantActivation)
	{
		return true;
	}

	if ( !npc.IsCurrentlyDodging() && Time2Dodge && dodgeEventTime )
	{
		if ( dodgeEventTime + 0.25 < GetLocalTime() )	//modSigns: dodge wait 0.1 -> 0.25 s
		{
			Time2Dodge = false;
		}
		if ( delayDodgeHeavyAttack > 0 && dodgeEventTime > GetLocalTime() )
		{
			return false;
		}
	}

	return Time2Dodge && super.IsAvailable();
}

// 5.x body; changed line marked //modSigns.
@replaceMethod(CBTTaskDodge)
function OnDeactivate()
{

	swingType = -1;
	swingDir = -1;
	//modSigns: removed nextDodgeTime = GetLocalTime() + minDelayBetweenDodges; (no delay between dodges)
	performDodgeDelay = 0;
	GetActor().SetIsCurrentlyDodging(false);
	super.OnDeactivate();
}

// 5.x body; changed lines marked //modSigns.
@replaceMethod(CBTTaskDodge)
function Dodge() : bool
{
	if ( dodgeEventTime + 0.25 < GetLocalTime() )	//modSigns: dodge wait 0.1 -> 0.25 s
	{
		return false;
	}

	//modSigns: removed the nextDodgeTime check (no delay between dodges)

	if ( !CheckDistance() )
	{
		return false;
	}
	InitializeCombatDataStorage();
	//modSigns: removed the check that refused a dodge while attacking (a dodge out of the attack task)

	if( !ChooseAndCheckDodge() )
	{
		return false;
	}

	if( !CheckNavMesh() )
	{
		return false;
	}

	return true;
}

// 5.x body; changed line marked //modSigns.
@replaceMethod(CBTTaskDodge)
function OnListenedGameplayEvent( eventName : name ) : bool
{
	var npc : CNewNPC = GetNPC();


	if ( eventName == 'swingType' )
	{
		swingType = this.GetEventParamInt(-1);
	}
	if ( eventName == 'swingDir' )
	{
		swingDir = this.GetEventParamInt(-1);
	}

	if ( eventName == 'Time2DodgeProjectile' )
	{
		dodgeType = EDT_Projectile;
		ownerPosition = npc.GetWorldPosition();
		performDodgeDelay = this.GetEventParamFloat(-1);
		performDodgeDelay = ClampF( (performDodgeDelay -0.4), 0, 99 );
		npc.AddTimer( 'DelayDodgeProjectileEventTimer', performDodgeDelay );
		return true;
	}
	else if ( eventName == 'Time2DodgeBomb' )
	{
		dodgeType = EDT_Bomb;
		ownerPosition = npc.GetWorldPosition();
		performDodgeDelay = this.GetEventParamFloat(-1);
		performDodgeDelay = ClampF( (performDodgeDelay -0.4), 0, 99 );
		npc.AddTimer( 'DelayDodgeBombEventTimer', performDodgeDelay );
		return true;
	}
	else if ( ( eventName == 'Time2DodgeFast' && earlyDodgeActivation ) || eventName == 'Time2Dodge' || eventName == 'Time2DodgeProjectileDelayed' || eventName == 'Time2DodgeBombDelayed' )
	{
		GetDodgeStats();
		if ( interruptTaskToExecuteCounter && CheckCounter() && !npc.IsCountering() )
		{
			npc.DisableHitAnimFor(0.1);
			Complete(true);
			return false;
		}

		if ( eventName != 'Time2DodgeProjectileDelayed' && eventName != 'Time2DodgeBombDelayed')
		{
			dodgeType = this.GetEventParamInt(-1);
		}

		if ( delayDodgeHeavyAttack > 0 && dodgeType == EDT_Attack_Heavy )
		{
			dodgeEventTime = GetLocalTime() + delayDodgeHeavyAttack;
		}
		else
		{
			dodgeEventTime = GetLocalTime();
		}

		if ( Dodge() )
		{
			Time2Dodge = true;
			if ( npc.IsInHitAnim() && signalGameplayEventWhileInHitAnim )
				npc.SignalGameplayEvent('WantsToPerformDodge');
			else if ( dodgeType == EDT_Attack_Heavy )
				npc.SignalGameplayEvent('WantsToPerformDodgeAgainstHeavyAttack');
			//modSigns: removed the dodge overlap (a dodge interrupting the ongoing one)
		}

		return true;
	}

	return false;
}

// AI-09: the reaction task dodged when its roll said no (1.32 and 5.x); legacy's fix. 5.x body (a latent
// function, replaced without the keyword); changed line marked //modSigns.
@replaceMethod(CBTTaskReaction)
function Main() : EBTNodeStatus
{
	var npc : CNewNPC = GetNPC();

	if ( (dodgeType == EDT_Attack_Light || dodgeType == EDT_Attack_Heavy ) && counterChance > 0)
	{
		if (RandRange(100) < counterChance)
		{
			if( npc.RaiseForceEvent( 'CounterAttack' ) )
			{
				npc.WaitForBehaviorNodeDeactivation( 'CounterAttackEnd', 10.0f );
				Time2Dodge = false;
				return BTNS_Completed;
			}
		}
	}
	else
	{
		if( ChooseAndCheckDodge() )	//modSigns: dodge when the roll says yes (vanilla: when it says no)
		{
			if( npc.RaiseForceEvent( 'Dodge' ) )
			{
				npc.WaitForBehaviorNodeDeactivation( 'DodgeEnd', 10.0f );
				Time2Dodge = false;
				return BTNS_Completed;
			}
		}
	}
	return BTNS_Failed;
}

// AI-09 with DEF-06: while stunned by a counter, the reaction task's dodge roll says no (legacy's guard,
// safe now that Main dodges only on a yes).
@wrapMethod(CBTTaskReaction)
function ChooseAndCheckDodge() : bool
{
	if(GetNPC().HasBuff(EET_CounterStrikeHit))
		return false;
	return wrappedMethod();
}
