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
	}
	return wrappedMethod(effectType);
}

// STAM-01, STAM-02: Ghost Mode's cooldowns are negative effects but must not be blocked by
// immunities to negative effects.
@wrapMethod(CActor)
function IsImmuneToBuff(effect : EEffectType) : bool
{
	if(GMIsSignCooldown(effect) || GMIsMeleeSpecialCooldown(effect))
		return false;
	return wrappedMethod(effect);
}
