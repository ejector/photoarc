import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:photoarc/database/database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.inMemory();
  });

  tearDown(() async {
    await db.close();
  });

  // Helper to build a PhotosCompanion with sensible defaults.
  PhotosCompanion makePhoto({
    required String path,
    String filename = 'photo.jpg',
    String directory = '/photos',
    DateTime? dateTaken,
    int fileSize = 1024,
    String format = 'jpg',
    String? yearMonth,
    int orientation = 1,
    bool isValid = true,
    DateTime? fileModifiedAt,
  }) {
    final dt = dateTaken ?? DateTime(2024, 1, 15);
    return PhotosCompanion(
      path: Value(path),
      filename: Value(filename),
      directory: Value(directory),
      dateTaken: Value(dt),
      fileSize: Value(fileSize),
      format: Value(format),
      yearMonth: Value(yearMonth ?? '${dt.year}-${dt.month.toString().padLeft(2, '0')}'),
      orientation: Value(orientation),
      isValid: Value(isValid),
      fileModifiedAt: Value(fileModifiedAt ?? dt),
    );
  }

  group('Photo insert and query', () {
    test('insertPhotoBatch inserts photos', () async {
      await db.insertPhotoBatch([
        makePhoto(path: '/photos/a.jpg'),
        makePhoto(path: '/photos/b.jpg'),
      ]);

      final all = await db.getPhotosPaginated(limit: 10, offset: 0);
      expect(all.length, 2);
    });

    test('insertPhotoBatch updates on conflict (same path)', () async {
      await db.insertPhotoBatch([
        makePhoto(path: '/photos/a.jpg', fileSize: 100),
      ]);

      // Insert again with different size.
      await db.insertPhotoBatch([
        makePhoto(path: '/photos/a.jpg', fileSize: 999),
      ]);

      final all = await db.getPhotosPaginated(limit: 10, offset: 0);
      expect(all.length, 1);
      expect(all.first.fileSize, 999);
    });

    test('getPhotosPaginated filters out invalid photos', () async {
      await db.insertPhotoBatch([
        makePhoto(path: '/photos/valid.jpg', isValid: true),
        makePhoto(path: '/photos/invalid.jpg', isValid: false),
      ]);

      final results = await db.getPhotosPaginated(limit: 10, offset: 0);
      expect(results.length, 1);
      expect(results.first.path, '/photos/valid.jpg');
    });

    test('getPhotosPaginated sorts newest first by default', () async {
      await db.insertPhotoBatch([
        makePhoto(path: '/photos/old.jpg', dateTaken: DateTime(2020, 1, 1)),
        makePhoto(path: '/photos/new.jpg', dateTaken: DateTime(2024, 6, 1)),
        makePhoto(path: '/photos/mid.jpg', dateTaken: DateTime(2022, 3, 1)),
      ]);

      final results = await db.getPhotosPaginated(limit: 10, offset: 0);
      expect(results[0].path, '/photos/new.jpg');
      expect(results[1].path, '/photos/mid.jpg');
      expect(results[2].path, '/photos/old.jpg');
    });

    test('getPhotosPaginated sorts oldest first when requested', () async {
      await db.insertPhotoBatch([
        makePhoto(path: '/photos/old.jpg', dateTaken: DateTime(2020, 1, 1)),
        makePhoto(path: '/photos/new.jpg', dateTaken: DateTime(2024, 6, 1)),
      ]);

      final results = await db.getPhotosPaginated(
        limit: 10,
        offset: 0,
        newestFirst: false,
      );
      expect(results.first.path, '/photos/old.jpg');
      expect(results.last.path, '/photos/new.jpg');
    });

    test('getPhotosPaginated respects limit and offset', () async {
      for (int i = 0; i < 10; i++) {
        await db.insertPhotoBatch([
          makePhoto(
            path: '/photos/$i.jpg',
            dateTaken: DateTime(2024, 1, i + 1),
          ),
        ]);
      }

      final page1 = await db.getPhotosPaginated(limit: 3, offset: 0);
      expect(page1.length, 3);

      final page2 = await db.getPhotosPaginated(limit: 3, offset: 3);
      expect(page2.length, 3);
      // Pages should not overlap.
      expect(
        page1.map((p) => p.path).toSet().intersection(
              page2.map((p) => p.path).toSet(),
            ),
        isEmpty,
      );
    });
  });

  group('Photo queries by year/month', () {
    test('getPhotosByYearMonth returns correct group', () async {
      await db.insertPhotoBatch([
        makePhoto(path: '/a.jpg', dateTaken: DateTime(2023, 3, 10), yearMonth: '2023-03'),
        makePhoto(path: '/b.jpg', dateTaken: DateTime(2023, 3, 20), yearMonth: '2023-03'),
        makePhoto(path: '/c.jpg', dateTaken: DateTime(2023, 5, 1), yearMonth: '2023-05'),
      ]);

      final march = await db.getPhotosByYearMonth('2023-03');
      expect(march.length, 2);

      final may = await db.getPhotosByYearMonth('2023-05');
      expect(may.length, 1);

      final empty = await db.getPhotosByYearMonth('2023-01');
      expect(empty, isEmpty);
    });

    test('getDistinctYearMonths returns sorted values', () async {
      await db.insertPhotoBatch([
        makePhoto(path: '/a.jpg', yearMonth: '2023-03'),
        makePhoto(path: '/b.jpg', yearMonth: '2023-01'),
        makePhoto(path: '/c.jpg', yearMonth: '2024-06'),
      ]);

      final descMonths = await db.getDistinctYearMonths(newestFirst: true);
      expect(descMonths, ['2024-06', '2023-03', '2023-01']);

      final ascMonths = await db.getDistinctYearMonths(newestFirst: false);
      expect(ascMonths, ['2023-01', '2023-03', '2024-06']);
    });
  });

  group('Valid photo count', () {
    test('getValidPhotoCount counts only valid photos', () async {
      await db.insertPhotoBatch([
        makePhoto(path: '/a.jpg', isValid: true),
        makePhoto(path: '/b.jpg', isValid: true),
        makePhoto(path: '/c.jpg', isValid: false),
      ]);

      final count = await db.getValidPhotoCount();
      expect(count, 2);
    });
  });

  group('Scan settings', () {
    test('saveScanFolders and loadScanFolders round-trip', () async {
      await db.saveScanFolders([
        ScanSettingsCompanion(
          folderPath: const Value('/home/user/Pictures'),
          isActive: const Value(true),
        ),
        ScanSettingsCompanion(
          folderPath: const Value('/mnt/external'),
          isActive: const Value(false),
        ),
      ]);

      final loaded = await db.loadScanFolders();
      expect(loaded.length, 2);
      expect(loaded[0].folderPath, '/home/user/Pictures');
      expect(loaded[0].isActive, true);
      expect(loaded[1].folderPath, '/mnt/external');
      expect(loaded[1].isActive, false);
    });

    test('saveScanFolders replaces previous entries', () async {
      await db.saveScanFolders([
        ScanSettingsCompanion(
          folderPath: const Value('/old'),
          isActive: const Value(true),
        ),
      ]);

      await db.saveScanFolders([
        ScanSettingsCompanion(
          folderPath: const Value('/new'),
          isActive: const Value(true),
        ),
      ]);

      final loaded = await db.loadScanFolders();
      expect(loaded.length, 1);
      expect(loaded.first.folderPath, '/new');
    });
  });

  group('App settings', () {
    test('getSetting returns null for unset key', () async {
      final value = await db.getSetting('nonexistent');
      expect(value, isNull);
    });

    test('setSetting and getSetting round-trip', () async {
      await db.setSetting('sort_order', 'desc');
      final value = await db.getSetting('sort_order');
      expect(value, 'desc');
    });

    test('setSetting upserts on same key', () async {
      await db.setSetting('sort_order', 'desc');
      await db.setSetting('sort_order', 'asc');

      final value = await db.getSetting('sort_order');
      expect(value, 'asc');
    });
  });

  group('Batch insert', () {
    test('large batch insert works correctly', () async {
      final photos = List.generate(
        250,
        (i) => makePhoto(
          path: '/photos/batch_$i.jpg',
          dateTaken: DateTime(2024, 1, 1).add(Duration(hours: i)),
        ),
      );

      await db.insertPhotoBatch(photos);
      final count = await db.getValidPhotoCount();
      expect(count, 250);

      // Pagination works across the large set.
      final page = await db.getPhotosPaginated(limit: 50, offset: 200);
      expect(page.length, 50);
    });
  });

  group('Database file migration', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('photoarc_test_');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('onDisk renames photo_feed.db to photoarc.db when old file exists',
        () async {
      // Create a legacy database file.
      final oldFile = File(p.join(tempDir.path, 'photo_feed.db'));
      oldFile.writeAsStringSync('legacy_data');

      final newFile = File(p.join(tempDir.path, 'photoarc.db'));
      expect(newFile.existsSync(), isFalse);

      final db = AppDatabase.onDisk(tempDir.path);
      addTearDown(() => db.close());

      // The old file should have been renamed.
      expect(oldFile.existsSync(), isFalse);
      expect(newFile.existsSync(), isTrue);
    });

    test('onDisk renames WAL and SHM journal files alongside main db', () async {
      final oldFile = File(p.join(tempDir.path, 'photo_feed.db'));
      oldFile.writeAsStringSync('legacy_data');
      final oldWal = File(p.join(tempDir.path, 'photo_feed.db-wal'));
      oldWal.writeAsStringSync('wal_data');
      final oldShm = File(p.join(tempDir.path, 'photo_feed.db-shm'));
      oldShm.writeAsStringSync('shm_data');

      final db = AppDatabase.onDisk(tempDir.path);
      addTearDown(() => db.close());

      expect(oldFile.existsSync(), isFalse);
      expect(oldWal.existsSync(), isFalse);
      expect(oldShm.existsSync(), isFalse);

      final newWal = File(p.join(tempDir.path, 'photoarc.db-wal'));
      final newShm = File(p.join(tempDir.path, 'photoarc.db-shm'));
      expect(newWal.existsSync(), isTrue);
      expect(newShm.existsSync(), isTrue);
      expect(newWal.readAsStringSync(), 'wal_data');
      expect(newShm.readAsStringSync(), 'shm_data');
    });

    test('onDisk uses photoarc.db when it already exists', () async {
      // Create the new database file.
      final newFile = File(p.join(tempDir.path, 'photoarc.db'));
      newFile.writeAsStringSync('new_data');

      final db = AppDatabase.onDisk(tempDir.path);
      addTearDown(() => db.close());

      // The new file should still exist.
      expect(newFile.existsSync(), isTrue);
    });

    test('onDisk does not touch old file when new file already exists',
        () async {
      // Both files exist; only photoarc.db should be used.
      final oldFile = File(p.join(tempDir.path, 'photo_feed.db'));
      oldFile.writeAsStringSync('old_data');
      final newFile = File(p.join(tempDir.path, 'photoarc.db'));
      newFile.writeAsStringSync('new_data');

      final db = AppDatabase.onDisk(tempDir.path);
      addTearDown(() => db.close());

      // Both files still present; old file untouched.
      expect(oldFile.existsSync(), isTrue);
      expect(newFile.existsSync(), isTrue);
      expect(oldFile.readAsStringSync(), 'old_data');
    });

    test('onDisk creates new db when neither file exists', () async {
      final newFile = File(p.join(tempDir.path, 'photoarc.db'));
      expect(newFile.existsSync(), isFalse);

      final db = AppDatabase.onDisk(tempDir.path);
      addTearDown(() => db.close());

      // Trigger a query to force the background isolate to open/create the file.
      await db.getValidPhotoCount();
      expect(newFile.existsSync(), isTrue);
    });
  });
}
