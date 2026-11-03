# SWD: swords

Geralt's steel and silver swords: their damage, their bonuses and the two swords with a mechanism of their own, Iris and Aerondight. Ghost Mode rebuilt the swords' numbers around one rule: **a sword's main damage (slashing for steel, silver for silver) is set by its item level** and is the highest that level allows (steel 25 + 8 per level, silver 90 + 10 per level), so a sword's level and its damage are the same thing. Every crafted, relic, unique and witcher sword then got fixed bonuses instead of random ranges: crit chance and crit damage, attack power, armor penetration (flat or a resistance reduction), an effect chance (bleeding, burning, freezing, poison, confusion, stagger), a sign's intensity, a dismember chance; the XP and crowns bonuses vanilla put on swords are gone. The witcher school swords follow their set's theme (Feline crits and bleeding, Griffin sign intensity and fire, Bear attack power and adrenaline, Wolven attack power and sign intensity, Viper poison and armor penetration, Manticore armor penetration and adrenaline). Iris and Aerondight were redesigned: charges from hits that decay and reset when Geralt is hit; a charged Iris adds 5% of Geralt's Vitality to a hit and its strong attack throws an undodgeable phantom strike that ignores armor and resistances; Aerondight gains 10 damage per enemy in combat and, charged, lands a certain critical hit with +100% crit power that ignores armor and resistances and shocks the enemies around. Source: the changelist's "Swords" section ([legacy-FullChangelist.txt](../legacy-FullChangelist.txt), lines 614–649) and bug fixes (lines 70–73, 104–108, 183).

Swords are part of player power: balance them with [balance.md](balance.md) and the [gear ledger](ledger/gear.md) (sections 2 and 7: the school swords, relics, Iris and Aerondight in vanilla 1.32, legacy and 5.x).

**How legacy Ghost Mode implements it.** A sword's stats are its `_Stats` ability in the item files (`def_item_weapons.xml`, `def_item_crafting_weapons.xml`, `def_item_weapons_relic.xml`, the expansions' copies, `dlc10_wolf_swords.xml`, `def_item_dlc15_weapons.xml`, the standalone starting swords); the swords that scale with the level (`Autogen`: loot and relic swords) take their damage from the per-level abilities `autogen_steel_dmg`/`_base` and `autogen_silver_dmg`/`_base` in `def_item_weapons_relic_autogen.xml`, added by ITEM's level code (`GenerateItemLevel`, `AddItemLevelAbility`); the level shown is computed back from the damage (`W3GameParams.GetItemLevel`, ITEM). Iris becomes an effect, `W3Effect_PhantomWeapon` (`phantomWeapon.ws`, `PhantomWeaponEffect` in `dlc/ep1/.../effects.xml`), replacing vanilla's `CPhantomWeaponManager`; Aerondight's effect (`aerondight.ws`, `AerondightEffect` in `dlc/bob/.../effects_ep2.xml`) is rewritten; both are managed in `CR4Player.ManageAerondightBuff`/`ManageIrisBuff` and the equip, combat and holster events, and act in the damage code (`GetTotalWeaponDamage`, `ProcessAction`, `ProcessCriticalHitCheck`, `GetAttackersPowerMod`, `GetDamageResists`, `CActor.DoAttack`, `PrepareAttackAction`).

**What 5.x did in this area.** Almost nothing to the swords that exist in 1.32: their abilities, Iris, Aerondight and the level code for swords are 1.32's (5.x changed scabbards, and fixed the steel/silver draw animation of three crafted silver swords as legacy did). 5.x added swords: the Netflix set's three tiers ("Forgotten Wolven", steel and silver, plus Reinald's pair), the Dol Blathanna longsword and the White Widow of Dol Blathanna, the Steel and Silver Vixen, and the Top Notch steel and silver swords; all carry vanilla-style bonuses (XP on kill included) and none follows Ghost Mode's damage-by-level rule.

Unit lists: [attribution.csv](attribution.csv): mapped 2026-10-19 from the changelist and sweeps of every unit in the weapon item files (`unit_sweep.py` and a field-by-field comparison of every sword item and ability, master against `legacy-GM`), and of `aerondight`, `phantomweapon`, `iris`, `sword_dmg_bonus`, `spell_dmg_bonus`, `steelsword|silversword`, `weapon`: 1,164 units carry an SWD feature (98 script units, 438 XML units and their 551 NG+ copies, 77 CSV rows: 5 tooltip rows and 8 strings × 9 languages); 114 of them are shared with other features (the damage functions with DMG, the set swords' items with ARM, the effect registration with MUT and ENCH). Units of weapon items whose only Ghost Mode change is the price, the dismantling parts, the weight, the level range or an NPC scabbard are left to ECON, CRAFT, WGT and ITEM, and NPC, monster and secondary weapons and crossbows to AI and XBOW ([hand-off](#hand-off-to-other-areas)). Port status: **mapped, analysed against 5.x from the code; [area decisions](#area-decisions) made by the owner (2026-10-19); **ported**: SWD-01 to SWD-10 ported and verified in both trees (2026-10-19; SWD-07 NG+ only, untested by policy); audited 2026-10-19 ([SWD audit](#swd-audit-2026-10-19): F1 to F12): every finding fixed, recorded or decided by the owner ([close-out](#audit-close-out)): the clear fixes F1, F2 and F9 (5.x-GM `c934ee50`) and the owner's decisions F4 and F10 (5.x-GM `0e524ca1`) made and verified in both trees; **signed off** by the project owner (2026-10-19).**

## Scope

**SWD covers** Geralt's steel and silver swords (and Ciri's Zireael): damage and its scaling by level, crit chance and crit damage, attack power, armor penetration, effect chances, sign intensity and other bonuses on swords, enhancement slots and quality, relic, unique and witcher school swords (the set swords' stats; their set tags are ARM's), Iris and Aerondight, the NG+ swords' damage bonuses, the swords' tooltip rows and attribute names, and 5.x's new swords.

**Not SWD** (the boundary, porter's call from the docs, for the owner to confirm with DS5):

| Subject | Area | Why |
|---|---|---|
| Crossbows and bolts (Ofir crossbows included) | XBOW | Their own changelist section and area (DMG's hand-off: armor piercing, headshots, NPC bows) |
| NPC weapons (`def_item_npcweapons.xml`, `def_item_weapons_npc.xml`, the `NPC *` swords in the player files), secondary weapons (axes, clubs, halberds; NPC scabbards added), monster weapons, fists, the Caretaker's shovel | AI | DMG handed "NPC and monster weapons" to AI; Geralt never wields them. Exception: Olgierd's own Iris (`NPC Olgierd Sabre`) is SWD-06, since the phantom strike code is shared |
| Sword oils (items, effects, the oil tooltip rows, the stuck-oil fix `RemoveAllOilAbilitiesFromItem`) | ALCH | Oils are alchemy items; their skills are SKL-14 (signed off), the Wolven set's oil bonuses ARM-09 |
| Item level (`GetItemLevel`, `GenerateItemLevel`, `AddItemLevelAbility`, `Autogen*` tags, `item_level_min/max`), random weapon bonuses (`def_item_quality.xml` `MA_*`, `InitWeaponAbilities`, `AddRandomEnhancementToItem`, `AddQualityAbilityToItem`), `DoNotEnhance` where legacy removed it (where legacy added it, SWD-02 carries it: [audit](#swd-audit-2026-10-19) F4), durability, the grindstone buff | ITEM | Shared with armor; DMG and ARM handed the same mechanisms to ITEM |
| Prices and the `mod_legendary`/`mod_valuable` price tags | ECON | as ARM |
| Dismantling parts, sword schematics (NG+ Wolven schematics included), crafting costs, mastercrafted weapon kits, the Blood and Wine relic schematics' colour fix | CRAFT | as ARM |
| Sword weights | WGT | as ARM |
| Where swords drop or are sold | LOOT | as ARM |
| The character panel's sword sections (average damage per hit, attack power and crit power lines), the instant-kill chance shown as the swords' maximum | UI | DMG and SKL handed the panel to UI (`SPlayerOffenseStats` is a struct) |
| Horseback damage from weapon damage | HORSE | Its own changelist section |

## Changes at a glance

### What Ghost Mode changed

| # | Feature | Vanilla 1.32 | Legacy GM | Units (main) |
|---|---|---|---|---|
| SWD-01 | Damage by item level | Fixed damage per sword (crafted Short sword 30 at quality 2, Nilfgaardian sword 4 270); level scaling `autogen_steel_dmg` 7–8, `_base` 20–25, silver 8–10 and 80–90; level read back from damage with `Floor(1 + …)` | Every sword's main damage is the maximum for its level: steel 25 + 8/level, silver 90 + 10/level (crafted Short sword 33 at level 1, grandmaster school swords 345/490 at level 40); autogen steel 8 per level, base 19–25; silver 10, base 82–90 | `autogen_*_dmg/_base`; `SlashingDamage`/`SilverDamage` in about 300 sword abilities |
| SWD-02 | Generic and crafted swords | Crafted swords quality 2–3 with damage only; loot swords random | Crafted swords quality 1–3, fixed bonuses per sword (armor penetration 20 or 5% resistance reduction, attack power 5–10%, crit chance 10%, crit damage 20%, an effect at 5%), more slots on some; no random enhancements (`DoNotEnhance`, ITEM); XP-on-kill bonuses removed; icons fixed | `*_crafted _Stats`, crafted items, standalone starting swords |
| SWD-03 | Relic and unique swords | Relics: random ranges (`min`/`max`) of small bonuses, crowns and XP bonuses | Fixed bonuses per sword: each a theme (an effect at 5–15%, one or two signs' intensity, crit chance and damage, attack power, armor penetration 15–80, dismember chance, adrenaline), crowns and XP bonuses removed; Hjalmar's sword, Ofir sabres, the Hearts of Stone unique swords, the Toussaint and guard swords, Ciri's Zireael retuned | `def_item_weapons_relic.xml`, `*_crafted` relics, `Unique*`, `q402`, `sq304`, EP1/EP2 swords |
| SWD-04 | Witcher school swords | Mixed crit and effect bonuses | Set themes: Feline crit chance 15–35% and bleeding 15–30%; Griffin sign intensity 10–30% and fire damage 20–60; Bear attack power 20–40% and adrenaline 15–30%; Wolven attack power 15–30% and sign intensity 10–25%; Viper poison and armor penetration 60; Manticore armor penetration 80 and adrenaline 25%; damage by level (slightly lower than vanilla at the same tier) | school sword abilities in `def_item_crafting_weapons.xml` (and BaW, EP1), `dlc10_wolf_swords.xml`, `mq1058_cat_school_sword` |
| SWD-05 | Aerondight | Charges from hits and finishers; +10% damage and +100% crit chance when charged; permanent damage growth stored on the item (`PermDamageBoost`) | +10 weapon damage per hostile in range while in combat; 4 hits charge it, one charge lost per 6 s and all on taking damage; charged: a certain crit with +100% crit power that ignores armor and resistances, discharging on the hit with 100 shock damage and a stagger to enemies within 3 m; no permanent growth; effect only in combat | `aerondight.ws` (28 units), `AerondightEffect`, damage functions, tooltip, string |
| SWD-06 | Iris | Light attacks charge it (vanilla manager); a charged strong attack spawns a phantom strike that knocks down | An effect (`EET_PhantomWeapon`, HUD counter): 4 damaging hits charge it, one charge lost per 6 s, all on taking damage; charged: weapon damage +5% of Geralt's maximum Vitality (drained from him on a successful hit); a charged strong attack's phantom strike cannot be dodged, ignores armor and resistances, staggers and breaks shields; Olgierd's own Iris strikes on every strong attack | `phantomWeapon.ws` (20), `phantomWeaponManager.ws` (11, removed), `CActor.DoAttack`/`PhantomWeapon`/`PrepareAttackAction`, `ManageIrisBuff`, tooltip, string |
| SWD-07 | NG+ sword and sign damage bonuses (NG+ only) | Vanilla NG+ school swords have higher base damage; `NGP Wolf * Sword Mod` lowers it | NG+ school swords keep the damage-by-level rule at their NG+ level and add `sword_dmg_bonus` (+5–25% weapon damage; Feline, Bear, Wolven) or `spell_dmg_bonus` (+5–25% sign damage; Griffin, Wolven), as pool terms | NG+ school sword abilities, `ProcessDamageIncrease`, `GetOffenseStatsList`, tooltip rows, 2 strings |
| SWD-08 | Sword fixes | Missing steel/silver draw animations on some crafted silver swords; mixed-up icons; Wolf relic's draw sounds | Animations and icons fixed (changelist 107; "inventory icons", line 39) | item `anim_*`, `icon_path` in about 70 units |
| SWD-09 | Sword tooltip rows and attribute names | No row for resistance reduction or dismember chance | Tooltip rows `armor_reduction_perc`, `dismember_chance` (the old `dismember_chance_mult` row removed), attribute names "Enemy damage resistance reduction", "Armor penetration", "Dismember chance" | `tooltip_settings.csv`, 4 strings × 9 languages |
| SWD-10 | 5.x's new swords | n/a | n/a (5.x only: Netflix, Dol Blathanna, Vixen, Top Notch) | none (5.x's entries, `gen_swd_items.py`'s `SWD10`) |

### What 5.x changed

| # | Feature | 5.x change (from code and data) |
|---|---|---|
| SWD-01 | Damage by level | none to the swords' damage or the autogen abilities; `GetItemLevel` unchanged for swords (5.x adds bolt levels) |
| SWD-02 | Generic and crafted swords | none (scabbards of some items changed) |
| SWD-03 | Relic and unique swords | none to their stats (scabbards changed) |
| SWD-04 | School swords | none |
| SWD-05 | Aerondight | none (`aerondight.ws` and `AerondightEffect` as 1.32) |
| SWD-06 | Iris | none to Iris; `CActor.PrepareAttackAction` changed elsewhere (hand merge) |
| SWD-07 | NG+ bonuses | none |
| SWD-08 | Fixes | the three crafted silver swords' animation switch fixed as legacy did (Harpy, Negotiator, Weeper); the Wolf relic's sounds and Torzirael's animations not |
| SWD-09 | Tooltip rows | none |
| SWD-10 | New swords | Netflix steel 201/318/372 and silver 314/449/524 damage (5.x's `GetItemLevel` gives them the armor's tiers, 21/35/41), crit 5–15%, crit damage 10–35%, sign intensity 5–10%, adrenaline 3–10%, bleeding 4–10%, XP on kill; Reinald's pair = the first tier; Dol Blathanna steel 91 (Aard +1%, armor penetration 5) and silver 171 (Igni +1%), level 8; Vixen steel 121 and silver 213, bleeding 5–6%, crit 10–11%, level 12; Top Notch: level-scaled (`Autogen`), steel crit 10% and crit damage 10%, silver sign intensity 15%, no slots |

### Classification and proposed action

| # | Feature | Class | Proposed action |
|---|---|---|---|
| SWD-01 | Damage by level | clean | Legacy's values through a generated DLC override (like ARM's `gen_arm_items.py`) |
| SWD-02 | Generic and crafted | clean | Port with the generator |
| SWD-03 | Relic and unique | clean | Port with the generator |
| SWD-04 | School swords | clean | Port with the generator; set tags stay ARM's |
| SWD-05 | Aerondight | clean (5.x untouched) | Port legacy's redesign; ends DMG's Aerondight deviations |
| SWD-06 | Iris | clean (one unit overlaps) | Port legacy's effect; ends DMG's and DEF's Iris hand-offs |
| SWD-07 | NG+ bonuses | clean | Port with the generator (`items_plus`) and the pool terms; ends DMG-04's `sword_dmg_bonus` deviation |
| SWD-08 | Fixes | partly in-5.x | Port the fixes 5.x lacks; drop the three animation edits 5.x already has |
| SWD-09 | Tooltip rows | clean | Port with the slices |
| SWD-10 | 5.x's new swords | rethink, needs-decision | Owner's call (DS1, DS2) |

---

### SWD-01 Sword damage by item level

| | |
|---|---|
| Kind | tuning, system |
| Pillars | P1, P8 |
| 5.x class | clean |
| Flags | balance |
| Depends on | DMG (signed off: weapon damage from the item, DMG-08), ITEM (item level from damage, the per-level abilities, `Autogen` tags), WGT, ECON, CRAFT (the same entries) |
| Skill trees | n/a |
| Port form | `gm_swd_items.xml` in the DLC's `items/` and `items_plus/`, generated by `tools/gen_swd_items.py`: every item and ability unit [attribution.csv](attribution.csv) gives an SWD feature, 5.x's entry given whole (`on_conflict="replace"`) with legacy's SWD changes merged from the same file (a three-way merge against 1.32), the `autogen_*` abilities with legacy's values; the set swords' entries carry ARM's set tags (`gen_arm_items.py` hands them over, so each sword has one entry); `--verify` compares the final items with legacy's |
| Port status | **signed off** (2026-10-19); **ported, verified** (2026-10-19, both trees) |
| Open checks | the level most swords show (read in game for six; the rest from the code, the deviation below); NG+ (`--verify`) |
| Save impact | none (expected: stats come from the definitions; an owned level-scaled sword keeps its count of per-level abilities, whose value is read from the definitions, as ARM-01 verified for armor) |
| NG+ counterpart | applied, untested: legacy's own `items_plus` values (legacy set NG+ swords by the same rule at their NG+ levels) |

**What it does:** "Slashing/silver damage is defined by item level – the bigger the level is, the bigger the damage gets" (changelist 617–621). A sword's main damage is always slashing (steel) or silver (silver), each the maximum for the sword's level: steel 25 + 8 × level, silver 90 + 10 × level; legacy's comments give each sword's intended level (crafted Short sword level 1: 33; Lynx School steel sword 3 level 34: 297; grandmaster school swords level 40: 345 and 490). Level-scaled swords (loot and relic swords, `Autogen`) get 8 (steel) or 10 (silver) per level with a base of 19–25 or 82–90. Extra damage types (fire, frost, poison) are added on top and processed separately (DMG).

**Implementation (legacy):** the damage nodes of about 150 regular sword abilities (and their NG+ copies) and the four `autogen_*` abilities; the level is computed from the damage by `W3GameParams.GetItemLevel` (`Ceil` instead of vanilla's `Floor(1 + …)`, ITEM).

**5.x:** unchanged from 1.32.

**Decisions:** port as legacy (legacy behaviour first; 5.x did not change these swords). What is SWD's in an item: every stat legacy changed in a sword's abilities except `weight` (WGT), `item_level_min/max` (ITEM); every attribute of the item legacy changed except the price (enhancement slots, icons, looks, names, draw and holster animations and sounds), its look variants, ability list and tags; not the price, the dismantling parts, NPC scabbards (`bound_items`, AI), `Autogen*` tags (ITEM) or the price tags (ECON); `DoNotEnhance` where legacy added it (SWD-02, the owner's decision on the [audit](#swd-audit-2026-10-19)'s F4), not where legacy removed it (ITEM). Where 5.x changed the same field (scabbards; the three crafted silver swords' animations, DS3), 5.x's stays.

- The level a sword shows and needs is legacy's (`Ceil((damage - 25) / 8)`, silver `(damage - 90) / 10`) since [ITEM-01](item.md#item-01-item-level-from-stats) (2026-10-19), which ended the deviation kept until ITEM: the grandmaster Griffin steel sword shows 40 (read in game).
- The swords legacy moved to damage by item level (the standalone starting swords, Ofir Sabre 2, the Iron Poker, the laundry stick, the `q702` vampire steel sword, the `mq1058` Feline sword) are level-scaled since [ITEM-04 and ITEM-05](item.md#item-04-items-moved-to-level-scaling) (2026-10-19), and NG+'s crafted Burning Rose sword has legacy's typed `SilverDamage`, which ended the deviation kept until ITEM.
- **Deviation:** NG+ entries legacy deleted stay as 5.x has them, since a DLC cannot remove an entry: `NGP Ofir Sabre 2` (legacy's NG+ then has only the regular sabre), `NGP Olgierd Sabre` and its ability (SWD-06) (confirmed by the owner, 2026-10-19).
- The level-generation tags and ranges are legacy's on every sword since [ITEM-03](item.md#item-03-level-tags-and-ranges-in-item-data), Damien's sword level-scaled since ITEM-04 (2026-10-19), which ended the deviation kept until ITEM (SWD audit F5).

**Slices:**

1. **Item data for SWD-01, SWD-02, SWD-08 and their tooltip rows** (5.x-GM `3eadb715`; `tools/gen_swd_items.py` on master). 97 regular and 99 NG+ abilities, 88 regular and 115 NG+ items (the crafted, generic and loot swords, and the set swords' entries moved from `gm_arm_items.xml` with ARM's tags; the school swords' stats come with SWD-04). `gen_swd_items.py --verify`: 0 unexplained differences (168 regular and 223 NG+ items, 265 and 317 abilities against legacy's; the rest counted as slices not ported yet and the deviations above); `gen_arm_items.py --verify` still 0. Verified 2026-10-19 in both trees (test save; `GMTest_swd01` in the regression run, scripted reads of the definitions and tooltips): the crafted Short sword 33 damage, armor penetration 20, quality 1 and 5.x's weight; the crafted silver sword 1 100 silver damage; 8 and 10 damage per level; the crafted Nilfgaardian sword 4's bleeding chance and attack power; the XP bonus gone; legacy's slots and the Inquisitor sword's icon; the tooltip rows "Enemy damage resistance reduction", "Dismember chance" and "Armor penetration". Real attack (classic tree, level 10, the crafted Short sword equipped by script, a real light attack through the input handler on a neutral test dummy, the damage probe): raw slashing damage 32.6 (33 with 5.x's random roll). Not in game: the level a sword shows (the deviation above, read from the code), NG+ (checked by `--verify`).

**Balance values:** [gear ledger](ledger/gear.md) (school swords, relics).

### SWD-02 Generic and crafted swords

| | |
|---|---|
| Kind | tuning |
| Pillars | P6, P8 |
| 5.x class | clean |
| Flags | balance |
| Depends on | SWD-01, ITEM (random enhancements; `DoNotEnhance`, carried here where legacy added it), CRAFT (their schematics) |
| Skill trees | n/a |
| Port form | the generator (SWD-01) |
| Port status | **signed off** (2026-10-19); **ported, verified** (2026-10-19, both trees; [SWD-01](#swd-01-sword-damage-by-item-level) slice 1; `DoNotEnhance` slice 2) |
| Open checks | a sword crafted at a blacksmith or bought (the tag tested on swords added by script, which runs the same item-received code); NG+ (`--verify`) |
| Save impact | stats none (expected); a crafted sword already owned keeps a random bonus it rolled before the tag (the bonus is stored on the item and the tag only stops new rolls; from the code, not tested: no test save holds one) |
| NG+ counterpart | applied, untested |

**What it does:** "Crafted items now have non-random bonuses" (changelist 657). Each crafted sword (Short sword, No Man's Land, Nilfgaardian, Novigradian, Skellige, Scoia'tael, dwarven, gnomish, elven, Inquisitor, the crafted silver swords) has a level (1 upward, one level per tier) with the matching damage and one or two fixed bonuses: armor penetration 20, 5% resistance reduction, attack power +5–10%, crit chance +10%, crit damage +20%, an effect chance of 5% (bleeding, stagger, confusion, burning) or a sign's intensity; quality lowered to 1–3 (13, 16 and 10 swords; the crafted relics stay 4); some get an extra slot. Loot swords (`Autogen`) keep their damage by level; their vanilla bonuses are mostly kept. Every sword loses its XP-on-kill bonus (`human_exp_bonus_when_fatal`, `nonhuman_exp_bonus_when_fatal`), not in the changelist. The standalone starting swords (Hearts of Stone and Blood and Wine standalone starts) become level-scaled.

**Implementation (legacy):** `*_crafted _Stats` abilities and items in `def_item_crafting_weapons.xml` (base game, EP1, BaW), loot swords in `def_item_weapons.xml`, the standalone starting swords; about 240 regular and NG+ units.

**5.x:** unchanged.

**Decisions:** port as legacy. `DoNotEnhance` where legacy added it, so 5.x's random masterwork or magical bonus (`AddRandomEnhancementToItem`, on quality 2 and 3 items Geralt or a merchant receives) no longer lands on top of the fixed bonuses: the owner's decision on the [audit](#swd-audit-2026-10-19)'s F4 (project owner, 2026-10-19); the same for ARM's crafted armor ([arm.md](arm.md), ARM-01).

- Where legacy removed `DoNotEnhance` (the Blood and Wine silver swords and their `R` copies, the Toussaint, Cianfanelli and `mq7007` elven swords, the `sq701` tournament swords), it is removed since [ITEM-08](item.md#item-08-donotenhance-removed) (2026-10-19), so they roll legacy's random bonuses; that ended the deviation kept until ITEM.

**Slices:**

1. Ported with [SWD-01](#swd-01-sword-damage-by-item-level)'s slice 1.
2. **No random bonus on crafted swords** ([audit](#swd-audit-2026-10-19) F4, the owner's decision; 5.x-GM `0e524ca1`; `tools/gen_swd_items.py` on master): legacy's `DoNotEnhance` on every SWD item legacy added it to, regular and NG+. It acts on the 26 crafted swords of quality 2 and 3 (No Man's Land 3–4, Nilfgaardian 4, Novigradian 3–4, Skellige 2–4, Scoia'tael 2–4, Inquisitor 1–2, the dwarven steel 2 and silver 1–2, the gnomish 1–2 and gnomish silver 1–2, the elven silver 1–2, the crafted silver swords 4–7) and the Wild Hunt swords 3–4; on the others (quality 1, 4 or 5) 5.x adds no random bonus anyway. `--verify` compares the tag with legacy's (0 unexplained; legacy's removals counted, the deviation above). Verified 2026-10-19 in both trees (test save; `GMTest_swd02` in the regression run, by script: `AddAnItem` runs 5.x's item-received code with its random roll, as crafting and buying do): the tag on six of them; 8 new copies each of the crafted Skellige sword 2 (quality 2), the crafted silver sword 6 (quality 3) and Wild Hunt sword 4 got no random (`MA_*`) ability, while 8 copies of the untagged loot Dwarven sword 2 (quality 2) got one each. Not in game: a sword crafted at a blacksmith or bought, NG+ (`--verify`).

### SWD-03 Relic and unique swords

| | |
|---|---|
| Kind | tuning |
| Pillars | P6, P8 |
| 5.x class | clean |
| Flags | balance |
| Depends on | SWD-01, ITEM (level-scaled relics), ECON (`mod_legendary` price tag) |
| Skill trees | n/a |
| Port form | the generator (SWD-01) |
| Port status | **signed off** (2026-10-19); **ported, verified** (2026-10-19, both trees) |
| Open checks | NG+ (`--verify`) |
| Save impact | none (expected) |
| NG+ counterpart | applied, untested |

**What it does:** every relic (quality 4) and unique sword gets a fixed, distinct identity instead of vanilla's random ranges: for example Caerme +10% adrenaline, 30 fire damage and 15% burning; Gwyhyr 25% crit chance, +30% crit damage and armor penetration 30; Fate +60% crit damage, 45 fire and burning; Hjalmar's sword 25% crit chance, +75% crit damage, +10% attack power and adrenaline; the Hearts of Stone unique swords 20% crit chance, +100% crit damage and 20% burning or confusion. Typical parts: an effect (and its chance, 5–15%), one or two signs' intensity, crit chance and damage, attack power, armor penetration (15–80) or resistance reduction, a dismember chance. The crowns bonus (`bonus_money`) and XP bonuses go; Torlara's, Torzirael's, Havcaaren's and Eredin's sword's instant-kill chance is retuned. Crafted relics (Arbitrator, Beannshie, Black Unicorn, ...) follow the same themes at their crafted level. Ofir sabres, the Toussaint, guard, knight and Hanza swords (Blood and Wine), the EP2 silver swords, `q402`, `sq304`, Ciri's Zireael (armor penetration) are retuned the same way.

**Implementation (legacy):** `def_item_weapons_relic.xml` (base game, BaW), relic `*_crafted` entries, unique swords in `def_item_weapons.xml` (base game, EP1, BaW); about 330 units.

**5.x:** unchanged.

**Decisions:** port as legacy. Legacy's relics keep ranges (`min`/`max`) for some bonuses, narrowed and raised (Caerme's fire damage 30–40, 1.32's 1–10); the port carries them as legacy has them. Torlara and Torzirael lose `MA_Indestructible` from their ability lists, as in legacy (attributed to SWD-03 by the mapping although durability is ITEM's; confirmed by the owner, 2026-10-19).

**Slices:**

1. **Relic and unique swords** (5.x-GM `d1f1170a`; `gen_swd_items.py` with SWD-03). `--verify`: 0 unexplained differences. Verified 2026-10-19 in both trees (test save; `GMTest_swd03` in the regression run, scripted reads of the definitions and a tooltip): Caerme's 15% burning, fire damage from 30 and adrenaline gain from 0.1; Gwyhyr's crit chance from 0.25, armor penetration from 30, crit damage from 0.3; Hjalmar's sword 25% crit chance, +75% crit damage, +10% attack power; Blood and Wine's unique silver sword (an expansion ability given whole) +100% crit damage and 20% burning, its level range 5.x's (ITEM); the crafted Harpy's 340 silver damage and legacy's ability list; Torlara and Torzirael without indestructibility; Longclaw's icon; Deireadh's crit chance in its tooltip and Axii intensity from 0.08. Real attack (classic tree, level 30, the crafted Harpy equipped by script, drawn, a real light attack through the input handler on a neutral wolf dummy, the damage probe): raw silver damage 369 for the sword's 340 (vanilla's random 0.9 to 1.1 per melee hit, `W3Action_Attack.AddDamage`). Not in game: the relics' NG+ entries (`--verify`). The Wolf relic's and Torzirael's `anim_actions`: [audit](#swd-audit-2026-10-19) F1, fixed ([SWD-08](#swd-08-sword-fixes) slice 1).

**Fix round fix3 (2026-11-02, sweeps B and D G7; the owner's decision): the Caretaker's Shovel heals on every enemy type**, as legacy and its description: its lifesteal (0.1 × the hit's damage) moves from 5.x's `CR4Player.OnProcessActionPost`, which read Geralt's own `UsesEssence()` for a victim on Essence and so healed nothing on monsters and specters, to the victim's `CActor.OnTakeDamage` (`mutations/takeDamage.ws`), which reads the victim's health type (legacy's lines). `swords/caretakerShovel.ws` replaces `OnProcessActionPost` without 5.x's block, so a hit heals once. **verified on the area build** (2026-11-02, gm/fix3 `51bce9eb`, both trees): `GMTest_swd03_shovel` (regression; scripted hits with the shovel as the weapon on a frozen bandit and wraith): +10.6 on the bandit for 10.6 expected, +9.06 on the wraith for 9.06; it failed first on a throwaway build with b3ec3609's code and data (gm/fix3-ff `efa40f24`, classic tree; the code checks also in the new tree) (the bandit healed, the wraith 0). A real swing: not tested.


### SWD-04 Witcher school swords

| | |
|---|---|
| Kind | tuning |
| Pillars | P4, P8 |
| 5.x class | clean |
| Flags | balance |
| Depends on | SWD-01, ARM-05 to ARM-11 (set tags, signed off), CRAFT (schematics) |
| Skill trees | n/a |
| Port form | the generator (SWD-01); the set swords' entries carry ARM's set tags (`gen_arm_items.py` hands them to `gen_swd_items.py`) |
| Port status | **signed off** (2026-10-19); **ported, verified** (2026-10-19, both trees) |
| Open checks | NG+ (`--verify`) |
| Save impact | none (expected) |
| NG+ counterpart | applied, untested (NG+ bonuses: SWD-07) |

**What it does:** each school's swords carry their set's theme, rising with the tier: Feline crit chance 15–35% and bleeding 15–30%; Griffin sign intensity +10–30% and 20–60 fire damage; Bear attack power +20–40% and adrenaline gain +15–30%; Wolven (DLC and grandmaster) attack power +15–30% and sign intensity +10–25%, one more slot on the first tiers; Viper (Hearts of Stone) poison and armor penetration 60; Manticore armor penetration 80 with resistance reduction and adrenaline +25%; the Feline sword from the free DLC quest (`mq1058_cat_school_sword`) likewise. Damage follows SWD-01 at each tier's level (a little below vanilla's at the same tier). The ledger's school-set sections list the per-tier values.

**Implementation (legacy):** the school sword abilities and items in `def_item_crafting_weapons.xml` (base game, EP1, BaW), `dlc10_wolf_swords.xml`, `def_item_dlc15_weapons.xml`; the items' set tags are ARM's (ARM-05 to ARM-11, attributed to both).

**5.x:** unchanged.

**Decisions:** port as legacy; ARM's hand-off ("set swords' stats").

- **Deviation:** the NG+ Wolven swords' damage reduction (`NGP Wolf Steel/Silver Sword Mod`, which 5.x's `NewGamePlusAdjustDLCItem` adds to owned NG+ Wolven swords), deleted by legacy, is given empty, which is what the deleted ability did; 5.x adds the same abilities to the NG+ Netflix swords, whose reduction stays emptied too (confirmed by the owner, 2026-10-19, with SWD-10's rules).

**Slices:**

1. **School swords** (5.x-GM `5f8bebdd`; `gen_swd_items.py` with SWD-04; the school swords' entries carry ARM's set tags). `--verify`: 0 unexplained differences; `gen_arm_items.py --verify` 0. Verified 2026-10-19 in both trees (test save; `GMTest_swd04` in the regression run, scripted reads of the definitions): the Feline steel sword 161 damage (level 17), 15% crit chance and bleeding; the grandmaster Griffin silver sword 490 silver damage (level 40), +30% sign intensity, 60 fire damage, its set tags; the superior Ursine steel sword +35% attack power, +25% adrenaline gain, its minor set tag; the Manticore steel sword armor penetration 80, resistance reduction 15%, adrenaline +25%; the free DLC's Wolven silver sword 3; the Viper steel sword's poison and legacy's look and icon. Real attack (classic tree, level 40, the superior Ursine steel sword equipped by script, drawn, a real light attack through the input handler on a neutral test dummy, the damage probe): raw slashing 277 for the sword's 298 and attack power ×1.35, the sword's +35%. Not in game: NG+ entries (`--verify`).

### SWD-05 Aerondight

| | |
|---|---|
| Kind | system |
| Pillars | P1, P8 |
| 5.x class | clean |
| Flags | — |
| Depends on | DMG-02, DMG-03, DMG-04, DMG-08 (the terms they host for SWD), MUT-02 (Conductors of Magic reads the sword damage with the per-enemy bonus) |
| Skill trees | n/a |
| Port form | `swords/aerondight.ws`: `@replaceMethod`s of `W3Effect_Aerondight`'s `LoadParams`, `OnEffectAdded`, `OnUpdate`, `IncreaseAerondightCharges`, `UpdateAerondightFX`, `DischargeAerondight`, `OnPaused`, `OnResumed`, `StopAerondightEffects` (5.x's fields serve legacy's: `m_currCount` the charges, `m_maxCount` the hits to charge, `m_aerondightDelay` the decay), legacy's other methods added (`GMAddCharge`, `GMDischargeAerondight`, ...), wrappers of `ManageAerondightBuff`, `OnSpawned`, `OnCombatStart`, `OnCombatFinished`, `EquipItemInGivenSlot`, the replaced `W3TooltipComponent.GetAerondightTooltipDescription`; the terms in the replaced `ProcessAction` (`defense/processAction.ws`), `GetTotalWeaponDamage` (`damage/weapon.ws`), `GetAttackersPowerMod` and `GetDamageResists` (`damage/formula.ws`), `OnTakeDamage` (`mutations/takeDamage.ws`), 5.x's pool term (`damage/pool.ws`) and kill charges (`enchantments/npcDeath.ws`) removed; the certain crit through 5.x's `crit_chance_bonus` term in `ProcessCriticalHitCheck` (1, legacy's code set the chance to 1); `AerondightEffect` given whole in the DLC's `abilities/gm_swords.xml` (NG+ copy by `gen_ngplus.py`); strings 2110992291, 2110992292 |
| Port status | **signed off** (2026-10-19); **ported, verified** (2026-10-19, both trees) |
| Open checks | the HUD counter and the sword's glow per charge on screen |
| Save impact | none (expected; an Aerondight carried from a vanilla save keeps its `PermDamageBoost` modifier, which legacy ignores: unsupported case) |
| NG+ counterpart | applied, untested (`abilities_plus`) |

**What it does:** changelist 643–648. While in combat Aerondight's weapon damage rises by 10 per hostile enemy in range. Each successful hit adds a charge (4 to charge it fully); a charge decays every 6 s, and all are lost when Geralt takes damage. A fully charged Aerondight's next hit is a certain critical hit with +100% crit power that ignores armor and resistances; it discharges, dealing 100 shock damage and a stagger to hostile enemies within 3 m. Vanilla's permanent damage growth (stacks per level stored on the item), the +10% damage and +100% crit chance, and the charge on finishers and discharge on kills are gone. The effect exists only in combat; sheathing the sword pauses it and resets its charges. Its visual effects map legacy's 4 charges onto vanilla's 10 stages.

**Implementation (legacy):** `aerondight.ws` (28 units, new `InitXmlValues`, `AddCharge`, `RemoveCharge`, `DischargeAerondight` with the shock, `GetDamageBoost`, `GetCritPowerBoost`, `Modded2Vanilla`), `AerondightEffect` values (`crit_dmg_bonus` 1, `dmg_boost_per_enemy` 10, `collateral_dmg` 100, `hitsToCharge` 4, `stackDrainDelay` 6), `ManageAerondightBuff`, the damage functions, `GetAerondightTooltipDescription`.

**5.x:** unchanged from 1.32. DMG ported its functions with 5.x's (vanilla's) Aerondight terms as temporary deviations until SWD: the pool term, the crit chance, the armor and resistance ignore, the damage in `GetTotalWeaponDamage` ([dmg.md](dmg.md), DMG-02, DMG-03, DMG-04, DMG-08).

**Decisions:** port as legacy (5.x did not change it). Blood and Wine's Aerondight is the item `Aerondight EP2` (tag `Aerondight`); the base game's relic named `Aerondight` (shown as Maugrim) is a relic (SWD-03), whose `Aerondight_Stats` the mapping had given SWD-05 (corrected in the attribution). The effect shows on the HUD when added (legacy's effect definition has `showOnHUD`; 5.x's definition, which a DLC cannot override, only after a resume: the port sets it in `OnEffectAdded`).

**Slices:**

1. **Aerondight** (5.x-GM `3a21e7a1`). Verified 2026-10-19 in both trees (test save, level 40, `Aerondight EP2` equipped by script, neutral drowner test dummies, real light attacks through the input handler, the damage probe and `gmtest_swd05_state`): no effect out of combat, the effect when the sword is drawn in combat, +10 weapon damage per hostile enemy (20 with two); the charges from real hits, 4/4 after four, then a critical hit with attack power ×2.25 (Geralt's crit power +1.0 from Aerondight) that ignored the dummy's 50 armor (the uncharged hit had it), the other dummy within 3 m took 100 shock damage and was staggered, the charges back to 0; a charge lost every 6 s (3, 2, 1, scripted charges); all lost on a hit taken (`hitme`, scripted); the effect removed when combat ended. `GMTest_swd05` in the regression run: the values, no effect out of combat, the description with its counter. Not in game: the HUD counter and the sword's glow per charge (on screen), the tooltip on screen (read by script), NG+.

### SWD-06 Iris

| | |
|---|---|
| Kind | system |
| Pillars | P1, P8, P9 |
| 5.x class | clean (`CActor.PrepareAttackAction` changed by 5.x: hand merge) |
| Flags | — |
| Depends on | DMG-02, DMG-08 (terms they host), DEF-01 (the phantom strike undodgeable, DEF's hand-off), effect framework (an enum extension, as ENCH's `EET_GMRuneword4`) |
| Skill trees | n/a |
| Port form | `swords/iris.ws`: legacy's effect as `W3GMEffect_PhantomWeapon` (`EET_GMPhantomWeapon`, an enum extension registered in `effects/gmEffectRegistration.ws`), `GMManageIrisBuff` (`@addMethod`, legacy's `ManageIrisBuff`) called from wrappers of `OnCombatStart`, `OnCombatFinished`, `OnSpawned`, `EquipItemInGivenSlot`, `UnequipItemFromSlot`, `WeaponHolsterStateSelectingWeapon.OnEquippedMeleeWeapon` and `CR4Player.OnHolsteredItem`; `@replaceMethod`s of `CActor.DoAttack`, `CActor.PhantomWeapon` (timer) and `CActor.PrepareAttackAction`; `CR4Player.InitPhantomWeaponMgr` replaced empty (vanilla's `CPhantomWeaponManager` is never created, so the holster's discharge finds nothing); the terms in the replaced `ProcessAction` (`defense/processAction.ws`: `GMIrisOnHit`), `GetDamageResists` (`damage/formula.ws`: source `PhantomWeapon`), `GetTotalWeaponDamage` (`damage/weapon.ws`), `W3PlayerWitcher.OnTakeDamage` (`mutations/takeDamage.ws`), the HUD counter (`mutations/hudCounters.ws`); the description through a wrapper of `W3TooltipComponent.GetBaseItemData`; `GMPhantomWeaponEffect` (legacy's `PhantomWeaponEffect`) with its HUD icon in the DLC's `abilities/gm_swords.xml` (NG+ copy by `gen_ngplus.py`); string 2110992299 (key `attribute_name_double_strike`, vanilla's key for Iris's description); Olgierd's and the player's Iris items by `gen_swd_items.py` |
| Port status | **signed off** (2026-10-19); **ported, verified** (2026-10-19, both trees) |
| Open checks | the HUD counter and the sword's charged glow on screen; whether the phantom strike gets through a guard in play ([to test in legacy](../open-questions.md#to-test-in-legacy-ghost-mode)); Olgierd's phantom strike on Geralt |
| Save impact | none (expected; the effect is a saved buff: after removing the mod an unknown effect stays on Geralt, unsupported) |
| NG+ counterpart | applied, untested |

**What it does:** changelist 637–642. Damaging hits with Iris on a hostile charge it (4 for a full charge, shown on the HUD); a charge decays every 6 s (a full charge decays at once), all are lost when Geralt takes damage. The effect exists only in combat while Iris is drawn (paused, and its charges reset, while sheathed; removed when combat ends). While fully charged, Iris's slashing damage rises by 5% of Geralt's maximum Vitality (capped at his current Vitality), drained from him when the hit lands. A strong attack with the charged sword is a phantom strike: its hits, and the phantom copy's strike right after, cannot be dodged, are not parried, ignore armor and resistances, stagger (vanilla: a heavy knockdown) and destroy shields; they discharge the sword. Vanilla's discharge by the holster code (its manager) is gone; sheathing resets the charges through the pause, as legacy. Olgierd's own Iris (an NPC's) performs the phantom strike on every strong attack (vanilla's).

**Implementation (legacy):** `phantomWeapon.ws` (new, 20 units), `phantomWeaponManager.ws` removed (11), `CR4Player.ManageIrisBuff`, `OnHolsteredItem`, the phantom manager's creation removed (`OnSpawned`, `InitPhantomWeaponMgr`, ...), `CActor.DoAttack`, `PhantomWeapon`, `PrepareAttackAction`, the holster states, `ProcessAction` (charge and discharge), `GetDamageResists`, `GetTotalWeaponDamage`, the HUD and tooltip functions; `PhantomWeaponEffect` (`dmg_bonus_prc` 0.05, `hitsToCharge` 4, `stackDrainDelay` 6).

**5.x:** Iris unchanged from 1.32; `CActor.PrepareAttackAction` changed by 5.x for other reasons (the `ParryingAttack` event, kept).

**Decisions:** port as legacy. Legacy's code, ported as it is: `DoAttack` decides the phantom strike before the strong attack's own hits (vanilla only for the copy's), so a charged strong attack lands two phantom hits, the first with the Vitality bonus and the drain; the copy's strike gives Geralt `ForceDismemberment` until a phantom hit discharges the sword (if that hit is not processed, for example on a target the first hit killed, the ability stays until the next discharge); the phantom hits' parry flag is cleared (`SetIsParried(false)`, as vanilla's phantom strike), so in the code they go through a parry, as the changelist says; whether that holds in play stays a [legacy test](../open-questions.md#to-test-in-legacy-ghost-mode). The phantom hits' resistance ignore checks only the source, so it also covers Olgierd's phantom strikes on Geralt (legacy).

- Iris is level-scaled (legacy's `Autogen`, no fixed damage; about 225 at level 25, read in game) since [ITEM-04](item.md#item-04-items-moved-to-level-scaling) (2026-10-19), which ended the deviation kept until ITEM.
- Starting NG+ keeps Iris, as legacy (`NewGamePlusReplaceEP1` without the swap) since ITEM-04 (2026-10-19), which ended the deviation kept until ITEM; `NGP Olgierd Sabre` stays defined (a DLC cannot remove an entry).

**Slices:**

1. **Iris** (5.x-GM `4845a197`). Verified 2026-10-19 in both trees (test save, level 40, `Olgierd Sabre` equipped by script and drawn, a neutral human test dummy with armor 50, real light and strong attacks through the input handler, the damage probe, `gmtest_swd06_state` and a test probe logging each melee hit): the effect when drawn in combat (none out of combat or equipped out of combat, `GMTest_swd06`); four real light hits charged it 1, 2, 3, 4/4, the charged slashing damage 363 + 283.75 (5% of 5675); a real strong attack then landed two hits with source `PhantomWeapon`, not dodgeable, not parried, with a stagger, both with armor 0 (a light hit: armor 50), Geralt's Vitality drained by about 5%, the charges back to 0 and no `ForceDismemberment` left; a charge lost after 6 s, a full charge lost at once (scripted charges); all lost on a hit taken (`hitme`); the effect gone when combat ended; no vanilla manager. `GMTest_swd06` in the regression run: the values, the charges and damage boost by script, the description with its numbers and counter. Not in game: the HUD counter and the glow (on screen), the tooltip on screen (read by script), a guarding or shielded enemy, Olgierd's strike, NG+.

### SWD-07 NG+ sword and sign damage bonuses

| | |
|---|---|
| Kind | tuning, system |
| Pillars | P1 |
| 5.x class | clean |
| Flags | — |
| Depends on | SWD-01, SWD-04, DMG-04 (the pool) |
| Skill trees | n/a |
| Port form | the generator's `items_plus` output; the two pool terms in DMG's `ProcessDamageIncrease` (`damage/pool.ws`); tooltip rows `sword_dmg_bonus`, `spell_dmg_bonus`; strings 2110992161, 2110992162 (legacy's rows in all 9 languages, by id: legacy's br, de, es, fr, it and pl tables give their keys as hashes) |
| Port status | **signed off** (2026-10-19); **ported** (2026-10-19, both trees; NG+ untested by policy: checked by `--verify` and scripted reads) |
| Open checks | NG+ in play |
| Save impact | none (expected) |
| NG+ counterpart | this feature is NG+ only: [not balanced or tested](../feature-mapping.md#new-game-carried-over-and-scaled-not-balanced-or-tested) |

**What it does:** a change legacy made only in its NG+ files ([rule](../feature-mapping.md#new-game-carried-over-and-scaled-not-balanced-or-tested)): the NG+ witcher school swords keep the damage-by-level rule at their NG+ levels (vanilla NG+ gives them higher flat damage, and `NGP Wolf Steel/Silver Sword Mod` lowered it) and add `sword_dmg_bonus`, +5 to +25% weapon damage by tier (Feline, Bear, Wolven), and `spell_dmg_bonus`, +5 to +25% sign damage (Griffin, Wolven); both are additive terms of the raw-damage pool, shown in the tooltip and the character panel.

**Implementation (legacy):** the NG+ school sword abilities (`items_plus/def_item_crafting_weapons.xml`, BaW's, `dlc10_wolf_swords.xml`'s `NGP` entries), `ProcessDamageIncrease`, `GetOffenseStatsList`.

**5.x:** unchanged. DMG-04 keeps the two pool terms as a temporary deviation until SWD.

**Decisions:** port as legacy (NG+ is carried over, not tested; DS4).

- The character panel's sword lines include `sword_dmg_bonus` (UI-01) and its sign lines `spell_dmg_bonus` (UI-03, 2026-10-21, 5.x-GM `52db5ef7`): the temporary deviation has ended.

**Slices:**

1. **NG+ bonuses** (5.x-GM `f4a5b6a9`; `gen_swd_items.py` with SWD-07: the NG+ school swords' and the free DLC's NG+ Wolven swords' abilities, 16 regular and 52 NG+ differences now ported). `--verify`: 0 unexplained differences. Checked 2026-10-19 in both trees by script (`GMTest_swd07` in the regression run): the free DLC's NG+ Wolven swords, which its regular items file defines too, read `sword_dmg_bonus` 0.05 to 0.2 and `spell_dmg_bonus` up to 0.2, and their tooltips list "Weapon damage" and "Sign damage". Not in game: the pool terms on a hit (NG+, untested by policy; the code is legacy's two terms), the panel (deviation above).
2. **Legacy's strings** (5.x-GM `c934ee50`, [audit](#swd-audit-2026-10-19) F2): the porter's translations of the two strings in br, es, fr, it and pl replaced by legacy's rows (de was already legacy's). Checked 2026-10-19: `gen_swd_items.py --verify` compares SWD's nine strings with legacy's rows in all nine tables (equal; the tables' ids alike), the built tables decoded (`w3strings.py decode`) give legacy's texts, and `GMTest_swd07` reads the two strings in game in both trees (English: "Weapon damage", "Sign damage"). Not in game: the other languages (the game runs in English; by `--verify` and the decoded tables).

### SWD-08 Sword fixes

| | |
|---|---|
| Kind | fix |
| Pillars | P8 |
| 5.x class | partly in-5.x |
| Flags | — |
| Depends on | SWD-01 (the same item entries) |
| Skill trees | n/a |
| Port form | the generator (display fields, as ARM's) |
| Port status | **signed off** (2026-10-19); **ported, verified** (2026-10-19, both trees): the icons, looks and draw attributes ([SWD-01](#swd-01-sword-damage-by-item-level) slice 1, SWD-03, SWD-04); the Wolf relic's and Torzirael's `anim_actions` blocks with the [audit](#swd-audit-2026-10-19)'s F1 fix (5.x-GM `c934ee50`) |
| Open checks | the Wolf relic's draw and holster sounds and animation (on screen) |
| Save impact | none (expected) |
| NG+ counterpart | applied, untested |

**What it does:** the missing silver-to-steel draw animations of crafted silver swords (changelist 107: Harpy, Negotiator, Weeper), Torzirael's animations and the Wolf relic's draw and holster sounds fixed; mixed-up inventory icons of swords fixed (changelist 39, "by other modders"; the crafted Short, Inquisitor, Longclaw, Viper, standalone and Witcher silver swords).

**5.x:** fixed the three crafted silver swords' animation switch the same way; not the others.

**Decisions:** port what 5.x lacks; legacy's edits of the three swords are dropped as in-5.x (DS3, project owner, 2026-10-19).

**Slices:**

1. **The Wolf relic's and Torzirael's animations** (5.x-GM `c934ee50`, [audit](#swd-audit-2026-10-19) F1; `gen_swd_items.py` carries the `anim_actions` and `anim_switches` blocks legacy changed, and `--verify` compares every child block). Verified 2026-10-19 in both trees (test save; `gmtest_swd08_draw()` and `gmtest_swd08_holster()`: the sword equipped by script in the silver slot, drawn and sheathed through `OnEquipMeleeWeapon`, the behaviour graph's activation notifications and the held state logged): Geralt's graph sends `draw_steel_sword_back_act` and `holster_steel_sword_back_act` for every sword drawn from the back, silver ones included; the fixed Wolf relic is in hand after 0.12 s and back on the back after 1.07 s, as Torzirael and the Witcher silver sword. The build before the fix (the relic's acts the silver ones, which the graph never sends), same test: a holster waited about 4 s or left the sword in hand, and one draw took 2 s. Not in game: the sounds and the animation on screen.

### SWD-09 Sword tooltip rows and attribute names

| | |
|---|---|
| Kind | ui |
| Pillars | P7 |
| 5.x class | clean |
| Flags | — |
| Depends on | ENCH-17 (the item tooltip fix, signed off), UI (the panel) |
| Skill trees | n/a |
| Port form | `tooltip_settings.csv` (whole-file override, `5.x-GM`'s copy: `dismember_chance` replacing `dismember_chance_mult`, `armor_reduction_perc` added), strings 2110992014, 2110992154, 2110992155, 2110992440 in the mod's table (9 languages, legacy's ids and keys) |
| Port status | **signed off** (2026-10-19); **ported, verified** (2026-10-19, both trees; [SWD-01](#swd-01-sword-damage-by-item-level) slice 1); SWD-07's two rows ported with SWD-07 |
| Open checks | the tooltips on screen (read by script) |
| Save impact | none |
| NG+ counterpart | none |

**What it does:** the swords' new stats show in their tooltips: rows for resistance reduction (`armor_reduction_perc`) and dismember chance (`dismember_chance`, replacing `dismember_chance_mult`), with the names "Enemy damage resistance reduction", "Armor penetration" (two vanilla string ids overridden) and "Dismember chance". "Main damage related bonuses from swords ... are shown when the sword is sheathed, ... sign power only when unsheathed" (changelist 1172–1174) is vanilla's tooltip behaviour.

**5.x:** unchanged.

**Decisions:** port with the slices.

### SWD-10 5.x's new swords

| | |
|---|---|
| Kind | content, tuning |
| Pillars | P6, P8 |
| 5.x class | rethink |
| Flags | balance (decided by the owner, 2026-10-19) |
| Depends on | SWD-01 to SWD-04, ARM-15 (the Netflix set's tags and bonuses, signed off) |
| Skill trees | n/a |
| Port form | `gm_swd_items.xml` (`items/`, `items_plus/`) by `tools/gen_swd_items.py` (its `SWD10` table, the owner's values): each sword's `_Stats` ability rebuilt from 5.x's (weight, quality and the secondary damage node kept; the main damage by level; the decided stats only), its items given whole with the decided slots; the Netflix swords' items carry ARM-15's set tags (`gen_arm_new.py` hands them over through `minor_tags`, so each sword has one entry); `--verify` checks every stat, the damage against the decided levels, the slots, the set tags and that each entry is defined once |
| Port status | **signed off** (2026-10-19); **ported, verified** (2026-10-19, both trees) |
| Open checks | a burning or bleeding proc from the new swords; the tooltips on screen; NG+ (`--verify`). The owner's request to compare their power with similar legacy swords (2026-10-19) is answered by the [audit](#swd-audit-2026-10-19) F10: the White Widow raised, the others kept |
| Save impact | none (verified: swords owned before SWD-10 read the new stats and slots) |
| NG+ counterpart | applied, untested: 5.x's `items_plus` entries (there its `NGP` swords hold 5.x's regular values, the regular names its NG+ values) by the [NG+ rule](../feature-mapping.md#ng-numbers): the level moves by the difference between the levels of 5.x's NG+ and regular damage (the Forgotten Wolven swords 51/65/71 steel, 49/63/71 silver), another stat takes the ratio of the 5.x stat it replaces where 5.x has it in both, else Ghost Mode's value |

**What it does:** 5.x's swords under Ghost Mode's sword rules (legacy has none of them). 5.x's versions and their nearest legacy counterparts:

| 5.x sword | 5.x stats (level by 5.x's `GetItemLevel`) | Nearest legacy sword | Legacy's stats |
|---|---|---|---|
| Netflix steel sword, tiers 1–3 ("Forgotten Wolven"), Reinald's = tier 1 | 201/318/372 (21/35/41), crit 5–7%, crit damage +10–20%, sign intensity +5–7%, adrenaline +6–10%, bleeding 5%, XP 5–10%, 2–3 slots | Wolven School steel sword tiers (21–40) | 194–345, attack power +15–30%, sign intensity +10–25%, 2–3 slots |
| Netflix silver sword, tiers 1–3, Reinald's = tier 1 | 314/449/524 (21/35/41), crit 5–15%, crit damage +15–35%, sign intensity +5–10%, adrenaline +3–7%, bleeding 4–10%, XP 5–10% | Wolven School silver sword tiers | 301–490, same themes |
| Dol Blathanna longsword (steel) | 91 (8), crit 5%, crit damage +10%, Aard +1%, armor penetration 5, XP 5%, 1 slot | crafted swords at level 9 (Novigradian sword 1: 97, crit damage +20%) | 97–105, one or two bonuses |
| White Widow of Dol Blathanna (silver) | 171 (8), crit 5%, crit damage +10%, Igni +1%, XP 5%, 1 slot | crafted silver swords | level × 10 + 90 |
| Steel Vixen | 121 (12), crit 10%, bleeding 5%, dismember 5%, 1 slot | relic at level 12 (e.g. Angivare: crit 15%, crit damage +20%, bleeding 10%) | damage by level, a theme |
| Silver Vixen | 213 (12), crit 11%, bleeding 6%, 1 slot | relic silver swords | damage by level, a theme |
| Top Notch steel / silver | level-scaled (`Autogen`), quality 4, steel crit 10% and crit damage +10%, silver sign intensity +15%, no slots | level-scaled relics | fixed theme, 3 slots |

**Decisions:** DS1 and DS2 (project owner, 2026-10-19): Ghost Mode's sword rules with themes like the comparable legacy swords. The per-sword rules (project owner, 2026-10-19): every sword gets damage by level and loses its XP-on-kill bonus;

- **Netflix "Forgotten Wolven" swords**, tiers at levels 21/35/41, steel and silver the same: attack power +15/25/30%, Yrden intensity +10/20/25%, adrenaline gain +5/7/10%, 2/3/3 slots; no crit, bleeding or XP (5.x's bleeding dropped). Reinald's pair are identical to tier 1. Their NG+ copies follow the same rules; 5.x's NG+ damage reduction (`NGP Wolf * Sword Mod`) stays emptied, as for the Wolven swords.
- **Dol Blathanna** (relics, level 8): steel, Sword of a Thousand Flowers: Aard intensity +10%, armor penetration 20, crit damage +20%, dismember 10%; silver, White Widow of the Valley of Flowers: Igni intensity +10%, fire damage 25, burning chance 8% (raised from 15 and 5% by the owner's decision on the [audit](#swd-audit-2026-10-19)'s F10, 2026-10-19), dismember 10%; 2 slots each.
- **Nine-Tailed Vixen** (relics, level 12): both crit chance 15%, crit damage +25%, bleeding 10%, dismember 10%, 2 slots; the silver one also adrenaline gain +5%.
- **Top Notch** (an account reward; level-scaled relics), keeping the generic names "Witcher's steel/silver sword": steel crit chance 10–20%, crit damage +20–40%, dismember 10%; silver sign intensity +8–15%, crit damage +15–30%, dismember 10%; 3 slots each. The steel one is measured against Headtaker, which it matches (audit F10), and stays as it is (the owner's decision, 2026-10-19).

Porter's calls on the details (each confirmed by the owner, 2026-10-19, audit F11):

- Each sword's list above is its whole set of bonuses, as legacy's fixed themes are: 5.x's other bonuses go, including Dol Blathanna's 5% crit chance and the Vixen's `dismember_chance_mult` (replaced by the decided `dismember_chance`, SWD-09's stat) (confirmed by the owner, 2026-10-19). Damage by level: steel 25 + 8 × level, silver 90 + 10 × level (Forgotten Wolven 193/305/353 and 300/440/500, Dol Blathanna 89 and 170, Vixen 121 and 210); the level-scaled Top Notch swords keep no fixed damage (the per-level abilities give it, as for legacy's level-scaled relics). An effect chance is written as legacy writes it (the effect, `buff_apply_chance` and its tooltip stat); quality, weight and names stay 5.x's.
- NG+ as in the table above: 5.x's NG+ Forgotten Wolven stats equal its regular ones, so their bonuses are the regular values; Dol Blathanna's NG+ armor penetration 60 and crit damage +30%, the Vixen's NG+ bleeding 20% (steel) and 25% (silver), the silver Vixen's crit chance 14% (confirmed by the owner, 2026-10-19).

**Slices:**

1. **5.x's new swords** (5.x-GM `9b2e2648`; `gen_swd_items.py` with SWD-10; the Netflix swords' items moved from `gm_arm_new.xml`). `--verify`: 0 unexplained differences (14 regular and 24 NG+ items, 12 and 22 abilities against the owner's values; the legacy units still 0). Verified 2026-10-19 in both trees (test save; `GMTest_swd10` in the regression run, scripted reads of the definitions and a tooltip): every sword's damage, bonuses, missing XP and slots as above, the Forgotten Wolven tooltip's "Yrden Sign intensity" row, the Top Notch swords' ranges and `Autogen` tag, ARM-15's set tags. Real attacks (light attacks through the input handler on neutral test dummies, the damage probe): classic tree, level 25, the first-tier Forgotten Wolven steel sword: raw slashing 194.9 for its 193, attack power x1.15; the Top Notch steel sword (level-scaled, 206 at level 22): raw 192.4; new tree, level 35, the second-tier Forgotten Wolven steel sword: raw 319.4 for its 305, attack power x1.25; the Top Notch silver sword on a wolf dummy: raw silver 423.9. Set count (both trees, worn by script, `gmtest_arm15_wear`): the six top-tier pieces with both grandmaster swords count 6 and give both bonuses; two first-tier armor pieces and Reinald's sword count 3 (classic tree). Save impact: a save made with the build before SWD-10 holding six of the new swords (`<save name>`), loaded: each reads the new bonuses and slots (`gmtest_swd10_owned`; its level, computed from the damage, the new one), the owned Top Notch steel sword's crit chance re-rolled inside the new range (0.187). Not in game: NG+ (`--verify`), a burning or bleeding proc from the new swords, the tooltips on screen.
2. **The White Widow raised** ([audit](#swd-audit-2026-10-19) F10, the owner's decision; 5.x-GM `0e524ca1`; `gen_swd_items.py`'s `SWD10` table): fire damage 25 and burning chance 8%, regular and NG+ (5.x has neither stat on the sword, so NG+ takes the same values). `--verify`: 0 unexplained. Verified 2026-10-19 in both trees (`GMTest_swd10` in the regression run, scripted reads of the definitions): silver 170, Igni +10%, fire 25, burning 0.08, dismember 0.10, no XP, 2 slots. Not in game: a burning proc, NG+.

### SWD audit (2026-10-19)

Done by a fresh session ([audit](../feature-mapping.md#audit-signing-a-feature-off)) on 5.x-GM `9b2e2648` and master `18183c02` (regression 510 passed, 0 failed in each tree, as recorded by the port), reading code and data only; no game run (every finding below is plain in the code or the data). Every script unit attributed to SWD-05 to SWD-07 (`aerondight.ws`, `iris.ws`, the terms in `processAction.ws`, `formula.ws`, `weapon.ws`, `pool.ws`, `takeDamage.ws`, `npcDeath.ws`, `hudCounters.ws`, the effect registration) was read against legacy's code (`legacy-GM`: `aerondight.ws`, `phantomWeapon.ws`, `actor.ws`, `damageManagerProcessor.ws`, `r4Player.ws`, `playerWitcher.ws`, `playerWeaponHolster.ws`, `guiTooltipComponent.ws`), 1.32 and 5.x, every 5.x call site of Aerondight and of the phantom weapon manager followed to the port's replacement, and the entries against the changelist's Swords section (lines 614–649) and fixes (70–73, 104–108, 183, 657). The data was compared by an independent script (the auditor's, not `gen_swd_items.py`): for each of the 979 item and ability units [attribution.csv](attribution.csv) gives SWD, the entry the game reads (Ghost Mode's DLC over 5.x) against legacy's, every ability node but `weight` and `item_level_*`, every item attribute but name, price and weight, the tags but `DoNotEnhance`, `Autogen*` and `mod_*` (then those separately), the ability list, the look and, separately, every child block (`anim_actions`, `anim_switches`, `player_override`); the SWD-10 entries against the owner's text; the 9 strings in 9 languages against legacy's rows; `tooltip_settings.csv` against 5.x's and legacy's.

**Checked and holding:** 890 of the 979 units equal legacy's in every compared field; the other 89 are the recorded deviations (22 abilities whose fixed damage stays where legacy moved to damage by level, 6 NG+ entries legacy deleted or emptied), ARM's NG+ set-tag rule (57 NG+ school sword items; [ARM audit](arm.md#audit-close-out)) and 5.x's own fixes kept (the NG+ Ursine steel swords' steel icons, the `sq304`/`q402` description tags); Iris is among the 22 but not in the deviation's list (F3); the child-block comparison found F1. Aerondight equals legacy's code (charges from damaging hits on hostiles only, decay, reset on damage taken, the certain crit through 5.x's `crit_chance_bonus` 1 where legacy set the chance to 1, +100% crit power, the armor and resistance ignore, the discharge's 100 shock and stagger within 3 m, +10 damage per hostile within 30 m, no effect out of combat, 5.x's pool term, kill charges and permanent growth gone; every 5.x call site replaced or inert); Iris equals legacy's code (the effect, its charges, decay and drain, `DoAttack`, `PhantomWeapon`, `PrepareAttackAction` with 5.x's `ParryingAttack` event kept, the phantom source ignoring armor and resistances, vanilla's manager never created so none of its five call sites acts, the HUD counter, the description); SWD-07's two pool terms equal legacy's (`OnHold` swords, so only the drawn sword's bonus counts, as legacy); the SWD-10 entries match the owner's text sword by sword (damage 193/305/353 and 300/440/500, 89/170, 121/210, Top Notch level-scaled; every decided stat; slots 2/3/3, 2, 2, 3; no XP); the 7 description and attribute strings equal legacy's in all 9 languages; the tooltip CSV differs from 5.x's only in SWD-09's and SWD-07's rows; the other areas' temporary deviations waiting for SWD are all ended (DMG-02/03/04/08's Aerondight and Iris terms and DMG-04's `sword_dmg_bonus`/`spell_dmg_bonus`, DEF's undodgeable phantom strike; none in MUT or ARM; `deviations.py --unconfirmed` lists none "until SWD"); no skill is involved (no per-tree code; the checks ran in both trees); no leftovers in the code; `check_modsigns.py` clean (257 bodies, 0 unmarked), `deviations.py --check` current (94), `gen_swd_items.py --check` and `--verify` (0 unexplained), `gen_arm_items.py --verify`, `gen_arm_new.py --check`, `gen_ngplus.py --check`, `gen_ench.py --verify` clean; `unit_sweep.py` (aerondight, phantomweapon, olgierd, `sword_dmg_bonus`, `spell_dmg_bonus`, steelsword/silversword, the new swords' names) finds one unattributed SWD unit (F3) and otherwise weight-only, crossbow, NPC and ITEM units.

**Findings:**

1. **SWD-08's animation fixes on the Wolf relic and Torzirael are half ported** (clear fix). Legacy changed the Wolf relic's (`WitcherSilverWolf`) draw and holster actions to the steel sword's in both the item's attributes and its `<anim_actions>` block, and removed the stray `steel_to_silver` switch from Torzirael's `<anim_actions>` (legacy `def_item_weapons_relic.xml`, items at 3319 and 5550, both folders). The port carries the attributes but not the blocks: `gm_swd_items.xml:10690` still has the silver draw act and `:10616` Torzirael's switch, because `gen_swd_items.py:56` carries only `variants` and `base_abilities`, and `--verify` compares no child block, so it could not see it. SWD-08 and SWD-03 called these fixes ported (SWD-03's slice: "Not in game: the Wolf relic's draw animations"). Fix: carry the child blocks legacy changed (`anim_actions`, `anim_switches`; `player_override` differs only in whitespace), and compare every child block in `--verify`. **Fixed** (5.x-GM `c934ee50`; `tools/gen_swd_items.py` on master): both blocks carried in `items` and `items_plus`; `--verify` compares every child block (whitespace ignored; the dismantling parts and NPC scabbards counted as CRAFT's and AI's) and found exactly these four differences before the fix, none after; verified in game in both trees ([SWD-08](#swd-08-sword-fixes) slice 1).
2. **SWD-07's strings: legacy has all nine languages** (clear fix). The deviation says legacy has "Weapon damage" and "Sign damage" only in English, Czech and Russian; legacy's br, de, es, fr, it and pl tables have both rows too, with the keys given as hashes (`4a0f3f56`, `4f424deb` are `w3strings.key_hash` of `attribute_name_spell_dmg_bonus` and `attribute_name_sword_dmg_bonus`), which a search by key name misses. The port's own translations differ from legacy's in br, es, fr, it and pl (e.g. es "Daño del arma" for legacy's "Daño de armas", it "Danni dei Segni" for "Danno Segno"); de matches. Fix: legacy's six rows (the text keys can stay); the deviation then goes (its text is corrected with this audit to state the facts). **Fixed** (5.x-GM `c934ee50`): legacy's texts in br, es, fr, it and pl (the ids and text keys kept; the keys' hashes equal legacy's), the deviation removed; all nine tables have the same rows ([SWD-07](#swd-07-ng-sword-and-sign-damage-bonuses) slice 2).
3. **Iris keeps 5.x's fixed damage; legacy made it level-scaled** (owner decision). Legacy removed `PC Olgierd Sabre _Stats`'s 363 slashing damage and gave the item `Autogen` (legacy `ep1 def_item_weapons.xml:57, 453`, both folders); the port keeps 363 at any level (`gm_swd_items.xml:877`, `items_plus:1179`), the same rule as SWD-01's second deviation (the `Autogen` tags are ITEM's) but not in its list, which the owner confirmed by name. In play: legacy's Iris got damage for Geralt's level when obtained (about 300 at level 35, 342 at 40); the port's has 363 from the start, 5–20% more at Hearts of Stone's levels. Also not attributed: legacy's NG+ start no longer swaps Iris for `NGP Olgierd Sabre` (legacy `playerWitcher.ws:1440`, commented out); 5.x's still does (`playerWitcher.ws:1581`, `NewGamePlusReplaceEP1`), consistent with the NG+ entries kept (SWD-01's third deviation). Options: (a) confirm as a temporary deviation until ITEM, like the other swords (recorded with this audit in SWD-06, with the NG+ swap; when ITEM ports it, an owned Iris needs reacquiring to get a level); (b) give Iris legacy's `Autogen` tag and no fixed damage with SWD now, an exception to DS5. Recommendation: (a); Iris is the most-used of these swords, so the owner should know. **Decided** (project owner, 2026-10-19): (a), 5.x's fixed damage and 5.x's NG+ Iris swap confirmed as temporary deviations until ITEM ([SWD-06](#swd-06-iris)).
4. **Crafted swords roll random bonuses again** (owner decision). Legacy tagged every crafted sword `DoNotEnhance` (changelist 657: "Crafted items now have non-random bonuses"; SWD-02 says so); the tag is ITEM's (DS5), so the port's entries keep 5.x's tags. 5.x's `AddRandomEnhancementToItem` gives every new quality 2 or 3 sword Geralt or a merchant receives a random masterwork or magical weapon ability unless it has `DoNotEnhance`: 26 crafted swords (No Man's Land 3–4, Nilfgaardian 4, Novigradian 3–4, Skellige 2–4, Scoia'tael 2–4, Inquisitor 1–2, the dwarven steel 2 and silver 1–2, the gnomish 1–2 and gnomish silver 1–2, the elven silver 1–2, the crafted silver swords 4–7) and the Wild Hunt swords 3–4 now get 5.x's random bonus on top of legacy's fixed ones. Not recorded as a deviation. The same holds for ARM's crafted armor (legacy tags 39 entries in `def_item_crafting_armor.xml`, the port 18; ARM is signed off). Options: (a) carry `DoNotEnhance` on SWD's entries now (a tag on entries SWD already writes; 5.x honours it), and the same for ARM's crafted armor; (b) record a temporary deviation until ITEM. Recommendation: (a); swords crafted with a build before the fix keep their rolled bonus (test saves only). **Decided** (project owner, 2026-10-19): (a), in the regular and NG+ data, `--verify` comparing the tag. **Fixed** (5.x-GM `0e524ca1`; `gen_swd_items.py`, `gen_arm_items.py`, `gen_arm_km.py` on master): legacy's `DoNotEnhance` on every sword and armor piece legacy added it to (where legacy removed it, 5.x's tag stays: a deviation until ITEM in SWD-02 and ARM-01); it acts on the 26 crafted swords, the Wild Hunt swords 3–4 and 35 crafted armor pieces (quality 2 and 3); both `--verify` runs compare it (0 unexplained); verified in both trees ([SWD-02](#swd-02-generic-and-crafted-swords) slice 2, `GMTest_arm_dne`).
5. **The other level-generation tags stay 5.x's, unrecorded** (owner decision: confirm the deviation recorded with this audit). Legacy removed `AutogenForceLevel` or `AutogenUseLevelRange` from about 30 relic, unique, Toussaint, guard and Ofir swords, the Wolf DLC's Remorse and the Caretaker's shovel, and added `Autogen` to Damien's sword (an NPC's, `NoDrop`); 5.x's `GenerateItemLevel` uses these tags to clamp a found sword's level to its range or to the player's level. They are ITEM's (DS5, hand-off), and the port keeps 5.x's; recorded with this audit as a temporary deviation until ITEM in SWD-01. Recommendation: confirm. **Decided** (project owner, 2026-10-19): confirmed, temporary until ITEM.
6. **The docs say sheathing Iris no longer discharges it** (corrected with this audit). Both legacy and the port pause the effect when Iris is sheathed, and pausing resets its charges (`OnPaused`, `iris.ws:72-77`, legacy `phantomWeapon.ws`); what legacy removed is vanilla's holster discharge through the manager. Aerondight's entry did not say that sheathing resets its charges either (`aerondight.ws:96-102`, legacy the same).
7. **An open question answered** (corrected with this audit). The per-hit variation of a sword's raw damage (0.93 to 1.09 in the slices' hits) is vanilla's: `W3Action_Attack.AddDamage` multiplies every melee damage by a random 0.9 to 1.1 (5.x `attackAction.ws:193`; 1.32 and legacy the same). Moved to [development.md](../development.md#testing-in-game); the [open question](../open-questions.md) is deleted.
8. **Stale doc labels** (corrected with this audit): this page's unit-list status ("the audit comes next"); every entry's **Open checks** row said "—" while its slice listed what was not tested in game (now listed); SWD-08's port status (garbled, and partly ported, F1); SWD-02's quality ("1–2": legacy's crafted swords are quality 1 to 3, 13/16/10 of them, the crafted relics 4); SWD-10's open check (the auditor's note, answered by F10); [dmg.md](dmg.md) DMG-04's open checks (Aerondight's pool term, gone since SWD-05); the hand-off table (ITEM: Iris's and Damien's sword's `Autogen`, the level tags, legacy's rework of the random enhancements); [attribution.csv](attribution.csv) (`W3PlayerWitcher.NewGamePlusReplaceEP1` to SWD-06); the [status page](README.md#where-the-port-stands).
9. **Regression gaps** (clear fix, tests and tools). `--verify` compares no child block (F1 passed); nothing checks a crafted sword's `DoNotEnhance` (F4); `GMTest_swd05` does not assert `crit_chance_bonus` 1, which makes the charged hit a certain crit; `GMTest_swd07` checks that the strings exist, not their text (F2); `GMTest_swd03`'s header names the Wolf relic's draw animations, which it does not check (`gmTestsSwd.ws:135`). Fix: `--verify` over every child block; in the regression run, Aerondight's crit chance bonus, the Wolf relic's and Torzirael's draw actions, a crafted sword's tag (if F4 a), the two strings against legacy's text in the running language. **Fixed** (5.x-GM `c934ee50`; `gen_swd_items.py` on master; F4's tag after the owner's decision, 5.x-GM `0e524ca1`: `GMTest_swd02`, `GMTest_arm_dne`, both `--verify` runs): `--verify` compares every child block and SWD's nine strings with legacy's rows in all nine tables (it fails on the data before F1 and F2: 4 and 8 differences); `GMTest_swd05` asserts `crit_chance_bonus` 1; `GMTest_swd07` the two strings by id and key, and their English text when the game runs in English (the other languages by `--verify`); an item's draw actions cannot be read by script, so `GMTest_swd03`'s header now says so and points to `--verify` and the exec check `gmtest_swd08_draw()`. Regression 511 passed, 0 failed in each tree.
10. **The new swords' power against similar legacy swords** (owner decision; the owner's auditor note). Method: at the same level, a sword's score is its main damage × (1 + the damage-equivalent of its bonuses). Assumptions: damage by level for fixed swords (steel 25 + 8 × level, silver 90 + 10 × level), level-scaled relics at the autogen mean (22 + 8 × level, 86 + 10 × level); a range at its middle; crit chance and crit damage as the gain in expected crit damage over a character with 10% crit chance and +50% crit damage; attack power at full value; flat armor penetration at 0.5 × penetration ÷ damage (armored enemies about half the time); resistance reduction 0.6 × itself; extra elemental damage 0.8 × itself ÷ damage; bleeding and burning chance 0.3 × chance, poison 0.2 ×, stagger, freezing and confusion 0.15 ×; all-sign intensity 0.4 ×, one sign 0.1 ×; adrenaline gain 0.5 ×; each slot +4%; dismember chance and set bonuses (ARM's) not counted. Two variants checked the result: a sign build (sign intensity 0.8 ×, one sign 0.25 ×, adrenaline gain 0.3 ×) and a crit build (30% and +100% before the sword). Results (score; bonus equivalent):

    | Level | New sword | Score | Legacy swords | Score | New vs legacy |
    |---|---|---|---|---|---|
    | 21–22 steel | Forgotten Wolven 1 (193; AP 15%, Yrden 10%, adr 5%, 2 slots) | 244 (+27%) | Wolven 1 (194; AP 15%, signs 10%) / Griffin 2 (L18) / Griffin 3 (L26) | 246 / 213 / 304 | −1% vs Wolven |
    | 34–35 steel | Forgotten Wolven 2 (305) | 435 (+43%) | Wolven 4 (298) / Griffin 4 (297) | 432 / 394 | +1% / +10% |
    | 40–41 steel | Forgotten Wolven 3 (353) | 528 (+50%) | Wolven grandmaster / Griffin grandmaster (345) | 524 / 468 | +1% / +13% |
    | 21–41 silver | Forgotten Wolven 1–3 (300/440/500) | 380 / 627 / 748 | Wolven 1 / 4 / grandmaster | 382 / 625 / 745 | −1% to +0.5% |
    | 8 steel | Sword of a Thousand Flowers (89) | 109 (+22%) | Headtaker / Ultimatum / Dyaebl at level 8 | 109 / 108 / 121 | 0% / +1% / −10% |
    | 8 silver | White Widow (170) | 200 (+18%) | Addandeith / Gynvaelaedd at level 8 | 209 / 227 | −4% / −12% |
    | 12 steel | Steel Vixen (121) | 151 (+25%) | Headtaker / Angivare at level 12 | 149 / 167 | +1% / −10% |
    | 12 silver | Silver Vixen (210) | 267 (+27%) | Bloodsword / Arainne at level 12 | 272 / 266 | −2% / 0% |
    | any (20 shown) steel | Top Notch steel (crit 10–20%, crit damage 20–40%, 3 slots) | 231 (+27%) | Headtaker ("Headhunter") / Angivare / Gwyhyr | 230 / 257 / 299 | 0% / −10% / −23% |
    | any (20 shown) silver | Top Notch silver (signs 8–15%, crit damage 15–30%) | 340 (+19%) | Addandeith / Deargdeith / Anathema | 360 / 351 / 346 | −6% / −3% / −2% |

    No new sword is clearly overpowered. The Forgotten Wolven swords match the Wolven swords tier for tier for a sword build (their Yrden-only intensity trades for adrenaline gain); in the sign variant they fall 3–5% behind the Wolven swords and stay 4–5% ahead of Griffin's. Dol Blathanna's and the Vixen's swords sit with the lower legacy relics of their level (they have 2 slots to the relics' 3); the White Widow is the weakest (−4 to −12%: 15 fire damage and 5% burning are small at 170 damage). The Top Notch swords match Headtaker, a low relic, and the steel one is clearly below Gwyhyr (−23%, −25% in the crit variant): Gwyhyr is a top relic, the Top Notch swords an account reward available from the start. Options: (a) keep all values (they are comparable, within ±10% of their nearest legacy swords except where noted); (b) raise the White Widow to 25 fire damage and 8% burning (score about 209, level with Addandeith); (c) raise the Top Notch steel sword toward a mid relic (crit 15–25%, crit damage 25–50%, armor penetration 15–40: about Angivare's level). Recommendation: (b) for the White Widow, (a) for the rest; (c) only if the owner wants the account reward to match Gwyhyr rather than Headtaker. The assumptions (the weights especially) are an estimate, not a measurement. **Decided** (project owner, 2026-10-19): (b) for the White Widow, (a) for the rest; the Top Notch steel sword is measured against Headtaker, which it matches. **Fixed** (5.x-GM `0e524ca1`): the White Widow's fire damage 25 and burning chance 8%, regular and NG+, verified in both trees ([SWD-10](#swd-10-5xs-new-swords) slice 2).
11. **Porter's calls not confirmed by the owner** (owner decision): SWD-07, the NG+ bonuses missing from the character panel until UI; SWD-10, each decided list as the sword's whole set of bonuses (Dol Blathanna's 5% crit chance and the Vixen's `dismember_chance_mult` dropped), the generic names kept, the NG+ values by the NG+ rule; the deviations recorded with this audit (F3, F5). Recommendation: confirm all (F2's deviation goes with its fix). **Decided** (project owner, 2026-10-19): all confirmed: the panel's sword lines until UI, SWD-10's lists as each sword's whole set of bonuses, SWD-10's NG+ values, and F3's and F5's deviations.
12. **Small differences with no effect, kept** (no action): Aerondight's reset also restarts the decay timer (legacy's did not; it only matters at 0 charges); its charged-hit check does not ask for a victim actor (a melee hit always has one); Iris's description replaces the tooltip's whole description, dropping 5.x's debug item-name prefix and the crafting text, empty for a sword; the five call sites of vanilla's phantom weapon manager are kept and find no manager; equipping Iris or Aerondight in combat adds the effect paused, as legacy; a sword's `sword_dmg_bonus` and `spell_dmg_bonus` count only while it is drawn (`OnHold`), as legacy.

**Doc corrections made with the audit:** F6 to F8, F2's deviation text, the deviations recorded for F3 and F5: this page (unit-list status, the open checks, SWD-02's quality, SWD-05's and SWD-06's sheathing, SWD-06's two deviations, SWD-01's deviation, SWD-07's deviation text, SWD-08's status, SWD-03's per-hit note, SWD-10's open check, the hand-off table), [dmg.md](dmg.md), [development.md](../development.md#testing-in-game), [open-questions.md](../open-questions.md), [attribution.csv](attribution.csv) and the generated [coverage.md](coverage.md) and [deviations.md](deviations.md), the [status page](README.md#where-the-port-stands).

**Not reviewed:** the translations' wording beyond legacy's rows; the test functions' internals beyond what they report; NG+ in game (the policy: not tested); the scabbards (`bound_items`, AI).

**Suggested fix slices** (each touches its own files; verified in game in one tree, since no skill is involved):

- **A, item data** (`tools/gen_swd_items.py` on master; `items/gm_swd_items.xml`, `items_plus/gm_swd_items.xml`): F1, `--verify` over the child blocks (F9); with F4 (a) the `DoNotEnhance` tags, with F3 (b) Iris's `Autogen`, with F10 (b) the White Widow's values. Check: the Wolf relic drawn and sheathed in game, a crafted sword bought or crafted without a random bonus. **Done**: F1 (5.x-GM `c934ee50`), F4 and F10 (5.x-GM `0e524ca1`); F3 decided (a), no change.
- **B, strings** (`localization/modGhostMode/br.csv`, `es.csv`, `fr.csv`, `it.csv`, `pl.csv`): F2, the deviation removed. **Done** (5.x-GM `c934ee50`).
- **C, ARM's crafted armor** (`tools/gen_arm_items.py`, `gm_arm_items.xml`; the starting armor's entry by `gen_arm_km.py`): only with F4 (a), as ARM's fix. **Done** (5.x-GM `0e524ca1`).
- **T, tests** (`tests/gmTestsSwd.ws`): F9, after A and B. **Done** (5.x-GM `c934ee50`; F4's checks `GMTest_swd02` and `GMTest_arm_dne` and F10's values in `GMTest_swd10`, 5.x-GM `0e524ca1`): regression 515 passed, 0 failed in each tree.
- **Docs**: F6 to F8 done (2026-10-19); the slices' results go into the entries as they land.

#### Audit close-out

Closed 2026-10-19: every finding is fixed, recorded or decided by the owner. Fixed and verified in both trees: F1, F2, F9 (5.x-GM `c934ee50`). Recorded: F6, F7, F8 (doc corrections), F12 (no action). Decided by the owner (2026-10-19): F3 (Iris's fixed damage and 5.x's NG+ Iris swap confirmed as temporary deviations until ITEM), F4 (legacy's `DoNotEnhance` on crafted swords, the Wild Hunt swords 3–4 and crafted armor, made and verified in both trees, 5.x-GM `0e524ca1`), F5 (the level tags' deviation confirmed, until ITEM), F10 (the White Widow raised to fire damage 25 and burning 8%, made and verified in both trees, 5.x-GM `0e524ca1`; the other new swords kept, the Top Notch steel sword matching Headtaker), F11 (the porter's calls confirmed). Checks at close: regression 515 passed, 0 failed in each tree; `check_modsigns.py` 0 unmarked; `gen_swd_items.py --verify` and `gen_arm_items.py --verify` 0 unexplained (`DoNotEnhance` compared); `gen_arm_km.py`, `gen_arm_new.py`, `gen_ngplus.py` and `gen_ench.py --check` current. Two new deviations: SWD-02's and ARM-01's `DoNotEnhance` kept where legacy removed it, until ITEM (confirmed by the owner, 2026-10-19). **Signed off** by the project owner, 2026-10-19 (SWD-01 to SWD-10). What stays open after the sign-off: the open checks listed in the entries (among them the HUD counters and glows on screen, a sword crafted at a blacksmith or bought, the new swords' effect procs, NG+); SWD's temporary deviations, confirmed, until ITEM and UI; no SWD deviation is left unconfirmed (`python tools/deviations.py --unconfirmed`).

---

### Dependencies on other areas

- **Done areas SWD builds on:** DMG (weapon damage from the item, the pool, the crit check, the resistance step: SWD's terms are hosted there as temporary deviations), DEF-01 (undodgeable attacks), ARM (set tags, ARM-15's Netflix set, the item generator as a model), ENCH (the item tooltip fix ENCH-17, enhancement slots for runes), MUT-02 (reads `GetTotalWeaponDamage`).
- **Areas SWD waits for or shares with:** ITEM (item level from damage, per-level abilities, `Autogen` tags, random weapon bonuses, `DoNotEnhance`), ECON (prices, price tags), CRAFT (schematics, parts, mastercrafted weapon kits), WGT (weights), UI (the panel's sword sections), ALCH (oils on swords).

### Hand-offs received

Every item other areas handed to SWD, and where it lands:

| From | Item | SWD |
|---|---|---|
| ARM (hand-off table, audit note) | The set swords' stats (their set tags are ARM's); the set sword abilities found by ARM's sweep | SWD-04; Netflix swords' stats SWD-10 |
| DMG (hand-off) | Sword damage and crit bonuses (618 units) | SWD-01 to SWD-04 |
| DMG (hand-off, DMG-04 deviation) | `sword_dmg_bonus`/`spell_dmg_bonus` pool terms | SWD-07 (ported, ends the deviation) |
| DMG (DMG-02, DMG-03, DMG-04, DMG-08 deviations) | Aerondight: attack power and crit power, crit chance, ignoring armor and resistances, damage per enemy | SWD-05 (ends the four deviations) |
| DMG (DMG-02, DMG-08 deviations) | Iris's phantom strike ignoring armor and resistances; the Phantom Weapon's boost in `GetTotalWeaponDamage` | SWD-06 (ends both deviations) |
| DEF (hand-off) | The Iris phantom strike cannot be dodged (`CActor.PrepareAttackAction`) | SWD-06 (ported) |
| MUT-02 (depends on DMG/SWD) | Conductors of Magic reads the sword's damage from `GetTotalWeaponDamage` | SWD-05, SWD-06 (their terms feed it, as legacy) |
| feature-mapping (roadmap) | The `SWD` area: swords | this file |

### Hand-off to other areas

| Area | Changes |
|---|---|
| XBOW | Crossbows and bolts (`def_item_weapons_crossbow(s).xml`, the Ofir crossbows; about 60 units left unattributed) |
| AI | NPC swords and weapons (`def_item_npcweapons.xml`, `def_item_weapons_npc.xml`, `NPC *` items in the player files, about 250 units), secondary weapons and their NPC scabbards (128), monster weapons (222), fists, the Caretaker's shovel ability (changelist 101) |
| ITEM ([item.md](item.md#hand-offs-received), mapped 2026-10-19) | The Hearts of Stone and Blood and Wine standalone starting armor (32 units in `def_item_ep1/ep2_stand_alone.xml`, the owner's decision, 2026-10-19); the `Autogen` tags legacy gave the swords it moved to damage by level (SWD-01's deviation; Iris's, SWD-06), the level-generation tags legacy removed (`AutogenForceLevel`, `AutogenUseLevelRange`) and Damien's sword's `Autogen` ([audit](#swd-audit-2026-10-19) F3, F5); legacy's rework of the random enhancements (`AddRandomEnhancementToItem` by level and quality, `AddQualityAbilityToItem`); item level (`GetItemLevel`'s `Ceil`, `GenerateItemLevel`, `AddItemLevelAbility`, `item_level_min/max`, `Autogen*` tags), random weapon bonuses (`def_item_quality.xml` `MA_*`, `InitWeaponAbilities`, `GetRandomCommonWeaponAbility`, `AddRandomEnhancementToItem`, `AddQualityAbilityToItem`; changelist 630–631), `DoNotEnhance`, durability, the grindstone buff (changelist 858, with the Armorer's Table) |
| ECON | Prices of every sword item and the `mod_legendary`/`mod_valuable` tags |
| CRAFT | Dismantling parts of swords, sword schematics (the NG+ Wolven schematics included), mastercrafted weapon kits, the BaW relic schematics' witcher colour fix (changelist 183) |
| WGT | Sword weights (every sword ability) |
| LOOT | Where swords drop and are sold |
| ALCH | Oil items, the oil tooltip rows (`vs*_critical_hit_*`, `vs*_resist_reduction`), the stuck-oil fix (`RemoveAllOilAbilitiesFromItem`, `GiveItemTo`; changelist 70) (ported with ALCH-16, 2026-10-20) |
| UI | The character panel's sword sections (average damage per hit, attack power and crit power lines: `SPlayerOffenseStats`, the rest of `GetOffenseStatsList`, `CharacterStatsPopup`), the instant-kill chance shown as the swords' maximum (changelist 169) |
| HORSE | Horseback damage from weapon damage (changelist 488) |

### Save impact

None expected for stats: sword stats are read from the definitions, so owned swords pick up the new values (as ARM-01 verified for armor). A crafted sword or armor piece received before `DoNotEnhance` (F4) keeps any random bonus it rolled then (stored on the item; from the code); new ones roll none; Iris's and Aerondight's effects are built at equip and in combat. Removing the mod mid-playthrough is not supported ([save compatibility](../feature-mapping.md#save-compatibility)); as facts: the Iris effect would stay on Geralt as an unknown effect, and an Aerondight would fall back to vanilla's mechanism.

### Area decisions

All five are decided by the owner (project owner, 2026-10-19), with the two open questions below. Legacy behaviour first applies to SWD-01 to SWD-09 (5.x did not change them).

| # | Question | Options | Recommendation | Owner's decision (2026-10-19) |
|---|---|---|---|---|
| DS1 | 5.x's new swords (Netflix, Dol Blathanna, Vixen, Top Notch) | (a) Ghost Mode's sword rules: damage by level at their levels, XP bonuses removed, fixed bonuses themed like the comparable legacy swords (Netflix like the Wolven school swords with its set's Yrden and sign theme; Vixen and Dol Blathanna like relics or crafted swords of their level; Top Notch like level-scaled relics), details per sword by the owner as in DA3/DA4; (b) keep 5.x's values; (c) only the damage rule and the XP bonus removal | **(a)**, porter's suggestion: no legacy behaviour exists; it keeps 5.x's swords consistent with Ghost Mode's, as ARM-15 did for the armor | (a): 5.x's new swords get Ghost Mode's sword rules, with themes like the comparable legacy swords; the per-sword details decided by the owner, 2026-10-19 ([SWD-10](#swd-10-5xs-new-swords)) |
| DS2 | The Netflix swords' levels | (a) the armor's tiers, 21/35/41 (steel 193/305/353, silver 300/440/500); (b) the levels 1.32's formula reads from 5.x's damage, about 23/37/44 (5.x's own `GetItemLevel` already shows 21/35/41) | **(a)**: the set's tiers are decided (DA3), and legacy's school swords share their armor's tier levels | (a), 21/35/41 |
| DS3 | The three crafted silver swords' animation fix | (a) drop legacy's edits, 5.x has the same fix; (b) carry legacy's entries anyway | **(a)** | (a) |
| DS4 | The NG+-only sword bonuses (SWD-07) | (a) port as legacy, NG+ untested; (b) leave NG+ swords as 5.x | **(a)** (the NG+ policy: legacy's NG+ changes are carried over) | (a), untested by policy |
| DS5 | The boundary | (a) as in [Scope](#scope): crossbows to XBOW, NPC and secondary weapons to AI, oils to ALCH, item level and random weapon bonuses to ITEM; (b) SWD also takes the random weapon bonuses (`MA_*`; the changelist lists them under Swords) | **(a)**: the random bonuses and the level code are shared with armor, and DMG and ARM already handed them to ITEM | (a), the boundary as mapped; the random weapon bonuses go to ITEM |

**Questions without a clear recommendation** (answered by the owner, 2026-10-19):

- Top Notch steel and silver swords: an account reward (confirmed by the owner), like Scarlet Crest; they stay, under Ghost Mode's rules, as relics at their level. Part of SWD-10, ported with it.
- The standalone starting armor units found unattributed (32: the Hearts of Stone and Blood and Wine standalone starts' armor, boots, gloves and trousers, items and abilities, regular and NG+): ITEM, deferred (attributed in [attribution.csv](attribution.csv)).

### Port order

Porter's plan, one slice per feature, each with its tooltip rows and strings (SWD-09) and its tests:

| # | Slice | Ends |
|---|---|---|
| 1 | The item generator `tools/gen_swd_items.py` (`--check`, `--verify` against legacy's data) with SWD-01 and SWD-02 (damage by level, crafted and loot swords), SWD-08's fixes | DMG's hand-off of sword damage |
| 2 | SWD-03 relic and unique swords | — |
| 3 | SWD-04 school swords (merged with ARM's set tags) | ARM's hand-off |
| 4 | SWD-05 Aerondight | DMG-02/03/04/08's Aerondight deviations |
| 5 | SWD-06 Iris | DMG-02/08's Iris deviations, DEF's hand-off |
| 6 | SWD-07 NG+ bonuses (pool terms, `items_plus`) | DMG-04's `sword_dmg_bonus`/`spell_dmg_bonus` deviation |
| 7 | SWD-10 5.x's new swords, after DS1 and DS2 (done, 5.x-GM `9b2e2648`) | ARM-15's Netflix sword entries (moved to `gm_swd_items.xml`) |
