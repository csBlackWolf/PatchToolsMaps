# PatchToolsMaps 0.3.0-alpha.15-local.1 — local combat-close fix

- Allow the modern frame's X button to close a map opened during combat through Blizzard's secure native close action.
- Keep the larger hit area at small map sizes. Movement, resizing and extended zoom retain their existing combat deferral.

Automated Classic Era/Forever integration checks passed, including combat close/reopen and classic/fullscreen restoration. In-game combat confirmation is pending. This is a local test build.

# PatchToolsMaps 0.3.0-alpha.14 — 2026-10-26

Public alpha test: bugs are possible. Please report problems in the central PatchTools issue tracker. The stable release remains available.

- Fix the modern map's close button at very small window sizes.
- Remember map position and size separately for each character; retain shared transparency settings.
- Keep the modern frame, addon toolbar, coordinates, buff timers and classic-frame option from the previous alpha.

Recommended companion: PatchTools 0.9.0-alpha.14.

The close-button fix was confirmed locally in Classic Era. Automated checks cover Classic Era and Forever; character-switch layout persistence still needs further in-game testing.

# PatchToolsMaps 0.3.0-alpha.13 — 2026-10-25

**Public alpha test: this version is likely to contain bugs. Please report problems and feedback on GitHub. Use the stable releases if you prefer the established feature set.**

Alpha preview. **Install together with PatchTools 0.9.0-alpha.13 for the complete settings experience.** Stable PatchToolsMaps 0.2.1 remains unchanged. The module also loads with stable PatchTools 0.8.0, but the matched alpha pair is recommended.

- Modern compact Classic Era map frame by default, with an option to restore the classic frame.
- A header for addon buttons and a footer for coordinates and zone-relevant Nova World Buffs timers, keeping the map itself clear.
- Integrations for Questie, ATT, MapNotes, SilverDragon, GuildMap and Deathlog; Deathlog heatmap toggles from a framed header icon.
- Shared native map transparency for modern/classic frames. Right-click the zone title for a compact slider that prefers placement outside the map and closes on outside clicks.
- Keep third-party tooltips under their addons' control; position our own header tooltips above the map when possible.
- A small public map-action and docking API, documented in INTEGRATION.md for other addon authors.
- Preserve movement, resizing, extended zoom, reveal modes, reset commands and combat deferral from the stable module.

Validation: Era/Forever tests in English, German and English fallback, including stable PatchTools 0.8.0 compatibility; local Classic Era gameplay and visual testing. Forever gameplay retest is unavailable while Beta is closed.

# PatchToolsMaps 0.3.0-alpha.12 — 2026-10-25

- Stop hooking/repositioning third-party header tooltips. Only PatchToolsMaps action/title tooltips use our above-header placement, avoiding jumps and conflicts with addon tooltip systems.
- Reduce the quick transparency popup to 260×70 with a shorter label. Prefer above the title; use space beside the map when needed before falling back below.
- Dismiss on outside clicks without consuming them. Inside slider clicks/drags stay open, and a second right-click on the title still closes it. Retain Escape/map-close/fullscreen cleanup; include a fallback for older clients without the global mouse event.

Validation: Era/Forever integration fixtures in English, German and English fallback cover external tooltip script preservation, compact popup placement/fallbacks, inside/outside clicks, title toggling and synchronization. In-game confirmation pending.

# PatchToolsMaps 0.3.0-alpha.11 — 2026-10-25

- Remove the tiny active-state checkmark from action icons. Deathlog keeps its original colors and reports heatmap state in its tooltip.
- Place modern-header action and area-name tooltips above the toolbar. Apply the same placement to standard GameTooltip tooltips owned by registered addon header buttons, preserving their content and callbacks. Clamp at screen edges; leave unrelated and Classic tooltips alone.

Validation: Era/Forever integration fixtures in English, German and English fallback cover ownership-aware tooltip placement, preserved external callbacks/content and Classic fallback. In-game appearance confirmation pending.

# PatchToolsMaps 0.3.0-alpha.10 — 2026-10-25

- Use additive blending for the round minimap-style hover glow. Its black texture background must not cover the Deathlog skull and border when hovered.

Validation: existing Era/Forever syntax and integration checks pass in English, German and English fallback. Actual hover appearance requires in-game confirmation.

# PatchToolsMaps 0.3.0-alpha.9 — 2026-10-25

- Right-click the area name in the modern frame for a quick transparency slider, synchronized with the native setting and the Map settings page. Close it with Escape, its close button, a second right-click, or by closing/maximizing the map.
- Give the Deathlog heatmap icon the native round minimap border and retain its original colors. Show active state with a small checkmark and tooltip instead of dimming the skull.
- Document the optional minimap action style and revised state indicator.

Validation: Era/Forever integration checks in English, German and English fallback cover quick-slider synchronization/cleanup, state indicators and existing toolbar/map behavior. In-game appearance confirmation pending.

# PatchToolsMaps 0.3.0-alpha.8 — 2026-10-25

- Replace the Deathlog footer checkbox with its minimap skull icon in the header. Click to toggle the original heatmap function; icon and tooltip show the current state. Restore the native checkbox in Classic/fullscreen and keep its own visibility preference.
- Offer the simple RegisterMapAction API as the preferred integration for addon toggles. Developers supply an icon, tooltip and callback, with optional active/visibility getters.
- Give the area name its own row when icons need more room; wrap long toolbars into further rows without covering map art.
- Expand INTEGRATION.md with the recommended icon approach and working examples.

Validation: Era/Forever syntax and integration fixtures in English, German and English fallback include Deathlog toggling/state/restoration/combat, action registration and wrapping with 30 extra actions. In-game confirmation pending.

# PatchToolsMaps 0.3.0-alpha.7 — 2026-10-25

- Add map transparency using Blizzard's worldMapOpacity setting for both Classic and Modern. External native-setting changes update the slider; fullscreen retains Blizzard's opaque behavior. Clients without the native setting use a local fallback.
- Move Deathlog's existing world-map heatmap checkbox and label into the modern footer. Preserve callbacks, visibility and the heatmap itself; restore the original placement for Classic/fullscreen and defer layout changes during combat.
- Document the versioned header/footer widget API, checkbox containers, fallback and compatibility guidelines in INTEGRATION.md.

Validation: Era/Forever integration checks in English, German and English fallback cover native/fallback opacity, CVar updates, fullscreen and combat, plus Deathlog docking, visibility, name collisions and restoration. In-game confirmation pending.

# PatchToolsMaps 0.3.0-alpha.6 — 2026-10-25

- Replace the Modern/Classic buttons with a single classic-frame checkbox. Unchecked keeps the modern default; existing saved choices remain unchanged.
- Use a native dropdown for unexplored-area display: Classic, semi-transparent fog or fully revealed.

Validation: dropdown selection, checked states and native/custom frame restoration pass the Era/Forever integration checks in English, German and English fallback. In-game confirmation pending.

# PatchToolsMaps 0.3.0-alpha.5 — 2026-10-24

- Offer Modern (default) and Classic map appearance buttons on Classic Era. Preserve saved choices and restore the native frame and original addon widget placement in Classic mode.
- Share the PatchTools addon-list icon, now included in the companion base test package.

Validation: automated style-selection and Era/Forever integration fixtures in English, German and English fallback. Local alpha only; in-game appearance/reload confirmation pending. Forever retains its existing native appearance.

# PatchToolsMaps 0.3.0-alpha.4 — 2026-10-24

- Fix all Nova buff timers appearing on the first map opening after reload, before a relevant buff zone has been viewed.
- Require a live HereBeDragons map-pin assignment before mirroring a timer; default-shown, unassigned Nova frames no longer count as zone-eligible displays.

Validation: reproduced the fresh-reload state in the integration fixture; it fails with Alpha 3 and passes with this correction. Era/Forever integration checks pass in English, German and English fallback. In-game reload confirmation pending.

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
