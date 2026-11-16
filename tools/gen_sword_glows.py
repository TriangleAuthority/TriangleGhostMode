"""Generate the new tree's own sword glows: recolored copies of 5.x's sword buff effects, so the player can
tell the skills apart from the skills that share 5.x's glows.

- gm_mm_buff (Muscle Memory, SKL-03, sword_s22): a copy of fast_attack_buff, the blue glow Precise Blows and
  the Feline set also show; green, 60,230,90 (owner's request, 2026-11-09).
- gm_st_buff (Strength Training, SKL-04, sword_s23): a copy of strong_attack_buff, the orange glow Crushing
  Blows also shows; yellow, 255,220,50 (owner's request, 2026-11-10).

Writes, under modGhostMode/files/ in the worktree (cooked files, read from the installed game's bundles and
patched; nothing is cooked), per glow:

- dlc/dlcghostmode/fx/<effect>_fx.w2p: the source effect's particle system with the color: emitter
  glow_distort's material color, and glow_distort_start's color over life (start a quarter of the way to
  white, end the color). Same-size byte edits of the cooked emitter data, CRCs recomputed.
- dlc/dlcghostmode/fx/<effect>_imtl.w2mi: 5.x's sword_fresnel_strongattack_imtl.w2mi (the blade's fresnel
  material of strong_attack_buff, the only variant that sets its `glow` color) with `glow` the color.

and once, for both:

- items/weapons/swords/witcher_steel_swords/sword_steel_fx.w2ent and .../witcher_silver_swords/sword_silver_fx.w2ent
  (whole-file overrides at their vanilla paths: the witcher swords' templates include them and find their
  effects there): 5.x's file with the two cooked effects appended, each a copy of its source effect whose
  particles and material point to its two files above and whose two lights take the color (scaled to the
  vanilla lights' brightness, the largest channel 216). Every vanilla entry keeps its bytes.

The colors are the files' own: without a color option the generator keeps the color each generated .w2mi
has (the default when there is none yet), so the other tools' runs never reset them. Change one with one
command:

    python tools/gen_sword_glows.py --worktree . --st-color 255,220,50   (R,G,B, 0-255; also --mm-color)
    python tools/gen_sword_glows.py --worktree . [--check]               rewrite with the current colors / check

--check writes nothing and fails if a file is out of date or wrong: each output must decode, have valid CRCs,
and differ from 5.x's file only where this tool edits it (the sword templates: every vanilla effect byte for
byte, each new effect's dump equal to its source's but for the name, the two imports and the light colors).
See docs/features/skl.md (SKL-03, SKL-04) and docs/tools.md.

Needs, not in this repository: the game install (5.x; found by tools/paths.py through Steam or W3_GAME_DIR)'s bundles, for the cooked files it copies.
"""
import argparse
import os
import struct
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import paths  # noqa: E402
import cr2w_dump  # noqa: E402
import cr2w_patch  # noqa: E402

FILES = "modGhostMode/files/"
LYNX = "fx\\gameplay\\armor_sets\\lynx_set_ability1\\"
SRC_STRONG_IMTL = LYNX + "sword_fresnel_strongattack_imtl.w2mi"
STRONG_GLOW = (249, 179, 110)       # sword_fresnel_strongattack_imtl.w2mi's `glow`
TEMPLATES = ["items\\weapons\\swords\\witcher_steel_swords\\sword_steel_fx.w2ent",
             "items\\weapons\\swords\\witcher_silver_swords\\sword_silver_fx.w2ent"]
LIGHT_MAX = 216

# Per glow: the source effect and 5.x's values in the files the tool edits (it fails if the game's files no
# longer have them): the particle system's material `color` (also the end of the color over life), the start
# of the color over life, the effect's material and its two lights (light_sart, light).
GLOWS = [
    dict(opt="mm", skill="Muscle Memory", effect="gm_mm_buff", src_effect="fast_attack_buff",
         src_w2p=LYNX + "fast_attack_buff_fx.w2p", src_imtl=LYNX + "sword_fresnel_imtl.w2mi",
         w2p_color=(46, 130, 255), w2p_start=(100, 160, 255), lights=[(50, 100, 216), (52, 140, 216)],
         default=(60, 230, 90)),    # green (owner's request, 2026-11-09)
    dict(opt="st", skill="Strength Training", effect="gm_st_buff", src_effect="strong_attack_buff",
         src_w2p=LYNX + "strong_attack_buff_fx.w2p", src_imtl=SRC_STRONG_IMTL,
         w2p_color=(255, 130, 46), w2p_start=(255, 150, 100), lights=[(216, 51, 63), (216, 140, 52)],
         default=(255, 220, 50)),   # yellow (owner's request, 2026-11-10)
]
for _g in GLOWS:
    _g["new_w2p"] = "dlc\\dlcghostmode\\fx\\%s_fx.w2p" % _g["effect"]
    _g["new_imtl"] = "dlc\\dlcghostmode\\fx\\%s_imtl.w2mi" % _g["effect"]


def out_path(depot):
    return FILES + depot.replace("\\", "/")


def outputs():
    """The paths it writes (for gen_all.py --list)."""
    return [out_path(g[k]) for g in GLOWS for k in ("new_w2p", "new_imtl")] + [out_path(p) for p in TEMPLATES]


_INDEX = {}


def game_file(depot):
    """A file's bytes in the 5.x install: the last copy in bundle load order; every copy must be equal."""
    import extract_vanilla
    import unbundle
    if not _INDEX:
        for b in extract_vanilla.bundle_load_order(str(paths.game_dir())):
            for e in extract_vanilla.read_toc(b):
                _INDEX.setdefault(e.name.lower(), []).append(e)
    copies = []
    for e in _INDEX[depot.lower()]:
        with open(e.bundle, "rb") as f:
            copies.append(unbundle.read_entry(f, e))
    if any(c != copies[-1] for c in copies):
        raise SystemExit("%s: the bundles hold different copies; check which one the game uses" % depot)
    return copies[-1]


def floats(rgb):
    return b"".join(struct.pack("<f", c / 255.0) for c in rgb)


def float_run(data, values, tol=1e-4):
    """The bytes of the one run of consecutive floats in `data` equal to `values` (within tol): the cooked
    color over life keeps the colors as 0-1 floats, rounded its own way."""
    n = 4 * len(values)
    hits = [i for i in range(0, len(data) - n + 1)
            if all(abs(struct.unpack_from("<f", data, i + 4 * k)[0] - v) <= tol for k, v in enumerate(values))]
    if len(hits) != 1:
        raise SystemExit("%d runs of the floats %s, expected one" % (len(hits), values))
    return data[hits[0]:hits[0] + n]


def lighter(rgb, k=0.25):
    return tuple(int(round(c + (255 - c) * k)) for c in rgb)


def light_color(rgb):
    m = max(rgb) or 1
    return tuple(int(round(c * LIGHT_MAX / m)) for c in rgb)


def material_color_edits(data, old, new):
    """Byte edits of a Color parameter inside a cooked material instance's parameter list: the struct
    `00 | (Red Uint8 =R) (Green =G) (Blue =B) (Alpha =A) | 0000`, each field `name(2) type(2) size=5(4) value(1)`."""
    f = cr2w_dump.CR2W(data)
    names = {n: i for i, n in enumerate(f.names)}
    pat = b"".join(struct.pack("<HHI", names[fld], names["Uint8"], 5) + bytes([v])
                   for fld, v in zip(("Red", "Green", "Blue"), old))
    rep = b"".join(struct.pack("<HHI", names[fld], names["Uint8"], 5) + bytes([v])
                   for fld, v in zip(("Red", "Green", "Blue"), new))
    return [(pat, rep)]


def make_w2p(g, rgb):
    data = game_file(g["src_w2p"])
    edits = material_color_edits(data, g["w2p_color"], rgb)
    edits += [(float_run(data, [c / 255.0 for c in g["w2p_start"] + g["w2p_color"]]), floats(lighter(rgb)) + floats(rgb))]
    out, _ = cr2w_patch.patch_bytes(data, edits, "%s_fx.w2p: " % g["effect"])
    return out


def make_imtl(g, rgb):
    data = game_file(SRC_STRONG_IMTL)
    out, _ = cr2w_patch.patch_bytes(data, material_color_edits(data, STRONG_GLOW, rgb), "%s_imtl.w2mi: " % g["effect"])
    return out


def effect_transform(g, rgb):
    def transform(buf):
        lc = light_color(rgb)
        ops = [cr2w_patch.Op("CFXDefinition.name=%s:%s" % (g["src_effect"], g["effect"]))]
        for n, old in enumerate(g["lights"]):
            for fld, o, v in zip(("Red", "Green", "Blue"), old, lc):
                if o != v:
                    ops.append(cr2w_patch.Op("CFXTrackItemDynamicLight#%d.color.%s=%d:%d" % (n, fld, o, v)))
        out, _, hit = cr2w_patch.apply(buf, ops)
        if len(hit) != len(ops):
            raise SystemExit("%s: an edit matched nothing: %s" % (g["src_effect"], [str(o) for k, o in enumerate(ops) if k not in hit]))
        out, _ = cr2w_patch.repoint_imports(out, {g["src_w2p"]: g["new_w2p"], g["src_imtl"]: g["new_imtl"]})
        return out
    return transform


def make_template(depot, colors):
    data = game_file(depot)
    for g in GLOWS:
        data, _ = cr2w_patch.clone_cooked_effect(data, g["src_effect"], g["effect"], effect_transform(g, colors[g["opt"]]))
    return data


def current_color(wt, g):
    """The color the glow's generated .w2mi has, else its default."""
    p = os.path.join(wt, out_path(g["new_imtl"]))
    if not os.path.exists(p):
        return g["default"]
    data = open(p, "rb").read()
    f = cr2w_dump.CR2W(data)
    names = {n: i for i, n in enumerate(f.names)}
    vals = []
    for fld in ("Red", "Green", "Blue"):
        pat = struct.pack("<HHI", names[fld], names["Uint8"], 5)
        i = data.index(pat)
        vals.append(data[i + len(pat)])
    return tuple(vals)


def dump_text(data):
    return "\n".join(cr2w_dump.dump_file(data))


def expected_dump(g, src_dump, rgb):
    """The source effect's dump with this tool's edits: the name, the two imports and the lights' colors."""
    lc = light_color(rgb)
    expect = [line.replace(g["src_w2p"], g["new_w2p"]).replace(g["src_imtl"], g["new_imtl"])
              .replace("= " + g["src_effect"], "= " + g["effect"]) for line in src_dump]
    light = -1
    for i, line in enumerate(expect):
        if "CFXTrackItemDynamicLight" in line:
            light += 1
        for fld, k in (("Red", 0), ("Green", 1), ("Blue", 2)):
            if light >= 0 and line.strip().startswith("%s (Uint8) = " % fld) and expect[i - 1 - k].strip() == "color (Color):":
                expect[i] = line.split("=")[0] + "= %d" % lc[k]
    return expect


def verify(outputs, colors):
    """The checks --check runs on what the files should be (beyond being equal to the files on disk)."""
    bad = []
    for p, data in outputs.items():
        if not cr2w_patch.check_crcs(data):
            bad.append("%s: CRCs inconsistent" % p)
        dump_text(data)  # must decode
    for depot in TEMPLATES:
        new = cr2w_patch.cooked_effects(outputs[out_path(depot)])
        old = cr2w_patch.cooked_effects(game_file(depot))
        if list(new)[:len(old)] != list(old) or any(new[k] != old[k] for k in old) or list(new)[len(old):] != [g["effect"] for g in GLOWS]:
            bad.append("%s: vanilla effects changed or the new effects missing" % depot)
            continue
        for g in GLOWS:
            expect = expected_dump(g, dump_text(old[g["src_effect"]]).splitlines(), colors[g["opt"]])
            got = dump_text(new[g["effect"]]).splitlines()
            if expect != got:
                diff = [(x, y) for x, y in zip(expect, got) if x != y][:5]
                bad.append("%s: %s's dump is not %s's with the expected edits: %s" % (depot, g["effect"], g["src_effect"], diff))
    for g in GLOWS:
        w2p = outputs[out_path(g["new_w2p"])]
        src = game_file(g["src_w2p"])
        if len(w2p) != len(src):
            bad.append("%s: size changed" % g["new_w2p"])
        print("%s: %d bytes differ from 5.x's (color bytes, floats and CRCs)" % (g["new_w2p"], sum(x != y for x, y in zip(src, w2p))))
    return bad


def parse_color(ap, text, opt):
    rgb = tuple(int(x) for x in text.split(","))
    if len(rgb) != 3 or any(not 0 <= c <= 255 for c in rgb):
        ap.error("--%s-color takes R,G,B with each 0-255" % opt)
    return rgb


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    paths.add_worktree(ap)
    for g in GLOWS:
        ap.add_argument("--%s-color" % g["opt"], help="R,G,B (0-255): %s's glow; default: its generated files' color (%s at first)"
                        % (g["skill"], ",".join(map(str, g["default"]))))
    ap.add_argument("--check", action="store_true", help="write nothing; fail if a file is out of date or wrong")
    a = ap.parse_args()
    colors = {}
    for g in GLOWS:
        given = getattr(a, "%s_color" % g["opt"])
        if given and a.check:
            ap.error("a color option writes; --check takes the files' colors")
        colors[g["opt"]] = parse_color(ap, given, g["opt"]) if given else current_color(a.worktree, g)
    outputs = {}
    for g in GLOWS:
        rgb = colors[g["opt"]]
        outputs[out_path(g["new_w2p"])] = make_w2p(g, rgb)
        outputs[out_path(g["new_imtl"])] = make_imtl(g, rgb)
        print("%s: color %d,%d,%d; particle start %s, lights %s" % ((g["effect"],) + rgb + (lighter(rgb), light_color(rgb))))
    for depot in TEMPLATES:
        outputs[out_path(depot)] = make_template(depot, colors)
    bad = verify(outputs, colors)
    stale = []
    for p, data in outputs.items():
        full = os.path.join(a.worktree, p)
        cur = open(full, "rb").read() if os.path.exists(full) else None
        if cur != data:
            stale.append(p)
            if not a.check:
                os.makedirs(os.path.dirname(full), exist_ok=True)
                with open(full, "wb") as f:
                    f.write(data)
        print("%s %s (%d bytes)" % ("out of date" if cur != data and a.check else "written" if cur != data else "same", p, len(data)))
    for b in bad:
        print("FAIL", b)
    if bad or (a.check and stale):
        sys.exit(1)


if __name__ == "__main__":
    main()
