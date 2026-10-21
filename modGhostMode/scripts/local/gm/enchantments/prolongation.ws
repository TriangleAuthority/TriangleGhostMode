// ENCH-09: Prolongation (Runeword 11), as legacy. In combat, adrenaline gained at the maximum builds a
// bonus (the effect, fed from W3AbilityManager.GainStat in enchantments/invigoration.ws): potion timers
// run slower by duration_gain_rate (0.5) % per 1% of excess adrenaline (3 points = 100%), up to max_bonus
// (50%), not for decoctions or White Raffard; shown on the HUD with a counter (mutations/hudCounters.ws).
// The bonus ends below maximum adrenaline (MUT's replaced OnFocusChanged), at combat end and at load.
// 5.x's +1 s per hit (CNewNPC.OnTakeDamage) reads the ability's 'duration', which legacy's ability does
// not have: it adds nothing. See docs/features/ench.md.

class W3GMEffect_Runeword11 extends CBaseGameplayEffect
{
	default effectType = EET_GMRuneword11;
	default isPositive = true;

	var bonusAdrenaline : float;
	var rate : float;
	var maxBonus : float;

	event OnEffectAdded(customParams : W3BuffCustomParams)
	{
		var min, max : SAbilityAttributeValue;

		theGame.GetDefinitionsManager().GetAbilityAttributeValue('Runeword 11 _Stats', 'duration_gain_rate', min, max);
		rate = max.valueMultiplicative;
		theGame.GetDefinitionsManager().GetAbilityAttributeValue('Runeword 11 _Stats', 'max_bonus', min, max);
		maxBonus = max.valueMultiplicative;

		super.OnEffectAdded(customParams);
	}

	public function IncBonusAdrenaline(delta : float)
	{
		bonusAdrenaline += delta * rate;
		bonusAdrenaline = MinF(bonusAdrenaline, thePlayer.GetStatMax(BCS_Focus) * maxBonus);
	}

	public function GetBonusAdrenaline() : float
	{
		bonusAdrenaline = MinF(bonusAdrenaline, thePlayer.GetStatMax(BCS_Focus) * maxBonus);
		return bonusAdrenaline;
	}

	// How much slower potion timers run (0.5 = half speed).
	public function GetExpirationBonus() : float
	{
		return GetBonusAdrenaline() / thePlayer.GetStatMax(BCS_Focus);
	}

	public function GetStacks() : int
	{
		return RoundMath(GetExpirationBonus() * 100);
	}

	public function GetMaxStacks() : int
	{
		return 100;
	}
}

// The share of a potion's time that passes: 1, or less with Prolongation's bonus.
function GMProlongationTimeFactor() : float
{
	var prolongation : W3GMEffect_Runeword11;
	var bonus : float;

	prolongation = (W3GMEffect_Runeword11)thePlayer.GetBuff(EET_GMRuneword11);
	if(!prolongation)
		return 1;
	bonus = prolongation.GetExpirationBonus();
	if(bonus > 0)
		return 1 - bonus;
	return 1;
}

// Potion timers run slower with the bonus (legacy). 5.x body; changes marked //modSigns.
@replaceMethod(CBaseGameplayEffect)
function OnTimeUpdated(dt : float)
{
	var toxicityThreshold : float;
	var isDecoction : bool;

	isDecoction = effectType >= EET_Mutagen01 && effectType <= EET_Mutagen28;

	if( isActive && pauseCounters.Size() == 0)
	{
		timeActive += dt;
		if( duration != -1 )
		{
			if(isPotionEffect && !((W3Mutagen_Effect)this) && isOnPlayer && effectType != EET_WhiteRaffardDecoction)	//modSigns: ENCH-09, Prolongation (not decoctions or White Raffard)
				timeLeft -= dt * GMProlongationTimeFactor();	//modSigns
			else	//modSigns
				timeLeft -= dt;
			if( timeLeft <= 0 )
			{
				if(isPotionEffect && isOnPlayer && thePlayer.CanUseSkill(S_Alchemy_s03) && effectType != EET_WhiteRaffardDecoction && !isDecoction )
				{
					isActive = false;


				}
				else
				{
					isActive = false;
				}
			}
		}
		OnUpdate(dt);
	}
}

// Tawny Owl's own timer, the same, with legacy's night hours (ALCH-07). 5.x body; changes marked //modSigns.
@replaceMethod(W3Potion_TawnyOwl)
function OnTimeUpdated(deltaTime : float)
{
	var currentHour, level : int;
	var toxicityThreshold : float;

	if( isActive && pauseCounters.Size() == 0)
	{
		timeActive += deltaTime;
		if( duration != -1 )
		{

			level = GetBuffLevel();
			currentHour = GameTimeHours(theGame.GetGameTime());
			if(level < 3 || (currentHour >= GetHourForDayPart(EDP_Dawn) && currentHour < GetHourForDayPart(EDP_Dusk)) )	//modSigns: ALCH-07, legacy's night: before dawn or from dusk on (5.x froze it during the dawn hour too)
				timeLeft -= deltaTime * GMProlongationTimeFactor();	//modSigns: ENCH-09, Prolongation

			if( timeLeft <= 0 )
			{
				if ( thePlayer.CanUseSkill(S_Alchemy_s03) )
				{
					toxicityThreshold = thePlayer.GetStatMax(BCS_Toxicity);
					toxicityThreshold *= GetWitcherPlayer().GetAlchemyS03Threshold();
				}
				isActive = false;

			}
		}
		OnUpdate(deltaTime);
	}
}

// Legacy removes the bonus when Runeword 1's ability (Replenishment) is removed, not Runeword 11's (a
// legacy quirk, kept).
@wrapMethod(W3AbilityManager)
function OnAbilityRemoved( abilityName : name )
{
	wrappedMethod(abilityName);
	if( abilityName == 'Runeword 1 _Stats' )
		thePlayer.RemoveBuff(EET_GMRuneword11);
}

// Leaving combat ends the bonus.
@wrapMethod(W3PlayerWitcher)
function OnCombatFinished()
{
	wrappedMethod();
	RemoveBuff(EET_GMRuneword11);
}

// The effect does not survive a load.
@wrapMethod(W3PlayerWitcher)
function OnSpawned(spawnData : SEntitySpawnData)
{
	wrappedMethod(spawnData);
	RemoveBuff(EET_GMRuneword11);
}

// For the tests: the current bonus, 0 without the effect.
@addMethod(W3PlayerWitcher)
function GMProlongationBonus() : float
{
	return 1 - GMProlongationTimeFactor();
}
