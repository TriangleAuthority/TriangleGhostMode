# DEF: dodging, parrying and countering

Ghost Mode makes the player's defence precise and decisive (pillar P9): a successful dodge, parry or counter takes no damage and no effects, a half-successful one (a graze while dodging, a partial parry or counter of an attack that cannot be fully blocked) halves the damage, and a counter is rewarded instead of penalised. The changelist's in-game description: "Wolf School defensive techniques: parry, counter, dodge. Successful parry, counter and dodge reduce damage taken to zero and prevent all negative effects. Successful countering grants additional 25% chance to critical hit. Partial parry reduces damage taken by 50% and prevents bleeding. Rolling grants immunity to all knockdown and stagger effects and allows to dodge arrows."

**How legacy Ghost Mode implements it.** The damage manager decides a dodge before any damage is computed (`ProcessAction` calls a new `DodgeDamage` on the victim), so a dodged hit never reaches the damage formula; the player's dodge test (safe angle 120°, vanilla 150°) and the graze reduction live in `W3PlayerWitcher.DodgeDamage` and `ReduceDamage`. Parry and counter rules are spread over `CR4Player.PerformParryCheck` and `PerformCounterCheck`, `CActor.ReduceDamage` (the partial-parry share), the damage manager (staggers, effects, a per-enemy "was countered" flag and its crit bonus) and a few XML entries.

**What 5.x did in this area.** The damage manager and the parry and counter checks changed in small, additive ways, but 5.x's skill rework touches this area's skills: Fleet Footed exists twice (`sword_s9`, one level, a full dodge at maximum; the reworked tree's `sword_s36`, three levels), Deflection has a new counterpart for arrows (`S_Sword_s33`, with deflectable boulders), and a new skill (`S_Sword_s31`) builds on vanilla's "recently countered or dodged" flags. Vanilla's player dodge block in `ReduceDamage` gained the new Fleet Footed.

Stamina costs of dodges, parries and counters are STAM-03's; NPC defence and its stamina are STAM-08's and AI's. 34 units are attributed to this area (5 of them shared with STAM-03 and STAM-08). Related changes in other areas: the light armor set's +30° dodge angle (ARM, read by DEF-01), the attack-power skills counted once (SKL-03, D47), Fleet Footed, Deflection, Counterattack, Deadly Precision and Perk 21 (SKL), NPC dodge rules and defence tasks (AI-09, AI-10), the Iris phantom strike that cannot be dodged (SWD-06), Mutation 8 in counters (MUT-06), mutagens and Quen beside the dodge (ALCH, ENCH), Glyphword 1 and the arrow collision fixes (ENCH-11, FIX), and skill descriptions reading the partial-parry constant (UI). Unit lists: [attribution.csv](attribution.csv). Port status: **signed off** by the owner (DEF-01, DEF-03 to DEF-08 on 2026-10-04; DEF-02 with SKL on 2026-10-17).

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
| Port form | `@wrapMethod(W3DamageManagerProcessor) ProcessActionDamage` (dodge first, skip damage when dodged); `@addMethod(CActor) GMDodgeDamage` (NPC rule, dispatches to `@addMethod(W3PlayerWitcher) GMPlayerDodgeDamage`); `@replaceMethod(W3PlayerWitcher) ReduceDamage` (5.x body without vanilla's 150° check). In `defense/dodge.ws` |
| Port status | signed off |
| Open checks | a real hit during a real dodge at more than 120° (the light armor set's +30° is verified with scripted hits, ARM-04) (the real dodges tested went straight away); the Ice Giant's stomp; whether a dodged hit plays a hit reaction (the same path as vanilla's dodge: no damage, flagged dodged) |
| Save impact | none (expected) |
| NG+ counterpart | none |

**What it does:** a dodgeable attack is avoided completely when the dodge angle (0° dodging straight away from the attack, 180° dodging into it) is within the safe angle: 120° (vanilla 150°), +30° with the light armor set bonus; an undodgeable attack hits inside its hitbox; environment and damage-over-time are never dodged. The dodge is decided before damage, and also counts when the combat action is a dodge or roll ("Inconsistent dodge registration bug is fixed", Bugfixes). The Ice Giant's stomp keeps vanilla's rule.

**Implementation (legacy):** `ProcessAction` calls the new `CActor.DodgeDamage` (vanilla's NPC dodge, moved out of `ReduceDamage`) before `ProcessActionDamage`; `W3PlayerWitcher.DodgeDamage` is the player's test; vanilla's dodge block is removed from both `ReduceDamage`s.

**5.x:** `ProcessAction` now guards the pre-hit steps with `GetSimulateOnly()`; vanilla's 150° player block is still in `W3PlayerWitcher.ReduceDamage` and now also handles 5.x's second Fleet Footed (`S_Sword_s36`): left in place it would re-test hits Ghost Mode decided were not dodged. A new 5.x hook marks dodged hits for `S_Sword_s31`; it reads the dodge flag, so it keeps working.

**Decisions:** port as legacy.

Vanilla's 150° check in `W3PlayerWitcher.ReduceDamage` is removed by replacing that function with its 5.x body minus the check (Fleet Footed's branch kept), as legacy removed it. The port dispatches from one `CActor` method by type instead of overriding an added method in a subclass. Legacy's fallback that counts a dodge or roll combat action as dodging is kept (legacy's comment calls it probably unneeded; it costs nothing). The dodge check is skipped for simulate-only actions, which 5.x added (no script sets them). Vanilla's NPC dodge in `CActor.ReduceDamage` stays in place but no longer fires: the same rule, decided earlier, skips the damage step.

**Slices:**

1. **Dodge resolution.** Verified 2026-10-04 (`gmtest_def01`, scripted hits from a spawned wolf through the damage manager, Geralt's dodge state set by script): dodged at 0° and 119°, hit at 121°, 145° and 170°; undodgeable attacks, environment damage and damage over time hit; a dodging NPC dodges, except undodgeable attacks. In a real fight (`gmtest_def01_real_a/b`, `gmtest_def_dodge`, scripted dodge input, real wolf bites): bites during a dodge were dodged, bites outside one hit. Ghost Mode's `ReduceDamage` replacement wins over other mods replacing the same function.

### DEF-02 Graze damage

| | |
|---|---|
| Kind | system, tuning |
| Pillars | P9 |
| 5.x class | clean (mechanism); rethink (the skill) |
| Flags | balance, needs-decision |
| Depends on | DEF-01; SKL (which Fleet Footed) |
| Skill trees | both: classic `sword_s9`, new `sword_s36` (Fleet Footed) |
| Port form | `@addField`/`@addMethod` on `W3DamageAction` (graze value), `@wrapMethod` of its `Clear` (`skills/fleetFooted.ws`); set in DEF-01's `GMPlayerDodgeDamage`, applied in `W3PlayerWitcher.ReduceDamage` (`defense/dodge.ws`) |
| Port status | signed off with SKL (2026-10-17) |
| Open checks | a real graze in a fight; that dodges cost stamina while the target attacks (5.x's free dodge, removed by replacing `SkipStaminaDodgeEvadeCost`, not tested) |
| Save impact | none (expected) |
| NG+ counterpart | applied and scaled, untested |

**What it does:** while dodging or rolling, damage that is not fully dodged is reduced by Fleet Footed, 10% per level, whether or not the attack could be dodged ("Fleet Footed reduces the damage taken while dodging (aka graze damage) by 10% per skill level"). Vitality damage only, at most 95%. Vanilla 1.32 reduced only failed dodges of dodgeable attacks, and at its top level turned them into full dodges.

**Implementation (legacy):** a graze field and accessors on `W3DamageAction`, set from `s9_damage_reduction` × the skill's level in the player's `DodgeDamage`, applied in `ReduceDamage` before Quen.

**5.x:** Fleet Footed is redesigned: the classic `sword_s9` has one level and a full dodge, the reworked tree's `sword_s36` three levels. Legacy reads only `sword_s9`.

**Decisions:** the mechanism ports as legacy, for [both skill trees](../feature-mapping.md#two-skill-trees): the classic tree's `sword_s9` and the new tree's `sword_s36`. SKL decided the values (project owner, 2026-10-08; [SKL-05](skl.md#skl-05-defense-branch)): legacy's Fleet Footed in both trees, the classic `sword_s9` with legacy's 5 levels at 10% per level, the new `sword_s36` at 16.67% per level (50% at level 3), without 5.x's full dodge and free dodge.

**Slices:**

1. **Graze damage.** Verified 2026-10-14 (`gmtest_def02`, scripted hits from a wolf, Geralt's dodge state set by script; classic level 5 and new tree level 3): a failed dodge and an undodgeable attack while dodging take half damage and do not count as dodges; a successful dodge still takes nothing.

### DEF-03 Roll immunity to long stagger

| | |
|---|---|
| Kind | tuning |
| Pillars | P9 |
| 5.x class | clean |
| Flags | — |
| Depends on | — |
| Skill trees | n/a |
| Port form | `@wrapMethod(CR4Player) SetIsCurrentlyDodging`, in `defense/dodge.ws` |
| Port status | signed off |
| Open checks | a long stagger hitting a real roll |
| Save impact | none (expected) |
| NG+ counterpart | none |

**What it does:** "Rolling grants immunity to all knockdown and stagger effects": vanilla already blocks knockdowns and staggers while rolling; Ghost Mode adds long stagger.

**Implementation (legacy):** `CR4Player.SetIsCurrentlyDodging` adds and removes the `'Roll'` immunity to `EET_LongStagger` with the others. 5.x's function is unchanged.

**Decisions:** port as legacy.

**Slices:**

1. **Long stagger immunity.** Verified 2026-10-04 (`gmtest_def03`, scripted dodge state; in `gmtest_regress()`): immune to long stagger while rolling, not while dodging without rolling; removed when the roll ends.

### DEF-04 Ciri's dodge

| | |
|---|---|
| Kind | system |
| Pillars | P9 |
| 5.x class | clean |
| Flags | — |
| Depends on | DEF-01 |
| Skill trees | n/a |
| Port form | `@addMethod(W3ReplacerCiri) GMCiriDodgeDamage`, called from DEF-01's dodge check; in `defense/dodge.ws` |
| Port status | signed off |
| Open checks | real dodges as Ciri against real attacks; her stamina gain on a dodge (needs her blink or charge ability, which the test save's Ciri lacks; vanilla's rule, unchanged) |
| Save impact | none (expected) |
| NG+ counterpart | none |

**What it does:** not in the changelist. Ciri dodges any dodgeable attack whatever the angle (vanilla: under 150°); a dodged hit also clears its effects and plays no hit animation.

**Implementation (legacy):** `W3ReplacerCiri.ReduceDamage` renamed `DodgeDamage` (called before damage, DEF-01), the 150° angle check removed, `ClearEffects` and no hit animation added; she gains stamina as in vanilla (`GainResource`).

**5.x:** Ciri's code is unchanged from 1.32.

**Decisions:** port as legacy (legacy behaviour first), though unannounced. Vanilla's check in `W3ReplacerCiri.ReduceDamage` stays but no longer sees a hit while dodging a dodgeable attack: those are all dodged before the damage step.

**Slices:**

1. **Ciri's dodge.** Verified 2026-10-04 (`gmtest_def04`, playing as Ciri through vanilla's `Ciri()` console command, scripted hits from a spawned wolf, her dodge state set by script): dodged at 0°, 145° and 170° with no damage and no effects; an undodgeable attack and a hit while not dodging hit.

### DEF-05 Parrying rules

| | |
|---|---|
| Kind | system |
| Pillars | P9 |
| 5.x class | conflict |
| Flags | balance |
| Depends on | STAM-03 (parry costs, partial parry without stamina) |
| Skill trees | both: Deflection (`sword_s10`, classic) reduces the partial-parry share; new tree: Deflection `sword_s33`, legacy's ([SKL-05](skl.md#skl-05-defense-branch)) |
| Port form | Share: `W3GameParams` defaults `PARRY_STAGGER_REDUCE_DAMAGE_LARGE`/`SMALL` 0.5 (scope block in `stamina/staminaCosts.ws`); partial parry, and parried attacks that knock down or stagger: `@replaceMethod(W3DamageManagerProcessor) ProcessAction` with legacy's block (`defense/processAction.ws`) and their zero damage in DEF-01's `W3PlayerWitcher.ReduceDamage` replacement (`defense/dodge.ws`); the stagger of a parry without stamina: `@wrapMethod(W3DamageManagerProcessor) ProcessActionBuffs` (`defense/parry.ws`); parry check: STAM-03's `@replaceMethod(CR4Player) PerformParryCheck` (`stamina/parryStamina.ws`) |
| Port status | signed off |
| Open checks | a real parry of a real attack that cannot be parried (scripted only); Ciri parrying an attack that cannot be parried and knocks down or staggers (her `ReduceDamage` is not changed: such hits keep vanilla's damage); the fistfight parry cost (needs a fistfight minigame); legacy's actual behaviour in four cases ([to test in legacy](../open-questions.md#to-test-in-legacy-ghost-mode)) |
| Save impact | none (expected) |
| NG+ counterpart | none |

**What it does:** "parrying at attack reduces the damage to zero and prevents all the negative effects"; a heavy attack without knockdown is parried partially: 50% damage, no bleeding, a short stagger (vanilla: a long stagger, and a share of 30% or 60% of the damage by the attacker's size); an attack that cannot be parried and knocks down or staggers (knockdown, heavy knockdown, stagger, long stagger, knockdown applicator) is parried for no damage, but its effects apply; a parry with too little stamina becomes partial (STAM-03) and staggers; no attacker breaks through a parry streak (vanilla: every 3rd parry in a row against an attacker with `BreakThroughParryOnHit`, in 5.x the sq703 panther, staggers); a parry in a fistfight minigame costs the normal parry cost (vanilla: the attacker's `stamina_damage`).

**Implementation (legacy):** `CActor.ReduceDamage` (the partial share, `PARRY_STAGGER_REDUCE_DAMAGE` 0.5 in `W3GameParams`, less with Deflection: SKL; `CanBeParried` dropped from the parry branch, so a parried hit that is not a partial parry takes no damage), `ProcessAction` (legacy's block replaces vanilla's: partial parry for an attack that cannot be parried or a parry without stamina, unless the attack knocks down or staggers; stagger instead of long stagger; partial counter, DEF-06), `PerformParryCheck` (removed break-through stagger and fistfight stamina damage; an armed Geralt's parry of an unarmed attacker fails, see Decisions). The removed deadly-level gate in `TestParryAndCounter` is already in 5.x; the removed parry-fail chance reads an attribute no 5.x data defines (no-op).

**5.x:** the parry functions are unchanged or changed elsewhere; 5.x still gives the long stagger. STAM-03's replacement of `PerformParryCheck` kept vanilla's fist-parry and break-through lines, so DEF edits that replacement.

**Decisions:** port as legacy. The partial parry is legacy's block, in a replacement of `ProcessAction` (5.x's body with vanilla's block swapped for legacy's, adapted to 5.x's three extra bleeding types). The project owner's rule (2026-10-03) was a wrapper first, `ProcessAction` replaced only if that fails; a wrapper could not carry legacy's rule for attacks that knock down or stagger (2026-10-04): vanilla's block would still mark such hits as partial parries and add a long stagger. The 50% share replaces the size-based shares by setting both vanilla constants to 0.5 (a default-value change; `CActor.ReduceDamage` is not replaced). The zero damage of a parried hit that is not a partial parry, which legacy got by dropping `CanBeParried` from `CActor.ReduceDamage`, is set in DEF-01's replacement of `W3PlayerWitcher.ReduceDamage`, after `CActor`'s; Ciri's is not changed. A wrapper of `ProcessActionBuffs` puts the stagger of a parry without stamina on Geralt directly, so the attack's other effects stay blocked. Legacy's actual behaviour in the cases below is to be [tested in legacy](../open-questions.md#to-test-in-legacy-ghost-mode).

- **Deviation:** a parry without enough stamina of a parryable attack (STAM-03) staggers. Legacy added the stagger, but vanilla's `ProcessActionBuffs` applies no effect of a parried hit of a parryable attack, in legacy too, so it never applied: a defect against the changelist's partial parry (project owner, 2026-10-04).
- **Deviation:** parrying an unarmed attacker with a weapon stays vanilla: the punch bounces off, no damage, no stamina. Legacy's code makes that parry fail (the attacker recoils, Geralt takes the punch and pays the parry); its comment describes the opposite case (an unarmed Geralt parrying a weapon), which vanilla's `FistFightCheck` already refuses, so the change looks like a misreading, and the changelist does not mention it (project owner, 2026-10-04).

Legacy's code for an attack that cannot be parried and knocks down or staggers (no partial parry; no damage; its effects apply, since `ProcessActionBuffs` exempts only parryable attacks and attack actions keep "apply effects without damage" on) is ported as it is (project owner, 2026-10-04). The changelist leaves knockdown attacks open ("heavy attacks that don't have knockdown effect … can be parried partially").

**Slices:**

1. **Partial parry: share and stagger.** Verified 2026-10-04 (`gmtest_def05`, scripted hits from a spawned wolf through the damage manager, parry flag and stamina set by script): a parried hit takes no damage and no effects; a parried attack that cannot be parried, or a parry without stamina, lets 50% through and staggers briefly, no long stagger, no bleeding. In a real fight (`gmtest_stam03_parry_a/b`, real wolf bites on a guarding Geralt): at 0 stamina partial parries, 50% and staggered; at full stamina full parries.
2. **Parry check.** No break-through stagger; a fistfight parry costs the parry cost. Verified 2026-10-04 (`gmtest_def05_parry`, scripted: the ability added to a spawned wolf, the defend counter set to 3, `PerformParryCheck` called as a hit calls it): parried, no stagger, the parry cost paid. The fistfight cost is from code reading.
3. **Legacy's block; knockdown and stagger attacks.** Legacy's parry and counter block in the `ProcessAction` replacement. Verified 2026-10-04 (`gmtest_def05`, `gmtest_def06_hit`, scripted hits as in slice 1): parried or countered, a long-stagger attack and a knockdown attack take no damage, are not partial, and their effect applies; in a real fight (`gmtest_stam03_parry_a/b`) partial and full parries as in slice 1.

### DEF-06 Counters and partial counters

| | |
|---|---|
| Kind | system |
| Pillars | P9 |
| 5.x class | conflict |
| Flags | — |
| Depends on | STAM-03 (counters need stamina), DEF-05 |
| Skill trees | both: Counterattack (`sword_s11`, classic); new tree: `sword_s31`, legacy's ([SKL-05](skl.md#skl-05-defense-branch)); the repel and AI rules involve no skill |
| Port form | `@replaceMethod(CR4Player) PerformCounterCheck` on the 5.x body (`defense/counter.ws`; STAM-03's stamina wrapper stays); partial counter, no effects on a counter and DEF-07's countered mark: DEF-05's `ProcessAction` replacement (`defense/processAction.ws`); the 1 s stun: DLC XML `extend` of `CounterStrikeHitEffect` (`gm_defense.xml`, and its NG+ copy); the tournament contestants: `GMIsTournamentContestant` (same file); stunned or countered enemies: wrappers of `CBTTaskDodge`, `CBTTaskCircularDodge`, `CBTTaskPerformParry` and `CBTTaskReaction` (`defense/enemyDefense.ws`) |
| Port status | signed off |
| Open checks | a real counter (scripted counter checks only); the kick down a slope stunning; a real dodge suppressed by a counter (the test bandit never dodged, marked or not); legacy's behaviour in two cases ([to test in legacy](../open-questions.md#to-test-in-legacy-ghost-mode)) |
| Save impact | none (expected) |
| NG+ counterpart | applied and scaled, untested |

**What it does:** "all the light attacks can be countered"; a counter no longer depends on whether the attack can be parried, and countering an attack that cannot be parried is a partial counter (the partial-parry share, no effects), unless it knocks down or staggers (no damage, its effects apply); the countered enemy is stunned for 1 s (vanilla 0.5 s); reworked repel animations (the Grave Hag's special repel only against her tongue, a side-step against two-handed and tournament fighters); while stunned by a counter or within 3 s of being countered, an enemy does not dodge, and while stunned it does not parry or react with a dodge.

**Implementation (legacy):** `CR4Player.PerformCounterCheck` (no `canBeParried`/`CannotBeCountered` gate; repel rework: the Grave Hag's special repel only against her tongue, two-handed and tournament fighters side-stepped, the slope kick stuns; Counterattack, Mutation 8, the Lynx set and Perk 21 reworked there too: other areas; the counter's stamina, STAM-03), `ProcessAction` (partial counter: the partial-parry share and `ClearEffects`, unless the attack knocks down or staggers; DEF-05's block), `effects.xml` (`CounterStrikeHitEffect` 0.5 → 1 s), `W3Effect_CounterStrikeHit.CacheSettings` (roll, sprint, dodge blocked: no effect, see Decisions), the tournament contestants' `.w2ent` files and their marker ability, and the defence tasks (`btTaskDodge`, `btTaskPerformParry`, `btTaskReaction`: no dodge, parry or reaction while stunned or countered). `TestParryAndCounter` also counts counters of attacks that cannot be parried toward the counter achievement.

**5.x:** `PerformCounterCheck` gained `ProcessSpearDestruction()`: countering a two-handed spear now breaks it (in 1.32 the branch only sent a signal few enemies handled).

**Decisions:** port as legacy, including the dropped `CannotBeCountered` check: enemies that carry that ability (e.g. sq701's Gregoire, the barrens ghost) become counterable (project owner, 2026-10-03). A counter costs the same against any attack (STAM-03's part of legacy's change; project owner, 2026-10-04). Legacy also added rolling, sprinting and dodging to the stun's blocked actions (`W3Effect_CounterStrikeHit.CacheSettings`); not ported, as it changes nothing: blocked actions are the player's input blocks, applied only when the effect is on the player, and the counter stun is only ever put on enemies. What keeps a stunned or countered enemy from dodging or parrying is legacy's AI tasks (`btTaskDodge`, `btTaskPerformParry`, `btTaskReaction`), ported with DEF; `btTaskDodge` reads DEF-07's "was countered" flag (project owner, 2026-10-04). The tournament contestants are recognised by their entity templates (12 of the 14 in `sq701_tournament\characters\contestants\`, the ones legacy marked; not Horm with a bow nor Rainfarn with a shield), where legacy gave them an empty marker ability `sq701_tournament_npcs` by editing their 12 `.w2ent` files: same behaviour, no binary edit or mounter (no vanilla DLC adds abilities with `CR4EntityTemplateParamDLCMounter`), and portable to loose scripts. A partial counter clears every effect, a knockdown applicator included, where a partial parry keeps it (legacy's code; the counter's "prevent all negative effects"); attacks that knock down or stagger are not countered partially (no damage, their effects apply), as DEF-05. The changelist contradicts itself on partial counters: "you will still get damage and all the negative effects" (Defense skill description) against "partial counters work the same as partial parries"; the port follows legacy's code. Legacy's guard against a dodge reaction while stunned in `CBTTaskReaction.ChooseAndCheckDodge` relies on legacy's fix of `CBTTaskReaction.Main`, which in vanilla, and in 5.x, starts a dodge when that check answers no; AI ported both together ([AI-09](ai.md#ai-09-dodging), `ai/dodge.ws`). The event that arms the reaction is still ignored while stunned. The parry and reaction checks while stunned look redundant (the AI runs no combat tasks in that state); kept, as legacy. The second deviation below is on the list [to test in legacy](../open-questions.md#to-test-in-legacy-ghost-mode).

- **Deviation:** 5.x's spear break is kept: countering a two-handed spear breaks it. Legacy removed the branch as "not working anyway", which 5.x fixed (project owner, 2026-10-04).
- **Deviation:** a counter blocks all of the attack's effects. Vanilla's code, and legacy's, applied them although the hit dealt no damage: a defect against the changelist's "prevent all negative effects" (project owner, 2026-10-04).
- **Deviation:** counters of attacks that cannot be parried do not count toward the counter achievement and Learning the Ropes (vanilla's `TestParryAndCounter`); legacy counted them (porter's call, confirmed by the owner, 2026-11-02).
- Legacy's Lynx set change here (a kick or bash counter keeps the chain going) is ported with ARM-06 (2026-10-17). Perk 21's counter stamina is ported (SKL-18, 2026-10-15); Mutation 8 first in the repel order with MUT-06 (2026-10-17).

**Slices:**

1. **Counter check.** Verified 2026-10-04 (`gmtest_def06`, `gmtest_def06_repel`; scripted counter checks with the counter window set by script, against a spawned wolf, bandit and Grave Hag): counters regardless of parryability and `CannotBeCountered`; the hag's special repel only against her tongue; two-handed fighters side-stepped; the counter cost the same against any attack. Not tested: a real counter, the slope kick.
2. **Partial counter; a counter blocks all effects.** Verified 2026-10-04 (`gmtest_def06_hit`, scripted hits with the countered flag): countered, no damage and no effects; a partial counter 50%, no stagger, no bleeding. Attacks that knock down or stagger: DEF-05's slice 3.
3. **1 s stun.** Verified 2026-10-04 (`gmtest_def06_stun`, scripted: the stun added to a spawned wolf and a bandit as a counter adds it): it lasts 1 s. NG+ copy untested.
4. **Tournament contestants.** Verified 2026-10-04 (`gmtest_def06_contestant`, each of the 14 templates spawned hostile, scripted counter check): the 12 contestants are side-stepped, also the six without `SkillTwoHanded`; Horm with a bow and Rainfarn with a shield are not.
5. **Stunned or countered enemies.** Verified 2026-10-04 (`gmtest_def06_ai_a/_swing/_b`, probes on the real AI's task calls; a spawned bandit marked countered by script before each real light attack): every dodge request while countered was refused. Not shown: that it would have dodged otherwise (the bandit never dodged, marked or not).

### DEF-07 Counter bonuses

| | |
|---|---|
| Kind | system, tuning |
| Pillars | P9 |
| 5.x class | clean (attack type, XML); overlap (counter tracking) |
| Flags | balance |
| Depends on | DEF-06 |
| Skill trees | both: classic Muscle Memory `sword_s21` (tag and per-level share) and Precise Blows `sword_s17` (crit, via `IsLightAttack`); new tree: via `IsLightAttack`, 5.x's combo skills `sword_s22`, `sword_s24` and `sword_s23`'s counter part (`ProcessNewSkills_Combat`; SKL replaces them, [SKL-03](skl.md#skl-03-fast-attack-branch)); `IsLightAttack` also lists the new tree's Whirl `sword_s35`; `S_Sword_s31` (new) reads vanilla's counter flag |
| Port form | DLC XML `replace` of `counter_attack_light` and `extend` of `sword_s21`'s tags (`gm_defense.xml` and its NG+ copy); `@wrapMethod(CR4Player) IsLightAttack` and `@wrapMethod(W3Action_Attack) GetPowerStatValue`; the per-enemy flag: `@addField`/`@addMethod(CActor)` (a deadline in engine time), set and cleared in DEF-05's `ProcessAction` replacement (`defense/processAction.ws`); `@wrapMethod(W3PlayerWitcher) GetCriticalHitChance` (all in `defense/counter.ws`) |
| Port status | signed off |
| Open checks | a real counter's damage and crit chance (scripted read-backs only); the new tree's Muscle Memory's attack power on a counter (counters are light attacks; still unchecked by test, the checks ran with classic or no skills); legacy's behaviour with Muscle Memory ([to test in legacy](../open-questions.md#to-test-in-legacy-ghost-mode)) |
| Save impact | none (expected) |
| NG+ counterpart | applied and scaled, untested |

**What it does:** "counter is now considered a light attack, so all the light attack bonuses apply"; counters are not damage-reduced (vanilla −75% attack power) and the countered enemy takes +25% critical chance from the player's next hit within 3 s.

**Implementation (legacy):** `basic_attacks.xml` (`counter_attack_light` without its −75% attack power), `CR4Player.IsLightAttack` (counters and the special light attack), a per-enemy flag on `CActor` (`WasCountered`, 3 s timer) set when Geralt counters (`ProcessActionReaction`) and cleared by his next hit (`ProcessAction`), and +25% crit on melee attacks against a countered enemy (`ProcessCriticalHitCheck`). Legacy removed vanilla's "recently countered" flag on Geralt and moved its readers (Counterattack, Mutation 8) to the per-enemy flag; the changelist's bug fixes "recently countered flag never being reset if your counterattack missed" and "countering multiple enemies simultaneously where only the first counter was considered" come from that.

**5.x:** unchanged except that `IsLightAttack` gained 5.x's `sword_s35`, and 5.x's new `S_Sword_s31` reads vanilla's "recently countered" flag, which legacy removed.

What "all the light attack bonuses" covers: the bonuses that ask `IsLightAttack` of the attack name (light-attack crit chance including Precise Blows `sword_s17`, the Lynx set, the light-attack combo skills, Aerondight), and a light attack's attack power bonuses, which vanilla gives in two shares: the abilities tagged `attack_light` (Muscle Memory `sword_s21`), and, for a light attack type, Muscle Memory per level again plus `attack_power_fast_style` (the new tree's light-attack perks). A counter has neither the tag nor an attack type (`IsBasicAttack` knows only light, heavy, super-heavy and speed-based attacks), so in legacy's code Muscle Memory and the perks did not reach it; the ported code gives counters Muscle Memory's attack power once, as every fast attack (SKL's D47), and keeps them distinguishable from light attacks (own name, tag and empty attack type). Legacy also removed the style bonuses (`attack_power_fast_style`, `attack_power_heavy_style`) for every attack. SKL did the same by replacing the new tree's light- and heavy-attack perks (`perk_5`, `perk_23`, `perk_27`; `perk_7`, `perk_25`) without them, so no ability in the port grants `attack_power_fast_style`: the counter's share of it in `defense/counter.ws` is 0, as in legacy, and the wrapper stays, commented, in case one ever grants it (whole-port audit A1-4).

**Decisions:** keep vanilla's flag (5.x's skills need it) and add Ghost Mode's per-enemy flag beside it (an implementation difference only; behaviour as legacy). The flag is a deadline in engine time (3 s), so it needs no timer function and is not saved (legacy's timer; same behaviour). Vanilla's flag keeps the two bugs the changelist lists as fixed (not reset after a missed counter; only the first of several simultaneous counters counted); they now touch only what still reads it: 5.x's `S_Sword_s31` (Counterattack reads the enemy's flag since SKL-05, Deadly Counter since MUT-06).

- **Deviation:** the +25% crit goes to the player's light and heavy attacks, not to melee attacks that are neither (e.g. `attack_super_heavy`, `attack_speed_based`); legacy gave it to every melee attack action. The crit function is asked with neither light nor heavy for bolts, signs and other actions too, so the wrapper cannot tell the rest apart (porter's call, confirmed by the owner, 2026-11-02).

- **Deviation:** a counter gets a light attack's attack power bonuses (Muscle Memory; the light-attack perks' style bonus no longer exists), as the changelist says; legacy's code gave it neither. Since SKL-03 ported D47 (2026-10-14), a counter gets Muscle Memory's attack power once, as every fast attack does. Counters stay distinguishable from light attacks, for later counter-only rules (project owner, 2026-10-04, revised 2026-10-11).

**Slices:**

1. **A counter is a light attack.** Verified 2026-10-04 (`gmtest_def07`, scripted read-backs of attack actions built as real attacks build them): `IsLightAttack` true for a counter and the special light attack, false for a heavy attack; a counter's base attack power equals a light attack's (vanilla a quarter); Muscle Memory raises both alike.
2. **Countered enemies: +25% crit.** Verified 2026-10-04 (`gmtest_def07_flag`, `gmtest_def07_flag_b`, scripted countered hit and crit read-backs): the countered enemy is marked, vanilla's flag still set; crit chance against it +25%, none for bolts or other actions; Geralt's next hit uses the mark up; it expires after 3 s. In `gmtest_regress()`.

### DEF-08 Arrow parry

| | |
|---|---|
| Kind | system |
| Pillars | P9 |
| 5.x class | rethink |
| Flags | — |
| Depends on | SKL (Deflection, 5.x's `S_Sword_s33`) |
| Skill trees | both: classic Deflection `sword_s10`, new `S_Sword_s33` |
| Port form | `@replaceMethod(W3ArrowProjectile) OnProjectileCollision` on the 5.x body (`defense/arrowParry.ws`); DEF-08's change is the ungated parry line; FIX-01, FIX-02, ENCH-11 (which removed 5.x's Deflection branch in front of the parry) and ARM-01 changes in the same body are marked with their IDs |
| Port status | signed off |
| Open checks | a real perfectly timed parry press reflecting an arrow with Deflection, either tree (SKL-05 verified it with scripted reflected-arrow hits; real arrows were reflected with a parry press stamped by script at impact, in both trees, by [ENCH-11](ench.md#ench-11-deflection-glyphword-1) slice 2, 2026-10-19) |
| Save impact | none (expected) |
| NG+ counterpart | none |

**What it does:** "Arrows can be parried": with the guard up, arrows are always parried (vanilla needs Deflection); Deflection reflects them from its first level (vanilla: second). With STAM-03, an arrow parry costs stamina and, without stamina, still parries fully (arrows have no partial parry).

**Implementation (legacy):** `W3ArrowProjectile.OnProjectileCollision`: the parry branch without its Deflection gate, reflection from Deflection's first level (vanilla: second), Deflection's level-3 damage moved to the damage manager (SKL); the same function also carries collision fixes (FIX), Glyphword 1 (ENCH) and the sq108 bounce ability.

**5.x:** redesigned: parrying arrows needs Deflection or the new `S_Sword_s33`, with its own deflection path and deflectable boulders.

**Decisions:** legacy's ungated arrow parry on 5.x's function (project owner, 2026-10-03): with the guard up anyone parries arrows; Deflection is legacy's in both trees, reflection from level 1 (SKL-05, D5 and D6, 2026-10-14). The parry goes through Geralt's parry check, so it costs stamina (STAM-03) and, without stamina, still parries the arrow in full (no partial parry for arrows), as legacy. 5.x gives Perk 31's adrenaline for every arrow parry (`GainAdrenalineFromPerk31('parry')`, new tree); with the gate gone that now happens without Deflection or `S_Sword_s33` too (Perk 31 is SKL's).

**Slices:**

1. **Arrows parried with the guard up.** Verified 2026-10-04 (a spawned enemy archer's real arrows; Geralt guarding by script, no Deflection nor `S_Sword_s33`; `gmtest_stam03_parry_a/b`): with stamina, arrows parried for their stamina cost and no damage; at 0 stamina still parried, no damage, no stagger.
