// SKL-17: the Trial of the Grasses skills, legacy's in both trees (D34, D60, project owner, 2026-10-09).
// - Frenzy (alchemy_s16; classic GM_C_alchemy_s16, 5 levels): with toxicity above 0, time slows by 15% per
//   level (new tree 25%) for 1.5 s when an enemy starts a counterattack on Geralt, whether or not he could
//   dodge (5.x: 0.48 - 12% per level, 0.3 s per level, only when a dodge or roll is allowed); while
//   overdosed, +5% attack power and sign intensity per level (new tree 8.33%): one copy of the skill's
//   ability per level on Geralt, kept in step by the toxicity effect and the skill hooks.
// - Endure Pain (alchemy_s20; classic GM_C_alchemy_s20, 5 levels): +10% maximum Vitality per level while
//   overdosed (5.x's effect, one copy of IgnorePainEffect per level); the new tree's level counts as 2, 3
//   and 5 copies (gm_endure_pain_copies, rounded), +50% at level 3. Removed when toxicity ends even
//   without the skill (legacy's fix; applied on equip, as 5.x already does).
// - Fast Metabolism (alchemy_s15; classic GM_C_alchemy_s15, 5 levels): toxicity drops 0.25 points per
//   second faster per level (new tree 0.4167), by data (5.x's code).
// - Killing Spree (classic alchemy_s17, 5 levels; the new tree's alchemy_s22 in place of Debilitating
//   Poison): with toxicity above 0, each kill gives +5% crit chance per level (new tree 8.33%) for the
//   fight (5.x's code for alchemy_s17, extended to alchemy_s22). 5.x's Debilitating Poison is gone
//   (damage/formula.ws).
// See docs/features/skl.md.

// Frenzy's attack power and intensity while overdosed: one copy of the skill's ability per level.
@addMethod(W3PlayerWitcher)
function GMUpdateFrenzyAbilities()
{
	var abilityName : name;
	var target, current : int;

	abilityName = SkillEnumToName(S_Alchemy_s16);
	target = 0;
	if(CanUseSkill(S_Alchemy_s16) && HasBuff(EET_Toxicity) && GetStatPercents(BCS_Toxicity) >= GetToxicityDamageThreshold())
		target = GetSkillLevel(S_Alchemy_s16);
	current = GetAbilityCount(abilityName);
	if(target > current)
		AddAbilityMultiple(abilityName, target - current);
	else if(target < current)
		RemoveAbilityMultiple(abilityName, current - target);
}

// Endure Pain's copies of IgnorePainEffect (+10% maximum Vitality each) for the skill's level.
@addMethod(W3PlayerWitcher)
function GMEndurePainCopies() : int
{
	if(!CanUseSkill(S_Alchemy_s20))
		return 0;
	return RoundMath(GetSkillLevel(S_Alchemy_s20) * CalculateAttributeValue(GetSkillAttributeValue(S_Alchemy_s20, 'gm_endure_pain_copies', false, false)));
}

// The Killing Spree the player has (classic first); S_SUndefined if none.
@addMethod(W3PlayerWitcher)
function GMKillingSpreeSkill() : ESkill
{
	if(CanUseSkill(S_Alchemy_s17))
		return S_Alchemy_s17;
	if(CanUseSkill(S_Alchemy_s22))
		return S_Alchemy_s22;
	return S_SUndefined;
}

// The skill hooks (called from skills/mutation.ws's GMMutationSkillChanged).
@addMethod(W3PlayerWitcher)
function GMGrassesSkillChanged(skill : ESkill)
{
	if(skill == S_Alchemy_s16)
		GMUpdateFrenzyAbilities();
}

@wrapMethod(W3Effect_Toxicity)
function OnUpdate(deltaTime : float)
{
	wrappedMethod(deltaTime);
	if(GetWitcherPlayer() && target == GetWitcherPlayer())
		GetWitcherPlayer().GMUpdateFrenzyAbilities();
}

// When toxicity ends: Frenzy's copies and Endure Pain go, with or without the skill (legacy).
@wrapMethod(W3Effect_Toxicity)
function OnEffectRemoved()
{
	wrappedMethod();
	if(target.HasBuff(EET_IgnorePain))
		target.RemoveBuff(EET_IgnorePain);
	if(GetWitcherPlayer() && target == GetWitcherPlayer())
		GetWitcherPlayer().GMUpdateFrenzyAbilities();
}

// Killing Spree in the new tree (5.x's OnDeath gives only alchemy_s17's).
@wrapMethod(CNewNPC)
function OnDeath( damageAction : W3DamageAction )
{
	wrappedMethod(damageAction);
	if(damageAction.attacker == thePlayer && GetWitcherPlayer() && thePlayer.GetStat(BCS_Toxicity) > 0 && !thePlayer.CanUseSkill(S_Alchemy_s17) && thePlayer.CanUseSkill(S_Alchemy_s22))
		thePlayer.AddAbilityMultiple(SkillEnumToName(S_Alchemy_s22), thePlayer.GetSkillLevel(S_Alchemy_s22));
}

// The new tree's Killing Spree ends with the fight, as 5.x ends alchemy_s17's.
@wrapMethod(CR4PlayerStateCombat)
function OnLeaveState( nextStateName : name )
{
	wrappedMethod(nextStateName);
	parent.RemoveAbilityAll(SkillEnumToName(S_Alchemy_s22));
}

// 5.x body; changes marked //modSigns.
@replaceMethod(W3PlayerWitcher)
function StartFrenzy()
{
	var ratio, duration : float;
	var skillLevel : int;

	isInFrenzy = true;
	skillLevel = GetSkillLevel(S_Alchemy_s16);
	ratio = 1.0f - skillLevel * CalculateAttributeValue(GetSkillAttributeValue(S_Alchemy_s16, 'slowdown_ratio', false, true));	//modSigns: legacy's slowdown (5.x: 0.48 - ratio per level)
	duration = CalculateAttributeValue(GetSkillAttributeValue(S_Alchemy_s16, 'slowdown_duration', false, true));	//modSigns: not per level (legacy)

	theGame.SetTimeScale(ratio, theGame.GetTimescaleSource(ETS_SkillFrenzy), theGame.GetTimescalePriority(ETS_SkillFrenzy) );
	AddTimer('SkillFrenzyFinish', duration * ratio, , , , true);
}


// 5.x body; changes marked //modSigns.
@replaceMethod(CNewNPC)
function OnPreAttackEvent(animEventName : name, animEventType : EAnimationEventType, data : CPreAttackEventData, animInfo : SAnimationEventAnimInfo )
{
	var witcher : W3PlayerWitcher;
	var levelDiff : int;

	super.OnPreAttackEvent(animEventName, animEventType, data, animInfo);
	
	if(animEventType == AET_DurationStart )
	{
		
		
		witcher = GetWitcherPlayer();
		
		
		
		if(GetTarget() == witcher )
		{
			levelDiff = GetLevel() - witcher.GetLevel();
			
			
			
			if ( levelDiff < 100 )
				this.SetDodgeFeedback( true );
		}
		
		if ( IsCountering() )
		{
			
			if(GetTarget() == witcher && witcher.GetStat(BCS_Toxicity) > 0 && witcher.CanUseSkill(S_Alchemy_s16))	//modSigns: SKL-17, Frenzy whether or not Geralt could dodge (legacy)
				witcher.StartFrenzy();
		}
	}
	else if(animEventType == AET_DurationEnd )
	{
		witcher = GetWitcherPlayer();
		
		if(GetTarget() == witcher )
		{		
			this.SetDodgeFeedback( false );
		}
	}
}


// 5.x body; changes marked //modSigns.
@replaceMethod(W3Effect_IgnorePain)
function OnEffectAdded(optional customParams : W3BuffCustomParams)
{	
	var witcher : W3PlayerWitcher;
	var level : int;
	
	witcher = (W3PlayerWitcher)target;

	if(!witcher)
	{
		LogEffects("W3Effect_Toxicity.OnEffectAdded: effect added on non-CR4Player object - aborting!");
		target.RemoveBuff(EET_IgnorePain, true);
		return false;
	}
	
	level = witcher.GMEndurePainCopies();	//modSigns: copies by level in either tree (the new tree's rounded)
	
	
	if(level > 1)
		witcher.AddAbilityMultiple(abilityName, level - 1);
	
	super.OnEffectAdded(customParams);
}


// 5.x body; changes marked //modSigns.
@replaceMethod(W3Effect_IgnorePain)
function OnSkillLevelChanged(delta : int)
{
	var i : int;
	
	delta = GetWitcherPlayer().GMEndurePainCopies() - thePlayer.GetAbilityCount(abilityName);	//modSigns: the copies for the new level (5.x added the level difference once per level of it)
	if(delta > 0)	//modSigns
		thePlayer.AddAbilityMultiple(abilityName, delta);	//modSigns
	else if(delta < 0)	//modSigns
		thePlayer.RemoveAbilityMultiple(abilityName, -delta);	//modSigns
}


// 5.x body; changes marked //modSigns.
@replaceMethod(W3Effect_IgnorePain)
function OnEffectRemoved()
{
	var percents : float;
	var level : int;

	percents = target.GetStatPercents(BCS_Vitality);
	
	super.OnEffectRemoved();
	
	target.RemoveAbilityAll(abilityName);	//modSigns: every copy, with or without the skill (5.x: the skill's level)
	
	
	target.UpdateStatMax(BCS_Vitality);
	target.ForceSetStat(BCS_Vitality, percents * target.GetStatMax(BCS_Vitality));
}
