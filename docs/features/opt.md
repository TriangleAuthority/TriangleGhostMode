# OPT: mod options

Ghost Mode's settings menu (Options → Mods → Ghost Mode) and what it sets: the four groups "Enemy scaling", "Experience", "Gameplay" and "QoL", their presets, the defaults a setting has before the player touches the menu, the code that reads each setting and re-applies it when the menu closes, and the options whose feature belongs to no other area: Geralt's Vitality regeneration (with his base regeneration, which the changelist puts under "General player abilities"), boat sinking when over-encumbered, the item weight reduction, instant sign casting and the gameplay and QoL presets. Ghost Mode's changelist has its own section, "Mod options" (lines 1176–1251), and mentions options in the "Stamina changes" section (lines 218–243), the weight lines of "Armor" (lines 925–935) and "General player abilities" (line 474); the mod description's section 8, "Mod customization options", sends the player to the changelist.

**The player-visible texts first.** Legacy's changelist, quoted exactly, for what this file maps (the scaling and experience options are quoted in [diff.md](diff.md) and [xp.md](xp.md#xp-07-experience-options), the stamina options in [stam.md](stam.md)): "Default settings for Gameplay are now automatically loaded if you haven't set them up in the menu manually (with presets or sliders). If you're updating from the previous mod version, make sure to re-apply your personal Gameplay settings after loading a save."; "Gameplay presets: recommended - enables boat sinking if overencumbered and cooldown for signs and special sword attacks; vanilla(ish) - restores stamina management to vanilla(ish) logic, i.e. melee has zero cost, signs drain 100% stamina; off - all zero and off."; "Sink the boat if overencumbered: enables boat sinking if Geralt is overencumbered."; "Overencumbrance threshold to sink the boat (%): defines overencumbrance threshold in percents relative to max carry weight at which boat sinking happens."; "Reduce item encumbrance (%): reduces item weight for all the items in percents."; "Combat/Out of combat vitality regen (additional): allows to additionally increase/decrease vitality regen in/out of combat (relative to default values)."; "QoL presets: recommended - enables sign instant casting and low stamina sfx; off - turns off sign instant casting and low stamina sfx."; "Instant sign casting with select key: allows to instantly cast a sign when corresponding sign selection key is pressed (3-7 by default)."; from "General player abilities": "Default health regen for Geralt in and out of combat is now zero."; from "Armor": "If your over encumbrance is too big (20% over the limit), the boat you're trying to board will sink (off by default, can be tweaked in options)." (the code turns it on: [DO3](#area-decisions)); from "Stamina changes": "if you don't like this type of combat and think that TW3 is better with vanilla stamina, you can switch the feature off in mod's options." Legacy's labels (English; every one in 9 languages, `localization/modGhostMode/<lang>.csv`): group "Gameplay" (2110992329) with "Gameplay Presets" (2110992450) and the presets "Recommended", "Vanilla(ish)", "Off" (2110992448, 459, 449); "Sink the boat if over encumbered" (180), "Over encumbrance threshold to sink the boat (%)" (181), "Reduce item encumbrance (%)" (183), "Combat vitality regen (additional)" (393), "Out of combat vitality regen (additional)" (394); group "QoL" (441) with "QoL Presets" (447), "Instant sign casting with sign select key" (432); the boat's message "Your over encumbrance is too high" (179); "Mods" (2110992000), the panel's name in 1.32, which 5.x names itself (`panel_mods` is vanilla in 5.x). The game's own texts that touch these options, decoded from 5.x's `en.w3strings` with `w3strings.py` and matched to the settings by name (unverified on screen): 5.x's Gameplay setting "Quick Sign Casting" (1222517 and others) and its tutorial, "You have enabled Quick Sign Casting on your controller. This setting aims to eliminate the need for the Quick Access Menu when casting signs." (1223738, controller buttons only); the Accessibility settings "Vitality Regeneration Boost" (1252440), "Ignore Item Weight" (1446543) and "Unlimited Boat Durability" (1446553).

**What 5.x did in this area** (from `vanilla-5.x` and the game's menu files, unverified in game). The menu framework is the same idea (a mod's menu XML in `bin\config\r4game\user_config_matrix\pc\`, groups under Options → Mods; [development.md](../development.md#options-menu)). 5.x adds settings of its own that meet four of legacy's: **"Quick Sign Casting"** (Gameplay, `EnableAlternateSignCasting`, off by default), which, from the code, also on a keyboard makes a sign-select key cast its sign (`CPlayerInput.OnSelectSign` → `AltCastSign`), keeps a channeled sign going while the key is held (`ShouldStopChanneling`) and aborts it on release: legacy's instant casting, built in; **"Vitality Regeneration Boost"** (Accessibility, `LowHPAutoHealOn` with a threshold and a multiplier), which adds to the value of Geralt's automatic Vitality regeneration (`W3Effect_AutoVitalityRegen.SetEffectValue`: +1 per second above the threshold, up to the multiplier × 1.1 below it), so it only acts while that regeneration runs; **"Ignore Item Weight"** (Accessibility, `WeightlessItems`), which makes no item count for weight (`IsItemEncumbranceItem`): legacy's weight reduction at 100%; **"Unlimited Boat Durability"** (Accessibility, `DisableDurabilityBoat`), which makes boats indestructible (`W3Boat.GetCanBeDestroyed`), and legacy's sinking only sinks a destructible boat. The Accessibility preset "Bard's Ballad: Focus & Rest" turns the last two on (DIFF's [DD3](diff.md#area-decisions) kept 5.x's aids, untuned). Geralt's base Vitality regeneration is 1.32's, 1 per second in and out of combat (`ConGeralt`); `W3Boat.OnAreaEnter`, `GetItemEncumbrance` and the effect manager's regen start (`FilterAutoBuff`) are 1.32's.

**How legacy Ghost Mode implements it.** Data: the menu file `menu/modSignsConfig.xml` (four groups, 37 variables with the hidden `GMVersion`, 9 presets; [inventory](#legacy-options-inventory)); `ConGeralt`'s four Vitality regen nodes set to 0 (`geralt_stats.xml`, regular and NG+); about 60 labels in 9 languages. Scripts: `gm_generic/gm_options.ws` (`gmLoadDefaultSettings`, `gmSetGMVersion`, `gmIsScalingOption`, `gmIsGameplayOption`, `gmIsQoLOption`, `gmModRegenValue`, `gmUpdateRegenEffects`, `gmInstantCastingAllowed` and the stamina cost and delay modifiers); `gm_generic/gm_input.ws` (`TestCastSignHold`, `ForceDeactivateCastSignHold`); the getters in `W3GameParams` (the gameplay and QoL ones cached until `gmResetCachedValuesGameplay` / `gmResetCachedValuesQoL`); `CR4Game.gmUserSettingsScaling`, `gmUserSettingsQuestLevels`, `gmUserSettingsGameplay`, `gmUserSettingsQoL`; `CR4IngameMenu`'s four change flags, set in `OnOptionValueChanged` and `OnPresetApplied` and acted on in `gmUserSettings` from `SaveChangedSettings`; `CR4Player.OnSpawned` (`gmLoadDefaultSettings`); the readers: `W3Effect_AutoVitalityRegen` (`SetEffectValue`, `OnLoad`, `wasLoaded`), `W3EffectManager.FilterAutoBuff`, `AddCharacterStat` (the panel), `W3Boat.OnAreaEnter` and `CheckPlayerEncumbrance`, `CInventoryComponent.GetItemEncumbrance`, `CPlayerInput.OnSelectSign`, `CR4Player.SetCastSignHoldTimestamp` and `castSignHoldTimestamp`, and `TestCastSignHold` in place of the cast key in `OnDelayOrientationChange`, `DelayOrientationChangeTimer`, `W3PlayerWitcher.OnProcessCastingOrientation`, `W3SignOwnerPlayer.ChangeAspect`, `W3SignEntityStateChanneling.ShouldStopChanneling`, and `ForceDeactivateCastSignHold` in `W3Effect_Tangled.OnEffectAdded`. No binary file.

Unit lists: [attribution.csv](attribution.csv): mapped 2026-11-02 from the changelist's sections, the mod description, legacy's menu XML option by option (each against its getter, its readers, `gmLoadDefaultSettings`, the presets and the port's `modGhostMode.xml` and `gmOptions.ws` on 5.x-GM `92548132`), the labels in 9 languages, every hand-off to OPT in the other areas' files (STAM, UI, EFX, FOOD, DIFF, XP, SKL) and in [deviations.md](deviations.md), a script diff of every function legacy changed that reads a setting (`GetInGameConfigWrapper`, `GetVarValue`, `SetVarValue`), and sweeps (`unit_sweep.py --unattributed` for `VitalityRegen`, `vitalityCombatRegen`, `GMVersion`, `InstantCast`, `TestCastSignHold`, `castSignHold`, `GetBoatSink`, `sink`, `too_heavy`, `GetEncumbranceMult`, `ConfigWrapper`, `GetVarValue|SetVarValue`, `preset`). **330 units carry an OPT feature**: 140 newly attributed, OPT added to 20 shared units (the menu file's glob row, STAM-04's `gmModRegenValue`, `gmUpdateRegenEffects` and `FilterAutoBuff`, UI-05's `AddCharacterStat`, `ConGeralt` regular and NG+, ARM-07's `ChangeAspect`, MUT-12's `ShouldStopChanneling`, EFX-10's web, OPT-01's own functions); the rest were OPT-01's already (the framework and the 405 labels the UI sweep gave it, among them the ported options' labels). By feature: OPT-01 192, OPT-02 2, OPT-03 36, OPT-04 38, OPT-05 18, OPT-06 30, OPT-07 51 (a unit can carry several). Unattributed units: 1,115 before, 975 after. Left unattributed, not OPT's: Community Patch – Base's menu units (`IngameMenu_FillArrayFromConfigGroup`, `IngameMenu_GetOptionTypeFromString`, `IngameMenu_FillOptionsSubMenuData`, `CR4IngameMenu.OnConfigUI`, `OnRefresh`, `StartShowingCustomDialogs`, `OnButtonClicked`, `ddd`, `InGameMenuActionType`, `IngameMenuStructureCreator.CreateNewGameListArray`, `CR4MainCreditsMenu.OnCloseMenu`: DEP, 1.32's mod-menu plumbing that 5.x has natively) and the Noonwraith trophy's Vitality regen (`noonwraith_mh308_trophy_stats`, TRPH). Port status: **ported** (2026-11-02): the [area decisions](#area-decisions) DO1 to DO5 and the [porter's calls](#porters-calls) PO1 to PO13 decided by the owner; slices O0 (WGT's three menu entries), O1 (Vitality regeneration, OPT-02 and OPT-03), O2 (presets and order, OPT-07) and O3 (instant casting is 5.x's "Quick Sign Casting", OPT-06) verified on the area build; OPT-04's and OPT-05's mechanics are WGT's (integrated 2026-11-02); **audited** 2026-11-02 ([OPT audit](#opt-audit-2026-11-02): 8 findings, every one fixed, decided or recorded, [close-out](#opt-audit-close-out)); **signed off** by the owner (2026-11-02).

**Size.** Small: OPT-01 with the stamina, scaling and experience options, two Vitality regen options with Geralt's base regeneration (OPT-02, OPT-03), two weight options whose mechanics are WGT's (OPT-04, OPT-05), one input option 5.x already offers in its own way (OPT-06, 5.x's) and the gameplay and QoL presets (OPT-07). About 140 new units, most of them labels.

## Scope

**OPT covers** the menu framework (OPT-01), every legacy option no other area owns (OPT-02 to OPT-06) and the gameplay and QoL presets (OPT-07).

**Already ported by other areas** (through OPT-01's framework; nothing left for OPT but the presets):

| Options | Ported by | State |
|---|---|---|
| Sign cooldown, alternate sign cooldown | STAM-01 | signed off |
| Melee special cooldown | STAM-02 | signed off |
| Sprint/jump, melee and sign action cost modifiers | STAM-03 | signed off |
| Combat and out-of-combat stamina regen | STAM-04 | signed off |
| Stamina regen penalty for armors | STAM-05 | signed off |
| Stamina regen delay | STAM-06 | signed off |
| The five low-stamina sound options, the QoL group's restart on change | STAM-07 | signed off |
| The "Enemy scaling" group: scaling type, random bounds, progressive bonuses and deltas, guards, animals, the four health and damage modifiers, its three presets ("Recommended", "Hardcore", "Off"), the re-levelling on change; the port's "Interpolated" type and "Ciri's sections: difficulty" | DIFF-04, DIFF-09, DIFF-10 | signed off |
| The "Experience" group: its four options, the "Default" preset, the quest-level reload on change | XP-07 | signed off |
| The skill tree toggle (`GMClassicSkillTree`, new in the port, first in the gameplay group) | SKL-02 | signed off |

**Not OPT:**

| Subject | Area | Why |
|---|---|---|
| Over-encumbrance itself: the effect, its stamina cost penalty, no fast travel or galloping, the carry limits, every item's weight, `GetItemEncumbrance`'s full-weight rule (1.32 counted quest items, keys and some categories at a fraction) | WGT | Weight; OPT-04 and OPT-05 only add the options on top (shared units) |
| Community Patch – Base's menu plumbing (the "BUTTON" option type, the main menu's mod groups, the expansion dialogs) | DEP | A dependency; 5.x has its own Mods menu |
| The Noonwraith trophy's +5 Vitality regen | TRPH | The trophies' rework |
| 5.x's accessibility aids ("Vitality Regeneration Boost", "Ignore Item Weight", "Unlimited Boat Durability") | DIFF (DD3) | Kept by the owner, untuned; OPT records how they meet OPT-03 to OPT-05 |

## Legacy options inventory

Every variable of legacy's menu, with its type (`SLIDER;min;max;steps`), its value with the menu never touched (legacy's code: `gmLoadDefaultSettings` writes the gameplay group's once, when `GMVersion` is empty; every other unset option reads as 0 or off), its three presets' values where it has them, the code that reads it, and where it stands on 5.x-GM `92548132` (`modGhostMode/menu/modGhostMode.xml`, defaults in `scripts/local/gm/options/gmOptions.ws`).

**Gameplay** (`GMGameplayOptions`; presets "Recommended" / "Vanilla(ish)" / "Off"):

| Option (label) | Variable, type | Untouched (legacy) | Presets R / V / O | Read by (legacy) | 5.x-GM |
|---|---|---|---|---|---|
| Sink the boat if over encumbered | `GMSinkBoat`, toggle | on | on / off / off | `W3Boat.OnAreaEnter` (`GetBoatSinkOption`) | entry and default on (slice O0); the sinking: WGT-10 |
| Over encumbrance threshold to sink the boat (%) | `GMSinkBoatOverEnc`, 0–100 | 20 | 20 / 0 / 0 | `W3Boat.CheckPlayerEncumbrance` | entry and default 20 (slice O0); the sinking: WGT-10 |
| Reduce item encumbrance (%) | `GMEncumbranceMultiplier`, 0–100 | 0 | 0 / 0 / 0 | `CInventoryComponent.GetItemEncumbrance` (`GetEncumbranceMult`, ÷100) | entry and default 0 (slice O0); the reduction: WGT-02 |
| Enable stamina regen penalty for armors | `GMArmorRegenPenalty`, toggle | off | off / on / off | `IsArmorRegenPenaltyEnabled` (regen, panel, tooltips) | STAM-05, default off |
| Combat stamina regen (additional) | `GMCombatStaminaRegen`, −15–85 | 0 | 0 / −5 / 0 | `gmModRegenValue` | STAM-04, default 0 |
| Out of combat stamina regen (additional) | `GMOutOfCombatStaminaRegen`, −100–0 | 0 | 0 / 0 / 0 | `gmModRegenValue` | STAM-04, default 0 |
| Combat vitality regen (additional) | `GMCombatVitalityRegen`, 0–1000 | 0 | 0 / 1 / 0 | `gmModRegenValue` (regen effect, its start, the panel) | OPT-03 (slice O1), default 0 |
| Out of combat vitality regen (additional) | `GMOutOfCombatVitalityRegen`, 0–1000 | 0 | 0 / 1 / 0 | `gmModRegenValue` | OPT-03 (slice O1), default 0 |
| Sprint/jump action cost modifier | `GMAgilityStaminaCostMultiplier`, −1–5 (60) | 0 (not written; unset reads 0) | 0 / 0 / 0 | `gmModAgilityStaminaCost` | STAM-03, default 0 |
| Melee action cost modifier | `GMMeleeStaminaCostMultiplier`, −1–5 (60) | 0 | 0 / −1 / 0 | `gmModMeleeStaminaCost` | STAM-03, default 0 |
| Sign action cost modifier | `GMSignStaminaCostMultiplier`, −1–3 (40) | 0 | 0 / 1.5 / 0 | `gmModSignStaminaCost` | STAM-03, default 0 |
| Stamina regen delay (additional, seconds) | `GMStaminaDelay`, −1–5 (60) | 0 | 0 / 0 / 0 | `gmModStaminaDelay` | STAM-06, default 0 |
| Melee special cooldown (seconds) | `GMMeleeSpecialCooldown`, 0–30 (60) | 7.5 | 7.5 / 0 / 0 | `GetMeleeSpecialCooldownDuration` | STAM-02, default 7.5 |
| Sign cooldown (seconds) | `GMSignCooldown`, 0–30 (60) | 5 | 5 / 0 / 0 | `GetSignCooldownDuration` | STAM-01, default 5 |
| Alternate Sign cooldown (seconds) | `GMAltSignCooldown`, 0–30 (60) | 7.5 | 7.5 / 0 / 0 | `GetAltSignCooldownDuration` | STAM-01, default 7.5 |
| (hidden) | `GMVersion`, `hideAlways` | 4.0 (always rewritten) | 4.0 / 4.0 / 4.0 | `gmLoadDefaultSettings` (empty: write the defaults); `GetGMVersion` has no caller | not ported (PO2) |

**QoL** (`GMQOLOptions`; presets "Recommended" / "Off"):

| Option (label) | Variable, type | Untouched (legacy) | Presets R / O | Read by (legacy) | 5.x-GM |
|---|---|---|---|---|---|
| Instant sign casting with sign select key | `GMSignInstantCast`, toggle | off | on / off | `gmInstantCastingAllowed` (`OnSelectSign`, `TestCastSignHold`) | not ported: OPT-06 |
| Low stamina sfx threshold (percents) | `GMLowStaminaSFX`, 0–100 | 0 (no heartbeat) | 50 / 0 | `CheckForLowStamina` | STAM-07, default 50 ([DO4](#area-decisions)) |
| Low stamina sfx volume | `GMLowStaminaSFXVolume`, 0–100 | 0 | 100 / 0 | `CheckForLowStamina` | STAM-07, default 100 |
| Use dynamic low stamina sfx volume | `GMLowStaminaSFXDynamicVolume`, toggle | off | on / off | the regen's sound update | STAM-07, default on |
| Low stamina sfx rate | `GMLowStaminaSFXRate`, 0–100 | 0 | 0 / 0 | `CheckForLowStamina` | STAM-07, default 0 |
| Use dynamic low stamina sfx rate | `GMLowStaminaSFXDynamicRate`, toggle | off | on / off | the regen's sound update | STAM-07, default on |

**Enemy scaling** (`GMScalingOptions`, 12 variables, presets "Recommended", "Hardcore", "Off") and **Experience** (`GMExpOptions`, 4 variables, preset "Default"): all ported with their presets and labels by DIFF-04 and XP-07; the inventory is in [diff.md](diff.md#diff-04-enemy-scaling-options) and [xp.md](xp.md#xp-07-experience-options). With the menu untouched the scaling group plays the "Recommended" preset in the port (DD1, a deviation), the experience group as legacy.

The port's groups today: "Enemy scaling" and "Experience" complete with presets; "Gameplay" with the skill tree toggle, WGT's three options (slice O0: boat sinking, its threshold, item weight reduction; their mechanics are WGT's), the 11 stamina options and the 2 Vitality options (slice O1), in legacy's order, with legacy's three presets (slice O2); "QoL" with the five heartbeat options and legacy's two presets (slice O2). `GMSignInstantCast` is not ported (DO5).

## Changes at a glance

### What Ghost Mode changed

| # | Feature | Vanilla 1.32 (and 5.x) | Legacy GM | Units (main) |
|---|---|---|---|---|
| OPT-01 | Options framework | No mod menu (1.32); 5.x: Options → Mods | Four groups with presets, defaults written at the first load, cached getters re-read when the menu closes | menu XML, 14 script units, about 170 label rows |
| OPT-02 | Geralt's base Vitality regen | 1 per second in and out of combat | 0 in and out of combat ("Default health regen for Geralt in and out of combat is now zero") | `ConGeralt` (regular, NG+) |
| OPT-03 | Vitality regen options | — | "Combat / Out of combat vitality regen (additional)", 0 to 1000 per second, default 0 | 9 script units, 18 labels |
| OPT-04 | Boat sinking | — | Boarding a boat while over-encumbered by more than 20% of the carry limit sinks it ("Your over encumbrance is too high"); on by default; toggle and threshold | 4 script units, 27 label rows |
| OPT-05 | Item weight reduction | — | Every item's weight × (1 − the option), 0 to 100%, default 0 | 2 script units, 9 labels |
| OPT-06 | Instant sign casting | Select keys only select a sign; casting is a separate key | A select key also casts its sign; held over 0.2 s it is the cast key held (alternate cast, channelling); off unless chosen | 10 script units, 9 labels |
| OPT-07 | Gameplay and QoL presets | — | "Recommended", "Vanilla(ish)", "Off" (gameplay); "Recommended", "Off" (QoL) | the menu's preset arrays, 45 label rows |

### What 5.x changed

| # | 5.x change (from code and data) |
|---|---|
| OPT-01 | The Mods menu built in (`panel_mods`, `Mods.<name>` groups); 5.x's `CR4IngameMenu` rewritten (the port wraps it) |
| OPT-02 | None (1/s, 1.32's) |
| OPT-03 | "Vitality Regeneration Boost" adds to the same regen effect, only while it runs |
| OPT-04 | "Unlimited Boat Durability" makes boats indestructible (and unsinkable by legacy's rule) |
| OPT-05 | "Ignore Item Weight" makes every item weightless |
| OPT-06 | "Quick Sign Casting": select keys cast, hold to channel, release to abort (also on a keyboard, from the code) |
| OPT-07 | None |

### Classification and proposed action

| # | Feature | Class | Proposed action |
|---|---|---|---|
| OPT-01 | Options framework | clean | Ported; finish with OPT-07's preset hooks and a gameplay change hook (PO2, PO4) |
| OPT-02 | Base Vitality regen 0 | clean | Legacy's (PO4) |
| OPT-03 | Vitality regen options | overlap | Legacy's options (PO4, PO5); 5.x's boost: DO1; the combat option alone: DO2 |
| OPT-04 | Boat sinking | clean | Legacy's, after WGT's over-encumbrance (PO6); its default: DO3 |
| OPT-05 | Item weight reduction | overlap | Legacy's slider next to 5.x's aid, with WGT's weights (PO7, PO12) |
| OPT-06 | Instant sign casting | overlap | DO5 (recommended: 5.x's "Quick Sign Casting") |
| OPT-07 | Presets | clean | Legacy's (PO8); the QoL defaults: DO4 |

---

### OPT-01 Ghost Mode options framework

| | |
|---|---|
| Kind | infra |
| Pillars | P8 |
| 5.x class | clean |
| Flags | — |
| Depends on | — |
| Skill trees | n/a |
| Port form | menu XML (`modGhostMode/menu/modGhostMode.xml`, legacy's group and variable ids); option labels in the string tables with legacy's ids; `scripts/local/gm/options/gmOptions.ws`: `GMOptionDefault` and `GMOptionList` (per-option defaults), `GMApplyDefaultOptions` from a `@wrapMethod` on `CR4Player.OnSpawned`, the live getters `GMGetOptionFloat` and `GMGetOptionBool`; the change hooks: `@wrapMethod(CR4IngameMenu)` `OnOptionValueChanged`, `OnPresetApplied` and `SaveChangedSettings` with a flag per kind of change (QoL, scaling, Ciri's difficulty, quest levels, and the gameplay flag of OPT-03, which restarts Geralt's Vitality regen) |
| Port status | **ported**; **signed off** (2026-11-02): the four groups with every option (gameplay: the skill tree toggle and STAM-01 to STAM-06's eleven; QoL: STAM-07's five; DIFF's scaling group and XP's experience group complete with presets), labels in 9 languages, per-option defaults, the QoL, scaling, Ciri and quest-level change hooks; WGT's three entries (OPT-04, OPT-05) in legacy's place since slice O0; the Vitality options and the gameplay change hook (OPT-03) since slice O1; the presets (OPT-07) and legacy's order of the gameplay group (PO3) since slice O2 |
| Open checks | — |
| Save impact | none (options in the user settings) |
| NG+ counterpart | none |
| Verified in game | partly: 5.0 hotfix, 2026-10-02, `gmtest_opt01()` (group registered and visible, labels, defaults written to `dx12user.settings`, a changed option changes the STAM-01 cooldown, 0 turns it off) and a screenshot of Options → Mods → Ghost Mode → Gameplay; the scaling and experience groups through the menu's code path (DIFF-04, XP-07) and on screen with real input (the [cleared run](xp.md#cleared-run-on-screen-2026-11-01), 2026-11-01) |

**What it does:** Options → Mods → Ghost Mode with four groups: "Enemy scaling", "Experience", "Gameplay" (stamina, regen, cooldowns, weight, boat sinking; the port adds the skill tree toggle) and "QoL" (instant sign casting, low-stamina sound). Each group has presets. Options the player never set get Ghost Mode's defaults when a save loads. A changed option takes effect when the menu closes (the game is paused while it is open): the scaling group re-levels the NPCs around Geralt, "Disable quest levels" clears or reloads the quest levels, the QoL group restarts the heartbeat, the gameplay group (legacy) restarts Geralt's regen effects.

**Implementation (legacy):** `menu/modSignsConfig.xml` (groups `GMScalingOptions`, `GMExpOptions`, `GMGameplayOptions`, `GMQOLOptions`); `gm_generic/gm_options.ws` (`gmLoadDefaultSettings`, `gmSetGMVersion`, `gmIs*Option`); the getters in `W3GameParams` (scaling and experience read live; gameplay and QoL cached in fields, reset by `gmResetCachedValuesGameplay` and `gmResetCachedValuesQoL`); `CR4Game.gmUserSettingsScaling`, `gmUserSettingsQuestLevels`, `gmUserSettingsGameplay` (cache reset and `gmUpdateRegenEffects`), `gmUserSettingsQoL` (cache reset and the heartbeat restart); `CR4IngameMenu`: four flags (`gmHasChangedScalingOption`, `…QuestLevelsOption`, `…GameplayOption`, `…QoLOption`) set in `OnOptionValueChanged` (by `gmIs*Option`; the scaling group's id test there never matches, legacy's own comment) and `OnPresetApplied` (by group), acted on in `gmUserSettings`, called by `SaveChangedSettings` before `SaveUserSettings`; `CR4Player.OnSpawned` calls `gmLoadDefaultSettings`, which writes the gameplay group's defaults (the boat 20% on, weight 0, stamina and Vitality options 0, cooldowns 7.5, 5 and 7.5) only when `GMVersion` is empty, then sets `GMVersion` to "4.0". `GetGMVersion` has no caller. Labels: about 60 strings per language (`panel_*`, `option_*`, `preset_*`, `preset_value_*`), the panel name "Mods" among them.

**5.x:** pilot slice 5 verified that 5.x loads a mod's menu XML from `bin\config\r4game\user_config_matrix\pc\`, places `Mods.<name>` groups under Options → Mods (whose label `panel_mods` is 5.x's own), and that an unset option reads as `""` (a virtual `OPTIONS` variable as `"-1"`, DIFF-04). See [development.md](../development.md#options-menu). 5.x's `CR4IngameMenu` was rewritten (accessibility presets, new settings), so legacy's edits of its methods are ported as wrappers.

**Decisions:** port as is, with the menu file renamed to Ghost Mode's own name (`modGhostMode.xml`). Group and variable ids, label keys and string ids stay as in legacy, so existing translations carry over. Defaults are applied **per option** (any unset option gets its default when a save loads) instead of legacy's one-time `GMVersion` check, so options added by later features get their defaults on existing installs too; the getters fall back to the default while an option is empty. Options appear in the menu only once their feature is ported. The getters read the settings live (legacy cached the gameplay and QoL ones until the menu closed): the same values in play, so not a deviation. The rest (PO2, PO3): `GMVersion` and its two functions are not ported; nor is the "Mods" label 2110992000 (5.x's `panel_mods`).

- Not a deviation: with the menu never opened the port gives the gameplay group legacy's defaults, as legacy's code did. The scaling group's "Recommended" values (DD1) and the QoL group's (DO4) are recorded by DIFF-04 and at DO4.

**Slices (done):** the pilot's gameplay group (2026-10-02, `gmtest_opt01`, scripted, and a screenshot); each later group with its feature (STAM-07's QoL group 2026-10-03, DIFF-04's scaling group 2026-10-30, XP-07's experience group 2026-10-31, SKL-02's toggle 2026-10-17); their verification is in those entries; OPT's own slices O0 to O3 in the [port order](#port-order).

---

### OPT-02 Geralt's base Vitality regeneration

| | |
|---|---|
| Kind | tuning |
| Pillars | P2 (with the regen options of OPT-03, P8) |
| 5.x class | clean |
| Flags | balance |
| Depends on | FOOD-03 (food raises Geralt's own regen and restarts it), OPT-03 (the options that let a player add regen back) |
| Skill trees | n/a |
| Port form | the DLC's `gm_stats.xml`: an `extend` of `ConGeralt` with the four Vitality regen nodes (`vitalityRegen` and `vitalityCombatRegen`, `add` and `mult`) at 0, listed in vanilla's order (repeated tags are replaced in order, as STAM-04's stamina nodes); the NG+ copy by `gen_ngplus.py` with legacy's 0 (legacy's NG+ file has 0) |
| Port status | ported (slice O1): **verified on the area build** (2026-11-02): scripted, see the [port order](#port-order)'s O1 row |
| Open checks | — |
| Save impact | none (expected: a base ability, read live) |
| NG+ counterpart | applied (0, legacy's NG+ value), untested |

**What it does** (changelist 474, "General player abilities"): Geralt no longer heals over time by himself, in or out of combat. Only food and drink, potions (Swallow), decoctions, skills, set bonuses, runewords, trophies and the OPT-03 options give him regeneration. Example: Geralt at level 20 (4,450 Vitality) who lost 1,000 in a fight gets nothing back by waiting; in 1.32 and 5.x he regains 1 per second, all of it in about 17 minutes. With a Bread eaten, or with OPT-03's out-of-combat option at 10, he does regenerate.

**Implementation (legacy):** `geralt_stats.xml` `ConGeralt`: `vitalityRegen` add 1 → 0, `vitalityCombatRegen` add 1 → 0 (the `mult` nodes already 0), regular and NG+. With every source at 0 the effect manager adds no automatic Vitality regeneration at all (`FilterAutoBuff` finds a null value); an ability that brings a regen stat starts it (legacy's `OnAbilityChanged`, FOOD-03's port).

**5.x:** 1.32's `ConGeralt` (1 and 1). The port has legacy's 0/s since slice O1 (`gm_stats.xml`), which FOOD-03's code comment assumes. 5.x's "Vitality Regeneration Boost" only acts while this regeneration runs, so the 0 meets it: [DO1](#area-decisions).

**Decisions:** legacy's (PO4). The changelist puts the line under "General player abilities"; no GEN area file exists, and the base value and the options (OPT-03) only make sense together, so OPT takes it (shared with GEN).

---

**Fix round fix3 (2026-11-02, sweep D G8 and Q3; the owner's decision): Geralt has no natural poison or bleeding resistance**, as legacy's data (`ConGeralt`'s `poison_resistance_perc` and `bleeding_resistance_perc` 0.25 → 0, regular and NG+; the changelist does not mention it, recorded in [open-questions.md](../open-questions.md#legacy-data-vs-changelist)): a fifth `ConGeralt` extend in `gm_stats.xml` (NG+ copy by `gen_ngplus.py`). Put here because OPT-02 is the entry for Geralt's base stats (no GEN area file exists). **verified on the area build** (2026-11-02, gm/fix3 `51bce9eb`, both trees): `GMTest_opt02_resist` (regression, the definition read): 0 and 0, `ConGeralt`'s stamina regen kept; it failed first on a throwaway build with b3ec3609's code and data (gm/fix3-ff `efa40f24`, classic tree; the code checks also in the new tree) (0.25, 0.25).


### OPT-03 Vitality regen options

| | |
|---|---|
| Kind | system |
| Pillars | P8 |
| 5.x class | overlap (5.x's "Vitality Regeneration Boost" adds to the same effect) |
| Flags | needs-decision |
| Depends on | OPT-01 (the menu), OPT-02 (base 0), FOOD-03 (the regen restart), ENCH-05 (the port's `W3Effect_AutoVitalityRegen.OnUpdate` wrapper), UI-05 (the panel lines) |
| Skill trees | n/a |
| Port form | the two options in the gameplay group (legacy's ids, `SLIDER;0;1000;1000`, after the stamina regen options as legacy) with defaults 0 and labels 2110992393, 394; `@wrapMethod(W3Effect_AutoVitalityRegen)` `SetEffectValue` adding the option for the regen in force (after 5.x's body, so 5.x's boost stays in it); the regen start: the options count when the effect manager decides whether Geralt has a Vitality regen (legacy's `FilterAutoBuff` edit; the method is private, so the slice finds the hook: a wrapper of `CActor.StartVitalityRegen` or of the manager's start, adding the effect when an option is above 0); a gameplay change flag in OPT's menu wrappers calling legacy's `gmUpdateRegenEffects` (update the running effect, start it if absent); UI-05's `GMPanelVitalityRegen` adds the option (ends UI-05's temporary deviation); in `options/gmOptions.ws` and a new `options/vitalityRegen.ws` |
| Port status | ported (slice O1): **verified on the area build** (2026-11-02): scripted, see the [port order](#port-order)'s O1 row |
| Open checks | — |
| Save impact | none (options in the user settings) |
| NG+ counterpart | none |

**What it does** (changelist 1235–1236): "Combat vitality regen (additional)" and "Out of combat vitality regen (additional)" add 0 to 1000 Vitality per second to Geralt's regeneration in or out of combat; both 0 by default (and in "Recommended" and "Off"), 1 each in "Vanilla(ish)", which gives back 1.32's 1 per second. They act at once when the menu closes. The character panel's two regen lines include them. Example: out of combat at 10 and nothing else, Geralt at 3,450 of 4,450 is full in 100 seconds; in combat at 5 with a Swallow (+40, ALCH) he regains 45 per second.

**Implementation (legacy):** `gmModRegenValue` adds `GetOutOfCombatVitalityRegen` to `vitalityRegen` and `GetCombatVitalityRegen` to `vitalityCombatRegen`; it is called in `W3Effect_AutoVitalityRegen.SetEffectValue` (Geralt only), in `W3EffectManager.FilterAutoBuff` (whether the automatic regen may start: it reads `vitalityRegen`, the out-of-combat stat, only) and in `AddCharacterStat`'s two Vitality regen lines; `gmUpdateRegenEffects` (from `gmUserSettingsGameplay`) updates the running regen effects and starts them when absent; `W3Effect_AutoVitalityRegen`'s `wasLoaded` (set in `OnLoad`) recomputes the value at the first update after a load.

**5.x:** no such options. 5.x's `W3Effect_AutoVitalityRegen` recomputes Geralt's value on every update (so `wasLoaded` has nothing to add) and adds the "Vitality Regeneration Boost" when that aid is on: +1 per second above its threshold, up to (1.1 × its multiplier) below it, while the effect runs.

**Decisions:** legacy's (PO4, PO5); the boost with Geralt's base 0: DO1 (b), switching the boost on also starts the regen (not a deviation: legacy had no such aid). Port (slice O1): the options in the gameplay group after the stamina regen options (legacy's place), labels 2110992393 and 394 in 9 languages; `options/vitalityRegen.ws`: `@wrapMethod(W3Effect_AutoVitalityRegen)` `SetEffectValue` adds the option for the regen in force after 5.x's value (5.x's boost stays in it); `@wrapMethod(W3EffectManager)` `StartVitalityRegen`: when 5.x starts no regen (Geralt has no regen stat), the effect is added as 5.x's own start adds it (`InternalAddEffect`, the manager's flag set) if either option is above 0 or the boost is on; the gameplay change hook (`gmVitalityRegenChanged` in `gmOptions.ws`'s menu wrappers: either option, the boost's switch, 5.x's accessibility preset, a gameplay preset) starts the regen when the menu closes (a running one recomputes its value each update in 5.x, so legacy's value refresh is not needed); UI-05's `GMPanelVitalityRegen` adds the option, which ended UI-05's temporary deviation. Regen is still Geralt's only (`W3PlayerWitcher`), as legacy's `gmModRegenValue`. Since the [audit](#opt-audit-2026-11-02)'s F1 the start also counts Geralt's own combat regen (the Tvarog rune).
- **Deviation:** Geralt's Vitality regen starts when either Vitality option is above 0; legacy's start read only the out-of-combat value, so "Combat vitality regen" alone gave nothing unless food or a potion had started the regen. A fix, so that the option works as its label says (owner, DO2, 2026-11-02).
- **Deviation:** Geralt's Vitality regen also starts when his own combat Vitality regen is above 0, so the Tvarog rune's +5 per second in combat (ENCH-16, the only source with a combat value and no out-of-combat one) works on its own, as its tooltip and the character panel say; with legacy's start rule and base 0 it gave nothing unless food, a potion or the out-of-combat option had started the regen. DO2's fix extended (`GMVitalityRegenStarts` in `options/vitalityRegen.ws`, read by the start wrapper and the keep-on test; OPT audit F1) (owner, 2026-11-02).

---

### OPT-04 Boat sinking

| | |
|---|---|
| Kind | system |
| Pillars | P6 (weight limits matter), P8 |
| 5.x class | clean |
| Flags | — |
| Depends on | OPT-01, WGT (over-encumbrance: the `OverEncumbered` effect and the run carry limit) |
| Skill trees | n/a |
| Port form | OPT's part (slice O0): the toggle `GMSinkBoat` and the threshold slider `GMSinkBoatOverEnc` (`SLIDER;0;100;100`) in the gameplay group, first after the port's skill tree toggle as legacy, defaults on and 20 (DO3) in `GMOptionDefault`, labels 2110992180 and 181 in 9 languages. WGT's part (WGT-10): the single `@replaceMethod(W3Boat)` `OnAreaEnter` with legacy's sinking branch, `CheckPlayerEncumbrance` and the message 2110992179 |
| Port status | ported: the entries **verified** (slice O0, 2026-11-02, `GMTest_opt_o0` in the regression: place in the group, type, label = string id, default, value written at the load, the getters); the sinking is WGT's (WGT-10, its slice W6, integrated 2026-11-02 and checked through these entries: `GMTest_wgt06`) |
| Open checks | — |
| Save impact | none (expected) |
| NG+ counterpart | none |

**What it does** (changelist 934–935, 1229–1232): when Geralt steps onto a boat while over-encumbered by more than the threshold (20% of his run carry limit by default), the boat sinks under him: its drowning starts, the sinking sound plays and the HUD says "Your over encumbrance is too high". Under the threshold, or with the option off, he boards as usual. Example: with a carry limit of 100, Geralt at 125 sinks the boat, at 115 he boards it (over-encumbered, with WGT's penalties). Not while a save is loading, and not for a boat that cannot be destroyed (its `canBeDestroyed` off; with 5.x's "Unlimited Boat Durability", every boat).

**Implementation (legacy):** `W3Boat.OnAreaEnter`, the `OnBoatTrigger` branch: if the option is on, the boat has its component, no load is in progress (`GetLoadGameProgress() == 0`), the boat can be destroyed and `CheckPlayerEncumbrance` holds, `TriggerDrowning` at Geralt's position, `SetHasDrowned(true)`, `SoundEvent("boat_sinking")` and `DisplayHudMessage("gm_geralt_too_heavy")`; else the vanilla interactions. `CheckPlayerEncumbrance`: Geralt has `EET_OverEncumbered` and (weight ÷ run limit − 1), clamped to 0…1, × 100 is above the threshold.

**5.x:** `OnAreaEnter` is 1.32's; `GetCanBeDestroyed` also reads "Unlimited Boat Durability" (DIFF's DD3 keeps it). The over-encumbrance effect and limits are WGT's to map.

**Decisions:** legacy's (PO6); the default: DO3 (on at 20%). The mechanics are WGT's (the parent's split of 2026-11-02); OPT owns the entries.

---

### OPT-05 Item weight reduction

| | |
|---|---|
| Kind | tuning |
| Pillars | P8 |
| 5.x class | overlap (5.x's "Ignore Item Weight" is the 100% case) |
| Flags | — |
| Depends on | OPT-01, WGT (`GetItemEncumbrance`'s rule and the item weights) |
| Skill trees | n/a |
| Port form | OPT's part (slice O0): the slider `GMEncumbranceMultiplier` (`SLIDER;0;100;100`) in the gameplay group after the boat options, default 0, label 2110992183 in 9 languages. WGT's part (WGT-02): the factor inside the single `@replaceMethod` of `CInventoryComponent.GetItemEncumbrance` (legacy's body: weight at least 0.01, × quantity × (1 − option ÷ 100), under 0.01 counts 0) |
| Port status | ported: the entry **verified** (slice O0, 2026-11-02, as OPT-04's); the reduction is WGT's (WGT-02, its slice W4, integrated 2026-11-02 and checked through this entry: `GMTest_wgt04`) |
| Open checks | — |
| Save impact | none (expected; the weight is recomputed when the inventory changes) |
| NG+ counterpart | none |

**What it does** (changelist 1233): every item Geralt carries weighs (100 − the option)% of its weight; 0 by default and in all three presets. Example: at 30% a 10-weight armor counts 7 and a stack of 20 herbs at 0.1 counts 1.4; at 100% nothing weighs anything (5.x's "Ignore Item Weight" gives the same).

**Implementation (legacy):** `GetEncumbranceMult` (the option ÷ 100, clamped 0…1); `GetItemEncumbrance`: for an item that counts (`IsItemEncumbranceItem`), max(weight, 0.01) × quantity × (1 − factor), 0 below 0.01; legacy also dropped 1.32's category rules there (quest items and keys at 0.01, usable items, upgrades and junk at a fifth, the rest at half, plus 0.01) and added a debug fact (`modSigns_debug_zero_enc`): WGT's.

**5.x:** `GetItemEncumbrance` is 1.32's; "Ignore Item Weight" returns early in `IsItemEncumbranceItem` and `GetEncumbrance`, so with it on the option has nothing to act on.

**Decisions:** legacy's slider next to 5.x's aid (PO7, PO12). The factor is WGT's (the parent's split of 2026-11-02); OPT owns the entry.

---

### OPT-06 Instant sign casting

| | |
|---|---|
| Kind | system |
| Pillars | P8 |
| 5.x class | overlap (5.x's "Quick Sign Casting") |
| Flags | needs-decision |
| Depends on | OPT-01, STAM-01 (the cooldown check on `OnCastSign` and on 5.x's `AltCastSign`), ARM-07 (the port's `W3SignOwnerPlayer.ChangeAspect`, `armor/gryphonSet.ws`), MUT-12 (`ShouldStopChanneling`), EFX-10 (the web's key release) |
| Skill trees | n/a (signs of both trees alike) |
| Port form | by DO5: (a) none in the menu; EFX-10's web also releases the five sign-select keys while 5.x's "Quick Sign Casting" is on (PO13); (b) the toggle in the QoL group with legacy's code: `@wrapMethod(CPlayerInput)` `OnSelectSign`, the timestamp field on `CR4Player`, `TestCastSignHold` in the six places legacy reads it (three of them in methods the port already replaces), `ForceDeactivateCastSignHold` in EFX-10's web |
| Port status | ported (slice O3): **verified on the area build** (2026-11-02), scripted, see the [port order](#port-order)'s O3 row |
| Open checks | on screen with real keys in a cleared run: a select key's cast, the hold (an alternate cast, a channel kept going and aborted on release), a web during a held channel |
| Save impact | none |
| NG+ counterpart | none |

**What it does** (changelist 1246–1247): with the option on, pressing a sign's select key (3 to 7 by default) selects the sign and casts it at once (refused while it is on cooldown, STAM-01); keeping the key held for more than 0.2 s counts as holding the cast key: the alternate cast where a skill allows it, and a channeled sign (Firestream, the active Quen shield, Puppet) keeps going until the key is released. Off unless the player turns it on or applies the QoL "Recommended" preset. Example: with Igni selected, pressing Aard's select key throws an Aard; holding it casts the alternate Aard (Aard Sweep).

**Implementation (legacy):** `CPlayerInput.OnSelectSign` (after setting the sign: if the option is on, the press time stored by `SetCastSignHoldTimestamp` and `CastSign()`, STAM-01's cooldown check included); `TestCastSignHold` (the cast key held, or with the option a select key pressed for more than 0.2 s) in place of `GetActionValue('CastSignHold')` in `W3SignOwnerPlayer.ChangeAspect` (the alternate cast), `W3SignEntityStateChanneling.ShouldStopChanneling`, `W3PlayerWitcher.OnProcessCastingOrientation` (three places), `CR4Player.OnDelayOrientationChange` and `DelayOrientationChangeTimer`; `ForceDeactivateCastSignHold` (the cast key and the five select keys) in the spider web (`W3Effect_Tangled.OnEffectAdded`, EFX-10). The timer's test is inverted: legacy put `TestCastSignHold()` where 1.32 tested "the cast key is released", so the delayed turning during a sign cast ends while the key is still held instead of on its release, with or without the option (from the code; how it played: the [legacy test list](../open-questions.md#to-test-in-legacy-ghost-mode)).

**5.x:** "Quick Sign Casting" (Gameplay, `EnableAlternateSignCasting`, off by default) does the same on a keyboard, from the code: `OnSelectSign` calls `AltCastSign` (refused without stamina or with the sign blocked; STAM-01 already wraps it with the cooldown check), `ShouldStopChanneling` keeps a channel going while a select key is held, releasing it aborts the channel (`OnSelectSign`), and `ChangeAspect`'s keyboard branch reads the select keys for the alternate cast. Its tutorial speaks of a controller only; how its hold works on a keyboard (the threshold) is not read and not seen. Porting legacy's toggle too would put two systems on the same keys.

**Decisions:** DO5 (a), owner 2026-11-02: 5.x's "Quick Sign Casting" serves as instant casting; legacy's toggle, its input code (`TestCastSignHold`, the press timestamp, `ForceDeactivateCastSignHold` in its own form) and its QoL preset entry are not ported. Port (slice O3): `options/instantCasting.ws`, a second `@wrapMethod(W3Effect_Tangled)` `OnEffectAdded` (after EFX-10's abort) that releases the five sign-select keys while 5.x's setting is on (PO13, `GMWebReleaseSignSelectKeys`), which closes EFX-10's PX9 item; STAM-01's cooldown check already sits on 5.x's `AltCastSign`.
- **Deviation:** legacy's "Instant sign casting with sign select key" (a QoL toggle, on in the QoL "Recommended" preset) is not ported; 5.x's own "Quick Sign Casting" (Options → Gameplay, off by default) gives the same: a select key casts its sign, holding it keeps a channeled sign going, releasing it aborts the channel. It differs in that the setting lives in 5.x's Gameplay settings under 5.x's name, Ghost Mode's QoL presets do not switch it, the alternate cast comes from 5.x's hold rule instead of legacy's 0.2 s, a select-key press refused for the sign's cooldown or for stamina keeps the old sign (legacy selected the sign first, so the cast key would then cast it), and legacy's inverted orientation timer does not come with it (owner, DO5, 2026-11-02; the refused press added from the OPT audit's F5, 2026-11-02).
- **Deviation:** legacy's inverted turning during a held sign cast is not ported, for every player, with or without instant casting: legacy's `DelayOrientationChangeTimer` read `TestCastSignHold()` where 1.32 tested the cast key's release, so Geralt's delayed turning toward the aim ended while the cast key was still held instead of when it was released; the port keeps 1.32's and 5.x's turning (a defect of legacy's, not a rule; OPT audit F4) (owner, 2026-11-02).

---

### OPT-07 Gameplay and QoL presets

| | |
|---|---|
| Kind | ui, infra |
| Pillars | P8 |
| 5.x class | clean |
| Flags | — |
| Depends on | OPT-01, OPT-03 (the Vitality options "Vanilla(ish)" sets), OPT-04, OPT-05 (their options), DO5 |
| Skill trees | n/a |
| Port form | `<PresetsArray>` in the gameplay group ("Recommended", "Vanilla(ish)", "Off") and the QoL group ("Recommended", "Off") with legacy's values for the options the port has, without `GMVersion` (PO2) and without the port's new options (PO8); labels 2110992447, 450, 459 in 9 languages (448 and 449 are in already, DIFF-04); `OnPresetApplied`'s wrapper sets the gameplay flag (OPT-03) and the QoL flag (the heartbeat restart, already in `GMOnQoLOptionsChanged`) |
| Port status | ported (slice O2): **verified on the area build** (2026-11-02), scripted, see the [port order](#port-order)'s O2 row |
| Open checks | the menu on screen (the order, the preset labels), in a cleared run |
| Save impact | none |
| NG+ counterpart | none |

**What it does** (changelist 1226–1228, 1245): one choice sets a whole group. Gameplay "Recommended": boat sinking on at 20%, no weight reduction, no armor regen penalty, regen and cost options 0, cooldowns 7.5 (Whirl and Rend), 5 (signs) and 7.5 (alternate signs): Ghost Mode as designed. "Vanilla(ish)": no boat sinking, the armor regen penalty on, stamina regen 15 → 10 per second in combat (−5), Vitality regen 1 and 1 per second (1.32's), melee actions free (−1: cost × 0), signs costing the whole bar (+1.5: 40 × 2.5 = 100), no cooldowns: close to 1.32's stamina rules. "Off": everything 0 and off (no sinking, no cooldowns, Ghost Mode's base costs and regen). QoL "Recommended": instant casting on, the heartbeat below 50% at full volume, dynamic volume and rate; "Off": instant casting and the heartbeat off. A preset applied takes effect when the menu closes, like a changed option.

**Implementation (legacy):** the preset arrays in `modSignsConfig.xml` (each also writes `GMVersion` "4.0"); `OnPresetApplied` sets the group's flag; the labels.

**5.x:** the same preset mechanism (DIFF-04's and XP-07's presets work through it).

**Decisions:** legacy's (PO8); the QoL defaults with the menu untouched: DO4 (a). Port (slice O2): the preset arrays in `modGhostMode.xml` with legacy's values for every option the port has, without `GMVersion` (PO2), the skill tree toggle (PO8) and `GMSignInstantCast` (DO5); labels 2110992447, 450 and 459 in 9 languages (448 and 449 were DIFF-04's); `OnPresetApplied`'s wrapper sets the gameplay flag (OPT-03's regen start) and the QoL flag (the heartbeat's restart). The gameplay group in legacy's order (PO3): the Whirl and Rend cooldown moved before the sign cooldowns.
- **Deviation:** with the options menu never opened, the QoL group has the "Recommended" preset's values, so the low-stamina heartbeat plays below 50% stamina; legacy's code wrote no QoL defaults, so its heartbeat stayed off until the player chose it. The changelist presents the cue as a feature that can be switched off, and DIFF's DD1 took "Recommended" for the scaling group the same way (owner, DO4, 2026-11-02).

---

### Dependencies on other areas

- **Done areas OPT builds on:** STAM (the stamina options and the QoL group's hook), DIFF-04 (the preset mechanism, labels 448 and 449), XP-07, SKL-02 (the skill tree toggle), FOOD-03 (the regen restart on a regen ability), ENCH-05 (the Vitality regen effect's `OnUpdate` wrapper), UI-05 (the panel lines), EFX-10 (the web), ARM-07 and MUT-12 (the sign methods instant casting reads).
- **Areas OPT shares with or waits for:** WGT (over-encumbrance and item weights for OPT-04 and OPT-05; mapped in parallel), GEN (the base Vitality regen line; no area file), DIFF's DD3 (the accessibility aids that meet OPT-03 to OPT-05).

### Hand-offs received

| From | Item | OPT |
|---|---|---|
| UI (UI-05, the owner's F12 decision, 2026-10-21) | The Vitality regen lines without legacy's regen options: **the open temporary deviation "until OPT"** | OPT-03 ends it: the lines add the options (PO4) |
| UI (hand-off) | `CR4IngameMenu`'s Ghost Mode units; the option strings not ported, by PO2 and DO5 (2110992000, 180, 181, 183, 393, 394, 432, 447–450, 459; the rest went to DIFF-04 and XP-07) | OPT-01, OPT-03 to OPT-07; 448 and 449 are DIFF-04's port, attributed to OPT-07 and DIFF-04 |
| UI, EFX (hand-offs to WGT) | `W3Boat.OnAreaEnter` and its message 2110992179 | OPT-04, shared with WGT |
| EFX (EFX-10, PX9) | The web's release of the sign-select keys (`ForceDeactivateCastSignHold`) with legacy's instant casting | OPT-06 (DO5, PO13) |
| EFX, FOOD (hand-offs to OPT and GEN) | Geralt's base Vitality regen and its options (`GetCombatVitalityRegen`, `GetOutOfCombatVitalityRegen`, `W3Effect_AutoVitalityRegen.SetEffectValue`) | OPT-02, OPT-03 |
| STAM (STAM-07, deviation, porter's call not confirmed) | Legacy's QoL presets and `GMSignInstantCast` not ported "as with OPT-01's other groups" | Done: OPT-07 ported the presets (slice O2); DO5 restated the deviation (5.x's "Quick Sign Casting" in place of the toggle; stam.md's STAM-07 bullet) |
| STAM (STAM-04, `gmModRegenValue`, `gmUpdateRegenEffects`, `FilterAutoBuff`) | "also vitality regen options" | OPT-03 |
| DIFF (DD1, `diff.md` "Not DIFF") | The menu framework, the shared "Recommended" and "Off" labels | OPT-01, OPT-07 |
| `ConGeralt`'s note ("its vitality regen … belong to other areas, not mapped yet") | Base Vitality regen 0 | OPT-02 |

**Temporary deviations "until OPT"** ([deviations.md](deviations.md)): UI-05's Vitality regen lines, **ended** by OPT-03 (slice O1, 2026-11-02). STAM-07's preset deviation is now DO5's (5.x's "Quick Sign Casting" in place of the toggle; above).

### Hand-off to other areas

| Area | Changes |
|---|---|
| WGT | Over-encumbrance and the weights OPT-04 and OPT-05 read: `GetItemEncumbrance`'s full-weight rule and debug fact (unit shared with OPT-05), `CheckPlayerEncumbrance`'s `OverEncumbered` effect and run limit (shared with OPT-04), the boat message 2110992179 (shared); WGT may port the two options with its mechanics (PO6, PO7); 5.x's "Ignore Item Weight" bypasses every weight rule |
| DEP | Community Patch – Base's menu units (listed in the [unit lists](#opt-mod-options) paragraph), unattributed |
| TRPH | `noonwraith_mh308_trophy_stats` (+5 Vitality regen), unattributed, found by the regen sweep |
| GEN | The changelist's "General player abilities" line on the base regen is ported here (OPT-02); nothing left |
| FOOD (note only) | FOOD-03's comment "Geralt is the only actor whose base regen Ghost Mode zeroes" holds since OPT-02 (slice O1); a Bread now starts the regen from a zero base (measured 10/s, slice O1) |

### Save impact

None: the options live in the user settings, `ConGeralt` is read live, the regen effect recomputes its value on every update. Removing the mod mid-playthrough is unsupported ([save compatibility](../feature-mapping.md#save-compatibility)).

### Area decisions

**Decided by the owner (2026-11-02): every recommendation.** DO1 (b) switching on 5.x's "Vitality Regeneration Boost" also starts the regen; DO2 (b) the regen starts when either Vitality option is above 0 (a fix: a deviation, recorded when ported); DO3 (a) boat sinking on at 20% by default (WGT's DW3); DO4 (a) the heartbeat on with the menu untouched, recorded as a deviation; DO5 (a) 5.x's "Quick Sign Casting" instead of legacy's toggle (a deviation; check 5.x's setting on a keyboard in game). The porter's calls confirmed.

| # | Question | Options | Recommendation |
|---|---|---|---|
| DO1 | 5.x's "Vitality Regeneration Boost" with Geralt's base regen at 0 (OPT-02, OPT-03). Legacy: no such aid. 5.x: the aid adds to Geralt's automatic Vitality regeneration while it runs (+1/s above its threshold, more below it); DIFF's DD3 kept it, assuming it adds to Ghost Mode's regen. With legacy's base 0 the automatic regeneration does not run unless food, a potion, a skill or an option gives some, so the aid does nothing most of the time | (a) legacy's rule only: the aid works while some regen runs (after a Bread, under Swallow), else nothing; (b) the aid also starts Geralt's regeneration when it is switched on, as 5.x intends (its +1/s, and its boost below the threshold), with or without other regen; with the aid off (the default) everything is legacy's | **(b)**: DD3 kept the aid for players who want it; with (a) it is switched on and silently does nothing. Not a deviation: legacy had no such aid, and with it off the game plays as legacy |
| DO2 | The combat Vitality option on its own (OPT-03). Legacy's code lets the automatic regeneration start only when the out-of-combat value is above 0 (`FilterAutoBuff` reads `vitalityRegen` only); with base 0, "Combat vitality regen" at 20 and "Out of combat" at 0, Geralt regains nothing in a fight unless food or a potion started the regeneration (from the code; the [legacy test list](../open-questions.md#to-test-in-legacy-ghost-mode)) | (a) legacy's code: the combat option acts only while something else runs the regeneration; (b) start the regeneration when either option is above 0 (a fix, a deviation): at 20 Geralt regains 20 per second in every fight | **(b)**: a defect that keeps the option from working as its label and the changelist say; both options start it in (b), so the out-of-combat one is unchanged |
| DO3 | Boat sinking's default (OPT-04): a **contradiction**. The changelist's weight section says "off by default" (line 935); its "Mod options" section says "Recommended" enables it, and legacy's code writes it on (20%) at the first load and in "Recommended" | (a) the code: on at 20% with the menu untouched; (b) the changelist line: off until the player turns it on (the threshold still 20%) | **(a)**: the code is the better guide ([rule](../feature-mapping.md#legacy-behaviour-first)), and two of the three sources (code, the options section) agree. Recorded in [open-questions.md](../open-questions.md#legacy-data-vs-changelist) |
| DO4 | The QoL group with the menu untouched (STAM-07, OPT-07). Legacy's code writes no QoL defaults, so with the menu never opened the heartbeat is off (threshold 0) and instant casting off until the player applies "Recommended" (or sets them). The port gives the QoL options "Recommended"'s values since STAM-07 (the heartbeat on below 50%), not recorded as a deviation | (a) keep the port's: the heartbeat on with the menu untouched; record it as a deviation, as DIFF's DD1 for the scaling group; instant casting off either way (DO5); (b) legacy's code: no heartbeat until the player chooses it | **(a)**: the changelist presents the cue as a feature that "can be switched off", and DD1 already took "Recommended" for the scaling group; the heartbeat was tested and listened to by the owner with these values |
| DO5 | Instant sign casting (OPT-06). Legacy: a QoL toggle (off by default, on in "Recommended"); a select key casts, held over 0.2 s it is the cast key held. 5.x: "Quick Sign Casting" in Gameplay does the same on the keyboard, from the code (select key casts, hold to channel, release aborts; the alternate cast from the select keys), off by default | (a) use 5.x's setting: legacy's toggle not ported, the QoL presets without it, legacy's input code not ported (a deviation: the option lives in 5.x's Gameplay settings, under its name, with 5.x's hold rule, and "Recommended" does not turn it on); (b) port legacy's toggle and code next to 5.x's (two systems on the same keys: with both on, one key press could start two casts or conflict); (c) Ghost Mode's toggle in QoL that switches 5.x's setting (the presets work as legacy's; two places show one setting, which can disagree if the player changes 5.x's) | **(a)**: 5.x built the feature into the game with STAM-01's cooldown already on its path; (b) duplicates it and needs the six input methods replaced; legacy's inverted orientation timer would come with it (fixed or kept). An in-game check of 5.x's setting on a keyboard (a select key casts, the hold, a cooldown refusal) goes into the slice |

### Porter's calls

Each follows legacy or has no play effect; for the owner to confirm.

| # | Call |
|---|---|
| PO1 | OPT is ported as one area with one audit at the end, about 140 new units, in the slices of the [port order](#port-order); OPT-04 and OPT-05 may be ported by WGT with its mechanics (PO6, PO7) |
| PO2 | OPT-01 stays as ported: per-option defaults (no `GMVersion`, `gmSetGMVersion` or `GetGMVersion`; legacy's "re-apply your Gameplay settings after updating" has no counterpart), live getters (no `gmResetCachedValues*`), legacy's ids and label keys; the "Mods" label 2110992000 not ported (5.x's `panel_mods`) |
| PO3 | The gameplay group in legacy's order, with the port's skill tree toggle first: boat sinking, threshold, item weight, armor regen penalty, stamina regen (combat, out of combat), Vitality regen (combat, out of combat), the three cost modifiers, regen delay, Whirl and Rend cooldown, sign cooldown, alternate sign cooldown (today the port has the Whirl and Rend cooldown last) |
| PO4 | OPT-02 and OPT-03 together in one slice: `ConGeralt`'s Vitality regen 0 by `extend` (NG+ 0, legacy's NG+), the options in the regen effect's `SetEffectValue` (a wrapper after 5.x's body), in the regen start (with DO1 and DO2), in a gameplay change hook that updates or starts the regeneration (legacy's `gmUpdateRegenEffects`; stamina needs nothing, STAM-04 recomputes every update), and in UI-05's panel lines, which ends UI-05's temporary deviation; `wasLoaded` not ported (5.x recomputes every update) |
| PO5 | The panel's Vitality regen lines show Geralt's regen with the options, without 5.x's "Vitality Regeneration Boost" (an aid legacy did not have; as today) |
| PO6 | OPT-04: legacy's branch in a `@replaceMethod` of `W3Boat.OnAreaEnter` (5.x's body is 1.32's) and `CheckPlayerEncumbrance` added; the message 2110992179 in 9 languages; it reads whatever over-encumbrance WGT ports, so it follows WGT's over-encumbrance slice; 5.x's "Unlimited Boat Durability" keeps boats from sinking (legacy's `GetCanBeDestroyed` check, kept) |
| PO7 | OPT-05: the factor in `GetItemEncumbrance`, whose body WGT replaces (legacy's full-weight rule); one `@replaceMethod`, written by the area that ports it first, with both parts; 5.x's "Ignore Item Weight" keeps working before it |
| PO8 | OPT-07: legacy's preset values for the options the port has, without `GMVersion` and without the port's new options (the skill tree toggle, as DIFF-09's option is outside the scaling presets); the QoL presets without `GMSignInstantCast` under DO5 (a); a preset takes effect when the menu closes through the same hooks as a changed option |
| PO9 | The 9 languages' labels as legacy's, rows keyed by `key(str)` (XP's PX9 form) |
| PO10 | OPT-03's slider range 0 to 1000 per second, as legacy (no balance change in the map) |
| PO11 | NG+: OPT-02's 0 in `abilities_plus` too (legacy's NG+ file), untested |
| PO12 | OPT-05: legacy's slider kept next to 5.x's "Ignore Item Weight" (its 1–99% has no 5.x counterpart) |
| PO13 | Under DO5 (a): EFX-10's spider web also releases the five sign-select keys while 5.x's "Quick Sign Casting" is on (legacy's `ForceDeactivateCastSignHold`), which closes EFX-10's open item without a deviation |

### Port order

Each slice compiles and is verified on its own by script (the regression in both trees; no skill is involved, so the per-tree checks are the regression's); menu changes go through the menu's code path (`ingamemenu()`, `OnOptionValueChanged` or `OnPresetApplied` as its Flash calls them, `game.py resume`). One audit after the last (PO1).

| # | Slice | Verified by |
|---|---|---|
| O0 | **WGT's menu entries** (OPT-04, OPT-05, DO3): `GMSinkBoat` (on), `GMSinkBoatOverEnc` (20), `GMEncumbranceMultiplier` (0) in the gameplay group after the skill tree toggle, legacy's ids, types and labels in 9 languages; entries only, the mechanics are WGT's | **Verified on the area build** (2026-11-02, gm/opt `5f6eeb33`): `GMTest_opt_o0` (in `GMTest_opt`, the regression; +22 checks in each tree, 1,322 and 156, all passing: 16 of O0, 6 of OPT-01 for the three new options) reads each entry's place in the group, its type, its label against its string id, its default and the value written at the load, and the getters; failed first on a build without the entries (16 of 16) |
| O1 | **Vitality regeneration** (OPT-02, OPT-03, DO1, DO2, PO4, PO5): `ConGeralt` 0, the two options and their labels, the regen start, the gameplay change hook, the panel lines | **Verified on the area build** (2026-11-02), all scripted: `GMTest_opt_o1` (in the regression): `ConGeralt`'s four nodes 0 (5.x 1 and 1), the options' defaults, place and labels; the regen stopped and started as the game starts it: none with the defaults, it starts with the out-of-combat option at 10, with the combat option at 20 alone (DO2) and with the boost alone (DO1), and the effect's values and the panel's two lines equal Geralt's own regen plus the options. Measured with `gmtest_opt_o1_a`/`_b` (Vitality at 50%, a 1-point drain starting the regen as a hit does, the rate over about 6 s): defaults 0/s (5.x: 1/s); out of combat at 10: 10/s; a Bread (Well Fed level 1, FOOD-03's restart) 10/s; the boost alone 1/s; with a frozen hostile test dummy (Geralt in combat) combat 20: 20/s, and out-of-combat 10 alone: 0/s in combat. The menu's path (`ingamemenu()`, `OnOptionValueChanged`, `game.py resume`) with the regen stopped at 50%: the combat option at 20, and the boost switched on, start it when the menu closes; an unchanged 0 does not. Each new check failed first on throwaway builds (without `ConGeralt`'s 0 and the code; with the 0 but without the code: no start with either option or the boost, 0/s measured at 10, no start through the menu). Regression (gm/opt `e45665c6`, the same tree as the tested build `572b4638`): 1,334 and 156 passed, 0 failed in each tree (+12 over O0's 1,322: 8 of O1, 4 of OPT-01 for the two options); in the regression Geralt carries the earlier checks' food and potions (80/s out of combat), so the case "no start with the defaults" is checked by `gmtest_opt()` on a fresh load |
| O2 | **Presets and order** (OPT-07, PO3, PO8, DO4): the gameplay and QoL preset arrays, labels 447, 450, 459, the gameplay group's order | **Verified on the area build** (2026-11-02, gm/opt `2c2a8be9`, the same tree as the tested build `2fe69782`), all scripted: `GMTest_opt_o2` (in the regression): the gameplay group's 16 options in legacy's order; 3 and 2 presets with their labels; each preset applied (`ApplyGroupPreset`) sets legacy's values and leaves the skill tree toggle alone, and in play gives: "Recommended" cooldowns 7.5, 5 and 7.5, a sign's 40 stamina 40, a light attack's 10 10; "Vanilla(ish)" no cooldowns, the sign 100, the light attack 0, combat stamina regen −5, Vitality regen +1 and +1, the armor penalty on, no boat sinking; "Off" no cooldowns, base costs, everything off; the QoL and gameplay defaults equal "Recommended" (DO4). Through the menu's path (`ingamemenu()`, `OnPresetApplied`, `game.py resume`): "Vanilla(ish)" sets the values and starts Geralt's stopped Vitality regen (1/s measured with the same values), "Off" leaves it stopped; at 20% stamina QoL "Off" stops the heartbeat and "Recommended" starts it. Each new check failed first on a throwaway build with the checks only (the order, no presets, values unchanged through the menu, no regen start, the heartbeat still playing); the QoL "Recommended" values and the defaults checks pass there too (they test what O2 keeps). Regression: 1,346 and 156 passed, 0 failed in each tree (+12 over O1's 1,334). Open: the menu on screen in a cleared run |
| O3 | **Instant casting** (OPT-06, DO5, PO13): 5.x's "Quick Sign Casting" in place of legacy's toggle; the web releases the five select keys while it is on | **Verified on the area build** (2026-11-02, gm/opt `7cd0332b`, the same tree as the tested build `4e1f41f3`), all scripted: `GMTest_opt_o3` (regression): no toggle in the QoL group, 5.x's setting in its Gameplay group. 5.x's setting switched on and off through the menu's path (`OnOptionValueChanged` on `Gameplay`/`EnableAlternateSignCasting`, which calls `SetIsAltSignCasting`; `game.py resume`); a select key pressed by script through `CPlayerInput.OnSelectSign` (`gmtest_opt_o3_select`/`_after`): with the setting on, Igni's and Aard's keys cast their sign at the press (the sign equipped, STAM-01's cooldown started); with the sign on cooldown (STAM-01) or no stamina the press is refused and the sign is not even selected; with the setting off the key only selects. A spider web (`EET_Tangled` added as the projectile adds it): the select keys released with the setting on, not with it off; failed first on a throwaway build without the release (0 with the setting on). Regression: 1,347 and 156 passed, 0 failed in each tree (+1 over O2's 1,346). Open: real keys on screen (the cast, the hold, a web during a held channel) |
| ~~O4~~ | Boat sinking: **WGT's** (the parent's split, 2026-11-02). WGT ports the sinking with its over-encumbrance and checks it in its slice W6 through O0's entries | — |
| ~~O5~~ | Item weight reduction: **WGT's**. WGT ports the factor in its `GetItemEncumbrance` and checks it in its slice W4 through O0's entry | — |

**Later:** none recorded.

### OPT audit (2026-11-02)

Done by a fresh session ([audit](../feature-mapping.md#audit-signing-a-feature-off)) on 5.x-GM `501a4d26` and master `ba6a5abf`, reading code and data, with game runs on 2026-11-02 (scripted only). Read against legacy (`legacy-GM`), 1.32 (`master`) and 5.x (`vanilla-5.x`): `options/gmOptions.ws`, `options/vitalityRegen.ws`, `options/instantCasting.ws`, UI-05's `GMPanelVitalityRegen` and `AddCharacterStat` wrapper, FOOD-03's regen restart, `ConGeralt` in `gm_stats.xml` (regular and NG+), the menu file, the tests in `tests/gmTestsOpt.ws`; and from the game: `W3Effect_AutoVitalityRegen`, `W3RegenEffect`, `W3EffectManager`'s regen start (`StartRegenInternal`, `FilterAutoBuff`), `CR4IngameMenu`'s option, preset and accessibility code, `CPlayerInput.OnSelectSign` and `AltCastSign`, `ShouldStopChanneling`, `ChangeAspect`; legacy's `gm_options.ws`, `gm_input.ws`, its getters in `W3GameParams`, `CR4Game.gmUserSettings*`, `CR4IngameMenu`'s flags, `CharacterStatsPopup`, `FilterAutoBuff`, `OnSelectSign` and `DelayOrientationChangeTimer`.

**Checked by scripts written for this audit** (scratchpad, not kept):
- **The menu**, parsed from both files: every group, variable, display name, type, range, visibility, option list and preset entry of legacy's `modSignsConfig.xml` against the port's `modGhostMode.xml`. Equal except what is recorded: `GMVersion` and its preset entries (PO2), `GMSignInstantCast` and its QoL preset entries (DO5), the port's own options (the skill tree toggle, Ciri's difficulty, the "Interpolated" scaling type). The four groups' display names, the order of every group and all nine presets' values equal legacy's.
- **The labels**: every key the port's menu needs (63: `panel_*`, `option_*`, `preset_*`, `preset_value_*`) resolved to its string id through the English tables, then the text compared with legacy's row of the same id in all 9 languages. Every legacy label is there with legacy's id and text, in every language; missing only `panel_Mods` 2110992000 (PO2; 5.x's own `panel_mods` is shown) and 2110992432 (DO5). The port keys the rows by `key(str)` where legacy had hashes (PO9). The skill tree toggle's label (SKL-02) is English in every language.
- **The defaults**: `GMOptionDefault` against legacy's `gmLoadDefaultSettings` for the gameplay group (equal; `GMAgilityStaminaCostMultiplier`, which legacy did not write, reads 0 in both); the other groups as their areas recorded (DD1, DO4, XP-07).
- **Every reader**: each of legacy's 37 option getters and its callers listed; each is ported by its area (STAM, DIFF, XP, OPT-03), not ported by decision (`GMVersion`: PO2; `GMSignInstantCast`: DO5) or WGT's (`GMSinkBoat`, `GMSinkBoatOverEnc`, `GMEncumbranceMultiplier`: F2). `unit_sweep.py --unattributed` for `VitalityRegen|vitalityCombatRegen`, `GMVersion|InstantCast|TestCastSignHold|castSignHold`, `GetBoatSink|too_heavy|GetEncumbranceMult`: no unit left.
- **Every source of Geralt's Vitality regen** in the port's data (5.x's files with the DLC's entries over them): food and drink, Swallow and the decoctions, Mutation 11, the Bear pheromone, runes, glyphs and runewords, the Noonwraith trophy, Undying (both trees' abilities), the new tree's `perk_1_day_ability` and `perk_38_day_ability`. Each has an out-of-combat part, so it starts the regen through the game's own rule, except the Tvarog rune (F1). The Troll decoction's +80 combat bonus comes on top of the decoction's own +100 out of combat.

**Checked and holding:**
- **Presets**: the three gameplay and two QoL presets give legacy's value for every option the port has; the skill tree toggle is in none (PO8); the regression's `GMTest_opt_o2` hard-codes legacy's values, not the port's file.
- **OPT-02**: `ConGeralt`'s four Vitality regen nodes are 0 in the regular and NG+ files, as legacy's NG+ file; 5.x has no other always-on Vitality regen for Geralt (`geralt_stats.xml`, both folders).
- **OPT-03's code**: the option is added after 5.x's value (so 5.x's boost stays in it) and for Geralt only (`W3PlayerWitcher`), as legacy's `isOnPlayer && GetWitcherPlayer()`; Ciri gets neither (legacy's start, which read the option for every actor, only ever added a zero-value effect to anyone but Geralt). The start wrapper adds the effect only when 5.x's start did not and the flag is off, as 5.x's own start does. The `OnEffectAdded` wrapper keeps a regen started by the combat option or the boost alone switched on (5.x switches off an effect whose value is 0 when added). Legacy's `gmUpdateRegenEffects` also refreshed the running effects' values and restarted the stamina regen: 5.x recomputes both every update, and the stamina regen cannot be missing while stamina is below full (its start reads `staminaRegen`, never null for Geralt).
- **The change hooks**: the Vitality flag is set by either option, the boost, 5.x's accessibility preset (which sets the boost through `updateAccessibilityPresetValues`) and the gameplay presets; legacy set its gameplay flag for every gameplay option, which in the port only the Vitality options need (everything else is read live). The scaling, quest-level, Ciri and QoL flags as their areas recorded.
- **The character panel**: `GMPanelVitalityRegen` is legacy's formula term for term (additive + multiplicative × maximum Vitality + the option), without 5.x's boost (PO5).
- **Instant casting (DO5)**: 5.x's keyboard path is complete in the code: `OnSelectSign` → `AltCastSign` (STAM-01's cooldown check, stamina, blocked signs), `ShouldStopChanneling` (5.x's, not replaced by the port) keeps a channel while a select key is held, `OnSelectSign`'s release aborts it, ARM-07's `ChangeAspect` keeps 5.x's keyboard branch for the alternate cast. The web's release (PO13) acts only while 5.x's setting is on.
- **Both skill trees**: no option reads a skill; the skills that give regen (Undying's two abilities, the new tree's two perks) have an out-of-combat part and start the regen in either tree. The regression ran in both.
- **Save impact** none and **NG+** as recorded.

**In game** (scripted, `game.py exec`, the test save, saving locked). A throwaway build, gm/optaudit `509834a0` (5.x-GM `501a4d26` plus `tests/gmAuditOpt.ws`), then the integrated build for the regression:

| Check | How | Result |
|---|---|---|
| A combat-only regen of Geralt's own starts the regen (F1): the Tvarog rune's ability on Geralt, the options 0, the boost off, Vitality 50%, the regen stopped, then started as a hit starts it | scripted, `gmaudit_opt_combonly()` | **FAIL**: not started; the panel's combat line says 5/s |
| The same in a fight: a frozen hostile dummy (Geralt in combat), the Tvarog ability, `gmtest_opt_o1_a(0, 0)` (a 1-point drain starts the regen), the rate over 2.5 s | scripted, `gmtest_opt_o1_b()` | **0/s** in combat (the panel: 5/s) |
| Contrast: the out-of-combat option at 1 starts the regen (`gmtest_opt_o1_a(1, 0)`), still in the fight | scripted, `gmtest_opt_o1_b()` | 4.99/s in combat: Tvarog acts once something else started the regen |

**Regression** (5.x-GM `501a4d26`, `build\integ-501a4d26`, `regress.py --trees both`, one fresh launch per tree): `gmtest_regress()` 1,483 passed, 0 failed, and `gmtest_panel()` 156 passed, 0 failed, in each tree. The release found the saves clean (1,079 live and in the backup; none gone, new or changed).

**Findings:**

1. **The Tvarog rune gives no regeneration on its own** (medium; owner decision). With Geralt's base regen at 0 (OPT-02), his automatic regeneration starts only when his out-of-combat regen is above 0 (5.x's `FilterAutoBuff`, which legacy kept, reading `vitalityRegen` only) or, since DO1 and DO2, when an option or the boost is on (`StartVitalityRegen`'s wrapper). The Tvarog rune (ENCH-16: "+5 Vitality regen in combat") is the only source in the port with a combat value and no out-of-combat one, so on its own it never starts the regen: measured 0/s in a fight while the character panel shows 5/s; once anything else starts the regen (food, a potion, the out-of-combat option) it adds its 5/s. Legacy had the same start rule and base, so from the code it played the same (added to the [legacy test list](../open-questions.md#to-test-in-legacy-ghost-mode)). This is the defect DO2 fixed for the combat option, left for Geralt's own combat regen.
   - (a) Keep legacy's rule: Tvarog works only while another source runs the regen; the panel's line overstates it.
   - (b) Extend DO2's fix: the regen also starts when Geralt's own combat regen is above 0 (the start wrapper and `OnEffectAdded`'s keep-on test read `vitalityCombatRegen` too); a deviation, recorded with DO2's.
   - **Recommendation: (b)**, for DO2's reason (the rune works as its tooltip and the changelist say). Test: `gmaudit_opt_combonly()` above, made a regression check.
2. **Boat sinking and the weight reduction are in the menu but do nothing on 5.x-GM yet** (low, temporary; doc correction, and a release gate). Slice O0 put the three entries in the menu, with their defaults and in the presets, but nothing on 5.x-GM `501a4d26` reads `GMSinkBoat`, `GMSinkBoatOverEnc` or `GMEncumbranceMultiplier` (a search of the scripts: only `GMOptionDefault` and `GMOptionList`): WGT's slices W4 (the weight factor) and W6 (the boats) are not integrated. OPT-01's rule "options appear in the menu only once their feature is ported" does not hold for them, and "Vanilla(ish)" and "Off" switch off a sinking that does not exist yet. Corrected in OPT-04's and OPT-05's port status (this audit). No build should be released before WGT's W4 and W6 are integrated.
3. **OPT's doc named WGT's slices the wrong way round** (low; doc correction, **done** with this audit): OPT-04 (boats) said WGT's W4, OPT-05 (weight) W6; WGT's port order has W4 for the formula and the option, W6 for the boats.
4. **Legacy's inverted turning during a sign cast is not ported, for every player** (low; owner decision and doc correction). Legacy's `DelayOrientationChangeTimer` reads `TestCastSignHold()` where 1.32 tested the cast key's release, so the delayed turning of a sign cast ended while the cast key was still held, with or without instant casting ([legacy test list](../open-questions.md#to-test-in-legacy-ghost-mode)). DO5's deviation mentions it only as part of instant casting. Not porting it changes how every held cast turns, so it is a deviation of its own (keeping 1.32's and 5.x's turning, a fix of legacy's defect). Recommendation: confirm, and record it as its own **Deviation** bullet in OPT-06 (`deviations.py --write`).
5. **A refused select-key press keeps the old sign** (low; doc correction). With 5.x's "Quick Sign Casting" a press refused for the cooldown (STAM-01) or for stamina does not select the sign (`AltCastSign` selects only when the cast goes ahead; seen in slice O3); legacy's `OnSelectSign` selected the sign first and then tried the cast, so after a refused press the sign was selected and the cast key would cast it. DO5's deviation lists four differences, not this one: add it. **Done** (2026-11-02, fix1).
6. **Stale comments in `gmOptions.ws`** (low; clear fix). `GMIsQoLOption`: "GMSignInstantCast is not ported yet" (it is not ported, by DO5); the header of the change hooks lists the QoL, scaling and quest-level reactions, not the Vitality regen's or Ciri's. **Fixed** (gm/fix1 `bc56705c`).
7. **Other areas' docs out of date on OPT** (low; doc correction, for the parent, not edited here): [README.md](README.md#where-the-port-stands) ("integrated so far: OPT's slice O0", "their decisions and porter's calls wait for the owner"); [ui.md](ui.md) UI-05's "Depends on … OPT (vitality regen options, not ported)". [open-questions.md](../open-questions.md#to-test-in-legacy-ghost-mode)'s OPT heading ("the port's decisions are open") is corrected with this audit. **Done** (2026-11-02): README.md's and ui.md's lines on OPT updated (fix1).
8. **`gmtest_opt_o1_end()` does not put the player's settings back** (low; clear fix, tests only): it sets both Vitality options to 0 and 5.x's boost off, whatever they were (the regression's `GMTest_opt_o1` restores them; the release restores the baseline, so only a session is affected). Save the values in `gmtest_opt_o1_a` and restore them. **Fixed** (gm/fix1 `bc56705c`): the first `gmtest_opt_o1_a` of a session saves them, `gmtest_opt_o1_end()` puts them back (checked by script: 5 and 3, boost off, restored after two `_a` calls).

**Open checks** (unchanged by the audit): the menu on screen (the order, the preset labels) and 5.x's "Quick Sign Casting" with real keys (the cast, the hold, a web during a held channel), in a cleared run; OPT-02's NG+ copy (a regular game does not read the `_plus` folders; checked offline).

#### OPT audit close-out

**OPT signed off by the owner (2026-11-02).** The open checks that need real keys or the menu on screen wait for a cleared run, and NG+ is checked offline only.

**The owner's decisions (2026-11-02), all as the audit recommended.** Every finding is fixed, decided or recorded.

| Finding | Outcome | How tested |
|---|---|---|
| F1 The Tvarog rune gives no regeneration on its own | **fixed** as decided (b), a deviation ([OPT-03](#opt-03-vitality-regen-options)): Geralt's regen also starts when his own combat regen is above 0 (`GMVitalityRegenStarts`, `options/vitalityRegen.ws`: the start wrapper and the keep-on test) | scripted, both trees: `GMTestOptO1Tvarog` in `GMTest_opt_o1` (the regression: Geralt's effects with an out-of-combat regen set aside and put back, the Tvarog ability alone, the options 0, the boost off: the regen starts at 5/s in combat, the panel's line 5); measured in a fight (a frozen hostile test dummy, `gmtest_opt_tvarog(true)`, `gmtest_opt_o1_a(0, 0)`, the rate over about 7 s with `gmtest_opt_o1_b()`): 4.99/s; failed first on the throwaway build: not started, 0/s over 7.2 s |
| F2 Boat sinking and the weight reduction did nothing yet | **closed**: WGT's W4 and W6 are integrated (5.x-GM `fbb925eb`); OPT-04's and OPT-05's status updated; the release gate removed | WGT's `GMTest_wgt04` and `GMTest_wgt06` through these entries |
| F3 WGT's slices named the wrong way round | **corrected** with the audit | read |
| F4 Legacy's inverted turning during a held sign cast | **confirmed**: not ported, recorded as its own deviation ([OPT-06](#opt-06-instant-sign-casting)) | docs only |
| F5 A refused select-key press keeps the old sign | **corrected** (fix1) | read |
| F6 Stale comments in `gmOptions.ws` | **fixed** (fix1, 5.x-GM `bc56705c`) | read |
| F7 Other areas' docs on OPT | **corrected** (fix1) | read |
| F8 `gmtest_opt_o1_end()` and the player's settings | **fixed** (fix1) | scripted (fix1) |

**Regression** (gm/fix2 `528540ef`, `regress.py --trees both`, `god()` off, a fresh launch per tree): `gmtest_regress()` 1,524 passed, 0 failed, and `gmtest_panel()` 156 passed, 0 failed, in each tree (+13 checks over 1,511: OPT 1, TRPH 4, WGT 8). Fail first: a throwaway build (gm/fix2-fail `74c94b7a`: the fixes, WGT-07's term and WGT-09's rule removed, the tests kept) failed every new check that tests a fix; the four "unchanged" checks (Aard, a usable item and Whirl per armor class; Roach's gear back) passed there too, as they test what stays. The saves: the releases found them clean (1,079 live and in the backup; none gone, new or changed).

**Deviations:** two new, both the owner's (2026-11-02): F1's regen start (OPT-03) and F4's turning (OPT-06).

### For the shared docs

Moved into the shared docs at integration (2026-11-02).
