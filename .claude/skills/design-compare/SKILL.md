---
name: design-compare
description: Compare a Scholia screen with its design - render the canvas screen to PNG with scripts/render-screen, take the committed reference snapshots (UITests/__Snapshots__) in light and dark, and judge the differences. Use for the writer's self-check and for design review.
---

# Design compare

Read `.claude/skills/design-system/SKILL.md` first: every judgement below is against its tokens and rules.

## 1. Find the screens

The issue and `Design/HANDOFF.md` ("Screens and behaviour") name the screens. Each is `Design/canvas/project/<Screen>.dc.html`; board sizes are in `canvas.json` (390x844, iPad 834x1194, icons 512x512). Dark references exist only for `Home-Dark`, `Library-Dark`, `Card-Dark`, `Sheet-Dark`, `Reader-Dark`, `Launch-Dark`, `Icon-V1-Dark`.

## 2. Render the design

```
scripts/render-screen Design/canvas/project/Main.dc.html build/design/Main.png
```

- macOS only, no dependencies: a Swift script that loads the screen in an offscreen WKWebView at its board size and snapshots it. About 6 s per screen. Output is 2x on a Retina Mac (780x1688 for a phone board).
- The export lacks the designer tool's `support.js`; the script fills the templates itself (`{{…}}`, `<sc-for>`, `<sc-if>`, `renderVals()`, and the bubble position that screens measure after load), so library grids and bubbles render complete.
- Literata comes from Google Fonts at render time. If the script warns that Literata did not load, serif text in the render is Georgia: do not report font differences from that render.
- Backdrop blur is not rendered: glass shows as its translucent fill with the content behind it sharp. Judge glass by presence, shape, size and fill, not by blur.
- If the output looks wrong, read the screen's markup: it is the spec, the PNG is a convenience.
- Component previews render the same way: `scripts/render-screen Design/design-system/project/components/Chip/preview.html build/design/Chip.png`. The script defines the CSS variables from `tokens.json` and snapshots the preview at its content size; `--dark` (previews only) uses the dark token values. The app side is the Component Gallery: `ComponentGalleryTests` attaches `GlassButton`, `Chip` and `BookCover` (and `-Dark`) plus list rows, segmented control, sheets and popover, selectable covers and the glass toolbar (`Selection`).

## 3. Screenshot the app

Every design screen has reference snapshots committed by its UI tests (skill `ui-tests`, Snapshot tests): `UITests/__Snapshots__/<TestClass>/<Screen>.light.png` and `<Screen>.dark.png`, named after the design file (`Library-A.dark.png` pairs with `Library-Dark` when that exists). They are the app side of the comparison: CI fails when the app stops matching them.

- Find them: `ls UITests/__Snapshots__/*/<Screen>.*.png`. A writer records them with `make snapshots … ONLY=ScholiaUITests/<Screen>Tests`, then compares.
- They are iPhone 17 Pro at 3x without the status bar and the home-indicator strip: 1206×2358 px = 402×786 pt, and y = 0 in the image is y = 54 pt on the screen. Add 54 pt before comparing a top offset with the board, whose content starts below its own status bar area; the bottom 34 pt of the screen are not in the image.
- A screen or appearance without a reference is a gap in the tests, not something to screenshot by hand.

The simulator itself is needed only for the system launch screen (it has no reference) and for a quick look at a state no test reaches yet. Take a simulator from the pool with `scripts/sim create <name>` (`--ipad` for iPad; queues if all are busy, give it back with `scripts/sim delete <name>` right after); it boots it and prints the udid; run it before any `simctl ui`, `install`, `launch` or `io`, which fail on a shut-down simulator. Set the appearance before each run:

```
xcrun simctl ui <udid> appearance light
xcrun simctl ui <udid> appearance dark
```

With the app theme at System it follows the simulator appearance. The reader page theme (Paper/Sepia/Night/Black) is separate: set it through the app for reader screens.

- The first screen after launch, after `make build DESTINATION=…`, per appearance:
  ```
  xcrun simctl install <udid> build/DerivedData/Build/Products/Debug-iphonesimulator/Scholia.app
  xcrun simctl ui <udid> appearance light
  xcrun simctl launch --terminate-running-process <udid> com.ione.scholia
  sleep 2
  xcrun simctl io <udid> screenshot build/design/<Screen>-light.png
  ```
  Set the appearance before launching and wait for the launch animation, otherwise the shot catches the app zooming in or half-switched. Look at every shot and retake one that shows a transition.
- Legacy, until a screen's tests are migrated to snapshots: its flow test calls `attachScreenshot("<Screen>")`. Run it once per appearance and export the attachments (`rm -rf build/design/light` first, then `xcrun xcresulttool export attachments --path <bundle> --output-path build/design/light`; `manifest.json` maps files to names). Report the missing reference as a test gap.

## 4. Compare

Open the render and the reference (or screenshot) with Read, side by side. To zoom into a detail crop both (`sips -c <height> <width> --cropOffset <y> <x> in.png --out crop.png`, pixels).

Work in points. Render pixels / 2, iPhone screenshot pixels / 3, iPad screenshot pixels / 2. Boards are 390x844 but the iPhone 17 Pro is 402x874 and the iPad Pro 11-inch is 834x1210: compare fixed metrics, not the absolute position of things that stretch or pin to the right or bottom edge.

Light: compare against the render. Dark: compare layout against the `-Dark` render if there is one, else against the light render, and colours against the dark values in `tokens.json`.

A mismatch (report or fix):
- Spacing: gutters, paddings, gaps, nav row top off by 2pt or more.
- Sizes: controls, covers, bubbles, rows, icons, touch targets.
- Colours: any fill, text or icon that is not the token for its role in the current theme; accent where the design has ink or the reverse.
- Fonts: serif vs sans, size, weight, tracking, uppercase, reading line height.
- Radii and corner style.
- Glass: floating control not glass, glass with a custom shadow, glass where the design has a solid fill or the reverse.
- Elements missing, extra, reordered or misaligned; wrong icon; wrong state (selected, open, disabled).
- Dark: anything that is not the token swap (hard-coded light colour, invisible text, cover colours changed).

Not a mismatch:
- Sample data: titles, authors, counts, cover colours, book text, translations, and text wrapping that follows from it.
- Status bar, home indicator, device width and height differences.
- The look of Liquid Glass versus the CSS approximation (refraction, highlights, blur strength).
- System UI drawn by iOS: Files picker, alerts, context menus, keyboard, share sheet. Native wins.
- Anti-aliasing and sub-point rendering differences.

## 5. Report

One line per mismatch: screen and theme, what differs with both values in points or token names, the SwiftUI view file:line responsible, the fix (token or component to use). Say "matches" per screen and theme with no mismatch.
