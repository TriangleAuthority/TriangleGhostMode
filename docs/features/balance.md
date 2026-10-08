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
| B6 | **General perks are cornerstones** | In legacy, perks cost 1 point, are available from level 1 and define builds: Adrenaline Burst and Attack is the Best Defense carry melee stamina, the school techniques carry stamina, adrenaline, crit and intensity, and Cold Blood and Trick Shot carry crossbow builds. Perks get the same scrutiny as tier-4 skills. |
| B7 | **Signs resemble legacy closely** | Signs are overpowered in both vanillas. Sign skills keep legacy's values and mechanisms unless the owner decides otherwise, and new sign-intensity sources in 5.x are suspect by default. |
| B8 | **Every archetype stays viable** | See [Archetypes](#archetypes). A change is checked against every archetype it touches, and synergies are tracked as well as single skills. |
| B9 | **Alchemy effects stay where they are** | An effect is never moved between potions or decoctions just to fill a gap, because each one becomes available at a different time. Potions and decoctions are ported in ALCH, but SKL balances knowing what they give (ledger, [potions and decoctions](ledger/alchemy.md)). |
| B10 | **5.x's faster skill buying is accepted for now** | In the new tree, skills cost about a third fewer points than in legacy. That is accepted for now; the pace is examined with XP (P10). The classic tree uses legacy's levels and tier points. |

## Two skill trees: the plan

Direction set by the project owner on 2026-10-05. It replaces the decision of 2026-10-03 to keep 5.x's changes to the classic tree and the 5/3 rule of 2026-10-04 for that tree.

1. **The trees are separated.** The 28 skills 5.x shares between the trees stop being shared: each tree gets its own values, levels, layout and descriptions.
2. **The classic tree becomes legacy Ghost Mode's tree**, ported directly: legacy's skills, values, maximum levels (mostly 5), layout and descriptions. It is the faithful Ghost Mode and the candidate for the default (D46).
3. **The new tree becomes Ghost Mode's experimental tree.** It is changed freely, guided by these rules and the ledger, and balanced over time. It does not affect the classic tree.

**How (from the code, unverified; research 2026-10-05).** Every skill stays one definition, with a per-tree *profile* applied at runtime:
- **Definition fields.** A Ghost Mode definitions block (`GMClassicSkills`) holds legacy's fields (max level, tier points, position, string keys, no new-tree prerequisites). Applied over the skill table when the classic tree is active, it also clears the shared flag so tier points gate the skill.
- **Values.** In the classic tree, the 28 formerly shared skills read their values from Ghost Mode abilities `GM_C_<skill>`, through wrappers of `SkillEnumToName` and `SkillNameToEnum`. The new tree keeps the vanilla ability names, which Ghost Mode then changes freely.
- **Switching trees** is not a normal workflow (project owner, 2026-10-05). It goes through Ghost Mode's character reset (D44, below), then the other profile applies.

There are no new skill enum values and no native changes. As a side effect, this fixes 5.x's classic tree, where some shared skills are locked behind new-tree prerequisites the classic menu does not show (Razor Focus, and through it Rend). The first slice proves it with Rend and Whirl:
- the profile is found and applied;
- five levels can be bought;
- the classic menu draws five level pips (the one thing only the game can show);
- the `GM_C_` value is read;
- everything survives a reload;
- switching back restores 5.x's Rend with points refunded.

**Character reset** (D44, project owner, 2026-10-05). A safe console command that resets Geralt's development so it can be rebuilt at the same level under whatever rules are now in force: a tree switch, a changed skill or progression rule, another mod added mid-game, a test. It is part of the mod, not test-only. By default it:
- refunds every skill point, including those not from level-ups (places of power and the like);
- refunds mutation research (skill points and greater mutagens);
- resets skills and skill slots;
- keeps Geralt's level, experience and inventory.

Legacy has the base for it: `Debug_ClearCharacterDevelopment` was rebuilt into a respec that keeps level, experience and total skill points, refunds the mutagens, clears toxicity and oils, and unequips gear. 5.x's `cleardevelop` is far harsher: it resets the level, empties the inventory unless told not to, and hands out testing items. What the reset must also cover on 5.x (5.x's point bookkeeping, the tree profile, Ghost Mode's own saved state) is worked out when it is ported, with SKL-01. Skill tests start from a reset, so they run on a clean character.

**What it changes in SKL:**
- The classic tree's port is legacy's numbers. Most of SKL's decisions for the classic tree become "as legacy", and the 5/3 rescaling no longer applies to it.
- The new tree's decisions (the new-tree counterparts, and D1, D2, D6, D9, D11, D13, D14, D20, D23–D24, D27, D30, D37, D40–D41) move to a second phase. They are made against the ledger's gaps rather than one by one.
- Order: DMG first (the damage and armor formula decides what every bonus is worth; decision 2026-10-06), then (1) the character reset and the separation slice; (2) the classic tree, branch by branch, as legacy; (3) the new tree, phase 2, with this page's checklist.

**Decided** (project owner, 2026-10-05): the classic tree uses legacy's tier points (8/20/28–30; Signs 6/18/28), and it is the default tree (D46). B10's faster skill buying therefore applies only to the new tree.

## Archetypes

The builds legacy supports and that must stay viable (B8). Cornerstones are listed in the [ledger](ledger/skills.md#cornerstones). This table records what each archetype depends on and where the new tree stands. It is updated as decisions are made.

| Archetype | Legacy cornerstones | Hard stats it lives on | New tree today (5.x) |
|---|---|---|---|
| Quick melee, light armor | Muscle Memory, Precise Blows, Crippling Strikes, Cat School (crit chance and damage), Adrenaline Burst (melee cost), Attack is the Best Defense (stamina back), Battle Frenzy, Fleet Footed; Cat set | Stamina (cost cuts, restoration), adrenaline gain | No melee cost cut, no stamina restoration, almost no crit chance; Cat gives crit damage only |
| Heavy armor, adrenaline | Strength Training, Rend, Bear School (adrenaline per hit, Vitality), Resolve, Undying, Razor Focus, Battle Trance; Bear set | Adrenaline gain and retention, Vitality | Bear gives strong-attack damage instead of adrenaline; Razor Focus at 3 points instead of 25 |
| Signs | Griffin School (intensity, sign cost), Focus (intensity per adrenaline point, signs give adrenaline), Rage Management (adrenaline first), Flood of Anger, the per-sign skills; Griffin set; Petri's Philtre | Sign cost, adrenaline, sign intensity | Sign intensity can reach far above legacy (Wolf, Catalyst, Chain Reaction, Focus 90%); no general sign cost cut; no per-sign flat skills |
| Bombs | Pyrotechnics, Efficiency, Cluster Bombs, Heavy Artillery, Advanced Pyrotechnics (adrenaline from bombs), Steady Aim | Adrenaline from bombs, toxicity room | No Heavy Artillery, no adrenaline from bombs |
| Crossbow | Steady Shot (flat bolt damage), Anatomical Knowledge, Cold Blood (bolt adrenaline), Trick Shot, Lightning Reflexes | Adrenaline from bolts | 5.x's Cold Blood gives far more adrenaline; no flat bolt damage, no Trick Shot, no crossbow crit |
| Alchemy, potions | Refreshment (stamina per potion), Prolonged Effects, Expert Brewer, Acquired Tolerance, Metabolic Control, Fast Metabolism, Restoration | Potion duration, toxicity, stamina | No potion-duration skill, no Refreshment; the replacements land far earlier than legacy's tier 3–4 |
| Overdose / mutagens | Frenzy (attack power and intensity while overdosed), Endure Pain, Tissue Transmutation, Adaptation, Synergy; the decoctions | Toxicity room and threshold | 5.x's overdose threshold is 50% (ALCH); decoction duration exists again (Adaptability) |
| Hybrids (combat/signs, combat/alchemy, signs/alchemy) | Perk-driven: a few cheap perks plus tier-1/2 skills from two paths | Whatever both sides need | Perks cost 3 points and are chained; capstones cost 4–7 points: hybrids reach capstones far sooner |

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

Blood and Wine's late-game progression: research with skill points and mutagens, one active mutation, and extra skill slots. Mapped as the MUT area ([mut.md](mut.md)); what each mutation scales and costs is in the [ledger](ledger/mutations.md), and the mutations at base stats in both tree files. Ghost Mode's cornerstones: Magic Sensibilities (Signs), Bloodbath (sword), Euphoria (alchemy); Adrenaline Rush, Mutated Skin, Deadly Counter and Life Leech run on adrenaline. The mutations are legacy Ghost Mode's in both trees; only their research costs differ by tree (classic: legacy's 29 skill points; new tree: decided with MUT) ([how](mut.md#mutations-in-two-trees)). They port after SKL's classic tree.

## How a balance-relevant change is made

For every skill, perk, mutation, potion or gear decision, before it is proposed:

1. **Ledger rows.** Which stats does it add, remove or move, and by how much at max level? Does it touch a hard stat (B2)?
2. **Timing and uptime.** At which tier or point cost does it arrive, compared with legacy (B3)? How easily and how often does it trigger, compared with the legacy effect it stands in for (B5)?
3. **Archetypes.** Which archetypes and synergies does it touch, and are they still viable (B8)?
4. **Replaced effects.** Does it restore or lose something legacy replaced (B4)?
5. **Signs and perks.** Extra scrutiny (B6, B7).
6. **Record.** The decision in the feature entry with the rules it applies, any deviation as a deviation, the ledger and the archetype table updated, and a Mnemosyne note with the reasoning.

## Open questions

- Whether 5.x's classic menu draws five level pips (the separation slice).
- Where legacy's code and its changelist disagree (contradictions and omissions): [open-questions.md](../open-questions.md#legacy-data-vs-changelist).
- MUT's DM3 (supercharged Aard and Piercing Cold, new tree): with phase 2.
