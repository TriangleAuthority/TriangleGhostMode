// Ghost Mode: the Balisse fruit fix (LOOT-05, legacy's "balisse fruit temp fix"; the owner's DT7: ported,
// whether 5.x still has the bug is an open check). Balisse fruit bushes refill like renewable loot and
// always hold a fruit once refilled; herbalists keep 10 fruit in stock (at spawn and at each restock).
// See docs/features/loot.md.

// Legacy's W3MerchantNPC.BalisseFruitTempFix: a herbalist without Balisse fruit gets 10.
@addMethod(W3MerchantNPC)
function GMBalisseFruitFix()
{
	var merchant : W3MerchantComponent;
	var inv : CInventoryComponent;

	merchant = (W3MerchantComponent)GetComponentByClassName('W3MerchantComponent');
	inv = GetInventory();
	if(inv && merchant && merchant.GetMapPinType() == 'Herbalist')
	{
		if(!inv.HasItem('Balisse fruit'))
			inv.AddAnItem('Balisse fruit', 10);
	}
}

@wrapMethod(W3MerchantNPC)
function OnSpawned( spawnData : SEntitySpawnData )
{
	wrappedMethod( spawnData );
	if(GetInventory())
		GMBalisseFruitFix();
}

// Legacy called it in OnInteraction when the merchant restocks (its funds refreshed: lastDayOfInteraction
// moves on), as ITEM-02's GMClearLowLevelWeapons.
@wrapMethod(W3MerchantNPC)
function OnInteraction( actionName : string, activator : CEntity )
{
	var day : int;
	var res : bool;

	day = lastDayOfInteraction;
	res = wrappedMethod( actionName, activator );
	if ( actionName == "Talk" && lastDayOfInteraction != day && GetInventory() )
		GMBalisseFruitFix();
	return res;
}

// LOOT-05: a Balisse fruit bush refills as renewable loot, and holds a fruit when it refills empty.
@replaceMethod(W3RefillableContainer)
function Refill(td : float, id : int)
{
	var inv : CInventoryComponent;
	var oldMoney, i : int;
	var oldItems : array<SItemUniqueId>;
	var oldItemsCounts : array<int>;
	var herbBonusChance : float;
	var isBalisse : bool; //modSigns: balisse fix

	isBalisse = StrEndsWith( GetReadableName(), "balisse_fruit.w2ent" ); //modSigns: balisse fix
	inv = GetInventory();
	if ( inv && ( inv.IsLootRenewable() || isBalisse ) ) //modSigns: balisse fix
	{
		if( inv.IsReadyToRenew() )
		{
			PreRefillContainer();
		}


		if(isPlayerInActivationRange)
		{
			oldMoney = inv.GetMoney();
			herbBonusChance = CalculateAttributeValue(thePlayer.GetAttributeValue('bonus_herb_chance'));

			if(herbBonusChance > 0)
			{
				inv.GetAllItems(oldItems);
				oldItemsCounts.Resize(oldItems.Size());
				for(i=0; i<oldItems.Size(); i+=1)
					oldItemsCounts[i] = inv.GetItemQuantity(oldItems[i]);
			}
		}

		inv.UpdateLoot();
		if( isBalisse && inv.IsEmpty() ) //modSigns: balisse fix
			inv.AddAnItem('Balisse fruit', 1); //modSigns: balisse fix
		checkedForBonusMoney = false;
		checkedForBonusHerbs = false;


		if(isPlayerInActivationRange)
		{
			checkedForBonusMoney = true;
			checkedForBonusHerbs = true;
			CheckForBonusMoney(oldMoney);

			if(herbBonusChance > 0)
				CheckForBonusHerbs(oldItems, oldItemsCounts, herbBonusChance);
		}

		if ( !inv.IsEmpty() )
		{
			isEmpty = false;

			SetFocusModeVisibility( FMV_Interactive );
			ApplyAppearance( "1_full" );
			Enable( true );
			RemoveTimer( 'Refill' );
		}
	}
	else
	{
		RemoveTimer( 'Refill' );
	}
}
