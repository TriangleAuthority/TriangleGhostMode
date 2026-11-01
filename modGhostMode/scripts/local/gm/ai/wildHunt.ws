// AI-15 (slice C1): the Wild Hunt. See docs/features/ai.md.
// Ice Armor (Caranthir's spell and the Hunt's warriors' ability) adds 30% to every resistance instead of
// halving the damage after the formula (5.x: CActor.ReduceDamage, removed there, damage/pipeline.ws), so
// resistance reduction counts against it, and any fire removes it (5.x: Igni only). Eredin is no longer
// immune to signs (the EredinInvulnerable check, removed from ReduceDamage). The Hunt's stats, weapons
// with frost damage and phase abilities are data (tools/gen_ai.py, gm_ai_special.xml, gm_ai_weapons.xml).

// AI-15: Ice Armor's resistance bonus for a hit, read by GetDamageResists (damage/formula.ws): +0.3 on
// every resistance of a victim with IceArmor, from any attacker but Ciri's rage, not for damage over time
// and not on Easy (legacy GetDamageResists; 5.x: damage halved, 5% on Easy).
function GMIceArmorResistBonus( action : W3DamageAction, attacker : CActor, victim : CActor ) : float
{
	if( !action || !attacker || !victim || action.IsDoTDamage() )
		return 0;
	if( !victim.HasAbility( 'IceArmor' ) || attacker.HasAbility( 'Ciri_Rage' ) )
		return 0;
	if( theGame.GetSpawnDifficultyMode() == EDM_Easy )	// DIFF-09: in Ciri's sections, their mode (the chosen one unless the option caps it)
		return 0;
	return 0.3;
}

// AI-15: any fire hit removes Ice Armor (legacy CNewNPC.OnFireHit): burning, fire bombs, Firestream and
// the fire runes as well as Igni, whose OnIgniHit removes it already (5.x). The damage pipeline calls
// OnFireHit for any hit that deals fire damage, also a burning tick.
@wrapMethod(CNewNPC)
function OnFireHit(source : CGameplayEntity)
{
	var res : bool;

	res = wrappedMethod(source);
	GMRemoveIceArmor();
	return res;
}

// AI-15: Ice Armor off, with its effect (vanilla's lines in OnIgniHit).
@addMethod(CNewNPC)
function GMRemoveIceArmor()
{
	if( HasAbility( 'IceArmor' ) )
	{
		RemoveAbility( 'IceArmor' );
		StopEffect( 'ice_armor' );
		PlayEffect( 'ice_armor_hit' );
	}
}
