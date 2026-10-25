// EFX-08: effect resistance point names (docs/features/efx.md). Legacy names the point (flat)
// resistances of bleeding, will and burning, which 1.32 and 5.x know only as percentages
// (`bleeding_resistance_perc`, ...): abilities giving such points count, and an effect entry naming
// its resistance by one of them is resisted. 5.x's hypnosis (and the witch's) names
// `will_resistance`: without these names the entry gives it no resistance at all, overriding the
// class's CDS_WillRes, so will resistance did not shorten it; with them it does (legacy).
// Ends DMG-02's temporary deviation.

// EFX-08: the three point names, after 5.x's (which return CDS_None for them).
@wrapMethod
function ResistStatNameToEnum(n : name, out isPointResistance : bool) : ECharacterDefenseStats
{
	var stat : ECharacterDefenseStats;

	stat = wrappedMethod(n, isPointResistance);
	if(stat == CDS_None)
	{
		switch(n)
		{
			case 'bleeding_resistance' :	isPointResistance = true; return CDS_BleedingRes;
			case 'will_resistance' :		isPointResistance = true; return CDS_WillRes;
			case 'burning_resistance' :		isPointResistance = true; return CDS_BurningRes;
		}
	}
	return stat;
}

// EFX-08: and back (5.x returns no name for them).
@wrapMethod
function ResistStatEnumToName(s : ECharacterDefenseStats, isPointResistance : bool) : name
{
	var n : name;

	n = wrappedMethod(s, isPointResistance);
	if(isPointResistance && !IsNameValid(n))
	{
		switch(s)
		{
			case CDS_BleedingRes :	return 'bleeding_resistance';
			case CDS_WillRes :		return 'will_resistance';
			case CDS_BurningRes :	return 'burning_resistance';
		}
	}
	return n;
}
