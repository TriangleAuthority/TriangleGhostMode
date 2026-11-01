// OPT-01: Ghost Mode options framework. The menu is modGhostMode/menu/modGhostMode.xml
// (Options > Mods > Ghost Mode); values live in Documents\The Witcher 3\dx12user.settings.
// An option that was never set reads as "", so every option has a default here, applied
// when a save loads, and the getters fall back to it while the option is empty.
// See docs/features/opt.md.

// Default value of a Ghost Mode option ("" if unknown). Add new options here and to the menu.
function GMOptionDefault(group : name, option : name) : string
{
	if(group == 'GMGameplayOptions')
	{
		switch(option)
		{
			// SKL-02: the classic tree is the default (D46)
			case 'GMClassicSkillTree' :		return "true";
			// STAM-05
			case 'GMArmorRegenPenalty' :		return "false";
			// STAM-04
			case 'GMCombatStaminaRegen' :		return "0";
			case 'GMOutOfCombatStaminaRegen' :	return "0";
			// STAM-06
			case 'GMStaminaDelay' :		return "0";
			// STAM-03
			case 'GMAgilityStaminaCostMultiplier' :	return "0";
			case 'GMMeleeStaminaCostMultiplier' :	return "0";
			case 'GMSignStaminaCostMultiplier' :	return "0";
			// STAM-02
			case 'GMMeleeSpecialCooldown' :	return "7.5";
			// STAM-01
			case 'GMSignCooldown' :		return "5";
			case 'GMAltSignCooldown' :	return "7.5";
		}
	}
	else if(group == 'GMScalingOptions')
	{
		switch(option)
		{
			// DIFF-04: the "Recommended" preset's values (DD1): soft upscaling, the rest off
			case 'Virtual_GMScaling' :		return "3";
			case 'GMRandomScalingMinLevel' :	return "0";
			case 'GMRandomScalingMaxLevel' :	return "0";
			case 'GMNoAddLevelsGuards' :		return "false";
			case 'GMNoAnimalUpscaling' :		return "false";
			case 'GMNonlinearLevelup' :		return "false";
			case 'GMNonlinearLevelDelta' :		return "0";
			case 'GMNonlinearAbilitiesDelta' :	return "0";
			case 'GMHealthMultiplier' :		return "0";
			case 'GMDamageMultiplier' :		return "0";
			case 'GMBossHealthMultiplier' :		return "0";
			case 'GMBossDamageMultiplier' :		return "0";
			// DIFF-09: "Ciri's sections: difficulty", "Same as game" (legacy's: no cap)
			case 'Virtual_GMCiriDifficulty' :	return "0";
		}
	}
	else if(group == 'GMExpOptions')
	{
		switch(option)
		{
			// XP-07: legacy's "Default" preset, everything off and 0 (PX9)
			case 'GMNoQuestLevels' :		return "false";
			case 'GMUseXMLExp' :			return "false";
			case 'GMQuestExpModifier' :		return "0";
			case 'GMMonsterExpModifier' :	return "0";
		}
	}
	else if(group == 'GMQOLOptions')
	{
		switch(option)
		{
			// STAM-07 (legacy's recommended preset)
			case 'GMLowStaminaSFX' :			return "50";
			case 'GMLowStaminaSFXVolume' :		return "100";
			case 'GMLowStaminaSFXDynamicVolume' :	return "true";
			case 'GMLowStaminaSFXRate' :		return "0";
			case 'GMLowStaminaSFXDynamicRate' :	return "true";
		}
	}
	return "";
}

// Every option with a default, for GMApplyDefaultOptions.
function GMOptionList(out groups : array<name>, out options : array<name>)
{
	groups.Clear();
	options.Clear();
	groups.PushBack('GMGameplayOptions');	options.PushBack('GMClassicSkillTree');
	groups.PushBack('GMGameplayOptions');	options.PushBack('GMArmorRegenPenalty');
	groups.PushBack('GMGameplayOptions');	options.PushBack('GMCombatStaminaRegen');
	groups.PushBack('GMGameplayOptions');	options.PushBack('GMOutOfCombatStaminaRegen');
	groups.PushBack('GMGameplayOptions');	options.PushBack('GMAgilityStaminaCostMultiplier');
	groups.PushBack('GMGameplayOptions');	options.PushBack('GMMeleeStaminaCostMultiplier');
	groups.PushBack('GMGameplayOptions');	options.PushBack('GMSignStaminaCostMultiplier');
	groups.PushBack('GMGameplayOptions');	options.PushBack('GMStaminaDelay');
	groups.PushBack('GMGameplayOptions');	options.PushBack('GMMeleeSpecialCooldown');
	groups.PushBack('GMGameplayOptions');	options.PushBack('GMSignCooldown');
	groups.PushBack('GMGameplayOptions');	options.PushBack('GMAltSignCooldown');
	groups.PushBack('GMScalingOptions');	options.PushBack('Virtual_GMScaling');
	groups.PushBack('GMScalingOptions');	options.PushBack('GMRandomScalingMinLevel');
	groups.PushBack('GMScalingOptions');	options.PushBack('GMRandomScalingMaxLevel');
	groups.PushBack('GMScalingOptions');	options.PushBack('GMNoAddLevelsGuards');
	groups.PushBack('GMScalingOptions');	options.PushBack('GMNoAnimalUpscaling');
	groups.PushBack('GMScalingOptions');	options.PushBack('GMNonlinearLevelup');
	groups.PushBack('GMScalingOptions');	options.PushBack('GMNonlinearLevelDelta');
	groups.PushBack('GMScalingOptions');	options.PushBack('GMNonlinearAbilitiesDelta');
	groups.PushBack('GMScalingOptions');	options.PushBack('GMHealthMultiplier');
	groups.PushBack('GMScalingOptions');	options.PushBack('GMDamageMultiplier');
	groups.PushBack('GMScalingOptions');	options.PushBack('GMBossHealthMultiplier');
	groups.PushBack('GMScalingOptions');	options.PushBack('GMBossDamageMultiplier');
	groups.PushBack('GMScalingOptions');	options.PushBack('Virtual_GMCiriDifficulty');
	groups.PushBack('GMExpOptions');	options.PushBack('GMNoQuestLevels');
	groups.PushBack('GMExpOptions');	options.PushBack('GMUseXMLExp');
	groups.PushBack('GMExpOptions');	options.PushBack('GMQuestExpModifier');
	groups.PushBack('GMExpOptions');	options.PushBack('GMMonsterExpModifier');
	groups.PushBack('GMQOLOptions');	options.PushBack('GMLowStaminaSFX');
	groups.PushBack('GMQOLOptions');	options.PushBack('GMLowStaminaSFXVolume');
	groups.PushBack('GMQOLOptions');	options.PushBack('GMLowStaminaSFXDynamicVolume');
	groups.PushBack('GMQOLOptions');	options.PushBack('GMLowStaminaSFXRate');
	groups.PushBack('GMQOLOptions');	options.PushBack('GMLowStaminaSFXDynamicRate');
}

// An option that was never set reads "", a virtual OPTIONS variable (Virtual_..., whose value is the option
// matching its entries' variables) "-1" (DIFF-04, seen in game).
function GMOptionUnset(option : name, value : string) : bool
{
	return value == "" || (value == "-1" && StrBeginsWith(NameToString(option), "Virtual_"));
}

// Give every unset option its default, keeping values the player has set.
function GMApplyDefaultOptions()
{
	var cfg : CInGameConfigWrapper;
	var groups, options : array<name>;
	var i : int;
	var changed : bool;

	cfg = theGame.GetInGameConfigWrapper();
	GMOptionList(groups, options);
	for(i = 0; i < options.Size(); i += 1)
	{
		if(GMOptionUnset(options[i], cfg.GetVarValue(groups[i], options[i])))
		{
			cfg.SetVarValue(groups[i], options[i], GMOptionDefault(groups[i], options[i]));
			changed = true;
		}
	}
	if(changed)
		theGame.SaveUserSettings();
}

function GMGetOptionFloat(group : name, option : name) : float
{
	var value : string;

	value = theGame.GetInGameConfigWrapper().GetVarValue(group, option);
	if(GMOptionUnset(option, value))
		value = GMOptionDefault(group, option);
	return StringToFloat(value);
}

function GMGetOptionBool(group : name, option : name) : bool
{
	var value : string;

	value = theGame.GetInGameConfigWrapper().GetVarValue(group, option);
	if(GMOptionUnset(option, value))
		value = GMOptionDefault(group, option);
	return value == "true";
}

@wrapMethod(CR4Player)
function OnSpawned(spawnData : SEntitySpawnData)
{
	wrappedMethod(spawnData);
	GMApplyDefaultOptions();
}

// ---- reacting to changes in the options menu (legacy: CR4IngameMenu.gmUserSettings) ----
// A changed option is noted when its value changes and applied when the menu saves the settings:
// quality-of-life options restart the low-stamina sound, scaling options (DIFF-04, GMIsScalingOption in
// difficulty/scaling.ws) re-level the NPCs near Geralt, "Disable quest levels" (XP-07) clears or reloads the quest levels.

// The quality-of-life group's options (legacy gmIsQoLOption; GMSignInstantCast is not ported yet).
function GMIsQoLOption(option : name) : bool
{
	switch(option)
	{
		case 'GMLowStaminaSFX' :
		case 'GMLowStaminaSFXVolume' :
		case 'GMLowStaminaSFXDynamicVolume' :
		case 'GMLowStaminaSFXRate' :
		case 'GMLowStaminaSFXDynamicRate' :
			return true;
	}
	return false;
}

// Apply changed quality-of-life options (legacy CR4Game.gmUserSettingsQoL).
function GMOnQoLOptionsChanged()
{
	if(thePlayer)
	{
		// STAM-07: restart the heartbeat with the new threshold, volume and rate
		thePlayer.GMStopLowStaminaSFX();
		thePlayer.GMCheckForLowStamina();
	}
}

@addField(CR4IngameMenu)
var gmQoLOptionChanged : bool;

@addField(CR4IngameMenu)
var gmScalingOptionChanged : bool;

@addField(CR4IngameMenu)
var gmCiriDifficultyChanged : bool;

// XP-07: "Disable quest levels" (legacy's gmHasChangedQuestLevelsOption).
@addField(CR4IngameMenu)
var gmQuestLevelsOptionChanged : bool;

// XP-07: the quest levels cleared or reloaded for the new value of "Disable quest levels" (xp/expOptions.ws).
function GMOnQuestLevelsOptionChanged()
{
	theGame.GMReloadQuestLevels();
}

// DIFF-09: "Ciri's sections: difficulty" (its virtual option and the variable its entries set).
function GMIsCiriDifficultyOption(option : name) : bool
{
	return option == 'Virtual_GMCiriDifficulty' || option == 'GMCiriDifficulty';
}

@wrapMethod(CR4IngameMenu)
function OnOptionValueChanged(groupId : int, optionName : name, optionValue : string)
{
	if(GMIsQoLOption(optionName))
		gmQoLOptionChanged = true;
	if(GMIsScalingOption(optionName))
		gmScalingOptionChanged = true;
	if(GMIsCiriDifficultyOption(optionName))
		gmCiriDifficultyChanged = true;
	if(optionName == 'GMNoQuestLevels')
		gmQuestLevelsOptionChanged = true;
	return wrappedMethod(groupId, optionName, optionValue);
}

// A preset of the scaling group (DIFF-04: "Recommended", "Hardcore", "Off") sets several scaling options at
// once: it re-levels like an option change (legacy's OnPresetApplied). The experience group's "Default" (XP-07) sets
// "Disable quest levels": the quest levels are reloaded like an option change.
@wrapMethod(CR4IngameMenu)
function OnPresetApplied(groupId : name, targetPresetIndex : int)
{
	if(groupId == 'GMScalingOptions')
		gmScalingOptionChanged = true;
	if(groupId == 'GMExpOptions')
		gmQuestLevelsOptionChanged = true;
	return wrappedMethod(groupId, targetPresetIndex);
}

@wrapMethod(CR4IngameMenu)
function SaveChangedSettings()
{
	if(gmQoLOptionChanged)
	{
		gmQoLOptionChanged = false;
		GMOnQoLOptionsChanged();
	}
	if(gmCiriDifficultyChanged)
	{
		// DIFF-09: while Ciri plays, her sections' new mode at once and a re-level (difficulty/ciri.ws)
		gmCiriDifficultyChanged = false;
		GMOnCiriDifficultyChanged();
	}
	if(gmScalingOptionChanged)
	{
		gmScalingOptionChanged = false;
		GMOnScalingOptionsChanged();
	}
	if(gmQuestLevelsOptionChanged)
	{
		gmQuestLevelsOptionChanged = false;
		GMOnQuestLevelsOptionChanged();
	}
	wrappedMethod();
}
