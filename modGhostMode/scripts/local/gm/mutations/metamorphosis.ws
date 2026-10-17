// MUT-13 Metamorphosis (Mutation 12), as legacy: up to 3 decoctions drunk while it is equipped cost
// no toxicity (their offset is 0; marked by the source name "Mutation12"); each such decoction active
// multiplies the chance of critical effects Geralt applies by 1 + 0.1 (x1.3 with 3): Igni's burning
// (skills/igni.ws), the knockdown roll (skills/aard.ws), Poisoned Blades (skills/oils.ws), Crippling
// Strikes (skills/cripplingStrikes.ws) and every non-sign effect of his actions (below). Vanilla's
// random decoction on critical effects is gone. The potion functions are SKL's
// (skills/metabolismBoosts.ws, skills/brewing.ws). See docs/features/mut.md.

// The factor on effect chances: 1 + 0.1 per free decoction active (legacy Mutation12GetBonus).
@addMethod(W3PlayerWitcher)
function GMMutation12ChanceMult() : float
{
	var min, max : SAbilityAttributeValue;
	var buffs : array< CBaseGameplayEffect >;

	if(!IsMutationActive(EPMT_Mutation12))
		return 1;
	buffs = GetDrunkMutagens("Mutation12");
	theGame.GetDefinitionsManager().GetAbilityAttributeValue('Mutation12', 'mut12bonus', min, max);
	return MaxF(1.0f, 1.0f + buffs.Size() * min.valueAdditive);
}

// Whether the next decoction is free (legacy Mutation12FreeDecoctionAvailable, with the mutation).
@addMethod(W3PlayerWitcher)
function GMMutation12FreeDecoction() : bool
{
	var min, max : SAbilityAttributeValue;
	var buffs : array< CBaseGameplayEffect >;

	if(!IsMutationActive(EPMT_Mutation12))
		return false;
	theGame.GetDefinitionsManager().GetAbilityAttributeValue('Mutation12', 'maxcap', min, max);
	buffs = GetDrunkMutagens("Mutation12");
	return buffs.Size() < min.valueAdditive;
}

// Vanilla's random decoction on critical effects is gone (legacy emptied it).
@replaceMethod(W3PlayerWitcher)
function AddMutation12Decoction()
{
	//modSigns: removed vanilla's random free decoction on critical effects (Metamorphosis reworked, MUT-13)
}

// Non-sign effects (weapons, bolts, bombs, oils) are resisted by the target and raised by
// Metamorphosis (legacy GetNonSignApplyBuffTest; 5.x: the bare apply chance).
@addMethod(W3EffectManager)
function GMNonSignApplyBuffTest(applyChance : float, effectType : EEffectType, actorAttacker : CActor) : bool
{
	var resPt, resPrc, chance : float;
	var witcher : W3PlayerWitcher;

	if(!IsNegativeEffectType(effectType))	// only negative effects are resisted
		return RandF() < applyChance;
	owner.GetResistValue(theGame.effectMgr.GetBuffResistStat(effectType), resPt, resPrc);
	chance = MaxF(0, applyChance * (1 - resPrc));
	witcher = (W3PlayerWitcher)actorAttacker;
	if(witcher)
		chance *= witcher.GMMutation12ChanceMult();
	return RandF() < chance;
}

@replaceMethod(W3EffectManager)
function AddEffectsFromAction( action : W3DamageAction ) : bool
{
	var i, size : int;
	var effectInfos : array< SEffectInfo >;
	var ret : EEffectInteract;
	var signProjectile : W3SignProjectile;
	var attackerPowerStatValue : SAbilityAttributeValue;
	var retB, applyBuff : bool;
	var signEntity : W3SignEntity;
	var canLog : bool;

	canLog = theGame.CanLog();
	size = action.GetEffects( effectInfos );
	signProjectile = (W3SignProjectile)action.causer;
	attackerPowerStatValue = action.GetPowerStatValue();
	retB = true;


	signEntity = (W3SignEntity)action.causer;
	if(!signEntity && signProjectile)
		signEntity = signProjectile.GetSignEntity();

	for( i = 0; i < size; i += 1 )
	{
		if ( canLog )
		{
			LogDMHits("Trying to add buff <<" + effectInfos[i].effectType + ">> on target...", action);
		}


		if(signEntity)
		{
			applyBuff = GetSignApplyBuffTest(signEntity.GetSignType(), effectInfos[i].effectType, attackerPowerStatValue, signEntity.IsAlternateCast(), (CActor)action.attacker, action.GetBuffSourceName() );
		}
		else
		{
			applyBuff = GMNonSignApplyBuffTest(effectInfos[i].applyChance, effectInfos[i].effectType, (CActor)action.attacker);	//modSigns: MUT-13, resisted, and Metamorphosis (legacy)
		}

		if(applyBuff)
		{

			ret = InternalAddEffect(effectInfos[i].effectType, action.attacker, action.GetBuffSourceName(), effectInfos[i].effectDuration, effectInfos[i].effectCustomValue, effectInfos[i].effectAbilityName, effectInfos[i].customFXName, signEntity, attackerPowerStatValue, effectInfos[i].effectCustomParam );
		}
		else
		{

			if( signEntity && signEntity.GetSignType() == ST_Aard )
			{

				ret = InternalAddEffect(EET_Stagger, action.attacker, action.GetBuffSourceName(), effectInfos[i].effectDuration, effectInfos[i].effectCustomValue, effectInfos[i].customFXName, effectInfos[i].effectAbilityName, signEntity, attackerPowerStatValue, effectInfos[i].effectCustomParam );
			}
		}

		if ( theGame.CanLog() )
		{
			if(ret == EI_Undefined)
			{
				retB = false;
				LogDMHits("... not valid effect!", action);
			}
			else if(!applyBuff)
				LogDMHits("... failed randomization test.", action);
			else if(ret == EI_Deny)
				LogDMHits("... denied.", action);
			else if(ret == EI_Override)
				LogDMHits("... overriden by other effect already on target.", action);
			else if(ret == EI_Pass)
				LogDMHits("... added.", action);
			else if(ret == EI_Cumulate)
				LogDMHits("... cumulated with existing effect on target.", action);
		}
		else
		{
			if ( ret == EI_Undefined )
			{
				retB = false;
			}
		}

	}

	return retB;
}
