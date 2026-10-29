// SKL-05: Deadly Precision, legacy's in both trees, level for level (D10, D11), and no instant-kill
// cooldown for the player (D12). For 3 s after a counter, melee hits on the countered enemy
// (CActor.GMWasCountered(), DEF-07) have an instant-kill chance of instant_kill_chance per level per
// adrenaline point (fractions count, at least 1 point; 3% per point at level 3); never during Whirl;
// enemies immune to instant kills are not affected. Classic sword_s3, new tree sword_s30, 3 levels.
// 5.x's new-tree instant-kill sources are gone: Deadly Precision's armed strong attack (and its
// adrenaline against immune enemies), Arrow Deflection's reflected arrows, Lightning Reflexes'
// headshots.
// AI-17 (ai/instantKill.ws) adds two of legacy's rules to the same function: contract monsters are immune,
// and a LastBreath monster is cut down to its threshold. See docs/features/skl.md and ai.md.

// The Deadly Precision the player has (classic first); S_SUndefined if none.
@addMethod(W3PlayerWitcher)
function GMDeadlyPrecisionSkill() : ESkill
{
	if(CanUseSkill(S_Sword_s03))
		return S_Sword_s03;
	if(CanUseSkill(S_Sword_s30))
		return S_Sword_s30;
	return S_SUndefined;
}

// The instant-kill chance Deadly Precision gives a hit: a melee hit that deals damage, not with fists,
// on the countered enemy, with at least 1 adrenaline point.
@addMethod(W3PlayerWitcher)
function GMDeadlyPrecisionChance(action : W3DamageAction, weaponId : SItemUniqueId, victim : CActor) : float
{
	var skill : ESkill;
	var focus : float;

	skill = GMDeadlyPrecisionSkill();
	if(skill == S_SUndefined || !action.IsActionMelee() || !action.DealsAnyDamage() || inv.IsItemFists(weaponId) || !victim || !victim.GMWasCountered())
		return 0;
	focus = GetStat(BCS_Focus);
	if(focus < 1)
		return 0;
	return focus * CalculateAttributeValue(GetSkillAttributeValue(skill, 'instant_kill_chance', false, true)) * GetSkillLevel(skill);
}

// 5.x body; changes marked //modSigns.
@replaceMethod(W3DamageManagerProcessor)
function ProcessInstantKill()
{
	var instantKill, focus : float;
	var victimIsImmune:bool;
	var witcherAttacker:W3PlayerWitcher;

	witcherAttacker = GetWitcherPlayer();


	if( action.WasDodged() || ( attackAction && ( attackAction.IsParried() || attackAction.IsCountered() ) ) )
	{
		return;
	}

	if( (W3MonsterHuntNPC)actorVictim )	//modSigns: AI-17, contract monsters are immune to instant kills (legacy)
	{	//modSigns
		return;	//modSigns
	}	//modSigns

	victimIsImmune = actorVictim.IsImmuneToInstantKill();


	if( !actorVictim || !actorAttacker || victimIsImmune || action.GetSimulateOnly() )
	{
		//modSigns: removed 5.x's new-tree Deadly Precision adrenaline against immune enemies (SKL-05, D11)
		return;
	}

	if( actorAttacker.HasAbility( 'ForceInstantKill' ) && actorVictim != thePlayer )
	{
		action.SetInstantKill();
	}


	//modSigns: removed the player's instant-kill cooldown (SKL-05, D12); a Whirl never kills instantly (legacy)
	if( actorAttacker == thePlayer && witcherAttacker )	//modSigns
	{
		if( witcherAttacker.IsDoingSpecialAttack(false) )	//modSigns
		{
			return;
		}
	}


	if( !action.GetInstantKill() )
	{

		instantKill = CalculateAttributeValue( actorAttacker.GetInventory().GetItemAttributeValue( weaponId, 'instant_kill_chance' ) );


		if( playerAttacker && witcherAttacker && actorAttacker == witcherAttacker )	//modSigns: Deadly Precision only on the countered enemy, melee, either tree (legacy; 5.x: any melee or ranged hit, classic only)
		{
			instantKill += witcherAttacker.GMDeadlyPrecisionChance(action, weaponId, actorVictim);	//modSigns
		}

		//modSigns: removed 5.x's new-tree instant kills (SKL-05, D12): Arrow Deflection's reflected arrows, Lightning Reflexes' headshots, Deadly Precision's armed strong attack
	}


	if( action.GetInstantKill() || ( RandF() < instantKill ) )
	{
		if( theGame.CanLog() )
		{
			if( action.GetInstantKill() )
			{
				instantKill = 1.f;
			}
			LogDMHits( "Instant kill!! (" + NoTrailZeros( instantKill * 100 ) + "% chance", action );
		}

		if( actorVictim.HasAbility( 'LastBreath' ) && !action.GetWasFrozen() )	//modSigns: AI-17, a LastBreath monster (rotfiend) is cut down to its threshold and explodes; a frozen one dies (EFX-09) (legacy)
		{	//modSigns
			if( actorVictim.UsesVitality() )	//modSigns
				action.processedDmg.vitalityDamage = GMGetLastBreathMaxAllowedDamage();	//modSigns
			else	//modSigns
				action.processedDmg.essenceDamage = GMGetLastBreathMaxAllowedDamage();	//modSigns
		}	//modSigns
		else	//modSigns
		{	//modSigns
			action.processedDmg.vitalityDamage = actorVictim.GetStat( BCS_Vitality );	//modSigns: the victim's health (legacy; 5.x adds it to the hit's damage)
			action.processedDmg.essenceDamage = actorVictim.GetStat( BCS_Essence );	//modSigns
		}	//modSigns
		action.SetCriticalHit();
		action.SetInstantKillFloater();


		if( playerAttacker )
		{
			thePlayer.SetLastInstantKillTime( theGame.GetGameTime() );
			theSound.SoundEvent( 'cmb_play_deadly_hit' );
			theGame.SetTimeScale( 0.2, theGame.GetTimescaleSource( ETS_InstantKill ), theGame.GetTimescalePriority( ETS_InstantKill ), true, true );
			thePlayer.AddTimer( 'RemoveInstantKillSloMo', 0.2 );
		}
	}
}
