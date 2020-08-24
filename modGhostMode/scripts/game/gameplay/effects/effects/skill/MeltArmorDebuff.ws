//modSigns
class W3Effect_MeltArmorDebuff extends CBaseGameplayEffect
{
	default effectType = EET_MeltArmorDebuff;
	default isNegative = true;
	default dontAddAbilityOnTarget = true;
	
	//var timestamp : float; //seconds
	//default timestamp = -1;
	
	function RemoveAbilities()
	{
		target.RemoveAbilityAll(abilityName);
		thePlayer.RemoveAllBuffsOfType(EET_MeltArmorTimer);
	}
	
	function AddAbilities()
	{
		var creatorSkillLevel : int;
		var debuffRate : int;
		var dt : float;

		debuffRate = thePlayer.GetSkillLevel(S_Magic_s08) * RoundMath(1 + 7.0*SignPowerStatToPowerBonus(creatorPowerStat.valueMultiplicative));
		//if(sourceName == "alt_cast" && timestamp >= 0)
		//{
		//	dt = theGame.GetEngineTimeAsSeconds() - timestamp;
		//	debuffRate = RoundMath(debuffRate * dt);
		//}
		if(debuffRate > 0)
		{
			target.AddAbilityMultiple(abilityName, debuffRate);
			//timestamp = theGame.GetEngineTimeAsSeconds();
			thePlayer.AddEffectDefault(EET_MeltArmorTimer, NULL, "");
			//theGame.witcherLog.AddMessage("MeltArmorDebuff: debuffRate = " + debuffRate);
		}
	}
	
	event OnEffectRemoved()
	{
		super.OnEffectRemoved();
		RemoveAbilities();
		//theGame.witcherLog.AddMessage("MeltArmorDebuff removed");
	}
		
	event OnEffectAdded(optional customParams : W3BuffCustomParams)
	{
		if(GetCreator() != GetWitcherPlayer())
		{
			isActive = false;
			return false;
		}
		
		super.OnEffectAdded(customParams);
		AddAbilities();
		//theGame.witcherLog.AddMessage("MeltArmorDebuff added. Duration = " + duration);
	}
	
	protected function GetSelfInteraction(e : CBaseGameplayEffect) : EEffectInteract
	{
		return EI_Cumulate;
	}
	
	public function CumulateWith(effect: CBaseGameplayEffect)
	{
		//for some reason EI_Deny is not working properly, so just making it do nothing on cumulate
		//timeLeft = effect.timeLeft;
		//duration = effect.duration;
		//sourceName = effect.sourceName;
		//AddAbilities();
		//theGame.witcherLog.AddMessage("MeltArmorDebuff cumulated");
	}
}
