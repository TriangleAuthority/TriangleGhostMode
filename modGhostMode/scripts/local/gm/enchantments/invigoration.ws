// ENCH-05: Invigoration (Runeword 4), as legacy. In combat at full Vitality, regeneration past the
// maximum builds a bonus effect (dmg_gain_rate: +2% weapon damage per 1% of excess Vitality, up to
// max_bonus +50%), shown on the HUD with a counter (mutations/hudCounters.ws). The bonus multiplies
// the sword's slashing and silver damage in GetTotalWeaponDamage (damage/weapon.ws); a damaging melee
// hit or Sign hit with Conductors of Magic spends it, as do losing Vitality, leaving combat and removing
// the runeword. 5.x's overheal
// (the ability manager's field, a raw-damage pool term) is gone: the field stays 0.
// See docs/features/ench.md.

class W3GMEffect_Runeword4 extends CBaseGameplayEffect
{
	default effectType = EET_GMRuneword4;
	default isPositive = true;

	var overhealBonus : float;
	var rate : float;
	var maxBonus : float;

	event OnEffectAdded(customParams : W3BuffCustomParams)
	{
		var min, max : SAbilityAttributeValue;

		theGame.GetDefinitionsManager().GetAbilityAttributeValue('Runeword 4 _Stats', 'dmg_gain_rate', min, max);
		rate = max.valueMultiplicative;
		theGame.GetDefinitionsManager().GetAbilityAttributeValue('Runeword 4 _Stats', 'max_bonus', min, max);
		maxBonus = max.valueMultiplicative;

		super.OnEffectAdded(customParams);
	}

	event OnEffectRemoved()
	{
		thePlayer.StopEffect('runeword_4');
		super.OnEffectRemoved();
	}

	public function IncOverhealBonus(hp : float)
	{
		overhealBonus += hp * rate;
		PlayRuneword4FX();
	}

	public function GetOverhealBonus() : float
	{
		PlayRuneword4FX();
		return overhealBonus;
	}

	// The weapon damage bonus as a fraction (0.5 = +50%).
	public function GetDamageBonus() : float
	{
		return GetOverhealBonus() / thePlayer.GetStatMax(BCS_Vitality);
	}

	// Caps the bonus (legacy does it here) and shows the runeword's FX.
	public function PlayRuneword4FX()
	{
		overhealBonus = MinF(overhealBonus, thePlayer.GetStatMax(BCS_Vitality) * maxBonus);
		if(!thePlayer.IsEffectActive('runeword_4', true))
			thePlayer.PlayEffect('runeword_4');
	}

	// The HUD counter: the bonus in percent.
	public function GetStacks() : int
	{
		return RoundMath(GetDamageBonus() * 100);
	}

	public function GetMaxStacks() : int
	{
		return 100;
	}
}

// Vitality gained past the maximum feeds the effect (5.x: the ability manager's overheal field);
// ENCH-09: adrenaline gained past the maximum feeds Prolongation's (enchantments/prolongation.ws).
// 5.x body; changes marked //modSigns.
@replaceMethod(W3AbilityManager)
function GainStat( stat : EBaseCharacterStats, amount : float )
{
	var statWithoutLock, statWithLock, lock, max : float;
	var invigoration : W3GMEffect_Runeword4;	//modSigns
	var prolongation : W3GMEffect_Runeword11;	//modSigns: ENCH-09

	statWithoutLock = GetStat(stat, true);
	statWithLock = GetStat(stat, false);
	lock = statWithLock - statWithoutLock;
	max = GetStatMax(stat);

	SetStatPointCurrent(stat, MinF( max - lock, statWithoutLock + MaxF(0, amount) ) );

	if( stat == BCS_Vitality )
	{
		OnVitalityChanged();
		if ( (W3PlayerAbilityManager)this && owner == GetWitcherPlayer() && GetWitcherPlayer().HasRunewordActive('Runeword 4 _Stats') && GetWitcherPlayer().IsInCombat() && (statWithoutLock + amount) > max )
		{
			//modSigns: removed 5.x's overheal field and its FX
			if(!thePlayer.HasBuff(EET_GMRuneword4))	//modSigns
				thePlayer.AddEffectDefault(EET_GMRuneword4, NULL, "");	//modSigns
			invigoration = (W3GMEffect_Runeword4)thePlayer.GetBuff(EET_GMRuneword4);	//modSigns
			if(invigoration)	//modSigns
				invigoration.IncOverhealBonus((statWithoutLock + amount) - GetStatMax(stat));	//modSigns
		}
	}
	else if( stat == BCS_Toxicity )
		OnToxicityChanged();
	else if( stat == BCS_Focus )
	{	//modSigns
		OnFocusChanged();
		if((W3PlayerAbilityManager)this && owner == GetWitcherPlayer() && GetWitcherPlayer().IsInCombat() && (statWithoutLock + amount) > max && GetWitcherPlayer().HasRunewordActive('Runeword 11 _Stats'))	//modSigns: ENCH-09, Prolongation: adrenaline gained at the maximum (legacy)
		{	//modSigns
			if(!thePlayer.HasBuff(EET_GMRuneword11))	//modSigns
				thePlayer.AddEffectDefault(EET_GMRuneword11, NULL, "");	//modSigns
			prolongation = (W3GMEffect_Runeword11)thePlayer.GetBuff(EET_GMRuneword11);	//modSigns
			if(prolongation)	//modSigns
				prolongation.IncBonusAdrenaline((statWithoutLock + amount) - GetStatMax(stat));	//modSigns
		}	//modSigns
	}	//modSigns
	else if( stat == BCS_Essence )
		OnEssenceChanged();
}

// Removing the runeword ends the bonus (5.x: resets the overheal field, which this keeps doing).
@wrapMethod(W3AbilityManager)
function OnAbilityRemoved( abilityName : name )
{
	wrappedMethod(abilityName);
	if( abilityName == 'Runeword 4 _Stats' )
		thePlayer.RemoveBuff(EET_GMRuneword4);
}

// Losing Vitality ends the bonus.
@wrapMethod(W3PlayerAbilityManager)
function OnVitalityChanged()
{
	wrappedMethod();
	if(GetStatPercents(BCS_Vitality) < 1.f)
		owner.RemoveBuff(EET_GMRuneword4);
}

// Vitality regeneration runs on at the maximum only while the runeword is active (legacy's rule,
// ENCH-01: the drawn sword); 5.x keeps it running with the runeword on either sword.
@wrapMethod(W3Effect_AutoVitalityRegen)
function OnUpdate(deltaTime : float)
{
	var witcher : W3PlayerWitcher;

	wrappedMethod(deltaTime);
	witcher = (W3PlayerWitcher)target;
	if(witcher && witcher.GetStatPercents(BCS_Vitality) >= 1.0f && !witcher.HasRunewordActive('Runeword 4 _Stats'))
		witcher.StopVitalityRegen();
}

// A damaging melee hit, or Sign hit with Conductors of Magic (whose damage reads the sword's), spends the
// bonus: the changelist's rule and legacy's own clause, which legacy placed in the melee branch where it
// could never act (the owner's decision; deviation, recorded).
@wrapMethod(W3PlayerWitcher)
function OnProcessActionPost(action : W3DamageAction)
{
	var attackAction : W3Action_Attack;
	var actorVictim : CActor;

	wrappedMethod(action);
	attackAction = (W3Action_Attack)action;
	if((attackAction && attackAction.IsActionMelee() || action.IsActionWitcherSign() && IsMutationActive(EPMT_Mutation1)) && HasBuff(EET_GMRuneword4) && action.DealsAnyDamage() && !action.IsDoTDamage())
	{
		RemoveBuff(EET_GMRuneword4);
		actorVictim = (CActor)action.victim;
		if(actorVictim)
			actorVictim.CreateFXEntityAtPelvis( 'runeword_4', true );
	}
}

// Leaving combat ends the bonus.
@wrapMethod(W3PlayerWitcher)
function OnCombatFinished()
{
	wrappedMethod();
	RemoveBuff(EET_GMRuneword4);
}

// The effect does not survive a load.
@wrapMethod(W3PlayerWitcher)
function OnSpawned(spawnData : SEntitySpawnData)
{
	wrappedMethod(spawnData);
	RemoveBuff(EET_GMRuneword4);
}

// Drawing the sword or changing gloves shows the FX while the bonus is up (5.x's call reads the
// overheal field, which stays 0).
@wrapMethod(CR4Player)
function PlayRuneword4FX(optional weaponType : EPlayerWeapon)
{
	var invigoration : W3GMEffect_Runeword4;

	wrappedMethod(weaponType);
	invigoration = (W3GMEffect_Runeword4)GetBuff(EET_GMRuneword4);
	if(invigoration)
		invigoration.PlayRuneword4FX();
}

// For the tests and the weapon damage: the current bonus as a fraction, 0 without the effect.
@addMethod(W3PlayerWitcher)
function GMInvigorationBonus() : float
{
	var invigoration : W3GMEffect_Runeword4;

	invigoration = (W3GMEffect_Runeword4)GetBuff(EET_GMRuneword4);
	if(!invigoration)
		return 0;
	return invigoration.GetDamageBonus();
}
