"""Declarations (enums, classes, structs, functions and their types) from WitcherScript sources
and script blobs, for `tools/enum_sync.py`'s type inference.

Types are normalized to the RTTI spelling script blobs use: Int32, Float, Bool, String, CName,
Uint8, `array:2,0,<T>`, and class, struct or enum names (no `handle:`).
"""

import os
import re

_SCRIPT_TYPES = {"int": "Int32", "float": "Float", "bool": "Bool", "string": "String",
                 "name": "CName", "byte": "Uint8", "Int32": "Int32", "Float": "Float",
                 "Bool": "Bool", "String": "String", "CName": "CName", "Uint8": "Uint8",
                 "Uint64": "Uint64", "Int64": "Int64", "Uint32": "Uint32", "Int8": "Int8",
                 "Uint16": "Uint16", "Int16": "Int16", "Double": "Double"}


def norm_type(t):
    """Normalize a type from a script (`array< handle:X >`, `int`) or a blob (`array:2,0,Int32`)."""
    if not t:
        return ""
    t = t.replace(" ", "")
    if t.startswith("array:"):
        return "array:2,0," + norm_type(t.split(",", 2)[2])
    m = re.fullmatch(r"array<(.*)>", t)
    if m:
        return "array:2,0," + norm_type(m.group(1))
    for p in ("handle:", "soft:", "ptr:", "*"):
        if t.startswith(p):
            t = t[len(p):]
    return _SCRIPT_TYPES.get(t, t)


def elem_type(t):
    return t[len("array:2,0,"):] if t and t.startswith("array:2,0,") else ""


class Func:
    __slots__ = ("name", "params", "ret")

    def __init__(self, name, params, ret):
        self.name = name
        self.params = params  # list of normalized types
        self.ret = ret


class Klass:
    __slots__ = ("name", "parent", "fields", "methods", "field_order", "machine")

    def __init__(self, name, parent=""):
        self.name = name
        self.parent = parent
        self.fields = {}
        self.field_order = []
        self.methods = {}
        self.machine = ""


class Decls:
    def __init__(self):
        self.enums = {}        # name -> [(member, value)]
        self.classes = {}      # classes and structs: name -> Klass
        self.functions = {}    # global functions: name -> Func
        self.method_index = {}  # method name -> [(Func, class name)] over every class

    # ------------------------------------------------ lookup
    def klass(self, name):
        return self.classes.get(name)

    def ancestors(self, name):
        seen = set()
        while name and name not in seen:
            seen.add(name)
            k = self.classes.get(name)
            if not k:
                return
            yield k
            name = k.parent

    def field(self, cls, name):
        for k in self.ancestors(cls):
            if name in k.fields:
                return k.fields[name]
        return ""

    def method(self, cls, name):
        for k in self.ancestors(cls):
            if name in k.methods:
                return k.methods[name]
        return None

    def methods_named(self, name):
        return [f for f, _ in self.method_index.get(name, [])]

    def methods_owned(self, name):
        return self.method_index.get(name, [])

    def add_method(self, cls, f):
        k = self.classes.setdefault(cls, Klass(cls))
        k.methods[f.name] = f
        self.method_index.setdefault(f.name, []).append((f, cls))

    def add_field(self, cls, name, t):
        k = self.classes.setdefault(cls, Klass(cls))
        if name not in k.fields:
            k.field_order.append(name)
        k.fields[name] = t

    # ------------------------------------------------ script sources
    def load_scripts(self, folder):
        for root, _, files in os.walk(folder):
            for fn in files:
                if fn.lower().endswith(".ws"):
                    with open(os.path.join(root, fn), "rb") as fh:
                        raw = fh.read()
                    if raw[:2] in (b"\xff\xfe", b"\xfe\xff"):
                        text = raw.decode("utf-16")
                    else:
                        text = raw.decode("utf-8", "replace")
                    self._parse(text)

    def _parse(self, text):
        toks = _tokenize(text)
        i = 0
        n = len(toks)

        def skip_block(j):
            # toks[j] == "{": return index after the matching "}"
            depth = 0
            while j < n:
                if toks[j] == "{":
                    depth += 1
                elif toks[j] == "}":
                    depth -= 1
                    if depth == 0:
                        return j + 1
                j += 1
            return j

        def read_type(j):
            # a type starting at j; returns (type, next index)
            t = toks[j]
            j += 1
            if j < n and toks[j] == "<":
                depth = 0
                parts = [t]
                while j < n:
                    parts.append(toks[j])
                    if toks[j] == "<":
                        depth += 1
                    elif toks[j] == ">":
                        depth -= 1
                        if depth == 0:
                            j += 1
                            break
                    j += 1
                t = "".join(parts)
            return norm_type(t), j

        def read_params(j):
            # toks[j] == "("; returns (types, next index after ")")
            j += 1
            types, pending = [], []
            while j < n and toks[j] != ")":
                tk = toks[j]
                if tk in ("optional", "out", ","):
                    j += 1
                elif tk == ":":
                    t, j = read_type(j + 1)
                    types.extend([t] * len(pending))
                    pending = []
                else:
                    pending.append(tk)
                    j += 1
            return types, j + 1

        def function_at(j):
            # toks[j] is "function" or "event"; returns (Func, next index)
            name = toks[j + 1]
            params, j = read_params(j + 2)
            ret = ""
            if j < n and toks[j] == ":":
                ret, j = read_type(j + 1)
            if j < n and toks[j] == "{":
                j = skip_block(j)
            elif j < n and toks[j] == ";":
                j += 1
            return Func(name, params, ret), j

        def class_body(cls, j):
            # toks[j] == "{"
            j += 1
            while j < n and toks[j] != "}":
                tk = toks[j]
                if tk in ("function", "event"):
                    f, j = function_at(j)
                    self.add_method(cls, f)
                elif tk in ("var", "autobind"):
                    names = []
                    j += 1
                    while j < n and toks[j] != ":":
                        if toks[j] != ",":
                            names.append(toks[j])
                        j += 1
                    t, j = read_type(j + 1)
                    for nm in names:
                        self.add_field(cls, nm, t)
                    while j < n and toks[j] != ";":
                        j += 1
                    j += 1
                elif tk in ("default", "hint"):
                    while j < n and toks[j] != ";":
                        j += 1
                    j += 1
                elif tk == "{":
                    j = skip_block(j)
                else:
                    j += 1
            return j + 1

        while i < n:
            tk = toks[i]
            if tk == "enum":
                name = toks[i + 1]
                j = i + 3
                members, nxt = [], 0
                while j < n and toks[j] != "}":
                    if toks[j] == ",":
                        j += 1
                        continue
                    m = toks[j]
                    j += 1
                    if j < n and toks[j] == "=":
                        j += 1
                        neg = toks[j] == "-"
                        if neg:
                            j += 1
                        try:
                            nxt = int(toks[j], 0) * (-1 if neg else 1)
                        except ValueError:
                            pass
                        j += 1
                    members.append((m, nxt))
                    nxt += 1
                self.enums.setdefault(name, members)
                i = j + 1
            elif tk in ("class", "struct"):
                name = toks[i + 1]
                j = i + 2
                parent = ""
                if toks[j] == "extends":
                    parent = toks[j + 1]
                    j += 2
                k = self.classes.setdefault(name, Klass(name))
                k.parent = k.parent or parent
                while j < n and toks[j] != "{":
                    j += 1
                i = class_body(name, j)
            elif tk == "state":
                sname = toks[i + 1]
                machine = toks[i + 3]
                j = i + 4
                parent = ""
                if toks[j] == "extends":
                    parent = machine + "State" + toks[j + 1]
                    j += 2
                cname = machine + "State" + sname
                k = self.classes.setdefault(cname, Klass(cname))
                k.parent = k.parent or parent or "CScriptableState"
                k.machine = machine
                while j < n and toks[j] != "{":
                    j += 1
                i = class_body(cname, j)
            elif tk in ("function", "event"):
                f, i = function_at(i)
                self.functions.setdefault(f.name, f)
            elif tk == "{":
                i = skip_block(i)
            else:
                i += 1

    # ------------------------------------------------ blobs
    def load_blob(self, blob):
        for e in blob.enums:
            members = self.enums.setdefault(e.name, [])
            known = {m for m, _ in members}
            used = {v for _, v in members}
            nxt = 0
            for m, _ in e.members:  # numbered like the game: smallest unused values
                if m not in known:
                    while nxt in used:
                        nxt += 1
                    members.append((m, nxt))
                    known.add(m)
                    used.add(nxt)
        for s in blob.structs:
            for p in s.props:
                self.add_field(s.name, p.name, norm_type(p.type_name))
        for c in blob.classes:
            k = self.classes.setdefault(c.name, Klass(c.name))
            k.parent = k.parent or c.parent
            k.machine = k.machine or c.machine
            for p in c.props:
                self.add_field(c.name, p.name, norm_type(p.type_name))
            for f in c.funcs:
                self.add_method(c.name, blob_func(f))
        for p in blob.add_fields:
            self.add_field(p.class_name, p.name, norm_type(p.type_name))
        for f in blob.functions + blob.replace_global:
            self.functions.setdefault(f.name, blob_func(f))
        for f in blob.add_methods + blob.replace_class:
            if f.owner:
                self.add_method(f.owner, blob_func(f))
            else:
                self.functions.setdefault(f.name, blob_func(f))


def blob_func(f):
    return Func(f.name, [norm_type(p.type_name) for p in f.params],
                norm_type(f.ret.type_name) if f.ret else "")


_TOKEN = re.compile(r'"(?:[^"\\\n]|\\.)*"|\'(?:[^\'\\\n]|\\.)*\'|[A-Za-z_][A-Za-z0-9_]*'
                    r'|0[xX][0-9A-Fa-f]+|\d+(?:\.\d*)?f?|::|[{}()<>;:,=\-\[\]]|\S')


def _tokenize(text):
    text = re.sub(r"/\*.*?\*/", " ", text, flags=re.S)
    text = re.sub(r"//[^\n]*", " ", text)
    return [t for t in _TOKEN.findall(text) if not t.startswith(('"', "'"))]
