// STAM-04: stamina regen. The base rate is 15/s (ConGeralt in the DLC's gm_stats.xml), regen
// while guarding is 50% of the normal rate (vanilla: a fixed staminaRegenGuarded value), and
// the options "Combat / Out of combat stamina regen (additional)" add to it.
// See docs/features/stam.md.

// Adds the regen options to a stamina regen value.
function GMModStaminaRegenValue(attributeName : name, out effectValue : SAbilityAttributeValue)
{
	if(attributeName == 'staminaOutOfCombatRegen')
		effectValue.valueAdditive += GMGetOptionFloat('GMGameplayOptions', 'GMOutOfCombatStaminaRegen');
	else if(attributeName == 'staminaRegen' || attributeName == 'staminaRegenGuarded')
		effectValue.valueAdditive += GMGetOptionFloat('GMGameplayOptions', 'GMCombatStaminaRegen');
}

// 5.x body, except: the value is recomputed on every update (so option changes apply at once,
// in and out of combat), and guarding uses SetEffectValue (50% of normal regen) instead of the
// staminaRegenGuarded attribute. STAM-10: while max stamina is lowered the regen keeps running and,
// with stamina full, brings max stamina back.
@replaceMethod(W3Effect_AutoStaminaRegen)
function OnUpdate(dt : float)
{
	if(isOnPlayer)
	{
		if ( regenModeIsCombat != cachedPlayer.IsInCombat() )
		{
			regenModeIsCombat = !regenModeIsCombat;
		}	//modSigns: the value is set below, on every update
		if(regenModeIsCombat)	//modSigns
			attributeName = RegenStatEnumToName(regenStat);
		else
			attributeName = 'staminaOutOfCombatRegen';
		SetEffectValue();	//modSigns: also when guarded, see SetEffectValue
		//modSigns: removed vanilla's in-combat block (staminaRegenGuarded while guarded, else SetEffectValue)
	}

	super.OnUpdate( dt );
	GMExhaustionRegen( dt );	//modSigns: STAM-10, max stamina comes back while stamina is full (exhaustion.ws)

	if( target.GetStatPercents( BCS_Stamina ) >= 1.0f && !GMExhaustionKeepsRegen( target ) )	//modSigns: STAM-10, not while max stamina is lowered
	{
		target.StopStaminaRegen();
	}
}

// The regen value with the options; halved while guarding.
@replaceMethod(W3Effect_AutoStaminaRegen)
function SetEffectValue()
{
	effectValue = target.GetAttributeValue(attributeName);
	if(isOnPlayer && GetWitcherPlayer())	//modSigns
	{	//modSigns
		GMModStaminaRegenValue(attributeName, effectValue);	//modSigns
		if(GetWitcherPlayer().IsGuarded())	//modSigns
		{	//modSigns
			effectValue.valueAdditive *= 0.5;	//modSigns
			effectValue.valueMultiplicative *= 0.5;	//modSigns
		}	//modSigns
	}	//modSigns
}
