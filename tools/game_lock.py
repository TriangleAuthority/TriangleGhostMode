"""The game slot: one holder at a time for the single game install (parallel ports).

Agents porting areas in parallel share one game. This tool hands the game out in FIFO order
with a token, and `game.py` and `build_mod.py --install` refuse to change the game without
the holder's `--holder AREA:TOKEN`. See docs/proposals/parallel-ports.md and
docs/game-automation.md#the-game-slot.

    python tools/game_lock.py request --who AREA --why TEXT   take the slot, or queue (0 granted, 2 queued, 3 paused)
    python tools/game_lock.py wait --who AREA [--timeout S]   block until granted (0 granted, 2 timed out, 3 paused or revoked)
    python tools/game_lock.py status [--json]                 holder, queue, lease, pause
    python tools/game_lock.py release --holder AREA:TOKEN     end the turn (game closed): settings restored, log archived, saves compared
    python tools/game_lock.py cancel --who AREA               leave the queue
    python tools/game_lock.py pause [--why TEXT]              no new grants; the holder's game commands refused (the owner, the parent)
    python tools/game_lock.py resume                          grants again
    python tools/game_lock.py config [--claim-deadline S] [--lease S]   show or set the timings
    python tools/game_lock.py config [--test-save NAME] [--slot-save NAME] [--allow-save NAME] [--disallow-save NAME]
                                                              the saves game.py may load (per machine)
    python tools/game_lock.py preempt --parent [--why TEXT]   quit the game, end the holder's turn, revoke its token
    python tools/game_lock.py reclaim --parent [--force]      the same, for a slot whose lease expired
    python tools/game_lock.py watch [--interval S]            exit 4 with an ALERT line on anything the parent must see
    python tools/game_lock.py baseline --parent               snapshot the four settings files (game closed, the owner's OK)
    python tools/game_lock.py selftest                        offline test in a temporary folder

State: %LOCALAPPDATA%\\TGM\\ (state.json, config.json, events.log, baseline\\, logs\\), changed only under an
OS file lock (msvcrt.locking on the permanent file `lock`; the OS frees it when a process dies) and
written through a temporary file and os.replace.

Rules:
- A grant needs: the slot free, the agent first in the queue, no pause, the game closed, the canonical
  settings baseline taken and the four settings files equal to it. Every grant backs up the saves
  (robocopy /E /XO into %USERPROFILE%\\W3SaveBackup\\gamesaves) and lists them for the release's comparison.
- Claim deadline (config `claim_deadline_s`, default 300): a grant with no gated command in that time is
  skipped and its token revoked; the agent requests again.
- Lease (config `lease_s`, default 1200): renewed by every gated command; `watch` reports an expired
  lease and `reclaim --parent` takes the slot back.
- Release (game closed): the four settings files restored from the baseline, scriptslog.txt archived
  under logs\\, the saves compared with the grant's list and with the backup (differences logged, no save
  is ever restored), then the next agent in the queue is granted.

The environment variable TGM_LOCK_SELFTEST_ROOT moves every path (state, Documents, backup, the game's
running state) into a test folder; game.py and build_mod.py then stop after their gate check. Only the
self-test sets it.
"""

import argparse
import datetime
import json
import msvcrt
import os
import re
import secrets
import shutil
import subprocess
import sys
import tempfile
import time
from pathlib import Path

TOOLS = Path(__file__).resolve().parent
sys.path.insert(0, str(TOOLS))
import paths  # noqa: E402

TEST_ENV = "TGM_LOCK_SELFTEST_ROOT"
SETTINGS = ("dx12user.settings", "input.settings", "profile.settings", "mods.settings")
# ReShade (here with RenoDX add-ons) can crash or hang the game at start; it is turned off for every turn:
# the grant renames these files in <game>/bin/x64_dx12, the end of the turn puts them back.
RESHADE = ("dxgi.dll",)
RESHADE_OFF = ".gamelock-off"
DEFAULTS = {"claim_deadline_s": 300, "lease_s": 1200, "stale_s": 600, "poll_s": 2.0,
            # The saves game.py run/load accept (docs/game-automation.md#test-saves): save file names differ
            # on every machine, so they live here, not in the repository. `test` and `slot` are aliases.
            "test_save": "", "slot_save": "", "other_saves": []}
WHO = re.compile(r"^[A-Za-z0-9_.-]{1,40}$")
# exit codes
OK, ERROR, NOT_YET, STOPPED, ALERT = 0, 1, 2, 3, 4


class Refused(Exception):
    def __init__(self, msg: str, code: int = ERROR):
        super().__init__(msg)
        self.code = code


# --- where things are ------------------------------------------------------------------

class Env:
    def __init__(self):
        root = os.environ.get(TEST_ENV)
        self.test = bool(root)
        if self.test:
            root = Path(root)
            self.state = root / "state"
            self.w3docs = root / "docs" / "The Witcher 3"
            self.backup = root / "backup" / "gamesaves"
            self.running_flag = root / "game_running"
        else:
            self.state = Path(os.environ["LOCALAPPDATA"]) / "TGM"
            self.w3docs = paths.documents_dir() / "The Witcher 3"
            self.backup = Path(os.environ["USERPROFILE"]) / "W3SaveBackup" / "gamesaves"
            self.running_flag = None
        self.saves = self.w3docs / "gamesaves"
        self.scriptslog = self.w3docs / "scriptslog.txt"
        self.lockfile = self.state / "lock"
        self.statefile = self.state / "state.json"
        self.configfile = self.state / "config.json"
        self.events = self.state / "events.log"
        self.baseline = self.state / "baseline"
        self.logs = self.state / "logs"
        for d in (self.state, self.logs):
            d.mkdir(parents=True, exist_ok=True)

    def game_running(self) -> bool:
        if self.test:
            return self.running_flag.exists()
        out = subprocess.run(["tasklist", "/FI", "IMAGENAME eq witcher3.exe", "/FO", "CSV", "/NH"],
                             capture_output=True, text=True).stdout
        return "witcher3.exe" in out.lower()

    def quit_game(self) -> None:
        if self.test:
            self.running_flag.unlink(missing_ok=True)
            return
        if self.game_running():
            subprocess.run([sys.executable, str(TOOLS / "game.py"), "quit"])


# --- the OS file lock --------------------------------------------------------------------

class FileLock:
    """An exclusive msvcrt lock on byte 0 of a permanent file; the OS releases it when the process dies."""

    def __init__(self, path: Path, timeout: float = 120, what: str = "the game lock", quiet: bool = True):
        self.path, self.timeout, self.what, self.quiet = path, timeout, what, quiet
        self.fd = None

    def __enter__(self):
        self.path.parent.mkdir(parents=True, exist_ok=True)
        self.fd = os.open(str(self.path), os.O_RDWR | os.O_CREAT | os.O_BINARY)
        end = time.monotonic() + self.timeout
        told = False
        while True:
            os.lseek(self.fd, 0, os.SEEK_SET)
            try:
                msvcrt.locking(self.fd, msvcrt.LK_NBLCK, 1)
                return self
            except OSError:
                if time.monotonic() > end:
                    os.close(self.fd)
                    raise Refused(f"timed out after {self.timeout:.0f} s waiting for {self.what} ({self.path})")
                if not self.quiet and not told:
                    print(f"waiting for {self.what} ...", flush=True)
                    told = True
                time.sleep(0.05 if self.quiet else 1)

    def __exit__(self, *exc):
        try:
            os.lseek(self.fd, 0, os.SEEK_SET)
            msvcrt.locking(self.fd, msvcrt.LK_UNLCK, 1)
        finally:
            os.close(self.fd)


# --- state -------------------------------------------------------------------------------

def now() -> float:
    return time.time()


def stamp(t: float | None = None) -> str:
    return datetime.datetime.fromtimestamp(t or now()).strftime("%Y-%m-%d %H:%M:%S")


def write_json(path: Path, data) -> None:
    fd, tmp = tempfile.mkstemp(dir=str(path.parent), prefix=path.name + ".", suffix=".tmp")
    with os.fdopen(fd, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=1)
    for attempt in range(50):  # a virus scanner or indexer may hold the target for a moment
        try:
            os.replace(tmp, path)
            return
        except PermissionError:
            time.sleep(0.1)
    os.replace(tmp, path)


def allowed_saves(env: "Env | None" = None) -> dict:
    """The saves game.py may load, from config.json: {'test': name, 'slot': name, <name>: name, ...}."""
    cfg = load_config(env or Env())
    out = {}
    for alias, key in (("test", "test_save"), ("slot", "slot_save")):
        if cfg.get(key):
            out[alias] = cfg[key]
    for name in cfg.get("other_saves") or []:
        out[name] = name
    for name in list(out.values()):
        out.setdefault(name, name)
    return out


def load_config(env: Env) -> dict:
    cfg = dict(DEFAULTS)
    if env.configfile.exists():
        cfg.update(json.loads(env.configfile.read_text(encoding="utf-8")))
    else:
        write_json(env.configfile, cfg)
    return cfg


def empty_state() -> dict:
    return {"holder": None, "queue": [], "paused": None, "ending": None, "revoked": {}, "blocked": None, "seq": 0}


def load_state(env: Env) -> dict:
    if not env.statefile.exists():
        return empty_state()
    st = json.loads(env.statefile.read_text(encoding="utf-8"))
    for k, v in empty_state().items():
        st.setdefault(k, v)
    return st


def event(env: Env, st: dict, kind: str, **data) -> None:
    st["seq"] += 1
    rec = {"seq": st["seq"], "at": stamp(), "event": kind, **data}
    with open(env.events, "a", encoding="utf-8") as f:
        f.write(json.dumps(rec) + "\n")


class Session:
    """The state, loaded and saved under the file lock."""

    def __init__(self, env: Env | None = None):
        self.env = env or Env()
        self.lock = FileLock(self.env.lockfile)

    def __enter__(self):
        self.lock.__enter__()
        try:
            self.cfg = load_config(self.env)
            self.st = load_state(self.env)
            self.before = json.dumps(self.st, sort_keys=True)
        except BaseException:
            self.lock.__exit__(None, None, None)
            raise
        return self

    def __exit__(self, *exc):
        try:
            if json.dumps(self.st, sort_keys=True) != self.before:
                write_json(self.env.statefile, self.st)
        finally:
            self.lock.__exit__(*exc)


# --- the rules ---------------------------------------------------------------------------

def settings_differ(env: Env) -> list[str]:
    """Settings files that differ from the baseline (all of them when there is no baseline)."""
    out = []
    for name in SETTINGS:
        base, live = env.baseline / name, env.w3docs / name
        if not base.exists():
            out.append(f"{name} (no baseline)")
        elif not live.exists() or live.read_bytes() != base.read_bytes():
            out.append(name)
    return out


def saves_list(env: Env) -> dict:
    if not env.saves.is_dir():
        return {}
    return {p.name: [p.stat().st_size, int(p.stat().st_mtime)] for p in env.saves.iterdir() if p.is_file()}


def backup_saves(env: Env) -> tuple[bool, str]:
    """robocopy the saves into the backup (copies only, never deletes); exit codes 0-7 are success."""
    env.backup.mkdir(parents=True, exist_ok=True)
    r = subprocess.run(["robocopy", str(env.saves), str(env.backup), "/E", "/XO", "/NFL", "/NDL", "/NJH", "/NJS", "/NP"],
                       capture_output=True, text=True, errors="replace")
    return r.returncode < 8, f"robocopy exit {r.returncode}"


def reshade_dir(env: Env) -> Path | None:
    if env.test:
        return None
    try:
        return paths.game_dir() / "bin" / "x64_dx12"
    except Exception:
        return None


def reshade_off(env: Env) -> str:
    """Rename ReShade's files so the game starts without it. Returns a note for the event log."""
    d = reshade_dir(env)
    if not d:
        return "no game folder"
    done = []
    for n in RESHADE:
        if (d / n).exists() and not (d / (n + RESHADE_OFF)).exists():
            (d / n).rename(d / (n + RESHADE_OFF))
            done.append(n)
    return f"ReShade off ({', '.join(done)})" if done else "no ReShade to turn off"


def reshade_on(env: Env) -> str | None:
    """Put back the files reshade_off renamed. Returns a report line, or None if nothing was off."""
    d = reshade_dir(env)
    if not d:
        return None
    done = []
    for n in RESHADE:
        if (d / (n + RESHADE_OFF)).exists() and not (d / n).exists():
            (d / (n + RESHADE_OFF)).rename(d / n)
            done.append(n)
    return f"ReShade back on ({', '.join(done)})" if done else None


def try_grant(env: Env, s: Session) -> None:
    st = s.st
    if st["holder"] or st["ending"] or not st["queue"]:
        return
    if st["paused"]:
        return
    reasons = []
    if not (env.baseline / SETTINGS[0]).exists():
        reasons.append("no settings baseline (the parent runs: game_lock.py baseline --parent)")
    if env.game_running():
        reasons.append("the game is running")
    diff = settings_differ(env) if not reasons else []
    if diff:
        reasons.append("settings differ from the baseline: " + ", ".join(diff))
    if reasons:
        reason = "; ".join(reasons)
        if st["blocked"] != reason:
            st["blocked"] = reason
            event(env, st, "blocked", reason=reason)
        return
    ok, info = backup_saves(env)
    if not ok:
        reason = f"saves backup failed ({info})"
        if st["blocked"] != reason:
            st["blocked"] = reason
            event(env, st, "blocked", reason=reason)
        return
    st["blocked"] = None
    try:
        info += "; " + reshade_off(env)
    except OSError as e:
        info += f"; ReShade not turned off ({e})"
    entry = st["queue"].pop(0)
    t = now()
    token = secrets.token_hex(4)
    st["holder"] = {"who": entry["who"], "why": entry.get("why", ""), "token": token, "granted_at": t,
                    "claimed": False, "lease_until": t + s.cfg["lease_s"], "last_cmd": None, "last_cmd_at": None,
                    "installed": None, "backup": f"{stamp(t)}, {info}"}
    st["revoked"].pop(entry["who"], None)
    write_json(env.state / "turn_saves.json", saves_list(env))
    event(env, st, "grant", who=entry["who"], backup=info)


def revoke(env: Env, st: dict, reason: str) -> None:
    h = st["holder"]
    st["revoked"][h["who"]] = {"token": h["token"], "reason": reason, "at": stamp()}
    st["holder"] = None


def housekeeping(s: Session) -> None:
    env, st, t = s.env, s.st, now()
    h = st["holder"]
    if h and not h["claimed"] and t > h["granted_at"] + s.cfg["claim_deadline_s"]:
        event(env, st, "skip", who=h["who"], reason=f"no game command within the claim deadline ({s.cfg['claim_deadline_s']} s)")
        revoke(env, st, f"claim deadline missed ({s.cfg['claim_deadline_s']} s without a game command); request again")
    try_grant(env, s)


def end_turn(env: Env, st: dict, who: str, how: str) -> list[str]:
    """Restore the settings, archive the script log, compare the saves. Returns the report lines."""
    report = []
    missing = [n for n in SETTINGS if not (env.baseline / n).exists()]
    if missing:
        report.append(f"WARNING: no baseline for {', '.join(missing)}: not restored")
    for name in SETTINGS:
        if name not in missing:
            shutil.copy2(env.baseline / name, env.w3docs / name)
    report.append(f"settings restored from the baseline: {', '.join(n for n in SETTINGS if n not in missing)}")
    try:
        line = reshade_on(env)
    except OSError as e:
        line = f"WARNING: ReShade not put back ({e}): rename <game>/bin/x64_dx12/dxgi.dll{RESHADE_OFF} to dxgi.dll"
    if line:
        report.append(line)
    if env.scriptslog.exists():
        dst = env.logs / f"{who}-{datetime.datetime.now():%Y%m%d-%H%M%S}-scriptslog.txt"
        shutil.copy2(env.scriptslog, dst)
        report.append(f"script log archived: {dst}")
    else:
        report.append("no script log to archive")
    before_file = env.state / "turn_saves.json"
    before = json.loads(before_file.read_text(encoding="utf-8")) if before_file.exists() else {}
    live = saves_list(env)
    gone = sorted(set(before) - set(live))
    new = sorted(set(live) - set(before))
    changed = sorted(n for n in set(before) & set(live) if before[n] != live[n])
    backed = {p.name for p in env.backup.iterdir()} if env.backup.is_dir() else set()
    not_live = sorted(backed - set(live))
    clean = not (gone or new or changed or not_live)
    report.append(f"saves: {len(live)} live, {len(backed)} in the backup; during the turn: "
                  f"{len(gone)} gone, {len(new)} new, {len(changed)} changed; in the backup but not live: {len(not_live)}"
                  + (" (clean)" if clean else ""))
    for label, names in (("gone", gone), ("new", new), ("changed", changed), ("backup only", not_live)):
        for n in names[:20]:
            report.append(f"  {label}: {n}")
        if len(names) > 20:
            report.append(f"  {label}: ... {len(names) - 20} more")
    event(env, st, "end", who=who, how=how, saves_clean=clean, gone=gone, new=new, changed=changed, backup_only=not_live)
    return report


# --- the gate (used by game.py and build_mod.py) -------------------------------------------

class Gate:
    def __init__(self, who: str, token: str, parent: bool, test: bool, installed: dict | None):
        self.who, self.token, self.parent, self.test, self.installed = who, token, parent, test, installed


def gate(holder: str | None, parent: bool, command: str) -> Gate:
    """Check that `holder` (AREA:TOKEN) holds the slot and renew its lease; raise Refused otherwise.
    `parent` skips the check (emergencies and the parent's own runs) and logs it."""
    env = Env()
    with Session(env) as s:
        housekeeping(s)
        st = s.st
        if parent:
            event(env, st, "parent-bypass", command=command)
            h = st["holder"]
            return Gate("parent", "", True, env.test, h.get("installed") if h else None)
        if not holder or ":" not in holder:
            raise Refused(f"{command} changes the game: pass --holder AREA:TOKEN "
                          "(python tools/game_lock.py request --who AREA --why ..., then wait)")
        who, token = holder.split(":", 1)
        h = st["holder"]
        if not h or h["who"] != who or h["token"] != token:
            rv = st["revoked"].get(who)
            if rv and rv["token"] == token:
                raise Refused(f"your token was revoked ({rv['at']}): {rv['reason']}", STOPPED)
            raise Refused(f"{who} does not hold the game slot (holder: {h['who'] if h else 'nobody'}); "
                          "request it and wait for the grant")
        if st["ending"]:
            raise Refused(f"the turn is being ended: {st['ending']['why']}", STOPPED)
        if st["paused"]:
            raise Refused(f"paused by {st['paused']['by']} ({st['paused']['why']}): quit the game and release", STOPPED)
        t = now()
        h["claimed"] = True
        h["lease_until"] = t + s.cfg["lease_s"]
        h["last_cmd"], h["last_cmd_at"] = command, t
        return Gate(who, token, False, env.test, h.get("installed"))


def record_install(g: Gate, marker: str) -> None:
    """Remember what the holder installed this turn (the first line of .built-by-build_mod)."""
    env = Env()
    with Session(env) as s:
        h = s.st["holder"]
        if g.parent:
            event(env, s.st, "parent-install", marker=marker)
            if h:
                h["installed"] = {"marker": marker, "by": "parent", "at": stamp()}
            return
        if h and h["who"] == g.who and h["token"] == g.token:
            h["installed"] = {"marker": marker, "by": g.who, "at": stamp()}
            event(env, s.st, "install", who=g.who, marker=marker)


def selftest_stop(g: Gate, what: str) -> None:
    """In the self-test, game.py and build_mod.py stop after the gate: they never touch the real game."""
    if g.test:
        print(f"selftest: gate passed for {what} ({g.who})")
        sys.exit(OK)


# --- commands ------------------------------------------------------------------------------

def check_who(who: str) -> str:
    if not WHO.match(who or ""):
        raise Refused(f"--who must be a short name (letters, digits, - _ .): {who!r}")
    return who


def show(s: Session) -> list[str]:
    st, t, cfg = s.st, now(), s.cfg
    out = []
    h = st["holder"]
    if h:
        lease = h["lease_until"] - t
        claim = "" if h["claimed"] else f", unclaimed ({cfg['claim_deadline_s'] - (t - h['granted_at']):.0f} s left to claim)"
        last = f", last command {h['last_cmd']} {t - h['last_cmd_at']:.0f} s ago" if h["last_cmd_at"] else ""
        out.append(f"holder: {h['who']} since {stamp(h['granted_at'])} ({h['why']}); lease "
                   + (f"{lease:.0f} s left" if lease > 0 else f"EXPIRED {-lease:.0f} s ago") + claim + last)
        if h.get("installed"):
            out.append(f"  installed this turn: {h['installed']['marker']}")
    else:
        out.append("holder: none")
    if st["ending"]:
        out.append(f"ending: {st['ending']['why']}")
    out.append("queue: " + (", ".join(f"{i + 1}. {q['who']} ({q.get('why', '')})" for i, q in enumerate(st["queue"])) or "empty"))
    out.append(f"paused: by {st['paused']['by']} since {st['paused']['at']} ({st['paused']['why']})" if st["paused"] else "paused: no")
    if st["blocked"]:
        out.append(f"blocked: {st['blocked']}")
    out.append(f"config: claim deadline {cfg['claim_deadline_s']} s, lease {cfg['lease_s']} s ({s.env.configfile})")
    return out


def cmd_request(a) -> int:
    who = check_who(a.who)
    with Session() as s:
        housekeeping(s)
        st = s.st
        h = st["holder"]
        if h and h["who"] == who:
            print(f"granted: you already hold the slot; token {h['token']} (--holder {who}:{h['token']})")
            return OK
        if not any(q["who"] == who for q in st["queue"]):
            st["queue"].append({"who": who, "why": a.why, "since": stamp()})
            event(s.env, st, "request", who=who, why=a.why)
            try_grant(s.env, s)
        h = st["holder"]
        if h and h["who"] == who:
            print(f"granted: token {h['token']} (--holder {who}:{h['token']}); saves backed up ({h['backup']})")
            return OK
        pos = [q["who"] for q in st["queue"]].index(who) + 1
        print(f"queued: position {pos} of {len(st['queue'])}" + (f"; blocked: {st['blocked']}" if st["blocked"] else ""))
        if st["paused"]:
            print(f"paused by {st['paused']['by']}: {st['paused']['why']}")
            return STOPPED
        return NOT_YET


def cmd_wait(a) -> int:
    who = check_who(a.who)
    end = time.monotonic() + a.timeout
    told = None
    while True:
        with Session() as s:
            housekeeping(s)
            st = s.st
            h = st["holder"]
            if h and h["who"] == who:
                print(f"granted: token {h['token']} (--holder {who}:{h['token']}); saves backed up ({h['backup']})")
                return OK
            if st["paused"]:
                print(f"paused by {st['paused']['by']}: {st['paused']['why']} (still queued)")
                return STOPPED
            names = [q["who"] for q in st["queue"]]
            if who not in names:
                rv = st["revoked"].get(who)
                if rv:
                    print(f"not queued: your last token was revoked ({rv['at']}): {rv['reason']}")
                    return STOPPED
                print("not queued: request first (game_lock.py request --who ... --why ...)")
                return ERROR
            pos = (names.index(who) + 1, len(names), st["blocked"])
            poll = s.cfg["poll_s"]
        if pos != told:
            print(f"waiting: position {pos[0]} of {pos[1]}" + (f"; blocked: {pos[2]}" if pos[2] else ""), flush=True)
            told = pos
        if time.monotonic() > end:
            print(f"timed out after {a.timeout:.0f} s (still queued: run wait again)")
            return NOT_YET
        time.sleep(poll)


def cmd_status(a) -> int:
    with Session() as s:
        housekeeping(s)
        if a.json:
            print(json.dumps({"state": s.st, "config": s.cfg}, indent=1))
        else:
            print("\n".join(show(s)))
    return OK


def parse_holder(holder: str) -> tuple[str, str]:
    if not holder or ":" not in holder:
        raise Refused("--holder AREA:TOKEN")
    return tuple(holder.split(":", 1))


def cmd_release(a) -> int:
    who, token = parse_holder(a.holder)
    env = Env()
    with Session(env) as s:
        st = s.st
        h = st["holder"]
        if not h or h["who"] != who or h["token"] != token:
            rv = st["revoked"].get(who)
            if rv and rv["token"] == token:
                print(f"nothing to release: your token was revoked ({rv['at']}): {rv['reason']}")
                return OK
            raise Refused(f"{who} does not hold the slot with that token")
        if env.game_running():
            raise Refused("the game is running: python tools/game.py quit first")
        report = end_turn(env, st, who, "released")
        st["holder"] = None
        event(env, st, "release", who=who)
        housekeeping(s)
        nxt = st["holder"]["who"] if st["holder"] else None
    print("\n".join(report))
    print(f"released; next: {nxt or 'nobody waiting'}")
    return OK


def cmd_cancel(a) -> int:
    who = check_who(a.who)
    with Session() as s:
        before = len(s.st["queue"])
        s.st["queue"] = [q for q in s.st["queue"] if q["who"] != who]
        if len(s.st["queue"]) == before:
            h = s.st["holder"]
            print("you hold the slot: release it instead" if h and h["who"] == who else "not queued")
            return OK
        event(s.env, s.st, "cancel", who=who)
        housekeeping(s)
    print("left the queue")
    return OK


def cmd_pause(a) -> int:
    with Session() as s:
        s.st["paused"] = {"by": a.by, "why": a.why, "at": stamp()}
        event(s.env, s.st, "pause", by=a.by, why=a.why)
        h = s.st["holder"]
    print(f"paused: no new grants; waiting agents get exit code 3"
          + (f"; the holder {h['who']}'s game commands are refused: it quits and releases" if h else ""))
    return OK


def cmd_resume(a) -> int:
    with Session() as s:
        s.st["paused"] = None
        event(s.env, s.st, "resume")
        housekeeping(s)
        h = s.st["holder"]
    print("resumed" + (f"; holder: {h['who']}" if h else ""))
    return OK


def cmd_config(a) -> int:
    env = Env()
    with Session(env) as s:
        changed = False
        for key, val in (("claim_deadline_s", a.claim_deadline), ("lease_s", a.lease),
                         ("test_save", a.test_save), ("slot_save", a.slot_save)):
            if val is not None:
                s.cfg[key] = val
                changed = True
        other = list(s.cfg.get("other_saves") or [])
        for name in a.allow_save or []:
            if name not in other:
                other.append(name)
                changed = True
        for name in a.disallow_save or []:
            if name in other:
                other.remove(name)
                changed = True
        s.cfg["other_saves"] = other
        if changed:
            write_json(env.configfile, s.cfg)
            event(env, s.st, "config", **{k: s.cfg.get(k) for k in ("claim_deadline_s", "lease_s", "test_save",
                                                                       "slot_save", "other_saves")})
        print(json.dumps(s.cfg, indent=1))
    return OK


def need_parent(a, what: str) -> None:
    if not a.parent:
        raise Refused(f"{what} is for the parent only: pass --parent")


def take_back(a, how: str) -> int:
    env = Env()
    with Session(env) as s:
        st = s.st
        h = st["holder"]
        if not h:
            print("nobody holds the slot")
            return OK
        if how == "reclaimed" and h["lease_until"] > now() and not a.force:
            raise Refused(f"{h['who']}'s lease has {h['lease_until'] - now():.0f} s left (--force to take it anyway)")
        who = h["who"]
        revoke(env, st, f"{how} by the parent" + (f": {a.why}" if a.why else ""))
        st["ending"] = {"who": who, "why": f"{how} by the parent", "at": stamp()}
        event(env, st, how, who=who, why=a.why)
    env.quit_game()  # outside the lock: quitting takes up to a minute or two
    with Session(env) as s:
        if env.game_running():
            event(env, s.st, "blocked", reason="the game is still running after the quit")
            raise Refused("the game is still running; the turn stays ending (quit it, then run this again)")
        report = end_turn(env, s.st, who, how)
        s.st["ending"] = None
        housekeeping(s)
        nxt = s.st["holder"]["who"] if s.st["holder"] else None
    print("\n".join(report))
    print(f"{how} {who}'s turn; next: {nxt or 'nobody (or paused)'}")
    return OK


def cmd_preempt(a) -> int:
    need_parent(a, "preempt")
    return take_back(a, "preempted")


def cmd_reclaim(a) -> int:
    need_parent(a, "reclaim")
    return take_back(a, "reclaimed")


def cmd_watch(a) -> int:
    env = Env()
    with Session(env) as s:
        start = s.st["seq"]
    print(f"watching (every {a.interval:.0f} s) ...", flush=True)
    while True:
        alerts = []
        with Session(env) as s:
            housekeeping(s)
            st, t = s.st, now()
            h = st["holder"]
            if st["paused"]:
                alerts.append(f"paused by {st['paused']['by']}: {st['paused']['why']}")
            if st["blocked"] and st["queue"]:
                alerts.append(f"grants blocked: {st['blocked']}")
            if h and h["lease_until"] < t:
                alerts.append(f"{h['who']}'s lease expired {t - h['lease_until']:.0f} s ago (reclaim --parent)")
            elif h and h["claimed"] and h["last_cmd_at"] and t - h["last_cmd_at"] > s.cfg["stale_s"]:
                alerts.append(f"{h['who']} is stale: no game command for {t - h['last_cmd_at']:.0f} s")
            if st["seq"] > start:
                for line in env.events.read_text(encoding="utf-8").splitlines()[-200:]:
                    e = json.loads(line)
                    if e["seq"] > start and e["event"] in ("skip", "blocked", "preempted", "reclaimed", "pause"):
                        alerts.append(f"event {e['event']}: " + ", ".join(f"{k}={v}" for k, v in e.items() if k not in ("seq", "event")))
                    if e["seq"] > start and e["event"] == "end" and not e.get("saves_clean"):
                        alerts.append(f"saves differ after {e['who']}'s turn: gone {e['gone']}, new {e['new']}, "
                                      f"changed {e['changed']}, backup only {len(e['backup_only'])}")
                start = st["seq"]
        if alerts:
            for x in alerts:
                print(f"ALERT: {x}")
            return ALERT
        if a.once:
            print("no alerts")
            return OK
        time.sleep(a.interval)


def cmd_baseline(a) -> int:
    need_parent(a, "baseline")
    env = Env()
    with Session(env) as s:
        if env.game_running():
            raise Refused("the game is running: the baseline is taken only with the game closed")
        if s.st["holder"] and not a.force:
            raise Refused(f"{s.st['holder']['who']} holds the slot (--force to take the baseline anyway)")
        missing = [n for n in SETTINGS if not (env.w3docs / n).exists()]
        if missing:
            raise Refused(f"missing settings files: {', '.join(missing)}")
        env.baseline.mkdir(parents=True, exist_ok=True)
        for n in SETTINGS:
            shutil.copy2(env.w3docs / n, env.baseline / n)
        (env.baseline / "taken.txt").write_text(f"{stamp()} {a.why}\n", encoding="utf-8")
        s.st["blocked"] = None
        event(env, s.st, "baseline", why=a.why)
        housekeeping(s)
    print(f"baseline taken: {', '.join(SETTINGS)} -> {env.baseline}")
    return OK


# --- self-test -----------------------------------------------------------------------------

def cmd_selftest(a) -> int:
    import game_lock_selftest
    return game_lock_selftest.run(keep=a.keep)


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="command", required=True)
    p = sub.add_parser("request"); p.set_defaults(fn=cmd_request)
    p.add_argument("--who", required=True); p.add_argument("--why", required=True)
    p = sub.add_parser("wait"); p.set_defaults(fn=cmd_wait)
    p.add_argument("--who", required=True); p.add_argument("--timeout", type=float, default=540)
    p = sub.add_parser("status"); p.set_defaults(fn=cmd_status); p.add_argument("--json", action="store_true")
    p = sub.add_parser("release"); p.set_defaults(fn=cmd_release); p.add_argument("--holder", required=True)
    p = sub.add_parser("cancel"); p.set_defaults(fn=cmd_cancel); p.add_argument("--who", required=True)
    p = sub.add_parser("pause"); p.set_defaults(fn=cmd_pause)
    p.add_argument("--by", default="owner"); p.add_argument("--why", default="the owner takes the computer back")
    p = sub.add_parser("resume"); p.set_defaults(fn=cmd_resume)
    p = sub.add_parser("config"); p.set_defaults(fn=cmd_config)
    p.add_argument("--claim-deadline", type=float); p.add_argument("--lease", type=float)
    p.add_argument("--test-save", help="the test save's file name, without .sav (game.py run test)")
    p.add_argument("--slot-save", help="the test-only slot's file name (game.py run slot)")
    p.add_argument("--allow-save", action="append", help="another save game.py may load, by full name (repeatable)")
    p.add_argument("--disallow-save", action="append", help="take a save off that list (repeatable)")
    for name, fn in (("preempt", cmd_preempt), ("reclaim", cmd_reclaim)):
        p = sub.add_parser(name); p.set_defaults(fn=fn)
        p.add_argument("--parent", action="store_true"); p.add_argument("--why", default="")
        p.add_argument("--force", action="store_true")
    p = sub.add_parser("watch"); p.set_defaults(fn=cmd_watch)
    p.add_argument("--interval", type=float, default=15); p.add_argument("--once", action="store_true")
    p = sub.add_parser("baseline"); p.set_defaults(fn=cmd_baseline)
    p.add_argument("--parent", action="store_true"); p.add_argument("--force", action="store_true")
    p.add_argument("--why", default="")
    p = sub.add_parser("selftest"); p.set_defaults(fn=cmd_selftest)
    p.add_argument("--keep", action="store_true", help="keep the temporary folder")
    a = ap.parse_args()
    try:
        return a.fn(a)
    except Refused as e:
        print(f"refused: {e}")
        return e.code


if __name__ == "__main__":
    sys.exit(main())
