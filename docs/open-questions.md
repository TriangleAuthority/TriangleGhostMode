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

- **Struct fields.** Can a blob add fields to a vanilla struct (re-declaring the struct, like a class)? Loose scripts reject it ("already exported and 'isMod' is false").
- **State overrides in game.** A scope-based override of a state (`state CombatFists in W3PlayerWitcher extends Combat { ... }`) compiles; not yet run in game. Wrapping a state function is verified.
- **Native functions.** The 5.0 changelog says native functions can be wrapped, but the executable also says "cannot wrap '%s' because it is native (only allowed in modio mods)". Test once Ghost Mode needs to wrap a native function.

## Install and testing

- **Mods without a `mods.settings` entry.** The wiki says mods in `<game>\mods` are enabled by default; ours has always had an entry. Test by removing the entry once.

## Localization

- **Languages without a mod table.** If Ghost Mode ships only some languages, what does the game show in the others: the English string, nothing, or a placeholder? Legacy Ghost Mode shipped br, cz, de, en, es, fr, it, pl and ru for its main table. Test by switching the game to a language the pilot has no table for.

## Legacy design intent

<a id="ungated-npc-attacks"></a>
- **Ungated NPC attacks (STAM-08).** Ghost Mode charges every NPC attack (the light-attack cost unless the behaviour tree names another), but an attack is only refused for lack of stamina where its task checks stamina, and some do not, in legacy as in the port. They start below their cost and leave the NPC at 0. (1) 41 attack tasks whose behaviour tree turns `checkStats` off (all free in vanilla, so the setting did not matter before Ghost Mode gave them a cost): Blood and Wine monsters (the panther's whole melee set; the bruxa; Dettlaff, his vampire form and tornado; the shaelmaar's melee and projectile; the banshee; the barghest's fire breath and counter; the fairytale witch's projectiles; the ep2 giant's ground trap; a death-bruxa spawn's projectile) and scripted boss tactics (Olgierd's sand attack, shadow dash, shadow step, a melee attack and his counter moves; the same set in the "ethereal" tactic; Gregoire's five attacks). Six more tasks with the check off are counterattacks (`EAT_Attack20`: Imlerith's two, the generic human counter-push's four); legacy's rule re-enables the check for every counterattack, so those are gated, which looks deliberate. (2) 13 attack task classes whose `IsAvailable` skips the check (charges incl. the fiend's, Dettlaff's dash, the ice giant's icicles, two magic attacks, synced-animation attacks, projectile attacks incl. archers, summons, bomb throws). Legacy never mentions them and changed none of these trees or classes, but it did re-tune most of these enemies' stamina values individually (the light-attack cost these attacks pay: panther and banshee 10 → 20, bruxa, shaelmaar, fairytale witch, giants and Gregoire 10 → 16; Dettlaff kept at 10 with cheaper parry and counter, 10; barghest kept at 20; Gregoire's free parry and counter now 20; Imlerith's −20 parry and counter discount removed; regen raised for all), so the author balanced these fights with their attacks charged but never refused, whether or not she knew they were ungated. The tree cases are almost all signature boss and monster moves, which suggests CDPR let set-piece moves ignore stamina in vanilla. Per enemy tree, most enemies are mixed, with a few signature moves ungated (bruxa 41 gated / 7 ungated, shaelmaar 18/3, ep2 giant 13/1, Dettlaff's vampire form 12/2, fairytale witch 10/2, Olgierd's tactics 8/4, "ethereal" 7/4, barghest 5/3, fiend 4/2, banshee 2/2, Dettlaff 2/1); entirely ungated are the panther (0/5) and Gregoire's tactics (0/5; his counter tree is gated); fully gated are e.g. Imlerith, the werewolf, the big bad wolf, ghouls, the ice giant's main tree and wolves. Asked the author (2026-10-03); the project owner resolves this entry when she answers. **Open:** did the author mean every attack to be refused without stamina (then these are oversights, closed by checking the cost directly at the attack's start), or are some deliberately ungated? Asking the author, or reading her other notes, would settle it. Until then the port keeps legacy's behaviour. Details in [stam.md](features/stam.md#stam-08-npc-stamina).

## XML and other data

- **Mounted CSV.** Does a CSV mounted from a DLC (e.g. quest levels through `CR4QuestDLCMounter.questLevelsFilePath`) override vanilla rows, or only add rows? Matters for porting Ghost Mode's `quest_levels.csv` changes.
- **`on_conflict` coverage.** `extend` and `replace` work on abilities, and repeated tags are replaced in order (see [development.md](development.md#fine-grained-xml-overrides-50)). Open: does it work for every definition type Ghost Mode changes (items, loot, recipes, ...); can attributes on the entry element itself (an item's `price`, `weight`) be extended; can a sub-node be removed without `replace`? Test each when the first feature needs it.
- **NG+ and DLC overrides.** In New Game+, does the game read only a DLC's NG+ mounter (`abilities_plus\`), or its regular one too (and then which wins)? Ghost Mode mounts both, as vanilla DLCs do ([development.md](development.md#fine-grained-xml-overrides-50)), so either way NG+ gets Ghost Mode's rules; only the scaling of a few values could differ. NG+ is not tested ([feature-mapping.md](feature-mapping.md#new-game-carried-over-and-scaled-not-balanced-or-tested)); a probe in an NG+ save, if one ever exists, would settle it.
