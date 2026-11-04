// In-game tests for ARM (armor and armor sets). See docs/features/arm.md.

// Adds gear to Geralt (equipping the given pieces) and returns the first id.
function GMTestArmAdd(itemName : name, equip : bool) : SItemUniqueId
{
	var ids : array<SItemUniqueId>;

	var tries : int;

	ids = thePlayer.GetInventory().AddAnItem(itemName, 1, true, true, false);
	// ITEM-02: a level-scaled piece can get Geralt's level + 1, which he cannot wear: take another copy
	while(equip && ids.Size() > 0 && tries < 20 && thePlayer.GetInventory().GetItemLevel(ids[0]) > thePlayer.GetLevel())
	{
		thePlayer.GetInventory().RemoveItem(ids[0], 1);
		ids = thePlayer.GetInventory().AddAnItem(itemName, 1, true, true, false);
		tries += 1;
	}
	if(equip && ids.Size() > 0)
		GetWitcherPlayer().EquipItem(ids[0]);
	return ids[0];
}

// Save impact: gives Geralt school and generic armor (four lower-tier Feline pieces equipped) and
// saves into a new manual slot, so a later build can check what items owned before it read.
exec function gmtest_arm_mksave()
{
	GMTestArmAdd('Lynx Armor', true);
	GMTestArmAdd('Lynx Boots 1', true);
	GMTestArmAdd('Lynx Gloves 1', true);
	GMTestArmAdd('Lynx Pants 1', true);
	GMTestArmAdd('Lynx Armor 4', false);
	GMTestArmAdd('Gryphon Armor 1', false);
	GMTestArmAdd('Bear Armor', false);
	GMTestArmAdd('Wolf Armor', false);
	GMTestArmAdd('Red Wolf Armor 1', false);
	LogChannel('GMTest', "ARM save: gear added, saving into a new manual slot");
	theGame.SaveGame(SGT_Manual, -1);
}

// ARM's situation-free checks (in gmtest_regress()).
function GMTest_arm()
{
	GMTest_arm05();
	GMTest_arm02();
	GMTest_arm01();
	GMTest_arm01_hair();	// fix3
	GMTest_arm04();
	GMTest_arm07();
	GMTest_arm08();
	GMTest_arm06();
	GMTest_arm09();
	GMTest_arm10();
	GMTest_arm11();
	GMTest_arm12();
	GMTest_arm13();
	GMTest_arm03();
	GMTest_arm14();
	GMTest_arm15();
	GMTest_arm_audit();
	GMTest_arm_dne();
}

// Crafted armor carries legacy's DoNotEnhance (the owner's decision on the SWD audit's F4, 2026-10-19),
// so a new piece gets no random bonus on top of its fixed stats; an untagged piece of the same quality
// still does (the control). The counting is GMTestSwdRandomBonuses (gmTestsSwd.ws). NG+ data: --verify.
function GMTest_arm_dne()
{
	var a, b, c, d, ab, bb, cb, db : int;

	GMTestReport(GMTestArmTag('Heavy armor 01_crafted', 'DoNotEnhance') && GMTestArmTag('Medium armor 01_crafted', 'DoNotEnhance') && GMTestArmTag('Light armor 08_crafted', 'DoNotEnhance')
		&& GMTestArmTag('Boots 01_crafted', 'DoNotEnhance') && GMTestArmTag('Heavy gloves 01_crafted', 'DoNotEnhance') && GMTestArmTag('Pants 01_crafted', 'DoNotEnhance') && !GMTestArmTag('Burning Rose Armor', 'DoNotEnhance'),
		"ARM DoNotEnhance on crafted armor: heavy armor 01, medium armor 01, light armor 08, boots 01, heavy gloves 01, trousers 01 (not on the Burning Rose armor)");
	a = GMTestSwdRandomBonuses('Heavy armor 01_crafted', 8, ab);
	b = GMTestSwdRandomBonuses('Medium armor 01_crafted', 8, bb);
	c = GMTestSwdRandomBonuses('Boots 01_crafted', 8, cb);
	d = GMTestSwdRandomBonuses('Burning Rose Armor', 8, db);
	GMTestReport(a == 0 && b == 0 && c == 0 && d == 8,
		"ARM new armor with a random bonus, of 8 each: crafted heavy armor 01 (quality 3) " + a + " (0), crafted medium armor 01 (quality 2) " + b + " (0), crafted boots 01 (quality 3) " + c + " (0); control, the untagged Burning Rose armor (quality 3) " + d + " (8); most abilities " + ab + "/" + bb + "/" + cb + "/" + db);
}

// ARM audit (2026-10-18) fixes, situation-free: the generated items against legacy's values (F2, F3,
// F4; F9 is NG+ data, which a regular game does not read: tools/gen_arm_items.py --verify checks it),
// the Fully Armed achievement's set tags (F5), the Bear sound bank (F6) and the tooltip's class (F8).
// Fully Armed with gear worn: gmtest_arm_fullyarmed(); the HUD counter (F7) is seen on screen.
function GMTest_arm_audit()
{
	var dm : CDefinitionsManagerAccessor;
	var w : W3PlayerWitcher;
	var inv : CInventoryComponent;
	var tox : float;
	var id : SItemUniqueId;
	var tooltip : W3TooltipComponent;
	var data : CScriptedFlashObject;
	var enchanted : bool;

	dm = theGame.GetDefinitionsManager();
	w = GetWitcherPlayer();
	inv = w.GetInventory();

	// F2, F3: DA5's and DA6's values where 5.x lowered a stat legacy had left at 1.32's
	GMTestReport(GMTestArmNear(GMTestArmAbl('Gryphon Boots 5 _Stats', 'rending_resistance_perc'), 0.06) && GMTestArmNear(GMTestArmAbl('Lynx Gloves 3 _Stats', 'rending_resistance_perc'), 0.03) && GMTestArmNear(GMTestArmAbl('Wolf Pants 1 _Stats', 'rending_resistance_perc'), 0.07),
		"ARM audit F2: legacy's rending resistance: grandmaster Griffin boots " + GMTestArmAbl('Gryphon Boots 5 _Stats', 'rending_resistance_perc') + " (expected 0.06; 5.x 0.04), Feline gloves 3 " + GMTestArmAbl('Lynx Gloves 3 _Stats', 'rending_resistance_perc') + " (0.03), Wolven trousers 1 " + GMTestArmAbl('Wolf Pants 1 _Stats', 'rending_resistance_perc') + " (0.07)");
	tox = GMTestArmAbl('Red Wolf Armor 1 _Stats', 'toxicity') + GMTestArmAbl('Red Wolf Boots 1 _Stats', 'toxicity') + GMTestArmAbl('Red Wolf Gloves 1 _Stats', 'toxicity') + GMTestArmAbl('Red Wolf Pants 1 _Stats', 'toxicity');
	GMTestReport(GMTestArmNear(tox, 25), "ARM audit F3: the first-tier Manticore set's toxicity +" + tox + " (expected legacy's 25, DA6; was 20)");

	// F4: class texts of the pieces legacy moved between classes, icons, the quest-equipped pieces' stats, the grandmaster Feline look
	GMTestReport(dm.GetItemLocalisationKeyDesc('Boots 02') == "item_category_medium_armor_description" && dm.ItemHasTag('Boots 02', 'MediumArmor') && dm.GetItemLocalisationKeyDesc('Pants 03') == "item_category_light_armor_description" && dm.ItemHasTag('Pants 03', 'LightArmor'),
		"ARM audit F4: class texts follow legacy's classes: Boots 02 " + dm.GetItemLocalisationKeyDesc('Boots 02') + ", Pants 03 " + dm.GetItemLocalisationKeyDesc('Pants 03'));
	GMTestReport(dm.GetItemIconPath('Heavy boots 03') == "icons/inventory/armors/common_heavy_boots_lvl3_64x128.png", "ARM audit F4: legacy's icons (Heavy boots 03: " + dm.GetItemIconPath('Heavy boots 03') + ")");
	GMTestReport(GMTestArmHasAbility('Autogen Boots', 'Autogen Boots _Stats') && GMTestArmHasAbility('Autogen Boots', 'Default armor _Stats') && !GMTestArmHasAbility('Autogen Boots', 'Starting Boots _Stats') && GMTestArmHasAbility('Autogen Pants', 'Autogen Pants _Stats') && GMTestArmNear(GMTestArmAbl('Autogen Pants _Stats', 'slashing_resistance_perc'), 0.03),
		"ARM audit F4: the quest-equipped Autogen boots and trousers have legacy's abilities (trousers slashing " + GMTestArmAbl('Autogen Pants _Stats', 'slashing_resistance_perc') + ", expected 0.03)");
	GMTestReport(StrEndsWith(dm.GetItemEquipTemplate('Lynx Armor 4'), "t_02_mg__lynx_lvl5.w2ent"), "ARM audit F4: the grandmaster Feline armor's look: " + dm.GetItemEquipTemplate('Lynx Armor 4') + " (legacy's t_02_mg__lynx_lvl5)");
	GMTestReport(dm.GetItemLocalisationKeyName('q108 Medium armor 10') == "item_name_heavy_armor_03" && dm.GetItemLocalisationKeyDesc('q108 Medium armor 10') == "item_category_heavy_armor_description" && StrEndsWith(dm.GetItemEquipTemplate('q108 Medium armor 10'), "t_01_mg__common_heavy_lvl3.w2ent") && dm.GetItemIconPath('q108 Medium armor 10') == "icons/inventory/armors/common_heavy_lvl3_01_64x128.png" && dm.ItemHasTag('q108 Medium armor 10', 'HeavyArmor'),
		"ARM audit F4b: Yoana's reward armor as legacy: name " + dm.GetItemLocalisationKeyName('q108 Medium armor 10') + " (" + GetLocStringByKeyExt(dm.GetItemLocalisationKeyName('q108 Medium armor 10')) + "), " + dm.GetItemLocalisationKeyDesc('q108 Medium armor 10') + ", look " + dm.GetItemEquipTemplate('q108 Medium armor 10') + ", icon " + dm.GetItemIconPath('q108 Medium armor 10'));

	// F5: lower-tier pieces report their set for the Fully Armed achievement's progress
	id = GMTestArmAdd('Lynx Boots 1', false);
	GMTestReport(inv.DetectTagOfASet(id) == 'LynxSetMinor', "ARM audit F5: a lower-tier Feline piece's set tag for Fully Armed: " + inv.DetectTagOfASet(id) + " (expected LynxSetMinor)");
	inv.RemoveItem(id, 1);

	// F6: the Bear set's bank is loaded without Bear pieces
	GMTestReport(w.GetSetPartsEquipped(EIST_Bear) == 0 && theSound.SoundIsBankLoaded("ep2_setbonus_bear.bnk"), "ARM audit F6: the Bear sound bank is loaded with " + w.GetSetPartsEquipped(EIST_Bear) + " Bear pieces worn (for Quen Discharge)");

	// F8: the tooltip does not mark the class as changed by Heft (Glyphword 4)
	if(!w.GetItemEquippedOnSlot(EES_Armor, id) || !theGame.GetHud())
	{
		GMTestReport(false, "ARM audit F8: needs an armor worn and the HUD");
		return;
	}
	tooltip = new W3TooltipComponent in w;
	tooltip.initialize(inv, theGame.GetHud().GetHudFlashValueStorage());
	tooltip.setCurrentInventory(inv);
	w.AddAbility('Glyphword 4 _Stats', false);
	data = tooltip.GetBaseItemData(id, inv);
	if(data)
		enchanted = data.GetMemberFlashBool("hasEnchantedType");
	w.RemoveAbility('Glyphword 4 _Stats');
	GMTestReport(data && !enchanted, "ARM audit F8: an armor's tooltip with Heft's ability on Geralt: class shown as changed " + enchanted + " (expected false, DA7)");
}

// ARM audit F5 with gear worn (needs setlevel(50) first): six lower-tier Feline pieces of mixed
// tiers, and six grandmaster Bear pieces without the school crossbow, make a full set for Fully
// Armed. Puts the gear back.
exec function gmtest_arm_fullyarmed()
{
	var w : W3PlayerWitcher;
	var names : array<name>;
	var added, old : array<SItemUniqueId>;
	var id : SItemUniqueId;

	w = GetWitcherPlayer();
	if(w.GetItemEquippedOnSlot(EES_Armor, id)) old.PushBack(id);
	if(w.GetItemEquippedOnSlot(EES_Boots, id)) old.PushBack(id);
	if(w.GetItemEquippedOnSlot(EES_Gloves, id)) old.PushBack(id);
	if(w.GetItemEquippedOnSlot(EES_Pants, id)) old.PushBack(id);
	if(w.GetItemEquippedOnSlot(EES_SteelSword, id)) old.PushBack(id);
	if(w.GetItemEquippedOnSlot(EES_SilverSword, id)) old.PushBack(id);

	names.PushBack('Lynx Armor 1'); names.PushBack('Lynx Boots 2'); names.PushBack('Lynx Gloves 1'); names.PushBack('Lynx Pants 3');
	names.PushBack('Lynx School steel sword 1'); names.PushBack('Lynx School silver sword 2');
	GMTestArmWear(names, added);
	GMTestReport(w.HasAllItemsFromSet('LynxSetMinor') && !w.HasAllItemsFromSet('LynxSet'), "ARM audit F5: six lower-tier Feline pieces of mixed tiers make a full set for Fully Armed: " + w.HasAllItemsFromSet('LynxSetMinor'));
	GMTestArmRestore(added, added);
	added.Clear();
	names.Clear();
	names.PushBack('Bear Armor 4'); names.PushBack('Bear Boots 5'); names.PushBack('Bear Gloves 5'); names.PushBack('Bear Pants 5');
	names.PushBack('Bear School steel sword 4'); names.PushBack('Bear School silver sword 4');
	GMTestArmWear(names, added);
	GMTestReport(w.HasAllItemsFromSet('BearSet') && !w.GetItemEquippedOnSlot(EES_RangedWeapon, id), "ARM audit F5: six grandmaster Bear pieces without the school crossbow make a full set: " + w.HasAllItemsFromSet('BearSet'));
	GMTestArmRestore(added, old);
}

// Whether an item definition has a tag.
function GMTestArmTag(itemName : name, tag : name) : bool
{
	return theGame.GetDefinitionsManager().ItemHasTag(itemName, tag);
}

// Whether an item definition lists an ability.
function GMTestArmHasAbility(itemName : name, abilityName : name) : bool
{
	var abls : array<name>;
	var weights : array<float>;
	var minA, maxA : int;

	theGame.GetDefinitionsManager().GetItemAbilitiesWithWeights(itemName, true, abls, weights, minA, maxA);
	return abls.Contains(abilityName);
}

// ARM-05: set tags from legacy (lower tiers minor, Viper and Tesham Mutna pieces counted), the
// replaced entries keeping their content (base game, Hearts of Stone, Blood and Wine, free DLC).
function GMTest_arm05()
{
	GMTestReport(GMTestArmTag('Lynx Armor', 'LynxSetMinor') && GMTestArmTag('Lynx Armor', 'SetBonusPiece') && !GMTestArmTag('Lynx Armor', 'LynxSet'), "ARM-05 Feline armor (tier 1): LynxSetMinor and SetBonusPiece, no LynxSet");
	GMTestReport(GMTestArmTag('Gryphon Boots 3', 'GryphonSetMinor') && GMTestArmTag('Bear Pants 2', 'BearSetMinor') && GMTestArmTag('Wolf Gloves 1', 'WolfSetMinor'), "ARM-05 lower tiers of Griffin, Bear and Wolf tagged minor");
	GMTestReport(GMTestArmTag('Lynx Armor 4', 'LynxSet') && GMTestArmTag('Lynx Armor 4', 'SetBonusPiece'), "ARM-05 grandmaster Feline armor (Blood and Wine) keeps LynxSet");
	GMTestReport(GMTestArmTag('EP1 Witcher Armor', 'ViperSet') && GMTestArmTag('EP1 Witcher Armor', 'SetBonusPiece') && GMTestArmTag('EP1 Viper School steel sword', 'SetBonusPiece'), "ARM-05 Viper gear (Hearts of Stone) is a set piece");
	GMTestReport(GMTestArmTag('q704 vampire silver sword', 'VampireSet') && GMTestArmTag('q704 vampire silver sword', 'SetBonusPiece'), "ARM-05 Tesham Mutna silver sword (Blood and Wine) is a set piece");
	GMTestReport(GMTestArmTag('NGP Wolf Armor', 'SetBonusPiece') && GMTestArmTag('NGP Wolf Armor', 'WolfSet'), "ARM-05 NG+ Wolven armor (free DLC) is a set piece");
	GMTestReport(GMTestArmHasAbility('Lynx Armor', 'Lynx Armor _Stats') && GMTestArmHasAbility('EP1 Witcher Armor', 'EP1 Witcher Armor _Stats') && GMTestArmHasAbility('NGP Wolf Armor', 'NGP Wolf Armor _Stats') && GMTestArmHasAbility('q704 vampire silver sword', 'q704 vampire silver sword _Stats')
		&& theGame.GetDefinitionsManager().GetItemCategory('EP1 Witcher Armor') == 'armor' && theGame.GetDefinitionsManager().GetItemEnhancementSlotCount('NGP Wolf Armor') == 2, "ARM-05 replaced entries keep their abilities and category (slots: legacy's, ARM-01)");
	GMTestReport(GetWitcherPlayer().ItemSetTypeToItemSetBonus(EIST_Lynx_Minor, 1) == EISB_Lynx_1 && GetWitcherPlayer().ItemSetTypeToItemSetBonus(EIST_Lynx_Minor, 2) == EISB_Undefined && GMGetNumItemsRequiredForFullSet(EIST_KaerMorhen) == 4, "ARM-05 minor tiers give the first bonus only; Kaer Morhen's full set is 4");
}

// ARM-05 counting: wears the given pieces (removing the slots' items for the check), reports the
// counts, then puts the original gear back. Run on its own: it changes the equipment for a moment.
function GMTestArmWear(names : array<name>, out added : array<SItemUniqueId>)
{
	var i : int;
	for(i = 0; i < names.Size(); i += 1)
		added.PushBack(GMTestArmAdd(names[i], true));
}

function GMTestArmRestore(added : array<SItemUniqueId>, old : array<SItemUniqueId>)
{
	var i : int;
	var w : W3PlayerWitcher;

	w = GetWitcherPlayer();
	for(i = 0; i < added.Size(); i += 1)
	{
		w.UnequipItem(added[i]);
		w.GetInventory().RemoveItem(added[i], 1);
	}
	for(i = 0; i < old.Size(); i += 1)
		if(w.GetInventory().IsIdValid(old[i]))
			w.EquipItem(old[i]);
}

// Needs a level for grandmaster gear: setlevel(50) first.
exec function gmtest_arm05_count()
{
	var w : W3PlayerWitcher;
	var names : array<name>;
	var added, old : array<SItemUniqueId>;
	var id : SItemUniqueId;

	w = GetWitcherPlayer();
	if(w.GetItemEquippedOnSlot(EES_Armor, id)) old.PushBack(id);
	if(w.GetItemEquippedOnSlot(EES_Boots, id)) old.PushBack(id);
	if(w.GetItemEquippedOnSlot(EES_Gloves, id)) old.PushBack(id);
	if(w.GetItemEquippedOnSlot(EES_Pants, id)) old.PushBack(id);

	names.PushBack('Lynx Boots 1'); names.PushBack('Lynx Gloves 1'); names.PushBack('Lynx Pants 1');
	GMTestArmWear(names, added);
	GMTestReport(w.GetSetPartsEquipped(EIST_Lynx) == 3 && w.GMGetSetPartsEquippedRaw(EIST_Lynx_Minor) == 3 && w.IsSetBonusActive(EISB_Lynx_1) && !w.IsSetBonusActive(EISB_Lynx_2) && !w.GMHasMixedSetsEquipped(),
		"ARM-05 three lower-tier Feline pieces: " + w.GetSetPartsEquipped(EIST_Lynx) + " pieces (minor " + w.GMGetSetPartsEquippedRaw(EIST_Lynx_Minor) + "), tier 1 " + w.IsSetBonusActive(EISB_Lynx_1) + ", tier 2 " + w.IsSetBonusActive(EISB_Lynx_2));
	names.Clear();
	names.PushBack('Lynx Armor 4');
	GMTestArmWear(names, added);
	GMTestReport(w.GetSetPartsEquipped(EIST_Lynx) == 4 && w.GMGetSetPartsEquippedRaw(EIST_Lynx) == 1 && w.GMHasMixedSetsEquipped(), "ARM-05 a grandmaster piece added: " + w.GetSetPartsEquipped(EIST_Lynx) + " pieces (grandmaster " + w.GMGetSetPartsEquippedRaw(EIST_Lynx) + "), mixed " + w.GMHasMixedSetsEquipped());
	w.GMRecalcSetItemsEquipped();
	GMTestReport(w.GetSetPartsEquipped(EIST_Lynx) == 4 && w.GMGetSetPartsEquippedRaw(EIST_Lynx_Minor) == 3, "ARM-05 recount at load gives the same: " + w.GetSetPartsEquipped(EIST_Lynx));
	GMTestArmRestore(added, old);
	GMTestReport(w.GetSetPartsEquipped(EIST_Lynx) == 0 && !w.IsSetBonusActive(EISB_Lynx_1), "ARM-05 gear back: " + w.GetSetPartsEquipped(EIST_Lynx) + " Feline pieces");
}

// Save impact (run after loading the save gmtest_arm_mksave() made with a build before ARM, and
// setlevel(35)): the Feline pieces owned since then have the new tags and count when worn.
exec function gmtest_arm_oldsave()
{
	var w : W3PlayerWitcher;
	var inv : CInventoryComponent;
	var ids : array<SItemUniqueId>;
	var names : array<name>;
	var i : int;

	w = GetWitcherPlayer();
	inv = w.GetInventory();
	ids = inv.GetItemsByName('Lynx Armor');
	GMTestReport(ids.Size() > 0 && inv.ItemHasTag(ids[0], 'LynxSetMinor') && inv.ItemHasTag(ids[0], 'SetBonusPiece') && !inv.ItemHasTag(ids[0], 'LynxSet'),
		"ARM save: the Feline armor owned before ARM has the new tags (" + ids.Size() + " owned)");
	names.PushBack('Lynx Armor'); names.PushBack('Lynx Boots 1'); names.PushBack('Lynx Gloves 1');
	for(i = 0; i < names.Size(); i += 1)
	{
		ids = inv.GetItemsByName(names[i]);
		if(ids.Size() > 0)
			w.EquipItem(ids[0]);
	}
	GMTestReport(w.GetSetPartsEquipped(EIST_Lynx) == 3 && w.IsSetBonusActive(EISB_Lynx_1), "ARM save: three lower-tier Feline pieces owned before ARM count when worn: " + w.GetSetPartsEquipped(EIST_Lynx) + ", tier 1 " + w.IsSetBonusActive(EISB_Lynx_1));
}

// Lists an item definition as the game has it: category, price, slots, abilities, some tags.
exec function gmtest_item_probe(itemName : name)
{
	var dm : CDefinitionsManagerAccessor;
	var abls : array<name>;
	var weights : array<float>;
	var minA, maxA, i : int;
	var s : string;
	var tags : array<name>;

	dm = theGame.GetDefinitionsManager();
	dm.GetItemAbilitiesWithWeights(itemName, true, abls, weights, minA, maxA);
	for(i = 0; i < abls.Size(); i += 1)
		s += abls[i] + "; ";
	LogChannel('GMTest', "ITEM " + itemName + " category=" + dm.GetItemCategory(itemName) + " price=" + dm.GetItemPrice(itemName) + " slots=" + dm.GetItemEnhancementSlotCount(itemName) + " key=" + dm.GetItemLocalisationKeyName(itemName) + " abilities=" + s);
	tags.PushBack('Armor'); tags.PushBack('LightArmor'); tags.PushBack('MediumArmor'); tags.PushBack('HeavyArmor'); tags.PushBack('LynxSet'); tags.PushBack('LynxSetMinor');
	tags.PushBack('SetBonusPiece'); tags.PushBack('ViperSet'); tags.PushBack('VampireSet'); tags.PushBack('WolfSet'); tags.PushBack('WolfSetMinor'); tags.PushBack('mod_armor');
	s = "";
	for(i = 0; i < tags.Size(); i += 1)
		if(dm.ItemHasTag(itemName, tags[i]))
			s += tags[i] + " ";
	LogChannel('GMTest', "ITEM " + itemName + " tags: " + s);
}

// The four armor slots' items, to put back after a test.
function GMTestArmWorn() : array<SItemUniqueId>
{
	var w : W3PlayerWitcher;
	var id : SItemUniqueId;
	var old : array<SItemUniqueId>;

	w = GetWitcherPlayer();
	if(w.GetItemEquippedOnSlot(EES_Armor, id)) old.PushBack(id);
	if(w.GetItemEquippedOnSlot(EES_Boots, id)) old.PushBack(id);
	if(w.GetItemEquippedOnSlot(EES_Gloves, id)) old.PushBack(id);
	if(w.GetItemEquippedOnSlot(EES_Pants, id)) old.PushBack(id);
	return old;
}

function GMTestArmDodgeCost() : float
{
	return GetWitcherPlayer().GetStaminaActionCost(ESAT_Dodge, '', 0);
}

// ARM-02: stamina costs by armor class (naked, 4 light, 4 heavy), signs with heavy armor, usable
// items unchanged; the glyphwords leave the class alone (DA7); the class tutorial text. Changes
// the gear for a moment and puts it back.
function GMTest_arm02()
{
	var w : W3PlayerWitcher;
	var old, added : array<SItemUniqueId>;
	var names : array<name>;
	var pieces : array<int>;
	var naked, light, heavy, signNaked, signHeavy, itemNaked, itemHeavy : float;
	var id : SItemUniqueId;

	w = GetWitcherPlayer();
	old = GMTestArmWorn();
	w.UnequipItemFromSlot(EES_Armor); w.UnequipItemFromSlot(EES_Boots); w.UnequipItemFromSlot(EES_Gloves); w.UnequipItemFromSlot(EES_Pants);
	naked = GMTestArmDodgeCost();
	signNaked = ((W3PlayerAbilityManager)w.GetAbilityManager()).GetSkillStaminaUseCost(S_Magic_1);
	itemNaked = w.GetStaminaActionCost(ESAT_UsableItem, '', 0);
	GMTestReport(AbsF(GMStaminaArmorPenalty() + 0.5) < 0.001, "ARM-02 naked: melee and agility costs " + GMStaminaArmorPenalty() * 100 + "% (expected -50%)");

	names.PushBack('Light armor 01'); names.PushBack('Boots 01'); names.PushBack('Gloves 01'); names.PushBack('Pants 01');
	GMTestArmWear(names, added);
	light = GMTestArmDodgeCost();
	w.GetInventory().GMCountArmorPieces(pieces);
	GMTestReport(pieces[0] == 4 && AbsF(light / naked - 1.4) < 0.01, "ARM-02 four light pieces (" + pieces[0] + "): dodge " + light + " vs naked " + naked + " (expected x1.4: -30% against -50%)");
	w.AddAbility('Glyphword 4 _Stats', false);
	w.GetItemEquippedOnSlot(EES_Armor, id);
	GMTestReport(w.GetInventory().GetArmorType(id) == EAT_Light && AbsF(GMTestArmDodgeCost() - light) < 0.001, "ARM-02 Heft's ability leaves the light armor light (DA7)");
	w.RemoveAbility('Glyphword 4 _Stats');

	GMTestArmRestore(added, added);	// takes the light pieces off
	added.Clear();
	names.Clear();
	names.PushBack('Heavy armor 01'); names.PushBack('Heavy boots 01'); names.PushBack('Heavy gloves 01'); names.PushBack('Heavy pants 01');
	GMTestArmWear(names, added);
	heavy = GMTestArmDodgeCost();
	signHeavy = ((W3PlayerAbilityManager)w.GetAbilityManager()).GetSkillStaminaUseCost(S_Magic_1);
	itemHeavy = w.GetStaminaActionCost(ESAT_UsableItem, '', 0);
	GMTestReport(AbsF(heavy / naked - 3) < 0.01, "ARM-02 four heavy pieces: dodge " + heavy + " vs naked " + naked + " (expected x3: +50% against -50%)");
	GMTestReport(AbsF(signHeavy / signNaked - 1.5) < 0.01, "ARM-02 four heavy pieces: Aard " + signHeavy + " vs " + signNaked + " (expected x1.5)");
	GMTestReport(AbsF(itemHeavy - itemNaked) < 0.001, "ARM-02 usable items cost the same in any armor: " + itemHeavy + " / " + itemNaked);
	GMTestArmRestore(added, old);
	GMTestReport(StrBeginsWith(GetLocStringById(2110992429), "Light Armor does not provide much protection, but your combat"), "ARM-02 armor class tutorial text: legacy's");
}

exec function gmtest_arm02()
{
	GMTest_arm02();
	GMTest_arm01();
	GMTest_arm04();
}

// An ability's attribute from the definitions (base and add nodes).
function GMTestArmAbl(abilityName : name, attr : name) : float
{
	var min, max : SAbilityAttributeValue;

	theGame.GetDefinitionsManager().GetAbilityAttributeValue(abilityName, attr, min, max);
	return min.valueBase + min.valueAdditive;
}

function GMTestArmNear(a : float, b : float) : bool
{
	return AbsF(a - b) < 0.0001;
}

// ARM-01: legacy's armor stats on 5.x's pieces (generic, school gear with DA5's resistances,
// Manticore's toxicity of DA6, expansions), legacy's weights (WGT-03 since WGT's slice W2), armor by item level, class
// tags and enhancement slots.
function GMTest_arm01()
{
	GMTestReport(GMTestArmNear(GMTestArmAbl('Lynx Armor _Stats', 'slashing_resistance_perc'), 0.08) && GMTestArmNear(GMTestArmAbl('Lynx Armor _Stats', 'bludgeoning_resistance_perc'), 0.07) && GMTestArmNear(GMTestArmAbl('Lynx Armor _Stats', 'weight'), 5),
		"ARM-01 Feline armor (tier 1): slashing " + GMTestArmAbl('Lynx Armor _Stats', 'slashing_resistance_perc') + " (expected 0.08; 5.x 0.05), bludgeoning " + GMTestArmAbl('Lynx Armor _Stats', 'bludgeoning_resistance_perc') + " (0.07), weight " + GMTestArmAbl('Lynx Armor _Stats', 'weight') + " (legacy's 5, WGT-03; 5.x 6.52)");
	GMTestReport(GMTestArmNear(GMTestArmAbl('Bear Armor 4 _Stats', 'rending_resistance_perc'), 0.22), "ARM-01 grandmaster Bear armor (Blood and Wine): rending " + GMTestArmAbl('Bear Armor 4 _Stats', 'rending_resistance_perc') + " (expected legacy's 0.22; 5.x 0.32, DA5)");
	GMTestReport(GMTestArmNear(GMTestArmAbl('Red Wolf Armor 1 _Stats', 'toxicity'), 10) && GMTestArmNear(GMTestArmAbl('Red Wolf Armor 1 _Stats', 'potion_duration'), 0.1), "ARM-01 Manticore armor: toxicity +" + GMTestArmAbl('Red Wolf Armor 1 _Stats', 'toxicity') + " (expected legacy's 10; 5.x 5, audit F3), potion duration +" + GMTestArmAbl('Red Wolf Armor 1 _Stats', 'potion_duration') + " (0.1)");
	GMTestReport(GMTestArmNear(GMTestArmAbl('Heavy armor 01 _Stats', 'slashing_resistance_perc'), 0.15) && GMTestArmNear(GMTestArmAbl('Heavy armor 01 _Stats', 'elemental_resistance_perc'), 0.15), "ARM-01 generic heavy armor: 15% against every damage type");
	GMTestReport(GMTestArmNear(GMTestArmAbl('autogen_armor_armor', 'armor'), 5), "ARM-01 armor per item level (chest): " + GMTestArmAbl('autogen_armor_armor', 'armor') + " (expected 5)");
	GMTestReport(theGame.GetDefinitionsManager().GetItemEnhancementSlotCount('Thief Armor') == 3 && theGame.GetDefinitionsManager().GetItemEnhancementSlotCount('Guard Lvl1 Armor 1') == 1, "ARM-01 legacy's enhancement slots (Thief Armor 3, Guard Lvl1 Armor 1 1)");
	GMTestReport(GMTestArmNear(GMTestArmAbl('q108 Medium armor 10 _Stats', 'q108_bounce_arrows'), 1), "ARM-01 Yoana's armor bounces arrows (q108_bounce_arrows " + GMTestArmAbl('q108 Medium armor 10 _Stats', 'q108_bounce_arrows') + ")");
	GMTestReport(GMTestArmTag('Beauclair Casual Suit 01', 'LightArmor') && GMTestArmTag('Beauclair Casual Suit 01', 'gm_NoSetBonuses'), "ARM-01 legacy's class tags (Beauclair casual suit light, no generic set)");
}

// Save impact of ARM-01 (after loading the pre-ARM save and setlevel(35)): a Feline armor owned
// before ARM, worn, reads legacy's resistances; generic armor owned with armor by level is listed.
exec function gmtest_arm01_oldsave()
{
	var w : W3PlayerWitcher;
	var inv : CInventoryComponent;
	var ids, all : array<SItemUniqueId>;
	var i : int;

	w = GetWitcherPlayer();
	inv = w.GetInventory();
	ids = inv.GetItemsByName('Lynx Armor');
	if(ids.Size() > 0)
		w.EquipItem(ids[0]);
	GMTestReport(ids.Size() > 0 && GMTestArmNear(GMTestArmItemValue(inv, ids[0], 'bludgeoning_resistance_perc'), 0.07) && GMTestArmNear(GMTestArmItemValue(inv, ids[0], 'slashing_resistance_perc'), 0.08),
		"ARM save: Feline armor owned before ARM: bludgeoning " + GMTestArmItemValue(inv, ids[0], 'bludgeoning_resistance_perc') + ", slashing " + GMTestArmItemValue(inv, ids[0], 'slashing_resistance_perc') + " (expected legacy's 0.07, 0.08)");
	inv.GetAllItems(all);
	for(i = 0; i < all.Size(); i += 1)
		if(inv.ItemHasTag(all[i], 'Autogen') && inv.IsItemAnyArmor(all[i]))
			LogChannel('GMTest', "INFO owned armor by level: " + inv.GetItemName(all[i]) + " abilities " + GMTestArmItemAbilities(inv, all[i]));
}

// An item's attribute (base and add; an item's multiplier part reads 0).
function GMTestArmItemValue(inv : CInventoryComponent, id : SItemUniqueId, attr : name) : float
{
	var v : SAbilityAttributeValue;

	v = inv.GetItemAttributeValue(id, attr);
	return v.valueBase + v.valueAdditive;
}

function GMTestArmItemAbilities(inv : CInventoryComponent, id : SItemUniqueId) : string
{
	var abls : array<name>;
	var i : int;
	var s : string;

	inv.GetItemAbilities(id, abls);
	for(i = 0; i < abls.Size(); i += 1)
		s += abls[i] + " ";
	return s;
}

// The armor of a generic piece made now (armor by level is added when an item is created).
exec function gmtest_arm01_autogen()
{
	var inv : CInventoryComponent;
	var ids : array<SItemUniqueId>;

	inv = thePlayer.GetInventory();
	ids = inv.AddAnItem('Light armor 01', 1, true, true, false);
	GetWitcherPlayer().EquipItem(ids[0]);
	LogChannel('GMTest', "INFO new Light armor 01: armor " + CalculateAttributeValue(inv.GetItemAttributeValue(ids[0], 'armor')) + ", level " + inv.GetItemLevel(ids[0]) + ", abilities " + GMTestArmItemAbilities(inv, ids[0]));
}

// Logs an owned item's attribute (first copy by name) and Geralt's total of it.
exec function gmtest_arm_attr(itemName : name, attr : name)
{
	var inv : CInventoryComponent;
	var ids : array<SItemUniqueId>;
	var v, p : SAbilityAttributeValue;

	inv = thePlayer.GetInventory();
	ids = inv.GetItemsByName(itemName);
	if(ids.Size() == 0)
	{
		LogChannel('GMTest', "INFO " + itemName + " not owned");
		return;
	}
	v = inv.GetItemAttributeValue(ids[0], attr);
	p = thePlayer.GetAttributeValue(attr);
	LogChannel('GMTest', "INFO " + itemName + " " + attr + ": base " + v.valueBase + " mult " + v.valueMultiplicative + " add " + v.valueAdditive + ", equipped " + GetWitcherPlayer().IsItemEquipped(ids[0]) + "; Geralt's total base " + p.valueBase + " add " + p.valueAdditive);
}

// The toxicity effect's decay value (needs toxicity), 0 without the effect.
function GMTestArmToxDecay() : float
{
	var tox : W3Effect_Toxicity;
	var v : SAbilityAttributeValue;

	tox = (W3Effect_Toxicity)thePlayer.GetBuff(EET_Toxicity);
	if(!tox)
		return 0;
	v = tox.GetEffectValue();
	return v.valueAdditive;
}

// ARM-04: generic sets: four medium pieces (the test save's starting gear) give the medium bonus and
// faster toxicity decay; four light pieces the light bonus; four heavy pieces the heavy bonus and
// +10% resistances; mixed classes none. Changes the gear for a moment and puts it back.
function GMTest_arm04()
{
	var w : W3PlayerWitcher;
	var old, added : array<SItemUniqueId>;
	var names : array<name>;
	var withSet, without : float;
	var resNo, resHeavy : SAbilityAttributeValue;

	w = GetWitcherPlayer();
	old = GMTestArmWorn();
	GMTestReport(GMTestArmNear(GMTestArmAbl('ArmorTypeHeavySetBonusAbility', 'rending_resistance_perc'), 0.1) && GMTestArmNear(GMTestArmAbl('ArmorTypeMediumSetBonusAbility', 'toxicityRegen'), -0.25) && GMTestArmNear(GMTestArmAbl('ArmorTypeLightSetBonusAbility', 'dodge_safe_ange_dist_deg'), 30), "ARM-04 set bonus values: heavy +0.1 resistances, medium -0.25 toxicity per second, light +30 degrees");
	w.UnequipItemFromSlot(EES_Gloves);
	GMTestReport(!w.HasAbility('ArmorTypeMediumSetBonusAbility'), "ARM-04 three pieces: no set");
	w.GainStat(BCS_Toxicity, 30);
	without = GMTestArmToxDecay();
	GMTestArmRestore(added, old);
	withSet = GMTestArmToxDecay();
	GMTestReport(w.GetInventory().GMGetSetArmorType() == EAT_Medium && w.HasAbility('ArmorTypeMediumSetBonusAbility') && GMTestArmNear(withSet - without, -0.25),
		"ARM-04 four medium pieces: medium set " + w.HasAbility('ArmorTypeMediumSetBonusAbility') + ", toxicity decay " + withSet + " against " + without + " without (expected 0.25 more)");
	w.DrainToxicity(w.GetStat(BCS_Toxicity));

	w.UnequipItemFromSlot(EES_Armor); w.UnequipItemFromSlot(EES_Boots); w.UnequipItemFromSlot(EES_Gloves); w.UnequipItemFromSlot(EES_Pants);
	resNo = w.GetAttributeValue('rending_resistance_perc');
	names.PushBack('Light armor 01'); names.PushBack('Boots 01'); names.PushBack('Gloves 01'); names.PushBack('Pants 01');
	GMTestArmWear(names, added);
	GMTestReport(w.HasAbility('ArmorTypeLightSetBonusAbility') && !w.HasAbility('ArmorTypeMediumSetBonusAbility'), "ARM-04 four light pieces: light set");
	GMTestArmRestore(added, added);
	added.Clear();
	names.Clear();
	names.PushBack('Heavy armor 01'); names.PushBack('Heavy boots 01'); names.PushBack('Heavy gloves 01'); names.PushBack('Heavy pants 01');
	GMTestArmWear(names, added);
	GMTestReport(w.HasAbility('ArmorTypeHeavySetBonusAbility') && !w.HasAbility('ArmorTypeLightSetBonusAbility'), "ARM-04 four heavy pieces: heavy set");
	w.UnequipItemFromSlot(EES_Boots);
	GMTestReport(!w.HasAbility('ArmorTypeHeavySetBonusAbility'), "ARM-04 a heavy piece off: no set");
	GMTestArmRestore(added, old);
	GMTestReport(w.HasAbility('ArmorTypeMediumSetBonusAbility') && !w.HasAbility('ArmorTypeHeavySetBonusAbility'), "ARM-04 gear back: medium set again");
}

exec function gmtest_arm04()
{
	GMTest_arm04();
}

// ARM-04 with DEF-01: the light set's 30 degrees on a scripted hit from a hostile NPC within 20 m
// (spawn one first): dodged at 145 degrees, not at 155. Puts the gear back.
exec function gmtest_arm04_dodge()
{
	var npc : CActor;
	var old, added : array<SItemUniqueId>;
	var names : array<name>;
	var savedHeading : float;
	var w : W3PlayerWitcher;

	npc = GMTestHostileNpc();
	if(!npc)
	{
		LogChannel('GMTest', "INFO ARM-04 dodge: no hostile NPC within 20 m");
		return;
	}
	w = GetWitcherPlayer();
	savedHeading = thePlayer.GMTestGetEvadeHeading();
	old = GMTestArmWorn();
	names.PushBack('Light armor 01'); names.PushBack('Boots 01'); names.PushBack('Gloves 01'); names.PushBack('Pants 01');
	GMTestArmWear(names, added);
	GMTestDef01Player(npc, 145, true, 0, true, "ARM-04 light set: dodging at 145 deg");
	GMTestDef01Player(npc, 155, true, 0, false, "ARM-04 light set: dodging at 155 deg");
	GMTestArmRestore(added, old);
	GMTestDef01Player(npc, 145, true, 0, false, "ARM-04 medium set: dodging at 145 deg");
	thePlayer.GMTestSetEvadeHeading(savedHeading);
}

// An ability's multiplier from the definitions.
function GMTestArmAblMult(abilityName : name, attr : name) : float
{
	var min, max : SAbilityAttributeValue;

	theGame.GetDefinitionsManager().GetAbilityAttributeValue(abilityName, attr, min, max);
	return min.valueMultiplicative;
}

// ARM-07: the Griffin set's values; 5.x's free cast gone (the buff no longer lets a sign be cast
// without stamina); legacy's descriptions. No gear needed.
function GMTest_arm07()
{
	var w : W3PlayerWitcher;
	var stamina, focus : float;
	var canCast : bool;

	w = GetWitcherPlayer();
	GMTestReport(GMTestArmNear(GMTestArmAbl('GryphonSetBonusEffect', 'duration'), 2.5) && GMTestArmNear(GMTestArmAbl('GryphonSetBonusEffect', 'gryphon_tier1_bonus'), 0.05), "ARM-07 Griffin tier 1: 2.5 s buff, -5% costs per piece");
	GMTestReport(GMTestArmNear(GMTestArmAblMult('GryphonSetBonusYrdenEffect', 'spell_power'), 0.5) && GMTestArmNear(GMTestArmAbl('GryphonSetBonusYrdenEffect', 'rending_resistance_perc'), 0.15) && GMTestArmNear(GMTestArmAbl('GryphonSetBonusYrdenEffect', 'will_resistance_perc'), 0.15)
		&& GMTestArmNear(GMTestArmAblMult('GryphonSetBonusYrdenEffect', 'staminaRegen'), 0) && GMTestArmNear(GMTestArmAbl('GryphonSetBonusYrdenEffect', 'gryphon_set_bns_dmg_reduction'), 0) && GMTestArmNear(GMTestArmAbl('GryphonSetBonusYrdenEffect', 'trigger_scale'), 1.4),
		"ARM-07 Griffin tier 2 inside Yrden: intensity +50%, resistances +15%, no regen, no damage reduction, traps +40%");
	stamina = w.GetStat(BCS_Stamina);
	focus = w.GetStat(BCS_Focus);
	w.AddEffectDefault(EET_GryphonSetBonus, w, "gmtest");
	w.DrainStamina(ESAT_FixedValue, stamina, 0);
	w.DrainFocus(focus);
	canCast = w.HasStaminaToUseSkill(S_Magic_1, false);
	w.RemoveBuff(EET_GryphonSetBonus);
	w.GainStat(BCS_Stamina, stamina);
	w.GainStat(BCS_Focus, focus);
	GMTestReport(!canCast, "ARM-07 no free cast: with the Griffin buff and no stamina Aard cannot be cast (5.x: free)");
	GMTestReport(StrBeginsWith(w.GetSetBonusTooltipDescription(EISB_Gryphon_1), "Casting a sign reduces stamina cost") && StrBeginsWith(w.GetSetBonusTooltipDescription(EISB_Gryphon_2), "The size of Yrden traps is increased by 40%"),
		"ARM-07 descriptions: " + w.GetSetBonusTooltipDescription(EISB_Gryphon_1) + " / " + w.GetSetBonusTooltipDescription(EISB_Gryphon_2));
}

// ARM-07 with gear (setlevel(50) first): three lower-tier pieces give tier 1; a sign cast starts the
// 2.5 s buff, which cuts sign, melee and agility costs by 15% and is not refreshed by a second cast;
// six grandmaster pieces give tier 2, and inside Yrden (its effect added by script) +15% resistances
// and +50% intensity. Puts the gear back.
exec function gmtest_arm07()
{
	var w : W3PlayerWitcher;
	var am : W3PlayerAbilityManager;
	var old, added : array<SItemUniqueId>;
	var names : array<name>;
	var sign0, dodge0, sign1, dodge1, left0, left1 : float;
	var id : SItemUniqueId;

	w = GetWitcherPlayer();
	am = (W3PlayerAbilityManager)w.GetAbilityManager();
	old = GMTestArmWorn();
	if(w.GetItemEquippedOnSlot(EES_SteelSword, id)) old.PushBack(id);
	if(w.GetItemEquippedOnSlot(EES_SilverSword, id)) old.PushBack(id);
	w.RemoveBuff(EET_GryphonSetBonus);
	names.PushBack('Gryphon Armor'); names.PushBack('Gryphon Gloves 1'); names.PushBack('Gryphon Pants 1');
	GMTestArmWear(names, added);
	GMTestReport(w.IsSetBonusActive(EISB_Gryphon_1) && !w.IsSetBonusActive(EISB_Gryphon_2) && w.GetSetPartsEquipped(EIST_Gryphon) == 3, "ARM-07 three lower-tier Griffin pieces: tier 1 (" + w.GetSetPartsEquipped(EIST_Gryphon) + " pieces)");
	sign0 = am.GetSkillStaminaUseCost(S_Magic_1);
	dodge0 = GMTestArmDodgeCost();
	w.OnSignCastPerformed(ST_Aard, false);
	GMTestReport(w.HasBuff(EET_GryphonSetBonus), "ARM-07 a sign cast starts the Griffin buff");
	left0 = w.GetBuff(EET_GryphonSetBonus).GetDurationLeft();
	sign1 = am.GetSkillStaminaUseCost(S_Magic_1);
	dodge1 = GMTestArmDodgeCost();
	GMTestReport(GMTestArmNear(sign1 / sign0, 0.85) && GMTestArmNear(dodge1 / dodge0, 0.85), "ARM-07 with the buff: Aard " + sign1 + " vs " + sign0 + ", dodge " + dodge1 + " vs " + dodge0 + " (expected x0.85)");
	w.GetBuff(EET_GryphonSetBonus).SetTimeLeft(1);
	w.OnSignCastPerformed(ST_Igni, false);
	left1 = w.GetBuff(EET_GryphonSetBonus).GetDurationLeft();
	GMTestReport(left0 > 2.3 && left0 <= 2.5 && left1 <= 1.0, "ARM-07 buff 2.5 s (" + left0 + "), not refreshed by a second cast (" + left1 + " left)");
	w.RemoveBuff(EET_GryphonSetBonus);
	GMTestArmRestore(added, added);
	added.Clear();
	names.Clear();
	names.PushBack('Gryphon Armor 4'); names.PushBack('Gryphon Gloves 5'); names.PushBack('Gryphon Pants 5'); names.PushBack('Gryphon Boots 5');
	names.PushBack('Gryphon School steel sword 4'); names.PushBack('Gryphon School silver sword 4');
	GMTestArmWear(names, added);
	w.GMTestArmKeep(added, old);
	w.AddEffectDefault(EET_GryphonSetBonusYrden, w, "gmtest");
	LogChannel('GMTest', "INFO ARM-07 six grandmaster pieces worn, tier 2 " + w.IsSetBonusActive(EISB_Gryphon_2) + "; Yrden buff added: run gmtest_arm07_b()");
}

@addField(W3PlayerWitcher)
public var gmTestArmAdded : array<SItemUniqueId>;
@addField(W3PlayerWitcher)
public var gmTestArmOld : array<SItemUniqueId>;
@addField(W3PlayerWitcher)
public var gmTestArmRes : float;
@addField(W3PlayerWitcher)
public var gmTestArmSp : float;

@addMethod(W3PlayerWitcher)
function GMTestArmKeep(added : array<SItemUniqueId>, old : array<SItemUniqueId>)
{
	gmTestArmAdded = added;
	gmTestArmOld = old;
}

@addMethod(W3PlayerWitcher)
function GMTestArmKeepValues(res : float, sp : float)
{
	gmTestArmRes = res;
	gmTestArmSp = sp;
}

// Step 2: the values with the Yrden buff, then the buff removed.
exec function gmtest_arm07_b()
{
	var w : W3PlayerWitcher;
	var sp : SAbilityAttributeValue;
	var pts, perc : float;

	w = GetWitcherPlayer();
	w.GetResistValue(CDS_SlashingRes, pts, perc);
	sp = w.GetPowerStatValue(CPS_SpellPower);
	w.GMTestArmKeepValues(perc, sp.valueMultiplicative);
	LogChannel('GMTest', "INFO ARM-07 with the Yrden buff (" + w.HasBuff(EET_GryphonSetBonusYrden) + ", ability " + w.HasAbility('GryphonSetBonusYrdenEffect') + "): slashing " + perc + ", intensity mult " + sp.valueMultiplicative);
	w.RemoveBuff(EET_GryphonSetBonusYrden);
}

// Step 3: the values without it, compared; the gear put back.
exec function gmtest_arm07_c()
{
	var w : W3PlayerWitcher;
	var sp : SAbilityAttributeValue;
	var pts, perc : float;

	w = GetWitcherPlayer();
	w.GetResistValue(CDS_SlashingRes, pts, perc);
	sp = w.GetPowerStatValue(CPS_SpellPower);
	GMTestReport(w.IsSetBonusActive(EISB_Gryphon_2) && GMTestArmNear(w.gmTestArmRes - perc, 0.15) && GMTestArmNear(w.gmTestArmSp - sp.valueMultiplicative, 0.5),
		"ARM-07 six grandmaster pieces: tier 2 " + w.IsSetBonusActive(EISB_Gryphon_2) + "; inside Yrden slashing resistance +" + (w.gmTestArmRes - perc) + ", intensity +" + (w.gmTestArmSp - sp.valueMultiplicative) + " (expected 0.15, 0.5)");
	GMTestArmRestore(w.gmTestArmAdded, w.gmTestArmOld);
}

// For real casts: wears three lower-tier Griffin pieces (or the six grandmaster pieces) until
// gmtest_arm_restore(); full stamina, no Griffin buff.
exec function gmtest_arm07_wear(grandmaster : bool)
{
	var w : W3PlayerWitcher;
	var old, added : array<SItemUniqueId>;
	var names : array<name>;
	var id : SItemUniqueId;

	w = GetWitcherPlayer();
	old = GMTestArmWorn();
	if(w.GetItemEquippedOnSlot(EES_SteelSword, id)) old.PushBack(id);
	if(w.GetItemEquippedOnSlot(EES_SilverSword, id)) old.PushBack(id);
	if(grandmaster)
	{
		names.PushBack('Gryphon Armor 4'); names.PushBack('Gryphon Gloves 5'); names.PushBack('Gryphon Pants 5'); names.PushBack('Gryphon Boots 5');
		names.PushBack('Gryphon School steel sword 4'); names.PushBack('Gryphon School silver sword 4');
	}
	else
	{
		names.PushBack('Gryphon Armor'); names.PushBack('Gryphon Gloves 1'); names.PushBack('Gryphon Pants 1');
	}
	GMTestArmWear(names, added);
	w.GMTestArmKeep(added, old);
	w.RemoveBuff(EET_GryphonSetBonus);
	w.GainStat(BCS_Stamina, w.GetStatMax(BCS_Stamina));
	LogChannel('GMTest', "INFO ARM-07 worn: Griffin pieces " + w.GetSetPartsEquipped(EIST_Gryphon) + ", tier 1 " + w.IsSetBonusActive(EISB_Gryphon_1) + ", tier 2 " + w.IsSetBonusActive(EISB_Gryphon_2));
}

// For real attacks: as gmtest_arm07_wear with the Bear set.
exec function gmtest_arm08_wear(grandmaster : bool)
{
	var w : W3PlayerWitcher;
	var old, added : array<SItemUniqueId>;
	var names : array<name>;
	var id : SItemUniqueId;

	w = GetWitcherPlayer();
	old = GMTestArmWorn();
	if(w.GetItemEquippedOnSlot(EES_SteelSword, id)) old.PushBack(id);
	if(w.GetItemEquippedOnSlot(EES_SilverSword, id)) old.PushBack(id);
	if(grandmaster)
	{
		names.PushBack('Bear Armor 4'); names.PushBack('Bear Gloves 5'); names.PushBack('Bear Pants 5'); names.PushBack('Bear Boots 5');
		names.PushBack('Bear School steel sword 4'); names.PushBack('Bear School silver sword 4');
	}
	else
	{
		names.PushBack('Bear Armor'); names.PushBack('Bear Gloves 1'); names.PushBack('Bear Pants 1');
	}
	GMTestArmWear(names, added);
	w.GMTestArmKeep(added, old);
	w.RemoveBuff(EET_GryphonSetBonus);
	w.GainStat(BCS_Stamina, w.GetStatMax(BCS_Stamina));
	LogChannel('GMTest', "INFO ARM-08 worn: Bear pieces " + w.GetSetPartsEquipped(EIST_Bear) + ", tier 1 " + w.IsSetBonusActive(EISB_Bear_1) + ", tier 2 " + w.IsSetBonusActive(EISB_Bear_2));
}

// The Griffin buffs and stamina, between real casts.
exec function gmtest_arm07_state()
{
	var w : W3PlayerWitcher;
	var pts, perc : float;
	var sp : SAbilityAttributeValue;

	w = GetWitcherPlayer();
	w.GetResistValue(CDS_SlashingRes, pts, perc);
	sp = w.GetPowerStatValue(CPS_SpellPower);
	LogChannel('GMTest', "INFO ARM-07 state: stamina " + w.GetStat(BCS_Stamina) + "/" + w.GetStatMax(BCS_Stamina) + ", Griffin buff " + w.HasBuff(EET_GryphonSetBonus) + ", inside-Yrden buff " + w.HasBuff(EET_GryphonSetBonusYrden) + ", slashing " + perc + ", intensity mult " + sp.valueMultiplicative);
}

// Puts back the gear gmtest_arm07_wear() or gmtest_arm07() changed.
exec function gmtest_arm_restore()
{
	var w : W3PlayerWitcher;

	w = GetWitcherPlayer();
	GMTestArmRestore(w.gmTestArmAdded, w.gmTestArmOld);
	LogChannel('GMTest', "INFO ARM gear restored");
}

// ARM-08: the Bear set's values (5.x's Quen values gone) and legacy's descriptions. No gear needed.
function GMTest_arm08()
{
	var w : W3PlayerWitcher;

	w = GetWitcherPlayer();
	GMTestReport(GMTestArmNear(GMTestArmAbl('setBonusAbilityBear_1', 'bonus_focus_gain'), 0.035) && GMTestArmNear(GMTestArmAblMult('setBonusAbilityBear_1', 'attack_power'), 0.035) && GMTestArmNear(GMTestArmAbl('setBonusAbilityBear_2', 'stamina_attack'), 0.334),
		"ARM-08 Bear values: +0.035 adrenaline and +3.5% attack power per piece, 33.4% of a strong attack's stamina back");
	GMTestReport(GMTestArmNear(GMTestArmAblMult('setBonusAbilityBear_1', 'quen_reapply_chance'), 0) && GMTestArmNear(GMTestArmAblMult('setBonusAbilityBear_2', 'quen_dmg_boost'), 0), "ARM-08 5.x's Bear Quen rules gone (free recast chance, Quen damage boost)");
	GMTestReport(StrBeginsWith(w.GetSetBonusTooltipDescription(EISB_Bear_1), "Taking damage increases your Adrenaline by 0.035") && StrBeginsWith(w.GetSetBonusTooltipDescription(EISB_Bear_2), "Damage dealt with a strong attack restores 33.4%"),
		"ARM-08 descriptions: " + w.GetSetBonusTooltipDescription(EISB_Bear_1) + " / " + w.GetSetBonusTooltipDescription(EISB_Bear_2));
}

// ARM-08 with gear and a hostile test dummy (setlevel(50), gmtest_dummy("wolf") first): three
// lower-tier Bear pieces: a scripted hit taken gives +0.105 adrenaline against the loss; attack power
// +10.5% per whole adrenaline point; six grandmaster pieces: a scripted strong attack on the dummy gives
// back 33.4% of its cost, a fast one nothing. Puts the gear back.
exec function gmtest_arm08()
{
	var w : W3PlayerWitcher;
	var npc : CActor;
	var old, added : array<SItemUniqueId>;
	var names : array<name>;
	var id : SItemUniqueId;
	var action : W3Action_Attack;
	var f0, f1, expected, s0, s1, cost, m0, m2 : float;
	var step : SGMTestDmgStep;
	var probes : bool;

	w = GetWitcherPlayer();
	npc = GMTestHostileNpc();
	if(!npc)
	{
		LogChannel('GMTest', "FAIL ARM-08: no hostile NPC (gmtest_dummy first)");
		return;
	}
	old = GMTestArmWorn();
	if(w.GetItemEquippedOnSlot(EES_SteelSword, id)) old.PushBack(id);
	if(w.GetItemEquippedOnSlot(EES_SilverSword, id)) old.PushBack(id);
	names.PushBack('Bear Armor'); names.PushBack('Bear Gloves 1'); names.PushBack('Bear Pants 1');
	GMTestArmWear(names, added);
	GMTestReport(w.IsSetBonusActive(EISB_Bear_1) && !w.IsSetBonusActive(EISB_Bear_2), "ARM-08 three lower-tier Bear pieces: tier 1 (" + w.GetSetPartsEquipped(EIST_Bear) + " pieces)");
	w.DrainFocus(w.GetStat(BCS_Focus));
	w.GainStat(BCS_Focus, 1);
	f0 = w.GetStat(BCS_Focus);
	action = new W3Action_Attack in theGame.damageMgr;
	action.Init(npc, w, NULL, GetInvalidUniqueId(), 'attack_light', npc.GetName(), EHRT_Light, false, false, '', AST_Jab, ASD_UpDown, true, false, false, false);
	action.AddDamage(theGame.params.DAMAGE_NAME_PHYSICAL, 300);
	action.SetSuppressHitSounds(true);
	action.SetHitAnimationPlayType(EAHA_ForceNo);
	theGame.damageMgr.ProcessAction(action);
	f1 = w.GetStat(BCS_Focus);
	expected = f0 - ClampF(action.GetDamageDealt() / w.GetMaxHealth(), 0, 1) + 0.105;
	GMTestReport(AbsF(f1 - expected) < 0.001 && action.GetDamageDealt() > 0, "ARM-08 a hit taken (" + action.GetDamageDealt() + " of " + w.GetMaxHealth() + "): adrenaline " + f0 + " -> " + f1 + " (expected " + expected + ": the loss less 0.105)");
	delete action;
	w.ForceSetStat(BCS_Vitality, w.GetStatMax(BCS_Vitality));
	w.DrainFocus(w.GetStat(BCS_Focus));
	w.GainStat(BCS_Focus, 2.5);
	GMTestReport(GMTestArmNear(w.GMBearSetAttackPower(), 0.21), "ARM-08 attack power at 2.5 adrenaline: +" + w.GMBearSetAttackPower() + " (expected 0.21: 3 pieces x 2 points x 3.5%)");
	probes = GMTestProbes();
	w.GMTestSetProbes(true);
	w.GetItemEquippedOnSlot(EES_SteelSword, id);
	w.DrainFocus(w.GetStat(BCS_Focus));
	GMTestDmgHit(w, npc, id, 'attack_light');
	step = GMTestDmgStep0();
	m0 = step.mult;
	w.DrainFocus(w.GetStat(BCS_Focus));
	w.GainStat(BCS_Focus, 2.5);
	GMTestDmgHit(w, npc, id, 'attack_light');
	step = GMTestDmgStep0();
	m2 = step.mult;
	w.GMTestSetProbes(probes);
	GMTestReport(GMTestArmNear(m2 - m0, 0.41), "ARM-08 a scripted sword hit's attack power: " + m2 + " at 2.5 adrenaline, " + m0 + " at 0 (expected +0.41: the set's 0.21 and 5.x's 0.1 per point)");
	w.DrainFocus(w.GetStat(BCS_Focus));
	GMTestArmRestore(added, added);
	added.Clear();
	names.Clear();
	names.PushBack('Bear Armor 4'); names.PushBack('Bear Gloves 5'); names.PushBack('Bear Pants 5'); names.PushBack('Bear Boots 5');
	names.PushBack('Bear School steel sword 4'); names.PushBack('Bear School silver sword 4');
	GMTestArmWear(names, added);
	w.GetItemEquippedOnSlot(EES_SteelSword, id);
	w.ForceSetStat(BCS_Stamina, 20);
	s0 = w.GetStat(BCS_Stamina);
	cost = w.GetStaminaActionCost(ESAT_HeavyAttack, '', 0);
	GMTestDmgHit(w, npc, id, 'attack_heavy');
	s1 = w.GetStat(BCS_Stamina);
	GMTestReport(w.IsSetBonusActive(EISB_Bear_2) && AbsF(s1 - s0 - cost * 0.334) < 0.01, "ARM-08 tier 2 " + w.IsSetBonusActive(EISB_Bear_2) + ": a strong attack gave back " + (s1 - s0) + " stamina (expected " + cost * 0.334 + ", 33.4% of " + cost + ")");
	s0 = w.GetStat(BCS_Stamina);
	GMTestDmgHit(w, npc, id, 'attack_light');
	s1 = w.GetStat(BCS_Stamina);
	GMTestReport(AbsF(s1 - s0) < 0.01, "ARM-08 a fast attack gives nothing back (" + (s1 - s0) + ")");
	w.ForceSetStat(BCS_Stamina, w.GetStatMax(BCS_Stamina));
	GMTestArmRestore(added, old);
}

// A scripted light sword hit's attack power on the hostile NPC at the given adrenaline and at 0.
exec function gmtest_arm_powerdiff(focus : float)
{
	var w : W3PlayerWitcher;
	var id : SItemUniqueId;
	var step : SGMTestDmgStep;
	var probes : bool;
	var m0, m1 : float;

	w = GetWitcherPlayer();
	probes = GMTestProbes();
	w.GMTestSetProbes(true);
	w.GetItemEquippedOnSlot(EES_SteelSword, id);
	w.DrainFocus(w.GetStat(BCS_Focus));
	w.GainStat(BCS_Focus, focus);
	GMTestDmgHit(w, GMTestHostileNpc(), id, 'attack_light');
	step = GMTestDmgStep0();
	m1 = step.mult;
	w.DrainFocus(w.GetStat(BCS_Focus));
	GMTestDmgHit(w, GMTestHostileNpc(), id, 'attack_light');
	step = GMTestDmgStep0();
	m0 = step.mult;
	w.GMTestSetProbes(probes);
	LogChannel('GMTest', "INFO ARM attack power: " + m1 + " at " + focus + " adrenaline, " + m0 + " at 0; Bear tier 1 " + w.IsSetBonusActive(EISB_Bear_1) + " term " + w.GMBearSetAttackPower());
}

// ARM-08: during a held alternate Quen, whether the Bear set's effect plays on the sign (Quen
// Discharge's visual since ARM-08) and the discharge share.
exec function gmtest_arm08_quenfx()
{
	var quen : W3QuenEntity;

	quen = (W3QuenEntity)GetWitcherPlayer().GetSignEntity(ST_Quen);
	if(quen)
		LogChannel('GMTest', "INFO ARM-08 Quen: alternate " + quen.IsAlternateCast() + ", discharge " + quen.GMTestDischarge() + ", Bear effect " + quen.IsEffectActive('default_fx_bear_abl2') + ", Bear tier 2 " + GetWitcherPlayer().IsSetBonusActive(EISB_Bear_2));
	else
		LogChannel('GMTest', "INFO ARM-08 Quen: no entity");
}

@addMethod(W3QuenEntity)
function GMTestDischarge() : float
{
	return dischargePercent;
}

// ARM-06: the Feline set's values and legacy's descriptions. No gear needed.
function GMTest_arm06()
{
	var w : W3PlayerWitcher;

	w = GetWitcherPlayer();
	GMTestReport(GMTestArmNear(GMTestArmAbl('LynxSetBonusEffect', 'lynx_ap_boost'), 0.025) && GMTestArmNear(GMTestArmAbl('LynxSetBonusEffect', 'lynx_boost_max'), 0.6) && GMTestArmNear(GMTestArmAbl('LynxSetBonusEffect', 'duration'), -1)
		&& GMTestArmNear(GMTestArmAbl('setBonusAbilityLynx_2', 'lynx_2_dmg_boost'), 0) && GMTestArmNear(GMTestArmAbl('setBonusAbilityLynx_2', 'lynx_2_adrenaline_cost'), 0),
		"ARM-06 Feline values: +2.5% per piece per fast hit up to +60%, no duration; 5.x's rear attack values gone");
	GMTestReport(StrBeginsWith(w.GetSetBonusTooltipDescription(EISB_Lynx_1), "Chained fast hits add +2.5% to Attack Power") && StrBeginsWith(w.GetSetBonusTooltipDescription(EISB_Lynx_2), "Critical hits with a sword double Adrenaline"),
		"ARM-06 descriptions: " + w.GetSetBonusTooltipDescription(EISB_Lynx_1) + " / " + w.GetSetBonusTooltipDescription(EISB_Lynx_2));
}

// One scripted sword hit of Geralt's on the NPC at 0 adrenaline (critical or not); returns the attack
// power the probe recorded; gained returns the adrenaline it gave.
function GMTestArmSwordHit(npc : CActor, attackName : name, crit : bool, out gained : float) : float
{
	var w : W3PlayerWitcher;
	var action : W3Action_Attack;
	var step : SGMTestDmgStep;
	var id : SItemUniqueId;

	w = GetWitcherPlayer();
	w.GetItemEquippedOnSlot(EES_SteelSword, id);
	w.GMTestDmgReset();
	w.ForceSetStat(BCS_Focus, 0);
	action = new W3Action_Attack in theGame.damageMgr;
	action.Init(w, npc, NULL, id, attackName, w.GetName(), EHRT_Light, false, false, attackName, AST_Jab, ASD_UpDown, true, false, false, false);
	if(crit)
		action.SetCriticalHit();
	action.SetSuppressHitSounds(true);
	action.SetHitAnimationPlayType(EAHA_ForceNo);
	theGame.damageMgr.ProcessAction(action);
	step = GMTestDmgStep0();
	gained = w.GetStat(BCS_Focus);
	delete action;
	npc.ForceSetStat(BCS_Vitality, npc.GetStatMax(BCS_Vitality));
	w.ForceSetStat(BCS_Focus, 0);
	return step.mult;
}

// ARM-06 with gear and a hostile test dummy (setlevel(50), gmtest_dummy("wolf"), then gmtest_dummy_neutral() first): three
// lower-tier Feline pieces: scripted fast hits add 7.5% attack power each to the next, a strong hit
// gets double and ends the chain; six grandmaster pieces: a sword crit gives double adrenaline. Leaves
// a chain of two hits running for gmtest_arm06_decay() (call it 4 s later). Puts the gear back there.
exec function gmtest_arm06()
{
	var w : W3PlayerWitcher;
	var npc : CActor;
	var old, added : array<SItemUniqueId>;
	var names : array<name>;
	var id : SItemUniqueId;
	var m1, m2, m3, m4, m5, g0, g1 : float;
	var probes : bool;

	w = GetWitcherPlayer();
	npc = GMTestHostileNpc();
	if(!npc)
	{
		LogChannel('GMTest', "FAIL ARM-06: no hostile NPC (gmtest_dummy first)");
		return;
	}
	probes = GMTestProbes();
	w.GMTestSetProbes(true);
	old = GMTestArmWorn();
	if(w.GetItemEquippedOnSlot(EES_SteelSword, id)) old.PushBack(id);
	if(w.GetItemEquippedOnSlot(EES_SilverSword, id)) old.PushBack(id);
	w.RemoveBuff(EET_LynxSetBonus);
	names.PushBack('Lynx Armor'); names.PushBack('Lynx Gloves 1'); names.PushBack('Lynx Pants 1');
	GMTestArmWear(names, added);
	GMTestReport(w.IsSetBonusActive(EISB_Lynx_1) && !w.IsSetBonusActive(EISB_Lynx_2), "ARM-06 three lower-tier Feline pieces: tier 1 (" + w.GetSetPartsEquipped(EIST_Lynx) + " pieces)");
	m1 = GMTestArmSwordHit(npc, 'attack_light', false, g0);
	m2 = GMTestArmSwordHit(npc, 'attack_light', false, g0);
	m3 = GMTestArmSwordHit(npc, 'attack_light', false, g0);
	m4 = GMTestArmSwordHit(npc, 'attack_heavy', false, g0);
	m5 = GMTestArmSwordHit(npc, 'attack_light', false, g0);
	GMTestReport(GMTestArmNear(m2 - m1, 0.075) && GMTestArmNear(m3 - m1, 0.15) && GMTestArmNear(m5 - m1, 0), "ARM-06 fast hits: attack power " + m1 + ", " + m2 + ", " + m3 + " (expected +0.075 per hit), after the strong hit " + m5 + " (chain ended)");
	GMTestReport(m4 - m1 > 0.449 && m4 - m1 < 0.451, "ARM-06 the strong hit got double the chain's 0.225: " + m4 + " against " + m1 + " without a chain");
	GMTestArmRestore(added, added);
	added.Clear();
	names.Clear();
	names.PushBack('Lynx Armor 4'); names.PushBack('Lynx Gloves 5'); names.PushBack('Lynx Pants 5'); names.PushBack('Lynx Boots 5');
	names.PushBack('Lynx School steel sword 4'); names.PushBack('Lynx School silver sword 4');
	GMTestArmWear(names, added);
	GMTestArmSwordHit(npc, 'attack_light', false, g0);
	GMTestArmSwordHit(npc, 'attack_light', true, g1);
	GMTestReport(w.IsSetBonusActive(EISB_Lynx_2) && g0 > 0 && GMTestArmNear(g1, 2 * g0), "ARM-06 tier 2 " + w.IsSetBonusActive(EISB_Lynx_2) + ": a sword crit gave " + g1 + " adrenaline, a normal hit " + g0 + " (expected double)");
	GMTestArmSwordHit(npc, 'attack_light', false, g0);
	GMTestArmSwordHit(npc, 'attack_light', false, g0);
	w.GMTestSetProbes(probes);
	w.GMTestArmKeep(added, old);
	LogChannel('GMTest', "INFO ARM-06 chain running: " + ((W3Effect_LynxSetBonus)w.GetBuff(EET_LynxSetBonus)).GMGetStacks() + "%; run gmtest_arm06_decay() in 4 s");
}

// The chain broken 3 s after its last hit; the gear put back.
exec function gmtest_arm06_decay()
{
	var w : W3PlayerWitcher;
	var lynx : W3Effect_LynxSetBonus;

	w = GetWitcherPlayer();
	lynx = (W3Effect_LynxSetBonus)w.GetBuff(EET_LynxSetBonus);
	GMTestReport(lynx && lynx.GMGetStacks() == 0, "ARM-06 the chain broke after 3 s without hits (" + lynx.GMGetStacks() + "%)");
	GMTestArmRestore(w.gmTestArmAdded, w.gmTestArmOld);
}

// ARM-09: the Wolven set's values, legacy's descriptions, nothing without the set. No gear needed.
function GMTest_arm09()
{
	var w : W3PlayerWitcher;

	w = GetWitcherPlayer();
	GMTestReport(GMTestArmNear(GMTestArmAbl('SetBonusAbilityWolf_1', 'per_piece_oil_bonus'), 0.167) && GMTestArmNear(GMTestArmAbl('SetBonusAbilityWolf_1', 'max_oils_count'), 0)
		&& GMTestArmNear(GMTestArmAbl('SetBonusAbilityWolf_2', 'max_oils_count'), 3) && GMTestArmNear(GMTestArmAbl('SetBonusAbilityWolf_2', 'per_oil_crit_chance_bonus'), 0.05)
		&& GMTestArmNear(GMTestArmAbl('SetBonusAbilityWolf_2', 'per_oil_crit_power_bonus'), 0.1) && GetSetBonusAbility(EISB_Wolf_2) == 'SetBonusAbilityWolf_2',
		"ARM-09 Wolven values: oils +16.7% per piece; three oils, +5% crit chance and +10% crit damage per oil");
	GMTestReport(w.IsSetBonusActive(EISB_Wolf_1) || (GMTestArmNear(GMWolfOilMult(), 1) && w.GMMaxOilsPerSword() == 1), "ARM-09 without the set: oil factor " + GMWolfOilMult() + ", oils per sword " + w.GMMaxOilsPerSword());
	GMTestReport(StrBeginsWith(w.GetSetBonusTooltipDescription(EISB_Wolf_1), "Each set piece increases the effectiveness of an oil") && StrBeginsWith(w.GetSetBonusTooltipDescription(EISB_Wolf_2), "Up to three different oils"),
		"ARM-09 descriptions: " + w.GetSetBonusTooltipDescription(EISB_Wolf_1) + " / " + w.GetSetBonusTooltipDescription(EISB_Wolf_2));
}

// The oils' attack power against humans on the equipped steel sword.
function GMTestArmOilAP() : float
{
	var w : W3PlayerWitcher;
	var v : SAbilityAttributeValue;

	w = GetWitcherPlayer();
	v = w.inv.GMOilBonus(w.GetEquippedSword(true), MC_Human, 'vsHuman_attack_power');
	return v.valueMultiplicative;
}

// Geralt's crit damage bonus with the sword against humans.
function GMTestArmCritDmg(sword : SItemUniqueId) : float
{
	var v : SAbilityAttributeValue;

	v = GetWitcherPlayer().GetCriticalHitDamageBonus(sword, MC_Human, false);
	return v.valueAdditive;
}

// The oils on the equipped steel or silver sword, as text.
function GMTestArmOils(steel : bool) : string
{
	var w : W3PlayerWitcher;
	var oils : array<W3Effect_Oil>;
	var line : string;
	var i : int;

	w = GetWitcherPlayer();
	oils = w.inv.GetOilsAppliedOnItem(w.GetEquippedSword(steel));
	line = oils.Size() + " oils:";
	for(i = 0; i < oils.Size(); i += 1)
		line += " " + oils[i].GetOilItemName() + " " + oils[i].GetAmmoCurrentCount() + "/" + oils[i].GetAmmoMaxCount();
	return line;
}

function GMTestArmOilCount(steel : bool) : int
{
	var w : W3PlayerWitcher;
	var oils : array<W3Effect_Oil>;

	w = GetWitcherPlayer();
	oils = w.inv.GetOilsAppliedOnItem(w.GetEquippedSword(steel));
	return oils.Size();
}

// Applies an oil to the equipped steel or silver sword (as the inventory does).
function GMTestArmApplyOil(oilName : name, steel : bool) : bool
{
	var w : W3PlayerWitcher;
	var ids : array<SItemUniqueId>;

	w = GetWitcherPlayer();
	ids = w.inv.AddAnItem(oilName, 1);
	return w.ApplyOil(ids[0], w.GetEquippedSword(steel));
}

// ARM-09 with gear and a neutral human test dummy (setlevel(50), gmtest_dummy("human"), then
// gmtest_dummy_neutral() first): the human oil's share of a scripted steel sword hit's attack power
// without the set, with three lower-tier pieces (+50.1%) and six grandmaster pieces (+100.2%); one oil
// per sword without tier 2; with it three oils on the silver sword (only two oils fit the steel one),
// the oldest replaced by a fourth, +5% crit chance and +10% crit damage per oil wearing off with the
// oils; 5.x's bleeding stacks gone. Leaves the six pieces and three oils for gmtest_arm09_b().
exec function gmtest_arm09()
{
	var w : W3PlayerWitcher;
	var npc : CActor;
	var old, added : array<SItemUniqueId>;
	var names : array<name>;
	var id, silver : SItemUniqueId;
	var b0, b1, b2, m0, m1, m2, g, cd3, cd0, cdHalf, wolfChance : float;
	var probes : bool;
	var i : int;

	w = GetWitcherPlayer();
	npc = GMTestHostileNpc();
	if(!npc)
	{
		LogChannel('GMTest', "FAIL ARM-09: no hostile NPC (gmtest_dummy first)");
		return;
	}
	probes = GMTestProbes();
	w.GMTestSetProbes(true);
	old = GMTestArmWorn();
	if(w.GetItemEquippedOnSlot(EES_SteelSword, id)) old.PushBack(id);
	if(w.GetItemEquippedOnSlot(EES_SilverSword, id)) old.PushBack(id);

	// Without the set.
	b0 = GMTestArmOilHit(npc, m0);

	// Three lower-tier pieces: tier 1.
	names.PushBack('Wolf Armor'); names.PushBack('Wolf Gloves 1'); names.PushBack('Wolf Pants 1');
	GMTestArmWear(names, added);
	b1 = GMTestArmOilHit(npc, m1);
	GMTestReport(w.IsSetBonusActive(EISB_Wolf_1) && !w.IsSetBonusActive(EISB_Wolf_2) && GMTestArmNear(b1 / b0, 1.501) && GMTestArmNear(m1, b1),
		"ARM-09 three lower-tier pieces: tier 1; the oil's attack power vs humans " + b1 + " against " + b0 + " (expected x1.501); in a hit +" + m1);
	GMTestArmApplyOil('Beast Oil 1', true);
	GMTestReport(GMTestArmOilCount(true) == 1, "ARM-09 without tier 2 a second oil replaces the first: " + GMTestArmOils(true));
	w.inv.RemoveAllOilsFromItem(w.GetEquippedSword(true));
	GMTestArmRestore(added, added);
	added.Clear();
	names.Clear();

	// Six grandmaster pieces: tier 2.
	names.PushBack('Wolf Armor 4'); names.PushBack('Wolf Gloves 5'); names.PushBack('Wolf Pants 5'); names.PushBack('Wolf Boots 5');
	names.PushBack('Wolf School steel sword 4'); names.PushBack('Wolf School silver sword 4');
	GMTestArmWear(names, added);
	b2 = GMTestArmOilHit(npc, m2);
	w.inv.RemoveAllOilsFromItem(w.GetEquippedSword(true));
	GMTestReport(w.IsSetBonusActive(EISB_Wolf_2) && GMTestArmNear(b2 / b0, 2.002) && GMTestArmNear(m2, b2),
		"ARM-09 six grandmaster pieces: tier 2; the oil's attack power vs humans " + b2 + " (expected x2.002); in a hit +" + m2);
	silver = w.GetEquippedSword(false);
	w.inv.RemoveAllOilsFromItem(silver);
	GMTestArmApplyOil('Necrophage Oil 1', false);
	GMTestArmApplyOil('Cursed Oil 1', false);
	GMTestArmApplyOil('Hybrid Oil 1', false);
	GMTestReport(GMTestArmOilCount(false) == 3, "ARM-09 tier 2: three oils on the silver sword: " + GMTestArmOils(false));
	cd3 = GMTestArmCritDmg(silver);
	wolfChance = w.inv.GMOilWolfCritBonus(silver, 'per_oil_crit_chance_bonus');
	GMTestArmApplyOil('Specter Oil 1', false);
	GMTestReport(GMTestArmOilCount(false) == 3 && !w.IsEquippedSwordUpgradedWithOil(false, 'Necrophage Oil 1') && w.IsEquippedSwordUpgradedWithOil(false, 'Specter Oil 1'),
		"ARM-09 a fourth oil replaces the oldest: " + GMTestArmOils(false));
	for(i = 0; i < 10; i += 1)
		w.ReduceAllOilsAmmo(silver);
	cdHalf = GMTestArmCritDmg(silver);
	w.inv.RemoveAllOilsFromItem(silver);
	cd0 = GMTestArmCritDmg(silver);
	GMTestReport(GMTestArmNear(cd3 - cd0, 0.3) && GMTestArmNear(cdHalf - cd0, 0.225) && GMTestArmNear(wolfChance, 0.15),
		"ARM-09 per oil: crit damage +" + (cd3 - cd0) + " with three fresh oils (expected 0.3), +" + (cdHalf - cd0) + " at half charges (0.225); crit chance +" + wolfChance + " (0.15)");

	// 5.x's bleeding stacks by adrenaline are gone.
	w.ForceSetStat(BCS_Focus, 3);
	npc.AddEffectDefault(EET_Bleeding, w, "gmtest");
	npc.AddEffectDefault(EET_Bleeding, w, "gmtest");
	GMTestReport(npc.HasBuff(EET_Bleeding) && !npc.HasBuff(EET_Bleeding1) && !npc.HasBuff(EET_Bleeding2) && !npc.HasBuff(EET_Bleeding3) && w.IsSetBonusActive(EISB_Wolf_2),
		"ARM-09 a second bleed at 3 adrenaline adds no wound stack (Bleeding1 " + npc.HasBuff(EET_Bleeding1) + "), tier 2 still read " + w.IsSetBonusActive(EISB_Wolf_2));
	npc.RemoveAllBuffsOfType(EET_Bleeding);
	w.ForceSetStat(BCS_Focus, 0);

	// Three oils on the held silver sword for gmtest_arm09_b().
	GMTestArmApplyOil('Necrophage Oil 1', false);
	GMTestArmApplyOil('Cursed Oil 1', false);
	GMTestArmApplyOil('Hybrid Oil 1', false);
	w.GMTestSetProbes(probes);
	w.GMTestArmKeep(added, old);
	LogChannel('GMTest', "INFO ARM-09 six pieces worn, " + GMTestArmOils(false) + "; run gmtest_draw(true), then gmtest_arm09_b()");
}

// A fresh human oil on the steel sword: returns its attack power bonus against humans; hitShare
// returns how much it added to a scripted light hit's attack power (the hit with the oil less one
// without).
function GMTestArmOilHit(npc : CActor, out hitShare : float) : float
{
	var w : W3PlayerWitcher;
	var bonus, withOil, g : float;

	w = GetWitcherPlayer();
	GMTestApplyHumanOil();
	bonus = GMTestArmOilAP();
	withOil = GMTestArmSwordHit(npc, 'attack_light', false, g);
	w.inv.RemoveAllOilsFromItem(w.GetEquippedSword(true));
	hitShare = withOil - GMTestArmSwordHit(npc, 'attack_light', false, g);
	return bonus;
}

// After gmtest_arm09() and gmtest_draw(true) (the silver sword in hand): the crit chance of a light
// attack with its three oils; then a piece taken off: tier 2 ends and only the newest oil stays; the gear
// put back.
exec function gmtest_arm09_b()
{
	var w : W3PlayerWitcher;
	var npc : CActor;
	var id : SItemUniqueId;
	var c3, c1 : float;

	w = GetWitcherPlayer();
	npc = GMTestHostileNpc();
	c3 = w.GetCriticalHitChance(true, false, npc, MC_Human, false);
	LogChannel('GMTest', "INFO ARM-09 held sword " + w.inv.GetItemName(w.inv.GetCurrentlyHeldSword()) + ", its Wolven crit chance " + w.inv.GMOilWolfCritBonus(w.inv.GetCurrentlyHeldSword(), 'per_oil_crit_chance_bonus'));
	w.GetItemEquippedOnSlot(EES_Boots, id);
	w.UnequipItem(id);
	c1 = w.GetCriticalHitChance(true, false, npc, MC_Human, false);
	GMTestReport(!w.IsSetBonusActive(EISB_Wolf_2) && GMTestArmOilCount(false) == 1 && w.IsEquippedSwordUpgradedWithOil(false, 'Hybrid Oil 1') && GMTestArmNear(c3 - c1, 0.15),
		"ARM-09 a piece off: tier 2 " + w.IsSetBonusActive(EISB_Wolf_2) + ", " + GMTestArmOils(false) + " (the newest stays); light attack crit chance " + c3 + " with three oils, " + c1 + " after (expected -0.15)");
	w.inv.RemoveAllOilsFromItem(w.GetEquippedSword(false));
	GMTestArmRestore(w.gmTestArmAdded, w.gmTestArmOld);
	w.OnEquipMeleeWeapon(PW_Steel, true);
}

// Save impact: six grandmaster Wolven pieces and three oils on the silver sword, saved into a new
// manual slot; gmtest_arm09_oldsave() after loading it.
exec function gmtest_arm09_mksave()
{
	var names : array<name>;
	var added : array<SItemUniqueId>;

	names.PushBack('Wolf Armor 4'); names.PushBack('Wolf Gloves 5'); names.PushBack('Wolf Pants 5'); names.PushBack('Wolf Boots 5');
	names.PushBack('Wolf School steel sword 4'); names.PushBack('Wolf School silver sword 4');
	GMTestArmWear(names, added);
	GMTestArmApplyOil('Necrophage Oil 1', false);
	GMTestArmApplyOil('Cursed Oil 1', false);
	GMTestArmApplyOil('Hybrid Oil 1', false);
	LogChannel('GMTest', "ARM-09 save: " + GMTestArmOils(false) + ", tier 2 " + GetWitcherPlayer().IsSetBonusActive(EISB_Wolf_2) + "; saving into a new manual slot");
	theGame.SaveGame(SGT_Manual, -1);
}

exec function gmtest_arm09_oldsave()
{
	GMTestReport(GetWitcherPlayer().IsSetBonusActive(EISB_Wolf_2) && GMTestArmOilCount(false) == 3, "ARM-09 after loading: tier 2 " + GetWitcherPlayer().IsSetBonusActive(EISB_Wolf_2) + ", " + GMTestArmOils(false));
}

// ARM-10: the Manticore set's values, legacy's description, nothing without the set. No gear needed.
function GMTest_arm10()
{
	var w : W3PlayerWitcher;

	w = GetWitcherPlayer();
	GMTestReport(GMTestArmNear(GMTestArmAbl('setBonusAbilityRedWolf_1', 'per_redwolf_piece_crit_chance_bonus'), 0.05) && GMTestArmNear(GMTestArmAbl('setBonusAbilityRedWolf_1', 'per_redwolf_piece_crit_power_bonus'), 0.1)
		&& GetSetBonusAbility(EISB_RedWolf_1) == 'setBonusAbilityRedWolf_1' && GMTestArmNear(GMTestArmAbl('setBonusAbilityRedWolf_2', 'amount'), 1),
		"ARM-10 Manticore values: bombs +5% crit chance and +10% crit damage per piece; tier 2 +1 charge");
	GMTestReport(w.IsSetBonusActive(EISB_RedWolf_1) || GMTestArmNear(w.GMManticoreBombBonus('per_redwolf_piece_crit_chance_bonus'), 0), "ARM-10 without the set: no bomb crit bonus");
	GMTestReport(StrBeginsWith(w.GetSetBonusTooltipDescription(EISB_RedWolf_1), "Bombs are thrown without any delay and can deal critical damage. Each set piece increases bomb critical hit chance by 5%"),
		"ARM-10 description: " + w.GetSetBonusTooltipDescription(EISB_RedWolf_1));
}

// ARM-10 with a neutral human test dummy (gmtest_dummy("human"), then gmtest_dummy_neutral() first):
// three Manticore pieces worn: tier 1, a bomb's crit chance +0.15 (four pieces +0.2); every hit made a
// crit (debug fact) and the damage probe reset for a real bomb throw: gmtest_skl06_throw(true, false,
// true), gmtest_skl06_throw(false, false, true), then gmtest_arm10_b().
exec function gmtest_arm10()
{
	var w : W3PlayerWitcher;
	var npc : CActor;
	var old, added : array<SItemUniqueId>;
	var names : array<name>;
	var id : SItemUniqueId;
	var c0, c3 : float;

	w = GetWitcherPlayer();
	npc = GMTestHostileNpc();
	if(!npc)
	{
		LogChannel('GMTest', "FAIL ARM-10: no hostile NPC (gmtest_dummy first)");
		return;
	}
	old = GMTestArmWorn();
	c0 = w.GetCriticalHitChance(false, false, npc, MC_Human, false);
	names.PushBack('Red Wolf Armor 1'); names.PushBack('Red Wolf Gloves 1'); names.PushBack('Red Wolf Pants 1');
	GMTestArmWear(names, added);
	c3 = w.GMManticoreBombCritChance(npc, MC_Human);
	GMTestReport(w.IsSetBonusActive(EISB_RedWolf_1) && GMTestArmNear(c3 - c0, 0.15), "ARM-10 three pieces: tier 1 " + w.IsSetBonusActive(EISB_RedWolf_1) + ", a bomb's crit chance " + c3 + " against " + c0 + " (expected +0.15)");
	w.GMTestArmKeep(added, old);
	FactsAdd('debug_fact_critical_boy', 1);
	w.GMTestSetProbes(true);
	w.GMTestDmgReset();
	LogChannel('GMTest', "INFO ARM-10 throw a bomb now, then gmtest_arm10_b()");
}

@addField(W3PlayerWitcher)
public var gmTestArm10Mult : float;

// The highest attack power the damage probe recorded since its reset (a bomb's impact among its
// cloud's damage-over-time ticks).
@addMethod(CR4Player)
function GMTestDmgMaxMult() : float
{
	var i : int;
	var m : float;

	for(i = 0; i < gmTestDmgSteps.Size(); i += 1)
		m = MaxF(m, gmTestDmgSteps[i].mult);
	return m;
}

@addMethod(W3PlayerWitcher)
function GMTestArm10Keep(m : float)
{
	gmTestArm10Mult = m;
}

// The bomb's crit hit with three pieces recorded; the fourth piece (boots) put on: crit chance +0.2;
// the probe reset for a second throw, then gmtest_arm10_c().
exec function gmtest_arm10_b()
{
	var w : W3PlayerWitcher;
	var npc : CActor;
	var added : array<SItemUniqueId>;
	var c0, c4 : float;

	w = GetWitcherPlayer();
	npc = GMTestHostileNpc();
	w.GMTestArm10Keep(w.GMTestDmgMaxMult());
	LogChannel('GMTest', "INFO ARM-10 bomb impact with three pieces: attack power mult " + w.gmTestArm10Mult);
	added = w.gmTestArmAdded;
	added.PushBack(GMTestArmAdd('Red Wolf Boots 1', true));
	w.GMTestArmKeep(added, w.gmTestArmOld);
	c0 = w.GetCriticalHitChance(false, false, npc, MC_Human, false);
	c4 = w.GMManticoreBombCritChance(npc, MC_Human);
	GMTestReport(GMTestArmNear(c4 - c0, 0.2), "ARM-10 four pieces: a bomb's crit chance +" + (c4 - c0) + " (expected 0.2)");
	w.GMTestDmgReset();
}

// The second bomb's crit damage: +0.1 for the fourth piece; the fact, probes and gear put back.
exec function gmtest_arm10_c()
{
	var w : W3PlayerWitcher;
	var m4 : float;

	w = GetWitcherPlayer();
	m4 = w.GMTestDmgMaxMult();
	GMTestReport(w.gmTestArm10Mult > 1 && GMTestArmNear(m4 - w.gmTestArm10Mult, 0.1), "ARM-10 bomb crits: attack power mult " + m4 + " with four pieces, " + w.gmTestArm10Mult + " with three (expected +0.1)");
	FactsRemove('debug_fact_critical_boy');
	w.GMTestSetProbes(false);
	GMTestArmRestore(w.gmTestArmAdded, w.gmTestArmOld);
}

// A scripted 100 poison damage hit by Geralt on himself at half Vitality; returns the Vitality gained
// (negative: taken); Vitality restored after.
function GMTestArmPoisonHit() : float
{
	var action : W3DamageAction;
	var before, half : float;

	before = thePlayer.GetStat(BCS_Vitality);
	half = thePlayer.GetStatMax(BCS_Vitality) / 2;
	thePlayer.ForceSetStat(BCS_Vitality, half);
	action = new W3DamageAction in theGame.damageMgr;
	action.Initialize(thePlayer, thePlayer, NULL, "gmtest", EHRT_None, CPS_Undefined, false, false, false, false);
	action.AddDamage(theGame.params.DAMAGE_NAME_POISON, 100);
	theGame.damageMgr.ProcessAction(action);
	delete action;
	half = thePlayer.GetStat(BCS_Vitality) - half;
	thePlayer.ForceSetStat(BCS_Vitality, before);
	thePlayer.RemoveAllBuffsOfType(EET_Poison);
	return half;
}

// ARM-11: the Viper set's value and legacy's text, nothing without the set. No gear needed.
function GMTest_arm11()
{
	var w : W3PlayerWitcher;

	w = GetWitcherPlayer();
	GMTestReport(GMTestArmNear(GMTestArmAbl('setBonusAbilityViper_1', 'per_viper_piece_poison_healing_rate'), 0.1), "ARM-11 Viper value: poison heals 10% per piece");
	GMTestReport(w.IsSetBonusActive(EISB_Viper) || GMTestArmNear(w.GMViperPoisonHealRate(), 0), "ARM-11 without the set: no healing");
	GMTestReport(StrBeginsWith(w.GetSetBonusTooltipDescription(EISB_Viper), "Grants poison immunity. Poisons heal by 10%"), "ARM-11 description: " + w.GetSetBonusTooltipDescription(EISB_Viper));
}

// ARM-11 with gear (setlevel(50) first): 100 poison damage (a scripted hit) hurts without the set; with
// three Viper pieces it heals 30, with all four 40; the gear put back.
exec function gmtest_arm11()
{
	var w : W3PlayerWitcher;
	var old, added : array<SItemUniqueId>;
	var names : array<name>;
	var without, with3, with4 : float;

	w = GetWitcherPlayer();
	w.RemoveBuff(EET_GoldenOriole);
	old = GMTestArmWorn();
	without = GMTestArmPoisonHit();
	names.PushBack('EP1 Witcher Armor'); names.PushBack('EP1 Witcher Gloves'); names.PushBack('EP1 Witcher Pants');
	GMTestArmWear(names, added);
	with3 = GMTestArmPoisonHit();
	GMTestReport(w.IsSetBonusActive(EISB_Viper) && GMTestArmNear(with3, 30) && without < 0,
		"ARM-11 three Viper pieces: set " + w.IsSetBonusActive(EISB_Viper) + ", 100 poison damage gave " + with3 + " Vitality (expected +30), without the set " + without);
	added.PushBack(GMTestArmAdd('EP1 Witcher Boots', true));
	with4 = GMTestArmPoisonHit();
	GMTestReport(GMTestArmNear(with4, 40), "ARM-11 four Viper pieces: 100 poison damage gave " + with4 + " Vitality (expected +40)");
	GMTestArmRestore(added, old);
}

// ARM-13: the Tesham Mutna set's value and legacy's text. No gear needed.
function GMTest_arm13()
{
	var w : W3PlayerWitcher;

	w = GetWitcherPlayer();
	GMTestReport(GMTestArmNear(GMTestArmAbl('setBonusAbilityVampire', 'life_percent'), 0.5), "ARM-13 Tesham Mutna value: 0.5% of maximum Vitality per piece per hit");
	GMTestReport(StrBeginsWith(w.GetSetBonusTooltipDescription(EISB_Vampire), "Dealing damage in combat heals 0.5% of maximum Vitality"), "ARM-13 description: " + w.GetSetBonusTooltipDescription(EISB_Vampire));
}

// ARM-13 with gear and a neutral test dummy (setlevel(50), gmtest_dummy("human"), then
// gmtest_dummy_neutral() first): a scripted sword hit at half Vitality heals nothing without the set,
// 1.5% of maximum Vitality with three pieces, 2% with four; a killing hit heals once (no kill heal).
// The gear put back; the dummy dies.
exec function gmtest_arm13()
{
	var w : W3PlayerWitcher;
	var npc : CActor;
	var old, added : array<SItemUniqueId>;
	var names : array<name>;
	var h0, h3, h4, hKill, g : float;

	w = GetWitcherPlayer();
	npc = GMTestHostileNpc();
	if(!npc)
	{
		LogChannel('GMTest', "FAIL ARM-13: no hostile NPC (gmtest_dummy first)");
		return;
	}
	old = GMTestArmWorn();
	h0 = GMTestArmVampireHit(npc, false);
	names.PushBack('q702_vampire_armor'); names.PushBack('q702_vampire_gloves'); names.PushBack('q702_vampire_pants');
	GMTestArmWear(names, added);
	h3 = GMTestArmVampireHit(npc, false);
	added.PushBack(GMTestArmAdd('q702_vampire_boots', true));
	h4 = GMTestArmVampireHit(npc, false);
	hKill = GMTestArmVampireHit(npc, true);
	GMTestReport(w.IsSetBonusActive(EISB_Vampire) && GMTestArmNear(h0, 0) && GMTestArmNear(h3, 0.015) && GMTestArmNear(h4, 0.02),
		"ARM-13 a hit heals (share of max Vitality): " + h0 + " without the set, " + h3 + " with three pieces (expected 0.015), " + h4 + " with four (0.02)");
	GMTestReport(GMTestArmNear(hKill, 0.02) && !npc.IsAlive(), "ARM-13 a killing hit healed " + hKill + " (expected 0.02: no kill heal), dummy dead " + !npc.IsAlive());
	GMTestArmRestore(added, old);
}

// One scripted sword hit on the NPC at half Vitality (with kill, the NPC at 1 Vitality); returns the
// Vitality gained as a share of the maximum. Vitality restored after.
function GMTestArmVampireHit(npc : CActor, kill : bool) : float
{
	var w : W3PlayerWitcher;
	var action : W3Action_Attack;
	var id : SItemUniqueId;
	var before, half, gained : float;

	w = GetWitcherPlayer();
	w.GetItemEquippedOnSlot(EES_SteelSword, id);
	before = w.GetStat(BCS_Vitality);
	half = w.GetStatMax(BCS_Vitality) / 2;
	w.ForceSetStat(BCS_Vitality, half);
	if(kill)
		npc.ForceSetStat(BCS_Vitality, 1);
	action = new W3Action_Attack in theGame.damageMgr;
	action.Init(w, npc, NULL, id, 'attack_light', w.GetName(), EHRT_Light, false, false, 'attack_light', AST_Jab, ASD_UpDown, true, false, false, false);
	action.SetSuppressHitSounds(true);
	action.SetHitAnimationPlayType(EAHA_ForceNo);
	theGame.damageMgr.ProcessAction(action);
	delete action;
	gained = (w.GetStat(BCS_Vitality) - half) / w.GetStatMax(BCS_Vitality);
	w.ForceSetStat(BCS_Vitality, before);
	if(!kill)
		npc.ForceSetStat(BCS_Vitality, npc.GetStatMax(BCS_Vitality));
	return gained;
}

// ARM-13: a later kill heal would come after the hit: with the set worn (gmtest_arm13_wear()), a hostile
// test dummy killed by a scripted hit at half Vitality; gmtest_arm13_kill_b() a second later reports
// whether Vitality changed since.
exec function gmtest_arm13_kill_a()
{
	var w : W3PlayerWitcher;
	var npc : CActor;
	var action : W3Action_Attack;
	var id : SItemUniqueId;

	w = GetWitcherPlayer();
	npc = GMTestHostileNpc();
	w.GetItemEquippedOnSlot(EES_SteelSword, id);
	w.ForceSetStat(BCS_Vitality, w.GetStatMax(BCS_Vitality) / 2);
	npc.ForceSetStat(BCS_Vitality, 1);
	action = new W3Action_Attack in theGame.damageMgr;
	action.Init(w, npc, NULL, id, 'attack_light', w.GetName(), EHRT_Light, false, false, 'attack_light', AST_Jab, ASD_UpDown, true, false, false, false);
	theGame.damageMgr.ProcessAction(action);
	delete action;
	w.GMTestArmKeepValues(w.GetStat(BCS_Vitality), 0);
	LogChannel('GMTest', "INFO ARM-13 kill: Vitality " + w.GetStat(BCS_Vitality) + " of " + w.GetStatMax(BCS_Vitality) + " right after, dummy alive " + npc.IsAlive());
}

exec function gmtest_arm13_kill_b()
{
	var w : W3PlayerWitcher;

	w = GetWitcherPlayer();
	GMTestReport(GMTestArmNear(w.GetStat(BCS_Vitality), w.gmTestArmRes), "ARM-13 no kill heal after the killing hit: Vitality " + w.GetStat(BCS_Vitality) + " against " + w.gmTestArmRes + " right after it");
	w.ForceSetStat(BCS_Vitality, w.GetStatMax(BCS_Vitality));
}

exec function gmtest_arm13_wear()
{
	var w : W3PlayerWitcher;
	var old, added : array<SItemUniqueId>;
	var names : array<name>;

	w = GetWitcherPlayer();
	old = GMTestArmWorn();
	names.PushBack('q702_vampire_armor'); names.PushBack('q702_vampire_gloves'); names.PushBack('q702_vampire_pants'); names.PushBack('q702_vampire_boots');
	GMTestArmWear(names, added);
	w.GMTestArmKeep(added, old);
	LogChannel('GMTest', "INFO ARM-13 worn: set " + w.IsSetBonusActive(EISB_Vampire) + "; gmtest_arm_restore() puts the gear back");
}

// ARM-12: the Kaer Morhen set's items, schematics, names and effect values. No gear needed.
function GMTest_arm12()
{
	var w : W3PlayerWitcher;
	var dm : CDefinitionsManagerAccessor;
	var schem : SCraftingSchematic;
	var known : array<name>;
	var startId : SItemUniqueId;
	var ids : array<SItemUniqueId>;

	w = GetWitcherPlayer();
	dm = theGame.GetDefinitionsManager();
	GMTestReport(dm.ItemHasTag('Kaer Morhen Armor', 'KaerMorhenSet') && dm.ItemHasTag('Kaer Morhen Gloves 3', 'KaerMorhenSet') && dm.ItemHasTag('Kaer Morhen Pants 2', 'MediumArmor')
		&& dm.GetItemCategory('Kaer Morhen Boots 1') == 'boots' && GMTestArmHasAbility('Kaer Morhen Armor 3', 'Kaer Morhen Armor 3 _Stats') && GMTestArmNear(GMTestArmAbl('Kaer Morhen Armor 3 _Stats', 'armor'), 160),
		"ARM-12 the Kaer Morhen pieces exist: set tag, medium class, category, stats (armor 3: armor " + GMTestArmAbl('Kaer Morhen Armor 3 _Stats', 'armor') + ")");
	schem = getCraftingSchematicFromName('Kaer Morhen Armor schematic');
	GMTestReport(schem.craftedItemName == 'Kaer Morhen Armor' && schem.ingredients.Size() == 5 && schem.ingredients[0].itemName == 'Starting Armor', "ARM-12 the first armor schematic makes " + schem.craftedItemName + " from " + schem.ingredients[0].itemName);
	schem = getCraftingSchematicFromName('Kaer Morhen Gloves 3 schematic');
	GMTestReport(schem.craftedItemName == 'Kaer Morhen Gloves 3' && schem.ingredients[0].itemName == 'Kaer Morhen Gloves 2', "ARM-12 the last gloves schematic makes " + schem.craftedItemName + " from " + schem.ingredients[0].itemName);
	known = w.GetCraftingSchematicsNames();
	GMTestReport(known.Contains('Kaer Morhen Armor schematic') && known.Contains('Kaer Morhen Pants schematic') && known.Contains('Kaer Morhen Gloves 3 schematic') && FactsQuerySum("gm_km_schematics_added") > 0,
		"ARM-12 Geralt knows the set's schematics");
	ids = w.inv.AddAnItem('Starting Armor', 1);
	GMTestReport(StrBeginsWith(GetLocStringByKeyExt(w.inv.GetItemLocalizedNameByUniqueID(ids[0])), "Worn Kaer Morhen") && GetLocStringByKeyExt(dm.GetItemLocalisationKeyName('Kaer Morhen Armor 1')) == "Enhanced Kaer Morhen armor",
		"ARM-12 names: " + GetLocStringByKeyExt(w.inv.GetItemLocalizedNameByUniqueID(ids[0])) + ", " + GetLocStringByKeyExt(dm.GetItemLocalisationKeyName('Kaer Morhen Armor 1')));
	w.inv.RemoveItem(ids[0], 1);
	GMTestReport(GMTestArmNear(GMTestArmAbl('GMKaerMorhenSetBonusEffect', 'staminaRegen'), 1) && GMTestArmNear(GMKaerMorhenMaxStacks(), 5) && StrBeginsWith(w.GetSetBonusTooltipDescription(EISB_KaerMorhen), "Stamina regeneration rate increases by 1 for each additional enemy in combat (max. 5)"),
		"ARM-12 bonus values and text: " + w.GetSetBonusTooltipDescription(EISB_KaerMorhen));
}

// ARM-12 with gear (setlevel(30) first): three Kaer Morhen pieces give the set; then call
// gmtest_dummy("human") three times (separate calls), wait 2 s and run gmtest_arm12_b().
exec function gmtest_arm12()
{
	var w : W3PlayerWitcher;
	var old, added : array<SItemUniqueId>;
	var names : array<name>;

	w = GetWitcherPlayer();
	old = GMTestArmWorn();
	names.PushBack('Kaer Morhen Armor 3'); names.PushBack('Kaer Morhen Pants 2'); names.PushBack('Kaer Morhen Gloves 1');
	GMTestArmWear(names, added);
	w.GMTestArmKeep(added, old);
	GMTestReport(w.IsSetBonusActive(EISB_KaerMorhen) && w.GetSetPartsEquipped(EIST_KaerMorhen) == 3, "ARM-12 three Kaer Morhen pieces of mixed tiers: set " + w.IsSetBonusActive(EISB_KaerMorhen));
}

// In combat with three hostile dummies: the effect gives two regen abilities (+2 stamina regen); the
// gear put back ends it.
exec function gmtest_arm12_b()
{
	var w : W3PlayerWitcher;
	var count : int;
	var regen : float;

	w = GetWitcherPlayer();
	count = w.GetAbilityCount('GMKaerMorhenSetBonusEffect');
	regen = GMTestArmRegenAttr();
	GMTestReport(w.IsInCombat() && w.HasBuff(EET_GMKaerMorhenSetBonus) && count == 2 && w.GMGetNumHostilesInRange() == 3,
		"ARM-12 in combat with " + w.GMGetNumHostilesInRange() + " enemies: effect " + w.HasBuff(EET_GMKaerMorhenSetBonus) + ", regen abilities " + count + " (expected 2), staminaRegen " + regen);
	GMTestArmRestore(w.gmTestArmAdded, w.gmTestArmOld);
	GMTestReport(!w.HasBuff(EET_GMKaerMorhenSetBonus) && w.GetAbilityCount('GMKaerMorhenSetBonusEffect') == 0, "ARM-12 the gear taken off ends the effect and its abilities");
}

function GMTestArmRegenAttr() : float
{
	var v : SAbilityAttributeValue;

	v = GetWitcherPlayer().GetAttributeValue('staminaRegen');
	return v.valueAdditive;
}

// ARM-12 save impact: four Kaer Morhen pieces worn and a spare in the bag, saved into a new manual slot
// (no hostile NPC may be near); gmtest_arm12_oldsave() after loading it.
exec function gmtest_arm12_mksave()
{
	var names : array<name>;
	var added : array<SItemUniqueId>;

	names.PushBack('Kaer Morhen Armor 3'); names.PushBack('Kaer Morhen Pants 2'); names.PushBack('Kaer Morhen Gloves 1'); names.PushBack('Kaer Morhen Boots');
	GMTestArmWear(names, added);
	GMTestArmAdd('Kaer Morhen Armor 1', false);
	LogChannel('GMTest', "ARM-12 save: set " + GetWitcherPlayer().IsSetBonusActive(EISB_KaerMorhen) + ", saving into a new manual slot");
	theGame.SaveGame(SGT_Manual, -1);
}

exec function gmtest_arm12_oldsave()
{
	var w : W3PlayerWitcher;
	var id : SItemUniqueId;

	w = GetWitcherPlayer();
	w.GetItemEquippedOnSlot(EES_Armor, id);
	GMTestReport(w.IsSetBonusActive(EISB_KaerMorhen) && w.inv.GetItemName(id) == 'Kaer Morhen Armor 3' && w.inv.HasItem('Kaer Morhen Armor 1'),
		"ARM-12 after loading: set " + w.IsSetBonusActive(EISB_KaerMorhen) + ", armor worn " + w.inv.GetItemName(id) + ", spare in the bag " + w.inv.HasItem('Kaer Morhen Armor 1'));
}

// ARM-12 New Game+: the 16 "Base Kaer Morhen ... _Stats" abilities the NG+ pieces (NGP Kaer Morhen *)
// carry, with legacy's values (legacy's items_plus/def_item_crafting_*.xml). They are defined only in
// the DLC's items_plus folder; this reads them through the definitions manager. 0 if one is missing.
// Only an NG+ game reads items_plus: in a regular game (the test save) the abilities and the NGP Kaer
// Morhen items are unknown, before and after the fix (seen 2026-11-02), so this is not in the regression:
// run gmtest_arm12_ngplus() in an NG+ game. Offline: gen_arm_km.py --verify and dlc_conflicts.py.
function GMTestArm12Plus(abl : name, weight, quality, armor, slashing, piercing, bludgeoning, rending, elemental : float) : int
{
	if(GMTestArmNear(GMTestArmAbl(abl, 'weight'), weight) && GMTestArmNear(GMTestArmAbl(abl, 'quality'), quality) && GMTestArmNear(GMTestArmAbl(abl, 'armor'), armor)
		&& GMTestArmNear(GMTestArmAbl(abl, 'slashing_resistance_perc'), slashing) && GMTestArmNear(GMTestArmAbl(abl, 'piercing_resistance_perc'), piercing)
		&& GMTestArmNear(GMTestArmAbl(abl, 'bludgeoning_resistance_perc'), bludgeoning) && GMTestArmNear(GMTestArmAbl(abl, 'rending_resistance_perc'), rending)
		&& GMTestArmNear(GMTestArmAbl(abl, 'elemental_resistance_perc'), elemental))
		return 1;
	LogChannel('GMTest', "INFO ARM-12 NG+ " + abl + ": armor " + GMTestArmAbl(abl, 'armor') + ", slashing " + GMTestArmAbl(abl, 'slashing_resistance_perc') + ", weight " + GMTestArmAbl(abl, 'weight'));
	return 0;
}

function GMTest_arm12_ngplus()
{
	var dm : CDefinitionsManagerAccessor;
	var n : int;

	dm = theGame.GetDefinitionsManager();
	n += GMTestArm12Plus('Base Kaer Morhen Armor _Stats', 10.0, 5.0, 35.0, 0.14, 0.06, 0.06, 0.14, 0.14);
	n += GMTestArm12Plus('Base Kaer Morhen Armor 1 _Stats', 10.0, 5.0, 70.0, 0.16, 0.08, 0.08, 0.16, 0.16);
	n += GMTestArm12Plus('Base Kaer Morhen Armor 2 _Stats', 10.0, 5.0, 120.0, 0.18, 0.09, 0.09, 0.18, 0.18);
	n += GMTestArm12Plus('Base Kaer Morhen Armor 3 _Stats', 10.0, 5.0, 160.0, 0.2, 0.1, 0.1, 0.2, 0.2);
	n += GMTestArm12Plus('Base Kaer Morhen Boots _Stats', 4.0, 5.0, 9.0, 0.05, 0.03, 0.03, 0.05, 0.05);
	n += GMTestArm12Plus('Base Kaer Morhen Boots 1 _Stats', 4.0, 5.0, 23.0, 0.06, 0.04, 0.04, 0.06, 0.06);
	n += GMTestArm12Plus('Base Kaer Morhen Boots 2 _Stats', 4.0, 5.0, 43.0, 0.07, 0.05, 0.05, 0.07, 0.07);
	n += GMTestArm12Plus('Base Kaer Morhen Boots 3 _Stats', 4.0, 5.0, 59.0, 0.08, 0.06, 0.06, 0.08, 0.08);
	n += GMTestArm12Plus('Base Kaer Morhen Gloves _Stats', 3.0, 5.0, 5.0, 0.05, 0.03, 0.03, 0.05, 0.05);
	n += GMTestArm12Plus('Base Kaer Morhen Gloves 1 _Stats', 3.0, 5.0, 19.0, 0.05, 0.04, 0.04, 0.06, 0.05);
	n += GMTestArm12Plus('Base Kaer Morhen Gloves 2 _Stats', 3.0, 5.0, 39.0, 0.06, 0.04, 0.04, 0.07, 0.06);
	n += GMTestArm12Plus('Base Kaer Morhen Gloves 3 _Stats', 3.0, 5.0, 55.0, 0.07, 0.05, 0.05, 0.07, 0.07);
	n += GMTestArm12Plus('Base Kaer Morhen Pants _Stats', 3.0, 5.0, 9.0, 0.06, 0.03, 0.03, 0.06, 0.06);
	n += GMTestArm12Plus('Base Kaer Morhen Pants 1 _Stats', 3.0, 5.0, 23.0, 0.07, 0.04, 0.04, 0.07, 0.07);
	n += GMTestArm12Plus('Base Kaer Morhen Pants 2 _Stats', 3.0, 5.0, 43.0, 0.08, 0.05, 0.05, 0.08, 0.08);
	n += GMTestArm12Plus('Base Kaer Morhen Pants 3 _Stats', 3.0, 5.0, 59.0, 0.09, 0.06, 0.06, 0.09, 0.09);
	GMTestReport(n == 16, "ARM-12 NG+ base abilities of the NGP Kaer Morhen pieces read legacy's stats: " + n + " of 16");
	LogChannel('GMTest', "INFO ARM-12 NG+ items in this game: NGP Kaer Morhen Armor category '" + dm.GetItemCategory('NGP Kaer Morhen Armor') + "', names its base ability "
		+ GMTestArmHasAbility('NGP Kaer Morhen Armor', 'Base Kaer Morhen Armor _Stats') + "; regular Kaer Morhen Armor 3 armor " + GMTestArmAbl('Kaer Morhen Armor 3 _Stats', 'armor'));
}

exec function gmtest_arm12_ngplus()
{
	GMTest_arm12_ngplus();
}

// ARM-03: with STAM-05's option on (set for the test, then put back), legacy's armor regen modifier:
// naked +20% (11+2+3+4 for the missing pieces); four heavy pieces their legacy values; Heft's
// ability on Geralt changes nothing. The gear put back.
function GMTest_arm03()
{
	var w : W3PlayerWitcher;
	var old, added : array<SItemUniqueId>;
	var names : array<name>;
	var previous : string;
	var naked, heavy, heft : float;
	var expected : float;
	var attr : SAbilityAttributeValue;
	var i : int;

	w = GetWitcherPlayer();
	previous = theGame.GetInGameConfigWrapper().GetVarValue('GMGameplayOptions', 'GMArmorRegenPenalty');
	theGame.GetInGameConfigWrapper().SetVarValue('GMGameplayOptions', 'GMArmorRegenPenalty', "true");
	old = GMTestArmWorn();
	for(i = 0; i < old.Size(); i += 1)
		w.UnequipItem(old[i]);
	naked = w.CalculatedArmorStaminaRegenBonus();
	names.PushBack('Heavy armor 01'); names.PushBack('Heavy gloves 01'); names.PushBack('Heavy pants 01'); names.PushBack('Heavy boots 01');
	GMTestArmWear(names, added);
	heavy = w.CalculatedArmorStaminaRegenBonus();
	expected = GMTestArmItemRegen('Heavy armor 01') + GMTestArmItemRegen('Heavy gloves 01') + GMTestArmItemRegen('Heavy pants 01') + GMTestArmItemRegen('Heavy boots 01');
	w.AddAbility('Glyphword 4 _Stats', false);
	heft = w.CalculatedArmorStaminaRegenBonus();
	w.RemoveAbility('Glyphword 4 _Stats');
	GMTestReport(GMTestArmNear(naked, 0.2) && GMTestArmNear(heavy, expected) && GMTestArmNear(GMTestArmItemRegen('Heavy armor 01'), -0.3) && GMTestArmNear(heft, heavy),
		"ARM-03 option on: naked " + naked + " (expected 0.2), four heavy pieces " + heavy + " (their values " + expected + "; chest " + GMTestArmItemRegen('Heavy armor 01') + ", legacy -0.3), with Heft " + heft);
	GMTestArmRestore(added, old);
	theGame.GetInGameConfigWrapper().SetVarValue('GMGameplayOptions', 'GMArmorRegenPenalty', previous);
}

// An item's staminaRegen_armor_mod (mult) from its definition.
function GMTestArmItemRegen(itemName : name) : float
{
	var min, max : SAbilityAttributeValue;

	theGame.GetDefinitionsManager().GetItemAttributeValueNoRandom(itemName, true, 'staminaRegen_armor_mod', min, max);
	return min.valueMultiplicative;
}

// ARM-14: lower-tier school pieces and the Kaer Morhen pieces are set items (by name and owned); a
// generic piece is not; every set's description has legacy's text.
function GMTest_arm14()
{
	var w : W3PlayerWitcher;
	var dm : CDefinitionsManagerAccessor;
	var ids : array<SItemUniqueId>;
	var owned : bool;
	var bonuses : array<EItemSetBonus>;
	var i : int;
	var empty : string;

	w = GetWitcherPlayer();
	dm = theGame.GetDefinitionsManager();
	ids = w.inv.AddAnItem('Lynx Armor', 1);
	owned = w.inv.IsItemSetItem(ids[0]);
	w.inv.RemoveItem(ids[0], 1);
	GMTestReport(dm.IsItemSetItem('Lynx Armor') && dm.IsItemSetItem('Gryphon Boots 1') && dm.IsItemSetItem('Kaer Morhen Gloves 2') && dm.IsItemSetItem('Wolf Armor 4') && owned && !dm.IsItemSetItem('Heavy armor 01'),
		"ARM-14 lower-tier and Kaer Morhen pieces are set items (owned Feline armor " + owned + "), a generic piece is not");
	bonuses.PushBack(EISB_Lynx_1); bonuses.PushBack(EISB_Lynx_2); bonuses.PushBack(EISB_Gryphon_1); bonuses.PushBack(EISB_Gryphon_2);
	bonuses.PushBack(EISB_Bear_1); bonuses.PushBack(EISB_Bear_2); bonuses.PushBack(EISB_Wolf_1); bonuses.PushBack(EISB_Wolf_2);
	bonuses.PushBack(EISB_RedWolf_1); bonuses.PushBack(EISB_RedWolf_2); bonuses.PushBack(EISB_Vampire); bonuses.PushBack(EISB_Viper); bonuses.PushBack(EISB_KaerMorhen);
	for(i = 0; i < bonuses.Size(); i += 1)
		if(w.GetSetBonusTooltipDescription(bonuses[i]) == "" || StrFindFirst(w.GetSetBonusTooltipDescription(bonuses[i]), "$S$") >= 0)
			empty += " " + bonuses[i];
	GMTestReport(empty == "", "ARM-14 every set bonus has a filled-in text" + empty);
}

// The sum of one attribute over abilities (a set's pieces).
function GMTestArmSum(abls : array<name>, attr : name, mult : bool) : float
{
	var i : int;
	var sum : float;

	for(i = 0; i < abls.Size(); i += 1)
		if(mult)
			sum += GMTestArmAblMult(abls[i], attr);
		else
			sum += GMTestArmAbl(abls[i], attr);
	return sum;
}

// ARM-15: 5.x's new armor under Ghost Mode's rules (DA3, DA4): the Netflix set's tags, stats, values and
// texts; Dol Blathanna, White Tiger and Scarlet Crest stats; 5.x's first starting armor upgrade gone
// (ARM-12). No gear needed.
function GMTest_arm15()
{
	var w : W3PlayerWitcher;
	var top, low, scarlet : array<name>;
	var known : array<name>;
	var t1, t2 : string;
	var added : bool;

	w = GetWitcherPlayer();
	top.PushBack('Netflix Armor 2 _Stats'); top.PushBack('Netflix Boots 2 _Stats'); top.PushBack('Netflix Gloves 2 _Stats'); top.PushBack('Netflix Pants 2 _Stats');
	low.PushBack('Netflix Armor _Stats'); low.PushBack('Netflix Boots _Stats'); low.PushBack('Netflix Gloves _Stats'); low.PushBack('Netflix Pants _Stats');
	scarlet.PushBack('Scarlet Crest Armor _Stats'); scarlet.PushBack('Scarlet Crest Boots _Stats'); scarlet.PushBack('Scarlet Crest Gauntlets _Stats'); scarlet.PushBack('Scarlet Crest Trousers _Stats');
	GMTestReport(GMTestArmTag('Netflix Armor', 'NetflixSetMinor') && GMTestArmTag('Netflix Armor', 'SetBonusPiece') && GMTestArmTag('Netflix Gloves 1', 'NetflixSetMinor') && GMTestArmTag('Reinald Netflix steel sword', 'NetflixSetMinor')
		&& !GMTestArmTag('Netflix Armor 2', 'NetflixSetMinor') && GMTestArmTag('Netflix silver sword 2', 'SetBonusPiece') && GMTestArmTag('Netflix Armor', 'NetflixSet') && GMTestArmHasAbility('Netflix Armor', 'Netflix Armor _Stats'),
		"ARM-15 Netflix lower tiers (armor, swords, Reinald's) tagged NetflixSetMinor and SetBonusPiece, the top tier not; abilities kept");
	GMTestReport(w.CheckSetTypeByName('Netflix Pants 1') == EIST_Netflix_Minor && w.CheckSetTypeByName('Netflix Pants 2') == EIST_Netflix && w.ItemSetTypeToItemSetBonus(EIST_Netflix_Minor, 1) == EISB_Netflix_1 && w.ItemSetTypeToItemSetBonus(EIST_Netflix_Minor, 2) == EISB_Undefined,
		"ARM-15 Netflix lower tiers count for the first bonus only");
	GMTestReport(GMTestArmNear(GMTestArmSum(top, 'armor', false), 487) && GMTestArmNear(GMTestArmSum(top, 'slashing_resistance_perc', false), 0.35) && GMTestArmNear(GMTestArmSum(top, 'piercing_resistance_perc', false), 0.20)
		&& GMTestArmNear(GMTestArmSum(top, 'bludgeoning_resistance_perc', false), 0.20) && GMTestArmNear(GMTestArmSum(top, 'rending_resistance_perc', false), 0.35) && GMTestArmNear(GMTestArmSum(top, 'elemental_resistance_perc', false), 0.35)
		&& GMTestArmNear(GMTestArmSum(low, 'armor', false), 267) && GMTestArmNear(GMTestArmSum(low, 'slashing_resistance_perc', false), 0.35),
		"ARM-15 Netflix top tier armor " + GMTestArmSum(top, 'armor', false) + " (487), resistances " + GMTestArmSum(top, 'slashing_resistance_perc', false) + "/" + GMTestArmSum(top, 'piercing_resistance_perc', false) + "/" + GMTestArmSum(top, 'bludgeoning_resistance_perc', false) + "/" + GMTestArmSum(top, 'rending_resistance_perc', false) + "/" + GMTestArmSum(top, 'elemental_resistance_perc', false) + " (35/20/20/35/35); first tier armor " + GMTestArmSum(low, 'armor', false) + " (267), same resistances");
	GMTestReport(GMTestArmNear(GMTestArmAblMult('Netflix Gloves 2 _Stats', 'spell_power_yrden'), 0.12) && GMTestArmNear(GMTestArmAblMult('Netflix Gloves 1 _Stats', 'spell_power_yrden'), 0.10) && GMTestArmNear(GMTestArmAblMult('Netflix Gloves 2 _Stats', 'spell_power_aard'), 0)
		&& GMTestArmNear(GMTestArmAblMult('Netflix Pants _Stats', 'spell_power'), 0.05) && GMTestArmNear(GMTestArmAblMult('Netflix Pants 2 _Stats', 'spell_power'), 0.12) && GMTestArmNear(GMTestArmAbl('Netflix Pants 2 _Stats', 'spell_power'), 0) && GMTestArmNear(GMTestArmAblMult('Netflix Pants 2 _Stats', 'staminaRegen_armor_mod'), 0)
		&& GMTestArmNear(GMTestArmAblMult('Netflix Armor 2 _Stats', 'attack_power'), 0.20) && GMTestArmNear(GMTestArmAbl('Netflix Armor 2 _Stats', 'focus_gain'), 0.20),
		"ARM-15 Netflix pieces: gloves Yrden intensity (not Aard), trousers sign intensity (no regen), chest attack power and adrenaline kept");
	GMTestReport(GMTestArmNear(GMNetflixPotionDurationPerPiece(), 0.07) && GMTestArmNear(GMNetflixYrdenIntensityBonus(), 0.5) && GMTestArmNear(GMNetflixYrdenIntensity(w, w, S_Magic_1), 0), "ARM-15 Netflix values: potions +7% per piece, +0.5 intensity inside Yrden");
	t1 = w.GetSetBonusTooltipDescription(EISB_Netflix_1);
	t2 = w.GetSetBonusTooltipDescription(EISB_Netflix_2);
	GMTestReport(StrBeginsWith(t1, "Increases the duration of potions (not decoctions) by 7% for each piece of the set") && StrBeginsWith(t2, "Against enemies inside your Yrden, every Sign effect except Yrden's own gains 50% Sign Intensity"), "ARM-15 texts: " + t1 + " / " + t2);
	GMTestReport(GMTestArmNear(GMTestArmAbl('Dol Blathanna Armor _Stats', 'slashing_resistance_perc'), 0.14) && GMTestArmNear(GMTestArmAbl('Dol Blathanna Armor _Stats', 'elemental_resistance_perc'), 0.14) && GMTestArmNear(GMTestArmAbl('Dol Blathanna Pants _Stats', 'rending_resistance_perc'), 0.07)
		&& GMTestArmNear(GMTestArmAblMult('Dol Blathanna Armor _Stats', 'spell_power_igni'), 0.10) && GMTestArmNear(GMTestArmAblMult('Dol Blathanna Armor _Stats', 'spell_power_aard'), 0.10) && GMTestArmNear(GMTestArmAblMult('Dol Blathanna Armor _Stats', 'staminaRegen_armor_mod'), 0)
		&& GMTestArmNear(GMTestArmAblMult('Dol Blathanna Gloves _Stats', 'spell_power_igni'), 0.05) && GMTestArmNear(GMTestArmAbl('Dol Blathanna Armor _Stats', 'armor'), 66),
		"ARM-15 Dol Blathanna: medium resistances (chest slashing " + GMTestArmAbl('Dol Blathanna Armor _Stats', 'slashing_resistance_perc') + "), chest Igni and Aard +10% (no regen), gloves +5%, armor kept");
	GMTestReport(GMTestArmNear(GMTestArmAbl('White Tiger Armor _Stats', 'slashing_resistance_perc'), 0.14) && GMTestArmNear(GMTestArmAbl('White Tiger Boots _Stats', 'bludgeoning_resistance_perc'), 0.04) && GMTestArmNear(GMTestArmAbl('White Tiger Armor _Stats', 'vitality'), 75)
		&& GMTestArmNear(GMTestArmAbl('White Tiger Gloves _Stats', 'poison_resistance_perc'), 0.05) && GMTestArmNear(GMTestArmAbl('White Tiger Pants _Stats', 'focus_gain'), 0.05),
		"ARM-15 White Tiger: medium resistances, extras kept (Vitality, poison resistance, adrenaline gain)");
	GMTestReport(GMTestArmNear(GMTestArmSum(scarlet, 'armor', false), 465) && GMTestArmNear(GMTestArmSum(scarlet, 'slashing_resistance_perc', false), 0.40) && GMTestArmNear(GMTestArmSum(scarlet, 'piercing_resistance_perc', false), 0.32)
		&& GMTestArmNear(GMTestArmSum(scarlet, 'bludgeoning_resistance_perc', false), 0.44) && GMTestArmNear(GMTestArmSum(scarlet, 'rending_resistance_perc', false), 0) && GMTestArmNear(GMTestArmSum(scarlet, 'elemental_resistance_perc', false), 0)
		&& GMTestArmNear(GMTestArmSum(scarlet, 'spell_power_quen', true), 0.35) && GMTestArmNear(GMTestArmSum(scarlet, 'focus_gain', false), 0.22),
		"ARM-15 Scarlet Crest: armor " + GMTestArmSum(scarlet, 'armor', false) + " (465), resistances " + GMTestArmSum(scarlet, 'slashing_resistance_perc', false) + "/" + GMTestArmSum(scarlet, 'piercing_resistance_perc', false) + "/" + GMTestArmSum(scarlet, 'bludgeoning_resistance_perc', false) + "/0/0, Quen " + GMTestArmSum(scarlet, 'spell_power_quen', true) + ", adrenaline gain " + GMTestArmSum(scarlet, 'focus_gain', false));
	added = w.AddCraftingSchematic('Starting Armor Upgrade schematic 1', true, true);
	known = w.GetCraftingSchematicsNames();
	GMTestReport(!added && !known.Contains('Starting Armor Upgrade schematic 1') && known.Contains('Kaer Morhen Armor schematic'), "ARM-12 5.x's Starting Armor Upgrade schematic 1 not known and not taught (" + added + "); the Kaer Morhen one known");
}

// ARM-15 with gear: wears three pieces of the Netflix set's first tier (0: two armor pieces and
// Reinald's sword) or second tier (1), or the six top-tier pieces (2; setlevel(41) first), until
// gmtest_arm_restore().
exec function gmtest_arm15_wear(tier : int)
{
	var w : W3PlayerWitcher;
	var old, added : array<SItemUniqueId>;
	var names : array<name>;
	var id : SItemUniqueId;

	w = GetWitcherPlayer();
	old = GMTestArmWorn();
	if(w.GetItemEquippedOnSlot(EES_SteelSword, id)) old.PushBack(id);
	if(w.GetItemEquippedOnSlot(EES_SilverSword, id)) old.PushBack(id);
	if(tier == 2)
	{
		names.PushBack('Netflix Armor 2'); names.PushBack('Netflix Gloves 2'); names.PushBack('Netflix Pants 2'); names.PushBack('Netflix Boots 2');
		names.PushBack('Netflix steel sword 2'); names.PushBack('Netflix silver sword 2');
	}
	else if(tier == 1)
	{
		names.PushBack('Netflix Armor 1'); names.PushBack('Netflix Gloves 1'); names.PushBack('Netflix Pants 1');
	}
	else
	{
		names.PushBack('Netflix Armor'); names.PushBack('Netflix Gloves'); names.PushBack('Reinald Netflix steel sword');
	}
	GMTestArmWear(names, added);
	w.GMTestArmKeep(added, old);
	w.GainStat(BCS_Stamina, w.GetStatMax(BCS_Stamina));
	LogChannel('GMTest', "INFO ARM-15 worn: Netflix pieces " + w.GetSetPartsEquipped(EIST_Netflix) + " (top tier " + w.GMGetSetPartsEquippedRaw(EIST_Netflix) + "), tier 1 " + w.IsSetBonusActive(EISB_Netflix_1) + ", tier 2 " + w.IsSetBonusActive(EISB_Netflix_2));
}

@addField(W3PlayerWitcher)
public var gmTestArmPotion : float;
@addField(W3PlayerWitcher)
public var gmTestArmDecoction : float;

@addMethod(W3PlayerWitcher)
function GMTestArmKeepPotion(p : float, d : float)
{
	gmTestArmPotion = p;
	gmTestArmDecoction = d;
}

// ARM-15 potion duration: without Netflix pieces worn, stores Swallow's and a decoction's (Mutagen 1)
// durations; with pieces worn, compares: potions +7% per piece of every tier, decoctions unchanged.
exec function gmtest_arm15_potion()
{
	var w : W3PlayerWitcher;
	var p, d : float;
	var n : int;

	w = GetWitcherPlayer();
	p = w.CalculatePotionDuration(GetInvalidUniqueId(), false, 'Swallow 1');
	d = w.CalculatePotionDuration(GetInvalidUniqueId(), true, 'Mutagen 1');
	n = w.GetSetPartsEquipped(EIST_Netflix);
	if(n == 0)
	{
		w.GMTestArmKeepPotion(p, d);
		LogChannel('GMTest', "INFO ARM-15 no Netflix pieces: Swallow " + p + " s, decoction " + d + " s (stored)");
	}
	else
	{
		GMTestReport(w.IsSetBonusActive(EISB_Netflix_1) && GMTestArmNear(p / w.gmTestArmPotion, 1 + 0.07 * n) && GMTestArmNear(d, w.gmTestArmDecoction),
			"ARM-15 " + n + " Netflix pieces: Swallow " + p + " s against " + w.gmTestArmPotion + " (x" + (p / w.gmTestArmPotion) + ", expected x" + (1 + 0.07 * n) + "), decoction " + d + " s against " + w.gmTestArmDecoction + " (unchanged)");
	}
}

// ARM-15 intensity inside Yrden (six top-tier pieces worn, a test dummy in front, after a Yrden cast or
// without one): the bonus each sign gets against the dummy.
exec function gmtest_arm15_yrden()
{
	var w : W3PlayerWitcher;
	var npc : CNewNPC;

	w = GetWitcherPlayer();
	npc = GMTestDummy();
	LogChannel('GMTest', "INFO ARM-15 tier 2 " + w.IsSetBonusActive(EISB_Netflix_2) + ", Yrden traps " + w.yrdenEntities.Size() + ", dummy inside " + w.GMIsInsideOwnYrden(npc)
		+ ": Aard +" + GMNetflixYrdenIntensity(w, npc, S_Magic_1) + ", Igni +" + GMNetflixYrdenIntensity(w, npc, S_Magic_2) + ", Axii +" + GMNetflixYrdenIntensity(w, npc, S_Magic_5)
		+ ", Quen +" + GMNetflixYrdenIntensity(w, npc, S_Magic_4) + ", Yrden +" + GMNetflixYrdenIntensity(w, npc, S_Magic_3) + ", alternate Yrden +" + GMNetflixYrdenIntensity(w, npc, S_Magic_s03));
}

// ARM-15 after a real cast at the dummy (damage probe on): the hit's damage types and power, and the
// dummy's effects with the power they carry; then clears the probe.
exec function gmtest_arm15_hit()
{
	var w : W3PlayerWitcher;
	var npc : CNewNPC;
	var i : int;
	var steps, buffs : string;
	var effects : array<CBaseGameplayEffect>;
	var sp : SAbilityAttributeValue;

	w = GetWitcherPlayer();
	npc = GMTestDummy();
	for(i = 0; i < w.gmTestDmgSteps.Size(); i += 1)
		steps += " " + w.gmTestDmgSteps[i].dmgType + " raw " + NoTrailZeros(w.gmTestDmgSteps[i].rawIn) + " power x" + NoTrailZeros(w.gmTestDmgSteps[i].mult) + ";";
	effects = npc.GetBuffs();
	for(i = 0; i < effects.Size(); i += 1)
	{
		sp = effects[i].GetCreatorPowerStat();
		buffs += " " + effects[i].GetEffectType() + " power x" + NoTrailZeros(sp.valueMultiplicative) + ";";
	}
	LogChannel('GMTest', "INFO ARM-15 hit (dummy inside Yrden " + w.GMIsInsideOwnYrden(npc) + "):" + steps + " effects:" + buffs);
	w.GMTestDmgReset();
}

// ARM-12 save impact: Geralt is taught 5.x's first starting armor upgrade schematic (past the
// wrapper, as a save made before the change) and saves into a new manual slot.
exec function gmtest_arm12_schem_mksave()
{
	var known : array<name>;

	GetWitcherPlayer().GMTestTeachSchematic('Starting Armor Upgrade schematic 1');
	known = GetWitcherPlayer().GetCraftingSchematicsNames();
	LogChannel('GMTest', "INFO ARM-12 knows Starting Armor Upgrade schematic 1: " + known.Contains('Starting Armor Upgrade schematic 1') + "; saving into a new manual slot");
	theGame.SaveGame(SGT_Manual, -1);
}

@addMethod(W3PlayerWitcher)
function GMTestTeachSchematic(nam : name)
{
	craftingSchematics.PushBack(nam);
}

// ARM-12 after loading that save: the schematic is gone, the Kaer Morhen one known.
exec function gmtest_arm12_schem_oldsave()
{
	var known : array<name>;

	known = GetWitcherPlayer().GetCraftingSchematicsNames();
	GMTestReport(!known.Contains('Starting Armor Upgrade schematic 1') && known.Contains('Kaer Morhen Armor schematic'), "ARM-12 save that knew Starting Armor Upgrade schematic 1: removed at load, Kaer Morhen Armor schematic known");
}

// ARM-15 save impact (after loading a save made before ARM-15 holding Netflix Armor, Gloves 1, Pants
// and Boots 2 in the bag, and setlevel(41)): worn, they read the new stats and count for the set.
exec function gmtest_arm15_oldsave()
{
	var w : W3PlayerWitcher;
	var inv : CInventoryComponent;
	var names : array<name>;
	var ids, added : array<SItemUniqueId>;
	var i : int;
	var pts, perc : float;
	var known : array<name>;

	w = GetWitcherPlayer();
	inv = w.GetInventory();
	known = w.GetCraftingSchematicsNames();
	names.PushBack('Netflix Armor'); names.PushBack('Netflix Gloves 1'); names.PushBack('Netflix Pants'); names.PushBack('Netflix Boots 2');
	for(i = 0; i < names.Size(); i += 1)
	{
		ids = inv.GetItemsByName(names[i]);
		if(ids.Size() > 0)
		{
			w.EquipItem(ids[0]);
			added.PushBack(ids[0]);
		}
	}
	GMTestReport(added.Size() == 4 && w.GetSetPartsEquipped(EIST_Netflix) == 4 && w.GMGetSetPartsEquippedRaw(EIST_Netflix_Minor) == 3 && w.IsSetBonusActive(EISB_Netflix_1) && inv.ItemHasTag(added[0], 'NetflixSetMinor')
		&& GMTestArmNear(GMTestArmItemValue(inv, added[0], 'armor'), 130) && GMTestArmNear(GMTestArmItemValue(inv, added[0], 'bludgeoning_resistance_perc'), 0.09),
		"ARM-15 Netflix pieces owned before ARM-15 (" + added.Size() + "): " + w.GetSetPartsEquipped(EIST_Netflix) + " count, tier 1 " + w.IsSetBonusActive(EISB_Netflix_1) + ", chest armor " + GMTestArmItemValue(inv, added[0], 'armor') + " (130), bludgeoning " + GMTestArmItemValue(inv, added[0], 'bludgeoning_resistance_perc') + " (0.09)");
	GMTestReport(!known.Contains('Starting Armor Upgrade schematic 1') && known.Contains('Kaer Morhen Armor schematic'), "ARM-12 on that save: Starting Armor Upgrade schematic 1 removed at load, Kaer Morhen Armor schematic known");
}

// ARM-01 (fix3, sweep C gap 5a): the hairstyles whose inquisitor and bowl variants legacy took Yoana's reward armor out
// of (`q108 Medium armor 10`, so Geralt keeps his default hair with it) are given whole: they still read as hair items
// with their tags and look. Their variant lists cannot be read by script (`gen_arm_items.py --verify` compares them
// with legacy's); the look on screen is an open check.
function GMTest_arm01_hair()
{
	var dm : CDefinitionsManagerAccessor;
	var hairs : array<name>;
	var i : int;
	var ok : bool;
	var text : string;

	dm = theGame.GetDefinitionsManager();
	hairs.PushBack('Preview Hair');
	hairs.PushBack('Half With Tail Hairstyle');
	hairs.PushBack('Long Loose Hairstyle');
	hairs.PushBack('Fancy Bowl');
	ok = true;
	for(i = 0; i < hairs.Size(); i += 1)
	{
		if(dm.GetItemCategory(hairs[i]) != 'hair' || !dm.ItemHasTag(hairs[i], 'Body') || !dm.ItemHasTag(hairs[i], 'NoShow'))
			ok = false;
		text += ", " + hairs[i] + " " + dm.GetItemCategory(hairs[i]) + " " + dm.ItemHasTag(hairs[i], 'Body') + " " + dm.ItemHasTag(hairs[i], 'NoShow');
	}
	GMTestReport(ok, "ARM-01 the hairstyles given whole without Yoana's armor in their variants read as hair items (category, Body and NoShow tags; Long Loose Hairstyle has no look of its own, in 5.x too)" + text);
}
