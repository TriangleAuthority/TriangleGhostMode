// DEF-06: counters. Countering no longer depends on whether the attack can be parried (also
// against enemies with CannotBeCountered, e.g. sq701's Gregoire; project owner, 2026-10-03); the
// Grave Hag's special repel only against her tongue; two-handed human fighters and the tournament
// contestants are side-stepped;
// a counter kick down a slope also stuns; countering an attack that cannot be parried is a partial
// counter (set in ProcessAction, defense/processAction.ws). 5.x's spear break is kept (project owner, 2026-10-04).
// STAM-03: a counter costs the same against any attack (legacy; project owner, 2026-10-04); that
// it needs stamina is STAM-03's wrapper in parryStamina.ws.
// SKL-05: Counterattack's knockdown roll comes after the whole repel chain, as legacy's (also for
// monsters, two-handed and tournament fighters and slope kicks; not after Mutation 8's finisher), and
// the ledge trace runs with the skill too; a kick or bash without a knockdown stuns (legacy).
// Left as 5.x for its area: the Lynx set (ARM). Deadly Counter's repel is MUT-06's (first in the order). See docs/features/def.md.

// DEF-06: the Blood and Wine tournament contestants (sq701) that legacy gave its empty marker
// ability sq701_tournament_npcs, recognised by their entity templates instead of edited .w2ent
// files: 12 of the folder's 14 (legacy left out Horm with a bow and Rainfarn with a shield).
function GMIsTournamentContestant(npc : CNewNPC) : bool
{
	var path, folder : string;
	var names : array<string>;
	var i : int;

	folder = "dlc\bob\data\quests\sidequests\quest_files\sq701_tournament\characters\contestants";
	path = StrLower(npc.GetReadableName());
	names.PushBack("\sq701_delwyn");
	names.PushBack("\sq701_donimir");
	names.PushBack("\sq701_guy");
	names.PushBack("\sq701_horm");
	names.PushBack("\sq701_llinos");
	names.PushBack("\sq701_rainfarn");
	for(i = 0; i < names.Size(); i += 1)
		if(path == folder + names[i] + ".w2ent" || path == folder + names[i] + "_rest.w2ent")
			return true;
	return false;
}

// 5.x body; changes marked //modSigns.
@replaceMethod(CR4Player)
function PerformCounterCheck(parryInfo: SParryInfo) : bool
{
	//modSigns: removed var mult (counters have no heavy-attack multiplier)
	var parryType					: EParryType;
	var validCounter, useKnockdown 	: bool;
	var slideDistance, duration 	: float;
	var playerToTargetRot			: EulerAngles;
	var zDifference, mutation8TriggerHP : float;
	var effectType 					: EEffectType;
	var repelType					: EPlayerRepelType = PRT_Random;
	var params						: SCustomEffectParams;
	var thisPos, attackerPos 		: Vector;
	var fistFightCheck, isMutation8 : bool;
	var fistFightCounter 			: bool;
	var attackerInventory			: CInventoryComponent;
	var weaponId					: SItemUniqueId;
	var weaponTags					: array<name>;
	var playerToAttackerVector 		: Vector;
	var tracePosStart				: Vector;
	var tracePosEnd					: Vector;
	var hitPos						: Vector;
	var hitNormal					: Vector;
	var min, max					: SAbilityAttributeValue;
	var npc 						: CNewNPC;
	var attType					: float;	//modSigns
	
	if(ShouldProcessTutorial('TutorialDodge') || ShouldProcessTutorial('TutorialCounter'))
	{
		theGame.RemoveTimeScale( theGame.GetTimescaleSource(ETS_TutorialFight) );
		FactsRemove("tut_fight_slomo_ON");
	}
	
	//modSigns: removed "if ( !parryInfo.canBeParried || parryInfo.attacker.HasAbility( 'CannotBeCountered' ) ) return false;" (DEF-06: countering does not depend on parrying)
	
	fistFightCheck = FistFightCheck( parryInfo.target, parryInfo.attacker, fistFightCounter );
	
	if( ParryCounterCheck() && parryInfo.targetToAttackerAngleAbs < theGame.params.PARRY_HALF_ANGLE && fistFightCheck )
	{
		
		validCounter = CheckCounterSpamming(parryInfo.attacker);
		
		if(validCounter)
		{
			if ( IsInCombatActionFriendly() )
				RaiseEvent('CombatActionFriendlyEnd');
			
			SetBehaviorVariable( 'parryType', ChooseParryTypeIndex( parryInfo ) );
			SetBehaviorVariable( 'counter', (float)validCounter);			
			
			
			
			SetBehaviorVariable( 'parryType', ChooseParryTypeIndex( parryInfo ) );
			SetBehaviorVariable( 'counter', (float)validCounter);			
			this.SetBehaviorVariable( 'combatActionType', (int)CAT_Parry );
			
			
			if ( !fistFightCounter )
			{
				attackerInventory = parryInfo.attacker.GetInventory();
				weaponId = attackerInventory.GetItemFromSlot('r_weapon');
				attackerInventory.GetItemTags( weaponId , weaponTags );
				
				if( GetWitcherPlayer().IsMutationActive( EPMT_Mutation8 ) )
				{
					isMutation8 = true;
					//modSigns: removed the health trigger read here (MUT-06: GMMutation8RepelToFinisherImmune checks it)
				}
				
				
				
				npc = (CNewNPC)parryInfo.attacker;
				if ( npc )	//modSigns
					attType = npc.GetBehaviorVariable( 'AttackType' );	//modSigns
				
				if( isMutation8 && npc && !npc.GMMutation8RepelToFinisherImmune() )	//modSigns: MUT-06, Deadly Counter first in the repel order (legacy)
				{	//modSigns
					repelType = PRT_RepelToFinisher;	//modSigns
					npc.AddEffectDefault( EET_CounterStrikeHit, this, "ReflexParryPerformed" );	//modSigns
					SetTarget( npc, true );	//modSigns
					PerformFinisher( 0.f, 0 );	//modSigns
				}	//modSigns
				//modSigns: the Grave Hag's special repel only against her tongue attacks (was any attack)
				else if ( parryInfo.attacker.HasAbility('mon_gravehag') && ( attType == 6 || attType == 19 ) && parryInfo.attacker.HasAbility('TongueAttack') )	//modSigns
				{
					repelType = PRT_Slash;
					parryInfo.attacker.AddEffectDefault(EET_CounterStrikeHit, this, 'ReflexParryPerformed');
					
				}

				else if ( npc && !npc.IsHuman() && !npc.HasTag( 'dettlaff_vampire' ) )
				{
					repelType = PRT_SideStepSlash;
				}
				else if ( weaponTags.Contains('spear2h') )
				{
					repelType = PRT_SideStepSlash;
					parryInfo.attacker.AddEffectDefault(EET_CounterStrikeHit, this, "ReflexParryPerformed");
					parryInfo.attacker.SignalGameplayEvent( 'SpearDestruction');
					((CNewNPC)parryInfo.attacker).ProcessSpearDestruction();
				}
				//modSigns: removed 5.x's Mutation 8 repel here (MUT-06: first in the order, above)
				else if ( npc && npc.IsHuman() && ( npc.HasAbility('SkillTwoHanded') || GMIsTournamentContestant(npc) ) )	//modSigns: two-handed fighters and the tournament contestants are side-stepped (legacy)
				{	//modSigns
					repelType = PRT_SideStepSlash;	//modSigns
				}	//modSigns
				else
				{
					
					thisPos = this.GetWorldPosition();
					attackerPos = parryInfo.attacker.GetWorldPosition();
					playerToTargetRot = VecToRotation( thisPos - attackerPos );
					zDifference = thisPos.Z - attackerPos.Z;
					
					if ( playerToTargetRot.Pitch < -5.f && zDifference > 0.35 )
					{
						repelType = PRT_Kick;
						
						ragdollTarget = parryInfo.attacker;
						AddTimer( 'ApplyCounterRagdollTimer', 0.3 );
						//modSigns: a kick down a slope stuns too, below (DEF-06), unless the attacker is knocked down
					}
					else
					{
						useKnockdown = false;
						//modSigns: removed Counterattack's roll here (SKL-05: rolled after the whole repel chain, legacy)
						if ( parryInfo.attacker.IsHuman() )	//modSigns: the ledge trace also with Counterattack (legacy)
						{ 
							
							tracePosStart = parryInfo.attacker.GetWorldPosition();
							tracePosStart.Z += 1.f;
							playerToAttackerVector = VecNormalize( parryInfo.attacker.GetWorldPosition() -  parryInfo.target.GetWorldPosition() );
							tracePosEnd = ( playerToAttackerVector * 0.75f ) + ( playerToAttackerVector * parryInfo.attacker.GetRadius() ) + parryInfo.attacker.GetWorldPosition();
							tracePosEnd.Z += 1.f;

							if ( !theGame.GetWorld().StaticTrace( tracePosStart, tracePosEnd, hitPos, hitNormal, counterCollisionGroupNames ) )
							{
								tracePosStart = tracePosEnd;
								tracePosEnd -= 3.f;
								
								if ( !theGame.GetWorld().StaticTrace( tracePosStart, tracePosEnd, hitPos, hitNormal, counterCollisionGroupNames ) )
									useKnockdown = true;
							}
						}
						//modSigns: removed the knockdown and the counter strike here (applied after the repel chain, legacy)
					}
				}
				
				parryInfo.attacker.GetInventory().PlayItemEffect(parryInfo.attackerWeaponId, 'counterattack');
				
				
				if ( repelType == PRT_Random )
					if ( RandRange(100) > 50 )
						repelType = PRT_Bash;
					else
						repelType = PRT_Kick;
				
				if ( repelType != PRT_RepelToFinisher )	//modSigns: SKL-05, the knockdown after the whole repel chain (legacy; Mutation 8's finisher left as 5.x)
				{	//modSigns
					if ( useKnockdown || RandF() < GetWitcherPlayer().GMCounterattackKnockdownChance() )	//modSigns: a human countered off a ledge, or Counterattack's roll (legacy: 5% per adrenaline point at level 3)
					{	//modSigns
						if ( GetWitcherPlayer().GMCounterattackSkill() != S_SUndefined )	//modSigns
							duration = CalculateAttributeValue(GetSkillAttributeValue(GetWitcherPlayer().GMCounterattackSkill(), 'duration', false, true));	//modSigns
						else	//modSigns
							duration = CalculateAttributeValue(GetSkillAttributeValue(S_Sword_s11, 'duration', false, true));	//modSigns: legacy reads Counterattack's duration also without the skill
						if(!parryInfo.attacker.IsImmuneToBuff(EET_HeavyKnockdown) || !parryInfo.attacker.IsImmuneToBuff(EET_Knockdown))	//modSigns
						{	//modSigns
							if(!parryInfo.attacker.IsImmuneToBuff(EET_HeavyKnockdown))	//modSigns
								params.effectType = EET_HeavyKnockdown;	//modSigns
							else	//modSigns
								params.effectType = EET_Knockdown;	//modSigns
							params.creator = this;	//modSigns
							params.sourceName = "ReflexParryPerformed";	//modSigns
							params.duration = duration;	//modSigns
							parryInfo.attacker.AddEffectCustom(params);	//modSigns
							repelType = PRT_Kick;	//modSigns
							useKnockdown = true;	//modSigns
						}	//modSigns
						else	//modSigns
							useKnockdown = false;	//modSigns
					}	//modSigns
					if ( !useKnockdown && ( repelType == PRT_Kick || repelType == PRT_Bash ) )	//modSigns: a kick or bash without a knockdown stuns (legacy)
						parryInfo.attacker.AddEffectDefault(EET_CounterStrikeHit, this, "ReflexParryPerformed");	//modSigns
				}	//modSigns
				
				this.SetBehaviorVariable( 'repelType', (int)repelType );
				parryInfo.attacker.SetBehaviorVariable( 'repelType', (int)repelType );
			}
			else
			{
				parryInfo.attacker.AddEffectDefault(EET_CounterStrikeHit, this, "ReflexParryPerformed");
			}
			
			
			SetParryTarget ( parryInfo.attacker );
			SetSlideTarget( parryInfo.attacker );
			if ( !IsActorLockedToTarget() )
				SetMoveTarget( parryInfo.attacker );
			
			if ( RaiseForceEvent( 'PerformCounter' ) )
				OnCombatActionStart();
			
			SetCustomRotation( 'Counter', VecHeading( parryInfo.attacker.GetWorldPosition() - this.GetWorldPosition() ), 0.0f, 0.2f, false );
			AddTimer( 'UpdateCounterRotation', 0.4f, true );
			AddTimer( 'SetCounterRotation', 0.2f );
			
			IncreaseUninterruptedHitsCount();	
			
			
			//modSigns: removed the heavy-attack multiplier (STAM-03: a counter costs the same against any attack)
			DrainStamina(ESAT_Counterattack, 0, 0, '', 0);	//modSigns
			if(GetWitcherPlayer() == this)	//modSigns: SKL-18, Attack is the Best Defense's stamina for a counter (legacy)
				GetWitcherPlayer().GMPerk21GainStamina('counter');	//modSigns
			
			theGame.GetGamerProfile().IncStat(ES_CounterattackChain);
		}
		else
		{
			ResetUninterruptedHitsCount();
		}
		return validCounter;
	}			
	
	return false;
}

// DEF-07: a countered enemy takes +25% critical hit chance from the player's next hit, within 3 s
// (legacy's per-enemy flag; vanilla's "recently countered" flag on Geralt stays, 5.x's S_Sword_s31
// and Counterattack read it). Set when Geralt counters its attack, used up by his next hit on it
// (the counter strike itself, when it lands), or after 3 s. The deadline is engine time, so the
// field is not saved and needs no timer.
@addField(CActor)
var gmCounteredUntil : float;

@addMethod(CActor)
function GMWasCountered() : bool
{
	return gmCounteredUntil > theGame.GetEngineTimeAsSeconds();
}

@addMethod(CActor)
function GMSetWasCountered(countered : bool)
{
	if(countered)
		gmCounteredUntil = theGame.GetEngineTimeAsSeconds() + 3.0;
	else
		gmCounteredUntil = 0;
}

// DEF-07: +25% critical hit chance against a countered enemy, for melee attacks (light or heavy;
// not bolts, signs or other actions, which ask with neither).
@wrapMethod(W3PlayerWitcher)
function GetCriticalHitChance(isLightAttack : bool, isHeavyAttack : bool, target : CActor, victimMonsterCategory : EMonsterCategory, isBolt : bool) : float
{
	var chance : float;

	chance = wrappedMethod(isLightAttack, isHeavyAttack, target, victimMonsterCategory, isBolt);
	if(target && target.GMWasCountered() && (isLightAttack || isHeavyAttack) && !isBolt)
		chance += 0.25;
	return chance;
}

// DEF-06's partial counter, a counter's effects and DEF-07's countered mark are set in
// W3DamageManagerProcessor.ProcessAction (defense/processAction.ws).

// DEF-07: a counter is a light attack, so the light-attack bonuses apply to it ("counter is now
// considered a light attack", changelist); so is the special light attack. Its -75% attack power is
// removed in the DLC XML (gm_defense.xml).
@wrapMethod(CR4Player)
function IsLightAttack(attackName : name) : bool
{
	if(attackName == 'counter_attack_light' || attackName == 'attack_light_special')
		return true;
	return wrappedMethod(attackName);
}

// DEF-07: a counter gets the light-attack attack power bonuses: the abilities tagged attack_light
// (Muscle Memory's tag is extended to counter_attack_light in gm_defense.xml; counted once, SKL's
// D47, skills/muscleStrength.ws) and attack_power_fast_style (the new tree's light-attack perks),
// which vanilla adds only for a light attack type; a counter has none, so it is added here.
@wrapMethod(W3Action_Attack)
function GetPowerStatValue() : SAbilityAttributeValue
{
	var result : SAbilityAttributeValue;
	var witcher : W3PlayerWitcher;

	result = wrappedMethod();
	witcher = (W3PlayerWitcher)attacker;
	if(witcher && attackName == 'counter_attack_light')
		result += witcher.GetAttributeValue('attack_power_fast_style');
	return result;
}
