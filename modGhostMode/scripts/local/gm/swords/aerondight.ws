// SWD-05: Aerondight as legacy redesigned it. See docs/features/swd.md.
// The effect exists only in combat (added at combat start or when Aerondight is drawn in combat,
// removed when combat ends; paused while sheathed). Each successful hit adds a charge (hitsToCharge
// for a full charge); a charge decays every stackDrainDelay seconds and all are lost when Geralt takes
// damage. The fully charged sword's next hit is a certain critical hit (crit_chance_bonus, 5.x's term
// in ProcessCriticalHitCheck) with +crit_dmg_bonus crit power that ignores armor and resistances; it
// discharges, dealing collateral_dmg shock damage and a stagger to hostile enemies within 3 m. While in
// combat the sword's damage rises by dmg_boost_per_enemy per hostile enemy (GetTotalWeaponDamage).
// Vanilla's permanent damage growth, its pool bonus per charge and the charges on kills are gone.
// The vanilla fields serve legacy's: m_currCount the charges, m_maxCount hitsToCharge,
// m_aerondightDelay and m_aerondightTime the decay.

@addField(W3Effect_Aerondight)
var gmCritDmgBonus : float;
@addField(W3Effect_Aerondight)
var gmDmgBoostPerEnemy : float;
@addField(W3Effect_Aerondight)
var gmCollateralDmg : float;

// The effect's values, from its ability (legacy InitXmlValues).
@replaceMethod(W3Effect_Aerondight)
function LoadParams()
{
	var dm : CDefinitionsManagerAccessor;	//modSigns
	var min, max : SAbilityAttributeValue;	//modSigns

	dm = theGame.GetDefinitionsManager();	//modSigns
	dm.GetAbilityAttributeValue(abilityName, 'crit_dmg_bonus', min, max);	//modSigns
	gmCritDmgBonus = CalculateAttributeValue(min);	//modSigns
	dm.GetAbilityAttributeValue(abilityName, 'dmg_boost_per_enemy', min, max);	//modSigns
	gmDmgBoostPerEnemy = CalculateAttributeValue(min);	//modSigns
	dm.GetAbilityAttributeValue(abilityName, 'collateral_dmg', min, max);	//modSigns
	gmCollateralDmg = CalculateAttributeValue(min);	//modSigns
	dm.GetAbilityAttributeValue(abilityName, 'hitsToCharge', min, max);	//modSigns
	m_maxCount = RoundMath(CalculateAttributeValue(min));	//modSigns
	dm.GetAbilityAttributeValue(abilityName, 'stackDrainDelay', min, max);	//modSigns
	m_aerondightDelay = CalculateAttributeValue(min);	//modSigns
}

@replaceMethod(W3Effect_Aerondight)
function OnEffectAdded( customParams : W3BuffCustomParams )
{
	LoadParams();	//modSigns
	GMResetCharges();	//modSigns
	SetShowOnHUD(true);	//modSigns: legacy's effect definition shows it on the HUD (5.x's only after a resume)

	super.OnEffectAdded( customParams );
}

// A charge decays every stackDrainDelay seconds.
@replaceMethod(W3Effect_Aerondight)
function OnUpdate( deltaTime : float )
{
	m_aerondightTime -= deltaTime;

	if( m_aerondightTime <= 0 )	//modSigns
		GMRemoveCharge();	//modSigns

	super.OnUpdate( deltaTime );
}

// Legacy: charges only from hits (GMAddCharge); kept for other callers.
@replaceMethod(W3Effect_Aerondight)
function IncreaseAerondightCharges( attackName : name )
{
	GMAddCharge();	//modSigns
}

// Vanilla's 10 charge stages mapped onto legacy's charges.
@replaceMethod(W3Effect_Aerondight)
function UpdateAerondightFX()
{
	var l_aerondightEnt			: CItemEntity;
	var l_effectComponent		: W3AerondightFXComponent;
	//modSigns: removed l_newChargingEffect (5.x's one stage per charge)

	target.GetInventory().GetCurrentlyHeldSwordEntity( l_aerondightEnt );

	l_effectComponent = (W3AerondightFXComponent)l_aerondightEnt.GetComponentByClassName( 'W3AerondightFXComponent' );

	//modSigns: removed 5.x's stop of the last stage's effect and the stage per charge
	if( m_currCount > 0 )	//modSigns
		l_aerondightEnt.PlayEffect( l_effectComponent.m_visualEffects[ GMModded2Vanilla( l_effectComponent.m_visualEffects.Size() ) ] );	//modSigns
	else	//modSigns
		l_aerondightEnt.PlayEffect( l_effectComponent.m_visualEffects[ 0 ] );	//modSigns
}

@replaceMethod(W3Effect_Aerondight)
function DischargeAerondight() : bool
{
	GMDischargeAerondight();	//modSigns
	return true;	//modSigns
}

@replaceMethod(W3Effect_Aerondight)
function OnPaused()
{
	super.OnPaused();

	SetShowOnHUD( false );
	GMResetCharges();	//modSigns: sheathing resets the charges
}

@replaceMethod(W3Effect_Aerondight)
function OnResumed()
{
	//modSigns: removed 5.x's variables for the charges lost during the pause
	super.OnResumed();

	SetShowOnHUD( true );	//modSigns
	GMResetCharges();	//modSigns: drawing starts without charges
}

// All of the sword's effects (StopEffect does not reach the sword's child entities).
@replaceMethod(W3Effect_Aerondight)
function StopAerondightEffects()
{
	var l_aerondightEnt			: CItemEntity;

	target.GetInventory().GetCurrentlyHeldSwordEntity( l_aerondightEnt );

	l_aerondightEnt.StopAllEffects();	//modSigns
}

@addMethod(W3Effect_Aerondight)
function GMAddCharge()
{
	m_aerondightTime = m_aerondightDelay;
	if(IsFullyCharged())
		return;
	m_currCount += 1;
	UpdateAerondightFX();
}

@addMethod(W3Effect_Aerondight)
function GMRemoveCharge()
{
	m_aerondightTime = m_aerondightDelay;
	if(m_currCount <= 0)
		return;
	m_currCount -= 1;
	if(m_currCount == 0)
		StopAerondightEffects();
	UpdateAerondightFX();
}

@addMethod(W3Effect_Aerondight)
function GMResetCharges()
{
	m_currCount = 0;
	m_aerondightTime = m_aerondightDelay;
	StopAerondightEffects();
	UpdateAerondightFX();
}

@addMethod(W3Effect_Aerondight)
function GMModded2Vanilla(stages : int) : int
{
	return Max(0, RoundMath(1.0 * m_currCount / Max(1, m_maxCount) * stages) - 1);
}

// The discharge: shock damage and a stagger to the hostile enemies within 3 m, except the one hit
// (as Quen's impulse).
@addMethod(W3Effect_Aerondight)
function GMDischargeAerondight(optional excludeEnt : CGameplayEntity)
{
	var ents : array<CGameplayEntity>;
	var i : int;
	var action : W3DamageAction;

	FindGameplayEntitiesInRange(ents, target, 3, 100, , FLAG_OnlyAliveActors + FLAG_ExcludeTarget + FLAG_Attitude_Hostile, target);
	for(i = 0; i < ents.Size(); i += 1)
	{
		if(excludeEnt && ents[i] == excludeEnt)
			continue;
		action = new W3DamageAction in theGame;
		action.Initialize(target, ents[i], this, "AerondightDischarge", EHRT_Light, CPS_AttackPower, false, false, false, false);
		action.SetCannotReturnDamage(true);
		action.SetProcessBuffsIfNoDamage(true);
		action.SetHitEffectAllTypes('hit_electric_quen');
		action.AddDamage(theGame.params.DAMAGE_NAME_SHOCK, gmCollateralDmg);
		action.AddEffectInfo(EET_Stagger);
		theGame.damageMgr.ProcessAction(action);
		delete action;
	}
	target.PlayEffect('lasting_shield_discharge');
	GMResetCharges();
}

@addMethod(W3Effect_Aerondight)
function GMPlayTrailEffect(bloodType : EBloodType)
{
	var ent : CItemEntity;
	var trailFxName : name;

	switch(bloodType)
	{
		case BT_Red : trailFxName = 'aerondight_blood_red'; break;
		case BT_Yellow : trailFxName = 'aerondight_blood_yellow'; break;
		case BT_Black : trailFxName = 'aerondight_blood_black'; break;
		case BT_Green : trailFxName = 'aerondight_blood_green'; break;
	}
	target.GetInventory().GetCurrentlyHeldSwordEntity(ent);
	ent.PlayEffect(trailFxName);
}

// While in combat: dmg_boost_per_enemy per hostile enemy within 30 m.
@addMethod(W3Effect_Aerondight)
function GMGetDamageBoost() : float
{
	var witcher : W3PlayerWitcher;

	witcher = (W3PlayerWitcher)target;
	if(!witcher)
		return 0;
	return witcher.GMGetNumHostilesInRange() * gmDmgBoostPerEnemy;
}

@addMethod(W3Effect_Aerondight)
function GMGetCritPowerBoost() : float
{
	return gmCritDmgBonus;
}

// The effect of a fully charged Aerondight, if this melee hit is made with it; NULL otherwise.
function GMAerondightChargedHit(playerAttacker : CR4Player, attackAction : W3Action_Attack, action : W3DamageAction) : W3Effect_Aerondight
{
	var aerondight : W3Effect_Aerondight;

	if(!playerAttacker || !attackAction || !action.IsActionMelee() || !playerAttacker.inv.ItemHasTag(attackAction.GetWeaponId(), 'Aerondight'))
		return NULL;
	aerondight = (W3Effect_Aerondight)playerAttacker.GetBuff(EET_Aerondight);
	if(aerondight && aerondight.IsFullyCharged())
		return aerondight;
	return NULL;
}

// A successful hit on a hostile charges the sword; a fully charged one discharges (ProcessAction).
function GMAerondightOnHit(playerAttacker : CR4Player, npc : CNewNPC, attackAction : W3Action_Attack)
{
	var aerondight : W3Effect_Aerondight;

	if(!attackAction || attackAction.WasDodged() || !playerAttacker.inv.ItemHasTag(attackAction.GetWeaponId(), 'Aerondight'))
		return;
	aerondight = (W3Effect_Aerondight)playerAttacker.GetBuff(EET_Aerondight);
	if(!aerondight)
		return;
	if(aerondight.IsFullyCharged())
	{
		aerondight.GMPlayTrailEffect(npc.GetBloodType());
		aerondight.GMDischargeAerondight(npc);
	}
	else
		aerondight.GMAddCharge();
}

// Only in combat: out of combat the effect goes (legacy).
@wrapMethod(CR4Player)
function ManageAerondightBuff( apply : bool )
{
	if(!IsInCombat())
	{
		if(HasBuff(EET_Aerondight))
			RemoveBuff(EET_Aerondight);
		return;
	}
	wrappedMethod(apply);
}

@wrapMethod(W3PlayerWitcher)
function OnSpawned(spawnData : SEntitySpawnData)
{
	wrappedMethod(spawnData);
	RemoveBuff(EET_Aerondight);
}

@wrapMethod(W3PlayerWitcher)
function OnCombatStart()
{
	wrappedMethod();
	ManageAerondightBuff(true);
}

@wrapMethod(W3PlayerWitcher)
function OnCombatFinished()
{
	var ret : bool;

	ret = wrappedMethod();
	RemoveBuff(EET_Aerondight);
	return ret;
}

// Equipping Aerondight adds the effect only in combat.
@wrapMethod(W3PlayerWitcher)
function EquipItemInGivenSlot(item : SItemUniqueId, slot : EEquipmentSlots, ignoreMounting : bool, optional toHand : bool) : bool
{
	var ret : bool;

	ret = wrappedMethod(item, slot, ignoreMounting, toHand);
	if(slot == EES_SilverSword && inv.ItemHasTag(item, 'Aerondight') && !IsInCombat() && HasBuff(EET_Aerondight))
		RemoveBuff(EET_Aerondight);
	return ret;
}

// The tooltip: legacy's description and counter (strings 2110992291, 2110992292).
@replaceMethod(W3TooltipComponent)
function GetAerondightTooltipDescription( itemInvComponent : CInventoryComponent, sword : SItemUniqueId ) : string
{
	var uniqueDesc		: string;
	var argsInt			: array<int>;	//modSigns
	var min, max		: SAbilityAttributeValue;
	var aerondight		: W3Effect_Aerondight;	//modSigns
	var dm				: CDefinitionsManagerAccessor = theGame.GetDefinitionsManager();

	dm.GetAbilityAttributeValue( 'AerondightEffect', 'dmg_boost_per_enemy', min, max );	//modSigns
	argsInt.PushBack( RoundMath( min.valueAdditive ) );	//modSigns
	dm.GetAbilityAttributeValue( 'AerondightEffect', 'crit_dmg_bonus', min, max );	//modSigns
	argsInt.PushBack( RoundMath( min.valueAdditive * 100 ) );	//modSigns
	dm.GetAbilityAttributeValue( 'AerondightEffect', 'hitsToCharge', min, max );	//modSigns
	argsInt.PushBack( RoundMath( min.valueAdditive ) );	//modSigns
	dm.GetAbilityAttributeValue( 'AerondightEffect', 'stackDrainDelay', min, max );	//modSigns
	argsInt.PushBack( RoundMath( min.valueAdditive ) );	//modSigns
	uniqueDesc = GetLocStringByKeyExtWithParams( "attribute_name_aerondight", argsInt );	//modSigns

	argsInt.Clear();	//modSigns
	aerondight = (W3Effect_Aerondight)thePlayer.GetBuff( EET_Aerondight );	//modSigns
	if( aerondight )	//modSigns
	{	//modSigns
		argsInt.PushBack( aerondight.GetCurrentCount() );	//modSigns
		argsInt.PushBack( aerondight.GetMaxCount() );	//modSigns
		argsInt.PushBack( RoundMath( aerondight.GMGetDamageBoost() ) );	//modSigns
	}	//modSigns
	else	//modSigns
	{	//modSigns
		argsInt.PushBack( 0 );	//modSigns
		dm.GetAbilityAttributeValue( 'AerondightEffect', 'hitsToCharge', min, max );	//modSigns
		argsInt.PushBack( RoundMath( min.valueAdditive ) );	//modSigns
		argsInt.PushBack( 0 );	//modSigns
	}	//modSigns
	uniqueDesc += GetLocStringByKeyExtWithParams( "attribute_name_aerondight_counter", argsInt );	//modSigns

	return uniqueDesc;
}
