# Automated game control

How Claude (or any script) drives the game for tests: launch it, reach the main menu, load a save, run exec functions, read the results, close it. With this, compile checks and console-command tests (see [Testing in game](development.md#testing-in-game)) run end to end with no key presses and no screenshots.

Status markers: **verified** (seen working on this machine), *unverified* (from docs, forums or the executable, not tried yet), **failed** (tried, does not work).

## Quick start

```bash
python tools/build_mod.py --scripts tools/automation/scripts --name modAutomation --out build/automation --install --enable   # once
python tools/game.py run                 # launch, load the newest save, wait until playable
python tools/game.py exec "gmpilot()"    # run exec functions, print their output
python tools/game.py quit
```

**Verified** 2026-10-01 (game build 5.0.1044392, with `modGhostMode` pilot build and `modAutomation` installed): the whole loop above takes **about 29 s**: 10 s to the main menu, 12 s to load, 2 s to quit.

Requirements: Steam running; `tools/rw3d/rw3d_cli.exe` (see [rw3d_cli](#rw3d_cli)); `modAutomation` installed. The game window opens normally and takes the screen, but nothing needs focus or input.

## How it works

Three pieces:

| Piece | What it does |
|---|---|
| `witcher3.exe -net -debugscripts` | Started directly (no launcher). `-debugscripts` writes `LogChannel` output live to `Documents\The Witcher 3\scriptslog.txt` (rewritten at each start). `-net` opens TCP port 37001 for the script debugger protocol. |
| `modAutomation` (`tools/automation/scripts/local/modAutomation.ws`) | Test-only mod, never shipped. Logs `[Automation]` markers at the main menu, game start and end of loading, and adds exec functions to query status, load a save, close menus and quit. |
| [rw3d_cli](#rw3d_cli) (`tools/rw3d/`) | Calls exec functions in the running game over port 37001 and prints their `LogChannel` output. |

`tools/game.py` combines them: it launches the game, waits for markers in the script log, and calls the mod's exec functions through rw3d_cli.

### game.py commands

| Command | What it does |
|---|---|
| `run [SAVE]` | `start` then `load` |
| `start` | Launch and wait for `[Automation] main menu`, closing the startup screens on the way (see [Startup screens](#startup-screens)) |
| `load [SAVE]` | `autoload()` (newest save) or `autoload("<file>")`; waits for `loading`, `game started`, `ready`; then checks status and closes any open menu |
| `exec "CMD" ...` | Run exec functions, print their output. Fails on "Command failed to execute" (function does not exist) |
| `status` | `autostatus()`: `ingame`, `paused`, `menu` (root menu name or `none`), `loadingvideo`, `scene` |
| `resume` | `autoresume()`: close the open menu |
| `saves [-n N]` | The N newest saves (file names are reported in lower case; `autoload` matches any case) |
| `log [-n N]` | Last N script log lines |
| `quit` | `autoquit()` (`theGame.RequestExit()`), then closing the window, then killing the process |

Options: `--timeout S` per step (default 180), `--wait MS` how long rw3d_cli waits for exec output (default 500; raise it for functions that log over time). Exit code 1 on errors or timeouts, with the last log lines printed. A failed step leaves the game running for inspection.

### modAutomation

Markers (each line `[Automation] <event> key=value ...`):

| Marker | Hook |
|---|---|
| `main menu` | `@wrapMethod(CR4CommonMainMenuBase) OnConfigUI` |
| `game started restored=<bool>` | `@wrapMethod(CR4Game) OnGameStarted` |
| `ready` | `@wrapMethod(CR4Game) OnAfterLoadingScreenGameStart` (loading screen gone) |

Exec functions: `autostatus()`, `autosaves(optional count)`, `autoload(optional file)`, `autoresume()`, `autoquit()`, `autoconfig(optional group)` (list the options menu groups, or one group's variables with display name, label, type, value and visibility), `autoconfigset(group, var, value)` (set a variable and save the user settings). Errors log `[Automation] error ...`, which `game.py` treats as a failure.

Input simulation: `autocast(sign, optional hold)`, `autocastrelease()` (see [Input simulation](#input-simulation)). Lock-on: `autolock()` hard-locks onto the nearest living hostile within 15 m (or `autolock(false, <range>)`), as the lock-on button does (`ProcessLockTarget`, `HardLockToTarget(true)`); `autolock(true)` releases it.

Probes, which report state (see [Setting up Geralt and the world](#setting-up-geralt-and-the-world)):

| Probe | Reports |
|---|---|
| `autoplayer()` | Level, experience, skill points, money, difficulty; vitality, stamina, toxicity, adrenaline (current/max); position, game time, player state (`Exploration`, `CombatSteel`, ...), in combat, immortality mode |
| `autoskills()` | Every learned skill: name, `ESkill` value, level/max level, slot (-1: not equipped), `canUse`; slot counts |
| `autoinv(optional all)` | Equipped items (all items with `true`): name, category, quantity |
| `autobuffs()` | Active effects with time left (-1: permanent) |
| `autoattr(attr)` | One of Geralt's attributes (`base`, `mult`, `add`), e.g. `autoattr('staminaRegen')` |
| `autoactors(optional range)` | Actors within 30 m (or `range`): template, name, attitude, level, health fraction, alive, distance |

Rebuild and reinstall after changing it with the build command in [Quick start](#quick-start) (without `--enable`). `build_mod.py --scripts <dir>` builds any folder of scripts (laid out like `content\scripts`) instead of a branch's changes.

It stays enabled in `mods.settings`, also for normal play. That's harmless (it only logs and adds exec functions), but saves made with it list it in their `.json` metadata. Disable it with `Enabled=0` if that matters.

## Setting up Geralt and the world

### Skill trees

Ghost Mode supports both of 5.x's skill trees ([feature-mapping.md](feature-mapping.md#two-skill-trees)), so skill tests run on both. `skilleq` equips any skill whatever the tree, so a test can equip the classic skill (e.g. `S_Sword_s01`) or the new tree's counterpart (`S_Sword_s35`) directly. The tree the player has chosen is 5.x's hidden setting `RemasterCombat`/`UseLegacySkillTree` (`autoconfigset(RemasterCombat, UseLegacySkillTree, true)`; it saves into the real settings file, so set it back to `false` afterwards); code that special-cases shared skills reads it. **Verified** 2026-10-03: `autoconfigset(RemasterCombat, UseLegacySkillTree, true)` sets it (`autoconfig(RemasterCombat)` lists nothing, the group being hidden), and with it on `skilleq(S_Sword_s01)` equips the classic Whirl, which then works in a fight. *Not yet tested:* the classic character screen itself (buying and equipping skills by hand).

**Timing of held special attacks:** each `game.py exec` call adds about a second, so a Whirl pressed in one call drains its stamina before a release in the next call arrives. Press, check and release in one call (`exec --wait 500 "gmtest_stam02_press(false)" "autostatus()" "gmtest_stam02_release(false)"`).

Tests that need a particular character (level, skills, gear) or a fight set it up with the game's own exec functions, called through `game.py exec` like any other. All 874 of them are cataloged by topic in [console-commands.md](console-commands.md) (generated by `tools/exec_catalog.py`). The script source is the reference for what each one does on 5.x; online command lists describe the legacy game.

**Vanilla debug output is not logged.** Vanilla functions that only log (`logskills()`, `printinv()`, `statsplayer()`, `printbuffs()`, `printdiff()`, ...) run, but nothing reaches `scriptslog.txt`: in the release build only mod scripts' `LogChannel` output appears. `pos()` and similar show a HUD message instead. Read the state with `modAutomation`'s probes (above).

**Verified** 2026-10-02 on the test save (see [Test saves](#test-saves)), each change confirmed with a probe:

| Goal | Call | Notes |
|---|---|---|
| Level | `setlevel(10)`, `levelup(3)`, `addexp(500)` | Each level grants its skill point and slot unlocks the normal way (level 1 → 10: 9 points, 11 of 16 slots) |
| Skill points | `addskillpoints(20)` | |
| Play as Ciri | `Ciri()`, back with `Geralt()` | Vanilla's `theGame.ChangePlayer`; give `exec --wait 3000`. Verified 2026-10-04 (DEF-04): `autoplayer()` then reports Ciri (level 0), and `thePlayer` is a `W3ReplacerCiri`. The test save's Ciri has no blink or charge ability. Do not save while playing as Ciri |
| Learn and equip a skill | `skilleq(S_Sword_s01)` | Takes an `ESkill` value; spends a skill point; equips into a free slot (unlocks one if none is free). `skilleq(S_Sword_s01, 0, 3)` learns 3 ranks. Whirl = `S_Sword_s01` (classic tree) or `S_Sword_s35` (new tree), Rend = `S_Sword_s02` (both); see [Skill trees](#skill-trees) |
| Learn without equipping | `learnskill(magic_s1)` | Takes the skill's *ability name* (`sword_s1`, `magic_s1`; not `magic_s01`). Learned but unequipped skills report `canUse=false` |
| Unequip | `skilluneq(<slot id>)` | |
| Start a new game | From the main menu (`game.py start`): `autonewgame()` (tutorial messages off), then skip the intro with `send_key.ps1 space` and `esc` until `status` shows `scene=false` (an `esc` too many opens the pause menu: `game.py resume`); about 40 s to Kaer Morhen's bedroom, default difficulty | Verified 2026-10-13 |
| Open the character menu | `dupemenu()` (vanilla): the new menu, or the classic one when `UseLegacySkillTree` is on; close with `game.py resume` | Verified 2026-10-13. The `K` key reopens the hub's last tab instead. A tab of the open character menu: `gmtest_menutab(SC_Red)` (combat), `SC_Blue` (signs), `SC_Green` (alchemy), `SC_Yellow` (general); the `e` key does not switch tabs |
| Reset character | `gmreset()` (Ghost Mode's character reset: refunds skills and mutation research, keeps level and inventory; not in combat) | Verified 2026-10-11 (SKL-01). Vanilla's `cleardevelop()` (resets the level, clears skills and inventory) and `ResetBuild()` (refunds skills) not tried |
| Add item | `additem('Viper School steel sword', 1, true)` | Item names are the `name` attributes in `gameplay/items/def_item_*.xml` (`dlc/ep1`, `dlc/bob` for the expansions) on `vanilla-5.x`; `true` equips it |
| Item sets | `addset(EIST_Lynx, true)`, `addsteelswords()`, `addpotions()`, `addbombs()`, `addoils()`, ... | Not tried yet |
| Money | `addmoney(1000)`, `removemoney(100)` | |
| Stamina and other stats | `hitstamina(60)` (drain 60% of max), `drainstat(BCS_Stamina, 50)`, `RestoreStamina()`, `addstat(BCS_Toxicity, 30)`, `hitme(20)` (20% of max vitality as damage), `HealGeralt()` | `hitstamina` and `drainstat` go through `DrainStamina`, so they also trigger regen delays |
| Effects | `buffme(EET_Drunkenness, 30)`, `buffgeralt(<effect name>)` | `buffme` takes an `EEffectType`, `buffgeralt` an effect name (`DrunkennessEffect`) |
| Abilities | `addabl(<ability>)`, `rmvabl(<ability>)` | Not tried yet |
| Invulnerable | `god()` (toggle) | Also turns off hit reactions, so enemies cannot interrupt a test's casts. Also turns on infinite stamina ("stamina boy"), so **never use `god()` alone in stamina tests**: run `staminaboy()` once right after it (a toggle) to turn infinite stamina back off and keep Geralt invulnerable (**verified**, STAM-07). Check with a drain: with infinite stamina, drains and `GainStat` leave it at 100%. `ForceSetStat(BCS_Stamina, ...)` does not change the player's stamina at all; drain with `DrainStamina` instead. `god2()` toggles a different immortality cheat (`CheatGod2`; not tried yet). It also makes Geralt immune to effects such as bleeding and knockdowns, so effect tests (e.g. Quen's effect rules, SKL-11) run without it (**verified** 2026-10-15). For damage comparisons, reset adrenaline before each scripted hit: 5.x turns adrenaline into attack power |
| Infinite stamina | `staminaboy()` (toggle) | |
| Difficulty | `difflevel(EDM_Hard)` | The test save is on `EDM_Hard` (Blood and Broken Bones) |
| Spawn enemies | `spawn(wolf, 2, 6, true)`: alias, count, distance, hostile, optional level | Aliases are in `gameplay/globals/resources/gameplay.xml` (`<res alias=... path=...>`), or a path under `characters\npc_entities\monsters\` without `.w2ent`. Hostile spawns at 6 m put Geralt in combat at once (`state=CombatSteel combat=true`); at 15 m combat started only after several seconds, or not within 3 s. Check `IsInCombat()` (or `autoplayer()`) before measuring anything combat-specific |
| Kill hostiles | `killall()` (20 m), `killall(50)` | |
| Time | `settime(<day>, <hour>, <minute>)`, `wait(0, 6)`, `passtime(...)` | |
| Weather | `changeweather(WT_Rain_Storm)` | Ran without error; not checked (no probe) |
| Guard | Script only: `thePlayer.SetGuarded(true)` / `false` (no exec function) | Held until reset, also in combat; `IsGuarded()` reports it. Used by `gmtest_stam04_c(true)` |
| Teleport | `tptopos(x, y, z)` (ends on the ground), `xy(x, y)` | `autoplayer()` prints the current position |

Actions that need input (casting, guarding) are driven by script instead: see [Input simulation](#input-simulation).

**Long exec output is cut off.** rw3d_cli returns only the first part of a call's `LogChannel` output when a function logs a lot (about 40 lines was too many); the script log has all of it (`grep GMTest` in `Documents\The Witcher 3\scriptslog.txt`). Keep test functions' INFO lines few.

**Changes made this way are not saved** unless the game saves. No autosave happened in testing, but an autosave can trigger at quest events; `game.py run <save>` with the test save's name always starts from its unchanged state. Do not save over the test save.

## Input simulation

The game has no way to fake a key press, but a script can call the input handler's events itself with a made-up key state. **Verified** for casting signs (STAM-01, 2026-10-02):

- `SInputAction`'s fields are declared `import const`, but a script can still set them on a local variable (`action.aName = 'CastSign'; action.value = 1; action.lastFrameValue = 0;` is a press, `0` after `1` a release), and pass it to an event: `thePlayer.GetInputHandler().OnCastSign(action)`. Everything behind the event runs as for a real key: the checks, Ghost Mode's wrappers on the event, the sign states, stamina.
- `modAutomation`: `autocast(ST_Igni)` presses the cast input with that sign selected, `autocastrelease()` releases it. Each logs the sign, `casting`, stamina and player state. Ghost Mode's own `gmtest_stam01_press/release` do the same without depending on `modAutomation`.
- **Held keys cannot be faked that way.** The game reads the real key state (`theInput.IsActionPressed('CastSign')`, `GetActionValue('CastSignHold')`) to decide on an alternate cast (`W3SignOwnerPlayer.ChangeAspect`) and to keep a channel going (`ShouldStopChanneling` in the sign's `Channeling` state). `autocast(ST_Igni, true)` sets a flag that `modAutomation`'s wrappers of those two functions answer as for a held key, until `autocastrelease()`. The hold lasts as long as the calls in between take (each `game.py exec` call about `--wait` ms).
- Casting needs its conditions as in play. Every cast, normal or alternate, needs the base sign cost (40 with Ghost Mode) to start. Sign cooldowns (STAM-01) block recasting the same sign; for repeated casts set `GMSignCooldown` and `GMAltSignCooldown` to 0 with `autoconfigset` and restore them afterwards (see below).
- Measuring a held cast: `gmtest_stam03_chan_a(<stamina>)`, `autocast(<sign>, true)`, then `gmtest_stam03_chan_b()` between calls and after `autocastrelease()`. It sums the per-frame channel drains (amount, frames, first and last time) and logs the sign entity's state.
- **Alternate Axii in tests:** with both alternate Axii skills equipped, 5.x casts the classic one (`ChangeAspect` checks `S_Magic_s05` first), so unequip it to test Puppet (`S_Magic_s31`): `autoskills()` shows its slot, `skilluneq(<slot>)` removes it, and check again, since slot numbers shift. The puppet lands on a human (e.g. `gmtest_stam06_bandit()`); on that bandit it is gone again within about 1.5 s (its forced hostile attitude), so read it when the channel ends (the test probe on `W3AxiiEntity.OnEnded`, logged with `gmtest_probes(true)`), not afterwards.
- Other conditions as in play: the sign's skill (alternate casts need the alternate skill equipped: `S_Magic_s01` to `s05` in the classic tree; in the new tree Aard, Yrden and Quen use the same (shared) skills, Igni `S_Magic_s28` and Axii `S_Magic_s31`), stamina, and for Axii a hostile target in range. Axii's alternate (puppet) aborts unless held about 2 s.
- **Hits interrupt casts.** In a fight, run `god()` first (no hit reactions); otherwise casts fail at random.
- **A scripted hit does not break a channel.** A hit through `theGame.damageMgr.ProcessAction`, even `EHRT_Heavy` with `EAHA_ForceYes`, left a held Firestream channeling (2026-10-16, SKL-07 slice 6). To test an interrupted cast, abort the sign (`OnSignAborted(true)` on the sign entity, `gmtest_skl07_foa_abort()`).
- **Out of combat, stamina regen is 100% of max per second**, so stamina read after an out-of-combat cast says nothing about its cost; measure costs in combat.
- Guarding: `thePlayer.SetGuarded(true)` from a script (see the table above).
- Special attacks: calling `CPlayerInput.OnCbtSpecialAttackLight/Heavy` with a press starts Whirl or Rend (needs `S_Sword_s35` / `S_Sword_s02` equipped and a drawn sword in combat; STAM-02's tests ran with the legacy `S_Sword_s01`), and the release ends it; no held-key simulation is needed (the attack runs until the release event). **Verified** (STAM-02, `gmtest_stam02_press/release`). Normal attacks: `OnCbtAttackLight` press and release starts a light attack; the sword heavy attack's event checks the real key's activation time (`theInput.GetLastActivationTime('AttackHeavy') < 0.2`), so start it with `thePlayer.SetupCombatAction(EBAT_HeavyAttack, BS_Released)`. Dodge and roll: `OnCbtDodge` / `OnCbtRoll`. Bombs: select one (`EquipItemInGivenSlot(id, EES_Petard1, false)`, `SelectQuickslotItem(EES_Petard1)`), then `SetupCombatAction(EBAT_ItemUse, BS_Pressed)`, a moment later `BS_Released` (the item input event depends on real key state; press and release in one frame throws nothing). **Verified** (STAM-03, `gmtest_stam03_act_a/b`, `gmtest_stam03_bomb_a/release/b`).
- Quick and aimed throws (`gmtest_skl06_throw(pressed, aimed, bomb)`): a press through `SetupCombatAction(EBAT_ItemUse, BS_Pressed)` throws a quick bolt or bomb (not aimed). An aimed **bomb** needs `thePlayer.SetThrowHold(true)` before the press (the throw animation's `ThrowHoldTest` event then enters `AimThrow`); while aiming, the buffered release is not processed, so release with `BombThrowRelease()` (test-only `GMTestBombThrowRelease`). It lands where the camera aims, not on a target. An aimed **crossbow** shot cannot be scripted this way: the crossbow reads the real key (`theInput.GetActionValue('ThrowItem')`). **Verified** 2026-10-15 (SKL-06).
- Whirl and Rend start through a timer (`IsSpecialLightAttackInputHeld` / `IsSpecialHeavyAttackInputHeld`) that repeats its resource check for as long as the button is held, so in a fight regen can make a refused start succeed a moment later. To test a refusal, pause regen first (`gmtest_stam03_chan_a(<stamina>)` sets stamina with regen paused 30 s). `gmtest_stam09_a(heavy, stamina, adrenaline)` and `gmtest_stam09_s()` start one and sample stamina, adrenaline and `isPerformingSpecialAttack`. `addstat(BCS_Focus, 1)` adds adrenaline through `GainStat`.
- **Lock on before combat tests** (`autolock()` after the spawn): without a hard lock, Geralt's attacks go to the soft-targeting choice, and enemies that move around get missed or ignored (seen in the STAM-06 finisher tests). **Verified** (STAM-08).
- **Baseline builds:** to see what vanilla does with the same probes, build a branch that is the current commit minus the feature's file (`git read-tree`, `git rm --cached`, `git commit-tree` with a temporary `GIT_INDEX_FILE`; a temporary worktree fails on this repo's long paths in the scratchpad) and run the same test. Used for STAM-08 (vanilla wolves attack without paying).
- Rend held by script (`gmtest_stam02_press(true)` or `gmtest_stam06_rend_a()`) charges until full (2 s from full stamina at Ghost Mode's cost) and then strikes on its own; it cannot be held longer.
- **Enemy archers:** `gmtest_def08_archer("skellige_bandit_bow", 12)` spawns a hostile archer from `living_world\enemy_templates\` (others there: `baron_renegade_bow`, `nilfgaardian_deserter_bow`, `..._crossbow`); it starts shooting at once. Quest archers such as the tournament's `sq701_horm_bow` do not fight when spawned. Paths built in script take forward slashes (`LoadResource("living_world/enemy_templates/...")`), which avoids backslashes before letters in strings.
- Finishers: `gmtest_stam06_bandit()` spawns a hostile human (finishers need a human male; the template is `dlc\dlc7\data\characters\sq107_bandit_lvl1_mortal.w2ent`: the non-`_mortal` one is immortal and never drops below 1 health), `ForceFinisher(true)` (vanilla) forces the next killing blow into a finisher, `gmtest_stam06_weaken()` puts the bandit at 1 health 1.5 m in front of Geralt and confuses it (Axii's effect, so it does not block), then a light attack (`gmtest_stam06_fin_a()`) kills it with a finisher. **Verified** (STAM-06).
- Horseback: `gmtest_stam03_mount()` mounts Roach (`GetHorseWithInventory().GetHorseComponent().Mount(thePlayer, VMT_ImmediateUse, EVS_driver_slot)`; on the test save Roach stands 4 m away; the mount takes about a second, then the player state is `HorseRiding`). Horseback actions go through the horse's combat manager (`GetUsedHorseComponent().GetUserCombatManager()`), whose input events (`OnAttack`, `OnItemAction`) exist only in its states; the tests add empty events of those names to `W3VehicleCombatManager` with `@addMethod`, so a script can call them and the current state's event runs. A sword attack press alone makes a whole swing (vanilla reads the real key as released and takes the quick-swing path). The crossbow fires with a press and a release (select it first: `EquipItemInGivenSlot(id, EES_RangedWeapon, false)`, `SelectQuickslotItem(EES_RangedWeapon)`). A bomb from horseback checks the real key's activation time, so only its refusal can be tested this way. **Verified** (STAM-03, `gmtest_stam03_horse_a/b`).

## Findings

### Hang after loading a save: the game on the wrong GPU

- **Seen** 2026-10-02: after the save loaded (`ready` logged, one exec answered), the game showed a black "Loading" screen and stopped answering exec calls; the same without any mods. It was rendering on another display adapter (LUID `0x17308`, no dedicated GPU memory, about 3 CPU cores busy) instead of the dedicated GPU, probably after a graphics driver update and a virtual display adapter (SudoMaker) being present. Restarting the computer fixed it.
- **Check** which GPU the game uses: `nvidia-smi --query-gpu=index,name,utilization.gpu,memory.used --format=csv` (the game's GPU shows load and several GB in use), or the game's memory per adapter: `(Get-Counter '\GPU Process Memory(*)\Dedicated Usage').CounterSamples` filtered on `pid_<witcher3 pid>`. On the right GPU the game uses about 6 GB there.

### Menus

- The inventory's stats view opens with `C` (`send_key.ps1 type c`); its rows do not react to the arrow keys or to a cursor moved by `SetCursorPos` (the game reads raw mouse input). Check panel values from script instead: `GetPlayerStatsGFxData(menu.GetMenuFlashValueStorage())` with any menu open (e.g. `ingamemenu()`), reading the lines back with `GetMemberFlashArray` / `GetMemberFlashString` (`gmtest_panel`).
- If the Claude desktop window covers the game, minimize it (`ShowWindow(<claude main window>, 6)`), then `focus_game.ps1`.

### Launch

- **Verified:** starting `bin\x64_dx12\witcher3.exe` directly (working directory `bin\x64_dx12`, Steam running) skips REDlauncher, and the process started is the game itself (no relaunch through Steam). Arguments pass straight through; no Steam launch-option change needed.
- *Unverified alternative:* the Steam launch option `--launcher-skip` ([Steam guide](https://steamcommunity.com/sharedfiles/filedetails/?id=2902047062)), only needed when Steam must start the game.
- Untested: launching while Steam is not running.

### Startup screens

Before the main menu the game shows a queue of screens (`CR4Game.PopulateMenuQueueMainOnce`), each a menu:

| Menu | What it is | Without input |
|---|---|---|
| `StartupMoviesMenu` | Logo videos | Ends after about 45 s |
| `RecapMoviesMenu` | Story intro video ("Space Skip") | Waits (still there after 150 s) |
| `StartupExperienceMenu` | CD PROJEKT RED account sign-in, then telemetry consent. Shown only on some launches (`EvaluateStartupLaunchCriteria`) | Waits |

- **Verified:** closing each with `autoresume()` (`CMenu.CloseMenu()`) moves on to the next, and then the main menu appears. `game.py start` does this as soon as the game answers exec calls (about 8 s after launch). Closing the sign-in screen answers neither the sign-in nor the telemetry question.
- Space as a key press also skips the videos (`SkipShowWithAnyKey=true`); not needed any more.

### Loading and pause state

- **Verified:** `theGame.LoadLastGameInit()` (what Continue calls) loads the newest save from the main menu, about 12 s here. `ListSavedGames` plus `LoadGameInit(info, false)` loads a named save. This machine has 491 saves; the list is newest first.
- **Verified:** marker order on load: `loading save=...`, `game started restored=true`, `ready`. Right after `ready` the game answers exec calls, is not paused and has no menu open.
- **Verified:** the vanilla exec function `ingamemenu()` opens the pause menu; `autostatus()` then reports `paused=true menu=CommonIngameMenu`, and `autoresume()` closes it (`paused=false menu=none`). So pause tests need no Esc key either.

### rw3d_cli

[Rusty Witcher 3 Debugger](https://github.com/SpontanCombust/rusty_witcher_debugger) CLI v0.8.0 (2024-08), downloaded from its GitHub release into `tools/rw3d/` (git-ignored). To get it again: `gh release download v0.8.0 -R SpontanCombust/rusty_witcher_debugger -p "*windows-msvc.zip"`, then unzip into `tools/rw3d/`.

- **Verified:** `exec "<call>"` runs any exec function, with arguments, without keyboard or focus, at the startup screens, the main menu and in game. With `-l output-only` it prints just the function's `LogChannel` output.
- **Verified:** rw3d_cli always waits the full response timeout (`-t`) for more output after the reply arrives, so `-t` is the time per call: 200 ms gives 0.27 s per call. `game.py` uses 500 ms.
- **Verified:** for about 5 s after launch the game does not answer (the CLI may even panic), and during loading it may answer late. A command can run even when the CLI reports "Waited too long for the response", so `game.py` never retries a command; it only retries the harmless `autostatus()` until the game answers.
- **Verified:** `autoquit()` exits the game before the reply is sent, so its call always "fails"; `game.py` then just waits for the process to exit.
- **Failed (for us):** `reload` started "Script compilation started..." and never reported back (gave up after 150 s). Afterwards the game ran without our mods' script blobs (`gmpilot` gone, vanilla `[PS4_Light]` log spam). It apparently recompiles vanilla plus loose mod scripts only. Use `build_mod.py` and a game restart instead.
- **Failed:** `rootpath` and `modlist` time out: the game answers (`-v` shows a `RootPathConfirm` packet) but this CLI version does not accept the reply, probably a 5.x protocol change. Not needed.

### Two script blobs

- **Verified:** two mods with a `precompiled.rsblob` each (`modAutomation` and the `modGhostMode` pilot) load together, both at priority 100: both mods' exec functions and wrappers work. They wrap different methods, so this does not yet show how wrappers of the *same* method chain (see [open-questions.md](open-questions.md#several-mods-with-script-blobs)).

### Close

- **Verified:** `autoquit()` exits in about 2 s, from the main menu or in game. Fallbacks in `game.py`: WM_CLOSE to the game window (also exits within seconds, no dialog), then `taskkill /F`.

### Keyboard and screenshot fallback

Used for the first manual run, before the mod existed. Kept for situations the mod cannot handle (e.g. a hang before scripts run, or checking what is on screen). Scripts in `tools/`, run as `powershell -NoProfile -ExecutionPolicy Bypass -File tools\<script> ...`:

- `focus_game.ps1`: brings the game window to the foreground (key presses go to the foreground window).
- `send_key.ps1 <key> [count] [delayMs]`: `space`, `esc`, `enter`, `tilde`, `e`, `backspace`, `up`, `down`, `left`, `right` as hardware scan codes (arrows as extended keys). `send_key.ps1 type <text>` types text as scan codes.
- `screenshot.ps1 <out.png> [-Region x,y,w,h]`: captures the primary screen (3440x1440 here). Save screenshots in the session scratchpad, not the repo.

What we learned about input:

- **Verified:** the game reads hardware scan codes (`SendInput` with `KEYEVENTF_SCANCODE`). `~` opens the console, letters type, Enter runs the command.
- **Failed:** Shift does not reach the console: `()` typed as Shift+9/Shift+0 came out as `12`. No-argument exec functions work without `()`.
- **Failed:** Unicode key events type nothing; clipboard plus simulated Ctrl+V did not paste (the console ran `k`, cause unknown).
- **Verified:** menus navigate with the arrow keys and Enter (open the pause menu with `exec "ingamemenu()"` first). E does not select in menus, and simulated mouse clicks (`SetCursorPos` plus `mouse_event`) did not register.
- The HUD message from `gmpilot` (`DisplayHudMessage`) never showed up in a screenshot, perhaps hidden by a tutorial hint. Results come from the script log instead.

## Test saves

**The test save is `<save name>`** (made 2026-10-02 with game build 5.0.1044392, `modGhostMode` and `modAutomation` installed): White Orchard, just past the tutorial, near Vesemir and Roach. Geralt is level 1 with no skill points, the starting gear (Long Steel Sword, Witcher Silver Sword, starting armor), 250 crowns, all five signs; difficulty Blood and Broken Bones (`EDM_Hard`).

Load it by name, since `game.py run` without a name loads the newest save:

```bash
python tools/game.py run <save name>
```

Build the character a test needs with exec functions after loading (see [Setting up Geralt and the world](#setting-up-geralt-and-the-world)), so the save itself stays a clean level 1 start.

## Ideas not done

- A test runner on top of `game.py`: build, `run`, a list of exec calls with expected log lines, `quit`, report.
- Skip the main menu entirely: `autoload()` during the startup screens (untested whether loading works before the main menu exists).
- Answer the remaining open question about blobs with two throwaway mods wrapping the same method, using this loop.

## Log

- 2026-10-02: sign casting by script (`autocast`), including alternate casts through a simulated held key.
- 2026-10-02: test save past the tutorial. Character and world setup through vanilla exec functions verified; probes added to `modAutomation` because vanilla debug output is not logged.
- 2026-10-01: `modAutomation` and `tools/game.py`: whole loop without key presses or screenshots, about 29 s. Startup screens closed by script; exec wait cut to 500 ms.
- 2026-10-01: rw3d_cli v0.8.0 tested: `exec` works on 5.0 (any arguments); `reload` drops blob mods; `rootpath`/`modlist` replies not parsed.
- 2026-10-01: first manual run of the whole loop with simulated keys and screenshots. Game reported build 5.0.1044392 (the 5.0 hotfix; `vanilla-5.x` now matches it).
