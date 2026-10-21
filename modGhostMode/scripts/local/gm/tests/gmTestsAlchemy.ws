// In-game tests for ALCH (alchemy: toxicity, potions, decoctions, bombs, oils). See docs/features/alch.md.
// GMTest_alchport() runs the situation-free checks (in gmtest_regress()); the exec checks below need time
// or a fight.

exec function gmtest_alchport()
{
	thePlayer.GMTestCount(true, true);
	GMTest_alchport();
	LogChannel('GMTest', "SUMMARY alchport: " + thePlayer.gmTestPassed + " passed, " + thePlayer.gmTestFailed + " failed");
}

function GMTest_alchport()
{
	GMTest_alch01();
	GMTest_alch02();
	GMTest_alch04();
	GMTest_alch07();
	GMTest_alch10();
	GMTest_alch11();
	GMTest_alch12();
	GMTest_alch13();
	GMTest_alch14();
	GMTest_alch15();
	GMTest_alch16();
	GMTest_alch17();
}

// The ALCH checks that read the game a call after GMTest_alchport() (in gmtest_panel(), the regression's next call).
function GMTest_alchport_after()
{
	GMTest_alch04_after();
}

// An ability attribute's value in the definitions (add + mult + base).
function GMTestAlchValue(abilityName : name, attributeName : name) : float
{
	var min, max : SAbilityAttributeValue;

	theGame.GetDefinitionsManager().GetAbilityAttributeValue(abilityName, attributeName, min, max);
	return min.valueAdditive + min.valueMultiplicative + min.valueBase;
}

function GMTestAlchCheck(abilityName : name, attributeName : name, expected : float, label : string)
{
	var value : float;

	value = GMTestAlchValue(abilityName, attributeName);
	GMTestReport(AbsF(value - expected) < 0.0001, label + " " + abilityName + "." + attributeName + " " + NoTrailZeros(value) + " (expected " + NoTrailZeros(expected) + ")");
}

function GMTestDecoctionAbilities() : array<name>
{
	var a : array<name>;

	a.PushBack('Mutagen_1'); a.PushBack('Mutagen_2'); a.PushBack('Mutagen_3'); a.PushBack('Mutagen_4');
	a.PushBack('Mutagen_5'); a.PushBack('Mutagen_6'); a.PushBack('Mutagen_7'); a.PushBack('Mutagen_8');
	a.PushBack('Mutagen_9'); a.PushBack('Mutagen_10'); a.PushBack('Mutagen_11'); a.PushBack('Mutagen_12');
	a.PushBack('Mutagen_13'); a.PushBack('Mutagen_14'); a.PushBack('Mutagen_15'); a.PushBack('Mutagen_16');
	a.PushBack('Mutagen_17'); a.PushBack('Mutagen_18'); a.PushBack('Mutagen_19'); a.PushBack('Mutagen_20');
	a.PushBack('Mutagen_21'); a.PushBack('Mutagen_22'); a.PushBack('Mutagen_23'); a.PushBack('Mutagen_24');
	a.PushBack('Mutagen_25'); a.PushBack('Mutagen_26'); a.PushBack('Mutagen_27'); a.PushBack('Mutagen_28');
	return a;
}

// ALCH-01, ALCH-09: the threshold, the decoction offsets, and the offset functions updating the toxicity
// effect (situation-free; restores toxicity and the offset).
function GMTest_alch01()
{
	var witcher : W3PlayerWitcher;
	var names : array<name>;
	var i, bad : int;
	var tox : float;
	var had : bool;

	witcher = GetWitcherPlayer();
	GMTestReport(AbsF(theGame.params.TOXICITY_DAMAGE_THRESHOLD - 0.75) < 0.0001, "ALCH-01 overdose threshold param " + theGame.params.TOXICITY_DAMAGE_THRESHOLD + " (legacy 0.75)");
	GMTestReport(AbsF(witcher.GetToxicityDamageThreshold() - 0.75) < 0.0001, "ALCH-01 GetToxicityDamageThreshold " + witcher.GetToxicityDamageThreshold());

	names = GMTestDecoctionAbilities();
	for(i = 0; i < names.Size(); i += 1)
		if(AbsF(GMTestAlchValue(names[i], 'toxicity_offset') - 70) > 0.0001)
		{
			bad += 1;
			LogChannel('GMTest', "INFO ALCH-09 " + names[i] + " toxicity_offset " + GMTestAlchValue(names[i], 'toxicity_offset'));
		}
	GMTestReport(bad == 0 && names.Size() == 28, "ALCH-09 all 28 decoctions lock 70 toxicity (" + bad + " differ)");
	GMTestAlchCheck('Mutagen_23', 'duration', 0, "ALCH-09 Basilisk no extra duration");
	GMTestAlchCheck('CommonMutagenAbility', 'duration', 1800, "ALCH-09 decoctions 30 min");

	// The offset functions update the toxicity effect at once (5.x's did not).
	tox = witcher.GetStat(BCS_Toxicity, true);
	thePlayer.ForceSetStat(BCS_Toxicity, 0);
	had = thePlayer.HasBuff(EET_Toxicity);
	witcher.AddToxicityOffset(10);
	GMTestReport(!had && thePlayer.HasBuff(EET_Toxicity), "ALCH-01 adding locked toxicity starts the toxicity effect (before " + had + ")");
	witcher.RemoveToxicityOffset(10);
	GMTestReport(!thePlayer.HasBuff(EET_Toxicity), "ALCH-01 removing the locked toxicity ends the toxicity effect");
	thePlayer.ForceSetStat(BCS_Toxicity, tox);
}

// ALCH-01 in time: toxicity at a share of the maximum (real toxicity, no offset), Vitality full; then
// gmtest_alch01_tick() a few seconds later reports the decay rate and whether overdose damage was dealt.
exec function gmtest_alch01_set(share : float)
{
	thePlayer.ForceSetStat(BCS_Vitality, thePlayer.GetStatMax(BCS_Vitality));
	thePlayer.ForceSetStat(BCS_Toxicity, share * thePlayer.GetStatMax(BCS_Toxicity));
	thePlayer.GMTestAlchMark();
	LogChannel('GMTest', "INFO ALCH-01 set toxicity " + NoTrailZeros(thePlayer.GetStat(BCS_Toxicity)) + " of " + NoTrailZeros(thePlayer.GetStatMax(BCS_Toxicity)) + " vitality " + NoTrailZeros(thePlayer.GetStat(BCS_Vitality)) + " combat " + thePlayer.IsInCombat());
}

exec function gmtest_alch01_tick(expectOverdose : bool)
{
	var dt, decay, vit : float;

	dt = theGame.GetEngineTimeAsSeconds() - thePlayer.gmTestAlchTime;
	decay = (thePlayer.gmTestAlchTox - thePlayer.GetStat(BCS_Toxicity, true)) / dt;
	vit = thePlayer.GetStat(BCS_Vitality);
	LogChannel('GMTest', "INFO ALCH-01 after " + NoTrailZeros(RoundTo(dt, 2)) + " s: toxicity " + NoTrailZeros(RoundTo(thePlayer.GetStat(BCS_Toxicity, true), 2)) + " decay " + NoTrailZeros(RoundTo(decay, 3)) + "/s, vitality " + NoTrailZeros(RoundTo(vit, 1)) + " of " + NoTrailZeros(thePlayer.GetStatMax(BCS_Vitality)) + ", combat " + thePlayer.IsInCombat());
	GMTestReport((vit < thePlayer.GetStatMax(BCS_Vitality) - 1) == expectOverdose, "ALCH-01 overdose damage " + expectOverdose + " at " + NoTrailZeros(RoundTo(100 * thePlayer.gmTestAlchTox / thePlayer.GetStatMax(BCS_Toxicity), 1)) + "% toxicity");
}

@addField(CR4Player)
public var gmTestAlchTime : float;
@addField(CR4Player)
public var gmTestAlchTox : float;

@addMethod(CR4Player)
function GMTestAlchMark()
{
	gmTestAlchTime = theGame.GetEngineTimeAsSeconds();
	gmTestAlchTox = GetStat(BCS_Toxicity, true);
}
