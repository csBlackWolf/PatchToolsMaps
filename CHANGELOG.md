# PatchToolsMaps 0.3.0-alpha.3 — 2026-10-24

- Show Nova World Buffs city/world-buff icons and timers in a compact footer row outside the map, following Nova's existing marker visibility and live timer text. Collapse the row when no relevant markers are shown.
- Show Nova's complete /buffs hint as a wrapped tooltip on each footer buff icon instead of the clipped map text. Forward clicks to the original Nova action.
- Preserve original pin anchors, parents and Show/Hide logic; restore the original presentation when disabling the frame or maximizing the map. Defer original-frame changes during combat.

Validation: automated source-visibility, timer text, tooltip, click, layer, pin preservation, restoration and combat checks in addition to Era/Forever regressions. Gameplay verification pending.

# PatchToolsMaps 0.3.0-alpha.2 — 2026-10-24

- Combine the title and addon buttons into one compact header; scale toolbar buttons down to fit.
- Use a thin border and a single coordinate footer row. Reserve additional info space only for registered widgets.
- Fit window height to the map artwork aspect ratio so fully zoomed-out maps use the viewport without a side panel; refit after changing maps.

Validation: automated Era/Forever checks, compact geometry at multiple window sizes and art aspect ratios, original button callbacks and scale restoration. In-game appearance still needs confirmation.

# PatchToolsMaps 0.3.0-alpha.1 — 2026-10-24

Experimental custom Classic Era frame on the alpha/custom-map-frame branch. Stable 0.2.1 remains unchanged.

- Separate the map title, addon button toolbar and coordinate/info footer.
- Dock existing Questie, ATT and MapNotes buttons from Krowi WorldMapButtons, and SilverDragon's world-map button. Preserve their scripts and visibility preferences.
- Add player/cursor coordinates using game map APIs, and a widget registration API for optional fixed addon information.
- Restore original widget parents and anchors when disabling the custom frame or maximizing the map. Defer layout changes during combat.
- Keep geographic addon pins and Nova timer labels on the original canvas. Keep Forever's native frame for now.

Validation: automated Era/Forever regression checks in English, German and English fallback. The new frame and installed addon combinations still need in-game validation. See ALPHA-FRAME.md.

# PatchToolsMaps 0.2.1 — 2026-10-24

- Fix Classic Era map clicks and continent highlights drifting away from the mouse pointer after resizing.
- Keep the map artwork, border and controls aligned as the window grows or shrinks.
- Preserve the current zoom and map position while resizing, without repeatedly resetting the view.
- Fix map content shaking during fully zoomed-out resizing and when scrolling outward at the minimum zoom.
- Finish interrupted resize gestures safely, including mouse release outside the corner and entering combat.

Validation: Classic Era gameplay checks confirmed correct map selection and smooth resizing, including fully zoomed-out views and repeated outward scrolling. Automated Era/Forever integration checks pass in English, German and English fallback. Forever Beta is closed and could not be retested in game; the window layout correction is specific to Era. Existing settings and map catalogs are preserved.

# PatchToolsMaps 0.2.0 — 2026-10-23

- Support Classic Era 1.15.9 and Forever 1.60.1 in one package, with separate client map catalogs selected by build.
- Enable mouse-wheel map zoom by default for new settings, from the native minimum to four times the native maximum. World, continent and zone views are supported.
- Allow map windows to grow without an upper size limit and move beyond screen edges.
- Use Era's existing title bar for dragging, without an extra label covering other addons, and a native-style corner resize handle.
- Add /ptmaps reset (also /patchtoolsmaps reset) to restore position, size and view, plus /ptmaps status for diagnostics.
- Keep zoom, movement and resizing inactive during combat. Reset requests finish after combat. Existing saved settings are preserved.

Requires PatchTools 0.7.0 or newer; PatchTools 0.8.0 is recommended for Era.

Validation: Classic Era gameplay tests confirmed wheel zoom on all world-map views and error-free combat behaviour. Automated Era/Forever integration checks pass in English, German and English fallback. The updated zoom has not been retested in the closed Forever Beta; older map behaviour was tested there. Era catalog build 70003 contains 525 overlays on 41 map-art variants. One inconsistent overlay retains native rendering; maps without matching build data also retain native rendering. Reveal is visual only and grants no exploration, XP or achievements.

# PatchToolsMaps 0.1.0 — 2026-10-23

First regular release. Requires PatchTools 0.7.0 or newer.

- Move and resize the world map; save window position and size.
- Native zoom; the additional zoom step is temporarily disabled for combat compatibility.
- Classic, semi-transparent fog (default) and fully revealed map modes.
- Reset position, size and zoom; an open map closes so it rebuilds cleanly on reopening.
- Compact square resize handle at the bottom-right corner. Controls remain visible during combat; resizing waits until combat ends.
- Keep addon reveal masks separate from Blizzard map state; do not change its zoom-level table.
- Built-in English and German; settings appear above About PatchTools in the base addon.
- Guard map opening before Blizzard has initialized its zoom levels.

Targets Forever 1.60.1 build 70532. Reveal is visual only and grants no exploration, XP or achievements. Maps without matching data keep the native display. Other client builds are not yet confirmed.

Validation: automated loading, settings, reveal, window and reset checks in English, German and English fallback. Initial in-game checks confirmed moving, resizing, zoom and reveal behaviour on Forever Beta. The complete map catalog and all addon combinations have not been exhaustively tested.
