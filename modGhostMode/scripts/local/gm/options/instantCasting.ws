// OPT-06: instant sign casting. Legacy's QoL toggle "Instant sign casting with sign select key" is not ported:
// 5.x's own "Quick Sign Casting" (Gameplay settings, EnableAlternateSignCasting) makes a sign-select key cast its
// sign (CPlayerInput.OnSelectSign -> AltCastSign, with STAM-01's cooldown check), keeps a channeled sign going while
// the key is held and aborts it on release (DO5). See docs/features/opt.md.

// PO13: legacy's spider web also released the sign-select keys (ForceDeactivateCastSignHold), so a key held
// through the web does not go on channelling or casting. With 5.x's Quick Sign Casting on, the select keys are cast
// keys, so the web releases them too (EFX-10's wrapper aborts the sign; 5.x releases only CastSignHold).
function GMWebReleaseSignSelectKeys()
{
	theInput.ForceDeactivateAction('SelectAard');
	theInput.ForceDeactivateAction('SelectIgni');
	theInput.ForceDeactivateAction('SelectYrden');
	theInput.ForceDeactivateAction('SelectQuen');
	theInput.ForceDeactivateAction('SelectAxii');
}

@wrapMethod(W3Effect_Tangled)
function OnEffectAdded(optional customParams : W3BuffCustomParams)
{
	var result : bool;

	result = wrappedMethod(customParams);
	if(isOnPlayer && thePlayer.GetInputHandler() && thePlayer.GetInputHandler().GetIsAltSignCasting())
		GMWebReleaseSignSelectKeys();
	return result;
}
