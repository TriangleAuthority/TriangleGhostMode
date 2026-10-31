// DIFF-06: Ciri's sections on the chosen difficulty (legacy: "Removed vanilla difficulty level restrictions
// for Ciri"), and two of her quest abilities by journal state. Her stats per quest are the abilities in
// gm_diff.xml (tools/gen_diff.py); her enemies' "Death March!" adjustment (CiriHardcoreDebuff*, added in
// AI-01's GMInternalAddLevelBonuses) is emptied there. See docs/features/diff.md.

// DIFF-06: no cap for Ciri: NPCs spawned or updated while she is played get the chosen mode's difficulty
// ability and variants (5.x: at most "Story and Sword!"'s while Ciri is the player). Legacy's body.
// The one place that decides the mode of Ciri's sections: her spawn's update (the wrapper below), OnPlayerChanged's
// update and every NPC spawned while she plays read it, and the scaling modifiers follow the difficulty ability it
// gives (GMAddOptionBonuses reads the NPC's multiplier); a cap would go back in here.
@replaceMethod(CR4Game)
function GetSpawnDifficultyMode() : EDifficultyMode
{
	//modSigns: removed 5.x's cap while Ciri is the player (return MinDiffMode( GetDifficultyMode(), EDM_Medium ))
	return GetDifficultyMode();
}

// DIFF-06: Ciri's spawn (W3ReplacerCiri.OnSpawned, 5.x's and legacy's) still updates every NPC for
// MinDiffMode(mode, "Story and Sword!"): their difficulty ability and per-enemy variants drop to that mode's until
// OnPlayerChanged updates them for the chosen mode again (a player change; seen in game, slice D3), and a variant
// in an enemy's own entity list (the drunken master's) is lost for good. Every update uses the spawn mode, which
// has no cap: the cap legacy's changelist removed is gone from her spawn too (porter's call, a deviation).
@wrapMethod(CR4Game)
function UpdateStatsForDifficultyLevel(difficulty : EDifficultyMode)
{
	wrappedMethod(GetSpawnDifficultyMode());
}

// DIFF-06 (DIFF audit F1, owner 2026-10-31: a deviation): every NPC near the new player is re-levelled at a player
// change (Geralt to Ciri and back), from its own level: enemies near Ciri when her section starts drop Geralt's
// scaling (her sections are not scaled) and get her Death March adjustment, and Geralt's scaling comes back when he
// returns. Legacy got the first only as a side effect of vanilla's capped update at her spawn on the two higher
// modes (a mode change re-levels), and nothing on the way back; the port's update is uncapped (above), so it
// re-levels here, on every mode, both ways. The mode stays the chosen one (OnPlayerChanged's own update).
@wrapMethod(CR4Game)
function OnPlayerChanged()
{
	wrappedMethod();
	GMOnScalingOptionsChanged();	// legacy's ResetLevel on every NPC near the player (scaling.ws)
}

// DIFF-06: legacy's CheckCiriAbilities, at her spawn and at each combat start: Ciri_Q305 while "Q302 Ciri -
// Rescuing Dudu" or "Q305 Ciri - chase to the temple" is active, Ciri_Q205 while "Q205 Ciri - safe heaven" is;
// each removed otherwise.
@addMethod(W3ReplacerCiri)
function GMCheckCiriAbilities()
{
	var journalManager : CWitcherJournalManager;
	var journalEntry : CJournalBase;
	var q305, q205 : bool;

	journalManager = theGame.GetJournalManager();
	// Ciri Story: Novigrad
	journalEntry = journalManager.GetEntryByString("Q302 Ciri - Rescuing Dudu DC58A7F2-49D51834-AC99B3A6-6106D4CC");
	q305 = journalManager.GetEntryStatus(journalEntry) == JS_Active;
	journalEntry = journalManager.GetEntryByString("Q305 Ciri - chase to the temple 12B8D11E-4BF80285-D48C5CAF-A75A0887");
	q305 = q305 || journalManager.GetEntryStatus(journalEntry) == JS_Active;
	// Ciri Story: Skellige
	journalEntry = journalManager.GetEntryByString("Q205 Ciri - safe heaven");
	q205 = journalManager.GetEntryStatus(journalEntry) == JS_Active;
	GMSetCiriQuestAbilities(q305, q205);
}

// DIFF-06: adds or removes the two quest abilities by the quests' state.
@addMethod(W3ReplacerCiri)
function GMSetCiriQuestAbilities(q305 : bool, q205 : bool)
{
	if(q305 && !HasAbility('Ciri_Q305'))
		AddAbility('Ciri_Q305');
	else if(!q305 && HasAbility('Ciri_Q305'))
		RemoveAbility('Ciri_Q305');
	if(q205 && !HasAbility('Ciri_Q205'))
		AddAbility('Ciri_Q205');
	else if(!q205 && HasAbility('Ciri_Q205'))
		RemoveAbility('Ciri_Q205');
}

@wrapMethod(W3ReplacerCiri)
function OnSpawned(spawnData : SEntitySpawnData)
{
	wrappedMethod(spawnData);
	GMCheckCiriAbilities();
}

@wrapMethod(W3ReplacerCiri)
function OnCombatStart()
{
	wrappedMethod();
	GMCheckCiriAbilities();
}
