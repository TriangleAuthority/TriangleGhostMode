// EFX-10: caught in a spider web (docs/features/efx.md). An arachas's web (EET_Tangled) on Geralt
// aborts the sign he is casting (bugfix 181, legacy's W3Effect_Tangled.OnEffectAdded). 5.x releases
// only the CastSignHold input. Legacy also releases the sign-select keys of its instant-casting option
// (ForceDeactivateCastSignHold), which comes with that option (OPT, PX9).
@wrapMethod(W3Effect_Tangled)
function OnEffectAdded(optional customParams : W3BuffCustomParams)
{
	var result : bool;

	result = wrappedMethod(customParams);
	if(isOnPlayer)
		thePlayer.AbortSign();
	return result;
}
