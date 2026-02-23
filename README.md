# PhotoArc

A cross-platform desktop app that scans directories for photos, indexes them into SQLite, and presents them in a scrollable feed with date grouping, full-screen preview, and folder navigation.

## Features

- Scan selected folders recursively for photos (JPG, PNG, GIF, BMP, WebP, TIFF, RAW, HEIC/HEIF, AVIF, SVG)
- Automatic EXIF metadata extraction (date taken, orientation)
- Thumbnail generation and caching (memory LRU + disk)
- Photo feed with adaptive grid layout and date-based grouping (month/year headers)
- Sort by newest or oldest first
- Full-screen photo view with keyboard navigation (arrow keys, Escape)
- Date scrollbar with floating month/year label
- Open containing folder in system file manager
- Incremental re-scan (skips unchanged files)
- Cross-platform: macOS, Windows, Linux

## Requirements

- Flutter SDK 3.11+
- Dart SDK 3.11+
- For RAW format support: LibRaw (`libraw-bin` / `dcraw_emu`) installed on system PATH

## Setup

```bash
# Install dependencies
flutter pub get

# Generate drift database code
dart run build_runner build --delete-conflicting-outputs
```

## Run

```bash
# macOS (default)
flutter run -d macos

# Windows
flutter run -d windows

# Linux
flutter run -d linux
```

## Build

```bash
flutter build macos
flutter build windows
flutter build linux
```

## Test

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Lint
flutter analyze
```

## Architecture

- **State management**: Provider
- **Database**: Drift (SQLite ORM) with generated code
- **Photo scanning**: Dart Isolate for background processing
- **Thumbnail caching**: Two-tier (in-memory LRU + disk)

### Project Structure

```
lib/
  main.dart              - App entry point, provider setup
  app.dart               - MaterialApp configuration, navigation
  database/
    database.dart        - Drift database, tables, and queries
  providers/
    scan_provider.dart   - Scan state and isolate management
    feed_provider.dart   - Photo list, pagination, sorting
  screens/
    folder_selection_screen.dart - Folder picker UI
    scanning_screen.dart         - Scan progress UI
    feed_screen.dart             - Photo grid feed
  services/
    photo_scanner.dart   - Isolate-based file walker, EXIF, thumbnails
    platform_service.dart - OS-specific paths and file manager
    thumbnail_service.dart - Thumbnail loading orchestration
    thumbnail_cache.dart   - In-memory LRU cache
  widgets/
    date_scrollbar.dart  - Custom scrollbar with date label
    folder_list_tile.dart - Folder checkbox tile
    month_header.dart    - Date group header
    photo_fullscreen.dart - Full-screen photo overlay
    photo_grid_tile.dart  - Grid thumbnail tile
```
