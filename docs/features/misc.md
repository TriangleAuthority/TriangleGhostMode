# MISC: misfits

Ghost Mode changes that fit no area, feature or [pillar](pillars.md), gathered here until they are dealt with. Anything goes in: a legacy change nobody can place, a port idea, a 5.x behaviour worth a look, a loose end from a slice.

- **Adding:** one row per misfit, with where it was found and why it does not fit. When a unit in `units.csv` needs attributing, give the row an ID (`MISC-01`, `MISC-02`, ...; never reused) and attribute the unit to it in [attribution.csv](attribution.csv), so it stops showing in [coverage.md](coverage.md).
- **Not here:** changes that belong to an area not mapped yet go into the hand-off list of the area file where they turned up (e.g. [stam.md](stam.md#hand-off-to-other-areas)); noise (re-save artifacts, formatting) is noted as noise.
- **Leaving:** when a misfit is tackled, move it into the area or feature it ends up in, or record the decision not to port it, and delete the row (keep its ID in a note if units were attributed to it).

| ID | Misfit | Found in | Why it fits nowhere | Added |
|---|---|---|---|---|

No open misfits.

**Closed** (each decided; the IDs stay on their units in [attribution.csv](attribution.csv), 28 units in all; numbered in the whole-port fix round, 2026-11-03, A8-4):

| ID | Units | Decision |
|---|---|---|
| MISC-01 | Legacy's two translators' `readme.txt` files | No effect: notes on encoding the CSVs, not shipped to the game (sweep B, 2026-11-02) |
| MISC-02 | An orphan Spanish string row (2110992503) | No effect: looked up nowhere; the port's Spanish Acquired Tolerance text uses the English text with the sentence included (SKL-19) (sweep B, 2026-11-02) |
| MISC-03 | 16 debug console commands (`dumpallquests`, `whoami`, `sethp`, `immortal`, `enabledeletedscene` and others; `addsetrec` only had a parameter renamed) | Dropped: debug only; the port tests through its `gmtest_*` exec functions and `tools/game.py`. `enabledeletedscene` set `q401_cooking_enabled` for a cut Kaer Morhen cooking scene (FOOD's mapping, 2026-10-23) (sweep B, 2026-11-02) |
| MISC-04 | `SQ102Finished` | No effect: dead code, no caller in legacy (sweep B, 2026-11-02) |
| MISC-05 | Whitespace in two signatures (`ReactToReflectedAttack`, `AddAllThMaps`), a stray semicolon after an enum (`gm_generic.ws`) | No effect (sweep B, 2026-11-02) |
| MISC-06 | Five binary files W3Edit only re-saved | No effect: re-save only, nothing to port ([binary-files.md](../binary-files.md)) (sweep C, 2026-11-02) |
