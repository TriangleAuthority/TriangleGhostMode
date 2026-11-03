// FIX's in-game checks (legacy's bug fixes no area took, docs/features/fix.md). gmtest_regress() and gmtest_panel() call the two
// functions GMTest_fix() and GMTest_fix_after(), so FIX adds its checks here and never edits gmTests.ws's lists.
//   GMTest_fix()        in gmtest_regress(): checks that need no fight, input or menu, each restoring what it changes
//   GMTest_fix_after()  in gmtest_panel(): checks that need the pause menu open, or read the game a frame or more
//                        after gmtest_regress() (spawned samples, effects' first updates)

exec function gmtest_fix()
{
	thePlayer.GMTestCount(true, true);
	GMTest_fix();
	LogChannel('GMTest', "SUMMARY fix: " + thePlayer.gmTestPassed + " passed, " + thePlayer.gmTestFailed + " failed");
}

function GMTest_fix()
{
	GMTest_fix01();	// FIX-01 (slice K1)
	GMTest_fix02();	// FIX-02 (slice K1)
	GMTest_fix05();	// FIX-05 (slice K2)
	GMTest_fix07();	// FIX-07 (slice K2)
	GMTest_fix06();	// FIX-06 (slice K3)
	GMTest_fix03();	// FIX-03 (slice K4)
	GMTest_fix04();	// FIX-04 (slice K5)
}

function GMTest_fix_after()
{
}

// ---------------------------------------------------------------------------------------------------------------
// FIX-01 and FIX-02 (slice K1): projectile collision groups, the arrow's stop list, the arrow of Yoana's armor test.

@addMethod(W3AdvancedProjectile)
function GMTestFixActive() : bool
{
	return isActive;
}

// A monster projectile task's groups after its Initialize (FIX-01's replacement), with 5.x's default groups or a
// task's custom ones.
@addMethod(CBTTaskProjectileAttack)
function GMTestFixGroups(custom : bool, ragdoll : bool, terrain : bool, staticCol : bool, water : bool) : array<name>
{
	collisionGroups.Clear();
	useCustomCollisionGroups = custom;
	collideWithRagdoll = ragdoll;
	collideWithTerrain = terrain;
	collideWithStatic = staticCol;
	collideWithWater = water;
	Initialize();
	return collisionGroups;
}

function GMTestFixNames(groups : array<name>) : string
{
	var s : string;
	var i : int;

	for(i = 0; i < groups.Size(); i += 1)
		s += " " + groups[i];
	return s;
}

function GMTestFixSame(groups : array<name>, expected : array<name>) : bool
{
	var i : int;

	if(groups.Size() != expected.Size())
		return false;
	for(i = 0; i < groups.Size(); i += 1)
		if(groups[i] != expected[i])
			return false;
	return true;
}

// An arrow (the archers' own, arrow_01, as CBTTaskShoot creates it) 3 m in front of Geralt, initialised and
// active as at a shot; its own caster when none is given.
function GMTestFixArrow(caster : CEntity) : W3ArrowProjectile
{
	var arrow : W3ArrowProjectile;
	var pos : Vector;

	pos = thePlayer.GetWorldPosition() + thePlayer.GetHeadingVector() * 3;
	pos.Z += 1.5;
	arrow = (W3ArrowProjectile)theGame.CreateEntity((CEntityTemplate)LoadResource("items\weapons\projectiles\arrows\arrow_01.w2ent", true), pos);
	if(arrow)
	{
		if(caster)
			arrow.Init(caster);
		else
			arrow.Init(arrow);
		arrow.ToggleActiveState(true);
	}
	return arrow;
}

// FIX-01: an arrow's collision with no entity in one group; true when it stopped (isActive false).
function GMTestFixArrowStops(group : name) : bool
{
	var arrow : W3ArrowProjectile;
	var groups : array<name>;
	var stopped : bool;

	arrow = GMTestFixArrow(thePlayer);
	if(!arrow)
		return false;
	groups.PushBack(group);
	arrow.OnProjectileCollision(arrow.GetWorldPosition(), Vector(0, 0, 1), NULL, groups, 0, 0);
	stopped = !arrow.GMTestFixActive();
	arrow.Destroy();
	return stopped;
}

exec function gmtest_fix01()
{
	thePlayer.GMTestCount(true, true);
	GMTest_fix01();
	LogChannel('GMTest', "SUMMARY fix01: " + thePlayer.gmTestPassed + " passed, " + thePlayer.gmTestFailed + " failed");
}

function GMTest_fix01()
{
	var task : CBTTaskProjectileAttack;
	var groups, expected, stops : array<name>;
	var i : int;
	var ok : bool;
	var s : string;

	// The archers' shot: 1.32's three groups, then legacy's seven (what the replaced ShootProjectile adds).
	groups.PushBack('Ragdoll'); groups.PushBack('Terrain'); groups.PushBack('Static');
	GMFixShotCollisionGroups(groups);
	expected.PushBack('Ragdoll'); expected.PushBack('Terrain'); expected.PushBack('Static');
	expected.PushBack('Debris'); expected.PushBack('Destructible'); expected.PushBack('RigidBody'); expected.PushBack('Foliage');
	expected.PushBack('Door'); expected.PushBack('Platforms'); expected.PushBack('Fence');
	GMTestReport(GMTestFixSame(groups, expected), "FIX-01 an archer's shot collides with" + GMTestFixNames(groups)
		+ " [legacy: Ragdoll Terrain Static Debris Destructible RigidBody Foliage Door Platforms Fence; 5.x: the first three and Foliage]");

	// A monster projectile task (a fresh one, no NPC): the default groups and a task's custom ones.
	task = new CBTTaskProjectileAttack in theGame;
	groups = task.GMTestFixGroups(false, false, false, false, false);
	expected.Clear();
	expected.PushBack('Ragdoll'); expected.PushBack('Terrain'); expected.PushBack('Static'); expected.PushBack('Water');
	expected.PushBack('Debris'); expected.PushBack('RigidBody'); expected.PushBack('Foliage'); expected.PushBack('Door'); expected.PushBack('Fence');
	GMTestReport(GMTestFixSame(groups, expected), "FIX-01 a monster projectile (default groups) collides with" + GMTestFixNames(groups)
		+ " [legacy: Ragdoll Terrain Static Water Debris RigidBody Foliage Door Fence; 5.x: the first four]");
	groups = task.GMTestFixGroups(true, true, true, true, false);
	expected.Clear();
	expected.PushBack('Ragdoll'); expected.PushBack('Terrain'); expected.PushBack('Static');
	expected.PushBack('Debris'); expected.PushBack('RigidBody'); expected.PushBack('Foliage'); expected.PushBack('Door'); expected.PushBack('Fence');
	GMTestReport(GMTestFixSame(groups, expected), "FIX-01 a monster projectile (custom groups with static) collides with" + GMTestFixNames(groups)
		+ " [legacy: Ragdoll Terrain Static Debris RigidBody Foliage Door Fence; 5.x: the first three]");
	groups = task.GMTestFixGroups(true, true, true, false, true);
	expected.Clear();
	expected.PushBack('Ragdoll'); expected.PushBack('Terrain'); expected.PushBack('Water');
	GMTestReport(GMTestFixSame(groups, expected), "FIX-01 a monster projectile (custom groups without static) collides with" + GMTestFixNames(groups)
		+ " [legacy and 5.x: Ragdoll Terrain Water]");
	delete task;

	// The arrow stops at every group legacy lists; a ragdoll (a body) does not stop it.
	stops.PushBack('Terrain'); stops.PushBack('Static'); stops.PushBack('Foliage');
	stops.PushBack('Debris'); stops.PushBack('Destructible'); stops.PushBack('RigidBody'); stops.PushBack('Door'); stops.PushBack('Platforms'); stops.PushBack('Fence');
	ok = true;
	for(i = 0; i < stops.Size(); i += 1)
	{
		if(GMTestFixArrowStops(stops[i]))
			s += " " + stops[i] + " stops;";
		else
		{
			s += " " + stops[i] + " FLIES ON;";
			ok = false;
		}
	}
	GMTestReport(ok, "FIX-01 an arrow hitting each solid group:" + s + " [legacy: all nine stop it; 5.x: Terrain, Static and Foliage only]");
	GMTestReport(!GMTestFixArrowStops('Ragdoll'), "FIX-01 an arrow hitting a ragdoll with no entity flies on");
}

// FIX-02: a collision whose component belongs to an entity that is not a gameplay entity (the game camera's), so the
// arrow finds no victim. With Yoana's test armor on, Geralt is the victim and the armor's bounce_arrows bounces the
// arrow: BounceOff, then Init with Geralt as its caster (which also sets isActive false, OnProjectileInit), and the
// quest's fact sq108_arrow_deflected; no damage. Without it the arrow ignores the collision (its caster stays itself).
function GMTestFixArrowBounces(out found : bool, out info : string) : bool
{
	var arrow : W3ArrowProjectile;
	var comp : CComponent;
	var ent : CGameplayEntity;
	var groups : array<name>;
	var bounced, fact : bool;
	var hp, lost : float;

	found = false;
	comp = theGame.GetGameCamera().GetComponentByClassName('CComponent');
	if(!comp)
		return false;
	ent = (CGameplayEntity)comp.GetEntity();
	if(ent)
		return false;
	found = true;
	arrow = GMTestFixArrow(NULL);
	if(!arrow)
		return false;
	hp = thePlayer.GetStat(BCS_Vitality);
	FactsRemove("sq108_arrow_deflected");
	arrow.OnProjectileCollision(thePlayer.GetWorldPosition() + Vector(0, 0, 1.5), Vector(0, 0, 1), comp, groups, 0, 0);
	fact = FactsDoesExist("sq108_arrow_deflected");
	lost = hp - thePlayer.GetStat(BCS_Vitality);
	bounced = arrow.caster == thePlayer && fact && lost == 0;
	info = "caster now Geralt " + (arrow.caster == thePlayer) + ", sq108_arrow_deflected set " + fact + ", Vitality lost " + NoTrailZeros(lost);
	if(lost > 0)
		thePlayer.ForceSetStat(BCS_Vitality, hp);
	arrow.Destroy();
	return bounced;
}

exec function gmtest_fix02()
{
	thePlayer.GMTestCount(true, true);
	GMTest_fix02();
	LogChannel('GMTest', "SUMMARY fix02: " + thePlayer.gmTestPassed + " passed, " + thePlayer.gmTestFailed + " failed");
}

function GMTest_fix02()
{
	var w : W3PlayerWitcher;
	var old, added : array<SItemUniqueId>;
	var names : array<name>;
	var types : array<EEffectType>;
	var kept : array<SGMTestEfxSavedBuff>;
	var found, without, withArmor, fact, worn : bool;
	var info : string;

	w = GetWitcherPlayer();
	fact = FactsDoesExist("sq108_arrow_deflected");
	without = GMTestFixArrowBounces(found, info);
	GMTestReport(found && !without, "FIX-02 without Yoana's test armor, an arrow colliding with no entity flies on (a camera component found: " + found + "; " + info + ")");

	// The gear swap loses the Armorer's Table and grindstone buffs: saved and put back (as GMTestWgt05Classes).
	types.PushBack(EET_EnhancedArmor);
	types.PushBack(EET_EnhancedWeapon);
	kept = GMTestEfxSaveBuffs(types);
	old = GMTestArmWorn();
	names.PushBack('sq108_heavy_armor');
	GMTestArmWear(names, added);
	worn = w.HasAbility('sq108_heavy_armor _Stats', true);
	withArmor = GMTestFixArrowBounces(found, info);
	GMTestArmRestore(added, old);
	GMTestEfxRestoreBuffs(types, kept);
	FactsRemove("sq108_arrow_deflected");
	if(fact)
		FactsAdd("sq108_arrow_deflected");	// the save's own fact put back
	GMTestReport(found && worn && withArmor, "FIX-02 with Yoana's test armor on (sq108_heavy_armor _Stats: " + worn + "), an arrow colliding with no entity hits Geralt and bounces off: "
		+ withArmor + " (" + info + ") [legacy: bounces; 5.x: flies on]");
	GMTestReport(!w.HasAbility('sq108_heavy_armor _Stats', true), "FIX-02 Yoana's test armor taken off again");
}

// ---------------------------------------------------------------------------------------------------------------
// FIX-05 and FIX-07 (slice K2): a hit cancels a throw only during a real throw; Vitality regen resumed at a load.

@addField(CR4Player)
public var gmTestFixAbortProbe : bool;

@addField(CR4Player)
public var gmTestFixAborts : int;

@addMethod(CR4Player)
function GMTestFixSetThrowing(throwing : bool, aiming : bool)
{
	isThrowingItem = throwing;
	isThrowingItemWithAim = aiming;
}

@addMethod(CR4Player)
function GMTestFixProbe(on : bool)
{
	gmTestFixAbortProbe = on;
	gmTestFixAborts = 0;
}

// Test probes: while on, an abort is counted and not run (nothing is being thrown).
@wrapMethod(CR4Player)
function ThrowingAbort()
{
	if(gmTestFixAbortProbe)
	{
		gmTestFixAborts += 1;
		return;
	}
	wrappedMethod();
}

@wrapMethod(CR4Player)
function BombThrowAbort()
{
	if(gmTestFixAbortProbe)
	{
		gmTestFixAborts += 1;
		return;
	}
	wrappedMethod();
}

// A hit on Geralt that dealt 10 Vitality damage, as ReactToBeingHit receives it (not run through the damage manager).
function GMTestFixHit(anim : EActionHitAnim, dot : bool) : W3DamageAction
{
	var action : W3DamageAction;

	action = new W3DamageAction in theGame.damageMgr;
	action.Initialize(NULL, thePlayer, NULL, "gmtest_fix05", EHRT_Light, CPS_AttackPower, false, false, false, false);
	action.AddDamage(theGame.params.DAMAGE_NAME_DIRECT, 10);
	action.processedDmg.vitalityDamage = 10;	// as after the damage manager's processing: DealsAnyDamage reads it
	action.SetHitAnimationPlayType(anim);
	if(dot)
		action.SetIsDoTDamage(1);
	return action;
}

function GMTestFixAborts(throwing : bool, aiming : bool, anim : EActionHitAnim, dot : bool) : bool
{
	var w : W3PlayerWitcher;
	var throwing0, aiming0, res : bool;

	w = GetWitcherPlayer();
	throwing0 = w.IsThrowingItem();
	aiming0 = w.IsThrowingItemWithAim();
	w.GMTestFixSetThrowing(throwing, aiming);
	res = w.GMFixHitAbortsThrow(GMTestFixHit(anim, dot));
	w.GMTestFixSetThrowing(throwing0, aiming0);
	return res;
}

exec function gmtest_fix05()
{
	thePlayer.GMTestCount(true, true);
	GMTest_fix05();
	LogChannel('GMTest', "SUMMARY fix05: " + thePlayer.gmTestPassed + " passed, " + thePlayer.gmTestFailed + " failed");
}

// FIX-05: the abort's test as ENCH-16's ReactToBeingHit replacement calls it.
function GMTest_fix05()
{
	GMTestReport(!GMTestFixAborts(false, false, EAHA_Default, false), "FIX-05 a damaging hit while Geralt throws nothing runs no throw abort [legacy: none; 5.x: the abort]");
	GMTestReport(GMTestFixAborts(true, false, EAHA_Default, false), "FIX-05 a damaging hit with a hit reaction during a bomb throw aborts it");
	GMTestReport(GMTestFixAborts(false, true, EAHA_Default, false), "FIX-05 a damaging hit with a hit reaction during a crossbow aim aborts it");
	GMTestReport(!GMTestFixAborts(true, false, EAHA_ForceNo, false), "FIX-05 a damaging hit with no hit reaction (EAHA_ForceNo) leaves the throw going [legacy: kept; 5.x: aborted]");
	GMTestReport(!GMTestFixAborts(true, false, EAHA_Default, true), "FIX-05 damage over time during a throw does not abort it (1.32, 5.x and legacy)");
}

// FIX-05 through the real ReactToBeingHit (not in the regression: it plays a hit reaction on Geralt): the probes
// count the aborts it runs for a hit while throwing nothing, while throwing with no hit reaction, while throwing.
exec function gmtest_fix05_hit()
{
	var w : W3PlayerWitcher;
	var none, forceNo, thrown : int;
	var throwing0, aiming0 : bool;

	thePlayer.GMTestCount(true, true);
	w = GetWitcherPlayer();
	throwing0 = w.IsThrowingItem();
	aiming0 = w.IsThrowingItemWithAim();
	w.GMTestFixSetThrowing(false, false);
	w.GMTestFixProbe(true);
	w.ReactToBeingHit(GMTestFixHit(EAHA_ForceNo, false));
	none = w.gmTestFixAborts;
	w.GMTestFixSetThrowing(true, false);
	w.GMTestFixProbe(true);
	w.ReactToBeingHit(GMTestFixHit(EAHA_ForceNo, false));
	forceNo = w.gmTestFixAborts;
	w.GMTestFixProbe(true);
	w.ReactToBeingHit(GMTestFixHit(EAHA_Default, false));
	thrown = w.gmTestFixAborts;
	w.GMTestFixProbe(false);
	w.GMTestFixSetThrowing(throwing0, aiming0);
	GMTestReport(none == 0, "FIX-05 ReactToBeingHit, throwing nothing: " + none + " aborts [legacy 0; 5.x 1]");
	GMTestReport(forceNo == 0, "FIX-05 ReactToBeingHit, throwing, no hit reaction: " + forceNo + " aborts [legacy 0; 5.x 1]");
	GMTestReport(thrown == 1, "FIX-05 ReactToBeingHit, throwing, a hit reaction: " + thrown + " aborts [1]");
	LogChannel('GMTest', "SUMMARY fix05_hit: " + thePlayer.gmTestPassed + " passed, " + thePlayer.gmTestFailed + " failed");
}

exec function gmtest_fix07()
{
	thePlayer.GMTestCount(true, true);
	GMTest_fix07();
	LogChannel('GMTest', "SUMMARY fix07: " + thePlayer.gmTestPassed + " passed, " + thePlayer.gmTestFailed + " failed");
}

// FIX-07: Vitality regen paused as a fistfight's start pauses it, then the load's resume (what the OnSpawned wrapper
// calls): no longer paused by the fistfight.
function GMTest_fix07()
{
	var buff : CBaseGameplayEffect;
	var before, after : bool;

	buff = thePlayer.GetBuff(EET_AutoVitalityRegen);
	if(!buff)
	{
		GMTestReport(false, "FIX-07 Geralt has no Vitality regen effect to test");
		return;
	}
	thePlayer.PauseHPRegenEffects('FistFightMinigame', -1);
	before = buff.IsPaused('FistFightMinigame');
	GetWitcherPlayer().GMFixResumeFistfightRegen();
	after = buff.IsPaused('FistFightMinigame');
	thePlayer.ResumeHPRegenEffects('FistFightMinigame');
	GMTestReport(before && !after, "FIX-07 Vitality regen paused by a fistfight (" + before + ") is resumed at a load: still paused " + after + " [legacy: resumed; 5.x: stays paused]");
}

// ---------------------------------------------------------------------------------------------------------------
// FIX-06 (slice K3): a generic merchant gets his scene's required tags first.

@addMethod(W3MerchantNPC)
function GMTestFixScenePath() : string
{
	if(embeddedScenes.Size() > 0 && embeddedScenes[0].storyScene)
		return embeddedScenes[0].storyScene.GetPath();
	return "";
}

@addMethod(W3MerchantNPC)
function GMTestFixRequiredTags() : array<name>
{
	var none : array<name>;

	if(embeddedScenes.Size() > 0 && embeddedScenes[0].storyScene)
		return embeddedScenes[0].storyScene.GetRequiredPositionTags();
	return none;
}

function GMTestFixStartsWith(tags : array<name>, head : array<name>) : bool
{
	var i : int;

	if(head.Size() == 0 || tags.Size() < head.Size())
		return false;
	for(i = 0; i < head.Size(); i += 1)
		if(tags[i] != head[i])
			return false;
	return true;
}

function GMTestFixMerchant(path : string, dist : float) : W3MerchantNPC
{
	var template : CEntityTemplate;

	template = (CEntityTemplate)LoadResource(path, true);
	return (W3MerchantNPC)theGame.CreateEntity(template, thePlayer.GetWorldPosition() - thePlayer.GetHeadingVector() * dist, thePlayer.GetWorldRotation());
}

exec function gmtest_fix06()
{
	thePlayer.GMTestCount(true, true);
	GMTest_fix06();
	LogChannel('GMTest', "SUMMARY fix06: " + thePlayer.gmTestPassed + " passed, " + thePlayer.gmTestFailed + " failed");
}

function GMTest_fix06()
{
	var m : W3MerchantNPC;
	var req, tags, again : array<name>;
	var npcs : array<CNewNPC>;
	var paths : array<string>;
	var path : string;
	var i : int;
	var generic : bool;

	// A generic travelling merchant (the Novigrad blacksmith of the generic shop scene), spawned as the world spawns
	// him: OnSpawned runs inside CreateEntity.
	m = GMTestFixMerchant("living_world\dialogue\generic_merchants\entities\shop_generic_merchant_novigrad_weapons.w2ent", 9);
	if(!m)
		GMTestReport(false, "FIX-06 the generic merchant did not spawn");
	else
	{
		path = m.GMTestFixScenePath();
		req = m.GMTestFixRequiredTags();
		tags = m.GetTags();
		GMTestReport(StrBeginsWith(path, "living_world\dialogue\generic_merchants\shop_generic_merchant") && GMTestFixStartsWith(tags, req) && tags.Contains('ShopkeeperEntity'),
			"FIX-06 a generic merchant's tags begin with his scene's required tags and keep ShopkeeperEntity: scene " + path + ", required" + GMTestFixNames(req) + ", tags" + GMTestFixNames(tags));
		if(req.Size() > 0)
			theGame.GetNPCsByTag(req[0], npcs);
		GMTestReport(req.Size() > 0 && npcs.Contains(m), "FIX-06 the generic merchant is found by his scene's tag (as ShowMeGoods finds him): " + npcs.Size() + " NPCs tagged");
		m.GMFixGenericMerchantTags();
		again = m.GetTags();
		GMTestReport(GMTestFixSame(again, tags), "FIX-06 the block run again changes nothing (tags" + GMTestFixNames(again) + ")");
		m.Destroy();
	}

	// A merchant of another scene: his tags are left alone.
	paths.PushBack("gameplay\community\shops_and_craftsmen\novigrad\temple_district\novi_temple_dist_alchemist_01.w2ent");
	paths.PushBack("dlc\ep1\data\gameplay\community\shops_and_craftsmen\enchanter\enchanter_01_lvl_1.w2ent");
	generic = true;
	for(i = 0; i < paths.Size() && generic; i += 1)
	{
		m = GMTestFixMerchant(paths[i], 10);
		if(!m)
			continue;
		path = m.GMTestFixScenePath();
		generic = StrBeginsWith(path, "living_world\dialogue\generic_merchants\shop_generic_merchant");
		if(!generic)
		{
			tags = m.GetTags();
			m.GMFixGenericMerchantTags();
			again = m.GetTags();
			GMTestReport(GMTestFixSame(again, tags), "FIX-06 a merchant of another scene (" + paths[i] + ", scene '" + path + "') keeps his tags:" + GMTestFixNames(again));
		}
		m.Destroy();
	}
	if(generic)
		GMTestReport(false, "FIX-06 no merchant of another scene found among the samples");
}

// ---------------------------------------------------------------------------------------------------------------
// FIX-03 (slice K4): quest items released after their quest.

// Legacy's 108 items (FixQuestItems' cases, in its order).
function GMTestFix03Items() : array<name>
{
	var names : array<name>;

	names.PushBack('lw_gr29_cage_key');
	names.PushBack('lw_sk41_prison_key');
	names.PushBack('lw_sk90_cage_key');
	names.PushBack('poi_bar_a_10_key');
	names.PushBack('poi_gor_d_06_note04');
	names.PushBack('ep1_poi_12_note_b');
	names.PushBack('camm_trophy');
	names.PushBack('q702_vampire_mask');
	names.PushBack('q704_vampire_mask');
	names.PushBack('sq701_item_wearable_feather');
	names.PushBack('q701_hare_mask');
	names.PushBack('q701_nml_notice');
	names.PushBack('noon_shadow_loot_note');
	names.PushBack('Only Geralt mandragora mask');
	names.PushBack('Beauclair Casual Suit 01');
	names.PushBack('Beauclair Casual Suit with medal');
	names.PushBack('Beauclair Casual Pants 01');
	names.PushBack('Beauclair casual shoes 01');
	names.PushBack('q705_medal');
	names.PushBack('q704_orianas_vampire_key');
	names.PushBack('q702_wicht_key');
	names.PushBack('th700_vault_journal');
	names.PushBack('th700_prison_journal');
	names.PushBack('th700_chapel_journal');
	names.PushBack('th700_crypt_journal');
	names.PushBack('th700_lake_journal');
	names.PushBack('th701_coward_journal');
	names.PushBack('th701_portal_crystal');
	names.PushBack('th701_wolf_witcher_note');
	names.PushBack('mh701_usable_lure');
	names.PushBack('mq7002_love_letter_01');
	names.PushBack('mq7002_love_letter_02');
	names.PushBack('mq7007_elven_mask');
	names.PushBack('mq7007_elven_shield');
	names.PushBack('Flowers');
	names.PushBack('Perfume');
	names.PushBack('sq701_victory_laurels');
	names.PushBack('mq7017_zmora_trophy');
	names.PushBack('sq703_accountance_book');
	names.PushBack('sq703_hunter_letter');
	names.PushBack('sq703_map_alternative');
	names.PushBack('sq703_wife_letter');
	names.PushBack('poi_gor_a_10_note');
	names.PushBack('poi_car_b_10_note_02');
	names.PushBack('poi_ww_ver_10_note');
	names.PushBack('mq6004_lab_key');
	names.PushBack('q504_fish');
	names.PushBack('Potestaquisitor');
	names.PushBack('Trial Potion Kit');
	names.PushBack('q401_forktail_brain');
	names.PushBack('q301_burdock');
	names.PushBack('q309_key_orders');
	names.PushBack('q309_key_letters');
	names.PushBack('q310_wine');
	names.PushBack('q206_herb_mixture');
	names.PushBack('q206_arnvalds_letter');
	names.PushBack('q111_fugas_top_key');
	names.PushBack('q106_magic_oillamp');
	names.PushBack('mq1002_artifact_1');
	names.PushBack('mq1002_artifact_2');
	names.PushBack('mq1002_artifact_3');
	names.PushBack('sq305_trophies');
	names.PushBack('sq303_robbery_speech');
	names.PushBack('sq201_ship_manifesto');
	names.PushBack('sq201_cursed_jewel');
	names.PushBack('sq201_werewolf_meat');
	names.PushBack('sq201_padlock_key');
	names.PushBack('sq205_brewing_instructions');
	names.PushBack('sq205_brewmasters_log');
	names.PushBack('sq104_notes');
	names.PushBack('q302_crafter_notes');
	names.PushBack('q303_bomb_fragment');
	names.PushBack('q303_bomb_cap');
	names.PushBack('q303_contact_note');
	names.PushBack('q308_sermon_1');
	names.PushBack('q308_sermon_2');
	names.PushBack('q308_sermon_3');
	names.PushBack('q308_sermon_4');
	names.PushBack('q308_sermon_5');
	names.PushBack('q308_nathanel_sermon_1');
	names.PushBack('q310_lever');
	names.PushBack('q309_mssg_from_triss');
	names.PushBack('q309_witch_hunters_orders');
	names.PushBack('q202_hjalmar_cell_key');
	names.PushBack('Geralt mask 01');
	names.PushBack('Geralt mask 02');
	names.PushBack('Geralt mask 03');
	names.PushBack('sq302_agates');
	names.PushBack('sq302_eyes');
	names.PushBack('sq204_wolf_heart');
	names.PushBack('th1009_journal_wolf_part4');
	names.PushBack('th1009_journal_wolf_part2a');
	names.PushBack('mq1055_letters');
	names.PushBack('mq4002_note');
	names.PushBack('mq4005_note_1');
	names.PushBack('mq4006_book');
	names.PushBack('mq2001_journal_2b');
	names.PushBack('mq2020_slave_cells_key');
	names.PushBack('mq2038_headsman_sword');
	names.PushBack('mq2015_kurisus_note');
	names.PushBack('mq0004_thalers_monocle');
	names.PushBack('mq0004_thalers_monocle_wearable');
	names.PushBack('mh305_doppler_letter');
	names.PushBack('mh207_lighthouse_keeper_letter');
	names.PushBack('cg100_barons_notes');
	names.PushBack('cg700_letter_monniers_brother');
	names.PushBack('cg700_letter_merchants');
	names.PushBack('cg700_letter_purist');
	return names;
}

// The six map pins legacy's key and note cases read.
function GMTestFix03Pins() : array<name>
{
	var pins : array<name>;

	pins.PushBack('nml_mp_gr29');
	pins.PushBack('sk41_mp_skellige');
	pins.PushBack('sk90_mp_skl');
	pins.PushBack('poi_bar_a_10_mp');
	pins.PushBack('poi_gor_d_06_mp');
	pins.PushBack('ep1_poi12_mp');
	return pins;
}

// A quest's journal entry from its file, set to `status`; the status it had is returned in `old`.
function GMTestFix03SetQuest(file : string, status : EJournalStatus, out old : EJournalStatus) : CJournalBase
{
	var r : CJournalResource;
	var e : CJournalBase;
	var jm : CWitcherJournalManager;

	jm = theGame.GetJournalManager();
	r = (CJournalResource)LoadResource(file, true);
	if(r)
		e = r.GetEntry();
	if(e)
	{
		old = jm.GetEntryStatus(e);
		jm.ActivateEntry(e, status, false, false);
	}
	return e;
}

function GMTestFix03Tags(inv : CInventoryComponent, id : SItemUniqueId) : string
{
	return "Quest " + inv.ItemHasTag(id, 'Quest') + ", NoDrop " + inv.ItemHasTag(id, 'NoDrop');
}

// One case: `item` added, its quest (a journal file) set to `status`, GMFixQuestItems run (what opening the inventory
// runs); the item's tags after it are returned, and everything put back.
function GMTestFix03Case(item : name, file : string, status : EJournalStatus, out before : string, out found : bool) : string
{
	var inv : CInventoryComponent;
	var ids : array<SItemUniqueId>;
	var e : CJournalBase;
	var old : EJournalStatus;
	var after : string;

	inv = thePlayer.GetInventory();
	found = true;
	if(file != "")
	{
		e = GMTestFix03SetQuest(file, status, old);
		if(!e)
			found = false;
	}
	ids = inv.AddAnItem(item, 1, true, true, false);
	if(ids.Size() == 0)
	{
		found = false;
		if(e)
			theGame.GetJournalManager().ActivateEntry(e, old, false, false);
		return "not added";
	}
	before = GMTestFix03Tags(inv, ids[0]);
	GMFixQuestItems();
	after = GMTestFix03Tags(inv, ids[0]);
	inv.RemoveItem(ids[0], 1);
	if(e)
		theGame.GetJournalManager().ActivateEntry(e, old, false, false);
	return after;
}

exec function gmtest_fix03()
{
	thePlayer.GMTestCount(true, true);
	GMTest_fix03();
	LogChannel('GMTest', "SUMMARY fix03: " + thePlayer.gmTestPassed + " passed, " + thePlayer.gmTestFailed + " failed");
}

function GMTest_fix03()
{
	var dm : CDefinitionsManagerAccessor;
	var mm : CCommonMapManager;
	var names, pins, known : array<name>;
	var areas : array<SAreaMapPinInfo>;
	var epins : array<SEntityMapPinInfo>;
	var i, j, defined : int;
	var noQuest, missing, before, after : string;
	var found, pinOld : bool;

	// Data: legacy's 108 items in 5.x's definitions (with the item layer's changes): all defined, all quest items but
	// the five that never were (Flowers, Perfume, mq1002_artifact_3, the two vampire masks), the Camerlengo's Seal
	// (TRPH-02) and the two wearables FIX-03 releases in the data; the Hearts of Stone note a QuestEP1 item.
	dm = theGame.GetDefinitionsManager();
	names = GMTestFix03Items();
	for(i = 0; i < names.Size(); i += 1)
	{
		if(IsNameValid(dm.GetItemCategory(names[i])))
			defined += 1;
		else
			missing += " " + names[i];
		if(!dm.ItemHasTag(names[i], 'Quest'))
			noQuest += " " + names[i];
	}
	GMTestReport(names.Size() == 108 && defined == 108, "FIX-03 legacy's " + names.Size() + " quest items defined in 5.x: " + defined + ", missing:" + missing);
	GMTestReport(noQuest == " camm_trophy q702_vampire_mask q704_vampire_mask sq701_item_wearable_feather Flowers Perfume mq1002_artifact_3 mq0004_thalers_monocle_wearable",
		"FIX-03 the items without Quest in the data:" + noQuest + " [the five that never had it, camm_trophy (TRPH-02), the feather and the wearable monocle (FIX-03)]");
	GMTestReport(dm.ItemHasTag('ep1_poi_12_note_b', 'QuestEP1') && dm.ItemHasTag('ep1_poi_12_note_b', 'Quest'), "FIX-03 the Hearts of Stone note ep1_poi_12_note_b carries QuestEP1 (and Quest)");

	// Data: the six map pins exist among the world's entity map pins (by the name IsEntityMapPinDisabled takes).
	mm = theGame.GetCommonMapManager();
	pins = GMTestFix03Pins();
	areas = mm.GetAreaMapPins();
	for(i = 0; i < areas.Size(); i += 1)
	{
		epins = mm.GetEntityMapPins(areas[i].worldPath);
		for(j = 0; j < epins.Size(); j += 1)
			if(pins.Contains(epins[j].entityName) && !known.Contains(epins[j].entityName))
				known.PushBack(epins[j].entityName);
	}
	missing = "";
	for(i = 0; i < pins.Size(); i += 1)
		if(!known.Contains(pins[i]))
			missing += " " + pins[i];
	GMTestReport(known.Size() == pins.Size(), "FIX-03 the six map pins found among 5.x's entity map pins (" + areas.Size() + " areas): " + known.Size() + ", not found:" + missing);

	// The release rule.
	after = GMTestFix03Case('sq104_notes', "gameplay\journal\quests\sq104werewolf.journal", JS_Success, before, found);
	GMTestReport(found && StrFindFirst(before, "Quest true") >= 0 && after == "Quest false, NoDrop false",
		"FIX-03 sq104_notes after SQ104 Werewolf succeeded: " + before + " -> " + after + " [legacy: released; 5.x: kept]");
	after = GMTestFix03Case('sq104_notes', "gameplay\journal\quests\sq104werewolf.journal", JS_Failed, before, found);
	GMTestReport(found && after == "Quest false, NoDrop false", "FIX-03 sq104_notes after SQ104 Werewolf failed: " + before + " -> " + after);
	after = GMTestFix03Case('sq104_notes', "gameplay\journal\quests\sq104werewolf.journal", JS_Active, before, found);
	GMTestReport(found && StrFindFirst(after, "Quest true") >= 0, "FIX-03 sq104_notes while SQ104 Werewolf is active keeps its tags: " + after);
	after = GMTestFix03Case('q701_hare_mask', "", JS_Inactive, before, found);
	GMTestReport(found && StrFindFirst(before, "Quest true") >= 0 && StrFindFirst(after, "Quest false") >= 0, "FIX-03 the hare mask (always released): " + before + " -> " + after);
	pinOld = mm.IsEntityMapPinDisabled('nml_mp_gr29');
	mm.SetEntityMapPinDisabled('nml_mp_gr29', true);
	after = GMTestFix03Case('lw_gr29_cage_key', "", JS_Inactive, before, found);
	mm.SetEntityMapPinDisabled('nml_mp_gr29', false);
	GMTestReport(found && StrFindFirst(before, "Quest true") >= 0 && StrFindFirst(after, "Quest false") >= 0, "FIX-03 lw_gr29_cage_key once its map pin nml_mp_gr29 is disabled: " + before + " -> " + after);
	after = GMTestFix03Case('lw_gr29_cage_key', "", JS_Inactive, before, found);
	mm.SetEntityMapPinDisabled('nml_mp_gr29', pinOld);
	GMTestReport(found && StrFindFirst(after, "Quest true") >= 0, "FIX-03 lw_gr29_cage_key with its map pin enabled keeps Quest: " + after);
	after = GMTestFix03Case('mh701_usable_lure', "dlc\bob\journal\quests\mh701tectonicterror.journal", JS_Success, before, found);
	GMTestReport(found && before == "Quest true, NoDrop true" && after == "Quest false, NoDrop false",
		"FIX-03 mh701_usable_lure after Contract: Tectonic Terror succeeded loses Quest and NoDrop: " + before + " -> " + after + " [legacy: both off; 5.x: kept]");
	// DK2 (a): 5.x's own quest items keep their tags.
	after = GMTestFix03Case('mq1060_right_hand_potion', "gameplay\journal\quests\mq1060devilspit.journal", JS_Success, before, found);
	GMTestReport(found && StrFindFirst(before, "Quest true") >= 0 && StrFindFirst(after, "Quest true") >= 0,
		"FIX-03 5.x's own mq1060_right_hand_potion after mq1060 succeeded keeps Quest (DK2): " + before + " -> " + after);
}

// The hook: FIX-03 runs when the inventory opens on Geralt's own inventory, not at a shop. Not in the regression (it
// opens menus). gmtest_fix03_menu_a() adds sq104_notes with SQ104 Werewolf succeeded, spawns a merchant and opens
// his shop; gmtest_fix03_menu_b() checks the note kept Quest and closes the shop; gmtest_fix03_menu_c() removes the
// merchant and opens the inventory; gmtest_fix03_menu_d() checks the note lost Quest, closes the menu and puts
// everything back.
@addField(W3PlayerWitcher)
public var gmTestFix03Old : EJournalStatus;

@addMethod(W3PlayerWitcher)
function GMTestFix03Remember(old : EJournalStatus)
{
	gmTestFix03Old = old;
}

exec function gmtest_fix03_menu_a()
{
	var w : W3PlayerWitcher;
	var ids : array<SItemUniqueId>;
	var e : CJournalBase;
	var old : EJournalStatus;
	var m : W3MerchantNPC;
	var initData : W3InventoryInitData;
	var found : bool;

	w = GetWitcherPlayer();
	e = GMTestFix03SetQuest("gameplay\journal\quests\sq104werewolf.journal", JS_Success, old);
	w.GMTestFix03Remember(old);
	ids = w.GetInventory().AddAnItem('sq104_notes', 1, true, true, false);
	m = GMTestFixMerchant("living_world\dialogue\generic_merchants\entities\shop_generic_merchant_novigrad_weapons.w2ent", 3);
	m.AddTag('Merchant');
	m.AddTag('gm_test_fix03');
	m.GetInventory().AutoBalanaceItemsWithPlayerLevel();
	initData = new W3InventoryInitData in theGame.GetGuiManager();
	initData.containerNPC = m;
	theGame.GetGuiManager().SetLastOpenedCommonMenuName('None');
	theGame.RequestMenuWithBackground('InventoryMenu', 'CommonMenu', initData);
	if(e)
		found = true;
	LogChannel('GMTest', "INFO fix03 menu a: note added (" + GMTestFix03Tags(w.GetInventory(), ids[0]) + "), quest found " + found + ", shop requested");
}

function GMTestFix03Note() : string
{
	var inv : CInventoryComponent;
	var ids : array<SItemUniqueId>;

	inv = thePlayer.GetInventory();
	ids = inv.GetItemsByName('sq104_notes');
	if(ids.Size() == 0)
		return "none";
	return GMTestFix03Tags(inv, ids[0]);
}

function GMTestFix03MenuOpen() : bool
{
	var root : CR4MenuBase;
	var inv : CR4InventoryMenu;

	root = (CR4MenuBase)theGame.GetGuiManager().GetRootMenu();
	if(!root)
		return false;
	inv = (CR4InventoryMenu)root.GetLastChild();
	if(inv)
		return true;
	return false;
}

exec function gmtest_fix03_menu_b()
{
	thePlayer.GMTestCount(true, true);
	GMTestReport(GMTestFix03MenuOpen(), "FIX-03 the shop (inventory menu with the merchant) is open");
	GMTestReport(StrFindFirst(GMTestFix03Note(), "Quest true") >= 0, "FIX-03 opening a shop releases nothing: sq104_notes " + GMTestFix03Note());
	theGame.GetGuiManager().GetRootMenu().CloseMenu();
}

exec function gmtest_fix03_menu_c()
{
	var npcs : array<CNewNPC>;
	var i : int;

	theGame.GetNPCsByTag('gm_test_fix03', npcs);
	for(i = 0; i < npcs.Size(); i += 1)
		npcs[i].Destroy();
	theGame.GetGuiManager().SetLastOpenedCommonMenuName('None');
	theGame.RequestMenuWithBackground('InventoryMenu', 'CommonMenu');
}

exec function gmtest_fix03_menu_d()
{
	var inv : CInventoryComponent;
	var ids : array<SItemUniqueId>;
	var e : CJournalBase;
	var r : CJournalResource;

	GMTestReport(GMTestFix03MenuOpen(), "FIX-03 Geralt's own inventory is open");
	GMTestReport(GMTestFix03Note() == "Quest false, NoDrop false", "FIX-03 opening Geralt's inventory released sq104_notes (SQ104 Werewolf succeeded): " + GMTestFix03Note() + " [legacy: released; 5.x: kept]");
	theGame.GetGuiManager().GetRootMenu().CloseMenu();
	inv = thePlayer.GetInventory();
	ids = inv.GetItemsByName('sq104_notes');
	if(ids.Size() > 0)
		inv.RemoveItem(ids[0], 1);
	r = (CJournalResource)LoadResource("gameplay\journal\quests\sq104werewolf.journal", true);
	if(r)
		e = r.GetEntry();
	if(e)
		theGame.GetJournalManager().ActivateEntry(e, GetWitcherPlayer().gmTestFix03Old, false, false);
	LogChannel('GMTest', "SUMMARY fix03_menu: " + thePlayer.gmTestPassed + " passed, " + thePlayer.gmTestFailed + " failed");
}

// ---------------------------------------------------------------------------------------------------------------
// FIX-04 (slice K5): the Family Issues checkpoints. No check writes a save: while the probe is on, the checkpoint
// function counts the saves its rule asks for and saves nothing (and game.py locks saving after each load).

@addField(CR4Game)
public var gmTestFix04Probe : bool;

@addField(CR4Game)
public var gmTestFix04Calls : int;

@addField(CR4Game)
public var gmTestFix04Saves : int;

@addMethod(CR4Game)
function GMTestFix04Probe(on : bool)
{
	gmTestFix04Probe = on;
	gmTestFix04Calls = 0;
	gmTestFix04Saves = 0;
}

@addMethod(CR4Game)
function GMTestFix04Count(saves : int)
{
	gmTestFix04Calls += 1;
	gmTestFix04Saves += saves;
}

// Test probe: while on, a checkpoint call counts and saves nothing.
@wrapMethod
function GMFixFamilyIssuesCheckpoint(questEntry : CJournalQuest)
{
	if(theGame.gmTestFix04Probe)
	{
		theGame.GMTestFix04Count(GMFixFamilyIssuesCheckpointsDue(questEntry));
		return;
	}
	wrappedMethod(questEntry);
}

// Family Issues' escort objective tagged `tag`, from the quest's journal file.
function GMTestFix04Objective(fam : CJournalQuest, tag : string) : CJournalQuestObjective
{
	var i, j : int;
	var phase : CJournalQuestPhase;
	var objective : CJournalQuestObjective;

	for(i = 0; i < fam.GetNumChildren(); i += 1)
	{
		phase = (CJournalQuestPhase)fam.GetChild(i);
		if(phase)
			for(j = 0; j < phase.GetNumChildren(); j += 1)
			{
				objective = (CJournalQuestObjective)phase.GetChild(j);
				if(objective && NameToString(objective.GetUniqueScriptTag()) == tag)
					return objective;
			}
	}
	return NULL;
}

exec function gmtest_fix04()
{
	thePlayer.GMTestCount(true, true);
	GMTest_fix04();
	LogChannel('GMTest', "SUMMARY fix04: " + thePlayer.gmTestPassed + " passed, " + thePlayer.gmTestFailed + " failed");
}

function GMTest_fix04()
{
	var jm : CWitcherJournalManager;
	var r : CJournalResource;
	var fam, other : CJournalQuest;
	var o1, o2 : CJournalQuestObjective;
	var s0, s1, s2 : EJournalStatus;
	var hud : CR4ScriptedHud;
	var oneActive, secondActive, noneActive, otherQuest, hookCalls, hookSaves, callsA, savesA, callsB, savesB, restoreCalls : int;
	var tag : string;
	var found, hudOk, otherOk : bool;

	theGame.GMTestFix04Probe(true);
	jm = theGame.GetJournalManager();
	r = (CJournalResource)LoadResource("gameplay\journal\quests\family.journal", true);
	if(r)
		fam = (CJournalQuest)r.GetEntry();
	if(!fam)
	{
		GMTestReport(false, "FIX-04 Family Issues' journal file (family.journal) not loaded");
		theGame.GMTestFix04Probe(false);
		return;
	}
	tag = NameToString(fam.GetUniqueScriptTag());
	o1 = GMTestFix04Objective(fam, "Protect Baron from wraiths");
	o2 = GMTestFix04Objective(fam, "Protect Baron from wraiths once more");
	if(o1 && o2)
		found = true;
	GMTestReport(tag == "Q103 Family Issues DB024D36-4E9AE35E-FB098D89-C8E7AB0F" && found,
		"FIX-04 5.x's Family Issues has legacy's tags: quest '" + tag + "', both escort objectives found");
	if(!found)
	{
		theGame.GMTestFix04Probe(false);
		return;
	}

	s0 = jm.GetEntryStatus(fam);
	s1 = jm.GetEntryStatus(o1);
	s2 = jm.GetEntryStatus(o2);
	// From "not started", silently (no on-screen info: no HUD event).
	jm.ActivateEntry(o2, JS_Inactive, false, false);
	jm.ActivateEntry(o1, JS_Inactive, false, false);
	jm.ActivateEntry(fam, JS_Inactive, false, false);
	// The walk's start as a quest block activates it (on-screen info on): the quest, then 'Protect Baron from wraiths';
	// each activation raises the HUD's OnQuestUpdate (audit F3). The probe stays on throughout: no save is written.
	theGame.GMTestFix04Probe(true);
	jm.ActivateEntry(fam, JS_Active, true, false);
	jm.ActivateEntry(o1, JS_Active, true, false);
	callsA = theGame.gmTestFix04Calls;
	savesA = theGame.gmTestFix04Saves;
	oneActive = GMFixFamilyIssuesCheckpointsDue(fam);
	// 'wraiths' done, '... once more' started.
	theGame.GMTestFix04Probe(true);
	jm.ActivateEntry(o1, JS_Success, true, false);
	jm.ActivateEntry(o2, JS_Active, true, false);
	callsB = theGame.gmTestFix04Calls;
	savesB = theGame.gmTestFix04Saves;
	secondActive = GMFixFamilyIssuesCheckpointsDue(fam);
	// The HUD's OnQuestUpdate called directly during the escort.
	hud = (CR4ScriptedHud)theGame.GetHud();
	theGame.GMTestFix04Probe(true);
	if(hud)
	{
		hudOk = true;
		hud.OnQuestUpdate(fam, true);
	}
	hookCalls = theGame.gmTestFix04Calls;
	hookSaves = theGame.gmTestFix04Saves;
	jm.ActivateEntry(o2, JS_Success, false, false);
	noneActive = GMFixFamilyIssuesCheckpointsDue(fam);
	r = (CJournalResource)LoadResource("gameplay\journal\quests\sq104werewolf.journal", true);
	if(r)
		other = (CJournalQuest)r.GetEntry();
	if(other)
		otherOk = true;
	otherQuest = GMFixFamilyIssuesCheckpointsDue(other);
	// Put back silently: no HUD event, so no checkpoint call.
	theGame.GMTestFix04Probe(true);
	jm.ActivateEntry(o2, s2, false, false);
	jm.ActivateEntry(o1, s1, false, false);
	jm.ActivateEntry(fam, s0, false, false);
	restoreCalls = theGame.gmTestFix04Calls;
	theGame.GMTestFix04Probe(false);

	GMTestReport(oneActive == 1, "FIX-04 Family Issues with 'Protect Baron from wraiths' active: " + oneActive + " checkpoint due [legacy 1; 5.x none]");
	GMTestReport(secondActive == 1, "FIX-04 with 'Protect Baron from wraiths once more' active: " + secondActive + " checkpoint due [legacy 1]");
	GMTestReport(noneActive == 0, "FIX-04 with both escort objectives done: " + noneActive + " due");
	GMTestReport(otherOk && otherQuest == 0, "FIX-04 another quest's update (SQ104 Werewolf): " + otherQuest + " due");
	GMTestReport(callsA == 2 && savesA == 1, "FIX-04 the walk's start (Family Issues, then 'Protect Baron from wraiths', activated with on-screen info): " + callsA
		+ " HUD updates reached the checkpoint, " + savesA + " checkpoint(s) asked [2 and 1; none written: the probe]");
	GMTestReport(callsB == 2 && savesB == 1, "FIX-04 'wraiths' done and 'once more' started (on-screen info): " + callsB + " HUD updates reached the checkpoint, " + savesB
		+ " checkpoint(s) asked [2 and 1; none written]");
	GMTestReport(hudOk && hookCalls == 1 && hookSaves == 1, "FIX-04 the HUD's OnQuestUpdate for Family Issues during the escort, called directly: " + hookCalls + " call(s), " + hookSaves
		+ " checkpoint(s) asked [1 and 1]");
	GMTestReport(restoreCalls == 0, "FIX-04 journal changes without on-screen info raise no HUD update, so no checkpoint: " + restoreCalls + " call(s)");
}
