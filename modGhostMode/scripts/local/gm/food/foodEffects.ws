// FOOD-03: food and drinks raise Geralt's own regeneration instead of regenerating on their own (legacy:
// "boosts existing autoregen effect instead of adding another one"). Legacy changed the effects' parent
// class to CBaseGameplayEffect; a mod cannot change a class's parent, so the two effects keep 5.x's
// W3RegenEffect and their own regeneration is switched off: the effect still ticks and adds its ability
// (vitalityRegen, vitalityCombatRegen, staminaRegen) to Geralt, whose auto regen reads it, the
// out-of-combat value out of combat and the combat value in combat. W3Effect_Edible (no item gives it) is
// left as 5.x's.
// FOOD-03, the owner's DF6: a weaker drink drunk while a stronger Well Hydrated lasts adds its time and the
// stronger tier stays (in CumulateWith, alchemy/potionRules.ws); an equal or stronger one refreshes it to
// the new drink. 5.x's W3Effect_WellHydrated.GetSelfInteraction already cumulates every drink (the effect
// definitions give it no level), which this rule relies on.
// See docs/features/food.md.

class W3Effect_WellFed extends W3RegenEffect
{
	event OnUpdate(dt : float)	//modSigns
	{	//modSigns
		var none : SAbilityAttributeValue;	//modSigns
		effectValue = none;	//modSigns: FOOD-03, no regeneration of its own: its ability raises Geralt's
		super.OnUpdate(dt);	//modSigns
	}	//modSigns
}

class W3Effect_WellHydrated extends W3RegenEffect
{
	event OnUpdate(dt : float)	//modSigns
	{	//modSigns
		var none : SAbilityAttributeValue;	//modSigns
		effectValue = none;	//modSigns: FOOD-03, no regeneration of its own: its ability raises Geralt's
		super.OnUpdate(dt);	//modSigns
	}	//modSigns
}

// FOOD-03: an ability that changes a Vitality or stamina regen stat (re)starts Geralt's auto regen (legacy), so
// food starts his regeneration even where his base regen is 0. Only for Geralt, and a frame later (a timer):
// legacy restarted it at once for every actor. Geralt is the only actor whose base regen Ghost Mode zeroes,
// and the timer keeps the restart out of the effect manager's own update (an effect with a regen ability
// ending); a frame's delay is invisible in play (a deviation confirmed by the owner, 2026-10-24).
@wrapMethod(W3AbilityManager)
function OnAbilityChanged( abilityName : name )
{
	var atts : array<name>;
	var i : int;
	var stat : ECharacterRegenStats;
	var player : CR4Player;

	wrappedMethod(abilityName);
	player = (CR4Player)owner;
	if(player)
	{
		theGame.GetDefinitionsManager().GetAbilityAttributes(abilityName, atts);
		for(i = 0; i < atts.Size(); i += 1)
		{
			stat = RegenStatNameToEnum(atts[i]);
			if(stat == CRS_Vitality || stat == CRS_Stamina)
			{
				player.AddTimer('GMRestartRegen', 0.0, false);
				break;
			}
		}
	}
}

@addMethod(CR4Player)
timer function GMRestartRegen(dt : float, id : int)
{
	StartVitalityRegen();
	StartStaminaRegen();
}
