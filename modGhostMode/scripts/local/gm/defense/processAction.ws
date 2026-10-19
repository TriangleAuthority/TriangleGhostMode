// DEF-05, DEF-06, DEF-07, STAM-03: how a parried or countered hit on the player is processed, as
// legacy's block in ProcessAction (it replaces vanilla's):
// - a partial parry: parrying an attack that cannot be parried, or parrying without enough stamina
//   (STAM-03): parry-stagger (50%, W3GameParams), no bleeding, a short stagger (vanilla: long);
// - a partial counter: countering an attack that cannot be parried: parry-stagger share, no effects;
// - neither for an attack that knocks down or staggers (Knockdown, HeavyKnockdown, Stagger, LongStagger,
//   KnockdownTypeApplicator): it is parried or countered for no damage, but its effects apply
//   (legacy; project owner, 2026-10-04; the zero damage is in W3PlayerWitcher.ReduceDamage, dodge.ws);
// - a counter of a parryable attack applies none of its effects (DEF-06);
// - Geralt's counter marks the attacker (DEF-07's +25% crit), his next hit uses the mark up.
// SKL-07: the adrenaline a hit on the player costs is the share of maximum health it removed, up to 1
// point (legacy; 5.x: a fixed amount by attack type), reduced by Resolve.
// The rest of legacy's ProcessAction changes belong to other areas. See docs/features/def.md.

// 5.x body; changes marked //modSigns.
@replaceMethod(W3DamageManagerProcessor)
function ProcessAction(act : W3DamageAction)
{
	var wasAlive, validDamage, isFrozen, autoFinishersEnabled : bool;
	var focusDrain : float;
	var npc : CNewNPC;
	var buffs : array<EEffectType>;
	var arrStr : array<string>;
	var aerondight	: W3Effect_Aerondight;
	var trailFxName : name;
	
	
	var swordEntity : CWitcherSword;
	var swordItem : SItemUniqueId;
	var bloodType : EBloodType;
	
		
	wasAlive = act.victim.IsAlive();		
	npc = (CNewNPC)act.victim;
	
	
 		InitializeActionVars(act);
 		
 		
	if( ((CNewNPC)actorAttacker).IsHorse() && actorVictim.HasAbility('mon_werewolf_base'))
	{
		action.SetHitReactionType(EHRT_Light);
	}
	
 		
 		
	
	//modSigns: removed vanilla's block (an attack that cannot be parried, parried, without a knockdown: parry-stagger, long stagger, no bleeding); legacy's below
	// DEF-07: Geralt's counter marks the attacker as countered (its next hit from him: +25% crit).
	if(playerVictim && (W3PlayerWitcher)playerVictim && attackAction && attackAction.IsActionMelee() && attackAction.IsCountered() && actorAttacker)	//modSigns
		actorAttacker.GMSetWasCountered(true);	//modSigns
	// DEF-06: a counter of a parryable attack applies none of its effects (vanilla applied them).
	if(playerVictim && attackAction && attackAction.IsActionMelee() && attackAction.IsCountered() && attackAction.CanBeParried())	//modSigns
		action.SetProcessBuffsIfNoDamage(false);	//modSigns
	// DEF-05, DEF-06, STAM-03: a partial parry (an attack that cannot be parried, or a parry without enough
	// stamina) or a partial counter (an attack that cannot be parried), unless the attack knocks down or staggers
	// (those are parried or countered for no damage, their effects applying: ReduceDamage).
	if(playerVictim && attackAction && attackAction.IsActionMelee() && (attackAction.IsParried() || attackAction.IsCountered())	//modSigns
		&& (!attackAction.CanBeParried() || attackAction.IsParried() && playerVictim.GMIsParryingWithNotEnoughStamina()))	//modSigns
	{	//modSigns
		action.GetEffectTypes(buffs);	//modSigns
		if(!buffs.Contains(EET_Knockdown) && !buffs.Contains(EET_HeavyKnockdown) && !buffs.Contains(EET_Stagger)	//modSigns
			&& !buffs.Contains(EET_LongStagger) && !buffs.Contains(EET_KnockdownTypeApplicator))	//modSigns
		{	//modSigns
			action.SetParryStagger();	//modSigns
			action.SetHitAnimationPlayType(EAHA_ForceNo);	//modSigns
			action.SetCanPlayHitParticle(false);	//modSigns
			if(attackAction.IsParried())	//modSigns
			{	//modSigns
				action.SetProcessBuffsIfNoDamage(true);	//modSigns
				action.RemoveBuffsByType(EET_Bleeding);	//modSigns
				action.RemoveBuffsByType(EET_Bleeding1);	//modSigns
				action.RemoveBuffsByType(EET_Bleeding2);	//modSigns
				action.RemoveBuffsByType(EET_Bleeding3);	//modSigns
				action.AddEffectInfo(EET_Stagger);	//modSigns: a short stagger (vanilla: long)
			}	//modSigns
			else	//modSigns
			{	//modSigns
				action.SetProcessBuffsIfNoDamage(false);	//modSigns
				action.ClearEffects();	//modSigns: a partial counter applies no effects
			}	//modSigns
		}	//modSigns
	}	//modSigns
 		
 		
	//modSigns: removed the player_had_quen fact (SKL-11: Quen's damage-over-time rule as legacy)
	
	if (!action.GetSimulateOnly())
	{
		
		ProcessPreHitModifications();

		
		ProcessActionQuest(act);
	}
	
	
	isFrozen = (actorVictim && actorVictim.HasBuff(EET_Frozen));
	
	
	validDamage = ProcessActionDamage();
	
	
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
		((CActor) action.attacker).SignalGameplayEventParamFloat(  'CausesDamage', MaxF( action.processedDmg.vitalityDamage, action.processedDmg.essenceDamage ) );
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
		//modSigns: removed 5.x's loss by attack type (light, heavy, super heavy)
		focusDrain = ClampF(action.GetDamageDealt() / actorVictim.GetMaxHealth(), 0, 1);	//modSigns: SKL-07, the share of maximum health the hit removed (legacy)
		
		
		if ( GetWitcherPlayer().CanUseSkill(S_Sword_s16) )
			focusDrain *= 1 - (CalculateAttributeValue( thePlayer.GetSkillAttributeValue(S_Sword_s16, 'focus_drain_reduction', false, true) ) * thePlayer.GetSkillLevel(S_Sword_s16));
			
		focusDrain -= GetWitcherPlayer().GMBearSetHitAdrenaline();	//modSigns: ARM-08, the Bear set's adrenaline on hits taken (legacy)
		if(focusDrain > 0)	//modSigns
			thePlayer.DrainFocus(focusDrain);
		else if(focusDrain < 0)	//modSigns
			thePlayer.GainStat(BCS_Focus, -focusDrain);	//modSigns
	}
	
	
	if(actorAttacker == GetWitcherPlayer() && actorVictim && !actorVictim.IsAlive() && (action.IsActionMelee() || action.GetBuffSourceName() == "Kill"))
	{
		autoFinishersEnabled = theGame.GetInGameConfigWrapper().GetVarValue('Gameplay', 'AutomaticFinishersEnabled');
		
		
		
		
		if(!autoFinishersEnabled || !thePlayer.GetFinisherVictim())
		{
			if(thePlayer.HasAbility('Runeword 10 _Stats', true))
				GetWitcherPlayer().Runeword10Triggerred();
			if(thePlayer.HasAbility('Runeword 12 _Stats', true))
				GetWitcherPlayer().Runeword12Triggerred();

		}
	}
	
	
	if(action.EndsQuen() && actorVictim)
	{
		actorVictim.FinishQuen(false);			
	}
	// DEF-07: Geralt's next hit on a countered enemy (not damage over time) uses its mark up.
	if(playerAttacker && actorVictim && actorVictim.GMWasCountered() && !action.IsDoTDamage())	//modSigns
		actorVictim.GMSetWasCountered(false);	//modSigns

	
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
	
	if( playerAttacker && npc && action.IsActionMelee() && action.DealtDamage() && IsRequiredAttitudeBetween( playerAttacker, npc, true ))
	{		
		if(!npc.HasTag( 'AerondightIgnore' ))	
		{
			if( playerAttacker.inv.ItemHasTag( attackAction.GetWeaponId(), 'Aerondight' ) )
			{
				
				aerondight = (W3Effect_Aerondight)playerAttacker.GetBuff( EET_Aerondight );
				aerondight.IncreaseAerondightCharges( attackAction.GetAttackName() );
				
				
				if( aerondight.GetCurrentCount() == aerondight.GetMaxCount() )
				{
					switch( npc.GetBloodType() )
					{
						case BT_Red : 
							trailFxName = 'aerondight_blood_red';
							break;
							
						case BT_Yellow :
							trailFxName = 'aerondight_blood_yellow';
							break;
						
						case BT_Black : 
							trailFxName = 'aerondight_blood_black';
							break;
						
						case BT_Green :
							trailFxName = 'aerondight_blood_green';
							break;
					}
					
					playerAttacker.inv.GetItemEntityUnsafe( attackAction.GetWeaponId() ).PlayEffect( trailFxName );
				}
			}
		}
		
		
		if(!action.WasDodged() && !attackAction.IsParried() && !attackAction.IsCountered())
		{
			swordItem = GetWitcherPlayer().GetHeldSword();
			if(swordItem != GetInvalidUniqueId())
			{
				swordEntity = (CWitcherSword)thePlayer.GetInventory().GetItemEntityUnsafe( swordItem );	
				if(swordEntity)
				{
					bloodType = npc.GetBloodType();
					if(bloodType == BT_Red || bloodType == BT_Yellow)
					{
						swordEntity.PlayEffectSingle('weapon_blood');
					}
					else if (bloodType == BT_Black || npc.HasAbility('mon_kikimora_warrior') || npc.HasAbility('mon_kikimora_worker') || npc.HasAbility('mon_black_spider_base') || npc.HasAbility('mon_black_spider_ep2_base') )
					{
						swordEntity.PlayEffectSingle('weapon_blood_black');
					}
					else if (bloodType == BT_Green)
					{
						swordEntity.PlayEffectSingle('weapon_blood_green');
					}
				}
			}
		}
		
	}
}
