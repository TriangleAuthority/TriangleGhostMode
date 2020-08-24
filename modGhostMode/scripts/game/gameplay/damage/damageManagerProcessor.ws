/***********************************************************************/
/** 	© 2015 CD PROJEKT S.A. All rights reserved.
/** 	THE WITCHER® is a trademark of CD PROJEKT S. A.
/** 	The Witcher game is based on the prose of Andrzej Sapkowski.
/***********************************************************************/





class W3DamageManagerProcessor extends CObject 
{
	
	private var playerAttacker				: CR4Player;				
	private var playerVictim				: CR4Player;				
	private var action						: W3DamageAction;
	private var attackAction				: W3Action_Attack;			
	private var weaponId					: SItemUniqueId;			
	private var actorVictim 				: CActor;					
	private var actorAttacker				: CActor;					
	private var dm 							: CDefinitionsManagerAccessor;
	private var attackerMonsterCategory		: EMonsterCategory;
	private var victimMonsterCategory		: EMonsterCategory;
	private var victimCanBeHitByFists		: bool;
	private var weaponsAreNotDeadly			: bool; //modSigns
	private var victimHealthPercBeforeHit	: float; //modSigns
	private var mutation8Triggered			: bool; //modSigns
	private var hasArmor					: bool; //modSigns
	
	
	
	public function ProcessAction(act : W3DamageAction)
	{
		var wasAlive, validDamage, isFrozen, autoFinishersEnabled : bool;
		var focusDrain : float;
		var npc : CNewNPC;
		var buffs : array<EEffectType>;
		var arrStr : array<string>;
		var aerondight	: W3Effect_Aerondight;
		//var trailFxName : name;
		var min, max : SAbilityAttributeValue; //modSigns
		var phantomWeapon : W3Effect_PhantomWeapon; //modSigns
			
		wasAlive = act.victim.IsAlive();		
		npc = (CNewNPC)act.victim;
		
		
 		InitializeActionVars(act);
 		
 		
		
		//debug
		/*theGame.witcherLog.AddMessage("DMG MANAGER");
		theGame.witcherLog.AddMessage("Attacker: " + actorAttacker.GetDisplayName());
		theGame.witcherLog.AddMessage("Victim: " + actorVictim.GetDisplayName());
		if (!npc.IsAnimal())
		{
			theGame.witcherLog.AddMessage("NPC level: " + npc.GetLevel());
			theGame.witcherLog.AddMessage("Max vitality: " + npc.GetStatMax(BCS_Vitality));
			theGame.witcherLog.AddMessage("Max essence: " + npc.GetStatMax(BCS_Essence));
			theGame.witcherLog.AddMessage("UsesVitality: " + npc.UsesVitality());
			theGame.witcherLog.AddMessage("UsesEssence: " + npc.UsesEssence());
			theGame.witcherLog.AddMessage("Cur vitality: " + npc.GetStat(BCS_Vitality));
			theGame.witcherLog.AddMessage("Cur essence: " + npc.GetStat(BCS_Essence));
			theGame.witcherLog.AddMessage("IsImmortal: " + npc.IsImmortal());
			theGame.witcherLog.AddMessage("IsInvulnerable: " + npc.IsInvulnerable());
			theGame.witcherLog.AddMessage("IsAlive: " + npc.IsAlive());
		}*/
		
		//modSigns: parry-stagger and counter behavior if an attack can't be parried
 		if(playerVictim && attackAction && attackAction.IsActionMelee() && 
			(attackAction.IsParried() || attackAction.IsCountered()) && 
			(!attackAction.CanBeParried() ||
				attackAction.IsParried() && playerVictim.IsParryingWithNotEnoughStamina()))
 		{
			action.GetEffectTypes(buffs);
			
			if(	!buffs.Contains(EET_Knockdown) && !buffs.Contains(EET_HeavyKnockdown) &&
				!buffs.Contains(EET_Stagger) && !buffs.Contains(EET_LongStagger) &&
				!buffs.Contains(EET_KnockdownTypeApplicator)) //modSigns
			{
				action.SetParryStagger();
				action.SetHitAnimationPlayType(EAHA_ForceNo);
				action.SetCanPlayHitParticle(false);

				if(attackAction.IsParried())
				{
					action.SetProcessBuffsIfNoDamage(true);
					action.RemoveBuffsByType(EET_Bleeding);
					action.RemoveBuffsByType(EET_LongStagger);
					action.AddEffectInfo(EET_Stagger);
				}
				else if(attackAction.IsCountered())
				{
					action.SetProcessBuffsIfNoDamage(false);
					action.ClearEffects();
				}
			}
 		}
 		
 		
 		//if(actorAttacker && playerVictim && ((W3PlayerWitcher)playerVictim) && GetWitcherPlayer().IsAnyQuenActive())
		//	FactsAdd("player_had_quen"); //modSigns
		
		
		ProcessPreHitModifications();

		
		ProcessActionQuest(act);
		
		
		isFrozen = (actorVictim && actorVictim.HasBuff(EET_Frozen));
		
		//modSigns: check dodge before processing the damage
		if(actorVictim)
			actorVictim.DodgeDamage(action);
		
		//modSigns: only process damage if it wasn't dodged
		if(!action.WasDodged())
			validDamage = ProcessActionDamage();
		else
			validDamage = 0;
		
		
		if(wasAlive && !action.victim.IsAlive())
		{
			arrStr.PushBack(action.victim.GetDisplayName());
			if(npc && npc.WillBeUnconscious())
			{
				theGame.witcherLog.AddCombatMessage(GetLocStringByKeyExtWithParams("hud_combat_log_unconscious", , , arrStr), NULL, action.victim);
			}
			else if(action.attacker && action.attacker.GetDisplayName() != "")
			{
				arrStr.PushBack(action.attacker.GetDisplayName());
				theGame.witcherLog.AddCombatMessage(GetLocStringByKeyExtWithParams("hud_combat_log_killed", , , arrStr), action.attacker, action.victim);
			}
			else
			{
				theGame.witcherLog.AddCombatMessage(GetLocStringByKeyExtWithParams("hud_combat_log_dies", , , arrStr), NULL, action.victim);
			}
		}
		
		if( wasAlive && action.DealsAnyDamage() )
		{
			//modSigns: percentage relative to max HP instead of just damage
			if( action.victim == thePlayer )
				((CActor)action.attacker).SignalGameplayEventParamFloat( 'CausesDamage', ClampF( action.processedDmg.vitalityDamage / (0.5 * thePlayer.GetMaxHealth()), 0.0f, 1.0f ) );
			else
				((CActor)action.attacker).SignalGameplayEventParamFloat( 'CausesDamage', 1.0 );
			
			//modSigns: signal headshot
			if( playerAttacker && action.GetIsHeadShot() )
				actorVictim.SignalGameplayEvent( 'Headshot' );
		}
		
		
		ProcessActionReaction(isFrozen, wasAlive);
		
		
		if(action.DealsAnyDamage() || action.ProcessBuffsIfNoDamage())
			ProcessActionBuffs();
		
		
		if(theGame.CanLog() && !validDamage && action.GetEffectsCount() == 0)
		{
			LogAssert(false, "W3DamageManagerProcessor.ProcessAction: action deals no damage and gives no buffs - investigate!");
			if ( theGame.CanLog() )
			{
				LogDMHits("*** Action has no valid damage and no valid buffs - investigate!", action);
			}
		}
		
		if( actorAttacker && wasAlive )
			actorAttacker.OnProcessActionPost(action);

		
		if(actorVictim == GetWitcherPlayer() && action.DealsAnyDamage() && !action.IsDoTDamage())
		{
			//if(actorAttacker && attackAction)
			//{
			//	if(actorAttacker.IsHeavyAttack( attackAction.GetAttackName() ))
			//		focusDrain = CalculateAttributeValue(thePlayer.GetAttributeValue('heavy_attack_focus_drain'));
			//	else if(actorAttacker.IsSuperHeavyAttack( attackAction.GetAttackName() ))
			//		focusDrain = CalculateAttributeValue(thePlayer.GetAttributeValue('super_heavy_attack_focus_drain'));
			//	else 
			//		focusDrain = CalculateAttributeValue(thePlayer.GetAttributeValue('light_attack_focus_drain')); 
			//}
			//else
			//{
			//	
			//	focusDrain = CalculateAttributeValue(thePlayer.GetAttributeValue('light_attack_focus_drain')); 
			//}
			//modSigns: remove vanilla attack type dependency entirely and replace it with hp dependency
			focusDrain = ClampF(action.GetDamageDealt() / actorVictim.GetMaxHealth(), 0, 1);
			
			//Resolve loss reduction
			if ( GetWitcherPlayer().CanUseSkill(S_Sword_s16) )
				focusDrain *= 1 - (CalculateAttributeValue( thePlayer.GetSkillAttributeValue(S_Sword_s16, 'focus_drain_reduction', false, true) ) * thePlayer.GetSkillLevel(S_Sword_s16));
				
			//theGame.witcherLog.AddMessage("focus drain: " + focusDrain);
			
			//modSigns: Bear tier 1 adrenaline
			if(GetWitcherPlayer().IsSetBonusActive(EISB_Bear_1))
			{
				theGame.GetDefinitionsManager().GetAbilityAttributeValue(GetSetBonusAbility(EISB_Bear_1), 'bonus_focus_gain', min, max);
				min.valueAdditive *= GetWitcherPlayer().GetSetPartsEquipped(EIST_Bear);
				//theGame.witcherLog.AddMessage("focus gain: " + min.valueAdditive);
				focusDrain -= min.valueAdditive;
			}
			
			//theGame.witcherLog.AddMessage("focus delta: " + (-focusDrain));
			
			if(focusDrain > 0)
				thePlayer.DrainFocus(focusDrain);
			else if(focusDrain < 0)
				thePlayer.GainStat(BCS_Focus, -focusDrain);
		}
		
		//modSigns: new perk 21 ability
		if(actorAttacker == GetWitcherPlayer() && thePlayer.CanUseSkill(S_Perk_21) && actorVictim && (action.IsActionMelee() || action.IsActionRanged() || action.IsActionWitcherSign()))
		{
			if(action.IsCriticalHit() && action.DealsAnyDamage())
			{
				GetWitcherPlayer().Perk21GainStamina('crit');
			}
		}
		
		//modSigns: make runewords 10 and 12 more useful -> moved to another place
		//if(actorAttacker == GetWitcherPlayer() && actorVictim && wasAlive && !actorVictim.IsAlive() && (action.IsActionMelee() || action.IsActionRanged() || action.IsActionWitcherSign() || action.GetBuffSourceName() == "Kill"))
		//{
			//autoFinishersEnabled = theGame.GetInGameConfigWrapper().GetVarValue('Gameplay', 'AutomaticFinishersEnabled');
			//if(!autoFinishersEnabled || !thePlayer.GetFinisherVictim())
			//{
				//if(GetWitcherPlayer().HasRunewordActive('Runeword 10 _Stats')) //modSigns
				//	GetWitcherPlayer().Runeword10Triggerred();
				//if(GetWitcherPlayer().HasRunewordActive('Runeword 12 _Stats')) //modSigns
				//	GetWitcherPlayer().Runeword12Triggerred();
				//theGame.witcherLog.AddMessage("Runewords triggered");
			//}
		//}
		
		
		if(action.EndsQuen() && actorVictim)
		{
			actorVictim.FinishQuen(false);			
		}
		
		//modSigns: reset recently countered after all the processing is done
		//if(playerAttacker && (W3PlayerWitcher)playerAttacker && ((W3PlayerWitcher)playerAttacker).HasRecentlyCountered())
		//	((W3PlayerWitcher)playerAttacker).SetRecentlyCountered(false);
		if(playerAttacker && actorVictim && actorVictim.WasCountered() && !action.IsDoTDamage())
			actorVictim.SetWasCountered(false);

		
		if(actorVictim == thePlayer && attackAction && attackAction.IsActionMelee() && (ShouldProcessTutorial('TutorialDodge') || ShouldProcessTutorial('TutorialCounter') || ShouldProcessTutorial('TutorialParry')) )
		{
			if(attackAction.IsCountered())
			{
				theGame.GetTutorialSystem().IncreaseCounters();
			}
			else if(attackAction.IsParried())
			{
				theGame.GetTutorialSystem().IncreaseParries();
			}
			
			if(attackAction.CanBeDodged() && !attackAction.WasDodged())
			{
				GameplayFactsAdd("tut_failed_dodge", 1, 1);
				GameplayFactsAdd("tut_failed_roll", 1, 1);
			}
		}
		
		if( playerAttacker && npc && action.IsActionMelee() && action.DealtDamage() && IsRequiredAttitudeBetween( playerAttacker, npc, true ) )
		{			
			//modSigns: increase charges/discharge Aerondight
			if( attackAction && !attackAction.WasDodged() && playerAttacker.inv.ItemHasTag( attackAction.GetWeaponId(), 'Aerondight' ) /*&& !npc.HasTag( 'AerondightIgnore' )*/ )
			{
				aerondight = (W3Effect_Aerondight)playerAttacker.GetBuff( EET_Aerondight );
				if( aerondight )
				{
					if( aerondight.IsFullyCharged() )
					{
						aerondight.PlayTrailEffect( npc.GetBloodType() );
						aerondight.DischargeAerondight( npc );
					}
					else
						aerondight.AddCharge();
				}
			}
			
			//modSigns: increase charges/discharge Iris
			if( attackAction && !attackAction.WasDodged() && playerAttacker.inv.ItemHasTag( attackAction.GetWeaponId(), 'PhantomWeapon' ) )
			{
				phantomWeapon = (W3Effect_PhantomWeapon)playerAttacker.GetBuff( EET_PhantomWeapon );
				if( phantomWeapon )
				{
					//theGame.witcherLog.AddMessage("Attack src = " + attackAction.GetBuffSourceName());
					//theGame.witcherLog.AddMessage("IsFullyCharged = " + phantomWeapon.IsFullyCharged());
					//health drain
					if( phantomWeapon.IsFullyCharged() )
						phantomWeapon.DrainAttackerHealth();
					if( attackAction.GetBuffSourceName() == "PhantomWeapon" )
						phantomWeapon.DischargePhantomWeapon();
					else if( !phantomWeapon.IsFullyCharged() )
						phantomWeapon.AddCharge();
				}
			}
		}
	}
	
	
	private final function InitializeActionVars(act : W3DamageAction)
	{
		var tmpName : name;
		var tmpBool	: bool;
	
		action 				= act;
		playerAttacker 		= (CR4Player)action.attacker;
		playerVictim		= (CR4Player)action.victim;
		attackAction 		= (W3Action_Attack)action;		
		actorVictim 		= (CActor)action.victim;
		actorAttacker		= (CActor)action.attacker;
		dm 					= theGame.GetDefinitionsManager();
		
		if(attackAction)
			weaponId 		= attackAction.GetWeaponId();
			
		theGame.GetMonsterParamsForActor(actorVictim, victimMonsterCategory, tmpName, tmpBool, tmpBool, victimCanBeHitByFists);
		
		if(actorAttacker)
			theGame.GetMonsterParamsForActor(actorAttacker, attackerMonsterCategory, tmpName, tmpBool, tmpBool, tmpBool);
		
		weaponsAreNotDeadly = NonDeadlyWeaponFight(); //modSigns
		
		//modSigns
		if(actorVictim && actorVictim.UsesVitality())
			victimHealthPercBeforeHit = actorVictim.GetStatPercents(BCS_Vitality);
		else if(actorVictim && actorVictim.UsesEssence())
			victimHealthPercBeforeHit = actorVictim.GetStatPercents(BCS_Essence);
		
		CheckMutation8Finisher(); //modSigns
	}
	
	//modSigns begin
	private function NonDeadlyWeaponFight() : bool
	{
		var attackerNonDeadly, victimNonDeadly : bool;
		var attackerWeaponId, victimWeaponId : SItemUniqueId;
		var heldWeapons : array<SItemUniqueId>;
		var attackerInv, victimInv : CInventoryComponent;
		
		if(!attackAction || !attackAction.IsActionMelee() || !actorAttacker || !actorVictim)
			return false;
		
		attackerInv = actorAttacker.GetInventory();
		heldWeapons = attackerInv.GetHeldWeapons();
		if(heldWeapons.Size() > 0)
			attackerWeaponId = heldWeapons[0];
		
		if(attackerWeaponId == GetInvalidUniqueId())
			return false;
		
		victimInv = actorVictim.GetInventory();
		heldWeapons = victimInv.GetHeldWeapons();
		if(heldWeapons.Size() > 0)
			victimWeaponId = heldWeapons[0];
		
		if(victimWeaponId == GetInvalidUniqueId())
			return false;
		
		if(actorAttacker.HasAbility('mon_ff204olaf') || actorAttacker.HasAbility('mon_ff205troll') || actorAttacker.HasAbility('mon_EP2_clubDwarfs') || actorAttacker.HasTag('mq7011_guards'))
			attackerNonDeadly = true;
		else
			attackerNonDeadly = attackerInv.ItemHasTag(attackerWeaponId, 'Wooden') || attackerInv.ItemHasTag(attackerWeaponId, 'Fists') && !attackerInv.ItemHasTag(attackerWeaponId, 'MagicWeaponFX');
		
		if(actorVictim.HasAbility('mon_ff204olaf') || actorVictim.HasAbility('mon_ff205troll') || actorVictim.HasAbility('mon_EP2_clubDwarfs') || actorVictim.HasTag('mq7011_guards'))
			victimNonDeadly = true;
		else
			victimNonDeadly = victimInv.ItemHasTag(victimWeaponId, 'Wooden') || victimInv.ItemHasTag(victimWeaponId, 'Fists') && !victimInv.ItemHasTag(victimWeaponId, 'MagicWeaponFX');
		
		return attackerNonDeadly && victimNonDeadly;
	}
	
	private function CheckMutation8Finisher()
	{
		//if(((W3PlayerWitcher)playerAttacker) && ((W3PlayerWitcher)playerAttacker).IsMutationActive(EPMT_Mutation8) && ((W3PlayerWitcher)playerAttacker).HasRecentlyCountered() && ((CNewNPC)actorVictim) && !((CNewNPC)actorVictim).IsImmuneToMutation8Finisher())
		if(action.GetBuffSourceName() != "Finisher" && action.GetBuffSourceName() != "AutoFinisher" && attackAction && attackAction.IsActionMelee() && ((W3PlayerWitcher)playerAttacker) && ((W3PlayerWitcher)playerAttacker).IsMutationActive(EPMT_Mutation8) && actorVictim.WasCountered() && ((CNewNPC)actorVictim) && !((CNewNPC)actorVictim).IsImmuneToMutation8Finisher())
		{
			mutation8Triggered = true;
		}
		else
		{
			mutation8Triggered = false;
		}
	}
	
	private function CleanupMutation8Finisher()
	{
		mutation8Triggered = false;
	}
	//modSigns end
	
	
	
	
	
	
	private function ProcessActionQuest(act : W3DamageAction)
	{
		var victimTags, attackerTags : array<name>;
		
		victimTags = action.victim.GetTags();
		
		if(action.attacker)
			attackerTags = action.attacker.GetTags();
		
		AddHitFacts( victimTags, attackerTags, "_weapon_hit" );
		
		
		if ((CGameplayEntity) action.victim) action.victim.OnWeaponHit(act);
	}
	
	
	
	
	
	private function ProcessActionDamage() : bool
	{
		var directDmgIndex, size, i : int;
		var dmgInfos : array< SRawDamage >;
		var immortalityMode : EActorImmortalityMode;
		var dmgValue : float;
		var anyDamageProcessed, fallingRaffard : bool;
		var /*victimHealthPercBeforeHit,*/ frozenAdditionalDamage : float;		
		var powerMod : SAbilityAttributeValue;
		var witcher : W3PlayerWitcher;
		var canLog : bool;
		var immortalityChannels : array<EActorImmortalityChanel>;
		var min, max : SAbilityAttributeValue; //modSigns
		var difficultyDamageMultiplier : float; //modSigns
		
		//modSigns: logic rewritten for clarity
		if(!actorVictim || (!actorVictim.UsesVitality() && !actorVictim.UsesEssence()))
		{
			if(action.GetDamageValue(theGame.params.DAMAGE_NAME_FIRE) > 0)
				action.victim.OnFireHit((CGameplayEntity)action.causer);
			
			if(!actorVictim.abilityManager)
				actorVictim.OnDeath(action);
			
			return false;
		}
		
		canLog = theGame.CanLog();
		
		//if(actorVictim.UsesVitality())
		//	victimHealthPercBeforeHit = actorVictim.GetStatPercents(BCS_Vitality);
		//else
		//	victimHealthPercBeforeHit = actorVictim.GetStatPercents(BCS_Essence);
		//modSigns: made global and moved to init
				
		if ( canLog )
		{
			LogBeginning();
		}
			
		ProcessDamageIncrease(); //modSigns: modified
		
		ProcessDamageDecrease(); //modSigns
		
		action.SetAllProcessedDamageAs(0);
		size = action.GetDTs( dmgInfos );
		action.SetDealtFireDamage(false);		
		
		ProcessCriticalHitCheck();
		
		
		ProcessOnBeforeHitChecks();
		
		
		powerMod = GetAttackersPowerMod();

		
		anyDamageProcessed = false;
		directDmgIndex = -1;
		witcher = GetWitcherPlayer();
		size = dmgInfos.Size();			
		for( i = 0; i < size; i += 1 )
		{
			//debug log
			//theGame.witcherLog.AddMessage( "Damage #" + i + ": type = " + dmgInfos[i].dmgType );
			//theGame.witcherLog.AddMessage( "Damage #" + i + ": value = " + dmgInfos[i].dmgVal );
			
			if(dmgInfos[i].dmgVal == 0)
				continue;
			
			if(dmgInfos[i].dmgType == theGame.params.DAMAGE_NAME_DIRECT)
			{
				directDmgIndex = i;
				continue;
			}
			
			//modSigns: Viper Set bonus added
			if(dmgInfos[i].dmgType == theGame.params.DAMAGE_NAME_POISON && witcher == actorVictim)
			{
				dmgValue = dmgInfos[i].dmgVal;
				//if(witcher.HasBuff(EET_GoldenOriole) && witcher.GetPotionBuffLevel(EET_GoldenOriole) == 3)
				//{
				//	witcher.GainStat(BCS_Vitality, dmgValue);
				//	if ( canLog )
				//	{
				//		LogDMHits("", action);
				//		LogDMHits("*** Player absorbs poison damage from level 3 Golden Oriole potion: " + dmgValue, action);
				//	}
				//	//dmgInfos[i].dmgVal = 0; //no immunity
				//} //no healing from GoldenOriole
				if(witcher.IsSetBonusActive(EISB_Viper))
				{
					theGame.GetDefinitionsManager().GetAbilityAttributeValue( 'setBonusAbilityViper_1', 'per_viper_piece_poison_healing_rate', min, max );
					witcher.GainStat(BCS_Vitality, dmgValue * CalculateAttributeValue(min) * witcher.GetSetPartsEquipped( EIST_Viper ));
					if ( canLog )
					{
						LogDMHits("", action);
						LogDMHits("*** Player absorbs poison damage from Viper Set ability: " + (dmgValue * CalculateAttributeValue(min) * witcher.GetSetPartsEquipped( EIST_Viper )), action);
					}
					dmgInfos[i].dmgVal = 0;
				}
				if(dmgInfos[i].dmgVal == 0.f)
					continue;
			}
			
			
			if ( canLog )
			{
				LogDMHits("", action);
				LogDMHits("*** Incoming " + NoTrailZeros(dmgInfos[i].dmgVal) + " " + dmgInfos[i].dmgType + " damage", action);
				if(action.IsDoTDamage())
					LogDMHits("DoT's current dt = " + NoTrailZeros(action.GetDoTdt()) + ", estimated dps = " + NoTrailZeros(dmgInfos[i].dmgVal / action.GetDoTdt()), action);
			}
			
			
			anyDamageProcessed = true;
				
			
			dmgValue = MaxF(0, CalculateDamage(dmgInfos[i], powerMod));
		
			
			if( DamageHitsEssence(  dmgInfos[i].dmgType ) )		action.processedDmg.essenceDamage  += dmgValue;
			if( DamageHitsVitality( dmgInfos[i].dmgType ) )		action.processedDmg.vitalityDamage += dmgValue;
			if( DamageHitsMorale(   dmgInfos[i].dmgType ) )		action.processedDmg.moraleDamage   += dmgValue;
			if( DamageHitsStamina(  dmgInfos[i].dmgType ) )		action.processedDmg.staminaDamage  += dmgValue;
		}
		
		if(size == 0 && canLog)
		{
			LogDMHits("*** There is no incoming damage set (probably only buffs).", action);
		}
		
		if ( canLog )
		{
			LogDMHits("", action);
			LogDMHits("Processing block, parry, immortality, signs and other GLOBAL damage reductions...", action);		
		}
		
		
		if(actorVictim)
			actorVictim.ReduceDamage(action);
		
		ProcessDamageModification(); //modSigns
		
		if(directDmgIndex != -1)
		{
			anyDamageProcessed = true;
			
			
			immortalityChannels = actorVictim.GetImmortalityModeChannels(AIM_Invulnerable);
			fallingRaffard = immortalityChannels.Size() == 1 && immortalityChannels.Contains(AIC_WhiteRaffardsPotion) && action.GetBuffSourceName() == "FallingDamage";
			
			if(action.GetIgnoreImmortalityMode() || (!actorVictim.IsImmortal() && !actorVictim.IsInvulnerable() && !actorVictim.IsKnockedUnconscious()) || fallingRaffard)
			{
				action.processedDmg.vitalityDamage += dmgInfos[directDmgIndex].dmgVal;
				action.processedDmg.essenceDamage  += dmgInfos[directDmgIndex].dmgVal;
			}
			else if( actorVictim.IsInvulnerable() )
			{
				
			}
			else if( actorVictim.IsImmortal() )
			{
				
				action.processedDmg.vitalityDamage += MinF(dmgInfos[directDmgIndex].dmgVal, actorVictim.GetStat(BCS_Vitality)-1 );
				action.processedDmg.essenceDamage  += MinF(dmgInfos[directDmgIndex].dmgVal, actorVictim.GetStat(BCS_Essence)-1 );
			}
		}
		
		
		if( actorVictim.HasAbility( 'OneShotImmune' ) )
		{
			if( action.processedDmg.vitalityDamage >= actorVictim.GetStatMax( BCS_Vitality ) )
			{
				action.processedDmg.vitalityDamage = actorVictim.GetStatMax( BCS_Vitality ) - 1;
			}
			else if( action.processedDmg.essenceDamage >= actorVictim.GetStatMax( BCS_Essence ) )
			{
				action.processedDmg.essenceDamage = actorVictim.GetStatMax( BCS_Essence ) - 1;
			}
		}
		
		
		if(action.HasDealtFireDamage())
			action.victim.OnFireHit( (CGameplayEntity)action.causer );
			
		
		ProcessInstantKill();
			
		
		ProcessActionDamage_DealDamage();
		
		
		//if(playerAttacker && witcher)
		//	witcher.SetRecentlyCountered(false); //modSigns: moved
		
		
		if( attackAction && !attackAction.IsCountered() && playerVictim && attackAction.IsActionMelee())
			theGame.GetGamerProfile().ResetStat(ES_CounterattackChain);
		
		
		ProcessActionDamage_ReduceDurability();
		
		
		if(playerAttacker && actorVictim)
		{
			
			//modSigns: moved to ReduceAllOilsAmmo
			//if(playerAttacker.inv.ItemHasAnyActiveOilApplied(weaponId) && (!playerAttacker.CanUseSkill(S_Alchemy_s06) || (playerAttacker.GetSkillLevel(S_Alchemy_s06) < 3)) )
			//{			
				playerAttacker.ReduceAllOilsAmmo( weaponId );
				
			//	if(ShouldProcessTutorial('TutorialOilAmmo'))
			//	{
			//		FactsAdd("tut_used_oil_in_combat");
			//	}
			//}
			
			
			playerAttacker.inv.ReduceItemRepairObjectBonusCharge(weaponId);
		}
		
		
		if(actorVictim && actorAttacker && !action.GetCannotReturnDamage() )
			ProcessActionReturnedDamage();	
		
		return anyDamageProcessed;
	}
	
	
	private function ProcessInstantKill()
	{
		var instantKill, focus : float;
		
		if( (W3MonsterHuntNPC)actorVictim ) //modSigns: no instant kill for monster hunt monsters
		{
			return;
		}
		
		if( !actorVictim || !actorAttacker || actorVictim.IsImmuneToInstantKill() )
		{
			return;
		}
		
		
		if( action.WasDodged() || ( attackAction && ( attackAction.IsParried() || attackAction.IsCountered() ) ) )
		{
			return;
		}
		
		if( actorAttacker.HasAbility( 'ForceInstantKill' ) && actorVictim != thePlayer )
		{
			action.SetInstantKill();
		}
		
		
		//modSigns: cooldown removed, whirl has zero instant kill chance
		if( actorAttacker == thePlayer /*&& !action.GetIgnoreInstantKillCooldown()*/ )
		{
			//if( !GameTimeDTAtLeastRealSecs( thePlayer.lastInstantKillTime, theGame.GetGameTime(), theGame.params.INSTANT_KILL_INTERNAL_PLAYER_COOLDOWN ) )
			if((W3PlayerWitcher)playerAttacker && thePlayer.IsDoingSpecialAttack(false))
			{
				//combat log
				//theGame.witcherLog.AddCombatMessage("Whirl has zero instant kill chance", actorAttacker, actorVictim);
				return;
			}
		}
	
		
		if( !action.GetInstantKill() )
		{
			
			instantKill = CalculateAttributeValue( actorAttacker.GetInventory().GetItemAttributeValue( weaponId, 'instant_kill_chance' ) );
			
			
			//modSigns: Deadly Precision instant kill is now only triggered on counters
			//if( (W3PlayerWitcher)playerAttacker && action.IsActionMelee() && action.DealsAnyDamage() && thePlayer.CanUseSkill( S_Sword_s03 ) && !playerAttacker.inv.IsItemFists( weaponId ) && ((W3PlayerWitcher)playerAttacker).HasRecentlyCountered() )
			if( (W3PlayerWitcher)playerAttacker && action.IsActionMelee() && action.DealsAnyDamage() && thePlayer.CanUseSkill( S_Sword_s03 ) && !playerAttacker.inv.IsItemFists( weaponId ) && actorVictim && actorVictim.WasCountered() )
			{
				focus = thePlayer.GetStat( BCS_Focus );
				
				if( focus >= 1 )
				{
					instantKill += focus * CalculateAttributeValue( thePlayer.GetSkillAttributeValue( S_Sword_s03, 'instant_kill_chance', false, true ) ) * thePlayer.GetSkillLevel( S_Sword_s03 );
				}
			}
		}
		
		
		//modSigns: debug
		//theGame.witcherLog.AddMessage("Instant kill chance: " + instantKill);

		if( action.GetInstantKill() || ( RandF() < instantKill ) )
		{
			if( theGame.CanLog() )
			{
				if( action.GetInstantKill() )
				{
					instantKill = 1.f;
				}
				LogDMHits( "Instant kill!! (" + NoTrailZeros( instantKill * 100 ) + "% chance", action );
			}
			
			//modSigns: prevent explode on death ability from killing the player
			//when instant kill ability is activated
			if( actorVictim && actorVictim.HasAbility( 'LastBreath' ) && !action.GetWasFrozen() )
			{
				if( actorVictim.UsesVitality() )
					action.processedDmg.vitalityDamage = GetLastBreathMaxAllowedDamage();
				else
					action.processedDmg.essenceDamage = GetLastBreathMaxAllowedDamage();
			}
			else
			{
				action.processedDmg.vitalityDamage /*+*/= actorVictim.GetStat( BCS_Vitality );
				action.processedDmg.essenceDamage /*+*/= actorVictim.GetStat( BCS_Essence );
			}
			action.SetCriticalHit();
			action.SetInstantKillFloater();
			
			if( playerAttacker )
			{
				thePlayer.SetLastInstantKillTime( theGame.GetGameTime() );
				theSound.SoundEvent( 'cmb_play_deadly_hit' );
				theGame.SetTimeScale( 0.2, theGame.GetTimescaleSource( ETS_InstantKill ), theGame.GetTimescalePriority( ETS_InstantKill ), true, true );
				thePlayer.AddTimer( 'RemoveInstantKillSloMo', 0.2 );
			}			
		}
	}
	
	//modSigns: instant kill for enemies with last breath ability
	private function GetLastBreathMaxAllowedDamage() : float
	{
		return MaxF( 0, actorVictim.GetHealth() - actorVictim.GetMaxHealth() * CalculateAttributeValue( actorVictim.GetAttributeValue('lastbreath_threshold') ) );
	}
	
	
	private function ProcessOnBeforeHitChecks()
	{
		var effectAbilityName/*, monsterBonusType*/ : name;
		var effectType : EEffectType;
		//var null, monsterBonusVal : SAbilityAttributeValue;
		var /*oilLevel, skillLevel,*/ i : int;
		var /*baseChance, perOilLevelChance,*/ chance : float;
		var buffs : array<name>;
		var resPt, resPrc : float; //modSigns
	
		if( weaponsAreNotDeadly ) //modSigns
			return;
		
		if( playerAttacker && actorVictim && attackAction && attackAction.IsActionMelee() && playerAttacker.CanUseSkill(S_Alchemy_s12) /*&& playerAttacker.inv.ItemHasActiveOilApplied( weaponId, victimMonsterCategory )*/ )
		{
			
			//monsterBonusType = MonsterCategoryToAttackPowerBonus(victimMonsterCategory);
			//monsterBonusVal = playerAttacker.inv.GetItemAttributeValue(weaponId, monsterBonusType);
		    //
			//if(monsterBonusVal != null)
			//{
				
				//oilLevel = (int)CalculateAttributeValue(playerAttacker.inv.GetItemAttributeValue(weaponId, 'level')) - 1;				
				//skillLevel = playerAttacker.GetSkillLevel(S_Alchemy_s12);
				//baseChance = CalculateAttributeValue(playerAttacker.GetSkillAttributeValue(S_Alchemy_s12, 'skill_chance', false, true));
				//perOilLevelChance = CalculateAttributeValue(playerAttacker.GetSkillAttributeValue(S_Alchemy_s12, 'oil_level_chance', false, true));						
				//chance = baseChance * skillLevel + perOilLevelChance * oilLevel;
				//modSigns: get chance
				chance = playerAttacker.inv.GetOilPoisonChanceAgainstMonster(weaponId, victimMonsterCategory);
				//modSigns: check resistance
				actorVictim.GetResistValue(theGame.effectMgr.GetBuffResistStat(EET_Poison), resPt, resPrc);
				chance = MaxF(0, chance * (1 - resPrc));
				//Metamorphosis new bonus
				if(((W3PlayerWitcher)playerAttacker).IsMutationActive(EPMT_Mutation12))
					chance *= MaxF(1.0f, 1.0f + ((W3PlayerWitcher)playerAttacker).Mutation12GetBonus());
				
				if(chance > 0 && RandF() < chance)
				{
					
					dm.GetContainedAbilities(playerAttacker.GetSkillAbilityName(S_Alchemy_s12), buffs);
					for(i=0; i<buffs.Size(); i+=1)
					{
						EffectNameToType(buffs[i], effectType, effectAbilityName);
						action.AddEffectInfo(effectType, , , effectAbilityName);
					}
				}
			//}
		}
		//modSigns: rend knockdown
		if((W3PlayerWitcher)playerAttacker && attackAction && SkillNameToEnum(attackAction.GetAttackTypeName()) == S_Sword_s02)
		{
			action.AddEffectInfo(EET_KnockdownTypeApplicator);
		}
	}
	
	
	private function ProcessCriticalHitCheck()
	{
		var critChance/*, critDamageBonus*/ : float;
		var	canLog, meleeOrRanged, redWolfSet, isLightAttack, isHeavyAttack, mutation2 : bool;
		var arrStr : array<string>;
		//var samum : CBaseGameplayEffect;
		var signPower, min, max : SAbilityAttributeValue;
		var aerondight : W3Effect_Aerondight;
		var blindnessCrit, confusionCrit : float; //modSigns
		
		if( action.IsDoTDamage() ) //modSigns: no crits for DoT as DoT doesn't have buffs anyway
			return;
		
		if( weaponsAreNotDeadly ) //modSigns: no critst for non-deadly fights
			return;
		
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
					//modSigns: changing the formula
					critChance = min.valueAdditive + SignPowerStatToPowerBonus(signPower.valueMultiplicative) * min.valueMultiplicative;
				}
			} 			
			else
			{
				if( attackAction )
				{
					
					if( SkillEnumToName(S_Sword_s02) == attackAction.GetAttackTypeName() )
					{				
						critChance += CalculateAttributeValue(playerAttacker.GetSkillAttributeValue(S_Sword_s02, theGame.params.CRITICAL_HIT_CHANCE, false, true)) * playerAttacker.GetSkillLevel(S_Sword_s02);
					}
					
					
					//if( action.IsActionMelee() && GetWitcherPlayer() && GetWitcherPlayer().HasRecentlyCountered() ) //modSigns: exclude ranged
					if( action.IsActionMelee() && (W3PlayerWitcher)playerAttacker && actorVictim && actorVictim.WasCountered() ) //modSigns: exclude ranged
					{
						critChance += 0.25; //25% crit chance for countering
						if( playerAttacker.CanUseSkill(S_Sword_s11) && playerAttacker.GetSkillLevel(S_Sword_s11) > 1 ) //modSigns
							critChance += CalculateAttributeValue(playerAttacker.GetSkillAttributeValue(S_Sword_s11, theGame.params.CRITICAL_HIT_CHANCE, false, true))*(playerAttacker.GetSkillLevel(S_Sword_s11) - 1);
						//theGame.witcherLog.AddMessage("+crit chance for countering");
					}
					
					
					isLightAttack = playerAttacker.IsLightAttack( attackAction.GetAttackName() );
					isHeavyAttack = playerAttacker.IsHeavyAttack( attackAction.GetAttackName() );
					critChance += playerAttacker.GetCriticalHitChance(isLightAttack, isHeavyAttack, actorVictim, victimMonsterCategory, (W3BoltProjectile)action.causer );
					
					
					if(action.GetIsHeadShot())
					{
						critChance += theGame.params.HEAD_SHOT_CRIT_CHANCE_BONUS;
						//actorVictim.SignalGameplayEvent( 'Headshot' ); //modSigns: moved to more logical place
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
							//modSigns: fully charged Aerondight has 100% crit chance
							critChance = 1.0;
							//min = playerAttacker.GetAbilityAttributeValue( 'AerondightEffect', 'crit_chance_bonus' );
							//critChance += min.valueAdditive;
						}
					}
				}
				else
				{
					
					critChance += playerAttacker.GetCriticalHitChance(false, false, actorVictim, victimMonsterCategory, (W3BoltProjectile)action.causer );
				}
				
				//samum = actorVictim.GetBuff(EET_Blindness, 'petard');
				//if(samum && samum.GetBuffLevel() == 3)
				//{
				//	critChance += 1.0f;
				//}
				
				//modSigns: crit bonuses for all the blindness effects
				if(actorVictim.HasBuff(EET_Blindness))
				{
					blindnessCrit = ((W3BlindnessEffect)actorVictim.GetBuff(EET_Blindness)).GetCritChanceBonus();
					//theGame.witcherLog.AddMessage("Blindness crit: " + blindnessCrit);
				}
				
				//modSigns: crit bonuses for all the confusion effects
				if(actorVictim.HasBuff(EET_Confusion))
				{
					confusionCrit = ((W3ConfuseEffect)actorVictim.GetBuff(EET_Confusion)).GetCriticalHitChanceBonus();
					//theGame.witcherLog.AddMessage("Confusion crit: " + confusionCrit);
				}
				
				//modSigns: only one of the bonuses can be active at a time
				if(blindnessCrit || confusionCrit)
				{
					critChance += MaxF(blindnessCrit, confusionCrit);
					//theGame.witcherLog.AddMessage("Crit bonus: " + MaxF(blindnessCrit, confusionCrit));
				}
				
				//modSigns: bonus chance from RedWolf set
				if(redWolfSet)
				{
					theGame.GetDefinitionsManager().GetAbilityAttributeValue( GetSetBonusAbility( EISB_RedWolf_1 ), 'per_redwolf_piece_crit_chance_bonus', min, max );
					min.valueAdditive *= GetWitcherPlayer().GetSetPartsEquipped( EIST_RedWolf );
					critChance += CalculateAttributeValue( min );
				}
			}
			
			//modSigns: debug
			if( FactsQuerySum( "modSigns_debug_dmg" ) > 0 )
			{
				if(!(action.IsDoTDamage() && (CBaseGameplayEffect)action.causer))
				{
					theGame.witcherLog.AddMessage("Dmg manager:");
					theGame.witcherLog.AddMessage("Attacker: " + actorAttacker.GetDisplayName());
					theGame.witcherLog.AddMessage("Victim: " + actorVictim.GetDisplayName());
					theGame.witcherLog.AddMessage("Critical hit chance prc: " + NoTrailZeros(critChance * 100));
				}
			}
			
			/*if ( canLog )
			{
				
				critDamageBonus = 1 + CalculateAttributeValue(actorAttacker.GetCriticalHitDamageBonus(weaponId, victimMonsterCategory, actorVictim.IsAttackerAtBack(playerAttacker)));
				//critDamageBonus += CalculateAttributeValue(actorAttacker.GetAttributeValue('critical_hit_chance_fast_style')); //modSigns
				critDamageBonus = 100 * critDamageBonus;
				
				
				LogDMHits("", action);				
				LogDMHits("Trying critical hit (" + NoTrailZeros(critChance*100) + "% chance, dealing " + NoTrailZeros(critDamageBonus) + "% damage)...", action);
			}*/
			
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
	
	
	private function LogBeginning()
	{
		var logStr : string;
		
		if ( !theGame.CanLog() )
		{
			return;
		}
		
		LogDMHits("-----------------------------------------------------------------------------------", action);		
		logStr = "Beginning hit processing from <<" + action.attacker + ">> to <<" + action.victim + ">> via <<" + action.causer + ">>";
		if(attackAction)
		{
			logStr += " using AttackType <<" + attackAction.GetAttackTypeName() + ">>";		
		}
		logStr += ":";
		LogDMHits(logStr, action);
		LogDMHits("", action);
		LogDMHits("Target stats before damage dealt are:", action);
		if(actorVictim)
		{
			if( actorVictim.UsesVitality() )
				LogDMHits("Vitality = " + NoTrailZeros(actorVictim.GetStat(BCS_Vitality)), action);
			if( actorVictim.UsesEssence() )
				LogDMHits("Essence = " + NoTrailZeros(actorVictim.GetStat(BCS_Essence)), action);
			if( actorVictim.GetStatMax(BCS_Stamina) > 0)
				LogDMHits("Stamina = " + NoTrailZeros(actorVictim.GetStat(BCS_Stamina, true)), action);
			if( actorVictim.GetStatMax(BCS_Morale) > 0)
				LogDMHits("Morale = " + NoTrailZeros(actorVictim.GetStat(BCS_Morale)), action);
		}
		else
		{
			LogDMHits("Undefined - victim is not a CActor and therefore has no stats", action);
		}
	}
	
	//modSigns: reworked
	private function ProcessDamageIncrease()
	{
		//var overheal, focusCost : float;
		var i, bonusCount : int;
		var frozenBuff : W3Effect_Frozen;
		var frozenDmgInfo, bonusDmgInfo : SRawDamage;
		var forceDamageIdx, bonusDamageIdx : int;
		var bonusDamagePercents, bonusDamagePoints : float;
		var mpac : CMovingPhysicalAgentComponent;
		var perk20Bonus : SAbilityAttributeValue;
		var witcherAttacker : W3PlayerWitcher;
		var damageVal, damageBonus, min, max, sp : SAbilityAttributeValue;		
		var npcVictim : CNewNPC;
		var sword : SItemUniqueId;
		var actionFreeze : W3DamageAction;
		var dmgBonusMult : float;
		var addForceDamage : bool;
		var mutagen : CBaseGameplayEffect;
		var dmgInfos : array< SRawDamage >;
		
		if( !thePlayer.IsFistFightMinigameEnabled() && weaponsAreNotDeadly ) //modSigns
			return;
		
		action.GetDTs(dmgInfos);
		witcherAttacker = (W3PlayerWitcher)playerAttacker;
		npcVictim = (CNewNPC)actorVictim;
		
		//moved here from actor.ReduceDamage
		if(action.IsActionMelee() && actorVictim && actorVictim.HasAbility( 'VulnerableFromFront' ) && actorAttacker && !actorVictim.IsAttackerAtBack(actorAttacker) )
		{
			action.SetIgnoreArmor( true );
		}
		
		dmgBonusMult = 0; //remove damage stacking, make all multipliers additive instead
		addForceDamage = false; //for frozen effect damage
		
		//fist damage bonus
		if( actorAttacker && attackAction && attackAction.IsActionMelee() && actorAttacker.IsWeaponHeld( 'fist' ) )
		{
			bonusDamagePoints = CalculateAttributeValue(actorAttacker.GetAttributeValue( 'fist_dmg_bonus' ));
			bonusDamageIdx = -1;
			for( i = 0 ; i < dmgInfos.Size() ; i += 1 )
			{
				if( dmgInfos[i].dmgType == theGame.params.DAMAGE_NAME_BLUDGEONING )
				{
					dmgInfos[i].dmgVal += bonusDamagePoints;
					bonusDamageIdx = i;
				}
			}
			if( bonusDamageIdx == -1 )
			{
				bonusDmgInfo.dmgVal = bonusDamagePoints;
				bonusDmgInfo.dmgType = theGame.params.DAMAGE_NAME_BLUDGEONING;
				dmgInfos.PushBack( bonusDmgInfo );
			}
			//theGame.witcherLog.AddMessage("fist_dmg_bonus = " + CalculateAttributeValue(actorAttacker.GetAttributeValue( 'fist_dmg_bonus' )));
		}
		
		//underwater crossbow damage boost
		if(actorVictim)
		{
			mpac = (CMovingPhysicalAgentComponent)actorVictim.GetMovingAgentComponent();
			if(mpac && mpac.IsDiving())
			{
				mpac = (CMovingPhysicalAgentComponent)actorAttacker.GetMovingAgentComponent();	
				if(mpac && mpac.IsDiving())
				{
					action.SetUnderwaterDisplayDamageHack();
					if(playerAttacker && attackAction && attackAction.IsActionRanged())
					{
						for(i=0; i<dmgInfos.Size(); i+=1)
						{
							if(FactsQuerySum("NewGamePlus"))
							{
								dmgInfos[i].dmgVal *= (1 + theGame.params.UNDERWATER_CROSSBOW_DAMAGE_BONUS_NGP);
							}
							else
							{
								dmgInfos[i].dmgVal *= (1 + theGame.params.UNDERWATER_CROSSBOW_DAMAGE_BONUS);
							}
						}
					}
				}
			}
		}
		
		//crossbow base damage boost
		if ( playerAttacker && action.IsActionRanged() && !action.IsDoTDamage() )
		{
			if ( ((W3BoltProjectile)action.causer) && GetWitcherPlayer().CanUseSkill(S_Sword_s15) )
			{
				damageVal.valueMultiplicative = 0;
				damageVal.valueAdditive = 0;
				damageVal.valueBase = CalculateAttributeValue(GetWitcherPlayer().GetSkillAttributeValue(S_Sword_s15, 'xbow_dmg_bonus', false, true)) * GetWitcherPlayer().GetSkillLevel(S_Sword_s15);
				for( i = 0 ; i < dmgInfos.Size() ; i += 1 )
				{
					dmgInfos[i].dmgVal += damageVal.valueBase;
				}
			}
		}
		
		//mutation 1 base sign damage boost
		if( playerAttacker && action.IsActionWitcherSign() && GetWitcherPlayer().IsMutationActive( EPMT_Mutation1 ) )
		{
			sword = playerAttacker.inv.GetCurrentlyHeldSword();
			damageVal.valueBase = 0;
			damageVal.valueMultiplicative = 0;
			damageVal.valueAdditive = 0;
			if( playerAttacker.inv.GetItemCategory(sword) == 'steelsword' )
			{
				//damageVal += playerAttacker.inv.GetItemAttributeValue(sword, theGame.params.DAMAGE_NAME_SLASHING);
				damageVal.valueBase += GetWitcherPlayer().GetTotalWeaponDamage(sword, theGame.params.DAMAGE_NAME_SLASHING, GetInvalidUniqueId());
			}
			else if( playerAttacker.inv.GetItemCategory(sword) == 'silversword' )
			{
				//damageVal += playerAttacker.inv.GetItemAttributeValue(sword, theGame.params.DAMAGE_NAME_SILVER);
				damageVal.valueBase += GetWitcherPlayer().GetTotalWeaponDamage(sword, theGame.params.DAMAGE_NAME_SILVER, GetInvalidUniqueId());
			}
			theGame.GetDefinitionsManager().GetAbilityAttributeValue('Mutation1', 'dmg_bonus_factor', min, max);				
			damageVal.valueBase *= CalculateAttributeValue(min);
			if( action.IsDoTDamage() )
			{
				damageVal.valueBase *= action.GetDoTdt();
			}
			for( i = 0 ; i < dmgInfos.Size() ; i+=1)
			{
				dmgInfos[i].dmgVal += damageVal.valueBase;
			}
			//debug log
			//theGame.witcherLog.AddMessage("Mutation1 active. Bonus dmg: " + damageVal.valueBase);
		}
		
		//Rotation damage buff
		if( playerAttacker && action.IsActionWitcherSign() && action.GetSignType() == ST_Igni && !action.IsDoTDamage() && GetWitcherPlayer().HasGlyphwordActive('Glyphword 7 _Stats') )
		{
			theGame.GetDefinitionsManager().GetAbilityAttributeValue('Glyphword 7 _Stats', 'glyphword7_dmg_buff', min, max);
			damageVal.valueMultiplicative = 0;
			damageVal.valueAdditive = 0;
			damageVal.valueBase = CalculateAttributeValue(min);
			for( i = 0 ; i < dmgInfos.Size() ; i += 1 )
			{
				dmgInfos[i].dmgVal += damageVal.valueBase;
			}
			//theGame.witcherLog.AddMessage("Rotation bonus dmg: " + damageVal.valueBase);
		}
		
		//new mutagen09 bonus
		if( playerAttacker && action.IsActionWitcherSign() && playerAttacker.HasBuff(EET_Mutagen09) )
		{
			damageVal.valueMultiplicative = 0;
			damageVal.valueAdditive = 0;
			damageVal.valueBase = ((W3Mutagen09_Effect)playerAttacker.GetBuff(EET_Mutagen09)).GetM09Bonus();
			if( action.IsDoTDamage() )
				damageVal.valueBase *= action.GetDoTdt();
			for( i = 0 ; i < dmgInfos.Size() ; i += 1)
				dmgInfos[i].dmgVal += damageVal.valueBase;
			//theGame.witcherLog.AddMessage("Mutagen09 bonus dmg: " + damageVal.valueBase);
		}
		
		//mutation 9 base damage boost
		if( playerAttacker && attackAction && attackAction.IsActionRanged() && ((W3BoltProjectile)action.causer) && !action.IsDoTDamage() && GetWitcherPlayer().IsMutationActive( EPMT_Mutation9 ) )
		{
			theGame.GetDefinitionsManager().GetAbilityAttributeValue('Mutation9', 'mut9_damage', min, max);
			for( i = 0; i < dmgInfos.Size(); i += 1 )
				dmgInfos[i].dmgVal *= 1 + min.valueMultiplicative;
		}
		
		//mutation 10 base sign/sword damage boost
		if( playerAttacker && (action.IsActionMelee() || action.IsActionWitcherSign()) && GetWitcherPlayer().IsMutationActive( EPMT_Mutation10 ) && GetWitcherPlayer().HasBuff(EET_Mutation10) )
		{
			damageVal.valueBase = 0;
			damageVal.valueMultiplicative = 0;
			damageVal.valueAdditive = 0;
			damageVal.valueBase += GetWitcherPlayer().GetToxicityDamage();
			if( action.IsDoTDamage() )
			{
				damageVal.valueBase *= action.GetDoTdt();
			}
			for( i = 0 ; i < dmgInfos.Size() ; i+=1)
			{
				dmgInfos[i].dmgVal += damageVal.valueBase;
			}
			//debug log
			//theGame.witcherLog.AddMessage("Mutation10 active. Bonus dmg: " + damageVal.valueBase);
		}
		
		//bounced arrows damage increase
		if( (W3PlayerWitcher)playerAttacker && action.IsActionRanged() && action.IsBouncedArrow() )
		{
			damageVal = actorVictim.GetPowerStatValue(CPS_AttackPower);
			//debug log
			//theGame.witcherLog.AddMessage("victim's bonus dmg: " + damageVal.valueBase);
			for( i = 0 ; i < dmgInfos.Size() ; i += 1 )
			{
				dmgInfos[i].dmgVal += damageVal.valueBase;
			}
			//new deflect mechanic
			if( thePlayer.CanUseSkill(S_Sword_s10) && thePlayer.GetSkillLevel(S_Sword_s10) >= 2 )
			{
				dmgBonusMult += CalculateAttributeValue( thePlayer.GetSkillAttributeValue(S_Sword_s10, 'damage_increase', false, true) ) * (thePlayer.GetSkillLevel(S_Sword_s10) - 1);
			}
		}
		
		//damage increase for heavy attack
		if( actorAttacker && attackAction && actorAttacker.IsHeavyAttack(attackAction.GetAttackName()) )
		{
			if( playerAttacker == GetWitcherPlayer() ) //for the player
			{
				damageBonus = GetWitcherPlayer().GetSkillAttributeValue(S_Sword_2, 'heavy_attack_dmg_boost', false, true);
				dmgBonusMult += damageBonus.valueMultiplicative;
			}
			else
			{
				dmgBonusMult += 0.25; //for npcs
			}
		}
		
		//weapon/sign dmg bonuses
		if(witcherAttacker)
		{
			if(action.IsActionMelee())
				dmgBonusMult += CalculateAttributeValue(witcherAttacker.GetAttributeValue( 'sword_dmg_bonus' ));
			if(action.IsActionWitcherSign())
				dmgBonusMult += CalculateAttributeValue(witcherAttacker.GetAttributeValue( 'spell_dmg_bonus' ));
		}
		
		//Rend dmg boost
		if(witcherAttacker && attackAction && SkillNameToEnum(attackAction.GetAttackTypeName()) == S_Sword_s02)
		{
			dmgBonusMult += witcherAttacker.GetRendPowerBonus();
		}
		
		//heft damage boost
		if(witcherAttacker && witcherAttacker.HasGlyphwordActive('Glyphword 4 _Stats') && action.IsActionMelee() && !witcherAttacker.IsDoingSpecialAttack(true) && !witcherAttacker.IsDoingSpecialAttack(false))
		{
			theGame.GetDefinitionsManager().GetAbilityAttributeValue('Glyphword 4 _Stats', 'glyphword4_mod', min, max);
			dmgBonusMult += CalculateAttributeValue(min);
			//theGame.witcherLog.AddMessage("heft dmg boost = " + CalculateAttributeValue(min));
		}
		
		if ( playerAttacker && action.IsActionRanged() && !action.IsDoTDamage() ) //modSigns: exclude DoTs
		{
			//perk20 petards damage boost
			if ( ((W3Petard)action.causer) && GetWitcherPlayer().CanUseSkill(S_Perk_20) )
			{
				perk20Bonus = GetWitcherPlayer().GetSkillAttributeValue( S_Perk_20, 'dmg_multiplier', false, false);
				dmgBonusMult += perk20Bonus.valueMultiplicative;
			}
		}
		
		//mutation 8 damage boost -> changed
		//if( playerAttacker && npcVictim && attackAction && action.IsActionMelee() && GetWitcherPlayer().IsMutationActive( EPMT_Mutation8 ) && ( victimMonsterCategory != MC_Human || npcVictim.IsImmuneToMutation8Finisher() ) && attackAction.GetWeaponId() == GetWitcherPlayer().GetHeldSword() )
		//{
		//	dm.GetAbilityAttributeValue( 'Mutation8', 'dmg_bonus', min, max );
		//	dmgBonusMult += min.valueMultiplicative;
		//}
		
		//frozen effect damage boost
		if(actorVictim && playerAttacker && !action.IsDoTDamage() && actorVictim.HasBuff(EET_Frozen) && ((W3AardProjectile)action.causer || (W3AardEntity)action.causer || action.DealsPhysicalOrSilverDamage()))
		{
			frozenBuff = (W3Effect_Frozen)actorVictim.GetBuff(EET_Frozen);
			//remove knockdown, make it to multiply the damage instead and fix the bug with wrong ability names
			dm.GetAbilityAttributeValue(frozenBuff.GetAbilityName(), 'hpPercDamageBonusPerHit', min, max);
			bonusDamagePercents = CalculateAttributeValue(GetAttributeRandomizedValue(min, max));
			dmgBonusMult += bonusDamagePercents;
			//additional force damage shouldn't be multiplied by bonus multiplier
			//move to another place so it won't be multiplied by attack power?
			forceDamageIdx = -1;
			for(i = 0; i < dmgInfos.Size(); i += 1)
			{
				if(dmgInfos[i].dmgType == theGame.params.DAMAGE_NAME_FORCE)
					forceDamageIdx = i;
			}
			//additional damage for Aard
			if((W3AardProjectile)action.causer || (W3AardEntity)action.causer)
			{
				frozenDmgInfo.dmgVal = 0.05 * actorVictim.GetMaxHealth(); // 5% of victim's health
				frozenDmgInfo.dmgType = theGame.params.DAMAGE_NAME_FORCE;
				addForceDamage = true;
			}
			action.SetWasFrozen();
			actorVictim.RemoveAllBuffsOfType(EET_Frozen);
		}
		
		//apply damage bonus multiplier
		if(dmgBonusMult != 0)
		{
			for(i = 0 ; i < dmgInfos.Size(); i += 1)
			{
				dmgInfos[i].dmgVal *= 1 + dmgBonusMult;
			}
		}

		//debug log
		//theGame.witcherLog.AddMessage("ProcessDamageIncrease: mult = " + dmgBonusMult);
		
		//add force damage from frozen buff if needed
		if(addForceDamage)
		{
			if(forceDamageIdx != -1)
				dmgInfos[forceDamageIdx].dmgVal += frozenDmgInfo.dmgVal;
			else
				dmgInfos.PushBack(frozenDmgInfo);
		}
		
		//update action damages
		action.SetDTs(dmgInfos);
	}
	
	//modSigns
	private function ProcessDamageDecrease()
	{
		var quen : W3QuenEntity;
		
		if(playerVictim && playerVictim.HasBuff(EET_Mutagen19))
		{
			((W3Mutagen19_Effect)playerVictim.GetBuff(EET_Mutagen19)).ProtectiveQuen(action);
		}
		
		if(playerVictim == GetWitcherPlayer() && GetWitcherPlayer().IsAnyQuenActive())
		{
			action.RemoveBuffsByType(EET_SlowdownFrost);	//Eredin's weapon
			action.RemoveBuffsByType(EET_Paralyzed);		//lightning strike
		}
		
		if(playerVictim == GetWitcherPlayer())
		{
			quen = (W3QuenEntity)GetWitcherPlayer().GetSignEntity(ST_Quen);
			if(quen && quen.IsAnyQuenActive())
				quen.OnTargetHit(action);
		}
		//weirdly enough, NPC is supposed to being hit while casting quen
		//else if(actorVictim && actorVictim.HasAlternateQuen())
		//{
		//	action.SetAllProcessedDamageAs(0);
		//	action.ClearDamage();
		//	action.ClearEffects();
		//}
	}
	
	
	private function ProcessActionReturnedDamage()
	{
		var witcher 			: W3PlayerWitcher;
		var quen 				: W3QuenEntity;
		var params 				: SCustomEffectParams;
		var processFireShield, canBeParried, canBeDodged, wasParried, wasDodged, returned : bool;
		var g5Chance			: SAbilityAttributeValue;
		var dist, checkDist		: float;
		
		if(action.WasDodged()) //modSigns
			return;
		
		if((W3PlayerWitcher)playerVictim && !playerAttacker && actorAttacker && !action.IsDoTDamage() && action.IsActionMelee() && (attackerMonsterCategory == MC_Necrophage || attackerMonsterCategory == MC_Vampire) && actorVictim.HasBuff(EET_BlackBlood))
		{
			returned = ProcessActionBlackBloodReturnedDamage();		
		}
		
		
		if(action.IsActionMelee() && actorVictim.HasAbility( 'Thorns' ) )
		{
			returned = ProcessActionThornDamage() || returned;
		}
		
		//if((W3PlayerWitcher)playerVictim && ((W3PlayerWitcher)playerVictim).HasGlyphwordActive( 'Glyphword 5 _Stats' )) //modSigns
		//{			
		//	if( GetAttitudeBetween(actorAttacker, actorVictim) == AIA_Hostile)
		//	{
		//		if( !action.IsDoTDamage() )
		//		{
		//			g5Chance = actorVictim.GetAttributeValue('glyphword5_chance');
		//			
		//			if(RandF() < g5Chance.valueAdditive)
		//			{
		//				//canBeParried = attackAction.CanBeParried();
		//				//canBeDodged = attackAction.CanBeDodged();
		//				//wasParried = attackAction.IsParried() || attackAction.IsCountered();
		//				//wasDodged = attackAction.WasDodged();
		//		        //
		//				//if(!action.IsActionMelee() || (!canBeParried && canBeDodged && !wasDodged) || (canBeParried && !wasParried && !canBeDodged) || (canBeParried && canBeDodged && !wasDodged && !wasParried))
		//				//{
		//					returned = ProcessActionReflectDamage() || returned;
		//				//} //modSigns: damage is processed and is zero if dodged/parried/whatever
		//			}	
		//		}
		//	}			
		//	
		//}
		
		
		if(playerVictim && !playerAttacker && actorAttacker && attackAction && attackAction.IsActionMelee() && thePlayer.HasBuff(EET_Mutagen26))
		{
			returned = ProcessActionLeshenMutagenDamage() || returned;
		}
		
		
		if(action.IsActionMelee() && actorVictim.HasAbility( 'FireShield' ) )
		{
			witcher = GetWitcherPlayer();			
			processFireShield = true;			
			if(playerAttacker == witcher)
			{
				quen = (W3QuenEntity)witcher.GetSignEntity(ST_Quen);
				if(quen && quen.IsAnyQuenActive())
				{
					processFireShield = false;
				}
			}
			
			if(processFireShield)
			{
				params.effectType = EET_Burning;
				params.creator = actorVictim;
				params.sourceName = actorVictim.GetName();
				
				params.effectValue.valueMultiplicative = 0.01;
				actorAttacker.AddEffectCustom(params);
				returned = true;
			}
		}
		
		
		if(actorAttacker.UsesEssence())
		{
			returned = ProcessSilverStudsReturnedDamage() || returned;
		}
			
		
		if( (W3PlayerWitcher)playerVictim && !playerAttacker && actorAttacker && !playerAttacker.IsInFistFightMiniGame() && !action.IsDoTDamage() && action.IsActionMelee() && GetWitcherPlayer().IsMutationActive( EPMT_Mutation4 ) )
		{
			
			dist = VecDistance( actorAttacker.GetWorldPosition(), actorVictim.GetWorldPosition() );
			checkDist = 3.f;
			if( actorAttacker.IsHuge() )
			{
				checkDist += 3.f;
			}
 
			if( dist <= checkDist )
			{
				returned = GetWitcherPlayer().ProcessActionMutation4ReturnedDamage( action.processedDmg.vitalityDamage, actorAttacker, EAHA_ForceYes, action ) || returned;
			}
		}
		
		action.SetWasDamageReturnedToAttacker( returned );
	}
	
	
	private function ProcessActionLeshenMutagenDamage() : bool
	{
		var damageAction : W3DamageAction;
		var returnedDamage, pts, perc : float;
		var mutagen : W3Mutagen26_Effect;
		
		mutagen = (W3Mutagen26_Effect)playerVictim.GetBuff(EET_Mutagen26);
		mutagen.GetReturnedDamage(pts, perc);
		
		if(pts <= 0 && perc <= 0)
			return false;
		
		if(action.GetDamageDealt() <= 0)
			return false;
		
		//modSigns: use damage dealt
		//returnedDamage = pts + perc * action.GetDamageValueTotal();
		returnedDamage = pts + perc * action.GetDamageDealt();
		
		if(returnedDamage <= 0)
			return false;
		
		damageAction = new W3DamageAction in this;
		//modSigns: returned damage shouldn't use attack power
		//damageAction.Initialize( action.victim, action.attacker, NULL, "Mutagen26", EHRT_None, CPS_AttackPower, true, false, false, false );
		damageAction.Initialize( action.victim, action.attacker, NULL, "Mutagen26", EHRT_None, CPS_Undefined, true, false, false, false );
		damageAction.SetCannotReturnDamage( true );
		damageAction.SetHitAnimationPlayType( EAHA_ForceNo );
		damageAction.AddDamage(theGame.params.DAMAGE_NAME_SILVER, returnedDamage);
		damageAction.AddDamage(theGame.params.DAMAGE_NAME_PHYSICAL, returnedDamage);
		
		theGame.damageMgr.ProcessAction(damageAction);
		delete damageAction;
		
		return true;
	}
	
	
	private function ProcessSilverStudsReturnedDamage() : bool
	{
		var damageAction : W3DamageAction;
		var returnedDamage : float;
		
		returnedDamage = CalculateAttributeValue(actorVictim.GetAttributeValue('returned_silver_damage'));
		
		if(returnedDamage <= 0)
			return false;
		
		damageAction = new W3DamageAction in this;
		//damageAction.Initialize( action.victim, action.attacker, NULL, "SilverStuds", EHRT_None, CPS_AttackPower, true, false, false, false );
		damageAction.Initialize( action.victim, action.attacker, NULL, "SilverStuds", EHRT_None, CPS_Undefined, true, false, false, false );
		damageAction.SetCannotReturnDamage( true );		
		damageAction.SetHitAnimationPlayType( EAHA_ForceNo );		
		
		damageAction.AddDamage(theGame.params.DAMAGE_NAME_SILVER, returnedDamage);
		
		theGame.damageMgr.ProcessAction(damageAction);
		delete damageAction;
		
		return true;
	}
	
	
	private function ProcessActionBlackBloodReturnedDamage() : bool
	{
		var returnedAction : W3DamageAction;
		var returnVal : SAbilityAttributeValue;
		var bb : W3Potion_BlackBlood;
		var potionLevel : int;
		var procDmg, returnedDamage : float;
		
		procDmg = action.GetDamageDealt(); //modSigns
		
		if(procDmg <= 0)
			return false;
		
		bb = (W3Potion_BlackBlood)actorVictim.GetBuff(EET_BlackBlood);
		potionLevel = bb.GetBuffLevel();
		
		returnVal = bb.GetReturnDamageValue();
		
		returnedDamage = (returnVal.valueBase + procDmg) * returnVal.valueMultiplicative + returnVal.valueAdditive;
		
		if(returnedDamage <= 0)
			return false;

		returnedAction = new W3DamageAction in this;
		//modSigns: returned damage shouldn't use attack power
		//returnedAction.Initialize( action.victim, action.attacker, bb, "BlackBlood", EHRT_None, CPS_AttackPower, true, false, false, false );
		returnedAction.Initialize( action.victim, action.attacker, bb, "BlackBlood", EHRT_None, CPS_Undefined, true, false, false, false );
		returnedAction.SetCannotReturnDamage( true );
		
		if(potionLevel == 1)
		{
			returnedAction.SetHitAnimationPlayType(EAHA_ForceNo);
		}
		else
		{
			returnedAction.SetHitAnimationPlayType(EAHA_ForceYes);
			returnedAction.SetHitReactionType(EHRT_Reflect);
		}
		
		returnedAction.AddDamage(theGame.params.DAMAGE_NAME_SILVER, returnedDamage);
		returnedAction.AddDamage(theGame.params.DAMAGE_NAME_PHYSICAL, returnedDamage);
		
		theGame.damageMgr.ProcessAction(returnedAction);
		delete returnedAction;
		
		return true;
	}
	
	
	//private function ProcessActionReflectDamage() : bool
	//{
	//	var returnedAction : W3DamageAction;
	//	var returnVal, min, max : SAbilityAttributeValue;
	//	var potionLevel : int;
	//	var procDmg, returnedDamage : float;
	//	var template : CEntityTemplate;
	//	var fxEnt : CEntity;
	//	var boneIndex: int;
	//	var b : bool;
	//	var component : CComponent;
	//	
	//	procDmg = action.GetDamageDealt(); //modSigns
	//	
	//	if(procDmg <= 0)
	//		return false;
	//	
	//	//why armor?!?!
	//	//returnedDamage = CalculateAttributeValue(actorVictim.GetTotalArmor());
	//	theGame.GetDefinitionsManager().GetAbilityAttributeValue('Glyphword 5 _Stats', 'damage_mult', min, max);
	//	returnedDamage = procDmg * min.valueMultiplicative; //modSigns
	//	
	//	if(returnedDamage <= 0)
	//		return false;
	//	
	//	returnedAction = new W3DamageAction in this;
	//	//modSigns: returned damage shouldn't use attack power
	//	//returnedAction.Initialize( action.victim, action.attacker, NULL, "Glyphword5", EHRT_None, CPS_AttackPower, true, false, false, false );
	//	returnedAction.Initialize( action.victim, action.attacker, NULL, "Glyphword5", EHRT_None, CPS_Undefined, true, false, false, false );
	//	returnedAction.SetCannotReturnDamage( true );
	//	returnedAction.SetHitAnimationPlayType(EAHA_ForceYes);
	//	returnedAction.SetHitReactionType(EHRT_Heavy);
	//	//modSigns
	//	returnedAction.AddDamage(theGame.params.DAMAGE_NAME_SILVER, returnedDamage);
	//	returnedAction.AddDamage(theGame.params.DAMAGE_NAME_PHYSICAL, returnedDamage);
	//	
	//	theGame.damageMgr.ProcessAction(returnedAction);
	//	delete returnedAction;
	//	
	//	template = (CEntityTemplate)LoadResource('glyphword_5');
	//	
	//	component = action.attacker.GetComponent('torso3effect');
	//	if(component)
	//		thePlayer.PlayEffect('reflection_damge', component);
	//	else
	//		thePlayer.PlayEffect('reflection_damge', action.attacker);
	//	action.attacker.PlayEffect('yrden_shock');
	//	
	//	return true;
	//}
	
	
	private function ProcessActionThornDamage() : bool
	{
		var damageAction 		: W3DamageAction;
		var damageVal 			: SAbilityAttributeValue;
		var damage				: float;
		var inv					: CInventoryComponent;
		var damageNames			: array < CName >;
		
		inv = actorAttacker.GetInventory();
		inv.GetWeaponDTNames( weaponId, damageNames );
		damage = actorAttacker.GetTotalWeaponDamage( weaponId, damageNames[0], GetInvalidUniqueId() );
		
		if( damage == 0 )
		{
			damage = 300; //modSigns: low-damage weapon
		}
		
		damage *= 0.10f;
		
		if(damage <= 0) //modSigns
			return false;
		
		damageAction = new W3DamageAction in this;
		damageAction.Initialize( action.victim, action.attacker, NULL, "Thorns", EHRT_Light, CPS_AttackPower, true, false, false, false );
		damageAction.SetCannotReturnDamage( true );
		damageAction.AddDamage( theGame.params.DAMAGE_NAME_PIERCING, damage );
		damageAction.SetHitAnimationPlayType( EAHA_ForceYes );
		theGame.damageMgr.ProcessAction( damageAction );
		delete damageAction;
		
		return true;
	}
		
	
	//modSigns: many changes to how power mod is calculated
	private function GetAttackersPowerMod() : SAbilityAttributeValue
	{		
		var powerMod, criticalDamageBonus, min, max, critReduction, sp : SAbilityAttributeValue;
		var totalBonus : float;
		var yrdenEnt : W3YrdenEntity;
		var aerondight	: W3Effect_Aerondight;
		var lynxSetBuff : W3Effect_LynxSetBonus;
			
		//no power mod bonuses during fistfights
		if( thePlayer.IsFistFightMinigameEnabled() || weaponsAreNotDeadly )
		{
			powerMod.valueBase = 0;
			powerMod.valueMultiplicative = 1;
			powerMod.valueAdditive = 0;
			return powerMod;
		}

		//no damage increase for DoT effects
		if( action.IsDoTDamage() )
		{
			powerMod.valueMultiplicative = 1;
			powerMod.valueBase = 0;
			powerMod.valueAdditive = 0;
			return powerMod;
		}
		
		//base value
		powerMod = action.GetPowerStatValue();
		//theGame.witcherLog.AddMessage("powerMod base value: " + powerMod.valueMultiplicative); //modSigns: debug
		
		//logging
		if ( powerMod.valueAdditive == 0 && powerMod.valueBase == 0 && powerMod.valueMultiplicative == 0 && theGame.CanLog() )
		{
			LogDMHits("Attacker has power stat of 0!", action);
		}
		
		//Yrden cached power mod: for Flood of Anger to work properly
		if( (W3PlayerWitcher)playerAttacker && action.IsActionWitcherSign() && StrContains(action.GetBuffSourceName(), "_sign_yrden_alt") )
		{
			yrdenEnt = (W3YrdenEntity)((W3PlayerWitcher)playerAttacker).GetSignEntity(ST_Yrden);
			if( yrdenEnt )
			{
				sp = yrdenEnt.GetCachedYrdenPower();
				if( !( sp.valueAdditive == 0 && sp.valueBase == 0 && sp.valueMultiplicative == 0 ) )
				{
					powerMod = sp;
					//theGame.witcherLog.AddMessage("Yrden turret powerMod: " + powerMod.valueMultiplicative); //modSigns: debug
				}
			}
		}
		
		//Whirl attack power bonus
		if((W3PlayerWitcher)playerAttacker && thePlayer.IsDoingSpecialAttack(false) && thePlayer.GetStat(BCS_Focus) > 0)
		{
			powerMod.valueMultiplicative += ((W3PlayerWitcher)playerAttacker).GetWhirlDamageBonus();
			//theGame.witcherLog.AddMessage("Whirl AP bonus: " + ((W3PlayerWitcher)playerAttacker).GetWhirlDamageBonus()); //debug
		}
		
		//Rend attack power bonus
		//if((W3PlayerWitcher)playerAttacker && attackAction && SkillNameToEnum(attackAction.GetAttackTypeName()) == S_Sword_s02)
		//{
		//	powerMod.valueMultiplicative += ((W3PlayerWitcher)playerAttacker).GetRendAttackPowerBonus();
		//}
		
		//Lynx tier 1 power bonus
		if( (W3PlayerWitcher)playerAttacker && attackAction && attackAction.IsActionMelee() && playerAttacker.HasBuff( EET_LynxSetBonus ) )
		{
			lynxSetBuff = (W3Effect_LynxSetBonus)playerAttacker.GetBuff( EET_LynxSetBonus );
			powerMod.valueMultiplicative += lynxSetBuff.GetLynxBonus( playerAttacker.IsHeavyAttack( attackAction.GetAttackName() ) );
			//theGame.witcherLog.AddMessage("Lynx set tier 1 AP boost: " + lynxSetBuff.GetLynxBonus( playerAttacker.IsHeavyAttack( attackAction.GetAttackName() ) )); //debug
		}
		
		//Bear tier 1 power bonus
		if( (W3PlayerWitcher)playerAttacker && attackAction && (attackAction.IsActionMelee() || attackAction.IsActionRanged()) && ((W3PlayerWitcher)playerAttacker).IsSetBonusActive( EISB_Bear_1 ) )
		{
			theGame.GetDefinitionsManager().GetAbilityAttributeValue(GetSetBonusAbility(EISB_Bear_1), 'attack_power', min, max);
			powerMod.valueMultiplicative += min.valueMultiplicative * ((W3PlayerWitcher)playerAttacker).GetSetPartsEquipped(EIST_Bear) * FloorF(thePlayer.GetStat(BCS_Focus));
		}
		
		//headshots
		if(action.GetIsHeadShot())
		{
			powerMod.valueMultiplicative += theGame.params.HEAD_SHOT_DAMAGE_BONUS;
		}
		
		//backstabs
		if(actorVictim && actorAttacker && actorVictim.IsAttackerAtBack(actorAttacker))
		{
			powerMod.valueMultiplicative += theGame.params.BACK_ATTACK_DAMAGE_BONUS;
		}
		
		//critical hits
		if(action.IsCriticalHit())
		{
			//sign crits from mutation
			if( playerAttacker && action.IsActionWitcherSign() && GetWitcherPlayer().IsMutationActive(EPMT_Mutation2) )
			{
				//sp = action.GetPowerStatValue(); //modSigns: we already have powerMod set
				theGame.GetDefinitionsManager().GetAbilityAttributeValue('Mutation2', 'crit_damage_factor', min, max);				
				//modSigns: changing the formula
				criticalDamageBonus.valueAdditive = min.valueAdditive + SignPowerStatToPowerBonus(powerMod.valueMultiplicative) * min.valueMultiplicative;
			}
			else
			{
				criticalDamageBonus = actorAttacker.GetCriticalHitDamageBonus(weaponId, victimMonsterCategory, actorVictim.IsAttackerAtBack(playerAttacker));
				
				if(playerAttacker && attackAction && attackAction.IsActionMelee()) //exclude crossbows
				{
					//heavy attack bonus from skills
					if(playerAttacker.IsHeavyAttack(attackAction.GetAttackName()) && playerAttacker.CanUseSkill(S_Sword_s08))
					{
						criticalDamageBonus += playerAttacker.GetSkillAttributeValue(S_Sword_s08, theGame.params.CRITICAL_HIT_DAMAGE_BONUS, false, true) * playerAttacker.GetSkillLevel(S_Sword_s08);
					}
					//light attack bonus from skills
					else if (!playerAttacker.IsHeavyAttack(attackAction.GetAttackName()) && playerAttacker.CanUseSkill(S_Sword_s17))
					{
						criticalDamageBonus += playerAttacker.GetSkillAttributeValue(S_Sword_s17, theGame.params.CRITICAL_HIT_DAMAGE_BONUS, false, true) * playerAttacker.GetSkillLevel(S_Sword_s17);
					}
				}
				
				if( (W3PlayerWitcher)playerAttacker && (W3BoltProjectile)action.causer )
				{
					if( playerAttacker.CanUseSkill(S_Sword_s07) )
					{
						criticalDamageBonus += playerAttacker.GetSkillAttributeValue(S_Sword_s07, theGame.params.CRITICAL_HIT_DAMAGE_BONUS, false, true) * playerAttacker.GetSkillLevel(S_Sword_s07);
					}
					//Cat Eyes mutation crit damage boost
					if( GetWitcherPlayer().IsMutationActive( EPMT_Mutation9 ) )
					{
						theGame.GetDefinitionsManager().GetAbilityAttributeValue( 'Mutation9', 'critical_damage', min, max );
						criticalDamageBonus += min;
					}
				}
			}
			
			//modSigns: fully charged Aerondight crit damage bonus
			if( playerAttacker && actorVictim && attackAction && action.IsActionMelee() && playerAttacker.inv.ItemHasTag( attackAction.GetWeaponId(), 'Aerondight' ) )
			{	
				aerondight = (W3Effect_Aerondight)playerAttacker.GetBuff( EET_Aerondight );
				if( aerondight && aerondight.IsFullyCharged() )
					criticalDamageBonus.valueAdditive += aerondight.GetCritPowerBoost();
			}
			
			//RedWolf bonus
			if( ( W3Petard )action.causer && ( W3PlayerWitcher )actorAttacker && GetWitcherPlayer().IsSetBonusActive( EISB_RedWolf_1 ) )
			{
				theGame.GetDefinitionsManager().GetAbilityAttributeValue( GetSetBonusAbility( EISB_RedWolf_1 ), 'per_redwolf_piece_crit_power_bonus', min, max );
				min.valueAdditive *= GetWitcherPlayer().GetSetPartsEquipped( EIST_RedWolf );
				criticalDamageBonus += min;
			}
			
			//crit damage reduction
			totalBonus = CalculateAttributeValue(criticalDamageBonus);
			critReduction = actorVictim.GetAttributeValue(theGame.params.CRITICAL_HIT_REDUCTION);
			totalBonus = totalBonus * ClampF(1 - critReduction.valueMultiplicative, 0.f, 1.f);
			//final mod
			powerMod.valueMultiplicative += totalBonus;
			//modSigns: debug
			if( FactsQuerySum( "modSigns_debug_dmg" ) > 0 )
			{
				if(!(action.IsDoTDamage() && (CBaseGameplayEffect)action.causer))
				{
					theGame.witcherLog.AddMessage("Dmg manager:");
					theGame.witcherLog.AddMessage("Attacker: " + actorAttacker.GetDisplayName());
					theGame.witcherLog.AddMessage("Victim: " + actorVictim.GetDisplayName());
					theGame.witcherLog.AddMessage("Critical hit damage bonus: " + totalBonus);
				}
			}
		}
		
		//modSigns: no additional per player level damage for crossbows -> doesn't matter anymore as level base AP bonuses were removed
		if( (W3PlayerWitcher)playerAttacker && action.IsActionRanged() && (W3BoltProjectile)action.causer )
		{
			powerMod.valueAdditive = 0;
		}
		
		//modSigns: prevent negatives
		powerMod.valueBase = MaxF(powerMod.valueBase, 0);
		powerMod.valueMultiplicative = MaxF(powerMod.valueMultiplicative, 0);
		powerMod.valueAdditive = MaxF(powerMod.valueAdditive, 0);
		
		return powerMod;
	}
	
	//modSigns: many changes to how resists are calculated
	private function GetDamageResists(dmgType : name, out resistPts : float, out resistPerc : float)
	{
		var armorReduction, armorReductionPerc, skillArmorReduction : SAbilityAttributeValue;
		var bonusReduct, bonusResist, armorVal : float;
		//var mutagenBuff : W3Mutagen28_Effect;
		var encumbranceBonus : float;
		var temp : bool;
		var mutagen : CBaseGameplayEffect;
		var min, max : SAbilityAttributeValue;
		var i : int;
		var meltArmorDebuff : float;
		var meltAblCount : int;
		var dbombEffect : W3Effect_DimeritiumEffect;
		var dbombArmorDebuff, dbombResReduction : float;
		var aerondight : W3Effect_Aerondight;
		
		//ignore resistances for fistfight minigames
		if(thePlayer.IsFistFightMinigameEnabled())
		{
			resistPts = 0;
			resistPerc = 0;
			return;
		}
		
		//headshots ignore resistances and armor
		if(action.GetIsHeadShot())
		{
			actorVictim.SignalGameplayEvent( 'Headshot' );
			resistPts = 0;
			resistPerc = 0;
			return;
		}
		
		//fully charged Aerondight negates all resistances
		if(playerAttacker && actorVictim && attackAction && action.IsActionMelee() && playerAttacker.inv.ItemHasTag(attackAction.GetWeaponId(), 'Aerondight'))
		{	
			aerondight = (W3Effect_Aerondight)playerAttacker.GetBuff(EET_Aerondight);
			if(aerondight && aerondight.IsFullyCharged())
			{
				resistPts = 0;
				resistPerc = 0;
				return;
			}
		}
		
		//PhantomWeapon phantom strike negates all resistances
		if(action.GetBuffSourceName() == "PhantomWeapon")
		{
			resistPts = 0;
			resistPerc = 0;
			return;
		}
			
		//reductions from victim
		if(actorVictim)
		{
			//get base resists
			actorVictim.GetResistValue( GetResistForDamage(dmgType, action.IsDoTDamage()), resistPts, resistPerc );
			
			//oil damage reduction if player has skill which makes oil reduce player's received damage when fighting proper monster type
			//modSigns: now reduces the final damage
			/*if(playerVictim && actorAttacker && playerVictim.CanUseSkill(S_Alchemy_s05))
			{
				GetOilProtectionAgainstMonster(dmgType, bonusResist, bonusReduct);
				resistPerc += bonusResist * playerVictim.GetSkillLevel(S_Alchemy_s05);
			}*/
			
			// Mutagen 2 - increase resistPerc based on the encumbrance
			/*if(playerVictim == GetWitcherPlayer() && playerVictim.HasBuff(EET_Mutagen02))
			{
				encumbranceBonus = 1 - ClampF((GetWitcherPlayer().GetEncumbrance() - 60.0f) / 100.0f, 0.0f, 1.0f);
				mutagen = playerVictim.GetBuff(EET_Mutagen02);
				dm.GetAbilityAttributeValue(mutagen.GetAbilityName(), 'resistGainRate', min, max);
				encumbranceBonus *= CalculateAttributeValue(GetAttributeRandomizedValue(min, max));
				resistPerc += encumbranceBonus;
			}*/ //reworked
			
			//mutagen 28 damage protection against monsters
			/*if(playerVictim && actorAttacker && playerVictim.HasBuff(EET_Mutagen28))
			{
				mutagenBuff = (W3Mutagen28_Effect)playerVictim.GetBuff(EET_Mutagen28);
				mutagenBuff.GetProtection(attackerMonsterCategory, dmgType, action.IsDoTDamage(), bonusResist, bonusReduct);
				resistPts += bonusReduct;
				resistPerc += bonusResist;
			}*/ //reworked
			
			//from attacker
			if(actorAttacker)
			{
				//base armor reduction
				armorReduction = actorAttacker.GetAttributeValue('armor_reduction');
				armorReductionPerc = actorAttacker.GetAttributeValue('armor_reduction_perc');
				
				//apply oil bonus armor reduction
				if(playerAttacker && playerAttacker.GetInventory().ItemHasActiveOilApplied( weaponId, victimMonsterCategory ))
				{
					armorReductionPerc += actorAttacker.GetInventory().GetOilResistReductionBonus( weaponId, victimMonsterCategory ); //modSigns
				}
				
				//basic heavy attack armor piercing
				if( attackAction && playerAttacker && playerAttacker.CanUseSkill(S_Sword_2) && playerAttacker.IsHeavyAttack(attackAction.GetAttackName()) )
				{
					armorReduction += playerAttacker.GetSkillAttributeValue(S_Sword_2, 'armor_reduction', false, true);
				}
				
				//skill damage reduction
				if ( playerAttacker && 
					 action.IsActionMelee() && playerAttacker.IsHeavyAttack(attackAction.GetAttackName()) && 
					 ( dmgType == theGame.params.DAMAGE_NAME_PHYSICAL || 
					   dmgType == theGame.params.DAMAGE_NAME_SLASHING || 
				       dmgType == theGame.params.DAMAGE_NAME_PIERCING || 
					   dmgType == theGame.params.DAMAGE_NAME_BLUDGEONING || 
					   dmgType == theGame.params.DAMAGE_NAME_RENDING || 
					   dmgType == theGame.params.DAMAGE_NAME_SILVER
					 ) && 
					 playerAttacker.CanUseSkill(S_Sword_s06)
				   ) 
				{
					//percentage skill reduction
					skillArmorReduction = playerAttacker.GetSkillAttributeValue(S_Sword_s06, 'armor_reduction_perc', false, true);
					armorReductionPerc += skillArmorReduction * playerAttacker.GetSkillLevel(S_Sword_s06);				
				}
			}
		}
		
		//add ARMOR if can
		if(!action.GetIgnoreArmor())
		{
			resistPts += CalculateAttributeValue( actorVictim.GetTotalArmor() );
		}
		
		//Dimeritium bomb armor debuff for magical creatures
		if( actorVictim != thePlayer && actorVictim.HasBuff(EET_DimeritiumEffect) )
		{
			dbombEffect = (W3Effect_DimeritiumEffect)actorVictim.GetBuff(EET_DimeritiumEffect);
			if(dbombEffect)
				dbombArmorDebuff = dbombEffect.GetArmorPiercing();
		}

		//reduce resistance points by armor reduction
		resistPts = MaxF(0, resistPts - CalculateAttributeValue(armorReduction) - dbombArmorDebuff);
		
		//Melt Armor new mechanic -> redone, it's an effect now
		//meltAblCount = actorVictim.GetAbilityCount(SkillEnumToName(S_Magic_s08));
		//if( actorVictim != thePlayer && meltAblCount > 0 )
		//{
		//	meltArmorDebuff = meltAblCount * CalculateAttributeValue(actorVictim.GetAbilityAttributeValue(SkillEnumToName(S_Magic_s08), 'armor_reduction_bonus'));
		//	resistPts *= ClampF(1 - meltArmorDebuff, 0.0f, 1.0f);
		//}
		
		//theGame.witcherLog.AddMessage("meltArmorDebuff = " + meltArmorDebuff);
		//theGame.witcherLog.AddMessage("dbombArmorDebuff = " + dbombArmorDebuff);
		//theGame.witcherLog.AddMessage("resistPts = " + resistPts);
		
		//modSigns: NG+ crossbow hack
		//if( FactsQuerySum("NewGamePlus") > 0 && (W3PlayerWitcher)playerAttacker && action.IsActionRanged() && (W3BoltProjectile)action.causer )
		//{
		//	resistPts -= MaxF(0, 5 * (playerAttacker.GetLevel() - theGame.params.GetNewGamePlusLevel()));
		//}

		resistPts = MaxF(0, resistPts); // can't have negative resistance
		
		//DoT damage ignores point resistance
		if(action.IsPointResistIgnored() || action.IsDoTDamage())
		{
			resistPts = 0;
		}
		
		//Yrden Turret ignores point resistance -> shock damage now ignores armor
		//if((W3PlayerWitcher)playerAttacker && action.IsActionWitcherSign() && StrContains(action.GetBuffSourceName(), "_sign_yrden_alt"))
		//{
		//	resistPts = 0;
		//}
		
		//Shock damage (signs) ignores point resistance
		if(playerAttacker && dmgType == theGame.params.DAMAGE_NAME_SHOCK)
		{
			resistPts = 0;
		}
		
		//modSigns: move IceArmor code here
		if( !action.IsDoTDamage() && actorAttacker && actorVictim && actorVictim.HasAbility( 'IceArmor' ) && !actorAttacker.HasAbility( 'Ciri_Rage' ) )
		{
			if( theGame.GetDifficultyMode() != EDM_Easy )
			{
				resistPerc += 0.3;
			}
		}
		
		//Dimeritium bomb resist reduction for magical creatures
		if( actorVictim != thePlayer && actorVictim.HasBuff(EET_DimeritiumEffect) )
		{
			dbombEffect = (W3Effect_DimeritiumEffect)actorVictim.GetBuff(EET_DimeritiumEffect);
			if(dbombEffect)
				dbombResReduction = dbombEffect.GetResistReduction();
		}

		//modSigns: new mutagen02 effect
		if(actorVictim && actorVictim != thePlayer && actorVictim.HasAbility('Mutagen02Effect'))
		{
			resistPerc -= CalculateAttributeValue(actorVictim.GetAttributeValue('mutagen02_resist_reduction'));
			resistPerc = MaxF(0, resistPerc);
			//theGame.witcherLog.AddMessage("mutagen02 debuff = " + CalculateAttributeValue(actorVictim.GetAttributeValue('mutagen02_resist_reduction')));
		}
			
		//reduce resistance percents by resistance reduction
		resistPerc = MaxF(0, resistPerc - CalculateAttributeValue(armorReductionPerc) - dbombResReduction); // can't have negative resistance
		
		//Melt Armor additional effect
		if( actorVictim != thePlayer && meltArmorDebuff > 0 )
		{
			resistPerc *= ClampF(1 - meltArmorDebuff, 0.0f, 1.0f);
		}
		
		//theGame.witcherLog.AddMessage("meltArmorDebuff = " + meltArmorDebuff);
		//theGame.witcherLog.AddMessage("dbombResReduction = " + dbombResReduction);
		//theGame.witcherLog.AddMessage("resistPerc = " + resistPerc);
		
		hasArmor = (resistPts > 0); //modSigns - NPC is armored against this type of damage
	}
	
	//modSigns: debug
	function GetAttackerAbilities()
	{
		var arrNames, arrUniqueNames : array< name >;
		var i : int;

		actorAttacker.GetCharacterStats().GetAbilities( arrNames, false );
		ArrayOfNamesAppendUnique(arrUniqueNames, arrNames);
		if(arrUniqueNames.Size() > 0)
		{
			for( i = 0; i < arrUniqueNames.Size(); i += 1 )
				theGame.witcherLog.AddCombatMessage("Ability:" + arrUniqueNames[i], thePlayer, NULL);
		}
	}
		
	//modSigns: damage formula changed
	private function CalculateDamage(dmgInfo : SRawDamage, powerMod : SAbilityAttributeValue) : float
	{
		var rawDamage, finalDamage, finalIncomingDamage : float;
		var resistPoints, resistPercents : float;
		var npcAttacker : CNewNPC;
		var maxAllowedDmg, minAllowedDmg, mutagen14bonus : float ;
		var axiiLvl : float;
		
		if(actorVictim.UsesVitality() && !DamageHitsVitality(dmgInfo.dmgType))
			return 0;
		
		if(actorVictim.UsesEssence() && !DamageHitsEssence(dmgInfo.dmgType))
			return 0;
		
		if(dmgInfo.dmgVal <= 0)
			return 0;
		
		if( !thePlayer.IsFistFightMinigameEnabled() && weaponsAreNotDeadly )
			return 10;
			
		npcAttacker = (CNewNPC)actorAttacker;

		//get total reductions for this damage type
		GetDamageResists(dmgInfo.dmgType, resistPoints, resistPercents);
		
		//let point resistance affect raw damage dealt by weapon (+ base damage bonuses from level up for npc)
		rawDamage = MaxF(0, dmgInfo.dmgVal + powerMod.valueBase - resistPoints);
		
		//final damage is multiplied by attacker's power, that includes crit bonuses
		//additive value is bonus/penalty damage that is not affected nor by armor not by attack power
		finalDamage = MaxF(0, rawDamage * powerMod.valueMultiplicative + powerMod.valueAdditive);
		
		//friendly npc damage: dirty hack, but I'm kinda tired of this
		//moved here for resistances to be able to affect npc damage
		if( !action.IsDoTDamage() && npcAttacker && actorVictim && GetAttitudeBetween(npcAttacker, thePlayer) == AIA_Friendly && GetAttitudeBetween(actorVictim, thePlayer) == AIA_Hostile )
		{
			if( npcAttacker.HasBuff( EET_AxiiGuardMe ) )
			{
				axiiLvl = CalculateAttributeValue(npcAttacker.GetAttributeValue('alt_axii_level'));
				//theGame.witcherLog.AddMessage("axiiLvl = " + axiiLvl);
				//buff axii puppet for new Succubus mutagen
				if( thePlayer.HasBuff(EET_Mutagen14) )
				{
					mutagen14bonus = ((W3Mutagen14_Effect)thePlayer.GetBuff(EET_Mutagen14)).GetMutagen14Bonus();
					//theGame.witcherLog.AddMessage("mutagen14bonus = " + mutagen14bonus);
					maxAllowedDmg = MaxF(20, 0.12 * (1 + mutagen14bonus) * actorVictim.GetMaxHealth() * axiiLvl/3.0);
					minAllowedDmg = MaxF(10, 0.06 * (1 + mutagen14bonus) * actorVictim.GetMaxHealth() * axiiLvl/3.0);
				}
				else
				{
					maxAllowedDmg = MaxF(20, 0.12 * actorVictim.GetMaxHealth() * axiiLvl/3.0);
					minAllowedDmg = MaxF(10, 0.06 * actorVictim.GetMaxHealth() * axiiLvl/3.0);
				}
			}
			else if( npcAttacker.HasTag('mq1041_soldier') || npcAttacker.HasTag('mq1041_redanian') )
			{
				maxAllowedDmg = MaxF(20, 0.15 * actorVictim.GetMaxHealth());
				minAllowedDmg = MaxF(10, 0.10 * actorVictim.GetMaxHealth());
			}
			else
			{
				//generic allies
				maxAllowedDmg = MaxF(20, 0.04 * actorVictim.GetMaxHealth());
				minAllowedDmg = MaxF(10, 0.02 * actorVictim.GetMaxHealth());
			}
			//hack of all hacks! sorry, really tired :)
			finalDamage = RandRangeF(maxAllowedDmg, minAllowedDmg);
			//no resistance pts for allies
			//if(!(attackAction && npcAttacker.IsHeavyAttack(attackAction.GetAttackName()))) //heavy attacks break through armor
			//	finalDamage -= resistPoints;
			finalDamage = MaxF(10, finalDamage);
			//theGame.witcherLog.AddMessage("finalDamage = " + finalDamage);
			if( FactsQuerySum( "modSigns_zero_ally_dmg" ) > 0 )
				finalDamage = 0; //debug helper
		}
		
		finalIncomingDamage = finalDamage; //for logging
		
		//apply damage resistance
		if(finalDamage > 0.f)
		{
			finalDamage *= ClampF(1 - resistPercents, 0, 1);
		}

		//fire damage
		if(finalDamage > 0 && dmgInfo.dmgType == theGame.params.DAMAGE_NAME_FIRE)
		{
			action.SetDealtFireDamage(true);
		}
		
		//modSigns: debug
		if( FactsQuerySum( "modSigns_debug_dmg" ) > 0 )
		{
			if(!(action.IsDoTDamage() && (CBaseGameplayEffect)action.causer) && (actorVictim.UsesVitality() && DamageHitsVitality(dmgInfo.dmgType) || actorVictim.UsesEssence() && DamageHitsEssence(dmgInfo.dmgType)))
			{
				theGame.witcherLog.AddMessage("Dmg manager:");
				theGame.witcherLog.AddMessage("Attacker: " + actorAttacker.GetDisplayName());
				theGame.witcherLog.AddMessage("Victim: " + actorVictim.GetDisplayName());
				theGame.witcherLog.AddMessage("Dmg type: " + (dmgInfo.dmgType));
				theGame.witcherLog.AddMessage("Weapon dmg: " + (dmgInfo.dmgVal));
				theGame.witcherLog.AddMessage("Mod.base: " + (powerMod.valueBase));
				theGame.witcherLog.AddMessage("Resist pts: " + (resistPoints));
				theGame.witcherLog.AddMessage("Raw dmg: " + (rawDamage));
				theGame.witcherLog.AddMessage("Mod.mult: " + (powerMod.valueMultiplicative));
				theGame.witcherLog.AddMessage("Mod.add: " + (powerMod.valueAdditive));
				theGame.witcherLog.AddMessage("Incoming dmg: " + (finalIncomingDamage));
				theGame.witcherLog.AddMessage("Resist prc: " + (resistPercents));
				theGame.witcherLog.AddMessage("Final dmg: " + (finalDamage));
			}
		}
		
		//extensive logging
		if ( theGame.CanLog() )
		{
			LogDMHits("Single hit damage: initial damage = " + NoTrailZeros(dmgInfo.dmgVal), action);
			LogDMHits("Single hit damage: attack_power = base: " + NoTrailZeros(powerMod.valueBase) + ", mult: " + NoTrailZeros(powerMod.valueMultiplicative) + ", add: " + NoTrailZeros(powerMod.valueAdditive), action );
			if(action.IsPointResistIgnored())
				LogDMHits("Single hit damage: resistance pts and armor = IGNORED", action);
			else
				LogDMHits("Single hit damage: resistance pts and armor = " + NoTrailZeros(resistPoints), action);			
			LogDMHits("Single hit damage: resistance perc = " + NoTrailZeros(resistPercents * 100), action);
			LogDMHits("Single hit damage: final damage to sustain = " + NoTrailZeros(finalDamage), action);
		}
			
		return finalDamage;
	}
	
	//modSigns: resists-independent damage mods
	private function ProcessDamageModification()
	{
		var min, max : SAbilityAttributeValue;
		var mult, dmg : float;
		var ignoreDifficultySettings : bool;
		var npcAttacker, npcVictim : CNewNPC;
		
		npcAttacker = (CNewNPC)actorAttacker;
		npcVictim = (CNewNPC)actorVictim;
		
		ignoreDifficultySettings = actorAttacker.IgnoresDifficultySettings();
		
		if(!action.DealsAnyDamage() || action.WasDodged() || action.IsDoTDamage() && (CBaseGameplayEffect)action.causer)
			return;
		
		if( (W3PlayerWitcher)playerAttacker ) //for player witcher attacker
		{
			//damage reduction for perk_16
			if( (CThrowable)action.causer && ((W3PlayerWitcher)playerAttacker).CanUseSkill( S_Perk_16 ) )
			{
				mult = 0.5;
				action.processedDmg.vitalityDamage *= mult;
				action.processedDmg.essenceDamage *= mult;
			}
			//damage reduction for non-aimed crossbow shots and bombs
			if( (CThrowable)action.causer && !((CThrowable)action.causer).IsFromAimThrow() && !action.IsBouncedArrow() )
			{
				mult = 0.5;
				action.processedDmg.vitalityDamage *= mult;
				action.processedDmg.essenceDamage *= mult;
			}
			//decrease sign vitality damage for non-DoT damages
			if( action.IsActionWitcherSign() && actorVictim.UsesVitality() )
			{
				mult = (0.75 - 0.5 * MaxF(0, 1 - 0.1 * (actorAttacker.GetLevel() - 1)));
				action.processedDmg.vitalityDamage *= mult;
				action.processedDmg.essenceDamage *= mult;
			}
			//severance damage debuff for Whirl and Rend
			if( action.IsActionMelee() && ( thePlayer.IsDoingSpecialAttack(false) || thePlayer.IsDoingSpecialAttack(true) ) )
			{
				theGame.GetDefinitionsManager().GetAbilityAttributeValue('Runeword 2 _Stats', 'runeword2_damage_debuff', min, max);
				mult = CalculateAttributeValue(min);
				action.processedDmg.vitalityDamage *= 1 - mult;
				action.processedDmg.essenceDamage *= 1 - mult;
				//theGame.witcherLog.AddMessage("Severance damage debuff % = " + (100 * mult));
			}
			//supercharged glyphs damage increase
			if( actorVictim.HasBuff(EET_YrdenHealthDrain) )
			{
				mult = ((W3Effect_YrdenHealthDrain)actorVictim.GetBuff(EET_YrdenHealthDrain)).GetDmgBonus();
				action.processedDmg.vitalityDamage *= 1 + mult;
				action.processedDmg.essenceDamage *= 1 + mult;
				//theGame.witcherLog.AddMessage("Supercharged Glyphs damage buff % = " + (100 * mult));
			}
			//crippling strikes damage increase
			if( attackAction && attackAction.IsActionMelee() && playerAttacker.IsLightAttack(attackAction.GetAttackName()) && playerAttacker.CanUseSkill(S_Sword_s05) && actorVictim.HasBuff(EET_Bleeding) )
			{
				mult = CalculateAttributeValue(playerAttacker.GetSkillAttributeValue(S_Sword_s05, 'sword_s5_dmg_boost', false, true)) * playerAttacker.GetSkillLevel(S_Sword_s05);
				action.processedDmg.vitalityDamage *= 1 + mult;
				action.processedDmg.essenceDamage *= 1 + mult;
				//theGame.witcherLog.AddMessage("Crippling strikes damage buff % = " + (100 * mult));
			}
			//mutation8 (Deadly Counter) damage increase
			//if( attackAction && attackAction.IsActionMelee() && ((W3PlayerWitcher)playerAttacker).IsMutationActive(EPMT_Mutation8) && ((W3PlayerWitcher)playerAttacker).HasRecentlyCountered() )
			if( attackAction && attackAction.IsActionMelee() && ((W3PlayerWitcher)playerAttacker).IsMutationActive(EPMT_Mutation8) && actorVictim && actorVictim.WasCountered() )
			{
				dm.GetAbilityAttributeValue( 'Mutation8', 'dmg_bonus', min, max );
				mult = min.valueMultiplicative * playerAttacker.GetStat(BCS_Focus);
				action.processedDmg.vitalityDamage *= 1 + mult;
				action.processedDmg.essenceDamage *= 1 + mult;
				//theGame.witcherLog.AddMessage("Deadly Counter damage buff % = " + (100 * mult));
			}
		}
		//modSigns: damage hack for forced non-minigame fistfights and wooden sword fights
		if(!thePlayer.IsFistFightMinigameEnabled() && weaponsAreNotDeadly)
		{
			if(playerAttacker)
			{
				if(actorVictim.HasAbility('mon_ff204olaf') || actorVictim.HasAbility('mon_ff205troll'))
					mult = 0.5;
				else
					mult = 1;
			}
			else if(actorAttacker.HasAbility('fistfight_q002')) //prologue fistfighters
				mult = 0.25;
			else
				mult = 0.25 + MaxF(0, (int)theGame.GetSpawnDifficultyMode() - 1) * 0.25 + 0.1 * ClampF(actorAttacker.GetLevel() - actorVictim.GetLevel(), -10, 10);
			if(actorVictim.UsesEssence())
			{
				action.processedDmg.essenceDamage = 0.2 * (1 + 1 * (int)actorAttacker.IsHeavyAttack(attackAction.GetAttackName())) * actorVictim.GetMaxHealth();
				action.processedDmg.essenceDamage *= mult;
			}
			else if(actorVictim.UsesVitality())
			{
				action.processedDmg.vitalityDamage = 0.2 * (1 + 1 * (int)actorAttacker.IsHeavyAttack(attackAction.GetAttackName())) * actorVictim.GetMaxHealth();
				action.processedDmg.vitalityDamage *= mult;
			}
			ignoreDifficultySettings = true;
		}
		//difficulty dependent damage increase
		//only for the player, allied npcs are handled differently
		if( actorAttacker && actorAttacker != thePlayer && !ignoreDifficultySettings && actorVictim && actorVictim == thePlayer && GetAttitudeBetween(actorAttacker, thePlayer) == AIA_Hostile )
		{
			if(thePlayer.IsFistFightMinigameEnabled())
				mult = 1.0 + ((int)theGame.GetSpawnDifficultyMode() - 1) * 0.25 + 0.1 * ClampF(actorAttacker.GetLevel() - actorVictim.GetLevel(), -10, 10);
			else
				mult = CalculateAttributeValue(actorAttacker.GetAttributeValue(theGame.params.DIFFICULTY_DMG_MULTIPLIER));
			action.processedDmg.vitalityDamage *= mult;
			action.processedDmg.essenceDamage *= mult;
			//theGame.witcherLog.AddMessage("Dmg manager: diff mult = " + mult);
		}
		//npc friendly fire
		if( npcAttacker && npcVictim && GetAttitudeBetween(npcAttacker, npcVictim) == AIA_Friendly )
		{
			mult = 0.25;
			action.processedDmg.vitalityDamage *= mult;
			action.processedDmg.essenceDamage *= mult;
		}
			
		//Dimeritium bomb dmg reduction
		if( (W3PlayerWitcher)playerVictim && actorAttacker && actorAttacker.HasBuff(EET_DimeritiumEffect) )
		{
			mult = 1 - ((W3Effect_DimeritiumEffect)actorAttacker.GetBuff(EET_DimeritiumEffect)).GetDamageReduction();
			action.processedDmg.vitalityDamage *= mult;
			action.processedDmg.essenceDamage *= mult;
			//theGame.witcherLog.AddMessage("Dbomb damage debuff % = " + 100*(((W3Effect_DimeritiumEffect)actorAttacker.GetBuff(EET_DimeritiumEffect)).GetDamageReduction()));
		}
		
		//no damage
		if( action.processedDmg.vitalityDamage < 1.f && !action.IsDoTDamage() )
		{
			action.processedDmg.vitalityDamage = 0;
		}
		
		if( action.processedDmg.essenceDamage < 1.f && !action.IsDoTDamage() )
		{
			action.processedDmg.essenceDamage = 0;
		}
		
		//damage negated by armor
		if( !action.DealsAnyDamage() && hasArmor )
		{
			action.SetArmorReducedDamageToZero();
		}
		
		if( FactsQuerySum( "modSigns_debug_dmg" ) > 0 )
		{
			theGame.witcherLog.AddMessage("Dmg manager:");
			theGame.witcherLog.AddMessage("Attacker: " + actorAttacker.GetDisplayName());
			theGame.witcherLog.AddMessage("Victim: " + actorVictim.GetDisplayName());
			if( actorVictim.UsesVitality() )
				theGame.witcherLog.AddMessage("Final vitality damage: " + action.processedDmg.vitalityDamage);
			else if( actorVictim.UsesEssence() )
				theGame.witcherLog.AddMessage("Final essence damage: " + action.processedDmg.essenceDamage);
		}
	}
	
	
	private function ProcessActionDamage_DealDamage()
	{
		var logStr : string;
		var hpPerc : float;
		var npcVictim : CNewNPC;
	
		
		if ( theGame.CanLog() )
		{
			logStr = "";
			if(action.processedDmg.vitalityDamage > 0)			logStr += NoTrailZeros(action.processedDmg.vitalityDamage) + " vitality, ";
			if(action.processedDmg.essenceDamage > 0)			logStr += NoTrailZeros(action.processedDmg.essenceDamage) + " essence, ";
			if(action.processedDmg.staminaDamage > 0)			logStr += NoTrailZeros(action.processedDmg.staminaDamage) + " stamina, ";
			if(action.processedDmg.moraleDamage > 0)			logStr += NoTrailZeros(action.processedDmg.moraleDamage) + " morale";
				
			if(logStr == "")
				logStr = "NONE";
			LogDMHits("Final damage to sustain is: " + logStr, action);
		}
		
		if( FactsQuerySum( "modSigns_debug_dmg" ) > 0 ) //modSigns debug
		{
			if(!(action.IsDoTDamage() && (CBaseGameplayEffect)action.causer))
			{
				theGame.witcherLog.AddMessage("Dmg manager:");
				theGame.witcherLog.AddMessage("Attacker: " + actorAttacker.GetDisplayName());
				theGame.witcherLog.AddMessage("Victim: " + actorVictim.GetDisplayName());
				if((CNewNPC)actorAttacker)
					theGame.witcherLog.AddMessage("Attacker level: " + ((CNewNPC)actorAttacker).GetLevel());
				if((CNewNPC)actorVictim)
					theGame.witcherLog.AddMessage("Victim level: " + ((CNewNPC)actorVictim).GetLevel());
				theGame.witcherLog.AddMessage("Attacker template: " + actorAttacker.GetReadableName());
				if( FactsQuerySum( "modSigns_debug_abl" ) > 0 )
				{
					GetAttackerAbilities();
				}
				theGame.witcherLog.AddMessage("Victim template: " + actorVictim.GetReadableName());
				theGame.witcherLog.AddMessage("Is melee: " + action.IsActionMelee());
				theGame.witcherLog.AddMessage("Attack name: " + attackAction.GetAttackName());
				theGame.witcherLog.AddMessage("Is light attack: " + actorAttacker.IsLightAttack(attackAction.GetAttackName()));
				theGame.witcherLog.AddMessage("Is heavy attack: " + actorAttacker.IsHeavyAttack(attackAction.GetAttackName()));
				if(action.IsActionMelee())
				{
					theGame.witcherLog.AddMessage("Is fistfight minigame: " + thePlayer.IsFistFightMinigameEnabled());
					theGame.witcherLog.AddMessage("Non-deadly weapon fight: " + weaponsAreNotDeadly);
				}
				if(action.IsActionRanged())
				{
					theGame.witcherLog.AddMessage("Is headshot: " + action.GetIsHeadShot());
					theGame.witcherLog.AddMessage("Is aimed: " + ((CThrowable)action.causer).IsFromAimThrow());
					theGame.witcherLog.AddMessage("Is bounced arrow: " + action.IsBouncedArrow());
				}
				theGame.witcherLog.AddMessage("Is critical: " + action.IsCriticalHit());
				theGame.witcherLog.AddMessage("Victim has alt Quen: " + actorVictim.HasAlternateQuen());
				theGame.witcherLog.AddMessage("Is dodged: " + action.WasDodged());
				if(attackAction)
				{
					theGame.witcherLog.AddMessage("Is parried: " + attackAction.IsParried());
					theGame.witcherLog.AddMessage("Is countered: " + attackAction.IsCountered());
				}
				if(actorVictim.UsesVitality())
				{
					theGame.witcherLog.AddMessage("Victim max vitality: " + actorVictim.GetStatMax(BCS_Vitality));
					theGame.witcherLog.AddMessage("Victim cur vitality: " + actorVictim.GetStat(BCS_Vitality));
				}
				if(actorVictim.UsesEssence())
				{
					theGame.witcherLog.AddMessage("Victim max essence: " + actorVictim.GetStatMax(BCS_Essence));
					theGame.witcherLog.AddMessage("Victim cur essence: " + actorVictim.GetStat(BCS_Essence));
				}
				theGame.witcherLog.AddMessage("Deals damage: " + action.DealsAnyDamage());
				if(actorVictim.UsesVitality() && action.processedDmg.vitalityDamage > 0)
					theGame.witcherLog.AddMessage("Vitality damage to deal: " + action.processedDmg.vitalityDamage);
				else if(actorVictim.UsesEssence() && action.processedDmg.essenceDamage > 0)
					theGame.witcherLog.AddMessage("Essence damage to deal: " + action.processedDmg.essenceDamage);
				theGame.witcherLog.AddMessage("Morale damage to deal: " + action.processedDmg.moraleDamage);
			}
		}
		
		if(actorVictim)
		{
			hpPerc = actorVictim.GetHealthPercents();
			
			
			if(actorVictim.IsAlive())
			{
				npcVictim = (CNewNPC)actorVictim;
				if(npcVictim && npcVictim.IsHorse())
				{
					npcVictim.GetHorseComponent().OnTakeDamage(action);
				}
				else
				{
					actorVictim.OnTakeDamage(action);
				}
			}
			
			if(!actorVictim.IsAlive() && hpPerc == 1)
				action.SetWasKilledBySingleHit();
		}
			
		if ( theGame.CanLog() )
		{
			LogDMHits("", action);
			LogDMHits("Target stats after damage dealt are:", action);
			if(actorVictim)
			{
				if( actorVictim.UsesVitality())						LogDMHits("Vitality = " + NoTrailZeros( actorVictim.GetStat(BCS_Vitality)), action);
				if( actorVictim.UsesEssence())						LogDMHits("Essence = "  + NoTrailZeros( actorVictim.GetStat(BCS_Essence)), action);
				if( actorVictim.GetStatMax(BCS_Stamina) > 0)		LogDMHits("Stamina = "  + NoTrailZeros( actorVictim.GetStat(BCS_Stamina, true)), action);
				if( actorVictim.GetStatMax(BCS_Morale) > 0)			LogDMHits("Morale = "   + NoTrailZeros( actorVictim.GetStat(BCS_Morale)), action);
			}
			else
			{
				LogDMHits("Undefined - victim is not a CActor and therefore has no stats", action);
			}
		}
	}
	
	
	private function ProcessActionDamage_ReduceDurability()
	{		
		var witcherPlayer : W3PlayerWitcher;
		var dbg_currDur, dbg_prevDur1, dbg_prevDur2, dbg_prevDur3, dbg_prevDur4, dbg_prevDur : float;
		var dbg_armor, dbg_pants, dbg_boots, dbg_gloves, reducedItemId, weapon : SItemUniqueId;
		var slot : EEquipmentSlots;
		var weapons : array<SItemUniqueId>;
		var armorStringName : string;
		var canLog, playerHasSword : bool;
		var i : int;
		
		canLog = theGame.CanLog();

		witcherPlayer = GetWitcherPlayer();
	
		
		if ( playerAttacker && playerAttacker.inv.IsIdValid( weaponId ) && playerAttacker.inv.HasItemDurability( weaponId ) )
		{		
			dbg_prevDur = playerAttacker.inv.GetItemDurability(weaponId);
						
			if ( playerAttacker.inv.ReduceItemDurability(weaponId) && canLog )
			{
				LogDMHits("", action);
				LogDMHits("Player's weapon durability changes from " + NoTrailZeros(dbg_prevDur) + " to " + NoTrailZeros(action.attacker.GetInventory().GetItemDurability(weaponId)), action );
			}
		}
		
		else if(playerVictim && attackAction && attackAction.IsActionMelee() && (attackAction.IsParried() || attackAction.IsCountered()) )
		{
			weapons = playerVictim.inv.GetHeldWeapons();
			playerHasSword = false;
			for(i=0; i<weapons.Size(); i+=1)
			{
				weapon = weapons[i];
				if(playerVictim.inv.IsIdValid(weapon) && (playerVictim.inv.IsItemSteelSwordUsableByPlayer(weapon) || playerVictim.inv.IsItemSilverSwordUsableByPlayer(weapon)) )
				{
					playerHasSword = true;
					break;
				}
			}
			
			if(playerHasSword)
			{
				playerVictim.inv.ReduceItemDurability(weapon);
			}
		}
		
		else if(action.victim == witcherPlayer && (action.IsActionMelee() || action.IsActionRanged()) && action.DealsAnyDamage())
		{
			
			if ( canLog )
			{
				if ( witcherPlayer.GetItemEquippedOnSlot(EES_Armor, dbg_armor) )
					dbg_prevDur1 = action.victim.GetInventory().GetItemDurability(dbg_armor);
				else
					dbg_prevDur1 = 0;
					
				if ( witcherPlayer.GetItemEquippedOnSlot(EES_Pants, dbg_pants) )
					dbg_prevDur2 = action.victim.GetInventory().GetItemDurability(dbg_pants);
				else
					dbg_prevDur2 = 0;
					
				if ( witcherPlayer.GetItemEquippedOnSlot(EES_Boots, dbg_boots) )
					dbg_prevDur3 = action.victim.GetInventory().GetItemDurability(dbg_boots);
				else
					dbg_prevDur3 = 0;
					
				if ( witcherPlayer.GetItemEquippedOnSlot(EES_Gloves, dbg_gloves) )
					dbg_prevDur4 = action.victim.GetInventory().GetItemDurability(dbg_gloves);
				else
					dbg_prevDur4 = 0;
			}
			
			slot = GetWitcherPlayer().ReduceArmorDurability();
			
			
			if( canLog )
			{
				LogDMHits("", action);
				if(slot != EES_InvalidSlot)
				{		
					switch(slot)
					{
						case EES_Armor : 
							armorStringName = "chest armor";
							reducedItemId = dbg_armor;
							dbg_prevDur = dbg_prevDur1;
							break;
						case EES_Pants : 
							armorStringName = "pants";
							reducedItemId = dbg_pants;
							dbg_prevDur = dbg_prevDur2;
							break;
						case EES_Boots :
							armorStringName = "boots";
							reducedItemId = dbg_boots;
							dbg_prevDur = dbg_prevDur3;
							break;
						case EES_Gloves :
							armorStringName = "gloves";
							reducedItemId = dbg_gloves;
							dbg_prevDur = dbg_prevDur4;
							break;
					}
					
					dbg_currDur = action.victim.GetInventory().GetItemDurability(reducedItemId);
					LogDMHits("", action);
					LogDMHits("Player's <<" + armorStringName + ">> durability changes from " + NoTrailZeros(dbg_prevDur) + " to " + NoTrailZeros(dbg_currDur), action );
				}
				else
				{
					LogDMHits("Tried to reduce player's armor durability but failed", action);
				}
			}
				
			
			if(slot != EES_InvalidSlot)
				thePlayer.inv.ReduceItemRepairObjectBonusCharge(reducedItemId);
		}
	}	
	
	
	
	
	
	private var confusionInstakillTested : bool; //modSigns
	
	//modSigns
	private function IsAxiiInstakillTarget() : bool
	{
		return (!playerVictim && actorVictim && !((W3MonsterHuntNPC)actorVictim) && !actorVictim.IsImmuneToInstantKill() && actorVictim.IsAlive() && attackAction && attackAction.DealsAnyDamage() && (actorVictim.HasBuff(EET_Confusion) || actorVictim.HasBuff(EET_AxiiGuardMe)));
	}
	
	//modSigns
	private function GetAxiiInstakillChance() : int
	{
		var chance : int; //0 to 100%
		var victimHealth, damageSeverity : float;
		var sp : SAbilityAttributeValue; //modSigns
		
		if(IsAxiiInstakillTarget())
		{
			victimHealth = victimHealthPercBeforeHit * actorVictim.GetMaxHealth();
			damageSeverity = ClampF(action.GetDamageDealt() / victimHealth, 0.f, 1.f);
			chance = 1 + RoundMath(damageSeverity * 33.4); //1% + damage severity bonus
			//axii confusion sign power bonus
			if(actorVictim.HasBuff(EET_Confusion) && ((W3ConfuseEffect)actorVictim.GetBuff(EET_Confusion)).IsSignEffect())
			{
				sp = ((W3ConfuseEffect)actorVictim.GetBuff(EET_Confusion)).GetCreatorPowerStat();
				chance = RoundMath(chance * (1 + SignPowerStatToPowerBonus(sp.valueMultiplicative)));
			}
			//theGame.witcherLog.AddMessage("damageDealt = " + action.GetDamageDealt());
			//theGame.witcherLog.AddMessage("victimHealth = " + victimHealth);
			//theGame.witcherLog.AddMessage("damageSeverity = " + damageSeverity);
			//theGame.witcherLog.AddMessage("chance = " + chance);
		}
		
		return chance;
	}
	
	private function ProcessActionReaction(wasFrozen : bool, wasAlive : bool)
	{
		var dismemberExplosion 			: bool;
		var damageName 					: name;
		var damage 						: array<SRawDamage>;
		var points, percents, hp, dmg 	: float;
		var counterAction 				: W3DamageAction;		
		var moveTargets					: array<CActor>;
		var i 							: int;
		var canPerformFinisher			: bool;
		var canDismember				: bool; //modSigns
		var weaponName					: name;
		var npcVictim					: CNewNPC;
		var toxicCloud					: W3ToxicCloud;
		var playsNonAdditiveAnim		: bool;
		var bleedCustomEffect 			: SCustomEffectParams;
		var resPt, resPrc, chance		: float; //modSigns
		
		if(!actorVictim)
			return;
		
		confusionInstakillTested = false; //modSigns
		npcVictim = (CNewNPC)actorVictim;
		canPerformFinisher = CanPerformFinisher(actorVictim);
		canDismember = CanDismember(wasFrozen, dismemberExplosion, weaponName); //modSigns
		
		//if(playerAttacker) //debug
		//{
		//	theGame.witcherLog.AddMessage("canPerformFinisher = " + canPerformFinisher);
		//	theGame.witcherLog.AddMessage("canDismember = " + canDismember);
		//	theGame.witcherLog.AddMessage("mutation8Triggered = " + mutation8Triggered);
		//}
		
		//modSigns: disable finishers if blizzard potion is active
		if(canPerformFinisher && thePlayer.HasBuff(EET_Blizzard) && ((W3Potion_Blizzard)thePlayer.GetBuff(EET_Blizzard)).IsSlowMoActive())
			canPerformFinisher = false;
		
		//modSigns: reworked to support dismembering of alive targets
		if( actorVictim.IsAlive() && !canPerformFinisher && !canDismember && !mutation8Triggered ) //modSigns
		{
			if(!action.IsDoTDamage() && action.DealtDamage())
			{
				if ( actorAttacker && npcVictim)
				{
					npcVictim.NoticeActorInGuardArea( actorAttacker );
				}
				if ( !playerVictim )
				{
					actorVictim.RemoveAllBuffsOfType(EET_Confusion);
					//modSigns: also remove knockdown effect
					actorVictim.RemoveAllBuffsOfType(EET_Knockdown);
					actorVictim.RemoveAllBuffsOfType(EET_HeavyKnockdown);
					//modSigns: remove axii guard me effect, if attacker is thePlayer
					if( playerAttacker )
						actorVictim.RemoveAllBuffsOfType(EET_AxiiGuardMe);
				}
				if(playerAttacker && action.IsActionMelee() && !playerAttacker.GetInventory().IsItemFists(weaponId) && playerAttacker.IsLightAttack(attackAction.GetAttackName()) && playerAttacker.CanUseSkill(S_Sword_s05))
				{
					//modSigns: params changed
					bleedCustomEffect.effectType = EET_Bleeding;
					bleedCustomEffect.creator = playerAttacker;
					bleedCustomEffect.sourceName = SkillEnumToName(S_Sword_s05);
					bleedCustomEffect.duration = CalculateAttributeValue(playerAttacker.GetSkillAttributeValue(S_Sword_s05, 'sword_s5_duration', false, true));
					bleedCustomEffect.effectValue.valueMultiplicative = CalculateAttributeValue(playerAttacker.GetSkillAttributeValue(S_Sword_s05, 'sword_s5_dmg_per_sec', false, true));
					//modSigns: apply chance
					chance = CalculateAttributeValue(playerAttacker.GetSkillAttributeValue(S_Sword_s05, 'sword_s5_chance', false, true)) * playerAttacker.GetSkillLevel(S_Sword_s05);
					//modSigns: check resistance
					actorVictim.GetResistValue(theGame.effectMgr.GetBuffResistStat(EET_Bleeding), resPt, resPrc);
					chance *= MaxF(0, 1 - resPrc);
					//Metamorphosis new bonus
					if(((W3PlayerWitcher)playerAttacker).IsMutationActive(EPMT_Mutation12))
						chance *= MaxF(1.0f, 1.0f + ((W3PlayerWitcher)playerAttacker).Mutation12GetBonus());
					//debug log
					//theGame.witcherLog.AddMessage("Crippling strikes bleeding chance: " + chance);
					//theGame.witcherLog.AddMessage("Crippling strikes duration: " + bleedCustomEffect.duration);
					//theGame.witcherLog.AddMessage("Crippling strikes value: " + bleedCustomEffect.effectValue.valueMultiplicative);
					if(RandF() < chance)
						actorVictim.AddEffectCustom(bleedCustomEffect);
				}
			}
			if(actorVictim && wasAlive)
			{
				playsNonAdditiveAnim = actorVictim.ReactToBeingHit( action );
			}
		}
		else
		{
			if( actorVictim.IsAlive() && (canPerformFinisher || canDismember || mutation8Triggered) ) //modSigns
			{
				//modSigns: drain health before initiating kill action so the huge damage from
				//the action won't be attributed to the player
				//if(actorVictim.UsesVitality()) actorVictim.DrainVitality(actorVictim.GetStat(BCS_Vitality) - 1);
				//else if(actorVictim.UsesEssence()) actorVictim.DrainEssence(actorVictim.GetStat(BCS_Essence) - 1);
				//theGame.witcherLog.AddMessage("Target HP: " + actorVictim.GetHealth());
				//and now the kill action
				actorVictim.Kill( 'Finisher', false, thePlayer );
			}
			
			if( !canPerformFinisher && canDismember )
			{
				ProcessDismemberment(wasFrozen, dismemberExplosion);
				toxicCloud = (W3ToxicCloud)action.causer;
				
				if( toxicCloud && toxicCloud.HasExplodingTargetDamages() )
					ProcessToxicCloudDismemberExplosion(toxicCloud.GetExplodingTargetDamages());
				
				//if( IsRequiredAttitudeBetween(thePlayer, action.victim, true) )
				//{
				//	moveTargets = thePlayer.GetMoveTargets();
				//	for( i = 0; i < moveTargets.Size(); i += 1 )
				//	{
				//		if( moveTargets[i].IsHuman() )
				//			moveTargets[i].DrainMorale(20.f);
				//	}
				//} //modSigns
			}
			else if( canPerformFinisher )
			{
				thePlayer.AddTimer( 'DelayedFinisherInputTimer', 0.1f );
				thePlayer.SetFinisherVictim( actorVictim );
				thePlayer.CleanCombatActionBuffer();
				thePlayer.OnBlockAllCombatTickets( true );
				
				if( actorVictim.WillBeUnconscious() )
				{
					actorVictim.SetBehaviorVariable( 'prepareForUnconsciousFinisher', 1.0f );
					actorVictim.ActionRotateToAsync( thePlayer.GetWorldPosition() );
				}
				
				moveTargets = thePlayer.GetMoveTargets();
				
				for( i = 0; i < moveTargets.Size(); i += 1 )
				{
					if ( actorVictim != moveTargets[i] )
						moveTargets[i].SignalGameplayEvent( 'InterruptChargeAttack' );
				}
				
				if( theGame.GetInGameConfigWrapper().GetVarValue('Gameplay', 'AutomaticFinishersEnabled' ) == "true" 
					|| ( (W3PlayerWitcher)playerAttacker && GetWitcherPlayer().IsMutationActive( EPMT_Mutation3 ) )
					||	actorVictim.WillBeUnconscious() )
				{
					actorVictim.AddAbility( 'ForceFinisher', false );
				}
				
				if( actorVictim.HasTag( 'ForceFinisher' ) )
					actorVictim.AddAbility( 'ForceFinisher', false );
				
				actorVictim.SignalGameplayEvent( 'ForceFinisher' );
			}
			else if( weaponName == 'fists' && npcVictim )
			{
				npcVictim.DisableAgony();
			}
			
			thePlayer.FindMoveTarget();
		}
		
		if( attackAction.IsActionMelee() )
		{
			actorAttacker.SignalGameplayEventParamObject( 'HitActionReaction', actorVictim );
			actorVictim.OnHitActionReaction( actorAttacker, weaponName );
		}
		
		
		actorVictim.ProcessHitSound(action, playsNonAdditiveAnim || !actorVictim.IsAlive());
		
		
		
		if(action.IsCriticalHit() && action.DealtDamage() && !actorVictim.IsAlive() && actorAttacker == thePlayer )
			GCameraShake( 0.5, true, actorAttacker.GetWorldPosition(), 10 );
		
		
		//modSigns: drop shield is has no stamina to parry or if low on stamina and player is using heavy attack
		//theGame.witcherLog.AddMessage("Shielded = " + npcVictim.IsShielded(actorAttacker));
		//theGame.witcherLog.AddMessage("Has stamina = " + npcVictim.HasStaminaToParry(attackAction.GetAttackName()));
		if( attackAction && npcVictim && npcVictim.IsShielded( actorAttacker ) /*&& attackAction.IsParried() && actorAttacker.IsHeavyAttack(attackAction.GetAttackName()) &&  npcVictim.GetStaminaPercents() <= 0.1*/ )
		{
			if(!npcVictim.HasStaminaToParry(attackAction.GetAttackName()) || actorAttacker.IsHeavyAttack(attackAction.GetAttackName()) &&  npcVictim.GetStaminaPercents() <= 0.34)
				npcVictim.ProcessShieldDestruction();
		}
		
		
		if( actorVictim && action.CanPlayHitParticle() && ( action.DealsAnyDamage() || (attackAction && attackAction.IsParried()) ) )
			actorVictim.PlayHitEffect(action);
			

		if( action.victim.HasAbility('mon_nekker_base') && !actorVictim.CanPlayHitAnim() && !((CBaseGameplayEffect) action.causer) ) 
		{
			
			actorVictim.PlayEffect(theGame.params.LIGHT_HIT_FX);
			actorVictim.SoundEvent("cmb_play_hit_light");
		}
			
		
		if(actorVictim && playerAttacker && action.IsActionMelee() && thePlayer.inv.IsItemFists(weaponId) )
		{
			actorVictim.SignalGameplayEvent( 'wasHitByFists' );	
				
			if(MonsterCategoryIsMonster(victimMonsterCategory))
			{
				if(!victimCanBeHitByFists)
				{
					playerAttacker.ReactToReflectedAttack(actorVictim);
				}
				else
				{			
					actorVictim.GetResistValue(CDS_PhysicalRes, points, percents);
				
					if(percents >= theGame.params.MONSTER_RESIST_THRESHOLD_TO_REFLECT_FISTS)
						playerAttacker.ReactToReflectedAttack(actorVictim);
				}
			}			
		}
		
		
		ProcessSparksFromNoDamage();
		
		
		if(attackAction && attackAction.IsActionMelee() && actorAttacker && playerVictim && attackAction.IsCountered() && (W3PlayerWitcher)playerVictim)
		{
			//theGame.witcherLog.AddMessage("countered");
			//GetWitcherPlayer().SetRecentlyCountered(true);
			//GetWitcherPlayer().AddTimer('ResetRecentlyCountered', 3.0);
			actorAttacker.SetWasCountered(true);
		}
		
		CleanupMutation8Finisher(); //modSigns
		
		
		
		
		if(attackAction && !action.IsDoTDamage() && (playerAttacker || playerVictim) && (attackAction.IsParried() || attackAction.IsCountered()) )
		{
			theGame.VibrateControllerLight();
		}
	}
	
	//modSigns: reworked to support alive targets
	private function CanDismember( wasFrozen : bool, out dismemberExplosion : bool, out weaponName : name ) : bool
	{
		var dismember			: bool;
		var dismemberChance 	: int;
		var petard 				: W3Petard;
		var bolt 				: W3BoltProjectile;
		var arrow 				: W3ArrowProjectile;
		var inv					: CInventoryComponent;
		var toxicCloud			: W3ToxicCloud;
		var witcher				: W3PlayerWitcher;
		var i					: int;
		var secondaryWeapon		: bool;
		
		petard = (W3Petard)action.causer;
		bolt = (W3BoltProjectile)action.causer;
		arrow = (W3ArrowProjectile)action.causer;
		toxicCloud = (W3ToxicCloud)action.causer;
		
		if( playerAttacker )
			secondaryWeapon = playerAttacker.inv.ItemHasTag( weaponId, 'SecondaryWeapon' ) || playerAttacker.inv.ItemHasTag( weaponId, 'Wooden' );
		
		dismemberExplosion = false;
		weaponName = '';
		
		if( actorVictim.HasAbility( 'DisableDismemberment' ) )
			return false;
		
		if( actorVictim.HasTag( 'DisableDismemberment' ) )
			return false;
		
		if( actorVictim.WillBeUnconscious() )
			return false;
		
		if( playerAttacker && secondaryWeapon )
			return false;
		
		if( actorVictim.IsAlive() && !CanDismemberAliveTarget( actorVictim ) )
			return false;
		
		if( arrow && !wasFrozen )
			return false;
		
		if( !actorVictim.IsAlive() && actorAttacker.HasAbility( 'ForceDismemberment' ) )
		{
			dismember = true;
			dismemberExplosion = action.HasForceExplosionDismemberment();
		}
		else if( !actorVictim.IsAlive() && wasFrozen )
		{
			dismember = true;
			dismemberExplosion = action.HasForceExplosionDismemberment();
		}						
		else if( !actorVictim.IsAlive() && ((petard && petard.DismembersOnKill()) || (bolt && bolt.DismembersOnKill())) )
		{
			dismember = true;
			dismemberExplosion = action.HasForceExplosionDismemberment();
		}
		else if( !actorVictim.IsAlive() && (W3Effect_YrdenHealthDrain)action.causer )
		{
			dismember = true;
			dismemberExplosion = true;
		}
		else if( !actorVictim.IsAlive() && toxicCloud && toxicCloud.HasExplodingTargetDamages() )
		{
			dismember = true;
			dismemberExplosion = true;
		}
		else
		{
			inv = actorAttacker.GetInventory();
			weaponName = inv.GetItemName( weaponId );
			
			if( attackAction 
				&& !inv.IsItemSteelSwordUsableByPlayer(weaponId) 
				&& !inv.IsItemSilverSwordUsableByPlayer(weaponId) 
				&& weaponName != 'polearm'
				&& weaponName != 'fists_lightning' 
				&& weaponName != 'fists_fire' )
			{
				dismember = false;
			}			
			else if ( !actorVictim.IsAlive() && action.IsCriticalHit() )
			{
				dismember = true;
				dismemberExplosion = action.HasForceExplosionDismemberment();
			}
			else if ( !actorVictim.IsAlive() && action.HasForceExplosionDismemberment() )
			{
				dismember = true;
				dismemberExplosion = true;
			}
			else
			{
				if( mutation8Triggered ) //modSigns
				{
					dismemberChance = 100;
				}
				else if( !confusionInstakillTested && IsAxiiInstakillTarget() ) //modSigns: redone
				{
					//alive enemy
					dismemberChance = GetAxiiInstakillChance();
					confusionInstakillTested = true;
					//theGame.witcherLog.AddMessage("dismemberChance = " + dismemberChance);
				}
				else if ( !actorVictim.IsAlive() )
				{
					dismemberChance = theGame.params.DISMEMBERMENT_ON_DEATH_CHANCE;
					
					if(playerAttacker && playerAttacker.forceDismember)
					{
						dismemberChance = thePlayer.forceDismemberChance;
						dismemberExplosion = thePlayer.forceDismemberExplosion;
					}
					
					if(attackAction)
					{
						dismemberChance += RoundMath(100 * CalculateAttributeValue(inv.GetItemAttributeValue(weaponId, 'dismember_chance')));
						dismemberExplosion = attackAction.HasForceExplosionDismemberment();
					}
					
					witcher = (W3PlayerWitcher)actorAttacker;
					if(witcher && witcher.CanUseSkill(S_Perk_03))
						dismemberChance += RoundMath(100 * CalculateAttributeValue(witcher.GetSkillAttributeValue(S_Perk_03, 'dismember_chance', false, true)));
					
					if( ( W3PlayerWitcher )playerAttacker && attackAction.IsActionMelee() && GetWitcherPlayer().IsMutationActive(EPMT_Mutation3) )	
					{
						if( thePlayer.inv.IsItemSteelSwordUsableByPlayer( weaponId ) || thePlayer.inv.IsItemSilverSwordUsableByPlayer( weaponId ) )
						{
							dismemberChance = 100;
						}
					}
				}
				
				dismemberChance = Clamp(dismemberChance, 0, 100);
				
				if (RandRange(100) < dismemberChance)
					dismember = true;
				else
					dismember = false;
			}
		}

		return dismember;
	}	
	
	//modSigns
	private function CanDismemberAliveTarget( actorVictim : CActor ) : bool
	{
		return ( actorVictim.HasBuff(EET_Confusion) || actorVictim.HasBuff(EET_AxiiGuardMe) || mutation8Triggered )
		&& actorVictim.IsVulnerable()
		&& !actorVictim.HasAbility('DisableDismemberment')
		&& !actorVictim.HasAbility('InstantKillImmune');
	}
	
	//modSigns: convoluted logic rewritten
	private function CanPerformFinisher( actorVictim : CActor ) : bool
	{
		var finisherChance 			: int;
		var areEnemiesAttacking		: bool;
		var i						: int;
		var victimToPlayerVector, playerPos	: Vector;
		var item 					: SItemUniqueId;
		var moveTargets				: array<CActor>;
		var res						: bool;
		var size					: int;
		var npc						: CNewNPC;
		
		if ( (W3ReplacerCiri)thePlayer || playerVictim || !playerAttacker || !thePlayer.IsAlive() || thePlayer.isInFinisher || thePlayer.IsInAir() || thePlayer.IsUsingVehicle() )
			return false;
		
		if ( thePlayer.IsCurrentSignChanneled() )
			return false;
		
		if ( !attackAction || !attackAction.IsActionMelee() )
			return false;
		
		if ( thePlayer.IsSecondaryWeaponHeld() || !thePlayer.IsWeaponHeld( 'steelsword') && !thePlayer.IsWeaponHeld( 'silversword') )
			return false;
		
		item = thePlayer.inv.GetItemFromSlot( 'l_weapon' );
		
		if ( thePlayer.inv.IsIdValid( item ) )
			return false;
		
		if ( actorVictim.HasAbility( 'DisableFinishers' ) )
			return false;
		
		if ( !actorVictim.IsHuman() || actorVictim.IsWoman() )
			return false;
		
		if ( actorVictim.WillBeUnconscious() && !theGame.GetDLCManager().IsEP2Available() )
			return false;
		
		if ( actorVictim.IsKnockedUnconscious() || actorVictim.HasBuff( EET_Knockdown ) || actorVictim.HasBuff( EET_Ragdoll ) || actorVictim.HasBuff( EET_Frozen ) )
			return false;
		
		if ( actorVictim.IsAlive() && !CanPerformFinisherOnAliveTarget(actorVictim) )
			return false;
		
		moveTargets = thePlayer.GetMoveTargets();	
		size = moveTargets.Size();
		playerPos = thePlayer.GetWorldPosition();
	
		if ( size > 0 )
		{
			areEnemiesAttacking = false;			
			for ( i = 0; i < size; i += 1 )
			{
				npc = (CNewNPC)moveTargets[i];
				if ( npc && VecDistanceSquared(playerPos, moveTargets[i].GetWorldPosition()) < 7 && npc.IsAttacking() && npc != actorVictim )
				{
					areEnemiesAttacking = true;
					break;
				}
			}
		}
		
		victimToPlayerVector = actorVictim.GetWorldPosition() - playerPos;
		
		npc = (CNewNPC)actorVictim;
		if( mutation8Triggered ) //modSigns
		{
			finisherChance = 100;
		}
		else if( !confusionInstakillTested && IsAxiiInstakillTarget() ) //modSigns: redone
		{
			//confused alive enemy
			//finisherChance = RoundMath(100*ExpF(-PowF(actorVictim.GetHealthPercents(), 2)*4.8));
			finisherChance = GetAxiiInstakillChance();
			confusionInstakillTested = true;
			//theGame.witcherLog.AddMessage("finisherChance = " + finisherChance);
		}
		else if( !actorVictim.IsAlive() )
		{
			if( actorVictim.HasAbility('ForceFinisher') || GetWitcherPlayer().IsMutationActive(EPMT_Mutation3) )
			{
				finisherChance = 100; //100% chance for forced finisher and mutation
			}
			else if( npc.currentLevel - thePlayer.GetLevel() >= theGame.params.LEVEL_DIFF_DEADLY )
			{
				finisherChance = 0; //0% chance for deadly enemy
			}
			else if( thePlayer.GetLevel() - npc.currentLevel  >= theGame.params.LEVEL_DIFF_DEADLY )
			{
				finisherChance = 100; //100% chance for very low level enemy
			}
			else if( size <= 1 )
			{
				finisherChance = 100; //100% chance for lone enemy
			}
			else //base finisher chance
			{
				finisherChance = theGame.params.FINISHER_ON_DEATH_CHANCE;
			}
		}
		else
		{
			finisherChance = 0;
		}
		finisherChance = Clamp(finisherChance, 0, 100);
		//modSigns: debug
		//theGame.witcherLog.AddMessage("finisherChance = " + finisherChance);
			
		if ( actorVictim.HasTag('ForceFinisher') )
		{
			finisherChance = 100;
			areEnemiesAttacking = false;
		}
			
		if ( thePlayer.forceFinisher )
		{
			res = true;
		}
		else
		{
			res = ( RandRange(100) < finisherChance && actorVictim.GetAttitude( thePlayer ) == AIA_Hostile
					&& !areEnemiesAttacking && AbsF( victimToPlayerVector.Z ) < 0.4f
					&& ( theGame.GetWorld().NavigationCircleTest( actorVictim.GetWorldPosition(), 2.f ) || actorVictim.HasTag('ForceFinisher') ) );
		}

		if ( res )
		{
			if ( !actorVictim.IsAlive() && !actorVictim.WillBeUnconscious() )
				actorVictim.AddAbility( 'DisableFinishers', false );
		}
		
		return res;
	}
	
	private function CanPerformFinisherOnAliveTarget( actorVictim : CActor ) : bool
	{
		return actorVictim.IsHuman() 
		&& ( actorVictim.HasBuff(EET_Confusion) || actorVictim.HasBuff(EET_AxiiGuardMe) || mutation8Triggered )
		&& actorVictim.IsVulnerable()
		&& !actorVictim.HasAbility('DisableFinisher')
		&& !actorVictim.HasAbility('InstantKillImmune');
	}
	
	
	
	
	
	
	private function ProcessActionBuffs() : bool
	{
		var inv : CInventoryComponent;
		var ret : bool;
	
		
		if(!action.victim.IsAlive() || action.WasDodged() || (attackAction && attackAction.IsActionMelee() && !attackAction.ApplyBuffsIfParried() && attackAction.CanBeParried() && attackAction.IsParried()) )
			return true;
			
		
		//ApplyQuenBuffChanges(); //modSigns: handled by effects manager
	
		
		if( actorAttacker == thePlayer && action.IsActionWitcherSign() && action.IsCriticalHit() && GetWitcherPlayer().IsMutationActive( EPMT_Mutation2 ) && action.HasBuff( EET_Burning ) )
		{
			action.SetBuffSourceName( 'Mutation2ExplosionValid' );
		}
	
		
		if(actorVictim && action.GetEffectsCount() > 0)
			ret = actorVictim.ApplyActionEffects(action);
		else
			ret = false;
			
		
		if(actorAttacker && actorVictim)
		{
			inv = actorAttacker.GetInventory();
			actorAttacker.ProcessOnHitEffects(actorVictim, inv.IsItemSilverSwordUsableByPlayer(weaponId), inv.IsItemSteelSwordUsableByPlayer(weaponId), action.IsActionWitcherSign() );
		}
		
		return ret;
	}
	
	
	//private function ApplyQuenBuffChanges() //modSigns: effects are handled in effect manager
	//{
	//	var npc : CNewNPC;
	//	var protection : bool;
	//	var witcher : W3PlayerWitcher;
	//	var quenEntity : W3QuenEntity;
	//	var i : int;
	//	var buffs : array<EEffectType>;
	//
	//	if(!actorVictim || !actorVictim.HasAlternateQuen())
	//		return;
	//	
	//	npc = (CNewNPC)actorVictim;
	//	if(npc)
	//	{
	//		if(!action.DealsAnyDamage())
	//			protection = true;
	//	}
	//	else
	//	{
	//		witcher = (W3PlayerWitcher)actorVictim;
	//		if(witcher)
	//		{
	//			quenEntity = (W3QuenEntity)witcher.GetCurrentSignEntity();
	//			if(quenEntity.GetBlockedAllDamage())
	//			{
	//				protection = true;
	//			}
	//		}
	//	}
	//	
	//	if(!protection)
	//		return;
	//		
	//	action.GetEffectTypes(buffs);
	//	for(i=buffs.Size()-1; i>=0; i -=1)
	//	{
	//		if(buffs[i] == EET_KnockdownTypeApplicator || IsKnockdownEffectType(buffs[i]))
	//			continue;
	//			
	//		action.RemoveBuff(i);
	//	}
	//}
	
	
	
	
	private function ProcessDismemberment(wasFrozen : bool, dismemberExplosion : bool )
	{
		var hitDirection		: Vector;
		var usedWound			: name;
		var npcVictim			: CNewNPC;
		var wounds				: array< name >;
		var i					: int;
		var petard 				: W3Petard;
		var bolt 				: W3BoltProjectile;		
		var forcedRagdoll		: bool;
		var isExplosion			: bool;
		var dismembermentComp 	: CDismembermentComponent;
		var specialWounds		: array< name >;
		var useHitDirection		: bool;
		var fxMask				: EDismembermentEffectTypeFlags;
		var template			: CEntityTemplate;
		var ent					: CEntity;
		var signType			: ESignType;
		
		if(!actorVictim)
			return;
			
		dismembermentComp = (CDismembermentComponent)(actorVictim.GetComponentByClassName( 'CDismembermentComponent' ));
		if(!dismembermentComp)
			return;
			
		if(wasFrozen)
		{
			ProcessFrostDismemberment();
			return;
		}
		
		forcedRagdoll = false;
		
		
		petard = (W3Petard)action.causer;
		bolt = (W3BoltProjectile)action.causer;
		
		if( dismemberExplosion || (attackAction && ( attackAction.GetAttackName() == 'attack_explosion' || attackAction.HasForceExplosionDismemberment() ))
			|| (petard && petard.DismembersOnKill()) || (bolt && bolt.DismembersOnKill()) )
		{
			isExplosion = true;
		}
		else
		{
			isExplosion = false;
		}
		
		
		if(playerAttacker && thePlayer.forceDismember && IsNameValid(thePlayer.forceDismemberName))
		{
			usedWound = thePlayer.forceDismemberName;
		}
		else
		{	
			
			if(isExplosion)
			{
				dismembermentComp.GetWoundsNames( wounds, WTF_Explosion );	

				
				if( action.IsMutation2PotentialKill() )
				{
					
					for( i=wounds.Size()-1; i>=0; i-=1 )
					{
						if( !StrContains( wounds[ i ], "_ep2" ) )
						{
							wounds.EraseFast( i );
						}
					}
					
					signType = action.GetSignType();
					if( signType == ST_Aard )
					{
						fxMask = DETF_Aaard;
					}
					else if( signType == ST_Igni )
					{
						fxMask = DETF_Igni;
					}
					else if( signType == ST_Yrden )
					{
						fxMask = DETF_Yrden;
					}
					else if( signType == ST_Quen )
					{
						fxMask = DETF_Quen;
					}
				}
				else
				{
					fxMask = 0;
				}
				
				if ( wounds.Size() > 0 )
					usedWound = wounds[ RandRange( wounds.Size() ) ];
					
				if ( usedWound )
					StopVO( actorVictim ); 
			}
			else if(attackAction || action.GetBuffSourceName() == "riderHit")
			{
				if  ( attackAction.GetAttackTypeName() == 'sword_s2' || thePlayer.isInFinisher )
					useHitDirection = true;
				
				if ( useHitDirection ) 
				{
					hitDirection = actorAttacker.GetSwordTipMovementFromAnimation( attackAction.GetAttackAnimName(), attackAction.GetHitTime(), 0.1, attackAction.GetWeaponEntity() );
					usedWound = actorVictim.GetNearestWoundForBone( attackAction.GetHitBoneIndex(), hitDirection, WTF_Cut );
				}
				else
				{			
					
					dismembermentComp.GetWoundsNames( wounds );
					
					
					if(wounds.Size() > 0)
					{
						dismembermentComp.GetWoundsNames( specialWounds, WTF_Explosion );
						for ( i = 0; i < specialWounds.Size(); i += 1 )
						{
							wounds.Remove( specialWounds[i] );
						}
						
						if(wounds.Size() > 0)
						{
							
							dismembermentComp.GetWoundsNames( specialWounds, WTF_Frost );
							for ( i = 0; i < specialWounds.Size(); i += 1 )
							{
								wounds.Remove( specialWounds[i] );
							}
							
							
							if ( wounds.Size() > 0 )
								usedWound = wounds[ RandRange( wounds.Size() ) ];
						}
					}
				}
			}
		}
		
		if ( usedWound )
		{
			npcVictim = (CNewNPC)action.victim;
			if(npcVictim)
				npcVictim.DisableAgony();			
			
			actorVictim.SetDismembermentInfo( usedWound, actorVictim.GetWorldPosition() - actorAttacker.GetWorldPosition(), forcedRagdoll, fxMask );
			actorVictim.AddTimer( 'DelayedDismemberTimer', 0.05f );
			actorVictim.SetBehaviorVariable( 'dismemberAnim', 1.0 );
			
			
			if ( usedWound == 'explode_02' || usedWound == 'explode2' || usedWound == 'explode_02_ep2' || usedWound == 'explode2_ep2')
			{
				ProcessDismembermentDeathAnim( usedWound, true, EFDT_LegLeft );
				actorVictim.SetKinematic( false );
				
			}
			else
			{
				ProcessDismembermentDeathAnim( usedWound, false );
			}
			
			
			if( usedWound == 'explode_01_ep2' || usedWound == 'explode1_ep2' || usedWound == 'explode_02_ep2' || usedWound == 'explode2_ep2' )
			{
				template = (CEntityTemplate) LoadResource( "explosion_dismember_force" );
				ent = theGame.CreateEntity( template, npcVictim.GetWorldPosition(), , , , true );
				ent.DestroyAfter( 5.f );
			}
			
			DropEquipmentFromDismember( usedWound, true, true );
			
			if( attackAction && actorAttacker == thePlayer )			
				GCameraShake( 0.5, true, actorAttacker.GetWorldPosition(), 10);
				
			if(playerAttacker)
				theGame.VibrateControllerHard();	
				
			
			if( dismemberExplosion && (W3AardProjectile)action.causer )
			{
				npcVictim.AddTimer( 'AardDismemberForce', 0.00001f );
			}
		}
		else
		{
			LogChannel( 'Dismemberment', "ERROR: No wound found to dismember on entity but entity supports dismemberment!!!" );
		}
	}
	
	function ApplyForce()
	{
		var size, i : int;
		var victim : CNewNPC;
		var fromPos, toPos : Vector;
		var comps : array<CComponent>;
		var impulse : Vector;
		
		victim = (CNewNPC)action.victim;
		toPos = victim.GetWorldPosition();
		toPos.Z += 1.0f;
		fromPos = toPos;
		fromPos.Z -= 2.0f;
		impulse = VecNormalize( toPos - fromPos.Z ) * 10;
		
		comps = victim.GetComponentsByClassName('CComponent');
		victim.GetVisualDebug().AddArrow( 'applyForce', fromPos, toPos, 1, 0.2f, 0.2f, true, Color( 0,0,255 ), true, 5.0f );
		size = comps.Size();
		for( i = 0; i < size; i += 1 )
		{
			comps[i].ApplyLocalImpulseToPhysicalObject( impulse );
		}
	}
	
	private function ProcessFrostDismemberment()
	{
		var dismembermentComp 	: CDismembermentComponent;
		var wounds				: array< name >;
		var wound				: name;
		var i, fxMask			: int;
		var npcVictim			: CNewNPC;
		
		dismembermentComp = (CDismembermentComponent)(actorVictim.GetComponentByClassName( 'CDismembermentComponent' ));
		if(!dismembermentComp)
			return;
		
		dismembermentComp.GetWoundsNames( wounds, WTF_Frost );
		
		
		
		if( theGame.GetDLCManager().IsEP2Enabled() )
		{
			fxMask = DETF_Mutation6;
			
			
			for( i=wounds.Size()-1; i>=0; i-=1 )
			{
				if( !StrContains( wounds[ i ], "_ep2" ) )
				{
					wounds.EraseFast( i );
				}
			}
		}
		else
		{
			fxMask = 0;
		}
		
		if ( wounds.Size() > 0 )
		{
			wound = wounds[ RandRange( wounds.Size() ) ];
		}
		else
		{
			return;
		}
		
		npcVictim = (CNewNPC)action.victim;
		if(npcVictim)
		{
			npcVictim.DisableAgony();
			StopVO( npcVictim );
		}
		
		actorVictim.SetDismembermentInfo( wound, actorVictim.GetWorldPosition() - actorAttacker.GetWorldPosition(), true, fxMask );
		actorVictim.AddTimer( 'DelayedDismemberTimer', 0.05f );
		if( wound == 'explode_02' || wound == 'explode2' || wound == 'explode_02_ep2' || wound == 'explode2_ep2' )
		{
			ProcessDismembermentDeathAnim( wound, true, EFDT_LegLeft );
			npcVictim.SetKinematic(false);
		}
		else
		{
			ProcessDismembermentDeathAnim( wound, false );
		}
		DropEquipmentFromDismember( wound, true, true );
		
		if( attackAction )			
			GCameraShake( 0.5, true, actorAttacker.GetWorldPosition(), 10);
			
		if(playerAttacker)
			theGame.VibrateControllerHard();	
	}
	
	
	private function ProcessDismembermentDeathAnim( nearestWound : name, forceDeathType : bool, optional deathType : EFinisherDeathType )
	{
		var dropCurveName : name;
		
		if ( forceDeathType )
		{
			if ( deathType == EFDT_Head )
				StopVO( actorVictim );
				
			actorVictim.SetBehaviorVariable( 'FinisherDeathType', (int)deathType );
			
			return;
		}
		
		dropCurveName = ( (CDismembermentComponent)(actorVictim.GetComponentByClassName( 'CDismembermentComponent' )) ).GetMainCurveName( nearestWound );
		
		if ( dropCurveName == 'head' )
		{
			actorVictim.SetBehaviorVariable( 'FinisherDeathType', (int)EFDT_Head );
			StopVO( actorVictim );
		}
		else if ( dropCurveName == 'torso_left' || dropCurveName == 'torso_right' || dropCurveName == 'torso' )
			actorVictim.SetBehaviorVariable( 'FinisherDeathType', (int)EFDT_Torso );
		else if ( dropCurveName == 'arm_right' )
			actorVictim.SetBehaviorVariable( 'FinisherDeathType', (int)EFDT_ArmRight );
		else if ( dropCurveName == 'arm_left' )
			actorVictim.SetBehaviorVariable( 'FinisherDeathType', (int)EFDT_ArmLeft );
		else if ( dropCurveName == 'leg_left' )
			actorVictim.SetBehaviorVariable( 'FinisherDeathType', (int)EFDT_LegLeft );
		else if ( dropCurveName == 'leg_right' )
			actorVictim.SetBehaviorVariable( 'FinisherDeathType', (int)EFDT_LegRight );
		else 
			actorVictim.SetBehaviorVariable( 'FinisherDeathType', (int)EFDT_None );
	}
	
	private function StopVO( actor : CActor )
	{
		actor.SoundEvent( "grunt_vo_death_stop", 'head' );
	}

	private function DropEquipmentFromDismember( nearestWound : name, optional dropLeft, dropRight : bool )
	{
		var dropCurveName : name;
		
		if( actorVictim.HasAbility( 'DontDropWeaponsOnDismemberment' ) )
		{
			return;
		}
		
		dropCurveName = ( (CDismembermentComponent)(actorVictim.GetComponentByClassName( 'CDismembermentComponent' )) ).GetMainCurveName( nearestWound );
		
		if ( ChangeHeldItemAppearance() )
		{
			actorVictim.SignalGameplayEvent('DropWeaponsInDeathTask');
			return;
		}
		
		if ( dropLeft || dropRight )
		{
			
			if ( dropLeft )
				actorVictim.DropItemFromSlot( 'l_weapon', true );
			
			if ( dropRight )
				actorVictim.DropItemFromSlot( 'r_weapon', true );			
			
			return;
		}
		
		if ( dropCurveName == 'arm_right' )
			actorVictim.DropItemFromSlot( 'r_weapon', true );
		else if ( dropCurveName == 'arm_left' )
			actorVictim.DropItemFromSlot( 'l_weapon', true );
		else if ( dropCurveName == 'torso_left' || dropCurveName == 'torso_right' || dropCurveName == 'torso' )
		{
			actorVictim.DropItemFromSlot( 'l_weapon', true );
			actorVictim.DropItemFromSlot( 'r_weapon', true );
		}			
		else if ( dropCurveName == 'head' || dropCurveName == 'leg_left' || dropCurveName == 'leg_right' )
		{
			if(  RandRange(100) < 50 )
				actorVictim.DropItemFromSlot( 'l_weapon', true );
			
			if(  RandRange(100) < 50 )
				actorVictim.DropItemFromSlot( 'r_weapon', true );
		} 
	}
	
	function ChangeHeldItemAppearance() : bool
	{
		var inv : CInventoryComponent;
		var weapon : SItemUniqueId;
		
		inv = actorVictim.GetInventory();
		
		weapon = inv.GetItemFromSlot('l_weapon');
		
		if ( inv.IsIdValid( weapon ) )
		{
			if ( inv.ItemHasTag(weapon,'bow') || inv.ItemHasTag(weapon,'crossbow') )
				inv.GetItemEntityUnsafe(weapon).ApplyAppearance("rigid");
			return true;
		}
		
		weapon = inv.GetItemFromSlot('r_weapon');
		
		if ( inv.IsIdValid( weapon ) )
		{
			if ( inv.ItemHasTag(weapon,'bow') || inv.ItemHasTag(weapon,'crossbow') )
				inv.GetItemEntityUnsafe(weapon).ApplyAppearance("rigid");
			return true;
		}
	
		return false;
	}
	
	
	//modSigns: moved to witcher player, ReduceDamage function
	/*private function GetOilProtectionAgainstMonster(dmgType : name, out resist : float, out reduct : float)
	{
		var i : int;
		var heldWeapons : array< SItemUniqueId >;
		var weapon : SItemUniqueId;
		
		resist = 0;
		reduct = 0;
		
		
		heldWeapons = thePlayer.inv.GetHeldWeapons();
		
		
		for( i=0; i<heldWeapons.Size(); i+=1 )
		{
			if( !thePlayer.inv.IsItemFists( heldWeapons[ i ] ) )
			{
				weapon = heldWeapons[ i ];
				break;
			}
		}
		
		
		if( !thePlayer.inv.IsIdValid( weapon ) )
		{
			return;
		}
	
		
		if( !thePlayer.inv.ItemHasActiveOilApplied( weapon, attackerMonsterCategory ) )
		{
			return;
		}
		
		resist = CalculateAttributeValue( thePlayer.GetSkillAttributeValue( S_Alchemy_s05, 'defence_bonus', false, true ) );		
	}*/
	
	
	private function ProcessToxicCloudDismemberExplosion(damages : array<SRawDamage>)
	{
		var act : W3DamageAction;
		var i, j : int;
		var ents : array<CGameplayEntity>;
		
		
		if(damages.Size() == 0)
		{
			LogAssert(false, "W3DamageManagerProcessor.ProcessToxicCloudDismemberExplosion: trying to process but no damages are passed! Aborting!");
			return;
		}		
		
		
		FindGameplayEntitiesInSphere(ents, action.victim.GetWorldPosition(), 3, 1000, , FLAG_OnlyAliveActors);
		
		
		for(i=0; i<ents.Size(); i+=1)
		{
			act = new W3DamageAction in this;
			act.Initialize(action.attacker, ents[i], action.causer, 'Dragons_Dream_3', EHRT_Heavy, CPS_Undefined, false, false, false, true);
			
			for(j=0; j<damages.Size(); j+=1)
			{
				act.AddDamage(damages[j].dmgType, damages[j].dmgVal);
			}
			
			theGame.damageMgr.ProcessAction(act);
			delete act;
		}
	}
	
	
	private final function ProcessSparksFromNoDamage()
	{
		var sparksEntity, weaponEntity : CEntity;
		var weaponTipPosition : Vector;
		var weaponSlotMatrix : Matrix;
		
		
		if(!playerAttacker || !attackAction || !attackAction.IsActionMelee() || attackAction.DealsAnyDamage())
			return;
		
		
		if( ( !attackAction.DidArmorReduceDamageToZero() && !actorVictim.IsVampire() && ( attackAction.IsParried() || attackAction.IsCountered() ) ) 
			|| ( ( attackAction.IsParried() || attackAction.IsCountered() ) && !actorVictim.IsHuman() && !actorVictim.IsVampire() )
			|| actorVictim.IsCurrentlyDodging() )
			return;
		
		
		if(actorVictim.HasTag('NoSparksOnArmorDmgReduced'))
			return;
		
		
		if (!actorVictim.GetGameplayVisibility())
			return;
		
		
		weaponEntity = playerAttacker.inv.GetItemEntityUnsafe(weaponId);
		weaponEntity.CalcEntitySlotMatrix( 'blood_fx_point', weaponSlotMatrix );
		weaponTipPosition = MatrixGetTranslation( weaponSlotMatrix );
		
		
		sparksEntity = theGame.CreateEntity( (CEntityTemplate)LoadResource( 'sword_colision_fx' ), weaponTipPosition );
		sparksEntity.PlayEffect('sparks');
	}
	
	private function ProcessPreHitModifications()
	{
		var fireDamage, totalDmg, maxHealth, currHealth : float;
		var attribute, min, max : SAbilityAttributeValue;
		var infusion : ESignType;
		var hack : array< SIgniEffects >;
		var dmgValTemp : float;
		var igni : W3IgniEntity;
		var quen : W3QuenEntity;

		if( actorVictim.HasAbility( 'HitWindowOpened' ) && !action.IsDoTDamage() )
		{
			if( actorVictim.HasTag( 'fairytale_witch' ) )
			{
				
				
				
				
				
				
					((CNewNPC)actorVictim).SetBehaviorVariable( 'shouldBreakFlightLoop', 1.0 );
				
			}
			else
			{
				quen = (W3QuenEntity)action.causer; 
			
				if( !quen )
				{
					if( actorVictim.HasTag( 'dettlaff_vampire' ) )
					{
						actorVictim.StopEffect( 'shadowdash' );
					}
					
					action.ClearDamage();
					if( action.IsActionMelee() )
					{
						actorVictim.PlayEffect( 'special_attack_break' );
					}
					actorVictim.SetBehaviorVariable( 'repelType', 0 );
					
					actorVictim.AddEffectDefault( EET_CounterStrikeHit, thePlayer ); 
					action.RemoveBuffsByType( EET_KnockdownTypeApplicator );
				}
			}
			
			((CNewNPC)actorVictim).SetHitWindowOpened( false );
		}
		
		
		
		if(playerAttacker == GetWitcherPlayer() && attackAction && attackAction.IsActionMelee() && GetWitcherPlayer().HasRunewordActive('Runeword 1 _Stats')) //modSigns
		{
			infusion = GetWitcherPlayer().GetRunewordInfusionType();
			
			switch(infusion)
			{
				case ST_Aard:
					action.AddEffectInfo(EET_KnockdownTypeApplicator);
					action.SetProcessBuffsIfNoDamage(true);
					attackAction.SetApplyBuffsIfParried(true);
					actorVictim.CreateFXEntityAtPelvis( 'runeword_1_aard', false );
					break;
				case ST_Axii:
					//modSigns: custom duration
					attribute = thePlayer.GetAttributeValue('runeword1_confusion_duration');
					action.AddEffectInfo(EET_Confusion, attribute.valueAdditive);
					action.SetProcessBuffsIfNoDamage(true);
					attackAction.SetApplyBuffsIfParried(true);
					break;
				case ST_Igni:
					
					totalDmg = action.GetDamageValueTotal();
					attribute = thePlayer.GetAttributeValue('runeword1_fire_dmg');
					fireDamage = totalDmg * attribute.valueMultiplicative;
					action.AddDamage(theGame.params.DAMAGE_NAME_FIRE, fireDamage);
					
					
					action.SetCanPlayHitParticle(false);					
					action.victim.AddTimer('Runeword1DisableFireFX', 1.f);
					action.SetHitReactionType(EHRT_Heavy);	
					action.victim.PlayEffect('critical_burning');
					break;
				case ST_Yrden:
					attribute = thePlayer.GetAttributeValue('runeword1_yrden_duration');
					action.AddEffectInfo(EET_Slowdown, attribute.valueAdditive);
					action.SetProcessBuffsIfNoDamage(true);
					attackAction.SetApplyBuffsIfParried(true);
					break;
				default:		
					break;
			}
		}
		
		
		if( playerAttacker && actorVictim && (W3PlayerWitcher)playerAttacker && GetWitcherPlayer().IsMutationActive( EPMT_Mutation9 ) && (W3BoltProjectile)action.causer )
		{
			maxHealth = actorVictim.GetMaxHealth();
			currHealth = actorVictim.GetHealth();
			
			
			if( AbsF( maxHealth - currHealth ) < 1.f )
			{
				theGame.GetDefinitionsManager().GetAbilityAttributeValue('Mutation9', 'health_reduction', min, max);
				actorVictim.ForceSetStat( actorVictim.GetUsedHealthType(), maxHealth * ( 1 - min.valueMultiplicative ) );
			}
			
			
			action.AddEffectInfo( EET_KnockdownTypeApplicator, 0.1f, , , , 1.f );
		}
	}
}

exec function ForceDismember( b: bool, optional chance : int, optional n : name, optional e : bool )
{
	var temp : CR4Player;
	
	temp = thePlayer;
	temp.forceDismember = b;
	temp.forceDismemberName = n;
	temp.forceDismemberChance = chance;
	temp.forceDismemberExplosion = e;
} 

exec function ForceFinisher( b: bool, optional n : name, optional rightStance : bool )
{
	var temp : CR4Player;
	
	temp = thePlayer;
	temp.forcedStance = rightStance;
	temp.forceFinisher = b;
	temp.forceFinisherAnimName = n;
} 
