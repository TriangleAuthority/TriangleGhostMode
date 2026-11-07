// In-game probes for the Yrden fix (SKL-10, 2026-11-06; docs/features/skl.md): the trap's real
// lifetime and wraiths' reaction to it (EntersYrden / LeavesYrden, isInYrden, the spectral form).
// The probes log only while gmtest_yfix_probe(true) is on.

@addField(W3PlayerWitcher)
var gmTestYfixProbe : bool;
@addField(W3YrdenEntity)
var gmTestPlacedAt : float;

function GMTestYfixOn() : bool
{
	return GetWitcherPlayer() && GetWitcherPlayer().gmTestYfixProbe;
}

exec function gmtest_yfix_probe(on : bool)
{
	var w : W3PlayerWitcher;

	w = GetWitcherPlayer();
	w.gmTestYfixProbe = on;
	LogChannel('GMTest', "INFO yfix probes " + on);
}

@wrapMethod(W3YrdenEntity)
function Place(trapPos : Vector)
{
	var w : W3PlayerWitcher;

	wrappedMethod(trapPos);
	w = GetWitcherPlayer();
	gmTestPlacedAt = theGame.GetEngineTimeAsSeconds();
	if(GMTestYfixOn())
		LogChannel('GMTest', "YFIX place t=" + gmTestPlacedAt + " alt " + IsAlternateCast() + " duration " + trapDuration + " charges " + charges + " traps " + w.yrdenEntities.Size());
}

@wrapMethod(W3YrdenEntity)
function TimedCanceled(delta : float, id : int)
{
	if(GMTestYfixOn())
		LogChannel('GMTest', "YFIX canceled t=" + theGame.GetEngineTimeAsSeconds() + " age " + (theGame.GetEngineTimeAsSeconds() - gmTestPlacedAt) + " alt " + IsAlternateCast() + " state " + GetCurrentStateName() + " duration " + trapDuration);
	wrappedMethod(delta, id);
}

@wrapMethod(W3YrdenEntityStateYrdenSlowdown)
function OnSignAborted(force : bool)
{
	if(GMTestYfixOn())
		LogChannel('GMTest', "YFIX trap aborted t=" + theGame.GetEngineTimeAsSeconds() + " age " + (theGame.GetEngineTimeAsSeconds() - parent.gmTestPlacedAt) + " force " + force);
	wrappedMethod(force);
}

@wrapMethod(BTTaskManageSpectralForm)
function OnListenedGameplayEvent(eventName : name) : bool
{
	if(GMTestYfixOn())
		LogChannel('GMTest', "YFIX spectral event " + eventName + " on " + GetNPC().GetDisplayName() + " t=" + theGame.GetEngineTimeAsSeconds());
	return wrappedMethod(eventName);
}

function GMTestYfixWraith() : CNewNPC
{
	return (CNewNPC)theGame.GetEntityByTag('gmyfix');
}

// Spawns a hostile wraith from its template dist m in front of Geralt (not frozen: its AI runs).
exec function gmtest_yfix_spawn(kind : string, optional dist : float)
{
	var template : CEntityTemplate;
	var npc : CNewNPC;

	if(dist <= 0)
		dist = 4;
	template = (CEntityTemplate)LoadResource(GMTestDummyTemplate(kind), true);
	if(!template)
	{
		LogChannel('GMTest', "FAIL yfix: no template " + kind);
		return;
	}
	npc = (CNewNPC)theGame.CreateEntity(template, thePlayer.GetWorldPosition() + thePlayer.GetHeadingVector() * dist, VecToRotation(-thePlayer.GetHeadingVector()));
	if(!npc)
	{
		LogChannel('GMTest', "FAIL yfix: " + kind + " not an NPC");
		return;
	}
	npc.AddTag('gmyfix');
	npc.SetTemporaryAttitudeGroup('hostile_to_player', AGP_Default);
	LogChannel('GMTest', "INFO yfix spawned " + kind + " " + npc.GetDisplayName() + " ShadowForm " + npc.HasAbility('ShadowForm'));
}

// Puts the wraith at the newest trap's centre (or at Geralt's feet without one).
exec function gmtest_yfix_into()
{
	var npc : CNewNPC;
	var w : W3PlayerWitcher;
	var pos : Vector;

	npc = GMTestYfixWraith();
	w = GetWitcherPlayer();
	if(!npc)
		return;
	if(w.yrdenEntities.Size() > 0 && w.yrdenEntities[w.yrdenEntities.Size() - 1])
		pos = w.yrdenEntities[w.yrdenEntities.Size() - 1].GetWorldPosition();
	else
		pos = thePlayer.GetWorldPosition();
	npc.TeleportWithRotation(pos, VecToRotation(thePlayer.GetWorldPosition() - pos));
	LogChannel('GMTest', "INFO yfix wraith moved to the trap t=" + theGame.GetEngineTimeAsSeconds());
}

// The newest trap and the wraith's state.
exec function gmtest_yfix_read()
{
	var npc : CNewNPC;
	var w : W3PlayerWitcher;
	var y : W3YrdenEntity;
	var s : string;
	var pts, prc : float;

	npc = GMTestYfixWraith();
	w = GetWitcherPlayer();
	s = "YFIX read t=" + theGame.GetEngineTimeAsSeconds() + " traps " + w.yrdenEntities.Size();
	if(w.yrdenEntities.Size() > 0)
		y = w.yrdenEntities[w.yrdenEntities.Size() - 1];
	if(y)
		s += "; newest: alt " + y.IsAlternateCast() + " state " + y.GetCurrentStateName() + " age " + (theGame.GetEngineTimeAsSeconds() - y.gmTestPlacedAt) + " duration " + y.GMTestTrapDuration() + " targets " + y.validTargetsInArea.Size();
	if(npc)
	{
		npc.GetResistValue(CDS_ShockRes, pts, prc);
		s += "; wraith alive " + npc.IsAlive() + " hostile " + (GetAttitudeBetween(thePlayer, npc) == AIA_Hostile) + " flying " + npc.IsFlying() + " isInYrden " + npc.GetBehaviorVariable('isInYrden') + " ShadowFormActive " + npc.HasAbility('ShadowFormActive') + " ShadowForm blocked " + npc.IsAbilityBlocked('ShadowForm') + " slowdown " + npc.HasBuff(EET_Slowdown);
		if(npc.HasBuff(EET_Slowdown))
			s += " " + ((W3Effect_Slowdown)npc.GetBuff(EET_Slowdown)).GMGetSlowdown();
		s += " shock res " + pts + "/" + prc;
		if(y)
			s += " dist " + VecDistance(npc.GetWorldPosition(), y.GetWorldPosition()) + " in targets " + y.validTargetsInArea.Contains(npc) + " in all " + y.allActorsInArea.Contains(npc);
	}
	LogChannel('GMTest', s);
}

exec function gmtest_yfix_kill()
{
	var npc : CNewNPC;

	npc = GMTestYfixWraith();
	if(npc)
		npc.Destroy();
}

// Why the wraith has no slowdown: what the trap's loop checks, and the effect manager's answer to the
// trap's slowdown params.
exec function gmtest_yfix_why()
{
	var npc : CNewNPC;
	var params : SCustomEffectParams;
	var cs : CBaseGameplayEffect;
	var ret : EEffectInteract;
	var s : string;
	var buffs : array<CBaseGameplayEffect>;
	var i : int;

	npc = GMTestYfixWraith();
	if(!npc)
		return;
	cs = npc.GetCurrentlyAnimatedCS();
	s = "YFIX why: animated CS";
	if(cs)
		s += " " + cs.GetEffectType();
	else
		s += " none";
	buffs = npc.GetBuffs();
	s += " recovering " + npc.GetIsRecoveringFromKnockdown() + " immune " + npc.IsImmuneToBuff(EET_Slowdown) + " buffs";
	for(i = 0; i < buffs.Size(); i += 1)
		s += " " + buffs[i].GetEffectType();
	params.effectType = EET_Slowdown;
	params.creator = thePlayer;
	params.sourceName = "yrden_mode0";
	params.isSignEffect = true;
	params.customAbilityName = '';
	params.duration = 0.2;
	params.effectValue.valueAdditive = 0.25;
	ret = npc.AddEffectCustom(params);
	s += "; AddEffectCustom " + ret + ", has it " + npc.HasBuff(EET_Slowdown);
	LogChannel('GMTest', s);
}
