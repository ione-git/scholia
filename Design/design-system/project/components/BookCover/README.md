# BookCover

A generated cover for a book that has no cover art, and the frame every real cover sits in. A flat colour block with the title in Literata and the author in small uppercase.

- Ratio 2:3. Sizes used: 80×120 (Home row), 100×150 and 107×152 (grids), 160×240 and 180×270 (Home hero), 40×60 (list thumbnails).
- `radius-sm` (6px; 8px on the hero, 4px under 60px wide). `shadow-cover`; the hero uses `shadow-cover-hero` with a glow tinted by the cover's own colour.
- Text: `cover-title` (12–24px by size) and the author at 8–10px, uppercase, 0.08em tracking, 85% opacity, both in a light cream on a dark block (4.5:1 minimum: choose the block colour accordingly).
- The block colour is per book and comes from the book, not from the palette; a real cover image replaces the block and keeps the radius and shadow.
- The app supplies title, author, colour or image, and the progress value when a thin `accent` bar on `track` sits under the cover (Home only).
