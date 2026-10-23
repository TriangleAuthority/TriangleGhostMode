# Ledger: potions, decoctions, toxicity (legacy vanilla 1.32 | legacy Ghost Mode 4.1 | vanilla 5.x)

**Status of everything in this file: from data/code, not tested in game.** Sources: `git show` of
`4f7041e5` (legacy vanilla 1.32), `legacy-GM`, `vanilla-5.x` for `gameplay/items/def_item_alchemy_potion.xml`,
`def_item_alchemy_mutagens.xml`, `abilities/effects_potions.xml`, `effects_mutagens.xml`, `effects.xml`,
`geralt_skills.xml`, `def_loot_shops.xml`, `def_loot_containers.xml`, `def_loot_monsters.xml`,
`def_item_alchemy_recipes_*.xml`; scripts under `effects/effects/potion/`, `effects/effects/mutagens/`,
`effects/effects/drain/toxicity.ws`, `playerWitcher.ws`, `PlayerAbilityManager.ws`, `gameParams.ws` in the
three versions' scripts; `docs/legacy-FullChangelist.txt` 384–425, 680–835.
Only the regular-game files were read (`*_plus` = NG+ copies, ignored).

Conventions: "AP" attack power, "SI" sign intensity, "regen" vitality regeneration per second.
Tiers are written T1/T2/T3 (base/enhanced/superior). Durations are item base values in seconds,
before potion-duration bonuses. Toxicity is the value added on drinking; decoction toxicity is a
**toxicity offset** that locks part of the toxicity bar for the decoction's whole duration.

---

## 1. Tables

### 1a. Potions

Columns: tox = toxicity, dur = duration (s), ch = charges T1/T2/T3. Where all tiers share a value one number is given.

| Potion | Legacy vanilla 1.32 | Legacy GM | 5.x vanilla | Stats it scales |
|---|---|---|---|---|
| **Swallow** | tox 20; dur 20; ch 3/4/5; regen +40/65/80 (combat and non-combat); T3 regen not paused on hit | tox **15**; dur **30** (changelist says 60, see note A); +**20/35/50% bleeding resistance**, cures bleeding; White Raffard no longer cancels it | as 1.32 | vitality regen; (GM) bleeding res |
| **Thunderbolt** | tox 25; dur 30/60/90; AP **+30/30/35%**; T3 +100% crit chance in storms | tox **20**; dur 30/60/90 (changelist 60/120/180, note A); AP **+25/30/35%** | as 1.32 | attack power; crit (T3, storms) |
| **Petri's Philtre** | tox 25; dur 30/60/90; SI **+15/20/25%** | tox **20**; dur 30/60/90 (changelist 60/120/180, note A); SI **+25/30/35%**; T3 sign effects last 1/3 longer (changelist) | as 1.32 | sign intensity |
| **Maribor Forest** | tox 20; dur 30/60/90; adrenaline gain **+15%** all tiers; T3 +1 adrenaline on drink | tox 20; dur 30/60/90 (changelist 60/120/180, note A); adrenaline gain **+15/20/25%**; T3 +1 adrenaline | as 1.32 | adrenaline gain |
| **Tawny Owl** | tox 20; dur 30/45/60; stamina regen +5/8/10% (mult); T3 does not expire at night | tox **15**; dur **60** all tiers; same values | as 1.32 | stamina regen |
| **Full Moon** | tox 25; dur 60/90/180; max vitality **+300/650/1000**; T3 heals by current toxicity on drink | tox **30**; dur **90/120/150**; vitality **+900/1300/1700** | as 1.32 | max vitality |
| **Black Blood** | tox 15; dur 30/45/60; returns **15/20/30%** of damage taken from vampires/necrophages; T3 bleeding aura vs them | tox **30**; dur **60/90/120**; returns **10/15/20%**; T2 adds stagger, T3 bleeding (changelist) | tox **25**; dur 30/45/60; 15/20/30% | returned damage (vs vampires, necrophages) |
| **Blizzard** | tox 25; dur 15/20/30; ch 2/3/4; after a kill, time scale 0.5/0.45/0.4 for 3 s | tox 25; dur **30** all tiers; time scale **0.5/0.35/0.25** (slower); finisher animation disabled while slowed | tox **20**; dur **8/10/12**; time scale **0.8/0.7/0.6** (weaker); **reworked: slow-mo runs continuously in combat** whenever there are targets or Geralt is attacked, not on kill | slow motion (defence/offence utility) |
| **Golden Oriole** | tox 20; dur 60/120/180; T1–T2 **100% poison resistance** + cure; T3 poison heals (absorb) | tox **15**; dur **60/90/120**; poison res **20/35/50%** + cure; T3 adds 5 s poison immunity | tox **25**; as 1.32 | poison resistance |
| **White Raffard's Decoction** (a potion despite the name) | tox 30; ch 2/2/3; heals **35/60/100%** max vitality; T3 3 s invulnerable; overrides (removes) Swallow | tox **25**; ch 2/2/**2**; same heal; no longer removes Swallow; cures bleeding | tox **25**; ch 2/2/3 | instant heal |
| **Cat** | tox 15; dur 60/120/180; night vision, highlight | tox **10**; dur **240/360/480**; T3 immunity to Hypnotized (changelist) | as 1.32 **+ crit chance +5/7/10%** | (5.x) crit chance; else utility |
| **Killer Whale** | tox 10; ch 3/6/10; breath/vision under water | tox 10; dur **180**; only T1 exists | tox **15** | utility |
| **White Honey** | removes potion effects and toxicity; ch 1/2/5 | ch **2/3/4** | as 1.32 | toxicity reset |
| **Pheromones** (bear/drowner/nekker) | tox 15; dur 90; ch 2 | tox **10**; dur **120**; bear and nekker restored and sold | as 1.32 | utility |
| **Pops' Antidote** (quest) | tox 25 | tox **10** | as 1.32 | quest |
| **Mutation Catalyst** (GM only) | — | tox 20; ch 3; activates GM's Life Leech mutation; counts as a potion | — | mutation trigger |
| **Reinald's Philtre** (5.x only, quest `mq1060`) | — | — | tox **50**; dur 360; ch 1; SI +15%, stamina regen +10% | sign intensity, stamina regen |

**Note A (GM durations):** the GM XML (what the game reads) gives Thunderbolt/Petri/Maribor 30/60/90 s and Swallow 30 s;
the changelist says 60/120/180 and 60. The other potions match the changelist exactly. No GM script doubles these durations
(`CalculatePotionDuration` only adds `potion_duration`). Either the changelist describes an older version or assumes
Prolonged Effects (+100%). Flag for the owner before porting values.

**Potion-wide mechanics**
- Legacy vanilla: drinking the same potion again replaces it. Passive `alchemy_potionduration` +5% potion and decoction duration per Alchemy point spent.
- GM: potions (not decoctions) **stack**: drinking again extends the duration; cannot drink during special sword attacks or channelled signs; the per-point passive is removed; decoctions never get potion-duration bonuses (`CalculatePotionDuration`: mutagen potions only get `mutagenSkillMod`, which GM sets to 0).
- 5.x: as 1.32, per-point passive lowered to **+2%** per Alchemy point; the Netflix ("Witcher" show) armour set adds +7% duration per piece.

### 1b. Mutagen decoctions

Common values: **Legacy vanilla** toxicity offset 70, duration 1800 s (30 min) except Basilisk (offset 40, 1800+3960 = 5760 s);
**GM** 70 for all including Basilisk, 1800 s for all, no potion-duration bonus;
**5.x** offset **50** (Basilisk 40, 5760 s), 1800 s. "Same" = same effect as the column to its left.

| # | Decoction (mutagen source) | Legacy vanilla 1.32 | Legacy GM | 5.x vanilla | Stats it scales (GM) |
|---|---|---|---|---|---|
| 1 | Katakan | +5% crit chance | **Reworked:** each non-crit sword hit +5% crit chance (max 25%); at max +50% crit damage; resets on crit and end of combat | +**10%** crit chance | crit chance, crit damage |
| 2 | Arachas | damage resistance up to +20%, scaled by unused carry capacity | **Replaced:** melee attackers get Acid: −1% damage resistance per hit (max −10%) | same as 1.32 | enemy resistance (debuff) |
| 3 | Cockatrice | +1 charge to every bomb and potion | same | same | bomb, potion charges |
| 4 | Archgriffin | heavy attacks spend 100% of current stamina and remove 5% of the enemy's current HP | **Changed:** all melee attacks cost +50% stamina; each hit removes 0.1% of enemy current HP per stamina point spent | same as 1.32 | damage (stamina-scaled) |
| 5 | Water Hag | +50% damage while at full vitality | **Replaced:** each melee hit +10% AP (max **+100%**); taking damage removes 0.5% per 1% HP lost; resets end of combat | same as 1.32 | attack power |
| 6 | Nightwraith | +50 max vitality per kill, for the decoction's duration | same | same | max vitality |
| 7 | Ekimmara | life leech 10% of damage dealt | same (data rewritten, same value) | same | vitality (leech) |
| 8 | Chort | immune to stagger, knockdown becomes stagger | same | same | CC immunity |
| 9 | Foglet | +25% SI when weather is not clear | **Replaced:** +10/17.5/25 base sign damage per equipped lesser/normal/greater **blue** mutagen | same as 1.32 | sign damage (flat) |
| 10 | Wyvern | +1% AP per melee hit, unlimited, reset when hit | **Replaced:** casting a sign +16.7% melee AP (max 50%), reset after dealing melee damage and end of combat (design doc says 10%; XML 0.167 × 3) | same as 1.32 | attack power (sign-melee alternation) |
| 11 | Doppler | +50% damage on attacks from behind | **Changed:** +50% crit damage on attacks from behind | same as 1.32 | crit damage |
| 12 | Troll | regen +100 out of combat, +20 in combat | same, plus +80 combat regen while stamina ≤ 33% | same as 1.32 | vitality regen |
| 13 | Noonwraith | stagger, knockdown, blind, confusion and similar effects on Geralt last only 0.5 s | **Replaced:** each kill +1 combat stamina regen per alive enemy nearby (max +10); resets end of combat | same as 1.32 | stamina regen |
| 14 | Succubus | in combat +1% AP every 2 s (max 30%) | **Replaced:** Axii Puppet allies deal +50% damage | same as 1.32 | (sign build) puppet damage |
| 15 | Alghoul | +50% adrenaline gain in combat until first damage taken | **Changed:** each melee hit +10% adrenaline gain (max 50%); damage taken removes 0.5% per 1% HP lost | same as 1.32 | adrenaline gain |
| 16 | Fiend | +20 carry weight | **Replaced:** no hit stagger from hits below 15% of max vitality | same as 1.32 | CC resistance |
| 17 | Forktail | +50% AP and SI once 3 of 5 action types used (counter, attack, sign, bomb, crossbow); cleared on next sign cast | **Replaced:** melee damage +10% SI (max 50%), reset on sign cast and end of combat | as 1.32, but light and heavy attacks count as separate types (easier to reach 3) | sign intensity |
| 18 | Grave Hag | +5 combat regen per kill, unlimited, for the duration | **Changed:** each kill +5 regen per alive enemy nearby (max +50, in and out of combat), resets end of combat | +**10** combat regen per kill | vitality regen |
| 19 | Wraith | a hit of ≥30% max vitality casts a free Quen | **Changed:** free Quen when attacked from behind; Quen power +50% when hostile specters are around | same as 1.32 | defence (Quen) |
| 20 | Elemental (D'ao) | burning/poison/bleeding DoT resistance grows 10%/s while affected | **Changed:** flat +50% resistance to bleeding, burning, poison and fire/poison damage | same as 1.32 | elemental, DoT resistance |
| 21 | Ekhidna (Lamia) | every stamina-costing action (not Whirl/Rend) heals 10% max vitality | **Changed:** heals 0.1% max vitality per stamina point spent, in combat only | same as 1.32 | vitality (stamina-driven heal) |
| 22 | Ancient Leshen | each sign cast in combat +2 stamina regen (flat), unlimited | **Replaced:** each sign cast +10% SI (max 50%); damage taken removes 0.5% per 1% HP lost | same as 1.32 | sign intensity |
| 23 | Basilisk | at dawn/dusk grants a random minor Place of Power buff (6 h game time); offset 40, ~96 min | **Replaced:** +4/8/16 regen per equipped lesser/normal/greater **green** mutagen; offset 70, 30 min | same as 1.32 | vitality regen |
| 24 | Werewolf | free sprint and jump out of combat | **Replaced:** at ≤20% vitality: +50% AP and SI, +5 stamina regen, +25% adrenaline gain; 10 s cooldown | as 1.32 **+50% stamina regen at night in clear weather** | AP, SI, stamina regen, adrenaline gain |
| 25 | Nekker Warrior | +50% AP for melee attacks on horseback | **Replaced:** −2.5/3.75/5% melee stamina cost per equipped lesser/normal/greater **red** mutagen | same as 1.32 | stamina cost |
| 26 | Leshen | melee attackers take 10 + 2% of their damage back | **Changed:** 25% returned | 10 + **10%** returned | returned damage |
| 27 | Griffin | each hit taken +1% to all resistances (max 25%) | **Replaced:** two hits within 1 s → immune to damage for 2 s | same as 1.32 | defence (immunity) |
| 28 | Reliever's | +10% AP vs specters, +15% resistances vs specters | **Changed:** damage to spectral-form enemies 10% → 60% of normal; damage from them −50% | same as 1.32 | specter fights only |

GM also: decoctions are not stackable (only potions are); `Synergy` (+50% mutagen bonus) concerns equipped mutagens, which
Foglet, Basilisk and Nekker Warrior read by count; whether Synergy multiplies those decoctions was not checked.

---

## 2. Effects GM moved, replaced or changed (flag: access timing)

Access-timing column uses section 3's rough classes (E early ≈ lvl 1–14, M mid ≈ 15–29, L late ≈ 30+).
"Moved" = the stat role now lives on a decoction whose mutagen comes from a different monster/region/level.

| Stat role | Legacy vanilla source | GM source | Timing change |
|---|---|---|---|
| Stamina regen (flat) | Ancient Leshen (Skellige sq204, M) | **Noonwraith** (Velen/Novigrad noonwraiths, E) | **earlier** in GM |
| CC protection (short CC) | Noonwraith (E) | Chort (unchanged, M) and **Fiend** (Skellige lvl ~29, M–L) | **later** (Noonwraith's role gone) |
| Carry weight | Fiend | removed | — |
| Sign intensity | Foglet (E, bad weather), Forktail (M, combo) | **Forktail** (melee→SI, M), **Ancient Leshen** (sign→SI, M); Foglet → flat sign damage per blue mutagen (E) | sign-power decoctions now mid; Foglet scales with mutagen grade |
| Attack power | Wyvern (E, per hit), Succubus (E–M, over time), Forktail (M), Nekker Warrior (mounted) | **Water Hag** (up to +100%, M), **Wyvern** (sign→AP 50%, E), **Werewolf** (low HP, E–M) | biggest AP decoction moved to Water Hag (Skellige/Velen greater hags) |
| Sign-build support | Succubus = AP | **Succubus** → Axii Puppet damage | AP role lost |
| Adrenaline gain | Alghoul (E–M) | Alghoul (same source, stacking) + Werewolf (+25%, low HP) | same source |
| Crit | Katakan (+5%, M–L) | Katakan (stacking 25% + crit dmg, same source); Doppler +50% crit dmg from behind (was +50% damage) | same source |
| Resistances | Griffin (+25% stacking, E–M), Arachas (encumbrance) | Griffin → 2 s immunity; Arachas → enemy debuff; **Elemental** flat 50% elemental/DoT (M) | role reshuffled |
| Vitality regen | Grave Hag (unlimited per kill, E), Troll | Grave Hag (capped, per enemy), Troll (+low-stamina bonus), **Basilisk** (per green mutagen) | Basilisk's shrine-buff role removed |
| Melee stamina cost | — | **Nekker Warrior** (per red mutagen, M, Skellige) | new role |
| Mobility | Werewolf (free sprint) | removed | Werewolf now berserk |
| Basilisk toxicity/duration | 40 / ~96 min | 70 / 30 min | decoction became much more expensive |

GM potion changes that move power: Thunderbolt T1 AP **lowered** (30→25%), Petri SI **raised** (15/20/25→25/30/35%),
Maribor adrenaline **raised** on T2/T3, Full Moon **tripled** at T1, Golden Oriole immunity → partial resistance,
Black Blood return **lowered** but duration doubled, Blizzard **stronger and longer**, most potion toxicities **lowered**
(15–20) while Black Blood and Full Moon **raised** (30). No potion effect was moved between potions.

**5.x vs 1.32 (vanilla changes the port meets):**
- Decoction offset 70 → **50**; Katakan crit 5 → 10%; Grave Hag +5 → +10 per kill; Leshen 2% → 10%;
  Werewolf adds night stamina regen; Forktail easier to trigger. No decoction effect moved.
- Blizzard reworked into a continuous, weaker, shorter in-combat slow-mo; Cat gains crit chance (new crit source on a 15-tox potion);
  Black Blood, Golden Oriole, Killer Whale toxicity up; Blizzard, White Raffard toxicity down; Reinald's Philtre added (quest).
- Overdose threshold 75% → 50% (section 4), which changes how many potions fit next to a decoction.

---

## 3. Access timing

### 3a. Potion formulas (shop and random-loot level gates; `[Ln]` = player level minimum)

- **Starting / prologue:** Swallow 1 (given at start in all three, `playerWitcher.ws`); Thunderbolt 1 via the alchemy tutorial (White Orchard).
- **Legacy vanilla:** T1 formulas at herbalists from L2–L10 (Maribor/Petri L2, Thunderbolt L3, Golden Oriole/Blizzard L5, Tawny Owl/Full Moon/Swallow 2/White Raffard L10, White Honey L15); T2 L2–L15 at shops, L10–L20 in random loot; T3 shops L2–L16 (Druid Herbalist, Master Alchemist), random loot ("_everywhere_recipes") L15–L30. Toussaint (EP2) alchemist/herbalist sell many T2/T3 (late game).
- **GM:** gates by item, from the data ([LOOT-03](../loot.md#loot-03-recipe-and-schematic-level-gates)): T1 mostly ungated (some L4), T2 L8–L12, T3 L16–L20 in shops and random loot (a few T2 and T3 ungated at the Druid Herbalist and Toussaint's herbalist); T1 recipes added to Druid Herbalist, Master Alchemist and the Toussaint alchemist; Swallow 1, Cat 1, White Honey 1, bear/nekker pheromones made purchasable; per changelist the Master Alchemist sells all recipes and rare ingredients after his quest.
- **5.x:** identical to 1.32 (no diff in the shop/container tables for these recipes).

Rough classes (GM): **early** Swallow, Thunderbolt, Petri, Maribor, Tawny Owl, Golden Oriole, White Raffard, Full Moon, Black Blood, Blizzard, Cat T1; **mid** all T2 (L8–12); **late-mid** all T3 (L16–20).

### 3b. Decoction formulas

All 28 formulas: sold by the Druid Herbalist (Skellige druids) and the Toussaint herbalist in all three versions, plus one or two regional shops
(Novigrad/Velen/Skellige herbalists, book or antique merchants, Oxenfurt herbalist), also granted by reading bestiary books
(`inventoryComponent.ws` book switch), and in random loot. Random-loot gate: **legacy vanilla and 5.x L1** for all;
**GM L5–L15**: L15 Archgriffin (4), Ekhidna (21), Ancient Leshen (22); L10 Katakan, Arachas, Ekimmara, Troll, Elemental, Basilisk, Leshen, Reliever's;
L5 Cockatrice, Chort, Doppler, Succubus, Fiend, Forktail, Werewolf, Nekker Warrior; ungated Water Hag, Nightwraith, Foglet, Wyvern, Noonwraith, Alghoul, Grave Hag, Wraith, Griffin.
In practice **the mutagen, not the formula, gates the decoction**.

### 3c. Decoction mutagen sources (from `def_loot_monsters.xml` + binary entities; levels from the GM changelist trophy list)

"10%" = generic monster loot chance; "always" = guaranteed (`chance=-1`). Regions: NML = Velen/No Man's Land, Nov = Novigrad/Oxenfurt, Sk = Skellige.

| # | Mutagen | Source | Rough timing |
|---|---|---|---|
| 1 | Katakan | Katakans 10%; contract `mh304` (Nov, lvl 26); coroner vampire quest | M–L |
| 2 | Arachas | Venomous arachas 10%; contract `mh102` (NML, lvl 33 per trophy list) | M (generic), L (contract) |
| 3 | Cockatrice | Cockatrices 10% (NML cockatrice contract lvl 8) | E |
| 4 | Archgriffin (Volcanic Gryphon) | Archgriffins 10%; contract `mh301` (Nov, lvl 35) | L |
| 5 | Water Hag | Greater water hags 10% (Sk trophy lvl 18) | M |
| 6 | Nightwraith | contract nightwraith always (NML, lvl 10), others 10% | E |
| 7 | Ekimmara | Ekimmaras 10% (NML contract lvl 22) | M |
| 8 | Chort | Chorts 10%; `mh107` (NML, lvl 20) | M |
| 9 | Foglet | Foglets 10%; `mh108` ancient foglet (NML, lvl 12) | E |
| 10 | Wyvern | Wyverns 10%; `mh105` royal wyvern (NML, lvl 7) | E |
| 11 | Doppler | `mh305` (Nov, lvl 13) only; GM: also Master Alchemist | E–M |
| 12 | Troll | Cave trolls 10%; DLC `mh201` cave troll | M |
| 13 | Noonwraith | Pesta (noonwraith contract) always; others 10–40% (noonwraiths lvl 2–16) | E |
| 14 | Succubus | Succubi 10%; `mh303` (Nov, lvl 15); `sq205` (Sk); GM: Master Alchemist | E–M |
| 15 | Alghoul | 5 lesser red mutagens + Alghoul bone marrow (alghouls 20–35%) | E–M |
| 16 | Fiend | Fiends 10% (Sk trophy lvl 29) | M–L |
| 17 | Forktail | Forktails 10%; `mh208` (Sk, lvl 28) | M |
| 18 | Grave Hag | Grave hags always (NML contract lvl 10) | E |
| 19 | Wraith | `mh207` (Sk, lvl 17); "Him" 10% | M |
| 20 | Elemental (D'ao) | D'aos 10%; `mh306` (Nov, lvl 24) | M |
| 21 | Ekhidna (Lamia) | Lamias 10%; `mh210` (Sk, lvl 19) | M |
| 22 | Ancient Leshen | Ancient leshens 10%; `sq204` (Sk, lvl ~22) | M |
| 23 | Basilisk | Basilisks always | M |
| 24 | Werewolf | Werewolves always (generic lycanthrope table) | E–M |
| 25 | Nekker Warrior | Nekker warriors 10%; `mh202` (Sk, lvl 16) | M |
| 26 | Leshen | Leshens 10%; `sq204`; Nov leshen contract lvl 25 | M |
| 27 | Griffin | Griffins 10%; `mh301` | E–M |
| 28 | Reliever's | 1 lesser red + green + blue mutagen (no named mutagen) | E (formula gated) |

The monster loot entries are the same in all three versions (no diff found for these names). Levels are contract levels from
the changelist trophy list and are approximate; region placement of generic monsters is from knowledge of the game, unverified.

---

## 4. The toxicity system

| | Legacy vanilla 1.32 | Legacy GM | 5.x vanilla |
|---|---|---|---|
| Base max toxicity | 100 | 100 | 100 |
| Overdose threshold (`TOXICITY_DAMAGE_THRESHOLD`) | **75%**, Heightened Tolerance `alchemy_s1` +5%/level (5 levels → 100%) | **75% fixed** (s1 repurposed to Refreshment) | **50.001%**, Heightened Tolerance +10%/level (3 levels → 80%) |
| Overdose damage | 0.5% max vitality/s (not in meditation) | same, through `GetToxicityDamage()` (× Euphoria mutation multiplier) | same |
| Base decay | 0.25/s (`ToxicityEffect.toxicityRegen`), **×2 out of combat** | 0.25/s **in and out of combat** (doubling removed) | 0.25/s, **×1.1 out of combat** |
| Decoction toxicity | offset 70 (Basilisk 40), locked for the duration, counts toward max and threshold (drink check `current + tox + offset > max`) | offset 70 all | offset **50** (Basilisk 40) |
| Overdose visuals | camera fx at fixed 50% | at the real threshold (GM fix) | at the real threshold |

Notes:
- GM changelist: in vanilla, decoctions did not trigger overdose damage and overdose visuals; GM fixed it. Whether 5.x still has this behaviour is unverified.
- With GM's 75% threshold one decoction (70) leaves 5 points before overdose at base max: decoctions need max-toxicity investment (Metabolic Control +40 → max 140, threshold 105) or Adaptation (−20% → 56).
- With 5.x's 50% threshold one decoction (50) sits exactly at the threshold; any potion on top overdoses unless max toxicity or the threshold is raised.

**Max toxicity sources:** Metabolic Control `perk_12` +30 (1.32, 5.x classic) / **+40** (GM); 5.x new tree `perk_33` +10;
Acquired Tolerance `alchemy_s18` (1.32: +1 per known formula of tier ≤ skill level; GM: +1 per formula, cap 50/level → 150; 5.x: +0.5 per formula);
GM Arachas trophy +40.

**Decay sources:** Fast Metabolism `alchemy_s15` (1.32 −1/s per level, 5 levels; GM −0.25/level → −1.25; 5.x −1/level);
GM Medium-armour set bonus −0.25/s; GM Placation runeword −5/s while adrenaline drains; GM Toxic Blood mutation halves decay.

**Skills that interact (SKL-13 to SKL-17 in `docs/features/skl.md`):**
- **SKL-13 Brewing** (potions only in GM): Refreshment `s1` +10% stamina/level per potion (GM; 5.x s1 is Heightened Tolerance); Restoration `s2` heal 5%/level (GM, 1.32) vs 10%/level (5.x); Expert Brewer `s3` −1 potion toxicity/level (GM; vanilla s3 Delayed Recovery: potions do not expire while toxicity above 90/80/70% in 1.32, 70/65/55% in 5.x); Prolonged Effects `s4` +20%/level potion duration (GM; vanilla s4 Side Effects: 20%/level (1.32) or 33%/level (5.x) chance of a random extra potion effect); 5.x new tree High Tolerance `s24` (≥80% toxicity: crit damage from toxicity, take 1.5× damage), Potent Sting `s26`.
- **SKL-16 Mutation:** Tissue Transmutation `s13` (data value +200 vitality in 1.32, +300 per decoction in 5.x, scaling not re-checked; GM +2 per offset point per level → +700 per 70-offset decoction at 5); Adaptation `s14` (GM −4%/level decoction toxicity; vanilla Adaptability +10%/level (1.32) or +33%/level (5.x) **decoction duration**); Acquired Tolerance `s18`; Synergy `s19`/`perk_43` +10%/level mutagen bonus.
- **SKL-17 Trial of the Grasses:** Frenzy `s16` (GM adds +25% AP/SI while overdosed); Endure Pain `s20` (vitality bonus while overdosed: its trigger moves with the threshold, 75% → 50% in 5.x); Fast Metabolism `s15`; Killing Spree `s17` (needs toxicity > 0 in GM).
- **SKL-18 perks:** Metabolism Boost `perk_13` (−33.4% potion toxicity per adrenaline point, adrenaline consumed; GM: potions only, not decoctions), Metabolic Control `perk_12`.

---

## 5. Build cornerstones in legacy GM, and what 5.x changes

| Build | GM cornerstones | What 5.x vanilla changes about them |
|---|---|---|
| **Adrenaline** | Maribor Forest (+15/20/25%, T3 +1 point), Alghoul (stacking +50%), Werewolf (+25% at low HP); Metabolism Boost turns adrenaline into cheap potions | Maribor +15% flat on all tiers; Alghoul flat +50% until hit; Werewolf has no adrenaline effect |
| **Melee / stamina** | Thunderbolt (+25–35% AP), Tawny Owl (stamina regen, 60 s), Water Hag (up to +100% AP), Noonwraith (+10 stamina regen), Nekker Warrior (−stamina cost), Katakan (crit build), Doppler (crit from behind), Archgriffin (stamina→damage), Troll/Ekhidna (sustain) | AP decoction roles differ: Water Hag only at full HP, Wyvern/Succubus give AP, Noonwraith is CC protection, Nekker Warrior mounted only; Katakan flat 10% crit; Cat gives crit; stamina regen decoction is Ancient Leshen (signs) or Werewolf (night) |
| **Signs** | Petri's Philtre (+25–35% SI), Forktail and Ancient Leshen (+50% SI each), Wyvern (sign→melee AP), Foglet (sign damage per blue mutagen), Succubus (puppet damage), Wraith (Quen), Werewolf (+50% SI low HP) | Petri only 15–25%; Foglet +25% SI in bad weather; Forktail +50% AP/SI combo; Ancient Leshen gives stamina regen per sign; Reinald's Philtre (quest) adds SI |
| **Bombs** | Cockatrice (+1 charge to bombs and potions); bomb damage itself comes only from skills/perks in GM | same Cockatrice; no 5.x decoction adds bomb damage |
| **Tank / sustain** | Full Moon (+900–1700 vitality), Swallow, White Raffard, Nightwraith, Grave Hag, Basilisk, Troll, Griffin (immunity), Chort/Fiend (stagger), Elemental, Leshen (25% return) | Full Moon +300–1000; Golden Oriole full poison immunity; Griffin stacking resistances; Leshen 10+10%; Grave Hag +10/kill uncapped |
| **Toxicity / overdose** | 75% threshold with Frenzy and Endure Pain; decoctions 70 offset need max toxicity | 50% threshold, 50 offset: overdose is the normal state with a decoction plus potions; High Tolerance rewards ≥80% |

Biggest porting risks for SKL balancing: (1) the threshold and offset numbers (section 4) decide how many potions a decoction leaves room for in each tree;
(2) the decoctions whose effect GM replaced change which monster (and when) gives a build its key buff (section 2), so moving them back or forward changes the power curve;
(3) the GM durations in note A are contradictory.
