// AI slice C1 tests (AI-15 the Wild Hunt, AI-16 weakened states and the djinn); docs/features/ai.md.
//
// Regression: GMTest_ai15() (gmtest_regress) spawns a Wild Hunt warrior, a hound of the Hunt and Eredin, frozen and
// neutral, far behind Geralt, and sets the hound burning with Ice Armor on (the warriors are immune to burning); GMTest_ai15_after() (gmtest_panel, after the burning's
// ticks and the level-bonus timer) checks the burning's fire took the Ice Armor off, Ice Armor's +30% resistances
// in a crafted hit (5.x: the damage halved), a fire hit taking it off (5.x: only Igni), a sign hit hurting Eredin
// (5.x: none while he has EredinInvulnerable), the weakened state's -15% physical resistances (Olgierd's,
// SetWeakenedState), and removes them. The abilities' values are in the generated data table (GMTest_ai03).
//
// Real fights (probes log "C1EV" lines, channel GMTestAI): gmtest_ai15_a("<path>", distance, iceArmor) spawns an
// enemy hostile `distance` m ahead (the silver sword drawn if asked) through gmtest_ai14_a's sampler (Geralt immortal, its health refilled), with Ice
// Armor on if asked; the probes log every hit on it (each damage type's resistance as GetDamageResists left it, Ice
// Armor before and after, the damage) and every hit it lands on Geralt (each damage type, the damage, the frost
// slowdown); gmtest_ai15_ice() puts Ice Armor on it again; gmtest_ai15_bomb_a(item)/_release() throw a bomb at it;
// gmtest_ai14_b() sums up and removes it.

@addField(CR4Player)
var gmTestAi15Npcs : array<CNewNPC>;

// ---- regression ----

function GMTestAi15Spawn(path : string, distance : float, side : float) : CNewNPC
{
	var template : CEntityTemplate;
	var npc : CNewNPC;
	var pos, h : Vector;

	template = (CEntityTemplate)LoadResource(path, true);
	if( !template )
		return NULL;
	h = thePlayer.GetHeadingVector();
	pos = thePlayer.GetWorldPosition() - h * distance + Vector(h.Y, -h.X, 0) * side;
	npc = (CNewNPC)theGame.CreateEntity(template, pos, VecToRotation(thePlayer.GetHeadingVector()));
	if( !npc )
		return NULL;
	npc.SetTemporaryAttitudeGroup('neutral_to_player', AGP_Default);
	npc.SetAttitude(thePlayer, AIA_Neutral);
	npc.SetAnimationSpeedMultiplier(0.001);
	return npc;
}

@addMethod(W3PlayerWitcher)
function GMTestAi15Set(npcs : array<CNewNPC>)
{
	gmTestAi15Npcs = npcs;
}

// AI-15: spawns the NPCs GMTest_ai15_after() reads; one warrior burns with Ice Armor on (no creator: its ticks only).
function GMTest_ai15()
{
	var npcs : array<CNewNPC>;
	var w1, w2, eredin, djinn : CNewNPC;
	var params : SCustomEffectParams;
	var res : EEffectInteract;

	w1 = GMTestAi15Spawn("gameplay/templates/characters/presets/wild_hunt/wlh_2h_sword.w2ent", 40, 6);
	w2 = GMTestAi15Spawn("characters/npc_entities/monsters/wildhunt_minion_lvl1.w2ent", 40, -6);	// a hound: the warriors are immune to burning
	eredin = GMTestAi15Spawn("quests/main_npcs/eredin.w2ent", 48, 0);
	djinn = GMTestAi15Spawn("quests/secondary_npcs/djinn.w2ent", 56, 0);
	npcs.PushBack(w1);
	npcs.PushBack(w2);
	npcs.PushBack(eredin);
	npcs.PushBack(djinn);
	GetWitcherPlayer().GMTestAi15Set(npcs);
	GMTestReport(w1 && w2 && eredin && djinn, "AI-15 a Wild Hunt warrior, a hound of the Hunt, Eredin and the djinn spawned");
	if( w2 )
	{
		w2.AddAbility('IceArmor', false);
		params.effectType = EET_Burning;
		params.creator = thePlayer;	// neutral to Geralt: not refused
		params.sourceName = "gmtest_ai15";
		params.duration = 10;
		res = w2.AddEffectCustom(params);
		LogChannel('GMTest', "INFO AI-15 burning added to a hound with Ice Armor: " + res + ", burning " + w2.HasBuff(EET_Burning));
	}
}

// A crafted hit of Geralt's on `npc` (W3DamageAction, not melee: no melee roll, no crit, no parry) with `amount` of `dmgType`, a sign's
// if `sign`; returns the health it took.
function GMTestAi15Hit(npc : CNewNPC, dmgType : name, amount : float, sign : bool) : float
{
	var action : W3DamageAction;
	var before : float;
	var stat : EBaseCharacterStats;

	stat = BCS_Vitality;
	if( npc.UsesEssence() )
		stat = BCS_Essence;
	npc.ForceSetStat(stat, npc.GetStatMax(stat));
	before = npc.GetStat(stat);
	action = new W3DamageAction in theGame.damageMgr;
	if( sign )
	{
		action.Initialize(thePlayer, npc, NULL, "gmtest_ai15", EHRT_Light, CPS_SpellPower, false, true, true, false);
		action.SetSignSkill(S_Magic_1);
	}
	else
		action.Initialize(thePlayer, npc, NULL, "gmtest_ai15", EHRT_Light, CPS_AttackPower, false, false, false, false);	// not melee: no guard or parry
	action.AddDamage(dmgType, amount);
	theGame.damageMgr.ProcessAction(action);
	LogChannel('GMTest', "INFO AI-15 crafted hit " + dmgType + " " + NoTrailZeros(amount) + " on " + npc.GetReadableName() + ": dealt " + NoTrailZeros(action.GetDamageDealt())
		+ ", health lost " + NoTrailZeros(before - npc.GetStat(stat)) + ", IceArmor " + npc.HasAbility('IceArmor'));
	delete action;
	return before - npc.GetStat(stat);
}

function GMTestAi15AttackPower(npc : CNewNPC) : float
{
	var emptyTags : array<name>;
	var ap : SAbilityAttributeValue;

	ap = npc.GetCharacterStats().GetAttributeValue('attack_power', emptyTags);
	return ap.valueMultiplicative;
}

function GMTestAi15Resist(npc : CNewNPC, dmg : ECharacterDefenseStats) : float
{
	var pts, perc : float;

	npc.GetResistValue(dmg, pts, perc);
	return perc;
}

// AI-15, AI-16 on the NPCs GMTest_ai15() spawned; removes them.
function GMTest_ai15_after()
{
	var npcs : array<CNewNPC>;
	var w1, w2, eredin, djinn : CNewNPC;
	var ap0, ap1, ap2 : float;
	var r, pts, armor, raw, d0, d1, want, got, r0, r1 : float;
	var still : bool;
	var i : int;

	npcs = thePlayer.gmTestAi15Npcs;
	if( npcs.Size() < 4 || !npcs[0] || !npcs[1] || !npcs[2] || !npcs[3] )
	{
		GMTestReport(false, "AI-15 test NPCs spawned (" + npcs.Size() + ")");
		return;
	}
	w1 = npcs[0];
	w2 = npcs[1];
	eredin = npcs[2];
	djinn = npcs[3];

	// Any fire removes Ice Armor: the burning's ticks did (5.x: Igni only).
	still = w2.HasAbility('IceArmor');
	GMTestReport(!still, "AI-15 a burning hound of the Wild Hunt lost its Ice Armor to the burning's ticks: " + !still + " (burning now " + w2.HasBuff(EET_Burning) + "; 5.x: only Igni removes it)");
	w2.RemoveAllBuffsOfType(EET_Burning);

	// Ice Armor: +30% resistances (5.x: the damage halved after the formula).
	w1.RemoveAllBuffsOfType(EET_Burning);
	w1.RemoveAbility('IceArmor');
	w1.GetResistValue(CDS_PhysicalRes, pts, r);	// silver damage: physical resistance (an Essence user takes no slashing)
	armor = CalculateAttributeValue(w1.GetTotalArmor());
	raw = armor + pts + 200;	// past its armor and points, well below its health
	d0 = GMTestAi15Hit(w1, theGame.params.DAMAGE_NAME_SILVER, raw, false);
	w1.AddAbility('IceArmor', false);
	d1 = GMTestAi15Hit(w1, theGame.params.DAMAGE_NAME_SILVER, raw, false);
	want = (1 - MinF(1, MaxF(0, r) + 0.3)) / (1 - MaxF(0, r));
	got = -1;
	if( d0 > 0 )
		got = d1 / d0;
	GMTestReport(d0 > 0 && AbsF(got - want) < 0.01 && w1.HasAbility('IceArmor'),
		"AI-15 Ice Armor adds 30% to a Wild Hunt warrior's resistances: a silver hit with it deals " + NoTrailZeros(got) + " of one without (want " + NoTrailZeros(want)
		+ " at " + NoTrailZeros(r * 100) + "% physical resistance; 5.x 0.5), and a hit without fire leaves it on");

	// Any fire hit removes it (5.x: Igni only).
	GMTestAi15Hit(w1, theGame.params.DAMAGE_NAME_FIRE, armor + 50, false);	// past its armor: fire damage dealt
	still = w1.HasAbility('IceArmor');
	GMTestReport(!still, "AI-15 a fire hit (not Igni) takes a Wild Hunt warrior's Ice Armor off: " + !still + " (5.x: only Igni)");

	// AI-16: the weakened state (Olgierd's, SetWeakenedState: the animation event's and the behaviour task's call).
	w1.AddTag('olgierd_gpl');
	r0 = GMTestAi15Resist(w1, CDS_SlashingRes);
	w1.SetWeakenedState(true);
	r1 = GMTestAi15Resist(w1, CDS_SlashingRes);
	GMTestReport(w1.HasAbility('WeakenedState') && AbsF(r1 - (r0 - 0.15)) < 0.001,
		"AI-16 a weakened enemy (WeakenedState) has 15% less physical resistance: slashing " + NoTrailZeros(r0 * 100) + "% -> " + NoTrailZeros(r1 * 100) + "% (5.x: unchanged)");
	w1.SetWeakenedState(false);
	w1.RemoveTag('olgierd_gpl');

	// Eredin is no longer immune to signs (5.x: a sign's hit deals nothing to an actor with EredinInvulnerable, which no
	// XML defines: the ability is given here by name, as a script or tree would).
	eredin.AddAbility('EredinInvulnerable', false);
	d0 = GMTestAi15Hit(eredin, theGame.params.DAMAGE_NAME_FORCE, 300, true);
	GMTestReport(d0 > 0, "AI-15 a sign's hit hurts Eredin (a negative check: no XML defines EredinInvulnerable and AddAbility refuses it, so 5.x's immunity never applied): "
		+ NoTrailZeros(d0) + " Essence (EredinInvulnerable held " + eredin.HasAbility('EredinInvulnerable') + ")");

	// AI-16: the djinn's rage +50% attack power, its weakness -50% (5.x: stamina regen only); the abilities its rage task adds.
	ap0 = GMTestAi15AttackPower(djinn);
	djinn.AddAbility('DjinnRage', false);
	ap1 = GMTestAi15AttackPower(djinn);
	djinn.RemoveAbility('DjinnRage');
	djinn.AddAbility('DjinnWeak', false);
	ap2 = GMTestAi15AttackPower(djinn);
	djinn.RemoveAbility('DjinnWeak');
	GMTestReport(AbsF(ap1 - ap0 - 0.5) < 0.001 && AbsF(ap0 - ap2 - 0.5) < 0.001, "AI-16 the djinn's rage adds 50% attack power, its weakness takes 50%: x" + NoTrailZeros(ap0)
		+ " -> x" + NoTrailZeros(ap1) + " in rage, x" + NoTrailZeros(ap2) + " weakened (5.x: unchanged)");

	for( i = 0; i < npcs.Size(); i += 1 )
		if( npcs[i] )
			npcs[i].Destroy();
	npcs.Clear();
	GetWitcherPlayer().GMTestAi15Set(npcs);
}

exec function gmtest_ai15()
{
	thePlayer.GMTestCount(true, true);
	GMTest_ai15();
	LogChannel('GMTest', "SUMMARY ai15: " + thePlayer.gmTestPassed + " passed, " + thePlayer.gmTestFailed + " failed (run gmtest_ai15_after() a few seconds later)");
}

exec function gmtest_ai15_after()
{
	thePlayer.GMTestCount(true, true);
	GMTest_ai15_after();
	LogChannel('GMTest', "SUMMARY ai15_after: " + thePlayer.gmTestPassed + " passed, " + thePlayer.gmTestFailed + " failed");
}

// ---- real fights ----

exec function gmtest_ai15_a(path : string, optional distance : float, optional iceArmor : bool, optional silver : bool)
{
	var template : CEntityTemplate;
	var npc : CNewNPC;

	if( distance <= 0 )
		distance = 6;
	template = (CEntityTemplate)LoadResource(path, true);
	if( !template )
	{
		LogChannel('GMTest', "INFO AI-15: no template " + path);
		return;
	}
	npc = (CNewNPC)theGame.CreateEntity(template, thePlayer.GetWorldPosition() + thePlayer.GetHeadingVector() * distance, VecToRotation(-thePlayer.GetHeadingVector()));
	if( !npc )
		return;
	npc.SetTemporaryAttitudeGroup('hostile_to_player', AGP_Default);
	GetWitcherPlayer().GMTestAi14Start(npc);
	if( silver )
		GetWitcherPlayer().OnEquipMeleeWeapon(PW_Silver, true);
	if( iceArmor )
		GMTestAi15Ice(npc);
	GMTestAi15Info(npc);
}

function GMTestAi15Ice(npc : CNewNPC)
{
	if( !npc.HasAbility('IceArmor') )
		npc.AddAbility('IceArmor', false);
	npc.PlayEffect('ice_armor');
	LogChannel('GMTestAI', "C1EV ice armor on " + npc.GetReadableName() + ": " + npc.HasAbility('IceArmor'));
}

function GMTestAi15Info(npc : CNewNPC)
{
	var weapons : array<SItemUniqueId>;
	var inv : CInventoryComponent;
	var i : int;
	var s : string;
	var frost, slash, ap : SAbilityAttributeValue;
	var emptyTags : array<name>;
	var abls : array<name>;
	var ablStr : string;

	inv = npc.GetInventory();
	weapons = inv.GetHeldWeapons();
	s = "";
	for( i = 0; i < weapons.Size(); i += 1 )
	{
		frost = inv.GetItemAttributeValue(weapons[i], 'FrostDamage');
		slash = inv.GetItemAttributeValue(weapons[i], 'SlashingDamage');
		s += " " + inv.GetItemName(weapons[i]) + " (frost " + NoTrailZeros(frost.valueBase) + ", slashing " + NoTrailZeros(slash.valueBase) + ")";
	}
	ap = npc.GetCharacterStats().GetAttributeValue('attack_power', emptyTags);
	npc.GetCharacterStats().GetAbilities(abls, false);
	for( i = 0; i < abls.Size(); i += 1 )
		ablStr += " " + abls[i];
	LogChannel('GMTestAI', "C1EV " + npc.GetReadableName() + " level " + npc.GetLevel() + ", health " + NoTrailZeros(npc.GetMaxHealth()) + " (essence " + npc.UsesEssence()
		+ "), armor " + NoTrailZeros(CalculateAttributeValue(npc.GetTotalArmor())) + ", slashing " + NoTrailZeros(GMTestAi15Resist(npc, CDS_SlashingRes) * 100)
		+ "%, fire " + NoTrailZeros(GMTestAi15Resist(npc, CDS_FireRes) * 100) + "%, frost " + NoTrailZeros(GMTestAi15Resist(npc, CDS_FrostRes) * 100)
		+ "%, IceArmor " + npc.HasAbility('IceArmor') + ", EredinInvulnerable " + npc.HasAbility('EredinInvulnerable') + ", DjinnRage " + npc.HasAbility('DjinnRage')
		+ ", DjinnWeak " + npc.HasAbility('DjinnWeak') + ", WeakenedState " + npc.HasAbility('WeakenedState') + ", attack power x"
		+ NoTrailZeros(ap.valueMultiplicative) + ", held:" + s + "; abilities:" + ablStr);
}

exec function gmtest_ai15_ice()
{
	if( thePlayer.gmTestAi14Npc )
		GMTestAi15Ice(thePlayer.gmTestAi14Npc);
}

exec function gmtest_ai15_info()
{
	if( thePlayer.gmTestAi14Npc )
		GMTestAi15Info(thePlayer.gmTestAi14Npc);
}

// A bomb thrown at the test NPC (item name, e.g. 'Dancing Star 1'): the throw through Geralt's combat action, as
// STAM-03's bomb test does; release with gmtest_ai15_bomb_release().
exec function gmtest_ai15_bomb_a(item : name)
{
	var ids : array<SItemUniqueId>;

	ids = thePlayer.inv.AddAnItem(item, 3);
	GetWitcherPlayer().EquipItemInGivenSlot(ids[0], EES_Petard1, false);
	GetWitcherPlayer().SelectQuickslotItem(EES_Petard1);
	thePlayer.GainStat(BCS_Stamina, thePlayer.GetStatMax(BCS_Stamina));
	thePlayer.SetupCombatAction(EBAT_ItemUse, BS_Pressed);
	LogChannel('GMTestAI', "C1EV bomb " + item + " pressed, selected bomb " + thePlayer.inv.IsItemBomb(thePlayer.GetSelectedItemId()));
}

exec function gmtest_ai15_bomb_release()
{
	thePlayer.SetupCombatAction(EBAT_ItemUse, BS_Released);
	LogChannel('GMTestAI', "C1EV bomb released");
}

// ---- probes ----

// Each damage type's resistance on the test NPC as GetDamageResists leaves it (after Ice Armor's term).
@wrapMethod(W3DamageManagerProcessor)
function GetDamageResists(dmgType : name, out resistPts : float, out resistPerc : float)
{
	wrappedMethod(dmgType, resistPts, resistPerc);
	if( GMTestProbes() && actorVictim && actorVictim == thePlayer.gmTestAi14Npc )
		LogChannel('GMTestAI', "C1EV resist " + dmgType + " on " + actorVictim.GetReadableName() + ": " + NoTrailZeros(resistPerc * 100) + "%, armor " + NoTrailZeros(resistPts)
			+ ", IceArmor " + actorVictim.HasAbility('IceArmor') + ", dot " + action.IsDoTDamage() + ", sign " + action.IsActionWitcherSign());
}

// Hits on the test NPC (Ice Armor before and after, the damage) and its hits on Geralt (each damage type, frost slowdown).
@wrapMethod(W3DamageManager)
function ProcessAction( act : W3DamageAction )
{
	var npc : CNewNPC;
	var ice, onNpc, onGeralt : bool;
	var dts : array<SRawDamage>;
	var i : int;
	var s : string;

	npc = thePlayer.gmTestAi14Npc;
	onNpc = GMTestProbes() && npc && act.victim == npc;
	onGeralt = GMTestProbes() && npc && act.victim == thePlayer && act.attacker == npc;
	s = "";
	if( onNpc || onGeralt )
	{
		ice = npc.HasAbility('IceArmor');
		act.GetDTs(dts);
		for( i = 0; i < dts.Size(); i += 1 )
			s += " " + dts[i].dmgType + " " + NoTrailZeros(dts[i].dmgVal);
	}
	wrappedMethod(act);
	if( onNpc )
		LogChannel('GMTestAI', "C1EV hit on " + npc.GetReadableName() + " by Geralt " + (act.attacker == thePlayer) + " (" + act.GetBuffSourceName() + ", sign " + act.IsActionWitcherSign() + ", dot "
			+ act.IsDoTDamage() + "):" + s + " -> dealt " + NoTrailZeros(act.GetDamageDealt()) + "; IceArmor " + ice + " -> " + npc.HasAbility('IceArmor')
			+ ", health " + NoTrailZeros(npc.GetHealthPercents() * 100) + "%");
	if( onGeralt )
		LogChannel('GMTestAI', "C1EV hit on Geralt by " + npc.GetReadableName() + " (" + act.GetBuffSourceName() + ", dot " + act.IsDoTDamage() + "):" + s + " -> dealt "
			+ NoTrailZeros(act.GetDamageDealt()) + "; frost slowdown " + thePlayer.HasBuff(EET_SlowdownFrost) + ", vitality " + NoTrailZeros(thePlayer.GetStat(BCS_Vitality)));
}

// Igni's own removal (5.x's, OnIgniHit) seen on the test NPC.
@wrapMethod(CNewNPC)
function OnIgniHit( sign : W3IgniProjectile )
{
	var ice, ret : bool;

	ice = HasAbility('IceArmor');
	ret = wrappedMethod(sign);
	if( GMTestProbes() && this == thePlayer.gmTestAi14Npc )
		LogChannel('GMTestAI', "C1EV igni hit on " + GetReadableName() + ": IceArmor " + ice + " -> " + HasAbility('IceArmor'));
	return ret;
}

@wrapMethod(CNewNPC)
function GMRemoveIceArmor()
{
	var ice : bool;

	ice = HasAbility('IceArmor');
	wrappedMethod();
	if( GMTestProbes() && ice && this == thePlayer.gmTestAi14Npc )
		LogChannel('GMTestAI', "C1EV fire hit took the Ice Armor off " + GetReadableName());
}

// The burning effect on the test NPC (no hit: its own ticks), Geralt its creator.
exec function gmtest_ai15_burn()
{
	var params : SCustomEffectParams;
	var npc : CNewNPC;

	npc = thePlayer.gmTestAi14Npc;
	if( !npc )
		return;
	params.effectType = EET_Burning;
	params.creator = thePlayer;
	params.sourceName = "gmtest_ai15";
	params.duration = 5;
	LogChannel('GMTestAI', "C1EV burning on " + npc.GetReadableName() + ": " + npc.AddEffectCustom(params) + ", IceArmor " + npc.HasAbility('IceArmor'));
}

// The weakened state on the test NPC (SetWeakenedState, what the animation event and the behaviour task call).
exec function gmtest_ai15_weak(on : bool)
{
	var npc : CNewNPC;
	var r0, r1 : float;

	npc = thePlayer.gmTestAi14Npc;
	if( !npc )
		return;
	r0 = GMTestAi15Resist(npc, CDS_SlashingRes);
	npc.SetWeakenedState(on);
	r1 = GMTestAi15Resist(npc, CDS_SlashingRes);
	LogChannel('GMTestAI', "C1EV weakened state " + on + " on " + npc.GetReadableName() + " (olgierd_gpl " + npc.HasTag('olgierd_gpl') + "): WeakenedState "
		+ npc.HasAbility('WeakenedState') + ", slashing " + NoTrailZeros(r0 * 100) + "% -> " + NoTrailZeros(r1 * 100) + "%");
}

// The djinn's rage or weakness on the test NPC: the ability its rage task (BTTaskManageDjinnRage) adds; logs attack
// and spell power and stamina regen.
exec function gmtest_ai15_rage(kind : int)
{
	var npc : CNewNPC;
	var emptyTags : array<name>;
	var sp, reg : SAbilityAttributeValue;
	var abl : name;

	npc = thePlayer.gmTestAi14Npc;
	if( !npc )
		return;
	npc.RemoveAbility('DjinnRage');
	npc.RemoveAbility('DjinnWeak');
	if( kind == 1 )
		abl = 'DjinnRage';
	else if( kind == 2 )
		abl = 'DjinnWeak';
	if( IsNameValid(abl) )
		npc.AddAbility(abl, false);
	sp = npc.GetCharacterStats().GetAttributeValue('spell_power', emptyTags);
	reg = npc.GetCharacterStats().GetAttributeValue('staminaRegen', emptyTags);
	LogChannel('GMTestAI', "C1EV djinn state " + abl + " on " + npc.GetReadableName() + ": attack power x" + NoTrailZeros(GMTestAi15AttackPower(npc)) + ", spell power x"
		+ NoTrailZeros(sp.valueMultiplicative) + ", stamina regen x" + NoTrailZeros(reg.valueMultiplicative));
}

// A scripted light attack of the test NPC with its held weapon on Geralt (the weapon's damage types and effects).
exec function gmtest_ai15_npchit()
{
	var npc : CNewNPC;
	var action : W3Action_Attack;
	var weapons : array<SItemUniqueId>;

	npc = thePlayer.gmTestAi14Npc;
	if( !npc )
		return;
	weapons = npc.GetInventory().GetHeldWeapons();
	if( weapons.Size() == 0 )
		weapons = npc.GetInventory().GetItemsByCategory('steelsword');
	if( weapons.Size() == 0 )
		return;
	action = new W3Action_Attack in theGame.damageMgr;
	action.Init(npc, thePlayer, NULL, weapons[0], 'attack_light', npc.GetName(), EHRT_Light, false, false, 'attack_light', AST_Jab, ASD_UpDown, true, false, false, false);
	theGame.damageMgr.ProcessAction(action);
	delete action;
	LogChannel('GMTestAI', "C1EV scripted attack of " + npc.GetReadableName() + " with " + npc.GetInventory().GetItemName(weapons[0]) + " on Geralt: frost slowdown "
		+ thePlayer.HasBuff(EET_SlowdownFrost));
}
