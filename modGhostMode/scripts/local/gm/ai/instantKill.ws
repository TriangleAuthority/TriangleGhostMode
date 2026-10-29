// AI-17: instant kills and LastBreath (docs/features/ai.md). Contract monsters (W3MonsterHuntNPC: the monster
// hunts' monsters, the Hakland mage, the Blood and Wine contract monsters) are immune to instant kills (legacy's
// check in ProcessInstantKill; legacy's InstantKillImmune tag on MonsterMHBoss, slice A2, names no ability, so
// HasAbility does not see it). An instant kill on a LastBreath monster (rotfiends) deals only the health above
// its LastBreath threshold instead of killing it: it fights on there, and the next hit sets off LastBreath (legacy:
// so the explosion cannot kill Geralt with the monster); a frozen one dies outright (EFX-09). Both rules are in the replaced
// ProcessInstantKill (skills/deadlyPrecision.ws). The explosion's damage is in effects/frozenRotfiend.ws.

// The damage that leaves the victim at its LastBreath threshold (legacy's GetLastBreathMaxAllowedDamage).
@addMethod(W3DamageManagerProcessor)
function GMGetLastBreathMaxAllowedDamage() : float
{
	return MaxF( 0, actorVictim.GetHealth() - actorVictim.GetMaxHealth() * CalculateAttributeValue( actorVictim.GetAttributeValue('lastbreath_threshold') ) );
}
