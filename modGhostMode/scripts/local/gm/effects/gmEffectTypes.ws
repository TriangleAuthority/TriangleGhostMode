// Ghost Mode: effect types added to the vanilla EEffectType enum (enum extension, needs the
// precompiled blob). Mod enum members come after the vanilla EET_EffectTypesSize, so the effect
// manager's array is grown for them in gmEffectRegistration.ws.

enum EEffectType
{
	// STAM-01: sign cooldowns
	EET_GMAardCooldown,
	EET_GMAxiiCooldown,
	EET_GMIgniCooldown,
	EET_GMQuenCooldown,
	EET_GMYrdenCooldown,
	// STAM-02: Whirl and Rend cooldowns
	EET_GMWhirlCooldown,
	EET_GMRendCooldown,
	// SKL-07: Undying
	EET_GMUndyingImmortal,
	EET_GMUndyingCooldown,
	// SKL-09: Melt Armor
	EET_GMMeltArmorDebuff,
	EET_GMMeltArmorTimer
}

// Last Ghost Mode effect type: keep it pointing at the last member above.
function GMLastEffectType() : EEffectType
{
	return EET_GMMeltArmorTimer;
}

function GMIsModEffectType(effect : EEffectType) : bool
{
	return (int)effect > (int)EET_EffectTypesSize && (int)effect <= (int)GMLastEffectType();
}
