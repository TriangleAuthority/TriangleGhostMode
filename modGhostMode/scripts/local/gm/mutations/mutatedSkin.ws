// MUT-10 Mutated Skin (Mutation 5), as legacy: a hit taken (not a DoT, with damage) while Geralt
// has at least 1 adrenaline point is not dealt at once but over 5 s per adrenaline point (max 15 s),
// as a DoT; meanwhile adrenaline drains by 1 point per 5 s, and at 0 the rest lands at once; a new
// hit spreads its damage and the remainder over the new duration. The hit still counts as dealt for
// everything else (only the Vitality drain is left out: CActor.OnTakeDamage, mutations/takeDamage.ws).
// 5.x: -15% damage per adrenaline point. Vanilla's damage reduction (ReduceDamage, defense/dodge.ws)
// and its EET_Mutation5 buff (combat start, adrenaline changes) are gone.
// The DoT is its own effect type, EET_GMMutation5 (W3GMEffect_Mutation5, a W3DamageOverTimeEffect;
// 5.x's W3Effect_Mutation5 is a plain effect and a scope-based override cannot change a class's
// base class), so it also lasts past combat end and an unequip, as legacy's (5.x removes
// EET_Mutation5 there).
// See docs/features/mut.md.

class W3GMEffect_Mutation5 extends W3DamageOverTimeEffect
{
	var focusDrainPerSec : float;

	default effectType = EET_GMMutation5;
	default isPositive = false;
	default isNeutral = false;
	default isNegative = true;
	default resistStat = CDS_None;
	default powerStatType = CPS_Undefined;

	function ActivateEffect()
	{
		var focus : float;

		theGame.MutationHUDFeedback(MFT_PlayOnce);
		focus = target.GetStat(BCS_Focus);
		if(focus >= 3.f)
			target.PlayEffect('mutation_5_stage_03');
		else if(focus >= 2.f)
			target.PlayEffect('mutation_5_stage_02');
		else
			target.PlayEffect('mutation_5_stage_01');
	}

	event OnEffectAdded(optional customParams : W3BuffCustomParams)
	{
		super.OnEffectAdded(customParams);
		ActivateEffect();
	}

	protected function GetSelfInteraction(e : CBaseGameplayEffect) : EEffectInteract
	{
		return EI_Cumulate;
	}

	// A new hit: the remaining damage is spread over the new duration with the new hit's. (Legacy kept
	// the old rate instead of the new hit's, the base CumulateWith not taking the new value, so the
	// new hit's damage was lost: fixed, a deviation.)
	public function CumulateWith(effect : CBaseGameplayEffect)
	{
		var remainder : float;
		var newValue : SAbilityAttributeValue;

		remainder = effectValue.valueAdditive * timeLeft;
		newValue = effect.GetEffectValue();
		super.CumulateWith(effect);
		ActivateEffect();
		if(timeLeft > 0)
			effectValue.valueAdditive = newValue.valueAdditive + remainder / timeLeft;
	}

	event OnUpdate(dt : float)
	{
		var min, max : SAbilityAttributeValue;

		super.OnUpdate(dt);
		// out of adrenaline: the rest lands at once and the effect ends
		if(target.GetStat(BCS_Focus) <= 0.0)
		{
			if(timeLeft > 0.0)
				target.DrainVitality(effectValue.valueAdditive * timeLeft);
			timeLeft = 0.0;
			isActive = false;
		}
		else
		{
			if(focusDrainPerSec <= 0.0)
			{
				theGame.GetDefinitionsManager().GetAbilityAttributeValue('Mutation5', 'mut5_duration_per_point', min, max);
				focusDrainPerSec = 1.0 / min.valueAdditive;
			}
			((W3PlayerWitcher)target).DrainFocus(dt * focusDrainPerSec);
		}
	}

	public function GMGetDamagePerSec() : float
	{
		return effectValue.valueAdditive;
	}
}

@addField(W3DamageAction)
var gmMutation5Triggered : bool;

@addMethod(W3DamageAction)
function GMSetMutation5Triggered()
{
	gmMutation5Triggered = true;
}

@addMethod(W3DamageAction)
function GMGetMutation5Triggered() : bool
{
	return gmMutation5Triggered;
}

// The trigger (legacy's, in OnTakeDamage before the damage is applied; mutations/takeDamage.ws).
@addMethod(W3PlayerWitcher)
function GMMutation5Trigger(action : W3DamageAction, currVitality : float, killSourceName : string)
{
	var params : SCustomEffectParams;
	var min, max : SAbilityAttributeValue;

	if(IsMutationActive(EPMT_Mutation5) && !action.IsDoTDamage() && action.processedDmg.vitalityDamage > 0.0 && GetStat(BCS_Focus) >= 1.0)
	{
		if(action.processedDmg.vitalityDamage < currVitality || killSourceName != "Quest" && killSourceName != "Kill Trigger" && killSourceName != "Trap" && killSourceName != "FallingDamage")
		{
			theGame.GetDefinitionsManager().GetAbilityAttributeValue('Mutation5', 'mut5_duration_per_point', min, max);
			params.effectType = EET_GMMutation5;
			params.creator = this;
			params.sourceName = "mutation5";
			params.duration = min.valueAdditive * GetStat(BCS_Focus);
			params.effectValue.valueAdditive = action.processedDmg.vitalityDamage / params.duration;
			AddEffectCustom(params);
			action.GMSetMutation5Triggered();
		}
	}
}

// No vanilla Mutated Skin buff on adrenaline changes.
@replaceMethod(W3PlayerAbilityManager)
function OnFocusChanged()
{
	var points : float;
	var buff : W3Effect_Toxicity;
	
	points = GetStat(BCS_Focus);
	
	if(points < owner.GetStatMax(BCS_Focus))	//modSigns: ENCH-09, Prolongation's bonus ends below the maximum (legacy)
		owner.RemoveBuff(EET_GMRuneword11);	//modSigns
	
	if(points < 1 && owner.HasBuff(EET_BattleTrance))
	{
		owner.RemoveBuff(EET_BattleTrance);
	}
	else if(points >= 1 && !owner.HasBuff(EET_BattleTrance))
	{
		if(CanUseSkill(S_Sword_5))
			owner.AddEffectDefault(EET_BattleTrance, owner, "BattleTranceSkill");
	}
	
	if ( (W3PlayerWitcher)owner && points >= owner.GetStatMax(BCS_Focus) && ((W3PlayerWitcher)owner).HasRunewordActive('Runeword 8 _Stats') && !owner.HasBuff(EET_Runeword8) )	//modSigns: ENCH-07, Placation from the drawn sword (ENCH-01)
	{
		owner.AddEffectDefault(EET_Runeword8, owner, "max focus");
	}
	
	
	//modSigns: removed 5.x's Mutated Skin buff on adrenaline changes (MUT-10)

	
	thePlayer.OnFocusChanged();
}

