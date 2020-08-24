/***********************************************************************/
/** 	© 2015 CD PROJEKT S.A. All rights reserved.
/** 	THE WITCHER® is a trademark of CD PROJEKT S. A.
/** 	The Witcher game is based on the prose of Andrzej Sapkowski.
/***********************************************************************/



class W3Effect_SilverDust extends CBaseGameplayEffect
{
	default isPositive = false;
	default isNeutral = false;
	default isNegative = true;
	default effectType = EET_SilverDust;
	
	event OnEffectAdded(optional customParams : W3BuffCustomParams)
	{
		if(target == thePlayer) //modSigns
		{
			target.RemoveBuff(EET_SilverDust);
		}
	
		super.OnEffectAdded(customParams);
		
		
		target.PauseEffects(EET_AutoEssenceRegen, 'silver_dust');
		
		BlockAbilities(true);
	}
	
	event OnEffectRemoved()
	{	
		
		target.ResumeEffects(EET_AutoEssenceRegen, 'silver_dust');
		
		BlockAbilities(false);
		
		super.OnEffectRemoved();
	}
	
	private final function BlockAbilities(block : bool)
	{
		var ret : bool;
		
		//modSigns begin
		//regen ability
		ret = target.BlockAbility('EssenceRegen', block) || ret;
		//gravehag, waterhag, fogling, nightwraith, noonwraith
		ret = target.BlockAbility('Doppelganger', block) || ret;
		ret = target.BlockAbility('MistCharge', block) || ret;
		ret = target.BlockAbility('ShadowForm', block) || ret;
		//foglings
		ret = target.BlockAbility('MistForm', block) || ret;
		//wraiths check for Specter ability and not for Teleport/Flashstep
		//ret = target.BlockAbility('Specter', block) || ret;
		//vampires and wraiths
		ret = target.BlockAbility('Flashstep', block) || ret;
		//werewolves, leshens, berserkers, white bear, him, witches
		ret = target.BlockAbility('Shapeshifter', block) || ret;
		//leshens
		ret = target.BlockAbility('Swarms', block) || ret;
		//bruxa, alp, cloud giant
		ret = target.BlockAbility('Teleport', block) || ret;
		//werewolves
		ret = target.BlockAbility('FullMoon', block) || ret;
		//modSigns end
		
		if(block && ret)
		{
			target.PlayEffect('transformation_block');
		}
		else if(!block)
		{
			target.StopEffect('transformation_block');
		}
	}
}