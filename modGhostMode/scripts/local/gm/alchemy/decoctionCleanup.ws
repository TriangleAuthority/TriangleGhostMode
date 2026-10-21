// ALCH-09 to ALCH-13: a load-time cleanup of the decoctions' runtime abilities (the owner's instruction,
// 2026-10-20). Stacks are combat-only (a save is never made in combat), so on load none should be on
// Geralt; a save from before the port may carry 5.x's (Wyvern's per-hit stacks, Alghoul's ability,
// Forktail's boost, Griffin's stacking resistances, Werewolf's night ability, Grave Hag's uncapped stacks).
// Decoctions whose ability now belongs on Geralt (Elemental, Griffin: 5.x left them off) get it back once.
// See docs/features/alch.md.

@wrapMethod(W3PlayerWitcher)
function OnSpawned(spawnData : SEntitySpawnData)
{
	wrappedMethod(spawnData);
	GMCleanupDecoctionAbilities();
}

@addMethod(W3PlayerWitcher)
function GMCleanupDecoctionAbilities()
{
	GMClearDecoctionStacks();
	RemoveAbilityAll('Mutagen24Effect');
	RemoveAbilityAll('Mutagen27Effect');
	RemoveAbilityAll('Mutagen20Effect');
	if(HasBuff(EET_Mutagen27))
		AddAbility('Mutagen27Effect', false);
	if(HasBuff(EET_Mutagen20))
		AddAbility('Mutagen20Effect', false);
	if(HasBuff(EET_Mutagen23))
		((W3Mutagen23_Effect)GetBuff(EET_Mutagen23)).GMAddM23Abilities();
	else
		RemoveAbilityAll('Mutagen23Effect');
	if(HasBuff(EET_Mutagen09))
		((W3Mutagen09_Effect)GetBuff(EET_Mutagen09)).GMRecalcM09Bonus();
	if(HasBuff(EET_Mutagen25))
		((W3Mutagen25_Effect)GetBuff(EET_Mutagen25)).GMRecalcM25Bonus();
}
