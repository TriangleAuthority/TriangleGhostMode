# MISC: misfits

Ghost Mode changes that fit no area, feature or [pillar](pillars.md), gathered here until they are dealt with. Anything goes in: a legacy change nobody can place, a port idea, a 5.x behaviour worth a look, a loose end from a slice.

- **Adding:** one row per misfit, with where it was found and why it does not fit. When a unit in `units.csv` needs attributing, give the row an ID (`MISC-01`, `MISC-02`, ...; never reused) and attribute the unit to it in [attribution.csv](attribution.csv), so it stops showing in [coverage.md](coverage.md).
- **Not here:** changes that belong to an area not mapped yet go into the hand-off list of the area file where they turned up (e.g. [stam.md](stam.md#hand-off-to-other-areas)); noise (re-save artifacts, formatting) is noted as noise.
- **Leaving:** when a misfit is tackled, move it into the area or feature it ends up in, or record the decision not to port it, and delete the row (keep its ID in a note if units were attributed to it).

| ID | Misfit | Found in | Why it fits nowhere | Added |
|---|---|---|---|---|
| — | `enabledeletedscene`: a debug command setting `q401_cooking_enabled` (a cut Kaer Morhen cooking scene); the unit is unattributed | FOOD's mapping ([food.md](food.md#scope)), 2026-10-23 | A quest scene's debug switch, not the food system or any other area | 2026-10-24 (FOOD audit) |
