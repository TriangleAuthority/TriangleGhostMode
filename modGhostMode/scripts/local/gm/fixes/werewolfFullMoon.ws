// FIX-11: werewolf regeneration stacking on higher difficulties (a 5.x bug; not in legacy). The werewolf's behaviour
// tree (gameplay\trees\monsters\monster_werewolf_logic.w2behtree) howls below 50% health and, when the howl ends,
// gives it FullMoon or, behind a Hard difficulty check, FullMoonOnSteroids (+60 essence regen, +0.30 attack power).
// The FullMoon task sets allowMultiple false; the FullMoonOnSteroids task leaves it at the script's default (true).
// The howl runs again until one finishes (an interrupted one does not count) and while the werewolf lacks FullMoon,
// which the Hard path never adds; each howl's end, interrupted or not, adds the ability. So every howl cut short by a
// hit, stagger or knockdown added another +60 regen per second, until the werewolf healed faster than any damage.
// The fix: FullMoonOnSteroids is added once, as FullMoon is; an interrupted howl still repeats, as in vanilla.
// See docs/features/fix.md.
@wrapMethod(BTTaskAddRemoveAbility)
function OnDeactivate()
{
	if( abilityName == 'FullMoonOnSteroids' && !removeAbility )
		allowMultiple = false;
	wrappedMethod();
}

// FIX-11: an NPC saved with stacked FullMoonOnSteroids (before the fix) keeps one.
@wrapMethod(CNewNPC)
function OnSpawned(spawnData : SEntitySpawnData)
{
	var ret : bool;

	ret = wrappedMethod(spawnData);
	GMFixFullMoonStacks();
	return ret;
}

// FIX-11: removes FullMoonOnSteroids beyond one copy; returns how many it removed.
@addMethod(CNewNPC)
function GMFixFullMoonStacks() : int
{
	var n : int;

	n = GetAbilityCount('FullMoonOnSteroids');
	if( n > 1 )
	{
		RemoveAbilityMultiple('FullMoonOnSteroids', n - 1);
		return n - 1;
	}
	return 0;
}
