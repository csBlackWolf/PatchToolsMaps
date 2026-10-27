# Custom map frame alpha

Version: 0.3.0-alpha.13. Branch: alpha/custom-map-frame. Based on stable 0.2.1.

This is an experimental Classic Era frame. Forever keeps its native layout until a separate in-game test is possible. No stable release tag is changed.

## Try it

Install the alpha package in place of PatchToolsMaps, keeping PatchTools installed. In `/patchtools` > Map, leave **Use the classic map frame** unchecked for the modern frame (the default on Era). Check it to restore the original frame. Existing position, size, zoom and reveal choices are preserved.

The dark frame has a single compact title/button header and a one-line coordinate footer. Extra fixed info gets another footer row only when registered. The viewport follows the current map art aspect ratio, leaving no side panel at fit zoom. It keeps Blizzard's canvas, pins and data providers. Coordinates are provided by PatchToolsMaps using game map APIs, rather than depending on a particular coordinate addon. On another map, the player's current zone is shown beside player coordinates.

## Compatibility in this first prototype

- Questie, ATT and HandyNotes MapNotes Classic Era: adopt existing buttons from the installed Krowi WorldMapButtons library. Their click and tooltip handlers and enabled/disabled settings are preserved. Blizzard's own overlay buttons are excluded.
- SilverDragon: adopt the existing world-map button from its LDB module, including its icon visibility menu.
- Nova World Buffs: mirror its existing city/world-buff marker icons and live timer text in a compact footer row outside the map. Nova controls which markers are shown for the current map, faction, layer and settings. Unknown timers remain unknown. Mask the original icon/timer/hint cluster without changing its anchors, parent, data provider or Show/Hide state, so Nova continues updating it. Restore alpha and mouse interaction when disabling the custom frame or using full-screen. Other geographic Nova markers (for example Felwood plants) are unchanged. Hovering a footer buff icon shows the complete wrapped /buffs hint; clicking forwards its existing Nova action.
- Deathlog: use its minimap skull icon in the header to toggle the existing heatmap handler. The original checkbox and label are masked, with their visibility preference and anchors untouched; Classic/fullscreen restores them. No footer row is reserved. The heatmap stays on the map.
- TomTom: leave waypoint and click handling intact. The footer provides player/cursor coordinates itself; it does not overwrite TomTom settings or fonts.
- Fixed widgets from other addons may use the API below. Unknown widgets are not automatically grabbed from the map.

Unprotected Classic Era maps support window gestures and zoom in combat; protected maps and frame-style changes wait until combat ends. Maximizing the map or disabling the custom frame restores adopted widgets to their saved parents and anchors. Protected widgets are rejected. No external addon files or settings are edited.

See [the developer integration guide](INTEGRATION.md) for complete examples and compatibility rules.

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
- Toggle the classic-frame checkbox in the Map settings (unchecked means Modern, the default); reload with it both enabled and disabled.
- Check for overlapping third-party coordinate text and timer labels.

Automated fixtures cover docking, preserved handlers/visibility, coordinate formatting, library relayout, restoration, combat deferral and full-screen changes in addition to the stable regression suite. Actual appearance and compatibility with all installed addons still require an in-game test. Nova-specific fixtures cover map-driven visibility, unknown/live timer text, late layer frames, click forwarding, complete hint tooltips, original pin preservation, restoration and combat deferral.
