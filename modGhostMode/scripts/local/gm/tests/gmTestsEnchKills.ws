// In-game tests for ENCH's later slices: Invigoration (ENCH-05), Placation, Rejuvenation and Elation
// (ENCH-07, ENCH-08), Prolongation (ENCH-09), Preservation and Dumplings (ENCH-06), the enchanter
// (ENCH-02). See docs/features/ench.md.

// The steel sword's damage of one type, as hits read it.
function GMTestEnchSwordDamage(dmgType : name) : float
{
	var id : SItemUniqueId;

	if(!GetWitcherPlayer().GetItemEquippedOnSlot(EES_SteelSword, id))
		return 0;
	return GetWitcherPlayer().GetTotalWeaponDamage(id, dmgType, GetInvalidUniqueId());
}

// An ability's multiplier as its "max" (the words set only max).
function GMTestEnchAblMax(abilityName : name, attr : name) : float
{
	var min, max : SAbilityAttributeValue;

	theGame.GetDefinitionsManager().GetAbilityAttributeValue(abilityName, attr, min, max);
	return max.valueMultiplicative;
}

// ENCH-05 Invigoration, situation-free: the values, the description, the effect's bonus (2% per 1% of
// excess Vitality, capped at 50%), its HUD counter and its weapon damage multiplier (slashing only).
function GMTest_ench05()
{
	var w : W3PlayerWitcher;
	var ints : array<int>;
	var fl : array<float>;
	var strs : array<string>;
	var eff : W3GMEffect_Runeword4;
	var maxVit, slashBase, slashNow : float;

	w = GetWitcherPlayer();
	GMTestReport(GMTestArmNear(GMTestEnchAblMax('Runeword 4 _Stats', 'dmg_gain_rate'), 2) && GMTestArmNear(GMTestEnchAblMax('Runeword 4 _Stats', 'max_bonus'), 0.5),
		"ENCH-05 Invigoration: gain rate " + GMTestEnchAblMax('Runeword 4 _Stats', 'dmg_gain_rate') + ", max " + GMTestEnchAblMax('Runeword 4 _Stats', 'max_bonus') + " (expected 2, 0.5)");
	w.GetInventory().GetParamsForRunewordTooltip('Runeword 4', ints, fl, strs);
	GMTestReport(ints.Size() == 2 && ints[0] == 2 && ints[1] == 50, "ENCH-05: Invigoration's description values " + ints[0] + "%, " + ints[1] + "%");
	GMTestReport(EffectTypeToName(EET_GMRuneword4) == 'GMRuneword4Effect', "ENCH-05: the effect type is registered");

	w.RemoveBuff(EET_GMRuneword4);
	slashBase = GMTestEnchSwordDamage('SlashingDamage');
	w.AddEffectDefault(EET_GMRuneword4, NULL, "test");
	eff = (W3GMEffect_Runeword4)w.GetBuff(EET_GMRuneword4);
	GMTestReport(eff, "ENCH-05: the effect can be added");
	if(!eff)
		return;
	maxVit = w.GetStatMax(BCS_Vitality);
	eff.IncOverhealBonus(maxVit * 0.1);
	GMTestReport(GMTestArmNear(w.GMInvigorationBonus(), 0.2) && eff.GetStacks() == 20 && eff.GetMaxStacks() == 100, "ENCH-05: 10% excess Vitality gives +" + w.GMInvigorationBonus() + " weapon damage (expected 0.2), HUD " + eff.GetStacks() + "/" + eff.GetMaxStacks());
	slashNow = GMTestEnchSwordDamage('SlashingDamage');
	GMTestReport(slashBase > 0 && GMTestArmNear(slashNow / slashBase, 1.2), "ENCH-05: steel sword slashing damage " + slashBase + " -> " + slashNow + " (expected x1.2)");
	eff.IncOverhealBonus(maxVit);
	GMTestReport(GMTestArmNear(w.GMInvigorationBonus(), 0.5) && eff.GetStacks() == 50, "ENCH-05: the bonus is capped at +" + w.GMInvigorationBonus() + " (expected 0.5)");
	w.RemoveBuff(EET_GMRuneword4);
	GMTestReport(!w.HasBuff(EET_GMRuneword4) && GMTestArmNear(GMTestEnchSwordDamage('SlashingDamage'), slashBase), "ENCH-05: removed, the sword's damage is back to " + GMTestEnchSwordDamage('SlashingDamage'));
}

// ENCH-05 in play, with the hostile test dummy (spawn it first: gmtest_dummy("human") and
// gmtest_dummy_neutral(); Geralt in combat). (a) enchants the steel sword, sheathes it, Vitality full:
// overheal builds nothing while sheathed; then draw the sword (gmtest_draw(), in combat). (b) drawn: Vitality gained past the
// maximum (GainStat, as regeneration and healing call it) builds the bonus, the FX plays; a scripted
// light hit on the dummy spends it; built again, a Vitality loss ends it; built again, the end of
// combat ends it. (c) after a few seconds at full Vitality with the sword drawn: regeneration keeps
// running (5.x stops it at the maximum without the runeword); removes the enchantment.
exec function gmtest_ench05_a()
{
	var w : W3PlayerWitcher;

	w = GetWitcherPlayer();
	w.RemoveBuff(EET_GMRuneword4);
	GMTestEnchant(EES_SteelSword, 'Runeword 4');
	w.OnEquipMeleeWeapon(PW_None, true);
	w.ForceSetStat(BCS_Vitality, w.GetStatMax(BCS_Vitality));
	w.GainStat(BCS_Vitality, w.GetStatMax(BCS_Vitality) * 0.1);
	GMTestReport(!w.HasBuff(EET_GMRuneword4), "ENCH-05: overheal with the sword sheathed builds nothing (in combat " + w.IsInCombat() + ")");
}

exec function gmtest_ench05_b()
{
	var w : W3PlayerWitcher;
	var npc : CActor;
	var maxVit : float;

	w = GetWitcherPlayer();
	npc = GMTestHostileNpc();
	maxVit = w.GetStatMax(BCS_Vitality);
	w.ForceSetStat(BCS_Vitality, maxVit);
	w.GainStat(BCS_Vitality, maxVit * 0.1);
	GMTestReport(GMTestEnchHeld(EES_SteelSword) && w.IsInCombat() && AbsF(w.GMInvigorationBonus() - 0.2) < 0.02, "ENCH-05: drawn (" + GMTestEnchHeld(EES_SteelSword) + "), in combat (" + w.IsInCombat() + "), 10% overheal gives +" + w.GMInvigorationBonus() + " (expected 0.2, real regen may add a little), FX " + w.IsEffectActive('runeword_4', true));
	if(npc)
	{
		GMTestDmgHit(thePlayer, npc, thePlayer.GetInventory().GetItemFromSlot('r_weapon'), 'attack_light');
		GMTestReport(!w.HasBuff(EET_GMRuneword4), "ENCH-05: a damaging sword hit spends the bonus");
	}
	w.GainStat(BCS_Vitality, maxVit * 0.05);
	GMTestReport(GMTestArmNear(w.GMInvigorationBonus(), 0.1), "ENCH-05: built again, +" + w.GMInvigorationBonus() + " (expected 0.1)");
	w.DrainVitality(1);
	GMTestReport(!w.HasBuff(EET_GMRuneword4), "ENCH-05: a Vitality loss ends the bonus");
	w.ForceSetStat(BCS_Vitality, maxVit);
	w.GainStat(BCS_Vitality, maxVit * 0.05);
	w.OnCombatFinished();
	GMTestReport(!w.HasBuff(EET_GMRuneword4), "ENCH-05: the end of combat ends the bonus");
	w.ForceSetStat(BCS_Vitality, maxVit);
}

exec function gmtest_ench05_c()
{
	var w : W3PlayerWitcher;

	w = GetWitcherPlayer();
	GMTestReport(GMTestEnchHeld(EES_SteelSword) && w.HasBuff(EET_AutoVitalityRegen), "ENCH-05: at full Vitality with the runeword drawn, regeneration keeps running (bonus +" + w.GMInvigorationBonus() + ", in combat " + w.IsInCombat() + ")");
	w.OnEquipMeleeWeapon(PW_None, true);
}

exec function gmtest_ench05_d()
{
	var w : W3PlayerWitcher;

	w = GetWitcherPlayer();
	GMTestReport(!GMTestEnchHeld(EES_SteelSword) && !w.HasBuff(EET_AutoVitalityRegen), "ENCH-05: at full Vitality with the runeword sheathed, regeneration stops");
	w.RemoveBuff(EET_GMRuneword4);
	GMTestEnchant(EES_SteelSword, '');
}

// ENCH-05, a real Sign hit (the changelist's rule, the owner's decision): with Conductors of Magic a
// damaging Sign hit spends the bonus, without it the bonus stays. After gmtest_dummy("human") and
// gmtest_dummy_neutral(): (a) a witcher steel sword (Conductors of Magic needs one) enchanted with
// Invigoration and drawn, Conductors of Magic equipped (on) or no mutation; (build) a moment later, the
// sword held: the bonus built (+20%); then cast Igni at the dummy (autocast(ST_Igni)); (b) a moment
// later: spent (on) or kept (off).
exec function gmtest_ench05_sign_a(on : bool)
{
	var w : W3PlayerWitcher;
	var ids : array<SItemUniqueId>;

	w = GetWitcherPlayer();
	ids = w.inv.GetItemsByName('Viper School steel sword');
	if(ids.Size() == 0)
		ids = w.inv.AddAnItem('Viper School steel sword', 1);
	w.EquipItem(ids[0]);
	if(on)
		GMTestPam().DEBUG_DevelopAndEquipMutation(EPMT_Mutation1);
	else
		GMTestPam().DEBUG_SetEquippedMutation(EPMT_None);
	GMTestEnchant(EES_SteelSword, 'Runeword 4');
	w.OnEquipMeleeWeapon(PW_Steel, true);
}

@addField(CR4Player)
public var gmTestEnch05Vit : float;

@addMethod(CR4Player)
function GMTestSetEnch05Vit(v : float)
{
	gmTestEnch05Vit = v;
}

exec function gmtest_ench05_sign_build()
{
	var w : W3PlayerWitcher;

	w = GetWitcherPlayer();
	thePlayer.GMTestSetEnch05Vit(GMTestHostileNpc().GetStat(BCS_Vitality));
	w.GainStat(BCS_Stamina, 1000);
	w.RemoveBuff(EET_GMRuneword4);
	w.ForceSetStat(BCS_Vitality, w.GetStatMax(BCS_Vitality));
	w.GainStat(BCS_Vitality, w.GetStatMax(BCS_Vitality) * 0.1);
	w.StopVitalityRegen();	// regeneration at the maximum would build a spent bonus again
	GMTestReport(w.HasBuff(EET_GMRuneword4), "ENCH-05: the bonus built for the Sign test (+" + w.GMInvigorationBonus() + ", Conductors of Magic " + w.IsMutationActive(EPMT_Mutation1) + ", in combat " + w.IsInCombat() + ", sword held " + GMTestEnchHeld(EES_SteelSword) + ")");
}

exec function gmtest_ench05_sign_b(on : bool)
{
	var w : W3PlayerWitcher;
	var npc : CActor;

	w = GetWitcherPlayer();
	npc = GMTestHostileNpc();
	// spent: the effect gone, or (if regeneration started again) built anew below the +20% it had
	if(on)
		GMTestReport(npc.GetStat(BCS_Vitality) < thePlayer.gmTestEnch05Vit && (!w.HasBuff(EET_GMRuneword4) || w.GMInvigorationBonus() < 0.19), "ENCH-05: an Igni hit with Conductors of Magic spent the bonus (now +" + w.GMInvigorationBonus() + ", regen running " + w.HasBuff(EET_AutoVitalityRegen) + ", the dummy's Vitality " + thePlayer.gmTestEnch05Vit + " -> " + npc.GetStat(BCS_Vitality) + ")");
	else
		GMTestReport(npc.GetStat(BCS_Vitality) < thePlayer.gmTestEnch05Vit && w.HasBuff(EET_GMRuneword4) && w.GMInvigorationBonus() >= 0.19, "ENCH-05: an Igni hit without Conductors of Magic left the bonus (+" + w.GMInvigorationBonus() + ", regen running " + w.HasBuff(EET_AutoVitalityRegen) + ", the dummy's Vitality " + thePlayer.gmTestEnch05Vit + " -> " + npc.GetStat(BCS_Vitality) + ")");
	w.RemoveBuff(EET_GMRuneword4);
	GMTestEnchant(EES_SteelSword, '');
	GMTestPam().DEBUG_SetEquippedMutation(EPMT_None);
}

// ENCH-14, real Axii casts (the changelist's rule, the owner's decision): gmtest_ench14_real(word) puts
// Beguilement on the chest armor or nothing and clears the stacks; cast Axii at the neutral test dummy
// (autocast(ST_Axii)); gmtest_ench14_count(word): at the cast's end, one Beguilement stack with the word,
// none without.
exec function gmtest_ench14_real(word : bool)
{
	var w : W3PlayerWitcher;
	var npc : CActor;

	w = GetWitcherPlayer();
	npc = GMTestHostileNpc();
	if(npc)
	{
		npc.RemoveAllBuffsOfType(EET_Confusion);
		npc.RemoveAllBuffsOfType(EET_AxiiGuardMe);
	}
	w.RemoveAbilityAll('Glyphword 14 abl');
	w.RemoveAbilityAll('Glyphword 10 abl');
	if(word)
		GMTestEnchant(EES_Armor, 'Glyphword 14');
	else
		GMTestEnchant(EES_Armor, '');
	w.GainStat(BCS_Stamina, 1000);
	thePlayer.GMTestSetAxiiEnd("");
	LogChannel('GMTest', "INFO ENCH-14: Beguilement on the chest armor " + w.HasGlyphwordActive('Glyphword 14 _Stats'));
}

exec function gmtest_ench14_count(word : bool)
{
	var w : W3PlayerWitcher;
	var npc : CActor;
	var expected : string;

	w = GetWitcherPlayer();
	npc = GMTestHostileNpc();
	// read when the cast ended (the test probe on W3AxiiEntity.OnEnded): the dummy's forced hostility ends
	// the confusion within about 1.5 s
	if(word)
		expected = "confused true, Beguilement stacks 1, Usurpation stacks 0";
	else
		expected = "confused true, Beguilement stacks 0, Usurpation stacks 0";
	GMTestReport(thePlayer.gmTestAxiiEnd == expected, "ENCH-14: a real Axii cast, word " + word + ", at the cast's end: " + thePlayer.gmTestAxiiEnd + " (expected " + expected + ")");
	// the stack's removal with the effect is gmtest_ench14_stacks' check: a real confusion on the frozen
	// dummy can outlast its duration and survive RemoveAllBuffsOfType (docs/game-automation.md)
	if(npc)
		npc.RemoveAllBuffsOfType(EET_Confusion);
	w.RemoveAbilityAll('Glyphword 14 abl');
	GMTestEnchant(EES_Armor, '');
}

// ENCH-07, ENCH-08, situation-free: legacy's values and the descriptions.
function GMTest_ench07_08()
{
	var w : W3PlayerWitcher;
	var ints : array<int>;
	var fl : array<float>;
	var strs : array<string>;

	w = GetWitcherPlayer();
	GMTestReport(GMTestArmNear(GMTestArmAblMult('Runeword 8 Regen', 'focus_drain'), 0.3) && GMTestArmNear(GMTestArmAblMult('Runeword 8 Regen', 'vitalityCombatRegen'), 0.05)
		&& GMTestArmNear(GMTestArmAblMult('Runeword 8 Regen', 'staminaRegen'), 0.05) && GMTestArmNear(GMTestArmAbl('Runeword 8 Regen', 'toxicityRegen'), -5),
		"ENCH-07 Placation: drain " + GMTestArmAblMult('Runeword 8 Regen', 'focus_drain') + "/s, Vitality and stamina regen +" + GMTestArmAblMult('Runeword 8 Regen', 'staminaRegen') + ", toxicity " + GMTestArmAbl('Runeword 8 Regen', 'toxicityRegen') + " (expected 0.3, 0.05, -5)");
	GMTestReport(GMTestArmNear(GMTestArmAblMult('Runeword 10 _Stats', 'health'), 0.15) && GMTestArmAblMult('Runeword 10 _Stats', 'stamina_runeword_gain') == 0, "ENCH-08 Rejuvenation: heals " + GMTestArmAblMult('Runeword 10 _Stats', 'health') + " of Vitality (expected 0.15), 5.x's stamina gain gone");
	GMTestReport(GMTestArmNear(GMTestArmAbl('Runeword 12 _Stats', 'focus'), 0.25) && GMTestArmAbl('Runeword 12 _Stats', 'focus_runeword_gain') == 0, "ENCH-08 Elation: " + GMTestArmAbl('Runeword 12 _Stats', 'focus') + " adrenaline per kill (expected 0.25), 5.x's gain gone");
	w.GetInventory().GetParamsForRunewordTooltip('Runeword 8', ints, fl, strs);
	GMTestReport(strs.Size() == 4 && strs[0] == "0.3" && strs[1] == "5" && strs[2] == "5" && strs[3] == "5" && StrFindFirst(GetLocStringById(2110992386), "decline") >= 0, "ENCH-07: Placation's description values " + strs[0] + ", " + strs[1] + "%, " + strs[2] + "%, " + strs[3]);
	w.GetInventory().GetParamsForRunewordTooltip('Runeword 10', ints, fl, strs);
	GMTestReport(ints.Size() == 1 && ints[0] == 15 && StrFindFirst(GetLocStringById(2110992294), "heals") >= 0, "ENCH-08: Rejuvenation's description value " + ints[0] + "%");
	w.GetInventory().GetParamsForRunewordTooltip('Runeword 12', ints, fl, strs);
	GMTestReport(fl.Size() == 1 && GMTestArmNear(fl[0], 0.25), "ENCH-08: Elation's description value " + fl[0]);
}

@addField(W3PlayerWitcher)
var gmTestEnchT0 : float;
@addField(W3PlayerWitcher)
var gmTestEnchF0 : float;

@addMethod(W3PlayerWitcher)
function GMTestEnchMark()
{
	gmTestEnchT0 = theGame.GetEngineTimeAsSeconds();
	gmTestEnchF0 = GetStat(BCS_Focus);
}

// ENCH-07 Placation, out of combat: (a) enchants the steel sword, sheathed: maximum adrenaline starts
// nothing; draws the sword. (b) drawn: maximum adrenaline starts Placation (its regen ability on
// Geralt); adrenaline gains are refused while it drains. (c) a few seconds later: adrenaline fell by
// 0.3/s; the after-combat drain is not running; leaves 0.1. (d) a second later: drained to zero, ended.
exec function gmtest_ench07_a()
{
	var w : W3PlayerWitcher;

	w = GetWitcherPlayer();
	w.RemoveBuff(EET_Runeword8);
	GMTestEnchant(EES_SteelSword, 'Runeword 8');
	w.OnEquipMeleeWeapon(PW_None, true);
	w.ForceSetStat(BCS_Focus, 0);
	w.ForceSetStat(BCS_Focus, w.GetStatMax(BCS_Focus));
	GMTestReport(!w.HasBuff(EET_Runeword8), "ENCH-07: maximum adrenaline with the sword sheathed starts nothing");
	w.ForceSetStat(BCS_Focus, 0);
	w.OnEquipMeleeWeapon(PW_Steel, true);
}

exec function gmtest_ench07_b()
{
	var w : W3PlayerWitcher;
	var before : float;

	w = GetWitcherPlayer();
	w.ForceSetStat(BCS_Focus, w.GetStatMax(BCS_Focus));
	GMTestReport(GMTestEnchHeld(EES_SteelSword) && w.HasBuff(EET_Runeword8) && w.HasAbility('Runeword 8 Regen'), "ENCH-07: drawn, maximum adrenaline starts Placation (in combat " + w.IsInCombat() + ")");
	w.DrainFocus(0.5);
	before = w.GetStat(BCS_Focus);
	w.GainStat(BCS_Focus, 0.4);
	GMTestReport(w.GetStat(BCS_Focus) == before, "ENCH-07: no adrenaline gained while it drains (" + before + " -> " + w.GetStat(BCS_Focus) + ")");
	w.GMTestEnchMark();
}

exec function gmtest_ench07_c()
{
	var w : W3PlayerWitcher;
	var dt, rate : float;

	w = GetWitcherPlayer();
	dt = theGame.GetEngineTimeAsSeconds() - w.gmTestEnchT0;
	rate = (w.gmTestEnchF0 - w.GetStat(BCS_Focus)) / dt;
	GMTestReport(AbsF(rate - 0.3) < 0.05 && w.HasBuff(EET_Runeword8) && !w.HasBuff(EET_AdrenalineDrain), "ENCH-07: adrenaline fell " + (w.gmTestEnchF0 - w.GetStat(BCS_Focus)) + " in " + dt + " s (" + rate + "/s, expected 0.3), the after-combat drain off (" + w.HasBuff(EET_AdrenalineDrain) + ")");
	w.ForceSetStat(BCS_Focus, 0.1);
}

// (d) a second later: adrenaline drained to zero, Placation ended; removes the enchantment.
exec function gmtest_ench07_d()
{
	var w : W3PlayerWitcher;

	w = GetWitcherPlayer();
	GMTestReport(w.GetStat(BCS_Focus) == 0 && !w.HasBuff(EET_Runeword8) && !w.HasAbility('Runeword 8 Regen'), "ENCH-07: drained to zero, Placation ends");
	w.OnEquipMeleeWeapon(PW_None, true);
	GMTestEnchant(EES_SteelSword, '');
}

// Kills the hostile test dummy with a scripted light sword hit (its Vitality set to 1 first).
function GMTestEnchKillDummy() : bool
{
	var npc : CActor;

	npc = GMTestHostileNpc();
	if(!npc)
		return false;
	npc.ForceSetStat(BCS_Vitality, 1);
	GMTestDmgHit(thePlayer, npc, thePlayer.GetInventory().GetItemFromSlot('r_weapon'), 'attack_light');
	return !npc.IsAlive();
}

// ENCH-08, a kill by a scripted sword hit (spawn a test dummy for each kill: gmtest_dummy("human")):
// (a) Rejuvenation on the drawn steel sword, Vitality at 50%: the kill heals 15% once (5.x's trigger in
// ProcessAction gone); stamina untouched. (b) Elation on it: a kill (CActor.Kill by Geralt, so no adrenaline from a hit) gives 0.25 adrenaline once.
// Draw the steel sword before (gmtest_draw()).
exec function gmtest_ench08_a()
{
	var w : W3PlayerWitcher;
	var vit, maxVit, stam : float;

	w = GetWitcherPlayer();
	GMTestEnchant(EES_SteelSword, 'Runeword 10');
	maxVit = w.GetStatMax(BCS_Vitality);
	w.ForceSetStat(BCS_Vitality, maxVit * 0.5);
	w.ForceSetStat(BCS_Stamina, w.GetStatMax(BCS_Stamina) * 0.5);
	vit = w.GetStat(BCS_Vitality);
	stam = w.GetStat(BCS_Stamina);
	GMTestReport(GMTestEnchKillDummy(), "ENCH-08: the dummy killed by a sword hit (drawn " + GMTestEnchHeld(EES_SteelSword) + ")");
	GMTestReport(AbsF((w.GetStat(BCS_Vitality) - vit) / maxVit - 0.15) < 0.01 && w.GetStat(BCS_Stamina) <= stam + 1, "ENCH-08 Rejuvenation: the kill healed " + ((w.GetStat(BCS_Vitality) - vit) / maxVit) + " of Vitality (expected 0.15, once), stamina " + stam + " -> " + w.GetStat(BCS_Stamina));
	w.ForceSetStat(BCS_Vitality, maxVit);
	GMTestEnchant(EES_SteelSword, '');
}

exec function gmtest_ench08_b()
{
	var w : W3PlayerWitcher;
	var npc : CActor;

	w = GetWitcherPlayer();
	GMTestEnchant(EES_SteelSword, 'Runeword 12');
	w.ForceSetStat(BCS_Focus, 0);
	npc = GMTestHostileNpc();
	if(npc)
		npc.Kill('Kill', true, thePlayer);
	GMTestReport(npc && !npc.IsAlive() && AbsF(w.GetStat(BCS_Focus) - 0.25) < 0.01, "ENCH-08 Elation: a kill by Geralt (Kill, no hit's own gain) gave " + w.GetStat(BCS_Focus) + " adrenaline (expected 0.25, once)");
	GMTestEnchant(EES_SteelSword, '');
}

// ENCH-09 Prolongation, situation-free: the values, the description, 5.x's per-hit 'duration' gone,
// the effect's bonus (0.5% slower per 1% of excess adrenaline, max 50%) and its HUD counter.
function GMTest_ench09()
{
	var w : W3PlayerWitcher;
	var ints : array<int>;
	var fl : array<float>;
	var strs : array<string>;
	var eff : W3GMEffect_Runeword11;

	w = GetWitcherPlayer();
	GMTestReport(GMTestArmNear(GMTestEnchAblMax('Runeword 11 _Stats', 'duration_gain_rate'), 0.5) && GMTestArmNear(GMTestEnchAblMax('Runeword 11 _Stats', 'max_bonus'), 0.5) && GMTestArmAbl('Runeword 11 _Stats', 'duration') == 0,
		"ENCH-09 Prolongation: rate " + GMTestEnchAblMax('Runeword 11 _Stats', 'duration_gain_rate') + ", max " + GMTestEnchAblMax('Runeword 11 _Stats', 'max_bonus') + " (expected 0.5, 0.5), 5.x's +1 s per hit gone (" + GMTestArmAbl('Runeword 11 _Stats', 'duration') + ")");
	w.GetInventory().GetParamsForRunewordTooltip('Runeword 11', ints, fl, strs);
	GMTestReport(strs.Size() == 2 && strs[0] == "0.5" && strs[1] == "50" && StrFindFirst(GetLocStringById(2110992507), "potion") >= 0, "ENCH-09: Prolongation's description values " + strs[0] + "%, " + strs[1] + "%");
	GMTestReport(EffectTypeToName(EET_GMRuneword11) == 'GMRuneword11Effect', "ENCH-09: the effect type is registered");
	w.RemoveBuff(EET_GMRuneword11);
	w.AddEffectDefault(EET_GMRuneword11, NULL, "test");
	eff = (W3GMEffect_Runeword11)w.GetBuff(EET_GMRuneword11);
	GMTestReport(eff, "ENCH-09: the effect can be added");
	if(!eff)
		return;
	eff.IncBonusAdrenaline(1.5);
	GMTestReport(GMTestArmNear(w.GMProlongationBonus(), 0.25) && eff.GetStacks() == 25, "ENCH-09: 1.5 points of excess adrenaline slow potion timers by " + w.GMProlongationBonus() + " (expected 0.25), HUD " + eff.GetStacks());
	eff.IncBonusAdrenaline(10);
	GMTestReport(GMTestArmNear(w.GMProlongationBonus(), 0.5), "ENCH-09: capped at " + w.GMProlongationBonus() + " (expected 0.5)");
	w.RemoveBuff(EET_GMRuneword11);
	GMTestReport(w.GMProlongationBonus() == 0, "ENCH-09: removed, no bonus");
}

@addField(W3PlayerWitcher)
var gmTestEnchP0 : float;
@addField(W3PlayerWitcher)
var gmTestEnchD0 : float;

@addMethod(W3PlayerWitcher)
function GMTestEnchMarkBuffs(p, d : float)
{
	gmTestEnchT0 = theGame.GetEngineTimeAsSeconds();
	gmTestEnchP0 = p;
	gmTestEnchD0 = d;
}

// ENCH-09 in play, in combat with the hostile test dummy (spawn it first) and the steel sword drawn
// (gmtest_draw() after (a)): (a) enchants the steel sword. (b) at maximum adrenaline, 0.6 more gained
// builds a 10% bonus; a potion (Cat) and a decoction (Mutagen 1) are drunk. (c) a few seconds later: the
// potion's timer ran at x0.9, the decoction's at x1; an adrenaline loss ends the bonus; built again,
// the end of combat ends it; removes the enchantment.
// Drinks the named potion or decoction (added if missing), toxicity cleared first.
function GMTestEnchDrink(itemName : name)
{
	var w : W3PlayerWitcher;
	var ids : array<SItemUniqueId>;

	w = GetWitcherPlayer();
	ids = w.inv.GetItemsByName(itemName);
	if(ids.Size() == 0)
		ids = w.inv.AddAnItem(itemName, 1);
	w.DrainToxicity(w.GetStat(BCS_Toxicity));
	w.DrinkPreparedPotion(EES_InvalidSlot, ids[0]);
	w.DrainToxicity(w.GetStat(BCS_Toxicity));
}

exec function gmtest_ench09_a()
{
	GetWitcherPlayer().RemoveBuff(EET_GMRuneword11);
	GMTestEnchant(EES_SteelSword, 'Runeword 11');
}

exec function gmtest_ench09_b()
{
	var w : W3PlayerWitcher;
	var p, d : CBaseGameplayEffect;

	w = GetWitcherPlayer();
	w.ForceSetStat(BCS_Focus, w.GetStatMax(BCS_Focus));
	w.GainStat(BCS_Focus, 0.6);
	GMTestReport(GMTestEnchHeld(EES_SteelSword) && w.IsInCombat() && GMTestArmNear(w.GMProlongationBonus(), 0.1), "ENCH-09: drawn (" + GMTestEnchHeld(EES_SteelSword) + "), in combat (" + w.IsInCombat() + "), 0.6 excess adrenaline: potion timers slowed by " + w.GMProlongationBonus() + " (expected 0.1)");
	w.RemoveBuff(EET_Cat);
	w.RemoveBuff(EET_Mutagen01);
	GMTestEnchDrink('Cat 1');
	GMTestEnchDrink('Mutagen 1');
	p = w.GetBuff(EET_Cat);
	d = w.GetBuff(EET_Mutagen01);
	GMTestReport(p && d && p.IsPotionEffect(), "ENCH-09: a potion (" + p.GetTimeLeft() + " s) and a decoction (" + d.GetTimeLeft() + " s) added");
	if(p && d)
		w.GMTestEnchMarkBuffs(p.GetTimeLeft(), d.GetTimeLeft());
}

exec function gmtest_ench09_c()
{
	var w : W3PlayerWitcher;
	var p, d : CBaseGameplayEffect;
	var dt, rp, rd : float;

	w = GetWitcherPlayer();
	p = w.GetBuff(EET_Cat);
	d = w.GetBuff(EET_Mutagen01);
	dt = theGame.GetEngineTimeAsSeconds() - w.gmTestEnchT0;
	if(p && d)
	{
		rp = (w.gmTestEnchP0 - p.GetTimeLeft()) / dt;
		rd = (w.gmTestEnchD0 - d.GetTimeLeft()) / dt;
	}
	GMTestReport(AbsF(rp - 0.9) < 0.04 && AbsF(rd - 1) < 0.04, "ENCH-09: over " + dt + " s the potion's timer ran at x" + rp + " (expected 0.9), the decoction's at x" + rd + " (expected 1)");
	w.DrainFocus(0.1);
	GMTestReport(!w.HasBuff(EET_GMRuneword11), "ENCH-09: losing adrenaline ends the bonus");
	w.ForceSetStat(BCS_Focus, w.GetStatMax(BCS_Focus));
	w.GainStat(BCS_Focus, 0.3);
	w.OnCombatFinished();
	GMTestReport(!w.HasBuff(EET_GMRuneword11), "ENCH-09: the end of combat ends the bonus");
	w.RemoveBuff(EET_Cat);
	w.RemoveBuff(EET_Mutagen01);
	GMTestEnchant(EES_SteelSword, '');
}

// ENCH-06, situation-free: Dumplings' value and description.
function GMTest_ench06()
{
	var w : W3PlayerWitcher;
	var ints : array<int>;
	var fl : array<float>;
	var strs : array<string>;

	w = GetWitcherPlayer();
	GMTestReport(GMTestArmNear(GMTestArmAblMult('Runeword 6 _Stats', 'runeword6_duration_bonus'), 1), "ENCH-06 Dumplings: edibles last +" + GMTestArmAblMult('Runeword 6 _Stats', 'runeword6_duration_bonus') + " (expected 1; 5.x 4)");
	w.GetInventory().GetParamsForRunewordTooltip('Runeword 6', ints, fl, strs);
	GMTestReport(ints.Size() == 1 && ints[0] == 100 && StrFindFirst(GetLocStringById(2110992159), "pierogi") >= 0, "ENCH-06: Dumplings' description value " + ints[0] + "%");
	GMTest_ench06_drink();
}

// Applies Well Hydrated (level 1, 15 s) to Geralt as a drink would and returns it. In the port no item
// applies it yet: 5.x's drinks give Well Fed; legacy's drinks give Well Hydrated (FOOD).
function GMTestEnchDrinkWater() : CBaseGameplayEffect
{
	var w : W3PlayerWitcher;

	w = GetWitcherPlayer();
	w.RemoveAllBuffsOfType(EET_WellHydrated);
	w.AddEffectDefault(EET_WellHydrated, w, "gmtest");
	return w.GetBuff(EET_WellHydrated);
}

// ENCH-06, audit F4: Well Hydrated (drinks, legacy) lasts +100% with Dumplings, also with the word on both swords (5.x: +200%,
// the attribute summed over both swords). Enchants both equipped swords and removes the words afterwards.
function GMTest_ench06_drink()
{
	var w : W3PlayerWitcher;
	var e : CBaseGameplayEffect;
	var d0, d1, d2 : float;
	var ok : bool;

	w = GetWitcherPlayer();
	GMTestEnchant(EES_SilverSword, '');
	GMTestEnchant(EES_SteelSword, '');
	e = GMTestEnchDrinkWater();
	if(e)
		d0 = e.GetTimeLeft();
	ok = GMTestEnchant(EES_SilverSword, 'Runeword 6');
	e = GMTestEnchDrinkWater();
	if(e)
		d1 = e.GetTimeLeft();
	ok = GMTestEnchant(EES_SteelSword, 'Runeword 6') && ok;
	e = GMTestEnchDrinkWater();
	if(e)
		d2 = e.GetTimeLeft();
	GMTestReport(ok && d0 > 0 && AbsF(d1 / d0 - 2) < 0.02 && AbsF(d2 / d0 - 2) < 0.02, "ENCH-06 Dumplings on drinks: Well Hydrated lasts " + d0 + " s, " + d1 + " s with Dumplings on one sword, " + d2 + " s on both (expected x2 and x2; 5.x x3 on both; swords enchanted " + ok + ")");
	w.RemoveAllBuffsOfType(EET_WellHydrated);
	GMTestEnchant(EES_SilverSword, '');
	GMTestEnchant(EES_SteelSword, '');
}

// Eats one Bread (added if missing) and returns its Well Fed effect.
function GMTestEnchEat() : CBaseGameplayEffect
{
	var w : W3PlayerWitcher;
	var ids : array<SItemUniqueId>;

	w = GetWitcherPlayer();
	w.RemoveAllBuffsOfType(EET_WellFed);
	ids = w.inv.GetItemsByName('Bread');
	if(ids.Size() == 0)
		ids = w.inv.AddAnItem('Bread', 1);
	w.ConsumeItem(ids[0]);
	return w.GetBuff(EET_WellFed);
}

// ENCH-06 in play, out of combat, swords sheathed. Dumplings: a Bread's Well Fed lasts twice as long
// with Dumplings on the (sheathed) silver sword, its regeneration unchanged. Preservation (on the
// sheathed steel sword): the grindstone buff removed is applied again; without it, it stays removed.
exec function gmtest_ench06()
{
	var w : W3PlayerWitcher;
	var e : CBaseGameplayEffect;
	var d0, d1, v0, v1 : float;
	var ev : SAbilityAttributeValue;

	w = GetWitcherPlayer();
	w.OnEquipMeleeWeapon(PW_None, true);
	GMTestEnchant(EES_SilverSword, '');
	e = GMTestEnchEat();
	if(e)
	{
		d0 = e.GetTimeLeft();
		ev = e.GetEffectValue();
		v0 = ev.valueAdditive + ev.valueMultiplicative;
	}
	GMTestEnchant(EES_SilverSword, 'Runeword 6');
	e = GMTestEnchEat();
	if(e)
	{
		d1 = e.GetTimeLeft();
		ev = e.GetEffectValue();
		v1 = ev.valueAdditive + ev.valueMultiplicative;
	}
	GMTestReport(d0 > 0 && AbsF(d1 / d0 - 2) < 0.02 && GMTestArmNear(v1, v0), "ENCH-06 Dumplings (active " + w.HasRunewordActive('Runeword 6 _Stats') + "): Well Fed lasts " + d0 + " -> " + d1 + " s (expected x2) from the sheathed silver sword, regeneration " + v0 + " -> " + v1 + " (unchanged)");
	w.RemoveAllBuffsOfType(EET_WellFed);
	GMTestEnchant(EES_SilverSword, '');

	GMTestEnchant(EES_SteelSword, 'Runeword 5');
	w.AddEffectDefault(EET_EnhancedWeapon, w, "repair_object", false);
	w.RemoveBuff(EET_EnhancedWeapon);
	GMTestReport(w.HasBuff(EET_EnhancedWeapon), "ENCH-06 Preservation: the grindstone buff removed is applied again");
	GMTestEnchant(EES_SteelSword, '');
	w.RemoveBuff(EET_EnhancedWeapon);
	GMTestReport(!w.HasBuff(EET_EnhancedWeapon), "ENCH-06: without Preservation it stays removed");
}

// ENCH-02, situation-free: legacy's schematics are read before the vanilla ones (by name, and by the
// enchanting menu's manager for every word, once each).
function GMTest_ench02()
{
	var s : SEnchantmentSchematic;
	var mgr : W3EnchantmentManager;
	var names : array<name>;
	var dm : CDefinitionsManagerAccessor;
	var main : SCustomNode;
	var ok : bool;

	dm = theGame.GetDefinitionsManager();
	main = dm.GetCustomDefinition('gm_enchantment_schematics');
	GMTestReport(main.subNodes.Size() == 23, "ENCH-02: Ghost Mode's schematics loaded from the DLC: " + main.subNodes.Size() + " (expected 23)");
	s = getEnchantmentSchematicFromName('Runeword 1');
	GMTestReport(s.baseCraftingPrice == 2396 && s.level == 3 && s.ingredients.Size() == 3 && s.ingredients[1].itemName == 'Rune veles greater', "ENCH-02: Replenishment's schematic " + s.baseCraftingPrice + ", level " + s.level + ", second rune " + s.ingredients[1].itemName + " (expected 2396, 3, Rune veles greater)");
	s = getEnchantmentSchematicFromName('Runeword 12');
	GMTestReport(s.baseCraftingPrice == 575 && s.level == 1, "ENCH-02: Elation " + s.baseCraftingPrice + ", level " + s.level + " (expected 575, 1)");
	s = getEnchantmentSchematicFromName('Glyphword 10');
	GMTestReport(s.baseCraftingPrice == 1116 && s.level == 2, "ENCH-02: Usurpation " + s.baseCraftingPrice + ", level " + s.level + " (expected 1116, 2)");
	mgr = new W3EnchantmentManager in thePlayer;
	mgr.Init(NULL);
	ok = mgr.GetSchematic('Runeword 8', s);
	GMTestReport(ok && s.baseCraftingPrice == 1182 && s.level == 2, "ENCH-02: the enchanting menu's manager: Placation " + s.baseCraftingPrice + ", level " + s.level + " (expected 1182, 2)");
	ok = mgr.GetSchematic('Glyphword 14', s);
	GMTestReport(ok && s.baseCraftingPrice == 542 && s.level == 1 && mgr.GMTestSchematicCount() == 23, "ENCH-02: Beguilement " + s.baseCraftingPrice + ", level " + s.level + " (expected 542, 1); " + mgr.GMTestSchematicCount() + " schematics (expected 23, no duplicates)");
	delete mgr;
}

@addMethod(W3EnchantmentManager)
function GMTestSchematicCount() : int
{
	return schematics.Size();
}

// ENCH-17: the steel sword's tooltip stats are the same with a rune socketed (legacy's fix; 5.x added
// the rune's bonus to the sword's lines). Adds a slot and an Elemental rune, removes them afterwards
// is not possible (slots stay; the test save is not saved).
function GMTest_ench17()
{
	var w : W3PlayerWitcher;
	var id : SItemUniqueId;
	var runes : array<SItemUniqueId>;
	var before, after : array<SAttributeTooltip>;
	var i : int;
	var same : bool;
	var names : array<name>;

	w = GetWitcherPlayer();
	if(!w.GetItemEquippedOnSlot(EES_SteelSword, id))
		return;
	w.inv.UnenchantItem(id);
	w.inv.GetItemEnhancementItems(id, names);
	if(names.Size() > 0)
	{
		GMTestReport(false, "ENCH-17: the steel sword already holds runes; check skipped");
		return;
	}
	w.inv.GetItemStats(id, before);
	if(w.inv.GetItemEnhancementSlotsCount(id) < 1)
		w.inv.AddSlot(id);
	runes = w.inv.AddAnItem('Rune elemental greater', 1);
	w.inv.EnhanceItemScript(id, runes[0]);
	w.inv.GetItemEnhancementItems(id, names);
	w.inv.GetItemStats(id, after);
	same = before.Size() == after.Size();
	for(i = 0; same && i < before.Size(); i += 1)
		same = before[i].originName == after[i].originName && AbsF(before[i].value - after[i].value) < 0.001;
	GMTestReport(names.Size() == 1 && same, "ENCH-17: a rune in the steel sword (" + names.Size() + " socketed) leaves its tooltip stats as they were (" + before.Size() + " -> " + after.Size() + " lines)");
	w.inv.RemoveItemEnhancementByIndexScript(id, 0);
}

