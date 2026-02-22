# PhotoFeed Desktop App - Implementation Plan

## Overview

Build a cross-platform Flutter Desktop app that scans directories for photos, indexes them into SQLite, and presents them in a scrollable feed with date grouping, full-screen preview, and folder navigation. Starting on macOS, with cross-platform support built in from the start.

## Context

- Files involved: Greenfield project - all files will be created from scratch
- Design spec: PhotoFeedDesign.md (comprehensive spec covering all screens, data model, architecture)
- Related patterns: Flutter Desktop, drift (SQLite ORM), provider (state management), Material 3
- Dependencies: drift, sqlite3_flutter_libs, provider, path_provider, exif, image, file_picker, url_launcher, intl, path

## Development Approach

- **Testing approach**: Regular (code first, then tests)
- Complete each task fully before moving to the next
- Focus on macOS first (developer platform), but write platform-agnostic code with platform service abstraction
- Defer RAW/HEIC/SVG support to a later task - get core flow working first with common formats (JPG, PNG, GIF, BMP, WebP, TIFF)
- **CRITICAL: every task MUST include new/updated tests**
- **CRITICAL: all tests must pass before starting next task**

## Implementation Steps

### Task 1: Project scaffolding and dependencies

**Files:**
- Create: Flutter project structure (via `flutter create`)
- Modify: `pubspec.yaml`
- Create: `lib/main.dart`, `lib/app.dart`

- [x] Run `flutter create --platforms=macos,windows,linux --org com.photofeed photo_feed` (or restructure existing directory)
- [x] Add all dependencies to pubspec.yaml: drift, drift_dev, build_runner, sqlite3_flutter_libs, provider, path_provider, path, exif, image, file_picker, url_launcher, intl
- [x] Set up lib/main.dart with MultiProvider and MaterialApp (Material 3 theme)
- [x] Set up lib/app.dart with basic navigation shell (placeholder screens)
- [x] Configure macOS entitlements for file system access and network (if needed)
- [x] Set minimum window size to 800x600
- [x] Write smoke test verifying app builds and renders
- [x] Run project test suite - must pass before task 2

### Task 2: Database layer with drift

**Files:**
- Create: `lib/database/database.dart`
- Create: `lib/database/tables.dart`

- [x] Define `photos` table with all columns from spec (id, path, filename, directory, date_taken, file_size, format, width, height, thumbnail_path, year_month, orientation, is_valid, file_modified_at, created_at)
- [x] Define `scan_settings` table (id, folder_path, is_active)
- [x] Define `app_settings` table (key, value)
- [x] Add indexes on date_taken, year_month, path
- [x] Implement DatabaseService with methods: insertPhotoBatch, getPhotosPaginated (sorted by date_taken, filtered by is_valid), getPhotosByYearMonth, getFileModifiedAt, saveScanFolders, loadScanFolders, getSetting, setSetting
- [x] Run `dart run build_runner build` to generate drift code
- [x] Write unit tests for all database methods (insert, query, pagination, batch insert, settings)
- [x] Run project test suite - must pass before task 3

### Task 3: Platform service

**Files:**
- Create: `lib/services/platform_service.dart`

- [x] Implement getAvailableDrives() - macOS: /Volumes/* + home; Windows: logical drives; Linux: /proc/mounts + common paths
- [x] Implement getDefaultPhotoDirectories() - returns Pictures, Downloads paths per platform
- [x] Implement openFileManager(path) - macOS: open -R; Windows: explorer.exe /select; Linux: xdg-open
- [x] Implement getThumbnailCacheDirectory() using path_provider
- [x] Write unit tests for platform service (mock file system where needed)
- [x] Run project test suite - must pass before task 4

### Task 4: Photo scanner (Isolate-based)

**Files:**
- Create: `lib/services/photo_scanner.dart`

- [x] Implement file system walker: recursive directory traversal, filter by supported extensions (jpg, jpeg, png, gif, bmp, webp, tiff, tif), skip hidden dirs and symlink loops, handle permission errors
- [x] Implement EXIF extraction: parse DateTimeOriginal and Orientation from JPG/TIFF, fall back to file modification date
- [x] Implement thumbnail generation: decode with image package, resize to 200x200, save as JPEG to cache directory
- [x] Compute year_month string from resolved date
- [x] Wrap scanner in Dart Isolate with SendPort/ReceivePort for progress streaming
- [x] Implement batch processing: accumulate 100 photos per batch, send to main isolate
- [x] Implement incremental re-scan: check file_modified_at before processing, skip unchanged files
- [x] Define progress message types: photosFound count, currentDirectory, batchReady, scanComplete, scanError
- [x] Write tests for file walking logic, EXIF parsing, thumbnail generation, batch accumulation
- [x] Run project test suite - must pass before task 5

### Task 5: Thumbnail service (caching layer)

**Files:**
- Create: `lib/services/thumbnail_service.dart`
- Create: `lib/services/thumbnail_cache.dart`

- [x] Implement disk-tier cache: look up thumbnail_path from database, verify file exists on disk
- [x] Implement in-memory LRU cache (~500 entries) for currently visible tiles
- [x] Implement getThumbnail(photo) method: check memory cache -> check disk -> return null (regenerate later)
- [x] Implement cache eviction and size management
- [x] Write tests for LRU cache behavior (insert, evict, hit/miss), disk cache lookup
- [x] Run project test suite - must pass before task 6

### Task 6: Providers (state management)

**Files:**
- Create: `lib/providers/scan_provider.dart`
- Create: `lib/providers/feed_provider.dart`

- [x] Implement ScanProvider: manages selected folders list, scan running/stopped state, progress (photos found, current directory), starts/stops PhotoScanner isolate, persists folder selections to scan_settings table
- [x] Implement FeedProvider: manages photo list (paginated, 200 per page), current sort order (newest/oldest), loads more on scroll, groups photos by year_month, persists sort preference to app_settings
- [x] Wire providers into MultiProvider in main.dart
- [x] Write tests for ScanProvider state transitions and FeedProvider pagination/sorting logic
- [x] Run project test suite - must pass before task 7

### Task 7: Folder selection screen

**Files:**
- Create: `lib/screens/folder_selection_screen.dart`
- Create: `lib/widgets/folder_list_tile.dart`

- [x] Build screen showing available drives/volumes with checkboxes (all selected by default)
- [x] Highlight default photo directories (Pictures, Downloads)
- [x] Add folder picker button to add custom folders
- [x] Add prominent "Scan" button at bottom
- [x] Implement navigation logic: first launch -> this screen; subsequent -> feed screen
- [x] Restore saved folder selections on subsequent visits
- [x] Write widget tests for folder selection screen (renders drives, toggle checkboxes, scan button)
- [x] Run project test suite - must pass before task 8

### Task 8: Scanning screen

**Files:**
- Create: `lib/screens/scanning_screen.dart`

- [ ] Build full-screen centered card with animated progress bar
- [ ] Display live counter of photos found and current directory being scanned
- [ ] Add cancel button that stops isolate and navigates to feed with partial results
- [ ] Auto-navigate to feed screen on scan completion
- [ ] Wire to ScanProvider for real-time progress updates
- [ ] Write widget tests for scanning screen (progress display, cancel button)
- [ ] Run project test suite - must pass before task 9

### Task 9: Feed screen - grid and date grouping

**Files:**
- Create: `lib/screens/feed_screen.dart`
- Create: `lib/widgets/photo_grid_tile.dart`
- Create: `lib/widgets/month_header.dart`

- [ ] Build CustomScrollView with alternating SliverList (month headers) + SliverGrid (photo tiles)
- [ ] Implement adaptive grid with SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 200)
- [ ] Load thumbnails from disk with center-crop (BoxFit.cover), apply EXIF orientation via Transform.rotate
- [ ] Show placeholder skeleton while thumbnails load
- [ ] Implement lazy loading (builder pattern) and pagination (load more on scroll near bottom)
- [ ] Implement sort toggle in app bar (newest/oldest first)
- [ ] Add re-scan button in app bar that navigates to folder selection screen
- [ ] Show window title with total photo count
- [ ] Handle empty state (no photos found message)
- [ ] Implement hover tooltip on thumbnails showing date taken and folder path
- [ ] Write widget tests for feed screen (grid renders, month headers appear, sort toggle works)
- [ ] Run project test suite - must pass before task 10

### Task 10: Full-screen photo view

**Files:**
- Create: `lib/widgets/photo_fullscreen.dart`

- [ ] Build full-screen overlay dialog opened by clicking a thumbnail
- [ ] Load and display full-resolution image asynchronously (show spinner while loading)
- [ ] Apply EXIF orientation for correct rotation
- [ ] Display date taken and full file path in bottom overlay bar
- [ ] Add "Open Folder" button that calls PlatformService.openFileManager
- [ ] Add close button (top-right) and close on click outside
- [ ] Implement keyboard navigation: left/right arrows to navigate between photos, Escape to close
- [ ] Write widget tests for fullscreen view (renders image, keyboard navigation, close behavior)
- [ ] Run project test suite - must pass before task 11

### Task 11: Date scrollbar widget

**Files:**
- Create: `lib/widgets/date_scrollbar.dart`

- [ ] Build custom scrollbar wrapping the feed CustomScrollView
- [ ] Show floating date label (month/year) when user drags scrollbar thumb
- [ ] Map scroll offset to photo index to year_month group for label text
- [ ] Fade out label when user releases scrollbar
- [ ] Write widget tests for date scrollbar (label appears on drag, correct date displayed)
- [ ] Run project test suite - must pass before task 12

### Task 12: RAW and special format support

**Files:**
- Modify: `lib/services/photo_scanner.dart`

- [ ] Add RAW format support (cr2, cr3, nef, arw, dng, orf, rw2, raf): extract embedded JPEG preview via LibRaw process invocation, resize to thumbnail
- [ ] Add HEIC/HEIF/AVIF handling: platform-specific decoder or placeholder fallback
- [ ] Add SVG handling: placeholder or flutter_svg render
- [ ] Update supported extensions list in scanner
- [ ] Write tests for RAW thumbnail extraction and format fallbacks
- [ ] Run project test suite - must pass before task 13

### Task 13: Verify acceptance criteria

- [ ] Manual test: launch app fresh, select folders, scan, browse feed, open fullscreen, navigate with keyboard, open folder in file manager
- [ ] Manual test: re-launch app, verify it goes directly to feed with persisted data
- [ ] Manual test: re-scan with incremental scan (should be fast for unchanged files)
- [ ] Manual test: scroll through large collection, verify smooth performance and date scrollbar
- [ ] Run full test suite
- [ ] Run linter (flutter analyze)
- [ ] Verify test coverage meets 80%+

### Task 14: Update documentation

- [ ] Update README.md with project description, setup instructions, build/run commands
- [ ] Create CLAUDE.md with project conventions, architecture notes, and build commands
- [ ] Move this plan to `docs/plans/completed/`
