# Sweep A: Shared Imports and Community Patch – Base units (2026-11-02)

Batch: every unit unattributed on master `d6062e97` whose `origin` is `SI` (Shared Imports v0.6) or `CPB` (Community Patch – Base v1.0): **192 units** (154 SI, 38 CPB). None of them has a `GM` origin too: Ghost Mode 4.1 left every one as its dependency had it. Offline analysis only; no game.

**Result: all 192 are `DEP`.** 179 are built into 5.x; 13 are not in 5.x, and Ghost Mode needs none of them. No gaps, no new features. Every unit is settled in `attribution.csv` (67 rows: a `::*` row for each `scripts/local` file and for `areaTypes.ws`, one row per unit everywhere else).

How it was checked: the units were compared with `change_units.py`'s own unit parser across `master` (1.32), `legacy-GM~2` (SI), `legacy-GM~1` (CPB), `legacy-GM` (GM) and `vanilla-5.x`, comments and whitespace ignored. SI's `scripts/local/*.ws` were compared with 5.x's `scripts/engine/*.ws` of the same name, where 5.x keeps them. Ghost Mode's dependence on them was checked two ways: every member name SI declares was grepped as a member access in Ghost Mode 4.1's added lines and in 5.x-GM's `scripts/local/gm` (`b3ec3609`), and every CPB function or field was grepped in both. 5.x-GM changes none of these vanilla files (`git diff vanilla-5.x b3ec3609` is empty for them), and none of its annotations targets a method in this batch.

## Shared Imports (154 units)

Shared Imports adds `import var` and `import function` declarations for engine classes, so scripts can read native properties. It has no logic. 5.0 ships the same declarations: its `scripts/engine/` holds the 13 files that SI put under `scripts/local/`, and its `components.ws` has SI's additions.

| Units | Category | Legacy-GM | 5.x | Note |
|---|---|---|---|---|
| `scripts/local/CActionpointComponent.ws` (1) | 4 built into 5.x | `scripts/local/CActionpointComponent.ws` | `scripts/engine/CActionpointComponent.ws`, identical | |
| `scripts/local/CAnimatedComponent.ws` (8: `CRagdoll`, `CSkeleton`, `SSkeletonBone`, ...) | 4 | same file | `engine/CAnimatedComponent.ws`, identical | |
| `scripts/local/CAreaEnvironmentComponent.ws` (2) | 4 | same file | `engine/CAreaEnvironmentComponent.ws`, identical | |
| `scripts/local/CCameraComponent.ws` (2) | 4 | same file | `engine/CCameraComponent.ws`, identical | |
| `scripts/local/CClothComponent.ws` (2) | 4 | same file | `engine/CClothComponent.ws`, identical | |
| `scripts/local/CDestructionComponent.ws` (9) | 4 | same file | `engine/CDestructionComponent.ws` | 5.x renamed three debris fields and types `fractureSoundEvent` as `String` (`CDestructionComponent.<members>`, 5.x line 123) |
| `scripts/local/CEntityTemplate.ws` (13) | 4 | same file | `engine/CEntityTemplate.ws`, identical | **Ghost Mode uses `CEntityTemplate.includes`**: legacy `gm_bugfixes.ws:352` (NPC armor ability from the template) and `console_debug.ws:224`; the port's DMG-15 at `local/gm/damage/weapon.ws:102`. 5.x declares it natively at `CEntityTemplate.ws:7`. |
| `scripts/local/CEnvironmentDefinition.ws` (62) | 4 | same file | `engine/CEnvironmentDefinition.ws` | 5.x adds `skyGIBrighthessCoef` (`CEnvGlobalSkyParameters`), the BLAS fields (`SMeshCookedData`), and `String` sound events (`CGameWorld`) |
| `scripts/local/CFurComponent.ws` (22) | 4 | same file | `engine/CFurComponent.ws`, identical | |
| `scripts/local/CLightComponent.ws` (4) | 4 | same file | `engine/CLightComponent.ws` | 5.x drops the spot light's `projectionTexture*` fields (`CSpotLightComponent`, 5.x line 35) |
| `scripts/local/CParticleComponent.ws` (3) | 4 | same file | `engine/CParticleComponent.ws`, identical | |
| `scripts/local/CSoundAmbientAreaComponent.ws` (6) | 4 | same file | `engine/CSoundAmbientAreaComponent.ws` | 5.x types the sound event names `String`, not `StringAnsi` |
| `scripts/local/CTriggerAreaComponents.ws` (1) | 4 | same file | `engine/CTriggerAreaComponents.ws`, identical | |
| `components.ws`: the `<members>` of `CComponent`, `CInteractionAreaComponent`, `CInteractionComponent`, `CAnimatedComponent`, `CDropPhysicsComponent`, `CBoundedComponent`, `CAreaComponent`, `CDrawableComponent`, `CRigidMeshComponent`, `CTriggerAreaComponent`, `CTriggerActivatorComponent`, and the new `CDecalComponent`, `CNormalBlendComponent`, `CSpriteComponent` (14) | 4 | `scripts/engine/components.ws` (lines 15–679) | `components.ws` lines 7–655, same members | 5.x also adds `CAnimatedComponent.PlayAnimationOnSkeleton` |
| `components.ws`: `CDestructionSystemComponent.<members>` and `.GetObjectBoundingVolume`, `CDestructionComponent.<members>` and `.GetObjectBoundingVolume`, `CClothComponent.<members>` (5, removed) | 4 | moved to `scripts/local/CDestructionComponent.ws` and `CClothComponent.ws` | moved the same way: `engine/CDestructionComponent.ws:55, 110, 123, 155`, `engine/CClothComponent.ws:12` | |

The differences in the four files are 5.x's own updates to the engine declarations, which supersede SI's. No Ghost Mode code, legacy or port, reads any of the changed fields.

## Community Patch – Base (38 units)

CPB's script changes make the Steam, GOG and GOTY 1.31/1.32 scripts identical: a random main menu, no "DLC installed" and welcome pop-ups, the "BUTTON" option type, the DLC options group, and refreshing the main menu once `content12` finishes installing. It also moves the area enums into `areaTypes.ws` for community hub mods. Ghost Mode's own code calls none of it. Its menu (legacy `menu/modSignsConfig.xml`) has no BUTTON option, and the port's menu is 5.x's Mods menu (`menu/modGhostMode.xml`, OPT).

| Unit | Category | Legacy-GM | 5.x | Note |
|---|---|---|---|---|
| `areaTypes.ws::EAreaName`, `EDlcAreaName`, `AreaNameToType`, `AreaTypeToName` (4, added) | 5 not in 5.x | `areaTypes.ws:1, 16, 22, 53` (moved unchanged from 1.32 `types.ws:52–105`) | no script `EAreaName` in 5.x: native (`questWorld.ws:9` uses it with no script definition); areas are passed as names (`commonMapManager.ws:605`, `lootManager.ws` `OnAreaChanged(newArea : name)`) | Superseded. Hub support is moot; the port already uses the name form (`local/gm/ai/levels.ws:229`, `'AN_NMLandNovigrad'`) |
| `types.ws::EAreaName`, `EDlcAreaName`, `AreaNameToType`, `AreaTypeToName` (4, removed) | 5 not in 5.x | commented out at `types.ws:53–106` | not in 5.x `types.ws` | The other half of the move above |
| `commonMainMenuBase.ws::CR4CommonMainMenuBase.OnConfigUI` | 4 | line 19 | `commonMainMenuBase.ws:69` | Menu music follows the random menu |
| `hud.ws::CR4ScriptedHud.OnConfigUI` | 4 | line 329 | `hud.ws:335`, no `CheckDLCMessagePending()` call | No "DLC installed" pop-up |
| `hudModuleTimeLapse.ws::CR4HudModuleTimeLapse.SetTimeLapseMessageTest`, `testTurkish1`, `testTurkish2` (3) | 4 | lines 72, 95, 111 | same lines, identical | Vanilla 1.31 test helpers |
| `ingameMenu.ws::InGameMenuActionType` | 4 | line 1 | `IGMActionType_Button = 28`, `ingameMenu.ws:36` | |
| `ingameMenu.ws::CR4IngameMenu.OnConfigUI` | 4 (in part 5) | line 143 | `UpdateAnchorsAspectRatio` at `ingameMenu.ws:142, 276, 450` | The `content12` gating of the expansion texts and the `RefreshMainMenuAfterContentLoaded()` call are not in 5.x, which handles a missing `content12` its own way (`ingameMenu.ws:4101`) |
| `ingameMenu.ws::CR4IngameMenu.OnRefresh` | 5 not in 5.x | line 340 | `ingameMenu.ws:546`, block reworked without the gate | Shows the expansion status texts only while `content12` is missing; cosmetic |
| `ingameMenu.ws::CR4IngameMenu.StartShowingCustomDialogs` | 4 | line 763 | `ingameMenu.ws:1242`, no welcome messages | |
| `ingameMenu.ws::CR4IngameMenu.OnButtonClicked` | 4 | line 1028 | `ingameMenu.ws:3270` (adds a `groupId` parameter) | |
| `ingameMenu.ws::ddd` | 4 | line 2194 | `ingameMenu.ws:5452`, identical | Vanilla test exec function |
| `igmOptions.ws::IngameMenu_GetOptionTypeFromString` | 4 | line 1 | `igmOptions.ws:54` | "BUTTON" type |
| `igmOptions.ws::IngameMenu_FillOptionsSubMenuData` | 4 | line 34 | `igmOptions.ws:222` | Passes `isMainMenu` |
| `igmOptions.ws::IngameMenu_FillArrayFromConfigGroup` | 4 | line 250 | signature `igmOptions.ws:291`; the DLC group at 216 and 247 | |
| `igmStructureCreator.ws::IngameMenuStructureCreator.CreateNewGameListArray` | 5 not in 5.x | line 195 | `igmStructureCreator.ws:266`, no `unavailable` flags | Greys out the Hearts of Stone, Blood and Wine and NG+ new-game entries when unavailable; every 5.x edition has both expansions |
| `mainCreditsMenu.ws::CR4MainCreditsMenu.OnCloseMenu` | 4 | line 380 | `mainCreditsMenu.ws:412`, identical | |
| `menuBase.ws::CR4MenuBase.<members>`, `.OnConfigUI`, `.setArabicAligmentMode` (3) | 4 | lines 37, 84, 515 | `menuBase.ws:46, 109, 530` | `setGameLanguage` to Flash |
| `popupBase.ws::CR4PopupBase.<members>`, `.OnConfigUI`, `.setArabicAligmentMode` (3) | 4 | lines 11, 23, 107 | `popupBase.ws:11, 31, 103`, identical | Same, for pop-ups |
| `r4guimanager.ws::CR4GuiManager.<members>`, `.Update`, `.RefreshMainMenuAfterContentLoaded` (3) | 5 not in 5.x | lines 111, 245, 271 | `r4guimanager.ws:132, 516`: 5.x refreshes the menu for `activeUserDisplayNameNeedsRefresh` instead | Refreshes the main menu when `content12` finishes installing |
| `r4Game.ws::CR4Game.<members>` | 4 | line 37 | `DisplayStore` at `r4Game.ws:291`, `_mainMenuType` at 1437 | |
| `r4Game.ws::CR4Game.PopulateMenuQueueStartupAlways`, `PopulateMenuQueueMainAlways`, `GetChosenMainMenuType`, `ChooseRandomMainMenuIfNotChosenYet` (4) | 4 | lines 1228, 1272, 1294, 1299 | `r4Game.ws:1364, 1415, 1439, 1444` (the last three identical; the first adds 5.x's GDK lines) | Random main menu |

**The OPT audit's 11 CPB menu units, confirmed with two corrections.** Eight are built into 5.x as the audit said: `InGameMenuActionType`, `StartShowingCustomDialogs`, `OnButtonClicked`, `ddd`, the three `igmOptions.ws` functions and `CR4MainCreditsMenu.OnCloseMenu`. `CR4IngameMenu.OnConfigUI` is built in except its `content12` lines. `CR4IngameMenu.OnRefresh` and `IngameMenuStructureCreator.CreateNewGameListArray` are not in 5.x. Ghost Mode needs neither.

## Summary by category

| Category | Units |
|---|---|
| 1 Existing feature, ported | 0 |
| 2 Existing feature, not ported | 0 |
| 3 New feature | 0 |
| 4 Dependency, built into 5.x | 179 (SI 154, CPB 25; `CR4IngameMenu.OnConfigUI` counted here, its `content12` lines aside) |
| 5 Dependency, not in 5.x | 13 (CPB: the 8 area-enum units in `areaTypes.ws` and `types.ws`, `OnRefresh`, `CreateNewGameListArray`, the 3 `r4guimanager.ws` units); Ghost Mode needs none |
| 6 Debug or dev only | 0 separately: the vanilla test exec functions `testTurkish1`, `testTurkish2`, `SetTimeLapseMessageTest` and `ddd` are in 5.x as they are, so `DEP` |
| 7 No effect | 0 |
| 8 Unclear | 0 |

Unattributed units in the batch: **192 before, 0 after**.

## Gaps and new features

None. A legacy player had nothing from these two dependencies that the port lacks in play: the parts 5.x lacks are main-menu behaviour during a staggered install, the greyed-out expansion entries and the hub-mod area file. 5.x handles the first its own way, the second is moot (every 5.x edition has both expansions), and the third is superseded by 5.x's name-based areas. None of it is gameplay.

## Owner questions

None.

## Suggestions for shared docs (not edited)

- [legacy-ghost-mode.md](../../legacy-ghost-mode.md#dependencies) says 5.0 has "part of ... `r4guimanager.ws`". None of CPB's `r4guimanager.ws` change is in 5.x. 5.x has a similar refresh for the user name.
- The same paragraph says hub support is missing from 5.0 (`areaTypes.ws`, `types.ws`) and asks for a decision. Settled: 5.x has no script area enum (native) and uses area names, so the move is moot; `DEP`, dropped.
- [opt.md](../opt.md) (unit lists paragraph and the DEP row) calls the 11 CPB menu units "1.32's mod-menu plumbing that 5.x has natively". Three are not fully in 5.x (above); they are attributed `DEP` "not in 5.x" with the reason.
- [feature-mapping.md](../../feature-mapping.md) "Expected outcome for SI and CPB units": confirmed, all `DEP`.

## Outside the batch

- master's `coverage.md` is 3 units stale: master `d6062e97` added attribution rows for the Hearts of Stone `Shovel _Stats` (both folders) and `Body palms cut` without regenerating it. A fresh `change_units.py` run on master gives 332 unattributed, not 335.
