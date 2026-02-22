import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:exif/exif.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;

// ── Supported extensions ─────────────────────────────────────────────────────

const supportedExtensions = {
  '.jpg',
  '.jpeg',
  '.png',
  '.gif',
  '.bmp',
  '.webp',
  '.tiff',
  '.tif',
};

bool isSupportedImage(String path) {
  final ext = p.extension(path).toLowerCase();
  return supportedExtensions.contains(ext);
}

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

    // Generate thumbnail
    final thumbnailPath = await generateThumbnail(file, config.thumbnailCacheDir);

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

    // Spawn isolate
    Isolate.spawn(_scannerIsolateEntry, config).then((isolate) {
      _isolate = isolate;
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
    _isRunning = false;
  }
}
