# PatchToolsMaps user guide / Bedienungsanleitung

## English

Install PatchTools 0.7.0 or newer and PatchToolsMaps next to each other in the same client's `Interface/AddOns` folder. Enable both. `/ptmaps` opens the Map settings; open the world map with your normal map key.

Drag the title bar to move the map and the bottom-right handle to resize it. Position and size are saved. The window can move beyond screen edges; `/ptmaps reset` restores position, size and zoom if you lose it. An open map closes during reset so that it can rebuild when reopened. Combat can delay protected layout changes.

The mouse wheel offers extended zoom outside combat, up to four times the native maximum. Native zoom remains available during combat. New settings enable extended zoom; updates preserve an existing choice.

For unexplored areas choose **Classic**, **Semi-transparent fog** (default) or **Fully revealed**. This changes only the display: exploration, XP and achievements are unchanged. Maps without matching data retain their normal display.

### Modern frame alpha

On Classic Era the alpha uses the modern frame by default. Check **Use the classic map frame** to return to the stable-style frame. Player/cursor coordinates appear in the footer; supported addon buttons and buff timers sit outside the map art. Right-click the area name for the compact transparency slider. It closes on an outside click or Escape and prefers space above the map. Modern and classic frames share the map-transparency setting.

Use the PatchTools and PatchToolsMaps alphas together for the complete set of alpha options. Settings come from the installed module, so an older module offers its older controls. The modern frame remains experimental; Forever keeps its native layout pending its own in-game checks.

## Deutsch

Installiere PatchTools ab Version 0.7.0 und PatchToolsMaps nebeneinander im `Interface/AddOns`-Ordner desselben Clients und aktiviere beide. `/ptmaps` öffnet die Karteneinstellungen. Die Karte selbst öffnest du mit deiner normalen Kartentaste.

Ziehe die Titelleiste zum Verschieben und den Griff unten rechts zum Ändern der Größe. Position und Größe werden gespeichert. Falls die Karte außerhalb des Bildschirms liegt, setzt `/ptmaps reset` Position, Größe und Zoom zurück. Eine offene Karte wird dabei geschlossen und beim erneuten Öffnen sauber aufgebaut. Im Kampf können Änderungen am Rahmen warten müssen.

Außerhalb des Kampfes kannst du mit dem Mausrad bis zum Vierfachen des normalen Maximums hineinzoomen. Im Kampf bleibt der normale Zoom verfügbar. Neue Einstellungen aktivieren den erweiterten Zoom; deine bisherige Auswahl bleibt bei Updates erhalten.

Für unentdeckte Gebiete stehen **Klassisch**, **Halbtransparenter Nebel** (Standard) und **Voll aufgedeckt** zur Wahl. Nur die Darstellung ändert sich: Erkundung, EP und Erfolge bleiben unverändert. Karten ohne passende Daten behalten ihre normale Darstellung.

### Moderner Rahmen in der Alpha

Auf Classic Era ist der moderne Rahmen in der Alpha standardmäßig aktiv. Mit **Klassischen Kartenrahmen verwenden** wechselst du zurück. Spieler- und Mauskoordinaten stehen unten; unterstützte Addon-Buttons und Buff-Timer liegen außerhalb der Kartenfläche. Ein Rechtsklick auf den Gebietsnamen öffnet den kompakten Transparenzregler, bevorzugt oberhalb der Karte. Ein Klick außerhalb oder Escape schließt ihn. Beide Rahmen verwenden dieselbe Kartentransparenz.

Nutze die Alpha von PatchTools und PatchToolsMaps zusammen für alle Alpha-Optionen. Die Einstellungen stammen aus dem installierten Modul; ältere Module bieten ihre bisherigen Optionen an. Der moderne Rahmen ist experimentell. Forever behält bis zu eigenen Spieltests den bisherigen Rahmen.

## Compatibility and reports / Kompatibilität und Fehlerberichte

Recorded in-game checks: Forever Beta 1.60.1 build 70532 and Classic Era 1.15.9 build 70003. Later zoom changes received Era gameplay checks and automated Forever checks; the closed beta prevented another Forever gameplay test. These observations do not guarantee later client builds.

For a report, include WoW edition/build, PatchTools and module versions, map/zone, frame choice and steps to reproduce. `/ptmaps status` provides useful details. English and German are welcome. Leave private chat/account information out of screenshots.

[Report a bug / Fehler melden](https://github.com/csBlackWolf/PatchToolsMaps/issues/new/choose) · [Developer guide](DEVELOPMENT.md) · [Changelog](CHANGELOG.md) · [Overview / Übersicht](README.md)
