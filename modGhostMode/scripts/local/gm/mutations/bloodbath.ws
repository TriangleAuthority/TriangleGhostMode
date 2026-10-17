// MUT-05 Bloodbath (Mutation 3), as legacy: at combat start, +10% attack power per equipped
// sword-path skill and +5% per other equipped skill (unlocked slots, both trees); a hit taken
// removes 0.5% per 1% of max Vitality lost (not DoTs from effects); a sword kill restores the bonus
// to its peak and adds +20%; max 250%; gone at combat end (and when not threatened). 5.x: +5% per
// sword hit, up to 250%, all lost on any damage taken. The bonus is counted in stacks of the
// Mutation3 ability (0.5% attack power each). Finishers or dismemberment on sword kills are 5.x's
// (unchanged). Triggers: combat start (mutations/combatStart.ws), damage taken
// (mutations/takeDamage.ws), kills (CNewNPC.OnDeath below). 5.x's start on a sword hit
// (OnProcessActionPost) stays: it only starts the effect if a hit comes before combat start, with
// the same bonus, and adds nothing to a running one (CumulateWith).
// See docs/features/mut.md.

class W3Effect_Mutation3 extends CBaseGameplayEffect
{
	default stacks = 0;	//modSigns: no stack before the bonus is set
	default dontAddAbilityOnTarget = true;	//modSigns: the stacks are Mutation3 abilities, added by the effect
}

@addField(W3Effect_Mutation3)
var gmBuffRateSword : int;
@addField(W3Effect_Mutation3)
var gmBuffRateOther : int;
@addField(W3Effect_Mutation3)
var gmBuffRateKill : int;
@addField(W3Effect_Mutation3)
var gmDebuffRate : int;
@addField(W3Effect_Mutation3)
var gmMaxStacks : int;

@addMethod(W3Effect_Mutation3)
function GMInitVars()
{
	var dm : CDefinitionsManagerAccessor;
	var min, max : SAbilityAttributeValue;

	dm = theGame.GetDefinitionsManager();
	dm.GetAbilityAttributeValue('Mutation3', 'attack_power', min, max);
	apBonus = min.valueMultiplicative;
	dm.GetAbilityAttributeValue('Mutation3', 'mutation3_maxcap', min, max);
	maxCap = RoundMath(min.valueAdditive);
	dm.GetAbilityAttributeValue('Mutation3', 'mutation3_buff_rate_sword', min, max);
	gmBuffRateSword = RoundMath(min.valueAdditive);
	dm.GetAbilityAttributeValue('Mutation3', 'mutation3_buff_rate_other', min, max);
	gmBuffRateOther = RoundMath(min.valueAdditive);
	dm.GetAbilityAttributeValue('Mutation3', 'mutation3_buff_rate_kill', min, max);
	gmBuffRateKill = RoundMath(min.valueAdditive);
	dm.GetAbilityAttributeValue('Mutation3', 'mutation3_debuff_rate', min, max);
	gmDebuffRate = RoundMath(min.valueAdditive);
}

// The stacks for the skills equipped in unlocked slots (the mutation slots included).
@addMethod(W3Effect_Mutation3)
function GMCalcInitialNumAbl() : int
{
	var skillSlots : array<SSkillSlot>;
	var pathType : ESkillPath;
	var i, ablNum : int;

	skillSlots = thePlayer.GetSkillSlots();
	for(i = 0; i < skillSlots.Size(); i += 1)
	{
		if(skillSlots[i].unlocked)
		{
			pathType = GetWitcherPlayer().GetSkillPathType(skillSlots[i].socketedSkill);
			if(pathType != ESP_NotSet)
			{
				if(pathType == ESP_Sword)
					ablNum += gmBuffRateSword;
				else
					ablNum += gmBuffRateOther;
			}
		}
	}
	return ablNum;
}

@addMethod(W3Effect_Mutation3)
function GMRemoveAllAbls()
{
	thePlayer.RemoveAbilityAll('Mutation3');
	stacks = 0;
}

@addMethod(W3Effect_Mutation3)
function GMSetAbls(num : int)
{
	var abilityCount : int;

	if(num > maxCap)
		num = maxCap;
	abilityCount = thePlayer.GetAbilityCount('Mutation3');
	if(abilityCount < num)
	{
		thePlayer.AddAbilityMultiple('Mutation3', num - abilityCount);
		GMPlayFX();
	}
	else if(abilityCount > num)
		thePlayer.RemoveAbilityMultiple('Mutation3', abilityCount - num);
	stacks = thePlayer.GetAbilityCount('Mutation3');
}

@addMethod(W3Effect_Mutation3)
function GMRemoveAbls(num : int)
{
	if(thePlayer.GetAbilityCount('Mutation3') - num <= 0)
		thePlayer.RemoveAbilityAll('Mutation3');
	else
		thePlayer.RemoveAbilityMultiple('Mutation3', num);
	stacks = thePlayer.GetAbilityCount('Mutation3');
}

@addMethod(W3Effect_Mutation3)
function GMPlayFX()
{
	var sword : CItemEntity;

	thePlayer.GetInventory().GetCurrentlyHeldSwordEntity(sword);
	if(sword)
		sword.PlayEffect('instant_fx');
}

@addMethod(W3Effect_Mutation3)
function GMGetBonusStacks() : int
{
	return stacks;
}

// A kill by Geralt's sword (or a finisher) restores the peak and adds to it; damage taken removes
// some; out of combat or not threatened, the bonus goes.
@addMethod(W3Effect_Mutation3)
function GMManageMutation3Bonus(damageAction : W3DamageAction)
{
	var attackAction : W3Action_Attack;

	attackAction = (W3Action_Attack)damageAction;
	if(target == thePlayer && thePlayer.IsInCombat() && thePlayer.IsThreatened())
	{
		if(damageAction.attacker == thePlayer && !damageAction.victim.IsAlive()
			&& (attackAction && attackAction.IsActionMelee() && attackAction.DealsAnyDamage() && !thePlayer.GetInventory().IsItemFists(attackAction.GetWeaponId())
			|| damageAction.GetBuffSourceName() == "Kill" || damageAction.GetBuffSourceName() == "Finisher"))
		{
			gmMaxStacks += gmBuffRateKill;
			if(gmMaxStacks > maxCap)
				gmMaxStacks = maxCap;
			GMSetAbls(gmMaxStacks);
		}
		else if(damageAction.victim == thePlayer && damageAction.DealsAnyDamage()
			&& !(damageAction.IsDoTDamage() && (CBaseGameplayEffect)damageAction.causer))
		{
			GMRemoveAbls(RoundMath(gmDebuffRate * damageAction.GetDamageDealt() / thePlayer.GetMaxHealth() * 100));
		}
	}
	else
		GMRemoveAllAbls();
}

@replaceMethod(W3Effect_Mutation3)
function OnEffectAddedPost()
{
	var min, max : SAbilityAttributeValue;
	var sword : CItemEntity;

	super.OnEffectAddedPost();

	GMInitVars();	//modSigns: legacy's values (removed 5.x's maxcap and attack_power reads, the single ability and the sword FX)
	gmMaxStacks = GMCalcInitialNumAbl();	//modSigns: the bonus for the equipped skills
	GMSetAbls(gmMaxStacks);	//modSigns

	theGame.MutationHUDFeedback( MFT_PlayRepeat );
}

@replaceMethod(W3Effect_Mutation3)
function CumulateWith(effect: CBaseGameplayEffect)
{
	var sword : CItemEntity;

	super.CumulateWith(effect);

	//modSigns: removed the stack per sword hit
}

@replaceMethod(W3Effect_Mutation3)
function OnEffectRemoved()
{
	GMRemoveAllAbls();	//modSigns

	theGame.MutationHUDFeedback( MFT_PlayHide );

	super.OnEffectRemoved();
}

// Kills (legacy's call in OnDeath, under the same condition: Geralt's hit, sign, bolt or finisher).
@wrapMethod(CNewNPC)
function OnDeath( damageAction : W3DamageAction )
{
	wrappedMethod(damageAction);
	if(damageAction.attacker == GetWitcherPlayer() && thePlayer.HasBuff(EET_Mutation3) && (damageAction.IsActionMelee() || damageAction.IsActionRanged() || damageAction.IsActionWitcherSign() || damageAction.GetBuffSourceName() == "Kill" || damageAction.GetBuffSourceName() == "Finisher" || damageAction.GetBuffSourceName() == "AutoFinisher"))
		((W3Effect_Mutation3)thePlayer.GetBuff(EET_Mutation3)).GMManageMutation3Bonus(damageAction);
}
