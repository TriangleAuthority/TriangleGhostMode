// XBOW-07 (headshots): the "Headshot" gameplay event (which behaviour trees with a kill-on-headshot
// task wait for, CBTTaskKill's onHeadshot) is sent where legacy sends it: when a headshot by Geralt
// deals damage (ProcessAction, defense/processAction.ws) and when a headshot's resistances are read
// (GetDamageResists, damage/formula.ws), no longer from the crit check (ProcessCriticalHitCheck,
// alchemy/bombs.ws). Which hits are headshots stays 5.x's (DB1 (b)): a bolt or arrow hitting a bone
// whose name contains head, neck or hroll (pelvis on humans), but only for an aimed shot: a quick
// (non-aimed) bolt of Geralt's is never a headshot, whatever bone it hits (F1 (c), owner, 2026-10-27;
// legacy and 5.x let any shot count). See docs/features/xbow.md.

@addMethod(W3DamageManagerProcessor)
function GMSignalHeadshot(from : name)
{
	if(actorVictim)
		actorVictim.SignalGameplayEvent( 'Headshot' );
}

// XBOW-07: a bolt of Geralt's is a headshot only when it was shot from aiming (CThrowable's
// isFromAimThrow, SKL-06's GMIsFromAimThrow, the flag the non-aimed half damage reads). Quick shots
// fly at a monster's targetable part or, without a torso2 bone, at the look-at point, which made most
// quick shots at wyverns, forktails and nekkers headshots (XBOW audit F1). 5.x body; the changed line
// is marked //modSigns.
@replaceMethod(W3BoltProjectile)
function ProcessDamageAction(victim : CGameplayEntity, pos : Vector, boneName : name)
{
	var action : W3Action_Attack;
	var victimTags, attackerTags : array<name>;
	var boneNameString : string;

	boneNameString = NameToString(boneName);

	
	
	
	
	if(caster == thePlayer)
	{
		
		thePlayer.ApplyItemAbilities(itemId);
		
		
		thePlayer.ApplyItemAbilities(crossbowId);
	}
	
	action = new W3Action_Attack in this;
	action.Init( (CGameplayEntity)caster, victim, this, itemId, 'bolt', caster.GetName(), EHRT_Light, false, false, '', AST_NotSet, ASD_NotSet, false, true, false, false, , , , , crossbowId);
	

	
	
	
	
	if ( (CNewNPC)victim && ( caster != thePlayer || GMIsFromAimThrow() ) )	//modSigns: XBOW-07, only an aimed shot of Geralt's can be a headshot (owner, 2026-10-27)
	{
		if ( StrFindFirst(boneNameString, "head") >= 0 || StrFindFirst(boneNameString, "neck") >= 0 || StrFindFirst(boneNameString, "hroll") >= 0 || ( StrFindFirst(boneNameString, "pelvis") >= 0 && ((CNewNPC)victim).IsHuman() ) )
			action.SetHeadShot();
	}
		
	theGame.damageMgr.ProcessAction( action );		
	delete action;
	
	
	if(caster == thePlayer)
	{
		
		thePlayer.RemoveItemAbilities(itemId);
		
		
		thePlayer.RemoveItemAbilities(crossbowId);
	}
	
	collidedEntities.PushBack(victim);
	
	
	if(caster == thePlayer && (CActor)victim && IsRequiredAttitudeBetween(caster, victim, true))
	{
		FactsAdd("ach_crossbow", 1, 4 );
	}
	
	
	victimTags = victim.GetTags();		
	attackerTags = caster.GetTags();		
	AddHitFacts( victimTags, attackerTags, "_bolt_hit" );
}
