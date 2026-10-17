// W3PlayerWitcher.OnTakeDamage and CActor.OnTakeDamage, replaced for the mutations' hunks: MUT-05
// Bloodbath's bonus lowered by damage taken (5.x: the effect ends); MUT-10 Mutated Skin's trigger and
// the Vitality drain it takes over; MUT-12: no death trigger for Mutation 11.
// See docs/features/mut.md.

@replaceMethod(W3PlayerWitcher)
function OnTakeDamage( action : W3DamageAction)
{
	var currVitality, rgnVitality, hpTriggerTreshold : float;
	var healingFactor, healingBase : float;
	var abilityName : name;
	var abilityCount, maxStack, itemDurability : float;
	var addAbility : bool;
	var min, max : SAbilityAttributeValue;
	var mutagenQuen : W3SignEntity;
	var equipped : array<SItemUniqueId>;
	var i : int;
	var killSourceName : string;
	var aerondight	: W3Effect_Aerondight;

	currVitality = GetStat(BCS_Vitality);

	
	if(action.processedDmg.vitalityDamage >= currVitality)
	{
		killSourceName = action.GetBuffSourceName();

		
		if( killSourceName != "Quest" && killSourceName != "Kill Trigger" && killSourceName != "Trap" && killSourceName != "FallingDamage" )
		{
			
			if(!cannotUseUndyingSkill && FloorF(GetStat(BCS_Focus)) >= 1 && CanUseSkill(S_Sword_s18) && HasBuff(EET_BattleTrance) )
			{
				healingFactor = CalculateAttributeValue( GetSkillAttributeValue(S_Sword_s18, 'healing_factor', false, true) );
				healingFactor *= GetStat(BCS_Focus);
				healingBase = CalculateAttributeValue( GetSkillAttributeValue(S_Sword_s18, 'healing_bonus', false, true) ) * (GetSkillLevel(S_Sword_s18) - 1);
				healingBase = ( healingBase + healingFactor ) * GetStatMax(BCS_Vitality);
				ForceSetStat(BCS_Vitality, healingBase);
				action.processedDmg.vitalityDamage = 0;
				DrainFocus(GetStat(BCS_Focus));
				RemoveBuff(EET_BattleTrance);
				cannotUseUndyingSkill = true;
				thePlayer.AddEffectDefault( EET_Undying, NULL, "UndyingEffect" );
				AddTimer('UndyingSkillCooldown', CalculateAttributeValue( GetSkillAttributeValue(S_Sword_s18, 'trigger_delay', false, true) ), false, , , true);
			}
			
			//modSigns: removed Second Life's death trigger (MUT-12: Life Leech starts with the Mutation Catalyst)
			else
			{
				
				equipped = GetEquippedItems();

				for(i=0; i<equipped.Size(); i+=1)
				{
					if ( !inv.IsIdValid( equipped[i] ) )
					{
						continue;
					}
					itemDurability = inv.GetItemDurability(equipped[i]);
					if(inv.ItemHasAbility(equipped[i], 'MA_Reinforced') && itemDurability > 0)
					{
						
						inv.SetItemDurabilityScript(equipped[i], MaxF(0, itemDurability - action.processedDmg.vitalityDamage) );

						
						action.processedDmg.vitalityDamage = 0;
						ForceSetStat(BCS_Vitality, 1);

						break;
					}
				}
			}
		}
	}

	
	if(action.DealsAnyDamage() && !((W3Effect_Toxicity)action.causer) )
	{
		if(HasBuff(EET_Mutagen10))
			RemoveAbilityAll( GetBuff(EET_Mutagen10).GetAbilityName() );

		if(HasBuff(EET_Mutagen15))
			RemoveAbilityAll( GetBuff(EET_Mutagen15).GetAbilityName() );
	}

	
	if(HasBuff(EET_Mutagen19))
	{
		theGame.GetDefinitionsManager().GetAbilityAttributeValue(GetBuff(EET_Mutagen19).GetAbilityName(), 'max_hp_perc_trigger', min, max);
		hpTriggerTreshold = GetStatMax(BCS_Vitality) * CalculateAttributeValue(GetAttributeRandomizedValue(min, max));

		if(action.GetDamageDealt() >= hpTriggerTreshold)
		{
			mutagenQuen = (W3SignEntity)theGame.CreateEntity( signs[ST_Quen].template, GetWorldPosition(), GetWorldRotation() );
			mutagenQuen.Init( signOwner, signs[ST_Quen].entity, true );
			mutagenQuen.OnStarted();
			mutagenQuen.OnThrowing();
			mutagenQuen.OnEnded();
		}
	}

	
	if(action.DealsAnyDamage() && !action.IsDoTDamage() && HasBuff(EET_Mutagen27))
	{
		abilityName = GetBuff(EET_Mutagen27).GetAbilityName();
		abilityCount = GetAbilityCount(abilityName);

		if(abilityCount == 0)
		{
			addAbility = true;
		}
		else
		{
			theGame.GetDefinitionsManager().GetAbilityAttributeValue(abilityName, 'mutagen27_max_stack', min, max);
			maxStack = CalculateAttributeValue(GetAttributeRandomizedValue(min, max));

			if(maxStack >= 0)
			{
				addAbility = (abilityCount < maxStack);
			}
			else
			{
				addAbility = true;
			}
		}

		if(addAbility)
		{
			AddAbility(abilityName, true);
		}
	}
	
	if(HasBuff(EET_Trap) && !action.IsDoTDamage() && action.attacker.HasAbility( 'mon_dettlaff_monster_base' ))
	{
		action.AddEffectInfo(EET_Knockdown);
		RemoveBuff(EET_Trap, true);
	}

	GMMutation5Trigger(action, currVitality, killSourceName);	//modSigns: MUT-10, Mutated Skin spreads the hit's damage

	super.OnTakeDamage(action);

	
	if( !action.WasDodged() && action.DealtDamage() && inv.ItemHasTag( inv.GetCurrentlyHeldSword(), 'Aerondight' ) && !action.IsDoTDamage() && !( (W3Effect_Toxicity) action.causer ) )
	{
		aerondight = (W3Effect_Aerondight)GetBuff( EET_Aerondight );
		if( aerondight && aerondight.GetCurrentCount() != 0 )
		{
			aerondight.ReduceAerondightStacks();
		}
	}

	
	//modSigns: removed Bloodbath's end on damage taken (MUT-05)
	if(HasBuff(EET_Mutation3))	//modSigns: MUT-05, damage taken lowers Bloodbath's bonus
		((W3Effect_Mutation3)GetBuff(EET_Mutation3)).GMManageMutation3Bonus(action);	//modSigns
}

@replaceMethod(CActor)
function OnTakeDamage( action : W3DamageAction )
{		
	var playerAttacker : CPlayer;
	var attackName : name;
	var animatedComponent : CAnimatedComponent;
	var buff : W3Effect_Frozen;
	var buffs : array<CBaseGameplayEffect>;
	var i : int;
	var mutagen : CBaseGameplayEffect;
	var min, max : SAbilityAttributeValue;
	var lifeLeech, health, stamina : float;
	var wasAlive : bool;
	var hudModuleDamageType : EFloatingValueType;
	
	
	var dontShowDamage : bool;
	
	playerAttacker = (CPlayer)action.attacker;
	wasAlive = IsAlive();
	
	
	buffs = GetBuffs(EET_Frozen);
	for(i=0; i<buffs.Size(); i+=1)
	{
		buff = (W3Effect_Frozen)buffs[i];
		if(buff.KillOnHit())
		{
			action.processedDmg.vitalityDamage = GetStatMax(BCS_Vitality);
			action.processedDmg.essenceDamage = GetStatMax(BCS_Essence);
			if ( action.attacker == thePlayer )
			{
				ShowFloatingValue(EFVT_InstantDeath, 0, false);
			}
			break;
		}
	}

	if(action.processedDmg.vitalityDamage > 0 && UsesVitality())
	{
		
		if(this.HasAlternateQuen() && this.HasTag('mq1060_witcher'))
		{
			dontShowDamage = true;
		}
		else
		{
			if(!action.GMGetMutation5Triggered())	//modSigns: MUT-10, Mutated Skin deals it over time
				DrainVitality(action.processedDmg.vitalityDamage);
			action.SetDealtDamage();
		}
		
	}
	if(action.processedDmg.essenceDamage > 0 && UsesEssence())
	{
		DrainEssence(action.processedDmg.essenceDamage);
		action.SetDealtDamage();
	}
	if(action.processedDmg.moraleDamage > 0)
		DrainMorale(action.processedDmg.moraleDamage);
	if(action.processedDmg.staminaDamage > 0)
		DrainStamina(ESAT_FixedValue, action.processedDmg.staminaDamage, 0);
		
	
	ShouldAttachArrowToPlayer( action );
	
	
	if( ((action.attacker && action.attacker == thePlayer) || (CBaseGameplayEffect)action.causer) && !action.GetUnderwaterDisplayDamageHack() )
	{
		if(action.GetInstantKillFloater())
		{
			hudModuleDamageType = EFVT_InstantDeath;
		}
		else if(action.IsCriticalHit())
		{
			hudModuleDamageType = EFVT_Critical;
		}
		else if(action.IsDoTDamage())
		{
			hudModuleDamageType = EFVT_DoT;
		}
		else
		{
			hudModuleDamageType = EFVT_None;
		}			
	
		
		if(!dontShowDamage)
			ShowFloatingValue(hudModuleDamageType, action.GetDamageDealt(), (hudModuleDamageType == EFVT_DoT) );
	}
	
	
	if(action.attacker && !action.IsDoTDamage() && wasAlive && action.GetDTCount() > 0 && !action.GetUnderwaterDisplayDamageHack())
	{
		theGame.witcherLog.CacheCombatDamageMessage(action.attacker, this, action.GetDamageDealt());
		theGame.witcherLog.AddCombatDamageMessage(action.DealtDamage());
	}
		
	
	if(playerAttacker)
	{
		if (thePlayer.HasBuff(EET_Mutagen07))
		{
			mutagen = thePlayer.GetBuff(EET_Mutagen07);
			theGame.GetDefinitionsManager().GetAbilityAttributeValue(mutagen.GetAbilityName(), 'lifeLeech', min, max);
			lifeLeech = CalculateAttributeValue(GetAttributeRandomizedValue(min, max));
			if (UsesVitality())
				lifeLeech = lifeLeech * action.processedDmg.vitalityDamage;
			else if (UsesEssence())
				lifeLeech = lifeLeech * action.processedDmg.essenceDamage;
			else
				lifeLeech = 0;
			
			thePlayer.GainStat(BCS_Vitality, lifeLeech);
		}			
	}
	
	
	if(playerAttacker && action.IsActionMelee())
	{
		attackName = ((W3Action_Attack)action).GetAttackName();
	
		
		if ( thePlayer.HasBuff(EET_Mutagen04) && action.DealsAnyDamage() && thePlayer.IsHeavyAttack(attackName) && thePlayer.GetStat(BCS_Stamina) > 0)
		{
			mutagen = thePlayer.GetBuff(EET_Mutagen04);
			theGame.GetDefinitionsManager().GetAbilityAttributeValue(mutagen.GetAbilityName(), 'staminaCostPerc', min, max);
			stamina = CalculateAttributeValue(GetAttributeRandomizedValue(min, max));
			stamina *= thePlayer.GetStat(BCS_Stamina);
			theGame.GetDefinitionsManager().GetAbilityAttributeValue(mutagen.GetAbilityName(), 'healthReductionPerc', min, max);
			health = CalculateAttributeValue(GetAttributeRandomizedValue(min, max));
			if (UsesVitality())
			{
				health *= GetStat(BCS_Vitality);
				DrainVitality(health);					
				thePlayer.DrainStamina(ESAT_FixedValue, stamina, 0.5f);
			}
			else if (UsesEssence())
			{
				health *= GetStat(BCS_Essence);
				DrainEssence(health);					
				thePlayer.DrainStamina(ESAT_FixedValue, stamina, 0.5f);
			}
			
			if(health > 0)
				action.SetDealtDamage();
		}
	}
	
	
	if( !IsAlive() )
	{
		
		
		
		
		
		
		OnDeath( action );
	}
	
	
	SignalGameplayDamageEvent('DamageTaken', action );
}

