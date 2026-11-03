// ENCH-16: runes and glyphs as legacy (changelist 78, 1015-1019). The values are the abilities in
// gm_ench.xml (tools/gen_ench.py): 3/4/5% for most runes and glyphs, Svarog 10/15/20, Pierog +5 Vitality
// regen out of combat, Tvarog +5 in combat (neither a relic any more), Mending 3/4/5, Binding 3/4/5%
// bleeding resistance. Glyph of Warding: a 3/4/5% chance that a projectile hit casts a free Quen that
// absorbs it, only when no Quen is up and for ranged hits that are not signs, damage over time or
// dodged (legacy moved the check from ReactToBeingHit to ReduceDamage). See docs/features/ench.md.

// Warding's free Quen; called from the port's ReduceDamage (defense/dodge.ws). Legacy's block.
@addMethod(W3PlayerWitcher)
function GMWardingQuen(out damageData : W3DamageAction)
{
	var quen : W3QuenEntity;
	var chance : float;

	quen = (W3QuenEntity)signs[ST_Quen].entity;
	if((quen && quen.IsAnyQuenActive()) || !damageData.IsActionRanged() || damageData.IsActionWitcherSign() || damageData.IsDoTDamage() || damageData.WasDodged())
		return;
	chance = ClampF(CalculateAttributeValue(GetAttributeValue('quen_chance_on_projectile')), 0, 1);
	if(chance <= 0 || RandF() >= chance)
		return;
	if(!quen)
		quen = (W3QuenEntity)theGame.CreateEntity(signs[ST_Quen].template, GetWorldPosition(), GetWorldRotation());
	quen.Init(signOwner, signs[ST_Quen].entity, true);
	quen.freeFromBearSetBonus = true;	// legacy's freeCast: no stamina, adrenaline or cooldown
	quen.OnStarted();
	quen.OnThrowing();
	quen.OnEnded();
	quen.GMShowHitFX();
	damageData.SetAllProcessedDamageAs(0);
	damageData.SetEndsQuen(true);
	gmWardingQuens += 1;
}

// Warding Quens cast so far (read by the tests).
@addField(W3PlayerWitcher)
public var gmWardingQuens : int;

// 5.x's body without its Quen on projectile hits (now in ReduceDamage, above). Changes marked //modSigns.
// FIX-05: the throw abort's test is FIX's (fixes/throwAbort.ws, docs/features/fix.md).
@replaceMethod(W3PlayerWitcher)
function ReactToBeingHit(damageAction : W3DamageAction, optional buffNotApplied : bool) : bool
{
	var pam : W3PlayerAbilityManager;	//modSigns: chance and procQuen removed
	var i : int;

	if(GMFixHitAbortsThrow(damageAction))	//modSigns: FIX-05, only while throwing or aiming, and only for a hit with a hit reaction (legacy; fixes/throwAbort.ws)
	{
		if(inv.IsItemBomb(selectedItemId))
		{
			BombThrowAbort();
		}
		else
		{

			ThrowingAbort();
		}
	}


	//modSigns: removed the Quen on projectile hits (Glyph of Warding; ENCH-16: GMWardingQuen, from ReduceDamage)


	if( !((W3Effect_Toxicity)damageAction.causer) )
		MeditationForceAbort(true);


	if(IsDoingSpecialAttack(false))
		damageAction.SetHitAnimationPlayType(EAHA_ForceNo);

	if(damageAction.DealtDamage())
	{
		ResetSkillComboCounter(S_Sword_s24);
		StopAllSkillComboEffectsEx(S_Sword_s24, PreciseBlowsCounterId_Fast);
		StopAllSkillComboEffectsEx(S_Sword_s24, PreciseBlowsCounterId_Strong);
	}
	if(thePlayer.CanUseSkill(S_Sword_s19) && tempLearnedSignSkills.Size() > 0)
	{
		pam = (W3PlayerAbilityManager)abilityManager;
		for(i=0; i<tempLearnedSignSkills.Size(); i+=1)
		{
			pam.RemoveTemporarySkill(tempLearnedSignSkills[i]);
		}

		tempLearnedSignSkills.Clear();
		RemoveAbilityAll(SkillEnumToName(S_Sword_s19));
	}

	return super.ReactToBeingHit(damageAction, buffNotApplied);
}
