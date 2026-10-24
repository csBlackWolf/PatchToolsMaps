local _, Maps = ...
_G.PatchToolsMaps = Maps
Maps.version = "0.3.0-alpha.1"
local en = {
    CUSTOM_FRAME="Own map frame with addon toolbar (Alpha)",
    FRAME_COORDS="Player: %s    |    Cursor: %s",
    TITLE="Map", INTRO="PatchToolsMaps · Changes affect only the world map display.",
    MOVABLE="Move the map window", RESIZE="Resize with the bottom-right corner handle",
    WINDOW_HINT="Drag the existing title bar; resize at the corner. No size cap or screen-edge limit. Reset: /ptmaps reset.",
    SIZE_DRAG="Drag to resize the map window",
    ZOOM="Extended map zoom", ZOOM_HINT="Mouse wheel: up to 4× beyond native maximum outside combat. Reset: /ptmaps reset.",
    MODE="Unexplored areas", CLASSIC="Classic", MIST="Semi-transparent fog (default)", FULL="Fully revealed",
    VISUAL="Visual only: exploration, XP and achievements are unchanged.", RESET="Reset map position, size and zoom",
    STATUS="Client build: %s. Maps without matching data keep their original display.",
    DRAG="PatchToolsMaps · drag here", SCALE="Window scale: %d%%", API="PatchToolsMaps needs PatchTools 0.7.0 or newer.",
    RESET_DONE="Map position, size and zoom reset.", RESET_PENDING="Map reset will finish after combat.",
    COMBAT="Map window changes are deferred until combat ends.",
}
local de = {
    CUSTOM_FRAME="Eigener Kartenrahmen mit Addon-Leiste (Alpha)",
    FRAME_COORDS="Spieler: %s    |    Maus: %s",
    TITLE="Karte", INTRO="PatchToolsMaps · Änderungen betreffen nur die Weltkartenanzeige.",
    MOVABLE="Kartenfenster frei verschieben", RESIZE="Größe am Eckgriff unten rechts ändern",
    WINDOW_HINT="Vorhandene Titelleiste ziehen; an der Ecke vergrößern. Ohne Größen- und Bildschirmgrenze. Reset: /ptmaps reset.",
    SIZE_DRAG="Ziehen, um die Kartengröße zu ändern",
    ZOOM="Erweiterter Kartenzoom", ZOOM_HINT="Mausrad: außerhalb des Kampfes bis 4× über das normale Maximum. Zurücksetzen: /ptmaps reset.",
    MODE="Unentdeckte Gebiete", CLASSIC="Klassisch", MIST="Halbtransparenter Nebel (Standard)", FULL="Voll aufgedeckt",
    VISUAL="Nur die Darstellung: Erkundung, EP und Erfolge bleiben unverändert.", RESET="Position, Größe und Zoom zurücksetzen",
    STATUS="Client-Build: %s. Karten ohne passende Daten behalten ihre normale Anzeige.",
    DRAG="PatchToolsMaps · hier ziehen", SCALE="Fenstergröße: %d%%", API="PatchToolsMaps benötigt PatchTools 0.7.0 oder neuer.",
    RESET_DONE="Kartenposition, Größe und Zoom zurückgesetzt.", RESET_PENDING="Karte wird nach dem Kampf zurückgesetzt.",
    COMBAT="Änderungen am Kartenfenster werden bis zum Kampfende aufgeschoben.",
}
Maps.language = GetLocale() == "deDE" and de or en
function Maps:T(key, ...)
    local value = self.language[key] or en[key] or key
    if select('#', ...) > 0 then return string.format(value, ...) end
    return value
end
