# Addon integration with the PatchToolsMaps frame

The modern frame keeps the geographic map free of fixed controls and timers.
Map pins remain on Blizzard's canvas; addon buttons and fixed information can
use the header and footer instead. The current modern frame is available on
Classic Era. Forever and the Classic frame retain their native layout.

## Preferred: a compact toolbar icon

Use an icon and tooltip for a feature that can be switched on/off. Avoid putting
checkboxes, settings panels or timer text over the map art. A click action needs
no frame creation or positioning code from your addon:

```lua
local maps = _G.PatchToolsMaps
if maps and maps.mapActionAPI == 1 then
    maps:RegisterMapAction("MyAddon.overlay", {
        icon = "Interface\\Icons\\INV_Misc_Map_01", -- your addon/minimap icon
        tooltip = "MyAddon: toggle overlay", -- string or a function returning text
        onClick = function(button, mouseButton)
            if mouseButton == "LeftButton" then MyAddon:ToggleOverlay() end
        end,
        isActive = function() return MyAddon:IsOverlayEnabled() end, -- optional
        isShown = function() return MyAddon:ShouldShowMapButton() end, -- optional
    })
end
```

`RegisterMapAction(id, options)` returns `true, button` on success or `false` for
invalid/duplicate registration. Use a unique ID and register once per UI session,
after your addon has initialized. As with the widget example below, optional
load order can be handled with `OptionalDeps` or retrying after `ADDON_LOADED`.
Your original native control remains the fallback when Modern is inactive;
custom action icons themselves are visible only in the Modern frame.

The icon is displayed at 24 px with a tooltip. An optional `isActive` callback
can adjust the plain border accent; original icon colors remain visible in both
states. Set `style = "minimap"` for the native round minimap border. For toggles,
put the current state in the tooltip; no small checkmark obscures the icon. `isShown` controls whether
the icon is present; omit it to show the action whenever Modern is active. These
callbacks are polled while the modern frame is visible: keep them cheap and
read-only. `onClick` receives the button and mouse-button name; your addon owns
the feature state and any combat restrictions. Layout itself waits for combat
lockdown to end. Never call protected functions from a callback to bypass it.

The toolbar normally shares a row with the area name. If icons would squeeze the
name below a readable width, the name gets its own row above the toolbar. More
icons wrap to additional toolbar rows as needed. The viewport height adapts so
these controls do not cover map art. Do not implement your own overflow offsets.

Deathlog uses this approach: its minimap skull icon toggles the existing world-map
heatmap handler. Its original checkbox/container is temporarily masked without
changing native anchors or Show/Hide state, and restored in Classic/fullscreen.
The heatmap itself stays geographic; no extra footer row is reserved.

## Public widget API, version 1

Detect support with `PatchToolsMaps.frameWidgetAPI == 1`. PatchToolsMaps is an
optional dependency; your addon must still work when it is absent or disabled.
Add `## OptionalDeps: PatchToolsMaps` to your TOC if appropriate.

```lua
local function RegisterMapControl()
    local maps = _G.PatchToolsMaps
    if not maps or maps.frameWidgetAPI ~= 1 or not MyAddonMapControl then return end
    local registered = maps:RegisterFrameWidget(
        "MyAddon.mapControl", MyAddonMapControl, "info-right")
    if registered and maps.initialized and not InCombatLockdown() then
        maps:Refresh()
    end
end

-- Call after creating your control. Retry after ADDON_LOADED when load order is
-- uncertain, and after PLAYER_REGEN_ENABLED if layout was requested in combat.
RegisterMapControl()
```

Available slots:

| Slot | Purpose | Size guidance |
| --- | --- | --- |
| `buttons` | Header buttons with their existing clicks and tooltips | Prefer 20–24 px height; larger buttons scale down to 24 px |
| `info-left` | Fixed controls or information in an extra footer row | Prefer 20–24 px height, at most 32 px |
| `info-right` | Right-aligned controls, labels or timers in that footer row | Prefer 20–24 px height, at most 32 px |

The registration returns `false` for an invalid slot, a protected object, or a
conflicting ID/frame. Use a unique, stable ID prefixed with your addon name.
Repeated registration of the same ID and frame is safe; the original slot
remains in effect. Registrations last for the UI session, so register again on
the next login/reload. Do not store frame objects in SavedVariables.

## A checkbox and label belong in one container

Prefer `RegisterMapAction` for simple toggles. If a text control is necessary, register a wrapper frame that contains both the checkbox and its label. Give
the wrapper enough width to include the complete localized text; the dock uses
`GetWidth()`/`GetHeight()`, not the bounds of children outside the wrapper.
Anchor children inside the wrapper, with the wrapper's original anchor on the
native map frame rather than the zooming canvas when you control its creation.
Do not register a geographical heatmap, a map pin, or the full map canvas.

Existing addon adapters may move original containers or mask an original fixed
control when providing an icon action. Never adopt the checkbox from an addon's
separate statistics window, and never move or rebuild the heatmap itself.

## Ownership, visibility and layout

- Your addon owns its callbacks, tooltip, values and Show/Hide preference.
  PatchToolsMaps does not replace those scripts or change your saved settings.
- The modern frame temporarily changes the registered frame's parent, anchors
  and scale. Selecting Classic or maximizing the map restores their snapshots.
  Keep the native placement valid as the fallback when integration is inactive.
- Do not continually reparent or reanchor a docked control. Call `maps:Refresh()`
  after changing its size or visibility so the header/footer can be laid out.
  Hidden controls stay hidden and do not reserve space on their own.
- Keep controls narrow and allow translated labels enough room. Fixed info shares
  one additional footer row; it does not provide unlimited panels or wrapping.
- Layout is deferred during combat. Never bypass this with protected methods or
  patch Blizzard's canvas/quest pin methods to force a layout update.

## Transparency

Era's `worldMapOpacity` CVar is the shared source of truth for modern and native
maps. PatchToolsMaps calls `WorldMapFrame_SetOpacity` when available, using its
native border/canvas alpha behavior. Fullscreen remains opaque as in Blizzard's
implementation; the minimized setting is retained. External CVar changes update
the slider. Clients without this CVar/helper use a local fallback with the same
alpha curve. Do not apply another transparency multiplier to registered widgets.

The PatchTools settings background has a separate transparency control. Its text
and controls remain opaque for readability.

## Compatibility checklist

Test without PatchToolsMaps, with Modern and Classic, minimized/fullscreen, at
different zoom/window/UI scales, before and after reload, during/after combat,
and with your own feature disabled. Verify clicks, right-clicks, modifiers,
tooltips, translated labels, visibility changes and original-anchor restoration.

The modern map area name has a right-click shortcut to a small transparency slider. It shares the same setting as the Map settings page, and closes on an outside click, Escape, a second right-click, or when the map closes/fullscreen starts. The compact popup prefers space above the title, then beside the map, before falling back below.

Only tooltips created by PatchToolsMaps itself (its action API and area name) are placed above their controls and clamped at screen edges. Tooltip scripts and placement belonging to registered third-party widgets are not hooked or repositioned, avoiding jumps and conflicts with their own tooltip systems.
