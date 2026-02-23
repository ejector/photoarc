# PhotoArc — Desktop Photo Discovery App

## Purpose

A cross-platform desktop application (Windows, macOS, Linux) that helps users rediscover forgotten photos buried in their file system. The app scans selected directories, indexes all images into a local database, and presents them in a scrollable feed so users can browse through their photo history and locate where old photos are stored.

---

## Technology Stack

- **Framework:** Flutter Desktop (Windows, macOS, Linux)
- **Language:** Dart
- **Database:** SQLite via `drift` package
- **Background processing:** Dart Isolates
- **EXIF parsing:** `exif` package (date, orientation)
- **Image processing:** `image` package (decode, resize, JPEG encode)
- **RAW support:** LibRaw (via `dart:ffi` / `Process` invocation)
- **State management:** `provider` (ChangeNotifier)
- **UI pattern:** Material 3

---

## Screens & User Flow

### 1. Folder Selection Screen (First Launch)

- Displayed on first app launch or when the user wants to re-scan
- Shows a list of all available drives/volumes:
  - **Windows:** Enumerates logical drives (`C:\`, `D:\`, etc.) via `dart:io`
  - **macOS:** Lists `/Volumes/*` + user home directory
  - **Linux:** Lists mount points from `/proc/mounts` or common paths (`/home`, `/media`, `/mnt`)
- All drives/roots are **selected by default**
- OS-specific default photo folders (Pictures, Downloads) are highlighted as suggested defaults
- User can:
  - Deselect specific drives/folders via checkboxes
  - Add custom folders via a native folder picker dialog (`file_picker` package)
- Custom added folders appear in the list with checkboxes
- **"Scan" button** at the bottom (large, prominent) to start scanning
- Selected folders are persisted to `scan_settings` table in the database
- On subsequent launches, saved folder selections are restored

#### Navigation Logic
- First launch → Folder Selection Screen
- Subsequent launches → Feed Screen (with option to re-scan from app bar menu)

### 2. Scanning Screen

- Full-screen centered card with scanning progress
- Displays:
  - Animated progress bar (based on directories scanned vs. total top-level dirs)
  - **Live counter** of photos found so far (e.g., "Found: 1,234 photos")
  - **Current directory** being scanned (e.g., "Scanning: `/Users/john/Pictures/2015`")
  - Cancel button
- Scanning runs in a **separate Dart Isolate** using `SendPort`/`ReceivePort` for progress streaming
- On completion → transitions automatically to the Feed screen
- On cancel → stops isolate, navigates to Feed with whatever was found so far

#### Scanner Details

**File System Walker:**
- Recursive directory traversal in a Dart Isolate
- Filters files by supported extensions (case-insensitive matching)
- Skips hidden directories (starting with `.`), system directories, and symlink loops
- Handles permission errors gracefully (skips inaccessible directories, continues scanning)

**EXIF Data Extraction:**
- Parses EXIF `DateTimeOriginal` for JPG/TIFF files to get accurate photo date
- Parses EXIF `Orientation` tag (values 1–8) for correct display rotation
- Falls back to file system modification date if EXIF is unavailable or for non-EXIF formats (PNG, GIF, BMP, WebP, etc.)
- Computes `year_month` string from the resolved date (e.g., `"2015-03"`) for fast grouping

**Thumbnail Generation:**
- For **standard formats** (JPG, PNG, GIF, WEBP, BMP, TIFF): decodes with `image` package, resizes to 200×200, saves as JPEG in app cache directory
- For **RAW formats** (CR2, CR3, NEF, ARW, DNG, ORF, RW2, RAF): extracts embedded JPEG preview using LibRaw (`dcraw_emu` or `libraw` via process call), then resizes to 200×200
- For **HEIC/HEIF/AVIF**: uses platform-specific decoders or falls back to a placeholder
- For **SVG**: renders to raster using `flutter_svg` or marks as special case
- Stores the generated thumbnail file path in `thumbnail_path` column
- Files that fail to decode are marked as `is_valid = false` and hidden from the feed

**Incremental Re-scan:**
- Before processing a file, checks the database for an existing entry with the same path
- Compares `file_modified_at` — if unchanged since last scan, skips processing entirely
- If changed, regenerates thumbnail and updates the database record
- New files are inserted as usual
- This makes subsequent scans significantly faster

**Batch Processing:**
- Accumulates found photos in batches of 100
- Sends each batch to the main isolate for database insertion
- Avoids holding all results in memory for large collections (50,000+ photos)

### 3. Feed Screen (Main View)

#### Grid Layout
- `CustomScrollView` with `SliverGrid`
- **Adaptive grid** using `SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 200)`
- Number of columns adjusts dynamically based on window width
- Square thumbnails loaded from pre-generated `thumbnail_path` (JPEG on disk) with center-crop (`BoxFit.cover`)
- EXIF `orientation` applied at render time using `Transform.rotate`
- Lazy loading via builder pattern — only visible + nearby tiles are built
- Photos with `is_valid = false` are excluded from the feed

#### Thumbnail Loading Pipeline
- Two-tier caching system:
  - **Disk tier:** Pre-generated 200×200 JPEG thumbnails stored in app cache directory (survives app restarts)
  - **Memory tier:** In-memory LRU cache (~500 entries) for currently visible tiles (ensures smooth 60fps scrolling)
- Shows a placeholder skeleton while thumbnail is loading
- Gracefully handles missing/corrupt thumbnails (shows error icon)

#### Sorting
- **Default: newest first** (descending by `date_taken`)
- Toggle button in the app bar switches between newest-first ↓ and oldest-first ↑
- Triggers re-query from the database
- Sorting preference is persisted to `app_settings` table

#### Date Grouping
- Photos are grouped by **month and year** using the pre-computed `year_month` field (no date parsing at display time)
- Sticky section headers as group dividers (e.g., "March 2015", "January 2008")
- Implemented as alternating `SliverList` (header) + `SliverGrid` (photos) within a `CustomScrollView`

#### Hover Tooltip
- On mouse hover over any thumbnail, a `Tooltip` widget appears showing:
  - **Date taken** (formatted, e.g., "15 January 2008, 14:30")
  - **Full folder path** (e.g., `D:\Photos\Vacation 2008\`)

#### Scrollbar with Date Indicator
- Custom `Scrollbar` widget wrapping the `CustomScrollView`
- When the user **grabs/drags the scrollbar thumb**, a floating `Card` label appears next to the scrollbar
- The label shows the **month and year** of the first visible photo at the current scroll position (e.g., "March 2015")
- Label disappears with a short fade-out when the user releases the scrollbar
- Implementation:
  - `ScrollController` + `ScrollNotification` to track position
  - Maps scroll offset → photo index → `year_month` group
  - Positions the floating widget using `Overlay` or `Stack`
- Enables fast navigation through large photo collections (similar to Google Photos)

#### Full-Screen Photo View
- Clicking a thumbnail opens a **full-screen overlay** (`PhotoFullscreenView` dialog)
- Displays:
  - Full-resolution image (loaded asynchronously, shows loading spinner first)
  - EXIF orientation applied for correct rotation
  - Date taken (bottom overlay bar)
  - Full file path
  - **"Open Folder" button** — opens the system file manager at the photo's location:
    - **Windows:** `explorer.exe /select,"<path>"`
    - **macOS:** `open -R "<path>"`
    - **Linux:** `xdg-open "<directory>"`
  - Close button (top-right)
- **Keyboard navigation:** Left/right arrow keys to navigate between photos, Escape to close
- Close also via click outside the overlay

#### App Bar Actions
- Sort toggle button (newest/oldest first)
- "Re-scan" button → navigates to Folder Selection Screen

---

## Supported Image Formats

| Category | Extensions | Thumbnail Strategy |
|----------|-----------|-------------------|
| Common | `.jpg`, `.jpeg`, `.png`, `.gif`, `.bmp`, `.webp` | Decode with `image` package, resize to 200×200 JPEG |
| Modern | `.heic`, `.heif`, `.avif` | Platform-specific decoder or placeholder |
| Lossless | `.tiff`, `.tif` | Decode with `image` package, resize to 200×200 JPEG |
| Vector | `.svg` | Render to raster with `flutter_svg` or special case |
| RAW | `.cr2`, `.cr3`, `.nef`, `.arw`, `.dng`, `.orf`, `.rw2`, `.raf` | Extract embedded JPEG preview via LibRaw, resize |

---

## Data Model

### SQLite Table: `photos`

| Column | Type | Description |
|--------|------|-------------|
| `id` | INTEGER (PK) | Auto-increment primary key |
| `path` | TEXT (UNIQUE) | Full absolute path to the image file |
| `filename` | TEXT | File name with extension |
| `directory` | TEXT | Parent directory path |
| `date_taken` | DATETIME | From EXIF `DateTimeOriginal`, or file modification date as fallback |
| `file_size` | INTEGER | File size in bytes |
| `format` | TEXT | File extension (lowercase) |
| `width` | INTEGER | Image width in pixels (if available) |
| `height` | INTEGER | Image height in pixels (if available) |
| `thumbnail_path` | TEXT | Path to generated 200×200 JPEG thumbnail in app cache directory |
| `year_month` | TEXT (INDEXED) | Pre-computed grouping key, e.g. `"2015-03"`. Enables fast `GROUP BY` / `ORDER BY` without parsing `date_taken` |
| `orientation` | INTEGER | EXIF orientation tag (1–8). Applied at render time to correctly rotate the image |
| `is_valid` | BOOLEAN | `true` if file was successfully read and decoded. Invalid files are hidden from the feed |
| `file_modified_at` | DATETIME | File system modification timestamp. Used for incremental re-scan: skip files whose modification date hasn't changed |
| `created_at` | DATETIME | When the record was added to the database |

**Indexes:** `date_taken`, `year_month`, `path`

### SQLite Table: `scan_settings`

| Column | Type | Description |
|--------|------|-------------|
| `id` | INTEGER (PK) | Auto-increment primary key |
| `folder_path` | TEXT | Selected scan directory |
| `is_active` | BOOLEAN | Whether this folder is included in scans |

### SQLite Table: `app_settings`

| Column | Type | Description |
|--------|------|-------------|
| `key` | TEXT (PK) | Setting name (e.g., `"sort_order"`) |
| `value` | TEXT | Setting value (e.g., `"desc"`) |

---

## Architecture

```
┌──────────────────────────────────────────────────┐
│                    UI Layer                       │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐ │
│  │   Folder    │  │  Scanning  │  │    Feed    │ │
│  │  Selection  │  │   Screen   │  │   Screen   │ │
│  └────────────┘  └────────────┘  └────────────┘ │
│  Widgets: FolderListTile, PhotoGridTile,         │
│  DateScrollbar, PhotoFullscreen, MonthHeader     │
├──────────────────────────────────────────────────┤
│              State Management                    │
│    ┌────────────────┐  ┌───────────────────┐     │
│    │  ScanProvider   │  │   FeedProvider    │     │
│    │ (scan state,    │  │ (photos, sorting, │     │
│    │  progress,      │  │  pagination,      │     │
│    │  folder list)   │  │  scroll position) │     │
│    └────────────────┘  └───────────────────┘     │
├──────────────────────────────────────────────────┤
│                Service Layer                     │
│  ┌────────────────┐  ┌───────────────────────┐   │
│  │  PhotoScanner   │  │   DatabaseService     │   │
│  │  (Isolate)      │  │   (drift + SQLite)    │   │
│  │  - file walker  │  │   - batch insert      │   │
│  │  - EXIF parser  │  │   - paginated query   │   │
│  │  - thumb gen    │  │   - grouped by month  │   │
│  │  - RAW extract  │  │   - incremental scan  │   │
│  └────────────────┘  └───────────────────────┘   │
│  ┌────────────────┐  ┌───────────────────────┐   │
│  │ ThumbnailService│  │   PlatformService     │   │
│  │ - disk cache    │  │   - drive detection   │   │
│  │ - LRU memory    │  │   - open file manager │   │
│  │ - orientation   │  │   - default folders   │   │
│  └────────────────┘  └───────────────────────┘   │
├──────────────────────────────────────────────────┤
│              Platform / OS Layer                  │
│  File System    SQLite    File Manager    LibRaw  │
└──────────────────────────────────────────────────┘
```

### Key Components

- **PhotoScanner**: Runs in a Dart Isolate. Recursively walks selected directories, filters by supported extensions, extracts EXIF data (date, orientation), generates JPEG thumbnails (200×200), and streams results back to the main isolate for DB insertion. For RAW files, extracts the embedded JPEG preview via LibRaw rather than decoding the full RAW data. Supports incremental re-scan by comparing `file_modified_at` — unchanged files are skipped. Reports progress in real-time via `SendPort`/`ReceivePort`.
- **DatabaseService**: Manages all SQLite operations via `drift`. Provides paginated queries (200 per page) sorted by `date_taken`, grouped by `year_month`, filtered by `is_valid = true`. Supports batch inserts (100 at a time), incremental scan checks (`getFileModifiedAt(path)`), and persists user settings. Indexes on `year_month`, `date_taken`, and `path`.
- **ThumbnailService**: Two-tier cache system. Disk tier: 200×200 JPEG thumbnails in app cache directory (path stored in `thumbnail_path`), survives app restarts. Memory tier: in-memory LRU (~500 entries) for currently visible tiles, ensures smooth 60fps scrolling.
- **PlatformService**: OS-specific operations — listing drives/volumes (Windows drives, macOS `/Volumes`, Linux mount points), opening file manager at a given path (`explorer.exe`, `open -R`, `xdg-open`), detecting default photo directories.
- **ScanProvider**: Manages scan state (selected folders, progress, running/stopped). Starts/stops the PhotoScanner isolate. Persists folder selections to `scan_settings`.
- **FeedProvider**: Manages feed data (photo list, current sort order, pagination offset, scroll position). Loads photos in pages of 200 from the database. Persists sort preference to `app_settings`.

---

## Project Structure

```
lib/
├── main.dart
├── app.dart
├── models/
│   └── photo.dart
├── database/
│   ├── database.dart            # Drift database definition
│   └── database.g.dart          # Generated code
├── services/
│   ├── photo_scanner.dart       # Isolate-based scanner
│   ├── platform_service.dart    # OS-specific: drives, open folder
│   ├── thumbnail_service.dart   # Generate & cache JPEG thumbnails on disk
│   └── thumbnail_cache.dart     # In-memory LRU cache for visible tiles
├── providers/
│   ├── scan_provider.dart       # Scan state & progress
│   └── feed_provider.dart       # Feed data & sorting
├── screens/
│   ├── folder_selection_screen.dart
│   ├── scanning_screen.dart
│   └── feed_screen.dart
└── widgets/
    ├── folder_list_tile.dart    # Checkbox + folder path
    ├── photo_grid_tile.dart     # Thumbnail with tooltip
    ├── date_scrollbar.dart      # Scrollbar with date indicator
    ├── photo_fullscreen.dart    # Full-screen overlay
    └── month_header.dart        # Section divider ("March 2015")
```

---

## Performance Considerations

- **Isolate-based scanning**: File system traversal, EXIF parsing, and thumbnail generation all run off the main thread in a dedicated Dart Isolate
- **Lazy loading**: `SliverGrid` with builder pattern — only visible tiles are built and rendered
- **Two-tier thumbnail caching**: Disk-persisted JPEG thumbnails (no need to re-decode originals after first scan) + in-memory LRU for visible tiles (smooth 60fps scrolling)
- **Batch DB inserts**: Photos are inserted in batches of 100 for efficiency
- **Indexed queries**: `date_taken` and `year_month` columns indexed for fast sorted retrieval and grouping
- **Paginated loading**: Feed loads 200 photos at a time from the database, fetches more on scroll
- **Incremental re-scan**: `file_modified_at` comparison skips unchanged files, making subsequent scans dramatically faster
- **RAW handling**: Embedded JPEG previews extracted from RAW files instead of decoding the full RAW data
- **Orientation-aware rendering**: EXIF orientation applied at display time via `Transform.rotate`, no need to re-encode rotated copies
- **Pre-computed grouping**: `year_month` field eliminates date parsing at display time

---

## Error Handling

- **Scanner**: Permission denied → skip directory and continue. Broken symlinks → skip. Corrupted files → mark `is_valid = false`, continue scanning.
- **Database**: Disk full → show error message. Concurrent access → handled by SQLite's built-in locking.
- **Images**: Corrupt/truncated files → show placeholder icon in grid. Missing thumbnails → regenerate on demand.
- **Empty state**: No photos found → friendly message with suggestion to adjust folder selection and re-scan.

---

## Platform-Specific Details

| Feature | Windows | macOS | Linux |
|---------|---------|-------|-------|
| Drive detection | Enumerate logical drives (`C:\`, `D:\`) | `/Volumes/*` + home dir | `/proc/mounts`, `/home`, `/media`, `/mnt` |
| Open folder | `explorer.exe /select,"<path>"` | `open -R "<path>"` | `xdg-open "<directory>"` |
| Default photo dir | `%USERPROFILE%\Pictures` | `~/Pictures` | `~/Pictures` |
| Long paths | Handle 260 char limit (extended paths) | N/A | N/A |
| HiDPI | Auto-handled by Flutter | Retina support built-in | Scale factor detection |
| Thumbnail cache | `%APPDATA%\PhotoArc\cache\` | `~/Library/Caches/PhotoArc/` | `~/.cache/PhotoArc/` |
| RAW support | LibRaw binary bundled | LibRaw binary bundled | LibRaw binary bundled |

---

## Dependencies

| Package | Purpose |
|---------|---------|
| `drift` | SQLite ORM & query builder |
| `sqlite3_flutter_libs` | SQLite native binaries for all platforms |
| `provider` | State management (ChangeNotifier) |
| `path_provider` | App data & cache directory paths |
| `path` | Cross-platform path manipulation |
| `exif` | EXIF metadata extraction (date, orientation) |
| `image` | Image decode, resize, JPEG encode for thumbnails |
| `file_picker` | Native folder picker dialog |
| `url_launcher` | Open file manager at photo location |
| `intl` | Date and number formatting |
| `dart:ffi` / `Process` | LibRaw invocation for RAW file thumbnail extraction |

---

## UX Polish

- Smooth animations for screen transitions
- Loading skeleton placeholders for thumbnails while they load
- Keyboard shortcuts: Escape (close fullscreen), Left/Right arrows (navigate photos), scroll with mouse wheel
- Window title shows total photo count (e.g., "PhotoArc — 12,345 photos")
- Minimum window size: 800×600

---

## Build & Distribution

| Platform | Format | Notes |
|----------|--------|-------|
| Windows | `.exe` / MSIX | Optional code signing |
| macOS | `.app` / `.dmg` | Notarization required for distribution |
| Linux | `.deb` / AppImage | Universal packaging via AppImage |

Binary size optimized via tree shaking and deferred loading.

---

## Out of Scope (YAGNI)

- Photo editing
- Tags, albums, or collections
- Cloud sync
- Search / filtering by name
- Duplicate detection
- Video file support
