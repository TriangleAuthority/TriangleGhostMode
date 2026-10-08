# SKL: skills, signs and perks

Ghost Mode reworks almost every skill and perk so that each one does what its description says (P7), fits the stamina economy (P2) and the damage formula (P1), and stays close to vanilla's idea of the skill (P8). Source: the changelist's "Skill changes" section (lines 250–467 of [legacy-FullChangelist.txt](../legacy-FullChangelist.txt)), plus the skill fixes in its Bugfixes section.

**How legacy Ghost Mode implements it.** Most changes are new values and new attributes in `geralt_skills.xml` (and its NG+ copy, the expansions' `geralt_skills_ep1/ep2.xml`), read by new or rewritten code in `damageManagerProcessor.ws`, `playerWitcher.ws`, `PlayerAbilityManager.ws`, the sign entity scripts and a few new effects (Melt Armor, Undying). The skill tree layout (`custom/skills/definitions`) moves a few skills between tiers and changes some level counts. Descriptions are new string rows and new tooltip arguments in `characterMenu.ws`.

**What 5.x did in this area.** 5.x has two skill trees ([Two skill trees](../feature-mapping.md#two-skill-trees)): the classic tree (1.32's skills, nearly all cut from 5 levels to 3 with raised values) and the new tree (52 reworked skills and perks, plus 28 skills shared with the classic tree). Several skills Ghost Mode reworked were reworked by 5.x too, differently: Undying, Flood of Anger, Fleet Footed, Deflection, Puppet; some classic skills lost their effect in 5.x's code (Shock Wave without Mutation 6, Pyromaniac). Facts that hold for the whole area, from the code (not tested in game):

- **Shared skills ignore tier points**, in both trees: `W3PlayerAbilityManager.CanLearnSkill` checks `requiredPointsSpent` only for classic-only skills; shared skills are gated by their `required_skills`. A tier change of a shared skill (legacy's "Rend is now tier 2") cannot be made through its points.
- **Passive path bonuses go to every equipped skill**, classic ones included (`OnSkillEquip`, `OnSkillUnequip`, `OnSkillEquippedLevelChange`); 5.x's function that would limit them to reworked and shared skills (`AddSkillPassiveBonusesForEquipped`) has no caller. 5.x also adds `survival_vitality` (+1% max Vitality per level of an equipped perk) and makes the potion-duration passive raise bomb damage.
- **Shared skills use new string keys in both trees** (e.g. `skill_rend_description`); legacy's overrides of the old keys (`skill_desc_sword_s2`) would not show for them. Classic-only skills keep the old keys. The new tree has its own character menu (`characterMenuDupe.ws`) with its own tooltip functions.
- **The new tree has no intensity skills** (Aard, Igni, Yrden, Quen, Axii Intensity), no Pyromaniac, no Quen Discharge and no Killing Spree; legacy's changes to those apply to the classic tree only.

Unit lists: [attribution.csv](attribution.csv): 1,416 units attributed to SKL-01 to SKL-19 (mapped 2026-10-04 from the changelist and sweeps of every skill, perk, sign and alchemy keyword); 973 of them are SKL-19's localization rows (108 strings × 9 languages). Units whose change belongs to other areas are in the [hand-off list](#hand-off-to-other-areas). Port status: not started; all entries are from reading the code.

## Area decisions

**Paused on 2026-10-06 for DMG; resumes after DMG's sign-off (2026-10-07).** The damage formula is in place ([dmg.md](dmg.md)): where a skill's bonus sits (raw damage and its additive pool, attack power, final damage) now decides what its numbers are worth, and DMG's functions host the skill terms SKL ports ([DMG's hand-off](dmg.md#hand-off-to-other-areas)); the test dummy and damage probe ([development.md](../development.md#testing-in-game)) measure them. Where the per-skill pass stopped:
- **Done** (combat tree, direct analogs): Muscle Memory (D1, D47), Whirl, Crippling Strike (D2); recorded in [SKL-03](#skl-03-fast-attack-branch) and [skl-decisions.md](../skill-trees/skl-decisions.md).
- **Next:** Strength Training (new tree `sword_s23`: 5.x's combo, +15% raw damage per level on the strong attack after a fast-attack hit). Recommended, not yet decided: keep the mechanism at +45%, add legacy's +15% strong-attack adrenaline gain at level 3.
- **Raw-damage multipliers, settled with DMG ([DD1](dmg.md#area-decisions), project owner, 2026-10-06):** 5.x's raw-damage multipliers (new Muscle Memory, Strength Training, Three Strikes, Crushing Blow, Anatomical Knowledge, Lightning Reflexes, Catalyst, Resonance, Elemental Attunement, Element of Surprise, the Manticore and Viper perks, Volatile Compound, Potent Sting, High Tolerance, the Wolven set) join legacy's additive raw-damage pool (D4). Exceptions are deliberate, confirmed 2026-10-07 in [DMG-04](dmg.md#dmg-04-additive-raw-damage-pool) (Crippling Strike's bonus is a final-damage multiplier, D2). The 45% chosen for Muscle Memory was set while the rule was open: recheck it as a pool term.
- **Then:** the rest of the combat tree in the agreed order (Rend, Crushing Blows, Sunder Armor, Deflection, Fleet Footed, Counterattack, Deadly Precision, Lightning Reflexes, Anatomical Knowledge, Crippling Shot and Maiming Shot, Cold Blood, the Battle Trance skills), then the skills legacy replaced or reworked (Steady Shot, Precise Blows' role, Three Strikes); then signs, alchemy, perks.


**Direction of 2026-10-05 (project owner):** the trees are separated and the classic tree becomes legacy Ghost Mode's tree, ported with legacy's values and maximum levels. The new tree becomes the experimental tree, balanced against the [ledger](ledger/README.md) under the rules in [balance.md](balance.md). For the classic tree, this replaces the 5/3 rescaling below and most of the per-skill decisions (they become "as legacy"). The new-tree decisions move to the second phase. The entries below still describe the 2026-10-04 state and are re-sorted after the separation slice ([plan](balance.md#two-skill-trees-the-plan)).

Made by the project owner on 2026-10-04 for the whole area:

- **Three-level skills keep legacy's top total** (now for the new tree only, see above). Where Ghost Mode set a per-level value on a skill that 5.x cut from 5 levels to 3, the per-level value is multiplied by 5/3, so level 3 gives legacy's level-5 total (e.g. Muscle Memory's adrenaline gain 0.03 → 0.05 per level, 15% at level 3). Where Ghost Mode did not change a skill, 5.x's version stays. STAM-09 kept Whirl's per-level cost reduction instead (30% at level 3); it moves to this rule as a [follow-up](stam.md#two-skill-trees-follow-ups).
- **New-tree counterparts:** where a new-tree skill or perk has the same mechanism as a classic one Ghost Mode changed, it gets legacy's value at its level 3 (a third per level); where the mechanism differs, 5.x's skill stays. Every case is listed in its entry and confirmed with the owner.
- **Passive path bonuses are removed in both trees** ([SKL-01](#skl-01-skill-system-rules)).
- **Muscle Memory's and Strength Training's double-counted attack power is canon** (project owner, 2026-10-06; it replaces "counts once with 5.x's values" of 2026-10-04): legacy was tested and played with it, so the classic tree gives +50% at level 5 (D47), and the description says so ([SKL-03](#skl-03-fast-attack-branch)).

Decisions are numbered (D1, D2, …) in the entries and kept in [skl-decisions.md](../skill-trees/skl-decisions.md).

---

### SKL-01 Skill system rules

| | |
|---|---|
| Kind | system, fix |
| Pillars | P2, P8 |
| 5.x class | overlap |
| Flags | balance |
| Depends on | — |
| Skill trees | both: every equipped skill and perk |
| Port form | DLC XML zeroing the passive abilities (`sword_adrenalinegain`, `magic_staminaregen`, `alchemy_potionduration`, `survival_vitality`); `@wrapMethod(W3PlayerWitcher) OnSpawned` (save cleanup); level sync in `OnSkillEquippedLevelChange`; slot fixes in `UnequipSkill` and both character menus |
| Port status | not started |
| Open checks | — |
| Save impact | none (expected: the load cleanup removes the passives from saves) |
| NG+ counterpart | applied and scaled, untested |

**What it does:** "Passive skills bonuses (adrenaline gain, stamina regen, potion duration) were removed from the game." Not in the changelist: a skill ability tagged `GlobalPassiveBonus` (perk_4, 10, 12, 22, Sun and Stars' parts, Prolonged Effects) follows the level of an equipped skill (vanilla added it only on equip, so a level bought while equipped was lost). Bugfixes 83–84 and 179: skills stuck in locked slots can be removed, a skill cannot be swapped into a slot of the wrong colour, a swap re-applies the bonuses. A respec sets toxicity to 0.

**Implementation (legacy):** the three passive abilities' attributes commented out in `geralt_skills.xml`; their add and remove blocks commented out in `W3PlayerAbilityManager.OnSkillEquip`, `OnSkillUnequip`, `OnSkillEquippedLevelChange` and `ResetCharacterDev`; `W3PlayerWitcher.OnSpawned` removes them on every load. Slot fixes: `UnequipSkill` (`GetSkillSlotIndex(slotID, false)`), `CR4CharacterMenu.CheckAdditionalSlots` (new) and `OnSwapSkill`. `Debug_ClearCharacterDevelopment` rebuilt as a respec that keeps level, XP and points.

**5.x:** keeps and extends the passives (above); none of the slot fixes; the level sync only for perk_30, 33 and 35 (`AdjustAbilitiesOnLevelChange`).

**Decisions:** remove the passives in both trees, including 5.x's `survival_vitality` and the potion-duration bomb damage, by zeroing the abilities (covers old saves and both trees), plus the load cleanup (project owner, 2026-10-04). The passive lines in both menus' tooltips go with SKL-19. The level sync ports generically, merged with 5.x's perk_30/33/35 case so nothing is added twice. Open: D43 (slot fixes here or under FIX). D44 decided (2026-10-05): the respec becomes a safe character reset in the mod, extended to 5.x's point bookkeeping and the tree profile ([balance.md](balance.md#two-skill-trees-the-plan)).

### SKL-02 Skill tree option

| | |
|---|---|
| Kind | infra |
| Pillars | P8 |
| 5.x class | in-5.x (the setting), clean (the toggle) |
| Flags | needs-decision |
| Depends on | OPT-01 |
| Skill trees | both |
| Port form | an option in Ghost Mode's menu bound to 5.x's `RemasterCombat`/`UseLegacySkillTree` |
| Port status | not started |
| Open checks | — |
| Save impact | none (expected) |
| NG+ counterpart | none |

**What it does:** a visible toggle for the skill tree (decision 2026-10-03, [Two skill trees](../feature-mapping.md#two-skill-trees)). No legacy units.

**5.x:** `UseLegacySkillTree` is hidden and read only in `CR4CommonMenu` (`commonMenu.ws`), where it opens the classic character menu instead of the new one. Skills of either kind can be equipped and work under either setting (`skilleq`, [game-automation.md](../game-automation.md#skill-trees)).

**Decisions:** the classic tree is the default (D46, project owner, 2026-10-05).

### SKL-03 Fast Attack branch

| | |
|---|---|
| Kind | system, tuning |
| Pillars | P1, P2 |
| 5.x class | conflict (classic); rethink (new tree) |
| Flags | balance, needs-decision |
| Depends on | DMG (damage multipliers), EFX (bleeding rework), STAM-09 (Whirl's drain, ported), DEF-07 |
| Skill trees | both: classic Muscle Memory `sword_s21`, Precise Blows `sword_s17`, Whirl `sword_s1`, Crippling Strikes `sword_s5`; new Muscle Memory `sword_s22`, Three Strikes `sword_s24`, Crippling Strike `sword_s29`, Whirl `sword_s35` |
| Port form | DLC XML `extend` of the skill abilities; wrappers of `W3PlayerWitcher.OnProcessActionPost`, `ReduceDamage`, the damage manager's power and reaction steps |
| Port status | not started |
| Open checks | — |
| Save impact | none (expected) |
| NG+ counterpart | applied and scaled, untested |

**What it does** (changelist 262–273): Muscle Memory +15% adrenaline gain for fast attacks; Whirl is a tier-2 skill, +5% attack power per additional attacker (max 25%) and −50% damage taken while spinning with adrenaline; Precise Blows' crit damage only for melee (not bolts); Crippling Strikes: 25% bleeding chance (bleeding as other sources: 1% of max health per second, 8 s, resisted), and bleeding enemies take +25% from fast attacks.

**Implementation (legacy):** XML `light_focus_gain` 0.03/level, `whirl_dmg_bonus` 0.01/level, `whirl_dmg_reduction` 0.25 + 0.0625 per level above 1, `sword_s5_chance` 0.05, `sword_s5_duration` 8, `sword_s5_dmg_per_sec` 0.01, `sword_s5_dmg_boost` 0.05; code in `OnProcessActionPost` (adrenaline), `GetWhirlDamageBonus` and `GetNumHostilesInRange` (new) through `GetAttackersPowerMod`, `W3PlayerWitcher.ReduceDamage` (Whirl's reduction), `ProcessActionReaction` (bleeding) and the new `ProcessDamageModification` (bleeding bonus). Tier swap of Whirl and Precise Blows in the skill definitions.

**5.x:** raised values (Muscle Memory 0.1/level, Precise Blows 0.04/0.25, Crippling Strikes 100% bleeding at 50 × level per second); still gives bolts Precise Blows' crit damage. The new tree's s22, s24 and s29 are combo multipliers on raw damage (`ProcessNewSkill_*`); `sword_s35` runs the same Whirl code as `sword_s1`.

**Attack power counted twice.** `W3Action_Attack.GetPowerStatValue` adds the attack power of equipped skill abilities tagged with the attack's name (`attack_light` on `sword_s21`, `attack_heavy` on `sword_s4`, DEF-07's counter tag), then adds `sword_s21` (light) and `sword_s4` (heavy) × level again explicitly, so both count twice (measured for `sword_s21`: +0.6 at level 3, [DEF hand-off](def.md#hand-off-to-other-areas)); the same in 1.32 and legacy. `sword_2` counts once: core skills are never equipped, so only the explicit path sees it.

**Decisions:**

- Muscle Memory (classic): 5.x's attack power stays, adrenaline gain 0.05/level (15% at 3). Whirl (both): attack power 0.01667/level per attacker (25% at 3 with 5 attackers), damage reduction 25% at level 1 to 50% at 3 (0.25 + 0.125 per level above 1). Crippling Strikes: chance and bonus 0.08333/level (25% at 3), 8 s, 1% of max health per second, replacing 5.x's. Precise Blows: 5.x's values, crit damage for melee only. Three Strikes `sword_s24`: 5.x's.
- **Per-skill decisions of 2026-10-06** (project owner; the bullets above are the 2026-10-04 state, re-sorted later). Muscle Memory: D47 (classic) and D1 (new tree). **Whirl:** the classic `sword_s1` as legacy (5 levels: 50 stamina/s with 15% less per level above 1, 20/s at level 5; +5% attack power per extra attacker, max +25%; −25% to −50% damage taken). The new tree's `sword_s35` matches legacy at its max level: +0.0167 attack power per extra attacker per level (+25% at level 3), damage taken −25% at level 1 to −50% at level 3 (0.25 + 0.125 per level above 1), stamina cost 30% less per level above 1 (20/s at level 3). This ends STAM-09's temporary deviation when ported. **Crippling Strike** (new tree `sword_s29`, D2): a fast-attack crit, Whirl hits included, applies legacy's bleed (1% of max health per second, 8 s, resisted as legacy) and a separate "crippled" condition unique to the skill, lasting 4 s (5.x: a random 3–6 s). Like 5.x's, crippling has no immunity check: it applies to every NPC, bosses included. A bleeding or crippled target takes +30% damage from any source at level 3 (0.1/level). Until DMG is ported it multiplies like 5.x's; with legacy's damage formula it must behave like legacy's Crippling Strikes bonus, a multiplier of final damage after every other bonus. Description: "Critical hits from Fast Attacks cripple enemies, causing them to bleed. Bleeding or crippled enemies take 30% more damage after all other bonuses." This is weaker than legacy's skill (it needs crits; legacy rolls on every fast-attack hit), but the bonus also applies to enemies immune to bleeding (about 20% of non-human enemy types). The classic `sword_s5` is legacy's.
- Muscle Memory's and Strength Training's attack power plays as legacy's double count: +50% at level 5 in the classic tree, whether the port counts it twice or once at 0.1/level; the description says 50% (project owner, 2026-10-06, D47). New-tree Muscle Memory: D1.
- **Deviation:** counters get a light attack's attack power (DEF-07 gave them both shares). In legacy's code Muscle Memory does not reach counters at all; the changelist says all light-attack bonuses apply to counters (project owner, 2026-10-04; [to test in legacy](../open-questions.md#to-test-in-legacy-ghost-mode)).
- Open: D1 (new Muscle Memory s22), D2 (new Crippling Strike s29), D3 (tier swaps).

### SKL-04 Strong Attack branch

| | |
|---|---|
| Kind | system, tuning |
| Pillars | P1 |
| 5.x class | conflict |
| Flags | balance, needs-decision |
| Depends on | DMG (additive damage bonus, heavy-attack penalty), STAM-09 and STAM-02 (Rend's costs and cooldown, ported) |
| Skill trees | both: core `sword_2`; classic Strength Training `sword_s4`, Crushing Blows `sword_s8`, Sunder Armor `sword_s6`; shared Rend `sword_s2`; new Strength Training `sword_s23`, Crushing Blow `sword_s25`, Sunder Armor `sword_s28` |
| Port form | DLC XML; wrappers of the damage manager's damage increase, resists, crit and before-hit steps and of `OnProcessActionPost` (Rend's shock wave) |
| Port status | not started |
| Open checks | — |
| Save impact | none (expected) |
| NG+ counterpart | applied and scaled, untested |

**What it does** (changelist 274–284): strong attacks +50% weapon damage and +200 armor penetration (vanilla: ignore armor, ×0.333 attack power); Strength Training +15% adrenaline gain for strong attacks; Rend (tier 2): ignores armor, +50% weapon damage and +100% crit chance at level 5, +50% per adrenaline point and +1% per stamina point spent charging, and at 3 adrenaline a shock wave that damages and knocks back enemies within 3 m; Crushing Blows' crit damage only for melee.

**Implementation (legacy):** `sword_2` `armor_reduction` 1000 → 200, `attack_power` removed, `heavy_attack_dmg_boost` 0.5; the additive damage bonus in the rewritten `ProcessDamageIncrease`; 1.32's heavy-attack power penalty removed in `GetAttackersPowerMod`. Rend: `GetRendPowerBonus` (new), crit in `ProcessCriticalHitCheck`, `RendAoE` (new) in `OnProcessActionPost` (all adrenaline drained), a knockdown applicator on every Rend hit (`ProcessOnBeforeHitChecks`, not in the changelist). Tier swap of Rend and Crushing Blows.

**5.x:** `sword_2` unchanged, heavy penalty −0.433; Rend reworked (3 levels, its own adrenaline and stamina bonuses on raw damage, no crit), and it reads `stamina_max_dmg_bonus` with another meaning than legacy's.

**Decisions:** Strength Training (classic): 5.x's attack power (counted once, as SKL-03), adrenaline gain 0.05/level. Rend (shared, both trees): crit 0.3333/level, damage 0.1667/level, 0.1667 per adrenaline point and 0.003333 per stamina point per level, the shock wave and knockdown as legacy; 5.x's Rend block neutralised. Crushing Blows: 5.x's values, melee only. Sunder Armor (both): 5.x's. Open: D1 (new Strength Training s23), D3 (tier swaps), D4 (multipliers until DMG).

### SKL-05 Defense branch

| | |
|---|---|
| Kind | system, tuning |
| Pillars | P9 |
| 5.x class | conflict (classic); rethink (new tree) |
| Flags | balance, needs-decision |
| Depends on | DEF-01 to DEF-08 (ported), DMG |
| Skill trees | both: classic Deflection `sword_s10` (2 levels), Fleet Footed `sword_s9` (1 level), Counterattack `sword_s11`, Deadly Precision `sword_s3` (2 levels); new Arrow Deflection `sword_s33`, Fleet-Footed `sword_s36`, Counterattack `sword_s31`, Deadly Precision `sword_s30` |
| Port form | DLC XML; DEF's existing functions (`defense/*.ws`) extended with the skill rules |
| Port status | not started |
| Open checks | — |
| Save impact | none (expected) |
| NG+ counterpart | applied and scaled, untested (legacy left `sword_s10`'s NG+ copy vanilla; the generator applies the change) |

**What it does** (changelist 285–300): Deflection: −30% more damage from partial parries and counters (down to 20%), reflects arrows with +100% damage, parry cost −50% against several enemies; Fleet Footed: graze damage −50% while dodging (DEF-02); Counterattack: +100% counter power, +70% crit chance (100% with DEF-07's 25%), 5% knockdown chance per adrenaline point; Deadly Precision: +3% instant-kill chance per adrenaline point, only on counters, not during Whirl.

**Implementation (legacy):** Deflection: `s10_damage_reduction` in `CActor.ReduceDamage`, reflection from level 1 in `W3ArrowProjectile.OnProjectileCollision`, reflected damage in `ProcessDamageIncrease`, `GetDeflectionBonus` (new) in `GetStaminaActionCost`. Fleet Footed: `s9_damage_reduction` in `W3PlayerWitcher.DodgeDamage`; the free dodge (`SkipStaminaDodgeEvadeCost`) removed from `PerformEvade`. Counterattack: attack power in `GetPowerStatValue` and crit in `ProcessCriticalHitCheck`, both on the countered enemy (`WasCountered`); knockdown in `PerformCounterCheck`. Deadly Precision: `ProcessInstantKill` (counters, melee, not Whirl), max level 2 → 3, and the player's instant-kill cooldown removed for every source.

**5.x:** Deflection has 2 levels; its level-3 double damage is unreachable. Fleet Footed: `sword_s9` one level (full dodge), `sword_s36` −33.3% per level (full at 3), both with the free dodge. Counterattack as 1.32; `sword_s31` also triggers after a dodge, its crit needs a level above 3 (unreachable). `sword_s30`: every attack arms a 15% instant kill (at level 3) on the next strong attack.

**Decisions:** Fleet Footed `sword_s9`: 50% graze reduction at its one level (legacy's total), no full dodge, no free dodge; `sword_s36`: 0.1667/level (50% at 3); unblocks DEF-02. Counterattack `sword_s11` (3 levels, as legacy): legacy's numbers, attack power and crit on `CActor.GMWasCountered()`, knockdown 0.05 × adrenaline at level 3; ends DEF-07's and part of DEF-06's temporary deviations. Open: D5 (Deflection's two levels), D6 (`sword_s33`), D9 (`sword_s31`), D10 (Deadly Precision's levels), D11 (`sword_s30`), D12 (the instant-kill cooldown).

### SKL-06 Marksmanship branch

| | |
|---|---|
| Kind | system, tuning |
| Pillars | P8 |
| 5.x class | conflict |
| Flags | balance, needs-decision |
| Depends on | XBOW, SKL-18 (Cold Blood moves to `perk_2`) |
| Skill trees | both: core `sword_4`; classic Lightning Reflexes `sword_s13`, Steady Shot (was Cold Blood) `sword_s15`, Anatomical Knowledge `sword_s7`, Crippling Shot `sword_s12`; new Cold Blood `sword_s34`, Anatomical Knowledge `sword_s26`, Maiming Shot `sword_s27`, Lightning Reflexes `sword_s32` |
| Port form | DLC XML (values, the `sword_s15`/`perk_2` name swap); a new damage step for non-aimed throwables |
| Port status | not started |
| Open checks | — |
| Save impact | none (expected) |
| NG+ counterpart | applied and scaled, untested |

**What it does** (changelist 301–306): non-aimed shots −50% damage; Steady Shot (on `sword_s15`'s slot): +50 crossbow base damage; Anatomical Knowledge +75% crit damage for bolts. Cold Blood becomes the perk `perk_2` (SKL-18).

**Implementation (legacy):** `ProcessDamageModification` (new): a player throwable not from an aimed throw (bolts and bombs) deals half damage (`CThrowable.IsFromAimThrow`); `sword_s15` `xbow_dmg_bonus` 10/level in `ProcessDamageIncrease`; `sword_s7` `critical_hit_damage_bonus` 0.15/level; name and description keys of `sword_s15` and `perk_2` swapped in the skill definitions.

**5.x:** bolts deal full damage aimed or not; classic values raised; the new tree's crossbow skills are their own designs.

**Decisions:** non-aimed bolts −50% in both trees (one line with SKL-15's bombs); Steady Shot 16.67/level (+50 at 3); Anatomical Knowledge `sword_s7`: crit damage 0.25/level (75% at 3), 5.x's crit chance stays; Lightning Reflexes, Crippling Shot, `sword_s27`, `sword_s32`: 5.x's. Open: D13 (new Cold Blood `sword_s34`), D14 (`sword_s26`), D17 (the Steady Shot/Cold Blood swap).

### SKL-07 Battle Trance branch

| | |
|---|---|
| Kind | system, tuning |
| Pillars | P2, P8 |
| 5.x class | conflict; overlap (Undying, Flood of Anger) |
| Flags | balance, needs-decision |
| Depends on | SKL-08 to SKL-12 (Flood of Anger's sign side), SKL-18 (Rage Management), ARM (Bear set), MUT (Mutation 11) |
| Skill trees | both: core `sword_5`; shared Resolve `sword_s16`, Undying `sword_s18`, Razor Focus `sword_s20`, Flood of Anger `sword_s19` |
| Port form | wrappers of `OnProcessActionPost`, `ProcessAction` (adrenaline loss), `OnTakeDamage`, `OnCombatStart`; Undying's effects (new effect types, DLC XML) |
| Port status | not started |
| Open checks | — |
| Save impact | none (expected) |
| NG+ counterpart | applied and scaled, untested |

**What it does** (changelist 306–319): adrenaline only from damage dealt (not dodged, parried or countered hits); adrenaline lost on damage taken in proportion to the share of max health lost; Undying works: once per 120 s it prevents death, gives 5 s of immortality and restores 25% of Vitality per adrenaline point over those 5 s; Razor Focus: at least 1.25 adrenaline when combat starts; Flood of Anger: +250% sign intensity and, with Rage Management, costs 3 adrenaline per sign instead of draining all.

**Implementation (legacy):** `OnProcessActionPost` (gain), `ProcessAction` (loss, then Resolve and the Bear set), `OnTakeDamage` and the new `W3Effect_UndyingSkillImmortal`/`W3Effect_UndyingSkillCooldown` (5 s immortality, regen per adrenaline point, 120 s cooldown, HUD icon), `OnCombatStart` (`focus_add`), Flood of Anger's trigger moved into the sign entity (`InitFoA`, `foaMult`), `AddTemporarySkills` no longer drains all adrenaline.

**5.x:** Battle Trance as 1.32; Undying fixed differently (an instant heal, needs the Battle Trance buff, 30 s cooldown); Flood of Anger reworked into "supercharged" signs that drain all adrenaline.

**Decisions:** adrenaline gain and loss as legacy (both trees); Resolve: 5.x's (100% at 3, as legacy); Razor Focus: `focus_add` 0.4167/level (1.25 at 3), 5.x's gain; Flood of Anger 0.8333/level (+250% at 3). Open: D15 (Undying), D16 (Flood of Anger's sign side).

### SKL-08 Aard

| | |
|---|---|
| Kind | system, tuning |
| Pillars | P3, P5 |
| 5.x class | conflict; rethink (`magic_s33`) |
| Flags | balance, needs-decision |
| Depends on | DMG (sign intensity conversion), EFX (low-stamina severity), STAM-01 and STAM-03 (ported), MUT (Mutation 6), ENCH |
| Skill trees | both: core `magic_1`; shared Far-Reaching Aard `magic_s20`, Aard Sweep `magic_s1`; classic Aard Intensity `magic_s12`, Shock Wave `magic_s6`; new Shockwave `magic_s33` |
| Port form | re-implementation of the knockdown applicator (`knockdownTypeApplicator.ws`) and `ModifyKnockdownSeverity`; wrappers of `W3AardProjectile.ProcessCollision`, `GetTotalSignSpellPower`, `ShouldEnableFinisher`; DLC XML |
| Port status | not started |
| Open checks | — |
| Save impact | none (expected) |
| NG+ counterpart | applied and scaled, untested |

**What it does** (changelist 323–332): Aard rolls stagger or knockdown first, then long stagger or heavy knockdown; knockdown chance 33% rising to 99% at 500% sign intensity, reduced by force resistance; only a heavy knockdown enables a finisher (5 s). Aard Sweep's intensity penalty 40/20/0% (fixing vanilla's formula, Bugfix 57); Aard Intensity +15% heavy knockdown chance; Shock Wave 300 damage, scaling with intensity. Not in the changelist: the roll applies to every knockdown source (Rend, Quen, counters, NPC charges); shield bearers and huge monsters step down, low-stamina targets step up; Aard deflects boulders; power-based Aard visuals; the alternate Aard's entity 1 m lower (Bugfix 35).

**5.x:** the applicator's heavy-knockdown threshold now depends on the level difference; Aard Sweep's formula defect is still there; diminishing returns for repeated Aard on one enemy within 1 s (new); classic Shock Wave deals no damage outside Mutation 6 (its branch was replaced by `magic_s33`, which deals 1% of Geralt's max Vitality per level as direct damage).

**Decisions:** core, Aard Sweep and Far-Reaching as legacy (both trees); Aard Intensity `heavy_knockdown_chance_bonus` 0.05/level (15% at 3); Shock Wave: 5.x's 100/level (= legacy's total), legacy's damage branch restored. Open: D18 (diminishing returns), D20 (`magic_s33`), D25 (boulder deflection without the skill).

### SKL-09 Igni

| | |
|---|---|
| Kind | system, tuning |
| Pillars | P3 |
| 5.x class | conflict |
| Flags | balance, needs-decision |
| Depends on | DMG (sign intensity; effect durations not scaled by power), EFX (burning), ENCH (Glyphword 7), STAM-01/03 (ported) |
| Skill trees | both: core `magic_2`; shared Melt Armor `magic_s8`; classic Firestream `magic_s2`, Igni Intensity `magic_s7`, Pyromaniac `magic_s9`; new Firestream `magic_s28` |
| Port form | wrapper or replacement of `W3EffectManager.GetSignApplyBuffTest` and `W3IgniProjectile.ProcessCollision`; the Melt Armor effects (new effect types, DLC XML) |
| Port status | not started |
| Open checks | — |
| Save impact | none (expected) |
| NG+ counterpart | applied and scaled, untested |

**What it does** (changelist 333–345): Igni deals 150 damage (scales with intensity) and has a 33% burning chance independent of intensity, reduced by burning resistance; Melt Armor applies before the damage: −10 armor and −1% resistances at level 5 (−150/−15% at 500% intensity), 15 s, not cumulative; Firestream 100 damage/s and burning as other sources; Igni Intensity +150 damage and +75/s for Firestream; Pyromaniac +25% burning chance.

**Implementation (legacy):** `magic_2` 150 and `initial_burn_chance` 0.33; `GetSignApplyBuffTest` rewritten; `EET_MeltArmorDebuff` and `EET_MeltArmorTimer` (new); Firestream and Igni Intensity damage in `ProcessCollision`; vanilla's Igni Intensity leftovers in `OnSkillEquip` and `W3Effect_BattleTrance` removed.

**5.x:** raised values; burn chance from sign power, with bonuses from Melt Armor (new `burn_chance_bonus`) and the new tree's Catalyst; classic Pyromaniac has no mechanical effect (its branch was replaced by Melt Armor's); diminishing returns cut Firestream's burning after about 1.5 s.

**Decisions:** core as legacy; Melt Armor (both trees) as legacy, values ×5/3 (−10/−1% at level 3); Firestream: legacy's numbers on both (`magic_s2` and `magic_s28`, the code reading the cast skill); Igni Intensity 50 and 25 per level; Pyromaniac 0.0833/level (25% at 3), restored by legacy's burn test. Open: D18 (diminishing returns), D21 (burn-chance bonuses).

### SKL-10 Yrden

| | |
|---|---|
| Kind | system, tuning |
| Pillars | P3 |
| 5.x class | conflict |
| Flags | balance, needs-decision |
| Depends on | DMG (shock damage ignores armor; sign intensity), AI (turret signals), STAM-01/03 (ported) |
| Skill trees | both: core `magic_3`; classic Sustained Glyphs `magic_s10` (2 levels), Yrden Intensity `magic_s16`; shared Magic Trap `magic_s3`, Supercharged Glyphs `magic_s11`; new Sustained Glyphs `magic_s42`; the new tree's general sign skills `magic_s35` to `s41` (only Catalyst and Fortify Signs touch Ghost Mode's code) |
| Port form | re-implementation of `YrdenSlowdown_Loop` and the slowdown effect on 5.x's `yrdenEntity.ws` (keeping 5.x's visuals and its `s36`/`s42` hooks); DLC XML |
| Port status | not started |
| Open checks | — |
| Save impact | none (expected) |
| NG+ counterpart | applied and scaled, untested |

**What it does** (changelist 346–357): the trap slows enemies by 25% (up to 75% at 500% intensity), lasts 7.5 s and decays over time; resisted by shock resistance; no slowdown of critical-state animations. Sustained Glyphs: no effect on the turret, +30% radius, +100% duration, a second trap. Magic Turret: 100 damage in 14 yards, ignores armor, 15 s. Yrden Intensity +150 turret damage; Supercharged Glyphs: enemies in the trap take +25% damage. Bugfix 117: the turret no longer hits targets out of range.

**5.x:** values as 1.32 except the intensity skill; new trap visuals; `magic_s42` (+5 s, +10% range, +2 charges, +1 trap per level); Fortify Signs `magic_s36` lengthens Yrden, Quen and Axii; Catalyst `magic_s35` raises Aard and Igni inside Yrden.

**Decisions:** trap core and Magic Trap as legacy (both trees); Yrden Intensity 50/level; Supercharged Glyphs 0.0833/level (25% at 3) replacing 5.x's drain in both trees (stacks with Catalyst in the new tree: balance); Catalyst's and Fortify Signs' hooks kept where legacy's rewritten functions host them. Open: D23 (Sustained Glyphs on 2 levels, and `magic_s42`).

### SKL-11 Quen

| | |
|---|---|
| Kind | system, tuning |
| Pillars | P1, P3 |
| 5.x class | conflict |
| Flags | balance, needs-decision |
| Depends on | DMG (Quen absorbs before armor: the order of damage steps), SKL-18 (Rage Management's adrenaline shield), ARM (Bear set), ENCH (Glyphwords 5, 17), STAM-01/03 (ported) |
| Skill trees | both: core `magic_4`; shared Exploding Shield `magic_s13`, Active Shield `magic_s4`; classic Quen Intensity `magic_s15`, Quen Discharge `magic_s14` |
| Port form | a damage-step hook before armor (with DMG); re-implementation of both shields' `OnTargetHit` and `GetSignStats`; `W3EffectManager.InternalAddEffect` rules; DLC XML |
| Port status | not started |
| Open checks | — |
| Save impact | none (expected) |
| NG+ counterpart | applied and scaled, untested |

**What it does** (changelist 358–370): Quen is a shield that absorbs damage before armor and resistances (250 base, scales with intensity, 30 s); it prevents stagger, burning, poison and bleeding and then breaks; casting it no longer clears damage-over-time effects. Exploding Shield: 60 damage and knock-back when it breaks; Active Shield: blocks twice as much, prevents those effects without breaking, breaks on knockdown, heals 100% of the damage absorbed; Quen Intensity +150 absorption; Quen Discharge returns 25% of the absorbed damage. The active shield's absorption drains stamina (or adrenaline with Rage Management) in proportion to the damage.

**5.x:** values as 1.32 except the classic intensity and discharge skills; casting no longer clears damage-over-time effects (in 5.x); Quen still reduces post-armor damage; supercharged-sign and Fortify Signs branches.

**Decisions:** the rework as legacy (both trees), hooked with DMG's order of damage steps; the cleanse removal is `in-5.x`; Exploding and Active Shield: legacy's numbers (3 levels already); Quen Intensity 50/level. Open: D22 (Quen Discharge).

### SKL-12 Axii

| | |
|---|---|
| Kind | system, tuning |
| Pillars | P3 |
| 5.x class | conflict; rethink (`magic_s31`) |
| Flags | balance, needs-decision |
| Depends on | DMG (sign intensity, effect durations), ENCH (Glyphwords 10, 14, 18), ALCH (Succubus decoction), STAM-01/03 (ported) |
| Skill trees | both: core `magic_5`; shared Delusion `magic_s17`, Domination `magic_s19`; classic Puppet `magic_s5`, Axii Intensity `magic_s18`; new Puppetmaster `magic_s31` |
| Port form | wrapper or replacement of `W3AxiiEntity.OnEnded`; `W3ConfuseEffect` (crit bonus, minimum duration); instant-kill functions; Delusion's time slowdown; DLC XML |
| Port status | not started |
| Open checks | — |
| Save impact | none (expected) |
| NG+ counterpart | applied and scaled, untested |

**What it does** (changelist 371–382): a failed Axii staggers; +25% crit chance against a confused enemy; confusion 5 s (scales with intensity, at least 3 s); confused enemies can be killed instantly (about 1%, more with intensity and damage dealt); damage ends confusion and knockdown. Delusion slows time while casting (+45% at level 3) and adds +75% crit against the confused; Puppet 20 s, +100% attack power, its damage a share of the victim's health; Axii Intensity +50% duration; Domination's penalty 25% per missing level. Bugfix 58 (Delusion and Puppet).

**5.x:** values as 1.32 except the intensity skill; a 270° target cone without line of sight; Puppet's duration overridden (11/13/15 s with Axii Intensity, no 8 s floor) and its damage ×1.2–1.6; Puppetmaster `magic_s31` (9 s base, +20% attack power per level, at level 3 not freed by Geralt's hits).

**Decisions:** core, Delusion and Domination as legacy (both trees); Puppet `magic_s5`: legacy's numbers (3 levels already); Axii Intensity 0.1667/level. Open: D24 (5.x's Puppet override and `magic_s31`), D26 (target cone).

### SKL-13 Brewing

| | |
|---|---|
| Kind | system, tuning |
| Pillars | P2, P8 |
| 5.x class | rethink |
| Flags | balance, needs-decision |
| Depends on | ALCH (toxicity rules, overdose threshold), SKL-01 (level sync for Prolonged Effects) |
| Skill trees | both: core `alchemy_1`; classic Refreshment (was Heightened Tolerance) `alchemy_s1`; shared Restoration `alchemy_s2`, Expert Brewer (was Delayed Recovery) `alchemy_s3`, Prolonged Effects (was Side Effects) `alchemy_s4`; new High Tolerance `alchemy_s24`, Potent Sting `alchemy_s26` |
| Port form | DLC XML; wrappers of `DrinkPreparedPotion`, `HasFreeToxicityToDrinkPotion`, `ToxicityLowEnoughToDrinkPotion`, `GetToxicityDamageThreshold`, `CalculatePotionDuration` |
| Port status | not started |
| Open checks | — |
| Save impact | none (expected) |
| NG+ counterpart | applied and scaled, untested |

**What it does** (changelist 384–391): skills cannot raise the overdose threshold; Brewing affects potions, not decoctions; Refreshment: each potion restores 30% Stamina; Restoration: heals 15%; Prolonged Effects +100% potion duration; Expert Brewer −5 potion toxicity. Ghost Mode repurposed skills by ID: `alchemy_s1` Heightened Tolerance → Refreshment, `s2` keeps vanilla's heal as Restoration, `s3` → Expert Brewer, `s4` → Prolonged Effects.

**The "Alchemy:" paragraph** (overdose at 75% of max toxicity, decay 0.25/s in and out of combat, overdose damage 0.5% of max Vitality per second) is the toxicity system's and goes to ALCH: its values are vanilla 1.32's, Ghost Mode only removed the faster decay out of combat. 5.x lowered the threshold to 50%, which also moves Endure Pain's and Frenzy's trigger (ALCH's decision).

**5.x:** Heightened Tolerance +10%/level; Refreshment heals 10%/level; Delayed Recovery and Side Effects reworked.

**Decisions:** Refreshment 0.1/level (legacy already had 3 levels); Restoration 0.05/level (15%); Prolonged Effects 0.3334/level as a global passive (needs SKL-01's level sync). `s3` and `s4` replace 5.x's Delayed Recovery and Side Effects in both trees (shared skills). Potent Sting: 5.x's. Open: D27 (Refreshment in the new tree), D28 (Expert Brewer's numbers), D29 (shared replacements and tier swaps).

### SKL-14 Oil Preparation

| | |
|---|---|
| Kind | system, tuning |
| Pillars | P8 |
| 5.x class | conflict; overlap (Hunter Instinct) |
| Flags | balance, needs-decision |
| Depends on | ALCH (oil items), ARM (Wolf set), DEF-07 (`GetPowerStatValue` wrapper) |
| Skill trees | both: core `alchemy_2`; shared Poisoned Blades `alchemy_s12`, Protective Coating `alchemy_s5`; classic Fixative `alchemy_s6`, Hunter Instinct `alchemy_s7`; new Hunter Instinct `alchemy_s27`, Volatile Compound `alchemy_s25` |
| Port form | oil bonuses read from the oil effect with a decay factor (`W3Effect_Oil`), wrappers of the attack power, resist and crit functions; `W3PlayerWitcher.ReduceDamage` (Protective Coating) |
| Port status | not started |
| Open checks | — |
| Save impact | none (expected) |
| NG+ counterpart | applied and scaled, untested |

**What it does** (changelist 392–402): oil bonuses fall to 50% as the oil wears off; Poisoned Blades +15% poison chance (+5% enhanced, +10% superior oil), resisted; Protective Coating −15% damage from the oil's monster type (+5%/+10%), as a cut of final damage; Fixative +33% charges per level, no wear at level 3; Hunter Instinct +33.4% crit damage per adrenaline point (max 100%). Not in the changelist: oil crit chance melee only, empty oils removed, the charge percentage fixed (vanilla integer division).

**5.x:** oil code as 1.32 plus an auto-apply option; Hunter Instinct fixed differently (full adrenaline only); `alchemy_s27` needs full adrenaline and the right oil. Fixative's 5.x descriptions promise two or three oils, but no script does it (from the code).

**Decisions:** oil decay in both trees; Poisoned Blades and Protective Coating 0.05/level (15% at 3, = legacy's total) plus the oil-level bonuses; legacy's save fix that sets Protective Coating to 5 levels is not ported (5.x's skill has 3); Fixative: 5.x's data with legacy's code fixes; Hunter Instinct `alchemy_s7` 0.1113/level per adrenaline point (33.4% per point at 3); Volatile Compound: 5.x's. Open: D30 (`alchemy_s27`).

### SKL-15 Bomb Creation

| | |
|---|---|
| Kind | system, tuning |
| Pillars | P8 |
| 5.x class | clean; overlap (Cluster Bombs) |
| Flags | balance, needs-decision |
| Depends on | ALCH (bomb items), SKL-06 (the non-aimed damage line), SKL-18 (Advanced Pyrotechnics, Heavy Artillery) |
| Skill trees | both: core `alchemy_3`; classic Steady Aim `alchemy_s9`; shared Pyrotechnics `alchemy_s10`, Efficiency `alchemy_s8`, Cluster Bombs `alchemy_s11`; new Toxic Shock `alchemy_s23` |
| Port form | DLC XML; the non-aimed step shared with SKL-06; `W3Petard` cluster code |
| Port status | not started |
| Open checks | — |
| Save impact | none (expected) |
| NG+ counterpart | applied and scaled, untested |

**What it does** (changelist 403–410): non-aimed bombs −50%; bomb damage is not affected by attack power (vanilla already: no unit); Pyrotechnics +250 damage; Efficiency +5 bombs; Cluster Bombs: 6 fragments, each dealing a full bomb's damage. Ghost Mode's Cluster Bombs damage values are read by no script.

**5.x:** Pyrotechnics 50/level; Efficiency +1/level; Cluster Bombs level + 1 fragments at 40% damage each; Steady Aim one level.

**Decisions:** non-aimed −50% in both trees; Pyrotechnics 83.33/level (250 at 3); Steady Aim and Toxic Shock: 5.x's. Open: D31 (Cluster Bombs), D32 (Efficiency).

### SKL-16 Mutation

| | |
|---|---|
| Kind | system, tuning |
| Pillars | P8 |
| 5.x class | conflict; rethink (Adaptation) |
| Flags | balance, needs-decision |
| Depends on | ALCH (decoctions and their toxicity offsets) |
| Skill trees | both: core `alchemy_4`; shared Acquired Tolerance `alchemy_s18`, Tissue Transmutation `alchemy_s13`, Adaptation (was Adaptability) `alchemy_s14`; classic Synergy `alchemy_s19` (new tree: `perk_43`) |
| Port form | `RecalcAlchemy18Abilities`, `RecalcTransmutationAbilities`, `GetAdaptationToxReduction` and their callers |
| Port status | not started |
| Open checks | — |
| Save impact | none (expected) |
| NG+ counterpart | applied and scaled, untested |

**What it does** (changelist 410–418): Acquired Tolerance: every known formula +1 max toxicity, up to 50 per level (150); Tissue Transmutation: +10 Vitality per point of toxicity offset of active decoctions; Adaptation: decoction toxicity −20%; Synergy +50%.

**5.x:** Acquired Tolerance 0.5 per formula of the skill's level or lower; Tissue Transmutation +300 per decoction; Adaptability +33% decoction duration per level; Synergy 0.1/level.

**Decisions:** Tissue Transmutation 3.333/level per offset point; Adaptation 0.0667/level (−20% at 3), replacing 5.x's Adaptability in both trees; Synergy: 5.x's values. Open: D29 (tier swap with Synergy), D33 (Acquired Tolerance per formula).

### SKL-17 Trial of the Grasses

| | |
|---|---|
| Kind | system, tuning, fix |
| Pillars | P8 |
| 5.x class | conflict |
| Flags | balance, needs-decision |
| Depends on | ALCH (overdose threshold) |
| Skill trees | both: core `alchemy_5`; shared Frenzy `alchemy_s16`, Endure Pain `alchemy_s20`, Fast Metabolism `alchemy_s15`; classic Killing Spree `alchemy_s17` (no new-tree counterpart); new Debilitating Poison `alchemy_s22` |
| Port form | DLC XML; wrappers of `StartFrenzy`, `CNewNPC.OnPreAttackEvent`, `W3Effect_Toxicity.OnUpdate`/`OnEffectRemoved`, `OnSkillEquip` |
| Port status | not started |
| Open checks | — |
| Save impact | none (expected) |
| NG+ counterpart | applied and scaled, untested |

**What it does** (changelist 419–425): Frenzy: 75% time slowdown for 1.5 s when an enemy counterattacks, and +25% attack power and sign intensity while overdosed; Endure Pain +50% Vitality when overdosed (with two fixes: applied on equip, removed when toxicity ends); Fast Metabolism +1.25/s decay; Killing Spree +25% crit per kill.

**5.x:** raised values on 3 levels; vanilla code.

**Decisions:** Frenzy 0.25/level slowdown (75% at 3), 1.5 s, 0.0833/level attack power and intensity while overdosed; Endure Pain's fixes; Fast Metabolism −0.4167/level; Killing Spree 0.0833/level; Debilitating Poison: 5.x's. Open: D34 (Endure Pain's value).

### SKL-18 Perks

| | |
|---|---|
| Kind | system, tuning |
| Pillars | P2, P8 |
| 5.x class | clean or conflict (classic: 5.x changed only `perk_4`); rethink (new tree) |
| Flags | balance, needs-decision |
| Depends on | ARM (armor classes for the school perks), FOOD (Connoisseur), WGT (Strong Back), GEN (Vitality), STAM-03 (cost functions, ported), SKL-07, SKL-15 |
| Skill trees | both: classic `perk_1` to `perk_22` (1 level each); new `perk_23` to `perk_44` (3 levels each) and the new tree's Focus `magic_s38`, Cold Blood `sword_s34` |
| Port form | DLC XML; STAM-03's cost functions extended (Perks 6, 9, 10); `ManageFocusGain` (new); wrappers of `OnProcessActionPost`, `PerformCounterCheck`, `CNewNPC.OnDeath`, the food effects |
| Port status | not started |
| Open checks | — |
| Save impact | none (expected) |
| NG+ counterpart | applied and scaled, untested |

**What it does** (changelist 427–467): Sun and Stars +5 stamina regen at night; Survival Instinct +750 Vitality; Cat, Griffin and Bear School per armor piece (crit chance and power; intensity and −5% sign cost; Vitality and adrenaline gain); Cold Blood as a perk (bolt adrenaline as a sword hit); Rage Management casts with adrenaline first; Adrenaline Burst −10% melee cost per adrenaline point; Focus +15% intensity per point, signs generate adrenaline; Metabolic Control +40; Metabolism Boost fixes; Advanced Pyrotechnics divided by cluster fragments; Battle Frenzy +10% crit per point; Strong Back +40; Connoisseur (replaces Gourmet); In Combat's Fires −50% damage from own bombs and bolts; Heavy Artillery ×2 (additive); Attack is the Best Defense: stamina instead of adrenaline (15% on a kill, 5% on a crit or counter, 2.5 s cooldown).

**Implementation (legacy):** mostly XML (per-perk values, `perk_21`'s attributes in the expansion file); code: `GetPerk6StaminaCostReduction`, `GetPerk10Bonus`, Rage Management's adrenaline-first branches in the sign states (STAM-03's units), `ManageFocusGain`, `Perk21GainStamina` and its triggers, Connoisseur in the food effects and `ConsumeItem`, In Combat's Fires in `ProcessDamageModification`, Heavy Artillery in `ProcessDamageIncrease`.

**5.x:** every classic perk as 1.32 except Survival Instinct (+15%); Metabolism Boost's drain fix is in 5.x. New-tree counterparts: Sun and Stars `perk_38`, Survival Instinct `perk_30`, Cat `perk_23`, Griffin `perk_24`, Bear `perk_25`, Anger Management `perk_34`, Adrenaline Burst `perk_42`, Focus `magic_s38`, Metabolic Control `perk_33`, Metabolic Boost `perk_32`, Gourmand `perk_41`, Advanced Pyrotechnics `perk_39` (another design), Battle Frenzy `perk_40`, Attack is the Best Defense `perk_31`, Strong Back `perk_35`, Synergy `perk_43`; new-only: Wolf, Manticore, Viper School, Elemental Attunement, Element of Surprise.

**Decisions:** classic perks as legacy (1 level, no rescaling); Metabolism Boost's pre-check fix ports, the unused `Perk13Effect` does not; Perk 21's port ends DEF-06's temporary deviation. New tree by the area rule: Sun and Stars night 1.667%/level; Cat 1.667% crit chance and 6.667% crit power per piece per level; Griffin 1.667% intensity and −1.667% sign cost per piece per level; Bear 2.5% Vitality and 0.00833 adrenaline per hit per piece per level; Anger Management adrenaline-first with 5.x's costs; Adrenaline Burst −3.334% melee cost per point per level; Focus `magic_s38` 5% per point per level and signs give adrenaline; Metabolic Control and Strong Back 13.334/level; Battle Frenzy 3.334%/level; Attack is the Best Defense: legacy's stamina rule (5/10/15% on a kill, 1.667/3.334/5% on a crit or counter); Survival Instinct, Metabolic Boost, Advanced Pyrotechnics, Elemental Attunement, Element of Surprise, the medium-armor schools and Synergy: 5.x's. Open: D37 (Survival Instinct), D38 (In Combat's Fires), D39 (own bombs in the new tree), D40 (sign adrenaline), D41 (Gourmand), D42 (horse Axii).

### SKL-19 Skill and perk descriptions

| | |
|---|---|
| Kind | ui |
| Pillars | P7 |
| 5.x class | conflict |
| Flags | — |
| Depends on | every SKL feature |
| Skill trees | both: `characterMenu.ws` (classic) and `characterMenuDupe.ws` (new) |
| Port form | tooltip cases in both menus; string rows (Ghost Mode's ID space, 9 languages) |
| Port status | not started |
| Open checks | — |
| Save impact | none (expected) |
| NG+ counterpart | none |

**What it does:** "Almost all the descriptions for skills and perks in-game were changed for clarity and to reflect mod changes" (changelist 256). Legacy: new tooltip arguments in `CR4CharacterMenu.Get{Sword,Sign,Alchemy}SkillsTooltipDescription` and `GetPerkTooltipDescription`, the passive lines removed; 108 skill and perk strings in 9 languages; skill lines in the character stats popup.

**5.x:** two menus with their own tooltip functions; shared skills on new string keys (above); the new menu appends the passive line to every tooltip.

**Decisions:** open: D45 (descriptions with each skill's slice).

---

### Decisions waiting for the owner

SKL's decisions (D1–D52: questions, recommendations, what is decided) are kept in [skl-decisions.md](../skill-trees/skl-decisions.md), next to the skills' texts in both games, with one row per skill of every tree. They are revisited often there; the entries above refer to them by number.

---

### Hand-off to other areas

| Area | Changes (legacy units) |
|---|---|
| DMG | The additive damage bonus in `ProcessDamageIncrease` (Strong Attack, Rend, reflected arrows, Steady Shot, Heavy Artillery), the heavy-attack power penalty, `ProcessDamageModification`, sign intensity conversion (`SignPowerStatToPowerBonus`), effect durations not scaled by power (`CBaseGameplayEffect.CalculateDuration`), shock damage ignoring armor, Quen's place before armor |
| ALCH | The toxicity rules (`TOXICITY_DAMAGE_THRESHOLD`, 5.x 0.50001 vs legacy 0.75; `W3Effect_Toxicity.OnUpdate`; `GetToxicityDamage`); potion, decoction and bomb items; mutagen decoctions (`mutagenNN.ws`, `effects_mutagens.xml`) |
| STAM | Correction: the active Quen shield still drains stamina (or adrenaline) in proportion to the damage absorbed; legacy only removed the controller vibration from `W3QuenEntity.OnTargetHit`. STAM-09's Whirl cost reduction moves to the area's 3-level rule; `GainStat`'s adrenaline pause and `CActor.PauseFocusGain`/`IsFocusGainPaused` are STAM-09's code, missing from attribution |
| DEF | DEF-02 gets Fleet Footed's values (SKL-05); DEF-07's counters get attack power once (SKL-03's deviation); SKL ends DEF-07's, DEF-08's and part of DEF-06's temporary deviations |
| EFX | Bleeding rework (strength as % of max health, bleeding resistance) for Crippling Strikes; low-stamina knockdown severity |
| XBOW | Crossbow crit rules in `CR4Player.GetCriticalHitChance`/`GetCriticalHitDamageBonus`, NPC bow damage, crossbow stat lines |
| ARM | Armor classes for the school perks; Bear, Griffin, Wolf, Lynx and Viper sets in skill functions |
| ENCH, MUT | Glyphwords and runewords in sign and skill functions; Mutations 6, 7, 8, 10, 11, 12 in the same units |
| AI | The Yrden turret's removed `EntersYrden`/`LeavesYrden` signals; flyers forced to land when hit; NPC Quen |
| FOOD, WGT, GEN, HORSE | Connoisseur's alcohol and raw-food toxicity; Strong Back's weight; the Vitality model (Survival Instinct); horse Axii's adrenaline payment |
| UI | The character stats popup outside the skill lines |
