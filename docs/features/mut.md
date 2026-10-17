# MUT: mutations

Blood and Wine's late-game progression: twelve mutations researched with skill points and greater mutagens, one active at a time, and four extra skill slots unlocked by the number researched. Ghost Mode reworked ten of them, retuned the other two, replaced Second Life with Life Leech (activated by a new potion, the Mutation Catalyst) and cut the research costs. Source: the changelist's "Mutations" section ([legacy-FullChangelist.txt](../legacy-FullChangelist.txt), around line 1021) and the mutation bug fixes.

Mutations are part of player power: balance them with [balance.md](balance.md) and the [ledger](ledger/mutations.md). Their texts at base stats are in both [tree files](../skill-trees/).

**How legacy Ghost Mode implements it.** The research tree and costs are `<custom><mutations>` in `dlc/bob/.../geralt_mutations.xml`, the values the abilities `Mutation1` to `Mutation12` in the same file, effect values in `effects_ep2.xml`. Code: the effect classes in `scripts/game/gameplay/effects/effects/mutations/`, hooks in the damage manager, `playerWitcher.ws`, `npc.ws`, `r4Player.ws` and the sign scripts; tooltips filled by `W3PlayerWitcher.GetMutationLocalizedDescription`.

**What 5.x did in this area.** Little: Piercing Cold's freeze chance now depends on adrenaline and spares three bosses, Toxic Blood's acid is doubled, Second Life's cooldown is 120 s, Metamorphosis allows 5 decoctions, and the new tree's character menu has its own copy of the mutation panel. Research costs and the tree are unchanged.

Unit lists: [attribution.csv](attribution.csv): mapped 2026-10-05 from the changelist and a sweep of every unit naming a mutation, its effects, the Catalyst or the mutation XML: 203 units (153 script, 50 XML; 53 of them shared with other features) plus 135 description rows (15 strings × 9 languages). Port status: not started; everything below is from reading the code (not tested in game). Not covered by the sweep and worth a look when porting: vanilla's Metamorphosis triggers in `criticalEffect.ws`, `dotEffect.ws`, `slowdown.ws`, `slowdownFrost.ws` (now calling the emptied `AddMutation12Decoction`); 5.x-only units the port merges with (`W3AardProjectile.CheckFrostEffect`, `W3DamageAction.IsMutation2PotentialKill`, `W3PlayerAbilityManager.GetStaminaActionCostInternal`, the `CR4CharacterDupeMenu` mutation functions). Row 2110992548 ("Crossbow bolts deal $F$ pts more base damage.", unknown key) sits among the mutation strings and is probably XBOW's: check before attributing.

## The research tree

The research tree (prerequisites, colours, mutagen costs, the 2/4/8/12 thresholds of Strengthened Synapses) is **identical in 1.32, legacy GM and 5.x**:

| Tier | Blue | Red–blue | Red | Red–green | Green |
|---|---|---|---|---|---|
| 1 | M2 Magic Sensibilities | | M8 Deadly Counter | | M4 Toxic Blood |
| 2 | M6 Piercing Cold (M2) | | M3 Bloodbath (M8) | | M10 Euphoria (M4) |
| 3 | M1 Conductors of Magic (M6) | M7 Adrenaline Rush (M6 + M3) | | M9 Cat Eyes (M3 + M10) | M5 Mutated Skin (M10) |
| 4 | | M11 Second Life / **Life Leech** (M7) | | M12 Metamorphosis (M9) | |

(M1 and M5 are two-coloured; M11 and M12 are red, blue and green.) The layout is derived from the prerequisites (the panel's coordinates are in its Flash file).

Costs (skill points; red/blue/green greater mutagens):

| | M1 | M2 | M3 | M4 | M5 | M6 | M7 | M8 | M9 | M10 | M11 | M12 | Total SP |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Mutagens R/B/G | 2/3/0 | 0/2/0 | 3/0/0 | 0/0/2 | 2/0/3 | 0/3/0 | 2/3/0 | 2/0/0 | 2/0/3 | 0/0/3 | 3/2/2 | 2/2/3 | |
| SP 1.32 and 5.x | 5 | 2 | 3 | 2 | 5 | 3 | 5 | 2 | 5 | 3 | 7 | 7 | 53 |
| SP legacy GM | 3 | 1 | 2 | 1 | 3 | 2 | 3 | 1 | 3 | 2 | 4 | 4 | 29 |

Ghost Mode's skill-point cut is not in the changelist.

## Changes at a glance

### What Ghost Mode changed

| # | Mutation | Vanilla 1.32 | Legacy GM | Units (main) |
|---|---|---|---|---|
| 1 | Conductors of Magic | Sign damage + 50% of the held sword's raw damage attribute (quality ≥ 3) | 30%, computed from the sword's total base damage (`GetTotalWeaponDamage`, GM's weapon damage incl. upgrades); Invigoration (Runeword 4) also consumed by Sign hits with M1 | XML `Mutation1`; `ProcessDamageIncrease`; `OnProcessActionPost` (Runeword 4, ENCH) |
| 2 | Magic Sensibilities | crit chance 20% + 10% × SP, crit damage 100% × SP (30%/100% at SI 0%) | Uses GM's SI→power-bonus curve B (`SignPowerStatToPowerBonus`, 0 at SI 0, 0.75 at 100%, 2.0 at ≥ 500%): chance 5% + 40% × B (5% → 85%), crit power 25% + 187.5% × B (25% → 400%) | XML `Mutation2`; `GetAttackersPowerMod`, `ProcessCriticalHitCheck`, tooltip |
| 3 | Bloodbath | +5% AP per melee hit (max 250%), lost on any damage taken | Combat start: +10% AP per sword-path skill and +5% per other skill equipped (unlocked slots); a hit removes 0.5% per 1% of max Vitality lost; a kill restores the bonus to its peak and adds +20%; max 250%; reset at combat end. Finisher/dismember on sword kills kept | XML `Mutation3` (new attributes); `W3Effect_Mutation3` (rewritten: `InitVars`, `CalcInitialNumAbl`, `SetAbls`, `AddAbls`, `RemoveAbls`, `ManageMutation3Bonus`); callers `CNewNPC.OnDeath`, `W3PlayerWitcher.OnTakeDamage`, `OnCombatStart`; old trigger removed from `OnProcessActionPost` |
| 4 | Toxic Blood | Attacker gets acid DoT = 1.5% of the damage dealt per toxicity point (3 s); vampires: −20% stamina regen, −2000 essence regen | Acid DoT independent of damage: 1.5 × current toxicity per second for 5 s (melee hits within 3 m, 6 m vs huge); every attacker gets −10% stamina regen while it runs; toxicity decay −50% | XML `Mutation4` (new), `AcidEffect`, `Mutation4BloodDebuff`; `ProcessActionMutation4ReturnedDamage`, `W3Effect_Acid.OnEffectAdded/Removed`, `W3Effect_Toxicity.OnUpdate` (decay), `W3Effect_Mutation4`, `AddCharacterStatToxicity`; `CNewNPC.RemoveMutation4BloodDebuff` removed |
| 5 | Mutated Skin | −15% damage taken per adrenaline point (max −45%) | Incoming damage (not DoT, ≥ 1 adrenaline) is turned into a DoT over 5 s per adrenaline point (max 15 s); adrenaline drains 1 pt / 5 s meanwhile; at 0 adrenaline the rest lands at once; repeated hits re-spread the remainder | XML `Mutation5`, `Mutation5Effect`; `W3Effect_Mutation5` (now a DoT effect); `W3PlayerWitcher.ReduceDamage` (old code removed), `OnTakeDamage` (trigger), `CActor.OnTakeDamage` (skips the drain), `W3DamageAction.Set/GetMutation5Triggered` |
| 6 | Piercing Cold | 25% freeze chance, else frost slowdown; frozen + knocked down = instant kill; non-frozen take 1500 force damage (added to the Aard action) | 30% × (1 − target frost resistance), not mid-air, not instant-kill-immune; no slowdown branch; non-frozen take 250 force damage in a separate action scaled by SI, plus a knockdown test; Shock Wave damage now dealt by the Aard hit itself (changelist bug fix "Aard Shockwave and Piercing Cold") | XML `Mutation6`; `W3AardProjectile.ProcessMutation6`, `ProcessCollision` (SKL-08), `CNewNPC.OnAardHit`, tooltip |
| 7 | Adrenaline Rush | Combat start vs several enemies: +30% AP/SI per extra enemy for 30 s, then −10% per enemy (max −70%) for 30 s | Endless 30 s cycle while in combat: Rush (adrenaline gain ×2, +50% AP and SI per current adrenaline point) and Recovery (gain ÷2, −50% per adrenaline point gained during Rush); debuff cannot be cleansed | XML `Mutation7Buff/Debuff`; `W3Effect_Mutation7Buff/Debuff`, `W3Mutation7BaseEffect` (rewritten); adrenaline gain ×2/÷2 in `OnProcessActionPost` (melee, bolts, Perk 18 bombs) and `W3SignEntity.ManageFocusGain`; `CActor.IsImmuneToBuff`, `AddBuffImmunity_AllNegative`; stats popup; `Mutation7CombatStartHackFix(Go)` removed |
| 8 | Deadly Counter | +25% sword damage vs monsters and counter-immune humans; counter vs humans < 25% Vitality → finisher | A countered enemy (DEF-07 per-enemy flag) at ≤ 15% health dies with a finisher/dismemberment (any enemy type that allows it; humans via repel-to-finisher in the counter, not bosses); melee damage vs a countered enemy +33.3% per adrenaline point (+100% at 3); the flat +25% removed | XML `Mutation8`; `CheckMutation8Finisher`, `CleanupMutation8Finisher`, `InitializeActionVars`, `ProcessActionReaction`, `ProcessDamageModification`, `CanPerformFinisher`/`CanDismember` paths, `CNewNPC.IsImmuneToMutation8Finisher`, `Mutation8RepelToFinisherImmune`, `CR4Player.PerformCounterCheck` |
| 9 | Cat Eyes | +150 bolt damage, +50% crossbow crit chance, 15% Vitality loss at full health, pierce, stun/knockdown | Bolt base damage ×2; full-health 15% loss, pierce, stun/knockdown kept; +25% aiming slow-motion while toxicity > 0; crit chance and flat damage removed | XML `Mutation9`; `ProcessDamageIncrease`, `GetOffenseStatsList`, `GetTotalWeaponDamage`, `PlayerAimingStateAiming.SloMo`, `GetEquippedCrossbowDamage` |
| 10 | Euphoria | +0.75% sword damage and SI per toxicity point (75% at 100) | Active only while overdosed and in combat: overdose drain × (1 + 0.75 × toxicity/100); that per-second drain is added to base sword and Sign damage. Fixes: triggering at combat start and after decoctions, double application, FX spam on alternate casts | XML `Mutation10Effect` (`mutation10_factor`); `W3Effect_Mutation10`, `W3Effect_Toxicity.OnUpdate`, `GetToxicityDamage` (new), `ProcessDamageIncrease`, `GetOffenseStatsList`, `AddCharacterStatSigns`, `OnCombatStart`, `OnMutationEquippedPost`; `ApplyMutation10StatBoost` removed (also out of `GetPowerStatValue`, `GetTotalSignSpellPower`) |
| 11 | Second Life → **Life Leech** | At 0 Vitality: full heal, brief invulnerability, Quen shock wave; 180 s cooldown | Activated by drinking the new **Mutation Catalyst** potion in combat: drains up to 3 hostile enemies within 30 m for 6 s (drain/s per enemy = (sword base damage + average AP% + average SI%) × adrenaline ÷ enemies, at least 1) and heals as much; immortal and free Quen while active; ends with a 5 m knockdown impulse (40 shock damage); 90 s cooldown. Death trigger removed (Undying is the death-save) | XML `Mutation11` (Force→Shock damage), `Mutation11BuffEffect`, `Mutation11DebuffEffect` (90 s); `W3Effect_Mutation11Buff` (rewritten: `AddDrainBuff`, `PlayDrainEnergy`, `OnUpdate`, `Impulse`), `Mutation11GetBaseStrength` (new), `OnMutation11Triggered`, `Mutation11ShockWave`, `OnTakeDamage` (trigger removed), Quen and channelling units; potion: item `Mutation Trigger`, `MutationTrigger_stats` (3 charges, 20 toxicity), `MutationTriggerEffect`, recipe (White Gull 1, Rubedo, Nigredo, Vampire blood), `W3Potion_MutationTrigger`, recipe granted in `OnMutationFullyResearched` and on load (`OnSpawned`) |
| 12 | Metamorphosis | Critical effects activate a random decoction for 120 s at no toxicity (max 3) | Up to 3 decoctions drunk normally cost no toxicity; each active free decoction multiplies critical-effect chances of swords and Signs by 1 + 0.1 × n (max ×1.3); random trigger emptied | XML `Mutation12`; `Mutation12GetBonus`, `Mutation12FreeDecoctionAvailable` (new), `AddMutation12Decoction` (emptied), `DrinkPreparedPotion`, `HasFreeToxicityToDrinkPotion`, `ToxicityLowEnoughToDrinkPotion`; chance hooks in `GetSignApplyBuffTest`, `GetNonSignApplyBuffTest`, `W3Effect_KnockdownTypeApplicator.OnEffectAdded`, `ProcessOnBeforeHitChecks`, `ProcessActionReaction`; stats popup |
| — | System | — | Research skill-point costs cut (53 → 29); current mutation's sound bank reloaded on load (`LoadCurrentMutationSoundBank`, changelist bug fix); `GetMutationsUsedMutagens` + `Debug_RestoreMutagensSpent` (refund in the debug respec, SKL D44); skill slots of mutation colours fixed (SKL-01); new descriptions for all 12 (15 strings × 9 languages) and tooltip arguments | `custom/mutations`; `PlayerAbilityManager` units; `GetMutationLocalizedDescription`; localization rows |

### What 5.x changed

| # | Mutation | 5.x change (from code) |
|---|---|---|
| 1 | Conductors of Magic | none |
| 2 | Magic Sensibilities | crit-kill explosion also for a supercharged Sign (`IsMutation2PotentialKill`, new-tree mechanic) |
| 3 | Bloodbath | none |
| 4 | Toxic Blood | acid doubled: `AcidEffect.DirectDamage` 0.005 → 0.01 (3% of the damage per toxicity point) |
| 5 | Mutated Skin | none |
| 6 | Piercing Cold | freeze chance now **adrenaline × 10%** (0–30%; XML 0.25 → 0.3 only feeds the tooltip); no freeze with a supercharged Aard; no instant kill on Eredin, Imlerith, Caranthir; Aard calls `OnFrostHit` (`CheckFrostEffect`); Shock Wave damage in the M6 path rewritten (classic `magic_s06` % of victim Vitality, new `magic_s33`); new description string mentioning adrenaline; Mutation 6 sound bank reloaded on spawn |
| 7 | Adrenaline Rush | interplay with Delayed Recovery (`alchemy_s3`): above its toxicity threshold M7 denies Blizzard's level-3 stamina bonus (`GetStaminaActionCostInternal`) |
| 8 | Deadly Counter | none in its code (`PerformCounterCheck`, `ProcessActionReaction` changed elsewhere) |
| 9 | Cat Eyes | none |
| 10 | Euphoria | cosmetic: energy FX only on hits on actors and not for channelled Signs |
| 11 | Second Life | cooldown 180 → 120 s |
| 12 | Metamorphosis | up to 5 decoctions (maxcap 3 → 5) |
| — | System | new-tree character menu (`characterMenuDupe.ws`) duplicates the mutation panel and the mutation skill slots; skill reset/refund (`RemasterSkillResetAndRefund`, `RemasterSkillSlotReset`, `UpdateSkillSlots`) accounts for mutation skill points; research costs and the Synapses thresholds unchanged; 16 skill slots (12 + 4 mutation) in both versions |

### Classification and proposed action

| # | Mutation | Class | Why | Proposed action |
|---|---|---|---|---|
| 1 | Conductors of Magic | clean | 5.x untouched; depends on GM's `GetTotalWeaponDamage` (DMG/SWD) | Port as-is (XML value + `ProcessDamageIncrease` hunk) |
| 2 | Magic Sensibilities | clean (units overlap) | idea untouched; hunks sit in damage-manager functions 5.x changed | Port the formula; 5.x's supercharged-Sign explosion follows SKL's rule for Flood of Anger casts: as legacy (project owner, 2026-10-11), checked against legacy's code when implemented |
| 3 | Bloodbath | clean | 5.x untouched | Port; check the skill count for the new tree (perks, shared skills) |
| 4 | Toxic Blood | overlap | 5.x buffed vanilla's acid; GM replaced the mechanic and sets `AcidEffect` itself | GM's version (legacy first); GM's `AcidEffect` values override 5.x's 0.01 |
| 5 | Mutated Skin | clean (units overlap) | 5.x untouched; hooks in `ReduceDamage`/`OnTakeDamage`/`CActor.OnTakeDamage` that 5.x and DEF changed | Port; merge with DEF's ported versions |
| 6 | Piercing Cold | overlap, needs-decision | 5.x reworked the freeze chance (adrenaline) and boss rules in the same function GM rewrote | Legacy rule (30% × (1 − frost res), 250 SI-scaled), no boss exclusion (DM2); a Flood of Anger Aard as legacy (DM3); override 5.x's new string; Shock Wave part with SKL-08 |
| 7 | Adrenaline Rush | clean | 5.x only added an unrelated interplay | Port; 5.x's Delayed Recovery rule goes (SKL replaces Delayed Recovery with Expert Brewer in both trees, D28) |
| 8 | Deadly Counter | clean | 5.x untouched; depends on DEF-06/07 | Port; ends the DEF-07 and DEF-06 temporary deviations |
| 9 | Cat Eyes | clean | 5.x untouched | Port with XBOW |
| 10 | Euphoria | clean | 5.x cosmetic only | Port with ALCH (overdose damage `GetToxicityDamage`) |
| 11 | Life Leech + Mutation Catalyst | overlap (XML cooldown), needs-decision on saves | 5.x lowered Second Life's cooldown in the unit GM replaced (90 s) | GM's Life Leech; new item/recipe/effect (save impact: recipe added on load) |
| 12 | Metamorphosis | overlap | 5.x raised the cap GM relies on (3 → 5); potion functions changed by 5.x and SKL-13/16 | GM's version, cap 3 |
| — | Research costs | overlap, needs-decision | GM cut SP costs (undocumented); 5.x made skills cheaper but kept mutation costs | Decide with the XP/progression review (P10) |
| — | Sound bank fix | in-5.x (partly) | 5.x reloads only Mutation 6's bank | Port GM's generic reload, drop 5.x's special case if redundant |

---

### MUT-01 Mutation system: research costs and housekeeping

| | |
|---|---|
| Kind | tuning, fix, infra |
| Pillars | P10, P8 |
| 5.x class | overlap (costs), in-5.x partly (sound bank) |
| Flags | needs-decision, balance |
| Depends on | SKL-01 (mutation skill slots), SKL D44 (debug respec), XP (progression pace) |
| Skill trees | both: the mutation panel exists in both menus (`characterMenu.ws`, `characterMenuDupe.ws`) |
| Port form | DLC XML override of `geralt_mutations.xml` `custom/mutations` (`skillPoints`; whether `<custom><mutations>` accepts `on_conflict` is an open check, else whole-file override); `@addMethod` on `W3PlayerAbilityManager` (`LoadCurrentMutationSoundBank`, `GetMutationsUsedMutagens`), `@wrapMethod(W3PlayerWitcher) OnSpawned` |
| Port status | not started |
| Open checks | `on_conflict` on `<custom><mutations>`; costs decision |
| Save impact | none (expected) |
| NG+ counterpart | applied and scaled, untested (`abilities_plus/geralt_mutations.xml`, identical) |

**What it does:** research costs 53 → 29 skill points (each mutation ≈ 60% of vanilla; mutagen costs unchanged; not in the changelist); the equipped mutation's sound bank is reloaded on load (changelist: "sound banks for mutations not being properly loaded after restarting the game"); the debug respec refunds the greater mutagens spent.

**Implementation (legacy):** `custom/mutations` (`skillPoints` 3/1/2/1/3/2/3/1/3/2/4/4); `LoadCurrentMutationSoundBank` called from `OnSpawned`; `GetMutationsUsedMutagens`, `Debug_RestoreMutagensSpent`; `OnMutationUnequippedPre` and `OnMutationEquippedPost` per-mutation cleanups (listed with each mutation).

**5.x:** costs unchanged (53); skill reset/refund functions count mutation skill points; Mutation 6's bank only is reloaded on spawn.

**Decisions:** DM1 (project owner, 2026-10-11): legacy's research costs, 29 skill points in all, in both trees (5.x: 53).

### MUT-02 Conductors of Magic (Mutation 1)

| | |
|---|---|
| Kind | tuning |
| Pillars | P1, P7 |
| 5.x class | clean |
| Flags | balance |
| Depends on | DMG / SWD (`GetTotalWeaponDamage`), ENCH (Runeword 4 Invigoration on Sign hits) |
| Skill trees | n/a |
| Port form | DLC XML (`Mutation1.dmg_bonus_factor` 0.3); `@wrapMethod`/`@replaceMethod` on `W3DamageManagerProcessor.ProcessDamageIncrease` (with SKL-04/05/06/18's hunks there) |
| Port status | not started |
| Open checks | — |
| Save impact | none (expected) |
| NG+ counterpart | applied and scaled, untested |

**What it does:** with a relic or witcher sword (quality ≥ 3) drawn, Signs gain 30% of the sword's base damage (vanilla 50% of the raw item attribute). **Scales:** sword base damage (upgrades, GM weapon damage), Sign damage. **Build:** Signs (support).

### MUT-03 Magic Sensibilities (Mutation 2)

| | |
|---|---|
| Kind | tuning, system |
| Pillars | P7, P3 |
| 5.x class | clean (units overlap 5.x) |
| Flags | balance |
| Depends on | DMG (SI → power-bonus curve `SignPowerStatToPowerBonus`), SKL-08 to SKL-12 (sign damage) |
| Skill trees | both (affects every Sign) |
| Port form | DLC XML `Mutation2` (add 0.05/mult 0.40 chance; add 0.25/mult 1.875 power); hunks in `GetAttackersPowerMod`, `ProcessCriticalHitCheck`; tooltip (MUT-13) |
| Port status | not started |
| Open checks | a Flood of Anger sign's crit and the explosion: as legacy, to check against legacy's code when implemented |
| Save impact | none (expected) |
| NG+ counterpart | applied and scaled, untested |

**What it does:** Sign crit chance 5% + 40% × B, crit power +25% + 187.5% × B, B from SI (0 → 2.0 at 500% SI): 5%/25% at SI 0, 35%/166% at SI 100%, 85%/400% at 500%. **Scales:** Sign Intensity. **Build:** Signs (cornerstone).

### MUT-04 Piercing Cold (Mutation 6)

| | |
|---|---|
| Kind | system, tuning |
| Pillars | P5, P7 |
| 5.x class | overlap |
| Flags | balance, needs-decision |
| Depends on | SKL-08 (Aard, Shock Wave `magic_s06` / new tree `magic_s33`, Aard diminishing returns), DMG (frost resistance), EFX (Frozen) |
| Skill trees | both: Aard; classic Shock Wave `magic_s06`, new `magic_s33` |
| Port form | `@replaceMethod(W3AardProjectile) ProcessMutation6` merged with 5.x's version; DLC XML `Mutation6` (0.3, ForceDamage 250); string override for 5.x's new description |
| Port status | not started |
| Open checks | a Flood of Anger Aard with Piercing Cold: as legacy (DM3), to check against legacy's code when implemented |
| Save impact | none (expected) |
| NG+ counterpart | applied and scaled, untested |

**What it does:** Aard freezes with 30% × (1 − frost resistance) (not mid-air, not instant-kill-immune); frozen + knocked down = instant kill; else 250 force damage scaled by SI in its own action, with a new knockdown test. **5.x:** chance = adrenaline × 10%, no freeze with a supercharged Aard, Wild Hunt generals cannot be killed, `OnFrostHit` on Aard hits, Shock Wave formula changed in this path. **Decided:** legacy rule, no boss exclusion (DM2); a Flood of Anger Aard as legacy (DM3), to check against legacy's code when implemented. **Scales:** Sign Intensity, target frost resistance, Aard knockdown. **Build:** Signs (control).

### MUT-05 Bloodbath (Mutation 3)

| | |
|---|---|
| Kind | system |
| Pillars | P1, P8 |
| 5.x class | clean |
| Flags | balance |
| Depends on | SKL (equipped skills count; both trees), GEN/FIX (finisher and dismemberment rules in `CanPerformFinisher`/`CanDismember`, SKL-12) |
| Skill trees | both: counts equipped skills in unlocked slots (sword path +10%, other paths and perks +5%) |
| Port form | `@replaceMethod`/`@addMethod`/`@addField` on `W3Effect_Mutation3`; DLC XML `Mutation3` (new attributes); `@wrapMethod` `CNewNPC.OnDeath`, `W3PlayerWitcher.OnTakeDamage`, `OnCombatStart`, `OnProcessActionPost` (remove vanilla trigger), `OnMutationUnequippedPre` |
| Port status | not started |
| Open checks | new tree: which skills count as "combat" (sword path) |
| Save impact | none (expected; buff removed at combat end) |
| NG+ counterpart | applied and scaled, untested |

**What it does:** see [What Ghost Mode changed](#what-ghost-mode-changed). Max 250% AP. **Scales:** attack power; number and kind of equipped skills; Vitality lost; kills. **Build:** Sword (cornerstone).

### MUT-06 Deadly Counter (Mutation 8)

| | |
|---|---|
| Kind | system |
| Pillars | P9 |
| 5.x class | clean |
| Flags | balance |
| Depends on | DEF-06, DEF-07 (per-enemy countered flag, signed off), SKL-05 (Counterattack), SKL-12 (finishers on alive targets) |
| Skill trees | n/a |
| Port form | `@addMethod`/`@addField` on `W3DamageManagerProcessor` (`CheckMutation8Finisher`, `CleanupMutation8Finisher`, `mutation8Triggered`) and hunks in `InitializeActionVars`, `ProcessActionReaction`, `ProcessDamageModification`, finisher/dismember functions; `CNewNPC.IsImmuneToMutation8Finisher` (`@replaceMethod`), `Mutation8RepelToFinisherImmune` (`@addMethod`); `CR4Player.PerformCounterCheck` (DEF's wrap); DLC XML `Mutation8` |
| Port status | not started |
| Open checks | — |
| Save impact | none (expected) |
| NG+ counterpart | applied and scaled, untested |

**What it does:** see [What Ghost Mode changed](#what-ghost-mode-changed). Ends the temporary DEF-06/DEF-07 deviations (Mutation 8 reads the countered enemy's flag and sits first in the repel order). **Scales:** adrenaline (+33.3%/pt), enemy health %, counters. **Build:** Sword/counter.

### MUT-07 Adrenaline Rush (Mutation 7)

| | |
|---|---|
| Kind | system |
| Pillars | P2, P8 |
| 5.x class | clean |
| Flags | balance |
| Depends on | SKL-07 (adrenaline gain rules in `OnProcessActionPost`), SKL-18 (Perk 11 `ManageFocusGain`, Perk 18 bombs), STAM-01/02 (cooldown immunity skip list in `IsImmuneToBuff`) |
| Skill trees | n/a (adrenaline from any source) |
| Port form | `@replaceMethod` on `W3Mutation7BaseEffect`, `W3Effect_Mutation7Buff/Debuff`, `W3Mutation7DebuffParams` (`@addField`); DLC XML `Mutation7Buff/Debuff` (±0.5); gain ×2/÷2 hunks; `OnCombatStart`, `OnCombatFinished` |
| Port status | not started |
| Open checks | — |
| Save impact | none (expected) |
| NG+ counterpart | applied and scaled, untested |

**What it does:** see [What Ghost Mode changed](#what-ghost-mode-changed). **Scales:** adrenaline (AP and SI ±50% per point, gain ×2 / ÷2). **Build:** Sword/Signs hybrid on adrenaline.

### MUT-08 Toxic Blood (Mutation 4)

| | |
|---|---|
| Kind | system |
| Pillars | P2, P7 |
| 5.x class | overlap |
| Flags | balance |
| Depends on | ALCH (toxicity decay, `W3Effect_Toxicity.OnUpdate`, SKL-17), STAM-08 (`Mutation4BloodDebuff` stamina value, attributed there) |
| Skill trees | n/a |
| Port form | DLC XML `Mutation4` (new), `AcidEffect` (1.5, 5 s; replaces 5.x's 0.01), `Mutation4BloodDebuff`; `@replaceMethod` `ProcessActionMutation4ReturnedDamage`, `W3Effect_Mutation4`; `@addMethod`/`@wrapMethod` `W3Effect_Acid.OnEffectAdded/Removed`; decay hunk in the toxicity effect; stats popup |
| Port status | not started |
| Open checks | — |
| Save impact | none (expected) |
| NG+ counterpart | applied and scaled, untested |

**What it does:** see [What Ghost Mode changed](#what-ghost-mode-changed). At 100 toxicity: 150 damage/s for 5 s per melee hit taken. **5.x:** doubled vanilla's acid; superseded by GM's values. **Scales:** current toxicity, toxicity decay. **Build:** Alchemy (support/defence).

### MUT-09 Euphoria (Mutation 10)

| | |
|---|---|
| Kind | system |
| Pillars | P2, P7 |
| 5.x class | clean |
| Flags | balance |
| Depends on | ALCH (overdose threshold and damage `GetToxicityDamage`, `W3Effect_Toxicity.OnUpdate`), SKL-17 (Frenzy in the same function), SKL-08 (`GetTotalSignSpellPower` without M10 boost) |
| Skill trees | n/a |
| Port form | DLC XML `Mutation10Effect` (`mutation10_factor` 0.75); `@replaceMethod` `W3Effect_Mutation10`; `@addMethod` `GetToxicityDamage` (or ALCH's); hunks in `ProcessDamageIncrease`, `GetOffenseStatsList`, stats popup; remove vanilla boost from `GetPowerStatValue`/`GetTotalSignSpellPower` |
| Port status | not started |
| Open checks | — |
| Save impact | none (expected) |
| NG+ counterpart | applied and scaled, untested |

**What it does:** see [What Ghost Mode changed](#what-ghost-mode-changed); at 100 toxicity and 5000 Vitality +44 base damage per hit, losing 44 Vitality/s. **Scales:** toxicity (overdose), max Vitality, weapon and Sign base damage. **Build:** Alchemy (cornerstone).

### MUT-10 Mutated Skin (Mutation 5)

| | |
|---|---|
| Kind | system |
| Pillars | P9, P2 |
| 5.x class | clean (units overlap) |
| Flags | balance |
| Depends on | DEF-01/02 (`ReduceDamage`), STAM-06/08 (`CActor.OnTakeDamage`), SKL-07 (Undying in `OnTakeDamage`, adrenaline) |
| Skill trees | n/a |
| Port form | `@replaceMethod` on `W3Effect_Mutation5` (class now extends `W3DamageOverTimeEffect`: base-class change needs a new class or scope override, open check); `@addMethod`/`@addField` on `W3DamageAction`; hunks in `OnTakeDamage`, `CActor.OnTakeDamage`; DLC XML `Mutation5`, `Mutation5Effect` |
| Port status | not started |
| Open checks | how to change an effect class's base class on 5.x |
| Save impact | none (expected) |
| NG+ counterpart | applied and scaled, untested |

**What it does:** see [What Ghost Mode changed](#what-ghost-mode-changed). **Scales:** adrenaline (duration 5 s/pt, drain 1 pt/5 s), Vitality. **Build:** Defensive/adrenaline.

### MUT-11 Cat Eyes (Mutation 9)

| | |
|---|---|
| Kind | tuning, system |
| Pillars | P7 |
| 5.x class | clean |
| Flags | balance |
| Depends on | XBOW (bolt damage, non-aimed bolts, `GetOffenseStatsList`), SKL-06 (crossbow skills, aiming slow-mo in `SloMo`), ALCH (toxicity) |
| Skill trees | n/a |
| Port form | DLC XML `Mutation9` (`mut9_damage` 1, `mut9_slowdown` 0.25, crit lines removed); hunks in `ProcessDamageIncrease`, `GetOffenseStatsList`, `GetTotalWeaponDamage`, `PlayerAimingStateAiming.SloMo` |
| Port status | not started |
| Open checks | — |
| Save impact | none (expected) |
| NG+ counterpart | applied and scaled, untested |

**What it does:** see [What Ghost Mode changed](#what-ghost-mode-changed). **Scales:** crossbow/bolt base damage, toxicity (> 0 for slow-mo), enemy at full Vitality. **Build:** Crossbow.

### MUT-12 Life Leech and Mutation Catalyst (Mutation 11)

| | |
|---|---|
| Kind | system, content |
| Pillars | P8, P7 |
| 5.x class | overlap |
| Flags | balance, needs-decision |
| Depends on | ALCH (new potion, recipe, potion effects), SKL-07 (Undying takes Second Life's role), SKL-11 (Quen during the effect), DMG (AP/SI averages in `GetOffenseStatsList`), INFRA (new effect type `EET_MutationTrigger`) |
| Skill trees | n/a |
| Port form | new effect type (enum extension + registration) and class `W3Potion_MutationTrigger`; `@replaceMethod` on `W3Effect_Mutation11Buff` + new methods; `@addMethod` `Mutation11GetBaseStrength`; hunks in `OnMutation11Triggered`, `Mutation11ShockWave`, `OnTakeDamage` (remove death trigger), Quen and channelling units; DLC XML: item, stats, effect, recipe, `Mutation11` (ShockDamage 40), `Mutation11BuffEffect`, `Mutation11DebuffEffect` (90 s); recipe in `OnMutationFullyResearched` and on load |
| Port status | not started |
| Open checks | owner: the feel of the drain; 90 s vs design doc's 120 s |
| Save impact | new item and recipe in saves (removing the mod leaves an unknown item); recipe added on load when Mutation 11 is researched |
| NG+ counterpart | applied and scaled, untested (`items_plus`, `abilities_plus`) |

**What it does:** see [What Ghost Mode changed](#what-ghost-mode-changed). **5.x:** Second Life cooldown 120 s (irrelevant once replaced). **Scales:** sword base damage + average AP + average SI, × adrenaline, ÷ enemies; potion (3 charges, 20 toxicity). **Build:** Hybrid (late-game sustain).

### MUT-13 Metamorphosis (Mutation 12)

| | |
|---|---|
| Kind | system |
| Pillars | P2, P7 |
| 5.x class | overlap |
| Flags | balance |
| Depends on | ALCH (decoctions, toxicity), SKL-13/SKL-16 (`DrinkPreparedPotion`, `HasFreeToxicityToDrinkPotion`, `ToxicityLowEnoughToDrinkPotion`, Tissue Transmutation offsets), SKL-08/09 (sign effect chances), EFX (critical effects) |
| Skill trees | both (Signs and swords) |
| Port form | DLC XML `Mutation12` (maxcap 3, `mut12bonus` 0.1; overrides 5.x's 5); `@addMethod` `Mutation12GetBonus`, `Mutation12FreeDecoctionAvailable`; `@replaceMethod` `AddMutation12Decoction` (empty); hunks in the potion functions and the five chance functions |
| Port status | not started |
| Open checks | — |
| Save impact | none (expected) |
| NG+ counterpart | applied and scaled, untested |

**What it does:** see [What Ghost Mode changed](#what-ghost-mode-changed). **Scales:** decoctions (count), critical-effect chances, toxicity. **Build:** Alchemy/decoctions.

### MUT-14 Mutation descriptions and HUD

| | |
|---|---|
| Kind | ui |
| Pillars | P7 |
| 5.x class | clean (5.x changed only Mutation 6's string) |
| Flags | — |
| Depends on | MUT-02 to MUT-13 (values), UI (HUD buff module) |
| Skill trees | both menus show the same tooltip (`GetMutationLocalizedDescription`) |
| Port form | `@replaceMethod(W3PlayerWitcher) GetMutationLocalizedDescription`; localization rows (GM's own string ids, 15 × 9 languages); HUD hunks in `CR4HudModuleBuffs.OnTick/UpdateBuffs` (Mutation 3/4/5/7/10 counters) |
| Port status | not started |
| Open checks | GM's keyless rows use the vanilla key hashes (`c3f5389b`…); check they still win over 5.x's rows |
| Save impact | none |
| NG+ counterpart | none |

**What it does:** new descriptions and live values for all 12 (filled at base stats in the [tree files](../skill-trees/)); Mutation 11's name "Life Leech"; Mutation Catalyst name and description. Proposed: one slice with each mutation, like SKL D45.

---

### Mutations in two trees

The mutations' effects and research costs are the same in both trees: legacy's (DM1, project owner, 2026-10-11). How (from the 5.x code, 2026-10-05; unverified):

- **Research costs.** `W3PlayerAbilityManager.LoadMutationData` refreshes each mutation's required skill points and mutagens from `<custom><mutations>` into the saved `mutations[]` array on every load. They are plain script fields, so a wrapper can apply legacy's costs after it, whichever tree is active. MUT-01 then needs no XML override of `<custom><mutations>`, which avoids the open `on_conflict` question.
- **Switching trees** is not a normal workflow (project owner, 2026-10-05). It goes through Ghost Mode's character reset ([SKL-01](skl.md#skl-01-skill-system-rules), D44), which refunds mutation research (skill points and mutagens) with everything else. Note: 5.x's own skill reset (`RemasterSkillResetAndRefund`) deliberately keeps researched mutations and their points.
- **On the costs.** Legacy cut the research costs from vanilla's 53 skill points to 29 (not in the changelist); 5.x kept vanilla's 53. The port uses legacy's 29 in both trees.

### Decisions waiting for the owner

**Decided** (project owner, 2026-10-05): the mutations are legacy Ghost Mode's in both trees: DM2 and DM4 as legacy (no boss exclusion from Piercing Cold's instant kill; Life Leech 90 s). DM1 (project owner, 2026-10-11): research costs match legacy in both trees, 29 skill points in all ([how](#mutations-in-two-trees)). DM3 (project owner, 2026-10-11): a Flood of Anger Aard behaves as in legacy, like SKL's other Flood of Anger casts (D16); checked against legacy's code when implemented.

| # | Question | Recommendation |
|---|---|---|
| DM1 | Research costs: Ghost Mode's 29 skill points or 5.x's 53 | **Legacy's 29 skill points in both trees** (project owner, 2026-10-11) |
| DM2 | Piercing Cold: keep 5.x's exclusion of Eredin, Imlerith and Caranthir from the instant kill | **As legacy: no exclusion** (2026-10-05) |
| DM3 | Piercing Cold and supercharged Aard (new tree only): 5.x gives no freeze | **As legacy** (project owner, 2026-10-11): a Flood of Anger cast behaves as in legacy; checked against legacy's code when implemented (SKL's D16) |
| DM4 | Life Leech's cooldown: 90 s (code, changelist) or 120 s (design notes) | **90 s** (2026-10-05) |

### Hand-off to other areas

| Area | Changes |
|---|---|
| ALCH | Mutation Catalyst potion, recipe and effect (MUT-12 ports them with Life Leech); overdose damage `GetToxicityDamage` (Euphoria, Toxic Blood's decay) |
| DEF | Deadly Counter ends DEF-06's and DEF-07's temporary deviations |
| SKL | Mutation skill slots (SKL-01); Shock Wave in Piercing Cold's path (SKL-08); Bloodbath counts equipped skills (both trees) |
| XBOW, DMG, ENCH | Cat Eyes' bolt damage; the intensity-to-power curve (Magic Sensibilities); Runeword 4 on Sign hits (Conductors of Magic) |
