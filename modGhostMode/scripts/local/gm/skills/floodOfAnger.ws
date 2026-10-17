// SKL-07: Flood of Anger, legacy's in both trees (D16; sword_s19, shared by the trees in 5.x: the
// classic tree reads GM_C_sword_s19, 5 levels, the new tree sword_s19, 3 levels). When Geralt casts a
// sign with at least 3 adrenaline points, the sign (W3SignEntity.Init, before it reads its stats):
// - learns every sign skill of the tree in use at its maximum level for the cast (legacy's
//   AddTempNonAlchemySkills: also skills not equipped), undone when the sign cleans up;
// - gets +250% sign intensity at Flood of Anger's maximum level (spell_power 0.5 per level classic,
//   0.8333 new tree: the skill's ability added once per level while it lasts);
// - costs 3 adrenaline points: with Rage Management its adrenaline costs are tripled (1 point becomes
//   3, a channel drains 3 times as fast), without it 3 points are paid on top of the stamina
//   (GMFoaMult, skills/rageManagement.ws; the alternate Quen's drain in skills/quen.ws).
// 5.x's Flood of Anger is gone: its drain of all adrenaline, its 13 sign skills, the "supercharged" sign
// and its timers (W3PlayerWitcher.AddTemporarySkills, replaced). Effects that outlast the cast (the Quen
// shield, the Yrden trap and turret, Axii's confusion) keep the values they cached at the cast, as
// legacy.
// The temporary skills and the ability last until the sign's CleanUp, as legacy: 5.x's removals when
// Geralt is hit (W3PlayerWitcher.ReactToBeingHit) or a combat action ends (OnCombatActionEnd, through
// RemoveTemporarySkills and its DelayedRemoveTemporarySkills timer) are skipped while the Flood of Anger
// sign is active. A sign destroyed without CleanUp undoes them in OnDestroyed; leftovers with no active
// sign are still removed by 5.x's two sites.
// See docs/features/skl.md.

// The tree's sign skills at their maximum level for one cast; returns their previous levels. The classic
// tree's are the skills 5.x does not mark as reworked; the new tree's the reworked and the shared ones.
@addMethod(W3PlayerAbilityManager)
function GMAddTempSignSkills() : array<SSimpleSkill>
{
	var i, cnt, j : int;
	var ret : array<SSimpleSkill>;
	var temp : SSimpleSkill;
	var classic, inTree : bool;

	classic = GMIsClassicProfileInForce();
	tempSkills.Clear();
	for(i = 0; i < skills.Size(); i += 1)
	{
		if(skills[i].skillPath != ESP_Signs || skills[i].isCoreSkill)
			continue;
		if(classic)
			inTree = !skills[i].isReworked;
		else
			inTree = skills[i].isReworked || skills[i].isUnchangedLegacy;
		if(!inTree)
			continue;
		if(skills[i].level < skills[i].maxLevel || !IsSkillEquipped(skills[i].skillType))
		{
			temp.skillType = skills[i].skillType;
			temp.level = skills[i].level;
			ret.PushBack(temp);
			tempSkills.PushBack(skills[i].skillType);
			cnt = skills[i].maxLevel - skills[i].level;
			for(j = 0; j < cnt; j += 1)
				AddSkill(skills[i].skillType, true);
		}
	}
	return ret;
}

// Flood of Anger for a cast: with the skill and at least 3 adrenaline points, the temporary skills and
// the intensity bonus. True when it applies.
@addMethod(W3PlayerWitcher)
function GMAddFoATemporarySkills() : bool
{
	if(!CanUseSkill(S_Sword_s19) || GetStat(BCS_Focus) < 3)
		return false;
	GMRemoveFoATemporarySkills();
	tempLearnedSignSkills = ((W3PlayerAbilityManager)abilityManager).GMAddTempSignSkills();
	AddAbilityMultiple(GetSkillAbilityName(S_Sword_s19), GetSkillLevel(S_Sword_s19));
	return true;
}

// Undoes Flood of Anger at once (5.x's RemoveTemporarySkills waits while a sign is being cast).
@addMethod(W3PlayerWitcher)
function GMRemoveFoATemporarySkills()
{
	var i : int;
	var pam : W3PlayerAbilityManager;

	pam = (W3PlayerAbilityManager)abilityManager;
	for(i = 0; i < tempLearnedSignSkills.Size(); i += 1)
		pam.RemoveTemporarySkill(tempLearnedSignSkills[i]);
	tempLearnedSignSkills.Clear();
	for(i = 0; i < gmFoaHitStash.Size(); i += 1)
		pam.RemoveTemporarySkill(gmFoaHitStash[i]);
	gmFoaHitStash.Clear();
	RemoveAbilityAll('sword_s19');
	RemoveAbilityAll('GM_C_sword_s19');
}

@addField(W3SignEntity)
var gmFoaActive : bool;

// The sign that holds Flood of Anger's temporary skills (the last Flood of Anger cast).
@addField(W3PlayerWitcher)
var gmFoaSign : W3SignEntity;

// The temporary skills set aside while 5.x's ReactToBeingHit runs (below).
@addField(W3PlayerWitcher)
var gmFoaHitStash : array<SSimpleSkill>;

// True while a Flood of Anger sign is active (between its Init and its CleanUp).
@addMethod(W3PlayerWitcher)
function GMIsFoASignActive() : bool
{
	return gmFoaSign && gmFoaSign.gmFoaActive;
}

@wrapMethod(W3SignEntity)
function Init(inOwner : W3SignOwner, prevInstance : W3SignEntity, optional skipCastingAnimation : bool, optional notPlayerCast : bool) : bool
{
	var witcher : W3PlayerWitcher;

	gmFoaMult = 1;
	gmFoaActive = false;
	witcher = inOwner.GetPlayer();
	if(witcher && inOwner.GetActor() == witcher && !notPlayerCast && witcher.GMAddFoATemporarySkills())
	{
		gmFoaMult = 3;
		gmFoaActive = true;
		witcher.gmFoaSign = this;
	}
	return wrappedMethod(inOwner, prevInstance, skipCastingAnimation, notPlayerCast);
}

@wrapMethod(W3SignEntity)
function CleanUp()
{
	wrappedMethod();
	GMEndFoA();
}

// Undoes this sign's Flood of Anger (once).
@addMethod(W3SignEntity)
function GMEndFoA()
{
	var witcher : W3PlayerWitcher;

	if(!gmFoaActive)
		return;
	gmFoaActive = false;
	witcher = owner.GetPlayer();
	if(witcher)
	{
		if(witcher.gmFoaSign == this)
			witcher.gmFoaSign = NULL;
		witcher.GMRemoveFoATemporarySkills();
	}
}

// A sign destroyed without its CleanUp (5.x destroys some without it) still undoes Flood of Anger.
@addMethod(W3SignEntity)
event OnDestroyed()
{
	GMEndFoA();
	return super.OnDestroyed();
}

// 5.x removes the temporary skills when Geralt is hit (ReactToBeingHit: with Flood of Anger and temporary
// skills). While the Flood of Anger sign is active they are set aside for the call, so they stay until
// the sign's CleanUp (legacy); if the sign ends during the call (a hit that breaks a channel), its
// CleanUp removes them, set aside or not. Leftovers with no active sign are removed.
@wrapMethod(W3PlayerWitcher)
function ReactToBeingHit(damageAction : W3DamageAction, optional buffNotApplied : bool) : bool
{
	var ret : bool;

	if(GMIsFoASignActive())
	{
		gmFoaHitStash = tempLearnedSignSkills;
		tempLearnedSignSkills.Clear();
	}
	else if(tempLearnedSignSkills.Size() > 0)
		GMRemoveFoATemporarySkills();
	ret = wrappedMethod(damageAction, buffNotApplied);
	if(gmFoaHitStash.Size() > 0)
	{
		tempLearnedSignSkills = gmFoaHitStash;
		gmFoaHitStash.Clear();
	}
	return ret;
}

// 5.x's removal at the end of a combat action (OnCombatActionEnd), at a revive and after a load: skipped
// while the Flood of Anger sign is active (legacy dropped the combat action's); otherwise leftovers are
// removed, the classic tree's ability included.
@wrapMethod(W3PlayerWitcher)
function RemoveTemporarySkills()
{
	if(GMIsFoASignActive())
		return;
	if(tempLearnedSignSkills.Size() > 0 || HasAbility('GM_C_sword_s19'))
		GMRemoveFoATemporarySkills();
	wrappedMethod();
}

// 5.x's timer for a removal asked during a cast: through RemoveTemporarySkills (above), which waits while a
// sign is being cast as 5.x's timer did.
@replaceMethod(W3PlayerWitcher)
function DelayedRemoveTemporarySkills(dt : float, id : int)
{
	RemoveTemporarySkills(); //modSigns: 5.x's wait and removal, through the wrapper above
}

// 5.x's Flood of Anger, started before the sign entity exists: removed (Flood of Anger is applied by the
// sign itself, above).
@replaceMethod(W3PlayerWitcher)
function AddTemporarySkills()
{
	//modSigns: removed 5.x's Flood of Anger (all adrenaline drained, 5.x's 13 sign skills, the supercharged sign, removal timers)
}
