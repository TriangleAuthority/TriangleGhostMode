// EFX-03: freezing pauses damage over time (docs/features/efx.md). While an enemy is frozen, its
// bleeding, poison and burning stop ticking and their timers stop; they resume when the freeze ends
// (changelist 856, legacy's W3Effect_Frozen and W3EffectManager). 5.x pauses only regeneration.

// EFX-03: every damage-over-time effect paused by the source (legacy's body).
@addMethod(W3EffectManager)
function PauseAllDoTEffects(sourceName : name, optional singleLock : bool, optional duration : float, optional useMaxDuration : bool)
{
	var i : int;
	var dotEffect : W3DamageOverTimeEffect;

	for(i=0; i<effects.Size(); i+=1)
	{
		dotEffect = (W3DamageOverTimeEffect)effects[i];
		if(dotEffect)
			PauseEffects(dotEffect.GetEffectType(), sourceName, singleLock, duration, useMaxDuration);
	}
}

// EFX-03: every damage-over-time effect's pause by the source lifted (legacy's body).
@addMethod(W3EffectManager)
function ResumeAllDoTEffects(sourceName : name)
{
	var i : int;
	var dotEffect : W3DamageOverTimeEffect;

	for(i=0; i<effects.Size(); i+=1)
	{
		dotEffect = (W3DamageOverTimeEffect)effects[i];
		if(dotEffect)
			ResumeEffects(dotEffect.GetEffectType(), sourceName);
	}
}

// EFX-03: legacy pauses them after 5.x's regeneration pause, which a freeze that fails (the target in
// mid-air: the effect made inactive) skips.
@wrapMethod(W3Effect_Frozen)
function OnEffectAdded(optional customParams : W3BuffCustomParams)
{
	var ret : bool;

	ret = wrappedMethod(customParams);
	if(isActive)
		effectManager.PauseAllDoTEffects('FrozenEffect');
	return ret;
}

// EFX-03: they resume when the freeze ends (legacy: after 5.x's regeneration resume).
@wrapMethod(W3Effect_Frozen)
function OnEffectRemoved()
{
	var ret : bool;

	ret = wrappedMethod();
	effectManager.ResumeAllDoTEffects('FrozenEffect');
	return ret;
}
