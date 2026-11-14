# EFX: generic effects (damage over time, critical effects, freezing, slowdowns)

The effects every source shares: bleeding, poison, burning, freezing, knockdown and stagger, hypnosis, frost slowdown, blindness, confusion, and the Places of Power's sign buffs. Whatever applies them (a sword, a sign, a bomb, a monster), their strength, length and rules live in `effects.xml` and the effect classes, which is what this area covers. Ghost Mode's changelist (847–859): "Damage over time (DoT) effects reworked to deal approximately the same amount of total damage. Bleeding effect: -1% hp/sec for 8 seconds, blocks hp regen. Bleeding effect from tracking bolt: -0.5% hp/sec for 16 seconds … Burning effect: -2.7% hp/sec for 3 seconds, blocks hp regen, stunlocks. Poison effect: -1.6% hp/sec for 5 seconds … Frozen effect now also pauses all DoT effects. … Enhanced Sign effects: 30 min duration, +20% to corresponding Sign Intensity"; the bugfix list (173: "DoT effects being able to continue indefinitely if the corresponding critical state animation is interrupted incorrectly"; the spider web aborting signs; Northern Wind); the Enemy AI section ("Killing a frozen rotfiend now prevents the explosion"). Sources: those lines, the other areas' hand-offs to EFX, and the code, which has more than the changelist (the frozen hit, the damage-over-time ticks, the frost slowdown's resistance).

**What 5.x did in this area** (from `vanilla-5.x`). The effect values are 1.32's. Burning changed: a burning enemy (not Geralt) plays no hit reaction for the first half of its burning (1.5 s of 3 s), so its burning stun cannot be interrupted by hits (`W3Effect_Burning.CacheSettings` and `OnUpdate`, `allowedHits`); Ignition (Glyphword 12) spreads without its chance roll (ENCH-13, ported). Bleeding gained three extra types (`EET_Bleeding1` to `3`) for the Wolven set's wound stacks, which the port removed (ARM-09): they are inert. Bomb damage over time grew with potion duration (removed by ALCH-14, DL7). The fiend's hypnosis lasts 20 s by default (1.32: 7 × its loop time; AI's). The rest of the effect classes, the frozen hit (a knockdown applicator and a separate frost hit; the latter removed by ALCH-14), the knockdown, stagger and ragdoll timing and the damage-over-time ticks are 1.32's. The Places of Power's buffs are 1.32's (+20% sign intensity for 30 min); 5.x only counts them for an achievement and has a dead `perk_36` branch (Gorged on Power's longer and stacking buffs: its ability is in `geralt_skills.xml`, but its `<skill>` entry is commented out, so neither tree offers it).

**How legacy Ghost Mode implements it.** Data: seven abilities of `effects.xml` (bleeding, the two bolt bleedings, critical poison, the generic freeze, hypnosis, frost slowdown), regular and NG+ (equal), and one NG+-only effect entry (immobilized). Scripts: the frozen effect and two new effect-manager methods (damage over time paused while frozen), the damage-over-time effect's tick (`CalculateDamage`, `OnUpdate`), the end of critical effects (`OnTimeUpdated` of the critical, critical damage-over-time, knockdown, heavy knockdown and ragdoll effects), the frost slowdown's resistance, the spider web's sign abort, the frozen-hit rules in `ProcessDamageIncrease`, the frozen rotfiend (`CActor.OnTakeDamage`, `CActor.ReduceDamage`, `ProcessInstantKill`, `BTTaskExplodeAtDeath.Explode`), the resistance point names (`ResistStatNameToEnum`, `ResistStatEnumToName`), a debug log (`toggledebugdot`).

Unit lists: [attribution.csv](attribution.csv): **42 units** carry an EFX feature (27 script units, 6 of them shared with DMG, STAM, SKL, MUT, ARM, ENCH, ALCH and SWD features in the damage functions; 7 XML units and their 7 NG+ copies; 1 NG+-only entry). Eight more units are attributed to the features that already port them (the blindness crit bonus to ALCH-14, the Elemental decoction's resistance block to ALCH-13, the Axii slowdown class to SKL-12, the negative-immunity removal to SKL-07, the finisher event to SKL-08; PX10). Units that only look like effects but belong elsewhere are listed under [Not EFX](#scope).

Port status: **signed off** by the owner (2026-10-25): EFX-01 to EFX-11 ported and verified in both trees; EFX-12 and EFX-13 dropped (deviations). Open checks are listed per entry.

## Scope

**EFX covers** the generic effects' values (bleeding, critical poison, the generic freeze, hypnosis, frost slowdown), the frozen hit (its bonus, no knockdown, Aard's force damage), damage over time paused while frozen, the damage-over-time tick, the end of critical effects, burning against hits, the effect resistance point names, the frozen rotfiend, the spider web, the Places of Power, the damage-over-time debug log, the NG+ immobilized entry.

**Ported by other areas** (nothing left for EFX):

| Subject | Ported by | What |
|---|---|---|
| Knockdown and stagger severity, low stamina raising it | SKL-08 (signed off) | Legacy's knockdown roll for every source and `ModifyKnockdownSeverity` (one step up below 30% stamina, two below 10%; shields, huge monsters, immunities, contract monsters), `skills/aard.ws` |
| Heavy knockdown 5 s, only heavy knockdowns allow finishers | SKL-08 | `HeavyKnockdownEffect`, `CBehTreeTaskCSEffect` |
| Firestream's burning (2.7% for 3 s), the slowdown defaults (35%, 7.5 s) | SKL-09, SKL-10 | `gm_effects.xml` |
| Confusion: 3 s minimum, +25% crit chance against the confused | SKL-12 | `ConfusionEffect`, `W3ConfuseEffect`; the crit term is read with blindness's in `GetCriticalHitChance` (`skills/oils.ws`): the larger of the two, as legacy |
| Blindness: crit chance against a blinded enemy (Samum +50/75/100%), its ability kept off the victim | ALCH-14 | `GMBlindnessCritBonus`, `W3BlindnessEffect` (`alchemy/bombs.ws`); the generic blindness (3 s) is 1.32's in all three |
| Northern Wind's freeze bonus (+25/35/50%) as a pool term, 5.x's separate frost hit removed | ALCH-14 | `damage/pool.ws`; the knockdown's removal and Aard's force damage are EFX-02's |
| Bomb burning and poison (1% per tick), no potion-duration bonus to bomb damage over time | ALCH-14 (DL7) | `effects.xml` bomb abilities, `W3DamageOverTimeEffect` and `W3CriticalDOTEffect.OnEffectAdded` |
| Heavy Artillery doubling only a damage over time's flat part | SKL-18 | `W3DamageOverTimeEffect.OnEffectAdded` |
| Crippling Strikes' bleeding (1% of max health per second for 8 s, resisted by bleeding resistance) and its bonus against bleeding enemies | SKL-03 | `skills/cripplingStrikes.ws`, from the skill's own values (not `BleedingEffect`) |
| Damage over time: no crits, no attack power, armor points ignored | DMG-02, DMG-03 | `damage/formula.ws`, `ProcessCriticalHitCheck` |
| Effect chances resisted (non-sign sources), effect durations not scaled by power | MUT-13, DMG-07 | `GetNonSignApplyBuffTest`, `CalculateDuration` |
| Ignition spreading the default burning | ENCH-13 | `W3Effect_Burning.OnUpdate` |
| Enhanced armor and weapon (Armorer's Table, grindstone: 30 min, +5% resistances; 10 armor penetration, +5%) | ITEM-12 | changelist 857–858 |
| Hypnosis immunity from Cat 3 | ALCH-07 | `W3Effect_Hypnotized.OnUpdate` |

**Not EFX** (confirmed by the owner with DX4, 2026-10-24):

| Subject | Area | Why |
|---|---|---|
| Which weapons and attacks carry an effect and with which chance: NPC weapons (Wild Hunt frost slowdown, bugfix 75; `def_item_npcweapons.xml`, e.g. `NPC Eredin Sword _Stats`), monster projectiles (`advancedProjectile.ws`: `projEfect` defaults, effect lengths 2 → 3 s), the ice spike's frost damage (`W3IceSpike.DealDamage`), monsters' effect resistances, the fiend's hypnosis length; also `CNewNPC.ReactToBeingHit` (flyers forced down), `OnFireHit` (Ice Armor), `ProcessShieldDestruction`, NPC Quen's stagger (`CBTTaskCastQuen.ProcessAction`) | AI | Enemy data; EFX sets what the effects do once applied |
| Bolts' effect chances (`blunt_bolt`, `broadhead_bolt`, `tracking_bolt`, `explosive_bolt` and their legendary versions) | XBOW | The bolts; their bleeding abilities are EFX-01's |
| Trophies' effect resistances (minion frost, forktail burning, wyvern poison, lamia bleeding) | TRPH | |
| Deadly enemies' blindness immunity (`CNewNPC.AddLevelBonuses`, `RemoveAllLevelBonuses`) | DIFF | Removed with the deadly-enemy bonuses |
| Hit reactions' severity (`ModifyHitSeverityReaction`, `ModifySeverity`: legacy no longer reduces hit reactions by `hit_severity`) | AI | Poise, with DMG's hand-off of the hit-severity half of `ModifyHitSeverityReactionFromDamage` (ported, AI slice B2) |
| The rotfiend explosion's damage (weapon damage, 300 if none) and the instant kill's cap (`GetLastBreathMaxAllowedDamage`) | AI | EFX-09 takes only the frozen exception |
| Releasing the sign-select keys when caught in a web (`ForceDeactivateCastSignHold`, `TestCastSignHold`) | OPT (instant casting) | Legacy's instant-casting option |
| Over-encumbrance blocking fast travel (`W3Effect_OverEncumbered`), the boat sinking (`W3Boat`) | WGT | |
| Geralt's base Vitality regen and its options (`W3Effect_AutoVitalityRegen`) | OPT, GEN | As FOOD recorded |
| Ciri's special attack (`W3ReplacerCiriStateCombatSword.SpecialAttackCleanup`: invulnerability, its immunity cleanup) | FIX | |

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

### Classification and action

| # | Feature | Class | Action |
|---|---|---|---|
| EFX-01 | Damage-over-time values | clean | Legacy's (PX1) |
| EFX-02 | Frozen hit | clean | Legacy's (DX2 (a)) |
| EFX-03 | Frozen pauses damage over time | clean | Legacy's |
| EFX-04 | Ticks | clean | Legacy's |
| EFX-05 | Frost slowdown, hypnosis | clean | Legacy's (PX2, PX3) |
| EFX-06 | Critical effects end | clean | Legacy's (PX4) |
| EFX-07 | Burning and hits | overlap (5.x changed it) | 1.32's, as legacy played (DX1 (a)) |
| EFX-08 | Resistance points | clean | Legacy's (PX6) |
| EFX-09 | Frozen rotfiend | clean | Legacy's (DX3 (a)), with 5.x's Northern Wind block kept |
| EFX-10 | Spider web | clean | Legacy's (PX9) |
| EFX-11 | Places of Power | in-5.x | Nothing to port; a scripted check (PX7) |
| EFX-12 | Debug log | clean | Not ported (PX5) |
| EFX-13 | NG+ immobilized | clean (if a DLC could override an effect entry) | Dropped (PX8) |

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
| Port status | **signed off** (2026-10-25), verified in both trees |
| Open checks | A real poison cloud not tested. (Real Tracking and Broadhead bolts verified by XBOW: 16 s at 0.5% and 8 s at 1% of maximum health per second, [xbow.md](xbow.md#xbow-01-bolts).) |
| Save impact | none (expected): effect abilities are read when an effect is applied |
| NG+ counterpart | applied (legacy's NG+ values), untested |

**What it does** (changelist 850–855): damage over time deals about the same total whatever the source, as a share of the victim's maximum health: bleeding 1% per second for 8 s (8%; 1.32: 0.8% for 10 s, 8%), a tracking bolt's bleeding 0.5% for 16 s (8%; 1.32: 0.1% for 30 s, 3%), a broadhead bolt's bleeding 1% for 8 s (1.32: a flat 10 plus 0.1–0.2% for 10 s), the critical poison (toxic clouds, gas, monsters' poison attacks) 1.6% for 5 s like the plain poison (1.32: 2%). Burning (2.7% for 3 s) and poison (1.6% for 5 s) are 1.32's. All of them block health regeneration, as in 1.32. Bleeding from swords, monsters and Crippling Strikes' own values (SKL-03, already legacy's) and the bolts' bleeding become comparable.

**Implementation (legacy):** the four abilities, regular and NG+.

**5.x:** 1.32's values. 5.x's `BleedingEffect1` to `3` (the Wolven set's wounds) use `BleedingEffect` as their default ability, so they would take the new values; nothing applies them since ARM-09 removed 5.x's Wolven rules. A bleeding's time left on Geralt is recalculated from his bleeding resistance whenever his abilities change (5.x's `RecalcDuration`).

**Decisions:** legacy's values (PX1, confirmed by the owner, 2026-10-24).

**Slices:**

1. **Effect values** (with EFX-05's data). Verified 2026-10-24, both trees: scripted (`GMTest_efx01`, in the regression) the four abilities' values, the broadhead bolt's flat part gone, 5.x's other attributes kept by `extend`; in play (`gmtest_efx01_apply`, scripted effects with Geralt as creator on the neutral test dummy) each effect deals its share per second for its time, 8% in all.

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
| Port status | **signed off** (2026-10-25), verified in both trees |
| Open checks | A bolt or a strong attack shattering a freeze; a fight with an enemy that fights back; NG+ |
| Save impact | none (expected) |
| NG+ counterpart | applied, untested |

**What it does** (bugfix 69 "Northern Wind bomb bugs and inconsistencies were fixed"; legacy's comment: "remove knockdown, make it to multiply the damage instead"): the hit of Geralt's that shatters a freeze (a sword, bolt or other physical or silver hit, or Aard) deals more damage and no longer knocks the enemy down: Northern Wind's freeze +25/35/50% (ported with ALCH-14), any other freeze +50% (the generic `FrozenEffect`: Piercing Cold's, which lasts 5 s instead of 4). An Aard hit on a frozen enemy also deals 5% of the enemy's maximum health as force damage. In 1.32 and 5.x the shattering hit knocks the enemy down (5.x's frost hit came on top; ALCH-14 removed it).

**Implementation (legacy):** `FrozenEffect` (regular, NG+); the frozen block of `W3DamageManagerProcessor.ProcessDamageIncrease` (the knockdown dropped, the force damage added).

**5.x:** 1.32's rule, with its separate frost hit of the bonus × the victim's health (removed by ALCH-14, whose pool term carries the bonus).

**Notes:** Aard's own knockdown roll (SKL-08) still applies to the enemy it unfreezes, as in legacy: only the freeze's extra knockdown is gone (5.x adds a second roll on a frozen enemy; the port has one). The force damage goes through the formula like Aard's other damage: Aard's intensity, force resistance, and the rule that the player's signs deal ×0.25 (level 1) to ×0.75 (from level 11) against Vitality (DMG, `damage/pipeline.ws`), so a level 1 Geralt's Aard takes 1.25% of a human's maximum health. When Piercing Cold freezes the enemy again with the same cast, its own 250 force damage is not dealt (MUT-04).

**Decisions:** legacy's frozen hit (DX2 (a), project owner, 2026-10-24).

**Slices:**

1. **The frozen hit** (with EFX-03). Verified 2026-10-24, both trees: scripted (`GMTest_efx02`, in the regression; `gmtest_efx02_scripted`) the freeze's values and bonus; real Aard casts (`autocast`, hit probe `gmtest_efx02_aard_a/b`), a real Piercing Cold freeze shattered by Aard, and real light attacks (`gmtest_efx02_light_a/b/c`) on the dummy frozen by the generic freeze and by Northern Wind 3: ×1.5 damage, Aard's force damage of 5% of maximum health, no knockdown, the freeze ended.

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
| Port status | **signed off** (2026-10-25), verified in both trees |
| Open checks | A damage over time applied while the enemy is already frozen keeps ticking (legacy's too: the pause is made when the freeze starts); not tested |
| Save impact | none (expected): pauses are by source name; a save made while an enemy is frozen is unlikely to matter |
| NG+ counterpart | none (scripts) |

**What it does** (changelist 856, ALCH's Northern Wind): while an enemy is frozen, its bleeding, poison and burning stop ticking and their timers stop; they resume when the freeze ends. A freeze no longer wastes a damage-over-time effect on an enemy who cannot be hurt by it longer, and a frozen enemy's regeneration was already paused (1.32).

**Implementation (legacy):** `W3EffectManager.PauseAllDoTEffects`, `ResumeAllDoTEffects` (new), `W3Effect_Frozen.OnEffectAdded`, `OnEffectRemoved`.

**5.x:** 1.32's (regeneration paused only).

**Notes:** a freeze ends burning instead of pausing it: `FrozenEffect` overrides (and denies) `BurningEffect` in `effects.xml`, 1.32's and legacy's data alike, so in play only bleeding and poison pause. The wrapper pauses only when the freeze is active after 5.x's `OnEffectAdded`; legacy paused inside it, also when the critical-state animation was refused, but such a freeze is removed at once and its removal resumes them, so nothing differs in play.

**Decisions:** port as legacy.

**Slices:**

1. **Pause while frozen** (with EFX-02). Verified 2026-10-24, both trees: scripted (`GMTest_efx02`, in the regression) the pause and resume by source; in play (`gmtest_efx03`, scripted effects on the neutral test dummy) a bleeding and a poison paused through a freeze and dealt their full 8% after it; a burning was ended by the freeze.

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
| Port status | **signed off** (2026-10-25), verified in both trees |
| Open checks | A tick reduced below 1 per second by a damage-over-time damage resistance (from the code: the floor comes before it) not tested in play |
| Save impact | none |
| NG+ counterpart | none |

**What it does:** each tick of bleeding, poison or burning damages only the stat the victim actually uses (Vitality for living things, Essence for specters and the like; 1.32 computed both and took the larger, so an effect flagged for both could count a victim's unused maximum), and deals at least 1 raw damage per second, so a small percentage on a weak enemy never rounds to nothing. The floor is the raw tick's: the damage-over-time damage resistances (`CDS_DoTBleedingDamageRes`, `CDS_DoTPoisonDamageRes`, `CDS_DoTBurningDamageRes`, which `GetResistForDamage` picks for a tick) still reduce it afterwards (from the code). The effect's own resistance (bleeding, poison, burning resistance) shortens the effect and does not reduce its ticks (1.32's, seen in play). The floor also reaches every other damage-over-time class, as in legacy: Mutated Skin's spread damage (MUT-10), the acid (`W3Effect_Acid`), Yrden's glyph health drain (`W3Effect_YrdenHealthDrain`, both trees), the wraiths' vitality drain, the swarm, the snowstorm, choking and drowning (from the code).

**Implementation (legacy):** `W3DamageOverTimeEffect.CalculateDamage`.

**5.x:** 1.32's.

**Decisions:** port as legacy.

**Slices:**

1. **Ticks** (with EFX-06). Verified 2026-10-24, both trees: scripted (`GMTest_efx04`, in the regression; `gmtest_efx04_calc` on a human and a wraith) the tick reads only the stat used and is at least 1 per second; in play (`gmtest_efx01_apply` on the neutral dummy, Vitality and Essence) the same, also with 50% effect resistance (shorter effect, same 1 per second).

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
| Port status | **signed off** (2026-10-25), verified in both trees |
| Open checks | A real frost attack (the Wild Hunt's, AI's) and the fiend's hypnosis not tested |
| Save impact | none (expected) |
| NG+ counterpart | applied, untested |

**What it does:** frost slowdown (the "freezing" chance of the Wild Hunt's swords, the Skellige sword, frost attacks on Geralt) lasts 7.5 s instead of 10 and is shortened by the victim's frost resistance (a Wild Hunt minion trophy's +50% frost resistance halves it on Geralt, TRPH). The slow itself is a fixed 30% in the code (`SetAnimationSpeedMultiplier(0.7)`, 1.32, legacy and 5.x); legacy's `slowdown` 0.35 (1.32: 0.5) is read by no script, so it changes nothing. Hypnosis lasts 5 s by default (1.32: 3 s); the fiend's hypnosis on Geralt passes its own length (1.32: 7 × its loop; 5.x: 20 s unless its behaviour tree says otherwise), so from the code the default is used only by sources that pass none (none found; unverified). Hypnosis's effect entry (and the witch's) names its resistance `will_resistance`, which 5.x does not know: will resistance shortens hypnosis only with EFX-08.

**Implementation (legacy):** `SlowdownFrostEffect`, `HypnotizedEffect` (regular, NG+), `W3Effect_SlowdownFrost.<members>`.

**5.x:** 1.32's.

**Decisions:** port as legacy (PX2, PX3, confirmed by the owner, 2026-10-24).

**Slices:**

1. **Values and frost resistance** (with EFX-01). Verified 2026-10-24, both trees: scripted (`GMTest_efx01`, in the regression) frost slowdown 7.5 s, halved at +50% frost resistance, hypnosis 5 s; the same durations seen in play on the neutral dummy (`gmtest_efx01_apply`).

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
| Port status | **signed off** (2026-10-25), verified in both trees |
| Open checks | A knockdown on an enemy moving normally getting up at its end, and a knockdown in mid-air (no wait for the landing, PX4), not watched in play; Geralt's own critical states not tested |
| Save impact | none |
| NG+ counterpart | none |

**What it does** (bugfix 173): a critical effect (knockdown, heavy knockdown, ragdoll, burning, stagger, freeze and the others) ends when its time runs out, whether or not its animation is still playing; the request to stop the animation moves to the effect's removal. In 1.32 an expired effect waited for its animation to stop and stayed active if the animation had been interrupted the wrong way, so its damage over time could tick forever; a damage-over-time effect also stops ticking once inactive or expired. Side effects of legacy's rewrite, kept: a knockdown no longer stays active until a victim in mid-air lands (the stop is asked with the in-air flag at removal), and the `DisableFinisher` signal 1.32 sent at the end of a critical effect is gone (SKL-08 already ignores that event: only heavy knockdowns allow finishers).

**Implementation (legacy):** the five `OnTimeUpdated`, the three `OnEffectRemoved`, the check in `W3DamageOverTimeEffect.OnUpdate`.

**5.x:** 1.32's code (only whitespace and the controller vibration changed).

**Decisions:** port as legacy (PX4, confirmed by the owner, 2026-10-24).

**Slices:**

1. **End on time** (with EFX-04). Verified 2026-10-24, both trees: scripted (`GMTest_efx04`, in the regression) an expired tick caches no damage; in play, on the frozen dummy whose animations never end (bugfix 173's case), scripted critical effects (`gmtest_efx01_apply`) and the knockdown and staggers of real Aard casts (`gmtest_efx06_watch`) each ended at their time.

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
| Port status | **signed off** (2026-10-25), verified in both trees |
| Open checks | A burning enemy with a second critical effect queued (from the code: the hit then moves the burning to the background instead of ending it); Dancing Star, Dragon's Dream, fire swords and Ignition's burning not tested (the rule is the effect's, whatever the source); not checked in regression (the checks need an NPC) |
| Save impact | none (expected): `allowedHits` is a saved field; an enemy burning in a save keeps 5.x's array until its burning ends |
| NG+ counterpart | none |

**What it does:** burning stuns: the victim flails in the burning animation ("stunlocks", changelist 854). In 1.32 and legacy any hit but Igni's plays its hit reaction, which breaks the flailing at once, and with it **the burning ends**: when the hit reaction stops the critical-state animation, the game removes the critical effect it was playing if no other critical effect waits (`CBehTreeTaskCriticalState.OnDeactivate`, `CActor.CriticalStateAnimStopped`, 1.32's and 5.x's code; seen in play: the burning's damage stops with the flailing). So a burning enemy takes its burning damage until the first hit that is not Igni's. Igni's hits (a second cast at a burning enemy) play no reaction and leave it flailing. 5.x makes a burning enemy ignore hits' reactions for the first half of its burning (1.5 s of the 3 s), so Igni, Dancing Star, Dragon's Dream, Ignition and fire swords give a guaranteed window of free hits. Legacy's burning (33% chance from Igni, independent of intensity, SKL-09) was balanced on 1.32's rule. The changelist's numbers (2.7% for 3 s) are 1.32's and 5.x's: no value to port. Legacy's one change here, in `CBehTreeTaskCriticalState.OnListenedGameplayEvent`, is a commented-out idea (`AvoidBurnCS`): no behaviour change.

**Implementation (legacy):** none with behaviour (the comment above).

**5.x:** `W3Effect_Burning.CacheSettings` (no hit allowed on an NPC) and `OnUpdate` (every hit but Igni allowed from half the duration).

**Decisions:** 1.32's and legacy's rule, 5.x's window removed (DX1 (a), project owner, 2026-10-24). The hit that breaks the flailing also ends the burning (the game's shared critical-state code, above): confirmed and kept by the project owner (2026-10-24), after being offered 5.x's 1.5 s window and a variant where the flailing breaks and the fire keeps burning. Legacy's rule, so not a deviation.

**Slices:**

1. **Burning and hits.** Verified 2026-10-24, both trees: scripted (`gmtest_efx07_scripted`) every hit reaction but Igni's allowed from the start; in play (`gmtest_efx07_a` on the unfrozen dummy, real Igni casts and light attacks) a sword hit in the burning's first half broke the flailing and ended the burning, a second Igni cast left it flailing.

### EFX-08 Effect resistance points

| | |
|---|---|
| Kind | fix |
| Pillars | P5 |
| 5.x class | clean |
| Flags | — |
| Depends on | DMG-02 (resistances, signed off; its registration of the points in `all_NPC_ability`/`all_PC_ability`) |
| Skill trees | n/a |
| Port form | `effects/resistNames.ws`: `@wrapMethod` of the global `ResistStatNameToEnum` and `ResistStatEnumToName`: `bleeding_resistance`, `will_resistance`, `burning_resistance` as point resistances, after 5.x's names |
| Port status | **signed off** (2026-10-25), verified in both trees |
| Open checks | The fiend's and the witch's real hypnosis on Geralt not tested (scripted hypnosis on the test dummy) |
| Save impact | none |
| NG+ counterpart | none |

**What it does:** the point (flat) resistance names of bleeding, will (Axii) and burning are recognised, so abilities giving such points would count, as for the other resistances. In 5.x's data every such point value is 0 (`opp_base_abl.xml`'s `bleeding_resistance` entries, a Hearts of Stone monster's `burning_resistance`) and legacy's own are registrations (`common_abilities.xml`, mult 1) or 0 (`monster_base_abl_new.xml`, `opp_base_abl.xml`'s `will_resistance`): no play difference from the point values. **But** effect entries name their resistance by these names (`resistStatName_name`), and an unknown name gives the effect no resistance at all, overriding the class's own: hypnosis and the witch's hypnosis name `will_resistance`, so in 5.x will resistance does not shorten them; with EFX-08 it does (legacy's behaviour). The other entries name known point resistances (`frost_resistance`, `force_resistance`, `shock_resistance`).

**Implementation (legacy):** `ResistStatNameToEnum`, `ResistStatEnumToName` (attributed to DMG-02 too).

**5.x:** 1.32's (the percentage names only).

**Decisions:** port as legacy (PX6, confirmed by the owner, 2026-10-24).

**Slices:**

1. **Point names.** Verified 2026-10-24, both trees: scripted (`GMTest_efx08`, in the regression) the three names read and named back, hypnosis's entries now read as will resistance; in play (`gmtest_efx08_points`, `gmtest_efx01_apply` on the neutral dummy) 10 points of each count, and a scripted hypnosis lasts 3 s at 40% will resistance (5.x: 5 s).

### EFX-09 Killing a frozen rotfiend

| | |
|---|---|
| Kind | system, fix |
| Pillars | P5 |
| 5.x class | clean (5.x adds Northern Wind's `PoisonDeath` block, kept by ALCH's DL7) |
| Flags | shared with AI (DX3) |
| Depends on | EFX-02 (`SetWasFrozen` on the shattering hit), DMG (`CActor.ReduceDamage` in `damage/pipeline.ws`, `ProcessInstantKill`), AI (the explosion's damage) |
| Skill trees | n/a |
| Port form | in the port's existing replacements: `CActor.ReduceDamage` (`damage/pipeline.ws`: LastBreath does not cap a frozen hit), `CActor.OnTakeDamage` (`mutations/takeDamage.ws`: a LastBreath monster killed by a frozen hit gets the tag `ExplodeNoDamage`); `@replaceMethod(BTTaskExplodeAtDeath)` `Explode` (`effects/frozenRotfiend.ws`: no damage with the tag; the explosion's damage legacy's since AI-17: the monster's weapon damage, 300 without one). LastBreath's cap on instant kills, with its frozen exception, is AI-17's (`GMGetLastBreathMaxAllowedDamage` in the replaced `ProcessInstantKill`): an instant kill on a frozen rotfiend kills it outright, and the tag covers its explosion |
| Port status | **signed off** (2026-10-25), verified in both trees |
| Open checks | The no-damage explosion only by a scripted `Death` signal: no real death ran the explosion in 5.x (Notes); a frozen rotfiend killed by an instant kill or a bolt not tested |
| Save impact | none |
| NG+ counterpart | none |

**What it does** (changelist, Enemy AI: "Killing a frozen rotfiend now prevents the explosion. Freezing a rotfiend that is about to explode also stops the explosion"): monsters with the `LastBreath` ability (rotfiends) cannot be killed by a hit: at low health they start their death explosion. A hit on a frozen one is not held back: it can kill it outright, and its explosion then deals no damage. The second sentence has no code of its own in legacy (from the code; maybe vanilla's freeze stopping the explode behaviour): on the [list to test](../open-questions.md#to-test-in-legacy-ghost-mode). 5.x's Northern Wind blocks `PoisonDeath` (a rotfiend frozen by it does not explode at all; ALCH-14, kept).

**Implementation (legacy):** `CActor.OnTakeDamage` (the tag), `CActor.ReduceDamage` and `ProcessInstantKill` (`!GetWasFrozen()`), `BTTaskExplodeAtDeath.Explode` (the tag; its damage formula is AI's).

**5.x:** 1.32's LastBreath, plus the `PoisonDeath` block.

**Notes** (from the code and tests in 5.x): a rotfiend at 25% health, or hit below it, holds the hit back to 25% (`lastbreath_threshold`), signals `LastBreath`, swells (no hit reactions, a self-drain of 10% of its maximum per second) and dies of the drain about 2.5 s later; below 40% it may also start swelling on its own. Its damaging explosion is `BTTaskExplodeAtDeath` (radius 2.75 m), which runs when its task hears the gameplay event `Death`; **in 5.x no real death ran it** (swelling to death, killed during the swelling or outright, with Ghost Mode on or off): only an explicit `SignalGameplayEvent('Death')` did. So in 5.x the explosion's damage, and EFX-09's removal of it, are not seen in play; whether 1.32 and legacy delivered `Death` is on the [list to test](../open-questions.md#to-test-in-legacy-ghost-mode). What EFX-09 changes in play: a frozen rotfiend is killed outright by the shattering hit instead of swelling.

**Decisions:** ported with EFX (DX3 (a), project owner, 2026-10-24); the explosion's damage is legacy's since AI-17 ([ai.md](ai.md#ai-17-instant-kills-and-lastbreath)): the weapon's damage (a rotfiend's claws 350) or 300, with attack power and armor (5.x: 150 + 4× on Hard).

**Slices:**

1. **Frozen rotfiend.** Verified 2026-10-24, both trees (a spawned rotfiend as the test dummy, `gmtest_efx09_spawn`, `gmtest_efx09_a`, `_b`): a real light attack on it frozen by a real Piercing Cold Aard or a real Northern Wind throw killed it outright (no LastBreath, tagged `ExplodeNoDamage`); unfrozen it was held back to 25% and swelled. Scripted (`gmtest_efx09_death`): the explosion run by a `Death` signal damages Geralt untagged and not tagged. Not in the regression (the checks need an NPC).

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
| Port status | **signed off** (2026-10-25), verified in both trees |
| Open checks | A real arachas's web projectile not tested (the web added by script as the projectile adds it); not compared with a build without the wrapper |
| Save impact | none |
| NG+ counterpart | none |

**What it does** (bugfix 181 "sign casting not being properly aborted when the player gets caught into a spider web"): an arachas's web stops the sign Geralt is casting. Legacy also releases the sign-select keys of its instant-casting option (`ForceDeactivateCastSignHold`, `gm_input.ws`).

**Implementation (legacy):** `W3Effect_Tangled.OnEffectAdded`.

**5.x:** 1.32's.

**Notes** (from the code, seen in play): `AbortSign` aborts the sign entity in its cast (Aard, Igni, Yrden, Axii: the entity is destroyed before the sign goes off) and ends a channel (Firestream to `Finished`). Quen's entity ignores the abort while it casts (`W3QuenEntity.OnSignAborted` is empty, 1.32, legacy and 5.x), so a web during a Quen cast still raises the shield; and a web projectile hitting Geralt while Quen is up does not entangle him at all (`W3AdvancedProjectile`: Quen takes the hit instead). `AddEffectDefault(EET_Tangled)` without a creator is denied.

**Decisions:** port as legacy (PX9, confirmed by the owner, 2026-10-24). The select keys are OPT's: instant casting is 5.x's "Quick Sign Casting" (DO5), and while it is on the web also releases the five sign-select keys (`options/instantCasting.ws`, a second wrapper of `W3Effect_Tangled.OnEffectAdded`; OPT-06's PO13, verified there); 5.x's release of `CastSignHold` stays.

**Slices:**

1. **Web aborts the sign.** Verified 2026-10-24, both trees (real sign casts through the cast input, `gmtest_efx10`, `gmtest_efx10_web`; the web added by script with the arachas dummy as creator): Aard, Igni, Yrden and Axii aborted, a held Firestream channel ended (classic `S_Magic_s02`, new tree `S_Magic_s28`), Quen's shield went up.

### EFX-11 Places of Power

| | |
|---|---|
| Kind | tuning (none) |
| Pillars | P7 |
| 5.x class | in-5.x |
| Flags | — |
| Depends on | DMG-06 (the sign intensity curve, signed off), SKL-18 (Gorged on Power, signed off) |
| Skill trees | n/a (Gorged on Power, classic `perk_14` only, is SKL-18's) |
| Port form | nothing; a scripted check of the five `Shrine*Effect` abilities in the regression |
| Port status | **signed off** (2026-10-25): nothing to port; `GMTest_efx11` in the regression, both trees |
| Open checks | — |
| Save impact | none |
| NG+ counterpart | none |

**What it does** (changelist 859): a Place of Power gives +20% to its sign's intensity for 30 minutes. These are 1.32's values, which legacy kept (its only change is a comment) and 5.x keeps; 5.x only adds an achievement counter and a branch for `perk_36` (Gorged on Power: +30 min and one more buff at a time per level), whose ability exists but whose `<skill>` entry is commented out in `geralt_skills.xml`, so neither tree offers it.

**Decisions:** nothing to port (PX7, confirmed by the owner, 2026-10-24).

**Slices:**

1. **Check.** Verified 2026-10-24, both trees (scripted, `GMTest_efx11`, in the regression): the five `Shrine*Effect` abilities give +20% for 1800 s, and each effect added to Geralt carries them.

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
| Port form | none: a DLC cannot override an `<effect>` entry |
| Port status | dropped (PX8, owner, 2026-10-24) |
| Open checks | — |
| Save impact | none |
| NG+ counterpart | this is one |

**What it does:** in New Game+ the immobilized effect loses Axii's stopping visual (`targetEffectName` `axii_stopping` → empty), as in the regular game's 1.32 data. 5.x's files are 1.32's.

**Decisions:**

- **Deviation:** not ported: in New Game+ the immobilized effect keeps 5.x's (1.32's NG+) Axii stopping visual, where legacy's NG+ data removed it. A DLC cannot override an `<effect>` entry: its entry is added after vanilla's, with or without `on_conflict`, and the effect reads only the first entry of its name, vanilla's; the alternative would be a whole-file override of 5.x's NG+ `effects.xml` for one visual in an untested mode (PX8: "record as a deviation if it doesn't work"; owner, 2026-10-24).

Shown by probe builds (`gmtest_efx13_probe`, not kept): a DLC `ImmobilizedEffect` entry, plain or with `on_conflict="replace"`, lands after vanilla's in the merged `<effects>`, and `CBaseGameplayEffect.CacheSettings` returns after the first entry of its type.

---

### Dependencies on other areas

- **Done areas EFX builds on:** DMG (`damage/pool.ws`, `damage/pipeline.ws`, formula rules for damage over time), ALCH-14 (the freeze bonus, blindness), SKL-08 (severity, finishers), SKL-09, SKL-10, SKL-12, SKL-18 (effect values and damage-over-time hooks), MUT-04 (Piercing Cold's freeze), ENCH-13 (burning's replaced methods), ITEM-12 (enhanced armor and weapons).
- **Areas EFX shares with:** AI (who applies effects, monster resistances, the rotfiend explosion's damage, hit-reaction severity), XBOW (bolt effect chances), TRPH (trophy resistances), OPT (instant casting, for EFX-10's select keys), DIFF (deadly enemies' immunity).

### Tests

The EFX regression checks (`GMTest_efx01`, `_efx02`, `_efx04`, `_efx11`) save Geralt's effects of the types they touch (the Places of Power buffs, frost slowdown, bleeding and its regen block) and put them back afterwards with their time left, value, source and creator (`GMTestEfxSaveBuffs`, `GMTestEfxRestoreBuffs`, `tests/gmTestsEfx.ws`). Other areas' checks that end Geralt's bleeding, frost slowdown or regen block by the effect they test (SKL's Undying and Cleansing, ALCH-04's Swallow) are left as they are (owner, 2026-10-25).

### Save impact

None expected: effect abilities are read when an effect is applied, the replaced methods live; burning's `allowedHits` is saved (EFX-07: an enemy burning in a save keeps 5.x's array until the burning ends). Adding or removing the mod mid-playthrough is not supported ([save compatibility](../feature-mapping.md#save-compatibility)).

### Area decisions

**Decided** (project owner, 2026-10-24):

- **DX1 (a):** 1.32's and legacy's burning rule: any hit but Igni breaks a burning enemy's flailing at once; 5.x's window of ignored hit reactions is removed (EFX-07). Legacy's Igni (33% burn chance) and the fire bombs were balanced on it; 5.x's window is a large buff to every burning source. The hit also ends the burning: confirmed and kept (project owner, 2026-10-24).
- **DX2 (a):** legacy's frozen hit: the shattering hit gets the freeze's bonus and no knockdown, Aard adds 5% of the enemy's maximum health as force damage, the generic freeze lasts 5 s with +50% (EFX-02).
- **DX3 (a):** the frozen rotfiend is ported with EFX (EFX-09); the explosion's own damage is AI's.
- **DX4:** the boundary as in [Scope](#scope), confirmed.
- **PX1 to PX7, PX9, PX10:** confirmed as proposed (below).
- **PX8:** confirmed as proposed ("go ahead and test the new game + change, and record as a deviation if it doesn't work"): a DLC cannot override an `<effect>` entry, so EFX-13 is dropped as a deviation ([EFX-13](#efx-13-ng-immobilized-look)). The project-wide [New Game+ policy](../feature-mapping.md#new-game-carried-over-and-scaled-not-balanced-or-tested) is unchanged (owner, 2026-10-24): EFX-01's, EFX-02's and EFX-05's NG+ copies are generated by `gen_ngplus.py`.

**Porter's calls** (confirmed by the owner, 2026-10-24; each follows legacy or has no play effect):

| # | Call |
|---|---|
| PX1 | EFX-01: legacy's bleeding and critical poison values; they also reach 5.x's three Wolven bleeding types, which nothing applies (ARM-09) |
| PX2 | EFX-05: frost slowdown 7.5 s, shortened by frost resistance; legacy's `slowdown` 0.35 carried though no script reads it (the slow stays a fixed 30%, as in legacy) |
| PX3 | EFX-05: hypnosis's default 5 s carried; the fiend passes its own length, so it is likely inert; the fiend's 5.x length is AI's |
| PX4 | EFX-06: legacy's end rule with its side effects (no wait for a mid-air knockdown to land; no `DisableFinisher` signal at the end) |
| PX5 | EFX-12: `toggledebugdot` and `PauseSources` not ported, as DMG-14's debug messages and ALCH-18's `toggledebugoils` (a deviation of a debug tool) |
| PX6 | EFX-08: the point names ported; no play effect from point values (5.x's data has no non-zero point value). Its one play effect: will resistance shortens hypnosis again (the fiend's and the witch's on Geralt), as legacy |
| PX7 | EFX-11: nothing to port for the Places of Power; a scripted check of the five buffs' +20% and 30 min |
| PX8 | EFX-13: try the NG+ `<effect>` override from the DLC; if a DLC cannot override effect entries, drop it as a deviation (NG+ only, a visual; NG+ is not tested) |
| PX9 | EFX-10: the web aborts the sign; the sign-select keys of legacy's instant casting are released when that option is ported (done by OPT) |
| PX10 | Attribution: the units the mapping found ported by other features are attributed to them (blindness to ALCH-14, the Elemental decoction's resistance block to ALCH-13, the Axii slowdown class to SKL-12, the negative-immunity removal to SKL-07, the finisher event to SKL-08); no code change |

**Later:** —
