local _, Maps = ...
_G.PatchToolsMaps = Maps
Maps.version = "0.1.0"
local en = {
    TITLE="Map", INTRO="PatchToolsMaps · Changes affect only the world map display.",
    MOVABLE="Move the map window", RESIZE="Resize with the bottom-right corner handle",
    WINDOW_HINT="Move with the top bar; resize with the corner tab. Reset closes the map until you reopen it.",
    SIZE_DRAG="Drag to resize the map window",
    ZOOM="Extended map zoom (temporarily unavailable)", ZOOM_HINT="Additional zoom is disabled while a combat issue is being checked. Normal mouse-wheel zoom still works.",
    MODE="Unexplored areas", CLASSIC="Classic", MIST="Semi-transparent fog (default)", FULL="Fully revealed",
    VISUAL="Visual only: exploration, XP and achievements are unchanged.", RESET="Reset map position, size and zoom",
    STATUS="Client map data: build 70532. Maps without matching data keep their original display.",
    DRAG="PatchToolsMaps · drag here", SCALE="Window scale: %d%%", API="PatchToolsMaps needs PatchTools 0.7.0 or newer.",
    COMBAT="Map window changes are deferred until combat ends.",
}
local de = {
    TITLE="Karte", INTRO="PatchToolsMaps · Änderungen betreffen nur die Weltkartenanzeige.",
    MOVABLE="Kartenfenster frei verschieben", RESIZE="Größe am Eckgriff unten rechts ändern",
    WINDOW_HINT="Oben an der Leiste verschieben; an der Ecklasche die Größe ändern. Zurücksetzen schließt die offene Karte.",
    SIZE_DRAG="Ziehen, um die Kartengröße zu ändern",
    ZOOM="Erweiterter Kartenzoom (vorübergehend nicht verfügbar)", ZOOM_HINT="Die Zusatzstufe ist zur Prüfung eines Kampffehlers deaktiviert. Der normale Mausradzoom funktioniert weiterhin.",
    MODE="Unentdeckte Gebiete", CLASSIC="Klassisch", MIST="Halbtransparenter Nebel (Standard)", FULL="Voll aufgedeckt",
    VISUAL="Nur die Darstellung: Erkundung, EP und Erfolge bleiben unverändert.", RESET="Position, Größe und Zoom zurücksetzen",
    STATUS="Kartendaten: Build 70532. Karten ohne passende Daten behalten ihre normale Anzeige.",
    DRAG="PatchToolsMaps · hier ziehen", SCALE="Fenstergröße: %d%%", API="PatchToolsMaps benötigt PatchTools 0.7.0 oder neuer.",
    COMBAT="Änderungen am Kartenfenster werden bis zum Kampfende aufgeschoben.",
}
Maps.language = GetLocale() == "deDE" and de or en
function Maps:T(key, ...)
    local value = self.language[key] or en[key] or key
    if select('#', ...) > 0 then return string.format(value, ...) end
    return value
end
