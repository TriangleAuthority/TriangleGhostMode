// Whole-port fix round (2026-11-03): checks on the shipped XML data that no single area owns (the abilities two
// DLC files extend, NG+ values). gmtest_regress() and gmtest_panel() call GMTest_data() and GMTest_data_after(),
// so checks go here and gmTests.ws's lists stay unchanged.
//   GMTest_data()        in gmtest_regress(): checks that need no fight, input or menu, each restoring what it changes
//   GMTest_data_after()  in gmtest_panel(): checks that read the game a frame or more after gmtest_regress()

exec function gmtest_data()
{
	thePlayer.GMTestCount(true, true);
	GMTest_data();
	LogChannel('GMTest', "SUMMARY data: " + thePlayer.gmTestPassed + " passed, " + thePlayer.gmTestFailed + " failed");
}

// One attribute of an ability as the definitions manager reads it (every DLC entry of the name applied): its base,
// multiplicative and additive sums; adds a line to `bad` when they differ.
function GMTestDataAbl(abl : name, attr : name, b : float, m : float, a : float, out bad : string)
{
	var mn, mx : SAbilityAttributeValue;

	theGame.GetDefinitionsManager().GetAbilityAttributeValue(abl, attr, mn, mx);
	if(AbsF(mn.valueBase - b) < 0.0005 && AbsF(mn.valueMultiplicative - m) < 0.0005 && AbsF(mn.valueAdditive - a) < 0.0005)
		return;
	bad += " " + attr + " reads b " + mn.valueBase + " m " + mn.valueMultiplicative + " a " + mn.valueAdditive
		+ " (expected " + b + ", " + m + ", " + a + ");";
}

function GMTestDataTag(abl : name, tag : name, out bad : string)
{
	if(!theGame.GetDefinitionsManager().AbilityHasTag(abl, tag))
		bad += " no tag " + tag + ";";
}

function GMTestDataReport(label : string, bad : string)
{
	GMTestReport(bad == "", "data " + label + bad);
}

// Abilities extended by two or more DLC entries (whole-port audit A1-9, A2-4, A8-1, C3-6): every attribute each entry
// sets, read from the game, one check per entry, so an entry the game dropped fails (vanilla's value comes back).
// Plus one attribute vanilla's entry has and no DLC entry lists, which every extend must keep.
function GMTest_data_extends()
{
	var bad : string;
	var n : name;
	var i : int;
	var heavies : array<name>;

	heavies.PushBack('attack_heavy');
	heavies.PushBack('attack_heavy_special');
	heavies.PushBack('attack_super_heavy');
	for(i = 0; i < heavies.Size(); i += 1)
	{
		n = heavies[i];
		// DMG-01, gm_damage.xml: no attack power bonus (vanilla mult 0.15, super heavy 0.5)
		bad = "";
		GMTestDataAbl(n, 'attack_power', 0, 0, 0, bad);
		GMTestDataReport(NameToString(n) + " gm_damage.xml (DMG-01)", bad);
		// SKL-07, gm_adrenaline.xml: no adrenaline of its own (vanilla base 0.1, super heavy 0.025)
		bad = "";
		GMTestDataAbl(n, 'focus_gain', 0, 0, 0, bad);
		if(n != 'attack_super_heavy')
			GMTestDataAbl(n, 'focus_hit_drain_mod', 0, 1.5, 0, bad);  // vanilla's, kept
		GMTestDataReport(NameToString(n) + " gm_adrenaline.xml (SKL-07)", bad);
	}

	// sword_s1 (classic Whirl): STAM-09/STAM-06 in gm_skills.xml, SKL-03 in gm_skill_trees.xml
	bad = "";
	GMTestDataAbl('sword_s1', 'stamina_cost_per_sec', 0, 0, 50, bad);
	GMTestDataAbl('sword_s1', 'stamina_delay', 0, 0, 1, bad);
	GMTestDataAbl('sword_s1', 'stamina_cost_reduction_after_1', 0, 0, 0.15, bad);
	GMTestDataAbl('sword_s1', 'focus_cost_per_sec_initial', 0, 0, 1, bad);  // vanilla's, kept
	GMTestDataReport("sword_s1 gm_skills.xml (STAM-09)", bad);
	bad = "";
	GMTestDataAbl('sword_s1', 'whirl_dmg_bonus', 0, 0.01, 0, bad);
	GMTestDataAbl('sword_s1', 'whirl_dmg_reduction', 0, 0.25, 0, bad);
	GMTestDataAbl('sword_s1', 'whirl_dmg_reduction_bonus_after_1', 0, 0.0625, 0, bad);
	GMTestDataAbl('sword_s1', 'cost_reduction', 0, 0.167, 0, bad);  // vanilla's, kept
	GMTestDataReport("sword_s1 gm_skill_trees.xml (SKL-03)", bad);

	// sword_s21 (classic Muscle Memory): DEF-07's tags in gm_defense.xml, SKL-07's adrenaline in gm_skill_trees.xml
	bad = "";
	GMTestDataTag('sword_s21', 'sword_s21', bad);
	GMTestDataTag('sword_s21', 'attack_light', bad);
	GMTestDataTag('sword_s21', 'counter_attack_light', bad);
	GMTestDataReport("sword_s21 gm_defense.xml (DEF-07)", bad);
	bad = "";
	GMTestDataAbl('sword_s21', 'light_focus_gain', 0, 0, 0.03, bad);
	GMTestDataAbl('sword_s21', 'attack_power', 0, 0.1, 0, bad);  // vanilla's, kept
	GMTestDataReport("sword_s21 gm_skill_trees.xml (SKL-07)", bad);

	// magic_s4 (Active Shield): STAM's channel cost and SKL-11's shield, both in gm_skills.xml
	bad = "";
	GMTestDataAbl('magic_s4', 'stamina_cost_per_sec', 0, 0, 20, bad);
	GMTestDataAbl('magic_s4', 'stamina_delay', 0, 0, 1, bad);
	GMTestDataAbl('magic_s4', 'stamina_cost_reduction_after_1', 0, 0.5, 0, bad);  // vanilla's, kept
	GMTestDataReport("magic_s4 gm_skills.xml first entry (STAM)", bad);
	bad = "";
	GMTestDataAbl('magic_s4', 'shield_health_factor', 0, 0, 2, bad);
	GMTestDataAbl('magic_s4', 'shield_healing_factor', 0, 0, 0.334, bad);
	GMTestDataReport("magic_s4 gm_skills.xml second entry (SKL-11)", bad);

	// ConGeralt: five entries in gm_stats.xml
	bad = "";
	GMTestDataAbl('ConGeralt', 'staminaRegen', 1, 0.15, 0, bad);
	GMTestDataAbl('ConGeralt', 'staminaRegenGuarded', 0, 0.15, 0, bad);
	GMTestDataReport("ConGeralt gm_stats.xml stamina regen (STAM-04)", bad);
	bad = "";
	GMTestDataAbl('ConGeralt', 'light_action_stamina_cost', 6.666, 0, 0, bad);
	GMTestDataAbl('ConGeralt', 'heavy_action_stamina_cost', 10, 0, 0, bad);
	GMTestDataAbl('ConGeralt', 'parry_stamina_cost', 5, 0, 0, bad);
	GMTestDataAbl('ConGeralt', 'counter_stamina_cost', 6.666, 0, 0, bad);
	GMTestDataAbl('ConGeralt', 'dodge_stamina_cost', 5, 0, 0, bad);
	GMTestDataAbl('ConGeralt', 'evade_stamina_cost', 5, 0, 0, bad);
	GMTestDataAbl('ConGeralt', 'roll_stamina_cost', 10, 0, 0, bad);
	GMTestDataAbl('ConGeralt', 'sprint_stamina_cost_per_sec', 10, 0, 0, bad);
	GMTestDataAbl('ConGeralt', 'jump_stamina_cost', 10, 0, 0, bad);
	GMTestDataAbl('ConGeralt', 'usable_item_stamina_cost', 5, 0, 0, bad);
	GMTestDataReport("ConGeralt gm_stats.xml action costs (STAM-03)", bad);
	bad = "";
	GMTestDataAbl('ConGeralt', 'light_action_stamina_delay', 1, 0, 0, bad);
	GMTestDataAbl('ConGeralt', 'heavy_action_stamina_delay', 1, 0, 0, bad);
	GMTestDataAbl('ConGeralt', 'parry_stamina_delay', 1, 0, 0, bad);
	GMTestDataAbl('ConGeralt', 'counter_stamina_delay', 1, 0, 0, bad);
	GMTestDataAbl('ConGeralt', 'dodge_stamina_delay', 1, 0, 0, bad);
	GMTestDataAbl('ConGeralt', 'evade_stamina_delay', 1, 0, 0, bad);
	GMTestDataAbl('ConGeralt', 'roll_stamina_delay', 1, 0, 0, bad);
	GMTestDataAbl('ConGeralt', 'sprint_stamina_delay', 1, 0, 0, bad);
	GMTestDataAbl('ConGeralt', 'jump_stamina_delay', 1, 0, 0, bad);
	GMTestDataAbl('ConGeralt', 'usable_item_stamina_delay', 1, 0, 0, bad);
	GMTestDataReport("ConGeralt gm_stats.xml action delays (STAM-06)", bad);
	bad = "";
	GMTestDataAbl('ConGeralt', 'vitalityRegen', 0, 0, 0, bad);
	GMTestDataAbl('ConGeralt', 'vitalityCombatRegen', 0, 0, 0, bad);
	GMTestDataReport("ConGeralt gm_stats.xml Vitality regen (OPT-02)", bad);
	bad = "";
	GMTestDataAbl('ConGeralt', 'poison_resistance_perc', 0, 0, 0, bad);
	GMTestDataAbl('ConGeralt', 'bleeding_resistance_perc', 0, 0, 0, bad);
	GMTestDataAbl('ConGeralt', 'swimming_stamina_cost_per_sec', 15, 0, 0, bad);  // vanilla's, kept
	GMTestDataReport("ConGeralt gm_stats.xml resistances (OPT-02)", bad);
}

// The item data the fix round changed (whole-port audit, the owner's answers, 2026-11-03), read from the game.
function GMTest_data_items()
{
	var dm : CDefinitionsManagerAccessor;
	var rec : SAlchemyRecipe;
	var inv : CInventoryComponent;
	var ids : array<SItemUniqueId>;
	var abls : array<name>;
	var q, i : int;
	var bad : string;

	dm = theGame.GetDefinitionsManager();
	// A6-1: Hearts of Stone's auctioned painting without Blood and Wine's painting-quest tag (legacy)
	GMTestReport(!dm.ItemHasTag('q603_auctioned_painting', 'mq7024_picture') && dm.ItemHasTag('q603_auctioned_painting', 'Painting'),
		"data A6-1 q603_auctioned_painting has no mq7024_picture tag, keeps Painting");
	// A6-2: 5.x's new gear trades as its counterpart (mod_legendary); the top Netflix schematic as the Wolf one (none)
	GMTestReport(dm.ItemHasTag('Netflix steel sword 1', 'mod_legendary') && dm.ItemHasTag('Dol Blathanna Armor', 'mod_legendary')
		&& dm.ItemHasTag('Top Notch Silver', 'mod_legendary') && dm.ItemHasTag('White Widow of Dol Blathanna', 'mod_legendary')
		&& !dm.ItemHasTag('Netflix Armor schematic 2', 'mod_legendary') && dm.ItemHasTag('Netflix Armor schematic 2', 'mod_crafting'),
		"data A6-2 DE2 items carry their counterparts' price tags (Netflix sword, Dol Blathanna armor, Top Notch, White Widow mod_legendary; the top Netflix schematic none)");
	// A4-3: the Netflix armor at exactly its tier's level (21/35/41)
	bad = "";
	GMTestDataAbl('Netflix Armor _Stats', 'armor', 130, 0, 0, bad);
	GMTestDataAbl('Netflix Boots 1 _Stats', 'armor', 75, 0, 0, bad);
	GMTestDataAbl('Netflix Gloves 2 _Stats', 'armor', 83, 0, 0, bad);
	GMTestDataAbl('Netflix Pants 2 _Stats', 'armor', 87, 0, 0, bad);
	GMTestDataReport("A4-3 Netflix armor at levels 21/35/41 (chest 130, boots 1 75, gloves 2 83, trousers 2 87)", bad);
	// C3-4: the pheromone formulas are quest formulas (legacy)
	bad = "";
	rec = getAlchemyRecipeFromName('Recipe for Bear Pheromone Potion 1');
	if(rec.cookedItemType != EACIT_Quest)
		bad += " bear " + rec.cookedItemType;
	rec = getAlchemyRecipeFromName('Recipe for Drowner Pheromone Potion 1');
	if(rec.cookedItemType != EACIT_Quest)
		bad += " drowner " + rec.cookedItemType;
	rec = getAlchemyRecipeFromName('Recipe for Nekker Pheromone Potion 1');
	if(rec.cookedItemType != EACIT_Quest)
		bad += " nekker " + rec.cookedItemType;
	GMTestDataReport("C3-4 bear, drowner and nekker pheromone formulas are quest formulas", bad);
	// C3-3: the Jug's icon (legacy's); Melitele figurine still defined with legacy's node after its abilities block
	GMTestReport(dm.GetItemIconPath('Jug') == "icons/inventory/ingredients/junk/glass_jug_64x64.png" && dm.GetItemCategory('Melitele figurine') == 'junk',
		"data C3-3 the Jug's icon " + dm.GetItemIconPath('Jug') + " (glass_jug); Melitele figurine defined (" + dm.GetItemCategory('Melitele figurine') + ")");
	inv = GetWitcherPlayer().GetHorseManager().GetInventoryComponent();
	ids = inv.AddAnItem('Melitele figurine', 1, true, true);
	if(ids.Size() > 0)
	{
		q = inv.GetItemQuality(ids[0]);
		inv.GetItemAbilities(ids[0], abls);
		LogChannel('GMTest', "INFO data C3-3 Melitele figurine: quality " + q + ", " + abls.Size() + " abilities (legacy's <a>Master _Stats</a> after the block)");
		for(i = 0; i < ids.Size(); i += 1)
			inv.RemoveItem(ids[i], inv.GetItemQuantity(ids[i]));
	}
}

function GMTest_data()
{
	GMTest_data_extends();
	GMTest_data_items();
}

function GMTest_data_after()
{
}
