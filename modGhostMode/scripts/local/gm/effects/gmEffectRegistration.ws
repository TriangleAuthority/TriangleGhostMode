// Ghost Mode: registers the mod's effect types with the game's effect manager, by wrapping
// the vanilla registration functions instead of replacing them.

// STAM-01, STAM-02: the effect manager sizes its array to EET_EffectTypesSize; mod enum members come after it.
@wrapMethod(W3GameEffectManager)
function Initialize()
{
	wrappedMethod();

	if(effects.Size() <= (int)GMLastEffectType())
	{
		effects.Grow((int)GMLastEffectType() + 1 - effects.Size());
	}
}

// STAM-01, STAM-02: creates the cooldown effects.
@wrapMethod(W3GameEffectManager)
function HACK_NO_MEMORY_TO_COMPILE_CacheEffect_Part1(effect : EEffectType) : bool
{
	switch(effect)
	{
		// STAM-01
		case EET_GMAardCooldown :	effects[effect] = new W3GMEffect_AardCooldown in this;	return true;
		case EET_GMAxiiCooldown :	effects[effect] = new W3GMEffect_AxiiCooldown in this;	return true;
		case EET_GMIgniCooldown :	effects[effect] = new W3GMEffect_IgniCooldown in this;	return true;
		case EET_GMQuenCooldown :	effects[effect] = new W3GMEffect_QuenCooldown in this;	return true;
		case EET_GMYrdenCooldown :	effects[effect] = new W3GMEffect_YrdenCooldown in this;	return true;
		// STAM-02
		case EET_GMWhirlCooldown :	effects[effect] = new W3GMEffect_WhirlCooldown in this;	return true;
		case EET_GMRendCooldown :	effects[effect] = new W3GMEffect_RendCooldown in this;	return true;
		// SKL-07
		case EET_GMUndyingImmortal :	effects[effect] = new W3GMEffect_UndyingImmortal in this;	return true;
		case EET_GMUndyingCooldown :	effects[effect] = new W3GMEffect_UndyingCooldown in this;	return true;
		// SKL-09
		case EET_GMMeltArmorDebuff :	effects[effect] = new W3GMEffect_MeltArmorDebuff in this;	return true;
		case EET_GMMeltArmorTimer :	effects[effect] = new W3GMEffect_MeltArmorTimer in this;	return true;
		// MUT-10
		case EET_GMMutation5 :	effects[effect] = new W3GMEffect_Mutation5 in this;	return true;
		// MUT-12
		case EET_GMMutationTrigger :	effects[effect] = new W3GMPotion_MutationTrigger in this;	return true;
		// ARM-12
		case EET_GMKaerMorhenSetBonus :	effects[effect] = new W3GMEffect_KaerMorhenSetBonus in this;	return true;
	}
	return wrappedMethod(effect);
}

// STAM-01, STAM-02: effect names (XML) to types.
@wrapMethod
function HACK_NO_MEMORY_TO_COMPILE_EffectNameToType_Part1(effectName : name, out type : EEffectType, out abilityName : name) : bool
{
	switch(effectName)
	{
		// STAM-01
		case 'GMAardCooldownEffect' :	type = EET_GMAardCooldown;	abilityName = '';	return true;
		case 'GMAxiiCooldownEffect' :	type = EET_GMAxiiCooldown;	abilityName = '';	return true;
		case 'GMIgniCooldownEffect' :	type = EET_GMIgniCooldown;	abilityName = '';	return true;
		case 'GMQuenCooldownEffect' :	type = EET_GMQuenCooldown;	abilityName = '';	return true;
		case 'GMYrdenCooldownEffect' :	type = EET_GMYrdenCooldown;	abilityName = '';	return true;
		// STAM-02
		case 'GMWhirlCooldownEffect' :	type = EET_GMWhirlCooldown;	abilityName = '';	return true;
		case 'GMRendCooldownEffect' :	type = EET_GMRendCooldown;	abilityName = '';	return true;
		// SKL-07
		case 'GMUndyingImmortalEffect' :	type = EET_GMUndyingImmortal;	abilityName = '';	return true;
		case 'GMUndyingCooldownEffect' :	type = EET_GMUndyingCooldown;	abilityName = '';	return true;
		// SKL-09
		case 'GMMeltArmorDebuffEffect' :	type = EET_GMMeltArmorDebuff;	abilityName = '';	return true;
		case 'GMMeltArmorTimerEffect' :	type = EET_GMMeltArmorTimer;	abilityName = '';	return true;
		// MUT-10
		case 'GMMutation5Effect' :	type = EET_GMMutation5;	abilityName = '';	return true;
		// MUT-12
		case 'GMMutationTriggerEffect' :	type = EET_GMMutationTrigger;	abilityName = '';	return true;
		// ARM-12
		case 'GMKaerMorhenSetBonusEffect' :	type = EET_GMKaerMorhenSetBonus;	abilityName = '';	return true;
	}
	return wrappedMethod(effectName, type, abilityName);
}

// STAM-01, STAM-02: effect types to names.
@wrapMethod
function EffectTypeToName(effectType : EEffectType) : name
{
	switch(effectType)
	{
		// STAM-01
		case EET_GMAardCooldown :	return 'GMAardCooldownEffect';
		case EET_GMAxiiCooldown :	return 'GMAxiiCooldownEffect';
		case EET_GMIgniCooldown :	return 'GMIgniCooldownEffect';
		case EET_GMQuenCooldown :	return 'GMQuenCooldownEffect';
		case EET_GMYrdenCooldown :	return 'GMYrdenCooldownEffect';
		// STAM-02
		case EET_GMWhirlCooldown :	return 'GMWhirlCooldownEffect';
		case EET_GMRendCooldown :	return 'GMRendCooldownEffect';
		// SKL-07
		case EET_GMUndyingImmortal :	return 'GMUndyingImmortalEffect';
		case EET_GMUndyingCooldown :	return 'GMUndyingCooldownEffect';
		// SKL-09
		case EET_GMMeltArmorDebuff :	return 'GMMeltArmorDebuffEffect';
		case EET_GMMeltArmorTimer :	return 'GMMeltArmorTimerEffect';
		// MUT-10
		case EET_GMMutation5 :	return 'GMMutation5Effect';
		// MUT-12
		case EET_GMMutationTrigger :	return 'GMMutationTriggerEffect';
		// ARM-12
		case EET_GMKaerMorhenSetBonus :	return 'GMKaerMorhenSetBonusEffect';
	}
	return wrappedMethod(effectType);
}

// STAM-01, STAM-02: Ghost Mode's cooldowns are negative effects but must not be blocked by
// immunities to negative effects; neither is Adrenaline Rush's Recovery (MUT-07, legacy).
@wrapMethod(CActor)
function IsImmuneToBuff(effect : EEffectType) : bool
{
	if(GMIsSignCooldown(effect) || GMIsMeleeSpecialCooldown(effect))
		return false;
	if(effect == EET_Mutation7Debuff)	// MUT-07: Adrenaline Rush's Recovery (legacy)
		return false;
	return wrappedMethod(effect);
}

// SKL-07 (SKL audit, owner's F32 follow-up): legacy's "removeIfPresent fix". With removeIfPresent,
// an immunity to all negative effects also removes the negative effects already present (Undying's
// start, a bed, god mode, teleports and Ciri's specials call it so), except Mutation 7's debuff and
// Ghost Mode's cooldowns (the sign cooldowns, Whirl's and Rend's), as legacy's
// CActor.AddBuffImmunity_AllNegative; 5.x's (as 1.32's) only sets the immunity flag.
@wrapMethod(CActor)
function AddBuffImmunity_AllNegative(source : name, removeIfPresent : bool)
{
	var buffs : array<CBaseGameplayEffect>;
	var types : array<EEffectType>;
	var type : EEffectType;
	var i : int;

	wrappedMethod(source, removeIfPresent);
	if(!removeIfPresent)
		return;
	buffs = GetBuffs();
	for(i = 0; i < buffs.Size(); i += 1)
	{
		if(!buffs[i] || !buffs[i].IsNegative())
			continue;
		type = buffs[i].GetEffectType();
		if(type == EET_Mutation7Debuff || GMIsSignCooldown(type) || GMIsMeleeSpecialCooldown(type))
			continue;
		if(!types.Contains(type))
			types.PushBack(type);
	}
	for(i = 0; i < types.Size(); i += 1)
		RemoveAllBuffsOfType(types[i]);
}
