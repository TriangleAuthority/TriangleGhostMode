// SKL-19: skill and perk descriptions (docs/features/skl.md). Both trees are drawn in the new
// character menu (CR4CharacterDupeMenu, SKL-02), so its tooltip text is Ghost Mode's: one text per
// skill (or per level, where the text changes with the level), shared by the two trees, with the
// numbers read from the skill's ability in force (GM_C_<skill> or the new tree's values) for the
// level shown. Skills Ghost Mode does not describe keep 5.x's text without the passive path lines
// (the passive bonuses are removed, SKL-01). Strings: modGhostMode/localization, ids 2110992000+.

// The value of one level of a skill's attribute (one copy of its ability), whatever its type.
function GMSkillVal(skill : ESkill, attributeName : name) : float
{
	var v : SAbilityAttributeValue;

	v = GetWitcherPlayer().GetSkillAttributeValue(skill, attributeName, false, false);
	return v.valueBase + v.valueMultiplicative + v.valueAdditive;
}

// The base value of a skill's attribute (for attributes that also carry 5.x's multiplier of 1).
function GMSkillBase(skill : ESkill, attributeName : name) : float
{
	var v : SAbilityAttributeValue;

	v = GetWitcherPlayer().GetSkillAttributeValue(skill, attributeName, false, false);
	return v.valueBase;
}

// The skill of the tree in force: the classic one or its new-tree counterpart.
function GMTreeSkill(classicSkill : ESkill, newSkill : ESkill) : ESkill
{
	if(GMIsClassicProfileInForce())
		return classicSkill;
	return newSkill;
}

// Level x value of an equipped skill's attribute, 0 if the skill is not in use.
function GMEquippedSkillVal(skill : ESkill, attributeName : name) : float
{
	var witcher : W3PlayerWitcher;

	witcher = GetWitcherPlayer();
	if(!witcher.CanUseSkill(skill))
		return 0;
	return GMSkillVal(skill, attributeName) * witcher.GetSkillLevel(skill);
}

// A number with up to prec decimals, trailing zeros dropped.
function GMDescNum(x : float, prec : int) : string
{
	var s : string;

	s = FloatToStringPrec(x, prec);
	if(StrFindFirst(s, ".") >= 0 || StrFindFirst(s, ",") >= 0)
	{
		while(StrEndsWith(s, "0"))
			s = StrLeft(s, StrLen(s) - 1);
		if(StrEndsWith(s, ".") || StrEndsWith(s, ","))
			s = StrLeft(s, StrLen(s) - 1);
	}
	return s;
}

// A share as a percentage in whole points (project owner, 2026-10-09); below one point, with up to
// two decimals, so a small value does not read 0.
function GMDescPct(x : float) : string
{
	x *= 100;
	if(x != 0 && AbsF(x) < 0.995)
		return GMDescNum(x, 2);
	return IntToString(RoundMath(x));
}

// Adrenaline amounts: two decimals at most (project owner, 2026-10-09).
function GMDescAdr(x : float) : string
{
	return GMDescNum(x, 2);
}

// 5.x's menu appends a passive path line to every tooltip (several to some); Ghost Mode has no
// passive bonuses (SKL-01), so they go.
function GMStripPassiveLines(desc : string) : string
{
	var labels : array<string>;
	var i, idx : int;

	labels.PushBack(GetLocStringByKeyExt("focus_gain"));
	labels.PushBack(GetLocStringByKeyExt("attribute_name_staminaregen"));
	labels.PushBack(GetLocStringByKeyExt("attribute_potion_duration_time"));
	labels.PushBack(GetLocStringByKeyExt("skill_tree_buff_survival"));
	for(i = 0; i < labels.Size(); i += 1)
	{
		if(labels[i] == "")
			continue;
		idx = StrFindLast(desc, "<br>" + labels[i]);
		while(idx >= 0)
		{
			desc = StrLeft(desc, idx);
			idx = StrFindLast(desc, "<br>" + labels[i]);
		}
	}
	return desc;
}

// The tooltip text of a skill at a level: Ghost Mode's, or 5.x's without the passive lines.
function GMSkillTooltip(skill : ESkill, level : int, vanillaDesc : string) : string
{
	var desc : string;

	if(level < 1)
		level = 1;
	desc = GMSkillDescription(skill, level);
	if(desc == "")
		desc = GMStripPassiveLines(vanillaDesc);
	return desc;
}

// Ghost Mode's text for a skill at a level, or "" where 5.x's text stands.
function GMSkillDescription(skill : ESkill, level : int) : string
{
	var desc : string;

	desc = GMSwordSkillDescription(skill, level);
	if(desc == "")
		desc = GMSignSkillDescription(skill, level);
	if(desc == "")
		desc = GMAlchemySkillDescription(skill, level);
	if(desc == "")
		desc = GMPerkDescription(skill, level);
	return desc;
}

@wrapMethod(CR4CharacterDupeMenu)
function GetSkillTooltipDescriptionForSkillLevel(targetSkill : SSkill, skillLevel : int) : string
{
	var desc : string;

	desc = wrappedMethod(targetSkill, skillLevel);
	return GMSkillTooltip(targetSkill.skillType, skillLevel, desc);
}

// Combat skills (core, both trees).
function GMSwordSkillDescription(skill : ESkill, lvl : int) : string
{
	var a : array<string>;
	var ai : array<int>;
	var af : array<float>;
	var witcher : W3PlayerWitcher;
	var v, cost : float;
	var dm : CDefinitionsManagerAccessor;
	var min, max : SAbilityAttributeValue;

	witcher = GetWitcherPlayer();
	switch(skill)
	{
		case S_Sword_2:
			ai.PushBack(RoundMath(GMSkillVal(skill, 'heavy_attack_dmg_boost') * 100));
			ai.PushBack(RoundMath(GMSkillVal(skill, 'armor_reduction')));
			return GetLocStringByKeyExtWithParams("gm_skill_desc_sword_2", ai);
		case S_Sword_3:
			ai.PushBack(25);	// DEF-07: crit chance against a countered enemy
			ai.PushBack(RoundMath((1 - ClampF(theGame.params.PARRY_STAGGER_REDUCE_DAMAGE_SMALL, 0, 1)) * 100));
			return GetLocStringByKeyExtWithParams("gm_skill_desc_sword_3", ai);
		case S_Sword_4:
			return GetLocStringByKeyExt("gm_skill_desc_sword_4");
		case S_Sword_5:
			min = witcher.GetSkillAttributeValue(S_Sword_5, PowerStatEnumToName(CPS_AttackPower), false, true);
			ai.PushBack(RoundMath(min.valueMultiplicative * 100));
			return GetLocStringByKeyExtWithParams("gm_skill_desc_sword_5", ai);
		// Whirl
		case S_Sword_s01:
		case S_Sword_s35:
			cost = GMSkillVal(skill, 'stamina_cost_per_sec') * (1 - GMSkillVal(skill, 'stamina_cost_reduction_after_1') * (lvl - 1));
			a.PushBack(GMDescNum(cost, 1));
			a.PushBack(GMDescAdr(cost / witcher.GetStatMax(BCS_Stamina)));
			v = GMSkillVal(skill, 'whirl_dmg_bonus') * lvl;
			a.PushBack(GMDescPct(v));
			a.PushBack(GMDescPct(v * 5));
			a.PushBack(GMDescPct(GMSkillVal(skill, 'whirl_dmg_reduction') + GMSkillVal(skill, 'whirl_dmg_reduction_bonus_after_1') * (lvl - 1)));
			return GetLocStringByKeyExtWithParams("gm_skill_desc_whirl", , , a);
		// Rend
		case S_Sword_s02:
			a.PushBack(GMDescPct(GMSkillVal(skill, 'attack_damage_bonus') * lvl));
			a.PushBack(GMDescPct(GMSkillVal(skill, 'stamina_max_dmg_bonus') * lvl));
			a.PushBack(GMDescPct(GMSkillVal(skill, 'adrenaline_final_damage_bonus') * lvl));
			a.PushBack(GMDescPct(GMSkillVal(skill, theGame.params.CRITICAL_HIT_CHANCE) * lvl));
			a.PushBack("3");	// the shock wave: 3 adrenaline points, 3 yards (RendAoE)
			a.PushBack("3");
			return GetLocStringByKeyExtWithParams("gm_skill_desc_rend", , , a);
		// Deadly Precision
		case S_Sword_s03:
		case S_Sword_s30:
			a.PushBack(GMDescPct(GMSkillVal(skill, 'instant_kill_chance') * lvl));
			return GetLocStringByKeyExtWithParams("gm_skill_desc_deadly_precision", , , a);
		// the classic Strength Training and Muscle Memory (D47)
		case S_Sword_s04:
			a.PushBack(GMDescPct(GMSkillVal(skill, PowerStatEnumToName(CPS_AttackPower)) * lvl));
			a.PushBack(GMDescPct(GMSkillVal(skill, 'heavy_focus_gain') * lvl));
			return GetLocStringByKeyExtWithParams("gm_skill_desc_strength_training_c", , , a);
		case S_Sword_s21:
			a.PushBack(GMDescPct(GMSkillVal(skill, PowerStatEnumToName(CPS_AttackPower)) * lvl));
			a.PushBack(GMDescPct(GMSkillVal(skill, 'light_focus_gain') * lvl));
			return GetLocStringByKeyExtWithParams("gm_skill_desc_muscle_memory_c", , , a);
		// Crippling Strikes
		case S_Sword_s05:
		case S_Sword_s29:
			a.PushBack(GMDescPct(GMSkillVal(skill, 'sword_s5_chance') * lvl));
			a.PushBack(GMDescPct(GMSkillVal(skill, 'sword_s5_dmg_boost') * lvl));
			return GetLocStringByKeyExtWithParams("gm_skill_desc_crippling_strikes", , , a);
		// Sunder Armor
		case S_Sword_s06:
		case S_Sword_s28:
			a.PushBack(GMDescPct(GMSkillVal(skill, 'armor_reduction_perc') * lvl));
			return GetLocStringByKeyExtWithParams("gm_skill_desc_sunder_armor", , , a);
		// Anatomical Knowledge
		case S_Sword_s07:
		case S_Sword_s26:
			a.PushBack(GMDescPct(GMSkillVal(skill, theGame.params.CRITICAL_HIT_CHANCE) * lvl));
			a.PushBack(GMDescPct(GMSkillVal(skill, theGame.params.CRITICAL_HIT_DAMAGE_BONUS) * lvl));
			return GetLocStringByKeyExtWithParams("gm_skill_desc_anatomical_knowledge", , , a);
		// the classic Crushing Blows and Precise Blows
		case S_Sword_s08:
		case S_Sword_s17:
			ai.PushBack(RoundMath(GMSkillVal(skill, theGame.params.CRITICAL_HIT_CHANCE) * lvl * 100));
			ai.PushBack(RoundMath(GMSkillVal(skill, theGame.params.CRITICAL_HIT_DAMAGE_BONUS) * lvl * 100));
			if(skill == S_Sword_s08)
				return GetLocStringByKeyExtWithParams("gm_skill_desc_crushing_blows_c", ai);
			return GetLocStringByKeyExtWithParams("gm_skill_desc_precise_blows_c", ai);
		// Fleet Footed
		case S_Sword_s09:
		case S_Sword_s36:
			a.PushBack(GMDescPct(GMSkillVal(skill, 's9_damage_reduction') * lvl));
			return GetLocStringByKeyExtWithParams("gm_skill_desc_fleet_footed", , , a);
		// Deflection (by level: reflected damage from level 2, the parry cost at level 3)
		case S_Sword_s10:
		case S_Sword_s33:
			a.PushBack(GMDescPct(GMSkillVal(skill, 's10_damage_reduction') * lvl));
			if(lvl < 2)
				return GetLocStringByKeyExtWithParams("gm_skill_desc_deflection_1", , , a);
			a.PushBack(GMDescPct(GMSkillVal(skill, 'damage_increase') * (lvl - 1)));
			if(lvl < 3)
				return GetLocStringByKeyExtWithParams("gm_skill_desc_deflection_2", , , a);
			a.PushBack(GMDescPct(GMSkillVal(skill, 'parry_cost_decrease')));
			return GetLocStringByKeyExtWithParams("gm_skill_desc_deflection_3", , , a);
		// Counterattack (by level: crit chance from level 2, the knockdown at level 3)
		case S_Sword_s11:
		case S_Sword_s31:
			a.PushBack(GMDescPct(GMSkillVal(skill, 'attack_power') * lvl));
			if(lvl < 2)
				return GetLocStringByKeyExtWithParams("gm_skill_desc_counterattack_1", , , a);
			a.PushBack(GMDescPct(GMSkillVal(skill, 'critical_hit_chance') * (lvl - 1)));
			if(lvl < 3)
				return GetLocStringByKeyExtWithParams("gm_skill_desc_counterattack_2", , , a);
			a.PushBack(GMDescPct(GMSkillVal(skill, 's11_knockdown_chance')));
			return GetLocStringByKeyExtWithParams("gm_skill_desc_counterattack_3", , , a);
		// Crippling Shot
		case S_Sword_s12:
		case S_Sword_s27:
			a.PushBack(GMDescNum(GMSkillVal(skill, 'duration') * lvl, 0));
			return GetLocStringByKeyExtWithParams("gm_skill_desc_crippling_shot", , , a);
		// Lightning Reflexes: 5.x's text. The new tree's value multiplies the aiming speed (0.6).
		case S_Sword_s13:
			ai.PushBack(RoundMath(GMSkillVal(skill, 'slowdown_mod') * lvl * 100));
			return GetLocStringByKeyExtWithParams("skill_desc_sword_s13", ai);
		case S_Sword_s32:
			ai.PushBack(RoundMath(0.6 * GMSkillVal(skill, 'slowdown_mod') * lvl * 100));
			return GetLocStringByKeyExtWithParams("skill_desc_sword_s13", ai);
		// Steady Shot, the classic tree's sword_s15 (legacy swapped it with perk_2)
		case S_Sword_s15:
			af.PushBack(GMSkillVal(skill, 'xbow_dmg_bonus') * lvl);
			return GetLocStringByKeyExtWithParams("gm_skill_desc_steady_shot", , af);
		// Resolve: 5.x's classic text
		case S_Sword_s16:
			ai.PushBack(RoundMath(GMSkillVal(skill, 'focus_drain_reduction') * lvl * 100));
			return GetLocStringByKeyExtWithParams("skill_desc_sword_s16", ai);
		// Undying
		case S_Sword_s18:
			dm = theGame.GetDefinitionsManager();
			dm.GetAbilityAttributeValue('GMUndyingImmortalEffect', 'duration', min, max);
			v = min.valueAdditive;
			a.PushBack(GMDescNum(v, 1));
			dm.GetAbilityAttributeValue(witcher.GMUndyingRegenAbility(), 'vitalityCombatRegen', min, max);
			a.PushBack(GMDescPct(min.valueMultiplicative * v * lvl));
			a.PushBack(GMDescPct(min.valueMultiplicative * v * lvl * 3));
			a.PushBack(GMDescNum(GMSkillVal(skill, 'trigger_delay'), 0));
			return GetLocStringByKeyExtWithParams("gm_skill_desc_undying", , , a);
		// Flood of Anger
		case S_Sword_s19:
			ai.PushBack(RoundMath(GMSkillVal(skill, 'spell_power') * lvl * 100));
			return GetLocStringByKeyExtWithParams("gm_skill_desc_flood_of_anger", ai);
		// Razor Focus
		case S_Sword_s20:
			a.PushBack(GMDescAdr(GMSkillVal(skill, 'focus_add') * lvl));
			ai.PushBack(RoundMath(GMSkillVal(skill, 'focus_gain') * lvl * 100));
			return GetLocStringByKeyExtWithParams("gm_skill_desc_razor_focus", ai, , a);
		// new design: Muscle Memory, new tree (D1, D53)
		case S_Sword_s22:
			if(lvl > 1)
				a.PushBack(IntToString(lvl));
			a.PushBack(GMDescPct(GMSkillVal(skill, 'gm_mm_attack_power')));
			a.PushBack(GMDescPct(GMSkillVal(skill, 'gm_mm_total_damage')));
			a.PushBack(GMDescPct(GMSkillVal(skill, 'light_focus_gain') * lvl));
			if(lvl > 1)
				return GetLocStringByKeyExtWithParams("gm_skill_desc_muscle_memory_23", , , a);
			return GetLocStringByKeyExtWithParams("gm_skill_desc_muscle_memory_1", , , a);
		// new design: Strength Training, new tree (D1, D54)
		case S_Sword_s23:
			a.PushBack(GMDescPct(GMSkillVal(skill, 'gm_st_attack_power')));
			a.PushBack(GMDescPct(GMSkillVal(skill, 'gm_st_weapon_damage')));
			if(lvl > 1)
				a.PushBack(IntToString(lvl));
			a.PushBack(GMDescPct(GMSkillVal(skill, 'heavy_focus_gain') * lvl));
			if(lvl > 1)
				return GetLocStringByKeyExtWithParams("gm_skill_desc_strength_training_23", , , a);
			return GetLocStringByKeyExtWithParams("gm_skill_desc_strength_training_1", , , a);
		// new designs: Precise Blows and Crushing Blows, new tree (D57, D55)
		case S_Sword_s24:
		case S_Sword_s25:
			a.PushBack(GMDescPct(GMSkillVal(skill, 'gm_crit_damage') * lvl));
			a.PushBack(GMDescPct(GMSkillVal(skill, 'gm_crit_chance')));
			a.PushBack(GMDescPct(GMSkillVal(skill, 'gm_chain_crit_chance')));
			a.PushBack(GMDescPct(GMSkillVal(skill, 'gm_chain_crit_damage') * lvl));
			a.PushBack(GMDescNum(GMSkillVal(skill, 'gm_chain_duration'), 1));
			if(skill == S_Sword_s24)
				return GetLocStringByKeyExtWithParams("gm_skill_desc_precise_blows", , , a);
			return GetLocStringByKeyExtWithParams("gm_skill_desc_crushing_blows", , , a);
		// new design: Cold Blood, new tree (D13, D17), with Steady Shot's damage
		case S_Sword_s34:
			a.PushBack(GMDescNum(GMSkillVal(skill, 'xbow_dmg_bonus') * lvl, 0));
			return GetLocStringByKeyExtWithParams("gm_skill_desc_cold_blood", , , a);
	}
	return "";
}

// Signs (core, both trees). "Current" values follow Geralt's sign intensity and the equipped
// intensity skills, as legacy's texts did.
function GMSignSkillDescription(skill : ESkill, lvl : int) : string
{
	var a : array<string>;
	var ai : array<int>;
	var witcher : W3PlayerWitcher;
	var v, v2, bonus : float;
	var sp, min, max : SAbilityAttributeValue;
	var dm : CDefinitionsManagerAccessor;
	var other : ESkill;

	witcher = GetWitcherPlayer();
	dm = theGame.GetDefinitionsManager();
	switch(skill)
	{
		// Aard: the knockdown roll (SKL-08), at Geralt's intensity
		case S_Magic_1:
			sp = witcher.GetTotalSignSpellPower(S_Magic_1);
			v = GMSkillVal(skill, 'starting_knockdown_chance') * (1 + GMSignPowerStatToPowerBonus(sp.valueMultiplicative));
			ai.PushBack(RoundMath(MinF(v, 1) * 100));
			other = GMTreeSkill(S_Magic_s12, S_Magic_s39);
			ai.PushBack(RoundMath((0.15 + GMEquippedSkillVal(other, 'heavy_knockdown_chance_bonus')) * MinF(v, 1) * 100));
			return GetLocStringByKeyExtWithParams("gm_skill_desc_aard", ai);
		// Igni: base damage and burn chance with the equipped Igni Intensity and Pyromaniac, and Rotation
		// (ENCH-13: +150 damage, 33.3 points less burning chance, floored at 0; legacy)
		case S_Magic_2:
			v = GMSkillVal(skill, theGame.params.DAMAGE_NAME_FIRE) + GMEquippedSkillVal(GMTreeSkill(S_Magic_s07, S_Magic_s35), 'fire_damage_bonus');
			if(witcher.HasGlyphwordActive('Glyphword 7 _Stats'))
				v += GMRotationValue('glyphword7_dmg_buff');
			ai.PushBack(RoundMath(v));
			v = GMSkillVal(skill, 'initial_burn_chance') + GMEquippedSkillVal(GMTreeSkill(S_Magic_s09, S_Magic_s41), 'chance_bonus');
			if(witcher.HasGlyphwordActive('Glyphword 7 _Stats'))
				v = MaxF(0, v + GMRotationValue('glyphword7_burnchance_debuff'));
			ai.PushBack(RoundMath(v * 100));
			return GetLocStringByKeyExtWithParams("gm_skill_desc_igni", ai);
		// Yrden's trap (SKL-10)
		case S_Magic_3:
			sp = witcher.GetTotalSignSpellPower(S_Magic_3);
			a.PushBack(GMDescPct(GMSkillVal(skill, 'min_starting_slowdown') * (1 + GMSignPowerStatToPowerBonus(sp.valueMultiplicative))));
			a.PushBack(GMDescPct(GMSkillVal(skill, 'max_slowdown')));
			v = GMSkillBase(skill, 'trap_duration') * (1 + GMEquippedSkillVal(GMTreeSkill(S_Magic_s10, S_Magic_s42), 'trap_duration_bonus'));
			a.PushBack(GMDescNum(v, 1));
			return GetLocStringByKeyExtWithParams("gm_skill_desc_yrden", , , a);
		// Quen's shield (SKL-11): health with the equipped Quen Intensity, at Geralt's intensity
		case S_Magic_4:
			ai.PushBack(RoundMath(GMSkillVal(skill, 'max_dmg_absorption') * 100));
			v = GMSkillBase(skill, 'shield_health') + GMEquippedSkillVal(GMTreeSkill(S_Magic_s15, S_Magic_s38), 'shield_health_bonus');
			ai.PushBack(RoundMath(v));
			sp = witcher.GetTotalSignSpellPower(S_Magic_4);
			ai.PushBack(RoundMath(v * (1 + GMSignPowerStatToPowerBonus(sp.valueMultiplicative))));
			ai.PushBack(RoundMath(GMSkillBase(skill, 'shield_duration')));
			return GetLocStringByKeyExtWithParams("gm_skill_desc_quen", ai);
		// Axii (SKL-12): crit chance with the equipped Delusion; duration with Axii Intensity
		case S_Magic_5:
			dm.GetAbilityAttributeValue('ConfusionEffect', 'critical_hit_chance', min, max);
			v = min.valueAdditive + GMEquippedSkillVal(S_Magic_s17, 'crit_chance_bonus');
			a.PushBack(GMDescPct(v));
			sp = witcher.GetTotalSignSpellPower(S_Magic_5);
			bonus = GMSignPowerStatToPowerBonus(sp.valueMultiplicative);
			a.PushBack(GMDescPct(0.01 * (1 + bonus)));
			v = GMSkillBase(skill, 'duration') * (1 + GMEquippedSkillVal(GMTreeSkill(S_Magic_s18, S_Magic_s36), 'axii_duration_bonus')) * (1 + bonus);
			a.PushBack(GMDescNum(MaxF(3, v), 1));
			return GetLocStringByKeyExtWithParams("gm_skill_desc_axii", , , a);
		// Far-Reaching Aard: 5.x's classic text
		case S_Magic_s20:
			ai.PushBack(RoundMath(GMSkillVal(skill, 'range') * lvl));
			return GetLocStringByKeyExtWithParams("skill_desc_magic_s20", ai);
		// Aard Sweep: the intensity penalty, 40/20/0% (SKL-08)
		case S_Magic_s01:
			v = -GMSkillVal(skill, 'spell_power') - GMSkillVal(skill, 'spell_power_penalty_reduction') * (lvl - 1);
			if(v <= 0.001)
				return GetLocStringByKeyExt("gm_skill_desc_aard_sweep_3");
			ai.PushBack(RoundMath(v * 100));
			return GetLocStringByKeyExtWithParams("gm_skill_desc_aard_sweep", ai);
		// Aard Intensity
		case S_Magic_s12:
		case S_Magic_s39:
			ai.PushBack(RoundMath(GMSkillVal(skill, 'heavy_knockdown_chance_bonus') * lvl * 100));
			return GetLocStringByKeyExtWithParams("gm_skill_desc_aard_intensity", ai);
		// Shock Wave
		case S_Magic_s06:
		case S_Magic_s33:
			ai.PushBack(RoundMath(GMSkillVal(skill, 'ForceDamage') * lvl));
			return GetLocStringByKeyExtWithParams("gm_skill_desc_shock_wave", ai);
		// Melt Armor: one stack per level at x1 intensity, 15 s
		case S_Magic_s08:
			dm.GetAbilityAttributeValue(witcher.GMMeltArmorStackAbility(), 'armor', min, max);
			a.PushBack(GMDescNum(-min.valueAdditive * lvl, 1));
			dm.GetAbilityAttributeValue(witcher.GMMeltArmorStackAbility(), 'physical_resistance_perc', min, max);
			a.PushBack(GMDescPct(-min.valueAdditive * lvl));
			dm.GetAbilityAttributeValue('GMMeltArmorDebuffEffect', 'duration', min, max);
			a.PushBack(GMDescNum(min.valueAdditive, 1));
			return GetLocStringByKeyExtWithParams("gm_skill_desc_melt_armor", , , a);
		// Firestream
		case S_Magic_s02:
		case S_Magic_s28:
			ai.PushBack(RoundMath(GMSkillVal(skill, 'channeling_damage') + GMSkillVal(skill, 'channeling_damage_after_1') * (lvl - 1)));
			ai.PushBack(RoundMath(GMSkillVal(skill, 'stamina_cost_per_sec') * (1 - GMSkillVal(skill, 'stamina_cost_reduction_after_1') * (lvl - 1))));
			return GetLocStringByKeyExtWithParams("gm_skill_desc_firestream", ai);
		// Igni Intensity
		case S_Magic_s07:
		case S_Magic_s35:
			ai.PushBack(RoundMath(GMSkillVal(skill, 'fire_damage_bonus') * lvl));
			ai.PushBack(RoundMath(GMSkillVal(skill, 'channeling_damage_bonus') * lvl));
			return GetLocStringByKeyExtWithParams("gm_skill_desc_igni_intensity", ai);
		// Pyromaniac
		case S_Magic_s09:
		case S_Magic_s41:
			ai.PushBack(RoundMath(GMSkillVal(skill, 'chance_bonus') * lvl * 100));
			return GetLocStringByKeyExtWithParams("gm_skill_desc_pyromaniac", ai);
		// Sustained Glyphs: +30% radius from level 2, a second trap at level 3
		case S_Magic_s10:
		case S_Magic_s42:
			ai.PushBack(RoundMath(GMSkillVal(skill, 'trap_duration_bonus') * lvl * 100));
			if(lvl < 2)
				return GetLocStringByKeyExtWithParams("gm_skill_desc_sustained_glyphs_1", ai);
			ai.PushBack(RoundMath(GMSkillVal(skill, 'range_bonus') * 100));
			if(lvl < 3)
				return GetLocStringByKeyExtWithParams("gm_skill_desc_sustained_glyphs_2", ai);
			return GetLocStringByKeyExtWithParams("gm_skill_desc_sustained_glyphs_3", ai);
		// Magic Turret (legacy's name; 5.x: Magic Trap), with the equipped Yrden Intensity
		case S_Magic_s03:
			v = GMSkillVal(skill, 'ShockDamage') + GMSkillVal(skill, 'damage_bonus_flat_after_1') * (lvl - 1) + GMEquippedSkillVal(GMTreeSkill(S_Magic_s16, S_Magic_s37), 'turret_bonus_damage');
			ai.PushBack(RoundMath(v));
			ai.PushBack(14);	// the turret's range (legacy's text)
			sp = witcher.GetTotalSignSpellPower(S_Magic_3);
			ai.PushBack(RoundMath(v * sp.valueMultiplicative));
			ai.PushBack(RoundMath(GMSkillBase(skill, 'trap_duration') + GMSkillVal(skill, 'duration_bonus_flat_after_1') * (lvl - 1)));
			ai.PushBack(RoundMath(GMSkillBase(skill, 'charge_count') + GMSkillVal(skill, 'charge_bonus_flat_after_1') * (lvl - 1)));
			return GetLocStringByKeyExtWithParams("gm_skill_desc_magic_turret", ai);
		// Yrden Intensity
		case S_Magic_s16:
		case S_Magic_s37:
			ai.PushBack(RoundMath(GMSkillVal(skill, 'turret_bonus_damage') * lvl));
			return GetLocStringByKeyExtWithParams("gm_skill_desc_yrden_intensity", ai);
		// Supercharged Glyphs
		case S_Magic_s11:
			a.PushBack(GMDescPct(GMSkillVal(skill, 's11_dmg_bonus') * lvl));
			return GetLocStringByKeyExtWithParams("gm_skill_desc_supercharged_glyphs", , , a);
		// Exploding Shield: 30 shock damage per level above 1, the knockdown roll at level 3
		case S_Magic_s13:
			if(lvl < 2)
				return GetLocStringByKeyExt("skill_desc_magic_s13");
			v = GMSkillVal(skill, 'ShockDamage') * (lvl - 1);
			ai.PushBack(RoundMath(v));
			sp = witcher.GetTotalSignSpellPower(S_Magic_4);
			ai.PushBack(RoundMath(v * sp.valueMultiplicative));
			if(lvl < 3)
				return GetLocStringByKeyExtWithParams("gm_skill_desc_exploding_shield_2", ai);
			return GetLocStringByKeyExtWithParams("gm_skill_desc_exploding_shield_3", ai);
		// Active Shield: no stamina drain per second at level 3
		case S_Magic_s04:
			ai.PushBack(RoundMath((GMSkillVal(skill, 'shield_health_factor') - 1) * 100));
			if(lvl < 3)
				ai.PushBack(RoundMath(GMSkillVal(skill, 'stamina_cost_per_sec') * (1 - GMSkillVal(skill, 'stamina_cost_reduction_after_1') * (lvl - 1))));
			ai.PushBack(RoundMath(GMSkillVal(skill, 'shield_healing_factor') * lvl * 100));
			if(lvl < 3)
				return GetLocStringByKeyExtWithParams("gm_skill_desc_active_shield", ai);
			return GetLocStringByKeyExtWithParams("gm_skill_desc_active_shield_3", ai);
		// Quen Intensity
		case S_Magic_s15:
		case S_Magic_s38:
			ai.PushBack(RoundMath(GMSkillVal(skill, 'shield_health_bonus') * lvl));
			return GetLocStringByKeyExtWithParams("gm_skill_desc_quen_intensity", ai);
		// Quen Discharge: 5.x's classic text
		case S_Magic_s14:
		case S_Magic_s40:
			ai.PushBack(RoundMath(GMSkillVal(skill, 'discharge_percent') * lvl * 100));
			return GetLocStringByKeyExtWithParams("skill_desc_magic_s14", ai);
		// Delusion
		case S_Magic_s17:
			ai.PushBack(RoundMath(GMSkillVal(skill, 'slowdown_mod') * lvl * 100));
			ai.PushBack(RoundMath(GMSkillVal(skill, 'crit_chance_bonus') * lvl * 100));
			return GetLocStringByKeyExtWithParams("gm_skill_desc_delusion", ai);
		// Puppet: 10 s + 5 s per level above 1, at least 8 s, with Axii Intensity and Geralt's intensity
		case S_Magic_s05:
		case S_Magic_s31:
			v = GMSkillBase(skill, 'duration') + GMSkillBase(skill, 'duration_bonus_after1') * (lvl - 1);
			ai.PushBack(RoundMath(v));
			ai.PushBack(RoundMath(GMSkillVal(skill, 'attack_power') * lvl * 100));
			sp = witcher.GetTotalSignSpellPower(S_Magic_5);
			v2 = v * (1 + GMEquippedSkillVal(GMTreeSkill(S_Magic_s18, S_Magic_s36), 'axii_duration_bonus')) * (1 + GMSignPowerStatToPowerBonus(sp.valueMultiplicative));
			ai.PushBack(RoundMath(MaxF(8, v2)));
			return GetLocStringByKeyExtWithParams("gm_skill_desc_puppet", ai);
		// Axii Intensity
		case S_Magic_s18:
		case S_Magic_s36:
			ai.PushBack(RoundMath(GMSkillVal(skill, 'axii_duration_bonus') * lvl * 100));
			return GetLocStringByKeyExtWithParams("gm_skill_desc_axii_intensity", ai);
		// Domination: 25% weaker per missing level
		case S_Magic_s19:
			v = GMSkillVal(skill, 'duration') * (3 - lvl);
			if(v <= 0.001)
				return GetLocStringByKeyExt("gm_skill_desc_domination_3");
			ai.PushBack(RoundMath(v * 100));
			return GetLocStringByKeyExtWithParams("gm_skill_desc_domination", ai);
	}
	return "";
}

// Alchemy (core, both trees).
function GMAlchemySkillDescription(skill : ESkill, lvl : int) : string
{
	var a : array<string>;
	var ai : array<int>;
	var witcher : W3PlayerWitcher;
	var v : float;

	witcher = GetWitcherPlayer();
	switch(skill)
	{
		// Oil Preparation and Bomb Creation: legacy's texts (oils wear off to 50%, SKL-14)
		case S_Alchemy_2:
			ai.PushBack(RoundMath((1 - GMOilDecayFactor()) * 100));
			return GetLocStringByKeyExtWithParams("gm_skill_desc_alchemy_2", ai);
		case S_Alchemy_3:
			return GetLocStringByKeyExt("gm_skill_desc_alchemy_3");
		// Refreshment (classic alchemy_s1, the new tree's alchemy_s24)
		case S_Alchemy_s01:
		case S_Alchemy_s24:
			ai.PushBack(RoundMath(GMSkillVal(skill, 'stamina_gain_perc') * lvl * 100));
			return GetLocStringByKeyExtWithParams("gm_skill_desc_refreshment", ai);
		// Restoration
		case S_Alchemy_s02:
			ai.PushBack(RoundMath(GMSkillVal(skill, 'vitality_gain_perc') * lvl * 100));
			return GetLocStringByKeyExtWithParams("gm_skill_desc_restoration", ai);
		// Expert Brewer
		case S_Alchemy_s03:
			a.PushBack(GMDescNum(GMSkillVal(skill, 'toxicityReduction') * lvl, 1));
			return GetLocStringByKeyExtWithParams("gm_skill_desc_expert_brewer", , , a);
		// Prolonged Effects
		case S_Alchemy_s04:
			a.PushBack(GMDescPct(GMSkillVal(skill, 'gm_potion_duration') * lvl));
			return GetLocStringByKeyExtWithParams("gm_skill_desc_prolonged_effects", , , a);
		// Poisoned Blades and Protective Coating: plus 5% per oil level above 1, wearing off to 50%
		case S_Alchemy_s12:
		case S_Alchemy_s05:
			if(skill == S_Alchemy_s12)
			{
				ai.PushBack(RoundMath(GMSkillVal(skill, 'skill_chance') * lvl * 100));
				v = GMSkillVal(skill, 'oil_level_chance');
			}
			else
			{
				ai.PushBack(RoundMath(GMSkillVal(skill, 'defence_bonus') * lvl * 100));
				v = GMSkillVal(skill, 'oil_level_defence');
			}
			ai.PushBack(RoundMath(v * 100));
			ai.PushBack(RoundMath(v * 2 * 100));
			ai.PushBack(RoundMath(GMOilDecayFactor() * 100));
			if(skill == S_Alchemy_s12)
				return GetLocStringByKeyExtWithParams("gm_skill_desc_poisoned_blades", ai);
			return GetLocStringByKeyExtWithParams("gm_skill_desc_protective_coating", ai);
		// Fixative (classic alchemy_s6, the new tree's alchemy_s25): no wear at level 3, one oil at a time
		case S_Alchemy_s06:
		case S_Alchemy_s25:
			if(lvl >= 3)
				return GetLocStringByKeyExt("gm_skill_desc_fixative_3");
			ai.PushBack(RoundMath(GMSkillVal(skill, 'ammo_bonus') * lvl * 100));
			return GetLocStringByKeyExtWithParams("skill_desc_alchemy_s6", ai);
		// Hunter Instinct
		case S_Alchemy_s07:
		case S_Alchemy_s27:
			v = GMSkillVal(skill, theGame.params.CRITICAL_HIT_DAMAGE_BONUS) * lvl;
			a.PushBack(GMDescPct(v));
			a.PushBack(GMDescPct(v * 3));
			return GetLocStringByKeyExtWithParams("gm_skill_desc_hunter_instinct", , , a);
		// Steady Aim (classic alchemy_s9, the new tree's alchemy_s23): 5.x's classic text
		case S_Alchemy_s09:
		case S_Alchemy_s23:
			ai.PushBack(RoundMath(GMSkillVal(skill, 'slowdown_mod') * lvl * 100));
			return GetLocStringByKeyExtWithParams("skill_desc_alchemy_s9", ai);
		// Pyrotechnics, Efficiency, Cluster Bombs: 5.x's classic texts
		case S_Alchemy_s10:
			ai.PushBack(RoundMath(GMSkillVal(skill, 'PhysicalDamage') * lvl));
			return GetLocStringByKeyExtWithParams("skill_desc_alchemy_s10", ai);
		case S_Alchemy_s08:
			ai.PushBack(RoundMath(GMSkillVal(skill, 'gm_efficiency_base') + GMSkillVal(skill, 'gm_efficiency_per_level') * lvl));
			return GetLocStringByKeyExtWithParams("skill_desc_alchemy_s8", ai);
		case S_Alchemy_s11:
			ai.PushBack(RoundMath(GMSkillVal(skill, 'gm_fragments_base') + GMSkillVal(skill, 'gm_fragments_per_level') * lvl));
			return GetLocStringByKeyExtWithParams("skill_desc_alchemy_s11", ai);
		// Acquired Tolerance: the current bonus is the count of the skill's ability on Geralt
		case S_Alchemy_s18:
			ai.PushBack(RoundMath(GMSkillVal(skill, 'max_abs_per_lvl_s18') * lvl));
			ai.PushBack(witcher.GetAbilityCount(SkillEnumToName(S_Alchemy_s18)));
			return GetLocStringByKeyExtWithParams("gm_skill_desc_acquired_tolerance", ai);
		// Tissue Transmutation
		case S_Alchemy_s13:
			ai.PushBack(RoundMath(GMSkillVal(skill, 'vitality') * lvl));
			return GetLocStringByKeyExtWithParams("gm_skill_desc_tissue_transmutation", ai);
		// Adaptation
		case S_Alchemy_s14:
			a.PushBack(GMDescPct(GMSkillVal(skill, 'tox_off_bonus') * lvl));
			return GetLocStringByKeyExtWithParams("gm_skill_desc_adaptation", , , a);
		// Synergy: one copy of the mutagen's bonus per level; the new tree's level counted as 2, 3, 5 copies
		case S_Alchemy_s19:
		case S_Alchemy_s26:
			if(skill == S_Alchemy_s26)
				v = RoundMath(GMSkillVal(skill, 'gm_synergy_levels') * lvl);
			else
				v = lvl;
			ai.PushBack(RoundMath(v * GMSkillVal(S_Alchemy_s19, 'synergy_bonus') * 100));
			return GetLocStringByKeyExtWithParams("skill_desc_alchemy_s19", ai);
		// Frenzy
		case S_Alchemy_s16:
			a.PushBack(GMDescPct(GMSkillVal(skill, 'slowdown_ratio') * lvl));
			a.PushBack(GMDescNum(GMSkillVal(skill, 'slowdown_duration'), 1));
			a.PushBack(GMDescPct(GMSkillVal(skill, 'attack_power') * lvl));
			return GetLocStringByKeyExtWithParams("gm_skill_desc_frenzy", , , a);
		// Endure Pain: one copy of 5.x's +10% maximum Vitality per level; the new tree's counted as 2, 3, 5
		case S_Alchemy_s20:
			ai.PushBack(RoundMath(GMSkillVal(skill, 'gm_endure_pain_copies') * lvl) * 10);
			return GetLocStringByKeyExtWithParams("skill_desc_alchemy_s20", ai);
		// Fast Metabolism
		case S_Alchemy_s15:
			a.PushBack(GMDescNum(-GMSkillVal(skill, 'toxicityRegen') * lvl, 2));
			return GetLocStringByKeyExtWithParams("gm_skill_desc_fast_metabolism", , , a);
		// Killing Spree (classic alchemy_s17, the new tree's alchemy_s22): 5.x's classic text
		case S_Alchemy_s17:
		case S_Alchemy_s22:
			ai.PushBack(RoundMath(GMSkillVal(skill, theGame.params.CRITICAL_HIT_CHANCE) * lvl * 100));
			return GetLocStringByKeyExtWithParams("skill_desc_alchemy_s17", ai);
	}
	return "";
}

// General perks (both trees): legacy's perks at 1 level (SKL-18, D49), the classic slot and the new
// tree's slot of each perk sharing its text.
function GMPerkDescription(skill : ESkill, lvl : int) : string
{
	var a : array<string>;
	var ai : array<int>;
	var af : array<float>;
	var dm : CDefinitionsManagerAccessor;
	var min, max : SAbilityAttributeValue;

	switch(skill)
	{
		// Cold Blood, the classic tree's perk_2 (legacy swapped it with sword_s15)
		case S_Perk_02:
			return GetLocStringByKeyExt("gm_skill_desc_cold_blood_c");
		// Survival Instinct: +750 Vitality (D37)
		case S_Perk_04:
		case S_Perk_30:
			a.PushBack(GMDescNum(GMSkillBase(skill, 'vitality'), 0));
			return GetLocStringByKeyExtWithParams("gm_skill_desc_survival_instinct", , , a);
		// Cat, Griffin and Bear School: per armor piece of the class
		case S_Perk_05:
		case S_Perk_23:
			a.PushBack(GMDescPct(GMSkillVal(skill, theGame.params.CRITICAL_HIT_CHANCE)));
			a.PushBack(GMDescPct(GMSkillVal(skill, theGame.params.CRITICAL_HIT_DAMAGE_BONUS)));
			return GetLocStringByKeyExtWithParams("gm_skill_desc_cat_school", , , a);
		case S_Perk_06:
		case S_Perk_24:
			a.PushBack(GMDescPct(GMSkillVal(skill, 'spell_power')));
			a.PushBack(GMDescPct(GMSkillVal(skill, 'perk_6_stamina_cost_reduction')));
			return GetLocStringByKeyExtWithParams("gm_skill_desc_griffin_school", , , a);
		// Bear School: its exact values (7.5% and 0.025 per piece), not rounded
		case S_Perk_07:
		case S_Perk_25:
			a.PushBack(GMDescNum(GMSkillVal(skill, 'vitality') * 100, 1));
			a.PushBack(GMDescNum(GMSkillVal(skill, 'bonus_focus_gain'), 3));
			return GetLocStringByKeyExtWithParams("gm_skill_desc_bear_school", , , a);
		// Rage Management (5.x's new-tree name: Anger Management)
		case S_Perk_09:
		case S_Perk_34:
			return GetLocStringByKeyExt("gm_skill_desc_rage_management");
		// Adrenaline Burst
		case S_Perk_10:
		case S_Perk_42:
			ai.PushBack(RoundMath(GMSkillVal(skill, 'focus_gain') * 100));
			ai.PushBack(RoundMath(GMSkillVal(skill, 'stamina_cost_reduction') * 100));
			return GetLocStringByKeyExtWithParams("gm_skill_desc_adrenaline_burst", ai);
		// Focus (the new tree's on perk_37, D40)
		case S_Perk_11:
		case S_Perk_37:
			ai.PushBack(RoundMath(GMSkillVal(skill, 'spell_power') * 100));
			return GetLocStringByKeyExtWithParams("gm_skill_desc_focus", ai);
		// Metabolic Control: 5.x's classic text
		case S_Perk_12:
		case S_Perk_33:
			ai.PushBack(RoundMath(GMSkillBase(skill, 'toxicity')));
			return GetLocStringByKeyExtWithParams("skill_desc_perk_12", ai);
		// Metabolism Boosts: 5.x's classic text, 33.4% per point (SKL-18)
		case S_Perk_13:
		case S_Perk_32:
			ai.PushBack(RoundMath(GMSkillVal(skill, 'cost_reduction') * 100));
			return GetLocStringByKeyExtWithParams("skill_desc_perk_13", ai);
		// Gorged on Power (the new tree's on perk_43, D61): 5.x's classic text
		case S_Perk_14:
		case S_Perk_43:
			return GetLocStringByKeyExt("skill_desc_perk_14");
		// Gourmet: 5.x's perk until Connoisseur is ported (FOOD); its argument, which 5.x's new menu lacks
		case S_Perk_15:
			min = GetWitcherPlayer().GetSkillAttributeValue(S_Perk_15, 'duration', false, false);
			a.PushBack(GMDescNum(min.valueAdditive / 60, 0));
			return GetLocStringByKeyExtWithParams("skill_desc_perk_15", , , a);
		// In Combat's Fires (the new tree's on perk_44, D38, D61)
		case S_Perk_16:
		case S_Perk_44:
			return GetLocStringByKeyExt("gm_skill_desc_in_combats_fires");
		// Trick Shot (the new tree's on perk_27, D61): 5.x's classic text
		case S_Perk_17:
		case S_Perk_27:
			return GetLocStringByKeyExt("skill_desc_perk_17");
		// Advanced Pyrotechnics (D39)
		case S_Perk_18:
		case S_Perk_39:
			af.PushBack(GMSkillVal(skill, 'gm_bomb_focus_gain'));
			return GetLocStringByKeyExtWithParams("gm_skill_desc_advanced_pyrotechnics", , af);
		// Battle Frenzy: 5.x's classic text, its argument (5.x's new menu shows it raw)
		case S_Perk_19:
		case S_Perk_40:
			ai.PushBack(RoundMath(GMSkillVal(skill, theGame.params.CRITICAL_HIT_CHANCE) * 100));
			return GetLocStringByKeyExtWithParams("skill_desc_perk_19", ai);
		// Heavy Artillery (the new tree's on perk_28, D61): +100% bomb damage, stacks halved
		case S_Perk_20:
		case S_Perk_28:
			a.PushBack(GMDescPct(GMSkillVal(skill, 'dmg_multiplier')));
			return GetLocStringByKeyExtWithParams("gm_skill_desc_heavy_artillery", , , a);
		// Attack is the Best Defense: stamina, 2.5 s cooldown for crits and counters
		case S_Perk_21:
		case S_Perk_31:
			ai.PushBack(RoundMath(GMSkillVal(skill, 'stamina_kill') * 100));
			ai.PushBack(RoundMath(GMSkillVal(skill, 'stamina_other') * 100));
			dm = theGame.GetDefinitionsManager();
			dm.GetAbilityAttributeValue('Perk21InternalCooldownEffect', 'duration', min, max);
			a.PushBack(GMDescNum(min.valueAdditive, 1));
			return GetLocStringByKeyExtWithParams("gm_skill_desc_attack_best_defense", ai, , a);
		// Strong Back: 5.x's classic text
		case S_Perk_22:
		case S_Perk_35:
			ai.PushBack(RoundMath(GMSkillBase(skill, 'encumbrance')));
			return GetLocStringByKeyExtWithParams("skill_desc_perk_22", ai);
		// new design: Wolf School (D61), the totals with four medium armor pieces
		case S_Perk_26:
			a.PushBack(GMDescPct(GMSkillVal(skill, 'gm_wolf_crit_chance') * 4));
			a.PushBack(GMDescPct(GMSkillVal(skill, 'gm_wolf_crit_damage') * 4));
			a.PushBack(GMDescPct(GMSkillVal(skill, 'gm_wolf_bomb_damage') * 4));
			return GetLocStringByKeyExtWithParams("gm_skill_desc_wolf_school", , , a);
	}
	return "";
}
