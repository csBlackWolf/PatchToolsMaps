# PatchToolsMaps

**Experimental branch: custom Classic Era frame, 0.3.0-alpha.4.** See [alpha test notes](ALPHA-FRAME.md) for scope and controls. The stable release remains 0.2.1.

Optional world map tools for **World of Warcraft: Forever and Classic Era**, with built-in **English and German** language support. Made by **Patch & Zen**.

**Requires [PatchTools](https://www.curseforge.com/wow/addons/patchtools).** Adds a **Map** section to the PatchTools settings.

[CurseForge project](https://www.curseforge.com/wow/addons/patchtoolsmaps) · [Source code](https://github.com/csBlackWolf/PatchToolsMaps)

## Features

- Move the world map using its existing title bar, without an extra label covering other addons.
- Resize it with a native-style bottom-right handle, without an upper size limit. Move it beyond screen edges if desired.
- Save your preferred position and size between sessions.
- Extended mouse-wheel zoom is enabled by default for new settings; zoom for up to four times the native maximum outside combat. Native zoom remains available during combat.
- Choose **Classic**, **Semi-transparent fog** (default), or **Fully revealed** for unexplored areas.
- Reset position, size and zoom with one button. An open map closes so it can rebuild cleanly when reopened.

Reveal changes only the map display. It does not grant exploration, experience or achievements. Map coverage depends on the supported client build.

## Availability and requirements

**Requires PatchTools 0.7.0 or newer.** Install or update the base addon before enabling PatchToolsMaps. PatchTools 0.6.0 does not support this module.

Tested in game on **Forever Beta 1.60.1, build 70532**. Classic Era **1.15.9, build 70003** has passed in-game checks for zoom on world, continent and zone views, and error-free combat behaviour. The updated zoom is covered by automated Forever checks but could not be retested in the closed Beta. Newer builds are not yet confirmed. Window movement, resizing and zoom have passed initial in-game checks.

## Installation

Install **PatchTools** and **PatchToolsMaps** together. For manual installation, place both folders next to each other in your WoW `Interface/AddOns` folder, for example:

```text
World of Warcraft/_forever_beta_/Interface/AddOns/PatchToolsMaps
World of Warcraft/_forever_/Interface/AddOns/PatchToolsMaps
World of Warcraft/_classic_era_/Interface/AddOns/PatchToolsMaps
```

Some existing beta installations use `_classic_beta_` instead. Choose the folder used by your game. Do not put PatchToolsMaps inside the PatchTools folder.

## Controls and languages

- Open **`/patchtools`**, then choose **Map** (German: **Karte**).
- Drag the existing title bar to move the map; drag the corner handle to resize it.
- Use the mouse wheel to zoom. **Extended map zoom** starts enabled for new settings; existing choices are preserved.
- Use **Reset map position, size and zoom**, or **`/ptmaps reset`** (also **`/patchtoolsmaps reset`**), to restore the default view even if the map is off-screen.
- English and German follow your game language; other languages use English.

## Reporting issues and suggesting features

[Open an issue](https://github.com/csBlackWolf/PatchToolsMaps/issues/new/choose) for a bug or an idea. Tell us what happened, what you expected, and your WoW, PatchTools and PatchToolsMaps versions. Screenshots and error messages help but are optional. Please leave out account details and private chat. English and German are welcome.

Track progress through the issue labels: new, reviewed, planned, in progress, next release and deferred. [What each status means](.github/ISSUE_STATUS.md).

## License

[MIT](LICENSE.txt). You may change and share the project while keeping the copyright and license notice.

## Changelog

### 2026-10-24 — 0.2.1

- Fix map clicks and highlights after resizing in Classic Era.
- Keep the map, frame and controls aligned while changing the window size.
- Preserve zoom and position when resizing; stop shaking at the smallest zoom.
- Handle resize release outside the corner and combat interruptions safely.

### 2026-10-23 — 0.2.0

- Add Classic Era support with its own map catalog.
- Enable map zoom by default for new settings, including world and continent views.
- Remove the window size cap and screen-edge restriction.
- Use the existing Era title bar and a native-style resize handle.
- Add `/ptmaps reset` and `/ptmaps status`; preserve saved choices and combat safeguards.

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
