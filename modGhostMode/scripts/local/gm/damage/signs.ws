// DMG-06: sign intensity to a power bonus, with diminishing returns, for sign effects other than
// damage (legacy SignPowerStatToPowerBonus, characterStats.ws). Intensity above 100% counts in steps
// of 50%: +0.40, +0.35, +0.30, +0.25, +0.20, +0.15, +0.10, +0.10, +0.10, +0.05, so +0.75 at 200% and at
// most +2.0 from 600%. The callers (Aard's knockdown, Melt Armor, Axii, Quen, Yrden, Mutation 2, the
// skill and stats panels) come with SKL and MUT. See docs/features/dmg.md.
function GMSignPowerStatToPowerBonus( valueMult : float ) : float
{
	valueMult -= 1;	// the power stat's multiplier to sign intensity above 100%
	if(valueMult <= 0)
		return 0;
	return	ClampF(valueMult * 2 - 0, 0, 1) * 0.40 +
			ClampF(valueMult * 2 - 1, 0, 1) * 0.35 +
			ClampF(valueMult * 2 - 2, 0, 1) * 0.30 +
			ClampF(valueMult * 2 - 3, 0, 1) * 0.25 +
			ClampF(valueMult * 2 - 4, 0, 1) * 0.20 +
			ClampF(valueMult * 2 - 5, 0, 1) * 0.15 +
			ClampF(valueMult * 2 - 6, 0, 1) * 0.10 +
			ClampF(valueMult * 2 - 7, 0, 1) * 0.10 +
			ClampF(valueMult * 2 - 8, 0, 1) * 0.10 +
			ClampF(valueMult * 2 - 9, 0, 1) * 0.05;
}
