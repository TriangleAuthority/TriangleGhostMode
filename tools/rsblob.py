"""Read, write and disassemble Witcher 3 (5.x) script blobs (`precompiled.rsblob`).

A script blob is a mod's compiled scripts. This module reads one into Python objects, writes it back
byte for byte, and decodes function bytecode into expression trees. `tools/enum_sync.py` uses it.

Format (written from the format description in Aelto's tw3-cahirb, `rsblob_disas.py`,
https://github.com/Aelto/tw3-cahirb, and checked against blobs built by wcc_lite and WSCompiler):

- Header: u32 format version, string platform, string build version, 8-byte CDateTime, string config.
- Body, in order: enums, structs, classes, global functions, then the annotations
  (@replaceMethod global, @replaceMethod class, @addMethod, @wrapMethod, @addField),
  then the import tables (types, properties, functions) that bytecode operands index.
- Names: a string table at the end; the file's last 4 bytes are its offset. Names elsewhere are
  compressed indexes into it.
- Integers are "compressed": first byte bit 7 = negative, bit 6 = more, 6 value bits; further bytes
  bit 7 = more, 7 value bits. Strings: compressed length (<= 0: UTF-8 of -length bytes, else UTF-16).
- Function bytecode: u32 runtime size, then instructions (opcode byte + operands, see OPCODES).
  Operands are serialized compactly; the runtime size is the size once linked (unchanged as long as
  no instruction changes size).

An enum member in a blob has value -1 (0xFFFFFFFF): numbered at load. Enum constants in code are
literals (ByteConst/ShortConst/IntConst by the enum's range), with no type attached.
"""

import io
import struct

# ---------------------------------------------------------------- primitives

class Reader:
    def __init__(self, data: bytes):
        self.data = data
        self.pos = 0

    def u8(self):
        v = self.data[self.pos]
        self.pos += 1
        return v

    def raw(self, n):
        v = self.data[self.pos:self.pos + n]
        if len(v) != n:
            raise ValueError("unexpected end of data")
        self.pos += n
        return v

    def u16(self):
        return struct.unpack("<H", self.raw(2))[0]

    def i16(self):
        return struct.unpack("<h", self.raw(2))[0]

    def u32(self):
        return struct.unpack("<I", self.raw(4))[0]

    def f32(self):
        return struct.unpack("<f", self.raw(4))[0]

    def cint(self):
        """Compressed signed int."""
        b = self.u8()
        neg = b & 0x80
        v = b & 0x3F
        if b & 0x40:
            shift = 6
            while True:
                b = self.u8()
                v |= (b & 0x7F) << shift
                shift += 7
                if not (b & 0x80) or shift > 27:
                    break
        return -v if neg else v

    def cuint(self):
        return self.cint() & 0xFFFFFFFF

    def string(self):
        n = self.cint()
        if n <= 0:
            return self.raw(-n).decode("utf-8")
        return self.raw(2 * n).decode("utf-16-le")


class Writer:
    def __init__(self):
        self.buf = io.BytesIO()

    def u8(self, v):
        self.buf.write(bytes([v & 0xFF]))

    def raw(self, b):
        self.buf.write(b)

    def u32(self, v):
        self.buf.write(struct.pack("<I", v & 0xFFFFFFFF))

    def cint(self, v):
        self.buf.write(encode_cint(v))

    def string(self, s):
        if all(ord(c) < 128 for c in s):
            b = s.encode("utf-8")
            self.cint(-len(b))
            self.raw(b)
        else:
            b = s.encode("utf-16-le")
            self.cint(len(b) // 2)
            self.raw(b)

    def tell(self):
        return self.buf.tell()

    def getvalue(self):
        return self.buf.getvalue()


def encode_cint(v):
    """Compressed int. Values >= 2**31 are written as unsigned (like -1 stored as 0xFFFFFFFF)."""
    neg = v <= 0  # zero is written as "negative zero" (0x80), as the game's writer does
    a = -v if neg else v
    out = bytearray()
    b = (0x80 if neg else 0) | (a & 0x3F)
    a >>= 6
    if a:
        b |= 0x40
    out.append(b)
    while a:
        b = a & 0x7F
        a >>= 7
        if a:
            b |= 0x80
        out.append(b)
    return bytes(out)

# ---------------------------------------------------------------- definitions

class Prop:
    __slots__ = ("name", "hint", "flags", "type_name", "class_name", "binding")


class DefaultValue:
    __slots__ = ("name", "value", "subs")


class Func:
    __slots__ = ("name", "owner", "flags", "ret", "params", "locals", "code")


class EnumDef:
    __slots__ = ("name", "members")  # members: list of [name, value]


class StructDef:
    __slots__ = ("name", "flags", "props", "defaults")


class ClassDef:
    __slots__ = ("name", "parent", "machine", "is_state", "flags", "props", "funcs", "defaults")


SECTIONS = ("enums", "structs", "classes", "functions",
            "replace_global", "replace_class", "add_methods", "wrap_methods", "add_fields")

FF_PRIVATE, FF_PROTECTED, FF_PUBLIC = 1 << 14, 1 << 15, 1 << 16


class Blob:
    """A parsed script blob. Names are stored as strings; `write()` rebuilds the string table."""

    def __init__(self):
        self.version = 0
        self.platform = self.build = self.config = ""
        self.timestamp = b""
        self.enums, self.structs, self.classes, self.functions = [], [], [], []
        self.replace_global, self.replace_class, self.add_methods, self.wrap_methods = [], [], [], []
        self.add_fields = []
        self.import_types = []      # [name, kind]
        self.import_props = []      # [name, type index, scope index]
        self.import_funcs = []      # [name, scope index]
        self.names = []             # original string table order (kept on write when possible)

    # ------------------------------------------------ reading
    @classmethod
    def read(cls, data: bytes) -> "Blob":
        b = cls()
        r = Reader(data)
        b.version = r.u32()
        b.platform = r.string()
        b.build = r.string()
        b.timestamp = r.raw(8)
        b.config = r.string()
        body = r.pos
        r.pos = struct.unpack("<I", data[-4:])[0]
        b.names = [r.string() for _ in range(r.u32())]
        b._names_end = r.pos
        r.pos = body
        nm = lambda: b.names[r.cuint()]
        arr = lambda f: [f() for _ in range(r.cint())]

        def prop():
            p = Prop()
            p.name = nm()
            p.hint = r.string()
            p.flags = r.cuint()
            p.type_name = nm()
            p.class_name = nm()
            p.binding = nm()
            return p

        def dval():
            d = DefaultValue()
            d.name = nm()
            d.value = r.string()
            d.subs = arr(dval)
            return d

        def ddef():
            name = nm()
            return (name, dval())

        def func():
            f = Func()
            f.name = nm()
            f.owner = nm()
            f.flags = r.cuint()
            f.ret = prop() if r.u8() else None
            f.params = arr(prop)
            f.locals = arr(prop)
            f.code = r.raw(r.cuint())
            return f

        def enum():
            e = EnumDef()
            e.name = nm()
            e.members = [[nm(), r.cint()] for _ in range(r.cuint())]
            return e

        def struc():
            s = StructDef()
            s.name = nm()
            s.flags = r.cuint()
            s.props = arr(prop)
            s.defaults = arr(ddef)
            return s

        def klass():
            c = ClassDef()
            c.name = nm()
            c.parent = nm()
            c.machine = nm()
            c.is_state = r.u8()
            c.flags = r.cuint()
            c.props = arr(prop)
            c.funcs = arr(func)
            c.defaults = arr(ddef)
            return c

        b.enums = arr(enum)
        b.structs = arr(struc)
        b.classes = arr(klass)
        b.functions = arr(func)
        b.replace_global = arr(func)
        b.replace_class = arr(func)
        b.add_methods = arr(func)
        b.wrap_methods = arr(func)
        b.add_fields = arr(prop)
        b.import_types = arr(lambda: [nm(), r.cuint()])
        b.import_props = arr(lambda: [nm(), r.cint(), r.cint()])
        b.import_funcs = arr(lambda: [nm(), r.cint()])
        b._body_end = r.pos
        return b

    def all_functions(self):
        """(class name or '', Func) for every function with code."""
        for c in self.classes:
            for f in c.funcs:
                yield c.name, f
        for sec in ("functions", "replace_global", "replace_class", "add_methods", "wrap_methods"):
            for f in getattr(self, sec):
                yield f.owner, f

    # ------------------------------------------------ writing
    def write(self) -> bytes:
        """Serialize. The string table keeps the original order; new names are appended.
        Bytecode is copied as is, except that name operands are re-indexed when names changed
        position (they never do: names are only appended)."""
        names = list(self.names)
        index = {n: i for i, n in enumerate(names)}

        def ni(n):
            if n not in index:
                index[n] = len(names)
                names.append(n)
            return index[n]

        w = Writer()
        w.u32(self.version)
        w.string(self.platform)
        w.string(self.build)
        w.raw(self.timestamp)
        w.string(self.config)
        nm = lambda n: w.cint(ni(n))

        def arr(items, f):
            w.cint(len(items))
            for x in items:
                f(x)

        def prop(p):
            nm(p.name)
            w.string(p.hint)
            w.cint(p.flags)
            nm(p.type_name)
            nm(p.class_name)
            nm(p.binding)

        def dval(d):
            nm(d.name)
            w.string(d.value)
            arr(d.subs, dval)

        def ddef(x):
            nm(x[0])
            dval(x[1])

        def func(f):
            nm(f.name)
            nm(f.owner)
            w.cint(f.flags)
            if f.ret is None:
                w.u8(0)
            else:
                w.u8(1)
                prop(f.ret)
            arr(f.params, prop)
            arr(f.locals, prop)
            w.cint(len(f.code))
            w.raw(f.code)

        def enum(e):
            nm(e.name)
            w.cint(len(e.members))
            for n, v in e.members:
                nm(n)
                w.cint(v)  # -1 ("numbered at load") is stored as 0xFFFFFFFF

        def struc(s):
            nm(s.name)
            w.cint(s.flags)
            arr(s.props, prop)
            arr(s.defaults, ddef)

        def klass(c):
            nm(c.name)
            nm(c.parent)
            nm(c.machine)
            w.u8(c.is_state)
            w.cint(c.flags)
            arr(c.props, prop)
            arr(c.funcs, func)
            arr(c.defaults, ddef)

        arr(self.enums, enum)
        arr(self.structs, struc)
        arr(self.classes, klass)
        for sec in ("functions", "replace_global", "replace_class", "add_methods", "wrap_methods"):
            arr(getattr(self, sec), func)
        arr(self.add_fields, prop)

        def imp_type(x):
            nm(x[0])
            w.cint(x[1])

        def imp_prop(x):
            nm(x[0])
            w.cint(x[1])
            w.cint(x[2])

        def imp_func(x):
            nm(x[0])
            w.cint(x[1])

        arr(self.import_types, imp_type)
        arr(self.import_props, imp_prop)
        arr(self.import_funcs, imp_func)
        table = w.tell()
        w.u32(len(names))
        for n in names:
            w.string(n)
        w.u32(table)
        self.names = names
        return w.getvalue()

# ---------------------------------------------------------------- bytecode

# Opcodes in order (value = index). Operand kinds: u8, i16, u16 raw; cu32/ci32 compressed;
# f32; str (compressed length + bytes); name (string table index); type (import type index);
# func (import function: >0 table index + 1, -1 the function itself, < -1 internal operator);
# prop (name + import type index of the owning class).
OPCODES = [
    ("Nop", ()), ("Null", ()), ("IntOne", ()), ("IntZero", ()),
    ("IntConst", ("ci32",)), ("ShortConst", ("i16",)), ("FloatConst", ("f32",)),
    ("StringConst", ("str",)), ("NameConst", ("name",)), ("ByteConst", ("u8",)),
    ("BoolTrue", ()), ("BoolFalse", ()), ("Breakpoint", ("cu32", "u8")),
    ("Assign", ()), ("Target", ()), ("LocalVar", ("name",)), ("ParamVar", ("name",)),
    ("ObjectVar", ("prop",)), ("ObjectBindableVar", ("prop",)), ("DefaultVar", ("prop",)),
    ("Switch", ("type", "i16")), ("SwitchLabel", ("i16", "i16")), ("SwitchDefault", ()),
    ("Jump", ("i16",)), ("JumpIfFalse", ("i16",)), ("Skip", ("i16",)),
    ("Conditional", ("i16", "i16")), ("Constructor", ("u8", "type")),
    ("FinalFunc", ("u16", "u16", "func")), ("VirtualFunc", ("u16", "u16", "name")),
    ("VirtualParentFunc", ("u16", "u16", "name")), ("EntryFunc", ("u16", "name")),
    ("ParamEnd", ()), ("Return", ()), ("StructMember", ("prop",)), ("Context", ("u16",)),
    ("TestEqual", ("type",)), ("TestNotEqual", ("type",)), ("New", ("type",)), ("Delete", ()),
    ("This", ()), ("Parent", ()), ("SavePoint", ("u16", "name")), ("SaveValue", ("name",)),
    ("SavePointEnd", ()),
] + [(n, ("type",)) for n in (
    "ArrayClear", "ArraySize", "ArrayResize", "ArrayFindFirst", "ArrayFindFirstFast",
    "ArrayFindLast", "ArrayFindLastFast", "ArrayContains", "ArrayContainsFast", "ArrayPushBack",
    "ArrayPopBack", "ArrayInsert", "ArrayRemove", "ArrayRemoveFast", "ArrayGrow", "ArrayErase",
    "ArrayEraseFast", "ArrayLast", "ArrayElement")] + [(n, ()) for n in (
    "StaticArraySize", "StaticArrayFindFirst", "StaticArrayFindFirstFast", "StaticArrayFindLast",
    "StaticArrayFindLastFast", "StaticArrayContains", "StaticArrayContainsFast", "StaticArrayLast",
    "StaticArrayElement",
    "BoolToByte", "BoolToInt", "BoolToFloat", "BoolToString", "ByteToBool", "ByteToInt",
    "ByteToFloat", "ByteToString", "IntToBool", "IntToByte", "IntToFloat", "IntToString")] + [
    ("IntToEnum", ("type",))] + [(n, ()) for n in (
    "FloatToBool", "FloatToByte", "FloatToInt", "FloatToString", "NameToBool", "NameToString",
    "StringToBool", "StringToByte", "StringToInt", "StringToFloat", "ObjectToBool",
    "ObjectToString")] + [(n, ("type",)) for n in ("EnumToString", "EnumToInt", "DynamicCast")] + [
    (n, ()) for n in ("GetGame", "GetPlayer", "GetCamera", "GetHud", "GetSound", "GetDebug",
                      "GetTimer", "GetInput", "GetTelemetry")]

OP = {name: i for i, (name, _) in enumerate(OPCODES)}

# Internal operator functions (FinalFunc with index < -1), in engine order.
_T = ("Int32", "Uint64")
INTERNAL_OPERATORS = (
    [f"{o}_Int32_Int32" for o in ("Add", "Subtract", "Multiply", "Divide", "Modulo")] +
    ["Neg_Int32", "BitNot_Int32"] +
    [f"{o}_Int32_Int32" for o in ("And", "Or", "Xor", "Equal", "NotEqual", "Less", "LessEqual",
                                  "Greater", "GreaterEqual", "AssignAdd", "AssignSubtract",
                                  "AssignMultiply", "AssignDivide", "AssignAnd", "AssignOr")] +
    [f"{o}_Uint64_Uint64" for o in ("Add", "Subtract", "Multiply", "Divide", "Modulo", "And", "Or",
                                    "Xor", "Equal", "NotEqual", "Less", "LessEqual", "Greater",
                                    "GreaterEqual", "AssignAdd", "AssignSubtract",
                                    "AssignMultiply", "AssignDivide", "AssignAnd", "AssignOr")] +
    ["Add_String_String", "AssignAdd_String_String"] +
    [f"{o}_Float_Float" for o in ("Add", "Subtract", "Multiply", "Divide", "Modulo")] +
    ["Neg_Float"] +
    [f"{o}_Float_Float" for o in ("Equal", "NotEqual", "Less", "LessEqual", "Greater",
                                  "GreaterEqual", "AssignAdd", "AssignSubtract", "AssignMultiply",
                                  "AssignDivide")] +
    [f"{o}_Uint8_Int32" for o in ("Add", "Subtract", "Multiply", "Divide", "Modulo", "And", "Or",
                                  "Xor")] +
    [f"{o}_Uint8_Uint8" for o in ("Equal", "NotEqual", "Less", "LessEqual", "Greater")] +
    ["GreaterEqual_Uint8_Int32"] +
    [f"{o}_Uint8_Int32" for o in ("AssignAdd", "AssignSubtract", "AssignMultiply",
                                  "AssignDivide", "AssignAnd", "AssignOr")] +
    ["LogicAnd_Bool_Bool", "LogicOr_Bool_Bool", "LogicNot_Bool", "Neg_Vector"] +
    [f"{o}_Vector_Vector" for o in ("Add", "Subtract", "Multiply", "Divide", "AssignAdd",
                                    "AssignSubtract", "AssignMultiply", "AssignDivide")] +
    [f"{o}_Vector_Float" for o in ("Add", "Subtract", "Multiply", "Divide", "AssignAdd",
                                   "AssignSubtract", "AssignMultiply", "AssignDivide")] +
    ["Multiply_Float_Vector", "Multiply_Matrix_Matrix", "AssignMultiply_Matrix_Matrix",
     "Add_EngineTime_EngineTime", "Add_EngineTime_Float", "AssignAdd_EngineTime_EngineTime",
     "AssignAdd_EngineTime_Float", "Subtract_EngineTime_EngineTime", "Subtract_EngineTime_Float",
     "AssignSubtract_EngineTime_EngineTime", "AssignSubtract_EngineTime_Float",
     "Multiply_EngineTime_Float", "AssignMultiply_EngineTime_Float", "Divide_EngineTime_Float",
     "AssignDivide_EngineTime_Float", "Modulo_EngineTime_Float", "Equal_EngineTime_EngineTime",
     "NotEqual_EngineTime_EngineTime", "Greater_EngineTime_EngineTime",
     "GreaterEqual_EngineTime_EngineTime", "Less_EngineTime_EngineTime",
     "LessEqual_EngineTime_EngineTime", "Greater_EngineTime_Float",
     "GreaterEqual_EngineTime_Float", "Less_EngineTime_Float", "LessEqual_EngineTime_Float",
     "LogicAnd_handle_IScriptable_handle_IScriptable",
     "Add_GameTime_GameTime", "Add_GameTime_Int32", "Subtract_GameTime_GameTime",
     "Subtract_GameTime_Int32", "Multiply_GameTime_Float", "Divide_GameTime_Float",
     "Neg_GameTime", "Equal_GameTime_GameTime", "NotEqual_GameTime_GameTime",
     "Less_GameTime_GameTime", "LessEqual_GameTime_GameTime", "Greater_GameTime_GameTime",
     "GreaterEqual_GameTime_GameTime", "AssignAdd_GameTime_GameTime",
     "AssignSubtract_GameTime_GameTime", "AssignAdd_GameTime_Int32",
     "AssignSubtract_GameTime_Int32", "AssignMultiply_GameTime_Float",
     "AssignDivide_GameTime_Float", "Equal_SItemUniqueId_SItemUniqueId",
     "NotEqual_SItemUniqueId_SItemUniqueId",
     "Add_SAbilityAttributeValue_SAbilityAttributeValue",
     "Subtract_SAbilityAttributeValue_SAbilityAttributeValue",
     "AssignAdd_SAbilityAttributeValue_SAbilityAttributeValue",
     "AssignSubtract_SAbilityAttributeValue_SAbilityAttributeValue",
     "Multiply_SAbilityAttributeValue_Float"])
assert len(INTERNAL_OPERATORS) == 153, len(INTERNAL_OPERATORS)


class Instr:
    __slots__ = ("op", "name", "args", "pos", "end")

    def __repr__(self):
        return f"{self.pos}:{self.name}{list(self.args) if self.args else ''}"


def disassemble(blob: Blob, code: bytes):
    """Instructions of one function. `pos` is the byte offset of the opcode in `code`; for
    ShortConst the operand is at pos + 1. Operands are resolved to names where they index tables."""
    r = Reader(code)
    r.u32()  # runtime size
    out = []
    while r.pos < len(code):
        ins = Instr()
        ins.pos = r.pos
        ins.op = r.u8()
        if ins.op >= len(OPCODES):
            raise ValueError(f"unknown opcode {ins.op} at {ins.pos}")
        ins.name, kinds = OPCODES[ins.op]
        args = []
        for k in kinds:
            if k == "u8":
                args.append(r.u8())
            elif k == "i16":
                args.append(r.i16())
            elif k == "u16":
                args.append(r.u16())
            elif k == "cu32":
                args.append(r.cuint())
            elif k == "ci32":
                args.append(r.cint())
            elif k == "f32":
                args.append(r.f32())
            elif k == "str":
                args.append(r.raw(r.cuint()).decode("utf-8", "replace"))
            elif k == "name":
                args.append(blob.names[r.cuint()])
            elif k == "type":
                args.append(blob.import_types[r.cuint()][0])
            elif k == "func":
                i = r.cint()
                if i > 0:
                    name, scope = blob.import_funcs[i - 1]
                    scope = blob.import_types[scope][0] if scope >= 0 else ""
                    args.append(("func", name, scope))
                elif i == -1:
                    args.append(("self",))
                else:
                    args.append(("op", INTERNAL_OPERATORS[-(i + 2)]))
            elif k == "prop":
                name = blob.names[r.cuint()]
                scope = r.cint()
                args.append((name, blob.import_types[scope][0] if scope >= 0 else ""))
        ins.args = tuple(args)
        ins.end = r.pos
        out.append(ins)
    return out


if __name__ == "__main__":
    import sys
    data = open(sys.argv[1], "rb").read()
    b = Blob.read(data)
    print(f"version {b.version} {b.platform} {b.build} {b.config}; names {len(b.names)}")
    for s in SECTIONS:
        print(f"  {s}: {len(getattr(b, s))}")
    print(f"  import types {len(b.import_types)}, props {len(b.import_props)}, funcs {len(b.import_funcs)}")
    for e in b.enums:
        print(f"  enum {e.name}: {[m for m, _ in e.members]}")
    out = b.write()
    print("round trip identical:", out == data, len(out), len(data))
    if len(sys.argv) > 2:
        for owner, f in b.all_functions():
            if sys.argv[2] in (f.name, "*"):
                print(f"== {owner}.{f.name}")
                for i in disassemble(b, f.code):
                    print("   ", i)


# ---------------------------------------------------------------- expression trees

class Node:
    """An instruction with its operand expressions (prefix order in the bytecode)."""
    __slots__ = ("ins", "kids")

    def __init__(self, ins, kids=()):
        self.ins = ins
        self.kids = list(kids)

    @property
    def name(self):
        return self.ins.name

    def __repr__(self):
        return f"{self.ins!r}({', '.join(map(repr, self.kids))})" if self.kids else repr(self.ins)


_LEAF = {"Nop", "Null", "IntOne", "IntZero", "IntConst", "ShortConst", "FloatConst", "StringConst",
         "NameConst", "ByteConst", "BoolTrue", "BoolFalse", "LocalVar", "ParamVar", "ObjectVar",
         "ObjectBindableVar", "DefaultVar", "This", "SaveValue", "SwitchDefault",
         "Jump", "Target", "SavePointEnd",
         "GetGame", "GetPlayer", "GetCamera", "GetHud", "GetSound", "GetDebug", "GetTimer",
         "GetInput", "GetTelemetry"}
_ARITY = {"Assign": 2, "JumpIfFalse": 1, "Switch": 1, "SwitchLabel": 1, "Return": 1, "Skip": 1,
          "Conditional": 3, "StructMember": 1, "Context": 2, "TestEqual": 2, "TestNotEqual": 2,
          "New": 1, "Delete": 1, "Parent": 1,
          "ArrayClear": 1, "ArraySize": 1, "ArrayResize": 2, "ArrayFindFirst": 2,
          "ArrayFindFirstFast": 2, "ArrayFindLast": 2, "ArrayFindLastFast": 2,
          "ArrayContains": 2, "ArrayContainsFast": 2, "ArrayPushBack": 2, "ArrayPopBack": 1,
          "ArrayInsert": 3, "ArrayRemove": 2, "ArrayRemoveFast": 2, "ArrayGrow": 2,
          "ArrayErase": 2, "ArrayEraseFast": 2, "ArrayLast": 1, "ArrayElement": 2,
          "StaticArraySize": 1, "StaticArrayFindFirst": 2, "StaticArrayFindFirstFast": 2,
          "StaticArrayFindLast": 2, "StaticArrayFindLastFast": 2, "StaticArrayContains": 2,
          "StaticArrayContainsFast": 2, "StaticArrayLast": 1, "StaticArrayElement": 2,
          "IntToEnum": 1, "EnumToString": 1, "EnumToInt": 1, "DynamicCast": 1}
_CALLS = {"FinalFunc", "VirtualFunc", "VirtualParentFunc", "EntryFunc"}


def parse_tree(instrs):
    """Statements of a function as Node trees. Breakpoint markers are dropped (they may also
    appear between an instruction and its operands). Raises ValueError if the code does not
    parse completely, which would mean an unknown construct."""
    ins = [i for i in instrs if i.name != "Breakpoint"]
    pos = 0

    def expr():
        nonlocal pos
        if pos >= len(ins):
            raise ValueError("bytecode ends inside an expression")
        i = ins[pos]
        pos += 1
        n = i.name
        if n in _LEAF:
            return Node(i)
        if n in _ARITY:
            return Node(i, [expr() for _ in range(_ARITY[n])])
        if n in _CALLS:
            kids = []
            while ins[pos].name != "ParamEnd":
                kids.append(expr())
            pos += 1
            return Node(i, kids)
        if n == "Constructor":
            return Node(i, [expr() for _ in range(i.args[0])])
        if n == "SavePoint":
            kids = []
            while ins[pos].name != "SavePointEnd":
                kids.append(expr())
            pos += 1
            return Node(i, kids)
        if n.endswith(("ToBool", "ToByte", "ToInt", "ToFloat", "ToString")):
            return Node(i, [expr()])
        raise ValueError(f"unexpected {i!r}")

    out = []
    while pos < len(ins):
        out.append(expr())
    return out
