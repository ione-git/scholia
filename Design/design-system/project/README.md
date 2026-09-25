# Scholia

Scholia is an iOS reader for books in languages you are still learning. Tap a word and its contextual translation appears where you are reading; nothing else moves. The design is a quiet paper page with iOS 26 Liquid Glass controls floating over it: warm, editorial, and almost entirely typographic. The name refers to scholia — notes in the margins of a text — but the visual language does not: no antiquity, no ornament, just paper, ink and one warm accent.

## Principles

1. **The page is the product.** Everything that is not the book text is a floating layer over paper and disappears when you read. Chrome appears on a tap and hides on the next.
2. **One accent, spent carefully.** `accent` marks progress and the primary action. It is never a background for text blocks and never a second brand colour.
3. **Serif for the book, sans for the app.** Literata carries titles and book text; the system sans (SF Pro) carries controls. Mixing them on one line is a mistake.
4. **Glass, not shadows.** Floating controls are Liquid Glass (`surface-glass` + `glass-blur` + `glass-border`). Their shadow (`shadow-glass`) is faint on purpose; in SwiftUI use `.glassEffect()` and add no shadow at all.
5. **Nothing the reader did not ask for.** No streaks, no badges, no words to review. A goal ring in the header, and that is the only number on Home.

## Colour

Two themes for the app (`light`, `dark`) and four reader themes that only change the page: Paper, Sepia, Night and Black (`surface-black`, pure black for OLED screens, text in `night-text`).

- Ground: `surface` (app) and `surface-paper` (reader). Cards sit on the ground in `surface-card` with `shadow-card`; grouped lists in Settings and sheets use `surface-card` with `hairline` separators.
- Text: `ink` for everything primary, `ink-muted` for authors, captions and counters, `ink-faint` for chevrons only. All three pass 4.5:1 on `surface` and `surface-card` in both themes.
- Accent: `accent` for progress bars and rings, the selected theme ring, uppercase labels that introduce the primary action, Done/Cancel in sheets, checkmarks. Solid buttons and selected chips are `ink` with `on-ink` text, not accent.
- Glass: `surface-glass` for buttons and toolbars, `surface-glass-strong` where text sits on the glass (menus, popovers, the reader sheet), both with a 1px `glass-border`.
- Reading marks: `word-tap` behind a tapped word while its bubble is open; `selection` + `selection-handle` for long-press selection; five `highlight-*` fills in the text with matching `highlight-*-solid` swatches in the colour menu and as the 4px bar in the Highlights list.
- Dark theme: the accent brightens to `#d8683a` so it holds contrast on `#151412`; solid `ink` controls invert to light with dark `on-ink` text; covers keep their colours.

## Typography

- **Display and reading:** Literata (Google Fonts, variable). `wordmark` 30/600 for the app name only; `title-book` 26/500 under the hero cover; `list-serif` 17/400 for chapter names and book titles in rows.
- **Book text:** `reading-body` 17px on a 27px line. The line height is a whole number of pixels so a paginated page always clips on a line boundary. The reader offers seven sizes; this is step 3.
- **UI:** system sans. `section` 20/600 for section headers and nav titles, `body` 16/400 for rows, `subhead` 14/500 in segmented controls and chips, `caption` 12 for page counters, `label-caps` 11/600 uppercase with 0.08em tracking.
- Bubbles and cards: the translated word is `translation` 20/500 in the bubble and 22/600 in the card; the source word is `headline` 26/600 in the card.

## Layout and shape

- Screens keep a `space-5` (20px) gutter; the reader text keeps `space-7` (28px). The nav row starts at `nav-top`.
- Touch targets are `control-h` (44px) or larger; menu rows 46–50px.
- Radii scale with the surface: covers `radius-sm`, fields and segmented controls `radius-md`, grouped lists `radius-lg`, cards and popovers `radius-xl`, sheets `radius-sheet`, pills and glass circles `radius-pill`.
- Book covers without art are generated: a flat colour block, the title in `cover-title`, the author in 8–9px uppercase, `shadow-cover` with its 3px lighter spine. Cover colours are per book and never come from the palette.

## Components in this system

Static previews of the pieces that repeat across the app: the glass button, the translation bubble, a generated book cover, a filter chip. Each README says what the app supplies and which tokens the piece uses. Screens themselves live in the Scholia design canvas.

## Iconography

Line icons at 20px on a 24px grid, 2px stroke, round caps, in `ink` (or `on-ink` on solid controls). Chevrons in `ink-faint`. The app icon is a Literata serif S; no emoji anywhere.
