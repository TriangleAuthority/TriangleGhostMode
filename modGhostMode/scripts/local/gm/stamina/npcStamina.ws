// STAM-08 (NPC stamina), slice 1: every NPC attack costs stamina (the light-attack cost unless
// its behaviour tree names another; counterattacks the counter cost) and is unavailable without
// it, refunded if the task ends in the frame it started (false starts); NPC sign casts pay
// through the sign only (no task cost: NPC Quen is free); regen is paused while an NPC acts in
// combat, and the vanilla 1 s delay follows. See docs/features/stam.md.

// Attacks cost the light-attack cost by default (vanilla: free unless the tree names a cost).
class CBTTaskAttackDef extends CBTTaskPlayAnimationEventDecoratorDef
{
	default xmlStaminaCostName = 'light_action_stamina_cost';	//modSigns
	default drainStaminaOnUse = true;	//modSigns
}

// Sign casts pay through the sign entity, not the task.
abstract class CBTTaskCastSignDef extends CBTTaskPlayAnimationEventDecoratorDef
{
	default xmlStaminaCostName = '';	//modSigns
	default drainStaminaOnUse = false;	//modSigns
}

// Counterattacks cost the counter cost and need it.
@wrapMethod(CBTTaskAttackDef)
function OnSpawn(task : IBehTreeTask)
{
	wrappedMethod(task);
	if(attackType == EAT_Attack20)
		((CBTTaskAttack)task).GMSetStaminaCost('counter_stamina_cost', true);
}

@addMethod(CBTTaskAttack)
function GMSetStaminaCost(costName : name, check : bool)
{
	xmlStaminaCostName = costName;
	checkStats = check;
}

// The attack is charged when its task starts, as vanilla does, but by this file (vanilla's charge
// is turned off in GetStats) so the regen pause gets its own name. Some behaviour trees start an
// attack task and end it in the same frame, many times before the real attack (ghouls about 8
// times, bears about 40: the bear's tree checks the range only after starting the task, the
// ghoul's animation event is refused for a few frames). A task that ends in the frame it started
// is refunded, its regen pause included. (Legacy charged ghouls and bears later instead.)
@addField(CBTTaskAttack)
var gmCharged : float;
@addField(CBTTaskAttack)
var gmChargedAt : float;

@addField(CActor)
var gmLastAttackChargeAt : float;	// start of the NPC's last attack that was not refunded

@addMethod(CActor)
function GMSetLastAttackChargeAt(t : float)
{
	gmLastAttackChargeAt = t;
}

// Undoes a refunded attack's regen pause, keeping what is left of the last real attack's 1 s.
@addMethod(CActor)
function GMUndoAttackPause()
{
	var remaining : float;

	ResumeStaminaRegen('gm_npc_attack');
	remaining = 1 - (theGame.GetEngineTimeAsSeconds() - gmLastAttackChargeAt);
	if(remaining > 0)
		PauseStaminaRegen('gm_npc_attack', remaining);
}

@addMethod(CBTTaskAttack)
function GMChargeAttack()
{
	var actor : CActor;
	var cost, before : float;

	gmCharged = 0;
	if((CBTTaskCastSign)this || !IsNameValid(xmlStaminaCostName))
		return;
	actor = GetActor();
	cost = CalculateAttributeValue(actor.GetAttributeValue(xmlStaminaCostName));
	if(cost <= 0)
		return;
	before = actor.GetStat(BCS_Stamina);
	actor.DrainStamina(ESAT_FixedValue, cost, 1, 'gm_npc_attack');
	gmCharged = before - actor.GetStat(BCS_Stamina);
	gmChargedAt = theGame.GetEngineTimeAsSeconds();
}

@addMethod(CBTTaskAttack)
function GMSettleAttackCharge()
{
	var actor : CActor;

	if(gmCharged <= 0)
		return;
	actor = GetActor();
	if(theGame.GetEngineTimeAsSeconds() - gmChargedAt < 0.0001)
	{
		actor.GainStat(BCS_Stamina, gmCharged);
		actor.GMUndoAttackPause();
	}
	else
	{
		actor.GMSetLastAttackChargeAt(gmChargedAt);
	}
	gmCharged = 0;
}

// Vanilla's charge on activation is off for attacks: GMChargeAttack charges them.
// CBTTaskAttack inherits GetStats (from CBTTaskPlayAnimationEventDecorator), so only a scope
// override can override it here; @replaceMethod refuses inherited definitions.
class CBTTaskAttack extends CBTTaskPlayAnimationEventDecorator
{
	function GetStats()
	{
		super.GetStats();	//modSigns
		drainStaminaOnUse = false;	//modSigns
	}
}

// An attack checks its availability (and so its stamina) again when it starts, then pays.
@wrapMethod(CBTTaskAttack)
function OnActivate() : EBTNodeStatus
{
	var ret : EBTNodeStatus;

	if(!((CBTTaskCastSign)this) && !IsAvailable())
	{
		Complete(false);
		return BTNS_Failed;
	}
	ret = wrappedMethod();
	if(ret != BTNS_Failed)
		GMChargeAttack();
	return ret;
}

@wrapMethod(CBTTaskAttack)
function OnDeactivate()
{
	GMSettleAttackCharge();
	wrappedMethod();
}

// Attack tasks whose OnDeactivate does not call CBTTaskAttack's.
@wrapMethod(BTTaskFrostSnakeAttack)
function OnDeactivate()
{
	GMSettleAttackCharge();
	wrappedMethod();
}

@wrapMethod(CBTTaskSpawnMultipleEntitiesAttack)
function OnDeactivate()
{
	GMSettleAttackCharge();
	wrappedMethod();
}

@wrapMethod(CBTTaskSpawnMultipleEntities3StateAttack)
function OnDeactivate()
{
	GMSettleAttackCharge();
	wrappedMethod();
}

@wrapMethod(CBTTaskToadBackProjectiles)
function OnDeactivate()
{
	GMSettleAttackCharge();
	wrappedMethod();
}

// Regen is paused while an NPC acts in combat (at most 10 s); the drain's 1 s delay follows.
@wrapMethod(CBTTaskPlayAnimationEventDecorator)
function OnActivate() : EBTNodeStatus
{
	var ret : EBTNodeStatus;

	ret = wrappedMethod();
	if(GetActor().IsInCombat())
		GetActor().PauseStaminaRegen('gm_combat_action', 10.f);
	return ret;
}

@wrapMethod(CBTTaskPlayAnimationEventDecorator)
function OnDeactivate()
{
	GetActor().ResumeStaminaRegen('gm_combat_action');
	wrappedMethod();
}

// ---- slice 2: defence needs stamina ----
// Raising the guard, parrying and countering need the stamina for it; the AI's rolls that decide
// whether it defends stay (raise_guard_chance, counter_chance). A parry costs the fixed parry
// cost (vanilla: x HEAVY_STRIKE_COST_MULTIPLIER); a counter is paid by the counterattack's own
// task (counter cost, slice 1), not again by the parry.

@addMethod(CActor)
function GMHasStaminaFor(costAttribute : name) : bool
{
	return GetStat(BCS_Stamina) >= CalculateAttributeValue(GetAttributeValue(costAttribute));
}

// The parry window only opens, and stays usable, with the parry cost in stamina.
@wrapMethod(CBTTaskPerformParry)
function CanParry() : bool
{
	return wrappedMethod() && GetNPC().GMHasStaminaFor('parry_stamina_cost');
}

@wrapMethod(CBTTaskPerformParry)
function IsAvailable() : bool
{
	var ret : bool;

	ret = wrappedMethod();
	return ret && GetNPC().GMHasStaminaFor('parry_stamina_cost');
}

// 5.x body; changed lines marked //modSigns.
@replaceMethod(CBTTaskPerformParry)
function TryToParry(optional counter : bool) : bool
{
	var npc : CNewNPC = GetNPC();
	var hasStamina : bool;	//modSigns

	if(counter)	//modSigns: the parry or counter cost is needed
		hasStamina = npc.GMHasStaminaFor('counter_stamina_cost');	//modSigns
	else	//modSigns
		hasStamina = npc.GMHasStaminaFor('parry_stamina_cost');	//modSigns

	if ( isActive && npc.CanParryAttack() && allowParryOverlap && hasStamina )	//modSigns: && hasStamina
	{
		LogChannel( 'HitReaction', "Parried" );
		
		npc.SignalGameplayEvent('SendBattleCry');
		//modSigns: removed mult = theGame.params.HEAVY_STRIKE_COST_MULTIPLIER (the parry costs a fixed amount)
		if ( npc.RaiseEvent('ParryPerform') )
		{
			if( counter )
			{
				npc.SignalGameplayEvent('Counter');	//modSigns: not drained here, the counterattack's task pays
			}
			else
				npc.DrainStamina( ESAT_FixedValue, CalculateAttributeValue(npc.GetAttributeValue('parry_stamina_cost')), 1 );	//modSigns: fixed parry cost (was ESAT_Parry x HEAVY_STRIKE_COST_MULTIPLIER)
			
			((CHumanAICombatStorage)combatDataStorage).IncParryCount();
			npc.IncDefendCounter();
			activationTimeLimit = GetLocalTime() + 0.5;
		}
		else
		{
			Complete(false);
		}
		
		return true;
		
	}
	else if ( isActive )
	{
		Complete(false);
		activationTimeLimit = 0.0;
	}
	
	
	return false;
}

// 5.x body; changed line marked //modSigns.
@replaceMethod(CBTTaskPerformParry)
function CheckCounter() : bool
{
	var npc : CNewNPC = GetNPC();
	var defendCounter : int;
	
	defendCounter = npc.GetDefendCounter();
	if ( defendCounter >= hitsToCounter )
	{
		if( Roll( counterChance ) && npc.GMHasStaminaFor('counter_stamina_cost') )	//modSigns: && counter stamina
		{
			npc.SignalGameplayEvent('CounterFromDefence');
			return true;
		}
	}
	
	return false;
}

// 5.x body; changed line marked //modSigns.
@replaceMethod(CBTTaskPerformParry)
function ShouldCounter(isHeavy : bool) : bool
{
	var playerTarget : W3PlayerWitcher;
	//modSigns: removed the unused var temp, temp2 : int
	if ( GetActor().HasAbility('DisableCounterAttack') )
		return false;
	
	playerTarget = (W3PlayerWitcher)GetCombatTarget();
	
	if ( playerTarget && playerTarget.IsInCombatAction_SpecialAttack() )
		return false;
	
	if ( isHeavy && !GetActor().HasAbility('ablCounterHeavyAttacks') )
		return false;
		
	return ((CHumanAICombatStorage)combatDataStorage).GetParryCount() >= hitsToCounter && Roll(counterChance)	//modSigns: the return continues below
		&& GetActor().GMHasStaminaFor('counter_stamina_cost');	//modSigns: && counter stamina
}

// 5.x body; changed line marked //modSigns.
@replaceMethod(CBTTaskDodge)
function CheckCounter() : bool
{
	var npc : CNewNPC = GetNPC();
	var defendCounter : int;

	defendCounter = npc.GetDefendCounter();
	if ( defendCounter >= hitsToCounter )
	{
		if( Roll( counterChance ) && npc.GMHasStaminaFor('counter_stamina_cost') )	//modSigns: && counter stamina
		{
			npc.SignalGameplayEvent('CounterFromDefence');
			return true;
		}
	}

	return false;
}

// 5.x body; changed line marked //modSigns.
@replaceMethod(BTTaskAdditiveHitListener)
function CheckGuardOrCounter() : bool
{
	var npc : CNewNPC = GetNPC();
	var hitCounter : int;
	
	
	GetStats();
	hitCounter = npc.GetHitCounter();
	if ( hitCounter >= hitsToRaiseGuard && npc.CanGuard() )
	{
		
		if( Roll( raiseGuardChance ) && npc.GMHasStaminaFor('parry_stamina_cost') )	//modSigns: && parry stamina
		{		
			if ( npc.RaiseGuard() )
			{
				npc.SignalGameplayEvent('HitReactionTaskCompleted');
				return true;
			}
		}
	}
	if ( !npc.IsHuman() && GetActor().GetMovingAgentComponent().GetName() != "wild_hunt_base" && hitCounter >= hitsToCounter   )
	{
		if( Roll( counterChance ) && npc.GetStat( BCS_Stamina ) >= counterStaminaCost )
		{
			npc.SignalGameplayEvent('LaunchCounterAttack');
			return true;
		}
	}
	
	return false;
}

// 5.x body; changed line marked //modSigns.
@replaceMethod(CBTTaskHitReactionDecorator)
function CheckGuardOrCounter() : bool
{
	var npc : CNewNPC = GetNPC();
	var hitCounter : int;
	
	if( npc.HasTag( 'olgierd_gpl' ) )
	{
		if( AbsF( NodeToNodeAngleDistance( thePlayer, npc ) ) > 90 )
		{
			return false;
		}
	}

	
	GetStats();
	hitCounter = npc.GetHitCounter();
	if ( hitCounter >= hitsToRaiseGuard && npc.CanGuard() )
	{
		if( Roll( raiseGuardChance ) && npc.GMHasStaminaFor('parry_stamina_cost') )	//modSigns: && parry stamina
		{		
			if ( npc.RaiseGuard() )
			{
				npc.SignalGameplayEvent('HitReactionTaskCompleted');
				return true;
			}
		}
	}
	if ( !npc.IsHuman() && hitCounter >= hitsToCounter && npc.GetMovingAgentComponent().GetName() != "wild_hunt_base" && !npc.HasTag( 'dettlaff_vampire' )  )
	{
		if( Roll( counterChance ) && npc.GetStat( BCS_Stamina ) >= counterStaminaCost )
		{
			npc.SignalGameplayEvent('LaunchCounterAttack');
			return true;
		}
	}
	
	return false;
}

// ---- slice 3: low stamina ----
// Below 10% stamina an NPC stops asking for attack tickets until it has 33.4% again; a shielded
// NPC drops its shield when it cannot pay for a parry, or on a heavy attack at 34% stamina or
// less (vanilla: a parried heavy attack at 10% or less).

@addField(CActor)
var gmWaitForStaminaRegen : bool;

@addMethod(CActor)
function GMCheckWaitForStaminaRegen()
{
	if(!gmWaitForStaminaRegen && GetStatPercents(BCS_Stamina) < 0.1)
		gmWaitForStaminaRegen = true;
	else if(gmWaitForStaminaRegen && GetStatPercents(BCS_Stamina) > 0.334)
		gmWaitForStaminaRegen = false;
}

@wrapMethod(W3AbilityManager)
function DrainStamina(action : EStaminaActionType, optional fixedCost : float, optional fixedDelay : float, optional abilityName : name, optional dt : float, optional costMult : float) : float
{
	var cost : float;

	cost = wrappedMethod(action, fixedCost, fixedDelay, abilityName, dt, costMult);
	if(owner != thePlayer)
		owner.GMCheckWaitForStaminaRegen();
	else
		thePlayer.GMCheckForLowStamina();	// STAM-07
	return cost;
}

@wrapMethod(W3Effect_AutoStaminaRegen)
function OnUpdate(dt : float)
{
	var ret : bool;

	ret = wrappedMethod(dt);
	if(!isOnPlayer)
		target.GMCheckWaitForStaminaRegen();
	else
		((CR4Player)target).GMCheckForLowStamina();	// STAM-07
	return ret;
}

// Attack tickets (the approach algorithm has its own ShouldAskForTicket, unaffected).
@wrapMethod(CTicketBaseAlgorithm)
function ShouldAskForTicket() : bool
{
	if(GetActor().gmWaitForStaminaRegen)
		return false;
	return wrappedMethod();
}

@wrapMethod(CTicketAlgorithmMelee)
function CalculateTicketImportance() : float
{
	if(GetActor().gmWaitForStaminaRegen)
		return 0;
	return wrappedMethod();
}

// The shield rule, after vanilla's (whose condition is a case of this one).
@wrapMethod(W3DamageManagerProcessor)
function ProcessActionReaction(wasFrozen : bool, wasAlive : bool)
{
	var npcVictim : CNewNPC;
	var attackName : name;

	wrappedMethod(wasFrozen, wasAlive);
	npcVictim = (CNewNPC)actorVictim;
	if(attackAction && npcVictim && actorAttacker && npcVictim.IsShielded(actorAttacker))
	{
		attackName = attackAction.GetAttackName();
		if(!npcVictim.HasStaminaToParry(attackName) || (actorAttacker.IsHeavyAttack(attackName) && npcVictim.GetStaminaPercents() <= 0.34))
			npcVictim.ProcessShieldDestruction();
	}
}
