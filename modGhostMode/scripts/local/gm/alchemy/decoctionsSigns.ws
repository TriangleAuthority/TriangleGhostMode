// ALCH-11: sign decoctions (legacy's).
// - Foglet (Mutagen 9): +10/17.5/25 base damage to every sign hit per equipped lesser/normal/greater blue
//   mutagen (per second for damage over time), recounted when mutagens change (damage/pool.ws). 1.32's
//   +25% intensity in bad weather is gone.
// - Succubus (Mutagen 14): Axii puppets deal 50% more (the ally damage limit x1.5, damage/formula.ws). 1.32's
//   attack power over time is gone.
// - Wraith (Mutagen 19): a free Quen when Geralt is attacked from behind (not while Quen is up, not damage
//   over time or falls, not when dodged, parried or countered); +50% Quen intensity while a hostile specter
//   is near (skills/quen.ws). 1.32's free Quen on a hit of 30% Vitality is gone.
// - Ancient Leshen (Mutagen 22): each sign cast in combat +10% sign intensity (20 stacks of 0.5%, up to 50%);
//   damage taken removes 0.5% per 1% of Vitality lost; reset at combat end. 1.32's stamina regen per sign is
//   gone.
// See docs/features/alch.md.

// ---- Foglet ----------------------------------------------------------------------------------------------

@addField(W3Mutagen09_Effect)
saved var gmM09Bonus : float;

@addMethod(W3Mutagen09_Effect)
function GMGetM09Bonus() : float
{
	return gmM09Bonus;
}

// The bonus from the blue mutagens in the skill slots (legacy's RecalcM09Bonus).
@addMethod(W3Mutagen09_Effect)
function GMRecalcM09Bonus()
{
	var mutagenSlots : array<SMutagenSlot>;
	var i : int;
	var item : SItemUniqueId;
	var mutagensCount : array<int>;
	var inv : CInventoryComponent;
	var abilities : array<name>;
	var abl, max : SAbilityAttributeValue;

	mutagenSlots = GetWitcherPlayer().GetPlayerSkillMutagens();
	inv = GetWitcherPlayer().GetInventory();
	mutagensCount.Resize(3);
	gmM09Bonus = 0;
	for(i = 0; i < mutagenSlots.Size(); i += 1)
	{
		item = mutagenSlots[i].item;
		if(item != GetInvalidUniqueId())
		{
			abilities.Clear();
			inv.GetItemAbilities(item, abilities);
			if(abilities.Contains('greater_mutagen_color_blue'))
				mutagensCount[2] += 1;
			else if(abilities.Contains('mutagen_color_blue'))
				mutagensCount[1] += 1;
			else if(abilities.Contains('lesser_mutagen_color_blue'))
				mutagensCount[0] += 1;
		}
	}
	theGame.GetDefinitionsManager().GetAbilityAttributeValue(abilityName, 'mutagen09_bonus_lesser', abl, max);
	gmM09Bonus += abl.valueAdditive * mutagensCount[0];
	theGame.GetDefinitionsManager().GetAbilityAttributeValue(abilityName, 'mutagen09_bonus_medium', abl, max);
	gmM09Bonus += abl.valueAdditive * mutagensCount[1];
	theGame.GetDefinitionsManager().GetAbilityAttributeValue(abilityName, 'mutagen09_bonus_greater', abl, max);
	gmM09Bonus += abl.valueAdditive * mutagensCount[2];
}

class W3Mutagen09_Effect extends W3Mutagen_Effect
{
	event OnEffectAdded(optional customParams : W3BuffCustomParams)	//modSigns
	{	//modSigns
		super.OnEffectAdded(customParams);	//modSigns
		GMRecalcM09Bonus();	//modSigns
	}	//modSigns
}

// 5.x body: 1.32's ability in bad weather. Changes marked //modSigns.
@replaceMethod(W3Mutagen09_Effect)
function OnUpdate(dt : float)
{
	super.OnUpdate(dt);
	//modSigns: removed 1.32's sign intensity in rain, snow and storms (ALCH-11)
}

// 5.x body; changes marked //modSigns.
@replaceMethod(W3Mutagen09_Effect)
function OnLoad(t : CActor, eff : W3EffectManager)
{
	super.OnLoad(t, eff);
	//modSigns: removed the weather ability's flag (ALCH-11)
}

function GMRecalcFoglet()
{
	if(thePlayer.HasBuff(EET_Mutagen09))
		((W3Mutagen09_Effect)thePlayer.GetBuff(EET_Mutagen09)).GMRecalcM09Bonus();
}

@wrapMethod(W3PlayerAbilityManager)
function OnSkillMutagenEquipped(item : SItemUniqueId, slot : EEquipmentSlots, prevColor : ESkillColor)
{
	wrappedMethod(item, slot, prevColor);
	GMRecalcFoglet();
}

@wrapMethod(W3PlayerAbilityManager)
function OnSkillMutagenUnequipped(out item : SItemUniqueId, slot : EEquipmentSlots, prevColor : ESkillColor, optional dontMerge : bool)
{
	wrappedMethod(item, slot, prevColor, dontMerge);
	GMRecalcFoglet();
}

@wrapMethod(W3PlayerAbilityManager)
function OnSwappedMutagensPost(a : SItemUniqueId, b : SItemUniqueId)
{
	wrappedMethod(a, b);
	GMRecalcFoglet();
}

// ---- Succubus --------------------------------------------------------------------------------------------

@addMethod(W3Mutagen14_Effect)
function GMGetMutagen14Bonus() : float
{
	var min, max : SAbilityAttributeValue;

	theGame.GetDefinitionsManager().GetAbilityAttributeValue(abilityName, 'mutagen14_bonus', min, max);
	return CalculateAttributeValue(GetAttributeRandomizedValue(min, max));
}

// 5.x body: 1.32's attack power timer. Changes marked //modSigns.
@replaceMethod(W3Mutagen14_Effect)
function OnEffectAdded(optional customParams : W3BuffCustomParams)
{
	super.OnEffectAdded(customParams);
	//modSigns: removed 1.32's attack power timer (ALCH-11)
}

// 5.x body; changes marked //modSigns.
@replaceMethod(W3Mutagen14_Effect)
function OnEffectRemoved()
{
	GetWitcherPlayer().RemoveTimer('Mutagen14Timer');
	target.RemoveAbilityAll(abilityName);	//modSigns: anything 1.32's timer added before (a save from before the port)
	super.OnEffectRemoved();
}

// ---- Wraith ----------------------------------------------------------------------------------------------

// Called at the top of GMProcessDamageDecrease (skills/quen.ws), before Quen absorbs the hit: the free
// Quen cast here takes this hit too (legacy).
@addMethod(W3Mutagen19_Effect)
function GMProtectiveQuen(action : W3DamageAction)
{
	var attackAction : W3Action_Attack;
	var witcher : W3PlayerWitcher;

	witcher = GetWitcherPlayer();
	if(action.attacker == witcher || action.victim != witcher)
		return;
	if(witcher.IsAnyQuenActive())
		return;
	if(!witcher.IsAttackerAtBack(action.attacker))
		return;
	if(action.IsDoTDamage() && (CBaseGameplayEffect)action.causer)
		return;
	if(action.GetBuffSourceName() == "FallingDamage")
		return;
	if(action.WasDodged())
		return;
	attackAction = (W3Action_Attack)action;
	if(attackAction && attackAction.CanBeParried() && (attackAction.IsParried() || attackAction.IsCountered()))
		return;
	witcher.GMCastFreeQuen();
}

@addMethod(W3Mutagen19_Effect)
function GMGetQuenPowerBonus() : SAbilityAttributeValue
{
	var witcher : W3PlayerWitcher;
	var min, max : SAbilityAttributeValue;
	var enemies : array<CActor>;
	var i : int;
	var nullAttr : SAbilityAttributeValue;

	witcher = GetWitcherPlayer();
	if(target != witcher)
		return nullAttr;
	enemies = witcher.GetHostileEnemies();
	for(i = 0; i < enemies.Size(); i += 1)
	{
		if(GMIsSpecter(enemies[i]))
		{
			theGame.GetDefinitionsManager().GetAbilityAttributeValue(abilityName, 'quen_power_bonus', min, max);
			return GetAttributeRandomizedValue(min, max);
		}
	}
	return nullAttr;
}

// Legacy's CActor.IsSpecter.
function GMIsSpecter(actor : CActor) : bool
{
	var monsterCategory : EMonsterCategory;
	var tmpName : name;
	var tmpBool : bool;

	if(!actor)
		return false;
	theGame.GetMonsterParamsForActor(actor, monsterCategory, tmpName, tmpBool, tmpBool, tmpBool);
	return monsterCategory == MC_Specter;
}

// Legacy's CastFreeQuen: a free Quen (no stamina, adrenaline or cooldown), with the Bear set's back effect.
@addMethod(W3PlayerWitcher)
function GMCastFreeQuen()
{
	var quen : W3QuenEntity;

	quen = (W3QuenEntity)signs[ST_Quen].entity;
	if(!quen)
		quen = (W3QuenEntity)theGame.CreateEntity(signs[ST_Quen].template, GetWorldPosition(), GetWorldRotation());
	PlayEffect( 'quen_lasting_shield_back' );
	quen.Init(signOwner, signs[ST_Quen].entity, true);
	quen.freeFromBearSetBonus = true;
	quen.OnStarted();
	quen.OnThrowing();
	quen.OnEnded();
}

// ---- Ancient Leshen --------------------------------------------------------------------------------------

class W3Mutagen22_Effect extends W3Mutagen_Effect
{
	event OnEffectRemoved()	//modSigns
	{	//modSigns
		super.OnEffectRemoved();	//modSigns
		target.RemoveAbilityAll(abilityName);	//modSigns
	}	//modSigns
}

@addMethod(W3Mutagen22_Effect)
function GMAddMutagen22Ability()
{
	var abilityCount, maxStack, buffRate : int;
	var min, max : SAbilityAttributeValue;

	if(target == thePlayer && thePlayer.IsInCombat() && thePlayer.IsThreatened())
	{
		theGame.GetDefinitionsManager().GetAbilityAttributeValue(abilityName, 'mutagen22_max_stack', min, max);
		maxStack = RoundMath(CalculateAttributeValue(GetAttributeRandomizedValue(min, max)));
		theGame.GetDefinitionsManager().GetAbilityAttributeValue(abilityName, 'mutagen22_buff_rate', min, max);
		buffRate = RoundMath(CalculateAttributeValue(GetAttributeRandomizedValue(min, max)));
		abilityCount = thePlayer.GetAbilityCount(abilityName);
		if(abilityCount + buffRate < maxStack)
			thePlayer.AddAbilityMultiple(abilityName, buffRate);
		else if(abilityCount < maxStack)
			thePlayer.AddAbilityMultiple(abilityName, maxStack - abilityCount);
	}
}

@addMethod(W3Mutagen22_Effect)
function GMRemoveMutagen22Abilities(damageAction : W3DamageAction)
{
	var min, max : SAbilityAttributeValue;
	var dmgVal, debuffRate : float;
	var abilityCount, debuffNum : int;

	if(target != thePlayer || !thePlayer.IsInCombat() || !thePlayer.IsThreatened())
	{
		thePlayer.RemoveAbilityAll(abilityName);
		return;
	}
	if(!damageAction || damageAction.victim != thePlayer || !damageAction.DealsAnyDamage()
		|| (damageAction.IsDoTDamage() && (CBaseGameplayEffect)damageAction.causer))
		return;
	dmgVal = damageAction.GetDamageDealt();
	if(dmgVal <= 0)
		return;
	theGame.GetDefinitionsManager().GetAbilityAttributeValue(abilityName, 'mutagen22_debuff_rate', min, max);
	debuffRate = CalculateAttributeValue(GetAttributeRandomizedValue(min, max));
	debuffNum = RoundMath(debuffRate * dmgVal / thePlayer.GetMaxHealth() * 100);
	abilityCount = thePlayer.GetAbilityCount(abilityName);
	if(debuffNum < abilityCount)
		thePlayer.RemoveAbilityMultiple(abilityName, debuffNum);
	else
		thePlayer.RemoveAbilityAll(abilityName);
}

@addMethod(W3Mutagen22_Effect)
function GMGetStacks() : int
{
	var min, max : SAbilityAttributeValue;

	theGame.GetDefinitionsManager().GetAbilityAttributeValue(abilityName, 'spell_power', min, max);
	return RoundMath(min.valueMultiplicative * 100 * thePlayer.GetAbilityCount(abilityName));
}
