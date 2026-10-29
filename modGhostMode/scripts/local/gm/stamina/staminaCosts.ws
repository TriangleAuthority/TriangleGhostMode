// STAM-03: stamina costs for every action. The base costs are XML (Ghost Mode's DLC:
// ConGeralt's action costs, sign cost 40); this file applies the options "Melee action cost
// modifier", "Sprint/jump action cost modifier" and "Sign action cost modifier" (cost * (1 + value))
// on top of 5.x's own cost rules (Avoidance, adrenaline casting, ...), caps every actor's costs at 100,
// and lowers the cost of parrying a heavy attack to x1.25 (vanilla x2).
// See docs/features/stam.md.

// Ghost Mode's W3GameParams defaults (a mod declares a class's scope-based override block once).
import class W3GameParams extends CObject
{
	// STAM-03: parrying a heavy attack costs x1.25 the parry cost (vanilla x2; counters: no multiplier, DEF-06's counter.ws).
	default HEAVY_STRIKE_COST_MULTIPLIER = 1.25;	//modSigns: vanilla 2
	// DEF-05: a partial parry lets 50% of the damage through, whatever the attacker's size
	// (legacy PARRY_STAGGER_REDUCE_DAMAGE 0.5; CActor.ReduceDamage multiplies by these).
	default PARRY_STAGGER_REDUCE_DAMAGE_LARGE = 0.5;	//modSigns: vanilla 0.6
	default PARRY_STAGGER_REDUCE_DAMAGE_SMALL = 0.5;	//modSigns: vanilla 0.3
	// ITEM-10: gear wears slower and counts as damaged below 75% (legacy; gm/items/durability.ws).
	default ITEM_DAMAGED_DURABILITY = 75;	//modSigns: vanilla 50
	default DURABILITY_ARMOR_LOSE_VALUE = 0.5;	//modSigns: vanilla 0.6
	default DURABILITY_WEAPON_LOSE_VALUE = 0.05;	//modSigns: vanilla 0.26
	default DURABILITY_WEAPON_LOSE_VALUE_HARDCORE = 0.05;	//modSigns: vanilla 0.1
	// ALCH-01: overdose at 75% of maximum toxicity (legacy, the owner's DL1; gm/alchemy/toxicity.ws).
	default TOXICITY_DAMAGE_THRESHOLD = 0.75;	//modSigns: vanilla 0.50001
	// AI-01: an enemy counts as "high" 6 and "deadly" 15 levels above Geralt (legacy and 1.32; the owner's
	// DA4). Also read by SKL-12's finisher rule, UI-12's red level, quest colours, parries and XP.
	default LEVEL_DIFF_HIGH = 6;	//modSigns: vanilla 10
	default LEVEL_DIFF_DEADLY = 15;	//modSigns: vanilla 20
}

function GMIsMeleeStaminaAction(action : EStaminaActionType) : bool
{
	return action == ESAT_LightAttack || action == ESAT_HeavyAttack || action == ESAT_UsableItem
		|| action == ESAT_Parry || action == ESAT_Counterattack
		|| action == ESAT_Dodge || action == ESAT_Roll || action == ESAT_Evade
		|| action == ESAT_Sprint || action == ESAT_Jump;
}

// STAM-03: applies the option for the kind of action, and the cap.
function GMModStaminaCost(action : EStaminaActionType, isSign : bool, out cost : float)
{
	if(isSign)
		cost *= 1 + GMGetOptionFloat('GMGameplayOptions', 'GMSignStaminaCostMultiplier');
	else if(action == ESAT_Sprint || action == ESAT_Jump)
		cost *= 1 + GMGetOptionFloat('GMGameplayOptions', 'GMAgilityStaminaCostMultiplier');
	else if(GMIsMeleeStaminaAction(action))
		cost *= 1 + GMGetOptionFloat('GMGameplayOptions', 'GMMeleeStaminaCostMultiplier');
	cost = ClampF(cost, 0, 100);
}

// STAM-03, STAM-06: every stamina cost of an actor goes through here (DrainStamina, HasStaminaToUseAction, ...).
@wrapMethod(W3AbilityManager)
function GetStaminaActionCost(action : EStaminaActionType, out cost : float, out delay : float, optional fixedCost : float, optional fixedDelay : float, optional abilityName : name, optional dt : float, optional costMult : float)
{
	wrappedMethod(action, cost, delay, fixedCost, fixedDelay, abilityName, dt, costMult);
	if(GMIsAttackDrainSuppressed(owner, action))	// paid later, in DoAttack (actionStamina.ws)
	{
		cost = 0;
		delay = 0;
		return;
	}
	if(owner == GetWitcherPlayer())
	{
		if(action != ESAT_FixedValue)
			GMModStaminaCost(action, action == ESAT_Ability && IsSkillSign(SkillNameToEnum(abilityName)), cost);
		// SKL-05: Deflection halves the parry cost at level 3 with more than one enemy around
		if(action == ESAT_Parry)
			cost *= 1 - GetWitcherPlayer().GMDeflectionParryCostCut();
		// STAM-06: the "Stamina regen delay" option adds to every regen pause of Geralt's.
		delay = MaxF(delay + GMGetOptionFloat('GMGameplayOptions', 'GMStaminaDelay'), 0);
	}
	cost = ClampF(cost, 0, 100);	// STAM-03: legacy capped every actor's costs, not only Geralt's
}

// STAM-06: a delay read with GetStaminaActionDelay already includes the "Stamina regen delay"
// option, and DrainStamina(ESAT_FixedValue, cost, delay) adds it again (it goes through the
// wrapper above). Pass a delay read that way through this first, so the option counts once,
// as in legacy (which added it only in DrainStamina).
function GMFixedDrainDelay(delay : float) : float
{
	return delay - GMGetOptionFloat('GMGameplayOptions', 'GMStaminaDelay');
}

// STAM-03: the sign cost checked before casting (HasStaminaToUseSkill) and shown in the UI.
@wrapMethod(W3PlayerAbilityManager)
function GetSkillStaminaUseCost(skill : ESkill, optional isPerSec : bool) : float
{
	var cost : float;

	cost = wrappedMethod(skill, isPerSec);
	if(owner == GetWitcherPlayer() && IsSkillSign(skill))
		GMModStaminaCost(ESAT_Ability, true, cost);
	return cost;
}
