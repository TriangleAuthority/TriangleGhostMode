# Player power and balance

How the port keeps Ghost Mode's **player-power economy** while it ports and re-balances skills, perks, mutations, potions, decoctions and gear for 5.x. This page holds the big picture, so that a single skill decision is never made in isolation. It governs SKL and MUT, and the balance parts of ALCH, ARM, ENCH and XP.

| Doc | What it holds |
|---|---|
| This page | The rules (B1–B10), the two-tree plan, the archetypes, the cross-area links and the checklist every balance-relevant change goes through |
| [ledger/](ledger/README.md) | The reference data: every source of every power stat in legacy Ghost Mode and in 5.x, when it becomes available, the effects legacy removed or replaced, the cornerstones (from the code, unverified) |
| [../skill-trees/](../skill-trees/) | The full trees at max level: [legacy](../skill-trees/legacy-skill-tree.html), [5.x](../skill-trees/5x-skill-trees.html); the SKL decisions side by side in [skl-decisions.md](../skill-trees/skl-decisions.md) |
| [skl.md](skl.md), `mut.md`, `alch.md` | The feature entries: what each skill, mutation, potion does and how it is ported |

Detailed notes (investigations, per-decision reasoning, verification) go into Mnemosyne with the tags `TriangleGhostMode`, `balance` and the feature ID.

## Rules

Set by the project owner on 2026-10-05. Every balance-relevant decision names the rules it applies. A decision that departs from one is recorded as a deviation.

| # | Rule | In practice |
|---|---|---|
| B1 | **Keep legacy's power economy** | What a build can reach, and when it reaches it, stays close to legacy Ghost Mode. Legacy made player power come only from sources the player chooses. A level-up gives +50 Vitality and nothing else. The path passives are removed. Base Vitality regen is 0. Stamina regen is a flat 15/s. |
| B2 | **The hard-to-scale stats come first** | Adrenaline (gain, retention, per-point effects), stamina (regen, restoration, cost cuts), toxicity (maximum, reduction), potion duration (and decoction duration). Every source of these is tracked in the [ledger](ledger/README.md), and a change that adds, removes or moves one needs the owner's decision. |
| B3 | **The other power stats keep their timing** | Attack power, sign intensity, bomb damage, crossbow damage, crit chance and damage, Vitality, armor and resistances may come from different skills or mutations than in legacy (there is plenty of room). Front-loaded stays front-loaded and back-loaded stays back-loaded: an effect legacy gives at tier 1 should not land in a capstone, nor a legacy capstone at the root of a grid. |
| B4 | **Replaced effects are replaced again** | Where legacy removed or replaced an effect entirely (Heightened Tolerance → Refreshment, Side Effects → Prolonged Effects, per-sign intensity → flat bonuses, ...), the port does the same, or gives the stats legacy gave instead, so scaling stays similar. The list is in the ledger's [removed and replaced effects](ledger/skills.md#removed-and-replaced-effects). |
| B5 | **A different mechanism is fine, judged by its effective power** | A 5.x skill that scales the same stat in a more interesting way (Muscle Memory's and Strength Training's combo damage) may stay, if its effective power matches legacy's reach and timing. Effective power counts how easily and how often the effect triggers, not only its number. Legacy's Muscle Memory is a constant flat bonus; 5.x's applies only after a dodge or roll, so a conditional effect may need a larger number to match a constant one, and an easy, always-on trigger may need a smaller one. |
| B6 | **General perks are cornerstones** | In legacy, perks cost 1 point, are available from level 1 and define builds: Adrenaline Burst and Attack is the Best Defense carry melee stamina, the school techniques carry stamina, adrenaline, crit and intensity, and Cold Blood and Trick Shot carry crossbow builds. Perks get the same scrutiny as tier-4 skills. In the port (SKL's D49) every general perk with a legacy counterpart is legacy's perk in both trees: 1 point, 1 level, legacy's effect and full value; the only general perk without a legacy counterpart is the redesigned Wolf School (D61), also 1 point and 1 level. |
| B7 | **Signs resemble legacy closely** | Signs are overpowered in both vanillas. Sign skills keep legacy's values and mechanisms unless the owner decides otherwise, and new sign-intensity sources in 5.x are suspect by default. |
| B8 | **Every archetype stays viable** | See [Archetypes](#archetypes). A change is checked against every archetype it touches, and synergies are tracked as well as single skills. |
| B9 | **Alchemy effects stay where they are** | An effect is never moved between potions or decoctions just to fill a gap, because each one becomes available at a different time. Potions and decoctions are ported in ALCH, but SKL balances knowing what they give (ledger, [potions and decoctions](ledger/alchemy.md)). |
| B10 | **Both trees use legacy's tiers** | The new tree drops 5.x's prerequisite tree (project owner, 2026-10-09, SKL's D59): its skills are gated by points spent in their path, at their legacy counterpart's tier, with the tier points scaled to its 3 levels (×3/5: sword 5/12/18, alchemy 5/12/17, signs 4/11/17). The classic tree uses legacy's levels and tier points (sword 8/20/30, alchemy 8/20/28, signs 6/18/28). Ported 2026-10-16 ([SKL-02](skl.md#skl-02-skill-tree-option)); the general skills have no gate. The new tree's levels and tier points stay as decided; their pace is examined with XP's skill-point income (P10), not before (porter's call, not confirmed by the owner, 2026-10-16). |

## Two skill trees: the plan

Set by the project owner (the separation and the classic tree 2026-10-05; the new tree's content 2026-10-09 to 2026-10-11).

1. **The trees are separated.** The 28 skills 5.x shares between the trees stop being shared: each tree gets its own values, levels, layout and descriptions.
2. **The classic tree becomes legacy Ghost Mode's tree**, ported directly: legacy's skills, values, maximum levels (mostly 5), layout and descriptions. It is the faithful Ghost Mode and the default tree (D46).
3. **The new tree carries legacy's skills on 3 levels.** Each new-tree skill is its legacy counterpart under legacy's name, with legacy's max-level total at level 3 (a third per level), gated by legacy's tiers scaled ×3/5 (B10); 5.x's new-only skills and perks give their slots to the legacy skills and perks that had none (SKL's D58, D60, D61). General perks (D49): every general perk with a legacy counterpart is legacy's perk in both trees: 1 point, 1 level, legacy's effect and full value; the only general perk without a legacy counterpart is the redesigned Wolf School (D61), also 1 point and 1 level. A few parts are new designs by the project owner, not deviations from legacy: Muscle Memory, Precise Blows, Strength Training, Crushing Blows, Cold Blood carrying Steady Shot's damage, Wolf School, the 3 levels with scaled tier points, and the skill-point income rule for the XP area ([list](skl.md#new-designs)). The new tree does not affect the classic tree.

**How (from the code, unverified; research 2026-10-05).** Every skill stays one definition, with a per-tree *profile* applied at runtime:
- **Definition fields.** A Ghost Mode definitions block (`GMClassicSkills`) holds legacy's fields (max level, tier points, position, string keys, no new-tree prerequisites). Applied over the skill table when the classic tree is active, it also clears the shared flag so tier points gate the skill.
- **Values.** In the classic tree, the 28 formerly shared skills read their values from Ghost Mode abilities `GM_C_<skill>`, through wrappers of `SkillEnumToName` and `SkillNameToEnum`. The new tree keeps the vanilla ability names, with Ghost Mode's values.
- **Switching trees** is not a normal workflow (project owner, 2026-10-05). It goes through Ghost Mode's character reset (D44, below), then the other profile applies.
- **Tier gates in the new tree** (B10, SKL's D59): the block `GMNewTreeSkills` holds the scaled tier points and a tier layout, the profile clears 5.x's prerequisites, and wrappers of `CanLearnSkill` and `IsSkillUnlockedByDependency` gate by tier (5.x checks `requiredPointsSpent` only for classic-only skills). Verified 2026-10-16 ([SKL-02](skl.md#skl-02-skill-tree-option) slice 3).

There are no new skill enum values and no native changes. As a side effect, this fixes 5.x's classic tree, where some shared skills are locked behind new-tree prerequisites the classic menu does not show (Razor Focus, and through it Rend). The first slice proves it with Rend and Whirl:
- the profile is found and applied;
- five levels can be bought;
- the menu draws five level pips (verified in the new menu, which shows the classic tree, [SKL-02](skl.md#skl-02-skill-tree-option));
- the `GM_C_` value is read;
- everything survives a reload;
- switching back restores the new tree's Rend (3 levels) with points refunded.

**Character reset** (D44, project owner, 2026-10-05). A safe console command that resets Geralt's development so it can be rebuilt at the same level under whatever rules are now in force: a tree switch, a changed skill or progression rule, another mod added mid-game, a test. It is part of the mod, not test-only. By default it:
- refunds every skill point, including those not from level-ups (places of power and the like);
- refunds mutation research (skill points and greater mutagens);
- resets skills and skill slots;
- keeps Geralt's level, experience and inventory.

Legacy has the base for it: `Debug_ClearCharacterDevelopment` was rebuilt into a respec that keeps level, experience and total skill points, refunds the mutagens, clears toxicity and oils, and unequips gear. 5.x's `cleardevelop` is far harsher: it resets the level, empties the inventory unless told not to, and hands out testing items. It is ported as the console command `gmreset()`, built on 5.x's own respec ([SKL-01](skl.md#skl-01-skill-system-rules), verified 2026-10-11); it leaves gear and oils alone and is refused in combat. The tree profile and Ghost Mode's own saved state join it as they are ported. Skill tests start from a reset, so they run on a clean character.

**What it means for SKL** (the per-skill pass is complete, 2026-10-11; [skl.md](skl.md#area-decisions)):
- The classic tree's port is legacy's numbers.
- The new tree's port is legacy's numbers at a third per level on legacy's tiers, plus the new designs above. Every skill and perk was decided one by one, against the ledger and these rules.
- Order: DMG came first (the damage and armor formula decides what every bonus is worth; signed off 2026-10-07); then (1) the character reset and the separation slice; (2) the trees branch by branch, the classic skill as legacy with its new-tree counterpart; the new tree's levels and tier points are revisited with XP's skill-point income (D59). SKL was signed off 2026-10-17.

**Decided** (project owner, 2026-10-05): the classic tree uses legacy's tier points (8/20/28–30; Signs 6/18/28), and it is the default tree (D46). The new tree uses the same tiers scaled to its 3 levels (B10, 2026-10-09).

## Archetypes

The builds legacy supports and that must stay viable (B8). Cornerstones are listed in the [ledger](ledger/skills.md#cornerstones). This table records what each archetype depends on, where 5.x's new tree stands, and where the port's new tree stands with SKL's decisions (2026-10-11); the classic tree is legacy's.

| Archetype | Legacy cornerstones | Hard stats it lives on | New tree in vanilla 5.x | New tree after the port |
|---|---|---|---|---|
| Quick melee, light armor | Muscle Memory, Precise Blows, Crippling Strikes, Cat School (crit chance and damage), Adrenaline Burst (melee cost), Attack is the Best Defense (stamina back), Battle Frenzy, Fleet Footed; Cat set | Stamina (cost cuts, restoration), adrenaline gain | No melee cost cut, no stamina restoration, almost no crit chance; Cat gives crit damage only | As legacy: Cat, Adrenaline Burst, Attack is the Best Defense, Battle Frenzy, Fleet Footed, Crippling Strikes. Muscle Memory (conditional attack power) and Precise Blows (crit chain) by new design |
| Heavy armor, adrenaline | Strength Training, Rend, Bear School (adrenaline per hit, Vitality), Resolve, Undying, Razor Focus, Battle Trance; Bear set | Adrenaline gain and retention, Vitality | Bear gives strong-attack damage instead of adrenaline; Razor Focus at 3 points instead of 25 | As legacy: Bear, Resolve, Undying, Rend, Razor Focus at tier 3. Strength Training's stacks and Crushing Blows's crit chain by new design |
| Signs | Griffin School (intensity, sign cost), Focus (intensity per adrenaline point, signs give adrenaline), Rage Management (adrenaline first), Flood of Anger, the per-sign skills; Griffin set; Petri's Philtre | Sign cost, adrenaline, sign intensity | Sign intensity can reach far above legacy (Wolf, Catalyst, Chain Reaction, Focus 90%); no general sign cost cut; no per-sign flat skills | As legacy: Griffin, Focus on `perk_37`, Rage Management, Flood of Anger, the per-sign skills (D58); none of 5.x's extra intensity. Flood of Anger casts as legacy |
| Bombs | Pyrotechnics, Efficiency, Cluster Bombs, Heavy Artillery, Advanced Pyrotechnics (adrenaline from bombs), Steady Aim | Adrenaline from bombs, toxicity room | No Heavy Artillery, no adrenaline from bombs | As legacy: Heavy Artillery `perk_28`, legacy's Advanced Pyrotechnics, Steady Aim `alchemy_s23`; plus Wolf School's link between bombs, poison and sword crits (new design) |
| Crossbow | Steady Shot (flat bolt damage), Anatomical Knowledge, Cold Blood (bolt adrenaline), Trick Shot, Lightning Reflexes | Adrenaline from bolts | 5.x's Cold Blood gives far more adrenaline; no flat bolt damage, no Trick Shot, no crossbow crit | As legacy, with Steady Shot's damage on Cold Blood (`sword_s34`, tier 2) and Trick Shot on `perk_27`. Revisited when balancing |
| Alchemy, potions | Refreshment (stamina per potion), Prolonged Effects, Expert Brewer, Acquired Tolerance, Metabolic Control, Fast Metabolism, Restoration | Potion duration, toxicity, stamina | No potion-duration skill, no Refreshment; the replacements land far earlier than legacy's tier 3–4 | As legacy, at legacy's tiers: Refreshment on `alchemy_s24`, Prolonged Effects, Expert Brewer, Metabolism Boosts |
| Overdose / mutagens | Frenzy (attack power and intensity while overdosed), Endure Pain, Tissue Transmutation, Adaptation, Synergy; the decoctions | Toxicity room and threshold | 5.x's overdose threshold is 50% (ALCH); decoction duration exists again (Adaptability) | As legacy: Adaptation, Synergy on `alchemy_s26`, Killing Spree on `alchemy_s22`. The overdose threshold is ALCH's |
| Hybrids (combat/signs, combat/alchemy, signs/alchemy) | Perk-driven: a few cheap perks plus tier-1/2 skills from two paths | Whatever both sides need | Perks cost 3 points and are chained; capstones cost 4–7 points: hybrids reach capstones far sooner | Perks cost 1 point with 1 level (D49); skills follow legacy's tiers scaled to 3 levels (D59) |

**Key synergies in legacy** (from the [ledger](ledger/README.md); a change to one piece is checked against the whole chain):

- **Light melee stamina loop.** Light armor (−30% melee cost), Adrenaline Burst (−10% melee cost per adrenaline point), Attack is the Best Defense (stamina back on kills, crits and counters), Cat School and the Feline set (crit chance, so more refunds; crits double adrenaline at 6 pieces).
- **Heavy adrenaline engine.** Bear set (large adrenaline gain, adrenaline when hit, strong attacks refund stamina at 6 pieces), Bear School (+0.1 adrenaline per hit per piece), Resolve (no loss), Razor Focus (start at 1.25), Battle Trance, Rend and Undying as the ways to spend it; Bloodbath and Adrenaline Rush late.
- **Sign economy.** Griffin set (−30% to all costs for 2.5 s after a sign), Griffin School (−5% sign cost and +5% intensity per piece), Rage Management (adrenaline first), Focus (signs give adrenaline, intensity per point), Flood of Anger; Magic Sensibilities late; Petri's Philtre.
- **Crossbow.** Cold Blood (a sword hit's adrenaline per bolt), Steady Shot, Anatomical Knowledge, Trick Shot, Lightning Reflexes; Cat Eyes late. The non-aimed −50% rule shapes it.
- **Bombs.** Pyrotechnics, Efficiency, Cluster Bombs, Heavy Artillery, Advanced Pyrotechnics (adrenaline per bomb), Manticore set; the non-aimed −50% rule.
- **Overdose.** Acquired Tolerance, Metabolic Control and the Arachas trophy (room), Frenzy and Endure Pain (rewards while overdosed), Adaptation and Synergy (decoctions), Euphoria and Metamorphosis late. Every piece moves with the overdose threshold (ALCH).

## Cross-area links

| Area | What SKL balancing must know |
|---|---|
| ALCH | Potions and decoctions are a large part of every build's power. Legacy reworked 22 of 28 decoction effects and moved several stat roles to other monsters (B9). The toxicity threshold (legacy 75% fixed, 5.x 50%) moves every "while overdosed" skill. Summary: [ledger](ledger/alchemy.md). |
| MUT | Mutations are late-game power and unlock skill slots: [MUT](#mutations) and the ledger. |
| ARM | Set bonuses and armor classes feed the school perks and archetypes: [ledger](ledger/gear.md). |
| ENCH | Runewords and glyphwords scale sign and melee builds; they hook into skill functions. |
| DMG | The damage formula decides what attack power and intensity are worth (P1); legacy's additive bonus pool (D4: settled by DMG's [DD1](dmg.md#area-decisions), 5.x's multipliers join the pool). |
| XP | How fast points arrive (P10, B10). |

## Mutations

Blood and Wine's late-game progression: research with skill points and mutagens, one active mutation, and extra skill slots. Mapped as the MUT area ([mut.md](mut.md)); what each mutation scales and costs is in the [ledger](ledger/mutations.md), and the mutations at base stats in both tree files. Ghost Mode's cornerstones: Magic Sensibilities (Signs), Bloodbath (sword), Euphoria (alchemy); Adrenaline Rush, Mutated Skin, Deadly Counter and Life Leech run on adrenaline. The mutations are legacy Ghost Mode's in both trees, research costs included (legacy's 29 skill points; MUT's DM1, project owner, 2026-10-11; [how](mut.md#mutations-in-two-trees)). They ported after SKL; MUT was signed off 2026-10-17.

## How a balance-relevant change is made

For every skill, perk, mutation, potion or gear decision, before it is proposed:

1. **Ledger rows.** Which stats does it add, remove or move, and by how much at max level? Does it touch a hard stat (B2)?
2. **Timing and uptime.** At which tier or point cost does it arrive, compared with legacy (B3)? How easily and how often does it trigger, compared with the legacy effect it stands in for (B5)?
3. **Archetypes.** Which archetypes and synergies does it touch, and are they still viable (B8)?
4. **Replaced effects.** Does it restore or lose something legacy replaced (B4)?
5. **Signs and perks.** Extra scrutiny (B6, B7).
6. **Record.** The decision in the feature entry with the rules it applies, any deviation as a deviation, the ledger and the archetype table updated, and a Mnemosyne note with the reasoning.

## Open questions

- Where legacy's code and its changelist disagree (contradictions and omissions): [open-questions.md](../open-questions.md#legacy-data-vs-changelist).
- What a Flood of Anger cast means for signs that outlast it and for Piercing Cold (5.x's supercharged-sign extras, MUT's DM3): as legacy (project owner, 2026-10-11), to check against legacy's code when implemented.
- SKL's D45: decided as one SKL-19 pass (porter's call, not confirmed by the owner, 2026-10-16). D43 is decided: the slot fixes are SKL-01's (project owner, 2026-10-16).
- The new tree's levels and tier points (B10): kept; examined with XP's skill-point income (P10).
- To revisit when balancing (project owner, 2026-10-09): enable a poison build, and create more synergy between bombs and other builds; 5.x's new-only skills dropped by SKL's D60 are the starting material.
