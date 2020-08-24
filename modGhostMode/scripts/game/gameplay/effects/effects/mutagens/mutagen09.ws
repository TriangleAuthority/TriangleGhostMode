/***********************************************************************/
/** 	© 2015 CD PROJEKT S.A. All rights reserved.
/** 	THE WITCHER® is a trademark of CD PROJEKT S. A.
/** 	The Witcher game is based on the prose of Andrzej Sapkowski.
/***********************************************************************/



class W3Mutagen09_Effect extends W3Mutagen_Effect
{
	default effectType = EET_Mutagen09;
	//default dontAddAbilityOnTarget = true;
	
	//modSigns
	
	private saved var m09Bonus : float;
	
	public function GetM09Bonus() : float
	{
		return m09Bonus;
	}
	
	public function RecalcM09Bonus()
	{
		var mutagenSlots : array<SMutagenSlot>;
		var i : int;
		var item : SItemUniqueId;
		var mutagensCount : array<int>;
		var inv : CInventoryComponent;
		var abilities : array<name>;
		var abl : SAbilityAttributeValue;
		
		mutagenSlots = GetWitcherPlayer().GetPlayerSkillMutagens();
		inv = GetWitcherPlayer().GetInventory();
		
		mutagensCount.Resize(3);
		m09Bonus = 0;
		
		for(i = 0; i < mutagenSlots.Size(); i += 1)
		{
			item = mutagenSlots[i].item;
			if(item != GetInvalidUniqueId())
			{
				abilities.Clear();
				inv.GetItemAbilities(item, abilities);
				//theGame.witcherLog.AddMessage("Mutagen09: item = " + inv.GetItemName(item));
				if(abilities.Contains('greater_mutagen_color_blue'))
					mutagensCount[2] += 1;
				else if(abilities.Contains('mutagen_color_blue'))
					mutagensCount[1] += 1;
				else if(abilities.Contains('lesser_mutagen_color_blue'))
					mutagensCount[0] += 1;
			}
		}
		
		abl = thePlayer.GetAbilityAttributeValue(abilityName, 'mutagen09_bonus_lesser');
		//theGame.witcherLog.AddMessage("Mutagen09: bonus_lesser = " + abl.valueAdditive);
		m09Bonus += abl.valueAdditive * mutagensCount[0];
		abl = thePlayer.GetAbilityAttributeValue(abilityName, 'mutagen09_bonus_medium');
		//theGame.witcherLog.AddMessage("Mutagen09: bonus_medium = " + abl.valueAdditive);
		m09Bonus += abl.valueAdditive * mutagensCount[1];
		abl = thePlayer.GetAbilityAttributeValue(abilityName, 'mutagen09_bonus_greater');
		//theGame.witcherLog.AddMessage("Mutagen09: bonus_greater = " + abl.valueAdditive);
		m09Bonus += abl.valueAdditive * mutagensCount[2];
		
		//theGame.witcherLog.AddMessage("Mutagen09: m09Bonus = " + m09Bonus);
	}
	
	event OnEffectAdded(optional customParams : W3BuffCustomParams)
	{
		super.OnEffectAdded(customParams);
		
		RecalcM09Bonus();
	}
	
	//modSigns: changed
	/*private var hasAbility : bool;
	
	event OnUpdate(dt : float)
	{
		super.OnUpdate(dt);
		
		//modSigns: fix weather condition
		if(GetCurWeather() != EWE_Rain && GetCurWeather() != EWE_Snow && GetCurWeather() != EWE_Storm)
		{
			if(hasAbility)
			{
				target.RemoveAbility(abilityName);
				hasAbility = false;
			}
		}
		else
		{
			if(!hasAbility)
			{
				target.AddAbility(abilityName, false);
				hasAbility = true;
			}
		}
	}
	
	public function OnLoad(t : CActor, eff : W3EffectManager)
	{
		super.OnLoad(t, eff);
		hasAbility = target.HasAbility(abilityName);
	}*/
}