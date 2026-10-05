// In-game checks of the port techniques themselves (docs/development.md), situation-free.

// Test-only @replaceMethod of a vanilla W3GameParams function, on a class Ghost Mode also
// scope-overrides (staminaCosts.ws) and extends with @addMethod (signCooldowns.ws): the 5.x body,
// plus a call count while the test probes are on.
@addField(CR4Player)
var gmTestReplaceCalls : int;

@addMethod(CR4Player)
function GMTestCountReplaceCall(reset : bool)
{
	if(reset)
		gmTestReplaceCalls = 0;
	else
		gmTestReplaceCalls += 1;
}

@replaceMethod(W3GameParams)
function IsForbiddenAttribute(nam : name) : bool
{
	if(GMTestProbes())	//modSigns
		thePlayer.GMTestCountReplaceCall(false);	//modSigns
	if(!IsNameValid(nam))
		return true;
	return forbiddenAttributes.Contains(nam);
}

exec function gmtest_annotations()
{
	GMTest_annotations();
}

function GMTest_annotations()
{
	var regen : W3Effect_AutoStaminaRegen;
	var value, attribute : SAbilityAttributeValue;
	var cfg : CInGameConfigWrapper;
	var previous : string;
	var stamina : float;

	// A scope override (a default value), @addMethod and @replaceMethod on one class
	thePlayer.GMTestSetProbes(true);
	thePlayer.GMTestCountReplaceCall(true);
	theGame.params.IsForbiddenAttribute('GMTestAttribute');
	GMTestReport(thePlayer.gmTestReplaceCalls == 1, "dev W3GameParams: @replaceMethod applies (IsForbiddenAttribute replaced)");
	GMTestReport(theGame.params.HEAVY_STRIKE_COST_MULTIPLIER == 1.25, "dev W3GameParams: scope override applies (HEAVY_STRIKE_COST_MULTIPLIER 1.25)");
	GMTestReport(theGame.params.GMGetSignCooldownDuration() > 0, "dev W3GameParams: @addMethod applies (GMGetSignCooldownDuration)");
	thePlayer.GMTestSetProbes(false);

	// @replaceMethod and @wrapMethod on one method (an event): W3Effect_AutoStaminaRegen.OnUpdate
	regen = (W3Effect_AutoStaminaRegen)thePlayer.GetBuff(EET_AutoStaminaRegen);
	if(!regen || thePlayer.IsInCombat())
	{
		LogChannel('GMTest', "INFO dev: no regen effect or in combat, OnUpdate checks skipped");
		return;
	}
	cfg = theGame.GetInGameConfigWrapper();
	previous = cfg.GetVarValue('GMGameplayOptions', 'GMOutOfCombatStaminaRegen');
	stamina = thePlayer.GetStat(BCS_Stamina);
	cfg.SetVarValue('GMGameplayOptions', 'GMOutOfCombatStaminaRegen', "-40");
	thePlayer.GMStopLowStaminaSFX();
	thePlayer.ForceSetStat(BCS_Stamina, thePlayer.GetStatMax(BCS_Stamina) * 0.05);
	regen.OnUpdate(0.001);
	value = regen.GMTestGetEffectValue();
	attribute = thePlayer.GetAttributeValue('staminaOutOfCombatRegen');
	// vanilla's OnUpdate recomputes the value only when combat starts or ends
	GMTestReport(value.valueAdditive == attribute.valueAdditive - 40, "dev OnUpdate: @replaceMethod applies (option recomputed out of combat)");
	// the STAM-07 wrapper starts the heartbeat below its threshold
	GMTestReport(thePlayer.gmLowStaminaSFXPlaying, "dev OnUpdate: @wrapMethod on the replaced event still runs (heartbeat started)");
	thePlayer.GMStopLowStaminaSFX();
	cfg.SetVarValue('GMGameplayOptions', 'GMOutOfCombatStaminaRegen', previous);
	thePlayer.ForceSetStat(BCS_Stamina, stamina);
	regen.OnUpdate(0.001);
}
