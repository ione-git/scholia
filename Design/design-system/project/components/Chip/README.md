# Chip

A filter chip in the Library's collection row: All, Science Fiction, Biographies…, plus a dashed "+" chip that creates a collection. One chip is selected at a time.

- Height 36px, padding 0 14px, `radius-pill`, `subhead` label with the count after it.
- Rest: `surface-card` fill, 0.5px `control-border`, label `ink`, count `ink-muted`.
- Selected: `ink` fill, label `on-ink`, count at 60% opacity. Never the accent.
- New-collection chip: 36px square, 1px dashed `ink-faint`, transparent, a 16px plus in `ink-muted`.
- The row scrolls horizontally and is hidden entirely when the library has no collections.
- The app supplies labels, counts, the selected id and the tap handlers.
