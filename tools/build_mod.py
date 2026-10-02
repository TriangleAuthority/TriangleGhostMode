"""Build an installable 5.x mod from a branch, and optionally install it.

The Ghost Mode branches hold the full vanilla file set with the mod's edits applied
(see docs/repository.md), so they cannot be installed as they are. This script takes
only what a branch changes relative to vanilla 5.x and builds a mod from it:

    <out>/scripts/<path>                     every script the branch adds or modifies,
                                             written straight from git objects (the
                                             working tree and checkout do not matter)
    <out>/<name>/content/precompiled.rsblob  those scripts compiled by REDkit's
                                             `wcc_lite compilescripts` against the game's
                                             own scripts (about 20 seconds; full log in
                                             <out>/compile.log)
    <out>/files/<depot path>                 every other game file the branch adds or
                                             modifies under modGhostMode/files
    <out>/<name>/content/blob0.bundle        those files packed by `wcc_lite pack` (zlib,
    <out>/<name>/content/metadata.store      like the 5.x game bundles), plus the metadata
                                             store from `wcc_lite metadatastore`
    <out>/<name>/content/<lang>.w3strings    the string tables: every
                                             modGhostMode/localization/<table>/<lang>.csv,
                                             merged per language and encoded by
                                             tools/w3strings.py
    <out>/<name>/bin/config/r4game/user_config_matrix/pc/<file>.xml
                                             the options menu: every modGhostMode/menu/*.xml.
                                             --install copies these into the game's own bin
                                             folder (the game reads menus only from there) and
                                             records them, so a reinstall removes stale ones

The mod ships the compiled blob, not loose scripts: 5.x applies scope-based overrides
and enum extensions only from a mod's precompiled.rsblob, and ignores a mod's loose
scripts when it has one. Compile errors therefore show up here, not at game start.
With --loose the mod gets the loose scripts instead (annotations and whole-file
overrides work that way; scope-based overrides and enum extensions do not).

Not handled (the script lists them and stops): anything else outside
modGhostMode/scripts, modGhostMode/files, modGhostMode/localization and
modGhostMode/menu.

Usage:
    python tools/build_mod.py --ref pilot-smoke                      # build into build/
    python tools/build_mod.py --ref pilot-smoke --install            # and copy into <game>/mods
    python tools/build_mod.py --ref pilot-smoke --install --enable   # and add it to mods.settings
    python tools/build_mod.py --scripts tools/automation/scripts --name modAutomation --out build/automation --install --enable
                                                                     # scripts from a folder instead of a branch

See docs/development.md.
"""

import argparse
import configparser
import ctypes
import shutil
import subprocess
import sys
from ctypes import wintypes
from pathlib import Path

import w3strings

REPO = Path(__file__).resolve().parent.parent
DEFAULT_GAME = Path(r"<Steam library>\steamapps\common\The Witcher 3")
DEFAULT_REDKIT = Path(r"<Steam library>\steamapps\common\The Witcher 3 REDkit")
SCRIPTS = "modGhostMode/scripts/"
FILES = "modGhostMode/files/"
LOCALIZATION = "modGhostMode/localization/"
MENU = "modGhostMode/menu/"
MENU_DIR = Path("bin") / "config" / "r4game" / "user_config_matrix" / "pc"
MARKER = ".built-by-build_mod"  # only folders carrying this are deleted on reinstall


def git(*args: str) -> bytes:
    return subprocess.run(["git", *args], cwd=REPO, check=True, capture_output=True).stdout


def changed_paths(base: str, ref: str) -> list[tuple[str, str]]:
    out = git("diff", "--name-status", "--no-renames", "-z", f"{base}...{ref}", "--", "modGhostMode")
    parts = out.decode("utf-8").split("\0")
    return [(parts[i], parts[i + 1]) for i in range(0, len(parts) - 1, 2)]


def documents_dir() -> Path:
    """The user's Documents folder, following OneDrive or other redirection."""
    folderid_documents = ctypes.c_byte * 16
    guid = folderid_documents(*bytes.fromhex("D09AD3FD8F23AF46ADB46C85480369C7"))
    path = ctypes.c_wchar_p()
    shell32 = ctypes.windll.shell32
    shell32.SHGetKnownFolderPath.argtypes = [ctypes.c_void_p, wintypes.DWORD, wintypes.HANDLE, ctypes.POINTER(ctypes.c_wchar_p)]
    if shell32.SHGetKnownFolderPath(ctypes.byref(guid), 0, None, ctypes.byref(path)) != 0:
        return Path.home() / "Documents"
    result = Path(path.value)
    ctypes.windll.ole32.CoTaskMemFree(path)
    return result


def collect(base: str, ref: str, out: Path) -> tuple[Path | None, Path | None, list[str], list[str]]:
    """Write what ref changes relative to base into <out>/scripts and <out>/files.

    Also returns the localization CSVs and menu XML files on ref (all of them: vanilla
    has none).
    """
    scripts, files, other, deleted = [], [], [], []
    for status, path in changed_paths(base, ref):
        if status == "D":
            deleted.append(path)
        elif path.startswith(SCRIPTS):
            scripts.append(path)
        elif path.startswith(FILES):
            files.append(path)
        elif path.startswith(LOCALIZATION) or path.startswith(MENU):
            pass
        else:
            other.append(path)
    localization = [p for p in git("ls-tree", "-r", "--name-only", ref, "--", LOCALIZATION).decode().splitlines()
                    if p.endswith(".csv")]
    menus = [p for p in git("ls-tree", "-r", "--name-only", ref, "--", MENU).decode().splitlines()
             if p.endswith(".xml")]

    if deleted:
        print(f"warning: {len(deleted)} file(s) deleted on {ref}; a mod cannot delete game files:")
        for p in deleted:
            print(f"  {p}")
    if other:
        print("error: this script cannot build these changes yet:")
        for p in other:
            print(f"  {p}")
        sys.exit(1)
    if not scripts and not files and not localization and not menus:
        print(f"nothing to build: {ref} changes nothing relative to {base}")
        sys.exit(1)

    result = []
    for paths, prefix, sub in ((scripts, SCRIPTS, "scripts"), (files, FILES, "files")):
        target_dir = out / sub
        if target_dir.exists():
            shutil.rmtree(target_dir)
        if not paths:
            result.append(None)
            continue
        for path in paths:
            target = target_dir / path[len(prefix):]
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(git("cat-file", "blob", f"{ref}:{path}"))
        print(f"collected {len(paths)} file(s) under {sub}/ from {ref}:")
        for path in paths:
            print(f"  {path[len(prefix):]}")
        result.append(target_dir)
    return result[0], result[1], localization, menus


def encode_strings(ref: str, csv_paths: list[str], out: Path) -> Path | None:
    """Merge the localization CSVs per language and encode one <lang>.w3strings each."""
    strings_dir = out / "strings"
    if strings_dir.exists():
        shutil.rmtree(strings_dir)
    if not csv_paths:
        return None
    strings_dir.mkdir()
    by_lang: dict[str, tuple[list, list]] = {}
    owner: dict[tuple[str, int], str] = {}
    tmp = out / "csv.tmp"
    for path in csv_paths:
        tmp.write_bytes(git("cat-file", "blob", f"{ref}:{path}"))
        lang, strings, keys = w3strings.read_csv(tmp)
        all_strings, all_keys = by_lang.setdefault(lang, ([], []))
        for sid, text in strings:
            if (lang, sid) in owner:
                print(f"error: string id {sid} is in both {owner[(lang, sid)]} and {path}")
                sys.exit(1)
            owner[(lang, sid)] = path
            all_strings.append((sid, text))
        all_keys.extend(keys)
    tmp.unlink()
    for lang, (strings, keys) in sorted(by_lang.items()):
        (strings_dir / f"{lang}.w3strings").write_bytes(w3strings.encode(lang, strings, keys))
    print(f"encoded strings: {', '.join(f'{lang} ({len(s)})' for lang, (s, _) in sorted(by_lang.items()))}")
    return strings_dir


def copy_scripts(src: Path, out: Path) -> Path:
    """Copy a folder of scripts (laid out like content/scripts) into <out>/scripts."""
    if not src.is_dir():
        print(f"error: {src} is not a folder")
        sys.exit(1)
    target_dir = out / "scripts"
    if target_dir.exists():
        shutil.rmtree(target_dir)
    shutil.copytree(src, target_dir)
    paths = sorted(p.relative_to(target_dir).as_posix() for p in target_dir.rglob("*.ws"))
    print(f"collected {len(paths)} script(s) from {src}:")
    for path in paths:
        print(f"  {path}")
    return target_dir


def wcc(redkit: Path, args: list[str], out: Path, log_name: str, what: str) -> None:
    """Run a wcc_lite commandlet; exit with its [Error][WCC] lines if it fails."""
    exe = redkit / "bin" / "x64_RedKit" / "wcc_lite.exe"
    if not exe.exists():
        print(f"error: {exe} not found (pass --redkit)")
        sys.exit(1)
    # -agreetoterms accepts the REDkit EULA, which wcc_lite otherwise asks for in a dialog
    # that blocks the build (the project owner accepted it and approved passing the flag).
    result = subprocess.run([str(exe), *args, "-agreetoterms"], cwd=exe.parent, capture_output=True, text=True,
                            errors="replace", timeout=600)
    log = out / log_name
    log.write_text(result.stdout + result.stderr, encoding="utf-8")
    # wcc_lite also logs unrelated [Error] lines about missing config files and asserts
    errors = [line for line in (result.stdout + result.stderr).splitlines() if "][Error][WCC]" in line]
    if result.returncode != 0:
        print(f"error: {what} failed:")
        for line in errors:
            print(f"  {line.split('][Error][WCC] ', 1)[-1]}")
        print(f"full log: {log}")
        sys.exit(1)


def compile_scripts(scripts_dir: Path, game: Path, redkit: Path, out: Path) -> Path:
    """Compile the game's scripts plus the mod's into a blob; exit on errors."""
    blob_dir = out / "scripts.rsblob"
    if blob_dir.exists():
        shutil.rmtree(blob_dir)
    print("compiling scripts with wcc_lite ...")
    # wcc_lite wants directories with a trailing backslash
    wcc(redkit, ["compilescripts", str(game / "content" / "content0" / "scripts") + "\\",
                 f"-patch={scripts_dir}\\", f"-out={blob_dir}"], out, "compile.log", "script compilation")
    print(f"scripts compile (log: {out / 'compile.log'})")
    return blob_dir / "blob.rsblob"


def pack_files(files_dir: Path, redkit: Path, out: Path) -> Path:
    """Pack the mod's game files into a bundle with its metadata store; exit on errors."""
    bundle_dir = out / "bundles"
    if bundle_dir.exists():
        shutil.rmtree(bundle_dir)
    bundle_dir.mkdir()
    print("packing files with wcc_lite ...")
    wcc(redkit, ["pack", f"-dir={files_dir}\\", f"-outdir={bundle_dir}\\", "-compression=ZLIB"],
        out, "pack.log", "packing")
    wcc(redkit, ["metadatastore", f"-path={bundle_dir}\\"], out, "metadatastore.log", "metadata store")
    print(f"packed: {', '.join(sorted(p.name for p in bundle_dir.iterdir()))}")
    return bundle_dir


def assemble(out: Path, name: str, source: str, scripts_dir: Path | None, blob: Path | None,
             bundle_dir: Path | None, strings_dir: Path | None = None, ref: str = "",
             menus: list[str] | None = None) -> Path:
    """Lay out the mod folder: script blob (or loose scripts), bundles, strings, menus."""
    mod_dir = out / name
    if mod_dir.exists():
        shutil.rmtree(mod_dir)
    content = mod_dir / "content"
    content.mkdir(parents=True)
    parts = []
    if blob:
        shutil.copy2(blob, content / "precompiled.rsblob")
        parts.append("precompiled.rsblob")
    elif scripts_dir:
        shutil.copytree(scripts_dir, content / "scripts")
        parts.append("loose scripts")
    if bundle_dir:
        for f in bundle_dir.iterdir():
            shutil.copy2(f, content / f.name)
        parts.append("bundle")
    if strings_dir:
        for f in strings_dir.iterdir():
            shutil.copy2(f, content / f.name)
        parts.append("strings")
    if menus:
        menu_dir = mod_dir / MENU_DIR
        menu_dir.mkdir(parents=True)
        for path in menus:
            (menu_dir / Path(path).name).write_bytes(git("cat-file", "blob", f"{ref}:{path}"))
        parts.append(f"menu ({', '.join(Path(p).name for p in menus)})")
    (mod_dir / MARKER).write_text(f"{source}\n")
    print(f"built {mod_dir} ({', '.join(parts)})")
    return mod_dir


def install(mod_dir: Path, game: Path) -> None:
    target = game / "mods" / mod_dir.name
    if target.exists():
        if not (target / MARKER).exists():
            print(f"error: {target} exists and was not installed by this script; not touching it")
            sys.exit(1)
        # remove the menu files the previous install put into the game's bin folder
        for line in (target / MARKER).read_text().splitlines()[1:]:
            old = game / line.strip()
            if line.strip() and old.is_file():
                old.unlink()
        shutil.rmtree(target)
    shutil.copytree(mod_dir, target, ignore=shutil.ignore_patterns("bin"))
    installed = []
    menu_src = mod_dir / MENU_DIR
    if menu_src.is_dir():
        (game / MENU_DIR).mkdir(parents=True, exist_ok=True)
        for f in sorted(menu_src.iterdir()):
            dest = game / MENU_DIR / f.name
            if dest.exists():
                print(f"error: {dest} already exists and is not ours; not overwriting it")
                sys.exit(1)
            shutil.copy2(f, dest)
            installed.append((MENU_DIR / f.name).as_posix())
    marker = target / MARKER
    lines = [marker.read_text().splitlines()[0], *installed]
    marker.write_text("".join(f"{line}\n" for line in lines))
    print(f"installed to {target}" + (f" (menu: {', '.join(installed)})" if installed else ""))


def check_settings(name: str, enable: bool) -> None:
    settings = documents_dir() / "The Witcher 3" / "mods.settings"
    cfg = configparser.ConfigParser()
    cfg.optionxform = str
    if settings.exists():
        cfg.read(settings, encoding="utf-8-sig")
    if cfg.has_section(name):
        state = "enabled" if cfg[name].get("Enabled", "1").strip() == "1" else "DISABLED"
        print(f"{settings}: [{name}] is {state}")
        return
    if not enable:
        print(f"{settings}: no [{name}] entry (pass --enable to add one)")
        return
    with settings.open("a", encoding="utf-8") as f:
        if settings.stat().st_size:
            f.write("\n")
        f.write(f"[{name}]\nEnabled=1\nPriority=100\n")
    print(f"{settings}: added [{name}] Enabled=1 Priority=100")


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--ref", default="5.x-GM", help="branch or commit to build (default: 5.x-GM)")
    ap.add_argument("--scripts", type=Path, help="build the scripts in this folder instead of a branch's changes")
    ap.add_argument("--base", default="vanilla-5.x", help="vanilla ref to diff against (default: vanilla-5.x)")
    ap.add_argument("--name", default="modGhostMode", help="mod folder name (default: modGhostMode)")
    ap.add_argument("--out", type=Path, default=REPO / "build", help="output directory (default: build/)")
    ap.add_argument("--install", action="store_true", help="copy the built mod into <game>/mods")
    ap.add_argument("--enable", action="store_true", help="with --install: add the mod to mods.settings if missing")
    ap.add_argument("--game", type=Path, default=DEFAULT_GAME, help="game install directory")
    ap.add_argument("--redkit", type=Path, default=DEFAULT_REDKIT, help="REDkit install directory (for wcc_lite)")
    ap.add_argument("--loose", action="store_true", help="ship loose scripts instead of precompiled.rsblob")
    ap.add_argument("--no-compile", action="store_true", help="with --loose: skip the wcc_lite compile check")
    args = ap.parse_args()
    if args.no_compile and not args.loose:
        ap.error("--no-compile needs --loose (the blob is the compiler's output)")
    out = args.out.resolve()

    strings_dir, menus = None, []
    if args.scripts:
        scripts_dir, files_dir = copy_scripts(args.scripts.resolve(), out), None
    else:
        scripts_dir, files_dir, csv_paths, menus = collect(args.base, args.ref, out)
        strings_dir = encode_strings(args.ref, csv_paths, out)
    blob = None
    if scripts_dir and not args.no_compile:
        blob = compile_scripts(scripts_dir, args.game, args.redkit, out)
    bundle_dir = pack_files(files_dir, args.redkit, out) if files_dir else None
    source = str(args.scripts) if args.scripts else f"{args.ref} {git('rev-parse', args.ref).decode().strip()}"
    mod_dir = assemble(out, args.name, source, scripts_dir, None if args.loose else blob, bundle_dir, strings_dir,
                       args.ref, menus)
    if args.install:
        install(mod_dir, args.game)
        check_settings(args.name, args.enable)


if __name__ == "__main__":
    main()
