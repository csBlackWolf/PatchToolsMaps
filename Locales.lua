local _, Maps = ...
_G.PatchToolsMaps = Maps
Maps.version = "0.1.0-local.7"
local en = {
    TITLE="Map", INTRO="PatchToolsMaps · local preview. Changes affect only the world map display.",
    MOVABLE="Move the map window", RESIZE="Resize with the bottom-right corner handle",
    WINDOW_HINT="Move with the top bar; resize with the corner tab. Reset closes the map until you reopen it.",
    SIZE_DRAG="Drag to resize the map window",
    ZOOM="Extended map zoom", ZOOM_HINT="Adds one closer zoom step. Image detail does not increase.",
    MODE="Unexplored areas", CLASSIC="Classic", MIST="Semi-transparent fog (default)", FULL="Fully revealed",
    VISUAL="Visual only: exploration, XP and achievements are unchanged.", RESET="Reset map position, size and zoom",
    STATUS="Client map data: build 70532. Maps without matching data keep their original display. In-game testing pending.",
    DRAG="PatchToolsMaps · drag here", SCALE="Window scale: %d%%", API="PatchToolsMaps needs the prepared PatchTools 0.7.0 or newer.",
    COMBAT="Map window changes are deferred until combat ends.",
}
local de = {
    TITLE="Karte", INTRO="PatchToolsMaps · lokale Vorschau. Änderungen betreffen nur die Weltkartenanzeige.",
    MOVABLE="Kartenfenster frei verschieben", RESIZE="Größe am Eckgriff unten rechts ändern",
    WINDOW_HINT="Oben an der Leiste verschieben; an der Ecklasche die Größe ändern. Zurücksetzen schließt die offene Karte.",
    SIZE_DRAG="Ziehen, um die Kartengröße zu ändern",
    ZOOM="Erweiterter Kartenzoom", ZOOM_HINT="Ergänzt eine nähere Zoomstufe. Die Bilddetails nehmen dabei nicht zu.",
    MODE="Unentdeckte Gebiete", CLASSIC="Klassisch", MIST="Halbtransparenter Nebel (Standard)", FULL="Voll aufgedeckt",
    VISUAL="Nur die Darstellung: Erkundung, EP und Erfolge bleiben unverändert.", RESET="Position, Größe und Zoom zurücksetzen",
    STATUS="Kartendaten: Build 70532. Karten ohne passende Daten behalten ihre normale Anzeige. Spieltest steht noch aus.",
    DRAG="PatchToolsMaps · hier ziehen", SCALE="Fenstergröße: %d%%", API="PatchToolsMaps benötigt das vorbereitete PatchTools 0.7.0 oder neuer.",
    COMBAT="Änderungen am Kartenfenster werden bis zum Kampfende aufgeschoben.",
}
Maps.language = GetLocale() == "deDE" and de or en
function Maps:T(key, ...)
    local value = self.language[key] or en[key] or key
    if select('#', ...) > 0 then return string.format(value, ...) end
    return value
end
