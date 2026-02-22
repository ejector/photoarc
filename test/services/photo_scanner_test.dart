import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:photo_feed/services/photo_scanner.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('photo_scanner_test_');
  });

  tearDown(() {
    tempDir.deleteSync(recursive: true);
  });

  group('isSupportedImage', () {
    test('accepts supported extensions', () {
      expect(isSupportedImage('photo.jpg'), isTrue);
      expect(isSupportedImage('photo.jpeg'), isTrue);
      expect(isSupportedImage('photo.png'), isTrue);
      expect(isSupportedImage('photo.gif'), isTrue);
      expect(isSupportedImage('photo.bmp'), isTrue);
      expect(isSupportedImage('photo.webp'), isTrue);
      expect(isSupportedImage('photo.tiff'), isTrue);
      expect(isSupportedImage('photo.tif'), isTrue);
    });

    test('accepts uppercase extensions', () {
      expect(isSupportedImage('photo.JPG'), isTrue);
      expect(isSupportedImage('photo.PNG'), isTrue);
      expect(isSupportedImage('photo.TIFF'), isTrue);
    });

    test('rejects unsupported extensions', () {
      expect(isSupportedImage('document.pdf'), isFalse);
      expect(isSupportedImage('video.mp4'), isFalse);
      expect(isSupportedImage('readme.txt'), isFalse);
      expect(isSupportedImage('raw.cr2'), isFalse);
      expect(isSupportedImage('photo.heic'), isFalse);
    });

    test('rejects files without extension', () {
      expect(isSupportedImage('noextension'), isFalse);
    });
  });

  group('computeYearMonth', () {
    test('formats single-digit months with leading zero', () {
      expect(computeYearMonth(DateTime(2024, 1, 15)), '2024-01');
      expect(computeYearMonth(DateTime(2024, 9, 1)), '2024-09');
    });

    test('formats double-digit months correctly', () {
      expect(computeYearMonth(DateTime(2024, 10, 1)), '2024-10');
      expect(computeYearMonth(DateTime(2024, 12, 31)), '2024-12');
    });

    test('handles various years', () {
      expect(computeYearMonth(DateTime(2000, 6, 15)), '2000-06');
      expect(computeYearMonth(DateTime(1999, 3, 1)), '1999-03');
    });
  });

  group('walkDirectories', () {
    test('finds supported image files in a directory', () async {
      // Create test files
      File(p.join(tempDir.path, 'photo1.jpg')).createSync();
      File(p.join(tempDir.path, 'photo2.png')).createSync();
      File(p.join(tempDir.path, 'document.txt')).createSync();

      final files = await walkDirectories([tempDir.path]).toList();
      final filenames = files.map((f) => p.basename(f.path)).toSet();

      expect(filenames, contains('photo1.jpg'));
      expect(filenames, contains('photo2.png'));
      expect(filenames, isNot(contains('document.txt')));
    });

    test('recurses into subdirectories', () async {
      final subDir = Directory(p.join(tempDir.path, 'subdir'));
      subDir.createSync();
      File(p.join(tempDir.path, 'root.jpg')).createSync();
      File(p.join(subDir.path, 'nested.png')).createSync();

      final files = await walkDirectories([tempDir.path]).toList();
      final filenames = files.map((f) => p.basename(f.path)).toSet();

      expect(filenames, contains('root.jpg'));
      expect(filenames, contains('nested.png'));
    });

    test('skips hidden directories', () async {
      final hiddenDir = Directory(p.join(tempDir.path, '.hidden'));
      hiddenDir.createSync();
      File(p.join(hiddenDir.path, 'secret.jpg')).createSync();
      File(p.join(tempDir.path, 'visible.jpg')).createSync();

      final files = await walkDirectories([tempDir.path]).toList();
      final filenames = files.map((f) => p.basename(f.path)).toSet();

      expect(filenames, contains('visible.jpg'));
      expect(filenames, isNot(contains('secret.jpg')));
    });

    test('skips hidden files', () async {
      File(p.join(tempDir.path, '.hidden.jpg')).createSync();
      File(p.join(tempDir.path, 'visible.jpg')).createSync();

      final files = await walkDirectories([tempDir.path]).toList();
      final filenames = files.map((f) => p.basename(f.path)).toSet();

      expect(filenames, contains('visible.jpg'));
      expect(filenames, isNot(contains('.hidden.jpg')));
    });

    test('handles multiple root directories', () async {
      final dir1 = Directory(p.join(tempDir.path, 'dir1'));
      final dir2 = Directory(p.join(tempDir.path, 'dir2'));
      dir1.createSync();
      dir2.createSync();
      File(p.join(dir1.path, 'a.jpg')).createSync();
      File(p.join(dir2.path, 'b.png')).createSync();

      final files = await walkDirectories([dir1.path, dir2.path]).toList();
      final filenames = files.map((f) => p.basename(f.path)).toSet();

      expect(filenames, contains('a.jpg'));
      expect(filenames, contains('b.png'));
    });

    test('handles symlink loops without hanging', () async {
      final dir1 = Directory(p.join(tempDir.path, 'dir1'));
      dir1.createSync();
      File(p.join(dir1.path, 'photo.jpg')).createSync();

      // Create symlink loop: dir1/link -> dir1
      try {
        Link(p.join(dir1.path, 'loop')).createSync(dir1.path);
      } on FileSystemException {
        // Symlinks may not be supported on all platforms
        return;
      }

      final files = await walkDirectories([dir1.path]).toList();
      // Should complete without hanging and find the photo
      expect(files.map((f) => p.basename(f.path)), contains('photo.jpg'));
    });

    test('reports errors for inaccessible directories', () async {
      final errors = <String>[];

      // Use a non-existent directory
      final noDir = Directory(p.join(tempDir.path, 'nonexistent'));
      final files = await walkDirectories(
        [noDir.path],
        onError: (error, path) => errors.add(error),
      ).toList();

      expect(files, isEmpty);
      // Should have reported an error
      expect(errors, isNotEmpty);
    });

    test('returns empty stream for empty directory', () async {
      final files = await walkDirectories([tempDir.path]).toList();
      expect(files, isEmpty);
    });

    test('handles all supported extensions', () async {
      for (final ext in supportedExtensions) {
        File(p.join(tempDir.path, 'test$ext')).createSync();
      }

      final files = await walkDirectories([tempDir.path]).toList();
      expect(files.length, supportedExtensions.length);
    });
  });

  group('extractExif', () {
    test('returns default values for non-EXIF file', () async {
      final file = File(p.join(tempDir.path, 'plain.jpg'));
      file.writeAsBytesSync([0xFF, 0xD8, 0xFF, 0xE0]); // Minimal JPEG header

      final result = await extractExif(file);
      expect(result.dateTaken, isNull);
      expect(result.orientation, 1);
    });

    test('returns default values for empty file', () async {
      final file = File(p.join(tempDir.path, 'empty.jpg'));
      file.writeAsBytesSync([]);

      final result = await extractExif(file);
      expect(result.dateTaken, isNull);
      expect(result.orientation, 1);
    });

    test('returns default values for corrupt file', () async {
      final file = File(p.join(tempDir.path, 'corrupt.jpg'));
      file.writeAsBytesSync([0x00, 0x01, 0x02, 0x03]);

      final result = await extractExif(file);
      expect(result.dateTaken, isNull);
      expect(result.orientation, 1);
    });
  });

  group('generateThumbnail', () {
    test('returns null for invalid image data', () async {
      final file = File(p.join(tempDir.path, 'bad.jpg'));
      file.writeAsBytesSync([0xFF, 0xD8]);

      final cacheDir = p.join(tempDir.path, 'cache');
      Directory(cacheDir).createSync();

      final result = await generateThumbnail(file, cacheDir);
      expect(result, isNull);
    });

    test('generates thumbnail for valid PNG image', () async {
      final pngBytes = _createValidPng(400, 300);

      final file = File(p.join(tempDir.path, 'test.png'));
      file.writeAsBytesSync(pngBytes);

      final cacheDir = p.join(tempDir.path, 'cache');
      Directory(cacheDir).createSync();

      final thumbPath = await generateThumbnail(file, cacheDir);
      expect(thumbPath, isNotNull);
      expect(File(thumbPath!).existsSync(), isTrue);
      expect(thumbPath, endsWith('_thumb.jpg'));
    });

    test('generates thumbnail in specified cache directory', () async {
      final pngBytes = _createValidPng(200, 200);

      final file = File(p.join(tempDir.path, 'test.png'));
      file.writeAsBytesSync(pngBytes);

      final cacheDir = p.join(tempDir.path, 'my_cache');
      Directory(cacheDir).createSync();

      final thumbPath = await generateThumbnail(file, cacheDir);
      expect(thumbPath, isNotNull);
      expect(thumbPath!, startsWith(cacheDir));
    });
  });

  group('ScanProgress message types', () {
    test('PhotosFoundProgress holds count', () {
      final msg = PhotosFoundProgress(42);
      expect(msg.count, 42);
    });

    test('CurrentDirectoryProgress holds directory', () {
      final msg = CurrentDirectoryProgress('/home/user/Photos');
      expect(msg.directory, '/home/user/Photos');
    });

    test('BatchReadyProgress holds photos list', () {
      final photos = [
        ScannedPhoto(
          path: '/test.jpg',
          filename: 'test.jpg',
          directory: '/',
          dateTaken: DateTime(2024, 1, 1),
          fileSize: 1000,
          format: 'jpg',
          yearMonth: '2024-01',
          orientation: 1,
          fileModifiedAt: DateTime(2024, 1, 1),
        ),
      ];
      final msg = BatchReadyProgress(photos);
      expect(msg.photos.length, 1);
      expect(msg.photos[0].filename, 'test.jpg');
    });

    test('ScanCompleteProgress holds total count', () {
      final msg = ScanCompleteProgress(100);
      expect(msg.totalPhotos, 100);
    });

    test('ScanErrorProgress holds message and optional path', () {
      final msg = ScanErrorProgress('Permission denied', path: '/secret');
      expect(msg.message, 'Permission denied');
      expect(msg.path, '/secret');

      final msg2 = ScanErrorProgress('General error');
      expect(msg2.path, isNull);
    });
  });

  group('ScannedPhoto', () {
    test('holds all required fields', () {
      final photo = ScannedPhoto(
        path: '/photos/vacation/beach.jpg',
        filename: 'beach.jpg',
        directory: '/photos/vacation',
        dateTaken: DateTime(2024, 7, 15, 14, 30),
        fileSize: 5242880,
        format: 'jpg',
        width: 4000,
        height: 3000,
        thumbnailPath: '/cache/abc_thumb.jpg',
        yearMonth: '2024-07',
        orientation: 6,
        fileModifiedAt: DateTime(2024, 7, 15, 14, 30),
      );

      expect(photo.path, '/photos/vacation/beach.jpg');
      expect(photo.filename, 'beach.jpg');
      expect(photo.directory, '/photos/vacation');
      expect(photo.fileSize, 5242880);
      expect(photo.format, 'jpg');
      expect(photo.width, 4000);
      expect(photo.height, 3000);
      expect(photo.thumbnailPath, '/cache/abc_thumb.jpg');
      expect(photo.yearMonth, '2024-07');
      expect(photo.orientation, 6);
    });

    test('allows null optional fields', () {
      final photo = ScannedPhoto(
        path: '/test.png',
        filename: 'test.png',
        directory: '/',
        dateTaken: DateTime(2024, 1, 1),
        fileSize: 100,
        format: 'png',
        yearMonth: '2024-01',
        orientation: 1,
        fileModifiedAt: DateTime(2024, 1, 1),
      );

      expect(photo.width, isNull);
      expect(photo.height, isNull);
      expect(photo.thumbnailPath, isNull);
    });
  });

  group('PhotoScanner', () {
    test('starts in non-running state', () {
      final scanner = PhotoScanner();
      expect(scanner.isRunning, isFalse);
    });

    test('throws if started while already running', () {
      final scanner = PhotoScanner();
      final cacheDir = p.join(tempDir.path, 'cache');
      Directory(cacheDir).createSync();

      // Start first scan
      scanner.startScan(
        directories: [tempDir.path],
        thumbnailCacheDir: cacheDir,
      );

      expect(scanner.isRunning, isTrue);

      // Second scan should throw
      expect(
        () => scanner.startScan(
          directories: [tempDir.path],
          thumbnailCacheDir: cacheDir,
        ),
        throwsStateError,
      );

      scanner.stop();
    });

    test('can be stopped', () {
      final scanner = PhotoScanner();
      final cacheDir = p.join(tempDir.path, 'cache');
      Directory(cacheDir).createSync();

      scanner.startScan(
        directories: [tempDir.path],
        thumbnailCacheDir: cacheDir,
      );

      expect(scanner.isRunning, isTrue);
      scanner.stop();
      expect(scanner.isRunning, isFalse);
    });

    test('scans directory and emits progress', () async {
      // Create test image files (just empty files for walking - won't generate thumbnails)
      File(p.join(tempDir.path, 'photo1.jpg')).createSync();
      File(p.join(tempDir.path, 'photo2.png')).createSync();

      final cacheDir = p.join(tempDir.path, 'cache');
      Directory(cacheDir).createSync();

      final scanner = PhotoScanner();
      final progress = <ScanProgress>[];

      await for (final msg in scanner.startScan(
        directories: [tempDir.path],
        thumbnailCacheDir: cacheDir,
      )) {
        progress.add(msg);
      }

      // Should end with ScanCompleteProgress
      expect(progress.last, isA<ScanCompleteProgress>());
      final complete = progress.last as ScanCompleteProgress;
      expect(complete.totalPhotos, 2);

      expect(scanner.isRunning, isFalse);
    });

    test('batches photos and sends BatchReadyProgress', () async {
      // Create enough files to trigger a batch (need >0 but won't test 100 for speed)
      File(p.join(tempDir.path, 'a.jpg')).createSync();

      final cacheDir = p.join(tempDir.path, 'cache');
      Directory(cacheDir).createSync();

      final scanner = PhotoScanner();
      final batches = <BatchReadyProgress>[];

      await for (final msg in scanner.startScan(
        directories: [tempDir.path],
        thumbnailCacheDir: cacheDir,
      )) {
        if (msg is BatchReadyProgress) {
          batches.add(msg);
        }
      }

      // Should have at least one batch with the remaining photos
      expect(batches, isNotEmpty);
      expect(batches.first.photos.first.filename, 'a.jpg');
    });

    test('incremental scan skips unchanged files', () async {
      final file = File(p.join(tempDir.path, 'existing.jpg'));
      file.createSync();
      final modTime = file.statSync().modified;

      final cacheDir = p.join(tempDir.path, 'cache');
      Directory(cacheDir).createSync();

      final scanner = PhotoScanner();
      final batches = <BatchReadyProgress>[];

      await for (final msg in scanner.startScan(
        directories: [tempDir.path],
        thumbnailCacheDir: cacheDir,
        existingFiles: {file.path: modTime},
      )) {
        if (msg is BatchReadyProgress) {
          batches.add(msg);
        }
      }

      // File should be skipped since mod time matches
      expect(batches, isEmpty);
    });

    test('incremental scan processes changed files', () async {
      final file = File(p.join(tempDir.path, 'changed.jpg'));
      file.createSync();

      final cacheDir = p.join(tempDir.path, 'cache');
      Directory(cacheDir).createSync();

      final scanner = PhotoScanner();
      final batches = <BatchReadyProgress>[];

      // Pass an old modification time - file should be processed
      await for (final msg in scanner.startScan(
        directories: [tempDir.path],
        thumbnailCacheDir: cacheDir,
        existingFiles: {file.path: DateTime(2000, 1, 1)},
      )) {
        if (msg is BatchReadyProgress) {
          batches.add(msg);
        }
      }

      expect(batches, isNotEmpty);
      expect(batches.first.photos.first.filename, 'changed.jpg');
    });
  });
}

// ── Test helpers ──────────────────────────────────────────────────────────────

/// Creates a valid PNG image using the image package.
List<int> _createValidPng(int width, int height) {
  final image = img.Image(width: width, height: height);
  // Fill with a solid color so it's a valid decodable image
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      image.setPixelRgb(x, y, 255, 0, 0);
    }
  }
  return img.encodePng(image);
}
