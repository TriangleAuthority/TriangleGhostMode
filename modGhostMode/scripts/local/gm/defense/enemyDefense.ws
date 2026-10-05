// DEF-06: a countered enemy is helpless for a moment: while stunned by the counter (EET_CounterStrikeHit,
// 1 s) or within 3 s of being countered (DEF-07's flag) it does not dodge; while stunned it does not
// parry or react with a dodge. Legacy's checks at the start of the behaviour-tree tasks
// (btTaskDodge, btTaskPerformParry, btTaskReaction), as wrappers that answer "no" before vanilla's body.
// Legacy's same lines also stop dodges in the air or off the ground: AI's (see docs/features/def.md).
// See docs/features/def.md.

function GMEnemyCannotDodge(npc : CNewNPC) : bool
{
	return npc && ( npc.HasBuff(EET_CounterStrikeHit) || npc.GMWasCountered() );
}

@wrapMethod(CBTTaskDodge)
function IsAvailable() : bool
{
	if(GMEnemyCannotDodge(GetNPC()))
		return false;
	return wrappedMethod();
}

@wrapMethod(CBTTaskDodge)
function OnActivate() : EBTNodeStatus
{
	if(GMEnemyCannotDodge(GetNPC()))
		return BTNS_Failed;
	return wrappedMethod();
}

@wrapMethod(CBTTaskDodge)
function Dodge() : bool
{
	if(GMEnemyCannotDodge(GetNPC()))
		return false;
	return wrappedMethod();
}

@wrapMethod(CBTTaskDodge)
function ChooseAndCheckDodge() : bool
{
	if(GMEnemyCannotDodge(GetNPC()))
		return false;
	return wrappedMethod();
}

@wrapMethod(CBTTaskCircularDodge)
function ChooseAndCheckDodge() : bool
{
	if(GMEnemyCannotDodge(GetNPC()))
		return false;
	return wrappedMethod();
}

@wrapMethod(CBTTaskDodge)
function OnListenedGameplayEvent(eventName : name) : bool
{
	if(GMEnemyCannotDodge(GetNPC()))
		return false;
	return wrappedMethod(eventName);
}

// While stunned, no parry (legacy: checked after the task's set-up, before the Quen check).
@wrapMethod(CBTTaskPerformParry)
function IsAvailable() : bool
{
	if(GetNPC().HasBuff(EET_CounterStrikeHit))
		return false;
	return wrappedMethod();
}

// While stunned, no dodge reaction: the event that arms it is ignored. (Legacy also guarded
// ChooseAndCheckDodge, together with fixing CBTTaskReaction.Main, which in vanilla dodges when that check
// answers no; both are AI's. A guard there without that fix would start a dodge.)
@wrapMethod(CBTTaskReaction)
function OnGameplayEvent(eventName : name) : bool
{
	if(eventName == 'Time2Dodge' && GetNPC().HasBuff(EET_CounterStrikeHit))
		return false;
	return wrappedMethod(eventName);
}
