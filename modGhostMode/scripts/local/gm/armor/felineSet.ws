// ARM-06: the Feline (Lynx) set as legacy (changelist 578-581, 600). Tier 1 (3 pieces, any tier): each
// fast hit in a chain adds +2.5% attack power per piece (up to +60%); a strong hit ends the chain at
// double the bonus; the chain breaks 3 s after the last hit (not while charging a special attack), at
// combat end, and a counter that kicks or bashes keeps it (defense/counter.ws). The bonus is DMG-03's
// attack power for melee hits (damage/formula.ws); 5.x's pool terms are gone (damage/pool.ws). Tier 2 (6
// grandmaster pieces): sword crits double the adrenaline gained (5.x: rear attacks +50% and a stun for
// 1 adrenaline). The HUD shows the bonus as a counter (mutations/hudCounters.ws). Values:
// LynxSetBonusEffect, setBonusAbilityLynx_2 in gm_armor_sets.xml. See docs/features/arm.md.

class W3Effect_LynxSetBonus extends CBaseGameplayEffect
{
	// The chain breaks when its delay runs out (legacy OnUpdate).
	event OnUpdate(dt : float)	//modSigns
	{	//modSigns
		super.OnUpdate(dt);	//modSigns
		if(gmDecay > 0 && !thePlayer.IsDoingSpecialAttack(true))	//modSigns
			gmDecay -= dt;	//modSigns
		if(gmDecay < 0 && gmCurBonus > 0)	//modSigns
			GMDischarge();	//modSigns
	}	//modSigns
}

@addField(W3Effect_LynxSetBonus)
var gmBonus : float;
@addField(W3Effect_LynxSetBonus)
var gmCurBonus : float;
@addField(W3Effect_LynxSetBonus)
var gmMaxBonus : float;
@addField(W3Effect_LynxSetBonus)
var gmDecay : float;

// The attack power bonus for a hit: doubled for a strong hit.
@addMethod(W3Effect_LynxSetBonus)
function GMGetLynxBonus(isHeavy : bool) : float
{
	if(isHeavy)
		return gmCurBonus * 2;
	return gmCurBonus;
}

// After a melee hit: a fast hit adds to the chain, a strong hit ends it.
@addMethod(W3Effect_LynxSetBonus)
function GMManageLynxBonus(isHeavy : bool)
{
	if(isHeavy && gmCurBonus > 0)
		GMDischarge();
	else if(!isHeavy)
		GMAccumulate();
}

@addMethod(W3Effect_LynxSetBonus)
function GMDischarge()
{
	var swEnt : CItemEntity;

	if(target.GetInventory().GetCurrentlyHeldSwordEntity(swEnt))
	{
		swEnt.StopEffectIfActive('fast_attack_buff');
		swEnt.PlayEffectSingle('fast_attack_buff_hit');
	}
	gmCurBonus = 0;
	gmDecay = 0;
}

@addMethod(W3Effect_LynxSetBonus)
function GMAccumulate()
{
	var swEnt : CItemEntity;

	if(target.GetInventory().GetCurrentlyHeldSwordEntity(swEnt) && !swEnt.IsEffectActive('fast_attack_buff'))
		swEnt.PlayEffect('fast_attack_buff');
	if(gmCurBonus < gmMaxBonus)
		gmCurBonus = MinF(gmCurBonus + gmBonus * ((W3PlayerWitcher)target).GetSetPartsEquipped(EIST_Lynx), gmMaxBonus);
	gmDecay = 3.0;
}

// A counter keeps the chain going without adding to it.
@addMethod(W3Effect_LynxSetBonus)
function GMResetDecay()
{
	gmDecay = 3.0;
}

@addMethod(W3Effect_LynxSetBonus)
function GMGetStacks() : int
{
	return RoundMath(gmCurBonus * 100);
}

@addMethod(W3Effect_LynxSetBonus)
function GMGetMaxStacks() : int
{
	return RoundMath(gmMaxBonus * 100);
}

// 5.x body; changes marked //modSigns.
@replaceMethod(W3Effect_LynxSetBonus)
function OnEffectAdded( customParams : W3BuffCustomParams )
{
	var dm			: CDefinitionsManagerAccessor;	//modSigns
	var min, max	: SAbilityAttributeValue;	//modSigns

	dm = theGame.GetDefinitionsManager();	//modSigns: legacy's values; the sword effect starts with the first fast hit
	dm.GetAbilityAttributeValue('LynxSetBonusEffect', 'lynx_ap_boost', min, max);	//modSigns
	gmBonus = min.valueAdditive;	//modSigns
	dm.GetAbilityAttributeValue('LynxSetBonusEffect', 'lynx_boost_max', min, max);	//modSigns
	gmMaxBonus = min.valueAdditive;	//modSigns
	
	super.OnEffectAdded( customParams );
}

// 5.x body; changes marked //modSigns.
@replaceMethod(W3Effect_LynxSetBonus)
function OnEffectRemoved()
{
	var inv		: CInventoryComponent;
	var swEnt	: CItemEntity;
	
	inv = target.GetInventory();
	
	if( inv.GetCurrentlyHeldSwordEntity( swEnt ) )
	{
		//modSigns: removed the discharge effect (legacy)
		swEnt.StopEffectIfActive( 'fast_attack_buff' );	//modSigns
	}
	
	super.OnEffectRemoved();
}

// 5.x body; changes marked //modSigns.
@replaceMethod(W3Effect_LynxSetBonus)
function OnResumed()
{
	var inv		: CInventoryComponent;
	var swEnt	: CItemEntity;
	
	inv = target.GetInventory();
	if( inv.GetCurrentlyHeldSwordEntity( swEnt ) && gmCurBonus > 0 )	//modSigns: only with a bonus
	{
		swEnt.PlayEffect( 'fast_attack_buff' );
	}

	super.OnResumed();
}

// Tier 1: any melee hit not dodged starts the effect, then feeds or ends the chain (legacy
// OnProcessActionPost). Tier 2: a sword crit doubles the adrenaline it gained (legacy doubles the hit's
// gain before Adrenaline Rush's multiplier, which GainStat applies again here).
@wrapMethod(W3PlayerWitcher)
function OnProcessActionPost(action : W3DamageAction)
{
	var attackAction : W3Action_Attack;
	var before, gained : float;
	var lynx : W3Effect_LynxSetBonus;

	attackAction = (W3Action_Attack)action;
	before = GetStat(BCS_Focus);
	wrappedMethod(action);
	if(attackAction && attackAction.IsActionMelee() && attackAction.IsCriticalHit() && IsSetBonusActive(EISB_Lynx_2) && !inv.IsItemFists(attackAction.GetWeaponId()))
	{
		gained = GetStat(BCS_Focus) - before;
		if(gained > 0 && GMMutation7GainMult() > 0)
			GainStat(BCS_Focus, gained / GMMutation7GainMult());
	}
	if(IsSetBonusActive(EISB_Lynx_1) && attackAction && attackAction.IsActionMelee() && !attackAction.WasDodged())
	{
		if(!HasBuff(EET_LynxSetBonus))
		{
			AddEffectDefault(EET_LynxSetBonus, NULL, "LynxSetBuff");
			SoundEvent("ep2_setskill_lynx_activate");
		}
		lynx = (W3Effect_LynxSetBonus)GetBuff(EET_LynxSetBonus);
		if(lynx)
			lynx.GMManageLynxBonus(IsHeavyAttack(attackAction.GetAttackName()));
	}
}

// Tier 1's attack power for a melee hit.
@addMethod(W3PlayerWitcher)
function GMLynxSetAttackPower(attackAction : W3Action_Attack) : float
{
	var lynx : W3Effect_LynxSetBonus;

	if(!attackAction || !attackAction.IsActionMelee())
		return 0;
	lynx = (W3Effect_LynxSetBonus)GetBuff(EET_LynxSetBonus);
	if(!lynx)
		return 0;
	return lynx.GMGetLynxBonus(IsHeavyAttack(attackAction.GetAttackName()));
}
