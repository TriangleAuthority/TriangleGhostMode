// MUT-01: the mutation system. Legacy Ghost Mode's research costs in skill points, 29 in all
// (1.32 and 5.x: 53), in both skill trees (DM1); the equipped mutation's sound bank loaded again
// on load (legacy's fix; 5.x reloads only Mutation 6's). Mutagen costs and the research tree are
// unchanged. The greater mutagens spent are refunded by the character reset (SKL-01).
// See docs/features/mut.md.

// Legacy's skill-point cost per mutation (legacy geralt_mutations.xml, <custom><mutations>).
function GMMutationResearchSkillPoints(mut : EPlayerMutationType) : int
{
	switch(mut)
	{
		case EPMT_Mutation1 : return 3;
		case EPMT_Mutation2 : return 1;
		case EPMT_Mutation3 : return 2;
		case EPMT_Mutation4 : return 1;
		case EPMT_Mutation5 : return 3;
		case EPMT_Mutation6 : return 2;
		case EPMT_Mutation7 : return 3;
		case EPMT_Mutation8 : return 1;
		case EPMT_Mutation9 : return 3;
		case EPMT_Mutation10 : return 2;
		case EPMT_Mutation11 : return 4;
		case EPMT_Mutation12 : return 4;
	}
	return -1;
}

// LoadMutationData refreshes the costs from the XML on every load (new game and saved game);
// legacy's costs are laid on after it. Skill points a save spent above the new cost (research
// paid at 5.x's prices) are given back.
@wrapMethod(W3PlayerAbilityManager)
function LoadMutationData()
{
	var i, cost, excess : int;
	var witcher : W3PlayerWitcher;

	wrappedMethod();

	witcher = (W3PlayerWitcher)owner;
	excess = 0;
	for(i = 0; i < mutations.Size(); i += 1)
	{
		cost = GMMutationResearchSkillPoints(mutations[i].type);
		if(cost < 0)
			continue;
		mutations[i].progress.skillpointsRequired = cost;
		if(mutations[i].progress.skillpointsUsed > cost)
		{
			excess += mutations[i].progress.skillpointsUsed - cost;
			mutations[i].progress.skillpointsUsed = cost;
		}
		mutations[i].progress.overallProgress = -1;
	}
	if(excess > 0 && witcher)
		witcher.AddPoints(ESkillPoint, excess, false);
}

@addMethod(W3PlayerAbilityManager)
function GMGetMutationSkillPoints(mut : EPlayerMutationType, out required : int, out used : int) : bool
{
	var idx : int;

	idx = GetMutationIndex(mut);
	if(idx < 0)
		return false;
	required = mutations[idx].progress.skillpointsRequired;
	used = mutations[idx].progress.skillpointsUsed;
	return true;
}

// The equipped mutation's sound bank (legacy LoadCurrentMutationSoundBank).
@addMethod(W3PlayerAbilityManager)
function GMLoadCurrentMutationSoundBank()
{
	var bank : string;

	bank = GetMutationSoundBank(GetEquippedMutationType());
	if(bank != "" && !theSound.SoundIsBankLoaded(bank))
		theSound.SoundLoadBank(bank, true);
}

@wrapMethod(W3PlayerWitcher)
function OnSpawned(spawnData : SEntitySpawnData)
{
	wrappedMethod(spawnData);
	((W3PlayerAbilityManager)abilityManager).GMLoadCurrentMutationSoundBank();
	GMAddMutationCatalystRecipe();	// MUT-12: the Catalyst's recipe for a character with Life Leech
}
