// WGT: what being overburdened does (docs/features/wgt.md), on top of 5.x's no running or sprinting.

// WGT-07: the share Geralt is over his carry limit while overburdened, 0 to 1 (legacy's
// W3PlayerAbilityManager.CalcStaminaOverEncumbrancePenalty). ARM-02's wrapper of GetStaminaActionCost adds it to
// the armor class's share for melee and agility actions: cost x (1 + armor + overencumbrance) (PW5).
function GMOverEncumbrancePenalty() : float
{
	var witcher : W3PlayerWitcher;
	var horseBonus : bool;
	var limit : float;

	witcher = GetWitcherPlayer();
	if(!witcher || !witcher.HasBuff(EET_OverEncumbered))
		return 0;
	limit = witcher.GetMaxRunEncumbrance(horseBonus);
	if(limit <= 0)
		return 0;
	return ClampF(witcher.GetEncumbrance() / limit - 1, 0, 1);
}

// WGT-08: no fast travel while overburdened.
@wrapMethod(W3Effect_OverEncumbered)
function OnEffectAdded(optional customParams : W3BuffCustomParams)
{
	var res : bool;

	res = wrappedMethod(customParams);
	if(isOnPlayer)
		((CR4Player)target).BlockAction(EIAB_FastTravel, 'OverEncumbered', true);
	return res;
}

@wrapMethod(W3Effect_OverEncumbered)
function OnEffectRemoved()
{
	var res : bool;

	res = wrappedMethod();
	if(isOnPlayer)
		((CR4Player)target).UnblockAction(EIAB_FastTravel, 'OverEncumbered');
	return res;
}

// WGT-09: Roach neither canters nor gallops while Geralt cannot sprint (5.x's cart and settlement rules kept).
@wrapMethod(W3HorseComponentStateExploration)
function CanCanter() : bool
{
	var res : bool;

	res = wrappedMethod();
	return res && thePlayer.IsActionAllowed(EIAB_RunAndSprint);
}

// WGT-11: the load recounted when Geralt comes to after a knockout (items or money taken while he was down).
@wrapMethod(CR4PlayerStateUnconscious)
function OnLeaveState(nextStateName : name)
{
	var res : bool;

	res = wrappedMethod(nextStateName);
	if((W3PlayerWitcher)parent)
		((W3PlayerWitcher)parent).UpdateEncumbrance();
	return res;
}
