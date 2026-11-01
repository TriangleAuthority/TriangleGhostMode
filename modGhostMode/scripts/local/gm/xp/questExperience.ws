// XP-01: quest experience by level (docs/features/xp.md; legacy's CR4Game.OnGiveReward, PX4).
//
// A reward's experience follows the reward's level against Geralt's: 1 + 0.16 per level the quest is above him
// (LEVEL_DIFF_XP_MOD), clamped to 0 .. 1.5 (MAX_XP_MOD), at least 5 XP. Every quest alike (no Hearts of Stone special
// case), on every mode (DIFF-08), and no halving once the main story is finished. In NG+ Geralt's level counts without
// the NG+ levels (reward levels are the base game's). The rest of 5.x's body is kept (its AddAnItem flag included).
//
// XP-07's options are read through GMXpNoQuestLevels, GMXpFixedExp and GMXpQuestExpModifier (xp/expOptions.ws).
@replaceMethod(CR4Game)
function OnGiveReward( target : CEntity, rewardName : name, rewrd : SReward )
{
	var i 						: int;
	var itemCount				: int;
	var gameplayEntity 			: CGameplayEntity;
	var inv		 				: CInventoryComponent;
	var goldMultiplier			: float;
	var itemMultiplier			: float;
	var itemsCount				: int;
	var ids						: array<SItemUniqueId>;
	var itemCategory 			: name;
	var lvlDiff					: int;
	var moneyWon				: int;
	var expModifier				: float;
	//modSigns: removed difficultyMode, rewardNameS, ep1Content
	var rewardMultData			: SRewardMultiplier;
	var expPoints				: int;	//modSigns

	if ( target == thePlayer )
	{
		
		if ( rewrd.experience > 0 && GetWitcherPlayer())
		{
			//modSigns: removed 5.x's rule (Hearts of Stone's level scaling, the post-story halving, the difficulty multipliers, 5% from LEVEL_DIFF_HIGH below)
			expPoints = GMQuestExperience(rewrd.experience, rewrd.level, thePlayer.GetLevel());	//modSigns
			GetWitcherPlayer().AddPoints(EExperiencePoint, expPoints, true);	//modSigns
		}

		if ( rewrd.achievement > 0 )
		{
			theGame.GetGamerProfile().AddAchievement( rewrd.achievement );
		}
	}

	gameplayEntity = (CGameplayEntity)target;
	if ( gameplayEntity )
	{
		inv = gameplayEntity.GetInventory();
		if ( inv )
		{
			rewardMultData = thePlayer.GetRewardMultiplierData( rewardName );

			if( rewardMultData.isItemMultiplier )
			{
				goldMultiplier = 1.0;
				itemMultiplier = rewardMultData.rewardMultiplier;
			}
			else
			{
				goldMultiplier = rewardMultData.rewardMultiplier;
				itemMultiplier = 1.0;
			}

			
			if ( rewrd.gold > 0 )
			{
				inv.AddMoney( (int)(rewrd.gold * goldMultiplier) );
				thePlayer.RemoveRewardMultiplier(rewardName);
				if( target == thePlayer )
				{
					moneyWon = (int)(rewrd.gold * goldMultiplier);

					if ( moneyWon > 0 )
						thePlayer.DisplayItemRewardNotification('Crowns', moneyWon );
				}
			}

			

			for ( i = 0; i < rewrd.items.Size(); i += 1 )
			{
				itemsCount = RoundF( rewrd.items[ i ].amount * itemMultiplier );

				if( itemsCount > 0 )
				{
					ids = inv.AddAnItem( rewrd.items[ i ].item, itemsCount, true );

					for ( itemCount = 0; itemCount < ids.Size(); itemCount += 1 )
					{
						
						if ( inv.ItemHasTag( ids[i], 'Autogen' ) && GetWitcherPlayer().GetLevel() - 1 > 1 )
						{
							inv.GenerateItemLevel( ids[i], true );
						}
					}

					itemCategory = inv.GetItemCategory( ids[0] );
					if ( itemCategory == 'alchemy_recipe' ||  itemCategory == 'crafting_schematic' )
					{
						inv.ReadSchematicsAndRecipes( ids[0] );
					}

					if(target == thePlayer)
					{
						
						if( !inv.ItemHasTag( ids[0], 'GwintCard') )
						{
							thePlayer.DisplayItemRewardNotification(rewrd.items[ i ].item, RoundF( rewrd.items[ i ].amount * itemMultiplier ) );
						}
					}
				}
			}
		}
	}
}

// XP-01: legacy's quest experience (OnGiveReward's experience block, in a function of its own so that tests can
// compare it with what a reward gives). `playerLevel` is Geralt's level as the game reads it; NG+'s levels are taken
// off here, as legacy does.
function GMQuestExperience(experience : int, level : int, playerLevel : int) : int
{
	var expModifier : float;
	var rewardLevel, lvlDiff, expPoints : int;

	expModifier = 1.f;	// start with 100%
	if(FactsQuerySum("NewGamePlus") > 0)	// reward levels are the base game's
		playerLevel -= theGame.params.GetNewGamePlusLevel();
	if(GMXpNoQuestLevels())	// XP-07 "Disable quest levels"
		rewardLevel = 0;
	else
		rewardLevel = level;
	if(!GMXpFixedExp() && rewardLevel > 0)	// XP-07 "Fixed experience for quests and combat"
	{
		lvlDiff = rewardLevel - playerLevel;	// negative for lower-level quests, positive for higher-level ones
		expModifier += lvlDiff * theGame.params.LEVEL_DIFF_XP_MOD;
		expModifier = ClampF(expModifier, 0, theGame.params.MAX_XP_MOD);	// 0% min, 150% max
	}
	expPoints = RoundMath(experience * theGame.expGlobalMod_quests * expModifier);
	expPoints = Max(5, expPoints);	// always at least 5
	if(GMXpQuestExpModifier() != 0)	// XP-07 "Quest experience modifier", after the minimum
		expPoints = RoundMath(expPoints * (1 + GMXpQuestExpModifier()));
	return expPoints;
}
