# PhotoArc - Project Conventions

## Build & Run Commands

```bash
flutter pub get                                          # Install dependencies
dart run build_runner build --delete-conflicting-outputs  # Generate drift code
flutter run -d macos                                     # Run on macOS
flutter test                                             # Run all tests
flutter test --coverage                                  # Run tests with coverage
flutter analyze                                          # Lint
```

## Architecture

- **Framework**: Flutter Desktop (macOS, Windows, Linux)
- **State management**: Provider (ChangeNotifierProvider for mutable state)
- **Database**: Drift (SQLite ORM) - generated code in `database.g.dart`
- **Background work**: Dart Isolates (photo scanning runs off main thread)
- **Theme**: Material 3

## Key Patterns

- Providers are set up in `main.dart` via MultiProvider
- `AppDatabase` uses drift with code generation (`build_runner build`)
- Photo scanning runs in a separate Isolate with SendPort/ReceivePort for progress streaming
- Thumbnails use a two-tier cache: in-memory LRU (500 entries) + disk cache
- Platform-specific behavior is abstracted in `PlatformService`
- Photos are paginated (200 per page) and grouped by year_month

## File Layout

- `lib/database/` - Drift database, tables, queries (run build_runner after changes)
- `lib/providers/` - ChangeNotifier providers (scan state, feed state)
- `lib/screens/` - Top-level screen widgets
- `lib/services/` - Business logic (scanner, platform, thumbnails)
- `lib/widgets/` - Reusable UI components
- `test/` - Mirrors lib/ structure

## Testing

- Tests use flutter_test with mocked dependencies
- Database tests use in-memory drift databases
- Widget tests use MultiProvider/ChangeNotifierProvider with mock providers
- Coverage target: 80%+

## Important Notes

- After modifying `lib/database/database.dart`, regenerate with: `dart run build_runner build --delete-conflicting-outputs`
- macOS entitlements are configured for file system access in `macos/Runner/Release.entitlements` and `macos/Runner/DebugProfile.entitlements`
- Minimum window size: 800x600 (set in `macos/Runner/MainFlutterWindow.swift`)
