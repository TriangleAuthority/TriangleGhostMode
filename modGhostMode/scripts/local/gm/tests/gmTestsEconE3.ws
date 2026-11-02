// ECON slice E3 (ECON-08, ECON-09; PE6, PE7): merchants' money and contract haggling, as legacy.
//   Money: a spawned merchant holds his class's starting money × mod_funds (type × region, legacy's table),
//   restocks by his class's amount × the same factor every 3 days (GetDaysToIncreaseFunds, which
//   W3MerchantNPC.OnInteraction reads), and at spawn gets his starting money again when he holds less than
//   100 crowns (OnSpawned called again with restored = true, as a merchant loaded from a save).
//   Haggling: the negotiation popup opened by script on Contract: The White Lady (mh308_final) many times:
//   the bar's maximum is double the reward, the employer accepts up to 1.2-1.7 × the reward (too much from
//   0.3 above that), always up to double for an always-successful negotiation; offers at and above the
//   limit through the popup's result function.

@addMethod(CR4HudModuleDialog)
function GMTestHaggleRead(out maxValue : int, out minValue : int, out prettyClose : float, out tooMuch : float)
{
	maxValue = maxHaggleValue;
	minValue = minimalHagglingReward;
	prettyClose = NPCsPrettyClose;
	tooMuch = NPCsTooMuch;
}

@addMethod(CR4HudModuleDialog)
function GMTestHaggleReset()
{
	anger = 0;
	isPopupOpened = false;
}

// The class's starting money, restock and ceiling (CInventoryComponent.SetupFunds, IncreaseFunds, GetFundsMax).
function GMTestEconFundsBase(t : EInventoryFundsType, out start : int, out restock : float, out restockFixed : int)
{
	start = 0;
	restock = 0;
	restockFixed = 0;
	switch(t)
	{
		case EInventoryFunds_Poor: start = 200; restock = 100; break;
		case EInventoryFunds_Avg: start = 500; restock = 150; break;
		case EInventoryFunds_Rich: start = 1000; restock = 1000; break;
		case EInventoryFunds_RichQuickStart: start = 5000; restock = 2500; restockFixed = 1000; break;
	}
}

function GMTestEconFundsName(t : EInventoryFundsType) : string
{
	switch(t)
	{
		case EInventoryFunds_Broke: return "broke";
		case EInventoryFunds_Poor: return "poor";
		case EInventoryFunds_Avg: return "average";
		case EInventoryFunds_Rich: return "rich";
		case EInventoryFunds_RichQuickStart: return "rich quick-start";
	}
	return "unknown";
}

// One merchant: his money at spawn, the restock interval and amount, and the reset below 100 at spawn.
function GMTestEconE3Merchant(path : string, label : string, ty : name, ar : name, dist : float)
{
	var template : CEntityTemplate;
	var m : W3MerchantNPC;
	var inv : CInventoryComponent;
	var spawnData : SEntitySpawnData;
	var f, eF, restock : float;
	var start, fixed, eStart, eRestock, money, before, after60, after150, after0 : int;
	var t : EInventoryFundsType;

	template = (CEntityTemplate)LoadResource(path, true);
	m = (W3MerchantNPC)theGame.CreateEntity(template, thePlayer.GetWorldPosition() - thePlayer.GetHeadingVector() * dist, thePlayer.GetWorldRotation());
	if(!m || !m.GetInventory())
	{
		GMTestReport(false, "ECON-08 " + label + ": not spawned (" + path + ")");
		return;
	}
	inv = m.GetInventory();
	t = inv.GetFundsType();
	f = inv.GetFundsModifier();
	eF = GMTestEconFactor('mod_funds', ty) * GMTestEconFactor('mod_funds', ar);
	GMTestEconFundsBase(t, start, restock, fixed);
	eStart = (int)(start * eF);
	eRestock = fixed + (int)(restock * eF);
	money = inv.GetMoney();
	GMTestReport(AbsF(f - eF) < 0.001 && money == eStart,
		"ECON-08 " + label + " (" + GMTestEconFundsName(t) + "): money at spawn " + money + " (" + start + " x " + eF + " = " + eStart + ")");
	GMTestReport(inv.GetDaysToIncreaseFunds() == 3,
		"ECON-08 " + label + ": restocks every " + inv.GetDaysToIncreaseFunds() + " days (legacy 3, 5.x 5)");
	before = inv.GetMoney();
	inv.IncreaseFunds();
	GMTestReport(inv.GetMoney() - before == eRestock,
		"ECON-08 " + label + ": a restock adds " + (inv.GetMoney() - before) + " (" + eRestock + "), ceiling " + inv.GetFundsMax());

	// The reset at spawn, as for a merchant loaded from a save (5.x's OnSpawned sets no funds then).
	spawnData.restored = true;
	inv.SetMoney(60);
	m.OnSpawned(spawnData);
	after60 = inv.GetMoney();
	inv.SetMoney(150);
	m.OnSpawned(spawnData);
	after150 = inv.GetMoney();
	inv.RemoveMoney(inv.GetMoney()); // SetMoney(0) leaves 1 crown (AddAnItem of 0 adds one)
	m.OnSpawned(spawnData);
	after0 = inv.GetMoney();
	GMTestReport(after60 == 60 + eStart && after150 == 150 && after0 == eStart,
		"ECON-08 " + label + ": money at a restored spawn: 60 -> " + after60 + " (" + (60 + eStart) + ", legacy below 100; 5.x 60), 150 -> " + after150 + " (150), 0 -> " + after0 + " (" + eStart + ")");
	m.Destroy();
}

function GMTest_econ_e3_money()
{
	var g : string;

	g = "living_world\dialogue\generic_merchants\entities\shop_generic_merchant_";
	GMTestEconE3Merchant(g + "novigrad_weapons.w2ent", "Novigrad blacksmith", 'type_blacksmith', 'area_novigrad', 6);
	GMTestEconE3Merchant(g + "novigrad_armor.w2ent", "Novigrad armorer", 'type_armorer', 'area_novigrad', 7);
	GMTestEconE3Merchant(g + "novigrad_herbalist.w2ent", "Novigrad herbalist", 'type_herbalist', 'area_novigrad', 8);
	GMTestEconE3Merchant(g + "novigrad_merchant.w2ent", "Novigrad general merchant", 'type_general', 'area_novigrad', 9);
	GMTestEconE3Merchant("gameplay\community\shops_and_craftsmen\novigrad\temple_district\novi_temple_dist_alchemist_01.w2ent", "Novigrad alchemist", 'type_alchemist', 'area_novigrad', 10);
	GMTestEconE3Merchant(g + "skellige_weapons.w2ent", "Skellige blacksmith", 'type_blacksmith', 'area_skellige', 11);
	GMTestEconE3Merchant(g + "nomansland_armor.w2ent", "No Man's Land armorer", 'type_armorer', 'area_nml', 12);
	GMTestEconE3Merchant(g + "nomansland_innkeeper.w2ent", "No Man's Land innkeeper", 'type_inn', 'area_nml', 13);
}

function GMTestEconE3Dialog() : CR4HudModuleDialog
{
	var hud : CR4ScriptedHud;

	hud = (CR4ScriptedHud)theGame.GetHud();
	if(!hud)
		return NULL;
	return (CR4HudModuleDialog)hud.GetHudModule("DialogModule");
}

// One opening of the popup (closed again at once); its bar and borders.
function GMTestEconE3Open(dm : CR4HudModuleDialog, rwName : name, gold : int, always : bool, out maxV : int, out minV : int, out close : float, out tooMuch : float)
{
	dm.GMTestHaggleReset();
	dm.OpenMonsterHuntNegotiationPopup(rwName, gold, always);
	dm.GMTestHaggleRead(maxV, minV, close, tooMuch);
	theGame.CloseMenu('PopupMenu');
	dm.GMTestHaggleReset();
}

// An offer through the popup's result function: the employer's answer. Leaves no reward multiplier behind.
function GMTestEconE3Offer(dm : CR4HudModuleDialog, rwName : name, value : int, had : bool) : ENegotiationResult
{
	var res : ENegotiationResult;

	dm.DialogueSliderDataPopupResult(value, false);
	res = dm.GetLastNegotiationResult();
	if(!had)
		thePlayer.RemoveRewardMultiplier(rwName);
	dm.GMTestHaggleReset();
	return res;
}

function GMTest_econ_e3_haggle()
{
	var dm : CR4HudModuleDialog;
	var rewrd : SReward;
	var rwName : name;
	var i, n, gold, maxV, minV, barOk, borderOk, deals, closes, alwaysOk : int;
	var close, tooMuch, lo, hi : float;
	var had : bool;
	var res, resAbove : ENegotiationResult;

	dm = GMTestEconE3Dialog();
	rwName = 'mh308_final';
	theGame.GetReward(rwName, rewrd);
	gold = rewrd.gold;
	if(!dm || gold <= 0)
	{
		GMTestReport(false, "ECON-09 haggling: no dialog module or no reward " + rwName);
		return;
	}
	had = thePlayer.GetRewardMultiplierExists(rwName);
	n = 60;
	lo = 10;
	hi = 0;
	for(i = 0; i < n; i += 1)
	{
		GMTestEconE3Open(dm, rwName, gold, false, maxV, minV, close, tooMuch);
		if(maxV == 2 * gold && minV == gold)
			barOk += 1;
		if(close >= 1.2 - 0.0001 && close <= 1.7 + 0.0001 && AbsF(tooMuch - close - 0.3) < 0.0001)
			borderOk += 1;
		lo = MinF(lo, close);
		hi = MaxF(hi, close);
		// An offer at the border is a deal, one 2 crowns above it is not.
		dm.OpenMonsterHuntNegotiationPopup(rwName, gold, false);
		dm.GMTestHaggleRead(maxV, minV, close, tooMuch);
		theGame.CloseMenu('PopupMenu');
		res = GMTestEconE3Offer(dm, rwName, FloorF(gold * close), had);
		dm.OpenMonsterHuntNegotiationPopup(rwName, gold, false);
		dm.GMTestHaggleRead(maxV, minV, close, tooMuch);
		theGame.CloseMenu('PopupMenu');
		resAbove = GMTestEconE3Offer(dm, rwName, CeilF(gold * close) + 2, had);
		if(res == WeHaveDeal)
			deals += 1;
		if(resAbove == PrettyClose || resAbove == TooMuch)
			closes += 1;
	}
	GMTestReport(barOk == n, "ECON-09 Contract: The White Lady (" + gold + " crowns): the bar goes up to " + (2 * gold) + " in " + barOk + " of " + n + " openings (legacy double; 5.x " + FloorF(gold * 1.35) + " to " + FloorF(gold * 1.5) + ")");
	GMTestReport(borderOk == n && lo < 1.35 && hi > 1.55,
		"ECON-09 the employer accepts up to " + NoTrailZeros(lo) + " to " + NoTrailZeros(hi) + " x the reward over " + n + " openings (" + FloorF(gold * lo) + " to " + FloorF(gold * hi) + " crowns; legacy 1.2 to 1.7, too much 0.3 above; 5.x 1.07 to 1.35), " + borderOk + " in range");
	GMTestReport(deals == n && closes == n, "ECON-09 offers: at the border a deal " + deals + " of " + n + ", 2 crowns above it not a deal " + closes + " of " + n);
	for(i = 0; i < 10; i += 1)
	{
		GMTestEconE3Open(dm, rwName, gold, true, maxV, minV, close, tooMuch);
		dm.OpenMonsterHuntNegotiationPopup(rwName, gold, true);
		theGame.CloseMenu('PopupMenu');
		res = GMTestEconE3Offer(dm, rwName, 2 * gold, had);
		if(maxV == 2 * gold && AbsF(close - 2) < 0.0001 && AbsF(tooMuch - 2) < 0.0001 && res == WeHaveDeal)
			alwaysOk += 1;
	}
	GMTestReport(alwaysOk == 10, "ECON-09 an always-successful negotiation accepts up to double: " + (2 * gold) + " a deal in " + alwaysOk + " of 10");
	GMTestReport(thePlayer.GetRewardMultiplierExists(rwName) == had && !dm.IsPopupOpened(), "ECON-09 the checks leave no reward multiplier and no open popup");
}

function GMTest_econ_e3()
{
	GMTest_econ_e3_money();
	GMTest_econ_e3_haggle();
}

exec function gmtest_econ_e3()
{
	thePlayer.GMTestCount(true, true);
	GMTest_econ_e3();
	LogChannel('GMTest', "SUMMARY econ_e3: " + thePlayer.gmTestPassed + " passed, " + thePlayer.gmTestFailed + " failed");
}

// ECON-08: the restock on talking (OnInteraction "Talk" called by script, which starts the merchant's
// scene), on two spawned Novigrad weaponsmiths, the last interaction moved back 3 and 2 days: the first
// restocks, the second does not. Run gmtest_econ_e3_restock_end() afterwards, which stops the scenes and
// removes the merchants. No game time passes.
@addField(CR4Player)
var gmTestEconRestock : array<CEntity>;

function GMTestEconE3Talk(daysBack : int, dist : float) : W3MerchantNPC
{
	var template : CEntityTemplate;
	var m : W3MerchantNPC;
	var before, eRestock, start, fixed : int;
	var restock : float;

	template = (CEntityTemplate)LoadResource("living_world\dialogue\generic_merchants\entities\shop_generic_merchant_novigrad_weapons.w2ent", true);
	m = (W3MerchantNPC)theGame.CreateEntity(template, thePlayer.GetWorldPosition() - thePlayer.GetHeadingVector() * dist, thePlayer.GetWorldRotation());
	if(!m || !m.GetInventory())
	{
		GMTestReport(false, "ECON-08 restock: no merchant spawned");
		return NULL;
	}
	m.GMTestSetLastDay(GameTimeDays(theGame.GetGameTime()) - daysBack);
	before = m.GetInventory().GetMoney();
	m.OnInteraction("Talk", thePlayer);
	GMTestEconFundsBase(m.GetInventory().GetFundsType(), start, restock, fixed);
	eRestock = fixed + (int)(restock * m.GetInventory().GetFundsModifier());
	if(daysBack >= 3)
		GMTestReport(m.GetInventory().GetMoney() - before == eRestock,
			"ECON-08 talking to a Novigrad weaponsmith " + daysBack + " days after the last restock: " + before + " -> " + m.GetInventory().GetMoney() + " crowns (+" + eRestock + ": restocked)");
	else
		GMTestReport(m.GetInventory().GetMoney() == before,
			"ECON-08 talking to a Novigrad weaponsmith " + daysBack + " days after the last restock: " + before + " -> " + m.GetInventory().GetMoney() + " crowns (no restock before 3 days; 5.x 5)");
	return m;
}

exec function gmtest_econ_e3_restock()
{
	var w : W3PlayerWitcher;
	var m : W3MerchantNPC;

	w = GetWitcherPlayer();
	thePlayer.GMTestCount(true, true);
	m = GMTestEconE3Talk(2, 6);
	if(m)
		w.gmTestEconRestock.PushBack(m);
	m = GMTestEconE3Talk(3, 8);
	if(m)
		w.gmTestEconRestock.PushBack(m);
	LogChannel('GMTest', "SUMMARY econ_e3_restock: " + thePlayer.gmTestPassed + " passed, " + thePlayer.gmTestFailed + " failed");
}

exec function gmtest_econ_e3_restock_end()
{
	var w : W3PlayerWitcher;
	var i : int;

	w = GetWitcherPlayer();
	thePlayer.StopAllScenes();
	for(i = 0; i < w.gmTestEconRestock.Size(); i += 1)
	{
		((CActor)w.gmTestEconRestock[i]).StopAllScenes();
		w.gmTestEconRestock[i].Destroy();
	}
	w.gmTestEconRestock.Clear();
	LogChannel('GMTest', "INFO econ_e3_restock_end: merchants removed");
}
