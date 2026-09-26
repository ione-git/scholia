---
name: ship-feature
description: The writer's procedure for one Scholia feature - issue to branch, own simulator, implementation, UI tests, lint and tests, design self-check in light and dark, commit and push, final report. Use when you are the writer agent for a GitHub issue.
---

# Ship a feature

You are the only writer for one issue, in your own git worktree. The orchestrator runs reviewers, opens the PR and merges. You never open, edit or merge PRs, never push to `main`, never force-push, never close issues.

## 1. Read

- `gh issue view <n> -R ione-git/scholia`: Scope, Depends on, Done when. If a dependency is not merged into `origin/main` and the orchestrator did not give you a base branch, stop and report.
- `CLAUDE.md`, the HANDOFF sections for the feature, and the screens they name (`Design/canvas/project/<Screen>.dc.html`).
- Skills: `.claude/skills/design-system/SKILL.md`, `.claude/skills/ui-tests/SKILL.md`, `.claude/skills/design-compare/SKILL.md`.
- Scope: `CLAUDE.md` overrides HANDOFF's MVP list (Curl page turn and the Bookmarks list are in; the reader Search menu item is hidden).

## 2. Branch and simulator

```
git fetch origin
git checkout --no-track -b feature/<n>-<slug> origin/main
scripts/sim create Scholia-<n>
```

`scripts/sim` hands out simulators from a shared pool (3 iPhone, 1 iPad) and queues you when all are busy. Take one right before you build-for-test, run tests or take screenshots, and give it back with `scripts/sim delete <name>` as soon as you are done — write code without holding one. `create` with the same name returns the simulator you already hold. For iPad work add `scripts/sim create Scholia-<n>-iPad --ipad`. `scripts/sim delete <name>` removes one. Pass your own simulator to every build and test run: `DESTINATION='platform=iOS Simulator,id=<udid>'`. DerivedData (`build/`) is already per worktree.

## 3. Implement

- Follow CLAUDE.md "Code rules" and "Decisions". Change `project.yml`, never the generated project.
- Values only through the design system (see its Swift API section). A missing token or component is a stop-and-report, not a literal.
- Readium is imported only in `Packages/ReaderEngine`. Translation only through the provider interface.
- User-facing text through the String Catalog: `Text("…")`, `String(localized:)`, `LocalizedStringResource`; never `Text(verbatim:)` or a plain `String` for UI copy. Command-line builds do not update the catalog; after `make build` run
  ```
  find build/DerivedData/Build/Intermediates.noindex/Scholia.build -name '*.stringsdata' -print0 | xargs -0 xcrun xcstringstool sync App/Resources/Localizable.xcstrings --stringsdata
  ```
  and commit the catalog change.
- Every interactive element gets an accessibility identifier (`ui-tests` convention); icon-only controls get the label from the screen's `aria-label`.
- No comments in code. No speculative code.

## 4. UI tests

- Follow `.claude/skills/ui-tests/SKILL.md`: screen objects, launch configuration, waits.
- At least one test per "Done when" item and per flow in the issue scope, asserting the outcome, not only that the screen appears.
- In the flow tests, call `attachScreenshot("<Screen>")` at every state that matches a design screen, named exactly like the file (`"Library-A"`). Design review uses these.

## 5. Checks

```
make lint
make test DESTINATION='platform=iOS Simulator,id=<udid>'
```

`make format` fixes most lint errors. The whole suite must pass, not only your tests.

## 6. Design self-check

Run `.claude/skills/design-compare/SKILL.md` for every screen you built or changed, light and dark (iPad too if in scope). Fix every mismatch. A deviation you keep on purpose goes in the report with the reason.

## 7. Commit and push

Stage explicit paths, check `git status` shows nothing unintended, then:

```
git commit -F - <<'EOF'
<Imperative summary of the feature>

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
EOF
git push -u origin feature/<n>-<slug>
```

## 8. Fix rounds

The orchestrator forwards reviewer findings. Fix each one, or answer with evidence why it is wrong. Re-run checks and the affected design compares, add a new commit (no amend), push, report again.

## Stop and report instead of guessing

Spec or screens ambiguous or contradicting; a token, component or API from another issue missing; a dependency not merged; the fix needs a change to CLAUDE.md decisions, CI, or another feature's code; checks fail for reasons outside your change.

## Final report

Under 200 words, this shape:

```
Branch: feature/<n>-<slug> @ <short sha>, pushed
Done when:
- <item> -> <TestClass/testMethod>
Checks: make lint clean; make test <passed>/<total>
Design: <Screen> light match, dark match; deviations: <what, why> or none
Changed: <main files or folders>
Open: <decisions needed, known gaps> or none
```
