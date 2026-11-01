// XP-04: kill experience (docs/features/xp.md; legacy's CNewNPC.CalculateExperiencePoints, GetExpByEnemyType and
// W3PlayerWitcher.GetExpModifierByEnemyType, PX5).
//
// A kill gives a base by enemy type (wolves and dogs 1; humans, drowners and the like 5; most monsters 10; large ones
// 15; contract monsters 15; bosses 20; unidentified creatures and animals 0) x (1 + 0.16 per level the enemy is above
// Geralt), clamped to 0 .. 1.5, x (1 - earlier kills of that type / 100, at most 100; bosses never cut, unidentified
// creatures and animals 0), at least 1. Guards give none and count as human kills. On every mode (DIFF-08). In NG+ the
// NG+ level is taken off the enemy's level only, not Geralt's (legacy's, DX3: about 1 XP a kill in NG+).
// The kill is counted here, after the experience is computed (UI-10's counter; its wrapper is folded in, PX5): the
// first kill of a type gives 100%. A call with skipLog (5.x's debug log) counts nothing (UI-10's rule).
// OnDeath (enchantments/npcDeath.ws) adds the gear bonus, the 1 XP minimum, XP-07's combat modifier and the combat log
// line. XP-07's options are read through GMXpFixedExp and GMXpCombatExpModifier (xp/expOptions.ws).

// Legacy's body (rewritten); every line Ghost Mode's.
@replaceMethod(CNewNPC)
function CalculateExperiencePoints(optional skipLog : bool) : int
{
	var finalExp				: int;	//modSigns
	var exp, expModifier		: float;	//modSigns
	var lvlDiff, npcLevel		: int;	//modSigns
	var enemyType				: EGMEnemyType;	//modSigns

	if(grantNoExperienceAfterKill || HasAbility('Zero_XP'))	//modSigns
		return 0;	//modSigns

	if(GetNPCType() == ENGT_Guard)	//modSigns: guards give none and count as human kills
	{	//modSigns
		if(!skipLog)	//modSigns
			GetWitcherPlayer().GMIncKills(GMENT_HUMAN);	//modSigns
		return 0;	//modSigns
	}	//modSigns

	enemyType = GMGetEnemyTypeByAbility(this);	//modSigns
	exp = (float)GMGetExpByEnemyType(enemyType);	//modSigns

	if((W3MonsterHuntNPC)this)	//modSigns: contract monsters
		exp = 15;	//modSigns

	expModifier = 1.0f;	//modSigns
	npcLevel = currentLevel;	//modSigns
	if(FactsQuerySum("NewGamePlus") > 0)	//modSigns: DX3, legacy's: the enemy's level only
		npcLevel -= theGame.params.GetNewGamePlusLevel();	//modSigns
	if(!GMXpFixedExp())	//modSigns: XP-07 "Fixed experience for quests and combat"
	{	//modSigns
		lvlDiff = npcLevel - thePlayer.GetLevel();	//modSigns
		expModifier = 1 + lvlDiff * theGame.params.LEVEL_DIFF_XP_MOD;	//modSigns
		expModifier = ClampF(expModifier, 0, theGame.params.MAX_XP_MOD);	//modSigns: 0% .. 150%
		expModifier *= GetWitcherPlayer().GMGetExpModifierByEnemyType(enemyType);	//modSigns
	}	//modSigns

	finalExp = RoundF(exp * expModifier);	//modSigns
	finalExp = Max(1, finalExp);	//modSigns: always at least 1

	if(!skipLog)	//modSigns: UI-10's counter, after the experience (PX5)
		GetWitcherPlayer().GMIncKills(enemyType);	//modSigns

	return finalExp;	//modSigns
}

// The base experience by enemy type (legacy's GetExpByEnemyType, gm_generic.ws).
function GMGetExpByEnemyType(et : EGMEnemyType) : int
{
	switch(et)
	{
		case GMENT_BOSS:				return 20;
		//BASE:
		case GMENT_HUMAN:				return 5;
		case GMENT_DOG:					return 1;
		case GMENT_WOLF:				return 1;
		case GMENT_BEAR:				return 5;
		case GMENT_BEAR_BERSERKER:		return 10;
		case GMENT_ENDRIAGA_WORKER:		return 5;
		case GMENT_ENDRIAGA_SOLDIER:	return 10;
		case GMENT_ENDRIAGA_TRUTEN:		return 10;
		case GMENT_FUGAS:				return 10;
		case GMENT_GARGOYLE:			return 10;
		case GMENT_ARACHAS:				return 15;
		case GMENT_ARACHAS_ARMORED:		return 15;
		case GMENT_ARACHAS_POISON:		return 15;
		case GMENT_WEREWOLF:			return 10;
		case GMENT_KATAKAN:				return 10;
		case GMENT_EKIMMA:				return 10;
		case GMENT_TROLL_ICE:			return 10;
		case GMENT_TROLL:				return 10;
		case GMENT_GOLEM:				return 15;
		case GMENT_ELEMENTAL:			return 15;
		case GMENT_ELEMENTAL_FIRE:		return 15;
		case GMENT_ELEMENTAL_ICE:		return 15;
		case GMENT_BIES:				return 15;
		case GMENT_CZART:				return 15;
		case GMENT_CYCLOPS:				return 10;
		case GMENT_SIREN:				return 5;
		case GMENT_HARPY:				return 5;
		case GMENT_ERYNIA:				return 5;
		case GMENT_WRAITH:				return 5;
		case GMENT_NIGHTWRAITH:			return 10;
		case GMENT_NOONWRAITH:			return 10;
		case GMENT_NEKKER:				return 5;
		case GMENT_DROWNER:				return 5;
		case GMENT_ROTFIEND:			return 5;
		case GMENT_ALGHOUL:				return 5;
		case GMENT_GHOUL:				return 5;
		case GMENT_WILD_HUNT_MINION:	return 5;
		case GMENT_GRYPHON:				return 10;
		case GMENT_BASILISK:			return 10;
		case GMENT_COCKATRICE:			return 10;
		case GMENT_LESSOG:				return 15;
		case GMENT_WYVERN:				return 5;
		case GMENT_FORKTAIL:			return 10;
		case GMENT_GRAVEHAG:			return 10;
		case GMENT_FOGLING:				return 5;
		case GMENT_WATERHAG:			return 5;
		case GMENT_WILD_HUNT_WARRIOR:	return 5;
		//EP1:
		case GMENT_BOAR:				return 5;
		case GMENT_BLACK_SPIDER:		return 5;
		//EP2:
		case GMENT_SHARLEY:				return 15;
		case GMENT_BRUXA:				return 10;
		case GMENT_ALP:					return 10;
		case GMENT_DRACOLIZARD:			return 10;
		case GMENT_BARGHEST:			return 5;
		case GMENT_KIKIMORA_WORKER:		return 5;
		case GMENT_KIKIMORA_WARRIOR:	return 10;
		case GMENT_SCOLOPENDROMORPH:	return 10;
		case GMENT_ARCHESPOR:			return 5;
		case GMENT_SPRIGAN:				return 15;
		case GMENT_WIGHT:				return 15;
		case GMENT_GRAVIER:				return 10;
		case GMENT_NIGHTWRAITH_BANSHEE:	return 10;
		case GMENT_FLEDER:				return 10;
		case GMENT_PROTOFLEDER:			return 10;
		case GMENT_GARKAIN:				return 10;
		case GMENT_PANTHER:				return 5;
		// no experience for unidentified creatures and animals
		case GMENT_GENERIC:
		case GMENT_ANIMAL:
		default:						return 0;
	}
}

// The diminishing returns by earlier kills of the type (legacy's GetExpModifierByEnemyType): bosses never cut,
// unidentified creatures and animals 0, the rest 1% less per earlier kill, down to 0 at 100.
@addMethod(W3PlayerWitcher)
function GMGetExpModifierByEnemyType(et : EGMEnemyType) : float
{
	switch(et)
	{
		case GMENT_BOSS:
			return 1;
		case GMENT_GENERIC:
		case GMENT_ANIMAL:
			return 0;
		default:
			return 1 - MinF(100.0f, (float)GMGetKills(et)) / 100.0f;
	}
}
