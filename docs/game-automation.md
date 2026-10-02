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

Rebuild and reinstall after changing it with the build command in [Quick start](#quick-start) (without `--enable`). `build_mod.py --scripts <dir>` builds any folder of scripts (laid out like `content\scripts`) instead of a branch's changes.

It stays enabled in `mods.settings`, also for normal play. That's harmless (it only logs and adds exec functions), but saves made with it list it in their `.json` metadata. Disable it with `Enabled=0` if that matters.

## Findings

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

## Ideas not done

- A test runner on top of `game.py`: build, `run`, a list of exec calls with expected log lines, `quit`, report.
- Skip the main menu entirely: `autoload()` during the startup screens (untested whether loading works before the main menu exists).
- Answer the remaining open question about blobs with two throwaway mods wrapping the same method, using this loop.

## Log

- 2026-10-01: `modAutomation` and `tools/game.py`: whole loop without key presses or screenshots, about 29 s. Startup screens closed by script; exec wait cut to 500 ms.
- 2026-10-01: rw3d_cli v0.8.0 tested: `exec` works on 5.0 (any arguments); `reload` drops blob mods; `rootpath`/`modlist` replies not parsed.
- 2026-10-01: first manual run of the whole loop with simulated keys and screenshots. Game reported build 5.0.1044392 (the 5.0 hotfix; `vanilla-5.x` now matches it).
