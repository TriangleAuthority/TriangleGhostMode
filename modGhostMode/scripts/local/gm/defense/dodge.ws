// DEF-01: dodge resolution. A dodge is decided before any damage is computed: a dodged hit
// skips the damage step entirely. The player dodges within a safe angle of 120 degrees
// (vanilla 150), +30 with the light armor set bonus; a dodge counts while dodging or while the
// combat action is a dodge or roll. NPCs dodge as in vanilla.
// DEF-04: Ciri dodges any dodgeable attack, whatever the angle.
// DEF-03: rolling also makes the player immune to long stagger.
// See docs/features/def.md.

// DEF-01: the dodge check runs first; a dodged hit deals no damage (legacy ProcessAction).
@wrapMethod(W3DamageManagerProcessor)
function ProcessActionDamage() : bool
{
	if(actorVictim && !action.GetSimulateOnly())
	{
		actorVictim.GMDodgeDamage(action);
		if(action.WasDodged())
		{
			action.SetAllProcessedDamageAs(0);
			return false;
		}
	}
	return wrappedMethod();
}

// DEF-01: legacy CActor.DodgeDamage (vanilla's NPC dodge, moved out of CActor.ReduceDamage, where
// 5.x still has it; it no longer fires there, since a dodged hit skips the damage step), and the
// player's dodge (legacy W3PlayerWitcher.DodgeDamage) and Ciri's (DEF-04), dispatched by type.
@addMethod(CActor)
function GMDodgeDamage(out damageData : W3DamageAction)
{
	var witcher : W3PlayerWitcher;
	var ciri : W3ReplacerCiri;

	witcher = (W3PlayerWitcher)this;
	if(witcher)
	{
		witcher.GMPlayerDodgeDamage(damageData);
		return;
	}
	ciri = (W3ReplacerCiri)this;
	if(ciri)
	{
		ciri.GMCiriDodgeDamage(damageData);
		return;
	}
	if(this != thePlayer && IsCurrentlyDodging() && damageData.CanBeDodged() && damageData.attacker
		&& (VecDistanceSquared(GetWorldPosition(), damageData.attacker.GetWorldPosition()) > 1.7
			|| HasAbility('IgnoreDodgeMinimumDistance')))
	{
		damageData.SetWasDodged();
		damageData.SetAllProcessedDamageAs(0);
		damageData.ClearEffects();
		damageData.SetHitAnimationPlayType(EAHA_ForceNo);
	}
}

// DEF-01: the player's dodge. The angle is between the dodge's heading and the attacker's
// (0: dodging straight away from the attack). The Ice Giant's stomp and anchor attacks keep
// vanilla's rule (dodged beyond 75% of their range). Environment and damage over time are
// never dodged. DEF-02: a hit taken while dodging that is not dodged (an undodgeable one included)
// is a graze, reduced by Fleet Footed (skills/fleetFooted.ws).
@addMethod(W3PlayerWitcher)
function GMPlayerDodgeDamage(out damageData : W3DamageAction)
{
	var actorAttacker : CActor;
	var attackRange : CAIAttackRange;
	var safeAngleDist, angleDist, distToAttacker, grazeReduction : float;
	var attackName : name;
	var isDodging, isIceGiantSpecial : bool;

	actorAttacker = (CActor)damageData.attacker;
	// legacy's fix for dodges not registered: the combat action counts too
	isDodging = IsCurrentlyDodging() || IsInCombatAction()
		&& ((int)GetBehaviorVariable('combatActionType') == (int)CAT_Dodge || (int)GetBehaviorVariable('combatActionType') == (int)CAT_Roll);
	if(!actorAttacker || !isDodging || damageData.IsActionEnvironment() || damageData.IsDoTDamage())
		return;
	grazeReduction = GMFleetFootedReduction();
	if(!damageData.CanBeDodged())
	{
		damageData.GMSetGrazeReduction(grazeReduction);
		return;
	}

	attackName = actorAttacker.GetLastAttackRangeName();
	angleDist = AbsF(AngleDistance(evadeHeading, actorAttacker.GetHeading()));
	attackRange = theGame.GetAttackRangeForEntity(actorAttacker, attackName);
	distToAttacker = VecDistance(GetWorldPosition(), actorAttacker.GetWorldPosition());
	isIceGiantSpecial = (attackName == 'stomp' || attackName == 'anchor_special_far' || attackName == 'anchor_far');

	safeAngleDist = 120;
	if(HasAbility('ArmorTypeLightSetBonusAbility'))	// ARM's light armor set bonus
		safeAngleDist += CalculateAttributeValue(GetAbilityAttributeValue('ArmorTypeLightSetBonusAbility', 'dodge_safe_ange_dist_deg'));
	safeAngleDist = ClampF(safeAngleDist, 0, 180);

	if(!isIceGiantSpecial && angleDist <= safeAngleDist || isIceGiantSpecial && attackRange && distToAttacker > attackRange.rangeMax * 0.75)
		damageData.SetWasDodged();
	else
		damageData.GMSetGrazeReduction(grazeReduction);
}

// DEF-04: Ciri dodges every dodgeable attack while dodging, whatever the angle (vanilla: under
// 150 degrees, in W3ReplacerCiri.ReduceDamage, which no longer sees a dodged hit); the hit's
// effects are cleared and no hit animation plays; she gains stamina as vanilla (legacy
// W3ReplacerCiri.DodgeDamage).
@addMethod(W3ReplacerCiri)
function GMCiriDodgeDamage(out damageData : W3DamageAction)
{
	if((CActor)damageData.attacker && IsCurrentlyDodging() && damageData.CanBeDodged())
	{
		damageData.SetAllProcessedDamageAs(0);
		damageData.SetWasDodged();
		damageData.ClearEffects();
		damageData.SetHitAnimationPlayType(EAHA_ForceNo);
		GainResource();
	}
}

// DEF-01: 5.x's W3PlayerWitcher.ReduceDamage without its dodge check (150 degrees): Ghost Mode
// decides the dodge before damage (GMPlayerDodgeDamage), as legacy did. 5.x body, changes marked
// //modSigns; Fleet Footed's reduction of a failed dodge is kept until DEF-02 (project owner,
// 2026-10-03).
@replaceMethod(W3PlayerWitcher)
function ReduceDamage(out damageData : W3DamageAction)
{
	var actorAttacker : CActor;
	var quen : W3QuenEntity;
	var currAdrenaline, adrenReducedDmg, focus : float;	//modSigns: the angle check's variables removed
	var useQuenForBleeding : bool;
	var min, max : SAbilityAttributeValue;
	var skillLevel, skillLevelRemaster : int;
	var attackAction : W3Action_Attack;	//modSigns

	super.ReduceDamage(damageData);

	//modSigns: DEF-05, DEF-06: a parried or countered hit that is not a partial parry takes no damage, also when
	//modSigns: the attack cannot be parried (legacy dropped CanBeParried from CActor.ReduceDamage's parry branch);
	//modSigns: its effects still apply (an attack that knocks down or staggers; defense/processAction.ws)
	attackAction = (W3Action_Attack)damageData;	//modSigns
	if(attackAction && damageData.IsActionMelee() && (attackAction.IsParried() || attackAction.IsCountered()) && !damageData.IsParryStagger())	//modSigns
		damageData.SetAllProcessedDamageAs(0);	//modSigns
	if(damageData.IsParryStagger() && GMDeflectionParryReduction() > 0)	//modSigns: SKL-05, Deflection: a partial parry or counter lets through 50% less its reduction (legacy: 1 - 0.5 - 0.1 per level)
		damageData.MultiplyAllDamageBy(ClampF(1 - theGame.params.PARRY_STAGGER_REDUCE_DAMAGE_SMALL - GMDeflectionParryReduction(), 0, 1) / (1 - theGame.params.PARRY_STAGGER_REDUCE_DAMAGE_SMALL));	//modSigns

	
	
	//modSigns: removed 5.x's Quen use for bleeding (SKL-11: Quen absorbs before armor, skills/quen.ws)

	
	if(!damageData.DealsAnyDamage())	//modSigns
		return;

	actorAttacker = (CActor)damageData.attacker;

	
	//modSigns: the dodge itself is decided before damage (DEF-01, GMPlayerDodgeDamage, 120 degrees);
	//modSigns: removed vanilla's 150 degree check and 5.x's Fleet Footed (a full dodge at its top level, else a reduction of failed dodges)
	if(damageData.GMGetGrazeReduction() > 0)	//modSigns: DEF-02, SKL-05: Fleet Footed reduces a graze's Vitality damage, at most 95% (legacy)
		damageData.processedDmg.vitalityDamage *= ClampF(1 - damageData.GMGetGrazeReduction(), 0.05, 1);	//modSigns

	
	//modSigns: removed the Quen call here (SKL-11: before armor, GMProcessDamageDecrease)

	
	//modSigns: removed the Griffin set's damage reduction inside Yrden (ARM-07: +15% resistances instead, legacy)

	
	//modSigns: removed Mutated Skin's damage reduction per adrenaline point (MUT-10: the damage is spread over time)

	if(!damageData.IsDoTDamage() && GMIsWhirlingWithAdrenaline())	//modSigns: SKL-03, Whirl: less damage taken while spinning with adrenaline
		damageData.processedDmg.vitalityDamage *= 1 - GMGetWhirlDamageReduction();	//modSigns
	damageData.processedDmg.vitalityDamage *= ClampF(1 - GMProtectiveCoatingCut(damageData), 0, 1);	//modSigns: SKL-14, Protective Coating (legacy; skills/oils.ws)
	GMWardingQuen(damageData);	//modSigns: ENCH-16, Glyph of Warding's Quen on projectile hits (legacy, moved here from ReactToBeingHit)
}

// DEF-03: rolling also grants immunity to long stagger (vanilla: knockdowns and stagger).
@wrapMethod(CR4Player)
function SetIsCurrentlyDodging(enable : bool, optional isRolling : bool)
{
	wrappedMethod(enable, isRolling);
	if(isRolling)
		AddBuffImmunity(EET_LongStagger, 'Roll', false);
	else
		RemoveBuffImmunity(EET_LongStagger, 'Roll');
}
