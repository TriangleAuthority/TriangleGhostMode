# Design pillars

The principles Ghost Mode is built on, taken from [legacy-ModDescription.txt](../legacy-ModDescription.txt) and [legacy-FullChangelist.txt](../legacy-FullChangelist.txt). Every feature names the pillars it serves. When 5.x breaks how a feature works, the pillar is what the port preserves; the mechanism is rebuilt on 5.x's systems (see [feature-mapping.md](../feature-mapping.md#two-layers-pillars-and-features)).

| # | Pillar | What it means in practice |
|---|---|---|
| P1 | **Armor must be penetrated** | Damage = (weapon damage − armor) × attack power × (1 − resistance). Attack power only scales what gets through armor, so damage does not snowball and armor, armor piercing and strong attacks matter. |
| P2 | **Combat is a stamina economy** | Every combat action costs stamina, for the player and for NPCs; running out limits what you can do. |
| P3 | **Signs are limited by cooldowns, not by draining all stamina** | Signs cost a moderate amount of stamina and have a cooldown, so they are tools to weave into melee instead of an all-or-nothing resource dump. |
| P4 | **Armor classes are distinct trade-offs** | Light, medium and heavy armor differ in resistances and in stamina costs and regen. |
| P5 | **Enemy types are distinct** | Enemies differ in armor, resistances, dodging and parrying, so each type calls for different tactics. |
| P6 | **Loot and money are scarce** | Prices, loot and crafting are rebalanced so that rewards mean something. |
| P7 | **Descriptions are accurate and consistent** | Skills, items and effects describe exactly what they do, with consistent terms. |
| P8 | **Close to vanilla in spirit** | The game's basics and feel stay recognizable; Ghost Mode fixes and deepens rather than replaces. |
| P9 | **Defence is precise and decisive** | A clean dodge, parry or counter negates the attack and its effects; a partial one (a graze, a partial parry or counter) halves it; a counter is rewarded. Added 2026-10-03 (project owner) for the DEF area. |
| P10 | **Progression is paced** | Experience and levels follow the content smoothly: less for content below the player's level, more above it, diminishing returns for repeated kills, no difficulty modifiers, quest levels that make sense, so the character's growth keeps pace with the game instead of outrunning it. Added 2026-10-03 (project owner); covers the XP area and how skills are bought (with SKL). |
