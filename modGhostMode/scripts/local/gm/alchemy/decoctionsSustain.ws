// ALCH-12: sustain and stamina decoctions (legacy's).
// - ArchGriffin (Mutagen 4): light, heavy and counter attacks and Whirl cost +50% stamina; each melee hit takes
//   0.1% of the victim's current Vitality per stamina point spent on it (Rend by its charge; mutations/takeDamage.ws).
// - Troll (Mutagen 12): its ability's regen; +80 more combat regen while stamina is at 33% or less. The
//   owner's DL12 fix: the bonus stays on while the condition holds (legacy toggled it at every stamina change).
// - Noonwraith (Mutagen 13): each kill +1 combat stamina regen per hostile within range (max +10), reset at
//   combat end. 1.32's short crowd control is gone.
// - Grave Hag (Mutagen 18): each kill +5 Vitality regen per hostile within range (max +50), reset at combat end.
// - Ekhidna (Mutagen 21): heals 0.1% of maximum Vitality per stamina point spent, in combat
//   (stamina/channelStamina.ws). 1.32's 10% per action is gone.
// - Basilisk (Mutagen 23): +4/8/16 Vitality regen per equipped lesser/normal/greater green mutagen.
// - Nekker Warrior (Mutagen 25): melee stamina actions cost 2.5/3.75/5% less per equipped lesser/normal/greater
//   red mutagen. 1.32's horseback attack power and horse panic immunity are gone.
// See docs/features/alch.md.

// ---- ArchGriffin -----------------------------------------------------------------------------------------

@addMethod(W3Mutagen04_Effect)
function GMGetHealthReductionPrc(cost : float) : float
{
	var min, max : SAbilityAttributeValue;

	theGame.GetDefinitionsManager().GetAbilityAttributeValue(abilityName, 'healthReductionPerc', min, max);
	return cost * CalculateAttributeValue(GetAttributeRandomizedValue(min, max));
}

@addMethod(W3Mutagen04_Effect)
function GMGetAttackCostIncrease() : float
{
	var min, max : SAbilityAttributeValue;

	theGame.GetDefinitionsManager().GetAbilityAttributeValue(abilityName, 'attackCostIncrease', min, max);
	return CalculateAttributeValue(GetAttributeRandomizedValue(min, max));
}

// The stamina cost terms of ArchGriffin (attacks dearer) and Nekker Warrior (melee actions cheaper) for
// Geralt's action (legacy's GetStaminaActionCost terms).
function GMDecoctionStaminaCostMult(action : EStaminaActionType) : float
{
	var mult : float;
	var w : W3PlayerWitcher;

	w = GetWitcherPlayer();
	mult = 1;
	if(!GMIsMeleeStaminaAction(action))
		return mult;
	if(w.HasBuff(EET_Mutagen25))
		mult *= 1 - ((W3Mutagen25_Effect)w.GetBuff(EET_Mutagen25)).GMGetM25Bonus();
	if(w.HasBuff(EET_Mutagen04) && (action == ESAT_LightAttack || action == ESAT_HeavyAttack || action == ESAT_Counterattack))
		mult *= 1 + ((W3Mutagen04_Effect)w.GetBuff(EET_Mutagen04)).GMGetAttackCostIncrease();
	return mult;
}

@wrapMethod(W3AbilityManager)
function GetStaminaActionCost(action : EStaminaActionType, out cost : float, out delay : float, optional fixedCost : float, optional fixedDelay : float, optional abilityName : name, optional dt : float, optional costMult : float)
{
	wrappedMethod(action, cost, delay, fixedCost, fixedDelay, abilityName, dt, costMult);
	if(owner == GetWitcherPlayer() && cost > 0)
		cost = ClampF(cost * GMDecoctionStaminaCostMult(action), 0, 100);
}

// ---- Troll -----------------------------------------------------------------------------------------------

class W3Mutagen12_Effect extends W3Mutagen_Effect
{
	event OnUpdate(dt : float)	//modSigns
	{	//modSigns
		super.OnUpdate(dt);	//modSigns
		GMManageAdditionalBonus();	//modSigns: DL12, checked every update: on while the condition holds
	}	//modSigns

	event OnEffectRemoved()	//modSigns
	{	//modSigns
		super.OnEffectRemoved();	//modSigns
		target.RemoveAbilityAll('TrollBonusEffect');	//modSigns
	}	//modSigns
}

// Legacy's ManageAdditionalBonus with the owner's DL12 fix: the bonus is on in combat at or below the stamina
// threshold and off otherwise (legacy removed it at the next stamina change while still below).
@addMethod(W3Mutagen12_Effect)
function GMManageAdditionalBonus()
{
	var min, max : SAbilityAttributeValue;
	var on : bool;

	if(target == thePlayer && thePlayer.IsInCombat())
	{
		theGame.GetDefinitionsManager().GetAbilityAttributeValue(abilityName, 'm12_threshold', min, max);
		on = thePlayer.GetStatPercents(BCS_Stamina) <= CalculateAttributeValue(GetAttributeRandomizedValue(min, max));
	}
	if(on && !thePlayer.HasAbility('TrollBonusEffect'))
		thePlayer.AddAbility('TrollBonusEffect');
	else if(!on && thePlayer.HasAbility('TrollBonusEffect'))
		thePlayer.RemoveAbilityAll('TrollBonusEffect');
}

// ---- Noonwraith and Grave Hag (kills) ----------------------------------------------------------------------

class W3Mutagen13_Effect extends W3Mutagen_Effect
{
	default dontAddAbilityOnTarget = true;	//modSigns

	event OnEffectRemoved()	//modSigns
	{	//modSigns
		super.OnEffectRemoved();	//modSigns
		target.RemoveAbilityAll(abilityName);	//modSigns
	}	//modSigns
}

// 5.x body: 1.32's short crowd control. Changes marked //modSigns.
@replaceMethod(W3Mutagen13_Effect)
function IsEffectTypeAffected(effectType : EEffectType) : bool
{
	//modSigns: removed 1.32's list of crowd-control effects cut to 0.5 s (ALCH-12: legacy's Noonwraith gives stamina regen per kill)
	return false;	//modSigns
}

// Legacy's ManageMutagen13Bonus/ManageMutagen18Bonus: a kill adds one stack per hostile within range (up to
// the maximum); out of combat the stacks go.
function GMManageKillDecoction(effect : CBaseGameplayEffect, maxName : name)
{
	var abl : name;
	var abilityCount, ablsToAdd, maxStack : int;
	var min, max : SAbilityAttributeValue;

	abl = effect.GetAbilityName();
	if(!(thePlayer.IsInCombat() && thePlayer.IsThreatened()))
	{
		thePlayer.RemoveAbilityAll(abl);
		return;
	}
	theGame.GetDefinitionsManager().GetAbilityAttributeValue(abl, maxName, min, max);
	maxStack = RoundMath(CalculateAttributeValue(GetAttributeRandomizedValue(min, max)));
	abilityCount = thePlayer.GetAbilityCount(abl);
	ablsToAdd = GetWitcherPlayer().GMGetNumHostilesInRange();
	if(abilityCount + ablsToAdd < maxStack)
		thePlayer.AddAbilityMultiple(abl, ablsToAdd);
	else if(abilityCount < maxStack)
		thePlayer.AddAbilityMultiple(abl, maxStack - abilityCount);
}

// Called from CNewNPC.OnDeath (enchantments/npcDeath.ws) for Geralt's kills.
function GMDecoctionsOnKill()
{
	if(thePlayer.HasBuff(EET_Mutagen13))
		GMManageKillDecoction(thePlayer.GetBuff(EET_Mutagen13), 'mutagen13_max_stack');
	if(thePlayer.HasBuff(EET_Mutagen18))
		GMManageKillDecoction(thePlayer.GetBuff(EET_Mutagen18), 'mutagen18_max_stack');
}

// ---- Ekhidna ---------------------------------------------------------------------------------------------

// Legacy's Heal(cost): 0.1% of maximum Vitality per stamina point spent, in combat.
@addMethod(W3Mutagen21_Effect)
function GMHeal(cost : float)
{
	var min, max : SAbilityAttributeValue;

	if(!target.IsInCombat())
		return;
	theGame.GetDefinitionsManager().GetAbilityAttributeValue(abilityName, 'healingRatio', min, max);
	target.GainStat(BCS_Vitality, target.GetStatMax(BCS_Vitality) * CalculateAttributeValue(GetAttributeRandomizedValue(min, max)) * cost);
}

// 5.x body: 1.32's heal per action (also called by 5.x's special attack code). Changes marked //modSigns.
@replaceMethod(W3Mutagen21_Effect)
function Heal()
{
	//modSigns: removed 1.32's heal per action (ALCH-12: legacy's Ekhidna heals per stamina point spent, GMHeal from DrainStamina)
}

// ---- Basilisk and Nekker Warrior (mutagens in the skill slots) ----------------------------------------------

class W3Mutagen23_Effect extends W3Mutagen_Effect
{
	event OnEffectAdded(optional customParams : W3BuffCustomParams)	//modSigns
	{	//modSigns
		super.OnEffectAdded(customParams);	//modSigns
		GMAddM23Abilities();	//modSigns
	}	//modSigns

	event OnEffectRemoved()	//modSigns
	{	//modSigns
		super.OnEffectRemoved();	//modSigns
		target.RemoveAbilityAll(abilityName);	//modSigns
	}	//modSigns
}

// 5.x body: 1.32's shrine buff at dawn and dusk. Changes marked //modSigns.
@replaceMethod(W3Mutagen23_Effect)
function OnUpdate(dt : float)
{
	//modSigns: removed the shrine buff's locals
	super.OnUpdate(dt);
	//modSigns: removed 1.32's shrine buff at dawn and dusk (ALCH-12: legacy's Basilisk gives regen per green mutagen)
}

// One copy of the ability (+4 regen) per lesser green mutagen in the skill slots, 2 per normal, 4 per greater.
@addMethod(W3Mutagen23_Effect)
function GMAddM23Abilities()
{
	var mutagenSlots : array<SMutagenSlot>;
	var i, mutagensCount, numAbls : int;
	var abilities : array<name>;

	mutagenSlots = GetWitcherPlayer().GetPlayerSkillMutagens();
	for(i = 0; i < mutagenSlots.Size(); i += 1)
	{
		if(mutagenSlots[i].item != GetInvalidUniqueId())
		{
			abilities.Clear();
			GetWitcherPlayer().GetInventory().GetItemAbilities(mutagenSlots[i].item, abilities);
			if(abilities.Contains('greater_mutagen_color_green'))
				mutagensCount += 4;
			else if(abilities.Contains('mutagen_color_green'))
				mutagensCount += 2;
			else if(abilities.Contains('lesser_mutagen_color_green'))
				mutagensCount += 1;
		}
	}
	numAbls = target.GetAbilityCount(abilityName);
	if(mutagensCount > numAbls)
		target.AddAbilityMultiple(abilityName, mutagensCount - numAbls);
	else if(mutagensCount < numAbls)
		target.RemoveAbilityMultiple(abilityName, numAbls - mutagensCount);
}

@addField(W3Mutagen25_Effect)
saved var gmM25Bonus : float;

@addMethod(W3Mutagen25_Effect)
function GMGetM25Bonus() : float
{
	return gmM25Bonus;
}

@addMethod(W3Mutagen25_Effect)
function GMRecalcM25Bonus()
{
	var mutagenSlots : array<SMutagenSlot>;
	var i : int;
	var mutagensCount : array<int>;
	var abilities : array<name>;
	var abl, max : SAbilityAttributeValue;

	mutagenSlots = GetWitcherPlayer().GetPlayerSkillMutagens();
	mutagensCount.Resize(3);
	gmM25Bonus = 0;
	for(i = 0; i < mutagenSlots.Size(); i += 1)
	{
		if(mutagenSlots[i].item != GetInvalidUniqueId())
		{
			abilities.Clear();
			GetWitcherPlayer().GetInventory().GetItemAbilities(mutagenSlots[i].item, abilities);
			if(abilities.Contains('greater_mutagen_color_red'))
				mutagensCount[2] += 1;
			else if(abilities.Contains('mutagen_color_red'))
				mutagensCount[1] += 1;
			else if(abilities.Contains('lesser_mutagen_color_red'))
				mutagensCount[0] += 1;
		}
	}
	theGame.GetDefinitionsManager().GetAbilityAttributeValue(abilityName, 'mutagen25_bonus_lesser', abl, max);
	gmM25Bonus += abl.valueAdditive * mutagensCount[0];
	theGame.GetDefinitionsManager().GetAbilityAttributeValue(abilityName, 'mutagen25_bonus_medium', abl, max);
	gmM25Bonus += abl.valueAdditive * mutagensCount[1];
	theGame.GetDefinitionsManager().GetAbilityAttributeValue(abilityName, 'mutagen25_bonus_greater', abl, max);
	gmM25Bonus += abl.valueAdditive * mutagensCount[2];
	gmM25Bonus = ClampF(gmM25Bonus, 0, 1);
}

class W3Mutagen25_Effect extends W3Mutagen_Effect
{
	event OnEffectAdded(optional customParams : W3BuffCustomParams)	//modSigns
	{	//modSigns
		super.OnEffectAdded(customParams);	//modSigns
		GMRecalcM25Bonus();	//modSigns
	}	//modSigns
}

// 5.x body: 1.32's attack power on horseback. Changes marked //modSigns.
@replaceMethod(W3Mutagen25_Effect)
function GetAttackPowerBonus() : SAbilityAttributeValue
{
	var none : SAbilityAttributeValue;	//modSigns
	return none;	//modSigns: ALCH-12, no attack power on horseback (legacy)
}

function GMRecalcSlotDecoctions()
{
	if(thePlayer.HasBuff(EET_Mutagen23))
		((W3Mutagen23_Effect)thePlayer.GetBuff(EET_Mutagen23)).GMAddM23Abilities();
	if(thePlayer.HasBuff(EET_Mutagen25))
		((W3Mutagen25_Effect)thePlayer.GetBuff(EET_Mutagen25)).GMRecalcM25Bonus();
}

@wrapMethod(W3PlayerAbilityManager)
function OnSkillMutagenEquipped(item : SItemUniqueId, slot : EEquipmentSlots, prevColor : ESkillColor)
{
	wrappedMethod(item, slot, prevColor);
	GMRecalcSlotDecoctions();
}

@wrapMethod(W3PlayerAbilityManager)
function OnSkillMutagenUnequipped(out item : SItemUniqueId, slot : EEquipmentSlots, prevColor : ESkillColor, optional dontMerge : bool)
{
	wrappedMethod(item, slot, prevColor, dontMerge);
	GMRecalcSlotDecoctions();
}

@wrapMethod(W3PlayerAbilityManager)
function OnSwappedMutagensPost(a : SItemUniqueId, b : SItemUniqueId)
{
	wrappedMethod(a, b);
	GMRecalcSlotDecoctions();
}

// Horse panic: 5.x bodies without Nekker Warrior's immunity (legacy removed 1.32's). Changes marked //modSigns.
@replaceMethod(CNewNPC)
function GainStat( stat : EBaseCharacterStats, amount : float )
{
	//modSigns: removed Nekker Warrior's horse panic immunity (ALCH-12)
	super.GainStat(stat, amount);
}

@replaceMethod(CNewNPC)
function ForceSetStat(stat : EBaseCharacterStats, val : float)
{
	//modSigns: removed Nekker Warrior's horse panic immunity (ALCH-12)
	super.ForceSetStat(stat, val);
}

@replaceMethod(W3HorseComponent)
function ShouldUpdatePanic() : bool
{
	var horseActor : CActor;

	horseActor 	= (CActor)GetEntity();

	return !horseActor.HasAbility( 'HorseAxiiBuff' ) && !horseActor.HasBuff( EET_Confusion ) && !horseActor.HasBuff( EET_AxiiGuardMe ) && !horseActor.HasAbility( 'DisableHorsePanic' );	//modSigns: removed Nekker Warrior's horse panic immunity (ALCH-12)
}

@replaceMethod(W3HorseComponentStateExploration)
function OnTakeDamage( action : W3DamageAction )
{	
	var actorAttacker : CNewNPC;
	var isMonster : bool;
	var threatMult : int;
	
	if( parentActor.HasAbility( 'DisableHorsePanic' ) )	//modSigns: removed Nekker Warrior's horse panic immunity (ALCH-12)
		return false;
	
	actorAttacker = (CNewNPC)action.attacker;
	isMonster = actorAttacker.IsMonster();
	
	if( isMonster )
		threatMult = 2;
	else
		threatMult = 1;
	
	parentActor.AddPanic( actorAttacker.GetThreatLevel() * 10 * threatMult );
}

@replaceMethod(W3HorseComponentStateExploration)
function OnCriticalEffectAdded( criticalEffect : ECriticalStateType )
{
	if( parentActor.HasAbility( 'DisableHorsePanic' ) )	//modSigns: removed Nekker Warrior's horse panic immunity (ALCH-12)
	{
		if( thePlayer.IsActionAllowed( EIAB_Movement ) )
		{
			return false;
		}
		else if( !isInJumpAnim )
		{
			parent.ShakeOffRider( DT_shakeOff );
		}
	}	
	else if( criticalEffect != ECST_Swarm ) 
	{
		parentActor.AddPanic( 100 );	
		
		
		if( !thePlayer.IsInCombat() )
		{
			parent.ShakeOffRider( DT_shakeOff );
		}	
	}
}
