// ENCH-07 Placation (Runeword 8) and ENCH-08 Rejuvenation and Elation (Runewords 10, 12), as legacy.
// Placation: at maximum adrenaline (from the drawn sword, the check in MUT's replaced OnFocusChanged,
// mutations/mutatedSkin.ws) adrenaline declines at focus_drain points/s to zero, in or out of combat,
// with no gain meanwhile (5.x's GainStat); the regen bonuses are 'Runeword 8 Regen' (gm_ench.xml).
// Rejuvenation and Elation: an enemy's death by Geralt's hand heals 15% Vitality / gives 0.25
// adrenaline, triggered from CNewNPC.OnDeath (enchantments/npcDeath.ws), finishers included, once.
// 5.x bodies; changes marked //modSigns. See docs/features/ench.md.

// Placation drains adrenaline itself (5.x: through the adrenaline drain effect, which stops in combat).
@replaceMethod(W3Effect_Runeword8)
function OnEffectAdded(customParams : W3BuffCustomParams)
{
	var val : SAbilityAttributeValue;
	var min : SAbilityAttributeValue;	//modSigns
	var toxicity : W3Effect_Toxicity;

	if(!((W3PlayerWitcher)target))	//modSigns: Geralt only (legacy)
	{	//modSigns
		isActive = false;	//modSigns
		return false;	//modSigns
	}	//modSigns

	target.AddAbility('Runeword 8 Regen');
	//modSigns: removed the adrenaline drain effect (the effect drains in OnUpdate, legacy)

	theGame.GetDefinitionsManager().GetAbilityAttributeValue('Runeword 8 Regen', 'focus_drain', min, val);	//modSigns: the ability's value (legacy)
	focusDrainPerSec = min.valueMultiplicative;	//modSigns

	CalculateDuration();

	toxicity = (W3Effect_Toxicity)target.GetBuff(EET_Toxicity);
	if(toxicity)
		toxicity.RecalcEffectValue();

	super.OnEffectAdded(customParams);
}

@replaceMethod(W3Effect_Runeword8)
function OnUpdate(dt : float)
{
	super.OnUpdate(dt);

	((CR4Player)target).DrainFocus(dt * focusDrainPerSec);	//modSigns: the drain (legacy)
	timeLeft = target.GetStatPercents(BCS_Focus) * initialDuration;
	timeLeft = MaxF(timeLeft, 0);	//modSigns
}

// The after-combat adrenaline drain pauses while Placation drains (5.x: Placation used it in combat).
@replaceMethod(W3Effect_AdrenalineDrain)
function OnUpdate(dt : float)
{
	var drainVal : float;
	var buff : W3Effect_Toxicity;


	if(target.IsInCombat() || target.HasBuff(EET_Runeword8))	//modSigns: not while Placation drains
		isActive = false;

	drainVal = dt * (effectValue.valueAdditive + (target.GetStatMax(BCS_Focus) + effectValue.valueBase) * effectValue.valueMultiplicative);
	((CR4Player)target).DrainFocus(drainVal);


	if(target.GetStat(BCS_Focus) <= 0)
	{
		isActive = false;
	}
}

// Rejuvenation heals (5.x: restores stamina).
@replaceMethod(W3PlayerWitcher)
function Runeword10Triggerred()
{
	var min, max : SAbilityAttributeValue;

	theGame.GetDefinitionsManager().GetAbilityAttributeValue( 'Runeword 10 _Stats', 'health', min, max );	//modSigns: Vitality (legacy)
	GainStat(BCS_Vitality, min.valueMultiplicative * GetStatMax(BCS_Vitality));	//modSigns
	//modSigns: removed 5.x's stamina gain

	PlayEffect('runeword_10_stamina');
}

// Elation gives a fixed amount (5.x: a random amount of focus_runeword_gain, capped).
@replaceMethod(W3PlayerWitcher)
function Runeword12Triggerred()
{
	var min, max : SAbilityAttributeValue;

	theGame.GetDefinitionsManager().GetAbilityAttributeValue( 'Runeword 12 _Stats', 'focus', min, max );	//modSigns: legacy's attribute
	GainStat(BCS_Focus, min.valueAdditive);	//modSigns
	//modSigns: removed 5.x's random amount and cap

	PlayEffect('runeword_20_adrenaline');
}

// The finisher triggers are gone: OnDeath triggers both words once for every kill (legacy).
@replaceMethod(CR4Player)
function OnAnimEvent_pad_vibration( animEventName : name, animEventType : EAnimationEventType, animInfo : SAnimationEventAnimInfo )
{
	//modSigns: removed the witcher variable
	theGame.VibrateControllerHard();
	//modSigns: removed 5.x's Rejuvenation and Elation triggers on finishers (ENCH-08: CNewNPC.OnDeath)
}
