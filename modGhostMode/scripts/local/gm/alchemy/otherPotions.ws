// ALCH-07: other potions' special effects (legacy's; the owner's DL4).
// - Blizzard: legacy's (1.32's) potion: 3 s of slow motion after each kill (time x0.5/0.35/0.25), no
//   finishers while it runs (SKL-12, skills/axii.ws); level 3 makes actions free during the slow motion
//   with 3 adrenaline points (alchemy/staminaCostInternal.ws). 5.x's continuous slow motion in combat is gone;
//   5.x's blue tint shows while legacy's slow motion runs (the owner's call, audit F5).
// - Cat: hypnosis immunity at level 3 only (1.32: from level 2); no crit chance (legacy's data).
// - Tawny Owl: regenerates through its ability only (legacy: its own regen effect removed); level 3 never
//   expires at night, legacy's hours (enchantments/prolongation.ws).
// - Maribor Forest no longer cancels Well Hydrated.
// See docs/features/alch.md.

// 1.32's body (legacy's Blizzard); 5.x's body did nothing here. Changes marked //modSigns.
@replaceMethod(W3Potion_Blizzard)
function KilledEnemy()
{
	if(slowdownCauserIds.Size() == 0)	//modSigns: ALCH-07, legacy's slow motion after a kill
	{	//modSigns
		theGame.SetTimeScale( slowdownFactor, theGame.GetTimescaleSource(ETS_PotionBlizzard), theGame.GetTimescalePriority(ETS_PotionBlizzard) );	//modSigns
		slowdownCauserIds.PushBack(target.SetAnimationSpeedMultiplier( 1 / slowdownFactor ));	//modSigns
		if(!isScreenFxActive)	//modSigns: ALCH-07, audit F5: 5.x's blue tint while the slow motion runs (the owner's call)
			EnableScreenFx(true);	//modSigns
	}	//modSigns

	currentSlowMoDuration = 0.f;	//modSigns
}

// 1.32's body (legacy's Blizzard): the slow motion lasts SLOW_MO_DURATION (3 s) after the last kill;
// 5.x's body started it whenever Geralt was in combat with targets. Changes marked //modSigns.
@replaceMethod(W3Potion_Blizzard)
function OnTimeUpdated(dt : float)
{
	//modSigns: removed 5.x's continuous slow motion in combat (ALCH-07, DL4)
	if(slowdownCauserIds.Size() > 0)	//modSigns
	{	//modSigns
		super.OnTimeUpdated(dt / slowdownFactor);	//modSigns

		currentSlowMoDuration += dt / slowdownFactor;	//modSigns
		if(currentSlowMoDuration > SLOW_MO_DURATION)	//modSigns
		{	//modSigns
			RemoveSlowMo();	//modSigns
		}	//modSigns
	}
	else	//modSigns
	{	//modSigns
		super.OnTimeUpdated(dt);	//modSigns
	}
}

// 5.x body; changes marked //modSigns.
@replaceMethod(W3Effect_Hypnotized)
function OnUpdate(deltaTime : float)
{
	var witcher : W3PlayerWitcher = GetWitcherPlayer();


	if(isOnPlayer && GetCreator() && !GetCreator().IsAlive())
		timeLeft = 0;


	if(isOnPlayer && witcher.HasBuff( EET_Cat ) && witcher.GetPotionBuffLevel( EET_Cat ) == 3 )	//modSigns: ALCH-07, Cat level 3 only (5.x: from level 2)
		timeLeft = 0;

	super.OnUpdate(deltaTime);
}

class W3Potion_TawnyOwl extends W3RegenEffect
{
	protected function GetEffectStrength() : float	//modSigns
	{	//modSigns
		return 0;	//modSigns: ALCH-07, audit F1: every dose stacks, as Swallow
	}	//modSigns

	event OnUpdate(deltaTime : float)	//modSigns
	{	//modSigns
		var none : SAbilityAttributeValue;	//modSigns
		effectValue = none;	//modSigns: ALCH-07, its regen comes from its ability alone (legacy)
		super.OnUpdate(deltaTime);	//modSigns
	}	//modSigns
}

class W3Potion_MariborForest extends CBaseGameplayEffect
{
	public function CacheSettings()	//modSigns
	{	//modSigns
		super.CacheSettings();	//modSigns
		override.Remove(EET_WellHydrated);	//modSigns: ALCH-07, no longer cancels Well Hydrated (the effect definition's override)
	}	//modSigns
}
