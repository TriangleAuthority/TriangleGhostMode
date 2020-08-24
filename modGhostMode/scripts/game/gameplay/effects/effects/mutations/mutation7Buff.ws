/***********************************************************************/
/** 	© 2015 CD PROJEKT S.A. All rights reserved.
/** 	THE WITCHER® is a trademark of CD PROJEKT S. A.
/** 	The Witcher game is based on the prose of Andrzej Sapkowski.
/***********************************************************************/
class W3Effect_Mutation7Buff extends W3Mutation7BaseEffect
{
	default effectType = EET_Mutation7Buff;
	default isPositive = true;
	//default isSonarIncreasing = false;
	//default enemyFlashFX = 'debuff';
	
	private var accumulatedFocusPts : int; //modSigns
	
	event OnEffectAdded( customParams : W3BuffCustomParams )
	{
		var fxEntity : CEntity;
		
		super.OnEffectAdded( customParams );
		
		//target.AddAbilityMultiple( 'Mutation7Buff', actorsCount - 1 );
		//modSigns
		accumulatedFocusPts = 0;
		savedFocusPts = FloorF(target.GetStat(BCS_Focus));
		target.AddAbilityMultiple( 'Mutation7Buff', savedFocusPts );
		
		fxEntity = target.CreateFXEntityAtPelvis( 'mutation7_flash', false );
		fxEntity.PlayEffect( 'buff' );
		fxEntity.DestroyAfter( 10.f );
		target.PlayEffect( 'mutation_7_baff' );				
		target.SoundEvent( 'ep2_mutations_07_berserk_buff' );
	}
	
	event OnUpdate(deltaTime : float)
	{
		//modSigns
		var curFocus : int = FloorF(target.GetStat(BCS_Focus));
		
		if(curFocus < savedFocusPts)
			target.RemoveAbilityMultiple( 'Mutation7Buff', savedFocusPts - curFocus );
		else if(curFocus > savedFocusPts)
		{
			target.AddAbilityMultiple( 'Mutation7Buff', curFocus - savedFocusPts );
			accumulatedFocusPts += curFocus - savedFocusPts;
		}
		savedFocusPts = curFocus;
	
		//var fxEntity : CEntity;
		//
		//if( timeActive <= 1.f )
		//{
		//	scale = MinF( timeActive / 1.f, 1.f );
		//	scale = 15.f - 14.f * scale;
		//}
		//else
		//{
		//	if( sonarEntity )
		//	{
		//		fxEntity = target.CreateFXEntityAtPelvis( 'mutation7_flash', false );
		//		fxEntity.PlayEffect( 'buff' );
		//		fxEntity.DestroyAfter( 10.f );
		//		
		//		target.PlayEffect( 'mutation_7_baff' );				
		//	}
		//}
		//
		//super.OnUpdate( deltaTime );
	}
	
	event OnEffectAddedPost()
	{
		var min, max : SAbilityAttributeValue;
		
		super.OnEffectAddedPost();
		
		//theGame.MutationHUDFeedback( MFT_PlayRepeat );
		
		theGame.GetDefinitionsManager().GetAbilityAttributeValue( 'Mutation7Buff', 'attack_power', min, max );
		apBonus = min.valueMultiplicative;
	}
	
	event OnEffectRemoved()
	{
		//var tempBuff		: W3Effect_Mutation7Debuff;
		var params 			: SCustomEffectParams;
		var mut7Params 		: W3Mutation7DebuffParams;
	
		target.RemoveAbilityAll( 'Mutation7Buff' );
		target.StopEffect( 'mutation_7_baff' );
		
		if( target.IsInCombat() )
		{
			mut7Params = new W3Mutation7DebuffParams in theGame;
			mut7Params.savedFocusPts = accumulatedFocusPts; //modSigns
			
			params.buffSpecificParams = mut7Params;
			params.creator = target;
			params.effectType = EET_Mutation7Debuff;
			params.sourceName = "Mutation 7 debuff phase"; //modSigns
			target.AddEffectCustom( params );
		}
		
		super.OnEffectRemoved();		
	}
}