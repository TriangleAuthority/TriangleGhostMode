// ALCH-02: potion-wide rules. Potions (not decoctions) stack: drinking a potion that is active adds its
// duration (time left and total) instead of replacing it, and its own CumulateWith runs; decoctions refresh.
// The owner's DL12 fix of legacy's stacking: a weaker dose drunk after a stronger one adds its duration and
// the stronger tier stays (legacy's ability swap let a lower tier replace a higher one). No drinking during
// a special sword attack (Whirl, Rend) or while channelling a sign.
// ALCH-08: the bear pheromone befriends grizzly bears too; the bear and nekker pheromones and Pops' Antidote
// (every fact potion) play the drinking sound.
// See docs/features/alch.md.

// 5.x body; changes marked //modSigns. this = the new dose, e = the running effect.
@replaceMethod(CBaseGameplayEffect)
function GetSelfInteraction( e : CBaseGameplayEffect) : EEffectInteract
{
	var thisVal, otherVal : float;


	//modSigns: removed Side Effects' override for potions from alchemy_s4 (SKL-13: Prolonged Effects in its place)


	if(sourceName != e.sourceName)
	{
		return EI_Undefined;
	}

	thisVal = GetEffectStrength();
	otherVal = e.GetEffectStrength();

	if(thisVal > otherVal)
	{
		return EI_Override;
	}
	else if(thisVal < otherVal)
	{
		return EI_Pass;
	}
	else
	{
		if(!((W3Mutagen_Effect)this) && isPotionEffect && e.isPotionEffect)	//modSigns: ALCH-02, potions cumulate
			return EI_Cumulate;	//modSigns

		if(timeLeft <= 0 && IsCriticalEffect(this))
			return EI_Pass;

		if(timeLeft > e.timeLeft)
			return EI_Override;

		return EI_Cumulate;
	}
}

// 5.x body; changes marked //modSigns. this = the running effect, effect = the new dose.
@replaceMethod(CBaseGameplayEffect)
function CumulateWith(effect: CBaseGameplayEffect)
{
	var keepTier : bool;	//modSigns

	if(!((W3Mutagen_Effect)this) && isPotionEffect && effect.isPotionEffect)	//modSigns: ALCH-02, potions stack their durations
	{	//modSigns
		timeLeft += effect.timeLeft;	//modSigns
		duration += effect.duration;	//modSigns
		initialDuration = duration;	//modSigns
		keepTier = effect.GetBuffLevel() < GetBuffLevel();	//modSigns: DL12, a weaker dose keeps the stronger tier
	}	//modSigns
	else if((W3Effect_WellHydrated)this && effect.GetBuffLevel() < GetBuffLevel())	//modSigns: FOOD-03, the owner's DF6: a weaker drink adds its time
	{	//modSigns
		timeLeft += effect.timeLeft;	//modSigns
		duration += effect.duration;	//modSigns
		initialDuration = duration;	//modSigns
		keepTier = true;	//modSigns: the stronger tier stays
	}	//modSigns
	else	//modSigns
	{	//modSigns
	timeLeft = effect.timeLeft;
	duration = effect.duration;
	}	//modSigns
	isPotionEffect = effect.isPotionEffect;
	creatorHandle = effect.creatorHandle;
	sourceName = effect.sourceName;

	if(abilityName != effect.abilityName && !dontAddAbilityOnTarget && !keepTier)	//modSigns: DL12
	{
		target.RemoveAbility(abilityName);
		target.AddAbility(effect.abilityName);
	}

	if(!keepTier)	//modSigns: DL12
	abilityName = effect.abilityName;

	if(isOnPlayer)
	{
		vibratePadLowFreq = effect.vibratePadLowFreq;
		vibratePadHighFreq = effect.vibratePadHighFreq;

		if(vibratePadLowFreq > 0 || vibratePadHighFreq > 0)
			theGame.OverrideRumbleDuration(vibratePadLowFreq, vibratePadHighFreq, timeLeft);
	}


	if(isOnPlayer && IsNameValid(onAddedSound))
		theSound.SoundEvent(onAddedSound);
}

// No drinking in the middle of a special sword attack or while channelling a sign (legacy's check).
@wrapMethod(W3PlayerWitcher)
function DrinkPotionFromSlot(slot : EEquipmentSlots)
{
	var gmItem : SItemUniqueId;

	if(GMCannotDrinkNow())
	{
		DisplayHudMessage(GetLocStringByKeyExt( "menu_cannot_perform_action_now" ));
		return;
	}
	// FOOD-05: alcohol and raw food refused when Geralt is too toxic for them (legacy).
	GetItemEquippedOnSlot(slot, gmItem);
	if(GMFoodTooToxic(gmItem))
	{
		SendToxicityTooHighMessage();
		return;
	}
	wrappedMethod(slot);
}

@addMethod(W3PlayerWitcher)
function GMCannotDrinkNow() : bool
{
	var actionType : int;

	if(!IsInCombatAction())
		return false;
	actionType = (int)GetBehaviorVariable('combatActionType');
	return actionType == (int)CAT_SpecialAttack || actionType == (int)CAT_CastSign && IsCurrentSignChanneled();
}

// ALCH-08: grizzly bears are befriended too.
@wrapMethod(W3Potion_PheromoneBear)
function OnEffectAdded(optional customParams : W3BuffCustomParams)
{
	var ret : bool;

	ret = wrappedMethod(customParams);
	theGame.SetGlobalAttitude( 'AG_grizzly_bear', 'player', AIA_Friendly );
	return ret;
}

@wrapMethod(W3Potion_PheromoneBear)
function OnEffectRemoved()
{
	var ret : bool;

	ret = wrappedMethod();
	theGame.SetGlobalAttitude( 'AG_grizzly_bear', 'player', AIA_Hostile );
	return ret;
}

// ALCH-08: the drinking sound (legacy's onStartSound in the effect definitions; the first definition of an
// effect wins, so a DLC cannot add the attribute: the class default is used where the XML has none).
class  W3Potion_PheromoneBear extends W3Potion_Pheromone
{
	default onAddedSound = 'gui_potion_activation';	//modSigns
}

class  W3Potion_PheromoneNekker extends W3Potion_Pheromone
{
	default onAddedSound = 'gui_potion_activation';	//modSigns
}

class W3Potion_Fact extends CBaseGameplayEffect
{
	default onAddedSound = 'gui_potion_activation';	//modSigns
}

// ALCH-08: the pheromone formulas are of the quest type in legacy, so Acquired Tolerance does not count them.
function GMIsPheromoneRecipe(recipeName : name) : bool
{
	return recipeName == 'Recipe for Bear Pheromone Potion 1' || recipeName == 'Recipe for Drowner Pheromone Potion 1'
		|| recipeName == 'Recipe for Nekker Pheromone Potion 1';
}
