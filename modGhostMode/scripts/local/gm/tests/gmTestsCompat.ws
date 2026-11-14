// Checks for the forms Ghost Mode uses so that sibling ports (TrianglePreparations, TriangleFriendlyMeditation)
// combine with it as separate blobs in any load order (docs/development.md, "Other mods and vanilla code").
//   GMTest_compat()   in gmtest_regress(): scripted checks, no fight or input; each restores what it changes.

exec function gmtest_compat()
{
	thePlayer.GMTestCount(true, true);
	GMTest_compat();
	LogChannel('GMTest', "SUMMARY compat: " + thePlayer.gmTestPassed + " passed, " + thePlayer.gmTestFailed + " failed");
}

function GMTest_compat()
{
	GMTest_compat_maxammo();
}

// SingletonItemGetMaxAmmo is a wrapper adding the difference between Ghost Mode's and 5.x's bomb formula
// (skills/heavyArtilleryTrickShot.ws). With no other mod wrapping it, a bomb's stack must equal Ghost Mode's
// formula in every skill state (which holds only if the wrapper's copy of 5.x's formula matches 5.x's own),
// and a potion's must be untouched by it.
function GMTest_compat_maxammo()
{
	var w : W3PlayerWitcher;
	var inv : CInventoryComponent;
	var heavy, otherHeavy : ESkill;
	var hadEff, hadPyro, hadHeavy, hadOther, hadBomb, hadPotion : bool;
	var bomb, potion : array<SItemUniqueId>;

	w = GetWitcherPlayer();
	inv = w.inv;
	if(GMIsClassicProfileInForce())
	{
		heavy = S_Perk_20; otherHeavy = S_Perk_43;
	}
	else
	{
		heavy = S_Perk_43; otherHeavy = S_Perk_20;
	}
	hadBomb = inv.GetItemQuantityByName('Dancing Star 1') > 0;
	hadPotion = inv.GetItemQuantityByName('Swallow 1') > 0;
	bomb = inv.GetItemsByName('Dancing Star 1');
	if(bomb.Size() == 0)
		bomb = inv.AddAnItem('Dancing Star 1', 1);
	potion = inv.GetItemsByName('Swallow 1');
	if(potion.Size() == 0)
		potion = inv.AddAnItem('Swallow 1', 1);

	hadEff = GMTestAlchSkillOn(S_Alchemy_s08, false);
	hadPyro = GMTestAlchSkillOn(S_Alchemy_s10, false);
	hadHeavy = GMTestAlchSkillOn(heavy, false);
	hadOther = GMTestAlchSkillOn(otherHeavy, false);

	GMTestCompatBombAmmo(inv, bomb[0], "no bomb skills");
	GMTestAlchSkillOn(S_Alchemy_s08, true);
	GMTestCompatBombAmmo(inv, bomb[0], "Efficiency level " + w.GetSkillLevel(S_Alchemy_s08));
	GMTestAlchSkillOn(heavy, true);
	GMTestCompatBombAmmo(inv, bomb[0], "Efficiency and Heavy Artillery (" + SkillEnumToName(heavy) + ")");
	GMTestAlchSkillOn(S_Alchemy_s10, true);
	GMTestCompatBombAmmo(inv, bomb[0], "Efficiency, Heavy Artillery and Pyrotechnics");
	GMTestReport(inv.SingletonItemGetMaxAmmo(potion[0]) == RoundMath(CalculateAttributeValue(inv.GetItemAttributeValue(potion[0], 'ammo'))),
		"compat: Swallow 1's stack untouched by the bomb wrapper (" + inv.SingletonItemGetMaxAmmo(potion[0]) + ")");

	GMTestAlchSkillOn(S_Alchemy_s10, hadPyro);
	GMTestAlchSkillOn(heavy, hadHeavy);
	GMTestAlchSkillOn(otherHeavy, hadOther);
	GMTestAlchSkillOn(S_Alchemy_s08, hadEff);
	if(!hadBomb)
		inv.RemoveItemByName('Dancing Star 1', -1);
	if(!hadPotion)
		inv.RemoveItemByName('Swallow 1', -1);
}

function GMTestCompatBombAmmo(inv : CInventoryComponent, id : SItemUniqueId, situation : string)
{
	var got, gm, vanilla : int;

	got = inv.SingletonItemGetMaxAmmo(id);
	gm = inv.GMBombMaxAmmo(id, true);
	vanilla = inv.GMBombMaxAmmo(id, false);
	GMTestReport(got == gm, "compat: Dancing Star 1's stack with " + situation + " is Ghost Mode's " + gm + " (got " + got + ", 5.x's formula " + vanilla + ")");
}
