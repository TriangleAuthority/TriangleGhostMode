"""Set integer or float properties in a CR2W resource (.w2scene, .w2phase, .w2ent, ...) in place.

Same-size edits only: an Int32/Uint32 (or Int8/16, Uint8/16) or Float property already present in a
chunk's property list, at the top level or inside struct properties (PROPERTY is then a dotted path,
e.g. W3Dimeritium.impactParams.range). Each edit names the chunk class, the property, the value
expected now and the new value; every chunk of that class whose property has the expected value is
changed, also in the CR2W files embedded in byte-array properties (an entity template's compiled copy,
flatCompiledData), whose own CRCs are recomputed. The chunk CRCs, the export table's CRC and the header
CRC are recomputed (CR2W: chunk CRC = CRC32 of its data; table CRC = CRC32 of the table; header CRC =
CRC32 of the 160-byte header and table headers with the CRC field set to 0xDEADBEEF), so the file
stays valid for the game.

    python tools/cr2w_patch.py FILE CLASS.PROPERTY[.FIELD]=OLD:NEW [...] [--check]

Values with a decimal point are floats. Prints each change; fails if an edit matches nothing. --check
changes nothing and fails if an edit would still change something (i.e. the file is not patched yet).
"""
import argparse, struct, sys, zlib, os

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import cr2w_dump

FORMATS = {"Int32": "<i", "Uint32": "<I", "Int16": "<h", "Uint16": "<H", "Int8": "<b", "Uint8": "<B", "Float": "<f"}


def find_props(f, d, pos, end):
    """Yields (name, type, value offset, value end) for the property list at d[pos:end]."""
    if d[pos] == 0:  # chunks and structs start with a zero byte before the property list
        pos += 1
    while pos + 2 <= end:
        ni = struct.unpack_from("<H", d, pos)[0]
        if ni == 0:
            return
        ti, size = struct.unpack_from("<HI", d, pos + 2)
        yield f.name(ni), f.name(ti), pos + 8, pos + 4 + size
        pos = pos + 4 + size


def edit_props(f, d, pos, end, path, old, new, label):
    """Applies one edit to the property list at d[pos:end] (path: the property, or the struct fields to it)."""
    out = []
    for pname, ptype, vs, ve in find_props(f, d, pos, end):
        if pname != path[0]:
            continue
        if len(path) > 1:
            out += edit_props(f, d, vs, ve, path[1:], old, new, label)
            continue
        if ptype not in FORMATS or ve - vs != struct.calcsize(FORMATS[ptype]):
            raise SystemExit("%s is %s, not an integer or float" % (label, ptype))
        fmt = FORMATS[ptype]
        v = struct.unpack_from(fmt, d, vs)[0]
        if (abs(v - old) > 1e-6) if ptype == "Float" else (v != old):
            continue
        struct.pack_into(fmt, d, vs, float(new) if ptype == "Float" else int(new))
        out.append("%s: %s -> %s" % (label, old, new))
    return out


def embedded_blobs(f, d, pos, end):
    """Yields (offset, size) of the CR2W files embedded in byte-array properties of a property list."""
    for pname, ptype, vs, ve in find_props(f, d, pos, end):
        if ptype.startswith("array:") and ptype.endswith(",Uint8") and bytes(d[vs + 4:vs + 8]) == b"CR2W":
            yield vs + 4, struct.unpack_from("<I", d, vs)[0]


def patch(data, edits, label=""):
    """Returns (new data, list of changes); the changes name each edit that matched nothing as NO MATCH
    (only at the top level: an edit may match only the file or only an embedded copy)."""
    d = bytearray(data)
    f = cr2w_dump.CR2W(bytes(d))
    coff = f.tables[4][0]
    changes = []
    hit = set()
    for i, ch in enumerate(f.chunks):
        start, end = ch["off"], ch["off"] + ch["size"]
        for eo, es in list(embedded_blobs(f, d, start, end)):
            sub, subchanges, subhit = patch(bytes(d[eo:eo + es]), edits, "%schunk %d embedded: " % (label, i))
            d[eo:eo + es] = sub
            changes += subchanges
            hit |= subhit
        for k, (cls, prop, old, new) in enumerate(edits):
            if ch["cls"] == cls:
                c = edit_props(f, d, start, end, prop.split("."), old, new, "%schunk %d %s.%s" % (label, i, cls, prop))
                if c:
                    hit.add(k)
                changes += c
        struct.pack_into("<I", d, coff + 24 * i + 20, zlib.crc32(bytes(d[start:end])))
    off, count, _ = f.tables[4]
    struct.pack_into("<I", d, 40 + 12 * 4 + 8, zlib.crc32(bytes(d[off:off + 24 * count])))
    struct.pack_into("<I", d, 32, 0xDEADBEEF)
    struct.pack_into("<I", d, 32, zlib.crc32(bytes(d[:160])))
    return bytes(d), changes, hit


def check_crcs(data):
    """True if the header, export table and chunk CRCs are consistent, also in embedded CR2W files."""
    f = cr2w_dump.CR2W(data)
    coff, count, tcrc = f.tables[4]
    ok = all(struct.unpack_from("<I", data, coff + 24 * i + 20)[0] == zlib.crc32(data[c["off"]:c["off"] + c["size"]])
             for i, c in enumerate(f.chunks))
    ok = ok and tcrc == zlib.crc32(data[coff:coff + 24 * count])
    h = bytearray(data[:160])
    struct.pack_into("<I", h, 32, 0xDEADBEEF)
    ok = ok and struct.unpack_from("<I", data, 32)[0] == zlib.crc32(bytes(h))
    for c in f.chunks:
        for eo, es in embedded_blobs(f, data, c["off"], c["off"] + c["size"]):
            ok = ok and check_crcs(bytes(data[eo:eo + es]))
    return ok


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("file")
    ap.add_argument("edits", nargs="+", help="CLASS.PROPERTY[.FIELD]=OLD:NEW")
    ap.add_argument("--check", action="store_true")
    a = ap.parse_args()
    edits = []
    for e in a.edits:
        target, vals = e.split("=", 1)
        cls, prop = target.split(".", 1)
        old, new = vals.split(":", 1)
        num = float if ("." in old or "." in new) else int
        edits.append((cls, prop, num(old), num(new)))
    data = open(a.file, "rb").read()
    if not check_crcs(data):
        raise SystemExit("%s: CRCs inconsistent before patching; not touching it" % a.file)
    out, changes, hit = patch(data, edits)
    missing = ["NO MATCH %s.%s=%s" % (e[0], e[1], e[2]) for k, e in enumerate(edits) if k not in hit]
    if a.check:
        print("\n".join(changes) or "already patched")
        sys.exit(1 if changes else 0)
    if missing:
        print("\n".join(changes + missing))
        raise SystemExit("an edit matched nothing; file not written")
    if not check_crcs(out):
        raise SystemExit("CRC recomputation failed; file not written")
    open(a.file, "wb").write(out)
    print("\n".join(changes))


if __name__ == "__main__":
    main()
