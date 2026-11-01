// XP-04 (XP audit F1, owner's decision (a), 2026-10-31): who earns a kill's experience, 1.32's and legacy's rule.
// Geralt earns it for his own kills, and within 20 m of him for a kill by something that is not an actor (a trap, the
// environment), by a party companion or by an NPC under Axii; never for a guard's kill. 5.x added any NPC friendly to
// Geralt within 30 m (guards included), so allies' kills gave Geralt the experience and used up his kill counts (UI-10).
// 5.x's body with its friendly branch removed (legacy left the function as 1.32's).
@replaceMethod(CNewNPC)
function ShouldGiveExp(attacker : CGameplayEntity) : bool
{
	var actor : CActor;
	var npc : CNewNPC;
	var victimAt : EAIAttitude;
	var giveExp : bool;
	
	victimAt = GetAttitudeBetween(thePlayer, this);
	giveExp = false;
	
	
	if(victimAt == AIA_Hostile)
	{
		if(attacker == thePlayer && !((W3PlayerWitcher)thePlayer) )
		{
			
			giveExp = false;
		}
		else if(attacker == thePlayer)	//modSigns: XP audit F1, 1.32's and legacy's (5.x: or any NPC friendly to Geralt within 30 m)
		{
			
			giveExp = true;
		}
		
		else if(VecDistance(thePlayer.GetWorldPosition(), GetWorldPosition()) <= 20)
		{
			npc = (CNewNPC)attacker;
			if(!npc || npc.npcGroupType != ENGT_Guard)	
			{
				actor = (CActor)attacker;
				if(!actor)
				{
					
					giveExp = true;
				}
				else if(actor.HasTag(theGame.params.TAG_NPC_IN_PARTY) || actor.HasBuff(EET_AxiiGuardMe))
				{
					
					giveExp = true;
				}							
			}
		}
	}
	
	return giveExp;
}
