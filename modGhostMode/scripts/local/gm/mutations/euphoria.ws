// MUT-09 Euphoria (Mutation 10), as legacy: active only while overdosed (toxicity at or above the
// damage threshold) and in combat; then the overdose's Vitality drain is multiplied by
// 1 + 0.75 x toxicity / 100, and that drain per second is added to the base damage of sword hits and
// Signs (damage/pool.ws). 5.x's +0.75% attack power and sign intensity per toxicity point
// (ApplyMutation10StatBoost) is gone with its XML attribute. The effect starts and stops in the
// toxicity effect's update (mutations/toxicity.ws), at combat start when overdosed
// (mutations/combatStart.ws) and when equipped while overdosed in combat; not on a toxicity change
// or a decoction (5.x). The energy FX on hits is 5.x's.
// See docs/features/mut.md.

@addField(W3Effect_Mutation10)
var gmDrainFactor : float;

// The overdose's Vitality drain per second (legacy's GetToxicityDamage): 5.x's ToxicityEffect
// DirectDamage x max Vitality, x Euphoria's factor while it runs.
@addMethod(W3PlayerWitcher)
function GMGetToxicityDamage() : float
{
	var min, max : SAbilityAttributeValue;
	var dmg : float;

	theGame.GetDefinitionsManager().GetAbilityAttributeValue('ToxicityEffect', 'DirectDamage', min, max);
	dmg = min.valueMultiplicative * GetStatMax(BCS_Vitality);
	if(HasBuff(EET_Mutation10))
		dmg *= ((W3Effect_Mutation10)GetBuff(EET_Mutation10)).GMGetDrainMult();
	return dmg;
}

@addMethod(W3Effect_Mutation10)
function GMGetDrainMult() : float
{
	return 1 + gmDrainFactor * target.GetStat(BCS_Toxicity) / 100.0;
}

@replaceMethod(W3Effect_Mutation10)
function OnEffectAddedPost()
{
	var min, max : SAbilityAttributeValue;

	super.OnEffectAddedPost();

	theGame.GetDefinitionsManager().GetAbilityAttributeValue( 'Mutation10Effect', 'mutation10_factor', min, max );	//modSigns: the drain factor
	gmDrainFactor = min.valueMultiplicative;	//modSigns

	theGame.MutationHUDFeedback( MFT_PlayRepeat );
}

// The HUD counter: the damage added per hit (the drain per second).
@replaceMethod(W3Effect_Mutation10)
function GetStacks() : int
{
	return RoundMath( GetWitcherPlayer().GMGetToxicityDamage() );	//modSigns
}

// The start FX (vanilla played it at combat start, with or without the effect).
class W3Effect_Mutation10 extends CBaseGameplayEffect
{
	event OnEffectAdded(optional customParams : W3BuffCustomParams)	//modSigns
	{	//modSigns
		super.OnEffectAdded(customParams);	//modSigns
		thePlayer.PlayEffect( 'mutation_10' );	//modSigns
		thePlayer.PlayEffect( 'critical_toxicity' );	//modSigns
		thePlayer.AddTimer( 'Mutation10StopEffect', 5.f );	//modSigns
	}	//modSigns
}

@replaceMethod(W3PlayerAbilityManager)
function OnToxicityChanged()
{
	var tox : float;
	var enemies : array< CActor >;

	if( !((W3PlayerWitcher)owner) )
		return;
		
	tox = GetStat(BCS_Toxicity);

	
	if( tox == 0.f && owner.HasBuff( EET_Toxicity ) )
	{
		owner.RemoveBuff( EET_Toxicity );			
	}
	else if(tox > 0.f && !owner.HasBuff(EET_Toxicity))
	{
		owner.AddEffectDefault(EET_Toxicity,owner,'toxicity_change');
	}	
	
	
	//modSigns: removed Euphoria's start and stop on a toxicity change (MUT-09: the toxicity effect's update starts it while overdosed in combat and stops it)
		
	theTelemetry.SetCommonStatFlt(CS_TOXICITY, GetStat(BCS_Toxicity));
}


@replaceMethod(W3PlayerAbilityManager)
function OnMutationEquippedPost( mutationType : EPlayerMutationType )
{
	var tutEquipping : W3TutorialManagerUIHandlerStateMutationsEquipping;
	var tutEquipped : W3TutorialManagerUIHandlerStateMutationsEquippedAfter;
	var bank : string;
	
	
	bank = GetMutationSoundBank( mutationType );
	if( bank != "" )
	{
		theSound.SoundLoadBank( bank, true );
	}
	
	UpdateMutationSkillSlots();
	
	if( GetWitcherPlayer().IsMutationActive( EPMT_Mutation10 ) && GetWitcherPlayer().GetStatPercents( BCS_Toxicity ) >= GetWitcherPlayer().GetToxicityDamageThreshold() && owner.IsInCombat() )	//modSigns: MUT-09, only while overdosed
	{
		owner.AddEffectDefault( EET_Mutation10, NULL, "Mutation 10" );
	}
	
	
	if( ShouldProcessTutorial( 'TutorialMutationsEquippingOnlyOne' ) )
	{
		tutEquipping = ( W3TutorialManagerUIHandlerStateMutationsEquipping ) theGame.GetTutorialSystem().uiHandler.GetCurrentState();
		if( tutEquipping )
		{
			tutEquipping.OnMutationEquippedPost();
		}
		
		tutEquipped = ( W3TutorialManagerUIHandlerStateMutationsEquippedAfter ) theGame.GetTutorialSystem().uiHandler.GetCurrentState();
		if( tutEquipped )
		{
			tutEquipped.OnMutationEquippedPost();
		}
		
		GameplayFactsAdd( "tutorial_mutations_equipped_mutation" );
	}
}

