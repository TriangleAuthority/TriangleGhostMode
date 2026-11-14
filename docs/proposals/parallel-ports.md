# Porting areas in parallel

Status: **implemented** (approved by the owner 2026-11-02). Areas that share no files are ported at the same time, one agent per area, each in its own worktree, sharing the one game install through a lock tool and queue. The procedure an area agent follows, sharing files and integration are in [development.md: Working in parallel](../development.md#working-in-parallel); the game slot, its commands and its guards in [game-automation.md: The game slot](../game-automation.md#the-game-slot); the tools in [tools.md](../tools.md).

This page keeps only the two sections that code comments and docs cite.

## 5. Shared ownership

Settled before areas branch, so no two areas edit the same lines (the rule in [development.md](../development.md#working-in-parallel)):

- **Per-area hooks:** each area's checks in its own `tests/gmTests<Area>.ws` (`GMTest_<area>()` called from `gmtest_regress()`, `GMTest_<area>_after()` from `gmtest_panel()`); `item_layer.py`'s `PORTED`, `TAGS`, `NODES`, `BLOCKS` and `ATTRS` sets one line per area; the string CSVs merged by union (`.gitattributes`), the build stopping on a duplicate string id.
- **OPT, WGT and TRPH:** OPT owns the menu (`modGhostMode.xml`), `gmOptions.ws` and the option labels, WGT's three entries included (boat sinking, its threshold, the weight reduction); WGT owns their mechanics, with the mod's only `@replaceMethod` of `W3Boat.OnAreaEnter` and of `CInventoryComponent.GetItemEncumbrance`. `gen_trph.py` writes the trophy abilities whole, legacy's weights included, and `gen_wgt.py` skips names another DLC file defines. Checks of the carry limit read it from the game, never as a fixed number (the Wight trophy adds to it).

## 6. Integration

A fresh integrator agent merges each area's squashed `gm/<area>` into `master` in batches, rebuilds the generated files with the merged tools (`tools/gen_all.py`), runs every check and a compile, regenerates the generated docs and runs the integrated regression in both trees as holder `integration`; the steps are in [development.md](../development.md#working-in-parallel).
