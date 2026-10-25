// FOOD-06: Connoisseur (legacy's perk_15 "Foodie" reworked) in both trees: the classic perk_15 and the new
// tree's perk_41, 1 level (the owner's DF7; abilities in gm_skill_trees.xml). No toxicity and no drunkenness
// from alcohol and raw food (food/toxicity.ws, GMHasConnoisseur); an alcohol's Well Fed and Well Hydrated
// last 100% longer (duration_bonus); unequipping it keeps the share of time left of the running food
// effects. 5.x's Gourmet (food lasting 20 minutes) and Gourmand (5 minutes per level, ended when
// unequipped) are gone.
// See docs/features/food.md.

// Connoisseur's duration bonus for an alcohol's effects (0 when not equipped).
@addMethod(W3PlayerWitcher)
function GMConnoisseurDurationBonus() : float
{
	var v : SAbilityAttributeValue;

	if(CanUseSkill(S_Perk_15))
		v = GetSkillAttributeValue(S_Perk_15, 'duration_bonus', false, false);
	else if(CanUseSkill(S_Perk_41))
		v = GetSkillAttributeValue(S_Perk_41, 'duration_bonus', false, false);
	return v.valueMultiplicative;
}

// 5.x body; changes marked //modSigns.
@replaceMethod(W3Effect_WellFed)
function Init(params : SEffectInitInfo)
{
	//modSigns: removed the local of Gourmand's duration

	super.Init(params);

	//modSigns: removed 5.x's Gourmand (perk_41: Well Fed lasting 5 minutes per level)
}

// 5.x body; changes marked //modSigns.
@replaceMethod(W3Effect_WellFed)
function OnPerk15Unequipped()
{
	var timeLeftPrc : float;	//modSigns
	timeLeftPrc = timeLeft / duration;	//modSigns: legacy, the share of time left is kept
	SetTimeLeft( initialDuration * timeLeftPrc );	//modSigns
	duration = initialDuration;
}

// Gourmand is gone: Connoisseur on perk_41 changes nothing while it is equipped.
@replaceMethod(W3Effect_WellFed)
function OnPerk41Updated()
{
	//modSigns: removed 5.x's Gourmand (perk_41 adding 5 minutes per level)
}

// Connoisseur unequipped from perk_41: as from perk_15 (legacy's rule).
@replaceMethod(W3Effect_WellFed)
function OnPerk41Unequipped()
{
	OnPerk15Unequipped();	//modSigns: FOOD-06, Connoisseur's unequip rule (5.x ended Well Fed)
}

// 5.x body; changes marked //modSigns.
@replaceMethod(W3Effect_WellFed)
function CalculateDuration(optional setInitialDuration : bool)
{
	var min, max : SAbilityAttributeValue;
	
	super.CalculateDuration(setInitialDuration);
	
	if( isOnPlayer && GetWitcherPlayer() )
	{	
		
		if( sourceName == "alcohol" )	//modSigns: FOOD-06, Connoisseur: an alcohol's effects last longer (5.x's Gourmet set 20 minutes)
		{
			duration *= 1 + GetWitcherPlayer().GMConnoisseurDurationBonus();	//modSigns
		}

		if( GetWitcherPlayer().HasRunewordActive( 'Runeword 6 _Stats' ) )
		{
			theGame.GetDefinitionsManager().GetAbilityAttributeValue('Runeword 6 _Stats', 'runeword6_duration_bonus', min, max);
			duration *= ( 1 + min.valueMultiplicative );
		}
	}
}

// Well Hydrated keeps its share of time left too when Connoisseur is unequipped (legacy).
@addMethod(W3Effect_WellHydrated)
function GMOnConnoisseurUnequipped()
{
	var timeLeftPrc : float;

	timeLeftPrc = timeLeft / duration;
	SetTimeLeft( initialDuration * timeLeftPrc );
	duration = initialDuration;
}

@wrapMethod(W3PlayerAbilityManager)
function OnSkillUnequip(skill : ESkill)
{
	var water : W3Effect_WellHydrated;

	wrappedMethod(skill);
	if(skill == S_Perk_15 || skill == S_Perk_41)
	{
		water = (W3Effect_WellHydrated)owner.GetBuff(EET_WellHydrated);
		if(water)
			water.GMOnConnoisseurUnequipped();
	}
}
