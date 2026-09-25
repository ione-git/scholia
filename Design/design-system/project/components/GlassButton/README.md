# GlassButton

A 44px Liquid Glass circle for floating actions over the page: back, bookmark, add, settings, the reader's "···" menu. It sits over content, never inside a card.

- Fill `surface-glass`, 1px `glass-border`, `backdrop-filter: blur(glass-blur) saturate(glass-saturate)`, `shadow-glass`, `radius-pill`. Size `control-h` (48px for the reader's bottom buttons).
- Icon 20px line, 2px stroke, `ink`. Icon-only buttons carry an accessibility label.
- Active / open state (the menu button while its menu is open): fill `ink`, icon `on-ink`, no glass.
- The app supplies the icon and the label. In SwiftUI: `.glassEffect(.regular, in: .circle)` with no custom shadow.
