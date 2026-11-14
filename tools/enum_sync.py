"""enum_sync: make script-blob mods that extend the same enum work together.

THE PROBLEM
    A mod's script blob (content/precompiled.rsblob) may add members to a vanilla enum, for
    example `enum EEffectType { EET_MyEffect }`. The compiler numbers them from the end of the
    vanilla enum as if the mod were alone, and writes those numbers into the mod's code as plain
    literals. At load the game merges every mod's members into one enum by name, appending them
    in load order. So when two mods extend the same enum, the second one's members get numbers
    its code does not use: both mods compiled their first member as 173, but only one of them
    gets 173. Every use of the other mod's members then points at the wrong member (in Ghost Mode
    with a second mod adding one effect type, all 18 Ghost Mode effects broke).

    Verified (TriangleGhostMode docs/development.md): a blob that declares the other mod's
    members first, in the same order, and its own after them, works: its numbers then match the
    merged enum. Placeholder members do not help (they are appended as extra names), and
    explicit values are refused by the compilers.

WHAT THIS TOOL DOES
    It gives every installed blob that extends an enum the same complete member list (the union
    of all of them, in mod load order), and renumbers the enum literals in that blob's code to
    match. Then all blobs agree on every number, whatever order the game loads them in.

    It patches the compiled blobs directly: nothing is decompiled or recompiled.
    - The enum declaration: the missing member names are inserted into the blob's enum (members
      in a blob carry no value; the game numbers them at load).
    - The code: every enum constant (a ByteConst/ShortConst/IntConst literal) whose expected type
      is the extended enum and whose value is one of the blob's own extension members is
      rewritten in place to the member's new number. Instructions keep their size, so no jump
      offsets change.
    - Default values (`default x = EET_MyEffect;`) are stored by name and need no change.

    Literals carry no type in the bytecode, so the tool infers each literal's expected type from
    its context: the variable it is assigned to, the parameter it is passed to, the type of the
    switch or comparison it appears in, the function's return type, and so on, using the vanilla
    script declarations (content/content0/scripts) and the blobs' own declarations. A literal in
    the range of the blob's own members whose type it cannot settle stops the run for that enum
    (nothing is written), listing where it is.

    Explicit numbers in a mod's code are left alone and reported: `(EEffectType)173` compiles to
    an int converted to the enum, not to the member, so no tool can tell what it meant.

TESTED (2026-11-14, game 5.x, TriangleGhostMode)
    - Ghost Mode's blob (wcc_lite, 2.5 MB, 18 EEffectType members, 4,009 functions): every
      function decodes; all 6,214 enum literals get a type that matches their value. Patched behind
      a one-member blob, it equals, function for function, Ghost Mode compiled by wcc_lite with that
      member declared first (only source line numbers differ).
    - In game, Ghost Mode plus two one-member probe blobs loading before it: with the list ordered
      probes first and with it ordered Ghost Mode first, both probes' effects worked at their new
      numbers and Ghost Mode's full regression passed in both skill trees each time.

LIMITS AND UNKNOWNS
    - Code that tests a range of its own members (e.g. `x > EET_EffectTypesSize && x <= MyLast`)
      also covers members of mods placed before it in the list.
    - Only enum literals are renumbered; enum values computed at runtime are fine, numbers written
      in data files (XML, entity templates) that refer to extension members are not touched.
    - Saves: an effect's type is not saved, so renumbering does not break saves for effects.
      A save that stores an enum value from a blob's extension (a saved variable of that enum
      type) would load with the old number. Check mods that save such values.
    - Re-run after adding, removing or updating a mod, as with merges. Originals are kept
      (precompiled.rsblob.enum_sync-original) and every run starts from them; `restore` puts
      them back.
    - Mods with loose scripts (no blob) that extend an enum are only reported.
    - Enums declared only in C++ (no script declaration) are not supported.
    - The numbering rule used for extension members (smallest unused values from 0) matches
      wcc_lite and WSCompiler for EEffectType (173 after EET_EffectTypesSize = 172, with
      EET_ForceEnumTo16Bit = 10000) and for gap-free enums; enums with gaps below their last
      value are reported.

USAGE
    python enum_sync.py check   [--mods DIR] [--scripts DIR]       report conflicts and the plan
    python enum_sync.py apply   [--mods DIR] [--scripts DIR]       patch the installed blobs
    python enum_sync.py restore [--mods DIR]                       put the originals back
    python enum_sync.py patch OUT_DIR BLOB [BLOB ...] [--scripts DIR]
        patch the given blobs (in that order) into OUT_DIR/<n>_<mod>/precompiled.rsblob;
        for build pipelines and tests. Order = load order.
    python enum_sync.py dump BLOB [FUNCTION]                       list a blob's enum literals

    --mods defaults to <game>/mods, --scripts to <game>/content/content0/scripts, where <game>
    is found as in tools/paths.py (W3_GAME_DIR or Steam). Load order: mods.settings Priority
    (lower first), then folder name, case-insensitive. Disabled mods are skipped.

    Requires Python 3.8+, no packages. Format reference: tools/rsblob.py.
"""

import argparse
import configparser
import hashlib
import json
import os
import shutil
import struct
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import rsblob  # noqa: E402
from ws_decls import Decls, elem_type, norm_type  # noqa: E402

ORIG_SUFFIX = ".enum_sync-original"
STATE_SUFFIX = ".enum_sync.json"

GLOBALS = {"GetGame": "CR4Game", "GetPlayer": "CR4Player", "GetCamera": "CCamera",
           "GetHud": "CR4ScriptedHud", "GetSound": "CScriptSoundSystem", "GetDebug": "CDebugAttributesManager",
           "GetTimer": "CTimerScriptKeyword", "GetInput": "CInputManager",
           "GetTelemetry": "CR4TelemetryScriptProxy"}
CONSTS = {"ByteConst", "ShortConst", "IntConst"}


# ---------------------------------------------------------------- type inference

class Site:
    __slots__ = ("func", "ins", "enum", "value", "status")

    def __init__(self, func, ins, enum, value, status):
        self.func, self.ins, self.enum, self.value, self.status = func, ins, enum, value, status

    def where(self):
        return f"{self.func} @{self.ins.pos} ({self.ins.name} {self.value})"


def _op_param_types(opname):
    parts = opname.split("_")[1:]
    m = {"Int32": "Int32", "Float": "Float", "String": "String", "Uint8": "Uint8", "Bool": "Bool",
         "Uint64": "Uint64"}
    return [m.get(p, "") for p in parts]


class Typer:
    """Walks one function's expression trees with the type each operand is expected to have,
    and reports the enum literals found (with their expected type, or "" when unknown)."""

    def __init__(self, decls: Decls, cls: str, func, blob):
        self.d = decls
        self.cls = cls
        self.f = func
        self.blob = blob
        self.locals = {p.name: norm_type(p.type_name) for p in func.params + func.locals}
        self.params = {p.name: norm_type(p.type_name) for p in func.params}
        self.ret = norm_type(func.ret.type_name) if func.ret else ""
        self.self_params = [norm_type(p.type_name) for p in func.params]
        self.found = []  # (Instr, expected type)
        self.switch_types = []

    # -------- types of expressions (only as far as needed)
    def type_of(self, n, ctx=None):
        name = n.name
        a = n.ins.args
        if name == "LocalVar":
            return self.locals.get(a[0], "")
        if name == "ParamVar":
            return self.params.get(a[0], "")
        if name in ("ObjectVar", "ObjectBindableVar", "DefaultVar"):
            prop, scope = a[0]
            return self.d.field(norm_type(scope) or self.cls, prop)
        if name == "StructMember":
            prop, scope = a[0]
            return self.d.field(norm_type(scope), prop)
        if name == "ArrayElement":
            return elem_type(norm_type(a[0]))
        if name == "ArrayLast":
            return elem_type(norm_type(a[0]))
        if name in ("StaticArrayElement", "StaticArrayLast"):
            return ""
        if name == "Context":
            return self.type_of(n.kids[1], self.type_of(n.kids[0]))
        if name in ("FinalFunc", "VirtualFunc", "VirtualParentFunc", "EntryFunc"):
            f = self.callee(n, ctx)
            return f.ret if f else ""
        if name in ("DynamicCast", "New", "IntToEnum"):
            return norm_type(a[0])
        if name == "This":
            return self.cls
        if name == "Parent":
            k = self.d.klass(self.cls)
            return k.machine if k else ""
        if name == "Skip":
            return self.type_of(n.kids[0], ctx)
        if name in GLOBALS:
            return GLOBALS[name]
        if name in ("IntConst", "IntZero", "IntOne", "EnumToInt") or name.endswith("ToInt"):
            return "Int32"
        if name == "FloatConst" or name.endswith("ToFloat"):
            return "Float"
        if name in ("StringConst", "EnumToString") or name.endswith("ToString"):
            return "String"
        if name == "NameConst":
            return "CName"
        if name in ("BoolTrue", "BoolFalse", "TestEqual", "TestNotEqual") or name.endswith("ToBool"):
            return "Bool"
        if name == "Conditional":
            return self.type_of(n.kids[1], ctx) or self.type_of(n.kids[2], ctx)
        return ""

    def callee(self, n, ctx):
        """The called function's declaration (ws_decls.Func), or None."""
        name = n.name
        a = n.ins.args
        if name == "FinalFunc":
            ref = a[2]
            if ref[0] == "self":
                return _FakeFunc(self.self_params, self.ret)
            if ref[0] == "op":
                return _FakeFunc(_op_param_types(ref[1]), "")
            _, fname, scope = ref
            scope = norm_type(scope)
            if scope:
                return self.d.method(scope, fname) or self._by_name(fname)
            return self.d.functions.get(fname) or self._by_name(fname)
        fname = a[2] if name in ("VirtualFunc", "VirtualParentFunc") else a[1]
        if name == "VirtualParentFunc":
            k = self.d.klass(self.cls)
            f = self.d.method(k.parent, fname) if k else None
            return f or self._by_name(fname)
        if ctx:
            return self.d.method(ctx, fname) or self._in_subclasses(ctx, fname) or self._by_name(fname)
        # unqualified: the class itself, then (in a state) its state machine
        f = self.d.method(self.cls, fname) if self.cls else None
        k = self.d.klass(self.cls) if self.cls else None
        if not f and k and k.machine:
            f = self.d.method(k.machine, fname) or self._in_subclasses(k.machine, fname)
        return f or self._by_name(fname)

    def _in_subclasses(self, cls, fname):
        """A method declared only in subclasses of the context's static type."""
        cands = [f for f, owner in self.d.methods_owned(fname)
                 if any(a.name == cls for a in self.d.ancestors(owner))]
        if not cands:
            return None
        return cands[0] if len(cands) == 1 else _Agreement(cands)

    def _by_name(self, fname):
        """Every declaration of a method with this name; usable where they all agree."""
        cands = self.d.methods_named(fname)
        if not cands:
            return None
        if len(cands) == 1:
            return cands[0]
        return _Agreement(cands)

    # -------- walk with expected types
    def run(self, stmts):
        for s in stmts:
            self.walk(s, "", None)
        return self.found

    def walk(self, n, expected, ctx):
        name = n.name
        a = n.ins.args
        k = n.kids
        if name in CONSTS:
            self.found.append((n.ins, expected))
            return
        if name == "Assign":
            t = self.type_of(k[0])
            self.walk(k[0], "", None)
            self.walk(k[1], t, None)
        elif name in ("TestEqual", "TestNotEqual"):
            t = norm_type(a[0])
            self.walk(k[0], t, None)
            self.walk(k[1], t, None)
        elif name in ("EnumToInt", "EnumToString"):
            self.walk(k[0], norm_type(a[0]), None)
        elif name == "IntToEnum":
            self.walk(k[0], "Int32", None)
        elif name == "Switch":
            t = norm_type(a[0])
            self.switch_types.append(t)
            self.walk(k[0], t, None)
        elif name == "SwitchLabel":
            self.walk(k[0], self.switch_types[-1] if self.switch_types else "", None)
        elif name == "Return":
            self.walk(k[0], self.ret, None)
        elif name == "Skip":
            self.walk(k[0], expected, ctx)
        elif name == "Conditional":
            self.walk(k[0], "Bool", None)
            self.walk(k[1], expected, ctx)
            self.walk(k[2], expected, ctx)
        elif name == "Context":
            self.walk(k[0], "", None)
            self.walk(k[1], expected, self.type_of(k[0]))
        elif name in ("FinalFunc", "VirtualFunc", "VirtualParentFunc", "EntryFunc"):
            f = self.callee(n, ctx)
            for i, kid in enumerate(k):
                t = f.param(i) if isinstance(f, (_FakeFunc, _Agreement)) else (
                    f.params[i] if f and i < len(f.params) else "")
                self.walk(kid, t, None)
        elif name == "Constructor":
            fields = []
            kl = self.d.klass(norm_type(a[1]))
            if kl:
                fields = [kl.fields[x] for x in kl.field_order]
            for i, kid in enumerate(k):
                self.walk(kid, fields[i] if i < len(fields) else "", None)
        elif name.startswith("Array"):
            el = elem_type(norm_type(a[0]))
            if name in ("ArrayPushBack", "ArrayContains", "ArrayContainsFast", "ArrayFindFirst",
                        "ArrayFindFirstFast", "ArrayFindLast", "ArrayFindLastFast",
                        "ArrayRemove", "ArrayRemoveFast"):
                self.walk(k[0], "", None)
                self.walk(k[1], el, None)
            elif name == "ArrayInsert":
                self.walk(k[0], "", None)
                self.walk(k[1], "Int32", None)
                self.walk(k[2], el, None)
            else:
                for kid in k:
                    self.walk(kid, "Int32" if kid is not k[0] else "", None)
        elif name.startswith("StaticArray"):
            for kid in k:
                self.walk(kid, "", None)
        else:
            for kid in k:
                self.walk(kid, "", None)


class _FakeFunc:
    def __init__(self, params, ret):
        self.params, self.ret = params, ret

    def param(self, i):
        return self.params[i] if i < len(self.params) else ""


class _Agreement:
    """Several declarations of a method name: a parameter type is known where they agree."""

    def __init__(self, cands):
        self.cands = cands
        rets = {c.ret for c in cands}
        self.ret = rets.pop() if len(rets) == 1 else ""

    def param(self, i):
        ts = {c.params[i] if i < len(c.params) else "" for c in self.cands}
        return ts.pop() if len(ts) == 1 else ""


def explicit_numbers(blob, targets):
    """Int literals converted to an extended enum, `(EEffectType)173`: left alone, reported."""
    out = []
    for owner, f in blob.all_functions():
        for s in rsblob.parse_tree(rsblob.disassemble(blob, f.code)):
            stack = [s]
            while stack:
                n = stack.pop()
                stack.extend(n.kids)
                if (n.name == "IntToEnum" and norm_type(n.ins.args[0]) in targets
                        and n.kids[0].name == "IntConst" and n.kids[0].ins.args[0] in targets[norm_type(n.ins.args[0])]):
                    out.append(f"{owner}.{f.name}: explicit number ({n.ins.args[0]}){n.kids[0].ins.args[0]} "
                               f"is not renumbered")
    return out


def enum_literals(blob, decls):
    """[(function label, Instr, expected type)] for every Byte/Short/IntConst in the blob."""
    out = []
    for owner, f in blob.all_functions():
        label = f"{owner}.{f.name}" if owner else f.name
        try:
            stmts = rsblob.parse_tree(rsblob.disassemble(blob, f.code))
        except (ValueError, IndexError, KeyError) as e:
            raise ValueError(f"{label}: {e}") from e
        for ins, t in Typer(decls, owner, f, blob).run(stmts):
            out.append((label, f, ins, t))
    return out


# ---------------------------------------------------------------- numbering

def extension_values(vanilla_members, count):
    """Values the game gives `count` members appended to an enum: the smallest unused ones."""
    used = {v for _, v in vanilla_members}
    out, v = [], 0
    while len(out) < count:
        if v not in used:
            out.append(v)
        v += 1
    return out


def has_gaps(vanilla_members):
    vals = sorted(v for _, v in vanilla_members)
    run = 0
    for v in vals:
        if v != run:
            return True
        run += 1
    return False


# ---------------------------------------------------------------- planning and patching

class Mod:
    def __init__(self, name, path):
        self.name = name          # mod folder name (or a label)
        self.path = path          # path of precompiled.rsblob
        self.orig_bytes = None
        self.blob = None


def load_original(mod):
    """The mod's original blob: the kept original if the installed blob is our output."""
    data = open(mod.path, "rb").read()
    orig, state = mod.path + ORIG_SUFFIX, mod.path + STATE_SUFFIX
    if os.path.exists(orig) and os.path.exists(state):
        st = json.load(open(state))
        if hashlib.sha256(data).hexdigest() == st.get("patched_sha256"):
            data = open(orig, "rb").read()
        # else: the mod was updated after our run; its new blob is the original now
    mod.orig_bytes = data
    mod.blob = rsblob.Blob.read(data)


def plan(mods, decls, log):
    """Decide the union per enum and the literal remaps per mod. Returns
    (unions, {mod: {enum: {old value: new value}}}, errors)."""
    errors = []
    unions = {}     # enum -> [member names in canonical order]
    owners = {}     # enum -> [mod names]
    for m in mods:
        for e in m.blob.enums:
            u = unions.setdefault(e.name, [])
            for name, _ in e.members:
                if name not in u:
                    u.append(name)
            owners.setdefault(e.name, []).append(m.name)
    shared = {e for e, o in owners.items() if len(o) > 1}
    remaps = {}
    for e in sorted(shared):
        van = decls_vanilla_enum(decls, e)
        if van is None:
            errors.append(f"{e}: not declared in the vanilla scripts (C++-only enum?); skipped")
            continue
        if has_gaps(van):
            log(f"  note: vanilla {e} has gaps or explicit values; extension numbers assume the "
                f"smallest unused values (verified for EEffectType)")
        vals = extension_values(van, len(unions[e]))
        newval = dict(zip(unions[e], vals))
        for m in mods:
            mine = next((x for x in m.blob.enums if x.name == e), None)
            if not mine:
                continue
            oldvals = extension_values(van, len(mine.members))
            mp = {ov: newval[nm] for (nm, _), ov in zip(mine.members, oldvals)}
            remaps.setdefault(m.name, {})[e] = mp
        top = max(vals)
        if top > 32767:
            errors.append(f"{e}: union reaches value {top}, beyond a ShortConst")
        log(f"{e}: {len(unions[e])} extension members from {', '.join(owners[e])}"
            f" -> values {vals[0]}..{vals[-1]}")
    return unions, shared, remaps, errors


def decls_vanilla_enum(decls, name):
    return decls.vanilla_enums.get(name)


def patch_mod(mod, unions, shared, remap, decls, log, errors):
    """Patch mod.blob in memory; returns new bytes, or None if nothing to change or on error."""
    blob = mod.blob
    targets = {e: mp for e, mp in remap.items() if e in shared}
    if not targets:
        return None
    changes = {}  # (func id, pos) -> (Func, Instr, new value)
    unresolved = []
    try:
        lits = enum_literals(blob, decls)
    except ValueError as e:
        errors.append(f"{mod.name}: bytecode not understood ({e}); not patched")
        return None
    for label, f, ins, t in lits:
        v = ins.args[0]
        if t in targets:
            mp = targets[t]
            if v in mp and mp[v] != v:
                changes[(id(f), ins.pos)] = (f, ins, mp[v])
        elif t == "" and ins.name != "IntConst":
            for e, mp in targets.items():
                if v in mp and mp[v] != v:
                    unresolved.append(f"{label} @{ins.pos}: {ins.name} {v} (would be {e} "
                                      f"member -> {mp[v]})")
    explicit = explicit_numbers(blob, targets)
    for x in explicit:
        log(f"  warning: {mod.name}: {x}")
    if unresolved:
        errors.append(f"{mod.name}: {len(unresolved)} literal(s) with a value of its own "
                      f"extension members whose type could not be inferred; not patched:\n    "
                      + "\n    ".join(unresolved[:40]))
        return None
    # enum declarations: the full union, in canonical order
    for e in blob.enums:
        if e.name in targets:
            # members carry no value (numbered at load); keep this compiler's marker for it
            # (wcc_lite writes 0x7FFFFFFF, WSCompiler 0xFFFFFFFF)
            marker = e.members[0][1] if e.members else 0x7FFFFFFF
            e.members = [[nm, marker] for nm in unions[e.name]]
    # literals
    codes = {}
    for f, ins, new in changes.values():
        code = codes.setdefault(id(f), (f, bytearray(f.code)))[1]
        if ins.name == "ByteConst":
            if not 0 <= new <= 255:
                errors.append(f"{mod.name}: value {new} does not fit a ByteConst")
                return None
            code[ins.pos + 1] = new
        elif ins.name == "ShortConst":
            code[ins.pos + 1:ins.pos + 3] = struct.pack("<h", new)
        else:
            enc_old = rsblob.encode_cint(ins.args[0])
            enc_new = rsblob.encode_cint(new)
            if len(enc_old) != len(enc_new):
                errors.append(f"{mod.name}: IntConst {ins.args[0]} -> {new} changes size")
                return None
            code[ins.pos + 1:ins.pos + 1 + len(enc_new)] = enc_new
    for f, code in codes.values():
        f.code = bytes(code)
    log(f"  {mod.name}: {len(changes)} literal(s) renumbered; enums "
        + ", ".join(f"{e} ({len(unions[e])} members)" for e in targets))
    return blob.write()


# ---------------------------------------------------------------- installed mods

def game_dir():
    try:
        import paths
        return str(paths.game_dir())
    except Exception:
        return os.environ.get("W3_GAME_DIR", "")


def installed_mods(mods_dir):
    settings = {}
    try:
        import paths
        docs = str(paths.documents_dir())
    except Exception:
        docs = os.path.join(os.path.expanduser("~"), "Documents")
    ms = os.path.join(docs, "The Witcher 3", "mods.settings")
    if os.path.exists(ms):
        cp = configparser.ConfigParser(strict=False)
        cp.optionxform = str
        try:
            cp.read(ms, encoding="utf-8-sig")
            for sec in cp.sections():
                settings[sec.lower()] = (cp[sec].get("Enabled", "1"), int(cp[sec].get("Priority", "0") or 0))
        except Exception:
            pass
    mods = []
    for name in os.listdir(mods_dir):
        p = os.path.join(mods_dir, name, "content", "precompiled.rsblob")
        if not os.path.isfile(p):
            continue
        en, prio = settings.get(name.lower(), ("1", 1 << 30))
        if en.strip() == "0":
            continue
        mods.append((prio, name.lower(), Mod(name, p)))
    mods.sort(key=lambda x: (x[0], x[1]))
    return [m for _, _, m in mods]


def _label(path):
    """mods/<mod>/content/precompiled.rsblob -> <mod>; other files -> their stem."""
    p = os.path.abspath(path)
    parent = os.path.dirname(p)
    if os.path.basename(parent).lower() == "content":
        return os.path.basename(os.path.dirname(parent))
    return os.path.splitext(os.path.basename(p))[0]


def build_decls(scripts, mods):
    d = Decls()
    d.load_scripts(scripts)
    d.vanilla_enums = {k: list(v) for k, v in d.enums.items()}
    for m in mods:
        d.load_blob(m.blob)
    return d


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    ap.add_argument("command", choices=["check", "apply", "restore", "patch", "dump"])
    ap.add_argument("args", nargs="*")
    ap.add_argument("--mods")
    ap.add_argument("--scripts")
    o = ap.parse_args(argv)
    g = game_dir()
    scripts = o.scripts or os.path.join(g, "content", "content0", "scripts")
    log = print

    if o.command == "dump":
        m = Mod("blob", o.args[0])
        load_original(m)
        d = build_decls(scripts, [m])
        for label, f, ins, t in enum_literals(m.blob, d):
            if len(o.args) > 1 and o.args[1] not in label:
                continue
            if t and t in d.enums and t not in ("Int32",):
                print(f"{label} @{ins.pos}: {ins.name} {ins.args[0]} : {t}")
            elif not t and ins.name != "IntConst":
                print(f"{label} @{ins.pos}: {ins.name} {ins.args[0]} : ?")
        return 0

    if o.command == "patch":
        out_dir, paths_ = o.args[0], o.args[1:]
        mods = [Mod(f"{i}_{_label(p)}", p) for i, p in enumerate(paths_)]
    else:
        mods_dir = o.mods or os.path.join(g, "mods")
        mods = installed_mods(mods_dir)

    if o.command == "restore":
        for m in mods:
            orig = m.path + ORIG_SUFFIX
            if os.path.exists(orig):
                shutil.copy2(orig, m.path)
                os.remove(orig)
                if os.path.exists(m.path + STATE_SUFFIX):
                    os.remove(m.path + STATE_SUFFIX)
                log(f"restored {m.name}")
        return 0

    for m in mods:
        try:
            load_original(m)
        except Exception as e:
            log(f"ERROR: {m.path}: cannot read the blob ({e}); nothing written")
            return 1
    log("load order: " + ", ".join(m.name for m in mods))
    decls = build_decls(scripts, mods)
    unions, shared, remaps, errors = plan(mods, decls, log)
    outputs = {}
    for m in mods:
        if m.name in remaps:
            new = patch_mod(m, unions, shared, remaps[m.name], decls, log, errors)
            if new is not None:
                outputs[m.name] = (m, new)
    for e in errors:
        log("ERROR: " + e)
    if errors:
        log("nothing written")
        return 1
    if o.command == "check":
        log(f"check only: {len(outputs)} blob(s) would change")
        return 0
    for name, (m, new) in outputs.items():
        if o.command == "patch":
            dst = os.path.join(out_dir, name)
            os.makedirs(dst, exist_ok=True)
            open(os.path.join(dst, "precompiled.rsblob"), "wb").write(new)
            log(f"wrote {os.path.join(dst, 'precompiled.rsblob')}")
            continue
        orig = m.path + ORIG_SUFFIX
        if not os.path.exists(orig) or open(m.path, "rb").read() == m.orig_bytes:
            open(orig, "wb").write(m.orig_bytes)
        open(m.path, "wb").write(new)
        json.dump({"patched_sha256": hashlib.sha256(new).hexdigest(),
                   "original_sha256": hashlib.sha256(m.orig_bytes).hexdigest(),
                   "tool": "enum_sync"}, open(m.path + STATE_SUFFIX, "w"), indent=1)
        log(f"patched {m.path}")
    if o.command == "apply":
        # blobs patched by an earlier run that need no patch now (a mod was removed): originals back
        for m in mods:
            if m.name not in outputs and os.path.exists(m.path + ORIG_SUFFIX):
                if open(m.path, "rb").read() != m.orig_bytes:
                    open(m.path, "wb").write(m.orig_bytes)
                    log(f"restored {m.path} (no longer needs a patch)")
                os.remove(m.path + ORIG_SUFFIX)
                if os.path.exists(m.path + STATE_SUFFIX):
                    os.remove(m.path + STATE_SUFFIX)
    if not shared:
        log("no enum is extended by more than one blob: nothing to patch")
    return 0


if __name__ == "__main__":
    sys.exit(main())
