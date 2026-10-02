# Open questions

Questions about modding 5.x that are not answered yet, with why they matter and how to answer them. Questions a planned pilot slice will answer are listed under that slice in [feature-mapping.md](feature-mapping.md#pilot) instead.

When a question is answered, move the answer into the doc it belongs to (usually [development.md](development.md)), and delete the entry here, noting where the answer went in the commit message.

## Several mods with script blobs

**How does the game merge the script blobs (`precompiled.rsblob`) of several mods?**

Each blob is compiled against the vanilla scripts only, so blobs are built without knowing about each other and the game must merge them at startup. What we have:

- The executable names wrappers `%s@%s@wrapper%03d` and has a "maxWrapping index reached" error, so `@wrapMethod` wrappers from several mods most likely chain.
- It reports "@replaceMethod duplicate found for '%s'"; unclear whether that is an error or last-one-wins between separate mods.
- Mods may not give new enum members explicit values, which suggests the game numbers them at load time.
- Two blob mods that wrap *different* methods load together and both work (`modAutomation` plus the pilot build, [game-automation.md](game-automation.md#two-script-blobs)).
- Community claims (untested): when several mods override the same function or enum with scope-based overrides, the mod with the highest priority in `mods.settings` wins outright; and a blob's change beats other mods' loose scripts for the same function, whatever the priority.

**Why it matters:** if overrides are winner-take-all, any other mod overriding a function Ghost Mode overrides silently drops one of the two changes. That decides how strongly to prefer `@wrapMethod` over overrides, and what priority Ghost Mode should recommend. It also decides what "higher priority" means in `mods.settings` (lower or higher number).

**How to answer:** two throwaway blob mods (`modGMTestA`, `modGMTestB`) that clash on purpose: both wrap the same method (do both run, in what order?), both override the same method in a scope block (which wins; does swapping their priorities flip it?), both add an enum member (distinct values, no error?). One build, two game launches (one per priority order); `tools/game.py` makes each launch a short scripted run.

## Scripts

- **Wrap and override of the same method in one mod.** Does a `@wrapMethod` apply on top of a scope-based override of the same method in the same mod, and in which order? It compiles. Matters when one Ghost Mode feature overrides a method and another wraps it.
- **Struct fields.** Can a blob add fields to a vanilla struct (re-declaring the struct, like a class)? Loose scripts reject it ("already exported and 'isMod' is false").
- **State overrides in game.** A scope-based override of a state (`state CombatFists in W3PlayerWitcher extends Combat { ... }`) compiles; not yet run in game. Wrapping a state function is verified.
- **Native functions.** The 5.0 changelog says native functions can be wrapped, but the executable also says "cannot wrap '%s' because it is native (only allowed in modio mods)". Test once Ghost Mode needs to wrap a native function.

## Install and testing

- **Mods without a `mods.settings` entry.** The wiki says mods in `<game>\mods` are enabled by default; ours has always had an entry. Test by removing the entry once.

## Localization

- **Languages without a mod table.** If Ghost Mode ships only some languages, what does the game show in the others: the English string, nothing, or a placeholder? Legacy Ghost Mode shipped br, cz, de, en, es, fr, it, pl and ru for its main table. Test by switching the game to a language the pilot has no table for.

## XML and other data

- **Mounted CSV.** Does a CSV mounted from a DLC (e.g. quest levels through `CR4QuestDLCMounter.questLevelsFilePath`) override vanilla rows, or only add rows? Matters for porting Ghost Mode's `quest_levels.csv` changes.
- **`on_conflict` coverage.** Basic `extend` and `replace` work on abilities (pilot slice 3b). Open: does it work for every definition type Ghost Mode changes (items, loot, recipes, effects, ...); how does `extend` match sub-nodes that occur more than once (several `<a>` in `<base_abilities>`, several `<parts>` in `<recycling_parts>`); can attributes on the entry element itself (an item's `price`, `weight`) be extended; can a sub-node be removed without `replace`? Test each when the first feature needs it.
- **NG+ and DLC overrides.** Does one DLC override of an entry (e.g. `sword_s1`) also change the New Game+ definition of the same entry (from `abilities_plus/`), or does NG+ need its own override? NG+ is not tested in game (see [feature-mapping.md](feature-mapping.md#new-game-carried-over-and-scaled-not-balanced-or-tested)), so this can only be settled by reading how NG+ loads its definitions, or by a quick probe in an NG+ save if one exists. Until then, assume NG+ needs its own override.
