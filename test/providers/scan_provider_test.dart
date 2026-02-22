import 'dart:async';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:photo_feed/database/database.dart';
import 'package:photo_feed/providers/scan_provider.dart';
import 'package:photo_feed/services/photo_scanner.dart';
import 'package:photo_feed/services/platform_service.dart';

/// A fake PhotoScanner that emits controllable progress events.
class FakePhotoScanner extends PhotoScanner {
  final StreamController<ScanProgress> _controller =
      StreamController<ScanProgress>.broadcast();
  bool startScanCalled = false;
  bool stopCalled = false;
  List<String>? lastDirectories;
  String? lastThumbnailCacheDir;

  @override
  bool get isRunning => startScanCalled && !stopCalled;

  @override
  Stream<ScanProgress> startScan({
    required List<String> directories,
    required String thumbnailCacheDir,
    Map<String, DateTime> existingFiles = const {},
  }) {
    startScanCalled = true;
    stopCalled = false;
    lastDirectories = directories;
    lastThumbnailCacheDir = thumbnailCacheDir;
    return _controller.stream;
  }

  @override
  void stop() {
    stopCalled = true;
  }

  void emit(ScanProgress progress) {
    _controller.add(progress);
  }

  void emitDone() {
    _controller.close();
  }
}

PlatformService _fakePlatformService() {
  return PlatformService.custom(
    getAvailableDrives: () async => [],
    getDefaultPhotoDirectories: () => ['/fake/Pictures'],
    openFileManager: (_) async {},
    getThumbnailCacheDirectory: () async => '/fake/cache/thumbnails',
  );
}

void main() {
  late AppDatabase db;
  late FakePhotoScanner fakeScanner;
  late ScanProvider provider;

  setUp(() {
    db = AppDatabase.inMemory();
    fakeScanner = FakePhotoScanner();
    provider = ScanProvider(
      db: db,
      platformService: _fakePlatformService(),
      scanner: fakeScanner,
    );
  });

  tearDown(() async {
    provider.dispose();
    await db.close();
  });

  group('Folder selection', () {
    test('starts with empty folders', () {
      expect(provider.selectedFolders, isEmpty);
    });

    test('setSelectedFolders replaces all folders', () {
      provider.setSelectedFolders(['/a', '/b']);
      expect(provider.selectedFolders, ['/a', '/b']);
    });

    test('addFolder adds unique folder', () {
      provider.addFolder('/a');
      provider.addFolder('/b');
      provider.addFolder('/a'); // duplicate
      expect(provider.selectedFolders, ['/a', '/b']);
    });

    test('removeFolder removes existing folder', () {
      provider.setSelectedFolders(['/a', '/b', '/c']);
      provider.removeFolder('/b');
      expect(provider.selectedFolders, ['/a', '/c']);
    });

    test('removeFolder does nothing for non-existent folder', () {
      provider.setSelectedFolders(['/a']);
      provider.removeFolder('/z');
      expect(provider.selectedFolders, ['/a']);
    });

    test('toggleFolder adds and removes', () {
      provider.toggleFolder('/a');
      expect(provider.selectedFolders, ['/a']);
      provider.toggleFolder('/a');
      expect(provider.selectedFolders, isEmpty);
    });

    test('saveFolders persists to database', () async {
      provider.setSelectedFolders(['/photos', '/downloads']);
      await provider.saveFolders();

      final saved = await db.loadScanFolders();
      expect(saved.length, 2);
      expect(saved.map((s) => s.folderPath).toSet(), {'/photos', '/downloads'});
    });

    test('loadFolders restores from database', () async {
      await db.saveScanFolders([
        ScanSettingsCompanion(
          folderPath: const Value('/saved/a'),
          isActive: const Value(true),
        ),
        ScanSettingsCompanion(
          folderPath: const Value('/saved/b'),
          isActive: const Value(false),
        ),
      ]);

      await provider.loadFolders();
      // Only active folders are loaded
      expect(provider.selectedFolders, ['/saved/a']);
    });

    test('notifies listeners on folder changes', () {
      var notifyCount = 0;
      provider.addListener(() => notifyCount++);

      provider.addFolder('/a');
      expect(notifyCount, 1);
      provider.removeFolder('/a');
      expect(notifyCount, 2);
      provider.setSelectedFolders(['/x']);
      expect(notifyCount, 3);
      provider.toggleFolder('/x');
      expect(notifyCount, 4);
    });
  });

  group('Scan lifecycle', () {
    test('initial state is not scanning', () {
      expect(provider.isScanning, isFalse);
      expect(provider.photosFound, 0);
      expect(provider.currentDirectory, '');
      expect(provider.scanComplete, isFalse);
    });

    test('startScan does nothing with empty folders', () async {
      await provider.startScan();
      expect(provider.isScanning, isFalse);
      expect(fakeScanner.startScanCalled, isFalse);
    });

    test('startScan transitions to scanning state', () async {
      provider.setSelectedFolders(['/photos']);
      await provider.startScan();

      expect(provider.isScanning, isTrue);
      expect(fakeScanner.startScanCalled, isTrue);
      expect(fakeScanner.lastDirectories, ['/photos']);
      expect(fakeScanner.lastThumbnailCacheDir, '/fake/cache/thumbnails');
    });

    test('handles PhotosFoundProgress', () async {
      provider.setSelectedFolders(['/photos']);
      await provider.startScan();

      fakeScanner.emit(PhotosFoundProgress(42));
      await Future.delayed(Duration.zero); // Let the microtask complete

      expect(provider.photosFound, 42);
    });

    test('handles CurrentDirectoryProgress', () async {
      provider.setSelectedFolders(['/photos']);
      await provider.startScan();

      fakeScanner.emit(CurrentDirectoryProgress('/photos/vacation'));
      await Future.delayed(Duration.zero);

      expect(provider.currentDirectory, '/photos/vacation');
    });

    test('handles BatchReadyProgress - inserts into database', () async {
      provider.setSelectedFolders(['/photos']);
      await provider.startScan();

      final scannedPhotos = [
        ScannedPhoto(
          path: '/photos/img1.jpg',
          filename: 'img1.jpg',
          directory: '/photos',
          dateTaken: DateTime(2024, 3, 15),
          fileSize: 2048,
          format: 'jpg',
          yearMonth: '2024-03',
          orientation: 1,
          fileModifiedAt: DateTime(2024, 3, 15),
        ),
      ];

      fakeScanner.emit(BatchReadyProgress(scannedPhotos));
      await Future.delayed(const Duration(milliseconds: 50));

      final dbPhotos = await db.getPhotosPaginated(limit: 10, offset: 0);
      expect(dbPhotos.length, 1);
      expect(dbPhotos[0].path, '/photos/img1.jpg');
    });

    test('handles ScanCompleteProgress', () async {
      provider.setSelectedFolders(['/photos']);
      await provider.startScan();

      fakeScanner.emit(ScanCompleteProgress(100));
      await Future.delayed(Duration.zero);

      expect(provider.scanComplete, isTrue);
      expect(provider.totalPhotos, 100);
      expect(provider.isScanning, isFalse);
    });

    test('stopScan stops the scanner', () async {
      provider.setSelectedFolders(['/photos']);
      await provider.startScan();

      await provider.stopScan();

      expect(provider.isScanning, isFalse);
      expect(fakeScanner.stopCalled, isTrue);
    });

    test('startScan persists folders before scanning', () async {
      provider.setSelectedFolders(['/my/photos']);
      await provider.startScan();

      final saved = await db.loadScanFolders();
      expect(saved.length, 1);
      expect(saved[0].folderPath, '/my/photos');
    });
  });
}
