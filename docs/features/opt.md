# OPT: mod options

Ghost Mode's settings menu and the code that reads, defaults and caches the settings. Partly mapped: only what the [STAM](stam.md) pilot needs.

---

### OPT-01 Ghost Mode options framework

| | |
|---|---|
| Kind | infra |
| Pillars | P8 |
| 5.x class | clean |
| Flags | — |
| Depends on | — |
| Port form | menu XML (`modGhostMode/menu/modGhostMode.xml`); option labels in the string table; `scripts/local/gm/options/gmOptions.ws` (defaults, getters); `@wrapMethod` on `CR4Player.OnSpawned` (defaults) |
| Port status | in progress: the gameplay group with the options of ported features (so far STAM-01's two cooldowns, STAM-04's two regen options, STAM-05's armor regen toggle and STAM-02's melee special cooldown STAM-03's three cost modifiers and STAM-06's regen delay), the QoL group with STAM-07's five low-stamina sound options, labels (en, ru, cz), per-option defaults, the QoL group's restart on change in the menu (`GMOnQoLOptionsChanged`); next: each feature adds its options as it is ported; presets and the other groups with their features |
| Save impact | none (expected) |
| NG+ counterpart | none |
| Verified in game | partly: 5.0 hotfix, 2026-10-02, `gmtest_opt01()` (group registered and visible, labels, defaults written to `dx12user.settings`, a changed option changes the STAM-01 cooldown, 0 turns it off) and a screenshot of Options → Mods → Ghost Mode → Gameplay |

**What it does:** Options → Mods → Ghost Mode with four groups: enemy scaling, experience, gameplay (stamina, regen, cooldowns, encumbrance, boat sinking) and quality of life (instant sign casting, low-stamina sound). Each group has presets (recommended, hardcore, vanilla-ish, off). Unset options get Ghost Mode's defaults when a save loads. Settings are cached in `W3GameParams` and re-read when they change.

**Implementation:** `menu/modSignsConfig.xml` (groups `GMScalingOptions`, `GMExpOptions`, `GMGameplayOptions`, `GMQOLOptions`); `scripts/gm_generic/gm_options.ws` (`gmLoadDefaultSettings`, `gmIs*Option`, `gmSetGMVersion`); `W3GameParams.gmResetCachedValuesGameplay`; `CR4Game.gmUserSettingsGameplay/QoL` (re-read on change); `CR4Player.OnSpawned` calls `gmLoadDefaultSettings`. Labels: about 40 strings in `localization/modGhostMode/<lang>.csv` (not yet attributed: CSV units are keyed by id).

**5.x:** pilot slice 5 verified that 5.x loads a mod's menu XML from `bin\config\r4game\user_config_matrix\pc\`, places `Mods.<name>` groups under Options → Mods, and that an unset option reads as `""` (which is what `gmLoadDefaultSettings` handles). See [development.md](../development.md#options-menu).

**Port notes:** group and variable ids, label keys and string ids stay as in legacy, so existing translations carry over. Defaults are applied **per option** (any unset option gets its default when a save loads) instead of legacy's one-time `GMVersion` check, so options added by later features get their defaults on existing installs too; the getter `GMGetOptionFloat` also falls back to the default while an option is empty. Options appear in the menu only once their feature is ported.

**Decision (proposed):** port as is, with the menu file renamed to Ghost Mode's own name.
