/***********************************************************************/
/** 	© 2015 CD PROJEKT S.A. All rights reserved.
/** 	THE WITCHER® is a trademark of CD PROJEKT S. A.
/** 	The Witcher game is based on the prose of Andrzej Sapkowski.
/***********************************************************************/




class W3Mutagen23_Effect extends W3Mutagen_Effect
{
	default effectType = EET_Mutagen23;
	default dontAddAbilityOnTarget = true;
	
	//modSigns
	
	public function AddM23Abilities()
	{
		var mutagenSlots : array<SMutagenSlot>;
		var i : int;
		var item : SItemUniqueId;
		var mutagensCount : int;
		var inv : CInventoryComponent;
		var abilities : array<name>;
		var numAbls : int;
	
		mutagenSlots = GetWitcherPlayer().GetPlayerSkillMutagens();
		inv = GetWitcherPlayer().GetInventory();
		
		for(i = 0; i < mutagenSlots.Size(); i += 1)
		{
			item = mutagenSlots[i].item;
			if(item != GetInvalidUniqueId())
			{
				abilities.Clear();
				inv.GetItemAbilities(item, abilities);
				//theGame.witcherLog.AddMessage("Mutagen23: item = " + inv.GetItemName(item));
				if(abilities.Contains('greater_mutagen_color_green'))
					mutagensCount += 4;
				else if(abilities.Contains('mutagen_color_green'))
					mutagensCount += 2;
				else if(abilities.Contains('lesser_mutagen_color_green'))
					mutagensCount += 1;
			}
		}
		
		numAbls = target.GetAbilityCount(abilityName);
		
		//theGame.witcherLog.AddMessage("Mutagen23: mutagensCount = " + mutagensCount);
		//theGame.witcherLog.AddMessage("Mutagen23: numAbls = " + numAbls);
		
		if(mutagensCount > numAbls)
		{
			target.AddAbilityMultiple(abilityName, mutagensCount - numAbls);
		}
		else if(mutagensCount < numAbls)
		{
			target.RemoveAbilityMultiple(abilityName, numAbls - mutagensCount);
		}
	}
	
	event OnEffectAdded(optional customParams : W3BuffCustomParams)
	{
		super.OnEffectAdded(customParams);
		
		AddM23Abilities();
	}
	
	event OnEffectRemoved()
	{
		super.OnEffectRemoved();
		
		target.RemoveAbilityAll(abilityName);
	}
	
	/*event OnUpdate(dt : float)
	{
		var currentHour, currentMinutes, i : int;
		var gameTime : GameTime;
		var params : SCustomEffectParams;
		var shrineBuffs : array<EEffectType>;
		var addBuff : bool;
		var shrineParams : W3ShrineEffectParams;
		
		super.OnUpdate(dt);
		
		if(effectManager.HasAnyMutagen23ShrineBuff())
			return true;
		
		
		if( target == GetWitcherPlayer() && GetWitcherPlayer().CanUseSkill( S_Perk_14 ) && effectManager.HasAnyShrineBuff() )
		{
			return true;
		}
		
		gameTime = theGame.GetGameTime();
		currentHour = GameTimeHours(gameTime);
		currentMinutes = GameTimeMinutes(gameTime);	

		if( (currentHour == GetHourForDayPart(EDP_Dawn) && currentMinutes < 15) || ( (currentHour == (GetHourForDayPart(EDP_Dawn) - 1)) && currentMinutes > 45) )
		{
			addBuff = true;
		}
		else
		{
			if( (currentHour == GetHourForDayPart(EDP_Dusk) && currentMinutes < 15) || ( ( currentHour == (GetHourForDayPart(EDP_Dusk) - 1)) && currentMinutes > 45) )
				addBuff = true;
			else
				addBuff = false;
		}
		
		if(addBuff)
		{			
			shrineBuffs = GetMinorShrineBuffs();
			
			
			for(i=shrineBuffs.Size()-1; i>=0; i-=1)
			{
				if(target.HasBuff(shrineBuffs[i]))
					shrineBuffs.Erase(i);
			}
			
			
			if(shrineBuffs.Size() == 0)
				shrineBuffs = GetMinorShrineBuffs();
			
			params.effectType = shrineBuffs[ RandRange(shrineBuffs.Size()) ];
			params.sourceName = 'Mutagen23';
			params.duration = ConvertGameSecondsToRealTimeSeconds(60 * 60 * 6);
			shrineParams = new W3ShrineEffectParams in theGame;
			shrineParams.isFromMutagen23 = true;
			params.buffSpecificParams = shrineParams;
			
			target.AddEffectCustom(params);
			
			delete shrineParams;
		}
	}*/
}
