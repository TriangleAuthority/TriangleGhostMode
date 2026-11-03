// WGT's in-game checks (weight, docs/features/wgt.md). Pre-seeded empty for the parallel ports
// (docs/proposals/parallel-ports.md, section 5): gmtest_regress() and gmtest_panel() already call the two
// functions below, so WGT adds its checks here and never edits gmTests.ws's lists.
//   GMTest_wgt()        in gmtest_regress(): checks that need no fight, input or menu, each restoring what it changes
//   GMTest_wgt_after()  in gmtest_panel(): checks that need the pause menu open, or read the game a frame or more
//                        after gmtest_regress() (spawned samples, effects' first updates)

exec function gmtest_wgt()
{
	thePlayer.GMTestCount(true, true);
	GMTest_wgt();
	LogChannel('GMTest', "SUMMARY wgt: " + thePlayer.gmTestPassed + " passed, " + thePlayer.gmTestFailed + " failed");
}

// One item's weight and whether it counts towards the load, as the game reads them: a copy spawned into the horse
// manager's inventory (no OnItemAdded side effects of Geralt's: journal, books, Gwent cards), read and removed.
// GetItemWeight is the item's own weight, or the sum of its abilities' when it has none (slice W1's probe, W2);
// a weight node with a max above its min is rolled per copy, so the expected weight is a range.
function GMTestWgtItemDef(item : name, weight : float, weightMax : float, counts : bool, out checks : int) : int
{
	var inv : CInventoryComponent;
	var ids : array<SItemUniqueId>;
	var w : float;
	var c : bool;
	var i : int;

	checks += 1;
	inv = GetWitcherPlayer().GetHorseManager().GetInventoryComponent();
	ids = inv.AddAnItem(item, 1, true, true);
	if(ids.Size() == 0)
	{
		LogChannel('GMTest', "FAIL WGT data " + item + ": could not be added");
		return 1;
	}
	w = inv.GetItemWeight(ids[0]);
	c = inv.IsItemEncumbranceItem(ids[0]);
	for(i = 0; i < ids.Size(); i += 1)
		inv.RemoveItem(ids[i], inv.GetItemQuantity(ids[i]));
	if(w > weight - 0.0005 && w < weightMax + 0.0005 && c == counts)
		return 0;
	LogChannel('GMTest', "FAIL WGT data " + item + " weighs " + w + ", counts " + c + " (expected " + weight + " to " + weightMax + ", " + counts + ")");
	return 1;
}

// One ability node's value as the definitions give it (base, mult and add parts of its min values).
function GMTestWgtAblDef(abl : name, attr : name, b : float, m : float, a : float, out checks : int) : int
{
	var mn, mx : SAbilityAttributeValue;

	checks += 1;
	theGame.GetDefinitionsManager().GetAbilityAttributeValue(abl, attr, mn, mx);
	if(AbsF(mn.valueBase - b) < 0.0005 && AbsF(mn.valueMultiplicative - m) < 0.0005 && AbsF(mn.valueAdditive - a) < 0.0005)
		return 0;
	LogChannel('GMTest', "FAIL WGT data " + abl + " " + attr + " reads b " + mn.valueBase + " m " + mn.valueMultiplicative
		+ " a " + mn.valueAdditive + " (expected " + b + ", " + m + ", " + a + ")");
	return 1;
}

// WGT-06, slice W2: Geralt's carry limit with each of the base game's saddlebags equipped on his horse, read from
// the game (GetMaxRunEncumbrance) less his own capacity: legacy's +40, +60, +80. The horse's bag is put back.
function GMTestWgtBagCapacity(item : name, extra : float) : bool
{
	var w : W3PlayerWitcher;
	var hm : W3HorseManager;
	var inv : CInventoryComponent;
	var ids : array<SItemUniqueId>;
	var own, cap : float;
	var hb : bool;

	w = GetWitcherPlayer();
	hm = w.GetHorseManager();
	inv = hm.GetInventoryComponent();
	ids = inv.AddAnItem(item, 1, true, true);
	if(ids.Size() == 0)
		return false;
	hm.EquipItem(ids[0]);
	cap = w.GetMaxRunEncumbrance(hb);
	own = CalculateAttributeValue(w.GetAttributeValue('encumbrance'));
	LogChannel('GMTest', "INFO WGT-06 " + item + ": carry limit " + cap + " (Geralt's own " + own + ")");
	return AbsF(cap - own - extra) < 0.001;
}

function GMTest_wgt_bags()
{
	var w : W3PlayerWitcher;
	var hm : W3HorseManager;
	var inv, ginv : CInventoryComponent;
	var orig : SItemUniqueId;
	var origName : name;
	var bags : array<name>;
	var extra : array<float>;
	var before, gbefore : array<int>;
	var ok : bool;
	var i, n : int;

	w = GetWitcherPlayer();
	hm = w.GetHorseManager();
	inv = hm.GetInventoryComponent();
	ginv = w.GetInventory();
	bags.PushBack('Horse Bag 1'); extra.PushBack(40);
	bags.PushBack('Horse Bag 2'); extra.PushBack(60);
	bags.PushBack('Horse Bag 3'); extra.PushBack(80);
	for(i = 0; i < bags.Size(); i += 1)
	{
		before.PushBack(inv.GetItemQuantityByName(bags[i]));
		gbefore.PushBack(ginv.GetItemQuantityByName(bags[i]));
	}
	orig = hm.GetItemInSlot(EES_HorseBag);
	if(inv.IsIdValid(orig))
		origName = inv.GetItemName(orig);
	for(i = 0; i < bags.Size(); i += 1)
	{
		ok = GMTestWgtBagCapacity(bags[i], extra[i]);
		GMTestReport(ok, "WGT-06 " + bags[i] + " on Geralt's horse adds " + extra[i] + " to his carry limit (legacy's)");
	}
	// put the horse's own bag back (or none), and remove the test bags wherever the unequips moved them
	if(origName != '')
	{
		orig = inv.GetItemId(origName);
		hm.EquipItem(orig);
	}
	else
		hm.UnequipItem(EES_HorseBag);
	for(i = 0; i < bags.Size(); i += 1)
	{
		n = inv.GetItemQuantityByName(bags[i]) - before[i];
		if(n > 0)
			inv.RemoveItemByName(bags[i], n);
		n = ginv.GetItemQuantityByName(bags[i]) - gbefore[i];
		if(n > 0)
			ginv.RemoveItemByName(bags[i], n);
	}
	w.UpdateEncumbrance();
	GMTestReport(hm.GetItemInSlot(EES_HorseBag) == orig || (origName == '' && !inv.IsIdValid(hm.GetItemInSlot(EES_HorseBag))),
		"WGT-06 saddlebag check: the horse's own bag (" + origName + ") back in place");
}

exec function gmtest_wgt_bags()
{
	thePlayer.GMTestCount(true, true);
	GMTest_wgt_bags();
	LogChannel('GMTest', "SUMMARY wgt_bags: " + thePlayer.gmTestPassed + " passed, " + thePlayer.gmTestFailed + " failed");
}

// WGT-03 to WGT-06, slices W1 and W2: every regular WGT item unit's weight and EncumbranceOff tag, every regular WGT
// ability unit's weight, capacity, panic and sprint cost (gen_wgt.py's data test).
function GMTest_wgtdata()
{
	var f, checks : int;

	f = GMTestWgtDataAll(checks);
	GMTestReport(f == 0 && checks == GMTestWgtDataChecks(), "WGT-03 to WGT-06 data: " + checks + " readings ("
		+ GMTestWgtDataItems() + " items weigh and count as Ghost Mode's DLC gives them: legacy's weights, florens and orens"
		+ " weightless, the Hearts of Stone pig trophy counted; the abilities' weights, saddlebag capacities, blinders' panic"
		+ " and the base horse's sprint cost as legacy's); " + f + " differ");
}

exec function gmtest_wgtdata()
{
	thePlayer.GMTestCount(true, true);
	GMTest_wgtdata();
	LogChannel('GMTest', "SUMMARY wgtdata: " + thePlayer.gmTestPassed + " passed, " + thePlayer.gmTestFailed + " failed");
}

// WGT-01, WGT-02, slice W4: a stack's counted weight (GetItemEncumbrance) of a copy spawned into the horse
// manager's inventory, read and removed.
function GMTestWgtCount(item : name, qty : int) : float
{
	var inv : CInventoryComponent;
	var ids : array<SItemUniqueId>;
	var e : float;
	var i : int;

	inv = GetWitcherPlayer().GetHorseManager().GetInventoryComponent();
	ids = inv.AddAnItem(item, qty, true, true);
	if(ids.Size() == 0)
		return -1;
	e = inv.GetItemEncumbrance(ids[0]);
	for(i = 0; i < ids.Size(); i += 1)
		inv.RemoveItem(ids[i], inv.GetItemQuantity(ids[i]));
	return e;
}

function GMTestWgtCountIs(item : name, qty : int, expected : float, label : string)
{
	var e : float;

	e = GMTestWgtCount(item, qty);
	GMTestReport(AbsF(e - expected) < 0.001, label + ": " + qty + " x " + item + " counts " + e + " (expected " + expected + ")");
}

// WGT-01: every item its full weight x quantity, at least 0.01 per item; recipes and schematics nothing.
// WGT-02 (OPT's entry, the former check O5): the reduction at 50% halves it. DW1: "Ignore Item Weight" on, nothing
// counts. Options set in memory and put back in the same call.
function GMTest_wgt04()
{
	var cfg : CInGameConfigWrapper;
	var prevMult, prevIgnore : string;
	var w : W3PlayerWitcher;
	var load : float;

	cfg = theGame.GetInGameConfigWrapper();
	w = GetWitcherPlayer();
	prevMult = cfg.GetVarValue('GMGameplayOptions', 'GMEncumbranceMultiplier');
	prevIgnore = cfg.GetVarValue('Accessibility', 'WeightlessItems');
	cfg.SetVarValue('GMGameplayOptions', 'GMEncumbranceMultiplier', "0");
	cfg.SetVarValue('Accessibility', 'WeightlessItems', "false");
	GMTestWgtCountIs('Drowner brain', 100, 10, "WGT-01 ingredients count (1.32 and 5.x: 0)");
	GMTestWgtCountIs('Bear Armor', 1, 15, "WGT-01 gear counts its full weight (5.x: half + 0.01)");
	GMTestWgtCountIs('q103_tamara_shrine_key', 1, 0.05, "WGT-01 a key its weight (5.x: 0.01)");
	GMTestWgtCountIs('Swallow 1', 1, 0.1, "WGT-01 potions count (5.x: 0)");
	GMTestWgtCountIs('Florens', 10, 0, "WGT-01 coins weightless (EncumbranceOff)");
	GMTestWgtCountIs('Rune pierog schematic', 1, 0, "WGT-01 schematics never count");
	GMTestWgtCountIs('Fire Horse Saddle', 1, 6.01, "WGT-01 horse gear carried counts its full weight");
	load = w.GetEncumbrance();
	LogChannel('GMTest', "INFO WGT-01 Geralt's load " + load);
	cfg.SetVarValue('GMGameplayOptions', 'GMEncumbranceMultiplier', "50");
	GMTestWgtCountIs('Drowner brain', 100, 5, "WGT-02 'Reduce item encumbrance' at 50%");
	GMTestWgtCountIs('Bear Armor', 1, 7.5, "WGT-02 'Reduce item encumbrance' at 50%");
	GMTestReport(AbsF(w.GetEncumbrance() - load / 2) < 0.05, "WGT-02 at 50% Geralt's load " + w.GetEncumbrance() + " (half of " + load + ", within the 0.01 minimum's rounding)");
	cfg.SetVarValue('GMGameplayOptions', 'GMEncumbranceMultiplier', "100");
	GMTestWgtCountIs('Bear Armor', 1, 0, "WGT-02 'Reduce item encumbrance' at 100%");
	cfg.SetVarValue('GMGameplayOptions', 'GMEncumbranceMultiplier', "0");
	cfg.SetVarValue('Accessibility', 'WeightlessItems', "true");
	GMTestWgtCountIs('Bear Armor', 1, 0, "DW1 'Ignore Item Weight' on: nothing counts");
	GMTestReport(w.GetEncumbrance() == 0, "DW1 'Ignore Item Weight' on: Geralt's load " + w.GetEncumbrance());
	cfg.SetVarValue('GMGameplayOptions', 'GMEncumbranceMultiplier', prevMult);
	cfg.SetVarValue('Accessibility', 'WeightlessItems', prevIgnore);
	w.UpdateEncumbrance();
}

exec function gmtest_wgt04()
{
	thePlayer.GMTestCount(true, true);
	GMTest_wgt04();
	LogChannel('GMTest', "SUMMARY wgt04: " + thePlayer.gmTestPassed + " passed, " + thePlayer.gmTestFailed + " failed");
}

// WGT-07 to WGT-09, slice W5: Geralt's load raised to a share over his carry limit (read from the game) with a
// stack of Drowner brains (0.1 each, WGT-04) in his inventory; returns the stacks' ids (a stack holds 1,000;
// remove them afterwards).
function GMTestWgtOverload(share : float, out ids : array<SItemUniqueId>) : bool
{
	var w : W3PlayerWitcher;
	var limit, need : float;
	var hb : bool;
	var qty : int;

	w = GetWitcherPlayer();
	limit = w.GetMaxRunEncumbrance(hb);
	need = limit * (1 + share) + 0.05 - w.GetEncumbrance();
	if(share > 0 && need < 1.05)
		need = 1.05;	// over the limit by at least 1 (UpdateEncumbrance's threshold)
	qty = CeilF(need / 0.1);
	if(qty < 1)
		return false;
	ids = w.GetInventory().AddAnItem('Drowner brain', qty, true, true);
	if(ids.Size() == 0)
		return false;
	w.UpdateEncumbrance();
	return true;
}

function GMTestWgtUnload(ids : array<SItemUniqueId>)
{
	var w : W3PlayerWitcher;
	var i : int;

	w = GetWitcherPlayer();
	for(i = 0; i < ids.Size(); i += 1)
		if(w.GetInventory().IsIdValid(ids[i]))
			w.GetInventory().RemoveItem(ids[i], w.GetInventory().GetItemQuantity(ids[i]));
	w.UpdateEncumbrance();
}

// The horse's gallop answer (OnCanGallop asks CanCanter), or -1 when Roach is not spawned.
function GMTestWgtCanGallop() : int
{
	var horse : CNewNPC;
	var comp : W3HorseComponent;

	horse = thePlayer.GetHorseWithInventory();
	if(!horse)
		return -1;
	comp = horse.GetHorseComponent();
	if(!comp)
		return -1;
	if(comp.OnCanGallop())
		return 1;
	return 0;
}

// WGT-07: a dodge's and a sprint's cost at 20% and 120% over the limit: x (1 + armor + share) / (1 + armor),
// the share capped at 1. WGT-08: fast travel blocked while overburdened, allowed again after the drop.
// WGT-09: Roach's gallop refused while overburdened (if Roach is spawned). Puts Geralt's load back.
function GMTest_wgt05()
{
	var w : W3PlayerWitcher;
	var ids : array<SItemUniqueId>;
	var hb : bool;
	var dodge0, sprint0, dodge, sprint, a, share, limit : float;
	var gallop0, gallop : int;
	var ft0 : bool;
	var shares : array<float>;
	var i : int;

	w = GetWitcherPlayer();
	w.UpdateEncumbrance();
	if(w.HasBuff(EET_OverEncumbered))
	{
		GMTestReport(false, "WGT-07 test needs Geralt not overburdened (load " + w.GetEncumbrance() + " of " + w.GetMaxRunEncumbrance(hb) + ")");
		return;
	}
	dodge0 = w.GetStaminaActionCost(ESAT_Dodge, '', 0);
	sprint0 = w.GetStaminaActionCost(ESAT_Sprint, '', 1);
	a = GMStaminaArmorPenalty();
	gallop0 = GMTestWgtCanGallop();
	ft0 = w.IsActionAllowed(EIAB_FastTravel);	// other blocks (the regression's spawned enemies) may hold it
	GMTestReport(!w.IsActionBlockedBy(EIAB_FastTravel, 'OverEncumbered') && GMOverEncumbrancePenalty() == 0, "WGT-07/08 not overburdened: no cost share, fast travel not blocked for the load");
	shares.PushBack(0.2); shares.PushBack(1.2);
	for(i = 0; i < shares.Size(); i += 1)
	{
		if(!GMTestWgtOverload(shares[i], ids))
		{
			GMTestReport(false, "WGT-07 could not overload Geralt");
			continue;
		}
		limit = w.GetMaxRunEncumbrance(hb);
		share = ClampF(w.GetEncumbrance() / limit - 1, 0, 1);
		dodge = w.GetStaminaActionCost(ESAT_Dodge, '', 0);
		sprint = w.GetStaminaActionCost(ESAT_Sprint, '', 1);
		GMTestReport(w.HasBuff(EET_OverEncumbered) && AbsF(GMOverEncumbrancePenalty() - share) < 0.001 && AbsF(dodge / dodge0 - (1 + a + share) / (1 + a)) < 0.001,
			"WGT-07 load " + w.GetEncumbrance() + " of " + limit + " (share " + share + "): dodge " + dodge + " vs " + dodge0 + " (expected x" + (1 + a + share) / (1 + a) + ", armor " + a + ")");
		GMTestReport(AbsF(sprint / sprint0 - (1 + a + share) / (1 + a)) < 0.001,
			"WGT-07 sprint per second " + sprint + " vs " + sprint0 + " (share " + share + ")");
		GMTestReport(w.IsActionBlockedBy(EIAB_FastTravel, 'OverEncumbered') && !w.IsActionAllowed(EIAB_FastTravel) && !w.IsActionAllowed(EIAB_RunAndSprint), "WGT-08 overburdened: fast travel blocked (and running, 5.x)");
		if(i == 0)
		{
			gallop = GMTestWgtCanGallop();
			if(gallop0 == 1)
				GMTestReport(gallop == 0, "WGT-09 overburdened: Roach's gallop refused (" + gallop + "; before " + gallop0 + ")");
			else
				LogChannel('GMTest', "INFO WGT-09 gallop not checked: Roach " + (gallop0 < 0 ? "not spawned" : "could not gallop before") );
		}
		GMTestWgtUnload(ids);
		ids.Clear();
	}
	GMTestReport(!w.HasBuff(EET_OverEncumbered) && !w.IsActionBlockedBy(EIAB_FastTravel, 'OverEncumbered') && w.IsActionAllowed(EIAB_FastTravel) == ft0 && AbsF(w.GetStaminaActionCost(ESAT_Dodge, '', 0) - dodge0) < 0.001,
		"WGT-08 after the drop: the load's fast-travel block gone (fast travel as before: " + ft0 + "), dodge back to " + dodge0);
	GMTestWgt05Classes();
	GMTestWgt05Canter();
}

// WGT audit F2 (its probes A3 and A4, adopted): the costs WGT-07 changes and those it leaves alone.
function GMTestWgt05Costs(out dodge : float, out attack : float, out jump : float, out sign : float, out item : float, out whirl : float)
{
	var w : W3PlayerWitcher;

	w = GetWitcherPlayer();
	dodge = w.GetStaminaActionCost(ESAT_Dodge, '', 0);
	attack = w.GetStaminaActionCost(ESAT_HeavyAttack, '', 0);
	jump = w.GetStaminaActionCost(ESAT_Jump, '', 0);
	sign = ((W3PlayerAbilityManager)w.GetAbilityManager()).GetSkillStaminaUseCost(S_Magic_1);
	item = w.GetStaminaActionCost(ESAT_UsableItem, '', 0);
	whirl = w.GetStaminaActionCost(ESAT_Ability, 'sword_s1', 1);
}

// WGT-07 with the armor classes (A3): naked, four light and four heavy pieces, each at 30% over the limit: a dodge,
// a heavy attack and a jump x (1 + armor + share) / (1 + armor); Aard, a usable item and Whirl unchanged (legacy:
// melee and agility actions only). Puts the gear and the load back.
function GMTestWgt05Class(label : string, names : array<name>, old : array<SItemUniqueId>)
{
	var w : W3PlayerWitcher;
	var added, ids : array<SItemUniqueId>;
	var d0, a0, j0, s0, i0, wh0, d1, a1, j1, s1, i1, wh1, arm, share, r, limit : float;
	var hb : bool;

	w = GetWitcherPlayer();
	w.UnequipItemFromSlot(EES_Armor); w.UnequipItemFromSlot(EES_Boots); w.UnequipItemFromSlot(EES_Gloves); w.UnequipItemFromSlot(EES_Pants);
	if(names.Size() > 0)
		GMTestArmWear(names, added);
	w.UpdateEncumbrance();
	arm = GMStaminaArmorPenalty();
	GMTestWgt05Costs(d0, a0, j0, s0, i0, wh0);
	if(!GMTestWgtOverload(0.3, ids))
		GMTestReport(false, "WGT-07 " + label + ": could not overload Geralt");
	else
	{
		limit = w.GetMaxRunEncumbrance(hb);
		share = ClampF(w.GetEncumbrance() / limit - 1, 0, 1);
		r = (1 + arm + share) / (1 + arm);
		GMTestWgt05Costs(d1, a1, j1, s1, i1, wh1);
		GMTestReport(w.HasBuff(EET_OverEncumbered) && AbsF(d1 / d0 - r) < 0.001 && AbsF(a1 / a0 - r) < 0.001 && AbsF(j1 / j0 - r) < 0.001,
			"WGT-07 " + label + " (armor " + arm + ", share " + share + "): dodge " + d0 + " -> " + d1 + ", heavy attack " + a0 + " -> " + a1 + ", jump " + j0 + " -> " + j1 + " (expected x" + r + ")");
		GMTestReport(AbsF(s1 - s0) < 0.001 && AbsF(i1 - i0) < 0.001 && AbsF(wh1 - wh0) < 0.001,
			"WGT-07 " + label + ": Aard " + s0 + " -> " + s1 + ", usable item " + i0 + " -> " + i1 + ", Whirl per second " + wh0 + " -> " + wh1 + " (unchanged)");
		GMTestWgtUnload(ids);
	}
	GMTestArmRestore(added, old);
}

function GMTestWgt05Classes()
{
	var w : W3PlayerWitcher;
	var old : array<SItemUniqueId>;
	var names : array<name>;
	var types : array<EEffectType>;
	var kept : array<SGMTestEfxSavedBuff>;

	w = GetWitcherPlayer();
	// The Armorer's Table and grindstone buffs (ITEM-12's regression check leaves them on for gmtest_panel()) lose
	// their ability when the gear comes off: saved here and put back with the gear.
	types.PushBack(EET_EnhancedArmor);
	types.PushBack(EET_EnhancedWeapon);
	kept = GMTestEfxSaveBuffs(types);
	old = GMTestArmWorn();
	GMTestWgt05Class("naked", names, old);
	names.PushBack('Light armor 01'); names.PushBack('Boots 01'); names.PushBack('Gloves 01'); names.PushBack('Pants 01');
	GMTestWgt05Class("four light pieces", names, old);
	names.Clear();
	names.PushBack('Heavy armor 01'); names.PushBack('Heavy boots 01'); names.PushBack('Heavy gloves 01'); names.PushBack('Heavy pants 01');
	GMTestWgt05Class("four heavy pieces", names, old);
	GMTestEfxRestoreBuffs(types, kept);
	w.UpdateEncumbrance();
	GMTestReport(!w.HasBuff(EET_OverEncumbered), "WGT-07 armor class checks: gear and load back (load " + w.GetEncumbrance() + ")");
}

// WGT-09 (A4): the horse state's CanCanter (wrapped by WGT-09) called on Roach's own Exploration state through a test
// method, without riding: allowed within the limit, refused 30% over it, allowed again after the drop.
@addMethod(W3HorseComponentStateExploration)
function GMTestWgtCanCanter() : bool
{
	return CanCanter();
}

function GMTestWgt05Canter()
{
	var horse : CNewNPC;
	var comp : W3HorseComponent;
	var st : W3HorseComponentStateExploration;
	var ids : array<SItemUniqueId>;
	var c0, c1, c2 : bool;

	horse = thePlayer.GetHorseWithInventory();
	if(horse)
		comp = horse.GetHorseComponent();
	if(comp)
		st = (W3HorseComponentStateExploration)comp.GetState('Exploration');
	if(!st)
	{
		GMTestReport(false, "WGT-09 no horse Exploration state (Roach " + (horse ? "spawned" : "not spawned") + ")");
		return;
	}
	c0 = st.GMTestWgtCanCanter();
	GMTestWgtOverload(0.3, ids);
	c1 = st.GMTestWgtCanCanter();
	GMTestWgtUnload(ids);
	c2 = st.GMTestWgtCanCanter();
	GMTestReport(c0 && !c1 && c2, "WGT-09 Roach's CanCanter: within the limit " + c0 + ", 30% over " + c1 + ", after the drop " + c2);
}

exec function gmtest_wgt05()
{
	thePlayer.GMTestCount(true, true);
	GMTest_wgt05();
	LogChannel('GMTest', "SUMMARY wgt05: " + thePlayer.gmTestPassed + " passed, " + thePlayer.gmTestFailed + " failed");
}

// WGT-11: leaving the Unconscious state recounts the load. Overloaded with the effect taken off by hand (as if
// the load changed while Geralt was down), the state's OnLeaveState puts the effect back. Run on its own: the
// state's code revives Geralt (full Vitality).
exec function gmtest_wgt11()
{
	var w : W3PlayerWitcher;
	var ids : array<SItemUniqueId>;
	var before, after : bool;

	thePlayer.GMTestCount(true, true);
	w = GetWitcherPlayer();
	if(GMTestWgtOverload(0.2, ids))
	{
		w.RemoveAllBuffsOfType(EET_OverEncumbered);
		before = w.HasBuff(EET_OverEncumbered);
		((CR4PlayerStateUnconscious)w.GetState('Unconscious')).OnLeaveState('Exploration');
		after = w.HasBuff(EET_OverEncumbered);
		GMTestReport(!before && after, "WGT-11 leaving Unconscious recounts the load: overburdened " + before + " -> " + after);
		GMTestWgtUnload(ids);
	}
	else
		GMTestReport(false, "WGT-11 could not overload Geralt");
	LogChannel('GMTest', "SUMMARY wgt11: " + thePlayer.gmTestPassed + " passed, " + thePlayer.gmTestFailed + " failed");
}

// WGT-10, slice W6: a boat spawned 6 m behind Geralt (the base game's gameplay boat); the boarding is its
// OnAreaEnter on the "OnBoatTrigger" area with one of Geralt's components (what the trigger sends), undone with
// OnAreaExit. Returns the boat, NULL if it could not be spawned.
function GMTestWgtBoat() : W3Boat
{
	var pos : Vector;
	var tpl : CEntityTemplate;

	tpl = (CEntityTemplate)LoadResource("environment\decorations\ships\basic\geralt_boat\gameplay_boat\gameplay_boat_base.w2ent", true);
	if(!tpl)
		return NULL;
	pos = thePlayer.GetWorldPosition() - thePlayer.GetHeadingVector() * 6;
	return (W3Boat)theGame.CreateEntity(tpl, pos, thePlayer.GetWorldRotation());
}

// Boards the boat by its trigger and steps off again; true if the boat sank.
function GMTestWgtBoard(boat : W3Boat) : bool
{
	var area : CTriggerAreaComponent;
	var activator : CComponent;
	var sank : bool;

	area = (CTriggerAreaComponent)boat.GetComponent("OnBoatTrigger");
	activator = thePlayer.GetMovingAgentComponent();
	if(!area || !activator)
	{
		LogChannel('GMTest', "INFO WGT-10 boat trigger or player component missing");
		return false;
	}
	boat.OnAreaEnter(area, activator);
	sank = boat.HasDrowned();
	boat.OnAreaExit(area, activator);
	return sank;
}

// WGT-10: the threshold check at 10% and 30% over (threshold 20), the threshold option at 5, and boardings that
// keep the boat afloat (the sinking's conditions read, not run); a boat sinks only when "Sink the boat if overencumbered" is on and Geralt is over the threshold (the former OPT
// check O4: the option off keeps it afloat). Options set in memory and put back in the same call.
function GMTest_wgt06()
{
	var cfg : CInGameConfigWrapper;
	var prevSink, prevThr : string;
	var ids : array<SItemUniqueId>;
	var boat : W3Boat;
	var w : W3PlayerWitcher;
	var hb : bool;

	w = GetWitcherPlayer();
	cfg = theGame.GetInGameConfigWrapper();
	prevSink = cfg.GetVarValue('GMGameplayOptions', 'GMSinkBoat');
	prevThr = cfg.GetVarValue('GMGameplayOptions', 'GMSinkBoatOverEnc');
	cfg.SetVarValue('GMGameplayOptions', 'GMSinkBoat', "true");
	cfg.SetVarValue('GMGameplayOptions', 'GMSinkBoatOverEnc', "20");
	GMTestReport(GetLocStringByKeyExt("gm_geralt_too_heavy") == GetLocStringById(2110992179) && GetLocStringById(2110992179) != "",
		"WGT-10 the message: " + GetLocStringByKeyExt("gm_geralt_too_heavy"));
	boat = GMTestWgtBoat();
	if(!boat)
	{
		GMTestReport(false, "WGT-10 no boat spawned");
		return;
	}
	GMTestReport(!boat.GMCheckPlayerEncumbrance(w) && !GMTestWgtBoard(boat), "WGT-10 not overburdened: the boat holds");
	boat.Destroy();
	GMTestWgtOverload(0.1, ids);
	boat = GMTestWgtBoat();
	GMTestReport(!boat.GMCheckPlayerEncumbrance(w) && !GMTestWgtBoard(boat), "WGT-10 " + RoundMath((w.GetEncumbrance() / w.GetMaxRunEncumbrance(hb) - 1) * 100) + "% over (threshold 20): the boat holds");
	cfg.SetVarValue('GMGameplayOptions', 'GMSinkBoatOverEnc', "5");
	GMTestReport(boat.GMCheckPlayerEncumbrance(w), "WGT-10 the same load with the threshold at 5%: over it");
	cfg.SetVarValue('GMGameplayOptions', 'GMSinkBoatOverEnc', "20");
	boat.Destroy();
	GMTestWgtUnload(ids);
	ids.Clear();
	GMTestWgtOverload(0.3, ids);
	boat = GMTestWgtBoat();
	cfg.SetVarValue('GMGameplayOptions', 'GMSinkBoat', "false");
	GMTestReport(boat.GMCheckPlayerEncumbrance(w) && !GMTestWgtBoard(boat), "WGT-10 30% over with 'Sink the boat' off: the boat holds (O4)");
	boat.Destroy();
	boat = GMTestWgtBoat();
	cfg.SetVarValue('GMGameplayOptions', 'GMSinkBoat', "true");
	// the sinking itself is not run: TriggerDrowning on a boat spawned on land crashed the game (slice W6)
	GMTestReport(GMGetOptionBool('GMGameplayOptions', 'GMSinkBoat') && boat.GetCanBeDestroyed() && theGame.GetLoadGameProgress() == 0 && boat.GMCheckPlayerEncumbrance(w),
		"WGT-10 30% over with 'Sink the boat' on: every condition of the sinking holds (the sinking itself: open check)");
	boat.Destroy();
	GMTestWgtUnload(ids);
	cfg.SetVarValue('GMGameplayOptions', 'GMSinkBoat', prevSink);
	cfg.SetVarValue('GMGameplayOptions', 'GMSinkBoatOverEnc', prevThr);
}

exec function gmtest_wgt06()
{
	thePlayer.GMTestCount(true, true);
	GMTest_wgt06();
	LogChannel('GMTest', "SUMMARY wgt06: " + thePlayer.gmTestPassed + " passed, " + thePlayer.gmTestFailed + " failed");
}

function GMTest_wgt()
{
	GMTest_wgtdata();
	GMTest_wgt_bags();
	GMTest_wgt04();
	GMTest_wgt05();
	GMTest_wgt06();
}

function GMTest_wgt_after()
{
}
