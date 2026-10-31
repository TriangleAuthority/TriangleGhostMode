// AI slice C2 tests (AI-17 instant kills and LastBreath, AI-18 special attacks and monster projectiles); docs/features/ai.md.
//
// Regression: GMTest_ai17() (gmtest_regress) spawns, frozen and neutral far behind Geralt, a contract monster (mq1051's
// wyvern, a W3MonsterHuntNPC without an InstantKillImmune ability of its own), two rotfiends, five bandits (one the
// Hakland mage's stand-in); reads the projectile entities AI-18 edits and Eredin's frost projectile's
// values, the projectile level term (at a set Geralt level 30), the magic fists, Aard's deflection of a stone, an
// environment projectile and a boulder (0.7 without skills; SKL-08, AI-C audit F5). GMTest_ai17_after() (gmtest_panel, a frame later) makes scripted instant kills on the contract
// monster (it survives) and a rotfiend (cut to its LastBreath threshold), signals a rotfiend's death next to a bandit
// (the explosion's raw damage: its weapon's, 300 without), hits a bandit with Eredin's frost projectile (500 frost, the
// slowdown 3 s), and (AI-C audit F3) with projectiles through their real collision: class defaults (Ifryt's 200 fire and
// burning 3 s, a stone's 200 and knockdown, a lightning bolt's paralysis 3 s), the Wild Hunt mage's ice spear (500, its
// slowdown 3 s), a debuff projectile without 5.x's second rending hit, the Hakland mage's debuff projectile twice
// within 3 s (the second deals nothing), a debuff projectile and a boulder set to ignore armor on the contract monster
// (armor ignored on an Essence user, the boulder's damage bludgeoning; owner, 2026-10-29); spawns the sergeant and reads his displayed level (AI-C audit F6); then removes them.
//
// Real fights: probes log "C2EV" lines (channel GMTestAI): every hit on Geralt (attacker, causer, each damage type,
// the damage dealt, effects) and every hit on the test NPC (thePlayer.gmTestAi17Npc; health before and after, instant
// kill). gmtest_ai17_a("<path>", distance, frozen) spawns the test NPC hostile; gmtest_ai17_info() reads it;
// gmtest_ai18_shoot("<projectile path>", distance) shoots that projectile at Geralt from the test NPC (Init with it as
// caster, at Geralt's position); gmtest_ai17_b() removes it.

@addField(CR4Player)
var gmTestAi17Npcs : array<CNewNPC>;
@addField(CR4Player)
public var gmTestAi17Npc : CNewNPC;
@addField(CR4Player)
var gmTestAi17Watch : CActor;
@addField(CR4Player)
var gmTestAi17Raw : string;
@addField(CR4Player)
var gmTestAi17RawPhys : float;
@addField(CR4Player)
var gmTestAi17Dealt : float;
@addField(CR4Player)
var gmTestAi17IgnoreArmor : bool;

@addMethod(W3PlayerWitcher)
function GMTestAi17Set(npcs : array<CNewNPC>)
{
	gmTestAi17Npcs = npcs;
}

@addMethod(W3PlayerWitcher)
function GMTestAi17SetNpc(npc : CNewNPC)
{
	gmTestAi17Npc = npc;
}

@addMethod(W3PlayerWitcher)
function GMTestAi17SetWatch(a : CActor)
{
	gmTestAi17Watch = a;
	gmTestAi17Raw = "";
	gmTestAi17RawPhys = -1;
	gmTestAi17Dealt = -1;
	gmTestAi17IgnoreArmor = false;
}

@addMethod(W3PlayerWitcher)
function GMTestAi17Record(raw : string, phys : float, dealt : float, ignoreArmor : bool)
{
	gmTestAi17IgnoreArmor = ignoreArmor;
	gmTestAi17Raw = raw;
	gmTestAi17RawPhys = phys;
	gmTestAi17Dealt = dealt;
}

// ---- test getters of the projectiles' fields ----

@addMethod(W3AdvancedProjectile)
function GMTestDmg() : float
{
	return projDMG;
}

@addMethod(W3AdvancedProjectile)
function GMTestInfo() : string
{
	return "projDMG " + NoTrailZeros(projDMG) + ", silver " + NoTrailZeros(projSilverDMG) + ", effect " + projEfect + ", ignoreArmor " + ignoreArmor
		+ ", dealDamageEvenIfDodging " + dealDamageEvenIfDodging + ", speed " + NoTrailZeros(projSpeed) + ", angle " + NoTrailZeros(projAngle);
}

@addMethod(W3AdvancedProjectile)
function GMTestEffect() : EEffectType
{
	return projEfect;
}

@addMethod(W3AdvancedProjectile)
function GMTestShoot(target : Vector, optional speed : float)
{
	if( speed <= 0 )
		speed = projSpeed;
	ToggleActiveState(true);
	ShootProjectileAtPosition(projAngle, speed, target, 30);
}

@addMethod(W3AdvancedProjectile)
function GMTestSetIgnoreArmor(b : bool)
{
	ignoreArmor = b;
}

@addMethod(W3AdvancedProjectile)
function GMTestSetBounce(f : float)
{
	bounceOfVelocityPreserve = f;
}

@addMethod(W3AdvancedProjectile)
function GMTestBounce() : float
{
	return bounceOfVelocityPreserve;
}

@addMethod(DebuffProjectile)
function GMTestDebuffInfo() : string
{
	return "damageType " + damageTypeName + ", destroyQuen " + destroyQuen;
}

@addMethod(DebuffProjectile)
function GMTestSetDamageType(n : name)
{
	damageTypeName = n;
}

@addMethod(DebuffProjectile)
function GMTestDestroyQuen() : bool
{
	return destroyQuen;
}

@addMethod(DebuffProjectile)
function GMTestDamageType() : name
{
	return damageTypeName;
}

@addMethod(W3WitchBoilingWaterObstacle)
function GMTestDamageValue() : float
{
	return damageValue;
}

@addMethod(CToadAcidPool)
function GMTestDamageVal() : float
{
	return damageVal;
}

function GMTestAi17Entity(path : string, distance : float) : CEntity
{
	var template : CEntityTemplate;
	var pos, h : Vector;

	template = (CEntityTemplate)LoadResource(path, true);
	if( !template )
		return NULL;
	h = thePlayer.GetHeadingVector();
	pos = thePlayer.GetWorldPosition() - h * distance + Vector(0, 0, 30);
	return theGame.CreateEntity(template, pos, VecToRotation(h));
}

// ---- regression ----

// AI-17, AI-18: spawns the NPCs GMTest_ai17_after() hits; reads the entity edits, the projectile defaults and level term,
// magic fists and the Hakland mage's hack.
function GMTest_ai17()
{
	var npcs : array<CNewNPC>;
	var mh, rot1, rot2, bandit1, bandit2, hakland, bandit3, bandit4 : CNewNPC;
	var ent : CEntity;
	var proj : W3AdvancedProjectile;
	var debuff : DebuffProjectile;
	var water : W3WitchBoilingWaterObstacle;
	var pool : CToadAcidPool;
	var before, after : float;
	var groups : array<name>;
	var ids : array<SItemUniqueId>;
	var attack : W3Action_Attack;
	var w : W3PlayerWitcher;
	var h : bool;

	w = GetWitcherPlayer();
	mh = GMTestAi15Spawn("quests/minor_quests/no_mans_land/quest_files/mq1051_monster_hunt_nilfgaard1/characters/mq1051_wyvern.w2ent", 44, 10);	// no InstantKillImmune of its own (mh102's arachas and most contract monsters have it)
	rot1 = GMTestAi15Spawn("characters/npc_entities/monsters/rotfiend_lvl1.w2ent", 52, 10);
	rot2 = GMTestAi15Spawn("characters/npc_entities/monsters/rotfiend_lvl1.w2ent", 60, 10);
	bandit1 = GMTestAi15Spawn("living_world/enemy_templates/nilfgaardian_deserter_sword_hard.w2ent", 61.5, 10);	// 1.5 m from rot2
	bandit2 = GMTestAi15Spawn("living_world/enemy_templates/nilfgaardian_deserter_sword_hard.w2ent", 68, 10);
	hakland = GMTestAi15Spawn("living_world/enemy_templates/nilfgaardian_deserter_sword_hard.w2ent", 76, 10);
	bandit3 = GMTestAi15Spawn("living_world/enemy_templates/nilfgaardian_deserter_sword_hard.w2ent", 52, -10);
	bandit4 = GMTestAi15Spawn("living_world/enemy_templates/nilfgaardian_deserter_sword_hard.w2ent", 60, -10);
	npcs.PushBack(mh);
	npcs.PushBack(rot1);
	npcs.PushBack(rot2);
	npcs.PushBack(bandit1);
	npcs.PushBack(bandit2);
	npcs.PushBack(hakland);
	npcs.PushBack(bandit3);
	npcs.PushBack(bandit4);
	w.GMTestAi17Set(npcs);
	GMTestReport(mh && rot1 && rot2 && bandit1 && bandit2 && hakland && bandit3 && bandit4, "AI-17 a contract monster, two rotfiends and five bandits spawned");
	h = false;
	if( (W3MonsterHuntNPC)mh )
		h = true;
	GMTestReport(h && !mh.HasAbility('InstantKillImmune'), "AI-17 mq1051's wyvern is a W3MonsterHuntNPC (a contract monster) without InstantKillImmune");

	// AI-18: the projectile entities' values (gen_ai_ent.py's edits; legacy's, 5.x's in brackets)
	proj = (W3AdvancedProjectile)GMTestAi17Entity("gameplay/abilities/sorceresses/sorceress_stone_proj.w2ent", 40);
	GMTestReport(proj && proj.GMTestDmg() == 200 && StrFindFirst(proj.GMTestInfo(), "ignoreArmor false") >= 0, "AI-18 the sorceresses' stone: 200 damage, armor applies [5.x 100, ignores armor]: " + proj.GMTestInfo());
	proj.Destroy();
	debuff = (DebuffProjectile)GMTestAi17Entity("dlc/ep1/data/gameplay/abilities/toad/toad_spit_proj.w2ent", 40);
	GMTestReport(debuff && debuff.GMTestDmg() == 200 && debuff.GMTestDamageType() == 'PoisonDamage', "AI-18 the toad's spit: 200 poison [5.x 500 piercing]: " + debuff.GMTestInfo() + ", " + debuff.GMTestDebuffInfo());
	debuff.Destroy();
	debuff = (DebuffProjectile)GMTestAi17Entity("dlc/bob/data/gameplay/abilities/dettlaff_monster/dettlaff_swarm_projectile.w2ent", 40);
	GMTestReport(debuff && debuff.GMTestDmg() == 600 && !debuff.GMTestDestroyQuen(), "AI-18 Dettlaff's swarm: 600, Quen not destroyed, dodgeable [5.x 30, destroys Quen]: " + debuff.GMTestInfo() + ", " + debuff.GMTestDebuffInfo());
	debuff.Destroy();
	water = (W3WitchBoilingWaterObstacle)GMTestAi17Entity("dlc/ep1/data/gameplay/abilities/mage/quick_sand.w2ent", 40);
	GMTestReport(water && water.GMTestDamageValue() == 300, "AI-18 the Hakland mage's quicksand: 300 [5.x 1,000]: " + water.GMTestDamageValue());
	water.Destroy();
	pool = (CToadAcidPool)GMTestAi17Entity("dlc/ep1/data/gameplay/abilities/toad/toad_acid_pool.w2ent", 40);
	GMTestReport(pool && pool.GMTestDamageVal() == 100, "AI-18 the toad's acid pool: at least 100 fire [5.x 5 per level]: " + pool.GMTestDamageVal());
	pool.Destroy();
	proj = (W3AdvancedProjectile)GMTestAi17Entity("gameplay/abilities/wh_mage/wh_icespear.w2ent", 40);
	GMTestReport(proj && proj.GMTestDmg() == 500, "AI-18 the Wild Hunt mage's ice spear: 500 (1.32's, legacy kept it) [5.x 285]: " + proj.GMTestInfo());
	proj.Destroy();

	// AI-18: Eredin's frost projectile's defaults, and no level term at a collision (Geralt at a set level 30)
	proj = (W3AdvancedProjectile)GMTestAi17Entity("gameplay/abilities/eredin/eredin_frost_proj.w2ent", 40);
	GMTestReport(proj && proj.GMTestDmg() == 500 && proj.GMTestEffect() == EET_SlowdownFrost, "AI-15/18 Eredin's frost projectile (its entity's values, as in 1.32 and legacy): 500, frost slowdown: " + proj.GMTestInfo());
	if( proj )
	{
		proj.Init(thePlayer);
		proj.ToggleActiveState(true);
		before = proj.GMTestDmg();
		w.GMTestSetLevelOverride(30);
		proj.OnProjectileCollision(proj.GetWorldPosition(), Vector(0, 0, 1), NULL, groups, 0, 0);
		w.GMTestSetLevelOverride(0);
		after = proj.GMTestDmg();
		GMTestReport(before > 0 && after == before, "AI-18 PA11 no level term at a collision, Geralt at level 30: " + NoTrailZeros(before) + " -> " + NoTrailZeros(after) + " [5.x x1.75]");
		proj.Destroy();
	}

	// AI-18: magic fists are ranged attacks
	ids = bandit2.GetInventory().AddAnItem('fists_lightning', 1);
	attack = new W3Action_Attack in theGame.damageMgr;
	attack.Init(bandit2, thePlayer, NULL, ids[0], 'attack_light', bandit2.GetName(), EHRT_Light, true, true, 'attack_light', AST_Horizontal, ASD_LeftRight, true, false, false, false);
	GMTestReport(attack.IsActionRanged() && !attack.IsActionMelee(), "AI-18 lightning fists deal ranged damage: ranged " + attack.IsActionRanged() + ", melee " + attack.IsActionMelee());
	delete attack;
	bandit2.GetInventory().RemoveItem(ids[0], 1);

	// AI-18: the Hakland mage's debuff projectile counts once in 3 s: his ability here, his projectile's two hits through
	// DebuffProjectile.OnProjectileCollision in GMTest_ai17_after
	hakland.AddAbility('HaklandMage', false);
	GMTestReport(hakland.HasAbility('HaklandMage'), "AI-18 the Hakland mage's ability on a stand-in caster");

	// SKL-08 (AI-C audit F5, owner, 2026-10-29): Aard deflects stones and environment projectiles at 0.7 of their speed
	// whatever the skills, as boulders (D25); 5.x: 0.1 without Aard Sweep or Aard Intensity. Their real OnAardHit,
	// called without a sign entity (a regular cast), Geralt without the two skills
	GMTestAi17Deflect("gameplay/abilities/elemental/elemental_stone_proj.w2ent", "a stone");
	GMTestAi17Deflect("gameplay/abilities/sorceresses/environment_projectile_1.w2ent", "an environment projectile");
	GMTestAi17Deflect("gameplay/abilities/sorceresses/sorceress_stone_proj.w2ent", "a boulder (D25)");
}

// A projectile entity's speed kept by Aard (its OnAardHit), Geralt without Aard Sweep and Aard Intensity.
function GMTestAi17Deflect(path : string, what : string)
{
	var proj : W3AdvancedProjectile;
	var skills : bool;
	var rigid : bool;
	var b : float;

	skills = thePlayer.CanUseSkill(S_Magic_s01) || thePlayer.CanUseSkill(S_Magic_s12);
	proj = (W3AdvancedProjectile)GMTestAi17Entity(path, 40);
	if( !proj )
	{
		GMTestReport(false, "SKL-08 Aard on " + what + ": no entity " + path);
		return;
	}
	rigid = false;
	if( proj.GetComponentByClassName('CRigidMeshComponent') )
		rigid = true;
	proj.Init(thePlayer);
	proj.GMTestSetBounce(0);
	proj.OnAardHit(NULL);
	b = proj.GMTestBounce();
	GMTestReport(!skills && !rigid && AbsF(b - 0.7) < 0.001, "SKL-08 Aard deflects " + what + " at " + NoTrailZeros(b) + " of its speed, Aard Sweep or Aard Intensity " + skills
		+ ", rigid mesh " + rigid + " [5.x: 0.1 without the skills]");
	proj.Destroy();
}

// A projectile entity's collision with `victim` through its real OnProjectileCollision (Init with `caster`, as its task
// does), the victim watched by the damage probe (w.gmTestAi17Raw: the action's raw damage; empty when none was dealt).
// ignoreArmor: 1 sets the projectile's ignoreArmor, 2 clears it, 0 leaves its entity's; damageType: a debuff
// projectile's damage type in place of its entity's.
function GMTestAi17Collide(path : string, caster : CEntity, victim : CNewNPC, optional ignoreArmor : int, optional damageType : name) : bool
{
	var proj : W3AdvancedProjectile;
	var comp : CComponent;
	var groups : array<name>;

	proj = (W3AdvancedProjectile)GMTestAi17Entity(path, 66);
	comp = victim.GetComponentByClassName('CMovingPhysicalAgentComponent');
	if( !proj || !comp )
	{
		if( proj )
			proj.Destroy();
		return false;
	}
	GetWitcherPlayer().GMTestAi17SetWatch(victim);
	if( ignoreArmor > 0 )
		proj.GMTestSetIgnoreArmor(ignoreArmor == 1);
	if( IsNameValid(damageType) && (DebuffProjectile)proj )
		((DebuffProjectile)proj).GMTestSetDamageType(damageType);
	proj.Init(caster);
	proj.ToggleActiveState(true);
	proj.OnProjectileCollision(victim.GetWorldPosition(), Vector(0, 0, 1), comp, groups, 0, 0);
	proj.Destroy();
	return true;
}

// The time left of `victim`'s effect of type `t`, -1 without one.
function GMTestAi17Left(victim : CActor, t : EEffectType) : float
{
	var buff : CBaseGameplayEffect;

	buff = victim.GetBuff(t);
	if( buff )
		return buff.GetDurationLeft();
	return -1;
}

// A scripted hit of Geralt's on `npc`: 10 direct damage, an instant kill if `instant`; returns its health share after.
function GMTestAi17Instant(npc : CNewNPC) : float
{
	var action : W3DamageAction;

	npc.ForceSetStat(npc.GetUsedHealthType(), npc.GetMaxHealth());
	action = new W3DamageAction in theGame.damageMgr;
	action.Initialize(thePlayer, npc, NULL, "gmtest_ai17", EHRT_None, CPS_AttackPower, false, false, false, false);
	action.AddDamage(theGame.params.DAMAGE_NAME_DIRECT, 10);
	action.SetInstantKill();
	theGame.damageMgr.ProcessAction(action);
	delete action;
	return npc.GetHealthPercents();
}

// AI-17, AI-18 on the NPCs GMTest_ai17() spawned; removes them.
function GMTest_ai17_after()
{
	var npcs : array<CNewNPC>;
	var mh, rot1, rot2, bandit1, bandit2, hakland, bandit3, bandit4, sergeant : CNewNPC;
	var w : W3PlayerWitcher;
	var ok : bool;
	var raw, strLevel, lvlName : string;
	var p, thr, want, x : float;
	var inv : CInventoryComponent;
	var weapon : SItemUniqueId;
	var dts : array<name>;
	var proj : W3AdvancedProjectile;
	var groups : array<name>;
	var comp : CComponent;
	var buff : CBaseGameplayEffect;
	var i : int;
	var armor : float;

	w = GetWitcherPlayer();
	npcs = w.gmTestAi17Npcs;
	if( npcs.Size() < 8 )
	{
		GMTestReport(false, "AI-17 the NPCs of GMTest_ai17() are there");
		return;
	}
	mh = npcs[0];
	rot1 = npcs[1];
	rot2 = npcs[2];
	bandit1 = npcs[3];
	bandit2 = npcs[4];
	hakland = npcs[5];
	bandit3 = npcs[6];
	bandit4 = npcs[7];

	// AI-17: a contract monster survives an instant kill; a rotfiend is cut down to its LastBreath threshold
	p = GMTestAi17Instant(mh);
	GMTestReport(mh.IsAlive() && p > 0.9, "AI-17 an instant kill on a contract monster: alive " + mh.IsAlive() + ", health " + NoTrailZeros(p * 100) + "% [5.x: killed]");
	thr = CalculateAttributeValue(rot1.GetAttributeValue('lastbreath_threshold'));
	p = GMTestAi17Instant(rot1);
	GMTestReport(rot1.IsAlive() && thr > 0 && AbsF(p - thr) < 0.02, "AI-17 an instant kill on a rotfiend leaves it at its LastBreath threshold " + NoTrailZeros(thr * 100) + "%: alive " + rot1.IsAlive()
		+ ", health " + NoTrailZeros(p * 100) + "% [5.x: killed]");

	// AI-17: the explosion's raw damage: the rotfiend's weapon damage, 300 without one (5.x on Hard: 150 + 4x)
	inv = rot2.GetInventory();
	weapon = inv.GetItemFromSlot('r_weapon');
	inv.GetWeaponDTNames(weapon, dts);
	want = 0;
	if( dts.Size() > 0 )
		want = rot2.GetTotalWeaponDamage(weapon, dts[0], GetInvalidUniqueId());
	x = want;
	if( want < 1 )
		want = 300;
	w.GMTestAi17SetWatch(bandit1);
	rot2.SignalGameplayEvent('Death');
	GMTestReport(w.gmTestAi17RawPhys > 0 && AbsF(w.gmTestAi17RawPhys - want) < 0.5, "AI-17 a rotfiend's explosion on a bandit 1.5 m away: raw " + w.gmTestAi17Raw + " (want " + NoTrailZeros(want)
		+ " physical and silver; 5.x on Hard " + NoTrailZeros(150 + 4 * x) + ")");

	// AI-18: Eredin's frost projectile on a bandit: its entity's 500 frost, frost slowdown 3 s (5.x: 2 s)
	proj = (W3AdvancedProjectile)GMTestAi17Entity("gameplay/abilities/eredin/eredin_frost_proj.w2ent", 66);
	comp = bandit2.GetComponentByClassName('CMovingPhysicalAgentComponent');
	if( proj && comp )
	{
		bandit2.RemoveAllBuffsOfType(EET_SlowdownFrost);
		w.GMTestAi17SetWatch(bandit2);
		proj.Init(thePlayer);
		proj.ToggleActiveState(true);
		proj.OnProjectileCollision(bandit2.GetWorldPosition(), Vector(0, 0, 1), comp, groups, 0, 0);
		buff = bandit2.GetBuff(EET_SlowdownFrost);
		x = -1;
		if( buff )
			x = buff.GetDurationLeft();
		GMTestReport(StrFindFirst(w.gmTestAi17Raw, "FrostDamage 500") >= 0 && x > 2.5 && x <= 3.01, "AI-15/18 Eredin's frost projectile on a bandit: raw " + w.gmTestAi17Raw + ", frost slowdown "
			+ NoTrailZeros(x) + " s left [5.x: none]");
		proj.Destroy();
	}
	else
		GMTestReport(false, "AI-18 Eredin's frost projectile and a bandit's collision component");

	// AI-18 (AI-C audit F3): class defaults through the real collision, projectiles whose entities set no damage or effect
	// (Geralt their caster: a neutral NPC's effects do not reach another neutral NPC)
	bandit3.RemoveAllBuffsOfType(EET_Burning);
	ok = GMTestAi17Collide("gameplay/abilities/elemental/elemental_ifryt_proj.w2ent", thePlayer, bandit3);
	x = GMTestAi17Left(bandit3, EET_Burning);
	GMTestReport(ok && StrFindFirst(w.gmTestAi17Raw, "FireDamage 200") >= 0 && x > 2.5 && x <= 3.01, "AI-18 Ifryt's projectile (the class default) on a bandit: raw" + w.gmTestAi17Raw
		+ ", burning " + NoTrailZeros(x) + " s left [5.x: 200, burning 2 s; without the default 20]");
	bandit3.RemoveAllBuffsOfType(EET_Burning);
	bandit3.RemoveAllBuffsOfType(EET_Knockdown);
	ok = GMTestAi17Collide("gameplay/abilities/elemental/elemental_stone_proj.w2ent", thePlayer, bandit3);
	GMTestReport(ok && StrFindFirst(w.gmTestAi17Raw, "BludgeoningDamage 200") >= 0 && bandit3.HasBuff(EET_Knockdown), "AI-18 a stone (the class default) on a bandit: raw" + w.gmTestAi17Raw
		+ ", knockdown " + bandit3.HasBuff(EET_Knockdown) + " [the projectile's damage and effect; without the default 20, no effect]");
	ok = GMTestAi17Collide("gameplay/abilities/sorceresses/sorceress_lightining_bolt.w2ent", thePlayer, bandit4);
	x = GMTestAi17Left(bandit4, EET_Paralyzed);
	GMTestReport(ok && StrFindFirst(w.gmTestAi17Raw, "ShockDamage 40") >= 0 && x > 2.5 && x <= 3.01, "AI-18 a sorceress's lightning bolt (the class default) on a bandit: raw" + w.gmTestAi17Raw
		+ ", paralysis " + NoTrailZeros(x) + " s left [5.x: 2 s]");
	bandit4.RemoveAllBuffsOfType(EET_Paralyzed);
	bandit3.RemoveAllBuffsOfType(EET_Knockdown);
	bandit3.RemoveAllBuffsOfType(EET_SlowdownFrost);
	ok = GMTestAi17Collide("gameplay/abilities/wh_mage/wh_icespear.w2ent", thePlayer, bandit3);
	x = GMTestAi17Left(bandit3, EET_SlowdownFrost);
	GMTestReport(ok && StrFindFirst(w.gmTestAi17Raw, "FrostDamage 500") >= 0 && x > 2.5 && x <= 3.01, "AI-18 the Wild Hunt mage's ice spear on a bandit: raw" + w.gmTestAi17Raw
		+ ", frost slowdown " + NoTrailZeros(x) + " s left [5.x: 285, 2 s]");

	// AI-18 (AI-C audit F3): a debuff projectile deals its one damage type (5.x adds a second hit of rending damage of its
	// value when its type does not hit Essence)
	ok = GMTestAi17Collide("dlc/ep1/data/gameplay/abilities/mage/sand_coil_proj.w2ent", bandit1, bandit4);
	GMTestReport(ok && StrFindFirst(w.gmTestAi17Raw, "PhysicalDamage 150") >= 0 && StrFindFirst(w.gmTestAi17Raw, "Rending") < 0, "AI-18 a debuff projectile (the sand coil, 150 physical) on a bandit: raw"
		+ w.gmTestAi17Raw + " [5.x: + RendingDamage 150]");

	// AI-18 (AI-C audit F3): the Hakland mage's debuff projectile through its real collision: the first hit counts, a second
	// within 3 s deals nothing (his projectile hit three times)
	ok = GMTestAi17Collide("dlc/ep1/data/gameplay/abilities/mage/sand_coil_proj.w2ent", hakland, bandit4);
	raw = w.gmTestAi17Raw;
	ok = ok && GMTestAi17Collide("dlc/ep1/data/gameplay/abilities/mage/sand_coil_proj.w2ent", hakland, bandit4);
	GMTestReport(ok && StrFindFirst(raw, "PhysicalDamage 150") >= 0 && w.gmTestAi17Raw == "", "AI-18 the Hakland mage's debuff projectile twice within 3 s: first raw" + raw
		+ ", second raw '" + w.gmTestAi17Raw + "' [5.x: both hit]");

	// AI-18 (AI-C audit F1, owner, 2026-10-29): a debuff projectile set to ignore armor ignores it on every victim, also on
	// an armored Essence user (5.x: only on Vitality users); the contract wyvern, Geralt the caster
	armor = CalculateAttributeValue(mh.GetTotalArmor());
	ok = GMTestAi17Collide("dlc/ep1/data/gameplay/abilities/mage/sand_coil_proj.w2ent", thePlayer, mh, 1);
	GMTestReport(ok && mh.UsesEssence() && armor > 0 && w.gmTestAi17Raw != "" && w.gmTestAi17IgnoreArmor, "AI-18 a debuff projectile set to ignore armor on a monster (Essence "
		+ mh.UsesEssence() + ", armor " + NoTrailZeros(armor) + "): raw" + w.gmTestAi17Raw + ", armor ignored " + w.gmTestAi17IgnoreArmor + ", dealt " + NoTrailZeros(w.gmTestAi17Dealt) + " [5.x: armor counts]");

	// the same with damage that hits Essence (the toad's spit, 200, as silver: the wyvern resists its poison fully): more
	// dealt with the flag
	ok = GMTestAi17Collide("dlc/ep1/data/gameplay/abilities/toad/toad_spit_proj.w2ent", thePlayer, mh, 2, theGame.params.DAMAGE_NAME_SILVER);
	raw = w.gmTestAi17Raw;
	x = w.gmTestAi17Dealt;
	ok = ok && GMTestAi17Collide("dlc/ep1/data/gameplay/abilities/toad/toad_spit_proj.w2ent", thePlayer, mh, 1, theGame.params.DAMAGE_NAME_SILVER);
	GMTestReport(ok && x > 0 && w.gmTestAi17IgnoreArmor && w.gmTestAi17Dealt > x + 1, "AI-18 a debuff projectile of silver damage on a monster (armor " + NoTrailZeros(armor) + "): without ignoreArmor raw" + raw + ", dealt "
		+ NoTrailZeros(x) + "; with it dealt " + NoTrailZeros(w.gmTestAi17Dealt) + ", armor ignored " + w.gmTestAi17IgnoreArmor + " [5.x: the same both times]");

	// AI-18 (owner, 2026-10-29): a boulder deals bludgeoning damage (5.x: rending), and its ignoreArmor applies to every
	// victim (5.x: only on Vitality users); the sorceresses' stone, set to ignore armor, on the contract wyvern
	ok = GMTestAi17Collide("gameplay/abilities/sorceresses/sorceress_stone_proj.w2ent", thePlayer, mh, 1);
	GMTestReport(ok && StrFindFirst(w.gmTestAi17Raw, "BludgeoningDamage 200") >= 0 && StrFindFirst(w.gmTestAi17Raw, "Rending") < 0 && w.gmTestAi17IgnoreArmor,
		"AI-18 a boulder set to ignore armor on a monster (Essence " + mh.UsesEssence() + "): raw" + w.gmTestAi17Raw + ", armor ignored " + w.gmTestAi17IgnoreArmor
		+ ", dealt " + NoTrailZeros(w.gmTestAi17Dealt) + " [5.x: RendingDamage 200, armor counts]");
	w.GMTestAi17SetWatch(NULL);

	// AI-06, AI-20 (AI-C audit F6): the sergeant's fake level is a real one (legacy: level 0 -> 11, levelFakeAddon 11 -> 0),
	// so the HUD's level (GetExperienceDifferenceLevelName) reads 11, not 22 (the addon added to it before F6;
	// since DIFF-05 the HUD adds no addon at all). Spawned
	// here, its level computed at once (RecalcLevel, as combat start does): spawning it in GMTest_ai17 costs the
	// regression's timers game time
	sergeant = GMTestAi15Spawn("quests/secondary_npcs/sergeant.w2ent", 68, -10);
	strLevel = "";
	lvlName = "";
	if( sergeant )
	{
		sergeant.RecalcLevel();
		sergeant.SetAttitude(thePlayer, AIA_Hostile);
		lvlName = sergeant.GetExperienceDifferenceLevelName(strLevel);
		sergeant.SetAttitude(thePlayer, AIA_Neutral);
		GMTestReport(StrFindFirst(strLevel, ">11<") >= 0, "AI-06/AI-20 the sergeant's displayed level 11 [the port before the fix: 22]: " + lvlName + " " + strLevel + ", level " + sergeant.GetLevel());
		sergeant.Destroy();
	}
	else
		GMTestReport(false, "AI-06/AI-20 the sergeant spawned");

	for( i = 0; i < npcs.Size(); i += 1 )
		if( npcs[i] )
			npcs[i].Destroy();
	npcs.Clear();
	w.GMTestAi17Set(npcs);
}

exec function gmtest_ai17()
{
	GMTest_ai17();
}

exec function gmtest_ai17_after()
{
	GMTest_ai17_after();
}

// ---- real fights ----

function GMTestAi17IsContract(npc : CNewNPC) : bool
{
	if( (W3MonsterHuntNPC)npc )
		return true;
	return false;
}

exec function gmtest_ai17_a(path : string, optional distance : float, optional frozen : bool)
{
	var template : CEntityTemplate;
	var npc : CNewNPC;

	if( distance <= 0 )
		distance = 5;
	template = (CEntityTemplate)LoadResource(path, true);
	if( !template )
	{
		LogChannel('GMTest', "INFO AI-17: no template " + path);
		return;
	}
	npc = (CNewNPC)theGame.CreateEntity(template, thePlayer.GetWorldPosition() + thePlayer.GetHeadingVector() * distance, VecToRotation(-thePlayer.GetHeadingVector()));
	if( !npc )
		return;
	npc.SetTemporaryAttitudeGroup('hostile_to_player', AGP_Default);
	if( frozen )
		npc.SetAnimationSpeedMultiplier(0.001);
	GetWitcherPlayer().GMTestAi17SetNpc(npc);
	thePlayer.GMTestSetProbes(true);
	thePlayer.SetImmortalityMode(AIM_Immortal, AIC_Default, true);
	LogChannel('GMTestAI', "C2EV spawned " + npc.GetReadableName() + " (contract monster " + GMTestAi17IsContract(npc) + ", LastBreath " + npc.HasAbility('LastBreath') + ") level " + npc.GetLevel()
		+ ", health " + NoTrailZeros(npc.GetMaxHealth()));
}

exec function gmtest_ai17_info()
{
	var npc : CNewNPC;

	npc = thePlayer.gmTestAi17Npc;
	if( npc )
		LogChannel('GMTestAI', "C2EV " + npc.GetReadableName() + " alive " + npc.IsAlive() + ", health " + NoTrailZeros(npc.GetHealth()) + " / " + NoTrailZeros(npc.GetMaxHealth())
			+ " (" + NoTrailZeros(npc.GetHealthPercents() * 100) + "%), Geralt level " + thePlayer.GetLevel() + ", vitality " + NoTrailZeros(thePlayer.GetStat(BCS_Vitality)));
}

exec function gmtest_ai17_b()
{
	if( thePlayer.gmTestAi17Npc )
		thePlayer.gmTestAi17Npc.Destroy();
	GetWitcherPlayer().GMTestAi17SetNpc(NULL);
	thePlayer.SetImmortalityMode(AIM_None, AIC_Default, true);
	thePlayer.GMTestSetProbes(false);
}

// Shoots a projectile entity at Geralt from 1.5 m above the point `distance` m ahead, with the test NPC (or Geralt's
// nearest hostile) as its caster.
exec function gmtest_ai18_shoot(path : string, optional distance : float, optional speed : float)
{
	var template : CEntityTemplate;
	var proj : W3AdvancedProjectile;
	var caster : CEntity;
	var pos, target : Vector;

	if( distance <= 0 )
		distance = 6;
	caster = thePlayer.gmTestAi17Npc;
	template = (CEntityTemplate)LoadResource(path, true);
	if( !template || !caster )
	{
		LogChannel('GMTestAI', "C2EV shoot: no template or no caster");
		return;
	}
	pos = thePlayer.GetWorldPosition() + thePlayer.GetHeadingVector() * distance + Vector(0, 0, 1.5);
	target = thePlayer.GetWorldPosition() + Vector(0, 0, 1.0);
	proj = (W3AdvancedProjectile)theGame.CreateEntity(template, pos, VecToRotation(target - pos));
	if( !proj )
	{
		LogChannel('GMTestAI', "C2EV shoot: not an advanced projectile " + path);
		return;
	}
	proj.Init(caster);
	proj.GMTestShoot(target, speed);
	LogChannel('GMTestAI', "C2EV shot " + path + " by " + ((CActor)caster).GetReadableName() + ": " + proj.GMTestInfo() + ", Geralt level " + thePlayer.GetLevel());
}

// ---- probes ----

// Aard's hits on stones, environment projectiles and boulders (the speed they keep; SKL-08).
function GMTestAi17AardLog(proj : W3AdvancedProjectile, what : string, sign : W3AardProjectile)
{
	var alt : bool;

	if( sign && sign.GetSignEntity() )
		alt = sign.GetSignEntity().IsAlternateCast();
	LogChannel('GMTestAI', "C2EV Aard hit " + what + ": speed kept " + NoTrailZeros(proj.GMTestBounce()) + ", alternate " + alt + ", Aard Sweep " + thePlayer.CanUseSkill(S_Magic_s01)
		+ ", Aard Intensity " + thePlayer.CanUseSkill(S_Magic_s12) + "/" + thePlayer.CanUseSkill(S_Magic_s39));
}

@wrapMethod(W3StoneProjectile)
function OnAardHit( sign : W3AardProjectile )
{
	var res : bool;

	res = wrappedMethod(sign);
	if( GMTestProbes() )
		GMTestAi17AardLog(this, "W3StoneProjectile", sign);
	return res;
}

@wrapMethod(W3EnvironmentProjectile)
function OnAardHit( sign : W3AardProjectile )
{
	var res : bool;

	res = wrappedMethod(sign);
	if( GMTestProbes() )
		GMTestAi17AardLog(this, "W3EnvironmentProjectile", sign);
	return res;
}

@wrapMethod(W3BoulderProjectile)
function OnAardHit( sign : W3AardProjectile )
{
	var res : bool;

	res = wrappedMethod(sign);
	if( GMTestProbes() )
		GMTestAi17AardLog(this, "W3BoulderProjectile", sign);
	return res;
}

function GMTestAi17Causer(c : IScriptable) : string
{
	if( (W3EredinFrostProjectile)c ) return "W3EredinFrostProjectile";
	if( (W3ElementalIfrytProjectile)c ) return "W3ElementalIfrytProjectile";
	if( (W3ElementalDaoProjectile)c ) return "W3ElementalDaoProjectile";
	if( (W3TraceGroundProjectile)c ) return "W3TraceGroundProjectile";
	if( (W3BoulderProjectile)c ) return "W3BoulderProjectile";
	if( (W3StoneProjectile)c ) return "W3StoneProjectile";
	if( (W3EnvironmentProjectile)c ) return "W3EnvironmentProjectile";
	if( (W3ArrowProjectile)c ) return "W3ArrowProjectile";
	if( (DebuffProjectile)c ) return "DebuffProjectile";
	if( (PoisonProjectile)c ) return "PoisonProjectile";
	if( (W3IceMeteorProjectile)c ) return "W3IceMeteorProjectile";
	if( (W3LightningStrikeProjectile)c ) return "W3LightningStrikeProjectile";
	if( (W3FireballProjectile)c ) return "W3FireballProjectile";
	if( (W3LightningBoltProjectile)c ) return "W3LightningBoltProjectile";
	if( (W3IceSpearProjectile)c ) return "W3IceSpearProjectile";
	if( (W3AdvancedProjectile)c ) return "W3AdvancedProjectile";
	if( (W3RedPlagueProjectile)c ) return "W3RedPlagueProjectile";
	if( (W3LeshyRootProjectile)c ) return "W3LeshyRootProjectile";
	if( (W3IceSpike)c ) return "W3IceSpike";
	if( (W3WitchBoilingWaterObstacle)c ) return "W3WitchBoilingWaterObstacle";
	if( (CActor)c ) return "actor";
	if( c ) return "other";
	return "none";
}

// Hits on Geralt (any attacker), on the test NPC and on the regression's watched NPC.
@wrapMethod(W3DamageManager)
function ProcessAction( act : W3DamageAction )
{
	var w : W3PlayerWitcher;
	var watch, onGeralt, onNpc : bool;
	var dts : array<SRawDamage>;
	var i : int;
	var s : string;
	var phys, before : float;
	var victim : CActor;
	var ign : bool;

	w = GetWitcherPlayer();
	victim = (CActor)act.victim;
	watch = w && w.gmTestAi17Watch && act.victim == w.gmTestAi17Watch;
	onGeralt = GMTestProbes() && act.victim == thePlayer && act.attacker != thePlayer;
	onNpc = GMTestProbes() && thePlayer.gmTestAi17Npc && act.victim == thePlayer.gmTestAi17Npc;
	s = "";
	phys = -1;
	if( watch || onGeralt || onNpc )
	{
		act.GetDTs(dts);
		for( i = 0; i < dts.Size(); i += 1 )
		{
			s += " " + dts[i].dmgType + " " + NoTrailZeros(dts[i].dmgVal);
			if( dts[i].dmgType == theGame.params.DAMAGE_NAME_PHYSICAL )
				phys = dts[i].dmgVal;
		}
		if( victim )
			before = victim.GetHealth();
		ign = act.GetIgnoreArmor();
	}
	wrappedMethod(act);
	if( watch )
		w.GMTestAi17Record(s, phys, act.GetDamageDealt(), ign);
	if( onGeralt || onNpc )
		LogChannel('GMTestAI', "C2EV hit on " + victim.GetReadableName() + " by " + ((CActor)act.attacker).GetReadableName() + " (" + act.GetBuffSourceName() + ", causer " + GMTestAi17Causer(act.causer)
			+ ", reaction " + act.GetHitReactionType() + ", dot " + act.IsDoTDamage() + ", ranged " + act.IsActionRanged() + ", instant kill " + act.GetInstantKill() + "):" + s
			+ " -> dealt " + NoTrailZeros(act.GetDamageDealt()) + ", health " + NoTrailZeros(before) + " -> " + NoTrailZeros(victim.GetHealth()) + ", alive " + victim.IsAlive()
			+ "; frost slowdown " + victim.HasBuff(EET_SlowdownFrost) + ", burning " + victim.HasBuff(EET_Burning) + ", Geralt level " + thePlayer.GetLevel());
}

// Real light attacks on the test NPC (B1's swings through the input handler, one every 1.4 s; they refill both sides'
// stamina and the NPC's health at each swing).
@addMethod(W3PlayerWitcher)
function GMTestAi17Swing(n : int)
{
	gmTestAi08Npc = gmTestAi17Npc;
	gmTestAi08Left = n;
	AddTimer('GMTestAi08Swing', 1.4, true);
}

exec function gmtest_ai17_swing(n : int)
{
	if( thePlayer.gmTestAi17Npc )
		GetWitcherPlayer().GMTestAi17Swing(n);
}

// Geralt's hits kill instantly (vanilla's ForceInstantKill ability, which ProcessInstantKill reads), or not.
exec function gmtest_ai17_force(on : bool)
{
	if( on )
		thePlayer.AddAbility('ForceInstantKill', false);
	else
		thePlayer.RemoveAbility('ForceInstantKill');
	LogChannel('GMTestAI', "C2EV ForceInstantKill on Geralt " + thePlayer.HasAbility('ForceInstantKill'));
}

// The test NPC's death signal (a rotfiend's explosion task listens to it), with the NPC unfrozen.
exec function gmtest_ai17_death()
{
	if( thePlayer.gmTestAi17Npc )
	{
		LogChannel('GMTestAI', "C2EV death signal to " + thePlayer.gmTestAi17Npc.GetReadableName() + ", Geralt " + NoTrailZeros(VecDistance(thePlayer.GetWorldPosition(), thePlayer.gmTestAi17Npc.GetWorldPosition())) + " m away");
		thePlayer.gmTestAi17Npc.SignalGameplayEvent('Death');
	}
}
