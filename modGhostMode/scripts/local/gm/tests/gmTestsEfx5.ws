// EFX slice 5's tests (docs/features/efx.md): EFX-08 effect resistance point names.
// GMTest_efx08() runs in gmtest_regress().
//
// In play (the neutral test dummy, see gmTestsEfx.ws):
//   gmtest_efx08_points()                       the dummy given 10 points of bleeding, will and burning
//                                               resistance through abilities (the test dummy's step
//                                               abilities): the game reads them as points
//   exec --wait 7000 "gmtest_efx01_apply(\"hypnosis\", 0.4)"   hypnosis at 40% will resistance: 3 s of 5

exec function gmtest_efx08()
{
	GMTest_efx08();
}

function GMTestEfx08Name(n : name, stat : ECharacterDefenseStats, point : bool) : bool
{
	var isPoint : bool;
	var got : ECharacterDefenseStats;
	var back : name;

	got = ResistStatNameToEnum(n, isPoint);
	back = ResistStatEnumToName(stat, point);
	GMTestReport(got == stat && isPoint == point && back == n, "EFX-08 " + n + " <-> " + stat + " (point " + point + "): read " + got + " (point " + isPoint + "), named back " + back);
	return got == stat;
}

// The point names of bleeding, will and burning resistance, both ways; the other names unchanged.
function GMTestEfx08Entry(effectName : name)
{
	var isPoint : bool;
	var dm : CDefinitionsManagerAccessor;
	var effects : SCustomNode;
	var i : int;
	var tmpName, resName : name;
	var found : bool;

	dm = theGame.GetDefinitionsManager();
	effects = dm.GetCustomDefinition('effects');
	for(i = 0; i < effects.subNodes.Size() && !found; i += 1)
	{
		dm.GetCustomNodeAttributeValueName(effects.subNodes[i], 'name_name', tmpName);
		if(tmpName == effectName)
		{
			dm.GetCustomNodeAttributeValueName(effects.subNodes[i], 'resistStatName_name', resName);
			found = true;
		}
	}
	GMTestReport(found && ResistStatNameToEnum(resName, isPoint) == CDS_WillRes, "EFX-08 " + effectName + "'s effect entry (found " + found + ") names its resistance " + resName + ", read as " + ResistStatNameToEnum(resName, isPoint) + " (5.x: none)");
}

function GMTest_efx08()
{
	var isPoint : bool;
	var pts, prc, sum : float;

	GMTestEfx08Name('bleeding_resistance', CDS_BleedingRes, true);
	GMTestEfx08Name('will_resistance', CDS_WillRes, true);
	GMTestEfx08Name('burning_resistance', CDS_BurningRes, true);
	GMTestEfx08Name('bleeding_resistance_perc', CDS_BleedingRes, false);
	GMTestEfx08Name('will_resistance_perc', CDS_WillRes, false);
	GMTestEfx08Name('burning_resistance_perc', CDS_BurningRes, false);
	GMTestEfx08Name('frost_resistance', CDS_FrostRes, true);
	GMTestEfx08Name('poison_resistance_perc', CDS_PoisonRes, false);
	GMTestReport(ResistStatNameToEnum('gm_no_such_resistance', isPoint) == CDS_None && ResistStatEnumToName(CDS_None, true) == '', "EFX-08 an unknown name stays unknown");

	// Hypnosis's effect entries (Geralt's Axii and the witch's) name will_resistance, which now reads
	// as will resistance.
	GMTestEfx08Entry('HypnotizedEffect');
	GMTestEfx08Entry('WitchHypnotizedEffect');

	// 5.x's data gives no such points (all 0, or registrations with a multiplier of 1): Geralt has none.
	thePlayer.GetResistValue(CDS_BleedingRes, pts, prc);
	sum = AbsF(pts);
	thePlayer.GetResistValue(CDS_WillRes, pts, prc);
	sum += AbsF(pts);
	thePlayer.GetResistValue(CDS_BurningRes, pts, prc);
	sum += AbsF(pts);
	GMTestReport(sum < 0.001, "EFX-08 Geralt's bleeding, will and burning resistance points read 0 (" + NoTrailZeros(sum) + " in all)");
}

exec function gmtest_efx08_points()
{
	var npc : CNewNPC;
	var pts, prc : float;
	var stats : array<ECharacterDefenseStats>;
	var names : array<name>;
	var i : int;
	var ok : bool;

	npc = GMTestDummy();
	if(!npc)
	{
		GMTestReport(false, "EFX-08 no test dummy");
		return;
	}
	names.PushBack('bleeding_resistance'); stats.PushBack(CDS_BleedingRes);
	names.PushBack('will_resistance'); stats.PushBack(CDS_WillRes);
	names.PushBack('burning_resistance'); stats.PushBack(CDS_BurningRes);
	for(i = 0; i < names.Size(); i += 1)
	{
		ok = GMTestDummySet(npc, names[i], 10);
		npc.GetResistValue(stats[i], pts, prc);
		GMTestReport(ok && AbsF(pts - 10) < 0.001 && AbsF(prc) < 0.001, "EFX-08 the dummy given 10 points of " + names[i] + " by an ability: the game reads " + NoTrailZeros(pts) + " points, " + NoTrailZeros(prc) + " percent (5.x: points not counted)");
		GMTestDummySet(npc, names[i], 0);
		npc.GetResistValue(stats[i], pts, prc);
		GMTestReport(AbsF(pts) < 0.001, "EFX-08 and back to " + NoTrailZeros(pts) + " points of " + names[i]);
	}
}
