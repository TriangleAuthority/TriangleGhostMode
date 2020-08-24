Ghost Mode v4.0 by wghost81 aka Wasteland Ghost
===============================================

Since v4.0 Ghost Mode requires Community Patch - Base and Shared Imports to work! All my other
mods that are compatible with Unification Patch are also compatible with Community Patch, so
don't worry - you can update safely.

If you're upgrading from one of the previous mod version, remove the mod completely before
installing v4.0. Use cleardevelop in console after updating to reset your character development
and update skill trees. Nothing is lost when you use it with the mod, you just need to reassign
your skillpoints again.

Installation
============

The mod requires Community Patch - Base and Shared Imports installed to compile properly.

It's recommended to install the mod using The Witcher 3 Mod Manager - it handles installing and
uninstalling the mod and its menu automatically. For manual install see the instructions below.
Remember, though, that mod manager does not resolve mod conflicts, you still need Script Merger
for this!

If you have any other mods installed, use Script Merger to find and resolve conflicts.

Compatibility with specific mods:
* Preparations - do not merge effects_ep2.xml file. Make sure the one from Ghost Mode has a
  priority (should be like this by default as modGhostMode is loaded before modPreparations).
* Nitpicker's Patch - do not merge bundled xml files, but make sure Ghost Mode has higher
  priority (is first in conflicts list). Loading order can be easily changed by renaming
  modNitpicker folder to modZNitpicker.
* Besserwisser's Patch - do not merge anything (including scripts!), but make sure Ghost Mode
  has higher priority (is first in conflicts list).
* All NPC Scabbards - do not merge bundled xml files, but make sure Ghost Mode has higher
  priority (is first in conflicts list). Nitpicker's Patch priority is irrelevant as Ghost Mode
  overrides both. Loading order can be easily changed by renaming modScabbards folder to
  modZScabbards.
* Better Icons mod - do not use xml versions of the mod as there are a lot of conflicts with
  Ghost Mode, but use version that changes icons themselves instead (search the Nexus for the
  one that corresponds to your language).

General merging advice: no other mod should override GM's files (ws, w3ent, xml, etc.)! If you
allow another mod to take priority, the game might run and even seem OK, but later you will
inevitably encounter things like wrong levels or abilities on NPCs. One-shotting the final boss
of the game is no fun and it can happen if you ignore this warning!

IMPORTANT NOTICE: please, exit the game and re-run it after script compilation is done. It was
discovered that playing the game without doing so might result in weird bugs occurring, such as
invalid (-1) number of potions, probably, something else. The nature of this bug is unknown,
but the above procedure should prevent it from happening.

RECOMMENDED MOD SETTINGS: use default/recommended presets in mod's options menu.

Installation (manual)
=====================

Install the mod by unpacking both modGhostMode and modGMTutorials it into
[Path to The Witcher 3]\Mods folder. Run Script Merger to find and resolve conflicts.

For in-game menu to work you need to copy [Path to The Witcher 3]\Mods\modGhostMode\bin
folder into your [Path to The Witcher 3] folder.

Uninstallation (manual)
=======================

Delete both modGhostMode and modGMTutorials from [Path to The Witcher 3]\Mods folder. Run
Script Merger to fix merged scripts.

Delete [Path to The Witcher 3]\bin\config\r4game\user_config_matrix\pc\modSignsConfig.xml.

If you want to continue playing with your GM character after uninstaling the mod, you will
need to install cleardevelop mod after uninstaling GM and type cleardevelop command in console.
You will also need to drop most of your items as they will have weird stats and respawn them
with console.

Thanks
======

- KasparsBITELV for permission to use parts of his Witcher Book Collection mod.
- Murzinio for original Razor Shaving mod.
- Wolfmark for Generic Merchants Fix.
- FreeSergey for his ideas, original cooking recipes and fixes.
- delamer for his ideas, cooking recipes and testing.
- SilversParlor for the header, logo and headlines.
- ViNT-1369 for playtesting the very early beta.
- FlynTie aka Chris.R and Moahofer30 for German translation.
- Denroth for Italian translation.
- Belzebox and lexo1000 for French translation.
- cavecanem and Spontan for Polish translation.
- lucard1984 and Musashiro for Brazilian Portuguese translation.
- udo and Kenny for Spanish translation.
- KNG for useful suggestions.
- KoalaNalle for various w2ent fixes.
- erxv for permission to use his Alternate Aard ripple fix.
- Polakowicz for permission to use his Ciri cutscenes sword bugfix.
- Reaper for useful suggestions and playtesting.
- lynn for being lynn.
- classboy05 for being nitpicky.
- Zym for brainstorming sessions and math. Lots of math.
- Spacecop42, Avaritica, Drum_Machinist, Remos, LaMurchik, combatmaster1o3, Monsieurbz75,
  slave.exe, Das, Kimura, Hi i'm Royeen, DreamGothic, Lexonn, kayjay, Pelmen and all the other
  beta players.
- Everyone who continues to support the mod on Nexus, Discord and Patreon, offers their help
  with localizing and testing the mod.
