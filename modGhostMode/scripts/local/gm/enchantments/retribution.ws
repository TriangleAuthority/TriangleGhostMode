// ENCH-12: Retribution (Glyphword 5) as legacy (changelist 1008): Quen Discharge and Exploding Shield
// deal +100% damage (skills/quen.ws, from the chest armor, ENCH-01); vanilla's chance to reflect melee
// damage is removed. 5.x body; changes marked //modSigns. DMG-11's wrapper (damage/returned.ws) still
// skips dodged hits. See docs/features/ench.md.

// Retribution's boost to Quen Discharge and Exploding Shield damage (0 without it).
function GMRetributionBoost(actor : CActor) : float
{
	var min, max : SAbilityAttributeValue;
	var w : W3PlayerWitcher;

	w = GetWitcherPlayer();
	if(!w || actor != w || !w.HasGlyphwordActive('Glyphword 5 _Stats'))
		return 0;
	theGame.GetDefinitionsManager().GetAbilityAttributeValue('Glyphword 5 _Stats', 'glyphword5_dmg_boost', min, max);
	return min.valueMultiplicative;
}

@replaceMethod(W3DamageManagerProcessor)
function ProcessActionReturnedDamage()
{
	var witcher 			: W3PlayerWitcher;
	var quen 				: W3QuenEntity;
	var params 				: SCustomEffectParams;
	var processFireShield, canBeParried, canBeDodged, wasParried, wasDodged, returned : bool;
	var g5Chance			: SAbilityAttributeValue;
	var dist, checkDist		: float;
	
	
	if((W3PlayerWitcher)playerVictim && !playerAttacker && actorAttacker && !action.IsDoTDamage() && action.IsActionMelee() && (attackerMonsterCategory == MC_Necrophage || attackerMonsterCategory == MC_Vampire) && actorVictim.HasBuff(EET_BlackBlood))
	{
		returned = ProcessActionBlackBloodReturnedDamage();		
	}
	

	
	
	if(action.IsActionMelee() && actorVictim.HasAbility( 'Thorns' ) )
	{
		returned = ProcessActionThornDamage() || returned;
	}
	

	
	//modSigns: ENCH-12, removed Retribution's (Glyphword 5) reflection of melee damage (legacy; it boosts Quen Discharge and Exploding Shield instead)

	
	if( (W3PlayerWitcher)playerVictim && !playerAttacker && actorAttacker && !playerAttacker.IsInFistFightMiniGame() && !action.IsDoTDamage() && action.IsActionMelee() && GetWitcherPlayer().IsMutationActive( EPMT_Mutation4 ) )
	{
		
		dist = VecDistance( actorAttacker.GetWorldPosition(), actorVictim.GetWorldPosition() );
		checkDist = 3.f;
		if( actorAttacker.IsHuge() )
		{
			checkDist += 3.f;
		}
 
		if( dist <= checkDist )
		{
			returned = GetWitcherPlayer().ProcessActionMutation4ReturnedDamage( action.processedDmg.vitalityDamage, actorAttacker, EAHA_ForceYes, action ) || returned;
		}
	}
	
	action.SetWasDamageReturnedToAttacker( returned );
}
