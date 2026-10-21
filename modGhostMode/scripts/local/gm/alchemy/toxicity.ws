// ALCH-01: toxicity and overdose. The threshold is 75% (W3GameParams default in stamina/staminaCosts.ws,
// the owner's DL1); the decay is legacy's (mutations/toxicity.ws). Here: a change of the locked
// toxicity (decoctions) updates the toxicity effect at once, as legacy (5.x's offset functions do
// not call OnToxicityChanged, so toxicity could linger after a decoction ends).
// See docs/features/alch.md.

@wrapMethod(W3PlayerAbilityManager)
function AddToxicityOffset(val : float)
{
	wrappedMethod(val);
	if(val > 0)
		OnToxicityChanged();
}

@wrapMethod(W3PlayerAbilityManager)
function SetToxicityOffset(val : float)
{
	wrappedMethod(val);
	if(val >= 0)
		OnToxicityChanged();
}

@wrapMethod(W3PlayerAbilityManager)
function RemoveToxicityOffset(val : float)
{
	wrappedMethod(val);
	OnToxicityChanged();
}
