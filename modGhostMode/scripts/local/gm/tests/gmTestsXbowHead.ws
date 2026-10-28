// XBOW-07 tests (headshots). With the probes on (gmtest_xbow_setup's shots switch them on), each
// "Headshot" event Ghost Mode sends is counted and logged with where it came from ('damage':
// ProcessAction, the headshot dealt damage; 'resists': GetDamageResists, once per damage type), and
// each bolt hit on an NPC logs the bone it hit and the events that hit sent.
// gmtest_xbow07_shoot(bone) fires a bolt by script at one bone of the test dummy: the equipped bolt's
// own projectile entity, made as the crossbow makes it (GetDeploymentItemEntity, InitializeCrossbow)
// and shot at the bone as a quick shot at a monster's targeted part is (ShootProjectileAtBone), so
// the hit, its bone and its damage are the game's; only the crossbow's animation is skipped (an aimed
// crossbow shot reads the real key, and a quick shot at a human flies at torso2). gmtest_xbow07_aimed(true)
// marks the next scripted bolts aimed, as the aimed throw does (isFromAimThrow); only those can be
// headshots (F1 (c)). See docs/features/xbow.md.

@addField(CR4Player)
public var gmTestXbow07Damage : int;

@addField(CR4Player)
public var gmTestXbow07Resists : int;

@wrapMethod(W3DamageManagerProcessor)
function GMSignalHeadshot(from : name)
{
	var p : CR4Player;

	wrappedMethod(from);
	if(GMTestProbes())
	{
		p = thePlayer;
		if(from == 'damage')
			p.gmTestXbow07Damage += 1;
		else
			p.gmTestXbow07Resists += 1;
	}
}

@wrapMethod(W3BoltProjectile)
function ProcessDamageAction(victim : CGameplayEntity, pos : Vector, boneName : name)
{
	var p : CR4Player;
	var npc : CNewNPC;

	p = thePlayer;
	p.gmTestXbow07Damage = 0;
	p.gmTestXbow07Resists = 0;
	wrappedMethod(victim, pos, boneName);
	npc = (CNewNPC)victim;
	if(GMTestProbes() && npc)
		LogChannel('GMTest', "INFO XBOW07 bolt hit bone " + boneName + " (aimed " + GMIsFromAimThrow() + ") on " + npc.GetReadableName() + " (human " + npc.IsHuman()
			+ "): Headshot events, damage " + p.gmTestXbow07Damage + ", resists " + p.gmTestXbow07Resists);
}

exec function gmtest_xbow07_shoot(bone : name, optional speed : float)
{
	var npc : CNewNPC;
	var ent : W3BoltProjectile;
	var boltId, crossId : SItemUniqueId;
	var pos : Vector;
	var groups : array<name>;
	var p : CR4Player;

	p = thePlayer;
	npc = GMTestDummy();
	if(!npc)
	{
		GMTestReport(false, "XBOW07 shot: no dummy");
		return;
	}
	if(speed <= 0)
		speed = 40;
	p.GMTestXbowShot(true);
	boltId = GMTestXbowEquippedBolt();
	crossId = GMTestXbowRanged();
	pos = p.GetWorldPosition() + VecNormalize(npc.GetWorldPosition() - p.GetWorldPosition()) * 0.8;
	pos.Z += 1.5;
	ent = (W3BoltProjectile)p.inv.GetDeploymentItemEntity(boltId, pos, p.GetWorldRotation());
	if(!ent)
	{
		GMTestReport(false, "XBOW07 shot: no bolt entity");
		return;
	}
	ent.InitializeCrossbow(p, boltId, crossId);
	ent.GMTestSetFromAimThrow(p.gmTestXbow07Aimed);	// gmtest_xbow07_aimed: the flag the aimed throw sets on the bolt before it flies
	groups.PushBack('Ragdoll');
	groups.PushBack('Static');
	groups.PushBack('Terrain');
	groups.PushBack('Water');
	groups.PushBack('Character');
	ent.ShootProjectileAtBone(0, speed, npc, bone, 30, groups);
	LogChannel('GMTest', "INFO XBOW07 shot " + p.inv.GetItemName(boltId) + " (aimed " + p.gmTestXbow07Aimed + ") at bone " + bone + " (index " + npc.GetBoneIndex(bone) + ") of "
		+ npc.GetReadableName() + ", " + NoTrailZeros(VecDistance(pos, npc.GetWorldPosition())) + " m");
}

// The lock-on target's targetable part, which a quick shot at a large monster flies at.
exec function gmtest_xbow07_vcc()
{
	var vcc : SVirtualControllerData;

	vcc = thePlayer.GetTargetableVirtualController();
	LogChannel('GMTest', "INFO XBOW07 target " + thePlayer.GetTarget().GetReadableName() + ", has targetable part " + thePlayer.HasVirtualControllerTarget()
		+ ", bone " + vcc.boneName);
}

// XBOW-07, regression (F1 (c), owner 2026-10-27): only an aimed bolt of Geralt's can be a headshot.
// A Bodkin bolt's projectile entity, made as the crossbow makes it, hits a friendly human NPC created
// 50 m below Geralt through the bolt's own ProcessDamageAction (the replaced 5.x body, with every
// wrapper of it), with the aimed flag set as the aimed throw sets it (isFromAimThrow) or not, at
// named bones; the hit's action is caught at the damage manager (W3DamageManager.ProcessAction, not
// run: no damage, no event) and its headshot flag read. The NPC, the bolt entity and the bolt added
// are removed in the same frame.
@addField(CR4Player)
public var gmTestXbow07Capture : bool;

@addField(CR4Player)
public var gmTestXbow07Caught : int;

@addField(CR4Player)
public var gmTestXbow07Headshot : bool;

@wrapMethod(W3DamageManager)
function ProcessAction(act : W3DamageAction)
{
	var p : CR4Player;

	p = thePlayer;
	if(p.gmTestXbow07Capture && act && (W3BoltProjectile)act.causer)
	{
		p.gmTestXbow07Caught += 1;
		p.gmTestXbow07Headshot = act.GetIsHeadShot();
	}
	else
		wrappedMethod(act);
}

@addMethod(W3BoltProjectile)
function GMTestXbow07Hit(victim : CNewNPC, bone : name, aimed : bool) : string
{
	var p : CR4Player;

	p = thePlayer;
	isFromAimThrow = aimed;
	collidedEntities.Clear();
	p.gmTestXbow07Caught = 0;
	p.gmTestXbow07Headshot = false;
	ProcessDamageAction(victim, victim.GetWorldPosition(), bone);
	if(p.gmTestXbow07Caught != 1)
		return "no hit";
	if(p.gmTestXbow07Headshot)
		return "headshot";
	return "body";
}

function GMTest_xbow07()
{
	var p : CR4Player;
	var template : CEntityTemplate;
	var npc : CNewNPC;
	var ent : W3BoltProjectile;
	var ids : array<SItemUniqueId>;
	var count : int;
	var r1, r2, r3, r4, r5 : string;

	p = thePlayer;
	count = p.inv.GetItemQuantityByName('Bodkin Bolt');
	template = (CEntityTemplate)LoadResource(GMTestDummyTemplate("human"), true);
	if(template)
		npc = (CNewNPC)theGame.CreateEntity(template, p.GetWorldPosition() - Vector(0, 0, 50));
	if(npc)
		npc.SetTemporaryAttitudeGroup('friendly_to_player', AGP_Default);
	ids = p.inv.AddAnItem('Bodkin Bolt', 1, true, true);
	if(ids.Size() > 0)
		ent = (W3BoltProjectile)p.inv.GetDeploymentItemEntity(ids[0], p.GetWorldPosition() - Vector(0, 0, 52), p.GetWorldRotation());
	if(npc && ent)
	{
		ent.InitializeCrossbow(p, ids[0], GMTestXbowRanged());
		p.gmTestXbow07Capture = true;
		r1 = ent.GMTestXbow07Hit(npc, 'head', false);
		r2 = ent.GMTestXbow07Hit(npc, 'pelvis', false);
		r3 = ent.GMTestXbow07Hit(npc, 'head', true);
		r4 = ent.GMTestXbow07Hit(npc, 'neck2', true);
		r5 = ent.GMTestXbow07Hit(npc, 'torso2', true);
		p.gmTestXbow07Capture = false;
	}
	GMTestReport(r1 == "body" && r2 == "body", "XBOW-07 a quick bolt is never a headshot: head " + r1 + ", a human's pelvis " + r2 + " (body, body)");
	GMTestReport(r3 == "headshot" && r4 == "headshot" && r5 == "body", "XBOW-07 an aimed bolt keeps 5.x's headshot bones: head " + r3 + ", neck2 " + r4 + ", torso2 " + r5 + " (headshot, headshot, body)");
	if(ent)
		ent.Destroy();
	if(npc)
		npc.Destroy();
	if(p.inv.GetItemQuantityByName('Bodkin Bolt') > count)
		p.inv.RemoveItemByName('Bodkin Bolt', p.inv.GetItemQuantityByName('Bodkin Bolt') - count);
}

exec function gmtest_xbow07()
{
	GMTest_xbow07();
}

// Marks the next bolts gmtest_xbow07_shoot fires as aimed (as the aimed throw does: isFromAimThrow).
exec function gmtest_xbow07_aimed(on : bool)
{
	var p : CR4Player;

	p = thePlayer;
	p.gmTestXbow07Aimed = on;
	LogChannel('GMTest', "INFO XBOW07 scripted shots aimed " + on);
}

@addField(CR4Player)
public var gmTestXbow07Aimed : bool;
