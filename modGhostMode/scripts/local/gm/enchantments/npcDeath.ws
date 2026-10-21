// CNewNPC.OnDeath, replaced for ENCH (legacy npc.ws): Eruption (ENCH-13: the explosion deals Glyphword 20's fire damage only, no weapon term) and Possession (ENCH-14) from the
// chest armor; Possession transfers Axii only to an enemy not already under Axii, not immune and below
// 100% will resistance; Usurpation no longer transfers it. The other areas' legacy changes to OnDeath stay
// 5.x's until their areas; ENCH-08's kill triggers (Rejuvenation, Elation) are here, as legacy's. 5.x body; changes marked //modSigns. See docs/features/ench.md.

@replaceMethod(CNewNPC)
function OnDeath( damageAction : W3DamageAction  )
{		
	var inWater, fists, tmpBool, addAbility, isFinisher : bool;		
	var expPoints, npcLevel, lvlDiff, i, j, swank		: int;
	var abilityName, tmpName 							: name;
	var abilityCount, maxStack, minDist					: float;
	var gmWillPts, gmWillPrc : float;	//modSigns: ENCH-14
	var itemExpBonus, radius							: float;
	
	var allItems 										: array<SItemUniqueId>;
	var damages 										: array<SRawDamage>;
	var atts 											: array<name>;
	var entities  										: array< CGameplayEntity >;
	
	var params											: SCustomEffectParams;
	var dmg 											: SRawDamage;
	var weaponID 										: SItemUniqueId;
	var min, max, bonusExp 								: SAbilityAttributeValue;

	var monsterCategory 								: EMonsterCategory;
	var attitudeToPlayer 								: EAIAttitude;
	
	var actor , targetEntity							: CActor;
	var gameplayEffect 									: CBaseGameplayEffect;
	var fxEnt 											: CEntity;
	
	var attackAction 									: W3Action_Attack;	
	var ciriEntity  									: W3ReplacerCiri;
	var witcher											: W3PlayerWitcher;
	var blizzard 										: W3Potion_Blizzard;
	var act 											: W3DamageAction;
	var burningCauser 									: W3Effect_Burning;
	var vfxEnt 											: W3VisualFx;
	var aerondight										: W3Effect_Aerondight;
	
	
	var damageAttr 										: SAbilityAttributeValue;
	var inv												: CInventoryComponent;
	var weaponId 										: SItemUniqueId;
	var damageNames										: array < CName >;
	var damageValue 									: float;
	var attribute										: name;
	

	ciriEntity = (W3ReplacerCiri)thePlayer;
	witcher = GetWitcherPlayer();
	
	deathTimestamp = theGame.GetEngineTimeAsSeconds();
	
	if(damageAction.attacker == GetWitcherPlayer() && (damageAction.IsActionMelee() || damageAction.IsActionRanged() || damageAction.IsActionWitcherSign() || damageAction.GetBuffSourceName() == "Kill" || damageAction.GetBuffSourceName() == "Finisher" || damageAction.GetBuffSourceName() == "AutoFinisher"))	//modSigns: ENCH-08, Rejuvenation and Elation on Geralt's kills (legacy; 5.x: in ProcessAction)
	{	//modSigns
		if(GetWitcherPlayer().HasRunewordActive('Runeword 10 _Stats'))	//modSigns
			GetWitcherPlayer().Runeword10Triggerred();	//modSigns
		if(GetWitcherPlayer().HasRunewordActive('Runeword 12 _Stats'))	//modSigns
			GetWitcherPlayer().Runeword12Triggerred();	//modSigns
	}	//modSigns
	
	if( damageAction.GetBuffSourceName() == "Mutation 6" )
	{
		PlayEffect( 'critical_frozen' );
		AddTimer( 'StopMutation6FX', 3.f );
	}
	
	if ( GetWitcherPlayer().HasGlyphwordActive('Glyphword 18 _Stats') && (HasBuff(EET_AxiiGuardMe) || HasBuff(EET_Confusion)) )	//modSigns: ENCH-14, Possession only, from the chest armor (legacy)
	{
		abilityName = 'Glyphword 18 _Stats';	//modSigns: Possession only (Usurpation's transfer removed)
			
		min = thePlayer.GetAbilityAttributeValue(abilityName, 'glyphword_range');
		FindGameplayEntitiesInRange(entities, this, CalculateAttributeValue(min), 10,, FLAG_OnlyAliveActors + FLAG_ExcludeTarget, this); 	
		
		minDist = 10000;
		for (i = 0; i < entities.Size(); i += 1)
		{
			if ( entities[i] == thePlayer.GetHorseWithInventory() || entities[i] == thePlayer || !IsRequiredAttitudeBetween(thePlayer, entities[i], true) )
				continue;
			if ( ((CActor)entities[i]).HasBuff(EET_AxiiGuardMe) || ((CActor)entities[i]).HasBuff(EET_Confusion) ) continue;	//modSigns: skip targets already affected (legacy)
			if ( HasBuff(EET_AxiiGuardMe) && ((CActor)entities[i]).IsImmuneToBuff(EET_AxiiGuardMe) || HasBuff(EET_Confusion) && ((CActor)entities[i]).IsImmuneToBuff(EET_Confusion) ) continue;	//modSigns: skip immune targets (legacy)
			((CActor)entities[i]).GetResistValue(CDS_WillRes, gmWillPts, gmWillPrc);	//modSigns: skip targets with 100% will resistance (legacy)
			if ( gmWillPrc >= 1.0 ) continue;	//modSigns
				
			if ( VecDistance2D(this.GetWorldPosition(), entities[i].GetWorldPosition()) < minDist)
			{
				minDist = VecDistance2D(this.GetWorldPosition(), entities[i].GetWorldPosition());
				targetEntity = (CActor)entities[i];
			}
		}
		
		if ( targetEntity )
		{
			if ( HasBuff(EET_AxiiGuardMe) )
				gameplayEffect = GetBuff(EET_AxiiGuardMe);
			else if ( HasBuff(EET_Confusion) )
				gameplayEffect = GetBuff(EET_Confusion);
			
			params.effectType 				= gameplayEffect.GetEffectType();
			params.creator 					= gameplayEffect.GetCreator();
			params.sourceName 				= gameplayEffect.GetSourceName();
			params.duration 				= gameplayEffect.GetDurationLeft();
			if ( params.duration < 5.0f ) 	params.duration = 5.0f;
			params.effectValue 				= gameplayEffect.GetEffectValue();
			params.customAbilityName 		= gameplayEffect.GetAbilityName();
			params.customFXName 			= gameplayEffect.GetTargetEffectName();
			params.isSignEffect 			= gameplayEffect.IsSignEffect();
			params.customPowerStatValue 	= gameplayEffect.GetCreatorPowerStat();
			params.vibratePadLowFreq 		= gameplayEffect.GetVibratePadLowFreq();
			params.vibratePadHighFreq		= gameplayEffect.GetVibratePadHighFreq();
			
			targetEntity.AddEffectCustom(params);
			gameplayEffect = targetEntity.GetBuff(params.effectType);
			gameplayEffect.SetTimeLeft(params.duration);
			
			fxEnt = CreateFXEntityAtPelvis( 'glyphword_10_18', true );
			fxEnt.PlayEffect('out');
			fxEnt.DestroyAfter(5);
			
			fxEnt = targetEntity.CreateFXEntityAtPelvis( 'glyphword_10_18', true );
			fxEnt.PlayEffect('in');
			fxEnt.DestroyAfter(5);
		}
	}
	
	super.OnDeath( damageAction );
	
	if ( (!IsHuman() && (damageAction.attacker == thePlayer || GetAttitudeBetween( thePlayer, damageAction.attacker ) == AIA_Friendly) && !ciriEntity && !HasTag('NoBestiaryEntry')) 

	) 
		AddBestiaryKnowledge();	
	
	if ( !WillBeUnconscious() && !HasTag( 'NoHitFx' ) )
	{
		if ( theGame.GetWorld().GetWaterDepth( this.GetWorldPosition() ) > 0 )
		{
			if ( this.HasEffect( 'water_death' ) ) this.PlayEffectSingle( 'water_death' );
		}
		else
		{
			if ( this.HasEffect( 'blood_spill' ) && !HasAbility ( 'NoBloodSpill' ) ) this.PlayEffectSingle( 'blood_spill' );
		}
	}
	
	
	if ( ( ( CMovingPhysicalAgentComponent ) this.GetMovingAgentComponent() ).HasRagdoll() )
	{
		SetBehaviorVariable('HasRagdoll', 1 );
	}
	
	
	if ( (W3AardProjectile)( damageAction.causer ) )
	{
		DropItemFromSlot( 'r_weapon' );
		DropItemFromSlot( 'l_weapon' );
		this.BreakAttachment();
	}
	
	SignalGameplayEventParamObject( 'OnDeath', damageAction );
	theGame.GetBehTreeReactionManager().CreateReactionEvent( this, 'BattlecryGroupDeath', 1.0f, 20.0f, -1.0f, 1 );
	
	attackAction = (W3Action_Attack)damageAction;
	
	
	if ( ((CMovingPhysicalAgentComponent)GetMovingAgentComponent()).GetSubmergeDepth() < 0 )
	{
		inWater = true;
		DisableAgony();
	}
	
	
	if( IsUsingHorse() )
	{
		SoundEvent( "cmb_play_hit_heavy" );
		SoundEvent( "grunt_vo_death" );
	}
					
	if(damageAction.attacker == thePlayer && ((W3PlayerWitcher)thePlayer) && thePlayer.GetStat(BCS_Toxicity) > 0 && thePlayer.CanUseSkill(S_Alchemy_s17))
	{
		thePlayer.AddAbilityMultiple( SkillEnumToName(S_Alchemy_s17), thePlayer.GetSkillLevel(S_Alchemy_s17) );
	}
	
	OnChangeDyingInteractionPriorityIfNeeded();
	
	actor = (CActor)damageAction.attacker;
	
	
	if(ShouldGiveExp(damageAction.attacker))
	{
		npcLevel = (int)CalculateAttributeValue(GetAttributeValue('level',,true));
		lvlDiff = npcLevel - witcher.GetLevel();
		expPoints = CalculateExperiencePoints();
		
		
		if(expPoints > 0)
		{				
			theGame.GetMonsterParamsForActor(this, monsterCategory, tmpName, tmpBool, tmpBool, tmpBool);
			if(MonsterCategoryIsMonster(monsterCategory))
			{
				bonusExp = thePlayer.GetAttributeValue('nonhuman_exp_bonus_when_fatal');
			}
			else
			{
				bonusExp = thePlayer.GetAttributeValue('human_exp_bonus_when_fatal');
			}				
			
			expPoints = RoundMath( expPoints * (1 + CalculateAttributeValue(bonusExp)) );
			
			witcher.AddPoints(EExperiencePoint, RoundF( expPoints * theGame.expGlobalMod_kills ), false );
		}			
	}
			
	
	attitudeToPlayer = GetAttitudeBetween(this, thePlayer);
	
	if(attitudeToPlayer == AIA_Hostile && !HasTag('AchievementKillDontCount'))
	{
		
		if(actor && actor.HasBuff(EET_AxiiGuardMe))
		{
			theGame.GetGamerProfile().IncStat(ES_CharmedNPCKills);
			FactsAdd("statistics_cerberus_sign");
		}
		
		
		if( aardedFlight && damageAction.GetBuffSourceName() == "FallingDamage" )
		{
			theGame.GetGamerProfile().IncStat(ES_AardFallKills);
		}
			
		
		if(damageAction.IsActionEnvironment())
		{
			theGame.GetGamerProfile().IncStat(ES_EnvironmentKills);
			FactsAdd("statistics_cerberus_environment");
		}
	}
	
	
	if(HasTag('cow'))
	{
		if( (damageAction.attacker == thePlayer) ||
			((W3SignEntity)damageAction.attacker && ((W3SignEntity)damageAction.attacker).GetOwner() == thePlayer) ||
			((W3SignProjectile)damageAction.attacker && ((W3SignProjectile)damageAction.attacker).GetCaster() == thePlayer) ||
			( (W3Petard)damageAction.attacker && ((W3Petard)damageAction.attacker).GetOwner() == thePlayer)
		){
			theGame.GetGamerProfile().IncStat(ES_KilledCows);
		}
	}
	
	
	if ( damageAction.attacker == thePlayer )
	{
		theGame.GetMonsterParamsForActor(this, monsterCategory, tmpName, tmpBool, tmpBool, tmpBool);
		
		
		//modSigns: removed 5.x's Grave Hag regen per kill, uncapped (ALCH-12)
		GMDecoctionsOnKill();	//modSigns: ALCH-12, Noonwraith's and Grave Hag's stacks per kill (legacy)
		
		
		if (thePlayer.HasBuff(EET_Mutagen06))
		{
			
			if(monsterCategory != MC_Animal || IsRequiredAttitudeBetween(this, thePlayer, true))
			{	
				gameplayEffect = thePlayer.GetBuff(EET_Mutagen06);
				thePlayer.AddAbility( gameplayEffect.GetAbilityName(), true);
			}
		}
		
		
		if(IsRequiredAttitudeBetween(this, thePlayer, true))
		{
			blizzard = (W3Potion_Blizzard)thePlayer.GetBuff(EET_Blizzard);
			if(blizzard)
				blizzard.KilledEnemy();
		}
		
		
		if( witcher.IsSetBonusActive( EISB_Vampire ) && !witcher.IsInFistFight() && !WillBeUnconscious() )
		{
			witcher.VampiricSetAbilityRegeneration();
		}
		
		if(!HasTag('AchievementKillDontCount'))
		{
			if (damageAction.GetIsHeadShot() && monsterCategory == MC_Human )		
				theGame.GetGamerProfile().IncStat(ES_HeadShotKills);
				
			
			if( (W3SignEntity)damageAction.causer || (W3SignProjectile)damageAction.causer)
			{
				FactsAdd("statistics_cerberus_sign");
			}
			else if( (CBaseGameplayEffect)damageAction.causer && ((CBaseGameplayEffect)damageAction.causer).IsSignEffect())
			{
				FactsAdd("statistics_cerberus_sign");
			}
			else if( (W3Petard)damageAction.causer )
			{
				FactsAdd("statistics_cerberus_petard");
			}
			else if( (W3BoltProjectile)damageAction.causer )
			{
				FactsAdd("statistics_cerberus_bolt");
			}				
			else
			{
				if(!attackAction)
					attackAction = (W3Action_Attack)damageAction;
					
				fists = false;
				if(attackAction)
				{
					weaponID = attackAction.GetWeaponId();
					if(damageAction.attacker.GetInventory().IsItemFists(weaponID))
					{
						FactsAdd("statistics_cerberus_fists");
						fists = true;
					}						
				}
				
				if(!fists && damageAction.IsActionMelee())
				{
					FactsAdd("statistics_cerberus_melee");
				}
			}
		}
		
		
		if( expPoints > 0 && !HasTag( 'AchievementKillDontCount' ) && thePlayer.inv.HasItem( 'q705_tissue_extractor' ) )
		{
			thePlayer.TissueExtractorIncCharge();
		}
		
		
		if( (W3BoltProjectile)damageAction.causer && damageAction.GetWasFrozen() && !WillBeUnconscious() )
		{
			theGame.GetGamerProfile().AddAchievement( EA_HastaLaVista );
			thePlayer.PlayVoiceset( 100, "HastaLaVista", true );
		}
					
		
		
	}
	
	
	if( damageAction.attacker == thePlayer || !((CNewNPC)damageAction.attacker) )
	{
		theTelemetry.LogWithLabelAndValue(TE_FIGHT_ENEMY_DIES, this.ToString(), GetLevel());
	}
	
	
	if(damageAction.attacker == thePlayer && !HasTag('AchievementKillDontCount'))
	{
		if ( attitudeToPlayer == AIA_Hostile )
		{
			
			if(!HasTag('AchievementSwankDontCount'))
			{
				swank = FactsQuerySum("statistic_killed_in_10_sec");
				if(swank >= 4)
					theGame.GetGamerProfile().AddAchievement(EA_Swank);
				else
				{
					FactsAdd("statistic_killed_in_10_sec", 1, 10);
					if(swank > 0)
						theGame.GetGamerProfile().NoticeAchievementProgress(EA_Swank, swank);
				}
			}
			
			
			if( witcher && !thePlayer.ReceivedDamageInCombat() && !witcher.UsedQuenInCombat())
			{
				theGame.GetGamerProfile().IncStat(ES_FinesseKills);
			}
		}
		
		
		if((W3PlayerWitcher)thePlayer)
		{
			if(!thePlayer.DidFailFundamentalsFirstAchievementCondition() && HasTag(theGame.params.MONSTER_HUNT_ACTOR_TAG) && !HasTag('failedFundamentalsAchievement'))
			{
				theGame.GetGamerProfile().IncStat(ES_FundamentalsFirstKills);
			}
		}
	}
				
	
	if(!inWater && (W3IgniProjectile)damageAction.causer)
	{
		
		if(RandF() < 0.3 && !WillBeUnconscious() )
		{
			AddEffectDefault(EET_Burning, this, 'IgniKill', true);
			EnableAgony();
			SignalGameplayEvent('ForceAgony');			
		}
	}
	
	
	OnDeathMutation2( damageAction );		
	
	
	if(damageAction.attacker == thePlayer && GetWitcherPlayer().HasGlyphwordActive('Glyphword 20 _Stats') && damageAction.GetBuffSourceName() != "Glyphword 20")	//modSigns: ENCH-13, Eruption from the chest armor (ENCH-01)
	{
		burningCauser = (W3Effect_Burning)damageAction.causer;			
		
		if(IsRequiredAttitudeBetween(thePlayer, damageAction.victim, true, false, false) && ((burningCauser && burningCauser.IsSignEffect()) || (W3IgniProjectile)damageAction.causer))
		{
			damageAction.SetForceExplosionDismemberment();
			
			
			radius = CalculateAttributeValue(thePlayer.GetAbilityAttributeValue('Glyphword 20 _Stats', 'radius'));
			
			
			theGame.GetDefinitionsManager().GetAbilityAttributes('Glyphword 20 _Stats', atts);
			for(i=0; i<atts.Size(); i+=1)
			{
				if(IsDamageTypeNameValid(atts[i]))
				{
					dmg.dmgType = atts[i];
					dmg.dmgVal = CalculateAttributeValue(thePlayer.GetAbilityAttributeValue('Glyphword 20 _Stats', dmg.dmgType));
					damages.PushBack(dmg);
				}
			}
			
			
			//modSigns: ENCH-13, removed 5.x's added damage (the dying enemy's weapon damage x5, minimum 50): Eruption deals Glyphword 20's 300 fire damage only (legacy)
			
			
			
			FindGameplayEntitiesInSphere(entities, GetWorldPosition(), radius, 1000, , FLAG_OnlyAliveActors);
			
			
			for(i=0; i<entities.Size(); i+=1)
			{
				if(IsRequiredAttitudeBetween(thePlayer, entities[i], true, false, false))
				{
					act = new W3DamageAction in this;
					act.Initialize(thePlayer, entities[i], damageAction.causer, "Glyphword 20", EHRT_Heavy, CPS_SpellPower, false, false, true, false);
					
					for(j=0; j<damages.Size(); j+=1)
					{
						act.AddDamage(damages[j].dmgType, damages[j].dmgVal);
					}
					//modSigns: ENCH-13, removed 5.x's weapon damage term
					
					
					act.AddEffectInfo(EET_Burning);	//modSigns: ENCH-13, Eruption's explosion always sets alight (legacy; 5.x: 50%)
					
					theGame.damageMgr.ProcessAction(act);
					delete act;
				}
			}
			
			CreateFXEntityAtPelvis( 'glyphword_20_explosion', false );				
		}
	}
	
	
	if(attackAction && IsWeaponHeld('fist') && damageAction.attacker == thePlayer && !thePlayer.ReceivedDamageInCombat() && !HasTag('AchievementKillDontCount'))
	{
		weaponID = attackAction.GetWeaponId();
		if(thePlayer.inv.IsItemFists(weaponID))
			theGame.GetGamerProfile().AddAchievement(EA_FistOfTheSouthStar);
	}
	
	
	if(damageAction.IsActionRanged() && damageAction.IsBouncedArrow())
	{
		theGame.GetGamerProfile().IncStat(ES_SelfArrowKills);
	}
	
	
	isFinisher = ( damageAction.GetBuffSourceName() == "Finisher" || damageAction.GetBuffSourceName() == "AutoFinisher" );
	if( damageAction.attacker == thePlayer && ( damageAction.IsActionMelee() || isFinisher ) )
	{			
		weaponID = attackAction.GetWeaponId();
		
		if( isFinisher && !thePlayer.inv.IsIdValid( weaponID ) )
		{
			weaponID = thePlayer.inv.GetCurrentlyHeldSword();
		}
		
		//modSigns: removed Aerondight's discharge and charge on kills and finishers (SWD-05, legacy)
	}


}
