// ALCH-10: decoctions that build up in a fight (legacy's), all reset at combat end:
// - Katakan (Mutagen 1): each non-critical melee hit (not fists) +5% crit chance, up to 5 stacks; at 5
//   stacks +50% crit damage (KatakanBonusEffect); a crit resets it.
// - Water Hag (Mutagen 5): each melee hit +10% attack power (20 stacks of 0.5%, up to +100%); damage taken
//   removes 0.5% per 1% of Vitality lost (damage over time excluded). 1.32's +50% at full Vitality is gone.
// - Wyvern (Mutagen 10): each sign cast in combat +16.7% attack power (up to 50%); a melee hit clears it.
//   1.32's +1% per hit is gone.
// - Alghoul (Mutagen 15): as Water Hag, on adrenaline gain (+10% per hit, up to 50%). 1.32's +50% until hit
//   is gone.
// - Forktail (Mutagen 17): each melee hit +10% sign intensity (up to 50%); any sign cast clears it. 1.32's
//   three-action-types rule is gone.
// The stack abilities are added on Geralt (dontAddAbilityOnTarget: the effect itself adds none).
// See docs/features/alch.md.

// ---- Katakan ----------------------------------------------------------------------------------------------

class W3Mutagen01_Effect extends W3Mutagen_Effect
{
	default dontAddAbilityOnTarget = true;	//modSigns

	event OnEffectRemoved()	//modSigns
	{	//modSigns
		super.OnEffectRemoved();	//modSigns
		GMRemoveMutagen01Abilities();	//modSigns
	}	//modSigns
}

@addMethod(W3Mutagen01_Effect)
function GMManageMutagen01Bonus(attackAction : W3Action_Attack)
{
	if(target == thePlayer && thePlayer.IsInCombat() && thePlayer.IsThreatened())
	{
		if(attackAction.DealsAnyDamage() && !attackAction.IsCriticalHit() && attackAction.IsActionMelee()
			&& !thePlayer.GetInventory().IsItemFists(attackAction.GetWeaponId()))
		{
			GMAddMutagen01Ability();
		}
		else if(attackAction.IsCriticalHit())
		{
			GMRemoveMutagen01Abilities();
		}
	}
	else
	{
		GMRemoveMutagen01Abilities();
	}
}

@addMethod(W3Mutagen01_Effect)
function GMRemoveMutagen01Abilities()
{
	thePlayer.RemoveAbilityAll(abilityName);
	thePlayer.RemoveAbilityAll('KatakanBonusEffect');
}

@addMethod(W3Mutagen01_Effect)
function GMAddMutagen01Ability()
{
	var abilityCount, maxStack : float;
	var min, max : SAbilityAttributeValue;

	if(target == thePlayer && thePlayer.IsInCombat() && thePlayer.IsThreatened())
	{
		theGame.GetDefinitionsManager().GetAbilityAttributeValue(abilityName, 'mutagen01_max_stack', min, max);
		maxStack = CalculateAttributeValue(GetAttributeRandomizedValue(min, max));
		abilityCount = thePlayer.GetAbilityCount(abilityName);
		if(abilityCount < maxStack)
		{
			thePlayer.AddAbility(abilityName, true);
			abilityCount += 1;
		}
		if(abilityCount >= maxStack && !thePlayer.HasAbility('KatakanBonusEffect'))
			thePlayer.AddAbility('KatakanBonusEffect');
	}
}

// The HUD counter: the crit chance in %.
@addMethod(W3Mutagen01_Effect)
function GMGetStacks() : int
{
	var min, max : SAbilityAttributeValue;

	theGame.GetDefinitionsManager().GetAbilityAttributeValue(abilityName, 'critical_hit_chance', min, max);
	return RoundMath(CalculateAttributeValue(min) * 100 * thePlayer.GetAbilityCount(abilityName));
}

// ---- Water Hag and Alghoul (the same rule, on attack power and on adrenaline gain) --------------------------

class W3Mutagen05_Effect extends W3Mutagen_Effect
{
	default dontAddAbilityOnTarget = true;	//modSigns

	event OnEffectRemoved()	//modSigns
	{	//modSigns
		super.OnEffectRemoved();	//modSigns
		target.RemoveAbilityAll(abilityName);	//modSigns
	}	//modSigns
}

@addMethod(W3Mutagen05_Effect)
function GMManageMutagen05Bonus(damageAction : W3DamageAction)
{
	GMManageBuildUpDecoction(this, damageAction, 'mutagen05_max_stack', 'mutagen05_buff_rate', 'mutagen05_debuff_rate');
}

@addMethod(W3Mutagen05_Effect)
function GMGetStacks() : int
{
	var min, max : SAbilityAttributeValue;

	theGame.GetDefinitionsManager().GetAbilityAttributeValue(abilityName, 'attack_power', min, max);
	return RoundMath(min.valueMultiplicative * 100 * thePlayer.GetAbilityCount(abilityName));
}

@addMethod(W3Mutagen15_Effect)
function GMManageMutagen15Bonus(damageAction : W3DamageAction)
{
	GMManageBuildUpDecoction(this, damageAction, 'mutagen15_max_stack', 'mutagen15_buff_rate', 'mutagen15_debuff_rate');
}

@addMethod(W3Mutagen15_Effect)
function GMGetStacks() : int
{
	var min, max : SAbilityAttributeValue;

	theGame.GetDefinitionsManager().GetAbilityAttributeValue(abilityName, 'focus_gain', min, max);
	return RoundMath(min.valueAdditive * 100 * thePlayer.GetAbilityCount(abilityName));
}

// Legacy's ManageMutagen05Bonus/ManageMutagen15Bonus: Geralt's melee hit (not fists) adds buffRate stacks up to
// maxStack; damage he takes (not damage over time from an effect) removes debuffRate stacks per 1% of
// maximum Vitality lost; out of combat (or not threatened) all stacks go.
function GMManageBuildUpDecoction(effect : CBaseGameplayEffect, damageAction : W3DamageAction, maxName : name, buffName : name, debuffName : name)
{
	var attackAction : W3Action_Attack;
	var abl : name;
	var min, max : SAbilityAttributeValue;
	var abilityCount, maxStack, buffRate, debuffNum : int;
	var debuffRate, dmgVal : float;

	abl = effect.GetAbilityName();
	attackAction = (W3Action_Attack)damageAction;
	if(!(thePlayer.IsInCombat() && thePlayer.IsThreatened()))
	{
		thePlayer.RemoveAbilityAll(abl);
		return;
	}
	if(attackAction && attackAction.attacker == thePlayer && attackAction.DealsAnyDamage() && attackAction.IsActionMelee()
		&& !thePlayer.GetInventory().IsItemFists(attackAction.GetWeaponId()))
	{
		theGame.GetDefinitionsManager().GetAbilityAttributeValue(abl, maxName, min, max);
		maxStack = RoundMath(CalculateAttributeValue(GetAttributeRandomizedValue(min, max)));
		theGame.GetDefinitionsManager().GetAbilityAttributeValue(abl, buffName, min, max);
		buffRate = RoundMath(CalculateAttributeValue(GetAttributeRandomizedValue(min, max)));
		abilityCount = thePlayer.GetAbilityCount(abl);
		if(abilityCount + buffRate < maxStack)
			thePlayer.AddAbilityMultiple(abl, buffRate);
		else if(abilityCount < maxStack)
			thePlayer.AddAbilityMultiple(abl, maxStack - abilityCount);
	}
	else if(damageAction.victim == thePlayer && damageAction.DealsAnyDamage()
		&& !(damageAction.IsDoTDamage() && (CBaseGameplayEffect)damageAction.causer))
	{
		dmgVal = damageAction.GetDamageDealt();
		if(dmgVal <= 0)
			return;
		theGame.GetDefinitionsManager().GetAbilityAttributeValue(abl, debuffName, min, max);
		debuffRate = CalculateAttributeValue(GetAttributeRandomizedValue(min, max));
		debuffNum = RoundMath(debuffRate * dmgVal / thePlayer.GetMaxHealth() * 100);
		abilityCount = thePlayer.GetAbilityCount(abl);
		if(debuffNum < abilityCount)
			thePlayer.RemoveAbilityMultiple(abl, debuffNum);
		else
			thePlayer.RemoveAbilityAll(abl);
	}
}

// 5.x body: 1.32's ability added in combat; legacy's Alghoul adds nothing when drunk. Changes marked //modSigns.
@replaceMethod(W3Mutagen15_Effect)
function OnEffectAdded(optional customParams : W3BuffCustomParams)
{
	super.OnEffectAdded(customParams);
	//modSigns: removed 1.32's ability in combat (ALCH-10: the stacks come from melee hits)
}

// 5.x body; changes marked //modSigns.
@replaceMethod(W3Mutagen15_Effect)
function OnEffectRemoved()
{
	super.OnEffectRemoved();
	target.RemoveAbilityAll(abilityName);	//modSigns: every stack
}

// ---- Wyvern and Forktail -------------------------------------------------------------------------------------

@addMethod(W3Mutagen10_Effect)
function GMManageMutagen10Bonus(attackAction : W3Action_Attack)
{
	if(target == thePlayer && thePlayer.IsInCombat() && thePlayer.IsThreatened())
	{
		if(attackAction.DealsAnyDamage() && attackAction.IsActionMelee()
			&& !thePlayer.GetInventory().IsItemFists(attackAction.GetWeaponId()))
		{
			thePlayer.RemoveAbilityAll(abilityName);
		}
	}
	else
	{
		thePlayer.RemoveAbilityAll(abilityName);
	}
}

@addMethod(W3Mutagen10_Effect)
function GMAddMutagen10Ability()
{
	var min, max : SAbilityAttributeValue;

	if(target == thePlayer && thePlayer.IsInCombat() && thePlayer.IsThreatened())
	{
		theGame.GetDefinitionsManager().GetAbilityAttributeValue(abilityName, 'mutagen10_max_stack', min, max);
		if(thePlayer.GetAbilityCount(abilityName) < CalculateAttributeValue(GetAttributeRandomizedValue(min, max)))
			thePlayer.AddAbility(abilityName, true);
	}
}

@addMethod(W3Mutagen10_Effect)
function GMGetStacks() : int
{
	var min, max : SAbilityAttributeValue;

	theGame.GetDefinitionsManager().GetAbilityAttributeValue(abilityName, 'attack_power', min, max);
	return RoundMath(min.valueMultiplicative * 100 * thePlayer.GetAbilityCount(abilityName));
}

class W3Mutagen10_Effect extends W3Mutagen_Effect
{
	event OnEffectRemoved()	//modSigns
	{	//modSigns
		super.OnEffectRemoved();	//modSigns
		target.RemoveAbilityAll(abilityName);	//modSigns
	}	//modSigns
}

@addMethod(W3Mutagen17_Effect)
function GMManageMutagen17Bonus(attackAction : W3Action_Attack)
{
	var min, max : SAbilityAttributeValue;

	if(target == thePlayer && thePlayer.IsInCombat() && thePlayer.IsThreatened())
	{
		if(attackAction.DealsAnyDamage() && attackAction.IsActionMelee()
			&& !thePlayer.GetInventory().IsItemFists(attackAction.GetWeaponId()))
		{
			theGame.GetDefinitionsManager().GetAbilityAttributeValue(abilityName, 'mutagen17_max_stack', min, max);
			if(thePlayer.GetAbilityCount(abilityName) < CalculateAttributeValue(GetAttributeRandomizedValue(min, max)))
				thePlayer.AddAbility(abilityName, true);
		}
	}
	else
	{
		thePlayer.RemoveAbilityAll(abilityName);
	}
}

@addMethod(W3Mutagen17_Effect)
function GMGetStacks() : int
{
	var min, max : SAbilityAttributeValue;

	theGame.GetDefinitionsManager().GetAbilityAttributeValue(abilityName, 'spell_power', min, max);
	return RoundMath(min.valueMultiplicative * 100 * thePlayer.GetAbilityCount(abilityName));
}

// 5.x body: 1.32's count of action types giving the boost; legacy's Forktail builds on melee hits. Changes marked //modSigns.
@replaceMethod(W3Mutagen17_Effect)
function OnUpdate(dt : float)
{
	//modSigns: removed the action counter's local
	super.OnUpdate(dt);
	//modSigns: removed 1.32's boost from three action types (ALCH-10); hasBoost stays false, so 5.x's ClearBoost calls in W3PlayerWitcher.Attack and W3SignEntity.OnEnded do nothing
}

// 5.x body; changes marked //modSigns.
@replaceMethod(W3Mutagen17_Effect)
function OnLoad(t : CActor, eff : W3EffectManager)
{
	super.OnLoad(t, eff);
	//modSigns: removed ClearBoost (it took one stack off; the stacks are combat-only, cleared at combat end and on load by GMClearDecoctionStacks)
}

class W3Mutagen17_Effect extends W3Mutagen_Effect
{
	event OnEffectRemoved()	//modSigns
	{	//modSigns
		super.OnEffectRemoved();	//modSigns
		target.RemoveAbilityAll(abilityName);	//modSigns
	}	//modSigns
}

// ---- Hooks -----------------------------------------------------------------------------------------------

// Geralt's hits and the hits he takes.
@wrapMethod(W3PlayerWitcher)
function OnProcessActionPost(action : W3DamageAction)
{
	var attackAction : W3Action_Attack;
	var ret : bool;

	ret = wrappedMethod(action);
	attackAction = (W3Action_Attack)action;
	if(action.attacker == this)
	{
		if(HasBuff(EET_Mutagen01) && attackAction)
			((W3Mutagen01_Effect)GetBuff(EET_Mutagen01)).GMManageMutagen01Bonus(attackAction);
		if(HasBuff(EET_Mutagen05))
			((W3Mutagen05_Effect)GetBuff(EET_Mutagen05)).GMManageMutagen05Bonus(action);
		if(HasBuff(EET_Mutagen10) && attackAction)
			((W3Mutagen10_Effect)GetBuff(EET_Mutagen10)).GMManageMutagen10Bonus(attackAction);
		if(HasBuff(EET_Mutagen15))
			((W3Mutagen15_Effect)GetBuff(EET_Mutagen15)).GMManageMutagen15Bonus(action);
		if(HasBuff(EET_Mutagen17) && attackAction)
			((W3Mutagen17_Effect)GetBuff(EET_Mutagen17)).GMManageMutagen17Bonus(attackAction);
	}
	return ret;
}

// Called from W3PlayerWitcher.OnTakeDamage (mutations/takeDamage.ws) for the damage Geralt takes.
@addMethod(W3PlayerWitcher)
function GMDecoctionsOnDamageTaken(action : W3DamageAction)
{
	if(HasBuff(EET_Mutagen05))
		((W3Mutagen05_Effect)GetBuff(EET_Mutagen05)).GMManageMutagen05Bonus(action);
	if(HasBuff(EET_Mutagen15))
		((W3Mutagen15_Effect)GetBuff(EET_Mutagen15)).GMManageMutagen15Bonus(action);
	if(HasBuff(EET_Mutagen22))	// ALCH-11, Ancient Leshen
		((W3Mutagen22_Effect)GetBuff(EET_Mutagen22)).GMRemoveMutagen22Abilities(action);
}

// Every sign Geralt casts (called where the sign's cooldown starts, stamina/signCooldowns.ws).
function GMDecoctionsOnSignCast()
{
	if(thePlayer.HasBuff(EET_Mutagen10))
		((W3Mutagen10_Effect)thePlayer.GetBuff(EET_Mutagen10)).GMAddMutagen10Ability();
	if(thePlayer.HasBuff(EET_Mutagen17))
		thePlayer.RemoveAbilityAll(thePlayer.GetBuff(EET_Mutagen17).GetAbilityName());
	if(thePlayer.HasBuff(EET_Mutagen22))	// ALCH-11, Ancient Leshen
		((W3Mutagen22_Effect)thePlayer.GetBuff(EET_Mutagen22)).GMAddMutagen22Ability();
}

// Combat end clears every stack (5.x already clears Wyvern's and Alghoul's).
@wrapMethod(W3PlayerWitcher)
function OnCombatFinished()
{
	wrappedMethod();
	GMClearDecoctionStacks();
}

@addMethod(W3PlayerWitcher)
function GMClearDecoctionStacks()
{
	if(HasBuff(EET_Mutagen01))
		((W3Mutagen01_Effect)GetBuff(EET_Mutagen01)).GMRemoveMutagen01Abilities();
	RemoveAbilityAll('Mutagen01Effect');
	RemoveAbilityAll('KatakanBonusEffect');
	RemoveAbilityAll('Mutagen05Effect');
	RemoveAbilityAll('Mutagen10Effect');
	RemoveAbilityAll('Mutagen15Effect');
	RemoveAbilityAll('Mutagen17Effect');
	RemoveAbilityAll('Mutagen22Effect');
	RemoveAbilityAll('Mutagen13Effect');	// ALCH-12
	RemoveAbilityAll('Mutagen18Effect');
	RemoveAbilityAll('TrollBonusEffect');
	GMClearArachasDebuffs();	// ALCH-13, DL12: the Arachas acid leaves the enemies
	GMManageWerewolf();	// ALCH-13: out of combat the Werewolf bonus goes
}

// Wyvern: 5.x adds a stack on each of Geralt's melee hits (CNewNPC.OnTakeDamage, 1.32's rule); legacy's stacks
// come from signs only: the hit's stack is taken off again.
@wrapMethod(CNewNPC)
function OnTakeDamage(action : W3DamageAction)
{
	var abl : name;
	var before, after : int;
	var ret : bool;

	if(action.attacker == thePlayer && thePlayer.HasBuff(EET_Mutagen10))
	{
		abl = thePlayer.GetBuff(EET_Mutagen10).GetAbilityName();
		before = thePlayer.GetAbilityCount(abl);
	}
	ret = wrappedMethod(action);
	if(IsNameValid(abl))
	{
		after = thePlayer.GetAbilityCount(abl);
		if(after > before)
			thePlayer.RemoveAbilityMultiple(abl, after - before);
	}
	return ret;
}
