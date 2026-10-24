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
