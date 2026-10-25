# DMG: the damage and armor formula

Ghost Mode moves armor in front of attack power (pillar P1): a hit must get through the victim's armor before any attack power bonus counts, so damage does not snowball and armor, armor piercing and strong attacks matter. The changelist's "Damage formula" section (lines 186–212 of [legacy-FullChangelist.txt](../legacy-FullChangelist.txt)):

> Vanilla: damage = (weapon_damage * attack_power - armor) * (1 - damage_resistance)
> Modded: damage = (weapon_damage - armor) * attack_power * (1 - damage_resistance)

and the rules every description follows: weapon damage raises the base value and helps penetrate armor; attack power scales what got through armor; armor penetration lowers the victim's armor; resistance reduction lowers the victim's resistance; "damage received" or "final damage" modifies the value after armor, attack power and resistances.

**How legacy Ghost Mode implements it.** Almost all of it is in the damage manager (`damageManagerProcessor.ws`), as a new order of damage steps:

1. `ProcessDamageIncrease`: **raw damage**. Flat additions (Steady Shot, Mutation 1, glyphwords, Mutation 10, ...), then one **additive bonus pool** ("remove damage stacking, make all multipliers additive instead"): Strong Attack's +50%, Rend, sword damage bonuses, Heft, Perk 20, Deflection, the frozen-target bonus are summed and multiply every damage type once. Written back to the action (`W3DamageAction.SetDTs`, new).
2. `ProcessDamageDecrease` (new): Quen absorbs the raw damage, before armor (SKL-11).
3. Crit check, before-hit checks, `GetAttackersPowerMod`: **attack power** (base value, multiplier, additive), with crits, headshots and backstabs (+25% each), Whirl, the Lynx and Bear sets.
4. `CalculateDamage`: (raw damage from step 1 + attack power base − armor points) × attack power multiplier + attack power additive, then × (1 − resistance %); armor points and resistances from `GetDamageResists`. The attack power base is added after the pool: the pool scales the weapon damage only.
5. `ReduceDamage` (parry, the victim's own reductions).
6. `ProcessDamageModification` (new): **final damage** multipliers (unaimed bolts and bombs ×0.5, Crippling Strikes, Mutation 8, Supercharged Glyphs, Severance, sign damage against Vitality, the difficulty multiplier, NPC friendly fire, Dimeritium), then damage below 1 becomes 0.
7. Direct damage, instant kill, dealing the damage, returned damage.

Around it: enemies' stats are rebuilt so armor and resistances depend on the enemy type alone (level bonuses give health and damage only), weapon damage is read from the item, sign intensity reaches non-damage effects through a diminishing curve, and effect durations no longer scale with power.

**What 5.x did in this area.** The formula is unchanged (still attack power before armor), but around it, from the code (not tested in game):

- **Strong attacks are stronger**: −0.433 attack power instead of 1.32's −0.833, still ×1.833 final damage. Aard's damage gets attack power through `AARD_SPELL_POWER_MULT` (1.32 forced it to 1), and Aard's direct damage now goes through the formula.
- **About 20 new raw-damage multipliers**, each `*=` and compounding with the others and with attack power: `ProcessNewSkills_Combat` (Muscle Memory s22 ×1.3, Strength Training s23 ×(1+0.15/level), Three Strikes s24, Crushing Blow s25 ×1.5) and in `ProcessDamageIncrease` Catalyst, Toxic Shock, Elemental Attunement, Element of Surprise, the Wolven and Netflix sets, Crippling Strike, the bomb passives and perks, `alchemy_s24`/`s25`/`s26`, Resonance, Anatomical Knowledge, the `sword_s32` headshot ×2.5 (full list in [DMG-04](#dmg-04-additive-raw-damage-pool)).
- **A negative resistance now shrinks armor** (`GetDamageResists`: armor × (1 + resistance) when the resistance is below 0), which the new Sunder Armor (`sword_s28`) uses.
- **Allies are rebuilt**: friendly NPCs' damage is raised to a floor (level × 40) and clamped against Geralt's own damage, allied hits on bosses are capped at 0.5% of their health, Puppet ×1.2–1.6 by level, damage-boost abilities (`FCR3*DamageBoost`) added to weak allies, Axii'd allies take ×0.1 from NPCs.
- `ProcessActionDamage` fetches the damage types once at the start, runs the immortality clamp after `ReduceDamage` (moved out of the actors' `ReduceDamage`), and adds Mutagen 28's specter block, auto-oil, `SetRecentlyDodged` and simulate-only gates.
- Everything else Ghost Mode changed outside the damage manager is unchanged in 5.x (`CalculateDuration`, the resistance names, `GetTotalWeaponDamage`, the durability curve), except `CActor.ReduceDamage` and `AddLevelBonuses`.

Unit lists: [attribution.csv](attribution.csv): DMG-01 to DMG-15 (DMG-09 and DMG-13 handed off) (mapped 2026-10-06 from the changelist, the damage manager function by function, and sweeps of the script and XML units touching attack power, armor, resistances, damage, power and durations). The XML sweep found 2,994 units with damage stats (1,404 regular, 1,590 NG+); 22 are DMG's (NPC basic attacks and stat registration, 11 and their NG+ copies), 76 are the enemy stat model, handed to AI and DIFF ([DMG-13](#dmg-13-enemy-stat-model)), the rest belong to the areas in the [hand-off list](#hand-off-to-other-areas). Port status: **signed off** 2026-10-07 after the [audit](#dmg-audit-2026-10-07); slices 1 to 6b ported and verified in game: DMG-01, DMG-06 to DMG-08, DMG-10 to DMG-12 and DMG-15 ported; DMG-02 to DMG-05 ported except the other areas' terms they host (each listed as a deviation); DMG-14 in progress (the probe; legacy's debug messages not ported); DMG-09 and DMG-13 handed off. The 5.x analysis is from reading the code.

## Area decisions

Made by the project owner on 2026-10-06 (DD1 to DD5):

- **DD1: multiplicative raw-damage bonuses become additive.** "That was a good call from legacy": every percentage bonus to raw damage, 5.x's included, joins the additive pool ([DMG-04](#dmg-04-additive-raw-damage-pool)). Any exception must be carefully considered and deliberate; the four confirmed on 2026-10-07 are listed in DMG-04. This settles SKL's D4.
- **DD2: resistances never go below 0, as legacy.** 5.x's rule that a negative resistance shrinks armor does not apply; the new tree's Sunder Armor (`sword_s28`) becomes legacy's flat −25% with SKL (D56) ([DMG-02](#dmg-02-armor-and-resistance-rules)).
- **DD3: allied NPC damage as legacy** ([DMG-12](#dmg-12-allied-npc-damage)); the new tree's Puppet `magic_s31` gets legacy's puppet rule with SKL (D24).
- **DD4: each change stays in its own area unless DMG needs it to be tested.** The enemy stat model (level bonuses, NPC templates, difficulty multipliers) is not needed to test the formula: the damage probe checks every step against any enemy. It goes to AI and DIFF ([DMG-13](#dmg-13-enemy-stat-model)). The human armor fix is needed (armor before attack power cannot be tested against human enemies without armor) and is ported here ([DMG-15](#dmg-15-human-npc-armor)).
- **DD5: the scope.** DMG owns the formula, where every bonus sits, and the generic rules the formula needs to work (weapon damage source, damage-over-time and returned-damage rules). The skills, sets, potions and mutations that feed it keep their own areas: DMG ports the steps with hooks for them, and each area fills in its own terms. Exception: Strong Attack's core rule (`sword_2`, +50% weapon damage, +200 armor piercing), which replaces vanilla's heavy-attack multipliers.

**Proposed port order** (slices, each verified in game):

1. **Damage probe** (DMG-14): a `gmtest_*` function that runs a hit through the damage manager and reports each step (raw, pool, armor, attack power, resistance, final), so every later slice is measured against legacy's formula.
2. **The formula** (DMG-01, DMG-02, DMG-03): `CalculateDamage`, `GetDamageResists`, `GetAttackersPowerMod`, Strong Attack's core rule.
3. **The pipeline** (DMG-04, DMG-05): `ProcessActionDamage` and `ProcessDamageIncrease` replaced on 5.x's bodies, the bonus pool, the final-damage step; 5.x's multipliers as decided in DD1.
4. **Weapon damage and human armor** (DMG-08, DMG-15).
5. **Signs and durations** (DMG-06, DMG-07).
6. **Special fights and rules** (DMG-09, DMG-10, DMG-11, DMG-12).

---

### DMG-01 Armor before attack power

| | |
|---|---|
| Kind | system |
| Pillars | P1 |
| 5.x class | conflict |
| Flags | balance |
| Depends on | DMG-02, DMG-03, DMG-04 (Strong Attack's +50%) |
| Skill trees | n/a (`sword_2` is a core skill, shared by both trees) |
| Port form | `@replaceMethod(W3DamageManagerProcessor) CalculateDamage` (5.x body with legacy's order; `damage/formula.ws`); `@replaceMethod(CActor) ReduceDamage` (5.x body without the player's minimum damage, `damage/pipeline.ws`); new global for damage below 1 |
| Port status | signed off (2026-10-07; slices 2, 3a, 3b) |
| Open checks | the removal of the fist bonus by level and of the per-monster Igni weakness (no Igni or fist hit tested); real attacks (all checks are scripted hits through the damage manager) |
| Save impact | none (expected) |
| NG+ counterpart | applied (`gm_damage.xml`'s NG+ copy; the `basic_attacks.xml` overrides reach the NG+ and ep1 definitions too: ep1's `attack_heavy_noparry` reads 0 attack power in game) |

**What it does:** damage = (weapon damage × (1 + the additive pool) + attack power base − armor) × attack power multiplier + attack power additive, then × (1 − resistance), resistance clamped to 0–100%. "Raw damage" is the weapon damage after the raw-damage steps (flat additions, then the pool, [DMG-04](#dmg-04-additive-raw-damage-pool)); the attack power base (flat, from the attacker's abilities, e.g. NPC level bonuses) is added after the pool, so the pool does not scale it. Until slice 3, 5.x's own raw-damage steps (separate multipliers) stand where the pool will be. Armor applies to every damage type, fire, frost and elemental included (vanilla let those through armor), except where DMG-02 ignores it. A hit that armor stops deals nothing: the player's vanilla minimum (5% of the raw damage, at least 1) is gone, damage below 1 becomes 0 and plays no hit reaction, and the hit is flagged as stopped by armor. Vanilla's heavy-attack handling (−0.833 attack power, ×1.833 final damage) is removed, replaced by Strong Attack's +50% weapon damage and +200 armor piercing (DMG-04, DMG-02); NPC heavy attacks get +25% raw damage instead of their attack power bonuses (`basic_attacks.xml`: heavy, super heavy, knockdown, stagger and bleeding attacks lose their +0.15 to +0.5).

**Implementation (legacy):** `CalculateDamage` rewritten; `GetAttackersPowerMod`'s heavy penalty removed; `ProcessDamageModification` (damage below 1, `hasArmor` → `SetArmorReducedDamageToZero`); `CActor.ReduceDamage` (minimum damage commented out); `ModifyHitSeverityReactionFromDamage` (new, `types.ws`: its DMG half zeroes damage below 1 and suppresses the hit animation; the other half is AI's poise); `basic_attacks.xml`.

**5.x:** the formula as 1.32; the heavy penalty −0.433 (1.32: −0.833), ×1.833 kept; minimum damage kept; `SetArmorReducedDamageToZero` takes a bool. Removed by legacy and still in 5.x: the fistfight damage scaling by Geralt's level outside the minigame, the burning-sign log cap on attack power, the per-monster Igni weakness (`igni_damage_amplifier`, 22 Blood and Wine and 3 Hearts of Stone abilities; legacy kept the XML and dropped the script).

**Decisions:** port as legacy; the per-monster Igni weakness is dropped as in legacy (weaknesses are resistances, AI).

- **Deviation:** 5.x's ×1.1 to the damage the player takes in New Game+ (end of `CalculateDamage`, new in 5.x) is kept: NG+ scaled like vanilla's ([New Game+ policy](../feature-mapping.md#new-game-carried-over-and-scaled-not-balanced-or-tested)) (project owner, 2026-10-07; audit F5).
- Mutagen 2's 1.32 resistance bonus is removed since [ALCH-13](alch.md#alch-13-defensive-and-conditional-decoctions-arachas-doppler-fiend-elemental-werewolf-leshen-griffin-relievers) (2026-10-20; until then a temporary deviation).


**Later:** —

**Slices:**

1. **The formula** (slice 2, 5.x-GM `6456ff4d`): `damage/formula.ws` replaces `CalculateDamage`, `GetDamageResists` and `GetAttackersPowerMod` on 5.x's bodies. Verified 2026-10-07 (`gmtest_dmg02`, `gmtest_dmg02_turn`/`_back`: scripted hits of Geralt's of one damage type on a human test dummy with set armor and resistances; `gmtest_dmg`: real weapons on dummies, a bandit and a wraith, and a live wolf; regression 181 passed): armor 40 subtracted from raw damage before attack power; a hit below the armor deals only the additive attack power; elemental damage reduced by armor; a resistance of −50% counts as 0 and leaves armor whole; a 30% resistance applied last; damage over time without armor and attack power; the player's shock damage without armor; a headshot without armor and resistance, +25% attack power; a backstab +25% attack power; the probe's recorded hits all follow the port's formula.
2. **Heavy attacks** (slice 3a, 5.x-GM `dc81f49b`, with [DMG-04](#dmg-04-additive-raw-damage-pool)): 5.x's −0.433 attack power and ×1.833 removed; `sword_2` as legacy (`gm_damage.xml`: +50% weapon damage, 200 armor piercing, no +0.333 attack power); heavy and special attacks lose their attack power bonus (`attack_heavy` and five more). Verified 2026-10-07 (`gmtest_dmg03a`, scripted attacks built as real ones, Geralt's sword, a human test dummy with 250 armor): a heavy attack has a light attack's attack power, Geralt's and the dummy's; it follows the formula without ×1.833; Strong Attack pierces 200 armor.
3. **No minimum damage, nothing below 1** (slice 3b, 5.x-GM `7aecd469`, with [DMG-05](#dmg-05-order-of-damage-steps-and-final-damage)): `CActor.ReduceDamage` replaced on 5.x's body without the player's minimum damage; hits below 1 deal nothing (the final-damage step). Verified 2026-10-07 (`gmtest_dmg03b`, scripted hits of the test dummy on Geralt): a hit of 10 that Geralt's armor stops deals 0 (5.x: at least 1); a hit of 0.43 after the formula deals 0. 
4. **Hits below 1 in `ReduceDamage`** (audit F2, 5.x-GM `6b90faf5`): `GMZeroSubOneDamage` (legacy `ModifyHitSeverityReactionFromDamage`, its damage half; the hit severity half is AI's), called in `CActor.ReduceDamage` after the bolts' minimum of 1: a hit below 1 deals nothing and plays no hit animation, before final damage (so the difficulty multiplier cannot lift it). Verified 2026-10-07 (`gmtest_dmg03b`, scripted hits of the test dummy on Geralt, the animation left to the game): a hit of 10 that his armor stops deals 0 with no hit animation; a hit of 300 deals 217 with its animation.

### DMG-02 Armor and resistance rules

| | |
|---|---|
| Kind | system |
| Pillars | P1, P5 |
| 5.x class | overlap |
| Flags | balance |
| Depends on | DMG-01; hooks for SKL (Sunder Armor, Strong Attack), ALCH (oils, Mutagen 2, Dimeritium), SWD (Aerondight, Iris), AI (Ice Armor), XBOW (headshots) |
| Skill trees | both: classic `sword_s6` Sunder Armor, new `sword_s28` (5.x's armor debuff goes; legacy's flat −25% with SKL: DD2, D56); `sword_2` shared |
| Port form | `@replaceMethod(W3DamageManagerProcessor) GetDamageResists` (`damage/formula.ws`); XML `all_NPC_ability`, `all_PC_ability`; the point names (`ResistStatNameToEnum`, `ResistStatEnumToName`) ported with EFX-08 (`effects/resistNames.ws`, wrappers) |
| Port status | signed off (2026-10-07), except the other areas' terms it hosts (deviations; ported with those areas) |
| Open checks | the fistfight minigame ignoring armor and resistances; the other areas' terms kept from 5.x (oils, Sunder Armor) with this function |
| Save impact | none (expected) |
| NG+ counterpart | applied (the two abilities' NG+ copies) |

**What it does:** armor points = the victim's resistance points + its armor, minus the attacker's armor piercing (and a Dimeritium bomb's), never below 0; resistance % minus resistance reduction, never below 0. Ignored completely (armor and resistance): fistfight minigames, headshots, a fully charged Aerondight, Iris's phantom strike. Armor ignored, resistances kept: damage over time, the player's shock damage (Yrden's turret, "shock damage now ignores armor"), point-resist-ignoring actions, and enemies vulnerable from the front (moved here from `ReduceDamage`). Point values of bleeding, will and burning resistance are read (vanilla only mapped the `_perc` names, so point values were silently ignored); NPCs and the player register will and burning resistances and the damage-over-time resistances.

**Implementation (legacy):** `GetDamageResists` rewritten (the early returns, the order, the clamps, the `hasArmor` flag, Ice Armor's +30% resistance moved here, Mutagen 2's resistance debuff, Dimeritium's armor and resistance reduction, oils' resistance reduction through `GetOilResistReductionBonus`); `ResistStatNameToEnum`/`EnumToName`; `all_NPC_ability`, `all_PC_ability` (`common_abilities.xml`).

**5.x:** a negative resistance shrinks armor (armor × (1 + resistance) when the resistance is below 0); the new Sunder Armor `sword_s28` adds `GetSunderArmorPercent()` to the resistance reduction; `alchemy_s22` adds resistance against poisoned attackers. 5.x's XML has 20 `bleeding_resistance` point entries (1.32: 12) that its scripts ignore; legacy's name mapping would switch them on.

**Decisions:** port as legacy; 5.x's armor-shrinking rule does not apply (DD2, project owner, 2026-10-06): with resistances clamped at 0 it can never trigger. Before porting the resistance names, list the abilities carrying `bleeding_resistance` points in 5.x; switching them on is a deviation if they differ from legacy's: checked with EFX-08 (2026-10-24): every `bleeding_resistance` and `burning_resistance` point value in 5.x's XML is 0 (20 and 2 entries), as legacy's (its `will_resistance` 0 or registrations with a multiplier of 1), so no deviation.

- **Deviation:** the other areas' terms in this function stay 5.x's until those areas are ported: Ice Armor's +30% resistance (AI, 5.x halves the damage in `ReduceDamage`) (temporary, until those areas). Mutagen 28's 1.32 resistances are gone and Mutagen 2's debuff is legacy's since ALCH-13, Dimeritium's armor and resistance reduction since ALCH-15, the oils' values since ALCH-16 (their resistance reduction 0 in every version; 2026-10-20). A fully charged Aerondight's and Iris's phantom strike's full ignore are legacy's (SWD-05, SWD-06, 2026-10-19).


**Slices:** slice 2, with [DMG-01](#dmg-01-armor-before-attack-power).
VulnerableFromFront (slice 3b, 5.x-GM `7aecd469`): checked in `ProcessDamageIncrease`, before the formula, and taken out of `CActor.ReduceDamage` (5.x checked it there, after armor had been applied, and skipped the rest of `ReduceDamage`). Verified 2026-10-07 (`gmtest_dmg03b`): a hit from the front on a dummy with the ability and 40 armor ignores the armor.
Point names (EFX-08, 2026-10-24, 5.x-GM `d804603d`): `bleeding_resistance`, `will_resistance` and `burning_resistance` read as point resistances; ends this feature's temporary deviation; verified in both trees ([EFX-08](efx.md#efx-08-effect-resistance-points)).
Stat registration (audit F4, 5.x-GM `6b90faf5`): `all_NPC_ability` registers will and burning resistance points and the three damage-over-time resistances, `all_PC_ability` will and burning resistance points (`gm_damage.xml` and its NG+ copy). Verified 2026-10-07 (`GMTest_dmgxml`, in `gmtest_regress()`; scripted reads).

### DMG-03 Attack power and crits

| | |
|---|---|
| Kind | system |
| Pillars | P1 |
| 5.x class | conflict |
| Flags | balance |
| Depends on | DMG-01; GEN (headshot and backstab rule); hooks for SKL (Whirl, crit skills), ARM (Lynx, Bear, Red Wolf), SWD (Aerondight), MUT (Mutations 2, 9) |
| Skill trees | both (crit skills `sword_s8`, `sword_s17`, `sword_s7` read by the function; ported with SKL) |
| Port form | `@replaceMethod(W3DamageManagerProcessor) GetAttackersPowerMod` (`damage/formula.ws`), `ProcessCriticalHitCheck` (later) (shared with SKL, MUT, DEF-07: one body, feature-tagged hunks); the constants as `GMHeadShotDamageBonus()` and `GMBackAttackDamageBonus()` |
| Port status | signed off (2026-10-07), except the other areas' terms it hosts (deviations; ported with those areas) |
| Open checks | Igni's and Aard's projectiles at full sign intensity; no additive attack power for bolts; no crits for damage over time and in non-deadly fights (the wrapper skips the check; a crit was not attempted in those cases) |
| Save impact | none (expected) |
| NG+ counterpart | none |

**What it does:** attack power is the action's power stat plus: headshots +25%, backstabs +25% ("Headshots and backstabs add 25% to Attack Power", General player abilities), crit damage (reduced by the victim's crit reduction). No attack power at all (×1, nothing added) for damage over time and in fistfights and non-deadly fights; no crits on damage over time or in non-deadly fights. Bolts get no additive attack power. Negative parts are clamped to 0. Signs keep their full power: vanilla's Igni projectile reduction (`IGNI_SPELL_POWER_MILT`) and Aard's reset to 1 are removed. Vanilla's bug of adding `critical_hit_chance_fast_style` to crit *damage* is removed.

**Implementation (legacy):** `GetAttackersPowerMod`, `ProcessCriticalHitCheck` (generic parts: early returns, debug), `W3GameParams.<members>` (`HEAD_SHOT_DAMAGE_BONUS`, `BACK_ATTACK_DAMAGE_BONUS` = 0.25).

**5.x:** heavy penalty −0.433; Aard through `AARD_SPELL_POWER_MULT`; `sword_s32` bolt headshot multiplier on the additive; the ally damage-boost abilities (DD3); `alchemy_s27` crit damage; Rend's crit chance removed from the crit check (SKL-04 restores it); `sword_s31` crit after a recent counter or dodge.

**Decisions:** port as legacy; the headshot and backstab rule is GEN's in the changelist, ported here because it is one line of this function.

- Mutagen 5's (Water Hag's) 1.32 attack power at full Vitality is removed, as legacy, since [ALCH-10](alch.md#alch-10-decoctions-that-build-up-on-melee-hits-katakan-water-hag-wyvern-alghoul-forktail) (2026-10-20; until then a temporary deviation). Aerondight's crit is legacy's since SWD-05 (2026-10-19): a certain crit through 5.x's `crit_chance_bonus` term, +100% crit power in `GetAttackersPowerMod`. Ported: the Bear, Feline and Manticore sets' terms (ARM-08, ARM-06, ARM-10), Mutation 2's crit formula and Mutation 9's bolt terms (MUT-03, MUT-11), 2026-10-17. SKL's terms here are ported: Whirl, the Yrden turret's cached intensity, the crit skills melee only, Anatomical Knowledge's crit damage on bolts.


**Slices:** slice 2, with [DMG-01](#dmg-01-armor-before-attack-power). The 5.x level-ups' additive attack power (+31 at level 10) applies after armor and so ignores it, until GEN removes it from level-ups.
No crits for damage over time or in non-deadly fights (slice 6a, 5.x-GM `5a615f82`): a wrapper skips the crit check (`nondeadly.ws`).

### DMG-04 Additive raw-damage pool

| | |
|---|---|
| Kind | system |
| Pillars | P1 |
| 5.x class | overlap |
| Flags | balance |
| Depends on | DMG-01; SKL (most of the pool's terms), SWD, ENCH, MUT, EFX (frozen) |
| Skill trees | both: the pool takes legacy's terms (classic) and 5.x's new-tree multipliers (`sword_s22` to `s26`, `s29`, `s32`, `magic_s35`, `s41`, `perk_27`, `28`, `37`, `44`, `alchemy_s23` to `s26`); SKL dropped or replaced most of these ([follow-ups from SKL](#follow-ups-from-skl)) |
| Port form | `damage/pool.ws`: `@replaceMethod(W3DamageManagerProcessor) ProcessDamageIncrease` on 5.x's signature (its multipliers as pool terms, the pool handed on in fields), `ProcessNewSkills_Combat` and the four new-tree combat skill functions (their bonuses as pool terms; the pool applied once at the end, `GMPoolApply`); the action's damage types written back (`SetDTs`, so that Quen and other later readers see the pool) with SKL-11, which needs it; XML `gm_damage.xml` (`sword_2`) |
| Port status | signed off (2026-10-07), except the other areas' terms it hosts (deviations; ported with those areas) |
| Open checks | the pool terms of other areas: the bomb items' terms, SWD-07's NG+ `sword_dmg_bonus` and `spell_dmg_bonus` (NG+, untested by policy) (Aerondight's is gone with SWD-05; Runeword 4's with ENCH-05; Mutation 8's is gone with MUT-06; the Lynx and Wolven sets' with ARM-06 and ARM-09); the NPC ranged bonus above level 31 being gone. SKL's pool terms are checked in SKL's entries (Rend, Strength Training, Deflection, Steady Shot, Heavy Artillery, Wolf School); the 5.x new-tree terms are gone ([follow-ups from SKL](#follow-ups-from-skl)) |
| Save impact | none (expected) |
| NG+ counterpart | none |

**What it does:** percentage bonuses to weapon damage are added together, then multiply the raw damage of every type once, before armor and attack power ("If something increases your weapon damage, it increases your base damage value and helps with penetrating enemy's Armor"). Flat additions are made first, so the pool scales them. Terms: Strong Attack (player heavy attacks, `heavy_attack_dmg_boost` 0.5: the core rule ported here), NPC heavy attacks +25%, `sword_dmg_bonus`/`spell_dmg_bonus` (Ghost Mode's item attributes), Rend, Heft, Perk 20 on bombs, Deflection on reflected arrows, the frozen-target bonus. Two stay separate multipliers: the underwater crossbow and Mutation 9. Removed from 1.32's function: the difficulty multiplier (moved to final damage, DMG-05), the NPC ranged bonus above level 31, the frozen target's separate frost hit (now a pool term, ALCH-14) and its knockdown (EFX-02, which also adds Aard's force damage on a frozen target after the pool), Rend's two multipliers (now `GetRendPowerBonus`), Mutation 8 (final damage), Lynx and Aerondight (attack power), Runeword 4 (an effect).

**Implementation (legacy):** `ProcessDamageIncrease` (no parameter; reads and writes the action's damage types); `W3DamageAction.SetDTs`. `GetVitalityDamageTotal` and `GetEssenceDamageTotal` (new in `W3DamageAction`) have no caller: not ported.

**5.x:** keeps every 1.32 block and adds the raw multipliers listed in the intro (each `*=`): `ProcessNewSkills_Combat` (s22 ×1.3, s23 ×(1+0.15/level), s24 ×1.4–1.7 on a chance, s25 ×1.5, s28 armor debuff), Netflix set 2 (direct damage), Catalyst `magic_s35` ×(1+0.3/level), Toxic Shock `alchemy_s23` (adds poison damage, 25/50/75% of the total), Elemental Attunement `perk_37` ×(1+0.03/level), Wolven set 1 (+1% per bleed stack × pieces), Element of Surprise `perk_44` ×(1+0.1/level), bombs ×(1+`potion_duration`), `perk_27` ×1.02, `alchemy_s25`, Crippling Strike ×(1+its multiplier), `perk_28` ×1.02 poison, `alchemy_s24` (player ×1.5 at 80% toxicity), `alchemy_s26` ×(1+0.05/level, 0.1 against poison-immune), Resonance `magic_s41`, Anatomical Knowledge `sword_s26` (flat), `sword_s32` headshot ×2.5. 5.x works on a local array and does not write the action, so later readers see pre-bonus values.

**Decisions:** the pool as legacy, and every 5.x raw-damage multiplier joins it as an additive term (DD1, project owner, 2026-10-06; settles SKL's D4). Each term's value stays its area's (SKL, ARM, ALCH); SKL's per-skill pass (complete 2026-10-11) re-judged the new tree's terms: most of 5.x's were dropped or replaced by SKL ([follow-ups from SKL](#follow-ups-from-skl)).

Exceptions, confirmed by the project owner on 2026-10-07 (DD1: "carefully considered and deliberate"):

1. **Crippling Strike** (new tree `sword_s29`): a final-damage multiplier, not a pool term (SKL's D2, project owner, 2026-10-06; since 2026-10-09 the skill is legacy's Crippling Strikes, whose bonus is for fast attacks against bleeding enemies).
2. **`alchemy_s24`** (the player takes ×1.5 at 80% toxicity): it changes damage *received*, which the changelist's rules put in final damage ("if something decreases or increases the damage received ... it modifies the final damage value"): final damage. Gone: SKL-13 replaced High Tolerance with Refreshment (D27).
3. **Flat additions stay flat** (they are not multipliers): Anatomical Knowledge `sword_s26` (silver sword damage added to bolts), Netflix set 2 (direct damage), Toxic Shock `alchemy_s23` (adds poison damage equal to 25/50/75% of the hit). Added before the pool like legacy's flat additions, so the pool scales them; Toxic Shock's share is taken of the damage before the pool, so the pool is not counted twice. Anatomical Knowledge's add (D14) and Toxic Shock (D60) are gone with SKL, Netflix set 2's with ARM-15 (DA3).
4. **Legacy's own exceptions**, kept multiplicative in legacy's code: the underwater crossbow bonus and Mutation 9's bolt damage. Kept as legacy.

- 5.x's own versions of the terms legacy reworked were pool terms until their areas ported legacy's; none is left (ended with SWD-05, 2026-10-19). Aerondight's is gone: legacy's damage per enemy and crit power since SWD-05 (2026-10-19). Runeword 4's overheal term is gone: legacy's Invigoration effect on the weapon damage since ENCH-05 (2026-10-19). The Wolven set's is gone (legacy's oil bonuses, ARM-09, 2026-10-17). Mutation 8's term is gone: legacy's final-damage factor since MUT-06 (2026-10-17). The Lynx set's are gone (legacy's attack power, ARM-06, 2026-10-17). SKL's are ported: Heavy Artillery (legacy's), Perk 27 and `alchemy_s25` gone, the potion-duration passive zeroed (SKL-01).
- **Deviation:** legacy's pool terms and flat additions of other areas are not ported yet: `fist_dmg_bonus` (AI) (temporary, until that area; the frozen target's bonus came with ALCH-14, audit F2, 2026-10-20; Mutagen 9 came with ALCH-11, 2026-10-20; Mutation 10 came with MUT-09, Heft and Rotation with ENCH-10 and ENCH-13, `sword_dmg_bonus`/`spell_dmg_bonus` with SWD-07, 2026-10-19).

**Slices:**

1. **The pool** (slice 3a, 5.x-GM `dc81f49b`). Every multiplier of 5.x's `ProcessDamageIncrease` (18) and of the four new-tree combat skills becomes a pool term; perk 37 adds to non-physical damage types only, perk 28 to poison; the confirmed exceptions are untouched; Strong Attack +50% for Geralt's heavy attacks, +25% for NPCs'; the NPC ranged bonus above level 31 removed. Verified 2026-10-07 (`gmtest_dmg03a`, scripted attacks built as real ones on a human test dummy, raw damage read before and after the pool): a light attack ×1; a heavy attack ×1.5; with the Element of Surprise perk (+10%) a heavy attack ×1.6, not 5.x's ×1.65; the dummy's heavy attack on Geralt ×1.25. The probe on a live wolf and slice 2's checks pass; regression 181 passed.

### DMG-05 Order of damage steps and final damage

| | |
|---|---|
| Kind | system |
| Pillars | P1 |
| 5.x class | conflict |
| Flags | balance |
| Depends on | DMG-01 to DMG-04; SKL-11 (Quen before armor); hooks for SKL, MUT, ENCH, ALCH, XBOW, DIFF |
| Skill trees | n/a (hooks only) |
| Port form | `damage/pipeline.ws`: `@replaceMethod(W3DamageManagerProcessor) ProcessActionDamage` on 5.x's body, one call added (DEF-01's wrapper stacks on it); `@addMethod` `GMProcessDamageModification`; `ProcessDamageDecrease` and the damage types re-read (Quen before armor) with SKL-11 |
| Port status | signed off (2026-10-07); Quen before armor added with SKL-11 slice 1 (2026-10-15: `GMProcessDamageDecrease` after the pool, the damage types written back with `GMSetDTs` and re-read); the other areas' terms it hosts are ported with those areas (deviations) |
| Open checks | the sign rule against Vitality and Crippling Strikes' bonus in final damage (no test yet: needs a sign hit, and a fast attack on a bleeding enemy; SKL's D2 of 2026-10-09 makes the new tree's bonus legacy's, fast attacks only) |
| Save impact | none (expected) |
| NG+ counterpart | none |

**What it does:** the order in the intro: raw damage and its pool, then Quen on the raw damage, then the damage types re-read, then crit, attack power and the formula, then `ReduceDamage`, then **final damage** (`ProcessDamageModification`), then direct damage. Final damage applies after everything else ("If something decreases or increases the damage received (or the final damage dealt), then it modifies the final damage value after all the Armor, Attack Power bonuses and resistances were applied"); skipped when there is no damage, for dodged hits and for effect damage over time. Its generic rules, owned here: the difficulty multiplier applies to hostile NPCs hitting the player only (DIFF owns the values), NPCs hitting friendly NPCs deal ×0.25 (DMG-12), damage below 1 becomes 0 (DMG-01), and the player's signs deal reduced damage to Vitality (humans, animals): ×(0.75 − 0.5 × max(0, 1 − 0.1 × (level − 1))), 25% at level 1 rising to 75% at level 11 and above. The other terms are hooks: Perk 16, unaimed bolts and bombs ×0.5, Severance, Supercharged Glyphs, Crippling Strikes, Mutation 8, Dimeritium. SKL adds one: the new Muscle Memory's +10% total damage ([follow-ups from SKL](#follow-ups-from-skl)).

**Implementation (legacy):** `ProcessActionDamage` (call order, damage types re-read after Quen, Viper set poison healing replacing Golden Oriole's), `ProcessDamageModification` (new), `ProcessDamageDecrease` (new).

**5.x:** see the intro: damage types fetched once at the start; the immortality clamp and `DamageInstigated` now in `ProcessActionDamage` after `ReduceDamage`; Mutagen 28 blocks specter abilities; `ProcessNewSkills_Combat`; Aard's direct damage through the formula; auto-oil; simulate-only gates. There is no wrap point between `ReduceDamage` and direct damage, hence the replacement.

**Decisions:** port as legacy on 5.x's body; the difficulty multiplier's position (final damage, hostile NPCs hitting the player only) is DMG's, its values DIFF's (DD4). Keeping 5.x's additions that are not in the way (auto-oil, simulate-only gates, `SetRecentlyDodged`). Mutagen 28's (Reliever's) 5.x specter block is removed since ALCH-13 (the owner's DL6, 2026-10-20).

- Golden Oriole's level-3 absorption of poison damage is removed from `ProcessActionDamage`, as legacy ([ALCH-05](alch.md#alch-05-golden-oriole), 2026-10-20; until then a temporary deviation); the Viper set heals from poison instead (ARM-11).
- The other areas' final-damage terms are ported: Dimeritium's mage damage cut (ALCH-15, 2026-10-20), Mutation 8's (MUT-06, 2026-10-17), Severance's (ENCH-04, 2026-10-19). SKL's are ported: unaimed bolts and bombs ×0.5, In Combat's Fires, Supercharged Glyphs, Crippling Strikes, Muscle Memory's total damage.
- **Deviation:** until DIFF ports legacy's difficulty values (`difficulty_Common*`: Normal none, Hard +100%, Hardcore +250%), 5.x's values (+40%, +130%, +230%) apply at legacy's position, final damage (temporary, until DIFF).
- The sign-damage reduction against Vitality is not in the changelist: an omission, recorded in [open-questions.md](../open-questions.md#legacy-data-vs-changelist).

**Slices:**

1. **The final-damage step** (slice 3b, 5.x-GM `7aecd469`): `ProcessActionDamage` calls `GMProcessDamageModification` right after `ReduceDamage`, before 5.x's immortality clamp and direct damage; it holds the signs-against-Vitality rule, Crippling Strike's bonus and `alchemy_s24` (from raw damage, DD1's exceptions), the difficulty multiplier (hostile NPCs hitting the player; from raw damage) and hits below 1. Verified 2026-10-07 (`gmtest_dmg03b`, scripted hits on and from a human test dummy; the probe on a live wolf; slices 2 and 3a's checks; regression 181 passed): with the dummy's difficulty multiplier at 2, its raw damage is unchanged and the damage dealt is twice the formula's; Geralt's hits deal the formula's damage; a live wolf's bite on Hard: armor first, then ×2.3.

### DMG-06 Sign intensity conversion

| | |
|---|---|
| Kind | system |
| Pillars | P3, P1 |
| 5.x class | clean |
| Flags | balance |
| Depends on | — (SKL-08 to SKL-12, MUT-02, MUT-03 and UI depend on it) |
| Skill trees | n/a |
| Port form | the global `GMSignPowerStatToPowerBonus` (`damage/signs.ws`) |
| Port status | signed off (2026-10-07; slice 5) |
| Open checks | — |
| Save impact | none (expected) |
| NG+ counterpart | none |

**What it does:** turns sign intensity into a diminishing bonus for sign effects other than damage: for intensity above 100%, each 50% step adds 0.40, 0.35, 0.30, 0.25, 0.20, 0.15, 0.10, 0.10, 0.10, 0.05, capped at +2.0 from 600% (+0.75 at 200%). Used for Aard's knockdown chance, Melt Armor, Axii's duration and instant kill, Quen's shield, Yrden's slow, Mutation 2's crits, and the skill and stats panels.

**Implementation (legacy):** `characterStats.ws::SignPowerStatToPowerBonus` (new). Its 24 callers belong to their areas.

**5.x:** absent; no conflict.

**Decisions:** port as legacy, as the first sign slice's foundation; the callers come with SKL and MUT.

**Slices:**

1. **The curve** (slice 5, 5.x-GM `43e612d1`). Verified 2026-10-07 (`GMTest_dmg06`, in `gmtest_regress()`; scripted values): +0 at 100%, +0.40 at 150%, +0.75 at 200%, +1.30 at 300%, +2.0 at 600% and 1000%. No caller yet: SKL and MUT port them.

### DMG-07 Effect durations not scaled by power

| | |
|---|---|
| Kind | system |
| Pillars | P3, P7 |
| 5.x class | clean |
| Flags | balance |
| Depends on | — (SKL sign skills, ALCH, EFX read it) |
| Skill trees | n/a |
| Port form | `damage/durations.ws`: `@replaceMethod(CBaseGameplayEffect) CalculateDuration`, `RecalcDuration`; `resistancePts` with SKL-08 (its only reader) |
| Port status | signed off (2026-10-07; slice 5) |
| Open checks | — |
| Save impact | none (expected) |
| NG+ counterpart | none |

**What it does:** an effect's duration is its base duration × (1 − the victim's resistance); the creator's attack power or sign intensity no longer lengthens it. Recalculating a duration starts from the initial value (vanilla shrank it at every recalculation, "Fixed a bug with effect duration math"). Effects keep the victim's point resistance (`resistancePts`) for the rules that subtract it (Aard's knockdown chance). The Petri Philtre's level-3 bonus to sign effect durations sits in the same function (ALCH).

**Implementation (legacy):** `CBaseGameplayEffect.CalculateDuration`, `RecalcDuration`, `<members>` (`resistStat` made protected, `resistancePts` new).

**5.x:** unchanged from 1.32 (durations still scale with power).

**Decisions:** port as legacy. `resistStat` cannot be made protected by annotation: Ghost Mode code reads it through an added getter.

- The Petri Philtre's level-3 bonus to sign effect durations (+34% for knockdown, confusion, Axii's puppet, burning) is in the same function since [ALCH-06](alch.md#alch-06-petris-philtre-level-3) (2026-10-20; until then a temporary deviation).

**Slices:**

1. **Durations** (slice 5, 5.x-GM `43e612d1`). Verified 2026-10-07 (`gmtest_dmg05`, a poison effect added by script to a human test dummy with Geralt as creator): 10 s at creator power ×3 stays 10 s (5.x: 30); at 50% poison resistance 5 s, still 5 s after two recalculations. Regression 182 passed.

### DMG-08 Weapon damage source

| | |
|---|---|
| Kind | fix |
| Pillars | P1 |
| 5.x class | clean |
| Flags | — |
| Depends on | — (AI's NPC special attacks, XBOW's NPC bows, MUT-02 read it) |
| Skill trees | n/a |
| Port form | `damage/weapon.ws`: `@replaceMethod(CActor) GetTotalWeaponDamage`; `@replaceMethod(W3PlayerWitcher) GetTotalWeaponDamage` (5.x's body, the DMG line changed; MUT-11, SWD and ENCH change the same body later) |
| Port status | signed off (2026-10-07; slice 4) |
| Open checks | the respawn growth itself (the fix holds either way) |
| Save impact | none (expected) |
| NG+ counterpart | none |

**What it does:** an actor's weapon damage is read from the held item alone (vanilla read the actor's attribute and subtracted the other held weapons; legacy's comment: the value grew on every NPC respawn). A sword's extra damage types (fire, frost, ...) are applied at full value: vanilla multiplied them by 0 plus the grindstone bonus, the changelist's "Fixed a bug with additional sword damages (like fire and frost) not being actually applied to a target".

**Implementation (legacy):** `CActor.GetTotalWeaponDamage`; `W3PlayerWitcher.GetTotalWeaponDamage` (`durMod` 1 instead of 0).

**5.x:** both unchanged from 1.32: the sword bug is still there.

**Decisions:** port as legacy (project owner, 2026-10-06: both are bugs). Reading the item is correct whether or not 5.x still has the respawn growth, so the fix needs no 5.x test first; the slice's check reads an NPC's weapon damage before and after a respawn.

- The other areas' terms in `W3PlayerWitcher.GetTotalWeaponDamage` are legacy's: Aerondight's damage per enemy (SWD-05) and the fully charged Iris's share of Geralt's Vitality (SWD-06), 2026-10-19; Mutation 9's flat bolt damage is gone (MUT-11, 2026-10-17); Invigoration's bonus (ENCH-05, 2026-10-19).

**Slices:**

1. **Weapon damage** (slice 4, 5.x-GM `a0817615`). Verified 2026-10-07 (`gmtest_dmg04`, scripted reads): a bandit's club deals its item's 150 bludgeoning damage; Geralt's relic sword Caerme deals its fire damage (2.26, 5.x: 0).

### DMG-09 Durability scaling

Handed off to ITEM ([hand-off](#hand-off-to-other-areas)); the ID is kept so the dependency is visible. `W3GameParams.GetDurabilityMultiplier` (a per-difficulty curve, clamped to 0.8/0.7/0.6/0.5) scales weapon damage *and* armor, so the formula's two terms wear differently from vanilla. Not in the changelist (the mod description: "durability penalties were redone").

### DMG-10 Non-deadly fights and fistfights

| | |
|---|---|
| Kind | system |
| Pillars | P8 |
| 5.x class | clean |
| Flags | — |
| Depends on | DMG-01, DMG-03, DMG-05 |
| Skill trees | n/a |
| Port form | `damage/nondeadly.ws`: `@addField` `gmWeaponsAreNotDeadly`, `@addMethod` `GMNonDeadlyWeaponFight`, `@wrapMethod` `InitializeActionVars` (sets the flag), `ProcessCriticalHitCheck` and `ProcessOnBeforeHitChecks` (skipped); hunks in `CalculateDamage`, `GetAttackersPowerMod` (formula.ws), `ProcessDamageIncrease` (pool.ws), `GMProcessDamageModification` (pipeline.ws) |
| Port status | signed off (2026-10-07; slice 6a) |
| Open checks | a real non-deadly fight (wooden swords, a fistfight outside the minigame); the fistfight minigame itself |
| Save impact | none (expected) |
| NG+ counterpart | none |

**What it does:** a melee fight where both sides hold wooden swords or fists (or the scripted opponents Olaf, the ff205 troll, the club dwarves, the mq7011 guards) is non-deadly: no bonuses, no crits, no attack power. Outside the fistfight minigame, a hit deals 20% of the victim's maximum health (×2 for heavy attacks), scaled for the player (×0.5 against Olaf and the troll), the prologue (×0.25) and NPCs (by difficulty and level difference); the difficulty multiplier does not apply. In the fistfight minigame, resistances and armor are ignored and the player's attack power is 1.

**Implementation (legacy):** `NonDeadlyWeaponFight` (new), `<members>`, `InitializeActionVars`, and the hunks listed under Port form.

**5.x:** none of it; 5.x keeps 1.32's fist rules (resistances ignored for fists against non-essence victims, damage outside the minigame scaled by Geralt's level).

**Decisions:** port as legacy.

**Slices:**

1. **Non-deadly fights** (slice 6a, 5.x-GM `5a615f82`). Verified 2026-10-07 (`gmtest_dmg06a`, scripted hits; Geralt bare-handed, the human test dummy with Olaf's ability and its club mounted in hand): Geralt's hit deals 20% of the dummy's maximum health ×0.5 (10000 of 100000); the dummy's hit on Geralt 20% of his maximum health ×0.25 (Hard, same level), with its difficulty multiplier set to 3 ignored.

### DMG-11 Returned damage

| | |
|---|---|
| Kind | system |
| Pillars | P1 |
| 5.x class | clean (Leshen: conflict) |
| Flags | — |
| Depends on | ALCH (Mutagen 26, Black Blood), ARM (silver studs), AI (Thorns), ENCH (Glyphword 5) |
| Skill trees | n/a |
| Port form | `damage/returned.ws`: `@wrapMethod` `ProcessActionReturnedDamage` (the dodge guard); `@replaceMethod` `ProcessActionLeshenMutagenDamage`, `ProcessSilverStudsReturnedDamage`, `ProcessActionBlackBloodReturnedDamage`, `ProcessActionThornDamage` |
| Port status | signed off (2026-10-07; slice 6a) |
| Open checks | Black Blood and silver studs (no test: a necrophage or vampire attacker with the potion, armor with silver studs); the dodge guard |
| Save impact | none (expected) |
| NG+ counterpart | none |

**What it does:** damage returned to an attacker is based on the damage actually dealt, gets no attack power ("returned damage shouldn't use attack power"; Thorns keep it), and nothing is returned for a dodged hit. Black Blood's returned damage is silver and physical (armor and resistances apply). Thorns return 10% of the attacker's weapon damage (30 if it has none).

**Implementation (legacy):** the five functions above.

**5.x:** unchanged from 1.32, except the Leshen mutagen (one direct damage type from the vitality damage dealt).

**Decisions:** port as legacy (the five functions here; their potions, items and abilities with their areas).

- Glyphword 5's (Retribution) reflection, which legacy disabled, is removed with [ENCH-12](ench.md#ench-12-retribution-glyphword-5) (2026-10-19).

**Slices:**

1. **Returned damage** (slice 6a, 5.x-GM `5a615f82`). Verified 2026-10-07 (`gmtest_dmg06a`, scripted hits of the test dummy on Geralt): with the Thorns ability on Geralt the dummy takes 10% of its weapon's damage with Geralt's attack power (46); with Mutagen 26 it takes 10 + 10% of the damage dealt (33.1 for 231.3), without attack power.

### DMG-12 Allied NPC damage

| | |
|---|---|
| Kind | system |
| Pillars | P5, P8 |
| 5.x class | overlap |
| Flags | balance |
| Depends on | DMG-01, DMG-05; SKL-12 (Puppet), ALCH (Succubus decoction) |
| Skill trees | both: classic `magic_s5` Puppet, new `magic_s31` |
| Port form | `GMAllyDamage` and hunks in `CalculateDamage`, `GetAttackersPowerMod` (formula.ws: 5.x's ally floor, clamps, Puppet multipliers and damage boosts off), `CActor.ReduceDamage` and `GMProcessDamageModification` (pipeline.ws) |
| Port status | signed off (2026-10-07; slice 6b) |
| Open checks | real allies in a quest fight; the mq1041 soldiers; the new tree's Puppet `magic_s31` as the puppet's level |
| Save impact | none (expected) |
| NG+ counterpart | none |

**What it does:** "Changed how damage is calculated for allied NPCs: both dealt and received" (changelist, AI). Dealt: an ally's hit on a hostile deals a random 2–4% of the victim's maximum health (at least 10–20); an Axii puppet 6–12% × Puppet level / 3, raised by the Succubus decoction; mq1041's soldiers 10–15%. Resistances still apply. Received: hostile hits on allies deal 1–2% of their maximum health (10–15% while Axii'd); NPCs hitting friendly NPCs ×0.25.

**Implementation (legacy):** `CalculateDamage` (the "friendly npc damage" block), `CActor.ReduceDamage`, `ProcessDamageModification`.

**5.x:** its own system (intro): allies raised to a level floor and clamped against Geralt's damage, boss hits capped at 0.5% of health, Puppet ×1.2–1.6 and `magic_s31`, damage-boost abilities for weak allies, Axii'd allies take ×0.1 from NPCs.

**Decisions:** port as legacy (DD3, project owner, 2026-10-06); 5.x's ally code in `CalculateDamage`, `GetAttackersPowerMod` (the damage-boost abilities) and `CActor.ReduceDamage` (×0.1 for Axii'd allies) is left out.

- **Deviation:** a puppet's level is the player's Puppet level, either tree (`S_Magic_s05` or `S_Magic_s31`); legacy read the puppet's `alt_axii_level`, which its XML gave Puppet's skill ability (one per level) and 5.x's lacks. The same result except when Geralt's Puppet level changes while a puppet lives (project owner, 2026-10-07, audit F8: no functional difference, and one change fewer to 5.x).
- The Succubus decoction's bonus to a puppet's damage (its limits ×1.5) is in `GMAllyDamage` since [ALCH-11](alch.md#alch-11-sign-decoctions-foglet-succubus-wraith-ancient-leshen) (2026-10-20; until then a temporary deviation).

**Slices:**

1. **Allied NPC damage** (slice 6b, 5.x-GM `b056fb60`). Verified 2026-10-07 (`gmtest_dmg06b` with `gmtest_dmg06b_spawn`: two hostile and one friendly test dummy with 100000 health, scripted hits; Puppet level 3): an ally's hit on a hostile 2043 (2% to 4%); a hostile's hit on the ally 1730 (1% to 2%); a hostile's hit on another hostile ×0.25; as an Axii puppet the ally deals 8819 (6% to 12%) and takes 14119 (10% to 15%; 5.x: ×0.1). The full DMG set passes (49 checks) and the regression 182.
2. **Hits without damage** (audit F1, 5.x-GM `5fba98de`): `CActor.ReduceDamage` no longer returns early for an action without damage (legacy), so the ally rule also covers a hostile hit the ally's armor stops and hostile actions that apply effects without damage. Verified 2026-10-07 (`gmtest_dmg06b`, scripted): a hit the friendly dummy's 5000 armor stops costs it 1540 (1% to 2%; 5.x: 0); the other DMG-12 checks and the regression (182) pass.

### DMG-13 Enemy stat model

Handed off to AI and DIFF (DD4, project owner, 2026-10-06): the formula can be tested without it. The ID is kept so the dependency is visible: legacy's formula was balanced against these stats, so fights are only judged once AI and DIFF port them. What it is: "Levelup bonuses for NPCs redone ... both armor and resistances are defined by enemy type alone" (changelist, AI). Per level, NPCs and monsters get a little Vitality or Essence (8–20 flat plus 15%) and attack power (+1 flat, +1% or +0.5%, from a base of 11) and nothing else; red-skull bonuses removed; the NPC templates retuned (`ConDefault` loses its 50% fire resistance, "Removed 87.5% of fire resistance from humans"; `MiniBoss` and `Boss` get flat Vitality, attack power and resistances); the difficulty multipliers (Easy −50% health and −25% damage, Normal none, Hard +100%/+100%, Hardcore +150%/+250%). Units: the XML abilities `NPCLevelBonus*`, `MonsterLevelBonus*`, `AnimalLevelBonus`, `BossNGPLevelBonus`, `MonsterMHBoss`, `PrologModifier`, `NPCLevelModFistFight*`, `Con*`, `MiniBoss`, `Boss` (AI), `difficulty_Common*` and the scaling options' `ModSigns*` abilities (DIFF), and `CNewNPC.AddLevelBonuses` (5.x rewrote it), `InternalAddLevelBonuses`, `RemoveAllLevelBonuses`, `ModSignsAddBonuses`, `CheckConstitutionAbility`.

### DMG-14 Damage debug tools

| | |
|---|---|
| Kind | infra |
| Pillars | — |
| 5.x class | clean |
| Flags | — |
| Depends on | — |
| Skill trees | n/a |
| Port form | the probe: test-only wrappers in `tests/gmTestsDmg.ws` (`ProcessDamageIncrease`, `ProcessNewSkills_Combat`, `GetDamageResists`, `CalculateDamage`, `ProcessActionDamage_DealDamage`, active only with `GMTestProbes()`); legacy's tools: `@wrapMethod` `ProcessActionDamage_DealDamage`; `@addMethod` `GetAttackerAbilities`; console functions in a Ghost Mode file; the debug hunks of the replaced functions; a `gmtest_*` probe |
| Port status | in progress (the probe is done; legacy's debug messages and console toggles not ported) |
| Open checks | — |
| Save impact | none |
| NG+ counterpart | none |

**What it does:** facts that print each step of a hit to the combat log: `modSigns_debug_dmg` (crit chance, power mod, the formula's inputs and output, final damage, a full dump before dealing damage), `modSigns_debug_abl` (the attacker's abilities), `modSigns_debug_reduce_damage`, and `modSigns_zero_ally_dmg` (allies deal 0); console toggles `toggledebugdmg`, `toggledebugabl`, `toggledebugreducedamage`, `toggleallynodmg`.

**Decisions:** port with the formula slices; they are also the base of the damage probe (slice 1). `toggledebugdot` and the other toggles go with their areas.

**Slices:**

1. **Damage probe** (5.x-GM `f2e20039`). Test-only wrappers record each step of a hit: the raw damage before and after the increase steps, armor points and resistance, attack power, each damage type's result, the damage dealt to the victim's stat; `gmtest_dmg()` makes a light and a heavy hit of Geralt's on the nearest hostile NPC and a light hit of the NPC's on Geralt, checks that each result follows the formula in force from the recorded inputs and that the damage dealt is their sum, and logs what legacy's formula would give from the same inputs. Verified 2026-10-07 (scripted hits through the damage manager, Geralt's real sword, the NPC's held weapon; level 10, Hard): 12 checks passed against a wolf and a bandit. Legacy's debug facts and console toggles come with the functions they belong to (slices 2 and 3).

What the probe showed of 5.x (level 10, steel sword, Hard): Geralt's attack power carries +31 additive from 5.x's level-ups, added after armor, so it ignores armor whichever formula is used (legacy gives level-ups no attack power: GEN); heavy attacks deal about 1.8 times legacy's formula from the same inputs (5.x's ×1.833); hostile NPCs' raw damage is ×2.3 before armor (the difficulty multiplier, in raw damage in 5.x); the spawned bandit has 0 armor (DMG-15).

---

### DMG-15 Human NPC armor

| | |
|---|---|
| Kind | fix |
| Pillars | P1, P5 |
| 5.x class | clean |
| Flags | — |
| Depends on | — (AI's armor values for humans) |
| Skill trees | n/a |
| Port form | `damage/weapon.ws`: `GMLazyArmorFix`, `GMHasArmorAbility`, `GMGetArmorAbilityFromPath`, called from `@wrapMethod(CNewNPC) OnSpawned` (legacy: from `AddLevelBonuses`, which AI replaces later) |
| Port status | signed off (2026-10-07; slice 4) |
| Open checks | — |
| Save impact | none (expected: added at spawn) |
| NG+ counterpart | none |

**What it does:** a human NPC without an armor ability gets the one its entity template includes (`npc_armor_lvl1` to `lvl6_wild_hunt` → `NPC Leather Armor` to `NPC_Wild_Hunt_Armor`). Changelist, Bugfixes: "Fixed a bug with humans not actually using armor abilities - all of them had zero armor."

**Implementation (legacy):** `gm_bugfixes.ws`: `LazyArmorFix`, `HasArmorAbility`, `GetArmorAbilityFromPath`; called from `CNewNPC.AddLevelBonuses`.

**5.x:** the bug is still there: without the fix, a renegade whose template includes leather armor has 0 armor (verified 2026-10-07, the build before slice 4); with it, 20.

**Decisions:** port as legacy (project owner, 2026-10-06: a bug), in DMG because armor before attack power cannot be tested against human enemies without it (DD4). The armor values themselves (30 to 120, legacy) are AI's; until AI ports them, humans have 5.x's (8 to 50).

**Slices:**

1. **Human armor** (slice 4, 5.x-GM `a0817615`). Verified 2026-10-07 (`gmtest_dmg04` with `gmtest_dmg04_spawn`: three archer templates, a bandit and Vesemir nearby): every human whose template includes an armor ability has it (a renegade 20 armor, Vesemir 30); the other templates include none. Without the fix the renegade has 0.

### DMG audit (2026-10-07)

Done by a fresh session ([audit](../feature-mapping.md#audit-signing-a-feature-off)) on its own branch off 5.x-GM `b056fb60`, in a separate worktree; regression run passing (182); every DMG check passing (the slices' 49, plus `gmtest_dmg03a` on the classic tree). The modSigns check, the deviation list and the attribution held; the unit sweep found no unit DMG misses. Findings F1 to F14, decided by the project owner on 2026-10-07:

- **Fixed in code** (verified in game, regression 184, every DMG check passing): F1 legacy's ally rule also covers hits without damage: `CActor.ReduceDamage` no longer returns early for them (5.x-GM `5fba98de`; an armor-stopped hit costs an ally 1–2%, and so do hostile actions that apply effects without damage; the blocks the return skipped otherwise change little: a recoil off a troll's back, a parry log line, the scripted "player is the boss" hits); F2 a hit below 1 deals nothing and plays no hit animation, in `ReduceDamage` before final damage; F4 the resistance stats registered; F11 a stale comment; F12 the probe stops when its victim dies (5.x-GM `6b90faf5`).
- **Recorded:** F5 5.x's ×1.1 to the damage the player takes in New Game+ kept (DMG-01); F6 Golden Oriole's poison absorption kept until ALCH and ARM (DMG-05); F7 the other areas' terms missing from the deviation bullets (DMG-03, DMG-08); F8 the puppet's level read from Geralt's Puppet level, confirmed (no functional difference, one change fewer to 5.x).
- **Corrected in the docs:** F3 the immortality-clamp deviation removed (legacy also clamped after final damage, in `CActor.OnTakeDamage`); F9 the damage types are written back with SKL-11; F10 DMG-01's NG+ cell.
- **Accepted:** F13 the untested parts stay open checks; F14 legacy's ally rule also overrides each damage-over-time tick an ally takes: kept as legacy, on the [list to test in legacy](../open-questions.md#to-test-in-legacy-ghost-mode).

**Signed off** by the project owner on 2026-10-07 (DMG-01 to DMG-08, DMG-10 to DMG-12, DMG-15; DMG-02 to DMG-05 without the other areas' terms they host, listed as deviations; DMG-14's debug messages left). The open checks stay listed in the entries; the legacy question is on the list [to test in legacy](../open-questions.md#to-test-in-legacy-ghost-mode).

### Follow-ups from SKL

SKL's per-skill pass (complete 2026-10-11; [skl.md](skl.md#area-decisions)) changed what DMG's functions host. SKL has ported all of it (SKL-03 to SKL-18, verified in game in both trees by 2026-10-16); the entries above describe the code with it.

Terms SKL adds or changes:

- **Muscle Memory, new tree `sword_s22`** (D1): +60% attack power on each boosted fast attack (the attack-power step) and +10% total damage, a new final-damage term (DMG-05), in place of 5.x's ×1.3 pool term.
- **Strength Training, new tree `sword_s23`** (D54): per stack an attack-power term and a weapon-damage pool term (up to +61.25% and +17.5% at 3 stacks), in place of 5.x's pool term.
- **Precise Blows `sword_s24`** (D57) and **Crushing Blows `sword_s25`** (D55), new tree: crit chance and crit damage terms for fast and strong attacks, base and chain (the crit check and crit damage, DMG-03), in place of 5.x's Three Strikes and Crushing Blow multipliers.
- **Wolf School `perk_26`** (D61): +30% bomb weapon damage against poisoned enemies, a pool term, and +20% crit chance and +60% crit damage for melee hits with the right oil within 10 s of bomb damage (totals at four medium armor pieces).
- **Cold Blood, new tree `sword_s34`** (D13): +16.67 bolt damage per level, a flat addition before the pool, as legacy's Steady Shot (`xbow_dmg_bonus`, the classic tree's `sword_s15`).
- **In Combat's Fires** (`perk_16`, new tree `perk_44`; D38): in the final-damage step it halves only the damage Geralt takes from his own bombs and bolts; legacy's code also halved the damage they deal to enemies.
- **Classic Muscle Memory and Strength Training** (D47): attack power counted once at +0.1 per level in `W3Action_Attack.GetPowerStatValue`, counters included (DEF-07's counter share changes with it).
- **Sunder Armor** (D56): legacy's flat −25% for melee strong attacks in both trees (DMG-02), in place of 5.x's stacks (`GetSunderArmorPercent`).

5.x new-tree terms that go, because SKL drops or replaces their skills: Three Strikes `sword_s24` and 5.x's Crushing Blow `sword_s25` multipliers; 5.x's Anatomical Knowledge `sword_s26` silver-sword add (DMG-04's exception 3; removed by SKL-06, 2026-10-15); Lightning Reflexes `sword_s32`'s headshot bonus (removed by SKL-06); Catalyst `magic_s35` and Resonance `magic_s41` (removed by D58, 2026-10-15); Elemental Attunement `perk_37` (removed by SKL-18's Focus, 2026-10-15); Element of Surprise `perk_44` (removed by SKL-18, 2026-10-15); the Manticore `perk_27` and Viper `perk_28` bonuses (removed by SKL-18, 2026-10-15); Toxic Shock `alchemy_s23` (exception 3; removed by SKL-15, 2026-10-15); Volatile Compound `alchemy_s25` (removed by SKL-14, 2026-10-15); Potent Sting `alchemy_s26` (removed by SKL-16, 2026-10-15); High Tolerance `alchemy_s24` (exception 2; removed by SKL-13, 2026-10-15); Debilitating Poison `alchemy_s22`'s resistance against poisoned attackers (DMG-02; removed by SKL-17, 2026-10-15). Crippling Strikes `sword_s29` keeps its final-damage exception with legacy's rule (fast attacks against bleeding enemies) instead of 5.x's crit trigger. Of 5.x's DD1 terms this left the Wolven set and Netflix set 2, both removed by ARM (ARM-09, ARM-15); the potion-duration passive on bombs goes with SKL-01. `gmtest_dmg03a` uses the new tree's Strength Training as its sample pool term (Element of Surprise is gone).

### Decisions waiting for the owner

None.

### Hand-off to other areas

| Area | Changes (legacy units) |
|---|---|
| SKL | The pool's skill terms (Rend `GetRendPowerBonus`, Deflection, Perk 20, Steady Shot), the final-damage terms (Perk 16, Crippling Strikes, Supercharged Glyphs), Whirl and the crit skills in `GetAttackersPowerMod`, Sunder Armor in `GetDamageResists`, skill attack power in `W3Action_Attack.GetPowerStatValue` (5.x adds `sword_s31` and `perk_27`'s attack power styles), Rend's crit chance (5.x removed it from `ProcessCriticalHitCheck`), the instant-kill skills (`ProcessInstantKill`: 5.x's `sword_s30`, `s32`, `s33`), Quen before armor (`ProcessDamageDecrease`, SKL-11), the callers of `SignPowerStatToPowerBonus`; the new-tree terms SKL adds and the 5.x terms it removes: [follow-ups from SKL](#follow-ups-from-skl) |
| AI | The enemy stat model's level bonuses and NPC templates ([DMG-13](#dmg-13-enemy-stat-model)), NPC armor abilities (`NPC Leather` to `Full Plate Armor` 8/20/30/40/50 → 30/45/60/90/120 with resistances; "Added different resistances to human armor"), `WeakenedState` (−15% resistances), individual monster armor and resistances (`monster_base_abl.xml` and expansions, about 830 units), NPC and monster weapons, Ice Armor (+30% resistances, removed by any fire: `CNewNPC.OnFireHit`), `EredinInvulnerable`, the hit-severity half of `ModifyHitSeverityReactionFromDamage` (poise, golems), monster-hunt monsters immune to instant kill, `LastBreath` (`GetLastBreathMaxAllowedDamage`), NPC special-attack damage now from weapon damage with attack power after armor (tornado, ground trap, ice spike, leshy roots and birds, boiling water, critters, `advancedProjectile.ws`), the Caretaker's heal, magic fists dealing ranged damage (`W3Action_Attack.Init`) |
| DIFF | The difficulty multipliers (`difficulty_Common*`) and the scaling options' abilities (`ModSigns*`, [DMG-13](#dmg-13-enemy-stat-model)), per-enemy difficulty variants and Ciri's stats (97 units), the scaling options and level randomisation (`W3GameParams.Get*Mult`, `ManageNGPLevels`, `ResetLevel`, `SetLevel`, `OnLevelUpscalingChanged`), the options in `modSignsConfig.xml` |
| ARM | Player armor values and resistances by class (about 1,000 units, 276 changed by 5.x), the Viper set's poison healing in `ProcessActionDamage`, Lynx, Bear and Red Wolf bonuses in `GetAttackersPowerMod`/crit check, Wolven and Netflix sets (5.x's DD1 terms), silver studs |
| SWD | Sword damage and crit bonuses (618 units), `sword_dmg_bonus`/`spell_dmg_bonus`, Aerondight (attack power, crit, ignoring armor), Iris's phantom strike |
| XBOW | Crossbows' armor piercing and bolts (62 units), headshots ignoring armor and resistances, NPC bow damage (`W3ArrowProjectile.ProcessDamageAction`, `GetHeldWeaponDamage`), the underwater multiplier |
| ITEM | Durability (`GetDurabilityMultiplier`, the durability constants in `W3GameParams.<members>`, DMG-09), random item modifiers (`def_item_quality.xml` MA_*: attack power add removed, crits and resistances raised; 24 units), item level |
| ALCH | Oils' resistance reduction (0 in 1.32, legacy and 5.x alike: no play difference; the 0.25 is the oils' attack power, [ALCH-16](alch.md#alch-16-oils)), Mutagens 2, 5, 9, 19, 20, 26, 28, Black Blood, Dimeritium bomb, Petri Philtre in `CalculateDuration`, Golden Oriole's poison healing removed |
| ENCH | Heft, Rotation, Severance, Runeword 1 (`ProcessPreHitModifications`, attributed to MUT-11 only), Runeword 4, Glyphword 5 (`ProcessActionReflectDamage`, disabled) |
| EFX | The frozen target's knockdown (legacy removed it) and Aard force damage (the pool bonus came with ALCH-14), Frozen pausing damage over time, damage-over-time ticks (at least 1 per second, only to the stat the target uses; `W3DamageOverTimeEffect.CalculateDamage`, `OnUpdate`), bleeding and blindness crit bonuses. All ported ([efx.md](efx.md#hand-offs-received)): the frozen hit by EFX-02, the pause by EFX-03, the ticks by EFX-04 and EFX-06 (2026-10-24), the crit bonuses by ALCH-14 and SKL-03 |
| GEN | Geralt's base poison and bleeding resistance removed (`ConGeralt`), level-ups without attack power or sign intensity |
| UI | The damage shown in the character panel and tooltips (`SPlayerOffenseStats`, `GetOffenseStatsList`, the stats popup's sword sections): `SPlayerOffenseStats` is a struct, which annotations cannot extend |
| HORSE | The horse-speed attack power bonus removed from `GetPowerStatValue` |
| XP | Experience no longer from attack power and armor (`CNewNPC.CalculateExperiencePoints`) |
