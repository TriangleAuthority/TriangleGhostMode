// ITEM-10: durability as legacy ("durability penalties were redone"). See docs/features/item.md.
// The penalty on weapon damage and armor is linear in lost durability: 1 - (1 - durability)/4 on easy
// and normal (at most -20% on easy and -25% on normal: the formula never goes below 0.75, so legacy's
// clamp of 0.7 on normal is never reached), 1 - (1 - durability)/2 on hard and Death March (at most -40%
// and -50%). The wear per hit and the "damaged" threshold are W3GameParams defaults, in the class's
// scope-based override block (gm/stamina/staminaCosts.ws). 5.x's Accessibility option "Disable item
// durability" stays available (DI4).

@replaceMethod(W3GameParams)
function GetDurabilityMultiplier(durabilityRatio : float, isWeapon : bool) : float
{
	var currDiff : EDifficultyMode;	//modSigns

	//modSigns: removed vanilla's stepped thresholds (GetDurMult with durabilityThresholdsWeapon or durabilityThresholdsArmor)
	currDiff = theGame.GetDifficultyMode();	//modSigns
	switch( currDiff )	//modSigns
	{	//modSigns
		case EDM_Easy:	//modSigns
			return ClampF(1.0f - (1.0f - durabilityRatio)/4.0f, 0.8f, 1.0f);	//modSigns
		case EDM_Medium:	//modSigns
			return ClampF(1.0f - (1.0f - durabilityRatio)/4.0f, 0.7f, 1.0f);	//modSigns
		case EDM_Hard:	//modSigns
			return ClampF(1.0f - (1.0f - durabilityRatio)/2.0f, 0.6f, 1.0f);	//modSigns
		case EDM_Hardcore:	//modSigns
			return ClampF(1.0f - (1.0f - durabilityRatio)/2.0f, 0.5f, 1.0f);	//modSigns
		default:	//modSigns
			return 1.0f;	//modSigns
	}	//modSigns
}
