// ENCH-14: Usurpation, Beguilement and Possession (Glyphwords 10, 14, 18) as legacy (changelist 991-992,
// 998-999, 1009-1011).
// - Usurpation: each enemy under Geralt's Axii Puppet gives +25% attack power and sign intensity
//   (`Glyphword 10 abl` on Geralt, up to 4).
// - Beguilement: each enemy Geralt's Axii confused gives +25% critical hit chance and power
//   (`Glyphword 14 abl`, up to 4).
//   A stack needs the word on the worn chest armor (ENCH-01) when the effect starts: the changelist's rule,
//   the owner's decision (legacy's AddGlyphwordBonuses gave the stacks for every Axii of Geralt's, with or
//   without the words; deviation, recorded).
// - Possession, from the chest armor (ENCH-01):
//  Axii moves to the nearest enemy when its target dies (enchantments/npcDeath.ws), and a
//   puppet's hits extend its Axii by 2 s (OnProcessActionPost, below); vanilla shared these with
//   Usurpation and Beguilement.
// A stack is added when the effect starts and removed when it ends. Stacks are not saved: a load
// removes them (legacy's load cleanup named the words' _Stats abilities instead). See docs/features/ench.md.

@addField(W3Effect_AxiiGuardMe)
var gmGlyphwordAblAdded : bool;
@addField(W3ConfuseEffect)
var gmGlyphwordAblAdded : bool;

// Adds a stack of the word's ability to Geralt for an effect his sign put on an enemy, while the stacks
// are below the maximum and the word is active (the changelist's rule); true when added.
function GMAddAxiiWordStack(word : name, abl : name, maxAttr : name, isOnPlayer : bool, creator : CGameplayEntity, isSignEffect : bool) : bool
{
	var min, max : SAbilityAttributeValue;
	var w : W3PlayerWitcher;

	w = GetWitcherPlayer();
	if(isOnPlayer || !w || creator != w || !isSignEffect || !w.HasGlyphwordActive(word))
		return false;
	theGame.GetDefinitionsManager().GetAbilityAttributeValue(abl, maxAttr, min, max);
	if(w.GetAbilityCount(abl) >= CalculateAttributeValue(min))
		return false;
	w.AddAbility(abl, true);
	return true;
}

@wrapMethod(W3Effect_AxiiGuardMe)
function OnEffectAdded(optional customParams : W3BuffCustomParams)
{
	wrappedMethod(customParams);
	gmGlyphwordAblAdded = GMAddAxiiWordStack('Glyphword 10 _Stats', 'Glyphword 10 abl', 'g10_max_stacks', isOnPlayer, GetCreator(), isSignEffect);
}

@wrapMethod(W3Effect_AxiiGuardMe)
function OnEffectRemoved()
{
	wrappedMethod();
	if(gmGlyphwordAblAdded)
		thePlayer.RemoveAbility('Glyphword 10 abl');
	gmGlyphwordAblAdded = false;
}

@wrapMethod(W3ConfuseEffect)
function OnEffectAdded(optional customParams : W3BuffCustomParams)
{
	wrappedMethod(customParams);
	gmGlyphwordAblAdded = GMAddAxiiWordStack('Glyphword 14 _Stats', 'Glyphword 14 abl', 'g14_max_stacks', isOnPlayer, GetCreator(), isSignEffect);
}

@wrapMethod(W3ConfuseEffect)
function OnEffectRemoved()
{
	wrappedMethod();
	if(gmGlyphwordAblAdded)
		thePlayer.RemoveAbility('Glyphword 14 abl');
	gmGlyphwordAblAdded = false;
}

// Stacks do not survive a load (their effects' flags are not saved).
@wrapMethod(W3PlayerWitcher)
function OnSpawned(spawnData : SEntitySpawnData)
{
	wrappedMethod(spawnData);
	RemoveAbilityAll('Glyphword 10 abl');
	RemoveAbilityAll('Glyphword 14 abl');
}

// Possession: a puppet's hits extend its Axii by 2 s (Beguilement no longer does). 5.x body; changes marked //modSigns.
@replaceMethod(CNewNPC)
function OnProcessActionPost(action : W3DamageAction)
{
	var actorVictim : CActor;
	var time, maxTox, toxToAdd : float;
	var gameplayEffect : CBaseGameplayEffect;
	var template : CEntityTemplate;
	var fxEnt : CEntity;
	var toxicity : SAbilityAttributeValue;
	
	super.OnProcessActionPost(action);
	
	
	actorVictim = (CActor)action.victim;
	if(HasBuff(EET_AxiiGuardMe) && GetWitcherPlayer().HasGlyphwordActive('Glyphword 18 _Stats') && action.DealtDamage())	//modSigns: ENCH-14, Possession only, from the chest armor (legacy)
	{
		time = CalculateAttributeValue(thePlayer.GetAttributeValue('increas_duration'));
		gameplayEffect = GetBuff(EET_AxiiGuardMe);
		gameplayEffect.SetTimeLeft( gameplayEffect.GetTimeLeft() + time );
		
		template = (CEntityTemplate)LoadResource('glyphword_10_18');
		
		if(GetBoneIndex('head') != -1)
		{				
			fxEnt = theGame.CreateEntity(template, GetBoneWorldPosition('head'), GetWorldRotation(), , , true);
			fxEnt.CreateAttachmentAtBoneWS(this, 'head', GetBoneWorldPosition('head'), GetWorldRotation());
		}
		else
		{
			fxEnt = theGame.CreateEntity(template, GetBoneWorldPosition('k_head_g'), GetWorldRotation(), , , true);
			fxEnt.CreateAttachmentAtBoneWS(this, 'k_head_g', GetBoneWorldPosition('k_head_g'), GetWorldRotation());
			
		}
		
		fxEnt.PlayEffect('axii_extra_time');
		fxEnt.DestroyAfter(5);
	}
	
	
	if( action.victim && action.victim == GetWitcherPlayer() && action.DealtDamage() )
	{
		toxicity = GetAttributeValue( 'toxicity_increase_on_hit' );
		if( toxicity.valueAdditive > 0.f || toxicity.valueMultiplicative > 0.f )
		{
			maxTox = GetWitcherPlayer().GetStatMax( BCS_Toxicity );
			toxToAdd = maxTox * toxicity.valueMultiplicative + toxicity.valueAdditive;
			GetWitcherPlayer().GainStat( BCS_Toxicity, toxToAdd );
		}
	}
}
