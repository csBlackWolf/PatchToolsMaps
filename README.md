# PatchToolsMaps

Optional world map tools for **World of Warcraft: Forever**, with built-in **English and German** language support. Made by **Patch & Zen**.

**Requires [PatchTools](https://www.curseforge.com/wow/addons/patchtools).** Adds a **Map** section to the PatchTools settings.

[CurseForge project](https://www.curseforge.com/wow/addons/patchtoolsmaps) · [Source code](https://github.com/csBlackWolf/PatchToolsMaps)

## Features

- Move the world map with a drag bar.
- Resize it with a small square handle at the bottom-right corner.
- Save your preferred position and size between sessions.
- Use the native mouse-wheel zoom. The extra zoom step is temporarily disabled for combat compatibility.
- Choose **Classic**, **Semi-transparent fog** (default), or **Fully revealed** for unexplored areas.
- Reset position, size and zoom with one button. An open map closes so it can rebuild cleanly when reopened.

Reveal changes only the map display. It does not grant exploration, experience or achievements. Map coverage depends on the supported client build.

## Availability and requirements

**Requires PatchTools 0.7.0 or newer.** Install or update the base addon before enabling PatchToolsMaps. PatchTools 0.6.0 does not support this module.

Currently tested on **Forever Beta 1.60.1, build 70532**. Other WoW editions and newer builds are not yet confirmed. Window movement, resizing and zoom have passed initial in-game checks.

## Installation

Install **PatchTools** and **PatchToolsMaps** together. For manual installation, place both folders next to each other in your WoW `Interface/AddOns` folder, for example:

```text
World of Warcraft/_forever_beta_/Interface/AddOns/PatchToolsMaps
World of Warcraft/_forever_/Interface/AddOns/PatchToolsMaps
```

Some existing beta installations use `_classic_beta_` instead. Choose the folder used by your game. Do not put PatchToolsMaps inside the PatchTools folder.

## Controls and languages

- Open **`/patchtools`**, then choose **Map** (German: **Karte**).
- Drag the top bar to move the map; drag the square corner handle to resize it.
- Use the mouse wheel to zoom.
- Use **Reset map position, size and zoom** to restore the default view.
- English and German follow your game language; other languages use English.

## Reporting issues and suggesting features

[Open an issue](https://github.com/csBlackWolf/PatchToolsMaps/issues/new/choose) for a bug or an idea. Tell us what happened, what you expected, and your WoW, PatchTools and PatchToolsMaps versions. Screenshots and error messages help but are optional. Please leave out account details and private chat. English and German are welcome.

## License

[MIT](LICENSE.txt). You may change and share the project while keeping the copyright and license notice.

## Changelog

### 2026-10-23 — 0.1.0

First regular release. Requires PatchTools 0.7.0 or newer.

- Keep move/resize controls visible during combat; ignore drag attempts until combat ends.
- Avoid modifying Blizzard's zoom table or registering addon textures in its shared mask list.
- Keep the additional zoom step disabled for combat compatibility; ordinary zoom is unchanged.

- Added optional map settings, movement and resizing.
- Added three display modes for unexplored areas.
- Added saved window settings and a reset button that closes an open map.
- Fixed opening the map before its zoom levels are ready.
- Replaced the pointed decoration with a compact square resize handle.

Developer notes: [DEVELOPMENT.md](DEVELOPMENT.md). Client-data generation: [tools/README.md](tools/README.md).
