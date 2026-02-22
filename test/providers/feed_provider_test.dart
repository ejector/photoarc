import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:photo_feed/database/database.dart';
import 'package:photo_feed/providers/feed_provider.dart';

PhotosCompanion _makePhoto({
  required String path,
  required DateTime dateTaken,
  String? yearMonth,
}) {
  final ym = yearMonth ??
      '${dateTaken.year}-${dateTaken.month.toString().padLeft(2, '0')}';
  return PhotosCompanion(
    path: Value(path),
    filename: Value(path.split('/').last),
    directory: const Value('/photos'),
    dateTaken: Value(dateTaken),
    fileSize: const Value(1024),
    format: const Value('jpg'),
    yearMonth: Value(ym),
    orientation: const Value(1),
    isValid: const Value(true),
    fileModifiedAt: Value(dateTaken),
  );
}

void main() {
  late AppDatabase db;
  late FeedProvider provider;

  setUp(() {
    db = AppDatabase.inMemory();
    provider = FeedProvider(db: db);
  });

  tearDown(() async {
    provider.dispose();
    await db.close();
  });

  group('Initial state', () {
    test('starts with empty photos and default sort', () {
      expect(provider.photos, isEmpty);
      expect(provider.newestFirst, isTrue);
      expect(provider.isLoading, isFalse);
      expect(provider.hasMore, isTrue);
      expect(provider.yearMonths, isEmpty);
    });
  });

  group('Loading photos', () {
    test('loadMore fetches photos from database', () async {
      await db.insertPhotoBatch([
        _makePhoto(path: '/a.jpg', dateTaken: DateTime(2024, 1, 10)),
        _makePhoto(path: '/b.jpg', dateTaken: DateTime(2024, 2, 20)),
      ]);

      await provider.loadMore();

      expect(provider.photos.length, 2);
      // Default sort: newest first
      expect(provider.photos[0].path, '/b.jpg');
      expect(provider.photos[1].path, '/a.jpg');
    });

    test('loadMore paginates correctly', () async {
      // Insert more than one page would hold if we used smaller sizes,
      // but here test that hasMore becomes false when results < pageSize
      await db.insertPhotoBatch([
        _makePhoto(path: '/a.jpg', dateTaken: DateTime(2024, 1, 1)),
      ]);

      await provider.loadMore();

      expect(provider.photos.length, 1);
      expect(provider.hasMore, isFalse); // 1 < 200 (page size)
    });

    test('loadMore does nothing when already loading', () async {
      await db.insertPhotoBatch([
        _makePhoto(path: '/a.jpg', dateTaken: DateTime(2024, 1, 1)),
      ]);

      // First load
      await provider.loadMore();
      final count = provider.photos.length;

      // hasMore is false, so second load should be no-op
      await provider.loadMore();
      expect(provider.photos.length, count);
    });

    test('refresh resets and reloads', () async {
      await db.insertPhotoBatch([
        _makePhoto(path: '/a.jpg', dateTaken: DateTime(2024, 1, 1)),
      ]);

      await provider.loadMore();
      expect(provider.photos.length, 1);

      // Add another photo
      await db.insertPhotoBatch([
        _makePhoto(path: '/b.jpg', dateTaken: DateTime(2024, 2, 1)),
      ]);

      await provider.refresh();
      expect(provider.photos.length, 2);
    });
  });

  group('Sorting', () {
    test('toggleSortOrder switches between newest and oldest', () async {
      await db.insertPhotoBatch([
        _makePhoto(path: '/old.jpg', dateTaken: DateTime(2023, 1, 1)),
        _makePhoto(path: '/new.jpg', dateTaken: DateTime(2024, 6, 1)),
      ]);

      await provider.loadMore();
      expect(provider.photos[0].path, '/new.jpg'); // newest first

      await provider.toggleSortOrder();
      expect(provider.newestFirst, isFalse);
      expect(provider.photos[0].path, '/old.jpg'); // oldest first
    });

    test('setSortOrder does nothing when value unchanged', () async {
      var notifyCount = 0;
      provider.addListener(() => notifyCount++);

      await provider.setSortOrder(newestFirst: true); // Already true
      expect(notifyCount, 0);
    });

    test('sort preference is persisted', () async {
      await provider.toggleSortOrder(); // Now false
      expect(provider.newestFirst, isFalse);

      // Create a new provider and initialize it - should restore sort pref
      final provider2 = FeedProvider(db: db);
      await provider2.initialize();
      expect(provider2.newestFirst, isFalse);
      provider2.dispose();
    });
  });

  group('Year-month grouping', () {
    test('photosByYearMonth groups correctly', () async {
      await db.insertPhotoBatch([
        _makePhoto(path: '/jan1.jpg', dateTaken: DateTime(2024, 1, 5)),
        _makePhoto(path: '/jan2.jpg', dateTaken: DateTime(2024, 1, 20)),
        _makePhoto(path: '/mar.jpg', dateTaken: DateTime(2024, 3, 10)),
      ]);

      await provider.loadMore();
      final groups = provider.photosByYearMonth;

      expect(groups.keys, contains('2024-01'));
      expect(groups.keys, contains('2024-03'));
      expect(groups['2024-01']!.length, 2);
      expect(groups['2024-03']!.length, 1);
    });

    test('yearMonths are loaded after refresh', () async {
      await db.insertPhotoBatch([
        _makePhoto(path: '/a.jpg', dateTaken: DateTime(2024, 1, 1)),
        _makePhoto(path: '/b.jpg', dateTaken: DateTime(2024, 3, 1)),
        _makePhoto(path: '/c.jpg', dateTaken: DateTime(2023, 12, 1)),
      ]);

      await provider.refresh();

      expect(provider.yearMonths.length, 3);
      // Default newest first
      expect(provider.yearMonths[0], '2024-03');
      expect(provider.yearMonths[1], '2024-01');
      expect(provider.yearMonths[2], '2023-12');
    });
  });

  group('Initialize', () {
    test('initialize loads sort preference and photos', () async {
      // Set a sort preference
      await db.setSetting('feed_sort_newest_first', 'false');
      await db.insertPhotoBatch([
        _makePhoto(path: '/a.jpg', dateTaken: DateTime(2024, 1, 1)),
      ]);

      await provider.initialize();

      expect(provider.newestFirst, isFalse);
      expect(provider.photos.length, 1);
    });
  });

  group('Notifications', () {
    test('notifies listeners during loadMore', () async {
      await db.insertPhotoBatch([
        _makePhoto(path: '/a.jpg', dateTaken: DateTime(2024, 1, 1)),
      ]);

      var notifyCount = 0;
      provider.addListener(() => notifyCount++);

      await provider.loadMore();

      // Should notify at least twice: loading=true, loading=false
      expect(notifyCount, greaterThanOrEqualTo(2));
    });
  });
}
