/***********************************************************************/
/** 	© 2015 CD PROJEKT S.A. All rights reserved.
/** 	THE WITCHER® is a trademark of CD PROJEKT S. A.
/** 	The Witcher game is based on the prose of Andrzej Sapkowski.
/***********************************************************************/



class W3Mutagen16_Effect extends W3Mutagen_Effect
{
	default effectType = EET_Mutagen16;
	
	//modSigns
	var healthPrc : float;
	
	public function Mutagen16ModifyHitAnim(out action : W3DamageAction)
	{
		if(action.IsDoTDamage())
			return;
		
		//lazy
		if(healthPrc <= 0)
		{
			healthPrc = CalculateAttributeValue(thePlayer.GetAbilityAttributeValue('Mutagen16Effect', 'mutagen16_health_prc'));
			//theGame.witcherLog.AddMessage("Mutagen16: healthPrc = " + healthPrc);
		}
		
		//theGame.witcherLog.AddMessage("Mutagen16: damage = " + action.GetDamageDealt());
		
		if(action.GetDamageDealt() <= healthPrc * target.GetMaxHealth())
		{
			action.SetHitAnimationPlayType(EAHA_ForceNo);
			//theGame.witcherLog.AddMessage("Mutagen16: no hit anim");
		}
	}
	
	/*event OnEffectAddedPost()
	{
		super.OnEffectAddedPost();
		
		UpdateEncumbrance();
	}
	
	event OnEffectRemoved()
	{	
		super.OnEffectRemoved();
		
		
		UpdateEncumbrance();
	}	
	
	private final function UpdateEncumbrance()
	{
		var invMenu : CR4InventoryMenu;
		
		if(isOnPlayer)
		{
			GetWitcherPlayer().UpdateEncumbrance();
			invMenu = (CR4InventoryMenu) ((CR4MenuBase)theGame.GetGuiManager().GetRootMenu()).GetLastChild();
			if(invMenu)
				invMenu.UpdateEncumbranceInfo();
		}
	}*/
}