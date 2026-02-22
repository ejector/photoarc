import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:photo_feed/services/thumbnail_cache.dart';
import 'package:photo_feed/services/thumbnail_service.dart';

Uint8List _bytes(List<int> values) => Uint8List.fromList(values);

void main() {
  group('ThumbnailService', () {
    late ThumbnailCache memoryCache;
    late Map<String, bool> fakeFileSystem;
    late ThumbnailService service;

    setUp(() {
      memoryCache = ThumbnailCache(maxEntries: 5);
      fakeFileSystem = {};
      service = ThumbnailService(
        memoryCache: memoryCache,
        fileExistsSync: (path) => fakeFileSystem[path] ?? false,
      );
    });

    test('returns null when no thumbnail in memory or disk', () async {
      final result = await service.loadThumbnail(
        photoPath: '/photos/img.jpg',
        thumbnailPath: '/cache/thumb.jpg',
      );
      expect(result, isNull);
    });

    test('returns null when thumbnailPath is null', () async {
      final result = await service.loadThumbnail(
        photoPath: '/photos/img.jpg',
        thumbnailPath: null,
      );
      expect(result, isNull);
    });

    test('returns null when thumbnailPath is empty', () async {
      final result = await service.loadThumbnail(
        photoPath: '/photos/img.jpg',
        thumbnailPath: '',
      );
      expect(result, isNull);
    });

    test('returns from memory cache on hit', () async {
      final data = _bytes([1, 2, 3]);
      memoryCache.put('/photos/img.jpg', data);

      final result = await service.loadThumbnail(
        photoPath: '/photos/img.jpg',
        thumbnailPath: '/cache/thumb.jpg',
      );
      expect(result, equals(data));
    });

    test('getFromMemory returns cached data', () {
      final data = _bytes([1, 2, 3]);
      memoryCache.put('/photos/img.jpg', data);

      final result = service.getFromMemory('/photos/img.jpg');
      expect(result, equals(data));
    });

    test('getFromMemory returns null on cache miss', () {
      final result = service.getFromMemory('/photos/img.jpg');
      expect(result, isNull);
    });

    test('putInMemory stores data retrievable by getFromMemory', () {
      final data = _bytes([4, 5, 6]);
      service.putInMemory('/photos/img.jpg', data);

      final result = service.getFromMemory('/photos/img.jpg');
      expect(result, equals(data));
    });

    test('evictFromMemory removes entry', () {
      service.putInMemory('/photos/img.jpg', _bytes([1]));
      service.evictFromMemory('/photos/img.jpg');
      expect(service.memoryCacheSize, 0);
    });

    test('clearMemoryCache removes all entries', () {
      service.putInMemory('/a', _bytes([1]));
      service.putInMemory('/b', _bytes([2]));
      service.clearMemoryCache();
      expect(service.memoryCacheSize, 0);
    });

    test('memoryCacheSize returns count', () {
      expect(service.memoryCacheSize, 0);
      service.putInMemory('/a', _bytes([1]));
      expect(service.memoryCacheSize, 1);
    });

    test('memoryCacheSizeBytes returns total bytes', () {
      service.putInMemory('/a', _bytes([1, 2, 3]));
      service.putInMemory('/b', _bytes([4, 5]));
      expect(service.memoryCacheSizeBytes, 5);
    });

    group('disk cache with real files', () {
      late Directory tempDir;

      setUp(() async {
        tempDir = await Directory.systemTemp.createTemp('thumb_test_');
      });

      tearDown(() async {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      });

      test('loads from disk when not in memory and file exists', () async {
        final thumbPath = '${tempDir.path}/thumb.jpg';
        final thumbData = _bytes([10, 20, 30, 40, 50]);
        File(thumbPath).writeAsBytesSync(thumbData);

        // Use service without mock fileExistsSync to hit real filesystem
        final realService = ThumbnailService(memoryCache: ThumbnailCache());

        final result = await realService.loadThumbnail(
          photoPath: '/photos/test.jpg',
          thumbnailPath: thumbPath,
        );
        expect(result, equals(thumbData));
      });

      test('promotes disk-loaded thumbnail into memory cache', () async {
        final thumbPath = '${tempDir.path}/thumb2.jpg';
        final thumbData = _bytes([11, 22, 33]);
        File(thumbPath).writeAsBytesSync(thumbData);

        final sharedCache = ThumbnailCache();
        final realService = ThumbnailService(memoryCache: sharedCache);

        // First call loads from disk
        await realService.loadThumbnail(
          photoPath: '/photos/test.jpg',
          thumbnailPath: thumbPath,
        );

        // Should now be in memory cache
        expect(sharedCache.get('/photos/test.jpg'), equals(thumbData));

        // Second call should hit memory (even with bogus disk path)
        final result = await realService.loadThumbnail(
          photoPath: '/photos/test.jpg',
          thumbnailPath: '/nonexistent/path.jpg',
        );
        expect(result, equals(thumbData));
      });

      test('returns null when disk file does not exist', () async {
        final realService = ThumbnailService(memoryCache: ThumbnailCache());

        final result = await realService.loadThumbnail(
          photoPath: '/photos/test.jpg',
          thumbnailPath: '${tempDir.path}/nonexistent.jpg',
        );
        expect(result, isNull);
      });
    });
  });
}
