// DMG slice 4: where a hit's weapon damage comes from (DMG-08) and the armor of human NPCs (DMG-15).
// See docs/features/dmg.md.

// DMG-08: an actor's weapon damage is read from the weapon item alone (legacy). Vanilla read the
// actor's attribute (which also holds every held weapon's abilities, and by legacy's comment grew each
// time an NPC respawned) and subtracted the other held weapons. Used by the player and by NPC attacks
// that carry a weapon.
@replaceMethod(CActor)
function GetTotalWeaponDamage(weaponId : SItemUniqueId, damageTypeName : name, crossbowId : SItemUniqueId) : float
{
	var excessiveDamage : SAbilityAttributeValue;
	var i : int;
	var weapons : array<SItemUniqueId>;
	var inv : CInventoryComponent;
	var n : name;
	var damage : float;

	//modSigns: not the actor's attribute (it holds every held weapon's abilities)
	inv = GetInventory();
	excessiveDamage = inv.GetItemAttributeValue(weaponId, damageTypeName);	//modSigns: the weapon's own damage
	excessiveDamage.valueMultiplicative = 1.0;	//modSigns: the multiplier sits on the actor, not on the item
	//modSigns: vanilla's subtraction of the other held weapons and addition of a weapon not held removed

	damage = CalculateAttributeValue(excessiveDamage);

	return damage;
}

// DMG-08: a sword's extra damage types (fire, frost, ...) at full value: vanilla multiplied every
// non-physical damage type by 0 + the grindstone bonus ("Fixed a bug with additional sword damages
// (like fire and frost) not being actually applied to a target", legacy). 5.x's body; the other
// areas' parts (Aerondight, Runeword 4) stay 5.x's until SWD and ENCH; Mutation 9's flat damage is gone (MUT-11).
@replaceMethod(W3PlayerWitcher)
function GetTotalWeaponDamage(weaponId : SItemUniqueId, damageTypeName : name, crossbowId : SItemUniqueId) : float
{
	var damage, durRatio, durMod, itemMod : float;
	var repairObjectBonus, min, max : SAbilityAttributeValue;

	durMod = 1;	//modSigns: vanilla 0, which zeroed non-physical weapon damage
	damage = super.GetTotalWeaponDamage(weaponId, damageTypeName, crossbowId);


	//modSigns: removed Mutation 9's flat bolt damage (MUT-11: legacy doubles the bolt's raw damage, damage/pool.ws)


	if(IsPhysicalResistStat(GetResistForDamage(damageTypeName, false)))
	{
		repairObjectBonus = inv.GetItemAttributeValue(weaponId, theGame.params.REPAIR_OBJECT_BONUS);
		durRatio = -1;

		if(inv.IsIdValid(crossbowId) && inv.HasItemDurability(crossbowId))
		{
			durRatio = inv.GetItemDurabilityRatio(crossbowId);
		}
		else if(inv.IsIdValid(weaponId) && inv.HasItemDurability(weaponId))
		{
			durRatio = inv.GetItemDurabilityRatio(weaponId);
		}


		if(durRatio >= 0)
			durMod = theGame.params.GetDurabilityMultiplier(durRatio, true);
		else
			durMod = 1;
	}


	if( damageTypeName == 'SilverDamage' && inv.ItemHasTag( weaponId, 'Aerondight' ) )
	{
		itemMod = inv.GetItemModifierFloat( weaponId, 'PermDamageBoost' );
		if( itemMod > 0.f )
		{
			damage += itemMod;
		}
	}

	return damage * (durMod + repairObjectBonus.valueMultiplicative);
}

// DMG-15: a human NPC without an armor ability gets the one its entity template includes ("Fixed a
// bug with humans not actually using armor abilities - all of them had zero armor", legacy
// gm_bugfixes.ws LazyArmorFix). Does nothing to an NPC that has one. Legacy called it when an NPC's
// level bonuses were applied; here when it spawns (AI replaces the level bonuses later).
@wrapMethod(CNewNPC)
function OnSpawned(spawnData : SEntitySpawnData)
{
	var ret : bool;

	ret = wrappedMethod(spawnData);
	GMLazyArmorFix(this);
	return ret;
}

function GMLazyArmorFix(npc : CNewNPC)
{
	var template : CEntityTemplate;
	var size, i : int;
	var armorAbility : name;

	if(!npc.IsHuman() || GMHasArmorAbility(npc))
		return;

	template = (CEntityTemplate)LoadResource(npc.GetReadableName(), true);
	if(!template)
		return;
	size = template.includes.Size();
	for(i = 0; i < size; i += 1)
	{
		armorAbility = GMGetArmorAbilityFromPath(template.includes[i].GetPath());
		if(armorAbility != 'none' && !npc.HasAbility(armorAbility))
		{
			npc.AddAbility(armorAbility);
			break;
		}
	}
}

function GMHasArmorAbility(npc : CNewNPC) : bool
{
	return npc.HasAbility('NPC Leather Armor') || npc.HasAbility('NPC Heavy Leather Armor')
		|| npc.HasAbility('NPC Chainmail Armor') || npc.HasAbility('NPC Partial Plate Armor')
		|| npc.HasAbility('NPC Full Plate Armor') || npc.HasAbility('NPC_Wild_Hunt_Armor');
}

function GMGetArmorAbilityFromPath(path : string) : name
{
	if(StrEndsWith(path, "npc_armor_lvl1.w2ent")) return 'NPC Leather Armor';
	if(StrEndsWith(path, "npc_armor_lvl2.w2ent")) return 'NPC Heavy Leather Armor';
	if(StrEndsWith(path, "npc_armor_lvl3.w2ent")) return 'NPC Chainmail Armor';
	if(StrEndsWith(path, "npc_armor_lvl4.w2ent")) return 'NPC Partial Plate Armor';
	if(StrEndsWith(path, "npc_armor_lvl5.w2ent")) return 'NPC Full Plate Armor';
	if(StrEndsWith(path, "npc_armor_lvl6_wild_hunt.w2ent")) return 'NPC_Wild_Hunt_Armor';
	return 'none';
}
