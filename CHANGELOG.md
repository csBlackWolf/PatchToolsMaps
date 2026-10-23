# PatchToolsMaps 0.1.0 — unreleased preparation, 2026-10-23

First regular release. Requires PatchTools 0.7.0 or newer.

- Move and resize the world map; save window position and size.
- Native zoom; the additional zoom step is temporarily disabled pending combat-taint verification.
- Classic, semi-transparent fog (default) and fully revealed map modes.
- Reset position, size and zoom; an open map closes so it rebuilds cleanly on reopening.
- Compact square resize handle at the bottom-right corner.
- Built-in English and German; settings appear above About PatchTools in the base addon.
- Guard map opening before Blizzard has initialized its zoom levels.

Targets Forever 1.60.1 build 70532. Reveal is visual only and grants no exploration, XP or achievements. Maps without matching data keep the native display. Other client builds are not yet confirmed.

Validation: automated loading, settings, reveal, window and reset checks in English, German and English fallback. Initial in-game checks confirmed moving, resizing, zoom and reveal behaviour on Forever Beta. The complete map catalog and all addon combinations have not been exhaustively tested.
