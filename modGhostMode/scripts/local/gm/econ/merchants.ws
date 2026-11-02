// ECON-08 (PE6): merchants' money, as legacy. See docs/features/econ.md. A merchant restocks his money
// every 3 days (5.x: 5) when Geralt talks to him, and gets his starting money again at spawn when he holds
// less than 100 crowns (5.x: only at 0). The funds factors by merchant type and region are the mod_funds
// row of economy_tagmodifiers.csv (PE5, slice E1).

// ECON-08: the restock interval W3MerchantNPC.OnInteraction reads through GetDaysToIncreaseFunds.
import class CInventoryComponent extends CComponent
{
	default daysToIncreaseFunds = 3; //modSigns: 5 -> 3
}

// ECON-08: legacy's OnSpawned set the funds up when the merchant held less than 100 crowns, where 5.x's
// does at 0. 5.x's body runs first, so a merchant at 0 is set up there (at least 160 crowns with legacy's
// factors, at most the 0 of a broke merchant) and this adds nothing more: the result is legacy's.
@wrapMethod(W3MerchantNPC)
function OnSpawned( spawnData : SEntitySpawnData )
{
	var inv : CInventoryComponent; //modSigns

	wrappedMethod( spawnData );
	inv = GetInventory(); //modSigns
	if ( inv && inv.GetMoney() < 100 ) //modSigns: legacy's reset below 100 (5.x: == 0)
		inv.SetupFunds(); //modSigns
}
