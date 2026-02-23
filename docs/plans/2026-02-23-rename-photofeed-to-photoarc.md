# Rename App from PhotoFeed to PhotoArc

## Overview

Rename all references from "PhotoFeed" / "photo_feed" to "PhotoArc" / "photoarc" across the entire codebase: Dart source, tests, platform configurations (macOS, Windows, Linux), and documentation. Uses "photoarc" (one word, no delimiter) for package names, binary names, and identifiers, and "PhotoArc" for CamelCase class names and display strings.

## Context

- Files involved: ~31 files across lib/, test/, macos/, windows/, linux/, and docs
- Related patterns: Flutter package naming, platform bundle identifiers, Drift database file naming
- Dependencies: None external; purely a rename operation
- Note: The on-disk database file is named `photo_feed.db`. Renaming it would break existing local installs. The plan includes a backward-compatible migration that checks for the old filename.

## Development Approach

- **Testing approach**: Regular (apply rename, then verify tests pass)
- Complete each task fully before moving to the next
- Use find-and-replace where safe; manual edits for nuanced references
- **CRITICAL: every task MUST include new/updated tests**
- **CRITICAL: all tests must pass before starting next task**

## Implementation Steps

### Task 1: Rename Dart package and update all imports

**Files:**
- Modify: `pubspec.yaml` (package name `photo_feed` -> `photoarc`)
- Modify: All files under `test/` (update `package:photo_feed/` -> `package:photoarc/`)

- [x] Change `name: photo_feed` to `name: photoarc` in `pubspec.yaml`
- [x] Update all `import 'package:photo_feed/...'` to `import 'package:photoarc/...'` in every test file
- [x] Run `flutter pub get` to validate the package rename
- [x] Run `flutter test` - must pass before task 2

### Task 2: Rename class and UI display strings

**Files:**
- Modify: `lib/app.dart` (class `PhotoFeedApp` -> `PhotoArcApp`, title string)
- Modify: `lib/main.dart` (class instantiation)
- Modify: `lib/screens/feed_screen.dart` (title bar strings)
- Modify: `test/widget_test.dart` (class reference)
- Modify: `test/screens/feed_screen_test.dart` (test strings and test names)

- [ ] Rename `PhotoFeedApp` class to `PhotoArcApp` in `lib/app.dart`
- [ ] Change app title from `'PhotoFeed'` to `'PhotoArc'` in `lib/app.dart`
- [ ] Update `PhotoFeedApp()` reference in `lib/main.dart`
- [ ] Update `'PhotoFeed ($totalCount photos)'` and `'PhotoFeed'` strings in `lib/screens/feed_screen.dart`
- [ ] Update `PhotoFeedApp()` reference and test assertions in test files
- [ ] Run `flutter test` - must pass before task 3

### Task 3: Update database filename with backward compatibility

**Files:**
- Modify: `lib/database/database.dart` (filename `photo_feed.db` -> `photoarc.db`, add fallback)
- Modify: `test/services/platform_service_test.dart` (cache path strings if they reference photo_feed)

- [ ] Change database filename from `photo_feed.db` to `photoarc.db` in `lib/database/database.dart`
- [ ] Add a check before opening: if `photoarc.db` does not exist but `photo_feed.db` does, rename the old file to the new name (one-time migration)
- [ ] Update comment referencing the old filename
- [ ] Update any test strings that reference `photo_feed` in cache/path contexts
- [ ] Run `flutter test` - must pass before task 4

### Task 4: Update macOS platform configuration

**Files:**
- Modify: `macos/Runner/Configs/AppInfo.xcconfig`
- Modify: `macos/Runner.xcodeproj/project.pbxproj`
- Modify: `macos/Runner.xcodeproj/xcshareddata/xcschemes/Runner.xcscheme`

- [ ] In `AppInfo.xcconfig`: change `PRODUCT_NAME` to `photoarc`, update `PRODUCT_BUNDLE_IDENTIFIER` to `com.photoarc.photoarc`, update copyright to `com.photoarc`
- [ ] In `project.pbxproj`: replace all `photo_feed_tmp` references with `photoarc`, update bundle identifiers from `com.photofeed` to `com.photoarc`
- [ ] In `Runner.xcscheme`: replace `photo_feed_tmp.app` with `photoarc.app`
- [ ] Run `flutter build macos` or at minimum `flutter analyze` to verify no breakage
- [ ] Run `flutter test` - must pass before task 5

### Task 5: Update Windows platform configuration

**Files:**
- Modify: `windows/CMakeLists.txt`
- Modify: `windows/runner/main.cpp`
- Modify: `windows/runner/Runner.rc`

- [ ] In `CMakeLists.txt`: change project name and `BINARY_NAME` from `photo_feed_tmp` to `photoarc`
- [ ] In `main.cpp`: change window title from `"photo_feed_tmp"` to `"PhotoArc"`
- [ ] In `Runner.rc`: update CompanyName to `com.photoarc`, update FileDescription/InternalName/ProductName to `photoarc`, update OriginalFilename to `photoarc.exe`, update copyright
- [ ] Run `flutter test` - must pass before task 6

### Task 6: Update Linux platform configuration

**Files:**
- Modify: `linux/CMakeLists.txt`
- Modify: `linux/runner/my_application.cc`

- [ ] In `CMakeLists.txt`: change `BINARY_NAME` to `photoarc`, change `APPLICATION_ID` to `com.photoarc.photoarc`
- [ ] In `my_application.cc`: change both window title strings from `"photo_feed_tmp"` to `"PhotoArc"`
- [ ] Run `flutter test` - must pass before task 7

### Task 7: Update documentation

**Files:**
- Modify: `README.md`
- Modify: `CLAUDE.md`
- Modify: `PhotoFeedDesign.md` (rename file to `PhotoArcDesign.md`)
- Modify: `docs/plans/completed/2026-02-22-photofeed-desktop-app.md`

- [ ] Update `README.md` title from `# PhotoFeed` to `# PhotoArc`
- [ ] Update `CLAUDE.md` header from `# PhotoFeed - Project Conventions` to `# PhotoArc - Project Conventions`
- [ ] Rename `PhotoFeedDesign.md` to `PhotoArcDesign.md` and update all internal PhotoFeed references
- [ ] Update title and references in `docs/plans/completed/2026-02-22-photofeed-desktop-app.md`
- [ ] No test changes needed for docs; run `flutter test` to confirm nothing broke

### Task 8: Verify acceptance criteria

- [ ] Run full test suite: `flutter test`
- [ ] Run linter: `flutter analyze`
- [ ] Grep entire project for any remaining `photofeed`, `PhotoFeed`, `photo_feed` references (should find none outside docs/plans/completed and this plan file)
- [ ] Verify test coverage meets 80%+: `flutter test --coverage`
- [ ] Manual test: `flutter run -d macos` and confirm window title shows "PhotoArc"

### Task 9: Update documentation

- [ ] Update README.md if user-facing changes
- [ ] Update CLAUDE.md if internal patterns changed
- [ ] Move this plan to `docs/plans/completed/`
