// Test-only automation mod (never shipped): lets tools/game.py drive the game through
// rw3d_cli exec calls and the script log instead of key presses and screenshots.
// See docs/game-automation.md.
//
// Every line it logs starts with "[Automation]" and has the form "<event> key=value ...",
// so the driver can wait for it in scriptslog.txt (needs -debugscripts).
//
// Log markers:
//   main menu                    the main menu is shown
//   game started restored=<b>    the world is set up (restored = loaded from a save)
//   ready                        the loading screen is gone
// Exec functions (all log one result line):
//   autostatus()                 what the game is doing right now
//   autosaves()                  list the 10 newest saves; autosaves(50) for more
//   autoload()                   load the newest save (what Continue does)
//   autoload("<file name>")      load a specific save, e.g. "<save name>" (any case)
//   autoresume()                 close the open menu (pause menu, inventory, intro video, ...), if any
//   autoquit()                   exit the game (what Exit in the menu does, without asking)
//   autoconfig()                 list the options menu groups (what the in-game config system knows)
//   autoconfig("<group id>")     list a group's variables: display name, label, type, value, visibility
//   autoconfigset("<group id>", "<var id>", "<value>")   set a variable and save the user settings

function AutomationLog(msg : string)
{
	LogChannel('Automation', msg);
}

function AutomationBool(b : bool) : string
{
	if (b)
		return "true";
	return "false";
}

@wrapMethod(CR4CommonMainMenuBase)
function OnConfigUI()
{
	wrappedMethod();
	AutomationLog("main menu");
}

@wrapMethod(CR4Game)
function OnGameStarted(restored : bool)
{
	wrappedMethod(restored);
	AutomationLog("game started restored=" + AutomationBool(restored));
}

@wrapMethod(CR4Game)
function OnAfterLoadingScreenGameStart()
{
	wrappedMethod();
	AutomationLog("ready");
}

exec function autostatus()
{
	var menu : CR4Menu;
	var menuName : string;
	var inGame : bool;

	menuName = "none";
	menu = theGame.GetGuiManager().GetRootMenu();
	if (menu)
		menuName = NameToString(menu.GetMenuName());

	inGame = thePlayer && theGame.IsActive();
	AutomationLog("status ingame=" + AutomationBool(inGame)
		+ " paused=" + AutomationBool(theGame.IsPaused())
		+ " menu=" + menuName
		+ " loadingvideo=" + AutomationBool(theGame.IsLoadingScreenVideoPlaying())
		+ " scene=" + AutomationBool(theGame.IsDialogOrCutscenePlaying()));
}

exec function autosaves(optional count : int)
{
	var saves : array< SSavegameInfo >;
	var i : int;

	if (count <= 0)
		count = 10;
	theGame.ListSavedGames(saves);
	for (i = 0; i < saves.Size() && i < count; i += 1)
	{
		AutomationLog("save index=" + IntToString(i) + " file=" + saves[i].filename + " type=" + IntToString((int)saves[i].slotType));
	}
	AutomationLog("saves count=" + IntToString(saves.Size()));
}

exec function autoload(optional file : string)
{
	var saves : array< SSavegameInfo >;
	var i : int;

	if (file == "")
	{
		AutomationLog("loading save=latest");
		theGame.LoadLastGameInit();
		return;
	}

	theGame.ListSavedGames(saves);
	for (i = 0; i < saves.Size(); i += 1)
	{
		if (StrLower(saves[i].filename) == StrLower(file))
		{
			AutomationLog("loading save=" + file);
			theGame.LoadGameInit(saves[i], false);
			return;
		}
	}
	AutomationLog("error save not found: " + file);
}

exec function autoresume()
{
	var menu : CR4Menu;

	menu = theGame.GetGuiManager().GetRootMenu();
	if (!menu)
	{
		AutomationLog("resume menu=none paused=" + AutomationBool(theGame.IsPaused()));
		return;
	}
	AutomationLog("resume closing=" + NameToString(menu.GetMenuName()));
	menu.CloseMenu();
}

exec function autoquit()
{
	AutomationLog("quitting");
	theGame.RequestExit();
}

exec function autoconfig(optional group : string)
{
	var cfg : CInGameConfigWrapper;
	var idx, i, count : int;
	var groupName, varName : name;
	var display : string;

	cfg = theGame.GetInGameConfigWrapper();
	if (group == "")
	{
		count = cfg.GetGroupsNum();
		for (i = 0; i < count; i += 1)
		{
			groupName = cfg.GetGroupName(i);
			AutomationLog("config group=" + NameToString(groupName)
				+ " display=" + cfg.GetGroupDisplayName(groupName)
				+ " visible=" + AutomationBool(cfg.IsGroupVisible(groupName)));
		}
		AutomationLog("config groups=" + IntToString(count));
		return;
	}

	idx = cfg.GetGroupIdx(group);
	if (idx < 0)
	{
		AutomationLog("error config group not found: " + group);
		return;
	}
	groupName = cfg.GetGroupName(idx);
	count = cfg.GetVarsNum(idx);
	AutomationLog("config group=" + group + " display=" + cfg.GetGroupDisplayName(groupName)
		+ " visible=" + AutomationBool(cfg.IsGroupVisible(groupName)) + " vars=" + IntToString(count));
	for (i = 0; i < count; i += 1)
	{
		varName = cfg.GetVarName(idx, i);
		display = cfg.GetVarDisplayName(groupName, varName);
		AutomationLog("config var=" + NameToString(varName)
			+ " display=" + display
			+ " label=" + GetLocStringByKeyExt("option_" + display)
			+ " type=" + cfg.GetVarDisplayType(groupName, varName)
			+ " value=" + cfg.GetVarValue(groupName, varName)
			+ " visible=" + AutomationBool(cfg.IsVarVisible(groupName, varName)));
	}
}

exec function autoconfigset(group : string, variable : string, value : string)
{
	var cfg : CInGameConfigWrapper;
	var idx, i, count : int;
	var groupName, varName : name;

	cfg = theGame.GetInGameConfigWrapper();
	idx = cfg.GetGroupIdx(group);
	if (idx < 0)
	{
		AutomationLog("error config group not found: " + group);
		return;
	}
	groupName = cfg.GetGroupName(idx);
	count = cfg.GetVarsNum(idx);
	for (i = 0; i < count; i += 1)
	{
		varName = cfg.GetVarName(idx, i);
		if (NameToString(varName) == variable)
		{
			cfg.SetVarValue(groupName, varName, value);
			theGame.SaveUserSettings();
			AutomationLog("config set group=" + group + " var=" + variable + " value=" + cfg.GetVarValue(groupName, varName));
			return;
		}
	}
	AutomationLog("error config var not found: " + group + "." + variable);
}
