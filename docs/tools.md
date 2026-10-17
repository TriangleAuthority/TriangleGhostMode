# Tools

`<game>` and `<REDkit>` stand for the install folders of The Witcher 3 and of REDkit. The tools find them through Steam, or take them from the `W3_GAME_DIR` and `W3_REDKIT_DIR` environment variables (`tools/paths.py`). No absolute paths go into the repository: tools and docs use relative paths, these placeholders or environment variables.

## Project tools (`tools/`)

Plain Python 3 (tested with 3.13); no extra packages needed.

| Script | Purpose |
|---|---|
| `paths.py` | Finds the game and REDkit install folders for the other tools: `W3_GAME_DIR` / `W3_REDKIT_DIR` if set, else Steam (the Steam folder from the registry or `STEAM_DIR`, its libraries, each app's manifest). Run it to print what it finds. |
| `extract_vanilla.py <out_dir> [--utf8] [--game DIR]` | Extracts the vanilla file set (all scripts, gameplay XML/CSV, and every other file under `modGhostMode/files`) from a game install into `<out_dir>/scripts` and `<out_dir>/files`, in pure Python (no REDkit). Works for legacy and 5.x installs; both committed baselines regenerate byte-for-byte. Keeps the game's encodings unless `--utf8` is given (use it for legacy). Takes a few seconds. |
| `unbundle.py <bundle-or-dir> <out_dir> [--list]` | Extracts every file from `.bundle` files in pure Python: legacy and 5.x game bundles and packed mods (`content\blob0.bundle`). Supports every compression the game uses: stored, zlib, Doboz (legacy game bundles) and LZ4/LZ4HC. The Doboz decoder was verified against the 232 Doboz-compressed files in the legacy baseline. |
| `port_status.py [--mod REF] [--new REF] [--out FILE]` | Compares the legacy vanilla files on `master`, `legacy-GM` and `vanilla-5.x`, and writes [5.x-file-status.md](5.x-file-status.md): per-file 5.x status and dry-run merge result for every Ghost Mode file. Re-run after a new game version lands on `vanilla-5.x`. |
| `cr2w_dump.py <file>` or `cr2w_dump.py --rev <ref> <path>` | Dumps a binary CR2W resource (`.w2ent`, `.journal`, `.w2scene`, ...) as readable text: every object and property, including embedded and compiled sub-files. Reads legacy (162/163) and 5.x (164) files; read-only. It is also git's text converter for these files (the `cr2w` diff driver, see [Git and GitHub](#git-and-github)). |
| `bindiff.py BASE OTHER [PATH ...] [--summary] [--keep-noise]` | Property-level diff of every binary file that differs between two refs, with re-save noise filtered out. `bindiff.py master legacy-GM` shows Ghost Mode's binary edits; `bindiff.py master vanilla-5.x` shows CDPR's. See [binary-files.md](binary-files.md). |
| `game.py run\|start\|load\|exec\|status\|resume\|saves\|log\|quit` | Drives the game for automated tests through the test-only `modAutomation` (`tools/automation/`, built with `build_mod.py --scripts`) and rw3d_cli (`tools/rw3d/`, git-ignored download): launch without the launcher, load a save, run exec functions and print their output, quit. See [game-automation.md](game-automation.md). |
| `exec_catalog.py [--ref REF] [--out FILE]` | Lists every vanilla `exec function` (console command) on `vanilla-5.x` with its signature, first statement and source line, grouped by topic, into [console-commands.md](console-commands.md). Topics come from name rules in the script; tested commands are marked from its `VERIFIED` set. A few seconds. Re-run after a new game version lands. |
| `focus_game.ps1`, `send_key.ps1`, `screenshot.ps1` | Fallback game control by simulated key presses (scan codes) and screenshots. See [game-automation.md](game-automation.md#keyboard-and-screenshot-fallback). |
| `change_units.py [--filter PATTERN]` | Inventories Ghost Mode's changes as change units (script functions and class members, XML entries, CSV rows, binary files) and compares each across legacy vanilla, the three `legacy-GM` commits and `vanilla-5.x`. Writes `docs/features/units.csv` and, once `docs/features/attribution.csv` exists, `docs/features/coverage.md`. About 30 seconds. `--filter "*Cooldown*"` prints matching units instead. Parses the lenient XML the game accepts (comments with `--`, repeated attributes). See [feature-mapping.md](feature-mapping.md#layout). |
| `unit_sweep.py PATTERN [--unattributed] [--type ws\|xml\|all] [--lines N]` | Lists every change unit whose Ghost Mode change adds or removes a line matching PATTERN (scripts: each function's changed lines, all definitions of the name; XML: the matching lines of each named element), with its attribution and 5.x status. Case-insensitive unless `--case-sensitive`. Used to check an area's mapping before calling it complete (see [feature-mapping.md](feature-mapping.md#feature-ids-and-areas)). About a minute. |
| `deviations.py [--unconfirmed] [--write] [--check]` | Lists every recorded deviation from legacy (the `- **Deviation:**` bullets in the feature entries' Decisions, [convention](feature-mapping.md#legacy-behaviour-first)), grouped by feature; `--unconfirmed` only those the project owner has not confirmed; `--write` regenerates `docs/features/deviations.md`, `--check` fails when it is out of date. |
| `check_modsigns.py [--worktree DIR] [--verbose]` | Checks Ghost Mode's scripts in the `5.x-GM` worktree against `vanilla-5.x`: every `@replaceMethod` body and every scope-based override (its methods and its `default`/field lines) must mark each change with `//modSigns` (added or changed lines at their end; a removal by a `//modSigns` comment where the code was); also raises an alarm for any `@wrapMethod` of a native function (blob only). Diffs each body with the 5.x original, so it shows exactly which lines are unmarked. Exits 1 on a finding. About 2 seconds. Run it before committing script changes. See [development.md](development.md#conventions). |
| `gen_npc_stamina.py [--check] [--worktree DIR]` | Generates STAM-08's `gm_npc_stamina.xml` in the `5.x-GM` worktree: for every enemy ability whose stamina nodes legacy changed (`master` vs `legacy-GM`), an `on_conflict="extend"` entry with legacy's values for the changed stamina tags only (removed nodes as 0); reports abilities missing in 5.x and tags both 5.x and legacy changed. Abilities another feature gives whole (`OWNED`, e.g. MUT-08's `Mutation4BloodDebuff`) are left out. `--check` prints the report only. A model for porting other per-ability XML changes. Run `gen_ngplus.py` afterwards. |
| `gen_ngplus.py [--check] [--worktree DIR]` | Writes the New Game+ copies of Ghost Mode's DLC ability XML (`abilities_plus/` next to `abilities/` in the `5.x-GM` worktree): every number scaled by the NG+ rule against `vanilla-5.x`'s NG and NG+ values ([feature-mapping.md](feature-mapping.md#ng-numbers)), comments kept; prints each value that changes. `--check` writes nothing and fails if a copy is missing or out of date. Re-run after changing any file in `abilities/`. |
| `gen_test_dummy.py [--worktree DIR]` | Generates the in-game test dummy's step abilities (`gm_test_dummy.xml` in Ghost Mode's DLC, in the `5.x-GM` worktree: one ability per stat, sign and scale) and the script lookup of their names (`tests/gmTestDummySteps.ws`; WitcherScript cannot build a name from a string, and one large function exhausts the script compiler's memory, so it writes one function per stat). Run `gen_ngplus.py` afterwards. See [development.md](development.md#testing-in-game). |
| `build_mod.py [--ref REF] [--install] [--enable] [--release] [--loose]` | Builds an installable mod from a branch: compiles every script the branch adds or changes relative to `vanilla-5.x` with `wcc_lite compilescripts` (about 20 seconds, log in `build/compile.log`) into `build/modGhostMode/content/precompiled.rsblob`. A compile error stops the build. `--install` copies the mod into `<game>\mods\modGhostMode`, `--enable` adds it to `mods.settings`, `--release` leaves out the in-game tests (`modGhostMode/scripts/local/gm/tests/`) for a build to play or publish, `--loose` ships loose scripts instead of the blob (experiments only), `--scripts DIR` builds a folder of scripts instead of a branch's changes (used for `modAutomation`). Changed game files under `modGhostMode/files/` are packed with `wcc_lite pack` into `blob0.bundle` plus `metadata.store`, the CSVs under `modGhostMode/localization/` are encoded into `<lang>.w3strings` with `w3strings.py`, the Wwise banks under `modGhostMode/sound/` are packed into `soundspc.cache` with `soundcache.py`, and `--install` copies the menu XML under `modGhostMode/menu/` into the game's `bin\config\r4game\user_config_matrix\pc\`. See [development.md](development.md#build-compile-install); the regression run (`gmtest_regress()`) in [development.md](development.md#testing-in-game). |
| `make_reddlc.py <out.reddlc> --id ID --xml PATH [--xml PATH ...] [--xml-ngplus PATH ...]` or `--selftest` | Writes a DLC definition (`.reddlc`, CR2W) whose `CR4DefinitionsDLCMounter`s make the game load the given definitions XML files or folders (depot paths, e.g. `dlc\dlcghostmode\data\gameplay\abilities\`), and whose `CR4DefinitionsNGPlusDLCMounter`s load the New Game+ ones (`--xml-ngplus`, e.g. `...\abilities_plus\`). Not required by saves, hidden from the DLC menu. A minimal CR2W writer: `--selftest` rebuilds vanilla `dlc8.reddlc` from the REDkit depot byte for byte. See [development.md](development.md#dlc-and-mounters). |
| `w3strings.py encode <in.csv> <out.w3strings>`, `decode <in.w3strings> <out.csv>`, `--selftest` | Encodes and decodes string tables in pure Python, in the 5.0 format (version 164, UTF-8 text) or the legacy one (162, UTF-16). Reads and writes the community encoder's CSV format. `--selftest` decodes all 18 of the game's 5.0 string tables and re-encodes them byte for byte. `build_mod.py` uses it for the mod's strings; decoding the game's tables finds a vanilla string's id. See [development.md](development.md#localization). |
| `soundcache.py list\|extract <cache> [out_dir]`, `pack <out.cache> <file>...` | Reads sound caches (`soundspc.cache`, `CS3W`) in formats 1 (legacy) and 2 (5.x), and writes format 2: a 64-byte header, the files from 0x40, the names, then the table (u64 name offset, data offset, size); the header's checksum is FNV-1a 64 over the names followed by the table (checked against the 5.0 cache). `build_mod.py` uses it to ship the mod's Wwise banks; see [development.md](development.md#sound-banks). |
| `to_utf8.py <dir-or-file>...` | Converts UTF-16/BOM text files (`.ws .xml .csv .txt`) to plain UTF-8 in place and fixes `encoding="UTF-16"` declarations. Used for the legacy baseline. Do not use it on files meant for 5.0, which expects a BOM on XML. |

## Game install

`...\The Witcher 3` (5.0 now installed; Steam app 292030).

**Legacy (1.32) game files:** a copy of the legacy install is kept locally, outside the repository (`<legacy game>`, a `legacy-The Witcher 3` folder next to the checkouts; `witcher3.exe` 3.0.0.1259521, same layout as the legacy install: `content\content0`–`12`, `patch0`, `patch1`, `DLC\*`). It is not a Steam install; use it as the source for legacy vanilla files, e.g. `tools/unbundle.py` on its bundles or `python tools/extract_vanilla.py <out> --utf8 --game "<legacy game>"`, which reproduces the legacy baseline on `master` exactly.

- Scripts are loose files in `content\content0\scripts` (`core`, `engine`, `game`).
- Everything else is in `content\content0\bundles\*.bundle`. `xml.bundle` holds most engine XML; gameplay XML is spread across `blob.bundle`, `bob.bundle`, `ep1.bundle`, `dlc0.bundle`, `startup.bundle` and the `world_*` bundles. [game-5.0-changes.md](game-5.0-changes.md) describes the bundle format.
- Menu configs: `bin\config\r4game\user_config_matrix\pc\*.xml`.
- String tables: `content\content0\<lang>.w3strings`.

## The Witcher 3 REDkit (CDPR's official mod tools)

`...\The Witcher 3 REDkit` (Steam app 2684660; updated alongside 5.0, build 25576626). Docs: [REDkit wiki](https://cdprojektred.atlassian.net/wiki/spaces/W3REDkit/pages/6324268/General+information); [development.md](development.md) summarizes what matters for this project. The wiki pages render with JavaScript, so fetch their text through the Confluence REST API instead: `https://cdprojektred.atlassian.net/wiki/rest/api/space/W3REDkit/content/page?limit=100&expand=body.view` lists every page with its content.

Steam updates REDkit in place, so older builds are not kept: the 5.0 update replaced the `wcc_lite` that could read legacy bundles. The project's extraction tools no longer depend on it. If an older build is ever needed, it would have to be fetched with Steam's depot downloader (`download_depot` in the Steam console, with an old manifest ID).

| Path | What it is |
|---|---|
| `bin\x64_RedKit\editor.exe` | The REDkit editor: opens and edits resources (entities `.w2ent`, quests, scenes, ...). This is the likely way to reapply Ghost Mode's binary-resource edits to the 5.0 versions. |
| `bin\x64_RedKit\scriptStudio.exe` | Script editor/debugger for `.ws` scripts. |
| `bin\x64_RedKit\wcc_lite.exe` | Command-line cooker and packer (see below). |
| `bin\x64_RedKit\bundlebuilder.exe`, `bin\tools\cooker\do_game.bat` | Bundle building and cooking pipeline. |
| `r4data\` | Uncooked game depot (about 66 GB): editable source versions of game resources, apparently matching the current game (files dated 2026-09-29, XML in UTF-8 with BOM). Another source of vanilla 5.0 files. |

### wcc_lite

Run it from `bin\x64_RedKit` with no arguments to list commands, or `wcc_lite <command>` for a command's usage. Commands useful here:

| Command | Use |
|---|---|
| `compilescripts <scripts dir>\ -patch=<mod scripts dir>\ -out=<path>` | New in 5.0. Compiles the game's scripts (`<game>\content\content0\scripts\`) plus a mod's, and writes the mod's compiled scripts as a script blob (`<path>\blob.rsblob`). Exit code 1 and `[Error][WCC] [<line>]: <message>` lines on errors. About 20 seconds. `tools/build_mod.py` runs it as its compile check. Directory arguments need a trailing backslash. |
| `unbundle -dir=<bundles dir> -outdir=<dir>` | Extracts **every** file from every bundle in a directory (recursive). There is no filter option. Since the REDkit update for 5.0 it only reads 5.x bundles: legacy ones fail with "invalid headerVersion: 3 (expected 5)". Use `tools/unbundle.py` instead. |
| `uncook -indir=<bundles dir> -outdir=<dir> [-unbundleonly]` | Extracts and uncooks resources (e.g. textures to `-imgfmt=tga`). |
| `pack -dir=<dir> -outdir=<dir> [-compression=LZ4\|LZ4HC\|ZLIB]` | Packs a directory into a bundle (for building the mod). |
| `metadatastore` | Generates `metadata.store` for a directory of packed bundles (needed when shipping a mod; run `wcc_lite metadatastore` for its arguments). |
| `cook`, `import`, `export` | Cooking and asset import/export. |
| `dumpfile -file=<path> -out=<file>` | Documented as dumping a resource's objects to text. Produced no output when tried on a legacy `.w2ent`. |
| `dumpbundleinfo -indir=<path> -outpath=<path>` | Lists bundle contents. It rejected `-outpath` when tried ("No out file path"). |

Gotchas: commandlets can open a blocking EULA dialog (it has no "remember" option, and the `DoNotShowEula` registry value under `HKCU\Software\CD Projekt RED\Mod Tools\1.0` does not stop it); pass `-agreetoterms` to skip it, as `build_mod.py` does (the project owner accepted the EULA and approved this). Pass absolute Windows paths. Output paths over 260 characters fail ("Unable to create output file"), so extract to a short directory (e.g. one at the drive root). Unknown options are silently ignored.

## Legacy-era community tools (for the 1.32 mod)

| Tool | Purpose |
|---|---|
| [W3Edit](https://drive.google.com/file/d/0B3axqSlhNHOOYmpkWk83TXRkZmM/view) (Saracen) | Legacy editor used to build the original mod (`modGhostMode.w3modproj`) and to edit its binary files; its saves are recognizable as CR2W version 162. |
| [WolvenKit](https://www.nexusmods.com/witcher3/mods/3161) | Community mod editor. Version 0.6.1 supports 1.32; 5.0 support is unverified. |
| [w3strings encoder](https://www.nexusmods.com/witcher3/mods/1055) | Encodes localization CSVs into `.w3strings` (`w3strings.exe --encode en.csv --id-space 992`). Writes the legacy format (version 162); replaced by `tools/w3strings.py` for 5.x. |
| [Script Merger](https://www.nexusmods.com/witcher3/mods/484) | Merges script conflicts between installed mods. |

## Git and GitHub

- Remote: `git@github.com:TriangleAuthority/TriangleGhostMode.git`. Repo-local identity: `Triangle Man <<noreply address>>` (keeps the private email out of commits).
- SSH: the GitHub key is loaded in the **Windows** OpenSSH agent, which Git for Windows' bundled `ssh` cannot see. Either run git with `core.sshCommand` set to Windows' own `ssh.exe` (`%SystemRoot%\System32\OpenSSH\ssh.exe`), or push over HTTPS with the `gh` CLI login: `git -c credential.helper= -c "credential.helper=!gh auth git-credential" push https://github.com/TriangleAuthority/TriangleGhostMode.git <branch>`.
- `gh` CLI is logged in as TriangleAuthority.
- `core.autocrlf=true` and `* text=auto`: text is stored with LF and checked out with CRLF (see [repository.md](repository.md)).
- **Readable diffs of binary files**: `.gitattributes` assigns a `cr2w` diff driver to `.w2ent`, `.journal`, `.w2scene`, `.w2phase`, `.w2beh`, `.w2behtree` and `.w2comm`. Git config is not versioned, so enable it once per clone:

  ```bash
  git config diff.cr2w.textconv "python tools/cr2w_dump.py"
  git config diff.cr2w.cachetextconv true
  ```

  Then `git diff`, `git show` and `git log -p` print these files through `tools/cr2w_dump.py` as indented text (e.g. `git diff master...legacy-GM -- <file.w2ent>`). Notes: the files stay binary in the repository; GitHub's web view and `git diff --stat` still say "Bin"; merges still treat them as binary; `--no-textconv` shows the raw "binary files differ". Re-save noise (CR2W version, regenerated proxy GUIDs, cooked effect buffers) appears in these diffs; `tools/bindiff.py` filters it.
