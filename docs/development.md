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
- **Both skill trees.** Code that depends on a skill handles the classic tree's skill and the new tree's counterpart (e.g. Whirl `S_Sword_s01` and `S_Sword_s35`): read the one the player has equipped instead of hard-coding either; for a shared skill (one definition for both trees) special-case on the tree in use (5.x's setting `RemasterCombat`/`UseLegacySkillTree`) where the rules differ. XML changes to skill abilities cover both skills. See [feature-mapping.md](feature-mapping.md#two-skill-trees).
- **Tag every override with its feature ID** in a comment above it: `// STAM-01: stamina cost for light attacks`.
- **In overridden methods and whole-file overrides, mark each changed line or block with `//modSigns`**, the legacy Ghost Mode marker, so changes against the vanilla body stay findable and the tooling can count them.
- **Commit messages** name the feature IDs and the save impact when it is not `none`.
- **No absolute paths in the repository** (tools, docs, any branch): they expose details of a contributor's machine and break on anyone else's. Tools find install folders with `tools/paths.py` (Steam lookup, or the `W3_GAME_DIR` / `W3_REDKIT_DIR` environment variables) and refer to repository files relative to the script; docs write `<game>`, `<REDkit>`, `<Wwise>`, relative paths such as `../TGM-5x-GM`, or environment variables such as `%ProgramFiles(x86)%`.
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

- Defaults of **behaviour-tree task definitions** (`...Def` classes) can be changed the same way, also for fields they inherit: `class CBTTaskAttackDef extends CBTTaskPlayAnimationEventDecoratorDef { default xmlStaminaCostName = 'light_action_stamina_cost'; }` gives every tree's attack task that cost unless the tree sets its own (trees store only non-default values). **Verified** (STAM-08). Abstract classes keep `abstract` in the header.
- `import` classes can be overridden the same way, header included: `import class W3GameParams extends CObject { default HEAVY_STRIKE_COST_MULTIPLIER = 1.25; }` changes the constant (**verified**, STAM-03).
- The header must match the vanilla declaration: the same `statemachine`, `abstract` and `extends`. Otherwise: "Base class mismatch. Class 'W3PlayerWitcher' specifies no base but its previous definition uses 'CR4Player'", or "Previous definition of 'W3PlayerWitcher' is a state machine".
- An overriding method must keep the vanilla kind and signature: event stays event, latent stays latent, same return type. Timer and `final` functions cannot be overridden. The compiler names the mismatch.
- New enum members **must not have explicit values** (the compiler forbids them for mods, to prevent clashes between mods). Their numbers come after the vanilla members.
- States are re-declared with their vanilla header too, e.g. `state CombatFists in W3PlayerWitcher extends Combat { ... }` (compiles; not yet tested in game).
- **A scope-based override and a `@wrapMethod` of the same method, in one mod, both apply** (**verified**: `W3Effect_AutoStaminaRegen.OnUpdate` is overridden for STAM-04's regen rates and wrapped for STAM-07's heartbeat and STAM-08's NPC rules, and all three work in game). So one feature can override a method another feature wraps. Presumably the wrapper wraps the overriding body (unverified).
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

- **A wrapper can stack on a replaced method:** `@replaceMethod(CR4Player) PerformParryCheck` plus a `@wrapMethod` on the subclass override that calls it via `super` both run (STAM-03).
- **A wrapper on a state's `entry` function compiles but never runs** (STAM-02: `W3PlayerWitcherStateCombatSword.PerformSpecialAttackLight`). Wrap the event or function that calls it instead.
- `@wrapMethod` works on `final` and `private` methods (**verified**, STAM-05: `W3PlayerWitcher.CalculatedArmorStaminaRegenBonus`, `CInventoryComponent.GetItemTooltipAttributes`), although a scope-based override cannot override a `final` one.
- The target class must exist, and the method must be **defined in that class**: "cannot wrap '%s' because it is a definition inherited from '%s'". Annotate the class that declares the method, not a subclass that inherits it.
- States: `@wrapMethod(CombatFists)` fails ("class 'CombatFists' is not defined"); use the internal name `W3PlayerWitcherStateCombatFists`.
- A wrapper must contain the `wrappedMethod` token and cannot be empty.
- A method added with `@addMethod` can itself be wrapped (e.g. by test code in another file). **Verified** (STAM-08).
- **`@replaceMethod` of a timer function: declare it without `timer`** (`@replaceMethod(W3PlayerWitcher) function SpecialAttackLightSustainCost(dt : float, id : int)`); with the keyword the compiler stops at a syntax error. Timers added by name (`AddTimer('SpecialAttackLightSustainCost', ...)`) then run the replacement (**verified**, STAM-09). Scope-based overrides still cannot override timers.
- **Wrapping a latent function: declare the wrapper without `latent`** (`@wrapMethod(W3VehicleCombatManagerStateSwordAttack) function DoAttack()`); with the keyword the compiler stops at a syntax error. The wrapper runs, including the latent original (**verified**, STAM-03 horseback). Inside such a wrapper, `return wrappedMethod();` fails ("latent calls not allowed in return statement"): store the result in a local first.
- **A wrapper may call `wrappedMethod` only once**: a second call (e.g. one in an early-return branch and one at the end) fails to compile with "Could not find function 'wrappedMethod'" at the second call (**verified** 2026-10-03). Compute what the branches need, call `wrappedMethod` once, then branch on the result. A wrapper must contain the call (it does not compile without it, as the REDkit wiki says), but a branch may return before reaching it. Not documented by CDPR; the error suggests the compiler resolves the identifier `wrappedMethod` to the wrapped method only once.
- **Several `@wrapMethod`s of one method all run**, also from different files: each wraps the next (**verified** 2026-10-03: a second wrapper of `W3AbilityManager.GetStaminaActionCost` ran once per call, and STAM-03's wrapper still applied its cost). So each feature wraps what it needs, even a method another feature already wraps; it need not hook into the other feature's wrapper. (STAM-07's calls still sit in STAM-08's `DrainStamina` and regen wrappers, from before this was known.)
- `@addMethod` can add an **event** to a class (`@addMethod(W3VehicleCombatManager) event OnAttack(action : SInputAction) {}`); a state of that class that defines the event still handles it (**verified**, test code for STAM-03 horseback).
- `@replaceMethod` cannot replace native functions, native class functions or imports (`import function ...` in the vanilla scripts).
- Wrapping a **global** function: `@wrapMethod` without a class (e.g. on `EffectTypeToName`) is **verified** (STAM-01, 2026-10-02).
- Wrapping **native** functions: the 5.0 changelog says it is now possible, but the executable also contains "cannot wrap '%s' because it is native (only allowed in modio mods)". **Unverified**, and probably limited to mods installed through mod.io.

### Adding effect types

New buffs and debuffs (cooldowns, potion effects, ...) need a new `EEffectType` member, an effect class and registration. **Verified** (STAM-01):

- Add the members with an **enum extension** in `scripts/local/gm/effects/gmEffectTypes.ws`, and keep `GMLastEffectType()` pointing at the last one.
- **Pitfall:** mod enum members come after the vanilla `EET_EffectTypesSize`, but `W3GameEffectManager.Initialize` sizes its effect array to `EET_EffectTypesSize`. `gmEffectRegistration.ws` wraps `Initialize` and grows the array; without that, the new effects index past its end. Vanilla loops up to `EET_EffectTypesSize` (immunities, Quen) simply skip mod effects.
- Register each type in `gmEffectRegistration.ws`: create the object in the wrapped `W3GameEffectManager.HACK_NO_MEMORY_TO_COMPILE_CacheEffect_Part1`, and map name and type in the wrapped global functions `HACK_NO_MEMORY_TO_COMPILE_EffectNameToType_Part1` and `EffectTypeToName`.
- An effect works without XML (5.x's own `EET_OverloadCooldown` has none): it then has no HUD icon or label. Override `CalculateDuration` to set the duration in script.
- Effect names follow the vanilla pattern `<Name>Effect`, with the `GM` prefix: `GMAardCooldownEffect`.

### Choosing a technique

| Change | Use |
|---|---|
| Add behaviour before or after a vanilla method (adjust arguments or the return value, add side effects) | `@wrapMethod`. Several mods can wrap the same method, so it is the most compatible. Prefer it. |
| Change logic in the middle of a vanilla method | Override it: in the class's scope-based override block, or with `@replaceMethod`. Copy the **5.x** body (from `vanilla-5.x`), apply the change, mark the changed lines with `//modSigns`. Only one mod's version can win, and CDPR updates to that method must be merged by hand, so keep overridden methods few and small. |
| Change a global function | `@replaceMethod` (scope-based overrides cover classes and states) |
| Change a value a vanilla UI function puts into a flash object (character panel lines, ...) | `@wrapMethod` the function, let it build the object, then overwrite the member (`statObject.SetMemberFlashString("value", ...)`) |
| New fields, methods and changed `default` values on a vanilla class | The class's scope-based override block (or `@addField`/`@addMethod`) |
| New effect types, item categories and other enum members | Enum extension |
| New classes, structs and global functions | Declare them in a new file |

Prefer **one file per vanilla class or system** that Ghost Mode changes, holding the scope-based override block and any annotations for it, each tagged with feature IDs. Shipping a whole edited copy of a vanilla script still works (in a blob it acts as an override of everything in the file), but it brings back the merge problem for no benefit; list only the changed members instead.

### WitcherScript rules learned along the way

- **Fields of another object cannot be assigned from outside its class**, even `public` ones: `thePlayer.gmCounter += 1` fails with "Expected type 'Int32' to be assignable". Reading works. To change another object's field, give its class a method (`@addMethod`) and call that.
- Fields default to private; declare fields that other code reads as `public`.
- **Exec functions cannot be called from scripts** ("Cannot call exec function ... from scripts instead of the console"). Put shared test code in a plain function and make the exec function a one-line wrapper (`exec function gmtest_stam07() { GMTest_stam07(); }`), as `gmtest_regress()` does.
- **A struct field cannot be read straight off a function's return value**: `GetAttr(...).valueAdditive` fails with "Cannot access struct property ... Parent scope does not come from variable". Assign the result to a local first.
- **`import const` struct fields can be set on a local variable.** `SInputAction` declares its fields `import const var`, yet `action.value = 1;` compiles and works, so a script can build an input action and call an input event with it (see [Input simulation](game-automation.md#input-simulation)). Calling another object's event directly (`thePlayer.GetInputHandler().OnCastSign(action)`) works too.
- **Wrap where a state is left, not where it "ends", when every exit matters.** A sign can leave its casting state through `OnEnded` or `OnSignAborted` (e.g. `DrainStamina` aborts the current sign at 0 stamina); a wrapper on one of them misses the other. A wrapper on the state's `OnLeaveState` sees all exits. If the state has no `OnLeaveState` of its own, wrap its base state's and filter on `parent` (STAM-01, Igni).
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

A DLC's definitions XML can also add to the `<custom>` sections that sit next to `<definitions>`, e.g. new `<effects>` and `<effect_icons>` entries for mod effects (**verified**, STAM-01: icons, HUD flag and labels of the sign cooldowns come from `dlc\dlcghostmode\data\gameplay\abilities\gm_effects.xml`). Ghost Mode's DLC mounts the whole `dlc\dlcghostmode\data\gameplay\abilities\` folder; add a mounter per folder as other definition types are ported (`make_reddlc.py --xml` once per folder).

**New Game+:** NG+ reads its definitions from `*_plus` folders, and a DLC adds its own with a `CR4DefinitionsNGPlusDLCMounter` (`make_reddlc.py --xml-ngplus`), as vanilla DLCs mount their `abilities_plus\` and `items_plus\` folders next to `abilities\` and `items\` (same file names). Ghost Mode's DLC mounts `abilities_plus\` with copies of its `abilities\` files that `tools/gen_ngplus.py` generates with the [NG+ rule](feature-mapping.md#ng-numbers); re-run it after changing a file in `abilities\` (`--check` fails when a copy is out of date). In a regular game the NG+ copies are not read (**verified** 2026-10-04: with a build whose NG+ copy gave the wolf a different stamina regen, the regular game used the `abilities\` value). NG+ itself is not tested.

**Repeated tags** (e.g. `ConGeralt` has three `<staminaRegen>` nodes: `add`, `base`, `mult`): `extend` replaces them **in order**: the first `<staminaRegen>` in the override replaces the first one in the vanilla entry, the second the second, and so on; the rest are kept (**verified**, STAM-04). So to change the Nth occurrence, list all occurrences up to it in vanilla order, copying the unchanged ones:

```xml
<ability name="ConGeralt" on_conflict="extend">
  <staminaRegen type="add" always_random="false" min="0" max="0" />     <!-- unchanged -->
  <staminaRegen type="base" always_random="false" min="1" max="1" />    <!-- unchanged -->
  <staminaRegen type="mult" always_random="false" min="0.15" max="0.15" />
</ability>
```

A single `<staminaRegen type="mult">` would have replaced the first node (the `add`) and left the vanilla `mult` in place. Whether `extend` works for every definition type, whether it can set attributes on the entry element itself (an item's `price`) and whether it can remove a sub-node are [open questions](open-questions.md).

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

## Sound banks

A mod ships Wwise banks in `<mod>\content\soundspc.cache`, and scripts load and play them with `theSound.SoundLoadBank("<bank>.bnk", false)`, `theSound.SoundEvent("<event>")` and `theSound.SoundParameter("<game parameter>", value)`. **Verified** (STAM-07, 2026-10-03): the game loaded Ghost Mode's rebuilt heartbeat bank from the mod's cache and played it, with its game parameters and `game_state` muting working. Two conditions:

- **The bank must be built with Wwise 2023.1** (bank version 150; see [game-5.0-changes.md](game-5.0-changes.md#audio)). Legacy banks (version 88) have to be rebuilt; vgmstream (`vgmstream-cli -o out.wav <bank or .wem>`) decodes their audio to WAV, since no Wwise tool exports audio.
- **The cache must be format version 2**, written by `python tools/soundcache.py pack <out>\soundspc.cache <bank> ...` ([tools.md](tools.md#project-tools-tools)). Whether the game still reads legacy's version 1 caches is untested (they hold only version 88 banks anyway).

**Where things live:** the repository holds only the built banks, `modGhostMode/sound/*.bnk` on `5.x-GM`; `tools/build_mod.py` packs them into the mod's `content\soundspc.cache`. The Wwise project, the decoded audio and the WAAPI scripts are kept locally, outside the repository, in a `TGM-audio` folder next to the checkouts (not in git; its README has the rebuild command). Legacy's banks stay recoverable from `legacy-GM` (`tools/soundcache.py extract`, then vgmstream).

**Building a bank without REDkit's editor:**

- Work in a copy of REDkit's audio project (`<REDkit>\assets\w3_audio`) **without** `Originals` (29 GB) and without the work units of the Actor-Mixer, Events, Interactive Music, SoundBanks, Dynamic Dialogue and Soundcaster hierarchies (keep each `Default Work Unit.wwu`); also remove the `Effects` lists from `Audio Devices\Default Work Unit.wwu`. The full project does not generate: it has 26,219 media items against the 200 the free licence allows, and its audio devices use the Mastering Suite, which needs its own licence. The trimmed project keeps the buses, state groups, switches, game parameters and conversion settings, so the bank's references resolve. Wwise IDs are hashes of the names (FNV-1 32-bit, lower case), so the bank refers to the game's own buses and states, e.g. `Gameplay Master Bus` or the `game_state` states.
- Script it through WAAPI: `WwiseConsole.exe waapi-server <project>.wproj --wamp-port <port>` (WwiseConsole is in `<Wwise>\Authoring\x64\Release\bin\`, where `<Wwise>` is the folder the Audiokinetic Launcher installed 2023.1.19.8928 into). Its HTTP endpoint does not start without admin rights (http.sys), so use WAMP over WebSocket; a stdlib-only client is about 60 lines. `ak.wwise.core.audio.import`, `object.create`, `object.set` (`@RTPC`, `@Effects`), `object.setReference` (`OutputBus`, by ID), `object.setStateGroups`, `object.setStateProperties` and `soundbank.setInclusions` cover a simple bank. WAAPI cannot set per-state values: add them to the saved work unit (`<CustomState ...><PropertyList><Property Name="Volume" Type="Real64" Value="-96"/></PropertyList></CustomState>`).
- Generate with `WwiseConsole.exe generate-soundbank <project>.wproj --bank <name> --platform Windows`. REDkit's project writes banks to `..\..\..\r4data\soundbanks\<platform>\`, outside the project folder: in a copy, set the SoundBank paths to `GeneratedSoundBanks\<platform>\` (`--output` sets only the external-sources path).
- **Curve shapes:** WAAPI and the work units call the bank's interpolation 1 (sine, constant-power fade in) `Log2` and 7 (reciprocal sine) `Exp2`; `Sine` and `SineRecip` are rejected. **dB curves** are stored as 10^(dB/20) − 1 below 0 dB and 1 − 10^(−dB/20) above, so a legacy bank's stored value converts back to the dB to author.

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
- **Reading a value:** `theGame.GetInGameConfigWrapper().GetVarValue('GMPilot', 'GMPilotToggle')` returns a string (`"true"`, `"2"`, ...). A variable that was never set returns `""`.
- **Ghost Mode's options** (OPT-01): add each option to `modGhostMode/menu/modGhostMode.xml` (legacy group and variable ids), give it a default in `GMOptionDefault` and an entry in `GMOptionList` (`scripts/local/gm/options/gmOptions.ws`), its label to the string tables, and read it with `GMGetOptionFloat(group, option)`, which falls back to the default while the option is empty. Unset options get their defaults when a save loads (**verified**).
- **Storage:** values are saved in `Documents\The Witcher 3\dx12user.settings`, one `[<group id>]` section per group. (`user.settings` is the legacy file; 5.x does not read it.)
- **Testing:** **`autoconfigset` saves into the player's real `dx12user.settings`**: set changed options back to their defaults (`GMOptionDefault`) after the test, or edit the file while the game is closed. `modAutomation`'s `autoconfig("<group id>")` lists a group's variables with labels, types, values and visibility, and `autoconfigset("<group id>", "<var id>", "<value>")` sets and saves one (see [game-automation.md](game-automation.md)). These check registration, labels and reading without opening the menu.

## Build, compile, install

```bash
python tools/build_mod.py --ref <branch>                      # build and compile into build/
python tools/build_mod.py --ref <branch> --install            # and copy into <game>\mods\modGhostMode
python tools/build_mod.py --ref <branch> --install --enable   # and add it to mods.settings if missing
python tools/build_mod.py --ref <branch> --release            # without the in-game tests: a build to play or publish
```

- **Collect:** takes every script `<branch>` adds or changes relative to `vanilla-5.x` into `build/scripts/`, every other game file it adds or changes under `modGhostMode/files/` into `build/files/` (at its depot path), every CSV under `modGhostMode/localization/`, every XML under `modGhostMode/menu/` and every `.bnk` under `modGhostMode/sound/`. Anything else stops the build. `--release` leaves out the test scripts (`modGhostMode/scripts/local/gm/tests/`); the rest of the mod must not call into them.
- **Strings:** the CSVs are merged per language and encoded to `<lang>.w3strings` with `tools/w3strings.py`; an id used twice in one language stops the build.
- **Compile:** runs REDkit's `wcc_lite compilescripts <game scripts> -patch=build/scripts` (about 20 seconds). Errors are printed with file and line; the full log is `build/compile.log`. A failed compile stops the build, so compile errors never reach the game.
- **Pack:** `wcc_lite pack -compression=ZLIB` packs `build/files/` into `blob0.bundle`, and `wcc_lite metadatastore` writes `metadata.store` next to it (logs: `build/pack.log`, `build/metadatastore.log`). **Verified** (pilot slice 3a): the game loads a mod bundle installed this way, and its files replace the vanilla ones.
- **Assemble:** the mod is `build/modGhostMode/content/` with `precompiled.rsblob` (see [How the game loads mod scripts](#how-the-game-loads-mod-scripts)) plus `blob0.bundle`, `metadata.store`, the `<lang>.w3strings` files and `soundspc.cache` (the banks packed by `tools/soundcache.py`; see [Sound banks](#sound-banks)). `--loose` ships the loose scripts instead, for experiments only; `--loose --no-compile` skips the compiler.
- **Install:** copies the mod into `<game>\mods\modGhostMode`, replacing only a folder this script installed earlier, and the menu XML into `<game>\bin\config\r4game\user_config_matrix\pc\` (recorded in the mod folder's `.built-by-build_mod`, so the next install removes stale ones; it never overwrites a file it did not install).
- **Verified** (pilot slices 1–2): the game loads and runs a mod installed this way, with a `[modGhostMode]` entry in `mods.settings`. That mods also load without an entry is from the wiki and not tested.
- **Enable:** mods in `<game>\mods` are enabled by default and load alphabetically. `Documents\The Witcher 3\mods.settings` (`[modName]`, `Enabled=0/1`, `Priority=1..9999`) overrides that. Mod folder names must start with `mod`. Documents may be redirected (e.g. to OneDrive); the script resolves it.

Automated game runs (launch, load a save, run exec functions, quit) are described in [game-automation.md](game-automation.md).

## Testing in game

- **Automated runs:** `python tools/game.py run`, then `python tools/game.py exec "<call>"` and `python tools/game.py quit` launch the game, load the newest save, run exec functions (printing their output) and exit, about 30 s in all, with no key presses. Needs the test-only `modAutomation` and rw3d_cli; see [game-automation.md](game-automation.md).
- **Console:** `DBGConsoleOn=true` in `<game>\bin\config\base\general.ini` (**verified**; set on this machine). A Steam "verify files" may reset it. Open with `~`; Ctrl+V pastes.
- **In-game test functions** live in `modGhostMode/scripts/local/gm/tests/gmTests.ws`: one `exec function gmtest_<feature>()` per feature, reporting `PASS <check>` / `FAIL <check>` lines with `LogChannel('GMTest', ...)`, so `python tools/game.py exec "gmtest_stam01()"` prints the results. Write them so they run without character actions where possible (e.g. add an effect directly instead of casting). Test-only wrappers (probes that log drains, attacks or NPC decisions) belong in `tests/` and do nothing unless `GMTestProbes()` is on: a test that reads their logs switches them on in its reset, or `gmtest_probes(true)` does; off by default, so a test build plays like a normal one.
- **Both skill trees:** a check that involves a skill runs once with the classic skill and once with the new tree's counterpart; how to switch the tree in a test is in [game-automation.md](game-automation.md#setting-up-geralt-and-the-world).
- **Regression run** (when a feature is finished, one game session, about a minute), on a build with the tests (without `--release`): `python tools/game.py run <save name>`, then `python tools/game.py exec "gmtest_regress()" "ingamemenu()" "gmtest_panel()"`, `python tools/game.py resume` and `quit`. `gmtest_regress()` runs every check that needs no fight, input or menu (each restores what it changes) and logs `SUMMARY regress: N passed, M failed`; the character panel check needs the menu open, so it follows. Long output is cut off by the exec call: read the results from the script log. Add a feature's situation-free checks to `gmtest_regress()` (as a plain `GMTest_<name>()` function) when the feature is finished. 2026-10-03: 167 + 9 checks, all passing.
- **Exec functions** are the quickest probes: `exec function gmsomething() { thePlayer.DisplayHudMessage("..."); }`, then type `gmsomething()` in the console.
- **Script log:** start the game with `-debugscripts` (`tools/game.py` does) to get `LogChannel` output in `Documents\The Witcher 3\scriptslog.txt`, written live and rewritten at each start. **Verified** on 5.0. The console does not show `LogChannel` output; rw3d_cli `exec` prints it.
- **Compile errors at game start** show a "Script Compilation Errors" window with file and line. With a blob they should not happen, since the build compiled it. If one appears, the game and `wcc_lite` disagree; record the case here.
- **A console command that does nothing** usually means the script was not loaded at all (e.g. loose scripts next to a blob), not that it failed.
- **Test save and setup:** load the [test save](game-automation.md#test-saves) (level 1, just past the tutorial) by name, then give Geralt the level, skills, items and enemies a test needs with vanilla exec functions (`setlevel`, `skilleq`, `additem`, `spawn`, ...; see [game-automation.md](game-automation.md#setting-up-geralt-and-the-world)). Read the state back with `modAutomation`'s probes (`autoplayer()`, `autoskills()`, ...): vanilla debug functions log nothing in the release build. Actions that need input (casting, attacking) cannot be triggered from the console yet.
- **Saves:** test with a new game or a dedicated test save. Do not overwrite personal saves with a test build. Legacy Ghost Mode needed `cleardevelop` (console) for existing characters; see [save compatibility](feature-mapping.md#save-compatibility).
- **REDkit's Script Studio** can attach to the game for breakpoints and hot reload (when the game is started from the editor). Not set up yet.

## References

- [REDkit wiki](https://cdprojektred.atlassian.net/wiki/spaces/W3REDkit/pages/6324268/General+information), in particular the [Changelog](https://cdprojektred.atlassian.net/wiki/spaces/W3REDkit/pages/12058625/Changelog) (5.0 modding features), [WS: Script Compilation Errors overrides](https://cdprojektred.atlassian.net/wiki/spaces/W3REDkit/pages/36241598/WS:+Script+Compilation+Errors+overrides) (annotations), [Managing mods](https://cdprojektred.atlassian.net/wiki/spaces/W3REDkit/pages/36339714/Managing+mods), [DLC Mods](https://cdprojektred.atlassian.net/wiki/spaces/W3REDkit/pages/6328346/DLC+Mods), [Publishing mods](https://cdprojektred.atlassian.net/wiki/spaces/W3REDkit/pages/6328254/Publishing+mods), [WS: Language Guide](https://cdprojektred.atlassian.net/wiki/spaces/W3REDkit/pages/36307090/WS:+Language+Guide). The wiki pages render with JavaScript; their text can be fetched from the Confluence REST API, e.g. `https://cdprojektred.atlassian.net/wiki/rest/api/content/<page id>?expand=body.view`.
- [modSaveNames](https://github.com/MajaAgent/modSaveNames): a small 5.0 script mod built only from annotations, verified in game by its author. Useful syntax examples.
