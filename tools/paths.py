"""Where the game and REDkit are installed, without hard-coded paths.

Each tool takes its install folders from here:

    W3_GAME_DIR     The Witcher 3 (5.x) install folder
    W3_REDKIT_DIR   The Witcher 3 REDkit install folder
    STEAM_DIR       the Steam folder, only used when the two above are not set

Without the environment variables the folders are looked up in Steam: the Steam folder
from the registry (HKCU\\Software\\Valve\\Steam, SteamPath), its libraries from
steamapps\\libraryfolders.vdf, and each app's folder from its appmanifest_<id>.acf.

    python tools/paths.py      prints what it finds
"""

import os
import re
import sys
from pathlib import Path

GAME_APP = "292030"      # The Witcher 3: Wild Hunt
REDKIT_APP = "2684660"   # The Witcher 3 REDkit


def steam_dir() -> Path | None:
    if os.environ.get("STEAM_DIR"):
        return Path(os.environ["STEAM_DIR"])
    try:
        import winreg
        with winreg.OpenKey(winreg.HKEY_CURRENT_USER, r"Software\Valve\Steam") as key:
            return Path(winreg.QueryValueEx(key, "SteamPath")[0])
    except OSError:
        return None


def steam_libraries() -> list[Path]:
    steam = steam_dir()
    if not steam:
        return []
    libraries = [steam]
    vdf = steam / "steamapps" / "libraryfolders.vdf"
    if vdf.exists():
        for value in re.findall(r'"path"\s+"([^"]+)"', vdf.read_text(encoding="utf-8", errors="replace")):
            path = Path(value.replace("\\\\", "\\"))
            if path not in libraries:
                libraries.append(path)
    return libraries


def steam_app_dir(app_id: str) -> Path | None:
    for library in steam_libraries():
        manifest = library / "steamapps" / f"appmanifest_{app_id}.acf"
        if manifest.exists():
            m = re.search(r'"installdir"\s+"([^"]+)"', manifest.read_text(encoding="utf-8", errors="replace"))
            if m:
                return library / "steamapps" / "common" / m.group(1)
    return None


def _find(env: str, app_id: str, what: str) -> Path:
    if os.environ.get(env):
        return Path(os.environ[env])
    found = steam_app_dir(app_id)
    if found:
        return found
    sys.exit(f"error: cannot find {what}: not installed through Steam (app {app_id}); set {env} to its folder")


def game_dir() -> Path:
    return _find("W3_GAME_DIR", GAME_APP, "The Witcher 3")


def redkit_dir() -> Path:
    return _find("W3_REDKIT_DIR", REDKIT_APP, "The Witcher 3 REDkit")


if __name__ == "__main__":
    print(f"steam:  {steam_dir()}")
    print(f"game:   {game_dir()}")
    print(f"redkit: {redkit_dir()}")
