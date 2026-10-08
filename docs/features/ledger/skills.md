# Ledger: skills and perks

Legacy Ghost Mode (GM, game 1.32) against 5.x's new skill tree, with vanilla 1.32 where GM replaced or removed an effect.

**Status of everything below: from code and tooltip text, not tested in game.** Amounts are at max level, from the computed tooltips (the [skill tree files](../../skill-trees/)), the skill XML (`git diff 4f7041e5 legacy-GM -- .../geralt_skills.xml`), `docs/features/skl.md` and the scripts where the tooltip is wrong (noted).

## How timing is measured

**Legacy GM (classic tree).** A skill needs `requiredPointsSpent` points already spent in its *path* (Sword, Signs or Alchemy, all branches of the path together), then 1 point per level:

| Tier | Sword, Alchemy | Signs |
|---|---|---|
| T1 | 0 | 0 |
| T2 | 8 | 6 |
| T3 | 20 | 18 |
| T4 | 28 (Alchemy) / 30 (Sword) | 28 |

Most GM skills have 5 levels, so a T4 skill at max costs 33-35 points in its path. GM's perks have 1 level, cost 1 point and have no gate: all 20 are buyable from the first level-up (each still takes a skill slot, as every skill does; slots open at character levels 0, 2, 4, 6, 8, 10, 12, 15, 18, 22, 26, 30, same in both games). Maxing everything costs 92 (Sword) + 80 (Signs) + 90 (Alchemy) + 20 (perks) = 282 points.

**5.x new tree.** `W3PlayerAbilityManager.CanLearnSkill` ignores `requiredPointsSpent` for reworked and shared skills (also the shared skills' classic tier values); the only gate is `required_skills`, and every new-tree skill has `isAlternative="1"` (any one learned prerequisite is enough). So the cost of a skill is the shortest prerequisite chain from a root (a skill with no prerequisite) in its grid, 1 point per skill:

- **unlock** = points to buy the chain plus the skill's first level; **max** = unlock + 2 (all new-tree skills have 3 levels, perks included).
- `row` is the grid row (0-25), a rough picture of depth; the point cost is what gates.
- The deepest skill in any grid costs 7 points to unlock and 9 to max (Resonance, Side Effects/Prolonged Effects slot, Crippling Strike 6/8). Maxing a whole grid is 60 points (240 for all four).
- New-tree perks have 3 levels (3 points to max) and are gated by the same chains from the six school perks (roots): every perk unlocks within 1-3 points.
- The new menu (`characterMenuDupe.ws`) still sends `requiredPointsSpent` to Flash as "points needed" for shared skills, but whether a skill can be bought is `CanLearnSkill` (`updateAvailable`). How the UI shows a shared skill with an unmet classic tier is not checked.

**Consequence in one line:** a legacy T3/T4 effect needs 20-30 points in one path first; the same or a similar effect in the new tree needs 3-7 points. The new tree front-loads almost everything.

Columns: **Points** for GM = path points needed, then levels to max; for 5.x = unlock/max in that grid. **Port decision** = what `docs/features/skl.md` decided (or recommends, Dn = open) for the new tree; empty = no change or not applicable.

## Ledger per stat

### Adrenaline gain

| Tree | Skill | Branch | Tier | Points | Max | Amount at max | Condition | Port decision (skl.md) |
|---|---|---|---|---|---|---|---|---|
| legacy GM | `sword_5` Battle Trance | Sword_BattleTrance | core | 0 (known from start) | 1 | adrenaline only from damage dealt (not from dodged/parried/countered hits) | base rule for every source |  |
| legacy GM | `sword_s21` Muscle Memory | Sword_StyleFast | T1 | 0 in Sword path; +5 to max | 5 | +15% | fast attacks only |  |
| legacy GM | `sword_s4` Strength Training | Sword_StyleStrong | T1 | 0 in Sword path; +5 to max | 5 | +15% | strong attacks only |  |
| legacy GM | `sword_s20` Razor Focus | Sword_BattleTrance | T3 | 20 in Sword path; +5 to max | 5 | +25% all gain; at least 1.25 pts on entering combat (0.25/level) |  |  |
| legacy GM | `perk_10` Adrenaline Burst | Perks | perk | 1 pt, no gate (any time) | 1 | +5% | also the cost cut per point (stamina_cost) |  |
| legacy GM | `perk_7` Bear School Techniques | Perks | perk | 1 pt, no gate (any time) | 1 | +0.025 pts per melee hit per heavy piece (+0.1/hit at 4 pieces) | flat, per heavy armor piece |  |
| legacy GM | `perk_2` Cold Blood | Perks | perk | 1 pt, no gate (any time) | 1 | each bolt hit gives a sword hit's adrenaline | split bolts 1/3 each; only on damage dealt |  |
| legacy GM | `perk_11` Focus | Perks | perk | 1 pt, no gate (any time) | 1 | casting a sign gives a sword hit's adrenaline | alternate modes per second; Quen per stamina spent |  |
| legacy GM | `perk_18` Advanced Pyrotechnics | Perks | perk | 1 pt, no gate (any time) | 1 | +0.1 pts per bomb damage instance | not raised by gain bonuses; divided among cluster fragments |  |
| 5.x new | `sword_5` Battle Trance | Sword_BattleTrance | core | 0 (known from start) | 1 | Battle Trance core as 1.32 (hits, also dodged/parried) |  | GM rule (damage dealt only) ports to both trees (SKL-07) |
| 5.x new | `sword_s22` Muscle Memory | Sword_StyleFast | row 0 | unlock 1, max 3 pts in Sword grid | 3 | none (combo damage skill) |  | D1: add +15% at L3 (0.05/level), recommended |
| 5.x new | `sword_s23` Strength Training | Sword_StyleStrong | row 3 | unlock 2, max 4 pts in Sword grid | 3 | none (combo damage skill) |  | D1: add +15% at L3, recommended |
| 5.x new | `sword_s20` Razor Focus | Sword_BattleTrance | row 12 | unlock 3, max 5 pts in Sword grid; shared (5.x requiredPointsSpent 12 ignored) | 3 | +30% from weapon strikes; +1 pt on entering combat |  | focus_add 1.25 at L3 (0.4167/level); 5.x gain kept |
| 5.x new | `perk_42` Adrenaline Burst | Perks_col3 | row 5 | unlock 2, max 4 pts in Perks grid | 3 | +6%; signs generate adrenaline |  | D40: sign adrenaline moves to Focus magic_s38; adds -3.334% melee cost per pt per level |
| 5.x new | `sword_s34` Cold Blood | Sword_Crossbow | row 3 | unlock 2, max 4 pts in Sword grid | 3 | +1.0 pt per bolt hit (0.3/0.6/1.0) | every bolt that hits | D13: legacy rule (a third of a sword hit per level, damage dealt only) |
| 5.x new | `perk_31` Attack is the Best Defense | Perks_col5 | row 8 | unlock 2, max 4 pts in Perks grid | 3 | per defensive action: parry 0.09, counter 0.6, dodge 0.3, roll 0.3 pts | runtime values x level 3 | replaced by legacy stamina rule (decided) |
| 5.x new | `sword_s30` Deadly Precision | Sword_Crossbow | row 24 | unlock 5, max 7 pts in Sword grid | 3 | +0.15 pts when the instant kill is denied by immunity |  |  |
| 5.x new | `perk_25` Bear School Techniques | Perks_col5 | row 10 | unlock 1, max 3 pts in Perks grid | 3 | none (Vitality and strong-attack damage) |  | 0.00833 pts/hit/piece/level (legacy 0.025/piece at L3), decided |
| 5.x new | `perk_39` Advanced Pyrotechnics | Perks_col3 | row 20 | unlock 2, max 4 pts in Perks grid | 3 | none (30% bomb not consumed, self-immunity) |  | 5.x design kept; no bomb adrenaline in new tree |
| 5.x new | passive:sword_adrenalinegain | passive | - | - | - | +1% per level of every equipped skill of the Sword tree (+3% per L3 skill; up to ~+36% with 12 slots) | equipped skills | removed in both trees (SKL-01) |

### Adrenaline retention (loss reduction)

| Tree | Skill | Branch | Tier | Points | Max | Amount at max | Condition | Port decision (skl.md) |
|---|---|---|---|---|---|---|---|---|
| legacy GM | `sword_5` Battle Trance | Sword_BattleTrance | core | 0 (known from start) | 1 | loss on damage taken = 0.01 pt per 1% max Vitality lost | base rule (GM) |  |
| legacy GM | `sword_s16` Resolve | Sword_BattleTrance | T1 | 0 in Sword path; +5 to max | 5 | -100% adrenaline loss on damage (20%/level) |  |  |
| 5.x new | `sword_s16` Resolve | Sword_BattleTrance | row 6 | unlock 2, max 4 pts in Sword grid; shared (5.x requiredPointsSpent 0 ignored) | 3 | -100% loss (33.3%/level) |  | 5.x values kept (= legacy total) |

### Adrenaline spending and per-point effects

| Tree | Skill | Branch | Tier | Points | Max | Amount at max | Condition | Port decision (skl.md) |
|---|---|---|---|---|---|---|---|---|
| legacy GM | `sword_5` Battle Trance | Sword_BattleTrance | core | 0 (known from start) | 1 | +10% Attack Power per point (30% at 3) | held, not consumed |  |
| legacy GM | `perk_11` Focus | Perks | perk | 1 pt, no gate (any time) | 1 | +15% Sign Intensity per point (45%) | held, not consumed |  |
| legacy GM | `perk_19` Battle Frenzy | Perks | perk | 1 pt, no gate (any time) | 1 | +10% crit chance per point (30%), replaces Battle Trance AP | held |  |
| legacy GM | `perk_10` Adrenaline Burst | Perks | perk | 1 pt, no gate (any time) | 1 | -10% melee stamina cost per point (-30%) | held |  |
| legacy GM | `alchemy_s7` Hunter Instinct | Alchemy_Oils | T4 | 28 in Alchemy path; +5 to max | 5 | +33.4% crit damage per point (100%) | vs the oil's monster type; held |  |
| legacy GM | `sword_s11` Counterattack | Sword_Utility | T3 | 20 in Sword path; +3 to max | 3 | +5% knockdown chance per point on counters (15%) | held |  |
| legacy GM | `sword_s3` Deadly Precision | Sword_Utility | T4 | 30 in Sword path; +3 to max | 3 | +3% instant-kill chance per point on counters (9%) | held; no player IK cooldown |  |
| legacy GM | `sword_s2` Rend | Sword_StyleStrong | T2 | 8 in Sword path; +5 to max | 5 | +50% weapon damage per point; 3 pts = shock wave (3 yd) | consumes all |  |
| legacy GM | `sword_s18` Undying | Sword_BattleTrance | T2 | 8 in Sword path; +5 to max | 5 | prevents death: 5 s immortality, 25% Vitality per point (75%), 120 s CD | consumes all on lethal damage |  |
| legacy GM | `sword_s19` Flood of Anger | Sword_BattleTrance | T4 | 30 in Sword path; +5 to max | 5 | 3 pts: sign at max level, +250% SI | consumed; with Rage Management cost x3 instead |  |
| legacy GM | `perk_9` Rage Management | Perks | perk | 1 pt, no gate (any time) | 1 | signs paid with adrenaline first | consumed per cast |  |
| legacy GM | `perk_13` Metabolism Boosts | Perks | perk | 1 pt, no gate (any time) | 1 | -33% potion toxicity per point | consumed on drinking |  |
| legacy GM | `sword_s1` Whirl | Sword_StyleFast | T2 | 8 in Sword path; +5 to max | 5 | drains 0.2 pts/s while spinning | consumed |  |
| 5.x new | `sword_5` Battle Trance | Sword_BattleTrance | core | 0 (known from start) | 1 | +10% Attack Power per point | held |  |
| 5.x new | `magic_s38` Focus | Signs_Yrden | row 18 | unlock 5, max 7 pts in Signs grid | 3 | +30% SI per point (10%/level/pt) | held | 5%/pt/level (15%/pt at L3); signs give adrenaline (D40) |
| 5.x new | `perk_40` Battle Frenzy | Perks_col4 | row 5 | unlock 2, max 4 pts in Perks grid | 3 | +9% crit chance per point, replaces Battle Trance AP | held | 3.334%/level (10%/pt at L3) |
| 5.x new | `alchemy_s27` Hunter Instinct | Alchemy_Oils | row 6 | unlock 2, max 4 pts in Alchemy grid | 3 | +60% crit damage | only at max adrenaline, right oil | D30: legacy per-point formula, keep right-oil condition |
| 5.x new | `sword_s2` Rend | Sword_StyleStrong | row 18 | unlock 4, max 6 pts in Sword grid; shared (5.x requiredPointsSpent 12 ignored) | 3 | +30% damage per point on hit; extra damage from stamina used; ignores defenses | consumes | legacy formula and shock wave (decided) |
| 5.x new | `sword_s18` Undying | Sword_BattleTrance | row 9 | unlock 3, max 5 pts in Sword grid; shared (5.x requiredPointsSpent 6 ignored) | 3 | instant heal 10% per point + 67%, 30 s CD | needs Battle Trance buff | D15: legacy (5 s immortality, 120 s) |
| 5.x new | `sword_s19` Flood of Anger | Sword_BattleTrance | row 24 | unlock 5, max 7 pts in Sword grid; shared (5.x requiredPointsSpent 18 ignored) | 3 | 3 pts: supercharged max-level sign, +150% SI | consumes 3 | +250% (0.8333/level); D16 sign side |
| 5.x new | `perk_32` Metabolic Boost | Perks_col1 | row 20 | unlock 2, max 4 pts in Perks grid | 3 | -30% potion toxicity per point | consumed | 5.x kept |
| 5.x new | `perk_34` Anger Management | Perks_col2 | row 13 | unlock 2, max 4 pts in Perks grid | 3 | signs paid with adrenaline when Stamina is empty, 1 pt per cast | consumed | adrenaline-first with 5.x costs (decided) |
| 5.x new | `sword_s35` Whirl | Sword_StyleFast | row 15 | unlock 5, max 7 pts in Sword grid | 3 | Whirl drains stamina and adrenaline; -50% cost at L3 | consumed | legacy Whirl numbers (STAM-09/SKL-03) |
| 5.x new | `sword_s31` Counterattack | Sword_Utility | row 18 | unlock 4, max 6 pts in Sword grid | 3 | none (no adrenaline term) |  | D9: legacy counter crit and knockdown per point |
| 5.x new | `sword_s30` Deadly Precision | Sword_Crossbow | row 24 | unlock 5, max 7 pts in Sword grid | 3 | none (no per-point IK) |  | D11 |

### Stamina regeneration and restoration

| Tree | Skill | Branch | Tier | Points | Max | Amount at max | Condition | Port decision (skl.md) |
|---|---|---|---|---|---|---|---|---|
| legacy GM | `perk_1` Sun and Stars | Perks | perk | 1 pt, no gate (any time) | 1 | +5 Stamina/s at night in combat (5% of max Stamina) | night, in combat |  |
| legacy GM | `perk_21` Attack is the Best Defense | Perks | perk | 1 pt, no gate (any time) | 1 | 15% Stamina per kill; 5% per crit or counter (2.5 s CD) |  |  |
| legacy GM | `alchemy_s1` Refreshment | Alchemy_Potions | T1 | 0 in Alchemy path; +3 to max | 3 | 30% max Stamina per potion dose (10%/level) | per potion |  |
| 5.x new | `perk_38` Sun and Stars | Perks_col1 | row 8 | unlock 2, max 4 pts in Perks grid | 3 | +3 Stamina/s at night in combat (3% max) | night, in combat | 1.667%/level (5% at L3) |
| 5.x new | `perk_24` Griffin School Techniques | Perks_col4 | row 15 | unlock 1, max 3 pts in Perks grid | 3 | ~+0.6 Stamina/s per medium piece (~2.4/s; tooltip rounds to 1) | per medium armor piece | replaced by legacy -sign cost (decided) |
| 5.x new | `perk_31` Attack is the Best Defense | Perks_col5 | row 8 | unlock 2, max 4 pts in Perks grid | 3 | none (gives adrenaline) |  | legacy stamina rule 5/10/15% kill, 1.67/3.33/5% crit/counter |
| 5.x new | `alchemy_s24` High Tolerance | Alchemy_Potions | row 15 | unlock 5, max 7 pts in Alchemy grid | 3 | none (High Tolerance: crit dmg from toxicity) |  | D27: turn into Refreshment (30% stamina per potion) |
| 5.x new | passive:magic_staminaregen | passive | - | - | - | +0.5 Stamina/s in combat per level of every equipped Signs skill (+1.5/s per L3 skill) | equipped skills | removed in both trees |

### Stamina cost reduction

| Tree | Skill | Branch | Tier | Points | Max | Amount at max | Condition | Port decision (skl.md) |
|---|---|---|---|---|---|---|---|---|
| legacy GM | `perk_6` Griffin School Techniques | Perks | perk | 1 pt, no gate (any time) | 1 | -5% sign stamina cost per medium piece (-20%) | per medium piece |  |
| legacy GM | `perk_10` Adrenaline Burst | Perks | perk | 1 pt, no gate (any time) | 1 | -10% melee action stamina cost per adrenaline point (-30%) | held adrenaline |  |
| legacy GM | `perk_9` Rage Management | Perks | perk | 1 pt, no gate (any time) | 1 | signs use adrenaline instead of Stamina | while >=1 adrenaline |  |
| legacy GM | `sword_s10` Deflection | Sword_Utility | T1 | 0 in Sword path; +3 to max | 3 | parry cost -50% vs multiple enemies | level 3 |  |
| legacy GM | `sword_s1` Whirl | Sword_StyleFast | T2 | 8 in Sword path; +5 to max | 5 | Whirl 20 Stamina/s (50 base, -15%/level above 1) |  |  |
| legacy GM | `magic_s2` Firestream | Signs_Igni | T2 | 6 in Signs path; +3 to max | 3 | Firestream 20 Stamina/s (30 base, -16.7%/level above 1) |  |  |
| legacy GM | `magic_s4` Active Shield | Signs_Quen | T2 | 6 in Signs path; +3 to max | 3 | maintaining free; blocked hits drain Stamina by damage absorbed |  |  |
| 5.x new | `magic_s39` Sidestep | Signs_Yrden | row 18 | unlock 5, max 7 pts in Signs grid | 3 | -60% Stamina cost of next sign after a dodge/roll | new-only skill |  |
| 5.x new | `sword_s35` Whirl | Sword_StyleFast | row 15 | unlock 5, max 7 pts in Sword grid | 3 | -50% Stamina and adrenaline cost of Whirl |  | legacy Whirl cost rule |
| 5.x new | `magic_s28` Firestream | Signs_Igni | row 3 | unlock 2, max 4 pts in Signs grid | 3 | -50% Firestream Stamina cost |  | legacy numbers |
| 5.x new | `magic_s4` Active Shield | Signs_Quen | row 3 | unlock 2, max 4 pts in Signs grid; shared (5.x requiredPointsSpent 6 ignored) | 3 | maintaining and blocking cost no Stamina |  | legacy: blocks drain stamina (STAM hand-off) |
| 5.x new | `perk_34` Anger Management | Perks_col2 | row 13 | unlock 2, max 4 pts in Perks grid | 3 | adrenaline casts when Stamina is empty |  | adrenaline-first |
| 5.x new | `perk_42` Adrenaline Burst | Perks_col3 | row 5 | unlock 2, max 4 pts in Perks grid | 3 | none |  | add -3.334% melee cost per adrenaline pt per level (decided) |
| 5.x new | `perk_24` Griffin School Techniques | Perks_col4 | row 15 | unlock 1, max 3 pts in Perks grid | 3 | none (regen instead) |  | -1.667% sign cost per piece per level (decided) |
| 5.x new | `sword_s33` Arrow Deflection | Sword_Utility | row 0 | unlock 1, max 3 pts in Sword grid | 3 | none |  | D6: add legacy partial-parry share and parry cost |

### Toxicity maximum and threshold

| Tree | Skill | Branch | Tier | Points | Max | Amount at max | Condition | Port decision (skl.md) |
|---|---|---|---|---|---|---|---|---|
| legacy GM | `perk_12` Metabolic Control | Perks | perk | 1 pt, no gate (any time) | 1 | +40 max Toxicity |  |  |
| legacy GM | `alchemy_s18` Acquired Tolerance | Alchemy_Mutagens | T1 | 0 in Alchemy path; +3 to max | 3 | +1 per known formula, cap +50/+100/+150 by level | scales with formulas known |  |
| legacy GM | general | general rule | - | - | - | overdose threshold fixed at 75% of max; no skill raises it | rule |  |
| 5.x new | `perk_33` Metabolic Control | Perks_col5 | row 18 | unlock 2, max 4 pts in Perks grid | 3 | +30 max Toxicity (10/level) |  | 13.334/level (40 at L3) |
| 5.x new | `alchemy_s18` Acquired Tolerance | Alchemy_Mutagens | row 9 | unlock 3, max 5 pts in Alchemy grid; shared (5.x requiredPointsSpent 0 ignored) | 3 | +0.5 per formula of level <= skill level (x level) |  | D33: +1 per formula |
| 5.x new | general | general rule | - | - | - | overdose threshold 50% (5.x); no new-tree skill raises it | rule | ALCH decides the threshold |

### Toxicity reduction

| Tree | Skill | Branch | Tier | Points | Max | Amount at max | Condition | Port decision (skl.md) |
|---|---|---|---|---|---|---|---|---|
| legacy GM | `alchemy_s3` Expert brewer | Alchemy_Potions | T4 | 28 in Alchemy path; +5 to max | 5 | -5 toxicity per potion (1/level) |  |  |
| legacy GM | `alchemy_s14` Adaptation | Alchemy_Mutagens | T3 | 20 in Alchemy path; +5 to max | 5 | -20% decoction toxicity (4%/level) |  |  |
| legacy GM | `alchemy_s15` Fast Metabolism | Alchemy_Grasses | T3 | 20 in Alchemy path; +5 to max | 5 | toxicity decays 1.25/s faster (0.25/level) |  |  |
| legacy GM | `perk_13` Metabolism Boosts | Perks | perk | 1 pt, no gate (any time) | 1 | -33% potion toxicity per adrenaline point | consumes adrenaline; not decoctions |  |
| legacy GM | `perk_15` Connoisseur | Perks | perk | 1 pt, no gate (any time) | 1 | alcohol and raw/toxic food toxicity = 0 |  |  |
| 5.x new | `alchemy_s15` Fast Metabolism | Alchemy_Grasses | row 21 | unlock 6, max 8 pts in Alchemy grid; shared (5.x requiredPointsSpent 12 ignored) | 3 | decays 3/s faster (1/level) |  | -0.4167/level (1.25 at L3) |
| 5.x new | `perk_32` Metabolic Boost | Perks_col1 | row 20 | unlock 2, max 4 pts in Perks grid | 3 | -30% potion toxicity per adrenaline point | consumes adrenaline | 5.x kept |
| 5.x new | `alchemy_s3` Delayed Recovery | Alchemy_Potions | row 15 | unlock 5, max 7 pts in Alchemy grid; shared (5.x requiredPointsSpent 12 ignored) | 3 | none (Delayed Recovery: potion extension) |  | D28/D29: Expert Brewer -5 at L3 |
| 5.x new | `alchemy_s14` Adaptability | Alchemy_Mutagens | row 3 | unlock 2, max 4 pts in Alchemy grid; shared (5.x requiredPointsSpent 18 ignored) | 3 | none (Adaptability: decoction duration) |  | Adaptation -20% decoction toxicity (decided) |
| 5.x new | `perk_41` Gourmand | Perks_col2 | row 13 | unlock 2, max 4 pts in Perks grid | 3 | none (Gourmand: food regen) |  | D41: Connoisseur |

### Potion duration

| Tree | Skill | Branch | Tier | Points | Max | Amount at max | Condition | Port decision (skl.md) |
|---|---|---|---|---|---|---|---|---|
| legacy GM | `alchemy_s4` Prolonged Effects | Alchemy_Potions | T3 | 20 in Alchemy path; +5 to max | 5 | +100% potion duration (20%/level) | potions, not decoctions; global passive |  |
| legacy GM | `perk_15` Connoisseur | Perks | perk | 1 pt, no gate (any time) | 1 | +100% alcohol buff duration | alcohol only |  |
| 5.x new | `alchemy_s4` Side Effects | Alchemy_Potions | row 24 | unlock 7, max 9 pts in Alchemy grid; shared (5.x requiredPointsSpent 18 ignored) | 3 | none (Side Effects: random free potion) |  | Prolonged Effects +100% at L3 (0.3334/level), decided |
| 5.x new | `alchemy_s3` Delayed Recovery | Alchemy_Potions | row 15 | unlock 5, max 7 pts in Alchemy grid; shared (5.x requiredPointsSpent 12 ignored) | 3 | +5 s to active potions per potion drunk above 55% toxicity |  | replaced by Expert Brewer (D29) |
| 5.x new | passive:alchemy_potionduration | passive | - | - | - | +2% potion duration AND bomb damage per level of every equipped Alchemy skill (+6% per L3) | equipped skills | removed in both trees |

### Decoction duration

| Tree | Skill | Branch | Tier | Points | Max | Amount at max | Condition | Port decision (skl.md) |
|---|---|---|---|---|---|---|---|---|
| legacy GM | general | general rule | - | - | - | none: no skill extends decoctions |  |  |
| 5.x new | `alchemy_s14` Adaptability | Alchemy_Mutagens | row 3 | unlock 2, max 4 pts in Alchemy grid; shared (5.x requiredPointsSpent 18 ignored) | 3 | +100% decoction duration (33.3%/level) |  | removed: Adaptation replaces it |

### Attack power and melee damage

| Tree | Skill | Branch | Tier | Points | Max | Amount at max | Condition | Port decision (skl.md) |
|---|---|---|---|---|---|---|---|---|
| legacy GM | `sword_2` Strong Attack | Sword_StyleStrong | core | 0 (known from start) | 1 | strong attacks +50% weapon damage (additive), +200 armor penetration | core |  |
| legacy GM | `sword_5` Battle Trance | Sword_BattleTrance | core | 0 (known from start) | 1 | +10% AP per adrenaline point | core |  |
| legacy GM | `sword_3` Defense | Sword_Utility | core | 0 (known from start) | 1 | counters count as fast attacks, no damage penalty | core |  |
| legacy GM | general | general rule | - | - | - | headshots and backstabs +25% AP | general rule |  |
| legacy GM | `sword_s21` Muscle Memory | Sword_StyleFast | T1 | 0 in Sword path; +5 to max | 5 | +25% AP fast (5%/level); code counts it twice (~+50%) | fast attacks and counters | counted once, 5.x 0.1/level (+30% at L3) |
| legacy GM | `sword_s4` Strength Training | Sword_StyleStrong | T1 | 0 in Sword path; +5 to max | 5 | +25% AP strong; counted twice (~+50%) | strong attacks | counted once (+30%) |
| legacy GM | `sword_s1` Whirl | Sword_StyleFast | T2 | 8 in Sword path; +5 to max | 5 | +5% AP per additional attacker (max 25%) | while spinning with adrenaline |  |
| legacy GM | `sword_s2` Rend | Sword_StyleStrong | T2 | 8 in Sword path; +5 to max | 5 | +50% weapon damage +50%/adrenaline pt +1%/stamina pt; ignores armor | Rend only |  |
| legacy GM | `sword_s5` Crippling Strikes | Sword_StyleFast | T4 | 30 in Sword path; +5 to max | 5 | fast attacks +25% final damage vs bleeding; 25% bleed chance (1% max HP/s, 8 s) | fast attacks |  |
| legacy GM | `sword_s6` Sunder Armor | Sword_StyleStrong | T4 | 30 in Sword path; +5 to max | 5 | -25% enemy damage resistance | always |  |
| legacy GM | `sword_s11` Counterattack | Sword_Utility | T3 | 20 in Sword path; +3 to max | 3 | +100% counter attack power | counters |  |
| legacy GM | `alchemy_s16` Frenzy | Alchemy_Grasses | T1 | 0 in Alchemy path; +5 to max | 5 | +25% AP (5%/level) | while overdosed (>75% toxicity) |  |
| legacy GM | `magic_s11` Supercharged Glyphs | Signs_Yrden | T4 | 28 in Signs path; +5 to max | 5 | enemies in Yrden trap take +25% final damage | inside trap |  |
| legacy GM | `magic_s8` Melt Armor | Signs_Igni | T1 | 0 in Signs path; +5 to max | 5 | -10 armor, -1% resistances (scales with SI: -150/-15% at 500%), 15 s | Igni hit |  |
| 5.x new | `sword_5` Battle Trance | Sword_BattleTrance | core | 0 (known from start) | 1 | +10% AP per adrenaline point | core |  |
| 5.x new | `sword_s22` Muscle Memory | Sword_StyleFast | row 0 | unlock 1, max 3 pts in Sword grid | 3 | +30% for next 3 fast attacks in a row | after a dodge/roll | D1 |
| 5.x new | `sword_s23` Strength Training | Sword_StyleStrong | row 3 | unlock 2, max 4 pts in Sword grid | 3 | next strong attack +45% | after fast attacks | D1 |
| 5.x new | `sword_s24` Three Strikes | Sword_StyleFast | row 6 | unlock 2, max 4 pts in Sword grid | 3 | 60%: 4th same-type attack +40-70% | combo | 5.x kept |
| 5.x new | `sword_s25` Crushing Blow | Sword_StyleStrong | row 12 | unlock 3, max 5 pts in Sword grid | 3 | 60%: next 2 strong attacks +50% | after a strong attack |  |
| 5.x new | `sword_s28` Sunder Armor | Sword_StyleStrong | row 21 | unlock 4, max 6 pts in Sword grid | 3 | -10% enemy resistance per stack, 3 stacks (-30%), 3-6 s | strong attacks | 5.x kept |
| 5.x new | `sword_s29` Crippling Strike | Sword_StyleFast | row 21 | unlock 6, max 8 pts in Sword grid | 3 | fast crit: target takes +30% damage, 3-6 s | needs crits | D2: keep 5.x |
| 5.x new | `sword_s31` Counterattack | Sword_Utility | row 18 | unlock 4, max 6 pts in Sword grid | 3 | next attack +100% (bolts x2) | after counter or dodge | D9 |
| 5.x new | `sword_s35` Whirl | Sword_StyleFast | row 15 | unlock 5, max 7 pts in Sword grid | 3 | none in 5.x (cost cut only) |  | legacy +25% vs crowds and -50% damage taken (decided) |
| 5.x new | `sword_s2` Rend | Sword_StyleStrong | row 18 | unlock 4, max 6 pts in Sword grid; shared (5.x requiredPointsSpent 12 ignored) | 3 | +30%/adrenaline pt, stamina-scaled damage, ignores defenses | Rend | legacy +50%/pt etc. |
| 5.x new | `magic_s41` Resonance | Signs_Yrden | row 24 | unlock 7, max 9 pts in Signs grid | 3 | next 3 melee attacks + 30% of Sign intensity as damage | after a sign |  |
| 5.x new | `perk_23` Cat School Techniques | Perks_col3 | row 0 | unlock 1, max 3 pts in Perks grid | 3 | +6% fast attack damage per light piece (24%) | light armor | legacy Cat replaces it (decided) |
| 5.x new | `perk_25` Bear School Techniques | Perks_col5 | row 10 | unlock 1, max 3 pts in Perks grid | 3 | +6% strong attack damage per heavy piece (24%) | heavy armor | Bear: legacy adrenaline per hit (decided) |
| 5.x new | `perk_26` Wolf School Techniques | Perks_col1 | row 5 | unlock 1, max 3 pts in Perks grid | 3 | +6% weapon damage per medium piece (24%) | medium armor | 5.x kept |
| 5.x new | `perk_27` Manticore School Techniques | Perks_col2 | row 20 | unlock 1, max 3 pts in Perks grid | 3 | +6% sword damage (fast and strong) per medium piece (24%) | medium armor | 5.x kept |
| 5.x new | `perk_44` Element of Surprise | Perks_col1 | row 18 | unlock 2, max 4 pts in Perks grid | 3 | +30% melee damage for 10 s | after a bomb hit | 5.x kept |
| 5.x new | `perk_37` Elemental Attunement | Perks_col4 | row 15 | unlock 3, max 5 pts in Perks grid | 3 | +9% non-physical damage (fire, frost, force, magic, poison) |  | 5.x kept |
| 5.x new | `alchemy_s26` Potent Sting | Alchemy_Potions | row 24 | unlock 5, max 7 pts in Alchemy grid | 3 | +15% damage with poisoned weapons (+30% vs poison-immune) | poison oil |  |
| 5.x new | `alchemy_s23` Toxic Shock | Alchemy_Bombs | row 9 | unlock 3, max 5 pts in Alchemy grid | 3 | strong attack on poisoned enemy: +75% of attack damage as poison, 5 s CD |  |  |
| 5.x new | `alchemy_s16` Frenzy | Alchemy_Grasses | row 0 | unlock 1, max 3 pts in Alchemy grid; shared (5.x requiredPointsSpent 0 ignored) | 3 | none (Frenzy: slowdown only) |  | +25% AP and SI while overdosed (0.0833/level) |
| 5.x new | `magic_s11` Supercharged Glyphs | Signs_Yrden | row 6 | unlock 3, max 5 pts in Signs grid; shared (5.x requiredPointsSpent 18 ignored) | 3 | 30 Vitality/s to enemies in trap |  | +25% damage taken (decided) |
| 5.x new | `magic_s8` Melt Armor | Signs_Igni | row 0 | unlock 1, max 3 pts in Signs grid; shared (5.x requiredPointsSpent 0 ignored) | 3 | Igni reduces armor (level-scaled) and +30% burn chance |  | legacy Melt Armor |

### Sign intensity

| Tree | Skill | Branch | Tier | Points | Max | Amount at max | Condition | Port decision (skl.md) |
|---|---|---|---|---|---|---|---|---|
| legacy GM | `perk_6` Griffin School Techniques | Perks | perk | 1 pt, no gate (any time) | 1 | +5% SI per medium piece (20%) | medium armor |  |
| legacy GM | `perk_11` Focus | Perks | perk | 1 pt, no gate (any time) | 1 | +15% SI per adrenaline point (45%) | held adrenaline |  |
| legacy GM | `sword_s19` Flood of Anger | Sword_BattleTrance | T4 | 30 in Sword path; +5 to max | 5 | +250% SI for one sign | 3 adrenaline (or x3 cost with Rage Management) |  |
| legacy GM | `alchemy_s16` Frenzy | Alchemy_Grasses | T1 | 0 in Alchemy path; +5 to max | 5 | +25% SI | while overdosed |  |
| legacy GM | `magic_s1` Aard Sweep | Signs_Aard | T2 | 6 in Signs path; +3 to max | 3 | Aard Sweep intensity penalty 40/20/0% |  |  |
| legacy GM | general | general rule | - | - | - | no per-sign intensity skill (the 5 Intensity skills give flat bonuses instead) |  |  |
| 5.x new | `perk_24` Griffin School Techniques | Perks_col4 | row 15 | unlock 1, max 3 pts in Perks grid | 3 | +6% SI per medium piece (24%) | medium armor | 1.667%/piece/level (20% at L3) |
| 5.x new | `perk_26` Wolf School Techniques | Perks_col1 | row 5 | unlock 1, max 3 pts in Perks grid | 3 | +6% SI per medium piece (24%) | medium armor; stacks with Griffin | 5.x kept |
| 5.x new | `magic_s38` Focus | Signs_Yrden | row 18 | unlock 5, max 7 pts in Signs grid | 3 | +30% SI per adrenaline point (90%) | held adrenaline | 15%/pt at L3 |
| 5.x new | `magic_s35` Catalyst | Signs_Yrden | row 12 | unlock 4, max 6 pts in Signs grid | 3 | +90% Aard and Igni intensity | enemies inside Yrden | kept (stacks with Supercharged Glyphs) |
| 5.x new | `magic_s37` Chain Reaction | Signs_Yrden | row 15 | unlock 5, max 7 pts in Signs grid | 3 | +15% SI to next different sign per stack, 5 stacks (+75%) | sign rotation | 5.x kept |
| 5.x new | `sword_s19` Flood of Anger | Sword_BattleTrance | row 24 | unlock 5, max 7 pts in Sword grid; shared (5.x requiredPointsSpent 18 ignored) | 3 | +150% SI, supercharged sign | 3 adrenaline | +250% |
| 5.x new | `alchemy_s16` Frenzy | Alchemy_Grasses | row 0 | unlock 1, max 3 pts in Alchemy grid; shared (5.x requiredPointsSpent 0 ignored) | 3 | none |  | +25% SI overdosed |

### Sign effects (flat, per sign)

| Tree | Skill | Branch | Tier | Points | Max | Amount at max | Condition | Port decision (skl.md) |
|---|---|---|---|---|---|---|---|---|
| legacy GM | `magic_s12` Aard Intensity | Signs_Aard | T3 | 18 in Signs path; +5 to max | 5 | +15% heavy knockdown chance | Aard |  |
| legacy GM | `magic_s6` Shock Wave | Signs_Aard | T4 | 28 in Signs path; +5 to max | 5 | Aard deals 300 damage (scales with SI) | Aard |  |
| legacy GM | `magic_s7` Igni Intensity | Signs_Igni | T3 | 18 in Signs path; +5 to max | 5 | +150 Igni damage, +75/s Firestream (scale with SI) | Igni |  |
| legacy GM | `magic_s9` Pyromaniac | Signs_Igni | T4 | 28 in Signs path; +5 to max | 5 | +25% burn chance | Igni (base 33%) |  |
| legacy GM | `magic_s2` Firestream | Signs_Igni | T2 | 6 in Signs path; +3 to max | 3 | Firestream 100 damage/s (scales), burning | Igni alt |  |
| legacy GM | `magic_s16` Yrden Intensity | Signs_Yrden | T3 | 18 in Signs path; +5 to max | 5 | +150 turret damage (scales) | Yrden alt |  |
| legacy GM | `magic_s3` Magic turret | Signs_Yrden | T2 | 6 in Signs path; +3 to max | 3 | turret 100 damage (scales), ignores armor, 15 s | Yrden alt |  |
| legacy GM | `magic_s10` Sustained Glyphs | Signs_Yrden | T1 | 0 in Signs path; +3 to max | 3 | +100% trap duration, +30% radius, 2nd trap | Yrden |  |
| legacy GM | `magic_s15` Quen Intensity | Signs_Quen | T3 | 18 in Signs path; +5 to max | 5 | +150 Quen absorption (scales; base 250) | Quen |  |
| legacy GM | `magic_s13` Exploding Shield | Signs_Quen | T1 | 0 in Signs path; +3 to max | 3 | 60 damage + knock-back when Quen breaks (scales) | Quen |  |
| legacy GM | `magic_s14` Quen Discharge | Signs_Quen | T4 | 28 in Signs path; +5 to max | 5 | reflects 25% of absorbed damage | Quen |  |
| legacy GM | `magic_s18` Axii Intensity | Signs_Axi | T3 | 18 in Signs path; +5 to max | 5 | +50% Axii duration | Axii |  |
| legacy GM | `magic_s5` Puppet | Signs_Axi | T2 | 6 in Signs path; +3 to max | 3 | Puppet 20 s (scales), ally +100% AP | Axii alt |  |
| legacy GM | `magic_s19` Domination | Signs_Axi | T4 | 28 in Signs path; +3 to max | 3 | two Axii targets, no duration penalty | Axii |  |
| 5.x new | `magic_s36` Fortify Signs | Signs_Yrden | row 12 | unlock 4, max 6 pts in Signs grid | 3 | +60% duration of Yrden, Quen, Axii |  | kept |
| 5.x new | `magic_s33` Shockwave | Signs_Aard | row 9 | unlock 3, max 5 pts in Signs grid | 3 | Aard +3% of current Vitality as damage |  | D20: legacy 300 damage scaling with SI |
| 5.x new | `magic_s40` Aftershock | Signs_Yrden | row 21 | unlock 6, max 8 pts in Signs grid | 3 | every sign deals magic damage in a small radius (15 x level, scales with SI) |  |  |
| 5.x new | `magic_s42` Sustained Glyphs | Signs_Yrden | row 0 | unlock 1, max 3 pts in Signs grid | 3 | +15 s duration, +30% area, +6 charges, +3 traps | Yrden | D23: +33.3%/level, 2nd trap at L3 |
| 5.x new | `magic_s28` Firestream | Signs_Igni | row 3 | unlock 2, max 4 pts in Signs grid | 3 | Firestream, -50% cost | Igni alt | legacy damage numbers |
| 5.x new | `magic_s31` Puppetmaster | Signs_Axi | row 3 | unlock 2, max 4 pts in Signs grid | 3 | Puppet ally +60% damage, 9 s base, not freed by Geralt at L3 | Axii alt | D24: legacy Puppet |
| 5.x new | `magic_s3` Magic Trap | Signs_Yrden | row 3 | unlock 2, max 4 pts in Signs grid; shared (5.x requiredPointsSpent 6 ignored) | 3 | turret, +50% damage at L3 (14 yd) | shared | legacy turret |
| 5.x new | `magic_s13` Exploding Shield | Signs_Quen | row 0 | unlock 1, max 3 pts in Signs grid; shared (5.x requiredPointsSpent 0 ignored) | 3 | push-back when Quen breaks | shared | legacy 60 damage |
| 5.x new | `magic_s4` Active Shield | Signs_Quen | row 3 | unlock 2, max 4 pts in Signs grid; shared (5.x requiredPointsSpent 6 ignored) | 3 | active shield, heals absorbed damage | shared | legacy rework |
| 5.x new | `magic_s19` Domination | Signs_Axi | row 9 | unlock 3, max 5 pts in Signs grid; shared (5.x requiredPointsSpent 18 ignored) | 3 | two Axii targets | shared | legacy |
| 5.x new | `magic_s17` Delusion | Signs_Axi | row 0 | unlock 1, max 3 pts in Signs grid; shared (5.x requiredPointsSpent 0 ignored) | 3 | target does not approach while casting | shared | legacy +45% slowdown, +75% crit vs confused |
| 5.x new | general | general rule | - | - | - | no intensity skills, no Pyromaniac, no Quen Discharge (classic only) |  |  |

### Bomb damage

| Tree | Skill | Branch | Tier | Points | Max | Amount at max | Condition | Port decision (skl.md) |
|---|---|---|---|---|---|---|---|---|
| legacy GM | `alchemy_3` Bomb Creation | Alchemy_Bombs | core | 0 (known from start) | 1 | non-aimed bombs -50%; bomb damage not affected by AP | core |  |
| legacy GM | `alchemy_s10` Pyrotechnics | Alchemy_Bombs | T2 | 8 in Alchemy path; +5 to max | 5 | +250 damage to every bomb (50/level) |  |  |
| legacy GM | `alchemy_s11` Cluster Bombs | Alchemy_Bombs | T4 | 28 in Alchemy path; +5 to max | 5 | 6 fragments, each a full bomb's damage | fragment damage values in XML read by no script |  |
| legacy GM | `perk_20` Heavy Artillery | Perks | perk | 1 pt, no gate (any time) | 1 | +100% base bomb damage, -50% stack size |  |  |
| legacy GM | `alchemy_s8` Efficiency | Alchemy_Bombs | T3 | 20 in Alchemy path; +5 to max | 5 | +5 bombs per slot |  |  |
| legacy GM | `perk_16` In Combat's Fires | Perks | perk | 1 pt, no gate (any time) | 1 | ignore own bomb/bolt effects; own bomb/bolt damage -50% | code also halves damage to enemies (D38) |  |
| 5.x new | `alchemy_s10` Pyrotechnics | Alchemy_Bombs | row 6 | unlock 2, max 4 pts in Alchemy grid; shared (5.x requiredPointsSpent 6 ignored) | 3 | +150 damage (50/level) | shared | 83.33/level (250 at L3) |
| 5.x new | `alchemy_s11` Cluster Bombs | Alchemy_Bombs | row 24 | unlock 5, max 7 pts in Alchemy grid; shared (5.x requiredPointsSpent 18 ignored) | 3 | 4 fragments x 40% damage | shared | D31: 2/4/6 full-damage fragments |
| 5.x new | `alchemy_s8` Efficiency | Alchemy_Bombs | row 0 | unlock 1, max 3 pts in Alchemy grid; shared (5.x requiredPointsSpent 12 ignored) | 3 | +3 bombs per slot | shared | D32: +3 |
| 5.x new | `alchemy_s25` Volatile Compound | Alchemy_Oils | row 18 | unlock 4, max 6 pts in Alchemy grid | 3 | +0.3% bomb damage per toxicity point | scales with current toxicity | 5.x kept |
| 5.x new | `perk_27` Manticore School Techniques | Perks_col2 | row 20 | unlock 1, max 3 pts in Perks grid | 3 | +6% bomb damage per medium piece (24%) | medium armor | 5.x kept |
| 5.x new | `perk_37` Elemental Attunement | Perks_col4 | row 15 | unlock 3, max 5 pts in Perks grid | 3 | +9% non-physical damage (bomb elements) |  |  |
| 5.x new | `perk_39` Advanced Pyrotechnics | Perks_col3 | row 20 | unlock 2, max 4 pts in Perks grid | 3 | 30% chance a thrown bomb is not consumed; own bomb immunity |  | D39 |
| 5.x new | passive:alchemy_potionduration | passive | - | - | - | +2% bomb damage per level of every equipped Alchemy skill |  | removed |
| 5.x new | general | general rule | - | - | - | no Heavy Artillery, no In Combat's Fires in the new tree |  |  |

### Crossbow damage

| Tree | Skill | Branch | Tier | Points | Max | Amount at max | Condition | Port decision (skl.md) |
|---|---|---|---|---|---|---|---|---|
| legacy GM | `sword_4` Marksmanship | Sword_Crossbow | core | 0 (known from start) | 1 | non-aimed bolts -50% | core |  |
| legacy GM | `sword_s15` Steady Shot | Sword_Crossbow | T2 | 8 in Sword path; +5 to max | 5 | +50 base bolt damage (10/level) |  |  |
| legacy GM | `sword_s12` Crippling Shot | Sword_Crossbow | T4 | 30 in Sword path; +5 to max | 5 | crossbow crits disable monster abilities 25 s |  |  |
| legacy GM | `perk_17` Trick Shot | Perks | perk | 1 pt, no gate (any time) | 1 | one extra bolt before reload |  |  |
| legacy GM | `sword_s13` Lightning Reflexes | Sword_Crossbow | T1 | 0 in Sword path; +3 to max | 3 | +45% slowdown while aiming |  |  |
| 5.x new | `sword_s26` Anatomical Knowledge | Sword_Crossbow | row 12 | unlock 3, max 5 pts in Sword grid | 3 | +30% of silver sword base damage added to bolts |  | D14: keep 5.x |
| 5.x new | `sword_s31` Counterattack | Sword_Utility | row 18 | unlock 4, max 6 pts in Sword grid | 3 | bolts x2 after counter or dodge |  | D9 |
| 5.x new | `sword_s32` Lightning Reflexes | Sword_Crossbow | row 12 | unlock 3, max 5 pts in Sword grid | 3 | headshot x2.5 (tooltip +250%), 15% IK on bolt headshots, +90% slowdown |  | 5.x kept |
| 5.x new | `sword_s27` Maiming Shot | Sword_Crossbow | row 21 | unlock 4, max 6 pts in Sword grid | 3 | after a weapon/sign crit, next bolt disables abilities 12 s |  | 5.x kept |
| 5.x new | general | general rule | - | - | - | no Steady Shot, no Trick Shot, no crossbow crit chance in the new tree |  |  |

### Critical hit chance

| Tree | Skill | Branch | Tier | Points | Max | Amount at max | Condition | Port decision (skl.md) |
|---|---|---|---|---|---|---|---|---|
| legacy GM | `sword_3` Defense | Sword_Utility | core | 0 (known from start) | 1 | +25% on counters | core |  |
| legacy GM | `magic_5` Axii Sign | Signs_Axi | core | 0 (known from start) | 1 | +25% vs confused enemies | core Axii |  |
| legacy GM | `sword_s17` Precise Blows | Sword_StyleFast | T3 | 20 in Sword path; +5 to max | 5 | +10% fast attacks (2%/level) |  |  |
| legacy GM | `sword_s8` Crushing Blows | Sword_StyleStrong | T3 | 20 in Sword path; +5 to max | 5 | +10% strong attacks |  |  |
| legacy GM | `sword_s7` Anatomical Knowledge | Sword_Crossbow | T3 | 20 in Sword path; +5 to max | 5 | +25% crossbow |  |  |
| legacy GM | `sword_s2` Rend | Sword_StyleStrong | T2 | 8 in Sword path; +5 to max | 5 | +100% (Rend) | Rend only |  |
| legacy GM | `sword_s11` Counterattack | Sword_Utility | T3 | 20 in Sword path; +3 to max | 3 | +70% on counters (100% with core 25% + 5%) | counters |  |
| legacy GM | `perk_5` Cat School Techniques | Perks | perk | 1 pt, no gate (any time) | 1 | +5% per light piece (20%) | light armor |  |
| legacy GM | `perk_19` Battle Frenzy | Perks | perk | 1 pt, no gate (any time) | 1 | +10% per adrenaline point (30%) | held adrenaline; replaces AP bonus |  |
| legacy GM | `alchemy_s17` Killing Spree | Alchemy_Grasses | T4 | 28 in Alchemy path; +5 to max | 5 | +25% per kill for the fight | toxicity > 0 |  |
| legacy GM | `magic_s17` Delusion | Signs_Axi | T1 | 0 in Signs path; +3 to max | 3 | +75% vs confused | Axii |  |
| 5.x new | `perk_40` Battle Frenzy | Perks_col4 | row 5 | unlock 2, max 4 pts in Perks grid | 3 | +9% per adrenaline point (27%) | replaces AP bonus | 10%/pt at L3 |
| 5.x new | `perk_23` Cat School Techniques | Perks_col3 | row 0 | unlock 1, max 3 pts in Perks grid | 3 | none (crit damage and fast damage) |  | +1.667% crit chance per piece per level (20% at L3), decided |
| 5.x new | `sword_s2` Rend | Sword_StyleStrong | row 18 | unlock 4, max 6 pts in Sword grid; shared (5.x requiredPointsSpent 12 ignored) | 3 | none in 5.x | shared | +100% at L3 (0.3333/level) |
| 5.x new | `magic_s17` Delusion | Signs_Axi | row 0 | unlock 1, max 3 pts in Signs grid; shared (5.x requiredPointsSpent 0 ignored) | 3 | none in 5.x | shared | +75% vs confused (legacy) |
| 5.x new | `sword_s31` Counterattack | Sword_Utility | row 18 | unlock 4, max 6 pts in Sword grid | 3 | crit needs level >3 (unreachable) |  | D9: legacy +70% on counters |
| 5.x new | general | general rule | - | - | - | no Precise Blows, Crushing Blows, Anatomical crit, Killing Spree in new tree |  |  |

### Critical hit damage

| Tree | Skill | Branch | Tier | Points | Max | Amount at max | Condition | Port decision (skl.md) |
|---|---|---|---|---|---|---|---|---|
| legacy GM | `sword_s17` Precise Blows | Sword_StyleFast | T3 | 20 in Sword path; +5 to max | 5 | +75% fast attacks (15%/level) |  |  |
| legacy GM | `sword_s8` Crushing Blows | Sword_StyleStrong | T3 | 20 in Sword path; +5 to max | 5 | +75% strong attacks |  |  |
| legacy GM | `sword_s7` Anatomical Knowledge | Sword_Crossbow | T3 | 20 in Sword path; +5 to max | 5 | +75% crossbow |  |  |
| legacy GM | `perk_5` Cat School Techniques | Perks | perk | 1 pt, no gate (any time) | 1 | +20% per light piece (80%) | light armor |  |
| legacy GM | `alchemy_s7` Hunter Instinct | Alchemy_Oils | T4 | 28 in Alchemy path; +5 to max | 5 | +33.4% per adrenaline point (100%) | vs oil's monster type |  |
| 5.x new | `perk_23` Cat School Techniques | Perks_col3 | row 0 | unlock 1, max 3 pts in Perks grid | 3 | +24% per light piece (96%) | light armor | legacy +6.667%/piece/level (80% at L3) |
| 5.x new | `alchemy_s27` Hunter Instinct | Alchemy_Oils | row 6 | unlock 2, max 4 pts in Alchemy grid | 3 | +60% | max adrenaline and right oil | D30 |
| 5.x new | `alchemy_s24` High Tolerance | Alchemy_Potions | row 15 | unlock 5, max 7 pts in Alchemy grid | 3 | +60% at full toxicity (tooltip 100%) | only at >=80% toxicity; take 150% damage | D27: becomes Refreshment |

### Vitality (max)

| Tree | Skill | Branch | Tier | Points | Max | Amount at max | Condition | Port decision (skl.md) |
|---|---|---|---|---|---|---|---|---|
| legacy GM | general | general rule | - | - | - | each character level +50 base Vitality (nothing else) | level-up |  |
| legacy GM | `perk_4` Survival Instinct | Perks | perk | 1 pt, no gate (any time) | 1 | +750 base Vitality |  |  |
| legacy GM | `perk_7` Bear School Techniques | Perks | perk | 1 pt, no gate (any time) | 1 | +7.5% max Vitality per heavy piece (30%) | heavy armor |  |
| legacy GM | `alchemy_s20` Endure Pain | Alchemy_Grasses | T2 | 8 in Alchemy path; +5 to max | 5 | +50% max Vitality (10%/level) | while overdosed |  |
| legacy GM | `alchemy_s13` Tissue Transmutation | Alchemy_Mutagens | T2 | 8 in Alchemy path; +5 to max | 5 | +10 Vitality per toxicity-offset point of active decoctions (2/level) | decoctions |  |
| 5.x new | `perk_30` Survival Instinct | Perks_col2 | row 10 | unlock 3, max 5 pts in Perks grid | 3 | +24% max Vitality (8%/level) |  | D37: +750 flat |
| 5.x new | `perk_25` Bear School Techniques | Perks_col5 | row 10 | unlock 1, max 3 pts in Perks grid | 3 | +6% per heavy piece (24%) | heavy armor | 2.5%/piece/level (30% at L3) |
| 5.x new | `perk_28` Viper School Techniques | Perks_col3 | row 25 | unlock 1, max 3 pts in Perks grid | 3 | +6% per medium piece (24%), +6% poison damage | medium armor | 5.x kept |
| 5.x new | `alchemy_s20` Endure Pain | Alchemy_Grasses | row 3 | unlock 2, max 4 pts in Alchemy grid; shared (5.x requiredPointsSpent 6 ignored) | 3 | +30% | overdosed; shared | D34: +30% |
| 5.x new | `alchemy_s13` Tissue Transmutation | Alchemy_Mutagens | row 12 | unlock 4, max 6 pts in Alchemy grid; shared (5.x requiredPointsSpent 6 ignored) | 3 | +900 per active decoction | shared | 3.333/level per offset point |
| 5.x new | passive:survival_vitality | passive | - | - | - | +1% max Vitality per level of every equipped perk (+3% per L3 perk) | equipped perks | removed |

### Vitality regeneration and healing

| Tree | Skill | Branch | Tier | Points | Max | Amount at max | Condition | Port decision (skl.md) |
|---|---|---|---|---|---|---|---|---|
| legacy GM | general | general rule | - | - | - | base Vitality regen 0 in and out of combat | rule |  |
| legacy GM | `perk_1` Sun and Stars | Perks | perk | 1 pt, no gate (any time) | 1 | +10 Vitality/s out of combat during the day | day |  |
| legacy GM | `alchemy_s2` Restoration | Alchemy_Potions | T2 | 8 in Alchemy path; +3 to max | 3 | 15% max Vitality per potion dose (5%/level) |  |  |
| legacy GM | `magic_s4` Active Shield | Signs_Quen | T2 | 6 in Signs path; +3 to max | 3 | heals 100% of damage absorbed | Active Shield |  |
| legacy GM | `sword_s18` Undying | Sword_BattleTrance | T2 | 8 in Sword path; +5 to max | 5 | Undying (see adrenaline_spend) |  |  |
| 5.x new | `perk_38` Sun and Stars | Perks_col1 | row 8 | unlock 2, max 4 pts in Perks grid | 3 | +30 Vitality/s out of combat during the day | day | decision covers the night value only |
| 5.x new | `alchemy_s2` Refreshment | Alchemy_Potions | row 0 | unlock 1, max 3 pts in Alchemy grid; shared (5.x requiredPointsSpent 6 ignored) | 3 | 30% Vitality per potion dose (10%/level) | shared (Refreshment in 5.x) | Restoration 0.05/level (15%) |
| 5.x new | `perk_41` Gourmand | Perks_col2 | row 13 | unlock 2, max 4 pts in Perks grid | 3 | food regenerates Vitality for 15 min |  | D41: Connoisseur |
| 5.x new | `magic_s4` Active Shield | Signs_Quen | row 3 | unlock 2, max 4 pts in Signs grid; shared (5.x requiredPointsSpent 6 ignored) | 3 | absorbed damage restores Vitality | shared | legacy |

### Damage reduction and resistances

| Tree | Skill | Branch | Tier | Points | Max | Amount at max | Condition | Port decision (skl.md) |
|---|---|---|---|---|---|---|---|---|
| legacy GM | `alchemy_s5` Protective Coating | Alchemy_Oils | T2 | 8 in Alchemy path; +5 to max | 5 | -15% damage from the oil's monster type (+5% enhanced, +10% superior), decays with oil | oil |  |
| legacy GM | `sword_s1` Whirl | Sword_StyleFast | T2 | 8 in Sword path; +5 to max | 5 | -50% damage taken | while spinning with adrenaline |  |
| legacy GM | `sword_s10` Deflection | Sword_Utility | T1 | 0 in Sword path; +3 to max | 3 | partial parries and counters -30% more (to 20% taken) |  |  |
| legacy GM | `sword_s9` Fleet Footed | Sword_Utility | T2 | 8 in Sword path; +5 to max | 5 | graze damage while dodging -50% (10%/level) | dodging/rolling |  |
| legacy GM | `magic_4` Quen Sign | Signs_Quen | core | 0 (known from start) | 1 | Quen absorbs 250 before armor (scales), 30 s | core |  |
| 5.x new | `alchemy_s5` Protective Coating | Alchemy_Oils | row 9 | unlock 3, max 5 pts in Alchemy grid; shared (5.x requiredPointsSpent 6 ignored) | 3 | 15% vs oil's monster type | shared | 0.05/level + oil-level bonuses |
| 5.x new | `sword_s36` Fleet-Footed | Sword_Utility | row 12 | unlock 4, max 6 pts in Sword grid | 3 | -100% damage while dodging (33.3%/level) |  | 0.1667/level (50% at L3) |
| 5.x new | `alchemy_s22` Debilitating Poison | Alchemy_Grasses | row 18 | unlock 4, max 6 pts in Alchemy grid | 3 | poisoned enemies deal -15% damage | poison | 5.x kept |
| 5.x new | `sword_s35` Whirl | Sword_StyleFast | row 15 | unlock 5, max 7 pts in Sword grid | 3 | none in 5.x |  | legacy -50% while spinning |

### Other defensive

| Tree | Skill | Branch | Tier | Points | Max | Amount at max | Condition | Port decision (skl.md) |
|---|---|---|---|---|---|---|---|---|
| legacy GM | `sword_3` Defense | Sword_Utility | core | 0 (known from start) | 1 | arrows parried by default; counters +25% crit | core |  |
| legacy GM | `sword_s10` Deflection | Sword_Utility | T1 | 0 in Sword path; +3 to max | 3 | perfect parry reflects arrows, +100% reflected damage |  |  |
| legacy GM | `alchemy_s16` Frenzy | Alchemy_Grasses | T1 | 0 in Alchemy path; +5 to max | 5 | 75% time slowdown 1.5 s when an enemy counterattacks | toxicity > 0 |  |
| legacy GM | `magic_s17` Delusion | Signs_Axi | T1 | 0 in Signs path; +3 to max | 3 | +45% time slowdown while casting Axii |  |  |
| 5.x new | `sword_s33` Arrow Deflection | Sword_Utility | row 0 | unlock 1, max 3 pts in Sword grid | 3 | parry arrows; perfect parry reflects +100%, 45% instant kill |  | D6 |
| 5.x new | `alchemy_s16` Frenzy | Alchemy_Grasses | row 0 | unlock 1, max 3 pts in Alchemy grid; shared (5.x requiredPointsSpent 0 ignored) | 3 | time slowdown 15% when enemy counterattacks | shared | 75%, 1.5 s |

### Utility

| Tree | Skill | Branch | Tier | Points | Max | Amount at max | Condition | Port decision (skl.md) |
|---|---|---|---|---|---|---|---|---|
| legacy GM | `perk_22` Strong Back | Perks | perk | 1 pt, no gate (any time) | 1 | +40 carry weight |  |  |
| legacy GM | `perk_14` Gorged on Power | Perks | perk | 1 pt, no gate (any time) | 1 | Place of Power bonus lasts indefinitely (one at a time) |  |  |
| legacy GM | `alchemy_s19` Synergy | Alchemy_Mutagens | T4 | 28 in Alchemy path; +5 to max | 5 | +50% mutagen bonus (10%/level) | tier 4 (GM moved from tier 3) |  |
| legacy GM | `alchemy_s6` Fixative | Alchemy_Oils | T3 | 20 in Alchemy path; +3 to max | 3 | oil charges +33%/level, no wear at L3 |  |  |
| legacy GM | `alchemy_s9` Steady Aim | Alchemy_Bombs | T1 | 0 in Alchemy path; +3 to max | 3 | +45% slowdown aiming bombs |  |  |
| 5.x new | `perk_35` Strong Back | Perks_col5 | row 10 | unlock 3, max 5 pts in Perks grid | 3 | +60 carry weight (20/level) |  | 13.334/level (40 at L3) |
| 5.x new | `perk_43` Synergy | Perks_col4 | row 15 | unlock 3, max 5 pts in Perks grid | 3 | +30% mutagen bonus (10%/level) |  | 5.x kept |
| 5.x new | general | general rule | - | - | - | no Gorged on Power, Trick Shot, Fixative, Steady Aim in new tree |  |  |

## Summary per stat: totals, timing, gaps

"5.x new" means 5.x's own values; "after port" means with skl.md's decisions (recommendations for open Dn). Passive path bonuses are removed by the port in both trees, so they are not counted in the totals.

### Tier 1: hard to scale

| Stat | Legacy GM: total and timing | 5.x new: total and timing | Gap |
|---|---|---|---|
| **Adrenaline gain** | +15% fast or strong (T1, 5 pts), +25% Razor Focus (**T3**: 20 sword pts + 5), +5% Adrenaline Burst (perk, any time), Bear +0.1/hit with 4 heavy pieces (perk); source unlocks as perks: bolts (Cold Blood), signs (Focus), bombs (Advanced Pyrotechnics). Sword build ~+45% by T3. | Razor Focus +30% and +1 pt at combat start (**3 pts**, max 5), Adrenaline Burst +6% (2-4 pts); Cold Blood **1 full point per bolt** (2-4 pts); Attack is the Best Defense **adrenaline from every parry/counter/dodge/roll** (2-4 pts); signs generate adrenaline via perk_42. Muscle Memory/Strength Training give none. | 5.x's raw generation is far higher and front-loaded (Cold Blood, AitBD); the port neutralises both (D13, AitBD → stamina). After port: Razor Focus at 3 pts instead of 25, MM/ST +15% only if D1. **No bomb-adrenaline source in the new tree** (perk_18 is classic only, perk_39 does something else). |
| **Adrenaline retention** | Resolve −100% loss, T1, 5 pts. | Resolve −100%, 2 pts unlock, 4 max (shared). | Same total, slightly cheaper. |
| **Adrenaline spending (per-point)** | Battle Trance +10% AP/pt (core). Perks, 1 pt each, any time: Focus +15% SI/pt, Battle Frenzy +10% crit/pt, Adrenaline Burst −10% melee cost/pt. Skills: Rend +50%/pt (T2), Counterattack +5% KD/pt (T3), Deadly Precision +3% IK/pt (T4), Hunter Instinct +33.4% crit dmg/pt (T4), Undying 25%/pt (T2), Flood of Anger 3 pts → +250% SI (**T4**, 30 pts). | Focus +30% SI/pt (**5 pts unlock, 7 max**), Battle Frenzy +9%/pt (2-4), Rend +30%/pt (4-6), Undying 10%/pt +67% (3-5), Flood of Anger +150% (**5-7 pts**), Hunter Instinct only at full adrenaline, no per-point melee cost cut, no per-point counter KD or IK. | Legacy's per-point effects are cheap perks; in the new tree Focus is deep in the sign grid (but double strength) while Flood of Anger moves from the last tier to 5 points. **Missing in 5.x new:** Adrenaline Burst's cost cut, per-point Hunter Instinct, per-point counter KD/IK (all handled by decisions or D9-D11/D30). |
| **Stamina regen / restore** | Sun and Stars +5/s at night in combat (perk), AitBD 15% on kill / 5% on crit or counter (perk), Refreshment 30% per potion (Alchemy **T1**, 3 pts). No other regen (passives and armor regen removed). | Sun and Stars +3/s at night (2-4 pts), Griffin ~+0.6/s per medium piece (1-3 pts). No restore on kill, no Refreshment (alchemy_s1 is classic only; its new-tree slot is High Tolerance). 5.x passive +1.5/s per L3 sign skill (up to ~+18/s with 12) removed by the port. | **Refreshment and AitBD's stamina have no 5.x new counterpart**; the port adds them (AitBD decided, Refreshment D27 on alchemy_s24 at 5-7 pts). |
| **Stamina cost** | Griffin −5% sign cost per medium piece (−20%), Adrenaline Burst −10% melee cost per adrenaline pt (−30%), Rage Management (signs on adrenaline first), Deflection −50% parry cost vs groups (T1 L3), Whirl/Firestream per-level cost cuts. All the big ones are perks: available from level 1. | Sidestep −60% on the next sign after a dodge (new-only, 5-7 pts), Whirl and Firestream −50%, Active Shield free, Anger Management (only when Stamina is empty). **No melee cost reduction, no general sign cost reduction.** | Legacy's melee stamina economy (Adrenaline Burst) and sign economy (Griffin, Rage Management first) are missing from 5.x new; the port adds them at 3 levels (−30% melee at L3 and 3 pts; −20% sign cost at L3). |
| **Toxicity max** | Metabolic Control +40 (perk), Acquired Tolerance +1 per formula up to +150 (Alchemy T1, 3 pts). Threshold fixed at 75% of max. | Metabolic Control +30 (2-4 pts), Acquired Tolerance +0.5 per formula of its level (3-5 pts). Threshold 50% (ALCH), nothing in the new tree raises it. | Similar shape; 5.x new lower totals (port: 40 and +1/formula, D33). The 50% threshold is ALCH's call and moves every "while overdosed" effect below. |
| **Toxicity reduction** | Expert Brewer −5 per potion (**T4**, 28 alch pts + 5), Adaptation −20% decoction tox (T3), Fast Metabolism +1.25/s (T3), Metabolism Boost −33%/adrenaline pt (perk), Connoisseur (alcohol, raw food = 0). | Fast Metabolism +3/s (**6 pts**, max 8), Metabolic Boost −30%/pt (2-4 pts). No flat potion reduction, no decoction reduction, no alcohol/food removal. | After port Expert Brewer sits in alchemy_s3's slot (5 pts unlock, 7 max) instead of 33 points, Adaptation in alchemy_s14's (2-4 pts) instead of 25: **much earlier**. Fast Metabolism also much earlier. |
| **Potion duration** | Prolonged Effects +100% (Alchemy **T3**: 20 pts + 5 = 25). | None (Side Effects in that slot; Delayed Recovery's +5 s per potion is situational). 5.x passive +6% per L3 alchemy skill (removed). | **5.x new has no potion-duration skill.** After port Prolonged Effects is on alchemy_s4 at row 24: **7 pts unlock, 9 max**, i.e. 16+ points earlier than legacy. |
| **Decoction duration** | None (GM removed Adaptability's duration). | Adaptability +100% (2-4 pts). | 5.x new has much more; the port removes it (Adaptation replaces it), matching legacy. |

### Tier 2

| Stat | Legacy GM | 5.x new | Gap |
|---|---|---|---|
| **Attack power** | Flat and early: Muscle Memory/Strength Training +25% (T1; the code counts it twice, ~+50%; the port counts once at 5.x's +30%), strong attack +50% weapon damage (core), Battle Trance +10%/pt. Conditional: Whirl +25% (T2), Rend (T2), Counterattack +100% (T3), Crippling Strikes +25% vs bleeding (**T4**), Sunder −25% resist (**T4**), Frenzy +25% overdosed (Alchemy T1), Supercharged Glyphs +25% (Signs T4). | No unconditional fast/strong AP (classic sword_s21/s4 only). Conditional combos: MM +30% after dodge, ST +45% next strong, Three Strikes, Crushing Blow, Counterattack +100% after counter/dodge; Sunder −30% in 3 stacks (4-6 pts), Crippling Strike +30% after fast crits (6-8 pts). Armor perks: Cat +24% fast, Bear +24% strong, Wolf +24% weapon, Manticore +24% sword (1-3 pts each, roots), Element of Surprise +30%, Elemental Attunement +9%. | New tree trades flat AP for combos and armor-perk stacking; endgame legacy effects (Sunder, Crippling) arrive at 4-8 pts. Crippling Strike depends on crits the new tree hardly gives (below). Frenzy's AP comes only from the port. |
| **Sign intensity** | Griffin +20% (perk), Focus +45% at 3 adrenaline (perk), Frenzy +25% overdosed (Alchemy T1), Flood of Anger +250% one sign (Sword **T4**). The five Intensity skills give flat bonuses, not SI. | Griffin +24% and Wolf +24% (stack, both roots, 1-3 pts), Focus +90% (5-7 pts), Catalyst +90% Aard/Igni in Yrden (4-6), Chain Reaction +75% (5-7), Flood of Anger +150% (5-7). | **5.x new's SI ceiling is far higher and earlier.** After port Griffin/Focus/Flood of Anger match legacy, but Wolf, Catalyst and Chain Reaction stay (balance flag in SKL-10). |
| **Sign flat effects** | Aard Intensity +15% heavy KD, Shock Wave 300, Igni Intensity +150, Pyromaniac +25% burn, Yrden Intensity +150, Quen Intensity +150, Quen Discharge 25%, Axii Intensity +50% duration (all T3/T4, 18-28 sign pts). | None of the Intensity skills, Pyromaniac or Quen Discharge; Shockwave = 3% current Vitality; Fortify Signs +60% duration; Aftershock. | **The T3/T4 per-sign flat bonuses have no new-tree home** (classic only). |
| **Bomb damage** | Pyrotechnics +250 (Alchemy T2, 8 pts), Heavy Artillery +100% (perk), Cluster Bombs 6 full-damage fragments (T4), Efficiency +5 (T3). Non-aimed −50%. | Pyrotechnics +150 (2-4 pts), Cluster Bombs 4 × 40% (5-7), Volatile Compound +0.3%/toxicity pt (4-6), Manticore +24% (medium armor), Elemental Attunement +9%. | **No Heavy Artillery (x2) in the new tree**; the port lifts Pyrotechnics to 250 and (D31) Cluster to legacy; no bomb adrenaline. |
| **Crossbow damage** | Steady Shot +50 base (T2), Anatomical Knowledge +25% crit/+75% crit dmg (T3), Trick Shot (perk), Cold Blood adrenaline (perk). Non-aimed −50%. | Anatomical Knowledge +30% of silver sword damage (3-5), Counterattack bolts x2 after counter/dodge (4-6), Lightning Reflexes headshot x2.5 and 15% IK (3-5). | **No flat bolt damage, no crossbow crit, no Trick Shot** in the new tree; 5.x's new crossbow skills are multipliers instead. |
| **Crit chance** | Many: counters +25% (core) +70% (Counterattack T3), Precise/Crushing Blows +10% (T3), Anatomical +25% (T3), Rend +100% (T2), Cat +20% (perk), Battle Frenzy +30% (perk), Killing Spree +25%/kill (T4), confused +25% (core) +75% Delusion (Signs T1). | Battle Frenzy +27% at 3 adrenaline (2-4 pts). That is all: Cat gives crit damage, Rend and Delusion no crit, Counterattack's crit unreachable. | **Biggest stat gap.** The port restores Cat's crit chance, Rend's, Delusion's and (D9) counters', but Precise/Crushing Blows, crossbow crit and Killing Spree have no new-tree counterpart. |
| **Crit damage** | Precise/Crushing/Anatomical +75% each (T3), Cat +80% (perk), Hunter Instinct +100% at 3 pts vs oil type (T4). | Cat +96% (1-3 pts), Hunter Instinct +60% at full adrenaline (2-4), High Tolerance +60% at ≥80% toxicity (5-7). | Comparable totals; legacy's are per attack type and late (T3), new tree's cheap. Port: Cat 80%, High Tolerance becomes Refreshment (D27). |
| **Vitality** | Survival Instinct +750 (perk), Bear +30% (perk), Endure Pain +50% overdosed (Alchemy T2), Tissue Transmutation +10 per offset pt (T2); levels +50 each. | Survival Instinct +24% (3-5), Bear +24%, Viper +24% (roots), Endure Pain +30% (2-4), Tissue Transmutation +900/decoction (4-6). | Similar; new tree more %-stacking (Bear + Viper exclusive by armor class though). Port: +750 flat (D37), Bear 30%, TT per offset point. |
| **Healing** | No base regen. Sun and Stars +10/s out of combat by day (perk), Restoration 15% per potion (T2), Active Shield. | Sun and Stars +30/s by day, alchemy_s2 30% heal per potion (**root, 1 pt**), Gourmand food regen, Active Shield. | 5.x new heals more and earlier; port: Restoration 15%, Connoisseur (D41). |
| **Damage reduction** | Protective Coating −15% (+oil level) (T2), Whirl −50% while spinning (T2), Deflection −30% on partial parries (T1), Fleet Footed −50% graze (T2), Quen 250 before armor (core). | Protective Coating 15% (3-5), Fleet-Footed −100% while dodging (4-6), Debilitating Poison −15% from poisoned enemies (4-6). | 5.x Fleet-Footed doubles legacy (port 50%); Deflection's partial-parry cut is missing (D6). |

**Timing overall.** In legacy a build's identity effects are perks (1 point, from level 1) plus T1 skills, and its capstones (Flood of Anger, Sunder Armor, Crippling Strikes, Deadly Precision, Expert Brewer, Killing Spree, Cluster Bombs, Synergy, Supercharged Glyphs, Shock Wave, the per-sign flat bonuses) need 28-30 points in one path, which is mid-to-late game and forces specialisation. In the new tree every capstone-like effect is 4-7 points from a root, while perks become 3-level (3 points to max) and chained (1-3 points to unlock). Net effect: perks get **more expensive** (×3) and skill capstones get **much cheaper** (÷4 to ÷8). The slot limit (12, same in both) becomes the only real limiter on the new tree's power.

## Removed and replaced effects

### Legacy GM vs vanilla 1.32 (does the vanilla effect survive somewhere in GM?)

| Skill / rule | Vanilla 1.32 | Legacy GM | Survives in GM? |
|---|---|---|---|
| Path passives | +1% adrenaline gain / +0.5% stamina regen / +5% potion duration per level of each equipped skill of the path | removed | adrenaline gain partly in MM/ST (+15%) and Razor Focus; potion duration only via Prolonged Effects; stamina regen only Sun and Stars (night) |
| Level-ups | attack power and sign power per level | +50 Vitality only | no |
| Strong attack `sword_2` | ignores armor, ×0.333 AP | +50% weapon damage, +200 armor pen | armor ignore only on Rend |
| Whirl ↔ Precise Blows, Rend ↔ Crushing Blows | Precise/Crushing T2, Whirl/Rend T3 | swapped | tier change only |
| Cold Blood `sword_s15` | +0.2 adrenaline per bolt (T2 Marksmanship) | Steady Shot +50 bolt damage | yes, stronger, as perk_2 (a full sword hit's adrenaline per bolt) |
| Steady Shot `perk_2` | +25% bolt damage | Cold Blood | yes, as flat +50 on sword_s15 |
| Arrow Deflection `sword_s10` | reflect arrows, +damage | Deflection: −30% partial parry/counter damage, reflect +100%, −50% parry cost vs groups; parrying arrows moved to core | yes (reflection kept) |
| Fleet Footed `sword_s9` | −100% dodge damage (20%/lvl), free dodge | −50% graze, no free dodge | reduced |
| Counterattack `sword_s11` | +AP and guaranteed crit on the next attack | +100% counter power, +70% crit, KD per adrenaline pt | reworked onto the counter itself |
| Deadly Precision `sword_s3` | 2 levels, instant kill per adrenaline pt, any attack, cooldown | 3 levels, counters only, no cooldown | partly |
| Undying `sword_s18` | heal per adrenaline pt, 30 s | 5 s immortality + regen 25%/pt, 120 s | reworked |
| Razor Focus `sword_s20` | +adrenaline gain | +gain and min 1.25 at combat start | yes |
| Flood of Anger `sword_s19` | +125% SI, drains all adrenaline | +250%, costs 3 (×3 sign cost with Rage Management) | reworked |
| Aard/Igni/Yrden/Quen/Axii Intensity | +25% intensity of that sign each | heavy KD +15%, +150 fire, +150 turret, +150 shield, +50% Axii duration | **per-sign SI removed everywhere** |
| Melt Armor `magic_s8` | stacking % armor reduction | flat −10 armor/−1% resist scaling with SI, no stacking | reworked |
| Pyromaniac `magic_s9` | +100% burn chance | +25% (base burn 33% fixed) | reduced |
| Supercharged Glyphs `magic_s11` | damage per second in trap | +25% damage taken in trap | replaced |
| Exploding Shield `magic_s13` | small damage + KD multiplier | 60 damage scaling with SI | replaced |
| Delusion `magic_s17` | stagger instead of short Axii | +45% slowdown, +75% crit vs confused | failed-Axii stagger moved to core Axii |
| Sustained Glyphs `magic_s10` | 2 levels, charges and duration (turret too) | 3 levels, duration, radius, 2nd trap, not turret | partly |
| Heightened Tolerance `alchemy_s1` | overdose threshold +25% | Refreshment: 30% stamina per potion | **no**: threshold fixed at 75% |
| Refreshment `alchemy_s2` | heal 25% per potion, 5 levels | Restoration 15%, 3 levels | reduced |
| Delayed Recovery `alchemy_s3` | potions persist above a toxicity threshold | Expert Brewer −5 toxicity per potion (T4) | no |
| Side Effects `alchemy_s4` | chance to trigger a random free potion | Prolonged Effects +100% potion duration (T3) | no |
| Adaptability `alchemy_s14` | +50% decoction duration | Adaptation −20% decoction toxicity (T3, swapped with Synergy) | **no decoction duration anywhere** |
| Protective Coating `alchemy_s5` | −25% | −15% + oil-level bonus, decays | reduced |
| Hunter Instinct `alchemy_s7` | +100% crit dmg vs oil type | +33.4% per adrenaline pt | reworked |
| Pyrotechnics, Cluster Bombs | +150; small fragment damage | +250; fragments a full bomb each | raised |
| Tissue Transmutation `alchemy_s13` | +1000 Vitality per decoction | +10 per offset point | reduced |
| Fast Metabolism `alchemy_s15` | 5/s | 1.25/s | reduced |
| Frenzy `alchemy_s16` | slowdown, 3 levels | slowdown 75%/1.5 s, 5 levels, +25% AP and SI overdosed | added AP/SI |
| Killing Spree `alchemy_s17` | +50% crit per kill | +25% | reduced |
| Sun and Stars `perk_1` | night +1/s | +5/s | raised |
| Survival Instinct `perk_4` | +500 | +750 | raised |
| Cat `perk_5` | +25% crit dmg and +5% fast AP per light piece | +5% crit chance, +20% crit dmg per piece | fast AP gone |
| Griffin `perk_6` | +5% SI, +5% stamina regen per medium piece | +5% SI, −5% sign cost | regen gone |
| Bear `perk_7` | +5% Vitality, +5% strong AP per heavy piece | +7.5% Vitality, +0.025 adrenaline per hit per piece | strong AP gone |
| Rage Management `perk_9` | adrenaline only when Stamina is too low | adrenaline first | reworked |
| Adrenaline Burst `perk_10` | +5% gain, signs generate adrenaline | +5% gain, −10% melee cost per adrenaline pt | sign adrenaline moved to Focus |
| Focus `perk_11` | +10% SI per adrenaline pt | +15%, signs generate adrenaline | raised |
| Metabolic Control `perk_12` | +30 | +40 | raised |
| Battle Frenzy `perk_19` | +8% crit per pt | +10% | raised |
| Strong Back `perk_22` | +60 | +40 | reduced |
| Gourmet `perk_15` | food regen 20 min | Connoisseur: alcohol and raw food toxicity 0, no drunkenness, +100% alcohol duration | **food regen gone** (with base regen 0) |
| In Combat's Fires `perk_16` | ignore own bomb/bolt effects | also own bomb/bolt damage −50% (GM removed vanilla's default 50% self-damage cut) | yes |
| Heavy Artillery `perk_20` | ×3 bomb damage | +100% | reduced |
| Advanced Pyrotechnics `perk_18` | 0.1 adrenaline per bomb hit | same, not raised by bonuses, split among fragments | yes |
| Attack is the Best Defense `perk_21` | adrenaline from parry 0.1, counter 0.4, dodge 0.3, roll 0.2 (5 s CD) | stamina: 15% on kill, 5% on crit/counter (2.5 s CD) | **defensive adrenaline gone** |

### 5.x new-tree skills whose legacy counterpart's key stat effect is missing

| New-tree skill | Legacy counterpart | Missing stat effect | Port |
|---|---|---|---|
| `sword_s22` Muscle Memory, `sword_s23` Strength Training | sword_s21, sword_s4 | +15% adrenaline gain; unconditional +25% AP | D1 adds the gain; flat AP not added |
| `sword_s29` Crippling Strike | sword_s5 | bleeding chance, +25% vs bleeding | D2 keeps 5.x |
| `sword_s28` Sunder Armor | sword_s6 | permanent −25% resist (now 3 stacks, 3-6 s) | 5.x kept |
| `sword_s33` Arrow Deflection | sword_s10 Deflection | partial-parry/counter damage cut, −50% parry cost | D6 adds them |
| `sword_s31` Counterattack | sword_s11 | +70% crit on counters (unreachable in 5.x), KD per adrenaline pt | D9 |
| `sword_s30` Deadly Precision | sword_s3 | instant kill per adrenaline pt on counters | D11 |
| `sword_s34` Cold Blood | perk_2 | adrenaline equal to a sword hit, damage-dealt only (5.x: fixed 1 pt) | D13 |
| `sword_s26` Anatomical Knowledge | sword_s7 | +25% crossbow crit chance, +75% crit damage | D14 keeps 5.x |
| (none) | sword_s15 Steady Shot, perk_17 Trick Shot | flat bolt damage, extra bolt | none |
| `magic_s33` Shockwave | magic_s6 | 300 damage scaling with SI | D20 |
| `magic_s31` Puppetmaster | magic_s5 | 20 s, +100% AP | D24 |
| `magic_s38` Focus | perk_11 | signs generate adrenaline (5.x puts it on perk_42) | D40 |
| (none) | Aard/Igni/Yrden/Quen/Axii Intensity, Pyromaniac, Quen Discharge | heavy KD, +150 flat damage/absorption, Axii duration, burn chance, reflection | none (classic only) |
| `alchemy_s24` High Tolerance | alchemy_s1 Refreshment | 30% stamina per potion | D27 |
| `alchemy_s27` Hunter Instinct | alchemy_s7 | crit damage per adrenaline pt (5.x: only at full) | D30 |
| shared `alchemy_s3`, `s4`, `s14` (5.x Delayed Recovery, Side Effects, Adaptability) | Expert Brewer, Prolonged Effects, Adaptation | −5 potion toxicity, +100% potion duration, −20% decoction toxicity | replaced in both trees (D29) |
| (none) | alchemy_s17 Killing Spree | crit chance per kill | none |
| (none) | alchemy_s6 Fixative, alchemy_s9 Steady Aim, alchemy_s19 Synergy (perk_43 is the counterpart, +30% vs +50%) | oil charges, bomb aim slowdown | none |
| `perk_23` Cat | perk_5 | crit chance per light piece | replaced by legacy |
| `perk_24` Griffin | perk_6 | sign cost reduction | replaced by legacy |
| `perk_25` Bear | perk_7 | adrenaline per hit | replaced by legacy |
| `perk_34` Anger Management | perk_9 Rage Management | adrenaline first | adrenaline-first |
| `perk_42` Adrenaline Burst | perk_10 | melee cost per adrenaline pt | added |
| `perk_31` Attack is the Best Defense | perk_21 | stamina restoration | replaced by legacy |
| `perk_30` Survival Instinct | perk_4 | flat +750 | D37 |
| `perk_39` Advanced Pyrotechnics | perk_18 | adrenaline from bombs | 5.x kept: **gap stays** |
| `perk_41` Gourmand | perk_15 Connoisseur | alcohol/raw-food toxicity removal | D41 |
| (none) | perk_20 Heavy Artillery, perk_16 In Combat's Fires, perk_14 Gorged on Power | ×2 bomb damage, own-bomb damage cut, Place of Power | none (D39 for own bombs) |

## Cornerstones

Effects legacy GM builds hinge on regardless of level, with their new-tree counterpart. Cost in the new tree = unlock/max points in its grid.

| Cornerstone (legacy) | Cost in GM | Drives | New-tree counterpart | Cost in new | Counterpart after port |
|---|---|---|---|---|---|
| Adrenaline Burst `perk_10` | perk, 1 pt | −30% melee stamina at 3 adrenaline, +5% gain | `perk_42` (+6%, sign adrenaline, **no cost cut**) | 2/4 | cost cut added (−10%/pt at L3) |
| Attack is the Best Defense `perk_21` | perk, 1 pt | stamina refund on kills, crits, counters | `perk_31` gives **adrenaline** instead | 2/4 | legacy stamina rule |
| Cat School `perk_5` | perk, 1 pt | +20% crit chance, +80% crit dmg (4 light pieces) | `perk_23` crit dmg 96%, fast +24%, **no crit chance** | 1/3 | legacy values at L3 |
| Griffin School `perk_6` | perk, 1 pt | +20% SI, −20% sign cost | `perk_24` +24% SI, ~+2.4 Stamina/s (+ Wolf `perk_26` +24% SI) | 1/3 | legacy values; Wolf stays |
| Bear School `perk_7` | perk, 1 pt | +30% Vitality, +0.1 adrenaline/hit | `perk_25` +24% Vitality, +24% strong dmg | 1/3 | legacy values |
| Cold Blood `perk_2` | perk, 1 pt | crossbow builds' adrenaline | `sword_s34` 1 pt per bolt | 2/4 (Sword grid) | D13: legacy rule |
| Trick Shot `perk_17` | perk, 1 pt | crossbow DPS | **none** | - | none |
| Rage Management `perk_9` | perk, 1 pt | sign builds cast on adrenaline first (with Flood of Anger ×3, Focus) | `perk_34` Anger Management, only when Stamina is empty | 2/4 | adrenaline-first |
| Focus `perk_11` | perk, 1 pt | +45% SI at 3 adrenaline; signs generate adrenaline | `magic_s38` +90% SI, no sign adrenaline | 5/7 (deep in Signs grid) | 45% at L3 + sign adrenaline (D40) |
| Battle Frenzy `perk_19` | perk, 1 pt | crit builds (+30% at 3 adrenaline) | `perk_40` +27% | 2/4 | 30% at L3 |
| Heavy Artillery `perk_20` | perk, 1 pt | bomb builds (×2) | **none** | - | none |
| Muscle Memory / Strength Training | T1, 5 pts | flat AP (+25%, played +50%) and +15% adrenaline gain | `sword_s22`/`s23` combo bonuses | 1/3, 2/4 | D1 gain only; flat AP gone |
| Resolve `sword_s16` | T1, 5 pts | keeps adrenaline (GM loses it on damage) | shared | 2/4 | same |
| Undying `sword_s18` | T2, 8+5 | survival on adrenaline (5 s immortality) | shared, 5.x instant heal 30 s | 3/5 | D15 legacy |
| Rend `sword_s2` | T2, 8+5 | adrenaline dump, +100% crit, shock wave | shared, 5.x version | 4/6 | legacy formula |
| Whirl `sword_s1` | T2, 8+5 | crowd damage, −50% damage taken | `sword_s35` (same code) | 5/7 | legacy numbers |
| Razor Focus `sword_s20` | T3, 20+5 | combat-start adrenaline (1.25), +25% gain | shared | 3/5 | 1.25 start, +30% gain |
| Counterattack `sword_s11` | T3, 20+3 | counter crit 100%, +100% power | `sword_s31` after counter or dodge | 4/6 | D9 |
| Flood of Anger `sword_s19` | T4, 30+5 | +250% SI nuke | shared, supercharged +150% | 5/7 | +250% (D16) |
| Hunter Instinct `alchemy_s7` | T4, 28+5 | crit dmg per adrenaline pt | `alchemy_s27` full adrenaline + right oil | 2/4 | D30 |
| Frenzy `alchemy_s16` | Alchemy T1, 5 | overdose builds: +25% AP and SI | shared, slowdown only | 1/3 (root) | +25% AP/SI overdosed |
| Endure Pain `alchemy_s20` | T2, 8+5 | overdose builds: +50% Vitality | shared +30% | 2/4 | D34 +30% |
| Acquired Tolerance + Metabolic Control | T1 / perk | toxicity room for potion builds (+150, +40) | shared `alchemy_s18`, `perk_33` | 3/5, 2/4 | +1/formula (D33), +40 |
| Prolonged Effects `alchemy_s4` | T3, 20+5 | potion uptime +100% | **none** in 5.x (Side Effects) | 7/9 | Prolonged Effects on s4 (much earlier) |
| Refreshment `alchemy_s1` | T1, 3 | 30% stamina per potion | **none** (`alchemy_s24` slot) | 5/7 | D27 |
| Pyrotechnics + Cluster Bombs | T2 / T4 | bomb damage | shared | 2/4, 5/7 | 250; D31 |
| Quen (core) + Active Shield `magic_s4` | core / T2 | pre-armor absorption, heal 100% | shared | 2/4 | legacy rework |

## Biggest gaps (one line each)

1. **Crit chance:** the new tree has one native source (Battle Frenzy); after port Cat, Rend, Delusion and counters restore some, but Precise/Crushing Blows, crossbow crit and Killing Spree have no new-tree home.
2. **Timing inversion:** legacy capstones need 28-30 path points; new-tree equivalents (Flood of Anger, Sunder, Expert Brewer, Prolonged Effects, Fast Metabolism, Crippling Strike) cost 4-7, while perks cost 3 points instead of 1.
3. **Stamina economy:** 5.x new has no melee or general sign cost reduction and no stamina restore (Adrenaline Burst, Griffin, AitBD, Refreshment); the port re-adds them (Refreshment pending D27).
4. **Adrenaline:** 5.x new's Cold Blood (1 pt/bolt) and AitBD (defensive adrenaline) far exceed legacy and are neutralised by decisions; the bomb-adrenaline source (Advanced Pyrotechnics) is missing from the new tree.
5. **Missing perks and flat effects:** Heavy Artillery, Trick Shot, Steady Shot (flat bolt damage), the per-sign Intensity flat bonuses, Pyromaniac and Quen Discharge exist only in the classic tree; sign intensity in the new tree can go far higher than legacy through Wolf, Catalyst and Chain Reaction, which the port keeps.
