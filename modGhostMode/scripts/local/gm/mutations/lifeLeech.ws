// MUT-12 Life Leech (Mutation 11, legacy's replacement of Second Life) and the Mutation Catalyst.
// Drinking the Catalyst (a new potion: 3 charges, 20 toxicity; its recipe is given when the mutation
// is researched, and on load to a character who has it) in combat with Life Leech equipped and off
// cooldown starts it: up to 3 hostile enemies within 30 m are drained for 6 s, each at
// (sword base damage + average attack power % + average sign intensity %) x adrenaline / enemies per
// second (at least 1), and Geralt heals as much; he is immortal and gets a free alternate Quen
// meanwhile (legacy's, given by 5.x's shock wave during the animation); at the end a 5 m knockdown
// impulse (40 shock damage); then a 90 s cooldown. 5.x's death trigger (Second Life: full heal at 0
// Vitality) is gone (mutations/takeDamage.ws).
// See docs/features/mut.md.

// Life Leech's free Quen (legacy's freeCast): its channel's start pays nothing
// (skills/rageManagement.ws) and its end starts no cooldown (stamina/signCooldowns.ws).
@addField(W3QuenEntity)
public var gmFreeCast : bool;

// The last free Quen Life Leech gave (read by the tests).
@addField(W3PlayerWitcher)
public var gmLifeLeechQuen : W3QuenEntity;

// 5.x body; changes marked //modSigns. The shock wave during Life Leech's animation gives legacy's
// free alternate Quen: 1000000 health for 10 s, no stamina, adrenaline or Flood of Anger, not the
// player's sign cast (5.x: RestoreQuen, the Quen restored after a load).
@replaceMethod(W3PlayerWitcher)
function Mutation11ShockWave( skipQuenSign : bool )
{
	var action : W3DamageAction;
	var ents : array< CGameplayEntity >;
	var i, j : int;
	var damages : array< SRawDamage >;
	var quen : W3QuenEntity;	//modSigns


	FindGameplayEntitiesInSphere(ents, GetWorldPosition(), 5.f, 1000, '', FLAG_OnlyAliveActors + FLAG_ExcludeTarget + FLAG_Attitude_Hostile + FLAG_Attitude_Neutral, this);

	if( ents.Size() > 0 )
	{
		damages = theGame.GetDefinitionsManager().GetDamagesFromAbility( 'Mutation11' );
	}


	for(i=0; i<ents.Size(); i+=1)
	{
		action = new W3DamageAction in theGame;
		action.Initialize( this, ents[i], NULL, "Mutation11", EHRT_Heavy, CPS_SpellPower, false, false, true, false );

		for( j=0; j<damages.Size(); j+=1 )
		{
			action.AddDamage( damages[j].dmgType, damages[j].dmgVal );
		}

		action.SetCannotReturnDamage( true );
		action.SetProcessBuffsIfNoDamage( true );
		action.AddEffectInfo( EET_KnockdownTypeApplicator );
		action.SetHitAnimationPlayType( EAHA_ForceYes );
		action.SetCanPlayHitParticle( false );

		theGame.damageMgr.ProcessAction( action );
		delete action;
	}




	mutation11QuenEntity = ( W3QuenEntity )GetSignEntity( ST_Quen );
	if( !mutation11QuenEntity )
	{
		mutation11QuenEntity = (W3QuenEntity)theGame.CreateEntity( GetSignTemplate( ST_Quen ), GetWorldPosition(), GetWorldRotation() );
		mutation11QuenEntity.CreateAttachment( this, 'quen_sphere' );
		AddTimer( 'DestroyMutation11QuenEntity', 2.f );
	}
	mutation11QuenEntity.PlayHitEffect( 'quen_impulse_explode', mutation11QuenEntity.GetWorldRotation() );

	if( !skipQuenSign )
	{

		PlayEffect( 'mutation_11_second_life' );


		//modSigns: removed 5.x's RestoreQuen( 1000000.f, 10.f, true ): legacy's free alternate Quen instead
		quen = (W3QuenEntity)theGame.CreateEntity( signs[ST_Quen].template, GetWorldPosition(), GetWorldRotation() );	//modSigns
		quen.Init( signOwner, signs[ST_Quen].entity, true, true );	//modSigns: not the player's cast (no Flood of Anger, no adrenaline gain)
		quen.SetAlternateCast( S_Magic_s04 );	//modSigns
		quen.gmFreeCast = true;	//modSigns
		quen.OnStarted();	//modSigns
		quen.OnThrowing();	//modSigns
		quen.SetDataFromRestore( 1000000.f, 10.f );	//modSigns
		gmLifeLeechQuen = quen;	//modSigns
	}
}

// The Catalyst's effect: starts Life Leech, or does nothing.
class W3GMPotion_MutationTrigger extends CBaseGameplayEffect
{
	default effectType = EET_GMMutationTrigger;

	event OnEffectAdded(optional customParams : W3BuffCustomParams)
	{
		var witcher : W3PlayerWitcher;

		super.OnEffectAdded(customParams);
		if(!isOnPlayer)
		{
			timeLeft = 0;
			return false;
		}
		witcher = (W3PlayerWitcher)target;
		if( witcher.IsSwimming() || witcher.IsDiving() || witcher.IsSailing() || witcher.IsUsingHorse() || witcher.IsUsingBoat() || witcher.IsUsingVehicle() || witcher.IsUsingExploration() )
		{
			timeLeft = 0;
			return false;
		}
		if( witcher.IsInCombat() && witcher.IsMutationActive( EPMT_Mutation11 ) && !witcher.HasBuff( EET_Mutation11Debuff ) && !witcher.IsInAir() )
			witcher.OnMutation11Triggered();
		else
			timeLeft = 0;
	}
}

// The drain per second at 1 adrenaline point, before it is shared: the held (or equipped) sword's
// base damage + the average attack power of fast and strong attacks with each sword (crits weighted)
// in %, from the character stats list (UI-01, legacy) + the average sign intensity bonus in %.
@addMethod(W3PlayerWitcher)
function GMMutation11GetBaseStrength() : float
{
	var swordDmg, avAP, avSI : float;
	var abl : SAbilityAttributeValue;
	var curStats : SGMOffenseStats;
	var sword : SItemUniqueId;

	abl  = GetTotalSignSpellPower(S_Magic_1);
	abl += GetTotalSignSpellPower(S_Magic_2);
	abl += GetTotalSignSpellPower(S_Magic_3);
	abl += GetTotalSignSpellPower(S_Magic_4);
	abl += GetTotalSignSpellPower(S_Magic_5);
	avSI = MaxF(0.0, abl.valueMultiplicative / 5.0 - 1.0) * 100;
	curStats = GMGetOffenseStats();
	avAP = MaxF(0.0,
				(	curStats.steelFastAP * (1 - curStats.steelFastCritChance/100.0) + curStats.steelFastCritAP * curStats.steelFastCritChance/100.0
				+	curStats.silverFastAP * (1 - curStats.silverFastCritChance/100.0) + curStats.silverFastCritAP * curStats.silverFastCritChance/100.0
				+	curStats.steelStrongAP * (1 - curStats.steelStrongCritChance/100.0) + curStats.steelStrongCritAP * curStats.steelStrongCritChance/100.0
				+	curStats.silverStrongAP * (1 - curStats.silverStrongCritChance/100.0) + curStats.silverStrongCritAP * curStats.silverStrongCritChance/100.0
				)/4.0
		) * 100;
	sword = inv.GetCurrentlyHeldSword();
	if( sword == GetInvalidUniqueId() )
	{
		GetItemEquippedOnSlot(EES_SteelSword, sword);
		if( sword == GetInvalidUniqueId() )
			GetItemEquippedOnSlot(EES_SilverSword, sword);
	}
	if( sword != GetInvalidUniqueId() )
	{
		if( inv.GetItemCategory(sword) == 'steelsword' )
			swordDmg = GetTotalWeaponDamage(sword, theGame.params.DAMAGE_NAME_SLASHING, GetInvalidUniqueId());
		else if( inv.GetItemCategory(sword) == 'silversword' )
			swordDmg = GetTotalWeaponDamage(sword, theGame.params.DAMAGE_NAME_SILVER, GetInvalidUniqueId());
	}
	return swordDmg + avAP + avSI;
}

@addField(W3Effect_Mutation11Buff)
var gmDrainTemplate : CEntityTemplate;
@addField(W3Effect_Mutation11Buff)
var gmActors : array< CActor >;
@addField(W3Effect_Mutation11Buff)
var gmNumActors : int;
@addField(W3Effect_Mutation11Buff)
var gmDrainEnts : array< CEntity >;
@addField(W3Effect_Mutation11Buff)
var gmDrainStrength : float;

@addMethod(W3Effect_Mutation11Buff)
function GMGetDrainStrength() : float
{
	return gmDrainStrength;
}

@addMethod(W3Effect_Mutation11Buff)
function GMPlayDrainEnergy( npc : CActor )
{
	var targetNode, sourceNode : CNode;
	var drainEffectEntity : CEntity;

	targetNode = target.GetComponent("DrainEnergyTarget");
	if( !targetNode )
		targetNode = target;
	sourceNode = npc.GetComponent("torso3effect");
	if( !sourceNode )
		sourceNode = npc;
	drainEffectEntity = theGame.CreateEntity( gmDrainTemplate, sourceNode.GetWorldPosition(), target.GetWorldRotation() );
	drainEffectEntity.PlayEffect( 'drain_energy', targetNode );
	gmDrainEnts.PushBack( drainEffectEntity );
}

@addMethod(W3Effect_Mutation11Buff)
function GMAddDrainBuff( npc : CActor )
{
	var drainParams : SCustomEffectParams;

	drainParams.effectType	= EET_VitalityDrain;
	drainParams.creator		= target;
	drainParams.sourceName	= 'Mutation11';
	drainParams.duration	= initialDuration;
	drainParams.effectValue.valueAdditive = gmDrainStrength;
	npc.AddEffectCustom( drainParams );
}

// The end: a knockdown impulse (Mutation11's 40 shock damage) on hostile enemies within 5 m.
@addMethod(W3Effect_Mutation11Buff)
function GMImpulse()
{
	var ents : array<CGameplayEntity>;
	var i, j : int;
	var action : W3DamageAction;
	var damages : array< SRawDamage >;

	damages = theGame.GetDefinitionsManager().GetDamagesFromAbility( 'Mutation11' );
	FindGameplayEntitiesInRange(ents, target, 5.f, 1000, , FLAG_OnlyAliveActors + FLAG_ExcludeTarget + FLAG_Attitude_Hostile, target);
	for(i = 0; i < ents.Size(); i += 1)
	{
		action = new W3DamageAction in theGame;
		action.Initialize(target, ents[i], NULL, "Mutation11", EHRT_Heavy, CPS_SpellPower, false, false, true, false);
		for(j = 0; j < damages.Size(); j += 1)
			action.AddDamage(damages[j].dmgType, damages[j].dmgVal);
		action.AddEffectInfo(EET_KnockdownTypeApplicator);
		action.SetCannotReturnDamage(true);
		action.SetProcessBuffsIfNoDamage(true);
		action.SetHitAnimationPlayType(EAHA_ForceYes);
		action.SetHitEffectAllTypes('hit_electric_quen');
		theGame.damageMgr.ProcessAction(action);
		delete action;
	}
	target.PlayEffect('lasting_shield_discharge');
}

// The drain starts: up to 3 hostile enemies within 30 m (5.x: Vitality set to health_prc).
@replaceMethod(W3Effect_Mutation11Buff)
function OnEffectAdded( customParams : W3BuffCustomParams )
{
	var min, max			: SAbilityAttributeValue;
	var i					: int;	//modSigns
	var tmpActors			: array< CActor >;	//modSigns

	super.OnEffectAdded( customParams );

	//modSigns: removed the Vitality set to health_prc (Second Life's heal)
	gmDrainTemplate = (CEntityTemplate)LoadResource("fx\monsters\noonwraith\drain_energy\drain_energy.w2ent", true);	//modSigns
	tmpActors = GetActorsInRange( target, 30, 50, '', true );	//modSigns
	for(i = tmpActors.Size() - 1; i >= 0; i -= 1)	//modSigns
	{	//modSigns
		if( GetAttitudeBetween( target, tmpActors[i] ) != AIA_Hostile )	//modSigns
			tmpActors.Erase( i );	//modSigns
	}	//modSigns
	gmNumActors = Min(3, tmpActors.Size());	//modSigns
	for(i = 0; i < gmNumActors; i += 1)	//modSigns
		gmActors.PushBack(tmpActors[i]);	//modSigns
	gmDrainStrength = ((W3PlayerWitcher)target).GMMutation11GetBaseStrength() * target.GetStat(BCS_Focus);	//modSigns
	gmDrainStrength /= 1.0 * gmNumActors;	//modSigns
	gmDrainStrength = MaxF(1, gmDrainStrength);	//modSigns
	for(i = 0; i < gmActors.Size(); i += 1)	//modSigns
	{	//modSigns
		GMPlayDrainEnergy( gmActors[i] );	//modSigns
		GMAddDrainBuff( gmActors[i] );	//modSigns
	}	//modSigns
}

@replaceMethod(W3Effect_Mutation11Buff)
function OnEffectRemoved()
{
	var i : int;	//modSigns

	target.RemoveBuff( EET_Mutation11Immortal );


	target.AddEffectDefault( EET_Mutation11Debuff, NULL, "Mutation 11 Debuff", false );

	super.OnEffectRemoved();
	for( i = 0; i < gmDrainEnts.Size(); i += 1 )	//modSigns: the drain FX end
	{	//modSigns
		if( gmDrainEnts[i] )	//modSigns
		{	//modSigns
			gmDrainEnts[i].StopEffect( 'drain_energy' );	//modSigns
			gmDrainEnts[i].DestroyAfter( 3 );	//modSigns
		}	//modSigns
	}	//modSigns
	GMImpulse();	//modSigns: the knockdown impulse
}

// While it runs: the FX follow the drained enemies; Geralt heals by the drain of those alive.
class W3Effect_Mutation11Buff extends CBaseGameplayEffect
{
	event OnUpdate( deltaTime : float )	//modSigns
	{	//modSigns
		var i : int;	//modSigns
		var sourceNode : CNode;	//modSigns
		super.OnUpdate( deltaTime );	//modSigns
		gmNumActors = 0;	//modSigns
		for( i = 0; i < gmActors.Size(); i += 1 )	//modSigns
		{	//modSigns
			if( !gmActors[i].IsAlive() )	//modSigns
			{	//modSigns
				if( gmDrainEnts[i] && gmDrainEnts[i].IsEffectActive( 'drain_energy' ) )	//modSigns
				{	//modSigns
					gmDrainEnts[i].StopEffect( 'drain_energy' );	//modSigns
					gmDrainEnts[i].DestroyAfter( 3 );	//modSigns
				}	//modSigns
			}	//modSigns
			else	//modSigns
			{	//modSigns
				gmNumActors += 1;	//modSigns
				if( gmDrainEnts[i] )	//modSigns
				{	//modSigns
					sourceNode = gmActors[i].GetComponent("torso3effect");	//modSigns
					if( !sourceNode )	//modSigns
						sourceNode = gmActors[i];	//modSigns
					gmDrainEnts[i].Teleport( sourceNode.GetWorldPosition() );	//modSigns
				}	//modSigns
			}	//modSigns
		}	//modSigns
		target.Heal( gmDrainStrength * gmNumActors * deltaTime );	//modSigns
	}	//modSigns
}

// The Catalyst's recipe when the mutation is researched, and on load (a save that has it).
@wrapMethod(W3PlayerAbilityManager)
function OnMutationFullyResearched( mutationType : EPlayerMutationType )
{
	wrappedMethod(mutationType);
	if(mutationType == EPMT_Mutation11)
		GetWitcherPlayer().AddAlchemyRecipe('gm_recipe_mutation_catalyst', false, true);
}

@addMethod(W3PlayerWitcher)
function GMAddMutationCatalystRecipe()
{
	if(IsMutationResearched(EPMT_Mutation11) && !alchemyRecipes.Contains('gm_recipe_mutation_catalyst'))
		AddAlchemyRecipe('gm_recipe_mutation_catalyst', true, true);
}
