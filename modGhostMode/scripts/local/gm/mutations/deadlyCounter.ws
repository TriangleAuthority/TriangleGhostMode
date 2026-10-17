// MUT-06 Deadly Counter (Mutation 8), as legacy:
// - Geralt's melee hit (not a finisher) on a living hostile NPC that he countered in the last 3 s
//   (DEF-07's per-enemy flag) and that was at 15% health or less before the hit kills it with a
//   finisher (a human, where finishers are allowed) or a dismemberment (gmMutation8Triggered, read by
//   SKL-12's finisher and dismemberment functions, skills/axii.ws);
// - a countered human that is no boss and allows finishers, at 15% health or less, is repelled straight
//   into a finisher, first in the counter's repel order (defense/counter.ws);
// - melee damage against a countered enemy is multiplied by 1 + 33.34% per adrenaline point (final
//   damage, damage/pipeline.ws); 5.x's +25% sword damage against monsters and counter-immune humans
//   is gone.
// See docs/features/mut.md.

@addField(W3DamageManagerProcessor)
var gmMutation8Triggered : bool;

// Legacy CheckMutation8Finisher, at the start of every action (the victim's health before the hit).
@wrapMethod(W3DamageManagerProcessor)
function InitializeActionVars(act : W3DamageAction)
{
	var witcher : W3PlayerWitcher;
	var npc : CNewNPC;

	wrappedMethod(act);
	witcher = (W3PlayerWitcher)playerAttacker;
	npc = (CNewNPC)actorVictim;
	gmMutation8Triggered = witcher && npc && attackAction && attackAction.IsActionMelee()
		&& act.GetBuffSourceName() != "Finisher" && act.GetBuffSourceName() != "AutoFinisher"
		&& witcher.IsMutationActive(EPMT_Mutation8) && npc.GMWasCountered() && !npc.IsImmuneToMutation8Finisher();
}

// The final-damage factor: a melee hit on a countered enemy, 1 + 33.34% per adrenaline point.
@addMethod(W3DamageManagerProcessor)
function GMMutation8DamageMult() : float
{
	var min, max : SAbilityAttributeValue;
	var witcher : W3PlayerWitcher;

	witcher = (W3PlayerWitcher)playerAttacker;
	if(!witcher || !attackAction || !attackAction.IsActionMelee() || !actorVictim || !witcher.IsMutationActive(EPMT_Mutation8) || !actorVictim.GMWasCountered())
		return 1;
	theGame.GetDefinitionsManager().GetAbilityAttributeValue('Mutation8', 'dmg_bonus', min, max);
	return 1 + min.valueMultiplicative * witcher.GetStat(BCS_Focus);
}

// Legacy's rule for the finisher on any enemy type: alive, hostile, not going unconscious, at 15%
// health or less (5.x: also humans only, no bosses, no instant-kill-immune enemies, finishers allowed;
// those rules stay for the repel to a finisher, GMMutation8RepelToFinisherImmune).
@replaceMethod(CNewNPC)
function IsImmuneToMutation8Finisher() : bool
{
	var min, max : SAbilityAttributeValue;
	var str : string;

	if( !IsAlive() || !IsRequiredAttitudeBetween( thePlayer, this, true ) )	//modSigns: any enemy type
	{
		return true;
	}

	//modSigns: removed the boss, instant-kill, Olgierd, finisher and tag exclusions (legacy; kept for the repel, GMMutation8RepelToFinisherImmune)

	if( WillBeUnconscious() )
	{
		return true;
	}

	str = GetName();
	if( StrStartsWith( str, "rosa_var_attre" ) )
	{
		return true;
	}

	theGame.GetDefinitionsManager().GetAbilityAttributeValue( 'Mutation8', 'hp_perc_trigger', min, max );
	if( GetHealthPercents() > min.valueMultiplicative )
	{
		return true;
	}

	return false;
}

// Legacy Mutation8RepelToFinisherImmune: the repel to a finisher needs a human that is no boss, not
// immune to instant kills, not Olgierd, allows finishers, and meets the finisher rule above.
@addMethod(CNewNPC)
function GMMutation8RepelToFinisherImmune() : bool
{
	if( !IsHuman() || !IsAlive() || !IsRequiredAttitudeBetween( thePlayer, this, true ) )
		return true;
	if( HasAbility( 'SkillBoss' ) || HasAbility( 'Boss' ) || HasAbility( 'InstantKillImmune' ) )
		return true;
	if( HasTag( 'olgierd_gpl' ) || HasAbility( 'DisableFinishers' ) || HasTag( 'Mutation8CounterImmune' ) )
		return true;
	return IsImmuneToMutation8Finisher();
}

// A finisher on a living target: confused, puppeted or (Deadly Counter) countered.
@replaceMethod(W3DamageManagerProcessor)
function CanPerformFinisherOnAliveTarget( actorVictim : CActor ) : bool
{
	return actorVictim.IsHuman()

	&& ( actorVictim.HasBuff(EET_Confusion) || actorVictim.HasBuff(EET_AxiiGuardMe) || gmMutation8Triggered )	//modSigns: MUT-06, Deadly Counter

	&& actorVictim.IsVulnerable()
	&& !actorVictim.HasAbility('DisableFinisher')
	&& !actorVictim.HasAbility('InstantKillImmune');
}
