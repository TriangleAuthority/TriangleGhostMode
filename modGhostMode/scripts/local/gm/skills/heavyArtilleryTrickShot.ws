// SKL-18: Heavy Artillery and Trick Shot, legacy's in both trees (D49, D61; classic perk_20 and
// perk_17, the new tree's perk_43 and perk_27 in place of 5.x's Synergy perk (which moved to alchemy_s26,
// D60) and Manticore School (gone: its ability is empty)).
// - Heavy Artillery: bomb damage +100% (a pool term for a bomb hit that is not damage over time, x2 on
//   the flat part of its damage over time (legacy; 5.x doubles the whole value) and on gas clouds),
//   bombs per slot halved (5.x: x2 damage), the stacks trimmed when the perk or Pyrotechnics is
//   equipped (legacy). 5.x's code reads perk_20: for perk_43 the same sites are taken here (the stack,
//   Dragon's Dream's gas, the bombs' damage over time).
// - Trick Shot: one extra bolt before reloading.
// See docs/features/skl.md.

@addMethod(W3PlayerWitcher)
function GMHeavyArtillerySkill() : ESkill
{
	if(CanUseSkill(S_Perk_20))
		return S_Perk_20;
	if(CanUseSkill(S_Perk_43))
		return S_Perk_43;
	return S_SUndefined;
}

@addMethod(W3PlayerWitcher)
function GMHasTrickShot() : bool
{
	return CanUseSkill(S_Perk_17) || CanUseSkill(S_Perk_27);
}

// Bomb stacks: SKL-15's Efficiency bonus and SKL-18's Heavy Artillery in either tree. A wrapper, not a
// replacement, so other mods' changes of this method (TrianglePreparations: oils and the alchemy table)
// combine with it in either load order: it adds the difference between Ghost Mode's and 5.x's bomb formula
// to whatever the inner chain returns, and leaves every other item alone (Ghost Mode changes only bombs).
@wrapMethod(CInventoryComponent)
function SingletonItemGetMaxAmmo(itemID : SItemUniqueId) : int
{
	var ammo : int;

	ammo = wrappedMethod(itemID);
	if( IsItemBomb(itemID) && GetEntity() == GetWitcherPlayer() && !ItemHasTag(itemID, 'NoAdditionalAmmo') )	//modSigns
		ammo += GMBombMaxAmmo(itemID, true) - GMBombMaxAmmo(itemID, false);	//modSigns
	return ammo;
}

// A player bomb's stack by 5.x's formula (gmRules false) or Ghost Mode's (true); 5.x's body, bombs only.
@addMethod(CInventoryComponent)
function GMBombMaxAmmo(itemID : SItemUniqueId, gmRules : bool) : int
{
	var ammo, i : int;
	var perk20Bonus, min, max : SAbilityAttributeValue;
	var atts : array<name>;
	var canUseSkill : bool;
	var heavyArtillery : ESkill;

	ammo = RoundMath(CalculateAttributeValue(GetItemAttributeValue(itemID, 'ammo')));
	if( ammo <= 0 )
		return ammo;

	if( thePlayer.CanUseSkill(S_Alchemy_s08) )
	{
		if( gmRules )
			ammo += thePlayer.GMEfficiencyBonus();	//modSigns: SKL-15, Efficiency (legacy: +1 per level; new tree +1/+3/+5, skills/bombs.ws)
		else
			ammo += thePlayer.GetSkillLevel(S_Alchemy_s08);
	}

	if( thePlayer.HasBuff(EET_Mutagen03) )
		ammo += 1;

	if( GetWitcherPlayer().IsSetBonusActive( EISB_RedWolf_2 ) )
	{
		theGame.GetDefinitionsManager().GetAbilityAttributeValue( GetSetBonusAbility( EISB_RedWolf_2 ), 'amount', min, max);
		ammo += (int)min.valueAdditive;
	}

	if( gmRules )
		heavyArtillery = GetWitcherPlayer().GMHeavyArtillerySkill();	//modSigns: either tree
	else if( thePlayer.CanUseSkill( S_Perk_20 ) )
		heavyArtillery = S_Perk_20;
	else
		heavyArtillery = S_SUndefined;

	if( heavyArtillery != S_SUndefined && GetItemName( itemID ) != 'Snow Ball' )
	{
		GetItemAttributes( itemID, atts );
		canUseSkill = thePlayer.CanUseSkill( S_Alchemy_s10 );
		perk20Bonus = GetWitcherPlayer().GetSkillAttributeValue( heavyArtillery, 'stack_multiplier', false, false );

		for( i=0 ; i<atts.Size() ; i+=1 )
		{
			if( canUseSkill || IsDamageTypeNameValid( atts[i] ) )
			{
				ammo = RoundMath( ammo * perk20Bonus.valueMultiplicative );
				break;
			}
		}
	}

	return ammo;
}

// 5.x body; changes marked //modSigns.
@replaceMethod(W3DragonsDream)
function ProcessMechanicalEffect(targets : array<CGameplayEntity>, isImpact : bool, optional dt : float)
{
	if(isImpact)
	{
		super.ProcessMechanicalEffect(targets, isImpact, dt);

		gasEntity = (W3ToxicCloud)theGame.CreateEntity(gasEntityTemplate, GetWorldPosition());
		gasEntity.explosionDamage.valueAdditive = loopParams.damages[0].dmgVal;
		gasEntity.SetBurningChance(CalculateAttributeValue(GetOwner().GetInventory().GetItemAttributeValue(itemId, 'burning_chance')));
		gasEntity.SetExplodingTargetDamages(GetExplodingTargetDamages());
		gasEntity.SetFromBomb(GetOwner());
		gasEntity.SetIsFromClusterBomb(isCluster);
		gasEntity.SetFriendlyFire( friendlyFire );


		if( GetWitcherPlayer().GMHasInCombatsFires() )	//modSigns: In Combat's Fires, either tree
		{
			gasEntity.SetWasPerk16Active( true );
		}


		if( (W3PlayerWitcher)GetOwner() && GetWitcherPlayer().GMHeavyArtillerySkill() != S_SUndefined )	//modSigns: either tree
		{
			gasEntity.SetPerk20DamageMultiplierOn();
		}
	}
}

// A bomb's damage over time from Geralt with Heavy Artillery: only its flat part is doubled, as legacy
// (5.x doubles the whole value, the share of maximum health included); for the new tree's perk_43 too
// (5.x's petard sets its flag for perk_20 only). 5.x body; changes marked //modSigns.
@replaceMethod(W3DamageOverTimeEffect)
function OnEffectAdded(optional customParams : W3BuffCustomParams)
{
	var params : W3BuffDoTParams;
	var perk20Bonus :SAbilityAttributeValue;
	var heavyArtillery : ESkill;	//modSigns

	var skillPassiveMod : float;

	params = (W3BuffDoTParams)customParams;
	if(params)
	{
		isEnvironment = params.isEnvironment;
	}


	//modSigns: removed 5.x's potion duration bonus to bomb damage (ALCH-14, the owner's DL7)



	if( params && ( params.isPerk20Active || ( params.isFromBomb && GetCreator() == GetWitcherPlayer() && GetWitcherPlayer().CanUseSkill(S_Perk_43) ) ) )	//modSigns: either tree
	{
		heavyArtillery = GetWitcherPlayer().GMHeavyArtillerySkill();	//modSigns
		if( heavyArtillery == S_SUndefined )	//modSigns: the flag outlives the perk
			heavyArtillery = S_Perk_20;	//modSigns
		perk20Bonus = GetWitcherPlayer().GetSkillAttributeValue( heavyArtillery, 'dmg_multiplier', false, false);	//modSigns
		effectValue.valueAdditive *= ( 1 + perk20Bonus.valueMultiplicative );	//modSigns: the flat part only (legacy)
	}

	AddHealthRegenReductionBuff();

	super.OnEffectAdded(customParams);
}

// Bombs carried above the new stack size are trimmed when Pyrotechnics (with Heavy Artillery it halves
// every bomb's stack) or the new tree's Heavy Artillery is equipped, as legacy's OnSkillEquip; 5.x trims
// for perk_20 only.
@wrapMethod(W3PlayerAbilityManager)
function OnSkillEquip(skill : ESkill)
{
	wrappedMethod(skill);
	if(skill == S_Alchemy_s10 || skill == S_Perk_43)
		thePlayer.SkillReduceBombAmmoBonus();
}

// 5.x body; changes marked //modSigns.
@replaceMethod(Crossbow)
function PlayOwnerReloadAnim() : bool
{
	var shouldPlayAnim : bool;

	if(ownerPlayerWitcher.GMHasTrickShot() && shotCount >= (1 + shotCountLimit) )	//modSigns: either tree
		shouldPlayAnim = true;
	else if (!ownerPlayerWitcher.GMHasTrickShot() && shotCount >= shotCountLimit )	//modSigns
		shouldPlayAnim = true;
	else if ( previousAmmoItemName != 'Bodkin Bolt' && previousAmmoItemName != 'Harpoon Bolt' && GetSpecialAmmoCount() <= 0 )
		shouldPlayAnim = true;
	else if ( previousAmmoItemName == '' )
		shouldPlayAnim = true;
	else
		shouldPlayAnim = false;

	if ( shouldPlayAnim )
	{
		SetBehaviorGraphVariables( 'isWeaponLoaded', false );
		return true;
	}
	else
		return false;
}
