// MUT-08 Toxic Blood (Mutation 4), as legacy: a melee hit taken (within 3 m, 6 m from a huge
// enemy; the trigger is 5.x's, unchanged) gives the attacker an acid DoT of 1.5 x Geralt's current
// toxicity per second for 5 s, whatever the hit's damage (vanilla: a share of the damage taken), and
// no acid without toxicity; every enemy under the acid has its stamina regeneration slowed by 10%
// (Mutation4BloodDebuff, vanilla only on a vampire's bite, for 15 s); toxicity decays 50% slower
// (mutations/toxicity.ws). The HUD counter shows the acid's damage per second (GetStacks).
// Vanilla's vampire-bite path (OnTaskSyncAnim) is kept: it adds the debuff once more and removes one
// copy 15 s later, after the acid's end has removed them all, so it plays as legacy's.
// See docs/features/mut.md.

// The toxicity decay reduction (Mutation4's toxicityRegenFactor, 0.5).
function GMMutation4DecayFactor() : float
{
	var min, max : SAbilityAttributeValue;

	theGame.GetDefinitionsManager().GetAbilityAttributeValue('Mutation4', 'toxicityRegenFactor', min, max);
	return min.valueAdditive;
}

@replaceMethod(W3PlayerWitcher)
function ProcessActionMutation4ReturnedDamage( damageDealt : float, attacker : CActor, hitAnimationType : EActionHitAnim, optional action : W3DamageAction ) : bool
{
	var customParams				: SCustomEffectParams;
	var currToxicity				: float;
	var min, max, customDamageValue	: SAbilityAttributeValue;
	var dm							: CDefinitionsManagerAccessor;
	var animAction					: W3DamageAction;
	var customDuration				: float;	//modSigns

	if( damageDealt <= 0 )
	{	//modSigns: order changed (legacy)
		return false;	//modSigns: order changed (legacy)
	}	//modSigns: order changed (legacy)

	//modSigns: removed SetMutation4Triggered here (moved below, once the acid is sure)

	dm = theGame.GetDefinitionsManager();	//modSigns: order changed (legacy)
	currToxicity = GetStat( BCS_Toxicity );	//modSigns: order changed (legacy)

	if( currToxicity <= 0 )	//modSigns: no acid without toxicity
	{	//modSigns
		return false;	//modSigns
	}	//modSigns

	dm.GetAbilityAttributeValue( 'AcidEffect', 'DirectDamage', min, max );	//modSigns: order changed (legacy)
	customDamageValue.valueAdditive = currToxicity * min.valueAdditive;	//modSigns: per second, by toxicity only
	dm.GetAbilityAttributeValue( 'AcidEffect', 'duration', min, max );	//modSigns
	customDuration = min.valueAdditive;	//modSigns

	if( customDamageValue.valueAdditive <= 0 || customDuration <= 0 )	//modSigns
	{	//modSigns
		return false;	//modSigns
	}	//modSigns

	if( action )	//modSigns
	{	//modSigns
		action.SetMutation4Triggered();	//modSigns
	}	//modSigns

	//modSigns: removed the damage-based value (damage dealt x DirectDamage x toxicity / duration)

	customParams.effectType = EET_Acid;
	customParams.effectValue = customDamageValue;
	customParams.duration = customDuration;	//modSigns
	customParams.creator = this;
	customParams.sourceName = 'Mutation4';

	attacker.AddEffectCustom( customParams );


	animAction = new W3DamageAction in theGame;
	animAction.Initialize( this, attacker, NULL, 'Mutation4', EHRT_Reflect, CPS_Undefined, true, false, false, false );
	animAction.SetCannotReturnDamage( true );
	animAction.SetCanPlayHitParticle( false );
	animAction.SetHitAnimationPlayType( hitAnimationType );
	theGame.damageMgr.ProcessAction( animAction );
	delete animAction;

	theGame.MutationHUDFeedback( MFT_PlayOnce );

	return true;
}

// The acid slows the enemy's stamina regeneration while it runs (legacy moved the debuff here).
class W3Effect_Acid extends W3DamageOverTimeEffect
{
	event OnEffectAdded(optional customParams : W3BuffCustomParams)	//modSigns
	{	//modSigns
		super.OnEffectAdded(customParams);	//modSigns
		if(target != thePlayer)	//modSigns
			target.AddAbility('Mutation4BloodDebuff');	//modSigns
	}	//modSigns

	event OnEffectRemoved()	//modSigns
	{	//modSigns
		super.OnEffectRemoved();	//modSigns
		target.RemoveAbilityAll('Mutation4BloodDebuff');	//modSigns
	}	//modSigns
}

// The HUD counter: the acid's damage per second at the current toxicity (vanilla: the percentage of
// the damage taken over the acid's duration).
@replaceMethod(W3Effect_Mutation4)
function OnEffectAddedPost()
{
	var min, max : SAbilityAttributeValue;

	super.OnEffectAddedPost();

	theGame.GetDefinitionsManager().GetAbilityAttributeValue( 'AcidEffect', 'DirectDamage', min, max );
	bonusPerPoint = min.valueAdditive;	//modSigns: damage per second per toxicity point
	//modSigns: removed dotDuration
}

@replaceMethod(W3Effect_Mutation4)
function GetStacks() : int
{
	var tox : float;
	var advancedMaths : float;

	tox = target.GetStat( BCS_Toxicity );
	advancedMaths = bonusPerPoint * tox;	//modSigns
	return RoundMath( advancedMaths );	//modSigns
}
