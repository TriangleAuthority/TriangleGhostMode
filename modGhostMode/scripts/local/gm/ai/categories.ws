// AI-07 (monster categories): legacy moved ghostly humans (the Hearts of Stone wedding guests, the
// Ethereal, the preacher's ghost, sq209's visions) to the specter category, dopplers to relics and
// succubi to hybrids, so oils, bombs and the bestiary treat them as what they are (the entity files,
// tools/gen_ai_ent.py). They still count as human for the human rules (finishers, dismemberment, the
// human resistances, DMG-15's armor fix): an actor tagged 'ethereal' or with legacy's ConHumanoidMonster
// template (AI-02) is human.
// See docs/features/ai.md.

// AI-07: legacy's IsHuman: also ethereal and humanoid-monster actors.
@wrapMethod(CActor)
function IsHuman() : bool
{
	var ret : bool;

	ret = wrappedMethod();
	if( !ret && ( HasTag( 'ethereal' ) || HasAbility( 'ConHumanoidMonster' ) ) )
		ret = true;
	return ret;
}
