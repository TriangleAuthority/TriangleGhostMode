# ARM: armor and armor sets

Geralt's armor: what each piece protects against, what its class costs in stamina, and what wearing a set gives. Ghost Mode rebuilt all three. Every generic piece got resistances by class (light almost none, heavy high) and armor by item level; the class now changes stamina costs (light −30% for melee actions, heavy +50% and +50% for signs) instead of regen; four pieces of one class give a generic set bonus; every witcher school set was redesigned, its minor bonus now available from the first tier; and the mod added the Kaer Morhen set and a Viper set bonus. Source: the changelist's "Armor" section ([legacy-FullChangelist.txt](../legacy-FullChangelist.txt), lines 542–612), its stamina section (lines 233–243) and three bug fixes (lines 104, 106, 144).

Armor and set bonuses are part of player power: balance them with [balance.md](balance.md) (rule B3, the archetypes) and the [gear ledger](ledger/gear.md), which lists every set and armor class in vanilla 1.32, legacy and 5.x.

**How legacy Ghost Mode implements it.** Item stats are the `_Stats` abilities in the item files (`def_item_armor.xml`, `def_item_crafting_*.xml`, `def_item_armor_relics.xml`, the expansions' and free DLCs' item files, `dlc10_wolf_armor.xml`), armor by item level in `def_item_weapons_relic_autogen.xml`. Set membership is item tags (`LynxSetMinor` on lower tiers, `SetBonusPiece`); the set framework is in `playerWitcher.ws` (`IsSetBonusActive`, `GetSetPartsEquipped`, `CheckSetType`) and `playerTypes.ws`. Set bonus values are abilities in `geralt_skills_ep2.xml`, `effects_ep2.xml` and `geralt_skills.xml`; their effects live where they act: stamina costs in `PlayerAbilityManager.ws`, attack power and crits in `damageManagerProcessor.ws`, adrenaline in `OnProcessActionPost` and `ProcessAction`, oils in `oil.ws`, Quen in `quenEntity.ws`. Tooltips: `GetSetBonusTooltipDescription`, `W3TooltipComponent.AddSetAttributes`, strings in `modGhostMode/<lang>.csv`.

**What 5.x did in this area.** Little, except to the Wolven set: its bonuses were replaced by bleeding mechanics, and the code for several oils on one sword is gone. 5.x also moved "bombs thrown without delay" to the Manticore set's first tier (as legacy did) and extended it to its new throwing knives, cut Manticore's maximum toxicity (30 → 20), lowered the rending (and the Feline set's elemental) resistances of the grandmaster school gear, the Wolven DLC gear and the Tesham Mutna set, tagged the Viper gear as a set without giving it a bonus (and hid it from set tooltips), let the Bear set's Quen boost work with the new tree's supercharged Quen, and added new armor: the Netflix set (3 tiers, potion duration and an Aard-in-Yrden bonus), Dol Blathanna, White Tiger and `w3r` armor. Generic armor, armor classes, the other set bonuses and the set framework are 1.32's.

Unit lists: [attribution.csv](attribution.csv). 2,255 units carry an ARM feature (155 script units, 803 XML units and their 964 NG+ copies, 333 string rows: 37 strings × 9 languages); 601 of them are shared with other features (STAM-05's per-item regen values, SKL's sign and Quen functions, DMG's damage functions). Units of armor items whose only Ghost Mode change is the price, the dismantling parts or the weight are left to ECON, CRAFT and WGT ([scope](#scope)).

**Status:** signed off by the owner (2026-10-18), ARM-01 to ARM-15, all ported and verified in both trees; ARM-01's slice 4 (crafted armor without random bonuses) came after, from the owner's decision on the SWD audit's F4 (2026-10-19). Not checked beyond the entries' open checks: the translations' wording (legacy's rows as shipped, SKL-19's rule); NG+ in game (the policy: not tested).

## Scope

**Not ARM:**

| Area | Changes |
|---|---|
| ECON | Prices of every armor item (449 item entries; left unattributed) |
| CRAFT | Dismantling parts of armor items (448); witcher gear schematics and their costs (about 180 schematic units, except Kaer Morhen's); mastercrafted kits (`AddMasterArmorerItems`, master repair kits); legacy's four craftable quest armors (Freya's Warriors' Armor, the Redanian Halberdier's Armor, the Hindarfjall Heavy Armor, the Oathbreaker Armor: `q108 Light armor 09_crafted`, `q108 Medium armor 03_crafted`, `q108 Heavy armor 04_crafted`, `Oathbreaker armor crafted`), whole: items and abilities with legacy's stats, schematics, shop entries, armor-stand looks (the owner's decision, 2026-10-18; `gen_arm_items.py` takes only items 1.32 already had) |
| WGT | Armor weights (425 abilities), Scarlet Crest's 8.2 (DA4); the Thief armor's carry bonus stays with ARM-01; legacy adds the overencumbrance stamina penalty to the armor class penalty in one factor (`1 + armor + overencumbrance`, `GetStaminaActionCost`), where ARM-02 multiplies the class term on its own |
| ITEM ([item.md](item.md)) | Item level (`GenerateItemLevel`, `GetItemLevel`, `AddItemLevelAbility`, `item_level_min/max`, `Autogen*` tags, `DoNotEnhance` where legacy removed it; where it added it, ARM-01 carries it), random enhancements, durability, the Armorer's Table buff (`AddRepairObjectBuff`, changelist 857) |
| ENCH | Levity, Balance and Heft's stamina trades (`GetGlyphword234Mod`, `HasGlyphwordActive`, runeword tooltips); Glyphword 5 (Quen Discharge); 5.x's `Glyphword 22 Bonus` |
| SWD | Set swords' stats (their set tags are ARM's) |
| ALCH | Golden Oriole's poison absorption (with ARM-11); potion duration rules for Manticore and Netflix gear |
| LOOT | Where witcher gear diagrams and armor drop; the shop and container entries of the four craftable quest armors' schematics (with CRAFT) |
| UI | The character panel's armor and set lines; the Yrden range line with the Griffin set's +40% (legacy `AddCharacterStatSigns`); the oil tooltip's Wolven boost (ARM-09) |

## Changes at a glance

### What Ghost Mode changed

| # | Feature | Vanilla 1.32 | Legacy GM | Units (main) |
|---|---|---|---|---|
| ARM-01 | Armor pieces | Resistances by piece (chest average: light 10%, medium 13%, heavy 17.5%); fixed armor on many pieces; few rune slots on light armor | Resistances by class (chest average: light 4.5%, medium 10.4%, heavy 20.4%, every damage type covered); armor by item level (autogen abilities); more slots (light and medium up to 3); unique and relic bonuses retuned (Thief armor's crowns, Ofir's sign intensity, silver studs, Yoana's arrow-bouncing armor fixed) | item `_Stats` abilities and item entries in every armor file; `autogen_*_armor`/`_base` |
| ARM-02 | Armor classes and stamina costs | Class changes stamina regen only; glyphwords Levity, Balance, Heft change the class | Melee and agility actions: light −7.5%/piece (−30%), heavy +12.5%/piece (+50%), each missing piece −12.5% (naked −50%); signs +12.5% per heavy piece; glyphwords no longer change the class | `CalcStaminaArmorPenalty`, `CalcSignCastingArmorPenalty`, `CountArmorPieces`, `GetArmorType`, cost sites in `GetStaminaActionCost`, `GetSkillStaminaUseCost` |
| ARM-03 | Armor regen with the option on | Regen ±% per piece (`staminaRegen_armor_mod`) | Off by default (STAM-05); with the option on: legacy's calculation (glyphwords ignored, regen per missing piece) and its per-piece values (e.g. heavy −0.10 → −0.30) | `CalculatedArmorStaminaRegenBonus`; `staminaRegen_armor_mod` in 545 item abilities |
| ARM-04 | Generic armor set bonuses | none | 4 non-witcher pieces of one class: light +30° safe dodge angle, medium toxicity decay +0.25/s, heavy +10% all resistances | `ManageSetArmorTypeBonus`, `ArmorType*SetBonusAbility`, `CountSetArmorPieces`, `IsSetArmorType`, toxicity, `DodgeDamage` |
| ARM-05 | Set framework | Set bonuses from grandmaster pieces only (3 and 6 pieces) | Tier 1 (3 pieces) from every tier of school gear; tier 2 (6) grandmaster only; Viper and Kaer Morhen sets; sound banks reloaded on load; achievement with lower tiers | `IsSetBonusActive`, `GetSetPartsEquipped`, `CheckSetType`, `playerTypes.ws` enums, `ITEM_SET_TAG_*_MINOR`, item tags |
| ARM-06 | Feline set | 3: a strong attack gives fast attacks +10%/piece for 5 s; 6: rear attacks +50%, stun for 1 adrenaline | 3: each fast hit in a chain +2.5% attack power per piece (max 60%), a strong hit ends the chain at double the bonus; 6: sword crits double adrenaline gained; gear: more attack power and crit | `W3Effect_LynxSetBonus`, `GetAttackersPowerMod`, `OnProcessActionPost`, `PerformCounterCheck`, `LynxSetBonusEffect` |
| ARM-07 | Griffin set | 3: after a sign paid with stamina, the next sign within 3 s is free; 6: Yrden +40%, inside it regen +5%, intensity +100%, damage −20% | 3: any sign starts a 2.5 s buff: sign, melee and agility stamina costs −5%/piece; 6: Yrden +40%, inside it intensity +50%, +15% all resistances, no regen | `OnSignCastPerformed`, `GetGryphonSetTier1Bonus`, cost sites, free-cast code removed, `GryphonSetBonus*Effect` |
| ARM-08 | Ursine (Bear) set | 3: Quen breaking may recast it free (5%/piece); 6: Quen damage +200% | 3: hits taken give +0.035 adrenaline per piece; +3.5% attack power per piece per adrenaline point (melee, bolts); 6: a damaging strong attack or Rend refunds 33.4% of its stamina; Quen rules removed, their effects given to Quen Discharge | `ProcessAction`, `GetAttackersPowerMod`, `OnProcessActionPost`, Quen units, `setBonusAbilityBear_1/2` |
| ARM-09 | Wolven set | 3: up to 3 oils on a sword; 6: bombs thrown without delay (a vanilla mix-up) | 3: oil effects +16.7%/piece (+100%); 6: 3 oils at once, each +5% crit chance and +10% crit damage | `W3Effect_Oil` getters, `ApplyOil`, `UpdateItemSetBonuses`, `SetBonusAbilityWolf_1/2` |
| ARM-10 | Manticore set | 3: bombs can crit; 6: +1 charge per alchemy item; gear +30 toxicity | 3: also no throw delay, +5% bomb crit chance and +10% crit damage per piece; gear +25 toxicity, +25% potion duration (not in the changelist) | `ProcessCriticalHitCheck`, `ThrowProjectile`, `setBonusAbilityRedWolf_1` |
| ARM-11 | Viper set | no bonus | 3: poison damage is cancelled and heals 10%/piece of it; armor +5 toxicity per piece (not in the changelist) | `ProcessActionDamage`, `setBonusAbilityViper_1`, `ViperSet` tags |
| ARM-12 | Kaer Morhen set | n/a | New 4-piece medium set from the start (tiers at levels 2/9/19/27), schematics known from the start, the starting armor renamed "Worn Kaer Morhen"; 3: stamina regen +1/s per additional enemy (max +5) | 16 new items, 15 schematics, `W3Effect_KaerMorhenSetBonus`, `KaerMorhenSetBonusEffect`, NG+ replacement |
| ARM-13 | Tesham Mutna set | 3: a kill heals 1%/piece | 3: dealing damage heals 0.5%/piece (max 3%) | `CActor.OnTakeDamage`, `VampiricSetAbilityRegeneration`, `setBonusAbilityVampire` |
| ARM-14 | Set and armor descriptions | — | New texts for every set bonus and the generic sets, live values, minor-tier counters, set lines on items in the stash (bug fix), crafting schematics and items not owned | `GetSetBonusTooltipDescription`, `AddSetAttributes`, `GetSetArmorItemDescription*`, 37 strings |
| ARM-15 | 5.x's new armor | n/a | n/a (5.x only: Netflix set, Dol Blathanna, White Tiger, `w3r` armor) | none |

### What 5.x changed

| # | Feature | 5.x change (from code and data) |
|---|---|---|
| ARM-01 | Armor pieces | Generic pieces unchanged; rending resistance lowered on the grandmaster school gear, Manticore, the Wolven DLC gear and Tesham Mutna (98 abilities, e.g. Bear chest 0.46 → 0.32), the Feline grandmaster elemental resistance (0.46 → 0.36); every one of these is also changed by legacy |
| ARM-02 | Armor classes | none (no cost terms; glyphwords still change the class, as 1.32) |
| ARM-03 | Armor regen | none |
| ARM-04 | Generic sets | none |
| ARM-05 | Framework | Netflix set added to the enums and checks; `UpdateItemSetBonuses` reports achievement progress and no longer removes extra oils; Viper gear tagged `ViperSet` (no bonus); in NG+ (`items_plus`) every tier of school gear is tagged `SetBonusPiece` |
| ARM-06 | Feline | none |
| ARM-07 | Griffin | none (the free cast is 1.32's) |
| ARM-08 | Bear | Quen boost (tier 2) also for the new tree's supercharged Quen |
| ARM-09 | Wolven | **Replaced:** 3: each Bleeding stack on enemies within 50 m adds +1%/piece to sword damage; 6: adrenaline raises the Bleeding stacks per enemy; oils have no charges and the several-oils code is gone |
| ARM-10 | Manticore | 3: bombs and the new throwing knives without delay (moved from Wolven 6, as legacy); gear toxicity 30 → 20 |
| ARM-11 | Viper | tagged as a set, hidden from set tooltips, no bonus |
| ARM-12 | Kaer Morhen | n/a |
| ARM-13 | Tesham Mutna | none (bonus as 1.32) |
| ARM-14 | Descriptions | new strings for the Netflix set; the Wolven text with its per-piece value |
| ARM-15 | New armor | Netflix set (dlc18: 3 tiers of 4 armor pieces and 2 swords, medium; only the top tier tagged `SetBonusPiece`): 3: potion and decoction duration +7%/piece; 6: Aard hitting enemies inside Yrden deals extra damage scaled by intensity. Dol Blathanna, White Tiger and `w3r` armor: 4 medium pieces each, vanilla-style resistances |

### Classification and action

| # | Feature | Class | Action |
|---|---|---|---|
| ARM-01 | Armor pieces | clean (generic), overlap (set gear) | Legacy's item stats through a generated DLC override (like STAM-08's `gen_npc_stamina.py`); legacy's values where 5.x also changed the item (DA5) |
| ARM-02 | Armor classes and stamina | clean | Port; glyphwords stop changing the class (DA7) |
| ARM-03 | Regen with the option on | clean | Port |
| ARM-04 | Generic sets | clean | Port |
| ARM-05 | Framework | clean (units overlap) | Port on 5.x's functions (Netflix kept in the enums) |
| ARM-06 | Feline | clean | Port |
| ARM-07 | Griffin | clean | Port legacy's redesign (DA1) |
| ARM-08 | Bear | overlap | Legacy (DA8) |
| ARM-09 | Wolven | overlap, needs-decision | Legacy (DA2), re-implementing three oils on one sword |
| ARM-10 | Manticore | overlap (partly in-5.x) | Legacy's crit per piece; the no-delay part is 5.x's already; legacy's toxicity (DA6) |
| ARM-11 | Viper | overlap | Legacy's bonus |
| ARM-12 | Kaer Morhen | clean (new content) | Port as new items through the DLC |
| ARM-13 | Tesham Mutna | clean | Port |
| ARM-14 | Descriptions | clean | Port with each feature's slice |
| ARM-15 | 5.x's new armor | rethink, needs-decision | Owner's call (DA3, DA4) |

---

### ARM-01 Armor pieces: resistances by class, armor by level

| | |
|---|---|
| Kind | tuning, content, fix |
| Pillars | P4, P1 |
| 5.x class | clean (generic pieces), overlap (school, Manticore, Wolven DLC and Tesham Mutna gear: 105 units changed by both) |
| Flags | balance |
| Depends on | DMG (armor and resistance formula), ITEM (item level: `GenerateItemLevel`, `GetItemLevel`), WGT, ECON, CRAFT (the same item entries) |
| Skill trees | n/a |
| Port form | `gm_arm_items.xml` in the DLC's `items/` and `items_plus/`, generated by `tools/gen_arm_items.py`: 5.x's item abilities and entries given whole (`on_conflict="replace"`) with legacy's ARM changes merged in (legacy's own NG+ entries for NG+), legacy's class texts, icons and looks of armor pieces and its abilities for the quest-equipped `Autogen` pieces, and Yoana's reward armor's heavy name, look and armor-stand look (`gm_arm_item_extensions.xml`); `--verify` compares the final items with legacy's; Yoana's bounce chance in DEF-08's replaced `W3ArrowProjectile.OnProjectileCollision` |
| Port status | **signed off** (2026-10-18); **ported, verified** (2026-10-17, both trees) |
| Open checks | a real arrow bouncing off Yoana's armor; Yoana's armor's armor-stand look (not seen); Geralt's hair with Yoana's armor, and with the grandmaster Feline armor under 5.x's hair extensions (on screen; decides the hair deviation below); the armor by level of a generic piece owned before ARM (no such piece on the test saves); the icons and the masked Feline look on screen (read from the definitions); NG+ (checked offline by `--verify` only) |
| Save impact | none (verified: pieces owned before ARM read the new stats, which come from the definitions; armor by level is a count of per-level abilities set when the piece is made, whose value comes from the definitions too); a crafted piece received before `DoNotEnhance` (slice 4) keeps a random bonus it rolled then (stored on the item; from the code, not tested) |
| NG+ counterpart | applied, untested: legacy's own `items_plus` values merged the same way |

**What it does:** every armor piece's protection follows its class (changelist 545–556): resistances low for light, medium for medium, high for heavy, across all five damage types (chest averages: light 4.5%, medium 10.4%, heavy 20.4%; vanilla 10%, 13%, 17.5%); armor comes from the item level (`autogen_armor_armor` 5 per level, pants and boots 2, gloves 2). Rune and glyph slots raised (light and medium pieces up to 3). Unique pieces retuned: Thief armor (`bonus_money`), Ofir armor (per-sign intensity), Oathbreaker armor, Yoana's armor (`q108`: arrows bounce, changelist 144; class changed), the relics' silver studs, gloves with herb chance. School gear stats are with each set (ARM-06 to ARM-13).

**Implementation (legacy):** about 470 item abilities and items (regular) and 580 NG+ copies attributed here; `def_item_weapons_relic_autogen.xml` (armor per level, the autogen pieces). Many pieces lost their fixed armor value for level-based armor and their `item_level_min/max` (ITEM). Legacy also gave ten boots and trousers it moved between light and medium the other class's text, gave each level of 21 boots, gauntlets and one armor its own icon, gave the grandmaster Feline armor a masked look (`t_02_mg__lynx_lvl5`), gave the quest-equipped `Autogen` pieces new abilities (`Autogen Boots _Stats`, `Autogen Pants _Stats`, `Default armor _Stats` on all four), and made Yoana's reward armor (`q108 Medium armor 10`) heavy with a heavy name, look, icon and armor-stand look.

**5.x:** generic armor unchanged; the school gear's rending resistance lowered (see the [table](#what-5x-changed)).

**Decisions:** DA5 (a), the owner's decision (2026-10-17): legacy's values where 5.x also changed the item, including, in an ability legacy rewrote, legacy's value where 5.x lowered one legacy had left at 1.32's. What is ARM's in an item: every stat legacy changed in a piece's abilities except `weight` (WGT), `quality` and `item_level_min/max` (ITEM); the class tags, `gm_NoSetBonuses` (ARM-04) and the enhancement slots of armor pieces; legacy's class texts, icons, looks and `Autogen` abilities above; `DoNotEnhance` where legacy added it, so crafted armor gets no random bonus on top of its stats (the owner's decision on the SWD audit's F4, 2026-10-19). Yoana's reward armor takes legacy's heavy name (`item_name_heavy_armor_03`, "Nilfgaardian guardsman armor"), class text, look, icon and armor-stand look, regular and NG+ (the owner's decision, 2026-10-18). The set gear's own stats (attack power, sign intensity, adrenaline gain, Manticore's toxicity of DA6, ...) come with this feature; each set's entry ports its bonus. The pieces legacy moved to armor by item level are level-scaled by [ITEM-04 and ITEM-05](item.md#item-04-items-moved-to-level-scaling), and legacy's `DoNotEnhance` removals (42 pieces) are applied by [ITEM-08](item.md#item-08-donotenhance-removed). Legacy deleted `NGP DLC Compatibility Chest Armor Mod` (−25 armor) and `NGP DLC Compatibility Armor Mod` (−10), which 5.x's `NewGamePlusAdjustDLCItem` adds to owned NG+ Temerian, Nilfgaardian, Wolven and Skellige pieces; both are given empty in `items_plus/gm_arm_items.xml` (the owner, 2026-11-02). Yoana's armor keeps Geralt's default hair, as legacy: it is taken out of the inquisitor and bowl hair variants of `Preview Hair`, `Half With Tail Hairstyle`, `Long Loose Hairstyle` and Blood and Wine's `Fancy Bowl` (the owner, 2026-11-02).

- **Deviation:** legacy's other display changes to item entries are not carried: the NG+ items' names (legacy shows the regular names in NG+), legacy's NG+-only glove looks (`g_01a_*` on eight crafted gloves) and the quest-equipped `Autogen` trousers' shirt variant and collapse rules; they are cosmetic and not ARM's rules (audit F4; porter's call, confirmed by the owner, 2026-10-18).
- **Deviation:** the grandmaster Feline armor's hair extensions (Blood and Wine's `bob_item_extensions.xml`, the hood hair `c_08_mg__witcher_lx` and the mask variants of `Lynx Armor 4`) stay 5.x's, though legacy removed them with the mask look the port carries; an empty `item_extension` replace is untested, so the owner waits for an on-screen look (the owner, 2026-11-02; temporary, until that look).

**Slices:**

1. **Item stats.** Verified 2026-10-17, both trees (`GMTest_arm01` in the regression, scripted reads of the definitions): legacy's resistances, armor per level, slots and unique values with 5.x's weights; a generic armor made at a level carries its per-level abilities. Save impact: a piece owned before ARM reads legacy's stats when worn (`gmtest_arm01_oldsave`).
2. **DA5 in full, display changes, NG+ tags.** Verified 2026-10-18, both trees (`GMTest_arm_audit` and `GMTest_arm01`, scripted reads of the definitions): DA5's values where 5.x lowered them (e.g. the Manticore set's toxicity 25), the class texts, icons, the Feline template and the `Autogen` abilities. `gen_arm_items.py --verify` compares every ARM tag, slot, display field and ability stat of every regular and NG+ item, as the game reads them, with legacy's: 0 unexplained differences.
3. **Yoana's reward armor as legacy.** Verified 2026-10-18, both trees (`GMTest_arm_audit`, scripted reads: name, class text, template, icon, heavy tag; the bounce chance in `GMTest_arm01`); real, on screen (classic tree): Geralt wears the heavy guardsman armor and the inventory shows the heavy icon.
4. **No random bonus on crafted armor.** Verified 2026-10-19, both trees (`GMTest_arm_dne`, by script: `AddAnItem` runs 5.x's item-received code with its random roll, as crafting and buying do): tagged crafted pieces got no random (`MA_*`) ability, untagged ones did. Since [ITEM-06 and ITEM-09](item.md#item-06-random-bonus-rules) quality-1 pieces and relic chests roll a bonus too, so the tag keeps the bonus off every tagged piece, quality 1 included (whole-port audit A4-2).
5. **NG+ DLC armor and Yoana's hair** (2026-11-02). The emptied NG+ compatibility abilities and the hair variant lists are checked offline by `gen_arm_items.py --verify` (it fails on 5.x's entries); `GMTest_arm01_hair` (regression) guards that the four hair items still read with their tags. Verified in both trees (scripted).

**Later:** —

### ARM-02 Armor classes and stamina costs

| | |
|---|---|
| Kind | system |
| Pillars | P4, P2 |
| 5.x class | clean |
| Flags | balance |
| Depends on | STAM-03 (cost functions), ENCH (Levity, Balance, Heft's new effects), SKL-18 (school perks count pieces by class) |
| Skill trees | n/a (the school perks that read the class are SKL-18's, both trees) |
| Port form | wrappers of `GetStaminaActionCost` and `GetSkillStaminaUseCost`; `@replaceMethod CInventoryComponent.GetArmorType` without the glyphword class change; `GMCountArmorPieces`, `GMGetArmorTypeByName` (`armor/armorClass.ws`); the tooltip's class flag cleared in the `W3TooltipComponent.GetBaseItemData` wrapper (`armor/setTooltips.ws`); the tutorial string 2110992429 (vanilla key `6d1ad461`) in 9 languages |
| Port status | **signed off** (2026-10-18); **ported, verified** (2026-10-17, both trees) |
| Open checks | the class tutorial seen in game (its text is checked by id only); a real dodge, roll and attack in each class (only a real Aard cast was measured); the tooltip's class in the inventory (the flag read by script) |
| Save impact | none |
| NG+ counterpart | none (scripts) |

**What it does** (changelist 233–235, 549–556): melee and agility actions (attacks, dodges, rolls, sprint, jump, parry, counter; not usable items) cost −7.5% per light piece, +12.5% per heavy piece, −12.5% per missing piece (4 light −30%, 4 heavy +50%, naked −50%); signs cost +12.5% per heavy piece. A piece's class comes from the item only: Levity, Balance and Heft no longer change it (their new effects are ENCH's). Applies to Geralt only.

**Implementation (legacy):** `CalcStaminaArmorPenalty`, `CalcSignCastingArmorPenalty` (added), applied in `GetStaminaActionCost` and `GetSkillStaminaUseCost` next to STAM-03's terms; `CountArmorPieces`; `GetArmorType(item, ignoreGlyphwords)` with the glyphword lines commented out; `GetArmorTypeByName` for tooltips; the tooltip's `hasEnchantedType` set false; the class tutorial text (string 2110992429).

**5.x:** no cost by class; glyphwords change the class as in 1.32, and 5.x's tooltip marks an equipped piece's class as changed by them (`hasEnchantedType`).

**Decisions:** port as legacy; DA7 (a), the owner's decision (2026-10-17): the class is the item's. SKL-18's school perks count pieces through `GetArmorType`, so they no longer follow the glyphwords either. Levity, Balance and Heft's legacy stamina trades are [ENCH-10](ench.md#ench-10-levity-balance-and-heft-glyphwords-2-3-4).

**Slices:**

1. **Class costs.** Verified 2026-10-17, both trees (`GMTest_arm02`, scripted cost reads in the regression; gear equipped by script): the costs naked, in light and in heavy armor, usable items unchanged, Heft's ability leaves light armor light, legacy's tutorial text; a real Aard cast (scripted input through the input handler) in four heavy pieces took +50%.
2. **The tooltip's class.** Verified 2026-10-18, both trees (`GMTest_arm_audit`): a tooltip built for the worn armor with Heft's ability on Geralt reads the class flag false.

**Later:** —

### ARM-03 Armor regen with the option on

| | |
|---|---|
| Kind | tuning |
| Pillars | P4 |
| 5.x class | clean |
| Flags | — |
| Depends on | STAM-05 (the option), ARM-01 (item values), ENCH (Hearts of Stone glyphword regen) |
| Skill trees | n/a |
| Port form | `@replaceMethod W3PlayerWitcher.CalculatedArmorStaminaRegenBonus` (`armor/armorRegen.ws`), under STAM-05's option wrapper; the `staminaRegen_armor_mod` values in ARM-01's generated XML |
| Port status | **signed off** (2026-10-18); **ported, verified** (2026-10-17, both trees) |
| Open checks | the regen measured in a fight with the option on (the modifier read) |
| Save impact | none |
| NG+ counterpart | applied (ARM-01's NG+ items), untested |

**What it does** (changelist 243, 1233): only with "Enable stamina regen penalty for armors" on (default off): legacy's calculation (the glyphwords' regen ignored, +11/+2/+3/+4% regen per missing chest/gloves/pants/boots) and legacy's per-piece values (e.g. heavy −0.10 → −0.30).

**Implementation (legacy):** `CalculatedArmorStaminaRegenBonus`; `staminaRegen_armor_mod` in 545 item abilities (shared with STAM-05, which hides the stat while the option is off); the stat name (string 2110992263).

**5.x:** as 1.32.

**Decisions:** port as legacy. The glyphwords' own legacy stamina trades are ENCH's.

**Slices:**

1. **Armor regen with the option on.** Verified 2026-10-17, both trees (`GMTest_arm03` in the regression, the option set by script; gear equipped by script): the bonus naked, in heavy armor, legacy's per-piece values, unchanged with Heft's ability; STAM-05's checks pass with the legacy values.

**Later:** —

### ARM-04 Generic armor set bonuses

| | |
|---|---|
| Kind | system |
| Pillars | P4 |
| 5.x class | clean |
| Flags | balance |
| Depends on | ARM-02 (class counting), DEF-01 (reads the light bonus), ALCH (toxicity decay) |
| Skill trees | n/a |
| Port form | `abilities/gm_armor.xml` (the three abilities, NG+ copy by `gen_ngplus.py`); `GMManageSetArmorTypeBonus`, `GMCountSetArmorPieces`, `GMGetSetArmorType`, `GMIsSetArmorType(ByName)`, `GMGetSetArmorItemDescription`; wrappers of `EquipItemInGivenSlot`, `UnequipItemFromSlot`, the load (`OnSpawned`) and `W3Effect_Toxicity.RecalcEffectValue` (`armor/genericSets.ws`); the tooltip line in `AddSetAttributes`; strings 2110992320–2110992322 in 9 languages |
| Port status | **signed off** (2026-10-18); **ported, verified** (2026-10-17, both trees) |
| Open checks | the tooltip line seen in the inventory; a real dodge at 121–150° in light armor |
| Save impact | none (the bonus is checked at every load) |
| NG+ counterpart | applied, untested |

**What it does** (changelist 561–565): four non-witcher pieces of one class (pieces tagged `gm_NoSetBonuses`, e.g. Ofir and Burning Rose variants, and witcher set pieces do not count): light +30° safe dodge angle, medium toxicity decay +0.25/s, heavy +10% to all resistances. Shown in item tooltips.

**Implementation (legacy):** `ManageSetArmorTypeBonus` grants `ArmorTypeLight/Medium/HeavySetBonusAbility`; `GetSetArmorType`, `IsSetArmorType(ByName)`, `CountSetArmorPieces`; `W3Effect_Toxicity.RecalcEffectValue`; the character panel's toxicity line; `ApplyPatchFixes` for old saves.

**5.x:** none. The port's DEF-01 reads `ArmorTypeLightSetBonusAbility` (`defense/dodge.ws`).

**Decisions:** port as legacy. The bonus is checked at every load, where legacy granted it once on old saves (same result). The tooltip shows the generic line for armor pieces only (legacy filled the set block for any item outside a witcher set; display only). 5.x's new medium armor (Dol Blathanna, White Tiger, Scarlet Crest) counts towards the generic medium set, as legacy's free DLC armor does. The character panel's toxicity decay line counts the medium set (UI-04).

**Slices:**

1. **Generic sets.** Verified 2026-10-17, both trees (`GMTest_arm04` in the regression; gear equipped and taken off by script): four pieces of each class give its set and its value, three give none, a piece taken off ends it. With DEF-01 (`gmtest_arm04_dodge`, scripted hits from a real wolf): in four light pieces a hit at 145° is dodged and one at 155° is not; in medium armor 145° is not dodged.

**Later:** —

### ARM-05 Set framework: minor bonus from every tier

| | |
|---|---|
| Kind | system, fix |
| Pillars | P8 |
| 5.x class | clean (units overlap: 5.x added the Netflix set to the same functions) |
| Flags | — |
| Depends on | ARM-01 (item tags) |
| Skill trees | n/a |
| Port form | enum extensions (`EItemSetType`, `EItemSetBonus`: minor tiers, Viper, Kaer Morhen); `@replaceMethod`s of `SetItemNameToType`, `IsSetBonusActive`, `GetSetPartsEquipped`, `UpdateItemSetBonuses`, `ManageActiveSetBonuses`, `CheckSetType(ByName)`, `SetBonusStatusByType`, `ItemSetTypeToItemSetBonus`, `ManageSetBonusesSoundbanks`, `W3TooltipComponent.AddSetAttributes`, the Fully Armed checks; `GMRecalcSetItemsEquipped` and the Bear sound bank at every load (`armor/setFramework.ws`, `armor/setTooltips.ws`); item tags in `gm_arm_items.xml`, generated by `tools/gen_arm_items.py` (5.x's entries given whole with legacy's set tags merged in; the set swords' entries, with these tags, in SWD's `gm_swd_items.xml`, written by `gen_swd_items.py`) |
| Port status | **signed off** (2026-10-18); **ported, verified** (2026-10-17, both trees) |
| Open checks | the tooltip lines seen in the inventory (scripted only); the set sound banks with lower tiers, and Quen Discharge's Bear sound (not listened to); the achievements themselves (granted through the gamer profile, not readable by script) |
| Save impact | none (verified: items owned before take their tags from the definitions; set pieces are recounted at load) |
| NG+ counterpart | applied, untested: the NG+ items get legacy's tags, and the lower tiers the regular ones' `<School>SetMinor` and `SetBonusPiece` (5.x tags every NG+ tier `SetBonusPiece`, legacy's NG+ entries kept the school tag); checked by `gen_arm_items.py --verify` |

**What it does** (changelist 567–569): every tier of the four school sets counts towards the minor bonus (3 pieces; lower tiers tagged `*SetMinor`); the full bonus (6) needs grandmaster pieces; the tooltip counts both and flags mixed tiers. Viper (3 pieces) and Kaer Morhen (3 of 4) join the system. Set bonus sound banks are reloaded on load (the Bear set's always, "used by regular Quen now", since Quen Discharge plays the Bear set's effects); the "Fully Armed" achievement accepts a full set of lower-tier pieces and no longer needs the school crossbow, and leaves Viper out; "Ready to Roll" needs any full bonus.

**Implementation (legacy):** `playerWitcher.ws` (`IsSetBonusActive`, `GetSetPartsEquipped(Raw)`, `HasMixedSetsEquipped`, `RecalcSetItemsEquipped`, `UpdateItemSetBonuses`, `ManageActiveSetBonuses`, `CheckSetType(ByName)`, `LoadCurrentSetBonusSoundbank`, `CheckForFullyArmedAchievement`), `playerTypes.ws`, `W3GameParams` set tags, `IsItemSetItem`; debug commands (`addset`, `allsets`, `addkmset`, not ported).

**5.x:** the same framework plus the Netflix set; grandmaster-only bonuses. 5.x's Fully Armed checks (`CheckForFullyArmedAchievement`, `HasAllItemsFromSet`, `CheckForFullyArmedByTag`, `DetectTagOfASet`) see only the school tags, so lower-tier sets would count for nothing.

**Decisions:** port as legacy. The Netflix set's lower tiers count towards its minor bonus (DA3, ARM-15: `EIST_Netflix_Minor`). `GetSetBonusAbility`'s new entries come with each set's feature. Set pieces are recounted at every load, where legacy recounted once on old saves (same counts; no behaviour change). 5.x's Viper hiding in the tooltip ended with ARM-11, which gave the set its bonus. The Ready to Roll achievement as legacy (any full bonus), with 5.x's progress notice kept for the grandmaster sets. Fully Armed as legacy (`CheckForFullyArmedAchievement`, `HasAllItemsFromSet`: the four lower-tier tags, no crossbow, no Viper), with 5.x's check and progress notice on equip (`CheckForFullyArmedByTag`, `DetectTagOfASet`) given the same rules.

- **Deviation:** in NG+ the lower tiers of the school gear take the regular lower tiers' tags (`<School>SetMinor`, `SetBonusPiece`): they count towards the first bonus, not the full one. Legacy's NG+ entries kept the school tag (its NGP lower tiers counted for nothing, without `SetBonusPiece`; NG+'s regular-named lower tiers counted as grandmaster pieces); the NG+ rule makes the regular folder's non-numeric change in NG+ (audit F9; porter's call, confirmed by the owner, 2026-10-18).
- **Deviation:** the Bear set's sound bank, loaded at every load for Quen Discharge's Bear effects as legacy, is never unloaded; legacy unloaded it whenever Bear pieces changed below three, until the next load, against its own note that Quen needs it always (audit F6; porter's call, confirmed by the owner, 2026-10-18).
- **Deviation:** Fully Armed is also granted, as in 5.x, by six worn pieces of the Manticore, Tesham Mutna or Netflix sets (5.x's check on equip, `CheckForFullyArmedByTag`); legacy's check covered the four school sets and their lower tiers only (audit F5; porter's call, confirmed by the owner, 2026-10-18).

**Slices:**

1. **Framework, tags and tooltip.** Verified 2026-10-17, both trees (`GMTest_arm05` in the regression, scripted reads of the definitions; `gmtest_arm05_count`, items equipped by script): set tags for regular, expansion and free DLC items, the replaced entries keep their abilities, category and slots; three lower-tier pieces give tier 1 and not tier 2, a grandmaster piece added counts as mixed, the load-time recount agrees. Save impact: on a save made before ARM, owned set pieces have the new tags and count when worn (`gmtest_arm_oldsave`). The tooltip compiles; not seen in the inventory.
2. **Fully Armed and the Bear sound bank.** Verified 2026-10-18, both trees (`gmtest_arm_fullyarmed`, `GMTest_arm_audit`; gear equipped by script): a full lower-tier Feline set of mixed tiers and a grandmaster Bear set without the crossbow make a full set for `HasAllItemsFromSet`; `DetectTagOfASet` gives a lower-tier piece's minor tag; the Bear bank is loaded after a load with no Bear piece worn (`SoundIsBankLoaded`).

**Later:** —

### ARM-06 Feline (Cat) set

| | |
|---|---|
| Kind | system, tuning |
| Pillars | P8 |
| 5.x class | clean |
| Flags | balance |
| Depends on | ARM-05, DMG-03/04 (attack power, the pool), SKL-07 (adrenaline gain), DEF-06 (counter keeps the chain) |
| Skill trees | n/a |
| Port form | `armor/felineSet.ws`: `W3Effect_LynxSetBonus` reworked (fields and methods added, `OnEffectAdded`, `OnEffectRemoved`, `OnResumed` replaced, `OnUpdate` overridden in a scope block), a wrapper of `W3PlayerWitcher.OnProcessActionPost` (the chain, the crit's adrenaline), `GMLynxSetAttackPower` in DMG-03's `GetAttackersPowerMod`; 5.x's Feline terms removed from `damage/pool.ws`; the counter in DEF-06's `PerformCounterCheck` (`defense/counter.ws`); the HUD counter: `@replaceMethod CR4HudModuleBuffs.OnTick` (`mutations/hudCounters.ws`) sends the chain's percentage each frame, as legacy (5.x's sends 1/1 for an effect without a duration); `LynxSetBonusEffect`, `setBonusAbilityLynx_2` given whole in `gm_armor_sets.xml`; strings 2110992106, 2110992109 |
| Port status | **signed off** (2026-10-18); **ported, verified** (2026-10-17, both trees) |
| Open checks | real attacks and a real counter in a fight (scripted hits; the counter's line read); the sword effect seen |
| Save impact | none (the effect's chain is not saved; a running effect from an old save starts at 0) |
| NG+ counterpart | applied, untested |

**What it does** (changelist 578–581, 600): tier 1: each fast hit in a chain adds +2.5% attack power per piece (+15% per hit at 6), up to +60%; a strong hit ends the chain at double the bonus; the chain breaks when hits stop (a counter keeps it) and at combat end. Tier 2: sword crits double the adrenaline gained. Gear: attack power up to +30%, crit chance; tiers at levels 17/23/29/34 (vanilla 19/25/31/36), grandmaster 40.

**5.x:** 1.32's bonus (fast attacks +10%/piece after a strong attack; rear attacks +50% and a stun for 1 adrenaline).

**Decisions:** port as legacy. The crit's double adrenaline adds the hit's gain once more (divided by Adrenaline Rush's multiplier, which the gain passes through again), the same as legacy's doubling before that multiplier; legacy's Bear School term in between counts heavy pieces, which a full Feline set does not have. The character panel's fast and strong attack power include the Feline chain (UI-01).

**Slices:**

1. **Feline set.** Verified 2026-10-17, both trees (`gmtest_arm06`, `gmtest_arm06_decay`, scripted sword hits on a neutral test dummy, attack power read by the damage probe; `GMTest_arm06` in the regression): the chain's attack power per fast hit, the strong hit's double bonus and the chain's end, the 60% cap, the chain breaking after the last hit, a sword crit's double adrenaline; 5.x's rear-attack values gone; legacy's texts.
2. **The HUD counter.** Verified 2026-10-18, both trees, on screen (chain built by scripted hits): the Feline buff shows the chain's percentage.

**Later:** —

### ARM-07 Griffin (Gryphon) set

| | |
|---|---|
| Kind | system, tuning |
| Pillars | P2, P3 |
| 5.x class | clean |
| Flags | balance |
| Depends on | ARM-05, STAM-03 (costs), SKL-10 (Yrden), SKL-18 (Rage Management's free-cast branch) |
| Skill trees | both (signs; the classic and the new tree cast the same signs) |
| Port form | `armor/gryphonSet.ws`: wrappers of `W3PlayerWitcher.OnSignCastPerformed` (the buff), `OnSpawned` (removed at load), `GetStaminaActionCost` and `GetSkillStaminaUseCost` (the cut); `@replaceMethod`s of `W3SignEntity.ManageGryphonSetBonusBuff` (emptied) and `W3SignOwnerPlayer.ChangeAspect` (5.x's block on alternate casts removed); 5.x's free cast removed from the replaced `ManagePlayerStamina`, `HasStaminaToUseSkill` (`skills/rageManagement.ws`) and the sign's `OnThrowing` (`skills/signSlots.ws`); the damage reduction removed from `defense/dodge.ws`; `GryphonSetBonusEffect` and `GryphonSetBonusYrdenEffect` given whole in `abilities/gm_armor_sets.xml`; the descriptions in `armor/setDescriptions.ws` (`@replaceMethod GetSetBonusTooltipDescription`, ARM-14), strings 2110992107 and 2110992108 (vanilla keys) in 9 languages |
| Port status | **signed off** (2026-10-18); **ported, verified** (2026-10-17, both trees) |
| Open checks | a real dodge or attack during the buff (measured by script); the buff icon and the set texts seen in game (texts read by script) |
| Save impact | none (the buff is removed at load) |
| NG+ counterpart | applied, untested (`abilities_plus/gm_armor_sets.xml`, same values) |

**What it does** (changelist 576–577, 598–599): tier 1: any sign cast starts a 2.5 s buff (not refreshed while it runs) during which sign, melee and agility stamina costs are 5% lower per piece (−30% at 6). Tier 2: Yrden traps +40%; inside a normal Yrden, sign intensity +50% and +15% to all resistances; no regen bonus. Gear: sign intensity (crit removed); tiers 11/18/26/34.

**5.x:** 1.32's free cast (after a sign paid with stamina, the next one within 3 s is free; a free alternate cast below full stamina); tier 2's −20% damage taken.

**Decisions:** DA1 (legacy's redesign, as the owner deferred it to ARM, 2026-10-16). 5.x's `Glyphword 22 Bonus` free cast is ENCH's. As in legacy's code, the cast that starts the buff is itself discounted: the sign calls `OnSignCastPerformed` from its throw, before it pays (legacy and 5.x alike); the description's "subsequent actions" is legacy's text. The Netflix set's tier 2 (DA3) reads enemies inside Geralt's Yrden, the Griffin set's tier 2 Geralt inside it; both cannot be worn at once (six pieces each), so they do not stack. `ManageActiveSetBonuses` also ends the Griffin buffs when lower-tier pieces come off (legacy only for grandmaster pieces; no effect found: the buff lasts 2.5 s, and the inside-Yrden buff needs grandmaster pieces anyway). The larger Yrden trap is SKL-10's code (5.x's trigger scaling in `Place`).

**Slices:**

1. **Griffin set.** Verified 2026-10-17, both trees (`gmtest_arm07`, `_b`, `_c`, scripted; gear equipped by script; `GMTest_arm07` in the regression): tier 1 from three lower-tier pieces, the buff's length and cost cut, tier 2's inside-Yrden resistance and intensity; no free cast. Real casts (`autocast`): Aard and Igni during the buff took the cut cost, a real Yrden at tier 2 gave the inside-Yrden buff, a held Igni at half stamina with the buff started Firestream (5.x refused it; classic).

**Later:** —

### ARM-08 Ursine (Bear) set

| | |
|---|---|
| Kind | system, tuning |
| Pillars | P2, P8 |
| 5.x class | overlap |
| Flags | balance, needs-decision |
| Depends on | ARM-05, SKL-07 (adrenaline loss on hits), SKL-11 (Quen Discharge), DMG-03 (attack power), STAM-03, ENCH (Glyphword 5) |
| Skill trees | both (Quen Discharge on the classic and the new tree's slot) |
| Port form | `armor/bearSet.ws`: `GMBearSetHitAdrenaline`, `GMBearSetAttackPower`, a wrapper of `W3PlayerWitcher.OnProcessActionPost` (the refund); `@replaceMethod`s of `W3QuenEntity.OnStarted` and `QuenChanneled.ShowHitFX` (the effects for Quen Discharge), `W3QuenEntity.ForceFinishQuen` (no free recast) and `ShieldActive.OnEnterState` (no Bear effect, no Bear knockdown rule); terms in SKL-07's adrenaline loss (`defense/processAction.ws`) and DMG-03's `GetAttackersPowerMod` (`damage/formula.ws`); the Quen boost removed from `skills/quen.ws`; `setBonusAbilityBear_1/2` given whole in `gm_armor_sets.xml`; strings 2110992325, 2110992336 |
| Port status | **signed off** (2026-10-18); **ported, verified** (2026-10-17, both trees) |
| Open checks | a real hit taken, a real strong attack and a real Rend refund in a fight (scripted hits); the Quen effects seen (checked by `IsEffectActive`) |
| Save impact | none |
| NG+ counterpart | applied, untested |

**What it does** (changelist 582–584, 601–602): tier 1: hits taken give +0.035 adrenaline per piece (0.21 at 6, offsetting the loss on hits); +3.5% attack power per piece per adrenaline point (melee and bolts). Tier 2: a strong attack or Rend that deals damage (not dodged, parried or countered) refunds 33.4% of its stamina. The vanilla Quen rules (free recast, +200% Quen damage) are gone; their visual effects (`default_fx_bear_abl2`, `quen_rebound_sphere_bear_abl2`, `quen_lasting_shield_bear_abl2`) were given to Quen Discharge. Gear: adrenaline gain up to +126% across the set, swords +20–40% attack power; tiers 20/25/30/34.

**5.x:** 1.32's, and the tier 2 Quen boost also applies to the new tree's supercharged Quen.

**Decisions:** DA8 (legacy). Quen Discharge's effects play in both trees (legacy keys them on the discharge share, which the port computes for either tree's skill). The character panel's attack power includes the Bear set's term, melee and crossbow (UI-01).

**Slices:**

1. **Bear set.** Verified 2026-10-17, both trees (`gmtest_arm08`, scripted hits on a hostile test dummy; `GMTest_arm08` in the regression): the adrenaline on a hit taken, the attack power per adrenaline point, a strong attack's refund and none for a fast attack; 5.x's Quen values gone; legacy's texts. Real casts (`autocast`): an alternate Quen with Quen Discharge played the Bear effect; with six grandmaster pieces its discharge share stayed unboosted.

**Later:** —

### ARM-09 Wolven set

| | |
|---|---|
| Kind | system, tuning |
| Pillars | P8 |
| 5.x class | overlap, needs-decision |
| Flags | balance, needs-decision |
| Depends on | ARM-05, SKL-14 (oils: one oil per sword, legacy's decay), ALCH (oil items) |
| Skill trees | both (Fixative's and Hunter Instinct's slots read the same oils) |
| Port form | `armor/wolfSet.ws`: `GMWolfOilMult` (tier 1) in SKL-14's `W3Effect_Oil.GMBonus` (`skills/oils.ws`); `GMOilWolfCritBonus` (tier 2) in SKL-14's replaced `GetCriticalHitChance` and `CR4Player.GetCriticalHitDamageBonus`; three oils at once in SKL-14's replaced `ApplyOil` (`GMMaxOilsPerSword`, 5.x's `RemoveOldestOilFromItem`); `@replaceMethod W3PlayerWitcher.RemoveExtraOilsFromItem` (legacy's body: the newest oil stays), called from the replaced `UpdateItemSetBonuses` (`armor/setFramework.ws`); 5.x's bleeding terms removed: the pool term (`damage/pool.ws`) and the wound stacks in `W3EffectManager.InternalAddEffect`, turned off by a wrapper that sets a flag read in the replaced `IsSetBonusActive` (instead of replacing that 260-line function); `@replaceMethod GetSetBonusAbility` (`EISB_Wolf_2`); `SetBonusAbilityWolf_1/2` given whole in `gm_armor_sets.xml`; strings 2110992091, 2110992326 |
| Port status | **signed off** (2026-10-18); **ported, verified** (2026-10-17, both trees) |
| Open checks | a real fight with three oils (scripted hits and reads); the oil tooltip, the HUD's oil icons and the set texts seen in game (texts read by script) |
| Save impact | none (verified: three oils on a sword survive a save and load with tier 2) |
| NG+ counterpart | applied, untested (`abilities_plus/gm_armor_sets.xml`, same values) |

**What it does** (changelist 585–589, 603–604): tier 1: every oil effect +16.7% per piece (+100% at 6), with SKL-14's decay. Tier 2: three different oils on one sword at once, each +5% crit chance and +10% crit damage. Gear: hybrid (adrenaline gain, attack power and intensity up to +30%); tiers 21/24/28/34.

**5.x:** bleeding design: tier 1, each Bleeding stack on enemies within 50 m adds +1% sword damage per piece; tier 2, adrenaline raises the Bleeding stacks per enemy. Oils have no charges, and the several-oils code is gone.

**Decisions:** DA2. Tier 1 boosts the oil's own bonuses (attack power, resistance reduction, crit chance and damage against its monster type), not Poisoned Blades or Protective Coating, as legacy. Tier 2's crit chance counts for melee attacks with the held sword, its crit damage for the attacking sword, both whatever the enemy and wearing off with each oil, as legacy. Only Hanged Man's Venom and Beast Oil fit a steel sword (legacy and 5.x alike), so three oils fit only a silver sword. 5.x also calls `RemoveExtraOilsFromItem` when Fixative is taken off, where its body removed every oil; with legacy's body the sword's newest oil stays (legacy did not call it there; with one oil per sword the result is legacy's). The oil item tooltip shows the Wolven tier 1 boost (UI-06, legacy's `AddOilStats`).

**Slices:**

1. **Wolven set.** Verified 2026-10-17, both trees (`gmtest_arm09`, `gmtest_arm09_b`; oils applied by script through `ApplyOil`; scripted sword hits on a neutral human test dummy, attack power read by the damage probe; `GMTest_arm09` in the regression): an oil's bonus with three and six pieces, also in a hit; without tier 2 a new oil replaces the old; with tier 2 three oils on the silver sword, a fourth replacing the oldest; the crit chance and damage per oil, decaying with the oil; no bleeding wound stack; a piece taken off ends tier 2 and leaves the newest oil. Save impact: six pieces and three oils survive a save into a new slot and its load (`gmtest_arm09_oldsave`).

**Later:** —

### ARM-10 Manticore set

| | |
|---|---|
| Kind | tuning |
| Pillars | P8 |
| 5.x class | overlap (no-delay throw: in-5.x) |
| Flags | balance |
| Depends on | ARM-05, SKL-15 (bombs), DMG-03 (crit check), ALCH (potion duration, toxicity) |
| Skill trees | n/a |
| Port form | `armor/manticoreSet.ws`: `GMManticoreBombBonus`, `GMManticoreBombCritChance`, a wrapper of `W3DamageManagerProcessor.ProcessCriticalHitCheck` that rolls the set's bombs' crit chance (5.x's roll has no per-piece term; as MUT-03's Magic Sensibilities wrapper); the crit damage term in DMG's `GetAttackersPowerMod` (`damage/formula.ws`); `setBonusAbilityRedWolf_1` (new: 5.x has none) in `gm_armor_sets.xml`; `GetSetBonusAbility`'s `EISB_RedWolf_1`; string 2110992090; gear in ARM-01's XML |
| Port status | **signed off** (2026-10-18); **ported, verified** (2026-10-17, both trees) |
| Open checks | a bomb crit seen in a real fight without the debug fact (the chance is read by script) |
| Save impact | none |
| NG+ counterpart | applied, untested (`abilities_plus/gm_armor_sets.xml`, same values) |

**What it does** (changelist 592–594, 605): tier 1: bombs thrown without delay and able to crit, +5% bomb crit chance and +10% bomb crit damage per piece. Tier 2: +1 charge per alchemy item (unchanged). Gear: +25 maximum toxicity, +25% potion duration (not in the changelist).

**5.x:** no delay already on tier 1 (and for throwing knives); toxicity +20.

**Decisions:** legacy's crit per piece; DA6 for toxicity (ARM-01). Legacy's NG+ file also rewrote `NGP Red Wolf Pants 2 _Stats` (armor 145, resistances 7/4/4/7/7%, +5 toxicity, +5% potion duration; 5.x: armor 151, 8/0/0/10/30%, +10% attack and sign power), an ability no item of 1.32, legacy or 5.x names in either folder (the only second-tier trousers are `Red Wolf Pants 2`, with `Red Wolf Pants 2 _Stats`, ARM-01's), so it most likely has no effect in play; it is carried anyway, with legacy's stats and WGT-03's weight (`gen_arm_items.py`'s `UNLISTED`; whole-port audit C3-1, 2026-11-03). The gear's potion duration does not raise bomb damage (5.x's rule, removed with ALCH's DL7, [ALCH-14](alch.md#alch-14-bombs)). The set's bombs roll Geralt's crit chance plus the set's; that crit chance includes legacy's blindness bonus (Samum +50/75/100%, the larger of it and confusion's, ALCH-14), and 5.x's certain crit against a level 3 Samum's blindness is gone.

**Slices:**

1. **Manticore set.** Verified 2026-10-17, both trees (`gmtest_arm10`, `_b`, `_c`; `GMTest_arm10` in the regression): the bomb crit chance per piece; real throws of Dancing Star (scripted input) with every hit made a crit (`debug_fact_critical_boy`) carried the crit damage per piece, read by the damage probe; nothing without the set; legacy's text.

**Later:** —

### ARM-11 Viper set

| | |
|---|---|
| Kind | content, system |
| Pillars | P8 |
| 5.x class | overlap |
| Flags | — |
| Depends on | ARM-05, DMG-05 (`ProcessActionDamage`), ALCH (Golden Oriole) |
| Skill trees | n/a |
| Port form | `armor/viperSet.ws` (`GMViperPoisonHealRate`); the term in DMG's replaced `ProcessActionDamage` (`damage/pipeline.ws`), after 5.x's Golden Oriole block; 5.x's Viper hiding removed from the replaced `AddSetAttributes` (`armor/setTooltips.ws`); `setBonusAbilityViper_1` (new: 5.x has none) in `gm_armor_sets.xml`; string 2110992323 (key `skill_desc_viper_set_ability1`); tags and gear in ARM-01's XML |
| Port status | **signed off** (2026-10-18); **ported, verified** (2026-10-17, both trees) |
| Open checks | a real poison effect or poisoned weapon on Geralt with the set (scripted poison hits; the poison effect deals the same damage type); the tooltip seen |
| Save impact | none |
| NG+ counterpart | applied, untested |

**What it does** (changelist 590–591, 750): with 3 Viper pieces (Hearts of Stone; armor and swords), poison damage is cancelled and heals 10% of it per piece (60% at 6). Armor pieces +5 maximum toxicity each (not in the changelist); poison resistance removed from the gear.

**5.x:** the gear tagged `ViperSet`, no bonus, hidden from set tooltips.

**Decisions:** port as legacy. 5.x's Golden Oriole absorption (level 3) is gone (ALCH-05); the set heals from the raw poison damage, before resistances, as legacy.

**Slices:**

1. **Viper set.** Verified 2026-10-17, both trees (`gmtest_arm11`, scripted poison damage hits of Geralt on himself; `GMTest_arm11` in the regression): without the set the hit took Vitality; with three and four pieces it healed 30% and 40% of the damage; legacy's text.

**Later:** —

### ARM-12 Kaer Morhen set

| | |
|---|---|
| Kind | content, system |
| Pillars | P8 |
| 5.x class | clean (new content) |
| Flags | balance |
| Depends on | ARM-05, CRAFT (schematics, crafting costs), STAM-04 (regen) |
| Skill trees | n/a |
| Port form | `items/gm_arm_kaer_morhen.xml` and its `items_plus` twin, generated by `tools/gen_arm_km.py` (legacy's items, abilities and schematics, and the NG+ pieces' 16 `Base Kaer Morhen … _Stats` abilities that legacy defines only in `items_plus`; the starting items given whole with legacy's name keys); `armor/kaerMorhenSet.ws`: `W3GMEffect_KaerMorhenSetBonus` (`EET_GMKaerMorhenSetBonus`, ability `GMKaerMorhenSetBonusEffect` in `gm_effects.xml`), the schematics granted once at load (fact `gm_km_schematics_added`), wrappers of `OnSpawned`, `OnCombatStart`, `OnCombatFinished` and `NewGamePlusInitialize` (NG+ items through 5.x's `NewGamePlusReplaceItem`), the set's effect from the replaced `ManageActiveSetBonuses`; a wrapper of `W3PlayerWitcher.AddCraftingSchematic` that never teaches 5.x's "Starting Armor Upgrade schematic 1", removed from saves at load (`GMRemoveStartingArmorUpgradeSchematic`); strings 2110992360–2110992380 |
| Port status | **signed off** (2026-10-18); **ported, verified** (2026-10-17, both trees; the schematic removal 2026-10-18; the NG+ base abilities 2026-11-02) |
| Open checks | crafting a piece at an armorer and wearing the set in a real fight (equipped by script, enemies frozen dummies); the regen itself measured (the attribute read); NG+ |
| Save impact | the schematics are granted at load (as legacy), and 5.x's "Starting Armor Upgrade schematic 1" removed (verified; Starting Armor 1 already made stays); a save keeps the pieces (verified). Removing the mod mid-playthrough is not supported ([save compatibility](../feature-mapping.md#save-compatibility)); as facts: the Kaer Morhen pieces vanish from the save, worn ones leaving their slots empty (verified), 5.x teaches its schematic again at the next load, and whether the save keeps the Kaer Morhen schematics is not probed (not needed under that policy) |
| NG+ counterpart | NG+ items (`NGP Kaer Morhen *`) replace the regular ones at the start of New Game+, as legacy; untested |

**What it does** (changelist 572–575): a 4-piece medium set from the start: the starting armor becomes "Worn Kaer Morhen" armor, upgraded to the set's tiers at levels 2, 9, 19 and 27 (schematics known from the start); tier 1 (3 pieces): +1 stamina regen per second per additional enemy in combat (max +5). No swords.

**Implementation (legacy):** 16 items and their abilities, 15 schematics plus the starting armor upgrade, `KaerMorhenSetBonusEffect`, `W3Effect_KaerMorhenSetBonus` (recounted every second), `OnCombatStart`/`OnCombatFinished`, `OnSpawned` (schematics, fact `ModSignsKMSetSchematicsAdded`), NG+ functions, 21 strings (names and the bonus).

**Decisions:** port as legacy. Appearance: legacy reuses the Viper templates and a generic icon. The effect, its ability and the fact carry Ghost Mode's prefix (legacy: `KaerMorhenSetBonusEffect`, `ModSignsKMSetSchematicsAdded`); the effect is removed at every load and at combat end and added at combat start or when the set is completed in combat, as legacy.

- **Deviation:** the first armor schematic is a new "Kaer Morhen Armor schematic" (Starting Armor to Kaer Morhen armor), known from the start like the others, where legacy turned 5.x's "Starting Armor Upgrade schematic 1" into the Kaer Morhen schematic: a DLC cannot override a schematic (the crafting manager would read both). 5.x's schematic is never taught (5.x teaches it at every spawn; any other source goes through the same function) and is removed from saves at load, so the starting armor upgrades only to Kaer Morhen armor, as legacy (the removal: the owner's decision, 2026-10-17; the new schematic's name: porter's call, confirmed by the owner, 2026-10-18).

**Slices:**

1. **Kaer Morhen set.** Verified 2026-10-17, both trees (`GMTest_arm12` in the regression, `gmtest_arm12`, `_b` with three hostile test dummies; gear equipped by script): the 16 pieces with the set tag, the medium class and legacy's stats; the schematics' results; Geralt knows the 16 schematics after a load; the starting armor's name; three pieces of mixed tiers give the set; in combat with three enemies the regen bonus for the extra enemies, gone with the gear off. Save impact: the set survives a save into a new slot and its load (`gmtest_arm12_oldsave`); with the mod disabled the save loads without the pieces.
2. **5.x's first starting armor upgrade removed.** Verified 2026-10-18, both trees (`GMTest_arm15` in the regression): after a load Geralt does not know 5.x's schematic and knows the Kaer Morhen one; teaching it by script is refused; a save made before loads without it (`gmtest_arm15_oldsave`).
3. **New Game+ base abilities** (2026-11-02). Checked offline: `gen_arm_km.py --verify` (every legacy Kaer Morhen ability present in each folder, every ability the file's items name defined) and `dlc_conflicts.py`'s guard (no DLC item names an ability nobody defines). A regular game does not read NG+ data (`gmtest_arm12_ngplus()` reads none), so this is not in the regression.

**Later:** —

### ARM-13 Tesham Mutna (Vampire) set

| | |
|---|---|
| Kind | tuning |
| Pillars | P8 |
| 5.x class | clean |
| Flags | balance |
| Depends on | ARM-05, DMG-10 (non-deadly fights: no heal in fistfights) |
| Skill trees | n/a |
| Port form | `armor/vampireSet.ws`: `@replaceMethod W3PlayerWitcher.VampiricSetAbilityRegeneration` (legacy's body: the ability's share per piece of every tier, no drain effect); the heal on damage dealt in MUT's replaced `CActor.OnTakeDamage` (`mutations/takeDamage.ws`); 5.x's kill heal in `CNewNPC.OnDeath` turned off by a wrapper that sets a flag the heal reads (instead of replacing that event); `setBonusAbilityVampire` given whole in `gm_armor_sets.xml`; string 2110992430 |
| Port status | **signed off** (2026-10-18); **ported, verified** (2026-10-17, both trees) |
| Open checks | real hits in a fight; no heal in a real fistfight (code read) |
| Save impact | none |
| NG+ counterpart | applied, untested (`abilities_plus/gm_armor_sets.xml`, same value) |

**What it does** (changelist 607–609): dealing damage in combat heals 0.5% of maximum Vitality per piece (3% at 6), instead of 1% per piece per kill. Gear resistances retuned (5.x also lowered them: DA5).

**Decisions:** port as legacy. Legacy's heal on damage dealt has no combat check of its own (the changelist's "in combat"): any hit of Geralt's that deals damage heals, as in legacy's code. Legacy also dropped the drain effect 5.x plays on every heal.

**Slices:**

1. **Tesham Mutna set.** Verified 2026-10-17, both trees (`gmtest_arm13`, scripted sword hits; `gmtest_arm13_kill_a/b`, classic; `GMTest_arm13` in the regression): no heal without the set, 0.5% per piece with it; a killing hit heals once, with no kill heal after it; legacy's text.

**Later:** —

### ARM-14 Set and armor descriptions

| | |
|---|---|
| Kind | ui, fix |
| Pillars | P7 |
| 5.x class | clean |
| Flags | — |
| Depends on | ARM-02 to ARM-13 (values), UI (tooltips) |
| Skill trees | n/a |
| Port form | `@replaceMethod`s of `GetSetBonusTooltipDescription` (`armor/setDescriptions.ws`, every set's text with each set's slice), `W3TooltipComponent.AddSetAttributes`, `CInventoryComponent.IsItemSetItem` and `CDefinitionsManagerAccessor.IsItemSetItem` (lower tiers and Kaer Morhen are set items); wrappers of `W3TooltipComponent.GetBaseItemData` (the generic set line) and `W3GuiPlayerInventoryComponent.GetCraftedItemInfo` (the schematics' set lines, overwritten as legacy's) (`armor/setTooltips.ws`); strings under legacy's ids in 9 languages (as SKL-19), 2110992474 for the generic sets on schematics |
| Port status | **signed off** (2026-10-18); **ported**: texts and set-item rules **verified** (2026-10-17, both trees); the two tooltip wrappers **compile** |
| Open checks | the item tooltips and the crafting schematics' set lines seen in the inventory and at an armorer (texts and rules read by script; the flash objects not built in a test) |
| Save impact | none |
| NG+ counterpart | none |

**What it does:** texts with live values for every set bonus and the three generic sets; the tooltip counts lower tiers and flags mixed sets; set lines for items in the stash and shops (changelist 106, read by item name) and on crafting schematics; set colour only for real set pieces (changelist 183); the armor class tutorial text; Kaer Morhen names.

**Decisions:** port with each feature's slice, as MUT-14: every set's text with its set (ARM-04 to ARM-13), the class tutorial with ARM-02, the stash fix and lower-tier counts with ARM-05, the Netflix set's texts with ARM-15. Manticore's tier 2 keeps 5.x's text (unchanged bonus). Every set text's arguments are legacy's; the texts use `NoTrailZeros` where legacy used `FloatToString` (same numbers, without trailing zeros).

**Slices:**

1. **Leftover texts and tooltip rules.** Verified 2026-10-17, both trees (`GMTest_arm14` in the regression, scripted reads): lower-tier, Kaer Morhen and grandmaster pieces are set items and a generic piece is not; every set bonus has a filled-in text. The generic set line and the schematics' set lines compile; not seen.

**Later:** —

### ARM-15 5.x's new armor

| | |
|---|---|
| Kind | content, tuning |
| Pillars | P4, P8 |
| 5.x class | rethink |
| Flags | balance, needs-decision |
| Depends on | ARM-01, ARM-05, ALCH (potion duration), SKL-08/10 (Aard, Yrden) |
| Skill trees | n/a |
| Port form | `items/gm_arm_new.xml` and its `items_plus` twin, generated by `tools/gen_arm_new.py` (5.x's abilities and items given whole with DA3's and DA4's values and the lower Netflix tiers' `NetflixSetMinor`, `SetBonusPiece`; the Netflix swords' entries, with these tags, are written by `gen_swd_items.py` since SWD-10); `armor/netflixSet.ws`: `EIST_Netflix_Minor` counted in ARM-05's replaced framework functions (`armor/setFramework.ws`), a wrapper of `W3DamageAction.GetPowerStatValue` (the +0.5 for a sign's damage action), the same term in SKL-09's `W3IgniProjectile.ProcessCollision` (Melt Armor, Firestream) and SKL-12's `W3AxiiEntity.OnEnded` (per target); potions only in SKL-13's `CalculatePotionDuration` (`skills/brewing.ws`); 5.x's Aard damage removed from DMG-04's pool (`damage/pool.ws`); `SetBonusAbilityNetflix_1/2` in `gm_armor_sets.xml`; strings 2110992631, 2110992632 (vanilla keys) in 9 languages |
| Port status | **signed off** (2026-10-18); **ported, verified** (2026-10-18, both trees) |
| Open checks | the items worn in a real fight and their tooltips seen; Quen's shock, Melt Armor and Firestream inside Yrden (same power terms, not measured); a lower-tier piece's NG+ copy; real potions drunk with the set (durations read by script) |
| Save impact | none (verified: Netflix pieces owned before ARM-15 read the new stats and tags) |
| NG+ counterpart | applied, untested: `items_plus` (including 5.x's `NGP` items) with the [NG+ rule](../feature-mapping.md#ng-numbers); resistances keep Ghost Mode's value, as legacy kept its armor resistances in NG+ |

**What it does:** 5.x's new armor under Ghost Mode's rules (legacy has none of it). The Netflix set ("Forgotten Wolven", medium, 3 tiers of 4 armor pieces and 2 swords, plus Reinald's two swords): every tier counts for the first bonus; 3 pieces: potions (not decoctions) last 7% longer per piece; 6 top-tier pieces: +0.5 sign intensity for every sign effect against enemies inside Geralt's Yrden but Yrden's own slow and shock; armor and resistances like legacy's grandmaster Griffin set; gloves Yrden intensity, trousers sign intensity. Dol Blathanna, White Tiger and Scarlet Crest get medium resistances (Scarlet Crest: high physical, none against rending and elemental damage). 5.x's version: set bonus from the top tier only, potions and decoctions, Aard damage against enemies inside Yrden; vanilla-style resistances that would out-protect Ghost Mode's medium armor.

**Decisions:** the owner's decisions DA3 and DA4 (project owner, 2026-10-17).

**DA3, the Netflix set** ("Forgotten Wolven", tiers at levels 21/35/41, which stay), under Ghost Mode's rules:

- Every tier counts toward the 3-piece bonus.
- Armor and resistances in line with legacy's grandmaster Griffin set: the top tier about armor 476 (487 since the levels were aligned, 2026-11-03) and resistances 35/20/20/35/35 (slashing/piercing/bludgeoning/rending/elemental, %), the lower tiers scaled to their levels.
- The 3-piece bonus: potions only, +7% duration per piece (no decoctions).
- The 6-piece bonus: 5.x's Aard-in-Yrden direct damage (overtuned by its current-health term) is replaced by +0.5 sign intensity (flat points, like Griffin's +50%) for every sign effect against enemies inside Geralt's Yrden: damage, knockdown, Axii, Melt Armor and so on. Yrden's own slow and shock are excluded.
- Per piece: the chest keeps attack power and adrenaline gain (`focus_gain`); the gloves become Yrden intensity (5.x: Aard), with the boots' per-tier values; the boots stay Yrden; the trousers' stamina regen (`staminaRegen_armor_mod`, inert without STAM-05's option) and their inert base `spell_power` are replaced by sign intensity for all signs (mult), +12% at the top tier and scaled like 5.x's 0.05/0.10/0.12 for the lower tiers.

**DA4, 5.x's other new armor**, under Ghost Mode's medium-armor rules at their current levels:

- Dol Blathanna "Thousand Flowers" (level 8): Ghost Mode's medium resistances. The chest's stamina regen modifier is replaced by Igni +10% and Aard +10%; the gloves keep Igni +5% and Aard +5%, so the set totals +15% each.
- White Tiger of the West (level 12): Ghost Mode's medium rules; its extras (chest +75 Vitality, gloves +5% poison resistance, trousers adrenaline gain) stay.
- Scarlet Crest (`w3r`, level 41; the player gets it as an account reward, confirmed by the project owner, 2026-10-19): armor 465; resistances slashing 40, piercing 32, bludgeoning 44, rending 0, elemental 0 (a deliberate weakness: high physical resistance for a medium set, below every comparable heavy armor, all of which are at 53%+ on every type); Quen +35% and adrenaline gain 0.22 stay. Its 8.2 weight goes to WGT.
- The Nilfgaardian guardsman heavy armor and gauntlet re-skins are covered by ARM-01.

How the port reads them: the top tier per piece is legacy's grandmaster Griffin piece's resistances (17/9/9/17/17% chest, 6/4/4/6/6% boots, 5/3/3/5/5% gloves, 7/4/4/7/7% trousers) with armor at level 41 (230/87/83/87; legacy's Griffin piece: 225/85/81/85); "inside Geralt's Yrden" is an enemy the trap holds (its targets list, as 5.x's own Aard bonus read it; flying enemies count once grounded); the bonus applies to the power a sign's action carries to its target (damage, effect chances and the power of its effects: knockdowns, burning, confusion, Quen's shock), Melt Armor, Firestream and Axii's duration; both bonuses read their values from `SetBonusAbilityNetflix_1/2`. The lower Netflix tiers keep `NetflixSet`, so 5.x's Fully Armed counts them (5.x's rule).

- The lower Netflix tiers keep the top tier's resistances and scale only their armor by level (Ghost Mode's rule, resistances by class and armor by level, as legacy's Griffin tiers) (porter's call, confirmed by the owner, 2026-10-18). Each tier's armor reads exactly the tier's level under [ITEM-01](item.md#item-01-item-level-from-stats)'s formula, the level of its swords: chest 130/200/230, boots and trousers 47/75/87, gloves 43/71/83 at levels 21/35/41 (the owner's decision, 2026-11-03, whole-port audit A4-3; previously one level lower, from legacy's grandmaster Griffin values). Verified in both trees (scripted: `GMTest_data_items` in the regression).
- Dol Blathanna and White Tiger take legacy's DLC5 Nilfgaardian medium armor's resistances (chest 14/6/6/14/14%, boots 6/4/4/6/6%, gloves 5/3/3/5/5%, trousers 7/4/4/7/7%), their armor kept (porter's call, confirmed by the owner, 2026-10-18).
- Scarlet Crest's set totals are spread over the pieces as legacy's Griffin set spreads its own: armor 220/83/79/83, slashing 19/7/6/8%, piercing 15/6/5/6%, bludgeoning 21/8/6/9% (chest, boots, gauntlets, trousers) (porter's call, confirmed by the owner, 2026-10-18).
- NG+: resistances keep Ghost Mode's value (legacy kept its armor resistances in NG+), other numbers follow the NG+ rule; Dol Blathanna's new chest intensity takes the gloves' NG+ ratio (0.20) (porter's call, confirmed by the owner, 2026-10-18).

**Slices:**

1. **5.x's new armor.** Verified 2026-10-18, both trees (`GMTest_arm15` in the regression; gear worn by script; real casts through `autocast` on a neutral test dummy, the power read by the damage probe and from the dummy's effects): the item stats and tags; tier 1 from lower-tier pieces lengthens a potion and not a decoction, tier 2 more; inside Geralt's Yrden a real Aard's damage and stagger, a real Igni's damage and a real Axii's confusion (classic) carry +0.5 intensity, with no extra direct damage; the bonus is 0 for Yrden's own skills and outside the trap (`gmtest_arm15_yrden`). Save impact: Netflix pieces owned before read the new stats and count (`gmtest_arm15_oldsave`).

**Later:** —

---

### Dependencies on other areas

- **Areas ARM builds on:** STAM-03 (cost functions; ARM-02, ARM-07), STAM-05 (the regen option; ARM-03), DEF-01 (the light set's dodge angle; ARM-04), DMG (pool terms for Feline, Bear, Wolven, Netflix, the crit check, `ProcessActionDamage`), SKL-07 (adrenaline), SKL-11 (Quen, Quen Discharge), SKL-14 (oils), SKL-18 (school perks, Rage Management).
- **Areas ARM shares with:** ENCH (Levity, Balance, Heft's stamina trades, ENCH-10; Glyphword 5's Quen Discharge boost, ENCH-12; Glyphword 22 removed, ENCH-18), ALCH (Golden Oriole with Viper, ALCH-05; potion duration not raising bomb damage, ALCH-14; oil items, ALCH-16), ITEM (item level), CRAFT (schematics, crafting costs), WGT (armor weight), ECON (prices), UI (character panel lines).

### Save impact

Mostly none: set counts, bonuses and costs are computed live, and items owned before read the changed tags and stats from the definitions (verified, ARM-05 and ARM-01). Exceptions: the Kaer Morhen set adds items and schematics (granted at load), and 5.x's "Starting Armor Upgrade schematic 1" is removed at load (ARM-12). Removing the mod mid-playthrough is not supported ([save compatibility](../feature-mapping.md#save-compatibility)); as facts: the Kaer Morhen pieces vanish from the save and worn ones leave their slots empty (verified, ARM-12), 5.x teaches its starting armor schematic again, and the generic set's ability stays on Geralt without a definition (no effect); whether the Kaer Morhen schematics survive a save made without the mod is not probed (not needed under that policy).

### Area decisions

All eight are decided by the owner (project owner, 2026-10-17): DA1, DA2 and DA5 to DA8 as recommended; DA3 and DA4 with the owner's own rules, written out under [ARM-15](#arm-15-5xs-new-armor).

| # | Question | Options | Recommendation | Owner's decision (2026-10-17) |
|---|---|---|---|---|
| DA1 | Griffin set | (a) legacy's redesign (cost cut after any sign, Yrden intensity and resistances), ending 5.x's free casts; (b) keep 5.x's free cast | **(a) legacy** (the owner deferred SKL's F3 to this, 2026-10-16) | (a), as recommended |
| DA2 | Wolven set: 5.x replaced it with bleeding and removed several oils per sword | (a) legacy whole: oil potency per piece, three oils at once with crit per oil (rebuilds the several-oils code); (b) legacy tier 1, and tier 2's crit per oil without several oils; (c) 5.x's bleeding set | **(a) legacy** | (a), as recommended |
| DA3 | Netflix set (5.x only) | (a) keep its bonuses, under Ghost Mode's rules: every tier counts towards its minor bonus, its potion duration on potions only (legacy's rule for `potion_duration`), its pieces with Ghost Mode's medium resistances; (b) keep it exactly as 5.x; (c) remove its bonuses | **(a)**, porter's suggestion: no legacy behaviour exists; (a) keeps 5.x's content consistent with Ghost Mode's sets | (a) with the owner's rules: every tier counts; Griffin-like armor and resistances; potions only; tier 2 becomes +0.5 sign intensity inside Yrden; per-piece changes ([ARM-15](#arm-15-5xs-new-armor)) |
| DA4 | 5.x's other new armor (Dol Blathanna, White Tiger, `w3r`) | (a) Ghost Mode's medium resistances at their level; (b) as 5.x | **(a)** (otherwise the best medium armor in the game) | (a), with per-set details: Dol Blathanna's regen becomes Igni and Aard intensity, White Tiger's extras stay, Scarlet Crest gets set values ([ARM-15](#arm-15-5xs-new-armor)) |
| DA5 | Resistances 5.x lowered on school, Wolven DLC, Manticore and Tesham Mutna gear | (a) legacy's values (legacy rewrote every one of these items); (b) 5.x's cuts scaled onto legacy's | **(a) legacy** | (a), as recommended |
| DA6 | Manticore gear toxicity: vanilla 30, legacy 25, 5.x 20 | (a) legacy's 25; (b) 5.x's 20 | **(a) legacy** | (a), as recommended |
| DA7 | Levity, Balance and Heft changing the armor class (5.x, and SKL-18's school perks) | (a) legacy: the class is the item's, from ARM-02 on; the glyphwords do nothing until ENCH gives them legacy's stamina trades (a temporary deviation); (b) keep 5.x's class change until ENCH | **(a) legacy** | (a), as recommended |
| DA8 | Bear set tier 2 and Quen | (a) legacy: no Quen rules, the refund on strong attacks, Quen Discharge plays the effects; 5.x's supercharged-Quen boost goes too; (b) keep 5.x's Quen boost | **(a) legacy** | (a), as recommended |

**Questions without a clear recommendation** (answered by the owner, 2026-10-17, with DA3 and DA4): the Netflix set stays, with its tiers at levels 21/35/41; the new pieces stay at their current levels (8, 12, 41).
