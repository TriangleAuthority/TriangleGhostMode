// SKL-08 to SKL-12, D58: the new tree's sign grid gives legacy's sign skills that had no new-tree
// counterpart the slots of 5.x's new-only sign skills, which are dropped (docs/features/skl.md):
//   magic_s35 Igni Intensity (5.x: Catalyst)          magic_s36 Axii Intensity (Fortified Signs)
//   magic_s37 Yrden Intensity (Convergence Theory,    magic_s38 Quen Intensity (Focus, a perk in the
//             shown as Chain Reaction)                          new tree: D40)
//   magic_s39 Aard Intensity (Avoidance, shown as     magic_s40 Quen Discharge (Overload, shown as
//             Sidestep)                                         Aftershock)
//   magic_s41 Pyromaniac (Resonance)
// Each takes legacy's max-level value at level 3 (gm_skills.xml) and its code reads the classic skill
// or the slot (GM<Skill>Skill() next to the sign's code). 5.x's skills: their values are 0 in
// gm_skills.xml, and their code goes here or in the replaced functions that held it (Catalyst's and
// Resonance's damage terms in damage/pool.ws).

// The buffs only 5.x's dropped skills give (Sidestep's sign discount after a dodge, Chain Reaction's
// stacks, Resonance's melee bonus, Aftershock's cooldown, Catalyst's unused buff) are never added.
@wrapMethod(W3EffectManager)
function InternalAddEffect(effectType : EEffectType, creat : CGameplayEntity, srcName : string, optional inDuration : float, optional customVal : SAbilityAttributeValue, optional customAbilityName : name, optional customFXName : name, optional signEffect : bool, optional powerStatValue : SAbilityAttributeValue, optional customParams : W3BuffCustomParams, optional vibratePadLowFreq : float, optional vibratePadHighFreq : float) : EEffectInteract
{
	if(effectType == EET_Avoidance || effectType == EET_ConvergenceTheory || effectType == EET_Resonance || effectType == EET_OverloadCooldown || effectType == EET_Catalyst)
		return EI_Deny;
	return wrappedMethod(effectType, creat, srcName, inDuration, customVal, customAbilityName, customFXName, signEffect, powerStatValue, customParams, vibratePadLowFreq, vibratePadHighFreq);
}

// 5.x body; changes marked //modSigns. Aftershock's impulse and Resonance's buff and sword effect are
// gone.
@replaceMethod(W3SignEntityStateBaseCast)
function OnThrowing()
{
	var l_player : W3PlayerWitcher;
	//modSigns: removed l_gryphonBuff (ARM-07)


	var abilityName : name;
	var abilityCount, maxStack : float;
	var min, max : SAbilityAttributeValue;
	var addAbility : bool;

	l_player = caster.GetPlayer();

	if( l_player )
	{

		//modSigns: removed 5.x's Overload (Aftershock, magic_s40): its impulse and cooldown (D58)

		//modSigns: removed 5.x's Resonance (magic_s41): its buff and sword effect (D58)

		FactsAdd("ach_sign", 1, 4 );

		theGame.GetGamerProfile().CheckLearningTheRopes();

		//modSigns: removed 5.x's Griffin set free cast (ARM-07: legacy's Griffin set has none)



		if(l_player.HasBuff(EET_Mutagen22) && l_player.IsInCombat() && l_player.IsThreatened())
		{
			abilityName = l_player.GetBuff(EET_Mutagen22).GetAbilityName();
			abilityCount = l_player.GetAbilityCount(abilityName);

			if(abilityCount == 0)
			{
				addAbility = true;
			}
			else
			{
				theGame.GetDefinitionsManager().GetAbilityAttributeValue(abilityName, 'mutagen22_max_stack', min, max);
				maxStack = CalculateAttributeValue(GetAttributeRandomizedValue(min, max));

				if(maxStack >= 0)
				{
					addAbility = (abilityCount < maxStack);
				}
				else
				{
					addAbility = true;
				}
			}

			if(addAbility)
			{
				l_player.AddAbility(abilityName, true);
			}

		}
	}

	return true;
}
