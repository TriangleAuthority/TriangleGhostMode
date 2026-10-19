"""Set integer properties in a CR2W resource (.w2scene, .w2phase, .w2ent, ...) in place.

Same-size edits only: an Int32/Uint32 (or Int8/16, Uint8/16) property already present in a chunk's
top-level property list. Each edit names the chunk class, the property, the value expected now and
the new value; every chunk of that class whose property has the expected value is changed. The
chunk CRCs, the export table's CRC and the header CRC are recomputed (CR2W: chunk CRC = CRC32 of
its data; table CRC = CRC32 of the table; header CRC = CRC32 of the 160-byte header and table
headers with the CRC field set to 0xDEADBEEF), so the file stays valid for the game.

    python tools/cr2w_patch.py FILE CLASS.PROPERTY=OLD:NEW [...] [--check]

Prints each change; fails if an edit matches nothing. --check changes nothing and fails if an
edit would still change something (i.e. the file is not patched yet).
"""
import argparse, struct, sys, zlib, os

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import cr2w_dump

INT_FORMATS = {"Int32": "<i", "Uint32": "<I", "Int16": "<h", "Uint16": "<H", "Int8": "<b", "Uint8": "<B"}


def find_props(f, d, chunk):
    """Yields (name, type, value offset, value end) for a chunk's top-level properties."""
    pos, end = chunk["off"], chunk["off"] + chunk["size"]
    if d[pos] == 0:  # chunks start with a zero byte before the property list
        pos += 1
    while pos + 2 <= end:
        ni = struct.unpack_from("<H", d, pos)[0]
        if ni == 0:
            return
        ti, size = struct.unpack_from("<HI", d, pos + 2)
        yield f.name(ni), f.name(ti), pos + 8, pos + 4 + size
        pos = pos + 4 + size


def patch(data, edits):
    d = bytearray(data)
    f = cr2w_dump.CR2W(bytes(d))
    coff = f.tables[4][0]
    changes = []
    for cls, prop, old, new in edits:
        hits = 0
        for i, ch in enumerate(f.chunks):
            if ch["cls"] != cls:
                continue
            for pname, ptype, vs, ve in find_props(f, d, ch):
                if pname != prop:
                    continue
                if ptype not in INT_FORMATS or ve - vs != struct.calcsize(INT_FORMATS[ptype]):
                    raise SystemExit("%s.%s is %s, not an integer" % (cls, prop, ptype))
                v = struct.unpack_from(INT_FORMATS[ptype], d, vs)[0]
                if v != old:
                    continue
                struct.pack_into(INT_FORMATS[ptype], d, vs, new)
                struct.pack_into("<I", d, coff + 24 * i + 20, zlib.crc32(bytes(d[ch["off"]:ch["off"] + ch["size"]])))
                changes.append("chunk %d %s.%s: %d -> %d" % (i, cls, prop, old, new))
                hits += 1
        if hits == 0:
            changes.append("NO MATCH %s.%s=%d" % (cls, prop, old))
    off, count, _ = f.tables[4]
    struct.pack_into("<I", d, 40 + 12 * 4 + 8, zlib.crc32(bytes(d[off:off + 24 * count])))
    struct.pack_into("<I", d, 32, 0xDEADBEEF)
    struct.pack_into("<I", d, 32, zlib.crc32(bytes(d[:160])))
    return bytes(d), changes


def check_crcs(data):
    """True if the header, export table and chunk CRCs are consistent."""
    f = cr2w_dump.CR2W(data)
    coff, count, tcrc = f.tables[4]
    ok = all(struct.unpack_from("<I", data, coff + 24 * i + 20)[0] == zlib.crc32(data[c["off"]:c["off"] + c["size"]])
             for i, c in enumerate(f.chunks))
    ok = ok and tcrc == zlib.crc32(data[coff:coff + 24 * count])
    h = bytearray(data[:160])
    struct.pack_into("<I", h, 32, 0xDEADBEEF)
    return ok and struct.unpack_from("<I", data, 32)[0] == zlib.crc32(bytes(h))


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("file")
    ap.add_argument("edits", nargs="+", help="CLASS.PROPERTY=OLD:NEW")
    ap.add_argument("--check", action="store_true")
    a = ap.parse_args()
    edits = []
    for e in a.edits:
        target, vals = e.split("=", 1)
        cls, prop = target.split(".", 1)
        old, new = vals.split(":", 1)
        edits.append((cls, prop, int(old), int(new)))
    data = open(a.file, "rb").read()
    if not check_crcs(data):
        raise SystemExit("%s: CRCs inconsistent before patching; not touching it" % a.file)
    out, changes = patch(data, edits)
    if a.check:
        pending = [c for c in changes if not c.startswith("NO MATCH")]
        print("\n".join(pending) or "already patched")
        sys.exit(1 if pending else 0)
    if any(c.startswith("NO MATCH") for c in changes):
        print("\n".join(changes))
        raise SystemExit("an edit matched nothing; file not written")
    if not check_crcs(out):
        raise SystemExit("CRC recomputation failed; file not written")
    open(a.file, "wb").write(out)
    print("\n".join(changes))


if __name__ == "__main__":
    main()
