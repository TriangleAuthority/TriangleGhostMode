# EFX: generic effects (damage over time, critical effects, freezing, slowdowns)

The effects every source shares: bleeding, poison, burning, freezing, knockdown and stagger, hypnosis, frost slowdown, blindness, confusion, and the Places of Power's sign buffs. Whatever applies them (a sword, a sign, a bomb, a monster), their strength, length and rules live in `effects.xml` and the effect classes, which is what this area covers. Ghost Mode's changelist (847–859): "Damage over time (DoT) effects reworked to deal approximately the same amount of total damage. Bleeding effect: -1% hp/sec for 8 seconds, blocks hp regen. Bleeding effect from tracking bolt: -0.5% hp/sec for 16 seconds … Burning effect: -2.7% hp/sec for 3 seconds, blocks hp regen, stunlocks. Poison effect: -1.6% hp/sec for 5 seconds … Frozen effect now also pauses all DoT effects. … Enhanced Sign effects: 30 min duration, +20% to corresponding Sign Intensity"; the bugfix list (173: "DoT effects being able to continue indefinitely if the corresponding critical state animation is interrupted incorrectly"; the spider web aborting signs; Northern Wind); the Enemy AI section ("Killing a frozen rotfiend now prevents the explosion"). Sources: those lines, every hand-off to EFX ([hand-offs received](#hand-offs-received)), and the code, which has more than the changelist (the frozen hit, the damage-over-time ticks, the frost slowdown's resistance).

**What 5.x did in this area** (from `vanilla-5.x`, unverified in game). The effect values are 1.32's. Burning changed: a burning enemy (not Geralt) plays no hit reaction for the first half of its burning (1.5 s of 3 s), so its burning stun cannot be interrupted by hits (`W3Effect_Burning.CacheSettings` and `OnUpdate`, `allowedHits`); Ignition (Glyphword 12) spreads without its chance roll (ENCH-13, ported). Bleeding gained three extra types (`EET_Bleeding1` to `3`) for the Wolven set's wound stacks, which the port removed (ARM-09): they are inert. Bomb damage over time grew with potion duration (removed by ALCH-14, DL7). The fiend's hypnosis lasts 20 s by default (1.32: 7 × its loop time; AI's). The rest of the effect classes, the frozen hit (a knockdown applicator and a separate frost hit; the latter removed by ALCH-14), the knockdown, stagger and ragdoll timing and the damage-over-time ticks are 1.32's. The Places of Power's buffs are 1.32's (+20% sign intensity for 30 min); 5.x only counts them for an achievement and has a dead `perk_36` branch (Gorged on Power's longer and stacking buffs: its ability is in `geralt_skills.xml`, but its `<skill>` entry is commented out, so neither tree offers it).

**How legacy Ghost Mode implements it.** Data: seven abilities of `effects.xml` (bleeding, the two bolt bleedings, critical poison, the generic freeze, hypnosis, frost slowdown), regular and NG+ (equal), and one NG+-only effect entry (immobilized). Scripts: the frozen effect and two new effect-manager methods (damage over time paused while frozen), the damage-over-time effect's tick (`CalculateDamage`, `OnUpdate`), the end of critical effects (`OnTimeUpdated` of the critical, critical damage-over-time, knockdown, heavy knockdown and ragdoll effects), the frost slowdown's resistance, the spider web's sign abort, the frozen-hit rules in `ProcessDamageIncrease`, the frozen rotfiend (`CActor.OnTakeDamage`, `CActor.ReduceDamage`, `ProcessInstantKill`, `BTTaskExplodeAtDeath.Explode`), the resistance point names (`ResistStatNameToEnum`, `ResistStatEnumToName`), a debug log (`toggledebugdot`).

Unit lists: [attribution.csv](attribution.csv): mapped 2026-10-24 from the changelist, every hand-off to EFX, a field-by-field comparison of every effect ability and effect entry legacy changed in `effects.xml` (master against `legacy-GM` and `vanilla-5.x`), every unit in `scripts/game/gameplay/effects/`, and sweeps (`unit_sweep.py --unattributed` for knockdown, stagger, bleed, poison, burning, frozen, frost, confus, hypnot, blind, slowdown, DoT, critical, severity, ragdoll, tangle, immobil, shrine, `EET_`, the effect ability names, immunity, pause and resume, `AddEffect*`): **42 units** carry an EFX feature (27 script units, 6 of them shared with DMG, STAM, SKL, MUT, ARM, ENCH, ALCH and SWD features in the damage functions; 7 XML units and their 7 NG+ copies; 1 NG+-only entry). The mapping also attributed eight units to the features that already port them (the blindness crit bonus to ALCH-14, the Elemental decoction's resistance block to ALCH-13, the Axii slowdown class to SKL-12, the negative-immunity removal to SKL-07, the finisher event to SKL-08). Units that only look like effects but belong elsewhere (monster resistances and projectiles, bolts, trophies, NPC weapons' frost slowdown) are handed off ([hand-off](#hand-off-to-other-areas)). Port status: **mapped** (2026-10-24); the owner's area decisions made (2026-10-24); EFX-12 and EFX-13 dropped; the port in progress ([port order](#port-order)): slice 1 (EFX-01, EFX-05's data) **verified** in both trees (2026-10-24, 5.x-GM `6317278f`; regression 861 passed, 0 failed in each tree); slice 2 (EFX-02, EFX-03) **verified** in both trees (2026-10-24, 5.x-GM `87a6a97a`; regression 867 passed, 0 failed in each tree); slice 3 (EFX-04, EFX-06) **verified** in both trees (2026-10-24, 5.x-GM `361dcc86`; regression 873 passed, 0 failed in each tree); slice 4 (EFX-07) **verified** in both trees (2026-10-24, 5.x-GM `3fdaad99`; regression 873 passed, 0 failed in each tree); slice 5 (EFX-08) **verified** in both trees (2026-10-24, 5.x-GM `d804603d`; regression 885 passed, 0 failed in each tree); slice 6 (EFX-09) **verified** in both trees (2026-10-24, 5.x-GM `2a8b70b4`; regression 885 passed, 0 failed in each tree); slice 7 (EFX-10, EFX-11) **verified** in both trees (2026-10-24, 5.x-GM `cc824c9a`; regression 895 passed, 0 failed in each tree). **EFX is ported** (EFX-01 to EFX-11; EFX-12 and EFX-13 dropped); **audited** 2026-10-24 ([EFX audit](#efx-audit-2026-10-24): 5 findings, every one fixed or recorded, no owner decision: [close-out](#audit-close-out), fix slice A in 5.x-GM `95ce014f`); **signed off** by the project owner (2026-10-25).

## Scope

**EFX covers** the generic effects' values (bleeding, critical poison, the generic freeze, hypnosis, frost slowdown), the frozen hit (its bonus, no knockdown, Aard's force damage), damage over time paused while frozen, the damage-over-time tick, the end of critical effects, burning against hits, the effect resistance point names, the frozen rotfiend, the spider web, the Places of Power, the damage-over-time debug log, the NG+ immobilized entry.

**Already ported by other areas** (nothing left for EFX; the hand-offs naming them close here):

| Subject | Ported by | What |
|---|---|---|
| Knockdown and stagger severity, low stamina raising it | SKL-08 (signed off) | Legacy's knockdown roll for every source and `ModifyKnockdownSeverity` (one step up below 30% stamina, two below 10%; shields, huge monsters, immunities, contract monsters), `skills/aard.ws`; closes STAM's and SKL's severity hand-offs |
| Heavy knockdown 5 s, only heavy knockdowns allow finishers | SKL-08 | `HeavyKnockdownEffect`, `CBehTreeTaskCSEffect` |
| Firestream's burning (2.7% for 3 s), the slowdown defaults (35%, 7.5 s) | SKL-09, SKL-10 | `gm_effects.xml` |
| Confusion: 3 s minimum, +25% crit chance against the confused | SKL-12 | `ConfusionEffect`, `W3ConfuseEffect`; the crit term is read with blindness's in `GetCriticalHitChance` (`skills/oils.ws`): the larger of the two, as legacy |
| Blindness: crit chance against a blinded enemy (Samum +50/75/100%), its ability kept off the victim | ALCH-14 | `GMBlindnessCritBonus`, `W3BlindnessEffect` (`alchemy/bombs.ws`); the generic blindness (3 s) is 1.32's in all three |
| Northern Wind's freeze bonus (+25/35/50%) as a pool term, 5.x's separate frost hit removed | ALCH-14 (audit F2) | `damage/pool.ws`; the knockdown's removal and Aard's force damage came with EFX-02 |
| Bomb burning and poison (1% per tick), no potion-duration bonus to bomb damage over time | ALCH-14 (DL7) | `effects.xml` bomb abilities, `W3DamageOverTimeEffect` and `W3CriticalDOTEffect.OnEffectAdded` |
| Heavy Artillery doubling only a damage over time's flat part | SKL-18 | `W3DamageOverTimeEffect.OnEffectAdded` |
| Crippling Strikes' bleeding (1% of max health per second for 8 s, resisted by bleeding resistance) | SKL-03 | `skills/cripplingStrikes.ws`, from the skill's own values (not `BleedingEffect`) |
| Damage over time: no crits, no attack power, armor points ignored | DMG-02, DMG-03 | `damage/formula.ws`, `ProcessCriticalHitCheck` |
| Effect chances resisted (non-sign sources), effect durations not scaled by power | MUT-13, DMG-07 | `GetNonSignApplyBuffTest`, `CalculateDuration` |
| Ignition spreading the default burning | ENCH-13 | `W3Effect_Burning.OnUpdate` |
| Enhanced armor and weapon (Armorer's Table, grindstone: 30 min, +5% resistances; 10 armor penetration, +5%) | ITEM-12 | changelist 857–858 |
| Hypnosis immunity from Cat 3 | ALCH-07 | `W3Effect_Hypnotized.OnUpdate` |

**Not EFX** (confirmed by the owner with DX4, 2026-10-24):

| Subject | Area | Why |
|---|---|---|
| Which weapons and attacks carry an effect and with which chance: NPC weapons (Wild Hunt frost slowdown, bugfix 75), monster projectiles (`advancedProjectile.ws`: effect lengths 2 → 3 s), ice spikes, monsters' effect resistances, the fiend's hypnosis length | AI | Enemy data; EFX sets what the effects do once applied |
| Bolts' effect chances (blunt knockdown, broadhead and tracking bleeding, explosive burning) | XBOW | The bolts; their bleeding abilities are EFX-01's |
| Trophies' effect resistances | TRPH | |
| Deadly enemies' blindness immunity | DIFF | Removed with the deadly-enemy bonuses |
| Hit reactions' severity (`ModifyHitSeverityReaction`, `ModifySeverity`: legacy no longer reduces hit reactions by `hit_severity`) | AI | Poise, with DMG's hand-off of the hit-severity half of `ModifyHitSeverityReactionFromDamage` |
| The rotfiend explosion's damage (weapon damage, 300 if none) and the instant kill's cap (`GetLastBreathMaxAllowedDamage`) | AI | EFX-09 takes only the frozen exception |
| Releasing the sign-select keys when caught in a web (`ForceDeactivateCastSignHold`) | OPT (instant casting) | Legacy's instant-casting option |
| Over-encumbrance blocking fast travel, the boat sinking | WGT | |
| Geralt's base Vitality regen and its options (`W3Effect_AutoVitalityRegen`) | OPT, GEN | As FOOD recorded |

## Changes at a glance

### What Ghost Mode changed

| # | Feature | Vanilla 1.32 | Legacy GM | Units (main) |
|---|---|---|---|---|
| EFX-01 | Damage-over-time values | Bleeding 0.8% for 10 s; tracking bolt 0.1% for 30 s; broadhead bolt 10 + 0.1–0.2% for 10 s; critical poison 2% for 5 s | Bleeding 1% for 8 s; tracking 0.5% for 16 s; broadhead 1% for 8 s; critical poison 1.6% for 5 s (as plain poison); burning and poison unchanged (2.7% for 3 s, 1.6% for 5 s) | 4 abilities (and NG+) |
| EFX-02 | Hitting a frozen enemy | The breaking hit knocks down; the generic freeze 4 s, +0% | The breaking hit gets the freeze's bonus (generic +50%, 5 s) and no knockdown; Aard adds 5% of the victim's max health as force damage | `FrozenEffect`, `ProcessDamageIncrease` |
| EFX-03 | Freezing pauses damage over time | Bleeding, poison and burning keep ticking on a frozen enemy | They pause, and resume on thaw | `W3Effect_Frozen`, 2 new effect-manager methods |
| EFX-04 | Damage-over-time ticks | Hits Vitality and Essence as flagged, may tick 0 | Only the stat the target uses; at least 1 damage per second | `CalculateDamage` |
| EFX-05 | Frost slowdown and hypnosis | Frost slowdown 10 s, not resisted; hypnosis default 3 s | Frost slowdown 7.5 s, shortened by frost resistance; hypnosis default 5 s | 2 abilities (and NG+), `W3Effect_SlowdownFrost` |
| EFX-06 | Critical effects end on time | An expired critical effect waits for its animation to stop; an interrupted one could keep its damage over time running | It ends at its time; the animation stop is asked at removal | 8 `OnTimeUpdated`/`OnEffectRemoved`, `W3DamageOverTimeEffect.OnUpdate` |
| EFX-07 | Burning and hits | Any hit but Igni interrupts a burning enemy's stun, which ends its burning | Unchanged (a comment only) | — |
| EFX-08 | Effect resistance points | No point names for bleeding, will and burning resistance | Named (so their points count) | `ResistStatNameToEnum`, `ResistStatEnumToName` |
| EFX-09 | Killing a frozen rotfiend | Its death explosion goes off | A frozen hit kills it outright and the explosion deals no damage | 4 shared units |
| EFX-10 | Caught in a spider web | The sign being cast carries on | It is aborted | `W3Effect_Tangled.OnEffectAdded` |
| EFX-11 | Places of Power | +20% sign intensity, 30 min | The same (changelist 859 states vanilla's values) | — (comments only) |
| EFX-12 | Damage-over-time debug log | — | `toggledebugdot`, per-second log of each tick | 4 units |
| EFX-13 | NG+ immobilized look | NG+: Axii's stopping visual on immobilized | NG+ as the regular game (no visual) | 1 NG+ entry |

### What 5.x changed

| # | 5.x change (from code and data) |
|---|---|
| EFX-01 | None (1.32's values); three extra bleeding types for the Wolven set (inert since ARM-09) |
| EFX-02 | None to the rule (1.32's knockdown); the frost hit ALCH-14 removed |
| EFX-03, EFX-04, EFX-06, EFX-10 | None (1.32's code) |
| EFX-05 | None to the values; the fiend's hypnosis 20 s by default (AI) |
| EFX-07 | A burning enemy ignores hits' reactions for the first half of its burning |
| EFX-08 | None (1.32's names) |
| EFX-09 | Northern Wind blocks the rotfiend's `PoisonDeath` (kept by ALCH's DL7) |
| EFX-11 | An achievement counter; a dead `perk_36` branch (its skill entry commented out) |
| EFX-12, EFX-13 | None |

### Classification and proposed action

| # | Feature | Class | Proposed action |
|---|---|---|---|
| EFX-01 | Damage-over-time values | clean | Legacy's (porter's call PX1) |
| EFX-02 | Frozen hit | clean | Legacy's (DX2 (a)); ends ALCH-14's temporary deviation |
| EFX-03 | Frozen pauses damage over time | clean | Legacy's |
| EFX-04 | Ticks | clean | Legacy's |
| EFX-05 | Frost slowdown, hypnosis | clean | Legacy's (PX2, PX3) |
| EFX-06 | Critical effects end | clean | Legacy's (PX4) |
| EFX-07 | Burning and hits | overlap (5.x changed it) | 1.32's, as legacy played (DX1 (a)) |
| EFX-08 | Resistance points | clean | Legacy's (PX6); ends DMG-02's temporary deviation |
| EFX-09 | Frozen rotfiend | clean | Legacy's (DX3 (a)), with 5.x's Northern Wind block kept |
| EFX-10 | Spider web | clean | Legacy's (PX9) |
| EFX-11 | Places of Power | in-5.x | Nothing to port; a scripted check (PX7) |
| EFX-12 | Debug log | clean | Not ported (PX5) |
| EFX-13 | NG+ immobilized | clean (if a DLC can override an effect entry) | Dropped (PX8, owner, 2026-10-24) |

---

### EFX-01 Damage-over-time values

| | |
|---|---|
| Kind | tuning |
| Pillars | P8, P5 |
| 5.x class | clean |
| Flags | balance |
| Depends on | — (DMG-07: durations not scaled by power, signed off) |
| Skill trees | n/a |
| Port form | `BleedingEffect`, `BleedingTrackingEffect`, `PoisonCriticalEffect` in Ghost Mode's DLC `gm_effects.xml` (`on_conflict="extend"`, as SKL's effect values); `BleedingEffect_BroadheadBolt` given whole (`replace`: legacy removed 5.x's flat `DirectDamage` node); NG+ through `gen_ngplus.py` (vanilla's NG and NG+ values are equal, so the copies equal legacy's NG+ values) |
| Port status | **signed off** (2026-10-25); ported (slice 1, 2026-10-24, 5.x-GM `6317278f`), verified in both trees |
| Open checks | A real broadhead or tracking bolt and a real poison cloud not tested (scripted effects with the bolts' ability names; the bolts' chances are XBOW's) |
| Save impact | none (expected): effect abilities are read when an effect is applied |
| NG+ counterpart | applied (legacy's NG+ values), untested |

**What it does** (changelist 850–855): damage over time deals about the same total whatever the source, as a share of the victim's maximum health: bleeding 1% per second for 8 s (8%; 1.32: 0.8% for 10 s, 8%), a tracking bolt's bleeding 0.5% for 16 s (8%; 1.32: 0.1% for 30 s, 3%), a broadhead bolt's bleeding 1% for 8 s (1.32: a flat 10 plus 0.1–0.2% for 10 s), the critical poison (toxic clouds, gas, monsters' poison attacks) 1.6% for 5 s like the plain poison (1.32: 2%). Burning (2.7% for 3 s) and poison (1.6% for 5 s) are 1.32's. All of them block health regeneration, as in 1.32. Bleeding from swords, monsters and Crippling Strikes' own values (SKL-03, already legacy's) and the bolts' bleeding become comparable.

**Implementation (legacy):** the four abilities, regular and NG+.

**5.x:** 1.32's values. 5.x's `BleedingEffect1` to `3` (the Wolven set's wounds) use `BleedingEffect` as their default ability, so they would take the new values; nothing applies them since ARM-09 removed 5.x's Wolven rules.

**Decisions:** legacy's values (PX1, confirmed by the owner, 2026-10-24).

**Verification (slice 1, 2026-10-24, both trees):** scripted (`GMTest_efx01`, in the regression): the four abilities' values as above, the broadhead bolt's flat part gone (0), 5.x's other attributes kept by `extend` (the health regen block 200, 5 s), the plain poison (1.6%) and 5.x's unused `BleedingEffect1` ability untouched. In play (`gmtest_efx01_apply`, scripted effects with Geralt as creator on the neutral test dummy, a frozen bandit with 100000 health and no resistances; a timer read its health every 0.25 s): bleeding 1.0% of maximum health per second, active 7.8 s of 8, 8.01% in all; a tracking bolt's bleeding 0.5% per second, 16 s, 8.0%; a broadhead bolt's bleeding (`BleedingEffect_BroadheadBolt` named as the bolt names it) 1.0% per second, 8 s, 8.0%; the critical poison 1.6% per second, 8.0% over its 5 s. On the frozen dummy a critical effect (critical poison, hypnosis) outlasted its time: it waited for its animation to end, which never comes (1.32's end rule); since EFX-06 (slice 3) it ends at its time, and the same run checks that.

### EFX-02 Hitting a frozen enemy

| | |
|---|---|
| Kind | system, tuning, fix |
| Pillars | P5, P8 |
| 5.x class | clean |
| Flags | balance |
| Depends on | ALCH-14 (the pool term, signed off), DMG-04 (`damage/pool.ws`, signed off), MUT-04 (Piercing Cold freezes with the generic effect, signed off), SKL-08 (Aard, signed off) |
| Skill trees | n/a in the code (no skill read); Aard is the core sign of both trees and Piercing Cold a mutation of both, so the checks run in both trees |
| Port form | `FrozenEffect` in `gm_effects.xml` (`extend`: 5 s, `hpPercDamageBonusPerHit` 0.5), NG+ copy (`gen_ngplus.py`); in `ProcessDamageIncrease` (`damage/pool.ws`, already replaced): the `EET_KnockdownTypeApplicator` line removed, Aard's force damage (5% of the victim's maximum health) stored in `gmFrozenForceDamage` and added by `GMPoolApply` after the pool's multiplication, to the action's force damage or as a new one (legacy's order: the bonus multiplies the hit, not the force damage) |
| Port status | **signed off** (2026-10-25); ported (slice 2, 2026-10-24, 5.x-GM `87a6a97a`), verified in both trees |
| Open checks | A bolt or a strong attack shattering a freeze; a fight with an enemy that fights back; NG+ |
| Save impact | none (expected) |
| NG+ counterpart | applied, untested |

**What it does** (bugfix 69 "Northern Wind bomb bugs and inconsistencies were fixed"; legacy's comment: "remove knockdown, make it to multiply the damage instead"): the hit of Geralt's that shatters a freeze (a sword, bolt or other physical or silver hit, or Aard) deals more damage and no longer knocks the enemy down: Northern Wind's freeze +25/35/50% (ported with ALCH-14), any other freeze +50% (the generic `FrozenEffect`: Piercing Cold's, which lasts 5 s instead of 4). An Aard hit on a frozen enemy also deals 5% of the enemy's maximum health as force damage. In 1.32 and 5.x the shattering hit knocks the enemy down (5.x's frost hit came on top; ALCH-14 removed it).

**Implementation (legacy):** `FrozenEffect` (regular, NG+); the frozen block of `W3DamageManagerProcessor.ProcessDamageIncrease` (the knockdown dropped, the force damage added).

**5.x:** 1.32's rule, with its separate frost hit of the bonus × the victim's health (removed by ALCH-14, whose pool term carries the bonus).

**Notes:** Aard's own knockdown roll (SKL-08) still applies to the enemy it unfreezes, as in legacy: only the freeze's extra knockdown is gone. The force damage goes through the formula like Aard's other damage: Aard's intensity, force resistance, and the rule that the player's signs deal ×0.25 (level 1) to ×0.75 (from level 11) against Vitality (DMG, `damage/pipeline.ws`), so a level 1 Geralt's Aard takes 1.25% of a human's maximum health. When Piercing Cold freezes the enemy again with the same cast, its own 250 force damage is not dealt (MUT-04).

**Decisions:** legacy's frozen hit (DX2 (a), project owner, 2026-10-24). Ends ALCH-14's temporary deviation (the knockdown and Aard's force damage).

**Verification (slice 2, 2026-10-24, both trees):** scripted (`GMTest_efx02`, in the regression): `FrozenEffect` 5 s and +0.5, Northern Wind's abilities untouched. Scripted hits (`gmtest_efx02_scripted`, a fixed physical hit of 100 by Geralt on the neutral human test dummy): the generic freeze added as Piercing Cold adds it lasts 5 s, its shattering hit deals 150, Northern Wind 1's 125; the freeze ends, no knockdown on the dummy. Real Aard casts (`autocast`, read by the hit probe `gmtest_efx02_aard_a/b`, which records the cast's first hit before and after the increase steps; the dummy made immune to knockdowns): unfrozen, Aard deals no force damage and carries its one knockdown roll; frozen by the generic freeze or by Northern Wind 3 (added by script), the hit carries 5000 force damage (5% of 100000) and the same single knockdown roll (5.x adds a second), deals 5000 before the sign rule and takes 1250 health; a real Piercing Cold cast (Mutation 6, the dummy's frost resistance at -300% so it always freezes) froze the dummy and a second real Aard 5 s later shattered it the same way (Piercing Cold froze it again). Real light attacks (`gmtest_efx02_light_a/b/c`, the input event, steel sword, locked on): raw damage ×1.5 on the dummy frozen by the generic freeze, by Northern Wind 3 added by script and by a real Northern Wind 3 throw (`gmtest_alch14_throw`, new tree), ×1 unfrozen; no knockdown in the hit or on the dummy, the freeze ended. Screenshots: the frozen dummy and the Aard cast that shattered it, in each tree.

### EFX-03 Freezing pauses damage over time

| | |
|---|---|
| Kind | system |
| Pillars | P5 |
| 5.x class | clean |
| Flags | — |
| Depends on | EFX-02 (which freezes take the generic effect) |
| Skill trees | n/a |
| Port form | `effects/frozen.ws`: `@addMethod(W3EffectManager)` `PauseAllDoTEffects`, `ResumeAllDoTEffects` (legacy's bodies: every `W3DamageOverTimeEffect` paused by source); `@wrapMethod(W3Effect_Frozen)` `OnEffectAdded` (after 5.x's regen pause, while the freeze is active: a target in mid-air is not frozen) and `OnEffectRemoved` |
| Port status | **signed off** (2026-10-25); ported (slice 2, 2026-10-24, 5.x-GM `87a6a97a`), verified in both trees |
| Open checks | A damage over time applied while the enemy is already frozen keeps ticking (legacy's too: the pause is made when the freeze starts); not tested |
| Save impact | none (expected): pauses are by source name; a save made while an enemy is frozen is unlikely to matter |
| NG+ counterpart | none (scripts) |

**What it does** (changelist 856, ALCH's Northern Wind): while an enemy is frozen, its bleeding, poison and burning stop ticking and their timers stop; they resume when the freeze ends. A freeze no longer wastes a damage-over-time effect on an enemy who cannot be hurt by it longer, and a frozen enemy's regeneration was already paused (1.32).

**Implementation (legacy):** `W3EffectManager.PauseAllDoTEffects`, `ResumeAllDoTEffects` (new), `W3Effect_Frozen.OnEffectAdded`, `OnEffectRemoved`.

**5.x:** 1.32's (regeneration paused only).

**Notes:** a freeze ends burning instead of pausing it: `FrozenEffect` overrides (and denies) `BurningEffect` in `effects.xml`, 1.32's and legacy's data alike, so in play only bleeding and poison pause.

**Decisions:** port as legacy.

**Verification (slice 2, 2026-10-24, both trees):** scripted (`GMTest_efx02`, in the regression): `PauseAllDoTEffects` pauses a bleeding on Geralt by its source and leaves his frost slowdown alone; `ResumeAllDoTEffects` lifts it. In play (`gmtest_efx03`, scripted effects with Geralt as creator on the neutral test dummy, the generic freeze added at 1 s, a timer reading every 0.1 s): a bleeding (1% for 8 s) paused at the freeze, dealt 0 and kept its 6.9 s left while frozen for 3 s, resumed when the freeze was removed, dealt 8% in all and ended 3 s late; a poison (1.6% for 5 s) paused through a freeze that ended on its own after 5.1 s (the generic freeze's 5 s), then dealt the rest, 8% in all; a burning was ended by the freeze.

### EFX-04 Damage-over-time ticks

| | |
|---|---|
| Kind | fix |
| Pillars | P5, P7 |
| 5.x class | clean |
| Flags | — |
| Depends on | — |
| Skill trees | n/a |
| Port form | `@replaceMethod(W3DamageOverTimeEffect)` `CalculateDamage` (5.x's body, legacy's two lines), `effects/dotTicks.ws` |
| Port status | **signed off** (2026-10-25); ported (slice 3, 2026-10-24, 5.x-GM `361dcc86`), verified in both trees |
| Open checks | A tick reduced below 1 per second by a damage-over-time damage resistance (from the code: the floor comes before it) not tested in play |
| Save impact | none |
| NG+ counterpart | none |

**What it does:** each tick of bleeding, poison or burning damages only the stat the victim actually uses (Vitality for living things, Essence for specters and the like; 1.32 computed both and took the larger, so an effect flagged for both could count a victim's unused maximum), and deals at least 1 raw damage per second, so a small percentage on a weak enemy never rounds to nothing. The floor is the raw tick's: the damage-over-time damage resistances (`CDS_DoTBleedingDamageRes`, `CDS_DoTPoisonDamageRes`, `CDS_DoTBurningDamageRes`, which `GetResistForDamage` picks for a tick) still reduce it afterwards (from the code). The effect's own resistance (bleeding, poison, burning resistance) shortens the effect and does not reduce its ticks (1.32's, seen in slice 3). The floor also reaches every other damage-over-time class, as in legacy: Mutated Skin's spread damage (MUT-10), the acid (`W3Effect_Acid`), Yrden's glyph health drain (`W3Effect_YrdenHealthDrain`, both trees), the wraiths' vitality drain, the swarm, the snowstorm, choking and drowning (from the code, audit F2).

**Implementation (legacy):** `W3DamageOverTimeEffect.CalculateDamage`.

**5.x:** 1.32's.

**Decisions:** port as legacy.

**Verification (slice 3, 2026-10-24, both trees):** scripted (`GMTest_efx04`, in the regression): a bleeding added to Geralt (Vitality), its tick computed by the effect's own `CalculateDamage` with made-up maximums: 1000 Vitality and 5000 Essence give 10 per second (5.x: 50, the unused maximum), 50 Vitality gives 1 per second (raw 0.5), a 0.25 s tick 0.25, a larger tick is unchanged. The same on the test dummy (`gmtest_efx04_calc`), a human (Vitality) and a wraith (Essence). In play (`gmtest_efx01_apply`, scripted effects with Geralt as creator on the neutral frozen dummy, a timer reading its health every 0.1 s): bleeding on the human and on the wraith at 100000 health 1% per second, 8% in all; at 50 maximum health (Vitality on the human, Essence on the wraith) 1 per second (raw 0.5), 8 over 8 s; critical poison and poison at 50 health 1 per second; with 50% bleeding or poison resistance the effect lasts half as long and still ticks 1 per second (4 over 4 s, 2.5 over 2.5 s).

### EFX-05 Frost slowdown and hypnosis

| | |
|---|---|
| Kind | tuning |
| Pillars | P5, P8 |
| 5.x class | clean |
| Flags | balance |
| Depends on | AI (which attacks carry frost slowdown: the Wild Hunt's weapons and projectiles, bugfix 75), DMG-02 (frost resistance) |
| Skill trees | n/a |
| Port form | `SlowdownFrostEffect` and `HypnotizedEffect` in `gm_effects.xml` (`extend`), NG+ copies; `W3Effect_SlowdownFrost`'s `default resistStat = CDS_FrostRes` in a scope-based override block (`effects/slowdownFrost.ws`, the port's form for class defaults, [development.md](../development.md)) |
| Port status | **signed off** (2026-10-25); ported (slice 1, 2026-10-24, 5.x-GM `6317278f`), verified in both trees |
| Open checks | A real frost attack (the Wild Hunt's, AI's) and the fiend's hypnosis not tested |
| Save impact | none (expected) |
| NG+ counterpart | applied, untested |

**What it does:** frost slowdown (the "freezing" chance of the Wild Hunt's swords, the Skellige sword, frost attacks on Geralt) lasts 7.5 s instead of 10 and is shortened by the victim's frost resistance (a Wild Hunt minion trophy's +50% frost resistance halves it on Geralt, TRPH). The slow itself is a fixed 30% in the code (`SetAnimationSpeedMultiplier(0.7)`, 1.32, legacy and 5.x); legacy's `slowdown` 0.35 (1.32: 0.5) is read by no script, so it changes nothing. Hypnosis lasts 5 s by default (1.32: 3 s); the fiend's hypnosis on Geralt passes its own length (1.32: 7 × its loop; 5.x: 20 s unless its behaviour tree says otherwise), so from the code the default is used only by sources that pass none (none found; unverified).

**Implementation (legacy):** `SlowdownFrostEffect`, `HypnotizedEffect` (regular, NG+), `W3Effect_SlowdownFrost.<members>`.

**5.x:** 1.32's.

**Decisions:** port as legacy (PX2, PX3, confirmed by the owner, 2026-10-24).

**Verification (slice 1, 2026-10-24, both trees):** scripted (`GMTest_efx01`, in the regression): frost slowdown 7.5 s with `slowdown` 0.35 and 5.x's decay attributes kept, hypnosis 5 s; frost slowdown added to Geralt with +50% frost resistance (test step abilities) lasts 3.75 s, without it 7.5 s. In play (`gmtest_efx01_apply` on the neutral test dummy): frost slowdown lasted 7.3 to 7.4 s of 7.5 at 0 frost resistance and 3.6 s of 3.75 at 50%; hypnosis's time 5 s. **Found:** hypnosis's effect entry (and the witch's, `WitchHypnotizedEffect`) names its resistance `will_resistance`, a point name 5.x's `ResistStatNameToEnum` does not know: the entry's name overrides the class's `CDS_WillRes` with none, so in 5.x (and 1.32) will resistance does not shorten hypnosis (seen: 5 s at 40% will resistance). Legacy's EFX-08 names it: since slice 5 will resistance shortens hypnosis (verified, [EFX-08](#efx-08-effect-resistance-points)).

### EFX-06 Critical effects end on time

| | |
|---|---|
| Kind | fix |
| Pillars | P8 |
| 5.x class | clean |
| Flags | — |
| Depends on | — |
| Skill trees | n/a |
| Port form | `effects/criticalEnd.ws`: `@replaceMethod` of `W3CriticalEffect.OnTimeUpdated`, `W3CriticalDOTEffect.OnTimeUpdated`, `W3Effect_Knockdown.OnTimeUpdated`, `W3Effect_HeavyKnockdown.OnTimeUpdated`, `W3Effect_Ragdoll.OnTimeUpdated` (5.x's bodies, legacy's end rule), `@wrapMethod` of `W3Effect_Knockdown.OnEffectRemoved` and `W3Effect_HeavyKnockdown.OnEffectRemoved`, the ragdoll's `OnEffectRemoved` (legacy's new event, calling `super`) in a scope-based override block (the event is inherited: [development.md](../development.md#choosing-a-technique)); `effects/dotTicks.ws`: the inactive check at the top of `W3DamageOverTimeEffect.OnUpdate` (`@replaceMethod`, 5.x's body) |
| Port status | **signed off** (2026-10-25); ported (slice 3, 2026-10-24, 5.x-GM `361dcc86`), verified in both trees |
| Open checks | A knockdown on an enemy moving normally getting up at its end, and a knockdown in mid-air (no wait for the landing, PX4), not watched in play; Geralt's own critical states not tested |
| Save impact | none |
| NG+ counterpart | none |

**What it does** (bugfix 173): a critical effect (knockdown, heavy knockdown, ragdoll, burning, stagger, freeze and the others) ends when its time runs out, whether or not its animation is still playing; the request to stop the animation moves to the effect's removal. In 1.32 an expired effect waited for its animation to stop and stayed active if the animation had been interrupted the wrong way, so its damage over time could tick forever; a damage-over-time effect also stops ticking once inactive or expired. Side effects of legacy's rewrite, kept: a knockdown no longer stays active until a victim in mid-air lands (the stop is asked with the in-air flag at removal), and the `DisableFinisher` signal 1.32 sent at the end of a critical effect is gone (SKL-08 already ignores that event: only heavy knockdowns allow finishers).

**Implementation (legacy):** the five `OnTimeUpdated`, the three `OnEffectRemoved`, the check in `W3DamageOverTimeEffect.OnUpdate`.

**5.x:** 1.32's code (only whitespace and the controller vibration changed).

**Decisions:** port as legacy (PX4, confirmed by the owner, 2026-10-24).

**Verification (slice 3, 2026-10-24, both trees):** scripted (`GMTest_efx04`, in the regression): a bleeding's tick with its time up caches no damage, one with time left caches its tick. In play, on the neutral frozen human dummy (its animations at 1/1000 speed, so a critical state's animation never ends: the interrupted-animation case of bugfix 173): scripted effects (`gmtest_efx01_apply`, a timer every 0.1 s) end at their time: critical poison 4.92 to 4.96 s of 5 (8% dealt, nothing after), burning 2.92 to 2.99 s of 3, hypnosis 4.93 to 4.94 s of 5, knockdown 0.92 to 0.94 s of 1, heavy knockdown 4.91 to 4.92 s of 5, stagger 0.45 to 0.51 s of 0.5, ragdoll its random time (1.8 to 2.7 s) within 0.05 s; before the slice the critical poison and hypnosis stayed active past their time (slice 1). Real Aard casts (`autocast(ST_Aard)`, followed by `gmtest_efx06_watch`, which reports every critical effect the dummy gets): its knockdown (1 s), long stagger (2.5 s) and stagger (0.5 s) each ended at their time on the frozen dummy. Screenshots: the Aard casts at the dummy, in each tree.

### EFX-07 Burning and hits

| | |
|---|---|
| Kind | tuning (5.x's change) |
| Pillars | P8, P5 |
| 5.x class | overlap |
| Flags | balance |
| Depends on | ENCH-13 (its replaced `W3Effect_Burning.OnEffectAdded` and `OnUpdate`, signed off), SKL-09 (Igni's burning chance, signed off) |
| Skill trees | n/a in the code; Igni (both trees) is the main burning source |
| Port form | `effects/burningHits.ws`: `@replaceMethod(W3Effect_Burning)` `CacheSettings` (5.x's body, 1.32's allowed hits for every target); the `allowedHits` release removed from ENCH-13's `OnUpdate` replacement (`enchantments/aardIgniWords.ws`) |
| Port status | **signed off** (2026-10-25); ported (slice 4, 2026-10-24, 5.x-GM `3fdaad99`), verified in both trees |
| Open checks | A burning enemy with a second critical effect queued (from the code: the hit then moves the burning to the background instead of ending it); Dancing Star, Dragon's Dream, fire swords and Ignition's burning not tested (the rule is the effect's, whatever the source); not checked in regression (the checks need an NPC) |
| Save impact | none (expected): `allowedHits` is a saved field; an enemy burning in a save keeps 5.x's array until its burning ends |
| NG+ counterpart | none |

**What it does:** burning stuns: the victim flails in the burning animation ("stunlocks", changelist 854). In 1.32 and legacy any hit but Igni's plays its hit reaction, which breaks the flailing at once, and with it **the burning ends**: when the hit reaction stops the critical-state animation, the game removes the critical effect it was playing if no other critical effect waits (`CBehTreeTaskCriticalState.OnDeactivate`, `CActor.CriticalStateAnimStopped`, 1.32's and 5.x's code; seen in slice 4: the burning's damage stops with the flailing). So a burning enemy takes its burning damage until the first hit that is not Igni's. Igni's hits (a second cast at a burning enemy) play no reaction and leave it flailing. 5.x makes a burning enemy ignore hits' reactions for the first half of its burning (1.5 s of the 3 s), so Igni, Dancing Star, Dragon's Dream, Ignition and fire swords give a guaranteed window of free hits. Legacy's burning (33% chance from Igni, independent of intensity, SKL-09) was balanced on 1.32's rule. The changelist's numbers (2.7% for 3 s) are 1.32's and 5.x's: no value to port. Legacy's one change here, in `CBehTreeTaskCriticalState.OnListenedGameplayEvent`, is a commented-out idea (`AvoidBurnCS`): no behaviour change.

**Implementation (legacy):** none with behaviour (the comment above).

**5.x:** `W3Effect_Burning.CacheSettings` (no hit allowed on an NPC) and `OnUpdate` (every hit but Igni allowed from half the duration).

**Decisions:** 1.32's and legacy's rule, 5.x's window removed (DX1 (a), project owner, 2026-10-24). The hit that breaks the flailing also ends the burning (the game's shared critical-state code, above): confirmed and kept by the project owner (2026-10-24), after being offered 5.x's 1.5 s window and a variant where the flailing breaks and the fire keeps burning. Legacy's rule, so not a deviation.

**Verification (slice 4, 2026-10-24, both trees):** scripted (`gmtest_efx07_scripted`, a burning from Geralt added to the neutral frozen test dummy): every hit reaction but Igni's allowed from the start, the allowed-hits array one entry per reaction (5.x grew it a second time on an NPC). In play (`gmtest_efx07_a(-3)` unfreezes the neutral dummy so it fights and flails, its burning resistance -300% so Igni's 33% always sets it alight, its burning then 12 s; Geralt `god()`, sword drawn, locked on; a test probe records every hit reaction, a 0.05 s timer the burning and the dummy's animated critical state): a real Igni cast set it alight and flailing; a real light attack 0.54 to 1.77 s into the burning (its first half) played its hit reaction (allowed by the burning, animation played), the flailing stopped and the burning ended within 0.08 s; a second real Igni cast at the flailing dummy (6.6 s, 11.3 s in) played no hit reaction and it kept flailing (the cast renewed the burning); a later sword hit broke it as the first. Screenshots: the dummy alight and flailing, and standing unburnt after the sword hit, in each tree.

### EFX-08 Effect resistance points

| | |
|---|---|
| Kind | fix |
| Pillars | P5 |
| 5.x class | clean |
| Flags | — |
| Depends on | DMG-02 (resistances, signed off; its registration of the points in `all_NPC_ability`/`all_PC_ability`, audit F4) |
| Skill trees | n/a |
| Port form | `effects/resistNames.ws`: `@wrapMethod` of the global `ResistStatNameToEnum` and `ResistStatEnumToName`: `bleeding_resistance`, `will_resistance`, `burning_resistance` as point resistances, after 5.x's names |
| Port status | **signed off** (2026-10-25); ported (slice 5, 2026-10-24, 5.x-GM `d804603d`), verified in both trees |
| Open checks | The fiend's and the witch's real hypnosis on Geralt not tested (scripted hypnosis on the test dummy) |
| Save impact | none |
| NG+ counterpart | none |

**What it does:** the point (flat) resistance names of bleeding, will (Axii) and burning are recognised, so abilities giving such points would count, as for the other resistances. In 5.x's data every such point value is 0 (`opp_base_abl.xml`'s `bleeding_resistance` entries, a Hearts of Stone monster's `burning_resistance`) and legacy's own are registrations (`common_abilities.xml`, mult 1) or 0 (`monster_base_abl_new.xml`, `opp_base_abl.xml`'s `will_resistance`): no play difference from the point values. **But** (found in slice 1, 2026-10-24): effect entries name their resistance by these names (`resistStatName_name`), and an unknown name gives the effect no resistance at all, overriding the class's own: hypnosis and the witch's hypnosis name `will_resistance`, so in 5.x will resistance does not shorten them; with EFX-08 it does (legacy's behaviour). The other entries name known point resistances (`frost_resistance`, `force_resistance`, `shock_resistance`). Answers DMG-02's open check ("until the 5.x XML entries carrying them are checked": checked, all 0).

**Implementation (legacy):** `ResistStatNameToEnum`, `ResistStatEnumToName` (attributed to DMG-02 too).

**5.x:** 1.32's (the percentage names only).

**Decisions:** port as legacy (PX6, confirmed by the owner, 2026-10-24); ends DMG-02's temporary deviation.

**Verification (slice 5, 2026-10-24, both trees):** scripted (`GMTest_efx08`, in the regression): the three point names read as bleeding, will and burning resistance points and are named back, the percentage names and the other point names unchanged, an unknown name stays unknown; `HypnotizedEffect`'s and `WitchHypnotizedEffect`'s entries name `will_resistance`, now read as will resistance; Geralt's three point values 0. In play (the neutral test dummy, `gmtest_efx08_points`): the dummy given 10 points of each by an ability (new test dummy steps for the three point stats, `tools/gen_test_dummy.py`) reads 10 points and 0 percent, and 0 again once removed; a scripted hypnosis (`gmtest_efx01_apply`) lasts 3 s at 40% will resistance (2.98 s seen; 5.x: 5 s) and 5 s at 0.

### EFX-09 Killing a frozen rotfiend

| | |
|---|---|
| Kind | system, fix |
| Pillars | P5 |
| 5.x class | clean (5.x adds Northern Wind's `PoisonDeath` block, kept by ALCH's DL7) |
| Flags | shared with AI (DX3) |
| Depends on | EFX-02 (`SetWasFrozen` on the shattering hit), DMG (`CActor.ReduceDamage` in `damage/pipeline.ws`, `ProcessInstantKill`), AI (the explosion's damage) |
| Skill trees | n/a |
| Port form | in the port's existing replacements: `CActor.ReduceDamage` (`damage/pipeline.ws`: LastBreath does not cap a frozen hit), `CActor.OnTakeDamage` (`mutations/takeDamage.ws`: a LastBreath monster killed by a frozen hit gets the tag `ExplodeNoDamage`); `@replaceMethod(BTTaskExplodeAtDeath)` `Explode` (`effects/frozenRotfiend.ws`: no damage with the tag; the explosion's damage formula stays 5.x's until AI). `ProcessInstantKill` unchanged: 5.x has no LastBreath cap on instant kills (legacy's cap, with its frozen exception, is AI's `GetLastBreathMaxAllowedDamage`), so an instant kill already kills a frozen rotfiend outright, and the tag covers its explosion |
| Port status | **signed off** (2026-10-25); ported (slice 6, 2026-10-24, 5.x-GM `2a8b70b4`), verified in both trees |
| Open checks | The no-damage explosion only by a scripted `Death` signal: no real death ran the explosion in 5.x (Notes); a frozen rotfiend killed by an instant kill or a bolt not tested |
| Save impact | none |
| NG+ counterpart | none |

**What it does** (changelist, Enemy AI: "Killing a frozen rotfiend now prevents the explosion. Freezing a rotfiend that is about to explode also stops the explosion"): monsters with the `LastBreath` ability (rotfiends) cannot be killed by a hit: at low health they start their death explosion. A hit on a frozen one is not held back: it can kill it outright, and its explosion then deals no damage. The second sentence has no code of its own in legacy (from the code; maybe vanilla's freeze stopping the explode behaviour): on the [list to test](../open-questions.md#to-test-in-legacy-ghost-mode). 5.x's Northern Wind blocks `PoisonDeath` (a rotfiend frozen by it does not explode at all; ALCH-14, kept).

**Implementation (legacy):** `CActor.OnTakeDamage` (the tag), `CActor.ReduceDamage` and `ProcessInstantKill` (`!GetWasFrozen()`), `BTTaskExplodeAtDeath.Explode` (the tag; its damage formula is AI's).

**5.x:** 1.32's LastBreath, plus the `PoisonDeath` block.

**Notes** (from the code and slice 6's tests, 5.x): a rotfiend (`rotfiend_lvl1`, Essence) at 25% health or a hit that would take it below holds the hit back to 25% (`lastbreath_threshold`), signals `LastBreath` and starts its swelling (its tree, `monster_drowner_logic`: swell, no hit reactions, it blocks, a self-drain of 10% of its maximum per second, the `Explode` animation) and dies of the drain about 2.5 s later in a burst of gore; below 40% it may also start the swelling on its own (a random chance). Its damaging explosion is `BTTaskExplodeAtDeath` (radius 2.75 m, on Hard about 740 damage to a level 1 Geralt), which runs when its task hears the gameplay event `Death`; **in 5.x no real death ran it**: swelling to death, killed during the swelling, killed outright, in Ghost Mode and with Ghost Mode off (a probe-only mod), Geralt at 1.1 to 1.6 m took no explosion damage and the task heard nothing. Only an explicit `SignalGameplayEvent('Death')` on a living rotfiend ran it. So in 5.x the explosion's damage, and EFX-09's removal of it, are not seen in play; whether 1.32 and legacy delivered `Death` is on the [list to test](../open-questions.md#to-test-in-legacy-ghost-mode). What EFX-09 changes in play: a frozen rotfiend is killed outright by the shattering hit instead of swelling.

**Decisions:** ported now with EFX, the explosion's own damage 5.x's until AI (DX3 (a), project owner, 2026-10-24).

**Verification (slice 6, 2026-10-24, both trees):** a rotfiend (`rotfiend_lvl1`) spawned as the test dummy (`gmtest_efx09_spawn`, frozen in place by animation speed; no armor or resistances, 200 Essence at 55%, above the 40% at which it may swell on its own), Geralt immortal for the test (damage dealt and measured, 3500 Vitality), a timer following its health, freeze and death, probes on the explosion task and on Geralt's damage (`gmtest_efx09_a`, `_b`). Real hits: a real light attack (silver sword, locked on) on the rotfiend frozen by a real Piercing Cold Aard (Mutation 6, its frost resistance -300%) or by a real Northern Wind 3 throw killed it outright: no LastBreath, tagged `ExplodeNoDamage`, no damage to Geralt; the same attack unfrozen was held back to 25% (LastBreath) and it swelled and died of its drain about 2.5 s later, with no explosion damage either (above). Scripted: the explosion run by a `Death` signal (`gmtest_efx09_death`) dealt 742 to Geralt untagged and nothing tagged. Not in the regression (the checks need an NPC). Screenshots: the rotfiend frozen by Piercing Cold and the hit that killed it, in each tree.

### EFX-10 Caught in a spider web

| | |
|---|---|
| Kind | fix |
| Pillars | P8 |
| 5.x class | clean |
| Flags | — |
| Depends on | OPT (legacy's instant casting, for its sign-select keys) |
| Skill trees | n/a |
| Port form | `@wrapMethod(W3Effect_Tangled)` `OnEffectAdded` (`effects/spiderWeb.ws`): on Geralt, `AbortSign()` after 5.x's `CastSignHold` release |
| Port status | **signed off** (2026-10-25); ported (slice 7, 2026-10-24, 5.x-GM `cc824c9a`), verified in both trees |
| Open checks | A real arachas's web projectile not tested (the web added by script as the projectile adds it); the instant-casting select keys wait for OPT (PX9); not compared with a build without the wrapper |
| Save impact | none |
| NG+ counterpart | none |

**What it does** (bugfix 181 "sign casting not being properly aborted when the player gets caught into a spider web"): an arachas's web stops the sign Geralt is casting. Legacy also releases the sign-select keys of its instant-casting option (`ForceDeactivateCastSignHold`, `gm_input.ws`), which waits for that option.

**Implementation (legacy):** `W3Effect_Tangled.OnEffectAdded`.

**5.x:** 1.32's.

**Notes** (from the code, seen in slice 7): `AbortSign` aborts the sign entity in its cast (Aard, Igni, Yrden, Axii: the entity is destroyed before the sign goes off) and ends a channel (Firestream to `Finished`). Quen's entity ignores the abort while it casts (`W3QuenEntity.OnSignAborted` is empty, 1.32, legacy and 5.x), so a web during a Quen cast still raises the shield; and a web projectile hitting Geralt while Quen is up does not entangle him at all (`W3AdvancedProjectile`: Quen takes the hit instead).

**Decisions:** port as legacy without the select keys until instant casting is ported (PX9, confirmed by the owner, 2026-10-24; a deviation only if the option is ported without it). **OPT, when it ports instant casting:** the web also releases its sign-select keys (legacy's `ForceDeactivateCastSignHold` in place of 5.x's `theInput.ForceDeactivateAction('CastSignHold')`).

**Verification (slice 7, 2026-10-24, both trees):** a real sign cast (the cast input called as a key press, `gmtest_efx10(sign, 0.25)`) caught 0.25 s in by a web added by script as an arachas's web projectile adds it (`AddEffectCustom`, the arachas test dummy as creator, 1 s), read 0.3 s later (a test probe on `AbortSign`): Aard, Igni, Yrden and Axii aborted (`AbortSign` called once, the sign entity destroyed before the sign went off), Quen's shield went up (above); a held Firestream channel (`autocast(ST_Igni, true)`, the classic `S_Magic_s02`, the new tree's `S_Magic_s28`) caught by the web (`gmtest_efx10_web`) went to `Finished`. `AddEffectDefault(EET_Tangled)` without a creator is denied (`EI_Deny`).

### EFX-11 Places of Power

| | |
|---|---|
| Kind | tuning (none) |
| Pillars | P7 |
| 5.x class | in-5.x |
| Flags | — |
| Depends on | DMG-06 (the sign intensity curve, signed off), SKL-18 (Gorged on Power, signed off) |
| Skill trees | n/a (Gorged on Power, classic `perk_14` and new `perk_43`, is SKL-18's) |
| Port form | nothing; a scripted check of the five `Shrine*Effect` abilities in the regression |
| Port status | **signed off** (2026-10-25); checked (slice 7, 2026-10-24, 5.x-GM `cc824c9a`): nothing to port; `GMTest_efx11` in the regression, both trees |
| Open checks | — |
| Save impact | none |
| NG+ counterpart | none |

**What it does** (changelist 859; ITEM's hand-off): a Place of Power gives +20% to its sign's intensity for 30 minutes. These are 1.32's values, which legacy kept (its only change is a comment) and 5.x keeps; 5.x only adds an achievement counter and a branch for `perk_36` (Gorged on Power: +30 min and one more buff at a time per level), whose ability exists but whose `<skill>` entry is commented out in `geralt_skills.xml`, so neither tree offers it.

**Decisions:** nothing to port (PX7, confirmed by the owner, 2026-10-24).

**Verification (slice 7, 2026-10-24, both trees):** scripted (`GMTest_efx11`, in the regression): `ShrineAardEffect`, `ShrineAxiiEffect`, `ShrineIgniEffect`, `ShrineQuenEffect` and `ShrineYrdenEffect` give +20% (`spell_power_<sign>`, mult 0.2) for 1800 s; each effect (`EET_ShrineAard` to `EET_ShrineYrden`) added to Geralt carries its ability and 1800 s.

### EFX-12 Damage-over-time debug log

| | |
|---|---|
| Kind | infra |
| Pillars | — |
| 5.x class | clean |
| Flags | — |
| Depends on | — |
| Skill trees | n/a |
| Port form | none (PX5) |
| Port status | dropped (PX5, owner, 2026-10-24) |
| Open checks | — |
| Save impact | none |
| NG+ counterpart | none |

**What it does:** `toggledebugdot` sets a fact that makes each damage-over-time effect write its raw damage per second, type, resistance and value to the on-screen log; `CBaseGameplayEffect.PauseSources` lists an effect's pause sources for the `whoami` debug command.

**Implementation (legacy):** `toggledebugdot`, `W3DamageOverTimeEffect.<members>` and the log in `OnUpdate`, `PauseSources`.

**Decisions:** not ported, as DMG-14's debug messages and ALCH-18's `toggledebugoils` (PX5, confirmed by the owner, 2026-10-24); the tests read the ticks directly.

- **Deviation:** `toggledebugdot` (legacy's per-second log of each damage-over-time tick) and `CBaseGameplayEffect.PauseSources` (the pause sources for `whoami`) are not ported: debug tools only; the EFX tests read the ticks and durations directly (porter's call PX5, confirmed by the owner, 2026-10-24).

### EFX-13 NG+ immobilized look

| | |
|---|---|
| Kind | ui (NG+ only) |
| Pillars | P8 |
| 5.x class | clean |
| Flags | — |
| Depends on | — |
| Skill trees | n/a |
| Port form | none: a DLC cannot override an `<effect>` entry (tried in slice 1, below) |
| Port status | dropped (slice 1, 2026-10-24; PX8, owner) |
| Open checks | — |
| Save impact | none |
| NG+ counterpart | this is one |

**What it does:** in New Game+ the immobilized effect loses Axii's stopping visual (`targetEffectName` `axii_stopping` → empty), as in the regular game's 1.32 data. 5.x's files are 1.32's.

**Decisions:**

- **Deviation:** not ported: in New Game+ the immobilized effect keeps 5.x's (1.32's NG+) Axii stopping visual, where legacy's NG+ data removed it. A DLC cannot override an `<effect>` entry: its entry is added after vanilla's, with or without `on_conflict`, and the effect reads only the first entry of its name, vanilla's; the alternative would be a whole-file override of 5.x's NG+ `effects.xml` for one visual in an untested mode (PX8: "record as a deviation if it doesn't work"; owner, 2026-10-24).

**Tried (slice 1, 2026-10-24):** two probe builds, not kept, added an `ImmobilizedEffect` entry with `targetEffectName_name="axii_stopping"` (a value the regular game's entry, "", does not have) to the DLC's regular `abilities/gm_effects.xml`, once plain and once with `on_conflict="replace"`; the regular folder because NG+ is not played and both folders merge the same way (the NG+ mounter's merge itself unverified). `gmtest_efx13_probe()` (5.x-GM `011145a5`, scripted) listed the merged `<effects>`: both times two `ImmobilizedEffect` entries, vanilla's first (node 52 of 173, "") and the DLC's last (node 168, `axii_stopping`), and an immobilized effect added to the test dummy resolved its `targetEffectName` to none, vanilla's. `CBaseGameplayEffect.CacheSettings` returns after the first entry of its type.

### EFX audit (2026-10-24)

Done by a fresh session ([audit](../feature-mapping.md#audit-signing-a-feature-off)) on 5.x-GM `cc824c9a` and master `5daf180f`, reading code and data, with one game launch for the regression in both trees. Every script unit [attribution.csv](attribution.csv) gives EFX (27, six shared with other features in the damage functions) and every method EFX's eight 5.x-GM commits replace, wrap or add was read against legacy's code (`legacy-GM`), 1.32 (`master`) and 5.x (`vanilla-5.x`). The data as the game reads it was compared with legacy's by a script written for this audit, independently of `gen_ngplus.py`: every `<ability>` and `<effect>` entry legacy changed in `effects.xml` (base game and Hearts of Stone, regular and NG+ folders), against 5.x's entry merged with every Ghost Mode DLC entry of that name in all DLC definition folders (`extend` replacing sub-nodes in order by tag, `replace` whole; `<effect>` entries taken as 5.x's, since a DLC cannot override them), node by node.

**Checked and holding:** the data: `BleedingEffect`, `BleedingTrackingEffect`, `BleedingEffect_BroadheadBolt`, `PoisonCriticalEffect`, `FrozenEffect`, `SlowdownFrostEffect` and `HypnotizedEffect` equal legacy's in both folders (attribute by attribute; 5.x's own attributes kept where legacy has them); legacy's, 1.32's and 5.x's NG+ entries equal their regular ones, so the NG+ copies follow the [NG+ rule](../feature-mapping.md#ng-numbers) (`gen_ngplus.py --check` current); 5.x-GM ships no copy of any `effects.xml`, and no DLC `<effect>` entry carries a vanilla effect's name. The other entries legacy changed in these files are other areas' and equal legacy's (ALCH-14's bombs and Northern Wind, SKL's slowdown, confusion, Firestream and heavy knockdown, ITEM-12's enhanced armor and weapon, FOOD's food and drunkenness, the effects Ghost Mode adds under `GM` names) or are recorded (EFX-13's NG+ immobilized entry; ALCH-08's Pops' Antidote sound, given by script). Scripts: EFX-02's frozen block (legacy's condition, the knockdown line gone, Aard's 5% of maximum health added after the pool's multiplication to the action's force damage or as a new one, cleared with the pool; no early return between `ProcessDamageIncrease` and `GMPoolApply`), EFX-03's two methods (legacy's bodies) and wrappers, EFX-04's `CalculateDamage` and EFX-06's `OnUpdate` check (legacy's lines on 5.x's bodies), EFX-06's five `OnTimeUpdated` (5.x's bodies: 5.x changed only whitespace and the controller vibration, which lives in `OnEffectAdded`, untouched) and three `OnEffectRemoved` (legacy's order: after the base class's own stop request), EFX-07's `CacheSettings` and the release removed from ENCH-13's `OnUpdate`, EFX-08's wrappers (they only fill in names 5.x returns as unknown), EFX-09's three changes (legacy's lines, in the port's existing replacements; `ProcessInstantKill` rightly unchanged: 5.x has no LastBreath cap there), EFX-10's wrapper (legacy's abort, also when the web's animation is refused, as legacy). Every changed line is marked; `check_modsigns.py` 0 unmarked (422 bodies), no native wrap. The eight units the mapping gave other features are ported there (`GMBlindnessCritBonus` and the blindness ability kept off the victim, `alchemy/bombs.ws`; `GetResistBonus` returning none, `alchemy/decoctionsDefense.ws`; the `CBehTreeTaskCSEffect` replacement and wrapper, `skills/aard.ws`) or need nothing (the Axii slowdown class, the negative-immunity removal). Every hand-off to EFX in the other areas' files (ALCH, DMG, SKL, STAM, MUT, ENCH, ITEM) is closed in [hand-offs received](#hand-offs-received); the hand-offs from EFX (AI, XBOW, TRPH, DIFF, OPT, WGT, FIX) are listed in its own table, the convention for areas not mapped yet ([misc.md](misc.md)). The temporary deviations EFX ends are ended (ALCH-14's frozen hit, DMG-02's point names): [deviations.md](deviations.md) lists none "until EFX". The owner's decisions as implemented: DX1 (a) (1.32's allowed hits for every target, and the hit that breaks the flailing also ends the burning, confirmed: not a deviation), DX2 (a), DX3 (a), DX4's boundary, PX1 to PX10 (PX8 as revised: tried, dropped as a deviation). Deviations: EFX-12's and EFX-13's, in the entries and in [deviations.md](deviations.md) with the right format (`deviations.py --check` current). Both trees: no EFX code reads a skill; Aard, Igni, Piercing Cold, Firestream and the Places of Power checks ran in both trees, and Yrden's glyph drain (both trees) takes EFX-04's floor like every damage over time. Status labels: every slice's **verified** claim matches its recorded checks (real casts, attacks and throws or scripted effects, said for each); what was not run is in the open checks. Tests: the regression checks (`GMTest_efx01`, `_efx02`, `_efx04`, `_efx08`, `_efx11`) compare against fixed expected values or the game's own resistance read, and fail on 5.x's behaviour (5.x's durations, 5.x's larger-maximum tick, no will resistance for hypnosis, an expired tick caching damage); the in-play checks compute their expectations from the ability data and the dummy's resistance, not from what they measure. `unit_sweep.py --unattributed` (knockdown, stagger, bleed, poison, burning, frozen, frost, confus, hypnot, blind, slowdown, DoT, critical, ragdoll, tangle, immobil, shrine, `EET_`, immunity, PauseEffect, ResumeEffect, AddEffect, LastBreath, explode, isActive, timeLeft, RequestCriticalAnimStop): no EFX unit missing; the hits are the areas the [hand-offs](#hand-off-to-other-areas) name (AI: monster abilities and projectiles, `CNewNPC.ReactToBeingHit`, `ProcessShieldDestruction`, `CBTTaskCastQuen.ProcessAction`, `GetLastBreathMaxAllowedDamage`, the large rotfiend's ability; XBOW: the blunt bolts; DIFF: `AddLevelBonuses`, `RemoveAllLevelBonuses`; FIX: Ciri's special attack) or not effects at all (weapons, rewards, the Skellige horse blinders, NG+ levels, debug commands). Regression on the audited build: 895 passed, 0 failed in each tree, `gmtest_panel()`'s checks passing (one launch, the new tree set with `GMClassicSkillTree` false and `gmreset()`, then restored).

**Findings:**

1. **The Places of Power's `perk_36` "no skill data defines it"** (doc-only; **corrected**). 5.x's `geralt_skills.xml` (both folders) has the ability `perk_36` (Gorged on Power's 5.x rework: +1800 s per level and `max_active` 1, more Places of Power buffs at a time); only its `<skill>` entry is commented out, so neither tree offers it and `CanUseSkill(S_Perk_36)` is never true. No play effect. The intro, the 5.x table and EFX-11 now say so.
2. **EFX-04's floor reaches more than the two effects named** (doc-only; **corrected**). Every damage-over-time class takes the at-least-1-per-second floor and EFX-06's inactive check, as in legacy: besides Mutated Skin and the acid, Yrden's glyph health drain (both trees), the wraiths' vitality drain, the swarm, the snowstorm, choking and drowning. Play effect: none worth noting (1 damage per second at most, on very weak targets); EFX-04's text now lists them.
3. **Regression checks remove Geralt's effects without putting them back** (clear fix, test-only, low; **fixed**, fix slice A, 5.x-GM `95ce014f`, **verified** in both trees). `GMTest_efx11` removes all five Places of Power buffs from Geralt (`RemoveAllBuffsOfType`, before and after each check); `GMTest_efx01`, `_efx02` and `_efx04` remove his frost slowdown, bleeding and the damage-over-time regen block. On the test save there is none, so nothing changes; run on a save where Geralt has a Place of Power buff (+20% sign intensity for up to 30 minutes), the regression ends it. The regression's rule is that each check restores what it changes ([development.md](../development.md#testing-in-game)). Fix: the four checks save Geralt's effects of the types they touch (all five Places of Power buffs; frost slowdown; bleeding and its regen block) and put them back afterwards with their time left, length, value, source, creator and Mutagen 23 origin (`GMTestEfxSaveBuffs`, `GMTestEfxRestoreBuffs`, `tests/gmTestsEfx.ws`); an effect a restored one adds by itself (a bleeding's regen block) is removed unless it was saved. **Verification** (2026-10-25, both trees, 5.x-GM `95ce014f`; scripted, read back by script): `gmtest_efx_buffs_setup()` gives Geralt a Place of Power buff (Igni), a weak bleeding with its regen block and a frost slowdown with odd times left (1234.5, 543.25, 432.75 s); after `GMTest_efx01`, `_efx02`, `_efx04` and `_efx11` (40 checks passing) all four are there with their source, ability, value and time left less the seconds passed (`gmtest_efx_buffs()`), and so is another check's short regen block that was on Geralt; after the whole regression (895 passed, 0 failed) the Place of Power buff is there with its time left. Not EFX's: three other areas' checks end Geralt's bleeding and frost slowdown by the effect they check (SKL's Undying, `GMTest_skla_undying`, and Cleansing, `GMTest_skla_cleanse`, remove negative effects; ALCH-04's Swallow, `GMTest_alchport`, stops bleeding), as the game does; ALCH-04's and SKL's damage-over-time checks leave a regen block of a few seconds (source `gmtest`). Pitfall: a bleeding's time left scales with Geralt's bleeding resistance whenever his abilities change (5.x's `RecalcDuration`), so it can differ from a fixed expectation after a check that adds abilities.
4. **EFX-03 pauses only when the freeze took** (no action). The wrapper pauses damage over time when the freeze is active after 5.x's `OnEffectAdded`; legacy paused inside it, also when the critical-state animation was refused (`ECH_Abort`, which makes the effect inactive). Such a freeze is removed at once and its removal resumes them, so nothing differs in play.
5. **Not verified in game** (no action; open checks). As the entries list them: real bolts (broadhead, tracking, a bolt shattering a freeze), a real poison cloud, the Wild Hunt's frost attacks and the fiend's and the witch's hypnosis on Geralt, a fight with an enemy that fights back while frozen, a knockdown in mid-air and Geralt's own critical states, burning with a second critical effect queued and from Dancing Star, Dragon's Dream, fire swords and Ignition, a real arachas web, the rotfiend's explosion (no real death ran it in 5.x, an [open question](../open-questions.md#to-test-in-legacy-ghost-mode)), NG+ (policy).

**Doc corrections made with the audit:** F1 (the intro, the 5.x table, EFX-11), F2 (EFX-04), the status line and the [status page](README.md#where-the-port-stands).

**Not reviewed:** nothing of EFX's code, data or docs. Not done: the in-game checks the entries list as open (F5); legacy's own behaviour in play (the [list to test](../open-questions.md#to-test-in-legacy-ghost-mode)). Out of scope: the other areas' entries in the shared files and functions (ALCH's bombs, SKL's sign effects, DMG's pool terms), AI's rotfiend explosion damage and instant-kill cap.

**Suggested fix slices:**

- **A, test hygiene** (`tests/gmTestsEfx.ws`, `gmTestsEfx2.ws`, `gmTestsEfx3.ws`, `gmTestsEfx7.ws`): F3: the regression checks keep or restore an effect Geralt already had (Places of Power buffs first). **Done** (5.x-GM `95ce014f`, verified in both trees, 2026-10-25).
- **Owner decisions:** none.

#### Audit close-out

Closed 2026-10-25: every finding is fixed or recorded; no owner decision was needed. Fixed and verified in both trees: F3 (fix slice A, 5.x-GM `95ce014f`); the other areas' regression checks that end Geralt's bleeding, frost slowdown or regen block by design (SKL's `GMTest_skla_undying` and `GMTest_skla_cleanse`, ALCH's `GMTest_alchport`, and the short regen blocks from `GMTest_sklg_dot`, `GMTest_sklg_selfbomb` and `GMTest_alchport`) are left as they are, the owner's decision (2026-10-25); the shared helpers `GMTestEfxSaveBuffs` and `GMTestEfxRestoreBuffs` are available if it ever matters. Corrected in the docs: F1, F2. Recorded: F4 (no action), F5 (the open checks). Checks at close: regression 895 passed, 0 failed in each tree, `gmtest_panel()`'s checks passing; `check_modsigns.py` 0 unmarked (422 bodies); `deviations.py --check` current. EFX was **signed off** by the project owner (2026-10-25). What stays open: the open checks in the entries (F5); legacy's own behaviour in play ([list to test](../open-questions.md#to-test-in-legacy-ghost-mode)).

---

### Dependencies on other areas

- **Done areas EFX builds on:** DMG (`damage/pool.ws`, `damage/pipeline.ws`, formula rules for damage over time), ALCH-14 (the freeze bonus, blindness), SKL-08 (severity, finishers), SKL-09, SKL-10, SKL-12, SKL-18 (effect values and damage-over-time hooks), MUT-04 (Piercing Cold's freeze), ENCH-13 (burning's replaced methods), ITEM-12 (enhanced armor and weapons).
- **Areas EFX shares with or waits for:** AI (who applies effects, monster resistances, the rotfiend explosion's damage, hit-reaction severity), XBOW (bolt effect chances), TRPH (trophy resistances), OPT (instant casting, for EFX-10's select keys), DIFF (deadly enemies' immunity).

### Hand-offs received

Every item other areas handed to EFX, and where it lands:

| From | Item | EFX |
|---|---|---|
| ALCH-14 deviation (until EFX, owner 2026-10-20; audit F2) | A frozen enemy's shattering hit still knocks down; no Aard force damage on frozen enemies | EFX-02: ended (2026-10-24, 5.x-GM `87a6a97a`): the freeze bonus is legacy's pool term (ALCH-14), 5.x's frost hit removed (ALCH-14), the knockdown applicator removed and Aard's force damage added (EFX-02) |
| ALCH (hand-off) | Generic bleeding, poison critical, hypnotized, frost slowdown | EFX-01, EFX-05 |
| ALCH (hand-off) | Frozen: damage over time paused, Aard on frozen enemies, legacy's removal of the knockdown, the generic `FrozenEffect`'s +0.5 | EFX-03, EFX-02 |
| ALCH (scope) | The frozen rotfiend (with AI) | EFX-09 (DX3): ported (2026-10-24, 5.x-GM `2a8b70b4`); the explosion's damage and the instant kill's cap stay AI's |
| ALCH-14 (depends on) | Burning, poison, blindness | EFX-01 (poison, bleeding); burning: EFX-07; blindness: ported by ALCH-14 (nothing left) |
| DMG (hand-off) | The frozen target's knockdown and Aard force damage | EFX-02 |
| DMG (hand-off) | Frozen pausing damage over time | EFX-03 |
| DMG (hand-off) | Damage-over-time ticks (at least 1 per second, only to the stat the target uses; `CalculateDamage`, `OnUpdate`) | Ported (2026-10-24, 5.x-GM `361dcc86`): EFX-04 (`CalculateDamage`), EFX-06 (`OnUpdate`'s inactive check); EFX-12 (`OnUpdate`'s log) dropped (PX5) |
| DMG (hand-off) | Bleeding and blindness crit bonuses | Blindness: ported by ALCH-14 (`GMBlindnessCritBonus`); bleeding: Crippling Strikes' bonus against bleeding enemies, ported by SKL-03 (DMG-04's exception); nothing left |
| DMG-02 deviation (temporary, until the 5.x XML is checked) | Point names of bleeding, will, burning resistance | Ended (2026-10-24, 5.x-GM `d804603d`): EFX-08 (checked: all 0 in 5.x's data) |
| DMG-04 (depends on) | Frozen | EFX-02 |
| SKL (hand-off) | The bleeding rework (strength as % of max health, bleeding resistance) for Crippling Strikes | Ported by SKL-03 from the skill's own values (1%, 8 s, resisted); EFX-01 gives the generic bleeding the same 1%/8 s |
| SKL, STAM (hand-offs) | Low stamina raising knockdown severity (`ModifyKnockdownSeverity`) | Ported by SKL-08 (`GMModifyKnockdownSeverity`); nothing left |
| SKL-09 (depends on) | Burning for Igni | EFX-07 (DX1); the values are 1.32's |
| ENCH-13 (depends on) | Ignition's burning | EFX-07; Ignition's spread ported by ENCH-13 |
| Confusion crit term | +25% crit chance against the confused, the larger of it and blindness's | Ported by SKL-12 and ALCH-14; nothing left |
| MUT-04 (depends on) | Frozen for Piercing Cold | EFX-02 (5 s, +50%), EFX-03 |
| MUT-13 (depends on) | Critical effects | Its chance factor is ported; EFX-06 changes how they end (ported 2026-10-24) |
| ITEM (scope, hand-off) | Places of Power's enhanced sign effects (changelist 859) | EFX-11 (nothing to port; checked in the regression, 2026-10-24) |
| feature-mapping (roadmap) | The `EFX` area | this file |

### Hand-off to other areas

| Area | Changes |
|---|---|
| AI | The NPC weapons and attacks that legacy gave frost slowdown (Wild Hunt, bugfix 75; `def_item_npcweapons.xml`, e.g. `NPC Eredin Sword _Stats`), monster projectiles' effects (`advancedProjectile.ws`: `projEfect` defaults, lengths 2 → 3 s), the ice spike's frost damage (`W3IceSpike.DealDamage`), the rotfiend explosion's damage (`BTTaskExplodeAtDeath.Explode`'s formula, shared with EFX-09) and `GetLastBreathMaxAllowedDamage`, hit-reaction severity (`ModifyHitSeverityReaction`, `ModifySeverity`), `CNewNPC.ReactToBeingHit` (flyers forced down, already AI's from SKL), `OnFireHit` (Ice Armor), `ProcessShieldDestruction`, NPC Quen's stagger (`CBTTaskCastQuen.ProcessAction`), the fiend's hypnosis length (5.x), monsters' effect resistances |
| XBOW | The bolts' effect chances (`blunt_bolt`, `broadhead_bolt`, `tracking_bolt`, `explosive_bolt` and their legendary versions) |
| TRPH | Trophies' effect resistances (minion frost, forktail burning, wyvern poison, lamia bleeding) |
| DIFF | Deadly enemies' blindness immunity removed (`CNewNPC.AddLevelBonuses`, `RemoveAllLevelBonuses`) |
| OPT | Instant casting (`gm_input.ws`: `TestCastSignHold`, `ForceDeactivateCastSignHold`), which EFX-10's web also releases |
| WGT | `W3Effect_OverEncumbered` (no fast travel), the boat sinking (`W3Boat`) |
| FIX | Ciri's special attack (`W3ReplacerCiriStateCombatSword.SpecialAttackCleanup`: invulnerability, its immunity cleanup) |

### Save impact

None expected: effect abilities are read when an effect is applied, the replaced methods live; burning's `allowedHits` is saved (EFX-07: an enemy burning in a save keeps 5.x's array until the burning ends). Adding or removing the mod mid-playthrough is not supported ([save compatibility](../feature-mapping.md#save-compatibility)).

### Area decisions

**Decided** (project owner, 2026-10-24):

- **DX1 (a):** 1.32's and legacy's burning rule: any hit but Igni breaks a burning enemy's flailing at once; 5.x's window of ignored hit reactions is removed (EFX-07). The hit also ends the burning (found in slice 4): confirmed and kept (project owner, 2026-10-24).
- **DX2 (a):** legacy's frozen hit: the shattering hit gets the freeze's bonus and no knockdown, Aard adds 5% of the enemy's maximum health as force damage, the generic freeze lasts 5 s with +50% (EFX-02); ends ALCH-14's temporary deviation when EFX-02 is ported.
- **DX3 (a):** the frozen rotfiend is ported now with EFX (EFX-09); the explosion's own damage stays 5.x's until AI.
- **DX4:** the boundary as in [Scope](#scope), confirmed.
- **PX1 to PX7, PX9, PX10:** confirmed as proposed.
- **PX8:** confirmed as proposed ("go ahead and test the new game + change, and record as a deviation if it doesn't work"): the override was tried in slice 1; a DLC cannot override an `<effect>` entry, so EFX-13 is dropped as a deviation ([EFX-13](#efx-13-ng-immobilized-look)). The project-wide [New Game+ policy](../feature-mapping.md#new-game-carried-over-and-scaled-not-balanced-or-tested) is unchanged (owner, 2026-10-24): EFX-01's, EFX-02's and EFX-05's NG+ copies are generated by `gen_ngplus.py`.

The questions as they were put (legacy behaviour first applies where 5.x did not change the subject):


| # | Question | Options | Recommendation |
|---|---|---|---|
| DX1 | Burning and hits (EFX-07): 5.x changed it | (a) 1.32's and legacy's: any hit but Igni breaks a burning enemy's flailing at once (its burning damage goes on); (b) 5.x's: a burning enemy shrugs off hits' reactions for the first 1.5 s of its 3 s burning, a guaranteed window of free hits after Igni, Dancing Star, Dragon's Dream, Ignition or a fire sword | (a): legacy's Igni (33% burn chance, 150 damage) and the fire bombs were balanced on it; (b) is a large buff to every burning source, especially Igni builds in both trees |
| DX2 | Hitting a frozen enemy (EFX-02) | (a) legacy's: the shattering hit deals the freeze's bonus (Northern Wind +25/35/50%, Piercing Cold's and other freezes +50%, which last 5 s), no knockdown; Aard adds 5% of the enemy's maximum health as force damage; (b) the port today: the bonus, plus 1.32's knockdown, no Aard bonus (ALCH-14's temporary deviation made permanent) | (a): legacy's fix ("make it multiply the damage instead"); 5.x is 1.32 here. Makes Piercing Cold's freezes worth a strong follow-up and Aard a finisher for frozen enemies |
| DX3 | The frozen rotfiend (EFX-09), shared with AI | (a) port it now with EFX: a frozen rotfiend (any monster that explodes on death) can be killed by the shattering hit and its explosion deals no damage; the explosion's own damage stays 5.x's until AI; (b) leave it all to AI | (a): four small changes in functions the port already replaces; keeps the freeze's rules together. 5.x's Northern Wind block (DL7) stays |
| DX4 | The boundary | As in [Scope](#scope) | Confirm |

**Porter's calls** (confirmed by the owner, 2026-10-24; each follows legacy or has no play effect):

| # | Call |
|---|---|
| PX1 | EFX-01: legacy's bleeding and critical poison values; they also reach 5.x's three Wolven bleeding types, which nothing applies (ARM-09) |
| PX2 | EFX-05: frost slowdown 7.5 s, shortened by frost resistance; legacy's `slowdown` 0.35 carried though no script reads it (the slow stays a fixed 30%, as in legacy) |
| PX3 | EFX-05: hypnosis's default 5 s carried; the fiend passes its own length, so it is likely inert; the fiend's 5.x length is AI's |
| PX4 | EFX-06: legacy's end rule with its side effects (no wait for a mid-air knockdown to land; no `DisableFinisher` signal at the end) |
| PX5 | EFX-12: `toggledebugdot` and `PauseSources` not ported, as DMG-14's debug messages and ALCH-18's `toggledebugoils` (a deviation of a debug tool, recorded with the slice) |
| PX6 | EFX-08: the point names ported; no play effect from point values (5.x's data has no non-zero point value); ends DMG-02's temporary deviation. It has one play effect, found in slice 1 and verified in slice 5: will resistance shortens hypnosis again (the fiend's and the witch's on Geralt), as legacy (see EFX-08) |
| PX7 | EFX-11: nothing to port for the Places of Power; a scripted check of the five buffs' +20% and 30 min |
| PX8 | EFX-13: try the NG+ `<effect>` override from the DLC; if a DLC cannot override effect entries, drop it as a deviation (NG+ only, a visual; NG+ is not tested) |
| PX9 | EFX-10: the web aborts the sign; the sign-select keys of legacy's instant casting are released when that option is ported |
| PX10 | Attribution: the units the mapping found ported by other features are attributed to them (blindness to ALCH-14, the Elemental decoction's resistance block to ALCH-13, the Axii slowdown class to SKL-12, the negative-immunity removal to SKL-07, the finisher event to SKL-08); no code change |

### Port order

Each slice compiles and is verified on its own, on a neutral test dummy with scripted effects and real casts, in both trees where Aard or Igni is involved.

| # | Slice | Ends |
|---|---|---|
| 1 | EFX-01, EFX-05 data: the effect values, frost slowdown's resistance, `gen_ngplus.py`; EFX-13's attempt (failed: dropped, PX8) | — |
| 2 | EFX-02, EFX-03: the frozen hit (no knockdown, Aard's force damage, the generic +50% and 5 s) and damage over time paused while frozen; real Aard casts in both trees, Piercing Cold's freeze | ALCH-14's temporary deviation (knockdown, Aard) |
| 3 | EFX-04, EFX-06: the ticks and the end of critical effects | — |
| 4 | EFX-07 (with DX1) | — |
| 5 | EFX-08: the resistance point names | DMG-02's temporary deviation |
| 6 | EFX-09 (with DX3): the frozen rotfiend (a spawned rotfiend frozen by Piercing Cold or Northern Wind) | — |
| 7 | EFX-10, EFX-11: the spider web, the Places of Power check | — |

**Later:** —
