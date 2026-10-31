// UI-12: an enemy far above Geralt shows its level in red on the HUD (and in the threat list) instead of
// 5.x's "???" with a skull (legacy, changelist 1113; DU8). DIFF-05: every enemy shows its real level,
// without the entity's fake addon, the NG+ fake addon or the cap at 5 above the maximum level, as
// legacy. 5.x body; changes marked //modSigns. See docs/features/ui.md and docs/features/diff.md.
@replaceMethod(CNewNPC)
function GetExperienceDifferenceLevelName( out strLevel : string ) : string
{
	var lvlDiff : int;
	var currentLevel : int;
	var ciriEntity  : W3ReplacerCiri;
	
	currentLevel = GetLevel();	//modSigns: DIFF-05, fake levels removed (legacy)
	
	//modSigns: DIFF-05, removed the NG+ fake level addon (legacy)
	
	//modSigns: DIFF-05, removed the cap at the maximum level + 5 (legacy)
	lvlDiff = currentLevel - thePlayer.GetLevel();
		
	if( GetAttitude( thePlayer ) != AIA_Hostile )
	{
		if( ( GetAttitudeGroup() != 'npc_charmed' ) )
		{
			strLevel = "";
			return "none";
		}
	}
	
	ciriEntity = (W3ReplacerCiri)thePlayer;
	if ( ciriEntity )
	{
		strLevel = "<font color=\"#66FF66\">" + currentLevel + "</font>"; 
		return "normalLevel";
	}

	
	//modSigns: removed the deadly level ("???" with a skull): such enemies show their level in red (UI-12, legacy)
	if ( lvlDiff >= theGame.params.LEVEL_DIFF_HIGH )	//modSigns: no longer an else branch
	{
		strLevel = "<font color=\"#FF1919\">" + currentLevel + "</font>"; 
		return "highLevel";
	}
	else if ( lvlDiff > -theGame.params.LEVEL_DIFF_HIGH )
	{
		strLevel = "<font color=\"#66FF66\">" + currentLevel + "</font>"; 
		return "normalLevel";
	}
	else
	{
		strLevel = "<font color=\"#E6E6E6\">" + currentLevel + "</font>"; 
		return "lowLevel";
	}
	return "none";
}
