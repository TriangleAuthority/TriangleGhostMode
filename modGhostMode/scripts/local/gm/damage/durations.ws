// DMG-07: effect durations are not scaled by power. A negative effect lasts its duration x (1 - the
// target's resistance); the creator's attack power or sign intensity no longer lengthens it (legacy
// CBaseGameplayEffect.CalculateDuration). Recalculating a duration (when the target's resistance
// changes) starts from the initial duration: vanilla shrank it at every recalculation ("Fixed a bug
// with effect duration math", legacy). The Petri Philtre's level-3 bonus to sign effects in the same
// function comes with ALCH. See docs/features/dmg.md.
@replaceMethod(CBaseGameplayEffect)
function RecalcDuration()
{
	var prevDuration, points : float;

	if(duration == -1)
		return;


	target.GetResistValue(resistStat, points, resistance);


	prevDuration = duration;
	duration = initialDuration;	//modSigns: recalculate from the initial duration, not the already reduced one
	CalculateDuration();


	timeLeft = timeLeft * duration / prevDuration;
}

@replaceMethod(CBaseGameplayEffect)
function CalculateDuration(optional setInitialDuration : bool)
{
	var durationResistance : float;
	var min, max : SAbilityAttributeValue;

	if(duration == 0)
	{
		theGame.GetDefinitionsManager().GetAbilityAttributeValue(abilityName, 'duration', min, max);
		duration = CalculateAttributeValue(GetAttributeRandomizedValue(min, max));
	}

	if(setInitialDuration)
		initialDuration = duration;

	if( duration == -1)
		return;


	if(isNegative)
	{

		if(IsCriticalEffect(this))
			durationResistance = MinF(0.99f, resistance);
		else
			durationResistance = resistance;

		duration = MaxF(0, duration * (1 - durationResistance) );	//modSigns: the creator's power does not lengthen it (vanilla: initialDuration x power x (1 - resistance))
		LogEffects("BaseEffect.CalculateDuration: " + effectType + " duration with target resistance (" + NoTrailZeros(resistance) + ") and attacker power mul of (" + NoTrailZeros(creatorPowerStat.valueMultiplicative) + ") is " + NoTrailZeros(duration) + ", base was " + NoTrailZeros(initialDuration));
	}
}
