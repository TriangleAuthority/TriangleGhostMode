// SKL-18: Rage Management, legacy's in both trees (D49; classic perk_9, the new tree's perk_34, which 5.x
// calls Anger Management): with at least 1 adrenaline point a sign is paid with adrenaline instead of
// stamina (adrenaline first): 1 point for a cast or a channel's start, and a channel's cost per second
// in points, the share of a normal cast's stamina cost it would take (Channeling.Update,
// stamina/channelStamina.ws; the alternate Quen's absorption, skills/quen.ws). 5.x's rules are dropped:
// perk_9 only when stamina runs out, perk_34 2/1.5/1 points by level whenever stamina is not full.
// A cast or channel start paid with adrenaline sets the sign's usedFocus, which the channel's drain
// and Quen's shield read; such a start does not pause stamina regeneration (legacy). Flood of Anger
// multiplies these costs (GMFoaMult, SKL-07), and its points are paid also on a cast the Gryphon set or
// Glyphword 22 makes free (legacy pays every cast). The alternate Aard's entity sits 1 m lower (SKL-08,
// legacy's bugfix 35).
// See docs/features/skl.md.

// Whether Geralt casts with adrenaline first: Rage Management in either tree.
@addMethod(CR4Player)
function GMHasRageManagement() : bool
{
	return CanUseSkill(S_Perk_09) || CanUseSkill(S_Perk_34);
}

// The base sign of a sign skill (legacy's GetBaseSignSkill), with the new tree's alternate casts
// (Firestream magic_s28, Puppet magic_s31); S_SUndefined for other skills.
function GMBaseSignSkill(skill : ESkill) : ESkill
{
	switch(skill)
	{
		case S_Magic_1:
		case S_Magic_s01:
			return S_Magic_1;
		case S_Magic_2:
		case S_Magic_s02:
		case S_Magic_s28:
			return S_Magic_2;
		case S_Magic_3:
		case S_Magic_s03:
			return S_Magic_3;
		case S_Magic_4:
		case S_Magic_s04:
			return S_Magic_4;
		case S_Magic_5:
		case S_Magic_s05:
		case S_Magic_s31:
			return S_Magic_5;
	}
	return S_SUndefined;
}

// Flood of Anger's cost multiplier for this cast: 3 when it is used, else 1 (set by SKL-07's code).
@addField(W3SignEntity)
var gmFoaMult : float;

@addMethod(W3SignEntity)
function GMFoaMult() : float
{
	if(gmFoaMult < 1)
		return 1;
	return gmFoaMult;
}

// Whether Flood of Anger is used by this cast (its cost is paid on top of a stamina cast).
@addMethod(W3SignEntity)
function GMUsedFoA() : bool
{
	return GMFoaMult() > 1;
}

// A cast's or a channel's start cost for Geralt: 1 adrenaline point (x Flood of Anger) with Rage
// Management and at least 1 point, else stamina (plus Flood of Anger's points). With payStamina false
// the stamina cost is left to the caller.
@addMethod(W3SignEntity)
function GMPaySignCost(player : CR4Player, payStamina : bool, optional focusCostIfAny : bool)
{
	if(player.GMHasRageManagement() && player.GetStat(BCS_Focus) >= 1)
	{
		if(!focusCostIfAny || cachedCost > 0)
			player.DrainFocus(1 * GMFoaMult());
		SetUsedFocus(true);
	}
	else
	{
		if(payStamina)
			player.DrainStamina(ESAT_Ability, 0, 0, SkillEnumToName(skillEnum));
		SetUsedFocus(false);
		if(GMUsedFoA())
			player.DrainFocus(1 * GMFoaMult());
	}
}

// 5.x body; changes marked //modSigns.
@replaceMethod(W3SignEntity)
function ManagePlayerStamina()
{
	var l_player			: W3PlayerWitcher;
	//modSigns: removed l_cost, l_stamina
	var l_gryphonBuff		: W3Effect_GryphonSetBonus;

	if ( disableCost )
	{
		return;
	}

	l_player = owner.GetPlayer();

	l_gryphonBuff = (W3Effect_GryphonSetBonus)l_player.GetBuff( EET_GryphonSetBonus );
	l_gryphonBuff.SetWhichSignForFree( this );

	if( (!l_gryphonBuff || l_gryphonBuff.GetWhichSignForFree() != this) && !l_player.HasAbility('Glyphword 22 Bonus', true))
	{
		GMPaySignCost(l_player, true);	//modSigns: legacy's Rage Management, adrenaline first (5.x: perk_9 only when stamina runs out, perk_34 by level)
	}	//modSigns
	else if(GMUsedFoA())	//modSigns: SKL-07, a free cast still pays Flood of Anger's adrenaline (legacy pays every cast in full; SKL audit F3)
	{	//modSigns
		l_player.DrainFocus(1 * GMFoaMult());	//modSigns
	}	//modSigns

	l_player.RemoveAbility('Glyphword 22 Bonus');

}

// 5.x body; changes marked //modSigns.
@replaceMethod(W3AardEntityStateAardCircleCast)
function OnThrowing()
{
	var player : CR4Player;
	var pos : Vector;	//modSigns
	//modSigns: removed cost, stamina

	if( super.OnThrowing() )
	{
		pos = parent.GetWorldPosition();	//modSigns: SKL-08, the entity 1 m lower (legacy's bugfix 35: the water ripples)
		pos.Z -= 1;	//modSigns
		parent.Teleport(pos);	//modSigns
		parent.ProcessThrow( true );

		player = caster.GetPlayer();
		if(player == caster.GetActor() && player)	//modSigns: Rage Management in either tree
		{
			//modSigns: removed 5.x's perk_9 rule (adrenaline only when stamina runs out)
			parent.GMPaySignCost(player, true);	//modSigns: legacy's Rage Management, adrenaline first
		}
		//modSigns: removed 5.x's perk_34 branch (adrenaline by level whenever stamina is not full)
		else
			caster.GetActor().DrainStamina( ESAT_Ability, 0, 0, SkillEnumToName( parent.skillEnum ) );
	}
}

// 5.x body; changes marked //modSigns.
@replaceMethod(W3SignEntityStateChanneling)
function OnEnterState( prevStateName : name )
{
	var player : CR4Player;
	var actor : CActor;
	var currentSign : ESignType;
	var hasConvergenceTheoryBuff : bool;


	super.OnEnterState( prevStateName );
	parent.cachedCost = -1.0f;

	actor = caster.GetActor();
	player = (CR4Player)actor;

	//modSigns: removed 5.x's perk_34 adrenaline cost for the alternate Yrden (YrdenChanneled.OnEnterState pays it)

	theGame.GetBehTreeReactionManager().CreateReactionEventIfPossible( parent.owner.GetActor(), 'CastSignAction', -1, 8.0f, 0.2f, -1, true );
	theGame.GetBehTreeReactionManager().CreateReactionEventIfPossible( parent, 'CastSignActionFar', -1, 30.0f, -1.f, -1, true );

	if(player)
	{

		currentSign = virtual_parent.GetSignType();
		hasConvergenceTheoryBuff = player.HasBuff( EET_ConvergenceTheory );

		if ( currentSign != GetWitcherPlayer().GetLastUsedSign() && player.CanUseSkill(S_Magic_s37) )
		{
			player.AddEffectDefault( EET_ConvergenceTheory, NULL, "ConvergenceTheoryEffect" );
		}
		else
		{
			if (hasConvergenceTheoryBuff)
			{
				GetWitcherPlayer().RemoveBuff( EET_ConvergenceTheory, false, "ConvergenceTheoryEffect" );
			}
		}
		GetWitcherPlayer().SetLastUsedSign(currentSign);
	}
}

// 5.x body; changes marked //modSigns. The channels' start cost (Igni, Quen, Axii; the alternate Yrden
// pays on entering its channel, as legacy; Life Leech's free Quen pays nothing, MUT-12).
@replaceMethod(W3SignEntityStateChanneling)
function OnThrowing()
{
	var actor : CActor;
	var player : CR4Player;
	var stamina : float;

	if( super.OnThrowing() )
	{
		if((W3QuenEntity)parent && ((W3QuenEntity)parent).gmFreeCast)	//modSigns: MUT-12, Life Leech's free Quen: no stamina, adrenaline or regen pause
			return true;	//modSigns

		actor = caster.GetActor();
		player = (CR4Player)actor;

		if((W3YrdenEntity)parent)	//modSigns: paid in YrdenChanneled.OnEnterState
			return true;	//modSigns

		if(player)
		{
			if( parent.cachedCost <= 0.0f )
			{
				parent.cachedCost = player.GetStaminaActionCost( ESAT_Ability, SkillEnumToName( parent.skillEnum ), 0 );
			}

			stamina = player.GetStat(BCS_Stamina);
		}

		if(player)	//modSigns: legacy's Rage Management, adrenaline first (a point only if the start costs anything)
		{	//modSigns
			parent.GMPaySignCost(player, true, true);	//modSigns
			if(!parent.GetUsedFocus())	//modSigns: the regen pauses only for a start paid with stamina (legacy; SKL audit F26)
			{	//modSigns
				actor.StartStaminaRegen();	//modSigns
				actor.PauseStaminaRegen( 'SignCast' );	//modSigns
			}	//modSigns
		}	//modSigns
		else	//modSigns
		{	//modSigns
			actor.DrainStamina( ESAT_Ability, 0, 0, SkillEnumToName( parent.skillEnum ) );
			actor.StartStaminaRegen();
			actor.PauseStaminaRegen( 'SignCast' );
		}	//modSigns

		//modSigns: removed 5.x's Adrenaline Burst point at a channel's start (SKL-18, legacy's Adrenaline Burst: skills/adrenalineBurst.ws)

		//modSigns: removed 5.x's perk_34 (only adrenaline for Igni and Quen, Axii's channel prepaid)

		return true;
	}

	return false;
}

// 5.x body; changes marked //modSigns. The alternate Yrden's start cost, before its channel (legacy).
@replaceMethod(W3YrdenEntityStateYrdenChanneled)
function OnEnterState( prevStateName : name )
{
	var player : CR4Player;	//modSigns

	super.OnEnterState( prevStateName );

	caster.OnDelayOrientationChange();
	player = caster.GetPlayer();	//modSigns
	if(player && player == caster.GetActor())	//modSigns: legacy's Rage Management, adrenaline first
	{	//modSigns
		parent.cachedCost = player.GetStaminaActionCost( ESAT_Ability, SkillEnumToName( parent.skillEnum ), 0 );	//modSigns
		parent.GMPaySignCost(player, true, true);	//modSigns
		parent.cachedCost = -1.0f;	//modSigns: the channel computes its cost per second
		if(!parent.GetUsedFocus())	//modSigns: the regen pauses only for a start paid with stamina (legacy; SKL audit F26)
		{	//modSigns
			player.StartStaminaRegen();	//modSigns
			player.PauseStaminaRegen( 'SignCast' );	//modSigns
		}	//modSigns
	}	//modSigns
	else	//modSigns
		caster.GetActor().PauseStaminaRegen( 'SignCast' );
	ChannelYrden();
}

// 5.x body; changes marked //modSigns. The check before a cast.
@replaceMethod(CR4Player)
function HasStaminaToUseSkill(skill : ESkill, optional perSec : bool, optional signHack : bool) : bool
{
	var ret, signSkillAvoidanceActive : bool;
	var cost, avoidanceMult : float;
	var signSkillAvoidanceLevel : int;
	var minAvoidance, maxAvoidance : SAbilityAttributeValue;

	cost = GetSkillStaminaUseCost(skill, perSec);


	if(thePlayer.CanUseSkill(S_Magic_s39) && IsSkillSign(skill))
	{
		avoidanceMult = 1;
		signSkillAvoidanceLevel = thePlayer.GetSkillLevel( S_Magic_s39 );
		signSkillAvoidanceActive = signSkillAvoidanceLevel >= 1 && thePlayer.HasBuff( EET_Avoidance ) && thePlayer.CanUseSkill(S_Magic_s39);
		if (signSkillAvoidanceActive)
		{
			theGame.GetDefinitionsManager().GetAbilityAttributeValue('magic_s39', 'stamina_cost_reduction', minAvoidance, maxAvoidance);
			avoidanceMult = 1 - ( minAvoidance.valueMultiplicative * signSkillAvoidanceLevel );
		}
		cost *= avoidanceMult;

	}

	ret = ( CanUseSkill(skill) && (abilityManager.GetStat(BCS_Stamina, signHack) >= cost) );


	if(!ret && IsSkillSign(skill) && GMHasRageManagement() && GetStat(BCS_Focus) >= 1)	//modSigns: Rage Management in either tree, 1 point (5.x: perk_34 by level; supercharged signs)
	{
		ret = true;
	}

	//modSigns: removed 5.x's perk_34 check


	if( !ret && IsSkillSign( skill ) && GetWitcherPlayer().HasBuff( EET_GryphonSetBonus ) )
	{
		ret = true;
	}

	if(!ret)
	{
		SetCombatActionHeading( GetHeading() );
		SetShowToLowStaminaIndication(cost);
	}

	return ret;
}

// 5.x body; changes marked //modSigns. 5.x's quick-released Firestream that throws a regular Igni pays
// a regular cast (legacy has none of it).
@replaceMethod(CR4Player)
function NGE_DrainIgniStamina(dt:float, id:int)
{
	if( GMHasRageManagement() && GetStat(BCS_Focus) >= 1 )	//modSigns: legacy's Rage Management, adrenaline first
	{
		DrainFocus(1);
	}
	else
	{
		DrainStamina( ESAT_Ability, 0, 0, SkillEnumToName( S_Magic_2 ) );
	}
	//modSigns: removed 5.x's perk_9 (only when stamina runs out) and perk_34 branches
}
