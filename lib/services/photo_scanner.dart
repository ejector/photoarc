import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:exif/exif.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;

// ── Supported extensions ─────────────────────────────────────────────────────

/// Standard image formats decodable by the `image` package.
const standardExtensions = {
  '.jpg',
  '.jpeg',
  '.png',
  '.gif',
  '.bmp',
  '.webp',
  '.tiff',
  '.tif',
};

/// RAW camera formats that need external tool extraction.
const rawExtensions = {
  '.cr2',
  '.cr3',
  '.nef',
  '.arw',
  '.dng',
  '.orf',
  '.rw2',
  '.raf',
};

/// HEIC/HEIF/AVIF formats that need platform-specific decoding.
const heicExtensions = {
  '.heic',
  '.heif',
  '.avif',
};

/// SVG vector format.
const svgExtensions = {
  '.svg',
};

/// All supported extensions across all format categories.
const supportedExtensions = {
  ...standardExtensions,
  ...rawExtensions,
  ...heicExtensions,
  ...svgExtensions,
};

bool isSupportedImage(String path) {
  final ext = p.extension(path).toLowerCase();
  return supportedExtensions.contains(ext);
}

/// Returns the format category for a given file path.
FormatCategory getFormatCategory(String path) {
  final ext = p.extension(path).toLowerCase();
  if (standardExtensions.contains(ext)) return FormatCategory.standard;
  if (rawExtensions.contains(ext)) return FormatCategory.raw;
  if (heicExtensions.contains(ext)) return FormatCategory.heic;
  if (svgExtensions.contains(ext)) return FormatCategory.svg;
  return FormatCategory.standard;
}

enum FormatCategory { standard, raw, heic, svg }

// ── Progress message types ───────────────────────────────────────────────────

/// Base class for all progress messages sent from the scanner isolate.
sealed class ScanProgress {}

/// Reports how many photo files have been found so far.
class PhotosFoundProgress extends ScanProgress {
  final int count;
  PhotosFoundProgress(this.count);
}

/// Reports which directory is currently being scanned.
class CurrentDirectoryProgress extends ScanProgress {
  final String directory;
  CurrentDirectoryProgress(this.directory);
}

/// A batch of scanned photo data ready for database insertion.
class BatchReadyProgress extends ScanProgress {
  final List<ScannedPhoto> photos;
  BatchReadyProgress(this.photos);
}

/// Scan completed successfully.
class ScanCompleteProgress extends ScanProgress {
  final int totalPhotos;
  ScanCompleteProgress(this.totalPhotos);
}

/// An error occurred during scanning (non-fatal, scanning continues).
class ScanErrorProgress extends ScanProgress {
  final String message;
  final String? path;
  ScanErrorProgress(this.message, {this.path});
}

// ── Scanned photo data ───────────────────────────────────────────────────────

/// Represents a photo that has been scanned and processed, ready for DB insert.
class ScannedPhoto {
  final String path;
  final String filename;
  final String directory;
  final DateTime dateTaken;
  final int fileSize;
  final String format;
  final int? width;
  final int? height;
  final String? thumbnailPath;
  final String yearMonth;
  final int orientation;
  final DateTime fileModifiedAt;

  const ScannedPhoto({
    required this.path,
    required this.filename,
    required this.directory,
    required this.dateTaken,
    required this.fileSize,
    required this.format,
    this.width,
    this.height,
    this.thumbnailPath,
    required this.yearMonth,
    required this.orientation,
    required this.fileModifiedAt,
  });
}

// ── Scanner configuration ────────────────────────────────────────────────────

/// Parameters passed to the scanner isolate.
class ScanConfig {
  final List<String> directories;
  final String thumbnailCacheDir;
  final SendPort sendPort;

  /// Map of file path -> file modified at time for incremental scanning.
  /// If a file's modification time matches, it will be skipped.
  final Map<String, DateTime> existingFiles;

  const ScanConfig({
    required this.directories,
    required this.thumbnailCacheDir,
    required this.sendPort,
    this.existingFiles = const {},
  });
}

// ── File system walker ───────────────────────────────────────────────────────

/// Walks directories recursively, yielding supported image file paths.
/// Skips hidden directories (starting with .) and handles permission errors.
Stream<File> walkDirectories(
  List<String> directories, {
  void Function(String error, String? path)? onError,
}) async* {
  final visited = <String>{};

  for (final dirPath in directories) {
    yield* _walkDirectory(Directory(dirPath), visited, onError: onError);
  }
}

Stream<File> _walkDirectory(
  Directory dir,
  Set<String> visited, {
  void Function(String error, String? path)? onError,
}) async* {
  String resolvedPath;
  try {
    resolvedPath = dir.resolveSymbolicLinksSync();
  } on FileSystemException {
    // Can't resolve path - skip
    onError?.call('Cannot resolve path: ${dir.path}', dir.path);
    return;
  }

  if (visited.contains(resolvedPath)) return;
  visited.add(resolvedPath);

  List<FileSystemEntity> entries;
  try {
    entries = dir.listSync();
  } on FileSystemException catch (e) {
    onError?.call('Permission denied: ${e.message}', dir.path);
    return;
  }

  for (final entity in entries) {
    final name = p.basename(entity.path);

    // Skip hidden files/dirs
    if (name.startsWith('.')) continue;

    if (entity is File) {
      if (isSupportedImage(entity.path)) {
        yield entity;
      }
    } else if (entity is Directory) {
      yield* _walkDirectory(entity, visited, onError: onError);
    } else if (entity is Link) {
      // Resolve symlinks - could be file or directory
      try {
        final target = entity.resolveSymbolicLinksSync();
        final stat = FileStat.statSync(target);
        if (stat.type == FileSystemEntityType.file && isSupportedImage(target)) {
          yield File(target);
        } else if (stat.type == FileSystemEntityType.directory) {
          yield* _walkDirectory(Directory(target), visited, onError: onError);
        }
      } on FileSystemException {
        // Broken symlink - skip
      }
    }
  }
}

// ── EXIF extraction ──────────────────────────────────────────────────────────

/// Result of EXIF parsing.
class ExifResult {
  final DateTime? dateTaken;
  final int orientation;

  const ExifResult({this.dateTaken, this.orientation = 1});
}

/// Extracts EXIF data from a file. Returns null date if EXIF is unavailable.
Future<ExifResult> extractExif(File file) async {
  try {
    final bytes = await file.readAsBytes();
    final tags = await readExifFromBytes(bytes);

    if (tags.isEmpty) return const ExifResult();

    DateTime? dateTaken;
    final dateTag = tags['EXIF DateTimeOriginal'] ??
        tags['EXIF DateTimeDigitized'] ??
        tags['Image DateTime'];

    if (dateTag != null) {
      dateTaken = _parseExifDate(dateTag.toString());
    }

    int orientation = 1;
    final orientationTag = tags['Image Orientation'];
    if (orientationTag != null) {
      try {
        orientation = orientationTag.values.firstAsInt();
      } catch (_) {
        // Keep default orientation if parsing fails
      }
    }

    return ExifResult(dateTaken: dateTaken, orientation: orientation);
  } catch (_) {
    return const ExifResult();
  }
}

/// Parses EXIF date string like "2024:01:15 14:30:00" into DateTime.
DateTime? _parseExifDate(String dateStr) {
  try {
    // EXIF uses "YYYY:MM:DD HH:MM:SS" format
    final cleaned = dateStr.trim();
    if (cleaned.isEmpty || cleaned.startsWith('0000')) return null;

    final parts = cleaned.split(' ');
    if (parts.length < 2) return null;

    final dateParts = parts[0].split(':');
    final timeParts = parts[1].split(':');

    if (dateParts.length < 3 || timeParts.length < 3) return null;

    return DateTime(
      int.parse(dateParts[0]),
      int.parse(dateParts[1]),
      int.parse(dateParts[2]),
      int.parse(timeParts[0]),
      int.parse(timeParts[1]),
      int.parse(timeParts[2]),
    );
  } catch (_) {
    return null;
  }
}

// ── Thumbnail generation ─────────────────────────────────────────────────────

/// Generates a 200x200 thumbnail for the given image file.
/// Returns the thumbnail path on success, null on failure.
Future<String?> generateThumbnail(
  File imageFile,
  String cacheDir,
) async {
  try {
    final bytes = await imageFile.readAsBytes();
    final image = img.decodeImage(bytes);
    if (image == null) return null;

    // Resize to fit within 200x200, maintaining aspect ratio, then center-crop
    final thumbnail = img.copyResizeCropSquare(image, size: 200);

    final hash = imageFile.path.hashCode.toRadixString(16);
    final thumbFilename = '${hash}_thumb.jpg';
    final thumbPath = p.join(cacheDir, thumbFilename);

    final jpegBytes = img.encodeJpg(thumbnail, quality: 85);
    await File(thumbPath).writeAsBytes(jpegBytes);

    return thumbPath;
  } catch (_) {
    return null;
  }
}

// ── RAW thumbnail extraction ─────────────────────────────────────────────────

/// Attempts to extract an embedded JPEG preview from a RAW file using
/// available command-line tools (dcraw or exiftool).
/// Returns the thumbnail path on success, null on failure.
Future<String?> generateRawThumbnail(
  File rawFile,
  String cacheDir,
) async {
  final hash = rawFile.path.hashCode.toRadixString(16);
  final thumbFilename = '${hash}_thumb.jpg';
  final thumbPath = p.join(cacheDir, thumbFilename);

  // Try dcraw first: extracts embedded JPEG preview
  if (await _tryDcrawExtract(rawFile.path, thumbPath)) {
    return thumbPath;
  }

  // Try exiftool: extracts preview image
  if (await _tryExiftoolExtract(rawFile.path, thumbPath)) {
    return thumbPath;
  }

  // No tool available - return null (no thumbnail)
  return null;
}

/// Tries to extract embedded JPEG using dcraw -e.
Future<bool> _tryDcrawExtract(String rawPath, String outputPath) async {
  try {
    // dcraw -e -c outputs the embedded JPEG to stdout
    final result = await Process.run(
      'dcraw',
      ['-e', '-c', rawPath],
      stdoutEncoding: null,
    );
    if (result.exitCode == 0) {
      final bytes = result.stdout as List<int>;
      if (bytes.isNotEmpty) {
        // Resize the extracted preview to thumbnail size
        final image = img.decodeImage(Uint8List.fromList(bytes));
        if (image != null) {
          final thumbnail = img.copyResizeCropSquare(image, size: 200);
          await File(outputPath).writeAsBytes(img.encodeJpg(thumbnail, quality: 85));
          return true;
        }
      }
    }
  } on ProcessException {
    // dcraw not available
  } catch (_) {
    // Other errors
  }
  return false;
}

/// Tries to extract preview image using exiftool.
Future<bool> _tryExiftoolExtract(String rawPath, String outputPath) async {
  try {
    final result = await Process.run(
      'exiftool',
      ['-b', '-PreviewImage', rawPath],
      stdoutEncoding: null,
    );
    if (result.exitCode == 0) {
      final bytes = result.stdout as List<int>;
      if (bytes.isNotEmpty) {
        final image = img.decodeImage(Uint8List.fromList(bytes));
        if (image != null) {
          final thumbnail = img.copyResizeCropSquare(image, size: 200);
          await File(outputPath).writeAsBytes(img.encodeJpg(thumbnail, quality: 85));
          return true;
        }
      }
    }
  } on ProcessException {
    // exiftool not available
  } catch (_) {
    // Other errors
  }
  return false;
}

// ── HEIC/HEIF/AVIF thumbnail generation ──────────────────────────────────────

/// Generates a thumbnail for HEIC/HEIF/AVIF files using platform-specific tools.
/// On macOS, uses `sips` to convert to JPEG. On Linux, tries `heif-convert`.
/// Returns the thumbnail path on success, null on failure.
Future<String?> generateHeicThumbnail(
  File heicFile,
  String cacheDir,
) async {
  final hash = heicFile.path.hashCode.toRadixString(16);
  final thumbFilename = '${hash}_thumb.jpg';
  final thumbPath = p.join(cacheDir, thumbFilename);

  // Intermediate full-size JPEG for conversion
  final tempJpeg = p.join(cacheDir, '${hash}_temp_heic.jpg');

  try {
    bool converted = false;

    if (Platform.isMacOS) {
      converted = await _trySipsConvert(heicFile.path, tempJpeg);
    }

    if (!converted) {
      converted = await _tryHeifConvert(heicFile.path, tempJpeg);
    }

    if (converted && File(tempJpeg).existsSync()) {
      // Resize to thumbnail
      final bytes = await File(tempJpeg).readAsBytes();
      final image = img.decodeImage(bytes);
      if (image != null) {
        final thumbnail = img.copyResizeCropSquare(image, size: 200);
        await File(thumbPath).writeAsBytes(img.encodeJpg(thumbnail, quality: 85));
        // Clean up temp file
        try {
          await File(tempJpeg).delete();
        } catch (_) {}
        return thumbPath;
      }
    }
  } catch (_) {
    // Clean up on failure
  }

  // Clean up temp file on failure
  try {
    if (File(tempJpeg).existsSync()) await File(tempJpeg).delete();
  } catch (_) {}

  return null;
}

/// Uses macOS sips to convert HEIC to JPEG.
Future<bool> _trySipsConvert(String inputPath, String outputPath) async {
  try {
    final result = await Process.run(
      'sips',
      ['-s', 'format', 'jpeg', inputPath, '--out', outputPath],
    );
    return result.exitCode == 0 && File(outputPath).existsSync();
  } on ProcessException {
    return false;
  } catch (_) {
    return false;
  }
}

/// Uses heif-convert (libheif) to convert HEIC to JPEG.
Future<bool> _tryHeifConvert(String inputPath, String outputPath) async {
  try {
    final result = await Process.run('heif-convert', [inputPath, outputPath]);
    return result.exitCode == 0 && File(outputPath).existsSync();
  } on ProcessException {
    return false;
  } catch (_) {
    return false;
  }
}

// ── SVG placeholder ──────────────────────────────────────────────────────────

/// Generates a simple placeholder thumbnail for SVG files.
/// Creates a small image with a distinguishing visual indicator.
/// Returns the thumbnail path on success, null on failure.
Future<String?> generateSvgPlaceholder(
  File svgFile,
  String cacheDir,
) async {
  try {
    final hash = svgFile.path.hashCode.toRadixString(16);
    final thumbFilename = '${hash}_thumb.jpg';
    final thumbPath = p.join(cacheDir, thumbFilename);

    // Create a 200x200 placeholder image with a light gray background
    // and "SVG" text indicator
    final image = img.Image(width: 200, height: 200);
    img.fill(image, color: img.ColorRgb8(220, 220, 230));

    // Draw a simple border
    img.drawRect(image,
      x1: 10, y1: 10, x2: 189, y2: 189,
      color: img.ColorRgb8(150, 150, 170),
      thickness: 2,
    );

    await File(thumbPath).writeAsBytes(img.encodeJpg(image, quality: 85));
    return thumbPath;
  } catch (_) {
    return null;
  }
}

// ── Format-aware thumbnail dispatch ──────────────────────────────────────────

/// Generates a thumbnail based on the file's format category.
/// Dispatches to the appropriate handler for standard, RAW, HEIC, or SVG files.
Future<String?> generateThumbnailForFormat(
  File imageFile,
  String cacheDir,
) async {
  final category = getFormatCategory(imageFile.path);
  switch (category) {
    case FormatCategory.standard:
      return generateThumbnail(imageFile, cacheDir);
    case FormatCategory.raw:
      return generateRawThumbnail(imageFile, cacheDir);
    case FormatCategory.heic:
      return generateHeicThumbnail(imageFile, cacheDir);
    case FormatCategory.svg:
      return generateSvgPlaceholder(imageFile, cacheDir);
  }
}

// ── Year/month computation ───────────────────────────────────────────────────

/// Computes "YYYY-MM" string from a DateTime.
String computeYearMonth(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}';
}

// ── Scanner isolate ──────────────────────────────────────────────────────────

/// The main entry point for the scanner isolate.
Future<void> _scannerIsolateEntry(ScanConfig config) async {
  final sendPort = config.sendPort;
  var totalFound = 0;
  final batch = <ScannedPhoto>[];

  await for (final file in walkDirectories(
    config.directories,
    onError: (error, path) {
      sendPort.send(ScanErrorProgress(error, path: path));
    },
  )) {
    totalFound++;

    // Report directory changes periodically
    final dir = p.dirname(file.path);
    if (totalFound % 50 == 1) {
      sendPort.send(CurrentDirectoryProgress(dir));
    }
    if (totalFound % 100 == 0) {
      sendPort.send(PhotosFoundProgress(totalFound));
    }

    // Incremental scan: check if file is unchanged
    final stat = file.statSync();
    final fileModified = stat.modified;
    final existingModified = config.existingFiles[file.path];
    if (existingModified != null && existingModified == fileModified) {
      continue; // File unchanged, skip processing
    }

    // Extract EXIF
    final exif = await extractExif(file);
    final dateTaken = exif.dateTaken ?? fileModified;

    // Generate thumbnail (format-aware)
    final thumbnailPath = await generateThumbnailForFormat(file, config.thumbnailCacheDir);

    final photo = ScannedPhoto(
      path: file.path,
      filename: p.basename(file.path),
      directory: p.dirname(file.path),
      dateTaken: dateTaken,
      fileSize: stat.size,
      format: p.extension(file.path).toLowerCase().replaceFirst('.', ''),
      thumbnailPath: thumbnailPath,
      yearMonth: computeYearMonth(dateTaken),
      orientation: exif.orientation,
      fileModifiedAt: fileModified,
    );

    batch.add(photo);

    // Send batch when it reaches 100
    if (batch.length >= 100) {
      sendPort.send(BatchReadyProgress(List.of(batch)));
      batch.clear();
    }
  }

  // Send remaining photos
  if (batch.isNotEmpty) {
    sendPort.send(BatchReadyProgress(List.of(batch)));
    batch.clear();
  }

  sendPort.send(PhotosFoundProgress(totalFound));
  sendPort.send(ScanCompleteProgress(totalFound));
}

// ── PhotoScanner (main isolate API) ──────────────────────────────────────────

/// Manages scanning photos in a background isolate with progress streaming.
class PhotoScanner {
  Isolate? _isolate;
  ReceivePort? _receivePort;
  StreamController<ScanProgress>? _controller;
  bool _isRunning = false;

  bool get isRunning => _isRunning;

  /// Starts scanning the given directories.
  /// Returns a stream of [ScanProgress] messages.
  ///
  /// [existingFiles] is a map of filePath -> fileModifiedAt for incremental scanning.
  Stream<ScanProgress> startScan({
    required List<String> directories,
    required String thumbnailCacheDir,
    Map<String, DateTime> existingFiles = const {},
  }) {
    if (_isRunning) {
      throw StateError('Scanner is already running');
    }
    _isRunning = true;

    final receivePort = ReceivePort();
    _receivePort = receivePort;

    final controller = StreamController<ScanProgress>();
    _controller = controller;

    final config = ScanConfig(
      directories: directories,
      thumbnailCacheDir: thumbnailCacheDir,
      sendPort: receivePort.sendPort,
      existingFiles: existingFiles,
    );

    // Listen to messages from isolate
    receivePort.listen((message) {
      if (message is ScanProgress) {
        controller.add(message);
        if (message is ScanCompleteProgress) {
          _cleanup();
          controller.close();
        }
      }
    });

    // Spawn isolate and handle the case where stop() is called before spawn completes
    Isolate.spawn(_scannerIsolateEntry, config).then((isolate) {
      if (_isRunning) {
        _isolate = isolate;
      } else {
        // stop() was called before spawn completed - kill the isolate immediately
        isolate.kill(priority: Isolate.immediate);
      }
    }).catchError((error) {
      controller.addError(error);
      _cleanup();
      controller.close();
    });

    return controller.stream;
  }

  /// Stops the currently running scan.
  void stop() {
    if (_isRunning) {
      _cleanup();
    }
  }

  void _cleanup() {
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
    _receivePort?.close();
    _receivePort = null;
    if (_controller != null && !_controller!.isClosed) {
      _controller!.close();
    }
    _controller = null;
    _isRunning = false;
  }
}
