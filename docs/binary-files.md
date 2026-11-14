# Ghost Mode's binary files

Ghost Mode ships 638 edited binary game resources, alongside its scripts and XML. The 4.1 release edits 12 more, the Blood and Wine tournament contestants (`sq701_tournament/characters/contestants/*.w2ent`): each only gains the `sq701_tournament_npcs` ability, which 4.1 defines in `monster_bob_base_abl.xml`. The analysis below covers the original 638. Almost all of them are enemy and NPC definitions. The rest are a few quests, shops, bestiary entries and one AI tree. The edits are data tweaks (levels, abilities, loot, monster type, weaknesses), not new behaviour.

Everything below comes from comparing each file in `legacy-GM` against the legacy vanilla file on `vanilla-1.32` with `tools/bindiff.py`, and from the original commit messages.

## What the files are

They are CR2W, the binary resource format of REDengine 3:

| Extension | Resource | Count | What Ghost Mode used them for |
|---|---|---|---|
| `.w2ent` | Entity template: an NPC, monster, projectile or object, with its level, abilities, loot, inventory, monster type, weaknesses, immunities and components | 618 | Enemy/NPC rebalancing |
| `.journal` | Journal entry (bestiary creature) | 8 | "Use against" item lists |
| `.w2scene` | Dialogue scene, including shop dialogues | 6 | Prices |
| `.w2phase` | Quest phase graph | 2 | Money requirements |
| `.w2beh` | Animation behaviour graph | 2 | None (re-save only) |
| `.w2behtree` | AI behaviour tree | 1 | Fiend (bies) AI |
| `.w2comm` | Community / spawn set | 1 | Spawn a Ghost Mode enemy template |

An entity template contains its components twice: once as editable objects, and again as a compiled copy inside `flatCompiledData`. It may also embed compiled copies of the templates it includes.

## How they were edited

Every Ghost Mode copy is saved as **CR2W version 162**, while the legacy game's files are version 163 (and 5.0's are 164). That matches **W3Edit** by Saracen, the community editor the original README names; it wrote version 162. Re-saving with it also regenerated some internal data, which shows up as noise when diffing (see below).

## What Ghost Mode changed

| Change | Files | Details and examples |
|---|---|---|
| **Levels** (`CNewNPC.level`) | ~270 | Mostly +1 to +5 (13→17, 11→16, 12→15, 6→7). Some quest NPCs were raised a lot (2→27, 0→30) so they scale like real enemies. Monster-hunt targets (`W3MonsterHuntNPC`) and quest rats (`W3Rat`) too. |
| **"Fake" level bonus** (`levelFakeAddon`) | 69 | Zeroed or removed, so displayed and real levels match. |
| **Loot** (`CR4LootParam`) | ~200 | The 90% `_monster_add__Mutagens_lesser` container was removed from **158 monsters** (lesser mutagens no longer drop from ordinary monsters). Blacksmiths and armorers got rune, glyph and schematic loot tables (`loot_include_smith_*_runes/schematics`, `loot_include_armor_*_glyphs/schematics`). Container counts adjusted. |
| **Abilities** (`CCharacterStatsParam`/`CCharacterStats`) | ~146 | Stat templates swapped (`ConDefault` removed 34×; `ConHumanoidMonster` added 27×, `ConAthletic` 10×). `Boss`, `MiniBoss`, `NewGamePlusFakeLevel`, `NPCDoNotGainNGPlusLevel` removed from some. `NPCDoNotGainBoost`/`NoAdaptBalance` added or removed. Quest-specific sets (`sq301_fistfighters`, `sq209_followers`, ...). `EtherealSkill_1`–`5` and `EtherealActive` on the Hearts of Stone Ethereal. |
| **Monster category** (`CMonsterParam.monsterCategory`, decides which oils, bombs and signs work) | 36 | Spiders Specter → Insectoid (13; commit "Spiders fix"). Ghostly humans (`q602_everc_*`, `q604_ethereal`, `th700_preacher_ghost`, ...) Human → Specter (13; "KoalaNalle's Ethereal fix"). Dopplers Human → Relic, succubi Human → Hybrid, `sq209` visions → Specter, a few others. |
| **Weaknesses** (`itemsUsedAgainstCreature`) | 20 | In creature data: Necrophage Oil → Insectoid Oil for spiders, plus a few more. In bestiary journals: Dimeritium → Silver Dust bomb for leshens, spriggans and some hunts; Axii/Yrden added for the djinn (commits "Dimeritium and Silver Dust bomb changes", "More d-bomb changes"). |
| **Inventories** (`CInventoryInitializerUniform`) | 15 | Wild Hunt sword tiers raised (1 → 3/4); lesser mutagens replaced by greater ones on some enemies; one boots swap. |
| **Immunities** (`CBuffImmunityParam`) | 5 | E.g. `q604_caretaker` immune to knockdown, heavy knockdown and bleeding; `sq701_gregoire` to acid and bleeding; `mh102_arachas` to poison instead of burning. |
| **Projectiles** (`DebuffProjectile`) | 5 | Blood and Wine projectiles (Dettlaff's swarm, sand coils, root lances): damage and whether they break Quen. |
| **Prices and quantities** (`.w2scene`, `.w2phase`) | 9 | Hearts of Stone enchanter prices 5,000/10,000/15,000 → 3,000/6,000/9,000; `mq6005` enchanter money requirement 5,000 → 3,000; `mq6003_taxes` 35,000 → 10,000; Vimme Vivaldi's loan repayment 130 → 390; the two `mh307` (Contract: The Apiarian Phantom) scenes' reward name `mh308_final` → `mh307_02_minion_killed_completed`, a parameter of their script calls (ECON-12). All ported (ENCH-02, ECON-11, ECON-12) with `cr2w_patch.py`. |
| **Spawns** (`.w2comm`) | 1 | `sq209_cave_nekkers` spawns Ghost Mode's `sq209_cave_nekker.w2ent` instead of the generic template. |
| **AI** (`.w2behtree`) | 1 | `monster_bies_logic.w2behtree`: fiend behaviour (collision monitoring, charge handling). |

Changes by folder: quest characters (`quests/**/characters`) mostly got level and ability changes; `characters/npc_entities` and `living_world/enemy_templates` (the generic monsters) mostly loot, levels and categories; `gameplay/community/shops_and_craftsmen` and `living_world/dialogue/generic_merchants` got loot tables.

### Probably not intentional

- **6 files have no real change**, only the W3Edit re-save: `monster_bies_combat.w2beh`, `monster_bies_constraints.w2beh`, `enemy_shortsword_normal.w2ent`, `mq1005_monster.w2ent`, `q305_thug_guard2.w2ent`, `sq102_farm_headhunter_1h_sword_t1.w2ent`.
- **138 files lost their `rangeShort` attack range** (a 1.2 m cone in `CAttackRangeParam`). They are mostly shopkeepers and quest humans, and nothing in the scripts references it; it looks like a side effect of W3Edit rebuilding the templates.
- **73 files lost the `critical_poison` cooked effect**, and some others lost cooked effects such as `stomp_l`/`landing`. Also likely a re-save side effect.
- Always different after re-saving, and filtered out by `bindiff.py`: the CR2W version, cooked effect buffers, regenerated `proxy_*` GUIDs in appearance attachment replacements, and the duplicate objects inside `flatCompiledData`.

## Porting them to 5.x

- The 5.x versions of all these files exist on `vanilla-5.x` (CR2W 164). Ghost Mode's legacy files cannot be used as-is.
- Each Ghost Mode edit is a small value change, so it can be reapplied to the 5.x file: take the 5.x file, then set the same level, ability list, loot entries, category, and so on. First check whether 5.x already changed that value: `python tools/bindiff.py vanilla-1.32 vanilla-5.x <path>`.
- Editing needs a tool that writes 5.x CR2W files. The REDkit editor can (see [tools.md](tools.md)); `tools/cr2w_dump.py` only reads. `tools/cr2w_patch.py` edits the port's copy of the 5.x file: same-size integer and float values in place (prices, counts, levels, ranges, also inside structs), and, rebuilding the file (sizes, offsets, name table, CRCs), name and enum values, removed properties, added and removed array entries (struct entries too) and the names they need; a rebuilt unchanged file is identical byte for byte. An entity template holds its components twice, the editable objects and the compiled copy in `flatCompiledData` (an embedded CR2W file the game reads); the script patches both, with the embedded file's own CRCs. A scene's script block (`CStorySceneScript`) stores its function's arguments as a second property list after its properties; `cr2w_patch.py` edits them with an `@` path (`CStorySceneScript.@rewardName=...`, ECON-12: the result equals legacy's W3Edit edit byte for byte). **Verified**: patched files load in game (ALCH-15's Dimeritium bomb, its smaller cloud seen in play; ENCH-02's dialogue and quest files; ECON-12's scenes). The build ships a patched file because it differs from `vanilla-5.x`.
- **The port applies legacy's entity edits by generator** (`gen_loot.py`, `gen_ai_ent.py`), derived from `vanilla-1.32` → `legacy-GM` for the properties each feature owns and applied to 5.x's file, so W3Edit's re-save noise is not carried over ([development.md](development.md#binary-resources)).
- Some edits may be better done another way in 5.x, e.g. loot through XML loot definitions. Some may be unnecessary, since 5.0 reworked monster combat and skills (see [game-5.0-changes.md](game-5.0-changes.md)).

## Inspecting them

With the `cr2w` diff driver enabled (see [tools.md](tools.md#git-and-github)), plain git shows these files as text, e.g. `git diff vanilla-1.32...legacy-GM -- modGhostMode/files/characters/npc_entities/monsters/arachas_lvl1.w2ent`. The scripts below give more focused views.

```bash
# Readable dump of one file
python tools/cr2w_dump.py --rev legacy-GM modGhostMode/files/characters/npc_entities/monsters/arachas_lvl1.w2ent

# What Ghost Mode changed in one file (or folder)
python tools/bindiff.py vanilla-1.32 legacy-GM modGhostMode/files/characters/npc_entities/monsters/arachas_lvl1.w2ent

# What 5.x changed in the same file
python tools/bindiff.py vanilla-1.32 vanilla-5.x modGhostMode/files/characters/npc_entities/monsters/arachas_lvl1.w2ent

# Which properties Ghost Mode touched, across all files
python tools/bindiff.py vanilla-1.32 legacy-GM --summary
```

For example, `arachas_lvl1.w2ent`: Ghost Mode removed the 90% lesser-mutagen loot container, and 5.0 still has it.
