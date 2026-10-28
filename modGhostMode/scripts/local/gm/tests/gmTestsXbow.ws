// XBOW tests (docs/features/xbow.md): the bolts' data (XBOW-01), selling bolts (XBOW-03), real bolt
// shots at a test dummy (quick shots through the combat action, as the throw button does; aimed shots
// read the real key and cannot be scripted, SKL-06).

// XBOW-01: one bolt's values as the game reads them: damage by type, armor piercing, the effect, its
// chance and tooltip chance, no duration of its own.
function GMTestXbowValue(abl : name, attr : name) : float
{
	var min, max : SAbilityAttributeValue;

	theGame.GetDefinitionsManager().GetAbilityAttributeValue(abl, attr, min, max);
	return min.valueAdditive + min.valueBase;
}

function GMTestXbowHas(list : array<name>, n : name) : bool
{
	return list.Contains(n);
}

function GMTestXbowBolt(abl : name, dmgType : name, dmg : float, silver : float, fire : float, pierce : float,
	effect : name, chance : float, descAttr : name)
{
	var dm : CDefinitionsManagerAccessor;
	var attrs, subs : array<name>;
	var ok : bool;
	var d, s, f, p, pp, c, dc : float;

	dm = theGame.GetDefinitionsManager();
	dm.GetAbilityAttributes(abl, attrs);
	dm.GetContainedAbilities(abl, subs);
	d = GMTestXbowValue(abl, dmgType);
	s = GMTestXbowValue(abl, 'SilverDamage');
	f = GMTestXbowValue(abl, 'FireDamage');
	p = GMTestXbowValue(abl, 'armor_reduction');
	pp = GMTestXbowValue(abl, 'armor_reduction_perc');
	c = GMTestXbowValue(abl, 'buff_apply_chance');
	ok = d == dmg && s == silver && f == fire && p == pierce && (pierce > 0) == (pp == 1) && (pierce > 0 || pp == 0) && AbsF(c - chance) < 0.001 && !attrs.Contains('duration');
	if(IsNameValid(effect))
	{
		dc = GMTestXbowValue(abl, descAttr);
		ok = ok && subs.Contains(effect) && subs.Size() == 1 && AbsF(dc - chance) < 0.001;
	}
	else
		ok = ok && subs.Size() == 0;
	GMTestReport(ok, "XBOW-01 " + abl + ": " + dmgType + " " + NoTrailZeros(d) + ", silver " + NoTrailZeros(s) + ", fire " + NoTrailZeros(f)
		+ ", armor piercing " + NoTrailZeros(p) + "/" + NoTrailZeros(pp) + ", effect " + effect + " (" + subs.Size() + " contained) chance " + NoTrailZeros(c)
		+ " tooltip " + NoTrailZeros(dc) + ", own duration " + attrs.Contains('duration') + " (legacy: " + NoTrailZeros(dmg) + ", " + NoTrailZeros(silver) + ", "
		+ NoTrailZeros(fire) + ", " + NoTrailZeros(pierce) + ", " + effect + " " + NoTrailZeros(chance) + ")");
}

exec function gmtest_xbow01()
{
	GMTest_xbow01();
}

function GMTest_xbow01()
{
	GMTestXbowBolt('bodkin_bolt _Stats', 'PiercingDamage', 10, 40, 0, 0, '', 0, '');
	GMTestXbowBolt('harpoon_bolt _Stats', 'PiercingDamage', 10, 500, 0, 0, '', 0, '');
	GMTestXbowBolt('bait_bolt _Stats', 'PiercingDamage', 10, 40, 0, 0, '', 0, '');
	GMTestXbowBolt('tracking_bolt _Stats', 'PiercingDamage', 10, 40, 0, 0, 'BleedingTrackingEffect', 0.5, 'desc_bleedingchance_mult');
	GMTestXbowBolt('blunt_bolt _Stats', 'BludgeoningDamage', 10, 40, 0, 0, 'KnockdownEffect', 0.3, 'desc_knockdownchance_mult');
	GMTestXbowBolt('blunt_bolt_legendary _Stats', 'BludgeoningDamage', 60, 110, 0, 0, 'KnockdownEffect', 0.5, 'desc_knockdownchance_mult');
	GMTestXbowBolt('broadhead_bolt _Stats', 'PiercingDamage', 50, 90, 0, 0, 'BleedingEffect_BroadheadBolt', 0.3, 'desc_bleedingchance_mult');
	GMTestXbowBolt('broadhead_bolt_legendary _Stats', 'PiercingDamage', 90, 150, 0, 0, 'BleedingEffect_BroadheadBolt', 0.5, 'desc_bleedingchance_mult');
	GMTestXbowBolt('target_point_bolt _Stats', 'PiercingDamage', 30, 70, 0, 1000, '', 0, '');
	GMTestXbowBolt('target_point_bolt_legendary _Stats', 'PiercingDamage', 70, 120, 0, 1000, '', 0, '');
	GMTestXbowBolt('split_bolt _Stats', 'PiercingDamage', 70, 120, 0, 0, '', 0, '');
	GMTestXbowBolt('split_bolt_legendary _Stats', 'PiercingDamage', 100, 160, 0, 0, '', 0, '');
	GMTestXbowBolt('explosive_bolt _Stats', 'PiercingDamage', 60, 100, 40, 0, 'BurningEffect', 0.3, 'desc_burningchance_mult');
	GMTestXbowBolt('explosive_bolt_legendary _Stats', 'PiercingDamage', 70, 110, 60, 0, 'BurningEffect', 0.5, 'desc_burningchance_mult');
	GMTestReport(GMTestXbowValue('split_bolt _Stats', 'split_count') == 3 && GMTestXbowValue('split_bolt_legendary _Stats', 'split_count') == 3,
		"XBOW-01 split bolts: three bolts each (" + GMTestXbowValue('split_bolt _Stats', 'split_count') + ", " + GMTestXbowValue('split_bolt_legendary _Stats', 'split_count') + ")");
	GMTest_xbow03();
}

// XBOW-03: the twelve special bolts sell (no mod_nosale, a sale price above 0), the two infinite bolts
// and the Blood and Wine quest bolt do not (its misspelt mod_nosalem fixed).
function GMTestXbowSalePrice(item : name) : int
{
	var ids : array<SItemUniqueId>;
	var price : int;

	ids = thePlayer.inv.AddAnItem(item, 1, true, true, false);
	price = thePlayer.inv.GetInventoryItemPriceModified(thePlayer.inv.GetItem(ids[0]), true);
	thePlayer.inv.RemoveItem(ids[0], 1);
	return price;
}

function GMTest_xbow03()
{
	var dm : CDefinitionsManagerAccessor;
	var bolts : array<name>;
	var i, price : int;
	var sellable, ok : bool;

	dm = theGame.GetDefinitionsManager();
	bolts.PushBack('Bait Bolt');			bolts.PushBack('Tracking Bolt');
	bolts.PushBack('Blunt Bolt');			bolts.PushBack('Blunt Bolt Legendary');
	bolts.PushBack('Broadhead Bolt');		bolts.PushBack('Broadhead Bolt Legendary');
	bolts.PushBack('Target Point Bolt');	bolts.PushBack('Target Point Bolt Legendary');
	bolts.PushBack('Split Bolt');			bolts.PushBack('Split Bolt Legendary');
	bolts.PushBack('Explosive Bolt');		bolts.PushBack('Explosive Bolt Legendary');
	bolts.PushBack('Bodkin Bolt');			bolts.PushBack('Harpoon Bolt');
	bolts.PushBack('q704_vampire_lure_bolt');
	for(i = 0; i < bolts.Size(); i += 1)
	{
		sellable = i < 12;
		price = GMTestXbowSalePrice(bolts[i]);
		ok = dm.ItemHasTag(bolts[i], 'mod_nosale') != sellable && !dm.ItemHasTag(bolts[i], 'mod_nosalem') && (price > 0) == sellable;
		GMTestReport(ok, "XBOW-03 " + bolts[i] + ": mod_nosale " + dm.ItemHasTag(bolts[i], 'mod_nosale') + ", mod_nosalem " + dm.ItemHasTag(bolts[i], 'mod_nosalem')
			+ ", sale price " + price + " (sellable: " + sellable + ")");
	}
}

// ---------------------------------------------------------------------------------------------
// Real shots. gmtest_xbow_setup(bolt, kind, crossbow): (setlevel(30) first for bolts above Geralt's level) Crossbow 1 selected, 200 bolts of the
// kind equipped, a neutral dummy of `kind` 4 m ahead (stats set in gmtest_xbow_arm a call later).
// gmtest_xbow_prep(), then in a later call gmtest_xbow_shot(true), a moment later gmtest_xbow_shot(false): one quick shot, the dummy's effects
// removed and health and Geralt's stamina restored before it; every bolt hit is logged (bolt,
// headshot, raw damage, armor points, the hit stat's result, damage dealt, effects on the dummy) and
// counted per shot; gmtest_xbow_report() counts the last shot and sums them.

@addField(CR4Player)
var gmTestXbowShots : int;
@addField(CR4Player)
var gmTestXbowHits : int;
@addField(CR4Player)
var gmTestXbowHead : int;
@addField(CR4Player)
var gmTestXbowBleed : int;
@addField(CR4Player)
var gmTestXbowKnock : int;
@addField(CR4Player)
var gmTestXbowBurn : int;
@addField(CR4Player)
var gmTestXbowShotFlags : int;	// this shot: 1 hit, 2 bleeding, 4 knockdown, 8 burning
@addField(CR4Player)
var gmTestXbowDealt : float;	// sum of the dealt damage of body hits (no headshot)
@addField(CR4Player)
var gmTestXbowBodyHits : int;
@addField(CR4Player)
var gmTestXbowOn : bool;
@addField(CR4Player)
var gmTestXbowShotVictims : array<CNewNPC>;	// XBOW-05: the victims of this shot's hits, one entry per hit
@addField(CR4Player)
var gmTestXbowRepeats : int;				// hits on a victim this shot already hit
@addField(CR4Player)
var gmTestXbowDummyHits : array<int>;		// hits per test dummy (index as in gmTestDummies)

@addMethod(CR4Player)
function GMTestXbowReset()
{
	gmTestXbowShots = 0;
	gmTestXbowHits = 0;
	gmTestXbowHead = 0;
	gmTestXbowBleed = 0;
	gmTestXbowKnock = 0;
	gmTestXbowBurn = 0;
	gmTestXbowShotFlags = 0;
	gmTestXbowDealt = 0;
	gmTestXbowBodyHits = 0;
	gmTestXbowShotVictims.Clear();
	gmTestXbowRepeats = 0;
	gmTestXbowDummyHits.Clear();
}

@addMethod(CR4Player)
function GMTestXbowEndShot()
{
	if(gmTestXbowShotFlags & 1)
		gmTestXbowHits += 1;
	if(gmTestXbowShotFlags & 2)
		gmTestXbowBleed += 1;
	if(gmTestXbowShotFlags & 4)
		gmTestXbowKnock += 1;
	if(gmTestXbowShotFlags & 8)
		gmTestXbowBurn += 1;
	gmTestXbowShotFlags = 0;
	gmTestXbowShotVictims.Clear();
}

@addMethod(CR4Player)
function GMTestXbowHit(action : W3DamageAction)
{
	var npc : CNewNPC;
	var i : int;
	var raw, pts, res : string;
	var head : bool;
	var k : int;

	npc = (CNewNPC)action.victim;
	if(!npc)
		return;
	if(gmTestXbowShotVictims.Contains(npc))
		gmTestXbowRepeats += 1;
	gmTestXbowShotVictims.PushBack(npc);
	k = gmTestDummies.FindFirst(npc);
	if(k >= 0)
	{
		while(gmTestXbowDummyHits.Size() <= k)
			gmTestXbowDummyHits.PushBack(0);
		gmTestXbowDummyHits[k] += 1;
	}
	head = action.GetIsHeadShot();
	gmTestXbowShotFlags = gmTestXbowShotFlags | 1;
	if(npc.HasBuff(EET_Bleeding) || npc.HasBuff(EET_BleedingTracking))
		gmTestXbowShotFlags = gmTestXbowShotFlags | 2;
	if(npc.HasBuff(EET_Knockdown) || npc.HasBuff(EET_HeavyKnockdown))
		gmTestXbowShotFlags = gmTestXbowShotFlags | 4;
	if(npc.HasBuff(EET_Burning))
		gmTestXbowShotFlags = gmTestXbowShotFlags | 8;
	if(head)
		gmTestXbowHead += 1;
	else
	{
		gmTestXbowDealt += action.GetDamageDealt();
		gmTestXbowBodyHits += 1;
	}
	for(i = 0; i < gmTestDmgSteps.Size(); i += 1)
	{
		raw += " " + gmTestDmgSteps[i].dmgType + " " + NoTrailZeros(gmTestDmgSteps[i].rawIn);
		if(gmTestDmgSteps[i].hitsStat)
		{
			pts = NoTrailZeros(gmTestDmgSteps[i].pts);
			res = NoTrailZeros(gmTestDmgSteps[i].result) + " (attack power x" + NoTrailZeros(gmTestDmgSteps[i].mult) + ")";
		}
	}
	LogChannel('GMTest', "INFO XBOW hit " + (gmTestXbowShots + 1) + ": " + thePlayer.inv.GetItemName(((W3Action_Attack)action).GetWeaponId())
		+ ", headshot " + head + ", raw" + raw + ", armor points " + pts + ", result " + res + ", dealt " + NoTrailZeros(action.GetDamageDealt())
		+ ", effects bleeding " + ((gmTestXbowShotFlags & 2) > 0) + " knockdown " + ((gmTestXbowShotFlags & 4) > 0) + " burning " + ((gmTestXbowShotFlags & 8) > 0)
		+ "; dummy " + k + " at " + NoTrailZeros(VecDistance(((CEntity)action.causer).GetWorldPosition(), npc.GetWorldPosition())) + " m from the bolt"
		+ "; crit " + action.IsCriticalHit() + GMTestXbowHeldCrit());
	GMTestDmgReset();
}

@wrapMethod(W3PlayerWitcher)
function OnProcessActionPost(action : W3DamageAction)
{
	wrappedMethod(action);
	if(gmTestXbowOn && (W3BoltProjectile)action.causer && action.victim != this)
		GMTestXbowHit(action);
}

// Before a shot (pressed): the previous shot is counted, the dummy's effects removed, its health
// restored and it is put back in place; without, the throw released. Driven
// one exec call at a time: a timer pressing from inside the player fired only the first shot.
@addMethod(CR4Player)
function GMTestXbowShot(pressed : bool)
{
	var npc : CNewNPC;
	var i : int;

	if(!pressed)
	{
		SetupCombatAction(EBAT_ItemUse, BS_Released);
		return;
	}
	if(gmTestXbowOn)
	{
		GMTestXbowEndShot();
		gmTestXbowShots += 1;
	}
	else
	{
		GMTestXbowReset();
		gmTestXbowOn = true;
		GMTestSetProbes(true);
	}
	for(i = 0; i < gmTestDummies.Size(); i += 1)
	{
		npc = gmTestDummies[i];
		if(npc)
		{
			npc.RemoveAllNonAutoBuffs();
			npc.SetHealthPerc(100);
			GMTestDummyFreeze(npc);
		}
	}
	GetWitcherPlayer().DrainFocus(GetStat(BCS_Focus));
	GMTestDmgReset();
}

// The press alone, as gmtest_skl06_throw: a press in the same call as the dummy's reset (teleported
// back in place) was often refused.
@addMethod(CR4Player)
function GMTestXbowPress()
{
	GainStat(BCS_Stamina, GetStatMax(BCS_Stamina));
	SetThrowHold(false);
	SetupCombatAction(EBAT_ItemUse, BS_Pressed);
}

// Counts the last shot and stops counting.
@addMethod(CR4Player)
function GMTestXbowStop()
{
	if(gmTestXbowOn)
	{
		GMTestXbowEndShot();
		gmTestXbowShots += 1;
	}
	gmTestXbowOn = false;
}

function GMTestXbowEquippedBolt() : SItemUniqueId
{
	var id : SItemUniqueId;

	GetWitcherPlayer().GetItemEquippedOnSlot(EES_Bolt, id);
	return id;
}

exec function gmtest_xbow_setup(bolt : name, kind : string, optional crossbow : name)
{
	var ids : array<SItemUniqueId>;
	var npc : CNewNPC;

	if(!IsNameValid(crossbow))
		crossbow = 'Crossbow 1';
	thePlayer.GMTestDummyClearAll();
	thePlayer.GMTestXbowStop();
	ids = thePlayer.inv.GetItemsByName(bolt);
	if(ids.Size() == 0 || thePlayer.inv.GetItemQuantity(ids[0]) < 100)
		ids = thePlayer.inv.AddAnItem(bolt, 200);
	GetWitcherPlayer().EquipItem(ids[0], EES_Bolt);
	GMTestSelectItem(crossbow, EES_RangedWeapon);
	npc = GMTestDummySpawn(kind, 1, 4);
	LogChannel('GMTest', "INFO XBOW setup: Geralt level " + thePlayer.GetLevel() + ", bolt " + thePlayer.inv.GetItemName(GMTestXbowEquippedBolt())
		+ " (" + thePlayer.inv.GetItemQuantity(GMTestXbowEquippedBolt()) + "), crossbow " + thePlayer.inv.GetItemName(thePlayer.GetSelectedItemId()) + ", dummy " + kind + " " + (bool)npc);
}

// The dummy's stats a call after the spawn: neutral, then the armor asked for.
exec function gmtest_xbow_arm(armor : float)
{
	var npc : CNewNPC;
	var ok : bool;

	npc = GMTestDummy();
	ok = npc && GMTestDummyNeutral(npc);
	if(ok && armor > 0)
		ok = GMTestDummySet(npc, 'armor', armor);
	GMTestReport(ok, "XBOW dummy neutral, armor " + NoTrailZeros(armor));
}

exec function gmtest_xbow_shot(pressed : bool)
{
	if(pressed)
	{
		GMTestXbowSwap();
		thePlayer.GMTestXbowPress();
	}
	else
		thePlayer.GMTestXbowShot(false);
}

// Before each shot, in a call of its own: counts the previous shot, resets the dummy and Geralt.
exec function gmtest_xbow_prep()
{
	thePlayer.GMTestXbowShot(true);
}

// Before each press: equip another copy of the same crossbow (added if missing). With the same crossbow
// held, presses after the first shot often fired nothing (its entity went to State_WeaponHolster, cause
// not found); a crossbow just equipped always fired.
function GMTestXbowSwap()
{
	var ids : array<SItemUniqueId>;
	var cur : SItemUniqueId;
	var i : int;

	cur = GMTestXbowRanged();
	ids = thePlayer.inv.GetItemsByName(thePlayer.inv.GetItemName(cur));
	if(ids.Size() < 2)
		ids = thePlayer.inv.AddAnItem(thePlayer.inv.GetItemName(cur), 1);
	for(i = 0; i < ids.Size(); i += 1)
		if(ids[i] != cur)
		{
			GetWitcherPlayer().EquipItemInGivenSlot(ids[i], EES_RangedWeapon, false);
			break;
		}
	GetWitcherPlayer().SelectQuickslotItem(EES_RangedWeapon);
}

function GMTestXbowRanged() : SItemUniqueId
{
	var id : SItemUniqueId;

	GetWitcherPlayer().GetItemEquippedOnSlot(EES_RangedWeapon, id);
	return id;
}

exec function gmtest_xbow_report()
{
	var p : CR4Player;

	p = thePlayer;
	p.GMTestXbowStop();
	LogChannel('GMTest', "INFO XBOW volley: " + p.gmTestXbowShots + " shots, " + p.gmTestXbowHits + " hit, " + p.gmTestXbowHead + " headshot hits; bleeding "
		+ p.gmTestXbowBleed + ", knockdown " + p.gmTestXbowKnock + ", burning " + p.gmTestXbowBurn + " shots; body hits " + p.gmTestXbowBodyHits
		+ ", mean damage dealt " + NoTrailZeros(p.gmTestXbowDealt / Max(1, p.gmTestXbowBodyHits)));
	GMTestXbowReportDummies();
}

// XBOW-04, XBOW-05: hits per dummy and repeated hits (a victim hit again by the same shot).
function GMTestXbowReportDummies()
{
	var p : CR4Player;
	var line : string;
	var i : int;

	p = thePlayer;
	for(i = 0; i < p.gmTestDummies.Size(); i += 1)
	{
		line += " dummy " + i;
		if(p.gmTestDummies[i])
			line += " (" + NoTrailZeros(VecDistance(p.gmTestDummies[i].GetWorldPosition(), p.gmTestDummies[0].GetWorldPosition())) + " m from dummy 0)";
		if(i < p.gmTestXbowDummyHits.Size())
			line += " " + p.gmTestXbowDummyHits[i];
		else
			line += " 0";
		line += " hits;";
	}
	LogChannel('GMTest', "INFO XBOW per dummy:" + line + " repeated hits on a victim within one shot " + p.gmTestXbowRepeats);
}

// XBOW-03 in a real shop: sells one of Geralt's `item` to the open shop through the menu's own event
// (what the sell click calls); open it with gmtest_shopopen(tag) first.
exec function gmtest_xbow_sell(tag : name, item : name)
{
	var menu : CR4InventoryMenu;
	var npc : CNewNPC;
	var ids : array<SItemUniqueId>;
	var inv : CInventoryComponent;
	var before, money, stock, price : int;

	menu = (CR4InventoryMenu)GMTestPlayMenu();
	npc = theGame.GetNPCByTag(tag);
	inv = thePlayer.GetInventory();
	ids = inv.GetItemsByName(item);
	if(!menu || !npc || ids.Size() == 0)
	{
		LogChannel('GMTest', "FAIL XBOW-03 sell: no shop menu, no NPC " + tag + " or no " + item);
		return;
	}
	before = inv.GetItemQuantityByName(item);
	money = inv.GetMoney();
	stock = npc.GetInventory().GetItemQuantityByName(item);
	price = npc.GetInventory().GetInventoryItemPriceModified(inv.GetItem(ids[0]), true);
	menu.OnSellItem(ids[0], 1);
	GMTestReport(inv.GetItemQuantityByName(item) == before - 1 && inv.GetMoney() == money + price && npc.GetInventory().GetItemQuantityByName(item) == stock + 1,
		"XBOW-03 sold " + item + " to " + tag + " for " + price + ": Geralt " + before + " -> " + inv.GetItemQuantityByName(item) + ", crowns " + money + " -> " + inv.GetMoney()
		+ ", merchant's stock " + stock + " -> " + npc.GetInventory().GetItemQuantityByName(item));
}

// ---------------------------------------------------------------------------------------------
// XBOW-02: a crossbow ability as the game reads it: attack power (min-max), armor piercing (min-max),
// crit damage, adrenaline, and no other attribute than these, quality, ammo and weight (1.32's
// experience bonuses and crit chance gone); its item's level (ITEM-01, from the attack power).
function GMTestXbowCrossbow(item : name, abl : name, apMin, apMax, arMin, arMax, crit, focus : float, level : int)
{
	var dm : CDefinitionsManagerAccessor;
	var attrs : array<name>;
	var min, max : SAbilityAttributeValue;
	var i, lvl : int;
	var ok : bool;
	var extra : string;
	var c, f : float;

	dm = theGame.GetDefinitionsManager();
	dm.GetAbilityAttributeValue(abl, 'attack_power', min, max);
	ok = AbsF(min.valueMultiplicative - apMin) < 0.001 && AbsF(max.valueMultiplicative - apMax) < 0.001;
	extra = "attack power x" + NoTrailZeros(min.valueMultiplicative) + "-" + NoTrailZeros(max.valueMultiplicative);
	dm.GetAbilityAttributeValue(abl, 'armor_reduction', min, max);
	ok = ok && AbsF(min.valueBase - arMin) < 0.001 && AbsF(max.valueBase - arMax) < 0.001;
	extra += ", armor piercing " + NoTrailZeros(min.valueBase) + "-" + NoTrailZeros(max.valueBase);
	c = GMTestXbowValue(abl, 'critical_hit_damage_bonus');
	f = GMTestXbowValue(abl, 'focus_gain');
	ok = ok && AbsF(c - crit) < 0.001 && AbsF(f - focus) < 0.001;
	dm.GetAbilityAttributes(abl, attrs);
	for(i = 0; i < attrs.Size(); i += 1)
		if(attrs[i] != 'attack_power' && attrs[i] != 'armor_reduction' && attrs[i] != 'critical_hit_damage_bonus' && attrs[i] != 'focus_gain'
			&& attrs[i] != 'quality' && attrs[i] != 'ammo' && attrs[i] != 'weight')
		{
			ok = false;
			extra += ", other " + attrs[i];
		}
	if(IsNameValid(item))
	{
		lvl = dm.GetItemLevelFromName(item);
		ok = ok && lvl == level;
		extra += "; " + item + " level " + lvl;
	}
	GMTestReport(ok, "XBOW-02 " + abl + ": " + extra + ", crit damage +" + NoTrailZeros(c) + ", adrenaline +" + NoTrailZeros(f)
		+ " (legacy: x" + NoTrailZeros(apMin) + "-" + NoTrailZeros(apMax) + ", " + NoTrailZeros(arMin) + "-" + NoTrailZeros(arMax) + ", +" + NoTrailZeros(crit) + ", +" + NoTrailZeros(focus) + ", level " + level + ")");
}

// The two Blood and Wine quest crossbows carry Toussaint Crossbow 1's ability (a new copy).
function GMTestXbowQuestCrossbow(item : name)
{
	var ids : array<SItemUniqueId>;
	var abls : array<name>;
	var ap, ar : SAbilityAttributeValue;
	var level : int;

	ids = thePlayer.inv.AddAnItem(item, 1, true, true, false);
	thePlayer.inv.GetItemAbilities(ids[0], abls);
	ap = thePlayer.inv.GetItemAttributeValue(ids[0], 'attack_power');
	ar = thePlayer.inv.GetItemAttributeValue(ids[0], 'armor_reduction');
	level = thePlayer.inv.GetItemLevel(ids[0]);
	thePlayer.inv.RemoveItem(ids[0], 1);
	GMTestReport(abls.Contains('Toussaint Crossbow 1 _Stats') && !abls.Contains('Toussaint Crossbow 2 _Stats') && AbsF(ap.valueMultiplicative - 2.1) < 0.001 && ar.valueBase >= 170 && ar.valueBase <= 190 && level == 34,
		"XBOW-02 " + item + " (a new copy): Toussaint Crossbow 1 " + abls.Contains('Toussaint Crossbow 1 _Stats') + ", 2 " + abls.Contains('Toussaint Crossbow 2 _Stats')
		+ ", attack power x" + NoTrailZeros(ap.valueMultiplicative) + ", armor piercing " + NoTrailZeros(ar.valueBase) + ", level " + level + " (legacy: Toussaint Crossbow 1's, x2.1, 170-190, level 34)");
}

exec function gmtest_xbow02()
{
	GMTest_xbow02();
}

function GMTest_xbow02()
{
	GMTestXbowCrossbow('Crossbow 1', 'Crossbow 1 _Stats', 1.01, 1.01, 0, 0, 0, 0, 1);
	GMTestXbowCrossbow('', 'Crossbow 1 q1 _Stats', 1.03, 1.1, 5, 10, 0, 0, 0);
	GMTestXbowCrossbow('Crossbow 2', 'Crossbow 2 _Stats', 1.13, 1.2, 15, 50, 0, 0, 4);
	GMTestXbowCrossbow('Crossbow 3', 'Crossbow 3 _Stats', 1.33, 1.4, 50, 70, 0, 0, 11);
	GMTestXbowCrossbow('Crossbow 4', 'Crossbow 4 _Stats', 1.43, 1.5, 70, 90, 0, 0, 15);
	GMTestXbowCrossbow('Crossbow q206', 'Crossbow q206 _Stats', 1.5, 1.5, 70, 70, 0.25, 0.02, 15);
	GMTestXbowCrossbow('Crossbow 5', 'Crossbow 5 _Stats', 1.53, 1.6, 90, 105, 0, 0, 19);
	GMTestXbowCrossbow('Crossbow 6', 'Crossbow 6 _Stats', 1.65, 1.65, 105, 120, 0, 0.02, 22);
	GMTestXbowCrossbow('Crossbow 7', 'Crossbow 7 _Stats', 1.75, 1.75, 120, 130, 0.5, 0.02, 25);
	GMTestXbowCrossbow('Lynx School Crossbow', 'Lynx School Crossbow _Stats', 1.85, 1.85, 140, 140, 0.5, 0.02, 27);
	GMTestXbowCrossbow('Bear School Crossbow', 'Bear School Crossbow _Stats', 2.0, 2.0, 160, 160, 0.75, 0.02, 32);
	GMTestXbowCrossbow('Toussaint Crossbow 1', 'Toussaint Crossbow 1 _Stats', 2.1, 2.1, 170, 190, 0, 0, 34);
	GMTestXbowCrossbow('Toussaint Crossbow 2', 'Toussaint Crossbow 2 _Stats', 2.2, 2.2, 200, 250, 0, 0.02, 38);
	GMTestXbowCrossbow('Ravix of Fourhorn Crossbow', 'Toussaint Crossbow 1 _Stats', 2.1, 2.1, 170, 190, 0, 0, 34);
	GMTestXbowCrossbow('Geralt of Rivia Crossbow', 'Toussaint Crossbow 1 _Stats', 2.1, 2.1, 170, 190, 0, 0, 34);
	GMTestXbowCrossbow('DLC13 Nilfgaardian Crossbow', 'DLC13 Nilfgaardian Crossbow _Stats', 1.25, 1.25, 60, 60, 0, 0, 8);
	GMTestXbowCrossbow('DLC13 Skellige Crossbow', 'DLC13 Skellige Crossbow _Stats', 1.45, 1.45, 80, 80, 0, 0, 15);
	GMTestXbowCrossbow('DLC13 Elven Crossbow', 'DLC13 Elven Crossbow _Stats', 1.65, 1.65, 110, 110, 0, 0, 22);
	GMTestXbowCrossbow('Ofir Crossbow', 'Ofir Crossbow _Stats', 2.0, 2.0, 130, 155, 0, 0, 32);
	GMTestXbowCrossbow('Ofir Crossbow R', 'Ofir Crossbow R _Stats', 2.1, 2.1, 170, 170, 0.75, 0, 34);
	GMTestXbowQuestCrossbow('Ravix of Fourhorn Crossbow');
	GMTestXbowQuestCrossbow('Geralt of Rivia Crossbow');
}

// Save impact (XBOW-02): every crossbow Geralt holds, with its abilities, attack power and armor
// piercing as the item has them (for a save made before the change).
exec function gmtest_xbow_held()
{
	var ids : array<SItemUniqueId>;
	var abls : array<name>;
	var ap, ar : SAbilityAttributeValue;
	var i, j : int;
	var line : string;

	ids = thePlayer.inv.GetItemsByCategory('crossbow');
	for(i = 0; i < ids.Size(); i += 1)
	{
		abls.Clear();
		thePlayer.inv.GetItemAbilities(ids[i], abls);
		ap = thePlayer.inv.GetItemAttributeValue(ids[i], 'attack_power');
		ar = thePlayer.inv.GetItemAttributeValue(ids[i], 'armor_reduction');
		line = "";
		for(j = 0; j < abls.Size(); j += 1)
			line += " " + abls[j];
		LogChannel('GMTest', "INFO XBOW-02 held " + thePlayer.inv.GetItemName(ids[i]) + ": attack power x" + NoTrailZeros(ap.valueMultiplicative)
			+ ", armor piercing " + NoTrailZeros(ar.valueBase) + ", level " + thePlayer.inv.GetItemLevel(ids[i]) + ", abilities" + line);
	}
}

// EFX-01's open check: the bleeding a real bolt left on the test dummy (type, ability, duration, time
// left, value).
exec function gmtest_xbow_bleed()
{
	var npc : CNewNPC;
	var buffs : array<CBaseGameplayEffect>;
	var value : SAbilityAttributeValue;
	var i : int;

	npc = GMTestDummy();
	if(!npc)
		return;
	buffs = npc.GetBuffs();
	for(i = 0; i < buffs.Size(); i += 1)
		if(buffs[i].GetEffectType() == EET_Bleeding || buffs[i].GetEffectType() == EET_BleedingTracking)
		{
			value = buffs[i].GetEffectValue();
			LogChannel('GMTest', "INFO XBOW bleeding on the dummy: " + buffs[i].GetEffectType() + " " + buffs[i].GetAbilityName() + ", duration " + NoTrailZeros(buffs[i].GetDurationLeft() + buffs[i].GetTimeActive())
				+ ", left " + NoTrailZeros(buffs[i].GetDurationLeft()) + ", value " + NoTrailZeros(value.valueMultiplicative) + " of max health per s + " + NoTrailZeros(value.valueAdditive)
				+ "; dummy health " + NoTrailZeros(npc.GetStat(BCS_Vitality)) + "/" + NoTrailZeros(npc.GetStatMax(BCS_Vitality)));
		}
}

// Why a press does not shoot: Geralt's combat action and throw flags; with reset, they are cleared.
exec function gmtest_xbow_state(optional reset : bool)
{
	var p : CR4Player;

	p = thePlayer;
	LogChannel('GMTest', "INFO XBOW state " + p.GetCurrentStateName() + ": combat action allowed " + p.GetBIsCombatActionAllowed() + ", throwing " + p.IsThrowingItem()
		+ ", aiming " + p.IsThrowingItemWithAim() + ", selected " + p.inv.GetItemName(p.GetSelectedItemId()) + ", crossbow allowed " + p.IsActionAllowed(EIAB_Crossbow)
		+ ", throw allowed " + p.IsActionAllowed(EIAB_ThrowBomb) + ", in combat action " + p.IsInCombatAction()
		+ ", crossbow entity state " + ((Crossbow)p.inv.GetItemEntityUnsafe(p.GetSelectedItemId())).GetCurrentStateName());
	if(reset)
	{
		p.CleanCombatActionBuffer();
		p.SetBIsCombatActionAllowed(true);
		p.SetIsThrowingItem(false);
	}
}

// XBOW-04, XBOW-05: another frozen dummy of `kind`, `forward` m ahead of Geralt and `side` m to his right
// (negative: left); its stats are set with gmtest_xbow_arm_all a call later. The first dummy
// (gmtest_xbow_setup) stays the one locked on and reset first.
exec function gmtest_xbow_spawnat(kind : string, forward : float, side : float)
{
	var template : CEntityTemplate;
	var npc : CNewNPC;
	var pos, right : Vector;

	template = (CEntityTemplate)LoadResource(GMTestDummyTemplate(kind), true);
	right = VecCross(thePlayer.GetHeadingVector(), Vector(0, 0, 1));
	pos = thePlayer.GetWorldPosition() + thePlayer.GetHeadingVector() * forward + VecNormalize(right) * side;
	npc = (CNewNPC)theGame.CreateEntity(template, pos, VecToRotation(thePlayer.GetWorldPosition() - pos));
	if(!npc)
	{
		LogChannel('GMTest', "FAIL XBOW spawnat: no NPC");
		return;
	}
	npc.SetTemporaryAttitudeGroup('hostile_to_player', AGP_Default);
	npc.SetLevel(1);
	thePlayer.GMTestDummyAdd(npc, pos);
	GMTestDummyFreeze(npc);
	LogChannel('GMTest', "INFO XBOW spawnat: dummy " + (thePlayer.gmTestDummies.Size() - 1) + " " + kind + " at " + NoTrailZeros(VecDistance(pos, thePlayer.gmTestDummies[0].GetWorldPosition())) + " m from dummy 0");
}

// Every dummy neutral (armor 0, 100000 health), a call after the spawns.
exec function gmtest_xbow_arm_all()
{
	var i : int;
	var ok : bool;

	ok = true;
	for(i = 0; i < thePlayer.gmTestDummies.Size(); i += 1)
		ok = ok && thePlayer.gmTestDummies[i] && GMTestDummyNeutral(thePlayer.gmTestDummies[i]);
	GMTestReport(ok, "XBOW " + thePlayer.gmTestDummies.Size() + " dummies neutral");
}

// XBOW-05: the equipped bolt's stack cut to `count` (the last bolt of a stack: 1).
exec function gmtest_xbow_stack(count : int)
{
	var id : SItemUniqueId;
	var n : int;

	id = GMTestXbowEquippedBolt();
	n = thePlayer.inv.GetItemQuantity(id);
	if(n > count)
		thePlayer.inv.RemoveItem(id, n - count);
	id = GMTestXbowEquippedBolt();
	LogChannel('GMTest', "INFO XBOW stack: " + thePlayer.inv.GetItemName(id) + " x" + thePlayer.inv.GetItemQuantity(id));
}

// XBOW-05: every stack of `bolt` Geralt holds, with the equipped bolt.
exec function gmtest_xbow_count(bolt : name)
{
	GMTestXbowCount(bolt);
}

function GMTestXbowCount(bolt : name)
{
	var ids : array<SItemUniqueId>;
	var line : string;
	var i : int;

	ids = thePlayer.inv.GetItemsByName(bolt);
	for(i = 0; i < ids.Size(); i += 1)
		line += " " + thePlayer.inv.GetItemQuantity(ids[i]);
	LogChannel('GMTest', "INFO XBOW count " + bolt + ": " + thePlayer.inv.GetItemQuantityByName(bolt) + " in " + ids.Size() + " stacks (" + line + " ), equipped "
		+ thePlayer.inv.GetItemName(GMTestXbowEquippedBolt()) + " x" + thePlayer.inv.GetItemQuantity(GMTestXbowEquippedBolt()));
}

// XBOW-05: all of `bolt` removed, then `count` added and equipped (one stack).
exec function gmtest_xbow_only(bolt : name, count : int)
{
	var ids : array<SItemUniqueId>;

	thePlayer.inv.RemoveItemByName(bolt, thePlayer.inv.GetItemQuantityByName(bolt));
	ids = thePlayer.inv.AddAnItem(bolt, count);
	GetWitcherPlayer().EquipItem(ids[0], EES_Bolt);
	GMTestXbowCount(bolt);
}

// XBOW-04: the explosive bolt's blast as its entity has it (spawned far below Geralt, read, removed);
// XBOW-05: a bolt carries its item's name for the hit.
exec function gmtest_xbow04()
{
	GMTest_xbow04();
}

function GMTest_xbow04()
{
	var template : CEntityTemplate;
	var bolt : W3ExplosiveBolt;

	template = (CEntityTemplate)LoadResource("items\weapons\projectiles\witcher_bolts\explosive_bolt.w2ent", true);
	if(template)
		bolt = (W3ExplosiveBolt)theGame.CreateEntity(template, thePlayer.GetWorldPosition() - Vector(0, 0, 50));
	GMTestReport(bolt && bolt.explosionRange == 3, "XBOW-04 explosive bolt's blast " + NoTrailZeros(bolt.explosionRange) + " m (legacy 3, 1.32 and 5.x 5)");
	if(bolt)
		bolt.Destroy();
	GMTestXbow05Throw();
}

@addMethod(W3BoltProjectile)
function GMTestProjectiles() : array<W3BoltProjectile>
{
	return projectiles;
}

// XBOW-05: a Split bolt's projectile entity, made as the crossbow makes it (GetDeploymentItemEntity,
// InitializeCrossbow, as gmtest_xbow07_shoot), thrown through ThrowProjectile 50 m below Geralt: each
// of the shot's three projectiles carries the bolt's name (set by the wrapper; without it the name is
// empty). The projectiles are destroyed before the release timer fires (no shot flies, no bolt is
// used); the bolt added, the stamina the throw costs (STAM-03), its regen pause and the fired fact
// are put back.
function GMTestXbow05Throw()
{
	var p : CR4Player;
	var ids : array<SItemUniqueId>;
	var ent : W3BoltProjectile;
	var projs : array<W3BoltProjectile>;
	var stamina : float;
	var count, named, i : int;
	var hadFact, thrown : bool;
	var names : string;

	p = thePlayer;
	count = p.inv.GetItemQuantityByName('Split Bolt');
	stamina = p.GetStat(BCS_Stamina);
	hadFact = FactsDoesExist("crossbow_was_fired");
	ids = p.inv.AddAnItem('Split Bolt', 1, true, true);
	if(ids.Size() > 0)
		ent = (W3BoltProjectile)p.inv.GetDeploymentItemEntity(ids[0], p.GetWorldPosition() - Vector(0, 0, 50), p.GetWorldRotation());
	if(ent)
	{
		thrown = true;
		ent.InitializeCrossbow(p, ids[0], GMTestXbowRanged());
		ent.ThrowProjectile(p.GetWorldPosition() + p.GetHeadingVector() * 10 - Vector(0, 0, 50));
		projs = ent.GMTestProjectiles();
		for(i = 0; i < projs.Size(); i += 1)
		{
			if(projs[i])
			{
				names += " " + projs[i].gmBoltItemName;
				if(projs[i].gmBoltItemName == 'Split Bolt')
					named += 1;
			}
		}
		for(i = projs.Size() - 1; i >= 0; i -= 1)
			if(projs[i] && projs[i] != ent)
				projs[i].Destroy();
		ent.Destroy();
	}
	GMTestReport(thrown && projs.Size() == 3 && named == 3, "XBOW-05 a thrown Split bolt's " + projs.Size() + " projectiles carry its name:" + names + " (3 of 3)");
	if(p.inv.GetItemQuantityByName('Split Bolt') > count)
		p.inv.RemoveItemByName('Split Bolt', p.inv.GetItemQuantityByName('Split Bolt') - count);
	p.ResumeStaminaRegen(StaminaActionTypeToName(ESAT_UsableItem));
	p.ForceSetStat(BCS_Stamina, stamina);
	if(!hadFact)
		FactsRemove("crossbow_was_fired");
	LogChannel('GMTest', "INFO XBOW-05 throw put back: Split bolts " + p.inv.GetItemQuantityByName('Split Bolt') + " (" + count + "), stamina "
		+ NoTrailZeros(p.GetStat(BCS_Stamina)) + " (" + NoTrailZeros(stamina) + "), fired fact " + FactsDoesExist("crossbow_was_fired") + " (" + hadFact + ")");
}

// XBOW-06: the held weapons with their crit damage and chance (a bolt hit's log line).
function GMTestXbowHeldCrit() : string
{
	var weapons : array<SItemUniqueId>;
	var line : string;
	var i : int;

	weapons = thePlayer.inv.GetHeldWeapons();
	for(i = 0; i < weapons.Size(); i += 1)
		line += " " + thePlayer.inv.GetItemName(weapons[i]) + " (crit damage " + NoTrailZeros(CalculateAttributeValue(thePlayer.inv.GetItemAttributeValue(weapons[i], theGame.params.CRITICAL_HIT_DAMAGE_BONUS)))
			+ ", chance " + NoTrailZeros(CalculateAttributeValue(thePlayer.inv.GetItemAttributeValue(weapons[i], theGame.params.CRITICAL_HIT_CHANCE))) + ")";
	return ", held:" + line;
}

// XBOW-06: the first sword of the list with crit damage, added and equipped (Weeper is a silver sword); the crossbow selected.
exec function gmtest_xbow06_setup(crossbow : name)
{
	var swords : array<name>;
	var ids : array<SItemUniqueId>;
	var sword : SItemUniqueId;
	var i : int;
	var cd : float;

	swords.PushBack('Weeper');	swords.PushBack('Hanza steel sword 3');	swords.PushBack('Knights steel sword 3');
	swords.PushBack('Guard lvl1 steel sword 3');	swords.PushBack('Lynx School steel sword');	swords.PushBack('Gryphon School steel sword');
	for(i = 0; i < swords.Size(); i += 1)
	{
		ids = thePlayer.inv.GetItemsByName(swords[i]);
		if(ids.Size() == 0)
			ids = thePlayer.inv.AddAnItem(swords[i], 1);
		if(ids.Size() == 0)
			continue;
		cd = CalculateAttributeValue(thePlayer.inv.GetItemAttributeValue(ids[0], theGame.params.CRITICAL_HIT_DAMAGE_BONUS));
		if(cd > 0)
		{
			GetWitcherPlayer().EquipItem(ids[0]);
			sword = ids[0];
			break;
		}
	}
	GMTestSelectItem(crossbow, EES_RangedWeapon);
	ids = thePlayer.inv.GetItemsByName(crossbow);
	LogChannel('GMTest', "INFO XBOW-06 setup: sword " + thePlayer.inv.GetItemName(sword) + " crit damage " + NoTrailZeros(cd)
		+ ", crossbow " + crossbow + " crit damage " + NoTrailZeros(CalculateAttributeValue(thePlayer.inv.GetItemAttributeValue(ids[0], theGame.params.CRITICAL_HIT_DAMAGE_BONUS))));
}

// XBOW-06: the crit chance (bolt, light attack) and crit damage (equipped bolt, held sword) as the
// damage step asks them now; the held weapons; horse state and speed.
exec function gmtest_xbow06_read()
{
	var w : W3PlayerWitcher;
	var horse : CNewNPC;
	var speed : float;
	var sword : SItemUniqueId;

	w = GetWitcherPlayer();
	sword = w.inv.GetCurrentlyHeldSword();
	if(!w.inv.IsIdValid(sword))
		sword = w.GetEquippedSword(true);
	if(w.IsInState('HorseRiding'))
		speed = ((CActor)w.GetUsedVehicle()).GetMovingAgentComponent().GetRelativeMoveSpeed();
	LogChannel('GMTest', "INFO XBOW-06 state " + w.GetCurrentStateName() + ", horse speed " + NoTrailZeros(speed) + "; crit chance bolt " + NoTrailZeros(w.GetCriticalHitChance(false, false, NULL, MC_Human, true))
		+ ", light attack " + NoTrailZeros(w.GetCriticalHitChance(true, false, NULL, MC_Human, false)) + "; crit damage bolt " + NoTrailZeros(CalculateAttributeValue(w.GetCriticalHitDamageBonus(GMTestXbowEquippedBolt(), MC_Human, false)))
		+ ", sword " + NoTrailZeros(CalculateAttributeValue(w.GetCriticalHitDamageBonus(sword, MC_Human, false))) + ", Geralt's own " + NoTrailZeros(CalculateAttributeValue(w.GetAttributeValue(theGame.params.CRITICAL_HIT_DAMAGE_BONUS)))
		+ GMTestXbowHeldCrit());
}

// XBOW-06: the mounted horse's speed set as quests set it (4: gallop).
exec function gmtest_xbow06_gallop(speed : float)
{
	var horse : CNewNPC;

	horse = thePlayer.GetHorseWithInventory();
	if(horse)
		horse.GetHorseComponent().QuestSetRiderSpeed(speed);
	LogChannel('GMTest', "INFO XBOW-06 horse speed set " + NoTrailZeros(speed) + " " + (bool)horse);
}

// XBOW-06: a sword drawn (1 steel, 2 silver) or sheathed (0).
exec function gmtest_xbow06_draw(kind : int)
{
	if(kind == 1)
		thePlayer.OnEquipMeleeWeapon(PW_Steel, true);
	else if(kind == 2)
		thePlayer.OnEquipMeleeWeapon(PW_Silver, true);
	else
		thePlayer.OnEquipMeleeWeapon(PW_None, true);
}

// DB1 (XBOW-07): the ragdoll bones of NPC templates, the bone names a bolt or arrow hit reports
// (W3ArrowProjectile.OnProjectileCollision: GetRagdollBoneName of the ragdoll actor hit).
// gmtest_xbow_rig_spawn(path) spawns a frozen, neutral NPC of the template on a circle 10 m around
// Geralt; gmtest_xbow_rig_read() logs each one's template, human flag and ragdoll bones, then removes them.
@addField(CR4Player)
var gmTestRigs : array<CNewNPC>;
@addField(CR4Player)
var gmTestRigPaths : array<string>;

@addMethod(CR4Player)
function GMTestRigAdd(npc : CNewNPC, path : string)
{
	gmTestRigs.PushBack(npc);
	gmTestRigPaths.PushBack(path);
}

@addMethod(CR4Player)
function GMTestRigClear()
{
	var i : int;

	for(i = 0; i < gmTestRigs.Size(); i += 1)
		if(gmTestRigs[i])
			gmTestRigs[i].Destroy();
	gmTestRigs.Clear();
	gmTestRigPaths.Clear();
}

exec function gmtest_xbow_rig_spawn(path : string)
{
	var template : CEntityTemplate;
	var npc : CNewNPC;
	var pos : Vector;
	var a : float;

	template = (CEntityTemplate)LoadResource(path, true);
	if(!template)
	{
		LogChannel('GMTest', "INFO DB1 rig " + path + ": no template");
		return;
	}
	a = thePlayer.gmTestRigs.Size() * 0.7;
	pos = thePlayer.GetWorldPosition() + Vector(10 * CosF(a), 10 * SinF(a), 0);
	npc = (CNewNPC)theGame.CreateEntity(template, pos, VecToRotation(thePlayer.GetWorldPosition() - pos));
	if(!npc)
	{
		LogChannel('GMTest', "INFO DB1 rig " + path + ": not an NPC");
		return;
	}
	npc.SetTemporaryAttitudeGroup('neutral_to_player', AGP_Default);
	npc.SetAnimationSpeedMultiplier(0.001);
	thePlayer.GMTestRigAdd(npc, path);
}

exec function gmtest_xbow_rig_read()
{
	var p : CR4Player;
	var mac : CMovingPhysicalAgentComponent;
	var bone : name;
	var line : string;
	var i, k : int;

	p = thePlayer;
	for(i = 0; i < p.gmTestRigs.Size(); i += 1)
	{
		line = "";
		if(p.gmTestRigs[i])
		{
			mac = (CMovingPhysicalAgentComponent)p.gmTestRigs[i].GetMovingAgentComponent();
			for(k = 0; mac && k < 80; k += 1)
			{
				bone = mac.GetRagdollBoneName(k);
				if(!IsNameValid(bone))
					break;
				line += " " + bone;
			}
			LogChannel('GMTest', "INFO DB1 rig " + p.gmTestRigPaths[i] + " | " + p.gmTestRigs[i].GetDisplayName(false) + " | human " + p.gmTestRigs[i].IsHuman()
				+ " | bones" + line);
		}
	}
	p.GMTestRigClear();
}
