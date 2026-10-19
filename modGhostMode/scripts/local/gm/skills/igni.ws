// SKL-09: Igni, legacy's in both trees (docs/features/skl.md).
// - The sign effect test (W3EffectManager.GetSignApplyBuffTest): every sign effect passes but regular
//   Igni's burning (legacy: the signs and the effects decide; 5.x rolls intensity / 2 - resistance for
//   Aard's knockdown applicator, Quen's and the rest, so a third of Aard casts at x1.26 did nothing).
//   Regular Igni burns at 33% for Geralt (magic_2's initial_burn_chance, independent of intensity) or 50%
//   for others, plus Pyromaniac (classic magic_s9: +5% per level, 5 levels; the new tree's magic_s41:
//   +8.33% per level, D58), x (1 - burning resistance).
//   5.x's intensity-based chance and its bonuses (Melt Armor, Catalyst, perk_3, Petri Philtre's level 3)
//   are gone (D21).
// - Igni's damage: 150 fire damage (magic_2, scaling with intensity).
// - The projectile (W3IgniProjectile.ProcessCollision, replaced): Melt Armor before the damage (below);
//   Igni Intensity's damage (classic magic_s7: +30 Igni and +15/s Firestream damage per level, 5
//   levels; the new tree's magic_s35: +50 and +25/s per level, D58); Firestream's damage per second as legacy, by the cast skill (classic magic_s2, new tree
//   magic_s28): 40 + 30 per level above 1, x the intensity (damage over time gets no attack power).
// - Melt Armor (both trees, legacy): an Igni hit (fire immunity excepted) gives the victim, before the
//   damage, a debuff of level x round(1 + 7 x intensity bonus) stacks for 15 s, not cumulative: each
//   stack -2 armor and -0.2% physical and elemental resistances (-10 and -1% at the maximum level and
//   100% intensity); a timer on Geralt's HUD. The new tree's 3 levels reach the classic totals with
//   larger stacks (GMMeltArmorDebuffNewTree).

// Igni Intensity: the classic magic_s7 or the new tree's magic_s35 (D58); S_SUndefined if none.
@addMethod(W3PlayerWitcher)
function GMIgniIntensitySkill() : ESkill
{
	if(CanUseSkill(S_Magic_s07))
		return S_Magic_s07;
	if(CanUseSkill(S_Magic_s35))
		return S_Magic_s35;
	return S_SUndefined;
}

// Pyromaniac: the classic magic_s9 or the new tree's magic_s41 (D58); S_SUndefined if none.
@addMethod(W3PlayerWitcher)
function GMPyromaniacSkill() : ESkill
{
	if(CanUseSkill(S_Magic_s09))
		return S_Magic_s09;
	if(CanUseSkill(S_Magic_s41))
		return S_Magic_s41;
	return S_SUndefined;
}

// Igni Intensity's damage per level for the sign's owner: fire_damage_bonus (Igni) or
// channeling_damage_bonus (Firestream, per second); 0 without the skill or for NPCs.
function GMIgniIntensityDamage(owner : W3SignOwner, attributeName : name) : float
{
	var witcher : W3PlayerWitcher;
	var skill : ESkill;

	witcher = owner.GetPlayer();
	if(!witcher)
		return 0;
	skill = witcher.GMIgniIntensitySkill();
	if(skill == S_SUndefined)
		return 0;
	return CalculateAttributeValue(witcher.GetSkillAttributeValue(skill, attributeName, false, false)) * witcher.GetSkillLevel(skill);
}

@replaceMethod(W3EffectManager)
function GetSignApplyBuffTest(signType : ESignType, effectType : EEffectType, powerStatValue : SAbilityAttributeValue, isAlternate : bool, caster : CActor, sourceName : string ) : bool
{
	var resPt, res, chance, rawChance, bonusChance : float;	//modSigns
	var witcher : W3PlayerWitcher;
	//modSigns: removed sp, tempF, chanceBonus, yrdens, i, j, foundVictim

	if(signType != ST_Igni || isAlternate)	//modSigns: every sign effect but regular Igni's burning passes (legacy)
		return true;	//modSigns
	//modSigns: removed 5.x's Petri Philtre level 3 pass and its intensity-based chances (all signs, Igni's with Melt Armor, Catalyst and perk_3 bonuses, Quen's applicator)

	owner.GetResistValue(theGame.effectMgr.GetBuffResistStat(effectType), resPt, res);	//modSigns
	rawChance = 0.5;	//modSigns: NPCs
	bonusChance = 0;	//modSigns
	witcher = (W3PlayerWitcher)caster;
	if(witcher)	//modSigns
	{	//modSigns
		rawChance = CalculateAttributeValue(witcher.GetSkillAttributeValue(S_Magic_2, 'initial_burn_chance', false, true));	//modSigns
		if(witcher.GMPyromaniacSkill() != S_SUndefined)	//modSigns: Pyromaniac, either tree
			bonusChance = CalculateAttributeValue(witcher.GetSkillAttributeValue(witcher.GMPyromaniacSkill(), 'chance_bonus', false, true)) * witcher.GetSkillLevel(witcher.GMPyromaniacSkill());	//modSigns
	}	//modSigns
	//modSigns: legacy's Glyphword 7 bonus comes with ENCH
	chance = MaxF(0, (rawChance + bonusChance) * (1 - res));	//modSigns
	if(witcher)	//modSigns: MUT-13, Metamorphosis
		chance *= witcher.GMMutation12ChanceMult();	//modSigns

	LogEffects("Buff <<" + effectType + ">> is from sign, chance = " + NoTrailZeros(100*chance) + "%, spell_power = " + NoTrailZeros(powerStatValue.valueMultiplicative) + ", resist=" + NoTrailZeros(res));	//modSigns
	if(RandF() >= chance)
	{
		if ( theGame.CanLog() )
		{
			LogEffects("Sign buff chance failed - no effect applied");
		}
		return false;
	}
	else
	{
		LogEffects("Sign buff chance succeeded!");
	}

	return true;
}

class W3GMEffect_MeltArmorDebuff extends CBaseGameplayEffect
{
	default effectType = EET_GMMeltArmorDebuff;
	default isNegative = true;
	default dontAddAbilityOnTarget = true;

	private var gmStackAbility : name;

	event OnEffectAdded(optional customParams : W3BuffCustomParams)
	{
		var witcher : W3PlayerWitcher;
		var stacks : int;

		witcher = (W3PlayerWitcher)GetCreator();
		if(!witcher)
		{
			isActive = false;
			return false;
		}
		super.OnEffectAdded(customParams);
		gmStackAbility = witcher.GMMeltArmorStackAbility();
		stacks = witcher.GetSkillLevel(S_Magic_s08) * RoundMath(1 + 7.0 * GMSignPowerStatToPowerBonus(creatorPowerStat.valueMultiplicative));
		if(stacks > 0)
		{
			target.AddAbilityMultiple(gmStackAbility, stacks);
			witcher.AddEffectDefault(EET_GMMeltArmorTimer, NULL, "GMMeltArmor");
		}
	}

	event OnEffectRemoved()
	{
		super.OnEffectRemoved();
		target.RemoveAbilityAll(gmStackAbility);
		thePlayer.RemoveAllBuffsOfType(EET_GMMeltArmorTimer);
	}

	// not cumulative: a new hit while it runs changes nothing (legacy)
	protected function GetSelfInteraction(e : CBaseGameplayEffect) : EEffectInteract
	{
		return EI_Cumulate;
	}

	public function CumulateWith(effect : CBaseGameplayEffect)
	{
	}
}

// Geralt's HUD timer for Melt Armor; a new debuff restarts it.
class W3GMEffect_MeltArmorTimer extends CBaseGameplayEffect
{
	default effectType = EET_GMMeltArmorTimer;
	default isPositive = true;
	default dontAddAbilityOnTarget = true;

	protected function GetSelfInteraction(e : CBaseGameplayEffect) : EEffectInteract
	{
		return EI_Cumulate;
	}

	public function CumulateWith(effect : CBaseGameplayEffect)
	{
		timeLeft = effect.timeLeft;
		duration = effect.duration;
	}
}

@addMethod(W3PlayerWitcher)
function GMMeltArmorStackAbility() : name
{
	if(GMIsClassicTreeAbility(GMGetSkillAbilityName(S_Magic_s08)))
		return 'GMMeltArmorDebuff';
	return 'GMMeltArmorDebuffNewTree';
}

// Melt Armor on an Igni hit, before the damage: Geralt's skill, an actor without fire immunity.
function GMMeltArmor(collider : CGameplayEntity, caster : CActor, signPower : SAbilityAttributeValue, alternate : bool)
{
	var victim : CActor;
	var params : SCustomEffectParams;
	var pts, prc : float;
	var witcher : W3PlayerWitcher;

	victim = (CActor)collider;
	witcher = (W3PlayerWitcher)caster;
	if(!victim || !witcher || !witcher.CanUseSkill(S_Magic_s08))
		return;
	victim.GetResistValue(CDS_FireRes, pts, prc);
	if(prc >= 1)
		return;
	params.effectType = EET_GMMeltArmorDebuff;
	params.creator = caster;
	if(alternate)
		params.sourceName = "alt_cast";
	else
		params.sourceName = "normal_cast";
	params.customPowerStatValue = signPower;
	victim.AddEffectCustom(params);
}

@replaceMethod(W3IgniProjectile)
function ProcessCollision( collider : CGameplayEntity, pos, normal : Vector )
{
	var signPower, channelDmg : SAbilityAttributeValue;
	var burnChance : float;
	var maxArmorReduction : float;
	var applyNbr : int;
	var i : int;
	var npc : CNewNPC;
	var armorRedAblName : name;
	var currentReduction : int;
	var actorVictim : CActor;
	var ownerActor : CActor;
	var dmg : float;
	var performBurningTest : bool;
	var igniEntity : W3IgniEntity;
	var postEffect : CGameplayFXSurfacePost = theGame.GetSurfacePostFX();
	var igniDRTier : int;
	var level : int;	//modSigns

	postEffect.AddSurfacePostFXGroup( pos, 0.5f, 8.0f, 10.0f, 2.5f, 1 );


	if ( hitEntities.Contains( collider ) )
	{
		return;
	}
	hitEntities.PushBack( collider );

	super.ProcessCollision( collider, pos, normal );

	ownerActor = owner.GetActor();
	actorVictim = ( CActor ) action.victim;
	npc = (CNewNPC)collider;
	signPower = signEntity.GetOwner().GetTotalSignSpellPower(signEntity.GetSkill());	//modSigns: needed before the damage
	signPower.valueMultiplicative += GMNetflixYrdenIntensity(ownerActor, actorVictim, signEntity.GetSkill());	//modSigns: ARM-15, the Netflix set inside Yrden (Melt Armor, Firestream)
	GMMeltArmor(collider, owner.GetActor(), signPower, signEntity.IsAlternateCast());	//modSigns: SKL-09, Melt Armor before the damage (legacy)
	if(!signEntity.IsAlternateCast() && GMIgniIntensityDamage(owner, 'fire_damage_bonus') > 0)	//modSigns: SKL-09, Igni Intensity's fire damage (legacy), either tree
		action.AddDamage(theGame.params.DAMAGE_NAME_FIRE, GMIgniIntensityDamage(owner, 'fire_damage_bonus'));	//modSigns


	if(signEntity.IsAlternateCast())
	{
		igniEntity = (W3IgniEntity)signEntity;
		performBurningTest = igniEntity.UpdateBurningChance(actorVictim, dt);



		if( igniEntity.hitEntities.Contains( collider ) )
		{
			channelCollided = true;
			action.SetHitEffect('');
			action.SetHitEffect('', true );
			action.SetHitEffect('', false, true);
			action.SetHitEffect('', true, true);
			action.ClearDamage();


			channelDmg = owner.GetSkillAttributeValue(signSkill, 'channeling_damage', false, false);	//modSigns: legacy's Firestream: per second, by the cast skill's level
			level = owner.GetSkillLevel(signSkill);	//modSigns
			channelDmg += owner.GetSkillAttributeValue(signSkill, 'channeling_damage_after_1', false, false) * (level - 1);	//modSigns
			dmg = channelDmg.valueAdditive + channelDmg.valueMultiplicative * actorVictim.GetMaxHealth();
			dmg += GMIgniIntensityDamage(owner, 'channeling_damage_bonus');	//modSigns: Igni Intensity's Firestream damage, either tree
			dmg *= signPower.valueMultiplicative;	//modSigns: damage over time gets no attack power, so the intensity is applied here
			dmg *= dt;
			action.AddDamage(theGame.params.DAMAGE_NAME_FIRE, dmg);
			action.SetIsDoTDamage(dt);

			if(!collider)
				return;
		}
		else
		{
			igniEntity.hitEntities.PushBack( collider );
		}

		if(!performBurningTest)
		{
			action.ClearEffects();
		}
	}


	if ( npc && npc.IsShielded( ownerActor ) )
	{
		collider.OnIgniHit( this );
		return;
	}

	igniDRTier = 1;

	if( owner.IsPlayer() && npc )
	{
		igniDRTier = npc.SignDRRegisterIgni( IsProjectileFromChannelMode() );
	}



	//modSigns: removed the sign power read here (read before the damage)


	if ( !owner.IsPlayer() )
	{

		burnChance = signPower.valueMultiplicative;
		if ( RandF() < burnChance )
		{
			action.AddEffectInfo(EET_Burning);
		}

		dmg = CalculateAttributeValue(signPower);
		if ( dmg <= 0 )
		{
			dmg = 20;
		}
		action.AddDamage( theGame.params.DAMAGE_NAME_FIRE, dmg);
	}

	if(signEntity.IsAlternateCast())
	{
		action.SetHitAnimationPlayType(EAHA_ForceNo);
	}
	else
	{

		if(ownerActor.HasTag('mq1060_witcher'))
		{
			action.SetHitEffect('igni_cone_hit_red', false, false);
			action.SetHitEffect('igni_cone_hit_red', true, false);
		}
		else
		{
			action.SetHitEffect('igni_cone_hit', false, false);
			action.SetHitEffect('igni_cone_hit', true, false);
		}
		action.SetHitReactionType(EHRT_Igni, false);
	}

	if( owner.IsPlayer() && npc )
	{
		if( igniDRTier == 2 )
		{
			if( RandF() >= 0.60f )
			{
				action.RemoveBuffsByType( EET_Burning );
			}
		}
		else if( igniDRTier == 3 )
		{
			if( RandF() >= 0.25f )
			{
				action.RemoveBuffsByType( EET_Burning );
			}
		}
		else if( igniDRTier >= 4 )
		{
			action.RemoveBuffsByType( EET_Burning );
		}
	}


	theGame.damageMgr.ProcessAction( action );


	//modSigns: removed 5.x's Melt Armor (armor abilities after the damage, by intensity / 2)
	collider.OnIgniHit( this );
}
