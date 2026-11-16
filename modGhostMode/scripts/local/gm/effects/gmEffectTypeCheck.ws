// The effect-type check (2026-11-15). Ghost Mode adds 18 members to the game's EEffectType (gmEffectTypes.ws). The
// game merges every mod's members by name at load and numbers them in load order, so another compiled mod that also
// adds effect types can shift Ghost Mode's numbers, and Ghost Mode's code then points at the wrong effects
// (docs/development.md, the enum bullets). A class default is resolved by name against the merged list, while a
// number in the code keeps its compiled value: when the two differ for Ghost Mode's first and last effect types, the
// mods clash. The fix is tools/enum_sync.py (README, "Using it with other mods"). Checked a few seconds after a save
// loads; a clash is shown as a notification and written to the script log.

@addField(W3PlayerWitcher)
var gmEffectTypeClash : string;	// "" when the numbers agree (read by the tests)

@addMethod(W3PlayerWitcher)
function GMCheckEffectTypes() : bool
{
	var first : W3GMEffect_AardCooldown;
	var last : W3GMEffect_Dimeritium;

	first = new W3GMEffect_AardCooldown in this;
	last = new W3GMEffect_Dimeritium in this;
	gmEffectTypeClash = "";
	if((int)first.GetEffectType() != (int)EET_GMAardCooldown || (int)last.GetEffectType() != (int)EET_GMDimeritium)
		gmEffectTypeClash = "EET_GMAardCooldown compiled " + (int)EET_GMAardCooldown + ", in game " + (int)first.GetEffectType()
			+ "; EET_GMDimeritium compiled " + (int)EET_GMDimeritium + ", in game " + (int)last.GetEffectType();
	delete first;
	delete last;
	return gmEffectTypeClash == "";
}

@wrapMethod(W3PlayerWitcher)
function OnSpawned(spawnData : SEntitySpawnData)
{
	wrappedMethod(spawnData);
	AddTimer('GMEffectTypeCheckTimer', 5.0, false);
}

@addMethod(W3PlayerWitcher)
timer function GMEffectTypeCheckTimer(dt : float, id : int)
{
	if(GMCheckEffectTypes())
	{
		LogChannel('GhostMode', "effect types: numbers agree with the game's");
		return;
	}
	LogChannel('GhostMode', "effect types CLASH with another mod: " + gmEffectTypeClash);
	theGame.GetGuiManager().ShowNotification("Ghost Mode: another installed mod also adds effect types, and their numbers clash, so some of"
		+ " Ghost Mode's effects will not work. Run enum_sync.py after installing mods (see Ghost Mode's README).", 15.0);
}
