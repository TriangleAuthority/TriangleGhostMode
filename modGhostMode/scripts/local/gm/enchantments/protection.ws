// ENCH-15: Protection (Glyphword 17) and Entanglement (Glyphword 15) as legacy (changelist 1000-1004).
// Protection: entering combat with no Quen up gives a free Quen (no stamina, adrenaline or cooldown)
// with +100% Quen intensity (W3PlayerWitcher.OnCombatStart in mutations/combatStart.ws; the intensity
// in skills/quen.ws GetSignStats). Vanilla's 1.32 chance roll and stamina restore are gone.
// Entanglement: the Magic Turret's hit places a Magic Trap of 2.5 yd, 5 s and 35% slowdown, unaffected
// by Yrden Intensity and upgrades (skills/yrden.ws). See docs/features/ench.md.

// Set on the Quen Protection casts; GetSignStats adds the bonus once and clears it.
@addField(W3QuenEntity)
var gmGlyphword17Cast : bool;

@addMethod(W3QuenEntity)
function GMSetGlyphword17Cast()
{
	gmGlyphword17Cast = true;
}
