# DEF: dodging, parrying and countering

Ghost Mode makes the player's defence precise and decisive (pillar P9): a successful dodge, parry or counter takes no damage and no effects, a half-successful one (a graze while dodging, a partial parry or counter of an attack that cannot be fully blocked) halves the damage, and a counter is rewarded instead of penalised. The changelist's in-game description: "Wolf School defensive techniques: parry, counter, dodge. Successful parry, counter and dodge reduce damage taken to zero and prevent all negative effects. Successful countering grants additional 25% chance to critical hit. Partial parry reduces damage taken by 50% and prevents bleeding. Rolling grants immunity to all knockdown and stagger effects and allows to dodge arrows."

**How legacy Ghost Mode implements it.** The damage manager decides a dodge before any damage is computed (`ProcessAction` calls a new `DodgeDamage` on the victim), so a dodged hit never reaches the damage formula; the player's dodge test (safe angle 120°, vanilla 150°) and the graze reduction live in `W3PlayerWitcher.DodgeDamage` and `ReduceDamage`. Parry and counter rules are spread over `CR4Player.PerformParryCheck` and `PerformCounterCheck`, `CActor.ReduceDamage` (the partial-parry share), the damage manager (staggers, effects, a per-enemy "was countered" flag and its crit bonus) and a few XML entries.

**What 5.x did in this area.** The damage manager and the parry and counter checks changed in small, additive ways, but 5.x's skill rework touches this area's skills: Fleet Footed exists twice (`sword_s9`, one level, a full dodge at maximum; the reworked tree's `sword_s36`, three levels), Deflection has a new counterpart for arrows (`S_Sword_s33`, with deflectable boulders), and a new skill (`S_Sword_s31`) builds on vanilla's "recently countered or dodged" flags. Vanilla's player dodge block in `ReduceDamage` gained the new Fleet Footed.

Stamina costs of dodges, parries and counters are STAM-03's; NPC defence and its stamina are STAM-08's and AI's. 34 units are attributed to this area (2026-10-03, mapped from the changelist and a sweep of dodge, parry and counter units; 5 of them shared with STAM-03 and STAM-08); the sweep's other matches belong to the areas in the [hand-off list](#hand-off-to-other-areas). Unit lists: [attribution.csv](attribution.csv). Port status: mapped; nothing ported yet. All findings below come from reading the code; nothing in this area has been tested in game yet.

---

### DEF-01 Dodge resolution

| | |
|---|---|
| Kind | system |
| Pillars | P9 |
| 5.x class | conflict |
| Flags | balance |
| Depends on | ARM (light armor bonus, read only) |
| Skill trees | n/a (reads the light armor bonus, not a skill) |
| Port form | `@wrapMethod(W3DamageManagerProcessor) ProcessActionDamage` (dodge first, skip damage when dodged); `@addMethod(CActor)` and per-class `DodgeDamage`; `@wrapMethod(W3PlayerWitcher) ReduceDamage` to switch off vanilla's dodge block |
| Port status | not started |
| Open checks | — |
| Save impact | none (expected) |
| NG+ counterpart | none |

**What it does:** a dodgeable attack is avoided completely when the dodge angle (0° dodging straight away from the attack, 180° dodging into it) is within the safe angle: 120° (vanilla 150°), +30° with the light armor set bonus; an undodgeable attack hits inside its hitbox; environment and damage-over-time are never dodged. The dodge is decided before damage, and also counts when the combat action is a dodge or roll ("Inconsistent dodge registration bug is fixed", Bugfixes). The Ice Giant's stomp keeps vanilla's rule.

**Implementation (legacy):** `ProcessAction` calls the new `CActor.DodgeDamage` (vanilla's NPC dodge, moved out of `ReduceDamage`) before `ProcessActionDamage`; `W3PlayerWitcher.DodgeDamage` is the player's test; vanilla's dodge block is removed from both `ReduceDamage`s.

**5.x:** `ProcessAction` now guards the pre-hit steps with `GetSimulateOnly()`; vanilla's 150° player block is still in `W3PlayerWitcher.ReduceDamage` and now also handles 5.x's second Fleet Footed (`S_Sword_s36`): left in place it would re-test hits Ghost Mode decided were not dodged. A new 5.x hook marks dodged hits for `S_Sword_s31`; it reads the dodge flag, so it keeps working.

**Decisions:** port as legacy (proposed). Until DEF-02 replaces it with the graze rule, 5.x's Fleet Footed handling of failed dodges stays (vanilla's branch in `W3PlayerWitcher.ReduceDamage`: damage reduced on a failed dodge, a full dodge at the top level; the classic `sword_s9` has one level) (project owner, 2026-10-03). Open for the port: whether an `@addMethod` override in a subclass works when the base method was also added by `@addMethod` (fallback: one method that dispatches by type); whether the dodge-registration fallback is still needed in 5.x; confirm in game that a dodged hit plays no hit reaction (the player path only flags the hit).

### DEF-02 Graze damage

| | |
|---|---|
| Kind | system, tuning |
| Pillars | P9 |
| 5.x class | clean (mechanism); rethink (the skill) |
| Flags | balance, needs-decision |
| Depends on | DEF-01; SKL (which Fleet Footed) |
| Skill trees | both: classic `sword_s9`, new `sword_s36` (Fleet Footed) |
| Port form | `@addField`/`@addMethod` on `W3DamageAction` (graze value), `@wrapMethod` of its `Clear`; applied in DEF-01's `ReduceDamage` wrapper |
| Port status | not started |
| Open checks | — |
| Save impact | none (expected) |
| NG+ counterpart | applied and scaled, untested |

**What it does:** while dodging or rolling, damage that is not fully dodged is reduced by Fleet Footed, 10% per level, whether or not the attack could be dodged ("Fleet Footed reduces the damage taken while dodging (aka graze damage) by 10% per skill level"). Vitality damage only, at most 95%. Vanilla 1.32 reduced only failed dodges of dodgeable attacks, and at its top level turned them into full dodges.

**Implementation (legacy):** a graze field and accessors on `W3DamageAction`, set from `s9_damage_reduction` × the skill's level in the player's `DodgeDamage`, applied in `ReduceDamage` before Quen.

**5.x:** Fleet Footed is redesigned: the classic `sword_s9` has one level and a full dodge, the reworked tree's `sword_s36` three levels. Legacy reads only `sword_s9`.

**Decisions:** the mechanism ports as legacy, for [both skill trees](../feature-mapping.md#two-skill-trees): the classic tree's `sword_s9` and the new tree's `sword_s36`. 5.x's versions of both skills are kept ([decision](../feature-mapping.md#two-skill-trees)): `sword_s9` has one level in 5.x, so how legacy's 10% per level maps onto it, and onto `sword_s36`'s three levels, is decided with SKL.

### DEF-03 Roll immunity to long stagger

| | |
|---|---|
| Kind | tuning |
| Pillars | P9 |
| 5.x class | clean |
| Flags | — |
| Depends on | — |
| Skill trees | n/a |
| Port form | `@wrapMethod(CR4Player) SetIsCurrentlyDodging` |
| Port status | not started |
| Open checks | — |
| Save impact | none (expected) |
| NG+ counterpart | none |

**What it does:** "Rolling grants immunity to all knockdown and stagger effects": vanilla already blocks knockdowns and staggers while rolling; Ghost Mode adds long stagger.

### DEF-04 Ciri's dodge

| | |
|---|---|
| Kind | system |
| Pillars | P9 |
| 5.x class | clean |
| Flags | — |
| Depends on | DEF-01 |
| Skill trees | n/a |
| Port form | `DodgeDamage` for `W3ReplacerCiri` |
| Port status | not started |
| Open checks | — |
| Save impact | none (expected) |
| NG+ counterpart | none |

**What it does:** not in the changelist. Ciri dodges any dodgeable attack whatever the angle (vanilla: under 150°); a dodged hit also clears its effects and plays no hit animation.

**Decisions:** port as legacy (legacy behaviour first), though unannounced.

### DEF-05 Parrying rules

| | |
|---|---|
| Kind | system |
| Pillars | P9 |
| 5.x class | conflict |
| Flags | balance |
| Depends on | STAM-03 (parry costs, partial parry without stamina) |
| Skill trees | both: Deflection (`sword_s10`, classic) reduces the partial-parry share; new-tree counterpart to check with SKL |
| Port form | STAM-03's `ProcessAction` wrapper and `PerformParryCheck` replacement extended; the partial-parry share in a `CActor.ReduceDamage` wrapper or replacement; constant as a GM getter |
| Port status | not started |
| Open checks | — |
| Save impact | none (expected) |
| NG+ counterpart | none |

**What it does:** "parrying at attack reduces the damage to zero and prevents all the negative effects"; a heavy attack without knockdown is parried partially: 50% damage, no bleeding, a short stagger (vanilla: a long stagger, and a share of 30% or 60% of the damage by the attacker's size); a parry with too little stamina becomes partial (STAM-03, ported); a fist parry against a weapon fails.

**Implementation (legacy):** `CActor.ReduceDamage` (the partial share, `PARRY_STAGGER_REDUCE_DAMAGE` 0.5 in `W3GameParams`, less with Deflection: SKL), `ProcessAction` (stagger instead of long stagger), `PerformParryCheck` (fist parry, removed break-through stagger and fistfight stamina damage). The removed deadly-level gate in `TestParryAndCounter` is already in 5.x; the removed parry-fail chance reads an attribute no 5.x data defines (no-op).

**5.x:** the parry functions are unchanged or changed elsewhere; 5.x still gives the long stagger. STAM-03's replacement of `PerformParryCheck` kept vanilla's fist-parry and break-through lines, so DEF edits that replacement.

**Decisions:** port as legacy. The long stagger (project owner, 2026-10-03): try a wrapper-level way first (e.g. removing the long stagger right after vanilla adds it); replace `ProcessAction` only if that fails. Open: how exactly to suppress vanilla's long stagger without replacing `ProcessAction` (a flag set before the vanilla block stops all buffs, including Ghost Mode's stagger). Unresolved: whether parrying a knockdown attack that cannot be parried took no damage at all in legacy (the code suggests so, which would contradict the changelist; legacy cannot be run here, so the port follows the changelist unless the owner recalls otherwise); and STAM-03's wrapper together with vanilla's block may give both staggers to a parry without stamina.

### DEF-06 Counters and partial counters

| | |
|---|---|
| Kind | system |
| Pillars | P9 |
| 5.x class | conflict |
| Flags | — |
| Depends on | STAM-03 (counters need stamina), DEF-05 |
| Skill trees | both: Counterattack (`sword_s11`, classic); new-tree counterpart to check with SKL |
| Port form | `@replaceMethod(CR4Player) PerformCounterCheck` on the 5.x body (STAM-03's wrapper stays); the counter branch in the `ProcessAction` wrapper; `@wrapMethod(W3Effect_CounterStrikeHit) CacheSettings`; DLC XML for `CounterStrikeHitEffect` |
| Port status | not started |
| Open checks | — |
| Save impact | none (expected) |
| NG+ counterpart | applied and scaled, untested |

**What it does:** "all the light attacks can be countered"; a counter no longer depends on whether the attack can be parried, and countering an attack that cannot be parried is a partial counter (like a partial parry, its effects cleared); the countered enemy is stunned for 1 s (vanilla 0.5 s) and cannot roll, sprint or dodge meanwhile; reworked repel animations (the Grave Hag's special repel only against her tongue, a side-step against two-handed and tournament fighters).

**5.x:** `PerformCounterCheck` changed (spear destruction).

**Decisions:** port as legacy, including the dropped `CannotBeCountered` check: enemies that carry that ability (e.g. sq701's Gregoire, the barrens ghost) become counterable (project owner, 2026-10-03). Parts that belong elsewhere: Counterattack's knockdown (SKL), Mutation 8 (MUT), the Lynx set (ARM), Perk 21 (SKL).

### DEF-07 Counter bonuses

| | |
|---|---|
| Kind | system, tuning |
| Pillars | P9 |
| 5.x class | clean (attack type, XML); overlap (counter tracking) |
| Flags | balance |
| Depends on | DEF-06 |
| Skill trees | both: `IsLightAttack` also lists the new tree's Whirl `sword_s35`; `S_Sword_s31` (new) reads the counter flag |
| Port form | DLC XML for `counter_attack_light`; `@wrapMethod(CR4Player) IsLightAttack`; a per-enemy flag (`@addField`/`@addMethod(CActor)`) set and cleared in damage-manager wrappers; `@wrapMethod(W3PlayerWitcher) GetCriticalHitChance` |
| Port status | not started |
| Open checks | — |
| Save impact | none (expected) |
| NG+ counterpart | applied and scaled, untested |

**What it does:** "counter is now considered a light attack, so all the light attack bonuses apply"; counters are not damage-reduced (vanilla −75% attack power) and the countered enemy takes +25% critical chance from the player's next hit within 3 s.

**5.x:** unchanged except that `IsLightAttack` gained 5.x's `sword_s35`, and 5.x's new `S_Sword_s31` reads vanilla's "recently countered" flag, which legacy removed.

**Decisions:** keep vanilla's flag (5.x's skills need it) and add Ghost Mode's per-enemy flag beside it, a deviation in implementation only. Open for the port: whether `@addMethod` can add a timer function (fallback: compare engine time).

### DEF-08 Arrow parry

| | |
|---|---|
| Kind | system |
| Pillars | P9 |
| 5.x class | rethink |
| Flags | — |
| Depends on | SKL (Deflection, 5.x's `S_Sword_s33`) |
| Skill trees | both: classic Deflection `sword_s10`, new `S_Sword_s33` |
| Port form | `@replaceMethod(W3ArrowProjectile) OnProjectileCollision` on the 5.x body, or keep 5.x's design |
| Port status | not started |
| Open checks | — |
| Save impact | none (expected) |
| NG+ counterpart | none |

**What it does:** "Arrows can be parried": with the guard up, arrows are always parried (vanilla needs Deflection); Deflection reflects them from its first level (vanilla: second). With STAM-03, an arrow parry costs stamina and, without stamina, still parries fully (arrows have no partial parry).

**5.x:** redesigned: parrying arrows needs Deflection or the new `S_Sword_s33`, with its own deflection path and deflectable boulders.

**Decisions:** legacy's ungated arrow parry on 5.x's function (project owner, 2026-10-03): with the guard up anyone parries arrows; 5.x's Deflection and `S_Sword_s33` keep their extra effects (reflection, deflection), to be checked against SKL's mapping.

---

### Hand-off to other areas

| Area | Changes (legacy units) |
|---|---|
| ARM | The light armor set bonus ability (`ArmorTypeLightSetBonusAbility`, +30° dodge angle) in `geralt_skills.xml`, granted in `PlayerAbilityManager`, shown in an item tooltip; DEF-01 only reads it |
| SKL | Fleet Footed (which skill DEF-02 targets, `s9_damage_reduction`, the free dodge removal in `PerformEvade`); Deflection (partial-parry share, arrow reflection level, level-3 damage moved to the damage manager); Counterattack (attack power, crit from level 2, knockdown); Deadly Precision on countered enemies; Perk 21 |
| AI | NPC dodge rules (minimum distance) and NPC defence tasks (`btTaskDodge.ws`, `btTaskReaction.ws`); `IncDefendCounter`/`IncHitCounter` windows 2 → 2.5 s |
| SWD | The Iris phantom strike cannot be dodged (`CActor.PrepareAttackAction`) |
| MUT, ALCH, ENCH, FIX | Mutation 8 in counters; mutagens and Quen next to the dodge in `ReduceDamage`/`OnTakeDamage`; Glyphword 1 and the arrow collision fixes in `OnProjectileCollision` |
| UI | Skill descriptions reading the partial-parry constant (`characterMenu`) |
