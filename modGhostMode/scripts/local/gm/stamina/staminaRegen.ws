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

class W3Effect_AutoStaminaRegen extends W3AutoRegenEffect
{
	// 5.x body, except: the value is recomputed on every update (so option changes apply at
	// once, in and out of combat), and guarding uses SetEffectValue (50% of normal regen)
	// instead of the staminaRegenGuarded attribute.
	event OnUpdate(dt : float)
	{
		if(isOnPlayer)
		{
			if ( regenModeIsCombat != cachedPlayer.IsInCombat() )
			{
				regenModeIsCombat = !regenModeIsCombat;
			}
			if(regenModeIsCombat)	//modSigns
				attributeName = RegenStatEnumToName(regenStat);
			else
				attributeName = 'staminaOutOfCombatRegen';
			SetEffectValue();	//modSigns: also when guarded, see SetEffectValue
		}

		super.OnUpdate( dt );

		if( target.GetStatPercents( BCS_Stamina ) >= 1.0f )
		{
			target.StopStaminaRegen();
		}
	}

	protected function SetEffectValue()
	{
		effectValue = target.GetAttributeValue(attributeName);
		if(isOnPlayer && GetWitcherPlayer())	//modSigns
		{
			GMModStaminaRegenValue(attributeName, effectValue);
			if(GetWitcherPlayer().IsGuarded())
			{
				effectValue.valueAdditive *= 0.5;
				effectValue.valueMultiplicative *= 0.5;
			}
		}
	}
}
