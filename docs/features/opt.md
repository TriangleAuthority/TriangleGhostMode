# OPT: mod options

Ghost Mode's settings menu (Options → Mods → Ghost Mode) and what it sets: the four groups "Enemy scaling", "Experience", "Gameplay" and "QoL", their presets, the defaults a setting has before the player touches the menu, the code that reads each setting and re-applies it when the menu closes, and the options whose feature belongs to no other area: Geralt's Vitality regeneration (with his base regeneration, which the changelist puts under "General player abilities"), boat sinking when over-encumbered, the item weight reduction, instant sign casting and the gameplay and QoL presets. Ghost Mode's changelist has its own section, "Mod options" (lines 1176–1251), and mentions options in the "Stamina changes" section (lines 218–243), the weight lines of "Armor" (lines 925–935) and "General player abilities" (line 474); the mod description's section 8, "Mod customization options", sends the player to the changelist.

**The player-visible texts first.** Legacy's changelist, quoted exactly, for what this file maps (the scaling and experience options are quoted in [diff.md](diff.md) and [xp.md](xp.md#xp-07-experience-options), the stamina options in [stam.md](stam.md)): "Default settings for Gameplay are now automatically loaded if you haven't set them up in the menu manually (with presets or sliders). If you're updating from the previous mod version, make sure to re-apply your personal Gameplay settings after loading a save."; "Gameplay presets: recommended - enables boat sinking if overencumbered and cooldown for signs and special sword attacks; vanilla(ish) - restores stamina management to vanilla(ish) logic, i.e. melee has zero cost, signs drain 100% stamina; off - all zero and off."; "Sink the boat if overencumbered: enables boat sinking if Geralt is overencumbered."; "Overencumbrance threshold to sink the boat (%): defines overencumbrance threshold in percents relative to max carry weight at which boat sinking happens."; "Reduce item encumbrance (%): reduces item weight for all the items in percents."; "Combat/Out of combat vitality regen (additional): allows to additionally increase/decrease vitality regen in/out of combat (relative to default values)."; "QoL presets: recommended - enables sign instant casting and low stamina sfx; off - turns off sign instant casting and low stamina sfx."; "Instant sign casting with select key: allows to instantly cast a sign when corresponding sign selection key is pressed (3-7 by default)."; from "General player abilities": "Default health regen for Geralt in and out of combat is now zero."; from "Armor": "If your over encumbrance is too big (20% over the limit), the boat you're trying to board will sink (off by default, can be tweaked in options)." (the code turns it on: [DO3](#area-decisions)); from "Stamina changes": "if you don't like this type of combat and think that TW3 is better with vanilla stamina, you can switch the feature off in mod's options." Legacy's labels (English; every one in 9 languages, `localization/modGhostMode/<lang>.csv`): group "Gameplay" (2110992329) with "Gameplay Presets" (2110992450) and the presets "Recommended", "Vanilla(ish)", "Off" (2110992448, 459, 449); "Sink the boat if over encumbered" (180), "Over encumbrance threshold to sink the boat (%)" (181), "Reduce item encumbrance (%)" (183), "Combat vitality regen (additional)" (393), "Out of combat vitality regen (additional)" (394); group "QoL" (441) with "QoL Presets" (447), "Instant sign casting with sign select key" (432); the boat's message "Your over encumbrance is too high" (179); "Mods" (2110992000), the panel's name in 1.32, which 5.x names itself (`panel_mods` is vanilla in 5.x). The game's own texts that touch these options, decoded from 5.x's `en.w3strings` with `w3strings.py` and matched to the settings by name (unverified on screen): 5.x's Gameplay setting "Quick Sign Casting" (1222517 and others) and its tutorial, "You have enabled Quick Sign Casting on your controller. This setting aims to eliminate the need for the Quick Access Menu when casting signs." (1223738, controller buttons only); the Accessibility settings "Vitality Regeneration Boost" (1252440), "Ignore Item Weight" (1446543) and "Unlimited Boat Durability" (1446553).

**What 5.x did in this area** (from `vanilla-5.x` and the game's menu files). The menu framework is the same idea (a mod's menu XML in `bin\config\r4game\user_config_matrix\pc\`, groups under Options → Mods; [development.md](../development.md#options-menu)). 5.x adds settings of its own that meet four of legacy's: **"Quick Sign Casting"** (Gameplay, `EnableAlternateSignCasting`, off by default), which, from the code, also on a keyboard makes a sign-select key cast its sign (`CPlayerInput.OnSelectSign` → `AltCastSign`), keeps a channeled sign going while the key is held (`ShouldStopChanneling`) and aborts it on release: legacy's instant casting, built in; **"Vitality Regeneration Boost"** (Accessibility, `LowHPAutoHealOn` with a threshold and a multiplier), which adds to the value of Geralt's automatic Vitality regeneration (`W3Effect_AutoVitalityRegen.SetEffectValue`: +1 per second above the threshold, up to the multiplier × 1.1 below it), so it only acts while that regeneration runs; **"Ignore Item Weight"** (Accessibility, `WeightlessItems`), which makes no item count for weight (`IsItemEncumbranceItem`): legacy's weight reduction at 100%; **"Unlimited Boat Durability"** (Accessibility, `DisableDurabilityBoat`), which makes boats indestructible (`W3Boat.GetCanBeDestroyed`), and legacy's sinking only sinks a destructible boat. The Accessibility preset "Bard's Ballad: Focus & Rest" turns the last two on (DIFF's [DD3](diff.md#area-decisions) kept 5.x's aids, untuned). Geralt's base Vitality regeneration is 1.32's, 1 per second in and out of combat (`ConGeralt`); `W3Boat.OnAreaEnter`, `GetItemEncumbrance` and the effect manager's regen start (`FilterAutoBuff`) are 1.32's.

**How legacy Ghost Mode implements it.** Data: the menu file `menu/modSignsConfig.xml` (four groups, 37 variables with the hidden `GMVersion`, 9 presets; [inventory](#legacy-options-inventory)); `ConGeralt`'s four Vitality regen nodes set to 0 (`geralt_stats.xml`, regular and NG+); about 60 labels in 9 languages. Scripts: `gm_generic/gm_options.ws` (`gmLoadDefaultSettings`, `gmSetGMVersion`, `gmIsScalingOption`, `gmIsGameplayOption`, `gmIsQoLOption`, `gmModRegenValue`, `gmUpdateRegenEffects`, `gmInstantCastingAllowed` and the stamina cost and delay modifiers); `gm_generic/gm_input.ws` (`TestCastSignHold`, `ForceDeactivateCastSignHold`); the getters in `W3GameParams` (the gameplay and QoL ones cached until `gmResetCachedValuesGameplay` / `gmResetCachedValuesQoL`); `CR4Game.gmUserSettingsScaling`, `gmUserSettingsQuestLevels`, `gmUserSettingsGameplay`, `gmUserSettingsQoL`; `CR4IngameMenu`'s four change flags, set in `OnOptionValueChanged` and `OnPresetApplied` and acted on in `gmUserSettings` from `SaveChangedSettings`; `CR4Player.OnSpawned` (`gmLoadDefaultSettings`); the readers: `W3Effect_AutoVitalityRegen` (`SetEffectValue`, `OnLoad`, `wasLoaded`), `W3EffectManager.FilterAutoBuff`, `AddCharacterStat` (the panel), `W3Boat.OnAreaEnter` and `CheckPlayerEncumbrance`, `CInventoryComponent.GetItemEncumbrance`, `CPlayerInput.OnSelectSign`, `CR4Player.SetCastSignHoldTimestamp` and `castSignHoldTimestamp`, and `TestCastSignHold` in place of the cast key in `OnDelayOrientationChange`, `DelayOrientationChangeTimer`, `W3PlayerWitcher.OnProcessCastingOrientation`, `W3SignOwnerPlayer.ChangeAspect`, `W3SignEntityStateChanneling.ShouldStopChanneling`, and `ForceDeactivateCastSignHold` in `W3Effect_Tangled.OnEffectAdded`. No binary file.

Unit lists: [attribution.csv](attribution.csv): **330 units carry an OPT feature** (OPT-01 192, OPT-02 2, OPT-03 36, OPT-04 38, OPT-05 18, OPT-06 30, OPT-07 51; a unit can carry several), OPT shared with other features on 20 of them (the menu file's glob row, STAM-04's `gmModRegenValue`, `gmUpdateRegenEffects` and `FilterAutoBuff`, UI-05's `AddCharacterStat`, `ConGeralt` regular and NG+, ARM-07's `ChangeAspect`, MUT-12's `ShouldStopChanneling`, EFX-10's web, OPT-01's own functions). Not OPT's and left unattributed: Community Patch – Base's menu units (`IngameMenu_FillArrayFromConfigGroup`, `IngameMenu_GetOptionTypeFromString`, `IngameMenu_FillOptionsSubMenuData`, `CR4IngameMenu.OnConfigUI`, `OnRefresh`, `StartShowingCustomDialogs`, `OnButtonClicked`, `ddd`, `InGameMenuActionType`, `IngameMenuStructureCreator.CreateNewGameListArray`, `CR4MainCreditsMenu.OnCloseMenu`: DEP, 1.32's mod-menu plumbing that 5.x has natively) and the Noonwraith trophy's Vitality regen (`noonwraith_mh308_trophy_stats`, TRPH).

**Status:** every feature ported and verified by script in both trees (OPT-04's and OPT-05's mechanics are WGT's); the [area decisions](#area-decisions) DO1 to DO5 and the [porter's calls](#porters-calls) PO1 to PO13 decided by the owner. Signed off by the owner (2026-11-02). Menu changes were tested through the menu's code path (`ingamemenu()`, `OnOptionValueChanged` or `OnPresetApplied` as its Flash calls them, `game.py resume`); the checks that need the menu on screen or real keys are open checks.

## Scope

**OPT covers** the menu framework (OPT-01), every legacy option no other area owns (OPT-02 to OPT-06) and the gameplay and QoL presets (OPT-07).

**Ported by other areas** (through OPT-01's framework):

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

Every variable of legacy's menu, with its type (`SLIDER;min;max;steps`), its value with the menu never touched (legacy's code: `gmLoadDefaultSettings` writes the gameplay group's once, when `GMVersion` is empty; every other unset option reads as 0 or off), its three presets' values where it has them, the code that reads it, and where it stands in the port (`modGhostMode/menu/modGhostMode.xml`, defaults in `scripts/local/gm/options/gmOptions.ws`).

**Gameplay** (`GMGameplayOptions`; presets "Recommended" / "Vanilla(ish)" / "Off"):

| Option (label) | Variable, type | Untouched (legacy) | Presets R / V / O | Read by (legacy) | Port |
|---|---|---|---|---|---|
| Sink the boat if over encumbered | `GMSinkBoat`, toggle | on | on / off / off | `W3Boat.OnAreaEnter` (`GetBoatSinkOption`) | entry and default on; the sinking: WGT-10 |
| Over encumbrance threshold to sink the boat (%) | `GMSinkBoatOverEnc`, 0–100 | 20 | 20 / 0 / 0 | `W3Boat.CheckPlayerEncumbrance` | entry and default 20; the sinking: WGT-10 |
| Reduce item encumbrance (%) | `GMEncumbranceMultiplier`, 0–100 | 0 | 0 / 0 / 0 | `CInventoryComponent.GetItemEncumbrance` (`GetEncumbranceMult`, ÷100) | entry and default 0; the reduction: WGT-02 |
| Enable stamina regen penalty for armors | `GMArmorRegenPenalty`, toggle | off | off / on / off | `IsArmorRegenPenaltyEnabled` (regen, panel, tooltips) | STAM-05, default off |
| Combat stamina regen (additional) | `GMCombatStaminaRegen`, −15–85 | 0 | 0 / −5 / 0 | `gmModRegenValue` | STAM-04, default 0 |
| Out of combat stamina regen (additional) | `GMOutOfCombatStaminaRegen`, −100–0 | 0 | 0 / 0 / 0 | `gmModRegenValue` | STAM-04, default 0 |
| Combat vitality regen (additional) | `GMCombatVitalityRegen`, 0–1000 | 0 | 0 / 1 / 0 | `gmModRegenValue` (regen effect, its start, the panel) | OPT-03, default 0 |
| Out of combat vitality regen (additional) | `GMOutOfCombatVitalityRegen`, 0–1000 | 0 | 0 / 1 / 0 | `gmModRegenValue` | OPT-03, default 0 |
| Sprint/jump action cost modifier | `GMAgilityStaminaCostMultiplier`, −1–5 (60) | 0 (not written; unset reads 0) | 0 / 0 / 0 | `gmModAgilityStaminaCost` | STAM-03, default 0 |
| Melee action cost modifier | `GMMeleeStaminaCostMultiplier`, −1–5 (60) | 0 | 0 / −1 / 0 | `gmModMeleeStaminaCost` | STAM-03, default 0 |
| Sign action cost modifier | `GMSignStaminaCostMultiplier`, −1–3 (40) | 0 | 0 / 1.5 / 0 | `gmModSignStaminaCost` | STAM-03, default 0 |
| Stamina regen delay (additional, seconds) | `GMStaminaDelay`, −1–5 (60) | 0 | 0 / 0 / 0 | `gmModStaminaDelay` | STAM-06, default 0 |
| Melee special cooldown (seconds) | `GMMeleeSpecialCooldown`, 0–30 (60) | 7.5 | 7.5 / 0 / 0 | `GetMeleeSpecialCooldownDuration` | STAM-02, default 7.5 |
| Sign cooldown (seconds) | `GMSignCooldown`, 0–30 (60) | 5 | 5 / 0 / 0 | `GetSignCooldownDuration` | STAM-01, default 5 |
| Alternate Sign cooldown (seconds) | `GMAltSignCooldown`, 0–30 (60) | 7.5 | 7.5 / 0 / 0 | `GetAltSignCooldownDuration` | STAM-01, default 7.5 |
| (hidden) | `GMVersion`, `hideAlways` | 4.0 (always rewritten) | 4.0 / 4.0 / 4.0 | `gmLoadDefaultSettings` (empty: write the defaults); `GetGMVersion` has no caller | not ported (PO2) |

**QoL** (`GMQOLOptions`; presets "Recommended" / "Off"):

| Option (label) | Variable, type | Untouched (legacy) | Presets R / O | Read by (legacy) | Port |
|---|---|---|---|---|---|
| Instant sign casting with sign select key | `GMSignInstantCast`, toggle | off | on / off | `gmInstantCastingAllowed` (`OnSelectSign`, `TestCastSignHold`) | not ported: OPT-06 |
| Low stamina sfx threshold (percents) | `GMLowStaminaSFX`, 0–100 | 0 (no heartbeat) | 50 / 0 | `CheckForLowStamina` | STAM-07, default 50 ([DO4](#area-decisions)) |
| Low stamina sfx volume | `GMLowStaminaSFXVolume`, 0–100 | 0 | 100 / 0 | `CheckForLowStamina` | STAM-07, default 100 |
| Use dynamic low stamina sfx volume | `GMLowStaminaSFXDynamicVolume`, toggle | off | on / off | the regen's sound update | STAM-07, default on |
| Low stamina sfx rate | `GMLowStaminaSFXRate`, 0–100 | 0 | 0 / 0 | `CheckForLowStamina` | STAM-07, default 0 |
| Use dynamic low stamina sfx rate | `GMLowStaminaSFXDynamicRate`, toggle | off | on / off | the regen's sound update | STAM-07, default on |

**Enemy scaling** (`GMScalingOptions`, 12 variables, presets "Recommended", "Hardcore", "Off") and **Experience** (`GMExpOptions`, 4 variables, preset "Default"): all ported with their presets and labels by DIFF-04 and XP-07; the inventory is in [diff.md](diff.md#diff-04-enemy-scaling-options) and [xp.md](xp.md#xp-07-experience-options). With the menu untouched the scaling group plays the "Recommended" preset in the port (DD1, a deviation), the experience group as legacy.

The port's groups: "Enemy scaling" and "Experience" complete with presets; "Gameplay" with the skill tree toggle, WGT's three options (boat sinking, its threshold, item weight reduction; their mechanics are WGT's), the 11 stamina options and the 2 Vitality options, in legacy's order, with legacy's three presets; "QoL" with the five heartbeat options and legacy's two presets. `GMSignInstantCast` is not ported (DO5).

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

### Classification and action

| # | Feature | Class | Action |
|---|---|---|---|
| OPT-01 | Options framework | clean | Ported, with OPT-07's preset hooks and a gameplay change hook (PO2, PO4) |
| OPT-02 | Base Vitality regen 0 | clean | Legacy's (PO4) |
| OPT-03 | Vitality regen options | overlap | Legacy's options (PO4, PO5); 5.x's boost starts the regen (DO1); either option starts it (DO2) |
| OPT-04 | Boat sinking | clean | Legacy's, with WGT's over-encumbrance (PO6); on at 20% by default (DO3) |
| OPT-05 | Item weight reduction | overlap | Legacy's slider next to 5.x's aid, with WGT's weights (PO7, PO12) |
| OPT-06 | Instant sign casting | overlap | 5.x's "Quick Sign Casting" (DO5) |
| OPT-07 | Presets | clean | Legacy's (PO8); the QoL group's defaults are "Recommended"'s (DO4) |

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
| Port status | **signed off** (2026-11-02): the four groups with every option (gameplay: the skill tree toggle, WGT's three entries, STAM-01 to STAM-06's eleven, OPT-03's two; QoL: STAM-07's five; DIFF's scaling group and XP's experience group complete with presets), labels in 9 languages, per-option defaults, the QoL, scaling, Ciri, quest-level and gameplay (OPT-03) change hooks |
| Open checks | — |
| Save impact | none (options in the user settings) |
| NG+ counterpart | none |

**What it does:** Options → Mods → Ghost Mode with four groups: "Enemy scaling", "Experience", "Gameplay" (stamina, regen, cooldowns, weight, boat sinking; the port adds the skill tree toggle) and "QoL" (instant sign casting, low-stamina sound). Each group has presets. Options the player never set get Ghost Mode's defaults when a save loads. A changed option takes effect when the menu closes (the game is paused while it is open): the scaling group re-levels the NPCs around Geralt, "Disable quest levels" clears or reloads the quest levels, the QoL group restarts the heartbeat, the gameplay group (legacy) restarts Geralt's regen effects.

**Implementation (legacy):** `menu/modSignsConfig.xml` (groups `GMScalingOptions`, `GMExpOptions`, `GMGameplayOptions`, `GMQOLOptions`); `gm_generic/gm_options.ws` (`gmLoadDefaultSettings`, `gmSetGMVersion`, `gmIs*Option`); the getters in `W3GameParams` (scaling and experience read live; gameplay and QoL cached in fields, reset by `gmResetCachedValuesGameplay` and `gmResetCachedValuesQoL`); `CR4Game.gmUserSettingsScaling`, `gmUserSettingsQuestLevels`, `gmUserSettingsGameplay` (cache reset and `gmUpdateRegenEffects`), `gmUserSettingsQoL` (cache reset and the heartbeat restart); `CR4IngameMenu`: four flags (`gmHasChangedScalingOption`, `…QuestLevelsOption`, `…GameplayOption`, `…QoLOption`) set in `OnOptionValueChanged` (by `gmIs*Option`; the scaling group's id test there never matches, legacy's own comment) and `OnPresetApplied` (by group), acted on in `gmUserSettings`, called by `SaveChangedSettings` before `SaveUserSettings`; `CR4Player.OnSpawned` calls `gmLoadDefaultSettings`, which writes the gameplay group's defaults (the boat 20% on, weight 0, stamina and Vitality options 0, cooldowns 7.5, 5 and 7.5) only when `GMVersion` is empty, then sets `GMVersion` to "4.0". `GetGMVersion` has no caller. Labels: about 60 strings per language (`panel_*`, `option_*`, `preset_*`, `preset_value_*`), the panel name "Mods" among them.

**5.x:** pilot slice 5 verified that 5.x loads a mod's menu XML from `bin\config\r4game\user_config_matrix\pc\`, places `Mods.<name>` groups under Options → Mods (whose label `panel_mods` is 5.x's own), and that an unset option reads as `""` (a virtual `OPTIONS` variable as `"-1"`, DIFF-04). See [development.md](../development.md#options-menu). 5.x's `CR4IngameMenu` was rewritten (accessibility presets, new settings), so legacy's edits of its methods are ported as wrappers.

**Decisions:** port as is, with the menu file renamed to Ghost Mode's own name (`modGhostMode.xml`). Group and variable ids, label keys and string ids stay as in legacy, so existing translations carry over. Defaults are applied **per option** (any unset option gets its default when a save loads) instead of legacy's one-time `GMVersion` check, so options added by later features get their defaults on existing installs too; the getters fall back to the default while an option is empty. Options appear in the menu only once their feature is ported. The getters read the settings live (legacy cached the gameplay and QoL ones until the menu closed): the same values in play, so not a deviation. The rest (PO2, PO3): `GMVersion` and its two functions are not ported; nor is the "Mods" label 2110992000 (5.x's `panel_mods`).

- Not a deviation: with the menu never opened the port gives the gameplay group legacy's defaults, as legacy's code did. The scaling group's "Recommended" values (DD1) and the QoL group's (DO4) are recorded by DIFF-04 and at DO4.

**Slices:**

1. **The framework** (the pilot's gameplay group). Verified 2026-10-02 (`gmtest_opt01()`, scripted, and a screenshot of Options → Mods → Ghost Mode → Gameplay): the group registered and visible, labels, defaults written to the user settings, a changed option changes the STAM-01 cooldown. Each later group was verified with its feature (STAM-07, DIFF-04, XP-07, SKL-02); the scaling and experience groups were also seen on screen with real input (XP-07).

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
| Port status | **signed off** (2026-11-02); verified by script |
| Open checks | — |
| Save impact | none (expected: a base ability, read live) |
| NG+ counterpart | applied (0, legacy's NG+ value), untested |

**What it does** (changelist 474, "General player abilities"): Geralt no longer heals over time by himself, in or out of combat. Only food and drink, potions (Swallow), decoctions, skills, set bonuses, runewords, trophies and the OPT-03 options give him regeneration. Example: Geralt at level 20 (4,450 Vitality) who lost 1,000 in a fight gets nothing back by waiting; in 1.32 and 5.x he regains 1 per second, all of it in about 17 minutes. With a Bread eaten, or with OPT-03's out-of-combat option at 10, he does regenerate.

**Implementation (legacy):** `geralt_stats.xml` `ConGeralt`: `vitalityRegen` add 1 → 0, `vitalityCombatRegen` add 1 → 0 (the `mult` nodes already 0), regular and NG+. With every source at 0 the effect manager adds no automatic Vitality regeneration at all (`FilterAutoBuff` finds a null value); an ability that brings a regen stat starts it (legacy's `OnAbilityChanged`, FOOD-03's port).

**5.x:** 1.32's `ConGeralt` (1 and 1). 5.x's "Vitality Regeneration Boost" only acts while this regeneration runs, so the 0 meets it: [DO1](#area-decisions).

**Decisions:** legacy's (PO4). The changelist puts the line under "General player abilities"; no GEN area file exists, and the base value and the options (OPT-03) only make sense together, so OPT takes it (shared with GEN).

- **Geralt has no natural poison or bleeding resistance**, as legacy's data (`ConGeralt`'s `poison_resistance_perc` and `bleeding_resistance_perc` 0.25 → 0, regular and NG+; the changelist does not mention it, recorded in [open-questions.md](../open-questions.md#legacy-data-vs-changelist)) (owner, 2026-11-02): a fifth `ConGeralt` extend in `gm_stats.xml` (NG+ copy by `gen_ngplus.py`). Put here because OPT-02 is the entry for Geralt's base stats. Verified 2026-11-02 in both trees (`GMTest_opt02_resist` in the regression, the definition read).

**Slices:**

1. **Base regen 0** (with OPT-03). Verified 2026-11-02 by script (`GMTest_opt_o1`, in the regression): `ConGeralt`'s four nodes read 0 (5.x: 1 and 1); with the defaults no regen starts and the rate measured over a few seconds is 0/s (5.x: 1/s).

---

### OPT-03 Vitality regen options

| | |
|---|---|
| Kind | system |
| Pillars | P8 |
| 5.x class | overlap (5.x's "Vitality Regeneration Boost" adds to the same effect) |
| Flags | — |
| Depends on | OPT-01 (the menu), OPT-02 (base 0), FOOD-03 (the regen restart), ENCH-05 (the port's `W3Effect_AutoVitalityRegen.OnUpdate` wrapper), UI-05 (the panel lines) |
| Skill trees | n/a |
| Port form | the two options in the gameplay group (legacy's ids, `SLIDER;0;1000;1000`, after the stamina regen options as legacy) with defaults 0 and labels 2110992393, 394 in 9 languages; `options/vitalityRegen.ws`: `@wrapMethod(W3Effect_AutoVitalityRegen)` `SetEffectValue` adds the option for the regen in force after 5.x's value (5.x's boost stays in it); `@wrapMethod(W3EffectManager)` `StartVitalityRegen`: when 5.x starts no regen (Geralt has no regen stat), the effect is added as 5.x's own start adds it (`InternalAddEffect`, the manager's flag set) when `GMVitalityRegenStarts` holds (either option above 0, the boost on, or Geralt's own combat regen above 0); an `OnEffectAdded` wrapper keeps such a regen on (5.x switches off an effect whose value is 0 when added); the gameplay change hook (`gmVitalityRegenChanged` in `gmOptions.ws`'s menu wrappers: either option, the boost's switch, 5.x's accessibility preset, a gameplay preset) starts the regen when the menu closes; UI-05's `GMPanelVitalityRegen` adds the option |
| Port status | **signed off** (2026-11-02); verified by script in both trees |
| Open checks | — |
| Save impact | none (options in the user settings) |
| NG+ counterpart | none |

**What it does** (changelist 1235–1236): "Combat vitality regen (additional)" and "Out of combat vitality regen (additional)" add 0 to 1000 Vitality per second to Geralt's regeneration in or out of combat; both 0 by default (and in "Recommended" and "Off"), 1 each in "Vanilla(ish)", which gives back 1.32's 1 per second. They act at once when the menu closes. The character panel's two regen lines include them. Example: out of combat at 10 and nothing else, Geralt at 3,450 of 4,450 is full in 100 seconds; in combat at 5 with a Swallow (+40, ALCH) he regains 45 per second.

**Implementation (legacy):** `gmModRegenValue` adds `GetOutOfCombatVitalityRegen` to `vitalityRegen` and `GetCombatVitalityRegen` to `vitalityCombatRegen`; it is called in `W3Effect_AutoVitalityRegen.SetEffectValue` (Geralt only), in `W3EffectManager.FilterAutoBuff` (whether the automatic regen may start: it reads `vitalityRegen`, the out-of-combat stat, only) and in `AddCharacterStat`'s two Vitality regen lines; `gmUpdateRegenEffects` (from `gmUserSettingsGameplay`) updates the running regen effects and starts them when absent; `W3Effect_AutoVitalityRegen`'s `wasLoaded` (set in `OnLoad`) recomputes the value at the first update after a load.

**5.x:** no such options. 5.x's `W3Effect_AutoVitalityRegen` recomputes Geralt's value on every update (so `wasLoaded` has nothing to add) and adds the "Vitality Regeneration Boost" when that aid is on: +1 per second above its threshold, up to (1.1 × its multiplier) below it, while the effect runs.

**Decisions:** legacy's (PO4, PO5); the boost with Geralt's base 0: DO1 (b), switching the boost on also starts the regen (not a deviation: legacy had no such aid). A running regen recomputes its value each update in 5.x, so legacy's value refresh (`gmUpdateRegenEffects`) and `wasLoaded` are not needed. Regen is still Geralt's only (`W3PlayerWitcher`), as legacy's `gmModRegenValue`; Ciri gets neither. The panel's lines show Geralt's regen with the options, without 5.x's boost (PO5). Every other source of Geralt's Vitality regen in the port's data (food and drink, Swallow and the decoctions, Mutation 11, the Bear pheromone, runes, glyphs and runewords, the Noonwraith trophy, Undying in both trees, the new tree's `perk_1_day_ability` and `perk_38_day_ability`) has an out-of-combat part and starts the regen through the game's own rule; the Tvarog rune was the only one without.
- **Deviation:** Geralt's Vitality regen starts when either Vitality option is above 0; legacy's start read only the out-of-combat value, so "Combat vitality regen" alone gave nothing unless food or a potion had started the regen. A fix, so that the option works as its label says (owner, DO2, 2026-11-02).
- **Deviation:** Geralt's Vitality regen also starts when his own combat Vitality regen is above 0, so the Tvarog rune's +5 per second in combat (ENCH-16, the only source with a combat value and no out-of-combat one) works on its own, as its tooltip and the character panel say; with legacy's start rule and base 0 it gave nothing unless food, a potion or the out-of-combat option had started the regen. DO2's fix extended (`GMVitalityRegenStarts` in `options/vitalityRegen.ws`, read by the start wrapper and the keep-on test; OPT audit F1) (owner, 2026-11-02).

**Slices:**

1. **Vitality regen options.** Verified 2026-11-02 by script in both trees (`GMTest_opt_o1`, in the regression; rates measured with `gmtest_opt_o1_a`/`_b`, Vitality at 50%, a 1-point drain starting the regen as a hit does): the regen starts with the out-of-combat option, with the combat option alone (DO2), with the boost alone (DO1) and with the Tvarog rune alone (`GMTestOptO1Tvarog`); the effect's values and the panel's two lines equal Geralt's own regen plus the options; in a fight against a frozen hostile dummy the combat option gives its rate and the out-of-combat option alone gives 0; through the menu's path a changed option or the boost starts the regen when the menu closes, an unchanged 0 does not. Each check failed first on a build without the code.

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
| Port form | OPT's part: the toggle `GMSinkBoat` and the threshold slider `GMSinkBoatOverEnc` (`SLIDER;0;100;100`) in the gameplay group, first after the port's skill tree toggle as legacy, defaults on and 20 (DO3) in `GMOptionDefault`, labels 2110992180 and 181 in 9 languages. WGT's part (WGT-10): the single `@replaceMethod(W3Boat)` `OnAreaEnter` with legacy's sinking branch, `CheckPlayerEncumbrance` and the message 2110992179 |
| Port status | **signed off** (2026-11-02): the entries verified by script (`GMTest_opt_o0` in the regression: place in the group, type, label = string id, default, value written at the load, the getters); the sinking is WGT-10's, checked through these entries (`GMTest_wgt06`) |
| Open checks | — |
| Save impact | none (expected) |
| NG+ counterpart | none |

**What it does** (changelist 934–935, 1229–1232): when Geralt steps onto a boat while over-encumbered by more than the threshold (20% of his run carry limit by default), the boat sinks under him: its drowning starts, the sinking sound plays and the HUD says "Your over encumbrance is too high". Under the threshold, or with the option off, he boards as usual. Example: with a carry limit of 100, Geralt at 125 sinks the boat, at 115 he boards it (over-encumbered, with WGT's penalties). Not while a save is loading, and not for a boat that cannot be destroyed (its `canBeDestroyed` off; with 5.x's "Unlimited Boat Durability", every boat).

**Implementation (legacy):** `W3Boat.OnAreaEnter`, the `OnBoatTrigger` branch: if the option is on, the boat has its component, no load is in progress (`GetLoadGameProgress() == 0`), the boat can be destroyed and `CheckPlayerEncumbrance` holds, `TriggerDrowning` at Geralt's position, `SetHasDrowned(true)`, `SoundEvent("boat_sinking")` and `DisplayHudMessage("gm_geralt_too_heavy")`; else the vanilla interactions. `CheckPlayerEncumbrance`: Geralt has `EET_OverEncumbered` and (weight ÷ run limit − 1), clamped to 0…1, × 100 is above the threshold.

**5.x:** `OnAreaEnter` is 1.32's; `GetCanBeDestroyed` also reads "Unlimited Boat Durability" (DIFF's DD3 keeps it). The over-encumbrance effect and limits are WGT's.

**Decisions:** legacy's (PO6); the default: DO3 (on at 20%). The mechanics are WGT's; OPT owns the entries.

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
| Port form | OPT's part: the slider `GMEncumbranceMultiplier` (`SLIDER;0;100;100`) in the gameplay group after the boat options, default 0, label 2110992183 in 9 languages. WGT's part (WGT-02): the factor inside the single `@replaceMethod` of `CInventoryComponent.GetItemEncumbrance` (legacy's body: weight at least 0.01, × quantity × (1 − option ÷ 100), under 0.01 counts 0) |
| Port status | **signed off** (2026-11-02): the entry verified by script (`GMTest_opt_o0`, as OPT-04's); the reduction is WGT-02's, checked through this entry (`GMTest_wgt04`) |
| Open checks | — |
| Save impact | none (expected; the weight is recomputed when the inventory changes) |
| NG+ counterpart | none |

**What it does** (changelist 1233): every item Geralt carries weighs (100 − the option)% of its weight; 0 by default and in all three presets. Example: at 30% a 10-weight armor counts 7 and a stack of 20 herbs at 0.1 counts 1.4; at 100% nothing weighs anything (5.x's "Ignore Item Weight" gives the same).

**Implementation (legacy):** `GetEncumbranceMult` (the option ÷ 100, clamped 0…1); `GetItemEncumbrance`: for an item that counts (`IsItemEncumbranceItem`), max(weight, 0.01) × quantity × (1 − factor), 0 below 0.01; legacy also dropped 1.32's category rules there (quest items and keys at 0.01, usable items, upgrades and junk at a fifth, the rest at half, plus 0.01) and added a debug fact (`modSigns_debug_zero_enc`): WGT's.

**5.x:** `GetItemEncumbrance` is 1.32's; "Ignore Item Weight" returns early in `IsItemEncumbranceItem` and `GetEncumbrance`, so with it on the option has nothing to act on.

**Decisions:** legacy's slider next to 5.x's aid (PO7, PO12). The factor is WGT's; OPT owns the entry.

---

### OPT-06 Instant sign casting

| | |
|---|---|
| Kind | system |
| Pillars | P8 |
| 5.x class | overlap (5.x's "Quick Sign Casting") |
| Flags | — |
| Depends on | OPT-01, STAM-01 (the cooldown check on `OnCastSign` and on 5.x's `AltCastSign`), ARM-07 (the port's `W3SignOwnerPlayer.ChangeAspect`, `armor/gryphonSet.ws`), MUT-12 (`ShouldStopChanneling`), EFX-10 (the web's key release) |
| Skill trees | n/a (signs of both trees alike) |
| Port form | none in the menu (DO5): 5.x's "Quick Sign Casting" serves; `options/instantCasting.ws`, a second `@wrapMethod(W3Effect_Tangled)` `OnEffectAdded` (after EFX-10's abort) that releases the five sign-select keys while 5.x's setting is on (PO13, `GMWebReleaseSignSelectKeys`); STAM-01's cooldown check already sits on 5.x's `AltCastSign` |
| Port status | **signed off** (2026-11-02); verified by script |
| Open checks | on screen with real keys: a select key's cast, the hold (an alternate cast, a channel kept going and aborted on release), a web during a held channel |
| Save impact | none |
| NG+ counterpart | none |

**What it does** (changelist 1246–1247): with the option on, pressing a sign's select key (3 to 7 by default) selects the sign and casts it at once (refused while it is on cooldown, STAM-01); keeping the key held for more than 0.2 s counts as holding the cast key: the alternate cast where a skill allows it, and a channeled sign (Firestream, the active Quen shield, Puppet) keeps going until the key is released. Off unless the player turns it on or applies the QoL "Recommended" preset. Example: with Igni selected, pressing Aard's select key throws an Aard; holding it casts the alternate Aard (Aard Sweep).

**Implementation (legacy):** `CPlayerInput.OnSelectSign` (after setting the sign: if the option is on, the press time stored by `SetCastSignHoldTimestamp` and `CastSign()`, STAM-01's cooldown check included); `TestCastSignHold` (the cast key held, or with the option a select key pressed for more than 0.2 s) in place of `GetActionValue('CastSignHold')` in `W3SignOwnerPlayer.ChangeAspect` (the alternate cast), `W3SignEntityStateChanneling.ShouldStopChanneling`, `W3PlayerWitcher.OnProcessCastingOrientation` (three places), `CR4Player.OnDelayOrientationChange` and `DelayOrientationChangeTimer`; `ForceDeactivateCastSignHold` (the cast key and the five select keys) in the spider web (`W3Effect_Tangled.OnEffectAdded`, EFX-10). The timer's test is inverted: legacy put `TestCastSignHold()` where 1.32 tested "the cast key is released", so the delayed turning during a sign cast ends while the key is still held instead of on its release, with or without the option (from the code; how it played: the [legacy test list](../open-questions.md#to-test-in-legacy-ghost-mode)).

**5.x:** "Quick Sign Casting" (Gameplay, `EnableAlternateSignCasting`, off by default) does the same on a keyboard, from the code: `OnSelectSign` calls `AltCastSign` (refused without stamina or with the sign blocked; STAM-01 already wraps it with the cooldown check), `ShouldStopChanneling` keeps a channel going while a select key is held, releasing it aborts the channel (`OnSelectSign`), and `ChangeAspect`'s keyboard branch reads the select keys for the alternate cast. Its tutorial speaks of a controller only; how its hold works on a keyboard (the threshold) is not read and not seen. Porting legacy's toggle too would put two systems on the same keys.

**Decisions:** DO5 (a), owner 2026-11-02: 5.x's "Quick Sign Casting" serves as instant casting; legacy's toggle, its input code (`TestCastSignHold`, the press timestamp, `ForceDeactivateCastSignHold` in its own form) and its QoL preset entry are not ported. The web's release of the select keys closes EFX-10's PX9 item.
- **Deviation:** legacy's "Instant sign casting with sign select key" (a QoL toggle, on in the QoL "Recommended" preset) is not ported; 5.x's own "Quick Sign Casting" (Options → Gameplay, off by default) gives the same: a select key casts its sign, holding it keeps a channeled sign going, releasing it aborts the channel. It differs in that the setting lives in 5.x's Gameplay settings under 5.x's name, Ghost Mode's QoL presets do not switch it, the alternate cast comes from 5.x's hold rule instead of legacy's 0.2 s, a select-key press refused for the sign's cooldown or for stamina keeps the old sign (legacy selected the sign first, so the cast key would then cast it), and legacy's inverted orientation timer does not come with it (owner, DO5, 2026-11-02; the refused press added from the OPT audit's F5, 2026-11-02).
- **Deviation:** legacy's inverted turning during a held sign cast is not ported, for every player, with or without instant casting: legacy's `DelayOrientationChangeTimer` read `TestCastSignHold()` where 1.32 tested the cast key's release, so Geralt's delayed turning toward the aim ended while the cast key was still held instead of when it was released; the port keeps 1.32's and 5.x's turning (a defect of legacy's, not a rule; OPT audit F4) (owner, 2026-11-02).

**Slices:**

1. **Instant casting.** Verified 2026-11-02 by script in both trees (`GMTest_opt_o3`, in the regression): no toggle in the QoL group, 5.x's setting in its Gameplay group; with 5.x's setting switched on through the menu's path, a select key pressed by script through `CPlayerInput.OnSelectSign` (`gmtest_opt_o3_select`/`_after`) casts its sign; on cooldown or without stamina the press is refused and the sign not selected; with the setting off the key only selects. A spider web (`EET_Tangled` added as the projectile adds it) releases the select keys with the setting on, not with it off; failed first without the release.

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
| Port status | **signed off** (2026-11-02); verified by script in both trees |
| Open checks | the menu on screen (the order, the preset labels) |
| Save impact | none |
| NG+ counterpart | none |

**What it does** (changelist 1226–1228, 1245): one choice sets a whole group. Gameplay "Recommended": boat sinking on at 20%, no weight reduction, no armor regen penalty, regen and cost options 0, cooldowns 7.5 (Whirl and Rend), 5 (signs) and 7.5 (alternate signs): Ghost Mode as designed. "Vanilla(ish)": no boat sinking, the armor regen penalty on, stamina regen 15 → 10 per second in combat (−5), Vitality regen 1 and 1 per second (1.32's), melee actions free (−1: cost × 0), signs costing the whole bar (+1.5: 40 × 2.5 = 100), no cooldowns: close to 1.32's stamina rules. "Off": everything 0 and off (no sinking, no cooldowns, Ghost Mode's base costs and regen). QoL "Recommended": instant casting on, the heartbeat below 50% at full volume, dynamic volume and rate; "Off": instant casting and the heartbeat off. A preset applied takes effect when the menu closes, like a changed option.

**Implementation (legacy):** the preset arrays in `modSignsConfig.xml` (each also writes `GMVersion` "4.0"); `OnPresetApplied` sets the group's flag; the labels.

**5.x:** the same preset mechanism (DIFF-04's and XP-07's presets work through it).

**Decisions:** legacy's (PO8), without `GMVersion` (PO2), the skill tree toggle (PO8) and `GMSignInstantCast` (DO5); the QoL defaults with the menu untouched: DO4 (a). The gameplay group in legacy's order (PO3).
- **Deviation:** with the options menu never opened, the QoL group has the "Recommended" preset's values, so the low-stamina heartbeat plays below 50% stamina; legacy's code wrote no QoL defaults, so its heartbeat stayed off until the player chose it. The changelist presents the cue as a feature that can be switched off, and DIFF's DD1 took "Recommended" for the scaling group the same way (owner, DO4, 2026-11-02).

**Slices:**

1. **Presets and order.** Verified 2026-11-02 by script in both trees (`GMTest_opt_o2`, in the regression; it hard-codes legacy's values, not the port's file): the gameplay group's 16 options in legacy's order; each preset applied sets legacy's values, leaves the skill tree toggle alone and plays as described (cooldowns, sign and attack costs, regen); the QoL and gameplay defaults equal "Recommended". Through the menu's path, "Vanilla(ish)" starts Geralt's stopped Vitality regen and the QoL presets stop and start the heartbeat. Each check failed first on a build without the presets.

---

### Dependencies on other areas

- **Areas OPT builds on:** STAM (the stamina options and the QoL group's hook), DIFF-04 (the preset mechanism, labels 448 and 449), XP-07, SKL-02 (the skill tree toggle), FOOD-03 (the regen restart on a regen ability), ENCH-05 (the Vitality regen effect's `OnUpdate` wrapper), UI-05 (the panel lines), EFX-10 (the web), ARM-07 and MUT-12 (the sign methods instant casting reads).
- **Areas OPT shares with:** WGT (over-encumbrance and item weights for OPT-04 and OPT-05), GEN (the base Vitality regen line; no area file), DIFF's DD3 (the accessibility aids that meet OPT-03 to OPT-05).

### Save impact

None: the options live in the user settings, `ConGeralt` is read live, the regen effect recomputes its value on every update. Removing the mod mid-playthrough is unsupported ([save compatibility](../feature-mapping.md#save-compatibility)).

### Area decisions

**Decided by the owner (2026-11-02), every one as recommended:** DO1 (b) switching on 5.x's "Vitality Regeneration Boost" also starts the regen; DO2 (b) the regen starts when either Vitality option is above 0 (a fix, a deviation); DO3 (a) boat sinking on at 20% by default (WGT's DW3); DO4 (a) the heartbeat on with the menu untouched (a deviation); DO5 (a) 5.x's "Quick Sign Casting" instead of legacy's toggle (a deviation). The table keeps the questions as they were put.

| # | Question | Options | Recommendation |
|---|---|---|---|
| DO1 | 5.x's "Vitality Regeneration Boost" with Geralt's base regen at 0 (OPT-02, OPT-03). Legacy: no such aid. 5.x: the aid adds to Geralt's automatic Vitality regeneration while it runs (+1/s above its threshold, more below it); DIFF's DD3 kept it, assuming it adds to Ghost Mode's regen. With legacy's base 0 the automatic regeneration does not run unless food, a potion, a skill or an option gives some, so the aid does nothing most of the time | (a) legacy's rule only: the aid works while some regen runs (after a Bread, under Swallow), else nothing; (b) the aid also starts Geralt's regeneration when it is switched on, as 5.x intends (its +1/s, and its boost below the threshold), with or without other regen; with the aid off (the default) everything is legacy's | **(b)**: DD3 kept the aid for players who want it; with (a) it is switched on and silently does nothing. Not a deviation: legacy had no such aid, and with it off the game plays as legacy |
| DO2 | The combat Vitality option on its own (OPT-03). Legacy's code lets the automatic regeneration start only when the out-of-combat value is above 0 (`FilterAutoBuff` reads `vitalityRegen` only); with base 0, "Combat vitality regen" at 20 and "Out of combat" at 0, Geralt regains nothing in a fight unless food or a potion started the regeneration (from the code; the [legacy test list](../open-questions.md#to-test-in-legacy-ghost-mode)) | (a) legacy's code: the combat option acts only while something else runs the regeneration; (b) start the regeneration when either option is above 0 (a fix, a deviation): at 20 Geralt regains 20 per second in every fight | **(b)**: a defect that keeps the option from working as its label and the changelist say; both options start it in (b), so the out-of-combat one is unchanged |
| DO3 | Boat sinking's default (OPT-04): a **contradiction**. The changelist's weight section says "off by default" (line 935); its "Mod options" section says "Recommended" enables it, and legacy's code writes it on (20%) at the first load and in "Recommended" | (a) the code: on at 20% with the menu untouched; (b) the changelist line: off until the player turns it on (the threshold still 20%) | **(a)**: the code is the better guide ([rule](../feature-mapping.md#legacy-behaviour-first)), and two of the three sources (code, the options section) agree. Recorded in [open-questions.md](../open-questions.md#legacy-data-vs-changelist) |
| DO4 | The QoL group with the menu untouched (STAM-07, OPT-07). Legacy's code writes no QoL defaults, so with the menu never opened the heartbeat is off (threshold 0) and instant casting off until the player applies "Recommended" (or sets them). The port gives the QoL options "Recommended"'s values since STAM-07 (the heartbeat on below 50%), not recorded as a deviation | (a) keep the port's: the heartbeat on with the menu untouched; record it as a deviation, as DIFF's DD1 for the scaling group; instant casting off either way (DO5); (b) legacy's code: no heartbeat until the player chooses it | **(a)**: the changelist presents the cue as a feature that "can be switched off", and DD1 already took "Recommended" for the scaling group; the heartbeat was tested and listened to by the owner with these values |
| DO5 | Instant sign casting (OPT-06). Legacy: a QoL toggle (off by default, on in "Recommended"); a select key casts, held over 0.2 s it is the cast key held. 5.x: "Quick Sign Casting" in Gameplay does the same on the keyboard, from the code (select key casts, hold to channel, release aborts; the alternate cast from the select keys), off by default | (a) use 5.x's setting: legacy's toggle not ported, the QoL presets without it, legacy's input code not ported (a deviation: the option lives in 5.x's Gameplay settings, under its name, with 5.x's hold rule, and "Recommended" does not turn it on); (b) port legacy's toggle and code next to 5.x's (two systems on the same keys: with both on, one key press could start two casts or conflict); (c) Ghost Mode's toggle in QoL that switches 5.x's setting (the presets work as legacy's; two places show one setting, which can disagree if the player changes 5.x's) | **(a)**: 5.x built the feature into the game with STAM-01's cooldown already on its path; (b) duplicates it and needs the six input methods replaced; legacy's inverted orientation timer would come with it (fixed or kept). An in-game check of 5.x's setting on a keyboard (a select key casts, the hold, a cooldown refusal) goes into the slice |

### Porter's calls

Each follows legacy or has no play effect; confirmed by the owner (2026-11-02).

| # | Call |
|---|---|
| PO1 | OPT is ported as one area with one audit at the end; OPT-04's and OPT-05's mechanics are ported by WGT (PO6, PO7) |
| PO2 | OPT-01 stays as ported: per-option defaults (no `GMVersion`, `gmSetGMVersion` or `GetGMVersion`; legacy's "re-apply your Gameplay settings after updating" has no counterpart), live getters (no `gmResetCachedValues*`), legacy's ids and label keys; the "Mods" label 2110992000 not ported (5.x's `panel_mods`) |
| PO3 | The gameplay group in legacy's order, with the port's skill tree toggle first: boat sinking, threshold, item weight, armor regen penalty, stamina regen (combat, out of combat), Vitality regen (combat, out of combat), the three cost modifiers, regen delay, Whirl and Rend cooldown, sign cooldown, alternate sign cooldown |
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

**Later:** none recorded.
