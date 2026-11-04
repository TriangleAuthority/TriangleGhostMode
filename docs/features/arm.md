# ARM: armor and armor sets

Geralt's armor: what each piece protects against, what its class costs in stamina, and what wearing a set gives. Ghost Mode rebuilt all three. Every generic piece got resistances by class (light almost none, heavy high) and armor by item level; the class now changes stamina costs (light −30% for melee actions, heavy +50% and +50% for signs) instead of regen; four pieces of one class give a generic set bonus; every witcher school set was redesigned, its minor bonus now available from the first tier; and the mod added the Kaer Morhen set and a Viper set bonus. Source: the changelist's "Armor" section ([legacy-FullChangelist.txt](../legacy-FullChangelist.txt), lines 542–612), its stamina section (lines 233–243) and three bug fixes (lines 104, 106, 144).

Armor and set bonuses are part of player power: balance them with [balance.md](balance.md) (rule B3, the archetypes) and the [gear ledger](ledger/gear.md), which lists every set and armor class in vanilla 1.32, legacy and 5.x.

**How legacy Ghost Mode implements it.** Item stats are the `_Stats` abilities in the item files (`def_item_armor.xml`, `def_item_crafting_*.xml`, `def_item_armor_relics.xml`, the expansions' and free DLCs' item files, `dlc10_wolf_armor.xml`), armor by item level in `def_item_weapons_relic_autogen.xml`. Set membership is item tags (`LynxSetMinor` on lower tiers, `SetBonusPiece`); the set framework is in `playerWitcher.ws` (`IsSetBonusActive`, `GetSetPartsEquipped`, `CheckSetType`) and `playerTypes.ws`. Set bonus values are abilities in `geralt_skills_ep2.xml`, `effects_ep2.xml` and `geralt_skills.xml`; their effects live where they act: stamina costs in `PlayerAbilityManager.ws`, attack power and crits in `damageManagerProcessor.ws`, adrenaline in `OnProcessActionPost` and `ProcessAction`, oils in `oil.ws`, Quen in `quenEntity.ws`. Tooltips: `GetSetBonusTooltipDescription`, `W3TooltipComponent.AddSetAttributes`, strings in `modGhostMode/<lang>.csv`.

**What 5.x did in this area.** Little, except to the Wolven set: its bonuses were replaced by bleeding mechanics, and the code for several oils on one sword is gone. 5.x also moved "bombs thrown without delay" to the Manticore set's first tier (as legacy did) and extended it to its new throwing knives, cut Manticore's maximum toxicity (30 → 20), lowered the rending (and the Feline set's elemental) resistances of the grandmaster school gear, the Wolven DLC gear and the Tesham Mutna set, tagged the Viper gear as a set without giving it a bonus (and hid it from set tooltips), let the Bear set's Quen boost work with the new tree's supercharged Quen, and added new armor: the Netflix set (3 tiers, potion duration and an Aard-in-Yrden bonus), Dol Blathanna, White Tiger and `w3r` armor. Generic armor, armor classes, the other set bonuses and the set framework are 1.32's.

Unit lists: [attribution.csv](attribution.csv): mapped 2026-10-17 from the changelist and sweeps of every unit naming an armor class, a set, a set tag or a set bonus, and of every armor item in the item files: 2,255 units carry an ARM feature (155 script units, 803 XML units and their 964 NG+ copies, 333 string rows: 37 strings × 9 languages); 601 of them are shared with other features (STAM-05's per-item regen values, SKL's sign and Quen functions, DMG's damage functions). Units of armor items whose only Ghost Mode change is the price, the dismantling parts or the weight are left to ECON, CRAFT and WGT ([hand-off](#hand-off-to-other-areas)). Port status: **mapped, analysed against 5.x from the code; the owner's [area decisions](#area-decisions) all made (2026-10-17); ported** ([port order](#port-order)): ARM-01 to ARM-15 ported and verified in both trees (2026-10-18); audited 2026-10-18 ([ARM audit](#arm-audit-2026-10-18)): every finding fixed, recorded or decided by the owner, the fixes verified in both trees (5.x-GM `9697aedf` and `eef6186c`, 2026-10-18); **signed off** by the owner (2026-10-18; [close-out](#audit-close-out)); since then ARM-01's slice 4, crafted armor without random bonuses (the owner's decision on the [SWD audit](swd.md#swd-audit-2026-10-19)'s F4, 2026-10-19, 5.x-GM `0e524ca1`, verified in both trees).

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
| ARM-07 | Griffin | none (the free cast is 1.32's; SKL kept it, F3) |
| ARM-08 | Bear | Quen boost (tier 2) also for the new tree's supercharged Quen |
| ARM-09 | Wolven | **Replaced:** 3: each Bleeding stack on enemies within 50 m adds +1%/piece to sword damage; 6: adrenaline raises the Bleeding stacks per enemy; oils have no charges and the several-oils code is gone |
| ARM-10 | Manticore | 3: bombs and the new throwing knives without delay (moved from Wolven 6, as legacy); gear toxicity 30 → 20 |
| ARM-11 | Viper | tagged as a set, hidden from set tooltips, no bonus |
| ARM-12 | Kaer Morhen | n/a |
| ARM-13 | Tesham Mutna | none (bonus as 1.32) |
| ARM-14 | Descriptions | new strings for the Netflix set; the Wolven text with its per-piece value |
| ARM-15 | New armor | Netflix set (dlc18: 3 tiers of 4 armor pieces and 2 swords, medium; only the top tier tagged `SetBonusPiece`): 3: potion and decoction duration +7%/piece; 6: Aard hitting enemies inside Yrden deals extra damage scaled by intensity. Dol Blathanna, White Tiger and `w3r` armor: 4 medium pieces each, vanilla-style resistances |

### Classification and proposed action

| # | Feature | Class | Proposed action |
|---|---|---|---|
| ARM-01 | Armor pieces | clean (generic), overlap (set gear) | Legacy's item stats through a generated DLC override (like STAM-08's `gen_npc_stamina.py`); legacy's values where 5.x also changed the item (DA5) |
| ARM-02 | Armor classes and stamina | clean | Port; glyphwords stop changing the class (DA7) |
| ARM-03 | Regen with the option on | clean | Port; ends STAM-05's deviation |
| ARM-04 | Generic sets | clean | Port; ends DEF-01's open check |
| ARM-05 | Framework | clean (units overlap) | Port on 5.x's functions (Netflix kept in the enums) |
| ARM-06 | Feline | clean | Port; ends SKL-07's, DEF-06's and DMG's Lynx deviations |
| ARM-07 | Griffin | clean | Port legacy's redesign (DA1); ends SKL's F3 free casts |
| ARM-08 | Bear | overlap | Legacy (DA8); ends SKL-07's and SKL-11's Bear deviations, Quen Discharge's visuals |
| ARM-09 | Wolven | overlap, needs-decision | Legacy (DA2), re-implementing three oils on one sword; ends SKL-14's and DMG's Wolf deviations |
| ARM-10 | Manticore | overlap (partly in-5.x) | Legacy's crit per piece; the no-delay part is 5.x's already; legacy's toxicity (DA6) |
| ARM-11 | Viper | overlap | Legacy's bonus; ends DMG's Golden Oriole deviation with ALCH |
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
| Depends on | DMG (armor and resistance formula, signed off), ITEM (item level: `GenerateItemLevel`, `GetItemLevel`), WGT, ECON, CRAFT (the same item entries) |
| Skill trees | n/a |
| Port form | `gm_arm_items.xml` in the DLC's `items/` and `items_plus/`, generated by `tools/gen_arm_items.py`: 5.x's item abilities and entries given whole (`on_conflict="replace"`) with legacy's ARM changes merged in (legacy's own NG+ entries for NG+), legacy's class texts, icons and looks of armor pieces and its abilities for the quest-equipped `Autogen` pieces (audit F4), and Yoana's reward armor's heavy name, look and armor-stand look (`gm_arm_item_extensions.xml`, audit F4b); `--verify` compares the final items with legacy's (audit F10); Yoana's bounce chance in DEF-08's replaced `W3ArrowProjectile.OnProjectileCollision` |
| Port status | **signed off** (2026-10-18); **ported, verified** (2026-10-17, both trees) |
| Open checks | a real arrow bouncing off Yoana's armor; Yoana's armor's armor-stand look (not seen); Geralt's hair with Yoana's armor, and with the grandmaster Feline armor under 5.x's hair extensions (on screen, fix3); the armor by level of a generic piece owned before ARM (no such piece on the test saves) |
| Save impact | none (verified: pieces owned before ARM read the new stats, which come from the definitions; armor by level is a count of per-level abilities set when the piece is made, whose value comes from the definitions too); a crafted piece received before `DoNotEnhance` (slice 4) keeps a random bonus it rolled then (stored on the item; from the code, not tested) |
| NG+ counterpart | applied, untested: legacy's own `items_plus` values merged the same way |

**What it does:** every armor piece's protection follows its class (changelist 545–556): resistances low for light, medium for medium, high for heavy, across all five damage types (chest averages: light 4.5%, medium 10.4%, heavy 20.4%; vanilla 10%, 13%, 17.5%); armor comes from the item level (`autogen_armor_armor` 5 per level, pants and boots 2, gloves 2). Rune and glyph slots raised (light and medium pieces up to 3). Unique pieces retuned: Thief armor (`bonus_money`), Ofir armor (per-sign intensity), Oathbreaker armor, Yoana's armor (`q108`: arrows bounce, changelist 144; class changed), the relics' silver studs, gloves with herb chance. School gear stats are with each set (ARM-06 to ARM-13).

**Implementation (legacy):** about 470 item abilities and items (regular) and 580 NG+ copies attributed here; `def_item_weapons_relic_autogen.xml` (armor per level, the autogen pieces). Many pieces lost their fixed armor value for level-based armor and their `item_level_min/max` (ITEM).

**5.x:** generic armor unchanged; the school gear's rending resistance lowered (see the [table](#what-5x-changed)).

**Decisions:** DA5 (a), the owner's decision (2026-10-17): legacy's values where 5.x also changed the item. What is ARM's in an item: every stat legacy changed in a piece's abilities except `weight` (WGT), `quality` and `item_level_min/max` (ITEM); the class tags, `gm_NoSetBonuses` (ARM-04) and the enhancement slots of armor pieces; `DoNotEnhance` where legacy added it, so crafted armor gets no random bonus on top of its stats (the owner's decision on the [SWD audit](swd.md#swd-audit-2026-10-19)'s F4, 2026-10-19). The set gear's own stats (attack power, sign intensity, adrenaline gain, Manticore's toxicity of DA6, ...) come with this slice; each set's slice ports its bonus.

- **Deviation:** legacy's other display changes to item entries are not carried: the NG+ items' names (legacy shows the regular names in NG+), legacy's NG+-only glove looks (`g_01a_*` on eight crafted gloves) and the quest-equipped `Autogen` trousers' shirt variant and collapse rules; they are cosmetic and not ARM's rules (audit F4; porter's call, confirmed by the owner, 2026-10-18).
- The pieces legacy moved to armor by item level (Ofir armor, Blood and Wine's first vampire armor, Yoana's armor, the Nekker boots, the standalone starting gear) are level-scaled since [ITEM-04 and ITEM-05](item.md#item-04-items-moved-to-level-scaling) (2026-10-19), which ended the deviation kept until ITEM.
- Where legacy removed `DoNotEnhance` (42 pieces: Blood and Wine's guard and knight gear, `sq701` tournament armor, Thief and Burning Rose `B` pieces, Hearts of Stone's Ofir armor), it is removed since [ITEM-08](item.md#item-08-donotenhance-removed) (2026-10-19), so they roll legacy's random bonuses; that ended the deviation kept until ITEM.

**Slices:**

1. **Item stats** (5.x-GM `a009e6b4`). Verified 2026-10-17 in both trees (test save; scripted reads of the definitions, `GMTest_arm01` in the regression run): Feline armor (tier 1) legacy's slashing 0.08 and bludgeoning 0.07 with 5.x's weight, grandmaster Bear armor's rending 0.22 (5.x 0.32), Manticore armor's +10% potion duration (its toxicity was 5.x's +5 until slice 2), generic heavy armor's 15% against every damage type, 5 armor per item level, Thief armor's 3 slots, the Beauclair casual suit light and outside the generic sets, Yoana's armor's bounce chance 1. A generic light armor made at level 26 had 31 per-level abilities and 181 armor (script call, equipped). Save impact: on the save made before ARM, the Feline armor owned then read legacy's resistances when worn (`gmtest_arm01_oldsave`). Not in game: a real arrow on Yoana's armor.
2. **Audit fixes F2, F3, F4, F9, F10** (5.x-GM `9697aedf`; `tools/gen_arm_items.py` on master). DA5 and DA6 in full: in an ability legacy rewrote, legacy's value also where 5.x lowered one legacy had left at 1.32's (14 regular and 13 NG+ rending resistances; the first-tier Manticore armor's toxicity +10, the set +25); legacy's class texts for the ten boots and trousers it moved between light and medium, the 21 icons (each present in 5.x's texture cache), the grandmaster Feline armor's masked look (`t_02_mg__lynx_lvl5`, its mask variant dropped), and `Default armor _Stats` with legacy's new `Autogen Boots _Stats` and `Autogen Pants _Stats` on the quest-equipped `Autogen` pieces; NG+ lower tiers tagged as the regular ones (ARM-05). Yoana's reward armor's name and look followed with the owner's decision (F4b, slice 3). `gen_arm_items.py --verify` (about a minute) reads what the game reads (Ghost Mode's DLC items over 5.x's) and compares every ARM tag, slot count, display field and ability stat of 4,754 regular and 4,896 NG+ items with legacy's: 0 unexplained differences, the explained ones counted by reason (the fixed armor kept until ITEM, legacy's NG+-only display changes, variants legacy changed without a new look, the NG+ tag rule). Verified 2026-10-18 in both trees (test save; `GMTest_arm_audit` and `GMTest_arm01` in the regression run, scripted reads of the definitions): the grandmaster Griffin boots' rending 0.06, the Manticore set's toxicity 25, `Boots 02`'s medium and `Pants 03`'s light class text, `Heavy boots 03`'s icon, the Autogen pieces' abilities, the Feline armor's template. Not seen in game: the icons and the masked Feline look (read from the definitions); NG+ (not read by a regular game; checked by `--verify`).
3. **Yoana's reward armor as legacy** (audit F4b, the owner's decision, 2026-10-18; 5.x-GM `eef6186c`; `tools/gen_arm_items.py` on master). `q108 Medium armor 10`, which legacy made heavy, takes legacy's name (`item_name_heavy_armor_03`, "Nilfgaardian guardsman armor"), the heavy class text, look (`t_01_mg__common_heavy_lvl3`, gloves variant `t_01a_mg__common_heavy_lvl3`), icon (`common_heavy_lvl3_01`) and armor-stand look (legacy's `_armor_stand_variants_extension.xml` entry given whole, `on_conflict="replace"`, in the generated `gm_arm_item_extensions.xml`), regular and NG+; its arrow bounce stays. `--verify`: 0 unexplained differences, no F4b difference left. Verified 2026-10-18 in both trees (test save; `GMTest_arm_audit` in the regression run, scripted reads of the definitions: the name key and its text, the class text, template, icon and heavy tag; the bounce chance in `GMTest_arm01`); on screen (classic tree, level 30, worn by script): Geralt wears the heavy guardsman armor in the world and in the inventory, the heavy icon in the chest slot. Not seen: the tooltip's name (read by script), the armor-stand look (no armor stand on the test save; `on_conflict` on an `item_extension` is unverified), NG+.
4. **No random bonus on crafted armor** (the owner's decision on the [SWD audit](swd.md#swd-audit-2026-10-19)'s F4, 2026-10-19; 5.x-GM `0e524ca1`; `tools/gen_arm_items.py` and, for the starting armor, `tools/gen_arm_km.py` on master): legacy's `DoNotEnhance` on every armor piece legacy added it to, regular and NG+. Since [ITEM-06 and ITEM-09](item.md#item-06-random-bonus-rules) (2026-10-20) quality-1 pieces and relic chests roll a bonus too, so the tag keeps ITEM-06's bonuses off every tagged piece, quality 1 included (15 of them are quality 1 now, among them the crafted light, medium and heavy armor `01_crafted`, the starting armor and the Kontusz; whole-port audit A4-2). `gen_arm_items.py --verify` compares the tag with legacy's: 0 unexplained (legacy's removals counted, the deviation above). Verified 2026-10-19 in both trees (test save; `GMTest_arm_dne` in the regression run, by script: `AddAnItem` runs 5.x's item-received code with its random roll, as crafting and buying do): the tag on six crafted pieces; 8 new copies each of the crafted heavy armor 01 (quality 3), medium armor 01 (quality 2) and boots 01 (quality 3) got no random (`MA_*`) ability, while 8 copies of the untagged Burning Rose armor (quality 3) got one each (the qualities as they were then: ITEM-09 has since made the crafted heavy armor 01 quality 1). Not in game: a piece crafted at an armorer or bought, NG+ (`--verify`).

**Fix round fix3 (2026-11-02, sweeps C and D; the owner's decisions):**
- **NG+ DLC armor at full armor** (sweep C gap 2): legacy deleted `NGP DLC Compatibility Chest Armor Mod` (−25 armor) and `NGP DLC Compatibility Armor Mod` (−10), which 5.x's `NewGamePlusAdjustDLCItem` still adds to owned NG+ Temerian, Nilfgaardian, Wolven and Skellige pieces; both are given empty in `items_plus/gm_arm_items.xml` (`gen_arm_items.py` `EMPTIED`, as SWD-04's Wolven swords). Offline check only: `gen_arm_items.py --verify` checks both empty (it fails on 5.x's entries).
- **Yoana's armor keeps Geralt's default hair** (sweep C gap 5a): `q108 Medium armor 10` taken out of the inquisitor and bowl hair variants of `Preview Hair`, `Half With Tail Hairstyle`, `Long Loose Hairstyle` and Blood and Wine's `Fancy Bowl` (5.x's entries given whole without that line, regular and NG+; `gen_arm_items.py` `HAIR_ARMOR`). `--verify` compares the variants with legacy's (it fails on 5.x's). In game (`GMTest_arm01_hair`, regression): the four still read as hair items with their tags, a guard of the whole entries (it passes on 5.x's entries too); the variant lists cannot be read by script. **verified on the area build** (2026-11-02, gm/fix3 `51bce9eb`, both trees).
- **Deviation:** the grandmaster Feline armor's hair extensions (Blood and Wine's `bob_item_extensions.xml`, the hood hair `c_08_mg__witcher_lx` and the mask variants of `Lynx Armor 4`) stay 5.x's, though legacy removed them with the mask look the port carries; an empty `item_extension` replace is untested, so the owner waits for an on-screen look (the owner, 2026-11-02; temporary, until that look).

Open checks added: Geralt's hair with Yoana's armor on screen; the grandmaster Feline armor's hair with 5.x's extensions on screen (decides the deviation above); NG+ (both offline only).


### ARM-02 Armor classes and stamina costs

| | |
|---|---|
| Kind | system |
| Pillars | P4, P2 |
| 5.x class | clean |
| Flags | balance |
| Depends on | STAM-03 (cost functions, signed off), ENCH (Levity, Balance, Heft's new effects), SKL-18 (school perks count pieces by class) |
| Skill trees | n/a (the school perks that read the class are SKL-18's, both trees) |
| Port form | wrappers of `GetStaminaActionCost` and `GetSkillStaminaUseCost`; `@replaceMethod CInventoryComponent.GetArmorType` without the glyphword class change; `GMCountArmorPieces`, `GMGetArmorTypeByName` (`armor/armorClass.ws`); the tutorial string 2110992429 (vanilla key `6d1ad461`) in 9 languages |
| Port status | **signed off** (2026-10-18); **ported, verified** (2026-10-17, both trees) |
| Open checks | the class tutorial seen in game (its text is checked by id only); a real dodge, roll and attack in each class (only a real Aard cast was measured) |
| Save impact | none |
| NG+ counterpart | none (scripts) |

**What it does** (changelist 233–235, 549–556): melee and agility actions (attacks, dodges, rolls, sprint, jump, parry, counter; not usable items) cost −7.5% per light piece, +12.5% per heavy piece, −12.5% per missing piece (4 light −30%, 4 heavy +50%, naked −50%); signs cost +12.5% per heavy piece. A piece's class comes from the item only: Levity, Balance and Heft no longer change it (their new effects are ENCH's). Applies to Geralt only.

**Implementation (legacy):** `CalcStaminaArmorPenalty`, `CalcSignCastingArmorPenalty` (added), applied in `GetStaminaActionCost` and `GetSkillStaminaUseCost` next to STAM-03's terms; `CountArmorPieces`; `GetArmorType(item, ignoreGlyphwords)` with the glyphword lines commented out; `GetArmorTypeByName` for tooltips; the class tutorial text (string 2110992429).

**5.x:** no cost by class; glyphwords change the class as in 1.32, which today also changes SKL-18's school perk counts.

**Decisions:** port as legacy; DA7 (a), the owner's decision (2026-10-17): the class is the item's. SKL-18's school perks count pieces through `GetArmorType`, so they no longer follow the glyphwords either.

- Levity, Balance and Heft no longer change the armor class (DA7); their legacy stamina trades came with [ENCH-10](ench.md#ench-10-levity-balance-and-heft-glyphwords-2-3-4) (2026-10-19).

**Slices:**

1. **Class costs** (5.x-GM `6f46fc7e`). Verified 2026-10-17 in both trees (test save, gear equipped by script): naked −50%, four light pieces −30% (a dodge 3.5 against 2.5 naked), four heavy pieces +50% (7.5) and Aard +50% (60 against 40), usable items unchanged, Heft's ability (`Glyphword 4 _Stats`) added to Geralt leaves light armor light, legacy's tutorial text under its id (`GMTest_arm02`, scripted cost reads, in the regression run); a real Aard cast (scripted input through the input handler) in four heavy pieces took 60 stamina.
2. **The tooltip's class** (audit F8, 5.x-GM `9697aedf`). The wrapper of `W3TooltipComponent.GetBaseItemData` (`armor/setTooltips.ws`) clears `hasEnchantedType` for armor pieces: 5.x showed the class as changed by Levity, Balance or Heft for equipped pieces, legacy never. Verified 2026-10-18 in both trees (`GMTest_arm_audit` in the regression run: a tooltip built for the worn armor with Heft's ability on Geralt reads the flag false). Not seen in the inventory.



### ARM-03 Armor regen with the option on

| | |
|---|---|
| Kind | tuning |
| Pillars | P4 |
| 5.x class | clean |
| Flags | — |
| Depends on | STAM-05 (the option, signed off), ARM-01 (item values), ENCH (Hearts of Stone glyphword regen) |
| Skill trees | n/a |
| Port form | `@replaceMethod W3PlayerWitcher.CalculatedArmorStaminaRegenBonus` (`armor/armorRegen.ws`), under STAM-05's option wrapper; the `staminaRegen_armor_mod` values in ARM-01's generated XML |
| Port status | **signed off** (2026-10-18); **ported, verified** (2026-10-17, both trees) |
| Open checks | the regen measured in a fight with the option on (the modifier read); the item tooltip's regen line (STAM-05's tooltip row, not ported) |
| Save impact | none |
| NG+ counterpart | applied (ARM-01's NG+ items), untested |

**What it does** (changelist 243, 1233): only with "Enable stamina regen penalty for armors" on (default off): legacy's calculation (the glyphwords' regen ignored, +11/+2/+3/+4% regen per missing chest/gloves/pants/boots) and legacy's per-piece values (e.g. heavy −0.10 → −0.30).

**Implementation (legacy):** `CalculatedArmorStaminaRegenBonus`; `staminaRegen_armor_mod` in 545 item abilities (shared with STAM-05, which hides the stat while the option is off); the stat name (string 2110992263).

**5.x:** as 1.32.

**Decisions:** port as legacy; ends STAM-05's deviation ("temporary, until ARM and the glyphwords"). The glyphwords' own legacy stamina trades are ENCH's (ARM-02's deviation).

**Slices:**

1. **Armor regen with the option on** (5.x-GM `1e347748`). Verified 2026-10-17 in both trees (`GMTest_arm03` in the regression run, the option set by script for the test; gear equipped by script): naked +0.20 (0.11 + 0.02 + 0.03 + 0.04 for the missing pieces), four heavy pieces −0.50, their legacy values (chest −0.30, vanilla −0.10), unchanged with Heft's ability on Geralt; STAM-05's checks pass with the legacy values.

### ARM-04 Generic armor set bonuses

| | |
|---|---|
| Kind | system |
| Pillars | P4 |
| 5.x class | clean |
| Flags | balance |
| Depends on | ARM-02 (class counting), DEF-01 (reads the light bonus, ported), ALCH (toxicity decay) |
| Skill trees | n/a |
| Port form | `abilities/gm_armor.xml` (the three abilities, NG+ copy by `gen_ngplus.py`); `GMManageSetArmorTypeBonus`, `GMCountSetArmorPieces`, `GMGetSetArmorType`, `GMIsSetArmorType(ByName)`, `GMGetSetArmorItemDescription`; wrappers of `EquipItemInGivenSlot`, `UnequipItemFromSlot`, the load (`OnSpawned`) and `W3Effect_Toxicity.RecalcEffectValue` (`armor/genericSets.ws`); the tooltip line in `AddSetAttributes`; strings 2110992320–2110992322 in 9 languages |
| Port status | **signed off** (2026-10-18); **ported, verified** (2026-10-17, both trees) |
| Open checks | the tooltip line seen in the inventory; a real dodge at 121–150° in light armor |
| Save impact | none (the bonus is checked at every load) |
| NG+ counterpart | applied, untested |

**What it does** (changelist 561–565): four non-witcher pieces of one class (pieces tagged `gm_NoSetBonuses`, e.g. Ofir and Burning Rose variants, and witcher set pieces do not count): light +30° safe dodge angle, medium toxicity decay +0.25/s, heavy +10% to all resistances. Shown in item tooltips.

**Implementation (legacy):** `ManageSetArmorTypeBonus` grants `ArmorTypeLight/Medium/HeavySetBonusAbility`; `GetSetArmorType`, `IsSetArmorType(ByName)`, `CountSetArmorPieces`; `W3Effect_Toxicity.RecalcEffectValue`; the character panel's toxicity line; `ApplyPatchFixes` for old saves.

**5.x:** none. The port's DEF-01 already reads `ArmorTypeLightSetBonusAbility` (`defense/dodge.ws`).

**Decisions:** port as legacy. The bonus is checked at every load, where legacy granted it once on old saves (same result). The tooltip shows the generic line for armor pieces only (legacy filled the set block for any item outside a witcher set; display only).

- The character panel's toxicity decay line counts the medium set since UI-04 (2026-10-21, 5.x-GM `a31306a4`): the temporary deviation has ended.

**Slices:**

1. **Generic sets** (5.x-GM `db5b9c0a`). Verified 2026-10-17 in both trees (test save, gear equipped and taken off by script; `GMTest_arm04` in the regression run): the bonus values; three pieces give no set; the starting gear's four medium pieces give the medium set and toxicity decay 0.5 against 0.25 without; four light pieces the light set; four heavy the heavy set, gone with a piece off; the gear put back restores the medium set. With DEF-01 (`gmtest_arm04_dodge`, scripted hits from a real wolf): in four light pieces a hit at 145° is dodged and one at 155° is not; in medium armor 145° is not dodged.



### ARM-05 Set framework: minor bonus from every tier

| | |
|---|---|
| Kind | system, fix |
| Pillars | P8 |
| 5.x class | clean (units overlap: 5.x added the Netflix set to the same functions) |
| Flags | — |
| Depends on | ARM-01 (item tags) |
| Skill trees | n/a |
| Port form | enum extensions (`EItemSetType`, `EItemSetBonus`: minor tiers, Viper, Kaer Morhen); `@replaceMethod`s of `SetItemNameToType`, `IsSetBonusActive`, `GetSetPartsEquipped`, `UpdateItemSetBonuses`, `ManageActiveSetBonuses`, `CheckSetType(ByName)`, `SetBonusStatusByType`, `ItemSetTypeToItemSetBonus`, `ManageSetBonusesSoundbanks`, `W3TooltipComponent.AddSetAttributes`; `GMRecalcSetItemsEquipped` at every load (`armor/setFramework.ws`, `armor/setTooltips.ws`); item tags in `gm_arm_items.xml`, generated by `tools/gen_arm_items.py` (5.x's entries given whole with legacy's set tags merged in; the set swords' entries, with these tags, in SWD's `gm_swd_items.xml` since 2026-10-19, written by `gen_swd_items.py`) |
| Port status | **signed off** (2026-10-18); **ported, verified** (2026-10-17, both trees) |
| Open checks | the tooltip lines seen in the inventory (scripted only); the set sound banks with lower tiers (not listened to) |
| Save impact | none (verified: items owned before take their tags from the definitions; set pieces are recounted at load) |
| NG+ counterpart | applied, untested: the NG+ items get legacy's tags, and the lower tiers the regular ones' `<School>SetMinor` and `SetBonusPiece` (audit F9; 5.x tags every NG+ tier `SetBonusPiece`, legacy's NG+ entries kept the school tag); checked by `gen_arm_items.py --verify` |

**What it does** (changelist 567–569): every tier of the four school sets counts towards the minor bonus (3 pieces; lower tiers tagged `*SetMinor`); the full bonus (6) needs grandmaster pieces; the tooltip counts both and flags mixed tiers. Viper (3 pieces) and Kaer Morhen (3 of 4) join the system. Set bonus sound banks are reloaded on load (the Bear set's always, for Quen Discharge's effects: [audit F6](#arm-audit-2026-10-18)); the "Fully Armed" achievement accepts a full set of lower-tier pieces and no longer needs the school crossbow, and leaves Viper out ([audit F5](#arm-audit-2026-10-18)); "Ready to Roll" needs any full bonus.

**Implementation (legacy):** `playerWitcher.ws` (`IsSetBonusActive`, `GetSetPartsEquipped(Raw)`, `HasMixedSetsEquipped`, `RecalcSetItemsEquipped`, `UpdateItemSetBonuses`, `ManageActiveSetBonuses`, `CheckSetType(ByName)`, `LoadCurrentSetBonusSoundbank`, `CheckForFullyArmedAchievement`), `playerTypes.ws`, `W3GameParams` set tags, `IsItemSetItem`; debug commands (`addset`, `allsets`, not ported).

**5.x:** the same framework plus the Netflix set; grandmaster-only bonuses.

**Decisions:** port as legacy. The Netflix set's lower tiers count towards its minor bonus (DA3, ARM-15: `EIST_Netflix_Minor`). `GetSetBonusAbility`'s new entries come with each set's slice. Set pieces are recounted at every load, where legacy recounted once on old saves (same counts; no behaviour change). 5.x's Viper hiding in the tooltip ended with ARM-11, which gave the set its bonus. The Ready to Roll achievement as legacy (any full bonus), with 5.x's progress notice kept for the grandmaster sets. Fully Armed as legacy (`CheckForFullyArmedAchievement`, `HasAllItemsFromSet`: the four lower-tier tags, no crossbow, no Viper), with 5.x's check and progress notice on equip (`CheckForFullyArmedByTag`, `DetectTagOfASet`) given the same rules.

- **Deviation:** in NG+ the lower tiers of the school gear take the regular lower tiers' tags (`<School>SetMinor`, `SetBonusPiece`): they count towards the first bonus, not the full one. Legacy's NG+ entries kept the school tag (its NGP lower tiers counted for nothing, without `SetBonusPiece`; NG+'s regular-named lower tiers counted as grandmaster pieces); the NG+ rule makes the regular folder's non-numeric change in NG+ (audit F9; porter's call, confirmed by the owner, 2026-10-18).
- **Deviation:** the Bear set's sound bank, loaded at every load for Quen Discharge's Bear effects as legacy, is never unloaded; legacy unloaded it whenever Bear pieces changed below three, until the next load, against its own note that Quen needs it always (audit F6; porter's call, confirmed by the owner, 2026-10-18).
- **Deviation:** Fully Armed is also granted, as in 5.x, by six worn pieces of the Manticore, Tesham Mutna or Netflix sets (5.x's check on equip, `CheckForFullyArmedByTag`); legacy's check covered the four school sets and their lower tiers only (audit F5; porter's call, confirmed by the owner, 2026-10-18).

**Slices:**

1. **Framework, tags and tooltip** (5.x-GM `36b30565`). Verified 2026-10-17 in both trees (test save; scripted calls): set tags read from the definitions for regular, Hearts of Stone (Viper), Blood and Wine (grandmaster Feline, Tesham Mutna sword) and free DLC (NG+ Wolven) items, and the replaced entries keep their abilities, category and slots (`GMTest_arm05`, in the regression run); three lower-tier Feline pieces worn give tier 1 and not tier 2, a grandmaster piece added counts as mixed with 4 pieces, the load-time recount gives the same, and the gear put back clears it (`gmtest_arm05_count`, items equipped by script at level 50). Save impact: on a save made before ARM with the old build (`<save name>`, made by `gmtest_arm_mksave`), the Feline armor owned then has the new tags and three such pieces count when worn (`gmtest_arm_oldsave`). The tooltip function was compiled, not looked at in the inventory.
2. **Fully Armed and the Bear sound bank** (audit F5, F6; 5.x-GM `9697aedf`). Verified 2026-10-18 in both trees (test save at level 50, gear equipped by script; `gmtest_arm_fullyarmed`, `GMTest_arm_audit` in the regression run): six lower-tier Feline pieces of mixed tiers (armor 1, boots 2, gloves 1, trousers 3, swords 1 and 2) make a full set for `HasAllItemsFromSet('LynxSetMinor')`, six grandmaster Bear pieces without the crossbow one for `BearSet`; `DetectTagOfASet` gives a lower-tier piece's `LynxSetMinor`; the Bear bank is loaded after a load with no Bear piece worn (`SoundIsBankLoaded`). Not checked: the achievement itself (granted through the gamer profile, not readable by script), Viper's exclusion (code read), the sound heard.



### ARM-06 Feline (Cat) set

| | |
|---|---|
| Kind | system, tuning |
| Pillars | P8 |
| 5.x class | clean |
| Flags | balance |
| Depends on | ARM-05, DMG-03/04 (attack power, the pool; signed off), SKL-07 (adrenaline gain, signed off), DEF-06 (counter keeps the chain) |
| Skill trees | n/a |
| Port form | `armor/felineSet.ws`: `W3Effect_LynxSetBonus` reworked (fields and methods added, `OnEffectAdded`, `OnEffectRemoved`, `OnResumed` replaced, `OnUpdate` overridden in a scope block), a wrapper of `W3PlayerWitcher.OnProcessActionPost` (the chain, the crit's adrenaline), `GMLynxSetAttackPower` in DMG-03's `GetAttackersPowerMod`; 5.x's Feline terms removed from `damage/pool.ws`; the counter in DEF-06's `PerformCounterCheck` (`defense/counter.ws`); the HUD counter (`mutations/hudCounters.ws`); `LynxSetBonusEffect`, `setBonusAbilityLynx_2` given whole in `gm_armor_sets.xml`; strings 2110992106, 2110992109 |
| Port status | **signed off** (2026-10-18); **ported, verified** (2026-10-17, both trees) |
| Open checks | real attacks and a real counter in a fight (scripted hits; the counter's line read); the sword effect seen (the HUD counter seen, 2026-10-18) |
| Save impact | none (the effect's chain is not saved; a running effect from an old save starts at 0) |
| NG+ counterpart | applied, untested |

**What it does** (changelist 578–581, 600): tier 1: each fast hit in a chain adds +2.5% attack power per piece (+15% per hit at 6), up to +60%; a strong hit ends the chain at double the bonus; the chain breaks when hits stop (a counter keeps it) and at combat end. Tier 2: sword crits double the adrenaline gained. Gear: attack power up to +30%, crit chance; tiers at levels 17/23/29/34 (vanilla 19/25/31/36), grandmaster 40.

**5.x:** 1.32's bonus (fast attacks +10%/piece after a strong attack; rear attacks +50% and a stun for 1 adrenaline); the port keeps them as DMG pool terms until ARM.

**Decisions:** port as legacy; ends DMG-04's Lynx term deviation, SKL-07's Lynx adrenaline deviation and DEF-06's Lynx deviation. The crit's double adrenaline adds the hit's gain once more (divided by Adrenaline Rush's multiplier, which the gain passes through again), the same as legacy's doubling before that multiplier; legacy's Bear School term in between counts heavy pieces, which a full Feline set does not have.

- The character panel's fast and strong attack power include the Feline chain since UI-01 (2026-10-21, 5.x-GM `f768e9b1`): the temporary deviation has ended.

**Slices:**

1. **Feline set** (5.x-GM `84c5ceb5`). Verified 2026-10-17 in both trees (test save at level 50, gear equipped by script, a neutral test dummy; `gmtest_arm06`, `gmtest_arm06_decay`; scripted sword hits through the damage manager, attack power read by the damage probe): three lower-tier pieces give tier 1; fast hits' attack power 1.18, 1.255, 1.33 (+7.5% per hit), a strong hit after three fast ones 1.63 (double the chain's 22.5%), the next fast hit 1.18 (chain ended); with six grandmaster pieces four fast hits reached the 60% cap, the chain broke 3 s after the last hit, and a sword crit gave 0.2 adrenaline against 0.1. In the regression run (`GMTest_arm06`): the values, 5.x's rear-attack values gone, legacy's two texts.
2. **The HUD counter** (audit F7, 5.x-GM `9697aedf`): `@replaceMethod CR4HudModuleBuffs.OnTick` (`mutations/hudCounters.ws`) sends the chain's percentage each frame, as legacy; 5.x's sent 1/1 for an effect without a duration. Verified 2026-10-18 in both trees on screen (screenshots of the HUD; chain built by scripted hits on a neutral test dummy at level 50, `gmtest_arm06`): before the fix the Feline buff read "1%" with the chain at 60%, after it "60%".


### ARM-07 Griffin (Gryphon) set

| | |
|---|---|
| Kind | system, tuning |
| Pillars | P2, P3 |
| 5.x class | clean |
| Flags | balance |
| Depends on | ARM-05, STAM-03 (costs), SKL-10 (Yrden, signed off), SKL-18 (Rage Management's free-cast branch) |
| Skill trees | both (signs; the classic and the new tree cast the same signs) |
| Port form | `armor/gryphonSet.ws`: wrappers of `W3PlayerWitcher.OnSignCastPerformed` (the buff), `OnSpawned` (removed at load), `GetStaminaActionCost` and `GetSkillStaminaUseCost` (the cut); `@replaceMethod`s of `W3SignEntity.ManageGryphonSetBonusBuff` (emptied) and `W3SignOwnerPlayer.ChangeAspect` (5.x's block on alternate casts removed); 5.x's free cast removed from the replaced `ManagePlayerStamina`, `HasStaminaToUseSkill` (`skills/rageManagement.ws`) and the sign's `OnThrowing` (`skills/signSlots.ws`); the damage reduction removed from `defense/dodge.ws`; `GryphonSetBonusEffect` and `GryphonSetBonusYrdenEffect` given whole in `abilities/gm_armor_sets.xml`; the descriptions in `armor/setDescriptions.ws` (`@replaceMethod GetSetBonusTooltipDescription`, ARM-14), strings 2110992107 and 2110992108 (vanilla keys) in 9 languages |
| Port status | **signed off** (2026-10-18); **ported, verified** (2026-10-17, both trees) |
| Open checks | a real dodge or attack during the buff (measured by script); the buff icon and the set texts seen in game (texts read by script) |
| Save impact | none (the buff is removed at load) |
| NG+ counterpart | applied, untested (`abilities_plus/gm_armor_sets.xml`, same values) |

**What it does** (changelist 576–577, 598–599): tier 1: any sign cast starts a 2.5 s buff (not refreshed while it runs) during which sign, melee and agility stamina costs are 5% lower per piece (−30% at 6). Tier 2: Yrden traps +40%; inside a normal Yrden, sign intensity +50% and +15% to all resistances; no regen bonus. Gear: sign intensity (crit removed); tiers 11/18/26/34.

**5.x:** 1.32's free cast (after a sign paid with stamina, the next one within 3 s is free; a free alternate cast below full stamina), kept by SKL's audit F3 as a temporary deviation; tier 2's −20% damage taken still in the port's `ReduceDamage`.

**Decisions:** DA1 (legacy's redesign, as the owner deferred it to ARM, 2026-10-16). Ends SKL-07's F3 deviation and SKL-18's open check on Rage Management with free casts; 5.x's `Glyphword 22 Bonus` free cast stays with ENCH. As in legacy's code, the cast that starts the buff is itself discounted: the sign calls `OnSignCastPerformed` from its throw, before it pays (legacy and 5.x alike); the description's "subsequent actions" is legacy's text. The Netflix set's tier 2 (DA3) reads enemies inside Geralt's Yrden, the Griffin set's tier 2 Geralt inside it; both cannot be worn at once (six pieces each), so they do not stack.

**Slices:**

1. **Griffin set** (5.x-GM `02ef6512`). Verified 2026-10-17 in both trees (test save at level 50, gear equipped by script): three lower-tier pieces give tier 1 only; a sign starts the buff (2.5 s, not refreshed by a second cast); with it Aard costs 34 against 40 and a dodge 4.25 against 5 (`gmtest_arm07`, scripted); six grandmaster pieces give tier 2, and inside Yrden +0.15 resistance and +0.5 intensity (`gmtest_arm07_b/_c`, the effect added by script). Real casts (`autocast`): a real Aard took 34 stamina and started the buff (both trees); a real Igni during the buff took 34 (classic); a real Yrden at tier 2 gave the inside-Yrden buff, slashing resistance 0.35 → 0.50 and intensity +0.5 (both trees); a held Igni at 50% stamina with the buff on started Firestream (5.x refused it; classic, in combat with a test dummy). In the regression run (`GMTest_arm07`): the values, no free cast (the buff and no stamina: Aard cannot be cast), legacy's two texts.


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

**5.x:** 1.32's, and the tier 2 Quen boost also applies to the new tree's supercharged Quen. The port keeps 5.x's tier 2 Quen boost until ARM (SKL-11, "legacy: Glyphword 5").

**Decisions:** DA8 (legacy). Ends SKL-07's Bear adrenaline deviation, SKL-11's Bear deviation and its deferred visuals (F19), DMG-03's Bear term. Quen Discharge's effects play in both trees (legacy keys them on the discharge share, which the port computes for either tree's skill).

- The character panel's attack power includes the Bear set's term (melee and crossbow) since UI-01 (2026-10-21, 5.x-GM `f768e9b1`): the temporary deviation has ended.

**Slices:**

1. **Bear set** (5.x-GM `b2756b98`). Verified 2026-10-17 in both trees (test save at level 50, gear equipped by script, a hostile test dummy; `gmtest_arm08`): three lower-tier pieces give tier 1; a scripted hit taken at 1 adrenaline left 1.076 (the loss less 0.105); a scripted sword hit's attack power 1.41 at 2.5 adrenaline against 1.00 at 0 (the set's +0.21 and the existing +0.1 per point); six grandmaster pieces: a scripted strong attack gave back 5.01 of its 15 stamina, a fast attack nothing. Real casts (`autocast`): an alternate Quen with Quen Discharge played the Bear effect on the sign; with six grandmaster pieces its discharge share stayed unboosted (classic 0.05, new tree 0.0833 at level 1; 5.x tripled it). In the regression run (`GMTest_arm08`): the values, 5.x's Quen values gone, legacy's two texts.


### ARM-09 Wolven set

| | |
|---|---|
| Kind | system, tuning |
| Pillars | P8 |
| 5.x class | overlap, needs-decision |
| Flags | balance, needs-decision |
| Depends on | ARM-05, SKL-14 (oils, signed off: one oil per sword, legacy's decay), ALCH (oil items) |
| Skill trees | both (Fixative's and Hunter Instinct's slots read the same oils) |
| Port form | `armor/wolfSet.ws`: `GMWolfOilMult` (tier 1) in SKL-14's `W3Effect_Oil.GMBonus` (`skills/oils.ws`); `GMOilWolfCritBonus` (tier 2) in SKL-14's replaced `GetCriticalHitChance` and `CR4Player.GetCriticalHitDamageBonus`; three oils at once in SKL-14's replaced `ApplyOil` (`GMMaxOilsPerSword`, 5.x's `RemoveOldestOilFromItem`); `@replaceMethod W3PlayerWitcher.RemoveExtraOilsFromItem` (legacy's body: the newest oil stays), called from the replaced `UpdateItemSetBonuses` (`armor/setFramework.ws`); 5.x's bleeding terms removed: the pool term (`damage/pool.ws`) and the wound stacks in `W3EffectManager.InternalAddEffect`, turned off by a wrapper that sets a flag read in the replaced `IsSetBonusActive` (instead of replacing that 260-line function); `@replaceMethod GetSetBonusAbility` (`EISB_Wolf_2`); `SetBonusAbilityWolf_1/2` given whole in `gm_armor_sets.xml`; strings 2110992091, 2110992326 |
| Port status | **signed off** (2026-10-18); **ported, verified** (2026-10-17, both trees) |
| Open checks | a real fight with three oils (scripted hits and reads); the oil tooltip, the HUD's oil icons and the set texts seen in game (texts read by script) |
| Save impact | none (verified: three oils on a sword survive a save and load with tier 2) |
| NG+ counterpart | applied, untested (`abilities_plus/gm_armor_sets.xml`, same values) |

**What it does** (changelist 585–589, 603–604): tier 1: every oil effect +16.7% per piece (+100% at 6), with SKL-14's decay. Tier 2: three different oils on one sword at once, each +5% crit chance and +10% crit damage. Gear: hybrid (adrenaline gain, attack power and intensity up to +30%); tiers 21/24/28/34.

**5.x:** bleeding design: tier 1, each Bleeding stack on enemies within 50 m adds +1% sword damage per piece; tier 2, adrenaline raises the Bleeding stacks per enemy. Oils have no charges, and the several-oils code is gone.

**Decisions:** DA2. Ends SKL-14's Wolf deviation and DMG-04's Wolven pool term. Tier 1 boosts the oil's own bonuses (attack power, resistance reduction, crit chance and damage against its monster type), not Poisoned Blades or Protective Coating, as legacy. Tier 2's crit chance counts for melee attacks with the held sword, its crit damage for the attacking sword, both whatever the enemy and wearing off with each oil, as legacy. Only Hanged Man's Venom and Beast Oil fit a steel sword (legacy and 5.x alike), so three oils fit only a silver sword. 5.x also calls `RemoveExtraOilsFromItem` when Fixative is taken off, where its body removed every oil; with legacy's body the sword's newest oil stays (legacy did not call it there; with one oil per sword the result is legacy's).

- The oil item tooltip shows the Wolven tier 1 boost since UI-06 (legacy's `AddOilStats`, 2026-10-20, 5.x-GM `6ca81e09`): the temporary deviation has ended.

**Slices:**

1. **Wolven set** (5.x-GM `f9bfe598`). Verified 2026-10-17 in both trees (test save at level 50, gear equipped and oils applied by script through `ApplyOil`, a neutral human test dummy; `gmtest_arm09`, `gmtest_arm09_b` after `gmtest_draw(true)`; scripted sword hits through the damage manager, attack power read by the damage probe): Hanged Man's Venom's attack power against humans 0.10 without the set, 0.1501 with three lower-tier pieces and 0.2002 with six grandmaster pieces, the same in a hit's attack power; without tier 2 Beast Oil replaced it; with six grandmaster pieces three oils on the silver sword, a fourth replaced the oldest; crit damage +0.30 with three fresh oils and +0.225 at half charges, a light attack's crit chance +0.15 with the silver sword drawn; a second bleed on the dummy at 3 adrenaline added no wound stack; a piece taken off ended tier 2 and left the newest oil. Save impact: six pieces and three oils saved into a new slot (`<save name>`, by `gmtest_arm09_mksave`) and loaded: tier 2 and the three oils were there (`gmtest_arm09_oldsave`). In the regression run (`GMTest_arm09`): the values, nothing without the set, legacy's two texts.

### ARM-10 Manticore set

| | |
|---|---|
| Kind | tuning |
| Pillars | P8 |
| 5.x class | overlap (no-delay throw: in-5.x) |
| Flags | balance |
| Depends on | ARM-05, SKL-15 (bombs, signed off), DMG-03 (crit check), ALCH (potion duration, toxicity) |
| Skill trees | n/a |
| Port form | `armor/manticoreSet.ws`: `GMManticoreBombBonus`, `GMManticoreBombCritChance`, a wrapper of `W3DamageManagerProcessor.ProcessCriticalHitCheck` that rolls the set's bombs' crit chance (5.x's roll has no per-piece term; as MUT-03's Magic Sensibilities wrapper); the crit damage term in DMG's `GetAttackersPowerMod` (`damage/formula.ws`); `setBonusAbilityRedWolf_1` (new: 5.x has none) in `gm_armor_sets.xml`; `GetSetBonusAbility`'s `EISB_RedWolf_1`; string 2110992090; gear in ARM-01's XML |
| Port status | **signed off** (2026-10-18); **ported, verified** (2026-10-17, both trees) |
| Open checks | a bomb crit seen in a real fight without the debug fact (the chance is read by script) |
| Save impact | none |
| NG+ counterpart | applied, untested (`abilities_plus/gm_armor_sets.xml`, same values) |

**What it does** (changelist 592–594, 605): tier 1: bombs thrown without delay and able to crit, +5% bomb crit chance and +10% bomb crit damage per piece. Tier 2: +1 charge per alchemy item (unchanged). Gear: +25 maximum toxicity, +25% potion duration (not in the changelist).

**5.x:** no delay already on tier 1 (and for throwing knives); toxicity +20.

**Decisions:** legacy's crit per piece; DA6 for toxicity (ARM-01). Legacy's NG+ file also rewrote `NGP Red Wolf Pants 2 _Stats` (armor 145, resistances 7/4/4/7/7%, +5 toxicity, +5% potion duration; 5.x: armor 151, 8/0/0/10/30%, +10% attack and sign power), an ability no item of 1.32, legacy or 5.x names in either folder (the only second-tier trousers are `Red Wolf Pants 2`, with `Red Wolf Pants 2 _Stats`, ARM-01's), so it most likely has no effect in play; it is carried anyway, with legacy's stats and WGT-03's weight (`gen_arm_items.py`'s `UNLISTED`; WGT's hand-off, closed by the whole-port audit's C3-1, 2026-11-03). The gear's potion duration no longer raises bomb damage (5.x's rule, removed with ALCH's DL7, [ALCH-14](alch.md#alch-14-bombs), 2026-10-20). The set's bombs roll Geralt's crit chance plus the set's; since ALCH-14 that crit chance includes legacy's blindness bonus (Samum +50/75/100%, the larger of it and confusion's) and 5.x's certain crit against a level 3 Samum's blindness is gone. Ends DMG's Red Wolf term.

**Slices:**

1. **Manticore set** (5.x-GM `b5babe69`). Verified 2026-10-17 in both trees (test save at level 50, gear equipped by script, a neutral human test dummy; `gmtest_arm10`, `_b`, `_c`): three pieces give tier 1 and a bomb's crit chance +0.15 (0.20 against 0.05), four pieces +0.20; real throws of Dancing Star (scripted input, `gmtest_skl06_throw`) with every hit made a crit (`debug_fact_critical_boy`): the impact's attack power 1.55 with three pieces and 1.65 with four (+0.10 for the fourth piece), read by the damage probe. In the regression run (`GMTest_arm10`): the values, nothing without the set, legacy's text.

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

**Decisions:** port as legacy; ends DMG-05's Golden Oriole deviation together with ALCH. 5.x's Golden Oriole absorption (level 3) is gone since ALCH-05 (2026-10-20); the set heals from the raw poison damage, before resistances, as legacy.

**Slices:**

1. **Viper set** (5.x-GM `26b79a3a`). Verified 2026-10-17 in both trees (test save at level 50, gear equipped by script; `gmtest_arm11`, scripted 100 poison damage hits of Geralt on himself at half Vitality): without the set the hit took 50.25 Vitality; with three pieces it gave 30, with four 40. In the regression run (`GMTest_arm11`): the value, nothing without the set, legacy's text.

### ARM-12 Kaer Morhen set

| | |
|---|---|
| Kind | content, system |
| Pillars | P8 |
| 5.x class | clean (new content) |
| Flags | balance |
| Depends on | ARM-05, CRAFT (schematics, crafting costs), STAM-04 (regen) |
| Skill trees | n/a |
| Port form | `items/gm_arm_kaer_morhen.xml` and its `items_plus` twin, generated by `tools/gen_arm_km.py` (legacy's items, abilities and schematics; the starting items given whole with legacy's name keys); `armor/kaerMorhenSet.ws`: `W3GMEffect_KaerMorhenSetBonus` (`EET_GMKaerMorhenSetBonus`, ability `GMKaerMorhenSetBonusEffect` in `gm_effects.xml`), the schematics granted once at load (fact `gm_km_schematics_added`), wrappers of `OnSpawned`, `OnCombatStart`, `OnCombatFinished` and `NewGamePlusInitialize` (NG+ items through 5.x's `NewGamePlusReplaceItem`), the set's effect from the replaced `ManageActiveSetBonuses`; a wrapper of `W3PlayerWitcher.AddCraftingSchematic` that never teaches 5.x's "Starting Armor Upgrade schematic 1", removed from saves at load (`GMRemoveStartingArmorUpgradeSchematic`); strings 2110992360–2110992380 |
| Port status | **signed off** (2026-10-18); **ported, verified** (2026-10-17, both trees; the schematic removal 2026-10-18); **NG+ base abilities fixed 2026-11-02, verified on the area build** (slice 3: the NG+ pieces lacked their 16 `Base Kaer Morhen … _Stats` abilities)
| Open checks | crafting a piece at an armorer and wearing the set in a real fight (equipped by script, enemies frozen dummies); the regen itself measured (the attribute read); NG+ |
| Save impact | the schematics are granted at load (as legacy), and 5.x's "Starting Armor Upgrade schematic 1" removed (verified 2026-10-18; Starting Armor 1 already made stays); a save keeps the pieces (verified). Removing the mod mid-playthrough is not supported ([save compatibility](../feature-mapping.md#save-compatibility)); as facts: the Kaer Morhen pieces vanish from the save, worn ones leaving their slots empty (verified 2026-10-17), 5.x teaches its schematic again at the next load, and whether the save keeps the Kaer Morhen schematics is not probed (audit F11, closed) |
| NG+ counterpart | NG+ items (`NGP Kaer Morhen *`) replace the regular ones at the start of New Game+, as legacy; untested |

**What it does** (changelist 572–575): a 4-piece medium set from the start: the starting armor becomes "Worn Kaer Morhen" armor, upgraded to the set's tiers at levels 2, 9, 19 and 27 (schematics known from the start); tier 1 (3 pieces): +1 stamina regen per second per additional enemy in combat (max +5). No swords.

**Implementation (legacy):** 16 items and their abilities, 15 schematics plus the starting armor upgrade, `KaerMorhenSetBonusEffect`, `W3Effect_KaerMorhenSetBonus` (recounted every second), `OnCombatStart`/`OnCombatFinished`, `OnSpawned` (schematics, fact `ModSignsKMSetSchematicsAdded`), NG+ functions, 21 strings (names and the bonus).

**Decisions:** port as legacy. Appearance: legacy reuses the Viper templates and a generic icon. The effect, its ability and the fact carry Ghost Mode's prefix (legacy: `KaerMorhenSetBonusEffect`, `ModSignsKMSetSchematicsAdded`); the effect is removed at every load and at combat end and added at combat start or when the set is completed in combat, as legacy.

- **Deviation:** the first armor schematic is a new "Kaer Morhen Armor schematic" (Starting Armor to Kaer Morhen armor), known from the start like the others, where legacy turned 5.x's "Starting Armor Upgrade schematic 1" into the Kaer Morhen schematic: a DLC cannot override a schematic (the crafting manager would read both). 5.x's schematic is never taught (5.x teaches it at every spawn; any other source goes through the same function) and is removed from saves at load, so the starting armor upgrades only to Kaer Morhen armor, as legacy (the removal: the owner's decision, 2026-10-17; the new schematic's name: porter's call, confirmed by the owner, 2026-10-18).

**Slices:**

1. **Kaer Morhen set** (5.x-GM `58606a30`). Verified 2026-10-17 in both trees (test save; `GMTest_arm12` in the regression run, `gmtest_arm12`, `_b` at level 30 with three hostile test dummies; gear equipped by script): the 16 pieces exist with the set tag, the medium class and legacy's stats; the first armor schematic makes Kaer Morhen armor from the starting armor, the last gloves schematic makes the mastercrafted gauntlets from the superior ones; Geralt knows the 16 schematics after loading the test save; the starting armor reads "Worn Kaer Morhen armor"; three pieces of mixed tiers give the set; in combat with three enemies the effect added two regen abilities (staminaRegen +2), and taking the gear off ended it. Save impact: four pieces worn and a spare saved into a new slot (`<save name>`, `gmtest_arm12_mksave`) loaded with the set intact (`gmtest_arm12_oldsave`); the same save loaded with the mod disabled: the save loads, the Kaer Morhen pieces are gone and the armor slots empty, the starting gear in the bag.
2. **5.x's first starting armor upgrade removed** (5.x-GM `4794908d`). Verified 2026-10-18 in both trees (`GMTest_arm15` in the regression run): after loading the test save (made with 5.x, which teaches the schematic at every spawn) Geralt does not know "Starting Armor Upgrade schematic 1" and knows "Kaer Morhen Armor schematic"; teaching it by script is refused; a save made with the build before (`<save name>`) loads without it (`gmtest_arm15_oldsave`).
3. **New Game+ base abilities** (fixed 2026-11-02; gm/arm12 `bd308f27`, tested as build `f94390e1`, the same tree; tools: master-arm12). The NG+ pieces (`NGP Kaer Morhen *`, which replace the regular ones at the start of New Game+) name 16 `Base Kaer Morhen … _Stats` abilities (the regular tiers' armor, resistances, weight and quality) that legacy defines only in its `items_plus` files; `gen_arm_km.py` copied only the abilities named `Kaer Morhen …`, so in New Game+ the set had no base stats. It now copies them too, whole, as legacy; the regular folder had no such gap. Checked offline: `gen_arm_km.py --verify` (every legacy Kaer Morhen ability present in each folder, every ability the file's items name defined) and `dlc_conflicts.py`'s new guard (no DLC item names an ability nobody defines). In game, only that a regular game does not read them: `gmtest_arm12_ngplus()` (scripted reads of the 16 abilities' stats through the definitions manager) reads 0 of 16 on the build before the fix and on the fixed build alike, and `NGP Kaer Morhen Armor` is unknown (category `None`), so the check is not in the regression; it is for an NG+ game, which the test save cannot start. Regression both trees on the fixed build (`regress.py --trees both`): 1,300 and 156 passed in each tree, 0 failed (+0 checks).

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

1. **Tesham Mutna set** (5.x-GM `0be19cda`). Verified 2026-10-17 in both trees (test save at level 50, gear equipped by script, a neutral human test dummy; `gmtest_arm13`, scripted sword hits at half Vitality): a hit healed nothing without the set, 1.5% of maximum Vitality with three pieces, 2% with four; a killing hit healed 2% once and nothing followed a second later (`gmtest_arm13_kill_a/b`, classic). In the regression run (`GMTest_arm13`): the value, legacy's text.

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

**Decisions:** port with each feature's slice, as MUT-14. Done: Feline (ARM-06), Griffin (ARM-07), Bear (ARM-08), Wolven (ARM-09), Manticore (ARM-10), Viper (ARM-11), Kaer Morhen (ARM-12), Tesham Mutna (ARM-13); the generic sets (ARM-04), the class tutorial (ARM-02), the stash fix and lower-tier counts (ARM-05). The Netflix set's texts came with ARM-15. The oil tooltip's Wolven boost waits for UI (ARM-09's deviation). Manticore's tier 2 keeps 5.x's text (unchanged bonus).

**Slices:**

1. **Leftover texts and tooltip rules** (5.x-GM `2517f573`). Verified 2026-10-17 in both trees (`GMTest_arm14` in the regression run, scripted reads): the lower-tier Feline armor (by name and owned), lower-tier Griffin boots, Kaer Morhen gauntlets and grandmaster Wolven armor are set items, a generic heavy armor is not; every set bonus (Feline, Griffin, Bear, Wolven, Manticore, Tesham Mutna, Viper, Kaer Morhen) has a filled-in text. Compiled, not seen: the generic set line on a generic piece's tooltip, the schematics' set lines.


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
| Open checks | the items worn in a real fight and their tooltips seen; Quen's shock and Melt Armor inside Yrden (same power terms, not measured); a lower-tier piece's NG+ copy; real potions drunk with the set (durations read by script) |
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

How the port reads them (2026-10-18): the top tier per piece is legacy's grandmaster Griffin piece's resistances (17/9/9/17/17% chest, 6/4/4/6/6% boots, 5/3/3/5/5% gloves, 7/4/4/7/7% trousers) with armor at level 41 (230/87/83/87; legacy's Griffin piece: 225/85/81/85); "inside Geralt's Yrden" is an enemy the trap holds (its targets list, as 5.x's own Aard bonus read it; flying enemies count once grounded); the bonus applies to the power a sign's action carries to its target (damage, effect chances and the power of its effects: knockdowns, burning, confusion, Quen's shock), Melt Armor, Firestream and Axii's duration; both bonuses read their values from `SetBonusAbilityNetflix_1/2`.

- The lower Netflix tiers keep the top tier's resistances and scale only their armor by level (Ghost Mode's rule, resistances by class and armor by level, as legacy's Griffin tiers) (porter's call, confirmed by the owner, 2026-10-18). Each tier's armor reads exactly the tier's level under [ITEM-01](item.md#item-01-item-level-from-stats)'s formula, the level of its swords: chest 130/200/230, boots and trousers 47/75/87, gloves 43/71/83 at levels 21/35/41 (the owner's decision, 2026-11-03, whole-port audit A4-3; until then 125/195/225, 45/73/85 and 41/69/81, one level lower: 20/34/40, from legacy's grandmaster Griffin values). Verified on the area build (fx-data, 2026-11-03, both trees; scripted: `GMTest_data_items` in the regression, failing first on a throwaway build with the old data).
- Dol Blathanna and White Tiger take legacy's DLC5 Nilfgaardian medium armor's resistances (chest 14/6/6/14/14%, boots 6/4/4/6/6%, gloves 5/3/3/5/5%, trousers 7/4/4/7/7%), their armor kept (porter's call, confirmed by the owner, 2026-10-18).
- Scarlet Crest's set totals are spread over the pieces as legacy's Griffin set spreads its own: armor 220/83/79/83, slashing 19/7/6/8%, piercing 15/6/5/6%, bludgeoning 21/8/6/9% (chest, boots, gauntlets, trousers) (porter's call, confirmed by the owner, 2026-10-18).
- NG+: resistances keep Ghost Mode's value (legacy kept its armor resistances in NG+), other numbers follow the NG+ rule; Dol Blathanna's new chest intensity takes the gloves' NG+ ratio (0.20) (porter's call, confirmed by the owner, 2026-10-18).

**Slices:**

1. **5.x's new armor** (5.x-GM `4794908d`). Verified 2026-10-18 in both trees (test save at level 41; gear worn by script; `GMTest_arm15` in the regression run; a neutral test dummy; real casts through `autocast`, the power read by the damage probe and from the dummy's effects): the item stats (Netflix top tier 476 armor and 35/20/20/35/35%, first tier 256 armor, gloves Yrden and trousers sign intensity, no Aard or regen; Dol Blathanna, White Tiger, Scarlet Crest 465 armor and 40/32/44/0/0%) and tags read from the definitions; three lower-tier pieces (two armor pieces and Reinald's sword) give tier 1, Swallow 24.2 s against 20 (+21%) and a decoction unchanged; six top-tier pieces 28.4 s (+42%) and tier 2. Against the dummy inside Geralt's Yrden: a real Aard's damage and its stagger carried intensity x1.962 against Aard's own x1.462 (outside Yrden x1.392, its own), with no extra direct damage (5.x's bonus gone); a real Igni's damage x1.892 against x1.392; a real Axii's confusion x1.962 inside against x1.462 outside (classic). The bonus is 0 for Yrden's own skills and outside the trap (`gmtest_arm15_yrden`, scripted). Save impact: a save made with the build before ARM-15 holding four Netflix pieces (`<save name>`), loaded: worn, they count four, give tier 1, and the chest reads 125 armor and 9% bludgeoning (`gmtest_arm15_oldsave`). Not measured: Quen's shock, Melt Armor, Firestream inside Yrden.

### ARM audit (2026-10-18)

Done by a fresh session ([audit](../feature-mapping.md#audit-signing-a-feature-off)) on 5.x-GM `4794908d` and master `c1063eba` (regression 375 passed, 0 failed in each tree, as recorded by the port), reading code and data only; no game run. Every script unit attributed to ARM-01 to ARM-15 was read against legacy's code (`legacy-GM`), 1.32 (`master`) and 5.x (`vanilla-5.x`), and the entries against the changelist's Armor section (lines 542–612), its stamina lines (233–243) and its fixes (104, 106, 144, 183). The generated item XML was checked by script rather than sampled: every ARM stat of every armor ability in `gm_arm_items.xml` (regular and NG+) against legacy's value, every item's set and class tags and enhancement slots against legacy's, and every stat DA5 covers wherever 5.x changed it; `gm_arm_kaer_morhen.xml` and `gm_arm_new.xml` value by value against legacy and against the text of DA3 and DA4. Findings go to the project owner; the fixes are made one slice at a time by later sessions.

**Checked and holding:** the generated item XML equals legacy's ARM values everywhere except F2 and F3 (all regular items' set and class tags and slots match legacy's; the abilities given whole keep 5.x's other stats); the set abilities (`gm_armor_sets.xml`, `gm_armor.xml`, `GMKaerMorhenSetBonusEffect`) equal legacy's, and their NG+ copies keep the same values, as legacy did; the Kaer Morhen items, abilities and schematics are legacy's, with no duplicate entry across the three generated files or Ghost Mode's other XML; DA3 and DA4 as written (the top Netflix tier 476 armor and 35/20/20/35/35%, gloves with Yrden intensity at the boots' values, trousers with sign intensity 0.05/0.10/0.12, the chest's attack power and adrenaline kept, potions only at 7% per piece of every tier, +0.5 intensity inside Geralt's Yrden for every sign but Yrden; Dol Blathanna's chest Igni and Aard +10% with the gloves' +5%; White Tiger's extras; Scarlet Crest 465 armor and 40/32/44/0/0%, Quen +35%, adrenaline 0.22), their NG+ copies following the NG+ rule; the class cost model (`armor/armorClass.ws`) equals legacy's `CalcStaminaArmorPenalty` and `CalcSignCastingArmorPenalty` on the same actions; the regen calculation, the generic sets and their toxicity term, the set framework's counts, tier rules and tooltip counters, and every set's mechanics (Feline chain, decay and crit adrenaline; Griffin buff and its cost sites; Bear adrenaline, attack power and refund; Wolven oil factor, crit per oil and three oils; Manticore crit chance and damage; Viper heal; Tesham Mutna heal on damage; Kaer Morhen effect, recount and combat rules; Quen Discharge's Bear effects) equal legacy's code or a recorded deviation; every set text's arguments equal legacy's `GetSetBonusTooltipDescription`; both skill trees are handled where signs are involved (Griffin's cost cut and the Netflix intensity read the sign skill, Quen Discharge's effects key on the discharge share); the temporary deviations other areas left for ARM are ended (`deviations.py --unconfirmed` lists none "until ARM"; F12 for the texts left behind); `check_modsigns.py` clean (206 bodies, 0 unmarked), `deviations.py --check` current (82), `gen_arm_items.py`, `gen_arm_km.py`, `gen_arm_new.py` and `gen_ngplus.py --check` clean; `unit_sweep.py` (set bonus, set tags, set enums, armor classes, Kaer Morhen, `staminaRegen_armor_mod`, `gm_NoSetBonuses`) finds no unattributed ARM unit (its hits are set swords' abilities, SWD's, and the free DLC armor's re-formatted entries, ECON's).

**Findings:**

1. **Four craftable quest armors were never ported nor handed off** (clear fix, docs). Legacy added craftable copies of Freya's Warriors' Armor, the Redanian Halberdier's Armor, the Hindarfjall Heavy Armor and the Oathbreaker Armor (`q108 Light armor 09_crafted`, `q108 Medium armor 03_crafted`, `q108 Heavy armor 04_crafted`, `Oathbreaker armor crafted`: legacy `def_item_crafting_armor.xml:112-284, 666, 897, 1073, 1134`), their schematics (`def_item_crafting_recipes.xml:1298, 1557`, sold by an armorer: `def_loot_shops.xml:3058, 3067-3069`; Oathbreaker's also in `def_loot_containers.xml:4177` and `def_loot_livingworld.xml:114`) and their armor-stand looks (`_armor_stand_variants_extension.xml:118, 448, 514`). The items are attributed to ARM-01 as "new item", but `gen_arm_items.py` takes only items 1.32 already had (`generate`: `if name not in m`), and nothing else ports them; the schematic, shop and armor-stand units are unattributed. Not in the changelist. Recommendation: CRAFT ports the four items whole with their schematics, shop entries and looks (the items are useless without them), with legacy's stats. **Recorded** with this audit (CRAFT's and LOOT's [hand-off](#hand-off-to-other-areas), the attribution notes, the changelist omissions in [open-questions.md](../open-questions.md#legacy-data-vs-changelist)); the owner may prefer ARM to port the items now (decision list). **Decided** by the owner (2026-10-18): the four armors, with their schematics and shop entries, go whole to CRAFT ([hand-off](#hand-off-to-other-areas)).
2. **DA5 is not fully applied: 14 armor stats keep 5.x's lower values** (clear fix). `merge_ability` (`tools/gen_arm_items.py:129`) skips every node whose legacy value equals 1.32's, so where 5.x lowered a value legacy had left at 1.32's, the port keeps 5.x's, against DA5 ("legacy's values where 5.x also changed the item"). Rending resistance (port, legacy in brackets): Griffin `Gryphon Boots 5` (grandmaster) 0.04 (0.06), `Gryphon Gloves 4` 0.03 (0.05), `Gryphon Pants 1` and `2` 0.05 (0.07); Feline `Lynx Boots 3` 0.02 (0.04), `Lynx Gloves 3` 0.02 (0.03); Wolven `Wolf Boots 5` and `NGP Wolf Boots 1` (both in the Wolven DLC file) 0.04 (0.06), `Wolf Gloves 4` 0.03 (0.05), `Wolf Pants 1` and `2` 0.05 (0.07); Manticore `Red Wolf Boots 1` 0.04 (0.06), `Red Wolf Gloves 2` 0.04 (0.05); 13 more in `items_plus`. The Netflix boots modelled on legacy's grandmaster Griffin boots (DA3) have 0.06, more than the Griffin boots themselves. Fix: for ARM's stats in an ability legacy rewrote, take legacy's value wherever 5.x's differs from it, not only where legacy's differs from 1.32's; regenerate both folders. **Fixed** (5.x-GM `9697aedf`; ARM-01 slice 2).
3. **The Manticore set gives +20 maximum toxicity, not legacy's 25 (DA6)** (clear fix). Same cause as F2: legacy's Manticore armor keeps 1.32's +10 (`Red Wolf Armor 1 _Stats`), 5.x lowered it to +5, and the port keeps 5.x's (`gm_arm_items.xml:510`): 5 + 5 + 5 + 5 = 20 with the first tier, 25 only with the mastercrafted armor. `GMTest_arm01` asserts the wrong value ("expected 5", `tests/gmTestsArm.ws:279`), and ARM-01's slice recorded "Manticore armor's +5 toxicity" as verified. Fixed by F2's generator change; the test follows (F10). **Fixed** (5.x-GM `9697aedf`; ARM-01 slice 2): +10, the set +25.
4. **Legacy's display changes to armor pieces are not carried** (clear fix). The generator carries tags, slots and ability values, not the item entries' other changes (legacy against 1.32; 5.x as 1.32 in each case): (a) the class description of ten boots and trousers whose class legacy swapped keeps the old class's text (`localisation_key_description`): `Boots 02`, `Boots 022`, `Boots 02_crafted`, `Pants 02`, `Pants 02_crafted` are medium with the light armor text, `Boots 03`, `Boots 032`, `Boots 03_crafted`, `Pants 03`, `Pants 03_crafted` light with the medium armor text; (b) Yoana's reward armor (`q108 Medium armor 10`, made heavy by legacy, "reward armor (heavy, relic)") keeps the medium armor's name, look, icon, description and armor-stand look (legacy: `item_name_heavy_armor_03`, `t_01_mg__common_heavy_lvl3` and its gloves variant, the heavy icon and description, `_armor_stand_variants_extension.xml:206`); (c) the `Autogen` pieces quests put on Geralt keep 1.32's abilities: the trousers get no resistances and the boots the starting boots' 4 armor (legacy gave them its new `Autogen Boots _Stats` and `Autogen Pants _Stats` and added `Default armor _Stats` to all four, legacy `def_item_weapons_relic_autogen.xml:116-130`); (d) the grandmaster Feline armor's look (`Lynx Armor 4`: legacy `t_02_mg__lynx_lvl5`, its mask variant commented out) and the icons of 21 boots, gauntlets and one armor (legacy gave each level its own icon; 1.32 and 5.x show the level-1 icon). Fix: carry `localisation_key_name`, `localisation_key_description`, `icon_path`, `equip_template`, `<variants>` and the ability list of armor pieces where legacy changed them, add legacy's two new `Autogen` abilities, and Yoana's armor-stand entry. (a) to (c) change what the player reads or the stats; (d) is cosmetic. **Fixed** but (b) (5.x-GM `9697aedf`; ARM-01 slice 2): (a), (c) and (d), the icons and the template present in 5.x; legacy's other display changes not carried (ARM-01's deviation). (b) (F4b) **fixed** as legacy by the owner's decision (2026-10-18; 5.x-GM `eef6186c`; ARM-01 slice 3), with its armor-stand look.
5. **The "Fully Armed" achievement no longer counts lower-tier sets, and still needs the crossbow** (clear fix; doc corrected). Lower-tier pieces carry `<School>SetMinor` instead of the school tag, so 5.x's `CheckForFullyArmedAchievement`, `HasAllItemsFromSet`, `CheckForFullyArmedByTag` (5.x `playerWitcher.ws:5745-5835`) and `DetectTagOfASet` (5.x `inventoryComponent.ws:4007`, called on equip, `playerWitcher.ws:6532`) never see them: a full lower-tier set gives neither the achievement nor its progress, which vanilla and legacy did. Legacy's versions (legacy `playerWitcher.ws:5854-5895`) accept the four lower-tier tags, drop the crossbow requirement for Bear and Feline and leave Viper out. ARM-05 had attributed the lower tiers to the "Ready to Roll" achievement, which legacy grants for any full bonus (as ported). Fix: legacy's two functions (keeping 5.x's Netflix and its per-tag progress notice if wanted). ARM-05's "What it does" is corrected with this audit. **Fixed** (5.x-GM `9697aedf`; ARM-05 slice 2), 5.x's Netflix and its progress notice kept (ARM-05's deviation).
6. **The Bear sound bank is not loaded for Quen Discharge** (clear fix). Legacy loads `ep2_setbonus_bear.bnk` at every spawn, "used by regular Quen now" (legacy `playerWitcher.ws:382, 11471-11474`), since Quen Discharge plays the Bear set's effects (ARM-08). The port loads it only while three Bear pieces are worn (`armor/setFramework.ws:476-514`), so Quen Discharge's `default_fx_bear_abl2` and `quen_rebound_sphere_bear_abl2` likely play without their sound otherwise. Fix: load the bank at spawn as legacy (`OnSpawned` wrapper, `armor/setFramework.ws:519`); listen in game. **Fixed** (5.x-GM `9697aedf`; ARM-05 slice 2), and never unloaded (ARM-05's deviation); not listened to.
7. **The Feline set's HUD counter is overwritten every frame** (clear fix; code read, to confirm in game). ARM-06 puts the counter in `UpdateBuffs` (`mutations/hudCounters.ws:63, 118-121`), but 5.x's `CR4HudModuleBuffs.OnTick` refreshes every shown effect's numbers each tick and, for an effect without a duration, sends 1/1; legacy's `OnTick` sends the Feline stacks (legacy `hudModuleBuffs.ws:198-202`). The unit `CR4HudModuleBuffs.OnTick` is attributed to ARM-06 and not ported. Fix: the Feline case in `OnTick` (as 5.x does for Mutations 3, 4, 5 and 10); check on screen. **Confirmed and fixed** (5.x-GM `9697aedf`; ARM-06 slice 2): the HUD read "1%" with the chain at 60%, "60%" after the fix.
8. **Armor tooltips still mark the class as changed by Levity, Balance or Heft** (clear fix). 5.x's `GetBaseItemData` sets `hasEnchantedType` for an equipped armor piece whenever one of the three glyphwords is on Geralt (5.x `guiTooltipComponent.ws:481`), which shows the class as altered; since DA7 the class is the item's, and legacy sets the flag false (legacy `guiTooltipComponent.ws:503`). The port's `GetBaseItemData` wrapper (`armor/setTooltips.ws:124-133`) leaves it. Fix: clear the flag in that wrapper. **Fixed** (5.x-GM `9697aedf`; ARM-02 slice 2).
9. **In New Game+, lower-tier school gear counts towards the full set bonus** (clear fix). 5.x tags every NG+ tier `SetBonusPiece`, and the 72 `NGP` lower-tier Feline, Griffin and Bear armor pieces and swords keep the school tag (`items_plus/gm_arm_items.xml`, from legacy's own NG+ entries, which have the school tag and no `SetBonusPiece`), so they count as grandmaster pieces: six of them give tier 2. Legacy's regular items use `*SetMinor`; the [NG+ rule](../feature-mapping.md#ng-numbers) makes the same non-numeric change in NG+. ARM-05's NG+ row ("the NG+ items get legacy's tags") is literally true, but legacy's NG+ entries never got the minor tags. Fix: in `items_plus`, give the `NGP` lower tiers the regular items' rule (`*SetMinor` and `SetBonusPiece`), in the generator. **Fixed** (5.x-GM `9697aedf`; ARM-01 slice 2), for NG+'s regular-named lower tiers too (169 NG+ items; ARM-05's deviation).
10. **Regression gaps** (clear fix, tests and tools). `GMTest_arm01` checks a handful of values and enshrines F3's wrong one; no check compares the generated XML with legacy's values (F2, F3 and F9 were found by a script, not by a test); nothing checks the Fully Armed achievement (F5), the Bear bank (F6), the HUD counter (F7), the tooltip flag (F8) or the NG+ set tags (F9). Fix: a `--verify` mode in `gen_arm_items.py` that compares every ARM stat, tag and slot of the final items (generated or 5.x's) with legacy's and reports differences other than the recorded deviations (ARM-01's fixed armor until ITEM), run with the other checks; in `GMTest_arm01` legacy's Manticore armor +10 and the set's +25, and a DA5 stat F2 fixes (grandmaster Griffin boots' rending 0.06); in `GMTest_arm05` the achievement functions with a lower-tier set; F6 to F8 with a scripted check where one is possible. **Fixed** (5.x-GM `9697aedf`): `--verify` (0 unexplained differences); `GMTest_arm_audit` (F2 to F6, F8) and `GMTest_arm01`'s +10 in the regression run, `gmtest_arm_fullyarmed` (F5 with gear worn); F7 checked on screen; F9 by `--verify` only (a regular game does not read NG+ data).
11. **The Kaer Morhen schematics after the mod is removed and reinstalled** (no action; **closed**). The schematics are granted once per fact (`gm_km_schematics_added`, `armor/kaerMorhenSet.ws:69-78`), as legacy's `ModSignsKMSetSchematicsAdded`. Whether a save loaded without the mod keeps the schematic names it no longer knows is unprobed (ARM-12's open check); if the game drops them, a save brought back to Ghost Mode would never get them again. Checking the known list instead of the fact would cover that at no behaviour cost; worth doing only if the probe shows the loss. **Closed** by the owner's decision (2026-10-18): adding or removing the mod in the middle of a playthrough is not supported ([save compatibility](../feature-mapping.md#save-compatibility)), so the schematics after a removal do not matter; ARM-12's open check is dropped.
12. **Other areas' docs still waited for ARM or described 5.x's ARM rules** (corrected with this audit): the [status page](README.md#where-the-port-stands)'s SKL row listed temporary deviations "until ARM" (none left); [skl.md](skl.md) SKL-11 slice 3 said 5.x's Bear set 2 bonuses check the classic `magic_s14` (gone with ARM-08); [stam.md](stam.md) STAM-05's "What it does" said the option restores 5.x's calculation (legacy's since ARM-03); [dmg.md](dmg.md) DMG-04's open checks listed the Lynx and Wolven pool terms (gone with ARM-06 and ARM-09). No deviation of STAM, DEF, DMG, SKL or MUT is left waiting for ARM.
13. **Stale or missing ARM texts and hand-offs** (corrected with this audit): this page's unit-list status and the [status page](README.md#where-the-port-stands) ("audit next"); ARM-05's "What it does" (F5); ARM-01's slice (F3's value); hand-offs: CRAFT and LOOT (F1), WGT (Scarlet Crest's 8.2 weight, DA4; legacy adds the overencumbrance stamina penalty to the class penalty in one factor, `1 + armor + overencumbrance`, legacy `PlayerAbilityManager.ws:1273-1277`, where the port multiplies the class term on its own), UI (the character panel's Yrden range with the Griffin set's +40%, legacy `CharacterStatsPopup.ws:825-829`); [attribution.csv](attribution.csv): F1's 16 item and ability rows (regular and NG+), and `SetGeraltLevelHandsOn` (legacy still equips the Feline armor there; its change is a level reset and line breaks, no ARM change).
14. **Porter's calls not confirmed by the owner** (owner decision): ARM-01's fixed armor kept until ITEM; ARM-04's, ARM-06's and ARM-08's character panel lines and ARM-09's oil tooltip until UI; ARM-12's new schematic's name ("Kaer Morhen Armor schematic"); ARM-15's four calls (the lower Netflix tiers keep the top tier's resistances and scale only armor; Dol Blathanna and White Tiger take legacy's Nilfgaardian DLC medium resistances; Scarlet Crest's totals spread as the Griffin set's; the NG+ choices). Recommendation: confirm all; they follow legacy's rules or wait for their areas. **Decided** (project owner, 2026-10-18): all confirmed, each deviation marked so.
15. **Small differences with no effect found, or kept on purpose** (no action): `ManageActiveSetBonuses` also ends the Griffin buffs when lower-tier pieces come off (legacy only for grandmaster pieces; the buff lasts 2.5 s, the inside-Yrden buff needs grandmaster pieces anyway); the set pieces are recounted and the generic set checked at every load (legacy once on old saves; same counts); 5.x's new medium armor (Dol Blathanna, White Tiger, Scarlet Crest) counts towards the generic medium set, as legacy's free DLC armor does; the lower Netflix tiers keep `NetflixSet`, so 5.x's Fully Armed counts them (5.x's rule); the Griffin set's larger Yrden trap is SKL-10's code (5.x's trigger scaling in `Place`), not re-reviewed here; legacy's debug commands (`addset`, `addkmset`, ...) are not ported; the set texts use `NoTrailZeros` where legacy used `FloatToString` (same numbers, without trailing zeros); removing the mod leaves the generic set's ability on Geralt without its definition (no effect; an unsupported case, recorded in the save impact).

**Doc corrections made with the audit:** F1, F5's text and F12 to F13: this page (unit-list status, ARM-01's slice, ARM-05's "What it does", the hand-off table, the save impact), the [status page](README.md#where-the-port-stands), [skl.md](skl.md), [stam.md](stam.md), [dmg.md](dmg.md), [attribution.csv](attribution.csv) (17 notes), [open-questions.md](../open-questions.md#legacy-data-vs-changelist) (the omission).

**Not reviewed:** the translations' wording (legacy's rows as shipped, SKL-19's rule); the test functions' internals beyond what they report; SKL-10's Yrden trap size with the Griffin set (signed off with SKL); NG+ in game (the policy: not tested).

**Suggested fix slices** (each touches its own files; code slices verified in game, in both trees where signs are involved):

- **A, item data** (`tools/gen_arm_items.py`, the generated `items/` and `items_plus/gm_arm_items.xml`, Yoana's armor-stand entry in Ghost Mode's DLC): F2, F3, F4, F9, and F10's `--verify` mode. **Done** (5.x-GM `9697aedf`, 2026-10-18); F4b with Yoana's armor-stand entry after the owner's decision (5.x-GM `eef6186c`).
- **B, achievement and sound bank** (`armor/setFramework.ws`): F5, F6. **Done** (5.x-GM `9697aedf`).
- **C, HUD and tooltip** (`mutations/hudCounters.ws`, `armor/setTooltips.ws`): F7, F8; screenshots of the counter and a tooltip. **Done** (5.x-GM `9697aedf`; the counter seen on screen, the tooltip flag read by script).
- **T, tests** (`tests/gmTestsArm.ws`): F10's checks, after A to C. **Done** (5.x-GM `9697aedf`): regression 385 passed, 0 failed in each tree.
- **D, docs**: F1, F5's text, F12 and F13 **done** (2026-10-18); the slices' results go into the entries as they land.

#### Audit close-out

Closed 2026-10-18: every finding is fixed, recorded or decided by the owner. Fixed and verified in both trees: F2 to F10 (5.x-GM `9697aedf`) and F4b (`eef6186c`). Recorded: F12 and F13 (doc corrections), F15 (no action). Decided by the owner (2026-10-18): F1 (the four craftable quest armors go whole to CRAFT), F4b (Yoana's armor as legacy), F11 (closed: adding or removing the mod mid-playthrough is not supported), F14 (the porter's calls confirmed). Checks at close: regression 385 passed, 0 failed in each tree; `gen_arm_items.py --verify` 0 unexplained differences; `check_modsigns.py` 0 unmarked.

The owner confirmed the fix round's porter's calls (2026-10-18): 5.x's Fully Armed grant on equip for the Manticore, Tesham Mutna and Netflix sets; in New Game+ the lower tiers of the school gear take the regular lower tiers' tags (ARM-05); the Bear sound bank is never unloaded (ARM-05); legacy's cosmetic display changes are not carried (NG+ names, NG+-only glove looks, the `Autogen` trousers' shirt variant and collapse rules; ARM-01). **Signed off** by the project owner, 2026-10-18 (ARM-01 to ARM-15). What stays open after the sign-off: the open checks listed in the entries; ARM's temporary deviations, confirmed, each until another area (ITEM, ENCH, UI); no ARM deviation is left unconfirmed (`python tools/deviations.py --unconfirmed`).

---

### Dependencies on other areas

- **Done areas ARM builds on:** STAM-03 (cost functions; ARM-02, ARM-07), STAM-05 (the regen option; ARM-03), DEF-01 (the light set's dodge angle; ARM-04), DMG (pool terms for Feline, Bear, Wolven, Netflix, the crit check, `ProcessActionDamage`), SKL-07 (adrenaline), SKL-11 (Quen, Quen Discharge), SKL-14 (oils), SKL-18 (school perks, Rage Management).
- **Areas ARM waits for or shares with:** ENCH (done 2026-10-19: Levity, Balance, Heft's stamina trades, ENCH-10; Glyphword 5's Quen Discharge boost, ENCH-12; Glyphword 22 removed, ENCH-18), ALCH (done 2026-10-20: Golden Oriole with Viper, ALCH-05; potion duration no longer raising bomb damage, ALCH-14; oil items, ALCH-16), ITEM (item level), CRAFT (schematics, crafting costs), WGT (armor weight), ECON (prices), UI (character panel lines).

### Hand-offs received

Every item other areas handed to ARM, and where it lands:

| From | Item | ARM |
|---|---|---|
| SKL (audit F3, 2026-10-16) | Legacy's Gryphon set redesign, ending 5.x's free sign casts (and Flood of Anger's payment on them) | ARM-07 (DA1) |
| SKL-11 (F19, 2026-10-16) | The Bear set's tier 2 redesign, freeing its effects for Quen Discharge's visuals; Quen Discharge's Bear boost | ARM-08 (DA8); Glyphword 5's boost: ENCH |
| SKL-07 | The Bear set's adrenaline on hits taken; the Feline set's double adrenaline on crits | ARM-08, ARM-06 |
| SKL-14 | The Wolven set's oil bonuses, crit per oil, several oils | ARM-09 (DA2) |
| SKL-18 | Armor classes for the school perks; Gryphon free cast with Rage Management (open check) | ARM-02 (DA7), ARM-07 |
| STAM-03 | Armor class cost modifiers; Griffin set free alternate cast; Bear tier 2 refund; Kaer Morhen regen; Vampire set | ARM-02, ARM-07, ARM-08, ARM-12, ARM-13 |
| STAM-05 | Legacy's armor regen calculation and per-piece `staminaRegen_armor_mod` values | ARM-03 |
| DEF-01, DEF-06 | The light armor set bonus (read only); the Lynx set in `PerformCounterCheck` | ARM-04, ARM-06 |
| DMG | Armor values and resistances by class; Viper healing; Lynx, Bear, Red Wolf terms; Wolven and Netflix pool terms; silver studs; Golden Oriole | ARM-01, ARM-11, ARM-06, ARM-08, ARM-10, ARM-09, ARM-15; Golden Oriole with ALCH |
| MUT (audit note) | The Gryphon trigger in `OnSignCastPerformed` | ARM-07 |
| balance.md | Set bonuses and armor classes for the archetypes | ARM-02, ARM-04, ARM-06 to ARM-13 |

### Hand-off to other areas

| Area | Changes |
|---|---|
| ECON | Prices of every armor item (449 item entries; left unattributed) |
| CRAFT | Dismantling parts of armor items (448); witcher gear schematics and their costs (about 180 schematic units, except Kaer Morhen's); mastercrafted kits (`AddMasterArmorerItems`, master repair kits); legacy's four craftable quest armors (Freya's Warriors' Armor, the Redanian Halberdier's Armor, the Hindarfjall Heavy Armor, the Oathbreaker Armor: `q108 Light armor 09_crafted`, `q108 Medium armor 03_crafted`, `q108 Heavy armor 04_crafted`, `Oathbreaker armor crafted`), whole: items and abilities with legacy's stats, schematics, shop entries, armor-stand looks ([audit F1](#arm-audit-2026-10-18); the owner's decision, 2026-10-18) |
| WGT | Armor weights (425 abilities), Scarlet Crest's 8.2 (DA4); the Thief armor's carry bonus stays with ARM-01; legacy adds the overencumbrance stamina penalty to the armor class penalty in one factor (`1 + armor + overencumbrance`, `GetStaminaActionCost`), where ARM-02 multiplies the class term on its own |
| ITEM ([item.md](item.md#hand-offs-received), mapped 2026-10-19) | Item level (`GenerateItemLevel`, `GetItemLevel`, `AddItemLevelAbility`, `item_level_min/max`, `Autogen*` tags, `DoNotEnhance` where legacy removed it; where it added it, ARM-01 carries it since 2026-10-19), random enhancements, durability, the Armorer's Table buff (`AddRepairObjectBuff`, changelist 857) |
| ENCH | Levity, Balance and Heft's stamina trades (`GetGlyphword234Mod`, `HasGlyphwordActive`, runeword tooltips); Glyphword 5 (Quen Discharge); 5.x's `Glyphword 22 Bonus` |
| SWD | Set swords' stats (their set tags are ARM's) |
| ALCH | Golden Oriole's poison absorption (with ARM-11); potion duration rules for Manticore and Netflix gear |
| LOOT | Where witcher gear diagrams and armor drop; the shop and container entries of the four craftable quest armors' schematics (with CRAFT) |
| UI | The character panel's armor and set lines beyond ARM-04's toxicity line (ARM-04, ARM-06, ARM-08 temporary deviations); the Yrden range line with the Griffin set's +40% (legacy `AddCharacterStatSigns`); the oil tooltip's Wolven boost (ARM-09) |

### Save impact

Mostly none: set counts, bonuses and costs are computed live, and items owned before read the changed tags and stats from the definitions (verified, ARM-05 and ARM-01). Exceptions: the Kaer Morhen set adds items and schematics (granted at load), and 5.x's "Starting Armor Upgrade schematic 1" is removed at load (ARM-12). Removing the mod mid-playthrough is not supported ([save compatibility](../feature-mapping.md#save-compatibility)); as facts: the Kaer Morhen pieces vanish from the save and worn ones leave their slots empty (verified, ARM-12), 5.x teaches its starting armor schematic again, and the generic set's ability stays on Geralt without a definition (no effect); whether the Kaer Morhen schematics survive a save made without the mod is not probed ([audit F11](#arm-audit-2026-10-18), closed by that policy).

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
| DA7 | Levity, Balance and Heft changing the armor class (5.x, and SKL-18's school perks today) | (a) legacy: the class is the item's, from ARM-02 on; the glyphwords do nothing until ENCH gives them legacy's stamina trades (a temporary deviation); (b) keep 5.x's class change until ENCH | **(a) legacy** | (a), as recommended |
| DA8 | Bear set tier 2 and Quen | (a) legacy: no Quen rules, the refund on strong attacks, Quen Discharge plays the effects; 5.x's supercharged-Quen boost goes too; (b) keep 5.x's Quen boost | **(a) legacy** | (a), as recommended |

**Questions without a clear recommendation** (answered by the owner, 2026-10-17, with DA3 and DA4): the Netflix set stays, with its tiers at levels 21/35/41; the new pieces stay at their current levels (8, 12, 41).

### Port order

Porter's plan (2026-10-17), one slice per feature, each with its descriptions (ARM-14) and its tests, both trees where signs are involved:

| # | Slice | Ends |
|---|---|---|
| 1 | ARM-05 set framework (tags in the item XML, minor tiers, Viper and Kaer Morhen types) | — |
| 2 | ARM-02 armor classes and stamina costs | STAM-03's hand-off; SKL-18's glyphword class counts (DA7) |
| 3 | ARM-01 armor pieces (generated XML; save impact tested here) | DMG's armor hand-off |
| 4 | ARM-04 generic sets | DEF-01's open check |
| 5 | ARM-07 Griffin (**done**) | SKL's F3 free casts, SKL-18's open check |
| 6 | ARM-08 Bear (**done**) | SKL-07's and SKL-11's Bear deviations, Quen Discharge's visuals, DMG's Bear term |
| 7 | ARM-06 Feline (**done**) | SKL-07's, DEF-06's and DMG's Lynx deviations |
| 8 | ARM-09 Wolven (**done**) | SKL-14's Wolf deviation, DMG's Wolven term |
| 9 | ARM-10 Manticore (**done**) | DMG's Red Wolf term |
| 10 | ARM-11 Viper (**done**) | DMG's Golden Oriole deviation (with ALCH) |
| 11 | ARM-13 Tesham Mutna (**done**) | STAM-03's Vampire hand-off |
| 12 | ARM-12 Kaer Morhen (new items) (**done**) | — |
| 13 | ARM-03 regen with the option on (**done**) | STAM-05's deviation |
| 14 | ARM-14 leftover set texts and tooltip rules (**done**) | — |
| 15 | ARM-15 5.x's new armor (per DA3, DA4) (**done**; with ARM-12's schematic removal) | DMG's Netflix pool term, SKL-13's Netflix decoction duration |

## For the shared docs

Moved into the shared docs at integration (2026-11-02).
