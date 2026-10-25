// ENCH-06 Preservation and Dumplings (Runewords 5, 6), as legacy; both work from an equipped sword
// (ENCH-01). Preservation: Armorer's Table and grindstone buffs keep their time running underneath
// but never expire while it is active, and one that gets removed is applied again. Dumplings: food and
// drinks last +100% (legacy's value, gm_ench.xml; 5.x +400%), their regeneration unchanged (5.x also
// multiplied it). The edible tooltip's line stays 5.x's until FOOD. See docs/features/ench.md.

// Preservation: the timer runs on (legacy: when Preservation goes, the buff has its real time left).
// 5.x body; changes marked //modSigns.
@replaceMethod(W3RepairObjectEnhancement)
function OnTimeUpdated(dt : float)
{
	var hasRuneword5 : bool;


	if(isOnPlayer)
		hasRuneword5 = GetWitcherPlayer().HasRunewordActive('Runeword 5 _Stats');
	else
		hasRuneword5 = false;

	if(hasRuneword5)
	{
		if( isActive && pauseCounters.Size() == 0)
		{
			timeActive += dt;
			timeLeft -= dt;	//modSigns
		}

		//modSigns: removed the time frozen at 0 and the early return
	}
	else	//modSigns: removed the reset of timeLeft from timeActive
	{	//modSigns
		super.OnTimeUpdated(dt);	//modSigns
	}	//modSigns
	//modSigns: removed the call after the branches
}

// Preservation applies a removed buff again (legacy). W3RepairObjectEnhancement inherits OnEffectRemoved,
// so this is a scope-based override.
abstract class W3RepairObjectEnhancement extends CBaseGameplayEffect
{
	event OnEffectRemoved()	//modSigns
	{	//modSigns
		super.OnEffectRemoved();	//modSigns
		if(isOnPlayer && GetWitcherPlayer().HasRunewordActive('Runeword 5 _Stats'))	//modSigns
			thePlayer.AddEffectDefault(effectType, GetCreator(), sourceName);	//modSigns
	}	//modSigns
}

// Dumplings lengthens food, it does not strengthen it (5.x multiplied the regeneration too).
@replaceMethod(W3Effect_WellFed)
function SetEffectValue()
{
	//modSigns: removed the locals of the multiplier
	super.SetEffectValue();
	//modSigns: removed 5.x's Dumplings multiplier on the regeneration
}

@replaceMethod(W3Effect_WellHydrated)
function SetEffectValue()
{
	//modSigns: removed the locals of the multiplier
	super.SetEffectValue();
	//modSigns: removed 5.x's Dumplings multiplier on the regeneration
}

// Dumplings on drinks: +100% read from the word's definition, as legacy (5.x read Geralt's attribute,
// which sums both swords: +200% with Dumplings on both). FOOD-06: Connoisseur's +100% on an alcohol's Well Hydrated.
// 5.x body; changes marked //modSigns.
@replaceMethod(W3Effect_WellHydrated)
function CalculateDuration(optional setInitialDuration : bool)
{
	var val : SAbilityAttributeValue;
	var gmMax : SAbilityAttributeValue;	//modSigns
	
	super.CalculateDuration(setInitialDuration);
	
	if(isOnPlayer && thePlayer == GetWitcherPlayer() && sourceName == "alcohol")	//modSigns: FOOD-06, Connoisseur: an alcohol's effects last longer
		duration *= 1 + GetWitcherPlayer().GMConnoisseurDurationBonus();	//modSigns
	
	if(isOnPlayer && thePlayer == GetWitcherPlayer() && GetWitcherPlayer().HasRunewordActive('Runeword 6 _Stats'))
	{
		theGame.GetDefinitionsManager().GetAbilityAttributeValue('Runeword 6 _Stats', 'runeword6_duration_bonus', val, gmMax);	//modSigns: ENCH-06, the word's value once, from its definition (legacy)
		duration *= ( 1 + val.valueMultiplicative );
	}
	
}
