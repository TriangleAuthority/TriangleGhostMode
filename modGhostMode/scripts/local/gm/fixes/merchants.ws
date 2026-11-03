// FIX-06: Wolfmark's Generic Merchants Fix ("resolves a problem with some generic merchants not showing their goods",
// changelist 37). Some travelling merchants spawn without the tags their dialogue scene needs: "Show me your goods"
// (ShowMeGoods, which finds the merchant by tag) opens nothing, the scene may use the wrong model, and the map shows no
// pin. A merchant of the generic shop scene gets the scene's required tags first, his own after them (legacy's order;
// the original's ShopkeeperEntity tag ends up among his own, PK8). Ported without first looking for a failing merchant
// in 5.x (DK1 (a)): where the tags are already right it changes nothing. See docs/features/fix.md.
@wrapMethod(W3MerchantNPC)
function OnSpawned( spawnData : SEntitySpawnData )
{
	wrappedMethod(spawnData);
	GMFixGenericMerchantTags();
}

// FIX-06: legacy's block (WMK), in a method so a test can read what it does.
@addMethod(W3MerchantNPC)
function GMFixGenericMerchantTags()
{
	var tags : array<name>;

	if(embeddedScenes.Size() > 0)
	{
		if(StrBeginsWith(embeddedScenes[0].storyScene.GetPath(), "living_world\dialogue\generic_merchants\shop_generic_merchant"))
		{
			tags = embeddedScenes[0].storyScene.GetRequiredPositionTags();
			ArrayOfNamesAppendUnique(tags, GetTags());
			SetTags(tags);
		}
	}
}
