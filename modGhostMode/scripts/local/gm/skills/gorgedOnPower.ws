// SKL-18: Gorged on Power, legacy's (and 5.x's classic) in both trees (D61; classic perk_14, the new tree's
// perk_43 in place of 5.x's Synergy perk, which moved to alchemy_s26 with SKL-16, D60): a Place of Power's
// bonus lasts indefinitely, one at a time. 5.x's code asks CanUseSkill(S_Perk_14) at every site (the
// shrine's timer, a new Place of Power, the effect cleanup, Mutagen 23, the HUD); while the new tree's
// profile is in force that question is answered for perk_43 (a character with no profile keeps 5.x's
// skills: perk_14 answers for itself). (5.x's own handling when perk_14 is equipped, which keeps
// only the newest shrine bonus, does not run for perk_43: the next Place of Power does the same.)
// 5.x's Synergy perk on perk_43 is gone: the mutagen Synergy bonus follows the Synergy skill's level.
// See docs/features/skl.md.

@wrapMethod(CR4Player)
function CanUseSkill(skill : ESkill) : bool
{
	var asked : ESkill;

	asked = skill;
	if(skill == S_Perk_14 && GMIsNewTreeProfileInForce())
		asked = S_Perk_43;
	return wrappedMethod(asked);
}

// 5.x's Synergy perk (perk_43) passed its own level to the mutagen bonus; the level is Synergy's
// (alchemy_s19, or the new tree's alchemy_s26: skills/mutation.ws), whatever the caller passes.
@wrapMethod(W3PlayerAbilityManager)
function MutagensSyngergyBonusUpdate( skillGroupID : int, skillLevel : int )
{
	wrappedMethod(skillGroupID, GMSynergyLevel());
}
