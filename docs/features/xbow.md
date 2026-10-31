# XBOW: crossbows and bolts

Geralt's crossbows and bolts, and the bows and crossbows of NPC archers: what a bolt deals, pierces and inflicts, what a crossbow adds, how critical hits and headshots work for bolts, and what an NPC's arrow deals. Ghost Mode's changelist has its own section (660–671): "You can now have a decent crossbow build, if you invest into crossbow skills. If not, it's still a utility weapon to bring down flying enemies and apply special effects from bolts": non-aimed shots deal 50% less damage, damage from own bolts is no longer halved, bolts and crossbows reworked ("damage and effects tweaked"), the explosive bolt's explosion range 5 → 3, headshots ignore armor and resistances and add 50% crit chance, bolts can be sold and bought at a reasonable price but not dismantled. The bugfix list adds the last bolt of a stack (161) and explosive bolts hitting the same target up to three times (162). Sources: those lines, every hand-off to XBOW ([hand-offs received](#hand-offs-received)), and the code and data, which have more than the changelist (NPC bow damage, the crossbows' crit rules, NPC archers' stamina).

**What 5.x did in this area** (from `vanilla-5.x`, unverified in game). The data is 1.32's: every bolt, crossbow (the Hearts of Stone, Blood and Wine and free-DLC crossbows included) and NPC bow has 1.32's values in `def_item_bolts.xml`, `def_item_weapons_crossbow(s).xml`, `dlc13_items.xml`, `def_item_npcweapons.xml`, regular and NG+ (equal in both); 5.x added no crossbow or bolt. The explosive bolt's entity is 1.32's (5 m blast). The code changed in five places: a bolt or arrow counts as a headshot when the bone it hits has `head`, `neck` or `hroll` anywhere in its name (and `pelvis` on humans), where 1.32 needed those exact bone names (`W3BoltProjectile.ProcessDamageAction`, `W3ArrowProjectile.ProcessDamageAction`); a quick shot at a large monster with targetable parts flies at the part Geralt targets, not at its torso (`ReleaseProjectiles2`, `HasVirtualControllerTarget`); a bolt shot while diving gets the underwater range and 60% speed, otherwise the full range (1.32: the full range while swimming, the underwater range otherwise); the controller vibration on firing is gone; the new tree's crossbow skills (Lightning Reflexes' headshot damage and instant kill, Maiming Shot's arming, Anatomical Knowledge's silver-sword damage on bolts), which SKL-06 removed. The underwater bonus (×3, ×7 in NG+), the bolt minimum of 1 damage, the effect-chance rule and the split and explosive bolts' code are 1.32's.

**How legacy Ghost Mode implements it.** Data: the fourteen bolt abilities and twelve bolt items (`def_item_bolts.xml`), the quest bolt (`q704_vampire_lure_bolt`), ten crossbow abilities, the two Toussaint crossbow abilities and the two quest crossbows that use them, the three free-DLC and two Ofir crossbow abilities, eight NPC bow and crossbow abilities, each regular and NG+ (equal), and the explosive bolt's entity (`explosive_bolt.w2ent`). Scripts: the bolt's hit (`W3BoltProjectile.ProcessDamageAction`, `OnProjectileInit`, a new field, a line of `ReleaseProjectiles2`), an NPC arrow's damage (`W3ArrowProjectile.ProcessDamageAction`, new `GetHeldWeaponDamage`), the crit functions (`CR4Player.GetCriticalHitChance`, `GetCriticalHitDamageBonus`), the headshot signal (`ProcessAction`, `ProcessCriticalHitCheck`, `GetDamageResists`), the NPC shot task (`CBTTaskShoot.IsAvailable`, `CBTTaskShootDef`).

Unit lists: [attribution.csv](attribution.csv): mapped 2026-10-25 from the changelist, every hand-off to XBOW, a field-by-field comparison of every bolt, crossbow and NPC bow entry legacy changed (master against `legacy-GM` and `vanilla-5.x`), every unit in `scripts/game/projectile/` and the bow and crossbow entity files, and sweeps (`unit_sweep.py --unattributed` for crossbow, bolt, bow, headshot, underwater, aim, xbow, `W3BoltProjectile`, ammo): **112 units** newly carry an XBOW feature (7 script units, 52 XML units and their 52 NG+ copies, 1 binary file; the NG+ copies are attributed with the regular entries' rows), and 10 already attributed units get an XBOW feature beside their others (the two quest crossbows' items and their NG+ copies, the two crit functions, `ProcessAction`, `ProcessCriticalHitCheck`, `GetDamageResists`, `ReleaseProjectiles2`). Units that only look like crossbow units are handed off ([hand-off](#hand-off-to-other-areas)): monster projectiles, the Skellige and quest archers' levels, the flyers' forced landing, the projectile collision fixes, prices and weights. Unattributed units: 5,394 before, 5,282 after. Port status: **mapped** (2026-10-25), the owner's [area decisions](#area-decisions) made 2026-10-25 (PB1 to PB12, DB2 and the port order confirmed) and 2026-10-26 (DB1 (b)); **porting**: slices 1 (XBOW-01, XBOW-03; 5.x-GM `ae77f0c2`), 2 (XBOW-02; `8954b0cd`), 3 (XBOW-04, XBOW-05; `b67b9f49`), XBOW-06 of slice 4 (`5c53d564`) and slice 5 (XBOW-08, XBOW-09; `fb1206fe`) done and verified in both trees (2026-10-25); XBOW-07 (`8d2185d6`, 2026-10-26) done and verified in both trees: **XBOW is ported**; **audited** 2026-10-26 ([XBOW audit](#xbow-audit-2026-10-26): 6 findings, one owner decision; the test fix, F2, done in fix slice T in 5.x-GM `b01f8737`, verified in both trees, regression 958 passed, 0 failed in each tree; F1 decided by the owner (2026-10-27: (c), only aimed shots can be headshots), fixed in 5.x-GM `170f4ad1` and verified in both trees, regression 960 passed, 0 failed in each tree; the audit is closed ([close-out](#audit-close-out)); XBOW is **signed off** by the project owner (2026-10-27).

## Scope

**XBOW covers** the bolts' damage, armor piercing and effects (and the bolts' sale), the crossbows' attack power, armor piercing, crit damage and adrenaline, the explosive bolt's blast, the bolt's hit fixes (the last bolt of a stack, one hit per target), the crossbow crit rules, headshot detection and its signal, the damage of NPC bows and crossbows, NPC archers' stamina.

**Already ported by other areas** (nothing left for XBOW; the hand-offs naming them close here):

| Subject | Ported by | What |
|---|---|---|
| Non-aimed bolts and bombs deal 50% less | SKL-06 (signed off) | The final-damage step, `CThrowable.GMIsFromAimThrow`, both trees; reflected arrows exempt |
| The crossbow skills | SKL-06, SKL-18 | Lightning Reflexes (classic `sword_s13`, new `sword_s32`), Steady Shot (`sword_s15`; the new tree's Cold Blood `sword_s34` carries it), Anatomical Knowledge (`sword_s7`, `sword_s26`), Crippling Shot (`sword_s12`, `sword_s27`), Cold Blood (`perk_2`, `sword_s34`), Trick Shot (`perk_17`, `perk_27`), In Combat's Fires (`perk_16`, `perk_44`) |
| Own bolts and bombs not halved for Geralt | SKL-18 | 5.x's halving of own bombs removed (legacy, "make Perk_16 more valuable"); 1.32 never halved own bolts, so the changelist's line changes nothing for them |
| Headshots ignore armor and resistances, +25% attack power | DMG-02, DMG-03 | `damage/formula.ws` (verified 2026-10-07); the +50% crit chance is 1.32's and 5.x's (`HEAD_SHOT_CRIT_CHANCE_BONUS`) |
| No additive attack power for bolts, the bolt minimum of 1 | DMG-03, DMG-01 | `damage/formula.ws`, `damage/pipeline.ws` |
| Underwater bolts ×3 (×7 in NG+) | DMG-04 | Kept a multiplier outside the pool (DD1's exception), 1.32's rule, which legacy did not change |
| Bolt stamina cost, crossbow refused without stamina (on foot, horseback) | STAM-03 | `stamina/actionStamina.ws` |
| Cat Eyes (Mutation 9): bolt damage ×2, slow motion, panel | MUT-11, UI-01 | Its pierce, stun and knockdown and the 15% health loss are vanilla's code |
| Bolt levels, crossbow levels from attack power (steps to 34 and 38) | ITEM-01 | Legacy's name list with `Blunt Bolt Legendary` 12 (DI1); the crossbow steps read XBOW-02's values |
| Bleeding of tracking and broadhead bolts (0.5% for 16 s, 1% for 8 s) | EFX-01 | `gm_effects.xml`; how often a bolt applies it is XBOW-01's |
| A bolt shattering a freeze | EFX-02 | The freeze bonus, no knockdown |
| The crossbow panel lines, the bolt knockdown tooltip row | UI-01, UI-02, UI-07 | The list reads the equipped bolt (deviation confirmed 2026-10-21); the row reads `desc_knockdownchance_mult`, which XBOW-01 gives the blunt bolts |
| Bolt schematics' ingredients, crossbow dismantling parts | CRAFT-01, CRAFT-08 | |
| Bolts in loot lists and the standalone starts | LOOT-05, LOOT-09 | |
| Arrows parried without a skill, reflected with Deflection | DEF-08, SKL-05 | |

**Not XBOW** (confirmed by the owner with DB2, 2026-10-25):

| Subject | Area | Why |
|---|---|---|
| Item prices (bolts, crossbows, schematics; the `mod_legendary` price tag removed from two Legendary bolts and given to the Ofir R crossbow) | ECON | Every area left prices to ECON |
| Item weights (bolts 0.05, crossbows; the weight nodes in crossbow abilities) | WGT | |
| Flyers forced to land by any bolt, Yrden or burning hit (`CNewNPC.ReactToBeingHit`) | AI | Handed to AI by SKL and EFX: the rule covers more than bolts |
| Projectile collision fixes (arrows and bolts stop at debris, foliage, doors, fences: `W3ArrowProjectile.OnProjectileCollision`, `CBTTaskShoot.ShootProjectile`, `CBTTaskProjectileAttack.Initialize`); the Yoana's-armor arrow fix (`sq108_heavy_armor`) | FIX | DEF-08 left them to FIX |
| Skellige bandit and pirate archers', the Emhyr quest crossbowman's level and attack ranges (`skellige_*_bow.w2ent`, `*_crossbow.w2ent`, `mq3035_red_crossbow_easy.w2ent`) | AI, DIFF | NPC levels and templates |
| Monster projectiles (`advancedProjectile.ws`, the leshen's, the toad's, the dracolizard's) | AI | As EFX handed them |
| NPC melee and secondary weapons | AI | SWD's boundary; only bows and crossbows are XBOW's |

## Changes at a glance

### What Ghost Mode changed

| # | Feature | Vanilla 1.32 | Legacy GM | Units (main) |
|---|---|---|---|---|
| XBOW-01 | Bolts | 4–20 damage, some full armor piercing, bleeding always, burning 25–30%, no knockdown | 10–160 damage by level, only Target Point bolts pierce armor (all of it), chances for bleeding (30–50%), knockdown (30–50%), burning (30–50%) | 14 abilities (and NG+) |
| XBOW-02 | Crossbows | Attack power ×1.01–3.0, little armor piercing, experience bonuses | Attack power ×1.01–2.2, armor piercing 5–250 by level, crit damage +25–75% on the best, adrenaline +0.02; two quest crossbows weaker | 17 abilities, 2 items (and NG+) |
| XBOW-03 | Selling bolts | Bolts cannot be sold; the quest bolt's tag misspelt | Bolts can be sold; the quest bolt cannot | 13 items (and NG+) |
| XBOW-04 | Explosive bolt's blast | 5 m | 3 m | `explosive_bolt.w2ent` |
| XBOW-05 | Bolt hit fixes | The last bolt of a stack hits without its bolt's damage and effect; an explosive bolt can hit one enemy up to three times | Fixed | `W3BoltProjectile` (3 units) |
| XBOW-06 | Crossbow crits | Bolts get +100% crit on a galloping horse; the drawn sword's crit damage applies to bolts | No horse crit for bolts; the sword's crit damage stays with the sword, the crossbow's with bolts | 2 crit functions |
| XBOW-07 | Headshots | The headshot signal sent from the crit check | Sent when the headshot deals damage | 3 shared units |
| XBOW-08 | NPC bows and crossbows | An arrow deals its projectile's damage | It deals the held bow's or crossbow's damage (150–250), retuned | 8 abilities (and NG+), 2 units |
| XBOW-09 | NPC archers' stamina | Shooting is free | A shot costs the light-attack stamina cost and needs it | `CBTTaskShoot` (2 units) |

### What 5.x changed

| # | 5.x change (from code and data) |
|---|---|
| XBOW-01 to XBOW-04 | None (1.32's data and entity) |
| XBOW-05 | None to the bugs (1.32's code; both bugs **seen in 5.x in game**, 2026-10-25); `ProcessDamageAction` changed for the headshot bones |
| XBOW-06 | None (1.32's crit functions; the horse crit and the sword's crit damage on bolts seen in game, 2026-10-25) |
| XBOW-07 | Headshots detected by bone names containing `head`, `neck`, `hroll` (`pelvis` on humans); quick shots at a large monster's targeted part |
| XBOW-08 | `ProcessDamageAction` changed for the headshot bones and deflected arrows; arrows and NPC bolts deal their entity's damage (arrow 200, bolt 600), which 5.x raises by 2.5% per Geralt level at each collision (`W3AdvancedProjectile.OnProjectileCollision`; **seen in game**, 2026-10-25) |
| XBOW-09 | None |

### Classification and proposed action

| # | Feature | Class | Proposed action |
|---|---|---|---|
| XBOW-01 | Bolts | clean | Legacy's (PB1) |
| XBOW-02 | Crossbows | clean | Legacy's (PB2) |
| XBOW-03 | Selling bolts | clean | Legacy's tags; prices ECON's (PB3) |
| XBOW-04 | Explosive blast | clean | Legacy's, a binary edit (PB4) |
| XBOW-05 | Bolt hit fixes | clean | Legacy's, if 5.x still has the bugs (PB5) |
| XBOW-06 | Crossbow crits | clean | Legacy's (PB6) |
| XBOW-07 | Headshots | overlap (5.x changed detection) | 5.x's detection (DB1 (b)); the signal legacy's (PB7) |
| XBOW-08 | NPC bows | clean | Legacy's (PB8) |
| XBOW-09 | NPC archers' stamina | clean | Legacy's, on STAM-08's mechanism (PB9) |

---

### XBOW-01 Bolts

| | |
|---|---|
| Kind | tuning |
| Pillars | P1, P5, P8 |
| 5.x class | clean |
| Flags | balance |
| Depends on | DMG-01 to DMG-03 (armor before attack power, signed off), MUT-13 (effect chances resisted), EFX-01 (the bolts' bleeding), SKL-08 (knockdown severity), SKL-06 (Steady Shot) |
| Skill trees | n/a in the data; Steady Shot (classic `sword_s15`, new `sword_s34`), Anatomical Knowledge (`sword_s7`, `sword_s26`) and Cold Blood add to bolt hits, so the checks run in both trees |
| Port form | the fourteen bolt abilities given whole (`on_conflict="replace"`: legacy removed nodes, the 1.32 armor piercing of Bait and Tracking bolts and two `duration` nodes) in a new DLC file `items/gm_xbow.xml`, NG+ copy in `items_plus/` (vanilla's and legacy's NG+ entries equal the regular ones), written by `tools/gen_xbow.py` (`--verify`: every bolt ability as the game reads it equals legacy's) |
| Port status | **signed off** (2026-10-27); ported (slice 1, 2026-10-25, 5.x-GM `ae77f0c2`), verified in both trees |
| Open checks | Aimed shots (the real key held; SKL-06's open check): every shot here was a quick shot, so every damage read is halved by the non-aimed rule |
| Save impact | none (expected): the bolt's abilities are applied to Geralt at each hit (`ApplyItemAbilities`) |
| NG+ counterpart | applied (legacy's values), untested |

**What it does** (changelist 668: "Bolts and crossbows are reworked, damage and effects tweaked"): each bolt's damage grows with its level, so better bolts matter against armor (P1), and the special bolts apply their effect on a chance, resisted by the target's resistance to it (MUT-13's rule):

| Bolt (level) | 1.32 and 5.x | Legacy |
|---|---|---|
| Bodkin (default, infinite) | 5 piercing, 4 silver | 10, 40 |
| Harpoon (underwater, infinite) | 10, 400 | 10, 500 |
| Bait (2) | 6, 5; ignores 100 armor and 100% resistance | 10, 40; no armor piercing |
| Tracking (2) | 6, 5; ignores 100 armor and 100% resistance; tracking bleeding on every hit | 10, 40; tracking bleeding 50% (0.5% per second for 16 s, EFX-01) |
| Blunt (2) | 8 bludgeoning, 8 silver; no effect | 10, 40; knockdown 30% |
| Blunt Legendary (12) | 10, 10 | 60, 110; knockdown 50% |
| Broadhead (10) | 8, 8; bleeding on every hit | 50, 90; bleeding 30% (1% per second for 8 s) |
| Broadhead Legendary (20) | 12, 12; bleeding on every hit | 90, 150; bleeding 50% |
| Target Point (5) | 12, 12; ignores 7 armor and 50% resistance | 30, 70; ignores all armor and resistance (1000, 100%) |
| Target Point Legendary (15) | 20, 20; 15 and 60% | 70, 120; all armor and resistance |
| Split (15), three bolts | 10, 10 each | 70, 120 each |
| Split Legendary (24) | 14, 14 each | 100, 160 each |
| Explosive (20) | 12, 12, fire 12; burning 25% | 60, 100, fire 40; burning 30% |
| Explosive Legendary (26) | 20, 15, fire 20; burning 30% | 70, 110, fire 60; burning 50% |

Piercing (bludgeoning for blunt bolts) counts against humans and beasts, silver against monsters, both against armor first. Each bolt's tooltip gets its chance line (`desc_*chance_mult`; the blunt bolts' knockdown row is UI-07's). Legacy also removed the tracking bolt's `duration` 120 and the broadhead bolts' 15, so their bleeding lasts EFX-01's time. The knockdown goes through SKL-08's severity rules (raised when the target is low on stamina).

**Implementation (legacy):** the fourteen `_Stats` abilities of `def_item_bolts.xml`, regular and NG+.

**Port** (slice 1, 2026-10-25, 5.x-GM `ae77f0c2`). Verified in both trees. How each check was tested:

- *The data* (scripted read, regression `GMTest_xbow01`): every bolt's damage types, silver and fire damage, armor piercing, effect ability, effect chance and tooltip chance read from the definitions equal legacy's table above, no bolt has a `duration` of its own, the split bolts fire three. `gen_xbow.py --verify`: all 15 abilities of the two bolt files (the quest bolt's unchanged) equal legacy's, regular and NG+.
- *Real shots* (quick shots fired by script through the combat action, as the throw button does: `gmtest_xbow_shot`, one exec call per press and release; Crossbow 1, Geralt level 30, no skills; a neutral, frozen human test dummy 4 m away, hard-locked; aimed shots cannot be scripted): every hit read the bolt's legacy damage (the damage probe's raw value) and dealt it × 2.01 (Geralt's 1 + the crossbow's 1.01) ÷ 2 (non-aimed): Bodkin, Tracking and Blunt 10.05, Target Point 30.15, Broadhead 50.25, Blunt Legendary 60.3, Target Point Legendary 70.35, Broadhead Legendary 90.45, Explosive 100.5 (piercing and fire), Explosive Legendary 130.65; against a troll the silver damage counts (Bodkin 40.2, Broadhead 90.45). Against 100 armor, Bodkin, Bait, Broadhead and Split bolts dealt 0 (the bolts' minimum of 1, halved by the non-aimed rule, falls below 1: DMG-01), the Target Point bolts read 0 armor points and dealt their full 30.15 and 70.35 (also against an armored troll). The split bolt hit three times per shot.
- *Effect chances* (real quick shots, the dummy's effects removed before each; a shot counts when the effect is on the dummy after the hit; classic tree, then new tree): Tracking bleeding 12/20 and 6/10 (50%); Broadhead 7/20 and 3/10 (30%); Broadhead Legendary 8/20 (50%); Blunt knockdown 3/20 and 3/10 (30%); Blunt Legendary 8/20 and 7/13 (50%); Explosive burning 5/20 and 3/10 (30%); Explosive Legendary 7/20 (50%). Each within the spread of its chance; no bleeding or knockdown from bolts without the effect. The bleeding's own values from a real bolt: EFX-01.
- *Regression:* 925 passed, 0 failed in each tree (895 before, the 30 checks of `GMTest_xbow01` added).
- *The bolts' bleeding from a real bolt* (EFX-01's open check, slice 2's launch, new tree; `gmtest_xbow_bleed` reads the dummy's effect): a Tracking bolt's `BleedingTrackingEffect` 16 s at 0.5% of maximum health per second, a Broadhead bolt's `BleedingEffect_BroadheadBolt` 8 s at 1% (the dummy's health fell 500 and 1,000 per second of its 100,000).

**5.x:** 1.32's values. In the port today the bolts deal 1.32's 4–20 damage under Ghost Mode's armor-first formula, so against armor most bolts deal the 1-point minimum (plus Steady Shot's flat damage); tracking and broadhead bolts bleed on every hit.

**Decisions:** legacy's bolts (PB1, confirmed (project owner, 2026-10-25)): the fourteen bolts whole, the Bait and Tracking bolts' 1.32 armor piercing removed, the tracking and broadhead bolts' own `duration` dropped.

### XBOW-02 Crossbows

| | |
|---|---|
| Kind | tuning |
| Pillars | P1, P8 |
| 5.x class | clean |
| Flags | balance |
| Depends on | DMG-02 (armor piercing in the formula, signed off), ITEM-01 (crossbow level from attack power, signed off), SKL-06 (Cold Blood reads `focus_gain`) |
| Skill trees | n/a in the data; Cold Blood (classic `perk_2`, new `sword_s34`) reads the crossbow's adrenaline gain, Anatomical Knowledge adds to its crit damage: checks in both trees |
| Port form | the seventeen crossbow abilities given whole (`replace`; the weight nodes stay 5.x's, WGT, placed last) in `gm_xbow.xml` (`gen_xbow.py`), NG+ copy; the two quest crossbows' `base_abilities` in their item entries in `gm_item.xml` (an `item_layer.py` field, `BLOCKS["XBOW-02"]`, which `gen_item.py` writes with CRAFT's dismantling parts) |
| Port status | **signed off** (2026-10-27); ported (slice 2, 2026-10-25, 5.x-GM `8954b0cd`), verified in both trees |
| Open checks | Aimed shots (quick shots only, as XBOW-01); a bolt crit with a crossbow's crit damage (read from the data only); the crossbow's adrenaline per hit with Cold Blood (read from the data; SKL-06's checks of Cold Blood's gain pass in the regression) |
| Save impact | none (**confirmed**): a save made with 5.x's quest crossbows (Toussaint Crossbow 2's stats), loaded with the slice: both crossbows had Toussaint Crossbow 1's ability, x2.1, armor piercing rolled on the load (176.7, 177.4) and level 34 |
| NG+ counterpart | applied (legacy's values), untested |

**What it does:** a crossbow's attack power multiplies its bolts' damage after armor; its armor piercing (`armor_reduction`) grows with its level so that bolts get through armor; the best crossbows add crit damage; most add adrenaline (`focus_gain` +0.02 per bolt hit, for Cold Blood). 1.32's experience bonuses on kills are gone. The level each one shows and needs (ITEM-01's formula, the crossbow's attack power read by name) moves with it:

| Crossbow | 1.32 and 5.x: attack power, armor piercing, other; level | Legacy; level |
|---|---|---|
| Crossbow 1 | ×1.01; 1 | unchanged; 1 |
| Crossbow 2 | ×1.1–1.25; 2–8 | ×1.13–1.2, 15–50; 4 |
| Crossbow 3 | ×1.2–1.5; 8–15 | ×1.33–1.4, 50–70; 11 |
| Crossbow 4 | ×1.3–1.7; 11–22 | ×1.43–1.5, 70–90; 15 |
| Crossbow q206 (Crach's reward) | ×1.45, adrenaline +0.01–0.02, +5% human kill experience; 15 | ×1.5, 70, crit damage +25%, +0.02; 15 |
| Crossbow 5 | ×1.4–1.8, 1–5; 15–25 | ×1.53–1.6, 90–105; 19 |
| Crossbow 6 | ×1.5–1.9, 5–10, +0.01–0.02; 19–27 | ×1.65, 105–120, +0.02; 22 |
| Crossbow 7 | ×2.0, +0.01–0.02, kill experience; 32 | ×1.75, 120–130, crit damage +50%, +0.02; 25 |
| Lynx School Crossbow | ×2.25, 10, crit chance +2%, kill experience, +0.01–0.02; 38 | ×1.85, 140, crit damage +50%, +0.02; 27 |
| Bear School Crossbow | ×2.1, crit chance +5%, crit damage +2%, kill experience, +0.01–0.02; 34 | ×2.0, 160, crit damage +75%, +0.02; 32 |
| Toussaint Crossbow 1 | ×2.5; 38 | ×2.1, 170–190; 34 |
| Toussaint Crossbow 2 | ×3.0; 38 | ×2.2, 200–250, +0.02; 38 |
| Ravix of Fourhorn, Geralt of Rivia crossbows | Toussaint Crossbow 2's; 38 | Toussaint Crossbow 1's; 34 |
| Nilfgaardian, Skellige, Elven crossbows (free DLC) | ×1.25, ×1.45, ×1.65; 8, 15, 22 | the same, 60, 80, 110 |
| Ofir Crossbow | ×1.65; 22 | ×2.0, 130–155; 32 |
| Ofir Crossbow R | ×2.0; 32 | ×2.1, 170, crit damage +75%; 34 |

Ranges are rolled when the item is made. `Crossbow 1 q1 _Stats` (×1.03–1.1, 5–10) is changed too, but no item uses it, in 1.32, legacy or 5.x. The crossbow's abilities, like the bolt's, are applied to Geralt only for the bolt's hit, so its armor piercing and crit damage count for bolts only.

**Implementation (legacy):** `def_item_weapons_crossbow.xml` (10 abilities), Blood and Wine's `def_item_weapons_crossbows.xml` (2 abilities, the two quest crossbows' base abilities), `dlc13_items.xml` (3), Hearts of Stone's `def_item_weapons.xml` (2), regular and NG+.

**Port** (slice 2, 2026-10-25, 5.x-GM `8954b0cd`). Verified in both trees. How each check was tested:

- *The data* (scripted read, regression `GMTest_xbow02`): every crossbow ability's attack power and armor piercing ranges, crit damage and adrenaline equal legacy's table above, and no ability keeps another attribute than these, quality, ammo and weight (1.32's experience bonuses and crit chance gone); each crossbow item's level as the game computes it from its attack power (ITEM-01): Crossbow 1 to 7 at 1, 4, 11, 15, 19, 22, 25, Crach's at 15, Lynx 27, Bear 32, Toussaint 34 and 38, the free DLC's 8, 15, 22, Ofir 32 and 34. A new Ravix of Fourhorn or Geralt of Rivia crossbow carries Toussaint Crossbow 1's ability (x2.1, armor piercing 188 and 184 rolled, level 34). `gen_xbow.py --verify`: all 33 bolt and crossbow abilities of XBOW's files equal legacy's (weight WGT's), and every item's tags and base abilities, regular and NG+.
- *Real shots* (quick shots by script, as XBOW-01; Broadhead bolts, 50 piercing, at a neutral human test dummy with armor; Geralt level 40, no skills; three shots per crossbow, in each tree): Crossbow 1 against 100 armor dealt 0; the Bear School crossbow (160 piercing) against 100 armor read 0 armor points and dealt 75 (50 x 3.0 / 2), Lynx 71.25 (x 2.85), the Ravix of Fourhorn crossbow against 150 armor 77.5 (x 3.1), Toussaint Crossbow 2 against 200 armor 80 (x 3.2), Ofir Crossbow R against 150 armor 77.5; Crossbow 2 against 50 armor read 2.6 armor points left (its rolled piercing 47.4) and attack power x2.19 (its rolled 1.19).
- *Save impact:* see the table.
- *Regression:* 947 passed, 0 failed in each tree (the 22 checks of `GMTest_xbow02` added).

**5.x:** 1.32's values; in the port today the crossbows read up to level 38 with 1.32's attack power (ITEM-01's steps were made for legacy's values: the Lynx crossbow shows 38 instead of 27).

**Decisions:** legacy's crossbows (PB2, confirmed (project owner, 2026-10-25)), including the two Blood and Wine quest crossbows (Ravix of Fourhorn, Geralt of Rivia crossbow) dropping to Toussaint Crossbow 1's stats; every crossbow's level follows ITEM-01's formula; 5.x's weight nodes kept (WGT).

### XBOW-03 Selling bolts

| | |
|---|---|
| Kind | content |
| Pillars | P6 |
| 5.x class | clean |
| Flags | — |
| Depends on | ECON (the prices) |
| Skill trees | n/a |
| Port form | the bolt items' tags in `gm_item.xml`: an `item_layer.py` field (`TAGS["XBOW-03"]`: `mod_nosale`, `mod_nosalem`) that `gen_item.py` writes into 5.x's item entries; prices and weights stay 5.x's |
| Port status | **signed off** (2026-10-27); ported (slice 1, 2026-10-25, 5.x-GM `ae77f0c2`), verified |
| Open checks | — |
| Save impact | none (expected; tags are read from the definition, ARM-05) |
| NG+ counterpart | applied, untested |

**What it does** (changelist 671: "Bolts no longer cost a fortune, you can sell them and buy them for a reasonable price, but you can't dismantle them"): the twelve non-infinite bolts lose `mod_nosale`, so merchants buy them; the Blood and Wine quest bolt's misspelt `mod_nosalem` becomes `mod_nosale`, so it can no longer be sold. Bolts have no dismantling parts in 1.32, legacy or 5.x. Legacy's prices (Bait, Tracking and Blunt 70, Target Point and Split 100, Broadhead 120, Explosive 170; the Legendary ones 100–200; the Harpoon bolt 0) and `mod_legendary` (a price modifier) are ECON's; the weight (0.05 each) WGT's.

**5.x:** 1.32's tags and prices.

**Port** (slice 1, 2026-10-25, 5.x-GM `ae77f0c2`), verified (the tags in both trees with the regression). Scripted checks (`GMTest_xbow03`, in the regression): the twelve special bolts have no `mod_nosale` and a sale price above 0 (Bait and Tracking 8, Target Point Legendary 20, Explosive Legendary 21 crowns from Geralt's own inventory), Bodkin, Harpoon and the quest bolt keep or get `mod_nosale` (sale price 0), no bolt has `mod_nosalem`. A real sale (a spawned Novigrad weaponsmith, his shop opened as the shop dialogue does, the sale through the shop menu's own event, what the sell click calls; `gmtest_xbow_sell`): a Tracking bolt sold for 3 crowns and an Explosive Legendary bolt for 16, Geralt's count down by one, the merchant's up by one; the shop's tooltips show both bolts with legacy's damage and chances. `gen_item.py --verify` and `gen_xbow.py --verify`: the tags of all 15 bolt items equal legacy's (but `mod_legendary`, ECON's), regular and NG+.

**Decisions:** PB3 (confirmed (project owner, 2026-10-25)): legacy's tags now, the prices with ECON.

### XBOW-04 Explosive bolt's blast

| | |
|---|---|
| Kind | tuning |
| Pillars | P8 |
| 5.x class | clean |
| Flags | balance |
| Depends on | — |
| Skill trees | n/a |
| Port form | binary edit of `items/weapons/projectiles/witcher_bolts/explosive_bolt.w2ent` (`W3ExplosiveBolt.explosionRange` 5 → 3) with `cr2w_patch.py`, shipped in the mod's bundle as LOOT's and ENCH's entity edits |
| Port status | **signed off** (2026-10-27); ported (slice 3, 2026-10-25, 5.x-GM `b67b9f49`), verified in both trees |
| Open checks | — |
| Save impact | none (expected): a new bolt entity is spawned for each shot |
| NG+ counterpart | none (no NG+ entity) |

**What it does** (changelist 669): an explosive bolt's blast reaches enemies within 3 m instead of 5 m.

**5.x:** 1.32's entity (bindiff: only re-save noise against 1.32).

**Port** (slice 3, 2026-10-25, 5.x-GM `b67b9f49`): `explosionRange` 5 → 3 in both copies of the entity (the editable object and the compiled `flatCompiledData`), `cr2w_patch.py "W3ExplosiveBolt.explosionRange=5.0:3.0"`; `gen_xbow.py --verify` checks the file is 5.x's with exactly that edit and legacy's value. Verified in both trees. How each check was tested:

- *The entity* (scripted read, regression `GMTest_xbow04`): a spawned explosive bolt reads `explosionRange` 3.
- *The blast* (real quick shots by script, as XBOW-01; Explosive bolts, Crossbow 1, Geralt level 30; the target dummy 4 m ahead and three more hostile human dummies beside it, about 2, 3 and 4 m from it; six shots per run): before the edit (5 m) every shot hit all three dummies then in place (2 and 4 m); with it every shot hit the target and the dummies at about 2 and 3 m, never the one at 4 m, in each tree, also with Cat Eyes. Screenshot of a 3 m blast: the explosion on the target, the dummy 4 m to the side untouched.

**Decisions:** PB4 (confirmed (project owner, 2026-10-25)): a binary edit of the entity, as legacy.

### XBOW-05 Bolt hit fixes

| | |
|---|---|
| Kind | fix |
| Pillars | P8 |
| 5.x class | clean (5.x's code is 1.32's; both bugs seen in 5.x in game, 2026-10-25) |
| Flags | — |
| Depends on | STAM-03 (the `ThrowProjectile` wrapper), SKL-06 (Cold Blood's adrenaline per hit) |
| Skill trees | n/a (Cold Blood's adrenaline, both trees, is counted per hit) |
| Port form | `xbow/boltHits.ws`: `@addField W3BoltProjectile.gmBoltItemName`, set by a `@wrapMethod` of `ThrowProjectile` (while the item is still in the inventory; legacy sets it in `ReleaseProjectiles2`, a timer) on every projectile of the shot; `@wrapMethod` of `ProcessDamageAction` (an early return for a victim this bolt already hit; the last bolt re-added around the hit and removed after) and of `OnProjectileInit` (`collidedEntities` cleared) |
| Port status | **signed off** (2026-10-27); ported (slice 3, 2026-10-25, 5.x-GM `b67b9f49`), verified in both trees |
| Open checks | — |
| Save impact | none (expected): the new field is not saved |
| NG+ counterpart | none |

**What it does** (bugfixes 161, 162): when Geralt shoots the last bolt of a stack, the item is gone from his inventory by the time the bolt hits, so the hit has no bolt to read: from the code, no damage types and no effect (only the bolts' 1-point minimum); legacy adds the bolt back for the hit and removes it again. A bolt hits each target once: an explosive bolt no longer damages the same enemy up to three times (and gives up to three times the adrenaline).

**5.x:** the same code as 1.32 (the bolt is removed at release, `ProcessDamageAction` applies its abilities at the hit; `ProcessDamageAction` keeps no per-victim check, the explosion calls it for every entity in range). Both bugs **seen in game** on the port before the fix (2026-10-25, classic tree; real quick shots by script at hostile test dummies, Geralt level 30, Crossbow 1):

- *The last bolt:* with a Broadhead stack cut to one bolt, the shot's hit read no bolt (item `None`), no damage types, and dealt 0 (the shots before it 50.25).
- *Repeated hits:* an explosive bolt explodes on whatever it touches and, with Cat Eyes (Mutation 9), pierces and flies on, so it explodes again on the next thing it touches (the ground, another enemy): over six shots with three dummies in the blast, 10 of 28 hits were a second hit on a dummy the same shot had already hit. Without Cat Eyes each shot exploded once and hit each dummy once (also with three dummies in the blast, and in slice 1's 30 shots at a lone dummy); a plain bolt's own collision already skips a victim it hit, so piercing plain bolts hit once.

**Port** (slice 3, 2026-10-25, 5.x-GM `b67b9f49`). Verified in both trees. How each check was tested (real quick shots by script as above):

- *The last bolt:* one stack of two Broadhead bolts: both hits read the bolt and dealt 50.25, the stack went 2 → 1 → 0 and the Bodkin bolt was equipped after; with two stacks (50 and an equipped 1), the last bolt of the equipped stack dealt 50.25 and Geralt was left with exactly the other 50. The last Split bolt: all three of its projectiles hit for 70.35 (the deviation below).
- *One hit per target:* with Cat Eyes, six explosive shots with three dummies in the blast: each dummy hit once per shot, no repeated hit (before the fix: 10). An NPC outside the test (not a dummy) also took a 0-damage hit in some explosions, as before the fix.
- *Regression:* 949 passed, 0 failed in each tree. Since the audit's fix slice T (2026-10-26), `GMTest_xbow04` throws a real Split bolt entity and reads the name on its three projectiles (fails without the wrapper; the check it replaced could not fail).

**Decisions:** PB5 (confirmed (project owner, 2026-10-25)): legacy's fixes, each only after a check in game shows 5.x still has the bug; a bug 5.x no longer has is dropped as `in-5.x`. Both bugs are in 5.x, so both fixes are ported.
- **Deviation:** the last bolt's fix covers a split bolt's two extra projectiles too: the bolt's name is set on every projectile of the shot when it is thrown, where legacy set it only on the first projectile (in `ReleaseProjectiles2`, after the copies were made), so in legacy the last Split bolt's two copies still hit without damage (porter's call 2026-10-25, confirmed by the owner, 2026-10-26).

### XBOW-06 Crossbow critical hits

| | |
|---|---|
| Kind | fix, tuning |
| Pillars | P8 |
| 5.x class | clean |
| Flags | balance |
| Depends on | SKL-06 (Anatomical Knowledge's crit chance and damage for bolts), SKL-14 and ALCH-16 (the replaced crit functions, `skills/oils.ws`), SWD (swords' crit damage), XBOW-02 (crossbows' crit damage) |
| Skill trees | both: Anatomical Knowledge (classic `sword_s7`, new `sword_s26`) adds crit chance and damage to bolts, Crippling Shot (`sword_s12`, `sword_s27`) fires on bolt crits; the rules themselves read no skill |
| Port form | in the replaced `CR4Player.GetCriticalHitChance` (`skills/oils.ws`): the galloping-horse +100% for non-bolts only; in the replaced `CR4Player.GetCriticalHitDamageBonus`: the held weapons' crit damage of the other kind subtracted (legacy's loop) |
| Port status | **signed off** (2026-10-27); ported (slice 4, 2026-10-25, 5.x-GM `5c53d564`), verified in both trees |
| Open checks | — |
| Save impact | none |
| NG+ counterpart | none |

**What it does:** a bolt shot from a galloping horse no longer gets 1.32's +100% crit chance (sword swings still do). A bolt's crit damage no longer includes the drawn sword's crit damage, and a sword hit's no longer includes the crossbow's (1.32 kept crit chance apart this way, not crit damage). With legacy's crossbows (XBOW-02) and swords (SWD) both carrying crit damage, this keeps each weapon's bonus with it. Legacy's other changes in these functions (the oils' crit chance and damage for melee only, confusion moved to the damage manager) are ported (SKL-14, SKL-12, ALCH-14).

**5.x:** 1.32's functions. Seen in game on the port before the change (2026-10-25, classic tree): on a galloping Roach a bolt's crit chance read 1.05 (Geralt's 0.05 + 1); with Weeper drawn (crit damage 0.64) a bolt's crit damage read 0.89 (Geralt's 0.25 + the sword's), and real bolt crits dealt attack power ×4.76 against ×4.11 after the change. A held sword's crit damage counts in Geralt's attributes only while it is drawn; its crit chance was already kept from bolts by 1.32's code.

**Port** (slice 4, 2026-10-25, 5.x-GM `5c53d564`). Verified in both trees. How each check was tested:

- *Galloping* (a **real gallop**: Roach mounted by script, `gmtest_stam03_mount()`, then the real W key held and Shift double-tapped and held, sent as key presses; read by script while she galloped, relative speed 4): a bolt's crit chance 0.05, a light attack's 1.05 (with Weeper drawn 1.29), in each tree; at a canter (speed 3) both 0.05. No bolt was shot from the galloping horse (aiming from horseback cannot be scripted at a target), so the check is the crit chance the damage step asks for.
- *Crit damage* (scripted reads, `gmtest_xbow06_read()`: what the damage step asks for a bolt and for the held sword; Weeper, a silver sword with crit damage 0.58–0.64 rolled, drawn; Bear School crossbow, crit damage 0.75): a bolt's crit damage 0.25 (Geralt's own, without the sword's), the sword's 0.83–0.84, in each tree.
- *Real bolt crits* (quick shots by script with every hit made a crit by vanilla's `criticalboy()`; Bodkin bolts, the Bear School crossbow, Weeper drawn, Geralt level 60; a neutral human dummy): each hit crit with attack power ×4.11 (Geralt's 1 + the crossbow's 2.0 + crit damage 0.25 + 0.75, and 0.11, Weeper's own attack power bonus, which counts for bolts while it is drawn, as in 1.32 and legacy; before the change ×4.76: the same plus Weeper's crit damage 0.64), dealt 20.55; with the Witcher Silver Sword drawn (no crit damage) ×4.0. Screenshot: "Geralt strikes a critical hit", the bolt hit for 20.56 (new tree).
- *Not tested in play:* a sword hit while a crossbow is held (the crossbow is in hand only during a shot); the code is legacy's loop, which the bolt side exercises.
- *Regression:* 949 passed, 0 failed in each tree.

**Decisions:** PB6 (confirmed (project owner, 2026-10-25)).

### XBOW-07 Headshots

| | |
|---|---|
| Kind | fix |
| Pillars | P8, P1 |
| 5.x class | overlap (5.x changed which hits are headshots) |
| Flags | balance |
| Depends on | DMG-02, DMG-03 (headshots ignore armor and resistances, +25% attack power: signed off), SKL-06 (5.x's new-tree headshot bonuses removed) |
| Skill trees | n/a (5.x's Lightning Reflexes `sword_s32` headshot terms already removed by SKL-06) |
| Port form | `xbow/headshots.ws`: `@addMethod W3DamageManagerProcessor.GMSignalHeadshot` sends the event to the victim; called in the port's `ProcessAction` (`defense/processAction.ws`: Geralt's headshot dealt damage) and `GetDamageResists` (`damage/formula.ws`: the headshot's resistances read, once per damage type); 5.x's send from the crit check removed (`ProcessCriticalHitCheck`, `alchemy/bombs.ws`). Detection: 5.x's (DB1 (b)), for aimed shots only: `@replaceMethod W3BoltProjectile.ProcessDamageAction` (`xbow/headshots.ws`, 5.x's body, one line changed) checks the bone only when the bolt is not Geralt's or was shot from aiming (`GMIsFromAimThrow`, SKL-06; audit F1, owner 2026-10-27) |
| Port status | **signed off** (2026-10-27); ported (2026-10-26, 5.x-GM `8d2185d6`; aimed shots only 2026-10-27, `170f4ad1`), verified in both trees |
| Open checks | A real aimed shot's headshot (aiming needs the real key held, SKL-06's open check; tested with the aimed flag set on a scripted bolt as the aiming path sets it); an aimed Split bolt's two copies: from the code they are made before 5.x sets the aimed flag on the bolt, so they count as quick shots (no headshot, and half damage under SKL-06's rule) |
| Save impact | none |
| NG+ counterpart | none |

**What it does:** a headshot (a bolt or arrow hitting an NPC's head, neck or `hroll` bone, or a human's pelvis) ignores the target's armor and resistances, adds 25% attack power (DMG, ported) and 50% crit chance (1.32's). Legacy sends the "Headshot" gameplay event, which some behaviour trees wait for (`CBTTaskKill`'s `onHeadshot`), when the headshot deals damage and when its resistances are read, instead of from the crit check. Only an aimed bolt of Geralt's can be a headshot (owner, 2026-10-27, audit F1): a quick shot (the button tapped, not aimed) never is, whatever bone it hits; NPCs' arrows and bolts are unchanged.

**5.x:** a hit counts as a headshot when the bone's name contains `head`, `neck` or `hroll` (or `pelvis`, humans), where 1.32 (and legacy) needed the exact names; bones such as a monster's second head or a head bone with a suffix now count (listed by rig below). Quick shots at a large monster with targetable parts fly at the targeted part, which can be its head. Under Ghost Mode every extra headshot ignores all armor. 5.x sends the event from the crit check (Geralt's hits only), as 1.32.

**DB1: the bones 5.x's rule adds** (listed 2026-10-25 for the owner). A bolt or arrow reports the bone of the ragdoll shape it hits (`GetRagdollBoneName`); a hit on an NPC without ragdoll shapes reports no bone and is never a headshot. Every NPC template under `characters\npc_entities\monsters\` of the base game and both expansions (253, 250 of them NPCs) and six humans (a bandit, a woman, a dwarf, an elf, a child, a Wild Hunt warrior) were spawned by script and their ragdoll bones read in game (`gmtest_xbow_rig_spawn`, `gmtest_xbow_rig_read`); the shapes' size and place come from the rigs' ragdoll files (`*.w2ragdoll`, read from the game's bundles). Legacy's rule (1.32's) counts the bones named exactly `head`, `neck`, `hroll`, and `pelvis` on humans (`IsHuman`: Wild Hunt warriors are not); 5.x's counts every bone whose name contains them. No rig has a `hroll` bone, and no bone contains `pelvis` but `pelvis` itself, so 5.x adds only neck bones, on six rig groups:

| Rig group (who uses it) | Headshot bones, legacy | 5.x adds | What the added bones are | Recommendation |
|---|---|---|---|---|
| Wolves, wargs, white wolves, wild dogs, barghests | `head` | `neck1` | the neck, between the shoulders (`spine3`) and the head | counts sensibly: a neck, as a human's `neck` counts |
| Panthers | `head` | `neck1`, `neck2` | the neck, two shapes between the chest (`torso3`) and the head | counts sensibly: the neck |
| Griffins, archgriffins, cockatrices, basilisks | none | `neck2` | the front-most shape, past `spine3`: the upper neck and the head (the rig has no head shape) | counts sensibly: the only head-or-neck shape; under legacy these monsters have no headshot at all |
| Wyverns, forktails | none | `neck1`, `neck2` | the long neck; `neck2`, the front-most shape, holds the head (no head shape) | counts sensibly, as for griffins |
| Fiends, chorts | none | `neck1` | the front-most shape (three capsules past `spine3`): neck and head | counts sensibly, as for griffins |
| Nekkers, nekker warriors | none | `k_neck_g` | a ball above the chest: the nekker's head (its rig names every bone `k_..._g`, so the exact names never match) | counts sensibly: it is the head |
| Everyone else (below) | as 5.x | none | — | no change either way |

The same under both rules: humans, including Bruxa and Alp in human form and mages (`head`, `neck`, `pelvis`); Wild Hunt warriors, giants, cyclopes, Bruxa, Alp, the higher vampires' monster forms (`head`, `neck`); drowners, drowned dead, rotfiends, devourers; werewolves; leshens and Hym; gargoyles, silvans; ghouls, alghouls, Hounds of the Wild Hunt (`head`); hags and foglets, sirens, harpies, trolls, katakans, ekimmaras, garkains, fleders, Shaelmaars, the crones, wights (`neck`). No headshot bone under either rule: arachasi, endrega drones and warriors, arachnomorphs and centipedes (ragdolls without head or neck shapes); bears, golems and elementals, wraiths, nightwraiths, noonwraiths, Dettlaff's monster form, toads report no ragdoll bone while alive, and endrega workers, archespores, kikimores, boars report `Unknown` (read by script; not confirmed with a bolt).

**Porter's assessment:** every bone 5.x's rule adds is a neck shape or the shape that holds the head; none is a false match (no tail, jaw or helmet bone). The change matters most for griffins, wyverns, fiends and nekkers, which legacy's exact names leave without any headshot. Under Ghost Mode a headshot ignores all armor and resistances (DMG), so headshots on these four groups (armored, large monsters among them) become a strong option for an aimed bolt; 5.x's quick shot at a large monster's targeted part (PB10) can also land on the head.

**Port** (2026-10-26, 5.x-GM `8d2185d6`). Verified in both trees. Shots: Broadhead bolts (50 piercing, 90 silver), Crossbow 1, Geralt level 30, no skills; the test dummy (frozen, neutral) with 100 armor, 4 m away and hard-locked; each hit logged with the bone it hit, the headshot flag, armor points, attack power, damage dealt and the Headshot events it sent (a test wrapper of `GMSignalHeadshot`). How each check was tested:

- *Body shots* (**real quick shots** by script, as XBOW-01): at a human (bandit) every bolt hit `torso2` (the quick shot's bone for a target without targetable parts): no headshot, 100 armor points, dealt 0, no event; at a griffin every bolt hit `spine3`: the same, 0 dealt; in each tree.
- *Nekker headshots* (**real quick shots**): every hit landed on `k_neck_g` (5 of 5 in the classic tree, 2 of 2 in the new tree; two presses fired nothing, as before): headshot, 0 armor points, attack power ×2.26 (the +25% of DMG-03), 101.7 dealt (90 silver × 2.26 ÷ 2, non-aimed; 112.95 on a crit), one event from the damage and two from the resistance read (piercing and silver). Under legacy's exact names these hits would read 100 armor and deal 0.
- *Human and griffin headshots* (**scripted shot at the bone**: a quick shot at a human flies at `torso2` and an aimed shot cannot be scripted, so `gmtest_xbow07_shoot(bone)` makes the equipped bolt's own projectile as the crossbow does and fires it at one bone, as a quick shot at a monster's targeted part is fired; the hit, its bone and its damage are the game's): aimed at the bandit's `head` the bolt hit `neck` (once `head`), at the griffin's `neck2` it hit `neck2`; every hit a headshot through all 100 armor: bandit 56.5 (piercing, ×2.26 ÷ 2; 62.75 on crits, the headshot's +50% crit chance at work), griffin 101.7 and 112.95; events: damage 1, resistances 2 per hit; in each tree. Screenshot (classic tree): the combat log "Geralt strikes a critical hit", "Geralt hits Griffin for 112.94", where the body shots dealt 0.
- *The crit check* no longer sends the event (the code; every logged event came from the two new places).
- *Aimed shots only* (audit F1 (c), 2026-10-27, 5.x-GM `170f4ad1`; Geralt level 30, no skills): **real quick shots** in a real fight, as the audit's (each monster spawned hostile 6 m away, Geralt invulnerable, hard lock-on, Bodkin bolts, Crossbow 1): wyvern 11 hits in the classic tree (all `neck2`) and 10 in the new tree (`neck2`, `neck1`, one `tail3`), forktail 12 and 10 (`neck2`, a few `None`), nekker 12 and 10 (`k_neck_g` 8 and 3 times, the rest torso, arm or `None`): no headshot and no event in either tree (the audit's build: 9 of 10, 7 of 10, 9 of 16); the wyverns and forktails read their 30 armor points and took 7.54 per hit (9.41 on a crit), the nekkers (no armor) 40.2 at attack power x2.01 (a headshot's x2.26 gone). Screenshot (classic tree): Geralt fighting the wyvern, still at 94% of its health after eleven quick shots. **Scripted shots at a bone** (`gmtest_xbow07_shoot(bone, 80)`, Broadhead bolts at the neutral, frozen dummy with 100 armor), the bolt marked aimed or not with `gmtest_xbow07_aimed(on)`, which sets the projectile's `isFromAimThrow` before it flies, as the aimed throw sets it on the bolt (`CThrowable`'s aiming state, `OnProcessThrowEvent`): aimed, at a bandit's `head` every bolt hit `head`, a headshot through all the armor, 113 (x2.26; not halved: aimed) and 125.5 on crits, at a griffin's `neck2` 203.4 and 225.9, each hit sending the event once from the damage and twice from the resistance read; not aimed, the same bones: no headshot, 100 armor points, 0 dealt, no event; three shots each, in each tree.
- *Regression check* `GMTest_xbow07` (`tests/gmTestsXbowHead.ws`): a Bodkin bolt's projectile, made as the crossbow makes it, hits a friendly human NPC created 50 m below Geralt through its own `ProcessDamageAction` (the replaced body with every wrapper of it): not aimed at `head` and `pelvis`, aimed at `head`, `neck2` and `torso2`; the hit is caught at the damage manager (not run: no damage, no event) and its headshot flag read; the NPC, the bolt entity and the bolt are removed in the same frame. Shown able to fail: on a throwaway build without the aimed condition the quick bolt read headshots at `head` and `pelvis` (FAIL); the real build passes. Regression 960 passed, 0 failed in each tree.
- *Not tested:* a behaviour tree waiting for the event (`CBTTaskKill`'s `onHeadshot`; no test NPC was found that uses it). An arrow or bolt marks a headshot only on an NPC (1.32, legacy and 5.x), so Geralt never takes one.
- *Regression:* 957 passed, 0 failed in each tree (no situation-free check added: the event needs a hit on an NPC).

**Found** (for the owner, 2026-10-26): every real quick shot at the nekker landed on its head (`k_neck_g`). From the code (`ReleaseProjectiles2`): a quick shot flies at the target's `torso2` bone, and when the target has none (the nekker's rig names every bone `k_..._g`) at the targeted position instead, which here lies at the head (the reason is inferred, not read in game). With 5.x's detection (DB1 (b)) every quick shot at a nekker is then a headshot, through all its armor; under legacy's names nekkers had no headshot at all. The audit checked every rig and shot each kind in a real fight: about half the quick shots at a fighting nekker, and most at wyverns and forktails (their jaw is a targetable part), are headshots; an owner decision ([audit F1](#xbow-audit-2026-10-26)), decided 2026-10-27: quick shots are never headshots, so none of this applies any more.

**Decisions:** DB1 (b) (project owner, 2026-10-26): 5.x's detection is kept. The signal: PB7 (confirmed (project owner, 2026-10-25)).
- **Deviation:** a bolt or arrow is a headshot when the bone it hits has `head`, `neck` or `hroll` anywhere in its name (and `pelvis` on humans), 5.x's rule, where legacy (as 1.32) needed those exact names: every bone this adds is a genuine neck or head shape (the list above), and it gives headshots to griffins and their kin, wyverns and forktails, fiends and chorts, and nekkers, which legacy's names never matched; wolves and panthers gain their neck (owner, 2026-10-26).
- **Deviation:** only an aimed bolt can be a headshot: a quick (non-aimed) shot of Geralt's is never one, whatever bone it hits, where legacy (and 1.32 and 5.x) let any bolt that hit a headshot bone count; under 5.x's targeting most quick shots at wyverns, forktails and nekkers land on the neck or head and would go through all their armor (audit F1); aimed shots keep DB1's wider detection, NPCs' arrows and bolts are unchanged (owner, 2026-10-27).

### XBOW-08 NPC bows and crossbows

| | |
|---|---|
| Kind | system, tuning |
| Pillars | P5, P2 |
| 5.x class | clean |
| Flags | balance |
| Depends on | DMG-08 (weapon damage read from the held item, signed off), DMG-01 to DMG-03 (the formula), DEF-08 (arrow parry) |
| Skill trees | n/a |
| Port form | `xbow/npcBows.ws`: `@addMethod W3ArrowProjectile.GMGetHeldWeaponDamage` (legacy's `GetHeldWeaponDamage`); `@wrapMethod W3ArrowProjectile.ProcessDamageAction` sets `projDMG` and `projSilverDMG` from the archer's held bow or crossbow, then 5.x's body; the eight NPC bow abilities given whole (`replace`, 5.x's weight nodes kept) in `gm_xbow.xml` (`gen_xbow.py`), NG+ copy |
| Port status | **signed off** (2026-10-27); ported (slice 5, 2026-10-25, 5.x-GM `fb1206fe`), verified in both trees |
| Open checks | The long bows, the elven bow, the dwarven and Nilfgaardian crossbows in an archer's hands (read from the data only: the two archer templates that stayed and shot carry `bow_01` and `crossbow_01`) |
| Save impact | none (expected): the damage is read from the held item at each hit |
| NG+ counterpart | applied (legacy's values; vanilla's NG+ bows equal its regular ones), untested |

**What it does:** an NPC's arrow or bolt deals the damage of the bow or crossbow it was shot from, instead of a fixed damage set in each projectile's entity ("damage is hardcoded in w2ent", legacy's comment), and the bows are retuned: the two plain bows 150 piercing (unchanged), long bows 200 → 180, the elven bow 250 → 200, the generic crossbow 150 → 220, the dwarven crossbow 200 → 240, the Nilfgaardian crossbow 250 → 220; silver 3 → 4 on all. The NPC's attack power and Geralt's armor then apply (DMG). A reflected arrow (Deflection, SKL-05) keeps its own damage: Geralt holds no bow.

**5.x:** an arrow deals its entity's damage: 200 for an archer's arrow (`arrow_01.w2ent`), 600 for a crossbowman's bolt (`bolt_01.w2ent`), and 5.x raises it by 2.5% per Geralt level each time the projectile collides (`W3AdvancedProjectile.OnProjectileCollision`, every advanced projectile; legacy's code has no such term). The bow abilities are 1.32's and unused for arrow damage. **Measured in game** before the port (2026-10-25, classic tree; real arrows from spawned archers on Geralt, Hard, his starting armor: 32.7 armor points, 5% piercing resistance): at Geralt level 1 a Skellige bandit's arrow read 205 and took 376 Vitality (of 3,500); at level 30 the same arrow read 350 and took 694 (of 5,380), a renegade crossbowman's bolt read 1,050 and took 2,223.

**Port** (slice 5, 2026-10-25, 5.x-GM `fb1206fe`). Verified in both trees. How each check was tested (**real NPC shots** from archers spawned by script, `gmtest_xbow08_archer`: a Skellige bandit with `bow_01` and a renegade crossbowman with `crossbow_01`, hostile, 12 m in front of Geralt; Geralt level 30, made immortal by script so he takes and reports damage; each arrow's hit logged by a test wrapper of `ProcessDamageAction`):

- *Arrows on Geralt:* every arrow read its bow's damage, 150 piercing and 4 silver (`bow_01`, legacy's `Bow 1`), and took 256 Vitality (150 less 32.7 armor points, less 5%, ×2.3 for Hard, 5.x's value then; ×2 since DIFF's slice D1); every bolt 220 and 4 (`crossbow_01`, legacy's `Crossbow 01`) and took 409; in each tree. Before the port, at the same level: 694 and 2,223. The archers' attack power was ×1.
- *Reflected arrows* (Deflection: classic `sword_s10`, new `S_Sword_s33`, level 1; the guard up by script, a parry press stamped at each arrow's impact, `gmtest_ench11_a(true, true)`): each reflected arrow hit the archer with its own damage, not a bow's (Geralt holds none): 612.5 (200 × 1.75 × 1.75: 5.x's level term at Geralt and again at the archer), 669.5 after SKL-05's pool; two arrows killed the archer, in each tree; Geralt lost nothing.
- *The data* (scripted read, regression `GMTest_xbow08`): the eight bow and crossbow abilities' piercing and silver damage equal legacy's; `gen_xbow.py --verify`: equal to legacy's, regular and NG+.
- *Regression:* 957 passed, 0 failed in each tree.

**Decisions:** PB8 (confirmed (project owner, 2026-10-25)); the boundary (DB2, confirmed (project owner, 2026-10-25)): NPC bows are XBOW's, other NPC weapons AI's.
- 5.x's level term on projectile damage (+2.5% per Geralt level at each collision) is gone from every projectile since AI-18 (slice C2, 2026-10-28, 5.x-GM `f32f3f59`, [ai.md](ai.md#ai-18-special-attacks-and-monster-projectiles); until then a temporary deviation, confirmed by the owner, 2026-10-26): a reflected arrow reads the arrow's 200 at Geralt level 30 (5.x: 612.5), 453 after SKL-05's pool (**real** reflected arrows, Deflection in each tree).

### XBOW-09 NPC archers' stamina

| | |
|---|---|
| Kind | system |
| Pillars | P2 |
| 5.x class | clean |
| Flags | — |
| Depends on | STAM-08 (NPC stamina, signed off) |
| Skill trees | n/a |
| Port form | `class CBTTaskShootDef extends CBTTaskPlayAnimationEventDecoratorDef { default xmlStaminaCostName = 'light_action_stamina_cost'; default drainStaminaOnUse = true; }` (as STAM-08's attack default); `@replaceMethod CBTTaskShoot.IsAvailable` adding the decorator's own check (`super.IsAvailable()`), in `stamina/npcStamina.ws` |
| Port status | **signed off** (2026-10-27); ported (slice 5, 2026-10-25, 5.x-GM `fb1206fe`), verified in both trees |
| Open checks | — |
| Save impact | none |
| NG+ counterpart | none |

**What it does:** an NPC archer's shot costs its light-attack stamina cost and is not taken without it, like every other NPC attack (STAM-08). Not in the changelist (an omission); STAM-08's mapping missed the shot task, which is not an attack task (`CBTTaskShoot` extends the animation decorator directly).

**5.x:** 1.32's task; shooting was free: **seen in game** before the port (2026-10-25), the archers' stamina stayed at 100 at every shot.

**Port** (slice 5, 2026-10-25, 5.x-GM `fb1206fe`). Verified in both trees with **real NPC shots** (archers spawned by script as for XBOW-08; each start of the shoot task and each release logged with the archer's stamina by test wrappers): each shot of the bandit archer and of the renegade crossbowman cost 25, their light-attack cost (100 → 75 at the task's start), and STAM-08's regen brought them back to 100 before the next shot (one shot every 4 to 8 s). With the crossbowman's stamina set to 0 and its regen paused by script for 15 s (`gmtest_xbow09_stamina`), it took no shot (the shoot task refused for lack of stamina, no arrow in about 13 s) and stayed at range; once its regen ran it shot again at 34 stamina (34 → 9); in each tree. Regression 957 passed, 0 failed in each tree. Regression check: `GMTest_xbow09` (a new `CBTTaskShootDef` reads the light-attack cost, drained and checked; fails on 5.x's defaults), added by the audit's fix slice T (2026-10-26).

**Decisions:** PB9 (confirmed (project owner, 2026-10-25)).

### XBOW audit (2026-10-26)

Done by a fresh session ([audit](../feature-mapping.md#audit-signing-a-feature-off)) on 5.x-GM `8d2185d6` and master `3799ad2f`, reading code and data, with game runs for the regression in both trees and for the nekker question. Every method XBOW's seven 5.x-GM commits replace, wrap or add was read against legacy's code (`legacy-GM`), 1.32 (`master`) and 5.x (`vanilla-5.x`), with the earlier areas' replacements it lands in. The data as the game reads it was compared with legacy's by a script written for this audit, independently of `gen_xbow.py --verify`: every `<ability>` and `<item>` entry of legacy's eight XBOW files (the base game's and Blood and Wine's bolts, the crossbow files of the base game, Blood and Wine, the free DLC and Hearts of Stone, both NPC weapon files), regular and NG+ (480 entries), against 5.x's entry merged with every Ghost Mode DLC entry of that name in the DLC's `items` folder (`extend` replacing sub-nodes in order by tag, `replace` whole), node by node with the tags' text; the explosive bolt's entity byte by byte and through `cr2w_dump.py` against 5.x's and legacy's.

**Checked and holding:** the data: the fourteen bolt abilities, the seventeen crossbow abilities and the eight NPC bow and crossbow abilities equal legacy's in both folders, but for the crossbows' weight nodes (WGT's, as recorded); the bolt and crossbow items equal legacy's but for prices and weights (ECON, WGT) and `mod_legendary` (ECON: legacy removed it from the Split and Explosive Legendary bolts and gave it to the Ofir Crossbow R); the sale tags (twelve special bolts sellable, Bodkin, Harpoon and the quest bolt not, no `mod_nosalem`) and the two quest crossbows' base abilities are legacy's; the other entries of those files that differ (NPC swords and torches, the Ofir sabres' and the Caretaker's shovel's weights) are AI's, SWD's and WGT's. The explosive bolt's entity is 5.x's with `explosionRange` 5 → 3 in both its copies and nothing else (legacy's value). Scripts: XBOW-05's three wrappers (legacy's two fixes; the name set at the throw on every projectile, the deviation; the blast's `super.ProcessDamageAction` goes through the wrapper, so a blast skips a victim the bolt already hit, as legacy), XBOW-06's two lines in the replaced crit functions (legacy's horse condition and held-weapon loop; legacy's other changes there are SKL-14's, ALCH-14's, ARM-09's), XBOW-07 (the event where legacy sends it: Geralt's headshot that deals damage, inside `wasAlive && DealsAnyDamage`, and the headshot branch of `GetDamageResists`, after the fistfight branch as legacy; removed from the crit check; the +50% crit chance stays there), XBOW-08's wrapper and `GMGetHeldWeaponDamage` (legacy's code; it overwrites `projDMG` after 5.x's level term was added at the collision, so an archer's arrow deals its bow's damage only, and Geralt's bolts, a subclass with their own `ProcessDamageAction`, never pass through it), XBOW-09 (legacy's two defaults and `IsAvailable`; 5.x's other changes to the task kept). 5.x's own crossbow changes are kept (PB10). `check_modsigns.py` 0 unmarked (424 bodies), no native wrap; `deviations.py --check` current; `gen_xbow.py --check` and `--verify`, `gen_item.py --check`, `gen_ngplus.py --check` pass. Completeness: every XBOW unit in [attribution.csv](attribution.csv) is ported; the changelist's Crossbow section and bugfixes 161 and 162 are ported here or by the areas in [Scope](#scope) (dismantling: bolts have no parts, CRAFT; crafting price: ECON); every hand-off to XBOW in the other areas' files (DMG, EFX, SWD, ITEM, CRAFT, SKL, MUT, UI, LOOT, STAM) is placed in [hand-offs received](#hand-offs-received); ITEM's "bolt quality changes": legacy changed no bolt's quality (the data comparison). XBOW's own hand-offs (ECON, WGT, AI, FIX, DIFF) are listed in its [table](#hand-off-to-other-areas), the convention for areas not mapped yet. `unit_sweep.py --unattributed` (crossbow, bolt, bow, headshot, aim, xbow, `W3BoltProjectile`, `W3ArrowProjectile`, arrow, `projDMG`, ammo, `BTTaskShoot`): no XBOW unit missing; the hits are other areas' (AI: monster projectiles, `CNewNPC.ReactToBeingHit`; XP: Crach's reward's level and experience; Hearts of Stone NG+ items; debug commands). Deviations: XBOW-05's, XBOW-07's and XBOW-08's, in the entries and in [deviations.md](deviations.md) in the right format; the owner's decisions as implemented (PB1 to PB12, DB1 (b), DB2). Both trees: no XBOW code reads a skill; the crossbow skills that add to bolt hits are SKL-06's and SKL-18's; the slices' shots and the regression ran in both trees. Tests: `GMTest_xbow01`, `_xbow02` (with `_xbow03`) and `_xbow08` compare the game's reads with fixed legacy values and fail on 5.x's data; `GMTest_xbow04`'s blast check reads a spawned entity (its bolt-name check: F2). Regression on the audited build: 957 passed, 0 failed in each tree, `gmtest_panel()`'s checks passing (one launch; the new tree set with `GMClassicSkillTree` false and `gmreset()`, then restored).

**Findings:**

1. **Quick shots at nekkers, wyverns and forktails are mostly headshots** (owner decision; the question from XBOW-07). A quick shot flies at the target's targetable part if it has one (5.x, PB10), else at its `torso2` bone, else at the point Geralt looks at (`ReleaseProjectiles2`). Read by script on all 179 NPC templates whose ragdoll has a headshot bone under 5.x's rule: the skeletons without `torso2` are the wolves, wargs, white wolves, wild dogs and barghests, the griffins, archgriffins, cockatrices and basilisks, the fiends and chorts, the forktails and wyverns, and the nekkers and nekker warriors (every other one has it); the base game's wyverns and the forktails also have a targetable part, `jaw`, so a quick shot flies at the jaw (Blood and Wine's wyverns have none). **Real quick shots** in a real fight (each monster spawned hostile 6 m away, Geralt made invulnerable, hard lock-on, Bodkin bolts, Crossbow 1, classic tree; the bone of each hit logged): wyvern 9 headshots of 10 hits (`neck2`, `neck1`), forktail 7 of 10 (`neck2`, `neck1`), nekker 9 of 16 (`k_neck_g`; the porter's 5 of 5 were on a frozen dummy); the others only now and then: griffin 2 of 9, wolf 1 of 10, fiend 1 of 5, cockatrice 1 of 8, chort 0 of 10, basilisk 0 of 9; a drowner (with `torso2`) 0 of 10 and a human dummy 0 of 3, all on the torso. Play effect: in Ghost Mode a headshot ignores all armor and resistances and gets +25% attack power and +50% crit chance, so the plain quick shot (the button tapped, no aiming) at a wyvern, forktail or nekker usually goes through all its armor; under legacy's exact bone names these monsters had no headshot at all, and legacy's quick shots (1.32's code: no targetable parts) flew at the look-at point. Options: (a) keep (5.x's targeting and DB1's detection as they are); (b) quick shots at a monster without `torso2` aim at a body bone, and quick shots ignore the targetable part (closest to legacy's targeting; undoes part of PB10's 5.x feature); (c) only aimed shots can be headshots (a quick shot never is; the port already knows an aimed throw, `GMIsFromAimThrow`, SKL-06): headshots become the aimed shot's reward on every monster, a deviation from legacy, where a quick shot that scattered onto a human's or wolf's exact `head` or `neck` counted (none did in the samples above). Recommendation: (c): it keeps DB1's wider detection for aimed bolts (griffins, wyverns, fiends, nekkers get headshots when aimed at), removes the free armor-ignoring quick shots against the three groups whatever the rig or targeting, and fits the changelist's crossbow ("non-aimed shots deal 50% less damage"); (b) is the alternative if quick-shot headshots on humans and wolves should stay possible. **Decided** (project owner, 2026-10-27): (c), a deviation (XBOW-07). **Fixed** (5.x-GM `170f4ad1`), **verified** in both trees (2026-10-27): real quick shots in a real fight at a wyvern, a forktail and a nekker hit their neck or head bones and none was a headshot; scripted aimed bolts at a human's head and a griffin's neck were headshots through all armor with the event, the same bolts not aimed were not; regression check `GMTest_xbow07`, shown able to fail (details in [XBOW-07](#xbow-07-headshots)); regression 960 passed, 0 failed in each tree.
2. **A regression check that cannot fail** (clear fix, test-only). `GMTest_xbow04`'s "XBOW-05 a bolt keeps its item's name for the hit" sets the field with `GMSetBoltItemName` and reads it back, so it tests nothing of the fix; the entry counted it as the regression's check of XBOW-05. Fix: throw a bolt entity made as the crossbow makes it (`GetDeploymentItemEntity`, `InitializeCrossbow`, as `gmtest_xbow07_shoot` does) through `ThrowProjectile` and read the name it carries, or drop the check and say XBOW-05 has none. XBOW-09 has no regression check either; a check of `CBTTaskShootDef`'s two defaults (as a new task definition reads them) would cover it. **Fixed** (fix slice T in 5.x-GM `b01f8737`), **verified** in both trees (2026-10-26): `GMTest_xbow04`'s second check (`GMTestXbow05Throw`, `tests/gmTestsXbow.ws`) makes a Split bolt's projectile entity as the crossbow does (`GetDeploymentItemEntity`, `InitializeCrossbow`), throws it through `ThrowProjectile` 50 m below Geralt and reads the name on each of the shot's three projectiles (the wrapper's code path, the split copies included: the deviation); the projectiles are destroyed before the release timer fires, so no bolt flies or is used, and the bolt added, the stamina the throw costs (STAM-03), its regen pause and the `crossbow_was_fired` fact are put back (logged). `GMTest_xbow09` (`tests/gmTestsXbowNpc.ws`, in the regression) reads a new `CBTTaskShootDef`: cost `light_action_stamina_cost`, drained, checked. Both shown able to fail: on a throwaway build without the wrapper's naming loop and without the `CBTTaskShootDef` defaults, in game, the XBOW-05 check read `None` on all three projectiles and XBOW-09 read `None`, not drained: both FAIL; on the real build both pass. Regression 958 passed, 0 failed in each tree (957 with the old check, plus XBOW-09), `gmtest_panel()`'s checks passing.
3. **"NPC arrows hitting Geralt's head"** (doc-only; **corrected**). XBOW-07's "not tested" listed it, but an arrow or bolt marks a headshot only on an NPC victim (`(CNewNPC)victim`, in 1.32, legacy and 5.x), so nothing hits Geralt's head; the event goes to NPCs only (an archer's arrow on another NPC, a reflected arrow on its archer).
4. **XBOW-06's unexplained ×0.11** (doc-only; **corrected**). The 0.11 attack power that came with Weeper drawn is Weeper's own `attack_power` (+8 to 15%), which counts for bolts while the sword is drawn, in 1.32, legacy and 5.x (legacy keeps only crit chance and crit damage apart); not a deviation.
5. **Stale status and claims** (doc-only; **corrected**). The status line ran two slices together; XBOW-07's finding said every quick shot at a nekker hits its head and that other rigs were not checked (F1 answers both). MUT-11's open check lists Cat Eyes' pierce as untested, but XBOW-05's shots saw it (explosive bolts pierced and exploded again; plain bolts pierce and hit once): [mut.md](mut.md) updated.
6. **Not verified in game** (no action; open checks). As the entries list them: aimed shots (the real key held), a bolt crit with a crossbow's crit damage and Cold Blood's adrenaline with legacy's crossbows (read from the data), a sword hit while the crossbow is held, the long bows, elven bow and dwarven and Nilfgaardian crossbows in an archer's hands, a behaviour tree waiting for the Headshot event, the last Split bolt in legacy ([list to test](../open-questions.md#to-test-in-legacy-ghost-mode)), NG+ (policy).

**Doc corrections made with the audit:** F3 (XBOW-07), F4 (XBOW-06), F5 (the status line, XBOW-07's finding, [mut.md](mut.md)'s MUT-11), the [status page](README.md#where-the-port-stands); [game-automation.md](../game-automation.md#input-simulation): quick shots at a real fighting monster and the frozen nekker that bolts missed.

**Not reviewed:** nothing of XBOW's code, data or docs. Not done: the open checks (F6); the barghests and Blood and Wine's wyverns were not shot (same skeletons as the wolves and, without the jaw part, as the griffins' kind of fallback); legacy's own behaviour in play ([list to test](../open-questions.md#to-test-in-legacy-ghost-mode)). Out of scope: the other areas' entries in the shared files and functions (SKL-06's crossbow skills, DMG's headshot terms, STAM-03's bolt stamina, ECON's prices, WGT's weights).

**Suggested fix slices:**

- **T, tests** (`tests/gmTestsXbow.ws`, `tests/gmTestsXbowNpc.ws`): F2. **Done** (2026-10-26, 5.x-GM `b01f8737`), verified in both trees.
- **Owner decision:** F1 (quick-shot headshots): (c) decided 2026-10-27; **done** (5.x-GM `170f4ad1`), verified in both trees.

#### Audit close-out

Closed 2026-10-27: every finding is fixed, corrected or recorded, and the owner's decision is made and implemented. Fixed and verified in both trees: F1 (the owner's (c), 2026-10-27: only aimed shots can be headshots, a deviation; 5.x-GM `170f4ad1`), F2 (fix slice T, 5.x-GM `b01f8737`). Corrected in the docs: F3, F4, F5. Recorded: F6 (the open checks). Checks at close: regression 960 passed, 0 failed in each tree, `gmtest_panel()`'s checks passing; `check_modsigns.py` 0 unmarked (425 bodies), no native wrap; `deviations.py --check` current; `gen_xbow.py --check` current. XBOW was **signed off** by the project owner (2026-10-27). What stays open: the open checks in the entries (F6, now with an aimed Split bolt's copies); legacy's own behaviour in play ([list to test](../open-questions.md#to-test-in-legacy-ghost-mode)).

---

### Dependencies on other areas

- **Done areas XBOW builds on:** DMG (the formula, headshots, the pool's underwater exception, weapon damage from the item), STAM-03 and STAM-08 (bolt and NPC stamina), SKL-06 and SKL-18 (the crossbow skills, the non-aimed rule, In Combat's Fires), MUT-11 and MUT-13 (Cat Eyes, effect chances), ITEM-01 (bolt and crossbow levels), EFX-01 and EFX-02 (bleeding values, the frozen hit), UI-01, UI-02, UI-07 (the panel and tooltip rows), CRAFT-01 and CRAFT-08 (schematics, dismantling), LOOT-05 and LOOT-09 (where bolts are found), DEF-08 and SKL-05 (arrow parry and reflection).
- **Areas XBOW shares with or waits for:** ECON (bolt and crossbow prices, `mod_legendary`), WGT (weights), AI (flyers forced to land, archers' templates and levels, monster projectiles), FIX (projectile collisions), DIFF (NPC archers' levels).

### Hand-offs received

Every item other areas handed to XBOW, and where it lands:

| From | Item | XBOW |
|---|---|---|
| DMG (hand-off) | Crossbows' armor piercing and bolts (62 units) | XBOW-02 (armor piercing), XBOW-01 (bolts) |
| DMG (hand-off), DMG-02 (depends on) | Headshots ignoring armor and resistances | Ported by DMG-02 and DMG-03 (verified 2026-10-07); detection and the signal: XBOW-07 |
| DMG (hand-off), DMG-08 (depends on) | NPC bow damage (`W3ArrowProjectile.ProcessDamageAction`, `GetHeldWeaponDamage`) | XBOW-08 |
| DMG (hand-off) | The underwater multiplier | Nothing to port: 1.32's, unchanged by legacy, kept outside the pool by DMG-04 (DD1's exception) |
| EFX (scope, hand-off), EFX-01 (open check) | The bolts' effect chances (`blunt_bolt`, `broadhead_bolt`, `tracking_bolt`, `explosive_bolt` and the Legendary versions); a real broadhead or tracking bolt | XBOW-01; its slice's real shots close EFX-01's open check |
| SWD (scope, hand-off) | `def_item_weapons_crossbow(s).xml`, the Ofir crossbows; about 60 units left unattributed | XBOW-02 (all crossbow abilities, the two quest crossbows' items); the crossbow items' other fields: CRAFT-08 (parts), ECON (prices), WGT |
| ITEM (scope, hand-off) | Bolt and crossbow levels; the bolt level list's fix (`Blunt Bolt Legendary`); bolt quality changes | Levels: ported by ITEM-01 (DI1, verified 2026-10-20); XBOW-02 moves the crossbow levels through their attack power. Quality: legacy changed no bolt's `quality`; it removed the `mod_legendary` price tag from the Split and Explosive Legendary bolts (ECON) |
| CRAFT (scope, hand-off) | Bolt and crossbow stats; the quest bolt's `mod_nosale` tag fix | XBOW-01, XBOW-02; XBOW-03 |
| SKL (hand-off) | Crossbow crit rules in `CR4Player.GetCriticalHitChance`/`GetCriticalHitDamageBonus` | XBOW-06 (the melee-only skill and oil terms are ported by SKL-03, SKL-14, DEF-07) |
| SKL (hand-off) | NPC bow damage | XBOW-08 |
| SKL (hand-off) | Crossbow stat lines | Ported by UI-02 (signed off) |
| SKL-06 (depends on) | XBOW for the crossbow skills, both trees | The skills are ported (SKL-06, SKL-18); XBOW's slices re-run their checks in both trees |
| MUT-11 (depends on), MUT (hand-off) | Cat Eyes: bolt damage, non-aimed bolts, `GetOffenseStatsList` | Ported by MUT-11 (bolt damage, slow motion), SKL-06 (non-aimed bolts), UI-01 (the list); XBOW's slices may take MUT-11's open checks (pierce and knockdown, the 15% health loss) |
| UI (depends on) | Bolt values in the panel and tooltips (UI-01, UI-07), bolt knockdown | The panel reads the equipped bolt (UI-01) and the knockdown row reads `desc_knockdownchance_mult`: both show XBOW-01's values once ported |
| LOOT-09 (depends on) | Bolts | Ported by LOOT-09 (the standalone starts' bolts) and LOOT-05 (loot lists); the bolts' definitions are XBOW-01 and XBOW-03 |
| STAM (attribution note) | `ReleaseProjectiles2`'s bolt name | XBOW-05 |
| feature-mapping (roadmap) | The `XBOW` area | this file |

### Hand-off to other areas

| Area | Changes |
|---|---|
| ECON | Bolt, crossbow and schematic prices (the bolt and crossbow items, `DLC13` crossbow items, bolt and school crossbow schematic items); `mod_legendary` on the Split and Explosive Legendary bolts (removed) and the Ofir Crossbow R (added) |
| WGT | Bolt weights (0.05), crossbow weights (items and the weight nodes of the Toussaint, DLC13 and Ofir abilities) |
| AI | `CNewNPC.ReactToBeingHit`: a flying enemy hit by a bolt, Yrden or burning (or any damaging hit) is forced to land (knockdown applicator), already AI's from SKL and EFX; the Skellige bandit and pirate archers' and the Emhyr quest crossbowman's levels and attack ranges (with DIFF); monster projectiles; 5.x's level term on projectile damage (`W3AdvancedProjectile.OnProjectileCollision`: +2.5% per Geralt level at each collision; legacy's code has none), removed by AI-18 (slice C2, 2026-10-28), which ended XBOW-08's deviation |
| FIX | The W3EE collision fixes: `W3ArrowProjectile.OnProjectileCollision`'s groups (also DEF-08's note), `CBTTaskShoot.ShootProjectile`, `CBTTaskProjectileAttack.Initialize`; the arrow fix for Yoana's armor test (`sq108_heavy_armor`, bugfix 144) |

### Save impact

None expected: bolt and crossbow abilities are read when a bolt hits, tags from the definition, the explosive bolt's entity is spawned per shot, the new field is not saved. Confirmed for XBOW-02 (2026-10-25): an owned Ravix of Fourhorn or Geralt of Rivia crossbow takes its new base ability when the save loads. Adding or removing the mod mid-playthrough is not supported ([save compatibility](../feature-mapping.md#save-compatibility)).

### Area decisions

**Decided** (project owner, 2026-10-25; DB1 2026-10-26):

| # | Question | Decision |
|---|---|---|
| DB2 | The boundary | As recommended: as in [Scope](#scope): NPC bows and crossbows (damage, archers' stamina) are XBOW's, other NPC weapons AI's; the flyers' forced landing AI's; prices ECON's, weights WGT's, `mod_legendary` ECON's; the projectile collision fixes FIX's; the archers' levels AI's and DIFF's |
| PB1 to PB12 | The porter's calls below | All confirmed as proposed |
| Port order | [Port order](#port-order) | Confirmed as proposed |
| DB1 | Which hits are headshots (XBOW-07): 5.x changed it | (b), 5.x's rule (2026-10-26): any bone whose name contains head, neck or `hroll` (a human's pelvis); in the game's rigs it adds only neck or head shapes (`neck1`, `neck2`, `k_neck_g`; the [list](#xbow-07-headshots)), so griffins, wyverns, fiends and nekkers get headshots. A deviation (XBOW-07) |

**Porter's calls** (confirmed by the project owner, 2026-10-25):

| # | Call |
|---|---|
| PB1 | XBOW-01: legacy's fourteen bolts whole, including the Bait and Tracking bolts' 1.32 armor piercing removed and the tracking and broadhead bolts' own `duration` dropped (their bleeding lasts EFX-01's 16 s and 8 s) |
| PB2 | XBOW-02: legacy's crossbows; the Ravix of Fourhorn and Geralt of Rivia crossbows on Toussaint Crossbow 1's stats (level 34, 1.32: 38); every crossbow's level follows ITEM-01's formula (the Lynx crossbow 38 → 27, the Ofir crossbow 22 → 32); 5.x's weight nodes kept (WGT) |
| PB3 | XBOW-03: bolts sellable with XBOW (legacy's tags), at 5.x's prices until ECON; the quest bolt's tag fixed |
| PB4 | XBOW-04: the 3 m blast as a binary edit of the entity (`cr2w_patch.py`), as legacy did, rather than a script override |
| PB5 | XBOW-05: legacy's two fixes, each after a check in game that 5.x still has the bug (dropped as `in-5.x` if not) |
| PB6 | XBOW-06: legacy's crit rules: no horse crit for bolts, each weapon's crit damage kept with it |
| PB7 | XBOW-07: legacy's headshot signal (on damage dealt and in the resistance read; not in the crit check) |
| PB8 | XBOW-08: legacy's NPC bow damage from the held bow, through a wrapper of 5.x's `ProcessDamageAction`; legacy's bow values |
| PB9 | XBOW-09: NPC shots cost and need the light-attack stamina cost (STAM-08's rule; found by XBOW's sweep) |
| PB10 | 5.x's own crossbow changes that legacy did not touch are kept: quick shots at a large monster's targeted part, the bolt range read from diving and slower underwater bolts, no controller vibration |
| PB11 | NG+: vanilla's and legacy's NG+ bolt, crossbow and bow entries equal their regular ones, so the NG+ copies carry legacy's values ([NG+ numbers](../feature-mapping.md#ng-numbers)) |
| PB12 | Attribution: XBOW is added to the shared units it changes (the two crit functions, `ProcessAction`, `ProcessCriticalHitCheck`, `GetDamageResists`, `ReleaseProjectiles2`, the two quest crossbows' items); no code change |

### Port order

Confirmed by the project owner (2026-10-25). Each slice compiles and is verified on its own, in both trees (the crossbow skills add to every bolt hit), on a neutral test dummy with quick shots through the combat action (`gmtest_skl06_throw`) and the damage probe; an aimed shot needs the real key held (SKL-06's open check). The regression runs after each slice.

| # | Slice | Ends |
|---|---|---|
| 1 (**done** 2026-10-25, 5.x-GM `ae77f0c2`) | XBOW-01, XBOW-03: the bolts' data and tags, a generator with `--verify`; real quick shots with each special bolt (damage against an armored dummy, the effect chances over many shots, Target Point through full armor), a bolt sold to a merchant | EFX-01's open check (a real broadhead and tracking bolt) |
| 2 (**done** 2026-10-25, 5.x-GM `8954b0cd`) | XBOW-02: the crossbows' data and the two quest crossbows; levels read by script; shots with a high-level crossbow against armor; an owned quest crossbow after a load | — |
| 3 (**done** 2026-10-25, 5.x-GM `b67b9f49`) | XBOW-05, XBOW-04: first a check that 5.x has the two bugs (the last bolt of a stack, an explosive bolt next to one dummy); the fixes; the 3 m blast with dummies at 2.5 m and 4 m | — |
| 4 (XBOW-06 **done** 2026-10-25, 5.x-GM `5c53d564`; XBOW-07 **done** 2026-10-26, `8d2185d6`) | XBOW-06, then XBOW-07 once DB1 is decided: the crit rules (a scripted bolt crit with a sword drawn, on horseback); for DB1, the list of every bone 5.x's rule adds over legacy's exact names, per monster and human rig, for the owner; headshots (scripted hits on named bones) after the decision | DB1 decided |
| 5 (**done** 2026-10-25, 5.x-GM `fb1206fe`) | XBOW-08, XBOW-09: a spawned archer's arrows on Geralt (damage against the bow's), its stamina per shot and its refusal at 0 | — |

**Later:** —
