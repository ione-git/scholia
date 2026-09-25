# Scholia

iOS reader for books in languages you are learning. Tap a word, its translation appears where you read. iPhone + iPad, iOS 26, SwiftUI, Liquid Glass. Goal: App Store.

## Sources of truth

- Product and behaviour: `Design/HANDOFF.md`.
- Screens: `Design/canvas/project/*.dc.html`, flow in `canvas.json`. Live canvas: https://claude.ai/code/artifact/b508b7dc-37f9-487d-ab49-a627c54ef9b8
- Values (colour, type, spacing, radius, shadow): `Design/design-system/project/tokens.json`. Tokens win over literal values in screens.
- Plan: `docs/ROADMAP.md`, one GitHub issue per feature.

## Decisions

- EPUB engine: Readium, hidden behind our own reader module interface. Nothing outside that module imports Readium. Positions and highlights are stored in our own format, so the engine can be replaced without touching screens, data or tests.
- Translation: behind a provider interface. Word translation via Apple Translation (on device). IPA and dictionary meanings come from a mock that returns one fixed value. A server provider comes later and plugs into the same interface.
- UI language: English only, but every user-facing string goes through the String Catalog so new languages cost only translation.
- Minimum iOS 26. Glass controls use `.glassEffect()` with no custom shadow.
- App is free. No accounts, no analytics.

## Scope

In: see MVP in `Design/HANDOFF.md`, plus Curl page turn and a Bookmarks list.
Out: saved words / vocabulary, footnotes, per-book target language, PDF, reader search (menu item hidden), iPad landscape spread.

## Process

- One feature = one issue = one branch = one PR. Branch: `feature/<issue-number>-<slug>`. PR body: `Closes #<issue>`.
- One writer agent per feature. Researchers and reviewers are called as needed.
- Independent features always run in parallel, each in its own worktree.
- Review before PR: code, design fidelity (simulator screenshot vs screen), UI test quality. Every screen checked in light and dark.
- PR merges after green CI and clean review. Owner is called only for decisions and the reader go/no-go.
- The owner explicitly allows every agent working on this repository to commit and push feature branches without asking (owner, 2026-09-25). Never push to `main`.

## Project layout and commands

- `project.yml` is the project definition (XcodeGen). `Scholia.xcodeproj` is generated and not committed: change `project.yml`, never the project file.
- `App/` app target (`Sources/`, `Resources/`), `UITests/` UI tests, `Fixtures/` test EPUBs (Debug builds only, regenerate with `python3 scripts/make_fixtures.py`), `Packages/DesignSystem`, `Packages/ReaderEngine` (the only module allowed to import Readium).
- Tools: Xcode 26.4.1 with the iOS 26.4 simulator runtime (same in CI), `brew install xcodegen`. Formatting and lint use the `swift-format` bundled with Xcode, config in `.swift-format`.
- `make generate` — generate the project.
- `make build` — build app and tests.
- `make test` — run all UI tests; `make test ONLY=ScholiaUITests/SmokeTests/testAppLaunches` for one test.
- `make lint` / `make format` — check / fix formatting.
- `make resolve` — update `Package.resolved` (pinned Swift package versions, copied into the generated project by `make generate`) after changing package dependencies.
- `make device DEVICE=<id>` — build Debug, install and launch on a real iPhone (signing team is in `project.yml`; ids from `xcrun devicectl list devices`).
- `DESTINATION` and `DERIVED_DATA` can be overridden, e.g. for a separate simulator per worktree.

## Code rules

- Swift, SwiftUI. No comments in code.
- Colours, fonts, spacing, radii only through the design system. No literal hex or magic numbers in feature code.
- Every interactive element has an accessibility identifier `screen.element` (e.g. `library.searchField`). Icon-only buttons have an accessibility label (see `aria-label` in screens).
- Tests: UI tests only (XCUITest). Every feature ships with UI tests for its flows. Translation and other external services are mocked in tests. How to write and run them: skill `ui-tests`.
