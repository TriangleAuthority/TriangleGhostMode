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
// Probes (vanilla debug exec functions such as logskills() or printinv() log nothing in the
// release build, so these report Geralt's and the world's state instead):
//   autoplayer()                 level, experience, points, stats, money, difficulty, position, time, state
//   autoskills()                 learned skills with level, max level and slot; skill slots
//   autoinv()                    equipped items; autoinv(true) for all items
//   autobuffs()                  active effects with time left
//   autoattr("<attribute>")      an attribute of Geralt, e.g. "staminaRegen" (base, mult, add)
//   autoactors()                 actors within 30 m (autoactors(60) for another range): name, attitude, level, health
// Input simulation (calls the input handler's events as if the key changed state):
//   autocast(ST_Aard)            select a sign and press the cast-sign input (CPlayerInput.OnCastSign)
//   autocast(ST_Aard, true)      the same, held: the cast becomes the alternate cast if its skill is
//                                equipped (the game reads the real key for that, so the decision in
//                                W3SignOwnerPlayer.ChangeAspect and the channel's ShouldStopChanneling
//                                are forced until the release)
//   autocastrelease()            release the cast-sign input (ends a held cast)

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

function AutomationStat(stat : EBaseCharacterStats, label : string) : string
{
	return " " + label + "=" + NoTrailZeros(thePlayer.GetStat(stat)) + "/" + NoTrailZeros(thePlayer.GetStatMax(stat));
}

exec function autoplayer()
{
	var witcher : W3PlayerWitcher;
	var pos : Vector;

	witcher = GetWitcherPlayer();
	pos = thePlayer.GetWorldPosition();
	AutomationLog("player level=" + IntToString(witcher.GetLevel())
		+ " exp=" + IntToString(witcher.GetPointsTotal(EExperiencePoint))
		+ " expNextLevel=" + IntToString(witcher.GetTotalExpForNextLevel())
		+ " skillPointsFree=" + IntToString(witcher.levelManager.GetPointsFree(ESkillPoint))
		+ " skillPointsTotal=" + IntToString(witcher.levelManager.GetPointsTotal(ESkillPoint))
		+ " money=" + IntToString(thePlayer.inv.GetMoney())
		+ " difficulty=" + theGame.GetDifficultyMode());
	AutomationLog("player stats"
		+ AutomationStat(BCS_Vitality, "vitality")
		+ AutomationStat(BCS_Stamina, "stamina")
		+ AutomationStat(BCS_Toxicity, "toxicity")
		+ AutomationStat(BCS_Focus, "adrenaline"));
	AutomationLog("player pos=" + NoTrailZeros(pos.X) + "," + NoTrailZeros(pos.Y) + "," + NoTrailZeros(pos.Z)
		+ " time=" + GameTimeToString(theGame.GetGameTime())
		+ " state=" + NameToString(thePlayer.GetCurrentStateName())
		+ " combat=" + AutomationBool(thePlayer.IsInCombat())
		+ " immortality=" + thePlayer.GetImmortalityMode());
}

exec function autoskills()
{
	var witcher : W3PlayerWitcher;
	var skills : array<SSkill>;
	var i, count, unlocked : int;

	witcher = GetWitcherPlayer();
	skills = witcher.GetPlayerSkills();
	for (i = 0; i < skills.Size(); i += 1)
	{
		if (skills[i].level > 0)
		{
			AutomationLog("skill " + SkillEnumToName(skills[i].skillType)
				+ " enum=" + skills[i].skillType
				+ " level=" + IntToString(skills[i].level) + "/" + IntToString(skills[i].maxLevel)
				+ " slot=" + IntToString(witcher.GetSkillSlotID(skills[i].skillType))
				+ " canUse=" + AutomationBool(witcher.CanUseSkill(skills[i].skillType)));
			count += 1;
		}
	}
	for (i = 0; i < witcher.GetSkillSlotsCount(); i += 1)
	{
		if (((W3PlayerAbilityManager)witcher.abilityManager).IsSkillSlotUnlocked(i))
			unlocked += 1;
	}
	AutomationLog("skills learned=" + IntToString(count) + " slots=" + IntToString(witcher.GetSkillSlotsCount())
		+ " slotsUnlocked=" + IntToString(unlocked));
}

exec function autoinv(optional all : bool)
{
	var items : array<SItemUniqueId>;
	var i, shown : int;
	var equipped : bool;

	thePlayer.inv.GetAllItems(items);
	for (i = 0; i < items.Size(); i += 1)
	{
		equipped = GetWitcherPlayer().IsItemEquipped(items[i]);
		if (all || equipped)
		{
			AutomationLog("item " + NameToString(thePlayer.inv.GetItemName(items[i]))
				+ " category=" + NameToString(thePlayer.inv.GetItemCategory(items[i]))
				+ " quantity=" + IntToString(thePlayer.inv.GetItemQuantity(items[i]))
				+ " equipped=" + AutomationBool(equipped));
			shown += 1;
		}
	}
	AutomationLog("inventory items=" + IntToString(items.Size()) + " shown=" + IntToString(shown));
}

exec function autobuffs()
{
	var buffs : array<CBaseGameplayEffect>;
	var i : int;

	buffs = thePlayer.GetBuffs();
	for (i = 0; i < buffs.Size(); i += 1)
	{
		AutomationLog("buff " + EffectTypeToName(buffs[i].GetEffectType())
			+ " timeLeft=" + NoTrailZeros(buffs[i].GetDurationLeft()));
	}
	AutomationLog("buffs count=" + IntToString(buffs.Size()));
}

exec function autoattr(attr : name)
{
	var v : SAbilityAttributeValue;

	v = thePlayer.GetAttributeValue(attr);
	AutomationLog("attr " + NameToString(attr) + " base=" + NoTrailZeros(v.valueBase)
		+ " mult=" + NoTrailZeros(v.valueMultiplicative) + " add=" + NoTrailZeros(v.valueAdditive));
}

exec function autoactors(optional range : float)
{
	var actors : array<CActor>;
	var npc : CNewNPC;
	var i : int;
	var level : string;

	if (range <= 0)
		range = 30;
	actors = GetActorsInRange(thePlayer, range);
	for (i = 0; i < actors.Size(); i += 1)
	{
		if (actors[i] == thePlayer)
			continue;
		npc = (CNewNPC)actors[i];
		level = "-";
		if (npc)
			level = IntToString(npc.GetLevel());
		AutomationLog("actor " + actors[i].GetReadableName()
			+ " name=" + actors[i].GetDisplayName()
			+ " attitude=" + actors[i].GetAttitude(thePlayer)
			+ " level=" + level
			+ " health=" + NoTrailZeros(actors[i].GetHealthPercents())
			+ " alive=" + AutomationBool(actors[i].IsAlive())
			+ " distance=" + NoTrailZeros(VecDistance(actors[i].GetWorldPosition(), thePlayer.GetWorldPosition())));
	}
	AutomationLog("actors count=" + IntToString(actors.Size()));
}

// A fake input action: pressed = value 1 after 0, released = value 0 after 1.
function AutomationInputAction(actionName : name, pressed : bool) : SInputAction
{
	var action : SInputAction;

	action.aName = actionName;
	if (pressed)
	{
		action.value = 1;
		action.lastFrameValue = 0;
	}
	else
	{
		action.value = 0;
		action.lastFrameValue = 1;
	}
	return action;
}

function AutomationSignState(label : string)
{
	AutomationLog(label + " equipped=" + GetWitcherPlayer().GetEquippedSign()
		+ " casting=" + AutomationBool(thePlayer.IsCastingSign())
		+ " stamina=" + NoTrailZeros(thePlayer.GetStat(BCS_Stamina))
		+ " state=" + NameToString(thePlayer.GetCurrentStateName()));
}

@addField(CR4Player)
var automationHoldCast : bool;

@addMethod(CR4Player)
function AutomationSetHoldCast(hold : bool)
{
	automationHoldCast = hold;
}

// Alternate casting is decided from the real key state; while autocast(..., true) holds the
// input, decide as the game does for a held key.
@wrapMethod(W3SignOwnerPlayer)
function ChangeAspect(signEntity : W3SignEntity, newSkill : ESkill) : bool
{
	if (thePlayer.automationHoldCast && player.CanUseSkill(newSkill))
	{
		signEntity.SetAlternateCast(newSkill);
		player.SetBehaviorVariable('alternateSignCast', 1);
		AutomationLog("cast alternate forced skill=" + newSkill);
		return true;
	}
	return wrappedMethod(signEntity, newSkill);
}

// Channeled casts (Igni, Quen, Axii alternates) continue while the key is held.
@wrapMethod(W3SignEntityStateChanneling)
function ShouldStopChanneling() : bool
{
	if (thePlayer.automationHoldCast)
		return false;
	return wrappedMethod();
}

exec function autocast(optional sign : ESignType, optional hold : bool)
{
	thePlayer.AutomationSetHoldCast(hold);
	if (sign != ST_None)
		GetWitcherPlayer().SetEquippedSign(sign);
	AutomationSignState("cast before");
	thePlayer.GetInputHandler().OnCastSign(AutomationInputAction('CastSign', true));
	AutomationSignState("cast pressed");
}

exec function autocastrelease()
{
	thePlayer.AutomationSetHoldCast(false);
	thePlayer.GetInputHandler().OnCastSign(AutomationInputAction('CastSign', false));
	AutomationSignState("cast released");
}

// Hard-locks onto the nearest living hostile within range (default 15 m), as the lock-on button
// does (CR4Player.HardLockToTarget on the current target). autolock(false) releases the lock.
exec function autolock(optional unlock : bool, optional range : float)
{
	var actors : array<CActor>;
	var target : CActor;
	var i : int;
	var dist, best : float;

	if (unlock)
	{
		thePlayer.HardLockToTarget(false);
		AutomationLog("lock released");
		return;
	}
	if (range <= 0)
		range = 15;
	actors = thePlayer.GetNPCsAndPlayersInRange(range, 50, , FLAG_OnlyAliveActors);
	best = range + 1;
	for (i = 0; i < actors.Size(); i += 1)
	{
		if (actors[i] == thePlayer || GetAttitudeBetween(thePlayer, actors[i]) != AIA_Hostile)
			continue;
		dist = VecDistance(actors[i].GetWorldPosition(), thePlayer.GetWorldPosition());
		if (dist < best)
		{
			best = dist;
			target = actors[i];
		}
	}
	if (!target)
	{
		AutomationLog("error lock: no hostile within " + NoTrailZeros(range) + " m");
		return;
	}
	thePlayer.ProcessLockTarget(target);
	thePlayer.HardLockToTarget(true);
	AutomationLog("locked target=" + target.GetDisplayName() + " distance=" + NoTrailZeros(best)
		+ " hardlock=" + AutomationBool(thePlayer.IsHardLockEnabled()) + " playerTarget=" + AutomationBool(thePlayer.GetTarget() == target));
}
