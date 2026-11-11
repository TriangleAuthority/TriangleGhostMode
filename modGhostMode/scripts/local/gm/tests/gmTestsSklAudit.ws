// Tests for the SKL audit's fixes (docs/features/skl.md, "SKL audit (2026-10-16)"): slices A (combat
// code), B (Quen and sign payment), C (Yrden and Axii), D (effect data), G (bombs and oils) and H (the
// character reset).

// --- F22: Geralt's own bombs deal him full damage unless In Combat's Fires ---

// A scripted 50 fire damage hit by Geralt on himself, with the given causer; returns the Vitality taken
// (restored after).
function GMTestSelfHit(causer : IScriptable, source : string) : float
{
	var action : W3DamageAction;
	var before, taken : float;

	before = thePlayer.GetStat(BCS_Vitality);
	action = new W3DamageAction in theGame.damageMgr;
	action.Initialize(thePlayer, thePlayer, causer, source, EHRT_None, CPS_Undefined, false, false, false, false);
	action.AddDamage(theGame.params.DAMAGE_NAME_FIRE, 50);
	theGame.damageMgr.ProcessAction(action);
	delete action;
	taken = before - thePlayer.GetStat(BCS_Vitality);
	thePlayer.ForceSetStat(BCS_Vitality, before);
	thePlayer.RemoveAllBuffsOfType(EET_Burning);
	return taken;
}

// The Vitality Geralt takes from his own bomb (a Dancing Star 1 entity, spawned, not thrown, as the
// hit's causer) as a share of the same hit without a causer: 1 without In Combat's Fires (5.x: 0.5),
// 0.5 with it (its final-damage step).
function GMTestSelfBombRatio(out bomb : float, out plain : float) : float
{
	var witcher : W3PlayerWitcher;
	var ids : array<SItemUniqueId>;
	var petard : W3Petard;

	witcher = GetWitcherPlayer();
	ids = witcher.inv.GetItemsByName('Dancing Star 1');
	if(ids.Size() == 0)
		ids = witcher.inv.AddAnItem('Dancing Star 1', 1);
	petard = (W3Petard)witcher.inv.GetDeploymentItemEntity(ids[0], witcher.GetWorldPosition(), , true);
	if(!petard)
		return -1;
	petard.Initialize(witcher, ids[0]);
	petard.GMTestSetFromAimThrow(true);	// an aimed bomb: a quick throw's damage is halved (SKL-06)
	bomb = GMTestSelfHit(petard, "petard");
	plain = GMTestSelfHit(NULL, "gmtest");
	petard.Destroy();
	if(plain <= 0)
		return -1;
	return bomb / plain;
}

function GMTest_sklg_selfbomb()
{
	var bomb, plain, ratio, expected : float;

	ratio = GMTestSelfBombRatio(bomb, plain);
	expected = 1;
	if(GetWitcherPlayer().GMHasInCombatsFires())
		expected = 0.5;
	GMTestReport(AbsF(ratio - expected) < 0.01, "SKL audit F22: Geralt's own bomb hit takes " + bomb + " Vitality, the same hit without a bomb " + plain + " (ratio " + ratio + ", expected " + expected + ", In Combat's Fires " + GetWitcherPlayer().GMHasInCombatsFires() + ")");
}

exec function gmtest_sklg_selfbomb()
{
	GMTest_sklg_selfbomb();
}

// A real explosion of Geralt's own Dancing Star 1 at his feet (the bomb entity spawned, not thrown,
// counted as aimed; W3Petard.ProcessEffect, the impact): logs the Vitality it took and what the same
// damages take as a hit without a bomb. Without In Combat's Fires the two match (5.x: half); with it
// Geralt is not hit.
@addMethod(W3Petard)
function GMTestExplode(pos : Vector) : array<SRawDamage>
{
	LoadDataFromItemXMLStats();
	ProcessEffect(pos);
	return impactParams.damages;
}

exec function gmtest_sklg_explode()
{
	var witcher : W3PlayerWitcher;
	var ids : array<SItemUniqueId>;
	var petard : W3Petard;
	var damages : array<SRawDamage>;
	var action : W3DamageAction;
	var before, bomb, plain, expected : float;
	var i : int;
	var list : string;

	witcher = GetWitcherPlayer();
	ids = witcher.inv.GetItemsByName('Dancing Star 1');
	if(ids.Size() == 0)
		ids = witcher.inv.AddAnItem('Dancing Star 1', 1);
	petard = (W3Petard)witcher.inv.GetDeploymentItemEntity(ids[0], witcher.GetWorldPosition(), , true);
	petard.Initialize(witcher, ids[0]);
	petard.GMTestSetFromAimThrow(true);
	before = witcher.GetStat(BCS_Vitality);
	damages = petard.GMTestExplode(witcher.GetWorldPosition());
	bomb = before - witcher.GetStat(BCS_Vitality);
	witcher.ForceSetStat(BCS_Vitality, before);
	witcher.RemoveAllBuffsOfType(EET_Burning);

	action = new W3DamageAction in theGame.damageMgr;
	action.Initialize(witcher, witcher, NULL, "gmtest", EHRT_None, CPS_Undefined, false, false, false, false);
	for(i = 0; i < damages.Size(); i += 1)
	{
		action.AddDamage(damages[i].dmgType, damages[i].dmgVal);
		list += " " + damages[i].dmgType + " " + damages[i].dmgVal;
	}
	theGame.damageMgr.ProcessAction(action);
	delete action;
	plain = before - witcher.GetStat(BCS_Vitality);
	witcher.ForceSetStat(BCS_Vitality, before);

	expected = plain;
	if(witcher.GMHasInCombatsFires())
		expected = 0;
	GMTestReport(plain > 0 && AbsF(bomb - expected) < 0.01, "SKL audit F22: Geralt's own Dancing Star exploding at his feet took " + bomb + " Vitality, its damages (" + list + " ) as a hit without a bomb " + plain + " (In Combat's Fires " + witcher.GMHasInCombatsFires() + ")");
}

// --- F23: Heavy Artillery doubles only the flat part of a bomb's damage over time ---

@addMethod(W3BuffDoTParams)
function GMTestSet(fromBomb : bool, perk20 : bool)
{
	isFromBomb = fromBomb;
	isPerk20Active = perk20;
}

// The value of Devil's Puffball 1's poison (PoisonEffect_DevilsPuffball_1) added to Geralt by himself as
// a bomb's damage over time, with 5.x's Heavy Artillery flag on or off (removed after).
function GMTestBombDoTValue(perk20 : bool) : SAbilityAttributeValue
{
	var params : SCustomEffectParams;
	var dot : W3BuffDoTParams;
	var buff : CBaseGameplayEffect;
	var value : SAbilityAttributeValue;
	var result : EEffectInteract;

	dot = new W3BuffDoTParams in thePlayer;
	dot.GMTestSet(true, perk20);
	params.effectType = EET_Poison;
	params.creator = thePlayer;
	params.sourceName = "gmtest";
	params.customAbilityName = 'PoisonEffect_DevilsPuffball_1';
	params.buffSpecificParams = dot;
	thePlayer.RemoveAllBuffsOfType(EET_Poison);
	result = thePlayer.AddEffectCustom(params);
	if(result == EI_Deny)
	{
		// seen once on the first add of a session; a second add went through
		LogChannel('GMTest', "INFO SKL audit F23: poison denied, added again");
		result = thePlayer.AddEffectCustom(params);
	}
	buff = thePlayer.GetBuff(EET_Poison);
	if(buff)
		value = buff.GetEffectValue();
	thePlayer.RemoveAllBuffsOfType(EET_Poison);
	delete dot;
	return value;
}

function GMTest_sklg_dot()
{
	var off, on : SAbilityAttributeValue;
	var newTree : bool;
	var factor : float;

	off = GMTestBombDoTValue(false);
	on = GMTestBombDoTValue(true);
	// the new tree's Heavy Artillery doubles without 5.x's flag (the flag is set for perk_20 only)
	newTree = GetWitcherPlayer().GMHeavyArtillerySkill() == S_Perk_43;
	factor = 2;
	if(newTree)
		factor = 1;
	// since ALCH-14 the bomb's poison is legacy's 1% of health per tick with no flat part, so there is nothing to double
	GMTestReport(AbsF(on.valueAdditive - factor * off.valueAdditive) < 0.01 && AbsF(on.valueMultiplicative - off.valueMultiplicative) < 0.00001,
		"SKL audit F23: a bomb's poison with Heavy Artillery's flag: flat " + on.valueAdditive + ", share of health " + on.valueMultiplicative + "; without: " + off.valueAdditive + ", " + off.valueMultiplicative + " (Heavy Artillery equipped: " + SkillEnumToName(GetWitcherPlayer().GMHeavyArtillerySkill()) + ")");
}

exec function gmtest_sklg_dot()
{
	GMTest_sklg_dot();
}

// --- F25: bomb stacks trimmed when Pyrotechnics or the new tree's Heavy Artillery is equipped ---

// With count > 0, sets the carried count of a bomb (added if missing); logs its count and maximum stack.
exec function gmtest_sklg_stack(itemName : name, optional count : int)
{
	var inv : CInventoryComponent;
	var ids : array<SItemUniqueId>;

	inv = thePlayer.inv;
	ids = inv.GetItemsByName(itemName);
	if(ids.Size() == 0)
		ids = inv.AddAnItem(itemName, 1);
	if(count > 0)
		inv.SetItemModifierInt(ids[0], 'ammo_current', count);
	LogChannel('GMTest', "INFO SKL audit F25 " + itemName + ": carried " + inv.GetItemModifierInt(ids[0], 'ammo_current') + ", stack " + inv.SingletonItemGetMaxAmmo(ids[0]) + " (Heavy Artillery " + SkillEnumToName(GetWitcherPlayer().GMHeavyArtillerySkill()) + ", Pyrotechnics " + thePlayer.CanUseSkill(S_Alchemy_s10) + ")");
}

// --- F28, F29: the character reset empties every skill slot and sets toxicity to 0 ---

// Copies on Geralt of the path abilities 5.x adds per level of an equipped sword, sign or alchemy skill
// (values zeroed by SKL-01, still added and removed): what a skill left in a slot at level 0 keeps.
function GMTestPathPassiveCount() : int
{
	return thePlayer.GetAbilityCount('sword_adrenalinegain') + thePlayer.GetAbilityCount('magic_staminaregen') + thePlayer.GetAbilityCount('alchemy_potionduration');
}

// mode 1: a skill at level 2 in the fourth mutation slot (slot 16, opened by script) with mutation 1
// equipped, then gmreset()'s reset. mode 2: the same, the mutation then unequipped outside the menu
// (the slot locks with the skill in it), then a Potion of Clearance used (ConsumeItem). Toxicity 30
// before; checks that the skill is out of every slot with none of its path abilities left, and toxicity 0.
exec function gmtest_sklh_reset(mode : int)
{
	var witcher : W3PlayerWitcher;
	var pam : W3PlayerAbilityManager;
	var mutation : SMutation;
	var skill : ESkill;
	var ids : array<SItemUniqueId>;
	var researched : bool;
	var countBefore : int;

	witcher = GetWitcherPlayer();
	pam = (W3PlayerAbilityManager)witcher.abilityManager;
	witcher.AddPoints(ESkillPoint, 40, false);
	witcher.inv.AddAnItem('Greater mutagen red', 12);
	witcher.inv.AddAnItem('Greater mutagen blue', 12);
	witcher.inv.AddAnItem('Greater mutagen green', 12);
	researched = GMTestResearchMutation(EPMT_Mutation1);
	witcher.SetEquippedMutation(EPMT_Mutation1);
	mutation = witcher.GetMutation(EPMT_Mutation1);
	skill = GMTestSkl01SkillOfColour(mutation.colors[0], S_SUndefined);
	pam.GMTestSetSlotUnlocked(BSS_SkillSlot4, true);
	skilleq_internal(skill, BSS_SkillSlot4, 2);
	countBefore = GMTestPathPassiveCount();
	if(mode == 2)
		witcher.SetEquippedMutation(EPMT_None);
	witcher.GainStat(BCS_Toxicity, 30);
	LogChannel('GMTest', "INFO SKL audit F28 setup (mode " + mode + "): mutation researched " + researched + ", " + SkillEnumToName(skill) + " level " + witcher.GetSkillLevel(skill) + " in slot " + pam.GMTestSlotOf(skill) + " (unlocked " + (pam.GetSkillSlotIndex(BSS_SkillSlot4, true) >= 0) + "), path abilities x" + countBefore + ", toxicity " + witcher.GetStat(BCS_Toxicity));

	if(mode == 2)
	{
		ids = witcher.inv.AddAnItem('Clearing Potion', 1);
		witcher.ConsumeItem(ids[0]);
	}
	else
		witcher.GMResetCharacter();

	GMTestReport(countBefore > 0 && pam.GMTestSlotOf(skill) < 0 && !witcher.IsSkillEquipped(skill), "SKL audit F28 (mode " + mode + "): the skill is out of every slot after the reset (slot " + pam.GMTestSlotOf(skill) + ")");
	GMTestReport(GMTestPathPassiveCount() == 0, "SKL audit F28 (mode " + mode + "): path abilities x" + GMTestPathPassiveCount() + " left (x" + countBefore + " before)");
	GMTestReport(witcher.GetStat(BCS_Toxicity) == 0, "SKL audit F29 (mode " + mode + "): toxicity " + witcher.GetStat(BCS_Toxicity) + " after the reset");
}

// --- Slice A ---

@addMethod(W3PlayerWitcher)
function GMTestShouldPauseRegen() : bool
{
	return ShouldPauseHealthRegenOnHit();
}

// F1: a hit does not pause Vitality regeneration while Undying's effect runs (the effect added and
// removed by script; adrenaline and Vitality restored, the cooldown it starts removed).
function GMTest_skla_undying()
{
	var witcher : W3PlayerWitcher;
	var focus, vitality : float;
	var during, after : bool;

	witcher = GetWitcherPlayer();
	focus = witcher.GetStat(BCS_Focus);
	vitality = witcher.GetStat(BCS_Vitality);
	witcher.AddEffectDefault(EET_GMUndyingImmortal, NULL, "gmtest");
	during = witcher.GMTestShouldPauseRegen();
	witcher.RemoveAllBuffsOfType(EET_GMUndyingImmortal);
	witcher.RemoveAllBuffsOfType(EET_GMUndyingCooldown);
	after = witcher.GMTestShouldPauseRegen();
	witcher.ForceSetStat(BCS_Vitality, vitality);
	if(focus > 0)
		witcher.GainStat(BCS_Focus, focus);
	GMTestReport(!during && after, "SKL audit F1: a hit pauses Vitality regeneration during Undying " + during + " (expected false), after it " + after);
}

exec function gmtest_skla_undying()
{
	GMTest_skla_undying();
}

@addField(W3PlayerWitcher)
public var gmTestUndyingVitality : float;

@addMethod(W3PlayerWitcher)
function GMTestSetUndyingVitality(v : float)
{
	gmTestUndyingVitality = v;
}

// F1 in play, after gmtest_skl07_undying(0) started Undying: a scripted physical hit from the hostile test
// dummy for the given physical damage (phase 0); 1.5 s later (phase 1) Vitality must have grown (5.x
// paused the regen for 2 s).
exec function gmtest_skla_undying_hit(phase : int, optional amount : float)
{
	var witcher : W3PlayerWitcher;
	var npc : CActor;
	var action : W3Action_Attack;

	witcher = GetWitcherPlayer();
	if(phase == 0)
	{
		npc = GMTestHostileNpc();
		action = new W3Action_Attack in theGame.damageMgr;
		action.Init(npc, witcher, NULL, GetInvalidUniqueId(), 'attack_light', npc.GetName(), EHRT_Light,
			false, false, '', AST_Jab, ASD_UpDown, true, false, false, false);
		if(amount <= 0)
			amount = 2000;
		action.AddDamage(theGame.params.DAMAGE_NAME_PHYSICAL, amount);
		action.SetSuppressHitSounds(true);
		action.SetHitAnimationPlayType(EAHA_ForceNo);
		theGame.damageMgr.ProcessAction(action);
		witcher.GMTestSetUndyingVitality(witcher.GetStat(BCS_Vitality));
		LogChannel('GMTest', "INFO SKL audit F1: hit during Undying " + witcher.HasBuff(EET_GMUndyingImmortal) + ", deals damage " + action.DealsAnyDamage() + ", pauses the regen " + witcher.GMTestShouldPauseRegen() + ", threatened " + witcher.IsThreatened() + ", Vitality " + witcher.gmTestUndyingVitality);
		delete action;
		return;
	}
	GMTestReport(witcher.HasBuff(EET_GMUndyingImmortal) && witcher.GetStat(BCS_Vitality) > witcher.gmTestUndyingVitality + 1, "SKL audit F1: Vitality " + witcher.gmTestUndyingVitality + " -> " + witcher.GetStat(BCS_Vitality) + " within 2 s of a hit during Undying (5.x: paused)");
}

// F2: n scripted counters (GMTestCounterCheck) on the nearest hostile at full stamina and the given
// adrenaline, as it is or as a two-handed human fighter; counts knockdowns, kicks and stuns.
// Counterattack's knockdown rolls after the whole repel chain (the port before: one-handed humans only).
exec function gmtest_skla_counter(n : int, focus : float, optional twoHanded : bool)
{
	var witcher : W3PlayerWitcher;
	var npc : CNewNPC;
	var i, repel, knocked, stunned, kicks, down : int;
	var chance, share : float;
	var hadAbility, ok : bool;

	witcher = GetWitcherPlayer();
	npc = (CNewNPC)GMTestHostileNpc();
	if(!npc)
	{
		GMTestReport(false, "SKL audit F2: needs a hostile nearby");
		return;
	}
	hadAbility = npc.HasAbility('SkillTwoHanded');
	if(twoHanded && !hadAbility)
		npc.AddAbility('SkillTwoHanded', false);
	witcher.DrainFocus(witcher.GetStat(BCS_Focus));
	if(focus > 0)
		witcher.GainStat(BCS_Focus, focus);
	chance = witcher.GMCounterattackKnockdownChance();
	for(i = 0; i < n; i += 1)
	{
		witcher.GainStat(BCS_Stamina, witcher.GetStatMax(BCS_Stamina));
		npc.RemoveAllBuffsOfType(EET_HeavyKnockdown);
		npc.RemoveAllBuffsOfType(EET_Knockdown);
		npc.RemoveAllBuffsOfType(EET_CounterStrikeHit);
		if(npc.HasBuff(EET_HeavyKnockdown) || npc.HasBuff(EET_Knockdown))
		{
			down += 1;	// a knockdown still ending (its animation is frozen): not counted
			continue;
		}
		witcher.GMTestCounterCheck(npc, true, 'attack_light', repel);
		if(npc.HasBuff(EET_HeavyKnockdown) || npc.HasBuff(EET_Knockdown))
			knocked += 1;
		if(npc.HasBuff(EET_CounterStrikeHit))
			stunned += 1;
		if(repel == (int)PRT_Kick)
			kicks += 1;
	}
	npc.RemoveAllBuffsOfType(EET_HeavyKnockdown);
	npc.RemoveAllBuffsOfType(EET_Knockdown);
	npc.RemoveAllBuffsOfType(EET_CounterStrikeHit);
	if(twoHanded && !hadAbility)
		npc.RemoveAbility('SkillTwoHanded');
	if(n - down < 20)
	{
		GMTestReport(false, "SKL audit F2: the attacker stayed knocked down (" + down + " of " + n + "); wait and run again");
		return;
	}
	share = (float)knocked / (n - down);
	if(chance > 0)
		ok = knocked > 0 && AbsF(share - chance) < 0.12 && kicks >= knocked;
	else
		ok = knocked == 0;
	GMTestReport(ok, "SKL audit F2: " + n + " counters on " + npc.GetDisplayName() + " (human " + npc.IsHuman() + ", two-handed " + twoHanded + "), Counterattack " + SkillEnumToName(witcher.GMCounterattackSkill()) + " level " + witcher.GMCounterattackLevel() + ", adrenaline " + witcher.GetStat(BCS_Focus) + ": knocked down " + knocked + " (" + share + ", chance " + chance + "), kicks " + kicks + ", stunned " + stunned + ", skipped (still down) " + down);
}

// F32: Attack is the Best Defense's internal cooldown is 5.x's neutral effect (project owner, 2026-10-16; legacy: negative).
function GMTest_skla_perk21()
{
	var buff : CBaseGameplayEffect;
	var had : bool;

	had = thePlayer.HasBuff(EET_Perk21InternalCooldown);
	thePlayer.AddEffectDefault(EET_Perk21InternalCooldown, thePlayer, "gmtest");
	buff = thePlayer.GetBuff(EET_Perk21InternalCooldown);
	GMTestReport(buff && !buff.IsNegative() && buff.IsNeutral(), "SKL audit F32: Perk 21's cooldown neutral " + buff.IsNeutral() + ", negative " + buff.IsNegative());
	if(!had)
		thePlayer.RemoveAllBuffsOfType(EET_Perk21InternalCooldown);
}

exec function gmtest_skla_perk21()
{
	GMTest_skla_perk21();
}

// F32 follow-up: Undying's start removes the negative effects already present (legacy's removeIfPresent
// fix of CActor.AddBuffImmunity_AllNegative): a slowdown goes; the sign cooldowns, Whirl's cooldown and
// Attack is the Best Defense's (neutral) cooldown stay. The effects are added by script; Undying is added and
// removed by script, adrenaline and Vitality restored, its cooldown removed.
function GMTest_skla_cleanse()
{
	var witcher : W3PlayerWitcher;
	var focus, vitality : float;
	var perk21, slow, aard, whirl, slowBefore : bool;

	witcher = GetWitcherPlayer();
	focus = witcher.GetStat(BCS_Focus);
	vitality = witcher.GetStat(BCS_Vitality);
	witcher.AddEffectDefault(EET_Perk21InternalCooldown, witcher, "gmtest");
	witcher.AddEffectDefault(EET_Slowdown, NULL, "gmtest");
	witcher.AddEffectDefault(EET_GMAardCooldown, witcher, "gmtest");
	witcher.AddEffectDefault(EET_GMWhirlCooldown, witcher, "gmtest");
	slowBefore = witcher.HasBuff(EET_Slowdown);
	LogChannel('GMTest', "INFO SKL audit F32 follow-up: before Undying Perk 21 cooldown " + witcher.HasBuff(EET_Perk21InternalCooldown) + ", slowdown " + slowBefore + ", Aard cooldown " + witcher.HasBuff(EET_GMAardCooldown) + ", Whirl cooldown " + witcher.HasBuff(EET_GMWhirlCooldown));
	witcher.AddEffectDefault(EET_GMUndyingImmortal, NULL, "gmtest");
	perk21 = witcher.HasBuff(EET_Perk21InternalCooldown);
	slow = witcher.HasBuff(EET_Slowdown);
	aard = witcher.HasBuff(EET_GMAardCooldown);
	whirl = witcher.HasBuff(EET_GMWhirlCooldown);
	witcher.RemoveAllBuffsOfType(EET_GMUndyingImmortal);
	witcher.RemoveAllBuffsOfType(EET_GMUndyingCooldown);
	witcher.RemoveAllBuffsOfType(EET_Perk21InternalCooldown);
	witcher.RemoveAllBuffsOfType(EET_Slowdown);
	witcher.RemoveAllBuffsOfType(EET_GMAardCooldown);
	witcher.RemoveAllBuffsOfType(EET_GMWhirlCooldown);
	witcher.ForceSetStat(BCS_Vitality, vitality);
	if(focus > 0)
		witcher.GainStat(BCS_Focus, focus);
	GMTestReport(slowBefore && !slow, "SKL audit F32 follow-up: Undying's start removes a present slowdown (" + slowBefore + " -> " + slow + ")");
	GMTestReport(aard && whirl && perk21, "SKL audit F32 follow-up: Undying's start keeps the Aard cooldown " + aard + ", Whirl's " + whirl + " and Perk 21's " + perk21);
}

exec function gmtest_skla_cleanse()
{
	GMTest_skla_cleanse();
}

// The same through a killing hit (gmtest_skl07_undying(0) between): phase 0 adds a slowdown, Perk 21's
// cooldown and the Aard cooldown; phase 1 reads them after Undying started.
exec function gmtest_skla_cleanse_hit(phase : int)
{
	var witcher : W3PlayerWitcher;

	witcher = GetWitcherPlayer();
	if(phase == 0)
	{
		witcher.AddEffectDefault(EET_Slowdown, NULL, "gmtest");
		witcher.AddEffectDefault(EET_Perk21InternalCooldown, witcher, "gmtest");
		witcher.AddEffectDefault(EET_GMAardCooldown, witcher, "gmtest");
		LogChannel('GMTest', "INFO SKL audit F32 follow-up: slowdown " + witcher.HasBuff(EET_Slowdown) + ", Perk 21 cooldown " + witcher.HasBuff(EET_Perk21InternalCooldown) + ", Aard cooldown " + witcher.HasBuff(EET_GMAardCooldown));
		return;
	}
	GMTestReport(witcher.HasBuff(EET_GMUndyingImmortal) && !witcher.HasBuff(EET_Slowdown) && witcher.HasBuff(EET_Perk21InternalCooldown) && witcher.HasBuff(EET_GMAardCooldown),
		"SKL audit F32 follow-up: after Undying's start (" + witcher.HasBuff(EET_GMUndyingImmortal) + ") slowdown " + witcher.HasBuff(EET_Slowdown) + ", Perk 21 cooldown " + witcher.HasBuff(EET_Perk21InternalCooldown) + ", Aard cooldown " + witcher.HasBuff(EET_GMAardCooldown));
}

// --- Slice B ---

// Exploding Shield's impulses since the last reset (F13), and the last Aard entity thrown with its drop at
// the throw (F18; the Teleport applies after the throw, so the state reads the entity's height later).
@addField(W3PlayerWitcher)
public var gmTestQuenImpulses : int;
@addField(W3PlayerWitcher)
public var gmTestAardDrop : float;
@addField(W3PlayerWitcher)
public var gmTestAardEntity : W3AardEntity;
@addField(W3PlayerWitcher)
public var gmTestAardThrows : int;

@addMethod(W3PlayerWitcher)
function GMTestResetSignProbes()
{
	gmTestQuenImpulses = 0;
	gmTestAardDrop = 0;
	gmTestAardEntity = NULL;
	gmTestAardThrows = 0;
}

@addMethod(W3PlayerWitcher)
function GMTestSetAardDrop(drop : float, aard : W3AardEntity)
{
	gmTestAardDrop = drop;
	gmTestAardEntity = aard;
	gmTestAardThrows += 1;
}

@wrapMethod(W3PlayerWitcher)
function QuenImpulse( isAlternate : bool, signEntity : W3QuenEntity, source : string, optional forceSkillLevel : int )
{
	gmTestQuenImpulses += 1;
	LogChannel('GMTest', "INFO Quen impulse (alternate " + isAlternate + ", level " + forceSkillLevel + "), stamina " + GetStat(BCS_Stamina) + ", adrenaline " + GetStat(BCS_Focus));
	wrappedMethod(isAlternate, signEntity, source, forceSkillLevel);
}

@wrapMethod(W3AardEntityStateAardCircleCast)
function OnThrowing()
{
	var before, after : Vector;
	var ret : bool;

	before = parent.GetWorldPosition();
	ret = wrappedMethod();
	after = parent.GetWorldPosition();
	if(caster.IsPlayer())
		GetWitcherPlayer().GMTestSetAardDrop(before.Z - after.Z, parent);
	return ret;
}

// The regular Aard's entity too, for comparison (its height is not changed).
@wrapMethod(W3AardEntityStateAardConeCast)
function OnThrowing()
{
	var ret : bool;

	ret = wrappedMethod();
	if(caster.IsPlayer())
		GetWitcherPlayer().GMTestSetAardDrop(0, parent);
	return ret;
}

exec function gmtest_sklb_reset()
{
	GetWitcherPlayer().GMTestResetSignProbes();
	thePlayer.RemoveAllBuffsOfType(EET_GMQuenCooldown);
	thePlayer.RemoveAllBuffsOfType(EET_GMAardCooldown);
	thePlayer.RemoveAllBuffsOfType(EET_GMIgniCooldown);
	thePlayer.RemoveAllBuffsOfType(EET_GMYrdenCooldown);
	thePlayer.RemoveAllBuffsOfType(EET_GMAxiiCooldown);
}

// State for the slice B checks: stamina, adrenaline, whether stamina regen is paused by a sign, Quen's
// state, the impulses counted, the alternate Aard's drop, the cooldowns.
exec function gmtest_sklb_state(optional label : string)
{
	var witcher : W3PlayerWitcher;
	var regen : CBaseGameplayEffect;
	var quen : W3QuenEntity;
	var paused : bool;
	var quenState : name;
	var aardPos, pos : Vector;
	var aard : string;

	witcher = GetWitcherPlayer();
	regen = witcher.GetBuff(EET_AutoStaminaRegen);
	if(regen)
		paused = regen.IsPaused('SignCast');
	quen = (W3QuenEntity)witcher.GetSignEntity(ST_Quen);
	if(quen)
		quenState = quen.GetCurrentStateName();
	aard = "throws " + witcher.gmTestAardThrows + ", drop at the throw " + witcher.gmTestAardDrop;
	if(witcher.gmTestAardEntity)
	{
		aardPos = witcher.gmTestAardEntity.GetWorldPosition();
		pos = witcher.GetWorldPosition();
		aard += ", entity Z - Geralt's Z " + (aardPos.Z - pos.Z);
	}
	LogChannel('GMTest', "INFO SKL audit B " + label + " t=" + theGame.GetEngineTimeAsSeconds() + ": stamina " + witcher.GetStat(BCS_Stamina) + "/" + witcher.GetStatMax(BCS_Stamina) + ", adrenaline " + witcher.GetStat(BCS_Focus) + ", regen effect " + (bool)regen + " paused by a sign " + paused + ", Quen " + quenState + ", impulses " + witcher.gmTestQuenImpulses + ", alternate Aard: " + aard + ", Vitality " + witcher.GetStat(BCS_Vitality) + ", cooldowns Quen " + witcher.HasBuff(EET_GMQuenCooldown) + " Aard " + witcher.HasBuff(EET_GMAardCooldown) + " Igni " + witcher.HasBuff(EET_GMIgniCooldown) + ", casting " + witcher.IsCastingSign() + ", Gryphon " + witcher.HasBuff(EET_GryphonSetBonus));
}

// F13: a scripted hit from the hostile test dummy on Geralt for the given physical damage (to break a
// held alternate Quen).
exec function gmtest_sklb_hit(amount : float)
{
	var witcher : W3PlayerWitcher;
	var npc : CActor;
	var action : W3Action_Attack;

	witcher = GetWitcherPlayer();
	npc = GMTestHostileNpc();
	if(!npc)
		return;
	action = new W3Action_Attack in theGame.damageMgr;
	action.Init(npc, witcher, NULL, GetInvalidUniqueId(), 'attack_light', npc.GetName(), EHRT_Light,
		false, false, '', AST_Jab, ASD_UpDown, true, false, false, false);
	action.AddDamage(theGame.params.DAMAGE_NAME_PHYSICAL, amount);
	action.SetSuppressHitSounds(true);
	action.SetHitAnimationPlayType(EAHA_ForceNo);
	theGame.damageMgr.ProcessAction(action);
	LogChannel('GMTest', "INFO SKL audit F13: hit of " + amount + ", impulses " + witcher.gmTestQuenImpulses + ", stamina " + witcher.GetStat(BCS_Stamina) + ", adrenaline " + witcher.GetStat(BCS_Focus));
	delete action;
}

// F16: RestoreQuen as a save's load calls it (W3PlayerWitcher.OnSpawned), at the given stamina share:
// the restored basic shield costs nothing and starts no cooldown.
exec function gmtest_sklb_restore(staminaShare : float)
{
	var witcher : W3PlayerWitcher;
	var stamina, focus : float;
	var restored : bool;

	witcher = GetWitcherPlayer();
	witcher.FinishQuen(true);
	witcher.RemoveAllBuffsOfType(EET_GMQuenCooldown);
	witcher.ForceSetStat(BCS_Stamina, witcher.GetStatMax(BCS_Stamina));
	if(staminaShare < 1)
		witcher.DrainStamina(ESAT_FixedValue, witcher.GetStatMax(BCS_Stamina) * (1 - staminaShare), 0);
	stamina = witcher.GetStat(BCS_Stamina);
	focus = witcher.GetStat(BCS_Focus);
	restored = witcher.RestoreQuen(500, 20);
	GMTestReport(restored && witcher.IsAnyQuenActive() && AbsF(witcher.GetStat(BCS_Stamina) - stamina) < 1 && witcher.GetStat(BCS_Focus) == focus && !witcher.HasBuff(EET_GMQuenCooldown),
		"SKL audit F16: restored Quen up " + witcher.IsAnyQuenActive() + ", stamina " + stamina + " -> " + witcher.GetStat(BCS_Stamina) + ", adrenaline " + focus + " -> " + witcher.GetStat(BCS_Focus) + ", cooldown " + witcher.HasBuff(EET_GMQuenCooldown));
}

// --- F15: Axii's casting slow motion on every cast (0.6, Delusion 0.15 lower per level) ---

// Logs the time scale each cast of Geralt's Axii sets, and the time scale after the cast removed it
// (test probes on).
@wrapMethod(W3AxiiEntity)
function GMSloMo()
{
	var expected : float;

	wrappedMethod();
	if(GMTestProbes() && owner.GetPlayer())
	{
		expected = 0.6;
		if(owner.CanUseSkill(S_Magic_s17))
			expected -= 0.15 * owner.GetSkillLevel(S_Magic_s17);
		GMTestReport(AbsF(theGame.GetTimeScale() - expected) < 0.001 && gmSloMoOn,
			"SKL audit F15: Axii cast (Delusion level " + owner.GetSkillLevel(S_Magic_s17) + "): time scale " + theGame.GetTimeScale() + " (expected " + expected + "), Geralt's animation multiplier " + gmSpeedMultCauserId);
	}
}

@wrapMethod(W3AxiiEntity)
function GMRemoveSloMo()
{
	var wasOn : bool;

	wasOn = gmSloMoOn;
	wrappedMethod();
	if(GMTestProbes() && wasOn)
		GMTestReport(AbsF(theGame.GetTimeScale() - 1) < 0.001, "SKL audit F15: Axii's slow motion removed: time scale " + theGame.GetTimeScale());
}

// --- F17: the turret's shock area by the cached level; no hit reaction on entering ---

// Logs each hit reaction Yrden gives an NPC (test probes on).
@wrapMethod(CGameplayEntity)
function OnYrdenHit( caster : CGameplayEntity )
{
	if(GMTestProbes() && (CNewNPC)this)
		LogChannel('GMTest', "INFO SKL audit F17: OnYrdenHit on " + ((CActor)this).GetDisplayName() + " at " + theGame.GetEngineTimeAsSeconds());
	wrappedMethod(caster);
}

// Logs the turret's shock area when it starts (test probes on): the area enabled, the cached level, the
// caster's live Magic Trap level.
@wrapMethod(W3YrdenEntityStateYrdenShock)
function OnEnterState( prevStateName : name )
{
	var areas : string;
	var i : int;
	var comp : CComponent;
	var names : array<name>;

	wrappedMethod(prevStateName);
	if(GMTestProbes())
	{
		names.PushBack('Shock_lvl_1');
		names.PushBack('Shock_lvl_2');
		names.PushBack('Shock_lvl_3');
		for(i = 0; i < names.Size(); i += 1)
		{
			comp = parent.GetComponent(names[i]);
			if(comp && comp.IsEnabled())
				areas += " " + names[i];
		}
		GMTestReport(StrLen(areas) > 0 && StrContains(areas, "lvl_" + parent.gmTurretLevel),
			"SKL audit F17: turret started at " + theGame.GetEngineTimeAsSeconds() + ", shock area enabled:" + areas + " (cached level " + parent.gmTurretLevel + ", Geralt's Magic Trap level now " + caster.GetSkillLevel(S_Magic_s03) + ")");
	}
}

// --- F14: legacy's effect values (heavy knockdown, Firestream's burning, the slowdown's defaults) ---

function GMTestAbilityMinMax(ability : name, attr : name, expected : float, label : string)
{
	var min, max : SAbilityAttributeValue;
	var vMin, vMax : float;

	theGame.GetDefinitionsManager().GetAbilityAttributeValue(ability, attr, min, max);
	vMin = min.valueBase + min.valueMultiplicative + min.valueAdditive;
	vMax = max.valueBase + max.valueMultiplicative + max.valueAdditive;
	GMTestReport(AbsF(vMin - expected) < 0.001 && AbsF(vMax - expected) < 0.001,
		"SKL audit F14: " + label + ": " + ability + "." + attr + " " + NoTrailZeros(vMin) + " to " + NoTrailZeros(vMax) + " (expected " + NoTrailZeros(expected) + ")");
}

function GMTest_skld_effects()
{
	GMTestAbilityMinMax('HeavyKnockdownEffect', 'duration', 5, "heavy knockdown");
	GMTestAbilityMinMax('BurningEffect_FireStream', 'FireDamage', 0.027, "Firestream burning per second");
	GMTestAbilityMinMax('BurningEffect_FireStream', 'duration', 3, "Firestream burning");
	GMTestAbilityMinMax('SlowdownEffect', 'duration', 7.5, "slowdown default");
	GMTestAbilityValue('SlowdownEffect', 'slowdown', 0.35);
	GMTestAbilityValue('BurningEffect_FireStream', 'hp_regen_reduction_strength', 200);	// extend keeps 5.x's other attributes
}

exec function gmtest_skld_effects()
{
	GMTest_skld_effects();
}

@addMethod(CBaseGameplayEffect)
function GMTestEffectValue() : SAbilityAttributeValue
{
	return effectValue;
}

// The effects as they reach an enemy (the hostile test dummy, neutral: no resistances): a heavy
// knockdown, Firestream's burning (its ability, as the skill gives it) and a default slowdown, each
// added by script; logs each effect's duration and value.
exec function gmtest_skld_apply()
{
	var npc : CActor;
	var params : SCustomEffectParams;
	var buff : CBaseGameplayEffect;
	var v : SAbilityAttributeValue;

	npc = GMTestHostileNpc();
	if(!npc)
		return;
	npc.AddEffectDefault(EET_HeavyKnockdown, thePlayer, "GMTest");
	buff = npc.GetBuff(EET_HeavyKnockdown);
	GMTestReport(buff && AbsF(buff.GetInitialDuration() - 5) < 0.01, "SKL audit F14: heavy knockdown on the dummy " + npc.HasBuff(EET_HeavyKnockdown) + ", duration " + buff.GetInitialDuration());
	npc.RemoveAllBuffsOfType(EET_HeavyKnockdown);

	params.effectType = EET_Burning;
	params.creator = thePlayer;
	params.sourceName = "GMTest";
	params.customAbilityName = 'BurningEffect_FireStream';
	npc.AddEffectCustom(params);
	buff = npc.GetBuff(EET_Burning);
	if(buff)
		v = buff.GMTestEffectValue();
	GMTestReport(buff && AbsF(buff.GetInitialDuration() - 3) < 0.01 && AbsF(v.valueMultiplicative - 0.027) < 0.0001, "SKL audit F14: Firestream burning on the dummy " + npc.HasBuff(EET_Burning) + " (" + buff.GetAbilityName() + "), duration " + buff.GetInitialDuration() + ", value x" + v.valueMultiplicative + " of max health per second");
	npc.RemoveAllBuffsOfType(EET_Burning);

	npc.AddEffectDefault(EET_Slowdown, thePlayer, "GMTest");
	buff = npc.GetBuff(EET_Slowdown);
	GMTestReport(buff && AbsF(buff.GetInitialDuration() - 7.5) < 0.01 && AbsF(((W3Effect_Slowdown)buff).GMGetSlowdown() - 0.35) < 0.001, "SKL audit F14: default slowdown on the dummy " + npc.HasBuff(EET_Slowdown) + ", duration " + buff.GetInitialDuration() + ", slowdown " + ((W3Effect_Slowdown)buff).GMGetSlowdown());
	npc.RemoveAllBuffsOfType(EET_Slowdown);
}

// After a real Firestream on the dummy: its burning's ability, duration and value.
exec function gmtest_skld_burn()
{
	var npc : CActor;
	var buff : CBaseGameplayEffect;
	var v : SAbilityAttributeValue;

	npc = GMTestHostileNpc();
	if(!npc)
		return;
	buff = npc.GetBuff(EET_Burning);
	if(!buff)
	{
		LogChannel('GMTest', "INFO SKL audit F14: the dummy is not burning");
		return;
	}
	v = buff.GMTestEffectValue();
	GMTestReport(buff.GetAbilityName() == 'BurningEffect_FireStream' && AbsF(buff.GetInitialDuration() - 3) < 0.01 && AbsF(v.valueMultiplicative - 0.027) < 0.0001,
		"SKL audit F14: the dummy's burning from Firestream: " + buff.GetAbilityName() + ", source " + buff.GetSourceName() + ", duration " + buff.GetInitialDuration() + " (left " + buff.GetDurationLeft() + "), value x" + v.valueMultiplicative + " of max health per second");
}
