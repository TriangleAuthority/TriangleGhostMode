// MUT-14: the HUD's buff list: Toxic Blood's counter (the acid's damage per second) and Euphoria's
// (the damage added per hit) show as numbers, as legacy's (5.x: percentages). Bloodbath's stays a
// percentage; Mutated Skin's damage over time is its own effect with a timer (MUT-10). Legacy's other
// HUD changes in this function (other features' counters) are not ported yet (UI); Iris's charges show
// as a counter like Aerondight's (SWD-06).
// See docs/features/mut.md.

@replaceMethod(CR4HudModuleBuffs)
function UpdateBuffs()
{
	var l_flashObject			: CScriptedFlashObject;
	var l_flashArray			: CScriptedFlashArray;
	var i 						: int;
	var oilEffect				: W3Effect_Oil;
	var aerondightEffect		: W3Effect_Aerondight;
	var buffDisplayLimit		: int = 16;
	var mut3Buff 				: W3Effect_Mutation3;
	var mut4Buff 				: W3Effect_Mutation4;
	var mut5Buff 				: W3Effect_Mutation5;
	var effectType				: EEffectType;
	var mut7Buff 				: W3Mutation7BaseEffect;
	var mut10Buff 				: W3Effect_Mutation10;
	var buffState				: int;
	var format					: int;
	var quenBuff 				: W3Effect_BasicQuen;
	
	
	var isOilInfinite : bool;

	l_flashArray = GetModuleFlashValueStorage()().CreateTempFlashArray();
	for(i = 0; i < Min(buffDisplayLimit,_currentEffects.Size()); i += 1) 
	{
		if(_currentEffects[i].ShowOnHUD() && _currentEffects[i].GetEffectNameLocalisationKey() != "MISSING_LOCALISATION_KEY_NAME" )
		{
			if(_currentEffects[i].IsNegative())
			{
				buffState = 0;
			}
			else if ( _currentEffects[i].IsPositive() )
			{
				buffState = 1;
			}
			else if ( _currentEffects[i].IsNeutral() )
			{
				buffState = 2;
			}

			effectType = _currentEffects[i].GetEffectType();

			
			if(thePlayer.IsSkillEquipped( S_Alchemy_s06 ) && GetWitcherPlayer().CanUseSkill(S_Alchemy_s06) && GetWitcherPlayer().GetSkillLevel(S_Alchemy_s06) > 2)
				isOilInfinite = true;
			
			if ( effectType == EET_Oil && isOilInfinite )
			{
				
				format = 0;
			}
			else if ( effectType == EET_Oil || effectType == EET_Aerondight || effectType == EET_GMPhantomWeapon || effectType == EET_Mutation4 || effectType == EET_Mutation10 )	//modSigns: MUT-08, MUT-09: Toxic Blood's and Euphoria's counters are damage values, not percentages; SWD-06: Iris's charges
			{
				
				format = 1;
			}
			else if ( effectType == EET_Mutation3 || effectType == EET_Mutation5 || effectType == EET_LynxSetBonus || effectType == EET_GMRuneword4 || effectType == EET_GMRuneword11 )	//modSigns: MUT-08, MUT-09: Mutation 4 and 10 moved to the counter format; ARM-06: the Feline set's bonus (legacy); ENCH-05, ENCH-09: Invigoration's and Prolongation's bonus in %
			{
				
				format = 2;
			}
			else if ( effectType == EET_Mutation7Buff || effectType == EET_Mutation7Debuff || effectType == EET_BasicQuen || effectType == EET_ConvergenceTheory || effectType == EET_Mutagen01 || effectType == EET_Mutagen05 || effectType == EET_Mutagen10 || effectType == EET_Mutagen15 || effectType == EET_Mutagen17 || effectType == EET_Mutagen22 )	//modSigns: ALCH-10, ALCH-11 (audit F13): the decoctions' stacks shown next to their timers (legacy)
			{
				
				format = 4;
			}
			else
			{
				
				format = 3;
			}				
			
			l_flashObject = m_flashValueStorage.CreateTempFlashObject();
			l_flashObject.SetMemberFlashBool("isVisible",_currentEffects[i].ShowOnHUD());
			l_flashObject.SetMemberFlashString("iconName",_currentEffects[i].GetIcon());
			l_flashObject.SetMemberFlashString("title",GetLocStringByKeyExt(_currentEffects[i].GetEffectNameLocalisationKey()));
			l_flashObject.SetMemberFlashBool("IsPotion",_currentEffects[i].IsPotionEffect());
			l_flashObject.SetMemberFlashInt("isPositive", buffState);
			l_flashObject.SetMemberFlashInt("format", format);
			
			if ( effectType == EET_Oil )
			{	
				oilEffect = (W3Effect_Oil)_currentEffects[i];
				if ( oilEffect )
				{
					
					if (oilEffect.GetAmmoCurrentCount() > 0 && isOilInfinite)
					{
						l_flashObject.SetMemberFlashNumber("duration",        oilEffect.GetAmmoMaxCount() 	  * 1.0 );
						l_flashObject.SetMemberFlashNumber("initialDuration", oilEffect.GetAmmoMaxCount() 	  * 1.0 );
						l_flashObject.SetMemberFlashInt("format", 0);
					}
					
					else
					{
						l_flashObject.SetMemberFlashNumber("duration",        oilEffect.GetAmmoCurrentCount() * 1.0 );
						l_flashObject.SetMemberFlashNumber("initialDuration", oilEffect.GetAmmoMaxCount() 	  * 1.0 );
					}
				}
			}
			else if( effectType == EET_Aerondight )
			{
				aerondightEffect = (W3Effect_Aerondight)_currentEffects[i];
				if( aerondightEffect )
				{
					l_flashObject.SetMemberFlashNumber("duration",        aerondightEffect.GetCurrentCount() * 1.0 );
					l_flashObject.SetMemberFlashNumber("initialDuration", aerondightEffect.GetMaxCount()	 * 1.0 );
				}
			}
			else if( effectType == EET_GMPhantomWeapon )	//modSigns: SWD-06, Iris's charges
			{	//modSigns
				l_flashObject.SetMemberFlashNumber("duration",        ( (W3GMEffect_PhantomWeapon)_currentEffects[i] ).GetCurrentCount() * 1.0 );	//modSigns
				l_flashObject.SetMemberFlashNumber("initialDuration", ( (W3GMEffect_PhantomWeapon)_currentEffects[i] ).GetMaxCount() * 1.0 );	//modSigns
			}	//modSigns
			
			
			else if( effectType == EET_LynxSetBonus )	//modSigns: ARM-06, the Feline set's bonus in % (legacy)
			{	//modSigns
				l_flashObject.SetMemberFlashNumber("duration", 			( ( W3Effect_LynxSetBonus ) _currentEffects[i] ).GMGetStacks() );	//modSigns
				l_flashObject.SetMemberFlashNumber("initialDuration", 	( ( W3Effect_LynxSetBonus ) _currentEffects[i] ).GMGetMaxStacks() );	//modSigns
			}	//modSigns
			else if( effectType == EET_GMRuneword4 )	//modSigns: ENCH-05, Invigoration's bonus in % (legacy)
			{	//modSigns
				l_flashObject.SetMemberFlashNumber("duration", 			( ( W3GMEffect_Runeword4 ) _currentEffects[i] ).GetStacks() );	//modSigns
				l_flashObject.SetMemberFlashNumber("initialDuration", 	( ( W3GMEffect_Runeword4 ) _currentEffects[i] ).GetMaxStacks() );	//modSigns
			}	//modSigns
			else if( effectType == EET_GMRuneword11 )	//modSigns: ENCH-09, Prolongation's bonus in % (legacy)
			{	//modSigns
				l_flashObject.SetMemberFlashNumber("duration", 			( ( W3GMEffect_Runeword11 ) _currentEffects[i] ).GetStacks() );	//modSigns
				l_flashObject.SetMemberFlashNumber("initialDuration", 	( ( W3GMEffect_Runeword11 ) _currentEffects[i] ).GetMaxStacks() );	//modSigns
			}	//modSigns
			else if( effectType == EET_Mutation3 )
			{						
				mut3Buff = ( W3Effect_Mutation3 ) _currentEffects[i];						
				l_flashObject.SetMemberFlashNumber("duration", 			mut3Buff.GetStacks() );
				l_flashObject.SetMemberFlashNumber("initialDuration", 	mut3Buff.GetStacks() );
			}
			else if( effectType == EET_Mutation4 )
			{						
				mut4Buff = ( W3Effect_Mutation4 ) _currentEffects[i];						
				l_flashObject.SetMemberFlashNumber("duration", 			mut4Buff.GetStacks() );
				l_flashObject.SetMemberFlashNumber("initialDuration", 	mut4Buff.GetStacks() );
			}
			else if( effectType == EET_Mutation5 )
			{						
				mut5Buff = ( W3Effect_Mutation5 ) _currentEffects[i];						
				l_flashObject.SetMemberFlashNumber("duration", 			mut5Buff.GetStacks() );
				l_flashObject.SetMemberFlashNumber("initialDuration", 	mut5Buff.GetStacks() );
			}
			
			
			else if( effectType == EET_Mutation10 )
			{						
				mut10Buff = ( W3Effect_Mutation10 ) _currentEffects[i];						
				l_flashObject.SetMemberFlashNumber("duration", 			mut10Buff.GetStacks() );
				l_flashObject.SetMemberFlashNumber("initialDuration", 	mut10Buff.GetStacks() );
			}
			else if ( (W3RepairObjectEnhancement)_currentEffects[i] && GetWitcherPlayer().HasRunewordActive('Runeword 5 _Stats') )
			{
				l_flashObject.SetMemberFlashNumber("duration", -1 );
				l_flashObject.SetMemberFlashNumber("initialDuration", -1 );
			}
			else
			{
				l_flashObject.SetMemberFlashNumber("duration",_currentEffects[i].GetDurationLeft() );
				l_flashObject.SetMemberFlashNumber("initialDuration", _currentEffects[i].GetInitialDurationAfterResists());
			}
			l_flashArray.PushBackFlashObject(l_flashObject);	
		}
	}
	
	m_flashValueStorage.SetFlashArray( "hud.buffs", l_flashArray );
}

// ARM-06 (audit F7): the HUD's per-frame update sends the Feline set's chain to the buff list, as
// legacy; 5.x sent 1/1 for an effect without a duration, overwriting UpdateBuffs's counter each tick.
// 5.x body; changes marked //modSigns.
@replaceMethod(CR4HudModuleBuffs)
function OnTick( timeDelta : float )
{
	var effectsSize : int;
	var effectArray : array< CBaseGameplayEffect >;
	var i : int;
	var offset : int;
	var duration : float;
	var extraValue : int;
	var initialDuration : float;
	var hasRunword5 : bool;
	var oilEffect : W3Effect_Oil;
	var aerondightEffect	: W3Effect_Aerondight;
	var effectType : EEffectType;
	var minAttributeValue, maxAttributeValue : SAbilityAttributeValue;

	if ( !CanTick( timeDelta ) )
		return true;

	_previousEffects = _currentEffects;
	_currentEffects.Clear();
	
	if( bDisplayBuffs && GetEnabled() )
	{		
		offset = 0;
		
		effectArray = thePlayer.GetCurrentEffects();
		effectsSize = effectArray.Size();
		hasRunword5 = false;
		
		for ( i = 0; i < effectsSize; i += 1 )
		{
			if(effectArray[i].ShowOnHUD() && effectArray[i].GetEffectNameLocalisationKey() != "MISSING_LOCALISATION_KEY_NAME" )
			{	
				
				initialDuration = effectArray[i].GetInitialDurationAfterResists();
				
				if ( (W3RepairObjectEnhancement)effectArray[i] && GetWitcherPlayer().HasRunewordActive('Runeword 5 _Stats') )
				{
					hasRunword5 = true;
					
					if (!m_runword5Applied)
					{
						m_runword5Applied = true;
						UpdateBuffs();
						break;
					}
				}

				effectType = effectArray[i].GetEffectType();

				if( initialDuration < 1.0)
				{
					initialDuration = 1;
					duration = 1;
				}
				else
				{
					duration = effectArray[i].GetDurationLeft();
					if ( thePlayer.CanUseSkill( S_Perk_14 ) &&
						( effectType == EET_ShrineAxii || 
						  effectType == EET_ShrineIgni || 
						  effectType == EET_ShrineQuen || 
						  effectType == EET_ShrineYrden || 
						  effectType == EET_ShrineAard
						)
					   )
					{
						
						duration = effectArray[i].GetInitialDuration() + 1;
					}
					else if ( effectType == EET_EnhancedWeapon ||
							  effectType == EET_EnhancedArmor )
					{
						if ( GetWitcherPlayer().HasRunewordActive('Runeword 5 _Stats') )
						{
							
							duration = effectArray[i].GetInitialDuration() + 1;
						}
					}
					else
					{
						if(duration < 0.f)
							duration = 0.f;		
					}
				}
				
				if ( effectType == EET_Oil )
				{
					oilEffect = (W3Effect_Oil)effectArray[ i ];
					if ( oilEffect )
					{
						
						if (oilEffect.GetAmmoCurrentCount() > 0 && GetWitcherPlayer().CanUseSkill(S_Alchemy_s06) && GetWitcherPlayer().GetSkillLevel(S_Alchemy_s06) > 2)
						{
							initialDuration = oilEffect.GetAmmoMaxCount();
							duration		= oilEffect.GetAmmoMaxCount();
						}
						else
						{
							initialDuration = oilEffect.GetAmmoMaxCount();
							duration		= oilEffect.GetAmmoCurrentCount();
						}
					}
				}					
				else if( effectType == EET_Aerondight )
				{
					aerondightEffect = (W3Effect_Aerondight)effectArray[i];
					if( aerondightEffect )
					{
						initialDuration = aerondightEffect.GetMaxCount();
						duration		= aerondightEffect.GetCurrentCount();
					}
				}
				else if( effectType == EET_GMPhantomWeapon )	//modSigns: SWD-06, Iris's charges
				{	//modSigns
					initialDuration = ( (W3GMEffect_PhantomWeapon)effectArray[i] ).GetMaxCount();	//modSigns
					duration		= ( (W3GMEffect_PhantomWeapon)effectArray[i] ).GetCurrentCount();	//modSigns
				}	//modSigns
				else if( effectType == EET_BasicQuen )
				{
					
					extraValue = ( ( W3Effect_BasicQuen ) effectArray[i] ).GetStacks();
					
				}
				else if ( effectType == EET_ConvergenceTheory )
				{
					theGame.GetDefinitionsManager().GetAbilityAttributeValue('ConvergenceTheoryEffect', 'spell_power', minAttributeValue, maxAttributeValue);
					extraValue = ( int )( minAttributeValue.valueMultiplicative * 100 );
					extraValue *= ( ( W3Effect_ConvergenceTheory ) effectArray[i] ).GetStacks() * thePlayer.GetSkillLevel(S_Magic_s37);
				}
				else if( effectType == EET_Mutation3 )
				{						
					duration = ( ( W3Effect_Mutation3 ) effectArray[i] ).GetStacks();
					initialDuration = duration;
				}
				else if( effectType == EET_Mutation4 )
				{						
					duration = ( ( W3Effect_Mutation4 ) effectArray[i] ).GetStacks();
					initialDuration = duration;
				}
				else if( effectType == EET_Mutation5 )
				{						
					duration = ( ( W3Effect_Mutation5 ) effectArray[i] ).GetStacks();
					initialDuration = ( ( W3Effect_Mutation5 ) effectArray[i] ).GetMaxStacks();
				}
				else if( effectType == EET_Mutation7Buff || effectType == EET_Mutation7Debuff )
				{	
					
					extraValue = ( ( W3Mutation7BaseEffect ) effectArray[i] ).GetStacks();
				}
				else if( effectType == EET_Mutation10 )
				{						
					duration = ( ( W3Effect_Mutation10 ) effectArray[i] ).GetStacks();
					initialDuration = duration;
				}
				else if( effectType == EET_Mutagen01 )	//modSigns: ALCH-10, the decoctions' stacks in % next to their timers (legacy)
					extraValue = ( ( W3Mutagen01_Effect ) effectArray[i] ).GMGetStacks();	//modSigns
				else if( effectType == EET_Mutagen05 )	//modSigns
					extraValue = ( ( W3Mutagen05_Effect ) effectArray[i] ).GMGetStacks();	//modSigns
				else if( effectType == EET_Mutagen10 )	//modSigns
					extraValue = ( ( W3Mutagen10_Effect ) effectArray[i] ).GMGetStacks();	//modSigns
				else if( effectType == EET_Mutagen15 )	//modSigns
					extraValue = ( ( W3Mutagen15_Effect ) effectArray[i] ).GMGetStacks();	//modSigns
				else if( effectType == EET_Mutagen17 )	//modSigns
					extraValue = ( ( W3Mutagen17_Effect ) effectArray[i] ).GMGetStacks();	//modSigns
				else if( effectType == EET_Mutagen22 )	//modSigns: ALCH-11
					extraValue = ( ( W3Mutagen22_Effect ) effectArray[i] ).GMGetStacks();	//modSigns
				else if( effectType == EET_LynxSetBonus )	//modSigns: ARM-06, the Feline set's chain (legacy)
				{	//modSigns
					duration = ( ( W3Effect_LynxSetBonus ) effectArray[i] ).GMGetStacks();	//modSigns
					initialDuration = ( ( W3Effect_LynxSetBonus ) effectArray[i] ).GMGetMaxStacks();	//modSigns
				}	//modSigns
				else if( effectType == EET_GMRuneword4 )	//modSigns: ENCH-05, Invigoration's bonus in % (legacy)
				{	//modSigns
					duration = ( ( W3GMEffect_Runeword4 ) effectArray[i] ).GetStacks();	//modSigns
					initialDuration = ( ( W3GMEffect_Runeword4 ) effectArray[i] ).GetMaxStacks();	//modSigns
				}	//modSigns
				else if( effectType == EET_GMRuneword11 )	//modSigns: ENCH-09, Prolongation's bonus in % (legacy)
				{	//modSigns
					duration = ( ( W3GMEffect_Runeword11 ) effectArray[i] ).GetStacks();	//modSigns
					initialDuration = ( ( W3GMEffect_Runeword11 ) effectArray[i] ).GetMaxStacks();	//modSigns
				}	//modSigns
				
				if(_currentEffects.Size() < i+1-offset)
				{
					_currentEffects.PushBack(effectArray[i]);
					m_fxSetPercentSFF.InvokeSelfFourArgs( FlashArgNumber(i-offset),FlashArgNumber( duration ), FlashArgNumber( initialDuration ), FlashArgInt( extraValue ) );
				}
				else if( effectArray[i].GetEffectType() == _currentEffects[i-offset].GetEffectType() )
				{
					m_fxSetPercentSFF.InvokeSelfFourArgs( FlashArgNumber(i-offset),FlashArgNumber( duration ), FlashArgNumber( initialDuration ), FlashArgInt( extraValue ) );
				}
				else
				{
					LogChannel('HUDBuffs',i+" something wrong");
				}
			}
			else
			{
				offset += 1;
				
			}
		}
		
		if (!hasRunword5 && m_runword5Applied)
		{
			m_runword5Applied = false;
			UpdateBuffs();
		}
	}

	
	if ( _currentEffects.Size() == 0 && _previousEffects.Size() == 0 )
		return true;

	
	if ( buffListHasChanged(_currentEffects, _previousEffects) || _forceUpdate )
	{
		_forceUpdate = false;
		UpdateBuffs();
	}

}
