# Sweep C: unattributed `files/` units of Ghost Mode (2026-11-02)

Batch: every unattributed unit under `files/` whose origin is `GM`. On master `d6062e97` there are **68** such units (coverage.md's list less the ones attributed since it was generated, such as `Body palms cut`). All 68 are attributed now. Unattributed units in the whole map: 332 before, **264** after (`change_units.py`).

How it was checked: offline only. `bindiff.py master legacy-GM` and `cr2w_dump.py --rev` for the binary files; `git diff`/`git show` on `master` (1.32), `legacy-GM`, `vanilla-5.x`; 5.x-GM read at `b3ec3609`. For each binary file, 5.x-GM's blob was compared with `vanilla-5.x`'s: all 26 are 5.x's file, unchanged. Nothing was run in game.

## Units

| Unit(s) | Cat. | Evidence | Feature | In play |
|---|---|---|---|---|
| 21 golem, earth elemental (Dao) and Ifryt entities: `characters/npc_entities/monsters/elemental_dao_lvl1`, `_lvl2`, `_mh`, `golem_lvl1`, `_lvl1_boss`, `_lvl2`, `_lvl2__ifryt`, `_lvl3`; `gameplay/templates/monsters/elemental_dao_lvl1a`, `_lvl2a`, `golem_lvl1`; quests `mq4006_dao`, `mq4006_ifryt`, `q104_dao`, `q201_dao`, `q210_lab_golem`, `_lab_golem_static`, `_vault_golem`, `q310_elemental`, `q502_dao`, `sq302_ifryt` | 2 | The only real edit: the template's own `CAttackRangeParam`, range `wide_arc` (a 360° cone), `rangeMax`. Daos 2 → 3; golems, Ifryts, `q104_dao` and `q310_elemental` 4 → 3 (1.32 = 5.x in all 21; the included `elemental_base` keeps 4 in every game). Changelist line 136: "Fixed different AoE radius for the same AoE attack for different Dao instances." 5.x-GM ships 5.x's files. `gen_ai_ent.py`'s `PROPS` have no `rangeMax`. | AI-14 | Legacy gives every golem and elemental the same 3 m radius for its all-round slam: Daos reach 1 m further, golems and Ifryts 1 m less. The port keeps 5.x's 2 m and 4 m. |
| `monster_bies_combat.w2beh`, `monster_bies_constraints.w2beh`, `enemy_shortsword_normal.w2ent`, `mq1005_monster.w2ent`, `sq102_farm_headhunter_1h_sword_t1.w2ent` | 7 | `bindiff.py --keep-noise`: CR2W 163 → 162, and in `monster_bies_combat` the graph buffer's name indices re-serialized. Already listed as re-saves in binary-files.md. | MISC | None. |
| `bob/.../monster_bob_base_abl.xml` `mon_EP2_clubDwarfs#2` | 1 | 1.32 and 5.x define the ability twice (`:2419` with −0.3 attack power, `:2472` with −0.5). Legacy keeps one definition (`:1886`). 5.x-GM: one `replace` entry (`gm_ai_monsters.xml:3033`), which `GMTest_ai03` reads (`gmTestsAiData.ws:243`). | AI-03 | The Blood and Wine dwarves' stats are legacy's. |
| `bob/.../items{,_plus}/bob_item_extensions.xml` (7 hairstyles × 2) | 2 | Legacy comments out every Geralt hair extension for `Lynx Armor 4` (`c_08_mg__witcher_lx` hood hair, plus the `category="mask"` variants), along with the armor's mask variant (`def_item_crafting_armor.xml:233`). 5.x-GM carries legacy's maskless look (`gm_arm_items.xml:5777`, ARM audit F4d) but ships 5.x's extensions file. | ARM-01 | Cosmetic. With the grandmaster Feline armor, legacy shows Geralt's normal hairstyle. The port probably still swaps in the hood hair under a hoodless look (not seen). |
| `gameplay/items{,_plus}/def_item_hairs.xml` `Preview Hair`, `Half With Tail Hairstyle`, `Long Loose Hairstyle` (6); `bob/.../def_item_hairs.xml` `Fancy Bowl` (2) | 2 | (a) Legacy drops `q108 Medium armor 10` (Yoana's reward armor, which it made heavy) from the inquisitor (`c_0x_mg__witcher_inq`) and bowl (`c_17_mg__witcher_bowl`) hair variants. It therefore gets the default hair, as `Heavy armor 03` (same look) does in 1.32 and 5.x. 5.x-GM ships 5.x's files. (b) Legacy adds Bear Armor 4 and the Wolven armors to the collar variants; 5.x made the same fix itself, with one difference: it puts `Wolf Armor` and `Wolf Armor 1` in `c_01_mg__witcher_br`, where legacy uses `br02`. | ARM-01 | Cosmetic. (a) Yoana's armor, which now looks like heavy plate, keeps the inquisitor-collar or bowl hair cut in the port. (b) is in 5.x already. |
| `gameplay/items{,_plus}/_armor_stand_variants_extension.xml` `q108 Medium armor 10` | 1 | Legacy's heavy lvl3 armor-stand look, given whole in 5.x-GM's `gm_arm_item_extensions.xml` (ARM audit F4b). | ARM-01 | Yoana's armor on a stand shows its heavy look. |
| `gameplay/items_plus/def_item_armor.xml` `NGP DLC Compatibility Chest Armor Mod`, `NGP DLC Compatibility Armor Mod` | 2 | Legacy deletes both abilities (−25 armor on chests, −10 on the other pieces). 5.x's `NewGamePlusAdjustDLCItem` (`playerWitcher.ws:1351`) still adds them, as legacy's code does (where they are now undefined). 5.x-GM has no override. SWD-04 already gives the swords' counterpart (`NGP Wolf Steel/Silver Sword Mod`) empty (`gm_swd_items.xml:900`). | ARM-01 | NG+ only. In legacy, NG+ Temerian, Nilfgaardian, Wolven and Skellige DLC armor keeps its full armor value; the port takes 25 off a chest and 10 off each other piece. |
| `globals/resources/gameplay.xml` `<file>` (base and Hearts of Stone) | 6 | Each adds only a console spawn alias: `succubus_mh` (base game) and `golem37` (Hearts of Stone). | AI-06 | None. AI-06 already records the deviation (not ported, owner-confirmed). |
| `ep1/.../items{,_plus}/def_item_weapons.xml` `NPC Long Steel Sword _Stats` | 1 | Hearts of Stone's duplicate, 200 → 250 slashing, the same as the base entry. One `replace` in `gm_ai_weapons.xml:131`, read as 250 by `GMTest_ai03` (ai.md AI-A audit). | AI-05 | — |
| `ep1/...` `Caretaker Shovel`, `caretaker_body` (× 2) | 1 | Both name legacy's own `Caretaker Shovel _Stats` in place of the shared `Shovel _Stats`. The items are given whole in `gm_ai_weapons.xml:1115, 1161` (AI-A audit F2). | AI-19 | The Caretaker's shovel deals legacy's damage. |
| `ep1/...` `NPC Burning Rose Sword` (× 2) | 7 | Legacy adds `bound_items` `NPC Scabbard 1`, an item defined nowhere, even in legacy. 5.x (= 1.32) has no scabbard on this sword. | AI-05 | None; AI-05's scabbard deviation. |
| `abilities{,_plus}/basic_attacks.xml` `attack_light` | 1 | `focus_gain` 0.05 commented out. 5.x-GM `gm_adrenaline.xml:8` sets it 0 (both folders). | SKL-07 | — |
| `abilities{,_plus}/basic_attacks.xml` `attack_speed_based` | 2 | `focus_gain` 0.025 commented out; `gm_adrenaline.xml` does not touch this ability. The only user is the horse's collision attack (`horseComponent.ws:876`); the player's own speed-based hits return early (`actor.ws:5068`). | SKL-07 | Tiny. In the port, trampling an enemy on horseback may give 0.1025 adrenaline instead of 0.1 (only if that hit counts as melee; not checked). |
| `abilities_plus/opp_base_abl.xml` `_combatFollowerHardcoreV` | 2 | NG+ only. Legacy 2.5 = its regular value (1.32 and 5.x NG+: 6.0). 5.x-GM has no entry. | AI-04 | NG+ only. On Death March, followers have ×2.5 Vitality in legacy and ×6 in the port. |

## By category

| Category | Units |
|---|---|
| 1 Existing feature, ported | **11**: AI-03 1 (`mon_EP2_clubDwarfs#2`), AI-05 2 (`NPC Long Steel Sword _Stats`), AI-19 4 (the Caretaker's items), ARM-01 2 (the armor-stand look), SKL-07 2 (`attack_light`) |
| 2 Existing feature, not ported | **48**: AI-14 21 (slam radius), ARM-01 24 (Feline hair extensions 14, hair items 8, NG+ armor mods 2), SKL-07 2 (`attack_speed_based`), AI-04 1 (`_combatFollowerHardcoreV`) |
| 6 Debug or dev only | **2**: AI-06 (spawn aliases) |
| 7 No effect | **7**: MISC 5 (re-saves), AI-05 2 (undefined scabbard) |
| 3, 4, 5, 8 | 0 |

Total 68. No unit is a dependency (all are origin `GM`), and none needs a new feature ID.

## Gaps (all in existing features)

1. **AI-14: the golems' and elementals' slam radius.** Legacy gives the all-round slam (`wide_arc`) of every golem, earth elemental (Dao) and Ifryt template the same 3 m radius (changelist 136). In 5.x it is 2 m for Daos and 4 m for golems and Ifryts. 22 files: these 21, plus `quests/generic_quests/novigrad/quest_files/mh306_dao/characters/mh306_dao.w2ent`, which is attributed to AI-02 and has the same 2 → 3 edit, not ported either. Port form: add `("CConeAttackRange", "rangeMax"): "AI-14"` to `gen_ai_ent.py`'s `PROPS_LATER` and AI-14 to its `FEATURES`. It diffs object by object, so only the `wide_arc` object legacy edited is written; the included base's copy, with the same class, stays 5.x's. Whether 5.x's reworked golem and elemental trees still use the `wide_arc` range: unverified.
2. **ARM-01: NG+ DLC armor penalty.** In NG+, legacy's Temerian, Nilfgaardian, Wolven and Skellige DLC armor keeps its full armor. In the port each chest loses 25 and each other piece 10. Port form: give both abilities empty in `items_plus/` (`on_conflict="replace"`, no nodes), the same way SWD-04 handles the Wolven swords. NG+ only, untested by policy.
3. **AI-04: followers' NG+ Death March health.** Legacy: ×2.5 Vitality, as in the regular game. Port: 5.x's ×6. This is the same pattern as AI-03 audit F3's NG+-only fixes. With the new AI-04 row, `gen_ai.py`'s `plus_units` will emit the ability into `gm_ai_ngplus.xml`. Until 5.x-GM is regenerated, `gen_ai.py --check` reports it out of date. NG+ only.
4. **SKL-07: horse trample adrenaline.** `attack_speed_based`'s `focus_gain` 0.025 is still there. Port form: one node in `gm_adrenaline.xml` (both folders). Possibly inert.
5. **ARM-01, cosmetic: hair with legacy's looks.** (a) The grandmaster Feline armor's hair extensions (Blood and Wine), which legacy removed together with the mask look the port already carries. (b) Yoana's armor taken out of the inquisitor and bowl hair variants. Neither was seen in game.

## Owner questions

1. **The slam radius (gap 1):** port legacy's 3 m to all 22 files? Options: (a) port as legacy, both directions; (b) port only the Dao fix (2 → 3, the changelist's stated bug) and keep 5.x's 4 m for golems and Ifryts; (c) keep 5.x's. Recommendation: (a). It is a listed bugfix and costs one line in `gen_ai_ent.py`. Check one golem and one Dao in game, in each tree.
2. **The cosmetic hair entries (gap 5):** port, or record as a deviation alongside ARM-01's other cosmetic display changes? Options: (a) port both through Ghost Mode's DLC (hair `item` entries given whole with `replace`; the extensions with an empty `replace`, if the engine accepts an empty `item_extension`, which is untested); (b) record a deviation. Recommendation: (a) for Yoana's hair, because the owner chose legacy's look for that armor (F4b). For the Feline hair extensions, look in game first: if 5.x's extensions look wrong with the maskless armor, port; if not, record a deviation.
3. Gaps 2 to 4 follow existing rules (NG+ carried over; SKL-07's data). Recommendation: port them in a small fix round, without new decisions.

## Outside the batch

- `mh306_dao.w2ent` (AI-02) has the same unported `wide_arc` edit (gap 1).
- `elemental_dao_lvl3__ice.w2ent` (AI-06, LOOT-06) also differs from 1.32 in its embedded copy of `monster_golem_logic.w2behtree` (two `BTTaskAdditiveHitListenerDef` flags, a look-at event). This is probably the cached embedded tree from the W3Edit re-save. Not checked further.
- coverage.md on master is stale. It says 335 unattributed, while a fresh run before this sweep gives 332; `Body palms cut`, for example, is already attributed.
- Suggestion for binary-files.md: its re-save list (six files) could note the cause of the `monster_bies_combat.w2beh` buffer difference (renumbered name indices).
