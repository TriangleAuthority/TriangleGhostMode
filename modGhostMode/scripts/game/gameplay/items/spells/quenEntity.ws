/***********************************************************************/
/** 	© 2015 CD PROJEKT S.A. All rights reserved.
/** 	THE WITCHER® is a trademark of CD PROJEKT S. A.
/** 	The Witcher game is based on the prose of Andrzej Sapkowski.
/***********************************************************************/
struct SQuenEffects
{
	editable var lastingEffectUpgNone	: name;
	editable var lastingEffectUpg1		: name;
	editable var lastingEffectUpg2		: name;
	editable var lastingEffectUpg3		: name;
	editable var castEffect				: name;
	editable var cameraShakeStranth		: float;
}



statemachine class W3QuenEntity extends W3SignEntity
{
	editable var effects : array< SQuenEffects >;
	editable var hitEntityTemplate : CEntityTemplate;
		
	
	protected var shieldDuration	: float;
	protected var shieldHealth		: float;
	protected var initialShieldHealth : float;
	protected var dischargePercent	: float;
	protected var ownerBoneIndex	: int;
	protected var blockedAllDamage  : bool;
	protected var shieldStartTime	: EngineTime;
	protected var dmgAbsorptionPrc	: float; //modSigns
	protected var impulseLevel		: int; //modSigns
	protected var quenPower			: SAbilityAttributeValue; //modSigns
	protected var healingFactor		: float; //modSigns
	private var hitEntityTimestamps : array<EngineTime>;
	private const var MIN_HIT_ENTITY_SPAWN_DELAY : float;
	private var hitDoTEntities : array<W3VisualFx>;
	public var showForceFinishedFX : bool;
	public var freeCast	: bool; //modSigns
	public var glyphword17Cast : bool; //modSigns
	
	default skillEnum = S_Magic_4;
	default MIN_HIT_ENTITY_SPAWN_DELAY = 0.25f;
	
	public function GetSignType() : ESignType
	{
		return ST_Quen;
	}
	
	public function SetBlockedAllDamage(b : bool)
	{
		blockedAllDamage = b;
	}
	
	public function GetBlockedAllDamage() : bool
	{
		return blockedAllDamage;
	}
	
	function Init( inOwner : W3SignOwner, prevInstance : W3SignEntity, optional skipCastingAnimation : bool, optional notPlayerCast : bool ) : bool
	{
		var oldQuen : W3QuenEntity;
		
		ownerBoneIndex = inOwner.GetActor().GetBoneIndex( 'pelvis' );
		if(ownerBoneIndex == -1)
			ownerBoneIndex = inOwner.GetActor().GetBoneIndex( 'k_pelvis_g' );
			
		oldQuen = (W3QuenEntity)prevInstance;
		if(oldQuen)
			oldQuen.OnSignAborted(true);
		
		hitEntityTimestamps.Clear();
		
		return super.Init( inOwner, prevInstance, skipCastingAnimation, notPlayerCast ); //modSigns
	}
	
	//modSigns: hit fx
	public function ShowHitFX(optional damageData : W3DamageAction)
	{
	}
	
	event OnTargetHit( out damageData : W3DamageAction )
	{
		//if(owner.GetActor() == thePlayer && !damageData.IsDoTDamage() && !damageData.WasDodged())
		//	theGame.VibrateControllerHard();	 //modSigns: moved to ShowHitFX
	}
		
	protected function GetSignStats()
	{
		var skillBonus : float;
		//var spellPower : SAbilityAttributeValue;
		var min, max : SAbilityAttributeValue;
		
		super.GetSignStats();
		
		quenPower = owner.GetActor().GetTotalSignSpellPower(S_Magic_4);
		
		if(owner.GetActor() == GetWitcherPlayer() && owner.GetActor().HasBuff(EET_Mutagen19))
			quenPower += ((W3Mutagen19_Effect)owner.GetActor().GetBuff(EET_Mutagen19)).GetQuenPowerBonus();
		
		//modSigns: Protection glyphword bonus to sign power
		if(glyphword17Cast)
		{
			theGame.GetDefinitionsManager().GetAbilityAttributeValue('Glyphword 17 _Stats', 'glyphword17_quen_buff', min, max);
			quenPower.valueMultiplicative += CalculateAttributeValue(min);
			glyphword17Cast = false;
			//theGame.witcherLog.AddMessage("Protection bonus: " + CalculateAttributeValue(min));
		}
		
		//modSigns: cache impulse and discharge skills
		if( owner.CanUseSkill(S_Magic_s13) )
			impulseLevel = owner.GetSkillLevel(S_Magic_s13);
		else
			impulseLevel = 0;
		
		dmgAbsorptionPrc = CalculateAttributeValue(owner.GetSkillAttributeValue(S_Magic_4, 'max_dmg_absorption', false, false));
		
		//modSigns: use base quen ability to get shield stats, because they're defined there
		shieldDuration = CalculateAttributeValue(owner.GetSkillAttributeValue(S_Magic_4, 'shield_duration', true, true));
		//level 3 petri philtre gives +30% to shield duration
		if(owner.GetPlayer() && owner.GetPlayer().GetPotionBuffLevel(EET_PetriPhiltre) == 3)
		{
			shieldDuration *= 1.34;
			//theGame.witcherLog.AddMessage("Quen shield; Duration: " + shieldDuration); //modSigns: debug
		}
		shieldHealth = CalculateAttributeValue(owner.GetSkillAttributeValue(S_Magic_4, 'shield_health', false, true));
		
		if( owner.CanUseSkill(S_Magic_s14) )
		{			
			dischargePercent = CalculateAttributeValue(owner.GetSkillAttributeValue(S_Magic_s14, 'discharge_percent', false, true)) * owner.GetSkillLevel(S_Magic_s14);
			if( owner.GetPlayer().HasGlyphwordActive( 'Glyphword 5 _Stats' ) ) //modSigns
			{
				theGame.GetDefinitionsManager().GetAbilityAttributeValue( 'Glyphword 5 _Stats', 'glyphword5_dmg_boost', min, max );
				dischargePercent *= 1 + min.valueMultiplicative;
			}
		}
		else
		{
			dischargePercent = 0;
		}
		
		if( owner.CanUseSkill(S_Magic_s15) )
			skillBonus = CalculateAttributeValue(owner.GetSkillAttributeValue(S_Magic_s15, 'shield_health_bonus', false, true)) * owner.GetSkillLevel(S_Magic_s15);
		else
			skillBonus = 0;
		
		shieldHealth += skillBonus;
		shieldHealth *= 1 + SignPowerStatToPowerBonus(quenPower.valueMultiplicative); //modSigns: soft cap

		initialShieldHealth = shieldHealth;
		
		if( owner.CanUseSkill(S_Magic_s04) )
			healingFactor = CalculateAttributeValue(owner.GetSkillAttributeValue(S_Magic_s04, 'shield_healing_factor', false, true)) * owner.GetSkillLevel(S_Magic_s04);
		else
			healingFactor = 0;
	}
	
	public final function AddBuffImmunities()
	{
		//modSigns: removed
		//var actor : CActor;
		//var i : int;
		//var crits : array<CBaseGameplayEffect>;
		//var effectType : EEffectType;
		//
		//actor = owner.GetActor();
		//
		//
		//crits = actor.GetBuffs();	
		//for(i=0; i<crits.Size(); i+=1)
		//{
		//	effectType = crits[i].GetEffectType();
		//	
		//	
		//	//if( effectType == EET_SnowstormQ403 || effectType == EET_Snowstorm )
		//	//{
		//	//	actor.FinishQuen( false );
		//	//	return;
		//	//} //handled in effects themselves
		//	
		//	
		//	//modSigns: casting quen doesn't remove active DoT effects, but having quen on denies adding DoT (see effectManager)
		//	//if( !IsDoTEffect( crits[i] ) )
		//	//{
		//	//	continue;
		//	//}
		//	//
		//	//
		//	//if( actor == GetWitcherPlayer() && ( effectType == EET_Poison || effectType == EET_PoisonCritical ) && actor.HasBuff( EET_GoldenOriole ) && GetWitcherPlayer().GetPotionBuffLevel( EET_GoldenOriole ) >= 3 )
		//	//{
		//	//	continue;
		//	//}
		//	//
		//	//actor.RemoveEffect( crits[i], true );			
		//}		
	}
	
	public final function RemoveBuffImmunities()
	{
		var actor : CActor;
		var i, size : int;
		var dots : array<EEffectType>;
		
		actor = owner.GetActor();
		
		dots.PushBack(EET_Bleeding);
		dots.PushBack(EET_Burning);
		dots.PushBack(EET_Poison);
		dots.PushBack(EET_PoisonCritical);
		dots.PushBack(EET_Swarm);
		
		
		size = (int)EET_EffectTypesSize;
		for(i=0; i<size; i+=1)
		{
			if(IsCriticalEffectType(i) && !dots.Contains(i))
				actor.RemoveBuffImmunity(i, 'Quen');
		}
	}
	
	event OnStarted() 
	{
		var isAlternate		: bool;
		var witcherOwner	: W3PlayerWitcher;
		
		owner.ChangeAspect( this, S_Magic_s04 );
		isAlternate = IsAlternateCast();
		witcherOwner = owner.GetPlayer();
		
		if(isAlternate)
		{
			
			CreateAttachment( owner.GetActor(), 'quen_sphere' );
			
			if((CPlayer)owner.GetActor())
				GetWitcherPlayer().FailFundamentalsFirstAchievementCondition();
		}
		else
		{
			super.OnStarted();
		}
		
		
		if(owner.GetActor() == thePlayer && ShouldProcessTutorial('TutorialSelectQuen'))
		{
			FactsAdd("tutorial_quen_cast");
		}
		
		if((CPlayer)owner.GetActor())
			GetWitcherPlayer().FailFundamentalsFirstAchievementCondition();
				
		if( isAlternate || !owner.IsPlayer() )
		{
			if( owner.IsPlayer() && GetWitcherPlayer().HasBuff( EET_Mutation11Immortal ) )
			{
				PlayEffect( 'quen_second_life' );
			}
			else
			{
				PlayEffect( effects[1].castEffect );
			}
			
			//if( witcherOwner && dischargePercent > 0 && witcherOwner.IsSetBonusActive( EISB_Bear_2 ) )
			//{
			//	PlayEffect( 'default_fx_bear_abl2' );
			//	witcherOwner.PlayEffect( 'quen_lasting_shield_bear_abl2' );
			//} //modSigns: bonus changed
			
			//modSigns: utilize now unused bear set visual effect for discharge skill
			if( witcherOwner && dischargePercent > 0 )
				PlayEffect( 'default_fx_bear_abl2' );
			
			CacheActionBuffsFromSkill();
			GotoState( 'QuenChanneled' );
		}
		else
		{
			PlayEffect( effects[0].castEffect );
			GotoState( 'QuenShield' );
		}
	}
	
	public final function IsAnyQuenActive() : bool
	{
		
		if(GetCurrentStateName() == 'QuenChanneled' || (GetCurrentStateName() == 'ShieldActive' && shieldHealth > 0) )
		{
			return true;
		}
				
		return false;
	}
	
	event OnSignAborted( optional force : bool ){}
	
	
	
	
	public final function PlayHitEffect(fxName : name, rot : EulerAngles, optional isDoT : bool)
	{
		var hitEntity : W3VisualFx;
		var currentTime : EngineTime;
		var dt : float;
		
		currentTime = theGame.GetEngineTime();
		if(hitEntityTimestamps.Size() > 0)
		{
			dt = EngineTimeToFloat(currentTime - hitEntityTimestamps[0]);
			if(dt < MIN_HIT_ENTITY_SPAWN_DELAY)
				return;
		}
		hitEntityTimestamps.Erase(0);
		hitEntityTimestamps.PushBack(currentTime);
		
		hitEntity = (W3VisualFx)theGame.CreateEntity(hitEntityTemplate, GetWorldPosition(), rot);
		if(hitEntity)
		{
			
			hitEntity.CreateAttachment(owner.GetActor(), 'quen_sphere', , rot);
			hitEntity.PlayEffect(fxName);
			hitEntity.DestroyOnFxEnd(fxName);
			
			if(isDoT)
				hitDoTEntities.PushBack(hitEntity);
		}
	}
	
	public function EraseFirstTimeStamp()
	{
		hitEntityTimestamps.Erase(0);
	}
	
	timer function RemoveDoTFX(dt : float, id : int)
	{
		RemoveHitDoTEntities();
	}
	
	public final function RemoveHitDoTEntities()
	{
		var i : int;
		
		for(i=hitDoTEntities.Size()-1; i>=0; i-=1)
		{
			if(hitDoTEntities[i])
				hitDoTEntities[i].Destroy();
		}
	}
	
	public final function GetShieldHealth() : float 		{return shieldHealth;}
	public final function GetInitialShieldHealth() : float 		{return initialShieldHealth;}
	
	public final function GetShieldRemainingDuration() : float
	{
		return shieldDuration - EngineTimeToFloat( theGame.GetEngineTime() - shieldStartTime );
	}
	
	public final function SetDataFromRestore(health : float, duration : float)
	{
		shieldHealth = health;
		shieldDuration = duration;
		if( shieldHealth > initialShieldHealth ) //modSigns
			initialShieldHealth = shieldHealth;
		shieldStartTime = theGame.GetEngineTime();
		AddTimer('Expire', shieldDuration, false, , , true, true);
	}
	
	timer function Expire( deltaTime : float , id : int)
	{		
		GotoState( 'Expired' );
	}
		
	public final function ForceFinishQuen( skipVisuals : bool, optional forceNoBearSetBonus : bool )
	{
		var min, max : SAbilityAttributeValue;
		var player : W3PlayerWitcher;
		
		player = owner.GetPlayer();
		
		//modSigns: full set redesign, Quen bonus removed
		//if( !forceNoBearSetBonus && player && player.IsSetBonusActive( EISB_Bear_1 ) )
		//{
		//	theGame.GetDefinitionsManager().GetAbilityAttributeValue( GetSetBonusAbility( EISB_Bear_1), 'quen_reapply_chance', min, max );
		//	
		//	min.valueMultiplicative *= player.GetSetPartsEquipped( EIST_Bear );
		//	
		//	
		//	min.valueMultiplicative /= PowF(2, player.m_quenReappliedCount - 1); //modSigns
		//	/*if( player.m_quenReappliedCount > 4 )
		//	{
		//		min.valueMultiplicative = 0;
		//	}*/ //modSigns	
		//	
		//	//modSigns debug
		//	if( FactsQuerySum( "modSigns_debug_bear" ) > 0 )
		//		theGame.witcherLog.AddMessage("Bear set Quen reapply prob = " + min.valueMultiplicative);
		//	
		//	if( min.valueMultiplicative >= RandF() )
		//	{
		//		player.PlayEffect( 'quen_lasting_shield_back' );
		//		player.AddTimer( 'BearSetBonusQuenReapply', 0.9, true );
		//		//modSigns debug
		//		if( FactsQuerySum( "modSigns_debug_bear" ) > 0 )
		//			theGame.witcherLog.AddMessage("Reapplied successfully!");
		//	}
		//	
		//	else
		//	{
		//		player.m_quenReappliedCount = 1;
		//	}
		//}
		////modSigns
		//else
		//{
		//	player.m_quenReappliedCount = 1;
		//}
			
		if(IsAlternateCast())
		{
			OnEnded();
			
			if(!skipVisuals)
				owner.GetActor().PlayEffect('hit_electric_quen');
		}
		else
		{
			showForceFinishedFX = !skipVisuals;
			GotoState('Expired');
		}
	}
}


state Expired in W3QuenEntity
{
	event OnEnterState( prevStateName : name )
	{
		parent.shieldHealth = 0;
		
		if(parent.showForceFinishedFX)
			parent.owner.GetActor().PlayEffect('quen_lasting_shield_hit');
			
		parent.DestroyAfter( 1.f );		
		
		if(parent.owner.GetActor() == thePlayer)
			theGame.VibrateControllerVeryHard();	
	}
}


state ShieldActive in W3QuenEntity extends Active
{
	//modSigns: function was rewritten to make fx depend on sign power
	private final function GetLastingFxName() : name
	{
		//var spellPower : SAbilityAttributeValue;
		var sp/*, level*/ : float;
		
		//spellPower = caster.GetActor().GetTotalSignSpellPower(virtual_parent.GetSkill());
		sp = parent.quenPower.valueMultiplicative - 1;
		if(sp >= 1.5)
			return parent.effects[0].lastingEffectUpg3;
		if(sp >= 1.0)
			return parent.effects[0].lastingEffectUpg2;
		else if(sp >= 0.5)
			return parent.effects[0].lastingEffectUpg1;
		else
			return parent.effects[0].lastingEffectUpgNone;
	}
	
	event OnEnterState( prevStateName : name )
	{
		var witcher			: W3PlayerWitcher;
		var params 			: SCustomEffectParams;
		
		super.OnEnterState( prevStateName );
		
		witcher = (W3PlayerWitcher)caster.GetActor();
		
		if(witcher)
		{
			witcher.SetUsedQuenInCombat();
			//witcher.m_quenReappliedCount = 1; //modSigns
			
			params.effectType = EET_BasicQuen;
			params.creator = witcher;
			params.sourceName = "sign cast";
			params.duration = parent.shieldDuration;
			
			witcher.AddEffectCustom( params );
		}
		
		caster.GetActor().PlayEffect(GetLastingFxName());
		
		//if( witcher && witcher.IsSetBonusActive( EISB_Bear_2 ) && parent.dischargePercent > 0 )
		//{
		//	witcher.PlayEffect( 'quen_force_discharge_bear_abl2_armour' );
		//} //modSigns: bonus changed
		
		parent.AddTimer( 'Expire', parent.shieldDuration, false, , , true );
		
		parent.AddBuffImmunities();
		
		/*if( witcher )
		{
			if( !parent.freeCast ) //modSigns
			{
				parent.ManagePlayerStamina();
				parent.ManageGryphonSetBonusBuff();
			}
		}
		else
		{
			caster.GetActor().DrainStamina( ESAT_Ability, 0, 0, SkillEnumToName( parent.skillEnum ) );
		}
		
		parent.freeCast = false; //modSigns: reset free casting
		*/ //modSigns -> moved to another place
		
		
		if( /*!witcher.IsSetBonusActive( EISB_Bear_1 ) ||*/ ( !witcher.HasBuff( EET_HeavyKnockdown ) && !witcher.HasBuff( EET_Knockdown ) ) )
		{
			witcher.CriticalEffectAnimationInterrupted("basic quen cast");
		}
		
		
		witcher.AddTimer('HACK_QuenSaveStatus', 0, true);
		parent.shieldStartTime = theGame.GetEngineTime();
	}
	
	event OnLeaveState( nextStateName : name )
	{
		var witcher : W3PlayerWitcher;
		
		
		witcher = (W3PlayerWitcher)caster.GetActor();
		//theGame.witcherLog.AddMessage("Quen shield; OnLeaveState"); //modSigns: debug
		if(witcher && parent == witcher.GetSignEntity(ST_Quen))
		{
			witcher.StopEffect(parent.effects[0].lastingEffectUpg1);
			witcher.StopEffect(parent.effects[0].lastingEffectUpg2);
			witcher.StopEffect(parent.effects[0].lastingEffectUpg3);
			witcher.StopEffect(parent.effects[0].lastingEffectUpgNone);
			//witcher.StopEffect( 'quen_force_discharge_bear_abl2_armour' );
			witcher.RemoveBuff( EET_BasicQuen );
		}
	
		parent.RemoveBuffImmunities();
		
		parent.RemoveHitDoTEntities();
		
		if(parent.owner.GetActor() == thePlayer)
		{
			GetWitcherPlayer().OnBasicQuenFinishing();			
		}
	}
	
	event OnEnded(optional isEnd : bool)
	{
		parent.StopEffect( parent.effects[parent.fireMode].castEffect );
	}
		
	
	//modSigns: hit fx
	public function ShowHitFX(optional damageData : W3DamageAction)
	{
		parent.owner.GetActor().PlayEffect('quen_lasting_shield_hit');
		GCameraShake( parent.effects[parent.fireMode].cameraShakeStranth, true, parent.GetWorldPosition(), 30.0f );
		theGame.VibrateControllerHard();
	}
	
	//modSigns: modified to handle raw damages
	event OnTargetHit( out damageData : W3DamageAction )
	{
		var inAttackAction : W3Action_Attack;
		var casterActor : CActor;
		var damageTypes : array<SRawDamage>;
		var reducedDamage, totalDamage : float;
		var i, size : int;
		var dmgVal : float;
		var dmgType : name;
		var returnedDmgAction : W3DamageAction;
		
		//falling damage is not reduced
		if(damageData.GetBuffSourceName() == "FallingDamage")
			return true;
		
		//DoT damage from effects (bleeding, poison, burning) is not reduced
		if(damageData.IsDoTDamage() && (CBaseGameplayEffect)damageData.causer)
			return true;
		
		//skip if dodged
		if(damageData.WasDodged())
			return true;
		
		//skip if parried or countered
		inAttackAction = (W3Action_Attack)damageData;
		if(inAttackAction && inAttackAction.CanBeParried() && (inAttackAction.IsParried() || inAttackAction.IsCountered()))
			return true;
		
		//debug log
		//theGame.witcherLog.AddMessage("Quen OnTargetHit");
		
		size = damageData.GetDTs(damageTypes);
		casterActor = caster.GetActor();
		reducedDamage = 0;
		totalDamage = 0;
				
		//debug log
		//theGame.witcherLog.AddMessage("num damages: " + size);
		
		//process damages
		for(i = 0; i < size; i += 1)
		{
			dmgType = damageTypes[i].dmgType;
			
			//debug log
			//theGame.witcherLog.AddMessage("dmgType: " + dmgType);
			
			if(casterActor.UsesVitality() && !DamageHitsVitality(dmgType))
				continue;
			
			if(casterActor.UsesEssence() && !DamageHitsEssence(dmgType))
				continue;
			
			dmgVal = damageTypes[i].dmgVal;
			
			totalDamage += dmgVal;
			
			//debug log
			//theGame.witcherLog.AddMessage("dmgVal: " + dmgVal);
			
			if(dmgType == theGame.params.DAMAGE_NAME_DIRECT)
				continue;
			
			if(parent.shieldHealth <= 0)
				continue;
			
			dmgVal *= parent.dmgAbsorptionPrc; //partial absorption
			
			if(dmgVal > parent.shieldHealth)
			{
				dmgVal = parent.shieldHealth;
				//damageTypes[i].dmgVal -= dmgVal;
			}
			//else
			//	damageTypes[i].dmgVal = 0;
			
			damageTypes[i].dmgVal -= dmgVal;
			
			reducedDamage += dmgVal;
			parent.shieldHealth -= dmgVal;
			
			//debug log
			//theGame.witcherLog.AddMessage("reduced dmgVal: " + dmgVal);
			
			if(theGame.CanLog())
			{
				LogDMHits("Quen ShieldActive.OnTargetHit: reducing damage from " + damageTypes[i].dmgVal + " to " + (damageTypes[i].dmgVal - dmgVal), damageData);
			}
		}
		
		for(i = size - 1; i >= 0; i -= 1)
		{
			//theGame.witcherLog.AddMessage( "Damage #" + i + ": type = " + damageTypes[i].dmgType );
			//theGame.witcherLog.AddMessage( "Damage #" + i + ": value = " + damageTypes[i].dmgVal );
			if(damageTypes[i].dmgVal <= 0)
				damageTypes.EraseFast(i);
		}
		
		//update action damages
		if(damageTypes.Size() > 0)
			damageData.SetDTs(damageTypes);
		else
			damageData.ClearDamage();
		
		//debug log
		//theGame.witcherLog.AddMessage("total dmg: " + totalDamage);
		//theGame.witcherLog.AddMessage("total reduced dmg: " + reducedDamage);
		//theGame.witcherLog.AddMessage("remaining shield health: " + parent.shieldHealth);
			
		//quen hit fx
		if(reducedDamage > 0)
		{
			ShowHitFX();
			
			//Quen discharge, returns a percentage of reduced damage
			if(!damageData.IsDoTDamage() && casterActor == thePlayer && damageData.attacker != casterActor && parent.dischargePercent > 0 && !damageData.IsActionRanged() && VecDistanceSquared( casterActor.GetWorldPosition(), damageData.attacker.GetWorldPosition() ) <= 13 ) //~3.5^2
			{
				returnedDmgAction = new W3DamageAction in theGame.damageMgr;
				returnedDmgAction.Initialize(casterActor, damageData.attacker, parent, 'quen', EHRT_Light, CPS_SpellPower, false, false, true, false, 'hit_shock');
				parent.InitSignDataForDamageAction(returnedDmgAction);
				returnedDmgAction.AddDamage(theGame.params.DAMAGE_NAME_SHOCK, parent.dischargePercent * reducedDamage);
				//debug log
				//theGame.witcherLog.AddMessage("Quen discharge dmg: " + (parent.dischargePercent * reducedDamage));
				
				returnedDmgAction.SetCanPlayHitParticle(true);
				returnedDmgAction.SetHitEffectAllTypes('hit_electric_quen');
				
				theGame.damageMgr.ProcessAction(returnedDmgAction);
				delete returnedDmgAction;
				
				casterActor.PlayEffect('quen_force_discharge');
			}
		}
		
		if(totalDamage <= reducedDamage)
		{
			parent.SetBlockedAllDamage(true);
			damageData.SetHitAnimationPlayType(EAHA_ForceNo);
			damageData.SetCanPlayHitParticle(false);
			
			//debug log
			//theGame.witcherLog.AddMessage("quen blocked all dmg: true");
		}
		else
		{
			parent.SetBlockedAllDamage(false);
		}
		
		//don't know what that is, but keeping it just in case
		if(totalDamage - reducedDamage >= 20)
			casterActor.RaiseForceEvent('StrongHitTest');
		
		//break shield if its HP is zero
		if(parent.shieldHealth <= 0)
		{
			if(parent.impulseLevel > 0)
			{				
				casterActor.PlayEffect('lasting_shield_impulse');
				caster.GetPlayer().QuenImpulse(false, parent, "quen_impulse", parent.impulseLevel, parent.quenPower);
			}
			damageData.SetEndsQuen(true);
		}
	}
}


state QuenShield in W3QuenEntity extends NormalCast
{
	event OnEnterState( prevStateName : name )
	{
		super.OnEnterState( prevStateName );
		
		caster.OnDelayOrientationChange();
		
		caster.GetActor().OnSignCastPerformed(ST_Quen, false);
	}
	
	event OnThrowing()
	{
		if( super.OnThrowing() )
		{
			//modSigns: stamina management
			if( (W3PlayerWitcher)caster.GetActor() )
			{
				if( !parent.freeCast )
				{
					parent.ManagePlayerStamina();
					parent.ManageGryphonSetBonusBuff();
					thePlayer.AddEffectDefault(EET_QuenCooldown, NULL, "normal_cast"); //modSigns
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
			}
			else
			{
				caster.GetActor().DrainStamina( ESAT_Ability, 0, 0, SkillEnumToName( parent.skillEnum ) );
			}
			parent.freeCast = false;
			//cleanup after stamina management
			parent.CleanUp();	
			parent.GotoState( 'ShieldActive' );
		}
	}
	
	event OnSignAborted( optional force : bool )
	{
		parent.StopEffect( parent.effects[parent.fireMode].castEffect );
		parent.GotoState( 'Expired' );
	}
}

state QuenChanneled in W3QuenEntity extends Channeling
{
	private const var HEALING_FACTOR : float;		
	
		default HEALING_FACTOR = 1.0f;

	event OnEnterState( prevStateName : name )
	{
		var casterActor : CActor;
		var witcher : W3PlayerWitcher;
		
		super.OnEnterState( prevStateName );
	
		casterActor = caster.GetActor();
		witcher = (W3PlayerWitcher)casterActor;
		
		if(witcher)
			witcher.SetUsedQuenInCombat();
							
		caster.OnDelayOrientationChange();
		
		//parent.GetSignStats(); //modSigns: already happens on change aspect
		
		
		casterActor.GetMovingAgentComponent().SetVirtualRadius( 'QuenBubble' );
			
		parent.AddBuffImmunities();	
		
		
		witcher.CriticalEffectAnimationInterrupted("quen channeled");
		
		//casterActor.OnSignCastPerformed(ST_Quen, true);
	}
	
	event OnThrowing()
	{
		if( super.OnThrowing() )
		{
			ChannelQuen();
		}
	}
	
	//private var HAXXOR_LeavingState : bool; //hack removed
	event OnLeaveState( nextStateName : name )
	{
		var casterActor : CActor;
		
		casterActor = caster.GetActor();
		casterActor.GetMovingAgentComponent().ResetVirtualRadius();
		casterActor.StopEffect('quen_shield');		
		//casterActor.StopEffect( 'quen_lasting_shield_bear_abl2' ); //ability changed
		parent.RemoveBuffImmunities();		
		parent.StopAllEffects();
		parent.RemoveHitDoTEntities();
		//only trigger if the shield wasn't destroyed by an attack to avoid triggering it twice
		if(parent.usedFocus && casterActor.GetStat(BCS_Focus) > 0 || !parent.usedFocus && casterActor.GetStat(BCS_Stamina) > 0)
		{
			if(parent.impulseLevel > 0)
			{
				parent.PlayHitEffect('quen_rebound_sphere_impulse', parent.GetWorldRotation());
				caster.GetPlayer().QuenImpulse(true, parent, "quen_impulse", parent.impulseLevel, parent.quenPower);
			}
		}
		
		//modSigns: cooldown
		if(caster.IsPlayer() && !caster.GetPlayer().HasBuff(EET_Mutation11Buff) && !caster.GetPlayer().HasBuff(EET_Mutation11Debuff))
		{
			thePlayer.AddEffectDefault(EET_QuenCooldown, NULL, "alt_cast");
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
		caster.GetActor().OnSignCastPerformed(ST_Quen, true); //modSigns: moved to the end of cast
		
		//a hack to prevent recursive call
		//whoever wrote this deserves to be eaten by harpies
		//HAXXOR_LeavingState = true;
		//OnEnded(true);
		super.OnLeaveState(nextStateName);
	}
	
	//OnEnded inevitably triggers OnLeaveState, so everything here can be done there
	//no need for hacks to prevent recursive OnEnded calls
	//event OnEnded(optional isEnd : bool)
	//{
	//	var casterActor : CActor;
	//	
	//	//a hack to prevent recursive call
	//	//whoever wrote this deserves to be eaten by harpies
	//	if(!HAXXOR_LeavingState)
	//		super.OnEnded();
	//		
	//	casterActor = caster.GetActor();
	//	casterActor.GetMovingAgentComponent().ResetVirtualRadius();
	//	casterActor.StopEffect('quen_shield');		
	//	//casterActor.StopEffect( 'quen_lasting_shield_bear_abl2' );
	//	
	//	parent.RemoveBuffImmunities();		
	//	
	//	parent.StopAllEffects();
	//	
	//	parent.RemoveHitDoTEntities();
	//	
	//	//isEnd is only ever used here and is always true when HAXXOR_LeavingState is true
	//	//QuenImpulse ends up triggered twice if the shield is destroyed by an attack
	//	//if(isEnd && caster.CanUseSkill(S_Magic_s13))
	//	//	caster.GetPlayer().QuenImpulse(true, parent, "quen_impulse", parent.impulseLevel, parent.quenPower); //modSigns
	//	//only activate quen impulse if it wasn't activated by damage destroying the shield
	//}
	
	event OnSignAborted( optional force : bool )
	{
		OnEnded();
	}
	
	entry function ChannelQuen()
	{
		while( Update(theTimer.timeDelta) ) //modSigns
		{
			ProcessQuenCollisionForRiders();
			//SleepOneFrame();
			//modSigns
			Sleep(theTimer.timeDelta);
		}
	}
	
	private function ProcessQuenCollisionForRiders()
	{
		var mac	: CMovingPhysicalAgentComponent;
		var collisionData : SCollisionData;
		var collisionNum : int;
		var i : int;
		var npc	: CNewNPC;
		var riderActor : CActor;
		var collidedWithRider : bool;
		var horseComp : W3HorseComponent;
		var riderToPlayerHeading, riderHeading : float;
		var angleDist : float;
		
		mac	= (CMovingPhysicalAgentComponent)thePlayer.GetMovingAgentComponent();
		if( !mac )
		{
			return;
		}
		
		collisionNum = mac.GetCollisionCharacterDataCount();
		for( i = 0; i < collisionNum; i += 1 )
		{
			collisionData = mac.GetCollisionCharacterData( i );
			npc	= (CNewNPC)collisionData.entity;
			if( npc )
			{
				if( npc.IsUsingHorse() )
				{
					collidedWithRider = true;
					horseComp = npc.GetUsedHorseComponent();
				}
				else
				{
					horseComp = npc.GetHorseComponent();
					if( horseComp.user )
						collidedWithRider = true;
				}
			}
			
			if( collidedWithRider )
			{
				riderActor = horseComp.user;
				
				if( IsRequiredAttitudeBetween( riderActor, thePlayer, true ) )
				{
					riderToPlayerHeading = VecHeading( thePlayer.GetWorldPosition() - riderActor.GetWorldPosition() );
					riderHeading = riderActor.GetHeading();
					angleDist = AngleDistance( riderToPlayerHeading, riderHeading );
					
					if( AbsF( angleDist ) < 45.0 )
					{
						horseComp.ReactToQuen();
					}
				}
			}
		}
	}
	
	//modSigns: modified
	public function ShowHitFX(optional damageData : W3DamageAction)
	{
		var movingAgent : CMovingPhysicalAgentComponent;
		var inWater, hasFireDamage, hasElectricDamage, hasPoisonDamage, isBirds : bool;
		var witcher	: W3PlayerWitcher;
		var rot : EulerAngles;
		
		GCameraShake(parent.effects[parent.fireMode].cameraShakeStranth, true, parent.GetWorldPosition(), 30.0f);
		theGame.VibrateControllerHard();
		
		if(!damageData || (CBaseGameplayEffect)damageData.causer)
		{
			parent.PlayHitEffect('quen_rebound_sphere', parent.GetWorldRotation());
			return;
		}
		
		if(damageData.attacker)
		{
			//get rotation towards where the hit came from
			rot = VecToRotation(damageData.attacker.GetWorldPosition() - caster.GetActor().GetWorldPosition());
			rot.Pitch = 0;
			rot.Roll = 0;
		}
		else
			rot = parent.GetWorldRotation();
		
		//isBirds = (CFlyingCrittersLairEntityScript)damageData.causer;
		witcher = parent.owner.GetPlayer();
		
		if(damageData.IsDoTDamage())
		{
			parent.PlayHitEffect('quen_rebound_sphere_constant', rot, true);
			parent.AddTimer('RemoveDoTFX', 0.3, false, , , , true);
		}
		else
		{
			hasFireDamage = damageData.GetDamageValue(theGame.params.DAMAGE_NAME_FIRE) > 0;
			hasPoisonDamage = damageData.GetDamageValue(theGame.params.DAMAGE_NAME_POISON) > 0;		
			hasElectricDamage = damageData.GetDamageValue(theGame.params.DAMAGE_NAME_SHOCK) > 0;
		
			//if(witcher && witcher.CanUseSkill( S_Magic_s14 ) && witcher.IsSetBonusActive( EISB_Bear_2 ))
			//{
			//	parent.PlayHitEffect( 'quen_rebound_sphere_bear_abl2', rot );
			//} //modSigns: bonus changed
			//modSigns: utilize now unused bear ability visual effect for discharge skill
			if (witcher && parent.dischargePercent > 0)
			{
				parent.PlayHitEffect( 'quen_rebound_sphere_bear_abl2', rot );
			}
			else if (hasFireDamage)
			{
				parent.PlayHitEffect( 'quen_rebound_sphere_fire', rot );
			}
			else if (hasPoisonDamage)
			{
				parent.PlayHitEffect( 'quen_rebound_sphere_poison', rot );
			}
			else if (hasElectricDamage)
			{
				parent.PlayHitEffect( 'quen_rebound_sphere_electricity', rot );
			}
			else
			{
				parent.PlayHitEffect( 'quen_rebound_sphere', rot );
			}
		}
		
		movingAgent = (CMovingPhysicalAgentComponent)caster.GetActor().GetMovingAgentComponent();
		inWater = movingAgent.GetSubmergeDepth() < 0;
		if(!inWater)
		{
			parent.PlayHitEffect( 'quen_rebound_ground', rot );
		}
	}
		
	//modSigns: modified to handle raw damages
	event OnTargetHit( out damageData : W3DamageAction )
	{
		var casterActor : CActor;
		var shieldHP, savedShieldHP, shieldFactor, staminaPrc, adrenalinePrc : float;
		var damageTypes : array<SRawDamage>;
		var reducedDamage, totalDamage : float;
		var i, size : int;
		var dmgVal : float;
		var dmgType : name;
		var returnedDmgAction : W3DamageAction;
		var attackerVictimEuler : EulerAngles;
		var reducedDamagePrc, drainedStamina, drainedAdrenaline : float;

		casterActor = caster.GetActor();
		
		//falling damage is not reduced
		if(damageData.GetBuffSourceName() == "FallingDamage")
			return true;
		
		//DoT damage from effects (bleeding, poison, burning) is not reduced
		if(damageData.IsDoTDamage() && (CBaseGameplayEffect)damageData.causer)
		{
			//theGame.witcherLog.AddMessage("Quen OnTargetHit: DoT effect, skipping.");
			return true;
		}
		
		//debug log
		//theGame.witcherLog.AddMessage("Quen OnTargetHit");
		
		//immortality from mutation removes all damages for free
		if(casterActor.HasBuff(EET_Mutation11Buff))
		{
			ShowHitFX(damageData);
			damageData.ClearDamage();
			parent.SetBlockedAllDamage(true);
			damageData.SetHitAnimationPlayType(EAHA_ForceNo);
			damageData.SetCanPlayHitParticle(false);
			return true;
		}
		
		//calculate current shield HP
		shieldFactor = CalculateAttributeValue(caster.GetSkillAttributeValue(S_Magic_s04, 'shield_health_factor', false, true));
		//casting with adrenaline
		if((W3PlayerWitcher)casterActor && caster.CanUseSkill(S_Perk_09) && parent.usedFocus)
			adrenalinePrc = casterActor.GetStat(BCS_Focus);
		else
			staminaPrc = casterActor.GetStat(BCS_Stamina)/casterActor.GetStatMax(BCS_Stamina);
		shieldHP = parent.shieldHealth * shieldFactor * (staminaPrc + adrenalinePrc);
		savedShieldHP = shieldHP;
		
		size = damageData.GetDTs(damageTypes);
				
		//debug log
		//theGame.witcherLog.AddMessage("num damages: " + size);
		
		reducedDamage = 0;
		totalDamage = 0;
		
		//process damages
		for(i = 0; i < size; i += 1)
		{
			dmgType = damageTypes[i].dmgType;
			
			//debug log
			//theGame.witcherLog.AddMessage("dmgType: " + dmgType);
			
			if(casterActor.UsesVitality() && !DamageHitsVitality(dmgType))
				continue;
			
			if(casterActor.UsesEssence() && !DamageHitsEssence(dmgType))
				continue;
			
			dmgVal = damageTypes[i].dmgVal;
			
			totalDamage += dmgVal;
			
			//debug log
			//theGame.witcherLog.AddMessage("dmgVal: " + dmgVal);
			
			if(dmgType == theGame.params.DAMAGE_NAME_DIRECT)
				continue;
			
			if(shieldHP <= 0)
				continue;
			
			if(dmgVal > shieldHP)
			{
				dmgVal = shieldHP;
				damageTypes[i].dmgVal -= dmgVal;
			}
			else
				damageTypes[i].dmgVal = 0;
			
			reducedDamage += dmgVal;
			shieldHP -= dmgVal;
			
			//debug log
			//theGame.witcherLog.AddMessage("reduced dmgVal: " + dmgVal);
			
			if(theGame.CanLog())
			{
				LogDMHits("Quen ShieldActive.OnTargetHit: reducing damage from " + damageTypes[i].dmgVal + " to " + (damageTypes[i].dmgVal - dmgVal), damageData);
			}
		}
		
		for(i = size - 1; i >= 0; i -= 1)
		{
			//theGame.witcherLog.AddMessage( "Damage #" + i + ": type = " + damageTypes[i].dmgType );
			//theGame.witcherLog.AddMessage( "Damage #" + i + ": value = " + damageTypes[i].dmgVal );
			if(damageTypes[i].dmgVal <= 0)
				damageTypes.EraseFast(i);
		}
		
		//update action damages
		if(damageTypes.Size() > 0)
			damageData.SetDTs(damageTypes);
		else
			damageData.ClearDamage();
		
		//debug log
		//theGame.witcherLog.AddMessage("total dmg: " + totalDamage);
		//theGame.witcherLog.AddMessage("total reduced dmg: " + reducedDamage);
		//theGame.witcherLog.AddMessage("remaining shield health: " + shieldHP);
		
		if(reducedDamage > 0)
		{
			ShowHitFX(damageData);
			
			//heal
			caster.GetActor().Heal(reducedDamage * parent.healingFactor);
			//debug log
			//theGame.witcherLog.AddMessage("Healing factor: " + parent.healingFactor);
			//theGame.witcherLog.AddMessage("HP healed: " + reducedDamage * parent.healingFactor);
		
			//Quen discharge, returns a percentage of reduced damage
			if(!damageData.IsDoTDamage() && casterActor == thePlayer && parent.dischargePercent > 0 && !damageData.IsActionRanged() && VecDistanceSquared( casterActor.GetWorldPosition(), damageData.attacker.GetWorldPosition() ) <= 13 ) //~3.5^2
			{
				returnedDmgAction = new W3DamageAction in theGame.damageMgr;
				returnedDmgAction.Initialize(casterActor, damageData.attacker, parent, 'quen', EHRT_Light, CPS_SpellPower, false, false, true, false, 'hit_shock');
				parent.InitSignDataForDamageAction(returnedDmgAction);
				returnedDmgAction.AddDamage(theGame.params.DAMAGE_NAME_SHOCK, parent.dischargePercent * reducedDamage);
				//debug log
				//theGame.witcherLog.AddMessage("Quen discharge dmg: " + (parent.dischargePercent * reducedDamage));
				
				returnedDmgAction.SetCanPlayHitParticle(true);
				returnedDmgAction.SetHitEffectAllTypes('hit_electric_quen');
				
				theGame.damageMgr.ProcessAction(returnedDmgAction);
				delete returnedDmgAction;
				
				parent.PlayHitEffect('discharge', attackerVictimEuler);
			}
		}
		
		if(totalDamage <= reducedDamage)
		{
			parent.SetBlockedAllDamage(true);
			damageData.SetHitAnimationPlayType(EAHA_ForceNo);
			damageData.SetCanPlayHitParticle(false);
			
			//debug log
			//theGame.witcherLog.AddMessage("quen blocked all dmg: true");
		}
		else
		{
			parent.SetBlockedAllDamage(false);
		}
		
		//don't know what that is, but keeping it just in case
		if(totalDamage - reducedDamage >= 20)
			casterActor.RaiseForceEvent( 'StrongHitTest' );
		
		//drain stamina/adrenaline
		if(reducedDamage > 0)
		{
			reducedDamagePrc = reducedDamage/(parent.shieldHealth * shieldFactor);
			//modSigns: casting with adrenaline
			if((W3PlayerWitcher)casterActor && caster.CanUseSkill(S_Perk_09) && parent.usedFocus)
			{
				drainedAdrenaline = MinF(reducedDamagePrc, casterActor.GetStat(BCS_Focus));
				if(drainedAdrenaline > 0)
					((W3PlayerWitcher)casterActor).DrainFocus( drainedAdrenaline * parent.foaMult ); //flood of anger multiplier
			}
			else
			{
				//modSigns: drain stamina
				drainedStamina = reducedDamagePrc * casterActor.GetStatMax(BCS_Stamina);
				casterActor.DrainStamina(ESAT_FixedValue, drainedStamina, casterActor.GetStaminaActionDelay(ESAT_Ability, caster.GetSkillAbilityName(S_Magic_s04)));
			}
		
			//debug log
			//theGame.witcherLog.AddMessage("Drained adrenaline %: " + (drainedAdrenaline * 100));
			//theGame.witcherLog.AddMessage("Drained stamina %: " + (drainedStamina * 100));

			//break on zero adrenaline OR zero stamina
			if(parent.usedFocus && casterActor.GetStat(BCS_Focus) <= 0 || !parent.usedFocus && casterActor.GetStat(BCS_Stamina) <= 0)
			{
				if(parent.impulseLevel > 0)
				{
					parent.PlayHitEffect('quen_rebound_sphere_impulse', attackerVictimEuler);
					caster.GetPlayer().QuenImpulse(true, parent, "quen_impulse", parent.impulseLevel, parent.quenPower);
				}
				damageData.SetEndsQuen(true);
			}
		}
	}
}
