// ALCH-14: bombs (legacy's, the owner's DL7 and DL11). Data in gm_alch.xml (gen_alch.py): fixed damage,
// clouds 3/4/5 s, Dragon's Dream, Northern Wind's +25/35/50% (5.x's PoisonDeath block kept), Samum's
// 4/5/6 s blindness with +50/75/100% crit chance against the blinded enemy (the blindness effect's ability,
// read for Geralt's hits: skills/oils.ws), Silver Dust 20/30/40 s. Here: only Grapeshot level 3 breaks
// shields; the selected bomb destroys a monster nest; Silver Dust's legacy blocks, never on Geralt; specters
// under Silver Dust cannot teleport and their drain dance heals a quarter; 5.x's level-3 Samum certain crit
// and 5.x's potion duration bonus to bomb damage removed (damage/pool.ws, heavyArtilleryTrickShot.ws, the
// critical damage over time below).
// See docs/features/alch.md.

// 5.x body; changes marked //modSigns.
@replaceMethod(W3Petard)
function OnProjectileCollision( pos, normal : Vector, collidingComponent : CComponent, hitCollisionsGroups : array< name >, actorIndex : int, shapeIndex : int )
{
	var depthTestPos, petardPos, collisionPos, collisionNormal, yVec : Vector;
	var template : CEntityTemplate;
	var npc : CNewNPC;
	var victim : CActor;
	var entity : CEntity;
	var rot : EulerAngles;
	var rotMatrix, m1, m2, m3 : Matrix;
	var waterEntity : CEntity; 
	
	if(stopCollisions)
		return true;
	
	OnImpact();
	
	if(collidingComponent)
		entity = collidingComponent.GetEntity();
	
	
	if(entity == GetOwner())
		return true;
		
	if(collidingComponent)
	{
		victim = (CActor)entity;
		npc = (CNewNPC)(victim);
	}
		
	if ( !CanCollideWithVictim( victim ) )
		return true;
	
	impactNormal = normal;
	
	
	if ( npc && npc.HasAbility( 'RepulseProjectiles' ) )
	{
		bounceOfVelocityPreserve = 0.8;
		BounceOff( normal, pos );
		victim.PlayEffect( 'lightning', this );
		this.Init( npc );
		return true;
	}
	
	victim.SignalGameplayEvent( 'HitByBomb' );	
	
	
	if( itemName == 'Grapeshot 3' )	//modSigns: only Grapeshot level 3 breaks shields (legacy)
	{
		if( npc && npc.IsShielded( thePlayer ) )
		{
			npc.ProcessShieldDestruction();
		}
	}
	
	
	
	
		
	
	if ( hitCollisionsGroups.Contains( 'Water' ) )
	{
		if(isInWater)
			return true;
			
		isInWater = true;
	
		petardPos = GetWorldPosition();
		depthTestPos = petardPos;
		depthTestPos.Z -= 1;
		
		if ( !theGame.GetWorld().StaticTrace(petardPos, depthTestPos, collisionPos, collisionNormal, snapCollisionGroupNames) )
			isInDeepWater = true;
		
		
		
		
		if(isInWater && !waterFXPlayed)
		{
			template = (CEntityTemplate)LoadResource("water_splash_small");
			waterEntity = theGame.CreateEntity(template, petardPos, thePlayer.GetWorldRotation());				
			if(isInDeepWater)
				waterEntity.PlayEffect('splash_big');
			else
				waterEntity.PlayEffect('splash');
			waterFXPlayed = true;
			waterEntity.AddTag('bomb_water_splash');
			waterEntity.DestroyAfter(6.f);
			waterEntity.SoundEvent("fx_water_object_splash_small");
		}
		
		if(isInDeepWater)
		{
			stopCollisions = true;
			DestroyAfter(3);
		}
		
		return true;
	}
	
	
	StopFlying();		
		
	if(isProximity || FactsQuerySum('debug_petards_proximity') > 0)
	{
		PlayEffectSingle('sparks');
		
		GetComponent("ProximityActivationArea").SetEnabled(true);
		AddTimer( 'DetonationTimer', theGame.params.PROXIMITY_PETARD_IDLE_DETONATION_TIME, , , , true );
		isStuck = true;
	}
	else
	{
		ProcessEffect( pos, (CGameplayEntity)entity );
	}
	
	if( alignToNormal )
	{
		
		
		
		m1 = MatrixBuildFromDirectionVector( normal );
		m2 = MatrixBuiltRotation( EulerAngles( -90, 0, 0 ) );
		m3 = m1 * m2;
		rot = MatrixGetRotation( m3 );
		
		TeleportWithRotation( GetWorldPosition(), rot );
		
	}
}

// 5.x body; changes marked //modSigns.
@replaceMethod(CMonsterNestEntity)
function PlayerHasBombActivator() : bool
{
	var i,j : int;
	var items : array<SItemUniqueId>;
	var selectedItem : SItemUniqueId;	//modSigns
	
	playerInventory = thePlayer.GetInventory();
	selectedItem = thePlayer.GetSelectedItemId();	//modSigns: ALCH-14, the selected bomb first (legacy)
	if( selectedItem != GetInvalidUniqueId() && bombActivators.Contains( playerInventory.GetItemName( selectedItem ) ) && playerInventory.SingletonItemGetAmmo( selectedItem ) > 0 )	//modSigns
	{	//modSigns
		usedBomb = selectedItem;	//modSigns
		return true;	//modSigns
	}	//modSigns
	
	for( i = 0; i < bombActivators.Size(); i += 1 )
	{
		
		if( playerInventory.HasItem( bombActivators[i] ))
		{
			items.Clear();
			items = playerInventory.GetItemsByName(bombActivators[i]);				
			for(j=0; j<items.Size(); j+=1)
			{
				
				if( playerInventory.SingletonItemGetAmmo(items[j]) > 0 )
				{
					usedBomb = items[j];
					return true;
				}
			}
		}
	}
	return false;
}

// 5.x body; changes marked //modSigns.
@replaceMethod(W3DamageManagerProcessor)
function ProcessCriticalHitCheck()
{
	var critChance, critDamageBonus : float;
	var	canLog, meleeOrRanged, redWolfSet, isLightAttack, isHeavyAttack, mutation2 : bool;
	var arrStr : array<string>;
	//modSigns: removed var samum
	var signPower, min, max : SAbilityAttributeValue;
	var aerondight : W3Effect_Aerondight;
	var witcherAttacker : W3PlayerWitcher;
	
	
	witcherAttacker = GetWitcherPlayer();
	meleeOrRanged = playerAttacker && attackAction && ( attackAction.IsActionMelee() || attackAction.IsActionRanged() );
	redWolfSet = ( W3Petard )action.causer && ( W3PlayerWitcher )actorAttacker && GetWitcherPlayer().IsSetBonusActive( EISB_RedWolf_1 );
	mutation2 = ( W3PlayerWitcher )actorAttacker && GetWitcherPlayer().IsMutationActive(EPMT_Mutation2) && action.IsActionWitcherSign();
	
	if( meleeOrRanged || redWolfSet || mutation2 )
	{
		canLog = theGame.CanLog();
	
		
		if( mutation2 )
		{
			if( FactsQuerySum('debug_fact_critical_boy') > 0 )
			{
				critChance = 1.f;
			}
			else
			{
				signPower = action.GetPowerStatValue();
				theGame.GetDefinitionsManager().GetAbilityAttributeValue('Mutation2', 'crit_chance_factor', min, max);
				critChance = min.valueAdditive + signPower.valueMultiplicative * min.valueMultiplicative;
			}
		} 			
		else
		{
			if( attackAction )
			{				
				
				if(GetWitcherPlayer() && GetWitcherPlayer().HasRecentlyCountered() && playerAttacker.CanUseSkill(S_Sword_s11) && playerAttacker.GetSkillLevel(S_Sword_s11) > 2)
				{
					critChance += CalculateAttributeValue(playerAttacker.GetSkillAttributeValue(S_Sword_s11, theGame.params.CRITICAL_HIT_CHANCE, false, true));
				}
				
				if(GetWitcherPlayer() && (GetWitcherPlayer().HasRecentlyCountered() || GetWitcherPlayer().HasRecentlyDodged()) && attackAction.GetAttackName() != 'counter_attack_light' 
					&& playerAttacker.CanUseSkill(S_Sword_s31) && playerAttacker.GetSkillLevel(S_Sword_s31) > 3)
				{
					critChance += CalculateAttributeValue(playerAttacker.GetSkillAttributeValue(S_Sword_s31, theGame.params.CRITICAL_HIT_CHANCE, false, true));
				}

				
				isLightAttack = playerAttacker.IsLightAttack( attackAction.GetAttackName() );
				isHeavyAttack = playerAttacker.IsHeavyAttack( attackAction.GetAttackName() );
				critChance += playerAttacker.GetCriticalHitChance(isLightAttack, isHeavyAttack, actorVictim, victimMonsterCategory, (W3BoltProjectile)action.causer );
				
				
				if(action.GetIsHeadShot())
				{
					critChance += theGame.params.HEAD_SHOT_CRIT_CHANCE_BONUS;
					actorVictim.SignalGameplayEvent( 'Headshot' );
				}
				
				
				if ( actorVictim && actorVictim.IsAttackerAtBack(playerAttacker) )
				{
					critChance += theGame.params.BACK_ATTACK_CRIT_CHANCE_BONUS;
				}
					
				
				if( action.IsActionMelee() && playerAttacker.inv.ItemHasTag( attackAction.GetWeaponId(), 'Aerondight' ) )
				{
					aerondight = (W3Effect_Aerondight)playerAttacker.GetBuff( EET_Aerondight );
					
					if( aerondight && aerondight.IsFullyCharged() )
					{
						
						min = playerAttacker.GetAbilityAttributeValue( 'AerondightEffect', 'crit_chance_bonus' );
						critChance += min.valueAdditive;
					}
				}


			}
			else
			{
				
				critChance += playerAttacker.GetCriticalHitChance(false, false, actorVictim, victimMonsterCategory, (W3BoltProjectile)action.causer );
			}
			
			
			//modSigns: removed 5.x's certain crit against a level-3 Samum's blindness (ALCH-14: legacy's crit bonus by level, skills/oils.ws)
		}
		
		
		if ( canLog )
		{
			
			critDamageBonus = 1 + CalculateAttributeValue(actorAttacker.GetCriticalHitDamageBonus(weaponId, victimMonsterCategory, actorVictim.IsAttackerAtBack(playerAttacker)));
			critDamageBonus += CalculateAttributeValue(actorAttacker.GetAttributeValue('critical_hit_chance_fast_style'));
			critDamageBonus = 100 * critDamageBonus;
			
			
			LogDMHits("", action);				
			LogDMHits("Trying critical hit (" + NoTrailZeros(critChance*100) + "% chance, dealing " + NoTrailZeros(critDamageBonus) + "% damage)...", action);
		}
		
		
		if(RandF() < critChance) 
		{
			
			action.SetCriticalHit();
							
			if ( canLog )
			{
				LogDMHits("********************", action);
				LogDMHits("*** CRITICAL HIT ***", action);
				LogDMHits("********************", action);				
			}
			
			arrStr.PushBack(action.attacker.GetDisplayName());
			theGame.witcherLog.AddCombatMessage(theGame.witcherLog.COLOR_GOLD_BEGIN + GetLocStringByKeyExtWithParams("hud_combat_log_critical_hit",,,arrStr) + theGame.witcherLog.COLOR_GOLD_END, action.attacker, NULL);
		}
		else if ( canLog )
		{
			LogDMHits("... nope", action);
		}
	}	
}

// 5.x body; changes marked //modSigns.
@replaceMethod(W3Effect_SilverDust)
function OnEffectAdded(optional customParams : W3BuffCustomParams)
{
	if(target == thePlayer)	//modSigns: ALCH-14, never on Geralt (legacy)
		target.RemoveBuff(EET_SilverDust);	//modSigns

	super.OnEffectAdded(customParams);
	
	
	target.PauseEffects(EET_AutoEssenceRegen, 'silver_dust');
	
	BlockAbilities(true);
}

// 5.x body; changes marked //modSigns.
@replaceMethod(W3Effect_SilverDust)
function BlockAbilities(block : bool)
{
	var ret : bool;
	
	//modSigns: removed 1.32's list (Swarm, SwarmShield, SwarmTeleport): legacy's blocks below
	ret = target.BlockAbility('Doppelganger', block) || ret;	//modSigns
	ret = target.BlockAbility('MistCharge', block) || ret;	//modSigns
	ret = target.BlockAbility('ShadowForm', block) || ret;	//modSigns
	ret = target.BlockAbility('MistForm', block) || ret;	//modSigns
	ret = target.BlockAbility('Flashstep', block) || ret;	//modSigns
	ret = target.BlockAbility('Shapeshifter', block) || ret;	//modSigns
	ret = target.BlockAbility('Swarms', block) || ret;	//modSigns
	ret = target.BlockAbility('Teleport', block) || ret;	//modSigns
	ret = target.BlockAbility('FullMoon', block) || ret;	//modSigns
	ret = target.BlockAbility('EssenceRegen', block) || ret;
	
	if(block && ret)
	{
		target.PlayEffect('transformation_block');
	}
	else if(!block)
	{
		target.StopEffect('transformation_block');
	}
}

// 5.x body; changes marked //modSigns.
@replaceMethod(CBTTaskWraithDrainDance)
function Main() : EBTNodeStatus
{
	var l_npc 						: CNewNPC 			= GetNPC();
	var l_target 					: CActor 			= l_npc.GetTarget();
	var l_npcPos, l_targetPos 		: Vector;
	var l_dist						: float;
	var l_summonerHealth			: float;
	
	var summonedEntityComponent 	: W3SummonedEntityComponent;
	
	var l_sourceNode				: CNode;
	var l_targetNode				: CNode;
	
	summonedEntityComponent = (W3SummonedEntityComponent) l_npc.GetComponentByClassName('W3SummonedEntityComponent');
	l_targetNode			= GetNPC().GetComponent("DrainEnergyTarget");
	if( !l_targetNode )
	{
		l_targetNode = GetNPC();
	}
	l_sourceNode			= GetCombatTarget().GetComponent("torso3effect");
	if( !l_sourceNode )
	{
		l_sourceNode = GetCombatTarget();
	}
	
	while ( !m_Disappeared )
	{			
		l_npcPos 		= l_npc.GetWorldPosition();
		l_targetPos 	= l_target.GetWorldPosition();
		
		l_dist 			= VecDistance( l_npcPos, l_targetPos );
		
		if( !summonedEntityComponent.GetSummoner() || !summonedEntityComponent.GetSummoner().IsAlive() )
		{
			l_npc.SignalGameplayEvent('Disappear');
			return BTNS_Active;
		}
		
		if( l_dist < 4 )
		{
			if( !l_target.HasBuff( EET_VitalityDrain ) )
			{
				AddDrainBuff();
			}				
			
			if( summonedEntityComponent )
			{
				
				l_summonerHealth = summonedEntityComponent.GetSummoner().GetCurrentHealth();
				if( summonedEntityComponent.GetSummoner().HasBuff(EET_SilverDust) )	//modSigns: ALCH-14, Silver Dust cuts the drain's heal to a quarter (legacy)
					summonedEntityComponent.GetSummoner().Heal( l_summonerHealth * 0.0005f );	//modSigns
				else	//modSigns
					summonedEntityComponent.GetSummoner().Heal( l_summonerHealth * 0.002f );	//modSigns
			}
			
			if( !m_DrainEffectEntity )
			{
				m_DrainEffectEntity = theGame.CreateEntity( drainTemplate, GetNPC().GetWorldPosition(), GetNPC().GetWorldRotation() );
			}
			
			if( !m_DrainEffectEntity.IsEffectActive('drain_energy') )
			{
				m_DrainEffectEntity.PlayEffect( 'drain_energy', l_targetNode );
			}
		}
		else
		{
			m_DrainEffectEntity.StopEffect( 'drain_energy' );
		}
		
		if( m_DrainEffectEntity )
		{
			m_DrainEffectEntity.Teleport( l_sourceNode.GetWorldPosition() );
		}
		
		Sleep( 0.01f );
	}
	return BTNS_Active;
}

// 5.x body; changes marked //modSigns.
@replaceMethod(W3CriticalDOTEffect)
function OnEffectAdded(optional customParams : W3BuffCustomParams)
{
	var i : int;
	var animHandling : ECriticalHandling;
	var veh : CGameplayEntity;
	var horseComp : W3HorseComponent;
	var boatComp : CBoatComponent;
	var params : W3BuffDoTParams;
	var perk20Bonus : SAbilityAttributeValue;
	
	var skillPassiveMod : float; 
			
	
	if(IsImmuneToAllDamage(100000))		
	{
		isActive = false;
		return true;
	}
	
	params = (W3BuffDoTParams)customParams;
	
	
	if( params )
	{
		//modSigns: removed 5.x's potion duration bonus to bomb damage (ALCH-14, the owner's DL7)
		
		if( params.isPerk20Active )
		{
			
			
			
		}
	}
	
	
	
		
	
	super.OnEffectAdded(customParams);
	
	
	if(isOnPlayer)
	{
		for(i=0; i<blockedActions.Size(); i+=1)
		{
			thePlayer.BlockAction( blockedActions[i], EffectTypeToName( effectType ) );
		}
	}
	
	
	if(!isOnPlayer)
		target.PauseStaminaRegen('in_critical_state');
		
	
	if(target.IsCriticalTypeHigherThanAllCurrent(criticalStateType))		
	{			
		if(target.IsInAir())
		{
			animHandling = airHandling;
		}			
		else
		{
			
			if(isOnPlayer)
			{
				if( !thePlayer.CanReactToCriticalState() )
				{
					animHandling = explorationStateHandling;
				}
				
				else
				{
					veh = thePlayer.GetUsedVehicle();
					
					if((W3Boat)veh)
					{
						
						
						animHandling = attachedHandling;
					}
					
					else if(veh)
					{
						horseComp = ((CNewNPC)veh).GetHorseComponent();
						horseComp.OnCriticalEffectAdded( criticalStateType );
						animHandling = onHorseHandling;
					}	
					
					else
					{
						animHandling = ECH_HandleNow;
					}
				}
			}
			
			else
			{
				
				animHandling = ECH_HandleNow;
			}
		}
	}
	
	else
	{
		animHandling = postponeHandling;
	}
	
	
	if(animHandling == ECH_HandleNow)
	{
		target.StartCSAnim(this);
	}
	else if(animHandling == ECH_Abort)
	{
		LogCritical("Cancelling CS <<" + criticalStateType + ">> as it cannot play anim right now and its handling wishes to abort in such case");
		isActive = false;
	}
	
	
	if(isOnPlayer)
		theGame.HapticStart( "classic_vibro_large_oneshot" );
}

// Specters under Silver Dust cannot teleport (legacy).
@wrapMethod(TaskTeleportAction)
function IsAvailable() : bool
{
	if(GetNPC().HasAbility('Specter') && GetNPC().HasBuff(EET_SilverDust))
		return false;
	return wrappedMethod();
}

// Specters under Silver Dust cannot teleport (legacy).
@wrapMethod(CBTTaskTeleport)
function IsAvailable() : bool
{
	if(GetNPC().HasAbility('Specter') && GetNPC().HasBuff(EET_SilverDust))
		return false;
	return wrappedMethod();
}

// Specters under Silver Dust cannot teleport (legacy).
@wrapMethod(CBTTaskTeleportDecorator)
function IsAvailable() : bool
{
	if(GetNPC().HasAbility('Specter') && GetNPC().HasBuff(EET_SilverDust))
		return false;
	return wrappedMethod();
}

// Samum's blindness: its ability holds Geralt's crit chance against the blinded enemy, so it is not added to
// the enemy (legacy).
class W3BlindnessEffect extends W3CriticalEffect
{
	default dontAddAbilityOnTarget = true;	//modSigns
}

// The crit chance bonus against a blinded enemy (Samum's: 0.5/0.75/1; legacy's GetCritChanceBonus).
function GMBlindnessCritBonus(target : CActor) : float
{
	var buff : CBaseGameplayEffect;
	var min, max : SAbilityAttributeValue;

	if(!target)
		return 0;
	buff = target.GetBuff(EET_Blindness);
	if(!buff)
		return 0;
	theGame.GetDefinitionsManager().GetAbilityAttributeValue(buff.GetAbilityName(), 'critical_hit_chance', min, max);
	return CalculateAttributeValue(GetAttributeRandomizedValue(min, max));
}
