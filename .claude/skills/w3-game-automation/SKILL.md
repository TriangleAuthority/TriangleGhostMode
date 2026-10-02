---
name: w3-game-automation
description: Drive The Witcher 3 (5.x) for this project without a human at the keyboard - launch it, load a save, run exec functions or console commands, read the script log, check pause/menu state, quit. Use whenever the user asks to test something in game, launch or close the game, run a console command, check that a mod build works in game, or anything else that needs interacting with the running game.
---

# Witcher 3 game automation

Drive the game with `tools/game.py`. Normal runs need no key presses and no screenshots. Full reference, findings and failure notes: [docs/game-automation.md](../../../docs/game-automation.md). Read it before changing the toolset or when something below fails.

## Before a run

1. **Tell the user** you are starting the game: its window takes over the screen while it runs. The user may be away, which is fine.
2. Check the prerequisites (fix what is missing):
   - `tools/rw3d/rw3d_cli.exe` exists. It is git-ignored; download it with `gh release download v0.8.0 -R SpontanCombust/rusty_witcher_debugger -p "*windows-msvc.zip" -D tools/rw3d`, then unzip it there. Downloading third-party executables needs the user's OK.
   - `modAutomation` is installed in `<game>\mods\`. If not: `python tools/build_mod.py --scripts tools/automation/scripts --name modAutomation --out build/automation --install --enable`. `game.py start` stops with this hint when it is missing.
   - The mod under test is built and installed (`python tools/build_mod.py --ref <branch> --install`, see [docs/development.md](../../../docs/development.md#build-compile-install)). Install while the game is **not** running; scripts load only at game start.
   - Steam is running.

## The loop

```bash
python tools/game.py run [SAVE]               # launch, close startup screens, load newest (or named) save, verify playable (~25 s)
python tools/game.py exec "myfunc()" "other(1, 2)"   # run exec functions; prints their LogChannel output
python tools/game.py status                   # ingame=, paused=, menu=, loadingvideo=, scene=
python tools/game.py log -n 40                # last script log lines (Documents\The Witcher 3\scriptslog.txt)
python tools/game.py quit                     # exit (~2 s); falls back to closing the window, then killing it
```

Other commands: `start` (to the main menu only), `load [SAVE]`, `resume` (close the open menu, e.g. the pause menu), `saves [-n N]` (newest saves). Options: `--timeout S` per step, `--wait MS` for exec functions that log over time (default 500).

- A command exits 1 on failure and prints the last log lines; the game stays running for inspection. Read the output, then `status`/`log`, before retrying.
- **Never retry a non-idempotent exec call blindly**: a call can run even when rw3d_cli reports a timeout. Check the log first.
- Quit the game when done unless the user wants it left open.

## Writing in-game tests

- Test through **exec functions** that report with `LogChannel('<Channel>', msg)`: their output comes back from `game.py exec` and lands in the script log. `DisplayHudMessage` is not visible to you.
- "Command failed to execute" means the function does not exist in the loaded scripts: usually the mod is not installed, not enabled in `mods.settings`, or the game was started before the install.
- Pause/menu tests: `exec "ingamemenu()"` opens the pause menu, `status` shows `paused=true menu=CommonIngameMenu`, `resume` closes it.
- Saves: loading any save is fine. Never save over the user's personal saves with a test build; use a dedicated test save when a test must save.
- New automation features (markers, exec helpers) belong in `tools/automation/scripts/local/modAutomation.ws` (rebuild and reinstall afterwards, without `--enable`) and `tools/game.py`. Record findings in docs/game-automation.md.

## Do not

- Do not use rw3d_cli `reload`: it drops blob mods from the running game. Rebuild with `build_mod.py` and restart instead.
- Do not reach for key presses or screenshots unless the scripted route cannot work (e.g. a hang before scripts run, or the user asks what is on screen). Fallback scripts: `tools/focus_game.ps1`, `tools/send_key.ps1` (scan codes; Shift does not work, so no `(`), `tools/screenshot.ps1 <out.png>` (save to the scratchpad and view it with Read). Key presses need the game window in front.
