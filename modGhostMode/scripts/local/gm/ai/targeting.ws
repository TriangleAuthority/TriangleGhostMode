// AI-11 (targeting): enemies go for whoever hurts them and no longer single out Geralt, so a puppet (Axii)
// or an ally draws its victims' attacks. The weights the combat AI gives each possible target: a recent
// hitter 20 -> 30, the current target 9 -> 20, the player 1,000 (monsters) or 100 (humans) -> 15, a monster
// for a human 101 -> 25 (legacy's). Entities and trees that set a weight themselves keep theirs (8 of 5.x's
// entity files set playerWeight: Blood and Wine's garkains and bruxa, a Skellige berserker; as in legacy).
// See docs/features/ai.md.

// AI-11: monsters (every monster combat parameter class derives from this one).
abstract class CAIBaseMonsterCombatParams extends CAICombatParameters
{
	default	hitterWeight 		= 30.0f;	//modSigns: 20
	default	currentTargetWeight = 20.0f;	//modSigns: 9
	default	playerWeight		= 15.0f;	//modSigns: 1000
}

// AI-11: human NPCs.
class CAINpcCombatParams extends CAICombatParameters
{
	default	hitterWeight 		= 30.0f;	//modSigns: 20
	default	currentTargetWeight = 20.0f;	//modSigns: 9
	default	playerWeight		= 15.0f;	//modSigns: 100
	default monsterWeight		= 25.0f;	//modSigns: 101
}
