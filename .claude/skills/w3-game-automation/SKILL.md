---
name: w3-game-automation
description: Drive The Witcher 3 (5.x) for this project without a human at the keyboard - launch it, load a save, run exec functions or console commands, read the script log, check pause/menu state, quit. Use whenever the user asks to test something in game, launch or close the game, run a console command, check that a mod build works in game, or anything else that needs interacting with the running game.
---

# Witcher 3 game automation

Drive the game with `tools/game.py`. Normal runs need no key presses and no screenshots. Full reference, findings and failure notes: [docs/game-automation.md](../../../docs/game-automation.md). Read it before changing the toolset or when something below fails.

**The game is one shared slot** ([The game slot](../../../docs/game-automation.md#the-game-slot)): several agents may port areas at once. Hold the slot before anything that changes the game, and run every game command from the main checkout's `tools/` (the only copy with rw3d_cli). An area agent follows [Working in parallel](../../../docs/development.md#working-in-parallel).

## Before a run

1. **Tell the user** you are starting the game: its window takes over the screen while it runs. The user may be away, which is fine.
2. **Build first, then ask for the slot:** commit, then make the compile-only build into a folder of your own (`python tools/build_mod.py --ref <branch> --out build/<area>-<commit>`, see [docs/development.md](../../../docs/development.md#build-compile-install)).
3. **Take the slot:** `python tools/game_lock.py request --who <area> --why "<what>"`. Exit 0: granted, the token is printed. Exit 2: queued; `python tools/game_lock.py wait --who <area> --timeout 540` (in the background if you have other work; again on exit 2). Exit 3: paused or your token revoked: stop and tell whoever directs you. Then pass `--holder <area>:<token>` to every `run`, `start`, `load`, `exec`, `resume` and install; claim the grant with one of them within the claim deadline (5 minutes).
4. **The saves are backed up by the grant** (robocopy into `%USERPROFILE%\W3SaveBackup\gamesaves`) and compared by the release. The grant also turns ReShade off, if installed, until the release. Avoid autosave triggers (quest events, teleports, time skips) and report any autosave the release lists; restore nothing without the owner.
5. **Install your prebuilt build:** `python tools/build_mod.py --install-from build/<area>-<commit> --holder <area>:<token>` (with the game closed). `game.py start` refuses a build you did not install this turn.
6. Check the prerequisites (report what is missing; the parent fixes it):
   - `tools/rw3d/rw3d_cli.exe` exists (git-ignored; the parent downloads it: `gh release download v0.8.0 -R SpontanCombust/rusty_witcher_debugger -p "*windows-msvc.zip" -D tools/rw3d`, with the user's OK).
   - `modAutomation` is installed in `<game>\mods\` (the parent's: `build_mod.py --scripts tools/automation/scripts --name modAutomation --out build/automation --install --enable --parent`). `game.py start` stops with this hint when it is missing.
   - Steam is running.
   - The test saves are configured on this machine (`python tools/game_lock.py config` shows `test_save` and `slot_save`; set them with `--test-save NAME --slot-save NAME`, see [Test saves](../../../docs/game-automation.md#test-saves)). `game.py run` refuses with this hint when they are missing.

## The loop

```bash
python tools/game.py run test --holder AREA:TOKEN   # launch, load the test save, lock saving (~25 s)
python tools/game.py exec "myfunc()" "other(1, 2)" --holder AREA:TOKEN           # run exec functions; prints their LogChannel output
python tools/game.py status                   # ingame=, paused=, menu=, loadingvideo=, scene=
python tools/game.py log -n 40                # last script log lines (Documents\The Witcher 3\scriptslog.txt)
python tools/game.py quit                     # exit (~2 s); falls back to closing the window, then killing it
python tools/regress.py --holder AREA:TOKEN --trees both   # the regression run in both skill trees, with counts
python tools/game_lock.py release --holder AREA:TOKEN       # game closed: settings restored, log archived, saves compared
```

Other commands: `start` (to the main menu only), `load SAVE`, `resume` (close the open menu, e.g. the pause menu), `saves [-n N]` (newest saves). Options go after the command: `--timeout S` per step, `exec --wait MS "..."` for exec functions that log over time (default 500). `quit`, `status`, `log` and `saves` need no holder.

**Release before editing code**: a failed check means quit, release, fix, commit, build, ask again. Never leave the game running or the slot held while you work on something else.

## Test save and character setup

- Load the test save: `python tools/game.py run test --holder AREA:TOKEN` (White Orchard, level 1, starting gear). `run` and `load` take `test`, `slot` (the test-only slot) or another save allowed in the lock's config, and lock saving after each load (`gmtest_nosave()`).
- Build the character and situation a test needs with vanilla exec functions after loading: `setlevel(10)`, `addskillpoints(20)`, `skilleq(S_Sword_s01)`, `additem('<item name>', 1, true)`, `spawn(wolf, 2, 6, true)`, `killall()`, ... The verified list, with argument forms and pitfalls, is in [docs/game-automation.md](../../../docs/game-automation.md#setting-up-geralt-and-the-world).
- Vanilla debug functions (`logskills()`, `printinv()`, ...) log nothing in the release build. Read state with `modAutomation`'s probes: `autoplayer()`, `autoskills()`, `autoinv()`, `autobuffs()`, `autoattr('<attribute>')`, `autoactors()`.
- Never use `god()` in stamina tests: it also turns on infinite stamina. Do use it in casting tests in a fight: hits interrupt casts.
- Player input from a script: `autocast(ST_Igni)` / `autocast(ST_Igni, true)` (held, for alternate casts) and `autocastrelease()`; guarding with `thePlayer.SetGuarded(true)` in a test function. See [Input simulation](../../../docs/game-automation.md#input-simulation).

- A command exits 1 on failure and prints the last log lines; the game stays running for inspection. Read the output, then `status`/`log`, before retrying.
- **Never retry a non-idempotent exec call blindly**: a call can run even when rw3d_cli reports a timeout. Check the log first.
- Quit the game when done unless the user wants it left open.

## Writing in-game tests

- Test through **exec functions** that report with `LogChannel('<Channel>', msg)`: their output comes back from `game.py exec` and lands in the script log. `DisplayHudMessage` is not visible to you.
- "Command failed to execute" means the function does not exist in the loaded scripts: usually the mod is not installed, not enabled in `mods.settings`, or the game was started before the install.
- Pause/menu tests: `exec "ingamemenu()"` opens the pause menu, `status` shows `paused=true menu=CommonIngameMenu`, `resume` closes it.
- Saves: only the allowed test saves load. Never save; saving the test-only slot is the parent's (`game.py exec` refuses the save makers).
- New automation features (markers, exec helpers) belong in `tools/automation/scripts/local/modAutomation.ws` (rebuild and reinstall afterwards, without `--enable`) and `tools/game.py`. Record findings in docs/game-automation.md.

## Do not

- Do not change the game without the slot: no `rw3d_cli` directly, no installs with `--scripts`, no copying saves by hand, no editing the settings files, no `--parent` (the parent's emergency switch).
- Do not use rw3d_cli `reload`: it drops blob mods from the running game. Rebuild with `build_mod.py` and restart instead.
- Do not reach for key presses or screenshots unless the scripted route cannot work (e.g. a hang before scripts run, or the user asks what is on screen). Fallback scripts: `tools/focus_game.ps1`, `tools/send_key.ps1` (scan codes; Shift does not work, so no `(`), `tools/screenshot.ps1 <out.png>` (save to the scratchpad and view it with Read). Key presses need the game window in front.
