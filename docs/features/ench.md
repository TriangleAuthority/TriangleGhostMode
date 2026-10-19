# ENCH: enchantments, runes and glyphs

What Geralt puts into his gear's slots and what the enchanter adds on top: runes (swords) and glyphs (armor), and the runewords and glyphwords the Hearts of Stone enchanter (the Ofieri runewright in Oxenfurt) can enchant into a sword or a chest armor with three free slots. Ghost Mode reworked most of the words, redid several from scratch, made their enchanting fees, enchanter levels and required runes more varied, cut the cost of upgrading the enchanter, made every runeword work only from the drawn sword (glyphwords only from the worn chest armor), and evened out the runes and glyphs (most at 3/4/5% per tier). Source: the changelist's "Enchantments" section ([legacy-FullChangelist.txt](../legacy-FullChangelist.txt), lines 947–1019), two bug fixes (lines 78, 104) and the Rotation fix (line 94, SKL-09's).

Runewords and glyphwords come from Hearts of Stone (`dlc/ep1`), not Blood and Wine: Blood and Wine's grandmaster smiths add mastercrafted gear and sockets, not enchantments.

Enchantments are part of player power: balance them with [balance.md](balance.md) and the [gear ledger](ledger/gear.md) (sections 4 and 5: every rune, glyph and word in vanilla 1.32, legacy and 5.x).

**How legacy Ghost Mode implements it.** A word's numbers are its `Runeword N _Stats` / `Glyphword N _Stats` ability in `dlc/ep1/.../def_item_ep1_runewords.xml`, which also holds the enchanter's schematics (fee, enchanter level, the three runes or glyphs required); legacy adds `Glyphword 10 abl` and `Glyphword 14 abl` (stack abilities given to Geralt) and two new effects, `Runeword4Effect` and `Runeword11Effect` (`dlc/ep1/.../effects.xml`, `runeword4.ws`, `runeword11.ws`). Whether a word is active is decided by `W3PlayerWitcher.HasRunewordActive` (legacy: the drawn sword only) and the new `HasGlyphwordActive` (the chest armor); every vanilla `HasAbility('Runeword N _Stats', true)` check is switched to them. The words' effects live where they act: stamina costs in `PlayerAbilityManager.ws`, damage terms in `damageManagerProcessor.ws`, sign rules in the sign entities, kill triggers in `CNewNPC.OnDeath`. The enchanter's upgrade price is in three `shop_enchanter_01_lvl_*.w2scene` dialogue scenes and the quest phase `mq6005_enchanter.w2phase`; the fee factors in `economy_tagmodifiers.csv`. Runes and glyphs are `def_item_upgrades.xml` (main game) and `def_item_ep1_upgrades.xml` (Hearts of Stone). Texts: `CInventoryComponent.GetParamsForRunewordTooltip` and 19 strings (vanilla keys) in 9 languages.

**What 5.x did in this area.** Little to the mechanics: the words, the activation rule, the enchanter and the runes are 1.32's. 5.x raised six words' numbers (Elation 0.1–0.25 → 1 adrenaline per kill, Rejuvenation 25% → 100% stamina per kill, Prolongation 0.5 → 1 s per hit, Dumplings +100% → +400%, Depletion 50% → 100% of the enemy's stamina, Ignition 25% → 100%, its chance roll removed), keeps an item's enchantment when it is crafted into its next tier, refuses to dismantle enchanted items, lets Deflection deflect its new boulder projectiles too, moved the enchanting menu in the menu tree, and added script references to Runewords 13 and 14 (Incineration, Perturbation) and Glyphwords 21 and 22 (Execution, Precision) with no definitions behind them (dead code, as is the `Glyphword 22 Bonus` free-cast check in `W3SignEntity`).

Unit lists: [attribution.csv](attribution.csv): mapped 2026-10-19 from the changelist and sweeps of every unit naming a runeword, glyphword, rune, glyph or the enchanter (`unit_sweep.py` with `runeword|glyphword|enchant|Rune |Glyph |EET_Runeword|quen_chance_on_projectile` and the words' attribute names; every enchantment file classified by what changed): 472 units carry an ENCH feature (105 script units, 95 XML units and their 95 NG+ copies, 4 binary files, 2 CSV rows, 171 string rows: 19 strings × 9 languages); 46 of them are shared with other features (SKL's sign functions, DMG's damage functions, MUT's and ARM's units). Units of rune and glyph items whose only change is price, weight or dismantling parts, and the rune and glyph crafting schematics, are left to ECON, WGT and CRAFT ([hand-off](#hand-off-to-other-areas)). Port status: **mapped, analysed against 5.x from the code; the owner's [area decisions](#area-decisions) made (2026-10-19); ported (2026-10-19, all 14 slices of the [port order](#port-order), verified in both trees); audited 2026-10-19 ([ENCH audit](#ench-audit-2026-10-19)): every finding fixed, recorded or decided by the owner ([close-out](#audit-close-out)): the clear fixes (F1 to F4, F9, F10; 5.x-GM `4d2b141c`) and the owner's three contradiction rulings (5.x-GM `1b7b4f32`) verified in both trees; **signed off** by the owner (2026-10-19; [close-out](#audit-close-out)).**

## Changes at a glance

### What Ghost Mode changed

| # | Feature | Vanilla 1.32 | Legacy GM | Units (main) |
|---|---|---|---|---|
| ENCH-01 | When words are active | Runewords from either equipped sword, glyphwords from any equipped item | Runewords only from the drawn sword (Preservation and Dumplings: equipped); glyphwords only from the worn chest armor | `HasRunewordActive`, `HasGlyphwordActive`, every check switched to them |
| ENCH-02 | Enchanter and schematics | Upgrades 5000/10000/15000 crowns; fees 525–2115; fee factor 0.45, removal 0.38, Novigrad ×1.1 | Upgrades 3000/6000/9000; fees 520–2396 and several words moved between enchanter levels; required runes and glyphs redone; removal 0.35; no Novigrad surcharge | 23 schematics, 3 scenes, quest phase, journal text, 2 price rows |
| ENCH-03 | Replenishment (Runeword 1) | After a sign, 1 adrenaline charges the next sword hit with it; Axii branch with the default confusion | Axii: 5 s confusion; Yrden slowdown 4 → 5 s | `ProcessPreHitModifications`, `Runeword 1 _Stats` |
| ENCH-04 | Severance (Runeword 2) | Whirl +1.1 yd, Rend +1.9 yd | Same range; final damage of Whirl and Rend −33.4% (legacy's code: with or without the runeword; the port: with it, the owner's ruling) | `ProcessDamageModification`, `OnPreAttackEvent` |
| ENCH-05 | Invigoration (Runeword 4) | Overheal at full Vitality adds up to +50% damage to the next hit | An effect with a HUD counter: +2% weapon damage per 1% of excess Vitality (max +50%), consumed by a damaging hit (and Sign hits with Conductors of Magic), lost when Vitality drops or combat ends | `runeword4.ws`, `GetTotalWeaponDamage`, `GainStat`, pool term removed |
| ENCH-06 | Preservation and Dumplings (Runewords 5, 6) | Armorer's Table and grindstone buffs never expire; food lasts +100% | Preservation re-applies a buff that is removed; both work from an equipped (not drawn) sword; Dumplings' tooltip on every edible | `W3RepairObjectEnhancement.OnEffectRemoved`, `AddBuffStats` |
| ENCH-07 | Placation (Runeword 8) | At max adrenaline, adrenaline drains 0.08/s; stamina regen +25%, Vitality +1%, toxicity −2/s | Drains 0.3/s (also out of combat), no adrenaline gain meanwhile; stamina regen +5%, Vitality +5%, toxicity −5/s | `W3Effect_Runeword8`, `Runeword 8 Regen`, `AdrenalineDrain` |
| ENCH-08 | Rejuvenation and Elation (Runewords 10, 12) | A kill restores 25% stamina / gives 0.1–0.25 adrenaline | A kill heals 15% Vitality / gives 0.25 adrenaline; triggered from the enemy's death | `Runeword10Triggerred`, `Runeword12Triggerred`, `CNewNPC.OnDeath` |
| ENCH-09 | Prolongation (Runeword 11) | Each unblocked hit adds 0.5 s to active potions | Adrenaline gained at max slows potion timers, 0.5% per 1% of excess (3 points = 100%), max 50%, reset on losing adrenaline or leaving combat; HUD counter | `runeword11.ws`, `CBaseGameplayEffect.OnTimeUpdated` |
| ENCH-10 | Levity, Balance, Heft (Glyphwords 2, 3, 4) | Armor counts as light / medium / heavy | Levity: melee −20%, signs +20% stamina; Balance: signs −20%, melee +20%; Heft: damaging melee +20% cost and +20% damage | `GetGlyphword234Mod`, cost sites, pool term |
| ENCH-11 | Deflection (Glyphword 1) | Armor deflects arrows; with Deflection 2+ reflects them | Bounces every arrow not parried; reflection only through a parry (DEF-08) | `W3ArrowProjectile.OnProjectileCollision` |
| ENCH-12 | Retribution (Glyphword 5) | Quen reflects 67% of melee damage, 30% chance | Quen Discharge and Exploding Shield deal +100% damage | `QuenImpulse`, `W3QuenEntity.GetSignStats`, reflect removed |
| ENCH-13 | Depletion, Rotation, Ignition, Eruption (Glyphwords 6, 7, 12, 20) | Aard drains 50% stamina; Igni 360°; burning spreads 25%; kills explode for 50 | Depletion 50% (drain from the projectile, regen delay 1 s); Rotation +150 damage, burn chance −33.3%; Ignition 50%, default burning; Eruption 300 | `glyphword*` attributes, sign entities, `W3Effect_Burning` |
| ENCH-14 | Usurpation, Beguilement, Possession (Glyphwords 10, 14, 18) | Axii transfers on death / +2 s per hit / both | Usurpation: +25% attack power and intensity per puppet (max 4); Beguilement: +25% crit chance and power per confused enemy (max 4); Possession keeps both vanilla effects | `AddGlyphwordBonuses`, `Glyphword 10/14 abl`, `CNewNPC` |
| ENCH-15 | Entanglement, Protection (Glyphwords 15, 17) | Turret hits place a trap; Quen at combat start | Entanglement's trap 2.5 yd, 5 s, 35% slowdown, unaffected by intensity; Protection's Quen free, only without a Quen up, +100% intensity | `W3YrdenEntity`, `W3QuenEntity.GetSignStats`, `OnCombatStart` |
| ENCH-16 | Runes and glyphs | Lesser/normal/greater 2/3/5% (sign glyphs 2/5/10%), Svarog 10/20/30, Pierog/Tvarog nothing, Mending 1/2/3, Warding +1/2/3% elemental (broken), Binding broken | 3/4/5% across the board, Svarog 10/15/20, Pierog +5 regen out of combat, Tvarog +5 in combat, Mending 3/4/5, Warding a 3/4/5% Quen on projectile hits, Binding 3/4/5% (fixed) | `def_item_upgrades.xml`, `def_item_ep1_upgrades.xml`, `ReduceDamage` |
| ENCH-17 | Descriptions and tooltips | — | Texts and live values for every reworked word; item tooltips show base stats with runes and glyphs listed apart (bug fix); schematic tooltips list ingredient counts | `GetParamsForRunewordTooltip`, `ExcludeEnhancements`, 19 strings |
| ENCH-18 | 5.x's enchantment changes | n/a | n/a (5.x only) | none |

### What 5.x changed

| # | Feature | 5.x change (from code and data) |
|---|---|---|
| ENCH-01 | Activation | none (1.32's rule) |
| ENCH-02 | Enchanter | none to costs, levels or schematics; the enchanting menu sits at the top of the menu tree; enchantments survive crafting the next tier (ENCH-18) |
| ENCH-03 | Replenishment | none |
| ENCH-04 | Severance | none (the new tree's Whirl `sword_s35` is a special attack like the classic one) |
| ENCH-05 | Invigoration | none (1.32's pool term) |
| ENCH-06 | Preservation, Dumplings | Dumplings +100% → +400%, applied to food and drinks |
| ENCH-07 | Placation | none |
| ENCH-08 | Rejuvenation, Elation | Rejuvenation 100% stamina, Elation 1 adrenaline per kill (`stamina_runeword_gain`, `focus_runeword_gain`, capped at the maximum) |
| ENCH-09 | Prolongation | +1 s per hit (was 0.5) |
| ENCH-10 | Levity, Balance, Heft | none (they change the armor class; gone in the port since ARM-02, DA7) |
| ENCH-11 | Deflection | also deflects 5.x's `W3DeflectableAdvancedProjectile` (thrown boulders) |
| ENCH-12 | Retribution | none |
| ENCH-13 | Aard and Igni words | Depletion 100%; Ignition 100%, no chance roll; Eruption's explosion also deals the dying enemy's weapon damage ×5 (minimum 50) and sets alight 50% of the time (removed by the port, audit F2) |
| ENCH-14 | Axii words | none |
| ENCH-15 | Yrden and Quen words | none |
| ENCH-16 | Runes and glyphs | none (no new runes or glyphs in the files at the mod's paths) |
| ENCH-17 | Descriptions | new tooltip params for Rejuvenation and Elation's new attributes and for Runeword 13 |
| ENCH-18 | 5.x's changes | Runewords 13, 14 and Glyphwords 21, 22 named in scripts only; `Glyphword 22 Bonus` checked by `W3SignEntity` and never granted; enchantments kept on crafted upgrades; enchanted items not dismantled |

### Classification and proposed action

| # | Feature | Class | Proposed action |
|---|---|---|---|
| ENCH-01 | Activation | clean | Port (DE1) |
| ENCH-02 | Enchanter | clean (data), conflict (binary scenes 5.x re-saved) | Port legacy's costs and schematics (DE3) |
| ENCH-03 | Replenishment | clean | Port; settle the trigger timing SKL's audit noted |
| ENCH-04 | Severance | clean | Port; ends DMG's Severance final-damage deviation |
| ENCH-05 | Invigoration | clean | Port; ends DMG's two Runeword 4 deviations and MUT-02's |
| ENCH-06 | Preservation, Dumplings | overlap | Legacy (DE2) |
| ENCH-07 | Placation | clean | Port |
| ENCH-08 | Rejuvenation, Elation | overlap | Legacy (DE2) |
| ENCH-09 | Prolongation | overlap | Legacy (DE2) |
| ENCH-10 | Levity, Balance, Heft | clean | Port; ends ARM-02's DA7 deviation and DMG's Heft term |
| ENCH-11 | Deflection | overlap | Legacy's rule, 5.x's boulders kept (DE5) |
| ENCH-12 | Retribution | clean | Port; ends SKL-11's and DMG's Glyphword 5 deviations |
| ENCH-13 | Aard and Igni words | overlap (Depletion, Ignition, Eruption) | Legacy (DE2); ends SKL-09's Glyphword 7 deviation and DMG's Rotation term |
| ENCH-14 | Axii words | clean | Port |
| ENCH-15 | Yrden and Quen words | clean | Port; ends SKL-10's and SKL-11's Glyphword 15 and 17 deviations |
| ENCH-16 | Runes and glyphs | clean | Port the values and Warding's Quen |
| ENCH-17 | Descriptions | clean | Port with each feature's slice |
| ENCH-18 | 5.x's changes | rethink, needs-decision | Owner's call (DE4, DE6) |

---

### ENCH-01 When runewords and glyphwords are active

| | |
|---|---|
| Kind | system |
| Pillars | P8 |
| 5.x class | clean |
| Flags | — |
| Depends on | — |
| Skill trees | n/a |
| Port form | `@replaceMethod W3PlayerWitcher.HasRunewordActive` (the drawn-sword rule), `@addMethod HasGlyphwordActive` (`enchantments/activation.ws`); each word's checks switched with that word's feature; legacy's debug commands (`enchantments/debugCommands.ws`); the generated `gm_ench.xml` (`tools/gen_ench.py`) |
| Port status | **signed off** (2026-10-19); **ported**, verified in both trees (2026-10-19) |
| Open checks | — |
| Save impact | none (expected) |
| NG+ counterpart | none (scripts) |

**What it does:** a runeword works only while its sword is drawn; Preservation and Dumplings (passive, out-of-combat words) work while the sword is equipped. A glyphword works only from the worn chest armor. Not in the changelist (an omission).

**Implementation (legacy):** `HasRunewordActive` requires `IsItemHeld` except for Runewords 5 and 6; `HasGlyphwordActive` reads the `EES_Armor` slot; every vanilla `HasAbility('Runeword N _Stats', true)` (which counts both equipped swords) and `HasAbility('Glyphword N _Stats', true)` is switched (sign entities, damage manager, effects, NPC events, the finisher triggers in `CR4Player.OnAnimEvent_pad_vibration`, `CR4PlayerStateCombat.OnPreAttackEvent`).

**5.x:** 1.32's rule: a runeword on the sheathed sword counts (both swords are always equipped), so a steel-sword runeword works with the silver sword drawn.

**Decisions:** DE1 (owner, 2026-10-19): legacy's rule. The ported debug commands (`enchantSteel`, `enchantSilver`, `enchantArmor`) remove an item's enchantment before adding one (legacy stacked a second word's ability; a debug tool): porter's call, confirmed by the owner (2026-10-19).

**Slices:**

1. **Activation rule** (5.x-GM `39db995f`). Verified 2026-10-19 in both trees (test save, words enchanted by script with `EnchantItem`, slots added up to three): Severance on the steel sword inactive while sheathed, active once the sword is drawn (a real draw, `OnEquipMeleeWeapon`), inactive again when sheathed; Dumplings and Preservation active from a sheathed silver sword; Deflection active from the chest armor; a glyphword's ability on Geralt but not on the chest armor does nothing; the replaced Hearts of Stone abilities keep their tags (`GMTest_ench01` in the regression run, `gmtest_ench01_a/b/c`). 5.x's own callers of `HasRunewordActive` (Invigoration's overheal, Preservation, Dumplings) follow the rule from here. Legacy's console commands `enchantSteel`, `enchantSilver`, `enchantArmor` and their `unenchant` counterparts are ported.

### ENCH-02 Enchanter costs and schematics

| | |
|---|---|
| Kind | content, tuning |
| Pillars | P6 |
| 5.x class | clean (XML, CSV), conflict (the three scenes and the quest phase: one property each, in files 5.x re-saved) |
| Flags | — |
| Depends on | ECON (the price factors' other rows), CRAFT (rune and glyph schematics) |
| Skill trees | n/a |
| Port form | legacy's 23 schematics whole in a `<custom><gm_enchantment_schematics>` node of the generated `gm_ench.xml` (`tools/gen_ench.py`; a schematic cannot be overridden), read before the vanilla entries by the replaced `W3CraftsmanComponent.LoadSchematicsXMLData` (enchanter levels), `W3EnchantmentManager.LoadSchematicsXMLData` (the enchanting menu) and `getEnchantmentSchematicFromName` (`enchantments/enchanter.ws`); the upgrade prices by binary property edits of the 5.x files (`tools/cr2w_patch.py`: `CPayStorySceneChoiceAction.money` in the three scenes, both `W3QuestCond_IsItemQuantityMet.count` crown checks in the phase); the journal objectives' text in a replaced `CR4JournalQuestMenu.UpdateObjectives`; the two fee-factor rows by a whole-file override of `economy_tagmodifiers.csv` (no CSV mounter covers it) |
| Port status | **signed off** (2026-10-19); **ported**, verified in both trees (2026-10-19; schematics; the binary edits and the CSV packed, not played) |
| Open checks | the enchanter's dialogue and upgrade quest at the patched prices (Oxenfurt; whether the mod's bundle overrides the Hearts of Stone files is not observed), the objectives' text (in the 8 other languages too), the enchanter's word list on screen, the fee factors |
| Save impact | none for fees and schematics (definitions); an enchanter upgrade already bought stays bought |
| NG+ counterpart | applied (legacy's `items_plus` schematics are the same) |

**What it does** (changelist 950–954): upgrading the enchanter costs 3000/6000/9000 crowns (vanilla 5000/10000/15000); the schematics were redone "to make them more diverse": enchanting fees 520–2396 (vanilla 525–2115), Placation and Usurpation moved to the enchanter's level 2, Elation and Beguilement to level 1 (the others' levels unchanged: see the [list](#schematics)), and the runes and glyphs each word needs; fees are the schematic price × 0.45 at the enchanter (removal 0.35, was 0.38), with no ×1.1 surcharge in Novigrad.

**Implementation (legacy):** schematics in `def_item_ep1_runewords.xml`; scenes and phase as above; `CR4JournalQuestMenu.UpdateObjectives` rewrites "5000" to "3000" in the two enchanter objectives (the same function also gains legacy's debug labels); four debug console commands (`enchantSteel`, `enchantSilver`, `unenchantSteel`, `unenchantSilver`; `enchantArmor` and `unenchantArmor` are attributed to ARM-01).

**5.x:** vanilla's costs and schematics.

**Decisions:** DE3 (owner, 2026-10-19): legacy's costs in full, binary edits included: all four binary edits are made (no fallback needed). From the code: the enchanting menu charges no fee in 1.32, legacy or 5.x (its price is set to 0 before every check; nothing removes money), so the schematics' prices and the fee factors only feed what the menu displays, if anything; they are ported as legacy's data all the same.

**Slices:**

1. **The enchanter** (5.x-GM `7e332cc8`). Verified 2026-10-19 in both trees (`GMTest_ench02` in the regression run): Ghost Mode's 23 schematics load from the DLC's custom node; by name, Replenishment reads legacy's fee 2396, level 3 and Veles greater as its second rune, Elation level 1, Usurpation level 2; the enchanting menu's manager (built by script as the menu builds it) reads Placation at level 2 and Beguilement at level 1 and holds 23 schematics, none twice. Checked outside the game: the three scenes and the phase differ from 5.x's only in the prices (3000, 6000, 9000; both crown checks 3000), with valid CRCs (`cr2w_dump.py`); the game starts and runs with them in the mod's bundle. Not in game: the enchanter's dialogue and upgrade quest (Oxenfurt, Hearts of Stone), the objective text, the enchanter's word list on screen, the fee factors.

<a id="schematics"></a>Schematics (level, then the three runes or glyphs; vanilla → legacy, where changed): Replenishment 3, Triglav/Morana/Dazhbog greater → Triglav/Veles/Dazhbog greater; Severance 2, Zoria/Veles/Perun → Stribog/Svarog/Elemental; Invigoration 3, Devana/Zoria/Perun greater → Devana/Svarog/Elemental greater; Preservation 1, Svarog/Devana/Morana lesser → Svarog/Devana/Elemental lesser; Placation 1 → 2, Devana/Morana/Stribog lesser → Zoria/Morana/Perun; Rejuvenation 2, Perun/Svarog/Stribog → Dazhbog/Triglav/Devana; Prolongation 3, Svarog greater → Zoria greater; Elation 2 → 1, Dazhbog/Veles/Devana → Stribog/Triglav/Perun lesser; the other glyphwords but Deflection, Heft and Entanglement (fee only): one or two glyphs swapped; Usurpation 1 → 2 (Axii/Mending/Reinforcement); Beguilement 2 → 1 (Axii/Igni/Mending lesser).

### ENCH-03 Replenishment (Runeword 1)

| | |
|---|---|
| Kind | tuning |
| Pillars | P8 |
| 5.x class | clean |
| Flags | balance |
| Depends on | ENCH-01, SKL (sign casts, signed off), MUT-11's `ProcessPreHitModifications` |
| Skill trees | both (any sign cast; the classic and the new tree cast the same signs) |
| Port form | `@replaceMethod` of `W3PlayerWitcher.OnSignCastPerformed`, `W3DamageManagerProcessor.ProcessPreHitModifications` (Axii's duration) and `CR4PlayerStateCombat.OnPreAttackEvent`; a wrapper of `W3PlayerWitcher.OnProcessActionPost` keeps the charge for a hit with the other sword (`enchantments/replenishmentSeverance.ws`) |
| Port status | **signed off** (2026-10-19); **ported**, verified in both trees (2026-10-19) |
| Open checks | the other signs' charges; a charge kept across a sword switch |
| Save impact | none (expected) |
| NG+ counterpart | applied (ability values) |

**What it does** (changelist 970–974): after a sign, one adrenaline point charges the next sword attack: Aard knockdown, Igni +100% of weapon damage as fire, Yrden 5 s slowdown (vanilla 4), Quen heals 50% of the damage, Axii 5 s confusion (vanilla: the effect's default). The infusion is cleared after combat.

**5.x:** as 1.32. SKL's audit (item 21) noted that `OnSignCastPerformed` runs at the start of Firestream and the active Quen in 5.x, where legacy ran it at the end: the moment Replenishment takes its adrenaline differs for channelled signs.

**Decisions:** port as legacy.

- **Deviation:** for channelled signs (Firestream, the active Quen) Replenishment takes its adrenaline point and charges the sword when the cast starts (5.x calls `OnSignCastPerformed` then), not when it ends as in legacy; moving the call would change every other user of it (the Griffin set, SKL's rules) (porter's call, confirmed by the owner, 2026-10-19).

**Slices:**

1. **Replenishment** (5.x-GM `9f7a6738`, with Severance). Verified 2026-10-19 in both trees: a real Axii cast with the Replenishment sword drawn spends one adrenaline point (classic; 3 → 2); scripted casts (`OnSignCastPerformed`): none spent with the sword sheathed, one with it drawn, Axii's charge; a scripted light hit with the sword on a neutral test dummy confuses it for 5 s and spends the charge (`gmtest_ench03_a/b`); values and descriptions (`GMTest_ench03_04` in the regression run). Not in game: the other signs' charges, a charge kept across a sword switch.

### ENCH-04 Severance (Runeword 2)

| | |
|---|---|
| Kind | tuning |
| Pillars | P1 |
| 5.x class | clean |
| Flags | balance |
| Depends on | ENCH-01, DMG-05 (final-damage step, signed off), STAM-09 (both Whirls) |
| Skill trees | both: Whirl (classic `sword_s1`, new `sword_s35`) and Rend (`sword_s2`, shared) |
| Port form | DMG's final-damage step (`GMProcessDamageModification`, `damage/pipeline.ws`) gains the term, applied while `HasRunewordActive('Runeword 2 _Stats')`; `OnPreAttackEvent`'s check (`enchantments/replenishmentSeverance.ws`) |
| Port status | **signed off** (2026-10-19); **ported**, verified in both trees (2026-10-19) |
| Open checks | the range with the runeword |
| Save impact | none (expected) |
| NG+ counterpart | applied |

**What it does** (changelist 962–963): Whirl +1.1 yd and Rend +1.9 yd of range (vanilla), and the final damage of both −33.4% (`runeword2_damage_debuff`), applied to Vitality and Essence damage after the formula. Legacy's code applies the cut to every Whirl and Rend hit of the player, with or without Severance (a [contradiction](../open-questions.md#legacy-data-vs-changelist) with the changelist, settled by the owner: the cut only with the runeword).

**5.x:** range as 1.32, no damage cut.

**Decisions:** port as legacy, except the cut's condition (below). Its description keeps legacy's text (which names the cut). Ends DMG's Severance deviation.

- **Deviation:** Whirl's and Rend's −33.4% final damage applies only while Severance is active (from the drawn sword, ENCH-01), as the changelist and the description say; legacy's code cut every Whirl and Rend hit of the player, with or without the runeword (project owner, 2026-10-19).

**Slices:**

1. **Severance** (5.x-GM `9f7a6738`). Verified 2026-10-19 in both trees: a real Whirl (classic `sword_s1`, new `sword_s35`) on a neutral test dummy deals x0.666 of its formula's result (then legacy's rule, without the runeword); the value and description (`GMTest_ench03_04`).
2. **The cut only with Severance** (the owner's ruling; 5.x-GM `1b7b4f32`). Verified 2026-10-19 in both trees on a neutral test dummy, test probes reading each hit's formula result and final damage (`gmtest_ench04_set`, `gmtest_ench04_check`): a real Whirl (classic `sword_s1`, new `sword_s35`, pressed through the input handler) deals x1.000 of its formula's result without Severance and x0.666 with it on the drawn sword; a real Rend (`sword_s2`) the same, x1.000 and x0.666, in each tree. Not in game: the range with the runeword.

### ENCH-05 Invigoration (Runeword 4)

| | |
|---|---|
| Kind | system |
| Pillars | P1, P7 |
| 5.x class | clean |
| Flags | balance |
| Depends on | ENCH-01, DMG-04 and DMG-08 (pool and weapon damage, signed off), MUT-02 (Conductors of Magic), SKL-07 (regen) |
| Skill trees | n/a |
| Port form | new effect type `EET_GMRuneword4` (enum extension) with `W3GMEffect_Runeword4` and `GMRuneword4Effect` in the DLC's `gm_effects.xml`; `@replaceMethod W3AbilityManager.GainStat` (5.x's overheal field replaced by the effect); wrappers of `W3AbilityManager.OnAbilityRemoved`, `W3PlayerAbilityManager.OnVitalityChanged`, `W3Effect_AutoVitalityRegen.OnUpdate`, `W3PlayerWitcher.OnProcessActionPost`, `OnCombatFinished`, `OnSpawned`, `CR4Player.PlayRuneword4FX` (`enchantments/invigoration.ws`); the pool term removed from `damage/pool.ws`, the bonus in `damage/weapon.ws`; the HUD counter in MUT's `mutations/hudCounters.ws` |
| Port status | **signed off** (2026-10-19); **ported**, verified in both trees (2026-10-19) |
| Open checks | a real sword attack spending the bonus; the HUD counter on screen |
| Save impact | none (the effect is removed at load) |
| NG+ counterpart | applied (`abilities_plus` effect, `items_plus` ability) |

**What it does** (changelist 975–977): in combat at full Vitality, regeneration past the maximum builds a bonus: +2% weapon damage (slashing or silver) per 1% of excess Vitality, up to +50%, shown as a buff with a counter; a damaging melee hit spends it, as does losing Vitality or leaving combat. Vitality regeneration keeps running at the maximum only while the runeword is active.

**Implementation (legacy):** `W3Effect_Runeword4` (`runeword4.ws`), `Runeword4Effect` (`effects.xml`), `dmg_gain_rate` 2; vanilla's overheal field, its pool term and `CR4Player.PlayRuneword4FX` removed; FX from the effect.

**5.x:** 1.32's overheal in the raw-damage pool.

**Decisions:** port as legacy, except where Sign hits spend the bonus (below). The effect takes the `GM` prefix (`EET_GMRuneword4`; legacy `EET_Runeword4`). Ends DMG's two Runeword 4 deviations and MUT-02's.

- **Deviation:** a damaging Sign hit with Conductors of Magic (which gets the bonus through the sword's damage) spends it, as the changelist says; legacy's check names those hits but sits inside `OnProcessActionPost`'s melee branch, so in legacy they never spent it (project owner, 2026-10-19).

**Slices:**

1. **Invigoration** (5.x-GM `02d5f72f`). Verified 2026-10-19 in both trees, in combat with the hostile test dummy: Vitality gained past the maximum (`GainStat`, as healing and regeneration call it) builds nothing with the sword sheathed and +20% for 10% excess with it drawn, the FX playing; real Vitality regeneration at the maximum builds the bonus with the sword drawn and stops with it sheathed; a scripted light hit with the sword spends the bonus; a Vitality loss and the end of combat (`OnCombatFinished` called by script) end it (`gmtest_ench05_a/b/c/d`); the values, the description, the cap at +50%, the HUD counter's values and the sword's slashing damage ×1.2 at +20% (`GMTest_ench05` in the regression run). Not in game: a real attack spending it, the HUD counter on screen.
2. **Sign hits with Conductors of Magic spend it** (the owner's ruling; 5.x-GM `1b7b4f32`). Verified 2026-10-19 in both trees, in combat with a neutral test dummy, a Viper School steel sword with Invigoration drawn, the bonus built to +20% by overheal (`GainStat`) and Vitality regeneration stopped by script so it cannot build again (`gmtest_ench05_sign_a/build/b`): a real Igni cast (`autocast`) that damaged the dummy spent the bonus with Conductors of Magic equipped and left it at +20% without it. Melee spending unchanged (`gmtest_ench05_a/b/c/d` passed again, classic tree).

### ENCH-06 Preservation and Dumplings (Runewords 5, 6)

| | |
|---|---|
| Kind | fix, tuning |
| Pillars | P8 |
| 5.x class | overlap (Dumplings' value) |
| Flags | needs-decision |
| Depends on | ENCH-01, FOOD (food and drink durations), ITEM (Armorer's Table and grindstone buffs) |
| Skill trees | n/a |
| Port form | `@replaceMethod W3RepairObjectEnhancement.OnTimeUpdated` and a scope-based override of its inherited `OnEffectRemoved` (Preservation); `@replaceMethod` of `W3Effect_WellFed.SetEffectValue` and `W3Effect_WellHydrated.SetEffectValue` (5.x's regen multiplier removed) and of `W3Effect_WellHydrated.CalculateDuration` (Dumplings' bonus read from the word's definition, audit F4; `enchantments/preservationDumplings.ws`); Dumplings' value in `gm_ench.xml`; the rest of legacy's food effects (Perk 15, the edible tooltip) with FOOD |
| Port status | **signed off** (2026-10-19); **ported**, verified in both trees (2026-10-19) |
| Open checks | a real drink (no item applies Well Hydrated in the port until FOOD: 5.x's drinks give Well Fed); the Armorer's Table; a grindstone buff outlasting its time with Preservation; the tooltip on screen |
| Save impact | none (expected) |
| NG+ counterpart | applied |

**What it does** (changelist 958–959): Preservation: Armorer's Table and grindstone buffs never expire (legacy re-applies one that gets removed); Dumplings: edibles last +100%, its bonus shown on every edible's tooltip. Both work from an equipped sword (ENCH-01).

**5.x:** Dumplings +400% (`runeword6_duration_bonus` 1 → 4), on food and drinks; on drinks (Well Hydrated) read from Geralt's attribute, which sums both swords (+800% with the word on both; legacy reads the definition: [audit](#ench-audit-2026-10-19) F4). 5.x's drinks give Well Fed (`BeverageQuality_1` to `_3`), legacy's Well Hydrated (FOOD).

**Decisions:** DE2 (owner, 2026-10-19): legacy's numbers and mechanics; 5.x's multiplier of food and drink regeneration by Dumplings' bonus is removed (legacy: duration only). Food and drink durations themselves and legacy's other changes to the food effects are FOOD's.

- **Deviation:** the edible tooltip shows Dumplings' bonus only for an edible equipped in a quick slot (5.x); legacy shows it on every edible (temporary, until FOOD, which owns the tooltip code; porter's call, confirmed by the owner, 2026-10-19).

**Slices:**

1. **Preservation and Dumplings** (5.x-GM `a1569c13`). Verified 2026-10-19 in both trees: a Bread eaten (`ConsumeItem`) with Dumplings on the sheathed silver sword gives Well Fed for 60 s instead of 30, its regeneration unchanged; with Preservation on the sheathed steel sword the grindstone buff, removed by script, is applied again, and without it stays removed (`gmtest_ench06`); the value and description (`GMTest_ench06` in the regression run). Not in game: a drink, the Armorer's Table, a grindstone buff outlasting its time with Preservation, the tooltip on screen.
2. **Dumplings on drinks once** (audit F4; 5.x-GM `4d2b141c`). `W3Effect_WellHydrated.CalculateDuration` reads the word's definition (+100%) instead of Geralt's attribute. Verified 2026-10-19 in both trees (`GMTest_ench06_drink` in the regression run, scripted: Well Hydrated added by script): 15 s without Dumplings, 30 s with the word on one sword, 30 s on both (5.x's reading: 45 s with legacy's value). Not in game: a real drink (none applies Well Hydrated in the port; legacy's drinks do, a FOOD change).

### ENCH-07 Placation (Runeword 8)

| | |
|---|---|
| Kind | tuning |
| Pillars | P2 |
| 5.x class | clean |
| Flags | balance |
| Depends on | ENCH-01, SKL-07 (adrenaline gain, signed off), MUT-10 (`OnFocusChanged`, hosted in `mutations/mutatedSkin.ws`), UI (toxicity panel line) |
| Skill trees | n/a |
| Port form | `@replaceMethod` of `W3Effect_Runeword8.OnEffectAdded` and `OnUpdate` (the drain) and `W3Effect_AdrenalineDrain.OnUpdate` (`enchantments/killWords.ws`); the drawn-sword check in MUT's replaced `OnFocusChanged` (`mutations/mutatedSkin.ws`); no gain while it drains is 5.x's `W3PlayerAbilityManager.GainStat`; `Runeword 8 Regen` in `gm_ench.xml`; the description values |
| Port status | **signed off** (2026-10-19); **ported**, verified in both trees (2026-10-19) |
| Open checks | the regen and toxicity bonuses measured; a real gain to the maximum in a fight |
| Save impact | none (expected) |
| NG+ counterpart | applied |

**What it does** (changelist 964–967): at maximum adrenaline, adrenaline declines at 0.3 points/s to zero, in or out of combat, and none is gained meanwhile; during the decline Vitality and stamina regenerate 5% faster and toxicity falls 5/s faster.

**5.x:** as 1.32 (0.08/s; stamina +25%, Vitality +1%, toxicity −2/s; drains in combat only, through the adrenaline drain effect).

**Decisions:** port as legacy.

**Slices:**

1. **Placation** (5.x-GM `af2545f9`, with ENCH-08). Verified 2026-10-19 in both trees: maximum adrenaline (set by script, so `OnFocusChanged` runs as for a real gain) starts nothing with the sword sheathed and starts Placation with it drawn, its regen ability on Geralt; adrenaline gains are refused meanwhile; adrenaline then fell at 0.30/s out of combat (classic) and in combat with the hostile test dummy (new tree), the after-combat drain not running (`gmtest_ench07_a/b/c`); the values and the description (`GMTest_ench07_08` in the regression run). Not in game: the regen and toxicity bonuses measured, a real gain to the maximum in a fight.

### ENCH-08 Rejuvenation and Elation (Runewords 10, 12)

| | |
|---|---|
| Kind | tuning |
| Pillars | P2, P8 |
| 5.x class | overlap |
| Flags | balance, needs-decision |
| Depends on | ENCH-01, DEF's `ProcessAction` (`defense/processAction.ws` hosts 5.x's triggers), MUT's `CNewNPC.OnDeath` units |
| Skill trees | n/a |
| Port form | `@replaceMethod` of `W3PlayerWitcher.Runeword10Triggerred`, `Runeword12Triggerred` and `CR4Player.OnAnimEvent_pad_vibration` (5.x's finisher trigger removed; `enchantments/killWords.ws`); the triggers moved from DEF's `ProcessAction` (`defense/processAction.ws`) to ENCH's replaced `CNewNPC.OnDeath` (`enchantments/npcDeath.ws`); values in `gm_ench.xml`; the description values |
| Port status | **signed off** (2026-10-19); **ported**, verified in both trees (2026-10-19) |
| Open checks | a finisher kill; a Sign or crossbow kill |
| Save impact | none (expected) |
| NG+ counterpart | applied |

**What it does** (changelist 960, 968): Rejuvenation: killing an enemy heals 15% of maximum Vitality (vanilla: 25% stamina). Elation: a kill gives 0.25 adrenaline (vanilla 0.1–0.25). Finishers trigger them once.

**5.x:** Rejuvenation 100% stamina, Elation 1 adrenaline, both capped at the maximum: the strongest adrenaline and stamina sources of any runeword (gear ledger).

**Decisions:** DE2 (owner, 2026-10-19): legacy's numbers and mechanics. Legacy's kill trigger: an enemy's death by Geralt's melee, ranged, Sign, finisher or kill action, from the drawn sword (ENCH-01).

**Slices:**

1. **Rejuvenation and Elation** (5.x-GM `af2545f9`). Verified 2026-10-19 in both trees with the hostile test dummy and the steel sword drawn: a kill by a scripted sword hit with Rejuvenation heals exactly 15% of Vitality (once: 5.x's trigger in `ProcessAction` is gone) and leaves stamina; a kill by Geralt (`CActor.Kill` with Geralt as the attacker, so no adrenaline from the hit) with Elation gives exactly 0.25 adrenaline (`gmtest_ench08_a/b`); the values and descriptions (`GMTest_ench07_08` in the regression run). Not in game: a finisher kill, a Sign or crossbow kill.

### ENCH-09 Prolongation (Runeword 11)

| | |
|---|---|
| Kind | system |
| Pillars | P8 |
| 5.x class | overlap |
| Flags | balance, needs-decision |
| Depends on | ENCH-01, ALCH (potion timers), SKL-13 (`CBaseGameplayEffect.OnTimeUpdated`, Tawny Owl), MUT-10 |
| Skill trees | n/a |
| Port form | new effect type `EET_GMRuneword11` with `W3GMEffect_Runeword11` and `GMRuneword11Effect` (`gm_effects.xml`); the gain in ENCH-05's replaced `W3AbilityManager.GainStat` (`enchantments/invigoration.ws`); the end below maximum in MUT's replaced `OnFocusChanged`; `@replaceMethod` of `CBaseGameplayEffect.OnTimeUpdated` and `W3Potion_TawnyOwl.OnTimeUpdated` (the timer term), wrappers of `W3AbilityManager.OnAbilityRemoved`, `OnCombatFinished`, `OnSpawned` (`enchantments/prolongation.ws`); the HUD counter in `mutations/hudCounters.ws`. 5.x's per-hit term in `CNewNPC.OnTakeDamage` stays but adds nothing: it reads the ability's `duration`, which legacy's ability does not have |
| Port status | **signed off** (2026-10-19); **ported**, verified in both trees (2026-10-19) |
| Open checks | adrenaline from real hits at the maximum; the HUD counter on screen; Tawny Owl |
| Save impact | none (the effect is removed at load) |
| NG+ counterpart | applied |

**What it does** (changelist 978–980): adrenaline gained while at maximum is counted as excess; it slows potion timers (not decoctions or White Raffard) by 0.5% per 1% of excess (3 points = 100%), up to 50%; the bonus ends when adrenaline drops below the maximum or combat ends; shown as a buff with a counter. Legacy quirk: `W3AbilityManager.OnAbilityRemoved` removes the effect when Runeword 1's ability (Replenishment) is removed, not Runeword 11's.

**5.x:** +1 s to active potions per unblocked hit (1.32: 0.5 s).

**Decisions:** DE2 (owner, 2026-10-19): legacy's numbers and mechanics. Ported now, ahead of ALCH: the rule is self-contained (the potion timers' tick). What waits for ALCH: Tawny Owl's night freeze stays 5.x's (legacy rewrote it); the timer term applies on top of whatever ALCH ports. Legacy's quirk (the bonus removed with Replenishment's ability, not Prolongation's) is ported as legacy's code, its fix on the Later list: porter's call, confirmed by the owner (2026-10-19).

**Later:** remove the bonus when Prolongation's own ability is removed (legacy's quirk keys it on Runeword 1).

**Slices:**

1. **Prolongation** (5.x-GM `673e45f0`). Verified 2026-10-19 in both trees, in combat with the hostile test dummy and the steel sword drawn: 0.6 adrenaline gained at the maximum slows potion timers by 10%; a drunk Cat potion's timer then ran at x0.90 and a Mutagen 1 decoction's at x1.00 over 6.5 s (classic; in the new tree the decoction was not drunk, the potion side only); losing adrenaline and the end of combat (`OnCombatFinished` called by script) end the bonus (`gmtest_ench09_a/b/c`); the values, the description, 5.x's per-hit attribute gone, the bonus per excess adrenaline, the cap at 50% and the HUD counter's values (`GMTest_ench09` in the regression run). Not in game: adrenaline from real hits at the maximum, the HUD counter on screen, Tawny Owl.

### ENCH-10 Levity, Balance and Heft (Glyphwords 2, 3, 4)

| | |
|---|---|
| Kind | system |
| Pillars | P2, P4 |
| 5.x class | clean |
| Flags | balance |
| Depends on | ENCH-01, STAM-03 (cost functions, signed off), ARM-02 (DA7: the class is the item's), DMG-04 (pool) |
| Skill trees | both (sign costs in either tree) |
| Port form | `GMGetGlyphword234Mod` in wrappers of `GetStaminaActionCost` and `GetSkillStaminaUseCost` (`enchantments/levityBalanceHeft.ws`); Heft's term in `damage/pool.ws`; the descriptions' values in a wrapper of `GetParamsForRunewordTooltip` (`enchantments/descriptions.ws`), the texts under the vanilla keys |
| Port status | **signed off** (2026-10-19); **ported**, verified in both trees (2026-10-19) |
| Open checks | a real attack's cost with a glyphword; the item tooltip on screen |
| Save impact | none (expected) |
| NG+ counterpart | applied |

**What it does** (changelist 985–986, 994–995, 1006–1007): Levity: melee actions cost 20% less stamina, signs 20% more. Balance: signs 20% less, melee 20% more. Heft: damaging melee actions (fast, strong, counter) cost 20% more and deal 20% more damage (an additive pool term). Special attacks (Whirl, Rend) are excluded. The class change of vanilla's glyphwords is gone (ARM-02), and so is their effect on regen (ARM-03).

**Implementation (legacy):** `W3PlayerAbilityManager.GetGlyphword234Mod`; its `IsActionMelee` counts light and heavy attacks, usable items, parry, counter, dodge, roll, evade, sprint and jump: Levity and Balance also change the cost of using items (bombs, crossbow), which the changelist's "melee actions" does not say ([open questions](../open-questions.md#legacy-data-vs-changelist)).

**5.x:** the 1.32 class change, removed by ARM-02. Today the three glyphwords do nothing (ARM-02's temporary deviation, the owner's DA7).

**Decisions:** port as legacy; ends ARM-02's deviation and DMG's Heft term. The owner (2026-10-19): legacy's code, so Levity and Balance also change the cost of using items, sprinting and jumping; their descriptions say "physical actions" instead of "melee actions" in all 9 languages (Heft's stays "damaging melee actions"; Czech and French keep legacy's English text).

**Slices:**

1. **Levity, Balance, Heft** (5.x-GM `39db995f`). Verified 2026-10-19 in both trees: with Levity on the chest armor a light attack, dodge, item use and sprint cost ×0.8 and Aard ×1.2 (by action and by skill); Balance the reverse; Heft light attacks ×1.2, dodge, item use, sprint and signs unchanged; the cost functions are read by script (the functions real actions pay through, STAM-03). Heft adds 0.2 to a melee hit's additive damage pool (scripted hits on a neutral test dummy, `gmtest_ench10_dmg`); Balance's description shows 20/20 and the "physical actions" text (`GMTest_ench10` in the regression run). Not in game: a real attack's cost with a glyphword, the item tooltip on screen.

### ENCH-11 Deflection (Glyphword 1)

| | |
|---|---|
| Kind | system |
| Pillars | P9 |
| 5.x class | overlap (5.x's deflectable boulders) |
| Flags | needs-decision |
| Depends on | ENCH-01, DEF-08 (arrow parry, `defense/arrowParry.ws`) |
| Skill trees | n/a (reflection is Deflection the skill's, DEF-08) |
| Port form | the glyphword branch in DEF-08's replaced `W3ArrowProjectile.OnProjectileCollision` moved after the parry, as legacy (5.x's branch before the parry removed, audit F1); `@replaceMethod W3ThrallBoulderProjectile.OnProjectileCollision` (5.x's thrown boulders) the same per DE5; the bounce in `GMDeflectionBounce` (`enchantments/deflection.ws`) |
| Port status | **signed off** (2026-10-19); **ported**, verified in both trees (2026-10-19; arrows) |
| Open checks | 5.x's thrown boulders; a real perfectly timed parry press (reflection checked with a press stamped by script) |
| Save impact | none |
| NG+ counterpart | none |

**What it does** (changelist 984): the armor bounces every arrow Geralt does not parry; it no longer reflects them (vanilla: with the Deflection skill at level 2+), reflection being the parry's (DEF-08).

**5.x:** 1.32's branch before the parry (bounce, or reflect with the skill); the same branch on 5.x's new thrown-boulder projectiles. In 5.x an arrow never reaches the parry with the word on: no guard needed, no parry stamina, and with the Deflection skill a reflection without guarding; the port removed that branch ([audit](#ench-audit-2026-10-19) F1).

**Decisions:** DE5 (owner, 2026-10-19): legacy's rule, 5.x's boulders under it too. The boulders' parry stays 5.x's (it needs the Deflection skill, as in 5.x; DEF-08 made only arrows parryable without it): porter's call, confirmed by the owner (2026-10-19). Deflection's checks are exec tests against a real archer rather than regression checks, and reflection is checked with a parry press stamped by script at each impact (a stand-in for a perfectly timed press): porter's calls, confirmed by the owner (2026-10-19).

**Slices:**

1. **Deflection** (5.x-GM `74155464`). Verified 2026-10-19 in both trees against a real archer, Geralt not guarding, 8 s each: with Deflection on the chest armor Geralt lost no Vitality and the archer none (arrows bounced, none reflected); without it the arrows landed (`gmtest_ench11_a/b`). Not in game: 5.x's thrown boulders (no test spawn for a boulder thrower); a parried arrow with Deflection on (the parry branch is DEF-08's, unchanged).
2. **Deflection after the parry** (audit F1; 5.x-GM `4d2b141c`). 5.x's branch before the parry removed. Verified 2026-10-19 in both trees against a real archer (`gmtest_def08_archer`), real arrows, 12 s per case, the guard raised by script (`thePlayer.SetGuarded`), parries and reflection checks counted by test probes (`gmtest_ench11_a/b`): with Deflection on the chest armor and the guard down, Geralt lost nothing, no arrow was parried and none reached the reflection check (`ProcessCombat_ArrowDeflection`), with and without the Deflection skill (classic `sword_s10`, new tree `sword_s33`); with the guard up, every arrow that hit was parried (1 or 2 per case, each costing parry stamina, 100 → 95) and reached the reflection check, none reflected without the skill; with the skill and a parry press stamped by script at each impact (`gmtest_ench11_a(true, true)`, standing in for a perfectly timed press), the reflected arrows took 420 Vitality from the archer. Without the word, unguarded, arrows landed (747 Vitality); guarded, they were parried (classic tree; in the new tree the archer stopped shooting in that window). No adrenaline from a parry or reflection (Perk 31's gain is gone with SKL-18). Not in game: a real timed parry press; 5.x's thrown boulders.

### ENCH-12 Retribution (Glyphword 5)

| | |
|---|---|
| Kind | system |
| Pillars | P8 |
| 5.x class | clean |
| Flags | balance |
| Depends on | ENCH-01, SKL-11 (Quen, Quen Discharge, Exploding Shield; signed off), DMG-11 (returned damage, `damage/returned.ws`) |
| Skill trees | both: Quen Discharge (classic `magic_s14`, the new tree's slot from D58) and Exploding Shield (`magic_s13`, shared) |
| Port form | the boost (`GMRetributionBoost`) in SKL-11's `QuenImpulse` and `W3QuenEntity.GetSignStats` (`skills/quen.ws`); `@replaceMethod W3DamageManagerProcessor.ProcessActionReturnedDamage` without the reflection (`enchantments/retribution.ws`); the description value |
| Port status | **signed off** (2026-10-19); **ported**, verified in both trees (2026-10-19) |
| Open checks | a real Quen Discharge on a real hit |
| Save impact | none |
| NG+ counterpart | applied |

**What it does** (changelist 1008): Quen Discharge and Exploding Shield deal +100% damage. Vanilla's effect (a 30% chance to reflect 67% of melee damage through Quen) is removed.

**5.x:** vanilla's reflection, kept by DMG-11 (temporary deviation) and SKL-11's note "legacy's Glyphword 5 boost comes with ENCH".

**Decisions:** port as legacy. The character panel's Quen Discharge lines with the boost are UI's (the port has no such lines yet). Legacy's `PlayGlyphword5FX` is not ported: nothing in legacy calls it (dead code; audit F7).

**Slices:**

1. **Retribution** (5.x-GM `60f4e831`). Verified 2026-10-19 in both trees: Quen Discharge's share doubles with the word on the chest armor (classic `magic_s14` 0.05 → 0.10, the new tree's `magic_s40` 0.083 → 0.167); Exploding Shield's impulse at level 3 on a neutral test dummy deals twice the damage (56.7 → 113.5); no boost from the ability on Geralt but not on the chest armor; no reflection chance in the data (`GMTest_ench12_15` in the regression run, `gmtest_ench12`; scripted: `QuenImpulse` called directly, the discharge share read from a new Quen entity). Not in game: a real Quen Discharge on a real hit.

### ENCH-13 Depletion, Rotation, Ignition and Eruption (Glyphwords 6, 7, 12, 20)

| | |
|---|---|
| Kind | tuning, system |
| Pillars | P8 |
| 5.x class | clean (Rotation), overlap (Depletion, Ignition values; Eruption's added weapon damage, removed: audit F2) |
| Flags | balance, needs-decision |
| Depends on | ENCH-01, SKL-08 and SKL-09 (Aard, Igni, signed off), MUT-04 (`W3AardProjectile.ProcessCollision` in `mutations/piercingCold.ws`), DMG-04 (Rotation's flat damage), EFX (burning) |
| Skill trees | both (Aard and Igni basic casts) |
| Port form | Depletion's drain in MUT's replaced `ProcessCollision` (`mutations/piercingCold.ws`), `@replaceMethod CNewNPC.OnAardHit` without 5.x's drain; Rotation: `@replaceMethod W3IgniEntity.OnStarted` (the 360° fire mode), its burn chance in SKL-09's `GetSignApplyBuffTest`, its flat damage in `damage/pool.ws`; Ignition: `@replaceMethod W3Effect_Burning.OnEffectAdded` and `OnUpdate`; Eruption: `@replaceMethod CNewNPC.OnDeath` (marked lines; `enchantments/npcDeath.ws`); Rotation in Igni's skill description (`skills/skillDescriptions.ws`, audit F3); values in `gm_ench.xml`; descriptions |
| Port status | **signed off** (2026-10-19); **ported**, verified in both trees (2026-10-19) |
| Open checks | Ignition and Eruption from a real Igni cast; how often Ignition fires |
| Save impact | none (expected) |
| NG+ counterpart | applied |

**What it does** (changelist 987–990, 996–997, 1012–1013): Depletion: Aard hits drain 50% of the enemy's stamina (raising knockdown chances). Rotation: Igni's basic cast hits all around and deals +150 damage (scales with intensity), burning chance −33.3%. Ignition: enemies set alight by Igni have a 50% chance to ignite others within 2 yd (default burning). Eruption: foes killed by Igni explode for 300 fire damage (vanilla 50).

**5.x:** Depletion 100%, Ignition 100% with the chance roll removed; Rotation as 1.32; Eruption's explosion adds the dying enemy's weapon damage ×5 (minimum 50) to its 300 fire damage (5.x `npc.ws` `OnDeath`; removed by the port, [audit](#ench-audit-2026-10-19) F2) and sets alight 50% of the time; Igni's skill description leaves out Rotation (legacy's tooltip shows it; audit F3).

**Decisions:** DE2 (owner, 2026-10-19): legacy's Depletion and Ignition; Rotation and Eruption port as legacy. Legacy's code, not the changelist's wording: Rotation's burning chance is cut by 33.3 points (additive), so at Igni's starting chance (33.35%) a basic Igni with Rotation hardly burns; its description shows legacy's rounding (34%; porter's call, confirmed by the owner, 2026-10-19); Ignition's roll skips an enemy when it falls below the chance (with 50% the same odds); Eruption's explosion always sets alight (legacy; 5.x 50%). The character panel's Igni lines with Rotation are UI's. Eruption's explosion damage is checked by an exec test with two dummies rather than in the regression run (porter's call, confirmed by the owner, 2026-10-19). `CNewNPC.OnDeath` is replaced with ENCH's changes only (the other areas' legacy changes to it stay 5.x's until their areas; ENCH-14's Possession and ENCH-08's kill triggers will land here).

**Slices:**

1. **Depletion, Rotation, Ignition, Eruption** (5.x-GM `c6ee16e6`). Verified 2026-10-19 in both trees: a real Aard cast with Depletion leaves a neutral test dummy at 49/100 stamina (`gmtest_ench13_depl_a/b`); real Igni casts at the dummy: fire mode 0 and 150 fire damage without Rotation, fire mode 2 (all around) and 300 with it (`gmtest_ench13_igni_a/b`, test probes); Rotation's burning chance by `GetSignApplyBuffTest` 4000 tries: 0.33 → 0 at level 1; Ignition (scripted Igni burning on one of two dummies at the same spot): the second one set alight with the default burning from `glyphword 12` in some trials and not in others, never without the word (`gmtest_ench13_ign_a/b`); Eruption (scripted: the burning dummy killed by a hit from its Igni burning): the other dummy took the explosion's damage and burns, nothing without the word (`gmtest_ench13_erupt_a/b`); values, the chest-armor rule and descriptions (`GMTest_ench13` in the regression run). Not in game: Ignition and Eruption from a real Igni cast; how often Ignition fires (a handful of trials only).
2. **Eruption without 5.x's weapon term; Igni's description with Rotation** (audit F2, F3; 5.x-GM `4d2b141c`). Verified 2026-10-19 in both trees. Eruption (scripted, `gmtest_ench13_erupt_a/b`, two neutral human test dummies, a test probe on the explosion's damage action): the explosion's raw damage is FireDamage 300 and nothing else, the other dummy hit and alight; the dying dummy held no weapon, so the term 5.x would add against an armed enemy is known gone from the code, not seen. Igni's description (`GMTest_ench13_igniDesc` in the regression run): 150 damage and 33% without the word, 300 and 0% with it (33.35% less 33.3 points; floored at 0 as legacy), the string's placeholders shared by the 9 languages (English read).

### ENCH-14 Usurpation, Beguilement and Possession (Glyphwords 10, 14, 18)

| | |
|---|---|
| Kind | system |
| Pillars | P8 |
| 5.x class | clean |
| Flags | balance |
| Depends on | ENCH-01, SKL-12 (Axii, Puppet, Delusion; signed off) |
| Skill trees | both (Axii and its Puppet in either tree) |
| Port form | wrappers of `W3ConfuseEffect` and `W3Effect_AxiiGuardMe` `OnEffectAdded`/`OnEffectRemoved` with an `@addField` flag for the stacks (added only with the word active), cleared at load (`enchantments/axiiWords.ws`); legacy's `Glyphword 10 abl` and `Glyphword 14 abl` (legacy's names kept) in `gm_ench.xml`; `@replaceMethod CNewNPC.OnProcessActionPost` and `OnDeath` (`enchantments/npcDeath.ws`) for Possession only |
| Port status | **signed off** (2026-10-19); **ported**, verified in both trees (2026-10-19) |
| Open checks | the stacks' attack power and crit bonuses in a fight; a load with stacks up |
| Save impact | none (expected; the stack abilities are on Geralt while the effects last) |
| NG+ counterpart | applied |

**What it does** (changelist 991–992, 998–999, 1009–1011): Usurpation: each enemy under Axii's Puppet gives +25% attack power and sign intensity (max 4 stacks). Beguilement: each enemy confused by Axii gives +25% critical hit chance and power (max 4). Possession: as vanilla, Axii transfers to a nearby enemy when its target dies, and its duration grows 2 s per blow the target lands (vanilla shared these with Usurpation and Beguilement; now Possession's only).

**5.x:** as 1.32.

**Decisions:** port as legacy, with two deviations:

- **Deviation:** a Usurpation or Beguilement stack is added only while its glyphword is on the worn chest armor when the Axii effect starts, as the changelist and the descriptions say; legacy's `AddGlyphwordBonuses` (`axiiGuardMe.ws`, `confusedEffect.ws`) checked only that the effect was Geralt's sign effect, so every Axii puppet and confusion of Geralt's gave the stacks, with or without the words (project owner, 2026-10-19). A stack already added stays until its effect ends, even if the armor is taken off meanwhile.
- **Deviation:** the stacks are cleared when a save loads, and Axii effects still running then add none (the effects' flag is not saved). Legacy saved the flag, and its load cleanup named the words' `_Stats` abilities instead of the stacks, so stacks lasted until their effects ended; the port avoids a saved field (porter's call, confirmed by the owner, 2026-10-19).

**Slices:**

1. **Usurpation, Beguilement, Possession** (5.x-GM `9c1a3376`). Verified 2026-10-19 in both trees: a real Axii cast at a neutral test dummy with Beguilement on the chest armor gives Geralt one stack, gone when the dummy is removed; scripted Axii effects (as Geralt's sign adds them) on two dummies: 2 stacks with two, then 1, then 0 as the confusions end, capped at 4; Usurpation one stack per puppet, removed with it (`gmtest_ench14_stacks`); Possession: a puppet's scripted hit extends its Axii by 2 s, and when it dies its Axii moves to the other dummy (`gmtest_ench14_poss_a/b`); values and descriptions (`GMTest_ench14` in the regression run). Not in game: the stacks' attack power and crit bonuses in a fight; a load with stacks up.
2. **Stacks only with the word** (the owner's ruling; 5.x-GM `1b7b4f32`). Verified 2026-10-19 in both trees: real Axii casts (`autocast`) at a neutral test dummy, the stacks read when the cast ends (the test probe on `W3AxiiEntity.OnEnded`; `gmtest_ench14_real`, `gmtest_ench14_count`): the dummy confused and no stack without a glyphword, one Beguilement stack (and no Usurpation stack) with Beguilement on the chest armor; scripted (`gmtest_ench14_stacks`, two dummies): no Beguilement stack and no Usurpation stack without the words, 2, 1, 0 and the cap at 4 with Beguilement, one Usurpation stack per puppet with Usurpation; in the regression run (`GMTest_ench14_rule`): `GMAddAxiiWordStack` as the effects call it gives no stack without the words, only the worn word's stack with one.

### ENCH-15 Entanglement and Protection (Glyphwords 15, 17)

| | |
|---|---|
| Kind | system, tuning |
| Pillars | P3, P8 |
| 5.x class | clean |
| Flags | balance |
| Depends on | ENCH-01, SKL-10 and SKL-11 (Yrden, Quen; signed off), STAM-01 (Protection's Quen and the cooldown) |
| Skill trees | both: Magic Turret (`magic_s03`, shared) for Entanglement; Quen for Protection |
| Port form | SKL-10's `skills/yrden.ws` (`GetSignStats`, `YrdenTrapHitEnemy`, `YrdenSlowdown_Loop`) gains the trap values; SKL-11's `skills/quen.ws` the +100% intensity; MUT's `mutations/combatStart.ws` (which hosts `OnCombatStart`) legacy's free Quen; the flag in `enchantments/protection.ws` |
| Port status | **signed off** (2026-10-19); **ported**, verified in both trees (2026-10-19) |
| Open checks | Protection at a real combat start |
| Save impact | none (expected) |
| NG+ counterpart | applied |

**What it does** (changelist 1000–1004): Entanglement: when the Magic Turret hits an enemy, a Magic Trap is placed there, limited to 2.5 yd, 5 s and 35% slowdown and unaffected by Yrden Intensity and upgrades. Protection: entering combat gives a Quen shield without stamina and with +100% intensity, unless a Quen is already up (vanilla: always, stamina restored afterwards, no bonus).

**5.x:** as 1.32.

**Decisions:** port as legacy; ends SKL-10's Glyphword 15 and SKL-11's Glyphword 17 deviations. Protection's free Quen uses the port's free-Quen flag (`freeFromBearSetBonus`, as Warding's and the restored Quen's): no stamina, adrenaline or cooldown.

**Slices:**

1. **Entanglement and Protection** (5.x-GM `60f4e831`). Verified 2026-10-19 in both trees: a real Magic Turret cast near a neutral test dummy with Entanglement on the chest armor places a trap on the turret's hit: 5 s, 2.5 yd, the dummy slowed by 35% (`gmtest_ench15_entangle`); Protection: a combat start with no Quen up gives a Quen with no stamina spent and intensity +1.0 (x2.0 classic, x2.26 new tree with its sign intensity), a second start with that Quen up casts none (`gmtest_ench15_protection`, `OnCombatStart` called by script); the values and descriptions (`GMTest_ench12_15`). Not in game: Protection at a real combat start.

### ENCH-16 Runes and glyphs

| | |
|---|---|
| Kind | tuning, fix |
| Pillars | P8 |
| 5.x class | clean |
| Flags | balance |
| Depends on | SKL-11 (Quen on projectile casts a Quen), ARM-01 (enhancement slots, signed off) |
| Skill trees | n/a |
| Port form | the rune and glyph `_Stats` abilities given whole in `gm_ench.xml`; Pierog and Tvarog's items from 5.x given whole without `Relic _Stats`; the Quen on projectile: `@replaceMethod ReactToBeingHit` (5.x's body without it) and `GMWardingQuen`, called from the port's `ReduceDamage` (`enchantments/runesGlyphs.ws`, `defense/dodge.ws`) |
| Port status | **signed off** (2026-10-19); **ported**, verified in both trees (2026-10-19) |
| Open checks | a glyph socketed by hand; the rune and glyph tooltip texts |
| Save impact | none (expected: runes and glyphs read their abilities from the definitions) |
| NG+ counterpart | applied |

**What it does** (changelist 78, 1015–1019): lesser/normal/greater: Perun (adrenaline gain), Elemental (attack power), Veles (intensity) and the effect-chance runes (Stribog, Dazhbog, Devana, Zoria, Morana, Triglav) 3/4/5% (vanilla 2/3/5); Svarog's armor piercing 10/15/20 (10/20/30); the sign glyphs 3/4/5% (2/5/10); Pierog +5 Vitality regen out of combat, Tvarog +5 in combat (vanilla nothing); Mending 3/4/5 (1/2/3); Warding: a 3/4/5% chance to cast a free Quen when hit by a projectile (vanilla: 1/2/3% elemental resistance, as a multiplier, the bug the changelist fixes); Binding 3/4/5% bleeding resistance (fixed: vanilla used a multiplier). Most values are not in the changelist (an omission).

**Implementation (legacy):** the abilities in both upgrade files; Pierog and Tvarog lose `Relic _Stats`; legacy moves the Quen-on-projectile check from `ReactToBeingHit` to `ReduceDamage` (only when no Quen is up, ranged non-sign hits not dodged), where the free Quen absorbs the hit and ends with it.

**5.x:** as 1.32.

**Decisions:** port as legacy. The rune and glyph items' prices, weights and dismantling parts stay 5.x's ([hand-off](#hand-off-to-other-areas) to ECON, WGT, CRAFT).

**Slices:**

1. **Runes and glyphs** (5.x-GM `029e8542`). Verified 2026-10-19 in both trees: legacy's values read from the definitions (Perun lesser 0.03, Stribog 0.04, Svarog 15, Pierog and Tvarog +5 regen, Mending lesser 3, Binding greater 5%, Warding greater 5% Quen chance and no elemental resistance, greater Aard glyph +5%); a Pierog rune added to the inventory is not a relic (`GMTest_ench16` in the regression run). Warding: scripted projectile hits of a test dummy's on Geralt with the chance raised to 100% are absorbed by a free Quen that does not stay up (5.x's own cast in `ReactToBeingHit` would have stayed up); without the glyph the hit lands (`gmtest_ench16_warding`). Not in game: a glyph socketed into armor by hand (the test puts Warding's ability on Geralt; the attribute is read the same way), the tooltip texts of the runes and glyphs.

### ENCH-17 Enchantment descriptions and tooltips

| | |
|---|---|
| Kind | ui, fix |
| Pillars | P7 |
| 5.x class | clean (units overlap) |
| Flags | — |
| Depends on | every ENCH feature; UI (the recipe part of the schematic tooltip) |
| Skill trees | n/a |
| Port form | a wrapper of `CInventoryComponent.GetParamsForRunewordTooltip` with legacy's cases (`GMRunewordTooltipParams`) and a wrapper of `GetItemTooltipAttributes` (legacy's `ExcludeEnhancements`; `enchantments/descriptions.ws`); the 19 strings under their vanilla keys in 9 languages, each with its word's slice; the schematic tooltip's ingredient counts with UI |
| Port status | **signed off** (2026-10-19); **ported**, verified in both trees (2026-10-19) |
| Open checks | the tooltips on screen |
| Save impact | none |
| NG+ counterpart | none |

**What it does** (changelist 104, 952): every reworked word's description with live values; item tooltips show the item's own stats, with runes and glyphs listed separately (bug fix); schematic tooltips list owned and needed ingredients (also for enchantment schematics).

**5.x:** vanilla texts; tooltip params for Rejuvenation's and Elation's new attributes and for Runeword 13.

**Decisions:** port with each feature's slice. The schematic tooltip's ingredient counts are UI's (the recipe part of `W3TooltipComponent.addComponentsInfo`).

**Slices:** the descriptions came with each word's slice (values and texts checked in the regression run's ENCH checks). The item tooltip fix (5.x-GM `16be4c7e`): verified 2026-10-19 in both trees: the steel sword's tooltip stats are the same with a greater Elemental rune socketed (`GMTest_ench17` in the regression run, `GetItemStats` as the inventory calls it). Not in game: the tooltips on screen.

### ENCH-18 5.x's enchantment changes

| | |
|---|---|
| Kind | content |
| Pillars | P8 |
| 5.x class | rethink |
| Flags | needs-decision |
| Depends on | CRAFT (crafting manager), SKL-07 (the free-cast check in `skills/rageManagement.ws`) |
| Skill trees | n/a |
| Port form | DE4: nothing (5.x's code kept); DE6: the check removed from SKL's replaced `W3SignEntity.ManagePlayerStamina` (`skills/rageManagement.ws`) |
| Port status | **signed off** (2026-10-19); **ported**, verified in both trees (2026-10-19) |
| Open checks | crafting an enchanted item's next tier; dismantling (5.x's code, unchanged) |
| Save impact | none |
| NG+ counterpart | none |

**What it does:** n/a in legacy. 5.x (from the code; not seen in game): (1) crafting an item's next tier keeps its enchantment (`W3CraftingManager.Craft`); enchanted items cannot be dismantled, and the blacksmith's socket removal skips them; (2) Runewords 13 and 14 (Incineration, Perturbation) and Glyphwords 21 and 22 (Execution, Precision) are named in the enchanting console helper, tooltips and sword FX, with no ability, item or schematic defining them (searched in the 5.x files at the mod's paths and the REDkit depot); `W3SignEntity` makes a cast free while Geralt has `Glyphword 22 Bonus`, which nothing grants. The port's `skills/rageManagement.ws` keeps that check (SKL's open check, "Glyphword 22's free sign with Rage Management").

**Decisions:** DE4 (owner, 2026-10-19): 5.x's conveniences kept; DE6 (owner, 2026-10-19): the `Glyphword 22 Bonus` check removed, which closes SKL's open check (Glyphword 22's free sign with Rage Management). 5.x's other dead references (Runewords 13, 14, Glyphword 21 in helpers, tooltips and FX) stay.

- **Deviation:** crafting an item's next tier keeps its enchantment (5.x's `W3CraftingManager.Craft`; legacy and 1.32 lose it) (the owner's DE4, confirmed by the owner, 2026-10-19).
- **Deviation:** enchanted items cannot be dismantled, and the blacksmith's socket removal skips them (5.x; legacy and 1.32 allow both) (the owner's DE4, confirmed by the owner, 2026-10-19).

**Slices:**

1. **DE6** (5.x-GM `16be4c7e`). Verified 2026-10-19 in both trees: a real Aard cast in combat costs 40 stamina through the replaced `ManagePlayerStamina`; the regression run passes. DE4 needs no code. Not in game: crafting an enchanted item's next tier, dismantling (5.x's code, unchanged).

### ENCH audit (2026-10-19)

Done by a fresh session ([audit](../feature-mapping.md#audit-signing-a-feature-off)) on 5.x-GM `16be4c7e` and master `bfdc731d` (regression 462 passed, 0 failed in each tree, as recorded by the port), reading code and data only; no game run (every finding below is plain in the code). Every script unit attributed to ENCH-01 to ENCH-18 was read against legacy's code (`legacy-GM`), 1.32 (`master`) and 5.x (`vanilla-5.x`), and the entries against the changelist's Enchantments section (lines 947–1019) and its fixes (78, 94, 104). Every vanilla 5.x check of a word's ability (`HasAbility('Runeword N _Stats', true)`, `HasAbility('Glyphword N _Stats', true)`, every call site) was followed to the port's replacement or wrapper. The data was checked by script rather than sampled: every ability in the three files legacy changed (`def_item_ep1_runewords.xml`, `def_item_upgrades.xml`, `def_item_ep1_upgrades.xml`, 87 abilities in each of the regular and NG+ folders) as the port leaves it (`gm_ench.xml` over 5.x's) against legacy's, attribute by attribute; the rune and glyph items for changes other than price, weight and dismantling parts; the 19 strings in 9 languages against legacy's rows; the four binary files against `vanilla-5.x` (`bindiff.py`) and against legacy's edits of 1.32's; the CSV against `vanilla-5.x`.

**Checked and holding:** every runeword, glyphword, rune and glyph ability equals legacy's in both folders (no difference: the words 5.x raised are legacy's, the abilities legacy left as 1.32's and 5.x did not change keep 5.x's, which are the same); the only item change legacy made besides prices, weights and parts (Pierog and Tvarog no longer relics) is ported in both folders; the 23 schematics are legacy's (`gen_ench.py --check` clean) and read first by the three replaced readers; `Runeword4Effect` and `Runeword11Effect` match legacy's under the `GM` names; the four binary files differ from 5.x's only in the four prices, as legacy's differ from 1.32's (no other money or count property in them names 5000/10000/15000), and `cr2w_patch.py --check` finds them patched; `economy_tagmodifiers.csv` differs from 5.x's only in ENCH-02's two rows (5.x's line endings kept); the 19 strings equal legacy's rows in all 9 languages except Levity's and Balance's "physical actions" (the owner's wording, in all 9); every description's placeholders match the values `GMRunewordTooltipParams` fills, which equal legacy's `GetParamsForRunewordTooltip` for the 17 reworked words, 5.x's cases for the others being the same as legacy's; the activation rule (DE1) is `HasRunewordActive`/`HasGlyphwordActive` at every check that acts (F5 lists the inert ones); Replenishment, Severance's cut, Invigoration (effect, gain, spending, ends, weapon damage, regen at the maximum, HUD), Preservation, Dumplings' food, Placation, Rejuvenation, Elation, Prolongation (timer, Tawny Owl, ends, legacy's quirk), Levity, Balance, Heft (costs and damage), Retribution (Quen Discharge, Exploding Shield, the reflection gone), Depletion, Rotation, Ignition, Usurpation, Beguilement, Possession, Entanglement, Protection, Warding and the item tooltip fix equal legacy's code or a recorded deviation; both skill trees are handled where skills are involved (Whirl and Rend in either tree, Quen Discharge's skill read per tree, the sign costs, the Magic Turret, Igni's burning chance); DE2 to DE6 and the Levity and Balance ruling are implemented as written (DE5's boulders: the old branch removed, the bounce after the parry); the other areas' temporary deviations waiting for ENCH are all ended (`deviations.py --unconfirmed` lists none "until ENCH"; the docs that still named ENCH are corrected, F8); `check_modsigns.py` clean (242 bodies, 0 unmarked), `deviations.py --check` current (87), `gen_ench.py --check`, `gen_ngplus.py --check` clean, `gen_arm_items.py --verify` 0 unexplained differences; `unit_sweep.py` (runeword, glyphword, enchant, rune, glyph, `quen_chance_on_projectile`) finds no unattributed ENCH unit (its hits are the rune and glyph shop lists and quest rewards, handed off to LOOT and XP).

**Findings:**

1. **Deflection: 5.x's branch before the parry is still in the arrow code** (clear fix). DEF-08's replaced `W3ArrowProjectile.OnProjectileCollision` keeps 5.x's `else if(thePlayer.HasAbility('Glyphword 1 _Stats', true))` before the parry (`defense/arrowParry.ws:134-146`); ENCH-11 added legacy's bounce after the parry (line 167) but did not remove it. Legacy commented the branch out ("moved", legacy `arrowProjectile.ws:185-211`) and bounces only what was not parried (243-250). In the port, with Deflection on the chest armor: an arrow is never parried (no guard needed, no parry stamina cost, no Perk 31 adrenaline), and with the Deflection skill (either tree; the port's `ProcessCombat_ArrowDeflection` reflects from level 1) arrows are reflected without guarding (subject only to the counter-spam check), which is what the changelist's "no longer reflects" removed. The slice's check (archer, no guard, no Deflection skill) could not see it; `arrowParry.ws:6` and ENCH-11's port form say the branch moved. Fix: remove the branch (`//modSigns: removed`), as the port did for the boulders; check with the Deflection skill, guard down (bounce, no reflection) and up (a parry, reflected). **Fixed** (5.x-GM `4d2b141c`; ENCH-11 slice 2), checked with real arrows.
2. **Eruption keeps 5.x's added weapon damage** (clear fix). 5.x's `CNewNPC.OnDeath` adds to every explosion hit the dying enemy's weapon damage ×5 of the weapon's first damage type (minimum 50), which the port's replaced body keeps (`enchantments/npcDeath.ws:463-480, 500`); 1.32 and legacy deal only Glyphword 20's 300 fire damage (legacy `npc.ws:2969-3015`). Against an armed enemy this can be several times the 300 the description names, and partly physical. Not recorded: ENCH-13 called Eruption "as 1.32" and clean (corrected with this audit). Fix: remove the term (marked), as legacy; the test asserts the explosion's damage (F10). **Fixed** (5.x-GM `4d2b141c`; ENCH-13 slice 2).
3. **Igni's skill description leaves out Rotation** (clear fix). Legacy's Igni tooltip adds Rotation's +150 damage and its −33.3-point burning chance (floored at 0) when the word is on the chest armor (legacy `characterMenu.ws:1903-1912`, a unit attributed to ENCH-13); the port's `skills/skillDescriptions.ws:357-363` shows the plain values. Both trees (Igni's `S_Magic_2` is shared). Fix: the two terms, as legacy. **Fixed** (5.x-GM `4d2b141c`; ENCH-13 slice 2): the numbers change in the port's own string (`gm_skill_desc_igni`), so all 9 languages follow; legacy's strings need not be reused.
4. **Dumplings counts twice on drinks with Dumplings on both swords** (clear fix, minor). 5.x's `W3Effect_WellHydrated.CalculateDuration` reads `target.GetAttributeValue('runeword6_duration_bonus')`, which sums every equipped item's ability: with both swords enchanted, drinks last +200%; legacy reads the definition, +100% (legacy `wellHydrated.ws:40-55`). Food reads the definition in 5.x too. Fix: read the definition (the rest of the body 5.x's; Connoisseur's alcohol rule stays FOOD's), or record a temporary deviation until FOOD, which owns the function. Recommendation: fix (one line). **Fixed** (5.x-GM `4d2b141c`; ENCH-06 slice 2). Inert in the port for now: no item applies Well Hydrated (5.x's drinks give Well Fed, which reads the definition; legacy's drinks give Well Hydrated, a FOOD change).
5. **Units left on 5.x's either-sword check, with no effect** (no action). `W3PlayerWitcher.OnSpawned` and `OnAbilityAdded` start Vitality regeneration with Invigoration on either sword (legacy: the drawn one), which stops itself at full Vitality through the port's `W3Effect_AutoVitalityRegen.OnUpdate` wrapper; `W3AardEntity.ProcessThrow_MainTick` sets Depletion's share on the projectile, which nothing reads since `OnAardHit`'s drain is gone (the port reads the word at the collision, legacy at the cast: the same unless the armor changes mid-flight); `CNewNPC.OnTakeDamage` adds Prolongation's absent `duration` (0); `GetOffenseStatsList` reads the overheal field (0). As in legacy, equipping a Placation sword at maximum adrenaline starts Placation even sheathed (`OnAbilityAdded`, unchanged by legacy).
6. **Hand-offs missing from the table** (corrected with this audit). The entries call the character panel's lines UI's but the hand-off table lacked them (Placation's toxicity line, Rotation's Igni lines, Retribution's Quen Discharge lines, legacy `CharacterStatsPopup.ws:592, 726, 746, 922, 936`), and Heft's damage in `GetOffenseStatsList` (legacy `playerWitcher.ws:8988-8992`); FOOD lacked the edible tooltip (ENCH-06's temporary deviation); ALCH, Tawny Owl's night freeze (ENCH-09); ECON, the other rows legacy changed in `economy_tagmodifiers.csv`, a file ENCH-02 now overrides whole (the enchanter column of crafting, upgrade removal, slots, repair and dismantling, among others).
7. **`PlayGlyphword5FX` is dead code in legacy** (corrected with this audit). ENCH-12 said it was not ported "noted with SKL's deferred sign visuals"; nothing in legacy calls it, and SKL notes nothing. Nothing to port.
8. **Stale doc labels** (corrected with this audit): this page's unit-list status ("the audit ... comes next"); every entry's **Open checks** row said "—" while its slice listed what was not tested in game (now listed, ENCH-02's binary edits and objective texts among them); ENCH-11's "5.x" and ENCH-13's 5.x class (F1, F2); the [status page](README.md#where-the-port-stands) (the phase paragraph, ENCH's row and index line, and the SKL, MUT and ARM rows still listing temporary deviations "until ENCH": none is left); [skl.md](skl.md) SKL-11 ("legacy's Glyphword 5 boost comes with ENCH"); [arm.md](arm.md) ("Areas ARM waits for: ENCH"); the [gear ledger](ledger/gear.md) section 5 ("if the port keeps 5.x's runeword data": it does not, DE2).
9. **Stale code comments** (clear fix, comments only): `damage/returned.ws:4` ("Glyphword 5's reflection stays 5.x's until ENCH"); `damage/pipeline.ws:352` (Severance among the terms that "come with their areas"); `defense/arrowParry.ws:6` (with F1). **Fixed** (5.x-GM `4d2b141c`), with `armor/armorClass.ws:2` ("their legacy stamina trades come with ENCH").
10. **Regression gaps** (clear fix, tests and tools). Nothing compares the words', runes' and glyphs' data with legacy's (this audit did it by script: no difference); the regression run has no Deflection check (the exec checks need an archer and covered neither the guard nor the skill, so F1 passed); Eruption's damage is not asserted (F2); Igni's description with Rotation (F3); nothing runs `cr2w_patch.py --check` on the four binary files or checks the CSV's two rows. Fix: a `--verify` mode in `gen_ench.py` (every ability of the three files against legacy's, both folders; the four binary values; the two CSV rows), run with the other checks; in the regression run, a scripted arrow hit with Deflection and the Deflection skill, guard down and up, Eruption's explosion damage on a dummy (300 × intensity, no weapon term), Igni's description with Rotation, a drink with Dumplings on both swords. **Fixed** (5.x-GM `4d2b141c`; `tools/gen_ench.py` on master): `gen_ench.py --verify` compares the 87 abilities of the three files in each folder with legacy's (no difference), and re-derives the four binary files from 5.x's with the price edits and the CSV from 5.x's rows with legacy's two (all equal); in the regression run Igni's description with and without Rotation and Well Hydrated with Dumplings on one and both swords (regression 465 passed, 0 failed in each tree). The arrow and Eruption checks need an archer or dummies, so they are exec checks rather than regression checks: `gmtest_ench11_a/b` (real arrows; guard, skill, a stamped perfect parry; probes for parries and the reflection check) and `gmtest_ench13_erupt_a/b` (a probe on the explosion's raw damage).
11. **The enchanter not played** (owner decision). The scenes' and the quest phase's prices, the objective text (legacy's `StrReplace` of "5000" also runs on the 8 other languages' titles, unchecked) and the word list are verified outside the game only; whether the mod's bundle overrides the Hearts of Stone files is not observed. Options: (a) a play session at the Oxenfurt enchanter (a save past Hearts of Stone's start; dialogue choices need key presses), before sign-off; (b) sign off with it as an open check. Recommendation: (b), checked when a save at the enchanter exists; legacy shipped the same edits. **Decided** by the owner (2026-10-19): (b), the enchanter's dialogue, Oxenfurt upgrade quest and prices stay untested, an open check of ENCH-02 (legacy shipped the same edits).
12. **Porter's calls not confirmed by the owner** (owner decision): ENCH-03, Replenishment's charge at the start of a channelled sign (5.x's call timing); ENCH-06, Dumplings' edible tooltip only for quick-slot edibles until FOOD; ENCH-14, Usurpation's and Beguilement's stacks cleared at load; also legacy's debug commands now remove an enchantment before adding one (legacy stacked a second word's ability; a debug tool). Recommendation: confirm all. **Decided** by the owner (2026-10-19): all confirmed, with the porter's other calls (Rotation's description at 34%, the boulders parried only with the Deflection skill, Prolongation's bonus ended by removing Replenishment, Deflection and Eruption checked by exec tests, the scripted perfect-parry stamp); each entry says so.
13. **Notes on the three contradictions with the owner** (not classified again). Invigoration: legacy's spending check itself names Sign hits with Conductors of Magic (`action.IsActionMelee() || action.IsActionWitcherSign() && IsMutationActive(EPMT_Mutation1)`, legacy `playerWitcher.ws:2852`) but sits inside the `attackAction.IsActionMelee()` branch (2690), so that clause can never be true: the author wrote the changelist's rule and placed it where it cannot act, which supports the recommendation to let Sign hits spend it. Severance: legacy's cut (`damageManagerProcessor.ws:2271-2279`, "severance damage debuff for Whirl and Rend") has no remnant of a runeword check, and the description in all 9 languages ties the cut to the word ("these attacks"). Usurpation and Beguilement: `AddGlyphwordBonuses` never names the words; with the port's F12 load rule the stacks end at a load, in legacy they lasted until their effects ended. **Decided** by the owner (2026-10-19), each as the changelist says: Severance's cut only with the runeword, the Axii word stacks only with the glyphword, Sign hits with Conductors of Magic spend Invigoration; recorded as deviations confirmed by the owner and verified in both trees (5.x-GM `1b7b4f32`; ENCH-04, ENCH-05, ENCH-14 slices 2).
14. **Small differences with no effect, kept** (no action): Protection's Quen is a new entity each time (5.x's code; legacy reused the existing one); Prolongation's Tawny Owl term omits `isOnPlayer` (Tawny Owl is Geralt's only); Ignition's chance is read from Geralt's attributes (legacy too); the Hearts of Stone scene files are whole-file copies of 5.x's with one value changed (a later 5.x patch to them must be merged by hand, like the CSV).

**Doc corrections made with the audit:** F6 to F8, the facts behind F1 and F2, and F13's evidence in [open-questions.md](../open-questions.md#legacy-data-vs-changelist) (Invigoration): this page (unit-list status, "What 5.x changed" and the classification for ENCH-13, ENCH-11's and ENCH-13's "5.x", ENCH-12's decision, every entry's open checks, the hand-off table: UI, FOOD, ALCH, ECON), the [status page](README.md#where-the-port-stands), [skl.md](skl.md), [arm.md](arm.md), the [gear ledger](ledger/gear.md).

**Not reviewed:** the translations' wording (legacy's rows as shipped; only Levity's and Balance's changed rows read); the test functions' internals beyond what they report; the localized objective titles (F11); NG+ in game (the policy: not tested).

**Suggested fix slices** (each touches its own files; verified in game, both trees where a sign or skill is involved):

- **A, Deflection** (`defense/arrowParry.ws`): F1, its header comment (F9). **Done** (5.x-GM `4d2b141c`, 2026-10-19).
- **B, Eruption** (`enchantments/npcDeath.ws`): F2. **Done** (5.x-GM `4d2b141c`).
- **C, Igni's description** (`skills/skillDescriptions.ws`): F3, both trees. **Done** (5.x-GM `4d2b141c`).
- **D, Dumplings on drinks** (`enchantments/preservationDumplings.ws`): F4. **Done** (5.x-GM `4d2b141c`).
- **E, comments** (`damage/returned.ws`, `damage/pipeline.ws`): F9. **Done** (5.x-GM `4d2b141c`).
- **T, tests and tools** (`tests/gmTestsEnch*.ws`, `tools/gen_ench.py`): F10, after A to D. **Done** (5.x-GM `4d2b141c`; `gen_ench.py --verify` on master): regression 465 passed, 0 failed in each tree.
- **Docs**: F6 to F8 done (2026-10-19); the slices' results go into the entries as they land.
- **O, the owner's rulings** (`damage/pipeline.ws`, `enchantments/axiiWords.ws`, `enchantments/invigoration.ws`, tests): F13. **Done** (5.x-GM `1b7b4f32`, 2026-10-19): regression 468 passed, 0 failed in each tree.

#### Audit close-out

Closed 2026-10-19: every finding is fixed, recorded or decided by the owner. Fixed and verified in both trees: F1 to F4, F9, F10 (5.x-GM `4d2b141c`). Recorded: F5, F7, F14 (no action), F6 and F8 (doc corrections). Decided by the owner (2026-10-19): F11 (the enchanter's dialogue, upgrade quest and prices an open check), F12 (the porter's calls confirmed), F13 (the three contradictions settled by the changelist's rule, made and verified in both trees, 5.x-GM `1b7b4f32`). Checks at close: regression 468 passed, 0 failed in each tree; `check_modsigns.py` 0 unmarked; `gen_ench.py --verify` clean; no ENCH deviation left unconfirmed. **Signed off** by the project owner, 2026-10-19 (ENCH-01 to ENCH-18). What stays open after the sign-off: the open checks listed in the entries (among them the enchanter's dialogue, upgrade quest and prices, not played; F11); ENCH's temporary deviation, confirmed, until FOOD; no ENCH deviation is left unconfirmed (`python tools/deviations.py --unconfirmed`).

---

### Dependencies on other areas

- **Done areas ENCH builds on:** STAM-01 and STAM-03 (cost functions, Protection's Quen), DEF-08 (arrows), DMG (pool, weapon damage, final damage, returned damage), SKL-07 to SKL-13 (adrenaline, signs, Quen, Yrden, Axii, potion timers), MUT (Conductors of Magic, the hosted `OnFocusChanged`, `OnCombatStart`, `W3AardProjectile.ProcessCollision`, HUD counters), ARM-01 to ARM-03 (slots, classes, regen).
- **Areas ENCH waits for or shares with:** ALCH (potion timers for Prolongation), FOOD (Dumplings), ITEM (Armorer's Table and grindstone buffs for Preservation; random enhancements), CRAFT (rune and glyph schematics; 5.x's enchantment carry-over), ECON (prices), UI (panel lines, recipe tooltips), EFX (burning).

### Hand-offs received

Every item other areas handed to ENCH, and where it lands:

| From | Item | ENCH |
|---|---|---|
| ARM-02 (DA7, temporary deviation) | Levity, Balance and Heft's stamina trades (`GetGlyphword234Mod`), `HasGlyphwordActive`, runeword tooltips | ENCH-10, ENCH-01, ENCH-17 |
| ARM (hand-off table) | Glyphword 5 (Quen Discharge); 5.x's `Glyphword 22 Bonus` | ENCH-12, ENCH-18 |
| ARM-03, STAM-04 | The Hearts of Stone glyphwords' stamina regen | Nothing left: vanilla's regen came from the class change, which ARM-02 and ARM-03 removed as legacy; Placation's regen is ENCH-07 |
| SKL-09 | Glyphword 7's (Rotation) Igni burning chance | ENCH-13 |
| SKL-10 | Glyphword 15's (Entanglement) trap values | ENCH-15 |
| SKL-11 | Glyphword 5's (Retribution) Quen Discharge boost; Glyphword 17's (Protection) Quen intensity | ENCH-12, ENCH-15 |
| SKL-12 | Glyphwords 10, 14, 18 | ENCH-14 |
| SKL (audit item 21, open check, F3) | `OnSignCastPerformed` timing for Replenishment; Glyphword 22's free sign with Rage Management | ENCH-03, ENCH-18 (DE6) |
| MUT-02 (temporary deviation) | Runeword 4 (Invigoration) consumed by Sign hits with Conductors of Magic | ENCH-05 |
| MUT (hand-off) | Runeword 1 in `ProcessPreHitModifications`; Depletion's drain in `W3AardProjectile.ProcessCollision` | ENCH-03, ENCH-13 |
| DMG (temporary deviations) | Heft and Rotation pool terms; Severance's final-damage term; Runeword 4's pool and weapon-damage terms; Glyphword 5's reflection | ENCH-10, ENCH-13, ENCH-04, ENCH-05, ENCH-12 |
| DEF-08 | Glyphword 1 in `OnProjectileCollision` | ENCH-11 |
| STAM (hand-off) | Heft, Balance, Levity; Depletion (`W3AardProjectile.ProcessCollision`, `CNewNPC.OnAardHit`); Glyphword 17's free Quen; Runeword 10 heals; Runeword 8 regen; tooltips | ENCH-10, ENCH-13, ENCH-15, ENCH-08, ENCH-07, ENCH-17 |
| gear ledger, balance.md | 5.x's stronger runeword and glyphword data (Elation, Rejuvenation, Prolongation, Dumplings, Depletion, Ignition) | DE2 |

### Hand-off to other areas

| Area | Changes |
|---|---|
| CRAFT | Rune and glyph crafting schematics (`def_item_crafting_recipes.xml`, 97 units, and Hearts of Stone's `def_item_ep1_crafting_recipes.xml`, 28; their NG+ copies): ingredients ("glyphs and runes require magical and monster components", changelist 657), prices, weights; Runestone and Glyph infusion items; 5.x's enchantment carry-over on crafting (with ENCH-18) |
| ECON | Prices of every rune and glyph item (45 main-game and 12 Hearts of Stone items, their NG+ copies); the other rows legacy changed in `economy_tagmodifiers.csv` (ENCH-02 overrides the whole file and changes only `mod_enchantment` and `mod_removeenchantment`; legacy also changed the enchanter column of `mod_craftitem`, `mod_removeupgrade`, `mod_addslot`, `mod_repair`, `mod_disassemble` and other rows; ECON edits the same copy; audit F6) |
| WGT | Rune and glyph weights (the same items) |
| LOOT | Runes and glyphs sold by smiths and armorers (eight new `loot_include_*_runes` / `_glyphs` lists in `def_loot_shops.xml`); the master enchanter's shop (`_store__LW_DLC_EnchanterMaster`); runes in quest rewards (`rewards.xml`) |
| ITEM | Random enhancements by item level (`AddRandomEnhancementToItem` with a level, called from `OnItemAdded`, `W3Container.RebalanceItems`, `W3MerchantNPC.OnSpawned`) |
| XP | `q702_03b_wight_disenchanted` reward XP |
| UI | The recipe part of `W3TooltipComponent.addComponentsInfo`; the Vitality regen attribute names (strings 2110992156, 2110992157); the character panel's lines with the words (legacy `CharacterStatsPopup.ws`: Placation's toxicity, 592; Rotation's Igni damage and burning chance, 726, 746; Retribution's Quen Discharge, 922, 936) and Heft's damage in `GetOffenseStatsList` (legacy `playerWitcher.ws:8988-8992`; audit F6) |
| FIX | The throw-abort fix in `W3PlayerWitcher.ReactToBeingHit` |
| FOOD | Food and drink durations Dumplings multiplies (`wellFed`, `wellHydrated`); legacy's drinks giving Well Hydrated (`BeverageQuality_1` to `_3`; 5.x's give Well Fed), which makes Dumplings' Well Hydrated rule (audit F4) act; Dumplings' bonus on every edible's tooltip (`W3TooltipComponent.AddBuffStats`, ENCH-06's temporary deviation; audit F6) |
| ALCH | Tawny Owl's level-3 night freeze, which legacy rewrote (`W3Potion_TawnyOwl.OnTimeUpdated`; Prolongation's term is ported on 5.x's; ENCH-09; audit F6) |

### Save impact

None expected: word and rune values come from the definitions (an enchanted item holds the word's ability name), the activation rules and costs are computed live, and Invigoration's and Prolongation's effects are removed at load. The enchanter's level is quest state: a save keeps the levels already bought, and later upgrades cost legacy's price. Removing the mod mid-playthrough is not supported ([save compatibility](../feature-mapping.md#save-compatibility)); as facts (expected): Invigoration and Prolongation buffs saved in combat would name effect types 5.x does not have.

### Area decisions

The owner's decisions (project owner, 2026-10-19):

| # | Question | Decision |
|---|---|---|
| DE1 | When runewords and glyphwords work (ENCH-01) | **Legacy:** runewords only from the drawn sword (Preservation and Dumplings from an equipped one); glyphwords only from the chest armor |
| DE2 | Words 5.x made stronger (Elation, Rejuvenation, Prolongation, Dumplings, Depletion, Ignition) | **Legacy's numbers and mechanics** for all six |
| DE3 | Enchanter costs and schematics (ENCH-02) | **Legacy's costs in full**, including the four binary scene and quest file edits. If those prove impractical: legacy's schematics and word requirements with 5.x's upgrade prices, recorded as a deviation and reported to the owner |
| DE4 | 5.x's conveniences (ENCH-18): the enchantment kept when crafting the next tier; enchanted items not dismantled (nor their sockets removed) | **Keep 5.x's**, recorded as deviations confirmed by the owner |
| DE5 | Deflection (ENCH-11) on 5.x's thrown boulders | **Legacy's rule, applied to 5.x's boulders too** |
| DE6 | 5.x's dead `Glyphword 22 Bonus` free cast (ENCH-18) | **Removed** from the port's sign-cost code (`skills/rageManagement.ws`), closing SKL's open check; 5.x's other dead references stay |
| — | Levity and Balance also change the cost of item use, sprinting and jumping in legacy's code, against the changelist's "melee actions" ([contradiction](../open-questions.md#legacy-data-vs-changelist)) | **Legacy's code**; their descriptions, in all 9 languages, say "physical actions" instead of "melee actions" (the owner's wording) |

### Port order

Porter's plan (2026-10-19), one slice per feature or pair, each with its descriptions (ENCH-17) and tests, both trees where signs or Whirl and Rend are involved:

| # | Slice | Ends |
|---|---|---|
| 1 | ENCH-01 activation rule (`HasRunewordActive`, `HasGlyphwordActive`) and the generated `gm_ench.xml` skeleton: **done** 2026-10-19 | — |
| 2 | ENCH-10 Levity, Balance, Heft: **done** 2026-10-19 | ARM-02's DA7 deviation; DMG's Heft term |
| 3 | ENCH-16 runes and glyphs: **done** 2026-10-19 | — |
| 4 | ENCH-12 Retribution, ENCH-15 Entanglement and Protection: **done** 2026-10-19 | SKL-10's and SKL-11's glyphword deviations; DMG's Glyphword 5 deviation |
| 5 | ENCH-13 Depletion, Rotation, Ignition, Eruption: **done** 2026-10-19 | SKL-09's Glyphword 7 deviation; DMG's Rotation term |
| 6 | ENCH-14 Usurpation, Beguilement, Possession: **done** 2026-10-19 | — |
| 7 | ENCH-11 Deflection: **done** 2026-10-19 | — |
| 8 | ENCH-03 Replenishment, ENCH-04 Severance: **done** 2026-10-19 | DMG's Severance term |
| 9 | ENCH-05 Invigoration: **done** 2026-10-19 | DMG's two Runeword 4 deviations; MUT-02's deviation |
| 10 | ENCH-07 Placation, ENCH-08 Rejuvenation and Elation: **done** 2026-10-19 | — |
| 11 | ENCH-09 Prolongation (on 5.x's potion timers; ALCH not ported): **done** 2026-10-19 | — |
| 12 | ENCH-06 Preservation and Dumplings (Dumplings' durations with FOOD): **done** 2026-10-19 | — |
| 13 | ENCH-02 enchanter costs and schematics: **done** 2026-10-19 | — |
| 14 | ENCH-18 per DE4 and DE6; leftover ENCH-17 texts: **done** 2026-10-19 | SKL's Glyphword 22 open check |
