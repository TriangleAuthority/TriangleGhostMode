// AI slice C3 tests (AI-19 the Caretaker and quest monsters' immunities, AI-20 fistfights); docs/features/ai.md.
//
// Regression: GMTest_ai19() (gmtest_regress) spawns, frozen and neutral far behind Geralt, the Caretaker, Gregoire,
// mh102's arachas, the ancient fogling, mh210's lamia and two bandits; checks the CausesDamage signal's value (a
// scripted hit of the Caretaker's on Geralt: the share of half his maximum Vitality; on a bandit: 1), the Caretaker's
// shovel items and the spade's text. GMTest_ai19_after() (gmtest_panel, a frame later) reads the five quest monsters'
// buff immunities and removes them. GMTest_ai20() checks Geralt's maximum Vitality at a fistfight's start and the fist
// damage bonus of a scripted fist hit (+150 Hard, +50 Easy), and spawns a bandit with every tier and level-difference
// ability; GMTest_ai20_after() starts its fistfight (OnStartFistfightMinigame, as the quest block does) and reads
// what is left (one tier, no level-difference abilities, the tier's health, the sergeant's fix), then ends it.
//
// Real fights: probes log "C3EV" lines (channel GMTestAI): every hit of the test NPC (thePlayer.gmTestAi19Npc) on
// Geralt with the CausesDamage value and the NPC's health before and after (the Caretaker's heal, against his maximum
// x the value x healing_per_hit_perc), the fist bonus added in ProcessDamageIncrease; every hit of Geralt's on it.
// gmtest_ai19_a(distance) spawns the Caretaker hostile; gmtest_ai19_hurt(perc) sets his health; gmtest_ai20_a("<path>",
// distance) spawns a fistfighter hostile and gmtest_ai20_start() starts the fistfight minigame on both sides;
// gmtest_ai19_swing(n) swings at the test NPC (B1's light attacks); gmtest_ai19_info() reads it; gmtest_ai19_b() ends
// the minigame if any and removes it.

@addField(CR4Player)
var gmTestAi19Npcs : array<CNewNPC>;
@addField(CR4Player)
var gmTestAi20Npcs : array<CNewNPC>;
@addField(CR4Player)
public var gmTestAi19Npc : CNewNPC;
@addField(CR4Player)
var gmTestAi19CD : float;
@addField(CR4Player)
var gmTestAi19CDVictim : CGameplayEntity;
@addField(CR4Player)
var gmTestAi19FistWatch : CActor;
@addField(CR4Player)
var gmTestAi19FistBefore : float;
@addField(CR4Player)
var gmTestAi19FistAfter : float;
@addField(CR4Player)
var gmTestAi19Fistfight : bool;

@addMethod(CR4Player)
function GMTestAi19Set(npcs : array<CNewNPC>)
{
	gmTestAi19Npcs = npcs;
}

@addMethod(CR4Player)
function GMTestAi20Set(npcs : array<CNewNPC>)
{
	gmTestAi20Npcs = npcs;
}

@addMethod(CR4Player)
function GMTestAi19SetNpc(npc : CNewNPC, fistfight : bool)
{
	gmTestAi19Npc = npc;
	gmTestAi19Fistfight = fistfight;
}

@addMethod(CR4Player)
function GMTestAi19RecordCD(v : float, victim : CGameplayEntity)
{
	gmTestAi19CD = v;
	gmTestAi19CDVictim = victim;
}

@addMethod(CR4Player)
function GMTestAi19SetFistWatch(a : CActor)
{
	gmTestAi19FistWatch = a;
	if( a )
	{
		gmTestAi19FistBefore = -1;
		gmTestAi19FistAfter = -1;
	}
}

@addMethod(CR4Player)
function GMTestAi19RecordFist(before : float, after : float)
{
	gmTestAi19FistBefore = before;
	gmTestAi19FistAfter = after;
}

// ---- probes ----

// The CausesDamage value ProcessAction signals (AI-19).
@wrapMethod(W3DamageManagerProcessor)
function GMCausesDamageValue() : float
{
	var v : float;

	v = wrappedMethod();
	thePlayer.GMTestAi19RecordCD(v, action.victim);
	return v;
}

function GMTestAi19Bludgeoning(dmgInfos : array< SRawDamage >) : float
{
	var i : int;
	var s : float;

	s = 0;
	for( i = 0; i < dmgInfos.Size(); i += 1 )
		if( dmgInfos[i].dmgType == theGame.params.DAMAGE_NAME_BLUDGEONING )
			s += dmgInfos[i].dmgVal;
	return s;
}

// The bludgeoning damage before and after ProcessDamageIncrease (AI-20's fist bonus is its first flat addition), for
// the watched attacker's hits.
@wrapMethod(W3DamageManagerProcessor)
function ProcessDamageIncrease(out dmgInfos : array< SRawDamage >)
{
	var before : float;
	var watch : bool;

	watch = thePlayer && thePlayer.gmTestAi19FistWatch && action.attacker == thePlayer.gmTestAi19FistWatch;
	if( watch )
		before = GMTestAi19Bludgeoning(dmgInfos);
	wrappedMethod(dmgInfos);
	if( watch )
		thePlayer.GMTestAi19RecordFist(before, GMTestAi19Bludgeoning(dmgInfos));
}

// Hits between Geralt and the real-fight NPC.
@wrapMethod(W3DamageManager)
function ProcessAction( act : W3DamageAction )
{
	var npc : CNewNPC;
	var onNpc, byNpc : bool;
	var dts : array<SRawDamage>;
	var i : int;
	var s : string;
	var before, after, geraltBefore, perc, shades, want : float;

	npc = thePlayer.gmTestAi19Npc;
	byNpc = GMTestProbes() && npc && act.attacker == npc && act.victim == thePlayer;
	onNpc = GMTestProbes() && npc && act.attacker == thePlayer && act.victim == npc;
	if( byNpc || onNpc )
	{
		act.GetDTs(dts);
		s = "";
		for( i = 0; i < dts.Size(); i += 1 )
			s += " " + dts[i].dmgType + " " + NoTrailZeros(dts[i].dmgVal);
		before = npc.GetHealth();
		geraltBefore = thePlayer.GetHealth();
		thePlayer.GMTestAi19RecordCD(-1, NULL);
		thePlayer.GMTestAi19SetFistWatch((CActor)act.attacker);
	}
	wrappedMethod(act);
	if( byNpc || onNpc )
	{
		after = npc.GetHealth();
		thePlayer.GMTestAi19SetFistWatch(NULL);
	}
	if( byNpc )
	{
		perc = CalculateAttributeValue(npc.GetAttributeValue('healing_per_hit_perc'));
		shades = CalculateAttributeValue(npc.GetAttributeValue('number_of_shades'));
		want = -1;
		if( thePlayer.gmTestAi19CD >= 0 )
			want = MinF(npc.GetMaxHealth() - before, npc.GetMaxHealth() * thePlayer.gmTestAi19CD * perc);
		LogChannel('GMTestAI', "C3EV hit on Geralt by " + npc.GetReadableName() + " (" + act.GetBuffSourceName() + "):" + s + " -> dealt " + NoTrailZeros(act.GetDamageDealt())
			+ " (Geralt " + NoTrailZeros(geraltBefore) + " of " + NoTrailZeros(thePlayer.GetMaxHealth()) + "), CausesDamage " + NoTrailZeros(thePlayer.gmTestAi19CD)
			+ " [5.x: the damage], fist bonus " + NoTrailZeros(thePlayer.gmTestAi19FistAfter - thePlayer.gmTestAi19FistBefore) + "; " + npc.GetReadableName() + " health "
			+ NoTrailZeros(before) + " -> " + NoTrailZeros(after) + " (healed " + NoTrailZeros(after - before) + ", want " + NoTrailZeros(want) + " without shades: max "
			+ NoTrailZeros(npc.GetMaxHealth()) + " x " + NoTrailZeros(thePlayer.gmTestAi19CD) + " x healing_per_hit_perc " + NoTrailZeros(perc) + "; number_of_shades " + NoTrailZeros(shades) + ")");
		if( thePlayer.gmTestAi19Fistfight && thePlayer.gmTestAi19FistAfter >= 0 )
			thePlayer.GMTestDiff02RecordFist(thePlayer.gmTestAi19FistAfter - thePlayer.gmTestAi19FistBefore);	// DIFF-02's punch check (gmTestsDiff02.ws)
	}
	if( onNpc )
		LogChannel('GMTestAI', "C3EV hit on " + npc.GetReadableName() + " by Geralt (" + act.GetBuffSourceName() + "):" + s + " -> dealt " + NoTrailZeros(act.GetDamageDealt())
			+ ", bludgeoning " + NoTrailZeros(thePlayer.gmTestAi19FistBefore) + " -> " + NoTrailZeros(thePlayer.gmTestAi19FistAfter) + " in ProcessDamageIncrease, health "
			+ NoTrailZeros(before) + " -> " + NoTrailZeros(after) + " of " + NoTrailZeros(npc.GetMaxHealth()));
}

// ---- regression ----

function GMTestAi19Damage(attacker : CActor, victim : CActor, amount : float)
{
	var action : W3DamageAction;

	action = new W3DamageAction in theGame.damageMgr;
	action.Initialize(attacker, victim, NULL, "gmtest_ai19", EHRT_None, CPS_AttackPower, false, false, false, false);
	action.AddDamage(theGame.params.DAMAGE_NAME_DIRECT, amount);
	theGame.damageMgr.ProcessAction(action);
	delete action;
}

function GMTestAi19HasAbility(npc : CNewNPC, items : array<SItemUniqueId>, abl : name) : bool
{
	var abls : array<name>;

	if( items.Size() < 1 )
		return false;
	npc.GetInventory().GetItemAbilities(items[0], abls);
	return abls.Contains(abl);
}

// AI-19: spawns the quest monsters GMTest_ai19_after() reads; the CausesDamage value, the shovel items, the spade text.
function GMTest_ai19()
{
	var npcs : array<CNewNPC>;
	var caretaker, gregoire, arachas, fogling, lamia, bandit : CNewNPC;
	var items : array<SItemUniqueId>;
	var prev, maxv, want : float;
	var key, text : string;

	caretaker = GMTestAi15Spawn("dlc/ep1/data/quests/quest_files/q604_mansion/characters/q604_caretaker.w2ent", 44, -10);
	gregoire = GMTestAi15Spawn("dlc/bob/data/quests/sidequests/quest_files/sq701_tournament/characters/sq701_gregoire.w2ent", 52, -10);
	arachas = GMTestAi15Spawn("quests/generic_quests/no_mans_land/quest_files/mh102_arachas/characters/mh102_arachas.w2ent", 60, -10);
	fogling = GMTestAi15Spawn("quests/generic_quests/no_mans_land/quest_files/mh108_fogling/characters/mh108_ancient_fogling.w2ent", 68, -10);
	lamia = GMTestAi15Spawn("quests/generic_quests/skellige/quest_files/mh210_lamia/characters/mh210_lamia.w2ent", 76, -10);
	bandit = GMTestAi15Spawn("living_world/enemy_templates/nilfgaardian_deserter_sword_hard.w2ent", 84, -10);
	npcs.PushBack(caretaker);
	npcs.PushBack(gregoire);
	npcs.PushBack(arachas);
	npcs.PushBack(fogling);
	npcs.PushBack(lamia);
	npcs.PushBack(bandit);
	thePlayer.GMTestAi19Set(npcs);
	GMTestReport(caretaker && gregoire && arachas && fogling && lamia && bandit, "AI-19 the Caretaker, Gregoire, mh102's arachas, the ancient fogling, mh210's lamia and a bandit spawned");
	if( !caretaker || !bandit )
		return;

	// the CausesDamage value: on Geralt the share of half his maximum Vitality, at most 1; on anyone else 1
	prev = thePlayer.GetStat(BCS_Vitality);
	maxv = thePlayer.GetStatMax(BCS_Vitality);
	thePlayer.SetImmortalityMode(AIM_Immortal, AIC_Default, true);
	thePlayer.GMTestAi19RecordCD(-1, NULL);
	GMTestAi19Damage(caretaker, thePlayer, 0.1 * maxv);
	want = 0.1 * maxv / (0.5 * thePlayer.GetMaxHealth());
	GMTestReport(thePlayer.gmTestAi19CDVictim == thePlayer && AbsF(thePlayer.gmTestAi19CD - want) < 0.01, "AI-19 the Caretaker's hit of 10% of Geralt's Vitality signals " + NoTrailZeros(thePlayer.gmTestAi19CD)
		+ " (want " + NoTrailZeros(want) + "; 5.x: the damage, " + NoTrailZeros(0.1 * maxv) + ")");
	thePlayer.ForceSetStat(BCS_Vitality, maxv);
	thePlayer.GMTestAi19RecordCD(-1, NULL);
	GMTestAi19Damage(caretaker, thePlayer, 0.9 * maxv);
	GMTestReport(AbsF(thePlayer.gmTestAi19CD - 1) < 0.001, "AI-19 a hit of 90% of Geralt's Vitality signals at most 1: " + NoTrailZeros(thePlayer.gmTestAi19CD));
	thePlayer.ForceSetStat(BCS_Vitality, prev);
	thePlayer.SetImmortalityMode(AIM_None, AIC_Default, true);
	thePlayer.GMTestAi19RecordCD(-1, NULL);
	GMTestAi19Damage(caretaker, bandit, 10);
	GMTestReport(thePlayer.gmTestAi19CDVictim == bandit && thePlayer.gmTestAi19CD == 1, "AI-19 the Caretaker's hit on another NPC (a shade) signals 1, a full heal share: " + NoTrailZeros(thePlayer.gmTestAi19CD));
	bandit.ForceSetStat(bandit.GetUsedHealthType(), bandit.GetMaxHealth());

	// the shovel items name the Caretaker's own ability
	items = bandit.GetInventory().AddAnItem('Caretaker Shovel', 1);
	GMTestReport(GMTestAi19HasAbility(bandit, items, 'Caretaker Shovel _Stats') && !GMTestAi19HasAbility(bandit, items, 'Shovel _Stats'), "AI-19 the Caretaker's shovel item has Caretaker Shovel _Stats, not Shovel _Stats");
	if( items.Size() > 0 )
		bandit.GetInventory().RemoveItem(items[0], 1);
	items = bandit.GetInventory().AddAnItem('caretaker_body', 1);
	GMTestReport(GMTestAi19HasAbility(bandit, items, 'Caretaker Shovel _Stats') && !GMTestAi19HasAbility(bandit, items, 'Shovel _Stats'), "AI-19 the Caretaker's phantom body weapon has Caretaker Shovel _Stats, not Shovel _Stats");
	if( items.Size() > 0 )
		bandit.GetInventory().RemoveItem(items[0], 1);

	// the spade's description (5.x: no text for its key)
	key = "item_name_caretaker_spade_desc";
	text = GetLocStringByKeyExt(key);
	GMTestReport(text != "" && text == GetLocStringById(2110992475), "AI-19 the Caretaker's spade has legacy's description: " + text);
}

function GMTestAi19Immune(npc : CNewNPC, effect : EEffectType, want : bool, label : string)
{
	var got : bool;

	if( !npc )
	{
		GMTestReport(false, "AI-19 " + label + ": the NPC is gone");
		return;
	}
	got = npc.IsImmuneToBuff(effect);
	GMTestReport(got == want, "AI-19 " + label + ": immune to " + effect + " " + got + " (want " + want + ")");
}

// AI-19: the quest monsters' buff immunities (legacy's lists, in 5.x's effect numbers); removes the NPCs.
function GMTest_ai19_after()
{
	var npcs : array<CNewNPC>;
	var i : int;

	npcs = thePlayer.gmTestAi19Npcs;
	if( npcs.Size() < 6 )
	{
		GMTestReport(false, "AI-19 the NPCs of GMTest_ai19() are there");
		return;
	}
	GMTestAi19Immune(npcs[0], EET_Knockdown, true, "the Caretaker [5.x: not immune]");
	GMTestAi19Immune(npcs[0], EET_HeavyKnockdown, true, "the Caretaker [5.x: not immune]");
	GMTestAi19Immune(npcs[0], EET_BleedingTracking, true, "the Caretaker [5.x: not immune]");
	GMTestAi19Immune(npcs[0], EET_Bleeding, true, "the Caretaker (1.32 and 5.x too)");
	GMTestAi19Immune(npcs[1], EET_Acid, true, "Gregoire [5.x: not immune]");
	GMTestAi19Immune(npcs[1], EET_BleedingTracking, true, "Gregoire [5.x: not immune]");
	GMTestAi19Immune(npcs[1], EET_KnockdownTypeApplicator, true, "Gregoire [5.x: not immune]");
	GMTestAi19Immune(npcs[2], EET_Poison, true, "mh102's arachas [5.x: not immune]");
	GMTestAi19Immune(npcs[2], EET_Burning, false, "mh102's arachas [5.x: immune]");
	GMTestAi19Immune(npcs[3], EET_HeavyKnockdown, true, "the ancient fogling [5.x: not immune]");
	GMTestAi19Immune(npcs[4], EET_Knockdown, false, "mh210's lamia [5.x: immune]");
	GMTestAi19Immune(npcs[4], EET_HeavyKnockdown, true, "mh210's lamia (5.x too)");
	for( i = 0; i < npcs.Size(); i += 1 )
		if( npcs[i] )
			npcs[i].Destroy();
	npcs.Clear();
	thePlayer.GMTestAi19Set(npcs);
}

// A scripted fist hit of `attacker` (holding `fists`) on `victim`; returns the bludgeoning damage ProcessDamageIncrease added.
function GMTestAi20FistHit(attacker : CNewNPC, victim : CNewNPC, fists : SItemUniqueId) : float
{
	var attack : W3Action_Attack;

	thePlayer.GMTestAi19SetFistWatch(attacker);
	attack = new W3Action_Attack in theGame.damageMgr;
	attack.Init(attacker, victim, NULL, fists, 'attack_light', attacker.GetName(), EHRT_Light, false, false, 'attack_light', AST_Horizontal, ASD_LeftRight, true, false, false, false);
	theGame.damageMgr.ProcessAction(attack);
	delete attack;
	thePlayer.GMTestAi19SetFistWatch(NULL);
	victim.ForceSetStat(victim.GetUsedHealthType(), victim.GetMaxHealth());
	if( thePlayer.gmTestAi19FistBefore < 0 )
		return -1;
	return thePlayer.gmTestAi19FistAfter - thePlayer.gmTestAi19FistBefore;
}

// AI-20: Geralt's maximum Vitality at a fistfight's start, the fist damage bonus of scripted hits; spawns the
// fistfighter GMTest_ai20_after() starts a fistfight with.
function GMTest_ai20()
{
	var npcs : array<CNewNPC>;
	var a, b, c : CNewNPC;
	var ids : array<SItemUniqueId>;
	var prev, maxBefore, maxDuring, x : float;

	// Geralt's maximum Vitality is not clamped to 2,000
	prev = thePlayer.GetStat(BCS_Vitality);
	maxBefore = thePlayer.GetStatMax(BCS_Vitality);
	thePlayer.FistFightHealthChange(true);
	maxDuring = thePlayer.GetStatMax(BCS_Vitality);
	thePlayer.FistFightHealthChange(false);
	GMTestReport(maxDuring == maxBefore && thePlayer.GetStatMax(BCS_Vitality) == maxBefore, "AI-20 Geralt's maximum Vitality at a fistfight's start: " + NoTrailZeros(maxBefore) + " -> "
		+ NoTrailZeros(maxDuring) + " [5.x: 2,000]");
	thePlayer.ForceSetStat(BCS_Vitality, prev);

	// the fist damage bonus: +150 on Hard, +50 on Easy, none without a tier
	a = GMTestAi15Spawn("gameplay/templates/characters/npcs/test_enemies/enemy_fists_easy.w2ent", 44, 10);	// a fistfighter: its fists are held once it moves
	b = GMTestAi15Spawn("living_world/enemy_templates/nilfgaardian_deserter_sword_hard.w2ent", 46, 10);
	c = GMTestAi15Spawn("living_world/enemy_templates/nilfgaardian_deserter_sword_hard.w2ent", 52, 10);
	npcs.PushBack(a);
	npcs.PushBack(b);
	npcs.PushBack(c);
	thePlayer.GMTestAi20Set(npcs);
	if( !a || !b || !c )
	{
		GMTestReport(false, "AI-20 three bandits spawned");
		return;
	}
	a.SetAnimationSpeedMultiplier(1);	// not frozen: a frozen NPC never holds its fists (neutral, 44 m behind Geralt)
	a.RemoveAbility('StatsFistsEasy');	// its own tier, added back by GMTest_ai20_after()
	ids = a.GetInventory().GetItemsByCategory('fist');
	if( ids.Size() > 0 )
		a.GetInventory().MountItem(ids[0], true);	// held from a later frame: the hits are in GMTest_ai20_after()

	// the fistfighter: every tier, level-difference abilities, the sergeant's mix of old saves
	c.AddAbility('fistfight_minigame', false);
	c.AddAbility('SkillFistsEasy', false);
	c.AddAbility('SkillFistsMedium', false);
	c.AddAbility('SkillFistsHard', false);
	c.AddAbility('StatsFistsEasy', false);
	c.AddAbility('StatsFistsMedium', false);
	c.AddAbility('StatsFistsHard', false);
	c.AddAbilityMultiple('NPCLevelModFistFightHigher', 3);
	c.AddAbilityMultiple('NPCLevelModFistFightLower', 2);
	c.AddAbility('qSergeantFistFIght', false);
	c.AddAbility('SkillBrigand', false);
	c.AddAbility('SkillOfficer', false);
}

// AI-20: the fistfight's start on the bandit GMTest_ai20() prepared; removes the NPCs.
function GMTest_ai20_after()
{
	var npcs : array<CNewNPC>;
	var a, b, c : CNewNPC;
	var i : int;
	var ids : array<SItemUniqueId>;
	var x : float;
	var stats : CCharacterStats;
	var vit : SAbilityAttributeValue;
	var empty : array<name>;

	npcs = thePlayer.gmTestAi20Npcs;
	if( npcs.Size() < 3 || !npcs[2] )
	{
		GMTestReport(false, "AI-20 the NPCs of GMTest_ai20() are there");
		return;
	}
	// the fist damage bonus: +150 on Hard, +50 on Easy, none without a tier
	a = npcs[0];
	b = npcs[1];
	ids = a.GetInventory().GetItemsByCategory('fist');
	GMTestReport(ids.Size() > 0 && a.IsWeaponHeld('fist'), "AI-20 a fistfighter holds its fists");
	if( ids.Size() > 0 && b )
	{
		x = GMTestAi20FistHit(a, b, ids[0]);
		GMTestReport(x == 0, "AI-20 a fist hit without a fistfight tier: bludgeoning +" + NoTrailZeros(x));
		a.AddAbility('StatsFistsHard', false);
		x = GMTestAi20FistHit(a, b, ids[0]);
		GMTestReport(AbsF(x - 150) < 0.01, "AI-20 a fist hit of a Hard-tier fistfighter: bludgeoning +" + NoTrailZeros(x) + " (want +150; 5.x: +0)");
		a.RemoveAbility('StatsFistsHard');
		a.AddAbility('StatsFistsEasy', false);
		x = GMTestAi20FistHit(a, b, ids[0]);
		GMTestReport(AbsF(x - 50) < 0.01, "AI-20 a fist hit of an Easy-tier fistfighter: bludgeoning +" + NoTrailZeros(x) + " (want +50; 5.x: +0)");
		a.RemoveAbility('StatsFistsEasy');
	}

	c = npcs[2];
	c.OnStartFistfightMinigame();
	GMTestReport(c.HasAbility('SkillFistsEasy') && !c.HasAbility('SkillFistsMedium') && !c.HasAbility('SkillFistsHard'), "AI-20 a fistfighter with three skill tiers keeps the lowest (Easy) [5.x: all three]");
	GMTestReport(c.HasAbility('StatsFistsEasy') && !c.HasAbility('StatsFistsMedium') && !c.HasAbility('StatsFistsHard'), "AI-20 a fistfighter with three stat tiers keeps the lowest (Easy) [5.x: all three]");
	GMTestReport(!c.HasAbility('NPCLevelModFistFightHigher') && !c.HasAbility('NPCLevelModFistFightLower'), "AI-20 no level-difference ability at the fight's start [5.x: kept]");
	GMTestReport(!c.HasAbility('SkillBrigand') && c.HasAbility('SkillOfficer'), "AI-20 the sergeant's fix: SkillBrigand removed where SkillOfficer is there too [5.x: kept]");
	stats = c.GetCharacterStats();
	vit = stats.GetAttributeValue('vitality', empty);
	GMTestReport(c.HasAbility('HealthFistFightEasy'), "AI-20 the Easy tier's health ability at the start: Vitality " + NoTrailZeros(c.GetStatMax(BCS_Vitality)) + " (base " + NoTrailZeros(vit.valueBase)
		+ ", mult " + NoTrailZeros(vit.valueMultiplicative) + ", add " + NoTrailZeros(vit.valueAdditive) + "), health " + NoTrailZeros(c.GetHealthPercents() * 100) + "%");
	c.OnEndFistfightMinigame();
	for( i = 0; i < npcs.Size(); i += 1 )
		if( npcs[i] )
			npcs[i].Destroy();
	npcs.Clear();
	thePlayer.GMTestAi20Set(npcs);
}

exec function gmtest_ai19()
{
	GMTest_ai19();
}

exec function gmtest_ai19_after()
{
	GMTest_ai19_after();
}

exec function gmtest_ai20()
{
	GMTest_ai20();
}

exec function gmtest_ai20_after()
{
	GMTest_ai20_after();
}

// ---- real fights ----

function GMTestAi19SpawnHostile(path : string, distance : float) : CNewNPC
{
	var template : CEntityTemplate;
	var npc : CNewNPC;

	template = (CEntityTemplate)LoadResource(path, true);
	if( !template )
	{
		LogChannel('GMTestAI', "C3EV no template " + path);
		return NULL;
	}
	npc = (CNewNPC)theGame.CreateEntity(template, thePlayer.GetWorldPosition() + thePlayer.GetHeadingVector() * distance, VecToRotation(-thePlayer.GetHeadingVector()));
	if( !npc )
		return NULL;
	npc.SetTemporaryAttitudeGroup('hostile_to_player', AGP_Default);
	thePlayer.GMTestSetProbes(true);
	thePlayer.SetImmortalityMode(AIM_Immortal, AIC_Default, true);
	return npc;
}

function GMTestAi19Info(npc : CNewNPC) : string
{
	var s : string;

	s = npc.GetReadableName() + " level " + npc.GetLevel() + ", health " + NoTrailZeros(npc.GetHealth()) + " / " + NoTrailZeros(npc.GetMaxHealth()) + " (" + NoTrailZeros(npc.GetHealthPercents() * 100)
		+ "%), alive " + npc.IsAlive() + ", healing_per_hit_perc " + NoTrailZeros(CalculateAttributeValue(npc.GetAttributeValue('healing_per_hit_perc'))) + ", fist_dmg_bonus "
		+ NoTrailZeros(CalculateAttributeValue(npc.GetAttributeValue('fist_dmg_bonus'))) + ", tiers";
	if( npc.HasAbility('SkillFistsEasy') ) s += " SkillFistsEasy";
	if( npc.HasAbility('SkillFistsMedium') ) s += " SkillFistsMedium";
	if( npc.HasAbility('SkillFistsHard') ) s += " SkillFistsHard";
	if( npc.HasAbility('StatsFistsTutorial') ) s += " StatsFistsTutorial";
	if( npc.HasAbility('StatsFistsEasy') ) s += " StatsFistsEasy";
	if( npc.HasAbility('StatsFistsMedium') ) s += " StatsFistsMedium";
	if( npc.HasAbility('StatsFistsHard') ) s += " StatsFistsHard";
	if( npc.HasAbility('HealthFistFightEasy') ) s += " HealthFistFightEasy";
	if( npc.HasAbility('HealthFistFightMedium') ) s += " HealthFistFightMedium";
	if( npc.HasAbility('HealthFistFightHard') ) s += " HealthFistFightHard";
	if( npc.HasAbility('fistfight_minigame') ) s += " fistfight_minigame";
	s += ", fists held " + npc.IsWeaponHeld('fist') + "; Geralt " + NoTrailZeros(thePlayer.GetHealth()) + " / " + NoTrailZeros(thePlayer.GetMaxHealth()) + ", fistfight "
		+ thePlayer.IsFistFightMinigameEnabled() + ", fists held " + thePlayer.IsWeaponHeld('fist') + ", level " + thePlayer.GetLevel();
	return s;
}

exec function gmtest_ai19_a(optional distance : float)
{
	var npc : CNewNPC;

	if( distance <= 0 )
		distance = 4;
	npc = GMTestAi19SpawnHostile("dlc/ep1/data/quests/quest_files/q604_mansion/characters/q604_caretaker.w2ent", distance);
	thePlayer.GMTestAi19SetNpc(npc, false);
	if( npc )
		LogChannel('GMTestAI', "C3EV spawned " + GMTestAi19Info(npc));
}

exec function gmtest_ai19_hurt(perc : float)
{
	var npc : CNewNPC;

	npc = thePlayer.gmTestAi19Npc;
	if( npc )
	{
		npc.ForceSetStat(npc.GetUsedHealthType(), npc.GetMaxHealth() * perc);
		LogChannel('GMTestAI', "C3EV set " + GMTestAi19Info(npc));
	}
}

exec function gmtest_ai19_info()
{
	if( thePlayer.gmTestAi19Npc )
		LogChannel('GMTestAI', "C3EV " + GMTestAi19Info(thePlayer.gmTestAi19Npc));
}

exec function gmtest_ai19_swing(n : int)
{
	var w : W3PlayerWitcher;

	w = GetWitcherPlayer();
	if( thePlayer.gmTestAi19Npc )
	{
		w.GMTestAi17SetNpc(thePlayer.gmTestAi19Npc);
		w.GMTestAi17Swing(n);
	}
}

exec function gmtest_ai20_a(path : string, optional distance : float)
{
	var npc : CNewNPC;

	if( distance <= 0 )
		distance = 3;
	npc = GMTestAi19SpawnHostile(path, distance);
	thePlayer.GMTestAi19SetNpc(npc, false);
	if( npc )
		LogChannel('GMTestAI', "C3EV spawned " + GMTestAi19Info(npc));
}

// The fistfight minigame's start on both sides, as the quest block does (the player's and the NPC's events).
exec function gmtest_ai20_start(optional toTheDeath : bool)
{
	var npc : CNewNPC;
	var maxBefore : float;

	npc = thePlayer.gmTestAi19Npc;
	if( !npc )
		return;
	maxBefore = thePlayer.GetStatMax(BCS_Vitality);
	thePlayer.SetFistFightParams(toTheDeath, false);
	thePlayer.OnStartFistfightMinigame();
	npc.OnStartFistfightMinigame();
	thePlayer.GMTestAi19SetNpc(npc, true);
	LogChannel('GMTestAI', "C3EV fistfight started (Geralt's maximum Vitality " + NoTrailZeros(maxBefore) + " -> " + NoTrailZeros(thePlayer.GetStatMax(BCS_Vitality)) + "): " + GMTestAi19Info(npc));
}

exec function gmtest_ai19_b()
{
	var npc : CNewNPC;

	npc = thePlayer.gmTestAi19Npc;
	GetWitcherPlayer().RemoveTimer('GMTestAi08Swing');
	if( npc && thePlayer.gmTestAi19Fistfight )
	{
		npc.OnEndFistfightMinigame();
		thePlayer.OnEndFistfightMinigame();
		LogChannel('GMTestAI', "C3EV fistfight ended: Geralt's maximum Vitality " + NoTrailZeros(thePlayer.GetStatMax(BCS_Vitality)));
	}
	if( npc )
		npc.Destroy();
	thePlayer.GMTestAi19SetNpc(NULL, false);
	GetWitcherPlayer().GMTestAi17SetNpc(NULL);
	thePlayer.SetImmortalityMode(AIM_None, AIC_Default, true);
	thePlayer.GMTestSetProbes(false);
}
