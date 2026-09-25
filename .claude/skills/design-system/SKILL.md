---
name: design-system
description: Scholia design system for writers and reviewers - where design values live, brand rules, the visual rules that are easy to get wrong, every token with its intended use, component specs, light/dark, reader themes and typography. Use before building or reviewing any UI.
---

# Scholia design system

## Where values live

- `Design/design-system/project/tokens.json` is the source of truth for every colour, type style, spacing, radius, shadow and glass value. `Design/canvas/project/ds/scholia/tokens.json` is an identical copy.
- Screens `Design/canvas/project/*.dc.html` use the same values as literal CSS. When a screen and `tokens.json` disagree, the token wins. Examples: chip border `rgba(0,0,0,0.1)` in screens is `control-border`; search field fill `rgba(0,0,0,0.05)` is `control-fill`; dashed new-collection chip `#C9C3B7` is `ink-faint`; bubble fill `rgba(255,255,255,0.8)` is `surface-glass-strong`.
- A screen value with no matching token (e.g. search placeholder `#8A857B`): use the token with the same role (`ink-muted`). If no token fits, stop and report it. Never add a literal.
- Brand book with usage rules: `Design/design-system/project/README.md`. Product behaviour: `Design/HANDOFF.md`.
- In a screen's markup, `aria-label` is the accessibility label for icon-only controls and `href` names the screen the element opens.
- Parked screens, do not build: `Home-A`, `Home-A-Words`, `Reader-Card-Words`, `Settings-Words`.

## Brand rules

1. The page is the product. Everything that is not book text floats over paper and hides while reading.
2. One accent, spent carefully. Never a text-block background, never a second brand colour.
3. Serif for the book, sans for the app. Never mix both on one line.
4. Glass, not shadows.
5. Nothing the reader did not ask for: no streaks, badges or words to review. The goal ring is the only number on Home.

## Visual rules that are easy to get wrong

- Glass controls: SwiftUI `.glassEffect()` (circle: `.glassEffect(.regular, in: .circle)`) and no custom shadow. The CSS glass in screens (`surface-glass` + blur + `glass-border` + `shadow-glass`) is only the designer's approximation.
- Solid buttons and selected chips are `ink` fill with `on-ink` text, never `accent`.
- `accent` only for: progress bars and rings, the selected reader-theme ring, uppercase labels introducing the primary action (CONTINUE READING), Done/Cancel in sheets, checkmarks.
- `ink-faint` is for chevrons and disclosure icons only, never text.
- Reading line height is a whole number of points (27 at 17pt, 30 at 19pt on iPad) so a page clips on a line boundary. Never a multiplier.
- Generated covers: flat colour block per book, never from the palette; title in Literata, author 8-10pt uppercase with 0.08em tracking at 85% opacity; `shadow-cover` with a 3pt lighter spine on the left. Covers keep their colours in dark mode.
- The dark theme is the same layout with the dark token values. No dark-only layout.
- Popovers and the reader settings sheet have no scrim. Modal sheets (Add Book, Add to Collection) use `scrim`.
- No time-left in the reader. No dates in Bookmarks. Contents marks the current chapter with a 3pt `accent` bar only.
- Highlight fills in text use `highlight-*`. Swatches and the 4pt bar in the Highlights list use `highlight-*-solid`.
- Icons: 20pt line icons on a 24pt grid, 2pt stroke, round caps, `ink` (or `on-ink` on solid controls). No emoji.
- App icon: Literata "S" with a rust marker stroke behind its lower half. Launch screen: the same glyph centred, no text.

## Colour tokens (light / dark)

| Token | Light | Dark | Use |
|---|---|---|---|
| `surface` | #f4f2ed | #151412 | App background: Home, Library, Settings, sheets. Never pure white. |
| `surface-paper` | #f7f5f0 | #1a1917 | Reader page, Paper theme. The dark value is the Night theme. |
| `surface-sepia` | #efe3cb | same | Reader page, Sepia theme (light only). |
| `surface-black` | #000000 | same | Reader page, Black theme (OLED). Reader only. |
| `surface-card` | #ffffff | #26241f | Cards, grouped lists, chips at rest, sheet contents. |
| `surface-glass` | rgba(255,255,255,0.7) | rgba(40,38,34,0.72) | Glass buttons and toolbars. |
| `surface-glass-strong` | rgba(255,255,255,0.88) | rgba(40,38,34,0.88) | Glass with text on it: menus, popovers, reader sheet, bubble. |
| `glass-border` | rgba(255,255,255,0.85) | rgba(255,255,255,0.12) | 1pt inner edge of glass. |
| `ink` | #1d1b17 | #edeae3 | Primary text and icons; fill of solid buttons and selected chips. |
| `ink-muted` | #6c675e | #9b968c | Authors, captions, page counters, section labels. |
| `ink-faint` | #b9b4a9 | #5e5a52 | Chevrons and disclosure icons only. |
| `on-ink` | #ffffff | #151412 | Text and icons on an `ink` fill. |
| `accent` | #b0471f | #d8683a | See the accent rule above. |
| `accent-tint` | rgba(176,71,31,0.12) | rgba(216,104,58,0.18) | Fill behind an active accent control (pressed goal ring). |
| `on-accent` | #ffffff | #ffffff | Text on an accent fill. |
| `track` | #e3dfd6 | #33312d | Empty part of progress bars, rings, sliders; grabbers. |
| `hairline` | rgba(0,0,0,0.08) | rgba(255,255,255,0.1) | 0.5pt separators in grouped lists and menus. |
| `control-fill` | rgba(0,0,0,0.06) | rgba(255,255,255,0.08) | Segmented controls, steppers, search field. |
| `control-border` | rgba(0,0,0,0.12) | rgba(255,255,255,0.14) | 0.5pt border of outlined pills and chips at rest. |
| `word-tap` | rgba(255,196,64,0.5) | rgba(255,196,64,0.35) | Behind the tapped word while its bubble is open. |
| `selection` | rgba(10,102,194,0.22) | rgba(90,160,255,0.3) | Long-press text selection. |
| `selection-handle` | #0a66c2 | #5aa0ff | Selection handles and carets. |
| `highlight-yellow` / `-green` / `-blue` / `-pink` / `-purple` | alpha 0.42 (yellow) / 0.4 | alpha 0.35 | Highlight fills in text. Yellow is the default. |
| `highlight-*-solid` | #f2c94c #7bc67e #6fa8f5 #f28bb0 #b48cf2 | same | Colour-menu swatches, Highlights list bar. |
| `danger` | #b3261e | #e5675f | Destructive items: Remove from Library, delete highlight. |
| `scrim` | rgba(29,27,23,0.32) | rgba(0,0,0,0.5) | Dim behind modal sheets only. |
| `night-text` | #e6e2d9 | same | Book text in Night and Black. |
| `sepia-text` | #4a3a22 | same | Book text in Sepia. |

## Typography

Serif = Literata (variable, bundled by #5). Sans = system SF Pro. Sizes in pt.

| Style | Family | Size / line / weight | Use |
|---|---|---|---|
| `wordmark` | serif | 30 / 1.0 / 600, -0.01em | App name in the Home header only. |
| `title-book` | serif | 26 / 1.15 / 500 | Book title under the hero cover. |
| `title-card` | serif | 22 / 1.15 / 500 | Book title in a card row. |
| `list-serif` | serif | 17 / 1.3 / 400 | Chapter names, book titles in list rows. |
| `cover-title` | serif | 14 / 1.2 / 500 | Title on a generated cover (12-24 by cover size). |
| `reading-body` | serif | 17 / 27pt / 400 | Book text, size step 3 of 7. iPad 19 / 30. |
| `reading-quote` | serif | 16 / 1.5 / 400 | Quote in the Highlights list. |
| `headline` | sans | 26 / 1.1 / 600, -0.01em | Word in the translation card. |
| `translation` | sans | 20 / 1.2 / 500 | Translation in the bubble; 22/600 in the card. |
| `section` | sans | 20 / 1.2 / 600 | Section headers on Home, nav bar titles. |
| `title-3` | sans | 17 / 1.25 / 600 | Row titles, sheet titles, Done. |
| `body` | sans | 16 / 1.3 / 400 | Rows in grouped lists and menus, inputs. |
| `callout` | sans | 15 / 1.35 / 500 | Edit-menu items, chips. |
| `subhead` | sans | 14 / 1.3 / 500 | Segmented controls, chip labels, page numbers in Contents. |
| `footnote` | sans | 13 / 1.35 / 400 | Secondary lines under titles. IPA and grammar line in the bubble are 12. |
| `caption` | sans | 12 / 1.3 / 400 | Page counter, meta under highlights, cover captions. |
| `label-caps` | sans | 11 / 1.2 / 600, 0.08em, uppercase | `accent` when it introduces the primary action, else `ink-muted`. |

## Spacing, radius, shadow, effects

- Spacing: `space-1` 4 (tight icon-text), `space-2` 8 (between chips, title-subtitle), `space-3` 12 (between covers or cards), `space-4` 16 (card and sheet padding, between sheet sections), `space-5` 20 (screen side gutter, always), `space-6` 24 (between major blocks on Home), `space-7` 28 (reader text side margin), `space-8` 32 (above a hero), `space-10` 40 (bottom inset of the last block; 64 on Home), `control-h` 44 (minimum touch target; menu rows 46-50), `nav-top` 62 (top of the nav row below the status bar).
- Radius: `radius-xs` 4 (tapped-word tint, small thumbnails), `radius-sm` 6 (covers; 8 hero, 4 under 60pt wide), `radius-md` 12 (search field, segmented controls, steppers), `radius-lg` 18 (grouped lists, chapter rows), `radius-xl` 22 (Home cards, popovers, menus; bubble 20), `radius-2xl` 24 (hero card, bottom toolbar), `radius-sheet` 36 (sheet top corners), `radius-pill` 999 (pills, chips, glass circles, toggles, swatches).
- Shadow: `shadow-card` (white cards on paper), `shadow-popover` (popovers, menus; bubble 0 8 24 at 0.12), `shadow-sheet` (bottom sheets), `shadow-cover` (every cover, with the 3pt spine), `shadow-cover-hero` (the one large Home cover, glow in the cover's own hue). `shadow-glass` exists for the canvas only: glass gets no shadow in SwiftUI.
- Effects: `glass-blur` 20 (24 bubble, 30 popovers and sheets), `glass-saturate` 1.4 (1.5 popovers), `hairline-w` 0.5. With `.glassEffect()` these are the system's job.

## Components

Specs in `Design/design-system/project/components/<Name>/README.md`, static previews in `preview.html` next to them. Built by #6, except TranslationBubble (word tap bubble, 4.2).

- GlassButton: 44pt glass circle (48 for the reader's bottom buttons), 20pt `ink` icon, accessibility label required. Open state: `ink` fill, `on-ink` icon, no glass. Over content, never inside a card.
- TranslationBubble: width 236, padding 12/14, radius 20, `surface-glass-strong`. Row 1 word 13/600 + IPA 12 `ink-muted`; row 2 `translation`; row 3 lemma and part of speech 12 `ink-muted` + chevron `ink-faint`. Loading: 132x14 `track` bar and three `accent` dots. Clamped 16pt from page edges, flips below the word when there is no room above. Minimal variant: 150x40 pill.
- BookCover: 2:3. Sizes 40x60, 80x120, 100x150, 107x152, 160x240, 180x270. Finished badge: `ink` check. Home only: thin `accent` progress bar on `track` under the cover.
- Chip: height 36, padding 0 14, `radius-pill`, `subhead` label + count. Rest: `surface-card`, 0.5pt `control-border`, count `ink-muted`. Selected: `ink` fill, `on-ink` label, count at 60% opacity. New-collection chip: 36pt square, 1pt dashed `ink-faint`, 16pt plus in `ink-muted`. The row is hidden when there are no collections.

## Light and dark

- App themes: System (default), Light, Dark (Settings). Every screen must work in both with the token swap; nothing is tuned per screen.
- Designed dark references: `Home-Dark`, `Library-Dark`, `Card-Dark`, `Sheet-Dark`, `Reader-Dark` (Night), `Launch-Dark`, `Icon-V1-Dark`. Other screens: light layout + dark token values.
- Dark specifics: `accent` brightens to #d8683a; solid `ink` controls invert to light with dark `on-ink` text; covers keep their colours.

## Reader themes

A reader theme changes only the page background and the book text colour.

| Theme | Page | Text |
|---|---|---|
| Paper | `surface-paper` light #f7f5f0 | `ink` |
| Sepia | `surface-sepia` #efe3cb | `sepia-text` |
| Night | `surface-paper` dark #1a1917 | `night-text` |
| Black | `surface-black` #000000 | `night-text` |

Appearance System: keep the chosen light theme (Paper or Sepia) by day, Night when iOS is dark. Sepia is light only; `tokens.json` says Night or Black replaces it in dark. Black on non-OLED devices is an open decision in HANDOFF (design says yes).

## iPad

Same screens at 834pt wide portrait: 32pt gutters, 5-column library, reader measure 642pt at 19/30, settings list 600pt wide centred, bubble scale = width / 834.

## Swift API

`import DesignSystem`. Token values live in `Packages/DesignSystem/Sources/DesignSystem/GeneratedTokens.swift`, generated from `tokens.json` by `python3 scripts/generate_tokens.py`. Never edit that file: change `tokens.json`, re-run the script, commit both. Swift names are token names in lowerCamelCase: `surface-card` → `surfaceCard`, `space-5` → `space5`, `radius-2xl` → `radius2xl`, `label-caps` → `labelCaps`.

- Colours: `.foregroundStyle(.ink)`, `.background(.surface)`, `.fill(.accent)`, `.stroke(.controlBorder, lineWidth: .hairlineW)`, `Color.inkMuted`. They are dynamic and follow light/dark (also `.environment(\.colorScheme, …)`). `selection` clashes with SwiftUI's `.selection` shape style: write `Color.selection`. A fixed variant: `ColorToken.surfacePaper.light` / `.dark`.
- Text styles: `.textStyle(.body)` sets font, tracking, exact line height and uppercase (`labelCaps`). `TextStyle.readingBody.lineHeight` is 27; `.font` / `.uiFont` where an API needs a font. Serif styles use the bundled Literata roman at the token weight; sizes are fixed (no Dynamic Type).
- Spacing, radius, effects are `CGFloat` constants: `.padding(.horizontal, .space5)`, `VStack(spacing: .space2)`, `RoundedRectangle(cornerRadius: .radiusXl)`, `.frame(minHeight: .controlH)`. `glassBlur` and `glassSaturate` describe the canvas glass only: in SwiftUI use `.glassEffect()`.
- Shadows: `.shadow(.card, in: RoundedRectangle(cornerRadius: .radiusXl))`, names without `shadow-` (`card`, `popover`, `sheet`, `cover`, `coverHero`, `glass`). Draws every CSS layer: drop shadows behind the shape (meant for opaque surfaces), the 0.5pt ring, the inset cover spine. Never on glass. The hero glow in the cover's own hue is not a token value: BookCover supplies it.
- Reader themes: `ReaderTheme.paper`, `.sepia`, `.night`, `.black`, each with fixed `page` and `text` colours.
- Literata: variable roman + italic TTFs and `OFL.txt` in `Packages/DesignSystem/Sources/DesignSystem/Fonts`, registered by `DesignSystem.registerFonts()` in `ScholiaApp.init`.
- Lists for tooling: `ColorToken.all`, `TextStyle.all`, `NumberToken.spacing` / `.radius` / `.effects`, `ShadowToken.all`. The Debug-only Token Gallery (root placeholder → Token Gallery, `App/Sources/TokenGallery.swift`) shows them all.

Components (Debug-only Component Gallery: root placeholder → Component Gallery, `App/Sources/ComponentGallery.swift`, every component in light and dark). User-facing text is passed in as `Text` from the app, so it stays in the app's String Catalog.

- `GlassButton(.back, label: Text("Back"), size: .regular, isActive: false) { … }`: 44pt glass circle, `.reader` is 48pt. `isActive` draws the open state (`ink` fill, `on-ink` icon, no glass) and adds the selected trait.
- `Icon`: line icons drawn from the screens' SVG paths on the 24pt grid (`back`, `add`, `bookmark`, `more`, `chevron`, `check`). A new icon is a new case with the path from the screen.
- `Chip(Text(name), count: 5, isSelected: true) { … }` and `NewCollectionChip(label: Text("New collection")) { … }`. The scrolling row and hiding it without collections are the feature's.
- `BookCover(title:author:color:image:size:isFinished:finishedValue:)`: sizes `.thumbnail` 40x60, `.row` 80x120, `.grid` 100x150, `.library` 107x152, `.hero` 160x240 and `.heroLarge` 180x270 (hero glow), `Size.width` / `.height` for layout. `color` is the generated block and the hue of the hero glow, so pass it with an `image` too. A title word too long for the cover shrinks the title instead of breaking mid-word. The cover is one accessibility element labelled with the title; `finishedValue` (e.g. `Text("Finished")`) is its accessibility value while `isFinished`. `ProgressBar(value:)` (0…1) is the Home bar: give it the cover's width.
- `GroupedSection(Text("Translation")) { rows }` (`label-caps` header + list), `GroupedList { rows }` (`surface-card`, `radius-lg`, hairline between rows), `ListRow(Text("Translate to"), height: .regular) { trailing }` (`.regular` 50pt, `.control` 56pt for a row holding a segmented control), `ListRowValue(Text("Russian"))` (value + chevron), `ListRowChevron()`. A tappable row is a `Button` or `NavigationLink` with `.buttonStyle(.plain)` around a `ListRow`.
- `SegmentedControl(selection:size:segments:)` with `.init(value, title:count:identifier:)`: `.regular` fills the width with equal 36pt segments, `.compact` hugs its labels at 30pt. Selected segment: `surface-card` with `shadow-card`, title at 600 (`subhead` weighted to `title-3`), count stays 500.
- Sheets: `.modalSheetStyle()` on modal sheet content (`surface`, `radius-sheet`, grabber; iOS draws the dimming), `.glassSheetStyle()` for the reader settings sheet (system glass, no dimming, the page stays interactive). `SheetHeader(Text("Add Book")) { Button("Cancel") { … }.buttonStyle(.sheetCancel) } trailing: { Button("Done") { … }.buttonStyle(.sheetDone) }` (`EmptyView()` for a missing side).
- Popovers: `.popoverStyle()` on the popover content keeps it a popover on iPhone (system glass).

If a feature needs a token or component that does not exist yet, stop and report.
