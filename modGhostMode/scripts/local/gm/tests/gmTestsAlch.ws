// In-game tests for SKL's alchemy branches (SKL-13 to SKL-17). See docs/features/skl.md.

// The value per level of an ability's attribute in the definitions (additive + multiplicative + base),
// checked against the expected value.
function GMTestAlchAbility(abilityName : name, attributeName : name, expected : float, label : string)
{
	var min, max : SAbilityAttributeValue;
	var value : float;

	theGame.GetDefinitionsManager().GetAbilityAttributeValue(abilityName, attributeName, min, max);
	value = min.valueAdditive + min.valueMultiplicative + min.valueBase;
	GMTestReport(AbsF(value - expected) < 0.0001, label + " " + abilityName + " " + attributeName + " " + value + " per level (expected " + expected + ")");
}

exec function gmtest_alch()
{
	GMTest_alch();
}

// The alchemy skills' values per level in both trees (situation-free; in gmtest_regress()).
function GMTest_alch()
{
	// SKL-13 Brewing
	GMTestAlchAbility('alchemy_s1', 'stamina_gain_perc', 0.1, "SKL-13 Refreshment (classic)");
	GMTestAlchAbility('alchemy_s1', 'threshold', 0, "SKL-13 no Heightened Tolerance");
	GMTestAlchAbility('alchemy_s24', 'stamina_gain_perc', 0.1, "SKL-13 Refreshment (new)");
	GMTestAlchAbility('alchemy_s24', 'received_damage_multiplier', 0, "SKL-13 no High Tolerance");
	GMTestAlchAbility('alchemy_s2', 'vitality_gain_perc', 0.05, "SKL-13 Restoration");
	GMTestAlchAbility('GM_C_alchemy_s3', 'toxicityReduction', 1, "SKL-13 Expert Brewer (classic)");
	GMTestAlchAbility('alchemy_s3', 'toxicityReduction', 1.666667, "SKL-13 Expert Brewer (new)");
	GMTestAlchAbility('GM_C_alchemy_s4', 'gm_potion_duration', 0.2, "SKL-13 Prolonged Effects (classic)");
	GMTestAlchAbility('alchemy_s4', 'gm_potion_duration', 0.333334, "SKL-13 Prolonged Effects (new)");
	GMTestAlchAbility('alchemy_s4', 'apply_chance', 0, "SKL-13 no Side Effects");
	// SKL-14 Oil Preparation
	GMTestAlchAbility('GM_C_alchemy_s12', 'skill_chance', 0.03, "SKL-14 Poisoned Blades (classic)");
	GMTestAlchAbility('GM_C_alchemy_s12', 'oil_level_chance', 0.05, "SKL-14 Poisoned Blades (classic)");
	GMTestAlchAbility('alchemy_s12', 'skill_chance', 0.05, "SKL-14 Poisoned Blades (new)");
	GMTestAlchAbility('alchemy_s12', 'oil_level_chance', 0.05, "SKL-14 Poisoned Blades (new)");
	GMTestAlchAbility('GM_C_alchemy_s5', 'defence_bonus', 0.03, "SKL-14 Protective Coating (classic)");
	GMTestAlchAbility('GM_C_alchemy_s5', 'oil_level_defence', 0.05, "SKL-14 Protective Coating (classic)");
	GMTestAlchAbility('alchemy_s5', 'defence_bonus', 0.05, "SKL-14 Protective Coating (new)");
	GMTestAlchAbility('alchemy_s5', 'oil_level_defence', 0.05, "SKL-14 Protective Coating (new)");
	GMTestAlchAbility('alchemy_s6', 'ammo_bonus', 0.334, "SKL-14 Fixative (classic)");
	GMTestAlchAbility('alchemy_s25', 'ammo_bonus', 0.334, "SKL-14 Fixative (new)");
	GMTestAlchAbility('alchemy_s25', 'bomb_damage_bonus', 0, "SKL-14 no Volatile Compound");
	GMTestAlchAbility('alchemy_s7', 'critical_hit_damage_bonus', 0.0668, "SKL-14 Hunter Instinct (classic)");
	GMTestAlchAbility('alchemy_s27', 'critical_hit_damage_bonus', 0.1113, "SKL-14 Hunter Instinct (new)");
	// SKL-15 Bomb Creation
	GMTestAlchAbility('alchemy_s9', 'slowdown_mod', 0.15, "SKL-15 Steady Aim (classic)");
	GMTestAlchAbility('alchemy_s23', 'slowdown_mod', 0.15, "SKL-15 Steady Aim (new)");
	GMTestAlchAbility('alchemy_s23', 'poison_dmg_level_3', 0, "SKL-15 no Toxic Shock");
	GMTestAlchAbility('GM_C_alchemy_s10', 'PhysicalDamage', 50, "SKL-15 Pyrotechnics (classic)");
	GMTestAlchAbility('alchemy_s10', 'PhysicalDamage', 83.333333, "SKL-15 Pyrotechnics (new)");
	GMTestAlchAbility('GM_C_alchemy_s8', 'gm_efficiency_per_level', 1, "SKL-15 Efficiency (classic)");
	GMTestAlchAbility('alchemy_s8', 'gm_efficiency_per_level', 2, "SKL-15 Efficiency (new)");
	GMTestAlchAbility('alchemy_s8', 'gm_efficiency_base', -1, "SKL-15 Efficiency (new)");
	GMTestAlchAbility('GM_C_alchemy_s11', 'gm_fragments_base', 1, "SKL-15 Cluster Bombs (classic)");
	GMTestAlchAbility('alchemy_s11', 'gm_fragments_per_level', 2, "SKL-15 Cluster Bombs (new)");
	// SKL-16 Mutation
	GMTestAlchAbility('alchemy_s18', 'toxicity', 1, "SKL-16 Acquired Tolerance");
	GMTestAlchAbility('alchemy_s18', 'max_abs_per_lvl_s18', 50, "SKL-16 Acquired Tolerance");
	GMTestAlchAbility('GM_C_alchemy_s13', 'vitality', 2, "SKL-16 Tissue Transmutation (classic)");
	GMTestAlchAbility('alchemy_s13', 'vitality', 3.333333, "SKL-16 Tissue Transmutation (new)");
	GMTestAlchAbility('GM_C_alchemy_s14', 'tox_off_bonus', 0.04, "SKL-16 Adaptation (classic)");
	GMTestAlchAbility('alchemy_s14', 'tox_off_bonus', 0.066667, "SKL-16 Adaptation (new)");
	GMTestAlchAbility('alchemy_s14', 'duration', 0, "SKL-16 no Adaptability");
	GMTestAlchAbility('alchemy_s26', 'gm_synergy_levels', 1.666667, "SKL-16 Synergy (new)");
	GMTestAlchAbility('alchemy_s26', 'damage_bonus', 0, "SKL-16 no Potent Sting");
	// SKL-17 Trial of the Grasses
	GMTestAlchAbility('GM_C_alchemy_s16', 'slowdown_ratio', 0.15, "SKL-17 Frenzy (classic)");
	GMTestAlchAbility('GM_C_alchemy_s16', 'attack_power', 0.05, "SKL-17 Frenzy (classic)");
	GMTestAlchAbility('alchemy_s16', 'slowdown_ratio', 0.25, "SKL-17 Frenzy (new)");
	GMTestAlchAbility('alchemy_s16', 'spell_power', 0.083333, "SKL-17 Frenzy (new)");
	GMTestAlchAbility('GM_C_alchemy_s20', 'gm_endure_pain_copies', 1, "SKL-17 Endure Pain (classic)");
	GMTestAlchAbility('alchemy_s20', 'gm_endure_pain_copies', 1.666667, "SKL-17 Endure Pain (new)");
	GMTestAlchAbility('GM_C_alchemy_s15', 'toxicityRegen', -0.25, "SKL-17 Fast Metabolism (classic)");
	GMTestAlchAbility('alchemy_s15', 'toxicityRegen', -0.416667, "SKL-17 Fast Metabolism (new)");
	GMTestAlchAbility('alchemy_s17', 'critical_hit_chance', 0.05, "SKL-17 Killing Spree (classic)");
	GMTestAlchAbility('alchemy_s22', 'critical_hit_chance', 0.083333, "SKL-17 Killing Spree (new)");
	GMTestAlchAbility('alchemy_s22', 'defence_bonus', 0, "SKL-17 no Debilitating Poison");
	GMTestReport(GetWitcherPlayer().GetToxicityDamageThreshold() == theGame.params.TOXICITY_DAMAGE_THRESHOLD, "SKL-13 overdose threshold " + GetWitcherPlayer().GetToxicityDamageThreshold() + " (no skill raises it)");
}

// SKL-13: drinks the named potion with toxicity 0, stamina and Vitality at half, and logs the toxicity
// gained, stamina and Vitality before and after, and the effect's duration against the item's.
exec function gmtest_skl13_drink(itemName : name)
{
	var witcher : W3PlayerWitcher;
	var ids : array<SItemUniqueId>;
	var effectType : EEffectType;
	var abilityName : name;
	var buff : CBaseGameplayEffect;
	var stamina, vitality, baseDuration : float;
	var duration : string;

	witcher = GetWitcherPlayer();
	ids = witcher.inv.GetItemsByName(itemName);
	if(ids.Size() == 0)
		ids = witcher.inv.AddAnItem(itemName, 1);
	witcher.inv.GetPotionItemBuffData(ids[0], effectType, abilityName);
	witcher.RemoveAllBuffsOfType(effectType);
	witcher.DrainToxicity(witcher.GetStat(BCS_Toxicity));
	witcher.ForceSetStat(BCS_Stamina, witcher.GetStatMax(BCS_Stamina) * 0.5);
	witcher.ForceSetStat(BCS_Vitality, witcher.GetStatMax(BCS_Vitality) * 0.5);
	stamina = witcher.GetStat(BCS_Stamina);
	vitality = witcher.GetStat(BCS_Vitality);
	baseDuration = CalculateAttributeValue(witcher.inv.GetItemAttributeValue(ids[0], 'duration'));
	witcher.DrinkPreparedPotion(EES_InvalidSlot, ids[0]);
	buff = witcher.GetBuff(effectType);
	duration = "none";
	if(buff)
		duration = FloatToString(buff.GetDurationLeft());
	LogChannel('GMTest', "INFO SKL-13 " + itemName + " (toxicity " + CalculateAttributeValue(witcher.inv.GetItemAttributeValue(ids[0], 'toxicity')) + ", duration " + baseDuration + "): toxicity 0 -> " + witcher.GetStat(BCS_Toxicity)
		+ ", stamina " + stamina + " -> " + witcher.GetStat(BCS_Stamina) + " / " + witcher.GetStatMax(BCS_Stamina) + ", Vitality " + vitality + " -> " + witcher.GetStat(BCS_Vitality) + " / " + witcher.GetStatMax(BCS_Vitality) + ", effect duration " + duration);
	witcher.DrainToxicity(witcher.GetStat(BCS_Toxicity));
}

// SKL-14: applies a fresh Hanged Man's Venom (human oil, level 1) to the steel sword and draws it.
function GMTestApplyHumanOil() : bool
{
	var witcher : W3PlayerWitcher;
	var ids : array<SItemUniqueId>;
	var applied : bool;

	witcher = GetWitcherPlayer();
	witcher.inv.RemoveAllOilsFromItem(witcher.GetEquippedSword(true));
	ids = witcher.inv.AddAnItem('Hanged Man Venom 1', 1);
	applied = witcher.ApplyOil(ids[0], witcher.GetEquippedSword(true));
	witcher.OnEquipMeleeWeapon(PW_Steel, true);
	return applied;
}

// Geralt's attack power for a light attack with the held sword on the victim (not processed).
function GMTestOilAttackPower(victim : CActor) : float
{
	var action : W3Action_Attack;
	var power : SAbilityAttributeValue;

	action = new W3Action_Attack in theGame.damageMgr;
	action.Init(thePlayer, victim, NULL, thePlayer.GetInventory().GetCurrentlyHeldSword(), 'attack_light', thePlayer.GetName(), EHRT_Light,
		false, false, 'attack_light', AST_Jab, ASD_UpDown, true, false, false, false);
	power = action.GetPowerStatValue();
	delete action;
	return power.valueMultiplicative;
}

// SKL-14: with apply, a fresh human oil on the steel sword; spends the given charges
// (ReduceAllOilsAmmo, as a hit does); then logs the oil's charges, its attack power bonus and Geralt's
// attack power against the hostile test dummy, Poisoned Blades' chance, Protective Coating's cut, the
// crit chance of a light attack and of a bolt against the dummy.
exec function gmtest_skl14_oil(apply : bool, spend : int)
{
	var witcher : W3PlayerWitcher;
	var npc : CActor;
	var sword : SItemUniqueId;
	var oils : array<W3Effect_Oil>;
	var i : int;
	var applied : bool;
	var line : string;
	var itemAttr, oilAttr : SAbilityAttributeValue;

	witcher = GetWitcherPlayer();
	npc = GMTestHostileNpc();
	if(apply)
		applied = GMTestApplyHumanOil();
	sword = witcher.inv.GetCurrentlyHeldSword();
	for(i = 0; i < spend; i += 1)
		witcher.ReduceAllOilsAmmo(sword);
	oils = witcher.inv.GetOilsAppliedOnItem(sword);
	line = "INFO SKL-14 oil: applied " + applied + ", oils on the held sword " + oils.Size();
	for(i = 0; i < oils.Size(); i += 1)
		line += " (" + oils[i].GetOilItemName() + " " + oils[i].GetAmmoCurrentCount() + "/" + oils[i].GetAmmoMaxCount() + ", share " + oils[i].GetAmmoPercentage() + ", factor " + oils[i].GMScaleFactor() + ")";
	LogChannel('GMTest', line);
	itemAttr = witcher.inv.GetItemAttributeValue(sword, 'vsHuman_attack_power');
	oilAttr = witcher.inv.GMOilBonus(sword, MC_Human, 'vsHuman_attack_power');
	LogChannel('GMTest', "INFO SKL-14 oil: attack power bonus vs humans " + oilAttr.valueMultiplicative + " (item attribute " + itemAttr.valueMultiplicative + ")"
		+ ", Geralt's attack power vs the dummy " + GMTestOilAttackPower(npc) + ", Poisoned Blades chance " + witcher.inv.GMOilPoisonChance(sword, MC_Human) + ", Protective Coating cut " + witcher.inv.GMOilProtection(sword, MC_Human)
		+ ", crit chance light " + witcher.GetCriticalHitChance(true, false, npc, MC_Human, false) + ", bolt " + witcher.GetCriticalHitChance(false, false, npc, MC_Human, true));
}

// SKL-14: n scripted light attacks with the held sword on the hostile test dummy (100 physical), the oil
// refreshed before each; logs how many poisoned it.
exec function gmtest_skl14_poison(n : int, optional keepOil : bool)
{
	var npc : CActor;
	var action : W3Action_Attack;
	var i, poisoned : int;

	npc = GMTestHostileNpc();
	if(!npc)
		return;
	for(i = 0; i < n; i += 1)
	{
		if(!keepOil)
			GMTestApplyHumanOil();
		npc.RemoveAllBuffsOfType(EET_Poison);
		action = new W3Action_Attack in theGame.damageMgr;
		action.Init(thePlayer, npc, NULL, thePlayer.GetInventory().GetCurrentlyHeldSword(), 'attack_light', thePlayer.GetName(), EHRT_Light,
			false, false, 'attack_light', AST_Jab, ASD_UpDown, true, false, false, false);
		action.AddDamage(theGame.params.DAMAGE_NAME_PHYSICAL, 100);
		action.SetSuppressHitSounds(true);
		action.SetHitAnimationPlayType(EAHA_ForceNo);
		theGame.damageMgr.ProcessAction(action);
		delete action;
		if(npc.HasBuff(EET_Poison))
			poisoned += 1;
		npc.ForceSetStat(BCS_Vitality, npc.GetStatMax(BCS_Vitality));
	}
	npc.RemoveAllBuffsOfType(EET_Poison);
	LogChannel('GMTest', "INFO SKL-14 Poisoned Blades: " + poisoned + " of " + n + " hits poisoned the dummy");
}

// SKL-14: n scripted physical hits of the hostile test dummy on Geralt (DEF's helper: 5% of his maximum
// Vitality); logs the average Vitality taken.
exec function gmtest_skl14_hit(n : int)
{
	var npc : CActor;
	var action : W3Action_Attack;
	var i : int;
	var total : float;

	npc = GMTestHostileNpc();
	if(!npc)
		return;
	for(i = 0; i < n; i += 1)
	{
		total += GMTestDefParryHit(npc, false, false, EET_Undefined, action);
		delete action;
	}
	GMTestDefClearHitEffects();
	LogChannel('GMTest', "INFO SKL-14 Protective Coating: average Vitality taken " + (total / n) + " over " + n + " hits (Protective Coating cut " + GetWitcherPlayer().inv.GMOilProtection(GetWitcherPlayer().inv.GetCurrentlyHeldSword(), MC_Human) + ")");
}

// SKL-14 Hunter Instinct: the critical hit damage bonus of the held sword against humans at 0 to 3
// adrenaline points (the adrenaline restored after).
exec function gmtest_skl14_hunter()
{
	var witcher : W3PlayerWitcher;
	var focus : float;
	var i : int;
	var bonus : SAbilityAttributeValue;
	var line : string;

	witcher = GetWitcherPlayer();
	focus = witcher.GetStat(BCS_Focus);
	line = "INFO SKL-14 Hunter Instinct: crit damage bonus vs humans";
	for(i = 0; i <= 3; i += 1)
	{
		witcher.DrainFocus(witcher.GetStat(BCS_Focus));
		witcher.GainStat(BCS_Focus, i);
		bonus = witcher.GetCriticalHitDamageBonus(witcher.inv.GetCurrentlyHeldSword(), MC_Human, false);
		line += ", " + i + " adrenaline: " + bonus.valueAdditive;
	}
	witcher.DrainFocus(witcher.GetStat(BCS_Focus));
	witcher.GainStat(BCS_Focus, focus);
	line += " (vs monsters at 3: ";
	witcher.GainStat(BCS_Focus, 3);
	bonus = witcher.GetCriticalHitDamageBonus(witcher.inv.GetCurrentlyHeldSword(), MC_Specter, false);
	witcher.DrainFocus(witcher.GetStat(BCS_Focus));
	witcher.GainStat(BCS_Focus, focus);
	LogChannel('GMTest', line + bonus.valueAdditive + ")");
}

// SKL-14 Fixative: applies the named oil to the steel sword (after a human oil) and lists the oils on it.
exec function gmtest_skl14_apply(itemName : name)
{
	var witcher : W3PlayerWitcher;
	var ids : array<SItemUniqueId>;
	var oils : array<W3Effect_Oil>;
	var i : int;
	var line : string;

	witcher = GetWitcherPlayer();
	GMTestApplyHumanOil();
	ids = witcher.inv.AddAnItem(itemName, 1);
	witcher.ApplyOil(ids[0], witcher.GetEquippedSword(true));
	oils = witcher.inv.GetOilsAppliedOnItem(witcher.GetEquippedSword(true));
	line = "INFO SKL-14 Fixative: oils on the steel sword after Hanged Man Venom 1 and " + itemName + ":";
	for(i = 0; i < oils.Size(); i += 1)
		line += " " + oils[i].GetOilItemName() + " " + oils[i].GetAmmoCurrentCount() + "/" + oils[i].GetAmmoMaxCount();
	LogChannel('GMTest', line);
}

// SKL-15: Efficiency's extra bombs and the Dancing Star's slot size, Cluster Bombs' fragments, Steady Aim's
// slowdown and the bomb aiming speed it gives (5.x's 0.6 less the slowdown per level).
exec function gmtest_skl15_state()
{
	var witcher : W3PlayerWitcher;
	var ids : array<SItemUniqueId>;
	var skill : ESkill;
	var slow : float;

	witcher = GetWitcherPlayer();
	ids = witcher.inv.GetItemsByName('Dancing Star 1');
	if(ids.Size() == 0)
		ids = witcher.inv.AddAnItem('Dancing Star 1', 1);
	skill = witcher.GMSteadyAimSkill();
	if(skill != S_SUndefined)
		slow = CalculateAttributeValue(witcher.GetSkillAttributeValue(skill, 'slowdown_mod', false, true)) * witcher.GetSkillLevel(skill);
	LogChannel('GMTest', "INFO SKL-15 Efficiency +" + witcher.GMEfficiencyBonus() + ", Dancing Star slot " + witcher.inv.SingletonItemGetMaxAmmo(ids[0]) + "; Cluster Bombs fragments " + witcher.GMClusterFragments()
		+ "; Steady Aim " + skill + " slowdown " + slow + ", bomb aiming speed " + (0.6 - slow) + "; Pyrotechnics level " + witcher.GetSkillLevel(S_Alchemy_s10));
}

// SKL-15: logs each of Geralt's bombs exploding while the test probes are on: a fragment or not, its
// impact damage.
@wrapMethod(W3Petard)
function ProcessEffect(optional explosionPosition : Vector, optional collidedTarget : CGameplayEntity)
{
	var params : SPetardParams;
	var i : int;
	var line : string;

	if(GMTestProbes() && GetOwner() == thePlayer)
	{
		params = GetImpactParams();
		line = "INFO SKL-15 bomb explodes: fragment " + isCluster + ", impact damage";
		for(i = 0; i < params.damages.Size(); i += 1)
			line += " " + params.damages[i].dmgType + " " + params.damages[i].dmgVal;
		LogChannel('GMTest', line);
	}
	wrappedMethod(explosionPosition, collidedTarget);
}

// The game's time scale and Geralt's state (bomb aiming: Steady Aim).
exec function gmtest_timescale()
{
	LogChannel('GMTest', "INFO time scale " + theGame.GetTimeScale() + ", state " + thePlayer.GetCurrentStateName());
}

// SKL-16: the Synergy level and each mutagen slot's bonus ability and copies.
@addMethod(W3PlayerAbilityManager)
function GMTestSynergyState() : string
{
	var i : int;
	var line : string;

	line = "Synergy level " + GMSynergyLevel();
	for(i = 0; i < mutagenSlots.Size(); i += 1)
		line += ", group " + mutagenSlots[i].skillGroupID + ": " + mutagenBonuses[mutagenSlots[i].skillGroupID].abilityName + " x" + mutagenBonuses[mutagenSlots[i].skillGroupID].count;
	return line;
}

@addMethod(W3PlayerWitcher)
function GMTestSynergyState() : string
{
	return ((W3PlayerAbilityManager)abilityManager).GMTestSynergyState();
}

// SKL-16: with mutagen, a greater red mutagen in the first skill mutagen slot; with decoction, drinks
// Mutagen 1 (after clearing toxicity); then logs maximum toxicity and Acquired Tolerance's copies and the
// formulas known, maximum Vitality, the toxicity offset and Tissue Transmutation's copies, Adaptation's
// share and the Synergy state.
exec function gmtest_skl16_state(optional mutagen : bool, optional decoction : bool)
{
	var witcher : W3PlayerWitcher;
	var ids : array<SItemUniqueId>;
	var recipes : array<name>;

	witcher = GetWitcherPlayer();
	if(mutagen)
	{
		ids = witcher.inv.GetItemsByName('Greater mutagen red');
		if(ids.Size() == 0)
			ids = witcher.inv.AddAnItem('Greater mutagen red', 1);
		witcher.EquipItem(ids[0], EES_SkillMutagen1);
	}
	if(decoction)
	{
		witcher.RemoveAllBuffsOfType(EET_Mutagen01);
		witcher.DrainToxicity(witcher.GetStat(BCS_Toxicity));
		ids = witcher.inv.GetItemsByName('Mutagen 1');
		if(ids.Size() == 0)
			ids = witcher.inv.AddAnItem('Mutagen 1', 1);
		witcher.inv.SingletonItemSetAmmo(ids[0], 1);
		witcher.DrinkPreparedPotion(EES_InvalidSlot, ids[0]);
	}
	recipes = witcher.GetAlchemyRecipes();
	LogChannel('GMTest', "INFO SKL-16 max toxicity " + witcher.GetStatMax(BCS_Toxicity) + ", Acquired Tolerance copies " + witcher.GetAbilityCount(SkillEnumToName(S_Alchemy_s18)) + ", formulas " + recipes.Size()
		+ "; max Vitality " + witcher.GetStatMax(BCS_Vitality) + ", toxicity " + witcher.GetStat(BCS_Toxicity) + " (offset " + (witcher.GetStat(BCS_Toxicity) - witcher.GetStat(BCS_Toxicity, true)) + "), Tissue Transmutation copies " + witcher.GetAbilityCount(witcher.GetSkillAbilityName(S_Alchemy_s13))
		+ "; Adaptation share " + witcher.GMAdaptationMult() + "; " + witcher.GMTestSynergyState());
}

// SKL-16: adds the named alchemy formula, then logs as gmtest_skl16_state.
exec function gmtest_skl16_recipe(recipe : name)
{
	LogChannel('GMTest', "INFO SKL-16 formula " + recipe + " added " + GetWitcherPlayer().AddAlchemyRecipe(recipe));
}

// SKL-17: with set, sets toxicity to the given share of its maximum (0 clears it); then logs toxicity
// against the overdose threshold, Frenzy's copies and Geralt's attack power and sign intensity, Endure
// Pain's effect, copies and maximum Vitality, the Killing Spree copies and the light-attack crit chance.
exec function gmtest_skl17_state(optional setTox : bool, optional share : float)
{
	var witcher : W3PlayerWitcher;
	var ap, sp : SAbilityAttributeValue;
	var ks : name;

	witcher = GetWitcherPlayer();
	if(setTox)
	{
		witcher.DrainToxicity(witcher.GetStat(BCS_Toxicity));
		if(share > 0)
			witcher.GainStat(BCS_Toxicity, witcher.GetStatMax(BCS_Toxicity) * share);
	}
	ap = witcher.GetAttributeValue('attack_power');
	sp = witcher.GetAttributeValue('spell_power');
	ks = SkillEnumToName(S_Alchemy_s17);
	if(!witcher.CanUseSkill(S_Alchemy_s17))
		ks = SkillEnumToName(S_Alchemy_s22);
	LogChannel('GMTest', "INFO SKL-17 toxicity " + witcher.GetStatPercents(BCS_Toxicity) + " (threshold " + witcher.GetToxicityDamageThreshold() + ", effect " + witcher.HasBuff(EET_Toxicity) + ")"
		+ "; Frenzy copies " + witcher.GetAbilityCount(SkillEnumToName(S_Alchemy_s16)) + ", attack power mult " + ap.valueMultiplicative + ", spell power mult " + sp.valueMultiplicative
		+ "; Endure Pain " + witcher.HasBuff(EET_IgnorePain) + ", copies " + witcher.GetAbilityCount('IgnorePainEffect') + ", max Vitality " + witcher.GetStatMax(BCS_Vitality)
		+ "; Killing Spree " + ks + " copies " + witcher.GetAbilityCount(ks) + ", crit chance " + witcher.GetCriticalHitChance(true, false, NULL, MC_Human, false));
}

// SKL-17: starts Frenzy's slow motion and logs the time scale (read again with gmtest_timescale()).
exec function gmtest_skl17_frenzy()
{
	GetWitcherPlayer().StartFrenzy();
	LogChannel('GMTest', "INFO SKL-17 Frenzy started: time scale " + theGame.GetTimeScale());
}

