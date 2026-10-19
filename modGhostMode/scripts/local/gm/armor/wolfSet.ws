// ARM-09: the Wolven set as legacy (DA2, project owner, 2026-10-17).
// - Tier 1 (3 pieces of any tier): every oil effect on the swords +16.7% per piece (+100% at 6): attack
//   power, resistance reduction, critical hit chance and damage against the oil's monster type, wearing off
//   with the oil (SKL-14's GMBonus, skills/oils.ws). Poisoned Blades and Protective Coating are not boosted.
// - Tier 2 (6 grandmaster pieces): up to three different oils on a sword at once (5.x keeps one, as the
//   port's SKL-14); each oil with charges adds +5% critical hit chance (melee) and +10% critical hit damage
//   whatever the enemy, wearing off with the oil. Without tier 2 the extra oils go, the newest one stays.
// - 5.x's bleeding rules are gone: tier 1's sword damage per Bleeding stack (damage/pool.ws) and tier 2's
//   Bleeding stacks by adrenaline (W3EffectManager.InternalAddEffect: turned off for the call by the
//   flag read in IsSetBonusActive, armor/setFramework.ws, instead of replacing that 260-line function).
// See docs/features/arm.md.

@addField(W3PlayerWitcher)
public var gmWolfBleedingOff : bool;

@addMethod(W3PlayerWitcher)
function GMSetWolfBleedingOff(off : bool)
{
	gmWolfBleedingOff = off;
}

// 5.x's Wolven tier 2 turns a second bleed on an NPC into a stack of wounds (EET_Bleeding1 to 3) by
// adrenaline; legacy's tier 2 has no such rule.
@wrapMethod(W3EffectManager)
function InternalAddEffect(effectType : EEffectType, creat : CGameplayEntity, srcName : string, optional inDuration : float, optional customVal : SAbilityAttributeValue, optional customAbilityName : name, optional customFXName : name, optional signEffect : bool, optional powerStatValue : SAbilityAttributeValue, optional customParams : W3BuffCustomParams, optional vibratePadLowFreq : float, optional vibratePadHighFreq : float) : EEffectInteract
{
	var witcher : W3PlayerWitcher;
	var result : EEffectInteract;
	var off : bool;

	witcher = GetWitcherPlayer();
	off = effectType == EET_Bleeding && witcher && !witcher.gmWolfBleedingOff;
	if(off)
		witcher.GMSetWolfBleedingOff(true);
	result = wrappedMethod(effectType, creat, srcName, inDuration, customVal, customAbilityName, customFXName, signEffect, powerStatValue, customParams, vibratePadLowFreq, vibratePadHighFreq);
	if(off)
		witcher.GMSetWolfBleedingOff(false);
	return result;
}

// Tier 1: the factor on an oil's own bonuses (1 without the set).
function GMWolfOilMult() : float
{
	var witcher : W3PlayerWitcher;
	var min, max : SAbilityAttributeValue;

	witcher = GetWitcherPlayer();
	if(!witcher || !witcher.IsSetBonusActive(EISB_Wolf_1))
		return 1;
	theGame.GetDefinitionsManager().GetAbilityAttributeValue(GetSetBonusAbility(EISB_Wolf_1), 'per_piece_oil_bonus', min, max);
	return 1 + CalculateAttributeValue(min) * witcher.GetSetPartsEquipped(EIST_Wolf);
}

// Tier 2: this oil's crit bonus (per_oil_crit_chance_bonus or per_oil_crit_power_bonus), whatever the
// enemy, wearing off; 0 for an empty oil or without the set.
@addMethod(W3Effect_Oil)
function GMWolfCritBonus(attributeName : name) : float
{
	var witcher : W3PlayerWitcher;
	var min, max : SAbilityAttributeValue;

	witcher = GetWitcherPlayer();
	if(!witcher || GetAmmoCurrentCount() < 1 || !witcher.IsSetBonusActive(EISB_Wolf_2))
		return 0;
	theGame.GetDefinitionsManager().GetAbilityAttributeValue(GetSetBonusAbility(EISB_Wolf_2), attributeName, min, max);
	return CalculateAttributeValue(min) * GMScaleFactor();
}

// Tier 2: the sum over the oils on the item.
@addMethod(CInventoryComponent)
function GMOilWolfCritBonus(weaponId : SItemUniqueId, attributeName : name) : float
{
	var oils : array<W3Effect_Oil>;
	var bonus : float;
	var i : int;

	oils = GetOilsAppliedOnItem(weaponId);
	for(i = 0; i < oils.Size(); i += 1)
		bonus += oils[i].GMWolfCritBonus(attributeName);
	return bonus;
}

// Tier 2: how many oils a sword holds (1 without it).
@addMethod(CR4Player)
function GMMaxOilsPerSword() : int
{
	var witcher : W3PlayerWitcher;
	var min, max : SAbilityAttributeValue;

	witcher = (W3PlayerWitcher)this;
	if(!witcher || !witcher.IsSetBonusActive(EISB_Wolf_2))
		return 1;
	theGame.GetDefinitionsManager().GetAbilityAttributeValue(GetSetBonusAbility(EISB_Wolf_2), 'max_oils_count', min, max);
	return Max(1, RoundMath(CalculateAttributeValue(max)));
}

// Without tier 2, both equipped swords keep only their newest oil (legacy: in UpdateItemSetBonuses).
@addMethod(W3PlayerWitcher)
function GMRemoveExtraOilsFromSwords()
{
	var id : SItemUniqueId;

	if(IsSetBonusActive(EISB_Wolf_2))
		return;
	if(GetItemEquippedOnSlot(EES_SteelSword, id))
		RemoveExtraOilsFromItem(id);
	if(GetItemEquippedOnSlot(EES_SilverSword, id))
		RemoveExtraOilsFromItem(id);
}

// Legacy's body: the newest oil stays (5.x removes every oil; 5.x also calls it when Fixative is taken
// off, which with one oil per sword now keeps it). Nothing goes while tier 2 is on.
@replaceMethod(W3PlayerWitcher)
function RemoveExtraOilsFromItem( item : SItemUniqueId )
{
	var oils : array< CBaseGameplayEffect >;
	var i, cnt : int;
	var buff : W3Effect_Oil;

	if( IsSetBonusActive( EISB_Wolf_2 ) )	//modSigns: ARM-09, three oils with tier 2
		return;	//modSigns

	//modSigns: removed 5.x's removal of every oil
	oils = GetBuffs( EET_Oil );	//modSigns: legacy's body
	for( i=0; i<oils.Size(); i+=1 )	//modSigns
	{	//modSigns
		buff = (W3Effect_Oil) oils[ i ];	//modSigns
		if( buff && buff.GetSwordItemId() == item )	//modSigns
		{	//modSigns
			cnt += 1;	//modSigns
		}	//modSigns
	}	//modSigns
	while( cnt > 1 )	//modSigns
	{	//modSigns
		inv.RemoveOldestOilFromItem( item );	//modSigns
		cnt -= 1;	//modSigns
	}	//modSigns
}
