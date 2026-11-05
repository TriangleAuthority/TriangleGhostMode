// STAM-10 Exhaustion: paying from max stamina (new skill tree only; a new design by the project owner,
// 2026-11-04). See docs/features/stam.md.
//
// While the new tree is in force (GMIsNewTreeInForce) and the option "Exhaustion" is on, Geralt can make a
// light or heavy attack (on foot or on horseback), a dodge, a roll, an underwater evade or a counter without
// the stamina for it: his stamina pays what it has, and the shortfall lowers his MAX stamina by the same
// amount and drains adrenaline at the shortfall x "Adrenaline per stamina point" (default 0.03). Max stamina
// never goes below "Max stamina floor" (default 40); when the max above the floor or the adrenaline cannot
// cover the whole shortfall, the action is refused as before. Attacks are checked at the press and paid at
// the hit frame (STAM-03): the payment is computed again there, and what can no longer be paid is free.
// Every adrenaline gain from an attack paid this way (the hit, a kill, skills) is cancelled.
// Max stamina comes back only while stamina is full, at the regen the effect computes x "Max stamina regen"
// (default 0.4), and all of it on meditation; a character reset, a tree switch, a load with the classic tree
// or the option off, and New Game+ clear it.
//
// The lowered max is stacks of GMExhaustedMaxStamina (stamina -1 each, gm_stats.xml); the exact amount is
// kept as a float (gmExhDebt) and the stacks follow it rounded up, so a fraction of a point counts as one.
// The stacks are saved with Geralt's abilities; the fraction is not (a load reads the stacks).
// Not covered (as before): sprint, jump, Whirl, Rend, parries (partial at 0), bombs, the crossbow, items,
// signs (Rage Management's adrenaline casting unchanged) and finishers (free).

// ---- in force ----

// The tree in force: the profile Geralt has (SKL-02's facts set by the character reset), else the option.
function GMIsNewTreeInForce() : bool
{
	return GMIsNewTreeIncome();
}

// STAM-10 applies: new tree in force, the option on, Geralt playing.
function GMExhaustionOn() : bool
{
	var w : W3PlayerWitcher;

	w = GetWitcherPlayer();
	if(!w || thePlayer != w)
		return false;
	return GMIsNewTreeInForce() && GMGetOptionBool('GMGameplayOptions', 'GMExhaustion');
}

// The actions that can be paid from max stamina.
function GMExhaustionCovers(action : EStaminaActionType) : bool
{
	return action == ESAT_LightAttack || action == ESAT_HeavyAttack || action == ESAT_Dodge || action == ESAT_Roll
		|| action == ESAT_Evade || action == ESAT_Counterattack;
}

function GMExhaustionAbility() : name
{
	return 'GMExhaustedMaxStamina';
}

function GMExhaustionFloor() : float
{
	return MaxF(0, GMGetOptionFloat('GMGameplayOptions', 'GMExhaustionFloor'));
}

function GMExhaustionAdrenalineRate() : float
{
	return MaxF(0, GMGetOptionFloat('GMGameplayOptions', 'GMExhaustionAdrenaline'));
}

function GMExhaustionMaxRegenMult() : float
{
	return MaxF(0, GMGetOptionFloat('GMGameplayOptions', 'GMExhaustionMaxRegen'));
}

// ---- the lowered max ----

@addField(W3PlayerWitcher)
var gmExhDebt : float;			// max stamina owed (exact); the stacks are its whole points, rounded up

@addField(W3PlayerWitcher)
var gmExhPaid : float;			// total paid from max this session (for tests)

@addField(W3PlayerWitcher)
var gmExhLastPay : float;		// the last payment from max (for tests)

@addField(W3PlayerWitcher)
var gmExhNullified : int;		// adrenaline gains cancelled (for tests)

@addMethod(W3PlayerWitcher)
function GMExhStacks() : int
{
	return GetAbilityCount(GMExhaustionAbility());
}

// Max stamina without the stacks.
@addMethod(W3PlayerWitcher)
function GMFullMaxStamina() : float
{
	return GetStatMax(BCS_Stamina) + GMExhStacks();
}

// The stacks a debt makes: its whole points, rounded up, never below the floor.
@addMethod(W3PlayerWitcher)
function GMExhStacksFor(debt : float) : int
{
	if(debt <= 0.0001)
		return 0;
	return Min(CeilF(debt - 0.0001), Max(0, FloorF(GMFullMaxStamina() - GMExhaustionFloor())));
}

// The exact debt; after a load (the fraction is not saved) or an outside change, the stacks.
@addMethod(W3PlayerWitcher)
function GMExhDebt() : float
{
	if(GMExhStacksFor(gmExhDebt) != GMExhStacks())
		gmExhDebt = GMExhStacks();
	return gmExhDebt;
}

// Max stamina that can still be paid: above the floor, less what is owed.
@addMethod(W3PlayerWitcher)
function GMExhMaxAvailable() : float
{
	return MaxF(0, GMFullMaxStamina() - GMExhaustionFloor() - GMExhDebt());
}

@addMethod(W3PlayerWitcher)
function GMExhSetDebt(debt : float)
{
	var target, current : int;

	gmExhDebt = MaxF(0, debt);
	target = GMExhStacksFor(gmExhDebt);
	current = GMExhStacks();
	if(target > current)
		AddAbilityMultiple(GMExhaustionAbility(), target - current);
	else if(target < current)
		RemoveAbilityMultiple(GMExhaustionAbility(), current - target);
	if(target == 0)
		gmExhDebt = 0;
}

// Clears the lowered max (reset, tree switch, meditation, New Game+, a load without the feature).
@addMethod(W3PlayerWitcher)
function GMExhClear()
{
	gmExhDebt = 0;
	if(GMExhStacks() > 0)
		RemoveAbilityMultiple(GMExhaustionAbility(), GMExhStacks());
}

// ---- the check (at the press) ----

// True when the action can be made only by paying from max: stamina short, the whole shortfall payable
// from max above the floor and from adrenaline.
@addMethod(W3PlayerWitcher)
function GMExhCanPay(action : EStaminaActionType, abilityName : name, dt : float, multiplier : float) : bool
{
	var cost, shortfall : float;

	if(!GMExhaustionOn() || !GMExhaustionCovers(action))
		return false;
	if(multiplier == 0)
		multiplier = 1;
	cost = multiplier * GetStaminaActionCost(action, abilityName, dt);
	shortfall = cost - GetStat(BCS_Stamina);
	if(shortfall <= 0)
		return false;
	return shortfall <= GMExhMaxAvailable() + 0.0001 && GetStat(BCS_Focus) + 0.0001 >= shortfall * GMExhaustionAdrenalineRate();
}

// A covered action Geralt cannot pay with stamina passes when max stamina and adrenaline can pay the rest;
// the wrapped check (which raises the "stamina needed" indication) runs only otherwise.
@wrapMethod(CR4Player)
function HasStaminaToUseAction(action : EStaminaActionType, optional abilityName : name, optional dt :float, optional multiplier : float) : bool
{
	var w : W3PlayerWitcher;

	w = GetWitcherPlayer();
	if(w && this == w && w.GMExhCanPay(action, abilityName, dt, multiplier))
		return true;
	return wrappedMethod(action, abilityName, dt, multiplier);
}

// ---- the payment (at the drain) ----

// Pays a shortfall from max stamina and adrenaline, as far as both reach now; the rest is free.
@addMethod(W3PlayerWitcher)
function GMExhPay(action : EStaminaActionType, shortfall : float)
{
	var pay, rate : float;

	rate = GMExhaustionAdrenalineRate();
	pay = MinF(shortfall, GMExhMaxAvailable());
	if(rate > 0)
		pay = MinF(pay, GetStat(BCS_Focus) / rate);
	if(pay <= 0)
		return;
	GMExhSetDebt(GMExhDebt() + pay);
	if(rate > 0)
		DrainFocus(pay * rate);
	gmExhPaid += pay;
	gmExhLastPay = pay;
	// the attack's adrenaline gains are cancelled (cleared when its hits are done, GMExhAttackEnded)
	if(action == ESAT_LightAttack || action == ESAT_HeavyAttack)
		gmExhNullGainUntil = theGame.GetEngineTimeAsSeconds() + 3.0;
	else if(action == ESAT_Counterattack)
		gmExhNullGainUntil = theGame.GetEngineTimeAsSeconds() + 2.0;
	LogChannel('GMStamina', "STAM-10 " + NameToString(StaminaActionTypeToName(action)) + ": " + NoTrailZeros(pay) + " of " + NoTrailZeros(shortfall) + " paid from max stamina (now " + NoTrailZeros(GetStatMax(BCS_Stamina))
		+ " of " + NoTrailZeros(GMFullMaxStamina()) + "), adrenaline " + NoTrailZeros(GetStat(BCS_Focus)));
}

// The real drain: the shortfall is read before the wrapped drain empties stamina (attacks are paid at the hit
// frame, STAM-03; the buffer's suppressed drain costs 0, so it has no shortfall).
@wrapMethod(W3PlayerAbilityManager)
function DrainStamina(action : EStaminaActionType, optional fixedCost : float, optional fixedDelay : float, optional abilityName : name, optional dt : float, optional costMult : float) : float
{
	var w : W3PlayerWitcher;
	var cost, delay, shortfall, ret : float;

	w = (W3PlayerWitcher)owner;
	shortfall = 0;
	if(w && w == GetWitcherPlayer() && GMExhaustionCovers(action) && GMExhaustionOn())
	{
		GetStaminaActionCost(action, cost, delay, fixedCost, fixedDelay, abilityName, dt, costMult);
		shortfall = cost - GetStat(BCS_Stamina);
	}
	ret = wrappedMethod(action, fixedCost, fixedDelay, abilityName, dt, costMult);
	if(shortfall > 0)
		w.GMExhPay(action, shortfall);
	return ret;
}

// ---- no adrenaline from an attack paid from max (MUT-07's pattern) ----

@addField(W3PlayerWitcher)
var gmExhNullGainUntil : float;		// set when an attack or counter is paid from max

@addField(W3PlayerWitcher)
var gmExhAttackCtx : int;			// inside Geralt's DoAttack (on foot)

@addField(W3PlayerWitcher)
var gmExhOwnActionCtx : int;		// inside the processing of one of Geralt's actions

@addMethod(W3PlayerWitcher)
function GMExhAttackContext(entering : bool)
{
	if(entering)
		gmExhAttackCtx += 1;
	else if(gmExhAttackCtx > 0)
		gmExhAttackCtx -= 1;
}

@addMethod(W3PlayerWitcher)
function GMExhOwnActionContext(entering : bool)
{
	if(entering)
		gmExhOwnActionCtx += 1;
	else if(gmExhOwnActionCtx > 0)
		gmExhOwnActionCtx -= 1;
}

// The attack's hits are done: its window closes, except for Phantom Weapon's delayed heavy hit (a timer
// the next frame), which keeps it half a second.
@addMethod(W3PlayerWitcher)
function GMExhAttackEnded(phantomHeavy : bool)
{
	if(gmExhNullGainUntil <= theGame.GetEngineTimeAsSeconds())
		return;
	if(phantomHeavy)
		gmExhNullGainUntil = theGame.GetEngineTimeAsSeconds() + 0.5;
	else
		gmExhNullGainUntil = 0;
}

@addMethod(W3PlayerWitcher)
function GMExhNullifiesGain() : bool
{
	return gmExhNullGainUntil > theGame.GetEngineTimeAsSeconds() && (gmExhAttackCtx > 0 || gmExhOwnActionCtx > 0);
}

@wrapMethod(CR4Player)
function DoAttack(animData : CPreAttackEventData, weaponId : SItemUniqueId, parried : bool, countered : bool, parriedBy : array<CActor>, attackAnimationName : name, hitTime : float)
{
	var w : W3PlayerWitcher;
	var phantomHeavy : bool;

	w = GetWitcherPlayer();
	if(w && this == w)
	{
		phantomHeavy = GetInventory().ItemHasTag(weaponId, 'PhantomWeapon') && IsHeavyAttack(attackActionName);
		w.GMExhAttackContext(true);
	}
	wrappedMethod(animData, weaponId, parried, countered, parriedBy, attackAnimationName, hitTime);
	if(w && this == w)
	{
		w.GMExhAttackContext(false);
		w.GMExhAttackEnded(phantomHeavy);
	}
}

// Horseback: the swing (latent) waits for its animation and deals its hits inside; they go through
// ProcessAction, where the context below sees them.
@wrapMethod(W3VehicleCombatManagerStateSwordAttack)
function DoAttack()
{
	var w : W3PlayerWitcher;

	w = GetWitcherPlayer();
	wrappedMethod();
	if(w && rider == w)
		w.GMExhAttackEnded(false);
}

@wrapMethod(W3DamageManagerProcessor)
function ProcessAction(act : W3DamageAction)
{
	var w : W3PlayerWitcher;
	var mine : bool;

	w = GetWitcherPlayer();
	mine = act && w && act.attacker == w;
	if(mine)
		w.GMExhOwnActionContext(true);
	wrappedMethod(act);
	if(mine)
		w.GMExhOwnActionContext(false);
}

// Positive adrenaline gains are cancelled while an attack paid from max is processed; losses pass.
@wrapMethod(W3PlayerAbilityManager)
function GainStat(stat : EBaseCharacterStats, amount : float)
{
	var w : W3PlayerWitcher;

	w = (W3PlayerWitcher)owner;
	if(stat == BCS_Focus && amount > 0 && w && w.GMExhNullifiesGain())
	{
		w.gmExhNullified += 1;
		return;
	}
	wrappedMethod(stat, amount);
}

// ---- max stamina regen (called from the replaced W3Effect_AutoStaminaRegen.OnUpdate, staminaRegen.ws) ----

// Max stamina's regen per second: the combat regen, in and out of combat (the out-of-combat rate, 100% of max
// a second, would restore it within seconds of a fight; the drain carries between fights instead, owner,
// 2026-11-04): the combat attribute with the combat option, halved while guarding, with the armor modifier.
function GMExhaustionRegenPoints(w : W3PlayerWitcher) : float
{
	var v : SAbilityAttributeValue;
	var points : float;

	v = w.GetAttributeValue('staminaRegen');
	GMModStaminaRegenValue('staminaRegen', v);
	if(w.IsGuarded())
	{
		v.valueAdditive *= 0.5;
		v.valueMultiplicative *= 0.5;
	}
	points = v.valueAdditive + v.valueMultiplicative * w.GetStatMax(BCS_Stamina);
	return points * (1 + w.CalculatedArmorStaminaRegenBonus());
}

// While stamina is full (at the lowered max), max stamina comes back at the combat regen x the option.
// A paused regen (STAM-06) does not update, so it pauses this too.
@addMethod(W3Effect_AutoStaminaRegen)
function GMExhaustionRegen(dt : float)
{
	var w : W3PlayerWitcher;
	var regenPoints : float;

	w = GetWitcherPlayer();
	if(!w || target != w || w.GMExhStacks() <= 0 || target.GetStatPercents(BCS_Stamina) < 1)
		return;
	regenPoints = GMExhaustionRegenPoints(w);
	if(regenPoints <= 0)
		return;
	w.GMExhSetDebt(w.GMExhDebt() - regenPoints * dt * GMExhaustionMaxRegenMult());
}

// The regen keeps running while max stamina is lowered.
function GMExhaustionKeepsRegen(target : CActor) : bool
{
	var w : W3PlayerWitcher;

	w = GetWitcherPlayer();
	return w && target == w && w.GMExhStacks() > 0;
}

// ---- clearing ----

// Meditation restores max stamina (leaving combat does not).
@wrapMethod(W3PlayerWitcher)
function MeditationRestoring(simulatedTime : float)
{
	wrappedMethod(simulatedTime);
	GMExhClear();
}

// A character reset (also how the tree is switched) clears it.
@wrapMethod(W3PlayerWitcher)
function GMResetCharacter() : bool
{
	var ret : bool;

	ret = wrappedMethod();
	if(ret)
		GMExhClear();
	return ret;
}

@wrapMethod(W3PlayerWitcher)
function NewGamePlusInitialize()
{
	wrappedMethod();
	GMExhClear();
}

// At a load: cleared when the feature is not in force (classic profile, option off); else the regen runs
// again, so a lowered max comes back.
@wrapMethod(W3PlayerWitcher)
function OnSpawned(spawnData : SEntitySpawnData)
{
	var ret : bool;

	ret = wrappedMethod(spawnData);
	GMExhOnLoad();
	return ret;
}

@addMethod(W3PlayerWitcher)
function GMExhOnLoad()
{
	if(GMExhStacks() <= 0)
		return;
	if(!GMIsNewTreeInForce() || !GMGetOptionBool('GMGameplayOptions', 'GMExhaustion'))
		GMExhClear();
	else
		StartStaminaRegen();
}

// ---- character panel ----

// The stamina line's maximum reads "<lowered max> (<full max>)" while max stamina is lowered.
@wrapMethod
function AddCharacterStat(tag : string, varKey : name, locKey : string, iconTag : string, toArray : CScriptedFlashArray, flashMaster : CScriptedFlashValueStorage) : CScriptedFlashObject
{
	var statObject : CScriptedFlashObject;
	var w : W3PlayerWitcher;

	statObject = wrappedMethod(tag, varKey, locKey, iconTag, toArray, flashMaster);
	w = GetWitcherPlayer();
	if(varKey == 'stamina' && w && thePlayer == w && w.GMExhStacks() > 0)
		statObject.SetMemberFlashString("maxValue", GMExhaustionPanelMax());
	return statObject;
}

function GMExhaustionPanelMax() : string
{
	var w : W3PlayerWitcher;

	w = GetWitcherPlayer();
	return (string)RoundMath(w.GetStatMax(BCS_Stamina)) + " (" + (string)RoundMath(w.GMFullMaxStamina()) + ")";
}
