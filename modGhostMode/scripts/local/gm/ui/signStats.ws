// UI-03: the sign lines of the stats popup and the inventory's stats view (legacy's AddCharacterStatSigns):
// per sign its intensity and every value with all its modifiers, as the cast gets them in Ghost Mode, raw
// before the target's resistances: Aard knockdown and heavy knockdown chance (Metamorphosis, Aard Intensity),
// Shock Wave's force damage; Igni's burn chance (Pyromaniac, Rotation, Metamorphosis), fire damage (Igni
// Intensity, Rotation), Firestream's damage per second; Quen's intensity (Wraith), duration, absorption,
// the active shield's absorption, Exploding Shield's damage, Quen Discharge's share (Retribution); Yrden's
// intensity, traps, duration and range (Sustained Glyphs, the Griffin set), slowdown, the turret's
// duration, charges and damage (Yrden Intensity); Axii's intensity, confusion and control durations (Axii
// Intensity, Puppet) and the instant-kill chance. Damage lines add the flat sign terms of the damage pool
// (Mutation 1, Foglet, Euphoria) and spell_dmg_bonus (SWD-07), times the sign's intensity. Each skill is
// read from either tree. The sections are built in GetPlayerStatsGFxData (ui/characterStatsPopup.ws).
// See docs/features/ui.md.

// The first of a classic skill and its new-tree counterpart that Geralt can use; S_SUndefined if none.
function GMPanelSkill(classic : ESkill, newTree : ESkill) : ESkill
{
	var w : W3PlayerWitcher;

	w = GetWitcherPlayer();
	if(w.CanUseSkill(classic))
		return classic;
	if(newTree != S_SUndefined && w.CanUseSkill(newTree))
		return newTree;
	return S_SUndefined;
}

// A skill attribute times the skill's level; 0 without the skill.
function GMPanelSkillPerLevel(skill : ESkill, attr : name, mods : bool) : float
{
	var w : W3PlayerWitcher;

	if(skill == S_SUndefined)
		return 0;
	w = GetWitcherPlayer();
	return CalculateAttributeValue(w.GetSkillAttributeValue(skill, attr, false, mods)) * w.GetSkillLevel(skill);
}

// The flat terms the damage pool adds to every sign hit (per second for damage over time): Mutation 1's
// share of the held sword's damage, Foglet's bonus, Euphoria's overdose drain (damage/pool.ws).
function GMPanelSignFlatDamage() : float
{
	var w : W3PlayerWitcher;
	var sword : SItemUniqueId;
	var min, max : SAbilityAttributeValue;
	var flat, swordDmg : float;

	w = GetWitcherPlayer();
	if(w.IsMutationActive(EPMT_Mutation1))
	{
		sword = w.inv.GetCurrentlyHeldSword();
		if(w.inv.GetItemCategory(sword) == 'steelsword')
			swordDmg = w.GetTotalWeaponDamage(sword, theGame.params.DAMAGE_NAME_SLASHING, GetInvalidUniqueId());
		else if(w.inv.GetItemCategory(sword) == 'silversword')
			swordDmg = w.GetTotalWeaponDamage(sword, theGame.params.DAMAGE_NAME_SILVER, GetInvalidUniqueId());
		theGame.GetDefinitionsManager().GetAbilityAttributeValue('Mutation1', 'dmg_bonus_factor', min, max);
		flat += swordDmg * CalculateAttributeValue(min);
	}
	if(w.HasBuff(EET_Mutagen09))
		flat += ((W3Mutagen09_Effect)w.GetBuff(EET_Mutagen09)).GMGetM09Bonus();
	if(w.IsMutationActive(EPMT_Mutation10) && w.HasBuff(EET_Mutation10))
		flat += w.GMGetToxicityDamage();
	return flat;
}

// A sign hit's damage: (base + the flat terms) x (1 + spell_dmg_bonus) x the sign's intensity.
function GMPanelSignDamage(base : float, signSkill : ESkill) : float
{
	var w : W3PlayerWitcher;
	var sp : SAbilityAttributeValue;

	w = GetWitcherPlayer();
	sp = w.GetTotalSignSpellPower(signSkill);
	return (base + GMPanelSignFlatDamage()) * (1 + CalculateAttributeValue(w.GetAttributeValue('spell_dmg_bonus'))) * sp.valueMultiplicative;
}

function GMPanelPercent(value : float) : string
{
	return (string)RoundMath(value * 100) + " %";
}

function GMPanelSeconds(value : float) : string
{
	return FloatToStringPrec(value, 1) + GetLocStringByKeyExt("per_second");
}

// Petri's Philtre level 3: signs' shields, traps and effects last a third longer (ALCH-06).
function GMPanelPetriMult() : float
{
	if(GetWitcherPlayer().GetPotionBuffLevel(EET_PetriPhiltre) == 3)
		return 1.34;
	return 1;
}

// Aard's knockdown chance as rolled before the target's resistances (skills/aard.ws).
function GMPanelAardKnockdownChance() : float
{
	var w : W3PlayerWitcher;
	var sp : SAbilityAttributeValue;
	var chance : float;

	w = GetWitcherPlayer();
	sp = w.GetTotalSignSpellPower(S_Magic_1);
	chance = CalculateAttributeValue(w.GetSkillAttributeValue(S_Magic_1, 'starting_knockdown_chance', false, false));
	chance = ClampF(chance * (1 + GMSignPowerStatToPowerBonus(sp.valueMultiplicative)), 0.1, 1.0);
	return MinF(1.0, chance * w.GMMutation12ChanceMult());
}

// Quen's absorption (W3QuenEntity.GetSignStats): shield health with Quen Intensity, scaled by the intensity
// (with Wraith's bonus).
function GMPanelQuenAbsorption() : float
{
	var w : W3PlayerWitcher;
	var sp : SAbilityAttributeValue;
	var health : float;

	w = GetWitcherPlayer();
	sp = w.GetTotalSignSpellPower(S_Magic_4);
	if(w.HasBuff(EET_Mutagen19))
		sp += ((W3Mutagen19_Effect)w.GetBuff(EET_Mutagen19)).GMGetQuenPowerBonus();
	health = CalculateAttributeValue(w.GetSkillAttributeValue(S_Magic_4, 'shield_health', false, true));
	health += GMPanelSkillPerLevel(GMPanelSkill(S_Magic_s15, S_Magic_s38), 'shield_health_bonus', true);
	return health * (1 + GMSignPowerStatToPowerBonus(sp.valueMultiplicative));
}

// An Axii duration (W3AxiiEntity.OnEnded): the skill's duration (Puppet's per level above 1), Axii
// Intensity, the intensity bonus, Petri's Philtre.
function GMPanelAxiiDuration(skill : ESkill) : float
{
	var w : W3PlayerWitcher;
	var duration, sp : SAbilityAttributeValue;
	var dur : float;

	w = GetWitcherPlayer();
	duration = w.GetSkillAttributeValue(skill, 'duration', false, true);
	if(skill != S_Magic_5)
		duration += w.GetSkillAttributeValue(skill, 'duration_bonus_after1', false, true) * (w.GetSkillLevel(skill) - 1);
	duration.valueMultiplicative = 1.0f;
	dur = CalculateAttributeValue(duration);
	dur *= 1 + GMPanelSkillPerLevel(GMPanelSkill(S_Magic_s18, S_Magic_s36), 'axii_duration_bonus', false);
	sp = w.GetTotalSignSpellPower(S_Magic_5);
	return dur * (1 + GMSignPowerStatToPowerBonus(sp.valueMultiplicative)) * GMPanelPetriMult();
}

// The value of a sign line (legacy's keys); found tells whether the key is one of them.
function GMPanelSignValue(varKey : name, out found : bool) : string
{
	var w : W3PlayerWitcher;
	var sp, min, max : SAbilityAttributeValue;
	var skill, sustained : ESkill;
	var value, base : float;
	var level : int;

	w = GetWitcherPlayer();
	found = true;
	switch(varKey)
	{
		case 'aard_power' :
			sp = w.GetTotalSignSpellPower(S_Magic_1);
			return GMPanelPercent(MaxF(sp.valueMultiplicative - 1, 0));
		case 'aard_knockdownchance' :
			return GMPanelPercent(GMPanelAardKnockdownChance());
		case 'aard_heavyknockdownchance' :
			value = 0.15;
			skill = GMPanelSkill(S_Magic_s12, S_Magic_s39);
			if(skill != S_SUndefined)
			{
				sp = w.GetSkillAttributeValue(skill, 'heavy_knockdown_chance_bonus', false, false);
				value += sp.valueMultiplicative * w.GetSkillLevel(skill);
			}
			return GMPanelPercent(value * GMPanelAardKnockdownChance());
		case 'aard_damage' :
			skill = GMPanelSkill(S_Magic_s06, S_Magic_s33);
			if(skill == S_SUndefined)
				return "0";
			base = w.GetSkillLevel(skill) * CalculateAttributeValue(w.GetSkillAttributeValue(skill, theGame.params.DAMAGE_NAME_FORCE, false, true));
			return (string)RoundMath(GMPanelSignDamage(base, S_Magic_1));

		case 'igni_power' :
			sp = w.GetTotalSignSpellPower(S_Magic_2);
			return GMPanelPercent(MaxF(sp.valueMultiplicative - 1, 0));
		case 'igni_burnchance' :
			value = CalculateAttributeValue(w.GetSkillAttributeValue(S_Magic_2, 'initial_burn_chance', false, true));
			value += GMPanelSkillPerLevel(w.GMPyromaniacSkill(), 'chance_bonus', true);
			if(w.HasGlyphwordActive('Glyphword 7 _Stats'))
				value += GMRotationValue('glyphword7_burnchance_debuff');
			return GMPanelPercent(MaxF(0, value) * w.GMMutation12ChanceMult());
		case 'igni_damage' :
			base = CalculateAttributeValue(w.GetSkillAttributeValue(S_Magic_2, theGame.params.DAMAGE_NAME_FIRE, false, true));
			base += GMPanelSkillPerLevel(w.GMIgniIntensitySkill(), 'fire_damage_bonus', false);
			if(w.HasGlyphwordActive('Glyphword 7 _Stats'))
				base += GMRotationValue('glyphword7_dmg_buff');
			return (string)RoundMath(GMPanelSignDamage(base, S_Magic_2));
		case 'igni_dmg_alt' :
			skill = GMPanelSkill(S_Magic_s02, S_Magic_s28);
			if(skill == S_SUndefined)
				return "0";
			sp = w.GetSkillAttributeValue(skill, 'channeling_damage', false, false);
			sp += w.GetSkillAttributeValue(skill, 'channeling_damage_after_1', false, false) * (w.GetSkillLevel(skill) - 1);
			base = sp.valueAdditive + GMPanelSkillPerLevel(w.GMIgniIntensitySkill(), 'channeling_damage_bonus', false);
			return (string)RoundMath(GMPanelSignDamage(base, skill));

		case 'quen_power' :
			sp = w.GetTotalSignSpellPower(S_Magic_4);
			if(w.HasBuff(EET_Mutagen19))
				sp += ((W3Mutagen19_Effect)w.GetBuff(EET_Mutagen19)).GMGetQuenPowerBonus();
			return GMPanelPercent(MaxF(sp.valueMultiplicative - 1, 0));
		case 'quen_duration' :
			value = CalculateAttributeValue(w.GetSkillAttributeValue(S_Magic_4, 'shield_duration', true, true)) * GMPanelPetriMult();
			return (string)RoundMath(value) + GetLocStringByKeyExt("per_second");
		case 'quen_discharge_pts' :
			if(!w.CanUseSkill(S_Magic_s13) || w.GetSkillLevel(S_Magic_s13) < 2)
				return "0";
			base = CalculateAttributeValue(w.GetSkillAttributeValue(S_Magic_s13, 'ShockDamage', false, true)) * (w.GetSkillLevel(S_Magic_s13) - 1);
			base *= 1 + GMRetributionBoost(w);
			return (string)RoundMath(GMPanelSignDamage(base, S_Magic_4));
		case 'quen_discharge_percent' :
			value = GMPanelSkillPerLevel(GMPanelSkill(S_Magic_s14, S_Magic_s40), 'discharge_percent', true);
			return GMPanelPercent(value * (1 + GMRetributionBoost(w)));
		case 'quen_damageabs' :
			return (string)RoundMath(GMPanelQuenAbsorption());
		case 'quen_damageabs_alt' :
			if(!w.CanUseSkill(S_Magic_s04))
				return "0";
			value = GMPanelQuenAbsorption() * CalculateAttributeValue(w.GetSkillAttributeValue(S_Magic_s04, 'shield_health_factor', false, true));
			return (string)RoundMath(value);

		case 'yrden_power' :
			sp = w.GetTotalSignSpellPower(S_Magic_3);
			return GMPanelPercent(MaxF(sp.valueMultiplicative - 1, 0));
		case 'yrden_traps' :
			sustained = GMPanelSkill(S_Magic_s10, S_Magic_s42);
			if(sustained != S_SUndefined && w.GetSkillLevel(sustained) >= 3)
				return "2";
			return "1";
		case 'yrden_duration' :
			value = CalculateAttributeValue(w.GetSkillAttributeValue(S_Magic_3, 'trap_duration', false, false));
			value *= 1 + GMPanelSkillPerLevel(GMPanelSkill(S_Magic_s10, S_Magic_s42), 'trap_duration_bonus', false);
			return GMPanelSeconds(value * GMPanelPetriMult());
		case 'yrden_range' :
			value = CalculateAttributeValue(w.GetSkillAttributeValue(S_Magic_3, 'range', false, false));
			sustained = GMPanelSkill(S_Magic_s10, S_Magic_s42);
			if(sustained != S_SUndefined && w.GetSkillLevel(sustained) >= 2)
				value *= 1 + CalculateAttributeValue(w.GetSkillAttributeValue(sustained, 'range_bonus', false, false));
			if(w.IsSetBonusActive(EISB_Gryphon_2))
			{
				theGame.GetDefinitionsManager().GetAbilityAttributeValue('GryphonSetBonusYrdenEffect', 'trigger_scale', min, max);
				value *= min.valueAdditive;
			}
			return FloatToStringPrec(value, 1);
		case 'yrden_slowdown' :
			sp = w.GetTotalSignSpellPower(S_Magic_3);
			value = CalculateAttributeValue(w.GetSkillAttributeValue(S_Magic_3, 'min_starting_slowdown', false, false));
			value *= 1 + GMSignPowerStatToPowerBonus(sp.valueMultiplicative);
			value = ClampF(value, CalculateAttributeValue(w.GetSkillAttributeValue(S_Magic_3, 'min_slowdown', false, false)), CalculateAttributeValue(w.GetSkillAttributeValue(S_Magic_3, 'max_slowdown', false, false)));
			return GMPanelPercent(value);
		case 'yrden_duration_alt' :
			if(!w.CanUseSkill(S_Magic_s03))
				return GMPanelSeconds(0);
			level = w.GetSkillLevel(S_Magic_s03);
			value = CalculateAttributeValue(w.GetSkillAttributeValue(S_Magic_s03, 'trap_duration', false, false));
			value += CalculateAttributeValue(w.GetSkillAttributeValue(S_Magic_s03, 'duration_bonus_flat_after_1', false, false)) * (level - 1);
			return GMPanelSeconds(value * GMPanelPetriMult());
		case 'yrden_charges' :
			if(!w.CanUseSkill(S_Magic_s03))
				return "0";
			level = w.GetSkillLevel(S_Magic_s03);
			value = CalculateAttributeValue(w.GetSkillAttributeValue(S_Magic_s03, 'charge_count', false, true));
			value += CalculateAttributeValue(w.GetSkillAttributeValue(S_Magic_s03, 'charge_bonus_flat_after_1', false, false)) * (level - 1);
			return (string)RoundMath(value);
		case 'yrden_damage' :
			if(!w.CanUseSkill(S_Magic_s03))
				return "0";
			level = w.GetSkillLevel(S_Magic_s03);
			base = CalculateAttributeValue(w.GetSkillAttributeValue(S_Magic_s03, theGame.params.DAMAGE_NAME_SHOCK, false, true));
			base += CalculateAttributeValue(w.GetSkillAttributeValue(S_Magic_s03, 'damage_bonus_flat_after_1', false, false)) * (level - 1);
			base += GMPanelSkillPerLevel(GMPanelSkill(S_Magic_s16, S_Magic_s37), 'turret_bonus_damage', true);
			return (string)RoundMath(GMPanelSignDamage(base, S_Magic_3));

		case 'axii_power' :
			sp = w.GetTotalSignSpellPower(S_Magic_5);
			return GMPanelPercent(MaxF(sp.valueMultiplicative - 1, 0));
		case 'axii_duration_confusion' :
			return GMPanelSeconds(GMPanelAxiiDuration(S_Magic_5));
		case 'axii_instakill' :
			sp = w.GetTotalSignSpellPower(S_Magic_5);
			return (string)RoundMath(1 + GMSignPowerStatToPowerBonus(sp.valueMultiplicative)) + " %";
		case 'axii_duration_control' :
			skill = GMPanelSkill(S_Magic_s05, S_Magic_s31);
			if(skill == S_SUndefined)
				return GMPanelSeconds(0);
			return GMPanelSeconds(GMPanelAxiiDuration(skill));
	}
	found = false;
	return "";
}

// The sign lines: 5.x builds the object, Ghost Mode's value replaces its value; a name without a string
// shows its key (legacy).
@wrapMethod
function AddCharacterStatSigns(tag : string, varKey : name, locKey : string, iconTag : string, toArray : CScriptedFlashArray, flashMaster : CScriptedFlashValueStorage) : CScriptedFlashObject
{
	var statObject : CScriptedFlashObject;
	var value : string;
	var found : bool;

	statObject = wrappedMethod(tag, varKey, locKey, iconTag, toArray, flashMaster);
	value = GMPanelSignValue(varKey, found);
	if(found)
		statObject.SetMemberFlashString("value", value);
	if(statObject.GetMemberFlashString("name") == "" && locKey != "")
		statObject.SetMemberFlashString("name", locKey);
	return statObject;
}
