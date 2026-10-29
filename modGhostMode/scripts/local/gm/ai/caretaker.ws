// AI-19: the Caretaker (Hearts of Stone; docs/features/ai.md). He heals in proportion to the damage of his hit
// instead of a fixed share per hit, so a heavily armored Geralt can tank him: the heal is his maximum health x
// the hit's relative damage x healing_per_hit_perc (x number_of_shades while shades are up). The relative damage
// is the CausesDamage signal's value, which legacy changed in W3DamageManagerProcessor.ProcessAction
// (defense/processAction.ws): on Geralt the Vitality the hit took over half his maximum, at most 1; on anyone
// else 1, so a hit on a shade still heals him fully. 5.x's removal of its three extra bleeding types at his
// dispel is kept (OnAnimEvent, not replaced).

// 5.x body; changes marked //modSigns.
@replaceMethod(BTTaskCaretakerManager)
function OnListenedGameplayEvent( eventName : name ) : bool
{
	var l_damage : float ;
	var l_player : CR4Player;

	if( eventName == 'CausesDamage' )
	{
		CalculateHealingValues();

		l_damage = GetEventParamFloat( 0 );	//modSigns: the relative damage, 0 to 1 (ProcessAction)

		if( m_SummonerComponent.GetNumberOfSummonedEntities() > 0 )
			RestoreHealth( m_Npc.GetMaxHealth() * l_damage * recoverPercPerHit * shadesModifier );	//modSigns: in proportion to the hit's damage
		else
			RestoreHealth( m_Npc.GetMaxHealth() * l_damage * recoverPercPerHit );	//modSigns: in proportion to the hit's damage
	}
	if( eventName == 'Death' )
	{
		l_player.AddTimer('RemoveForceFinisher', 3, false, , , true );

		m_Npc.PlayEffectOnHeldWeapon( 'summon_shades', true );
	}

	return true;
}

// AI-19: the CausesDamage signal's value (legacy's, in ProcessAction): the share of half Geralt's maximum
// Vitality the hit took, at most 1, when he is the victim; 1 for any other victim (5.x: the damage dealt).
@addMethod(W3DamageManagerProcessor)
function GMCausesDamageValue() : float
{
	if( action.victim == thePlayer )
		return ClampF( action.processedDmg.vitalityDamage / (0.5 * thePlayer.GetMaxHealth()), 0.0f, 1.0f );
	return 1.0;
}
