// SWD-03: the Caretaker's Shovel (Hearts of Stone) heals Geralt on every enemy type, as legacy: its leech moves to
// the victim's CActor.OnTakeDamage (mutations/takeDamage.ws), which reads the victim's health type. 5.x's leech here
// read Geralt's own UsesEssence() for a victim on Essence, so it never healed on monsters or specters, although the
// shovel's description promises it (sweep B and D G7). See docs/features/swd.md.

// 5.x body; changes marked //modSigns.
@replaceMethod(CR4Player)
function OnProcessActionPost(action : W3DamageAction)
{
	var npc : CNewNPC;
	var attackAction : W3Action_Attack;
	var lifeLeech : float;
	
	super.OnProcessActionPost(action);
	
	attackAction = (W3Action_Attack)action;
	
	if(attackAction)
	{
		npc = (CNewNPC)action.victim;
		
		
		if ( npc && npc.UsesEssence() )
		{
			PlayBattleCry( 'BattleCryMonstersSilverHit', 0.09f );
		}
		
		else if(npc && (npc.IsHuman() || npc.GetMovingAgentComponent().GetName() == "wild_hunt_base") )
		{
			PlayBattleCry('BattleCryHumansHit', 0.09f );
		}
		else
		{
			PlayBattleCry('BattleCryMonstersHit', 0.09f );
		}
		
		if(attackAction.IsActionMelee())
		{
			
			IncreaseUninterruptedHitsCount();
			
			
			if( IsLightAttack( attackAction.GetAttackName() ) )
			{
				GCameraShake(0.1, false, GetWorldPosition(), 10);
			}
			
			
			//modSigns: removed the Caretaker's Shovel's leech (SWD-03: in CActor.OnTakeDamage, by the victim's health type, mutations/takeDamage.ws)
		}
	}
}
