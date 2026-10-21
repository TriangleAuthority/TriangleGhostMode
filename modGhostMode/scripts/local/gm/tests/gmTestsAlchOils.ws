// ALCH-16 tests: oils.

// Regression: the data, the ogroid names, Hanged Man's Venom's tags.
function GMTest_alch16()
{
	var ids : array<SItemUniqueId>;
	var inv : CInventoryComponent;

	GMTestAlchCheck('BeastOil_1', 'vsBeast_attack_power', 0.25, "ALCH-16 oils +25% at every tier");
	GMTestAlchCheck('SpecterOil_3', 'vsSpecter_attack_power', 0.25, "ALCH-16 oils +25% at every tier");
	GMTestAlchCheck('NecrophageOil_1', 'vsNecrophage_critical_hit_chance', 0, "ALCH-16 no crit chance at tier 1");
	GMTestAlchCheck('NecrophageOil_2', 'vsNecrophage_critical_hit_chance', 0.05, "ALCH-16 crit chance from tier 2");
	GMTestAlchCheck('NecrophageOil_2', 'vsNecrophage_critical_hit_damage_bonus', 0, "ALCH-16 no crit damage at tier 2");
	GMTestAlchCheck('HangedManVenom_3', 'vsHuman_critical_hit_damage_bonus', 0.25, "ALCH-16 crit damage at tier 3");
	GMTestAlchCheck('VampireOil_3', 'vsVampire_resist_reduction', 0, "ALCH-16 no resistance reduction");
	GMTestAlchCheck('OgreOil_3', 'vsOgre_critical_hit_chance', 0.05, "ALCH-16 ogroid oil");
	GMTestAlchCheck('OgreOil_3', 'vsOgre_critical_hit_damage_bonus', 0.25, "ALCH-16 ogroid oil");
	GMTestReport(MonsterCategoryToCriticalChanceBonus(MC_Troll) == 'vsOgre_critical_hit_chance' && MonsterCategoryToCriticalDamageBonus(MC_Troll) == 'vsOgre_critical_hit_damage_bonus'
		&& MonsterCategoryToResistReduction(MC_Troll) == 'vsOgre_resist_reduction' && MonsterCategoryToAttackPowerBonus(MC_Troll) == 'vsOgre_attack_power',
		"ALCH-16 ogroids read the ogroid oil's vsOgre_ attributes");
	inv = thePlayer.inv;
	ids = inv.AddAnItem('Hanged Man Venom 2', 1);
	GMTestReport(inv.ItemHasTag(ids[0], 'SteelOil') && !inv.ItemHasTag(ids[0], 'SilverOil'), "ALCH-16 Hanged Man's Venom on steel swords only (DL9)");
	inv.RemoveItem(ids[0], 1);
}

exec function gmtest_alch16_regress()
{
	GMTest_alch16();
}

// A real oil application (W3PlayerWitcher.ApplyOil, the inventory's path) on the drawn steel or silver sword against
// the hostile test dummy (spawn it first, e.g. gmtest_dummy("troll") for an ogroid): Geralt's attack power,
// crit chance and crit damage bonus with and without the oil.
exec function gmtest_alch16(oilName : name, silver : bool, expCrit : float, expCritDmg : float)
{
	var w : W3PlayerWitcher;
	var npc : CNewNPC;
	var ids : array<SItemUniqueId>;
	var sword : SItemUniqueId;
	var cat : EMonsterCategory;
	var tmpName : name;
	var tmpBool, applied : bool;
	var ap0, ap1, cc0, cc1, cd0, cd1 : float;
	var cd : SAbilityAttributeValue;

	w = GetWitcherPlayer();
	npc = GMTestDummy();
	theGame.GetMonsterParamsForActor(npc, cat, tmpName, tmpBool, tmpBool, tmpBool);
	sword = w.GetEquippedSword(!silver);
	w.inv.RemoveAllOilsFromItem(sword);
	if(silver)
		w.OnEquipMeleeWeapon(PW_Silver, true);
	else
		w.OnEquipMeleeWeapon(PW_Steel, true);
	ap0 = GMTestOilAttackPower(npc);
	cc0 = w.GetCriticalHitChance(true, false, npc, cat, false);
	cd = w.GetCriticalHitDamageBonus(sword, cat, false);
	cd0 = cd.valueAdditive;
	ids = w.inv.AddAnItem(oilName, 1);
	applied = w.ApplyOil(ids[0], sword);
	ap1 = GMTestOilAttackPower(npc);
	cc1 = w.GetCriticalHitChance(true, false, npc, cat, false);
	cd = w.GetCriticalHitDamageBonus(sword, cat, false);
	cd1 = cd.valueAdditive;
	GMTestReport(applied && AbsF(ap1 - ap0 - 0.25) < 0.005 && AbsF(cc1 - cc0 - expCrit) < 0.005 && AbsF(cd1 - cd0 - expCritDmg) < 0.005,
		"ALCH-16 " + oilName + " (real application) against category " + cat + ": +" + RoundMath(100 * (ap1 - ap0)) + "% attack power, +" + RoundMath(100 * (cc1 - cc0)) + "% crit chance (expected "
		+ RoundMath(100 * expCrit) + "), +" + RoundMath(100 * (cd1 - cd0)) + "% crit damage (expected " + RoundMath(100 * expCritDmg) + ")");
	w.inv.RemoveAllOilsFromItem(sword);
}

// Hanged Man's Venom refused on the silver sword (DL9).
exec function gmtest_alch16_silver()
{
	var w : W3PlayerWitcher;
	var ids, swords : array<SItemUniqueId>;
	var silver : SItemUniqueId;
	var applied : bool;
	var oils : array<W3Effect_Oil>;

	w = GetWitcherPlayer();
	silver = w.GetEquippedSword(false);
	if(!w.inv.IsIdValid(silver))
	{
		swords = w.inv.AddAnItem('Silver sword 1', 1);
		w.EquipItem(swords[0]);
		silver = swords[0];
	}
	ids = w.inv.AddAnItem('Hanged Man Venom 3', 1);
	applied = w.ApplyOil(ids[0], silver);
	oils = w.inv.GetOilsAppliedOnItem(silver);
	GMTestReport(!applied && oils.Size() == 0, "ALCH-16 Hanged Man's Venom not applied to the silver sword (" + applied + ")");
	w.inv.RemoveAllOilsFromItem(silver);
}

// The stuck-oil fix: an oiled steel sword given to the test dummy's inventory arrives without the oil, and
// Geralt keeps no oil effect for it; taken back and equipped again.
exec function gmtest_alch16_transfer()
{
	var w : W3PlayerWitcher;
	var npc : CNewNPC;
	var ids, swords : array<SItemUniqueId>;
	var sword, moved, back : SItemUniqueId;
	var before, after, hadAbility : bool;
	var oils : array<W3Effect_Oil>;

	w = GetWitcherPlayer();
	npc = GMTestDummy();
	swords = w.inv.AddAnItem('Guard Lvl1 steel sword 1', 1);
	sword = swords[0];
	ids = w.inv.AddAnItem('Beast Oil 2', 1);
	w.ApplyOil(ids[0], sword);
	oils = w.inv.GetOilsAppliedOnItem(sword);
	before = oils.Size() > 0;
	hadAbility = w.inv.ItemHasAbility(sword, 'BeastOil_2');
	moved = w.inv.GiveItemTo(npc.GetInventory(), sword, 1, false, true);
	after = npc.GetInventory().ItemHasAbility(moved, 'BeastOil_2');
	GMTestReport(before && hadAbility && !after,
		"ALCH-16 an oiled sword (oil " + before + ", its ability on the item " + hadAbility + ") moved to another inventory arrives without the oil's ability (" + after + ")");
	back = npc.GetInventory().GiveItemTo(w.inv, moved, 1, false, true);
	w.inv.RemoveItem(back, 1);
}
