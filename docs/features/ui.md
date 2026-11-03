# UI: character panel, tooltips, recipe texts, bestiary, HUD and menus

What the player reads: the character stats panel (the popup opened from the character menu and the inventory, and the summary lines beside the paperdoll), item tooltips, the recipe and schematic texts, the bestiary, the enemy level on the HUD, loading screen tips and tutorials, and the few menus legacy changed. Ghost Mode reworked the panel so its numbers follow Ghost Mode's own formula ("Character stats menu was altered to show detailed sign infos ... Sword stats now show average damage per hit and not theoretical damage per second. Attack power and critical hit power stats were added to sword damage sections. Adrenaline gain stat was added ... More stats were added for Toxicity section", changelist 1154–1170), fixed tooltips that hid or garbled information (bugfixes 87–92, 104, 132, 169), added a kill count to the bestiary and restructured the recipe and schematic texts. Sources: the changelist's UI section (1154–1174), the bugfix list (lines 39–42, 87–92, 104–106, 120, 122, 130–132, 169–170), the Other items section (shaving, 866), and the code, which has more than the changelist (the oil tooltip, the enemy level display, the alchemy menu's ingredient buying, the debug labels).

UI shows the numbers other areas ported; it changes no rule. Most entries are therefore displays of features that are already ported and signed off (SKL, MUT, ARM, ENCH, SWD, ITEM, ALCH, DMG, STAM), and they end the temporary deviations those areas recorded "until UI".

**What 5.x did in this area** (from `vanilla-5.x`, unverified in game). 5.x added a new character menu (`characterMenuDupe.ws`) for its new skill tree; the port draws both trees in it (SKL-02), and it opens the same stats popup as the classic menu and the inventory (`CharacterStatsPopupData` → `GetPlayerStatsGFxData`). The popup itself is 1.32's except the sign lines (`AddCharacterStatSigns`: 5.x's new-tree Shock Wave, Conjunction `perk_37`, Melt Armor's burn chance, a logarithmic burn chance). `GetOffenseStatsList` is 1.32's damage-per-second model with 5.x's new-tree perk terms (`perk_23`, `perk_25`, `perk_27`) and Heightened Tolerance's crit damage; 5.x's allied-NPC damage block reads it (switched off in the port by DMG-12). Tooltips: 5.x rewrote `GetBaseItemData` (5.x's unique sword descriptions) and kept 1.32's recipe tooltip typo (`'alchemy_recipies'`, so recipe items show no crafted item) and the "random attributes" lines on crafting texts. The alchemy menu buys missing ingredients from the NPC who opened it (5.x adopted the community code legacy used). Bestiary, tips, enemy level (still `???` for deadly enemies) and the recipe book are 1.32's.

**How legacy Ghost Mode implements it.** Scripts only, fed into the vanilla Flash panels: `CharacterStatsPopup.ws` (the popup), `W3PlayerWitcher.GetOffenseStatsList` and `SPlayerOffenseStats` (the numbers), `guiTooltipComponent.ws` (item tooltips), `guiBaseInventoryComponent.ws` (recipe and schematic texts), `alchemyMenu.ws`, `glossaryBestiaryMenu.ws`, `npc.ws` (enemy level); data: rows of `tooltip_settings.csv`, about 90 strings in 9 languages (panel labels, attribute names, kill count, loading screen tips), 16 tutorial texts in 6 languages (`modGMTutorials`), 8 bestiary journals (binary), and `content/texture.cache` (one skill icon). **No Flash (SWF/redswf) file was shipped**: every legacy UI change is a script or data change, so nothing binary in the UI layer has to be carried apart from the icon (UI-14) and the journals (UI-11).

Unit lists: [attribution.csv](attribution.csv): mapped 2026-10-20 from the changelist, the hand-offs of DMG, DEF, STAM, SKL, MUT, ARM, ENCH, SWD, ITEM and ALCH, and sweeps (`unit_sweep.py` for flash, `GetLocString`, tooltip, panel, hud, popup, notification and description; every unattributed unit under `scripts/game/gui/`; every unattributed string row): 900 units carry a UI feature at mapping (59 script units, the razor's item and its NG+ copy, 5 tooltip rows, 8 binary journals, 1 texture cache, 825 string rows: 729 in the nine `modGhostMode` tables and 96 tutorial rows); 18 of the script units are shared with features already ported (UI adds its lines). The sweep also attributed 405 string rows already ported by other features (options to OPT-01; effect and stamina cost names to STAM-01, STAM-02, STAM-03, STAM-09; Undying and Melt Armor to SKL-07, SKL-09; a crafting title to ARM-14). Port status: **signed off** by the project owner (2026-10-21, UI-01 to UI-17); **mapped** (2026-10-20), analysed against 5.x from the code; the [area decisions](#area-decisions) made by the owner (2026-10-20); **ported** (2026-10-21, all ten slices verified in both trees: UI-01 to UI-13, UI-15 and UI-09's Yolar pin ported, UI-09's buying kept as 5.x's, UI-14, UI-16 and UI-17 not ported as decided); 901 units with the audit's F1; **audited** 2026-10-21 ([UI audit](#ui-audit-2026-10-21)): every finding fixed, recorded or decided, the audit closed ([close-out](#audit-close-out), 2026-10-21).

## Scope

**UI covers** the character stats popup and the summary lines of both character menus and the inventory, the numbers behind them (`GetOffenseStatsList`), item tooltips (display, descriptions, rows, attribute names), recipe and schematic texts, the alchemy menu's ingredient buying, the bestiary (kill count, weaknesses), the enemy level on the HUD, loading screen tips and tutorials, the skill icon in legacy's texture cache, shaving from the inventory, legacy's debug labels and the unused leftovers.

**Not UI:**

| Subject | Area | Why |
|---|---|---|
| Ghost Mode's options menu (`modGhostMode.xml`, `CR4IngameMenu`'s Ghost Mode units: `OnPresetApplied`, `OnOptionValueChanged`, `gmUserSettings`, `SaveChangedSettings`, the Ghost Mode members), the option strings | OPT | OPT owns the options framework ([opt.md](opt.md)) |
| The menu units of Community Patch – Base (`ingameMenu.ws`, `igmOptions.ws`, `igmStructureCreator.ws`, `mainCreditsMenu.ws`, `menuBase.ws`, `popupBase.ws`, `r4guimanager.ws`, `commonMainMenuBase.ws`, `CR4ScriptedHud.OnConfigUI`, `hudModuleTimeLapse.ws`) | DEP | Dependency changes ([what counts](../feature-mapping.md#what-counts-as-ghost-mode)) |
| HUD buff counters (decoction stacks, Lynx, Iris, Invigoration, Prolongation, mutations), the toxicity look of the wolf head | done with MUT-14, ARM-06, SWD-06, ENCH-05, ENCH-09, ALCH-10, ALCH-01 | Ported with their features |
| Skill, perk, mutation, set, runeword, potion, decoction, bomb and oil descriptions, and the item tooltip fixes those areas made | done with SKL-19, MUT-14, ARM-14, ENCH-17, SWD-05, SWD-06, SWD-09, ITEM-12, ALCH-17 | Ported with their features |
| Dismantling from the inventory (`PlayerDismantleItem`, the dismantle inputs) | CRAFT | Already handed over by ALCH |
| `FixQuestItems` (inventory menu), `FamilyIssuesAutosave` (`CR4ScriptedHud.OnQuestUpdate`) | FIX | Bug fixes run from a menu |
| The monster-hunt reward negotiation (`OpenMonsterHuntNegotiationPopup`) | ECON | Money |

## Changes at a glance

### What Ghost Mode changed

| # | Feature | Vanilla 1.32 | Legacy GM | Units (main) |
|---|---|---|---|---|
| UI-01 | The damage numbers behind the panel | Damage per second, vanilla formula, sword bonuses only from the drawn sword | Expected damage per hit with Ghost Mode's terms (attack power and crit power per attack type, skills, sets, runewords, mutations, potions, oils, NG+ bonuses), sheathed swords' bonuses included; crossbow redone (attack power, crit damage, elemental bolt damage) | `GetOffenseStatsList`, `SPlayerOffenseStats` |
| UI-02 | Panel: sword and crossbow sections, summary lines | "Silver/steel damage per second", fast and strong DPS, crit chance and crit damage | "Damage per hit"; per attack type attack power, damage, crit chance, crit power, crit damage; crossbow attack power, crit chance, crit damage, adrenaline gain, bolt damage by type; instant kill as the larger sword chance | `GetPlayerStatsGFxData`, `AddCharacterStatU`, `AddCharacterStatU2`, `GetEquippedCrossbowDamage`, `UpdatePlayerStatisticsData` |
| UI-03 | Panel: signs | One section: knockdown, Aard damage, Igni damage and burn, Quen absorption, Yrden slowdown, damage, duration, Axii duration | Two sections; per sign its intensity and every value with all modifiers (heavy knockdown, Firestream, Quen duration, discharge, active shield, Yrden traps, range, turret, Axii control, confusion and instant kill) | `AddCharacterStatSigns`, `gm_sign_stats_*` |
| UI-04 | Panel: toxicity | Locked toxicity, current toxicity | Locked toxicity, available toxicity, decay rate, overdose threshold, overdose Vitality drain | `AddCharacterStatToxicity` |
| UI-05 | Panel: vitality, armor and other lines | Vitality regen without its multiplicative part; sign power as an average; XP bonus lines | Regen with the multiplicative part (bugfix 89); raw sign power; money bonus; adrenaline gain (general, fast, strong, crossbow); the armor regen modifier under Armor; XP lines removed | `AddCharacterStat`, `AddCharacterStatF`, `AddCharacterHeader` |
| UI-06 | Item tooltips: descriptions and stat display | No description on armor and weapons; "+" on negative values; negative modifiers compared backwards; potion toxicity "/max"; oil line with its first bonus | Armor and weapon descriptions (class texts with their stamina rule); Gwent cards without description; trophies' stats like gear; negative values and comparisons fixed; toxicity after Expert Brewer and Adaptation; the oil tooltip lists every bonus (with Wolven), the sword's oil line name and charges | `GetBaseItemData`, `AddItemStats`, `CalculateStatsComparance`, `AddOilStats`, `AddOilInfo` |
| UI-07 | Tooltip rows and attribute names | Rows missing for Ghost Mode's attributes | Five rows (armor regen modifier, frost resistance, bolt knockdown, combat Vitality regen, Yoana's arrow bounce) and nine attribute names | `tooltip_settings.csv`, strings |
| UI-08 | Recipe and schematic texts | Recipe items in shops show nothing (typo); extended texts unordered, with weight and random-attribute lines | Typo fixed (bugfix 87); have/need ingredient counts in red or green on schematic, recipe and enchantment tooltips; extended texts restructured (changelist 1170); random-attribute and weight lines removed | `GetRecipeDataFromXML`, `addComponentsInfo`, `GetAlchemyBookText`, `GetSchematicBookText`, `GetCraftedItemInfo` |
| UI-09 | Alchemy menu: buying ingredients | — | Missing ingredients bought from a herbalist or alchemist in the alchemy menu (modFriendlyHUD code); Yolar's map pin as a herbalist | `CR4AlchemyMenu` (9 units), `GetMapPinType` |
| UI-10 | Bestiary kill count | — | A "Kill count" entry: totals (humanoids, animals, monsters, unique creatures) and kills by type, from a saved counter | `UpdateKillCountEntry`, `IncKills`, `GetKills`, `GetEnemyTypeByAbility`, `GetLocStringByEnemyType` |
| UI-11 | Bestiary weaknesses | Dimeritium bomb against leshens and spriggans | Silver Dust instead (leshens, spriggans, two hunts); Dimeritium against a hunt and succubi; Axii and Yrden against the djinn | 8 `.journal` files |
| UI-12 | Enemy level on the HUD | `???` for enemies far above Geralt | The level in red | `GetExperienceDifferenceLevelName` |
| UI-13 | Loading screen tips and tutorials | Vanilla texts | Nine tips and sixteen tutorials rewritten for Ghost Mode's rules | strings, `modGMTutorials` |
| UI-14 | Skill icon | Deflection's arrow icon | A replacement icon for `sword_s10` | `content/texture.cache` |
| UI-15 | Shaving from the inventory | The razor is junk | Using the razor shaves Geralt | `inventoryContext.ws`, `UpdateFace`, item `Razor` |
| UI-16 | Debug labels | — | `toggledebuglabels`: tags in the quest journal, map pins, bestiary and item tooltips | `toggledebuglabels`, map, journal, bestiary hunks |
| UI-17 | Unused leftovers | — | Stash-mode code and strings never called; two commented-out panel lines' strings | `TransferStashItemsTo/From`, strings |

### What 5.x changed

| # | Feature | 5.x change (from code and data) |
|---|---|---|
| UI-01 | Offense list | New-tree perk terms (`perk_23`, `perk_25`, `perk_27`), Heightened Tolerance's crit damage; read by 5.x's allied-NPC damage (off in the port) |
| UI-02 | Sword and crossbow sections | none; the new character menu repeats the summary lines (`characterMenuDupe.ws`) |
| UI-03 | Signs | New-tree terms in `AddCharacterStatSigns` (Shock Wave `magic_s33`, Conjunction `perk_37`, `magic_s08` burn chance, a logarithmic burn chance) |
| UI-04 | Toxicity | none |
| UI-05 | Other lines | none |
| UI-06 | Tooltips | `GetBaseItemData` rewritten (5.x's sword descriptions); oil charges and the HUD read only the classic Fixative `alchemy_s6` |
| UI-07 | Rows | none |
| UI-08 | Recipe texts | none (typo kept) |
| UI-09 | Alchemy menu | Buying from the NPC who opened the menu, no herbalist gate; Yolar unchanged |
| UI-10 to UI-17 | | none |

### Classification and proposed action

| # | Feature | Class | Proposed action |
|---|---|---|---|
| UI-01 | Offense list | overlap | Legacy's list with each skill's new-tree counterpart; 5.x's terms for slots the port gave legacy's skills removed (DU1) |
| UI-02 | Sword and crossbow sections | clean (popup), conflict (new menu) | Port; the new menu's summary too |
| UI-03 | Signs | conflict | Port on 5.x's function, both trees |
| UI-04 | Toxicity | clean | Port |
| UI-05 | Other lines | clean | Port (DU3) |
| UI-06 | Tooltips | conflict | Port as wrappers next to ALCH-17's |
| UI-07 | Rows | clean | Rows in the `tooltip_settings.csv` override |
| UI-08 | Recipe texts | clean | Port |
| UI-09 | Alchemy menu | in-5.x | Keep 5.x's buying; Yolar's pin (Q2) |
| UI-10 | Kill count | clean | Port (DU6) |
| UI-11 | Bestiary weaknesses | conflict (5.x re-saved the files) | Legacy's lists, applied in script by the creature's tag (DU7; the journals stay 5.x's) |
| UI-12 | Enemy level | clean | Port (DU8) |
| UI-13 | Tips and tutorials | clean | Port legacy's texts (DU9) |
| UI-14 | Skill icon | conflict (cache format) | Owner's question (Q1) |
| UI-15 | Shaving | clean | Port (DU10) |
| UI-16 | Debug labels | clean | Drop (DU11) |
| UI-17 | Leftovers | obsolete | Drop (DU12) |

---

### UI-01 The damage numbers behind the panel

| | |
|---|---|
| Kind | ui |
| Pillars | P7, P1 |
| 5.x class | overlap |
| Flags | — |
| Depends on | DMG-01 to DMG-05 (the formula), SKL-03, SKL-04, SKL-06 (skills of both trees), ARM-06, ARM-08 (Feline, Bear), ENCH-05, ENCH-10 (Invigoration, Heft), MUT-09, MUT-11 (Euphoria, Cat Eyes), SWD-07 (`sword_dmg_bonus`), ALCH-03, ALCH-10, ALCH-16 (Thunderbolt, decoctions, oils), XBOW (bolt values) |
| Skill trees | both: classic Muscle Memory `sword_s21`, Strength Training `sword_s4`, Precise Blows `sword_s17`, Crushing Blows `sword_s8`, Steady Shot `sword_s15`, Anatomical Knowledge `sword_s7`; new `sword_s22`, `sword_s23`, `sword_s24`, `sword_s25`, Cold Blood `sword_s34` (with Steady Shot's damage), `sword_s26` |
| Port form | `ui/offenseStats.ws`: Ghost Mode's struct `SGMOffenseStats` with legacy's fields (`SPlayerOffenseStats` is a struct: annotations cannot extend it) filled by `@addMethod GMGetOffenseStats` (per sword `GMOffenseSwordStats`, per attack type `GMOffenseAttackPower`), `@replaceMethod` of `GetOffenseStatsList` filling 5.x's fields from it; Life Leech's `GMMutation11GetBaseStrength` reads it; DMG's `CalculateDamage` no longer reads the list on every hit (its readers are off, DMG-12) |
| Port status | **signed off** (2026-10-21); **ported** (slice 3, 5.x-GM `f768e9b1`), verified in both trees |
| Open checks | a real fight's hits against the panel (scripted hits only); the crossbow line against a real bolt hit (read by script); the new tree's Strength Training with more than one stack (scripted hits in one frame count as one swing). The crit chance lines equal the hit's `GetCriticalHitChance` in both trees (`GMTest_ui01_crit`, below); a sword with crit chance of its own sheathed (the test's swords have none) |
| Save impact | none (expected) |
| NG+ counterpart | none (scripts) |

**What it does** (changelist 1161–1162, 1171–1174): the numbers the panel, the inventory's stat hovers and the summary lines show. Per sword and attack type: attack power (general, per attack type, per sword), damage per hit against an enemy with no armor or resistance ((weapon + elemental damage) × (1 + damage bonuses) × attack power, strong attacks with Strong Attack's multiplier), crit chance, crit power (attack power plus crit bonuses) and crit damage, and the expected damage per hit (normal and crit weighted by the crit chance), which replaces 1.32's damage per second. The sheathed sword's bonuses are read from the item, so both swords show their own damage, attack power, crit and effects; other bonuses (sign power) only show while the sword is drawn (changelist 1172–1174). Terms: Muscle Memory and Strength Training per attack type, Precise Blows and Crushing Blows, the Lynx chain, Bear tier 1 attack power per adrenaline point, Thunderbolt 3's crit chance, Heft, Euphoria's damage, the Wolven tier 2 oil bonuses, `sword_dmg_bonus` (NG+), Invigoration's 1.32 line removed. Crossbow: attack power, crit chance, crit damage (legacy's list also reads Cat Eyes' `critical_damage`, which its data comments out: 0), bolt damage by type with Steady Shot's +50 and Cat Eyes' doubled base, elemental bolt damage.

**Implementation (legacy):** `W3PlayerWitcher.GetOffenseStatsList` (rewritten), `SPlayerOffenseStats` (new fields: attack power and crit attack power per attack type and sword, crossbow attack power, crit damage bonus, elemental damage and its type). Legacy's Life Leech reads the list's attack power (`Mutation11GetBaseStrength`).

**5.x:** 1.32's DPS model with 5.x's new-tree perk terms and Heightened Tolerance's crit damage; the port's new-tree slots hold legacy's skills (SKL), so those terms read the wrong skills. The port's `damage/formula.ws` still calls the list for 5.x's allied-NPC block, which DMG-12 switched off (no reader in play); MUT-12's drain computes its own average attack power (the deviation below).

**Decisions:** DU1 (owner, 2026-10-20): legacy's list and terms in both trees, each classic term read from either tree's skill; 5.x's terms for the perks and skills the port replaced are dropped; 5.x-only gear (SWD-10's swords, ARM-15's armor) reads through the same item attributes.
Each term is the one Ghost Mode's formula gives a hit: the attack power as the attack action builds it (the attack power plus the abilities tagged with the attack's name, which carry the classic Muscle Memory and Strength Training per level, Strong Attack's term and the style attributes), the conditional terms counted only while they are active (the Feline chain, the Bear set per adrenaline point, the new tree's Muscle Memory while armed with its +10% total damage on fast hits, Strength Training's stacks with their weapon damage), Precise Blows and Crushing Blows of either tree, the pool's terms (Strong Attack's +50%, Heft, `sword_dmg_bonus`), Euphoria's base damage. Situational terms are not shown, as legacy: headshots, backstabs, oils against a monster type, counters, Wolf School and Hunter Instinct against an enemy. The crossbow: attack power with the Bear set, crit chance as a bolt gets it, crit damage with Anatomical Knowledge of either tree, Steady Shot's (or Cold Blood's) flat damage, Cat Eyes' doubled base, no additive attack power (DMG-03). 5.x's terms are gone: its new-tree perks, Heightened Tolerance, Water Hag's `damageIncrease` (ALCH-10's list part), Runeword 4's overheal, `perk_2`'s crossbow attack power, the ×1.833 heavy multiplier and the attack speed divisors.
- **Deviation:** Thunderbolt 3's +100% in a storm is counted as crit chance, as the hit counts it; legacy's list added it to crit power (porter's call, confirmed by the owner, 2026-10-21).
- **Deviation:** the expected hit weights normal and crit damage by the crit chance capped at 100%; legacy's list did not cap it (Life Leech's average attack power keeps legacy's uncapped weighting) (porter's call, confirmed by the owner, 2026-10-21).
- **Deviation:** the bolt's damage is read from the equipped bolt (its level's values, ITEM's DI1), as the hit reads it; legacy's list read the bolt's definition (porter's call, confirmed by the owner, 2026-10-21).

**Verification (slice 3, 2026-10-21, both trees):** scripted: `GMTest_ui01` (in the regression): 5.x's struct carries Ghost Mode's list, the expected hit is the crit-weighted average, Life Leech's base strength = sword damage + the list's average attack power + sign intensity. `gmtest_ui01_hits` (scripted hits through `ProcessAction` on a neutral test dummy, a human for the steel sword and a drowner for the silver one; the damage probe records the hit): for fast and strong, normal and crit hits with each sword, the list's attack power equals the hit's exactly and the damage dealt is the list's within the hit's random 0.9 to 1.1; without skills, with the classic tree's Muscle Memory, Strength Training, Precise Blows and Crushing Blows at level 5 (fast and strong 1.5, crit 2.5) and with the new tree's `sword_s22` to `sword_s25` at level 3 (Muscle Memory armed: fast 1.6, crit 2.45; Strength Training's stack: strong 1.35). `gmtest_ui01_terms`, both trees, level 30: Crossbow 1 with Bodkin bolts: (5 + Steady Shot 50) × attack power 2.01 = 110.55, with Cat Eyes 221.1; crit damage +100% with Anatomical Knowledge (`sword_s7` or `sword_s26`); three Bear pieces at 2.5 adrenaline +0.21 attack power, three Feline pieces with two fast hits' chain +0.15 fast and +0.3 strong. Real, on screen: the inventory's stats view (C) in both trees at level 30 with the skills above (screenshots): the silver sword's fast and strong damage, crit chance and crit damage and the swords' headline values follow the list (still under 5.x's labels until UI-02).

**Verification (UI audit slice A, 2026-10-21, 5.x-GM `e58db763`, both trees):** scripted: `GMTest_ui01_crit` (in `gmtest_panel()`; `gmtest_ui01_crit()` alone): the panel's fast and strong crit chance of each sword equal the hit's `GetCriticalHitChance`, the drawn sword as is, a sheathed one with its own crit chance and the Wolven oil bonus added: without skills 5 % (the steel and the silver sword sheathed and drawn in turn, `gmtest_ui01_draw`), classic Precise and Crushing Blows 5: 14.99 %, the new tree's `sword_s24`, `sword_s25` 3: 13 %.

**Ends:** SKL-06's Steady Shot deviation; MUT-11's Cat Eyes, MUT-12's average attack power (the drain reads the list again, as legacy), ARM-06's Feline and ARM-08's Bear deviations; with UI-02 and UI-03, ALCH-10's Water Hag lines, MUT-09's Euphoria lines and SWD-07's panel lines; DMG's, SWD's and ENCH's (Heft) hand-offs.

**Later:** —

### UI-02 Panel: sword and crossbow sections, summary lines

| | |
|---|---|
| Kind | ui |
| Pillars | P7 |
| 5.x class | clean (popup); conflict (the new character menu's summary) |
| Flags | — |
| Depends on | UI-01, SKL-03 (Crippling Strikes' chance), SKL-05 (instant kill without Deadly Precision), MUT-13 (Metamorphosis' chance lines) |
| Skill trees | both: classic Crippling Strikes `sword_s5`, new `sword_s29`; both menus' summaries |
| Port form | `ui/characterStatsPopup.ws` (STAM's file): `@replaceMethod` of the global `GetPlayerStatsGFxData` (the sword and crossbow sections legacy's; the other sections are changed by UI-03 to UI-05), wrappers of the global `AddCharacterStatU` (values from UI-01's list; the summary line's label for both character menus and the inventory, so no menu wrapper is needed) and `AddCharacterStatU2`, `@replaceMethod` of `GetEquippedCrossbowDamage`; 19 strings in 9 languages (2110992017, 018, 028, 029, 074–085 by key hash, 105, 167, 168) |
| Port status | **signed off** (2026-10-21); **ported** (slice 4, 5.x-GM `8dad0e47`), verified in both trees |
| Open checks | the new character menu's summary line on screen (its view opened by `dupemenu()` shows the skill tree; checked by script) |
| Save impact | none (expected) |
| NG+ counterpart | none |

**What it does** (changelist 1161–1162, bugfix 169): the silver and steel sections are headed "Damage per hit" (the average of the fast and strong expected hits, UI-01); each lists, for fast and then strong attacks, attack power, damage, crit chance, crit power and crit damage, then the effect chances (poison, bleeding with Crippling Strikes, burning, confusion, freezing, stagger; Metamorphosis' bonus). The crossbow section lists attack power, crit chance, crit damage, adrenaline gain per bolt (Cold Blood), the bolt's damage under its damage type's name and its elemental damage. Instant kill shows the larger of the two swords' chances, not their sum. The labels of 1.32's DPS lines read "Fast attack damage" and so on (12 strings by key hash, also in the inventory's stat hovers); the summary's "Damage per hit" labels are legacy's `_dph_gm` strings.

**Implementation (legacy):** `GetPlayerStatsGFxData` (sections), `AddCharacterStatU` (the sword and crossbow values, instant kill), `AddCharacterStatU2` (chances), `GetEquippedCrossbowDamage` (Water Hag's line removed, Steady Shot moved), new `GetCrossbowSteelDmgName`, `GetCrossbowElementaDmgName`, `IsBoltEquipped`; `CR4CharacterMenu.UpdatePlayerStatisticsData` (labels); strings 2110992017, 018, 028, 029, 074–085, 167, 168.

**5.x:** the popup is 1.32's; the new character menu has its own copy of the summary (`characterMenuDupe.ws:3296`), which needs legacy's labels too (5.x-only code; the classic `characterMenu.ws` is not used by the port).

**Decisions:** port as legacy (DU1). The crossbow's adrenaline line reads Cold Blood of either tree (legacy: `perk_2`), with Razor Focus and Adrenaline Rush's factor; the bleeding chance adds Crippling Strikes of either tree. 5.x's Flash popup draws legacy's rows as they come (20 rows in a sword section, 7 in the crossbow's), seen on screen. 5.x's new character menu has its own hover tooltip for offense (`GetOffenseTooltipData`, 1.32's, which legacy left too); not changed.

**Verification (slice 4, 2026-10-21, both trees):** scripted: `GMTest_ui02` (in `gmtest_panel()`, after the regression, and again with skills): the stats popup built by `GetPlayerStatsGFxData` with a menu open: "Damage per hit (silver)" and "(steel)" with the average expected hit; the silver section's 20 lines with the list's values (attack power 150 % with Muscle Memory 5, crit power 250 %), legacy's labels ("Fast attack damage", "Fast attack power", "Fast attack critical hit power"); the steel bleeding chance 25 % with Crippling Strikes 5 (classic) and 3 (`sword_s29`); the crossbow section with Crossbow 1 and Bodkin bolts at level 30: attack power 201 %, crit chance 30 %, crit damage 100 %, adrenaline gain 0.10 (Cold Blood, `perk_2` or `sword_s34`), piercing 111, silver 109, the headline 210; instant kill the larger sword's; 5.x's summary call returns "Damage per hit (silver) 196". Real, on screen (inventory's stats view, hovered with the mouse; screenshots): the silver section (classic), the crossbow section (classic), the steel section (new tree).

**Ends:** SWD's hand-off (sword sections, instant kill); with UI-01, ALCH-10's Water Hag deviation (ended); with UI-03, MUT-13's.

**Later:** —

### UI-03 Panel: signs

| | |
|---|---|
| Kind | ui |
| Pillars | P7, P3 |
| 5.x class | conflict (5.x changed `AddCharacterStatSigns`) |
| Flags | — |
| Depends on | SKL-08 to SKL-12 (signs of both trees), DMG-06 (`SignPowerStatToPowerBonus`), MUT-02, MUT-09, MUT-13, ALCH-11 (Foglet, Wraith), ARM-07 (Griffin), ENCH-12, ENCH-13 (Retribution, Rotation), SWD-07 (`spell_dmg_bonus`) |
| Skill trees | both: the sign skills of SKL-08 to SKL-12 in each tree (e.g. Aard Intensity classic `magic_s12`, new `magic_s39`; Sustained Glyphs `magic_s10`/`magic_s42`; Puppet `magic_s5`/`magic_s31`; Quen Discharge `magic_s14`/`magic_s40`); shared `magic_s3`, `magic_s4`, `magic_s13` |
| Port form | `ui/signStats.ws`: a wrapper of the global `AddCharacterStatSigns` (5.x builds the line, Ghost Mode's value replaces its value: `GMPanelSignValue`, each skill read from either tree; a name without a string shows its key, as legacy); the two sections in UI-02's `GetPlayerStatsGFxData`; 13 strings in 9 languages (2110992019, 020, 022–026, 030, 272, 277, 278, 293, 461) |
| Port status | **signed off** (2026-10-21); **ported** (slice 5, 5.x-GM `52db5ef7`), verified in both trees |
| Open checks | the character menu's stats popup on screen (the inventory's stats view, built by the same function, was seen); real casts checked for Quen, Yrden and Axii only (`gmtest_ui03_casts`, below); Aard's and Igni's chances and the damage lines against real casts |
| Save impact | none (expected) |
| NG+ counterpart | none |

**What it does** (changelist 1157–1160): the common sign power line shows the raw value; each sign gets its own intensity line and its values with every modifier, as raw values before the target's resistance: Aard knockdown and heavy knockdown chance (Metamorphosis), force damage; Igni burn chance (Pyromaniac, Rotation, Metamorphosis), fire damage (Igni Intensity, Rotation, Conductors of Magic, Euphoria, Foglet, `spell_dmg_bonus`), Firestream damage per second; Quen intensity (Wraith's bonus), duration, absorption, active shield absorption, discharge as points and as a share (Retribution); Yrden intensity, traps, duration, range (Sustained Glyphs, the Griffin set's +40%), slowdown, turret duration, charges and damage; Axii intensity, confusion and control durations, instant kill chance. Yrden and Axii move to a second section.

**Implementation (legacy):** `AddCharacterStatSigns` (rewritten), `GetPlayerStatsGFxData`; strings 2110992019–027, 030, 272, 277, 278, 293, 461 (021 and 027 label lines legacy commented out: not ported).

**5.x:** 1.32's lines with 5.x's new-tree terms (Shock Wave's damage, Conjunction, Melt Armor's burn chance, a logarithmic burn chance); the port gave those slots legacy's skills (SKL-08 to SKL-12), so 5.x's terms go.

**Decisions:** port as legacy in both trees (DU1). Q3 (owner, 2026-10-20): use 5.x's character menu and popup however is easiest, as long as all of legacy's information is shown; one combined sign section is fine. Legacy's two sections work in 5.x's Flash popup (seen on screen: two "Sign intensity" rows), so they are kept. The damage lines add the damage pool's flat sign terms as the hit gets them (Mutation 1 from the held sword's total damage, Foglet, Euphoria's drain), then `spell_dmg_bonus` and the intensity.
- **Deviation:** the sign lines show each value as the port's cast gets it where legacy's panel computed it differently: Yrden's range multiplies Sustained Glyphs' and the Griffin set's bonuses (legacy's panel added them; the trap scales by both); the second trap from Sustained Glyphs' level 3 (legacy's panel: level 2; the cast: level 3); Quen's and Yrden's durations and Axii's with Petri's Philtre level 3; the knockdown chance clamped to 10 % to 100 % before Metamorphosis, the heavy knockdown chance as a share of it; Exploding Shield's damage 0 below level 2, Retribution on its base only, and `spell_dmg_bonus` (the NG+ school swords) on it as on every sign hit (legacy's panel left it out of this line); the Yrden slowdown clamped to its minimum and maximum; the Axii instant-kill chance rounded to a whole percent as rolled (porter's call, confirmed by the owner, 2026-10-21).

**Verification (slice 5, 2026-10-21, both trees):** scripted: `GMTest_ui03` (in `gmtest_panel()`): the popup built by `GetPlayerStatsGFxData` has two sign sections of 19 and 16 lines, every line named, legacy's labels by id ("Knockdown chance", "Heavy knockdown chance", "Firestream damage per sec", "Damage absorption", "Magic Trap Range", "Confusion duration"); without skills on the test save: knockdown 33 %, heavy knockdown 5 %, fire damage 150, burning 33 %, Quen 30 s and 250, Yrden 7.5 s, range 2.7, slowdown 25 %, Axii confusion 5 s, instant kill 1 %, the skill lines 0. `gmtest_ui03_skills` at level 30 (intensity +26 %) with the classic skills at level 5 (Aard Intensity, Shock Wave, Igni Intensity, Pyromaniac, Quen Intensity, Quen Discharge, Yrden Intensity, Axii Intensity) and the new tree's counterparts at level 3, plus Firestream, Exploding Shield, Active Shield, Sustained Glyphs, Magic Trap and Puppet: the same totals in both trees (D58): heavy knockdown 12 % (30 % of 40 %), Shock Wave 378 (300 x 1.26), burning 58 %, fire damage 378 ((150 + 150) x 1.26), Firestream 221/s, absorption 484 and active shield 967, Discharge 25 %, Exploding Shield 76, two traps, trap 15 s and range 3.5, turret 15 s, 6 charges, 315 damage, confusion 9.1 s, control 36.3 s. Real, on screen (inventory's stats view, both sign rows hovered with the mouse; screenshots in both trees): the two sections with the values above. Real casts (UI audit, 2026-10-21, both trees, level 30, classic Sustained Glyphs 3, Quen Intensity 5, Axii Intensity 5 and the new tree's `magic_s42`, `magic_s38`, `magic_s36` at 3; casts by input simulation, the cast entities read by a temporary probe): the panel's Quen absorption 484 and 30 s equal the shield's 483.5 and 30 s; Yrden 15.0 s, range 3.5 and 2 traps equal the trap's 14.99 s, 3.5 and 2; Axii's confusion 9.1 s equals the effect's 9.06 s on the neutral dummy. Repeated as a test (UI audit slice A, 5.x-GM `e58db763`, both trees, the same skills): `gmtest_ui03_cast(sign)` casts by input simulation (the cast input pressed by script), `gmtest_ui03_casts(sign)` compares the cast entity with the panel's line up to its display precision: Quen 483.51 and 30 s against 484 and 30 s; Yrden 14.99 s, 3.5, 2 traps against 15.0 s, 3.5, 2; Axii 9.06 s against 9.1 s; 3 passed, 0 failed in each tree. Each sign is checked before the next cast: Quen's shield is gone once another sign is cast (its entity then reads 0).

**Ends:** ALCH-11's deviation (Foglet's line, Wraith's Quen power), MUT-13's (with UI-02), SWD-07's (with UI-01); MUT-09's sign part (its drain line waits for UI-04); SKL's audit F34 hand-off; ARM's Griffin Yrden range and ENCH's Rotation and Retribution hand-offs.

**Later:** —

### UI-04 Panel: toxicity

| | |
|---|---|
| Kind | ui |
| Pillars | P7 |
| 5.x class | clean |
| Flags | — |
| Depends on | ALCH-01 (threshold, decay), SKL-17 (Fast Metabolism `alchemy_s15`, shared), ARM-04 (medium set), ENCH-07 (Placation), MUT-08, MUT-09 (Toxic Blood, Euphoria) |
| Skill trees | n/a (Fast Metabolism is shared) |
| Port form | `ui/characterStatsPopup.ws`: a wrapper of the global `AddCharacterStatToxicity` (`GMPanelToxicityDecay`: the toxicity effect's own terms, as `W3Effect_Toxicity.RecalcEffectValue` and ARM-04's wrapper give them); the section in UI-02's `GetPlayerStatsGFxData`; 4 strings in 9 languages (2110992423–425, 519) |
| Port status | **signed off** (2026-10-21); **ported** (slice 6, 5.x-GM `a31306a4`), verified in both trees |
| Open checks | — |
| Save impact | none (expected) |
| NG+ counterpart | none |

**What it does** (changelist 1164): locked toxicity, available toxicity (maximum − current), decay rate per second (base, medium set, Fast Metabolism, Placation, Toxic Blood's reduction), overdose threshold (75% of the maximum, ALCH-01), overdose Vitality drain per second (Euphoria's factor). The current toxicity line goes (the bar shows it).

**Implementation (legacy):** `AddCharacterStatToxicity`; strings 2110992423–425, 519.

**Decisions:** port as legacy.

**Verification (slice 6, 2026-10-21, both trees):** scripted: `GMTest_ui04` (in `gmtest_panel()`): the section's 5 lines with legacy's labels ("Toxicity offset", "Available Toxicity", "Toxicity Decay Rate", "Overdose threshold", "Overdose Vitality drain"), no current toxicity line; available = maximum − current, threshold 75 of 100, drain 18/s (5.x's drain from maximum Vitality, 3,500 on the test save). `gmtest_ui04_live` with toxicity added (`addstat`) and the toxicity effect running: the decay line equals the live effect's decay per second, 0.5/s with the medium set (the test save's armor), 0.62/s (classic) and 0.87/s (new tree) with Fast Metabolism 3 and Toxic Blood. Real, on screen (inventory's stats view hovered, new tree; screenshot): the section with 28 toxicity: 72 available, 0.87/s, 75, 18/s.

**Ends:** ARM-04's (`tox_dec_rate`) and MUT-08's (Toxic Blood) deviations, MUT-09's (with UI-01 and UI-03); ALCH's and ENCH's (Placation) hand-offs.

**Later:** —

### UI-05 Panel: vitality, armor and other lines

| | |
|---|---|
| Kind | ui, fix |
| Pillars | P7 |
| 5.x class | clean |
| Flags | — |
| Depends on | STAM-04, STAM-05 (the existing `ui/characterStatsPopup.ws`), SKL-07 (Razor Focus `sword_s20`), SKL-03, SKL-04 (Muscle Memory, Strength Training of both trees), SKL-06 (Cold Blood: classic `perk_2`, new `sword_s34`), MUT-07 (Adrenaline Rush), OPT-03 (the Vitality regen options, ported by OPT slice O1, 2026-11-02) |
| Skill trees | both (as UI-01) |
| Port form | `ui/characterStatsPopup.ws`: the global `AddCharacterStat` wrapper extended (Vitality regen, sign power; STAM-05's armor line moved to the armor section of `GetPlayerStatsGFxData`), UI-02's `AddCharacterStatU` wrapper (adrenaline gain, `GMPanelAdrenalineGain`), the misc section's lines in `GetPlayerStatsGFxData` (the money bonus by 5.x's `AddCharacterStatF`), `@replaceMethod` of `AddCharacterHeader` (legacy's name fallback; the same fallback in `AddCharacterStat` and `AddCharacterStatF` is not ported: none of their lines lacks a string, so nothing differs on screen); 2 strings in 9 languages (2110992383, 384; 105 came with UI-02) |
| Port status | **signed off** (2026-10-21); **ported** (slice 7, 5.x-GM `1a6a9fd6`), verified in both trees |
| Open checks | the attack power and sign intensity lines with Adrenaline Rush running (they read the attack power and sign power stats the Rush changes; not tested); the armor regen line on screen (scripted only) |
| Save impact | none (expected) |
| NG+ counterpart | none |

**What it does** (changelist 1163, bugfixes 89, 132): Vitality regen in and out of combat shows the multiplicative part (1.32 showed the additive part only) and the regen options; sign power shows its raw value; the misc section gains the money bonus and adrenaline gain (general, fast and strong with Muscle Memory and Strength Training, Razor Focus, Adrenaline Rush's rise or fall) and loses the XP bonus lines; the armor regen modifier line (option on) sits under Armor; a name without a string shows its key (legacy's fallback).

**Implementation (legacy):** `GetPlayerStatsGFxData`, `AddCharacterStat`, `AddCharacterStatU`, `AddCharacterStatF`, `AddCharacterHeader`; strings 2110992105, 383, 384.

**5.x:** 1.32's lines.

**Decisions:** port as legacy; DU3 (owner, 2026-10-20): the armor regen modifier line under Armor, as legacy (moved from STAM-05's stamina section). The adrenaline lines give a hit's gain as the port's hit gets it (Muscle Memory and Strength Training of either tree, Razor Focus, the Bear School's bonus with its perk, Adrenaline Rush's factor). Sign power's raw value is read with `GetPowerStatValue(CPS_SpellPower)` (Geralt's raw `spell_power` attribute reads -9999 in 5.x).
- Ended: the temporary deviation "the Vitality regen lines read without legacy's Vitality regen options" (until OPT; owner, 2026-10-21). Since OPT's slice O1 (OPT-03, 2026-11-02) the lines add the two options, as legacy's; they leave out 5.x's "Vitality Regeneration Boost" (OPT's PO5).

**Verification (slice 7, 2026-10-21, both trees):** scripted: `GMTest_ui05` (in `gmtest_panel()`): the Vitality regen lines equal the additive part plus the multiplicative part of maximum Vitality (1/s on the test save, 41/s with the regression's potions); the sign power headline "+0 %" (the raw value); the misc section with "Chance to take additional coin while looting", herbs, instant kill and "Adrenaline Gain 0.10", no experience lines; STAM-05's panel checks: no armor line with the option off, the modifier under Armor and not under Stamina with it on. `gmtest_ui05_skills`: with Razor Focus 3 and Muscle Memory and Strength Training (classic level 5: +0.15 each; new tree `sword_s22`, `sword_s23` level 3: +0.15 each): general 0.12, fast and strong 0.13 (classic) and 0.14 (new tree, its Razor Focus). Real, on screen (inventory's stats view, the misc section hovered, new tree; screenshot): money, herbs, instant kill, adrenaline 0.12, fast 0.14, strong 0.14.

**Ends:** MUT-07's deviation (Adrenaline Rush lines, with UI-01's attack power).

**Later:** —

### UI-06 Item tooltips: descriptions and stat display

| | |
|---|---|
| Kind | ui, fix |
| Pillars | P7, P4 |
| 5.x class | conflict (5.x rewrote `GetBaseItemData`) |
| Flags | — |
| Depends on | ALCH-16, ALCH-17 (their wrappers of `GetBaseItemData`, `AddItemStats`, `CalculateStatsComparance`), ARM-02 (classes), ARM-09 (Wolven), SKL-13 (Expert Brewer `alchemy_s3`), SKL-16 (Adaptation `alchemy_s14`), SKL-14 (Fixative), TRPH (trophy values) |
| Skill trees | both: classic Fixative `alchemy_s6`, new `alchemy_s25` (5.x's UI reads only `alchemy_s6`); shared Expert Brewer and Adaptation |
| Port form | `ui/tooltips.ws`: a `GetBaseItemData` wrapper (descriptions, the oil's stats and charges; it marks a trophy's tooltip, `gmTipTrophy`), `@replaceMethod` of `W3TooltipComponent.AddOilInfo` and of the global `CalculateStatsComparance`, `@addMethod GMAddOilStats`; ALCH-17's `AddItemStats` wrapper (`alchemy/tooltips.ws`) extended (toxicity, negative values, a trophy's stats as gear's); the HUD's infinite-oil checks (`mutations/hudCounters.ws`) read either tree's Fixative (`GMFixativeNoWear`); 4 strings |
| Port status | **signed off** (2026-10-21); **ported** (slice 1, 5.x-GM `6ca81e09`), verified in both trees |
| Open checks | a book's, key's and quest item's description by name key on screen (ALCH audit F6); a Gwent card's and a trophy's tooltip on screen; a sword's oil line and the HUD's oil charges on screen (scripted only); comparisons on screen (scripted with made-up stats) |
| Save impact | none (expected) |
| NG+ counterpart | none |

**What it does** (bugfixes 41, 91, 104; code): armor and weapons show their item description (1.32 showed none), and the light, medium and heavy armor texts state the class's stamina rule (strings 2110992426–428); Gwent cards show no description; notes say "Contains useless information." (2110992256, by legacy's name-key lookup ported in ALCH-17); trophies list their stats like gear; a negative value has no "+", and comparing negative modifiers shows better and worse the right way round; a potion's toxicity is shown after Expert Brewer's reduction without "/max" and a decoction's offset after Adaptation; oils list every bonus (attack power, crit chance, crit damage, with the Wolven tier 1 boost per piece), and a sword's oil line shows the oil's name and charges only.

**Implementation (legacy):** `W3TooltipComponent.GetBaseItemData` (descriptions, trophies, oil stats), `AddItemStats` (toxicity, negative values), `CalculateStatsComparance` (comparisons), new `AddOilStats`, `AddOilInfo`.

**5.x:** armor and weapon descriptions still hidden; 5.x's own sword descriptions (`sq304`, `q402` swords); oil charges with Fixative read only `alchemy_s6`.

**Decisions:** port as legacy (DU4). Swords with a description of their own keep it: Aerondight and Iris (SWD's) and 5.x's two unique swords (`sq304`, `q402`, 5.x-only). Legacy passed trophies to `AddItemStats` as gear; that flag only changes the toxicity line, which the Arachas trophy has (+40 maximum toxicity): ported since the TRPH audit's F2 (2026-11-02), so its row reads "Maximum Toxicity +40" as legacy's, not a potion's "Toxicity 40" (39 with Expert Brewer, which cut it as a potion's). Regression check `GMTestTrphToxTip` (in `GMTest_trph`), with Expert Brewer `gmtest_trph_toxtip()`; **verified** on the fix build (gm/fix1 `bc56705c`, the tested build `d2b22899`, both trees, scripted), failed first on a build without the fix ("Toxicity 40", "39"). The oil's charges with Fixative count either tree's skill (5.x and legacy read the classic one only).

**Verification (slice 1, 2026-10-20, both trees):** scripted (`GMTest_ui06`, in the regression): Light armor 01's tooltip shows "Light gear. Offers minimal protection. Combat actions require less stamina." and a steel sword "Steel sword. Used when fighting humans."; Superior Beast Oil lists attack power 25 %, crit chance 5 %, crit power 25 % and "60 charges"; an oiled sword's line reads "Superior beast oil (60/60)"; Thunderbolt 1's toxicity "20" (no "/max"); `CalculateStatsComparance` with made-up stats: a new negative modifier "worse", "-10 %"; losing a negative one "better", "+20". With skills (`gmtest_ui06_skills`, equipped by `skilleq`): Expert Brewer 3 shows Thunderbolt 1's 20 as 17 (classic) and 15 (new tree), Adaptation 3 the Werewolf decoction's offset 70 as 62 and 56; the oil's charges "60 ( +60 )" with `alchemy_s6` and with `alchemy_s25`; the HUD's infinite-oil check follows either Fixative. Real, on screen (inventory opened by `r4inventory()`, items hovered with the mouse; screenshots): the Cidarian Gambeson's tooltip with the class text, the Superior Beast Oil's three bonuses and charges, the Witcher's steel sword with its description.

**Ends:** ALCH-16's and ARM-09's oil deviations, ALCH-17's toxicity line deviation; SKL-14's open check (the oil charges with the new tree's Fixative); ALCH's `GetBaseItemData` hand-off (Gwent cards, armor and weapon descriptions) and the check of ALCH audit F6.

**Later:** —

### UI-07 Tooltip rows and attribute names

| | |
|---|---|
| Kind | ui |
| Pillars | P7 |
| 5.x class | clean |
| Flags | — |
| Depends on | STAM-05, ENCH-16 (rune and glyph regen), XBOW (bolt knockdown), TRPH (frost resistance), ARM-01 (Yoana's armor) |
| Skill trees | n/a |
| Port form | rows in the `tooltip_settings.csv` override; 8 strings |
| Port status | **signed off** (2026-10-21); **ported** (slice 1, 5.x-GM `6ca81e09`), verified in both trees |
| Open checks | — |
| Save impact | none |
| NG+ counterpart | none |

**What it does:** item stats legacy added get a tooltip row and a name: the armor regen modifier (shown only with the option on, STAM-05), frost resistance, a bolt's knockdown chance, combat Vitality regen, Yoana's arrow bounce chance; names for Vitality regen in and out of combat, knockdown chance, crit power bonus, damage increase, Vitality drain.

**Implementation (legacy):** `tooltip_settings.csv` rows `staminaRegen_armor_mod`, `frost_resistance_perc`, `desc_knockdownchance_mult`, `vitalityCombatRegen`, `q108_bounce_arrows`; strings 2110992013, 110, 153, 156, 157, 164, 265, 476.

**Decisions:** port as legacy.

**Verification (slice 1, 2026-10-20, both trees):** scripted (`GMTest_ui06`, in the regression): the five names read legacy's strings by key ("Frost resistance", "Vitality regeneration outside of combat", ...). Not seen on screen: an item with one of the five rows. The combat Vitality regen name (2110992157) names a food or drink tooltip's in-combat regen row since the FOOD audit (F4, owner 2026-10-24), through FOOD-08's code ([food.md](food.md#food-08-edible-tooltip)); UI's code is unchanged.

**Ends:** STAM-05's tooltip row deviation; ENCH's hand-off (Vitality regen names).

**Later:** —

### UI-08 Recipe and schematic texts

| | |
|---|---|
| Kind | ui, fix |
| Pillars | P7 |
| 5.x class | clean |
| Flags | — |
| Depends on | ALCH-17 (potion, bomb and decoction texts by name), ENCH-17, CRAFT (ingredients) |
| Skill trees | n/a |
| Port form | `ui/recipes.ws`: `@replaceMethod`s of `W3TooltipComponent.GetRecipeDataFromXML`, `W3GuiBaseInventoryComponent.GetAlchemyBookText` and `GetSchematicBookText`; `@addMethod GMAddComponentsInfo` called from a `GetBaseItemData` wrapper (which also adds a recipe's potion or bomb effects and a decoction recipe's values); a `GetCraftedItemInfo` wrapper empties the random-attribute line |
| Port status | **signed off** (2026-10-21); **ported** (slice 2, 5.x-GM `5b5ab8a5`), verified in both trees |
| Open checks | a recipe or schematic item's tooltip and the extended text (E) on screen at a merchant (scripted only: an added recipe is read at once); the crafting menu on screen |
| Save impact | none |
| NG+ counterpart | none |

**What it does** (bugfix 87, changelist 1170): a recipe item in a shop or the inventory shows what it brews (1.32's typo `'alchemy_recipies'` made it show nothing); schematic, recipe and enchantment schematic tooltips list the ingredients as "have / need", red when short; the extended text (shown with E when buying) reads: item name in orange and rarity, the effects as "value name", the description (a decoction's with its values), the level required, the ingredients as "have / need"; the weight and the "random attributes" lines are gone (crafted gear has no random bonus: SWD's and ARM's `DoNotEnhance`), also in the crafting menu.

**Implementation (legacy):** `GetRecipeDataFromXML` (the typo), `addComponentsInfo` (new), `GetAlchemyBookText`, `GetSchematicBookText`, `GetCraftedItemInfo`.

**5.x:** 1.32's (typo included); the port's ALCH-17 wrapper reads the broken `GetRecipeDataFromXML`, so its test for a decoction's recipe never matches until this fix.

**Decisions:** port as legacy (DU5).
- **Deviation:** the extended texts name and colour every effect as the item tooltip does (slowdown, breath, focus; the default colour for a stat without one); legacy printed the names as they came, so a potion's slowdown showed as a bare "50 %" (porter's call, confirmed by the owner, 2026-10-21).

**Verification (slice 2, 2026-10-20, both trees):** scripted (`GMTest_ui08`, in the regression): `GetRecipeDataFromXML('Recipe for Blizzard 1')` finds Blizzard 1; the recipe's tooltip lists Toxicity 25, Effect duration 30 s, Slowdown 50 % and "0 / 1 Dwarven spirit", "1 / 5 White myrtle petals", "0 / 1 Golem's heart" (red); its extended text "Usable Items / Potion", "Master Item", "25 Toxicity", "30 Effect duration", "50 % Slowdown", the description, "Required:" and the ingredients as have / need, no weight; a decoction recipe's tooltip and text with its values (no `$`); Short sword 1's schematic tooltip and text with have / need, no weight or random-attribute line; the crafting menu's line empty. Real, on screen: the alchemy menu opened from the hub (screenshot), unchanged by this slice.

**Ends:** ALCH-17's recipe book deviation; ENCH-17's (`addComponentsInfo`) and ITEM's (book layout) hand-offs.

**Later:** —

### UI-09 Alchemy menu: buying ingredients

| | |
|---|---|
| Kind | ui |
| Pillars | P8 |
| 5.x class | in-5.x (buying); clean (Yolar's pin) |
| Flags | — |
| Depends on | — |
| Skill trees | n/a |
| Port form | none for buying (5.x's); Yolar: `ui/mapPins.ws`, `@wrapMethod` of `W3MerchantComponent.GetMapPinType` |
| Port status | **signed off** (2026-10-21); **ported** (Yolar's pin, slice 9, 5.x-GM `4a61e025`; compiles, not seen in game) |
| Open checks | which NPCs open the alchemy menu in 5.x; Yolar's pin on the map (not on the test save; compiles only) |
| Save impact | none |
| NG+ counterpart | none |

**What it does** (code; modFriendlyHUD's, merged into legacy): in the alchemy menu opened at a herbalist or alchemist (by the NPC's map pin), the recipe list shows the vendor's stock and price, and a missing ingredient can be bought there; the druid Yolar's map pin shows him as a herbalist.

**5.x:** the same buying, from whichever NPC opened the menu (no pin check); Yolar's pin unchanged.

**Decisions:** Q2 (owner, 2026-10-20): keep 5.x's buying from any merchant who opened the menu (the owner reports it if it plays wrong); legacy's herbalist gate is not ported; Yolar's pin is ported if it is a separate, clean change. It is (one line in legacy's `GetMapPinType`, a wrapper here): ported.

**Ends:** ALCH's hand-off (buying ingredients).

**Later:** —

### UI-10 Bestiary kill count

| | |
|---|---|
| Kind | ui |
| Pillars | P10 |
| 5.x class | clean |
| Flags | — |
| Depends on | XP (legacy counts in `CNewNPC.CalculateExperiencePoints`, which XP reworks; diminishing returns read the counts) |
| Skill trees | n/a |
| Port form | `ui/bestiary.ws`: `@addField` saved `gmEnemiesKilledByType` on `W3PlayerWitcher`, `@addMethod`s `GMIncKills`, `GMGetKills`; legacy's enemy types and functions as `EGMEnemyType` (`GMENT_...`), `GMGetEnemyTypeByAbility`, `GMGetLocStringByEnemyType` (shared with XP; `GetExpByEnemyType` stays XP's); the count is incremented in XP-04's `@replaceMethod(CNewNPC)` `CalculateExperiencePoints` (`xp/killExperience.ws`, legacy's counting place, after the experience is computed; UI-10's wrapper folded in there in XP slice X3, PX5); since X3 `GMGetEnemyTypeByAbility` also counts 5.x's `ConDefaultSilver` (the plague victims) as humans (XP's DX4); `CR4GlossaryBestiaryMenu`: `PopulateData` and `UpdateItems` replaced, `UpdateImage` and `UpdateDescription` wrapped; 9 strings in 9 languages (2110992301–309) |
| Port status | **signed off** (2026-10-21); **ported** (slice 8, 5.x-GM `a736a02e`), verified in both trees |
| Open checks | a kill in a real fight (scripted kills through the game's death path only) |
| Save impact | a new saved field: kills count from the mod's installation (DU6); an older save starts at 0 |
| NG+ counterpart | none |

**What it does** (changelist 1167): the bestiary gets a "Kill count" group with one entry: total kills, humanoids (with Wild Hunt warriors), animals, monsters and unique creatures, then kills by enemy type. A kill counts when it would give experience; guards count as humanoids without experience.

**Implementation (legacy):** `CR4GlossaryBestiaryMenu.PopulateData`, `UpdateItems`, `UpdateImage`, `UpdateDescription`, new `UpdateKillCountEntry`; `W3PlayerWitcher.IncKills`, `GetKills`, saved `enemiesKilledByType`; `gm_generic.ws` `EEnemyType`, `GetEnemyTypeByAbility`, `GetLocStringByEnemyType`; strings 2110992301–309. `GetExpByEnemyType` and `GetExpModifierByEnemyType` are XP's.

**Decisions:** DU6 (owner, 2026-10-20): the counter is ported now, with UI; it counts from the mod's installation; XP reuses it. The entry's icon (`bestiary_leshen_locked.png`) exists in 5.x (seen on screen).

**Verification (slice 8, 2026-10-21, both trees):** scripted: `GMTest_ui10` (regression): a count added to wolves and unique creatures reads back and shows in the entry's text ("Total: 2; Humanoids: 0; Animals: 1; Monsters: 0; Unique creatures: 1; Kills by type: Wolves: 1"), then taken back. `gmtest_ui10_kill_a/b/c`: a hostile wolf spawned and killed through the game's death path with Geralt as the killer (`Kill`) counts one wolf. Since XP slice X3 (2026-10-31, both trees, 5.x-GM `9ce4fd30`) the counting is XP-04's: `GMTest_ui10` and `gmtest_ui10_kill_a/b/c` pass unchanged (the counting order is all that moved: legacy's, after the experience), and XP-04's checks show each kill counted once, a guard's kill counted as a human's and a kill without experience (an NPC flagged `grantNoExperienceAfterKill`) not counted ([XP-04](xp.md#xp-04-kill-experience)). Real, on screen (the bestiary opened by script, the entry selected with `OnEntrySelected`; screenshot): the "* Kill count" group with its entry, the leshen silhouette and the text "Total: 1, Humanoids: 0, Animals: 1, Monsters: 0, Unique creatures: 0, Kills by type: Wolves: 1".

**Verification (UI audit F8, 2026-10-21, classic tree, 5.x-GM `e58db763`):** the counts survive a save and a load. Scripted kill (`gmtest_ui10_kill_a/b/c`: 0 to 1 wolf), hostiles removed, a manual save into a new slot by script (`gmtest_save()`, `theGame.SaveGame(SGT_Manual, -1)`: `<save name>`; the audit's attempt wrote nothing, probably with a hostile still near), that save loaded (a real load): `GMGetKills(GMENT_WOLF)` reads 1 and the entry's text "Total: 1; Animals: 1; Wolves: 1". The saved field is **verified**.

**Later:** —

### UI-11 Bestiary weaknesses

| | |
|---|---|
| Kind | ui |
| Pillars | P7 |
| 5.x class | conflict (5.x re-saved the files, unchanged content) |
| Flags | — |
| Depends on | ALCH-14, ALCH-15 (Silver Dust and Dimeritium rules, ported) |
| Skill trees | n/a |
| Port form | script: `GMBestiaryItemsUsedAgainst` in `ui/bestiary.ws` changes the journal's list by the creature entry's tag, read by the replaced `CR4GlossaryBestiaryMenu.UpdateItems` (the journals stay 5.x's files) |
| Port status | **signed off** (2026-10-21); **ported** (slice 8, 5.x-GM `a736a02e`), verified in both trees |
| Open checks | the lists on screen (the test save knows none of the eight creatures); 5.x's preparation menu (`preparationMenu.ws`, a tracked creature's list) still reads the journal's list (not used in 5.x's play, unverified) |
| Save impact | none (expected) |
| NG+ counterpart | none |

**What it does:** the bestiary's "used against" lists follow Ghost Mode's bombs: Silver Dust instead of Dimeritium for the leshen, the ancient leshen, the spriggan, the grottore and hunt mh302; Dimeritium added for hunt mh303 and the succubus; Axii and Yrden added for the djinn.

**Implementation (legacy):** `itemsUsedAgainstCreature` in `leshy1`, `sq204ancientleszen`, `bestiarymonsterhuntmh302`, `bestiarymonsterhuntmh303`, `dzinn`, `succubus`, and Blood and Wine's `mq7002grottore`, `mq7002spriggan` journals. The same lists in the creatures' data (12 entity files) are AI's.

**Decisions:** port as legacy (DU7). The lists are changed in script instead of in the eight binary journals: the bestiary is the journals' only reader in play, the result on screen is legacy's, and no binary file has to be shipped or merged (the tags with spaces and dashes are compared as strings: a name literal cannot hold them).

**Verification (slice 8, 2026-10-21, both trees):** scripted (`GMTest_ui11`, regression): the leshen, succubus and djinn entries loaded by their journal aliases (`BestiaryLeshy`, `BestiarySuccubus`, `BestiaryDzinn`, which also checks the tags) give "Silver Dust Bomb 1, Relic Oil 1, Igni", "Hybrid Oil 1, Quen, Dwimeritium Bomb 1" and "Dwimeritium Bomb 1, Magicals Oil 1, Yrden, Axii"; the other five tags with 5.x's lists give legacy's; another creature keeps its list.

**Later:** —

### UI-12 Enemy level on the HUD

| | |
|---|---|
| Kind | ui |
| Pillars | P7, P5 |
| 5.x class | clean |
| Flags | — |
| Depends on | DIFF-05 (fake levels) |
| Skill trees | n/a |
| Port form | `ui/enemyLevel.ws`: `@replaceMethod` of `CNewNPC.GetExperienceDifferenceLevelName` (the deadly branch removed; the fake addon, the NG+ addon and the cap removed by [DIFF-05](diff.md#diff-05-fake-levels), slice D6) |
| Port status | **signed off** (2026-10-21); **ported** (slice 9, 5.x-GM `4a61e025`; the fake levels with DIFF's slice D6, 5.x-GM `523457b1`), verified in both trees |
| Open checks | — |
| Save impact | none |
| NG+ counterpart | none |

**What it does** (changelist 1113): an enemy far above Geralt shows its level in red instead of `???`, from 6 levels above him (`LEVEL_DIFF_HIGH`: 6 since AI's slice A1, the owner's DA4, 2026-10-28; 10 before it, 5.x's value). The number is the enemy's real level, without 5.x's fake addon and its cap at 5 above the maximum level, as legacy ([DIFF-05](diff.md#diff-05-fake-levels), which lists the enemies whose shown level this lowers).

**Decisions:** port as legacy (DU8). The temporary deviation that kept 5.x's fake level addon and its cap until DIFF (porter's call, confirmed by the owner, 2026-10-21) ended with DIFF's slice D6 (2026-10-30): the HUD shows the real level, as legacy. The 71 enemies whose fake level legacy made real (AI-06, since the AI-C audit's F6) carry it as their level, so the sergeant shows 11.

**Verification (slice 9, 2026-10-21, both trees):** scripted (`gmtest_ui12_a/b`): a hostile human 40 levels above Geralt (level 41 against 1) gives "highLevel" and its level in red (`#FF1919`), not "deadlyLevel". Real, on screen (the HUD with the enemy locked on; screenshot): "41" in the level diamond above its health bar, red; 5.x's skull marker above it remains. UI audit slice A (2026-10-21, both trees, level 30): `gmtest_ui12_a/b` pass ("highLevel", level 70 in red); the check is listed with the manual UI checks in `gmTestsUi.ws`.

**Verification (AI slice A1, 2026-10-28, both trees):** scripted (`gmtest_ai01_read`, hostile human dummies): 5 levels above Geralt "normalLevel" (green), 6 levels above "highLevel" (red), 6 below "lowLevel". Real, on screen: a bandit at level 7 against Geralt's 1, locked on, shows its level in red.

**Skull marker** (answered by the owner, 2026-10-21): 1.32 also shows the skull above an enemy's level, so the skull plus the red level is vanilla's and legacy's HUD; nothing to change.

**Verification (DIFF slice D6, 2026-10-30, both trees):** scripted (`gmtest_diff05_*`, `GMTest_diff05`): the five 5.x entities with an addon the mod's files do not clear show their real level and legacy's colour, a hand-set addon and NG+ addon flag are not shown, a level of 120 is not capped ([DIFF-05](diff.md#diff-05-fake-levels)). The level seen on screen with an enemy locked on: **verified** in DIFF's [cleared run](diff.md#cleared-run-on-screen-2026-11-01) (2026-11-01, a level-1 wolf shows 1).

**Later:** —

### UI-13 Loading screen tips and tutorials

| | |
|---|---|
| Kind | ui |
| Pillars | P7 |
| 5.x class | clean |
| Flags | — |
| Depends on | the rules they describe (STAM, DEF, DMG, SKL-06, ITEM-12, ARM-05) |
| Skill trees | n/a |
| Port form | string overrides: the tips by key hash in `modGhostMode` (2110992520–528, 9 languages), the tutorials by vanilla id in a `modGMTutorials` table (legacy's, 6 languages) |
| Port status | **signed off** (2026-10-21); **ported** (slice 9, 5.x-GM `4a61e025`), verified in both trees |
| Open checks | a tip on a loading screen and a tutorial popup on screen (the texts read by script only); how legacy's input placeholders (`<<AttackLight>>`, `<<AttackHeavy>>`, gamepad-only actions on PC in 1.32 and 5.x) show with a keyboard |
| Save impact | none |
| NG+ counterpart | none |

**What it does** (changelist 1168): nine loading screen tips (enemy stamina, level colours, grindstones, mounted attacks, attacks from behind, aiming, deflecting arrows, Quen against critical effects, dodging or parrying by enemy size) and sixteen tutorials (parry, counter, fast and strong attacks, dodge, roll, bombs, signs with cooldowns, crossbow, stamina, grindstones and armorer's tables, oils, adrenaline, witcher sets) describe Ghost Mode's rules.

**Implementation (legacy):** strings 2110992520–528 (by key hash) in nine languages; `modGMTutorials` rows by vanilla id in six languages (Brazilian Portuguese, German, English, Spanish, Polish, Russian).

**Decisions:** DU9 (owner, 2026-10-20): legacy's tips and tutorials; languages legacy lacks keep 5.x's. The 5.x texts were compared before being overridden (English): the fast and strong attack tutorials (1075370, 1075376) describe the alternative input scheme (`<<AttackWithAlternateLight>>`, the "Modify Attack Type" key) and the sign tutorial (1075722) the sign selection keys. These are 1.32's texts too (1.32's `patch1` string table; 5.x's equal them), so legacy's tutorials already replaced them in 1.32: losing those notes is legacy's behaviour, not a deviation (UI audit F2). The input placeholders of legacy's texts (`<<AttackLight>>`, `<<AttackHeavy>>`) are bound to the gamepad only, on PC, in 1.32 and 5.x alike (`input_qwerty.ini`). Legacy's Brazilian and Russian tutorial tables declared English in their header; the port's say `br` and `ru` (the build reads the header).
- **Deviation:** the Brazilian and Russian tutorial tables declare their own language (legacy's declared English, so whether legacy's players saw them is unknown; [to test in legacy](../open-questions.md#to-test-in-legacy-ghost-mode)) (porter's call, confirmed by the owner, 2026-10-21; recorded by the UI audit, F3).

**Verification (slice 9, 2026-10-21, both trees):** scripted (`GMTest_ui13`, regression): the English fast attack tutorial is legacy's ("press <<AttackLight>> ... armor"); the tip rows 2110992520 and 528 read legacy's texts.

**Later:** —

### UI-14 Skill icon

| | |
|---|---|
| Kind | ui |
| Pillars | P7 |
| 5.x class | conflict (texture cache format) |
| Flags | — |
| Depends on | SKL-05 (Deflection) |
| Skill trees | classic `sword_s10` (the new tree's Deflection `sword_s33` has 5.x's icon) |
| Port form | a texture cache for 5.x cooked by `wcc_lite` (unverified) |
| Port status | **signed off** (2026-10-21); **not ported** (Q1, 2026-10-21) |
| Open checks | — |
| Save impact | none |
| NG+ counterpart | none |

**What it does:** legacy's `content/texture.cache` holds one image, `gameplay\gui_new\icons\skills\sword\sword_s10.png`, replacing Deflection's icon for its reworked role (parried hits, not only arrows). Whether 5.x reads a mod's 1.32-format texture cache is unknown.

**Decisions:** Q1 (owner, 2026-10-20): keep 5.x's Deflection icon; legacy's texture cache is not ported.
- **Deviation:** the classic Deflection (`sword_s10`) keeps 5.x's arrow icon; legacy replaced it for the skill's reworked role (the owner's Q1, 2026-10-20).

**Later:** —

### UI-15 Shaving from the inventory

| | |
|---|---|
| Kind | ui |
| Pillars | P8 |
| 5.x class | clean |
| Flags | — |
| Depends on | CRAFT (the inventory's primary action is shared with dismantling) |
| Skill trees | n/a |
| Port form | `ui/shaving.ws`: wrappers of `W3InventoryGridContext.updateInputFeedback` and `execurePrimaryAction`, `@addMethod CR4InventoryMenu.GMUpdateFace`; the razor given whole with its description key (`gm_ui.xml` in the DLC's `items` and `items_plus`); 2 strings in 9 languages (2110992169, 173) |
| Port status | **signed off** (2026-10-21); **ported** (slice 9, 5.x-GM `4a61e025`), verified in both trees |
| Open checks | the E key on the razor (a real double-click used it; a scripted E press with `send_key.ps1` did nothing) |
| Save impact | none |
| NG+ counterpart | applied (the item's description key) |

**What it does** (changelist 866): the razor gets a "Use" input in the inventory; using it shaves Geralt (vanilla's `ShaveGeralt_Quest`), refreshes the paperdoll and says "Geralt is now clean-shaven". Its description reads "Used for shaving.".

**Implementation (legacy):** `W3InventoryGridContext.updateInputFeedback`, `execurePrimaryAction`, `CR4InventoryMenu.UpdateFace`; item `Razor` (`item_desc_razor_mod`; its price, weight and parts are ECON's, WGT's and CRAFT's); strings 2110992169, 173.

**Decisions:** port as legacy (DU10).

**Verification (slice 9, 2026-10-21, both trees):** scripted: `GMTest_ui15` (regression): the razor's description key reads "Used for shaving."; `gmtest_ui15_a/b/c`: with the beard grown (head_4), the razor's action with the inventory open shaves Geralt (head_0) and shows "Geralt is now clean-shaven". Real, on screen (classic tree; screenshots): the razor's tooltip "Used for shaving." with "E Use" in the input bar; a real double-click on the razor shaved Geralt (head_4 to head_0).

**Later:** —

### UI-16 Debug labels

| | |
|---|---|
| Kind | infra |
| Pillars | — |
| 5.x class | clean |
| Flags | — |
| Depends on | — |
| Skill trees | n/a |
| Port form | none (DU11) |
| Port status | **signed off** (2026-10-21); **dropped** (DU11, slice 10, 2026-10-21) |
| Open checks | — |
| Save impact | none |
| NG+ counterpart | none |

**What it does:** `toggledebuglabels` (a fact) makes the quest journal show quest and objective tags, map pins their tags (and every pin as a fast-travel point), the bestiary the creature's string id, and item tooltips the item's name, tags and abilities.

**Implementation (legacy):** `toggledebuglabels`; hunks in `CR4MapMenu.UpdateEntityPins`, `AddPinTypeData`, `CR4JournalQuestMenu.generateFlashObjectForQuest`, `UpdateObjectives`, `CR4GlossaryBestiaryMenu.PopulateData`, `W3TooltipComponent.GetBaseItemData`.

**Decisions:** DU11 (owner, 2026-10-20): dropped; the port's tests read tags by script.
- **Deviation:** legacy's debug labels (`toggledebuglabels`: tags in the quest journal, map pins, bestiary and item tooltips) are not ported (the owner's DU11, 2026-10-20).

**Later:** —

### UI-17 Unused leftovers

| | |
|---|---|
| Kind | infra |
| Pillars | — |
| 5.x class | obsolete |
| Flags | — |
| Depends on | — |
| Skill trees | n/a |
| Port form | none |
| Port status | **signed off** (2026-10-21); **dropped** (DU12, slice 10, 2026-10-21) |
| Open checks | — |
| Save impact | none |
| NG+ counterpart | none |

**What it does:** nothing in legacy: a stash mode that was never wired (`CInventoryComponent.TransferStashItemsTo`, `TransferStashItemsFrom`, `CanTransferItem`, `IsItemTempTransferred`, no caller; strings 2110992182, 184–187, 261, 312) and the strings of two commented-out panel lines (chance to keep balance when hit, 2110992264; attack power from levels, 2110992324).

**Decisions:** DU12 (owner, 2026-10-20): dropped. They change nothing in play (no caller, no shown line), so dropping them is no deviation; likewise legacy's two strings of commented-out sign lines (2110992021, 027, UI-03).

**Later:** —

### UI audit (2026-10-21)

Done by a fresh session ([audit](../feature-mapping.md#audit-signing-a-feature-off)) on 5.x-GM `4a61e025` and master `84c1f4b4`. Every script unit [attribution.csv](attribution.csv) gives UI (`gm/ui/*.ws`, UI's hunks in `alchemy/tooltips.ws` and `mutations/hudCounters.ws`) was read against legacy's code (`legacy-GM`: `CharacterStatsPopup.ws`, `GetOffenseStatsList`, `guiTooltipComponent.ws`, `guiBaseInventoryComponent.ws`, `glossaryBestiaryMenu.ws`, `npc.ws`, `merchantComponent.ws`, `inventoryContext.ws`, `inventoryMenu.ws`, `characterMenu.ws`), 1.32 and 5.x, and the changelist (1113, 1154–1174, 866, the bugfix lines). An independent script compared all 900 UI string rows of the nine `modGhostMode` tables and the six `modGMTutorials` tables with legacy's (id, key hash, key, text), and legacy's 55 changed `tooltip_settings.csv` rows with what the game reads. The 16 overridden tutorials were compared with 1.32's and 5.x's English texts decoded from both games' string tables (`w3strings.py`, 1.32's `content0` to `patch1`). In game (both trees, a build of `4a61e025` plus a temporary probe, not committed): the regression on a fresh load of the test save (763 passed, 0 failed in each tree, the panel checks after it passing), real Quen, Yrden and Axii casts by input simulation against the panel's lines, the panel's crit chance against the hit's for the drawn sword, `gmtest_ui01_hits` (new tree) and a scripted wolf kill.

**Checked and holding:** the offense list is legacy's term by term apart from the three recorded deviations (Thunderbolt 3, the capped weighting, the bolt from the item) and DU1's tree mapping; the classic Muscle Memory and Strength Training reach it through the attack's tagged abilities, as the hit (SKL's single count); the sheathed sword's bonuses and the drawn other sword's subtraction are legacy's. The panel's attack power and damage equal scripted hits (slice 3, and again in the new tree); its crit chance equals the hit's `GetCriticalHitChance` for the drawn sword in both trees (classic Precise and Crushing Blows 5: 14.99 % fast and strong; new tree `sword_s24`, `sword_s25` 3: 13 %). The sword, crossbow, toxicity, Vitality, sign power and misc sections are legacy's line for line (labels, order, formats, the instant kill maximum, Metamorphosis' factor, Crippling Strikes and Cold Blood of either tree); the toxicity decay reads only additive values in the data, so the port's "as the effect gets it" and legacy's additive part agree. The sign lines are legacy's apart from the recorded UI-03 deviation, and real casts agree with them in both trees (Quen 484 and 30 s, the shield 483.5 and 30 s; Yrden 15.0 s, 3.5, two traps, the trap 14.99 s, 3.5, two; Axii 9.1 s, the effect 9.06 s). Tooltips, recipe and schematic texts, the oil tooltip and line, the comparisons, the kill count text and counting place (5.x's caller of `CalculateExperiencePoints` is 1.32's), the bestiary lists, the enemy level, Yolar's pin (`GetScriptInfo` gives the map its pin type) and the razor are legacy's apart from recorded deviations. All 900 UI string rows equal legacy's in all nine tables (text, key hash, key); only 2110992021 and 027 are missing, legacy's commented-out lines (UI-03); the dropped UI-17 rows are absent; the tutorial rows equal legacy's in six languages. The 55 tooltip rows legacy changed read as legacy's. No deviation recorded "until UI" is left in [deviations.md](deviations.md). `check_modsigns.py` 0 unmarked (391 bodies); `deviations.py --check` current (after this audit's edits, regenerated); `gen_npc_stamina`, `gen_arm_km`, `gen_arm_new`, `gen_ngplus`, `gen_ench`, `gen_alch`, `gen_arm_items`, `gen_swd_items`, `gen_item` `--check` current; `gen_ench`, `gen_alch`, `gen_arm_items`, `gen_swd_items`, `gen_item` `--verify` no unexplained difference. `unit_sweep.py --unattributed` (tooltip, popup, GetLocString, flash, hud): no unattributed UI unit apart from F1; the rest are DEP's menu units, OPT's, WGT's boat message and the Community Patch's time-lapse tests, as mapped.

**Findings:**

1. **The kill counter's increment had no attribution** (doc correction, made). `CNewNPC.CalculateExperiencePoints` (legacy `npc.ws:2464`, `IncKills` at 2476 and 2506) is wrapped by UI-10 (`ui/bestiary.ws:509`) but had no row in [attribution.csv](attribution.csv) (`unit_sweep.py flash --unattributed` lists it). Added with UI-10 (XP's part noted); [units.csv](units.csv) and [coverage.md](coverage.md) regenerated.
2. **The "Modify Attack Type" notes legacy's tutorials replace are 1.32's, not 5.x's** (doc correction, made; settles the porter's call on them). 1.32's `patch1` string table already holds 1075370, 1075376 and 1075722 with `<<AttackWithAlternateLight>>`, the Modify Attack Type key and the sign selection keys, word for word as 5.x; legacy's `modGMTutorials` (`en.csv` rows 1075370, 1075376, 1075722) replaced them in 1.32. The port does what legacy did: no deviation. The placeholders `<<AttackLight>>` and `<<AttackHeavy>>` are gamepad-only actions on PC in both games (`bin/config/r4game/legacy/base/input_qwerty.ini`), a gap legacy had. UI-13's decision and open checks corrected.
3. **The Brazilian and Russian tutorial headers were not recorded as a deviation** (doc correction, made; owner decision). Legacy's `modGMTutorials/br.csv` and `ru.csv` start `;meta[language=en]`; the port's say `br` and `ru` (UI-13). How legacy's tables reached its players is unknown (no built legacy mod is kept). Recorded as a deviation (porter's call) and added to [to test in legacy](../open-questions.md#to-test-in-legacy-ghost-mode). Options: (a) keep the port's headers (the tables load in their language); (b) legacy's headers. Recommendation: (a). **Decided** by the owner (2026-10-21): (a), the deviation confirmed.
4. **The UI-03 deviation left out Exploding Shield's `spell_dmg_bonus`** (doc correction, made; part of the owner's call on the sign lines). The port's line adds it (`ui/signStats.ws:215` through `GMPanelSignDamage`), as the damage pool does for sign actions (`damage/pool.ws:334-335`); legacy's line did not (`CharacterStatsPopup.ws`, `quen_discharge_pts`). Only the NG+ school swords carry it. Added to the deviation's text.
5. **The UI-12 deviation left out the New Game+ level addon** (doc correction, made). The port keeps `newGamePlusFakeLevelAddon` (`ui/enemyLevel.ws:13-16`); legacy dropped it with the other fake levels (legacy `npc.ws`, `GetExperienceDifferenceLevelName`). Added to the deviation's text; DIFF's.
6. **Stale texts** (doc corrections, made). UI-01's "crit damage (Cat Eyes' crit boost)": legacy's list reads `Mutation9`'s `critical_damage`, which legacy's data comments out (`dlc/bob/.../geralt_mutations.xml:66`), so it adds 0, as the port. The classification table's "Binary edits with `cr2w_patch.py` (DU7)": UI-11 changes the lists in script. UI-03's and UI-01's open checks updated with this audit's casts and crit check.
7. **Legacy's name fallback in `AddCharacterStat` and `AddCharacterStatF` is not ported** (no action). Legacy shows a line's key when its label has no string; the port has the fallback in `AddCharacterHeader`, `AddCharacterStatU` and `AddCharacterStatSigns` only (`ui/characterStatsPopup.ws:435`, `:596`; `ui/signStats.ws:310`). Every label those two functions get has a string, so nothing differs on screen. Noted in UI-05's port form.
8. **The kill counts across a save and a load are not verified** (clear fix: a check). `gmEnemiesKilledByType` is a saved `@addField` on Geralt (`ui/bestiary.ws:488-489`), the port's first player-level saved field whose loss the player sees; slice 8 checked the count in one session only. The audit's scripted `theGame.SaveGame(SGT_Manual, -1)` wrote no save. Fix: kill a wolf on the test save, save into a new manual slot (never over a save of the owner's), load it, read `GMGetKills(GMENT_WOLF)`; the test save itself stays untouched. **Resolved** (2026-10-21, slice A, classic tree, 5.x-GM `e58db763`): a wolf killed by script, saved by script into the new slot `<save name>` with no hostile near, that save loaded: the count reads 1 ([UI-10](#ui-10-bestiary-kill-count)'s verification).
9. **Regression gaps** (clear fix). Nothing in `gmtest_regress()`/`gmtest_panel()` compares the panel with the mechanics it describes: the crit chance with `GetCriticalHitChance` (this audit's probe), the sign lines with the cast entities (Quen's `initialShieldHealth` and `shieldDuration`, Yrden's `trapDuration`, `baseModeRange`, `gmMaxCount`, Axii's confusion duration), or the enemy level's name (`gmtest_ui12_a/b` are manual). Fix: the crit check in `gmtest_panel()` (situation-free, draw the sword in an earlier call or compare with the sheathed sword's item crit added), a `gmtest_ui03_casts` exec test (casts by `autocast`, entity readers in `tests/`), UI-12's check in the manual UI tests list. **Resolved** (2026-10-21, slice A, 5.x-GM `e58db763`, verified in both trees): `GMTest_ui01_crit` in `gmtest_panel()` (each sword, drawn or sheathed); `gmtest_ui03_cast(sign)` and `gmtest_ui03_casts(sign)` with the readers `GMTestQuenValues`, `GMTestYrdenValues` (casts by input simulation, each sign checked before the next cast); the manual UI checks, UI-12's among them, listed in `gmTestsUi.ws`'s header.
10. **Kills of enemies without a type count in no total** (no action; Later). `GMGetEnemyTypeByAbility` returns `GMENT_GENERIC` or `GMENT_ANIMAL` for creatures it does not know; `GMKillCountText` (`ui/bestiary.ws:523`) sums from `GMENT_HUMAN` up, so those kills show nowhere, not even in "Total". Legacy's (`glossaryBestiaryMenu.ws`, `UpdateKillCountEntry`, same loop). Possible improvement after the first version.
11. **The sign lines follow the port's cast** (owner decision; the porter's call 1). Per item, against legacy's own cast (`yrdenEntity.ws:140-215`, `damageManagerProcessor.ws:2646-2661`): the second trap at Sustained Glyphs 3 is legacy's cast (legacy's panel said level 2: a panel bug); Petri's Philtre 3's ×1.34 on Quen's and Yrden's durations is legacy's cast (`yrdenEntity.ws:210`), which legacy's panel did not show; Axii's instant-kill chance is rounded to a whole percent by legacy's own roll (`chance : int`, `RoundMath`); the knockdown clamp, the slowdown clamp and Exploding Shield's terms (F4) follow the port's cast. Yrden's range is the one real difference in the cast itself: legacy's cast added Sustained Glyphs' +30 % and the Griffin set's bonus into one multiplier and then scaled the trigger again by the Griffin scale; the port multiplies them (the trap scales by both). Options: (a) confirm (the panel shows what the cast does); (b) legacy's panel formulas. Recommendation: (a). **Decided** by the owner (2026-10-21): (a), UI-03's deviation confirmed.
12. **The Vitality regen lines ignore legacy's regen options** (owner decision; the porter's call 2). The regen in play has no options either (OPT not ported); the line equals the regen. Recommendation: confirm, temporary until OPT. **Decided** by the owner (2026-10-21): confirmed, temporary until OPT.
13. **The enemy level keeps 5.x's fake addon, the NG+ addon and the cap** (owner decision; the porter's call 3). They belong to DIFF's fake levels; with them, the displayed level is the level the enemy's stats use in 5.x. Recommendation: confirm, temporary until DIFF. Related question (no recommendation): slice 9's screenshot shows 5.x's skull marker above the red level of an enemy 40 levels up; whether 1.32's HUD showed one for `highLevel` is unknown (the marker is Flash's, not script). **Decided** by the owner (2026-10-21): confirmed, temporary until DIFF; the question answered: 1.32 also shows the skull above the level, so the HUD is vanilla's and legacy's.
14. **Earlier porter's calls in the panel and texts** (owner decision): Thunderbolt 3 counted as crit chance (legacy's hit does so too, legacy `playerWitcher.ws:2586-2590`; its panel comment says "crit chance" but adds to crit power), the expected hit with the crit chance capped at 100 %, the bolt damage from the equipped bolt (its level's values, as the hit), the extended recipe texts naming every effect, and STAM-04's out-of-combat stamina regen line without the armor modifier (the effect applies it in combat only). Each makes the screen agree with play. Recommendation: confirm all five. **Decided** by the owner (2026-10-21): all five confirmed (STAM-04's in [stam.md](stam.md)).
15. **Yolar's map pin is compiles-only** (no action; open check). The wrapper (`ui/mapPins.ws`) changes the value `GetScriptInfo` hands the map; the test save has no Yolar.

**Doc corrections made with the audit:** F1 ([attribution.csv](attribution.csv), [units.csv](units.csv), [coverage.md](coverage.md)), F2 (UI-13's decisions and open checks), F3 (UI-13's deviation, [open-questions.md](../open-questions.md#to-test-in-legacy-ghost-mode)), F4 (UI-03's deviation), F5 (UI-12's deviation), F6 (UI-01's text and open checks, UI-03's open checks and verification, the classification table), F7 (UI-05's port form), F8 (UI-10's open checks); [deviations.md](deviations.md) regenerated; the [status page](README.md#where-the-port-stands).

**Not reviewed:** the character menu's own stats popup and the new menu's summary line on screen (the inventory's stats view is built by the same function; an attempt to open it for screenshots by key presses opened the hub's last tab instead, so this audit took no screenshots); the strings on screen in languages other than English; Aard's and Igni's chances and every damage line against real casts (scripted reads only); a tutorial popup and a loading screen tip on screen; NG+ (the policy: not tested).

**Suggested fix slices** (each touching distinct files):

- **A, tests** (`gm/tests/gmTestsUi.ws`, the regression list in `gm/tests/gmTests.ws`): F9's crit check in `gmtest_panel()`, `gmtest_ui03_casts` with the entity readers, UI-12 in the manual checks; F8's save and load check, run by hand once (a new manual save, the owner's saves untouched). No mod code changes. **Done** (5.x-GM `e58db763`, 2026-10-21).
- **Owner decisions:** F3, F11 to F14 (and F13's question). **Made** 2026-10-21.

#### Audit close-out

Closed 2026-10-21: every finding is fixed, recorded or decided by the owner. Fixed and verified in both trees: F8 and F9 (fix slice A, 5.x-GM `e58db763`, tests only: the panel's crit chance against the hit's for each sword, drawn or sheathed; Quen, Yrden and Axii cast by input simulation against the panel's lines; the kill counts across a save into a new slot and its load, classic tree). Recorded: F1 to F7 (doc corrections made with the audit), F10 and F15 (no action; F15 stays UI-09's open check). Decided by the owner (2026-10-21): F3 (the Brazilian and Russian tutorial headers relabelled), F11 (the sign lines follow the port's cast), F12 (the Vitality regen lines without the regen options, temporary until OPT; ended by OPT's slice O1, 2026-11-02), F13 (the enemy level keeps 5.x's fake addon, the NG+ addon and the cap, temporary until DIFF; the skull marker above the red level is 1.32's HUD too), F14 (Thunderbolt 3 as crit chance, the expected hit's capped crit chance, the bolt damage from the equipped bolt, the extended recipe texts, STAM-04's out-of-combat regen line), each deviation marked confirmed. Checks at close: regression 763 passed, 0 failed in each tree (plus `gmtest_panel()`'s checks, the crit check among them); `check_modsigns.py` 0 unmarked (391 bodies); `deviations.py --check` current; no UI deviation left unconfirmed (`python tools/deviations.py --unconfirmed`). No owner decision is left open. What stays open after the sign-off: the open checks listed in the entries (among them a real fight's hits, the character menu's stats popup on screen, Aard's and Igni's lines against real casts, a guard's kill, a tutorial popup and a loading screen tip on screen, Yolar's pin, NG+). UI is **signed off** by the project owner (2026-10-21).

### Dependencies on other areas

- **Done areas UI builds on:** DMG (the formula behind UI-01), STAM (`ui/characterStatsPopup.ws` with the stamina lines, STAM-05's option), SKL (every skill of both trees, the descriptions already ported), MUT, ARM, ENCH, SWD, ITEM (`GMGetEnhancedBuffInfo`), ALCH (the tooltip wrappers in `alchemy/tooltips.ws`, ALCH-01's threshold).
- **Areas UI waits for or shares with:** XP (the kill counter, UI-10), OPT (the vitality regen options, UI-05; ported by OPT's slice O1, 2026-11-02), DIFF (fake levels, UI-12), CRAFT (ingredients, dismantling, UI-08, UI-15), XBOW (bolt values, UI-01, UI-07), TRPH (trophy stats, UI-06, UI-07), AI (the creatures' weakness lists, UI-11).

### Hand-offs received

Every item other areas handed to UI, and where it lands:

| From | Item | UI |
|---|---|---|
| DMG (hand-off) | The damage shown in the panel and tooltips (`SPlayerOffenseStats`, `GetOffenseStatsList`, the sword sections) | UI-01, UI-02 |
| DEF (hand-off) | Skill descriptions reading the partial-parry constant | Ended: SKL-19 ported them (`skills/skillDescriptions.ws`, `S_Sword_3`) |
| STAM-05 deviation (until those rows) | The `staminaRegen_armor_mod` tooltip row | UI-07 (ended) |
| SKL (audit F34) | The popup's skill lines, `gm_sign_stats_*`, `gm_combat_stats_*` | UI-02, UI-03, UI-05 |
| SKL-06 deviation (until UI; not confirmed by the owner) | Steady Shot's +50 in the panel's crossbow damage | UI-01 (ends it) |
| SKL-14 (open checks) | The panel's oil lines; the HUD's oil charges and the oil tooltip with the new tree's Fixative | UI-01; UI-06 |
| MUT-07, MUT-08, MUT-09, MUT-11, MUT-12, MUT-13 deviations (until UI) | Adrenaline Rush lines; Toxic Blood's decay; Euphoria's lines; Cat Eyes' crossbow damage; Life Leech's average attack power; Metamorphosis' chance lines | UI-05 and UI-01; UI-04; UI-01, UI-03, UI-04; UI-01; UI-01; UI-02, UI-03 (end them) |
| ARM-04, ARM-06, ARM-08, ARM-09 deviations (until UI) | Medium set decay line; Feline and Bear attack power; the oil tooltip's Wolven boost | UI-04; UI-01; UI-01; UI-06 (end them) |
| ARM (hand-off) | Yrden's range with the Griffin set | UI-03 |
| ENCH (hand-off) | `addComponentsInfo`'s recipe part; Vitality regen names; Placation, Rotation, Retribution lines; Heft's damage | UI-08; UI-07; UI-04, UI-03; UI-01 |
| SWD-07 deviation (until UI) | `sword_dmg_bonus` and `spell_dmg_bonus` in the panel | UI-01, UI-02, UI-03 (ends it) |
| SWD (hand-off) | Sword sections, instant kill as the maximum | UI-02 |
| ITEM (hand-off) | Recipe and schematic layout; the tooltip and panel beyond ITEM-12's line | UI-08 (ended); UI-06 |
| ALCH-10, ALCH-11 deviations (until UI) | Water Hag lines removed; Foglet's and Wraith's lines | UI-01, UI-02; UI-03 (end them) |
| ALCH-16, ALCH-17 deviations (until UI) | The sword's oil line; the potion toxicity line; the recipe book and recipe tooltip | UI-06; UI-06; UI-08 (end them) |
| ALCH (hand-off) | Buying ingredients in the alchemy menu; the toxicity panel lines; the oil tooltip; `GetRecipeDataFromXML`; `GetBaseItemData`'s Gwent and armor and weapon hunks; the name-key descriptions of books, keys and quest items | UI-09; UI-04; UI-06; UI-08; UI-06; UI-06 (open check) |

All 17 deviations recorded "until UI" and STAM-05's row land in a UI feature (list in [port order](#port-order)); none is handed on.

### Hand-off to other areas

| Area | Changes |
|---|---|
| OPT | `CR4IngameMenu`'s Ghost Mode units, the option strings (ported with OPT, 2026-11-02, but those of `GMVersion`, the "Mods" label and instant casting, by OPT's PO2 and DO5; at the hand-off: 002–009, 016, 180, 181, 183, 250–255, 270, 271, 300, 314, 327, 328, 393, 394, 432, 447–453, 459, 495–498; the ported ones are now attributed to OPT-01)) |
| DEP | The Community Patch – Base menu units listed in [Scope](#scope) |
| XP | `CalculateExperiencePoints` (where the kill counter is incremented), `GetExpByEnemyType`, `GetExpModifierByEnemyType`; UI-10's counter and `GetEnemyTypeByAbility` are shared |
| DIFF | The displayed level's fake addon and cap in `GetExperienceDifferenceLevelName` |
| FIX | `CR4InventoryMenu.OnConfigUI` (`FixQuestItems`), `CR4ScriptedHud.OnQuestUpdate` (`FamilyIssuesAutosave`) |
| CRAFT | Dismantling (`PlayerDismantleItem`, the dismantle inputs in `inventoryContext.ws`, strings 2110992257, 258, 260, 330–334), the crafting components' rarity colours (bugfix 120: item data), the razor's parts |
| ECON | `OpenMonsterHuntNegotiationPopup`, the razor's price |
| WGT | `W3Boat.OnAreaEnter` and its message (2110992179), the razor's weight |
| FOOD | `attribute_name_staminaRestore` (2110992352; unused by legacy, dropped: [food.md](food.md) FOOD-08) |
| AI | The creatures' weakness lists (`itemsUsedAgainstCreature` in 12 entity files), the caretaker's spade text (2110992475) |
| ARM | `arrowProjectile.ws`'s fix for Yoana's arrow bounce (the row is UI-07's) |

### Save impact

None expected: the panel, tooltips and texts are built when shown. UI-10 adds a saved kill array to Geralt; kills count from the mod's installation. Adding or removing the mod mid-playthrough is not supported ([save compatibility](../feature-mapping.md#save-compatibility)); removing it drops the kill counts (a fact, unsupported).

### Area decisions

Made by the project owner (2026-10-20):

| # | Question | Decision |
|---|---|---|
| DU1 | The panel's numbers (UI-01 to UI-05) | Legacy's damage-per-hit lists and values in both trees, each skill read from either tree; 5.x's terms for replaced slots dropped |
| DU2 | The boundary | As mapped in [Scope](#scope); OPT keeps the options menu |
| DU3 | The armor regen modifier line (option on) | Under Armor, as legacy (moved from STAM-05's stamina section) |
| DU4 | Armor and weapon descriptions in tooltips (UI-06) | Legacy's: the item description with the class texts' stamina rule |
| DU5 | Recipe and schematic texts (UI-08) | Legacy's layout, have/need counts, no random-attribute or weight lines |
| DU6 | The kill counter (UI-10) | Ported now; it counts from the mod's installation |
| DU7 | Bestiary weaknesses (UI-11) | Legacy's lists |
| DU8 | Enemy level (UI-12) | Enemies far above Geralt show their level in red |
| DU9 | Tips and tutorials (UI-13) | Legacy's texts; languages legacy lacks keep 5.x's |
| DU10 | Shaving (UI-15) | Ported |
| DU11 | Debug labels (UI-16) | Dropped |
| DU12 | Unused leftovers (UI-17) | Dropped |
| Q1 | Deflection's icon (UI-14) | 5.x's icon kept; legacy's texture cache not ported |
| Q2 | Who sells ingredients in the alchemy menu (UI-09) | 5.x's: any merchant who opened the menu (the owner reports it if it plays wrong); legacy's herbalist gate not ported; Yolar's map pin ported if separate and clean |
| Q3 | The sign sections (UI-03) | 5.x's character menu and popup used however is easiest, as long as all of legacy's information is shown; one combined sign section is fine; the result shown with a screenshot |

### Port order

Proposed; each slice compiles and is verified on its own, in both trees where skills are read (scripted reads of the flash objects as ALCH-17 did, plus the owner's look at the screens):

| # | Slice | Ends |
|---|---|---|
| 1 | UI-07 tooltip rows and names; UI-06 tooltips (descriptions, negative values, comparisons, toxicity line, oil tooltip and Fixative of both trees) | STAM-05's row; ALCH-16's, ARM-09's and ALCH-17's toxicity deviations; SKL-14's open check; ENCH's names and ALCH's `GetBaseItemData` hand-offs |
| 2 | UI-08 recipe and schematic texts | ALCH-17's recipe deviation; ENCH-17's and ITEM's hand-offs |
| 3 | UI-01 the offense list | SKL-06, MUT-11, MUT-12, ARM-06, ARM-08 deviations; DMG's and ENCH's Heft hand-offs |
| 4 | UI-02 sword and crossbow sections, both menus' summaries | ALCH-10's deviation (with slice 3); SWD's hand-off |
| 5 | UI-03 signs | ALCH-11's, MUT-13's (with slice 4) and SWD-07's (with slices 3, 4) deviations; SKL F34, ARM and ENCH hand-offs |
| 6 | UI-04 toxicity | ARM-04's, MUT-08's and MUT-09's (with slices 3, 5) deviations; ALCH's and ENCH's hand-offs |
| 7 | UI-05 other lines | MUT-07's deviation |
| 8 | UI-10 kill count, UI-11 weaknesses | — |
| 9 | UI-12 enemy level, UI-13 tips and tutorials, UI-15 shaving, UI-09 Yolar's pin, UI-14 if decided | ALCH's buying hand-off |
| 10 | UI-16, UI-17 as decided (deviations recorded) | — |
