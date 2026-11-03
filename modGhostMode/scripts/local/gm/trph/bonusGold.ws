// TRPH audit F3: bonus gold (the gold trophies, gear's bonus_money) on every corpse 5.x's loot merge takes.
// A container gets its bonus gold (CheckForBonusMoney) once, when Geralt first comes within its interaction range
// (W3Container.OnInteractionActivated). 5.x's loot merge (Gameplay/LootMergeEnabled) lists or takes every remains
// within 15 m with the one Geralt loots, also those he never walked up to, so they missed it; legacy had no merge,
// and every corpse it looted had been approached. Each merged remains gets the check before its loot is listed (the
// loot window) or taken (Auto-loot). See docs/features/trph.md.

// The bonus gold check, once per container, as OnInteractionActivated runs it.
@addMethod(W3Container)
function GMCheckBonusMoneyOnce()
{
	if(inv && !disableLooting && !checkedForBonusMoney)
	{
		checkedForBonusMoney = true;
		CheckForBonusMoney(0);
	}
}

// Every container of the class within range of `center` that the merge would take (not loot bags), `center` itself
// included, gets its bonus gold check.
function GMMergedLootBonusMoney(center : CGameplayEntity, range : float, containerClass : name)
{
	var found : array<CGameplayEntity>;
	var c : W3Container;
	var i : int;

	if(!center || range <= 0 || !IsNameValid(containerClass))
		return;
	FindGameplayEntitiesInRange(found, center, range, 100, '', 0, NULL, containerClass);
	for(i = 0; i < found.Size(); i += 1)
	{
		if(!found[i] || found[i].HasTag('lootbag'))
			continue;
		c = (W3Container)found[i];
		if(c)
			c.GMCheckBonusMoneyOnce();
	}
}

// The loot window: with the merge on, BuildCache lists every remains within range of the window's container.
@wrapMethod(CR4LootPopup)
function BuildCache(rootContainer : W3Container, range : float, containerClass : name)
{
	if(range > 0 && IsNameValid(containerClass))
		GMMergedLootBonusMoney(_container, range, containerClass);
	wrappedMethod(rootContainer, range, containerClass);
}

// Auto-loot ("Quick Corpse Looting") with the merge on: ProcessLoot takes every remains within 15 m (5.x's
// conditions, read the same way).
@wrapMethod(W3Container)
function ProcessLoot()
{
	if(!disableLooting && (W3ActorRemains)this && !HasTag('lootbag')
		&& theGame.GetInGameConfigWrapper().GetVarValue('Accessibility', 'AutoLoot')
		&& theGame.GetInGameConfigWrapper().GetVarValue('Gameplay', 'LootMergeEnabled'))
	{
		GMMergedLootBonusMoney(this, 15.0f, 'W3ActorRemains');
	}
	wrappedMethod();
}
