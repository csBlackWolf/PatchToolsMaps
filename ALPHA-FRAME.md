# Custom map frame alpha

Version: 0.3.0-alpha.1. Branch: alpha/custom-map-frame. Based on stable 0.2.1.

This is an experimental Classic Era frame. Forever keeps its native layout until a separate in-game test is possible. No stable release tag is changed.

## Try it

Install the alpha package in place of PatchToolsMaps, keeping PatchTools installed. In `/patchtools` > Map, enable **Own map frame with addon toolbar (Alpha)**. The alpha enables this new setting by default on Era if no choice exists. Switch it off to restore the original frame. Existing position, size, zoom and reveal choices are preserved.

The dark frame has a separate title, a toolbar above the map and a coordinate/info footer. It keeps Blizzard's canvas, pins and data providers. Coordinates are provided by PatchToolsMaps using game map APIs, rather than depending on a particular coordinate addon. On another map, the player's current zone is shown beside player coordinates.

## Compatibility in this first prototype

- Questie, ATT and HandyNotes MapNotes Classic Era: adopt existing buttons from the installed Krowi WorldMapButtons library. Their click and tooltip handlers and enabled/disabled settings are preserved. Blizzard's own overlay buttons are excluded.
- SilverDragon: adopt the existing world-map button from its LDB module, including its icon visibility menu.
- Nova World Buffs: keep its location-based map pins and attached timer labels on the original map canvas. Do not move these into the footer: their positioning is geographic. A separate fixed timer readout is not automatically identified in this prototype.
- TomTom: leave waypoint and click handling intact. The footer provides player/cursor coordinates itself; it does not overwrite TomTom settings or fonts.
- Fixed widgets from other addons may use the API below. Unknown widgets are not automatically grabbed from the map.

Out-of-combat layout changes only. Maximizing the map or disabling the custom frame restores adopted widgets to their saved parents and anchors. Protected widgets are rejected. No external addon files or settings are edited.

## Optional widget API

```lua
-- Existing unprotected Frame/Button; keep its own scripts and visibility.
PatchToolsMaps:RegisterFrameWidget("MyAddon.button", myButton, "buttons")
PatchToolsMaps:RegisterFrameWidget("MyAddon.timer", myTimerFrame, "info-right")
PatchToolsMaps:Refresh()
```

Slots: `buttons`, `info-left`, `info-right`. IDs and widget registrations must be unique. Registration returns false for protected frames, invalid slots or conflicting registrations. Register fixed UI only, never map pins. Register again on the next UI session; the addon does not serialize frame references.

## Test checklist

- Button tooltips, left/right/shift clicks and addon-specific show/hide options.
- Cursor/player coordinates at different zoom levels, window sizes and map views.
- Drag, resize, reset, full-screen/minimized transitions and combat entry/exit.
- Toggle the alpha frame off and on; reload with it both enabled and disabled.
- Check for overlapping third-party coordinate text and timer labels.

Automated fixtures cover docking, preserved handlers/visibility, coordinate formatting, library relayout, restoration, combat deferral and full-screen changes in addition to the stable regression suite. Actual appearance and compatibility with all installed addons still require an in-game test.
