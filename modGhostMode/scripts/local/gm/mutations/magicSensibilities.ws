// MUT-03 Magic Sensibilities (Mutation 2): Signs crit with a chance of 5% + 40% of the sign's power
// bonus and deal +25% + 187.5% of it as crit damage (the power bonus from GMSignPowerStatToPowerBonus:
// 0 at no intensity, 0.75 at 100%, 2.0 at 500%). Vanilla: 20% + 10% and 100% of the raw intensity.
// The crit damage is in GetAttackersPowerMod (damage/formula.ws), the values in gm_mutations.xml.
// See docs/features/mut.md.

function GMMutation2CritChance(signPower : SAbilityAttributeValue) : float
{
	var min, max : SAbilityAttributeValue;

	theGame.GetDefinitionsManager().GetAbilityAttributeValue('Mutation2', 'crit_chance_factor', min, max);
	return min.valueAdditive + GMSignPowerStatToPowerBonus(signPower.valueMultiplicative) * min.valueMultiplicative;
}

function GMMutation2CritDamage(signPower : SAbilityAttributeValue) : float
{
	var min, max : SAbilityAttributeValue;

	theGame.GetDefinitionsManager().GetAbilityAttributeValue('Mutation2', 'crit_damage_factor', min, max);
	return min.valueAdditive + GMSignPowerStatToPowerBonus(signPower.valueMultiplicative) * min.valueMultiplicative;
}

// A Sign hit under Magic Sensibilities rolls legacy's chance here (vanilla's own roll in
// ProcessCriticalHitCheck is skipped for it; the rest of that function serves melee, bolts and bombs).
@wrapMethod(W3DamageManagerProcessor)
function ProcessCriticalHitCheck()
{
	var critChance : float;
	var arrStr : array<string>;

	if(!action.IsDoTDamage() && !gmWeaponsAreNotDeadly && (W3PlayerWitcher)actorAttacker && action.IsActionWitcherSign() && GetWitcherPlayer().IsMutationActive(EPMT_Mutation2))
	{
		if(FactsQuerySum('debug_fact_critical_boy') > 0)
			critChance = 1.f;
		else
			critChance = GMMutation2CritChance(action.GetPowerStatValue());
		if(RandF() < critChance)
		{
			action.SetCriticalHit();
			arrStr.PushBack(action.attacker.GetDisplayName());
			theGame.witcherLog.AddCombatMessage(theGame.witcherLog.COLOR_GOLD_BEGIN + GetLocStringByKeyExtWithParams("hud_combat_log_critical_hit",,,arrStr) + theGame.witcherLog.COLOR_GOLD_END, action.attacker, NULL);
		}
		return;
	}
	wrappedMethod();
}
