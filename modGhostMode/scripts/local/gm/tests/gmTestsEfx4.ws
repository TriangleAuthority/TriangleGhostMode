// EFX slice 4's tests (docs/features/efx.md): EFX-07 burning and hits.
//
// In play (the neutral test dummy, see gmTestsEfx.ws; god() first: the unfrozen dummy fights back):
//   gmtest_efx07_scripted()    a burning (Geralt's, not a sign's) added to the frozen dummy: every hit
//                              reaction but Igni's allowed from the start, the array 1.32's size
//   gmtest_efx07_a(res)        unfreezes the dummy (so it plays its flailing), sets its burning resistance
//                              (-3: Igni's 33% chance x4, always alight; its burning 4 x 3 s) and watches
//                              it for 30 s: its burning, its animated critical state, every hit reaction
//   autocast(ST_Igni)          a real Igni sets it alight
//   gmtest_efx02_light_b()     a real light attack (sword drawn, locked on)
//   gmtest_efx07_b()           the report: the light attack's hit reaction played and stopped the flailing,
//                              a second Igni's (cast while it burns) did not

@addField(W3PlayerWitcher)
var gmTestEfx7Armed : bool;
@addField(W3PlayerWitcher)
var gmTestEfx7Until : float;
@addField(W3PlayerWitcher)
var gmTestEfx7BurnStart : float;	// when the burning was first seen (0: not yet)
@addField(W3PlayerWitcher)
var gmTestEfx7BurnEnd : float;
@addField(W3PlayerWitcher)
var gmTestEfx7BurnDuration : float;
@addField(W3PlayerWitcher)
var gmTestEfx7Animated : bool;		// the burning is the dummy's animated critical state (last sample)
@addField(W3PlayerWitcher)
var gmTestEfx7AnimStart : float;
@addField(W3PlayerWitcher)
var gmTestEfx7AnimEnd : float;
@addField(W3PlayerWitcher)
var gmTestEfx7Hits : array<string>;
// The first hit of each kind on the burning, flailing dummy: sword (light attack) and Igni.
@addField(W3PlayerWitcher)
var gmTestEfx7SwordAt : float;
@addField(W3PlayerWitcher)
var gmTestEfx7SwordAllowed : bool;
@addField(W3PlayerWitcher)
var gmTestEfx7SwordPlayed : bool;
@addField(W3PlayerWitcher)
var gmTestEfx7IgniAt : float;
@addField(W3PlayerWitcher)
var gmTestEfx7IgniAllowed : bool;
@addField(W3PlayerWitcher)
var gmTestEfx7IgniPlayed : bool;
@addField(W3PlayerWitcher)
var gmTestEfx7AnimAfterIgni : bool;

@addMethod(W3CriticalDOTEffect)
function GMTestAllowedHits() : int
{
	return allowedHits.Size();
}

function GMTestEfx7Burning(npc : CActor) : W3Effect_Burning
{
	return (W3Effect_Burning)npc.GetBuff(EET_Burning);
}

function GMTestEfx7Flailing(npc : CActor) : bool
{
	var cs : CBaseGameplayEffect;

	cs = npc.GetCurrentlyAnimatedCS();
	return cs && cs.GetEffectType() == EET_Burning;
}

// Test probe: every hit reaction of the dummy while the watch runs.
@wrapMethod(CNewNPC)
function ReactToBeingHit(damageAction : W3DamageAction, optional buffNotApplied : bool) : bool
{
	var w : W3PlayerWitcher;
	var ret, flailing, allowed, sign, burning, armed : bool;
	var now, at : float;

	w = GetWitcherPlayer();
	armed = w && w.gmTestEfx7Armed && this == GMTestDummy() && !damageAction.IsDoTDamage();	// the burning's own ticks left out
	if(armed)
	{
		now = theGame.GetEngineTimeAsSeconds();
		flailing = GMTestEfx7Flailing(this);
		allowed = CriticalBuffIsHitAllowed(GetCurrentlyAnimatedCS(), damageAction.GetHitReactionType());
		sign = damageAction.IsActionWitcherSign();
		burning = HasBuff(EET_Burning);
	}
	ret = wrappedMethod(damageAction, buffNotApplied);
	if(armed)
	{
		if(w.gmTestEfx7BurnStart > 0)
			at = now - w.gmTestEfx7BurnStart;
		w.gmTestEfx7Hits.PushBack("hit at " + NoTrailZeros(RoundTo(at, 2)) + " s of the burning: reaction " + damageAction.GetHitReactionType() + (sign ? " (sign)" : "")
			+ ", attacker Geralt " + ((CActor)damageAction.attacker == w) + ", burning " + burning + ", flailing before " + flailing + ", allowed by the burning " + allowed + ", hit animation played " + ret);
		LogChannel('GMTest', "INFO EFX-07 " + w.gmTestEfx7Hits[w.gmTestEfx7Hits.Size() - 1]);
		if(flailing && damageAction.attacker == w)
		{
			if(sign && damageAction.GetHitReactionType() == EHRT_Igni && w.gmTestEfx7IgniAt == 0)
			{
				w.gmTestEfx7IgniAt = at;
				w.gmTestEfx7IgniAllowed = allowed;
				w.gmTestEfx7IgniPlayed = ret;
			}
			else if(!sign && w.gmTestEfx7SwordAt == 0)
			{
				w.gmTestEfx7SwordAt = at;
				w.gmTestEfx7SwordAllowed = allowed;
				w.gmTestEfx7SwordPlayed = ret;
			}
		}
	}
	return ret;
}

exec function gmtest_efx07_scripted()
{
	var npc : CNewNPC;
	var params : SCustomEffectParams;
	var burn : W3Effect_Burning;
	var i, wrong : int;
	var line : string;

	npc = GMTestDummy();
	if(!npc)
	{
		GMTestReport(false, "EFX-07 no test dummy");
		return;
	}
	npc.RemoveAllBuffsOfType(EET_Burning);
	params.effectType = EET_Burning;
	params.creator = thePlayer;
	params.sourceName = "GMTest";
	npc.AddEffectCustom(params);
	burn = GMTestEfx7Burning(npc);
	if(!burn)
	{
		GMTestReport(false, "EFX-07 a burning on the dummy: did not take");
		return;
	}
	for(i = 0; i <= EnumGetMax('EHitReactionType'); i += 1)
	{
		if(burn.IsHitAllowed((EHitReactionType)i) != (i != (int)EHRT_Igni))
			wrong += 1;
		line += " " + i + "=" + burn.IsHitAllowed((EHitReactionType)i);
	}
	LogChannel('GMTest', "INFO EFX-07 burning on the dummy, hit reactions allowed:" + line + " (Igni is " + (int)EHRT_Igni + ")");
	GMTestReport(wrong == 0, "EFX-07 a burning NPC allows every hit reaction but Igni's from the start of its burning (" + wrong + " wrong; 5.x: none for the first half)");
	GMTestReport(burn.GMTestAllowedHits() == EnumGetMax('EHitReactionType') + 1, "EFX-07 the burning's allowed-hits array has one entry per hit reaction (" + burn.GMTestAllowedHits() + ", expected " + (EnumGetMax('EHitReactionType') + 1) + "; 5.x grew it twice on an NPC)");
	npc.RemoveAllBuffsOfType(EET_Burning);
}

exec function gmtest_efx07_a(optional res : float)
{
	var w : W3PlayerWitcher;
	var npc : CNewNPC;

	w = GetWitcherPlayer();
	npc = GMTestDummy();
	if(!npc)
	{
		GMTestReport(false, "EFX-07 no test dummy");
		return;
	}
	npc.RemoveAllBuffsOfType(EET_Burning);
	GMTestDummySet(npc, 'burning_resistance_perc', res);
	GMTestDummyHeal(npc);
	npc.SetAnimationSpeedMultiplier(1);
	w.gmTestEfx7Hits.Clear();
	w.gmTestEfx7BurnStart = 0;
	w.gmTestEfx7BurnEnd = 0;
	w.gmTestEfx7BurnDuration = 0;
	w.gmTestEfx7Animated = false;
	w.gmTestEfx7AnimStart = 0;
	w.gmTestEfx7AnimEnd = 0;
	w.gmTestEfx7SwordAt = 0;
	w.gmTestEfx7IgniAt = 0;
	w.gmTestEfx7AnimAfterIgni = false;
	w.gmTestEfx7Armed = true;
	w.gmTestEfx7Until = theGame.GetEngineTimeAsSeconds() + 30;
	w.GainStat(BCS_Stamina, 1000);
	w.RemoveTimer('GMTestEfx7Watch');
	w.AddTimer('GMTestEfx7Watch', 0.05, true);
	LogChannel('GMTest', "INFO EFX-07 watching the dummy for 30 s (unfrozen), burning resistance " + NoTrailZeros(GMTestDummyRead(npc, 'burning_resistance_perc')));
}

@addMethod(W3PlayerWitcher)
timer function GMTestEfx7Watch(dt : float, id : int)
{
	var npc : CNewNPC;
	var burn : W3Effect_Burning;
	var now : float;
	var flailing : bool;
	var left : string;

	npc = GMTestDummy();
	now = theGame.GetEngineTimeAsSeconds();
	if(!npc || now > gmTestEfx7Until)
	{
		gmTestEfx7Armed = false;
		RemoveTimer('GMTestEfx7Watch');
		return;
	}
	burn = GMTestEfx7Burning(npc);
	if(npc.HasBuff(EET_Burning) && burn && gmTestEfx7BurnStart == 0)
	{
		gmTestEfx7BurnStart = now;
		gmTestEfx7BurnDuration = burn.GetDurationLeft();
		LogChannel('GMTest', "INFO EFX-07 alight: burning for " + NoTrailZeros(RoundTo(gmTestEfx7BurnDuration, 2)) + " s, from a sign " + burn.IsSignEffect());
	}
	if(!npc.HasBuff(EET_Burning) && gmTestEfx7BurnStart > 0 && gmTestEfx7BurnEnd == 0)
	{
		gmTestEfx7BurnEnd = now;
		LogChannel('GMTest', "INFO EFX-07 the burning ended at " + NoTrailZeros(RoundTo(now - gmTestEfx7BurnStart, 2)) + " s of " + NoTrailZeros(RoundTo(gmTestEfx7BurnDuration, 2)));
	}
	flailing = GMTestEfx7Flailing(npc);
	if(flailing != gmTestEfx7Animated)
	{
		gmTestEfx7Animated = flailing;
		if(flailing && gmTestEfx7AnimStart == 0)
			gmTestEfx7AnimStart = now;
		if(!flailing && gmTestEfx7AnimEnd == 0)
			gmTestEfx7AnimEnd = now;
		left = "";
		if(npc.HasBuff(EET_Burning))
			left = ", " + NoTrailZeros(RoundTo(burn.GetDurationLeft(), 2)) + " s left";
		LogChannel('GMTest', "INFO EFX-07 flailing (burning the animated critical state) " + flailing + " at " + NoTrailZeros(RoundTo(now - gmTestEfx7BurnStart, 2)) + " s, burning " + npc.HasBuff(EET_Burning) + left);
	}
	if(gmTestEfx7IgniAt > 0 && flailing && npc.HasBuff(EET_Burning) && now - gmTestEfx7BurnStart > gmTestEfx7IgniAt + 0.5)
		gmTestEfx7AnimAfterIgni = true;
}

exec function gmtest_efx07_b()
{
	var w : W3PlayerWitcher;
	var npc : CNewNPC;
	var i : int;

	w = GetWitcherPlayer();
	npc = GMTestDummy();
	LogChannel('GMTest', "INFO EFX-07 burning seen " + (w.gmTestEfx7BurnStart > 0) + " (" + NoTrailZeros(RoundTo(w.gmTestEfx7BurnDuration, 2)) + " s), flailing from " + NoTrailZeros(RoundTo(w.gmTestEfx7AnimStart - w.gmTestEfx7BurnStart, 2))
		+ " s to " + NoTrailZeros(RoundTo(w.gmTestEfx7AnimEnd - w.gmTestEfx7BurnStart, 2)) + " s, burning still on " + npc.HasBuff(EET_Burning) + (w.gmTestEfx7BurnEnd > 0 ? ", ended at " + NoTrailZeros(RoundTo(w.gmTestEfx7BurnEnd - w.gmTestEfx7BurnStart, 2)) + " s" : "") + "; hits " + w.gmTestEfx7Hits.Size());
	if(w.gmTestEfx7SwordAt > 0)
		GMTestReport(w.gmTestEfx7SwordAllowed && w.gmTestEfx7SwordPlayed && w.gmTestEfx7AnimEnd > 0 && w.gmTestEfx7AnimEnd - w.gmTestEfx7BurnStart >= w.gmTestEfx7SwordAt - 0.05,
			"EFX-07 a real sword hit " + NoTrailZeros(RoundTo(w.gmTestEfx7SwordAt, 2)) + " s into a " + NoTrailZeros(RoundTo(w.gmTestEfx7BurnDuration, 2)) + " s burning (in its first half " + (w.gmTestEfx7SwordAt < 0.5 * w.gmTestEfx7BurnDuration) + ") plays its hit reaction: allowed " + w.gmTestEfx7SwordAllowed + ", played " + w.gmTestEfx7SwordPlayed
			+ ", the flailing stopped at " + NoTrailZeros(RoundTo(w.gmTestEfx7AnimEnd - w.gmTestEfx7BurnStart, 2)) + " s");
	else
		LogChannel('GMTest', "INFO EFX-07 no sword hit on the flailing dummy");
	if(w.gmTestEfx7IgniAt > 0)
		GMTestReport(!w.gmTestEfx7IgniAllowed && !w.gmTestEfx7IgniPlayed, "EFX-07 a real Igni hit " + NoTrailZeros(RoundTo(w.gmTestEfx7IgniAt, 2)) + " s into the burning plays no hit reaction: allowed " + w.gmTestEfx7IgniAllowed + ", played " + w.gmTestEfx7IgniPlayed
			+ ", still flailing half a second later " + w.gmTestEfx7AnimAfterIgni);
	else
		LogChannel('GMTest', "INFO EFX-07 no Igni hit on the flailing dummy");
}
