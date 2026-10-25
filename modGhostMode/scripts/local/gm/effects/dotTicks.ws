// EFX-04: damage-over-time ticks, and EFX-06's check in the tick (docs/features/efx.md).
// EFX-04 (legacy's CalculateDamage): a tick of bleeding, poison or burning hits only the stat the
// victim uses (Vitality or Essence; 1.32 and 5.x take the larger of both maximums when an effect is
// flagged for both), and deals at least 1 raw damage per second (before resistances).
// EFX-06 (bugfix 173, legacy's OnUpdate): an inactive or expired damage over time deals nothing.
// 5.x bodies; changes marked //modSigns.

// EFX-06: no tick once the effect is inactive or its time is up.
@replaceMethod(W3DamageOverTimeEffect)
function OnUpdate(dt : float)
{
	var dmg, maxVit, maxEss : float;
	var i : int;

	super.OnUpdate(dt);

	if(!target.IsAlive())
		return true;

	if(!isActive || (duration != -1 && timeLeft <= 0))	//modSigns: EFX-06
		return true;	//modSigns

	maxVit = target.GetStatMax( BCS_Vitality);
	maxEss = target.GetStatMax( BCS_Essence);

	for(i=0; i<damages.Size(); i+=1)
	{
		dmg = CalculateDamage(i, maxVit, maxEss, dt);

		if( (!damages[i].hitsVitality && !damages[i].hitsEssence) || dmg <= 0)
		{
			LogAssert(false, "W3DamageOverTimeEffect: effect " + this + " on " + target.GetReadableName() + " is dealing no damage");
		}
		else
		{
			effectManager.CacheDamage(damages[i].damageTypeName, dmg, GetCreator(), this, dt, true, powerStatType, isEnvironment);
		}


		if(effectValue.valueBase != 0)
			LogAssert(false, "W3DamageOverTimeEffect.OnUpdate: effect <<" + this + ">> has baseValue set which makes no sense!!!!");
		else if(effectValue.valueMultiplicative == 1)
			LogAssert(false, "W3DamageOverTimeEffect.OnUpdate: effect <<" + this + ">> has valueMultiplicative set to 1 which results in 100% MAX HP damage /sec!!!!!");
	}
}

// EFX-04: only the stat the target uses; at least 1 damage per second.
@replaceMethod(W3DamageOverTimeEffect)
function CalculateDamage(arrayIndex : int, maxVit : float, maxEss : float, dt : float) : float
{
	var dmg, dmgV, dmgE : float;

	if(damages[arrayIndex].hitsVitality && target.UsesVitality())	//modSigns: EFX-04
	{
		dmgV = MaxF(0, dt * (effectValue.valueAdditive + (effectValue.valueMultiplicative * maxVit) ));
	}
	if(damages[arrayIndex].hitsEssence && target.UsesEssence())	//modSigns: EFX-04
	{
		dmgE = MaxF(0, dt * (effectValue.valueAdditive + (effectValue.valueMultiplicative * maxEss) ));
	}

	dmg = MaxF(dmgE, dmgV);
	dmg = MaxF(dt, dmg);	//modSigns: EFX-04, at least 1 damage per second
	return dmg;
}
