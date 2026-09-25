# Scholia — design files

Snapshot of the two claude.ai artifacts, 25 Sep 2026 (canvas v31: 53 screens incl. first-launch empty state, Bookmarks tab, goal-done ring, iPad row).

- `canvas/project/` — the Design canvas (https://claude.ai/code/artifact/b508b7dc-37f9-487d-ab49-a627c54ef9b8): `canvas.json` is the index (artboard positions, flow arrows and labels), every `*.dc.html` is one screen. `Main.dc.html` is Home. `ds/scholia/tokens.json` is the installed copy of the design-system tokens.
- `design-system/project/` — the Scholia Design System (https://claude.ai/artifact/3JncvgG2jiEbSg7jqqnSe2): `tokens.json` (colour for light/dark, type, spacing, radius, shadow, effects), `README.md` (brand book), `components/*/` (guidelines + static previews), `components/Cover/preview.html`.

For implementation, `design-system/project/tokens.json` is the source of truth for values; the screens use the same values as literal hex.
