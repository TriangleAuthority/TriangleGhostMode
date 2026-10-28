# Game version 5.0: changes that affect porting

Observations from comparing the legacy game (1.32, Steam build 3280809, `witcher3.exe` 3.0.0.1259521) with version 5.0 (Steam build 25575366, `witcher3.exe` 5.0.0.1041720, released 2026-09-29 as the "Remastered" update). Per-file details are in [5.x-file-status.md](5.x-file-status.md).

**5.0 hotfix** (Steam build 25646871, `witcher3.exe` 5.0.0.1044392, installed 2026-10-01; the current `vanilla-5.x`): changes 10 files of the baseline. Scripts: meditation sound fixes (`commonMenu.ws`, `meditation.ws`), a marketing consent setting (`startupExperienceMenu.ws`), whitespace in four projectile scripts. Binary: `q604_caretaker.w2ent` (mesh, light and trigger channel flags) and a re-save of `monster_bies_combat.w2beh` and `monster_bies_constraints.w2beh` (no property changes). None of it touches what Ghost Mode changes in those files.

Anything marked *unverified* is inferred but not yet tested in game.

## Gameplay systems (from the official patch notes)

5.0 reworks several systems Ghost Mode overhauls. Check these before porting the matching Ghost Mode features:

- **Skills:** reorganized into a skill tree with three ranks per skill. New skills unlock through prerequisite skills instead of a fixed point cost. All skill points are reset. Skill bonuses, effects and synergies are rebalanced, and several skills are renamed. Ghost Mode reworked skills, perks and set bonuses extensively, so this is the largest overlap. New skill effect scripts include `avoidanceSignSkillBuff.ws`, `catalystSignSkillBuff.ws`, `convergenceTheorySignSkillBuff.ws`, `elementOfSurpriseSurvivalSkillBuff.ws`, `resonance.ws`, `overloadCooldown.ws` and `undyingSkillDebuff.ws`. Ghost Mode has its own `undyingSkillCooldown.ws`/`undyingSkillImmortal.ws` and sign cooldown effects.
- **Monster combat:** attack patterns, counterattacks, movement and effect application of all non-boss monsters were reworked. Ghost Mode changes monster stats, abilities and behaviour-tree tasks, including dodge, parry and hit reactions.
- **Finishers and movement:** new finisher animations, a quick-disengage move (hold dodge, press sprint) and faster climbing. Ghost Mode changed finishers and stamina costs.
- **Reforging ("transmog"):** equipment appearance can be changed at master craftsmen. New `transmogMenu.ws` and `guiTransmogInventoryComponent.ws`.
- **Looting:** loot from horseback, a grouped loot window, a loot feed HUD module (`hudModuleLootFeed.ws`) and item tooltips before pickup.
- **Throwing knives:** new `knifeProjectile.ws` and `throwingKnifeProjectile.ws`.
- **Aiming slow motion (from the code, verified 2026-10-15):** 1.32 slows time to ×0.6 half a second into aiming a bomb or a bolt (`PlayerAimingStateAiming.Aim` calls `SloMo`); 5.x dropped that call, so aiming a bomb no longer slows time at all, and the crossbow gets its slow motion from `rangedWeapon.ws` (`OnAddAimingSloMo`). Steady Aim (`alchemy_s9`) deepens a slow motion that never starts; Ghost Mode restores it for bombs (SKL-15).
- **Crossbow and bolts (from the code and data, 2026-10-25; unverified in game):** the bolt, crossbow and NPC bow data is 1.32's, and 5.x added no crossbow or bolt. A bolt or arrow counts as a headshot when the bone it hits has `head`, `neck` or `hroll` anywhere in its name (and `pelvis` on humans; 1.32: those exact names); a quick shot at a large monster with targetable parts (`HasVirtualControllerTarget`) flies at the targeted part's bone instead of `torso2`; a bolt shot while diving gets the underwater range and 60% speed, otherwise the full range (1.32: the full range while swimming, the underwater range otherwise; `W3BoltProjectile.ReleaseProjectiles2`); arrows derive from the new `W3DeflectableAdvancedProjectile`. Every advanced projectile (arrows, NPC bolts, monster projectiles) gains 2.5% of its damage per Geralt level each time it collides (`W3AdvancedProjectile.OnProjectileCollision`; 1.32's code, as legacy has it, has no such term): an archer's arrow (`arrow_01.w2ent`, 200) reads 205 on Geralt at level 1 and 350 at level 30, a crossbowman's bolt (`bolt_01.w2ent`, 600) 1,050 at level 30, and a reflected arrow, scaled at Geralt and again at the archer, 612.5 (**seen in game** 2026-10-25). See [features/xbow.md](features/xbow.md).
- **Skills with no ability:** some 5.x skills have no `<ability>` entry for their ability name (e.g. Endure Pain `alchemy_s20`: its value is the effect `IgnorePainEffect`); a DLC that gives one values adds a new entry (no `on_conflict`).
- Also removed in 5.0: the drinking-game minigame, the old combat focus-mode scripts (`player/states/focusMode/*`, `focusModeCombat.ws`) and `combatManager.ws`.

Sources: [mp1st patch notes summary](https://mp1st.com/news/the-witcher-3-remastered-update-patch-notes-list-over-90-improvements), [Game Rant](https://gamerant.com/the-witcher-3-remastered-patch-50-notes/), [Beebom](https://beebom.com/the-witcher-3-remastered-patch-notes/).

## Mod support

- **Shared Imports is built in.** The 14 new `scripts/engine/C*.ws` files and the additions to `engine/components.ws` and `engine/environment.ws` are the community Shared Imports mod (v0.6), which Ghost Mode depends on. See [legacy-ghost-mode.md](legacy-ghost-mode.md#dependencies).
- The patch notes announce cross-platform mod support through mod.io in the main menu, plus REDkit improvements. New scripts: `gui/menus/modMenu.ws`, `gui/menus/modmenu_states/*`, `gui/data/ModPopupData.ws`, `systems/modHandlerSystem.ws`.
- **Local mods still load from `<game>\mods\<modName>\content\`** (folder names must start with `mod`), plus Steam Workshop subscriptions. All are enabled by default and load alphabetically; `Documents\The Witcher 3\mods.settings` overrides enabling and priority. The fresh install has no `mods` folder; create it. Source: REDkit wiki ([Managing mods](https://cdprojektred.atlassian.net/wiki/spaces/W3REDkit/pages/36339714/Managing+mods)). **Verified** in game for scripts (pilot slice 1, 2026-10-01): a mod in `<game>\mods\modGhostMode\content\scripts\` with a `mods.settings` entry compiled and ran, including script annotations and a whole-file override of a vanilla script.
- **5.0 adds modding features that let mods change the game without replacing vanilla files** (REDkit [changelog](https://cdprojektred.atlassian.net/wiki/spaces/W3REDkit/pages/12058625/Changelog) for 5.0.1042178, 29.09.2026). How the port uses them is in [development.md](development.md).
  - *Script annotations* (`@wrapMethod`, `@replaceMethod`, `@addMethod`, `@addField`, since patch 4.04) now also work on events, states and (per the changelog) native functions.
  - *Scope-based overrides*: a new script file re-declares a class with its vanilla header and adds or overrides members, including `default` values; merged at runtime. Mods can also add members to vanilla enums. **Both only work from a script blob** (verified, pilot slice 2). Syntax and rules in [development.md](development.md#scope-based-overrides-50).
  - *Fine-grained XML overrides*: a DLC can redefine existing XML entries, or single fields of them, with `on_conflict="replace"` (the changelog spells it `onConflict`, which the game ignores) or `"extend"` (default: error on redefinition). Previously DLC XML could only add entries.
  - *New DLC mounters* for conflict-free DLC mods that change base-game features.
  - *Script blobs*: a mod's scripts compiled to `content\precompiled.rsblob`. The game compiles blobs as mod code; when a mod has one, its loose `.ws` files are ignored. Loose scripts are still compiled together with the vanilla scripts, the legacy way (verified, pilot slices 1–2).
  - *`wcc_lite compilescripts`*: compiles the game's scripts plus a mod's from the command line. Used as the compile check in `tools/build_mod.py` (see [tools.md](tools.md)).
- **New script types** `map` and `set` (generic like `array`; methods `Clear`, `Size`, `Contains`, `Erase`, `TryGet`, `Key`), per the [mod.io guide](https://mod.io/g/the-witcher-3/r/what-does-the-remaster-mean-for-modding) (unverified here).
- **mod.io** (the in-game Mod Hub, also on consoles) validates every mod and update. Not available through it: mod menus, custom inputs, configuration mods (`.ini` edits) and injected code; mods need a JSON file (name, version, description, game version) and lowercase paths ([mod.io guide](https://mod.io/g/the-witcher-3/r/what-does-the-remaster-mean-for-modding)). Ghost Mode's options menu would rule it out there as it stands.
- Debug console: `DBGConsoleOn=true` in `<game>\bin\config\base\general.ini` (REDkit wiki).
- Menu configs in `bin\config\r4game\user_config_matrix\pc\` are now UTF-8 with BOM (10 files). There is no `dx11filelist.txt`/`dx12filelist.txt`: the game reads every XML in that folder, so a mod's menu file only has to be copied there (verified, pilot slice 5). Settings are saved in `Documents\The Witcher 3\dx12user.settings`; the legacy `user.settings` is no longer read. See [development.md](development.md#options-menu).
- Localization: a Ukrainian string table (`ua.w3strings`) was added. String tables moved to format version 164: the text is UTF-8 (obfuscated per byte), with offsets and lengths in bytes; legacy version 162 stored UTF-16. A mod's `content\<lang>.w3strings` is loaded without registration, and its strings override vanilla ones with the same id (verified, pilot slice 4). See [development.md](development.md#localization).

## Audio

- **The game runs Wwise 2023.1.19** (statically linked; `witcher3.exe` contains the SDK build paths `wwise_v2023.1.19`). All 740 banks in `content\content0\soundspc.cache` are bank version 150 (Wwise 2023.1). Legacy Ghost Mode's bank is version 88 (Wwise 2013.1/2013.2). Verified from the files; version-to-release mapping from [wwiser](https://github.com/bnnm/wwiser) (`wdefs.py`).
- **Mods ship banks in `content\soundspc.cache`, format version 2.** The game's sound caches moved from format version 1 (legacy: u32 fields) to version 2 (u64 fields, a 64-byte header with an FNV-1a 64 checksum); layout in [tools.md](tools.md#project-tools-tools) (`soundcache.py`). **Verified** (STAM-07, 2026-10-03): a version 2 cache in `mods\modGhostMode\content\` with a Wwise 2023.1 bank loads (`SoundIsBankLoaded` true) and plays, game parameters and `game_state` states included. Legacy version 1 caches were not tried.
- **Building banks for a mod needs Wwise 2023.1, not newer than 2023.1.19.** Install **2023.1.19.8928** with the Mastering Suite and Motion plugins through the Audiokinetic Launcher: that is the version of REDkit's audio project (`<REDkit>\assets\w3_audio\w3_audio.wproj`: `WwiseVersion="v2023.1.19" WwiseBuild="8928"`) and of the game's runtime. REDkit's editor says "The Wwise version must not be newer than 2023.1.19"; the REDkit wiki ([HOW-TO: Implement sounds and use Wwise](https://cdprojektred.atlassian.net/wiki/spaces/W3REDkit/pages/6327994)) accepts any 2023.1.x. Wwise 2024.1 writes bank version 154, which the 2023.1 runtime would not load (inferred, not tested).
- **Packages:** **Authoring** only. It contains `WwiseConsole.exe` (`Authoring\x64\Release\bin\`), which REDkit calls to build banks. The SDK is for compiling a game against Wwise and is not needed.
- **Deployment platforms:** only **Windows** (Microsoft > Windows in the Launcher; the Visual Studio version does not matter, since no game code is built against the SDK). Banks for a PC mod are generated for the `Windows` platform ("Generate SoundBank(s) for current platform", or REDkit's `WwiseConsole ... --platform`). `w3_audio.wproj` also lists Linux, the consoles and others; those need not be installed (console platforms need an NDA anyway), and Wwise may warn that they are missing (unverified here).
- **REDkit does not ship Wwise.** It runs an installed `WwiseConsole.exe generate-soundbank` and writes `soundspc.cache`. It looks in `%ProgramFiles(x86)%\Audiokinetic\Wwise*\Authoring\x64\Release\bin\`, then the PATH, then `<REDkit>\tools\wwise\...`; Tools > Sound > Set Wwise path sets it by hand. Modders add sounds to the `_Mod` bank of the `w3_audio` project and reload banks with Tools > Sound > Reload soundbanks (wiki; unverified here).
- **Licence:** the REDkit wiki says a licence is needed above 250 sound files; the free key comes from the "Witcher 3 REDkit Modding" course at audiokinetic.com/school (3 months, renewable; wiki page [HOW-TO: Get a Wwise license](https://cdprojektred.atlassian.net/wiki/spaces/W3REDkit/pages/6327958)). Ghost Mode's one bank is far below that limit.

## Install layout

| | Legacy | 5.0 |
|---|---|---|
| Executable | `bin\x64\witcher3.exe` (DX11) | `bin\x64_dx12\witcher3.exe` (DX12 only) |
| Content | `content\content0`–`content12`, `content\patch0`, `content\patch1` | `content\content0` only |
| DLC | `DLC\<name>\content\bundles` (DLC1–16, ep1, bob) | Merged into `content0\bundles` (`bob.bundle`, `ep1.bundle`, `dlc0.bundle`). `dlc-tombstones\<name>\*.tombstone` are empty marker files. |
| Scripts | `content\content0\scripts` (1,491 files) | Same place (1,527 files) |
| New | | `content0\hdr`, `bin\config\r4game\legacy\base\override_input_switch2.ini`, new DLC `dlc\dlc20` (models, entities and `.w3app` appearance files only; no gameplay XML) |

Depot paths inside the bundles are unchanged: DLC files still live under `dlc\<name>\data\...`, matching the mod's `files/dlc/...` paths.

## Bundle format

Both versions use the `POTATO70` magic and store the table of contents uncompressed after a 0x20-byte header.

| | Legacy | 5.0 |
|---|---|---|
| Header | u32 size, u32 total uncompressed size, u32 TOC size, then constants | u64 bundle size, u32 TOC size, u16 version = 5, u32 data start |
| TOC entry | 0x140 bytes | 0x130 bytes: name[0x100], hash[16], u64 offset, u32 size, u32 compressed size, u32 CRC, u32 compression, 8 zero bytes |
| Payload alignment | 4 KiB | none (payloads follow the TOC) |
| Compression | none, zlib, Doboz, LZ4, LZ4HC | none and zlib only |

In 5.0, about 40,000 paths appear in more than one bundle. For every file in our baseline the duplicates are byte-identical, so load order does not matter. `tools/extract_vanilla.py` handles both formats (see [tools.md](tools.md)).

## Encodings

5.0 moved from UTF-16 to UTF-8. See the table in [repository.md](repository.md#encodings-and-line-endings). Details:

- **XML:** all UTF-8 with BOM and CRLF. Quirks: `dlc/bob/.../items/def_loot_shops.xml` and `items_plus/def_loot_shops.xml` still declare `encoding="UTF16"` although they are UTF-8. 18 files have a tab in the XML declaration and 4 use lower-case `utf-8`.
- **Scripts:** UTF-8 without BOM. 543 use CRLF only; the other 984 mix CRLF and LF.
- **CSV:** mostly ASCII with CRLF. Still UTF-16 LE: `gameplay/globals/credits.csv`, `credits_ep1.csv`, `credits_ep2.csv`, `credits_ng.csv`, `credits_tw3re.csv`, `eula.csv`, `gameworlds.csv`. UTF-8 with BOM: `credits_ly.csv`. UTF-8 without BOM: `game/photomode_characters.csv`, `game/photomode_props.csv`. None of these are Ghost Mode files.
- **Ported files** should match 5.0: XML in UTF-8 with BOM, scripts in UTF-8 without BOM, CSV as the 5.0 original. Merging with `vanilla-5.x` gives this automatically for files where Ghost Mode did not edit line 1. Whether 5.0 also accepts UTF-16 or BOM-less XML is *unverified*.

## File structure changes (baseline file set)

Compared with legacy, ignoring encoding and line endings:

- **Scripts:** 71 added, 35 deleted, 341 with real code changes, 1,115 changed only in whitespace or the license header (`®` became `©`, trailing spaces, blank lines removed). Real changes cluster in `game/gameplay` (83), `game/gui` (77), `game/behavior_tree` (41), `game/quests` (36) and `game/player` (29). For example, `playerWitcher.ws` gained a skill-combo system (`SSkillComboData`, `ESkillComboEntityKind`) and grew from about 11,000 to 13,000 lines. `geralt_skills.xml` also changed heavily.
- **XML:** 28 added (new item sets such as `w3r_items.xml`, `dlc18_netflix_*`, `def_item_*_dol_blathanna.xml`, `def_gwint_decks.xml`, weapon scabbards), 1 deleted (`gameplay/abilities/geralt_mutation.xml`, not modified by Ghost Mode), 162 with real changes, 263 whitespace/BOM only.
- **CSV:** 11 added (photo mode, credits, `rewardsmap.csv`, ...), 15 with real changes, 70 identical.
- **Binary resources:** every `.w2ent`, `.journal`, `.w2scene`, `.w2phase`, `.w2beh`, `.w2behtree` and `.w2comm` in the set changed. For `.w2ent` the CR2W header version went from 163 to 164, so the mod's legacy-format resources cannot be dropped into 5.0 as-is.

## Impact on Ghost Mode

Full lists are in [5.x-file-status.md](5.x-file-status.md). Summary of the files `legacy-GM` modifies (Ghost Mode 4.1 plus its Shared Imports and Community Patch – Base scripts):

| Files | 5.0 reformatted only | 5.0 changed | Merge conflicts |
|---|---|---|---|
| 203 scripts | 87 | 116 | 73 |
| 314 XML | 174 | 140 | 96 |
| 6 CSV | 0 (5 identical) | 1 | 1 (`quest_levels.csv`) |
| 650 binary | — | 650 (new format) | 650 |

- Ghost Mode's 41 new files (scripts, localization, menu, design docs) do not collide with any 5.0 path.
- No file Ghost Mode modifies was deleted in 5.0.
- Conflicting scripts concentrate in the systems 5.0 reworked: abilities (`PlayerAbilityManager.ws`, `abilityManager.ws`), damage and effects (`damageManagerProcessor.ws`, `effectManager.ws`, many effect scripts), signs (`signEntity.ws`, `quenEntity.ws`, ...), player (`playerWitcher.ws`, `r4Player.ws`, `playerInput.ws`), NPC combat behaviour trees, and the character, alchemy and inventory menus.
