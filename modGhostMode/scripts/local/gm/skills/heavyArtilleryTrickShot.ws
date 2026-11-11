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

// 5.x body; changes marked //modSigns.
@replaceMethod(CInventoryComponent)
function SingletonItemGetMaxAmmo(itemID : SItemUniqueId) : int
{
	var ammo, i : int;
	var perk20Bonus, min, max : SAbilityAttributeValue;
	var atts : array<name>;
	var canUseSkill : bool;

	ammo = RoundMath(CalculateAttributeValue(GetItemAttributeValue(itemID, 'ammo')));

	if( !ItemHasTag( itemID, 'NoAdditionalAmmo' ) )
	{
		if(GetEntity() == GetWitcherPlayer() && ammo > 0)
		{
			if(IsItemBomb(itemID) && thePlayer.CanUseSkill(S_Alchemy_s08) )
			{
				ammo += thePlayer.GMEfficiencyBonus();	//modSigns: SKL-15, Efficiency (legacy: +1 per level; new tree +1/+3/+5, skills/bombs.ws)
			}

			if(thePlayer.HasBuff(EET_Mutagen03) && (IsItemBomb(itemID) || (!IsItemMutagenPotion(itemID) && IsItemPotion(itemID))) )
			{
				ammo += 1;
			}

			if( GetWitcherPlayer().IsSetBonusActive( EISB_RedWolf_2 ) && !IsItemMutagenPotion(itemID) )
			{
				theGame.GetDefinitionsManager().GetAbilityAttributeValue( GetSetBonusAbility( EISB_RedWolf_2 ), 'amount', min, max);
				ammo += (int)min.valueAdditive;
			}


			if( IsItemBomb( itemID ) && GetWitcherPlayer().GMHeavyArtillerySkill() != S_SUndefined &&  GetItemName( itemID ) != 'Snow Ball' )	//modSigns: either tree
			{
				GetItemAttributes( itemID, atts );
				canUseSkill = thePlayer.CanUseSkill( S_Alchemy_s10 );
				perk20Bonus = GetWitcherPlayer().GetSkillAttributeValue( GetWitcherPlayer().GMHeavyArtillerySkill(), 'stack_multiplier', false, false );	//modSigns

				for( i=0 ; i<atts.Size() ; i+=1 )
				{
					if( canUseSkill || IsDamageTypeNameValid( atts[i] ) )
					{
						ammo = RoundMath( ammo * perk20Bonus.valueMultiplicative );
						break;
					}
				}
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
