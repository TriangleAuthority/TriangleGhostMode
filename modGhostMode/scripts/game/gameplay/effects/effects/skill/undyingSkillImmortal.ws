class W3Effect_UndyingSkillImmortal extends CBaseGameplayEffect
{
	default effectType = EET_UndyingSkillImmortal;
	default isPositive = true;
	default dontAddAbilityOnTarget = true;
	
	event OnEffectAdded( customParams : W3BuffCustomParams )
	{
		var witcher : W3PlayerWitcher;
	
		super.OnEffectAdded( customParams );
		witcher = (W3PlayerWitcher)target;
		witcher.SetImmortalityMode( AIM_Immortal, AIC_UndyingSkill );
		witcher.AddBuffImmunity_AllNegative('UndyingImmunity', true);
		witcher.AddAbilityMultiple(abilityName, FloorF(witcher.GetStat(BCS_Focus)) * witcher.GetSkillLevel(S_Sword_s18));
		witcher.DrainFocus(witcher.GetStat(BCS_Focus));
		//handled properly by ability manager now
		//if(witcher.HasBuff(EET_AutoVitalityRegen))
		//	((W3Effect_AutoVitalityRegen)witcher.GetBuff(EET_AutoVitalityRegen)).UpdateEffectValue();
		//else
		//	target.StartVitalityRegen();
		witcher.ResumeHPRegenEffects('', true);
	}
	
	event OnEffectRemoved()
	{
		target.RemoveAbilityAll(abilityName);
		target.SetImmortalityMode( AIM_None, AIC_UndyingSkill );
		target.RemoveBuffImmunity_AllNegative('UndyingImmunity');
		target.AddEffectDefault( EET_UndyingSkillCooldown, NULL, "UndyingCooldown" );
		//handled properly by ability manager now
		//if(target.HasBuff(EET_AutoVitalityRegen))
		//	((W3Effect_AutoVitalityRegen)target.GetBuff(EET_AutoVitalityRegen)).UpdateEffectValue();
		super.OnEffectRemoved();
	}
}