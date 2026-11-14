# XBOW: crossbows and bolts

Geralt's crossbows and bolts, and the bows and crossbows of NPC archers: what a bolt deals, pierces and inflicts, what a crossbow adds, how critical hits and headshots work for bolts, and what an NPC's arrow deals. Ghost Mode's changelist has its own section (660–671): "You can now have a decent crossbow build, if you invest into crossbow skills. If not, it's still a utility weapon to bring down flying enemies and apply special effects from bolts": non-aimed shots deal 50% less damage, damage from own bolts is no longer halved, bolts and crossbows reworked ("damage and effects tweaked"), the explosive bolt's explosion range 5 → 3, headshots ignore armor and resistances and add 50% crit chance, bolts can be sold and bought at a reasonable price but not dismantled. The bugfix list adds the last bolt of a stack (161) and explosive bolts hitting the same target up to three times (162). The code and data have more than the changelist (NPC bow damage, the crossbows' crit rules, NPC archers' stamina).

**What 5.x did in this area** (from `vanilla-5.x`). The data is 1.32's: every bolt, crossbow (the Hearts of Stone, Blood and Wine and free-DLC crossbows included) and NPC bow has 1.32's values in `def_item_bolts.xml`, `def_item_weapons_crossbow(s).xml`, `dlc13_items.xml`, `def_item_npcweapons.xml`, regular and NG+ (equal in both); 5.x added no crossbow or bolt. The explosive bolt's entity is 1.32's (5 m blast). The code changed in five places: a bolt or arrow counts as a headshot when the bone it hits has `head`, `neck` or `hroll` anywhere in its name (and `pelvis` on humans), where 1.32 needed those exact bone names (`W3BoltProjectile.ProcessDamageAction`, `W3ArrowProjectile.ProcessDamageAction`); a quick shot at a large monster with targetable parts flies at the part Geralt targets, not at its torso (`ReleaseProjectiles2`, `HasVirtualControllerTarget`); a bolt shot while diving gets the underwater range and 60% speed, otherwise the full range (1.32: the full range while swimming, the underwater range otherwise); the controller vibration on firing is gone; the new tree's crossbow skills (Lightning Reflexes' headshot damage and instant kill, Maiming Shot's arming, Anatomical Knowledge's silver-sword damage on bolts), which SKL-06 removed. The underwater bonus (×3, ×7 in NG+), the bolt minimum of 1 damage, the effect-chance rule and the split and explosive bolts' code are 1.32's.

**How legacy Ghost Mode implements it.** Data: the fourteen bolt abilities and twelve bolt items (`def_item_bolts.xml`), the quest bolt (`q704_vampire_lure_bolt`), ten crossbow abilities, the two Toussaint crossbow abilities and the two quest crossbows that use them, the three free-DLC and two Ofir crossbow abilities, eight NPC bow and crossbow abilities, each regular and NG+ (equal), and the explosive bolt's entity (`explosive_bolt.w2ent`). Scripts: the bolt's hit (`W3BoltProjectile.ProcessDamageAction`, `OnProjectileInit`, a new field, a line of `ReleaseProjectiles2`), an NPC arrow's damage (`W3ArrowProjectile.ProcessDamageAction`, new `GetHeldWeaponDamage`), the crit functions (`CR4Player.GetCriticalHitChance`, `GetCriticalHitDamageBonus`), the headshot signal (`ProcessAction`, `ProcessCriticalHitCheck`, `GetDamageResists`), the NPC shot task (`CBTTaskShoot.IsAvailable`, `CBTTaskShootDef`).

Unit lists: [attribution.csv](attribution.csv) (112 units carry an XBOW feature: 7 script units, 52 XML units and their 52 NG+ copies, 1 binary file; 10 shared units carry XBOW beside other features: the two quest crossbows' items and their NG+ copies, the two crit functions, `ProcessAction`, `ProcessCriticalHitCheck`, `GetDamageResists`, `ReleaseProjectiles2`).

**Status:** every feature ported and verified in both trees. Signed off by the owner (2026-10-27).

## Scope

**XBOW covers** the bolts' damage, armor piercing and effects (and the bolts' sale), the crossbows' attack power, armor piercing, crit damage and adrenaline, the explosive bolt's blast, the bolt's hit fixes (the last bolt of a stack, one hit per target), the crossbow crit rules, headshot detection and its signal, the damage of NPC bows and crossbows, NPC archers' stamina.

**Ported by other areas:**

| Subject | Ported by | What |
|---|---|---|
| Non-aimed bolts and bombs deal 50% less | SKL-06 | The final-damage step, `CThrowable.GMIsFromAimThrow`, both trees; reflected arrows exempt |
| The crossbow skills | SKL-06, SKL-18 | Lightning Reflexes (classic `sword_s13`, new `sword_s32`), Steady Shot (`sword_s15`; the new tree's Cold Blood `sword_s34` carries it), Anatomical Knowledge (`sword_s7`, `sword_s26`), Crippling Shot (`sword_s12`, `sword_s27`), Cold Blood (`perk_2`, `sword_s34`), Trick Shot (`perk_17`, `perk_27`), In Combat's Fires (`perk_16`, `perk_44`) |
| Own bolts and bombs not halved for Geralt | SKL-18 | 5.x's halving of own bombs removed (legacy, "make Perk_16 more valuable"); 1.32 never halved own bolts, so the changelist's line changes nothing for them |
| Headshots ignore armor and resistances, +25% attack power | DMG-02, DMG-03 | `damage/formula.ws`; the +50% crit chance is 1.32's and 5.x's (`HEAD_SHOT_CRIT_CHANCE_BONUS`) |
| No additive attack power for bolts, the bolt minimum of 1 | DMG-03, DMG-01 | `damage/formula.ws`, `damage/pipeline.ws` |
| Underwater bolts ×3 (×7 in NG+) | DMG-04 | Kept a multiplier outside the pool (DD1's exception), 1.32's rule, which legacy did not change |
| Bolt stamina cost, crossbow refused without stamina (on foot, horseback) | STAM-03 | `stamina/actionStamina.ws` |
| Cat Eyes (Mutation 9): bolt damage ×2, slow motion, panel | MUT-11, UI-01 | Its pierce, stun and knockdown and the 15% health loss are vanilla's code |
| Bolt levels, crossbow levels from attack power (steps to 34 and 38) | ITEM-01 | Legacy's name list with `Blunt Bolt Legendary` 12 (DI1); the crossbow steps read XBOW-02's values |
| Bleeding of tracking and broadhead bolts (0.5% for 16 s, 1% for 8 s) | EFX-01 | `gm_effects.xml`; how often a bolt applies it is XBOW-01's |
| A bolt shattering a freeze | EFX-02 | The freeze bonus, no knockdown |
| The crossbow panel lines, the bolt knockdown tooltip row | UI-01, UI-02, UI-07 | The list reads the equipped bolt; the row reads `desc_knockdownchance_mult`, which XBOW-01 gives the blunt bolts |
| Bolt schematics' ingredients, crossbow dismantling parts | CRAFT-01, CRAFT-08 | |
| Bolts in loot lists and the standalone starts | LOOT-05, LOOT-09 | |
| Arrows parried without a skill, reflected with Deflection | DEF-08, SKL-05 | |

**Not XBOW** (confirmed by the owner with DB2, 2026-10-25):

| Subject | Area | Why |
|---|---|---|
| Item prices (bolts, crossbows, schematics; the `mod_legendary` price tag removed from the Split and Explosive Legendary bolts and given to the Ofir Crossbow R) | ECON | Every area left prices to ECON |
| Item weights (bolts 0.05, crossbows; the weight nodes in crossbow abilities) | WGT | |
| Flyers forced to land by any bolt, Yrden or burning hit (`CNewNPC.ReactToBeingHit`) | AI | The rule covers more than bolts |
| Projectile collision fixes (arrows and bolts stop at debris, foliage, doors, fences: `W3ArrowProjectile.OnProjectileCollision`, `CBTTaskShoot.ShootProjectile`, `CBTTaskProjectileAttack.Initialize`); the Yoana's-armor arrow fix (`sq108_heavy_armor`, bugfix 144) | FIX | |
| Skellige bandit and pirate archers', the Emhyr quest crossbowman's level and attack ranges (`skellige_*_bow.w2ent`, `*_crossbow.w2ent`, `mq3035_red_crossbow_easy.w2ent`) | AI, DIFF | NPC levels and templates |
| Monster projectiles (`advancedProjectile.ws`, the leshen's, the toad's, the dracolizard's); 5.x's level term on projectile damage | AI | AI-18 removed the level term for every projectile |
| NPC melee and secondary weapons | AI | Only bows and crossbows are XBOW's |

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
| XBOW-05 | None to the bugs (1.32's code; both bugs **seen in 5.x in game**); `ProcessDamageAction` changed for the headshot bones |
| XBOW-06 | None (1.32's crit functions; the horse crit and the sword's crit damage on bolts seen in game) |
| XBOW-07 | Headshots detected by bone names containing `head`, `neck`, `hroll` (`pelvis` on humans); quick shots at a large monster's targeted part |
| XBOW-08 | `ProcessDamageAction` changed for the headshot bones and deflected arrows; arrows and NPC bolts deal their entity's damage (arrow 200, bolt 600), which 5.x raises by 2.5% per Geralt level at each collision (`W3AdvancedProjectile.OnProjectileCollision`; **seen in game**) |
| XBOW-09 | None |

### Classification and action

| # | Feature | Class | Action |
|---|---|---|---|
| XBOW-01 | Bolts | clean | Legacy's (PB1) |
| XBOW-02 | Crossbows | clean | Legacy's (PB2) |
| XBOW-03 | Selling bolts | clean | Legacy's tags; prices ECON's (PB3) |
| XBOW-04 | Explosive blast | clean | Legacy's, a binary edit (PB4) |
| XBOW-05 | Bolt hit fixes | clean | Legacy's, 5.x still has the bugs (PB5) |
| XBOW-06 | Crossbow crits | clean | Legacy's (PB6) |
| XBOW-07 | Headshots | overlap (5.x changed detection) | 5.x's detection (DB1 (b)), aimed shots only; the signal legacy's (PB7) |
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
| Depends on | DMG-01 to DMG-03 (armor before attack power), MUT-13 (effect chances resisted), EFX-01 (the bolts' bleeding), SKL-08 (knockdown severity), SKL-06 (Steady Shot) |
| Skill trees | n/a in the data; Steady Shot (classic `sword_s15`, new `sword_s34`), Anatomical Knowledge (`sword_s7`, `sword_s26`) and Cold Blood add to bolt hits, so the checks run in both trees |
| Port form | the fourteen bolt abilities given whole (`on_conflict="replace"`: legacy removed nodes, the 1.32 armor piercing of Bait and Tracking bolts and two `duration` nodes) in a new DLC file `items/gm_xbow.xml`, NG+ copy in `items_plus/` (vanilla's and legacy's NG+ entries equal the regular ones), written by `tools/gen_xbow.py` (`--verify`: every bolt ability as the game reads it equals legacy's) |
| Port status | **signed off** (2026-10-27); verified in both trees |
| Open checks | Aimed shots (the real key held; SKL-06's open check): every shot tested was a quick shot, so every damage read is halved by the non-aimed rule |
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

**5.x:** 1.32's values. Without the port, the bolts deal 1.32's 4–20 damage under Ghost Mode's armor-first formula, so against armor most bolts deal the 1-point minimum (plus Steady Shot's flat damage); tracking and broadhead bolts bleed on every hit.

**Decisions:** legacy's bolts (PB1, owner, 2026-10-25): the fourteen bolts whole, the Bait and Tracking bolts' 1.32 armor piercing removed, the tracking and broadhead bolts' own `duration` dropped.

**Slices:**

1. **Bolts.** Verified 2026-10-25 in both trees. Scripted read (`GMTest_xbow01`, in the regression): every bolt's damage, armor piercing, effect, chance and tooltip chance equal legacy's table. Real quick shots fired by script through the combat action (`gmtest_xbow_shot`) at a human test dummy: each bolt dealt its legacy damage × attack power ÷ 2; against 100 armor only the Target Point bolts got through; the split bolt hit three times; effect chances over 10–20 shots each fell within their spread. The bleeding of a real Tracking and Broadhead bolt (`gmtest_xbow_bleed`) lasted 16 s at 0.5% and 8 s at 1% (EFX-01's open check).

### XBOW-02 Crossbows

| | |
|---|---|
| Kind | tuning |
| Pillars | P1, P8 |
| 5.x class | clean |
| Flags | balance |
| Depends on | DMG-02 (armor piercing in the formula), ITEM-01 (crossbow level from attack power), SKL-06 (Cold Blood reads `focus_gain`) |
| Skill trees | n/a in the data; Cold Blood (classic `perk_2`, new `sword_s34`) reads the crossbow's adrenaline gain, Anatomical Knowledge adds to its crit damage: checks in both trees |
| Port form | the seventeen crossbow abilities given whole (`replace`; the weight nodes stay 5.x's, WGT, placed last) in `gm_xbow.xml` (`gen_xbow.py`), NG+ copy; the two quest crossbows' `base_abilities` in their item entries in `gm_item.xml` (an `item_layer.py` field, `BLOCKS["XBOW-02"]`, which `gen_item.py` writes with CRAFT's dismantling parts) |
| Port status | **signed off** (2026-10-27); verified in both trees |
| Open checks | Aimed shots (quick shots only, as XBOW-01); a bolt crit with a crossbow's crit damage (read from the data only); the crossbow's adrenaline per hit with Cold Blood (read from the data; SKL-06's checks of Cold Blood's gain pass in the regression) |
| Save impact | none (**confirmed**): an owned 5.x quest crossbow (Toussaint Crossbow 2's stats) takes Toussaint Crossbow 1's ability, its rolled armor piercing and level 34 when the save loads |
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

**5.x:** 1.32's values; without the port the crossbows read up to level 38 with 1.32's attack power (ITEM-01's steps were made for legacy's values: the Lynx crossbow shows 38 instead of 27).

**Decisions:** legacy's crossbows (PB2, owner, 2026-10-25), including the two Blood and Wine quest crossbows (Ravix of Fourhorn, Geralt of Rivia crossbow) dropping to Toussaint Crossbow 1's stats; every crossbow's level follows ITEM-01's formula; 5.x's weight nodes kept (WGT).

**Slices:**

1. **Crossbows.** Verified 2026-10-25 in both trees. Scripted read (`GMTest_xbow02`, in the regression): every crossbow ability equals legacy's table and keeps no other attribute (experience bonuses and crit chance gone); each crossbow's level as the game computes it matches the table. Real quick shots by script with Broadhead bolts at an armored dummy: high-level crossbows' armor piercing took the dummy's armor to 0 and their attack power multiplied the damage as expected; Crossbow 1 against 100 armor dealt 0.

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
| Port status | **signed off** (2026-10-27); verified |
| Open checks | — |
| Save impact | none (expected; tags are read from the definition, ARM-05) |
| NG+ counterpart | applied, untested |

**What it does** (changelist 671: "Bolts no longer cost a fortune, you can sell them and buy them for a reasonable price, but you can't dismantle them"): the twelve non-infinite bolts lose `mod_nosale`, so merchants buy them; the Blood and Wine quest bolt's misspelt `mod_nosalem` becomes `mod_nosale`, so it can no longer be sold. Bolts have no dismantling parts in 1.32, legacy or 5.x. Legacy's prices (Bait, Tracking and Blunt 70, Target Point and Split 100, Broadhead 120, Explosive 170; the Legendary ones 100–200; the Harpoon bolt 0) and `mod_legendary` (a price modifier) are ECON's; the weight (0.05 each) WGT's.

**5.x:** 1.32's tags and prices.

**Decisions:** PB3 (owner, 2026-10-25): legacy's tags, the prices with ECON.

**Slices:**

1. **Tags.** Verified 2026-10-25. Scripted checks (`GMTest_xbow03`, in the regression): the twelve special bolts are sellable, Bodkin, Harpoon and the quest bolt are not, no bolt has `mod_nosalem`. A real sale through a spawned weaponsmith's shop menu event (`gmtest_xbow_sell`): two bolts sold, the counts moved by one each; the shop's tooltips show legacy's damage and chances.

### XBOW-04 Explosive bolt's blast

| | |
|---|---|
| Kind | tuning |
| Pillars | P8 |
| 5.x class | clean |
| Flags | balance |
| Depends on | — |
| Skill trees | n/a |
| Port form | binary edit of `items/weapons/projectiles/witcher_bolts/explosive_bolt.w2ent` (`W3ExplosiveBolt.explosionRange` 5 → 3 in both copies of the entity, the editable object and the compiled `flatCompiledData`) with `cr2w_patch.py "W3ExplosiveBolt.explosionRange=5.0:3.0"`, shipped in the mod's bundle as LOOT's and ENCH's entity edits; `gen_xbow.py --verify` checks the file is 5.x's with exactly that edit |
| Port status | **signed off** (2026-10-27); verified in both trees |
| Open checks | — |
| Save impact | none (expected): a new bolt entity is spawned for each shot |
| NG+ counterpart | none (no NG+ entity) |

**What it does** (changelist 669): an explosive bolt's blast reaches enemies within 3 m instead of 5 m.

**5.x:** 1.32's entity (bindiff: only re-save noise against 1.32).

**Decisions:** PB4 (owner, 2026-10-25): a binary edit of the entity, as legacy.

**Slices:**

1. **Blast range.** Verified 2026-10-25 in both trees. Scripted read (`GMTest_xbow04`): a spawned explosive bolt reads `explosionRange` 3. Real quick shots by script at a dummy with three more about 2, 3 and 4 m from it: every blast hit the dummies at 2 and 3 m, never the one at 4 m (before the edit, all), also with Cat Eyes.

### XBOW-05 Bolt hit fixes

| | |
|---|---|
| Kind | fix |
| Pillars | P8 |
| 5.x class | clean (5.x's code is 1.32's; both bugs seen in 5.x in game) |
| Flags | — |
| Depends on | STAM-03 (the `ThrowProjectile` wrapper), SKL-06 (Cold Blood's adrenaline per hit) |
| Skill trees | n/a (Cold Blood's adrenaline, both trees, is counted per hit) |
| Port form | `xbow/boltHits.ws`: `@addField W3BoltProjectile.gmBoltItemName`, set by a `@wrapMethod` of `ThrowProjectile` (while the item is still in the inventory; legacy sets it in `ReleaseProjectiles2`, a timer) on every projectile of the shot; `@wrapMethod` of `ProcessDamageAction` (an early return for a victim this bolt already hit; the last bolt re-added around the hit and removed after) and of `OnProjectileInit` (`collidedEntities` cleared) |
| Port status | **signed off** (2026-10-27); verified in both trees |
| Open checks | — |
| Save impact | none (expected): the new field is not saved |
| NG+ counterpart | none |

**What it does** (bugfixes 161, 162): when Geralt shoots the last bolt of a stack, the item is gone from his inventory by the time the bolt hits, so the hit has no bolt to read: no damage types and no effect (only the bolts' 1-point minimum); legacy adds the bolt back for the hit and removes it again. A bolt hits each target once: an explosive bolt no longer damages the same enemy up to three times (and gives up to three times the adrenaline).

**5.x:** the same code as 1.32 (the bolt is removed at release, `ProcessDamageAction` applies its abilities at the hit and keeps no per-victim check; the explosion calls it for every entity in range). Both bugs **seen in game** in 5.x: the last bolt of a stack hit with no item and dealt 0; with Cat Eyes (Mutation 9) an explosive bolt pierces, flies on and explodes again on the next thing it touches, hitting dummies already hit by the same shot. Without Cat Eyes each shot exploded once; a plain bolt's own collision already skips a victim it hit, so piercing plain bolts hit once.

**Decisions:** PB5 (owner, 2026-10-25): legacy's fixes, each only after a check in game shows 5.x still has the bug. Both bugs are in 5.x, so both fixes are ported.
- **Deviation:** the last bolt's fix covers a split bolt's two extra projectiles too: the bolt's name is set on every projectile of the shot when it is thrown, where legacy set it only on the first projectile (in `ReleaseProjectiles2`, after the copies were made), so in legacy the last Split bolt's two copies still hit without damage (porter's call 2026-10-25, confirmed by the owner, 2026-10-26).

**Slices:**

1. **Last bolt, one hit per target.** Verified 2026-10-25 in both trees with real quick shots by script: the last bolt of a stack hit with its full damage and the stack emptied correctly; all three projectiles of the last Split bolt hit with damage; with Cat Eyes each dummy in a blast took one hit per shot. Regression check: `GMTest_xbow04` throws a real Split bolt entity through `ThrowProjectile` and reads the name on its three projectiles (`GMTestXbow05Throw`, `tests/gmTestsXbow.ws`; shown able to fail without the wrapper).

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
| Port status | **signed off** (2026-10-27); verified in both trees |
| Open checks | A sword hit while a crossbow is held (the crossbow is in hand only during a shot; the code is legacy's loop, which the bolt side exercises); a bolt shot from a galloping horse (aiming from horseback cannot be scripted; the crit chance the damage step asks for was read instead) |
| Save impact | none |
| NG+ counterpart | none |

**What it does:** a bolt shot from a galloping horse no longer gets 1.32's +100% crit chance (sword swings still do). A bolt's crit damage no longer includes the drawn sword's crit damage, and a sword hit's no longer includes the crossbow's (1.32 kept crit chance apart this way, not crit damage). With legacy's crossbows (XBOW-02) and swords (SWD) both carrying crit damage, this keeps each weapon's bonus with it. A drawn sword's own `attack_power` bonus still counts for bolts, in 1.32, legacy and 5.x (legacy keeps only crit chance and crit damage apart). Legacy's other changes in these functions (the oils' crit chance and damage for melee only, confusion moved to the damage manager) are ported (SKL-14, SKL-12, ALCH-14).

**5.x:** 1.32's functions, seen in game: on a galloping horse a bolt's crit chance rose by 1; with a sword drawn a bolt's crit damage included the sword's. A held sword's crit damage counts in Geralt's attributes only while it is drawn; its crit chance was already kept from bolts by 1.32's code.

**Decisions:** PB6 (owner, 2026-10-25).

**Slices:**

1. **Crit rules.** Verified 2026-10-25 in both trees. Galloping (a real gallop, key presses sent): a bolt's crit chance stayed Geralt's own while a light attack's rose by 1. Crit damage (scripted reads, `gmtest_xbow06_read()`): a bolt's excludes the drawn sword's, the sword's excludes the crossbow's. Real bolt crits by script (`criticalboy()`) dealt attack power without the drawn sword's crit damage.

### XBOW-07 Headshots

| | |
|---|---|
| Kind | fix |
| Pillars | P8, P1 |
| 5.x class | overlap (5.x changed which hits are headshots) |
| Flags | balance |
| Depends on | DMG-02, DMG-03 (headshots ignore armor and resistances, +25% attack power), SKL-06 (5.x's new-tree headshot bonuses removed; `GMIsFromAimThrow`) |
| Skill trees | n/a (5.x's Lightning Reflexes `sword_s32` headshot terms already removed by SKL-06) |
| Port form | `xbow/headshots.ws`: `@addMethod W3DamageManagerProcessor.GMSignalHeadshot` sends the event to the victim; called in the port's `ProcessAction` (`defense/processAction.ws`: Geralt's headshot dealt damage) and `GetDamageResists` (`damage/formula.ws`: the headshot's resistances read, once per damage type); 5.x's send from the crit check removed (`ProcessCriticalHitCheck`, `alchemy/bombs.ws`). Detection: 5.x's (DB1 (b)), for aimed shots only: `@replaceMethod W3BoltProjectile.ProcessDamageAction` (`xbow/headshots.ws`, 5.x's body, one line changed) checks the bone only when the bolt is not Geralt's or was shot from aiming (`GMIsFromAimThrow`, SKL-06) |
| Port status | **signed off** (2026-10-27); verified in both trees |
| Open checks | A real aimed shot's headshot (aiming needs the real key held, SKL-06's open check; tested with the aimed flag set on a scripted bolt as the aiming path sets it); an aimed Split bolt's two copies: from the code they are made before 5.x sets the aimed flag on the bolt, so they count as quick shots (no headshot, and half damage under SKL-06's rule); a behaviour tree waiting for the event (`CBTTaskKill`'s `onHeadshot`; no test NPC found that uses it); barghests and Blood and Wine's wyverns not shot (same skeletons as the wolves and the griffins' kind) |
| Save impact | none |
| NG+ counterpart | none |

**What it does:** a headshot (a bolt or arrow hitting an NPC's head, neck or `hroll` bone, or a human's pelvis) ignores the target's armor and resistances, adds 25% attack power (DMG) and 50% crit chance (1.32's). Legacy sends the "Headshot" gameplay event, which some behaviour trees wait for (`CBTTaskKill`'s `onHeadshot`), when the headshot deals damage and when its resistances are read, instead of from the crit check. Only an aimed bolt of Geralt's can be a headshot (owner, 2026-10-27): a quick shot (the button tapped, not aimed) never is, whatever bone it hits; NPCs' arrows and bolts are unchanged. An arrow or bolt marks a headshot only on an NPC victim (1.32, legacy and 5.x), so Geralt never takes one.

**5.x:** a hit counts as a headshot when the bone's name contains `head`, `neck` or `hroll` (or `pelvis`, humans), where 1.32 (and legacy) needed the exact names; bones such as a monster's neck now count (listed by rig below). Quick shots at a large monster with targetable parts fly at the targeted part, which can be its head. 5.x sends the event from the crit check (Geralt's hits only), as 1.32.

A quick shot flies at the target's targetable part if it has one (5.x), else at its `torso2` bone, else at the point Geralt looks at (`ReleaseProjectiles2`). The skeletons without `torso2` are the wolves' kind, the griffins' kind, fiends and chorts, forktails and wyverns, and nekkers; the base game's wyverns and the forktails also have a targetable `jaw`. In real fights about half the quick shots at a nekker and most at wyverns and forktails landed on a headshot bone under 5.x's rule, which is why quick shots are excluded.

**The bones 5.x's rule adds** (DB1). A bolt or arrow reports the bone of the ragdoll shape it hits (`GetRagdollBoneName`); a hit on an NPC without ragdoll shapes reports no bone and is never a headshot. Every NPC template under `characters\npc_entities\monsters\` of the base game and both expansions and six humans (a bandit, a woman, a dwarf, an elf, a child, a Wild Hunt warrior) were spawned by script and their ragdoll bones read in game (`gmtest_xbow_rig_spawn`, `gmtest_xbow_rig_read`); the shapes' size and place come from the rigs' ragdoll files (`*.w2ragdoll`). Legacy's rule (1.32's) counts the bones named exactly `head`, `neck`, `hroll`, and `pelvis` on humans (`IsHuman`: Wild Hunt warriors are not). No rig has a `hroll` bone, and no bone contains `pelvis` but `pelvis` itself, so 5.x adds only neck bones, on six rig groups:

| Rig group (who uses it) | Headshot bones, legacy | 5.x adds | What the added bones are |
|---|---|---|---|
| Wolves, wargs, white wolves, wild dogs, barghests | `head` | `neck1` | the neck, between the shoulders (`spine3`) and the head |
| Panthers | `head` | `neck1`, `neck2` | the neck, two shapes between the chest (`torso3`) and the head |
| Griffins, archgriffins, cockatrices, basilisks | none | `neck2` | the front-most shape, past `spine3`: the upper neck and the head (the rig has no head shape) |
| Wyverns, forktails | none | `neck1`, `neck2` | the long neck; `neck2`, the front-most shape, holds the head (no head shape) |
| Fiends, chorts | none | `neck1` | the front-most shape (three capsules past `spine3`): neck and head |
| Nekkers, nekker warriors | none | `k_neck_g` | a ball above the chest: the nekker's head (its rig names every bone `k_..._g`, so the exact names never match) |
| Everyone else (below) | as 5.x | none | — |

The same under both rules: humans, including Bruxa and Alp in human form and mages (`head`, `neck`, `pelvis`); Wild Hunt warriors, giants, cyclopes, Bruxa, Alp, the higher vampires' monster forms (`head`, `neck`); drowners, drowned dead, rotfiends, devourers; werewolves; leshens and Hym; gargoyles, silvans; ghouls, alghouls, Hounds of the Wild Hunt (`head`); hags and foglets, sirens, harpies, trolls, katakans, ekimmaras, garkains, fleders, Shaelmaars, the crones, wights (`neck`). No headshot bone under either rule: arachasi, endrega drones and warriors, arachnomorphs and centipedes (ragdolls without head or neck shapes); bears, golems and elementals, wraiths, nightwraiths, noonwraiths, Dettlaff's monster form, toads report no ragdoll bone while alive, and endrega workers, archespores, kikimores, boars report `Unknown` (read by script; not confirmed with a bolt).

Every bone 5.x's rule adds is a neck shape or the shape that holds the head; none is a false match (no tail, jaw or helmet bone).

**Decisions:** DB1 (b) (owner, 2026-10-26): 5.x's detection is kept. The signal: PB7 (owner, 2026-10-25).
- **Deviation:** a bolt or arrow is a headshot when the bone it hits has `head`, `neck` or `hroll` anywhere in its name (and `pelvis` on humans), 5.x's rule, where legacy (as 1.32) needed those exact names: every bone this adds is a genuine neck or head shape (the list above), and it gives headshots to griffins and their kin, wyverns and forktails, fiends and chorts, and nekkers, which legacy's names never matched; wolves and panthers gain their neck (owner, 2026-10-26).
- **Deviation:** only an aimed bolt can be a headshot: a quick (non-aimed) shot of Geralt's is never one, whatever bone it hits, where legacy (and 1.32 and 5.x) let any bolt that hit a headshot bone count; under 5.x's targeting most quick shots at wyverns, forktails and nekkers land on the neck or head and would go through all their armor (audit F1); aimed shots keep DB1's wider detection, NPCs' arrows and bolts are unchanged (owner, 2026-10-27).

**Slices:**

1. **Detection and signal.** Verified 2026-10-26 in both trees. Real quick shots by script at a human and a griffin hit the torso: no headshot, no event. Scripted shots at a named bone (`gmtest_xbow07_shoot(bone)`, the equipped bolt's own projectile fired at one bone) at a human's head and a griffin's `neck2`: headshots through all armor, the event sent once from the damage and once per damage type from the resistance read; the crit check sends none.
2. **Aimed shots only** (2026-10-27). Verified in both trees. Real quick shots in a real fight at a wyvern, a forktail and a nekker hit their neck or head bones and none was a headshot. Scripted shots at a bone, marked aimed or not with `gmtest_xbow07_aimed(on)` (sets the projectile's `isFromAimThrow` as the aimed throw does): aimed bolts were headshots with the event, the same bolts not aimed were not. Regression check `GMTest_xbow07` (`tests/gmTestsXbowHead.ws`): a bolt's projectile hits a friendly NPC through its own `ProcessDamageAction`, aimed and not, at several bones, and its headshot flag is read; shown able to fail.

### XBOW-08 NPC bows and crossbows

| | |
|---|---|
| Kind | system, tuning |
| Pillars | P5, P2 |
| 5.x class | clean |
| Flags | balance |
| Depends on | DMG-08 (weapon damage read from the held item), DMG-01 to DMG-03 (the formula), DEF-08 (arrow parry), AI-18 (5.x's level term on projectiles removed) |
| Skill trees | n/a |
| Port form | `xbow/npcBows.ws`: `@addMethod W3ArrowProjectile.GMGetHeldWeaponDamage` (legacy's `GetHeldWeaponDamage`); `@wrapMethod W3ArrowProjectile.ProcessDamageAction` sets `projDMG` and `projSilverDMG` from the archer's held bow or crossbow, then 5.x's body; the eight NPC bow abilities given whole (`replace`, 5.x's weight nodes kept) in `gm_xbow.xml` (`gen_xbow.py`), NG+ copy. Geralt's bolts, a subclass with their own `ProcessDamageAction`, never pass through the wrapper |
| Port status | **signed off** (2026-10-27); verified in both trees |
| Open checks | The long bows, the elven bow, the dwarven and Nilfgaardian crossbows in an archer's hands (read from the data only: the two archer templates tested carry `bow_01` and `crossbow_01`) |
| Save impact | none (expected): the damage is read from the held item at each hit |
| NG+ counterpart | applied (legacy's values; vanilla's NG+ bows equal its regular ones), untested |

**What it does:** an NPC's arrow or bolt deals the damage of the bow or crossbow it was shot from, instead of a fixed damage set in each projectile's entity ("damage is hardcoded in w2ent", legacy's comment), and the bows are retuned: the two plain bows 150 piercing (unchanged), long bows 200 → 180, the elven bow 250 → 200, the generic crossbow 150 → 220, the dwarven crossbow 200 → 240, the Nilfgaardian crossbow 250 → 220; silver 3 → 4 on all. The NPC's attack power and Geralt's armor then apply (DMG). A reflected arrow (Deflection, SKL-05) keeps its own damage: Geralt holds no bow.

**5.x:** an arrow deals its entity's damage: 200 for an archer's arrow (`arrow_01.w2ent`), 600 for a crossbowman's bolt (`bolt_01.w2ent`), and 5.x raises it by 2.5% per Geralt level each time the projectile collides (`W3AdvancedProjectile.OnProjectileCollision`, every advanced projectile; legacy's code has no such term). The bow abilities are 1.32's and unused for arrow damage. **Measured in game:** at Geralt level 30 an archer's arrow read 350 and a crossbowman's bolt 1,050.

**Decisions:** PB8 (owner, 2026-10-25); the boundary (DB2, owner, 2026-10-25): NPC bows are XBOW's, other NPC weapons AI's.
- 5.x's level term on projectile damage is gone from every projectile since AI-18 ([ai.md](ai.md#ai-18-special-attacks-and-monster-projectiles)): a reflected arrow deals the arrow's own 200 before SKL-05's pool.

**Slices:**

1. **NPC bow damage.** Verified 2026-10-25 in both trees with real NPC shots from archers spawned by script (`gmtest_xbow08_archer`) at an immortal Geralt: every arrow read its bow's damage (150 and 4 silver from `bow_01`, 220 and 4 from `crossbow_01`) and took far less Vitality than 5.x's; reflected arrows (Deflection, both trees) hit the archer with the arrow's own damage. Scripted read (`GMTest_xbow08`): the eight abilities equal legacy's.

### XBOW-09 NPC archers' stamina

| | |
|---|---|
| Kind | system |
| Pillars | P2 |
| 5.x class | clean |
| Flags | — |
| Depends on | STAM-08 (NPC stamina) |
| Skill trees | n/a |
| Port form | `class CBTTaskShootDef extends CBTTaskPlayAnimationEventDecoratorDef { default xmlStaminaCostName = 'light_action_stamina_cost'; default drainStaminaOnUse = true; }` (as STAM-08's attack default); `@replaceMethod CBTTaskShoot.IsAvailable` adding the decorator's own check (`super.IsAvailable()`), in `stamina/npcStamina.ws` |
| Port status | **signed off** (2026-10-27); verified in both trees |
| Open checks | — |
| Save impact | none |
| NG+ counterpart | none |

**What it does:** an NPC archer's shot costs its light-attack stamina cost and is not taken without it, like every other NPC attack (STAM-08). Not in the changelist (an omission); STAM-08's mapping missed the shot task, which is not an attack task (`CBTTaskShoot` extends the animation decorator directly).

**5.x:** 1.32's task; shooting is free (**seen in game**: the archers' stamina stayed at 100 at every shot).

**Decisions:** PB9 (owner, 2026-10-25).

**Slices:**

1. **Shot stamina.** Verified 2026-10-25 in both trees with real NPC shots: each shot cost the archer's light-attack cost (25); with its stamina at 0 and regen paused (`gmtest_xbow09_stamina`) the crossbowman took no shot until it regenerated. Regression check `GMTest_xbow09` (`tests/gmTestsXbowNpc.ws`): a new `CBTTaskShootDef` reads the light-attack cost, drained and checked; shown able to fail.

---

### Dependencies on other areas

- **Areas XBOW builds on:** DMG (the formula, headshots, the pool's underwater exception, weapon damage from the item), STAM-03 and STAM-08 (bolt and NPC stamina), SKL-06 and SKL-18 (the crossbow skills, the non-aimed rule, In Combat's Fires), MUT-11 and MUT-13 (Cat Eyes, effect chances), ITEM-01 (bolt and crossbow levels), EFX-01 and EFX-02 (bleeding values, the frozen hit), UI-01, UI-02, UI-07 (the panel and tooltip rows), CRAFT-01 and CRAFT-08 (schematics, dismantling), LOOT-05 and LOOT-09 (where bolts are found), DEF-08 and SKL-05 (arrow parry and reflection), AI-18 (projectile level term).
- **Areas that hold XBOW-adjacent changes:** ECON (bolt and crossbow prices, `mod_legendary`), WGT (weights), AI (flyers forced to land, archers' templates and levels, monster projectiles), FIX (projectile collisions), DIFF (NPC archers' levels); see [Scope](#scope).

### Save impact

None expected: bolt and crossbow abilities are read when a bolt hits, tags from the definition, the explosive bolt's entity is spawned per shot, the new field is not saved. Confirmed for XBOW-02: an owned Ravix of Fourhorn or Geralt of Rivia crossbow takes its new base ability when the save loads. Adding or removing the mod mid-playthrough is not supported ([save compatibility](../feature-mapping.md#save-compatibility)).

### Area decisions

**Decided** (owner, 2026-10-25; DB1 2026-10-26):

| # | Question | Decision |
|---|---|---|
| DB2 | The boundary | As in [Scope](#scope): NPC bows and crossbows (damage, archers' stamina) are XBOW's, other NPC weapons AI's; the flyers' forced landing AI's; prices ECON's, weights WGT's, `mod_legendary` ECON's; the projectile collision fixes FIX's; the archers' levels AI's and DIFF's |
| PB1 to PB12 | The porter's calls below | All confirmed as proposed |
| DB1 | Which hits are headshots (XBOW-07): 5.x changed it | (b), 5.x's rule (2026-10-26): any bone whose name contains head, neck or `hroll` (a human's pelvis); in the game's rigs it adds only neck or head shapes (`neck1`, `neck2`, `k_neck_g`; the [list](#xbow-07-headshots)), so griffins, wyverns, fiends and nekkers get headshots. A deviation (XBOW-07); since 2026-10-27 for aimed shots only |

**Porter's calls** (confirmed by the owner, 2026-10-25):

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
| PB9 | XBOW-09: NPC shots cost and need the light-attack stamina cost (STAM-08's rule) |
| PB10 | 5.x's own crossbow changes that legacy did not touch are kept: quick shots at a large monster's targeted part, the bolt range read from diving and slower underwater bolts, no controller vibration |
| PB11 | NG+: vanilla's and legacy's NG+ bolt, crossbow and bow entries equal their regular ones, so the NG+ copies carry legacy's values ([NG+ numbers](../feature-mapping.md#ng-numbers)) |
| PB12 | Attribution: XBOW is added to the shared units it changes (the two crit functions, `ProcessAction`, `ProcessCriticalHitCheck`, `GetDamageResists`, `ReleaseProjectiles2`, the two quest crossbows' items); no code change |

Legacy's own behaviour in play (for example the last Split bolt's copies) is on the [list to test in legacy Ghost Mode](../open-questions.md#to-test-in-legacy-ghost-mode).

**Later:** —
