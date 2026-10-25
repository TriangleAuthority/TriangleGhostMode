// FOOD-05: alcohol and raw food cost toxicity (the items' alco_toxicity, alco_toxicity_strong and
// food_toxicity: 5, 10 and 5; raw food is tagged Uncooked), and Geralt refuses them, from the quick slot
// (alchemy/potionRules.ws, DrinkPotionFromSlot) and from the inventory, when he has too little free
// toxicity for them; alcohol makes him drunk (60 s, DrunkennessEffect in gm_food.xml). Connoisseur
// (FOOD-06) removes the toxicity and the drunkenness. An alcohol's effects carry the buff source
// "alcohol", which Connoisseur's longer duration reads.
// See docs/features/food.md.

// Whether Connoisseur is equipped (classic perk_15, new tree perk_41: FOOD-06).
@addMethod(W3PlayerWitcher)
function GMHasConnoisseur() : bool
{
	return CanUseSkill(S_Perk_15) || CanUseSkill(S_Perk_41);
}

// Alcohol or raw food that Geralt cannot take now: it would cost toxicity he does not have free.
@addMethod(W3PlayerWitcher)
function GMFoodTooToxic(item : SItemUniqueId) : bool
{
	if(!inv.IsIdValid(item) || GMHasConnoisseur())
		return false;
	if(!inv.ItemHasTag(item, 'Alcohol') && !inv.ItemHasTag(item, 'Uncooked'))
		return false;
	return !ToxicityLowEnoughToDrinkPotion(EES_Potion1, item);
}

// 5.x body; changes marked //modSigns.
@replaceMethod(CR4Player)
function ConsumeItem( itemId : SItemUniqueId ) : bool
{
	var params : SCustomEffectParams;
	var buffs : array<SEffectInfo>;
	var i : int;
	var category : name;
	var potionToxicity : float;
	var gmWitcher : W3PlayerWitcher;	//modSigns
	
	if(!inv.IsIdValid(itemId))
		return false;
	
	
	category = inv.GetItemCategory(itemId);
	if(category == 'edibles' || inv.ItemHasTag(itemId, 'Drinks') || ( category == 'alchemy_ingredient' && inv.ItemHasTag(itemId, 'Alcohol')) )
	{
		
		if(IsFistFightMinigameEnabled() || IsDiving())
		{
			DisplayActionDisallowedHudMessage(EIAB_Undefined, false, false, true);
			return false;
		}
	
		
		inv.GetItemBuffs(itemId, buffs);
		
		for(i=0; i<buffs.Size(); i+=1)
		{
			params.effectType = buffs[i].effectType;
			params.creator = this;
			if(inv.ItemHasTag(itemId, 'Alcohol'))	//modSigns: FOOD-06, an alcohol's effects are told apart (Connoisseur)
				params.sourceName = "alcohol";	//modSigns
			else	//modSigns
			params.sourceName = "edible";
			params.customAbilityName = buffs[i].effectAbilityName;
			AddEffectCustom(params);
		}
		
		gmWitcher = (W3PlayerWitcher)this;	//modSigns
		
		if ( ( inv.ItemHasTag(itemId, 'Alcohol') || inv.ItemHasTag(itemId, 'Uncooked') ) && !( gmWitcher && gmWitcher.GMHasConnoisseur() ) )	//modSigns: FOOD-05, raw food costs toxicity too; none with Connoisseur
		{
			potionToxicity = CalculateAttributeValue(inv.GetItemAttributeValue(itemId, 'toxicity'));
			abilityManager.GainStat(BCS_Toxicity, potionToxicity );				
			if ( inv.ItemHasTag(itemId, 'Alcohol') )	//modSigns: FOOD-05, raw food does not make Geralt drunk
			AddEffectDefault(EET_Drunkenness, NULL, inv.GetItemName(itemId));
		}
		else if ( CanUseSkill( S_Perk_29 ) ) 
		{
			params.effectType = EET_CatPerk29;
			params.creator = this;
			params.sourceName = "edible";
			params.customAbilityName = 'CatEffectPerk29';
			params.duration = GetSkillLevel( S_Perk_29 ) * CalculateAttributeValue( GetSkillAttributeValue( S_Perk_29, 'duration', false, false ) );
			AddEffectCustom(params);
		}


		PlayItemConsumeSound( itemId );
	}
	
	if(inv.IsItemFood(itemId))
		FactsAdd("consumed_food_cnt");
	
	
	if(!inv.ItemHasTag(itemId, theGame.params.TAG_INFINITE_USE) && !inv.RemoveItem(itemId))
	{
		LogAssert(false,"Failed to remove consumable item from player inventory!" + inv.GetItemName( itemId ) );
		return false;
	}
	
	return true;
}

// The inventory's "use" refuses alcohol and raw food when Geralt is too toxic (legacy's message, with his
// current toxicity), as for potions.
@wrapMethod(W3InventoryItemContext)
function HandleUserFeedback(keyName : string)
{
	var witcher : W3PlayerWitcher;
	var useKey : bool;
	var text, language, audioLanguage : string;

	witcher = GetWitcherPlayer();
	if(theGame.GetPlatform() == Platform_Switch2_Ounce)
		useKey = keyName == "gamepad_Y";
	else
		useKey = keyName == "gamepad_X";
	if(useKey && witcher && witcher.GMFoodTooToxic(currentItemId))
	{
		text = GetLocStringByKeyExt("menu_cannot_perform_action_now") + "<br/>" + GetLocStringByKeyExt("panel_common_statistics_tooltip_current_toxicity");
		theGame.GetGameLanguageName(audioLanguage, language);
		if(language == "AR")
			text += (int)(witcher.abilityManager.GetStat(BCS_Toxicity, false)) + " / " + (int)(witcher.abilityManager.GetStatMax(BCS_Toxicity)) + " :";
		else
			text += ": " + (int)(witcher.abilityManager.GetStat(BCS_Toxicity, false)) + " / " + (int)(witcher.abilityManager.GetStatMax(BCS_Toxicity));
		theSound.SoundEvent("gui_global_denied");
		invMenuRef.showNotification(text);
		return;
	}
	wrappedMethod(keyName);
}
