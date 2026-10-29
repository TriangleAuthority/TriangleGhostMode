// AI-14 (monster fixes): cyclopes lose ablIgnoreSigns, so Axii's confusion (and the other signs' critical
// states) take on them (changelist 1120); arachases move at 75% animation speed; the Hearts of Stone toad
// stays in Yrden's trap however often it is hit (its Yrden task no longer ends on a third hit); an NPC's Quen
// staggers a melee attacker with the stagger's default length (1.32 and 5.x: 0.1 s). The cyclops and arachas
// lines run where legacy put them, in AI-01's AddLevelBonuses (ai/levels.ws). The fiend's close-range branch
// (bugfix 77) is 5.x's own tree (PA9); the sorceress's hand effect is 5.x's. See docs/features/ai.md.

// AI-14: the id of the arachas's animation speed causer (legacy's CNewNPC.animSpeedMult), so a recompute of
// the level bonuses replaces it instead of stacking another. Never id 0 (GMSetAnimSpeedCauser).
@addField(CNewNPC)
public var gmArachasSpeedId : int;

@addField(CNewNPC)
public var gmArachasSpeedSet : bool;

// AI-14 (AI-B audit F1), SKL-10: sets an animation speed causer that is never id 0, and returns its id (pass it
// back to change the same causer; 0: a new one). SetAnimationSpeedMultiplier's optional id defaults to 0, so
// every caller that leaves it out (5.x's frost slowdown, Blizzard, the slowdown effect's decay) overwrites causer
// 0 and later removes it: a causer that took id 0 (an actor's first) would lose its value and then vanish. Id 0
// is taken and released here, so no causer of this actor gets it afterwards (the counter only grows).
@addMethod(CActor)
function GMSetAnimSpeedCauser(mul : float, optional id : int) : int
{
	var newId : int;

	if( id == 0 )
		id = -1;
	newId = SetAnimationSpeedMultiplier(mul, id);
	if( newId == 0 )
	{
		ResetAnimationSpeedMultiplier(0);
		newId = SetAnimationSpeedMultiplier(mul, -1);
	}
	return newId;
}

// AI-14: legacy's two lines in AddLevelBonuses, run on every recompute.
@addMethod(CNewNPC)
function GMMonsterFixes()
{
	if( HasAbility('mon_cyclops') && HasAbility('ablIgnoreSigns') )
		RemoveAbilityAll('ablIgnoreSigns');

	if( HasAbility('mon_arachas_base') )
	{
		gmArachasSpeedId = GMSetAnimSpeedCauser(0.75, gmArachasSpeedId);
		gmArachasSpeedSet = true;
	}
}

// AI-14: the toad stays in Yrden until it leaves the trap or its time runs out (5.x's body; legacy removed the
// third-hit branch).
@replaceMethod(CBTTaskToadYrden)
function Main(): EBTNodeStatus
{
	while( true )
	{
		if ( leftYrden )
			break;
		//modSigns: removed else if ( npc.GetHitCounter() >= 3 ) { break; }
		else if ( theGame.GetEngineTimeAsSeconds() > enterTimestamp + leaveAfter )
		{
			break;
		}

		SleepOneFrame();
	}

	return BTNS_Completed;

}

// AI-14: an NPC's Quen staggers a melee attacker with the stagger effect's default length (5.x: 0.1 s).
function GMNpcQuenStagger( attacker : CActor, caster : CActor )
{
	if( attacker )
		attacker.AddEffectDefault( EET_Stagger, caster, "quen", true );
}

@replaceMethod(CBTTaskCastQuen)
function ProcessAction( data : CDamageData )
{
	var npc 	: CNewNPC = GetNPC();
	var params 	: SCustomEffectParams;

	if ( data.isActionMelee )
	{
		//modSigns: removed params.effectType = EET_Stagger; params.creator = GetActor(); params.sourceName = "quen"; params.duration = 0.1; ((CActor)data.attacker).AddEffectCustom( params );
		GMNpcQuenStagger( (CActor)data.attacker, GetActor() );	//modSigns: the default stagger
	}


}
