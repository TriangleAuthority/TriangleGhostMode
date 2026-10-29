// AI-14 checks in a real fight (AI-B audit F2), automated: each reports PASS/FAIL lines and a SUMMARY. Not in
// gmtest_regress() (they fight): run them after it, god() off (god() keeps the stagger off Geralt).
//   gmtest_ai14_toad()  the Hearts of Stone toad stays in its Yrden task after a third hit (a real Yrden cast
//                       through the input handler; the hit counter raised by script). About 10 to 40 s.
//   gmtest_ai14_quen()  an NPC's Quen staggers Geralt for the stagger's default through the replaced
//                       CBTTaskCastQuen.ProcessAction (Reinald; real light attacks). About 5 to 45 s.
// The probes of gmTestsAi14.ws feed them (the toad task's end, each ProcessAction on Geralt's melee hits).

@addField(CR4Player)
var gmTestAi14Phase : int;
@addField(CR4Player)
var gmTestAi14T : float;
@addField(CR4Player)
var gmTestAi14THit : float;
@addField(CR4Player)
var gmTestAi14Tries : int;
@addField(CR4Player)
var gmTestAi14ToadLeft : bool;
@addField(CR4Player)
var gmTestAi14ToadLen : float;
@addField(CR4Player)
var gmTestAi14ToadDone : bool;
@addField(CR4Player)
var gmTestAi14QuenHits : int;
@addField(CR4Player)
var gmTestAi14QuenDur : float;

@addMethod(W3PlayerWitcher)
function GMTestAi14ToadEnded(left : bool, len : float)
{
	gmTestAi14ToadLeft = left;
	gmTestAi14ToadLen = len;
	gmTestAi14ToadDone = true;
}

@addMethod(W3PlayerWitcher)
function GMTestAi14QuenSeen(dur : float)
{
	gmTestAi14QuenHits += 1;
	if( gmTestAi14QuenHits == 1 )
		gmTestAi14QuenDur = dur;
}

@addMethod(W3PlayerWitcher)
function GMTestAi14Spawn(path : string, distance : float) : CNewNPC
{
	var template : CEntityTemplate;
	var npc : CNewNPC;

	template = (CEntityTemplate)LoadResource(path, true);
	if( template )
		npc = (CNewNPC)theGame.CreateEntity(template, GetWorldPosition() + GetHeadingVector() * distance, VecToRotation(-GetHeadingVector()));
	if( npc )
	{
		npc.SetTemporaryAttitudeGroup('hostile_to_player', AGP_Default);
		GMTestAi14Start(npc);
	}
	return npc;
}

@addMethod(W3PlayerWitcher)
function GMTestAi14End(summary : string)
{
	RemoveTimer('GMTestAi14ToadStep');
	RemoveTimer('GMTestAi14QuenStep');
	RemoveTimer('GMTestAi14Sample');
	RemoveTimer('GMTestAi08Swing');
	if( gmTestAi14Npc )
		gmTestAi14Npc.Destroy();
	GMTestSetProbes(false);
	SetImmortalityMode(AIM_None, AIC_Default, true);
	ForceSetStat(BCS_Vitality, GetStatMax(BCS_Vitality));
	LogChannel('GMTest', "SUMMARY " + summary + ": " + gmTestPassed + " passed, " + gmTestFailed + " failed");
}

// ---- the toad in Yrden ----

// A hostile toad 3 m ahead, Geralt immortal; a real Yrden cast 2.5 s later; once its Yrden task runs, its hit
// counter is raised to 3 (as three hits that played a hit reaction); 1.5 s later the task must still run (5.x's
// ends at once). Up to three toads when one never enters the task or leaves the trap (inconclusive, no result).
exec function gmtest_ai14_toad()
{
	thePlayer.GMTestCount(true, true);
	GetWitcherPlayer().GMTestAi14ToadBegin(1);
}

@addMethod(W3PlayerWitcher)
function GMTestAi14ToadBegin(tries : int)
{
	var npc : CNewNPC;

	RemoveTimer('GMTestAi14ToadStep');
	RemoveTimer('GMTestAi14Sample');
	if( gmTestAi14Npc )
		gmTestAi14Npc.Destroy();
	gmTestAi14Tries = tries;
	gmTestAi14Phase = 0;
	gmTestAi14T = 0;
	gmTestAi14ToadDone = false;
	gmTestAi14ToadLeft = false;
	SetEquippedSign(ST_Yrden);
	npc = GMTestAi14Spawn("dlc/ep1/data/characters/npc_entities/monsters/toad.w2ent", 3);
	if( !npc )
	{
		GMTestReport(false, "AI-14 toad spawned");
		GMTestAi14End("ai14_toad");
		return;
	}
	LogChannel('GMTest', "INFO AI-14 toad check: try " + tries);
	AddTimer('GMTestAi14ToadStep', 0.25, true);
}

@addMethod(W3PlayerWitcher)
timer function GMTestAi14ToadStep(dt : float, id : int)
{
	var npc : CNewNPC;
	var i : int;
	var still : bool;

	npc = gmTestAi14Npc;
	gmTestAi14T += 0.25;
	GainStat(BCS_Stamina, GetStatMax(BCS_Stamina));
	if( !npc || !npc.IsAlive() )
	{
		GMTestReport(false, "AI-14 toad check: the toad is gone");
		GMTestAi14End("ai14_toad");
		return;
	}
	if( gmTestAi14Phase == 0 )
	{
		if( gmTestAi14T >= 2.5 )
		{
			GMTestCastInput(true);
			gmTestAi14Phase = 1;
		}
	}
	else if( gmTestAi14Phase == 1 )
	{
		GMTestCastInput(false);
		gmTestAi14Phase = 2;
	}
	else if( gmTestAi14Phase == 2 )
	{
		if( gmTestAi14ToadIn )
		{
			for( i = npc.GetHitCounter(); i < 3; i += 1 )
				npc.IncHitCounter();
			gmTestAi14THit = gmTestAi14T;
			gmTestAi14Phase = 3;
			LogChannel('GMTest', "INFO AI-14 toad in its Yrden task, hit counter raised to " + npc.GetHitCounter());
		}
		else if( gmTestAi14T > 12 )
			GMTestAi14ToadRetry("the toad never entered its Yrden task");
	}
	else if( gmTestAi14Phase == 3 )
	{
		if( gmTestAi14ToadDone && gmTestAi14ToadLeft )
			GMTestAi14ToadRetry("the toad left the trap");
		else if( gmTestAi14ToadDone || gmTestAi14T >= gmTestAi14THit + 1.5 )
		{
			still = !gmTestAi14ToadDone && gmTestAi14ToadIn;
			if( still )
				GMTestReport(true, "AI-14 the toad stays in Yrden's trap after a third hit: its task still runs 1.5 s after the hit counter reached 3 (5.x: ends at the third hit)");
			else
				GMTestReport(false, "AI-14 the toad stays in Yrden's trap after a third hit: its task ended " + NoTrailZeros(gmTestAi14ToadLen)
					+ " s after it started, " + NoTrailZeros(gmTestAi14T - gmTestAi14THit) + " s after the counter reached 3, not by leaving (5.x's rule)");
			GMTestAi14End("ai14_toad");
		}
	}
}

@addMethod(W3PlayerWitcher)
function GMTestAi14ToadRetry(why : string)
{
	LogChannel('GMTest', "INFO AI-14 toad check inconclusive: " + why);
	if( gmTestAi14Tries >= 3 )
	{
		LogChannel('GMTest', "INFO AI-14 toad check: no conclusive try in 3; run it again");
		GMTestAi14End("ai14_toad");
	}
	else
		GMTestAi14ToadBegin(gmTestAi14Tries + 1);
}

// ---- NPC Quen ----

// Reinald (whose tree casts Quen) hostile 3 m ahead, Geralt immortal with his steel sword drawn, real light attacks
// every 1.4 s until a melee hit reaches Reinald's Quen (up to 30); the probe on ProcessAction reads the stagger.
exec function gmtest_ai14_quen()
{
	var npc : CNewNPC;
	var w : W3PlayerWitcher;

	thePlayer.GMTestCount(true, true);
	w = GetWitcherPlayer();
	w.OnEquipMeleeWeapon(PW_Steel, true);
	npc = w.GMTestAi14Spawn("quests/minor_quests/no_mans_land/quest_files/mq1060_devils_pit/characters/mq1060_witcher.w2ent", 3);
	if( !npc )
	{
		GMTestReport(false, "AI-14 Reinald spawned");
		w.GMTestAi14End("ai14_quen");
		return;
	}
	w.GMTestAi14QuenBegin();
}

@addMethod(W3PlayerWitcher)
function GMTestAi14QuenBegin()
{
	gmTestAi14QuenHits = 0;
	gmTestAi14QuenDur = 0;
	gmTestAi14T = 0;
	gmTestAi08Swings = 0;
	GMTestAi14Swing(30);
	AddTimer('GMTestAi14QuenStep', 0.25, true);
}

@addMethod(W3PlayerWitcher)
timer function GMTestAi14QuenStep(dt : float, id : int)
{
	gmTestAi14T += 0.25;
	if( gmTestAi14QuenHits > 0 )
	{
		GMTestReport(gmTestAi14QuenDur > 0.2, "AI-14 NPC Quen (CBTTaskCastQuen.ProcessAction, a real melee hit on Reinald's Quen) staggers Geralt for "
			+ NoTrailZeros(gmTestAi14QuenDur) + " s (the stagger's default; 5.x 0.1 s)");
		GMTestAi14End("ai14_quen");
	}
	else if( gmTestAi14T > 45 )
	{
		LogChannel('GMTest', "INFO AI-14 Quen check inconclusive: no melee hit reached Reinald's Quen in " + gmTestAi08Swings + " swings; run it again");
		GMTestAi14End("ai14_quen");
	}
}
