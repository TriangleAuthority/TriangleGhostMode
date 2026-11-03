// FIX-04: checkpoints during the Bloody Baron's botchling escort (legacy's FamilyIssuesAutosave; changelist, Known bugs
// 7-10). While "Protect Baron from wraiths" (or "... once more") is active in Family Issues, every quest update saves a
// checkpoint, so dying to the wraiths does not send the player back to before the walk. Legacy's known side effect,
// kept (sweep B Q4): reloading such a checkpoint hides the botchling until the destination ("strictly visual").
// Called after 5.x's OnQuestUpdate body, when the HUD has its journal update module (legacy called it there).
// See docs/features/fix.md.
@wrapMethod(CR4ScriptedHud)
function OnQuestUpdate( journalQuest : CJournalQuest, isQuestUpdate : bool )
{
	wrappedMethod(journalQuest, isQuestUpdate);
	if(GetHudModule("JournalUpdateModule"))
		GMFixFamilyIssuesCheckpoint(journalQuest);
}

// FIX-04: saves a checkpoint for each active escort objective, as legacy (in play one at a time).
function GMFixFamilyIssuesCheckpoint(questEntry : CJournalQuest)
{
	var i, n : int;

	n = GMFixFamilyIssuesCheckpointsDue(questEntry);
	for(i = 0; i < n; i += 1)
		theGame.SaveGame(SGT_CheckPoint, -1);
}

// FIX-04: legacy's rule: the checkpoints due for this quest update, one per active objective tagged "Protect Baron from
// wraiths" or "... once more" in Family Issues; 0 for any other quest.
function GMFixFamilyIssuesCheckpointsDue(questEntry : CJournalQuest) : int
{
	var i, j, n : int;
	var questPhase : CJournalQuestPhase;
	var objective : CJournalQuestObjective;
	var journalManager : CWitcherJournalManager;
	var objectiveTag : string;

	if(!questEntry || NameToString(questEntry.GetUniqueScriptTag()) != "Q103 Family Issues DB024D36-4E9AE35E-FB098D89-C8E7AB0F")
		return 0;
	journalManager = theGame.GetJournalManager();
	for(i = 0; i < questEntry.GetNumChildren(); i += 1)
	{
		questPhase = (CJournalQuestPhase)questEntry.GetChild(i);
		if(questPhase)
		{
			for(j = 0; j < questPhase.GetNumChildren(); j += 1)
			{
				objective = (CJournalQuestObjective)questPhase.GetChild(j);
				if(objective && journalManager.GetEntryStatus(objective) == JS_Active)
				{
					objectiveTag = NameToString(objective.GetUniqueScriptTag());
					if(objectiveTag == "Protect Baron from wraiths" || objectiveTag == "Protect Baron from wraiths once more")
						n += 1;
				}
			}
		}
	}
	return n;
}
