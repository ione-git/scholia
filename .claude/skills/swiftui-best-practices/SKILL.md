---
name: swiftui-best-practices
description: Scholia's Swift and SwiftUI rules with their sources - state and dependencies, view performance, presentation, UIKit bridging, Swift 6.2 concurrency, SwiftData, module architecture, Liquid Glass, accessibility, localization, App Store requirements. Use when designing a feature (architect), checking a plan against best practice (expert), writing Swift code (writer), or reviewing a diff (reviewer).
---

# Swift and SwiftUI best practices

Rules for this project, each with the source it comes from (keys in brackets, URLs at the end).

- **Architect**: decide the data model, module boundaries, presentation and concurrency shape before code. Run the checklist at the end.
- **Expert**: check the architect's plan against these rules before implementation starts. Every objection names the rule number and its source.
- **Writer**: follow the rules. If a rule conflicts with the issue or the design, stop and report instead of choosing silently.
- **Reviewer**: every finding cites the rule number and its source, plus the concrete fix.

Known violations in the current code are open issues labelled `audit` (`gh issue list -R ione-git/scholia -l audit`), linked below as (#n). Do not copy a pattern an audit issue marks as wrong. Fix it only when that issue is in your scope.

## 1. State and dependencies

1.1 `@State` is `private`, initialized at the declaration, and owns view-local values. Pass values or `Binding`s down. An `@Observable` model can live in `@State`. [State]
1.2 App-wide dependencies (services, settings, clock, notification center) come from `ScholiaApp` through the environment (`.environment(object)`, `@Entry`). Feature code never reads `LaunchConfiguration.current` or other globals. [ModelData] [Entry] (#77)
1.3 The test/production switch (mock vs real provider, fixed date) happens once, in `ScholiaApp`. Production code never uses a test double. (#82)

## 2. View bodies and performance

2.1 `body` and view `init` stay cheap. No filtering, sorting, formatter or font creation, bundle lookups, text measurement or image decoding there. Compute once in `init`, keep derived data in `@State` updated from `.onChange`, or let `@Query` filter and sort. [WWDC23-10160] [WWDC25-306] (#70)
2.2 Narrow dependencies: extract subviews that take only the data they read, so unrelated state (a menu opening, an alert) does not rebuild a list. [WWDC23-10160]
2.3 Filter before `ForEach`. Each element produces a constant number of views with a stable, unique id. [WWDC23-10160] [WWDC21-10022]
2.4 One view in two states is one view with inert modifiers (ternaries), not an `if/else` that changes its identity. [WWDC21-10022]
2.5 Large repeated content inside `ScrollView` uses `LazyVStack`, `LazyHStack` or `LazyVGrid`. [LazyStacks]
2.6 Images: never decode full size for a small view and never decode in `body`/`init` on the main thread. Store a display-size thumbnail at import (`preparingThumbnail(of:)`), load it in `.task(id:)` through a `@concurrent` helper, cache it. [Thumbnail] [PrepareForDisplay] [WWDC18-219] (#69)
2.7 Performance work is measured with the SwiftUI Instruments template before and after. [WWDC25-306]

## 3. Presentation

3.1 A sheet that shows optional data is item-driven (`sheet(item:)` or the DesignSystem wrapper), never `isPresented` plus `if let`. [SheetItem] (#71)
3.2 While a sheet saves, disable Cancel and apply `.interactiveDismissDisabled(true)`. The work belongs to the owner of the data, not to an unstructured `Task` in the child. [InteractiveDismiss] (#71)
3.3 `preferredColorScheme` applies to the nearest presentation and the first non-nil value wins. Set it in one place. [ColorScheme]

## 4. UIKit and WebKit bridging

4.1 `makeUIViewController` / `makeUIView` creates the object. Never return an instance owned by a model. State goes in through `update…`, events come back through a `Coordinator`, teardown happens in `dismantle…`. No `didSet` hooks that push model state into UIKit. [Representable] (#72)

## 5. Concurrency (Swift 6.2)

5.1 Every module uses the same concurrency settings: MainActor default isolation, `NonisolatedNonsendingByDefault`, `InferIsolatedConformances`. Packages do not inherit them from the app; set them in `Package.swift`. [WWDC25-268] [SE-0466] [PkgConcurrency] (#75)
5.2 File I/O, parsing and image work run off the main actor with explicit `@concurrent`. A plain `nonisolated async` function runs on the caller's actor. [WWDC25-268]
5.3 Value types persisted by SwiftData or sent across isolation domains are `nonisolated` and `Sendable`. [WWDC25-268]
5.4 `.task` / `.task(id:)`: cancellation is cooperative. After every `await`, check `Task.isCancelled` before writing state or deleting anything, so a stale task never overwrites a newer result. [TaskID] [SwiftCancellation] (#71)
5.5 Reentrancy: set guard flags synchronously before the first `await`. Re-check assumptions after each `await`, and never mutate shared state based on what was true before a suspension. [WWDC21-10133] (#73)
5.6 Deduplicate in-flight work by caching the `Task`, not only its result (translation, future network calls). [WWDC21-10133]
5.7 Prefer structured work (`.task`, `async let`, task groups) over `Task {}` in views. An unstructured `Task` needs an owner that cancels it. [WWDC21-10134]

## 6. SwiftData and persistence

6.1 Every shipped schema is a `VersionedSchema`, and the container opens with a `SchemaMigrationPlan`. After the first release each model change adds a version plus a stage, or only adds optional properties. Lightweight migration cannot invent values for new non-optional attributes. [WWDC23-10195] [MigrationPlan] (#66)
6.2 Opening a container runs migration. Never open a store just to erase it; delete the store files by URL. [WWDC23-10195] (#66)
6.3 Persisted types belong to the app model, not to DesignSystem or ReaderEngine, and hold everything the engine needs to restore a position or highlight. Map at the module boundary. [Decisions] (#74)
6.4 `mainContext` autosaves. An explicit `save()` exists to surface the error, so handle it with `do/catch`. Never `try?` a side-effecting call. [Autosave] (#78)
6.5 Failures are logged with `Logger(subsystem: "com.ione.scholia", category: <area>)`. [Logger] [WWDC20-10168] (#78)

## 7. Architecture and modules

7.1 Local packages expose a small public interface. Readium is imported only in ReaderEngine; use Readium's parsing (metadata, cover, encryption) instead of writing a parser. [LocalPackages] [Decisions] (#76)
7.2 Each rule has one authoritative place: sort orders, book-file locations, error enums, colour types. [DRY] (#82)
7.3 A file is named after its primary type; extensions go in `Type+Feature.swift`. [SwiftStyle]
7.4 Debug-only code sits in `#if DEBUG`, apart from shipping code.

## 8. Liquid Glass (iOS 26)

8.1 Glass elements near each other share one `GlassEffectContainer`; use `glassEffectID` to morph (a menu out of its button). [Glass] [GlassContainer] [WWDC25-323] (#81)
8.2 `glassEffect` comes after the modifiers that set the look. Custom glass controls are `.interactive()` (or use the `.glass` / `.glassProminent` button styles). Tint only to convey meaning, and never add a custom shadow. [Glass] [Decisions]

## 9. Accessibility

9.1 Text scales with Dynamic Type. Design-system text styles scale through `UIFontMetrics` or `Font.custom(_:size:relativeTo:)`. Text-bearing controls use `minHeight`, not a fixed height, and icons use `@ScaledMetric`. Cap with `.dynamicTypeSize(...)` only where a layout cannot grow. Target is 200% with no overlap or severe truncation. [HIG-A11y] [FontMetrics] [LargerText] (#67)
9.2 Contrast: text up to 17 pt needs at least 4.5:1, larger or bold text 3:1, and graphics that show a control or its state 3:1. Provide high-contrast token variants for Increase Contrast. [HIG-A11y] [WCAG-1.4.11] (#79)
9.3 When Reduce Motion is on, replace scale and zoom transitions with opacity (`accessibilityReduceMotion`). [HIG-A11y] [ReduceMotion]
9.4 VoiceOver: group related elements (`.accessibilityElement(children: .combine)`) and hide decorative or duplicate images. [HIG-VoiceOver]
9.5 Accessibility identifiers are unique. Never build them from user data such as titles. [AXIdentifier]
9.6 UI tests run `performAccessibilityAudit()` on every screen. [AXAudit] [WWDC23-10035] (#80)

## 10. Localization

10.1 Every user-facing string goes through the String Catalog with a `comment:` for translators. When the same English word is used in different places, each place gets its own key with `defaultValue`. [L10nViews] [StringCatalog] [WWDC22-10110] [WWDC23-10155]
10.2 Numbers, dates, durations and measurements use Foundation formatters, never hand-written units such as `"\(n) min"`. [Formatters]
10.3 Custom icons that point in a direction flip in RTL (`flipsForRightToLeftLayoutDirection`). [HIG-RTL]

## 11. App Store requirements

11.1 `App/PrivacyInfo.xcprivacy` declares every required-reason API used by the app or by statically linked SDKs that ship no manifest. After adding a dependency, recheck with `nm -u` on a Release archive. [RequiredReason] [PrivacyManifest] (#68)
11.2 `ITSAppUsesNonExemptEncryption` is set in `App/Info.plist`. [Encryption] (#82)

## Checklist

| The plan or diff... | Check |
|---|---|
| adds or changes a SwiftData model | 6.1, 6.2, 6.3 |
| shows a sheet, popover or alert over data | 3.1, 3.2 |
| starts async work from a view | 5.2, 5.4, 5.5, 5.7 |
| shows a list, grid or images | 2.1–2.6 |
| wraps UIKit or WebKit | 4.1 |
| adds text or controls | 9.1–9.5, 10.1–10.3 |
| adds glass | 8.1, 8.2 |
| needs a service, the clock or a test override | 1.2, 1.3 |
| adds a dependency or package | 5.1, 7.1, 11.1 |

Objection format: `rule 5.4 [TaskID]: <what breaks, with file:line> -> <fix>`.

## Sources

- [State] https://developer.apple.com/documentation/swiftui/state
- [ModelData] https://developer.apple.com/documentation/swiftui/managing-model-data-in-your-app
- [Entry] https://developer.apple.com/documentation/swiftui/entry()
- [WWDC23-10160] Demystify SwiftUI performance https://developer.apple.com/videos/play/wwdc2023/10160/
- [WWDC25-306] Optimize SwiftUI performance with Instruments https://developer.apple.com/videos/play/wwdc2025/306/
- [WWDC21-10022] Demystify SwiftUI https://developer.apple.com/videos/play/wwdc2021/10022/
- [LazyStacks] https://developer.apple.com/documentation/swiftui/creating-performant-scrollable-stacks
- [Thumbnail] https://developer.apple.com/documentation/uikit/uiimage/preparingthumbnail(of:)
- [PrepareForDisplay] https://developer.apple.com/documentation/uikit/uiimage/preparingfordisplay()
- [WWDC18-219] Image and graphics best practices https://developer.apple.com/videos/play/wwdc2018/219/
- [SheetItem] https://developer.apple.com/documentation/swiftui/view/sheet(item:ondismiss:content:)
- [InteractiveDismiss] https://developer.apple.com/documentation/swiftui/view/interactivedismissdisabled(_:)
- [ColorScheme] https://developer.apple.com/documentation/swiftui/view/preferredcolorscheme(_:)
- [Representable] https://developer.apple.com/documentation/swiftui/uiviewcontrollerrepresentable/makeuiviewcontroller(context:)
- [WWDC25-268] Embracing Swift concurrency https://developer.apple.com/videos/play/wwdc2025/268/
- [SE-0466] https://github.com/swiftlang/swift-evolution/blob/main/proposals/0466-control-default-actor-isolation.md
- [PkgConcurrency] https://useyourloaf.com/blog/approachable-concurrency-in-swift-packages/
- [TaskID] https://developer.apple.com/documentation/swiftui/view/task(id:priority:_:)
- [SwiftCancellation] https://docs.swift.org/swift-book/documentation/the-swift-programming-language/concurrency/
- [WWDC21-10133] Protect mutable state with Swift actors https://developer.apple.com/videos/play/wwdc2021/10133/
- [WWDC21-10134] Explore structured concurrency in Swift https://developer.apple.com/videos/play/wwdc2021/10134/
- [WWDC23-10195] Model your schema with SwiftData https://developer.apple.com/videos/play/wwdc2023/10195/
- [MigrationPlan] https://developer.apple.com/documentation/swiftdata/schemamigrationplan
- [Autosave] https://developer.apple.com/documentation/swiftdata/modelcontext/autosaveenabled
- [Logger] https://developer.apple.com/documentation/os/logger
- [WWDC20-10168] Explore logging in Swift https://developer.apple.com/videos/play/wwdc2020/10168/
- [LocalPackages] https://developer.apple.com/documentation/xcode/organizing-your-code-with-local-packages
- [Decisions] `CLAUDE.md`, section Decisions
- [DRY] The Pragmatic Programmer, 20th anniversary edition
- [SwiftStyle] https://google.github.io/swift/#file-names
- [Glass] https://developer.apple.com/documentation/swiftui/applying-liquid-glass-to-custom-views
- [GlassContainer] https://developer.apple.com/documentation/swiftui/glasseffectcontainer
- [WWDC25-323] Build a SwiftUI app with the new design https://developer.apple.com/videos/play/wwdc2025/323/
- [HIG-A11y] https://developer.apple.com/design/human-interface-guidelines/accessibility
- [FontMetrics] https://developer.apple.com/documentation/uikit/uifontmetrics
- [LargerText] https://developer.apple.com/help/app-store-connect/manage-app-accessibility/larger-text-evaluation-criteria/
- [WCAG-1.4.11] https://www.w3.org/WAI/WCAG22/Understanding/non-text-contrast.html
- [ReduceMotion] https://developer.apple.com/documentation/swiftui/environmentvalues/accessibilityreducemotion
- [HIG-VoiceOver] https://developer.apple.com/design/human-interface-guidelines/voiceover
- [AXIdentifier] https://developer.apple.com/documentation/uikit/uiaccessibilityidentification/accessibilityidentifier
- [AXAudit] https://developer.apple.com/documentation/accessibility/performing-accessibility-audits-for-your-app
- [WWDC23-10035] Perform accessibility audits for your app https://developer.apple.com/videos/play/wwdc2023/10035/
- [L10nViews] https://developer.apple.com/documentation/swiftui/preparing-views-for-localization
- [StringCatalog] https://developer.apple.com/documentation/xcode/localizing-and-varying-text-with-a-string-catalog
- [WWDC22-10110] Build global apps https://developer.apple.com/videos/play/wwdc2022/10110/
- [WWDC23-10155] Discover String Catalogs https://developer.apple.com/videos/play/wwdc2023/10155/
- [Formatters] https://developer.apple.com/documentation/xcode/preparing-dates-numbers-with-formatters
- [HIG-RTL] https://developer.apple.com/design/human-interface-guidelines/right-to-left
- [RequiredReason] https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api
- [PrivacyManifest] https://developer.apple.com/documentation/bundleresources/privacy-manifest-files
- [Encryption] https://developer.apple.com/documentation/security/complying-with-encryption-export-regulations
