// In-game tests for ALCH's decoctions (ALCH-09 to ALCH-13). See docs/features/alch.md.

// Drinks a decoction (clears the locked toxicity first, so several can be tested in a row).
function GMTestAlchDecoction(itemName : name, effectType : EEffectType) : CBaseGameplayEffect
{
	thePlayer.RemoveAllBuffsOfType(effectType);
	return GMTestAlchDrink(itemName);
}

// A scripted light sword hit of Geralt's on an NPC (crit optional); the NPC's Vitality is restored.
function GMTestAlchSwordHit(npc : CActor, crit : bool)
{
	var w : W3PlayerWitcher;
	var action : W3Action_Attack;
	var id : SItemUniqueId;

	w = GetWitcherPlayer();
	w.GetItemEquippedOnSlot(EES_SteelSword, id);
	action = new W3Action_Attack in theGame.damageMgr;
	action.Init(w, npc, NULL, id, 'attack_light', w.GetName(), EHRT_Light, false, false, 'attack_light', AST_Jab, ASD_UpDown, true, false, false, false);
	if(crit)
		action.SetCriticalHit();
	action.SetSuppressHitSounds(true);
	action.SetHitAnimationPlayType(EAHA_ForceNo);
	theGame.damageMgr.ProcessAction(action);
	delete action;
	npc.ForceSetStat(BCS_Vitality, npc.GetStatMax(BCS_Vitality));
}

// A scripted fist hit of Geralt's on an NPC (his fists item as the weapon); the NPC's Vitality is restored.
function GMTestAlchFistHit(npc : CActor)
{
	var w : W3PlayerWitcher;
	var action : W3Action_Attack;
	var fists : array<SItemUniqueId>;

	w = GetWitcherPlayer();
	fists = w.inv.GetItemsByCategory('fist');
	if(fists.Size() == 0)
	{
		LogChannel('GMTest', "FAIL ALCH-10 Geralt has no fists item");
		return;
	}
	action = new W3Action_Attack in theGame.damageMgr;
	action.Init(w, npc, NULL, fists[0], 'attack_light', w.GetName(), EHRT_Light, false, false, 'attack_light', AST_Jab, ASD_UpDown, true, false, false, false);
	action.SetSuppressHitSounds(true);
	action.SetHitAnimationPlayType(EAHA_ForceNo);
	theGame.damageMgr.ProcessAction(action);
	LogChannel('GMTest', "INFO ALCH-10 fist hit: melee " + action.IsActionMelee() + ", damage " + NoTrailZeros(action.processedDmg.vitalityDamage) + ", fists " + w.inv.IsItemFists(fists[0]));
	delete action;
	npc.ForceSetStat(BCS_Vitality, npc.GetStatMax(BCS_Vitality));
}

// Geralt's light sword hit on the NPC; returns the Vitality it lost beyond the hit's damage (ArchGriffin's
// drain), and in left its Vitality after the hit's damage; heals it afterwards.
function GMTestAlchSwordHitExtra(npc : CActor, out left : float) : float
{
	var w : W3PlayerWitcher;
	var action : W3Action_Attack;
	var id : SItemUniqueId;
	var before, dealt : float;

	w = GetWitcherPlayer();
	npc.ForceSetStat(BCS_Vitality, npc.GetStatMax(BCS_Vitality));
	before = npc.GetStat(BCS_Vitality);
	w.GetItemEquippedOnSlot(EES_SteelSword, id);
	action = new W3Action_Attack in theGame.damageMgr;
	action.Init(w, npc, NULL, id, 'attack_light', w.GetName(), EHRT_Light, false, false, 'attack_light', AST_Jab, ASD_UpDown, true, false, false, false);
	action.SetSuppressHitSounds(true);
	action.SetHitAnimationPlayType(EAHA_ForceNo);
	theGame.damageMgr.ProcessAction(action);
	dealt = action.processedDmg.vitalityDamage;
	delete action;
	left = before - dealt;
	dealt = before - npc.GetStat(BCS_Vitality) - dealt;
	npc.ForceSetStat(BCS_Vitality, npc.GetStatMax(BCS_Vitality));
	return dealt;
}

function GMTestAlchCount(abl : name) : int
{
	return thePlayer.GetAbilityCount(abl);
}

// ALCH-10 against the test dummy (gmtest_dummy("human"), then gmtest_dummy_neutral(), Geralt in combat).
exec function gmtest_alch10()
{
	var npc : CActor;
	var n, i, cap : int;

	npc = GMTestDummy();
	if(!npc)
	{
		LogChannel('GMTest', "FAIL ALCH-10 no test dummy (gmtest_dummy(\"human\") first)");
		return;
	}
	LogChannel('GMTest', "INFO ALCH-10 combat " + thePlayer.IsInCombat() + ", threatened " + thePlayer.IsThreatened());
	thePlayer.ForceSetStat(BCS_Vitality, thePlayer.GetStatMax(BCS_Vitality));

	// Katakan.
	GMTestAlchDecoction('Mutagen 1', EET_Mutagen01);
	GMTestReport(GMTestAlchCount('Mutagen01Effect') == 0, "ALCH-10 Katakan: no stack when drunk (" + GMTestAlchCount('Mutagen01Effect') + ")");
	GMTestAlchSwordHit(npc, false); GMTestAlchSwordHit(npc, false); GMTestAlchSwordHit(npc, false);
	GMTestReport(GMTestAlchCount('Mutagen01Effect') == 3 && !thePlayer.HasAbility('KatakanBonusEffect'), "ALCH-10 Katakan: 3 hits, 3 stacks (" + GMTestAlchCount('Mutagen01Effect') + ")");
	GMTestAlchSwordHit(npc, false); GMTestAlchSwordHit(npc, false); GMTestAlchSwordHit(npc, false);
	GMTestReport(GMTestAlchCount('Mutagen01Effect') == 5 && thePlayer.HasAbility('KatakanBonusEffect'), "ALCH-10 Katakan: capped at 5 stacks with the crit damage bonus (" + GMTestAlchCount('Mutagen01Effect') + ", HUD " + ((W3Mutagen01_Effect)thePlayer.GetBuff(EET_Mutagen01)).GMGetStacks() + "%)");
	GMTestAlchSwordHit(npc, true);
	GMTestReport(GMTestAlchCount('Mutagen01Effect') == 0 && !thePlayer.HasAbility('KatakanBonusEffect'), "ALCH-10 Katakan: a crit resets it");
	thePlayer.RemoveAllBuffsOfType(EET_Mutagen01);

	// Water Hag.
	GMTestAlchDecoction('Mutagen 5', EET_Mutagen05);
	GMTestAlchSwordHit(npc, false);
	n = GMTestAlchCount('Mutagen05Effect');
	GMTestReport(n == 20, "ALCH-10 Water Hag: a hit, 20 stacks (+10%) (" + n + ", HUD " + ((W3Mutagen05_Effect)thePlayer.GetBuff(EET_Mutagen05)).GMGetStacks() + "%)");
	GMTestDefHit(npc, thePlayer, false, 0);
	GMTestReport(GMTestAlchCount('Mutagen05Effect') == n - 5, "ALCH-10 Water Hag: a hit for 5% of Vitality takes 5 stacks off (" + GMTestAlchCount('Mutagen05Effect') + ")");
	thePlayer.ForceSetStat(BCS_Vitality, thePlayer.GetStatMax(BCS_Vitality));
	for(n = 0; n < 12; n += 1)
		GMTestAlchSwordHit(npc, false);
	GMTestReport(GMTestAlchCount('Mutagen05Effect') == 200, "ALCH-10 Water Hag: capped at 200 stacks (+100%) (" + GMTestAlchCount('Mutagen05Effect') + ")");
	thePlayer.RemoveAllBuffsOfType(EET_Mutagen05);
	GMTestReport(GMTestAlchCount('Mutagen05Effect') == 0, "ALCH-10 Water Hag: the stacks go with the decoction");

	// Wyvern.
	GMTestAlchDecoction('Mutagen 10', EET_Mutagen10);
	GMTestAlchSwordHit(npc, false);
	GMTestReport(GMTestAlchCount('Mutagen10Effect') == 0, "ALCH-10 Wyvern: a melee hit adds nothing (" + GMTestAlchCount('Mutagen10Effect') + ")");
	GMDecoctionsOnSignCast(); GMDecoctionsOnSignCast();
	GMTestReport(GMTestAlchCount('Mutagen10Effect') == 2, "ALCH-10 Wyvern: two sign casts, 2 stacks (" + GMTestAlchCount('Mutagen10Effect') + ", HUD " + ((W3Mutagen10_Effect)thePlayer.GetBuff(EET_Mutagen10)).GMGetStacks() + "%)");
	GMTestAlchSwordHit(npc, false);
	GMTestReport(GMTestAlchCount('Mutagen10Effect') == 0, "ALCH-10 Wyvern: a melee hit clears it (" + GMTestAlchCount('Mutagen10Effect') + ")");
	// Audit F18: a fist hit neither clears the sign stacks nor adds 5.x's per-hit stack (the OnTakeDamage wrapper).
	GMDecoctionsOnSignCast(); GMDecoctionsOnSignCast();
	GMTestAlchFistHit(npc);
	GMTestReport(GMTestAlchCount('Mutagen10Effect') == 2, "ALCH-10 audit F18 Wyvern: two sign casts, then a fist hit: 2 stacks (" + GMTestAlchCount('Mutagen10Effect') + ")");
	thePlayer.RemoveAllBuffsOfType(EET_Mutagen10);

	// Alghoul.
	GMTestAlchDecoction('Mutagen 15', EET_Mutagen15);
	GMTestReport(GMTestAlchCount('Mutagen15Effect') == 0, "ALCH-10 Alghoul: no ability when drunk in combat (" + GMTestAlchCount('Mutagen15Effect') + ")");
	GMTestAlchSwordHit(npc, false);
	n = GMTestAlchCount('Mutagen15Effect');
	GMTestReport(n > 0, "ALCH-10 Alghoul: a hit adds stacks (" + n + ", HUD " + ((W3Mutagen15_Effect)thePlayer.GetBuff(EET_Mutagen15)).GMGetStacks() + "%)");
	GMTestDefHit(npc, thePlayer, false, 0);
	GMTestReport(GMTestAlchCount('Mutagen15Effect') < n, "ALCH-10 Alghoul: damage taken takes stacks off (" + GMTestAlchCount('Mutagen15Effect') + ")");
	for(i = 0; i < 120; i += 1)
		GMTestAlchSwordHit(npc, false);
	cap = RoundMath(GMTestAlchValue('Mutagen15Effect', 'mutagen15_max_stack'));
	GMTestReport(cap > 0 && GMTestAlchCount('Mutagen15Effect') == cap, "ALCH-10 audit F24 Alghoul: capped at " + cap + " stacks after 120 hits (" + GMTestAlchCount('Mutagen15Effect') + ")");
	thePlayer.ForceSetStat(BCS_Vitality, thePlayer.GetStatMax(BCS_Vitality));
	thePlayer.RemoveAllBuffsOfType(EET_Mutagen15);

	// Forktail.
	GMTestAlchDecoction('Mutagen 17', EET_Mutagen17);
	GMTestAlchSwordHit(npc, false); GMTestAlchSwordHit(npc, false);
	GMTestReport(GMTestAlchCount('Mutagen17Effect') == 2, "ALCH-10 Forktail: two hits, 2 stacks (" + GMTestAlchCount('Mutagen17Effect') + ", HUD " + ((W3Mutagen17_Effect)thePlayer.GetBuff(EET_Mutagen17)).GMGetStacks() + "%)");
	for(i = 0; i < 10; i += 1)
		GMTestAlchSwordHit(npc, false);
	cap = RoundMath(GMTestAlchValue('Mutagen17Effect', 'mutagen17_max_stack'));
	GMTestReport(cap > 0 && GMTestAlchCount('Mutagen17Effect') == cap, "ALCH-10 audit F24 Forktail: capped at " + cap + " stacks after 12 hits (" + GMTestAlchCount('Mutagen17Effect') + ")");
	GMDecoctionsOnSignCast();
	GMTestReport(GMTestAlchCount('Mutagen17Effect') == 0, "ALCH-10 Forktail: a sign cast clears it");
	GMTestAlchSwordHit(npc, false);
	GetWitcherPlayer().GMClearDecoctionStacks();
	GMTestReport(GMTestAlchCount('Mutagen17Effect') == 0, "ALCH-10 combat end clears the stacks");
	thePlayer.RemoveAllBuffsOfType(EET_Mutagen17);
	GetWitcherPlayer().SetToxicityOffset(0);
}

// ALCH-10 data (situation-free; in the regression).
function GMTest_alch10()
{
	GMTestAlchCheck('Mutagen01Effect', 'critical_hit_chance', 0.05, "ALCH-10 Katakan DL6:");
	GMTestAlchCheck('KatakanBonusEffect', 'critical_hit_damage_bonus', 0.5, "ALCH-10 Katakan");
	GMTestAlchCheck('Mutagen05Effect', 'mutagen05_max_stack', 200, "ALCH-10 Water Hag");
	GMTestAlchCheck('Mutagen10Effect', 'mutagen10_max_stack', 3, "ALCH-10 Wyvern");
	GMTestAlchCheck('Mutagen17Effect', 'mutagen17_max_stack', 5, "ALCH-10 Forktail");
}

// ALCH-11 data (situation-free; in the regression).
function GMTest_alch11()
{
	GMTestAlchCheck('Mutagen09Effect', 'mutagen09_bonus_greater', 25, "ALCH-11 Foglet");
	GMTestAlchCheck('Mutagen09Effect', 'spell_power', 0, "ALCH-11 Foglet: no weather intensity");
	GMTestAlchCheck('Mutagen14Effect', 'mutagen14_bonus', 0.5, "ALCH-11 Succubus");
	GMTestAlchCheck('Mutagen19Effect', 'quen_power_bonus', 0.5, "ALCH-11 Wraith");
	GMTestAlchCheck('Mutagen22Effect', 'mutagen22_max_stack', 100, "ALCH-11 Ancient Leshen");
}

// ALCH-11 with a test dummy (gmtest_dummy("wraith") or "human", gmtest_dummy_neutral(), setlevel(30) first for
// the mutagen slots): Foglet's recount from the slots, Wraith's Quen from behind and near a specter,
// Ancient Leshen's stacks.
exec function gmtest_alch11()
{
	var w : W3PlayerWitcher;
	var npc : CActor;
	var ids : array<SItemUniqueId>;
	var foglet : W3Mutagen09_Effect;
	var wraith : W3Mutagen19_Effect;
	var quens, n : int;
	var pos : Vector;
	var bonus : SAbilityAttributeValue;

	w = GetWitcherPlayer();
	npc = GMTestDummy();
	if(!npc)
	{
		LogChannel('GMTest', "FAIL ALCH-11 no test dummy");
		return;
	}
	// Foglet.
	foglet = (W3Mutagen09_Effect)GMTestAlchDecoction('Mutagen 9', EET_Mutagen09);
	GMTestReport(foglet.GMGetM09Bonus() == 0, "ALCH-11 Foglet without blue mutagens: +" + foglet.GMGetM09Bonus());
	ids = w.inv.AddAnItem('Greater mutagen blue', 1);
	w.EquipItem(ids[0], EES_SkillMutagen1);
	GMTestReport(foglet.GMGetM09Bonus() == 25, "ALCH-11 Foglet with a greater blue mutagen equipped: +" + foglet.GMGetM09Bonus() + " sign damage (recounted on equipping)");
	w.UnequipItem(ids[0]);
	GMTestReport(foglet.GMGetM09Bonus() == 0, "ALCH-11 Foglet after unequipping: +" + foglet.GMGetM09Bonus());
	w.EquipItem(ids[0], EES_SkillMutagen1);
	w.RemoveAllBuffsOfType(EET_Mutagen09);

	// Wraith: see gmtest_alch11_wraith_place/_hit (a teleport takes effect on the next frame).

	// Ancient Leshen.
	GMTestAlchDecoction('Mutagen 22', EET_Mutagen22);
	GMDecoctionsOnSignCast();
	n = GMTestAlchCount('Mutagen22Effect');
	GMTestReport(n == 20, "ALCH-11 Ancient Leshen: a sign cast, 20 stacks (+10%) (" + n + ", HUD " + ((W3Mutagen22_Effect)w.GetBuff(EET_Mutagen22)).GMGetStacks() + "%)");
	w.ForceSetStat(BCS_Vitality, w.GetStatMax(BCS_Vitality));
	GMTestDefHit(npc, w, false, 0);
	GMTestReport(GMTestAlchCount('Mutagen22Effect') == n - 5, "ALCH-11 Ancient Leshen: a hit for 5% takes 5 stacks off (" + GMTestAlchCount('Mutagen22Effect') + ")");
	w.GMClearDecoctionStacks();
	GMTestReport(GMTestAlchCount('Mutagen22Effect') == 0, "ALCH-11 Ancient Leshen: combat end clears it");
	w.RemoveAllBuffsOfType(EET_Mutagen22);
	w.SetToxicityOffset(0);
	w.ForceSetStat(BCS_Vitality, w.GetStatMax(BCS_Vitality));
}

// ALCH-11 Foglet's damage on a real sign: gmtest_alch11_foglet(true) drinks Foglet (a greater blue mutagen
// must be equipped, gmtest_alch11 leaves one) or removes it, and resets the dummy's Vitality; cast Igni at the
// dummy, then gmtest_alch11_dmg() reports the Vitality it lost.
exec function gmtest_alch11_foglet(on : bool)
{
	var ids : array<SItemUniqueId>;
	var id : SItemUniqueId;

	if(!GetWitcherPlayer().GetItemEquippedOnSlot(EES_SkillMutagen1, id))
	{
		ids = GetWitcherPlayer().inv.AddAnItem('Greater mutagen blue', 1);
		GetWitcherPlayer().EquipItem(ids[0], EES_SkillMutagen1);
	}
	thePlayer.RemoveAllBuffsOfType(EET_Mutagen09);
	if(on)
		GMTestAlchDecoction('Mutagen 9', EET_Mutagen09);
	GMTestDummy().ForceSetStat(BCS_Vitality, GMTestDummy().GetStatMax(BCS_Vitality));
	GetWitcherPlayer().SetToxicityOffset(0);
}

exec function gmtest_alch11_dmg()
{
	var npc : CActor;
	var bonus : float;
	var slots : array<SMutagenSlot>;
	var i, n : int;

	npc = GMTestDummy();

	slots = GetWitcherPlayer().GetPlayerSkillMutagens();
	for(i = 0; i < slots.Size(); i += 1)
		if(slots[i].item != GetInvalidUniqueId())
			n += 1;
	if(thePlayer.HasBuff(EET_Mutagen09))
		bonus = ((W3Mutagen09_Effect)thePlayer.GetBuff(EET_Mutagen09)).GMGetM09Bonus();
	LogChannel('GMTest', "INFO ALCH-11 dummy lost " + NoTrailZeros(RoundTo(npc.GetStatMax(BCS_Vitality) - npc.GetStat(BCS_Vitality), 1)) + " Vitality, Foglet " + thePlayer.HasBuff(EET_Mutagen09) + " (+" + bonus + ", mutagens in slots " + n + ")");
	npc.RemoveAllBuffsOfType(EET_Burning);
}

// ALCH-11 Wraith, in steps: gmtest_alch11_wraith_place(behind) drinks the Wraith decoction (if not active)
// and turns Geralt to face the test dummy or to turn his back to it; gmtest_alch11_wraith_hit(expectQuen) in a later
// call makes the dummy hit him (5% of his Vitality) and checks whether a free Quen was cast.
exec function gmtest_alch11_wraith_place(behind : bool)
{
	var w : W3PlayerWitcher;
	var pos : Vector;
	var bonus : SAbilityAttributeValue;

	w = GetWitcherPlayer();
	if(!w.HasBuff(EET_Mutagen19))
		GMTestAlchDecoction('Mutagen 19', EET_Mutagen19);
	w.SetToxicityOffset(0);
	pos = GMTestDummy().GetWorldPosition();
	if(behind)	// Geralt turns his back to the dummy (the frozen dummy does not move)
		w.TeleportWithRotation(w.GetWorldPosition(), VecToRotation(w.GetWorldPosition() - pos));
	else
		w.TeleportWithRotation(w.GetWorldPosition(), VecToRotation(pos - w.GetWorldPosition()));
	bonus = ((W3Mutagen19_Effect)w.GetBuff(EET_Mutagen19)).GMGetQuenPowerBonus();
	LogChannel('GMTest', "INFO ALCH-11 Wraith: dummy specter " + GMIsSpecter(GMTestDummy()) + ", hostile enemies " + w.GetHostileEnemiesCount() + ", Quen power bonus " + bonus.valueMultiplicative);
}

// Free Quens from the Wraith decoction so far (test-only counter; audit F23: kept out of the production code).
@addField(W3PlayerWitcher)
public var gmWraithQuens : int;

@wrapMethod(W3PlayerWitcher)
function GMCastFreeQuen()
{
	wrappedMethod();
	gmWraithQuens += 1;
}

exec function gmtest_alch11_wraith_hit(expectQuen : bool)
{
	var w : W3PlayerWitcher;
	var quens : int;

	w = GetWitcherPlayer();
	quens = w.gmWraithQuens;
	w.ForceSetStat(BCS_Vitality, w.GetStatMax(BCS_Vitality));
	GMTestDefHit(GMTestDummy(), w, false, 0);
	GMTestReport((w.gmWraithQuens > quens) == expectQuen, "ALCH-11 Wraith: free Quen " + expectQuen + " (cast " + (w.gmWraithQuens - quens) + ", attacker behind " + w.IsAttackerAtBack(GMTestDummy()) + ", Quen up " + w.IsAnyQuenActive() + ", Vitality " + NoTrailZeros(RoundTo(100 * w.GetStatPercents(BCS_Vitality), 1)) + "%)");
}

// The damage probe's steps since the last call (switch the probes on first, gmtest_probes(true)): each
// damage type's raw value as CalculateDamage receives it; then resets.
exec function gmtest_alch_probe(label : string)
{
	var i : int;

	for(i = 0; i < thePlayer.gmTestDmgSteps.Size(); i += 1)
		LogChannel('GMTest', "INFO ALCH probe " + label + ": " + thePlayer.gmTestDmgSteps[i].dmgType + " raw " + NoTrailZeros(RoundTo(thePlayer.gmTestDmgSteps[i].rawIn, 2)) + " result " + NoTrailZeros(RoundTo(thePlayer.gmTestDmgSteps[i].result, 2)));
	thePlayer.GMTestDmgReset();
}

// ALCH-12 data (situation-free; in the regression).
function GMTest_alch12()
{
	GMTestAlchCheck('Mutagen04Effect', 'attackCostIncrease', 0.5, "ALCH-12 ArchGriffin");
	GMTestAlchCheck('Mutagen04Effect', 'healthReductionPerc', 0.001, "ALCH-12 ArchGriffin");
	GMTestAlchCheck('TrollBonusEffect', 'vitalityCombatRegen', 80, "ALCH-12 Troll");
	GMTestAlchCheck('Mutagen12Effect', 'm12_threshold', 0.333, "ALCH-12 Troll");
	GMTestAlchCheck('Mutagen13Effect', 'mutagen13_max_stack', 10, "ALCH-12 Noonwraith");
	GMTestAlchCheck('Mutagen18Effect', 'mutagen18_max_stack', 10, "ALCH-12 Grave Hag (capped, DL6)");
	GMTestAlchCheck('Mutagen21Effect', 'healingRatio', 0.001, "ALCH-12 Ekhidna");
	GMTestAlchCheck('Mutagen25Effect', 'mutagen25_bonus_greater', 0.05, "ALCH-12 Nekker Warrior");
	GMTestAlchCheck('Mutagen25Effect', 'attack_power', 0, "ALCH-12 Nekker Warrior: no horseback attack power");
}

// ALCH-12 with the test dummy (gmtest_dummy("human"), gmtest_dummy_neutral(), setlevel(30)): costs, the
// ArchGriffin hit, Troll's bonus held, kills stacks (the hook called), Ekhidna's heal, the slot decoctions.
exec function gmtest_alch12()
{
	var w : W3PlayerWitcher;
	var npc : CActor;
	var ids : array<SItemUniqueId>;
	var base, baseDodge, cost, vit, vitMax, hp, extra : float;
	var i : int;

	w = GetWitcherPlayer();
	npc = GMTestDummy();
	if(!npc)
	{
		LogChannel('GMTest', "FAIL ALCH-12 no test dummy");
		return;
	}
	// ArchGriffin: +50% attack costs, the hit's share of Vitality.
	base = w.GetStaminaActionCost(ESAT_LightAttack, '', 0);
	baseDodge = w.GetStaminaActionCost(ESAT_Dodge, '', 0);
	GMTestAlchDecoction('Mutagen 4', EET_Mutagen04);
	cost = w.GetStaminaActionCost(ESAT_LightAttack, '', 0);
	GMTestReport(AbsF(cost - base * 1.5) < 0.01, "ALCH-12 ArchGriffin: light attack " + base + " -> " + cost);
	GMTestReport(AbsF(w.GetStaminaActionCost(ESAT_Dodge, '', 0) - baseDodge) < 0.01, "ALCH-12 audit F24 ArchGriffin: dodge unchanged, " + baseDodge + " before drinking -> " + w.GetStaminaActionCost(ESAT_Dodge, '', 0));
	// The hit's extra drain: 0.1% of the victim's Vitality (after the hit's damage) per stamina point.
	extra = GMTestAlchSwordHitExtra(npc, hp);
	GMTestReport(cost > 0 && AbsF(extra - hp * 0.001 * cost) < MaxF(1, hp * 0.001 * cost * 0.02),
		"ALCH-12 ArchGriffin hit: extra drain " + NoTrailZeros(RoundTo(extra, 1)) + " (expected " + NoTrailZeros(RoundTo(hp * 0.001 * cost, 1)) + ": " + NoTrailZeros(RoundTo(hp, 1)) + " Vitality left after the hit x 0.1% x " + NoTrailZeros(cost) + " stamina)");
	w.RemoveAllBuffsOfType(EET_Mutagen04);
	extra = GMTestAlchSwordHitExtra(npc, hp);
	GMTestReport(AbsF(extra) < 1, "ALCH-12 ArchGriffin ended: no extra drain (" + NoTrailZeros(RoundTo(extra, 1)) + ")");

	// Troll: on at or below 33% stamina in combat, and it stays on.
	GMTestAlchDecoction('Mutagen 12', EET_Mutagen12);
	w.ForceSetStat(BCS_Stamina, w.GetStatMax(BCS_Stamina) * 0.2);
	((W3Mutagen12_Effect)w.GetBuff(EET_Mutagen12)).GMManageAdditionalBonus();
	GMTestReport(w.HasAbility('TrollBonusEffect'), "ALCH-12 Troll: bonus on at 20% stamina in combat");
	((W3Mutagen12_Effect)w.GetBuff(EET_Mutagen12)).GMManageAdditionalBonus();
	GMTestReport(w.HasAbility('TrollBonusEffect'), "ALCH-12 Troll DL12: still on at the next check");
	w.ForceSetStat(BCS_Stamina, w.GetStatMax(BCS_Stamina));
	((W3Mutagen12_Effect)w.GetBuff(EET_Mutagen12)).GMManageAdditionalBonus();
	GMTestReport(!w.HasAbility('TrollBonusEffect'), "ALCH-12 Troll: off at full stamina");
	w.RemoveAllBuffsOfType(EET_Mutagen12);

	// Noonwraith and Grave Hag: a kill adds a stack per hostile in range.
	GMTestAlchDecoction('Mutagen 13', EET_Mutagen13);
	GMTestAlchDecoction('Mutagen 18', EET_Mutagen18);
	GMDecoctionsOnKill();
	GMTestReport(w.GMGetNumHostilesInRange() > 0, "ALCH-12 audit F24 a hostile in range for the kill checks (" + w.GMGetNumHostilesInRange() + ")");
	GMTestReport(GMTestAlchCount('Mutagen13Effect') == w.GMGetNumHostilesInRange() && GMTestAlchCount('Mutagen18Effect') == w.GMGetNumHostilesInRange(), "ALCH-12 Noonwraith and Grave Hag: a kill adds " + GMTestAlchCount('Mutagen13Effect') + " and " + GMTestAlchCount('Mutagen18Effect') + " (hostiles in range " + w.GMGetNumHostilesInRange() + ")");
	for(i = 0; i < 15; i += 1)
		GMDecoctionsOnKill();
	GMTestReport(GMTestAlchCount('Mutagen18Effect') == 10, "ALCH-12 Grave Hag capped at 10 stacks (+50) (" + GMTestAlchCount('Mutagen18Effect') + ")");
	GMTestReport(GMTestAlchCount('Mutagen13Effect') == 10, "ALCH-12 audit F24 Noonwraith capped at 10 stacks (" + GMTestAlchCount('Mutagen13Effect') + ")");
	w.GMClearDecoctionStacks();
	w.RemoveAllBuffsOfType(EET_Mutagen13);
	w.RemoveAllBuffsOfType(EET_Mutagen18);

	// Ekhidna: 0.1% of maximum Vitality per stamina point spent, in combat.
	GMTestAlchDecoction('Mutagen 21', EET_Mutagen21);
	vitMax = w.GetStatMax(BCS_Vitality);
	w.ForceSetStat(BCS_Vitality, vitMax * 0.5);
	w.ForceSetStat(BCS_Stamina, w.GetStatMax(BCS_Stamina));
	vit = w.GetStat(BCS_Vitality);
	w.DrainStamina(ESAT_FixedValue, 20, 0);
	GMTestReport(AbsF(w.GetStat(BCS_Vitality) - vit - vitMax * 0.001 * 20) < 1, "ALCH-12 Ekhidna: 20 stamina spent heals " + NoTrailZeros(RoundTo(w.GetStat(BCS_Vitality) - vit, 1)) + " (expected " + NoTrailZeros(vitMax * 0.02) + ")");
	w.RemoveAllBuffsOfType(EET_Mutagen21);
	w.ForceSetStat(BCS_Vitality, vitMax);

	// Basilisk and Nekker Warrior: green and red mutagens in the slots.
	ids = w.inv.AddAnItem('Greater mutagen green', 1);
	w.EquipItem(ids[0], EES_SkillMutagen2);
	ids = w.inv.AddAnItem('Greater mutagen red', 1);
	w.EquipItem(ids[0], EES_SkillMutagen3);
	GMTestAlchDecoction('Mutagen 23', EET_Mutagen23);
	GMTestReport(GMTestAlchCount('Mutagen23Effect') == 4, "ALCH-12 Basilisk: a greater green mutagen, 4 copies (+16 regen) (" + GMTestAlchCount('Mutagen23Effect') + ")");
	w.RemoveAllBuffsOfType(EET_Mutagen23);
	base = w.GetStaminaActionCost(ESAT_Dodge, '', 0);
	GMTestAlchDecoction('Mutagen 25', EET_Mutagen25);
	cost = w.GetStaminaActionCost(ESAT_Dodge, '', 0);
	GMTestReport(AbsF(cost - base * 0.95) < 0.01, "ALCH-12 Nekker Warrior: a greater red mutagen, dodge " + base + " -> " + cost + " (-5%)");
	w.RemoveAllBuffsOfType(EET_Mutagen25);
	w.SetToxicityOffset(0);
}

// ALCH-12 ArchGriffin's hit: the dummy's Vitality loss from one scripted light hit without and with the decoction.
exec function gmtest_alch12_griffin()
{
	var w : W3PlayerWitcher;
	var npc : CActor;
	var id : SItemUniqueId;
	var action : W3Action_Attack;
	var loss : array<float>;
	var i : int;

	w = GetWitcherPlayer();
	npc = GMTestDummy();
	w.RemoveAllBuffsOfType(EET_Mutagen04);
	for(i = 0; i < 2; i += 1)
	{
		if(i == 1)
			GMTestAlchDecoction('Mutagen 4', EET_Mutagen04);
		npc.ForceSetStat(BCS_Vitality, npc.GetStatMax(BCS_Vitality));
		w.GetItemEquippedOnSlot(EES_SteelSword, id);
		action = new W3Action_Attack in theGame.damageMgr;
		action.Init(w, npc, NULL, id, 'attack_light', w.GetName(), EHRT_Light, false, false, 'attack_light', AST_Jab, ASD_UpDown, true, false, false, false);
		action.SetSuppressHitSounds(true);
		action.SetHitAnimationPlayType(EAHA_ForceNo);
		theGame.damageMgr.ProcessAction(action);
		delete action;
		loss.PushBack(npc.GetStatMax(BCS_Vitality) - npc.GetStat(BCS_Vitality));
	}
	GMTestReport(loss[1] - loss[0] > 900, "ALCH-12 ArchGriffin: a light hit takes " + NoTrailZeros(RoundTo(loss[0], 1)) + " without, " + NoTrailZeros(RoundTo(loss[1], 1)) + " with the decoction (0.1% of 100000 per stamina point, about 1000 more; the hit's own damage varies)");
	w.RemoveAllBuffsOfType(EET_Mutagen04);
	w.SetToxicityOffset(0);
	npc.ForceSetStat(BCS_Vitality, npc.GetStatMax(BCS_Vitality));
}

// ALCH-13 and ALCH-09 data (situation-free; in the regression).
function GMTest_alch13()
{
	GMTestAlchCheck('Mutagen02Effect', 'mutagen02_resist_reduction', 0.01, "ALCH-13 Arachas");
	GMTestAlchCheck('Mutagen02Effect', 'resistGainRate', 0, "ALCH-13 Arachas: no carry-weight resistance");
	GMTestAlchCheck('Mutagen11Effect', 'damageIncrease', 0.5, "ALCH-13 Doppler");
	GMTestAlchCheck('Mutagen16Effect', 'mutagen16_health_prc', 0.15, "ALCH-13 Fiend");
	GMTestAlchCheck('Mutagen16Effect', 'encumbrance', 0, "ALCH-13 Fiend: no carry weight");
	GMTestAlchCheck('Mutagen20Effect', 'fire_resistance_perc', 0.5, "ALCH-13 Elemental");
	GMTestAlchCheck('Mutagen24Effect', 'm24_hp_threshold', 0.2, "ALCH-13 Werewolf");
	GMTestAlchCheck('Mutagen26Effect', 'returned_damage', 0.25, "ALCH-13 Leshen (DL6)");
	GMTestAlchCheck('Mutagen27Effect', 'mutagen27_bonus_duration', 2, "ALCH-13 Griffin");
	GMTestAlchCheck('Mutagen28Effect', 'mutagen28_dmg_mult', 0.6, "ALCH-13 Reliever's");
	GMTestAlchCheck('Mutagen07Effect', 'lifeLeech', 0.1, "ALCH-09 Ekimmara");
	GMTest_alch13_state();
}

// Nightwraith's new dose wipes its stacks; the load-time cleanup removes 5.x's leftovers.
function GMTest_alch13_state()
{
	var w : W3PlayerWitcher;
	var abl : name;

	w = GetWitcherPlayer();
	GMTestAlchDecoction('Mutagen 6', EET_Mutagen06);
	abl = w.GetBuff(EET_Mutagen06).GetAbilityName();
	w.AddAbilityMultiple(abl, 3);
	GMTestAlchDrink('Mutagen 6');
	GMTestReport(w.GetAbilityCount(abl) == 0, "ALCH-09 Nightwraith: a new dose wipes the stacks (" + w.GetAbilityCount(abl) + ")");
	w.RemoveAllBuffsOfType(EET_Mutagen06);
	w.AddAbilityMultiple('Mutagen10Effect', 2);
	w.AddAbilityMultiple('Mutagen27Effect', 4);
	w.AddAbility('Mutagen24Effect', false);
	w.GMCleanupDecoctionAbilities();
	GMTestReport(w.GetAbilityCount('Mutagen10Effect') == 0 && w.GetAbilityCount('Mutagen27Effect') == 0 && !w.HasAbility('Mutagen24Effect'), "ALCH load cleanup: 5.x's leftover Wyvern, Griffin and Werewolf abilities removed");
	w.SetToxicityOffset(0);
	GMTest_alch09_chort();
}

// ALCH-09, audit F3: with Chort's decoction a heavy knockdown or a knockdown on Geralt becomes a stagger, and a
// stagger is denied (legacy); the staggers given are removed at once.
function GMTest_alch09_chort()
{
	var w : W3PlayerWitcher;
	var res : EEffectInteract;

	w = GetWitcherPlayer();
	GMTestAlchDecoction('Mutagen 8', EET_Mutagen08);
	res = w.AddEffectDefault(EET_HeavyKnockdown, w, 'gmtest');
	GMTestReport(!w.HasBuff(EET_HeavyKnockdown) && !w.HasBuff(EET_Knockdown) && w.HasBuff(EET_Stagger),
		"ALCH-09 audit F3 Chort: a heavy knockdown becomes a stagger (heavy knockdown " + w.HasBuff(EET_HeavyKnockdown) + ", knockdown " + w.HasBuff(EET_Knockdown) + ", stagger " + w.HasBuff(EET_Stagger) + ", " + res + ")");
	w.RemoveAllBuffsOfType(EET_Stagger);
	res = w.AddEffectDefault(EET_Knockdown, w, 'gmtest');
	GMTestReport(!w.HasBuff(EET_Knockdown) && w.HasBuff(EET_Stagger), "ALCH-09 Chort: a knockdown becomes a stagger (stagger " + w.HasBuff(EET_Stagger) + ", " + res + ")");
	w.RemoveAllBuffsOfType(EET_Stagger);
	res = w.AddEffectDefault(EET_Stagger, w, 'gmtest');
	GMTestReport(!w.HasBuff(EET_Stagger) && res == EI_Deny, "ALCH-09 Chort: a stagger is denied (" + res + ")");
	w.RemoveAllBuffsOfType(EET_Stagger);
	w.RemoveAllBuffsOfType(EET_Mutagen08);
	w.SetToxicityOffset(0);
}

exec function gmtest_alch09_chort()
{
	GMTest_alch09_chort();
}

// ALCH-13 with the test dummy (gmtest_dummy("human"), gmtest_dummy_neutral()).
exec function gmtest_alch13()
{
	var w : W3PlayerWitcher;
	var npc : CActor;
	var action : W3Action_Attack;
	var pts, perc, vitMax : float;

	w = GetWitcherPlayer();
	npc = GMTestDummy();
	if(!npc)
	{
		LogChannel('GMTest', "FAIL ALCH-13 no test dummy");
		return;
	}
	vitMax = w.GetStatMax(BCS_Vitality);
	// Arachas: acid on the enemy per melee hit taken, up to 10; gone at combat end (DL12).
	GMTestAlchDecoction('Mutagen 2', EET_Mutagen02);
	w.ForceSetStat(BCS_Vitality, vitMax);
	GMTestDefHit(npc, w, false, 0); GMTestDefHit(npc, w, false, 0); GMTestDefHit(npc, w, false, 0);
	GMTestReport(npc.GetAbilityCount('Mutagen02Effect') == 3, "ALCH-13 Arachas: three hits taken, 3 acid stacks on the enemy (" + npc.GetAbilityCount('Mutagen02Effect') + ", -" + RoundMath(100 * GMArachasResistReduction(npc)) + "% resistances)");
	w.GMClearDecoctionStacks();
	GMTestReport(npc.GetAbilityCount('Mutagen02Effect') == 0, "ALCH-13 Arachas DL12: the acid leaves the enemy at combat end");
	GMTestDefHit(npc, w, false, 0);
	w.RemoveAllBuffsOfType(EET_Mutagen02);
	GMTestReport(npc.GetAbilityCount('Mutagen02Effect') == 0, "ALCH-13 Arachas DL12: the acid leaves the enemy when the decoction ends");
	w.ForceSetStat(BCS_Vitality, vitMax);

	// Fiend: no hit animation for a hit below 15% of maximum Vitality.
	GMTestAlchDecoction('Mutagen 16', EET_Mutagen16);
	action = new W3Action_Attack in theGame.damageMgr;
	action.Init(npc, w, NULL, GetInvalidUniqueId(), 'attack_light', npc.GetName(), EHRT_Light, false, false, '', AST_Jab, ASD_UpDown, true, false, false, false);
	action.AddDamage(theGame.params.DAMAGE_NAME_DIRECT, vitMax * 0.05);
	action.SetSuppressHitSounds(true);
	theGame.damageMgr.ProcessAction(action);
	GMTestReport(action.GetHitAnimationPlayType() == EAHA_ForceNo, "ALCH-13 Fiend: no hit reaction from a 5% hit (" + action.GetHitAnimationPlayType() + ")");
	delete action;
	w.RemoveAllBuffsOfType(EET_Mutagen16);
	w.ForceSetStat(BCS_Vitality, vitMax);

	// Elemental: flat resistances.
	GMTestAlchDecoction('Mutagen 20', EET_Mutagen20);
	w.GetResistValue(CDS_FireRes, pts, perc);
	GMTestReport(w.HasAbility('Mutagen20Effect') && perc >= 0.5, "ALCH-13 Elemental: its ability on Geralt, fire resistance " + RoundMath(100 * perc) + "%");
	w.RemoveAllBuffsOfType(EET_Mutagen20);
	GMTestReport(!w.HasAbility('Mutagen20Effect'), "ALCH-13 Elemental: the ability goes with the decoction");

	// Werewolf: at 20% Vitality in combat, off above it with a cooldown.
	GMTestAlchDecoction('Mutagen 24', EET_Mutagen24);
	GMTestReport(!w.HasAbility('Mutagen24Effect'), "ALCH-13 Werewolf: nothing at full Vitality (no night ability)");
	w.ForceSetStat(BCS_Vitality, vitMax * 0.15);
	GMTestReport(w.HasAbility('Mutagen24Effect'), "ALCH-13 Werewolf: on at 15% Vitality in combat");
	w.ForceSetStat(BCS_Vitality, vitMax * 0.5);
	GMTestReport(!w.HasAbility('Mutagen24Effect'), "ALCH-13 Werewolf: off above 20%");
	w.ForceSetStat(BCS_Vitality, vitMax * 0.15);
	GMTestReport(!w.HasAbility('Mutagen24Effect'), "ALCH-13 Werewolf: not again during the 10 s cooldown");
	w.RemoveAllBuffsOfType(EET_Mutagen24);
	w.ForceSetStat(BCS_Vitality, vitMax);

	// Griffin: two hits in quick succession, then the next is dodged with no damage.
	GMTestAlchDecoction('Mutagen 27', EET_Mutagen27);
	GMTestDefHit(npc, w, false, 0); GMTestDefHit(npc, w, false, 0);
	GMTestReport(((W3Mutagen27_Effect)w.GetBuff(EET_Mutagen27)).GMIsBonusActive(), "ALCH-13 Griffin: two quick hits start the immunity");
	w.ForceSetStat(BCS_Vitality, vitMax);
	action = new W3Action_Attack in theGame.damageMgr;	// physical damage: direct damage skips the victim's ReduceDamage
	action.Init(npc, w, NULL, GetInvalidUniqueId(), 'attack_light', npc.GetName(), EHRT_Light, false, false, '', AST_Jab, ASD_UpDown, true, false, false, false);
	action.AddDamage(theGame.params.DAMAGE_NAME_PHYSICAL, vitMax * 0.05);
	action.SetSuppressHitSounds(true);
	action.SetHitAnimationPlayType(EAHA_ForceNo);
	theGame.damageMgr.ProcessAction(action);
	GMTestReport(action.WasDodged() && w.GetStat(BCS_Vitality) == vitMax, "ALCH-13 Griffin: the next hit dodged, no damage (" + action.WasDodged() + ", " + NoTrailZeros(w.GetStat(BCS_Vitality)) + ")");
	w.RemoveAllBuffsOfType(EET_Mutagen27);
	w.SetToxicityOffset(0);
	w.ForceSetStat(BCS_Vitality, vitMax);
}

// ALCH-10, audit F13: the HUD's stack percentages. gmtest_alch10_hud() (test dummy spawned, Geralt in combat)
// drinks Alghoul and Forktail and hits the dummy until both carry stacks; look at the HUD; gmtest_alch10_hud_end().
exec function gmtest_alch10_hud()
{
	var npc : CActor;
	var i : int;

	npc = GMTestDummy();
	GMTestAlchDecoction('Mutagen 15', EET_Mutagen15);
	GMTestAlchDecoction('Mutagen 17', EET_Mutagen17);
	for(i = 0; i < 3; i += 1)
		GMTestAlchSwordHit(npc, false);
	LogChannel('GMTest', "INFO ALCH-10 HUD: Alghoul " + ((W3Mutagen15_Effect)thePlayer.GetBuff(EET_Mutagen15)).GMGetStacks() + "%, Forktail " + ((W3Mutagen17_Effect)thePlayer.GetBuff(EET_Mutagen17)).GMGetStacks() + "%");
}

exec function gmtest_alch10_hud_end()
{
	thePlayer.RemoveAllBuffsOfType(EET_Mutagen15);
	thePlayer.RemoveAllBuffsOfType(EET_Mutagen17);
	GetWitcherPlayer().SetToxicityOffset(0);
}
