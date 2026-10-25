// EFX-06: critical effects end on time (bugfix 173, docs/features/efx.md). A critical effect
// (knockdown, heavy knockdown, ragdoll, critical poison, burning, stagger, hypnosis, ...) ends when its
// time runs out, whether or not its animation is still playing; the request to stop the animation is
// made at its removal (W3CriticalEffect.OnEffectRemoved, 5.x's, and below for the knockdowns and the
// ragdoll, with the in-air flag). In 1.32 and 5.x an expired effect asks for the animation to stop and
// stays active until it does, so an interrupted animation left it, and its damage over time, running.
// Kept with legacy's rewrite (PX4): no wait for a knockdown in mid-air to land, no 'DisableFinisher'
// signal at the end. 5.x bodies; changes marked //modSigns.

@replaceMethod(W3CriticalEffect)
function OnTimeUpdated(deltaTime : float)
{
	if ( isActive )
	{
		timeActive += deltaTime;
	}

	if(pauseCounters.Size() == 0)
	{
		if( duration != -1 )
			timeLeft -= deltaTime;
		OnUpdate(deltaTime);
	}

	if(duration != -1 && timeLeft <= 0 && isActive)	//modSigns: EFX-06, ends on time
	{	//modSigns
		isActive = false;	//modSigns
	}	//modSigns
	//modSigns: removed the wait for the animation to stop, and the DisableFinisher signal
}

@replaceMethod(W3CriticalDOTEffect)
function OnTimeUpdated(deltaTime : float)
{
	if(pauseCounters.Size() == 0)
	{
		if( duration != -1 )
			timeLeft -= deltaTime;
		OnUpdate(deltaTime);


		if(!this)
			return;
	}

	if(duration != -1 && timeLeft <= 0 && isActive)	//modSigns: EFX-06, ends on time
	{	//modSigns
		isActive = false;	//modSigns
	}	//modSigns
	//modSigns: removed the wait for the animation to stop, the DisableFinisher signal and the dead-target branch
}

@replaceMethod(W3Effect_Knockdown)
function OnTimeUpdated(deltaTime : float)
{
	var mac : CMovingPhysicalAgentComponent;
	var isInAir : bool;

	if ( isActive )
	{
		timeActive += deltaTime;
	}

	if(pauseCounters.Size() == 0)
	{
		if( duration != -1 )
			timeLeft -= deltaTime;
		OnUpdate(deltaTime);
	}

	if(duration != -1 && timeLeft <= 0 && isActive)	//modSigns: EFX-06, ends on time
	{	//modSigns
		isActive = false;	//modSigns
	}	//modSigns
	//modSigns: removed the wait for the animation to stop and for the target to land
}

@replaceMethod(W3Effect_HeavyKnockdown)
function OnTimeUpdated(deltaTime : float)
{
	var mac : CMovingPhysicalAgentComponent;
	var isInAir : bool;

	if ( isActive )
	{
		timeActive += deltaTime;
	}

	if(pauseCounters.Size() == 0)
	{
		if( duration != -1 )
			timeLeft -= deltaTime;
		OnUpdate(deltaTime);
	}

	if(duration != -1 && timeLeft <= 0 && isActive)	//modSigns: EFX-06, ends on time
	{	//modSigns
		isActive = false;	//modSigns
	}	//modSigns
	//modSigns: removed the wait for the animation to stop and for the target to land
}

@replaceMethod(W3Effect_Ragdoll)
function OnTimeUpdated(deltaTime : float)
{
	var mac : CMovingPhysicalAgentComponent;
	var isInAir : bool;

	if ( isActive )
	{
		timeActive += deltaTime;
	}

	if(pauseCounters.Size() == 0)
	{
		if( duration != -1 )
			timeLeft -= deltaTime;
		OnUpdate(deltaTime);
	}

	if(duration != -1 && timeLeft <= 0 && isActive)	//modSigns: EFX-06, ends on time
	{	//modSigns
		isActive = false;	//modSigns
	}	//modSigns
	//modSigns: removed the wait for the animation to stop and for the target to land
}

// EFX-06: the animation's stop asked at removal, with the in-air flag (after 5.x's own request
// without it in W3CriticalEffect.OnEffectRemoved), as legacy.
@wrapMethod(W3Effect_Knockdown)
function OnEffectRemoved()
{
	wrappedMethod();
	if(this == target.GetCurrentlyAnimatedCS())
		target.RequestCriticalAnimStop(target.IsInAir());
}

@wrapMethod(W3Effect_HeavyKnockdown)
function OnEffectRemoved()
{
	wrappedMethod();
	if(this == target.GetCurrentlyAnimatedCS())
		target.RequestCriticalAnimStop(target.IsInAir());
}

// The ragdoll does not define OnEffectRemoved in 5.x: a scope-based override of the inherited event
// (legacy's new event).
class W3Effect_Ragdoll extends W3CriticalEffect
{
	event OnEffectRemoved()
	{
		super.OnEffectRemoved();	//modSigns

		if(this == target.GetCurrentlyAnimatedCS())	//modSigns
			target.RequestCriticalAnimStop(target.IsInAir());	//modSigns
	}
}
