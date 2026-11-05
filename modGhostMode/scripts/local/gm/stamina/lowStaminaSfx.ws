// STAM-07: low-stamina heartbeat. Below a stamina threshold (option, % of max) Geralt hears a
// heartbeat loop: Ghost Mode's bank heartbeat02a.bnk (modGhostMode/sound/, shipped in the mod's
// soundspc.cache). Its volume and rate are options; with the dynamic options both rise as stamina
// falls, (1 - stamina / threshold) x 100. The bank mutes it outside combat (game_state states).
// Checked after every stamina drain and regen tick (the wrappers in npcStamina.ws) and stopped when
// the player dies. Only Geralt: legacy's CR4Player versions were empty, so Ciri hears nothing.
// Deviation from legacy: legacy saved the playing flag in the save; here it lasts for the session
// only (no save impact). A loaded game starts with it off, and the next check starts the sound.

@addField(CR4Player)
var gmLowStaminaSFXPlaying : bool;

@addMethod(CR4Player)
function GMCheckForLowStamina()
{
	var threshold, staminaPrc, level : float;

	if(!((W3PlayerWitcher)this))
		return;

	threshold = 0.01 * GMGetOptionFloat('GMQOLOptions', 'GMLowStaminaSFX');
	staminaPrc = GetStat(BCS_Stamina) / ((W3PlayerWitcher)this).GMFullMaxStamina();	// STAM-10: of the full max while max stamina is lowered

	if(staminaPrc < threshold && !gmLowStaminaSFXPlaying)
	{
		gmLowStaminaSFXPlaying = true;
		if(!theSound.SoundIsBankLoaded("heartbeat02a.bnk"))
			theSound.SoundLoadBank("heartbeat02a.bnk", false);
		theSound.SoundEvent("play_heartbeat_02a_loop");
		theSound.SoundParameter("heartbeat_rate", GMGetOptionFloat('GMQOLOptions', 'GMLowStaminaSFXRate'));
		theSound.SoundParameter("heartbeat_volume", GMGetOptionFloat('GMQOLOptions', 'GMLowStaminaSFXVolume'));
	}
	else if(staminaPrc >= threshold && gmLowStaminaSFXPlaying)
	{
		GMStopLowStaminaSFX();
	}

	if(gmLowStaminaSFXPlaying)
	{
		level = (1.0f - staminaPrc / threshold) * 100.0f;
		if(GMGetOptionBool('GMQOLOptions', 'GMLowStaminaSFXDynamicRate'))
			theSound.SoundParameter("heartbeat_rate", level);
		if(GMGetOptionBool('GMQOLOptions', 'GMLowStaminaSFXDynamicVolume'))
			theSound.SoundParameter("heartbeat_volume", level);
	}
}

@addMethod(CR4Player)
function GMStopLowStaminaSFX()
{
	gmLowStaminaSFXPlaying = false;
	theSound.SoundEvent("stop_heartbeat_02a_loop");
}

@wrapMethod(CR4Player)
function OnDeath(damageAction : W3DamageAction)
{
	wrappedMethod(damageAction);
	GMStopLowStaminaSFX();
}
