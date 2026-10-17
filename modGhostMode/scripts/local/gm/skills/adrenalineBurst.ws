// SKL-18: Adrenaline Burst, legacy's in both trees (D49; classic perk_10, the new tree's perk_42): +5%
// adrenaline gain (focus_gain, gm_skill_trees.xml and gm_skills.xml), and each adrenaline point held
// cuts the stamina cost of melee and agility actions by 10% (legacy's GetPerk10Bonus). 5.x's adrenaline
// for every sign cast moves to Focus (D40, skills/focusPerk.ws) and is gone here (W3SignEntity.Init,
// replaced), as is its point at a channel's start (skills/rageManagement.ws).
// See docs/features/skl.md.

@addMethod(W3PlayerWitcher)
function GMAdrenalineBurstCostCut() : float
{
	var skill : ESkill;

	if(CanUseSkill(S_Perk_10))
		skill = S_Perk_10;
	else if(CanUseSkill(S_Perk_42))
		skill = S_Perk_42;
	else
		return 0;
	return ClampF(FloorF(GetStat(BCS_Focus)) * CalculateAttributeValue(GetSkillAttributeValue(skill, 'stamina_cost_reduction', false, false)), 0, 1);
}

@wrapMethod(W3AbilityManager)
function GetStaminaActionCost(action : EStaminaActionType, out cost : float, out delay : float, optional fixedCost : float, optional fixedDelay : float, optional abilityName : name, optional dt : float, optional costMult : float)
{
	wrappedMethod(action, cost, delay, fixedCost, fixedDelay, abilityName, dt, costMult);
	if(owner == GetWitcherPlayer() && GMIsMeleeStaminaAction(action))
		cost *= 1 - GetWitcherPlayer().GMAdrenalineBurstCostCut();
}

// 5.x body; changes marked //modSigns.
@replaceMethod(W3SignEntity)
function Init( inOwner : W3SignOwner, prevInstance : W3SignEntity, optional skipCastingAnimation : bool, optional notPlayerCast : bool ) : bool
{
	//modSigns: removed player, focus
	var witcher: W3PlayerWitcher;

	owner = inOwner;
	fireMode = 0;
	GetSignStats();

	if ( skipCastingAnimation || owner.InitCastSign( this ) )
	{
		if(!notPlayerCast)
		{
			owner.SetCurrentlyCastSign( GetSignType(), this );
			CacheActionBuffsFromSkill();
		}


		if ( !skipCastingAnimation )
		{
			AddTimer( 'BroadcastSignCast', 0.8, false, , , true );
		}


		//modSigns: removed 5.x's Adrenaline Burst adrenaline for a sign cast (SKL-18: legacy's Focus, D40)


		witcher = (W3PlayerWitcher) owner.GetPlayer();
		if( witcher && !notPlayerCast )
		{
			if( witcher.IsMutationActive( EPMT_Mutation1 ) )
			{
				PlayMutation1CastFX();
			}
			else if( witcher.IsMutationActive( EPMT_Mutation6 ) )
			{
				theGame.MutationHUDFeedback( MFT_PlayOnce );
			}
		}

		return true;
	}
	else
	{
		owner.GetActor().SoundEvent( "gui_ingame_low_stamina_warning" );
		CleanUp();
		Destroy();
		return false;
	}
}
