# STAM: stamina and cooldowns

Ghost Mode makes combat a stamina economy (pillar P2): every action costs stamina, regen is tuned, and signs trade the vanilla "drain the whole bar" cost for a moderate cost plus a cooldown (P3). All of it is configurable in Options → Mods → Ghost Mode (see [OPT-01](opt.md#opt-01-ghost-mode-options-framework)). Source: the changelist's "Stamina changes" and "Mod options" sections.

**How legacy Ghost Mode implements it.** `W3GameParams` (`gameParams.ws`) gains cached getters that read the options (`GetSignCooldownDuration`, `GetSignStaminaCostMult`, ...). `scripts/gm_generic/gm_options.ws` has small helpers that apply them (`gmModSignStaminaCost`, `gmModRegenValue`, ...) and the defaults. Cooldowns are new effect types, each with an effect class and an XML ability, applied by the casting code and checked before acting.

**What 5.x did in this area.** Signs still cost 100 stamina (the whole bar) and there are no general sign cooldowns. Melee is still free. 5.x's reworked skills add new ways to pay for signs: `S_Magic_s39` (Avoidance) lowers sign stamina cost, `S_Perk_34` and "supercharged" signs let signs be cast with adrenaline, and the new `S_Magic_s40` (Overload) has a 2 s cooldown built exactly like Ghost Mode's (effect type `EET_OverloadCooldown`, effect class, registration in `gameEffectManager.ws`). Whirl and Rend were reworked (Whirl: 75 stamina/s plus adrenaline; Rend: damage bonus 0.5 → 1.5). The stamina regen effect is unchanged.

1068 units are attributed to this area, 910 of them XML (NPC abilities' stamina values, armor items' regen modifiers, skills); 200 were also changed by 5.x and need a hand merge. Unit lists: [attribution.csv](attribution.csv). The area was mapped from the changelist first and completed on 2026-10-02 by a sweep of every unit whose Ghost Mode change touches stamina (scripts and XML); stamina effects that belong to other areas are listed in [Hand-off to other areas](#hand-off-to-other-areas).

---

### STAM-01 Sign cooldowns

| | |
|---|---|
| Kind | system |
| Pillars | P3, P2 |
| 5.x class | conflict |
| Flags | balance |
| Depends on | OPT-01 |
| Skill trees | both: the cooldowns hook the sign cast states, not skills, so they cover every sign skill (classic `magic_s1` to `s5`; the new tree's shared `magic_s1`, `s3`, `s4` and its `magic_s28` Firestream, `magic_s31` Puppet) |
| Port form | enum extension, effect classes; `@wrapMethod` on the sign cast states, `W3SignEntity.ManagePlayerStamina`, `CPlayerInput.OnCastSign`/`AltCastSign`, `CActor.IsImmuneToBuff` and the effect registration; DLC XML for the HUD icons and labels. In `stamina/signCooldowns.ws`, `effects/gmEffectRegistration.ws`, `gm_effects.xml` |
| Port status | signed off (2026-10-04; [audit](#stam-audit-2026-10-03)) |
| Open checks | — |
| Save impact | none (expected) |
| NG+ counterpart | applied and scaled, untested ([NG+ copies](#stam-audit-2026-10-03)) |

**What it does:** after casting a sign, that sign cannot be cast again for 5 s (normal cast) or 7.5 s (alternate cast). Both durations are options ("Sign cooldown", "Alternate Sign cooldown"); 0 turns a cooldown off. Each sign has its own cooldown, shown as a buff.

**Implementation (legacy):** new effect types `EET_AardCooldown` … `EET_AxiiCooldown`, effect classes `skill/<Sign>Cooldown.ws` (durations from `W3GameParams`), XML abilities `<Sign>CooldownEffect` in `effects.xml`, registration in `gameEffectManager.ws`. Each sign entity's cast state adds the cooldown, `CPlayerInput.CastSign` refuses while `IsSignOnCooldown`, and the buff immunity functions skip cooldowns. 40 units.

**5.x:** no general sign cooldown exists; 5.x's Overload (`S_Magic_s40`) has a 2 s cooldown built the same way, which shows the pattern works. 5.x changed 5 of the units (the enum, the three registration functions, `W3AardEntityStateAardCircleCast.OnThrowing`). Its new sign skills (Avoidance, adrenaline casting, Overload, supercharged signs) change how often signs can be cast.

**Decisions:** port (2026-10-02). Everything fits the 5.x port forms without replacing vanilla code. Where 5.x moved things, the hooks moved with them: 5.x has no `CastSign()`, so both cast input events are wrapped; 5.x pays Quen in its `ShieldActive` state, so normal casts are caught in `ManagePlayerStamina`; Igni's alternate cooldown is added when the channel state is left (a stream run down to 0 ends through `OnSignAborted`, not `OnEnded`), as legacy did; an aborted Axii puppet gets no cooldown, as in legacy. Names carry the `GM` prefix. Re-tune the defaults in the balance pass.

**Slices:**

1. **Effects, options, HUD.** Verified 2026-10-02 (`gmtest_stam01`, scripted): the effects register, durations follow the options, the cooldown check works, HUD icons and labels come from the DLC.
2. **Casting.** Verified 2026-10-02 (`gmtest_stam01_press/release/after`, real casts through the input handler, alternate casts with `autocast`; a fight with wolves): all five signs get 5 s after a normal cast and 7.5 s after an alternate one, and a second cast during the cooldown is refused; an Igni stream run down to 0 stamina gets its cooldown. 2026-10-03: the same for the new tree's Firestream and Puppet (real casts with `autocast`).

**Balance values:** sign cooldown 5 s, alternate 7.5 s (options).

---

### STAM-02 Whirl and Rend cooldowns

| | |
|---|---|
| Kind | system |
| Pillars | P2 |
| 5.x class | overlap |
| Flags | balance |
| Depends on | OPT-01, STAM-01 (shared effect registration) |
| Skill trees | both: Whirl (classic `sword_s1`, new `sword_s35`) shares one input event and attack state; Rend `sword_s2` is shared |
| Port form | as STAM-01 (enum extension, effect classes, registration, DLC XML); `@wrapMethod` on `W3PlayerWitcherStateCombatSword.OnPerformSpecialAttack` (the attack ends) and `CPlayerInput.OnCbtSpecialAttackLight/Heavy` (presses refused); option. In `stamina/meleeSpecialCooldowns.ws` |
| Port status | signed off (2026-10-04; [audit](#stam-audit-2026-10-03)) |
| Open checks | — |
| Save impact | none (expected) |
| NG+ counterpart | applied and scaled, untested ([NG+ copies](#stam-audit-2026-10-03)) |

**What it does:** after Whirl ends, Whirl cannot be used again for 7.5 s; the same for Rend (each has its own cooldown, shown as a buff). Option "Melee special cooldown" (`GMMeleeSpecialCooldown`; 0 turns the cooldowns off).

**Implementation (legacy):** effect types `EET_WhirlCooldown`/`EET_RendCooldown`, effect classes and XML abilities, applied in `W3PlayerWitcherStateCombatSword.PerformSpecialAttackLight/Heavy`, checked in `CPlayerInput.OnCbtSpecialAttackLight/Heavy`. 19 units, plus the registration shared with STAM-01.

**5.x:** Whirl and Rend were reworked: the new tree's Whirl drains 75 stamina per second and costs adrenaline, Rend's damage bonus tripled. 5.x changed both input handlers. 5.x's adrenaline cost limits Whirl spam its own way, overlapping with the cooldown's purpose.

**Decisions:** port with its option (2026-10-02); the default is set in the balance pass, after seeing what 5.x's Whirl and Rend cost under Ghost Mode's stamina rules. A wrapper on the state's entry functions `PerformSpecialAttackLight/Heavy` compiles but never runs, so the port wraps the event that calls them, `OnPerformSpecialAttack`, with the same conditions. Releases always pass, so a held attack can end. The stamina costs of Whirl and Rend are [STAM-09](#stam-09-whirl-and-rend-stamina-costs).

**Slices:**

1. **Effects and option.** Verified 2026-10-02 (`gmtest_stam02`, scripted): the effects register, the duration follows the option, HUD icons and labels, not blocked by immunities, option 0 turns them off.
2. **Whirl and Rend.** Verified (`gmtest_stam02_press/release/after/refused`, scripted input, real attacks in a fight): the attack runs while held, its cooldown starts when it ends, the other attack is not affected, a second press during the cooldown starts nothing. Classic `sword_s1` 2026-10-03 with the classic tree setting on; new tree `sword_s35` 2026-10-03; Rend 2026-10-02.

**Balance values:** melee special cooldown 7.5 s (option).

---

### STAM-03 Stamina costs for every action

| | |
|---|---|
| Kind | system, tuning |
| Pillars | P2, P3 |
| 5.x class | overlap |
| Flags | balance |
| Depends on | OPT-01 |
| Skill trees | both: sign costs on `magic_1` to `magic_5`; alternate sign costs on the shared `magic_s1`, `s3`, `s4`, the classic `magic_s2`, `s5` and the new tree's `magic_s28`, `s31` (`gm_skills.xml`) |
| Port form | DLC XML `extend` of `ConGeralt` and the sign skills (`gm_stats.xml`, `gm_skills.xml`); wrappers on the cost functions and a scope override of `W3GameParams` (`stamina/staminaCosts.ws`); parry and counter checks (`stamina/parryStamina.ws`); refusals, charge timing, bombs, crossbow, items and sprint (`stamina/actionStamina.ws`); horseback (`stamina/horseStamina.ws`); the alternate Yrden and Axii channels (`stamina/channelStamina.ws`: `@replaceMethod` of `W3SignEntityStateChanneling.Update` and `W3PlayerAbilityManager.DrainStamina`) |
| Port status | signed off (2026-10-04; [audit](#stam-audit-2026-10-03)) |
| Open checks | sprint start out of combat and the 2 s sprint lockout with the real sprint key (`CanSprint` reads the key; the lockout is checked by a scripted call); the heavy and super-heavy parry multipliers (wolves only attack light); the counter check; a horseback attack with stamina between 1× and 3× the light cost; Ciri |
| Save impact | none (expected) |
| NG+ counterpart | applied and scaled, untested ([NG+ copies](#stam-audit-2026-10-03)) |

**What it does:** every combat action costs stamina, and an action without enough stamina is refused (attacks, dodges, rolls, bombs, crossbow and usable items, on foot and on horseback; signs as in vanilla), except parrying, which becomes a partial parry (parried, but staggered and partly hurt). Attacks are paid at the swing's hit frame, hit or miss (a swing cancelled before it is free); finishers are free; bombs are paid on the throw, bolts when released. A sign costs 40 (vanilla 100); channeled signs drain per second and end at 0 stamina: Aard sweep 40 (vanilla 60), Igni stream 30/s (50), Yrden trap 26.8/s (35), active Quen 20/s (15), Axii puppet 16/s (22.2). Options multiply the cost of agility actions (sprint, jump), melee and signs (cost × (1 + value), default 0). Every cost, for every actor, is capped at 100. Parrying a heavy attack costs 1.25× the parry cost, a super-heavy one 1.5× (vanilla 2× for both); a counter costs the same against any attack (vanilla 2× against a heavy one). Out of combat a sprint can start with any stamina (vanilla: above 90%); after a sprint stops at 0 stamina, sprinting is blocked for 2 s. The character panel lists every action's cost. Ciri does not use stamina, except 100 for her blink, as in vanilla.

**Implementation (legacy):** base costs in `ConGeralt` (`geralt_stats.xml`: light 6.666, heavy 10, parry 5, counter 6.666, dodge and evade 5, roll 10, sprint 10/s, jump 10, usable item 5; vanilla 0 except sprint and jump 12.5) and `magic_1` to `magic_5` `stamina_cost` 100 → 40; `W3PlayerAbilityManager.GetStaminaActionCost` and `GetSkillStaminaUseCost` apply the options, the cap and other features' modifiers; `CR4Player.HasStaminaToUseSkill`, `CActor.HasStaminaToParry` (heavy multiplier removed; callers pass it) and the parry flags enforce costs; `W3PlayerWitcher.CanSprint` adds the 2 s lockout; `W3GameParams` heavy-strike multipliers. 31 units.

**5.x:** melee is still free and signs still cost 100, and 5.x's new sign skills are built around that cost: Avoidance (`S_Magic_s39`) reduces it, adrenaline casting (`S_Perk_34`, supercharged signs) bypasses it. 5.x changed `GetStaminaActionCostInternal`, `HasStaminaToUseSkill` and `ManagePlayerStamina` for them.

**Decisions:** port Ghost Mode's cost model (cheap signs plus cooldowns, paid melee) and apply its multipliers on top of 5.x's cost rules, so Avoidance and adrenaline casting keep working with a 40 cost; whether those skills still make sense is judged in the balance pass (SKL) (2026-10-02). Avoidance (Sidestep) is dropped by SKL's D58 (2026-10-15). Legacy's changes to the cost functions also carry other features' rules (armor class modifiers, overencumbrance, the Griffin perk and set, glyphwords, mutagens, adrenaline-first casting); they stay with their features ([hand-off](#hand-off-to-other-areas)). Deviations and notes:

- Counters cost the same against any attack, as in legacy (project owner, 2026-10-04; in DEF-06's replacement of `PerformCounterCheck`, `defense/counter.ws`). Until then the port kept vanilla's counter check, whose heavy-attack multiplier read Ghost Mode's lowered `HEAVY_STRIKE_COST_MULTIPLIER` (1.25; vanilla 2).
- <a id="stam-03-channeled-signs"></a>*Channeled signs:* 5.x drains channels per second and ends them at 0 stamina, as legacy, so the XML costs suffice, with one legacy exception ported: the alternate Yrden (trap) and Axii (puppet) channels finish even at 0 stamina, or 0 adrenaline when casting with it; releasing the sign still ends them. Today they cannot run dry (a cast needs 40 to start, the whole channels cost about 37 and 38), but skills or items that lower a sign's start cost or raise its channel cost could change that (project owner, 2026-10-04). For it, as in legacy, a drain that empties stamina no longer aborts the sign being cast (vanilla's `W3PlayerAbilityManager.DrainStamina`); every other channel still stops itself at 0. The rest of legacy's channel rework is SKL or STAM-01.
- **Deviation:** legacy's moved charge points for normal casts are not ported: legacy charged Yrden and Quen at the throw, like the other signs; 5.x charges them when the trap or shield becomes active, which in game happens at the throw (all five measured charging once, at the throw). Only a cast interrupted between the throw and the active state would differ (porter's call, 2026-10-03, not confirmed by the owner).
- *Horseback:* a sword attack costs 3× the light-attack cost (legacy's `ON_HORSEBACK_STAMINA_MULTIPLIER`, `GMHorsebackStaminaMult()`). Legacy's other horseback changes are HORSE's.
- **Deviation:** a horseback sword attack is paid in `SwordAttack.DoAttack`, which both swing paths run; legacy paid on the button release, which missed the quick swing (a legacy gap; porter's call, not confirmed by the owner).
- *Partial parry:* Ghost Mode parries anyway and marks the hit as a parry-stagger in `ProcessAction` (since the DEF audit, in DEF-05's replacement of it, `defense/processAction.ws`, unless the attack knocks down or staggers), which lets part of the damage through (50% since DEF-05; vanilla's share was about 28%). The stagger it adds was not applied (vanilla's `ProcessActionBuffs` skips all effects of a parried hit of a parryable attack; legacy had the same gate); DEF-05 applies it ([DEF-05](def.md#def-05-parrying-rules)). The rest of legacy's parry rework is DEF's.
- *Ciri* needs no code: the options and base costs apply to Geralt only, and her parry check always passes in 5.x.
- The test counter `gmStaminaRefusals` stays in `actionStamina.ws` (it only counts; accepted at the audit).

**Slices:**

1. **Costs and options.** Verified 2026-10-02 (`gmtest_stam03`, scripted read-back, one real Aard cast): every action's cost, sign cost 40, the options, the cap, the heavy parry multiplier.
2. **Parry and counter.** Verified 2026-10-02 (`gmtest_stam03_parry_a/b`, real wolf attacks on a guarding Geralt): with stamina, full parries at 5 each; at 0, partial parries that let about 28% through (50% since DEF-05). The test counted the parry-stagger flag, not the effect, which was not applied; since DEF-05 it checks the effect and passes (2026-10-04).
3. **Refusals and charge timing.** Verified 2026-10-02 (`gmtest_stam03_act_a/b`, `gmtest_stam03_bomb_a/release/b`, scripted input, real attacks, dodges and bomb throws): attacks charged once at the hit frame, dodges and rolls at the press, a bomb at the throw; all refused at 0 stamina. Finishers free: verified with STAM-06's real finisher (2026-10-03).
4. **Alternate and channeled signs.** Verified (`gmtest_stam03` read-back; `gmtest_stam03_chan_a/b`, real casts with `autocast`): every alternate drains its cost per second (the Aard sweep once) and ends at 0 or on release; normal casts charge 40 once at the throw. 2026-10-03: Firestream and Puppet, real held casts, 30/s and 16/s.
5. **Horseback.** Verified 2026-10-02 (`gmtest_stam03_mount`, `gmtest_stam03_horse_a/b`, scripted input, real swing and shot): a swing charged 3× the light cost when swung, a crossbow shot its item cost; at 0 the sword, crossbow and bombs are refused.
6. **Character panel.** Verified (`gmtest_panel`, scripted read of the panel's data): the cost lines.
7. **Audit fixes** (5.x-GM `f8c8d108`): the 2 s sprint lockout (`@wrapMethod(W3PlayerWitcher) CanSprint`), `HasStaminaToParry` without vanilla's heavy multiplier (`@replaceMethod(CActor)`, used by NPC parries and STAM-08's shield rule), the cap for every actor. Verified 2026-10-03 (`gmtest_stamaudit`, scripted, a ghoul in range): a cost of 150 capped at 100 for Geralt and the ghoul; sprint refused right after stopping at 0; the ghoul (parry cost 20) can parry a heavy attack at 22 stamina.
8. **Alternate Yrden and Axii finish at 0 stamina** (5.x-GM, not pushed). Verified 2026-10-04 (`gmtest_stam03_chan_a`, `gmtest_stam03_chan_empty`, `gmtest_stam03_chan_b`; real held alternate casts with `autocast`, stamina emptied by script mid-channel, sign cooldowns set to 0 and restored): the alternate Yrden kept channelling at 0 and placed its trap; the classic alternate Axii and the new tree's Puppet, cast at a hostile bandit, kept channelling at 0 to the channel's end and puppeted it, as casts with full stamina did (same channel length; the puppet read when the channel ends, by a test probe on `W3AxiiEntity.OnEnded`); Firestream, without the exception, stopped at 0. Regression run 176 + 9 passed.

**Balance values:** sign cost 40 (vanilla 100); action costs as above; parrying heavy ×1.25, super-heavy ×1.5 (vanilla ×2); per-action multipliers (options, default 0).

---

### STAM-04 Stamina regen

| | |
|---|---|
| Kind | tuning, system |
| Pillars | P2 |
| 5.x class | clean |
| Flags | balance |
| Depends on | OPT-01 |
| Skill trees | n/a |
| Port form | DLC XML `extend` of `ConGeralt` (`gm_stats.xml`); `@replaceMethod` of `W3Effect_AutoStaminaRegen.OnUpdate` and `SetEffectValue` (`stamina/staminaRegen.ws`); character panel lines by `@wrapMethod` on the global `AddCharacterStat` (`ui/characterStatsPopup.ws`) |
| Port status | signed off (2026-10-04; [audit](#stam-audit-2026-10-03)) |
| Open checks | — |
| Save impact | none (expected) |
| NG+ counterpart | applied and scaled, untested ([NG+ copies](#stam-audit-2026-10-03)) |

**What it does:** regen is 15 per second (vanilla 10); while guarding it is 50% of normal (vanilla: a fixed value unaffected by buffs). Options add to combat and out-of-combat regen. The character panel shows the modified values.

**Implementation (legacy):** `W3Effect_AutoStaminaRegen` (`OnUpdate`, `SetEffectValue`, `OnLoad`, fields), `gmModRegenValue` (also the vitality regen options), `gmUpdateRegenEffects`, `W3EffectManager.FilterAutoBuff`, `AddCharacterStat`, the regen getters. 11 units, all unchanged in 5.x.

**5.x:** unchanged.

**Decisions:** port the default, without the armor regen modifier (2026-10-02). `FilterAutoBuff` is not needed for stamina. Re-check the rates in the balance pass.

- **Deviation:** with STAM-05's option on, 5.x's own armor calculation applies, not legacy's rework of it (which ignored the Hearts of Stone glyphwords' regen and added regen per missing armor piece), and legacy's per-item `staminaRegen_armor_mod` values (e.g. heavy armor −0.10 → −0.30), which matter only with the option on, are not ported; they are attributed here (temporary, until ARM and the glyphwords; porter's call, 2026-10-02, not confirmed by the owner).
- **Deviation:** the regen effect recomputes its value on every update, in and out of combat (legacy and vanilla: in combat only), so option changes apply at once (porter's call, not confirmed by the owner).
- **Deviation:** the character panel's out-of-combat regen line leaves out the armor modifier (legacy showed it), because the effect applies it in combat only (porter's call, not confirmed by the owner).

**Slices:**

1. **Regen and options.** Verified 2026-10-02 (`gmtest_stam04_a/b`, scripted read-back; `gmtest_stam04_c/d/e`, real regen measured in a wolf fight, guarding set by script): 15/s in combat, 20/s with the combat option at +5, 7.5/s guarded, 10/s guarded with +5.
2. **Character panel.** Verified 2026-10-02 (`gmtest_panel`, scripted read of the panel's data): the regen lines include the options.
3. **`@replaceMethod` instead of a scope override** (5.x-GM, 2026-10-04; the [rule](../development.md#choosing-a-technique)). Verified 2026-10-04 (`gmtest_annotations`, scripted, in `gmtest_regress()`: the option recomputed out of combat, STAM-07's wrapper still runs; `gmtest_stam04_c/d/e`, real regen in a wolf fight: 15.0/s, 20.0/s with the option at +5, guarded as before; a bite during the sample window can pause regen and spoil a sample).

**Balance values:** regen 15/s; guarded 50%; option offsets.

---

### STAM-05 Armor stamina regen penalties removed

| | |
|---|---|
| Kind | tuning |
| Pillars | P4, P2 |
| 5.x class | clean |
| Flags | balance |
| Depends on | OPT-01 |
| Skill trees | n/a |
| Port form | `@wrapMethod` on `W3PlayerWitcher.CalculatedArmorStaminaRegenBonus` (feeds the regen effect and the panel) and `CInventoryComponent.GetItemTooltipAttributes`/`GetItemStatsFromName` (the armor regen line); option. In `stamina/armorRegenPenalty.ws` |
| Port status | signed off (2026-10-04; [audit](#stam-audit-2026-10-03)), except Ghost Mode's tooltip row for the modifier (ported with the other `tooltip_settings.csv` rows) |
| Open checks | — |
| Save impact | none (expected) |
| NG+ counterpart | none |

**What it does:** armor no longer changes stamina regen (vanilla gives armor pieces regen penalties or bonuses); the option "Enable stamina regen penalty for armors" (`GMArmorRegenPenalty`, default off) restores 5.x's calculation. Tooltips and the character panel hide the modifier when it is off; with it on, the panel shows it under the regen lines ("Stamina regeneration modifier", legacy string 2110992263; legacy put it under Armor). Armor classes affect stamina costs instead (ARM).

**Implementation (legacy):** `W3GameParams.IsArmorRegenPenaltyEnabled`, `W3RegenEffect.OnUpdate`, `W3PlayerWitcher.CalculatedArmorStaminaRegenBonus`, `CInventoryComponent.GetItemStatsFromName`, tooltips (`AddItemStats`, `CalculateStatsComparance`), character panel. 8 units, all unchanged in 5.x.

**5.x:** unchanged.

**Decisions:** port as is. Vanilla (legacy and 5.x) has no `tooltip_settings.csv` row for `staminaRegen_armor_mod`, so the line never shows; Ghost Mode adds one along with 55 other tooltip rows; the filter keeps it out while the option is off.

- **Deviation:** the tooltip row is not ported yet: it comes with Ghost Mode's other tooltip rows, to avoid a whole-file override of the CSV for one row; it is attributed here (temporary, until those rows are ported; porter's call, not confirmed by the owner).

**Slices:**

1. **Penalty removed, option.** Verified 2026-10-02 (`gmtest_stam05`, scripted, `Heavy armor 01` equipped, modifier −10%): option off, bonus 0 and no armor regen line in the item stats; on, −0.1. Real regen in a fight (`gmtest_stam04_c/d/e`): 15.0/s off, 13.5/s on. Panel (`gmtest_panel`, scripted): no modifier line off; "−10 %" and the lower regen on.

---

### STAM-06 Regen pause after actions

| | |
|---|---|
| Kind | system, tuning |
| Pillars | P2 |
| 5.x class | conflict |
| Flags | balance |
| Depends on | OPT-01 |
| Skill trees | both: delays on `magic_1` to `magic_5`, the alternate sign skills (`magic_s1` to `s5`, `magic_s28`, `magic_s31`), Whirl (classic `sword_s1`, new `sword_s35`) and Rend `sword_s2` |
| Port form | DLC XML (`gm_stats.xml`, `gm_skills.xml`); the delay option in the `GetStaminaActionCost` wrapper (`stamina/staminaCosts.ws`), so `DrainStamina` stays vanilla; `@wrapMethod` on `CActor.OnTakeDamage` and the finisher, combat-end and spawn events (`stamina/regenPause.ws`) |
| Port status | signed off (2026-10-04; [audit](#stam-audit-2026-10-03)) |
| Open checks | the pauses after real dodges and attacks (measured with scripted drains); the boss exemption; no pause after a killing blow; DoT from effects; whether regen resumes at the finisher's end or at the end of combat |
| Save impact | none (expected) |
| NG+ counterpart | applied and scaled, untested ([NG+ copies](#stam-audit-2026-10-03)) |

**What it does:** every action, sign and alternate sign, Whirl and Rend pause stamina regen for 1 s; the option "Stamina regen delay" (`GMStaminaDelay`, default 0, −1 to 5) adds to every pause of Geralt's, floored at 0. A hit that deals damage pauses the victim's regen for severity / 4 s (severity 0–4: one step per 5% of max health, scaled down for victims taller than 2 m), on every actor except bosses and DoT from effects, not after a killing blow. Regen is paused during finishers.

**Implementation (legacy):** delays in `ConGeralt` (every action 1 s; vanilla 0 to 1 s) and `stamina_delay` 1 s on the sign skills, `sword_s1` (Whirl, vanilla 2 s) and `sword_s2` (Rend, vanilla 0.5 s); `W3AbilityManager.DrainStamina` adds the option; `CActor.OnTakeDamage` pauses by hit severity (`GetHitSeverityFromDamageData`, bosses excluded by `HideHealthBarModule`); Rend's charge (`SpecialAttackHeavySustainCost`) and finishers (`OnFinisherStart`) pause, `OnPerformSpecialAttack`, `CancelHoldAttacks`, `OnFinisherEnd`, `OnCombatFinished` and `OnSpawned` resume. NPCs' per-action pauses are [STAM-08](#stam-08-npc-stamina).

**5.x:** 5.x changed `DrainStamina` (Avoidance's sign cost reduction).

**Decisions:** port, applying the delay where the cost is computed so `DrainStamina` stays vanilla. A delay read with `GetStaminaActionDelay` and then passed to a fixed-value drain goes through the wrapper twice; `GMFixedDrainDelay` takes the option out first, so it counts once (Whirl, Rend's minimum cost). Rend needs no code: its charge drains each tick with Rend's 1 s delay, and a Rend cannot be held past full charge, so legacy's open-ended Rend pause adds nothing.

**Slices:**

1. **Action delays and option.** Verified 2026-10-03 (`gmtest_stam06`, scripted read-back; `gmtest_stam06_a/s/b`, a real Aard cast and scripted drains of the actions' types, measured in a fight): regen restarted 1 s after the cast's charge, 1 s after a dodge drain, 1.5 s after a light-attack drain with the option at +0.5.
2. **Damage pauses.** Verified 2026-10-03 (`gmtest_stam06_hit`, scripted hits on Geralt; `gmtest_stam06_npc_a/b`, real attacks on a wolf): pauses by severity, from none (3% of max health) to 1 s (20%); the wolf paused 0.5 s per hit.
3. **Whirl, Rend, finishers.** Verified 2026-10-03 (`gmtest_stam06_rend_a`, `gmtest_stam06_whirl_a`, scripted input, real attacks; `gmtest_stam06_fin_a/b`, a real finisher): regen restarted 1 s after the last Rend or Whirl drain; stayed paused during the finisher and rose after it.
4. **Option counted once** (audit fix, 5.x-GM `f8c8d108`). Verified 2026-10-03 (scripted input, real Whirl, option at +0.5): regen restarted 1.5 s after Whirl's last drain (2.0 s before the fix).

**Balance values:** action delay 1 s; sign delay 1 s (vanilla 0.5 s).

---

### STAM-07 Low-stamina heartbeat

| | |
|---|---|
| Kind | ui |
| Pillars | P2 |
| 5.x class | conflict |
| Flags | — |
| Depends on | OPT-01 |
| Skill trees | n/a |
| Port form | `@addField`/`@addMethod` on `CR4Player`, `@wrapMethod(CR4Player) OnDeath` (`stamina/lowStaminaSfx.ws`), called from STAM-08's `DrainStamina` and regen wrappers; the QoL options group and a restart hook on `CR4IngameMenu` (`options/gmOptions.ws`); the bank `modGhostMode/sound/heartbeat02a.bnk`, packed by `build_mod.py` |
| Port status | signed off (2026-10-04; [audit](#stam-audit-2026-10-03)) |
| Open checks | *waiting for the owner* (listening): (1) dynamic volume off, threshold 100%, stamina dropped to 5% in a fight: full loudness while it slows, fading out at 100%; (2) a real change in the menu: with the heartbeat playing, set the volume to 0 with dynamic volume off in Options > Mods > Ghost Mode > QoL and close the menu: silent at once. Loading a save while it plays |
| Save impact | none (expected) |
| NG+ counterpart | none |

**What it does:** below a stamina threshold a heartbeat plays; threshold, volume and rate are options (legacy's recommended values as defaults: threshold 50%, volume 100 dynamic, rate 0 dynamic), and volume and rate can rise as stamina falls. It stops on death.

**Implementation (legacy):** `CheckForLowStamina`/`StopLowStaminaSFX` on `CR4Player` and `W3PlayerWitcher`, called from `DrainStamina`, the regen effect and when options change; the getters `GetLowStaminaSFX*`; Ghost Mode's own Wwise bank `heartbeat02a.bnk` in the mod's `soundspc.cache` (5.x has no heartbeat sound). 11 units.

**5.x:** the code is new or trivially placed. The legacy bank (Wwise 2013, bank version 88) does not load in 5.x's Wwise 2023.1, so it is rebuilt ([how](../development.md#sound-banks)).

**Decisions:** port as legacy, for `W3PlayerWitcher` only.

- **Deviation:** legacy's presets for this options group and its `GMSignInstantCast` toggle are not ported, as with OPT-01's other groups (porter's call, not confirmed by the owner).
- **Deviation:** the playing flag is not saved (legacy saved it); a loaded game starts with it off and the next stamina change starts the sound. No save impact (porter's call, not confirmed by the owner).

**The legacy bank:** one sound, a 0.693 s stereo 48 kHz beat looped, on `Gameplay Master Bus`; events `play_heartbeat_02a_loop` (0.5 s fade in) and `stop_heartbeat_02a_loop` (1.5 s fade out); `heartbeat_volume` sets the volume (0 → −96 dB, sine curve, 100 → 0 dB); `heartbeat_rate` drives a Time Stretch effect (0 → 100%, 100 → 80%, so 25% faster) and its gain (0 → +6 dB); muted in 16 `game_state` states (exploration, dialogue, cutscenes, menus and the like), so in practice heard in combat. The rebuilt bank (2026-10-03, Wwise 2023.1.19, audio decoded with vgmstream and encoded with the game's conversion settings) keeps the bank and event IDs and the curves; sources in the local [audio folder](../development.md#sound-banks).

**Slices:**

1. **Sound bank.** Verified 2026-10-03 (scripted `SoundLoadBank` and events in real fights; the owner listened): loads from the mod's cache, plays in combat, rate and volume respond, silent out of combat, the stop event fades it out.
2. **Heartbeat logic.** Verified 2026-10-03 (`gmtest_stam07_set/s`, a ghoul fight; the owner listened): stamina drained to 5% by script started it loud and fast; real regen eased it and stopped it above 50%; a real Aard cast below the threshold started it; killing Geralt by script cleared it.
3. **Options.** Verified 2026-10-03 (`autoconfig`/`autoconfigset`, scripted): the group and its five options registered with labels and defaults; with the threshold at 80% it started at 74.9% in a fight; defaults restored.

---

### STAM-08 NPC stamina

| | |
|---|---|
| Kind | system, tuning |
| Pillars | P2 |
| 5.x class | clean |
| Flags | balance |
| Depends on | STAM-03, STAM-06 |
| Skill trees | n/a |
| Port form | scope overrides, `@wrapMethod` and `@replaceMethod` on behaviour-tree tasks, ticket algorithms and the damage processor (`scripts/local/gm/stamina/npcStamina.ws`); generated DLC XML (`gm_npc_stamina.xml`, `tools/gen_npc_stamina.py`) |
| Port status | signed off (2026-10-04; [audit](#stam-audit-2026-10-03)) |
| Open checks | counterattacks' cost and counters (no test enemy countered); a guard refused for lack of stamina; NPC sign casts' cost. The author's answer on [ungated attacks](../open-questions.md#ungated-npc-attacks) |
| Save impact | none (expected) |
| NG+ counterpart | applied and scaled, untested ([NG+ copies](#stam-audit-2026-10-03)) |

**What it does:** NPCs play by the same stamina rules: "The same logic is also applied to NPCs" (changelist, Stamina changes) and "Stamina is now properly checked and drained for all types of attack and defense actions" (Enemies). Every NPC attack pays stamina; raising the guard, parrying and countering also need stamina: the AI's rolls that decide whether it defends stay (`raise_guard_chance`, `counter_chance`), and stamina is required on top (legacy removed `CBTTaskPerformParry`'s `parry_chance` roll, which only runs where a behaviour tree sets `checkParryChance`; no game resource sets it, in 1.32 or 5.x, so the roll never runs); a parry drains a fixed cost (no heavy multiplier); counters pay the counter cost; NPC Quen is free. Below 10% stamina an NPC stops asking for attack tickets until it has 33.4% again. Regen pauses during each action and for 1 s after. A shielded NPC drops its shield when it lacks the stamina to parry, or on a heavy attack at 34% stamina or less (vanilla: a parried heavy at 10% or less). NPC stamina regen is raised (e.g. humans 0.07 → 0.25 of max per second); vanilla's cost discounts for some bosses and the Death March and level-bonus regen boosts are removed ("Stamina regen for AI no longer boosted for DM", Difficulty modes).

**Implementation (legacy):** behaviour-tree tasks (`CBTTaskAttack`, `CBTTaskAttackDef`, `CBTTaskPerformParry`, `CBTTaskDodge`, `BTTaskAdditiveHitListener`, `CBTTaskHitReactionDecorator`, `CBTTaskPlayAnimationEventDecorator`, `CBTTaskCastQuenDef`), the ticket algorithms (`btTicket.ws`, `CActor.CheckShouldWaitForStaminaRegen`), the shield rule in `W3DamageManagerProcessor.ProcessActionReaction`, and the stamina values of about 150 NPC abilities in the base ability XML (with NG+ copies). 26 script units and 300 XML units.

**5.x:** the tasks are unchanged apart from small additive changes that do not conflict (an NG+ multiplier on the `parry_chance` roll that never runs, a dodge flag, "player under attack" in `CBTTaskAttack.Main`). The NPC abilities' stamina values are unchanged in 5.x, except the wolf base, where legacy's values win.

**Decisions:**

- **Deviation:** false starts: some species' trees start an attack task and end it in the same frame, many times before a real attack (ghouls, bears). Legacy charged those two in `Main`; the port charges every attack at its start and refunds it, regen pause included, if its task ends in the frame it started. This covers every species whose tree does this; charging in `Main` would have made 16 attack task classes that replace `Main` free (project owner, 2026-10-03).
- **Deviation:** `CBTTaskPerformParry.IsAvailable` requires the parry stamina at all times; legacy only within the activation window, the same in effect (accepted at the STAM audit; project owner, 2026-10-04).
- *Kept as legacy (project owner, 2026-10-03):* the low-stamina wait only stops NPCs asking for new attack tickets (an NPC holding a ticket keeps attacking; NPCs on the engine's own ticket handling, e.g. wolves, ignore it); the shield rule's 34% check runs after the parry is paid; specials and basic attacks share one stamina pool (legacy balanced its costs around it).
- Legacy's other changes in the same tasks (dodge timing and distance, no dodge after being countered, Quen's stagger) belong to AI or DEF. Not ported: `ConHumanoidMonster`, an ability legacy added for another feature.

**Slices:**

1. **Attacks and action pauses.** Every NPC attack costs stamina (the light-attack cost unless its tree names one; counterattacks the counter cost) and is unavailable without it; false starts refunded; NPC sign casts have no task cost (NPC Quen free); regen paused while an NPC acts in combat (at most 10 s), then vanilla's 1 s delay (legacy's per-type NPC delays are all 1 s). Verified 2026-10-03 (`gmtest_stam08_a/s/set`, real NPC attacks, against a baseline build): a wolf paid each attack, held regen during and after it, and would not attack without the cost; ghoul, bear and wolf attack-task lifecycles showed false starts refunded and each real attack paid once.
2. **Defence needs stamina.** Guard, parry window and parry need the parry cost, counters the counter cost (after the AI's rolls); a parry costs the fixed parry cost with a 1 s delay; a counter is paid by the counterattack's task only. Verified 2026-10-03 (`gmtest_stam08_tough`, scripted light attacks, the bandit's real AI decisions): with stamina it guarded and parried at a flat cost; at 0 it never opened the parry window, parried or guarded.
3. **Low stamina.** The attack-ticket wait (below 10% until 33.4%) and the shield-drop rule. Verified 2026-10-03 (`gmtest_stam08_set/s/shield`, scripted stamina, real fights): a drained ghoul stopped asking for attacks until 33.4% (finishing ones it held a ticket for); a wolf was flagged but kept attacking, as in legacy; the shield broke under the rule's conditions and held otherwise.
4. **Enemy stamina values.** `extend` entries for 145 abilities, generated from legacy's ability XML (only the stamina nodes legacy changed, with legacy's values; removed nodes written as 0, neutral since ability values add up). Verified 2026-10-03 (`gmtest_stam08_xml`, scripted read-back, then a real fight): definitions carry legacy's values, a spawned wolf's effective costs match, and its attacks paid the new cost.

Detailed measurements, the behaviour-tree analysis of the false starts, and the full mapping against 5.x are kept in the maintainer's working notes, outside the repository.

**Balance values:** NPC regen and costs per ability; delays 1 s.

---

### STAM-09 Whirl and Rend stamina costs

| | |
|---|---|
| Kind | system, tuning |
| Pillars | P2 |
| 5.x class | rethink |
| Flags | balance |
| Depends on | STAM-02, STAM-03 |
| Skill trees | both: Whirl (classic `sword_s1`, new `sword_s35`; `GMWhirlSkill()` reads the equipped one, the classic first as vanilla's sustain code does); Rend `sword_s2` is shared |
| Port form | `@replaceMethod(W3PlayerWitcher)` of the Whirl sustain timer `SpecialAttackLightSustainCost` (Ghost Mode's body) and of `IsSpecialLightAttackInputHeld`/`IsSpecialHeavyAttackInputHeld` (5.x bodies, changes marked); new Whirl cost methods; `@wrapMethod` on `W3PlayerAbilityManager.GainStat` (adrenaline pause) and `W3PlayerWitcherStateCombatSword.OnPerformSpecialAttack` (Rend's minimum cost); all in `stamina/whirlRendStamina.ws`. DLC XML `extend` of `sword_s1` and `sword_s35` (`gm_skills.xml`); panel lines in `ui/characterStatsPopup.ws` |
| Port status | signed off (2026-10-04; [audit](#stam-audit-2026-10-03)), except the ArchGriffin decoction's cost increase (ALCH) |
| Open checks | the low-stamina warning and sound when a start is refused; the skill description text (new tree) |
| Save impact | none (expected) |
| NG+ counterpart | applied and scaled, untested ([NG+ copies](#stam-audit-2026-10-03)) |

**What it does:** Whirl drains stamina and adrenaline together each second and stops when stamina cannot pay the next moment (vanilla: stamina first, then adrenaline once stamina is empty); 50 stamina/s, 15% less per level above 1, adrenaline at the same cost ÷ max stamina (0.5/s at level 1); adrenaline gain is paused while it spins and for 1 s after. Starting Whirl or Rend needs half a second's stamina (25 at base cost), with the low-stamina warning and sound; while the button is held the check repeats, so the attack starts once regen reaches the cost. Rend pays no lump sum at its start, only its charge per second, but at least half a second's worth: a Rend released earlier pays the rest when it ends. The character panel lists Whirl's and Rend's cost per second while the skill is equipped.

**Implementation (legacy):** `W3PlayerWitcher.SpecialAttackLightSustainCost`, `HasResourcesForWhirl`, `GetWhirlStaminaCost`, `WhirlDrainResources`, `GetRendStaminaCost`, `IsSpecialLightAttackInputHeld`, `IsSpecialHeavyAttackInputHeld`, `SpecialAttackHeavySustainCost` (with STAM-06); `W3PlayerWitcherStateCombatSword.PerformSpecialAttackHeavy` (Rend's minimum cost) and `OnPerformSpecialAttack` (Rend's start cost removed); `sword_s1` in `geralt_skills.xml` (`stamina_cost_reduction_after_1` 0.15 per level).

**5.x:** the new tree has its own Whirl, `sword_s35`; `sword_s1` is the classic tree's (both 3 levels, 75 stamina/s). Rend `sword_s2` is shared. 1.32's drain model is unchanged in 5.x (stamina per second, then 1 adrenaline per second once stamina is empty); only the numbers changed: 75/s (1.32: 50), cost reduction 33% at level 2 and 50% at level 3, also on the adrenaline cost. Rend's start lump sum is already 0 in 5.x; Rend needs a full second's stamina to start (without cost modifiers) and has no minimum cost. Rend's damage bonus 0.5 → 1.5.

**Decisions:** port Ghost Mode's drain model and numbers onto both Whirls (project owner, 2026-10-03; the classic `sword_s1` after the [two skill trees](../feature-mapping.md#two-skill-trees) decision). `W3PlayerWitcher.GetWhirlFocusCostPerSec` is not ported: on 5.x only the replaced Whirl functions called it.

- **Deviation:** with both Whirls equipped, `GMWhirlSkill()` uses the classic one, where 5.x's `CR4Player` prefers `sword_s35` (accepted at the STAM audit; project owner, 2026-10-04).

**Slices:**

1. **Whirl drain and starts (new tree).** Verified 2026-10-03 (`gmtest_stam09_a/s`, `gmtest_stam02_press/release`, scripted input, real attacks in a fight): Whirl drained 50/s and 0.5 adrenaline/s and stopped at 0 stamina with adrenaline left; 35/s at level 3; Whirl and Rend refused below half a second's stamina, Rend started above it; adrenaline gain blocked while spinning.
2. **Character panel.** Verified 2026-10-03 (`gmtest_panel`, scripted): the lines are hidden without the skills and show 35/s (Whirl level 3) and 50/s (Rend).
3. **Classic Whirl** (5.x-GM `2d2b3039`). Verified 2026-10-03 (classic tree setting on, `sword_s1` equipped, scripted input, real Whirl in a ghoul fight): 50/s at level 1, 35/s at level 3, adrenaline in proportion, stopped at 0; panel line 35/s.
4. **Rend minimum cost** (audit fix, 5.x-GM `f8c8d108`). Verified 2026-10-03 (scripted input, real Rend in a ghoul fight): held about 0.15 s, it charged 18.3 and its end added 6.7 (25 in all); held about 0.25 s, nothing added.

**Balance values:** Whirl cost per second and reduction per level; Whirl and Rend start check.

---

### Two skill trees: follow-ups

The STAM features were first ported for the new skill tree only. After the decision to support [both trees](../feature-mapping.md#two-skill-trees) (2026-10-03), the counterparts were added and verified the same day: the classic Whirl `sword_s1` (STAM-02, STAM-06, STAM-09; 5.x-GM `2d2b3039`) and the new tree's alternate Igni and Axii, Firestream `magic_s28` and Puppet `magic_s31` (STAM-01, STAM-03, STAM-06; `c5a7317c`). Each entry's **Skill trees** row and slices record them.

**Follow-up (SKL, decided 2026-10-06):** the classic Whirl takes legacy's 5 levels (15% less per level above 1, 20/s at level 5), and the new tree's `sword_s35` matches it at its max level (30% less per level above 1, 20/s at level 3). Ported 2026-10-14 ([SKL-03](skl.md#skl-03-fast-attack-branch)): the classic Whirl has 5 levels, the new tree's cut is 30% per level above 1; STAM-09's temporary deviation has ended.

### STAM audit (2026-10-03)

Done by a fresh session ([audit](../feature-mapping.md#audit-signing-a-feature-off)) on 5.x-GM `c5a7317c`, regression run passing. Findings and what became of them (decided by the project owner):

- **Fixed in code** (5.x-GM `f8c8d108`, verified in game; regression run 167 passed, 0 failed): Rend's minimum cost (STAM-09, slice 4); the regen delay option counted twice for Whirl (STAM-06, slice 4); the 2 s sprint lockout, `HasStaminaToParry` without the heavy multiplier, the cost cap for every actor (STAM-03, slice 7); the test probes in `tests/` (logging every drain and NPC action into lists never cleared) now run only while a test turns them on (`GMTestProbes()`), and `build_mod.py --release` leaves `tests/` out; STAM-04's situation-free checks joined `gmtest_regress()`. Comments (`10911be3`): per-override feature tags, the Whirl comment in `gm_skills.xml`.
- **Closed open checks:** STAM-02 on the new tree's Whirl; STAM-01's alternate cooldowns after Firestream and Puppet.
- **Docs:** the entries follow the [template](../feature-mapping.md#feature-entry-template) (Skill trees, Open checks, slices); the [hand-off](#hand-off-to-other-areas) lists the other areas' changes inside STAM's units (SKL, ALCH, MUT rows) and `attribution.csv` notes them; stale texts corrected.
- **Accepted:** `CBTTaskPerformParry.IsAvailable` requires parry stamina at all times (legacy only within the activation window; the same in effect; STAM-08); `GMWhirlSkill()`'s order (STAM-09); the `gmStaminaRefusals` counter (STAM-03).
- **NG+** (finding X2): Ghost Mode's DLC mounted only `abilities/`, so none of its definitions reached New Game+. Now the DLC also mounts `abilities_plus/` with NG+ copies of every file, generated by `tools/gen_ngplus.py` with the [NG+ rule](../feature-mapping.md#ng-numbers) (5.x-GM `4f0820d3`). 593 of the 594 scaled values equal legacy's own NG+ values; the exception, the wolf's stamina regen (`mon_wolf_base`, 0.25 in legacy's NG and NG+; the rule would give 0.15 from vanilla's 0.05 and 0.03), keeps legacy's value (project owner, 2026-10-04; now a rule of the generator). Checked in game: the regular game still reads `abilities/` (regression run 167 passed, 0 failed, on 5.x-GM `a006a66a`); NG+ itself is untested, as for every feature.

**Signed off** by the project owner on 2026-10-04. The open checks stay listed in the entries; STAM-07's two listening checks still wait for the owner.

### Hand-off to other areas

Ghost Mode changes that affect stamina but belong to other features. They stay unattributed until their areas are mapped; this list is where those areas start.

| Area | Changes (legacy units) |
|---|---|
| ARM | Griffin set: free alternate cast at less than full stamina removed (`W3SignOwnerPlayer.ChangeAspect`); armor class cost modifiers (`W3PlayerAbilityManager.CalcStaminaArmorPenalty`, `CalcSignCastingArmorPenalty`; light −30%, heavy +50%, no armor −50%); Bear set tier 2 stamina refund (`W3PlayerWitcher.OnProcessActionPost`); Kaer Morhen set regen, Griffin set sign cost (`GetSetBonusTooltipDescription`, `effects_ep2.xml`, `geralt_skills_ep2.xml` `setBonusAbilityBear_2`); Vampire set regen (`CActor.OnTakeDamage`) |
| WGT | Overencumbrance cost penalty (`CalcStaminaOverEncumbrancePenalty`) |
| SKL | `W3PlayerWitcher.QuenImpulse` (uses stamina); the alternate Aard's Perk 9 (adrenaline first, Flood of Anger) and its entity moved 1 m down, in the Aard cast states; the Rend charge threshold 0.95 → 0.99 (`SpecialAttackHeavySustainCost`); Whirl's damage changes for both Whirls (`sword_s1`, `sword_s35`); Quen's shields rewritten (`W3QuenEntity.OnTargetHit`, `W3QuenEntityStateQuenChanneled.OnTargetHit`, `W3QuenEntityStateShieldActive.OnTargetHit`; the active shield still drains stamina, or adrenaline, in proportion to the damage absorbed: SKL-11); Perk 6 Griffin sign cost (`GetPerk6StaminaCostReduction`, `perk_6`), Perk 10 melee cost (`GetPerk10Bonus`, `perk_10`), Perk 21 stamina on kill and crit (`Perk21GainStamina`, `CNewNPC.OnDeath`, `ProcessAction`; conflicts with 5.x's Perk 21), Refreshment (`DrinkPreparedPotion`, `alchemy_s1`), passive skill regen removed (`magic_staminaregen`, `ResetCharacterDev`, `W3PlayerWitcher.OnSpawned`), Fleet Footed free dodge removed (`CR4PlayerStateCombat.PerformEvade`), Perk 11 adrenaline from signs (`W3SignEntity.ManageFocusGain`), Rend damage from stamina (`GetRendPowerBonus`, `ProcessDamageIncrease`, `sword_s2`), Whirl damage per hit and damage reduction while spinning (`sword_s1` `whirl_dmg_bonus`, `whirl_dmg_reduction`, `whirl_dmg_reduction_bonus_after_1`; to be ported onto `sword_s35`), Perk 9 adrenaline casting and Flood of Anger (`Channeling.Update` and `OnThrowing`, `YrdenChanneled.OnEnterState`, `ManagePlayerStamina`, `InitFoA`), Quen impulse only when an active shield ends with stamina or adrenaline left (`QuenChanneled.OnLeaveState`), perk and skill descriptions (`CR4CharacterMenu.Get*TooltipDescription`, `perk_1`) |
| ALCH | Mutagen 21's proportional heal in `W3PlayerAbilityManager.DrainStamina` and its hack removed in `OnPerformSpecialAttack`; ArchGriffin decoction (`CalcMutagen04Penalty`, `CActor.OnTakeDamage`), Troll decoction (`W3Mutagen12_Effect.ManageAdditionalBonus`, `OnStaminaChanged`, `ForceSetStat`, `GainStat`), Nekker Warrior and other mutagens (`effects_mutagens.xml`), potion and decoction tooltips (`GetPotionAttributesForTooltip`, `GetPotionAttributesByName`, `FillInMutagenDescriptionFromBuffType`) |
| ENCH | Glyphwords Heft, Balance, Levity (`GetGlyphword234Mod`), Depletion (`W3AardProjectile.ProcessCollision`, `CNewNPC.OnAardHit`), Glyphword 17 free Quen (`OnCombatStart`), Runeword 10 restores health instead of stamina (`Runeword10Triggerred`), Runeword 8 regen (`def_item_ep1_runewords.xml`), tooltips (`GetParamsForRunewordTooltip`) |
| MUT | Mutation descriptions (`GetMutationLocalizedDescription`); Mutagens 10, 17 and 22 hooks on every sign cast (the sign cast states STAM-01 wraps) |
| HORSE | Horse Axii cost (`W3VehicleCombatManagerStateCastSign.HasResourcesForAxii`, `DrainResourcesForAxii`, `StartCastingSign`, `OnEnterState`), no stamina drain on enemies hit from horseback (`DealDamageToHostiles`), horse sprint cost 5 → 7.5 (`def_item_horse.xml` `HorseLevel1`) |
| EFX | Low stamina raises knockdown severity (`ModifyKnockdownSeverity`) |
| ITEM, CRAFT | Stamina regen removed from random magical items (`InitPantsAbilities`, `InitBootsAbilities`, `def_item_quality.xml` `MA_StaminaRegeneration`) |
| FOOD | Drinks' stamina regen (`effects.xml` `WellHydratedEffect_Level*`) |
| TRPH | Trophy stamina regen (`wyvern_mq1051_trophy_stats`, `white_basilisk_trophy_stats`) |
| FIX | Regen not starting when an ability with a regen stat is added (`W3AbilityManager.OnAbilityChanged`); the fiend's tree (`monster_bies_logic.w2behtree`, legacy's only behaviour-tree edit) gains a close-range melee branch (three attacks within 4 m, melee ticket), the changelist's "Fixed a bug with chorts and fiends not attacking the player"; its attacks use the default cost like any other |
| DEF | Partial parry damage reduction 50% and the rest of legacy's parry and counter rework (`ProcessAction`, `PerformParryCheck`, `PerformCounterCheck`; already attributed to STAM-03 for its stamina part) |
| — | `W3IgniProjectile.ProcessCollision` touches no stamina (the sweep matched it by name) |
