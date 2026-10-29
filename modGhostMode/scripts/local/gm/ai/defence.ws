// AI-10 (guarding, parrying and taunts): hits and blocks count towards an enemy's guard and counter rolls
// for 2.5 s (2 s); the defend pose ends on the hit it blocked and keeps the enemy's following counter from
// being interrupted (no hit animation for 2 s); a broken shield lowers the guard and does not stagger its
// holder; the taunt always rolls the enemy's XML taunt chance (AI-08's values); monsters taunt every 5 s (3)
// and are made to attack after 10 s of taunting (20).
// Guard, parry and counter stamina are STAM-08's (stamina/npcStamina.ws, stamina/parryStamina.ws).
// See docs/features/ai.md.

// AI-10: monsters' taunt timing.
class CAIMonsterTauntParams extends CAITauntParameters
{
	default tauntDelay 			 = 5;	//modSigns: 3 -> 5 s
	default forceAttackDelay 	 = 10;	//modSigns: 20 -> 10 s
}

// AI-10: the taunt task rolls the XML chance (legacy also set the default; IsAvailable below ignores it).
class CBTTaskTauntDef extends CBTTaskPlayAnimationEventDecoratorDef
{
	default useXMLTauntChance = true;	//modSigns
}

// 5.x body; changed line marked //modSigns.
@replaceMethod(CActor)
function IncHitCounter()
{
	hitCounter += 1;
	totalHitCounter += 1;
	AddTimer('ResetHitCounter',2.5,false);	//modSigns: 2 -> 2.5 s
}

// 5.x body; changed line marked //modSigns.
@replaceMethod(CActor)
function IncDefendCounter()
{
	defendCounter += 1;
	totalDefendCounter += 1;
	AddTimer('ResetDefendCounter',2.5,false);	//modSigns: 2 -> 2.5 s
}

// 5.x body; changed lines marked //modSigns.
@replaceMethod(CBTTaskDefend)
function OnDeactivate()
{
	var npc : CNewNPC = GetNPC();

	npc.SetGuarded(false);
	npc.SetParryEnabled( false );
	if ( useCustomHits )
	{
		npc.customHits = false;
	}

	npc.SetIsInHitAnim(false);	//modSigns: the player cannot interrupt the counter that follows
	npc.DisableHitAnimFor(2.0);	//modSigns
}

// 5.x body; changed lines marked //modSigns.
@replaceMethod(CBTTaskDefend)
function OnGameplayEvent( eventName : name ) : bool
{
	var npc 					: CNewNPC = GetNPC();
	var data 					: CDamageData;
	var l_currentDuration		: float;

	if ( eventName == 'BeingHit' )
	{
		data = (CDamageData) GetEventParamBaseDamage();

		if( (CBaseGameplayEffect) data.causer )
			return true;

		if( !data.isDoTDamage && playParrySound )
			npc.SoundEvent( "cmb_play_parry" );

		if ( data.customHitReactionRequested )
		{
			npc.RaiseEvent('CustomHit');
			SetHitReactionDirection();
			//modSigns: removed return true; (the task completes below)
		}

		Complete(true);	//modSigns: the defend pose ends on the hit
		return true;	//modSigns
	}
	else if ( listenToParryEvents && ( eventName == 'ParryPerform' || eventName == 'ParryStagger' ) && npc.CanPlayHitAnim() )
	{
		npc.RaiseEvent('CustomHit');
		SetHitReactionDirection();
		return true;
	}
	else if ( eventName == 'IsDefending' )
	{
		SetEventRetvalInt(1);

		l_currentDuration = GetLocalTime() - m_activationTime;

		if ( completeTaskOnIsDefending && l_currentDuration > minimumDuration )
			Complete(true);
		return true;
	}

	else if ( eventName == 'DamageTaken' )
	{
		data = (CDamageData) GetEventParamBaseDamage();

		if( !data.isDoTDamage && playParrySound )
			npc.SoundEvent( "cmb_play_parry" );
	}


	return false;
}

// 5.x body; changed lines marked //modSigns.
@replaceMethod(CBTTaskTaunt)
function IsAvailable() : bool
{
	InitializeCombatDataStorage();
	timeStamp = combatDataStorage.GetTauntTimeStamp();
	if ( tauntDelay > 0 && timeStamp > 0 && ( timeStamp + tauntDelay > GetLocalTime() ) )
	{
		return false;
	}

	//modSigns: removed if ( useXMLTauntChance ): always the XML taunt chance
	//modSigns: removed {
		chance = (int)(100*CalculateAttributeValue(GetActor().GetAttributeValue('taunt_chance')));
		if ( !Roll(chance) )
			return false;
	//modSigns: removed }


	if ( GetActor().HasTag('mq1060_pv_boss') )
		return false;


	return true;
}

// 5.x body; changed lines marked //modSigns.
@replaceMethod(CNewNPC)
function ProcessShieldDestruction()
{
	var shield : CEntity;

	if( HasTag( 'imlerith' ) )
		return;

	SetBehaviorVariable( 'bShieldUp', 0.f );	//modSigns: the guard goes down
	DisableHitAnimFor( 2.0f );	//modSigns
	SetBehaviorVariable( 'bShieldbreak', 1.0 );
	//modSigns: removed AddEffectDefault( EET_Stagger, thePlayer, "ParryStagger" ); (no stagger)
	shield = GetInventory().GetItemEntityUnsafe( GetInventory().GetItemFromSlot( 'l_weapon' ) );
	ToggleEffectOnShield( 'heavy_block', true );
	DropItemFromSlot( 'l_weapon', true );
}
