// DIFF slice D2 (docs/features/diff.md): DIFF-02, the expansions' per-enemy difficulty variants (legacy's 50:
// 37 emptied or added empty, 13 retuned). The data are in the regression's data check (GMTest_diffdata, the
// generated tests/gmTestsDiffData.ws). In game, on modes set through the game's own path (GMTestDiffSetMode,
// tests/gmTestsDiff.ws); each call that changes the mode sets back the one it found:
//   gmtest_diff02_a()          spawns frozen neutral enemies with variants (a kikimore worker and warrior, a
//                              shaelmaar, a slyzard, a Toussaint guard knight (knight_hansa), Olgierd); logs who has which
//                              parent ability
//   gmtest_diff02_modes()      sets each mode in turn: each enemy has only its mode's variant, and its stats move
//                              from "Story and Sword!" by legacy's variant alone
//   gmtest_diff02_b()          removes them
// The drunken master (ff701_master), a real fistfight on "Death March!": gmtest_diff_mode(EDM_Hardcore), then
//   gmtest_ai20_a("dlc/bob/data/quests/minor_quests/quest_files/ff701_fistfights/ff701_drunken_master/characters/ff701_master.w2ent")
//   gmtest_diff02_master()     reads his fist damage bonus: his tier's, +50 on "Death March!" (mon_EP2_hardcore_FF)
//   gmtest_ai20_start(), punches (C3EV lines), gmtest_diff02_fists() checks every punch on Geralt carried his
//   "Death March!" bonus, gmtest_ai19_b() ends the fight

@addField(CR4Player)
var gmTestDiff02Npcs : array<CNewNPC>;
@addField(CR4Player)
var gmTestDiff02Kinds : array<string>;
@addField(CR4Player)
var gmTestDiff02Fists : array<float>;
@addField(CR4Player)
var gmTestDiff02MasterTier : float;	// his tier's bonus
@addField(CR4Player)
var gmTestDiff02MasterBonus : float;	// his bonus at the spawn

@addMethod(CR4Player)
function GMTestDiff02Add(npc : CNewNPC, kind : string)
{
	gmTestDiff02Npcs.PushBack(npc);
	gmTestDiff02Kinds.PushBack(kind);
}

@addMethod(CR4Player)
function GMTestDiff02Clear()
{
	gmTestDiff02Npcs.Clear();
	gmTestDiff02Kinds.Clear();
}

@addMethod(CR4Player)
function GMTestDiff02RecordFist(bonus : float)
{
	gmTestDiff02Fists.PushBack(bonus);
}

@addMethod(CR4Player)
function GMTestDiff02SetMaster(tier : float, bonus : float)
{
	gmTestDiff02MasterTier = tier;
	gmTestDiff02MasterBonus = bonus;
	gmTestDiff02Fists.Clear();
}

// The kind of enemy by its parent ability (the one that lists the variants).
function GMTestDiff02Kind(npc : CNewNPC) : string
{
	if( npc.HasAbility('mon_kikimora_worker') )		return "kikimore worker";
	if( npc.HasAbility('mon_kikimora_warrior') )	return "kikimore warrior";
	if( npc.HasAbility('mon_sharley_base') )		return "shaelmaar";
	if( npc.HasAbility('mon_draco_base') )			return "slyzard";
	if( npc.HasAbility('guardKnight') )				return "guard knight";
	if( npc.HasAbility('olgierd_default_stats') )	return "Olgierd";
	return "";
}

// The variants the kind's parent lists, and the mode each is tagged with.
function GMTestDiff02Variants(kind : string, out names : array<name>, out modes : array<EDifficultyMode>)
{
	names.Clear();
	modes.Clear();
	switch( kind )
	{
		case "kikimore worker":
			names.PushBack('kikimora_easy');			modes.PushBack(EDM_Easy);
			names.PushBack('kikimora_normal');			modes.PushBack(EDM_Medium);
			names.PushBack('kikimora_hard');			modes.PushBack(EDM_Hard);
			names.PushBack('kikimora_hardcore');		modes.PushBack(EDM_Hardcore);
			break;
		case "kikimore warrior":
			names.PushBack('kikimora_easy');			modes.PushBack(EDM_Easy);
			names.PushBack('kikimora_normal');			modes.PushBack(EDM_Medium);
			names.PushBack('kikimora_hard');			modes.PushBack(EDM_Hard);
			names.PushBack('kikimora_hardcore_big');	modes.PushBack(EDM_Hardcore);
			break;
		case "shaelmaar":
			names.PushBack('sharley_easy');				modes.PushBack(EDM_Easy);
			names.PushBack('sharley_medium');			modes.PushBack(EDM_Medium);
			names.PushBack('sharley_hardcore');			modes.PushBack(EDM_Hardcore);
			break;
		case "slyzard":
			names.PushBack('mon_draco_easy');			modes.PushBack(EDM_Easy);
			names.PushBack('mon_draco_normal');			modes.PushBack(EDM_Medium);
			names.PushBack('mon_draco_hardcore');		modes.PushBack(EDM_Hardcore);
			break;
		case "guard knight":
			names.PushBack('mon_gaurdknight_hard');		modes.PushBack(EDM_Hard);
			names.PushBack('mon_gaurdknight_hardcore');	modes.PushBack(EDM_Hardcore);
			break;
		case "Olgierd":
			names.PushBack('mon_olgierdeasy_ep1');		modes.PushBack(EDM_Easy);
			names.PushBack('mon_olgierdmedium_ep1');	modes.PushBack(EDM_Medium);
			names.PushBack('mon_olgierdhard_ep1');		modes.PushBack(EDM_Hard);
			names.PushBack('mon_olgierhardcore_ep1');	modes.PushBack(EDM_Hardcore);
			break;
	}
}

// The stats the variants touch (legacy's or 5.x's).
function GMTestDiff02Attrs() : array<name>
{
	var a : array<name>;

	a.PushBack('toxicityVenom');
	a.PushBack('attack_power');
	a.PushBack('essence');
	a.PushBack('vitality');
	a.PushBack('armor');
	a.PushBack('poison_resistance_perc');
	a.PushBack('poison_DoT_damage_resistance_perc');
	a.PushBack('burning_resistance_perc');
	a.PushBack('igni_damage_amplifier');
	return a;
}

// Legacy's change of a stat from "Story and Sword!" to `mode` (the mode's variant minus the Medium one), as base,
// mult and add; 0 where legacy's variants have nothing. 5.x's in the comments.
function GMTestDiff02Want(kind : string, mode : EDifficultyMode, attr : name, out b : float, out m : float, out a : float)
{
	b = 0; m = 0; a = 0;
	switch( kind )
	{
		case "kikimore worker":	// 5.x: venom -0.005, +0.01, +0.025; Death March essence x+0.1, igni amplifier +9
			if( attr == 'toxicityVenom' && mode == EDM_Easy )		m = -0.005;
			if( attr == 'toxicityVenom' && mode == EDM_Hard )		m = 0.005;
			if( attr == 'toxicityVenom' && mode == EDM_Hardcore )	m = 0.01;
			break;
		case "kikimore warrior":	// 5.x: venom -0.005, +0.01, +0.045; Death March attack power x+0.15
			if( attr == 'toxicityVenom' && mode == EDM_Easy )		m = -0.005;
			if( attr == 'toxicityVenom' && mode == EDM_Hard )		m = 0.005;
			if( attr == 'toxicityVenom' && mode == EDM_Hardcore )	m = 0.015;
			break;
		case "shaelmaar":	// 5.x: Easy armor -200, attack power and essence x-0.5 (Medium x-0.3); Death March poison resistance +0.5
			if( attr == 'armor' && mode == EDM_Easy )								b = -150;
			if( attr == 'poison_resistance_perc' && mode == EDM_Hardcore )			a = 0.2;
			if( attr == 'poison_DoT_damage_resistance_perc' && mode == EDM_Hardcore )	b = 0.2;
			break;
		// slyzard (5.x: attack power x-0.5, x-0.2, x+0.4 and essence x+0.4, igni amplifier +9 on all but
		// "Blood and Broken Bones!"), guard knight (5.x: the two higher modes vitality x+4, armor +40), Olgierd
		// (5.x: the two higher modes vitality x+0.5, attack power x-0.2 and x-0.3): nothing on any mode
	}
}

// Through the character stats: the ability manager answers -9999 for the resistances (forbidden attributes).
function GMTestDiff02Read(npc : CNewNPC, attr : name) : SAbilityAttributeValue
{
	var noTags : array<name>;

	return npc.GetCharacterStats().GetAttributeValue(attr, noTags);
}

exec function gmtest_diff02_a()
{
	var paths : array<string>;
	var npc : CNewNPC;
	var i : int;
	var kind : string;

	thePlayer.GMTestDiff02Clear();
	paths.PushBack("dlc/bob/data/characters/npc_entities/monsters/kikimore_small.w2ent");
	paths.PushBack("dlc/bob/data/characters/npc_entities/monsters/kikimore.w2ent");
	paths.PushBack("dlc/bob/data/characters/npc_entities/monsters/sharley.w2ent");
	paths.PushBack("dlc/bob/data/living_world/enemy_templates/dracolizard.w2ent");
	paths.PushBack("dlc/bob/data/living_world/quests/scenes/characters/knight_hansa.w2ent");	// the only entity with guardKnight
	paths.PushBack("dlc/ep1/data/quests/main_npcs/olgierd.w2ent");	// the only entity with olgierd_default_stats
	for( i = 0; i < paths.Size(); i += 1 )
	{
		npc = GMTestAi15Spawn(paths[i], 14 + 4 * (i % 3), -12 + 8 * (i / 3));
		if( !npc )
		{
			LogChannel('GMTest', "INFO DIFF-02 no NPC from " + paths[i]);
			continue;
		}
		kind = GMTestDiff02Kind(npc);
		LogChannel('GMTest', "INFO DIFF-02 spawned " + npc.GetReadableName() + " from " + paths[i] + ": " + (kind == "" ? "no parent ability with variants" : kind));
		if( kind == "" )
			npc.Destroy();
		else
			thePlayer.GMTestDiff02Add(npc, kind);
	}
	LogChannel('GMTest', "INFO DIFF-02 " + thePlayer.gmTestDiff02Npcs.Size() + " enemies kept on " + GMTestDiffModeName(theGame.GetDifficultyMode()) + "; read them in a later call");
}

exec function gmtest_diff02_b()
{
	var i : int;

	for( i = 0; i < thePlayer.gmTestDiff02Npcs.Size(); i += 1 )
		if( thePlayer.gmTestDiff02Npcs[i] )
			thePlayer.gmTestDiff02Npcs[i].Destroy();
	thePlayer.GMTestDiff02Clear();
	LogChannel('GMTest', "INFO DIFF-02 enemies removed");
}

// Each mode in turn on every spawned enemy: only the variant tagged with that mode among its parent's, and each
// stat's change from "Story and Sword!" legacy's variant alone. Sets back the mode it found.
exec function gmtest_diff02_modes()
{
	var start, mode : EDifficultyMode;
	var modes, vmodes : array<EDifficultyMode>;
	var names : array<name>;
	var attrs : array<name>;
	var base : array<SAbilityAttributeValue>;
	var npc : CNewNPC;
	var kind, held, wrong, stats : string;
	var i, k, j, m, bad : int;
	var v : SAbilityAttributeValue;
	var wb, wm, wa, db, dm, da : float;

	thePlayer.GMTestCount(true, true);
	start = theGame.GetDifficultyMode();
	attrs = GMTestDiff02Attrs();
	modes.PushBack(EDM_Medium); modes.PushBack(EDM_Easy); modes.PushBack(EDM_Hard); modes.PushBack(EDM_Hardcore);
	for( m = 0; m < modes.Size(); m += 1 )
	{
		mode = modes[m];
		GMTestDiffSetMode(mode);
		for( i = 0; i < thePlayer.gmTestDiff02Npcs.Size(); i += 1 )
		{
			npc = thePlayer.gmTestDiff02Npcs[i];
			kind = thePlayer.gmTestDiff02Kinds[i];
			if( !npc )
				continue;
			GMTestDiff02Variants(kind, names, vmodes);
			held = "";
			wrong = "";
			for( k = 0; k < names.Size(); k += 1 )
			{
				if( npc.HasAbility(names[k]) )
					held += " " + names[k];
				if( npc.HasAbility(names[k]) != (vmodes[k] == mode) )
					wrong += " " + names[k];
			}
			bad = 0;
			stats = "";
			for( j = 0; j < attrs.Size(); j += 1 )
			{
				v = GMTestDiff02Read(npc, attrs[j]);
				if( m == 0 )
				{
					base.PushBack(v);
					continue;
				}
				db = v.valueBase - base[i * attrs.Size() + j].valueBase;
				dm = v.valueMultiplicative - base[i * attrs.Size() + j].valueMultiplicative;
				da = v.valueAdditive - base[i * attrs.Size() + j].valueAdditive;
				GMTestDiff02Want(kind, mode, attrs[j], wb, wm, wa);
				if( AbsF(db - wb) > 0.001 || AbsF(dm - wm) > 0.0001 || AbsF(da - wa) > 0.001 )
				{
					bad += 1;
					stats += " " + attrs[j] + " " + NoTrailZeros(db) + "/" + NoTrailZeros(dm) + "/" + NoTrailZeros(da) + " (legacy's " + NoTrailZeros(wb) + "/" + NoTrailZeros(wm) + "/" + NoTrailZeros(wa) + ")";
				}
				else if( wb != 0 || wm != 0 || wa != 0 )
					stats += " " + attrs[j] + " " + NoTrailZeros(db) + "/" + NoTrailZeros(dm) + "/" + NoTrailZeros(da) + " as legacy's";
			}
			if( m == 0 )
				GMTestReport(wrong == "", "DIFF-02 " + GMTestDiffModeName(mode) + ": the " + kind + " (" + npc.GetReadableName() + ") holds" + (held == "" ? " no variant" : held)
					+ (wrong == "" ? " (its mode's only)" : "; wrong:" + wrong) + "; the base the other modes are read against");
			else
				GMTestReport(wrong == "" && bad == 0, "DIFF-02 " + GMTestDiffModeName(mode) + ": the " + kind + " holds" + (held == "" ? " no variant" : held)
					+ (wrong == "" ? " (its mode's only)" : "; wrong:" + wrong) + "; change from Story and Sword! (base/mult/add):" + (stats == "" ? " none, as legacy's" : stats));
		}
	}
	GMTestDiffSetMode(start);
	LogChannel('GMTest', "INFO DIFF-02 mode set back to " + GMTestDiffModeName(theGame.GetDifficultyMode()));
	LogChannel('GMTest', "SUMMARY diff02_modes: " + thePlayer.gmTestPassed + " passed, " + thePlayer.gmTestFailed + " failed");
}

// The drunken master spawned by gmtest_ai20_a on the current mode: his fist damage bonus is his fistfight tier's,
// +50 on "Death March!" (mon_EP2_hardcore_FF, in his entity's own ability list). An entity's own variant is chosen
// when it spawns: a later mode change removes it and does not add it back, so spawn him on the mode to test.
exec function gmtest_diff02_master()
{
	var npc : CNewNPC;
	var bonus, tier, want : float;
	var held, wantHeld : bool;
	var tiers : array<name>;
	var i : int;
	var b, m, a : float;

	thePlayer.GMTestCount(true, true);
	npc = thePlayer.gmTestAi19Npc;
	if( !npc )
	{
		LogChannel('GMTest', "FAIL DIFF-02 no drunken master (gmtest_ai20_a first)");
		return;
	}
	tiers.PushBack('StatsFistsTutorial'); tiers.PushBack('StatsFistsEasy'); tiers.PushBack('StatsFistsMedium'); tiers.PushBack('StatsFistsHard');
	tiers.PushBack('SkillFistsEasy'); tiers.PushBack('SkillFistsMedium'); tiers.PushBack('SkillFistsHard');
	for( i = 0; i < tiers.Size(); i += 1 )
		if( npc.HasAbility(tiers[i]) )
		{
			GMTestAiAbl(tiers[i], 'fist_dmg_bonus', b, m, a);
			tier += b + a;
		}
	bonus = CalculateAttributeValue(npc.GetAttributeValue('fist_dmg_bonus'));
	held = npc.HasAbility('mon_EP2_hardcore_FF');
	wantHeld = theGame.GetDifficultyMode() == EDM_Hardcore;
	want = tier;
	if( wantHeld )
		want += 50;
	thePlayer.GMTestDiff02SetMaster(tier, bonus);
	GMTestReport(held == wantHeld && AbsF(bonus - want) < 0.01, "DIFF-02 the drunken master spawned on " + GMTestDiffModeName(theGame.GetDifficultyMode()) + " (level " + npc.GetLevel() + "): mon_EP2_hardcore_FF held " + held
		+ ", fist damage bonus " + NoTrailZeros(bonus) + " (want " + NoTrailZeros(want) + ": his tier's " + NoTrailZeros(tier) + (wantHeld ? " + legacy's 50; 5.x: + 0 and attack power x+0.8)" : ")"));
	LogChannel('GMTest', "SUMMARY diff02_master: " + thePlayer.gmTestPassed + " passed, " + thePlayer.gmTestFailed + " failed");
}

// After a real fistfight on "Death March!": every punch of the master's on Geralt during the minigame had his "Death March!" bonus
// added before the pool (the C3EV probe), which is his "Story and Sword!" bonus + 50.
exec function gmtest_diff02_fists()
{
	var i, ok : int;
	var s : string;

	thePlayer.GMTestCount(true, true);
	for( i = 0; i < thePlayer.gmTestDiff02Fists.Size(); i += 1 )
	{
		s += " " + NoTrailZeros(thePlayer.gmTestDiff02Fists[i]);
		if( AbsF(thePlayer.gmTestDiff02Fists[i] - thePlayer.gmTestDiff02MasterBonus) < 0.01 )
			ok += 1;
	}
	GMTestReport(ok > 0 && ok == thePlayer.gmTestDiff02Fists.Size() && theGame.GetDifficultyMode() == EDM_Hardcore && AbsF(thePlayer.gmTestDiff02MasterBonus - thePlayer.gmTestDiff02MasterTier - 50) < 0.01,
		"DIFF-02 real punches of the drunken master on Geralt on " + GMTestDiffModeName(theGame.GetDifficultyMode()) + ": " + thePlayer.gmTestDiff02Fists.Size() + " punches, fist bonus before the pool:" + s
		+ " (want " + NoTrailZeros(thePlayer.gmTestDiff02MasterTier) + " + 50 each, his tier's and legacy's Death March! bonus; read at the start " + NoTrailZeros(thePlayer.gmTestDiff02MasterBonus) + ")");
	LogChannel('GMTest', "SUMMARY diff02_fists: " + thePlayer.gmTestPassed + " passed, " + thePlayer.gmTestFailed + " failed");
}

// Debugging aid: on each spawned enemy, whether it holds `abl`, that ability's `attr` as the enemy's ability
// manager reads it, and the enemy's total `attr`.
exec function gmtest_diff02_abl(abl : name, attr : name)
{
	var i : int;
	var npc : CNewNPC;
	var a, t : SAbilityAttributeValue;

	for( i = 0; i < thePlayer.gmTestDiff02Npcs.Size(); i += 1 )
	{
		npc = thePlayer.gmTestDiff02Npcs[i];
		if( !npc )
			continue;
		a = npc.GetCharacterStats().GetAbilityAttributeValue(attr, abl);
		t = GMTestDiff02Read(npc, attr);
		LogChannel('GMTest', "INFO DIFF-02 the " + thePlayer.gmTestDiff02Kinds[i] + " on " + GMTestDiffModeName(theGame.GetDifficultyMode()) + ": holds " + abl + " " + npc.HasAbility(abl)
			+ ", its " + attr + " " + NoTrailZeros(a.valueBase) + "/" + NoTrailZeros(a.valueMultiplicative) + "/" + NoTrailZeros(a.valueAdditive)
			+ ", total " + NoTrailZeros(t.valueBase) + "/" + NoTrailZeros(t.valueMultiplicative) + "/" + NoTrailZeros(t.valueAdditive));
	}
}
