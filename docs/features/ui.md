# UI: character panel, tooltips, recipe texts, bestiary, HUD and menus

What the player reads: the character stats panel (the popup opened from the character menu and the inventory, and the summary lines beside the paperdoll), item tooltips, the recipe and schematic texts, the bestiary, the enemy level on the HUD, loading screen tips and tutorials, and the few menus legacy changed. Ghost Mode reworked the panel so its numbers follow Ghost Mode's own formula ("Character stats menu was altered to show detailed sign infos ... Sword stats now show average damage per hit and not theoretical damage per second. Attack power and critical hit power stats were added to sword damage sections. Adrenaline gain stat was added ... More stats were added for Toxicity section", changelist 1154–1170), fixed tooltips that hid or garbled information (bugfixes 87–92, 104, 132, 169), added a kill count to the bestiary and restructured the recipe and schematic texts. Sources: the changelist's UI section (1154–1174), the bugfix list (lines 39–42, 87–92, 104–106, 120, 122, 130–132, 169–170), the Other items section (shaving, 866), and the code, which has more than the changelist (the oil tooltip, the enemy level display, the alchemy menu's ingredient buying, the debug labels).

UI shows the numbers other areas ported; it changes no rule. Most entries are therefore displays of features ported in other areas (SKL, MUT, ARM, ENCH, SWD, ITEM, ALCH, DMG, STAM), and they ended all 17 temporary deviations those areas recorded "until UI", and STAM-05's tooltip row.

**What 5.x did in this area** (from `vanilla-5.x`, unverified in game). 5.x added a new character menu (`characterMenuDupe.ws`) for its new skill tree; the port draws both trees in it (SKL-02), and it opens the same stats popup as the classic menu and the inventory (`CharacterStatsPopupData` → `GetPlayerStatsGFxData`). The popup itself is 1.32's except the sign lines (`AddCharacterStatSigns`: 5.x's new-tree Shock Wave, Conjunction `perk_37`, Melt Armor's burn chance, a logarithmic burn chance). `GetOffenseStatsList` is 1.32's damage-per-second model with 5.x's new-tree perk terms (`perk_23`, `perk_25`, `perk_27`) and Heightened Tolerance's crit damage; 5.x's allied-NPC damage block reads it (switched off in the port by DMG-12). Tooltips: 5.x rewrote `GetBaseItemData` (5.x's unique sword descriptions) and kept 1.32's recipe tooltip typo (`'alchemy_recipies'`, so recipe items show no crafted item) and the "random attributes" lines on crafting texts. The alchemy menu buys missing ingredients from the NPC who opened it (5.x adopted the community code legacy used). Bestiary, tips, enemy level (still `???` for deadly enemies) and the recipe book are 1.32's.

**How legacy Ghost Mode implements it.** Scripts only, fed into the vanilla Flash panels: `CharacterStatsPopup.ws` (the popup), `W3PlayerWitcher.GetOffenseStatsList` and `SPlayerOffenseStats` (the numbers), `guiTooltipComponent.ws` (item tooltips), `guiBaseInventoryComponent.ws` (recipe and schematic texts), `alchemyMenu.ws`, `glossaryBestiaryMenu.ws`, `npc.ws` (enemy level); data: rows of `tooltip_settings.csv`, about 90 strings in 9 languages (panel labels, attribute names, kill count, loading screen tips), 16 tutorial texts in 6 languages (`modGMTutorials`), 8 bestiary journals (binary), and `content/texture.cache` (one skill icon). **No Flash (SWF/redswf) file was shipped**: every legacy UI change is a script or data change, so nothing binary in the UI layer has to be carried apart from the icon (UI-14) and the journals (UI-11).

Unit lists: [attribution.csv](attribution.csv). 901 units carry a UI feature (59 script units plus `CNewNPC.CalculateExperiencePoints`'s kill counting, the razor's item and its NG+ copy, 5 tooltip rows, 8 binary journals, 1 texture cache, 825 string rows: 729 in the nine `modGhostMode` tables and 96 tutorial rows); 18 of the script units are shared with features of other areas (UI adds its lines).

**Status:** signed off by the owner (2026-10-21), UI-01 to UI-17: UI-01 to UI-13 and UI-15 ported and verified in both trees (UI-09's buying kept as 5.x's, Yolar's pin ported), UI-14, UI-16 and UI-17 not ported as decided. Not checked beyond the entries' open checks: the strings on screen in languages other than English; NG+ (the policy: not tested).

## Scope

**UI covers** the character stats popup and the summary lines of both character menus and the inventory, the numbers behind them (`GetOffenseStatsList`), item tooltips (display, descriptions, rows, attribute names), recipe and schematic texts, the alchemy menu's ingredient buying, the bestiary (kill count, weaknesses), the enemy level on the HUD, loading screen tips and tutorials, the skill icon in legacy's texture cache, shaving from the inventory, legacy's debug labels and the unused leftovers.

**Not UI:**

| Subject | Area | Why |
|---|---|---|
| Ghost Mode's options menu (`modGhostMode.xml`, `CR4IngameMenu`'s Ghost Mode units: `OnPresetApplied`, `OnOptionValueChanged`, `gmUserSettings`, `SaveChangedSettings`, the Ghost Mode members), the option strings | OPT | OPT owns the options framework ([opt.md](opt.md)) |
| The menu units of Community Patch – Base (`ingameMenu.ws`, `igmOptions.ws`, `igmStructureCreator.ws`, `mainCreditsMenu.ws`, `menuBase.ws`, `popupBase.ws`, `r4guimanager.ws`, `commonMainMenuBase.ws`, `CR4ScriptedHud.OnConfigUI`, `hudModuleTimeLapse.ws`) | DEP | Dependency changes ([what counts](../feature-mapping.md#what-counts-as-ghost-mode)) |
| HUD buff counters (decoction stacks, Lynx, Iris, Invigoration, Prolongation, mutations), the toxicity look of the wolf head | done with MUT-14, ARM-06, SWD-06, ENCH-05, ENCH-09, ALCH-10, ALCH-01 | Ported with their features |
| Skill, perk, mutation, set, runeword, potion, decoction, bomb and oil descriptions, and the item tooltip fixes those areas made | done with SKL-19, MUT-14, ARM-14, ENCH-17, SWD-05, SWD-06, SWD-09, ITEM-12, ALCH-17 | Ported with their features |
| Dismantling from the inventory (`PlayerDismantleItem`, the dismantle inputs in `inventoryContext.ws`, strings 2110992257, 258, 260, 330–334), the crafting components' rarity colours (bugfix 120: item data), the razor's parts | CRAFT | Crafting |
| `FixQuestItems` (`CR4InventoryMenu.OnConfigUI`), `FamilyIssuesAutosave` (`CR4ScriptedHud.OnQuestUpdate`) | FIX | Bug fixes run from a menu |
| The monster-hunt reward negotiation (`OpenMonsterHuntNegotiationPopup`), the razor's price | ECON | Money |
| `CalculateExperiencePoints` (where the kill counter is incremented), `GetExpByEnemyType`, `GetExpModifierByEnemyType`; UI-10's counter and `GetEnemyTypeByAbility` are shared | XP | Experience |
| The displayed level's fake addon and cap in `GetExperienceDifferenceLevelName` | DIFF | Fake levels ([DIFF-05](diff.md#diff-05-fake-levels)) |
| `W3Boat.OnAreaEnter` and its message (2110992179), the razor's weight | WGT | Weight |
| `attribute_name_staminaRestore` (2110992352; unused by legacy, dropped: [food.md](food.md) FOOD-08) | FOOD | Food |
| The creatures' weakness lists (`itemsUsedAgainstCreature` in 12 entity files), the caretaker's spade text (2110992475) | AI | Enemies |
| `arrowProjectile.ws`'s fix for Yoana's arrow bounce (the row is UI-07's) | ARM | Armor |

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

### Classification and action

| # | Feature | Class | Action |
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
| UI-14 | Skill icon | conflict (cache format) | 5.x's icon kept (Q1) |
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
| Port status | **signed off** (2026-10-21); **ported** (slice 3), verified in both trees |
| Open checks | a real fight's hits against the panel (scripted hits only); the crossbow line against a real bolt hit (read by script); a sword with crit chance of its own sheathed (the test's swords have none) |
| Save impact | none (expected) |
| NG+ counterpart | none (scripts) |

**What it does** (changelist 1161–1162, 1171–1174): the numbers the panel, the inventory's stat hovers and the summary lines show. Per sword and attack type: attack power (general, per attack type, per sword), damage per hit against an enemy with no armor or resistance ((weapon + elemental damage) × (1 + damage bonuses) × attack power, strong attacks with Strong Attack's multiplier), crit chance, crit power (attack power plus crit bonuses) and crit damage, and the expected damage per hit (normal and crit weighted by the crit chance), which replaces 1.32's damage per second. The sheathed sword's bonuses are read from the item, so both swords show their own damage, attack power, crit and effects; other bonuses (sign power) only show while the sword is drawn (changelist 1172–1174). Terms: Muscle Memory and Strength Training per attack type, Precise Blows and Crushing Blows, the Lynx chain, Bear tier 1 attack power per adrenaline point, Thunderbolt 3's crit chance, Heft, Euphoria's damage, the Wolven tier 2 oil bonuses, `sword_dmg_bonus` (NG+), Invigoration's 1.32 line removed. Crossbow: attack power, crit chance, crit damage (legacy's list also reads Cat Eyes' `critical_damage`, which its data comments out: 0), bolt damage by type with Steady Shot's +50 and Cat Eyes' doubled base, elemental bolt damage.

**Implementation (legacy):** `W3PlayerWitcher.GetOffenseStatsList` (rewritten), `SPlayerOffenseStats` (new fields: attack power and crit attack power per attack type and sword, crossbow attack power, crit damage bonus, elemental damage and its type). Legacy's Life Leech reads the list's attack power (`Mutation11GetBaseStrength`).

**5.x:** 1.32's DPS model with 5.x's new-tree perk terms and Heightened Tolerance's crit damage; the port's new-tree slots hold legacy's skills (SKL), so those terms read the wrong skills. The port's `damage/formula.ws` still calls the list for 5.x's allied-NPC block, which DMG-12 switched off (no reader in play); MUT-12's drain reads the list, as legacy.

**Decisions:** DU1 (owner, 2026-10-20): legacy's list and terms in both trees, each classic term read from either tree's skill; 5.x's terms for the perks and skills the port replaced are dropped; 5.x-only gear (SWD-10's swords, ARM-15's armor) reads through the same item attributes.
Each term is the one Ghost Mode's formula gives a hit: the attack power as the attack action builds it (the attack power plus the abilities tagged with the attack's name, which carry the classic Muscle Memory and Strength Training per level, Strong Attack's term and the style attributes), the conditional terms counted only while they are active (the Feline chain, the Bear set per adrenaline point, the new tree's Muscle Memory's and Strength Training's dodge boost and next-strike bonus while armed), the new tree's Muscle Memory's attack power for fast attacks and Strength Training's for strong attacks, Precise Blows and Crushing Blows of either tree, the pool's terms (Strong Attack's +50%, Heft, `sword_dmg_bonus`), Euphoria's base damage. Situational terms are not shown, as legacy: headshots, backstabs, oils against a monster type, counters, Wolf School, Viper School and Hunter Instinct against an enemy. The crossbow: attack power with the Bear set, crit chance as a bolt gets it, crit damage with Anatomical Knowledge of either tree, Steady Shot's (or Cold Blood's) flat damage, Cat Eyes' doubled base, no additive attack power (DMG-03). 5.x's terms are gone: its new-tree perks, Heightened Tolerance, Water Hag's `damageIncrease` (ALCH-10's list part), Runeword 4's overheal, `perk_2`'s crossbow attack power, the ×1.833 heavy multiplier and the attack speed divisors. The sheathed sword's bonuses and the drawn other sword's subtraction are legacy's.
- **Deviation:** Thunderbolt 3's +100% in a storm is counted as crit chance, as the hit counts it; legacy's list added it to crit power (porter's call, confirmed by the owner, 2026-10-21).
- **Deviation:** the expected hit weights normal and crit damage by the crit chance capped at 100%; legacy's list did not cap it (Life Leech's average attack power keeps legacy's uncapped weighting) (porter's call, confirmed by the owner, 2026-10-21).
- **Deviation:** the bolt's damage is read from the equipped bolt (its level's values, ITEM's DI1), as the hit reads it; legacy's list read the bolt's definition (porter's call, confirmed by the owner, 2026-10-21).

**Slices:**

3. **The offense list.** Verified 2026-10-21, both trees. Scripted: `GMTest_ui01` (regression: 5.x's struct carries Ghost Mode's list, the expected hit is the crit-weighted average, Life Leech's base strength); `gmtest_ui01_hits` (scripted hits through `ProcessAction` on test dummies, without skills and with each tree's Muscle Memory, Strength Training, Precise Blows and Crushing Blows): the list's attack power equals the hit's and the damage dealt is the list's within the hit's random 0.9 to 1.1; `gmtest_ui01_terms`: the crossbow, Cat Eyes, Anatomical Knowledge, Bear and Feline terms; `GMTest_ui01_crit` (in `gmtest_panel()`): each sword's crit chance, drawn or sheathed, equals the hit's `GetCriticalHitChance`. Real, on screen: the inventory's stats view follows the list in both trees.

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
| Port status | **signed off** (2026-10-21); **ported** (slice 4), verified in both trees |
| Open checks | the new character menu's summary line on screen (its view opened by `dupemenu()` shows the skill tree; checked by script); the character menu's own stats popup on screen (the inventory's stats view, built by the same function, was seen) |
| Save impact | none (expected) |
| NG+ counterpart | none |

**What it does** (changelist 1161–1162, bugfix 169): the silver and steel sections are headed "Damage per hit" (the average of the fast and strong expected hits, UI-01); each lists, for fast and then strong attacks, attack power, damage, crit chance, crit power and crit damage, then the effect chances (poison, bleeding with Crippling Strikes, burning, confusion, freezing, stagger; Metamorphosis' bonus). The crossbow section lists attack power, crit chance, crit damage, adrenaline gain per bolt (Cold Blood), the bolt's damage under its damage type's name and its elemental damage. Instant kill shows the larger of the two swords' chances, not their sum. The labels of 1.32's DPS lines read "Fast attack damage" and so on (12 strings by key hash, also in the inventory's stat hovers); the summary's "Damage per hit" labels are legacy's `_dph_gm` strings.

**Implementation (legacy):** `GetPlayerStatsGFxData` (sections), `AddCharacterStatU` (the sword and crossbow values, instant kill), `AddCharacterStatU2` (chances), `GetEquippedCrossbowDamage` (Water Hag's line removed, Steady Shot moved), new `GetCrossbowSteelDmgName`, `GetCrossbowElementaDmgName`, `IsBoltEquipped`; `CR4CharacterMenu.UpdatePlayerStatisticsData` (labels); strings 2110992017, 018, 028, 029, 074–085, 167, 168.

**5.x:** the popup is 1.32's; the new character menu has its own copy of the summary (`characterMenuDupe.ws:3296`), which needs legacy's labels too (5.x-only code; the classic `characterMenu.ws` is not used by the port).

**Decisions:** port as legacy (DU1). The crossbow's adrenaline line reads Cold Blood of either tree (legacy: `perk_2`), with Razor Focus and Adrenaline Rush's factor; the bleeding chance adds Crippling Strikes of either tree. 5.x's Flash popup draws legacy's rows as they come (20 rows in a sword section, 7 in the crossbow's), seen on screen. 5.x's new character menu has its own hover tooltip for offense (`GetOffenseTooltipData`, 1.32's, which legacy left too); not changed.

**Slices:**

4. **Sword and crossbow sections.** Verified 2026-10-21, both trees. Scripted: `GMTest_ui02` (in `gmtest_panel()`): the popup built by `GetPlayerStatsGFxData` has legacy's headings, lines, labels and the list's values; Crippling Strikes of each tree in the bleeding chance; the crossbow section with Cold Blood of either tree; instant kill the larger sword's; 5.x's summary call returns "Damage per hit (silver)". Real, on screen (the inventory's stats view): the silver and crossbow sections (classic), the steel section (new tree).

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
| Port status | **signed off** (2026-10-21); **ported** (slice 5), verified in both trees |
| Open checks | the character menu's stats popup on screen (the inventory's stats view, built by the same function, was seen); real casts checked for Quen, Yrden and Axii only (`gmtest_ui03_casts`); Aard's and Igni's chances and the damage lines against real casts |
| Save impact | none (expected) |
| NG+ counterpart | none |

**What it does** (changelist 1157–1160): the common sign power line shows the raw value; each sign gets its own intensity line and its values with every modifier, as raw values before the target's resistance: Aard knockdown and heavy knockdown chance (Metamorphosis), force damage; Igni burn chance (Pyromaniac, Rotation, Metamorphosis), fire damage (Igni Intensity, Rotation, Conductors of Magic, Euphoria, Foglet, `spell_dmg_bonus`), Firestream damage per second; Quen intensity (Wraith's bonus), duration, absorption, active shield absorption, discharge as points and as a share (Retribution); Yrden intensity, traps, duration, range (Sustained Glyphs, the Griffin set's +40%), slowdown, turret duration, charges and damage; Axii intensity, confusion and control durations, instant kill chance. Yrden and Axii move to a second section.

**Implementation (legacy):** `AddCharacterStatSigns` (rewritten), `GetPlayerStatsGFxData`; strings 2110992019–027, 030, 272, 277, 278, 293, 461 (021 and 027 label lines legacy commented out: not ported).

**5.x:** 1.32's lines with 5.x's new-tree terms (Shock Wave's damage, Conjunction, Melt Armor's burn chance, a logarithmic burn chance); the port gave those slots legacy's skills (SKL-08 to SKL-12), so 5.x's terms go.

**Decisions:** port as legacy in both trees (DU1). Q3 (owner, 2026-10-20): use 5.x's character menu and popup however is easiest, as long as all of legacy's information is shown; one combined sign section is fine. Legacy's two sections work in 5.x's Flash popup (seen on screen: two "Sign intensity" rows), so they are kept. The damage lines add the damage pool's flat sign terms as the hit gets them (Mutation 1 from the held sword's total damage, Foglet, Euphoria's drain), then `spell_dmg_bonus` and the intensity. Where the deviation below follows legacy's own cast rather than its panel: the second trap at Sustained Glyphs 3, Petri's Philtre 3's ×1.34 on Quen's and Yrden's durations (legacy `yrdenEntity.ws:210`) and Axii's instant-kill chance rounded by legacy's roll are legacy's cast; Yrden's range is the one real difference in the cast itself (legacy's cast added Sustained Glyphs' +30 % and the Griffin set's bonus into one multiplier and then scaled the trigger again by the Griffin scale; the port multiplies them).
- **Deviation:** the sign lines show each value as the port's cast gets it where legacy's panel computed it differently: Yrden's range multiplies Sustained Glyphs' and the Griffin set's bonuses (legacy's panel added them; the trap scales by both); the second trap from Sustained Glyphs' level 3 (legacy's panel: level 2; the cast: level 3); Quen's and Yrden's durations and Axii's with Petri's Philtre level 3; the knockdown chance clamped to 10 % to 100 % before Metamorphosis, the heavy knockdown chance as a share of it; Exploding Shield's damage 0 below level 2, Retribution on its base only, and `spell_dmg_bonus` (the NG+ school swords) on it as on every sign hit (legacy's panel left it out of this line); the Yrden slowdown clamped to its minimum and maximum; the Axii instant-kill chance rounded to a whole percent as rolled (porter's call, confirmed by the owner, 2026-10-21).

**Slices:**

5. **Sign sections.** Verified 2026-10-21, both trees. Scripted: `GMTest_ui03` (in `gmtest_panel()`): two sign sections of 19 and 16 lines with legacy's labels and values on the test save; `gmtest_ui03_skills`: the same totals in both trees with each tree's sign skills (D58). Real casts by input simulation: `gmtest_ui03_cast(sign)` and `gmtest_ui03_casts(sign)` compare the Quen, Yrden and Axii cast entities with the panel's lines (absorption, durations, range, traps, confusion) up to display precision in both trees; cast each sign separately, as Quen's shield is gone once another sign is cast. Real, on screen (the inventory's stats view): the two sections in both trees.

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
| Port status | **signed off** (2026-10-21); **ported** (slice 6), verified in both trees |
| Open checks | — |
| Save impact | none (expected) |
| NG+ counterpart | none |

**What it does** (changelist 1164): locked toxicity, available toxicity (maximum − current), decay rate per second (base, medium set, Fast Metabolism, Placation, Toxic Blood's reduction), overdose threshold (75% of the maximum, ALCH-01), overdose Vitality drain per second (Euphoria's factor). The current toxicity line goes (the bar shows it).

**Implementation (legacy):** `AddCharacterStatToxicity`; strings 2110992423–425, 519.

**Decisions:** port as legacy. The toxicity decay reads only additive values in the data, so the port's "as the effect gets it" and legacy's additive part agree.

**Slices:**

6. **Toxicity section.** Verified 2026-10-21, both trees. Scripted: `GMTest_ui04` (in `gmtest_panel()`): the section's 5 lines with legacy's labels, no current toxicity line, available = maximum − current, threshold 75 % of the maximum; `gmtest_ui04_live`: the decay line equals the running toxicity effect's decay with the medium set, Fast Metabolism and Toxic Blood. Real, on screen (the inventory's stats view, new tree): the section.

**Later:** —

### UI-05 Panel: vitality, armor and other lines

| | |
|---|---|
| Kind | ui, fix |
| Pillars | P7 |
| 5.x class | clean |
| Flags | — |
| Depends on | STAM-04, STAM-05 (the existing `ui/characterStatsPopup.ws`), SKL-07 (Razor Focus `sword_s20`), SKL-03, SKL-04 (Muscle Memory, Strength Training of both trees), SKL-06 (Cold Blood: classic `perk_2`, new `sword_s34`), MUT-07 (Adrenaline Rush), OPT-03 (the Vitality regen options) |
| Skill trees | both (as UI-01) |
| Port form | `ui/characterStatsPopup.ws`: the global `AddCharacterStat` wrapper extended (Vitality regen, sign power; STAM-05's armor line moved to the armor section of `GetPlayerStatsGFxData`), UI-02's `AddCharacterStatU` wrapper (adrenaline gain, `GMPanelAdrenalineGain`), the misc section's lines in `GetPlayerStatsGFxData` (the money bonus by 5.x's `AddCharacterStatF`), `@replaceMethod` of `AddCharacterHeader` (legacy's name fallback; the same fallback in `AddCharacterStat` and `AddCharacterStatF` is not ported: none of their lines lacks a string, so nothing differs on screen); 2 strings in 9 languages (2110992383, 384; 105 came with UI-02) |
| Port status | **signed off** (2026-10-21); **ported** (slice 7), verified in both trees |
| Open checks | the attack power and sign intensity lines with Adrenaline Rush running (they read the attack power and sign power stats the Rush changes; not tested); the armor regen line on screen (scripted only) |
| Save impact | none (expected) |
| NG+ counterpart | none |

**What it does** (changelist 1163, bugfixes 89, 132): Vitality regen in and out of combat shows the multiplicative part (1.32 showed the additive part only) and the regen options; sign power shows its raw value; the misc section gains the money bonus and adrenaline gain (general, fast and strong with Muscle Memory and Strength Training, Razor Focus, Adrenaline Rush's rise or fall) and loses the XP bonus lines; the armor regen modifier line (option on) sits under Armor; a name without a string shows its key (legacy's fallback).

**Implementation (legacy):** `GetPlayerStatsGFxData`, `AddCharacterStat`, `AddCharacterStatU`, `AddCharacterStatF`, `AddCharacterHeader`; strings 2110992105, 383, 384.

**5.x:** 1.32's lines.

**Decisions:** port as legacy; DU3 (owner, 2026-10-20): the armor regen modifier line under Armor, as legacy (moved from STAM-05's stamina section). The adrenaline lines give a hit's gain as the port's hit gets it (Muscle Memory and Strength Training of either tree, Razor Focus, the Bear School's bonus with its perk, Adrenaline Rush's factor). Sign power's raw value is read with `GetPowerStatValue(CPS_SpellPower)` (Geralt's raw `spell_power` attribute reads -9999 in 5.x). The Vitality regen lines add legacy's two regen options (OPT-03), as legacy's; they leave out 5.x's "Vitality Regeneration Boost" (OPT's PO5).

**Slices:**

7. **Other lines.** Verified 2026-10-21, both trees. Scripted: `GMTest_ui05` (in `gmtest_panel()`): the Vitality regen lines equal the additive plus the multiplicative part, the raw sign power, the misc section's lines without experience lines, the armor modifier under Armor only with the option on; `gmtest_ui05_skills`: the adrenaline lines with Razor Focus, Muscle Memory and Strength Training of each tree. Real, on screen (the inventory's stats view, new tree): the misc section.

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
| Port status | **signed off** (2026-10-21); **ported** (slice 1), verified in both trees |
| Open checks | a book's, key's and quest item's description by name key on screen (ALCH audit F6); a Gwent card's and a trophy's tooltip on screen; a sword's oil line and the HUD's oil charges on screen (scripted only); comparisons on screen (scripted with made-up stats) |
| Save impact | none (expected) |
| NG+ counterpart | none |

**What it does** (bugfixes 41, 91, 104; code): armor and weapons show their item description (1.32 showed none), and the light, medium and heavy armor texts state the class's stamina rule (strings 2110992426–428); Gwent cards show no description; notes say "Contains useless information." (2110992256, by legacy's name-key lookup ported in ALCH-17); trophies list their stats like gear; a negative value has no "+", and comparing negative modifiers shows better and worse the right way round; a potion's toxicity is shown after Expert Brewer's reduction without "/max" and a decoction's offset after Adaptation; oils list every bonus (attack power, crit chance, crit damage, with the Wolven tier 1 boost per piece), and a sword's oil line shows the oil's name and charges only.

**Implementation (legacy):** `W3TooltipComponent.GetBaseItemData` (descriptions, trophies, oil stats), `AddItemStats` (toxicity, negative values), `CalculateStatsComparance` (comparisons), new `AddOilStats`, `AddOilInfo`.

**5.x:** armor and weapon descriptions still hidden; 5.x's own sword descriptions (`sq304`, `q402` swords); oil charges with Fixative read only `alchemy_s6`.

**Decisions:** port as legacy (DU4). Swords with a description of their own keep it: Aerondight and Iris (SWD's) and 5.x's two unique swords (`sq304`, `q402`, 5.x-only). Legacy passed trophies to `AddItemStats` as gear; that flag only changes the toxicity line, which the Arachas trophy has (+40 maximum toxicity): ported since the TRPH audit's F2 (2026-11-02), so its row reads "Maximum Toxicity +40" as legacy's, not a potion's "Toxicity 40" cut by Expert Brewer. Regression check `GMTestTrphToxTip` (in `GMTest_trph`), with Expert Brewer `gmtest_trph_toxtip()`; **verified** in both trees (scripted). The oil's charges with Fixative count either tree's skill (5.x and legacy read the classic one only).

**Slices:**

1. **Tooltips** (with UI-07). Verified 2026-10-20, both trees. Scripted: `GMTest_ui06` (regression): armor and sword descriptions, the oil tooltip's bonuses and charges, an oiled sword's line, a potion's toxicity without "/max", `CalculateStatsComparance` with made-up negative modifiers; `gmtest_ui06_skills`: Expert Brewer and Adaptation of each tree, the oil's charges and the HUD's infinite-oil check with either Fixative. Real, on screen (the inventory, items hovered): an armor's class text, an oil's bonuses and charges, a sword's description.

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
| Port status | **signed off** (2026-10-21); **ported** (slice 1), verified in both trees |
| Open checks | an item with one of the five rows on screen |
| Save impact | none |
| NG+ counterpart | none |

**What it does:** item stats legacy added get a tooltip row and a name: the armor regen modifier (shown only with the option on, STAM-05), frost resistance, a bolt's knockdown chance, combat Vitality regen, Yoana's arrow bounce chance; names for Vitality regen in and out of combat, knockdown chance, crit power bonus, damage increase, Vitality drain.

**Implementation (legacy):** `tooltip_settings.csv` rows `staminaRegen_armor_mod`, `frost_resistance_perc`, `desc_knockdownchance_mult`, `vitalityCombatRegen`, `q108_bounce_arrows`; strings 2110992013, 110, 153, 156, 157, 164, 265, 476. Legacy changed 55 `tooltip_settings.csv` rows in all; they read as legacy's in the port.

**Decisions:** port as legacy. The combat Vitality regen name (2110992157) also names a food or drink tooltip's in-combat regen row, through FOOD-08's code ([food.md](food.md#food-08-edible-tooltip)).
- **Deviation:** the Czech row of string 2110992110 ("Knockdown chance") carries the key `attribute_name_desc_knockdownchance_mult`, as every other language; legacy's Czech table misspelt it `attribute_name_dockdownchance_mult`, so in Czech the blunt bolts' knockdown chance row had no name (whole-port audit A7-1; owner, 2026-11-03).

**Slices:**

1. **Rows and names** (with UI-06). Verified 2026-10-20, both trees. Scripted (`GMTest_ui06`, regression): the five names read legacy's strings by key. The Czech key (A7-1) checked offline in the built `cz.w3strings` (decoded with `w3strings.py`).

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
| Port form | `ui/recipes.ws`: `@replaceMethod`s of `W3TooltipComponent.GetRecipeDataFromXML`, `W3GuiBaseInventoryComponent.GetAlchemyBookText` and `GetSchematicBookText`; `@addMethod GMAddComponentsInfo` called from a `GetBaseItemData` wrapper (which also adds a recipe's potion or bomb effects and a decoction recipe's values); a `GetCraftedItemInfo` wrapper empties the random-attribute line and shows the item's real weight |
| Port status | **signed off** (2026-10-21); **ported** (slice 2), verified in both trees |
| Open checks | a recipe or schematic item's tooltip and the extended text (E) on screen at a merchant (scripted only: an added recipe is read at once); the crafting menu on screen, its weight line included |
| Save impact | none |
| NG+ counterpart | none |

**What it does** (bugfix 87, changelist 1170): a recipe item in a shop or the inventory shows what it brews (1.32's typo `'alchemy_recipies'` made it show nothing); schematic, recipe and enchantment schematic tooltips list the ingredients as "have / need", red when short; the extended text (shown with E when buying) reads: item name in orange and rarity, the effects as "value name", the description (a decoction's with its values), the level required, the ingredients as "have / need"; the weight and the "random attributes" lines are gone (crafted gear has no random bonus: SWD's and ARM's `DoNotEnhance`). The crafting and alchemy menus' item panel (`GetCraftedItemInfo`) has no "random attributes" line either, and its weight line shows the item's real weight (its definition's) where 1.32 and 5.x show a display discount (×0.5 + 0.01; usable items, upgrades and junk ×0.2 + 0.01; crafting ingredients 0): a Short sword 1 (6) shows "Weight 6", not 5.x's 3.01 (legacy commented the discount out; whole-port audit C2-6, 2026-11-03).

**Implementation (legacy):** `GetRecipeDataFromXML` (the typo), `addComponentsInfo` (new), `GetAlchemyBookText`, `GetSchematicBookText`, `GetCraftedItemInfo`.

**5.x:** 1.32's (typo included); ALCH-17's wrapper reads `GetRecipeDataFromXML`, so it depends on this fix to match a decoction's recipe.

**Decisions:** port as legacy (DU5).
- **Deviation:** the extended texts name and colour every effect as the item tooltip does (slowdown, breath, focus; the default colour for a stat without one); legacy printed the names as they came, so a potion's slowdown showed as a bare "50 %" (porter's call, confirmed by the owner, 2026-10-21).

**Slices:**

2. **Recipe and schematic texts.** Verified 2026-10-20, both trees. Scripted (`GMTest_ui08`, regression): `GetRecipeDataFromXML` finds a recipe's potion; a recipe's tooltip and extended text with its effects, description and have / need ingredients, no weight; a decoction recipe's values; a schematic's tooltip and text without weight or random-attribute line. `GMTest_ui08_weight` (audit C2-6, 2026-11-03): the crafting menu's weight line is the item's definition's; failed first on a build without the change.

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
| Port form | none for buying (5.x's); Yolar: `ui/mapPins.ws`, `@wrapMethod` of `W3MerchantComponent.GetMapPinType` (the value `GetScriptInfo` hands the map) |
| Port status | **signed off** (2026-10-21); **ported** (Yolar's pin, slice 9; compiles, not seen in game) |
| Open checks | which NPCs open the alchemy menu in 5.x; Yolar's pin on the map (not on the test save; compiles only) |
| Save impact | none |
| NG+ counterpart | none |

**What it does** (code; modFriendlyHUD's, merged into legacy): in the alchemy menu opened at a herbalist or alchemist (by the NPC's map pin), the recipe list shows the vendor's stock and price, and a missing ingredient can be bought there; the druid Yolar's map pin shows him as a herbalist.

**5.x:** the same buying, from whichever NPC opened the menu (no pin check); Yolar's pin unchanged.

**Decisions:** Q2 (owner, 2026-10-20): keep 5.x's buying from any merchant who opened the menu (the owner reports it if it plays wrong); legacy's herbalist gate is not ported; Yolar's pin is ported if it is a separate, clean change. It is (one line in legacy's `GetMapPinType`, a wrapper here): ported.

**Known limit** (whole-port audit C2-13, owner, 2026-11-03): at a herbalist legacy's alchemy menu filled the merchant info panel (`UpdateMerchantData`: the merchant's name and money); 5.x's rewritten alchemy menu never sets it, and the port keeps 5.x's menu, so the panel stays empty while buying works. Not seen on screen.

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
| Port form | `ui/bestiary.ws`: `@addField` saved `gmEnemiesKilledByType` on `W3PlayerWitcher`, `@addMethod`s `GMIncKills`, `GMGetKills`; legacy's enemy types and functions as `EGMEnemyType` (`GMENT_...`), `GMGetEnemyTypeByAbility`, `GMGetLocStringByEnemyType` (shared with XP; `GetExpByEnemyType` stays XP's); the count is incremented in XP-04's `@replaceMethod(CNewNPC)` `CalculateExperiencePoints` (`xp/killExperience.ws`, legacy's counting place, after the experience is computed; PX5); `GMGetEnemyTypeByAbility` also counts 5.x's `ConDefaultSilver` (the plague victims) as humans (XP's DX4); `CR4GlossaryBestiaryMenu`: `PopulateData` and `UpdateItems` replaced, `UpdateImage` and `UpdateDescription` wrapped; 9 strings in 9 languages (2110992301–309) |
| Port status | **signed off** (2026-10-21); **ported** (slice 8), verified in both trees |
| Open checks | a kill in a real fight (scripted kills through the game's death path only) |
| Save impact | a new saved field: kills count from the mod's installation (DU6); an older save starts at 0 |
| NG+ counterpart | none |

**What it does** (changelist 1167): the bestiary gets a "Kill count" group with one entry: total kills, humanoids (with Wild Hunt warriors), animals, monsters and unique creatures, then kills by enemy type. A kill counts when it would give experience; guards count as humanoids without experience.

**Implementation (legacy):** `CR4GlossaryBestiaryMenu.PopulateData`, `UpdateItems`, `UpdateImage`, `UpdateDescription`, new `UpdateKillCountEntry`; `W3PlayerWitcher.IncKills`, `GetKills`, saved `enemiesKilledByType`; `gm_generic.ws` `EEnemyType`, `GetEnemyTypeByAbility`, `GetLocStringByEnemyType`; strings 2110992301–309. `GetExpByEnemyType` and `GetExpModifierByEnemyType` are XP's.

**Decisions:** DU6 (owner, 2026-10-20): the counter is ported now, with UI; it counts from the mod's installation; XP reuses it. The entry's icon (`bestiary_leshen_locked.png`) exists in 5.x (seen on screen).

**Slices:**

8. **Kill count** (with UI-11). Verified 2026-10-21, both trees. Scripted: `GMTest_ui10` (regression): counts read back and show in the entry's text; `gmtest_ui10_kill_a/b/c`: a hostile wolf killed through the game's death path counts one wolf; XP-04's checks show each kill counted once, a guard's kill counted as a human's and a kill without experience not counted ([XP-04](xp.md#xp-04-kill-experience)). The saved field is **verified**: a scripted kill, a save into a new manual slot and a real load of it keep the count (classic tree). Real, on screen: the bestiary's "Kill count" group and entry text.

**Later:** kills of enemies without a type count in no total: `GMGetEnemyTypeByAbility` returns `GMENT_GENERIC` or `GMENT_ANIMAL` for creatures it does not know, and `GMKillCountText` sums from `GMENT_HUMAN` up, so those kills show nowhere, not even in "Total" (legacy's loop in `UpdateKillCountEntry` does the same).

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
| Port status | **signed off** (2026-10-21); **ported** (slice 8), verified in both trees |
| Open checks | the lists on screen (the test save knows none of the eight creatures); 5.x's preparation menu (`preparationMenu.ws`, a tracked creature's list) still reads the journal's list (not used in 5.x's play, unverified) |
| Save impact | none (expected) |
| NG+ counterpart | none |

**What it does:** the bestiary's "used against" lists follow Ghost Mode's bombs: Silver Dust instead of Dimeritium for the leshen, the ancient leshen, the spriggan, the grottore and hunt mh302; Dimeritium added for hunt mh303 and the succubus; Axii and Yrden added for the djinn.

**Implementation (legacy):** `itemsUsedAgainstCreature` in `leshy1`, `sq204ancientleszen`, `bestiarymonsterhuntmh302`, `bestiarymonsterhuntmh303`, `dzinn`, `succubus`, and Blood and Wine's `mq7002grottore`, `mq7002spriggan` journals. The same lists in the creatures' data (12 entity files) are AI's.

**Decisions:** port as legacy (DU7). The lists are changed in script instead of in the eight binary journals: the bestiary is the journals' only reader in play, the result on screen is legacy's, and no binary file has to be shipped or merged (the tags with spaces and dashes are compared as strings: a name literal cannot hold them).

**Slices:**

8. **Weaknesses** (with UI-10). Verified 2026-10-21, both trees. Scripted (`GMTest_ui11`, regression): the leshen, succubus and djinn entries loaded by their journal aliases give legacy's lists; the other five tags with 5.x's lists give legacy's; another creature keeps its list.

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
| Port form | `ui/enemyLevel.ws`: `@replaceMethod` of `CNewNPC.GetExperienceDifferenceLevelName` (the deadly branch removed; the fake addon, the NG+ addon and the cap removed by [DIFF-05](diff.md#diff-05-fake-levels)) |
| Port status | **signed off** (2026-10-21); **ported** (slice 9; the fake levels with DIFF-05), verified in both trees |
| Open checks | — |
| Save impact | none |
| NG+ counterpart | none |

**What it does** (changelist 1113): an enemy far above Geralt shows its level in red instead of `???`, from 6 levels above him (`LEVEL_DIFF_HIGH`: 6 since AI's slice A1, the owner's DA4, 2026-10-28; 5.x's value is 10). The number is the enemy's real level, without 5.x's fake addon and its cap at 5 above the maximum level, as legacy ([DIFF-05](diff.md#diff-05-fake-levels), which lists the enemies whose shown level this lowers).

**Decisions:** port as legacy (DU8). The HUD shows the real level, as legacy (the temporary deviation that kept 5.x's fake level addon, the NG+ addon and the cap until DIFF ended with DIFF-05). The 71 enemies whose fake level legacy made real (AI-06) carry it as their level, so the sergeant shows 11. **Skull marker** (answered by the owner, 2026-10-21): 1.32 also shows the skull above an enemy's level, so the skull plus the red level is vanilla's and legacy's HUD; nothing to change.

**Slices:**

9. **Enemy level** (with UI-13, UI-15, Yolar's pin). Verified 2026-10-21, both trees. Scripted (`gmtest_ui12_a/b`, listed with the manual UI checks in `gmTestsUi.ws`): a hostile far above Geralt gives "highLevel" and its level in red (`#FF1919`), not "deadlyLevel"; `gmtest_ai01_read` (AI slice A1): 5 levels above "normalLevel", 6 above "highLevel". Real, on screen: the red level in the diamond above the health bar of a locked-on enemy; the real level without addons with DIFF-05 (`gmtest_diff05_*`).

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
| Port status | **signed off** (2026-10-21); **ported** (slice 9), verified in both trees |
| Open checks | a tip on a loading screen and a tutorial popup on screen (the texts read by script only); how legacy's input placeholders (`<<AttackLight>>`, `<<AttackHeavy>>`, gamepad-only actions on PC in 1.32 and 5.x) show with a keyboard |
| Save impact | none |
| NG+ counterpart | none |

**What it does** (changelist 1168): nine loading screen tips (enemy stamina, level colours, grindstones, mounted attacks, attacks from behind, aiming, deflecting arrows, Quen against critical effects, dodging or parrying by enemy size) and sixteen tutorials (parry, counter, fast and strong attacks, dodge, roll, bombs, signs with cooldowns, crossbow, stamina, grindstones and armorer's tables, oils, adrenaline, witcher sets) describe Ghost Mode's rules.

**Implementation (legacy):** strings 2110992520–528 (by key hash) in nine languages; `modGMTutorials` rows by vanilla id in six languages (Brazilian Portuguese, German, English, Spanish, Polish, Russian).

**Decisions:** DU9 (owner, 2026-10-20): legacy's tips and tutorials; languages legacy lacks keep 5.x's. The 5.x texts were compared before being overridden (English): the fast and strong attack tutorials (1075370, 1075376) describe the alternative input scheme (`<<AttackWithAlternateLight>>`, the "Modify Attack Type" key) and the sign tutorial (1075722) the sign selection keys. These are 1.32's texts too (1.32's `patch1` string table; 5.x's equal them), so legacy's tutorials already replaced them in 1.32: losing those notes is legacy's behaviour, not a deviation (UI audit F2). The input placeholders of legacy's texts (`<<AttackLight>>`, `<<AttackHeavy>>`) are bound to the gamepad only, on PC, in 1.32 and 5.x alike (`input_qwerty.ini`). Legacy's Brazilian and Russian tutorial tables declared English in their header; the port's say `br` and `ru` (the build reads the header).
- **Known limit** (whole-port audit A7-4, owner, 2026-11-03): the rewritten tutorials exist only in Brazilian Portuguese, German, English, Spanish, Polish and Russian, as legacy's; Czech, French and Italian players see 5.x's vanilla tutorials, which describe vanilla rules (no sign cooldown, no −50% for non-aimed throws). Translating them is a later task if wanted.
- **Deviation:** the Brazilian and Russian tutorial tables declare their own language (legacy's declared English, so whether legacy's players saw them is unknown; [to test in legacy](../open-questions.md#to-test-in-legacy-ghost-mode)) (porter's call, confirmed by the owner, 2026-10-21; recorded by the UI audit, F3).

**Slices:**

9. **Tips and tutorials.** Verified 2026-10-21, both trees. Scripted (`GMTest_ui13`, regression): the English fast attack tutorial and the tip rows 2110992520 and 528 read legacy's texts. All 900 UI string rows of the nine `modGhostMode` tables and the six `modGMTutorials` tables were compared with legacy's (id, key hash, key, text): equal, apart from the commented-out 2110992021 and 027 (UI-03) and the dropped UI-17 rows.

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
| Port form | none (Q1); it would need a texture cache for 5.x cooked by `wcc_lite` (unverified) |
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
| Port status | **signed off** (2026-10-21); **ported** (slice 9), verified in both trees |
| Open checks | the E key on the razor (a real double-click used it; a scripted E key press did nothing) |
| Save impact | none |
| NG+ counterpart | applied (the item's description key) |

**What it does** (changelist 866): the razor gets a "Use" input in the inventory; using it shaves Geralt (vanilla's `ShaveGeralt_Quest`), refreshes the paperdoll and says "Geralt is now clean-shaven". Its description reads "Used for shaving.".

**Implementation (legacy):** `W3InventoryGridContext.updateInputFeedback`, `execurePrimaryAction`, `CR4InventoryMenu.UpdateFace`; item `Razor` (`item_desc_razor_mod`; its price, weight and parts are ECON's, WGT's and CRAFT's); strings 2110992169, 173.

**Decisions:** port as legacy (DU10).

**Slices:**

9. **Shaving.** Verified 2026-10-21, both trees. Scripted: `GMTest_ui15` (regression): the razor's description; `gmtest_ui15_a/b/c`: with the beard grown, the razor's action shaves Geralt and shows the message. Real (classic tree): the razor's tooltip with "E Use" on screen; a real double-click on the razor shaved Geralt.

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
| Port status | **signed off** (2026-10-21); **dropped** (DU11) |
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
| Port status | **signed off** (2026-10-21); **dropped** (DU12) |
| Open checks | — |
| Save impact | none |
| NG+ counterpart | none |

**What it does:** nothing in legacy: a stash mode that was never wired (`CInventoryComponent.TransferStashItemsTo`, `TransferStashItemsFrom`, `CanTransferItem`, `IsItemTempTransferred`, no caller; strings 2110992182, 184–187, 261, 312) and the strings of two commented-out panel lines (chance to keep balance when hit, 2110992264; attack power from levels, 2110992324).

**Decisions:** DU12 (owner, 2026-10-20): dropped. They change nothing in play (no caller, no shown line), so dropping them is no deviation; likewise legacy's two strings of commented-out sign lines (2110992021, 027, UI-03).

**Later:** —

### Dependencies on other areas

- **Areas UI builds on:** DMG (the formula behind UI-01), STAM (`ui/characterStatsPopup.ws` with the stamina lines, STAM-05's option), SKL (every skill of both trees, the descriptions), MUT, ARM, ENCH, SWD, ITEM (`GMGetEnhancedBuffInfo`), ALCH (the tooltip wrappers in `alchemy/tooltips.ws`, ALCH-01's threshold).
- **Areas UI shares with:** XP (the kill counter, UI-10), OPT (the Vitality regen options, UI-05), DIFF (fake levels, UI-12), CRAFT (ingredients, dismantling, UI-08, UI-15), XBOW (bolt values, UI-01, UI-07), TRPH (trophy stats, UI-06, UI-07), AI (the creatures' weakness lists, UI-11).

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
