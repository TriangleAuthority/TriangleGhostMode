// XBOW-08 (NPC bows and crossbows) and XBOW-09 (NPC archers' stamina): tests against real archers.
// gmtest_xbow08_setup() switches the probes on and makes Geralt immortal (he takes and reports
// damage but cannot die); gmtest_xbow08_archer(who, distance) spawns a hostile archer from
// living_world/enemy_templates/<who>.w2ent. Each arrow that hits (Geralt or, reflected, the archer)
// is logged by the wrapper of W3ArrowProjectile.ProcessDamageAction below: the archer, its held bow
// and the bow's damage, the arrow's own damage (projDMG, which 5.x scales by Geralt's level at each
// collision), the raw damage per type as the damage manager receives it, armor points, attack
// power, the damage dealt. Each shot (the arrow's release) and each start of the shoot task are
// logged with the archer's stamina; refusals for lack of stamina are counted.
// See docs/features/xbow.md.

@addField(CR4Player)
var gmTestArrowOn : bool;
@addField(CR4Player)
var gmTestArrowHits : int;
@addField(CR4Player)
var gmTestArrowRaw : float;
@addField(CR4Player)
var gmTestArrowDealt : float;
@addField(CR4Player)
var gmTestArrowShots : int;
@addField(CR4Player)
var gmTestArrowStarts : int;
@addField(CR4Player)
var gmTestArrowRefusals : int;
@addField(CR4Player)
var gmTestArrowPaid : float;
@addField(CR4Player)
var gmTestArrowLog : bool;		// log each shot and task start (false: count only)

@addMethod(CR4Player)
function GMTestArrowReset(on : bool)
{
	gmTestArrowOn = on;
	gmTestArrowHits = 0;
	gmTestArrowRaw = 0;
	gmTestArrowDealt = 0;
	gmTestArrowShots = 0;
	gmTestArrowStarts = 0;
	gmTestArrowRefusals = 0;
	gmTestArrowPaid = 0;
	gmTestArrowLog = on;
}

@addMethod(CR4Player)
function GMTestArrowQuiet()
{
	gmTestArrowLog = false;
}

@addMethod(CR4Player)
function GMTestArrowHit(raw : float, dealt : float)
{
	gmTestArrowHits += 1;
	gmTestArrowRaw += raw;
	gmTestArrowDealt += dealt;
}

@addMethod(CR4Player)
function GMTestArrowCount(kind : int, paid : float)
{
	if(kind == 0)
		gmTestArrowShots += 1;
	else if(kind == 1)
	{
		gmTestArrowStarts += 1;
		gmTestArrowPaid += paid;
	}
	else
		gmTestArrowRefusals += 1;
}

// The held bow or crossbow of an actor, for the log ('' when none).
function GMTestArcherBow(actor : CActor, out bow : SItemUniqueId) : string
{
	var inv : CInventoryComponent;
	var held : array<SItemUniqueId>;
	var i : int;
	var cat : name;

	if(!actor)
		return "";
	inv = actor.GetInventory();
	held = inv.GetHeldWeapons();
	for(i = 0; i < held.Size(); i += 1)
	{
		cat = inv.GetItemCategory(held[i]);
		if(cat == 'bow' || cat == 'crossbow')
		{
			bow = held[i];
			return inv.GetItemName(held[i]) + " (" + cat + ")";
		}
	}
	return "";
}

@wrapMethod(W3ArrowProjectile)
function ProcessDamageAction(victim : CGameplayEntity, pos : Vector, boneName : name)
{
	var actor : CActor;
	var bow : SItemUniqueId;
	var bowName, steps : string;
	var on : bool;
	var before, health, raw, dealt : float;
	var i : int;
	var pierce, silver : float;
	var victimActor : CActor;

	on = thePlayer.gmTestArrowOn;
	if(on)
	{
		actor = (CActor)caster;
		bowName = GMTestArcherBow(actor, bow);
		if(bowName != "")
		{
			pierce = actor.GetTotalWeaponDamage(bow, theGame.params.DAMAGE_NAME_PIERCING, GetInvalidUniqueId());
			silver = actor.GetTotalWeaponDamage(bow, theGame.params.DAMAGE_NAME_SILVER, GetInvalidUniqueId());
		}
		before = projDMG;
		victimActor = (CActor)victim;
		if(victimActor)
			health = victimActor.GetStat(BCS_Vitality);
		thePlayer.GMTestDmgReset();
		thePlayer.GMTestSetProbes(true);
	}
	wrappedMethod(victim, pos, boneName);
	if(on)
	{
		for(i = 0; i < thePlayer.gmTestDmgSteps.Size(); i += 1)
		{
			steps += " " + thePlayer.gmTestDmgSteps[i].dmgType + " " + NoTrailZeros(thePlayer.gmTestDmgSteps[i].rawIn) + " (armor " + NoTrailZeros(thePlayer.gmTestDmgSteps[i].pts)
				+ ", resist " + NoTrailZeros(thePlayer.gmTestDmgSteps[i].perc) + ", attack power x" + NoTrailZeros(thePlayer.gmTestDmgSteps[i].mult) + " -> " + NoTrailZeros(thePlayer.gmTestDmgSteps[i].result) + ")";
			if(thePlayer.gmTestDmgSteps[i].hitsStat)
				raw += thePlayer.gmTestDmgSteps[i].rawIn;
		}
		dealt = thePlayer.gmTestDmgFinal;
		thePlayer.GMTestArrowHit(raw, dealt);
		LogChannel('GMTest', "INFO ARROW hit " + thePlayer.gmTestArrowHits + ": " + caster.GetReadableName() + " -> " + victim.GetReadableName()
			+ ", bow " + bowName + " piercing " + NoTrailZeros(pierce) + " silver " + NoTrailZeros(silver)
			+ ", arrow projDMG " + NoTrailZeros(before) + " -> " + NoTrailZeros(projDMG) + " silver " + NoTrailZeros(projSilverDMG)
			+ ", reflected " + (isBouncedArrow || deflected) + ", Geralt level " + thePlayer.GetLevel() + ";" + steps
			+ "; dealt " + NoTrailZeros(dealt) + ", vitality " + NoTrailZeros(health) + " -> " + NoTrailZeros(victimActor.GetStat(BCS_Vitality)));
		thePlayer.ForceSetStat(BCS_Vitality, thePlayer.GetStatMax(BCS_Vitality));
	}
}

@wrapMethod(CBTTaskShoot)
function ShootProjectile()
{
	wrappedMethod();
	if(thePlayer.gmTestArrowOn)
	{
		thePlayer.GMTestArrowCount(0, 0);
		if(thePlayer.gmTestArrowLog)
			LogChannel('GMTest', "INFO ARROW shot " + thePlayer.gmTestArrowShots + " at " + NoTrailZeros(theGame.GetEngineTimeAsSeconds()) + " s: "
				+ GetActor().GetReadableName() + " stamina " + NoTrailZeros(GetActor().GetStat(BCS_Stamina)) + "/" + NoTrailZeros(GetActor().GetStatMax(BCS_Stamina))
				+ "; projectile " + arrow.GetReadableName() + " projDMG " + NoTrailZeros(arrow.projDMG));
	}
}

@wrapMethod(CBTTaskShoot)
function OnActivate() : EBTNodeStatus
{
	var before : float;
	var ret : EBTNodeStatus;

	before = GetActor().GetStat(BCS_Stamina);
	ret = wrappedMethod();
	if(thePlayer.gmTestArrowOn)
	{
		thePlayer.GMTestArrowCount(1, before - GetActor().GetStat(BCS_Stamina));
		if(thePlayer.gmTestArrowLog)
			LogChannel('GMTest', "INFO ARROW shoot task start " + thePlayer.gmTestArrowStarts + " at " + NoTrailZeros(theGame.GetEngineTimeAsSeconds()) + " s: stamina "
				+ NoTrailZeros(before) + " -> " + NoTrailZeros(GetActor().GetStat(BCS_Stamina)) + ", light-attack cost "
				+ NoTrailZeros(CalculateAttributeValue(GetActor().GetAttributeValue('light_action_stamina_cost'))));
	}
	return ret;
}

@wrapMethod(CBTTaskShoot)
function IsAvailable() : bool
{
	var ret : bool;

	ret = wrappedMethod();
	if(!ret && thePlayer.gmTestArrowOn && GetActor().GetStat(BCS_Stamina) < CalculateAttributeValue(GetActor().GetAttributeValue('light_action_stamina_cost')))
		thePlayer.GMTestArrowCount(2, 0);
	return ret;
}

exec function gmtest_xbow08_setup(optional quiet : bool)
{
	thePlayer.GMTestArrowReset(true);
	if(quiet)
		thePlayer.GMTestArrowQuiet();
	thePlayer.SetImmortalityMode(AIM_Immortal, AIC_Default, true);
	thePlayer.ForceSetStat(BCS_Vitality, thePlayer.GetStatMax(BCS_Vitality));
	LogChannel('GMTest', "INFO ARROW setup: Geralt level " + thePlayer.GetLevel() + ", vitality " + thePlayer.GetStatMax(BCS_Vitality) + ", immortal");
}

// Spawns a hostile archer (living_world/enemy_templates/<who>.w2ent) at distance metres in front of Geralt.
// skellige_bandit_bow and baron_renegade_crossbow stay and shoot; nilfgaardian_deserter_bow and the
// pirates' templates were found thousands of metres away a moment after spawning (2026-10-25).
exec function gmtest_xbow08_archer(who : string, distance : float)
{
	var template : CEntityTemplate;
	var npc : CNewNPC;
	var path : string;
	var pos : Vector;

	path = "living_world/enemy_templates/" + who + ".w2ent";
	template = (CEntityTemplate)LoadResource(path, true);
	if(!template)
	{
		LogChannel('GMTest', "INFO ARROW archer template not found: " + path);
		return;
	}
	pos = thePlayer.GetWorldPosition() + thePlayer.GetHeadingVector() * distance;
	npc = (CNewNPC)theGame.CreateEntity(template, pos, thePlayer.GetWorldRotation());
	npc.AddTag('gm_test_archer');
	npc.SetTemporaryAttitudeGroup('hostile_to_player', AGP_Default);
	npc.NoticeActor(thePlayer);
	LogChannel('GMTest', "INFO ARROW archer spawned: " + who + ", " + npc.GetReadableName() + ", level " + npc.GetLevel());
}

// Each test archer: its weapons (bows and crossbows with their damage), stamina, light-attack cost, attack power.
exec function gmtest_xbow08_info()
{
	var npcs : array<CNewNPC>;
	var inv : CInventoryComponent;
	var items : array<SItemUniqueId>;
	var i, j : int;
	var cat : name;
	var s : string;
	var ap : SAbilityAttributeValue;

	theGame.GetNPCsByTag('gm_test_archer', npcs);
	for(i = 0; i < npcs.Size(); i += 1)
	{
		inv = npcs[i].GetInventory();
		inv.GetAllItems(items);
		s = "";
		for(j = 0; j < items.Size(); j += 1)
		{
			cat = inv.GetItemCategory(items[j]);
			if(cat == 'bow' || cat == 'crossbow')
				s += " " + inv.GetItemName(items[j]) + " (" + cat + ", held " + inv.IsItemHeld(items[j]) + ", piercing "
					+ NoTrailZeros(npcs[i].GetTotalWeaponDamage(items[j], theGame.params.DAMAGE_NAME_PIERCING, GetInvalidUniqueId())) + ", silver "
					+ NoTrailZeros(npcs[i].GetTotalWeaponDamage(items[j], theGame.params.DAMAGE_NAME_SILVER, GetInvalidUniqueId())) + ")";
		}
		ap = npcs[i].GetPowerStatValue(CPS_AttackPower);
		LogChannel('GMTest', "INFO ARROW archer " + i + ": " + npcs[i].GetReadableName() + ", alive " + npcs[i].IsAlive() + ", level " + npcs[i].GetLevel()
			+ ", at " + NoTrailZeros(VecDistance(npcs[i].GetWorldPosition(), thePlayer.GetWorldPosition())) + " m; stamina " + NoTrailZeros(npcs[i].GetStat(BCS_Stamina)) + "/" + NoTrailZeros(npcs[i].GetStatMax(BCS_Stamina))
			+ ", light-attack cost " + NoTrailZeros(CalculateAttributeValue(npcs[i].GetAttributeValue('light_action_stamina_cost')))
			+ ", attack power x" + NoTrailZeros(ap.valueMultiplicative) + "; weapons:" + s);
	}
}

// The test archers' stamina set to value, its regen paused for seconds (0: not paused; < 0: resumed).
exec function gmtest_xbow09_stamina(value : float, seconds : float)
{
	var npcs : array<CNewNPC>;
	var i : int;

	theGame.GetNPCsByTag('gm_test_archer', npcs);
	for(i = 0; i < npcs.Size(); i += 1)
	{
		if(seconds < 0)
			npcs[i].ResumeStaminaRegen('gm_test_xbow09');
		if(value >= 0)
		{
			npcs[i].ForceSetStat(BCS_Stamina, value);
			npcs[i].StartStaminaRegen();	// a full NPC's regen effect is gone; a drain would restart it
		}
		if(seconds > 0)
			npcs[i].PauseStaminaRegen('gm_test_xbow09', seconds);
		LogChannel('GMTest', "INFO ARROW archer " + i + " stamina " + NoTrailZeros(npcs[i].GetStat(BCS_Stamina)) + "/" + NoTrailZeros(npcs[i].GetStatMax(BCS_Stamina)));
	}
}

exec function gmtest_xbow08_report(optional reset : bool)
{
	var p : CR4Player;

	p = thePlayer;
	LogChannel('GMTest', "INFO ARROW report: " + p.gmTestArrowShots + " shots, " + p.gmTestArrowStarts + " shoot task starts (stamina paid " + NoTrailZeros(p.gmTestArrowPaid)
		+ "), " + p.gmTestArrowRefusals + " refusals for lack of stamina; " + p.gmTestArrowHits + " hits, average raw " + NoTrailZeros(p.gmTestArrowRaw / Max(1, p.gmTestArrowHits))
		+ ", average dealt " + NoTrailZeros(p.gmTestArrowDealt / Max(1, p.gmTestArrowHits)));
	if(reset)
		p.GMTestArrowReset(p.gmTestArrowOn);
}

// Removes the test archers, the probes and Geralt's immortality.
exec function gmtest_xbow08_clear()
{
	var npcs : array<CNewNPC>;
	var i : int;

	theGame.GetNPCsByTag('gm_test_archer', npcs);
	for(i = 0; i < npcs.Size(); i += 1)
		npcs[i].Destroy();
	thePlayer.GMTestArrowReset(false);
	thePlayer.GMTestSetProbes(false);
	thePlayer.SetGuarded(false);
	thePlayer.SetImmortalityMode(AIM_None, AIC_Default, true);
	thePlayer.ForceSetStat(BCS_Vitality, thePlayer.GetStatMax(BCS_Vitality));
	LogChannel('GMTest', "INFO ARROW cleared " + npcs.Size() + " archers");
}

// XBOW-08, situation-free (in the regression): the eight NPC bow and crossbow abilities carry
// legacy's damage (piercing, silver), which an NPC's arrow now deals.
function GMTestXbowNpcBow(abl : name, pierce : float)
{
	var p, s : float;

	p = GMTestXbowValue(abl, 'PiercingDamage');
	s = GMTestXbowValue(abl, 'SilverDamage');
	GMTestReport(p == pierce && s == 4, "XBOW-08 " + abl + ": piercing " + NoTrailZeros(p) + ", silver " + NoTrailZeros(s) + " (expected " + NoTrailZeros(pierce) + ", 4)");
}

exec function gmtest_xbow08()
{
	GMTest_xbow08();
}

function GMTest_xbow08()
{
	GMTestXbowNpcBow('Bow 1 _Stats', 150);
	GMTestXbowNpcBow('Bow 2 _Stats', 150);
	GMTestXbowNpcBow('Long bow 1 _Stats', 180);
	GMTestXbowNpcBow('Long bow 2 _Stats', 180);
	GMTestXbowNpcBow('Elven bow _Stats', 200);
	GMTestXbowNpcBow('Crossbow 01 _Stats', 220);
	GMTestXbowNpcBow('Dwarven crossbow _Stats', 240);
	GMTestXbowNpcBow('Nilfgaardian crossbow _Stats', 220);
}

// XBOW-09: the shoot task's definition as a new one reads it (trees store only non-default values):
// the light-attack stamina cost, drained when the task starts (5.x: no cost, no drain).
exec function gmtest_xbow09()
{
	GMTest_xbow09();
}

function GMTest_xbow09()
{
	var taskDef : CBTTaskShootDef;

	taskDef = new CBTTaskShootDef in theGame;
	GMTestReport(taskDef && taskDef.xmlStaminaCostName == 'light_action_stamina_cost' && taskDef.drainStaminaOnUse && taskDef.checkStats,
		"XBOW-09 shoot task's stamina cost " + taskDef.xmlStaminaCostName + ", drained " + taskDef.drainStaminaOnUse + ", checked " + taskDef.checkStats
		+ " (light_action_stamina_cost, true, true; 5.x None, false)");
}
