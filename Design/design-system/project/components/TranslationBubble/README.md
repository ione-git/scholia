# TranslationBubble

The popover that appears above (or below, near the top of the page) a tapped word. It shows at once with the word and its IPA, then fills with the contextual translation about a second later. Tapping it opens the word card.

- Width 236px, padding 12/14, `radius-xl` (20px), `surface-glass-strong` with `glass-blur` 24px, `glass-border`, `shadow-popover` (0 8px 24px 0.12 in the app).
- Row 1: the word in `callout`-weight 13px/600, IPA in `caption` `ink-muted`. Row 2: the translation in `translation`. Row 3: lemma and part of speech in `caption` `ink-muted`, a chevron in `ink-faint`.
- Loading: row 2 is a 132×14 `track` bar; three dots in `accent` fading to its tints.
- Minimal variant (setting "On word tap: Minimal"): a 150×40 pill with only the translation and a chevron.
- Behind the word in the page: `word-tap` tint, `radius-xs`.
- The app supplies the word, IPA, translation, lemma, part of speech and the loading state; horizontal placement is clamped to a 16px inset from the page edge.
