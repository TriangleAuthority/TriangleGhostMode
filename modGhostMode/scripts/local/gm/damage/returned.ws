// DMG-11: returned damage. Damage returned to an attacker is based on the damage the hit actually
// dealt and gets no attack power ("returned damage shouldn't use attack power", legacy); a dodged hit
// returns nothing. Thorns return 10% of the attacker's weapon damage (30 without a weapon) and keep
// attack power. Legacy's bodies; Glyphword 5's reflection stays 5.x's until ENCH. See
// docs/features/dmg.md.

// Nothing is returned for a dodged hit.
@wrapMethod(W3DamageManagerProcessor)
function ProcessActionReturnedDamage()
{
	if(action.WasDodged())
		return;
	wrappedMethod();
}

// Mutagen 26 (Leshen): a share of the damage dealt, as silver and physical damage (5.x: direct
// damage from the Vitality damage), no attack power.
@replaceMethod(W3DamageManagerProcessor)
function ProcessActionLeshenMutagenDamage() : bool
{
	var damageAction : W3DamageAction;
	var returnedDamage, pts, perc : float;
	var mutagen : W3Mutagen26_Effect;

	mutagen = (W3Mutagen26_Effect)playerVictim.GetBuff(EET_Mutagen26);
	mutagen.GetReturnedDamage(pts, perc);

	if(pts <= 0 && perc <= 0)
		return false;

	if(action.GetDamageDealt() <= 0)	//modSigns
		return false;	//modSigns
	returnedDamage = pts + perc * action.GetDamageDealt();	//modSigns: the damage dealt
	if(returnedDamage <= 0)	//modSigns
		return false;	//modSigns

	damageAction = new W3DamageAction in this;
	damageAction.Initialize( action.victim, action.attacker, NULL, "Mutagen26", EHRT_None, CPS_Undefined, true, false, false, false );	//modSigns: no attack power
	damageAction.SetCannotReturnDamage( true );
	damageAction.SetHitAnimationPlayType( EAHA_ForceNo );

	damageAction.AddDamage(theGame.params.DAMAGE_NAME_SILVER, returnedDamage);	//modSigns: silver and physical (5.x: direct)
	damageAction.AddDamage(theGame.params.DAMAGE_NAME_PHYSICAL, returnedDamage);	//modSigns

	theGame.damageMgr.ProcessAction(damageAction);
	delete damageAction;

	return true;
}

// Silver studs: no attack power.
@replaceMethod(W3DamageManagerProcessor)
function ProcessSilverStudsReturnedDamage() : bool
{
	var damageAction : W3DamageAction;
	var returnedDamage : float;

	returnedDamage = CalculateAttributeValue(actorVictim.GetAttributeValue('returned_silver_damage'));

	if(returnedDamage <= 0)
		return false;

	damageAction = new W3DamageAction in this;
	damageAction.Initialize( action.victim, action.attacker, NULL, "SilverStuds", EHRT_None, CPS_Undefined, true, false, false, false );	//modSigns: no attack power
	damageAction.SetCannotReturnDamage( true );
	damageAction.SetHitAnimationPlayType( EAHA_ForceNo );

	damageAction.AddDamage(theGame.params.DAMAGE_NAME_SILVER, returnedDamage);

	theGame.damageMgr.ProcessAction(damageAction);
	delete damageAction;

	return true;
}

// Black Blood: based on the damage dealt, as silver and physical damage (armor and resistances apply;
// 5.x: direct damage), no attack power.
@replaceMethod(W3DamageManagerProcessor)
function ProcessActionBlackBloodReturnedDamage() : bool
{
	var returnedAction : W3DamageAction;
	var returnVal : SAbilityAttributeValue;
	var bb : W3Potion_BlackBlood;
	var potionLevel : int;
	var returnedDamage : float;
	var procDmg : float;	//modSigns

	procDmg = action.GetDamageDealt();	//modSigns: the damage dealt
	if(procDmg <= 0)	//modSigns
		return false;

	bb = (W3Potion_BlackBlood)actorVictim.GetBuff(EET_BlackBlood);
	potionLevel = bb.GetBuffLevel();
	returnVal = bb.GetReturnDamageValue();	//modSigns: read first, to skip a hit that returns nothing
	returnedDamage = (returnVal.valueBase + procDmg) * returnVal.valueMultiplicative + returnVal.valueAdditive;	//modSigns
	if(returnedDamage <= 0)	//modSigns
		return false;	//modSigns

	returnedAction = new W3DamageAction in this;
	returnedAction.Initialize( action.victim, action.attacker, bb, "BlackBlood", EHRT_None, CPS_Undefined, true, false, false, false );	//modSigns: no attack power
	returnedAction.SetCannotReturnDamage( true );
	//modSigns: the return value is read above

	if(potionLevel == 1)
	{
		returnedAction.SetHitAnimationPlayType(EAHA_ForceNo);
	}
	else
	{
		returnedAction.SetHitAnimationPlayType(EAHA_ForceYes);
		returnedAction.SetHitReactionType(EHRT_Reflect);
	}

	returnedAction.AddDamage(theGame.params.DAMAGE_NAME_SILVER, returnedDamage);	//modSigns: silver and physical (5.x: direct)
	returnedAction.AddDamage(theGame.params.DAMAGE_NAME_PHYSICAL, returnedDamage);	//modSigns

	theGame.damageMgr.ProcessAction(returnedAction);
	delete returnedAction;
	return true;
}

// Thorns (an NPC ability): 10% of the attacker's weapon damage (30 without a weapon's damage), with
// attack power (vanilla mixed in the victim's attack damage and the damage dealt).
@replaceMethod(W3DamageManagerProcessor)
function ProcessActionThornDamage() : bool
{
	var damageAction 		: W3DamageAction;
	var damageVal 			: SAbilityAttributeValue;
	var damage				: float;
	var inv					: CInventoryComponent;
	var damageNames			: array < CName >;

	inv = actorAttacker.GetInventory();	//modSigns: moved before the action is built
	inv.GetWeaponDTNames(weaponId, damageNames );	//modSigns
	damage = actorAttacker.GetTotalWeaponDamage(weaponId, damageNames[0], GetInvalidUniqueId() );	//modSigns: the weapon's damage alone
	if( damage == 0 )	//modSigns
	{	//modSigns
		damage = 300;	//modSigns: a weapon without damage (vanilla 10 after the 10%)
	}	//modSigns
	damage *= 0.10f;	//modSigns
	if(damage <= 0)	//modSigns
		return false;	//modSigns

	damageAction	= new W3DamageAction in this;
	damageAction.Initialize( action.victim, action.attacker, NULL, "Thorns", EHRT_Light, CPS_AttackPower, true, false, false, false );
	damageAction.SetCannotReturnDamage( true );
	damageAction.AddDamage(  theGame.params.DAMAGE_NAME_PIERCING, damage );	//modSigns: not added to the damage dealt (vanilla: the victim's attack damage attribute mixed in)

	damageAction.SetHitAnimationPlayType( EAHA_ForceYes );
	theGame.damageMgr.ProcessAction(damageAction);
	delete damageAction;

	return true;
}
