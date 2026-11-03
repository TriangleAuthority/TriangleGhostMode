// In-game tests for SWD (swords). See docs/features/swd.md.

// An ability's value as the definitions give it (base and add).
function GMTestSwdAbl(abilityName : name, attr : name) : float
{
	var min, max : SAbilityAttributeValue;

	theGame.GetDefinitionsManager().GetAbilityAttributeValue(abilityName, attr, min, max);
	return min.valueBase + min.valueAdditive + min.valueMultiplicative;
}

function GMTestSwdNear(a : float, b : float) : bool
{
	return AbsF(a - b) < 0.0001;
}

// Whether a sword's tooltip stats list an attribute, and under which name.
function GMTestSwdTooltip(itemName : name, attr : name, out label : string) : bool
{
	var inv : CInventoryComponent;
	var ids : array<SItemUniqueId>;
	var stats : array<SAttributeTooltip>;
	var i : int;
	var found : bool;

	inv = thePlayer.GetInventory();
	ids = inv.AddAnItem(itemName, 1, true, true, false);
	inv.GetItemStats(ids[0], stats);
	for(i = 0; i < stats.Size(); i += 1)
		if(stats[i].originName == attr)
		{
			found = true;
			label = stats[i].attributeName;
		}
	inv.RemoveItem(ids[0], 1);
	return found;
}

// SWD's situation-free checks (in gmtest_regress()). Data the scripts cannot read (the items' child
// blocks, the strings in all nine languages) is checked by `python tools/gen_swd_items.py --verify`.
function GMTest_swd()
{
	GMTest_swd01();
	GMTest_swd02();
	GMTest_swd03();
	GMTest_swd04();
	GMTest_swd05();
	GMTest_swd06();
	GMTest_swd07();
	GMTest_swd10();
}

// SWD-01, SWD-02, SWD-08, SWD-09 (slice 1): damage by item level, crafted and generic swords' fixed
// bonuses, the XP bonuses removed, display fixes, the tooltip rows; legacy's weights (WGT-03 since WGT's slice W2).
function GMTest_swd01()
{
	var dm : CDefinitionsManagerAccessor;
	var label : string;
	var found : bool;

	dm = theGame.GetDefinitionsManager();
	GMTestReport(GMTestSwdNear(GMTestSwdAbl('Short sword 1_crafted _Stats', 'SlashingDamage'), 33) && GMTestSwdNear(GMTestSwdAbl('Short sword 1_crafted _Stats', 'armor_reduction'), 20) && GMTestSwdNear(GMTestSwdAbl('Short sword 1_crafted _Stats', 'quality'), 1) && GMTestSwdNear(GMTestSwdAbl('Short sword 1_crafted _Stats', 'weight'), 8),
		"SWD-01/02 crafted Short sword: damage " + GMTestSwdAbl('Short sword 1_crafted _Stats', 'SlashingDamage') + " (expected 33 = 25 + 8 x level 1; 5.x 30), armor penetration " + GMTestSwdAbl('Short sword 1_crafted _Stats', 'armor_reduction') + " (20), quality " + GMTestSwdAbl('Short sword 1_crafted _Stats', 'quality') + " (1), weight " + GMTestSwdAbl('Short sword 1_crafted _Stats', 'weight') + " (legacy's 8, WGT-03; 5.x 3.2)");
	GMTestReport(GMTestSwdNear(GMTestSwdAbl('Silver sword 1_crafted _Stats', 'SilverDamage'), 100) && GMTestSwdNear(GMTestSwdAbl('Short sword 2_crafted _Stats', 'armor_reduction_perc'), 0.05),
		"SWD-01/02 crafted silver sword 1: silver damage " + GMTestSwdAbl('Silver sword 1_crafted _Stats', 'SilverDamage') + " (expected 100 = 90 + 10 x 1); crafted Short sword 2 resistance reduction " + GMTestSwdAbl('Short sword 2_crafted _Stats', 'armor_reduction_perc') + " (0.05)");
	GMTestReport(GMTestSwdNear(GMTestSwdAbl('Nilfgaardian sword 4_crafted _Stats', 'buff_apply_chance'), 0.05) && GMTestSwdNear(GMTestSwdAbl('Nilfgaardian sword 4_crafted _Stats', 'attack_power'), 0.05),
		"SWD-02 crafted Nilfgaardian sword 4: bleeding chance " + GMTestSwdAbl('Nilfgaardian sword 4_crafted _Stats', 'buff_apply_chance') + " (0.05), attack power +" + GMTestSwdAbl('Nilfgaardian sword 4_crafted _Stats', 'attack_power') + " (0.05)");
	GMTestReport(GMTestSwdNear(GMTestSwdAbl('autogen_steel_dmg', 'SlashingDamage'), 8) && GMTestSwdNear(GMTestSwdAbl('autogen_silver_dmg', 'SilverDamage'), 10),
		"SWD-01 damage per item level: steel " + GMTestSwdAbl('autogen_steel_dmg', 'SlashingDamage') + " (8), silver " + GMTestSwdAbl('autogen_silver_dmg', 'SilverDamage') + " (10)");
	GMTestReport(GMTestSwdNear(GMTestSwdAbl('EP1 Standalone Starting Steel Sword _Stats', 'human_exp_bonus_when_fatal'), 0) && GMTestSwdNear(GMTestSwdAbl('Long Steel Sword _Stats', 'armor_reduction'), 0),
		"SWD-02 no XP bonus on the Hearts of Stone standalone steel sword (" + GMTestSwdAbl('EP1 Standalone Starting Steel Sword _Stats', 'human_exp_bonus_when_fatal') + "); the Long Steel Sword's armor penetration removed (" + GMTestSwdAbl('Long Steel Sword _Stats', 'armor_reduction') + ")");
	GMTestReport(dm.GetItemEnhancementSlotCount('Novigraadan sword 1_crafted') == 2 && dm.GetItemEnhancementSlotCount('Dwarven sword 1_crafted') == 1,
		"SWD-02 legacy's slots: crafted Novigraadan sword 1 " + dm.GetItemEnhancementSlotCount('Novigraadan sword 1_crafted') + " (2; 5.x 0), crafted dwarven sword 1 " + dm.GetItemEnhancementSlotCount('Dwarven sword 1_crafted') + " (1; 5.x 2)");
	GMTestReport(dm.GetItemIconPath('Inquisitor sword 1_crafted') == "icons/inventory/weapons/inquisitor_sword_lvl1_64x128.png", "SWD-08 crafted Inquisitor sword's icon: " + dm.GetItemIconPath('Inquisitor sword 1_crafted'));
	found = GMTestSwdTooltip('Short sword 2_crafted', 'armor_reduction_perc', label);
	GMTestReport(found && label == "Enemy damage resistance reduction", "SWD-09 tooltip row for resistance reduction (crafted Short sword 2): " + found + ", '" + label + "'");
	found = GMTestSwdTooltip('Burning Rose Sword B', 'dismember_chance', label);
	GMTestReport(found && label == "Dismember chance" && GMTestSwdNear(GMTestSwdAbl('Burning Rose Sword B _Stats', 'dismember_chance_mult'), 0), "SWD-09 tooltip row for dismember chance (Burning Rose sword): " + found + ", '" + label + "' (the old dismember_chance_mult gone)");
	found = GMTestSwdTooltip('Short sword 1_crafted', 'armor_reduction', label);
	GMTestReport(found && label == "Armor penetration", "SWD-09 armor penetration's name (crafted Short sword 1): '" + label + "'");
}

// How many of `count` new copies of an item got a random bonus (an `MA_` ability: 5.x's
// AddRandomEnhancementToItem, which runs when Geralt receives an item, bought, crafted or added) and the
// highest number of abilities a copy had; each copy is removed again.
function GMTestSwdRandomBonuses(itemName : name, count : int, out maxAbilities : int) : int
{
	var inv : CInventoryComponent;
	var ids : array<SItemUniqueId>;
	var abls : array<name>;
	var i, j, n : int;
	var rolled : bool;

	inv = thePlayer.GetInventory();
	maxAbilities = 0;
	for(i = 0; i < count; i += 1)
	{
		ids = inv.AddAnItem(itemName, 1, true, true, false);
		abls.Clear();
		inv.GetItemAbilities(ids[0], abls);
		rolled = false;
		for(j = 0; j < abls.Size(); j += 1)
			if(StrBeginsWith(NameToString(abls[j]), "MA_"))
				rolled = true;
		if(rolled)
			n += 1;
		if(abls.Size() > maxAbilities)
			maxAbilities = abls.Size();
		inv.RemoveItem(ids[0], 1);
	}
	return n;
}

// SWD-02 (SWD audit F4, the owner's decision, 2026-10-19): crafted swords and the Wild Hunt swords 3
// and 4 carry legacy's DoNotEnhance, so a new one gets no random bonus on top of its fixed ones; a loot
// sword of the same quality without the tag still does (the control). NG+ data: --verify.
function GMTest_swd02()
{
	var a, b, c, d, ab, bb, cb, db : int;

	GMTestReport(GMTestArmTag('Skellige sword 2_crafted', 'DoNotEnhance') && GMTestArmTag('Scoiatael sword 4_crafted', 'DoNotEnhance') && GMTestArmTag('Silver sword 6_crafted', 'DoNotEnhance')
		&& GMTestArmTag('Gnomish silver sword 1_crafted', 'DoNotEnhance') && GMTestArmTag('Wild Hunt sword 3', 'DoNotEnhance') && GMTestArmTag('Wild Hunt sword 4', 'DoNotEnhance') && !GMTestArmTag('Dwarven sword 2', 'DoNotEnhance'),
		"SWD-02 DoNotEnhance on the crafted Skellige sword 2, Scoia'tael sword 4, silver sword 6, gnomish silver sword 1 and the Wild Hunt swords 3 and 4 (not on the loot Dwarven sword 2)");
	a = GMTestSwdRandomBonuses('Skellige sword 2_crafted', 8, ab);
	b = GMTestSwdRandomBonuses('Silver sword 6_crafted', 8, bb);
	c = GMTestSwdRandomBonuses('Wild Hunt sword 4', 8, cb);
	d = GMTestSwdRandomBonuses('Dwarven sword 2', 8, db);
	GMTestReport(a == 0 && b == 0 && c == 0 && d == 8,
		"SWD-02 new swords with a random bonus, of 8 each: crafted Skellige sword 2 (quality 2) " + a + " (0), crafted silver sword 6 (quality 3) " + b + " (0), Wild Hunt sword 4 " + c + " (0); control, the untagged loot Dwarven sword 2 (quality 2) " + d + " (8); most abilities " + ab + "/" + bb + "/" + cb + "/" + db);
}

// Adds a sword and equips it (Geralt's level must allow it), then logs its damage, level and the
// damage the game computes for it.
exec function gmtest_swd_equip(itemName : name)
{
	var w : W3PlayerWitcher;
	var inv : CInventoryComponent;
	var ids : array<SItemUniqueId>;

	w = GetWitcherPlayer();
	inv = w.GetInventory();
	ids = inv.AddAnItem(itemName, 1, true, true, false);
	w.EquipItem(ids[0]);
	LogChannel('GMTest', "INFO " + itemName + ": equipped " + inv.IsItemMounted(ids[0]) + ", slashing " + CalculateAttributeValue(inv.GetItemAttributeValue(ids[0], 'SlashingDamage')) + ", silver " + CalculateAttributeValue(inv.GetItemAttributeValue(ids[0], 'SilverDamage')) + ", level " + inv.GetItemLevel(ids[0]) + ", total weapon damage " + w.GetTotalWeaponDamage(ids[0], 'SlashingDamage', GetInvalidUniqueId()));
}

@addField(CR4Player)
var gmTestSwdCrit : bool;

@addMethod(CR4Player)
function GMTestSwdSetCrit(crit : bool)
{
	gmTestSwdCrit = crit;
}

// Records whether the player's hit was a critical hit (test probe).
@wrapMethod(W3DamageManagerProcessor)
function ProcessCriticalHitCheck()
{
	wrappedMethod();
	if(GMTestProbes() && playerAttacker && action.IsActionMelee())
		thePlayer.GMTestSwdSetCrit(action.IsCriticalHit());
}

// A real light attack (through the input handler) with the drawn sword, for gmtest_swd_hit_b().
exec function gmtest_swd_hit_a()
{
	thePlayer.GMTestDmgReset();
	thePlayer.GMTestSwdSetCrit(false);
	thePlayer.GMTestSetProbes(true);
	GMTestActInput(0, true);
	GMTestActInput(0, false);
}

// The raw damage of the last hit (before the increase steps) and each damage type's formula step.
exec function gmtest_swd_hit_b()
{
	var i : int;

	LogChannel('GMTest', "INFO hit: dealt " + thePlayer.gmTestDmgDealt + ", raw before increase " + thePlayer.gmTestDmgRawBefore + ", final " + thePlayer.gmTestDmgFinal + ", crit " + thePlayer.gmTestSwdCrit);
	for(i = 0; i < thePlayer.gmTestDmgSteps.Size(); i += 1)
		GMTestDmgLogStep("hit", thePlayer.gmTestDmgSteps[i]);
	thePlayer.GMTestSetProbes(false);
}

// SWD-03 (slice 2): relic and unique swords' themes (legacy's ranges), the crowns and XP bonuses and
// the indestructibility of Torlara and Torzirael gone, icons. The Wolf relic's and Torzirael's draw
// animations (SWD-08, their anim_actions) cannot be read by script: `gen_swd_items.py --verify` compares
// every child block with legacy's, and gmtest_swd08_draw() draws the Wolf relic in game.
function GMTest_swd03()
{
	var dm : CDefinitionsManagerAccessor;
	var label : string;
	var found : bool;

	dm = theGame.GetDefinitionsManager();
	GMTestReport(GMTestSwdNear(GMTestSwdAbl('Caerme_Stats', 'buff_apply_chance'), 0.15) && GMTestSwdNear(GMTestSwdAbl('Caerme_Stats', 'FireDamage'), 30) && GMTestSwdNear(GMTestSwdAbl('Caerme_Stats', 'focus_gain'), 0.1) && GMTestSwdNear(GMTestSwdAbl('Caerme_Stats', 'dismember_chance_mult'), 0),
		"SWD-03 Caerme: burning chance " + GMTestSwdAbl('Caerme_Stats', 'buff_apply_chance') + " (0.15), fire damage from " + GMTestSwdAbl('Caerme_Stats', 'FireDamage') + " (30; 1.32 1), adrenaline gain from " + GMTestSwdAbl('Caerme_Stats', 'focus_gain') + " (0.1)");
	GMTestReport(GMTestSwdNear(GMTestSwdAbl('Gwyhyr_Stats', 'critical_hit_chance'), 0.25) && GMTestSwdNear(GMTestSwdAbl('Gwyhyr_Stats', 'armor_reduction'), 30) && GMTestSwdNear(GMTestSwdAbl('Gwyhyr_Stats', 'critical_hit_damage_bonus'), 0.3),
		"SWD-03 Gwyhyr: crit chance from " + GMTestSwdAbl('Gwyhyr_Stats', 'critical_hit_chance') + " (0.25), armor penetration from " + GMTestSwdAbl('Gwyhyr_Stats', 'armor_reduction') + " (30), crit damage from " + GMTestSwdAbl('Gwyhyr_Stats', 'critical_hit_damage_bonus') + " (0.3)");
	GMTestReport(GMTestSwdNear(GMTestSwdAbl('Hjalmar_Short_Steel_Sword _Stats', 'critical_hit_chance'), 0.25) && GMTestSwdNear(GMTestSwdAbl('Hjalmar_Short_Steel_Sword _Stats', 'critical_hit_damage_bonus'), 0.75) && GMTestSwdNear(GMTestSwdAbl('Hjalmar_Short_Steel_Sword _Stats', 'attack_power'), 0.1),
		"SWD-03 Hjalmar's sword: crit chance " + GMTestSwdAbl('Hjalmar_Short_Steel_Sword _Stats', 'critical_hit_chance') + " (0.25), crit damage " + GMTestSwdAbl('Hjalmar_Short_Steel_Sword _Stats', 'critical_hit_damage_bonus') + " (0.75), attack power " + GMTestSwdAbl('Hjalmar_Short_Steel_Sword _Stats', 'attack_power') + " (0.1)");
	GMTestReport(GMTestSwdNear(GMTestSwdAbl('Unique silver sword _Stats', 'critical_hit_damage_bonus'), 1) && GMTestSwdNear(GMTestSwdAbl('Unique silver sword _Stats', 'buff_apply_chance'), 0.2) && GMTestSwdNear(GMTestSwdAbl('Unique silver sword _Stats', 'item_level_min'), 45),
		"SWD-03 Blood and Wine unique silver sword: crit damage " + GMTestSwdAbl('Unique silver sword _Stats', 'critical_hit_damage_bonus') + " (1.0), burning chance " + GMTestSwdAbl('Unique silver sword _Stats', 'buff_apply_chance') + " (0.2), level range from " + GMTestSwdAbl('Unique silver sword _Stats', 'item_level_min') + " (45, legacy's: ITEM-03; 5.x 40)");
	GMTestReport(GMTestSwdNear(GMTestSwdAbl('Harpy_crafted_Stats', 'SilverDamage'), 340) && GMTestSwdNear(GMTestSwdAbl('Harpy_crafted_Stats', 'critical_hit_chance'), 0.25) && GMTestArmHasAbility('Harpy_crafted', 'Default weapon _Stats'),
		"SWD-03 crafted Harpy: silver damage " + GMTestSwdAbl('Harpy_crafted_Stats', 'SilverDamage') + " (340 = level 25), crit chance " + GMTestSwdAbl('Harpy_crafted_Stats', 'critical_hit_chance') + " (0.25), legacy's ability list");
	GMTestReport(!GMTestArmHasAbility('Torlara', 'MA_Indestructible') && !GMTestArmHasAbility('Torzirael', 'MA_Indestructible') && GMTestSwdNear(GMTestSwdAbl('Torlara_Stats', 'instant_kill_chance'), 0.01),
		"SWD-03 Torlara and Torzirael without indestructibility; Torlara's instant kill chance from " + GMTestSwdAbl('Torlara_Stats', 'instant_kill_chance') + " (0.01)");
	GMTestReport(dm.GetItemIconPath('Longclaw') == "icons/inventory/weapons/steel_unique_longclaw_64x128.png", "SWD-08 Longclaw's icon: " + dm.GetItemIconPath('Longclaw'));
	found = GMTestSwdTooltip('Deireadh', 'critical_hit_chance', label);
	GMTestReport(found && GMTestSwdNear(GMTestSwdAbl('Deireadh_Stats', 'spell_power_axii'), 0.08), "SWD-03 Deireadh: crit chance in the tooltip (" + found + ", '" + label + "'), Axii intensity from " + GMTestSwdAbl('Deireadh_Stats', 'spell_power_axii') + " (0.08)");
}

// SWD-04 (slice 3): the school swords' themes and damage by level, entries merged with ARM's set tags,
// the Viper sword's look.
function GMTest_swd04()
{
	var dm : CDefinitionsManagerAccessor;

	dm = theGame.GetDefinitionsManager();
	GMTestReport(GMTestSwdNear(GMTestSwdAbl('Lynx School steel sword _Stats', 'SlashingDamage'), 161) && GMTestSwdNear(GMTestSwdAbl('Lynx School steel sword _Stats', 'critical_hit_chance'), 0.15) && GMTestSwdNear(GMTestSwdAbl('Lynx School steel sword _Stats', 'buff_apply_chance'), 0.15),
		"SWD-04 Feline steel sword: damage " + GMTestSwdAbl('Lynx School steel sword _Stats', 'SlashingDamage') + " (161, level 17), crit chance " + GMTestSwdAbl('Lynx School steel sword _Stats', 'critical_hit_chance') + " (0.15), bleeding " + GMTestSwdAbl('Lynx School steel sword _Stats', 'buff_apply_chance') + " (0.15)");
	GMTestReport(GMTestSwdNear(GMTestSwdAbl('Gryphon School silver sword 4 _Stats', 'SilverDamage'), 490) && GMTestSwdNear(GMTestSwdAbl('Gryphon School silver sword 4 _Stats', 'spell_power'), 0.3) && GMTestSwdNear(GMTestSwdAbl('Gryphon School silver sword 4 _Stats', 'FireDamage'), 60) && GMTestArmTag('Gryphon School silver sword 4', 'GryphonSet') && GMTestArmTag('Gryphon School silver sword 4', 'SetBonusPiece'),
		"SWD-04 grandmaster Griffin silver sword: silver " + GMTestSwdAbl('Gryphon School silver sword 4 _Stats', 'SilverDamage') + " (490, level 40), sign intensity " + GMTestSwdAbl('Gryphon School silver sword 4 _Stats', 'spell_power') + " (0.3), fire " + GMTestSwdAbl('Gryphon School silver sword 4 _Stats', 'FireDamage') + " (60), ARM's set tags kept");
	GMTestReport(GMTestSwdNear(GMTestSwdAbl('Bear School steel sword 3 _Stats', 'attack_power'), 0.35) && GMTestSwdNear(GMTestSwdAbl('Bear School steel sword 3 _Stats', 'focus_gain'), 0.25) && GMTestArmTag('Bear School steel sword 3', 'BearSetMinor'),
		"SWD-04 superior Ursine steel sword: attack power " + GMTestSwdAbl('Bear School steel sword 3 _Stats', 'attack_power') + " (0.35), adrenaline gain " + GMTestSwdAbl('Bear School steel sword 3 _Stats', 'focus_gain') + " (0.25), minor set tag kept");
	GMTestReport(GMTestSwdNear(GMTestSwdAbl('Red Wolf School steel sword 1 _Stats', 'armor_reduction'), 80) && GMTestSwdNear(GMTestSwdAbl('Red Wolf School steel sword 1 _Stats', 'armor_reduction_perc'), 0.15) && GMTestSwdNear(GMTestSwdAbl('Red Wolf School steel sword 1 _Stats', 'focus_gain'), 0.25),
		"SWD-04 Manticore steel sword: armor penetration " + GMTestSwdAbl('Red Wolf School steel sword 1 _Stats', 'armor_reduction') + " (80), resistance reduction " + GMTestSwdAbl('Red Wolf School steel sword 1 _Stats', 'armor_reduction_perc') + " (0.15), adrenaline gain " + GMTestSwdAbl('Red Wolf School steel sword 1 _Stats', 'focus_gain') + " (0.25)");
	GMTestReport(GMTestSwdNear(GMTestSwdAbl('Wolf School silver sword 3 _Stats', 'SilverDamage'), 431) && GMTestSwdNear(GMTestSwdAbl('Wolf School silver sword 3 _Stats', 'attack_power'), 0.25) && GMTestSwdNear(GMTestSwdAbl('Wolf School silver sword 3 _Stats', 'spell_power'), 0.2),
		"SWD-04 Wolven silver sword 3 (free DLC): silver " + GMTestSwdAbl('Wolf School silver sword 3 _Stats', 'SilverDamage') + " (431), attack power " + GMTestSwdAbl('Wolf School silver sword 3 _Stats', 'attack_power') + " (0.25), sign intensity " + GMTestSwdAbl('Wolf School silver sword 3 _Stats', 'spell_power') + " (0.2)");
	GMTestReport(GMTestSwdNear(GMTestSwdAbl('Viper School steel sword _Stats', 'PoisonDamage'), 10) && dm.GetItemIconPath('Viper School steel sword') == "icons/inventory/weapons/nomansland_sword_lvl2_64x128.png",
		"SWD-04 Viper steel sword: poison damage " + GMTestSwdAbl('Viper School steel sword _Stats', 'PoisonDamage') + " (10), legacy's look and icon (" + dm.GetItemIconPath('Viper School steel sword') + ")");
}

// SWD-05 (slice 4): Aerondight's values (situation-free); out of combat it has no effect, even equipped.
function GMTest_swd05()
{
	var w : W3PlayerWitcher;
	var ids : array<SItemUniqueId>;
	var old : SItemUniqueId;
	var had, has : bool;
	var desc : string;
	var tc : W3TooltipComponent;

	GMTestReport(GMTestSwdNear(GMTestSwdAbl('AerondightEffect', 'crit_dmg_bonus'), 1) && GMTestSwdNear(GMTestSwdAbl('AerondightEffect', 'dmg_boost_per_enemy'), 10) && GMTestSwdNear(GMTestSwdAbl('AerondightEffect', 'collateral_dmg'), 100)
		&& GMTestSwdNear(GMTestSwdAbl('AerondightEffect', 'hitsToCharge'), 4) && GMTestSwdNear(GMTestSwdAbl('AerondightEffect', 'stackDrainDelay'), 6) && GMTestSwdNear(GMTestSwdAbl('AerondightEffect', 'perm_dmg_boost'), 0)
		&& GMTestSwdNear(GMTestSwdAbl('AerondightEffect', 'crit_chance_bonus'), 1),
		"SWD-05 Aerondight's values: crit power +" + GMTestSwdAbl('AerondightEffect', 'crit_dmg_bonus') + " (1), " + GMTestSwdAbl('AerondightEffect', 'dmg_boost_per_enemy') + " per enemy (10), shock " + GMTestSwdAbl('AerondightEffect', 'collateral_dmg') + " (100), " + GMTestSwdAbl('AerondightEffect', 'hitsToCharge') + " hits (4), decay " + GMTestSwdAbl('AerondightEffect', 'stackDrainDelay') + " s (6), no permanent growth, charged crit chance +" + GMTestSwdAbl('AerondightEffect', 'crit_chance_bonus') + " (1: a certain crit)");
	w = GetWitcherPlayer();
	if(w.IsInCombat())
	{
		GMTestReport(false, "SWD-05 out-of-combat check skipped: in combat");
		return;
	}
	w.GetItemEquippedOnSlot(EES_SilverSword, old);
	ids = w.inv.AddAnItem('Aerondight EP2', 1, true, true, false);
	w.EquipItemInGivenSlot(ids[0], EES_SilverSword, false);
	has = w.HasBuff(EET_Aerondight);
	tc = new W3TooltipComponent in w;
	desc = tc.GetAerondightTooltipDescription(w.inv, ids[0]);
	if(w.inv.IsIdValid(old))
		w.EquipItemInGivenSlot(old, EES_SilverSword, false);
	GMTestReport(!has && w.inv.ItemHasTag(ids[0], 'Aerondight'), "SWD-05 Aerondight (Blood and Wine) equipped out of combat: no effect (" + has + ")");
	w.inv.RemoveItem(ids[0], 1);
	GMTestReport(StrFindFirst(desc, "per enemy") >= 0 && StrFindFirst(desc, "0/4") >= 0, "SWD-05 Aerondight's description: " + StrLeft(desc, 60) + "... " + StrRight(desc, 60));
}

// Aerondight's state in a fight (scripted read): the effect, charges, damage boost, hostiles.
exec function gmtest_swd05_state()
{
	var w : W3PlayerWitcher;
	var a : W3Effect_Aerondight;
	var id : SItemUniqueId;

	w = GetWitcherPlayer();
	a = (W3Effect_Aerondight)w.GetBuff(EET_Aerondight);
	w.GetItemEquippedOnSlot(EES_SilverSword, id);
	if(!a)
	{
		LogChannel('GMTest', "INFO Aerondight: no effect; in combat " + w.IsInCombat() + ", state " + w.GetCurrentStateName());
		return;
	}
	LogChannel('GMTest', "INFO Aerondight: effect, paused " + a.IsPaused() + ", charges " + a.GetCurrentCount() + "/" + a.GetMaxCount() + ", full " + a.IsFullyCharged() + ", damage boost " + a.GMGetDamageBoost() + " (hostiles " + w.GMGetNumHostilesInRange() + "), weapon damage " + w.GetTotalWeaponDamage(id, 'SilverDamage', GetInvalidUniqueId()) + ", in combat " + w.IsInCombat());
}

// Gives the drawn Aerondight n charges (scripted), for the discharge test.
exec function gmtest_swd05_charge(n : int)
{
	var a : W3Effect_Aerondight;
	var i : int;

	a = (W3Effect_Aerondight)thePlayer.GetBuff(EET_Aerondight);
	for(i = 0; a && i < n; i += 1)
		a.GMAddCharge();
	LogChannel('GMTest', "INFO Aerondight charges " + a.GetCurrentCount());
}

// The test dummies' health (the discharge's shock reaches the one not hit).
exec function gmtest_swd_actors()
{
	var ents : array<CGameplayEntity>;
	var i : int;
	var a : CActor;

	FindGameplayEntitiesInRange(ents, thePlayer, 10, 10, , FLAG_OnlyAliveActors + FLAG_ExcludeTarget, thePlayer);
	for(i = 0; i < ents.Size(); i += 1)
	{
		a = (CActor)ents[i];
		if(a)
			LogChannel('GMTest', "INFO actor " + a.GetName() + ": health " + a.GetHealth() + ", essence " + a.GetStat(BCS_Essence, true) + ", staggered " + a.HasBuff(EET_Stagger) + ", distance " + VecDistance(a.GetWorldPosition(), thePlayer.GetWorldPosition()));
	}
}

// Debug: applies Aerondight's effect as drawing it does, and logs what it finds.
exec function gmtest_swd05_apply()
{
	var item : SItemUniqueId;
	var res : EEffectInteract;

	item = thePlayer.inv.GetCurrentlyHeldSword();
	LogChannel('GMTest', "INFO held " + thePlayer.inv.GetItemName(item) + ", Aerondight tag " + thePlayer.inv.ItemHasTag(item, 'Aerondight') + ", in combat " + thePlayer.IsInCombat() + ", has effect " + thePlayer.HasBuff(EET_Aerondight));
	thePlayer.ManageAerondightBuff(true);
	LogChannel('GMTest', "INFO after ManageAerondightBuff: has effect " + thePlayer.HasBuff(EET_Aerondight));
	if(!thePlayer.HasBuff(EET_Aerondight))
	{
		res = thePlayer.AddEffectDefault(EET_Aerondight, thePlayer, "Aerondight");
		LogChannel('GMTest', "INFO AddEffectDefault: " + res + ", has effect " + thePlayer.HasBuff(EET_Aerondight));
	}
}

// SWD-06 (slice 5): Iris's values, its effect's charges, decay, damage boost and description (scripted,
// situation-free); out of combat it has no effect, even equipped; vanilla's manager is not created.
function GMTest_swd06()
{
	var w : W3PlayerWitcher;
	var ids : array<SItemUniqueId>;
	var old : SItemUniqueId;
	var has, mgr : bool;
	var desc : string;
	var tc : W3TooltipComponent;
	var pw : W3GMEffect_PhantomWeapon;
	var dmg0, dmg4, boost : float;
	var full : bool;
	var after : int;

	GMTestReport(GMTestSwdNear(GMTestSwdAbl('GMPhantomWeaponEffect', 'dmg_bonus_prc'), 0.05) && GMTestSwdNear(GMTestSwdAbl('GMPhantomWeaponEffect', 'hitsToCharge'), 4) && GMTestSwdNear(GMTestSwdAbl('GMPhantomWeaponEffect', 'stackDrainDelay'), 6),
		"SWD-06 Iris's values: " + GMTestSwdAbl('GMPhantomWeaponEffect', 'dmg_bonus_prc') + " of Vitality (0.05), " + GMTestSwdAbl('GMPhantomWeaponEffect', 'hitsToCharge') + " hits (4), decay " + GMTestSwdAbl('GMPhantomWeaponEffect', 'stackDrainDelay') + " s (6)");
	w = GetWitcherPlayer();
	if(w.IsInCombat())
	{
		GMTestReport(false, "SWD-06 out-of-combat checks skipped: in combat");
		return;
	}
	w.GetItemEquippedOnSlot(EES_SteelSword, old);
	ids = w.inv.AddAnItem('Olgierd Sabre', 1, true, true, false);
	w.EquipItemInGivenSlot(ids[0], EES_SteelSword, false);
	has = w.HasBuff(EET_GMPhantomWeapon);
	if(w.GetPhantomWeaponMgr())
		mgr = true;
	if(w.inv.IsIdValid(old))
		w.EquipItemInGivenSlot(old, EES_SteelSword, false);
	GMTestReport(!has && !mgr && w.inv.ItemHasTag(ids[0], 'PhantomWeapon'), "SWD-06 Iris equipped out of combat: no effect (" + has + "), no vanilla manager (" + mgr + ")");

	// The effect by script: charges, damage boost, a full charge decays at once.
	dmg0 = w.GetTotalWeaponDamage(ids[0], 'SlashingDamage', GetInvalidUniqueId());
	w.AddEffectDefault(EET_GMPhantomWeapon, w, "PhantomWeapon");
	pw = (W3GMEffect_PhantomWeapon)w.GetBuff(EET_GMPhantomWeapon);
	if(!pw)
	{
		GMTestReport(false, "SWD-06 the effect could not be added");
		w.inv.RemoveItem(ids[0], 1);
		return;
	}
	pw.AddCharge(); pw.AddCharge(); pw.AddCharge();
	GMTestReport(!pw.IsFullyCharged() && pw.GetCurrentCount() == 3 && GMTestSwdNear(w.GetTotalWeaponDamage(ids[0], 'SlashingDamage', GetInvalidUniqueId()), dmg0), "SWD-06 three charges: not charged, no damage boost (" + w.GetTotalWeaponDamage(ids[0], 'SlashingDamage', GetInvalidUniqueId()) + ", " + dmg0 + ")");
	pw.AddCharge();
	full = pw.IsFullyCharged();
	dmg4 = w.GetTotalWeaponDamage(ids[0], 'SlashingDamage', GetInvalidUniqueId());
	boost = MinF(w.GetMaxHealth() * 0.05, w.GetCurrentHealth());
	tc = new W3TooltipComponent in w;
	desc = tc.GMGetIrisTooltipDescription();
	pw.RemoveCharge();
	after = pw.GetCurrentCount();
	GMTestReport(full && AbsF(dmg4 - dmg0 - boost) < 0.01 * boost + 0.01 && after == 0,
		"SWD-06 four charges: charged, slashing damage +" + (dmg4 - dmg0) + " (5% of Vitality " + boost + "); a full charge decays at once (" + after + ")");
	GMTestReport(StrFindFirst(desc, "phantom") >= 0 && StrFindFirst(desc, "4/4") >= 0 && StrFindFirst(desc, " 5%") >= 0, "SWD-06 Iris's description: " + StrLeft(desc, 60) + "... " + StrRight(desc, 60));
	w.RemoveBuff(EET_GMPhantomWeapon);
	w.inv.RemoveItem(ids[0], 1);
}

// Iris's state in a fight (scripted read).
exec function gmtest_swd06_state()
{
	var w : W3PlayerWitcher;
	var pw : W3GMEffect_PhantomWeapon;
	var id : SItemUniqueId;

	w = GetWitcherPlayer();
	pw = (W3GMEffect_PhantomWeapon)w.GetBuff(EET_GMPhantomWeapon);
	w.GetItemEquippedOnSlot(EES_SteelSword, id);
	if(!pw)
	{
		LogChannel('GMTest', "INFO Iris: no effect; in combat " + w.IsInCombat() + ", state " + w.GetCurrentStateName() + ", held " + w.inv.GetItemName(w.inv.GetCurrentlyHeldSword()));
		return;
	}
	LogChannel('GMTest', "INFO Iris: effect, paused " + pw.IsPaused() + ", charges " + pw.GetCurrentCount() + "/" + pw.GetMaxCount() + ", full " + pw.IsFullyCharged() + ", boost " + pw.GetDamageBoost() + ", slashing " + w.GetTotalWeaponDamage(id, 'SlashingDamage', GetInvalidUniqueId()) + ", Vitality " + w.GetCurrentHealth() + "/" + w.GetMaxHealth() + ", ForceDismemberment " + w.HasAbility('ForceDismemberment') + ", in combat " + w.IsInCombat());
}

// Gives the drawn Iris n charges (scripted).
exec function gmtest_swd06_charge(n : int)
{
	var pw : W3GMEffect_PhantomWeapon;
	var i : int;

	pw = (W3GMEffect_PhantomWeapon)thePlayer.GetBuff(EET_GMPhantomWeapon);
	for(i = 0; pw && i < n; i += 1)
		pw.AddCharge();
	if(pw)
		LogChannel('GMTest', "INFO Iris charges " + pw.GetCurrentCount());
}

// A real strong attack (the combat action, as a released heavy attack key) with the drawn sword.
exec function gmtest_swd_heavy_a()
{
	thePlayer.GMTestSetProbes(true);
	GMTestActInput(1, true);
}

// Logs each melee hit of Geralt's while the probes are on: its source, dodgeable, parried, the damage
// it dealt and the effects it carries.
@wrapMethod(W3DamageManagerProcessor)
function ProcessAction(act : W3DamageAction)
{
	var atk : W3Action_Attack;
	var effs : array<SEffectInfo>;
	var i : int;
	var s : string;

	wrappedMethod(act);
	atk = (W3Action_Attack)act;
	if(GMTestProbes() && atk && act.attacker == thePlayer && act.IsActionMelee())
	{
		act.GetEffects(effs);
		for(i = 0; i < effs.Size(); i += 1)
			s += " " + effs[i].effectType;
		LogChannel('GMTest', "INFO melee hit on " + ((CActor)act.victim).GetName() + ": source " + atk.GetBuffSourceName() + ", dodgeable " + atk.CanBeDodged() + ", parried " + atk.IsParried() + ", dealt " + act.processedDmg.vitalityDamage + "/" + act.processedDmg.essenceDamage + ", effects" + s + ", at " + theGame.GetEngineTimeAsSeconds());
	}
}

// SWD-07 (slice 6): the NG+ school swords' weapon and sign damage bonuses (NG+ is not tested: the free
// DLC's NG+ Wolven swords are defined in the regular items too, so their values and tooltip rows read).
function GMTest_swd07()
{
	var lw, ls, ws, ss, audio, lang : string;
	var hw, hs : bool;

	GMTestReport(GMTestSwdNear(GMTestSwdAbl('NGP Wolf School steel sword _Stats', 'sword_dmg_bonus'), 0.05) && GMTestSwdNear(GMTestSwdAbl('NGP Wolf School steel sword 3 _Stats', 'sword_dmg_bonus'), 0.2)
		&& GMTestSwdNear(GMTestSwdAbl('NGP Wolf School silver sword 3 _Stats', 'spell_dmg_bonus'), 0.2),
		"SWD-07 NG+ Wolven swords: weapon damage +" + GMTestSwdAbl('NGP Wolf School steel sword _Stats', 'sword_dmg_bonus') + " (0.05) to +" + GMTestSwdAbl('NGP Wolf School steel sword 3 _Stats', 'sword_dmg_bonus') + " (0.2), sign damage +" + GMTestSwdAbl('NGP Wolf School silver sword 3 _Stats', 'spell_dmg_bonus') + " (0.2)");
	hw = GMTestSwdTooltip('NGP Wolf School steel sword 3', 'sword_dmg_bonus', lw);
	hs = GMTestSwdTooltip('NGP Wolf School steel sword 3', 'spell_dmg_bonus', ls);
	GMTestReport(hw && hs && lw == GetLocStringByKeyExt("attribute_name_sword_dmg_bonus") && ls == GetLocStringByKeyExt("attribute_name_spell_dmg_bonus") && StrLen(lw) > 0 && StrFindFirst(lw, "attribute_name") < 0,
		"SWD-07 tooltip rows: " + hw + " '" + lw + "', " + hs + " '" + ls + "'");
	// The strings are legacy's rows (by id and key; their text in English here, all nine languages by
	// gen_swd_items.py --verify).
	theGame.GetGameLanguageName(audio, lang);
	ws = GetLocStringById(2110992162);
	ss = GetLocStringById(2110992161);
	GMTestReport(ws == GetLocStringByKeyExt("attribute_name_sword_dmg_bonus") && ss == GetLocStringByKeyExt("attribute_name_spell_dmg_bonus") && (lang != "EN" || (ws == "Weapon damage" && ss == "Sign damage")),
		"SWD-07 strings (" + lang + "): 2110992162 '" + ws + "', 2110992161 '" + ss + "' (legacy's; EN: Weapon damage, Sign damage)");
}

// SWD-10 (slice 7): 5.x's new swords under Ghost Mode's rules (the owner's values): damage by level, the
// decided bonuses, no XP on kill or 5.x's other bonuses, the slots; the Netflix swords keep ARM-15's tags.
function GMTest_swd10()
{
	var dm : CDefinitionsManagerAccessor;
	var w : W3PlayerWitcher;
	var label : string;
	var found : bool;
	var a : name;

	dm = theGame.GetDefinitionsManager();
	w = GetWitcherPlayer();
	a = 'Netflix steel sword _Stats';
	GMTestReport(GMTestSwdNear(GMTestSwdAbl(a, 'SlashingDamage'), 193) && GMTestSwdNear(GMTestSwdAbl(a, 'attack_power'), 0.15) && GMTestSwdNear(GMTestSwdAbl(a, 'spell_power_yrden'), 0.10) && GMTestSwdNear(GMTestSwdAbl(a, 'focus_gain'), 0.05)
		&& GMTestSwdNear(GMTestSwdAbl(a, 'critical_hit_chance'), 0) && GMTestSwdNear(GMTestSwdAbl(a, 'buff_apply_chance'), 0) && GMTestSwdNear(GMTestSwdAbl(a, 'spell_power'), 0) && GMTestSwdNear(GMTestSwdAbl(a, 'human_exp_bonus_when_fatal'), 0) && dm.GetItemEnhancementSlotCount('Netflix steel sword') == 2,
		"SWD-10 Forgotten Wolven steel sword: damage " + GMTestSwdAbl(a, 'SlashingDamage') + " (193, level 21), attack power " + GMTestSwdAbl(a, 'attack_power') + " (0.15), Yrden " + GMTestSwdAbl(a, 'spell_power_yrden') + " (0.10), adrenaline " + GMTestSwdAbl(a, 'focus_gain') + " (0.05), no crit, bleeding, sign intensity or XP, slots " + dm.GetItemEnhancementSlotCount('Netflix steel sword') + " (2)");
	a = 'Netflix silver sword 1 _Stats';
	GMTestReport(GMTestSwdNear(GMTestSwdAbl(a, 'SilverDamage'), 440) && GMTestSwdNear(GMTestSwdAbl(a, 'attack_power'), 0.25) && GMTestSwdNear(GMTestSwdAbl(a, 'spell_power_yrden'), 0.20) && GMTestSwdNear(GMTestSwdAbl(a, 'focus_gain'), 0.07) && GMTestSwdNear(GMTestSwdAbl(a, 'nonhuman_exp_bonus_when_fatal'), 0)
		&& dm.GetItemEnhancementSlotCount('Netflix silver sword 1') == 3 && dm.GetItemEnhancementSlotCount('Netflix silver sword') == 2 && dm.GetItemEnhancementSlotCount('Reinald Netflix silver sword') == 2 && GMTestArmHasAbility('Reinald Netflix silver sword', 'Netflix silver sword _Stats'),
		"SWD-10 enhanced Forgotten Wolven silver sword: silver " + GMTestSwdAbl(a, 'SilverDamage') + " (440, level 35), attack power " + GMTestSwdAbl(a, 'attack_power') + " (0.25), Yrden " + GMTestSwdAbl(a, 'spell_power_yrden') + " (0.20), adrenaline " + GMTestSwdAbl(a, 'focus_gain') + " (0.07), slots 3; first tier and Reinald's silver swords 2 slots, Reinald's = first tier");
	a = 'Netflix silver sword 2 _Stats';
	GMTestReport(GMTestSwdNear(GMTestSwdAbl(a, 'SilverDamage'), 500) && GMTestSwdNear(GMTestSwdAbl('Netflix steel sword 2 _Stats', 'SlashingDamage'), 353) && GMTestSwdNear(GMTestSwdAbl(a, 'attack_power'), 0.30) && GMTestSwdNear(GMTestSwdAbl(a, 'spell_power_yrden'), 0.25) && GMTestSwdNear(GMTestSwdAbl(a, 'focus_gain'), 0.10)
		&& GMTestArmTag('Netflix silver sword 2', 'SetBonusPiece') && GMTestArmTag('Netflix steel sword 2', 'NetflixSet') && !GMTestArmTag('Netflix steel sword 2', 'NetflixSetMinor') && GMTestArmTag('Netflix steel sword', 'NetflixSetMinor') && GMTestArmTag('Reinald Netflix steel sword', 'NetflixSetMinor')
		&& w.CheckSetTypeByName('Netflix steel sword 2') == EIST_Netflix && w.CheckSetTypeByName('Netflix silver sword 1') == EIST_Netflix_Minor,
		"SWD-10 grandmaster Forgotten Wolven swords: silver " + GMTestSwdAbl(a, 'SilverDamage') + " (500), steel " + GMTestSwdAbl('Netflix steel sword 2 _Stats', 'SlashingDamage') + " (353, level 41), attack power 0.30, Yrden 0.25, adrenaline 0.10; ARM-15's set tags (top tier full set, lower tiers minor)");
	found = GMTestSwdTooltip('Netflix steel sword', 'spell_power_yrden', label);
	GMTestReport(found, "SWD-10 Forgotten Wolven steel sword's tooltip lists Yrden intensity: " + found + ", '" + label + "'");
	a = 'Dol Blathanna longsword _Stats';
	GMTestReport(GMTestSwdNear(GMTestSwdAbl(a, 'SlashingDamage'), 89) && GMTestSwdNear(GMTestSwdAbl(a, 'spell_power_aard'), 0.10) && GMTestSwdNear(GMTestSwdAbl(a, 'armor_reduction'), 20) && GMTestSwdNear(GMTestSwdAbl(a, 'critical_hit_damage_bonus'), 0.20) && GMTestSwdNear(GMTestSwdAbl(a, 'dismember_chance'), 0.10)
		&& GMTestSwdNear(GMTestSwdAbl(a, 'critical_hit_chance'), 0) && GMTestSwdNear(GMTestSwdAbl(a, 'human_exp_bonus_when_fatal'), 0) && dm.GetItemEnhancementSlotCount('Dol Blathanna longsword') == 2,
		"SWD-10 Sword of a Thousand Flowers: damage " + GMTestSwdAbl(a, 'SlashingDamage') + " (89, level 8), Aard " + GMTestSwdAbl(a, 'spell_power_aard') + " (0.10), armor penetration " + GMTestSwdAbl(a, 'armor_reduction') + " (20), crit damage " + GMTestSwdAbl(a, 'critical_hit_damage_bonus') + " (0.20), dismember " + GMTestSwdAbl(a, 'dismember_chance') + " (0.10), no crit chance or XP, slots " + dm.GetItemEnhancementSlotCount('Dol Blathanna longsword') + " (2)");
	a = 'White Widow of Dol Blathanna _Stats';
	GMTestReport(GMTestSwdNear(GMTestSwdAbl(a, 'SilverDamage'), 170) && GMTestSwdNear(GMTestSwdAbl(a, 'spell_power_igni'), 0.10) && GMTestSwdNear(GMTestSwdAbl(a, 'FireDamage'), 25) && GMTestSwdNear(GMTestSwdAbl(a, 'buff_apply_chance'), 0.08) && GMTestSwdNear(GMTestSwdAbl(a, 'dismember_chance'), 0.10)
		&& GMTestSwdNear(GMTestSwdAbl(a, 'nonhuman_exp_bonus_when_fatal'), 0) && dm.GetItemEnhancementSlotCount('White Widow of Dol Blathanna') == 2,
		"SWD-10 White Widow of the Valley of Flowers: silver " + GMTestSwdAbl(a, 'SilverDamage') + " (170, level 8), Igni " + GMTestSwdAbl(a, 'spell_power_igni') + " (0.10), fire " + GMTestSwdAbl(a, 'FireDamage') + " (25; audit F10, was 15), burning " + GMTestSwdAbl(a, 'buff_apply_chance') + " (0.08; was 0.05), dismember 0.10, no XP, 2 slots");
	a = 'Steel Vixen _Stats';
	GMTestReport(GMTestSwdNear(GMTestSwdAbl(a, 'SlashingDamage'), 121) && GMTestSwdNear(GMTestSwdAbl('Silver Vixen _Stats', 'SilverDamage'), 210) && GMTestSwdNear(GMTestSwdAbl(a, 'critical_hit_chance'), 0.15) && GMTestSwdNear(GMTestSwdAbl(a, 'critical_hit_damage_bonus'), 0.25) && GMTestSwdNear(GMTestSwdAbl(a, 'buff_apply_chance'), 0.10)
		&& GMTestSwdNear(GMTestSwdAbl(a, 'dismember_chance'), 0.10) && GMTestSwdNear(GMTestSwdAbl(a, 'dismember_chance_mult'), 0) && GMTestSwdNear(GMTestSwdAbl(a, 'focus_gain'), 0) && GMTestSwdNear(GMTestSwdAbl('Silver Vixen _Stats', 'focus_gain'), 0.05)
		&& dm.GetItemEnhancementSlotCount('Steel Vixen') == 2 && dm.GetItemEnhancementSlotCount('Silver Vixen') == 2,
		"SWD-10 Nine-Tailed Vixen swords: steel " + GMTestSwdAbl(a, 'SlashingDamage') + " (121, level 12), silver " + GMTestSwdAbl('Silver Vixen _Stats', 'SilverDamage') + " (210), crit " + GMTestSwdAbl(a, 'critical_hit_chance') + " (0.15), crit damage " + GMTestSwdAbl(a, 'critical_hit_damage_bonus') + " (0.25), bleeding " + GMTestSwdAbl(a, 'buff_apply_chance') + " (0.10), dismember 0.10, the silver one adrenaline " + GMTestSwdAbl('Silver Vixen _Stats', 'focus_gain') + " (0.05), 2 slots each");
	a = 'Top Notch Steel Sword _Stats';
	GMTestReport(GMTestSwdNear(GMTestSwdAbl(a, 'SlashingDamage'), 0) && GMTestSwdNear(GMTestSwdAbl(a, 'critical_hit_chance'), 0.10) && GMTestSwdNear(GMTestSwdAbl(a, 'critical_hit_damage_bonus'), 0.20) && GMTestSwdNear(GMTestSwdAbl(a, 'dismember_chance'), 0.10)
		&& GMTestSwdNear(GMTestSwdAbl('Top Notch Silver sword _Stats', 'spell_power'), 0.08) && GMTestSwdNear(GMTestSwdAbl('Top Notch Silver sword _Stats', 'critical_hit_damage_bonus'), 0.15) && GMTestSwdNear(GMTestSwdAbl('Top Notch Silver sword _Stats', 'dismember_chance'), 0.10)
		&& dm.GetItemEnhancementSlotCount('Top Notch Steel') == 3 && dm.GetItemEnhancementSlotCount('Top Notch Silver') == 3 && GMTestArmTag('Top Notch Steel', 'Autogen') && GMTestArmTag('Top Notch Silver', 'Autogen'),
		"SWD-10 Top Notch swords, level-scaled: steel crit from " + GMTestSwdAbl(a, 'critical_hit_chance') + " (0.10-0.20), crit damage from " + GMTestSwdAbl(a, 'critical_hit_damage_bonus') + " (0.20-0.40); silver sign intensity from " + GMTestSwdAbl('Top Notch Silver sword _Stats', 'spell_power') + " (0.08-0.15), crit damage from " + GMTestSwdAbl('Top Notch Silver sword _Stats', 'critical_hit_damage_bonus') + " (0.15-0.30); dismember 0.10, 3 slots, Autogen kept");
}

function GMTestSwdMult(inv : CInventoryComponent, id : SItemUniqueId, attr : name) : float
{
	var v : SAbilityAttributeValue;

	v = inv.GetItemAttributeValue(id, attr);
	return v.valueMultiplicative;
}

// SWD-10 save impact: the swords Geralt owns, as the inventory reads them (damage, bonuses, slots).
exec function gmtest_swd10_owned()
{
	var inv : CInventoryComponent;
	var ids, more : array<SItemUniqueId>;
	var i : int;

	inv = thePlayer.GetInventory();
	ids = inv.GetItemsByCategory('steelsword');
	more = inv.GetItemsByCategory('silversword');
	for(i = 0; i < more.Size(); i += 1)
		ids.PushBack(more[i]);
	for(i = 0; i < ids.Size(); i += 1)
		LogChannel('GMTest', "INFO owned " + inv.GetItemName(ids[i]) + ": slashing " + CalculateAttributeValue(inv.GetItemAttributeValue(ids[i], 'SlashingDamage')) + ", silver " + CalculateAttributeValue(inv.GetItemAttributeValue(ids[i], 'SilverDamage'))
			+ ", attack power " + GMTestSwdMult(inv, ids[i], 'attack_power') + ", Yrden " + GMTestSwdMult(inv, ids[i], 'spell_power_yrden') + ", crit " + CalculateAttributeValue(inv.GetItemAttributeValue(ids[i], 'critical_hit_chance'))
			+ ", crit damage " + CalculateAttributeValue(inv.GetItemAttributeValue(ids[i], 'critical_hit_damage_bonus')) + ", dismember " + CalculateAttributeValue(inv.GetItemAttributeValue(ids[i], 'dismember_chance'))
			+ ", XP " + CalculateAttributeValue(inv.GetItemAttributeValue(ids[i], 'human_exp_bonus_when_fatal')) + "/" + CalculateAttributeValue(inv.GetItemAttributeValue(ids[i], 'nonhuman_exp_bonus_when_fatal'))
			+ ", slots " + inv.GetItemEnhancementSlotsCount(ids[i]) + ", level " + inv.GetItemLevel(ids[i]) + ", NetflixSetMinor " + inv.ItemHasTag(ids[i], 'NetflixSetMinor'));
}

// SWD-08 (audit F1): draws a sword in game (by default the Wolf relic, whose anim_actions legacy moved to
// the steel sword's draw and holster acts) from the silver slot and logs, for 4 s, which draw and holster
// activation notifications Geralt's behaviour graph sends and when the sword is held (gmtest_swd08_holster()
// sheathes it and logs the same).
@addField(W3PlayerWitcher)
var gmTestSwdDrawId : SItemUniqueId;
@addField(W3PlayerWitcher)
var gmTestSwdDrawTime : float;
@addField(W3PlayerWitcher)
var gmTestSwdDrawSeen : array<name>;
@addField(W3PlayerWitcher)
var gmTestSwdDrawHeld : bool;

exec function gmtest_swd08_draw(optional itemName : name)
{
	var w : W3PlayerWitcher;
	var ids : array<SItemUniqueId>;

	w = GetWitcherPlayer();
	if(!IsNameValid(itemName))
		itemName = 'WitcherSilverWolf';
	ids = w.inv.AddAnItem(itemName, 1, true, true, false);
	w.EquipItemInGivenSlot(ids[0], EES_SilverSword, false);
	w.gmTestSwdDrawId = ids[0];
	w.gmTestSwdDrawTime = 0;
	w.gmTestSwdDrawSeen.Clear();
	w.gmTestSwdDrawHeld = false;
	w.OnEquipMeleeWeapon(PW_Silver, true);
	w.AddTimer('GMTestSwdDrawWatch', 0, true);
	LogChannel('GMTest', "INFO SWD-08 drawing " + itemName + " (equipped " + w.inv.IsItemMounted(ids[0]) + ")");
}

exec function gmtest_swd08_holster()
{
	var w : W3PlayerWitcher;

	w = GetWitcherPlayer();
	w.gmTestSwdDrawTime = 0;
	w.gmTestSwdDrawSeen.Clear();
	w.gmTestSwdDrawHeld = true;
	w.OnEquipMeleeWeapon(PW_None, true);
	w.AddTimer('GMTestSwdDrawWatch', 0, true);
}

@addMethod(W3PlayerWitcher)
timer function GMTestSwdDrawWatch(dt : float, id : int)
{
	var acts : array<name>;
	var i : int;

	acts.PushBack('draw_steel_sword_back_act');
	acts.PushBack('draw_silver_sword_back_act');
	acts.PushBack('holster_steel_sword_back_act');
	acts.PushBack('holster_silver_sword_back_act');
	gmTestSwdDrawTime += dt;
	for(i = 0; i < acts.Size(); i += 1)
		if(!gmTestSwdDrawSeen.Contains(acts[i]) && BehaviorNodeActivationNotificationReceived(acts[i]))
		{
			gmTestSwdDrawSeen.PushBack(acts[i]);
			LogChannel('GMTest', "INFO SWD-08 " + gmTestSwdDrawTime + " s: notification " + acts[i] + ", held " + inv.IsItemHeld(gmTestSwdDrawId));
		}
	if(inv.IsItemHeld(gmTestSwdDrawId) != gmTestSwdDrawHeld)
	{
		gmTestSwdDrawHeld = !gmTestSwdDrawHeld;
		LogChannel('GMTest', "INFO SWD-08 " + gmTestSwdDrawTime + " s: held " + gmTestSwdDrawHeld);
	}
	if(gmTestSwdDrawTime > 4)
	{
		RemoveTimer('GMTestSwdDrawWatch');
		LogChannel('GMTest', "INFO SWD-08 after 4 s: held " + inv.IsItemHeld(gmTestSwdDrawId) + ", mounted " + inv.IsItemMounted(gmTestSwdDrawId) + ", notifications seen " + gmTestSwdDrawSeen.Size());
	}
}
