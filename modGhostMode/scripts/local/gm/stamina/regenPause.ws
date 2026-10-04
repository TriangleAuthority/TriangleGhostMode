// STAM-06 (damage pause): taking damage pauses stamina regen for up to 1 s, by the hit's
// severity, on every actor except bosses. The pauses after actions are XML and the delay
// option (staminaCosts.ws). See docs/features/stam.md.

// Severity 0-4 of a hit, from the share of the victim's max health it took: under 5% is 0,
// then one step per 5%, 20% or more is 4. Tall victims (capsule over 2 m) need bigger hits.
// DoT from effects and hits that dealt no damage are 0. (Legacy GetHitSeverityFromDamageData.)
function GMGetHitSeverity(damageData : W3DamageAction) : int
{
	var healthPrc, damage, capsuleHeight : float;
	var victim : CActor;
	var mac : CMovingPhysicalAgentComponent;

	if(damageData.IsDoTDamage() && (CBaseGameplayEffect)damageData.causer || !damageData.DealtDamage())
		return 0;

	victim = (CActor)damageData.victim;
	if(!victim || victim.GetMaxHealth() <= 0)
		return 0;

	if(victim.UsesEssence())
		damage = damageData.processedDmg.essenceDamage;
	else
		damage = damageData.processedDmg.vitalityDamage;

	healthPrc = damage / victim.GetMaxHealth() * 100;

	mac = (CMovingPhysicalAgentComponent)victim.GetMovingAgentComponent();
	if(mac)
		capsuleHeight = mac.GetCapsuleHeight();
	healthPrc /= 1 + MaxF(0, capsuleHeight - 2);

	if(healthPrc < 5)
		return 0;
	if(healthPrc < 10)
		return 1;
	if(healthPrc < 15)
		return 2;
	if(healthPrc < 20)
		return 3;
	return 4;
}

// A hit pauses the victim's regen for severity / 4 s (no pause for bosses, nor after a
// killing blow). Geralt's pause also gets the delay option (staminaCosts.ws).
@wrapMethod(CActor)
function OnTakeDamage(action : W3DamageAction)
{
	var ret : bool;
	var severity : int;

	ret = wrappedMethod(action);
	if(IsAlive() && !(action.IsDoTDamage() && (CBaseGameplayEffect)action.causer) && !HasTag('HideHealthBarModule'))
	{
		severity = GMGetHitSeverity(action);
		DrainStamina(ESAT_FixedValue, 0, severity / 4.0);
	}
	return ret;
}

// STAM-06 (finishers): stamina regen is paused during a finisher (finishers are free, STAM-03),
// and resumed when it ends, when combat ends and on load. Rend needs nothing: each tick of its
// charge drains with Rend's 1 s delay (gm_skills.xml), which keeps regen paused while charging
// and for 1 s after the release, as legacy's explicit pause did.
@wrapMethod(CR4Player)
function OnFinisherStart()
{
	var ret : bool;

	ret = wrappedMethod();
	PauseStaminaRegen('IsPerformingFinisher');
	return ret;
}

@wrapMethod(CR4Player)
function OnFinisherEnd()
{
	var ret : bool;

	ret = wrappedMethod();
	ResumeStaminaRegen('IsPerformingFinisher');
	return ret;
}

@wrapMethod(CR4Player)
function OnCombatFinished()
{
	var ret : bool;

	ret = wrappedMethod();
	ResumeStaminaRegen('IsPerformingFinisher');
	return ret;
}

@wrapMethod(W3PlayerWitcher)
function OnSpawned(spawnData : SEntitySpawnData)
{
	var ret : bool;

	ret = wrappedMethod(spawnData);
	ResumeStaminaRegen('IsPerformingFinisher');
	return ret;
}
