// In-game tests for ENCH (runewords, glyphwords, runes and glyphs). See docs/features/ench.md.

// Enchants the item in the slot with a word as the enchanter would ('Runeword 2', ...; empty removes
// the enchantment). The game refuses items with fewer than three slots: slots are added up to three
// first (they stay; tests run on the unsaved test save).
function GMTestEnchant(slot : EEquipmentSlots, word : name) : bool
{
	var id : SItemUniqueId;
	var inv : CInventoryComponent;
	var i : int;

	inv = thePlayer.inv;
	if(!GetWitcherPlayer().GetItemEquippedOnSlot(slot, id))
		return false;
	inv.UnenchantItem(id);
	if(!IsNameValid(word))
		return !inv.IsItemEnchanted(id);
	for(i = inv.GetItemEnhancementSlotsCount(id); i < 3; i += 1)
		inv.AddSlot(id);
	return inv.EnchantItem(id, word, getEnchamtmentStatName(word)) && inv.IsItemEnchanted(id);
}

function GMTestEnchHeld(slot : EEquipmentSlots) : bool
{
	var id : SItemUniqueId;

	return GetWitcherPlayer().GetItemEquippedOnSlot(slot, id) && GetWitcherPlayer().IsItemHeld(id);
}

// ENCH's situation-free checks (in gmtest_regress()).
function GMTest_ench()
{
	GMTest_ench01();
	GMTest_ench10();
	GMTest_ench16();
	GMTest_ench12_15();
	GMTest_ench13();
	GMTest_ench14();
	GMTest_ench03_04();
	GMTest_ench05();
	GMTest_ench07_08();
	GMTest_ench09();
	GMTest_ench06();
	GMTest_ench02();
	GMTest_ench17();
}

// ENCH-01, situation-free: the words given whole keep their tags; a runeword on a sheathed sword is
// inactive (Preservation works from an equipped one); a glyphword works from the chest armor only.
// Enchants the equipped silver sword, steel sword and armor and removes the enchantments afterwards.
function GMTest_ench01()
{
	var w : W3PlayerWitcher;
	var dm : CDefinitionsManagerAccessor;
	var ok : bool;

	w = GetWitcherPlayer();
	dm = theGame.GetDefinitionsManager();
	GMTestReport(dm.AbilityHasTag('Runeword 5 _Stats', 'Runeword') && dm.AbilityHasTag('Glyphword 1 _Stats', 'Glyphword'), "ENCH-01: the words given whole keep their tags (Runeword 5 Runeword, Glyphword 1 Glyphword)");

	ok = GMTestEnchant(EES_SteelSword, 'Runeword 2') && GMTestEnchant(EES_SilverSword, 'Runeword 5') && GMTestEnchant(EES_Armor, 'Glyphword 1');
	GMTestReport(ok, "ENCH-01: steel sword, silver sword and armor enchanted by script");
	if(!GMTestEnchHeld(EES_SteelSword))
		GMTestReport(!w.HasRunewordActive('Runeword 2 _Stats'), "ENCH-01: Severance on the sheathed steel sword inactive");
	GMTestReport(w.HasRunewordActive('Runeword 5 _Stats'), "ENCH-01: Preservation active from the equipped silver sword (drawn " + GMTestEnchHeld(EES_SilverSword) + ")");
	GMTestReport(w.HasGlyphwordActive('Glyphword 1 _Stats') && !w.HasGlyphwordActive('Glyphword 2 _Stats'), "ENCH-01: Deflection active from the chest armor, Levity not (not on it)");
	GMTestEnchant(EES_SteelSword, '');
	GMTestEnchant(EES_SilverSword, '');
	GMTestEnchant(EES_Armor, '');
	GMTestReport(!w.HasRunewordActive('Runeword 5 _Stats') && !w.HasGlyphwordActive('Glyphword 1 _Stats'), "ENCH-01: enchantments removed, words inactive");
}

// ENCH-01 in play, two calls: (a) enchants the steel sword with Severance, the silver sword with
// Dumplings, and draws the steel sword; (b) a moment later: Severance active while drawn, Dumplings
// active from the sheathed silver sword; sheathes the sword. (c) Severance inactive again; removes the
// enchantments. Give each call --wait 3000 (drawing takes a moment).
exec function gmtest_ench01_a()
{
	GMTestEnchant(EES_SteelSword, 'Runeword 2');
	GMTestEnchant(EES_SilverSword, 'Runeword 6');
	thePlayer.OnEquipMeleeWeapon(PW_Steel, true);
	LogChannel('GMTest', "INFO ENCH-01: steel sword enchanted with Severance, silver with Dumplings; drawing the steel sword");
}

exec function gmtest_ench01_b()
{
	var w : W3PlayerWitcher;

	w = GetWitcherPlayer();
	GMTestReport(GMTestEnchHeld(EES_SteelSword) && w.HasRunewordActive('Runeword 2 _Stats'), "ENCH-01: Severance active from the drawn steel sword (held " + GMTestEnchHeld(EES_SteelSword) + ")");
	GMTestReport(!GMTestEnchHeld(EES_SilverSword) && w.HasRunewordActive('Runeword 6 _Stats'), "ENCH-01: Dumplings active from the sheathed silver sword");
	thePlayer.OnEquipMeleeWeapon(PW_None, true);
}

exec function gmtest_ench01_c()
{
	var w : W3PlayerWitcher;

	w = GetWitcherPlayer();
	GMTestReport(!GMTestEnchHeld(EES_SteelSword) && !w.HasRunewordActive('Runeword 2 _Stats'), "ENCH-01: Severance inactive once the steel sword is sheathed");
	GMTestEnchant(EES_SteelSword, '');
	GMTestEnchant(EES_SilverSword, '');
}

// The cost of a physical action, a sign by action and by skill, with the word on the chest armor.
function GMTestEnchCosts(out costs : array<float>)
{
	var w : W3PlayerWitcher;

	w = GetWitcherPlayer();
	costs.Clear();
	costs.PushBack(w.GetStaminaActionCost(ESAT_LightAttack, '', 0));
	costs.PushBack(w.GetStaminaActionCost(ESAT_Dodge, '', 0));
	costs.PushBack(w.GetStaminaActionCost(ESAT_UsableItem, '', 0));
	costs.PushBack(w.GetStaminaActionCost(ESAT_Sprint, '', 1));
	costs.PushBack(w.GetStaminaActionCost(ESAT_Ability, 'magic_1', 0));
	costs.PushBack(((W3PlayerAbilityManager)w.GetAbilityManager()).GetSkillStaminaUseCost(S_Magic_1));
}

function GMTestEnchRatios(word : string, base : array<float>, now : array<float>, melee : float, item : float, sign : float)
{
	GMTestReport(AbsF(now[0] / base[0] - melee) < 0.001 && AbsF(now[3] / base[3] - item) < 0.001, "ENCH-10 " + word + ": light attack x" + (now[0] / base[0]) + ", sprint x" + (now[3] / base[3]) + " (expected x" + melee + ", x" + item + ")");
	GMTestReport(AbsF(now[1] / base[1] - item) < 0.001 && AbsF(now[2] / base[2] - item) < 0.001, "ENCH-10 " + word + ": dodge x" + (now[1] / base[1]) + ", item use x" + (now[2] / base[2]) + " (expected x" + item + ")");
	GMTestReport(AbsF(now[4] / base[4] - sign) < 0.001 && AbsF(now[5] / base[5] - sign) < 0.001, "ENCH-10 " + word + ": Aard x" + (now[4] / base[4]) + " by action, x" + (now[5] / base[5]) + " by skill (expected x" + sign + ")");
}

// ENCH-10, situation-free: the values; Levity, Balance and Heft on the chest armor change the costs
// (scripted reads of the functions real actions pay through); Heft's damage bonus for a melee hit;
// a glyphword on Geralt but not on the chest armor does nothing (ENCH-01); the description values.
function GMTest_ench10()
{
	var w : W3PlayerWitcher;
	var base, now : array<float>;
	var action : W3Action_Attack;
	var ints : array<int>;
	var fl : array<float>;
	var strs : array<string>;

	w = GetWitcherPlayer();
	GMTestReport(GMTestArmNear(GMTestArmAbl('Glyphword 2 _Stats', 'glyphword2_mod'), 0.2) && GMTestArmNear(GMTestArmAbl('Glyphword 3 _Stats', 'glyphword3_mod'), 0.2) && GMTestArmNear(GMTestArmAbl('Glyphword 4 _Stats', 'glyphword4_mod'), 0.2), "ENCH-10: Levity, Balance, Heft 20% (legacy)");
	GMTestEnchant(EES_Armor, '');
	GMTestEnchCosts(base);
	GMTestEnchant(EES_Armor, 'Glyphword 2');
	GMTestEnchCosts(now);
	GMTestEnchRatios("Levity", base, now, 0.8, 0.8, 1.2);
	GMTestEnchant(EES_Armor, 'Glyphword 3');
	GMTestEnchCosts(now);
	GMTestEnchRatios("Balance", base, now, 1.2, 1.2, 0.8);
	GMTestEnchant(EES_Armor, 'Glyphword 4');
	GMTestEnchCosts(now);
	GMTestEnchRatios("Heft", base, now, 1.2, 1, 1);
	action = new W3Action_Attack in theGame.damageMgr;
	action.Init(thePlayer, thePlayer, NULL, GetInvalidUniqueId(), 'attack_light', thePlayer.GetName(), EHRT_Light, false, false, 'attack_light', AST_Jab, ASD_UpDown, true, false, false, false);
	GMTestReport(AbsF(GMHeftDamageBonus(action) - 0.2) < 0.001, "ENCH-10 Heft: melee hit damage pool term +" + GMHeftDamageBonus(action) + " (expected 0.2)");
	delete action;
	GMTestEnchant(EES_Armor, '');
	w.AddAbility('Glyphword 2 _Stats', false);
	GMTestEnchCosts(now);
	GMTestReport(AbsF(now[0] - base[0]) < 0.001 && AbsF(now[4] - base[4]) < 0.001, "ENCH-10: Levity's ability on Geralt, not on the chest armor: costs unchanged");
	w.RemoveAbility('Glyphword 2 _Stats');
	w.GetInventory().GetParamsForRunewordTooltip('Glyphword 3', ints, fl, strs);
	GMTestReport(ints.Size() == 2 && ints[0] == 20 && ints[1] == 20 && GetLocStringById(2110992337) != "" && StrFindFirst(GetLocStringById(2110992337), "physical") >= 0, "ENCH-10: Balance's description values " + ints[0] + "/" + ints[1] + " and text: " + GetLocStringById(2110992337));
}

// Test probe: the additive pool's sum (DMG-04) of the last hit, recorded while probes are on.
@addField(CR4Player)
public var gmTestPoolAll : float;

@addMethod(CR4Player)
function GMTestSetPool(v : float)
{
	gmTestPoolAll = v;
}

@wrapMethod(W3DamageManagerProcessor)
function GMPoolApply(out dmgInfos : array< SRawDamage >)
{
	if(GMTestProbes())
		thePlayer.GMTestSetPool(gmPoolAll);
	wrappedMethod(dmgInfos);
}

// ENCH-10 Heft's damage against the test dummy (gmtest_dummy("human") and gmtest_dummy_neutral() in
// earlier calls): a scripted slashing hit of 100 raw damage without and with Heft on the chest armor,
// read in the additive pool.
exec function gmtest_ench10_dmg()
{
	var npc : CNewNPC;
	var a, b : SGMTestDmgStep;
	var probes : bool;
	var poolA, poolB : float;

	npc = GMTestDummy();
	if(!npc)
	{
		GMTestReport(false, "ENCH-10 Heft damage: no test dummy");
		return;
	}
	probes = GMTestProbes();
	thePlayer.GMTestSetProbes(true);
	GMTestEnchant(EES_Armor, '');
	a = GMTestDmgNoCrit(npc, theGame.params.DAMAGE_NAME_SLASHING, 100, 0);
	poolA = thePlayer.gmTestPoolAll;
	GMTestEnchant(EES_Armor, 'Glyphword 4');
	b = GMTestDmgNoCrit(npc, theGame.params.DAMAGE_NAME_SLASHING, 100, 0);
	poolB = thePlayer.gmTestPoolAll;
	GMTestEnchant(EES_Armor, '');
	thePlayer.GMTestSetProbes(probes);
	GMTestReport(a.rawIn > 0 && b.rawIn > 0 && AbsF(poolB - poolA - 0.2) < 0.001, "ENCH-10 Heft: the hit's damage pool " + poolA + " -> " + poolB + " (expected +0.2; raw damage " + a.rawIn + ", " + b.rawIn + ", each with the attack's random part)");
}

// ENCH-16, situation-free: legacy's rune and glyph values (one sample per kind), Pierog and Tvarog no
// longer relics.
function GMTest_ench16()
{
	var min, max : SAbilityAttributeValue;
	var inv : CInventoryComponent;
	var ids : array<SItemUniqueId>;

	GMTestReport(GMTestArmNear(GMTestArmAbl('Rune perun lesser _Stats', 'focus_gain'), 0.03) && GMTestArmNear(GMTestArmAbl('Rune stribog _Stats', 'buff_apply_chance'), 0.04) && GMTestArmNear(GMTestArmAbl('Rune svarog _Stats', 'armor_reduction'), 15),
		"ENCH-16 runes: Perun lesser +" + GMTestArmAbl('Rune perun lesser _Stats', 'focus_gain') + " adrenaline gain, Stribog " + GMTestArmAbl('Rune stribog _Stats', 'buff_apply_chance') + ", Svarog " + GMTestArmAbl('Rune svarog _Stats', 'armor_reduction') + " (expected 0.03, 0.04, 15)");
	GMTestReport(GMTestArmNear(GMTestArmAbl('Rune pierog _Stats', 'vitalityRegen'), 5) && GMTestArmNear(GMTestArmAbl('Rune tvarog _Stats', 'vitalityCombatRegen'), 5),
		"ENCH-16 runes: Pierog +" + GMTestArmAbl('Rune pierog _Stats', 'vitalityRegen') + " regen out of combat, Tvarog +" + GMTestArmAbl('Rune tvarog _Stats', 'vitalityCombatRegen') + " in combat (expected 5, 5)");
	GMTestReport(GMTestArmNear(GMTestArmAbl('Glyph mending lesser _Stats', 'vitalityRegen'), 3) && GMTestArmNear(GMTestArmAbl('Glyph binding greater _Stats', 'bleeding_resistance_perc'), 0.05) && GMTestArmNear(GMTestArmAbl('Glyph warding greater _Stats', 'quen_chance_on_projectile'), 0.05) && GMTestArmAbl('Glyph warding greater _Stats', 'elemental_resistance_perc') == 0,
		"ENCH-16 glyphs: Mending lesser " + GMTestArmAbl('Glyph mending lesser _Stats', 'vitalityRegen') + ", Binding greater " + GMTestArmAbl('Glyph binding greater _Stats', 'bleeding_resistance_perc') + ", Warding greater Quen chance " + GMTestArmAbl('Glyph warding greater _Stats', 'quen_chance_on_projectile') + " (expected 3, 0.05, 0.05; no elemental resistance)");
	theGame.GetDefinitionsManager().GetAbilityAttributeValue('Glyph aard greater _Stats', 'spell_power_aard', min, max);
	GMTestReport(GMTestArmNear(min.valueMultiplicative, 0.05), "ENCH-16 glyphs: greater Aard glyph +" + min.valueMultiplicative + " intensity (expected 0.05)");
	inv = thePlayer.GetInventory();
	ids = inv.AddAnItem('Rune pierog', 1, true, true, false);
	GMTestReport(ids.Size() > 0 && inv.ItemHasAbility(ids[0], 'Rune pierog _Stats') && !inv.ItemHasAbility(ids[0], 'Relic _Stats'), "ENCH-16: a Pierog rune is not a relic");
	inv.RemoveItem(ids[0], 1);
}

// ENCH-16 Glyph of Warding, against a hostile NPC (a test dummy): scripted projectile hits of the NPC's
// on Geralt (a) with Warding's chance raised to 100% (the greater glyph's ability 20 times on Geralt):
// a free Quen absorbs the hit and ends with it (no Quen left up: 5.x's cast from ReactToBeingHit,
// which stayed up, is gone); (b) without it: the hit lands.
function GMTestEnchProjectile(npc : CActor) : float
{
	var action : W3Action_Attack;
	var before : float;

	before = thePlayer.GetStat(BCS_Vitality);
	action = new W3Action_Attack in theGame.damageMgr;
	action.Init(npc, thePlayer, NULL, GetInvalidUniqueId(), 'attack_light', npc.GetName(), EHRT_Light,
		false, false, 'attack_light', AST_Jab, ASD_UpDown, false, true, false, false);
	action.AddDamage(theGame.params.DAMAGE_NAME_PIERCING, 100);
	action.SetSuppressHitSounds(true);
	action.SetHitAnimationPlayType(EAHA_ForceNo);
	theGame.damageMgr.ProcessAction(action);
	delete action;
	return before - thePlayer.GetStat(BCS_Vitality);
}

exec function gmtest_ench16_warding()
{
	var w : W3PlayerWitcher;
	var npc : CActor;
	var i, quens : int;
	var lost : float;

	w = GetWitcherPlayer();
	npc = GMTestHostileNpc();
	if(!npc)
	{
		GMTestReport(false, "ENCH-16 Warding: no hostile NPC nearby");
		return;
	}
	w.ForceSetStat(BCS_Vitality, w.GetStatMax(BCS_Vitality));
	for(i = 0; i < 20; i += 1)
		w.AddAbility('Glyph warding greater _Stats', true);
	quens = w.gmWardingQuens;
	lost = GMTestEnchProjectile(npc);
	GMTestReport(w.gmWardingQuens == quens + 1 && lost == 0 && !w.IsAnyQuenActive(), "ENCH-16 Warding: projectile hit absorbed by a free Quen (" + (w.gmWardingQuens - quens) + " cast, Vitality lost " + lost + ", Quen up afterwards " + w.IsAnyQuenActive() + ")");
	w.RemoveAbilityAll('Glyph warding greater _Stats');
	quens = w.gmWardingQuens;
	lost = GMTestEnchProjectile(npc);
	GMTestReport(w.gmWardingQuens == quens && lost > 0 && !w.IsAnyQuenActive(), "ENCH-16 Warding: without the glyph the hit lands (Vitality lost " + lost + ")");
	w.ForceSetStat(BCS_Vitality, w.GetStatMax(BCS_Vitality));
}
