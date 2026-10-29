// AI-12 (poise): "the bigger they are, the less severe their hit reaction is" (legacy's
// ModifyHitSeverityReactionFromDamage, its hit severity half; the damage half is DMG-01's GMZeroSubOneDamage,
// damage/pipeline.ws, which calls this one). Golems never react to hits. Melee hits on enemies up to 2 m tall
// are left alone (parries and counters handle those); any other hit loses one step of hit reaction
// (heavy -> light -> none) when it takes less than 3% of the victim's health and two below 1%, the
// thresholds scaled up by the victim's height over 2 m. "Huge" (IsHuge) means a capsule taller than 2 m.
// The hit_severity stat 5.x reads (no 5.x ability sets it) is no longer read. See docs/features/ai.md.

// The victim's movement capsule height (legacy CActor.GetCapsuleHeight).
@addMethod(CActor)
function GMGetCapsuleHeight() : float
{
	return ((CMovingPhysicalAgentComponent)GetMovingAgentComponent()).GetCapsuleHeight();
}

// AI-12: the hit severity half of legacy's ModifyHitSeverityReactionFromDamage. Called by GMZeroSubOneDamage
// for hits it leaves alone (not damage over time; not parried, countered or dodged; the victim an actor, not
// flying; at least 1 damage).
function GMModifyHitSeverityFromDamage( out damageData : W3DamageAction )
{
	var healthPrc, damage, capsuleHeight : float;
	var type : EHitReactionType;
	var severityReduction : int;
	var actorVictim : CActor;

	actorVictim = (CActor)damageData.victim;
	if( !actorVictim )
		return;

	// golems never react to hits
	if( actorVictim.HasAbility('mon_golem_base') )
	{
		damageData.SetHitReactionType(EHRT_None);
		damageData.SetHitAnimationPlayType(EAHA_ForceNo);
		return;
	}

	capsuleHeight = actorVictim.GMGetCapsuleHeight();

	// melee hits on enemies up to 2 m are left to parries and counters
	if( damageData.IsActionMelee() && capsuleHeight <= 2.0f )
		return;

	type = damageData.GetHitReactionType();

	if( actorVictim.UsesEssence() )
		damage = damageData.processedDmg.essenceDamage;
	else
		damage = damageData.processedDmg.vitalityDamage;

	healthPrc = damage / actorVictim.GetMaxHealth() * 100;
	healthPrc /= 1 + MaxF(0, capsuleHeight - 2);	// as if the thresholds grew with the height over 2 m

	if( healthPrc < 1 )
		severityReduction = 2;
	else if( healthPrc < 3 )
		severityReduction = 1;

	type = GMModifySeverity( type, severityReduction );
	if( type != damageData.GetHitReactionType() )
		damageData.SetHitReactionType(type);
	if( type == EHRT_None )
		damageData.SetHitAnimationPlayType(EAHA_ForceNo);
}

// Legacy's ModifySeverity: a hit reaction lowered by the given steps (Igni counts as heavy; Reflect kept).
function GMModifySeverity( type : EHitReactionType, severityReduction : int ) : EHitReactionType
{
	var severity : int;

	if( severityReduction == 0 )
		return type;

	switch( type )
	{
		case EHRT_Reflect :
			return type;
		case EHRT_Igni :
		case EHRT_Heavy :
			severity = 2;
			break;
		case EHRT_Light :
		case EHRT_LightClose :
			severity = 1;
			break;
		default :
			severity = 0;
			break;
	}

	severity = Clamp(severity - severityReduction, 0, 2);

	switch( severity )
	{
		case 2:		return EHRT_Heavy;
		case 1:		return EHRT_Light;
		default :	return EHRT_None;
	}
}

// AI-12: the hit_severity stat is not read (legacy). Rewritten body: every line is Ghost Mode's.
@replaceMethod
function ModifyHitSeverityReaction(target : CActor, type : EHitReactionType) : EHitReactionType
{
	return type;	//modSigns: hit_severity is no longer read
}

// AI-12: "huge" means a movement capsule taller than 2 m (5.x: the mon_type_huge ability). Read by Mutation 4's
// reach (damage manager) and Retribution (ENCH).
@replaceMethod(CActor)
function IsHuge() : bool
{
	return GMGetCapsuleHeight() > 2.0f;	//modSigns: 5.x: HasAbility( 'mon_type_huge' )
}
