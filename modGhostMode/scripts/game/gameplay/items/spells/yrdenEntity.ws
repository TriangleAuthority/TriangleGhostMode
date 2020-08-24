/***********************************************************************/
/** 	© 2015 CD PROJEKT S.A. All rights reserved.
/** 	THE WITCHER® is a trademark of CD PROJEKT S. A.
/** 	The Witcher game is based on the prose of Andrzej Sapkowski.
/***********************************************************************/




struct SYrdenEffects
{
	editable var castEffect		: name;
	editable var placeEffect	: name;
	editable var shootEffect	: name;
	editable var activateEffect : name;
}

statemachine class W3YrdenEntity extends W3SignEntity
{
	editable var effects		: array< SYrdenEffects >;
	editable var projTemplate	: CEntityTemplate;
	editable var projDestroyFxEntTemplate : CEntityTemplate;
	editable var runeTemplates	: array< CEntityTemplate >;

	protected var validTargetsInArea, allActorsInArea : array< CActor >;
	protected var flyersInArea	: array< CNewNPC >;
	
	protected var trapDuration	: float;
	protected var charges		: int;
	protected var isPlayerInside : bool;
	protected var baseModeRange : float;
	protected var maxCount		: int; //modSigns
	protected var hasSupercharged	: bool; //modSigns
	protected var yrdenPower/*, healthDrain*/	: SAbilityAttributeValue; //modSigns
	protected var turretLevel	: int; //modSigns
	protected var turretDamageBonus	: float; //modSigns
	protected var superchargedDmg	: float; //modSigns
	protected var isEntanglement	: bool; //modSigns
	
	public var notFromPlayerCast : bool;
	public var fxEntities : array< CEntity >;
	
	default skillEnum = S_Magic_3;

	public function Init( inOwner : W3SignOwner, prevInstance : W3SignEntity, optional skipCastingAnimation : bool, optional notPlayerCast : bool ) : bool
	{
		notFromPlayerCast = notPlayerCast;
		
		return super.Init(inOwner, prevInstance, skipCastingAnimation, notPlayerCast);
	}
		
	public function GetSignType() : ESignType
	{
		return ST_Yrden;
	}
		
	public function GetIsPlayerInside() : bool
	{
		return isPlayerInside;
	}
	
	public function SkillUnequipped(skill : ESkill)
	{
		var i : int;
	
		super.SkillUnequipped(skill);
		
		if(skill == S_Magic_s11)
		{
			for(i=0; i<validTargetsInArea.Size(); i+=1)
				validTargetsInArea[i].RemoveBuff( EET_YrdenHealthDrain );
		}
	}
	
	public function IsValidTarget( target : CActor ) : bool
	{
		return target && target.GetHealth() > 0.f && target.GetAttitude( owner.GetActor() ) == AIA_Hostile;
	}
	
	public function SkillEquipped(skill : ESkill)
	{
		var i : int;
		var params : SCustomEffectParams;
	
		super.SkillEquipped(skill);
	
		if(skill == S_Magic_s11)
		{
			params.effectType = EET_YrdenHealthDrain;
			params.creator = owner.GetActor();
			params.sourceName = "yrden_mode0";
			params.isSignEffect = true;
			
			for(i=0; i<validTargetsInArea.Size(); i+=1)
				validTargetsInArea[i].AddEffectCustom(params);
		}
	}

	event OnProcessSignEvent( eventName : name )
	{
		if ( eventName == 'yrden_draw_ready' )
		{
			PlayEffect( 'yrden_cast' );
		}
		else
		{
			return super.OnProcessSignEvent(eventName);
		}
		
		return true;
	}
	
	public final function ClearActorsInArea()
	{
		var i : int;
		
		for(i=0; i<validTargetsInArea.Size(); i+=1)
			validTargetsInArea[i].SignalGameplayEventParamObject('LeavesYrden', this );
		
		validTargetsInArea.Clear();
		flyersInArea.Clear();
		allActorsInArea.Clear();
	}
	
	public final function GetCachedYrdenPower() : SAbilityAttributeValue //modSigns: for damage manager
	{
		return yrdenPower;
	}
	
	protected function GetSignStats()
	{
		var chargesAtt, trapDurationAtt : SAbilityAttributeValue;
		var min, max : SAbilityAttributeValue;
		var rangeMult : float;
	
		super.GetSignStats();

		//modSigns: cache skill dependent stats for Flood of Anger to work properly
		isEntanglement = (notFromPlayerCast && (W3PlayerWitcher)owner.GetActor() && ((W3PlayerWitcher)owner.GetActor()).HasGlyphwordActive('Glyphword 15 _Stats'));
		
		chargesAtt = owner.GetSkillAttributeValue(skillEnum, 'charge_count', false, true);
		
		//separate duration for Yrden Turret and Yrden Trap
		if(IsAlternateCast())
			trapDurationAtt = owner.GetSkillAttributeValue(skillEnum, 'trap_duration', false, false);
		else
			trapDurationAtt = owner.GetSkillAttributeValue(skillEnum, 'trap_duration', false, false);
		
		baseModeRange = CalculateAttributeValue( owner.GetSkillAttributeValue(skillEnum, 'range', false, false) );
		rangeMult = 1;
		if(!IsAlternateCast() && owner.CanUseSkill(S_Magic_s10) && owner.GetSkillLevel(S_Magic_s10) >= 2)
			rangeMult += CalculateAttributeValue(owner.GetSkillAttributeValue(S_Magic_s10, 'range_bonus', false, false));
		if(!IsAlternateCast() && owner.GetPlayer() && GetWitcherPlayer().IsSetBonusActive( EISB_Gryphon_2 ))
		{
			theGame.GetDefinitionsManager().GetAbilityAttributeValue( 'GryphonSetBonusYrdenEffect', 'trigger_scale', min, max );
			rangeMult += min.valueAdditive - 1;
		}
		baseModeRange *= rangeMult;
		
		maxCount = 1;
		if(!IsAlternateCast() && owner.CanUseSkill(S_Magic_s10) && owner.GetSkillLevel(S_Magic_s10) >= 3)
		{
			maxCount += 1;
		}
		yrdenPower = owner.GetActor().GetTotalSignSpellPower(skillEnum);
		hasSupercharged = owner.CanUseSkill(S_Magic_s11);
		if( hasSupercharged && owner.GetPlayer() )
		{
			//healthDrain = owner.GetPlayer().GetSkillAttributeValue(S_Magic_s11, 'direct_damage_per_sec', false, true);
			//healthDrain.valueMultiplicative *= (float)owner.GetPlayer().GetSkillLevel(S_Magic_s11);
			superchargedDmg = CalculateAttributeValue(owner.GetPlayer().GetSkillAttributeValue(S_Magic_s11, 's11_dmg_bonus', false, true));
			superchargedDmg *= (float)owner.GetPlayer().GetSkillLevel(S_Magic_s11);
		}
		if( owner.CanUseSkill(S_Magic_s03) )
		{
			turretLevel = owner.GetSkillLevel(S_Magic_s03);
			turretDamageBonus = CalculateAttributeValue( owner.GetPlayer().GetSkillAttributeValue( S_Magic_s03, 'damage_bonus_flat_after_1', false, false ) ) * ( turretLevel - 1 );
			trapDurationAtt.valueAdditive += CalculateAttributeValue( owner.GetPlayer().GetSkillAttributeValue( S_Magic_s03, 'duration_bonus_flat_after_1', false, false ) ) * ( turretLevel - 1 );
			chargesAtt.valueAdditive += CalculateAttributeValue( owner.GetPlayer().GetSkillAttributeValue( S_Magic_s03, 'charge_bonus_flat_after_1', false, false ) ) * ( turretLevel - 1 );
			if( owner.CanUseSkill(S_Magic_s16) )
				turretDamageBonus += CalculateAttributeValue( owner.GetPlayer().GetSkillAttributeValue( S_Magic_s16, 'turret_bonus_damage', false, true ) ) * owner.GetSkillLevel(S_Magic_s16);
		}
		else
		{
			turretLevel = 0;
			turretDamageBonus = 0;
		}
		
		charges = (int)CalculateAttributeValue(chargesAtt);
		
		//modSigns: duration is no longer affected by spell power
		//trapDurationAtt += owner.GetActor().GetTotalSignSpellPower(skillEnum);
		//trapDurationAtt.valueMultiplicative -= 1;	//100% base spell power
		
		trapDuration = CalculateAttributeValue(trapDurationAtt);
		
		if(!IsAlternateCast() && owner.CanUseSkill(S_Magic_s10))
			trapDuration *= 1 + CalculateAttributeValue(owner.GetSkillAttributeValue(S_Magic_s10, 'trap_duration_bonus', false, false)) * owner.GetSkillLevel(S_Magic_s10);
		
		//Entanglement
		if(isEntanglement)
		{
			theGame.GetDefinitionsManager().GetAbilityAttributeValue('Glyphword 15 _Stats', 'glyphword15_duration', min, max);
			trapDuration = min.valueAdditive;
			theGame.GetDefinitionsManager().GetAbilityAttributeValue('Glyphword 15 _Stats', 'glyphword15_range', min, max);
			baseModeRange = min.valueAdditive;
		}
		
		//level 3 petri philtre
		if(owner.GetPlayer() && owner.GetPlayer().GetPotionBuffLevel(EET_PetriPhiltre) == 3)
		{
			trapDuration *= 1.34;
			//theGame.witcherLog.AddMessage("Yrden; Duration: " + trapDuration); //modSigns: debug
		}
		
		//theGame.witcherLog.AddMessage("Yrden charges:" + charges);
		//theGame.witcherLog.AddMessage("Yrden trap duration:" + trapDuration);
		//theGame.witcherLog.AddMessage("Yrden Trap range:" + baseModeRange);
	}
	
	event OnStarted()
	{
		var player : CR4Player;
		
		Attach(true, true);
		
		player = (CR4Player)owner.GetActor();
		if(player)
		{
			GetWitcherPlayer().FailFundamentalsFirstAchievementCondition();
			player.AddTimer('ResetPadBacklightColorTimer', 2);
		}
		
		PlayEffect( 'cast_yrden' );
		
		if ( owner.ChangeAspect( this, S_Magic_s03 ) )
		{
			CacheActionBuffsFromSkill();
			GotoState( 'YrdenChanneled' );
		}
		else
		{
			GotoState( 'YrdenCast' );
		}
	}
	
	
	protected latent function Place(trapPos : Vector)
	{
		var trapPosTest, trapPosResult, collisionNormal, scale : Vector;
		var rot : EulerAngles;
		var witcher : W3PlayerWitcher;
		var trigger : CComponent;
		var min, max : SAbilityAttributeValue;
		
		witcher = GetWitcherPlayer();
		witcher.yrdenEntities.PushBack(this);
		
		DisablePreviousYrdens();
		
		if( GetWitcherPlayer().IsSetBonusActive( EISB_Gryphon_2 ) )
		{
			theGame.GetDefinitionsManager().GetAbilityAttributeValue( 'GryphonSetBonusYrdenEffect', 'trigger_scale', min, max );
			
			trigger = GetComponent( "Slowdown" );
			scale = trigger.GetLocalScale() * min.valueAdditive;			
			
			trigger.SetScale( scale );
		}
		
		
		Detach();
		
		
		SleepOneFrame();
		
		
		trapPosTest = trapPos;
		trapPosTest.Z -= 0.5;		
		rot = GetWorldRotation();
		rot.Pitch = 0;
		rot.Roll = 0;
		
		if(theGame.GetWorld().StaticTrace(trapPos, trapPosTest, trapPosResult, collisionNormal))
		{
			trapPosResult.Z += 0.1;	
			TeleportWithRotation ( trapPosResult, rot );
		}
		else
		{
			TeleportWithRotation ( trapPos, rot );
		}
		
		
		SleepOneFrame();
		
		AddTimer('TimedCanceled', trapDuration, , , , true);
		
		if(!notFromPlayerCast)
			owner.GetActor().OnSignCastPerformed(ST_Yrden, fireMode);
	}
	
	private final function DisablePreviousYrdens()
	{
		var /*maxCount,*/ i, size, currCount : int; //modSigns: cached
		var isAlternate : bool;
		var witcher : W3PlayerWitcher;
		
		
		isAlternate = IsAlternateCast();
		witcher = GetWitcherPlayer();
		size = witcher.yrdenEntities.Size();
		
		
		//maxCount = 1; //modSigns: cached
		currCount = 0;
		
		/*if(!isAlternate && owner.CanUseSkill(S_Magic_s10) && owner.GetSkillLevel(S_Magic_s10) >= 2)
		{
			maxCount += 1;
		}*/ //modSigns: cached
		
		for(i=size-1; i>=0; i-=1)
		{
			
			if(!witcher.yrdenEntities[i])
			{
				witcher.yrdenEntities.Erase(i);		
				continue;
			}
			
			if(witcher.yrdenEntities[i].IsAlternateCast() == isAlternate)
			{
				currCount += 1;
				
				
				if(currCount > maxCount)
				{
					witcher.yrdenEntities[i].OnSignAborted(true);
				}
			}
		}
	}
	
	timer function TimedCanceled( delta : float , id : int)
	{
		var i : int;
		var areas : array<CComponent>;
		
		isPlayerInside = false;
		
		super.CleanUp();
		StopAllEffects();
		
		
		areas = GetComponentsByClassName('CTriggerAreaComponent');
		for(i=0; i<areas.Size(); i+=1)
			areas[i].SetEnabled(false);
		
		for(i=0; i<validTargetsInArea.Size(); i+=1)
		{
			validTargetsInArea[i].BlockAbility('Flying', false);
		}
		
		for( i=0; i<fxEntities.Size(); i+=1 )
		{
			fxEntities[i].StopAllEffects();
			fxEntities[i].DestroyAfter( 5.f );
		}
		
		UpdateGryphonSetBonusYrdenBuff();
		ClearActorsInArea();
		DestroyAfter(3);
	}
	
	
	protected function NotifyGameplayEntitiesInArea( componentName : CName )
	{
		var entities : array<CGameplayEntity>;
		var triggerAreaComp : CTriggerAreaComponent;
		var i : int;
		var ownerActor : CActor;
		
		ownerActor = owner.GetActor();
		triggerAreaComp = (CTriggerAreaComponent)this.GetComponent( componentName );
		triggerAreaComp.GetGameplayEntitiesInArea( entities, 6.0 );
		
		for ( i=0 ; i < entities.Size() ; i+=1 )
		{
			if( !((CActor)entities[i]) )
				entities[i].OnYrdenHit( ownerActor );
		}
	}
	
	event OnVisualDebug( frame : CScriptedRenderFrame, flag : EShowFlags, selected : bool )
	{
	}
	
	protected function UpdateGryphonSetBonusYrdenBuff()
	{
		var player : W3PlayerWitcher;
		var i : int;
		var isPlayerInYrden, hasBuff : bool;
		
		player = GetWitcherPlayer();
		hasBuff = player.HasBuff( EET_GryphonSetBonusYrden );
		
		if ( player.IsSetBonusActive( EISB_Gryphon_2 ) ) 
		{
			isPlayerInYrden = false;
			
			for( i=0 ; i < player.yrdenEntities.Size() ; i+=1 )
			{
				if( !player.yrdenEntities[i].IsAlternateCast() && player.yrdenEntities[i].isPlayerInside )
				{
					isPlayerInYrden = true;
					break;
				}
			}
			
			if( isPlayerInYrden && !hasBuff )
			{
				player.AddEffectDefault( EET_GryphonSetBonusYrden, NULL, "GryphonSetBonusYrden" );
			}
			else if( !isPlayerInYrden && hasBuff )
			{
				player.RemoveBuff( EET_GryphonSetBonusYrden, false, "GryphonSetBonusYrden" );
			}
		}
		else if( hasBuff )
		{
			player.RemoveBuff( EET_GryphonSetBonusYrden, false, "GryphonSetBonusYrden" );
		}
	}
}

state YrdenCast in W3YrdenEntity extends NormalCast
{
	event OnThrowing()
	{
		if( super.OnThrowing() )
		{
			//modSigns: stamina management
			if(!parent.notFromPlayerCast)
			{
				if( caster.GetPlayer() )
				{
					parent.ManagePlayerStamina();
					parent.ManageGryphonSetBonusBuff();
					thePlayer.AddEffectDefault(EET_YrdenCooldown, NULL, "normal_cast"); //modSigns
					//modSigns: new mutagen10 effect
					if(thePlayer.HasBuff(EET_Mutagen10))
						((W3Mutagen10_Effect)thePlayer.GetBuff(EET_Mutagen10)).AddMutagen10Ability();
					//modSigns: new mutagen17 effect
					if(thePlayer.HasBuff(EET_Mutagen17))
						((W3Mutagen17_Effect)thePlayer.GetBuff(EET_Mutagen17)).RemoveMutagen17Abilities();
					//modSigns: new mutagen22 effect
					if(thePlayer.HasBuff(EET_Mutagen22))
						((W3Mutagen22_Effect)thePlayer.GetBuff(EET_Mutagen22)).AddMutagen22Ability();
				}
				else
				{
					caster.GetActor().DrainStamina( ESAT_Ability, 0, 0, SkillEnumToName( parent.skillEnum ) );
				}
			}
			//cleanup after stamina management
			parent.CleanUp();	
			parent.StopEffect( 'yrden_cast' );			
			parent.GotoState( 'YrdenSlowdown' );
		}
	}
}

state YrdenChanneled in W3YrdenEntity extends Channeling
{
	event OnEnterState( prevStateName : name )
	{
		var actor : CActor;
		var player : CR4Player;
		var stamina : float;
		
		super.OnEnterState( prevStateName );
		
		caster.OnDelayOrientationChange();
		//caster.GetActor().PauseStaminaRegen( 'SignCast' );
		
		actor = caster.GetActor();
		player = (CR4Player)actor;
			
		if(player)
		{
			if( parent.cachedCost <= 0.0f )
			{
				parent.cachedCost = player.GetStaminaActionCost( ESAT_Ability, SkillEnumToName( parent.skillEnum ), 0 );
			}
			stamina = player.GetStat(BCS_Stamina);
		}
			
		if( player && player.CanUseSkill(S_Perk_09) && player.GetStat(BCS_Focus) >= 1 )
		{
			if( parent.cachedCost > 0 )
			{
				player.DrainFocus( 1 * parent.foaMult ); //flood of anger cost mult
			}
			parent.SetUsedFocus( true );
		}
		else
		{
			actor.DrainStamina( ESAT_Ability, 0, 0, SkillEnumToName( parent.skillEnum ) );
			actor.StartStaminaRegen();
			actor.PauseStaminaRegen( 'SignCast' );
			parent.SetUsedFocus( false );
			if(parent.GetUsedFoA()) //flood of anger cost
				player.DrainFocus( 1 * parent.foaMult );
		}
		
		ChannelYrden();
	}
	
	event OnThrowing()
	{
		//if( super.OnThrowing() )
		//{
			parent.CleanUp();	
		//}
		
		parent.StopEffect( 'yrden_cast' );
		
		caster.GetActor().ResumeStaminaRegen( 'SignCast' );
		
		parent.GotoState( 'YrdenShock' );
	}
	
	event OnEnded(optional isEnd : bool)
	{
	}
	
	event OnSignAborted( optional force : bool )
	{
		if ( caster.IsPlayer() )
		{
			caster.GetPlayer().LockToTarget( false );
		}
		
		parent.AddTimer('TimedCanceled', 0, , , , true);
		
		super.OnSignAborted( force );
	}		
	
	entry function ChannelYrden()
	{
		while( Update(theTimer.timeDelta) ) //modSigns
		{
			Sleep(theTimer.timeDelta); //modSigns
		}
		
		OnSignAborted();
	}
}


state YrdenShock in W3YrdenEntity extends Active
{
	private var usedShockAreaName : name;
	
	event OnEnterState( prevStateName : name )
	{
		var skillLevel : int;
		
		super.OnEnterState( prevStateName );
		
		if(caster.IsPlayer()) //modSigns
		{
			thePlayer.AddEffectDefault(EET_YrdenCooldown, NULL, "alt_cast");
			//modSigns: new mutagen10 effect
			if(thePlayer.HasBuff(EET_Mutagen10))
				((W3Mutagen10_Effect)thePlayer.GetBuff(EET_Mutagen10)).AddMutagen10Ability();
			//modSigns: new mutagen17 effect
			if(thePlayer.HasBuff(EET_Mutagen17))
				((W3Mutagen17_Effect)thePlayer.GetBuff(EET_Mutagen17)).RemoveMutagen17Abilities();
			//modSigns: new mutagen22 effect
			if(thePlayer.HasBuff(EET_Mutagen22))
				((W3Mutagen22_Effect)thePlayer.GetBuff(EET_Mutagen22)).AddMutagen22Ability();
		}
		
		//skillLevel = caster.GetSkillLevel(parent.skillEnum);
		skillLevel = parent.turretLevel; //modSigns
		
		if(skillLevel == 1)
			usedShockAreaName = 'Shock_lvl_1';
		else if(skillLevel == 2)
			usedShockAreaName = 'Shock_lvl_2';
		else if(skillLevel == 3)
			usedShockAreaName = 'Shock_lvl_3';
			
		parent.GetComponent(usedShockAreaName).SetEnabled( true );
		
		ActivateShock();
		//parent.NotifyGameplayEntitiesInArea( usedShockAreaName ); //modSigns
	}
	
	event OnLeaveState( nextStateName : name )
	{
		parent.GetComponent(usedShockAreaName).SetEnabled( false );
		parent.ClearActorsInArea();
	}
	
	entry function ActivateShock()
	{
		var i, size : int;
		var target : CActor;
		var hitEntity : CEntity;
		var shot, validTargetsUpdated : bool;
			
		parent.Place(parent.GetWorldPosition());
		
		parent.PlayEffect( parent.effects[parent.fireMode].placeEffect );
		parent.PlayEffect( parent.effects[parent.fireMode].castEffect );
		
		
		Sleep(1.f);
		
		while( parent.charges > 0 )
		{
			hitEntity = NULL;
			shot = false;
			size = parent.validTargetsInArea.Size();
			if ( size > 0 )
			{
				do
				{
					target = parent.validTargetsInArea[RandRange(size)];
					if(target.GetHealth() <= 0.f || target.IsInAgony() )
					{
						parent.validTargetsInArea.Remove(target);
						size -= 1;
						target = NULL;
					}
				}while(size > 0 && !target)
				
				if(target && target.GetGameplayVisibility())
				{
					shot = true;
					hitEntity = ShootTarget(target, true, 0.2f, false);
				}
			}
			
			if(hitEntity)
			{
				Sleep(2.f);		
			}
			else if(shot)
			{
				Sleep(0.1f);	
			}
			else
			{
				validTargetsUpdated = false;
				
				
				if( parent.validTargetsInArea.Size() == 0 )
				{				
					for( i=0; i<parent.allActorsInArea.Size(); i+=1 )
					{
						if( parent.IsValidTarget( parent.allActorsInArea[i] ) )
						{
							parent.validTargetsInArea.PushBack( parent.allActorsInArea[i] );
							validTargetsUpdated = true;
						}
					}
				}
				
				
				if( !validTargetsUpdated )
				{
					Sleep(1.f);		
				}
			}
		}
		
		parent.GotoState( 'Discharged' );
	}
	
	event OnAreaEnter( area : CTriggerAreaComponent, activator : CComponent )
	{
		var target : CNewNPC;		
		var projectile : CProjectileTrajectory;		
		
		target = (CNewNPC)(activator.GetEntity());
		
		if( target && !parent.allActorsInArea.Contains( target ) )
		{
			parent.allActorsInArea.PushBack( target );
		}
		
		if ( parent.charges && parent.IsValidTarget( target ) && !parent.validTargetsInArea.Contains(target) )
		{
			if( parent.validTargetsInArea.Size() == 0 )
			{
				parent.PlayEffect( parent.effects[parent.fireMode].activateEffect );
			}
			
			parent.validTargetsInArea.PushBack( target );			
			
			//target.OnYrdenHit( caster.GetActor() ); //modSigns
			
			//target.SignalGameplayEventParamObject('EntersYrden', parent ); //modSigns
		}		
		else if(parent.projDestroyFxEntTemplate)
		{
			projectile = (CProjectileTrajectory)activator.GetEntity();
			
			if(projectile && !((W3SignProjectile)projectile) && IsRequiredAttitudeBetween(caster.GetActor(), projectile.caster, true, true, false))
			{
				if(projectile.IsStopped())
				{
					
					projectile.SetIsInYrdenAlternateRange(parent);
				}
				else
				{			
					ShootDownProjectile(projectile);
				}
			}
		}
	}
	
	public final function ShootDownProjectile(projectile : CProjectileTrajectory)
	{
		var hitEntity, fxEntity : CEntity;
		
		hitEntity = ShootTarget(projectile, false, 0.1f, true);
					
		
		if(hitEntity == projectile || !hitEntity)
		{
			
			fxEntity = theGame.CreateEntity( parent.projDestroyFxEntTemplate, projectile.GetWorldPosition() );
			
			
			
			if(!hitEntity)
			{
				parent.PlayEffect( parent.effects[1].shootEffect );		
				parent.PlayEffect( parent.effects[1].shootEffect, fxEntity );
			}
			
			projectile.StopProjectile();
			projectile.Destroy();			
		}
	}
	
	event OnAreaExit( area : CTriggerAreaComponent, activator : CComponent )
	{
		var target : CNewNPC;
		var projectile : CProjectileTrajectory;
		
		target = (CNewNPC)(activator.GetEntity());
		
		if ( target && parent.charges && target.GetAttitude( thePlayer ) == AIA_Hostile )
		{
			parent.validTargetsInArea.Erase( parent.validTargetsInArea.FindFirst( target ) );
			//target.SignalGameplayEventParamObject('LeavesYrden', parent ); //modSigns
		}
		
		if ( parent.validTargetsInArea.Size() <= 0 )
		{
			parent.StopEffect( parent.effects[parent.fireMode].activateEffect );
		}
		
		//modSigns: remove target from allActorsInArea list too
		if( target && parent.allActorsInArea.Contains( target ) )
		{
			parent.allActorsInArea.Erase( parent.allActorsInArea.FindFirst( target ) );
		}
	}
	
	var traceFrom, traceTo : Vector;
	private function ShootTarget( targetNode : CNode, useTargetsPositionCorrection : bool, extraRayCastLengthPerc : float, useProjectileGroups : bool ) : CEntity
	{
		var results : array<SRaycastHitResult>;
		var i, ind : int;
		var min : float;
		var collisionGroupsNames : array<name>;
		var entity : CEntity;
		var targetActor : CActor;
		var targetPos : Vector;
		var physTest : bool;
		
		traceFrom = virtual_parent.GetWorldPosition();
		traceFrom.Z += 1.f;
		
		targetPos = targetNode.GetWorldPosition();
		traceTo = targetPos;
		if(useTargetsPositionCorrection)
			traceTo.Z += 1.f;
		
		traceTo = traceFrom + (traceTo - traceFrom) * (1.f + extraRayCastLengthPerc);
		
		collisionGroupsNames.PushBack( 'RigidBody' );
		collisionGroupsNames.PushBack( 'Static' );
		collisionGroupsNames.PushBack( 'Debris' );	
		collisionGroupsNames.PushBack( 'Destructible' );	
		collisionGroupsNames.PushBack( 'Terrain' );
		collisionGroupsNames.PushBack( 'Phantom' );
		collisionGroupsNames.PushBack( 'Water' );
		collisionGroupsNames.PushBack( 'Boat' );		
		collisionGroupsNames.PushBack( 'Door' );
		collisionGroupsNames.PushBack( 'Platforms' );
		
		if(useProjectileGroups)
		{
			collisionGroupsNames.PushBack( 'Projectile' );
		}
		else
		{			
			collisionGroupsNames.PushBack( 'Character' );			
		}
		
		physTest = theGame.GetWorld().GetTraceManager().RayCastSync(traceFrom, traceTo, results, collisionGroupsNames);

		if ( !physTest || results.Size() == 0 )
			FindActorsAtLine( traceFrom, traceTo, 0.05f, results, collisionGroupsNames );
		
		if ( results.Size() > 0 )
		{
			
			while(results.Size() > 0)
			{
				
				min = results[0].distance;
				ind = 0;
				
				for(i=1; i<results.Size(); i+=1)
				{
					if(results[i].distance < min)
					{
						min = results[i].distance;
						ind = i;
					}
				}
				
				
				if(results[ind].component)
				{
					entity = results[ind].component.GetEntity();
					targetActor = (CActor)entity;
					
					
					if(targetActor && IsRequiredAttitudeBetween(targetActor, caster.GetActor(), false, false, true))
						return NULL;
					
					
					if( (targetActor && targetActor.GetHealth() > 0.f && targetActor.IsAlive()) || (!targetActor && entity) )
					{
						
						YrdenTrapHitEnemy(targetActor, results[ind].position);						
						return entity;
					}
					else if(targetActor)
					{
						
						results.EraseFast(ind);
					}
				}
				else
				{
					break;
				}
			}
		}
		
		return NULL;
	}
	
	private final function YrdenTrapHitEnemy(entity : CEntity, hitPosition : Vector)
	{
		var component : CComponent;
		var targetActor, casterActor : CActor;
		var action : W3DamageAction;
		var player : W3PlayerWitcher;
		var skillType : ESkill;
		var skillLevel, i : int;
		var damageBonusFlat : float;		
		var damages : array<SRawDamage>;
		var glyphwordY : W3YrdenEntity;
		
		
		parent.StopEffect( parent.effects[parent.fireMode].castEffect );
		parent.PlayEffect( parent.effects[parent.fireMode].shootEffect );
		parent.PlayEffect( parent.effects[parent.fireMode].castEffect );
			
		targetActor = (CActor)entity;
		if(targetActor)
		{
			component = targetActor.GetComponent('torso3effect');		
			if ( component )
			{
				parent.PlayEffect( parent.effects[parent.fireMode].shootEffect, component );
			}
		}
		
		if(!targetActor || !component)
		{
			parent.PlayEffect( parent.effects[parent.fireMode].shootEffect, entity );
		}

		
		
			parent.charges -= 1;
		
		
		casterActor = caster.GetActor();
		if ( casterActor && (CGameplayEntity)entity)
		{
			
			action =  new W3DamageAction in theGame.damageMgr;
			player = caster.GetPlayer();
			skillType = virtual_parent.GetSkill();
			//skillLevel = player.GetSkillLevel(skillType);
			//skillLevel = parent.turretLevel; //modSigns
			
			
			action.Initialize( casterActor, (CGameplayEntity)entity, this, casterActor.GetName()+"_sign_yrden_alt" /*modSigns*/, EHRT_Light, CPS_SpellPower, false, false, true, false, 'yrden_shock', 'yrden_shock', 'yrden_shock', 'yrden_shock');
			virtual_parent.InitSignDataForDamageAction(action);
			action.hitLocation = hitPosition;
			action.SetCanPlayHitParticle(true);
			
			
			if(parent.turretDamageBonus > 0) //modSigns
			{
				action.GetDTs(damages);
				//damageBonusFlat = CalculateAttributeValue(player.GetSkillAttributeValue(skillType, 'damage_bonus_flat_after_1', false, true));
				action.ClearDamage();
				
				for(i=0; i<damages.Size(); i+=1)
				{
					damages[i].dmgVal += parent.turretDamageBonus; //damageBonusFlat * (skillLevel - 1);
					action.AddDamage(damages[i].dmgType, damages[i].dmgVal);
				}
			}
			
			
			theGame.damageMgr.ProcessAction( action );
			
			((CGameplayEntity)entity).OnYrdenHit( casterActor ); //modSigns
		}
		else
		{
			entity.PlayEffect( 'yrden_shock' );
		}
		
		if((W3PlayerWitcher)casterActor && ((W3PlayerWitcher)casterActor).HasGlyphwordActive('Glyphword 15 _Stats')) //modSigns
		{
			glyphwordY = (W3YrdenEntity)theGame.CreateEntity(GetWitcherPlayer().GetSignTemplate(ST_Yrden), entity.GetWorldPosition(), entity.GetWorldRotation() );
			glyphwordY.Init(caster, parent, true, true);
			glyphwordY.CacheActionBuffsFromSkill();
			glyphwordY.GotoState( 'YrdenSlowdown' );
		}
	}
	
	event OnThrowing()
	{
		parent.CleanUp();	
	}
	
	event OnVisualDebug( frame : CScriptedRenderFrame, flag : EShowFlags, selected : bool )
	{
		frame.DrawLine(traceFrom, traceTo, Color(255, 255, 0));
	}
}

state YrdenSlowdown in W3YrdenEntity extends Active
{
	event OnEnterState( prevStateName : name )
	{
		//var player				: CR4Player;
		
		super.OnEnterState( prevStateName );
		
		parent.GetComponent( 'Slowdown' ).SetEnabled( true );
		parent.PlayEffect( 'yrden_slowdown_sound' );
		
		ActivateSlowdown();
		
		/*if(!parent.notFromPlayerCast)
		{
			player = caster.GetPlayer();
			
			if( player )
			{
				parent.ManagePlayerStamina();
				parent.ManageGryphonSetBonusBuff();
			}
			else
			{
				caster.GetActor().DrainStamina( ESAT_Ability, 0, 0, SkillEnumToName( parent.skillEnum ) );
			}
		}*/ //modSigns: moved to another place
	}
	
	event OnLeaveState( nextStateName : name )
	{
		CleanUp();
		parent.GetComponent('Slowdown').SetEnabled( false );
		parent.ClearActorsInArea();
	}
	
	private function CleanUp()
	{
		var i, size : int;
		
		size = parent.validTargetsInArea.Size();
		for( i = 0; i < size; i += 1 )
		{
			parent.validTargetsInArea[i].RemoveBuff( EET_YrdenHealthDrain );
		}
		
		for( i=0; i<virtual_parent.fxEntities.Size(); i+=1 )
		{
			virtual_parent.fxEntities[i].StopAllEffects();
			virtual_parent.fxEntities[i].DestroyAfter( 5.f );
		}
	}
	
	event OnThrowing()
	{
		parent.CleanUp();	
	}
	
	event OnSignAborted( force : bool )
	{
		if( force )
			CleanUp();
		
		parent.AddTimer('TimedCanceled', 0, , , , true);
		
		super.OnSignAborted( force );
	}
	
	entry function ActivateSlowdown()
	{
		var obj : CEntity;
		var pos : Vector;
		
		obj = (CEntity)parent;
		pos = obj.GetWorldPosition();
		parent.Place(pos);
		
		CreateTrap();
		
		theGame.GetBehTreeReactionManager().CreateReactionEvent( parent, 'YrdenCreated', parent.trapDuration, 30, 0.1f, 999, true );
		parent.NotifyGameplayEntitiesInArea( 'Slowdown' );
		YrdenSlowdown_Loop();
	}
	
	private function CreateTrap()
	{
		var i, size : int;
		var worldPos : Vector;
		var isSetBonus2Active : bool;
		var worldRot : EulerAngles;
		var polarAngle, yrdenRange, unitAngle : float;
		var runePositionLocal, runePositionGlobal : Vector;
		var entity : CEntity;
		//var min, max : SAbilityAttributeValue;
		
		isSetBonus2Active = GetWitcherPlayer().IsSetBonusActive( EISB_Gryphon_2 );
		worldPos = virtual_parent.GetWorldPosition();
		worldRot = virtual_parent.GetWorldRotation();
		yrdenRange = virtual_parent.baseModeRange;
		size = virtual_parent.runeTemplates.Size();
		unitAngle = 2 * Pi() / size;
		
		if( isSetBonus2Active )
		{
			virtual_parent.PlayEffect( 'ability_gryphon_set' );
			//theGame.GetDefinitionsManager().GetAbilityAttributeValue( 'GryphonSetBonusYrdenEffect', 'trigger_scale', min, max );
			//yrdenRange *= min.valueAdditive; //modSigns -> moved
		}
		
		for( i=0; i<size; i+=1 )
		{
			polarAngle = unitAngle * i;
			
			runePositionLocal.X = yrdenRange * CosF( polarAngle );
			runePositionLocal.Y = yrdenRange * SinF( polarAngle );
			runePositionLocal.Z = 0.f;
			
			runePositionGlobal = worldPos + runePositionLocal;			
			runePositionGlobal = TraceFloor( runePositionGlobal );
			runePositionGlobal.Z += 0.05f;		
			
			entity = theGame.CreateEntity( virtual_parent.runeTemplates[i], runePositionGlobal, worldRot );
			virtual_parent.fxEntities.PushBack( entity );
		}
	}
	
	//modSigns: modified
	entry function YrdenSlowdown_Loop()
	{
		var i							: int;
		var casterActor, curTarget		: CActor;
		var casterPlayer				: CR4Player;
		var npc							: CNewNPC;
		var params, paramsDrain			: SCustomEffectParams;
		var min, max, pts, prc			: float;
		var startingMin					: float;
		var slowPower/*, drainNoRes*/	: float;
		var decayDelay, timePassed		: float;
		var inc, mult, slow/*, drain*/	: float;
		var dt							: float = 0.1f;
		var ablMin, ablMax				: SAbilityAttributeValue;
		var superchargedBonus, bonus	: float;
		var currentlyAnimatedCS			: CBaseGameplayEffect;
		
		casterActor = caster.GetActor();
		casterPlayer = caster.GetPlayer();
		
		//set up the slowdown effect
		params.effectType = EET_Slowdown; //parent.actionBuffs[0].effectType;
		params.creator = casterActor;
		params.sourceName = "yrden_mode0";
		params.isSignEffect = true;
		params.customAbilityName = ''; //parent.actionBuffs[0].effectAbilityName;
		params.duration = 0.2;	//continuous inside area
		
		//cache xml params
		min = CalculateAttributeValue(casterPlayer.GetSkillAttributeValue(S_Magic_3, 'min_slowdown', false, false));
		max = CalculateAttributeValue(casterPlayer.GetSkillAttributeValue(S_Magic_3, 'max_slowdown', false, false));
		startingMin = CalculateAttributeValue(casterPlayer.GetSkillAttributeValue(S_Magic_3, 'min_starting_slowdown', false, false));
		slowPower = parent.yrdenPower.valueMultiplicative;
		
		//Entanglement
		if(parent.isEntanglement)
		{
			theGame.GetDefinitionsManager().GetAbilityAttributeValue('Glyphword 15 _Stats', 'glyphword15_slow_cap', ablMin, ablMax);
			max = CalculateAttributeValue(ablMin);
		}
		
		//set up the health drain effect -> redone to grant a bonus to damage instead
		if(parent.hasSupercharged)
		{
			paramsDrain.effectType = EET_YrdenHealthDrain;
			paramsDrain.creator = casterActor;
			paramsDrain.sourceName = "yrden_mode0";
			paramsDrain.isSignEffect = true;
			paramsDrain.customAbilityName = '';
			paramsDrain.duration = 0.2;	//continuous inside area
			//paramsDrain.effectValue = parent.healthDrain;
			//drainNoRes = parent.healthDrain.valueMultiplicative;
			superchargedBonus = parent.superchargedDmg;
		}
		
		//set up starting values
		timePassed = 0;
		mult = 0;
		//time until effects start to decay
		decayDelay = parent.trapDuration / 3.0;
		//mult increment
		inc = dt / (parent.trapDuration - decayDelay);
		
		while(true)
		{
			//check if flyers landed / crashed
			for(i=parent.flyersInArea.Size()-1; i>=0; i-=1)
			{
				npc = parent.flyersInArea[i];
				if(!npc.IsFlying())
				{
					parent.validTargetsInArea.PushBack(npc);
					npc.BlockAbility('Flying', true);
					parent.flyersInArea.EraseFast(i);
				}
			}
			
			for(i=0; i<parent.validTargetsInArea.Size(); i+=1)
			{
				curTarget = parent.validTargetsInArea[i];
				
				//slowdown and drain if Shock Resistance < 100%
				curTarget.GetResistValue(CDS_ShockRes, pts, prc);
				if(prc < 1)
				{
					//effect values
					if(parent.isEntanglement)
						slow = max * (1 - prc);
					else
						slow = MaxF(0, startingMin * (1 + SignPowerStatToPowerBonus(slowPower - pts/100))) * (1 - prc);
					slow = ClampF(slow, min, max);
					//drain = MaxF(0, drainNoRes * (1 - prc));
					bonus = MaxF(0, superchargedBonus * (1 - prc));
					//effect decay
					if(timePassed >= decayDelay)
					{
						slow = min + (slow - min) * (1 - MinF(mult, 1));
						//drain *= 1 - MinF(mult, 1);
						bonus *= 1 - MinF(mult, 1);
					}
					//slowdown
					params.effectValue.valueAdditive = slow;
					currentlyAnimatedCS = curTarget.GetCurrentlyAnimatedCS();
					if(currentlyAnimatedCS && !((W3Effect_PoisonCritical)currentlyAnimatedCS) || curTarget.GetIsRecoveringFromKnockdown()) //has critical effect currently animated
					{
						if(curTarget.HasBuff(EET_Slowdown))
							curTarget.RemoveBuff(EET_Slowdown);
					}
					else if(!curTarget.HasBuff(EET_Slowdown))
						curTarget.AddEffectCustom(params);
					else
						((W3Effect_Slowdown)curTarget.GetBuff(EET_Slowdown)).ResetSlowdownEffect(params.effectValue);
					//hp drain -> dmg bonus
					if(parent.hasSupercharged)
					{
						//paramsDrain.effectValue.valueMultiplicative = drain;
						if(!curTarget.HasBuff(EET_YrdenHealthDrain))
							curTarget.AddEffectCustom(paramsDrain);
						//else
						//	((W3Effect_YrdenHealthDrain)curTarget.GetBuff(EET_YrdenHealthDrain)).ResetHealthDrainEffect(paramsDrain.effectValue);
						((W3Effect_YrdenHealthDrain)curTarget.GetBuff(EET_YrdenHealthDrain)).SetDmgBonus(bonus);
					}
				}
				
				//hit
				curTarget.OnYrdenHit( casterActor );
			}
			
			timePassed += dt;
			if(timePassed >= decayDelay)
				mult += inc;
			Sleep(dt);
			//SleepOneFrame();
		}
	}
	
	event OnAreaEnter( area : CTriggerAreaComponent, activator : CComponent )
	{
		var target : CNewNPC;
		var casterActor : CActor;
		
		target = (CNewNPC)(activator.GetEntity());
		casterActor = caster.GetActor();
		if( (W3PlayerWitcher)activator.GetEntity() )
		{
			parent.isPlayerInside = true;
		}
		
		if( target && !parent.allActorsInArea.Contains( target ) )
		{
			parent.allActorsInArea.PushBack( target );
		}
		
		if ( parent.IsValidTarget( target ) && !parent.validTargetsInArea.Contains(target))
		{
			if (!target.IsFlying())
			{
				
				if( parent.validTargetsInArea.Size() == 0 )
				{
					parent.PlayEffect( parent.effects[parent.fireMode].activateEffect );
				}
				
				parent.validTargetsInArea.PushBack( target );		
				target.SignalGameplayEventParamObject('EntersYrden', parent );
				target.BlockAbility('Flying', true);
			}
			else
			{
				parent.flyersInArea.PushBack(target);
			}
		}
		if( parent.isPlayerInside && GetWitcherPlayer().IsSetBonusActive( EISB_Gryphon_2 ) )
		{
			parent.UpdateGryphonSetBonusYrdenBuff();
		}
	}
	
	event OnAreaExit( area : CTriggerAreaComponent, activator : CComponent )
	{
		var target : CNewNPC;
		var i : int;
		
		target = (CNewNPC)(activator.GetEntity());
	
		if( (W3PlayerWitcher)activator.GetEntity() )
		{
			parent.isPlayerInside = false;
		}
		if( target )
		{
			i = parent.validTargetsInArea.FindFirst( target );
			if( i >= 0 )
			{
				target.RemoveBuff( EET_YrdenHealthDrain );
				
				parent.validTargetsInArea.Erase( i );
			}
			target.SignalGameplayEventParamObject('LeavesYrden', parent );
			target.BlockAbility('Flying', false);
			parent.flyersInArea.Remove(target);
		}
		
		if ( parent.validTargetsInArea.Size() == 0 )
		{
			parent.StopEffect( parent.effects[parent.fireMode].activateEffect );
		}
		if( !parent.isPlayerInside )
		{
			parent.UpdateGryphonSetBonusYrdenBuff();
		}
		
		//modSigns: remove target from allActorsInArea list too
		if( target && parent.allActorsInArea.Contains( target ) )
		{
			parent.allActorsInArea.Erase( parent.allActorsInArea.FindFirst( target ) );
		}
	}
}

state Discharged in W3YrdenEntity extends Active
{
	event OnEnterState( prevStateName : name )
	{
		YrdenExpire();
	}
	
	entry function YrdenExpire()
	{
		Sleep( 1.f );
		OnSignAborted( true );
	}
}