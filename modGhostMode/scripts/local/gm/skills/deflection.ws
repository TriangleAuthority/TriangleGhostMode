// SKL-05: Deflection, legacy's in both trees, level for level (D5, D6): damage from partial parries
// and counters -10% per level; arrows reflected on a perfectly timed parry from level 1; a reflected
// arrow's weapon damage +50% per level from level 2 (a pool term, damage/pool.ws); parry cost -50%
// with more than one enemy around, at level 3. Classic sword_s10, new tree sword_s33 (5.x: Arrow
// Deflection), 3 levels each; values in gm_skill_trees.xml and gm_skills.xml. 5.x's instant kill on
// reflected arrows (sword_s33) is set to 0 there.
// See docs/features/skl.md.

// The Deflection the player has (classic first); S_SUndefined if none.
@addMethod(W3PlayerWitcher)
function GMDeflectionSkill() : ESkill
{
	if(CanUseSkill(S_Sword_s10))
		return S_Sword_s10;
	if(CanUseSkill(S_Sword_s33))
		return S_Sword_s33;
	return S_SUndefined;
}

@addMethod(W3PlayerWitcher)
function GMDeflectionValue(attributeName : name) : float
{
	var skill : ESkill;

	skill = GMDeflectionSkill();
	if(skill == S_SUndefined)
		return 0;
	return CalculateAttributeValue(GetSkillAttributeValue(skill, attributeName, false, true));
}

// The share of a partial parry's or partial counter's damage Deflection removes, on top of the
// parry's own (DEF-05's 50%): s10_damage_reduction per level.
@addMethod(W3PlayerWitcher)
function GMDeflectionParryReduction() : float
{
	if(GMDeflectionSkill() == S_SUndefined)
		return 0;
	return GMDeflectionValue('s10_damage_reduction') * GetSkillLevel(GMDeflectionSkill());
}

// A reflected arrow's weapon damage bonus: damage_increase per level above 1.
@addMethod(W3PlayerWitcher)
function GMDeflectionDamageBonus() : float
{
	if(GMDeflectionSkill() == S_SUndefined)
		return 0;
	return GMDeflectionValue('damage_increase') * Max(GetSkillLevel(GMDeflectionSkill()) - 1, 0);
}

// The parry cost cut at level 3 with more than one enemy around (legacy GetDeflectionBonus).
@addMethod(W3PlayerWitcher)
function GMDeflectionParryCostCut() : float
{
	if(GMDeflectionSkill() == S_SUndefined || GetSkillLevel(GMDeflectionSkill()) < 3 || GMGetNumHostilesInRange() <= 1)
		return 0;
	return GMDeflectionValue('parry_cost_decrease');
}

// A perfectly timed parry reflects the arrow at its archer with either Deflection, from level 1
// (5.x: the classic skill from level 2, the new one from level 1, with its damage multiplied here).
// The damage bonus is applied as a pool term instead (legacy).
@replaceMethod(W3DeflectableAdvancedProjectile)
function ProcessCombat_ArrowDeflection() : bool
{
	var counterSpamming : bool;	//modSigns
	counterSpamming = thePlayer.CheckCounterSpamming( (CActor)caster );	//modSigns
	if ( counterSpamming && GetWitcherPlayer() && GetWitcherPlayer().GMDeflectionSkill() != S_SUndefined )	//modSigns: either tree, from level 1
	{	//modSigns
		StopProjectile();	//modSigns
		casterPos = caster.GetWorldPosition();	//modSigns
		casterPos.Z += 1.5;	//modSigns
		this.Init(thePlayer);	//modSigns
		this.deflected = true;	//modSigns: the hit is marked as a reflected arrow (SetBouncedArrow) for the pool term
		this.ShootProjectileAtPosition(8, projSpeed*1.25, casterPos);	//modSigns
		ActivateTrail('arrow_trail_red');	//modSigns
		if(thePlayer.CanUseSkill(S_Sword_s33))	//modSigns
			GetWitcherPlayer().GainAdrenalineFromPerk31( 'counter' );	//modSigns
		return true;	//modSigns
	}	//modSigns
	return false;	//modSigns
}
