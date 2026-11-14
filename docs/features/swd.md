# SWD: swords

Geralt's steel and silver swords: their damage, their bonuses and the two swords with a mechanism of their own, Iris and Aerondight. Ghost Mode rebuilt the swords' numbers around one rule: **a sword's main damage (slashing for steel, silver for silver) is set by its item level** and is the highest that level allows (steel 25 + 8 per level, silver 90 + 10 per level), so a sword's level and its damage are the same thing. Every crafted, relic, unique and witcher sword then got fixed bonuses instead of random ranges: crit chance and crit damage, attack power, armor penetration (flat or a resistance reduction), an effect chance (bleeding, burning, freezing, poison, confusion, stagger), a sign's intensity, a dismember chance; the XP and crowns bonuses vanilla put on swords are gone. The witcher school swords follow their set's theme (Feline crits and bleeding, Griffin sign intensity and fire, Bear attack power and adrenaline, Wolven attack power and sign intensity, Viper poison and armor penetration, Manticore armor penetration and adrenaline). Iris and Aerondight were redesigned: charges from hits that decay and reset when Geralt is hit; a charged Iris adds 5% of Geralt's Vitality to a hit and its strong attack throws an undodgeable phantom strike that ignores armor and resistances; Aerondight gains 10 damage per enemy in combat and, charged, lands a certain critical hit with +100% crit power that ignores armor and resistances and shocks the enemies around. Source: the changelist's "Swords" section ([legacy-FullChangelist.txt](../legacy-FullChangelist.txt), lines 614–649) and bug fixes (lines 70–73, 104–108, 183).

Swords are part of player power: balance them with [balance.md](balance.md) and the [gear ledger](ledger/gear.md) (sections 2 and 7: the school swords, relics, Iris and Aerondight in vanilla 1.32, legacy and 5.x).

**How legacy Ghost Mode implements it.** A sword's stats are its `_Stats` ability in the item files (`def_item_weapons.xml`, `def_item_crafting_weapons.xml`, `def_item_weapons_relic.xml`, the expansions' copies, `dlc10_wolf_swords.xml`, `def_item_dlc15_weapons.xml`, the standalone starting swords); the swords that scale with the level (`Autogen`: loot and relic swords) take their damage from the per-level abilities `autogen_steel_dmg`/`_base` and `autogen_silver_dmg`/`_base` in `def_item_weapons_relic_autogen.xml`, added by ITEM's level code (`GenerateItemLevel`, `AddItemLevelAbility`); the level shown is computed back from the damage (`W3GameParams.GetItemLevel`, ITEM). Iris becomes an effect, `W3Effect_PhantomWeapon` (`phantomWeapon.ws`, `PhantomWeaponEffect` in `dlc/ep1/.../effects.xml`), replacing vanilla's `CPhantomWeaponManager`; Aerondight's effect (`aerondight.ws`, `AerondightEffect` in `dlc/bob/.../effects_ep2.xml`) is rewritten; both are managed in `CR4Player.ManageAerondightBuff`/`ManageIrisBuff` and the equip, combat and holster events, and act in the damage code (`GetTotalWeaponDamage`, `ProcessAction`, `ProcessCriticalHitCheck`, `GetAttackersPowerMod`, `GetDamageResists`, `CActor.DoAttack`, `PrepareAttackAction`).

**What 5.x did in this area.** Almost nothing to the swords that exist in 1.32: their abilities, Iris, Aerondight and the level code for swords are 1.32's (5.x changed scabbards, and fixed the steel/silver draw animation of three crafted silver swords as legacy did). 5.x added swords: the Netflix set's three tiers ("Forgotten Wolven", steel and silver, plus Reinald's pair), the Dol Blathanna longsword and the White Widow of Dol Blathanna, the Steel and Silver Vixen, and the Top Notch steel and silver swords; all carry vanilla-style bonuses (XP on kill included) and none follows Ghost Mode's damage-by-level rule.

Unit lists: [attribution.csv](attribution.csv): 1,164 units carry an SWD feature (98 script units, 438 XML units and their 551 NG+ copies, 77 CSV rows: 5 tooltip rows and 8 strings × 9 languages); 114 of them are shared with other features (the damage functions with DMG, the set swords' items with ARM, the effect registration with MUT and ENCH). Units of weapon items whose only Ghost Mode change is the price, the dismantling parts, the weight, the level range or an NPC scabbard belong to ECON, CRAFT, WGT and ITEM, and NPC, monster and secondary weapons and crossbows to AI and XBOW ([scope](#scope)).

Port status: **signed off** by the owner (2026-10-19): SWD-01 to SWD-10 ported and verified in both trees (SWD-07 NG+ only, untested by policy). Open checks are listed per entry.

## Scope

**SWD covers** Geralt's steel and silver swords (and Ciri's Zireael): damage and its scaling by level, crit chance and crit damage, attack power, armor penetration, effect chances, sign intensity and other bonuses on swords, enhancement slots and quality, relic, unique and witcher school swords (the set swords' stats; their set tags are ARM's), Iris and Aerondight, the NG+ swords' damage bonuses, the swords' tooltip rows and attribute names, and 5.x's new swords.

**Not SWD** (the boundary, confirmed by the owner with DS5):

| Subject | Area | Why |
|---|---|---|
| Crossbows and bolts (`def_item_weapons_crossbow(s).xml`, the Ofir crossbows) | XBOW | Their own changelist section and area (DMG's hand-off: armor piercing, headshots, NPC bows) |
| NPC weapons (`def_item_npcweapons.xml`, `def_item_weapons_npc.xml`, the `NPC *` swords in the player files), secondary weapons (axes, clubs, halberds; NPC scabbards added), monster weapons, fists, the Caretaker's shovel ability (changelist 101) | AI | DMG handed "NPC and monster weapons" to AI; Geralt never wields them. Exception: Olgierd's own Iris (`NPC Olgierd Sabre`) is SWD-06, since the phantom strike code is shared |
| Sword oils (items, effects, the oil tooltip rows `vs*_critical_hit_*`, `vs*_resist_reduction`, the stuck-oil fix `RemoveAllOilAbilitiesFromItem`, `GiveItemTo`; changelist 70) | ALCH (ALCH-16) | Oils are alchemy items; their skills are SKL-14 (signed off), the Wolven set's oil bonuses ARM-09 |
| Item level (`GetItemLevel`, `GenerateItemLevel`, `AddItemLevelAbility`, `Autogen*` tags, `item_level_min/max`), random weapon bonuses (`def_item_quality.xml` `MA_*`, `InitWeaponAbilities`, `AddRandomEnhancementToItem`, `AddQualityAbilityToItem`), `DoNotEnhance` where legacy removed it (where legacy added it, SWD-02 carries it), durability, the grindstone buff, the standalone starting armor | ITEM | Shared with armor; DMG and ARM handed the same mechanisms to ITEM |
| Prices and the `mod_legendary`/`mod_valuable` price tags | ECON | as ARM |
| Dismantling parts, sword schematics (NG+ Wolven schematics included), crafting costs, mastercrafted weapon kits, the Blood and Wine relic schematics' colour fix (changelist 183) | CRAFT | as ARM |
| Sword weights | WGT | as ARM |
| Where swords drop or are sold | LOOT | as ARM |
| The character panel's sword sections (average damage per hit, attack power and crit power lines: `SPlayerOffenseStats`, `GetOffenseStatsList`, `CharacterStatsPopup`), the instant-kill chance shown as the swords' maximum (changelist 169) | UI | DMG and SKL handed the panel to UI (`SPlayerOffenseStats` is a struct) |
| Horseback damage from weapon damage (changelist 488) | HORSE | Its own changelist section |

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

### Classification and action

| # | Feature | Class | Action |
|---|---|---|---|
| SWD-01 | Damage by level | clean | Legacy's values through a generated DLC override (like ARM's `gen_arm_items.py`) |
| SWD-02 | Generic and crafted | clean | Ported with the generator |
| SWD-03 | Relic and unique | clean | Ported with the generator |
| SWD-04 | School swords | clean | Ported with the generator; set tags stay ARM's |
| SWD-05 | Aerondight | clean (5.x untouched) | Legacy's redesign |
| SWD-06 | Iris | clean (one unit overlaps) | Legacy's effect |
| SWD-07 | NG+ bonuses | clean | The generator (`items_plus`) and the pool terms |
| SWD-08 | Fixes | partly in-5.x | The fixes 5.x lacks; the three animation edits 5.x already has dropped |
| SWD-09 | Tooltip rows | clean | Ported with the slices |
| SWD-10 | 5.x's new swords | rethink | Owner's design (DS1, DS2) |

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
| Port form | `gm_swd_items.xml` in the DLC's `items/` and `items_plus/`, generated by `tools/gen_swd_items.py`: every item and ability unit [attribution.csv](attribution.csv) gives an SWD feature, 5.x's entry given whole (`on_conflict="replace"`) with legacy's SWD changes merged from the same file (a three-way merge against 1.32, child blocks such as `anim_actions` included), the `autogen_*` abilities with legacy's values; the set swords' entries carry ARM's set tags (`gen_arm_items.py` hands them over, so each sword has one entry); `--verify` compares the final items, every child block and SWD's strings with legacy's |
| Port status | **signed off** (2026-10-19), verified in both trees |
| Open checks | NG+ (`--verify`) |
| Save impact | none (expected: stats come from the definitions; an owned level-scaled sword keeps its count of per-level abilities, whose value is read from the definitions, as ARM-01 verified for armor) |
| NG+ counterpart | applied, untested: legacy's own `items_plus` values (legacy set NG+ swords by the same rule at their NG+ levels) |

**What it does:** "Slashing/silver damage is defined by item level – the bigger the level is, the bigger the damage gets" (changelist 617–621). A sword's main damage is always slashing (steel) or silver (silver), each the maximum for the sword's level: steel 25 + 8 × level, silver 90 + 10 × level; legacy's comments give each sword's intended level (crafted Short sword level 1: 33; Lynx School steel sword 3 level 34: 297; grandmaster school swords level 40: 345 and 490). Level-scaled swords (loot and relic swords, `Autogen`) get 8 (steel) or 10 (silver) per level with a base of 19–25 or 82–90. Extra damage types (fire, frost, poison) are added on top and processed separately (DMG). The level a sword shows and needs is read back from its damage (ITEM-01). Every melee hit's raw damage varies by vanilla's random 0.9 to 1.1 (`W3Action_Attack.AddDamage`).

**Implementation (legacy):** the damage nodes of about 150 regular sword abilities (and their NG+ copies) and the four `autogen_*` abilities; the level is computed from the damage by `W3GameParams.GetItemLevel` (`Ceil` instead of vanilla's `Floor(1 + …)`, ITEM).

**5.x:** unchanged from 1.32.

**Decisions:** port as legacy (legacy behaviour first; 5.x did not change these swords). What is SWD's in an item: every stat legacy changed in a sword's abilities except `weight` (WGT), `item_level_min/max` (ITEM); every attribute of the item legacy changed except the price (enhancement slots, icons, looks, names, draw and holster animations and sounds), its look variants, ability list and tags; not the price, the dismantling parts, NPC scabbards (`bound_items`, AI), `Autogen*` tags (ITEM) or the price tags (ECON); `DoNotEnhance` where legacy added it (SWD-02), not where legacy removed it (ITEM). Where 5.x changed the same field (scabbards; the three crafted silver swords' animations, DS3), 5.x's stays. The swords legacy moved to damage by item level (the standalone starting swords, Ofir Sabre 2, the Iron Poker, the laundry stick, the `q702` vampire steel sword, the `mq1058` Feline sword, Damien's sword) and their level tags are ITEM's ([ITEM-03](item.md#item-03-level-tags-and-ranges-in-item-data), [ITEM-04](item.md#item-04-items-moved-to-level-scaling)).

- **Deviation:** NG+ entries legacy deleted stay as 5.x has them, since a DLC cannot remove an entry: `NGP Ofir Sabre 2`, `NGP Olgierd Sabre` and its ability (SWD-06) (confirmed by the owner, 2026-10-19). At the start of NG+ legacy still swapped Ofir Sabre 2 for its deleted `NGP` copy (`NewGamePlusReplaceItem` removes the item first), so in legacy the sabre most likely vanished; the port keeps the swap, so NG+ gives 5.x's `NGP Ofir Sabre 2` (the owner keeps 5.x's items, 2026-11-03; [ITEM-04](item.md#item-04-items-moved-to-level-scaling)'s deviation, with Ofir Armor; whole-port audit C3-5).

**Slices:**

1. **Item data for SWD-01, SWD-02, SWD-08 and their tooltip rows.** Verified 2026-10-19, both trees: `gen_swd_items.py --verify` 0 unexplained; scripted reads (`GMTest_swd01`, in the regression) of the crafted swords' damage, bonuses, slots, icons and the tooltip rows; a real light attack with the crafted Short sword on a neutral test dummy dealt its 33 raw damage (within the random roll).

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
| Port status | **signed off** (2026-10-19), verified in both trees |
| Open checks | a sword crafted at a blacksmith or bought (the tag tested on swords added by script, which runs the same item-received code); NG+ (`--verify`) |
| Save impact | stats none (expected); a crafted sword already owned keeps a random bonus it rolled before the tag (the bonus is stored on the item and the tag only stops new rolls; from the code) |
| NG+ counterpart | applied, untested |

**What it does:** "Crafted items now have non-random bonuses" (changelist 657). Each crafted sword (Short sword, No Man's Land, Nilfgaardian, Novigradian, Skellige, Scoia'tael, dwarven, gnomish, elven, Inquisitor, the crafted silver swords) has a level (1 upward, one level per tier) with the matching damage and one or two fixed bonuses: armor penetration 20, 5% resistance reduction, attack power +5–10%, crit chance +10%, crit damage +20%, an effect chance of 5% (bleeding, stagger, confusion, burning) or a sign's intensity; quality lowered to 1–3 (13, 16 and 10 swords; the crafted relics stay 4); some get an extra slot. Loot swords (`Autogen`) keep their damage by level; their vanilla bonuses are mostly kept. Every sword loses its XP-on-kill bonus (`human_exp_bonus_when_fatal`, `nonhuman_exp_bonus_when_fatal`), not in the changelist. The standalone starting swords (Hearts of Stone and Blood and Wine standalone starts) become level-scaled.

**Implementation (legacy):** `*_crafted _Stats` abilities and items in `def_item_crafting_weapons.xml` (base game, EP1, BaW), loot swords in `def_item_weapons.xml`, the standalone starting swords; about 240 regular and NG+ units.

**5.x:** unchanged.

**Decisions:** port as legacy. `DoNotEnhance` where legacy added it, so 5.x's random masterwork or magical bonus (`AddRandomEnhancementToItem`, on quality 2 and 3 items Geralt or a merchant receives) no longer lands on top of the fixed bonuses (project owner, 2026-10-19); it acts on the 26 crafted swords of quality 2 and 3 and the Wild Hunt swords 3–4; the same for ARM's crafted armor ([arm.md](arm.md), ARM-01). Where legacy removed the tag (the Blood and Wine silver swords and their `R` copies, the Toussaint, Cianfanelli and `mq7007` elven swords, the `sq701` tournament swords), it is removed by [ITEM-08](item.md#item-08-donotenhance-removed).

**Slices:**

1. Ported with [SWD-01](#swd-01-sword-damage-by-item-level)'s slice 1.
2. **No random bonus on crafted swords.** Verified 2026-10-19, both trees (scripted, `GMTest_swd02`, in the regression: `AddAnItem` runs 5.x's item-received code with its random roll, as crafting and buying do): new copies of tagged crafted and Wild Hunt swords got no random (`MA_*`) ability, an untagged loot sword did; `--verify` compares the tag.

### SWD-03 Relic and unique swords

| | |
|---|---|
| Kind | tuning |
| Pillars | P6, P8 |
| 5.x class | clean |
| Flags | balance |
| Depends on | SWD-01, ITEM (level-scaled relics), ECON (`mod_legendary` price tag) |
| Skill trees | n/a |
| Port form | the generator (SWD-01); `swords/caretakerShovel.ws` (the shovel's lifesteal, slice 2) |
| Port status | **signed off** (2026-10-19), verified in both trees |
| Open checks | NG+ (`--verify`); a real swing of the Caretaker's Shovel |
| Save impact | none (expected) |
| NG+ counterpart | applied, untested |

**What it does:** every relic (quality 4) and unique sword gets a fixed, distinct identity instead of vanilla's random ranges: for example Caerme +10% adrenaline, 30 fire damage and 15% burning; Gwyhyr 25% crit chance, +30% crit damage and armor penetration 30; Fate +60% crit damage, 45 fire and burning; Hjalmar's sword 25% crit chance, +75% crit damage, +10% attack power and adrenaline; the Hearts of Stone unique swords 20% crit chance, +100% crit damage and 20% burning or confusion. Typical parts: an effect (and its chance, 5–15%), one or two signs' intensity, crit chance and damage, attack power, armor penetration (15–80) or resistance reduction, a dismember chance. The crowns bonus (`bonus_money`) and XP bonuses go; Torlara's, Torzirael's, Havcaaren's and Eredin's sword's instant-kill chance is retuned. Crafted relics (Arbitrator, Beannshie, Black Unicorn, ...) follow the same themes at their crafted level. Ofir sabres, the Toussaint, guard, knight and Hanza swords (Blood and Wine), the EP2 silver swords, `q402`, `sq304`, Ciri's Zireael (armor penetration) are retuned the same way.

The Caretaker's Shovel heals on every enemy type, as legacy and its description: its lifesteal (0.1 × the hit's damage) is read from the victim's health type in `CActor.OnTakeDamage` (legacy's lines); 5.x's `CR4Player.OnProcessActionPost` read Geralt's own `UsesEssence()` for a victim on Essence and so healed nothing on monsters and specters.

**Implementation (legacy):** `def_item_weapons_relic.xml` (base game, BaW), relic `*_crafted` entries, unique swords in `def_item_weapons.xml` (base game, EP1, BaW); about 330 units; the shovel's lifesteal in `CActor.OnTakeDamage`.

**5.x:** unchanged; the shovel's lifesteal in `OnProcessActionPost` (above).

**Decisions:** port as legacy. Legacy's relics keep ranges (`min`/`max`) for some bonuses, narrowed and raised (Caerme's fire damage 30–40, 1.32's 1–10); the port carries them as legacy has them. Torlara and Torzirael lose `MA_Indestructible` from their ability lists, as in legacy (confirmed by the owner, 2026-10-19). The shovel's lifesteal moves to the victim's `OnTakeDamage` (`mutations/takeDamage.ws`) and `swords/caretakerShovel.ws` replaces `OnProcessActionPost` without 5.x's block, so a hit heals once (fix round 3, the owner's decision, 2026-11-02).

**Slices:**

1. **Relic and unique swords.** Verified 2026-10-19, both trees: `--verify` 0 unexplained; scripted reads (`GMTest_swd03`, in the regression) of sample relics' and unique swords' bonuses, icons and a tooltip; a real light attack with the crafted Harpy on a neutral wolf dummy dealt its silver damage (within the random roll).
2. **The Caretaker's Shovel's lifesteal** (fix round 3). Verified 2026-11-02, both trees (scripted hits with the shovel, `GMTest_swd03_shovel`, in the regression; failing first on a build with 5.x's code): it heals 0.1 × the damage on a bandit (Vitality) and on a wraith (Essence).

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
| Port status | **signed off** (2026-10-19), verified in both trees |
| Open checks | NG+ (`--verify`) |
| Save impact | none (expected) |
| NG+ counterpart | applied, untested (NG+ bonuses: SWD-07) |

**What it does:** each school's swords carry their set's theme, rising with the tier: Feline crit chance 15–35% and bleeding 15–30%; Griffin sign intensity +10–30% and 20–60 fire damage; Bear attack power +20–40% and adrenaline gain +15–30%; Wolven (DLC and grandmaster) attack power +15–30% and sign intensity +10–25%, one more slot on the first tiers; Viper (Hearts of Stone) poison and armor penetration 60; Manticore armor penetration 80 with resistance reduction and adrenaline +25%; the Feline sword from the free DLC quest (`mq1058_cat_school_sword`) likewise. Damage follows SWD-01 at each tier's level (a little below vanilla's at the same tier). The ledger's school-set sections list the per-tier values.

**Implementation (legacy):** the school sword abilities and items in `def_item_crafting_weapons.xml` (base game, EP1, BaW), `dlc10_wolf_swords.xml`, `def_item_dlc15_weapons.xml`; the items' set tags are ARM's (ARM-05 to ARM-11, attributed to both).

**5.x:** unchanged.

**Decisions:** port as legacy.

- **Deviation:** the NG+ Wolven swords' damage reduction (`NGP Wolf Steel/Silver Sword Mod`, which 5.x's `NewGamePlusAdjustDLCItem` adds to owned NG+ Wolven swords), deleted by legacy, is given empty, which is what the deleted ability did; 5.x adds the same abilities to the NG+ Netflix swords, whose reduction stays emptied too (confirmed by the owner, 2026-10-19, with SWD-10's rules).

**Slices:**

1. **School swords.** Verified 2026-10-19, both trees: `--verify` 0 unexplained (`gen_arm_items.py --verify` too); scripted reads (`GMTest_swd04`, in the regression) of sample school swords' damage, bonuses and set tags; a real light attack with the superior Ursine steel sword on a neutral test dummy showed its damage and its +35% attack power.

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
| Port status | **signed off** (2026-10-19), verified in both trees |
| Open checks | the HUD counter and the sword's glow per charge on screen |
| Save impact | none (expected; an Aerondight carried from a vanilla save keeps its `PermDamageBoost` modifier, which legacy ignores: unsupported case) |
| NG+ counterpart | applied, untested (`abilities_plus`) |

**What it does:** changelist 643–648. While in combat Aerondight's weapon damage rises by 10 per hostile enemy in range (30 m). Each successful hit adds a charge (4 to charge it fully); a charge decays every 6 s, and all are lost when Geralt takes damage. A fully charged Aerondight's next hit is a certain critical hit with +100% crit power that ignores armor and resistances; it discharges, dealing 100 shock damage and a stagger to hostile enemies within 3 m. Vanilla's permanent damage growth (stacks per level stored on the item), the +10% damage and +100% crit chance, and the charge on finishers and discharge on kills are gone. The effect exists only in combat; sheathing the sword pauses it and resets its charges. Its visual effects map legacy's 4 charges onto vanilla's 10 stages.

**Implementation (legacy):** `aerondight.ws` (28 units, new `InitXmlValues`, `AddCharge`, `RemoveCharge`, `DischargeAerondight` with the shock, `GetDamageBoost`, `GetCritPowerBoost`, `Modded2Vanilla`), `AerondightEffect` values (`crit_dmg_bonus` 1, `dmg_boost_per_enemy` 10, `collateral_dmg` 100, `hitsToCharge` 4, `stackDrainDelay` 6), `ManageAerondightBuff`, the damage functions, `GetAerondightTooltipDescription`.

**5.x:** unchanged from 1.32.

**Decisions:** port as legacy (5.x did not change it). Blood and Wine's Aerondight is the item `Aerondight EP2` (tag `Aerondight`); the base game's relic named `Aerondight` (shown as Maugrim) is a relic (SWD-03). The effect shows on the HUD when added (legacy's effect definition has `showOnHUD`; 5.x's definition, which a DLC cannot override, only after a resume: the port sets it in `OnEffectAdded`). Small differences with no effect: the reset also restarts the decay timer (it only matters at 0 charges); the charged-hit check does not ask for a victim actor (a melee hit always has one); equipping Aerondight in combat adds the effect paused, as legacy.

**Slices:**

1. **Aerondight.** Verified 2026-10-19, both trees (real light attacks with `Aerondight EP2` on neutral drowner test dummies, damage probe, `gmtest_swd05_state`; `GMTest_swd05` in the regression): the effect only in combat, +10 damage per hostile, four real hits charge it and the next is a crit with ×2.25 attack power ignoring armor, the other dummy within 3 m shocked and staggered; the decay and the loss on a hit taken (scripted). Not in game: the HUD counter and glow on screen.

### SWD-06 Iris

| | |
|---|---|
| Kind | system |
| Pillars | P1, P8, P9 |
| 5.x class | clean (`CActor.PrepareAttackAction` changed by 5.x: hand merge) |
| Flags | — |
| Depends on | DMG-02, DMG-08 (terms they host), DEF-01 (the phantom strike undodgeable), effect framework (an enum extension, as ENCH's `EET_GMRuneword4`), ITEM-04 (Iris level-scaled) |
| Skill trees | n/a |
| Port form | `swords/iris.ws`: legacy's effect as `W3GMEffect_PhantomWeapon` (`EET_GMPhantomWeapon`, an enum extension registered in `effects/gmEffectRegistration.ws`), `GMManageIrisBuff` (`@addMethod`, legacy's `ManageIrisBuff`) called from wrappers of `OnCombatStart`, `OnCombatFinished`, `OnSpawned`, `EquipItemInGivenSlot`, `UnequipItemFromSlot`, `WeaponHolsterStateSelectingWeapon.OnEquippedMeleeWeapon` and `CR4Player.OnHolsteredItem`; `@replaceMethod`s of `CActor.DoAttack`, `CActor.PhantomWeapon` (timer) and `CActor.PrepareAttackAction`; `CR4Player.InitPhantomWeaponMgr` replaced empty (vanilla's `CPhantomWeaponManager` is never created, so the holster's discharge finds nothing); the terms in the replaced `ProcessAction` (`defense/processAction.ws`: `GMIrisOnHit`), `GetDamageResists` (`damage/formula.ws`: source `PhantomWeapon`), `GetTotalWeaponDamage` (`damage/weapon.ws`), `W3PlayerWitcher.OnTakeDamage` (`mutations/takeDamage.ws`), the HUD counter (`mutations/hudCounters.ws`); the description through a wrapper of `W3TooltipComponent.GetBaseItemData`; `GMPhantomWeaponEffect` (legacy's `PhantomWeaponEffect`) with its HUD icon in the DLC's `abilities/gm_swords.xml` (NG+ copy by `gen_ngplus.py`); string 2110992299 (key `attribute_name_double_strike`, vanilla's key for Iris's description); Olgierd's and the player's Iris items by `gen_swd_items.py` |
| Port status | **signed off** (2026-10-19), verified in both trees |
| Open checks | the HUD counter and the sword's charged glow on screen; whether the phantom strike gets through a guard in play ([to test in legacy](../open-questions.md#to-test-in-legacy-ghost-mode)); Olgierd's phantom strike on Geralt |
| Save impact | none (expected; the effect is a saved buff: after removing the mod an unknown effect stays on Geralt, unsupported) |
| NG+ counterpart | applied, untested |

**What it does:** changelist 637–642. Damaging hits with Iris on a hostile charge it (4 for a full charge, shown on the HUD); a charge decays every 6 s (a full charge decays at once), all are lost when Geralt takes damage. The effect exists only in combat while Iris is drawn (paused, and its charges reset, while sheathed; removed when combat ends). While fully charged, Iris's slashing damage rises by 5% of Geralt's maximum Vitality (capped at his current Vitality), drained from him when the hit lands. A strong attack with the charged sword is a phantom strike: its hits, and the phantom copy's strike right after, cannot be dodged, are not parried, ignore armor and resistances, stagger (vanilla: a heavy knockdown) and destroy shields; they discharge the sword. Vanilla's discharge by the holster code (its manager) is gone; sheathing resets the charges through the pause, as legacy. Olgierd's own Iris (an NPC's) performs the phantom strike on every strong attack (vanilla's). Iris is level-scaled and kept at the start of NG+ ([ITEM-04](item.md#item-04-items-moved-to-level-scaling)).

**Implementation (legacy):** `phantomWeapon.ws` (new, 20 units), `phantomWeaponManager.ws` removed (11), `CR4Player.ManageIrisBuff`, `OnHolsteredItem`, the phantom manager's creation removed (`OnSpawned`, `InitPhantomWeaponMgr`, ...), `CActor.DoAttack`, `PhantomWeapon`, `PrepareAttackAction`, the holster states, `ProcessAction` (charge and discharge), `GetDamageResists`, `GetTotalWeaponDamage`, the HUD and tooltip functions; `PhantomWeaponEffect` (`dmg_bonus_prc` 0.05, `hitsToCharge` 4, `stackDrainDelay` 6).

**5.x:** Iris unchanged from 1.32; `CActor.PrepareAttackAction` changed by 5.x for other reasons (the `ParryingAttack` event, kept).

**Decisions:** port as legacy. Legacy's code, ported as it is: `DoAttack` decides the phantom strike before the strong attack's own hits (vanilla only for the copy's), so a charged strong attack lands two phantom hits, the first with the Vitality bonus and the drain; the copy's strike gives Geralt `ForceDismemberment` until a phantom hit discharges the sword (if that hit is not processed, for example on a target the first hit killed, the ability stays until the next discharge); the phantom hits' parry flag is cleared (`SetIsParried(false)`, as vanilla's phantom strike), so in the code they go through a parry, as the changelist says; whether that holds in play stays a [legacy test](../open-questions.md#to-test-in-legacy-ghost-mode). The phantom hits' resistance ignore checks only the source, so it also covers Olgierd's phantom strikes on Geralt (legacy). Small differences with no effect: Iris's description replaces the tooltip's whole description (dropping 5.x's debug item-name prefix and the crafting text, empty for a sword); the five call sites of vanilla's phantom weapon manager are kept and find no manager; equipping Iris in combat adds the effect paused, as legacy.

**Slices:**

1. **Iris.** Verified 2026-10-19, both trees (real light and strong attacks with `Olgierd Sabre` on a neutral human dummy with armor, damage probe, `gmtest_swd06_state`; `GMTest_swd06` in the regression): four hits charge it and add 5% of Geralt's maximum Vitality; the charged strong attack lands two undodgeable, unparried phantom hits that ignore armor, stagger, drain Geralt and discharge the sword; decay and loss on a hit taken (scripted). Not in game: the HUD counter and glow, a guarding or shielded enemy, Olgierd's strike.

### SWD-07 NG+ sword and sign damage bonuses

| | |
|---|---|
| Kind | tuning, system |
| Pillars | P1 |
| 5.x class | clean |
| Flags | — |
| Depends on | SWD-01, SWD-04, DMG-04 (the pool), UI-01, UI-03 (the panel lines) |
| Skill trees | n/a |
| Port form | the generator's `items_plus` output; the two pool terms in DMG's `ProcessDamageIncrease` (`damage/pool.ws`); tooltip rows `sword_dmg_bonus`, `spell_dmg_bonus`; strings 2110992161, 2110992162 (legacy's rows in all 9 languages, by id: legacy's br, de, es, fr, it and pl tables give their keys as hashes) |
| Port status | **signed off** (2026-10-19); NG+ untested by policy (checked by `--verify` and scripted reads) |
| Open checks | NG+ in play |
| Save impact | none (expected) |
| NG+ counterpart | this feature is NG+ only: [not balanced or tested](../feature-mapping.md#new-game-carried-over-and-scaled-not-balanced-or-tested) |

**What it does:** a change legacy made only in its NG+ files ([rule](../feature-mapping.md#new-game-carried-over-and-scaled-not-balanced-or-tested)): the NG+ witcher school swords keep the damage-by-level rule at their NG+ levels (vanilla NG+ gives them higher flat damage, and `NGP Wolf Steel/Silver Sword Mod` lowered it) and add `sword_dmg_bonus`, +5 to +25% weapon damage by tier (Feline, Bear, Wolven), and `spell_dmg_bonus`, +5 to +25% sign damage (Griffin, Wolven); both are additive terms of the raw-damage pool, shown in the tooltip and the character panel (UI-01's sword lines, UI-03's sign lines). They count only while the sword is drawn (`OnHold`), as legacy.

**Implementation (legacy):** the NG+ school sword abilities (`items_plus/def_item_crafting_weapons.xml`, BaW's, `dlc10_wolf_swords.xml`'s `NGP` entries), `ProcessDamageIncrease`, `GetOffenseStatsList`.

**5.x:** unchanged.

**Decisions:** port as legacy (NG+ is carried over, not tested; DS4).

**Slices:**

1. **NG+ bonuses.** Checked 2026-10-19, both trees: `--verify` 0 unexplained; scripted (`GMTest_swd07`, in the regression) the free DLC's NG+ Wolven swords (defined in its regular items file too) read both bonuses and list them in their tooltips. Not in game: the pool terms on a hit (NG+).
2. **Legacy's strings.** Checked 2026-10-19: `--verify` compares SWD's nine strings with legacy's rows in all nine tables; the built tables decoded give legacy's texts; `GMTest_swd07` reads the English texts in game.

### SWD-08 Sword fixes

| | |
|---|---|
| Kind | fix |
| Pillars | P8 |
| 5.x class | partly in-5.x |
| Flags | — |
| Depends on | SWD-01 (the same item entries) |
| Skill trees | n/a |
| Port form | the generator (display fields and the `anim_actions` and `anim_switches` child blocks legacy changed, as ARM's) |
| Port status | **signed off** (2026-10-19), verified in both trees |
| Open checks | the Wolf relic's draw and holster sounds and animation (on screen) |
| Save impact | none (expected) |
| NG+ counterpart | applied, untested |

**What it does:** the missing silver-to-steel draw animations of crafted silver swords (changelist 107: Harpy, Negotiator, Weeper), Torzirael's animations and the Wolf relic's draw and holster sounds fixed; mixed-up inventory icons of swords fixed (changelist 39, "by other modders"; the crafted Short, Inquisitor, Longclaw, Viper, standalone and Witcher silver swords). Geralt's behaviour graph sends the steel sword's draw and holster acts for every sword drawn from the back, silver ones included: the Wolf relic with the silver acts (vanilla) waited about 4 s to holster or stayed in hand.

**5.x:** fixed the three crafted silver swords' animation switch the same way; not the others.

**Decisions:** port what 5.x lacks; legacy's edits of the three swords are dropped as in-5.x (DS3, project owner, 2026-10-19).

**Slices:**

1. **Icons, looks and draw attributes** with [SWD-01](#swd-01-sword-damage-by-item-level)'s slice 1, SWD-03 and SWD-04.
2. **The Wolf relic's and Torzirael's animations.** Verified 2026-10-19, both trees (`gmtest_swd08_draw()`, `gmtest_swd08_holster()`: drawn and sheathed by script, the behaviour graph's notifications logged): the fixed Wolf relic is drawn and sheathed in about 0.1 s and 1 s, as Torzirael and the Witcher silver sword. Not in game: the sounds and the animation on screen.

### SWD-09 Sword tooltip rows and attribute names

| | |
|---|---|
| Kind | ui |
| Pillars | P7 |
| 5.x class | clean |
| Flags | — |
| Depends on | ENCH-17 (the item tooltip fix, signed off), UI (the panel) |
| Skill trees | n/a |
| Port form | `tooltip_settings.csv` (whole-file override, the port's copy: `dismember_chance` replacing `dismember_chance_mult`, `armor_reduction_perc` added), strings 2110992014, 2110992154, 2110992155, 2110992440 in the mod's table (9 languages, legacy's ids and keys) |
| Port status | **signed off** (2026-10-19), verified in both trees (with [SWD-01](#swd-01-sword-damage-by-item-level)'s slice 1); SWD-07's two rows ported with SWD-07 |
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
| Port form | `gm_swd_items.xml` (`items/`, `items_plus/`) by `tools/gen_swd_items.py` (its `SWD10` table, the owner's values): each sword's `_Stats` ability rebuilt from 5.x's (quality and the secondary damage node kept, the weight WGT's DW2; the main damage by level; the decided stats only), its items given whole with the decided slots; the Netflix swords' items carry ARM-15's set tags (`gen_arm_new.py` hands them over through `minor_tags`, so each sword has one entry); `--verify` checks every stat, the damage against the decided levels, the slots, the set tags and that each entry is defined once |
| Port status | **signed off** (2026-10-19), verified in both trees |
| Open checks | a burning or bleeding proc from the new swords; the tooltips on screen; NG+ (`--verify`) |
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
- **Dol Blathanna** (relics, level 8): steel, Sword of a Thousand Flowers: Aard intensity +10%, armor penetration 20, crit damage +20%, dismember 10%; silver, White Widow of the Valley of Flowers: Igni intensity +10%, fire damage 25, burning chance 8% (raised from 15 and 5% by the owner, 2026-10-19), dismember 10%; 2 slots each.
- **Nine-Tailed Vixen** (relics, level 12): both crit chance 15%, crit damage +25%, bleeding 10%, dismember 10%, 2 slots; the silver one also adrenaline gain +5%.
- **Top Notch** (an account reward; level-scaled relics), keeping the generic names "Witcher's steel/silver sword": steel crit chance 10–20%, crit damage +20–40%, dismember 10%; silver sign intensity +8–15%, crit damage +15–30%, dismember 10%; 3 slots each. The steel one is measured against Headtaker, which it matches, and stays as it is (the owner's decision, 2026-10-19).

At the owner's request (2026-10-19) the new swords were compared with similar legacy swords by an estimated score (main damage × the damage-equivalent of the bonuses, at the same level): none is clearly overpowered; the Forgotten Wolven swords match the Wolven school swords tier for tier; Dol Blathanna's and the Vixen's sit with the lower legacy relics of their level; the White Widow was the weakest and was raised (above); the Top Notch swords match Headtaker, a low relic, below top relics such as Gwyhyr.

Porter's calls on the details (each confirmed by the owner, 2026-10-19):

- Each sword's list above is its whole set of bonuses, as legacy's fixed themes are: 5.x's other bonuses go, including Dol Blathanna's 5% crit chance and the Vixen's `dismember_chance_mult` (replaced by the decided `dismember_chance`, SWD-09's stat) (confirmed by the owner, 2026-10-19). Damage by level: steel 25 + 8 × level, silver 90 + 10 × level (Forgotten Wolven 193/305/353 and 300/440/500, Dol Blathanna 89 and 170, Vixen 121 and 210); the level-scaled Top Notch swords keep no fixed damage (the per-level abilities give it, as for legacy's level-scaled relics). An effect chance is written as legacy writes it (the effect, `buff_apply_chance` and its tooltip stat); quality, weight and names stay 5.x's.
- NG+ as in the table above: 5.x's NG+ Forgotten Wolven stats equal its regular ones, so their bonuses are the regular values; Dol Blathanna's NG+ armor penetration 60 and crit damage +30%, the Vixen's NG+ bleeding 20% (steel) and 25% (silver), the silver Vixen's crit chance 14% (confirmed by the owner, 2026-10-19).

**Slices:**

1. **5.x's new swords.** Verified 2026-10-19, both trees: `--verify` 0 unexplained; scripted reads (`GMTest_swd10`, in the regression) of every sword's damage, bonuses, slots and set tags; real light attacks with Forgotten Wolven and Top Notch swords on neutral test dummies (both trees) dealt their damage and attack power; ARM-15's set counts with the swords worn (`gmtest_arm15_wear`); a save holding six of the new swords from before reads the new stats and slots (`gmtest_swd10_owned`).
2. **The White Widow raised.** Verified 2026-10-19, both trees (scripted, `GMTest_swd10`): fire damage 25 and burning 8%, regular and NG+. Not in game: a burning proc.

---

### Dependencies on other areas

- **Done areas SWD builds on:** DMG (weapon damage from the item, the pool, the crit check, the resistance step: SWD's terms are hosted there), DEF-01 (undodgeable attacks), ARM (set tags, ARM-15's Netflix set, the item generator as a model), ENCH (the item tooltip fix ENCH-17, enhancement slots for runes), MUT-02 (reads `GetTotalWeaponDamage`), ITEM (item level from damage, per-level abilities, `Autogen` tags, random weapon bonuses, `DoNotEnhance` where legacy removed it), UI (the panel's sword sections).
- **Areas SWD shares with:** ECON (prices, price tags), CRAFT (schematics, parts, mastercrafted weapon kits), WGT (weights), ALCH (oils on swords). What each owns is in the [scope](#scope).

### Save impact

None expected for stats: sword stats are read from the definitions, so owned swords pick up the new values (as ARM-01 verified for armor). A crafted sword or armor piece received before the mod keeps any random bonus it rolled then (stored on the item; from the code); new ones roll none; Iris's and Aerondight's effects are built at equip and in combat. Removing the mod mid-playthrough is not supported ([save compatibility](../feature-mapping.md#save-compatibility)); as facts: the Iris effect would stay on Geralt as an unknown effect, and an Aerondight would fall back to vanilla's mechanism.

### Area decisions

Decided by the owner (2026-10-19). Legacy behaviour first applies to SWD-01 to SWD-09 (5.x did not change them).

| # | Question | Decision (owner, 2026-10-19) |
|---|---|---|
| DS1 | 5.x's new swords (Netflix, Dol Blathanna, Vixen, Top Notch) | (a) Ghost Mode's sword rules: damage by level, XP bonuses removed, fixed bonuses themed like the comparable legacy swords; the per-sword details decided by the owner ([SWD-10](#swd-10-5xs-new-swords)). No legacy behaviour exists; it keeps 5.x's swords consistent with Ghost Mode's, as ARM-15 did for the armor |
| DS2 | The Netflix swords' levels | (a) the armor's tiers, 21/35/41 (steel 193/305/353, silver 300/440/500), as legacy's school swords share their armor's tier levels |
| DS3 | The three crafted silver swords' animation fix | (a) legacy's edits dropped: 5.x has the same fix |
| DS4 | The NG+-only sword bonuses (SWD-07) | (a) ported as legacy, untested (the NG+ policy) |
| DS5 | The boundary | (a) as in [Scope](#scope): crossbows to XBOW, NPC and secondary weapons to AI, oils to ALCH, item level and random weapon bonuses to ITEM (shared with armor) |

Also answered by the owner (2026-10-19): the Top Notch swords are an account reward, like Scarlet Crest, and stay under Ghost Mode's rules as relics at their level (SWD-10); the 32 standalone starting armor units are ITEM's (ITEM-05).
