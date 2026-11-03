// OPT-02, OPT-03: Geralt's Vitality regeneration. His base regen is 0 in and out of combat (OPT-02, ConGeralt in
// the DLC's gm_stats.xml); "Combat vitality regen (additional)" and "Out of combat vitality regen (additional)"
// add 0 to 1000 per second (legacy's gmModRegenValue). See docs/features/opt.md.

// The option that adds to a Vitality regen attribute (0 for any other attribute).
function GMVitalityRegenOption(attributeName : name) : float
{
	if(attributeName == 'vitalityRegen')
		return GMGetOptionFloat('GMGameplayOptions', 'GMOutOfCombatVitalityRegen');
	if(attributeName == 'vitalityCombatRegen')
		return GMGetOptionFloat('GMGameplayOptions', 'GMCombatVitalityRegen');
	return 0;
}

// Whether the options start Geralt's regen without any other source: either Vitality option above 0 (DO2, a fix:
// legacy's start read the out-of-combat value only), or 5.x's "Vitality Regeneration Boost" on (DO1).
function GMVitalityRegenFromOptions() : bool
{
	return GMVitalityRegenOption('vitalityRegen') > 0 || GMVitalityRegenOption('vitalityCombatRegen') > 0
		|| theGame.GetInGameConfigWrapper().GetVarValue('Accessibility', 'LowHPAutoHealOn') == "true";
}

// Whether Geralt's regen starts although he has no out-of-combat regen of his own (5.x's start reads only that):
// the options (above), or a combat regen of his own above 0 (OPT audit F1, a fix like DO2's: the Tvarog rune's +5 in
// combat, ENCH-16, is the only source with a combat value and no out-of-combat one, and alone it never started the
// regen; legacy's start was the same).
function GMVitalityRegenStarts(actor : CActor) : bool
{
	var own : SAbilityAttributeValue;

	if(GMVitalityRegenFromOptions())
		return true;
	own = actor.GetAttributeValue('vitalityCombatRegen');
	return own.valueAdditive + own.valueMultiplicative * actor.GetStatMax(BCS_Vitality) > 0;
}

// The options that change Geralt's regen when the menu closes.
function GMIsVitalityRegenOption(option : name) : bool
{
	switch(option)
	{
		case 'GMCombatVitalityRegen' :
		case 'GMOutOfCombatVitalityRegen' :
		case 'LowHPAutoHealOn' :
		case 'AccessibilityPreset' :	// 5.x's accessibility presets switch the boost
			return true;
	}
	return false;
}

// Changed options take effect when the menu closes (legacy's gmUpdateRegenEffects): a running regen recomputes its
// value at every update (5.x), so only a stopped one needs starting.
function GMOnVitalityRegenOptionsChanged()
{
	var witcher : W3PlayerWitcher;

	witcher = GetWitcherPlayer();
	if(witcher)
		witcher.StartVitalityRegen();
}

// OPT-03: the option for the regen in force, added after 5.x's value (which keeps its boost in it).
@wrapMethod(W3Effect_AutoVitalityRegen)
function SetEffectValue()
{
	wrappedMethod();
	if(isOnPlayer && (W3PlayerWitcher)target)
		effectValue.valueAdditive += GMVitalityRegenOption(attributeName);
}

// A regen effect whose value is 0 when it is added is switched off at once (W3RegenEffect.OnEffectAdded). Its value
// at that moment is the out-of-combat one, without 5.x's boost (read after the add): a regen started by the combat
// option, the boost or Geralt's own combat regen alone stays on (DO1, DO2, OPT audit F1). Its value is recomputed at
// every update.
@wrapMethod(W3Effect_AutoVitalityRegen)
function OnEffectAdded(optional customParams : W3BuffCustomParams)
{
	wrappedMethod(customParams);
	if(!isActive && isOnPlayer && (W3PlayerWitcher)target && target.GetStatMax(BCS_Vitality) > 0 && GMVitalityRegenStarts(target))
		isActive = true;
}

// The regen start (legacy's FilterAutoBuff edit): with no out-of-combat regen of his own, Geralt's regen still starts
// when the options give him one (DO1, DO2) or he has a combat regen of his own (OPT audit F1).
@wrapMethod(W3EffectManager)
function StartVitalityRegen() : bool
{
	var started : bool;
	var addResult : EEffectInteract;

	started = wrappedMethod();
	if(!started && !vitalityAutoRegenOn && (W3PlayerWitcher)owner && GMVitalityRegenStarts(owner))
	{
		addResult = InternalAddEffect(EET_AutoVitalityRegen, owner, 'autobuff');
		if(addResult == EI_Cumulate)
			owner.SetEffectsUpdateTicking(true);
		if(addResult == EI_Pass || addResult == EI_Cumulate)
		{
			vitalityAutoRegenOn = true;
			started = true;
		}
	}
	return started;
}
