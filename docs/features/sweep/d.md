# Sweep D: attributed but not ported (2026-11-02)

Sweep D's batch is the units that **are attributed** but whose note says part of the change is not ported, handed to another area, or waiting for one. The question for each: did the port take it, was it dropped or kept for later by a recorded decision, or did it fall between two areas? Offline analysis only, against 5.x-GM `b3ec3609`, `legacy-GM`, `vanilla-5.x` and master's 1.32. **No attribution row is edited**: the stale notes are listed in [Stale notes](#stale-notes-for-the-parent-to-fix) for the parent to fix.

Method:
- every `attribution.csv` note matching "not ported", "LATER", "later", "hand-off", "handed", "until <AREA>", "kept 5.x's", "TODO", "NEW", "gap", "for <AREA>" or "belongs to <AREA>": 254 rows;
- every note naming an area that was never mapped (FIX, HORSE, GEN, DEP, INFRA, MISC);
- `deviations.py` (all deviations and the unconfirmed ones);
- every feature doc's "Hand-off to other areas" table and "Later" list;
- the changelist's "General player abilities", "Horse combat" and "Bugfixes" sections, against the docs and 5.x-GM's code (`modGhostMode/scripts/local/gm/`, the DLC's `gm_*.xml`).

Unattributed units: unchanged by this sweep, which attributes nothing. The committed coverage.md says 335; regenerated on this branch, `change_units.py` says 332 (21,083 of 21,415 attributed), the same before and after.

## Summary

| Category (common brief) | Groups | Rows |
|---|---|---|
| 1. Existing feature, ported (the note is stale) | 11 | 50, plus 812 rows whose "weight: WGT" or "price: ECON" note names a feature the row lacks |
| 2. Existing feature, not ported (a gap) | 7 | 9 attributed rows; more in unattributed units |
| 3. New feature (an area never mapped) | 3 areas: FIX, HORSE, GEN | the units are mostly unattributed (sweeps A to C) |
| 6. Debug or dev only (not ported, recorded) | 1 | 32 |
| 7. No effect (not ported, recorded) | 9 | about 110 |
| 8. Unclear (needs the owner) | 6 questions | — |

- **Temporary deviations:** none left. `deviations.py`: 131 deviations, 0 temporary. Every "until <AREA>" deviation in the feature docs names an area that is now ported, and that area's doc says it ended it.
- **Unconfirmed deviations:** 6, all porter's calls from STAM and DEF (2026-10-03 and 2026-10-04) that the owner never confirmed. Listed in [Owner questions](#owner-questions), Q7.

## Gaps: what a legacy player had that the port lacks

Each gap is checked in 5.x-GM's code, so the note is not just stale. The legacy lines are on `legacy-GM`; the 5.x lines are in `vanilla-5.x`'s copies under `modGhostMode/scripts/game/`, which 5.x-GM leaves untouched.

| # | In play terms | Evidence | Proposed home and action |
|---|---|---|---|
| G1 | **A hit stops a bomb throw or a crossbow aim only when Geralt is really throwing, and only if the hit plays a hit animation.** In legacy, a hit with no hit reaction (`EAHA_ForceNo`, e.g. during a special attack) does not cancel the throw. The port keeps 5.x's rule: any damaging hit cancels it. | Unit `W3PlayerWitcher.ReactToBeingHit` (ENCH-16; note: "also the throw-abort fix (FIX)"). Legacy: `if(IsThrowingItem() \|\| IsThrowingItemWithAim())` and `GetHitAnimationPlayType() != EAHA_ForceNo`. The port's `@replaceMethod` (`enchantments/runesGlyphs.ws:39-56`) keeps 5.x's body there unchanged. | FIX, a new feature (FIX-NEW1). Port it as two marked lines in ENCH-16's replacement. |
| G2 | **Generic travelling merchants always open their shop and show a map pin** (Wolfmark's fix, changelist 37). | Unit `W3MerchantNPC.OnSpawned` (ITEM-06 LOOT-05 ECON-08; note: "the generic merchants fix by Wolfmark (FIX)"). Legacy's `// WMK` block copies the scene's `GetRequiredPositionTags()` onto the NPC. 5.x only adds `ShopkeeperEntity` (5.x `merchantNPC.ws`, `OnSpawned`). None of the port's three wrappers (`econ/merchants.ws`, `items/itemGeneration.ws`, `loot/balisse.ws`) does it; `GetRequiredPositionTags` appears nowhere in `local/gm`. Whether 5.x still has the bug is **unverified**. | FIX-NEW2. Check in game whether 5.x's generic merchants still fail; if they do, port it as a wrapper. |
| G3 | **NPC arrows and projectiles stop at doors, fences, debris, destructibles, rigid bodies and platforms** (W3EE's collision fix, changelist 46). Also, **the arrow in Yoana's armor test hits Geralt** (bugfix 144: `sq108_heavy_armor` makes a null victim Geralt). In the port, arrows pass through those objects (5.x added only `Foliage`), and the quest arrow can miss. | Unit `W3ArrowProjectile.OnProjectileCollision` (DEF-08 SKL-05 MUT-11 ENCH-11; note: "sq108 and collision FIX"). The port's `defense/arrowParry.ws:6-8` says "Legacy's other changes here (collision groups, …) belong to FIX". The port's body (line 53) has 5.x's three groups. Also the unattributed units `CBTTaskShoot.ShootProjectile` and `CBTTaskProjectileAttack.Initialize` (the same groups). | FIX-NEW3: all three functions, plus the sq108 line. |
| G4 | **An active Quen shield is gone after loading a save.** Legacy removed 5.x's `RestoreQuen` on load ("params aren't saved properly anyway") and zeroes the saved values. The port restores the shield (5.x). SKL audit F16 then made the restored Quen free, on the assumption that legacy restores it on load. | Unit `W3PlayerWitcher.OnSpawned` (16 features; note: "… FIX"). Legacy `playerWitcher.ws`, `OnSpawned`: the `/*if(spawnData.restored) RestoreQuen…*/` block. 5.x's `OnSpawned` still calls `RestoreQuen(savedQuenHealth, savedQuenDuration)`, and nothing in `local/gm` removes the call. | SKL-11. **Unclear (Q4):** port legacy's rule, or keep 5.x's as a recorded deviation. Either way, record it. |
| G5 | **Vitality regeneration stuck after a fistfight comes back on load** (bugfix 139: legacy calls `ResumeHPRegenEffects('FistFightMinigame')` in `OnSpawned`). | Unit `W3PlayerWitcher.OnSpawned`. Legacy `playerWitcher.ws:395`. Absent from `local/gm`. 5.x pauses and resumes it in `actor.ws:656/662`, as 1.32 does, so the rare bug the changelist names may remain. | FIX-NEW4. One line in the existing `OnSpawned` wrapper. |
| G6 | **Wolf liver in a quick slot stays there after a load.** Legacy disabled 5.x's `HACK_UnequipWolfLiver`, because Wolf liver became food. In the port, Wolf liver is food (FOOD-04, FOOD audit F1), but 5.x's hack still runs on every load. It unequips Wolf liver from potion slots 1 and 3 (or 2 and 4) **and whatever is in the paired slot**. | Unit `W3PlayerWitcher.OnSpawned`. Legacy: `//HACK_UnequipWolfLiver(); //modSigns`. 5.x `playerWitcher.ws:227` calls it and `604-636` defines it. Nothing in `local/gm` overrides it. Inferred from the code, **not tested in game**. | FOOD-04 (a gap in a signed-off feature). Port it as an empty `@replaceMethod` of `HACK_UnequipWolfLiver`, and check it with a scripted load. |
| G7 | **The Caretaker's Shovel (Hearts of Stone's player weapon) leeches health from Essence monsters too.** Vanilla's leech in `CR4Player.OnProcessActionPost` reads the player's `UsesEssence()` instead of the victim's, so it gives nothing against specters. Legacy moved the leech into the victim's `CActor.OnTakeDamage` and reads the victim's stat. | Unit `CActor.OnTakeDamage` (STAM-06 STAM-08 MUT-10 ARM-13 ALCH-12 ALCH-13 EFX-09; note: "SWD: Caretaker Shovel"). Legacy `actor.ws:2647-2662`. The port's replacement (`mutations/takeDamage.ws`) has no `lifesteal` code. The unattributed unit `CR4Player.OnProcessActionPost` (legacy comments vanilla's block out) belongs with it. SWD's doc never mentions the shovel. | SWD-03 (relic and unique weapons), or FIX. Port both hunks together. |
| G8 | **Geralt has no natural poison or bleeding resistance.** Legacy sets `ConGeralt`'s `poison_resistance_perc` and `bleeding_resistance_perc` from 0.25 to 0 (regular and NG+); the changelist does not mention it. In the port, Geralt resists 25% of both, as in 5.x. | Unit `ConGeralt` (STAM-03 STAM-04 STAM-06 SKL-07 OPT-02; note: "poison/bleeding resistance … belong to other areas, not mapped yet"). DMG's hand-off table lists it for GEN (`dmg.md:513`). The port's four `ConGeralt` extends (`abilities/gm_stats.xml`) set none of it. Its third item, the doubled `*_attack_focus_drain`, has **no effect**: legacy's code no longer reads those nodes (`damageManagerProcessor.ws:182-191` commented out; SKL-07's drain by share of maximum health replaces them). | GEN-NEW1 (or OPT-02's `ConGeralt` extend). **Q3.** |
| G9 | **NG+ only: Hearts of Stone's Censer works as a censer in the UI.** Legacy fixed the NG+ copy's `UI_OilLamp` tag to `UI_Censer`, as the regular copy has it. The port's NG+ entry is whole (`replace`) with 5.x's `UI_OilLamp`. | Unit `items_plus/def_item_misc.xml::item:Censer` (WGT-05, weight only). WGT's hand-off: "UI (or ITEM): the NG+ Censer's `UI_Censer` tag". Neither UI nor ITEM took it. Port: `items_plus/gm_econ.xml:4412-4422`. | ITEM-01 (or UI). One tag in `gen_econ`'s whole NG+ entry (item_layer). |
| G10 | **NG+ only: the Hearts of Stone wedding suit's bare-hands variant has its hands.** Legacy defined the missing NG+ `Body palms cut` item, which the NG+ suit's variants name. Without it, the variant's hands item is missing; the visible effect is **unverified**. | Unit `Body palms cut` (ITEM-01; note: "for ITEM, not ported … no ITEM feature covers it yet"). 5.x's NG+ `def_item_armor.xml` names it twice and defines it nowhere in NG+. | ITEM-01: port it (one new NG+ entry). **Q5.** |

Gaps found in units outside this batch (unattributed, sweeps A to C), listed here because another area handed them off and nobody took them:

| # | In play terms | Evidence | Proposed home |
|---|---|---|---|
| G11 | **Quest items lose their Quest tag once their quest is over**, so they can be sold or dropped (bugfix 150). This covers about 60 items: keys, notes, masks, the Beauclair suit, journals and the Zmora trophy, checked each time the inventory opens. Also **an autosave at "Family Issues"** (`FamilyIssuesAutosave` from `CR4ScriptedHud.OnQuestUpdate`). | `scripts/fixes/gm_bugfixes.ws::FixQuestItems`, `fixquestitems`, `FamilyIssuesAutosave`, `SQ102Finished` (unattributed). Handed to FIX by ALCH, CRAFT, TRPH, UI and WGT. TRPH-02 took only Camerlengo's Seal's unconditional tag removal (`gm_trph.xml:137`). | FIX-NEW5 |
| G12 | **Horse trampling gives Geralt no adrenaline.** Legacy removed `attack_speed_based`'s `focus_gain` 0.025; it is the horse's collision attack (`horseComponent.ws:876`). The port's `gm_adrenaline.xml` zeroes `attack_light`, `attack_heavy`, `attack_heavy_special` and `attack_super_heavy`, but not `attack_speed_based`. | `basic_attacks.xml` units (4, unattributed). AI's hand-off to SKL ("`attack_light` and `attack_speed_based` lose their `focus_gain`", `ai.md:1110`). SKL never listed it. | SKL-07 (one more extend in `gm_adrenaline.xml`) |
| G13 | **Ciri is invulnerable during her special attack** (bugfix 113). | `W3ReplacerCiriStateCombatSword.SpecialAttackCleanup` (unattributed), EFX's hand-off to FIX. | FIX-NEW6 |
| G14 | **Horse combat as legacy** (changelist 485-490): a horseback hit adds the weapon's own damage × speed/4 (up to ×2 at full speed) instead of 5.x's flat direct bonus, and no longer drains 100% of the enemy's stamina; Axii from horseback costs 50 stamina (adrenaline with Perk 10) and holds the horse 0.5 s per tick. Only the 3× light-attack cost is ported (STAM-03). | Units in `useVehicle.ws` (`W3VehicleCombatManagerStateSwordAttack.DealDamageToHostiles`, the five `W3VehicleCombatManagerStateCastSign` units; unattributed). Handed to HORSE by STAM, SKL, SWD and DMG. 5.x `useVehicle.ws`: `actor.DrainStamina(ESAT_FixedValue, 100, 1)`, `baseDamage * MaxF(1.1 + speed, 1)`. | HORSE, a new area (HORSE-NEW1, HORSE-NEW2). **Q2.** |

## Areas never mapped

| Area | What legacy changed there | State in the port |
|---|---|---|
| `FIX` Bugfixes | The changelist's "Bugfixes" section (lines 31-184, about 90 items), the three community fixes in `gm_bugfixes.ws` and the W3EE collision fixes | Most fixes went with their feature and are ported. 41 bugfix lines are referenced by number in the docs, and others by name (DMG-15's human armor, ALCH-16's stuck oils, FOOD-03's regen restart, SKL-12's dismemberment, AI-14's fiends). Not ported: G1 to G3, G5, G11, G13. **Lines no doc names and this sweep did not trace:** 35 (alt Aard water ripple), 36 (Ciri's cutscene sword), 43 (KoalaNalle's w2ent fixes), 86 (Vivienne's feather), 136 (Dao AoE radius: the `elemental_dao*`/`golem*` entities in coverage), 137 (Polish ingredient name), 138 (a Russian description), 152 (Evil Keira and Geralt doppelgangers on Essence), 154 (an NPC invulnerable after dropping a shield), 166 (Preservation removed after cutscenes), 177 and 178 (pheromone and antidote potion sounds). AI-14 has 44 (sorceress hand fx, "in 5.x"). The FIX area needs its own short mapping pass over this list. |
| `HORSE` Horse combat | Changelist 485-490, horse Axii, horse panic | Ported: the 3× cost (STAM-03); the horse sprint cost and blinders (WGT-06, PW9); Mutagen 25's horseback attack power removed (ALCH-12, which covers DMG's "horse-speed attack power" hand-off: 5.x's horse block in `GetPowerStatValue` holds only that). Not ported: G14 and G12. |
| `GEN` General player abilities | Changelist 469-480 | Every line is ported elsewhere: level-ups 50 Vitality only (XP-08), base regen 0 (OPT-02), headshots and backstabs +25% (`damage/formula.ws:541`), adrenaline only for damage dealt and the 0.01-per-1% loss (SKL-07, `defense/processAction.ws:156`), the fistfight health (AI-20). Left: G8, which the changelist does not mention. |
| `DEP` | 154 SI and 38 CPB units, all unattributed | For sweeps A to C. Nothing in this batch. |
| `INFRA` | No unit claims it | Shared code; no legacy change to map. |
| `MISC` | `enabledeletedscene` (unattributed, listed in misc.md) | For the unattributed sweeps. |

## Hand-offs between areas

Every mapped area's "Hand-offs received" table places what other areas handed to it. Checked against 5.x-GM:

- **Handed to areas mapped since, and taken:**
  - DMG and STAM to SKL, ALCH, ARM, ENCH, ITEM, EFX, AI, XP and DIFF;
  - ALCH to CRAFT, LOOT, FOOD, EFX, XP and UI;
  - every area's weights to WGT and prices to ECON (checked below);
  - AI's `LATER` nodes: `gen_ai.py` has every feature of its `LATER` table in `PORTED` (AI-08, AI-12, XP, WGT), and `gen_ai_ent.py` has AI-08, AI-14 and AI-20, so no `LATER` node or entity ability is waiting. The only one left is AI-19's `Shovel _Stats` weight, not ported by the owner's decision (WGT audit F4).
- **Handed to FIX, HORSE or GEN:** never taken; see the gaps and [Areas never mapped](#areas-never-mapped).
- **Handed around between areas, nobody took it:**
  - the NG+ Censer tag (WGT to UI or ITEM; G9);
  - `Body palms cut` (ECON to ARM or MISC, then WGT to ITEM; G10);
  - `attack_speed_based` (AI to SKL; G12);
  - the siren crawl finisher (AI to SKL): 5.x's `syncManager.ws:502` already reads `man_ger_crawl_finish`. **Built into 5.x**; the unattributed unit `SetupSimpleSyncAnim` is no-effect or DEP-like (for sweeps A to C).
- **Circular, but done:** ALCH-08's notes hand the pheromone potions' and Killer Whale's quality 4 to ITEM, and ITEM's audit hands it back to ALCH. Both carry it: `gm_alch.xml:324-356` gives every `PheromonePotion*_1`, `KillerWhale_1` and `PopsImmunity` quality 4.
- **The Pheromone bomb's `StaminaDrowner_Stats`:** **no effect, nothing to port.** `FeromoneBomb` names it in 1.32, legacy and 5.x alike, and none of the three defines it. It is a vanilla dangling reference that legacy did not touch. `dlc_conflicts.py` lists it "for ITEM"; that label can go.
- **Weights and prices other areas called "not ported":**
  - 495 rows say "weight: WGT" and 317 say "price: ECON" without carrying a WGT or ECON feature.
  - Checked against master and `legacy-GM`: 359 of those weights and 103 of those prices are unchanged by legacy. The note is the ARM, CRAFT or SWD generator's template text.
  - About 130 weights and 156 prices belong to items legacy added (the craftable quest armors, the Kaer Morhen set, …). Those items' areas write them whole with legacy's weight and price (e.g. `gm_item.xml:13430` price 550, `:142` weight 6.5; `gm_arm_kaer_morhen.xml:253` 1700).
  - 6 are entries legacy removed or moved (the starting `Autogen` boots and pants abilities; Wolf liver moved to the edibles).
  - **No gap.**

## Later lists

| Doc | Item | Why it is later | Who decided |
|---|---|---|---|
| wgt.md:117, 476 | The loot window showing each item's weight; the load recomputed when the reduction option changes | An improvement over legacy, which shows 0 (legacy behaviour first) | **Not stated** |
| xp.md:671 | NG+ kill experience on the base game's levels (DX3 (b)); a new-tree line in the level texts (DX5 (b)) | Stated | The owner, 2026-10-31 |
| xp.md:671 | The free DLCs' quest levels reloaded when "Disable quest levels" is turned off | **Not stated** | **Not stated** |
| ench.md:337 | Prolongation's bonus removed with its own ability (legacy keys it on Runeword 1) | A legacy quirk, ported as is | **Not stated** |
| craft.md:281 | "Silver Ingot" vs "Silver ingot" in two Knight Geralt pants' parts | A legacy data quirk (audit F9) | Implied by the audit; **no name** |
| alch.md:557 | Werewolf's HUD flag | The quirk is ported as legacy's (alch.md:547) | **Not stated** in the Later line |
| econ.md:950 | Blood and Wine price factors; `mq2052`'s haggling | Open investigations, not improvements (vanilla behaviour in 1.32 and 5.x) | **Not stated**; these fit better in open-questions.md |
| ai.md:1178 | All done | — | — |
| opt.md:395, trph.md:373, and every other "Later: —" | Empty | — | — |

Suggestion (for the docs' owners, not edited here): each Later item ends with "(why; who, date)", as the deviation bullets do.

## Stale notes for the parent to fix

| Rows | Unit(s) | Note says | Should say |
|---|---|---|---|
| 14 | The entity files `q104_wild_hunt_boss`, `q704_ft_goldilocks_bear_01/02`, `q604_olgierd_thugs`, `enemy_2handed_sword`, `mq1005_scavenger_boss`, `mq0005_arsonist`, `mq2038_gundar`, `mq2038_shieldmaiden`, `sergeant`, `sq301_wh_boss`, `sq301_wh_rest`, `_rest2`, `_rest3` (`::<file>`) | "entity abilities of later features kept 5.x's until then (AI-08 / AI-14 / AI-20 …)" | "entity abilities legacy's (AI-08 since slice B1, AI-14 since B3, AI-20 since C3; `gen_ai_ent.py`)" |
| 1 | `menu/modSignsConfig.xml::*` | "OPT-03 to OPT-06: the gameplay and QoL options not ported yet" | "OPT-03 to OPT-06: the gameplay and QoL options (ported 2026-11-02; `GMVersion` and instant casting not ported, PO2 and DO5)" |
| 2 | `def_item_edibles.xml` (both folders) `Free nilfgaardian lemon` | "FOOD: its drink abilities …, 5.x until FOOD (KEEP_5X)" | "FOOD-04: its drink abilities legacy's (ended CRAFT-07's deviation, 2026-10-24)" |
| 1 | `guiTooltipComponent.ws::W3TooltipComponent.AddItemStats` | "the potion toxicity line without /max and the Adaptation reduction wait for UI" | "… ported (UI-06, `alchemy/tooltips.ws:581-631`)" |
| 1 | `inventoryMenu.ws::CR4InventoryMenu.UnequipItem` | "(not ported: ITEM audit F1)" | "(ported: ITEM audit F1, fix slice A, `items/repair.ws` `gmForceUnequip`)" |
| 1 | `effectManager.ws::W3EffectManager.InternalAddEffect` | "ALCH-09: Chort … (not ported: ALCH audit F3)" | "ALCH-09: Chort turns a heavy knockdown into a stagger too (ALCH audit F3, fix slice C)" |
| 16 | `def_item_alchemy_potion.xml` (both folders) `KillerWhale_1` to `_3`, `PheromonePotion*_1`, `PopsImmunity` | "(quality 4: ITEM hand-off)" | "(quality 4, in ALCH-08's whole entries)" |
| 1 | `npc.ws::CNewNPC.CalculateExperiencePoints` | "XP's (not mapped yet; UI audit F1)" | Drop "not mapped yet"; XP-04 carries it |
| 2 | `geralt_stats.xml` (both folders) `ConGeralt` | "its vitality regen, poison/bleeding resistance and adrenaline gain changes belong to other areas, not mapped yet" | "Vitality regen OPT-02; the `*_attack_focus_drain` nodes unread by legacy's code (no effect); poison and bleeding resistance 0.25 → 0 not ported (sweep D G8)" |
| 8 | `ProcessActionReaction`, `ShouldEnableFinisher`, `IsAxiiInstakillTarget`, `GetAxiiInstakillChance`, `CanDismember`, `CanDismemberAliveTarget`, `CanPerformFinisher`, `CanPerformFinisherOnAliveTarget` | "GEN/FIX: finisher, dismember" or "GEN finishers/dismemberment in the same functions" | "finishers and dismembering of living targets ported with SKL-12 and MUT-05 (`skills/axii.ws`, `mutations/deadlyCounter.ws`)" |
| 1 | `actor.ws::CActor.OnTakeDamage` | "FIX: immortal clamp, LastBreath; SWD: Caretaker Shovel; UI: combat log" | "LastBreath: AI-17 and EFX-09; immortal clamp: in 5.x's place (`damage/pipeline.ws`); combat log: ALCH-12; Caretaker Shovel: not ported (sweep D G7)" |
| 1 | `merchantNPC.ws::W3MerchantNPC.OnSpawned` | "the generic merchants fix by Wolfmark (FIX)" | Add "not ported (sweep D G2)" |
| 1 | `playerWitcher.ws::W3PlayerWitcher.ReactToBeingHit` | "also the throw-abort fix (FIX)" | Add "not ported (sweep D G1)" |
| 1 | `arrowProjectile.ws::W3ArrowProjectile.OnProjectileCollision` | "q108 ITEM, sq108 and collision FIX" | "q108's bounce chance ARM-01; sq108 and collision groups not ported (sweep D G3)" |
| 1 | `playerWitcher.ws::W3PlayerWitcher.OnSpawned` | "… FIX; …" | "FIX: fistfight regen resume, Quen not restored, Wolf liver hack off: not ported (sweep D G4 to G6)" |
| 812 | Rows whose note says "weight: WGT" (495) or "price: ECON" (317) without the feature | Template text | Optional: drop the phrase where legacy changed neither ([above](#hand-offs-between-areas)) |

Doc text, also stale:
- `ui.md:641` (OPT row: "the option strings not ported yet") and `opt.md:325` list strings that are now decided (PO2, DO5).
- `trph.md:329`, `wgt.md:418` and `alch.md:832` ("FIX or ITEM", "FIX (or TRPH)", "FIX") point at an area that does not exist yet.
- `ai.md:363` ("all but WGT's legacy's since"): WGT is ported now.

## Debug and no-effect units, not ported by a recorded reason (category 6, 7)

Confirmed sound; nothing to do:
- **Debug only (32 rows):** legacy's debug commands `addcraftedarmor`, `addmediumarmor`, `addlightarmor`, `allsets`, `addset_internal`, `addLynxArmors`, `addGryphonArmors`, `addBearArmors`, `addviperset`, `addViperArmors`, `addkmset` and `ciriquests`. The port has its own `gmtest_*` tests.
- **No effect:**
  - UI-17's 81 unused string rows and the unused stash code;
  - setters and helpers no legacy code calls (`SetCanBeDodged`, `GetVitalityDamageTotal`, `SignSkillToSignType`, `GetTotalArmorWeight`, `GetGMVersion`);
  - DEF-06's stun blocks (the stun is only put on enemies);
  - DEF-07's `HasRecentlyCountered` (5.x's skills use it);
  - STAM-09's `GetWhirlFocusCostPerSec`;
  - SKL-16's Synergy save migration;
  - OPT-01's "Mods" label (5.x's `panel_mods`);
  - FOOD-08's `attribute_name_staminaRestore`;
  - AI-19's `Shovel _Stats` weight (owner, 2026-11-02).
- **Legacy save migration in `OnSpawned`** (the `new_game_started_with_GM_40` fact and `ApplyPatchFixes`' `modSigns_*Introduced` steps): no effect on 5.x, since no legacy Ghost Mode save loads on 5.x (save compatibility).

## Owner questions

- **Q1. A FIX area.** Map the changelist's "Bugfixes" section as its own small area: G1, G2, G3, G5, G11, G13 and the untraced lines listed under [Areas never mapped](#areas-never-mapped).
  - (a) map and port it as legacy;
  - (b) port only what still happens on 5.x (G2 and G5 need a check first);
  - (c) leave it.

  Recommendation: (a), checking each fix against 5.x first. These are small script fixes.
- **Q2. A HORSE area.**
  - (a) map and port legacy's horse combat (G14, with G12);
  - (b) keep 5.x's horse combat as a recorded deviation.

  Recommendation: (a). It is a changelist section of its own (485-490), and the 3× cost already ported assumes legacy's damage model.
- **Q3. Geralt's base poison and bleeding resistance** (G8).
  - (a) legacy's 0;
  - (b) 5.x's 25%, a recorded deviation.

  Recommendation: (a): add it to OPT-02's `ConGeralt` extend. It is an undocumented legacy change, so it also goes on the list of contradictions between legacy's data and its changelist.
- **Q4. Quen after loading a save** (G4).
  - (a) legacy's: the shield is gone;
  - (b) 5.x's: restored for free (today's behaviour), a recorded deviation.

  Recommendation: (a). It is a one-line change to the `OnSpawned` wrapper, and it makes SKL audit F16's free restore moot on that path.
- **Q5. `Body palms cut` and the NG+ Censer tag** (G10, G9). These are NG+ only, and the port carries NG+ without testing it.
  - (a) port both (one entry and one tag);
  - (b) drop them, recorded.

  Recommendation: (a).
- **Q6. Wolf liver and the quick slots** (G6). Port legacy's removal of 5.x's hack, or keep the hack as a recorded deviation? Recommendation: port it, with a scripted check. As things stand, the hack can also empty an unrelated potion slot.
- **Q7. The six porter's calls never confirmed** (STAM-03 ×2, STAM-04, STAM-07, DEF-06, DEF-07; `deviations.py --unconfirmed`). Confirm or reject them. Recommendation: confirm. They are signed-off areas, and none has a save impact.

## Seen outside the batch

- The Later lists need "who and why" (above).
- `econ.md`'s Later list holds open investigations; they would fit better in `open-questions.md`.
- `5.x-file-status.md` and `misc.md` were not checked for staleness.

## Owner's decisions (2026-11-02)

The owner chose every recommendation of sweeps B, C and D ("all as recommended"):

- Small gaps in existing features, fixed in one round: the golem/elemental/Ifryt slam radius at legacy's 3 m (all 22 files), the NG+ DLC armour sets at full armour, NG+ Death March followers at ×2.5 Vitality, no adrenaline from horse trampling.
- The Caretaker's Shovel heals on every enemy type (legacy's fix); Quen is removed on load (legacy); Geralt's base poison and bleeding resistance 0 (legacy; also a data-vs-changelist contradiction); 5.x's Wolf liver load fix removed; the NG+ `Body palms cut` item and the Censer's tag ported.
- Hair: Yoana's armour gets Geralt's default hair (legacy) now; the grandmaster Feline armour's hair extensions wait for an on-screen look (an empty `item_extension` replace is untested).
- FIX (legacy's bug fixes no area took) and HORSE (horseback hits, horse Axii's stamina) are mapped as areas of their own, each fix checked against 5.x first.
- The six porter's calls not confirmed before (DEF-06, DEF-07, STAM-03 ×2, STAM-04, STAM-07) are confirmed.

**Done** (fix round fix3, 2026-11-02; gm/fix3 `51bce9eb`, verified on the area build in both trees, regression 1,531 and 157): the slam radius (AI-14), the NG+ DLC armor (ARM-01) and followers (AI-04), horse trampling (SKL-07), the Caretaker's Shovel (SWD-03), Quen on load (SKL-11), Geralt's base resistances (OPT-02), the Wolf liver hack (FOOD-04), `Body palms cut` and the Censer tag (ITEM-01), Yoana's hair (ARM-01; the Feline extensions a temporary deviation), the stale notes above and B's two row suggestions, and the six porter's calls confirmed. FIX and HORSE: their own mapping.
