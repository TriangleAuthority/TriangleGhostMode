// ARM-13: the Tesham Mutna (Vampire) set as legacy: with 3 pieces, every hit of Geralt's that deals
// damage (not damage over time, not in fistfights) heals 0.5% of his maximum Vitality per piece (3% at 6),
// in the replaced CActor.OnTakeDamage (mutations/takeDamage.ws); 5.x's heal on kills (1% per piece) is
// gone. Legacy's text. See docs/features/arm.md.

@addField(W3PlayerWitcher)
var gmVampireKillHealOff : bool;

@addMethod(W3PlayerWitcher)
function GMSetVampireKillHealOff(off : bool)
{
	gmVampireKillHealOff = off;
}

// 5.x heals on kills from CNewNPC.OnDeath; legacy does not: the call is turned off for that event
// (instead of replacing it).
@wrapMethod(CNewNPC)
function OnDeath( damageAction : W3DamageAction )
{
	var witcher : W3PlayerWitcher;

	witcher = GetWitcherPlayer();
	if(witcher)
		witcher.GMSetVampireKillHealOff(true);
	wrappedMethod(damageAction);
	if(witcher)
		witcher.GMSetVampireKillHealOff(false);
}

// Legacy's body: the share from the set's ability, per piece of every tier.
@replaceMethod(W3PlayerWitcher)
function VampiricSetAbilityRegeneration()
{
	var healthMax		: float;
	var healthToReg		: float;
	var min, max		: SAbilityAttributeValue;	//modSigns

	if( gmVampireKillHealOff )	//modSigns: no heal on kills (legacy)
		return;	//modSigns

	healthMax = GetStatMax( BCS_Vitality );

	theGame.GetDefinitionsManager().GetAbilityAttributeValue( 'setBonusAbilityVampire', 'life_percent', min, max );	//modSigns: legacy reads the value
	healthToReg = ( min.valueAdditive * GetSetPartsEquipped( EIST_Vampire ) * healthMax ) / 100;	//modSigns

	//modSigns: removed the drain effect (legacy: no effect on every hit)
	GainStat( BCS_Vitality, healthToReg );
}
