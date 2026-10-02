# Development guide

How to write, build and test the 5.x port. Read this before changing anything on `5.x-GM`.

[feature-mapping.md](feature-mapping.md) decides *what* to port and in which order. This doc covers *how*: which 5.x modding features to use, the conventions for this mod, and the build and test loop.

Status labels: **verified** means tested in game on 5.x; **compiles** means `wcc_lite compilescripts` accepts it but it has not been run in game yet; **unverified** comes from documentation or other sources and has not been tested here. Update the labels as the pilot and the port confirm things. Questions nobody has answered yet are collected in [open-questions.md](open-questions.md).

## Principles

- **Prefer the least invasive way to make a change** (see [Port forms](#port-forms)). 5.x can merge script and XML changes from several mods at game start, so a mod that only adds override files survives CDPR patches and other mods far better than one that ships edited copies of vanilla files.
- **Small steps, each run in game before the next.** See [feature-mapping.md](feature-mapping.md#small-steps-verified-in-game). Every step passes the [compile check](#build-compile-install) and the in-game check.
- **Record the save impact** of every change (`none`, `reacquire items`, `cleardevelop`, `new game`). See [feature-mapping.md](feature-mapping.md#save-compatibility).
- **Keep the spirit of Ghost Mode, built on 5.x's systems.** Re-apply the intent of a legacy change to the 5.x code, not the legacy code itself.
- **Do not edit `vanilla-5.x` or `master`'s game files.** All mod work happens on `5.x-GM` (or a short-lived branch off it).

## Port forms

Use the first form that can express the change:

| # | Form | Use for | Details |
|---|---|---|---|
| 1 | **Scope-based override**, **enum extension** or **script annotation** (`@wrapMethod`, `@replaceMethod`, `@addMethod`, `@addField`), in a new script file | All script changes | [Scripts](#scripts) |
| 2 | **XML override through Ghost Mode's DLC** (`on_conflict="extend"` or `"replace"`) | Changing or adding abilities, items, loot and other definitions | [XML](#xml-and-csv) |
| 3 | **DLC mounter** in Ghost Mode's `.reddlc` | Attaching abilities or parameters to entity templates, registering XML, CSV, journal or other content | [DLC mounters](#dlc-and-mounters) |
| 4 | **Whole-file override**: the mod ships its own copy of a vanilla file at the same path | XML, CSV and other files the forms above cannot express. Not needed for scripts (see [Choosing a technique](#choosing-a-technique)). | The legacy approach. Every vanilla update to that file must be merged by hand. |
| 5 | **Binary resource edit** (`.w2ent`, `.journal`, ...) in REDkit | Values only stored in a binary resource, when a mounter cannot do it | [binary-files.md](binary-files.md) |

The feature entry records the form used ("Port form" in the [entry template](feature-mapping.md#feature-entry-template)), and why when it is 4 or 5.

## Where things go on `5.x-GM`

| What | Path |
|---|---|
| Script files (scope-based overrides, annotations, new classes, exec functions) | `modGhostMode/scripts/local/`. One file per vanilla class or system Ghost Mode changes; group into folders by feature area once there are several. `tools/build_mod.py` compiles everything Ghost Mode adds or changes under `modGhostMode/scripts/` into the blob. |
| Ghost Mode's DLC (XML overrides, `.reddlc`, mounted CSV) | `modGhostMode/files/dlc/dlcghostmode/`: `dlcghostmode.reddlc` (DLC id `dlc_ghostmode`) and `data/gameplay/...` below it, mirroring vanilla's layout (e.g. `data/gameplay/abilities/`). It ships inside the mod's `blob0.bundle`; no separate DLC install is needed (verified, pilot slice 3b). |
| Whole-file XML/CSV/binary overrides | The vanilla path under `modGhostMode/files/`, edited in place |
| Localization source (CSV) | `modGhostMode/localization/<table>/<lang>.csv` (see [Localization](#localization)) |
| Options menu (XML) | `modGhostMode/menu/<file>.xml` (see [Options menu](#options-menu)) |

`tools/build_mod.py` turns these into an installable mod (see [Build, compile, install](#build-compile-install)).

## Conventions

- **Prefix everything Ghost Mode adds** so it cannot collide with vanilla or other mods: fields, methods and functions start with `GM`/`gm` (`gmStaminaCostMult`, `GMGetSignCooldown`), new classes with `W3GM`/`CGM`, exec functions with `gm`, log channels with `GM` (`LogChannel('GMStamina', ...)`), XML entries added (not overridden) with `GM_` or `gm_`.
- **Tag every override with its feature ID** in a comment above it: `// STAM-01: stamina cost for light attacks`.
- **In overridden methods and whole-file overrides, mark each changed line or block with `//modSigns`**, the legacy Ghost Mode marker, so changes against the vanilla body stay findable and the tooling can count them.
- **Commit messages** name the feature IDs and the save impact when it is not `none`.
- **Encodings:** scripts UTF-8 without BOM; XML UTF-8 with BOM; CSV as the 5.0 original. See [game-5.0-changes.md](game-5.0-changes.md#encodings).

## Scripts

### How the game loads mod scripts

**Ghost Mode ships its scripts as one compiled file, `mods\modGhostMode\content\precompiled.rsblob`**, built by `tools/build_mod.py` (pilot slices 1–2, **verified** 2026-10-01). What the pilot established:

- A mod's scripts come either as **loose `.ws` files** in `content\scripts\`, or as a **script blob**, `content\precompiled.rsblob`. If a mod has a blob, **the game ignores that mod's loose scripts** (they are not loaded at all, without any error).
- **Loose scripts are compiled together with the vanilla scripts**, as in legacy versions. Annotations and whole-file overrides work there, but re-declaring an existing class or enum fails at game start: "Class 'W3PlayerWitcher' is already defined in current compilation unit", "Enum 'EEffectType' is already defined and 'isMod' is false".
- **A blob is compiled as mod code** (`isMod`), so it also allows **scope-based overrides** and **enum extensions**. Everything else works from a blob too: annotations, new classes and functions, and copies of vanilla files.
- The blob comes from `wcc_lite compilescripts <game scripts>\ -patch=<mod scripts>\ -out=<dir>` (REDkit), which also acts as the compile check. Blobs from REDkit build 1042178 load in game builds 1041720 (5.0) and 1044392 (5.0 hotfix).
- From a community source (unverified here): a blob's changes take precedence over other mods' loose scripts for the same function, whatever the priority in `mods.settings`.

So write scripts so they work in a blob, and use `--loose` builds only for experiments.

### Scope-based overrides (5.0)

Re-declare an existing class (or state) in a new file with **exactly its vanilla header**, and list only what to add or change. The game merges it into the vanilla class. **Verified** (pilot slice 2):

```ws
// Header copied from vanilla: "statemachine class W3PlayerWitcher extends CR4Player".
statemachine class W3PlayerWitcher extends CR4Player
{
	// New field and new method.
	var gmScopeOverrideCalls : int;

	public function GMScopeAdded() : string
	{
		return "OK";
	}

	// Override an existing method: replaces the vanilla body.
	public function GetCannotUseUndying() : bool
	{
		gmScopeOverrideCalls += 1;
		return cannotUseUndyingSkill;
	}

	// Change an existing default value (vanilla: 0.5f).
	default _HoldBeforeOpenRadialMenuTime = 0.51f;
}

// Enum extension: add members to a vanilla enum.
enum EEffectType
{
	EET_GMPilotEffect
}
```

Rules:

- The header must match the vanilla declaration: the same `statemachine`, `abstract` and `extends`. Otherwise: "Base class mismatch. Class 'W3PlayerWitcher' specifies no base but its previous definition uses 'CR4Player'", or "Previous definition of 'W3PlayerWitcher' is a state machine".
- An overriding method must keep the vanilla kind and signature: event stays event, latent stays latent, same return type. Timer and `final` functions cannot be overridden. The compiler names the mismatch.
- New enum members **must not have explicit values** (the compiler forbids them for mods, to prevent clashes between mods). Their numbers come after the vanilla members.
- States are re-declared with their vanilla header too, e.g. `state CombatFists in W3PlayerWitcher extends Combat { ... }` (compiles; not yet tested in game).
- If several mods override the same function or enum, the mod with the higher priority wins (community source; unverified here).

### Annotations

Annotations (added in patch 4.04, extended in 5.0) are declared outside any class, in a new file:

```ws
// Add a field to an existing class.
@addField(CR4Player)
public var gmPilotSpawns : int;

// Add a method to an existing class.
@addMethod(CR4Player)
function GMPilotSpawns() : int
{
	return gmPilotSpawns;
}

// Wrap an existing method: runs instead of it, and must call wrappedMethod(...)
// to run the original (and any other mods' wrappers).
@wrapMethod(CR4Player)
function OnSpawned(spawnData : SEntitySpawnData)
{
	wrappedMethod(spawnData);
	gmPilotSpawns += 1;
}

// Wrap a state's function: address the state by its internal class name,
// <state machine class>State<state name>. Inside, "parent" is the state machine.
@wrapMethod(CR4PlayerStateExploration)
function OnEnterState( prevStateName : name )
{
	parent.GMPilotCount('state');
	wrappedMethod(prevStateName);
}

// Replace a class method entirely.
@replaceMethod(CR4Player)
function GetSubmergeDepth() : float
{
	return submergeDepth;
}

// Replace a global function: no parentheses after the annotation.
@replaceMethod
function IsAutohealEnabled() : bool
{
	...
}
```

All of these are **verified** (pilot slices 1–2): `@addField`, `@addMethod`, `@wrapMethod` on an event and on a state event, `@replaceMethod` on a class method and on a global function.

Rules (from testing and the compiler's messages in `witcher3.exe`):

- The target class must exist, and the method must be **defined in that class**: "cannot wrap '%s' because it is a definition inherited from '%s'". Annotate the class that declares the method, not a subclass that inherits it.
- States: `@wrapMethod(CombatFists)` fails ("class 'CombatFists' is not defined"); use the internal name `W3PlayerWitcherStateCombatFists`.
- A wrapper must contain the `wrappedMethod` token and cannot be empty.
- `@replaceMethod` cannot replace native functions, native class functions or imports (`import function ...` in the vanilla scripts).
- Wrapping **native** functions: the 5.0 changelog says it is now possible, but the executable also contains "cannot wrap '%s' because it is native (only allowed in modio mods)". **Unverified**, and probably limited to mods installed through mod.io.

### Choosing a technique

| Change | Use |
|---|---|
| Add behaviour before or after a vanilla method (adjust arguments or the return value, add side effects) | `@wrapMethod`. Several mods can wrap the same method, so it is the most compatible. Prefer it. |
| Change logic in the middle of a vanilla method | Override it: in the class's scope-based override block, or with `@replaceMethod`. Copy the **5.x** body (from `vanilla-5.x`), apply the change, mark the changed lines with `//modSigns`. Only one mod's version can win, and CDPR updates to that method must be merged by hand, so keep overridden methods few and small. |
| Change a global function | `@replaceMethod` (scope-based overrides cover classes and states) |
| New fields, methods and changed `default` values on a vanilla class | The class's scope-based override block (or `@addField`/`@addMethod`) |
| New effect types, item categories and other enum members | Enum extension |
| New classes, structs and global functions | Declare them in a new file |

Prefer **one file per vanilla class or system** that Ghost Mode changes, holding the scope-based override block and any annotations for it, each tagged with feature IDs. Shipping a whole edited copy of a vanilla script still works (in a blob it acts as an override of everything in the file), but it brings back the merge problem for no benefit; list only the changed members instead.

### WitcherScript rules learned along the way

- **Fields of another object cannot be assigned from outside its class**, even `public` ones: `thePlayer.gmCounter += 1` fails with "Expected type 'Int32' to be assignable". Reading works. To change another object's field, give its class a method (`@addMethod`) and call that.
- Fields default to private; declare fields that other code reads as `public`.
- **A struct field cannot be read straight off a function's return value**: `GetAttr(...).valueAdditive` fails with "Cannot access struct property ... Parent scope does not come from variable". Assign the result to a local first.
- Fields are not stored in saves unless declared `saved`. A `saved` field changes what saves contain, so record the save impact.

Unanswered questions about scripts (how several mods' blobs merge, wrap plus override of one method, struct fields, native functions) are tracked in [open-questions.md](open-questions.md).

### Other mods and vanilla code

- Never wrap or replace a method just to read a value: add a getter with `@addMethod` instead.
- Legacy Ghost Mode code calls helpers from Shared Imports and Community Patch – Base. Shared Imports is built into 5.x; check whether a Community Patch helper exists in 5.x before porting code that uses it. See [legacy-ghost-mode.md](legacy-ghost-mode.md#dependencies).

## XML and CSV

### Fine-grained XML overrides (5.0)

5.0 lets a DLC redefine existing XML entries, or individual fields of them, with an **`on_conflict`** attribute on the entry. **Verified** (pilot slice 3b, 2026-10-01). The 5.0 REDkit changelog writes it `onConflict`, but the game ignores that spelling; the attribute name in `witcher3.exe` is `on_conflict`.

| `on_conflict` | Effect | Verified |
|---|---|---|
| *(none)* | Error on redefinition (per the changelog) | no |
| `extend` | The entry's sub-nodes listed in the DLC replace the matching vanilla ones; all other sub-nodes are kept | yes: `sword_s1` with only `stamina_cost_per_sec` changed that value and kept `focus_cost_per_sec_initial`, `cost_reduction` and `stamina_delay` |
| `replace` | The DLC's entry replaces the vanilla one completely; sub-nodes it does not list are gone | yes: `sword_s2` with only `stamina_cost_per_sec` lost its other attributes (they read 0) |

**New Game+:** the `*_plus` siblings of definition folders (`abilities_plus/`, `items_plus/`, ...) are the New Game+ variants. Make every change in the regular folder, and the corresponding change in the `*_plus` counterpart: numbers scaled the way vanilla scales them from NG to NG+ (GM NG+ = vanilla NG+ × GM NG ÷ vanilla NG; edge cases in [feature-mapping.md](feature-mapping.md#ng-numbers)), everything else the same. NG+ is neither balanced nor tested (see [feature-mapping.md](feature-mapping.md#new-game-carried-over-and-scaled-not-balanced-or-tested)). In the in-game check, test the regular game only. Whether one DLC override also covers the NG+ definition of the same entry is an [open question](open-questions.md).

This is how Ghost Mode's XML changes are ported: Ghost Mode's DLC contains only the entries it changes, with `on_conflict="extend"` and only the changed sub-nodes, instead of a full copy of files like `geralt_skills.xml`. Use `replace` only when Ghost Mode removes sub-nodes or rewrites an entry wholesale. Entries Ghost Mode adds are plain new entries (no attribute).

```xml
<?xml version="1.0" encoding="UTF-8"?>
<redxml>
  <definitions>
    <abilities>
      <!-- SKL-12: Ghost Mode value for a sword skill -->
      <ability name="sword_s1" on_conflict="extend">
        <stamina_cost_per_sec type="add" min="78" />
      </ability>
    </abilities>
  </definitions>
</redxml>
```

Each of the DLC's XML files (or folders) is registered with a `CR4DefinitionsDLCMounter` in its `.reddlc` file (see [DLC and mounters](#dlc-and-mounters)). XML files are UTF-8 with BOM, like the 5.0 originals.

How `extend` matches sub-nodes that occur more than once (several `<a>` in `<base_abilities>`), whether it can remove a sub-node, and whether it works for every definition type Ghost Mode changes are [open questions](open-questions.md).

### CSV

Some CSVs can be mounted from a DLC (e.g. quest levels through `CR4QuestDLCMounter.questLevelsFilePath`). Whether a mounted CSV overrides vanilla rows or only adds rows is **unverified**. Otherwise, ship a whole-file override.

## DLC and mounters

A DLC is a folder under `dlc\<name>\` with a `.reddlc` file (a CR2W `CDLCDefinition`; `tools/cr2w_dump.py` reads it) that lists **mounters**. Mounters tell the engine where the DLC's files are and attach them to the game. They are the conflict-free way to add things to base-game content. Mounters relevant to Ghost Mode:

| Mounter | What it does | Possible Ghost Mode use |
|---|---|---|
| `CR4DefinitionsDLCMounter` | Loads a definitions XML | All XML overrides |
| `CR4EntityTemplateParamDLCMounter` | Adds parameters to entity templates at given paths | Adding abilities or stats to enemies without editing `.w2ent` files (e.g. the tournament contestants' `sq701_tournament_npcs` ability) |
| `CR4EntityTemplateSlotDLCMounter`, `CR4DefinitionsEntitieTemplatesDLCMounter` | Slots / entity template folders | If Ghost Mode needs new entities |
| `CR4JournalEntriesDLCMounter`, `CR4JournalDLCMounter` | Journal entries | Bestiary "use against" changes |
| `CR4RewardsDLCMounter` | Rewards XML | Quest reward changes |
| `CR4QuestDLCMounter` | Starts a quest; also takes scene voice tags and quest levels CSVs | Quest level changes |
| `CGameplayDLCMounterScripted` | Scriptable mounter | Script-side setup when the DLC mounts |

Full list: [REDkit wiki: DLC Mods](https://cdprojektred.atlassian.net/wiki/spaces/W3REDkit/pages/6328346/DLC+Mods). 5.0 added more ("e.g. the LoadingScreenDLCMounter", undocumented). `r4data\dlc\*\*.reddlc` in the REDkit install are working examples (`python tools/cr2w_dump.py "<REDkit>\r4data\dlc\dlc10\dlc10.reddlc"`).

Write `.reddlc` files with `tools/make_reddlc.py` (`--id`, one `--xml` per definitions file or folder; its `--selftest` rebuilds vanilla `dlc8.reddlc` byte for byte). It sets the DLC as hidden from the DLC menu and **not required by saves**, so removing the mod does not make saves unloadable. A DLC packed in a mod's bundle (under `<game>\mods\`) is found and enabled by the game (verified, pilot slice 3b: `IsDLCAvailable('dlc_ghostmode')` and `IsDLCEnabled` both true). REDkit can also create them in its editor.

## Binary resources

See [binary-files.md](binary-files.md). Before editing a `.w2ent`, check whether a mounter can do the same job. Edits that remain are made in the REDkit editor on the 5.x file (REDkit workspace: check out the file, edit, save).

## Localization

**Verified** (pilot slice 4, 2026-10-01). A mod's strings ship as `content\<lang>.w3strings` next to its script blob and bundle; the game loads them without registration.

- **Source:** CSV files in the community encoder's format, `modGhostMode/localization/<table>/<lang>.csv` (the legacy layout; legacy Ghost Mode has the tables `modGhostMode` and `modGMTutorials`):

  ```
  ;meta[language=en]
  ; id      |key(hex)|key(str)| text
  2110992001|        |panel_ghost_mode|Ghost Mode
  ```

  Leave `key(hex)` empty; it is computed from `key(str)`.
- **Build:** `tools/build_mod.py` merges every table per language and encodes `<lang>.w3strings` with `tools/w3strings.py` (format version 164: UTF-8). The community w3strings encoder writes the legacy format (version 162, UTF-16) and is not used.
- **Lookup:** scripts find a string by key (`GetLocStringByKeyExt("panel_ghost_mode")`) or by id (`GetLocStringById(2110992001)`).
- **IDs:** Ghost Mode keeps its legacy IDs, **2110992000–2110992999** (the community encoder's ID space 992). They are inside the range REDkit allows for mods (10,000,000 to `0x7FFFFFFF - 1000`) and far above the vanilla IDs (97,959–1,482,499 in 5.0). New strings take the next free number in this range.
- **Overriding vanilla text:** a row with a vanilla string's id replaces that string. If the vanilla string has a key, repeat the key in the row too: lookups by key otherwise still find the vanilla text. (Legacy `modGMTutorials` rewrites vanilla tutorial strings this way.) Find a vanilla string's id and key by decoding the game's table: `python tools/w3strings.py decode "<game>\content\content0\en.w3strings" en.csv` (key names are not stored, only their hashes; `w3strings.key_hash()` computes one).
- **Languages:** one CSV per language (`en`, `pl`, `de`, ... as the game names its tables). What the game shows in a language for which the mod has no table is an [open question](open-questions.md).

## Options menu

**Verified** (pilot slice 5, 2026-10-01). Ghost Mode's settings appear under Options → Mods, defined by XML and read by scripts through the in-game config system.

- **Source:** `modGhostMode/menu/<file>.xml` (UTF-8 with BOM, like the game's own menu files). Format, as in legacy Ghost Mode's `modSignsConfig.xml`:

  ```xml
  <UserConfig>
  	<Group id="GMPilot" displayName="Mods.gm_pilot">
  		<VisibleVars>
  			<Var id="GMPilotToggle" displayName="gm_pilot_toggle" displayType="TOGGLE"/>
  		</VisibleVars>
  	</Group>
  </UserConfig>
  ```

  Other `displayType`s: `OPTIONS` (with an `<OptionsArray>`), `SLIDER;min;max;steps`, `SUBTLE_SEPARATOR`; groups can have a `<PresetsArray>`. The game's own files in `<game>\bin\config\r4game\user_config_matrix\pc\` are working examples.
- **Install:** the game reads every `*.xml` in `<game>\bin\config\r4game\user_config_matrix\pc\` (the folder comes from `MatrixPath` in `bin\config\r4game\ingameconfig.ini`). No list file needs editing; legacy `dx11filelist.txt` does not exist in 5.x. Menu files cannot live in the mod folder, so `tools/build_mod.py --install` copies them there and records them for removal on the next install.
- **Menu tree:** a group's `displayName` is a dotted path. `Mods.<name>` puts the group under the game's own Options → Mods entry (its label `panel_mods` is vanilla).
- **Labels** are string keys in Ghost Mode's string table: `panel_<segment>` for each path segment (`panel_gm_pilot`), `option_<displayName>` for a variable (`option_gm_pilot_toggle`), `preset_value_<name>` for option and preset values.
- **Reading a value:** `theGame.GetInGameConfigWrapper().GetVarValue('GMPilot', 'GMPilotToggle')` returns a string (`"true"`, `"2"`, ...). A variable that was never set returns `""`, so scripts must treat an empty value as the default (legacy Ghost Mode set its defaults in script).
- **Storage:** values are saved in `Documents\The Witcher 3\dx12user.settings`, one `[<group id>]` section per group. (`user.settings` is the legacy file; 5.x does not read it.)
- **Testing:** `modAutomation`'s `autoconfig("<group id>")` lists a group's variables with labels, types, values and visibility, and `autoconfigset("<group id>", "<var id>", "<value>")` sets and saves one (see [game-automation.md](game-automation.md)). These check registration, labels and reading without opening the menu.

## Build, compile, install

```bash
python tools/build_mod.py --ref <branch>                      # build and compile into build/
python tools/build_mod.py --ref <branch> --install            # and copy into <game>\mods\modGhostMode
python tools/build_mod.py --ref <branch> --install --enable   # and add it to mods.settings if missing
```

- **Collect:** takes every script `<branch>` adds or changes relative to `vanilla-5.x` into `build/scripts/`, every other game file it adds or changes under `modGhostMode/files/` into `build/files/` (at its depot path), every CSV under `modGhostMode/localization/` and every XML under `modGhostMode/menu/`. Anything else stops the build.
- **Strings:** the CSVs are merged per language and encoded to `<lang>.w3strings` with `tools/w3strings.py`; an id used twice in one language stops the build.
- **Compile:** runs REDkit's `wcc_lite compilescripts <game scripts> -patch=build/scripts` (about 20 seconds). Errors are printed with file and line; the full log is `build/compile.log`. A failed compile stops the build, so compile errors never reach the game.
- **Pack:** `wcc_lite pack -compression=ZLIB` packs `build/files/` into `blob0.bundle`, and `wcc_lite metadatastore` writes `metadata.store` next to it (logs: `build/pack.log`, `build/metadatastore.log`). **Verified** (pilot slice 3a): the game loads a mod bundle installed this way, and its files replace the vanilla ones.
- **Assemble:** the mod is `build/modGhostMode/content/` with `precompiled.rsblob` (see [How the game loads mod scripts](#how-the-game-loads-mod-scripts)) plus `blob0.bundle`, `metadata.store` and the `<lang>.w3strings` files. `--loose` ships the loose scripts instead, for experiments only; `--loose --no-compile` skips the compiler.
- **Install:** copies the mod into `<game>\mods\modGhostMode`, replacing only a folder this script installed earlier, and the menu XML into `<game>\bin\config\r4game\user_config_matrix\pc\` (recorded in the mod folder's `.built-by-build_mod`, so the next install removes stale ones; it never overwrites a file it did not install).
- **Verified** (pilot slices 1–2): the game loads and runs a mod installed this way, with a `[modGhostMode]` entry in `mods.settings`. That mods also load without an entry is from the wiki and not tested.
- **Enable:** mods in `<game>\mods` are enabled by default and load alphabetically. `Documents\The Witcher 3\mods.settings` (`[modName]`, `Enabled=0/1`, `Priority=1..9999`) overrides that. Mod folder names must start with `mod`. Documents may be redirected (e.g. to OneDrive); the script resolves it.

Automated game runs (launch, load a save, run exec functions, quit) are described in [game-automation.md](game-automation.md).

## Testing in game

- **Automated runs:** `python tools/game.py run`, then `python tools/game.py exec "<call>"` and `python tools/game.py quit` launch the game, load the newest save, run exec functions (printing their output) and exit, about 30 s in all, with no key presses. Needs the test-only `modAutomation` and rw3d_cli; see [game-automation.md](game-automation.md).
- **Console:** `DBGConsoleOn=true` in `<game>\bin\config\base\general.ini` (**verified**; set on this machine). A Steam "verify files" may reset it. Open with `~`; Ctrl+V pastes.
- **Exec functions** are the quickest probes: `exec function gmsomething() { thePlayer.DisplayHudMessage("..."); }`, then type `gmsomething()` in the console.
- **Script log:** start the game with `-debugscripts` (`tools/game.py` does) to get `LogChannel` output in `Documents\The Witcher 3\scriptslog.txt`, written live and rewritten at each start. **Verified** on 5.0. The console does not show `LogChannel` output; rw3d_cli `exec` prints it.
- **Compile errors at game start** show a "Script Compilation Errors" window with file and line. With a blob they should not happen, since the build compiled it. If one appears, the game and `wcc_lite` disagree; record the case here.
- **A console command that does nothing** usually means the script was not loaded at all (e.g. loose scripts next to a blob), not that it failed.
- **Saves:** test with a new game or a dedicated test save. Do not overwrite personal saves with a test build. Legacy Ghost Mode needed `cleardevelop` (console) for existing characters; see [save compatibility](feature-mapping.md#save-compatibility).
- **REDkit's Script Studio** can attach to the game for breakpoints and hot reload (when the game is started from the editor). Not set up yet.

## References

- [REDkit wiki](https://cdprojektred.atlassian.net/wiki/spaces/W3REDkit/pages/6324268/General+information), in particular the [Changelog](https://cdprojektred.atlassian.net/wiki/spaces/W3REDkit/pages/12058625/Changelog) (5.0 modding features), [WS: Script Compilation Errors overrides](https://cdprojektred.atlassian.net/wiki/spaces/W3REDkit/pages/36241598/WS:+Script+Compilation+Errors+overrides) (annotations), [Managing mods](https://cdprojektred.atlassian.net/wiki/spaces/W3REDkit/pages/36339714/Managing+mods), [DLC Mods](https://cdprojektred.atlassian.net/wiki/spaces/W3REDkit/pages/6328346/DLC+Mods), [Publishing mods](https://cdprojektred.atlassian.net/wiki/spaces/W3REDkit/pages/6328254/Publishing+mods), [WS: Language Guide](https://cdprojektred.atlassian.net/wiki/spaces/W3REDkit/pages/36307090/WS:+Language+Guide). The wiki pages render with JavaScript; their text can be fetched from the Confluence REST API, e.g. `https://cdprojektred.atlassian.net/wiki/rest/api/content/<page id>?expand=body.view`.
- [modSaveNames](https://github.com/MajaAgent/modSaveNames): a small 5.0 script mod built only from annotations, verified in game by its author. Useful syntax examples.
