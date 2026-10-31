// DIFF slice D4 (docs/features/diff.md): DIFF-07, guards who knock Geralt out take a quarter of his money on
// every mode, with no cap (legacy's rule, DD2; 5.x: 25/40/65/85%, at most 750/1,250/1,750/2,250 crowns).
//
// In the regression: GMTest_diff07() calls the Unconscious state's TakeMoneyFromPlayer on the current mode with
// 20,000 and 1,001 crowns, then restores the money. gmtest_diff07(true) does it on each of the four modes, set
// natively and put back in the same call: a mode change rebuilds every NPC's stats for that mode (the native
// SetDifficultyLevel runs the change's update too), which undid the AI-06 samples' set levels when it ran
// inside the regression, so the regression keeps to the current mode.
// In game, a real knockout by a spawned guard (the caller sets the mode first with gmtest_diff_mode):
//   gmtest_diff07_a()   records Geralt's money (once), sets it to 20,000, his Vitality to 10% and spawns a
//                       hostile Novigrad guard 3 m ahead, unfrozen, set to ENGT_Guard (the world's guards get
//                       the type from their community's spawn tree, SetNPCTypeEffector; the template alone has 1); a watcher logs each
//                       change of state and money, and makes the guard friendly and frozen once Geralt is down
//   gmtest_diff07_b()   about 25 s later: the money taken against a quarter, the branch taken (killedByGuard),
//                       game time and distance moved over the knockout; removes the guard
//   gmtest_diff07_restore()  puts back the money recorded by the first gmtest_diff07_a()

@addField(CR4Player)
var gmTestDiff07Money : int;		// Geralt's money before the first test
@addField(CR4Player)
var gmTestDiff07Recorded : bool;
@addField(CR4Player)
var gmTestDiff07Guard : CNewNPC;
@addField(CR4Player)
var gmTestDiff07Before : int;		// money set before the fight
@addField(CR4Player)
var gmTestDiff07Last : int;			// money at the watcher's last tick
@addField(CR4Player)
var gmTestDiff07State : name;
@addField(CR4Player)
var gmTestDiff07ByGuard : bool;		// the Unconscious state's killedByGuard, read while Geralt was down
@addField(CR4Player)
var gmTestDiff07Down : bool;
@addField(CR4Player)
var gmTestDiff07Drops : int;		// how many times the money fell
@addField(CR4Player)
var gmTestDiff07Time : float;		// game time (seconds) when Geralt went down
@addField(CR4Player)
var gmTestDiff07TimeUp : float;		// game time when he left the state
@addField(CR4Player)
var gmTestDiff07Pos : Vector;		// where he went down
@addField(CR4Player)
var gmTestDiff07PosUp : Vector;

@addMethod(CR4PlayerStateUnconscious)
function GMTestKilledByGuard() : bool
{
	return killedByGuard;
}

function GMTestDiff07SetMoney(m : int)
{
	thePlayer.RemoveMoney(thePlayer.GetMoney());
	thePlayer.AddMoney(m);
}

function GMTestDiff07Take(m : int) : int
{
	GMTestDiff07SetMoney(m);
	((CR4PlayerStateUnconscious)thePlayer.GetState('Unconscious')).TakeMoneyFromPlayer();
	return m - thePlayer.GetMoney();
}

function GMTest_diff07(optional allModes : bool)
{
	var start, mode : EDifficultyMode;
	var modes : array<EDifficultyMode>;
	var money, m, big, small : int;
	var ok : bool;
	var s : string;

	start = theGame.GetDifficultyMode();
	money = thePlayer.GetMoney();
	ok = true;
	if(allModes)
	{
		modes.PushBack(EDM_Easy); modes.PushBack(EDM_Medium); modes.PushBack(EDM_Hard); modes.PushBack(EDM_Hardcore);
	}
	else
		modes.PushBack(start);
	for(m = 0; m < modes.Size(); m += 1)
	{
		mode = modes[m];
		if(mode != theGame.GetDifficultyMode())
			theGame.SetDifficultyLevel(mode);
		big = GMTestDiff07Take(20000);
		small = GMTestDiff07Take(1001);
		if(big != 5000 || small != 250)
			ok = false;
		s += " " + GMTestDiffModeName(mode) + " " + big + "/" + small + ";";
	}
	if(start != theGame.GetDifficultyMode())
		theGame.SetDifficultyLevel(start);
	GMTestDiff07SetMoney(money);
	GMTestReport(ok && theGame.GetDifficultyMode() == start && thePlayer.GetMoney() == money,
		"DIFF-07 guards' toll: a quarter of 20,000 and of 1,001 crowns on " + (allModes ? "every mode" : "the current mode") + " (5,000/250; 5.x 750, 1,250, 1,750, 2,250 and 250, 400, 650, 850):" + s
		+ " mode and money put back (" + GMTestDiffModeName(theGame.GetDifficultyMode()) + ", " + thePlayer.GetMoney() + ")");
}

exec function gmtest_diff07(optional allModes : bool)
{
	thePlayer.GMTestCount(true, true);
	GMTest_diff07(allModes);
	LogChannel('GMTest', "SUMMARY diff07: " + thePlayer.gmTestPassed + " passed, " + thePlayer.gmTestFailed + " failed");
}

exec function gmtest_diff07_a(optional path : string, optional vitality : float)
{
	thePlayer.GMTestDiff07Start(path, vitality);
}

@addMethod(CR4Player)
function GMTestDiff07Start(path : string, vitality : float)
{
	var template : CEntityTemplate;
	var npc : CNewNPC;
	var pos : Vector;
	var typeWas : ENPCGroupType;

	if(path == "")
		path = "characters/npc_entities/crowd_npc/novigrad_soldier/community/novigrad_guard_lvl2_community.w2ent";
	if(vitality <= 0)
		vitality = 0.1;
	if(!gmTestDiff07Recorded)
	{
		gmTestDiff07Money = GetMoney();
		gmTestDiff07Recorded = true;
	}
	template = (CEntityTemplate)LoadResource(path, true);
	if(!template)
	{
		LogChannel('GMTest', "FAIL DIFF-07 template not found: " + path);
		return;
	}
	pos = GetWorldPosition() + GetHeadingVector() * 3;
	npc = (CNewNPC)theGame.CreateEntity(template, pos, VecToRotation(-GetHeadingVector()));
	if(!npc)
	{
		LogChannel('GMTest', "FAIL DIFF-07 no NPC spawned from " + path);
		return;
	}
	typeWas = npc.GetNPCType();
	if(typeWas != ENGT_Guard)
		npc.SetNPCType(ENGT_Guard);	// what a community's spawn tree does for the world's guards (SetNPCTypeEffector)
	npc.SetTemporaryAttitudeGroup('hostile_to_player', AGP_Default);
	gmTestDiff07Guard = npc;
	GMTestDiff07SetMoney(20000);
	GetWitcherPlayer().SetImmortalityMode(AIM_None, AIC_Default, true);
	ForceSetStat(BCS_Vitality, GetStatMax(BCS_Vitality) * vitality);
	gmTestDiff07Before = GetMoney();
	gmTestDiff07Last = gmTestDiff07Before;
	gmTestDiff07State = GetCurrentStateName();
	gmTestDiff07ByGuard = false;
	gmTestDiff07Down = false;
	gmTestDiff07Drops = 0;
	AddTimer('GMTestDiff07Watch', 0.05, true);
	LogChannel('GMTest', "INFO DIFF-07 on " + GMTestDiffModeName(theGame.GetDifficultyMode()) + ": " + npc.GetDisplayName() + " (" + path + ") spawned hostile 3 m ahead, NPC type "
		+ (int)typeWas + " from the template, now " + (int)npc.GetNPCType() + " (guard " + (npc.GetNPCType() == ENGT_Guard) + "), level " + npc.GetLevel() + "; Geralt level " + GetLevel() + ", Vitality "
		+ NoTrailZeros(GetStat(BCS_Vitality)) + " / " + NoTrailZeros(GetStatMax(BCS_Vitality)) + ", immortal " + IsImmortal() + ", money " + GetMoney()
		+ " (recorded before the tests " + gmTestDiff07Money + ")");
}

@addMethod(CR4Player)
timer function GMTestDiff07Watch(dt : float, id : int)
{
	var st : name;
	var m : int;
	var u : CR4PlayerStateUnconscious;

	st = GetCurrentStateName();
	m = GetMoney();
	if(st != gmTestDiff07State)
	{
		LogChannel('GMTest', "INFO DIFF-07 state " + gmTestDiff07State + " -> " + st + ", money " + m + ", Vitality " + NoTrailZeros(GetStat(BCS_Vitality)));
		if(st == 'Unconscious')
		{
			gmTestDiff07Down = true;
			gmTestDiff07Time = GameTimeToSeconds(theGame.GetGameTime());
			gmTestDiff07Pos = GetWorldPosition();
			if(gmTestDiff07Guard)
			{
				gmTestDiff07Guard.SetTemporaryAttitudeGroup('friendly_to_player', AGP_Default);
				gmTestDiff07Guard.SetAnimationSpeedMultiplier(0.001);
			}
		}
		else if(gmTestDiff07State == 'Unconscious')
		{
			gmTestDiff07TimeUp = GameTimeToSeconds(theGame.GetGameTime());
			gmTestDiff07PosUp = GetWorldPosition();
		}
		gmTestDiff07State = st;
	}
	if(st == 'Unconscious')
	{
		u = (CR4PlayerStateUnconscious)GetState('Unconscious');
		if(u && u.GMTestKilledByGuard())
			gmTestDiff07ByGuard = true;
	}
	if(m != gmTestDiff07Last)
	{
		LogChannel('GMTest', "INFO DIFF-07 money " + gmTestDiff07Last + " -> " + m + " in state " + st);
		if(m < gmTestDiff07Last)
			gmTestDiff07Drops += 1;
		gmTestDiff07Last = m;
	}
}

exec function gmtest_diff07_b()
{
	var taken, want : int;
	var hours : float;

	thePlayer.RemoveTimer('GMTestDiff07Watch');
	thePlayer.GMTestCount(true, true);
	taken = thePlayer.gmTestDiff07Before - thePlayer.GetMoney();
	want = (int)(thePlayer.gmTestDiff07Before * 0.25);
	hours = (thePlayer.gmTestDiff07TimeUp - thePlayer.gmTestDiff07Time) / 3600;
	GMTestReport(thePlayer.gmTestDiff07Down && thePlayer.gmTestDiff07ByGuard, "DIFF-07 Geralt knocked out by the guard (Unconscious state, killedByGuard " + thePlayer.gmTestDiff07ByGuard + ")");
	GMTestReport(taken == want && thePlayer.gmTestDiff07Drops == 1, "DIFF-07 on " + GMTestDiffModeName(theGame.GetDifficultyMode()) + ": the guard took " + taken + " of " + thePlayer.gmTestDiff07Before
		+ " crowns, " + want + " wanted (a quarter), in " + thePlayer.gmTestDiff07Drops + " drop(s)");
	GMTestReport(thePlayer.GetCurrentStateName() != 'Unconscious' && thePlayer.IsAlive(), "DIFF-07 Geralt up again: state " + thePlayer.GetCurrentStateName() + ", alive " + thePlayer.IsAlive()
		+ ", Vitality " + NoTrailZeros(thePlayer.GetStat(BCS_Vitality)) + " / " + NoTrailZeros(thePlayer.GetStatMax(BCS_Vitality)));
	LogChannel('GMTest', "INFO DIFF-07 over the knockout: game time +" + NoTrailZeros(hours) + " h, Geralt moved " + NoTrailZeros(VecDistance(thePlayer.gmTestDiff07Pos, thePlayer.gmTestDiff07PosUp)) + " m");
	thePlayer.GMTestDiff07Clear();
	LogChannel('GMTest', "SUMMARY diff07_b: " + thePlayer.gmTestPassed + " passed, " + thePlayer.gmTestFailed + " failed");
}

exec function gmtest_diff07_restore()
{
	if(thePlayer.gmTestDiff07Recorded)
		GMTestDiff07SetMoney(thePlayer.gmTestDiff07Money);
	LogChannel('GMTest', "INFO DIFF-07 money now " + thePlayer.GetMoney() + " (recorded " + thePlayer.gmTestDiff07Money + ")");
}

@addMethod(CR4Player)
function GMTestDiff07Clear()
{
	if(gmTestDiff07Guard)
		gmTestDiff07Guard.Destroy();
	gmTestDiff07Guard = NULL;
}
