// Ghost Mode: a schematic and a recipe every save learns once at load (legacy's W3PlayerWitcher.OnSpawned,
// fact ModSignsRecipesAdded there): CRAFT-01's new Meteorite plate schematic, and CRAFT-06's "fix missing
// Tawny Owl recipe" (1.32 and 5.x give it only in the standalone starts). See docs/features/craft.md.

@wrapMethod(W3PlayerWitcher)
function OnSpawned(spawnData : SEntitySpawnData)
{
	wrappedMethod(spawnData);
	GMAddCraftGrants();
}

@addMethod(W3PlayerWitcher)
function GMAddCraftGrants()
{
	if(FactsQuerySum("gm_craft_recipes_added") > 0)
		return;
	AddAlchemyRecipe('Recipe for Tawny Owl 1', true, true);
	AddCraftingSchematic('Meteorite plate schematic', true, true);
	FactsAdd("gm_craft_recipes_added");
}
