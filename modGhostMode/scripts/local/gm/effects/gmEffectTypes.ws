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
	EET_GMMeltArmorTimer,
	// MUT-10: Mutated Skin's damage over time
	EET_GMMutation5,
	// MUT-12: the Mutation Catalyst's potion effect
	EET_GMMutationTrigger,
	// ARM-12: the Kaer Morhen set's stamina regen
	EET_GMKaerMorhenSetBonus,
	// ENCH-05: Invigoration
	EET_GMRuneword4,
	// ENCH-09: Prolongation
	EET_GMRuneword11,
	// SWD-06: Iris
	EET_GMPhantomWeapon
}

// Last Ghost Mode effect type: keep it pointing at the last member above.
function GMLastEffectType() : EEffectType
{
	return EET_GMPhantomWeapon;
}

function GMIsModEffectType(effect : EEffectType) : bool
{
	return (int)effect > (int)EET_EffectTypesSize && (int)effect <= (int)GMLastEffectType();
}
