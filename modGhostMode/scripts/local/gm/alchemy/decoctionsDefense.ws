// ALCH-13: defensive and conditional decoctions (legacy's), and ALCH-09's Nightwraith.
// - Arachas (Mutagen 2): an enemy that damages Geralt in melee (not dodged) gets acid: -1% to all its
//   resistances per hit, up to -10% (damage/formula.ws). The owner's DL12 fix: the stacks are removed from the
//   enemies when Geralt's fight ends and when the decoction ends (legacy never removed them).
// - Doppler (Mutagen 11): +50% crit damage from behind (data; skills/oils.ws reads it).
// - Fiend (Mutagen 16): no hit reaction from hits below 15% of maximum Vitality (damage over time excluded).
// - Elemental (Mutagen 20): flat 50% resistance to bleeding, burning and poison effects and to fire and poison
//   damage (its ability on Geralt). 1.32's resistance growing while affected is gone.
// - Werewolf (Mutagen 24): at 20% Vitality or less in combat: +50% attack power and sign intensity, +5 stamina
//   regen, +25% adrenaline gain; off above 20% (then a 10 s cooldown) and out of combat. 1.32's free sprint and
//   5.x's night regen are gone.
// - Leshen (Mutagen 26): 25% of damage taken returned (data; damage/returned.ws).
// - Griffin (Mutagen 27): two hits within 1 s make Geralt immune to damage for 2 s (counted as dodged).
// - Reliever's (Mutagen 28): against an enemy in spectral form Geralt deals 60% (10% without), takes half.
//   1.32's attack power and resistances against specters and 5.x's specter ability block are gone.
// - Nightwraith (Mutagen 6): a new dose wipes the stacks.
// See docs/features/alch.md.

// ---- Arachas ---------------------------------------------------------------------------------------------

class W3Mutagen02_Effect extends W3Mutagen_Effect
{
	default dontAddAbilityOnTarget = true;	//modSigns: the ability is the acid on enemies

	event OnEffectRemoved()	//modSigns
	{	//modSigns
		super.OnEffectRemoved();	//modSigns
		GMClearArachasDebuffs();	//modSigns: DL12
	}	//modSigns
}

// The enemies Geralt's Arachas acid is on (not saved).
@addField(W3PlayerWitcher)
var gmArachasVictims : array<CActor>;

@addMethod(W3Mutagen02_Effect)
function GMAddDebuffToEnemy(enemy : CActor)
{
	var abilityCount, maxStack : int;
	var min, max : SAbilityAttributeValue;

	if(enemy && enemy != thePlayer)
	{
		theGame.GetDefinitionsManager().GetAbilityAttributeValue(abilityName, 'mutagen02_max_stack', min, max);
		maxStack = RoundMath(CalculateAttributeValue(GetAttributeRandomizedValue(min, max)));
		abilityCount = enemy.GetAbilityCount(abilityName);
		if(abilityCount < maxStack)
		{
			enemy.AddAbility(abilityName, true);
			GetWitcherPlayer().GMAddArachasVictim(enemy);
		}
	}
}

@addMethod(W3PlayerWitcher)
function GMAddArachasVictim(enemy : CActor)
{
	if(!gmArachasVictims.Contains(enemy))
		gmArachasVictims.PushBack(enemy);
}

// DL12: the acid leaves every enemy it is on.
function GMClearArachasDebuffs()
{
	GetWitcherPlayer().GMClearArachasVictims();
}

@addMethod(W3PlayerWitcher)
function GMClearArachasVictims()
{
	var i : int;

	for(i = 0; i < gmArachasVictims.Size(); i += 1)
		if(gmArachasVictims[i])
			gmArachasVictims[i].RemoveAbilityAll('Mutagen02Effect');
	gmArachasVictims.Clear();
}

// The acid's resistance cut on an enemy (damage/formula.ws, GetDamageResists).
function GMArachasResistReduction(victim : CActor) : float
{
	if(victim && victim != thePlayer && victim.HasAbility('Mutagen02Effect'))
		return CalculateAttributeValue(victim.GetAttributeValue('mutagen02_resist_reduction'));
	return 0;
}

// ---- Fiend -----------------------------------------------------------------------------------------------

@addMethod(W3Mutagen16_Effect)
function GMModifyHitAnim(out action : W3DamageAction)
{
	var min, max : SAbilityAttributeValue;

	if(action.IsDoTDamage())
		return;
	theGame.GetDefinitionsManager().GetAbilityAttributeValue('Mutagen16Effect', 'mutagen16_health_prc', min, max);
	if(action.GetDamageDealt() <= CalculateAttributeValue(min) * target.GetMaxHealth())
		action.SetHitAnimationPlayType(EAHA_ForceNo);
}

// ---- Elemental -------------------------------------------------------------------------------------------

class W3Mutagen20_Effect extends W3Mutagen_Effect
{
	default dontAddAbilityOnTarget = false;	//modSigns: its flat resistances are an ability on Geralt (legacy)
}

// 5.x body: 1.32's resistance growing while affected. Changes marked //modSigns.
@replaceMethod(W3Mutagen20_Effect)
function GetResistBonus(resist : ECharacterDefenseStats, out points : SAbilityAttributeValue, out percents : SAbilityAttributeValue)
{
	var none : SAbilityAttributeValue;	//modSigns

	//modSigns: removed 1.32's growing resistances (ALCH-13: legacy's flat resistances come from the ability)
	points = none;	//modSigns
	percents = none;	//modSigns
}

// ---- Werewolf --------------------------------------------------------------------------------------------

class W3Mutagen24_Effect extends W3Mutagen_Effect
{
	default isPositive = false;	//modSigns
	default isNegative = false;	//modSigns
	default isNeutral = true;	//modSigns

	event OnEffectAdded(optional customParams : W3BuffCustomParams)	//modSigns
	{	//modSigns
		super.OnEffectAdded(customParams);	//modSigns
		GMManageMutagen24Bonus();	//modSigns
	}	//modSigns

	event OnEffectRemoved()	//modSigns
	{	//modSigns
		super.OnEffectRemoved();	//modSigns
		GMResetMutagen24Bonus();	//modSigns
	}	//modSigns
}

@addField(W3Mutagen24_Effect)
var gmCooldownTimer : float;

// 5.x body: 1.32's ability at night in clear weather. Changes marked //modSigns.
@replaceMethod(W3Mutagen24_Effect)
function OnUpdate(dt : float)
{
	//modSigns: removed the hour's local
	super.OnUpdate(dt);

	//modSigns: removed 1.32's night ability (and 5.x's stamina regen with it); legacy's cooldown instead
	if(gmCooldownTimer > 0.0f)	//modSigns
		gmCooldownTimer -= dt;	//modSigns
	else if(gmCooldownTimer > -999.0f)	//modSigns
	{	//modSigns
		gmCooldownTimer = -1000.0f;	//modSigns
		GMForceUpdateBuffsModule();	//modSigns
	}	//modSigns
}

// 5.x body; changes marked //modSigns.
@replaceMethod(W3Mutagen24_Effect)
function OnLoad(t : CActor, eff : W3EffectManager)
{
	super.OnLoad(t, eff);
	//modSigns: removed the night ability's flag
}

@addMethod(W3Mutagen24_Effect)
function GMManageMutagen24Bonus()
{
	var min, max : SAbilityAttributeValue;

	if(target == thePlayer && thePlayer.IsInCombat())
	{
		theGame.GetDefinitionsManager().GetAbilityAttributeValue(abilityName, 'm24_hp_threshold', min, max);
		if(!thePlayer.HasAbility(abilityName))
		{
			if(thePlayer.GetStatPercents(BCS_Vitality) <= CalculateAttributeValue(GetAttributeRandomizedValue(min, max)) && gmCooldownTimer <= 0.0f)
			{
				thePlayer.AddAbility(abilityName);
				thePlayer.SoundEvent("magic_geralt_healing_oneshot");
				GMForceUpdateBuffsModule();
			}
		}
		else if(thePlayer.GetStatPercents(BCS_Vitality) > CalculateAttributeValue(GetAttributeRandomizedValue(min, max)))
		{
			theGame.GetDefinitionsManager().GetAbilityAttributeValue(abilityName, 'm24_cooldown_time', min, max);
			gmCooldownTimer = CalculateAttributeValue(GetAttributeRandomizedValue(min, max));
			GMResetMutagen24Bonus();
		}
	}
	else if(target == thePlayer)
	{
		GMResetMutagen24Bonus();
	}
}

@addMethod(W3Mutagen24_Effect)
function GMResetMutagen24Bonus()
{
	if(thePlayer.HasAbility(abilityName))
	{
		thePlayer.RemoveAbilityAll(abilityName);
		GMForceUpdateBuffsModule();
	}
}

// The HUD colour: legacy's, its quirk included (the cooldown branch sets isNegative twice).
@addMethod(W3Mutagen24_Effect)
function GMForceUpdateBuffsModule()
{
	var hud : CR4ScriptedHud;
	var module : CR4HudModuleBuffs;

	if(gmCooldownTimer > 0)
	{
		isPositive = false;
		isNegative = true;
		isNegative = false;
	}
	else if(thePlayer.HasAbility(abilityName))
	{
		isPositive = true;
		isNegative = false;
		isNeutral = false;
	}
	else
	{
		isPositive = false;
		isNegative = false;
		isNeutral = true;
	}
	hud = (CR4ScriptedHud)theGame.GetHud();
	if(hud)
	{
		module = (CR4HudModuleBuffs)hud.GetHudModule("BuffsModule");
		if(module)
			module.ForceUpdate();
	}
}

function GMManageWerewolf()
{
	if(thePlayer.HasBuff(EET_Mutagen24))
		((W3Mutagen24_Effect)thePlayer.GetBuff(EET_Mutagen24)).GMManageMutagen24Bonus();
}

@wrapMethod(W3PlayerAbilityManager)
function OnVitalityChanged()
{
	wrappedMethod();
	if(owner == GetWitcherPlayer())
		GMManageWerewolf();
}

@wrapMethod(W3PlayerWitcher)
function OnCombatStart()
{
	wrappedMethod();
	GMManageWerewolf();
}

// ---- Griffin ---------------------------------------------------------------------------------------------

@addField(W3Mutagen27_Effect)
var gmBonusActive : bool;
@addField(W3Mutagen27_Effect)
var gmBonusTimeLeft : float;
@addField(W3Mutagen27_Effect)
var gmCachedNumHits : int;
@addField(W3Mutagen27_Effect)
var gmCachedTime : float;

@addMethod(W3Mutagen27_Effect)
function GMAccumulateHits()
{
	var min, max : SAbilityAttributeValue;

	if(gmBonusActive)
		return;
	gmCachedNumHits += 1;
	if(gmCachedNumHits == 1)
	{
		gmCachedTime = theGame.GetEngineTimeAsSeconds();
		return;
	}
	theGame.GetDefinitionsManager().GetAbilityAttributeValue('Mutagen27Effect', 'mutagen27_dmg_window', min, max);
	if(theGame.GetEngineTimeAsSeconds() - gmCachedTime <= CalculateAttributeValue(min))
	{
		GMSetBonusActive(true);
		return;
	}
	gmCachedNumHits = 1;
	gmCachedTime = theGame.GetEngineTimeAsSeconds();
}

@addMethod(W3Mutagen27_Effect)
function GMSetBonusActive(a : bool)
{
	var min, max : SAbilityAttributeValue;

	gmBonusActive = a;
	if(a)
	{
		theGame.GetDefinitionsManager().GetAbilityAttributeValue('Mutagen27Effect', 'mutagen27_bonus_duration', min, max);
		gmBonusTimeLeft = CalculateAttributeValue(min);
		thePlayer.PlayEffect( 'power' );
	}
	else
	{
		gmCachedNumHits = 0;
		gmCachedTime = 0;
	}
}

@addMethod(W3Mutagen27_Effect)
function GMIsBonusActive() : bool
{
	return gmBonusActive;
}

// While the immunity runs, a hit is dodged and deals nothing.
@addMethod(W3Mutagen27_Effect)
function GMReduceDamage(out damageData : W3DamageAction)
{
	if(gmBonusActive)
	{
		damageData.SetAllProcessedDamageAs(0);
		damageData.SetWasDodged();
		thePlayer.PlayEffect( 'power_place_quen' );
		thePlayer.SoundEvent("sign_quen_discharge_short");
	}
}

class W3Mutagen27_Effect extends W3Mutagen_Effect
{
	default dontAddAbilityOnTarget = false;	//modSigns: legacy's Griffin adds its ability on Geralt (no stacking resistances in its data)

	public function OnTimeUpdated(dt : float)	//modSigns
	{	//modSigns
		super.OnTimeUpdated(dt);	//modSigns
		if(gmBonusActive)	//modSigns
		{	//modSigns
			gmBonusTimeLeft -= dt;	//modSigns
			if(gmBonusTimeLeft <= 0)	//modSigns
				GMSetBonusActive(false);	//modSigns
		}	//modSigns
	}	//modSigns
}

// GMReduceDamage is called in W3PlayerWitcher.ReduceDamage right after its base reduction (defense/dodge.ws).

// ---- Reliever's ------------------------------------------------------------------------------------------

@addMethod(W3Mutagen28_Effect)
function GMGetDmgMultiplier() : float
{
	var min, max : SAbilityAttributeValue;

	theGame.GetDefinitionsManager().GetAbilityAttributeValue('Mutagen28Effect', 'mutagen28_dmg_mult', min, max);
	return CalculateAttributeValue(min);
}

@addMethod(W3Mutagen28_Effect)
function GMGetDmgReduction() : float
{
	var min, max : SAbilityAttributeValue;

	theGame.GetDefinitionsManager().GetAbilityAttributeValue('Mutagen28Effect', 'mutagen28_dmg_reduction', min, max);
	return CalculateAttributeValue(min);
}

// 5.x body: 1.32's attack power against specters. Changes marked //modSigns.
@replaceMethod(W3Mutagen28_Effect)
function GetMonsterDamageBonus(mc : EMonsterCategory) : SAbilityAttributeValue
{
	var none : SAbilityAttributeValue;	//modSigns
	//modSigns: removed 1.32's attack power against specters (ALCH-13: legacy's Reliever's acts on the spectral form, CActor.ReduceDamage)
	return none;	//modSigns
}

// 5.x body: 1.32's resistances against specters. Changes marked //modSigns.
@replaceMethod(W3Mutagen28_Effect)
function GetProtection(mc : EMonsterCategory, dmgType : name, isDoT : bool, out bonusResist : float, out bonusReduct : float)
{
	//modSigns: removed 1.32's resistances against specters (ALCH-13)
	bonusResist = 0;	//modSigns
	bonusReduct = 0;	//modSigns
}

// ---- Nightwraith (ALCH-09) ---------------------------------------------------------------------------------

class W3Mutagen06_Effect extends W3Mutagen_Effect
{
	public function CumulateWith(effect: CBaseGameplayEffect)	//modSigns
	{	//modSigns
		super.CumulateWith(effect);	//modSigns
		target.RemoveAbilityAll(abilityName);	//modSigns: a new dose wipes the stacks (legacy)
	}	//modSigns
}

// ---- Hooks ------------------------------------------------------------------------------------------------

// Called from GMDecoctionsOnDamageTaken (the damage Geralt takes).
function GMDefenseDecoctionsOnDamageTaken(action : W3DamageAction)
{
	var w : W3PlayerWitcher;

	w = GetWitcherPlayer();
	if(w.HasBuff(EET_Mutagen02) && !action.WasDodged() && action.DealtDamage() && action.IsActionMelee())
		((W3Mutagen02_Effect)w.GetBuff(EET_Mutagen02)).GMAddDebuffToEnemy((CActor)action.attacker);
	if(w.HasBuff(EET_Mutagen27) && !action.WasDodged() && action.DealtDamage() && !(action.IsActionEnvironment() || action.IsDoTDamage()))
		((W3Mutagen27_Effect)w.GetBuff(EET_Mutagen27)).GMAccumulateHits();
}
