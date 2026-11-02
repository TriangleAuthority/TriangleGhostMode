// ECON slice E4 (ECON-10, DE1, PE8, PE9; docs/features/econ.md): quest reward gold, as legacy.
//
// In the regression: GMTest_econrewards() in gmtest_regress(), GMTest_econ_e4_give() in gmtest_panel() (in
// gmtest_regress()'s frame the rewards given made the panel's AI-18 stone check fail in the new tree). gmtest_econ_e4()
// runs both on their own.
//   GMTest_econrewards(): the generated table (tests/gmTestsEconRewards.ws, tools/gen_loot.py): the gold of every
//   reward ECON decides as GetReward reads it (legacy's for the 187 ECON-10 rewards and the loan, legacy's for the
//   three more rewards 5.x raised (DE1), 5.x's for 5.x's three new rewards with gold (PE9)), counted and summed by group.
//   GMTest_econ_e4_give(): rewards given through the game's own GiveReward (CR4Game.OnGiveReward, as a quest's reward
//   block or a scene's reward function) and the crowns gained compared: Emhyr's payment, the sq108 griffin, the loan,
//   a horse race, a fistfight, Hearts of Stone's finale purse, and Contract: The White Lady after a deal made through
//   the negotiation popup (its haggled multiplier applied). The bar and the employer's borders read on 250 crowns.
//   Geralt's crowns, items and experience are put back; the rewards with experience are given with Geralt's level
//   held at 100 (GMTestSetLevelOverride: 5 XP for a reward with a level, its own experience, 10, for one without;
//   taken back), and only when Geralt is more than 50 XP from his next level, so they cannot level him up.

function GMTestEconReward(rname : name, gold : int, group : int, out checks : array<int>, out sums : array<int>) : int
{
	var r : SReward;

	checks[group] += 1;
	if(theGame.GetReward(rname, r))
		sums[group] += r.gold;
	if(theGame.GetReward(rname, r) && r.gold == gold)
		return 0;
	LogChannel('GMTest', "FAIL ECON data reward " + rname + " reads gold " + r.gold + " (expected " + gold + ")");
	return 1;
}

function GMTestEconRewardGold(rname : name) : int
{
	var r : SReward;

	theGame.GetReward(rname, r);
	return r.gold;
}

function GMTest_econrewards()
{
	var checks, sums : array<int>;
	var f, i, n, g : int;
	var labels : array<string>;

	checks.Resize(5);
	sums.Resize(5);
	labels.Resize(5);
	labels[1] = "ECON-10: the rewards legacy changed (1.32 27,843 crowns over them; 5.x 28,168)";
	labels[2] = "ECON-11: the loan's reward, vivaldis_loan (1.32 100)";
	labels[3] = "DE1: the rewards 5.x raised where legacy kept 1.32's gold (5.x 14,150)";
	labels[4] = "PE9: 5.x's new rewards with gold, 5.x's";
	f = GMTestEconRewardsAll(checks, sums);
	for(i = 1; i <= 4; i += 1)
	{
		GMTestEconRewardExpected(i, n, g);
		GMTestReport(checks[i] == n && sums[i] == g, "ECON data " + labels[i] + ": " + checks[i] + " rewards read, " + sums[i] + " crowns (expected " + n + ", " + g + ")");
	}
	GMTestReport(f == 0, "ECON data: every reward's gold as legacy's (5.x's new rewards 5.x's), " + f + " differ");
	// The owner's DE1 and the porter's PE9, named.
	GMTestReport(GMTestEconRewardGold('q110_1b_accepted_emhyrs_reward') == 2000 && GMTestEconRewardGold('q605_mirror_finale_cash') == 5000
		&& GMTestEconRewardGold('q107_4_reward_baron') == 100 && GMTestEconRewardGold('q103_06_find_daughter') == 100,
		"ECON DE1 (a): Emhyr's payment " + GMTestEconRewardGold('q110_1b_accepted_emhyrs_reward') + " (legacy 2000, 5.x 4000), Hearts of Stone's finale purse "
		+ GMTestEconRewardGold('q605_mirror_finale_cash') + " (5000, 5.x 10000), the baron's payment " + GMTestEconRewardGold('q107_4_reward_baron')
		+ " (100, 5.x 150), q103_06_find_daughter " + GMTestEconRewardGold('q103_06_find_daughter') + " (100, 5.x 200)");
	GMTestReport(GMTestEconRewardGold('sq106_3_hammond_killed_crach') == 200 && GMTestEconRewardGold('mq1060_priest_reward') == 200
		&& GMTestEconRewardGold('q504_horse_returned') == 15,
		"ECON PE9: 5.x's new rewards keep 5.x's gold: Killbill's new branch " + GMTestEconRewardGold('sq106_3_hammond_killed_crach') + " (200), the mq1060 priest "
		+ GMTestEconRewardGold('mq1060_priest_reward') + " (200), the returned horse " + GMTestEconRewardGold('q504_horse_returned') + " (15)");
}

exec function gmtest_econrewards()
{
	thePlayer.GMTestCount(true, true);
	GMTest_econrewards();
	LogChannel('GMTest', "SUMMARY econrewards: " + thePlayer.gmTestPassed + " passed, " + thePlayer.gmTestFailed + " failed");
}

// One reward given through GiveReward; the crowns gained against `want`. Items the reward gives (`item`, `count`) are
// removed again, the crowns and the experience put back.
function GMTestEconGive(rname : name, want : int, label : string, optional item : name, optional count : int) : bool
{
	var w : W3PlayerWitcher;
	var r : SReward;
	var money, gained, exp, expGained, lvl, items : int;
	var ok : bool;
	var itemText : string;

	w = GetWitcherPlayer();
	theGame.GetReward(rname, r);
	money = w.GetMoney();
	exp = w.levelManager.GetPointsTotal(EExperiencePoint);
	lvl = w.levelManager.GetLevel();
	if(item != '')
		items = w.inv.GetItemQuantityByName(item);
	theGame.GiveReward(rname, thePlayer);
	gained = w.GetMoney() - money;
	expGained = w.levelManager.GetPointsTotal(EExperiencePoint) - exp;
	ok = gained == want;
	if(item != '')
	{
		itemText = ", " + item + " +" + (w.inv.GetItemQuantityByName(item) - items) + " (" + count + ")";
		ok = ok && w.inv.GetItemQuantityByName(item) == items + count;
		w.inv.RemoveItemByName(item, w.inv.GetItemQuantityByName(item) - items);
	}
	w.levelManager.GMTestTakeExp(expGained);
	if(w.GetMoney() > money)
		w.RemoveMoney(w.GetMoney() - money);
	GMTestReport(ok && w.GetMoney() == money && w.levelManager.GetPointsTotal(EExperiencePoint) == exp && w.levelManager.GetLevel() == lvl,
		"ECON-10 " + label + " (" + rname + ", gold " + r.gold + ") given: +" + gained + " crowns (" + want + ")" + itemText
		+ "; crowns, experience (+" + expGained + " taken back) and level " + lvl + " put back");
	return ok;
}

function GMTest_econ_e4_give()
{
	var w : W3PlayerWitcher;
	var dm : CR4HudModuleDialog;
	var res : ENegotiationResult;
	var maxV, minV, gap, gold, lo, hi, i : int;
	var close, tooMuch : float;
	var had : bool;

	w = GetWitcherPlayer();
	gap = w.levelManager.GetTotalExpForNextLevel() - w.levelManager.GetPointsTotal(EExperiencePoint);
	if(gap <= 50)
	{
		GMTestReport(false, "ECON-10 rewards given: Geralt " + gap + " XP from his next level, too close to give rewards with experience");
		return;
	}
	// Rewards without experience.
	GMTestEconGive('q110_1b_accepted_emhyrs_reward', 2000, "Emhyr's payment for finding Ciri (DE1; 5.x 4000)");
	GMTestEconGive('sq108_griffon_killed', 250, "the sq108 griffin (1.32 25)", 'Heavy boots 06', 1);
	GMTestEconGive('vivaldis_loan', 300, "Vivaldi's loan (ECON-11's reward; 1.32 100)");
	GMTestEconGive('hr101_2_item', 50, "a horse race (hr101; 1.32 20)", 'Horse Saddle 2', 1);
	// Rewards with experience, Geralt's level held at 100 (5 or 10 XP each, taken back).
	w.GMTestSetLevelOverride(100);
	GMTestEconGive('ff104_1_victory', 125, "a fistfight (ff104; 1.32 80)");
	GMTestEconGive('hr201_regular_reward_repeat', 50, "a repeated horse race (hr201; 1.32 30)");
	GMTestEconGive('q605_mirror_finale_cash', 5000, "Hearts of Stone's finale purse (DE1; 5.x 10000)");
	// Contract: The White Lady: legacy's 250 crowns, the negotiation popup's bar and borders, and a deal at 1.2 x
	// (always within the employer's limit) given with its multiplier.
	dm = GMTestEconE3Dialog();
	gold = GMTestEconRewardGold('mh308_final');
	had = thePlayer.GetRewardMultiplierExists('mh308_final');
	if(!dm || had)
	{
		w.GMTestSetLevelOverride(0);
		GMTestReport(false, "ECON-10 Contract: The White Lady: no dialog module, or a reward multiplier already set (" + had + ")");
		return;
	}
	lo = 10000;
	hi = 0;
	for(i = 0; i < 20; i += 1)
	{
		GMTestEconE3Open(dm, 'mh308_final', gold, false, maxV, minV, close, tooMuch);
		lo = Min(lo, FloorF(gold * close));
		hi = Max(hi, FloorF(gold * close));
	}
	GMTestReport(gold == 250 && maxV == 500 && minV == 250 && lo >= 300 && hi <= 425,
		"ECON-10 Contract: The White Lady pays " + gold + " crowns (legacy 250, 5.x 246): the bar " + minV + " to " + maxV + " (500), the employer's limit seen "
		+ lo + " to " + hi + " over 20 openings (legacy 300 to 425)");
	dm.GMTestHaggleReset();
	dm.OpenMonsterHuntNegotiationPopup('mh308_final', gold, false);
	theGame.CloseMenu('PopupMenu');
	dm.DialogueSliderDataPopupResult(300, false);
	res = dm.GetLastNegotiationResult();
	dm.GMTestHaggleReset();
	GMTestReport(res == WeHaveDeal && AbsF(thePlayer.GetRewardMultiplier('mh308_final') - 1.2) < 0.001,
		"ECON-09/10 Contract: The White Lady haggled to 300: a deal (" + res + "), multiplier " + NoTrailZeros(thePlayer.GetRewardMultiplier('mh308_final')) + " (1.2)");
	GMTestEconGive('mh308_final', 300, "Contract: The White Lady after the deal at 300");
	if(thePlayer.GetRewardMultiplierExists('mh308_final'))
		thePlayer.RemoveRewardMultiplier('mh308_final');
	GMTestReport(!thePlayer.GetRewardMultiplierExists('mh308_final') && !dm.IsPopupOpened(), "ECON-10 the reward used its multiplier up; no popup left open");
	w.GMTestSetLevelOverride(0);
}

function GMTest_econ_e4()
{
	GMTest_econrewards();
	GMTest_econ_e4_give();
}

exec function gmtest_econ_e4()
{
	thePlayer.GMTestCount(true, true);
	GMTest_econ_e4();
	LogChannel('GMTest', "SUMMARY econ_e4: " + thePlayer.gmTestPassed + " passed, " + thePlayer.gmTestFailed + " failed");
}
