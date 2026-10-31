// DIFF slice D3 (docs/features/diff.md): DIFF-06, Ciri: no difficulty cap, her quest stats, her enemies' "Death
// March!" adjustment zeroed, the two quest abilities by journal state. Her eight abilities' data are in the
// regression's data check (GMTest_diffdata, tests/gmTestsDiffData.ws, tools/gen_diff.py).
//
// Played as Ciri with vanilla's Ciri() and back with Geralt() (theGame.ChangePlayer, no scene, no teleport;
// exec --wait 3000 each). Modes are set through the game's own path (GMTestDiffSetMode); calls that change the
// mode set back the one they found.
//   gmtest_diff06_snap()          as Geralt: records his state (level, experience, points, money, skills,
//                                 abilities, items, effects, stats); gmtest_diff06_same() after Geralt() compares
//   gmtest_diff06_var_a()         spawns a frozen neutral kikimore warrior and shaelmaar (their variants follow
//                                 the mode); gmtest_diff06_var() checks they hold the current mode's variant and
//                                 difficulty ability, as Geralt or Ciri; gmtest_diff06_var_b() removes them
//   gmtest_diff06_jset(on)        activates "Q205 Ciri - safe heaven" in the journal (on) or puts back its status
//   gmtest_diff06_spawned()       as Ciri: what her spawn gave her (Ciri_Q205 by the journal check)
//   gmtest_diff06_journal()       as Ciri: the journal entries found, the quest-ability rule for every combination,
//                                 each entry activated and put back with the real check
//   gmtest_diff06_combat_a(), _b() as Ciri: Q305's entry active, a hostile bandit spawned: combat start adds
//                                 Ciri_Q305; _b checks, puts the entry back and removes the bandit
//   gmtest_diff06_a()             as Ciri: a frozen hostile bandit and ghoul (test dummies 0 and 1)
//   gmtest_diff06_modes()         as Ciri: every mode in turn: no cap, the mode's ability and legacy's multipliers
//   gmtest_diff06_debuff()        as Ciri on "Death March!": the enemies' adjustment held and empty
//   gmtest_diff06_abl()           as Ciri: each of her quest abilities and her rage added and read, then removed
//   gmtest_diff06_fight_a(), _b() as Ciri: the bandit and the ghoul unfrozen, real hits on her (immortal)

@addField(CR4Game)
var gmTestDiff06Snap : array<string>;
@addField(CR4Game)
var gmTestDiff06Pos : Vector;
@addField(CR4Game)
var gmTestDiff06Vit : float;
@addField(CR4Game)
var gmTestDiff06Npcs : array<CNewNPC>;
@addField(CR4Game)
var gmTestDiff06Kinds : array<string>;
@addField(CR4Game)
var gmTestDiff06JStatus : EJournalStatus;
@addField(CR4Game)
var gmTestDiff06JSet : bool;

@addMethod(CR4Game)
function GMTestDiff06SetSnap(s : array<string>, pos : Vector, vit : float)
{
	gmTestDiff06Snap = s;
	gmTestDiff06Pos = pos;
	gmTestDiff06Vit = vit;
}

@addMethod(CR4Game)
function GMTestDiff06AddNpc(npc : CNewNPC, kind : string)
{
	gmTestDiff06Npcs.PushBack(npc);
	gmTestDiff06Kinds.PushBack(kind);
}

@addMethod(CR4Game)
function GMTestDiff06ClearNpcs()
{
	var i : int;

	for(i = 0; i < gmTestDiff06Npcs.Size(); i += 1)
		if(gmTestDiff06Npcs[i])
			gmTestDiff06Npcs[i].Destroy();
	gmTestDiff06Npcs.Clear();
	gmTestDiff06Kinds.Clear();
}

@addMethod(CR4Game)
function GMTestDiff06SetJ(isSet : bool, status : EJournalStatus)
{
	gmTestDiff06JSet = isSet;
	gmTestDiff06JStatus = status;
}

// The order of a player change, in the script log (test builds only).
@wrapMethod(CR4Game)
function OnPlayerChanged()
{
	LogChannel('GMTestDiff06', "player change: OnPlayerChanged (spawn mode " + GMTestDiffModeName(GetSpawnDifficultyMode()) + ")");
	wrappedMethod();
}

@wrapMethod(W3ReplacerCiri)
function OnSpawned(spawnData : SEntitySpawnData)
{
	var i : int;
	var held : string;
	var npc : CNewNPC;

	LogChannel('GMTestDiff06', "player change: Ciri's OnSpawned (restored " + spawnData.restored + ")");
	wrappedMethod(spawnData);
	for(i = 0; i < theGame.gmTestDiff06Npcs.Size(); i += 1)
	{
		npc = theGame.gmTestDiff06Npcs[i];
		if(npc)
		{
			GMTestDiff06VarOk(npc, theGame.gmTestDiff06Kinds[i], theGame.GetDifficultyMode(), held);
			LogChannel('GMTestDiff06', "player change: at the end of Ciri's OnSpawned the " + theGame.gmTestDiff06Kinds[i] + " holds" + held);
		}
	}
}

function GMTestDiff06IsCiri(label : string) : bool
{
	if((W3ReplacerCiri)thePlayer)
		return true;
	GMTestReport(false, "DIFF-06 " + label + ": Ciri is not the player (Ciri() first)");
	return false;
}

function GMTestDiff06F(f : float) : string
{
	return NoTrailZeros(RoundTo(f, 3));
}

// Geralt's state as lines, compared as a multiset.
function GMTestDiff06State() : array<string>
{
	var s : array<string>;
	var w : W3PlayerWitcher;
	var abls : array<name>;
	var items : array<SItemUniqueId>;
	var inv : CInventoryComponent;
	var buffs : array<CBaseGameplayEffect>;
	var i, id : int;
	var sk : ESkill;
	var pts, prc : float;
	var ap : SAbilityAttributeValue;

	w = GetWitcherPlayer();
	if(!w)
	{
		s.PushBack("the player is not Geralt");
		return s;
	}
	s.PushBack("level " + w.GetLevel());
	s.PushBack("experience " + w.levelManager.GetPointsTotal(EExperiencePoint));
	s.PushBack("skill points free " + w.levelManager.GetPointsFree(ESkillPoint) + ", used " + w.levelManager.GetPointsUsed(ESkillPoint));
	s.PushBack("money " + w.GetMoney());
	s.PushBack("mutation " + (int)w.GetEquippedMutationType());
	for(i = 0; i < w.GetSkillSlotsCount(); i += 1)
	{
		id = w.GetSkillSlotIDFromIndex(i);
		if(w.GetSkillOnSlot(id, sk))
			s.PushBack("skill slot " + id + ": " + (int)sk);
	}
	w.GetCharacterStats().GetAbilities(abls, true);
	for(i = 0; i < abls.Size(); i += 1)
		s.PushBack("ability " + abls[i]);
	inv = w.GetInventory();
	inv.GetAllItems(items);
	for(i = 0; i < items.Size(); i += 1)
		s.PushBack("item " + inv.GetItemName(items[i]) + " x" + inv.GetItemQuantity(items[i]) + (w.IsItemEquipped(items[i]) ? " equipped" : ""));
	buffs = w.GetBuffs();
	for(i = 0; i < buffs.Size(); i += 1)
		s.PushBack("effect " + EffectTypeToName(buffs[i].GetEffectType()));
	s.PushBack("vitality max " + GMTestDiff06F(w.GetStatMax(BCS_Vitality)));	// the current value regenerates: read apart
	s.PushBack("stamina max " + GMTestDiff06F(w.GetStatMax(BCS_Stamina)));
	s.PushBack("toxicity " + GMTestDiff06F(w.GetStat(BCS_Toxicity)) + " of " + GMTestDiff06F(w.GetStatMax(BCS_Toxicity)));
	s.PushBack("adrenaline " + GMTestDiff06F(w.GetStat(BCS_Focus)) + " of " + GMTestDiff06F(w.GetStatMax(BCS_Focus)));
	ap = w.GetPowerStatValue(CPS_AttackPower);
	s.PushBack("attack power " + GMTestDiff06F(ap.valueBase) + "/" + GMTestDiff06F(ap.valueMultiplicative) + "/" + GMTestDiff06F(ap.valueAdditive));
	ap = w.GetPowerStatValue(CPS_SpellPower);
	s.PushBack("sign intensity " + GMTestDiff06F(ap.valueMultiplicative));
	s.PushBack("armor " + GMTestDiff06F(CalculateAttributeValue(w.GetTotalArmor())));
	w.GetResistValue(CDS_SlashingRes, pts, prc);	s.PushBack("slashing resistance " + GMTestDiff06F(pts) + "/" + GMTestDiff06F(prc));
	w.GetResistValue(CDS_FrostRes, pts, prc);		s.PushBack("frost resistance " + GMTestDiff06F(pts) + "/" + GMTestDiff06F(prc));
	s.PushBack("immortality " + (int)w.GetImmortalityMode());
	return s;
}

exec function gmtest_diff06_snap()
{
	var s : array<string>;

	s = GMTestDiff06State();
	theGame.GMTestDiff06SetSnap(s, thePlayer.GetWorldPosition(), thePlayer.GetStat(BCS_Vitality));
	LogChannel('GMTest', "INFO DIFF-06 Geralt's state recorded: " + s.Size() + " lines (level, experience, points, money, skills, abilities, items, effects, stats) at "
		+ VecToString(thePlayer.GetWorldPosition()) + " on " + GMTestDiffModeName(theGame.GetDifficultyMode()));
}

exec function gmtest_diff06_same()
{
	var now, rest, onlyBefore : array<string>;
	var i, k : int;
	var d : string;

	thePlayer.GMTestCount(true, true);
	now = GMTestDiff06State();
	rest = now;
	for(i = 0; i < theGame.gmTestDiff06Snap.Size(); i += 1)
	{
		k = rest.FindFirst(theGame.gmTestDiff06Snap[i]);
		if(k >= 0)
			rest.Erase(k);
		else
			onlyBefore.PushBack(theGame.gmTestDiff06Snap[i]);
	}
	for(i = 0; i < onlyBefore.Size() && i < 12; i += 1)
		LogChannel('GMTest', "INFO DIFF-06 before only: " + onlyBefore[i]);
	for(i = 0; i < rest.Size() && i < 12; i += 1)
		LogChannel('GMTest', "INFO DIFF-06 now only: " + rest[i]);
	GMTestReport(theGame.gmTestDiff06Snap.Size() > 0 && onlyBefore.Size() == 0 && rest.Size() == 0 && (W3PlayerWitcher)thePlayer,
		"DIFF-06 Geralt after Ciri: " + now.Size() + " state lines against " + theGame.gmTestDiff06Snap.Size() + " recorded; " + onlyBefore.Size() + " lost, " + rest.Size() + " new");
	GMTestReport(thePlayer.GetStat(BCS_Vitality) >= theGame.gmTestDiff06Vit - 0.01, "DIFF-06 Geralt's Vitality " + GMTestDiff06F(thePlayer.GetStat(BCS_Vitality)) + ", recorded "
		+ GMTestDiff06F(theGame.gmTestDiff06Vit) + " (not lower; it regenerates out of combat)");
	LogChannel('GMTest', "INFO DIFF-06 Geralt at " + VecToString(thePlayer.GetWorldPosition()) + ", " + GMTestDiff06F(VecDistance(thePlayer.GetWorldPosition(), theGame.gmTestDiff06Pos))
		+ " m from where he was recorded; mode " + GMTestDiffModeName(theGame.GetDifficultyMode()) + ", spawn mode " + GMTestDiffModeName(theGame.GetSpawnDifficultyMode()));
	LogChannel('GMTest', "SUMMARY diff06_same: " + thePlayer.gmTestPassed + " passed, " + thePlayer.gmTestFailed + " failed");
}

// ---- the variants of NPCs present at the player change (the open check)

exec function gmtest_diff06_var_a()
{
	var paths : array<string>;
	var npc : CNewNPC;
	var i : int;

	theGame.GMTestDiff06ClearNpcs();
	paths.PushBack("dlc/bob/data/characters/npc_entities/monsters/kikimore.w2ent");
	paths.PushBack("dlc/bob/data/characters/npc_entities/monsters/sharley.w2ent");
	paths.PushBack("dlc/bob/data/quests/minor_quests/quest_files/ff701_fistfights/ff701_drunken_master/characters/ff701_master.w2ent");
	for(i = 0; i < paths.Size(); i += 1)
	{
		npc = GMTestAi15Spawn(paths[i], 16 + 4 * i, -6 + 6 * i);
		if(npc && i == 2)
			theGame.GMTestDiff06AddNpc(npc, "drunken master");
		else if(npc)
			theGame.GMTestDiff06AddNpc(npc, GMTestDiff02Kind(npc));
	}
	LogChannel('GMTest', "INFO DIFF-06 " + theGame.gmTestDiff06Npcs.Size() + " enemies with variants spawned on " + GMTestDiffModeName(theGame.GetDifficultyMode()));
}

exec function gmtest_diff06_var_b()
{
	theGame.GMTestDiff06ClearNpcs();
	LogChannel('GMTest', "INFO DIFF-06 enemies with variants removed");
}

// Whether the NPC holds exactly `mode`'s variant among its parent's and `mode`'s difficulty ability; `held` lists
// what it holds.
function GMTestDiff06VarOk(npc : CNewNPC, kind : string, mode : EDifficultyMode, out held : string) : bool
{
	var names : array<name>;
	var vmodes : array<EDifficultyMode>;
	var k : int;
	var ok : bool;
	var modes : array<EDifficultyMode>;

	ok = true;
	held = "";
	if(kind == "drunken master")	// his variant sits in his entity's own list: chosen at his spawn
	{
		names.PushBack('mon_EP2_hardcore_FF');	vmodes.PushBack(EDM_Hardcore);
	}
	else
		GMTestDiff02Variants(kind, names, vmodes);
	for(k = 0; k < names.Size(); k += 1)
	{
		if(npc.HasAbility(names[k]))
			held += " " + names[k];
		if(npc.HasAbility(names[k]) != (vmodes[k] == mode))
			ok = false;
	}
	modes.PushBack(EDM_Easy); modes.PushBack(EDM_Medium); modes.PushBack(EDM_Hard); modes.PushBack(EDM_Hardcore);
	for(k = 0; k < modes.Size(); k += 1)
	{
		if(npc.HasAbility(GMTestDiffAbilityOf(modes[k])))
			held += " " + GMTestDiffAbilityOf(modes[k]);
		if(npc.HasAbility(GMTestDiffAbilityOf(modes[k])) != (modes[k] == mode))
			ok = false;
	}
	if(held == "")
		held = " nothing";
	return ok;
}

exec function gmtest_diff06_var()
{
	var i : int;
	var npc : CNewNPC;
	var held, who : string;
	var mode : EDifficultyMode;
	var n : int;

	thePlayer.GMTestCount(true, true);
	mode = theGame.GetDifficultyMode();
	who = "Geralt";
	if((W3ReplacerCiri)thePlayer)
		who = "Ciri";
	for(i = 0; i < theGame.gmTestDiff06Npcs.Size(); i += 1)
	{
		npc = theGame.gmTestDiff06Npcs[i];
		if(!npc)
			continue;
		n += 1;
		GMTestReport(GMTestDiff06VarOk(npc, theGame.gmTestDiff06Kinds[i], mode, held), "DIFF-06 " + who + " the player on " + GMTestDiffModeName(mode)
			+ ": the " + theGame.gmTestDiff06Kinds[i] + " spawned before the change holds" + held + " (that mode's variant and ability expected)");
	}
	GMTestReport(n >= 2, "DIFF-06 " + n + " enemies with variants read");
	LogChannel('GMTest', "SUMMARY diff06_var: " + thePlayer.gmTestPassed + " passed, " + thePlayer.gmTestFailed + " failed");
}

// ---- the journal check

// The entry as GMCheckCiriAbilities looks it up (the manager knows only the journal files loaded: those of
// quests the save has reached).
function GMTestDiff06EntryByString(i : int) : CJournalBase
{
	var jm : CWitcherJournalManager;

	jm = theGame.GetJournalManager();
	switch(i)
	{
		case 0: return jm.GetEntryByString("Q302 Ciri - Rescuing Dudu DC58A7F2-49D51834-AC99B3A6-6106D4CC");
		case 1: return jm.GetEntryByString("Q305 Ciri - chase to the temple 12B8D11E-4BF80285-D48C5CAF-A75A0887");
		case 2: return jm.GetEntryByString("Q205 Ciri - safe heaven");
	}
	return NULL;
}

function GMTestDiff06EntryFile(i : int) : string
{
	switch(i)
	{
		case 0: return "gameplay\journal\quests\q302rescuingdudu.journal";
		case 1: return "gameplay\journal\quests\q305cirichasetothetemple.journal";
		case 2: return "gameplay\journal\quests\q205cirireplacer.journal";
	}
	return "";
}

// The entry, its journal file loaded first if the manager does not know it yet (the test save has not reached
// Ciri's quests).
function GMTestDiff06Entry(i : int) : CJournalBase
{
	var e : CJournalBase;
	var r : CJournalResource;

	e = GMTestDiff06EntryByString(i);
	if(e)
		return e;
	r = (CJournalResource)LoadResource(GMTestDiff06EntryFile(i), true);
	if(r)
		e = r.GetEntry();
	return e;
}

function GMTestDiff06EntryName(i : int) : string
{
	switch(i)
	{
		case 0: return "Q302 Ciri - Rescuing Dudu";
		case 1: return "Q305 Ciri - chase to the temple";
		case 2: return "Q205 Ciri - safe heaven";
	}
	return "";
}

// The ability entry i gives.
function GMTestDiff06EntryAbl(i : int) : name
{
	if(i == 2)
		return 'Ciri_Q205';
	return 'Ciri_Q305';
}

// Activates entry i (on) or puts back the status it had (off); the status is kept on theGame across the swap.
function GMTestDiff06JournalSet(i : int, on : bool)
{
	var jm : CWitcherJournalManager;
	var e : CJournalBase;

	jm = theGame.GetJournalManager();
	e = GMTestDiff06Entry(i);
	if(!e)
		return;
	if(on)
	{
		if(!theGame.gmTestDiff06JSet)
			theGame.GMTestDiff06SetJ(true, jm.GetEntryStatus(e));
		jm.ActivateEntry(e, JS_Active, false, false);
	}
	else if(theGame.gmTestDiff06JSet)
	{
		jm.ActivateEntry(e, theGame.gmTestDiff06JStatus, false, false);
		theGame.GMTestDiff06SetJ(false, JS_Inactive);
	}
}

exec function gmtest_diff06_jset(on : bool)
{
	var e : CJournalBase;

	GMTestDiff06JournalSet(2, on);
	e = GMTestDiff06Entry(2);
	if(e)
		LogChannel('GMTest', "INFO DIFF-06 journal entry " + GMTestDiff06EntryName(2) + " status " + (int)theGame.GetJournalManager().GetEntryStatus(e));
	else
		LogChannel('GMTest', "INFO DIFF-06 journal entry " + GMTestDiff06EntryName(2) + " not found");
}

exec function gmtest_diff06_spawned()
{
	var e : CJournalBase;
	var active : bool;

	thePlayer.GMTestCount(true, true);
	if(!GMTestDiff06IsCiri("spawn"))
		return;
	e = GMTestDiff06Entry(2);
	if(e)
		active = theGame.GetJournalManager().GetEntryStatus(e) == JS_Active;
	GMTestReport(active && thePlayer.HasAbility('Ciri_Q205') && !thePlayer.HasAbility('Ciri_Q305'), "DIFF-06 Ciri's spawn with " + GMTestDiff06EntryName(2)
		+ (active ? " active" : " not active") + ": Ciri_Q205 " + (thePlayer.HasAbility('Ciri_Q205') ? "held" : "not held") + ", Ciri_Q305 " + (thePlayer.HasAbility('Ciri_Q305') ? "held" : "not held")
		+ " (her spawn's journal check)");
	GMTestReport(theGame.GetSpawnDifficultyMode() == theGame.GetDifficultyMode(), "DIFF-06 as Ciri on " + GMTestDiffModeName(theGame.GetDifficultyMode()) + ": the spawn mode is "
		+ GMTestDiffModeName(theGame.GetSpawnDifficultyMode()));
	LogChannel('GMTest', "SUMMARY diff06_spawned: " + thePlayer.gmTestPassed + " passed, " + thePlayer.gmTestFailed + " failed");
}

exec function gmtest_diff06_journal()
{
	var ciri : W3ReplacerCiri;
	var jm : CWitcherJournalManager;
	var e : CJournalBase;
	var i, c : int;
	var q305, q205 : bool;
	var st : EJournalStatus;
	var found : bool;

	thePlayer.GMTestCount(true, true);
	if(!GMTestDiff06IsCiri("journal"))
		return;
	ciri = (W3ReplacerCiri)thePlayer;
	jm = theGame.GetJournalManager();
	for(i = 0; i < 3; i += 1)
	{
		e = GMTestDiff06EntryByString(i);
		found = false;
		if(e)
			found = true;
		LogChannel('GMTest', "INFO DIFF-06 journal: " + GMTestDiff06EntryName(i) + (found ? " known to the manager" : " not known to the manager yet (its quest not reached)"));
		e = GMTestDiff06Entry(i);
		found = false;
		if(e)
			found = true;
		if(found)
			GMTestReport(true, "DIFF-06 journal: " + GMTestDiff06EntryName(i) + " found in 5.x's journal (" + GMTestDiff06EntryFile(i) + "), status " + (int)jm.GetEntryStatus(e)
				+ "; found by GMCheckCiriAbilities' string now: " + (GMTestDiff06EntryByString(i) == e));
		else
			GMTestReport(false, "DIFF-06 journal: " + GMTestDiff06EntryName(i) + " not found in 5.x's journal");
	}
	// the rule, every combination
	for(c = 0; c < 4; c += 1)
	{
		q305 = c == 1 || c == 3;
		q205 = c == 2 || c == 3;
		ciri.GMSetCiriQuestAbilities(q305, q205);
		GMTestReport(ciri.HasAbility('Ciri_Q305') == q305 && ciri.HasAbility('Ciri_Q205') == q205, "DIFF-06 the quest abilities with Novigrad's quests " + (q305 ? "active" : "inactive")
			+ " and Skellige's " + (q205 ? "active" : "inactive") + ": Ciri_Q305 " + ciri.HasAbility('Ciri_Q305') + ", Ciri_Q205 " + ciri.HasAbility('Ciri_Q205'));
	}
	ciri.GMCheckCiriAbilities();
	// each entry activated for real, checked, put back, checked
	for(i = 0; i < 3; i += 1)
	{
		e = GMTestDiff06Entry(i);
		if(!e)
			continue;
		st = jm.GetEntryStatus(e);
		jm.ActivateEntry(e, JS_Active, false, false);
		ciri.GMCheckCiriAbilities();
		GMTestReport(jm.GetEntryStatus(e) == JS_Active && ciri.HasAbility(GMTestDiff06EntryAbl(i)), "DIFF-06 journal: " + GMTestDiff06EntryName(i) + " activated (status " + (int)jm.GetEntryStatus(e)
			+ "): " + GMTestDiff06EntryAbl(i) + (ciri.HasAbility(GMTestDiff06EntryAbl(i)) ? " added" : " not added"));
		jm.ActivateEntry(e, st, false, false);
		ciri.GMCheckCiriAbilities();
		GMTestReport(jm.GetEntryStatus(e) == st && !ciri.HasAbility(GMTestDiff06EntryAbl(i)), "DIFF-06 journal: " + GMTestDiff06EntryName(i) + " put back to status " + (int)jm.GetEntryStatus(e)
			+ " (was " + (int)st + "): " + GMTestDiff06EntryAbl(i) + (ciri.HasAbility(GMTestDiff06EntryAbl(i)) ? " still held" : " removed"));
	}
	LogChannel('GMTest', "SUMMARY diff06_journal: " + thePlayer.gmTestPassed + " passed, " + thePlayer.gmTestFailed + " failed");
}

// Combat start's check: Q305's entry active, then a hostile bandit spawned 4 m ahead (frozen): Ciri enters combat.
exec function gmtest_diff06_combat_a()
{
	if(!GMTestDiff06IsCiri("combat start"))
		return;
	thePlayer.RemoveAbility('Ciri_Q305');
	GMTestDiff06JournalSet(1, true);
	thePlayer.GMTestDummyClearAll();
	GMTestDummySpawn("human", 0, 4);
	LogChannel('GMTest', "INFO DIFF-06 Q305's entry active, Ciri_Q305 " + thePlayer.HasAbility('Ciri_Q305') + ", in combat " + thePlayer.IsInCombat() + "; a hostile bandit spawned");
}

exec function gmtest_diff06_combat_b()
{
	var had : bool;

	thePlayer.GMTestCount(true, true);
	if(!GMTestDiff06IsCiri("combat start"))
		return;
	had = thePlayer.HasAbility('Ciri_Q305');
	GMTestReport(thePlayer.IsInCombat() && had, "DIFF-06 combat start with " + GMTestDiff06EntryName(1) + " active: in combat " + thePlayer.IsInCombat() + ", Ciri_Q305 " + (had ? "added" : "not added"));
	GMTestDiff06JournalSet(1, false);
	((W3ReplacerCiri)thePlayer).GMCheckCiriAbilities();
	thePlayer.GMTestDummyClearAll();
	LogChannel('GMTest', "INFO DIFF-06 entry put back, Ciri_Q305 " + thePlayer.HasAbility('Ciri_Q305') + ", bandit removed");
	LogChannel('GMTest', "SUMMARY diff06_combat: " + thePlayer.gmTestPassed + " passed, " + thePlayer.gmTestFailed + " failed");
}

// ---- her enemies

exec function gmtest_diff06_a()
{
	if(!GMTestDiff06IsCiri("enemies"))
		return;
	thePlayer.GMTestDummyClearAll();
	GMTestDummySpawn("human", 0, 4);
	GMTestDummySpawn("ghoul", 0, 6);
	LogChannel('GMTest', "INFO DIFF-06 " + thePlayer.gmTestDummies.Size() + " NPCs spawned near Ciri (bandit, ghoul) on " + GMTestDiffModeName(theGame.GetDifficultyMode()) + "; read them in a later call");
}

// Every mode in turn as Ciri: the spawn mode is the mode (5.x: at most "Story and Sword!"), each spawned NPC holds
// that mode's difficulty ability alone with legacy's multipliers, and the variant NPCs (if spawned) that mode's
// variant. Sets back the mode it found.
exec function gmtest_diff06_modes()
{
	var start, mode : EDifficultyMode;
	var modes : array<EDifficultyMode>;
	var npc : CNewNPC;
	var i, m, k, others : int;
	var hp, dmg, wantHp, wantDmg : float;
	var held : string;

	thePlayer.GMTestCount(true, true);
	if(!GMTestDiff06IsCiri("modes"))
		return;
	start = theGame.GetDifficultyMode();
	// a mode change drops the drunken master's own variant for good (DIFF-02): remove him first
	for(i = 0; i < theGame.gmTestDiff06Npcs.Size(); i += 1)
		if(theGame.gmTestDiff06Npcs[i] && theGame.gmTestDiff06Kinds[i] == "drunken master")
		{
			theGame.gmTestDiff06Npcs[i].Destroy();
			LogChannel('GMTest', "INFO DIFF-06 the drunken master removed before the mode changes");
		}
	modes.PushBack(EDM_Easy); modes.PushBack(EDM_Medium); modes.PushBack(EDM_Hard); modes.PushBack(EDM_Hardcore);
	for(m = 0; m < modes.Size(); m += 1)
	{
		mode = modes[m];
		GMTestDiffSetMode(mode);
		GMTestDiffWant(mode, wantHp, wantDmg);
		GMTestReport(theGame.GetSpawnDifficultyMode() == mode, "DIFF-06 Ciri on " + GMTestDiffModeName(mode) + ": spawn mode " + GMTestDiffModeName(theGame.GetSpawnDifficultyMode()));
		for(i = 0; i < thePlayer.gmTestDummies.Size(); i += 1)
		{
			npc = thePlayer.gmTestDummies[i];
			if(!npc)
				continue;
			others = 0;
			for(k = 0; k < modes.Size(); k += 1)
				if(modes[k] != mode && npc.HasAbility(GMTestDiffAbilityOf(modes[k])))
					others += 1;
			GMTestDiffRead(npc, hp, dmg);
			GMTestReport(npc.HasAbility(GMTestDiffAbilityOf(mode)) && others == 0 && AbsF(hp - wantHp) < 0.001 && AbsF(dmg - wantDmg) < 0.001,
				"DIFF-06 Ciri on " + GMTestDiffModeName(mode) + ": the " + npc.GetDisplayName() + " has " + GMTestDiffAbilityOf(mode) + (others > 0 ? " and " + others + " other modes' abilities" : " alone")
				+ ", health x" + NoTrailZeros(hp) + ", damage x" + NoTrailZeros(dmg) + " (legacy's x" + NoTrailZeros(wantHp) + ", x" + NoTrailZeros(wantDmg) + ")");
		}
		for(i = 0; i < theGame.gmTestDiff06Npcs.Size(); i += 1)
		{
			npc = theGame.gmTestDiff06Npcs[i];
			if(npc)
				GMTestReport(GMTestDiff06VarOk(npc, theGame.gmTestDiff06Kinds[i], mode, held), "DIFF-06 Ciri on " + GMTestDiffModeName(mode) + ": the " + theGame.gmTestDiff06Kinds[i] + " holds" + held);
		}
	}
	GMTestDiffSetMode(start);
	LogChannel('GMTest', "INFO DIFF-06 mode set back to " + GMTestDiffModeName(theGame.GetDifficultyMode()));
	LogChannel('GMTest', "SUMMARY diff06_modes: " + thePlayer.gmTestPassed + " passed, " + thePlayer.gmTestFailed + " failed");
}

// As Ciri on "Death March!" (set in an earlier call, the level-bonus timer since run): the bandit holds
// CiriHardcoreDebuffHuman, the ghoul CiriHardcoreDebuffMonster, and each one's attack power is the same with and
// without it (legacy: x0; 5.x: +0.7 and +0.6); legacy's multipliers x2.5 / x3.5.
exec function gmtest_diff06_debuff()
{
	var npc : CNewNPC;
	var i : int;
	var debuff : name;
	var with, without : SAbilityAttributeValue;
	var noTags : array<name>;
	var had : bool;
	var hp, dmg : float;

	thePlayer.GMTestCount(true, true);
	if(!GMTestDiff06IsCiri("Death March adjustment"))
		return;
	for(i = 0; i < thePlayer.gmTestDummies.Size(); i += 1)
	{
		npc = thePlayer.gmTestDummies[i];
		if(!npc)
			continue;
		if(npc.UsesEssence())
			debuff = 'CiriHardcoreDebuffMonster';
		else
			debuff = 'CiriHardcoreDebuffHuman';
		had = npc.HasAbility(debuff);
		if(!had)
			npc.AddAbility(debuff);
		with = npc.GetCharacterStats().GetAttributeValue('attack_power', noTags);
		npc.RemoveAbility(debuff);
		without = npc.GetCharacterStats().GetAttributeValue('attack_power', noTags);
		if(had)
			npc.AddAbility(debuff);
		GMTestDiffRead(npc, hp, dmg);
		GMTestReport(theGame.GetDifficultyMode() == EDM_Hardcore && had && AbsF(with.valueMultiplicative - without.valueMultiplicative) < 0.0001 && AbsF(with.valueAdditive - without.valueAdditive) < 0.001,
			"DIFF-06 Ciri on " + GMTestDiffModeName(theGame.GetDifficultyMode()) + ": the " + npc.GetDisplayName() + (had ? " holds " : " lacks ") + debuff + "; attack power mult with it "
			+ NoTrailZeros(with.valueMultiplicative) + ", without " + NoTrailZeros(without.valueMultiplicative) + " (legacy: the same; 5.x: +" + (npc.UsesEssence() ? "0.6" : "0.7") + ")"
			+ "; health x" + NoTrailZeros(hp) + ", damage x" + NoTrailZeros(dmg));
	}
	LogChannel('GMTest', "SUMMARY diff06_debuff: " + thePlayer.gmTestPassed + " passed, " + thePlayer.gmTestFailed + " failed");
}

// ---- her abilities

function GMTestDiff06AblOne(abl : name, vit : float, armor : float, ap : float, frost : float)
{
	var noTags : array<name>;
	var v0, v1, a0, a1, p0, p1, f0, f1 : SAbilityAttributeValue;
	var m0, m1 : float;
	var cs : CCharacterStats;
	var had : bool;

	cs = thePlayer.GetCharacterStats();
	had = thePlayer.HasAbility(abl);
	if(had)
		thePlayer.RemoveAbility(abl);
	v0 = cs.GetAttributeValue('vitality', noTags);	a0 = cs.GetAttributeValue('armor', noTags);
	p0 = cs.GetAttributeValue('attack_power', noTags);	f0 = cs.GetAttributeValue('frost_resistance_perc', noTags);
	m0 = thePlayer.GetStatMax(BCS_Vitality);
	thePlayer.AddAbility(abl, false);
	v1 = cs.GetAttributeValue('vitality', noTags);	a1 = cs.GetAttributeValue('armor', noTags);
	p1 = cs.GetAttributeValue('attack_power', noTags);	f1 = cs.GetAttributeValue('frost_resistance_perc', noTags);
	m1 = thePlayer.GetStatMax(BCS_Vitality);
	if(!had)
		thePlayer.RemoveAbility(abl);
	GMTestReport(AbsF(v1.valueBase - v0.valueBase - vit) < 0.01 && AbsF(a1.valueBase - a0.valueBase - armor) < 0.01 && AbsF(p1.valueAdditive - p0.valueAdditive - ap) < 0.01
		&& AbsF(f1.valueBase - f0.valueBase - frost) < 0.0001,
		"DIFF-06 Ciri with " + abl + ": vitality +" + NoTrailZeros(v1.valueBase - v0.valueBase) + " (maximum " + NoTrailZeros(m0) + " -> " + NoTrailZeros(m1) + "), armor +" + NoTrailZeros(a1.valueBase - a0.valueBase)
		+ ", attack power +" + NoTrailZeros(p1.valueAdditive - p0.valueAdditive) + ", frost resistance +" + NoTrailZeros(f1.valueBase - f0.valueBase)
		+ " (legacy's +" + NoTrailZeros(vit) + ", +" + NoTrailZeros(armor) + ", +" + NoTrailZeros(ap) + ", +" + NoTrailZeros(frost) + ")");
}

exec function gmtest_diff06_abl()
{
	thePlayer.GMTestCount(true, true);
	if(!GMTestDiff06IsCiri("abilities"))
		return;
	// 5.x: Q205 250 health; Q305 +100 attack power; no armor or frost resistance; her rage 10,000 health
	GMTestDiff06AblOne('Ciri_Q205', 800, 150, 250, 0);
	GMTestDiff06AblOne('Ciri_Q305', 500, 150, 150, 0);
	GMTestDiff06AblOne('Ciri_Q403', 2000, 230, 500, 1);
	GMTestDiff06AblOne('Ciri_Q111', 2500, 260, 600, 0);
	GMTestDiff06AblOne('Ciri_Q501', 2500, 320, 150, 1);
	GMTestDiff06AblOne('Ciri_Rage', 5000, 0, 0, 0);
	LogChannel('GMTest', "SUMMARY diff06_abl: " + thePlayer.gmTestPassed + " passed, " + thePlayer.gmTestFailed + " failed");
}

// ---- a real fight: the bandit and the ghoul unfrozen on the current mode, Ciri immortal; the probe of
// gmTestsDiff.ws records every hit on her (the difficulty step's damage before and after).
exec function gmtest_diff06_fight_a()
{
	var i : int;

	if(!GMTestDiff06IsCiri("fight"))
		return;
	thePlayer.SetImmortalityMode(AIM_Immortal, AIC_Default, true);
	thePlayer.ForceSetStat(BCS_Vitality, thePlayer.GetStatMax(BCS_Vitality));
	thePlayer.GMTestDiffHitsClear();
	thePlayer.GMTestSetProbes(true);
	for(i = 0; i < thePlayer.gmTestDummies.Size(); i += 1)
		if(thePlayer.gmTestDummies[i])
			thePlayer.gmTestDummies[i].SetAnimationSpeedMultiplier(1);
	LogChannel('GMTest', "INFO DIFF-06 " + thePlayer.gmTestDummies.Size() + " enemies unfrozen near Ciri on " + GMTestDiffModeName(theGame.GetDifficultyMode()) + "; Ciri immortal");
}

exec function gmtest_diff06_fight_b()
{
	var i, n : int;
	var npc : CNewNPC;
	var w : CR4Player;

	thePlayer.GMTestCount(true, true);
	if(!GMTestDiff06IsCiri("fight"))
		return;
	w = thePlayer;
	for(i = 0; i < w.gmTestDummies.Size(); i += 1)
	{
		npc = w.gmTestDummies[i];
		if(npc)
		{
			GMTestDummyFreeze(npc);
			LogChannel('GMTest', "INFO DIFF-06 the " + npc.GetDisplayName() + ": health " + NoTrailZeros(npc.GetHealth()) + " of " + NoTrailZeros(npc.GetMaxHealth())
				+ (npc.HasAbility('CiriHardcoreDebuffHuman') ? ", CiriHardcoreDebuffHuman" : "") + (npc.HasAbility('CiriHardcoreDebuffMonster') ? ", CiriHardcoreDebuffMonster" : ""));
		}
	}
	thePlayer.GMTestSetProbes(false);
	n = GMTestDiffCheckHits("real hit on Ciri");
	GMTestReport(n >= 1, "DIFF-06 Ciri on " + GMTestDiffModeName(theGame.GetDifficultyMode()) + ": " + n + " real hits on her checked (" + w.gmTestDiffHitWho.Size() + " recorded)");
	thePlayer.ForceSetStat(BCS_Vitality, thePlayer.GetStatMax(BCS_Vitality));
	thePlayer.SetImmortalityMode(AIM_None, AIC_Default, true);
	LogChannel('GMTest', "SUMMARY diff06_fight: " + thePlayer.gmTestPassed + " passed, " + thePlayer.gmTestFailed + " failed");
}
