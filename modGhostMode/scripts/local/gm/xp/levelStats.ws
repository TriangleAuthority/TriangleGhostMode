// XP-08: Geralt's level-up Vitality (docs/features/xp.md). The level abilities Lvl2 to Lvl50 are data
// (abilities/gm_xp.xml, tools/gen_xp.py): +50 Vitality each, no attack or spell power.
//
// Save impact: a save keeps Geralt's maximum Vitality as a stored stat, which the game recomputes from the
// definitions only when an ability with Vitality is added or removed (W3AbilityManager.OnAbilityChanged's
// UpdateStatMax). So a character saved with other level-up values (5.x's: 1,400 by level 20 instead of 950) keeps the
// old maximum after loading until such a change; attack power and spell power are read live and change at once.
// The maximum is recomputed once when a save is loaded, keeping Geralt's Vitality percentage as the game's own path
// does.
@wrapMethod(W3PlayerWitcher)
function OnSpawned(spawnData : SEntitySpawnData)
{
	wrappedMethod(spawnData);
	if(spawnData.restored && abilityManager && abilityManager.IsInitialized())
		GMRecomputeVitalityAtLoad();
}

// Runs after the effects are back: the effect manager and the abilities come from the save before this point
// (CActor.OnSpawned: abilityManager.Init, effectManager.OnLoad), so an effect's Vitality ability (Blood and Wine's
// "Well rested", +500) is counted in the new maximum (verified by gmtest_xp08_vit_c, XP audit F4). True when the
// maximum changed.
@addMethod(W3PlayerWitcher)
function GMRecomputeVitalityAtLoad() : bool
{
	var oldMax, cur : float;

	oldMax = GetStatMax(BCS_Vitality);
	cur = GetStat(BCS_Vitality, true);
	UpdateStatMax(BCS_Vitality);
	if(oldMax > 0 && GetStatMax(BCS_Vitality) != oldMax)
	{
		ForceSetStat(BCS_Vitality, MinF(cur * GetStatMax(BCS_Vitality) / oldMax, GetStatMax(BCS_Vitality)));
		LogChannel('GMXp', "XP-08: maximum Vitality recomputed at load: " + NoTrailZeros(oldMax) + " -> " + NoTrailZeros(GetStatMax(BCS_Vitality)));
		return true;
	}
	return false;
}
