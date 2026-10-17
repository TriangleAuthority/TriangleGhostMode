// MUT-07 Adrenaline Rush (Mutation 7), as legacy: in combat Geralt alternates between two 30 s
// states. Rush (Mutation7Buff): adrenaline gain x2 and +50% attack power and sign intensity per
// adrenaline point held (kept in step with the points). Recovery (Mutation7Debuff): adrenaline gain
// halved and -50% per adrenaline point gained during the Rush. The cycle starts at combat start and
// ends with combat; the Recovery cannot be blocked or cleansed (CActor.IsImmuneToBuff and the cleanse
// in AddBuffImmunity_AllNegative, effects/gmEffectRegistration.ws). Vanilla: a one-off buff by the
// number of enemies. The gain rule covers the adrenaline Geralt gains from his own hits (melee, bolts,
// bombs: legacy's sites) and from sign casts (Focus, skills/focusPerk.ws). See docs/features/mut.md.

@addField(W3Mutation7BaseEffect)
var gmSavedFocusPts : int;

@addField(W3Effect_Mutation7Buff)
var gmAccumulatedFocusPts : int;

@addField(W3Mutation7DebuffParams)
var gmSavedFocusPts : int;

@addMethod(W3Mutation7DebuffParams)
function GMSetSavedFocusPts(pts : int)
{
	gmSavedFocusPts = pts;
}

// The factor on adrenaline gains: x2 in the Rush, x0.5 in the Recovery.
@addMethod(W3PlayerWitcher)
function GMMutation7GainMult() : float
{
	if(HasBuff(EET_Mutation7Buff))
		return 2;
	if(HasBuff(EET_Mutation7Debuff))
		return 0.5;
	return 1;
}

// Adrenaline gained while one of Geralt's actions is processed (his hits: melee, bolts, bombs, in
// whichever wrapper of OnProcessActionPost gives it) gets the factor.
@addField(W3PlayerWitcher)
var gmMut7HitContext : int;

@addMethod(W3PlayerWitcher)
function GMMutation7HitContext(entering : bool)
{
	if(entering)
		gmMut7HitContext += 1;
	else if(gmMut7HitContext > 0)
		gmMut7HitContext -= 1;
}

@addMethod(W3PlayerWitcher)
function GMInMutation7HitContext() : bool
{
	return gmMut7HitContext > 0;
}

@wrapMethod(W3DamageManagerProcessor)
function ProcessAction(act : W3DamageAction)
{
	var witcher : W3PlayerWitcher;
	var mine : bool;

	witcher = GetWitcherPlayer();
	mine = act && witcher && act.attacker == witcher;
	if(mine)
		witcher.GMMutation7HitContext(true);
	wrappedMethod(act);
	if(mine)
		witcher.GMMutation7HitContext(false);
}

@wrapMethod(W3PlayerAbilityManager)
function GainStat(stat : EBaseCharacterStats, amount : float)
{
	var witcher : W3PlayerWitcher;

	witcher = (W3PlayerWitcher)owner;
	if(stat == BCS_Focus && amount > 0 && witcher && witcher.GMInMutation7HitContext())
		amount *= witcher.GMMutation7GainMult();
	wrappedMethod(stat, amount);
}

// The cycle starts at once when combat starts (5.x: a timer waiting for two enemies).
@wrapMethod(W3PlayerWitcher)
function OnCombatStart()
{
	wrappedMethod();
	if(IsMutationActive(EPMT_Mutation7))
	{
		RemoveTimer('Mutation7CombatStartHackFix');
		RemoveTimer('Mutation7CombatStartHackFixGo');
		AddEffectDefault(EET_Mutation7Buff, this, "Mutation 7 buff phase");
		theGame.MutationHUDFeedback(MFT_PlayRepeat);
	}
}

// The base effect: no sonar or enemy count (legacy removed them).
@replaceMethod(W3Mutation7BaseEffect)
function OnEffectAdded( customParams : W3BuffCustomParams )
{
	super.OnEffectAdded( customParams );	//modSigns: removed the enemy count and the sonar
}

@replaceMethod(W3Mutation7BaseEffect)
function OnEffectRemoved()
{
	//modSigns: removed the sonar
	super.OnEffectRemoved();
}

@replaceMethod(W3Mutation7BaseEffect)
function OnUpdate(deltaTime : float)
{
	//modSigns: removed the sonar
	super.OnUpdate( deltaTime );	//modSigns
}

@replaceMethod(W3Mutation7BaseEffect)
function GetStacks() : int
{
	return RoundMath( 100 * apBonus * gmSavedFocusPts );	//modSigns: the bonus per adrenaline point held (Rush) or gained in the Rush (Recovery)
}

@replaceMethod(W3Effect_Mutation7Buff)
function OnEffectAdded( customParams : W3BuffCustomParams )
{
	var fxEntity : CEntity;	//modSigns

	super.OnEffectAdded( customParams );

	gmAccumulatedFocusPts = 0;	//modSigns
	gmSavedFocusPts = FloorF( target.GetStat( BCS_Focus ) );	//modSigns
	target.AddAbilityMultiple( 'Mutation7Buff', gmSavedFocusPts );	//modSigns: one bonus per adrenaline point held

	fxEntity = target.CreateFXEntityAtPelvis( 'mutation7_flash', false );	//modSigns
	fxEntity.PlayEffect( 'buff' );	//modSigns
	fxEntity.DestroyAfter( 10.f );	//modSigns
	target.PlayEffect( 'mutation_7_baff' );	//modSigns
	target.SoundEvent( 'ep2_mutations_07_berserk_buff' );
}

@replaceMethod(W3Effect_Mutation7Buff)
function OnUpdate(deltaTime : float)
{
	var curFocus : int;	//modSigns

	curFocus = FloorF( target.GetStat( BCS_Focus ) );	//modSigns: the bonus follows the adrenaline points held
	if( curFocus < gmSavedFocusPts )	//modSigns
		target.RemoveAbilityMultiple( 'Mutation7Buff', gmSavedFocusPts - curFocus );	//modSigns
	else if( curFocus > gmSavedFocusPts )	//modSigns
	{	//modSigns
		target.AddAbilityMultiple( 'Mutation7Buff', curFocus - gmSavedFocusPts );	//modSigns
		gmAccumulatedFocusPts += curFocus - gmSavedFocusPts;	//modSigns: points gained in the Rush
	}	//modSigns
	gmSavedFocusPts = curFocus;	//modSigns
	//modSigns: removed the sonar
}

@replaceMethod(W3Effect_Mutation7Buff)
function OnEffectAddedPost()
{
	var min, max : SAbilityAttributeValue;

	super.OnEffectAddedPost();

	//modSigns: removed the HUD feedback (it starts with combat, OnCombatStart)

	theGame.GetDefinitionsManager().GetAbilityAttributeValue( 'Mutation7Buff', 'attack_power', min, max );
	apBonus = min.valueMultiplicative;
}

@replaceMethod(W3Effect_Mutation7Buff)
function OnEffectRemoved()
{
	//modSigns: removed tempBuff
	var params 			: SCustomEffectParams;
	var mut7Params 		: W3Mutation7DebuffParams;

	target.RemoveAbilityAll( 'Mutation7Buff' );	//modSigns: before the Recovery starts
	target.StopEffect( 'mutation_7_baff' );	//modSigns

	if( target.IsInCombat() )
	{
		mut7Params = new W3Mutation7DebuffParams in theGame;
		mut7Params.GMSetSavedFocusPts( gmAccumulatedFocusPts );	//modSigns: the points gained in the Rush

		params.buffSpecificParams = mut7Params;
		params.creator = target;
		params.effectType = EET_Mutation7Debuff;
		params.sourceName = "Mutation 7 debuff phase";	//modSigns
		target.AddEffectCustom( params );
	}

	//modSigns: the abilities are removed above

	super.OnEffectRemoved();
}

@replaceMethod(W3Effect_Mutation7Debuff)
function OnEffectAdded( optional customParams : W3BuffCustomParams )
{
	var fxEntity : CEntity;
	var min, max : SAbilityAttributeValue;

	super.OnEffectAdded( customParams );

	gmSavedFocusPts = ((W3Mutation7DebuffParams)customParams).gmSavedFocusPts;	//modSigns: -50% per point gained in the Rush
	target.AddAbilityMultiple( 'Mutation7Debuff', gmSavedFocusPts );	//modSigns

	//modSigns: removed the paused Vitality regeneration

	fxEntity = target.CreateFXEntityAtPelvis( 'mutation7_flash', false );
	fxEntity.PlayEffect( 'debuff' );
	fxEntity.DestroyAfter( 10.f );
	target.PlayEffect( 'mutation_7_debaff' );
	target.SoundEvent( 'ep2_mutations_07_berserk_debuff' );
}

@replaceMethod(W3Effect_Mutation7Debuff)
function GetStacks() : int
{
	return RoundMath( 100 * apBonus * gmSavedFocusPts );	//modSigns: as the base effect's
}

@replaceMethod(W3Effect_Mutation7Debuff)
function OnEffectAddedPost()
{
	var min, max : SAbilityAttributeValue;

	super.OnEffectAddedPost();

	theGame.GetDefinitionsManager().GetAbilityAttributeValue( 'Mutation7Debuff', 'attack_power', min, max );
	apBonus = -min.valueMultiplicative;	//modSigns: shown as a positive percentage
}

@replaceMethod(W3Effect_Mutation7Debuff)
function OnEffectRemoved()
{
	target.RemoveAbilityAll( 'Mutation7Debuff' );
	//modSigns: removed the resumed Vitality regeneration

	//modSigns: removed the HUD feedback's end (the cycle goes on)

	target.StopEffect( 'mutation_7_debaff' );

	if( target.IsInCombat() )	//modSigns: the next Rush
		target.AddEffectDefault( EET_Mutation7Buff, target, "Mutation 7 buff phase" );	//modSigns

	super.OnEffectRemoved();
}
