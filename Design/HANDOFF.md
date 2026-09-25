# Scholia — handoff for the implementing agent

## What it is
Scholia is an iOS reader (iPhone + iPad, iOS 26, SwiftUI, Liquid Glass) for reading books in languages you are learning. The one feature that matters: **tap a word → its contextual translation appears where you read**, nothing else moves. Everything else is a quiet paper page with glass controls that hide while reading. Users bring their own EPUBs; there is no store.

## Where the design lives
- `canvas/project/*.dc.html` — one HTML file per screen (390×844; iPad row 834×1194). `canvas.json` holds positions plus the flow: every arrow note (`kind: "arrow"`) starts at the element that triggers it and points at the resulting screen; the sticky next to it names the action.
- `design-system/project/tokens.json` — **source of truth for every value** (colour light/dark, type, spacing, radius, shadow, glass). Screens use the same values as literal hex; when they disagree, tokens win. `README.md` there is the brand book with usage rules per token; `components/*/README.md` describe the four repeating pieces (GlassButton, TranslationBubble, BookCover, Chip).
- Live artifacts: canvas https://claude.ai/code/artifact/b508b7dc-37f9-487d-ab49-a627c54ef9b8, design system https://claude.ai/artifact/3JncvgG2jiEbSg7jqqnSe2.

## MVP scope
In: import EPUB, library with collections, paginated reader with themes, tap-to-translate (bubble / minimal / card), long-press selection, highlights with 5 colours, contents, daily reading goal, light + dark app themes, reader themes Paper / Sepia / Night / Black, iPad portrait.
Out (designed but parked, do not build): saved words / vocabulary review (`Home-A-Words`, `Reader-Card-Words`, `Settings-Words`), footnotes/endnotes, per-book target language, PDF, search results UI (entry point exists, results screen not designed), iPad landscape two-page spread, curl page-turn animation (keep the option in the list; ship Slide, Fast fade, Scroll).

## Navigation
No tab bar. `Main.dc.html` (Home) is the root; everything is a push, popover or sheet from it.
- Home: wordmark + goal ring → `Home-Goal` popover (minutes read inside the ring, "N min to go"; the goal itself is set in Settings). When the goal is reached the ring becomes a filled accent disc with a cream check (`Home-Done-3`); its popover shows the minutes inside the ring and "Goal done" only (`Home-Done-Goal`). Hero cover → `Reader`. "+" → system Files picker (EPUB) → `Import` (Add Book sheet). Gear → `Settings`. "Library / All N" → `Library-A`.
- First launch, no books (`Home-Empty`): same header (ring at 0, "+", gear), no hero, no Library section; a centred dashed cover placeholder, "No books yet", one line about Files / share sheet, and an ink "Add a Book" pill — both the placeholder and the pill open the Files picker. The moment the first book is added, Home becomes `Main`.
- Books shared from other apps (Open in…) land in the same Add Book sheet.

## Screens and behaviour
**Add Book** (`Import`, `Import-Language`): cover extracted from the file, editable title/author, `Language · German · detected` is a tappable row → language list with search; the book's language drives word segmentation and the translation source language. `Collection · None ›` opens the same Add to Collection sheet; a book may belong to zero or several collections.

**Library** (`Library-A`, `Library-Empty`, `Library-Sort`, `Library-Select`, `Library-NewCollection`, `Library-Menu`, `Library-AddTo`, `Library-Finished`, `Library-Info`, `Library-Remove`): search field; chip row of collections (hidden entirely when there are none; "+" chip creates one); 3-column grid (5 on iPad). "…" menu: Select Books (multi-select with bottom glass bar: Collection · Finished · Remove), New Collection (alert with name), Sort by (Recently opened / Recently added / Title / Author). Long press on a cover: Add to Collection (checklist, multi), Mark as Finished (ink check badge on the cover; menu item becomes Mark as Unread), Book Info (sheet: fields, language, collections, progress, highlights count, reset progress), Remove from Library (confirmation: file and highlights deleted from device).

**Reader** (`Reader`, `Reader-Chrome`, `Reader-Menu`, `Reader-Menu-Settings`, `Reader-Contents-2`, `Reader-Highlights`, `Reader-Bookmarks`): paginated by default, Literata 17/27 on paper, running head (book title) top, page counter "3 of 78" bottom, no time-left anywhere. Tap empty page area toggles the chrome: back, bookmark, page counter, one "···" glass button bottom-right. The menu holds Search, Contents, Highlights, Bookmarks, Themes & Settings. The bookmark button in the chrome toggles a bookmark on the current page (filled icon = bookmarked, one bookmark per page). Themes & Settings is a bottom sheet: theme circles Paper/Sepia/Night/Black, font chips (Literata default), size slider (7 steps, step 3 default), Page turn segmented (Slide/Curl/Fade/Scroll), line spacing, Lock rotation button. Appearance "System" in Settings = keep the chosen light reader theme by day, Night when iOS goes dark. Contents, Highlights and Bookmarks are one screen with a three-tab segmented control (counts on Highlights and Bookmarks); the menu items just open the matching tab. Contents: chapter names with start page, current chapter marked by a 3px accent bar (no progress, no current page). Highlights: quotes with a 4px colour bar, tap = jump to the place. Bookmarks: "Page N · chapter" plus the first line of that page in serif, tap = jump to the page; no dates anywhere.

**Translation** (`Reader-Loading`, `Reader-Bubble`, `Pill-Loading`, `Bubble-Pill`, `Reader-Card`): on tap the word gets the `word-tap` tint and the bubble appears **immediately** with the word and IPA; the contextual translation (LLM with sentence context — "run a company" must yield "управлять", not "бежать") fills in asynchronously, 0.5–1.5 s is acceptable, show the skeleton bar + three dots meanwhile. Bubble 236px, clamped 16px from the page edges, flips below the word when there is no room above. Tap the bubble → word card (headword, IPA, lemma + part of speech, meaning in this context, all dictionary meanings, pronounce). Setting "On word tap": Bubble / Minimal (150×40 pill with only the translation) / Card. Target language is one global setting (Settings → Translate to).

**Selection and highlights** (`Reader-Select`, `Reader-Highlighted`, `Reader-DragHighlight`): long press without moving = standard text selection with the menu Highlight · Translate · Copy (Highlight applies immediately, no navigation). Long press and drag = paints a highlight directly in the last used colour, no menu. Tap an existing highlight = colour pill (yellow, green, blue, pink, purple + delete). Highlight fills use `highlight-*`, list bars `highlight-*-solid`.

**Settings**: Translate to; On word tap (Bubble/Minimal/Card); Daily goal (minutes); Reminder time toggle; Theme System/Light/Dark; Sort books by. Nothing about words/vocabulary.

## Visual rules that are easy to get wrong
- Glass controls: `surface-glass` + blur 20 + 1px `glass-border`; in SwiftUI use `.glassEffect()` and **no custom shadow**. Solid buttons and selected chips are `ink` with `on-ink` text — never the accent.
- One accent (`accent`, #b0471f light / #d8683a dark): progress, active theme ring, uppercase labels for the primary action, Done/Cancel, checkmarks.
- Serif (Literata, Google Fonts variable) for book text and titles; system sans for all controls. Reading line height is an integer number of px so a page clips on a line boundary.
- Generated covers: flat colour block per book, title in Literata, author 8–9px uppercase; `shadow-cover` with a 3px lighter spine.
- Dark theme = same layout with the token swap in `tokens.json` (dark values); covers keep their colours.
- App icon: Literata "S" with a rust marker stroke behind its lower half (`Icon-V1`, `Icon-V1-Dark`). Launch screen: the same glyph centred, no text (`Launch-Light`, `Launch-Dark`).

## iPad
Same screens at 834×1194, portrait (`iPad-Home`, `iPad-Library`, `iPad-Reader`, `iPad-Reader-Menu`, `iPad-Settings`): 32px gutters, 5-column library, reader measure 642px at 19/30, settings list 600px wide centred, bubble scale = width/834. No iPad-only elements yet. Not designed: centred form sheets, landscape two-page spread.

## Open decisions for engineering
Translation provider and dictionary source; EPUB rendering engine and how tap-word / selection / highlight anchors map to CFI-like positions; Curl animation (private API in Books — ship without it); whether Black theme is offered on non-OLED devices (design says yes, as an option).
