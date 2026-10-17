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
	groups.PushBack('GMQOLOptions');	options.PushBack('GMLowStaminaSFX');
	groups.PushBack('GMQOLOptions');	options.PushBack('GMLowStaminaSFXVolume');
	groups.PushBack('GMQOLOptions');	options.PushBack('GMLowStaminaSFXDynamicVolume');
	groups.PushBack('GMQOLOptions');	options.PushBack('GMLowStaminaSFXRate');
	groups.PushBack('GMQOLOptions');	options.PushBack('GMLowStaminaSFXDynamicRate');
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
		if(cfg.GetVarValue(groups[i], options[i]) == "")
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
	if(value == "")
		value = GMOptionDefault(group, option);
	return StringToFloat(value);
}

function GMGetOptionBool(group : name, option : name) : bool
{
	var value : string;

	value = theGame.GetInGameConfigWrapper().GetVarValue(group, option);
	if(value == "")
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
// A changed option is noted when its value changes and applied when the menu saves the settings.

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

@wrapMethod(CR4IngameMenu)
function OnOptionValueChanged(groupId : int, optionName : name, optionValue : string)
{
	if(GMIsQoLOption(optionName))
		gmQoLOptionChanged = true;
	return wrappedMethod(groupId, optionName, optionValue);
}

@wrapMethod(CR4IngameMenu)
function SaveChangedSettings()
{
	if(gmQoLOptionChanged)
	{
		gmQoLOptionChanged = false;
		GMOnQoLOptionsChanged();
	}
	wrappedMethod();
}
