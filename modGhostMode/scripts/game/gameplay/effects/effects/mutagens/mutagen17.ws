/***********************************************************************/
/** 	© 2015 CD PROJEKT S.A. All rights reserved.
/** 	THE WITCHER® is a trademark of CD PROJEKT S. A.
/** 	The Witcher game is based on the prose of Andrzej Sapkowski.
/***********************************************************************/



class W3Mutagen17_Effect extends W3Mutagen_Effect
{
	default effectType = EET_Mutagen17;
	default dontAddAbilityOnTarget = true;
	
	public function ManageMutagen17Bonus(attackAction : W3Action_Attack)
	{
		if(target == thePlayer && thePlayer.IsInCombat() && thePlayer.IsThreatened())
		{
			if(attackAction.DealsAnyDamage() && attackAction.IsActionMelee()
				&& !thePlayer.GetInventory().IsItemFists(attackAction.GetWeaponId()))
			{
				AddMutagen17Ability();
			}
			//removing abilities in combat is done in sign entities after casting a sign
		}
		else
		{
			RemoveMutagen17Abilities();
		}
	}
	
	public function RemoveMutagen17Abilities()
	{
		thePlayer.RemoveAbilityAll(abilityName);
		//theGame.witcherLog.AddMessage("Mutagen17 ability removed");
	}
	
	private function AddMutagen17Ability()
	{
		var abilityCount, maxStack : float;
		var min, max : SAbilityAttributeValue;
		
		//theGame.witcherLog.AddMessage("Mutagen17 ability = " + abilityName);
		
		if(target == thePlayer && thePlayer.IsInCombat() && thePlayer.IsThreatened())
		{
			theGame.GetDefinitionsManager().GetAbilityAttributeValue(abilityName, 'mutagen17_max_stack', min, max);
			maxStack = CalculateAttributeValue(GetAttributeRandomizedValue(min, max));
			abilityCount = thePlayer.GetAbilityCount(abilityName);
			
			if(abilityCount < maxStack)
			{
				thePlayer.AddAbility(abilityName, true);
				//theGame.witcherLog.AddMessage("Mutagen17 ability added");
			}
		}
	}
	
	var spBonus : float; default spBonus = -1;
	function GetSPBonus() : float
	{
		var min, max : SAbilityAttributeValue;
		
		if(spBonus < 0)
		{
			theGame.GetDefinitionsManager().GetAbilityAttributeValue(abilityName, 'spell_power', min, max);
			spBonus = min.valueMultiplicative;
		}
		return spBonus;
	}
	
	public final function GetStacks() : int
	{
		return RoundMath( GetSPBonus() * 100 * thePlayer.GetAbilityCount(abilityName) );
	}
	
	event OnEffectRemoved()
	{
		super.OnEffectRemoved();
		
		target.RemoveAbilityAll(abilityName);
	}
	
	/*private var hasBoost, isAvailable : bool; //modSigns
	
	//modSigns: change the way the bonus is added and cleared
	event OnUpdate(dt : float)
	{
		var cnt : int;
		
		super.OnUpdate(dt);
		
		if(!hasBoost && !isAvailable) //modSigns
		{
			cnt = 0;
			
			if(FactsQuerySum("ach_counter") > 0)	cnt += 1;
			if(FactsQuerySum("ach_attack") > 0)		cnt += 1;
			if(FactsQuerySum("ach_sign") > 0)		cnt += 1;
			if(FactsQuerySum("ach_bomb") > 0)		cnt += 1;
			if(FactsQuerySum("ach_crossbow") > 0)	cnt += 1;
			
			if(cnt >= 3)
			{
				//target.AddAbility(abilityName, false);
				//hasBoost = true;
				isAvailable = true;
				//theGame.witcherLog.AddMessage("mutagen17 boost available"); //modSigns: debug
			}
		}
	}
	
	public function IsBoostAvailable() : bool //modSigns
	{
		return isAvailable;
	}
	
	public function ActivateBoost() //modSigns
	{
		isAvailable = false;
		hasBoost = true;
		target.AddAbility(abilityName, false);
	}
	
	public function HasBoost() : bool
	{
		return hasBoost;
	}
	
	public function OnLoad(t : CActor, eff : W3EffectManager)
	{
		super.OnLoad(t, eff);
		//target.RemoveAbility(abilityName);	
		ClearBoost(); //modSigns
	}
	
	public function ClearBoost()
	{
		isAvailable = false; //modSigns
		hasBoost = false;
		target.RemoveAbility(abilityName);
	}*/
}