// STAM-03: the alternate Yrden (trap) and Axii (puppet) channels always finish: running out of
// stamina, or of adrenaline when casting with it (Rage Management, SKL-18), does not stop them; releasing
// the sign still does (legacy; project owner, 2026-10-04: skills or items that lower a sign's start
// cost or raise its channel cost could otherwise let them run dry). Vanilla stops every channel at 0.
// Both trees: the alternate Yrden is the shared S_Magic_s03, the alternate Axii S_Magic_s05
// (classic) or S_Magic_s31 (Puppet, new tree). As in legacy, a drain that empties stamina no
// longer aborts the sign being cast (W3PlayerAbilityManager.DrainStamina below); each channel stops
// itself at 0 in Channeling.Update. See docs/features/stam.md.

function GMSignChannelFinishes(skill : ESkill) : bool
{
	return skill == S_Magic_s03 || skill == S_Magic_s05 || skill == S_Magic_s31;
}

// 5.x body; changes marked //modSigns.
@replaceMethod(W3SignEntityStateChanneling)
function Update() : bool
{
	var multiplier, avoidanceMult, stamina, leftStaminaCostPerc, leftStaminaCost, normalCastCost : float;	//modSigns: normalCastCost
	var player : CR4Player;
	var reductionCounter, signSkillAvoidanceLevel : int;
	var stop, abortAxii, signSkillAvoidanceActive : bool;
	var costReduction, minAvoidance, maxAvoidance : SAbilityAttributeValue;
	
	player = caster.GetPlayer();
	abortAxii = false;
	
	if(player)
	{
		if( player.HasBuff( EET_Mutation11Buff ) )
		{
			return true;
		}
		
		stop = false;
		stamina = player.GetStat(BCS_Stamina);
		if( ShouldStopChanneling() )
		{
			stop = true;
			abortAxii = true;
		}
		else
		{	
			if(parent.skipChannelCost)
			{
				stop = false;
			}
			else if(player.GMHasRageManagement() && parent.usedFocus)	//modSigns: a channel started with adrenaline (Rage Management, SKL-18) stops when adrenaline runs out
			{
				stop = player.GetStat(BCS_Focus) <= 0;	//modSigns
			}
			else
			{
				if(stamina <= 0)
				{
					stop = true;
				}
				else
				{
					stop = false;
				}
			}
			if( GMSignChannelFinishes( parent.skillEnum ) )	//modSigns: alternate Yrden and Axii are not stopped by running out of stamina or adrenaline
				stop = false;	//modSigns
		}
	}		
	
	if(stop)
	{
		if( ( parent.skillEnum == S_Magic_s05 || parent.skillEnum == S_Magic_s31 ) && abortAxii )		
		{
			OnSignAborted( true );
		}
		else
		{
			OnEnded();
		}
		
		return false;
	}
	else
	{
		if(player && !((W3QuenEntity)parent) )	
		{
			
		}
		
		
		reductionCounter = caster.GetSkillLevel(virtual_parent.skillEnum) - 1;
		multiplier = 1;
		if(reductionCounter > 0)
		{
			costReduction = caster.GetSkillAttributeValue(virtual_parent.skillEnum, 'stamina_cost_reduction_after_1', false, false) * reductionCounter;
			multiplier = 1 - costReduction.valueMultiplicative;
		}
		
		
		if (!(virtual_parent.GetSignType() == ST_Quen && caster.CanUseSkill(S_Magic_s04) && multiplier == 0) && !parent.skipChannelCost )
		{
			if(player)
			{
				if( parent.cachedCost <= 0.0f )
				{	
					parent.cachedCost = multiplier * player.GetStaminaActionCost( ESAT_Ability, SkillEnumToName( parent.skillEnum ), theTimer.timeDelta );
				}
			}
			
			if(player && player.GMHasRageManagement() && parent.usedFocus)	//modSigns: Rage Management (SKL-18, legacy): the frame's cost in adrenaline, as a share of a regular cast's stamina cost, x Flood of Anger
			{	//modSigns
				leftStaminaCost = multiplier * player.GetStaminaActionCost( ESAT_Ability, SkillEnumToName( parent.skillEnum ), theTimer.timeDelta );	//modSigns: each frame's own time (legacy: the first frame's)
				normalCastCost = ((W3PlayerAbilityManager)player.GetAbilityManager()).GetSkillStaminaUseCost(GMBaseSignSkill(parent.skillEnum));	//modSigns
				if(normalCastCost <= 0)	//modSigns
					normalCastCost = player.GetStatMax(BCS_Stamina);	//modSigns
				leftStaminaCostPerc = leftStaminaCost / normalCastCost;	//modSigns
				player.DrainFocus( MinF(player.GetStat(BCS_Focus), leftStaminaCostPerc * parent.GMFoaMult()) );	//modSigns
				//modSigns: removed 5.x's perk_34 drain (from max stamina x its cost by level) and its stop (the check above stops the channel)
			}	//modSigns
			else if(multiplier > 0.f)
			{
				caster.GetActor().DrainStamina( ESAT_Ability, 0, 0, SkillEnumToName( parent.skillEnum ), theTimer.timeDelta, multiplier );
			}
		}
		caster.OnProcessCastingOrientation( true );
	}
	return true;
}

// 5.x body; changes marked //modSigns. (Legacy's Mutagen 21 and adrenaline changes here are ALCH's
// and SKL's.)
@replaceMethod(W3PlayerAbilityManager)
function DrainStamina(action : EStaminaActionType, optional fixedCost : float, optional fixedDelay : float, optional abilityName : name, optional dt : float, optional costMult : float) : float
{	
	var cost : float;
	var mutagen : W3Mutagen21_Effect;
	var min, max : SAbilityAttributeValue;
	//modSigns: removed var signEntity (its use is removed below)
	
	if(FactsDoesExist("debug_fact_stamina_boy"))
		return 0;
		
	cost = super.DrainStamina(action, fixedCost, fixedDelay, abilityName, dt, costMult);
	
	if(cost > 0 && dt > 0)
	{
		
		owner.AddTimer('AbilityManager_FloorStaminaSegment', 0.1, , , , true);
	}
	
	
	if (cost > 0 && dt <= 0 && owner == thePlayer && thePlayer.HasBuff(EET_Mutagen21) && abilityName != 'sword_s1' && abilityName != 'sword_s2' && abilityName != 'GM_C_sword_s2')	//modSigns: SKL, Rend's classic-tree ability
	{	
		mutagen = (W3Mutagen21_Effect)thePlayer.GetBuff(EET_Mutagen21);
		mutagen.Heal();
	}
	
	
	
	if(cost > 0 && owner == GetWitcherPlayer() && GetWitcherPlayer().GetCurrentSignEntity())	//modSigns: SKL-18, Focus: a sign's stamina earns adrenaline (legacy's ManageFocusGain; skills/focusPerk.ws)
		GetWitcherPlayer().GetCurrentSignEntity().GMManageFocusGain(cost, dt);	//modSigns

	//modSigns: removed the abort of the sign being cast when stamina reaches 0 (each channel stops itself at 0 in Channeling.Update, except the alternate Yrden and Axii)
	
	return cost;
}
