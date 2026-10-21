// ALCH-04: Swallow, White Raffard's Decoction, White Honey (legacy's fixes).
// - Swallow stops bleeding on every dose; its regen is its ability's alone (5.x's W3Potion_VitalityRegen also
//   ran a regen effect of its own, counting the regen twice); its strength is 0, legacy's, so doses stack.
// - White Raffard's Decoction heals the stated share of maximum Vitality without raising it first, on every
//   dose, stops bleeding, and no longer cancels Swallow.
// - White Honey clears toxicity and potions on every dose (with 5.x's locked-toxicity reset, the owner's DL6).
// ALCH-05: Golden Oriole cures poison on every dose; level 3 adds 5 s of poison immunity; 5.x's level-3
// healing from poison is removed (damage/pipeline.ws; the Viper set heals instead, the owner's DL5).
// DL10: Reinald's Philtre (5.x's quest potion) regenerates through its ability only, as Swallow.
// See docs/features/alch.md.

// --- Swallow ---------------------------------------------------------------------------------------------

// 5.x body; changes marked //modSigns. The regen comes from the effect's ability on Geralt (his own regen
// reads it); the effect's own regen is zeroed, its timer still runs.
@replaceMethod(W3Potion_VitalityRegen)
function OnUpdate(deltaTime : float)
{
	var none : SAbilityAttributeValue;	//modSigns

	//modSigns: removed the combat and non-combat regen values (ALCH-04: no second regen)
	effectValue = none;	//modSigns

	super.OnUpdate(deltaTime);
}

class W3Potion_Swallow extends W3Potion_VitalityRegen
{
	protected function GetEffectStrength() : float	//modSigns
	{	//modSigns
		return 0;	//modSigns: ALCH-04, audit F1: legacy's strength (no main value), so every dose stacks (DL12's tier rule) even after the running dose's value was zeroed
	}	//modSigns

	event OnEffectAdded(optional customParams : W3BuffCustomParams)	//modSigns
	{	//modSigns
		super.OnEffectAdded(customParams);	//modSigns
		target.RemoveAllBuffsOfType(EET_Bleeding);	//modSigns
	}	//modSigns

	public function CumulateWith(effect: CBaseGameplayEffect)	//modSigns
	{	//modSigns
		super.CumulateWith(effect);	//modSigns
		target.RemoveAllBuffsOfType(EET_Bleeding);	//modSigns
	}	//modSigns
}

// DL10: Reinald's Philtre regenerates through its ability only.
class W3Potion_ReinaldPhiltre extends W3RegenEffect
{
	protected function GetEffectStrength() : float	//modSigns
	{	//modSigns
		return 0;	//modSigns: DL10, audit F1: every dose stacks, as Swallow
	}	//modSigns

	event OnUpdate(dt : float)	//modSigns
	{	//modSigns
		var none : SAbilityAttributeValue;	//modSigns
		effectValue = none;	//modSigns
		super.OnUpdate(dt);	//modSigns
	}	//modSigns
}

// --- White Raffard's Decoction ----------------------------------------------------------------------------

class W3Potion_WhiteRaffardDecoction extends CBaseGameplayEffect
{
	default dontAddAbilityOnTarget = true;	//modSigns: its Vitality share heals; it no longer raises maximum Vitality

	public function CacheSettings()	//modSigns
	{	//modSigns
		super.CacheSettings();	//modSigns
		override.Remove(EET_Swallow);	//modSigns: no longer cancels Swallow (the effect definition's override)
	}	//modSigns

	public function CumulateWith(effect: CBaseGameplayEffect)	//modSigns
	{	//modSigns
		super.CumulateWith(effect);	//modSigns
		GMAddVitality();	//modSigns: every dose heals
	}	//modSigns
}

// 5.x body; changes marked //modSigns.
@replaceMethod(W3Potion_WhiteRaffardDecoction)
function OnEffectAdded(optional customParams : W3BuffCustomParams)
{
	//modSigns: removed the locals of the heal (moved to GMAddVitality)
	super.OnEffectAdded(customParams);

	GMAddVitality();	//modSigns: the heal (and the bleeding cure) in a function every dose calls

	if(GetBuffLevel() == 3)
	{
		target.SetImmortalityMode(AIM_Invulnerable, AIC_WhiteRaffardsPotion);
	}
}

@addMethod(W3Potion_WhiteRaffardDecoction)
function GMAddVitality()
{
	var vitality : float;
	var vitAtt, min, max : SAbilityAttributeValue;

	theGame.GetDefinitionsManager().GetAbilityAttributeValue(abilityName, StatEnumToName(BCS_Vitality), min, max);
	vitAtt = GetAttributeRandomizedValue(min, max);
	vitality = target.GetStatMax(BCS_Vitality) * vitAtt.valueMultiplicative + vitAtt.valueAdditive;
	target.GainStat(BCS_Vitality, vitality);
	target.RemoveAllBuffsOfType(EET_Bleeding);
}

// --- White Honey ------------------------------------------------------------------------------------------

class W3Potion_WhiteHoney extends CBaseGameplayEffect
{
	public function CumulateWith(effect: CBaseGameplayEffect)	//modSigns
	{	//modSigns
		var exceptions : array<CBaseGameplayEffect>;	//modSigns
		var wolf : CBaseGameplayEffect;	//modSigns

		super.CumulateWith(effect);	//modSigns
		// Every dose clears toxicity and the other potions again (legacy), and the locked toxicity (5.x, DL6).
		target.ForceSetStat(BCS_Toxicity, 0);	//modSigns
		exceptions.PushBack(this);	//modSigns
		wolf = thePlayer.GetBuff(EET_WolfHour);	//modSigns
		if(wolf)	//modSigns
			exceptions.PushBack(wolf);	//modSigns
		thePlayer.RemoveAllPotionEffects(exceptions);	//modSigns
		((W3PlayerAbilityManager)GetWitcherPlayer().abilityManager).SetToxicityOffset(0.f);	//modSigns
	}	//modSigns
}

// --- Golden Oriole ----------------------------------------------------------------------------------------

// 5.x body; changes marked //modSigns.
@replaceMethod(W3Potion_GoldenOriole)
function OnEffectAdded(optional customParams : W3BuffCustomParams)
{
	super.OnEffectAdded(customParams);

	//modSigns: removed the level < 3 condition: every tier cures poison
	GMHandlePoisonStatus();	//modSigns
}

// 5.x body; changes marked //modSigns.
@replaceMethod(W3Potion_GoldenOriole)
function CumulateWith(effect: CBaseGameplayEffect)
{
	super.CumulateWith(effect);

	//modSigns: removed the level < 3 condition: every dose cures poison
	GMHandlePoisonStatus();	//modSigns
}

@addMethod(W3Potion_GoldenOriole)
function GMHandlePoisonStatus()
{
	var min, max : SAbilityAttributeValue;

	target.RemoveAllBuffsOfType(EET_Poison);
	target.RemoveAllBuffsOfType(EET_PoisonCritical);
	if(GetBuffLevel() == 3)
	{
		target.AddBuffImmunity(EET_Poison, 'GoldenOrioleTempPoisonImmunity', true);
		target.AddBuffImmunity(EET_PoisonCritical, 'GoldenOrioleTempPoisonImmunity', true);
		theGame.GetDefinitionsManager().GetAbilityAttributeValue(abilityName, 'poison_immunity_duration', min, max);
		target.AddTimer('GMRemoveGoldenOriolePoisonImmunity', min.valueAdditive, false, false, , true, true);
	}
}

class W3Potion_GoldenOriole extends CBaseGameplayEffect
{
	event OnEffectRemoved()	//modSigns
	{	//modSigns
		super.OnEffectRemoved();	//modSigns
		target.RemoveBuffImmunity(EET_Poison, 'GoldenOrioleTempPoisonImmunity');	//modSigns
		target.RemoveBuffImmunity(EET_PoisonCritical, 'GoldenOrioleTempPoisonImmunity');	//modSigns
	}	//modSigns
}

// Golden Oriole level 3: the temporary poison immunity ends.
@addMethod(CActor)
timer function GMRemoveGoldenOriolePoisonImmunity(time : float, id : int)
{
	RemoveBuffImmunity(EET_Poison, 'GoldenOrioleTempPoisonImmunity');
	RemoveBuffImmunity(EET_PoisonCritical, 'GoldenOrioleTempPoisonImmunity');
}
