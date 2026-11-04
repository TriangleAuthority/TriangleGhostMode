# FIX: legacy's bug fixes that no other area took

The vanilla bugs legacy Ghost Mode fixed that belong to no gameplay area: enemy arrows and projectiles passing through solid objects, the arrow of Yoana's armour test, quest items that stay quest items forever, checkpoints during the Bloody Baron's botchling escort, a hit cancelling a bomb throw that is not happening, travelling merchants that do not open their shop, Vitality regeneration stuck after a fistfight, and a Polish and eight Russian text corrections; plus the fixes 5.x made itself, recorded so that nothing in legacy's "Bugfixes" section is left untraced. Legacy's changelist has its own section, "Bugfixes" (lines 31–184: "Fixes by other modders included in Ghost Mode", "Irrelevant vanilla bugs", "Fixes by the mod"), and its "Known bugs" (lines 4–24).

**The player-visible texts first.** Legacy's changelist, quoted exactly, for the lines FIX takes: "Generic Merchants Fix by Wolfmark - resolves a problem with some generic merchants not showing their goods." (37); "A fix for a bug with NPC projectiles ignoring certain solid obstacles like trees (credits to Reaper)." (46); "Fixed a bug with Ciri being vulnerable during her special attack." (113); "Added missing "Meteorytowa plyta" ingredient name to Polish localization." (137); "Fixed a rare bug with HP regen being blocked by fistfight minigame and never unblocked again (at least not until another minigame). The true reason of the issue is unknown as the code appears to be correct, but saving and reloading a game should now restart HP regen properly." (139–142); "Fixed a bug with arrow not bouncing off Geralt when testing Yoana's new armor." (144); "Fixed numerous bugs with quest items being stuck in the inventory after completing corresponding quests." (150–151); "Ciri cutscene sword fix by Polakowicz - Ciri no longer has two swords in cutscenes." (36); "Fixed a bug with wearable feather from Vivienne not equipping properly." (86); "Fixed a bug with inability to finish off sirens - it was an incorrect animation name for Geralt action." (171–172). And the known bug: "Reloading from new checkpoints during lifting a curse from botchling phase of Baron's quest will cause the botchling to disappear. The bug is strictly visual and Axiing him still works (technically you Axii the baron and not him anyway). The botchling will reappear once you reach the destination." (7–10). The changelist has no line for the throw-abort fix (FIX-05) or for the Russian corrections other than Hunter Instinct's (138, which is SKL-19's): both are omissions. No menu option, tooltip or tutorial belongs to FIX; the texts it changes are FIX-08's nine strings.

**What 5.x did in this area** (from `vanilla-5.x`, unverified in game). It fixed four of these bugs itself: Ciri's invulnerability during her special attack (5.x's `ciri_combat.ws` `CompleteSpecialAttack` and `SpecialAttackCleanup` have legacy's three lines and an extra reset of the invulnerability), Ciri's cutscene sword (`CR4Player.HasRequiredLevelToEquipItem`), the siren finisher (`W3SyncAnimationManager.SetupSimpleSyncAnim`: `man_ger_crawl_finish`) and the feather's equipping (5.x's `sq701_item_wearable_feather` has `QuickSlot`). It added one collision group, `Foliage`, to the bow shot of human archers (`btTaskShoot.ws:184`) and to the arrow's stop list. Everything else FIX ports is 1.32's code in 5.x: the projectile tasks' other groups, the null victim of the sq108 arrow, the `Quest` tags (5.x even adds 9 new quest items), no checkpoint in Family Issues from script, the throw abort on every damaging hit, the merchants' tags, the fistfight's pause of Vitality regeneration, and the Polish and Russian string tables (checked by sweep B in the installed game's `content0` tables).

**How legacy Ghost Mode implements it.** Scripts: the collision groups in `CBTTaskShoot.ShootProjectile`, `CBTTaskProjectileAttack.Initialize` and `W3ArrowProjectile.OnProjectileCollision` (W3EE's fix, credited to Reaper), with the sq108 line in the last; `gm_bugfixes.ws` (`FixQuestItems`, its console command `fixquestitems`, `FamilyIssuesAutosave`; its other functions are DMG-15's, AI-06's and dead code); the calls from `CR4InventoryMenu.OnConfigUI` and `CR4ScriptedHud.OnQuestUpdate`; `W3PlayerWitcher.ReactToBeingHit` (throw abort), `W3MerchantNPC.OnSpawned` (Wolfmark's `// WMK` block), `W3PlayerWitcher.OnSpawned` (the fistfight line). Data: the `Quest` tag off two wearables and `QuestEP1` on a Hearts of Stone note (item XML, regular and NG+); one Polish and eight Russian rows in `modGhostMode`'s string tables. No binary file, no menu.

Unit lists: [attribution.csv](attribution.csv): mapped 2026-11-02 from the changelist's "Bugfixes" and "Known bugs" sections, sweep B's and sweep D's findings ([b.md](sweep/b.md), [d.md](sweep/d.md): FIX-NEW1 to FIX-NEW4, gaps G1, G2, G3, G5, G11, G13), every hand-off to FIX in the other areas' files, every changelist fix line read against the feature docs ([below](#every-bugfix-line-traced)), a script diff of every legacy function marked `W3EE`, `WMK`, `CiriCSfix` or "fix quest", and a tag comparison of the 108 quest items in master, `legacy-GM`, `vanilla-5.x` and 5.x-GM. **30 units carry a FIX feature** (31 since FIX-10, whole-port fix round, 2026-11-03): the 16 provisional FIX-NEW rows renamed, 4 MISC rows of fixes 5.x made itself moved to FIX-09, and FIX added to 10 shared rows (the 6 item entries, regular and NG+, of the feather, the monocle and the Hearts of Stone note; `ReactToBeingHit`, the two `OnSpawned` units, `OnProjectileCollision`). Unattributed units: 0 before and after. Port status: **mapped** (2026-11-02), analysed against 5.x from the code and data (unverified in game); the owner's sweep decisions (2026-11-02) already settle the main questions ([area decisions](#area-decisions)); the owner decided DK1 and DK2 as recommended and confirmed the porter's calls PK1 to PK12 (2026-11-02). **All of FIX ported** (gm/fix, 2026-11-03): slices K1 (FIX-01, FIX-02), K2 (FIX-05, FIX-07), K3 (FIX-06), K4 (FIX-03), K5 (FIX-04) verified on the area build by script, K6 (FIX-08) offline, regression +37 and +0 checks in each tree; **audited** 2026-11-03 ([FIX audit](#fix-audit-2026-11-03): 4 findings, none high; F3 fixed in K7, [close-out](#fix-audit-close-out)); **signed off** by the owner (2026-11-03).

**Size.** Small: eight short script fixes (each a few lines in a wrapper or a replaced body), a 108-item list, nine strings and a few item tags. The work is in verifying them on 5.x (journal entries, quest objective tags, generic merchants), not in the code.

## Scope

**FIX covers** the changelist's bug fixes that no gameplay area claims, the `gm_bugfixes.ws` functions no area took, and the record of the fixes 5.x made itself.

**Already ported or recorded by other areas** (nothing left for FIX): every other line of the "Bugfixes" section; the table [below](#every-bugfix-line-traced) names the feature of each. The hand-offs FIX received and passed on are under [Hand-offs received](#hand-offs-received).

**Not FIX:**

| Subject | Area | Why |
|---|---|---|
| Camerlengo's Seal (`camm_trophy`) losing `Quest` in its XML | TRPH-02 (signed off) | The trophy's rework; FIX-03's unconditional case for it is then a no-op |
| The fiend's close-range melee branch ("chorts and fiends not attacking", 77) | AI-14 (signed off) | 5.x's own behaviour tree has it |
| The Dao and golem slam radius (136) | AI-14 (owner, sweeps 2026-11-02) | Entity data, AI's |
| The sorceress hand effect (44) | AI-14 | In 5.x |
| The regen restart when an ability with a regen stat is added (115, STAM's hand-off) | FOOD-03 (signed off) | The `OnAbilityChanged` wrapper |
| Oils removed from both swords by the debug respec (`Debug_ClearCharacterDevelopment`'s "oil part: FIX") | SKL-01 (signed off) | A recorded deviation: the character reset leaves oils alone |
| The Caretaker's Shovel lifesteal, Quen after a load, Wolf liver's quick-slot hack | SWD-03, SKL-11, FOOD-04 (owner, sweeps 2026-11-02) | Gaps in those features, not standalone fixes |
| The `mh307` contract's reward name in two scenes | ECON-12 (signed off) | Money |

## Changes at a glance

### What Ghost Mode changed

| # | Feature | Vanilla 1.32 (and 5.x) | Legacy GM | Units |
|---|---|---|---|---|
| FIX-01 | Projectiles stopped by solid objects | Human archers' arrows and monster projectiles collide with ragdolls, terrain, static meshes (and water); 5.x adds foliage to bow shots | Also debris, rigid bodies, foliage, doors and fences (bow shots also destructibles and platforms); an arrow stops at all of them | 3 |
| FIX-02 | The arrow of Yoana's armour test | A collision that finds no entity is not a hit on Geralt, so the test arrow can fly through him | With Yoana's armour on, such an arrow counts as hitting Geralt (and bounces off the armour) | 1 (shared) |
| FIX-03 | Quest items released after their quest | Keys, notes, letters, masks and trophies keep `Quest` for good: they cannot be sold or dropped | 108 items lose `Quest` (95 also `NoDrop`) when the inventory opens, once their quest is done or failed (95), their map pin is cleared (6), or always (7); two wearables lose `Quest`, a Hearts of Stone note gains `QuestEP1` in the XML | 9 |
| FIX-04 | Family Issues checkpoints | No save during the botchling escort | A checkpoint save at every quest update while "Protect Baron from wraiths" (or "once more") is active | 2 |
| FIX-05 | A hit cancels a throw only during a real throw | Every damaging hit runs the throw abort, throwing or not | Only while Geralt is throwing or aiming, and only for a hit that plays a hit reaction | 1 (shared) |
| FIX-06 | Generic merchants' shop and map pin | Some travelling merchants spawn without their scene's tags: "Show me your goods" opens nothing, no map pin | The scene's required tags are put first on the merchant at spawn | 1 (shared) |
| FIX-07 | Vitality regen after a fistfight | A fistfight pauses Vitality regeneration; rarely it never resumes | Resumed at every load | 1 (shared) |
| FIX-08 | Polish and Russian text fixes | The Polish table lacks the Meteorite plate's name; eight Russian texts misstate what an item does | The name and the eight corrections | 9 |
| FIX-09 | Fixes 5.x made itself | — | Ciri invulnerable in her special attack, her cutscene sword, the siren finisher, the feather's quick slot | 6 (2 shared) |
| FIX-10 | 5.x's one-time save fixes | 5.x: three one-time fixes run at the first load of a save (`ApplyPatchFixes`) | Legacy turned them off | 1 (shared) |

### What 5.x changed

| # | 5.x change (from code and data) |
|---|---|
| FIX-01 | `Foliage` for the human archers' bow shot and in the arrow's stop list; nothing for monster projectiles |
| FIX-03 | 9 new `Quest` items (the `mq1060` quest's notes, key and potions, the `ngu_gear` letters, `Signs Enhancement`), none in legacy's list; the feather gains `QuickSlot` |
| FIX-09 | All four fixes, in 5.x's own code and data |
| FIX-10 | The three one-time fixes are 5.x's own (1.32 has them too; legacy commented them out) |
| FIX-02, FIX-04 to FIX-08 | None |

### Classification and proposed action

| # | Feature | Class | Proposed action |
|---|---|---|---|
| FIX-01 | Projectile collisions | clean | Legacy's groups (decided, sweep B Q2) |
| FIX-02 | sq108 arrow | clean | Legacy's line (PK4) |
| FIX-03 | Quest items | clean | Legacy's list and hook (decided, sweep B Q3; DK2) |
| FIX-04 | Family Issues checkpoints | clean | Legacy's, with its known bug (decided, sweep B Q4) |
| FIX-05 | Throw abort | clean | Legacy's two conditions in ENCH-16's replacement (PK7) |
| FIX-06 | Generic merchants | clean | Legacy's block in a wrapper (DK1) |
| FIX-07 | Fistfight regen | clean | Legacy's line (PK9) |
| FIX-08 | Strings | conflict (string ids) | By vanilla id and key (decided, sweep B Q5) |
| FIX-09 | Fixes in 5.x | in-5.x | Nothing to port (PK2) |
| FIX-10 | One-time save fixes | in-5.x | Keep 5.x's (deviation, porter's call) |

---

### FIX-01 Projectiles stopped by solid objects

| | |
|---|---|
| Kind | fix |
| Pillars | P5 |
| 5.x class | clean |
| Flags | — |
| Depends on | DEF-08 (its `OnProjectileCollision` replacement, `defense/arrowParry.ws`), STAM-08 (its `CBTTaskShoot.IsAvailable` replacement), XBOW-08 (NPC bows) |
| Skill trees | n/a |
| Port form | `fixes/projectiles.ws`: `@replaceMethod(CBTTaskShoot)` `ShootProjectile` (5.x's body, legacy's 7 groups added to the first list, read from an `@addMethod` helper so a test can read them) and `@replaceMethod(CBTTaskProjectileAttack)` `Initialize` (5.x's body, legacy's 5 groups in both branches); legacy's 6 extra groups in the stop branch of DEF-08's existing `OnProjectileCollision` replacement (`defense/arrowParry.ws:59`), marked FIX-01 |
| Port status | **verified on the area build** (slice K1, 2026-11-03, gm/fix): by script in both trees (`gmtest_fix01()`, in the regression), failing first on a throwaway build without the lines |
| Open checks | (by script: the shot's groups, a fresh monster task's groups in both branches, an `arrow_01` stopped by each of the nine groups and not by a ragdoll) an archer shooting at Geralt behind a fence, a door and a crate, and through bushes (a real fight); a monster projectile (a drowned dead's spit, an elemental's rock) at a crate, and through a bush (does it fly on, with an impact effect? audit F1); what each projectile class does when it hits a door or a crate (legacy changed only the arrow's stop branch) |
| Save impact | none (expected) |
| NG+ counterpart | none (scripts) |

**What it does** (changelist 46): enemy arrows and monster projectiles no longer fly through crates, barrels, loose debris, physics objects, bushes and trees, doors and fences: they hit them and stop. Example: a bandit archer behind a wooden fence in Velen; in 5.x his arrow passes through the fence and hits Geralt (a bush already stops it since 5.x), in legacy it sticks in the fence. Monster projectiles (thrown rocks, spit, magic) also report collisions with the same objects (in 5.x only with static meshes and terrain); from 5.x's projectile classes, a door or a container (a gameplay entity) then takes the hit and stops the projectile, while foliage, debris, physics objects and fences without an entity do not stop it in script: it flies on, and the boulder classes play their impact effect at the contact (`advancedProjectile.ws:245`). Legacy's code does the same (audit F1).

**Implementation (legacy):** `CBTTaskShoot.ShootProjectile` (human bows and crossbows) pushes `Debris`, `Destructible`, `RigidBody`, `Foliage`, `Door`, `Platforms`, `Fence` after 1.32's `Ragdoll`, `Terrain`, `Static`. `CBTTaskProjectileAttack.Initialize` (monster projectiles) pushes `Debris`, `RigidBody`, `Foliage`, `Door`, `Fence` after the default groups, and after `Static` when a task uses custom groups with static collision. `W3ArrowProjectile.OnProjectileCollision` stops the arrow (it sticks, plays the dirt impact, is destroyed after 5 s) on all nine groups instead of 1.32's `Terrain` and `Static`. Credited to Reaper (W3EE's "collisions fix").

**5.x:** 1.32's code, plus `Foliage` on the non-Yrden branch of `ShootProjectile` (`btTaskShoot.ws:184`) and in the arrow's stop branch (the port's `arrowParry.ws:59` keeps it). The group names exist in 5.x's scripts (`Door`, `Fence`, `Platforms` and the rest are used by other 5.x code). Subclasses of the monster task (`CBTTaskProjectileAttackWithPrepare`, `CBTTaskCaranthirMeteor`) inherit `Initialize`.

**Decisions:** legacy's groups (project owner, 2026-11-02, sweep B Q2 as recommended: "check in game that arrows still reach Geralt behind thin cover"). 5.x's own `Foliage` line stays in `ShootProjectile` (a duplicate entry with legacy's, no effect; PK3).

### FIX-02 The arrow of Yoana's armour test

| | |
|---|---|
| Kind | fix |
| Pillars | — |
| 5.x class | clean |
| Flags | — |
| Depends on | DEF-08 (`OnProjectileCollision`) |
| Skill trees | n/a |
| Port form | legacy's line after the parent call in DEF-08's `OnProjectileCollision` replacement (`defense/arrowParry.ws:44`), marked FIX-02 |
| Port status | **verified on the area build** (slice K1, 2026-11-03, gm/fix): by script in both trees (`gmtest_fix02()`, in the regression): with `sq108_heavy_armor` worn, an arrow colliding with a component of no gameplay entity (the game camera's) bounces off Geralt (re-initialised with him as caster, `sq108_arrow_deflected` set, no damage); without the armour it ignores the collision; failing first on a throwaway build |
| Open checks | the armour test of the Master Armorers quest itself (needs a save at Yoana's test) |
| Save impact | none (expected) |
| NG+ counterpart | none |

**What it does** (changelist 144): in Yoana's armour test (the Novigrad armourer's quest), the arrow shot at Geralt in her new armour bounces off him as the scene expects. In 1.32 and 5.x the collision can come without an entity, so the arrow is not counted as hitting Geralt and flies on.

**Implementation (legacy):** in `W3ArrowProjectile.OnProjectileCollision`, after the parent's call: if the collision found no victim and Geralt has `sq108_heavy_armor _Stats` (he wears the armour), the victim is Geralt. The arrow then goes through the player branch, where the test armour's (`sq108_heavy_armor`) `bounce_arrows` ability, 5.x's `BOUNCE_ARROWS_ABILITY`, bounces it every time and sets the quest's fact `sq108_arrow_deflected`. (ARM-01's `q108_bounce_arrows` chance is another armour's, `q108 Medium armor 10`.)

**5.x:** 1.32's code; the port's replacement (`arrowParry.ws`) has no such line. Whether 5.x's quest still shows the bug is unverified.

**Decisions:** legacy's line as it is (PK4). From the code it also applies outside the quest: while Geralt wears Yoana's armour, an arrow whose collision finds no entity and is not terrain or static counts as hitting him, and bounces off; legacy's behaviour, ported with it.

### FIX-03 Quest items released after their quest

| | |
|---|---|
| Kind | fix |
| Pillars | P6 |
| 5.x class | clean |
| Flags | — |
| Depends on | TRPH-02 (Camerlengo's Seal), WGT and ECON (the released items' weight and price, ported), the item layer (`tools/item_layer.py`) |
| Skill trees | n/a |
| Port form | `fixes/questItems.ws`: legacy's `FixQuestItems` as `GMFixQuestItems`, called from a wrapper of `CR4InventoryMenu.OnConfigUI` before the original body, when the menu opens on Geralt's own inventory (no shop, container or stash, read from the menu's init data as the body does); the item tags through the item layer (`"FIX-"` in `AREAS`, `TAGS["FIX-03"] = {"Quest", "QuestEP1"}`, FIX-03 in `PORTED`; FIX-09 owns no field), regular and NG+ |
| Port status | **verified on the area build** (slice K4, 2026-11-03, gm/fix): by script in both trees (`gmtest_fix03()`, in the regression): the 108 items defined in 5.x, the items without `Quest` exactly the five that never had it, the Camerlengo's Seal and the two wearables, the Hearts of Stone note with `QuestEP1`; the six map pins among 5.x's entity map pins; the release (`sq104_notes` after SQ104 Werewolf succeeded or failed: `Quest` off; while it is active: kept; the hare mask always; `lw_gr29_cage_key` once its pin is disabled, kept while enabled); 5.x's own `mq1060_right_hand_potion` keeps `Quest` after mq1060 succeeded (DK2). The hook through the real menus (`gmtest_fix03_menu_a` to `_d`, not in the regression): a shop opening released nothing, Geralt's own inventory released the note. Failing first on a throwaway build without the release and the tag changes. `mh701_usable_lure` after Contract: Tectonic Terror succeeded loses `Quest` and `NoDrop` (slice K5) |
| Open checks | the inventory on screen after a quest is finished (the item no longer marked as a quest item, sold at a merchant) |
| Save impact | none (expected): items already in a save lose the tag at the next inventory opening |
| NG+ counterpart | the tags applied (item layer); the script reads both |

**What it does** (changelist 150–151): keys, notes, letters, masks, outfits and trophies that vanilla leaves as quest items long after their quest can be dropped and sold once the quest is over. Each time Geralt opens his inventory, every item of legacy's list he carries loses its `Quest` tag (the "quest item" mark that forbids dropping and selling):

- 95 items when their journal quest is succeeded or failed (55 quests); they also lose `NoDrop`. Examples: the Beauclair casual suit and its medal after the epilogue's ceremony (`Q705 Ceremony`), the three Triss masks after "A Matter of Life and Death" (`SQ301 Triss`), the Umbra trophy after "The Warble of a Smitten Knight"'s horse quest (`mq7017_zmora_trophy`, TRPH's hand-off), the Wolf School gear journals, the forktail brain and the potion kit of "The Curse" (`Q401`, ALCH's hand-off).
- 6 when their map pin is cleared: the cage and prison keys of three Velen and Skellige events, a Toussaint key and two notes, including the Hearts of Stone note `ep1_poi_12_note_b` (CRAFT's hand-off).
- 7 always: Camerlengo's Seal, the two Toussaint vampire masks, Vivienne's feather, the hare mask, a notice and a note that no quest uses as quest items.

Two wearables also lose `Quest` in the item data (Vivienne's feather, Thaler's wearable monocle; legacy), and the Hearts of Stone note gains `QuestEP1`, the expansion's quest-item mark in the shop, loot and popup screens.

**Implementation (legacy):** `FixQuestItems` (`gm_bugfixes.ws`): for each `Quest` item in Geralt's inventory, a `switch` on its name gives a map pin (`CCommonMapManager.IsEntityMapPinDisabled`), a journal entry (`CWitcherJournalManager.GetEntryByString`, status `JS_Success` or `JS_Failed`) or an unconditional release; `RemoveItemTag('Quest')`, and `'NoDrop'` for the journal cases. Called from `CR4InventoryMenu.OnConfigUI` in the branch that opens Geralt's own inventory; also the console command `fixquestitems`. Item XML: `sq701_item_wearable_feather` and `mq0004_thalers_monocle_wearable` without `Quest`, `ep1_poi_12_note_b` with `QuestEP1` (regular and NG+).

**5.x:** every item of the list still has 1.32's tags (`Quest`; `mh701_usable_lure` also `NoDrop`), five of them (`Flowers`, `Perfume`, `mq1002_artifact_3`, the two vampire masks) have no `Quest` in 1.32, legacy or 5.x, so their cases do nothing; Camerlengo's Seal has none in the port (TRPH-02). No 5.x script removes `Quest`. The functions legacy calls exist in 5.x (`IsEntityMapPinDisabled`, `GetEntryByString`, `GetItemsByTag`, `RemoveItemTag`). The 55 journal identifiers all resolve on 5.x: each is the exact identifier of one quest in 5.x's journal files (an offline scan of the game's bundles, 2026-11-03; `Q309 Novigrad Under Control` and `ww_vermentino` also begin longer identifiers in other files, matched exactly in their own); the 6 map pins are all among 5.x's entity map pins (`GetEntityMapPins` over the 11 areas, in game). 5.x added 9 quest items legacy never knew (DK2).

**Decisions:** legacy's list and rule, after a script check of the 55 entries and 6 pins (project owner, 2026-11-02, sweep B Q3 as recommended). The hook, the tags and the console command: PK5. 5.x's 9 new quest items keep 5.x's tags (DK2 (a), project owner, 2026-11-02: kept as quest items in case there is a reason to hold onto them; not on the Later list).

### FIX-04 Family Issues checkpoints

| | |
|---|---|
| Kind | fix |
| Pillars | — |
| 5.x class | clean |
| Flags | — |
| Depends on | — |
| Skill trees | n/a |
| Port form | `fixes/familyIssues.ws`: `GMFixFamilyIssuesCheckpoint` (legacy's `FamilyIssuesAutosave`: one checkpoint per active escort objective, the rule in `GMFixFamilyIssuesCheckpointsDue`, the test seam), called from a wrapper of `CR4ScriptedHud.OnQuestUpdate` after the original body when the HUD has its journal update module (legacy's condition) |
| Port status | **verified on the area build** (slice K5, 2026-11-03, gm/fix), the rule only, by script in both trees (`gmtest_fix04()`, in the regression; no save written: a test probe turns the save into a count, and saving stays locked): 5.x's `family.journal` has legacy's quest and objective tags; with 'Protect Baron from wraiths' or '... once more' active one checkpoint is due, with both done none, for another quest none; the walk's start as a quest block makes it (Family Issues, then 'Protect Baron from wraiths', activated with on-screen info) raises 2 HUD updates that reach the checkpoint and ask 1 checkpoint, and 'wraiths' done with '... once more' started 2 and 1 (slice K7, audit F3); the HUD's `OnQuestUpdate` called directly reaches it once; journal changes without on-screen info raise no HUD update (the silent put-back: 0). Failing first on throwaway builds without the rule and the hook (K5) and without the hook (K7) |
| Open checks | a real checkpoint during the escort (needs a save in "Family Issues" at the botchling); the botchling hidden after reloading one (legacy's known bug) |
| Save impact | none (expected) |
| NG+ counterpart | none |

**What it does** (changelist, Known bugs 7–10): during the Bloody Baron's walk with the botchling to the castle ("Protect Baron from wraiths", then "… once more"), the game saves a checkpoint at each quest update, so dying to the wraiths on the way does not send the player back to before the walk. Legacy's known side effect: reloading such a checkpoint hides the botchling until the destination ("strictly visual", the changelist).

**Implementation (legacy):** `FamilyIssuesAutosave(questEntry)`: if the updated quest's script tag is `Q103 Family Issues DB024D36-4E9AE35E-FB098D89-C8E7AB0F`, it walks the quest's phases and objectives and, for an active objective tagged `Protect Baron from wraiths` or `Protect Baron from wraiths once more`, calls `theGame.SaveGame(SGT_CheckPoint, -1)`. Called from `CR4ScriptedHud.OnQuestUpdate` next to the journal update module's call.

**5.x:** 1.32's `OnQuestUpdate` (`hud.ws:1233`); `SaveGame` and `SGT_CheckPoint` unchanged. The quest's and objectives' tags are legacy's (5.x's `gameplay\journal\quests\family.journal`, read in game 2026-11-03). Whether 5.x's quest data saves checkpoints of its own there is unverified.

**Decisions:** legacy's, with its known bug, recorded as legacy's known issue and not a deviation (project owner, 2026-11-02, sweep B Q4 as recommended).

### FIX-05 A hit cancels a throw only during a real throw

| | |
|---|---|
| Kind | fix |
| Pillars | P2 |
| 5.x class | clean |
| Flags | — |
| Depends on | ENCH-16 (its `ReactToBeingHit` replacement, `enchantments/runesGlyphs.ws:39`) |
| Skill trees | n/a |
| Port form | legacy's two conditions in `GMFixHitAbortsThrow` (`fixes/throwAbort.ws`, an `@addMethod` of `W3PlayerWitcher`), which replaces the abort block's test in ENCH-16's replacement in one line marked FIX-05 |
| Port status | **verified on the area build** (slice K2, 2026-11-03, gm/fix): by script in both trees (`gmtest_fix05()`, in the regression: the test for a hit while throwing nothing, during a bomb throw, during a crossbow aim, with `EAHA_ForceNo`, damage over time); through the real `ReactToBeingHit` with test probes counting the aborts (`gmtest_fix05_hit()`, not in the regression: it plays a hit reaction): 0 throwing nothing, 0 with no hit reaction, 1 during a throw; failing first on a throwaway build with 5.x's rule |
| Open checks | a bomb throw and a crossbow aim interrupted by a real hit, and kept through a hit with no hit reaction |
| Save impact | none (expected) |
| NG+ counterpart | none |

**What it does** (code; no changelist line, an omission): a damaging hit cancels Geralt's bomb throw or crossbow aim only if he is throwing or aiming, and only if the hit plays a hit reaction. A hit that plays none (`EAHA_ForceNo`) leaves the throw going. In 1.32 and 5.x every damaging hit, other than damage over time, runs the abort, throwing or not: `ThrowingAbort` raises the `actionStop` behaviour event and resets the throw stage; with a bomb selected, `BombThrowAbort` also unblocks the bomb and crossbow actions.

**Implementation (legacy):** `W3PlayerWitcher.ReactToBeingHit`: `if(IsThrowingItem() || IsThrowingItemWithAim())` around the abort, and `GetHitAnimationPlayType() != EAHA_ForceNo` added to its test.

**5.x:** 1.32's rule (`playerWitcher.ws:8439`); ENCH-16's replacement keeps it.

**Decisions:** legacy's (PK7; sweep D G1).

### FIX-06 Generic merchants' shop and map pin

| | |
|---|---|
| Kind | fix |
| Pillars | — |
| 5.x class | clean |
| Flags | — |
| Depends on | ECON-08 and LOOT-05 (their `W3MerchantNPC.OnSpawned` wrappers); ITEM-06's call in `OnSpawned` is 5.x's own body (ITEM's merchant hook wraps `OnInteraction`, ITEM-02) |
| Skill trees | n/a |
| Port form | `fixes/merchants.ws`: `@wrapMethod(W3MerchantNPC)` `OnSpawned`, legacy's block after the original (the required tags put first, the NPC's own after them) |
| Port status | **verified on the area build** (slice K3, 2026-11-03, gm/fix): by script in both trees (`gmtest_fix06()`, in the regression): a generic merchant spawned from `shop_generic_merchant_novigrad_weapons.w2ent` carries `generic_merchant_novigrad_weapons ShopkeeperEntity` (his scene's required tag first) and `GetNPCsByTag` finds him by it; running the block again changes nothing; a merchant of another scene (the Novigrad temple alchemist, no embedded scene) keeps his tags. On the throwaway build without the call he carried `ShopkeeperEntity` only and nothing found him by the scene's tag |
| Open checks | a travelling merchant's shop ("Show me your goods") and map pin on screen; whether the world's spawners give the scene tag themselves (a merchant spawned from his entity file by script has none in 5.x, so the entity data lacks it) |
| Save impact | none (expected): the tags are set at every spawn |
| NG+ counterpart | none |

**What it does** (changelist 37, Wolfmark's "Generic Merchants Fix"): some travelling merchants on the roads spawn without the tags their dialogue scene needs. "Show me your goods" then opens nothing (the shop function does not find the merchant by tag), the scene may use the wrong model, and the merchant has no map pin. Legacy gives such a merchant his scene's required tags at spawn. Wolfmark's note: patch 1.12 claimed to fix it, and did not.

**Implementation (legacy):** `W3MerchantNPC.OnSpawned`, right after the parent's call: if the NPC's first embedded scene's path begins with `living_world\dialogue\generic_merchants\shop_generic_merchant`, its tags become the scene's `GetRequiredPositionTags()` followed by the NPC's own (`ArrayOfNamesAppendUnique`).

**5.x:** 1.32's `OnSpawned` (`merchantNPC.ws:36`) and `ShowMeGoods` (`scene_functions.ws:203`, which finds the merchant by tag within 2 m, then by tag anywhere). 5.x's entity data still lacks the tag: the Novigrad generic blacksmith spawned from his entity file carries only `ShopkeeperEntity`, not his scene's `generic_merchant_novigrad_weapons` (seen in game 2026-11-03, the K3 throwaway build); whether the world's spawners add it is unverified.

**Decisions:** the wrapper ported now, without first looking for a failing merchant (DK1 (a), project owner, 2026-11-02).

### FIX-07 Vitality regen after a fistfight

| | |
|---|---|
| Kind | fix |
| Pillars | — |
| 5.x class | clean |
| Flags | — |
| Depends on | — |
| Skill trees | n/a |
| Port form | `fixes/fistfight.ws`: `@wrapMethod(W3PlayerWitcher)` `OnSpawned`, `ResumeHPRegenEffects('FistFightMinigame')` after the original (in an `@addMethod` helper, so a test can run it) |
| Port status | **verified on the area build** (slice K2, 2026-11-03, gm/fix): by script in both trees (`gmtest_fix07()`, in the regression): Vitality regen paused with `'FistFightMinigame'` as a fistfight's start does, then `GMFixResumeFistfightRegen` (what the `OnSpawned` wrapper calls): no longer paused; failing first on a throwaway build without the line. The wrapper's call at a real load is checked by compile and code only |
| Open checks | — (the bug itself is rare and not reproducible on demand) |
| Save impact | none (expected) |
| NG+ counterpart | none |

**What it does** (changelist 139–142): a fistfight pauses Geralt's Vitality regeneration, and rarely it is never resumed. In legacy, loading a save restarts it.

**Implementation (legacy):** `W3PlayerWitcher.OnSpawned`: `ResumeHPRegenEffects('FistFightMinigame')` (with the Rend and finisher resumes STAM ported).

**5.x:** the fistfight's pause and resume are 1.32's (`actor.ws:656`, `:662`); nothing resumes it at load. Legacy's comment says the code "appears to be correct", so whether 5.x has the bug is unknown; the line is harmless where it does not.

**Decisions:** legacy's (PK9; sweep D G5).

### FIX-08 Polish and Russian text fixes

| | |
|---|---|
| Kind | ui, fix |
| Pillars | P7 |
| 5.x class | conflict (how vanilla strings are overridden) |
| Flags | — |
| Depends on | the string build (`tools/build_mod.py`, `w3strings.py`) |
| Skill trees | n/a |
| Port form | rows by vanilla id and key in a table of FIX's own, `localization/modGhostModeFixes/pl.csv` (1) and `ru.csv` (8): `modGhostMode`'s tables keep one id set in every language (SWD's string check), as `modGMTutorials` keeps its vanilla overrides apart |
| Port status | **verified on the area build** offline (slice K6, 2026-11-03, gm/fix): the built `pl.w3strings` and `ru.w3strings` decoded (`w3strings.py decode`): the nine vanilla ids (pl 1092943; ru 1048432, 1081301, 1064028, 1064017 to 1064019, 1064034, 1084281) carry legacy's texts with the keys' hashes, legacy's ids unused; the ids and keys checked against the installed game's `content0` tables (the Polish table has no 1092943; the English one names it `8dce0afd`, Meteorite plate). Not shown in game: the text language cannot be switched by script without the settings file and a restart |
| Open checks | the texts on screen with the game in Polish and in Russian |
| Save impact | none |
| NG+ counterpart | none |

**What it does** (changelist 137; the Russian rows are omissions): in Polish, the Meteorite plate crafting ingredient has a name ("Meteorytowa płyta"; 5.x's Polish table has no text for it). In Russian, eight vanilla texts say what the item actually does: the Black Blood decoctions (three tiers) injure vampires and necrophages that wound Geralt (vanilla: poison them), Superior Full Moon heals by the current Toxicity, Enhanced Grapeshot is stronger (vanilla: lasts longer), and three rewordings (Superior Maribor Forest, the secondary-weapon category, the money-bonus line).

**Implementation (legacy):** new rows in Ghost Mode's ids carrying the vanilla key's hash, the way the community encoder overrides a keyed vanilla string: pl `2110992509` (`item_name_meteorite_plate`, key hash `8dce0afd`, vanilla id 1092943); ru `2110992236` (`item_desc_grapeshot_2`, 1048432), `2110992340` (`bonus_money`, 1081301), `2110992341` (`item_desc_full_moon_3`, 1064028), `2110992468`–`2110992470` (`item_desc_black_blood_1` to `_3`, 1064017–1064019), `2110992472` (`item_desc_maribor_forest_3`, 1064034), `2110992473` (`item_category_secondary_desc`, 1084281).

**5.x:** the Polish table still lacks 1092943's text, the Russian table has the uncorrected texts (sweep B, decoded from the installed game). On 5.x a vanilla string is overridden by a row with its vanilla id and its key ([development.md](../development.md#localization), verified in pilot slice 4): the item data looks these texts up by key, and a row without the key leaves the key's lookup on the vanilla text. Legacy's form (a new id with the vanilla key's hash) is unverified on 5.x and not used.

**Decisions:** all nine, by vanilla id and key (project owner, 2026-11-02, sweep B Q5 as recommended). The same text as legacy's, so not a deviation; legacy's ids 2110992236, 2110992340, 2110992341, 2110992468–2110992470, 2110992472, 2110992473 and 2110992509 stay reserved (IDs are never reused, PK10).

### FIX-09 Fixes 5.x made itself

| | |
|---|---|
| Kind | fix |
| Pillars | — |
| 5.x class | in-5.x |
| Flags | — |
| Depends on | — |
| Skill trees | n/a |
| Port form | none |
| Port status | dropped (in 5.x) |
| Open checks | — |
| Save impact | none |
| NG+ counterpart | none |

**What it does:** four vanilla bugs legacy fixed and 5.x fixed too, recorded here so that their units and changelist lines are accounted for:

- **Ciri's special attack** (changelist 113): Ciri cannot be hit during her charged special attack, and its buff immunity is cleared afterwards. Legacy: `MakeInvulnerable(true/false)` in `W3ReplacerCiriStateCombatSword.CompleteSpecialAttack`, `RemoveBuffImmunity_AllNegative('CiriSpecial')` in `SpecialAttackCleanup`. 5.x has the same three calls (`ciri_combat.ws:1231`, `:1327`, `:1431`) and also clears the invulnerability when the attack ends early (`:892`). Nothing in 5.x-GM overrides these functions. **Settles sweep D's G13**, which called it missing (sweep B was right).
- **Ciri's cutscene sword** (changelist 36, Polakowicz): Ciri ignores the item level, so she no longer shows two swords in cutscenes. Legacy: `CR4Player.HasRequiredLevelToEquipItem` (`//CiriCSfix`); 5.x has the same check.
- **The siren finisher** (changelist 171): finishing off a crawling siren plays Geralt's `man_ger_crawl_finish`. Legacy: `W3SyncAnimationManager.SetupSimpleSyncAnim`; 5.x has the same name. AI handed it to SKL, which never listed it (sweep D).
- **Vivienne's feather** (changelist 86): the wearable feather goes into a quick slot (`QuickSlot`, which 1.32 lacks). 5.x's entry has it. Legacy's other change to it, `Quest` removed, is FIX-03's.

**Decisions:** nothing to port (PK2).

### FIX-10 5.x's one-time save fixes

| | |
|---|---|
| Kind | fix |
| Pillars | — |
| 5.x class | in-5.x |
| Flags | — |
| Depends on | SKL-01 (passive skill bonuses), SKL-16 (Acquired Tolerance, Synergy) |
| Skill trees | both: 5.x's code, unchanged, runs the same in either tree |
| Port form | none: 5.x's `W3PlayerWitcher.ApplyPatchFixes` kept as it is |
| Port status | not ported (5.x's kept); recorded in the whole-port fix round (2026-11-03, C2 audit's C2-4) |
| Open checks | — |
| Save impact | each fix runs once per save, at its first load (a fact marks it done); none in play (below) |
| NG+ counterpart | none |

**What it does:** at the first load of a save, 5.x runs one-time repairs of old saves in `ApplyPatchFixes`. Legacy commented out three of them: `ClearingPotionPassiveBonusFix` (removes the branch passive abilities `sword_adrenalinegain`, `magic_staminaregen`, `alchemy_potionduration` and `survival_vitality` beyond the points spent in each branch), `DimeritiumSynergyFix` (unequips Synergy, removes every mutagen synergy bonus ability, equips Synergy again) and `154997` (unequips and equips Acquired Tolerance again).

**Implementation (legacy):** the three blocks in `W3PlayerWitcher.ApplyPatchFixes` in comments (`//modSigns`); the unit is shared with SKL-16 and ARM-04, whose own parts are ported in those features.

**5.x:** the three blocks as 1.32 has them (`playerWitcher.ws:751-805`, `:952-961`).

**Decisions:**
- **Deviation:** 5.x's three one-time save fixes stay on, where legacy turned them off: kept for save safety, since they only repair a save's skill abilities once; no play difference is known, because Ghost Mode removes the branch passive bonuses at every load (SKL-01) and the other two only unequip and equip a skill again, which restores its bonuses (porter's call, not confirmed by the owner, 2026-11-03).

---

### Every bugfix line traced

Every line of legacy's "Bugfixes" section (changelist 35–184) and its "Known bugs", against the feature docs. "In 5.x": fixed by 5.x itself, nothing ported. Lines 50–53 ("Irrelevant vanilla bugs") change nothing.

| Line | Fix (short) | Feature |
|---|---|---|
| 4–24 | Known bugs: the botchling checkpoints; mastercrafted kits at 100%; Firestream's visual damage; B&W price modifiers; fistfight regen | FIX-04; CRAFT-10's kits; vanilla (no change); vanilla (no change); FIX-07 |
| 25–29 | Oils stuck on a blade | ALCH-16 |
| 35 | Alternate Aard's water ripples | SKL (audit F18, ported) |
| 36 | Ciri's cutscene sword | FIX-09 (in 5.x) |
| 37 | Generic merchants | FIX-06 |
| 39 | Mixed-up icons of boots, gloves and swords | ARM-01 (boots, gloves), SWD-08 (swords) |
| 41 | Extended descriptions of books, keys, quest items | UI-06, ALCH-17 (the name-key lookup) |
| 43 | KoalaNalle's entity fixes (spiders not specters) | AI-07 |
| 44 | Sorceress hand effect after combat | AI-14 (in 5.x) |
| 46 | NPC projectiles through obstacles | FIX-01 |
| 57 | Aard Sweep's penalty | SKL-08 |
| 58 | Axii Delusion and Puppet | SKL-12 |
| 59 | Quen Exploding Shield's range | SKL-11 |
| 60 | Undying | SKL-07 |
| 61–65 | Flood of Anger | SKL-07 |
| 66 | Dodge registration | DEF-01 |
| 68 | Hunter Instinct's crit damage | SKL-14 |
| 69 | Northern Wind | ALCH-14 |
| 70–71 | Oils stuck after a transfer | ALCH-16 |
| 72–73 | A sword's extra damage types not applied | DMG-08 |
| 74 | Humans with zero armour | DMG-15 |
| 75–76 | The Wild Hunt's frost slowdown | AI-15, EFX-05 |
| 77 | Chorts and fiends not attacking | AI-14 (5.x's tree) |
| 78 | Glyphs of Warding and Binding's resistance | ENCH-16 |
| 79–82 | Euphoria's triggers and double bonus | MUT-09 |
| 83–85 | Skills stuck in locked slots, wrong slot colours | SKL-01 |
| 86 | Vivienne's feather | FIX-09 (in 5.x), FIX-03 (its `Quest` tag) |
| 87–88 | Recipe tooltips in shops | UI-08 |
| 89–90 | Multiplicative Vitality regen on the panel | UI-05 |
| 91–92 | Potion and bomb tooltips | UI-06, ALCH-17 |
| 93 | Ethereals as specters | AI-07 |
| 94 | Rotation's Igni cast effect | ENCH-13 |
| 95–96 | Whirl as a light attack | DEF-07 (`IsLightAttack`: `attack_light_special`) |
| 97–100 | Succubi, dopplers, the Cave of Dreams visions (`sq209`), the Everec ghosts | AI-07 |
| 101 | The Caretaker's shovel ability | AI-19 |
| 102–103 | Blood and Wine's tourney champion and mixed-up abilities | AI-07, AI-03 |
| 104–105 | Rune and glyph bonuses in tooltips | UI-06, ENCH |
| 106 | Set bonus text for items in the stash | ARM-14 |
| 107–108 | Silver-to-steel draw animations | SWD-08 |
| 109–111 | Metabolism Boosts | SKL-18 |
| 112 | Doppler decoction's crit power | ALCH-13 |
| 113 | Ciri vulnerable in her special attack | FIX-09 (in 5.x) |
| 114 | Swallow and Tawny Owl regen | ALCH-04 |
| 115–116 | The ability manager's regen bonuses | FOOD-03 (STAM's hand-off) |
| 117 | Yrden Turret out of range | SKL-10 |
| 118–119 | White Honey's repeated charges | ALCH-04 |
| 120 | Rarity colours in the crafting menu | CRAFT-07 |
| 121–124 | Decoctions' overdose damage and look, the green border at 50% | ALCH-01 |
| 125–129 | White Raffard | ALCH-04 |
| 130–131 | Slowdown and breath texts in the alchemy menu | UI-08, ALCH-17 |
| 132–133 | Buffs on the character panel | UI (panel) |
| 134–135 | Mutation sound banks after a restart | MUT-01 |
| 136 | The Dao's slam radius | AI-14 (owner, sweeps 2026-11-02) |
| 137 | Polish Meteorite plate | FIX-08 |
| 138 | Russian Hunter Instinct description | SKL-19 (Ghost Mode's own `skill_desc_alchemy_s7`, ru 2110992492) |
| 139–142 | Fistfight regen | FIX-07 |
| 143 | Effect duration math | DMG-07 |
| 144 | Yoana's armour test arrow | FIX-02; its bounce chance ARM-01 |
| 145 | Nekker Warrior recipe in loot | LOOT-03 |
| 146–147 | Aard Shock Wave and Piercing Cold | SKL-08, MUT (Piercing Cold) |
| 148–149 | Synergy's bonus | SKL-16 |
| 150–151 | Quest items stuck | FIX-03 |
| 152–153 | The evil Keira and Geralt doppelgangers (`q104_evil_*`) on Essence, specters | AI-07 |
| 154 | NPC invulnerable after dropping a shield | AI-10 (guard down after the shield breaks) |
| 155–158 | The recently-countered flag; several counters at once | DEF-07, DEF-06 |
| 159–160 | Toxicity on Geralt's face under Quen and after fast travel | ALCH-01 (kept 5.x's rebuilt head effect; its open check) |
| 161 | The last bolt in a stack | XBOW-05 |
| 162–163 | Explosive bolts hitting three times | XBOW-05 |
| 164–165 | Blizzard's tier 3 | ALCH-07 |
| 166 | Preservation removed after cutscenes | ENCH-06 |
| 167–168 | Euphoria's effect per alternate cast | MUT-09 |
| 169–170 | Instant-kill chance on the panel | UI-02 |
| 171–172 | Sirens' finisher | FIX-09 (in 5.x) |
| 173–174 | Damage over time after an interrupted critical state | EFX-06 |
| 175–176 | Oil charges in finishers with Fixative | SKL-14 |
| 177–178 | Pheromone and Pops' Antidote sounds | ALCH-08 |
| 179–180 | Skill bonuses after a swap | SKL-01 |
| 181–182 | Signs aborted in a spider web | EFX-10 |
| 183 | B&W relic schematics in set colour | ARM-14 |
| 184 | "something else" | — |
| — | The throw abort (no line) | FIX-05 |
| — | Russian corrections other than 138 (no line) | FIX-08 |

Lines traced to an area rather than one feature (102–103, 104–105, 132–133, Piercing Cold in 146–147) are claimed by that area's doc in words; their port is that area's.

### Dependencies on other areas

- **Done areas FIX builds on:** DEF-08 (`OnProjectileCollision`), ENCH-16 (`ReactToBeingHit`), STAM-08 (`CBTTaskShoot.IsAvailable`), ECON-08 and LOOT-05 (their `W3MerchantNPC.OnSpawned` wrappers; ITEM-06's call there is 5.x's own body), ARM-01 (Yoana's armour), TRPH-02, the item layer.
- **Areas FIX waits for:** none.

### Hand-offs received

| From | Item | FIX |
|---|---|---|
| AI, XBOW, DEF (DEF-08's note) | The collision groups of `ShootProjectile`, `Initialize`, `OnProjectileCollision`; the sq108 arrow | FIX-01, FIX-02 |
| ALCH, CRAFT, TRPH, UI, WGT | `FixQuestItems` (alchemy quest items, `ep1_poi_12_note_b`'s `QuestEP1`, the Umbra trophy, the inventory hook) | FIX-03 |
| UI | `FamilyIssuesAutosave` from `OnQuestUpdate` | FIX-04 |
| ENCH | The throw-abort fix in `ReactToBeingHit` | FIX-05 |
| ITEM | Wolfmark's fix in `W3MerchantNPC.OnSpawned` | FIX-06 |
| EFX | Ciri's special attack | FIX-09 (in 5.x) |
| STAM | The regen not starting when a regen ability is added; the fiend's tree | Taken: FOOD-03; AI-14 (5.x's tree) |
| DIFF | The golems' and ice elementals' attack ranges | Taken: AI-14 (owner, sweeps 2026-11-02) |
| XP | The `mh307` reward name (ECON or FIX) | Taken: ECON-12 |
| Sweeps B and D | FIX-NEW1 to FIX-NEW4; G1, G2, G3, G5, G11, G13 | FIX-01 (FIX-NEW1, G3), FIX-02 (G3), FIX-03 (FIX-NEW2, G11), FIX-04 (FIX-NEW3, G11), FIX-05 (G1), FIX-06 (G2), FIX-07 (G5), FIX-08 (FIX-NEW4), FIX-09 (G13) |

### Hand-off to other areas

None.

### Save impact

None for the player: scripts read live; FIX-03 releases items already in a save at the next inventory opening, and its item tags apply to items when the game reads the definitions (a `Quest` tag on a carried item instance may stay until FIX-03's script removes it; checked in the slice).

### Area decisions

**Already decided** by the project owner (2026-11-02, sweeps B and D, "all as recommended"): FIX is mapped and ported as legacy, each fix checked against 5.x first (sweep D Q1 (a)); FIX-01 legacy's collision groups, checked in game against thin cover (sweep B Q2); FIX-03 legacy's list after a script check of its journal entries and map pins (Q3); FIX-04 legacy's checkpoints with their known botchling bug, recorded as legacy's known issue (Q4); FIX-08 all nine strings by vanilla id and key (Q5).

**Decided** by the project owner (2026-11-02, "take the recommendations"): DK1 (a) and DK2 (a); for DK2 the 9 new items stay as 5.x has them, with no later release. The porter's calls PK1 to PK12 are confirmed.

| # | Question | Options | Recommendation |
|---|---|---|---|
| DK1 | Wolfmark's merchant fix (FIX-06) when nobody knows whether 5.x still has the bug. Example: a travelling merchant on a Velen road whose "Show me your goods" opens no shop and who has no map pin. Legacy: the scene's tags put on the merchant at spawn. 5.x: 1.32's code; the data unverified | (a) port the wrapper now: where the tags are already right it changes nothing; (b) look for a failing merchant in 5.x first and port only if one is found | **(a)**: legacy behaviour first, the block only touches merchants of the generic shop scene, and finding the rare failing merchant in game would cost more than the port. The slice checks that a generic merchant's shop still opens with the wrapper |
| DK2 | 5.x's new quest items (FIX-03). 5.x added 9 quest items legacy never knew: the `mq1060` quest's two armour notes, key, ingredient and potion, the three `ngu_gear` letters, `Signs Enhancement`. Example: after `mq1060` is finished, Osmund's armour note stays undroppable and unsellable for good, as in 5.x | (a) legacy's 108 items only; (b) add the 9 by analogy with legacy's rule (each released when its quest is done) | **(a)**: legacy's list, and 5.x's own items keep 5.x's behaviour; (b) to Later. Not a deviation: content legacy never had, as XP's DX4 |

**Porter's calls** (each follows legacy or has no play effect; confirmed by the owner, 2026-11-02):

| # | Call |
|---|---|
| PK1 | FIX is ported as one area with one audit at the end, in the slices of the [port order](#port-order); new code in `scripts/local/gm/fixes/`, tests in `tests/gmTestsFix.ws` |
| PK2 | FIX-09: Ciri's special attack (sweep D's G13), her cutscene sword, the siren finisher and the feather's quick slot are in 5.x; nothing ported. Their four script units move from MISC to FIX-09; the feather's two entries carry FIX-09 beside CRAFT-08 and FIX-03 |
| PK3 | FIX-01: `ShootProjectile` and `Initialize` replaced with 5.x's bodies plus legacy's groups; 5.x's own `Foliage` line in `ShootProjectile` kept (a duplicate, no effect); the arrow's stop list extended in DEF-08's existing replacement rather than a second one, the lines marked FIX-01 |
| PK4 | FIX-02: legacy's line as it is, including its effect outside the quest (an arrow with no entity and not terrain or static counts as hitting Geralt while he wears Yoana's armour, and bounces off) |
| PK5 | FIX-03: legacy's list, journal entries and map pins; released when the menu opens on Geralt's own inventory (not at a shop, a container or the stash), before the grids are built, as legacy; `Quest` and, for the journal cases, `NoDrop` removed; the feather's and monocle's `Quest` and the note's `QuestEP1` through the item layer, both folders; the console command `fixquestitems` not ported (it repeats what opening the inventory does) |
| PK6 | FIX-04: legacy's rule, after 5.x's `OnQuestUpdate` body; the quest's and objectives' tags checked on 5.x by script first |
| PK7 | FIX-05: legacy's two conditions in ENCH-16's `ReactToBeingHit` replacement, marked FIX-05 |
| PK8 | FIX-06: legacy's block in a wrapper after the original `OnSpawned` (the original's `ShopkeeperEntity` tag ends up after the required tags, as legacy's order) |
| PK9 | FIX-07: the one line in a wrapper of `W3PlayerWitcher.OnSpawned` |
| PK10 | FIX-08: the nine rows by vanilla id and key in Polish and Russian (a table of FIX's own, `modGhostModeFixes`, since slice K6); legacy's ids for them are left unused |
| PK11 | Every slice is checked by script in both trees (FIX touches no skill: the second tree is a regression run only) |
| PK12 | NG+: FIX-03's tags in both folders (item layer); the scripts have no NG+ counterpart; untested |

### Port order

Each slice compiles and is verified on its own by script; the regression in both trees after each. One audit after the last (PK1). The game runs need a save backup first (the autosave rotation); FIX-04's real checkpoint writes a save.

| # | Slice | Verified by |
|---|---|---|
| K1 | FIX-01, FIX-02: `fixes/projectiles.ws`; the two lines in `defense/arrowParry.ws` | Scripted: a fresh `CBTTaskProjectileAttack` (both branches) and the shot's group helper hold legacy's groups; an arrow spawned and given `OnProjectileCollision` with `Door`, `Fence`, `RigidBody` stops (`isActive` false), with `Ragdoll` on Geralt does not; with Yoana's armour on and no colliding entity the arrow bounces (the armour's bounce), without it flies on. Real: an archer shooting at Geralt behind a fence (open check) |
| K2 | FIX-05, FIX-07: the conditions in `enchantments/runesGlyphs.ws`; `fixes/fistfight.ws` | Scripted: `ReactToBeingHit` with a damaging action while not throwing runs no abort (a test wrapper counts `ThrowingAbort`/`BombThrowAbort`), while throwing with a hit reaction aborts, with `EAHA_ForceNo` does not; Vitality regen paused with `'FistFightMinigame'`, then the wrapper's resume (an `@addMethod` helper the `OnSpawned` wrapper calls) run by script: Vitality regenerates again; a load after a real fistfight is not reproducible on demand |
| K3 | FIX-06: `fixes/merchants.ws` | Scripted: a generic merchant spawned from a `shop_generic_merchant` entity has the scene's required tags first and keeps `ShopkeeperEntity`; `theGame.GetNPCByTag` finds him by the scene's tag; an ordinary merchant's tags unchanged. On screen: his shop opens and a map pin shows (open check, DK1) |
| K4 | FIX-03: `fixes/questItems.ws`; `item_layer.py` with FIX-03's tags; `gen_item.py` | Data test: the 55 journal entries resolve (`GetEntryByString`), the 108 items exist with the tags the map lists, the feather and monocle without `Quest`, the note with `QuestEP1`, both folders. Scripted: items added, a quest's status set to success, the inventory menu opened (its own `OnConfigUI`): the item loses `Quest` and `NoDrop`; a pending quest's item keeps them; a shop opening releases nothing |
| K5 | FIX-04: `fixes/familyIssues.ws` | Data test: `Q103 Family Issues`' tag and its two objective tags read on 5.x. Scripted: the rule's decision on the quest's own entry with the objective active and inactive (through a test seam; no save written by the scripted check); one real checkpoint from a save in the escort (open check) |
| K6 | FIX-08: the nine rows | The built `pl.w3strings` and `ru.w3strings` decoded (`w3strings.py decode`): the vanilla ids carry legacy's texts and the keys; in game, a lookup by key and by id returns them with the text language set to Polish and Russian (open check if the language cannot be switched by script) |

**Generator work:** `tools/item_layer.py`: `"FIX-"` in `AREAS`, FIX-03 in `TAGS` (`Quest`, `QuestEP1`) and `PORTED`, each on FIX's own line (K4); `gen_item.py` then writes the three items' entries (5.x's with the tag changes; `--verify`). No new generator.

**Later:** releasing quest items also when a shop opens.

### FIX audit (2026-11-03)

Done by a fresh session ([audit](../feature-mapping.md#audit-signing-a-feature-off)) on 5.x-GM `cba6ea5c` and master `d283cffe`, reading code and data, with game runs on 2026-11-03 (scripted only; no save written, saving locked). Every port file (`fixes/*.ws`, the FIX lines in `defense/arrowParry.ws` and `enchantments/runesGlyphs.ws`, `localization/modGhostModeFixes/`, the item layer's FIX-03 entries in `gm_item.xml`, `tests/gmTestsFix.ws`) was read against legacy (`legacy-GM`), 1.32 (legacy's base commit) and 5.x (`vanilla-5.x`). Throwaway probes on `gm/fix-audit` (`tests/gmTestsFixAudit.ws`, not for integration).

**Checked and holding:**

- **Both skill trees:** FIX touches no skill; the regression ran in both.
- **Completeness:** the 30 FIX units in `attribution.csv` are each ported, dropped (FIX-09, `fixquestitems`) or shared with a reason. `unit_sweep.py --unattributed` with collision groups, `W3EE`, `WMK`/`GetRequiredPositionTags`, the quest tags, `SaveGame`/`SGT_CheckPoint`, the fistfight regen, the throw abort and `fix`: 0 units each. Legacy's string tables: the only rows in one language and not in English are FIX-08's nine, SKL-19's two Russian skill texts and MISC's orphan Spanish row.
- **FIX-01:** `ShootProjectile` and `Initialize` equal 5.x's bodies plus one marked call each (a normalised diff), the helpers hold legacy's groups in legacy's places (`Initialize`: after `Water` in the default branch, after `Static` in the custom one); the arrow's stop list is legacy's nine groups. The subclasses (`CBTTaskProjectileAttackWithPrepare`, the toad's, Caranthir's meteor) inherit `Initialize`; the other 5.x shooting tasks legacy never changed are untouched, as in legacy.
- **FIX-02:** the line and its place (after the parent call, before the victim branch) are legacy's; Geralt's own bolts (`W3BoltProjectile`) reach it only after their own victim test, and a NULL victim there becomes Geralt = the caster, which returns: no effect on his shots.
- **FIX-03:** legacy's whole `switch` against the port's, parsed by script: the same 108 names, each with the same condition (95 journal entries over 55 identifiers, 6 map pins, 7 unconditional), byte-equal identifiers and pin names, `NoDrop` removed only in the journal cases; the only line dropped is legacy's debug `LogChannel`. 5.x's 9 new quest items fall to `default` and are never touched (DK2). `GMFixIsOwnInventory` mirrors 5.x's `OnConfigUI` reading of the init data line for line; probed in game (`gmfa03_own`): own inventory with no init data and with init data naming nothing, not with a container or an NPC (directly or in `W3InventoryInitData`), not in stash mode. The item data in both folders' `gm_item.xml` (`on_conflict="replace"`) has legacy's tags (feather and monocle `QuickSlot`, the note `Quest, ReadableItem, QuestEP1`).
- **FIX-04:** the rule is legacy's (the same tags, one save per active escort objective), called in legacy's place (only with the journal update module). Loading the test save called the HUD's `OnQuestUpdate` 0 times (probe wrapper logging every call), so a load replays no quest update; a save inside the escort would confirm it for Family Issues. The test probe's wrapper, when off, only calls the original; it is in `tests/` (left out of `--release`), and its flag is an unsaved field off at every load.
- **FIX-05, FIX-07:** legacy's conditions and line; FIX-07 resumes at every spawn, as legacy's unconditional line.
- **FIX-06:** legacy's block; with ECON's and LOOT's wrappers of `OnSpawned` (ITEM-06's call there is 5.x's own body; corrected in the whole-port fix round, 2026-11-03, A8-3) it stacks safely in any order: FIX's touches only tags, theirs only the inventory and funds (`SetupFunds` reads the inventory component's type and region, not tags), and the original's `ShopkeeperEntity` tag is kept.
- **FIX-08:** the built `pl.w3strings` and `ru.w3strings` of the integrated build (`build/integ-cba6ea5c`) decoded: the nine vanilla ids carry legacy's texts byte for byte with legacy's key hashes; the English and German files carry none of them. The build merges `modGhostModeFixes` into the same per-language file as `modGhostMode`'s rows, so the game reads them in one table; on screen in Polish and Russian stays an open check.
- **The verification:** each slice's checks say scripted; the open checks are listed per feature. The regression on the integrated build passed: 1,581 + 166 in each tree, 0 failed.

**Findings:**

| # | Finding | Evidence | Severity | Kind |
|---|---|---|---|---|
| F1 | FIX-01's "What it does" said monster projectiles stop at the new obstacles. From 5.x's projectile classes, only a door or a container (a gameplay entity) stops one; foliage, debris, physics objects and fences without an entity do not stop it in script, and a boulder plays its impact effect at the contact and flies on. Nothing that should pass is stopped by script (the engine's own reaction to the extra groups is unverified); legacy's code is the same | `advancedProjectile.ws:229-260` (`W3BoulderProjectile`), `:910` (`W3StoneProjectile`), `:1604` (`DebuffProjectile`): stops on `Terrain`, `Static`, `Water` or an entity victim | low | doc correction (made: FIX-01's text); the open check "a monster projectile at a crate" gains "and through a bush: does it fly on, with an impact effect?" |
| F2 | The status page's FIX row still says "porting" | `features/README.md:215` | low | doc correction (status page: "ported 2026-11-03, audited 2026-11-03") |
| F3 | FIX-04's regression check activates the journal entries with `showInfoOnScreen` false, which raises no HUD event, so the check reads "calls from the journal activations alone: 0" and FIX-04's entry said activations do not call it. A quest block's activation does: probed (`gmfa04_a/b`, probe on, no save): activating Family Issues and "Protect Baron from wraiths" with `true` called `OnQuestUpdate` twice in the same call (1 checkpoint asked: the walk's start itself saves); "wraiths" done and "… once more" active, twice again (1 asked); restoring with `false`, 0 calls | the probe's log (`fix-audit-20261103-033510-scriptslog.txt`); `tests/gmTestsFix.ws:997-999` | low | clear fix (test: activate with `true` under the probe and expect 2 calls, 1 save) and doc correction (made: FIX-04's port status) |
| F4 | FIX-08's legacy ids were written as `340`, `468`–`470` for 2110992340 and so on | FIX-08's Implementation and Decisions | low | doc correction (made) |

F3 fixed (slice K7, 2026-11-03, gm/fix-k7): `gmtest_fix04()` activates the escort with on-screen info under the save probe (probe on throughout, no save written) and expects what the audit measured; failing first on a throwaway without the hook; regression 1,584 + 166 in each tree. No owner decision. Open checks unchanged, plus F1's addition: those of FIX-01 to FIX-03, FIX-06 and FIX-08 need a real fight, a quest save or a language switch; FIX-04's needs a save at the botchling escort (how many checkpoints the walk makes; a reload there).

#### FIX audit close-out

**FIX signed off by the owner (2026-11-03).** Every finding is fixed or corrected: F1, F2 and F4 doc corrections (made), F3 fixed in K7 (scripted, in the regression). No owner decision was needed. The open checks per feature (archers through cover, the Family Issues checkpoint in a real escort, the generic merchants' shop and pin, the Polish and Russian texts on screen) wait for the owner's playthrough.

**Regression** on the integrated build (5.x-GM `deee175c`, `regress.py --trees both`): `gmtest_regress()` 1,584 passed and `gmtest_panel()` 166 passed, 0 failed, in each tree; saves clean.

### For the shared docs

- (development.md, Testing in game) **A projectile's collision with no entity** (FIX slice K1): pass a component of an entity that is not a gameplay entity, the game camera's (`theGame.GetGameCamera().GetComponentByClassName('CComponent')`; `CCustomCamera` extends `CEntity`, and `GetComponentByClassName` matches subclasses); the projectile's `(CGameplayEntity)collidingComponent.GetEntity()` is then NULL. A NULL component with a group list (`'Door'`, `'Fence'`, ...) tests the stop branches.
- (development.md, Testing in game) **A projectile re-initialised by its own code reads inactive:** `Init(caster)` raises `OnProjectileInit`, which sets `isActive` false, so an arrow that bounced (`BounceOff`, then `Init(thePlayer)`) reads `isActive` false although it flies on; test a bounce by its caster (and the effects of the branch), not by `isActive`.
- (development.md, Annotations) **A behaviour-tree task created by script can run code that calls nothing native:** `new CBTTaskProjectileAttack in theGame` and its `Initialize` (through a test `@addMethod` that sets the task's private fields first) ran safely (FIX slice K1); only native calls such as `GetActor()` crash (AI slice B3).
- (development.md, Testing in game) **A scripted hit for `ReactToBeingHit`:** `W3DamageAction.DealsAnyDamage()` reads the processed damage (`processedDmg.vitalityDamage` or `essenceDamage` above 0), not the damage added with `AddDamage`; a hit built by script and passed straight to `ReactToBeingHit` sets `action.processedDmg.vitalityDamage` itself (FIX slice K2).
- (development.md, Testing in game) **Map pins and quest items in tests** (FIX slice K4): `GetCommonMapManager().GetAreaMapPins()` lists the areas (11) and `GetEntityMapPins(area.worldPath)` each one's entity pins by `entityName`, the name `IsEntityMapPinDisabled` and `SetEntityMapPinDisabled` take, so a test can check that a pin exists and set it disabled and back. A quest's status set from its journal file (`LoadResource(...).GetEntry()`, `ActivateEntry`) is what `GetEntryByString` and `GetEntryStatus` read in the same call. The inventory menu opened by script runs `OnConfigUI` before the next exec call; with a `W3InventoryInitData` naming a merchant it is his shop.
- (development.md, Localization) **Vanilla text overrides for some languages only go in a table of their own** (FIX slice K6): `gen_swd_items.py --verify` requires `modGhostMode`'s nine tables to hold one id set, so rows by vanilla id in Polish and Russian only (FIX-08) live in `localization/modGhostModeFixes/`, as `modGMTutorials` holds its own; a table may cover only some languages, and the build merges every table per language.
