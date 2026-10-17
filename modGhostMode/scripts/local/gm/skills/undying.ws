// SKL-07: Undying, legacy's in both trees (D15, project owner, 2026-10-09). When a hit would kill
// Geralt with at least 1 adrenaline point and no Undying effect or cooldown running, the hit is
// cancelled and Vitality set to 1; 5 s of immortality follow (EET_GMUndyingImmortal) with immunity to
// negative effects and no adrenaline gain, healing a share of maximum Vitality per second per level
// per whole adrenaline point (classic 1%, new tree 1.667%), all adrenaline spent; then a 120 s cooldown
// (EET_GMUndyingCooldown), both with a HUD icon. 5.x's Undying (an instant heal, Battle Trance buff
// needed, 30 s) never fires. Kill sources that bypass it are 5.x's (quests, kill triggers, traps,
// falling). See docs/features/skl.md.

// Legacy's own immortality channel (AIC_UndyingSkill = 256 in legacy's EActorImmortalityChanel);
// a mod enum member cannot take an explicit value, and the channels are bit flags.
function GMUndyingImmortalityChannel() : EActorImmortalityChannel
{
	return (EActorImmortalityChannel)256;
}

class W3GMEffect_UndyingImmortal extends CBaseGameplayEffect
{
	default effectType = EET_GMUndyingImmortal;
	default isPositive = true;
	default dontAddAbilityOnTarget = true;

	event OnEffectAdded(optional customParams : W3BuffCustomParams)
	{
		var witcher : W3PlayerWitcher;

		super.OnEffectAdded(customParams);
		witcher = (W3PlayerWitcher)target;
		if(witcher)
		{
			witcher.SetImmortalityMode(AIM_Immortal, GMUndyingImmortalityChannel());
			witcher.AddBuffImmunity_AllNegative('GMUndyingImmunity', true);
			witcher.AddAbilityMultiple(witcher.GMUndyingRegenAbility(), FloorF(witcher.GetStat(BCS_Focus)) * witcher.GetSkillLevel(S_Sword_s18));
			witcher.DrainFocus(witcher.GetStat(BCS_Focus));
			witcher.ResumeHPRegenEffects('', true);
			witcher.StartVitalityRegen();	// the cancelled hit started none (legacy's ability manager did)
		}
	}

	event OnEffectRemoved()
	{
		var witcher : W3PlayerWitcher;

		witcher = (W3PlayerWitcher)target;
		if(witcher)
			witcher.RemoveAbilityAll(witcher.GMUndyingRegenAbility());
		target.SetImmortalityMode(AIM_None, GMUndyingImmortalityChannel());
		target.RemoveBuffImmunity_AllNegative('GMUndyingImmunity');
		target.AddEffectDefault(EET_GMUndyingCooldown, NULL, "GMUndyingCooldown");
		super.OnEffectRemoved();
	}
}

class W3GMEffect_UndyingCooldown extends CBaseGameplayEffect
{
	default effectType = EET_GMUndyingCooldown;
	default isNegative = true;
	default dontAddAbilityOnTarget = true;

	protected function CalculateDuration(optional setInitialDuration : bool)
	{
		if(!isOnPlayer)
			return;
		duration = CalculateAttributeValue(GetWitcherPlayer().GetSkillAttributeValue(S_Sword_s18, 'trigger_delay', false, true));
		if(setInitialDuration)
			initialDuration = duration;
	}
}

// The regen ability, added once per level per whole adrenaline point: classic 1% of maximum Vitality
// per second, new tree 1.667%.
@addMethod(W3PlayerWitcher)
function GMUndyingRegenAbility() : name
{
	if(GMIsClassicTreeAbility(GMGetSkillAbilityName(S_Sword_s18)))
		return 'GMUndyingRegen';
	return 'GMUndyingRegenNewTree';
}

@addMethod(W3PlayerWitcher)
function GMCanUseUndying() : bool
{
	return CanUseSkill(S_Sword_s18) && GetStat(BCS_Focus) >= 1 && !HasBuff(EET_GMUndyingImmortal) && !HasBuff(EET_GMUndyingCooldown);
}

@wrapMethod(W3PlayerWitcher)
function OnTakeDamage(action : W3DamageAction)
{
	var killSourceName : string;

	killSourceName = action.GetBuffSourceName();
	if(action.processedDmg.vitalityDamage >= GetStat(BCS_Vitality) && killSourceName != "Quest" && killSourceName != "Kill Trigger" && killSourceName != "Trap" && killSourceName != "FallingDamage" && GMCanUseUndying())
	{
		action.SetAllProcessedDamageAs(0);
		ForceSetStat(BCS_Vitality, 1);
		AddEffectDefault(EET_GMUndyingImmortal, NULL, "GMUndyingSkill");
	}
	SetCannotUseUndyingSkill(true);	// 5.x's Undying is replaced
	wrappedMethod(action);
}

// No adrenaline gain during Undying (legacy).
@wrapMethod(W3PlayerAbilityManager)
function GainStat(stat : EBaseCharacterStats, amount : float)
{
	if(stat == BCS_Focus && amount > 0 && owner.HasBuff(EET_GMUndyingImmortal))
		return;
	wrappedMethod(stat, amount);
}

// Undying's healing goes on when Geralt is hit during the 5 s (legacy's exemption in
// ShouldPauseHealthRegenOnHit, SKL audit F1).
@wrapMethod(W3PlayerWitcher)
function ShouldPauseHealthRegenOnHit() : bool
{
	var pause : bool;

	pause = wrappedMethod();
	if(HasBuff(EET_GMUndyingImmortal))
		return false;
	return pause;
}
