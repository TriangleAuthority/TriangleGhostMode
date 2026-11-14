# Ledger: gear: legacy vanilla 1.32, legacy Ghost Mode, vanilla 5.x

**Status: from data/code, not tested in game.** Every number below was read from the XML definitions and scripts on the three refs: `vanilla-1.32`, `legacy-GM` (Ghost Mode 4.1) and `vanilla-5.x`. For 5.x the item and set-bonus texts were decoded from the installed game's `content0/en.w3strings`. Where the GM changelist (`docs/legacy-FullChangelist.txt`) disagrees with GM's data, the data value is given and the mismatch flagged. Unless noted, the NG+ copies (`*_plus`) are ignored.

Abbreviations: **AP** attack power, **SI** sign intensity, **adr** adrenaline (`BCS_Focus`), **pc** piece(s), **GM-4** a 4-piece generic set, **3/6** minor/major set bonus thresholds (3 and 6 pieces in all three versions; GM's Kaer Morhen set has 4 pieces).

## How to read the numbers

- **Adrenaline gain:** each melee hit gives `0.1 × (1 + focus_gain)` adr, the same in 1.32 and GM (`playerWitcher.OnProcessActionPost`). So `focus_gain 0.20` = +20% per hit, while GM's flat `bonus_focus_gain` (Bear perk, Bear set) adds points per hit **on top**: +0.025/hit is +25% of a base hit. In GM, being hit drains adr in proportion to the damage taken.
- **Which items count toward set bonuses:** only items tagged `SetBonusPiece`.
  - **1.32 and 5.x (regular game):** only the grandmaster tier of the four schools (BaW: 4 armor plus 2 swords), Manticore, Tesham Mutna and, in 5.x, the Netflix set. Lower-tier school gear gives no set bonus. In 5.x's NG+ data (`items_plus`), every tier is tagged.
  - **GM:** every tier counts toward the minor (3-pc) bonus (`EIST_*_Minor` tags, added up by `GetSetPartsEquipped`). The 6-pc bonus needs 6 grandmaster pieces. Kaer Morhen and Viper count from tier 1.
- **Stamina regen (`staminaRegen`):** `mult` values are % of base regen. GM's base regen is 15/s, vanilla's is 10/s.
- **Potion duration (`potion_duration`):**
  - 1.32 and 5.x: applies to potions and decoctions.
  - GM: potions only; `CalculatePotionDuration` excludes mutagen potions.
  - 5.x also multiplies bomb damage and bomb DoT by `1 + potion_duration` (`damageManagerProcessor` ~1868, `dotEffect` ~84). In a port, any GM source of `potion_duration` (Water Hag trophy, GM's Manticore pieces) would also boost bombs unless that is handled.

## 1. Armor classes (stamina)

| | 1.32 vanilla | Ghost Mode | 5.x vanilla |
|---|---|---|---|
| Stamina regen by armor | `staminaRegen_armor_mod` on each piece: light chest +10%, gloves +2%, pants +10%, boots +3% (light set up to +25%); heavy the same values negative (up to −25%); medium 0. | Off by default (option "Enable stamina regen penalty for armors"). With it on: the piece values above, plus +11/+2/+3/+4% per **missing** chest/gloves/pants/boots. | As 1.32 (same function and data). |
| Stamina **cost** by armor | none | melee actions: **light −7.5%/pc (−30%)**, medium 0, heavy **+12.5%/pc (+50%)**, missing piece **−12.5%** (naked −50%); signs: heavy +12.5%/pc (+50%) (`CalcStaminaArmorPenalty`, `CalcSignCastingArmorPenalty`) | none |
| Generic 4-pc set bonus (non-witcher armor) | none | light: +30° dodge safe angle; medium: toxicity decays 0.25/s faster (`toxicityRegen −0.25`); heavy: +10% all resistances | none |
| Glyphwords Levity / Balance / Heft (HoS) | armor is treated as light / medium / heavy: counts for school perks and the regen modifier (Levity +25%, Heft −25% when all 4 are worn) | **Replaced:** armor class no longer changes (code commented out). Levity: melee −20% cost, signs +20%. Balance: signs −20%, melee +20%. Heft: melee +20% cost and +20% damage. | as 1.32 |

Witcher armor classes (same on all three refs): Feline light; Griffin, Wolven, Manticore, Viper (HoS) and Netflix medium; Ursine and Tesham Mutna heavy. GM's Kaer Morhen set is medium.

**School perks per piece** (stats they scale):

| Perk | 1.32 vanilla | GM | 5.x classic | 5.x new tree (per skill level, per piece) |
|---|---|---|---|---|
| Cat (perk_5, light) | +25% fast-attack crit chance, +5% fast-attack AP | +5% crit chance, +20% crit damage | as 1.32 | perk_23: +8% crit damage, +2% fast AP |
| Griffin (perk_6, medium) | +5% SI, +5% stamina regen | +5% SI, −5% sign stamina cost | as 1.32 | perk_24: +2% SI, +0.2% stamina regen |
| Bear (perk_7, heavy) | +5% max vitality, +5% strong-attack AP | +7.5% max vitality, **+0.025 adr per hit (flat)** | as 1.32 | perk_25: +2% vitality, +2% strong AP |

5.x also has perk_26 to perk_28 (AP/SI, fast/strong/bomb, poison/vitality at +2%). The project's SKL docs map these.

## 2. Witcher school sets

### Feline (Lynx; light; Cat school)
- **Availability:** vanilla tiers lvl 19/25/31/36, grandmaster 40 (BaW). GM tiers 17/23/29/34, grandmaster 40.
- **Item stats:** 1.32/5.x: AP +5 to 22% per piece, crit chance, bleeding chance. GM: AP up to +30%, crit chance up to +35% per piece, bleeding chance.

| | 1.32 vanilla | GM | 5.x |
|---|---|---|---|
| 3 pc | A strong attack gives fast attacks +10%/pc damage for 5 s (+60% at 6 pc) | **Replaced:** each fast hit in a chain adds +2.5% AP per piece (+15%/hit at 6 pc), up to +60%. A strong attack finishing the chain "discharges" it at double the current bonus. Resets when the chain breaks or combat ends. | as 1.32 |
| 6 pc | Rear attacks +50% damage; stun for 1 adr | **Replaced:** sword crits give **double adrenaline** | as 1.32 |
| Stats scaled | AP (fast) | AP (fast/strong), **adr gain** (with crits) | AP |

### Griffin (Gryphon; medium)
- **Availability:** vanilla 13/20/28/36, GM 11/18/26/34; grandmaster 40.
- **Item stats:** SI. 1.32/5.x also crit; GM SI only (plus fire damage on items).

| | 1.32 vanilla | GM | 5.x |
|---|---|---|---|
| 3 pc | After a standard cast paid with stamina, the next standard sign within 3 s is free | **Replaced:** casting a sign makes all actions cost −5%/pc stamina (−30% at 6) for 2.5 s | as 1.32 |
| 6 pc | Yrden traps +40% size; inside your Yrden: stamina regen +5%, SI +100%, damage taken −20% | Yrden +40%; inside: SI **+50%**, **+15% all resistances**; stamina regen bonus **removed** | as 1.32 |
| Stats scaled | **sign stamina**, SI, stamina regen | **stamina cost (all actions)**, SI | as 1.32 |

### Ursine (Bear; heavy)
- **Availability:** vanilla 22/27/32/36, GM 20/25/30/34; grandmaster 40.
- **Item stats:** **focus_gain** on every piece.
  - 1.32/5.x: tier 3 = 0.20 + 3 × 0.10 + 2 × 0.20 ≈ **+90% adr gain**; grandmaster ≈ 0.22 + 3 × 0.11 + 2 × 0.21 ≈ **+97%**.
  - GM: chest 0.10 to 0.30, other pieces 0.04 to 0.12, swords 0.15 to 0.30 (grandmaster ≈ **+126%**). GM swords also have AP +20 to 40%.
  - 1.32/5.x items also have crit damage.

| | 1.32 vanilla | GM | 5.x |
|---|---|---|---|
| 3 pc | When Quen breaks, 5%/pc chance to recast it for free | **Replaced:** taking damage gives **+0.035 adr/pc** (0.21 at 6, offsets the drain); **+3.5% AP/pc per adrenaline point** (+21%/pt at 6) | as 1.32 |
| 6 pc | Quen abilities deal +200% damage | **Replaced:** a damaging strong attack (or Rend) **refunds 33.4% of its stamina cost** | as 1.32 (also with supercharged signs on the new tree) |
| Stats scaled | adr (items), Quen | **adr gain and retention, AP per adr, strong-attack stamina** | as 1.32 |

### Wolven (Wolf; medium; DLC10 free DLC base set + BaW grandmaster)
- **Availability:** vanilla 16/23/31/36, GM 21/24/28/34; grandmaster 40.
- **Item stats:** focus_gain + AP + SI (hybrid). GM: chest up to 0.15 focus_gain, other pieces 0.03 to 0.07, AP and SI up to +30%.

| | 1.32 vanilla | GM | 5.x |
|---|---|---|---|
| 3 pc | Up to 3 oils at once on a sword (`max_oils_count`) | **Replaced:** oil effects +16.7%/pc (+100% at 6) | **Changed:** each Bleeding stack on enemies within 50 m adds +1%/pc to sword damage |
| 6 pc | The only code that reads it is **"bombs thrown without delay"** (`petard.ws`). This looks like a vanilla mix-up: the Manticore 3-pc text claims that effect. The 1.32 description string could not be read. | 3 oils at once; **each oil +5% crit chance, +10% crit damage** | **Changed:** each adr point raises the number of Bleeding stacks per enemy |
| Stats scaled | oils | **oil-scaled AP/crit**, crit | sword damage (bleed), uses **adr** |

In 5.x oils no longer use charges and the multiple-oils code is gone.

### Manticore (Red Wolf; medium; BaW, late)
- **Availability:** 2 tiers, BaW, late (around grandmaster level).
- **Item stats:**
  - **Max toxicity:** 1.32 chest +10, pants +10, gloves +5, boots +5 = **+30**. GM +25 (chest 10, others 5 each). 5.x **+20** (chest and pants cut to 5).
  - **GM adds `potion_duration`:** chest +10%, other pieces +5% each = **+25%** (not in the changelist).
  - Other stats: 1.32/5.x crit chance and damage, focus_gain 0.20 on chest and boots, armor reduction 250. GM: swords focus_gain 0.25, armor reduction 80, armor reduction % 15.

| | 1.32 vanilla | GM | 5.x |
|---|---|---|---|
| 3 pc | Bombs can crit (using your crit stats) | Bombs: no throw delay, can crit, **+5% bomb crit chance and +10% bomb crit damage per piece** | Bombs can crit **and no throw delay** (moved here from Wolven 6, as GM did) |
| 6 pc | +1 charge for every alchemy item except decoctions | same (+1) | same |
| Stats scaled | bomb crit, **max toxicity** | bomb crit, **max toxicity, potion duration** | bomb crit, max toxicity (lower) |

## 3. Other sets

| Set | 1.32 vanilla | GM | 5.x | Availability |
|---|---|---|---|---|
| **Kaer Morhen** (GM only, 4 medium pieces) | n/a | 3+ pc: **stamina regen +1/s per additional enemy in combat, max +5/s** | n/a | from the start; tiers lvl 2/9/19/27 |
| **Viper** (HoS "EP1 Witcher" gear, medium) | no set bonus | 3+ pc: poison immunity; poison heals 10%/pc of poison damage. Armor pieces **+5 max toxicity each** (not in the changelist). | no set bonus (`EIST_Viper` exists, no bonus) | HoS, ~lvl 34 |
| **Tesham Mutna** (`VampireSet`, BaW q702/q704, heavy) | 3+ pc: a kill restores 1%/pc max vitality | **Changed:** dealing damage heals 0.5%/pc (3% max) | as 1.32 | BaW, late |
| **Netflix** (5.x only, dlc18, medium, 4 armor + 2 swords) | n/a | n/a | 3 pc: **potion duration +7%/pc** (potions and decoctions; +42% at 6). 6 pc: Aard hitting enemies inside Yrden deals extra damage (scales with SI). Items: focus_gain (chest 0.08 to 0.20, swords 0.03 to 0.10), AP, SI, crit. | 5.x, mid (3 tiers) |

## 4. Runes and glyphs (single upgrades, mostly main game; Pierog, Tvarog, Warding, Binding, Reinforcement and Mending are HoS)

| Upgrade | 1.32 vanilla (lesser/normal/greater) | GM | 5.x |
|---|---|---|---|
| **Perun** (rune) | **adr gain +2/3/5%** | +3/4/5% | as 1.32 |
| Elemental (rune) | AP +2/3/5% | +3/4/5% | as 1.32 |
| Veles (rune) | SI +2/3/5% | +3/4/5% | as 1.32 |
| Svarog (rune) | armor reduction 10/20/30 | 10/15/20 | as 1.32 |
| Stribog, Dazhbog, Devana, Zoria, Morana, Triglav | stagger/burn/bleed/freeze/poison/confusion chance 2/3/5% | 3/4/5% | as 1.32 |
| Pierog / Tvarog (HoS) | nothing | **+5 vitality regen** out of combat / in combat | nothing |
| Glyphs of Aard/Axii/Igni/Quen/Yrden | +2/5/10% to that sign's intensity | +3/4/5% | as 1.32 |
| Mending (HoS) | vitality regen +1/2/3 | +3/4/5 | as 1.32 |
| Warding (HoS) | elemental resistance +1/2/3% | **Quen on projectile hit 3/4/5%** | as 1.32 |
| Binding (HoS) | bleed resistance (mult) | bleed resistance (base) 3/4/5% | as 1.32 |

No rune or glyph touches stamina, toxicity or potion duration on any ref. **Perun is the only rune for adrenaline gain.**

## 5. Runewords and glyphwords (Hearts of Stone enchanter, data in `dlc/ep1`)

Note: the task brief and `docs/features/deviations.md` call these Blood and Wine. The data is HoS (`dlc/ep1`, Oxenfurt enchanter). Only the entries relevant to the target stats are listed; the full GM list is in the changelist.

| Word (internal no.) | 1.32 vanilla | GM | 5.x | Stats |
|---|---|---|---|---|
| **Elation** (Runeword 12) | a kill gives **0.1 to 0.25 adr** | a kill gives **0.25 adr** (enchanter level 1) | a kill gives **1.0 adr** (`focus_runeword_gain`) | **adr gain** |
| **Placation** (Runeword 8) | at max adr, adr drains (`focus_drain` 0.08, presumably 0.08 adr/s) while stamina regen is +25%, vitality regen +1%, toxicity −2/s | drains 0.3 adr/s; stamina regen **+5%**, vitality regen +5%, **toxicity −5/s** | as 1.32 | **stamina regen, toxicity, uses adr** |
| **Rejuvenation** (Runeword 10) | a kill restores **25% stamina** | **Replaced:** a kill heals 15% vitality | a kill restores **100% stamina** (`stamina_runeword_gain`) | **stamina** |
| **Prolongation** (Runeword 11) | each unblocked hit adds **+0.5 s** to active potions | **Replaced:** excess adr slows the potion expiry timer, 0.5% per 1% of excess adr, max 50% | **+1.0 s** per hit | **potion duration** |
| Dumplings (Runeword 6) | food duration/regen +100% | +100% | **+400%** | regen |
| Replenishment (Runeword 1) | after a sign cast, spends 1 adr to empower the next hit | same, plus an Axii branch | as 1.32 | uses adr |
| Invigoration (Runeword 4) | overheal turns into damage, up to +50% | reworked: +2% weapon damage per 1% excess vitality, up to +50% | as 1.32 | — |
| **Levity / Balance / Heft** (Glyphwords 2/3/4) | change armor class (see section 1) | **stamina cost ±20%** (melee vs signs; Heft +20% damage) | as 1.32 | **stamina cost** |
| Protection (Glyphword 17) | Quen on combat start (100% chance) | Quen on combat start, +100% sign power | as 1.32 | — |
| Depletion (Glyphword 6) | Aard drains 50% enemy stamina | 50% | **100%** | — |
| Ignition (Glyphword 12) | 25% chance to spread burning | 50% | **100%** | — |
| Usurpation (Glyphword 10) | Axii transfers on death | **Replaced:** each puppet gives +25% AP and SI (max 4 stacks) | as 1.32 | AP, SI |
| Beguilement (Glyphword 14) | Axii +2 s per hit | **Replaced:** each confused enemy gives +25% crit chance and crit damage (max 4) | as 1.32 | crit |

Elation, Rejuvenation and Prolongation were strongly buffed in 5.x (×4 to ×10 adr, ×4 stamina, ×2 potion time). The port takes legacy's numbers and mechanics for all six words 5.x raised (the owner's DE2, [ENCH](../ench.md#area-decisions), 2026-10-19). 5.x also added the dying enemy's weapon damage ×5 to Eruption's (Glyphword 20) explosion, which the port still has ([ENCH](../ench.md) F2).

## 6. Trophies (worn on the horse; the abilities apply to Geralt)

**1.32 and 5.x: no combat stats** (identical data: XP, money, herb and dismember bonuses only). **GM gives every trophy an individual bonus.** The relevant ones (data values):

| Trophy (GM) | Bonus | Stat | Availability |
|---|---|---|---|
| Wyvern (mq1051) | **stamina regen +5%** | stamina | early (No Man's Land, lvl ~7) |
| White Basilisk | **stamina regen +10%** | stamina | BaW |
| Grave Hag | **adr gain +10%** (changelist says +5%) | adr | early (lvl ~10) |
| Arachas | **max toxicity +40** | toxicity | mid (lvl ~33) |
| Water Hag | **potion duration +20%** (potions only in GM) | potion duration | Skellige, lvl ~18 |
| Noonwraith (mh308) | vitality regen +5 / +5 in combat | regen | Novigrad, lvl ~16 |
| Cave Troll | +500 vitality | vitality | DLC |
| Gryphon / Gryphon sq108 | AP +5% / +15% | AP | prologue / mid |
| Noonwraith, Leshy (Skellige) | SI +5% / +10% | SI | early / mid |
| Sign-specific | Cockatrice Aard +10, Nightwraith Yrden +10, Fogling/Katakan Quen +10/+15, Gryphon mh301/Dracolizard Igni +15/+20, Succubus/Garkain Axii +10/+20 (%) | SI | various |
| Ekimmara | crit chance **+10%** (changelist says +15%) | crit | mid |
| Czart / Fiend | crit damage +25% / +35% | crit | mid |
| Dao / Leshy mh302 / Sharley Matriarch | armor reduction +40 / +10% / +60 | damage | mid / BaW |
| Wild Hunt Minion | frost resistance **+50%** (changelist says 25%) | defence | Novigrad |

Only one trophy can be worn. In GM the trophy slot is effectively a "pick one stat" slot: stamina regen (White Basilisk), adr (Grave Hag), toxicity (Arachas), potion duration (Water Hag), or AP/SI/crit.

## 7. Notable unique items and relics

| Item | 1.32 vanilla | GM | 5.x | Stat |
|---|---|---|---|---|
| Relic armor (Light 04r, Medium 05r, Heavy 04r/05r) | Light 04r focus_gain 4 to 6% | all four: focus_gain 4 to 8% (light/medium), 5 to 10% (heavy) | as 1.32 | adr |
| Crafted generic armor (Light 04, Pants 04, Heavy 01/03 crafted) | — | focus_gain 4 to 6% each | — | adr |
| Relic swords (Wolf, Vynbleidd, Bloedaedd, Caerme, Azurewrath, Weeper, Ultimatum, Moonblade, Breath of the North, Hjalmar's) | none on these | **focus_gain 5 to 15%** each | none | adr |
| DLC10 Remorse | focus_gain 15% | 10 to 15% | 15% | adr |
| BaW vampire swords (q702/q704) | — | focus_gain 10 to 20% | — | adr |
| Crossbows (Lynx/Bear school, Crossbow 6/7, q206, Toussaint 2) | focus_gain 1 to 2% | 2% | as 1.32 | adr (with Cold Blood) |
| Boots 012 | focus_gain 5 to 6% | 5% | as 1.32 | adr |
| Random-quality modifiers `MA_AdrenalineGain` / `MA_StaminaRegeneration` | 1 to 4% / 1% | **3 to 5% / 0% (regen roll disabled)** | as 1.32 | adr / stamina |
| 5.x free DLC armor | — | — | Scarlet Crest set: focus_gain 3 to 7%/pc and Quen +5 to 15%. White Tiger pants focus_gain 5%. Dol Blathanna gloves Igni and Aard +5%. Fire Horse saddle: horse stamina +90. | adr, SI |
| Iris (HoS), Aerondight (BaW) | vanilla mechanics | reworked (changelist "Special swords") | vanilla | damage, not the target stats |

**Stamina regen from gear is rare everywhere.**
- Vanilla: Griffin 6 pc (inside Yrden), Placation, the light-armor regen modifier and the 1% item roll.
- GM: Kaer Morhen set, two trophies, Placation, and the regen option if enabled.
- No source modifies max toxicity apart from Manticore, Viper armor in GM, the GM Arachas trophy and the Metabolic Control perk.

## 8. Index by stat

| Stat | 1.32 vanilla | GM | 5.x |
|---|---|---|---|
| **Adr gain** | Bear items (~+90%), Wolven/Manticore items, Perun, relic armor, Remorse, Elation (small), quality rolls | Bear items (~+105 to 126%), Bear perk (+0.1/hit at 4 heavy), Bear 3 pc (adr when hit), Feline 6 pc (×2 on crit), Perun, relic swords and armor, Grave Hag trophy, Elation 0.25, quality rolls | Bear/Wolven/Netflix/Scarlet Crest items, Perun, **Elation 1.0 per kill** |
| **Adr retention / use** | Placation (spends it) | Bear 3 pc offsets the drain; Placation; Prolongation spends excess | Wolven 6 pc (bleed stacks per adr), Placation |
| **Stamina regen** | Griffin 6 pc (+5% in Yrden), light-armor modifier (+25%), Placation +25%, quality roll | Kaer Morhen (+1 to 5/s), Wyvern/White Basilisk trophies (+5/+10%), Placation +5%, regen option | as 1.32 |
| **Stamina cost** | Griffin 3 pc (free sign), Rejuvenation 25% per kill | armor class (−30%/+50%), Griffin 3 pc (−30% all actions for 2.5 s), Bear 6 pc (refund), Levity/Balance/Heft (±20%), Griffin perk (−5%/pc signs) | Griffin 3 pc, **Rejuvenation 100% per kill** |
| **Max toxicity** | Manticore +30 | Manticore +25, Viper armor +20, Arachas trophy +40 | Manticore +20 |
| **Toxicity decay** | Placation −2/s | Placation −5/s, generic medium 4-pc −0.25/s | Placation −2/s |
| **Potion duration** | Prolongation +0.5 s/hit | Manticore +25%, Water Hag +20% (potions only), Prolongation (excess adr) | **Netflix +42%**, Prolongation +1 s/hit (also scales bombs, see top) |
| **Decoction duration** | Prolongation (acts on all potion buffs) | nothing from gear (`potion_duration` excludes decoctions) | Netflix, Prolongation |
| AP | Feline items and 3 pc (fast), Elemental rune | Feline 3 pc (up to +60%), Bear 3 pc (+21%/adr), GM Bear swords +20 to 40%, Gryphon trophies, Usurpation | as 1.32 |
| SI | Griffin items, Griffin 6 pc +100% in Yrden, glyphs, Veles | Griffin 6 pc +50%, glyphs, Veles, sign trophies, Usurpation | as 1.32 |
| Crit | Feline/Bear items | Feline items (+35%/pc), Wolven 6 pc (per oil), Ekimmara/Czart/Fiend trophies, Beguilement | as 1.32 |
| Bomb damage | Manticore 3 pc (crit) | Manticore 3 pc (+30% crit chance and +60% crit damage at 6) | Manticore 3 pc; `potion_duration` sources |
| Crossbow | crossbow items | crossbow items; Cold Blood | as 1.32 |
| Vitality / regen | Mending, Tesham Mutna | Mending 3 to 5, Pierog/Tvarog +5, Noonwraith mh308, Cave Troll, Tesham Mutna 0.5%/pc on hit, Rejuvenation 15% | as 1.32 |

## 9. Where GM moved or replaced effects, and where 5.x changed them

**GM vs 1.32:**
- **Every set bonus was rebuilt:**
  - Feline: fast-chain AP / double adr on crit.
  - Griffin: stamina-cost window / Yrden resistances; the Yrden regen was removed.
  - Bear: adr when hit plus AP per adr / strong-attack refund. Quen is dropped from both.
  - Wolven: oil potency / 3 oils plus crit.
  - Manticore 3 pc: bomb crit stats per piece, plus no throw delay (moved from Wolven 6).
  - Tesham Mutna: heals on hit instead of on kill.
  - New: Kaer Morhen, Viper, and the generic light/medium/heavy sets.
- **Minor bonuses from every tier** (vanilla: grandmaster only).
- **Armor class affects stamina costs** (vanilla: regen only); regen penalties are off by default.
- **Glyphwords 2/3/4 no longer change armor class**; they are ±20% stamina-cost trades.
- Runewords: Elation fixed at 0.25; Placation stronger toxicity decay but weak regen; Rejuvenation turned into a vitality heal; Prolongation tied to excess adr.
- Trophies: all got combat stats. Potion duration and toxicity were added to Manticore, toxicity to Viper. Focus gain was added to relic swords and more armor.
- Runes and glyphs: flattened to 3/4/5%.

**5.x vs 1.32:**
- **Wolven bonuses replaced by bleed mechanics.**
- Manticore 3 pc now has the no-delay bombs.
- Manticore toxicity cut from 30 to 20.
- **New Netflix set (potion duration)**.
- Runewords buffed: Elation ×4 to ×10, Rejuvenation ×4, Prolongation ×2, Dumplings ×4, Depletion and Ignition ×2 to ×4.
- `potion_duration` also scales bomb damage.
- New free-DLC armor with focus_gain.
- The other set bonuses, runes, glyphs, trophies and armor-class rules are unchanged.

**Data vs changelist mismatches in GM:**
- Grave Hag trophy: 0.10 in data vs "+5%" in the changelist.
- Ekimmara: 0.10 vs 15%.
- Wild Hunt Minion: 0.50 vs 25%.
- Manticore `potion_duration` and Viper armor toxicity are not in the changelist.

## 10. Build cornerstones in legacy GM

Each archetype is defined by an armor class (stamina cost rule plus school perk), a set's 3-pc bonus (all tiers), and later the grandmaster 6-pc bonus. Trophy and runeword or glyphword choices tune the hard stats.

1. **Feline: light, fast melee, crits.**
   - Gear: light armor (−30% melee stamina) plus Cat School Techniques (+20% crit chance and +80% crit damage at 4 pc). Feline 3 pc stacks AP over a fast chain (up to +60%) and pays out on a strong finisher. Feline 6 pc doubles adr on crits.
   - Cornerstones: Ekimmara, Czart or Fiend trophy; Beguilement; Levity glyphword (another −20% melee cost); Perun or Elemental runes.
   - Perk interplay:
     - Adrenaline Burst: −10% melee cost and +5% adr gain per point. Together with light armor and Levity this makes melee nearly free at high adr.
     - Battle Frenzy: +10% crit per point.
     - Attack is the Best Defense: crits and counters restore 5 stamina, kills 15. It loves high crit.
   - The weak point is defence (light resistances), so dodge and the light 4-pc +30° angle (only with generic light armor, not Feline) matter.
2. **Ursine: heavy, adrenaline, strong attacks.**
   - Gear: heavy armor (+50% melee and sign cost) plus Bear School Techniques (+30% vitality, **+0.1 adr per hit** at 4 pc). Bear items (~+105 to 126% adr gain). Bear 3 pc: adr when hit (offsets GM's hit drain) and **+21% AP per adr point** at 6 pc. Bear 6 pc: strong attacks refund a third of their cost.
   - This is GM's adrenaline engine: points come fast and stay.
   - Cornerstones: Heft (+20% damage for +20% cost), Perun, Grave Hag trophy, Elation, or Placation (turns maxed adr into regen and toxicity decay).
   - Perk interplay:
     - Adrenaline Burst is key: it offsets the heavy +50% melee cost (−30% at 3 pts).
     - Battle Frenzy.
     - Rage Management / Focus: spending adr on signs conflicts with the Bear AP-per-adr bonus.
     - Metabolism Boost: spends adr on potion toxicity.
     - Attack is the Best Defense: stamina sustain for strong attacks.
3. **Griffin: medium, signs.**
   - Gear: medium armor (neutral melee, no sign penalty) plus Griffin School Techniques (+20% SI, −20% sign cost at 4 pc). Griffin 3 pc: a cast discounts the stamina of all actions by 30% for 2.5 s, a hybrid sign-then-strike rhythm. Griffin 6 pc: Yrden +40%, inside it SI +50% and +15% resistances.
   - Cornerstones: sign glyphs, Veles runes, Balance glyphword (signs −20%), sign trophies (Dracolizard, Garkain, Katakan), Leshy/Noonwraith SI trophies, Protection, Usurpation.
   - Perk interplay:
     - Focus: +15% SI per adr point, and signs generate adr.
     - Rage Management: signs paid with adr; Flood of Anger.
     - Adrenaline sources (Perun, Grave Hag) feed Focus. Bear-style adr gear helps a sign build in GM through Focus.
     - Kaer Morhen (medium, early) is the natural pre-Griffin set for stamina.
4. **Manticore: medium, alchemy and bombs (BaW, late).**
   - Gear: medium armor. +25 max toxicity, +25% potion duration (potions only), bomb crits at +30% chance / +60% damage at 6 pc with no throw delay, and +1 charge on all alchemy items.
   - Cornerstones: Arachas trophy (+40 toxicity) or Water Hag (+20% potion time), Placation (−5 toxicity/s), Prolongation (excess adr extends potions), Viper armor (+20 toxicity, poison immunity) as the HoS predecessor, the generic medium 4-pc (toxicity decay).
   - Perk interplay:
     - Metabolic Control: +40 toxicity.
     - Metabolism Boost: −33% potion toxicity per adr point. This is the main adr sink for alchemists.
     - Advanced Pyrotechnics: +0.1 adr per bomb hit.
     - Heavy Artillery and Efficiency for bombs.
     - Cold Blood and Trick Shot for a ranged secondary (crossbow adr per bolt).
5. **Wolven: medium, oils, hybrid.**
   - Gear: 3 pc boosts oil effects by 16.7% per piece (×2 at 6). 6 pc: 3 oils, each +5% crit chance and +10% crit damage. Items give a mix of focus_gain, AP and SI.
   - It is the "monster-specific" hybrid.
   - Cornerstones: Fixative (oils never wear off at level 3), Hunter Instinct (crit damage per adr), crit trophies.
   - Perk interplay: Battle Frenzy and Adrenaline Burst as for Feline. The focus_gain on items gives moderate adr for Hunter Instinct.
6. **Kaer Morhen: medium, early game (GM only).**
   - +1 to 5/s stamina regen against groups. It bridges until a school set is available; on regen it competes with the Wyvern trophy (+5%).

**Crossbow side builds (Cold Blood, Trick Shot):** no set supports crossbows in any version. The scaling comes from crossbow focus_gain (2%), headshots, and adr from bolts via Cold Blood. Cat Eyes (Mutation) is the real multiplier.

## 11. Points worth checking for skill balancing

- **5.x runeword data:** decide whether to keep 5.x's Elation (1 adr per kill), Rejuvenation (100% stamina) and Prolongation (+1 s/hit), or restore GM's values. Kept as-is, they undercut GM's adrenaline and stamina economy.
- **The `potion_duration` → bomb damage coupling in 5.x:** GM sources (Water Hag, Manticore) would inflate bombs.
- **5.x Wolven:** its 3/6-pc bonuses depend on bleeding stacks and adr, which GM's skills and DoT rework change.
- **Netflix set (5.x):** it has no GM counterpart (+42% potion duration including decoctions); decided: DA3, ported with ARM-15 (every tier counts, potions only, +0.5 sign intensity against enemies inside Yrden at 6 pieces; [arm.md](../arm.md#arm-15-5xs-new-armor)).
- **Set-bonus eligibility:** GM grants minor bonuses from every tier; 5.x regular data tags only grandmaster, Manticore, Tesham Mutna and Netflix as `SetBonusPiece`. A port must re-tag the tiers or change the counting.
- **1.32 Wolven 6 pc:** the vanilla text is unknown; the code only gives bombs without delay. Only matters for "legacy behaviour" questions.
