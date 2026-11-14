# MUT: mutations

Blood and Wine's late-game progression: twelve mutations researched with skill points and greater mutagens, one active at a time, and four extra skill slots unlocked by the number researched. Ghost Mode reworked ten of them, retuned the other two, replaced Second Life with Life Leech (activated by a new potion, the Mutation Catalyst) and cut the research costs. Source: the changelist's "Mutations" section ([legacy-FullChangelist.txt](../legacy-FullChangelist.txt), around line 1021) and the mutation bug fixes.

Mutations are part of player power: balance them with [balance.md](balance.md) and the [ledger](ledger/mutations.md). Their texts at base stats are in both [tree files](../skill-trees/).

**How legacy Ghost Mode implements it.** The research tree and costs are `<custom><mutations>` in `dlc/bob/.../geralt_mutations.xml`, the values the abilities `Mutation1` to `Mutation12` in the same file, effect values in `effects_ep2.xml`. Code: the effect classes in `scripts/game/gameplay/effects/effects/mutations/`, hooks in the damage manager, `playerWitcher.ws`, `npc.ws`, `r4Player.ws` and the sign scripts; tooltips filled by `W3PlayerWitcher.GetMutationLocalizedDescription`.

**What 5.x did in this area.** Little: Piercing Cold's freeze chance now depends on adrenaline and spares three bosses, Toxic Blood's acid is doubled, Second Life's cooldown is 120 s, Metamorphosis allows 5 decoctions, and the new tree's character menu has its own copy of the mutation panel. Research costs and the tree are unchanged.

Unit lists: [attribution.csv](attribution.csv): mapped from the changelist and a sweep of every unit naming a mutation, its effects, the Catalyst or the mutation XML: 203 units (153 script, 50 XML; 53 of them shared with other features) plus 135 description rows (15 strings × 9 languages). Legacy changes inside MUT's units that belong to other areas (Runeword 1 and Glyphword 6 in the Aard projectile, the overdose threshold, the character stats popup's mutation lines) are attributed to and ported by ENCH, ALCH and UI. Port status: MUT-01 to MUT-14 ported and verified in game in both trees; **signed off** by the project owner on 2026-10-17. 5.x-only units the port merges with, outside the sweep: vanilla's Metamorphosis triggers in `criticalEffect.ws`, `dotEffect.ws`, `slowdown.ws`, `slowdownFrost.ws` (they call the emptied `AddMutation12Decoction`, MUT-13); `W3AardProjectile.CheckFrostEffect` (dropped, MUT-04); `W3DamageAction.IsMutation2PotentialKill` (never applies, MUT-03); `W3PlayerAbilityManager.GetStaminaActionCostInternal` (5.x's Delayed Recovery rule, never triggers: SKL-13); the `CR4CharacterDupeMenu` mutation functions (the new tree's menu, same data). Row 2110992548 among the mutation strings is Steady Shot's text (SKL-19). Test accessors outside `tests/` (`GMGetDrainStrength`, `GMGetBonusStacks`, `GMGetDamagePerSec`, `GMGetMutationSkillPoints`) are accepted.

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
| 1 | Conductors of Magic | Sign damage + 50% of the held sword's raw damage attribute (any drawn sword; the changelist and tooltip say relic and witcher swords) | 30%, computed from the sword's total base damage (`GetTotalWeaponDamage`, GM's weapon damage incl. upgrades); Invigoration (Runeword 4) also consumed by Sign hits with M1 (changelist; legacy's code: never, ENCH-05) | XML `Mutation1`; `ProcessDamageIncrease`; `OnProcessActionPost` (Runeword 4, ENCH) |
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
| — | Research costs | overlap | GM cut SP costs (undocumented); 5.x made skills cheaper but kept mutation costs | Legacy's 29 skill points in both trees (DM1, project owner, 2026-10-11) |
| — | Sound bank fix | in-5.x (partly) | 5.x reloads only Mutation 6's bank | Port GM's generic reload, drop 5.x's special case if redundant |

---

### MUT-01 Mutation system: research costs and housekeeping

| | |
|---|---|
| Kind | tuning, fix, infra |
| Pillars | P10, P8 |
| 5.x class | overlap (costs), in-5.x partly (sound bank) |
| Flags | balance |
| Depends on | SKL-01 (mutation skill slots), SKL D44 (character reset), XP (progression pace) |
| Skill trees | both: the mutation panel exists in both menus (`characterMenu.ws`, `characterMenuDupe.ws`); costs and research are the same in both |
| Port form | `mutations/mutationSystem.ws`: `@wrapMethod(W3PlayerAbilityManager) LoadMutationData` lays legacy's costs on the saved `mutations[]` (no XML override of `<custom><mutations>` needed); `@addMethod` `GMLoadCurrentMutationSoundBank`, called from a wrapper of `W3PlayerWitcher.OnSpawned`; the greater-mutagen refund is the character reset's (SKL-01, `GMGetMutationsUsedMutagens`) |
| Port status | signed off (2026-10-17); verified in both trees |
| Open checks | the costs read on screen in the mutation panel (the panel's own data array was read by script); a real save and reload with a mutation equipped (the reload function was called by script) |
| Save impact | none: the costs are laid on at every load; a save that paid 5.x's costs gets the excess skill points back. Removing the mod (not supported mid-playthrough, [save compatibility](../feature-mapping.md#save-compatibility)): 5.x's costs return at the next load, so a mutation researched at legacy's cost shows as partly researched (`GetMutationResearchProgress` counts the points; legacy had the same on uninstall) |
| NG+ counterpart | the same script in NG+ (the costs are not in `abilities_plus`) |

**What it does:** research costs 53 → 29 skill points (each mutation ≈ 60% of vanilla; mutagen costs unchanged; not in the changelist); the equipped mutation's sound bank is reloaded on load (changelist: "sound banks for mutations not being properly loaded after restarting the game"); the character reset refunds the greater mutagens spent (SKL-01).

**Implementation (legacy):** `custom/mutations` (`skillPoints` 3/1/2/1/3/2/3/1/3/2/4/4); `LoadCurrentMutationSoundBank` called from `OnSpawned`; `GetMutationsUsedMutagens`, `Debug_RestoreMutagensSpent`; `OnMutationUnequippedPre` and `OnMutationEquippedPost` per-mutation cleanups (listed with each mutation).

**5.x:** costs unchanged (53); skill reset/refund functions count mutation skill points; Mutation 6's bank only is reloaded on spawn (kept: it is the same load, done twice harmlessly).

**Decisions:** DM1 (project owner, 2026-10-11): legacy's research costs, 29 skill points in all, in both trees (5.x: 53).

- **Deviation:** a save that researched at 5.x's (or vanilla's) higher costs gets the skill points above legacy's cost back at load, and the research keeps exactly legacy's cost; legacy read the costs from the XML and left the extra points spent, which also counted towards the research progress, so a mutation could show as researched with mutagens missing (porter's call, confirmed by the owner, 2026-10-17).

**Slices:**

1. **Costs and sound bank.** Verified 2026-10-17 in both trees (`gmtest_mut01_research`, `gmtest_mut01_bank`, `gmtest_mut01_overpay`: scripted calls of the functions the mutation panel and the load use): every cost legacy's, 29 in all, a research refused with too few points; the bank unloaded and reloaded by the load-time function; a research overpaid at 5 points kept 3 and gave 2 back. `GMTest_mut01_costs` in the regression.

### MUT-02 Conductors of Magic (Mutation 1)

| | |
|---|---|
| Kind | tuning |
| Pillars | P1, P7 |
| 5.x class | clean |
| Flags | balance |
| Depends on | DMG / SWD (`GetTotalWeaponDamage`), ENCH (Runeword 4 Invigoration on Sign hits) |
| Skill trees | n/a (every Sign, both trees) |
| Port form | DLC XML `gm_mutations.xml` (`Mutation1` given whole, `on_conflict="replace"`: `dmg_bonus_factor` 0.3); two lines in `ProcessDamageIncrease` (`damage/pool.ws`, already replaced by DMG); description in `mutations/mutationDescriptions.ws` (MUT-14) |
| Port status | signed off (2026-10-17); verified in both trees |
| Open checks | a Sign hit with a silver sword drawn (steel tested; the same code path); the description read on screen (read through the menu's function) |
| Save impact | none |
| NG+ counterpart | applied (`abilities_plus/gm_mutations.xml`, generated), untested |

**What it does:** with a sword drawn, Signs gain 30% of the sword's base damage (vanilla 50% of the raw item attribute). Any drawn sword counts, plain ones included, in vanilla, legacy and the port alike; legacy's changelist and tooltip said "magic, relic and witcher swords" (whole-port audit A3-5), so the port's description says any sword. **Scales:** sword base damage (upgrades, GM weapon damage), Sign damage. **Build:** Signs (support).

**Decisions:**

- **Deviation:** the description says any drawn sword counts, as it does in legacy and the port; legacy's said magic, relic and witcher swords (owner, 2026-11-03). Text only: no play difference.
- Invigoration (Runeword 4) with Conductors of Magic since ENCH-05 (2026-10-19): Sign hits get its bonus through the sword's damage and a damaging Sign hit spends it, as the changelist says (the owner's ruling, 2026-10-19; legacy's check sat in the melee branch, so there they never spent it: a deviation recorded in [ENCH-05](ench.md#ench-05-invigoration-runeword-4)).

**Slices:**

1. **The bonus and the description.** Verified 2026-10-17 in both trees (real Igni casts with a steel sword drawn at a test dummy, the damage probe; `gmtest_mut02_setup/read`): the sign hit's raw damage rose by 30% of the sword's base damage (`GetTotalWeaponDamage`), none without the mutation; the description (English, through `GetMutationLocalizedDescription`, the menus' call) is legacy's with "30%". `GMTest_mut02` (the XML value) in the regression.

### MUT-03 Magic Sensibilities (Mutation 2)

| | |
|---|---|
| Kind | tuning, system |
| Pillars | P7, P3 |
| 5.x class | clean (units overlap 5.x) |
| Flags | balance |
| Depends on | DMG (SI → power-bonus curve `GMSignPowerStatToPowerBonus`), SKL-08 to SKL-12 (sign damage) |
| Skill trees | both (affects every Sign) |
| Port form | `mutations/magicSensibilities.ws`: `GMMutation2CritChance`, `GMMutation2CritDamage`; a wrapper of `W3DamageManagerProcessor.ProcessCriticalHitCheck` rolls a Sign hit's crit with legacy's chance (vanilla's roll skipped for it); the crit damage in `GetAttackersPowerMod` (`damage/formula.ws`, replaced by DMG); DLC XML `Mutation2` (whole, `replace`); description (MUT-14) |
| Port status | signed off (2026-10-17); verified in both trees |
| Open checks | the crit rate in play (the roll ran with crits forced; the chance formula is checked by script); the explosion of an enemy killed by a Sign crit (vanilla's code, unchanged and the same as legacy's) |
| Save impact | none |
| NG+ counterpart | applied (generated), untested |

**What it does:** Sign crit chance 5% + 40% × B, crit power +25% + 187.5% × B, B from SI (0 → 2.0 at 500% SI): 5%/25% at SI 0, 35%/166% at SI 100%, 85%/400% at 500%. **Scales:** Sign Intensity. **Build:** Signs (cornerstone).

**Decisions:** a Flood of Anger cast behaves as in legacy (project owner, 2026-10-11): 5.x's Sign-crit explosion for a supercharged sign without the mutation (`IsMutation2PotentialKill`) never applies, since the port has no supercharged signs (SKL-07); with the mutation a Flood of Anger cast crits by its raised intensity, as legacy's.

**Slices:**

1. **Crit chance, crit damage, description.** Verified 2026-10-17 in both trees (real Igni casts with crits forced by vanilla's debug fact, the damage probe; `gmtest_mut03_setup/read`): legacy's crit damage on a sign crit, none without the mutation; the description's values at the current intensity. The formula at sign power ×1, ×2, ×6 (`GMTest_mut03`, scripted): 5%/25%, 35%/165.6%, 85%/400%.

### MUT-04 Piercing Cold (Mutation 6)

| | |
|---|---|
| Kind | system, tuning |
| Pillars | P5, P7 |
| 5.x class | overlap |
| Flags | balance |
| Depends on | SKL-08 (Aard, Shock Wave `magic_s06` / new tree `magic_s33`, Aard diminishing returns), DMG (frost resistance), EFX (Frozen) |
| Skill trees | both: Aard; classic Shock Wave `magic_s06`, new `magic_s33` |
| Port form | `mutations/piercingCold.ws`: `@replaceMethod(W3AardProjectile)` `ProcessCollision` (5.x's body: the Aard hit stays a normal hit, no frost hit) and `ProcessMutation6` (legacy's rule); DLC XML `Mutation6` (whole, `replace`: 0.3, ForceDamage 250); description (MUT-14), which replaces 5.x's adrenaline text |
| Port status | signed off (2026-10-17); verified in both trees |
| Open checks | the 30% chance in play (tested at 100% and −300% frost resistance, which give 0% and 100%); Eredin, Imlerith and Caranthir killed by it (code read: no exclusion); Shock Wave with Piercing Cold (code read: SKL-08's wrapper adds it to the Aard hit either way); an enemy in mid-air |
| Save impact | none |
| NG+ counterpart | applied (generated), untested |

**What it does:** Aard freezes with 30% × (1 − frost resistance) (not mid-air, not instant-kill-immune); frozen + knocked down = instant kill; else 250 force damage scaled by SI in its own action, with a new knockdown test. **5.x:** chance = adrenaline × 10%, no freeze with a supercharged Aard, Wild Hunt generals cannot be killed, `OnFrostHit` on Aard hits, Shock Wave formula changed in this path. **Scales:** Sign Intensity, target frost resistance, Aard knockdown. **Build:** Signs (control).

**Decisions:** legacy rule, no boss exclusion (DM2); a Flood of Anger Aard as legacy (DM3): legacy's code has no rule for it, so it freezes like any Aard, with its raised intensity in the damage (5.x: no freeze with a supercharged Aard). 5.x's frost hit on Aard hits with the mutation (`CheckFrostEffect` → `OnFrostHit`) is dropped with the rest of 5.x's version (legacy has none). The "Mutation 6" sound bank is still loaded by 5.x on spawn and by MUT-01's reload.

- The replaced `ProcessCollision` also carries ENCH's Glyphword 6 (Depletion) enemy stamina drain, which legacy moved into the Aard projectile.

**Slices:**

1. **The freeze, the instant kill, the force damage, the description.** Verified 2026-10-17 in both trees (real Aard casts at a human test dummy whose frost resistance and knockdown state were set by script; `gmtest_mut04_setup/read`): at 100% frost resistance no freeze and one 250 force hit scaled by intensity; at −300% and immune to knockdowns frozen and alive, no force hit; at −300% and knocked down first frozen and killed. The description's values read right. `GMTest_mut04` (the XML values) in the regression.

### MUT-05 Bloodbath (Mutation 3)

| | |
|---|---|
| Kind | system |
| Pillars | P1, P8 |
| 5.x class | clean |
| Flags | balance |
| Depends on | SKL (equipped skills; both trees), SKL-12 (finishers and dismemberment, unchanged here) |
| Skill trees | both: counts the skills equipped in unlocked slots by their path (`GetSkillPathType`): the sword path +10% (classic `sword_s*`, new tree `sword_s35` and the rest of its sword path), every other path, perks included, +5% (verified in both trees) |
| Port form | `mutations/bloodbath.ws`: a scope-based override of `W3Effect_Mutation3` (defaults `stacks` 0, `dontAddAbilityOnTarget`), `@addField`/`@addMethod` (legacy's `InitVars`, `CalcInitialNumAbl`, `SetAbls`, `RemoveAbls`, `ManageMutation3Bonus` as `GM...`), `@replaceMethod` `OnEffectAddedPost`, `CumulateWith`, `OnEffectRemoved`; a wrapper of `CNewNPC.OnDeath` (kills); `mutations/takeDamage.ws` (`@replaceMethod W3PlayerWitcher.OnTakeDamage`, for the mutations' hunks: damage taken lowers the bonus, 5.x ended the effect); the start in `mutations/combatStart.ws`; DLC XML `Mutation3` (whole, `replace`); description (MUT-14) |
| Port status | signed off (2026-10-17); verified in both trees |
| Open checks | a real fight: real hits taken and a real killing blow (scripted through the damage manager); the attack power on screen; the end at combat end (5.x's, unchanged) |
| Save impact | none (the effect ends with combat) |
| NG+ counterpart | applied (generated), untested |

**What it does:** at combat start, +10% attack power per equipped sword-path skill and +5% per other equipped skill (unlocked slots; stacks of the `Mutation3` ability, 0.5% each); a hit taken (not a DoT from an effect) removes 0.5% per 1% of max Vitality lost; a kill by Geralt (a sword hit, a finisher) restores the bonus to its peak and adds +20%; max 250%; it all goes at combat end, or when Geralt is no longer threatened. Finisher or dismemberment on sword kills: 5.x's, unchanged. **Scales:** attack power; number and kind of equipped skills; Vitality lost; kills. **Build:** Sword (cornerstone).

**Decisions:**

- 5.x's start of the effect on a sword hit (`OnProcessActionPost`) is kept: it starts the effect, with the same bonus, only if a hit lands before the combat-start event, and adds nothing to a running effect (`CumulateWith` no longer stacks), so it plays as legacy's, which removed it.

**Slices:**

1. **The bonus, its losses and kills, the description.** Verified 2026-10-17 in both trees (`gmtest_mut05(1..3)`: the combat-start event called by script, scripted hits through the damage manager, skills equipped with `skilleq`): the stacks by the equipped skills' paths (sword path +10%, others +5%), losses by the share of Vitality lost, a kill restoring the peak and adding +20%; the description's values. `GMTest_mut05` in the regression.

### MUT-06 Deadly Counter (Mutation 8)

| | |
|---|---|
| Kind | system |
| Pillars | P9 |
| 5.x class | clean |
| Flags | balance |
| Depends on | DEF-06, DEF-07 (per-enemy countered flag, `CActor.GMWasCountered`), SKL-05 (Counterattack), SKL-12 (finishers and dismemberment on living targets, `skills/axii.ws`), DMG-05 (final damage) |
| Skill trees | n/a |
| Port form | `mutations/deadlyCounter.ws`: a wrapper of `W3DamageManagerProcessor.InitializeActionVars` sets `gmMutation8Triggered` (legacy `CheckMutation8Finisher`); `GMMutation8DamageMult` in `GMProcessDamageModification` (`damage/pipeline.ws`; 5.x's pool term removed from `pool.ws`); `@replaceMethod` `CNewNPC.IsImmuneToMutation8Finisher` and `CanPerformFinisherOnAliveTarget`; `@addMethod` `GMMutation8RepelToFinisherImmune`; lines in SKL-12's `ProcessActionReaction`, `CanDismember`, `CanPerformFinisher` and DEF-06's `PerformCounterCheck`; DLC XML `Mutation8` (whole, `replace`); description (MUT-14) |
| Port status | signed off (2026-10-17); verified in both trees |
| Open checks | a real counter followed by a real killing hit (the countered flag and the hits are scripted); the finisher animation after a repel to a finisher (the repel type is read; the dummy is frozen); the enemy-focus HUD icon (vanilla's code reads the new immunity rule) |
| Save impact | none |
| NG+ counterpart | applied (generated), untested |

**What it does:** a melee hit (not a finisher) on a living hostile NPC Geralt countered in the last 3 s that had 15% health or less before the hit kills it: a finisher on a human where finishers are allowed, else a dismemberment, any enemy type; a countered human that is no boss, not immune to instant kills and allows finishers, at 15% or less, is repelled straight into a finisher, first in the repel order; melee damage against a countered enemy × (1 + 33.34% × adrenaline) as final damage (+100% at 3 points); 5.x's flat +25% against monsters and counter-immune humans is gone. **Scales:** adrenaline (+33.3%/pt), enemy health %, counters. **Build:** Sword/counter.

**Slices:**

1. **The kill, the repel, the damage, the description.** Verified 2026-10-17 in both trees (`gmtest_mut06_hits`: scripted light hits with DEF-07's countered flag set by script, the damage probe; `gmtest_mut06_repel`: `PerformCounterCheck` by script): final damage ×2 with 3 adrenaline against a countered enemy and ×1 otherwise; a countered bandit and a countered wolf at 10% died from the hit, an uncountered bandit and one countered at 20% lived; a repel to a finisher at 10% health, a normal repel at full health. `GMTest_mut06` in the regression. Ends DEF-06's and DEF-07's Mutation 8 deviations and DMG's Mutation 8 terms.

### MUT-07 Adrenaline Rush (Mutation 7)

| | |
|---|---|
| Kind | system |
| Pillars | P2, P8 |
| 5.x class | clean |
| Flags | balance |
| Depends on | SKL-07 (adrenaline gain rules in `OnProcessActionPost`), SKL-18 (Focus `GMManageFocusGain`, Advanced Pyrotechnics' bombs), STAM-01/02 (cooldown immunity skip list in `IsImmuneToBuff`) |
| Skill trees | n/a (adrenaline from any source, both trees) |
| Port form | `mutations/adrenalineRush.ws`: `@replaceMethod` on `W3Mutation7BaseEffect`, `W3Effect_Mutation7Buff`, `W3Effect_Mutation7Debuff`, `@addField`s (`W3Mutation7DebuffParams` among them); the gain factor by a wrapper of `W3PlayerAbilityManager.GainStat` for adrenaline gained while one of Geralt's actions is processed (a wrapper of `W3DamageManagerProcessor.ProcessAction`) and in `GMManageFocusGain` (sign casts); a wrapper of `OnCombatStart` starts the cycle; `IsImmuneToBuff` skips the Recovery (`effects/gmEffectRegistration.ws`); DLC XML `Mutation7Buff/Debuff` (whole, ±0.5); description (MUT-14) |
| Port status | signed off (2026-10-17); verified in both trees |
| Open checks | the 30 s phases running out on their own in a long fight (the phases were ended by script); a bolt's and a bomb's gain (code read: the same path as the tested melee hits); the HUD icons and their percentages on screen (`GetStacks` read by script); the character stats popup lines (with UI) |
| Save impact | none (the effects are removed at combat end) |
| NG+ counterpart | applied (generated), untested |

**What it does:** see [What Ghost Mode changed](#what-ghost-mode-changed). **Scales:** adrenaline (AP and SI ±50% per point, gain ×2 / ÷2). **Build:** Sword/Signs hybrid on adrenaline.

**Decisions:**

- Implementation: legacy multiplies the gain at each of its sites (melee hits with the Lynx set's and the Bear School perk's terms, Cold Blood's bolts, Advanced Pyrotechnics' bombs, Focus's sign casts); the port applies the factor to every adrenaline gain made while one of Geralt's own actions is processed, which covers those sites and the port's other gains on hits (the new tree's Muscle Memory and Strength Training follow the hit's rule), and to Focus's sign casts directly. Razor Focus's combat-start top-up is not doubled, as legacy's. Confirmed by the owner (2026-10-17).
- The character stats popup shows the Adrenaline Rush terms since UI-01 (attack power) and UI-05 (adrenaline gain with the Rush's or the Recovery's factor; 2026-10-21): the temporary deviation has ended.

**Slices:**

1. **The cycle, the gain factor, the description.** Verified 2026-10-17 in both trees (`gmtest_mut07(1..4)`: the combat-start event called by script, scripted light hits, the phases ended by `RemoveBuff`; `gmtest_mut07_sign_a/b`, real Aard casts; a real combat start against a spawned wolf): the Rush's bonuses following the adrenaline points down, the gain doubled for hits and sign casts; the Recovery's penalties for the points gained in the Rush, the gain halved, not blocked by an immunity to negative effects; the next Rush after it; removed at the end of combat. `GMTest_mut07` (the XML values) in the regression. Ends SKL's temporary deviations on Adrenaline Rush (SKL-06 Cold Blood, SKL-07, SKL-18 Advanced Pyrotechnics).

### MUT-08 Toxic Blood (Mutation 4)

| | |
|---|---|
| Kind | system |
| Pillars | P2, P7 |
| 5.x class | overlap |
| Flags | balance |
| Depends on | ALCH (toxicity decay, `W3Effect_Toxicity.OnUpdate`, SKL-17), STAM-08 (`Mutation4BloodDebuff` stamina value) |
| Skill trees | n/a |
| Port form | `mutations/toxicBlood.ws`: `@replaceMethod` `W3PlayerWitcher.ProcessActionMutation4ReturnedDamage` and `W3Effect_Mutation4.OnEffectAddedPost/GetStacks` (the HUD counter's value); a scope-based override of `W3Effect_Acid` (`OnEffectAdded/OnEffectRemoved`, inherited) adds and removes the debuff; the decay in `mutations/toxicity.ws` (`@replaceMethod W3Effect_Toxicity.OnUpdate`, where ALCH's changes go too); DLC XML `Mutation4` (new), `AcidEffect` and `Mutation4BloodDebuff` (whole, `replace`; the debuff left out of `gen_npc_stamina.py`'s output); description (MUT-14) |
| Port status | signed off (2026-10-17); verified in both trees |
| Open checks | a real enemy's melee hit (the hit was scripted, through the damage manager as real hits) |
| Save impact | none |
| NG+ counterpart | applied (generated), untested |

**What it does:** a melee hit taken from an enemy within 3 m (6 m from a huge one), with toxicity above 0, gives the attacker acid for 5 s of 1.5 damage per second per toxicity point (150/s at 100), whatever the hit's damage, and slows its stamina regeneration by 10% while the acid runs; the acid also pauses its health regeneration (5.x's DoT attributes, legacy's values); toxicity decays 50% slower. **5.x:** doubled vanilla's acid (3% of the damage taken per toxicity point over 3 s); superseded. **Scales:** current toxicity, toxicity decay. **Build:** Alchemy (support/defence).

**Decisions:**

- Vanilla's vampire-bite path (`OnTaskSyncAnim`, a Bruxa's bite) is kept: legacy removed its own debuff and 15 s timer, but the acid's end removes every copy of the debuff first, so it plays as legacy's.
- The character stats popup's toxicity decay line shows Toxic Blood's reduction since UI-04 (2026-10-21): the temporary deviation has ended.

**Slices:**

1. **The acid, the debuff, the decay, the description.** Verified 2026-10-17 in both trees (`gmtest_mut08_hit/read`: a scripted melee hit of a test dummy on Geralt through the damage manager; `gmtest_mut08_decay_a/b`): at toxicity 100 the attacker got acid of 150/s for 5 s and the debuff, both gone after; no acid without the mutation or at toxicity 0; toxicity decay halved. `GMTest_mut08` (the XML values and the debuff's tag) in the regression.

### MUT-09 Euphoria (Mutation 10)

| | |
|---|---|
| Kind | system |
| Pillars | P2, P7 |
| 5.x class | clean |
| Flags | balance |
| Depends on | ALCH (overdose threshold and drain, `W3Effect_Toxicity.OnUpdate`), SKL-17 (Frenzy in the same function), SKL-13 (`DrinkPreparedPotion`, `skills/brewing.ws`), DMG (`ProcessDamageIncrease`) |
| Skill trees | n/a |
| Port form | `mutations/euphoria.ws`: `@addMethod` `GMGetToxicityDamage` (legacy's `GetToxicityDamage`), `W3Effect_Mutation10.GMGetDrainMult`; `@replaceMethod` `W3Effect_Mutation10.OnEffectAddedPost/GetStacks`, `W3PlayerAbilityManager.OnToxicityChanged` (5.x's start and stop removed) and `OnMutationEquippedPost` (only when overdosed); a scope-based override of `W3Effect_Mutation10.OnEffectAdded` (the start FX); the start and stop and the drain in `mutations/toxicity.ws`; `mutations/combatStart.ws` (`@replaceMethod W3PlayerWitcher.OnCombatStart`, for the mutations' combat-start rules); the damage in `ProcessDamageIncrease` (`damage/pool.ws`); the decoction start removed from SKL-13's `DrinkPreparedPotion`; DLC XML `Mutation10Effect` (whole, `replace`); description (MUT-14) |
| Port status | signed off (2026-10-17); verified in both trees |
| Open checks | a real sword hit (the hit was scripted; Igni was cast for real); a decoction drunk with Euphoria below the threshold (code read: 5.x's start removed) |
| Save impact | none |
| NG+ counterpart | applied (generated), untested |

**What it does:** only while overdosed (toxicity at or above the overdose threshold, legacy's 75%, ALCH-01) and in combat: the overdose's Vitality drain is × (1 + 0.75 × toxicity / 100), and that drain per second is added to the base damage of every sword hit and Sign (per damage type of the hit, as legacy's loop: a hit with three damage types gets it three times); it starts when Geralt is overdosed in combat or enters combat overdosed, and stops below the threshold and at combat end. 5.x's +0.75% attack power and sign intensity per toxicity point is gone. At 100 toxicity and 5380 Vitality: +47 per damage type, 47 Vitality lost per second. **Scales:** toxicity (overdose), max Vitality. **Build:** Alchemy (cornerstone).

**Decisions:**

- Legacy's own rule kept: Euphoria stops when toxicity falls below the threshold during the toxicity effect's update; toxicity set to 0 at once (a potion that clears it) ends the toxicity effect first, and Euphoria then lasts until combat ends.
- **Deviation:** the energy FX on hits is 5.x's (on melee and Sign hits on actors, not for channelled Signs); legacy played it on melee hits and once per Sign cast (porter's call, confirmed by the owner, 2026-10-17).
- The character stats popup shows Euphoria's damage bonus in the sword lines (UI-01) and the sign lines (UI-03) and the overdose drain with its factor (UI-04, 2026-10-21): the temporary deviation has ended.
- Euphoria starts and stops at the overdose threshold, legacy's 75% since [ALCH-01](alch.md#alch-01-toxicity-and-overdose) (2026-10-20; until then 5.x's 50%, a temporary deviation that ALCH ended).

**Slices:**

1. **The effect's rules, the drain, the damage, the description.** Verified 2026-10-17 in both trees (`gmtest_mut09(1..5)`: toxicity set and the combat-start event called by script, a scripted light hit and a real Igni cast read by the damage probe; `gmtest_mut09_drain`): no Euphoria below the threshold, also not at combat start; overdosed, the drain × (1 + 0.75 × toxicity / 100), added per damage type to a sword hit and to Igni, Vitality falling by it; stopped below the threshold; started at combat start overdosed. `GMTest_mut09` in the regression. Ends DMG's Mutation 10 term.

### MUT-10 Mutated Skin (Mutation 5)

| | |
|---|---|
| Kind | system |
| Pillars | P9, P2 |
| 5.x class | clean (units overlap) |
| Flags | balance |
| Depends on | DEF-01/02 (`ReduceDamage`, `defense/dodge.ws`), STAM-06/08 (`CActor.OnTakeDamage`), SKL-07 (Undying in `OnTakeDamage`, adrenaline), SKL-11 (the `player_had_quen` fact) |
| Skill trees | n/a |
| Port form | `mutations/mutatedSkin.ws`: a new effect type `EET_GMMutation5` (`GMMutation5Effect`, class `W3GMEffect_Mutation5 extends W3DamageOverTimeEffect`, legacy's `W3Effect_Mutation5`; registered in `effects/`, its ability and HUD entry in `gm_effects.xml`); `@addField`/`@addMethod` on `W3DamageAction` (`GMSetMutation5Triggered`); `GMMutation5Trigger`, called in the replaced `W3PlayerWitcher.OnTakeDamage`; the drain left out in the replaced `CActor.OnTakeDamage` (both in `mutations/takeDamage.ws`); `@replaceMethod W3PlayerAbilityManager.OnFocusChanged` (5.x's buff removed); 5.x's damage reduction removed from DEF's `ReduceDamage`, its combat-start buff from `mutations/combatStart.ws`; DLC XML `Mutation5` (whole, `replace`); description (MUT-14) |
| Port status | signed off (2026-10-17); verified in both trees |
| Open checks | real hits in a fight (scripted through the damage manager) |
| Save impact | none (a running DoT is a new effect type; a save holding 5.x's `EET_Mutation5` buff from a fight keeps it until combat ends) |
| NG+ counterpart | applied (generated), untested |

**What it does:** a hit taken (not a DoT, with damage) while Geralt has at least 1 adrenaline point is not dealt at once but as a DoT over 5 s per adrenaline point (max 15 s); meanwhile adrenaline drains by 1 point per 5 s, and at 0 the rest of the damage lands at once; a new hit is spread, with the remainder, over its new duration. Everything else treats the hit as dealt (only the Vitality drain waits). The DoT goes on after combat and after an unequip, as legacy's. 5.x's −15% damage per adrenaline point is gone. **Scales:** adrenaline (duration 5 s/pt, drain 1 pt/5 s), Vitality. **Build:** Defensive/adrenaline.

**Decisions:**

- The DoT is its own effect type (`EET_GMMutation5`): legacy changed `W3Effect_Mutation5`'s base class to the DoT class, which 5.x cannot do from a mod (a scope-based override keeps the base class). 5.x's `EET_Mutation5` is no longer added.
- **Deviation:** a new hit while the DoT runs adds its own damage to the remainder over the new duration; legacy's `CumulateWith` kept the previous damage rate instead (the base function does not take the new effect's value), so the new hit's damage was replaced by the old rate over the new duration, which could deal less or more than the hits; legacy's description says the skin absorbs and redistributes the damage (audit F3; project owner, confirmed 2026-10-17).
- `OnMutationUnequippedPre` stays 5.x's: its removal of `EET_Mutation5` now hits an unused effect, so the DoT outlasts an unequip, as legacy's.

**Slices:**

1. **The DoT, the drain, the description.** Verified 2026-10-17 in both trees (`gmtest_mut10(1..4)`: scripted hits of a test dummy on Geralt through the damage manager, his Vitality and adrenaline read over a few seconds): with the mutation and 2 adrenaline points nothing landed at once and the hit ran as a DoT over 10 s while adrenaline drained; at 0 adrenaline the rest landed; a second hit was spread with the remainder over its new duration; without the mutation the hit landed at once. `GMTest_mut10` in the regression. Found with it: a save from 5.x play can carry the `player_had_quen` fact, which cut the first DoT on Geralt to 0.1 s; it is removed on spawn, as legacy did (SKL-11).

### MUT-11 Cat Eyes (Mutation 9)

| | |
|---|---|
| Kind | tuning, system |
| Pillars | P7 |
| 5.x class | clean |
| Flags | balance |
| Depends on | XBOW (bolt damage, non-aimed bolts, `GetOffenseStatsList`), SKL-06 (crossbow skills), SKL-15 (the aiming slow motion, `skills/bombs.ws`), ALCH (toxicity) |
| Skill trees | n/a |
| Port form | DLC XML `Mutation9` (whole, `replace`: `mut9_damage` 1, `health_reduction` 0.15, `mut9_slowdown` 0.25; no `damage` or `critical_hit_chance`); the bolt's raw damage ×2 in `ProcessDamageIncrease` (`damage/pool.ws`, before the pool); 5.x's +150 removed from `GetTotalWeaponDamage` (`damage/weapon.ws`); the slowdown in SKL-15's replaced `PlayerAimingStateAiming.SloMo`; description (MUT-14) |
| Port status | signed off (2026-10-17); verified in both trees |
| Open checks | an aimed shot with the real key (the crossbow's aim cannot be scripted: tested by switching a bomb's aim to the crossbow's); the 15% health loss and knockdown (vanilla's code, unchanged; the pierce was seen in XBOW-05's shots, 2026-10-25: explosive bolts pierced and exploded again, plain bolts pierce and hit each enemy once, [xbow.md](xbow.md#xbow-05-bolt-hit-fixes)); the inventory's and character panel's crossbow damage (legacy doubles it in `GetOffenseStatsList`, with UI) |
| Save impact | none |
| NG+ counterpart | applied (generated), untested |

**What it does:** see [What Ghost Mode changed](#what-ghost-mode-changed). **Scales:** crossbow/bolt base damage, toxicity (> 0 for slow-mo), enemy at full Vitality. **Build:** Crossbow.

**Decisions:**

- The crossbow damage shown in the inventory and the character panel is doubled by Cat Eyes as legacy's since UI-01 (2026-10-21): the temporary deviation has ended.

**Slices:**

1. **Bolt damage, slow motion, description.** Verified 2026-10-17 in both trees (quick crossbow shots through the combat action, `gmtest_skl06_throw`, the damage probe; `gmtest_mut11_slomo`, an aimed bomb whose aim type was switched to the crossbow's by script): a bolt's raw damage doubled with Cat Eyes (5.x's +150 gone); aiming the crossbow with Cat Eyes and toxicity slowed time to ×0.35, otherwise ×0.6. `GMTest_mut11` in the regression. Ends DMG's Mutation 9 terms.

### MUT-12 Life Leech and Mutation Catalyst (Mutation 11)

| | |
|---|---|
| Kind | system, content |
| Pillars | P8, P7 |
| 5.x class | overlap |
| Flags | balance |
| Depends on | ALCH (potions, recipes), SKL-07 (Undying takes Second Life's role), SKL-11 (Quen during the effect), SKL-18 (a channel's start cost), STAM-01 (Quen's cooldown), DMG (`GetTotalWeaponDamage`), UI (the character stats list) |
| Skill trees | n/a |
| Port form | `mutations/lifeLeech.ws`: a new effect type `EET_GMMutationTrigger` (`GMMutationTriggerEffect`, class `W3GMPotion_MutationTrigger`, legacy's `W3Potion_MutationTrigger`); `@addMethod` `GMMutation11GetBaseStrength`; on `W3Effect_Mutation11Buff` `@addField`s, `@addMethod`s (legacy's `PlayDrainEnergy`, `AddDrainBuff`, `Impulse` as `GM...`), `@replaceMethod` `OnEffectAdded` and `OnEffectRemoved`, a scope-based override for `OnUpdate`; the recipe from a wrapper of `W3PlayerAbilityManager.OnMutationFullyResearched` and on load (MUT-01's `OnSpawned` wrapper); the death trigger removed in `mutations/takeDamage.ws`; the free Quen: `@replaceMethod W3PlayerWitcher.Mutation11ShockWave` (legacy's alternate Quen instead of 5.x's `RestoreQuen`), `@addField W3QuenEntity.gmFreeCast` (legacy's `freeCast`), read in SKL-18's `Channeling.OnThrowing` (`skills/rageManagement.ws`: nothing paid), STAM-03's `Channeling.Update` (`stamina/channelStamina.ws`: it ends with Life Leech) and STAM-01's `QuenChanneled.OnLeaveState` wrapper (`stamina/signCooldowns.ws`: no cooldown); DLC XML `Mutation11`, `Mutation11BuffEffect`, `Mutation11DebuffEffect` (whole, `replace`), the effect in `gm_effects.xml`, the item, its stats and the recipe in the new `items/gm_items.xml` (the DLC now mounts `items\` and `items_plus\`); strings: the description, the Catalyst's name and description, and the name "Life Leech" over 5.x's string 1188318 (`skill_name_mutation_11`) |
| Port status | signed off (2026-10-17); slices 1 to 3 verified in both trees |
| Open checks | owner: the feel of the drain; a real drink from a quick slot in a real fight (drunk by script with the inventory's function); the animation and the shield's look on screen (the animation's shock-wave event fired and gave the free Quen, read by script); the end impulse's knockdown (the frozen dummy was not seen knocked down 3 s later); the recipe added on load (code read); the Catalyst in the alchemy menu on screen (brewed by script) |
| Save impact | new item and recipe in saves (`gm_mutation_catalyst`, `gm_recipe_mutation_catalyst`; removing the mod, not supported mid-playthrough, leaves an unknown item); the recipe is added on load when Mutation 11 is researched |
| NG+ counterpart | the mutation values applied (generated); the item and recipe copied to `items_plus`; untested |

**What it does:** drinking the Mutation Catalyst (3 charges, 20 toxicity; the recipe comes with the research: White Gull, Rubedo, Nigredo, vampire blood) in combat with Life Leech equipped and off cooldown drains up to 3 hostile enemies within 30 m for 6 s, each at (sword base damage + average attack power % + average sign intensity %) × adrenaline ÷ enemies per second (at least 1), and heals Geralt as much; he is immortal meanwhile, with 5.x's shock wave and legacy's free alternate Quen (1000000 health, 10 s at most; no stamina, adrenaline or Flood of Anger; it absorbs every hit, ends with Life Leech and starts no Quen cooldown) during the animation; at the end a 5 m knockdown impulse (40 shock damage); then a 90 s cooldown (DM4). Second Life's heal at 0 Vitality is gone (Undying is the death save). **Scales:** sword base damage, attack power, sign intensity, adrenaline, enemies. **Build:** Hybrid (late-game sustain).

**Decisions:**

- Names: the item, the recipe and the effect carry Ghost Mode's prefix (`gm_mutation_catalyst`, `gm_recipe_mutation_catalyst`, `GMMutationTriggerEffect`; legacy: "Mutation Trigger"); the player sees legacy's "Mutation Catalyst" (porter's call, confirmed by the owner, 2026-10-17).
- The free Quen is legacy's (project owner, 2026-10-17): the shock wave builds an alternate Quen that is not the player's cast (no Flood of Anger, no adrenaline gain), marked free, with 1000000 health for 10 s; 5.x's `RestoreQuen` (the Quen restored after a load) is no longer used for it.
- **Deviation:** only Life Leech's free Quen skips Quen's cooldown; legacy skipped it for every alternate Quen that ended while Life Leech or its 90 s cooldown was on Geralt, so his own alternate Quen in those 90 s had none (audit F4, option (b); project owner, 2026-10-17).
- **Deviation:** the free Quen costs nothing at all: legacy's `freeCast` skipped only the basic shield's payment, so its free alternate Quen paid an alternate Quen's channel start like any other (stamina, or with Rage Management adrenaline when the start costs anything) (porter's call, confirmed by the owner, 2026-10-17).
- **Deviation:** the free Quen ends when Life Leech ends, also while the cast key is held; legacy's went on as a normal channel while the key was held, paying stamina per second (porter's call, confirmed by the owner, 2026-10-17).
- The drain's average attack power is read from the character stats list again, as legacy (per attack type and sword, crits weighted by the unclamped chance) since UI-01 (2026-10-21): the temporary deviation has ended.

**Slices:**

1. **The Catalyst, the drain, the cooldown, the description and name.** Verified 2026-10-17 in both trees (`gmtest_mut12(1, 2)`: the mutation researched, the Catalyst given and drunk with `DrinkPreparedPotion`, the inventory's function, by script; `gmtest_mut12_brew`: brewed through the alchemy manager by script): the research gave the recipe; the Catalyst drunk at 3 adrenaline started Life Leech, immortal, draining a test dummy at base × 3 for 6 s and healing Geralt as much, +20 toxicity; it ended with the 90 s cooldown, during which a second Catalyst did nothing; the recipe brewed a Catalyst from its four ingredients; the description and the name "Life Leech". `GMTest_mut12` in the regression.
2. **The classic tree's Precise Blows and Crushing Blows in the drain** (audit F1). Legacy's `Mutation11GetBaseStrength` reads `GetOffenseStatsList`, which adds the classic `sword_s17` (fast) and `sword_s08` (strong) crit chance and crit damage per level; the port's base strength now adds them too, as it already did the new tree's `sword_s24` and `sword_s25`. Verified 2026-10-17 in both trees (`gmtest_mut12_blows`: the base strength read by script before and after equipping the tree's two skills; the Catalyst drunk by script).
3. **Legacy's free Quen; Quen's cooldown only for Geralt's own casts** (audit F4, F5, the owner's decisions of 2026-10-17). Verified 2026-10-17 in both trees (`gmtest_mut12_quen(1..7)`: the Catalyst drunk by script with Rage Management and Active Shield equipped, the animation's shock-wave event firing in game; Geralt's own alternate Quen cast for real through the input handler): the free Quen is an alternate Quen in its channel with 1000000 health for 10 s, paid with neither adrenaline nor stamina; it ends with Life Leech without a Quen cooldown, also with the cast key held over the end; Geralt's own alternate Quen during Life Leech's cooldown gets Quen's cooldown. A real press during Life Leech does not cast: Geralt is held in the free Quen's channel (as legacy). `GMTest_mut12_quen` in the regression.

### MUT-13 Metamorphosis (Mutation 12)

| | |
|---|---|
| Kind | system |
| Pillars | P2, P7 |
| 5.x class | overlap |
| Flags | balance |
| Depends on | ALCH (decoctions, toxicity), SKL-13/SKL-16 (`DrinkPreparedPotion`, `HasFreeToxicityToDrinkPotion`, `ToxicityLowEnoughToDrinkPotion`, Adaptation), SKL-08/09/14/03 (the knockdown roll, Igni's burning, Poisoned Blades, Crippling Strikes), EFX (critical effects) |
| Skill trees | both (Signs and swords) |
| Port form | `mutations/metamorphosis.ws`: `@addMethod` `GMMutation12ChanceMult`, `GMMutation12FreeDecoction`; `@replaceMethod` `AddMutation12Decoction` (empty) and `W3EffectManager.AddEffectsFromAction` (non-sign effects through `GMNonSignApplyBuffTest`, legacy's `GetNonSignApplyBuffTest`); lines in SKL's replaced potion functions and chance functions; DLC XML `Mutation12` (whole, `replace`: maxcap 3, `mut12bonus` 0.1); description (MUT-14) |
| Port status | signed off (2026-10-17); verified in both trees |
| Open checks | the factor on Igni's burning, the knockdown roll, Poisoned Blades and Crippling Strikes in play (the same function as the tested effect chance; code read); a decoction drunk from the inventory or a quick slot (the drink function was called by script); the character stats popup's chance lines (with UI) |
| Save impact | none |
| NG+ counterpart | applied (generated), untested |

**What it does:** up to 3 decoctions drunk while it is equipped cost no toxicity; each such decoction active multiplies the chance of the critical effects Geralt applies (swords, Signs, bolts, bombs, oils) by 1 + 0.1 × n (max ×1.3); vanilla's random decoction on critical effects is gone; unequipping it removes the free decoctions (vanilla). **Scales:** decoctions (count), critical-effect chances, toxicity. **Build:** Alchemy/decoctions.

**Decisions:**

- With legacy's `GetNonSignApplyBuffTest` (attributed to MUT-13 only), the negative effects of Geralt's and every other actor's non-sign actions are now resisted: the chance is × (1 − the target's resistance) (5.x: the bare chance). "Negative" is the game's `IsNegativeEffectType`: critical effects (burning, knockdowns, staggers, blindness, freezing...) and a few drains and slowdowns; bleeding and poison are not, so their chances are not resisted or raised.
- The character stats popup's chance lines include Metamorphosis's bonus since UI-02 (the swords' effect chances) and UI-03 (Aard's knockdown, Igni's burning; 2026-10-21): the temporary deviation has ended.

**Slices:**

1. **Free decoctions, the chance factor, the description.** Verified 2026-10-17 in both trees (`gmtest_mut13_drink`: `DrinkPreparedPotion`, the inventory's and quick slots' drink function, called by script; `gmtest_mut13_effect`: scripted hits carrying burning with chance 1): three decoctions free of toxicity raising the factor to ×1.1, ×1.2, ×1.3, a fourth paying its toxicity; burning resisted by the target's burning resistance and raised by the factor; the description's values. `GMTest_mut13` in the regression. Ends SKL's temporary deviations on Metamorphosis (the knockdown roll, Igni's burning, Poisoned Blades).

### MUT-14 Mutation descriptions and HUD

| | |
|---|---|
| Kind | ui |
| Pillars | P7 |
| 5.x class | clean (5.x changed only Mutation 6's string) |
| Flags | — |
| Depends on | MUT-02 to MUT-13 (values), UI (HUD buff module, the character stats popup) |
| Skill trees | both menus show the same tooltip (`GetMutationLocalizedDescription`) |
| Port form | `mutations/mutationDescriptions.ws`: a wrapper of `W3PlayerWitcher.GetMutationLocalizedDescription` returns `GMMutationDescription` (legacy's text and live values) for every mutation; strings `gm_mutation_desc_<n>` under legacy's ids, legacy's rows in all 9 languages (as SKL-19: legacy's rows as shipped, English where legacy had no translation); Mutation 11's name over 5.x's string (MUT-12); `mutations/hudCounters.ws`: `@replaceMethod CR4HudModuleBuffs.UpdateBuffs`, Toxic Blood's and Euphoria's counters as numbers (the file also replaces `OnTick` for [ARM-06](arm.md)'s Feline chain) |
| Port status | signed off (2026-10-17); the descriptions with each mutation's slice and the HUD counters verified in both trees |
| Open checks | the texts in a language other than English in game (the regression checks the English ones) |
| Save impact | none |
| NG+ counterpart | none |

**What it does:** legacy's descriptions with live values for all 12 (filled at base stats in the [tree files](../skill-trees/)); Mutation 11's name "Life Leech"; the Mutation Catalyst's name and description; the HUD counters: Toxic Blood's (the acid's damage per second) and Euphoria's (the damage added per hit) as numbers (5.x: percentages); Bloodbath's stays a percentage; Mutated Skin's damage over time shows with its timer (its own effect, MUT-10). GM's own keys replace legacy's rows keyed by vanilla key hashes (`c3f5389b`…), so the wrapper decides which text shows. The character stats popup's mutation lines are UI's (deviations in MUT-07, MUT-08, MUT-09, MUT-11, MUT-13).

**Slices:**

1. **Descriptions** (with each mutation's slice, MUT-02 to MUT-13): each read through `GetMutationLocalizedDescription`, the menus' call, in English, with its live values.
2. **The HUD counters.** Verified 2026-10-17 on screen (classic tree; the effects added by script, `gmtest_mut14_hud`): Toxic Blood's and Euphoria's counters as numbers without a percent sign; Mutated Skin's damage over time with its icon and timer.
3. **Regression checks of the texts** (audit F11). `GMTest_mut14` in `gmtest_regress()`: the twelve descriptions through `GetMutationLocalizedDescription` (each Ghost Mode's text, no `$` argument left, no missing string, not empty), Mutation 11's name "Life Leech" (string 1188318), the Catalyst's name and description, and its recipe (four ingredients, one Catalyst). Passes in both trees (English).

---

### Mutations in two trees

The mutations' effects and research costs are the same in both trees: legacy's (DM1, project owner, 2026-10-11). How (verified in both trees with MUT-01, 2026-10-17):

- **Research costs.** `W3PlayerAbilityManager.LoadMutationData` refreshes each mutation's required skill points and mutagens from `<custom><mutations>` into the saved `mutations[]` array on every load. They are plain script fields, so a wrapper can apply legacy's costs after it, whichever tree is active. MUT-01 needs no XML override of `<custom><mutations>` (whether a DLC could override it is untested and not needed).
- **Switching trees** is not a normal workflow (project owner, 2026-10-05). It goes through Ghost Mode's character reset ([SKL-01](skl.md#skl-01-skill-system-rules), D44), which refunds mutation research (skill points and mutagens) with everything else. Note: 5.x's own skill reset (`RemasterSkillResetAndRefund`) deliberately keeps researched mutations and their points.
- **On the costs.** Legacy cut the research costs from vanilla's 53 skill points to 29 (not in the changelist); 5.x kept vanilla's 53. The port uses legacy's 29 in both trees.

### Area decisions

The mutations are legacy Ghost Mode's in both trees (project owner, 2026-10-05):

| # | Question | Decision |
|---|---|---|
| DM1 | Research costs: Ghost Mode's 29 skill points or 5.x's 53 | **Legacy's 29 skill points in both trees** (project owner, 2026-10-11; [how](#mutations-in-two-trees)) |
| DM2 | Piercing Cold: keep 5.x's exclusion of Eredin, Imlerith and Caranthir from the instant kill | **As legacy: no exclusion** (2026-10-05) |
| DM3 | Piercing Cold and supercharged Aard (new tree only): 5.x gives no freeze | **As legacy** (project owner, 2026-10-11): a Flood of Anger Aard behaves as in legacy, like SKL's other Flood of Anger casts (D16) |
| DM4 | Life Leech's cooldown: 90 s (code, changelist) or 120 s (design notes) | **90 s** (2026-10-05) |
