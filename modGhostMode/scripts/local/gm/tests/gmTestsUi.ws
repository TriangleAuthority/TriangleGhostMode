// UI tests (docs/features/ui.md). Tooltips are built as the inventory builds them (needs the HUD).
// GMTest_uiport() runs the situation-free checks (in gmtest_regress()); the panel checks GMTest_ui01_crit,
// GMTest_ui02 to GMTest_ui05 run in gmtest_panel() (a menu open).
//
// Manual UI checks (a situation set up by hand; run in both trees, see each function's comment):
//   UI-01  gmtest_ui01_hits(silver), gmtest_ui01_terms(mode): the panel's list against scripted hits
//   UI-01  gmtest_ui01_crit(): the crit chance against the hit's, also after gmtest_ui01_draw(silver)
//   UI-03  gmtest_ui03_skills(): the sign lines with the sign skills (a menu open)
//   UI-03  gmtest_ui03_cast(sign), gmtest_ui03_casts(sign) per sign: the sign lines against real Quen, Yrden, Axii casts
//   UI-04  gmtest_ui04_live(): the toxicity decay against the effect
//   UI-05  gmtest_ui05_skills(): the other lines with skills
//   UI-10  gmtest_ui10_kill_a/b/c(): a wolf killed through the death path counts
//   UI-12  gmtest_ui12_a(), gmtest_ui12_b(): an enemy 40 levels up shows its level in red
//   UI-15  gmtest_ui15_a/b/c(): the razor shaves Geralt

exec function gmtest_uiport()
{
	thePlayer.GMTestCount(true, true);
	GMTest_uiport();
	LogChannel('GMTest', "SUMMARY uiport: " + thePlayer.gmTestPassed + " passed, " + thePlayer.gmTestFailed + " failed");
}

function GMTest_uiport()
{
	GMTest_ui01();
	GMTest_ui06();
	GMTest_ui08();
	GMTest_ui10();
	GMTest_ui11();
	GMTest_ui13();
	GMTest_ui15();
}

function GMTestUiTooltip() : W3TooltipComponent
{
	var w : W3PlayerWitcher;
	var tc : W3TooltipComponent;

	w = GetWitcherPlayer();
	tc = new W3TooltipComponent in w;
	tc.initialize(w.inv, theGame.GetHud().GetHudFlashValueStorage());
	tc.setCurrentInventory(w.inv);
	return tc;
}

// The text of a stats list's row with the id, "" if none.
function GMTestUiRow(list : CScriptedFlashArray, id : string) : string
{
	var i : int;
	var line : CScriptedFlashObject;

	for(i = 0; i < list.GetLength(); i += 1)
	{
		line = list.GetElementFlashObject(i);
		if(line.GetMemberFlashString("id") == id)
			return line.GetMemberFlashString("value");
	}
	return "";
}

function GMTestUiStat(attr : name, attrName : string, value : float, pct : bool, primary : bool) : SAttributeTooltip
{
	var s : SAttributeTooltip;

	s.originName = attr;
	s.attributeName = attrName;
	s.value = value;
	s.percentageValue = pct;
	s.primaryStat = primary;
	s.attributeColor = "BAADA0";
	return s;
}

exec function gmtest_ui06()
{
	thePlayer.GMTestCount(true, true);
	GMTest_ui06();
	LogChannel('GMTest', "SUMMARY ui06: " + thePlayer.gmTestPassed + " passed, " + thePlayer.gmTestFailed + " failed");
}

// UI-06, UI-07: names, descriptions, oil tooltips, toxicity lines, negative values and comparisons.
function GMTest_ui06()
{
	var w : W3PlayerWitcher;
	var tc : W3TooltipComponent;
	var data, row : CScriptedFlashObject;
	var list, comp : CScriptedFlashArray;
	var ids, swords : array<SItemUniqueId>;
	var a, b : array<SAttributeTooltip>;
	var desc, s, tox : string;
	var i : int;
	var ok : bool;

	w = GetWitcherPlayer();
	// UI-07: the attribute names (legacy's strings win over 5.x's keys).
	GMTestReport(GetLocStringByKeyExt("attribute_name_frost_resistance_perc") == GetLocStringById(2110992013) && GetLocStringById(2110992013) != "", "UI-07 frost resistance name: " + GetLocStringByKeyExt("attribute_name_frost_resistance_perc"));
	GMTestReport(GetLocStringByKeyExt("attribute_name_desc_knockdownchance_mult") == GetLocStringById(2110992110), "UI-07 knockdown chance name");
	GMTestReport(GetLocStringByKeyExt("attribute_name_vitalityRegen") == GetLocStringById(2110992156), "UI-07 Vitality regen name: " + GetLocStringByKeyExt("attribute_name_vitalityRegen"));
	GMTestReport(GetLocStringByKeyExt("attribute_name_vitalityCombatRegen") == GetLocStringById(2110992157), "UI-07 combat Vitality regen name");
	GMTestReport(GetLocStringByKeyExt("attribute_name_q108_bounce_arrows") == GetLocStringById(2110992265), "UI-07 arrow bounce name");
	GMTestReport(GetLocStringByKeyExt("item_category_light_armor_description") == GetLocStringById(2110992426), "UI-06 the light armor class text: " + GetLocStringByKeyExt("item_category_light_armor_description"));

	tc = GMTestUiTooltip();
	// UI-06: an armor piece shows its description (5.x: none).
	ids = w.inv.AddAnItem('Light armor 01', 1);
	data = tc.GetBaseItemData(ids[0], w.inv);
	desc = data.GetMemberFlashString("Description");
	w.inv.RemoveItem(ids[0], 1);
	GMTestReport(StrFindFirst(desc, GetLocStringById(2110992426)) >= 0, "UI-06 Light armor 01's tooltip shows the class text: '" + desc + "'");
	// A weapon too.
	ids = w.inv.AddAnItem('Guard Lvl1 steel sword 1', 1);
	data = tc.GetBaseItemData(ids[0], w.inv);
	desc = data.GetMemberFlashString("Description");
	s = GetLocStringByKeyExt(w.inv.GetItemLocalizedDescriptionByUniqueID(ids[0]));
	w.inv.RemoveItem(ids[0], 1);
	GMTestReport(s == "" || StrFindFirst(desc, s) >= 0, "UI-06 a steel sword's tooltip shows its description: '" + desc + "'");

	// UI-06: an oil's tooltip lists every bonus as a percentage (legacy's AddOilStats).
	ids = w.inv.AddAnItem('Beast Oil 3', 1);
	data = tc.GetBaseItemData(ids[0], w.inv);
	list = data.GetMemberFlashArray("StatsList");
	s = "";
	ok = list.GetLength() >= 3;
	for(i = 0; i < list.GetLength(); i += 1)
	{
		row = list.GetElementFlashObject(i);
		s += row.GetMemberFlashString("name") + " " + row.GetMemberFlashString("value") + "; ";
		ok = ok && StrFindFirst(row.GetMemberFlashString("value"), "%") >= 0 && !StrBeginsWith(row.GetMemberFlashString("value"), "+");
	}
	GMTestReport(ok, "UI-06 Beast Oil 3's tooltip lists every bonus: " + s + " charges " + data.GetMemberFlashString("charges"));
	// A sword's oil line: the oil's name and charges.
	swords = w.inv.AddAnItem('Guard Lvl1 steel sword 1', 1);
	w.ApplyOil(ids[0], swords[0]);
	data = tc.GetBaseItemData(swords[0], w.inv);
	s = data.GetMemberFlashString("appliedOilInfo1");
	w.inv.RemoveAllOilsFromItem(swords[0]);
	w.inv.RemoveItem(swords[0], 1);
	w.inv.RemoveItem(ids[0], w.inv.GetItemQuantity(ids[0]));
	GMTestReport(StrFindFirst(s, GetLocStringByKeyExt(w.inv.GetItemLocalizedNameByName('Beast Oil 3'))) == 0 && StrFindFirst(s, "/") > 0 && StrFindFirst(s, "%") < 0, "UI-06 the oiled sword's line: '" + s + "'");

	// UI-06: a potion's toxicity without "/max".
	ids = w.inv.AddAnItem('Thunderbolt 1', 1);
	data = tc.GetBaseItemData(ids[0], w.inv);
	tox = GMTestUiRow(data.GetMemberFlashArray("StatsList"), "toxicity");
	w.inv.RemoveItem(ids[0], 1);
	GMTestReport(tox != "" && StrFindFirst(tox, "/") < 0, "UI-06 Thunderbolt 1's toxicity line without /max: '" + tox + "'");

	// UI-06: negative values and comparisons (CalculateStatsComparance with the item tooltip's "+").
	a.PushBack(GMTestUiStat('ui_test_neg', "Negative", -0.1, true, false));
	b.PushBack(GMTestUiStat('ui_test_neg2', "Negative two", -0.2, true, false));
	comp = data.CreateFlashArray();
	CalculateStatsComparance(a, b, data, comp, true, false);
	row = comp.GetElementFlashObject(0);
	s = row.GetMemberFlashString("icon") + " '" + row.GetMemberFlashString("value") + "' '" + row.GetMemberFlashString("diffValue") + "'";
	GMTestReport(comp.GetLength() == 2 && row.GetMemberFlashString("icon") == "worse" && row.GetMemberFlashString("value") == "-10 %" && StrFindFirst(row.GetMemberFlashString("diffValue"), "-10") >= 0, "UI-06 a new negative modifier is worse, no '+': " + s);
	row = comp.GetElementFlashObject(1);
	s = row.GetMemberFlashString("icon") + " '" + row.GetMemberFlashString("diffValue") + "'";
	GMTestReport(row.GetMemberFlashString("icon") == "better" && StrFindFirst(row.GetMemberFlashString("diffValue"), "+20") >= 0, "UI-06 losing a negative modifier is better: " + s);
	delete tc;
}

// UI-06 with skills (equip first: skilleq(S_Alchemy_s03, 0, 3), skilleq(S_Alchemy_s14, 0, 3), and Fixative
// skilleq(S_Alchemy_s06, 0, 3) or the new tree's skilleq(S_Alchemy_s25, 0, 3)): Expert Brewer's toxicity,
// Adaptation's offset, the oil's charges with Fixative.
exec function gmtest_ui06_skills()
{
	var w : W3PlayerWitcher;
	var tc : W3TooltipComponent;
	var data : CScriptedFlashObject;
	var ids : array<SItemUniqueId>;
	var tox, charges : string;
	var base, cut : float;
	var tips : array<SAttributeTooltip>;
	var fixative : ESkill;

	thePlayer.GMTestCount(true, true);
	w = GetWitcherPlayer();
	tc = GMTestUiTooltip();
	ids = w.inv.AddAnItem('Thunderbolt 1', 1);
	w.inv.GetItemBaseStats(ids[0], tips);
	base = GMTestAlchTipValue(tips, 'toxicity');
	cut = MaxF(0, base - CalculateAttributeValue(w.GetSkillAttributeValue(S_Alchemy_s03, 'toxicityReduction', false, false)) * w.GetSkillLevel(S_Alchemy_s03));
	data = tc.GetBaseItemData(ids[0], w.inv);
	tox = GMTestUiRow(data.GetMemberFlashArray("StatsList"), "toxicity");
	w.inv.RemoveItem(ids[0], 1);
	GMTestReport(w.CanUseSkill(S_Alchemy_s03) && cut < base && tox == NoTrailZeros(RoundMath(cut)), "UI-06 Expert Brewer " + w.GetSkillLevel(S_Alchemy_s03) + ": Thunderbolt 1's toxicity " + NoTrailZeros(base) + " shown as '" + tox + "'");

	ids = w.inv.AddAnItem('Mutagen 24', 1);
	tips.Clear();
	w.inv.GetItemBaseStats(ids[0], tips);
	base = GMTestAlchTipValue(tips, 'toxicity_offset');
	data = tc.GetBaseItemData(ids[0], w.inv);
	tox = GMTestUiRow(data.GetMemberFlashArray("StatsList"), "toxicity_offset");
	w.inv.RemoveItem(ids[0], 1);
	GMTestReport(w.CanUseSkill(S_Alchemy_s14) && tox == NoTrailZeros(RoundMath(base * w.GMAdaptationMult())), "UI-06 Adaptation " + w.GetSkillLevel(S_Alchemy_s14) + ": the decoction's offset " + NoTrailZeros(base) + " shown as '" + tox + "'");

	fixative = thePlayer.GMFixativeSkill();
	ids = w.inv.AddAnItem('Beast Oil 3', 1);
	data = tc.GetBaseItemData(ids[0], w.inv);
	charges = data.GetMemberFlashString("charges");
	w.inv.RemoveItem(ids[0], w.inv.GetItemQuantity(ids[0]));
	GMTestReport(fixative != S_SUndefined && StrFindFirst(charges, "( +") >= 0, "UI-06 Fixative " + SkillEnumToName(fixative) + ": the oil's charges '" + charges + "'");
	GMTestReport(thePlayer.GMFixativeNoWear() == (thePlayer.GetSkillLevel(fixative) >= 3), "UI-06 the HUD's infinite oil follows " + SkillEnumToName(fixative) + " level " + thePlayer.GetSkillLevel(fixative));
	delete tc;
	LogChannel('GMTest', "SUMMARY ui06_skills: " + thePlayer.gmTestPassed + " passed, " + thePlayer.gmTestFailed + " failed");
}

exec function gmtest_ui08()
{
	thePlayer.GMTestCount(true, true);
	GMTest_ui08();
	LogChannel('GMTest', "SUMMARY ui08: " + thePlayer.gmTestPassed + " passed, " + thePlayer.gmTestFailed + " failed");
}

// UI-08: recipe and schematic tooltips, the extended texts, the crafting menu's line.
function GMTest_ui08()
{
	var w : W3PlayerWitcher;
	var tc : W3TooltipComponent;
	var comp : W3GuiPlayerInventoryComponent;
	var data : CScriptedFlashObject;
	var ids : array<SItemUniqueId>;
	var rec : SAlchemyRecipe;
	var desc, stats, book : string;

	w = GetWitcherPlayer();
	tc = GMTestUiTooltip();
	rec = tc.GetRecipeDataFromXML('Recipe for Blizzard 1');
	GMTestReport(rec.cookedItemName == 'Blizzard 1', "UI-08 GetRecipeDataFromXML finds the recipe: '" + NameToString(rec.cookedItemName) + "'");

	ids = w.inv.AddAnItem('Recipe for Blizzard 1', 1);
	data = tc.GetBaseItemData(ids[0], w.inv);
	desc = data.GetMemberFlashString("Description");
	stats = GMTestAlchFlashListText(data.GetMemberFlashArray("StatsList"));
	w.inv.RemoveItem(ids[0], 1);
	GMTestReport(StrFindFirst(desc, " / ") > 0 && StrFindFirst(desc, "#FF0000") > 0 && StrLen(stats) > 0, "UI-08 the Blizzard recipe's tooltip: '" + desc + "' | " + stats);

	comp = new W3GuiPlayerInventoryComponent in thePlayer;
	comp.Initialize(thePlayer.inv);
	ids = w.inv.AddAnItem('Recipe for Blizzard 1', 1);
	book = comp.GetAlchemyBookText(ids[0]);
	w.inv.RemoveItem(ids[0], 1);
	GMTestReport(StrFindFirst(book, " / ") > 0 && StrFindFirst(book, GetLocStringByKeyExt("attribute_name_weight")) < 0 && StrFindFirst(book, GetLocStringByKeyExt("panel_crafting_book_start")) < 0, "UI-08 the Blizzard recipe's book text: '" + book + "'");

	ids = w.inv.AddAnItem('Recipe for Mutagen 20', 1);
	data = tc.GetBaseItemData(ids[0], w.inv);
	desc = data.GetMemberFlashString("Description");
	book = comp.GetAlchemyBookText(ids[0]);
	w.inv.RemoveItem(ids[0], 1);
	GMTestReport(StrFindFirst(desc, "$") < 0 && StrFindFirst(desc, " / ") > 0 && StrFindFirst(book, "$") < 0, "UI-08 a decoction recipe's tooltip with its values: '" + StrLeft(desc, 200) + "'");

	ids = w.inv.AddAnItem('Short sword 1 schematic', 1);
	data = tc.GetBaseItemData(ids[0], w.inv);
	desc = data.GetMemberFlashString("Description");
	book = comp.GetSchematicBookText(ids[0]);
	w.inv.RemoveItem(ids[0], 1);
	GMTestReport(StrFindFirst(desc, " / ") > 0, "UI-08 the schematic's tooltip lists have / need: '" + desc + "'");
	GMTestReport(StrFindFirst(book, " / ") > 0 && StrFindFirst(book, GetLocStringByKeyExt("panel_crafting_number_random_attributes")) < 0 && StrFindFirst(book, GetLocStringByKeyExt("attribute_name_weight")) < 0, "UI-08 the schematic's book text: '" + book + "'");

	comp.GetCraftedItemInfo('Short sword 1', data);
	GMTestReport(data.GetMemberFlashString("additionalDescription") == "", "UI-08 the crafting menu has no random attributes line");
	delete comp;
	delete tc;
}

// UI-01: the offense list. Situation-free (in the regression): 5.x's struct carries Ghost Mode's
// list, the expected hit is the crit-weighted average, and Life Leech's drain reads the list's average
// attack power (MUT-12).
exec function gmtest_ui01()
{
	thePlayer.GMTestCount(true, true);
	GMTest_ui01();
	LogChannel('GMTest', "SUMMARY ui01: " + thePlayer.gmTestPassed + " passed, " + thePlayer.gmTestFailed + " failed");
}

function GMTestUiNear(a : float, b : float) : bool
{
	return AbsF(a - b) < 0.01;
}

function GMTest_ui01()
{
	var w : W3PlayerWitcher;
	var gm : SGMOffenseStats;
	var st : SPlayerOffenseStats;
	var focus, expected, avAP, swordDmg, avSI : float;
	var abl : SAbilityAttributeValue;
	var sword : SItemUniqueId;

	w = GetWitcherPlayer();
	focus = w.GetStat(BCS_Focus);
	w.ForceSetStat(BCS_Focus, 0);
	gm = w.GMGetOffenseStats();
	st = w.GetOffenseStatsList();
	GMTestReport(gm.steelFastDmg > 0 && gm.silverFastDmg > 0 && st.steelFastDmg == gm.steelFastDmg && st.steelStrongCritDmg == gm.steelStrongCritDmg && st.silverFastCritChance == gm.silverFastCritChance
		&& st.silverStrongDPS == gm.silverStrongDPS && st.steelFastDPS == gm.steelFastDPS && st.crossbowSteelDmg == gm.crossbowSteelDmg && st.crossbowCritChance == gm.crossbowCritChance,
		"UI-01 GetOffenseStatsList carries Ghost Mode's list: steel fast " + NoTrailZeros(st.steelFastDmg) + " (crit " + NoTrailZeros(st.steelFastCritDmg) + ", " + NoTrailZeros(st.steelFastCritChance) + " %), strong " + NoTrailZeros(st.steelStrongDmg)
		+ ", silver fast " + NoTrailZeros(st.silverFastDmg) + ", strong " + NoTrailZeros(st.silverStrongDmg) + ", crossbow " + NoTrailZeros(st.crossbowSteelDmg));
	expected = gm.steelFastDmg * (1 - ClampF(gm.steelFastCritChance / 100, 0, 1)) + gm.steelFastCritDmg * ClampF(gm.steelFastCritChance / 100, 0, 1);
	GMTestReport(GMTestUiNear(gm.steelFastDPS, expected), "UI-01 the expected hit is the crit-weighted average: " + NoTrailZeros(gm.steelFastDPS) + " (expected " + NoTrailZeros(expected) + ")");
	GMTestReport(gm.steelStrongDmg > gm.steelFastDmg && gm.steelFastCritDmg > gm.steelFastDmg && gm.steelFastAP > 0 && gm.steelFastCritAP > gm.steelFastAP,
		"UI-01 strong > fast (" + NoTrailZeros(gm.steelStrongDmg) + " > " + NoTrailZeros(gm.steelFastDmg) + "), crit > normal; attack power " + NoTrailZeros(gm.steelFastAP) + ", crit power " + NoTrailZeros(gm.steelFastCritAP));

	// MUT-12: the drain's average attack power is the list's (legacy)
	abl  = w.GetTotalSignSpellPower(S_Magic_1);
	abl += w.GetTotalSignSpellPower(S_Magic_2);
	abl += w.GetTotalSignSpellPower(S_Magic_3);
	abl += w.GetTotalSignSpellPower(S_Magic_4);
	abl += w.GetTotalSignSpellPower(S_Magic_5);
	avSI = MaxF(0.0, abl.valueMultiplicative / 5.0 - 1.0) * 100;
	avAP = MaxF(0, (gm.steelFastAP * (1 - gm.steelFastCritChance/100) + gm.steelFastCritAP * gm.steelFastCritChance/100
		+ gm.silverFastAP * (1 - gm.silverFastCritChance/100) + gm.silverFastCritAP * gm.silverFastCritChance/100
		+ gm.steelStrongAP * (1 - gm.steelStrongCritChance/100) + gm.steelStrongCritAP * gm.steelStrongCritChance/100
		+ gm.silverStrongAP * (1 - gm.silverStrongCritChance/100) + gm.silverStrongCritAP * gm.silverStrongCritChance/100) / 4) * 100;
	sword = w.inv.GetCurrentlyHeldSword();
	if(!w.inv.IsIdValid(sword))
		w.GetItemEquippedOnSlot(EES_SteelSword, sword);
	if(w.inv.GetItemCategory(sword) == 'silversword')
		swordDmg = w.GetTotalWeaponDamage(sword, theGame.params.DAMAGE_NAME_SILVER, GetInvalidUniqueId());
	else
		swordDmg = w.GetTotalWeaponDamage(sword, theGame.params.DAMAGE_NAME_SLASHING, GetInvalidUniqueId());
	GMTestReport(avAP > 0 && GMTestUiNear(w.GMMutation11GetBaseStrength(), swordDmg + avAP + avSI), "MUT-12 the drain's base strength " + NoTrailZeros(w.GMMutation11GetBaseStrength()) + " = sword " + NoTrailZeros(swordDmg) + " + the list's average attack power " + NoTrailZeros(avAP) + " % + sign intensity " + NoTrailZeros(avSI) + " %");
	w.ForceSetStat(BCS_Focus, focus);
}

// One scripted hit of Geralt's with the sword in the slot (the probe records it): the attack power the
// formula used; dealt gets the damage dealt.
function GMTestUi01Hit(npc : CActor, silver : bool, attackName : name, crit : bool, out dealt : float, out wasCrit : bool) : float
{
	var w : W3PlayerWitcher;
	var action : W3Action_Attack;
	var step : SGMTestDmgStep;
	var id : SItemUniqueId;

	w = GetWitcherPlayer();
	if(silver)
		w.GetItemEquippedOnSlot(EES_SilverSword, id);
	else
		w.GetItemEquippedOnSlot(EES_SteelSword, id);
	w.GMTestDmgReset();
	action = new W3Action_Attack in theGame.damageMgr;
	action.Init(w, npc, NULL, id, attackName, w.GetName(), EHRT_Light, false, false, attackName, AST_Jab, ASD_UpDown, true, false, false, false);
	if(crit)
		action.SetCriticalHit();
	action.SetSuppressHitSounds(true);
	action.SetHitAnimationPlayType(EAHA_ForceNo);
	theGame.damageMgr.ProcessAction(action);
	step = GMTestDmgStep0();
	dealt = w.gmTestDmgFinal;
	wasCrit = action.IsCriticalHit();
	delete action;
	npc.ForceSetStat(BCS_Vitality, npc.GetStatMax(BCS_Vitality));
	return step.mult;
}

// Scripted hits come within one swing's time: forget Strength Training's last swing, so the next
// strong hit is a new swing (a real one comes later anyway).
@addMethod(W3PlayerWitcher)
function GMTestNewSwing()
{
	gmSTUsedAt = 0;
}

// One attack type's check: the list read just before a scripted hit against the neutral dummy: the
// attack power equals the formula's exactly, the damage dealt is the list's within the hit's random
// 0.9 to 1.1.
function GMTestUi01Compare(npc : CActor, silver : bool, heavy : bool, crit : bool)
{
	var w : W3PlayerWitcher;
	var gm : SGMOffenseStats;
	var ap, dmg, mult, dealt, critAP, critDmg : float;
	var label : string;
	var attackName : name;
	var wasCrit : bool;

	w = GetWitcherPlayer();
	w.ForceSetStat(BCS_Focus, 0);
	w.GMTestNewSwing();
	gm = w.GMGetOffenseStats();
	if(silver)
	{
		label = "silver";
		if(heavy)	{ ap = gm.silverStrongAP; dmg = gm.silverStrongDmg; critAP = gm.silverStrongCritAP; critDmg = gm.silverStrongCritDmg; }
		else		{ ap = gm.silverFastAP; dmg = gm.silverFastDmg; critAP = gm.silverFastCritAP; critDmg = gm.silverFastCritDmg; }
	}
	else
	{
		label = "steel";
		if(heavy)	{ ap = gm.steelStrongAP; dmg = gm.steelStrongDmg; critAP = gm.steelStrongCritAP; critDmg = gm.steelStrongCritDmg; }
		else		{ ap = gm.steelFastAP; dmg = gm.steelFastDmg; critAP = gm.steelFastCritAP; critDmg = gm.steelFastCritDmg; }
	}
	if(heavy)
	{
		attackName = 'attack_heavy';
		label += " strong";
	}
	else
	{
		attackName = 'attack_light';
		label += " fast";
	}
	mult = GMTestUi01Hit(npc, silver, attackName, crit, dealt, wasCrit);
	if(wasCrit)	// forced, or rolled by the hit (the list's crit chance)
	{
		label += " crit";
		ap = critAP;
		dmg = critDmg;
	}
	GMTestReport(GMTestUiNear(mult, ap) && dealt >= 0.89 * dmg && dealt <= 1.11 * dmg, "UI-01 " + label + ": the list's attack power " + NoTrailZeros(ap) + " = the hit's " + NoTrailZeros(mult) + "; damage " + NoTrailZeros(dmg) + ", the hit dealt " + NoTrailZeros(dealt));
}

// UI-01 against Ghost Mode's formula: needs the hostile test dummy, neutral (gmtest_dummy("human") for
// the steel sword, gmtest_dummy("drowner") for the silver one with silver = true, then
// gmtest_dummy_neutral()). Fast and strong, normal and crit; with the new tree's Muscle Memory armed and
// Strength Training stacked when equipped. Run it without skills and with each tree's sword skills.
exec function gmtest_ui01_hits(optional silver : bool)
{
	var w : W3PlayerWitcher;
	var npc : CActor;
	var probes : bool;
	var i : int;
	var tmp : float;
	var tmpCrit : bool;

	thePlayer.GMTestCount(true, true);
	w = GetWitcherPlayer();
	npc = GMTestDummy();
	if(!npc)
	{
		GMTestReport(false, "UI-01 hits: spawn the test dummy first");
		return;
	}
	probes = GMTestProbes();
	w.GMTestSetProbes(true);
	if(w.CanUseSkill(S_Sword_s22))
		w.GMMuscleMemoryArm();
	GMTestUi01Compare(npc, silver, false, false);
	GMTestUi01Compare(npc, silver, false, true);
	if(w.CanUseSkill(S_Sword_s23))
	{
		for(i = 0; i < 3; i += 1)
			GMTestUi01Hit(npc, silver, 'attack_light', false, tmp, tmpCrit);
		LogChannel('GMTest', "INFO UI-01 Strength Training stacks " + w.GMStrengthTrainingStacks() + ", Muscle Memory armed " + w.GMMuscleMemoryArmed());
	}
	GMTestUi01Compare(npc, silver, true, false);
	GMTestUi01Compare(npc, silver, true, true);
	w.GMTestSetProbes(probes);
	LogChannel('GMTest', "SUMMARY ui01_hits: " + thePlayer.gmTestPassed + " passed, " + thePlayer.gmTestFailed + " failed");
}

// UI-01 terms with gear and skills, read off the list (both trees: equip the tree's skills first with
// skilleq, a crossbow and bolts with additem): the crossbow (Steady Shot or Cold Blood's flat damage,
// Anatomical Knowledge's crit damage, Cat Eyes' doubled base when equipped), and with mode 2 the Bear
// set's attack power or the Feline chain (two fast hits' worth added by script), with their pieces worn.
exec function gmtest_ui01_terms(optional mode : int)
{
	var w : W3PlayerWitcher;
	var gm, gm0 : SGMOffenseStats;
	var crossbow, bolt : SItemUniqueId;
	var ap : SAbilityAttributeValue;
	var base, expected, steady, mult, fast, strong, bear : float;
	var ap1 : SAbilityAttributeValue;
	var lynx : W3Effect_LynxSetBonus;
	var min, max : SAbilityAttributeValue;

	thePlayer.GMTestCount(true, true);
	w = GetWitcherPlayer();
	w.ForceSetStat(BCS_Focus, 0);
	gm = w.GMGetOffenseStats();
	if(w.GetItemEquippedOnSlot(EES_RangedWeapon, crossbow) && w.GetItemEquippedOnSlot(EES_Bolt, bolt))
	{
		ap = w.GetPowerStatValue(CPS_AttackPower) + w.inv.GetItemAttributeValue(crossbow, PowerStatEnumToName(CPS_AttackPower));
		base = CalculateAttributeValue(w.inv.GetItemAttributeValue(bolt, gm.crossbowSteelDmgType));
		steady = w.GMSteadyShotDamage();
		mult = 1;
		if(w.IsMutationActive(EPMT_Mutation9))
		{
			theGame.GetDefinitionsManager().GetAbilityAttributeValue('Mutation9', 'mut9_damage', min, max);
			mult = 1 + min.valueMultiplicative;
		}
		expected = ((base + steady) * mult + ap.valueBase) * ap.valueMultiplicative;
		GMTestReport(GMTestUiNear(gm.crossbowSteelDmg, expected), "UI-01 crossbow " + w.inv.GetItemName(bolt) + ": " + NoTrailZeros(gm.crossbowSteelDmg) + " " + gm.crossbowSteelDmgType + " = (" + NoTrailZeros(base) + " + Steady Shot " + NoTrailZeros(steady) + ") x Cat Eyes " + NoTrailZeros(mult) + " x attack power " + NoTrailZeros(ap.valueMultiplicative));
		expected = CalculateAttributeValue(w.GetCriticalHitDamageBonus(crossbow, MC_NotSet, false) + w.inv.GetItemAttributeValue(crossbow, theGame.params.CRITICAL_HIT_DAMAGE_BONUS) + w.GMAnatomicalKnowledgeCritDamage());
		GMTestReport(GMTestUiNear(gm.crossbowCritDmgBonus, expected), "UI-01 crossbow crit damage +" + NoTrailZeros(gm.crossbowCritDmgBonus * 100) + " % (Anatomical Knowledge " + SkillEnumToName(w.GMAnatomicalKnowledgeSkill()) + " +" + NoTrailZeros(CalculateAttributeValue(w.GMAnatomicalKnowledgeCritDamage()) * 100) + " %), crit chance " + NoTrailZeros(gm.crossbowCritChance * 100) + " %, attack power " + NoTrailZeros(gm.crossbowAttackPower));
	}
	else
		GMTestReport(false, "UI-01 crossbow: equip a crossbow and bolts first");
	LogChannel('GMTest', "INFO UI-01 fast crit chance " + NoTrailZeros(gm.steelFastCritChance) + " %, strong " + NoTrailZeros(gm.steelStrongCritChance) + " %; Precise/Crushing Blows +" + NoTrailZeros(w.GMOffenseBlowsCritChance(false) * 100) + " / +" + NoTrailZeros(w.GMOffenseBlowsCritChance(true) * 100) + " %, crit power +" + NoTrailZeros(w.GMOffenseBlowsCritPower(false)) + " / +" + NoTrailZeros(w.GMOffenseBlowsCritPower(true)));
	if(mode == 2)
	{
		gm0 = gm;
		ap = w.GetPowerStatValue(CPS_AttackPower);
		w.ForceSetStat(BCS_Focus, 2.5);
		ap1 = w.GetPowerStatValue(CPS_AttackPower);
		if(w.IsSetBonusActive(EISB_Lynx_1))
		{
			w.RemoveBuff(EET_LynxSetBonus);
			w.AddEffectDefault(EET_LynxSetBonus, NULL, "LynxSetBuff");
			lynx = (W3Effect_LynxSetBonus)w.GetBuff(EET_LynxSetBonus);
			lynx.GMManageLynxBonus(false);
			lynx.GMManageLynxBonus(false);
			fast = lynx.GMGetLynxBonus(false);
			strong = lynx.GMGetLynxBonus(true);
		}
		gm = w.GMGetOffenseStats();
		bear = w.GMBearSetAttackPower();
		GMTestReport((bear > 0 || fast > 0) && GMTestUiNear(gm.steelFastAP - gm0.steelFastAP, ap1.valueMultiplicative - ap.valueMultiplicative + fast + bear) && GMTestUiNear(gm.silverStrongAP - gm0.silverStrongAP, ap1.valueMultiplicative - ap.valueMultiplicative + strong + bear),
			"ARM-06, ARM-08 the list's attack power with the Feline chain (+" + NoTrailZeros(fast) + " fast, +" + NoTrailZeros(strong) + " strong) and the Bear set (+" + NoTrailZeros(bear) + ") at 2.5 adrenaline (its own +" + NoTrailZeros(ap1.valueMultiplicative - ap.valueMultiplicative) + "): fast " + NoTrailZeros(gm0.steelFastAP) + " -> " + NoTrailZeros(gm.steelFastAP) + ", strong " + NoTrailZeros(gm0.silverStrongAP) + " -> " + NoTrailZeros(gm.silverStrongAP));
		w.RemoveBuff(EET_LynxSetBonus);
		w.ForceSetStat(BCS_Focus, 0);
	}
	LogChannel('GMTest', "SUMMARY ui01_terms: " + thePlayer.gmTestPassed + " passed, " + thePlayer.gmTestFailed + " failed");
}

// The stats popup's section with the main line's tag (a menu must be open; nth: the nth such section, from
// 0): its main line first ("tag|name|value"), then its lines.
function GMTestPanelSection(mainTag : string, optional nth : int) : array<string>
{
	var menu : CR4Menu;
	var data, stat, line : CScriptedFlashObject;
	var stats, sub : CScriptedFlashArray;
	var i, j : int;
	var lines : array<string>;

	menu = theGame.GetGuiManager().GetRootMenu();
	if(!menu)
		return lines;
	data = GetPlayerStatsGFxData(menu.GetMenuFlashValueStorage());
	stats = data.GetMemberFlashArray("stats");
	for(i = 0; i < stats.GetLength(); i += 1)
	{
		stat = stats.GetElementFlashObject(i);
		if(stat.GetMemberFlashString("tag") != mainTag)
			continue;
		if(nth > 0)
		{
			nth -= 1;
			continue;
		}
		lines.PushBack(mainTag + "|" + stat.GetMemberFlashString("name") + "|" + stat.GetMemberFlashString("value"));
		sub = stat.GetMemberFlashArray("subStats");
		for(j = 0; j < sub.GetLength(); j += 1)
		{
			line = sub.GetElementFlashObject(j);
			lines.PushBack(line.GetMemberFlashString("tag") + "|" + line.GetMemberFlashString("name") + "|" + line.GetMemberFlashString("value"));
		}
		break;
	}
	return lines;
}

// The line with the tag ("" if none): "name|value".
function GMTestPanelLine(lines : array<string>, tag : string) : string
{
	var i : int;

	for(i = 0; i < lines.Size(); i += 1)
		if(StrStartsWith(lines[i], tag + "|"))
			return StrAfterFirst(lines[i], "|");
	return "";
}

function GMTestPanelValue(lines : array<string>, tag : string) : string
{
	return StrAfterFirst(GMTestPanelLine(lines, tag), "|");
}

function GMTestPanelName(lines : array<string>, tag : string) : string
{
	return StrBeforeFirst(GMTestPanelLine(lines, tag), "|");
}

// UI-02 (in gmtest_panel(), a menu open): the sword and crossbow sections show Ghost Mode's list in
// legacy's lines, labels and formats; the summary line's label (both character menus, the inventory).
function GMTest_ui02()
{
	var w : W3PlayerWitcher;
	var s : SGMOffenseStats;
	var silver, steel, xbow, extra : array<string>;
	var focus, chance, ik1, ik2 : float;
	var item : SItemUniqueId;
	var menu : CR4Menu;
	var arr : CScriptedFlashArray;
	var obj : CScriptedFlashObject;
	var fastName : string;

	w = GetWitcherPlayer();
	focus = w.GetStat(BCS_Focus);
	w.ForceSetStat(BCS_Focus, 0);
	s = w.GMGetOffenseStats();
	silver = GMTestPanelSection("mainSilverStat");
	steel = GMTestPanelSection("mainSteelStat");
	xbow = GMTestPanelSection("majorStat4");
	extra = GMTestPanelSection("majorStat5");
	if(silver.Size() == 0)
	{
		GMTestReport(false, "UI-02 a menu is open (run ingamemenu() first)");
		w.ForceSetStat(BCS_Focus, focus);
		return;
	}
	GMTestReport(GMTestPanelName(silver, "mainSilverStat") == GetLocStringByKeyExt("panel_common_statistics_tooltip_silver_dph_gm") && GMTestPanelValue(silver, "mainSilverStat") == NoTrailZeros(RoundMath((s.silverFastDPS + s.silverStrongDPS) / 2))
		&& GMTestPanelName(steel, "mainSteelStat") == GetLocStringByKeyExt("panel_common_statistics_tooltip_steel_dph_gm") && GMTestPanelValue(steel, "mainSteelStat") == NoTrailZeros(RoundMath((s.steelFastDPS + s.steelStrongDPS) / 2)),
		"UI-02 the sword lines: '" + GMTestPanelLine(silver, "mainSilverStat") + "', '" + GMTestPanelLine(steel, "mainSteelStat") + "' (the average expected hit)");
	GMTestReport(silver.Size() == 1 + 1 + 12 + 6 && GMTestPanelValue(silver, "silverStat0") == NoTrailZeros(RoundMath(s.silverFastAP * 100)) + " %" && GMTestPanelValue(silver, "silverStat1") == NoTrailZeros(RoundMath(s.silverFastDmg))
		&& GMTestPanelValue(silver, "silverStat2") == NoTrailZeros(RoundMath(s.silverFastCritChance)) + " %" && GMTestPanelValue(silver, "silverStat3") == NoTrailZeros(RoundMath(s.silverFastCritAP * 100)) + " %"
		&& GMTestPanelValue(silver, "silverStat9") == NoTrailZeros(RoundMath(s.silverStrongCritDmg)) && GMTestPanelValue(steel, "steelStat6") == NoTrailZeros(RoundMath(s.steelStrongDmg)),
		"UI-02 the silver section (" + silver.Size() + " lines): " + GMTestPanelLine(silver, "silverStat0") + "; " + GMTestPanelLine(silver, "silverStat1") + "; " + GMTestPanelLine(silver, "silverStat2") + "; "
		+ GMTestPanelLine(silver, "silverStat3") + "; " + GMTestPanelLine(silver, "silverStat4") + "; " + GMTestPanelLine(silver, "silverStat9"));
	fastName = GMTestPanelName(silver, "silverStat1");
	GMTestReport(fastName != "" && (fastName == GetLocStringById(2110992079) || fastName == GetLocStringById(2110992084)) && GMTestPanelName(silver, "silverStat0") == GetLocStringByKeyExt("gm_combat_stats_fast_attack_power"),
		"UI-02 legacy's labels: '" + fastName + "', '" + GMTestPanelName(silver, "silverStat0") + "', '" + GMTestPanelName(silver, "silverStat3") + "'");
	chance = w.GMCripplingStrikesValue('sword_s5_chance', true);
	if(w.GetItemEquippedOnSlot(EES_SteelSword, item))
		chance += CalculateAttributeValue(w.inv.GetItemAttributeValue(item, 'desc_bleedingchance_mult'));
	chance *= w.GMMutation12ChanceMult();
	GMTestReport(GMTestPanelValue(steel, "steelStat11") == NoTrailZeros(RoundMath(chance * 100)) + " %", "UI-02 the steel bleeding chance " + GMTestPanelLine(steel, "steelStat11") + " (Crippling Strikes " + NoTrailZeros(w.GMCripplingStrikesValue('sword_s5_chance', true) * 100) + " %)");
	GMTestReport(GMTestPanelValue(xbow, "steelStat17") == NoTrailZeros(RoundMath(s.crossbowAttackPower * 100)) + " %" && GMTestPanelValue(xbow, "steelStat21") == NoTrailZeros(RoundMath(s.crossbowSteelDmg))
		&& GMTestPanelValue(xbow, "steelStat19") == NoTrailZeros(RoundMath(s.crossbowCritDmgBonus * 100)) + " %" && GMTestPanelLine(xbow, "steelStat20") != "",
		"UI-02 the crossbow section: " + GMTestPanelLine(xbow, "steelStat17") + "; " + GMTestPanelLine(xbow, "steelStat18") + "; " + GMTestPanelLine(xbow, "steelStat19") + "; " + GMTestPanelLine(xbow, "steelStat20") + "; " + GMTestPanelLine(xbow, "steelStat21") + "; " + GMTestPanelLine(xbow, "steelStat22") + "; headline " + GMTestPanelValue(xbow, "majorStat4"));
	if(w.GetItemEquippedOnSlot(EES_SteelSword, item))
		ik1 = CalculateAttributeValue(w.inv.GetItemAttributeValue(item, 'instant_kill_chance_mult'));
	if(w.GetItemEquippedOnSlot(EES_SilverSword, item))
		ik2 = CalculateAttributeValue(w.inv.GetItemAttributeValue(item, 'instant_kill_chance_mult'));
	GMTestReport(GMTestPanelValue(extra, "extraStat2") == NoTrailZeros(RoundMath(MaxF(ik1, ik2) * 100)) + " %", "UI-02 instant kill " + GMTestPanelLine(extra, "extraStat2") + " (the larger sword's)");
	menu = theGame.GetGuiManager().GetRootMenu();
	arr = menu.GetMenuFlashValueStorage().CreateTempFlashArray();
	obj = AddCharacterStatU("mainSilverStat", 'silverdamage', "panel_common_statistics_tooltip_silver_dps", "attack_silver", arr, menu.GetMenuFlashValueStorage());
	GMTestReport(obj.GetMemberFlashString("name") == GetLocStringByKeyExt("panel_common_statistics_tooltip_silver_dph_gm"), "UI-02 the menus' summary line (5.x's call) reads '" + obj.GetMemberFlashString("name") + " " + obj.GetMemberFlashString("value") + "'");
	w.ForceSetStat(BCS_Focus, focus);
}

// A section's line by position: "name|value".
function GMTestPanelAt(lines : array<string>, i : int) : string
{
	if(i >= lines.Size())
		return "";
	return StrAfterFirst(lines[i], "|");
}

function GMTestPanelValueAt(lines : array<string>, i : int) : string
{
	return StrAfterFirst(GMTestPanelAt(lines, i), "|");
}

function GMTestPanelNameAt(lines : array<string>, i : int) : string
{
	return StrBeforeFirst(GMTestPanelAt(lines, i), "|");
}

// UI-03 (in gmtest_panel(), a menu open): the sign lines in two sections (Aard, Igni, Quen; Yrden, Axii),
// legacy's labels, the values without the skills.
function GMTest_ui03()
{
	var w : W3PlayerWitcher;
	var s1, s2 : array<string>;
	var sp : SAbilityAttributeValue;
	var i : int;

	w = GetWitcherPlayer();
	s1 = GMTestPanelSection("mainMagicStat", 0);
	s2 = GMTestPanelSection("mainMagicStat", 1);
	GMTestReport(s1.Size() == 19 && s2.Size() == 16, "UI-03 two sign sections: " + s1.Size() + " and " + s2.Size() + " lines");
	GMTestReport(GMTestPanelNameAt(s1, 5) == GetLocStringById(2110992293) && GMTestPanelNameAt(s1, 11) == GetLocStringById(2110992019)
		&& GMTestPanelNameAt(s1, 17) == GetLocStringById(2110992030) && GMTestPanelNameAt(s2, 6) == GetLocStringById(2110992461)
		&& GMTestPanelNameAt(s2, 13) == GetLocStringById(2110992277) && GMTestPanelNameAt(s1, 4) == GetLocStringById(2110992272),
		"UI-03 legacy's labels: '" + GMTestPanelAt(s1, 4) + "', '" + GMTestPanelAt(s1, 5) + "', '" + GMTestPanelAt(s1, 11) + "', '" + GMTestPanelAt(s1, 17) + "', '" + GMTestPanelAt(s2, 6) + "', '" + GMTestPanelAt(s2, 13) + "'");
	for(i = 2; i < s1.Size(); i += 1)
		if(GMTestPanelNameAt(s1, i) == "")
			break;
	GMTestReport(i == s1.Size(), "UI-03 every line of the first section has a name (first without: " + i + ")");
	for(i = 2; i < s2.Size(); i += 1)
		if(GMTestPanelNameAt(s2, i) == "")
			break;
	GMTestReport(i == s2.Size(), "UI-03 every line of the second section has a name (first without: " + i + ")");
	sp = w.GetTotalSignSpellPower(S_Magic_1);
	GMTestReport(GMTestPanelValueAt(s1, 3) == (string)RoundMath(MaxF(sp.valueMultiplicative - 1, 0) * 100) + " %" && GMTestPanelValueAt(s1, 4) == GMPanelPercent(GMPanelAardKnockdownChance()),
		"UI-03 Aard: " + GMTestPanelAt(s1, 3) + "; " + GMTestPanelAt(s1, 4) + "; " + GMTestPanelAt(s1, 5) + "; " + GMTestPanelAt(s1, 6));
	if(GMPanelSkill(S_Magic_s06, S_Magic_s33) == S_SUndefined && GMPanelSkill(S_Magic_s02, S_Magic_s28) == S_SUndefined && !w.CanUseSkill(S_Magic_s03) && !w.CanUseSkill(S_Magic_s04))
		GMTestReport(GMTestPanelValueAt(s1, 6) == "0" && GMTestPanelValueAt(s1, 11) == "0" && GMTestPanelValueAt(s1, 18) == "0" && GMTestPanelValueAt(s2, 9) == "0" && GMTestPanelValueAt(s2, 10) == "0",
			"UI-03 without the skills: Shock Wave, Firestream, the active shield and the turret read 0");
	LogChannel('GMTest', "INFO UI-03 Igni: " + GMTestPanelAt(s1, 8) + "; " + GMTestPanelAt(s1, 9) + "; " + GMTestPanelAt(s1, 10) + "; " + GMTestPanelAt(s1, 11));
	LogChannel('GMTest', "INFO UI-03 Quen: " + GMTestPanelAt(s1, 13) + "; " + GMTestPanelAt(s1, 14) + "; " + GMTestPanelAt(s1, 15) + "; " + GMTestPanelAt(s1, 16) + "; " + GMTestPanelAt(s1, 17) + "; " + GMTestPanelAt(s1, 18));
	LogChannel('GMTest', "INFO UI-03 Yrden: " + GMTestPanelAt(s2, 3) + "; " + GMTestPanelAt(s2, 4) + "; " + GMTestPanelAt(s2, 5) + "; " + GMTestPanelAt(s2, 6) + "; " + GMTestPanelAt(s2, 7) + "; " + GMTestPanelAt(s2, 8) + "; " + GMTestPanelAt(s2, 9) + "; " + GMTestPanelAt(s2, 10));
	LogChannel('GMTest', "INFO UI-03 Axii: " + GMTestPanelAt(s2, 12) + "; " + GMTestPanelAt(s2, 13) + "; " + GMTestPanelAt(s2, 14) + "; " + GMTestPanelAt(s2, 15));
}

// UI-03 with the sign skills equipped (a menu open; skilleq at the levels in docs/features/ui.md): the
// classic skills at level 5 and the new tree's at level 3 give the same totals (D58).
exec function gmtest_ui03_skills()
{
	var w : W3PlayerWitcher;
	var s1, s2 : array<string>;
	var sp : SAbilityAttributeValue;
	var skill : ESkill;
	var perLevel, base, absorption : float;

	thePlayer.GMTestCount(true, true);
	w = GetWitcherPlayer();
	s1 = GMTestPanelSection("mainMagicStat", 0);
	s2 = GMTestPanelSection("mainMagicStat", 1);
	GMTest_ui03();
	GMTestReport(GMTestPanelValueAt(s1, 5) == GMPanelPercent(0.30 * GMPanelAardKnockdownChance()), "UI-03 Aard Intensity " + SkillEnumToName(GMPanelSkill(S_Magic_s12, S_Magic_s39)) + ": heavy knockdown 30 % of the knockdown chance, '" + GMTestPanelValueAt(s1, 5) + "'");
	skill = GMPanelSkill(S_Magic_s06, S_Magic_s33);
	if(skill == S_Magic_s06)
		perLevel = 60;
	else
		perLevel = 100;
	GMTestReport(skill != S_SUndefined && GMTestPanelValueAt(s1, 6) == (string)RoundMath(GMPanelSignDamage(perLevel * w.GetSkillLevel(skill), S_Magic_1)), "UI-03 Shock Wave " + SkillEnumToName(skill) + " level " + w.GetSkillLevel(skill) + ": " + GMTestPanelAt(s1, 6));
	GMTestReport(GMTestPanelValueAt(s1, 9) == "58 %", "UI-03 Pyromaniac " + SkillEnumToName(w.GMPyromaniacSkill()) + ": burn chance 33 + 25 %, '" + GMTestPanelValueAt(s1, 9) + "'");
	GMTestReport(GMTestPanelValueAt(s1, 10) == (string)RoundMath(GMPanelSignDamage(150 + 150, S_Magic_2)), "UI-03 Igni Intensity " + SkillEnumToName(w.GMIgniIntensitySkill()) + ": fire damage (150 + 150) x intensity, '" + GMTestPanelValueAt(s1, 10) + "'");
	GMTestReport(GMTestPanelValueAt(s1, 11) != "0", "UI-03 Firestream " + SkillEnumToName(GMPanelSkill(S_Magic_s02, S_Magic_s28)) + ": " + GMTestPanelAt(s1, 11));
	sp = w.GetTotalSignSpellPower(S_Magic_4);
	absorption = (250 + 150) * (1 + GMSignPowerStatToPowerBonus(sp.valueMultiplicative));
	GMTestReport(GMTestPanelValueAt(s1, 17) == (string)RoundMath(absorption) && GMTestPanelValueAt(s1, 18) == (string)RoundMath(absorption * 2),
		"UI-03 Quen Intensity " + SkillEnumToName(GMPanelSkill(S_Magic_s15, S_Magic_s38)) + ": absorption (250 + 150) x (1 + bonus), active shield x 2: " + GMTestPanelAt(s1, 17) + "; " + GMTestPanelAt(s1, 18));
	GMTestReport(GMTestPanelValueAt(s1, 16) == "25 %", "UI-03 Quen Discharge " + SkillEnumToName(GMPanelSkill(S_Magic_s14, S_Magic_s40)) + ": " + GMTestPanelAt(s1, 16));
	GMTestReport(w.GetSkillLevel(S_Magic_s13) >= 2 && GMTestPanelValueAt(s1, 15) == (string)RoundMath(GMPanelSignDamage(30 * (w.GetSkillLevel(S_Magic_s13) - 1), S_Magic_4)), "UI-03 Exploding Shield level " + w.GetSkillLevel(S_Magic_s13) + ": " + GMTestPanelAt(s1, 15));
	GMTestReport(GMTestPanelValueAt(s2, 4) == "2", "UI-03 Sustained Glyphs " + SkillEnumToName(GMPanelSkill(S_Magic_s10, S_Magic_s42)) + " level 3: traps '" + GMTestPanelValueAt(s2, 4) + "'");
	base = CalculateAttributeValue(w.GetSkillAttributeValue(S_Magic_s03, theGame.params.DAMAGE_NAME_SHOCK, false, true)) + CalculateAttributeValue(w.GetSkillAttributeValue(S_Magic_s03, 'damage_bonus_flat_after_1', false, false)) * (w.GetSkillLevel(S_Magic_s03) - 1);
	GMTestReport(GMTestPanelValueAt(s2, 10) == (string)RoundMath(GMPanelSignDamage(base + 150, S_Magic_3)), "UI-03 Yrden Intensity " + SkillEnumToName(GMPanelSkill(S_Magic_s16, S_Magic_s37)) + ": turret damage (" + NoTrailZeros(base) + " + 150) x intensity, '" + GMTestPanelValueAt(s2, 10) + "'");
	GMTestReport(GMTestPanelValueAt(s2, 15) != GMPanelSeconds(0), "UI-03 Puppet " + SkillEnumToName(GMPanelSkill(S_Magic_s05, S_Magic_s31)) + ": " + GMTestPanelAt(s2, 15));
	LogChannel('GMTest', "SUMMARY ui03_skills: " + thePlayer.gmTestPassed + " passed, " + thePlayer.gmTestFailed + " failed");
}

// UI-01 (in gmtest_panel(); UI audit F9): the panel's crit chance equals the hit's (GetCriticalHitChance)
// for each sword, fast and strong. For the drawn sword as is; for a sheathed one, its own crit chance and
// the Wolven set's oil bonus added (a hit gets them from the held sword), the drawn other sword's taken off.
function GMTest_ui01_crit()
{
	GMTestUi01Crit(false);
	GMTestUi01Crit(true);
}

exec function gmtest_ui01_crit()
{
	thePlayer.GMTestCount(true, true);
	GMTest_ui01_crit();
	LogChannel('GMTest', "SUMMARY ui01_crit: " + thePlayer.gmTestPassed + " passed, " + thePlayer.gmTestFailed + " failed");
}

// Draws a sword (for gmtest_ui01_crit() in a later call, the drawn sword's case).
exec function gmtest_ui01_draw(optional silver : bool)
{
	if(silver)
		GetWitcherPlayer().OnEquipMeleeWeapon(PW_Silver, true);
	else
		GetWitcherPlayer().OnEquipMeleeWeapon(PW_Steel, true);
}

function GMTestUi01Crit(silver : bool)
{
	var w : W3PlayerWitcher;
	var gm : SGMOffenseStats;
	var sword, other : SItemUniqueId;
	var adjust, hitFast, hitStrong, panelFast, panelStrong : float;
	var label : string;

	w = GetWitcherPlayer();
	gm = w.GMGetOffenseStats();
	if(silver)
	{
		w.GetItemEquippedOnSlot(EES_SilverSword, sword);
		w.GetItemEquippedOnSlot(EES_SteelSword, other);
		panelFast = gm.silverFastCritChance;
		panelStrong = gm.silverStrongCritChance;
		label = "silver";
	}
	else
	{
		w.GetItemEquippedOnSlot(EES_SteelSword, sword);
		w.GetItemEquippedOnSlot(EES_SilverSword, other);
		panelFast = gm.steelFastCritChance;
		panelStrong = gm.steelStrongCritChance;
		label = "steel";
	}
	if(!w.inv.IsIdValid(sword))
	{
		LogChannel('GMTest', "INFO UI-01 crit chance: no " + label + " sword equipped, not checked");
		return;
	}
	if(w.inv.IsItemHeld(sword))
		label += " (drawn)";
	else
	{
		label += " (sheathed)";
		adjust = CalculateAttributeValue(w.inv.GetItemAttributeValue(sword, theGame.params.CRITICAL_HIT_CHANCE)) + w.inv.GMOilWolfCritBonus(sword, 'per_oil_crit_chance_bonus');
		if(w.inv.IsIdValid(other) && w.inv.IsItemHeld(other))
			adjust -= CalculateAttributeValue(w.inv.GetItemAttributeValue(other, theGame.params.CRITICAL_HIT_CHANCE)) + w.inv.GMOilWolfCritBonus(other, 'per_oil_crit_chance_bonus');
	}
	hitFast = (w.GetCriticalHitChance(true, false, NULL, MC_NotSet, false) + adjust) * 100;
	hitStrong = (w.GetCriticalHitChance(false, true, NULL, MC_NotSet, false) + adjust) * 100;
	GMTestReport(GMTestUiNear(panelFast, hitFast) && GMTestUiNear(panelStrong, hitStrong), "UI-01 " + label + " crit chance: the panel's fast " + NoTrailZeros(RoundTo(panelFast, 2)) + " %, strong " + NoTrailZeros(RoundTo(panelStrong, 2))
		+ " % = the hit's " + NoTrailZeros(RoundTo(hitFast, 2)) + " %, " + NoTrailZeros(RoundTo(hitStrong, 2)) + " % (sword's own " + NoTrailZeros(RoundTo(adjust * 100, 2)) + " % added)");
}

// UI-03 against real casts (UI audit F9; both trees). Each sign is cast by input simulation, and the cast
// entities' values are compared with the panel's lines: Quen's shield health and duration, Yrden's trap
// duration, range and trap count, Axii's confusion on the target. Setup: setlevel(30), the sign skills of
// docs/features/ui.md (UI-03's real casts), gmtest_dummy("human"), then gmtest_dummy_neutral(), god() and
// autolock(); then, per sign, the cast and a couple of seconds later its check (exec --wait 2500):
//   gmtest_ui03_cast(ST_Quen), gmtest_ui03_casts(ST_Quen), the same for ST_Yrden, then ST_Axii
// (Quen first: its check starts the count). Each sign is checked before the next cast: Quen's shield is
// gone once another sign is cast. The sign cooldowns (STAM-01) are per sign: no option change needed.
@addMethod(W3QuenEntity)
function GMTestQuenValues(out health : float, out duration : float)
{
	health = initialShieldHealth;
	duration = shieldDuration;
}

@addMethod(W3YrdenEntity)
function GMTestYrdenValues(out duration : float, out range : float, out traps : int)
{
	duration = trapDuration;
	range = baseModeRange;
	traps = gmMaxCount;
}

// Releases the previous cast input, then presses the cast input with the sign selected.
exec function gmtest_ui03_cast(sign : ESignType)
{
	GMTestCastInput(false);
	GetWitcherPlayer().SetEquippedSign(sign);
	GMTestCastInput(true);
	LogChannel('GMTest', "INFO UI-03 cast " + sign + ": casting " + thePlayer.IsCastingSign() + ", stamina " + NoTrailZeros(RoundTo(thePlayer.GetStat(BCS_Stamina), 1)));
}

// A sign line's number as shown (its seconds suffix removed).
function GMTestUi03PanelNumber(key : name) : float
{
	var found : bool;

	return StringToFloat(StrReplace(GMPanelSignValue(key, found), GetLocStringByKeyExt("per_second"), ""));
}

// The cast's value equals the panel's number up to the line's display precision (step: 1 or 0.1).
function GMTestUi03Shown(cast : float, key : name, step : float) : bool
{
	return AbsF(cast - GMTestUi03PanelNumber(key)) <= step / 2 + 0.001;
}

exec function gmtest_ui03_casts(sign : ESignType)
{
	var w : W3PlayerWitcher;
	var quen : W3QuenEntity;
	var yrden : W3YrdenEntity;
	var npc : CNewNPC;
	var buff : CBaseGameplayEffect;
	var found : bool;
	var health, duration, range : float;
	var traps : int;

	GMTestCastInput(false);
	w = GetWitcherPlayer();
	if(sign == ST_Quen)
	{
		thePlayer.GMTestCount(true, true);
		LogChannel('GMTest', "INFO UI-03 casts: classic tree " + GMIsClassicSkillTree() + ", level " + w.GetLevel());
		quen = (W3QuenEntity)w.GetSignEntity(ST_Quen);
		if(quen)
			quen.GMTestQuenValues(health, duration);
		GMTestReport(quen && GMTestUi03Shown(health, 'quen_damageabs', 1) && GMTestUi03Shown(duration, 'quen_duration', 1),
			"UI-03 Quen cast: the shield's health " + NoTrailZeros(RoundTo(health, 2)) + " and duration " + NoTrailZeros(RoundTo(duration, 2)) + " s; the panel's " + GMPanelSignValue('quen_damageabs', found) + " and " + GMPanelSignValue('quen_duration', found));
	}
	else if(sign == ST_Yrden)
	{
		yrden = (W3YrdenEntity)w.GetSignEntity(ST_Yrden);
		if(yrden)
			yrden.GMTestYrdenValues(duration, range, traps);
		GMTestReport(yrden && GMTestUi03Shown(duration, 'yrden_duration', 0.1) && GMTestUi03Shown(range, 'yrden_range', 0.1) && GMTestUi03Shown((float)traps, 'yrden_traps', 1),
			"UI-03 Yrden cast: the trap's duration " + NoTrailZeros(RoundTo(duration, 2)) + " s, range " + NoTrailZeros(RoundTo(range, 2)) + ", traps " + traps + "; the panel's " + GMPanelSignValue('yrden_duration', found) + ", " + GMPanelSignValue('yrden_range', found) + ", " + GMPanelSignValue('yrden_traps', found));
	}
	else if(sign == ST_Axii)
	{
		npc = GMTestDummy();
		if(npc)
			buff = npc.GetBuff(EET_Confusion);
		if(buff)
			duration = buff.GetInitialDuration();
		GMTestReport(buff && GMTestUi03Shown(duration, 'axii_duration_confusion', 0.1),
			"UI-03 Axii cast: the confusion's duration " + NoTrailZeros(RoundTo(duration, 2)) + " s on the dummy (found " + (bool)buff + "); the panel's " + GMPanelSignValue('axii_duration_confusion', found));
	}
	LogChannel('GMTest', "SUMMARY ui03_casts: " + thePlayer.gmTestPassed + " passed, " + thePlayer.gmTestFailed + " failed");
}

// UI-04 (in gmtest_panel(), a menu open): legacy's toxicity lines: locked, available, decay, overdose
// threshold, overdose drain; no current toxicity line.
function GMTest_ui04()
{
	var w : W3PlayerWitcher;
	var tox : array<string>;

	w = GetWitcherPlayer();
	tox = GMTestPanelSection("majorStat2");
	GMTestReport(tox.Size() == 7 && GMTestPanelNameAt(tox, 3) == GetLocStringById(2110992425) && GMTestPanelNameAt(tox, 4) == GetLocStringById(2110992424)
		&& GMTestPanelNameAt(tox, 5) == GetLocStringById(2110992519) && GMTestPanelNameAt(tox, 6) == GetLocStringById(2110992423),
		"UI-04 the toxicity section (" + tox.Size() + " lines): " + GMTestPanelAt(tox, 2) + "; " + GMTestPanelAt(tox, 3) + "; " + GMTestPanelAt(tox, 4) + "; " + GMTestPanelAt(tox, 5) + "; " + GMTestPanelAt(tox, 6));
	GMTestReport(GMTestPanelValueAt(tox, 3) == NoTrailZeros(RoundMath(w.GetStatMax(BCS_Toxicity) - w.GetStat(BCS_Toxicity))) && GMTestPanelValueAt(tox, 5) == NoTrailZeros(RoundMath(0.75 * w.GetStatMax(BCS_Toxicity)))
		&& GMTestPanelValueAt(tox, 6) == NoTrailZeros(RoundMath(w.GMGetToxicityDamage())) + "/" + GetLocStringByKeyExt("per_second"),
		"UI-04 available " + GMTestPanelValueAt(tox, 3) + ", overdose at 75 % of " + NoTrailZeros(w.GetStatMax(BCS_Toxicity)) + " = " + GMTestPanelValueAt(tox, 5) + ", drain " + GMTestPanelValueAt(tox, 6));
}

// UI-04 against the live toxicity effect (toxicity above 0, e.g. addstat(BCS_Toxicity, 30), and a menu
// open): the decay line equals the effect's decay per second.
exec function gmtest_ui04_live()
{
	var w : W3PlayerWitcher;
	var tox : array<string>;
	var effect : CBaseGameplayEffect;
	var ev : SAbilityAttributeValue;
	var decay : float;

	thePlayer.GMTestCount(true, true);
	w = GetWitcherPlayer();
	GMTest_ui04();
	tox = GMTestPanelSection("majorStat2");
	effect = w.GetBuff(EET_Toxicity);
	if(effect)
		ev = effect.GetEffectValue();
	decay = -(ev.valueAdditive + ev.valueMultiplicative * (ev.valueBase + w.GetStatMax(BCS_Toxicity)));
	if(w.IsMutationActive(EPMT_Mutation4))
		decay *= MaxF(0.01, 1 - GMMutation4DecayFactor());
	GMTestReport(effect && GMTestPanelValueAt(tox, 4) == NoTrailZeros(RoundTo(decay, 2)) + "/" + GetLocStringByKeyExt("per_second"),
		"UI-04 decay '" + GMTestPanelValueAt(tox, 4) + "' = the toxicity effect's " + NoTrailZeros(RoundTo(decay, 4)) + " (Fast Metabolism " + w.GetSkillLevel(S_Alchemy_s15) + ", medium set " + w.HasAbility('ArmorTypeMediumSetBonusAbility') + ", Toxic Blood " + w.IsMutationActive(EPMT_Mutation4) + ")");
	LogChannel('GMTest', "SUMMARY ui04_live: " + thePlayer.gmTestPassed + " passed, " + thePlayer.gmTestFailed + " failed");
}

// UI-05 (in gmtest_panel(), a menu open): Vitality regen with its multiplicative part, raw sign power, the
// misc section's money bonus and adrenaline gain, no experience lines.
function GMTest_ui05()
{
	var w : W3PlayerWitcher;
	var vit, signs, extra : array<string>;
	var sp : SAbilityAttributeValue;
	var regen, combatRegen, gain : float;
	var perSecond : string;

	w = GetWitcherPlayer();
	perSecond = "/" + GetLocStringByKeyExt("per_second");
	vit = GMTestPanelSection("majorStat1");
	signs = GMTestPanelSection("mainMagicStat");
	extra = GMTestPanelSection("majorStat5");
	sp = w.GetAttributeValue('vitalityRegen');
	regen = sp.valueAdditive + sp.valueMultiplicative * w.GetStatMax(BCS_Vitality);
	sp = w.GetAttributeValue('vitalityCombatRegen');
	combatRegen = sp.valueAdditive + sp.valueMultiplicative * w.GetStatMax(BCS_Vitality);
	GMTestReport(GMTestPanelValue(vit, "defStat12") == NoTrailZeros(RoundMath(regen)) + perSecond && GMTestPanelValue(vit, "defStat13") == NoTrailZeros(RoundMath(combatRegen)) + perSecond,
		"UI-05 Vitality regen add + mult x max: " + GMTestPanelLine(vit, "defStat12") + "; " + GMTestPanelLine(vit, "defStat13"));
	sp = w.GetPowerStatValue(CPS_SpellPower);
	GMTestReport(GMTestPanelValue(signs, "mainMagicStat") == "+" + (string)RoundMath(MaxF(sp.valueMultiplicative - 1, 0) * 100) + " %", "UI-05 raw sign power: " + GMTestPanelLine(signs, "mainMagicStat"));
	gain = 0.1 * (1 + CalculateAttributeValue(w.GetAttributeValue('focus_gain')) + GMPanelSkillPerLevel(GMPanelSkill(S_Sword_s20, S_SUndefined), 'focus_gain', true));
	if(w.CanUseSkill(S_Perk_07) || w.CanUseSkill(S_Perk_25))
		gain += CalculateAttributeValue(w.GetAttributeValue('bonus_focus_gain'));
	gain *= w.GMMutation7GainMult();
	GMTestReport(GMTestPanelName(extra, "extraStat0") != "" && GMTestPanelValue(extra, "extraStat0") != "" && GMTestPanelLine(extra, "extraStat3") == "" && GMTestPanelValue(extra, "extraStat4") == FloatToStringPrec(gain, 2),
		"UI-05 misc: " + GMTestPanelLine(extra, "extraStat0") + "; " + GMTestPanelLine(extra, "extraStat2") + "; " + GMTestPanelLine(extra, "extraStat4") + "; no experience lines (" + extra.Size() + " lines)");
}

// UI-05 with Muscle Memory, Strength Training and Razor Focus (a menu open; skilleq first): the fast and
// strong attack lines, +0.03 per level of each style skill (classic level 5, new tree level 3: D53, D54).
exec function gmtest_ui05_skills()
{
	var w : W3PlayerWitcher;
	var extra : array<string>;
	var i : int;
	var line : string;

	thePlayer.GMTestCount(true, true);
	w = GetWitcherPlayer();
	GMTest_ui05();
	extra = GMTestPanelSection("majorStat5");
	for(i = 0; i < extra.Size(); i += 1)
		line += extra[i] + "; ";
	GMTestReport(extra.Size() == 1 + 1 + 3 + 3, "UI-05 misc with both style skills: " + line);
	GMTestReport(GMTestPanelValueAt(extra, 6) == FloatToStringPrec(GMPanelAdrenalineGain('adrenaline_gain') + 0.1 * GMPanelSkillPerLevel(GMPanelSkill(S_Sword_s21, S_Sword_s22), 'light_focus_gain', true) * w.GMMutation7GainMult(), 2)
		&& GMTestPanelValueAt(extra, 7) == FloatToStringPrec(GMPanelAdrenalineGain('adrenaline_gain') + 0.1 * GMPanelSkillPerLevel(GMPanelSkill(S_Sword_s04, S_Sword_s23), 'heavy_focus_gain', true) * w.GMMutation7GainMult(), 2),
		"UI-05 fast " + GMTestPanelAt(extra, 6) + " (" + SkillEnumToName(GMPanelSkill(S_Sword_s21, S_Sword_s22)) + " " + NoTrailZeros(GMPanelSkillPerLevel(GMPanelSkill(S_Sword_s21, S_Sword_s22), 'light_focus_gain', true)) + "), strong " + GMTestPanelAt(extra, 7)
		+ " (" + SkillEnumToName(GMPanelSkill(S_Sword_s04, S_Sword_s23)) + " " + NoTrailZeros(GMPanelSkillPerLevel(GMPanelSkill(S_Sword_s04, S_Sword_s23), 'heavy_focus_gain', true)) + ")");
	LogChannel('GMTest', "SUMMARY ui05_skills: " + thePlayer.gmTestPassed + " passed, " + thePlayer.gmTestFailed + " failed");
}

// UI-10, UI-11 (in the regression): the kill counter counts and reads back (restored), the entry's text;
// the bestiary lists of the eight creatures follow Ghost Mode's bombs.
function GMTest_ui10()
{
	var w : W3PlayerWitcher;
	var before, beforeBoss : int;
	var text : string;

	w = GetWitcherPlayer();
	before = w.GMGetKills(GMENT_WOLF);
	beforeBoss = w.GMGetKills(GMENT_BOSS);
	w.GMIncKills(GMENT_WOLF);
	w.GMIncKills(GMENT_BOSS);
	text = GMKillCountText();
	GMTestReport(w.GMGetKills(GMENT_WOLF) == before + 1 && w.GMGetKills(GMENT_BOSS) == beforeBoss + 1 && StrFindFirst(text, GMGetLocStringByEnemyType(GMENT_WOLF) + ": " + (before + 1)) >= 0
		&& StrFindFirst(text, GetLocStringByKeyExt("gm_kills_bosses_total") + ": " + (beforeBoss + 1)) >= 0,
		"UI-10 the counter and the entry's text: " + StrReplaceAll(text, "<br>", "; "));
	w.GMTestKillsAdd(GMENT_WOLF, -1);
	w.GMTestKillsAdd(GMENT_BOSS, -1);
	GMTestReport(w.GMGetKills(GMENT_WOLF) == before && w.GMGetKills(GMENT_BOSS) == beforeBoss, "UI-10 the test's kills taken back");
}

@addMethod(W3PlayerWitcher)
function GMTestKillsAdd(et : EGMEnemyType, n : int)
{
	gmEnemiesKilledByType[et] += n;
}

function GMTestUi11Str(items : array<name>) : string
{
	var i : int;
	var s : string;

	for(i = 0; i < items.Size(); i += 1)
		s += NameToString(items[i]) + ",";
	return s;
}

// A creature's list by its journal alias (as the NPCs' code loads it): "tag: list".
function GMTestUi11List(alias : string) : string
{
	var resource : CJournalResource;
	var creature : CJournalCreature;

	resource = (CJournalResource)LoadResource(alias);
	if(resource)
		creature = (CJournalCreature)resource.GetEntry();
	if(!creature)
		return "(no entry)";
	return NameToString(creature.GetUniqueScriptTag()) + ": " + GMTestUi11Str(GMBestiaryItemsUsedAgainst(creature));
}

function GMTest_ui11()
{
	var leshen, succubus : array<name>;
	var tags : array<string>;
	var i : int;

	GMTestReport(GMTestUi11List("BestiaryLeshy") == "Leszy: Silver Dust Bomb 1,Relic Oil 1,Igni,", "UI-11 leshen (the journal's entry): " + GMTestUi11List("BestiaryLeshy"));
	GMTestReport(GMTestUi11List("BestiarySuccubus") == "Succubus: Hybrid Oil 1,Quen,Dwimeritium Bomb 1,", "UI-11 succubus (the journal's entry): " + GMTestUi11List("BestiarySuccubus"));
	GMTestReport(GMTestUi11List("BestiaryDzinn") == "Dzinn: Dwimeritium Bomb 1,Magicals Oil 1,Yrden,Axii,", "UI-11 djinn (the journal's entry): " + GMTestUi11List("BestiaryDzinn"));
	leshen.PushBack('Dwimeritium Bomb 1'); leshen.PushBack('Relic Oil 1'); leshen.PushBack('Igni');
	succubus.PushBack('Hybrid Oil 1'); succubus.PushBack('Quen');
	tags.PushBack("sq204 Ancient Leszen 920DD44F-4640510C-A48A8EAB-F8003E1D");
	tags.PushBack("mh302 : Leszy 8CCA7A96-4BD5C339-42B6F291-07412A2D");
	tags.PushBack("mq7002 Grottore E96773DE-48D2D0D5-974018A2-1E1EF657");
	tags.PushBack("mq7002 : Spriggan F281E002-49FFDC37-8398DAA6-BD22C527");
	for(i = 0; i < tags.Size(); i += 1)
		GMTestReport(GMTestUi11Str(GMBestiaryItemsFor(tags[i], leshen)) == "Silver Dust Bomb 1,Relic Oil 1,Igni,", "UI-11 " + tags[i] + ": " + GMTestUi11Str(GMBestiaryItemsFor(tags[i], leshen)));
	GMTestReport(GMTestUi11Str(GMBestiaryItemsFor("mh303 : Succubus D68E01B9-4EA4564C-2F363DA3-3A813843", succubus)) == "Hybrid Oil 1,Quen,Dwimeritium Bomb 1,", "UI-11 hunt mh303");
	GMTestReport(GMTestUi11Str(GMBestiaryItemsFor("Wolf", leshen)) == "Dwimeritium Bomb 1,Relic Oil 1,Igni,", "UI-11 other creatures keep their list");
}

// UI-10 with a real kill: spawns a wolf in front of Geralt and kills it through the game's death path
// with Geralt as the killer; a later call (gmtest_ui10_kill_b) reads the counter.
exec function gmtest_ui10_kill_a()
{
	var w : W3PlayerWitcher;

	w = GetWitcherPlayer();
	w.gmTestKillsBefore = w.GMGetKills(GMENT_WOLF);
	GMTestDummySpawn("wolf");
	LogChannel('GMTest', "INFO UI-10 wolf kills before: " + w.gmTestKillsBefore);
}

@addField(W3PlayerWitcher)
var gmTestKillsBefore : int;

exec function gmtest_ui10_kill_b()
{
	var npc : CActor;

	npc = GMTestDummy();
	if(npc)
		npc.Kill('GMTest', true, thePlayer);
	LogChannel('GMTest', "INFO UI-10 wolf killed: " + (bool)npc);
}

exec function gmtest_ui10_kill_c()
{
	var w : W3PlayerWitcher;

	thePlayer.GMTestCount(true, true);
	w = GetWitcherPlayer();
	GMTestReport(w.GMGetKills(GMENT_WOLF) == w.gmTestKillsBefore + 1, "UI-10 a wolf killed by Geralt counts: " + w.gmTestKillsBefore + " -> " + w.GMGetKills(GMENT_WOLF) + "; " + StrReplaceAll(GMKillCountText(), "<br>", "; "));
	LogChannel('GMTest', "SUMMARY ui10_kill: " + thePlayer.gmTestPassed + " passed, " + thePlayer.gmTestFailed + " failed");
}

// Opens the bestiary on the kill count entry (for a screenshot).
exec function gmtest_ui10_open()
{
	theGame.RequestMenuWithBackground('GlossaryBestiaryMenu', 'CommonMenu');
}

exec function gmtest_ui10_select(optional tag : name)
{
	var menu : CR4GlossaryBestiaryMenu;

	if(tag == '')
		tag = 'KillCount';
	menu = (CR4GlossaryBestiaryMenu)((CR4MenuBase)theGame.GetGuiManager().GetRootMenu()).GetLastChild();
	if(menu)
		menu.OnEntrySelected(tag);
	LogChannel('GMTest', "INFO UI-10 bestiary menu found: " + (bool)menu);
}

// UI-13, UI-15 (in the regression): legacy's tutorial texts (English: the fast attack tutorial names
// <<AttackLight>>, 5.x's names <<AttackWithAlternateLight>>), the nine tips' rows, the razor's description.
function GMTest_ui13()
{
	var text : string;

	text = GetLocStringById(1075370);
	if(GetLocStringById(2110992520) != "" && StrFindFirst(GetLocStringById(2110992307), "Kill") >= 0)	// the English table
		GMTestReport(StrFindFirst(text, "<<AttackLight>>") >= 0 && StrFindFirst(text, "armor") >= 0, "UI-13 the fast attack tutorial is legacy's: " + StrLeft(text, 120));
	GMTestReport(GetLocStringById(2110992520) != "" && GetLocStringById(2110992528) != "", "UI-13 the tips' rows: '" + StrLeft(GetLocStringById(2110992520), 60) + "', '" + StrLeft(GetLocStringById(2110992528), 60) + "'");
}

function GMTest_ui15()
{
	GMTestReport(theGame.GetDefinitionsManager().GetItemLocalisationKeyDesc('Razor') == "item_desc_razor_mod" && GetLocStringByKeyExt("item_desc_razor_mod") == GetLocStringById(2110992173),
		"UI-15 the razor's description: '" + GetLocStringByKeyExt(theGame.GetDefinitionsManager().GetItemLocalisationKeyDesc('Razor')) + "'");
}

// UI-12 (two calls, the second a moment later): a hostile human 40 levels above Geralt shows its level
// in red ("highLevel"), not 5.x's "deadlyLevel".
exec function gmtest_ui12_a()
{
	GMTestDummySpawn("human", thePlayer.GetLevel() + 40, 4);
}

exec function gmtest_ui12_b()
{
	var npc : CNewNPC;
	var strLevel, kind : string;

	thePlayer.GMTestCount(true, true);
	npc = GMTestDummy();
	if(npc)
		kind = npc.GetExperienceDifferenceLevelName(strLevel);
	GMTestReport(npc && kind == "highLevel" && StrFindFirst(strLevel, "#FF1919") >= 0 && npc.GetLevel() - thePlayer.GetLevel() >= theGame.params.LEVEL_DIFF_DEADLY,
		"UI-12 an enemy " + (npc.GetLevel() - thePlayer.GetLevel()) + " levels above Geralt: " + kind + " '" + strLevel + "'");
	LogChannel('GMTest', "SUMMARY ui12: " + thePlayer.gmTestPassed + " passed, " + thePlayer.gmTestFailed + " failed");
}

// UI-15 (three calls): the beard grown, then the razor used (the inventory open or not), then Geralt's
// head read back.
exec function gmtest_ui15_a()
{
	var acs : array< CComponent >;

	acs = thePlayer.GetComponentsByClassName('CHeadManagerComponent');
	((CHeadManagerComponent)acs[0]).SetBeardStage(true);
}

@addField(W3PlayerWitcher)
var gmTestHeadBefore : name;

exec function gmtest_ui15_b()
{
	var acs : array< CComponent >;
	var w : W3PlayerWitcher;
	var menu : CR4InventoryMenu;

	w = GetWitcherPlayer();
	acs = thePlayer.GetComponentsByClassName('CHeadManagerComponent');
	w.gmTestHeadBefore = ((CHeadManagerComponent)acs[0]).GetCurHeadName();
	if((CR4MenuBase)theGame.GetGuiManager().GetRootMenu())
		menu = (CR4InventoryMenu)((CR4MenuBase)theGame.GetGuiManager().GetRootMenu()).GetLastChild();
	GMShaveGeralt(menu);
	LogChannel('GMTest', "INFO UI-15 head before: " + w.gmTestHeadBefore + ", inventory open: " + (bool)menu);
}

exec function gmtest_ui15_c()
{
	var acs : array< CComponent >;
	var head : name;

	thePlayer.GMTestCount(true, true);
	acs = thePlayer.GetComponentsByClassName('CHeadManagerComponent');
	head = ((CHeadManagerComponent)acs[0]).GetCurHeadName();
	GMTestReport(head != GetWitcherPlayer().gmTestHeadBefore, "UI-15 the razor shaved Geralt: " + GetWitcherPlayer().gmTestHeadBefore + " -> " + head);
	LogChannel('GMTest', "SUMMARY ui15: " + thePlayer.gmTestPassed + " passed, " + thePlayer.gmTestFailed + " failed");
}
