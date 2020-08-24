/***********************************************************************/
/** 	© 2015 CD PROJEKT S.A. All rights reserved.
/** 	THE WITCHER® is a trademark of CD PROJEKT S. A.
/** 	The Witcher game is based on the prose of Andrzej Sapkowski.
/***********************************************************************/



abstract class W3RepairObjectEnhancement extends CBaseGameplayEffect
{
	protected var usesPerkBonus : bool;
	//protected var durUpdates : bool; //modSigns
	
	default isPositive = true;
	default isNeutral = false;
	default isNegative = false;
	default usesPerkBonus = false;
	
	public function OnTimeUpdated(dt : float)
	{
		var hasRuneword5 : bool;
		
		
		if(isOnPlayer)
			hasRuneword5 = GetWitcherPlayer().HasRunewordActive('Runeword 5 _Stats');
		else
			hasRuneword5 = false;
		
		if(hasRuneword5)
		{
			if( isActive && pauseCounters.Size() == 0)
			{
				timeActive += dt;	
				timeLeft -= dt; //modSigns
			}
			
			//timeLeft = 0.f; //modSigns
			//durUpdates = false; //modSigns
			//return; //modSigns
		}
		else //if(!durUpdates) //modSigns
		{
			//timeLeft = duration - timeActive; //modSigns
			//durUpdates = true; //modSigns
			super.OnTimeUpdated(dt);
		}
		
		//super.OnTimeUpdated(dt); //modSigns
	}
	
	//modSigns
	event OnEffectRemoved()
	{
		super.OnEffectRemoved();
		if(isOnPlayer && GetWitcherPlayer().HasRunewordActive('Runeword 5 _Stats'))
			thePlayer.AddEffectDefault(effectType, GetCreator(), sourceName);
	}
}