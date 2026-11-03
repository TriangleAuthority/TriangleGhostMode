// FIX-07: Vitality regeneration resumed at every load after a fistfight ("Fixed a rare bug with HP regen being blocked
// by fistfight minigame and never unblocked again ... saving and reloading a game should now restart HP regen
// properly", changelist 139-142). The fistfight pauses it with the source 'FistFightMinigame' (CActor's
// OnStartFistfightMinigame) and resumes it at its end; rarely the resume never comes. See docs/features/fix.md.
@wrapMethod(W3PlayerWitcher)
function OnSpawned(spawnData : SEntitySpawnData)
{
	wrappedMethod(spawnData);
	GMFixResumeFistfightRegen();
}

// FIX-07: legacy's line, in a method so a test can run it.
@addMethod(W3PlayerWitcher)
function GMFixResumeFistfightRegen()
{
	ResumeHPRegenEffects('FistFightMinigame');
}
