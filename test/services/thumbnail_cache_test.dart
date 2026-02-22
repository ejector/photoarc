import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:photo_feed/services/thumbnail_cache.dart';

Uint8List _bytes(int length) => Uint8List(length);

void main() {
  group('ThumbnailCache', () {
    late ThumbnailCache cache;

    setUp(() {
      cache = ThumbnailCache(maxEntries: 3);
    });

    test('returns null for missing key', () {
      expect(cache.get('missing'), isNull);
    });

    test('stores and retrieves a value', () {
      final data = _bytes(10);
      cache.put('photo1', data);
      expect(cache.get('photo1'), equals(data));
    });

    test('length reflects number of entries', () {
      expect(cache.length, 0);
      cache.put('a', _bytes(1));
      expect(cache.length, 1);
      cache.put('b', _bytes(1));
      expect(cache.length, 2);
    });

    test('containsKey works correctly', () {
      cache.put('a', _bytes(1));
      expect(cache.containsKey('a'), isTrue);
      expect(cache.containsKey('b'), isFalse);
    });

    test('evicts least-recently-used entry when capacity exceeded', () {
      cache.put('a', _bytes(1));
      cache.put('b', _bytes(1));
      cache.put('c', _bytes(1));
      // Cache is full (3 entries). Adding one more should evict 'a'.
      cache.put('d', _bytes(1));

      expect(cache.length, 3);
      expect(cache.get('a'), isNull);
      expect(cache.get('b'), isNotNull);
      expect(cache.get('c'), isNotNull);
      expect(cache.get('d'), isNotNull);
    });

    test('accessing an entry promotes it to most-recently-used', () {
      cache.put('a', _bytes(1));
      cache.put('b', _bytes(1));
      cache.put('c', _bytes(1));
      // Access 'a' to promote it
      cache.get('a');
      // Now 'b' is the LRU entry
      cache.put('d', _bytes(1));

      expect(cache.get('b'), isNull);
      expect(cache.get('a'), isNotNull);
      expect(cache.get('c'), isNotNull);
      expect(cache.get('d'), isNotNull);
    });

    test('updating an existing key does not increase size', () {
      cache.put('a', _bytes(1));
      cache.put('b', _bytes(1));
      cache.put('a', _bytes(2));

      expect(cache.length, 2);
      expect(cache.get('a')!.lengthInBytes, 2);
    });

    test('remove returns true when key exists', () {
      cache.put('a', _bytes(1));
      expect(cache.remove('a'), isTrue);
      expect(cache.get('a'), isNull);
      expect(cache.length, 0);
    });

    test('remove returns false when key does not exist', () {
      expect(cache.remove('nonexistent'), isFalse);
    });

    test('clear removes all entries', () {
      cache.put('a', _bytes(1));
      cache.put('b', _bytes(1));
      cache.clear();
      expect(cache.length, 0);
      expect(cache.get('a'), isNull);
    });

    test('totalSizeBytes sums all cached bytes', () {
      cache.put('a', _bytes(100));
      cache.put('b', _bytes(200));
      expect(cache.totalSizeBytes, 300);
    });

    test('default maxEntries is 500', () {
      final defaultCache = ThumbnailCache();
      expect(defaultCache.maxEntries, 500);
    });

    test('evicts multiple entries if many added at once below capacity', () {
      // Cache with capacity 2
      final smallCache = ThumbnailCache(maxEntries: 2);
      smallCache.put('a', _bytes(1));
      smallCache.put('b', _bytes(1));
      smallCache.put('c', _bytes(1));
      smallCache.put('d', _bytes(1));

      expect(smallCache.length, 2);
      expect(smallCache.get('a'), isNull);
      expect(smallCache.get('b'), isNull);
      expect(smallCache.get('c'), isNotNull);
      expect(smallCache.get('d'), isNotNull);
    });
  });
}
