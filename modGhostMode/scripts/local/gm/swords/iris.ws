// SWD-06: Iris as legacy redesigned it. See docs/features/swd.md.
// Vanilla's phantom weapon manager (light attacks charge it, a charged strong attack's phantom strike
// knocks down) is replaced by an effect, EET_GMPhantomWeapon (legacy's EET_PhantomWeapon), that exists
// only in combat while Iris is drawn (paused while sheathed). Each damaging hit on a hostile adds a charge
// (hitsToCharge for a full charge); a charge decays every stackDrainDelay seconds (a full charge goes at
// once) and all are lost when Geralt takes damage. While fully charged, Iris's slashing damage rises by
// dmg_bonus_prc of Geralt's maximum Vitality (at most his current Vitality), drained from him when the hit
// lands. A strong attack with the fully charged sword is a phantom strike, and the phantom copy strikes
// again: these hits cannot be dodged, are not parried, ignore armor and resistances (GetDamageResists),
// stagger and destroy shields; they discharge the sword. Olgierd's own Iris (an NPC's) strikes so on
// every strong attack (vanilla's NPC behaviour). Holstering no longer discharges it.

// ---- the effect (legacy's W3Effect_PhantomWeapon) ----

class W3GMEffect_PhantomWeapon extends CBaseGameplayEffect
{
	default effectType = EET_GMPhantomWeapon;
	default isPositive = true;

	private var xml_dmg_bonus_prc : float;
	private var xml_hitsToCharge : int;
	private var xml_stackDrainDelay : float;

	private var currCount : int;
	private var drainDelay : float;

	private var chargedLoopedFxName : name;
	private var chargedSingleFxName : name;
	default chargedLoopedFxName = 'special_attack_charged';
	default chargedSingleFxName = 'special_attack_ready';

	private var inv : CInventoryComponent;
	private var itemId : SItemUniqueId;

	private function InitXmlValues()
	{
		var defMgr : CDefinitionsManagerAccessor = theGame.GetDefinitionsManager();
		var min, max : SAbilityAttributeValue;

		defMgr.GetAbilityAttributeValue(abilityName, 'dmg_bonus_prc', min, max);
		xml_dmg_bonus_prc = CalculateAttributeValue(min);
		defMgr.GetAbilityAttributeValue(abilityName, 'hitsToCharge', min, max);
		xml_hitsToCharge = RoundMath(CalculateAttributeValue(min));
		defMgr.GetAbilityAttributeValue(abilityName, 'stackDrainDelay', min, max);
		xml_stackDrainDelay = CalculateAttributeValue(min);
	}

	private function InitWeapon()
	{
		var itemIds : array<SItemUniqueId>;

		inv = target.GetInventory();
		itemIds = inv.GetItemsByTag('PhantomWeapon');
		if(itemIds.Size())
			itemId = itemIds[0];
	}

	event OnEffectAdded(customParams : W3BuffCustomParams)
	{
		InitXmlValues();
		InitWeapon();
		ResetCharges();
		super.OnEffectAdded(customParams);
	}

	event OnEffectRemoved()
	{
		ResetCharges();
		super.OnEffectRemoved();
	}

	protected function OnPaused()
	{
		super.OnPaused();
		SetShowOnHUD(false);
		ResetCharges();
	}

	protected function OnResumed()
	{
		super.OnResumed();
		SetShowOnHUD(true);
		ResetCharges();
	}

	protected function StopTargetFX()
	{
		super.StopTargetFX();
		StopChargedFX();
	}

	event OnUpdate(deltaTime : float)
	{
		drainDelay -= deltaTime;
		if(drainDelay <= 0)
			RemoveCharge();
		super.OnUpdate(deltaTime);
	}

	private function PlayChargedFX()
	{
		inv.PlayItemEffect(itemId, chargedLoopedFxName);
		inv.PlayItemEffect(itemId, chargedSingleFxName);
	}

	private function StopChargedFX()
	{
		inv.StopItemEffect(itemId, chargedLoopedFxName);
		inv.StopItemEffect(itemId, chargedSingleFxName);
	}

	// A full charge decays at once.
	public function RemoveCharge()
	{
		drainDelay = xml_stackDrainDelay;
		if(currCount <= 0)
			return;
		if(IsFullyCharged())
			ResetCharges();
		else
		{
			currCount -= 1;
			if(currCount == 0)
				StopChargedFX();
		}
	}

	public function AddCharge()
	{
		drainDelay = xml_stackDrainDelay;
		if(IsFullyCharged())
			return;
		currCount += 1;
		if(currCount == xml_hitsToCharge)
			PlayChargedFX();
	}

	public function ResetCharges()
	{
		currCount = 0;
		StopChargedFX();
	}

	public function DischargePhantomWeapon()
	{
		ResetCharges();
		target.RemoveAbility('ForceDismemberment');
	}

	public function GetDamageBoost() : float
	{
		return MinF(target.GetMaxHealth() * xml_dmg_bonus_prc, target.GetCurrentHealth());
	}

	public function DrainAttackerHealth()
	{
		var hpToDrain : float;

		hpToDrain = GetDamageBoost();
		hpToDrain = MinF(hpToDrain, target.GetCurrentHealth() - 1);
		hpToDrain = ClampF(hpToDrain, 0, target.GetMaxHealth() - 1);
		if(hpToDrain > 0)
			target.DrainVitality(hpToDrain);
	}

	public function IsFullyCharged() : bool
	{
		return currCount == xml_hitsToCharge;
	}

	public function GetCurrentCount() : int
	{
		return currCount;
	}

	public function GetMaxCount() : int
	{
		return xml_hitsToCharge;
	}
}

// ---- managing the effect (legacy's ManageIrisBuff and its callers) ----

// Only in combat, while Iris is drawn: added or resumed (apply), paused (sheathed).
@addMethod(CR4Player)
function GMManageIrisBuff(apply : bool)
{
	var phantomWeapon : W3GMEffect_PhantomWeapon;
	var item : SItemUniqueId;

	if(!IsInCombat())
	{
		if(HasBuff(EET_GMPhantomWeapon))
			RemoveBuff(EET_GMPhantomWeapon);
		return;
	}
	item = inv.GetCurrentlyHeldSword();
	if(!inv.ItemHasTag(item, 'PhantomWeapon'))
		return;
	phantomWeapon = (W3GMEffect_PhantomWeapon)GetBuff(EET_GMPhantomWeapon);
	if(apply)
	{
		if(!phantomWeapon)
			AddEffectDefault(EET_GMPhantomWeapon, this, "PhantomWeapon");
		else
			phantomWeapon.Resume('ManageIrisBuff');
	}
	else if(phantomWeapon)
		phantomWeapon.Pause('ManageIrisBuff');
}

// Vanilla's manager is no longer created (legacy removed it), so nothing else charges or discharges
// Iris: vanilla's discharge on holstering (WeaponHolster.DischargePhantomWeapon) finds no manager.
@replaceMethod(CR4Player)
function InitPhantomWeaponMgr()
{
	//modSigns: removed the creation of vanilla's CPhantomWeaponManager (SWD-06: Iris is an effect)
}

@wrapMethod(W3PlayerWitcher)
function OnSpawned(spawnData : SEntitySpawnData)
{
	wrappedMethod(spawnData);
	RemoveBuff(EET_GMPhantomWeapon);
}

@wrapMethod(W3PlayerWitcher)
function OnCombatStart()
{
	wrappedMethod();
	GMManageIrisBuff(true);
}

@wrapMethod(W3PlayerWitcher)
function OnCombatFinished()
{
	var ret : bool;

	ret = wrappedMethod();
	RemoveBuff(EET_GMPhantomWeapon);
	return ret;
}

// Equipping Iris in combat adds the effect paused (it resumes when drawn).
@wrapMethod(W3PlayerWitcher)
function EquipItemInGivenSlot(item : SItemUniqueId, slot : EEquipmentSlots, ignoreMounting : bool, optional toHand : bool) : bool
{
	var ret : bool;
	var phantomWeapon : W3GMEffect_PhantomWeapon;

	ret = wrappedMethod(item, slot, ignoreMounting, toHand);
	if(ret && slot == EES_SteelSword && inv.ItemHasTag(item, 'PhantomWeapon') && IsInCombat() && !HasBuff(EET_GMPhantomWeapon))
	{
		AddEffectDefault(EET_GMPhantomWeapon, this, "PhantomWeapon");
		phantomWeapon = (W3GMEffect_PhantomWeapon)GetBuff(EET_GMPhantomWeapon);
		if(phantomWeapon)
			phantomWeapon.Pause('ManageIrisBuff');
	}
	return ret;
}

@wrapMethod(W3PlayerWitcher)
function UnequipItemFromSlot(slot : EEquipmentSlots, optional reequipped : bool) : bool
{
	var item : SItemUniqueId;
	var ret : bool;

	GetItemEquippedOnSlot(slot, item);
	ret = wrappedMethod(slot, reequipped);
	if(slot == EES_SteelSword && inv.ItemHasTag(item, 'PhantomWeapon'))
		RemoveBuff(EET_GMPhantomWeapon);
	return ret;
}

// Drawing the steel sword resumes (or adds) the effect.
@wrapMethod(WeaponHolsterStateSelectingWeapon)
function OnEquippedMeleeWeapon(weaponType : EPlayerWeapon)
{
	var ret : bool;

	ret = wrappedMethod(weaponType);
	if(weaponType == PW_Steel)
		thePlayer.GMManageIrisBuff(true);
	return ret;
}

// Sheathing it pauses the effect.
@wrapMethod(CR4Player)
function OnHolsteredItem(category : name, slotName : name)
{
	var ret : bool;

	ret = wrappedMethod(category, slotName);
	if(slotName == 'r_weapon' && category == 'steelsword')
		GMManageIrisBuff(false);
	return ret;
}

// ---- the hits ----

// The fully charged Iris's damage boost, for a slashing damage of Iris (GetTotalWeaponDamage).
function GMIrisDamageBoost(actor : CActor, weaponId : SItemUniqueId, damageTypeName : name) : float
{
	var phantomWeapon : W3GMEffect_PhantomWeapon;

	if(damageTypeName != 'SlashingDamage' || !actor.GetInventory().ItemHasTag(weaponId, 'PhantomWeapon'))
		return 0;
	phantomWeapon = (W3GMEffect_PhantomWeapon)actor.GetBuff(EET_GMPhantomWeapon);
	if(phantomWeapon && phantomWeapon.IsFullyCharged())
		return phantomWeapon.GetDamageBoost();
	return 0;
}

// A damaging hit on a hostile (ProcessAction): the charged sword drains Geralt's Vitality; a phantom
// strike discharges it; any other hit adds a charge.
function GMIrisOnHit(playerAttacker : CR4Player, attackAction : W3Action_Attack)
{
	var phantomWeapon : W3GMEffect_PhantomWeapon;

	if(!attackAction || attackAction.WasDodged() || !playerAttacker.inv.ItemHasTag(attackAction.GetWeaponId(), 'PhantomWeapon'))
		return;
	phantomWeapon = (W3GMEffect_PhantomWeapon)playerAttacker.GetBuff(EET_GMPhantomWeapon);
	if(!phantomWeapon)
		return;
	if(phantomWeapon.IsFullyCharged())
		phantomWeapon.DrainAttackerHealth();
	if(attackAction.GetBuffSourceName() == "PhantomWeapon")
		phantomWeapon.DischargePhantomWeapon();
	else if(!phantomWeapon.IsFullyCharged())
		phantomWeapon.AddCharge();
}

// Damage taken resets the charges (W3PlayerWitcher.OnTakeDamage).
function GMIrisOnDamageTaken(witcher : W3PlayerWitcher)
{
	var phantomWeapon : W3GMEffect_PhantomWeapon;

	if(!witcher.inv.ItemHasTag(witcher.inv.GetCurrentlyHeldSword(), 'PhantomWeapon'))
		return;
	phantomWeapon = (W3GMEffect_PhantomWeapon)witcher.GetBuff(EET_GMPhantomWeapon);
	if(phantomWeapon)
		phantomWeapon.ResetCharges();
}

// The phantom strike: a strong attack with the fully charged Iris (Geralt), or with an NPC's Iris (always).
// The strong attack's own hits are phantom strikes too, and the phantom copy strikes again (legacy).
@replaceMethod(CActor)
function DoAttack(animData : CPreAttackEventData, weaponId : SItemUniqueId, parried : bool, countered : bool, parriedBy : array<CActor>, attackAnimationName : name, hitTime : float)
{
	var i : int;
	var weaponEntity : CItemEntity;
	var phantomWeapon : W3GMEffect_PhantomWeapon;	//modSigns

	phantomStrike = false;
	weaponEntity = GetInventory().GetItemEntityUnsafe(weaponId);

	phantomWeapon = (W3GMEffect_PhantomWeapon)GetBuff( EET_GMPhantomWeapon );	//modSigns: SWD-06, whether this attack is a phantom strike
	if( GetInventory().ItemHasTag( weaponId, 'PhantomWeapon' ) && IsHeavyAttack( attackActionName ) )	//modSigns
	{	//modSigns
		if( this == thePlayer )	//modSigns
		{	//modSigns
			if( phantomWeapon && phantomWeapon.IsFullyCharged() )	//modSigns
				phantomStrike = true;	//modSigns
		}	//modSigns
		else	//modSigns
			phantomStrike = true;	//modSigns
	}	//modSigns


	for(i=0; i<hitTargets.Size(); i+=1)
	{
		Attack(hitTargets[i], animData, weaponId, parried, countered, parriedBy, attackAnimationName, hitTime, weaponEntity);
	}

	//modSigns: removed vanilla's charge by light attacks (the manager): charges come from hits (GMIrisOnHit)
	if( phantomStrike )	//modSigns
	{
		AddTimer('PhantomWeapon', 0.0);
		phantomWeaponHitTime = hitTime + 0.0;
		phantomWeaponAnimData = animData;
		phantomWeaponWeaponId = weaponId;
		phantomWeaponParried = parried;
		phantomWeaponCountered = countered;
		phantomWeaponParriedBy = parriedBy;
		phantomWeaponAttackAnimationName = attackAnimationName;
		phantomWeaponHitTargets = hitTargets;
	}
	else
	{
		attackActionName = '';
	}
	//modSigns: removed vanilla's outer check of the PhantomWeapon tag and its else (attackActionName = '')


	hitTargets.Clear();
	AddTimer('PostAttackDebugRangeClear', 1);
}

// The phantom copy's strike (only started for a phantom strike).
@replaceMethod(CActor)
function PhantomWeapon(dt : float, id : int)
{
	var i : int;
	var weaponEntity : CItemEntity;

	weaponEntity = GetInventory().GetItemEntityUnsafe(phantomWeaponWeaponId);

	//modSigns: removed vanilla's charge check (DoAttack decides the phantom strike)
	if( this == thePlayer )	//modSigns
		AddAbility( 'ForceDismemberment' );	//modSigns: until the strike discharges the sword


	for(i=0; i<phantomWeaponHitTargets.Size(); i+=1)
	{

		phantomWeaponHitTargets[i].AddAbility( 'DisableFinishers', true );
		phantomWeaponHitTargets[i].AddAbility( 'DisableDismemberment', true );

		Attack(phantomWeaponHitTargets[i], phantomWeaponAnimData, phantomWeaponWeaponId, phantomWeaponParried, phantomWeaponCountered, phantomWeaponParriedBy, phantomWeaponAttackAnimationName, phantomWeaponHitTime, weaponEntity);

		phantomWeaponHitTargets[i].RemoveAbility( 'DisableFinishers' );
		phantomWeaponHitTargets[i].RemoveAbility( 'DisableDismemberment' );
	}

	if( !phantomWeaponCountered && phantomWeaponHitTargets.Size() && phantomWeaponParried )
		PlayEffectOnHeldWeapon( 'special_attack_block' );

	AddTimer('PostAttackDebugRangeClear', 1);
	attackActionName = '';
}

// A phantom strike cannot be dodged (DEF-01's hand-off) and its source is "PhantomWeapon"; Geralt's
// staggers (vanilla: a heavy knockdown) and destroys a shield.
@replaceMethod(CActor)
function PrepareAttackAction( hitTarget : CGameplayEntity, animData : CPreAttackEventData, weaponId : SItemUniqueId, parried : bool, countered : bool, parriedBy : array<CActor>, attackAnimationName : name, hitTime : float, weaponEntity : CItemEntity, out attackAction : W3Action_Attack) : bool
{
	var actor : CActor;
	var npc : CNewNPC;	//modSigns
	var canDodge : bool;	//modSigns
	var attackSrc : string;	//modSigns

	if(!hitTarget)
		return false;

	attackAction = new W3Action_Attack in theGame.damageMgr;

	if ( animData.hitFX == 'basedOnWeapon' )
		ChangeHitFxBasedOnWeapon(animData, weaponId);

	if( phantomStrike )	//modSigns
	{	//modSigns
		canDodge = false;	//modSigns
		attackSrc = "PhantomWeapon";	//modSigns
	}	//modSigns
	else	//modSigns
	{	//modSigns
		canDodge = animData.canBeDodged;	//modSigns
		attackSrc = GetName();	//modSigns
	}	//modSigns

	attackAction.Init( this, hitTarget, NULL, weaponId, animData.attackName, attackSrc, animData.hitReactionType, animData.Can_Parry_Attack, canDodge, attackActionName, animData.swingType, animData.swingDir, true, false, false, false, animData.hitFX, animData.hitBackFX, animData.hitParriedFX, animData.hitBackParriedFX);	//modSigns

	attackAction.SetAttackAnimName(attackAnimationName);
	attackAction.SetHitTime(hitTime);
	attackAction.SetWeaponEntity(weaponEntity);
	attackAction.SetWeaponSlot(animData.weaponSlot);
	attackAction.SetSoundAttackType(animData.soundAttackType);

	actor = (CActor)hitTarget;

	if(actor && parriedBy.Contains(actor))
	{
		if(parried)
		{
			attackAction.SetIsParried(true);
			SignalGameplayEvent('AttackParried');
			actor.SignalGameplayEvent('ParryingAttack');
		}
		else if(countered)
		{
			attackAction.SetIsCountered(true);
			SignalGameplayEvent('AttackCountered');
		}
	}


	if ( attackAction.IsParried() && attackAction.attacker.HasAbility('ReflectOnBeingParried') )
	{
		((CActor)attackAction.attacker).SetCanPlayHitAnim( true );
		ReactToReflectedAttack(attackAction.victim);
	}


	if(phantomStrike)
	{
		attackAction.SetIsParried(false);
		attackAction.SetHitAnimationPlayType(EAHA_ForceNo);

		if( attackAction.attacker == thePlayer )
		{
			//modSigns: removed vanilla's discharge (the manager): the hit discharges the effect (GMIrisOnHit)
			npc = (CNewNPC)attackAction.victim;	//modSigns
			if( npc && npc.IsShielded( thePlayer ) )	//modSigns
				npc.ProcessShieldDestruction();	//modSigns
			attackAction.AddEffectInfo( EET_Stagger );	//modSigns: vanilla a heavy knockdown
		}
		else
		{
			if( parried )
			{
				attackAction.AddEffectInfo( EET_Stagger );
				attackAction.ClearDamage();
			}
			else if( !parried && !countered )
			{
				attackAction.AddEffectInfo( EET_Knockdown );
			}
		}
	}

	return true;
}

// ---- the tooltip ----

// Legacy's description with the counter (string 2110992299, the key vanilla gives Iris's description).
@addMethod(W3TooltipComponent)
function GMGetIrisTooltipDescription() : string
{
	var argsInt : array<int>;
	var dm : CDefinitionsManagerAccessor = theGame.GetDefinitionsManager();
	var min, max : SAbilityAttributeValue;
	var phantomWeapon : W3GMEffect_PhantomWeapon;
	var healthPrc : float;
	var hitsToCharge : float;

	dm.GetAbilityAttributeValue('GMPhantomWeaponEffect', 'dmg_bonus_prc', min, max);
	argsInt.PushBack(RoundMath(min.valueAdditive * 100));
	healthPrc = min.valueAdditive;
	dm.GetAbilityAttributeValue('GMPhantomWeaponEffect', 'hitsToCharge', min, max);
	argsInt.PushBack(RoundMath(min.valueAdditive));
	hitsToCharge = min.valueAdditive;
	dm.GetAbilityAttributeValue('GMPhantomWeaponEffect', 'stackDrainDelay', min, max);
	argsInt.PushBack(RoundMath(min.valueAdditive));
	argsInt.PushBack(RoundMath(min.valueAdditive));
	phantomWeapon = (W3GMEffect_PhantomWeapon)thePlayer.GetBuff(EET_GMPhantomWeapon);
	if(phantomWeapon)
		argsInt.PushBack(phantomWeapon.GetCurrentCount());
	else
		argsInt.PushBack(0);
	argsInt.PushBack(RoundMath(hitsToCharge));
	argsInt.PushBack(RoundMath(thePlayer.GetMaxHealth() * healthPrc));
	return GetLocStringByKeyExtWithParams("attribute_name_double_strike", argsInt);
}

// Iris's description: vanilla gives the Iris item (OlgierdSabre tag) the string without its numbers;
// legacy, every PhantomWeapon item the description with them (a sword has no other description).
@wrapMethod(W3TooltipComponent)
function GetBaseItemData( item : SItemUniqueId, itemInvComponent : CInventoryComponent, optional isShopItem : bool, optional compareWithItem : SItemUniqueId, optional compareItemInv : CInventoryComponent ) : CScriptedFlashObject
{
	var tooltipData : CScriptedFlashObject;

	tooltipData = wrappedMethod(item, itemInvComponent, isShopItem, compareWithItem, compareItemInv);
	if(tooltipData && itemInvComponent && itemInvComponent.ItemHasTag(item, 'PhantomWeapon'))
		tooltipData.SetMemberFlashString("Description", itemInvComponent.GMGetEnhancedBuffInfo(item) + GMGetIrisTooltipDescription());	// ITEM-12: the table and grindstone lines first
	return tooltipData;
}
