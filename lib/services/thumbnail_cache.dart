import 'dart:collection';
import 'dart:typed_data';

/// In-memory LRU cache for thumbnail image bytes.
///
/// Stores [Uint8List] thumbnail data keyed by photo path.
/// Evicts least-recently-used entries when capacity is exceeded.
class ThumbnailCache {
  final int maxEntries;
  final LinkedHashMap<String, Uint8List> _cache = LinkedHashMap<String, Uint8List>();

  ThumbnailCache({this.maxEntries = 500});

  /// Returns the cached thumbnail bytes for [key], or null if not cached.
  /// Accessing an entry moves it to the most-recently-used position.
  Uint8List? get(String key) {
    final value = _cache.remove(key);
    if (value != null) {
      _cache[key] = value;
    }
    return value;
  }

  /// Stores [value] under [key]. If the cache exceeds [maxEntries],
  /// the least-recently-used entry is evicted.
  void put(String key, Uint8List value) {
    _cache.remove(key);
    _cache[key] = value;
    while (_cache.length > maxEntries) {
      _cache.remove(_cache.keys.first);
    }
  }

  /// Removes the entry for [key] if present. Returns true if removed.
  bool remove(String key) {
    return _cache.remove(key) != null;
  }

  /// Removes all entries from the cache.
  void clear() {
    _cache.clear();
  }

  /// Number of entries currently in the cache.
  int get length => _cache.length;

  /// Whether [key] is in the cache.
  bool containsKey(String key) => _cache.containsKey(key);

  /// Estimated total size in bytes of all cached thumbnails.
  int get totalSizeBytes {
    int total = 0;
    for (final value in _cache.values) {
      total += value.lengthInBytes;
    }
    return total;
  }
}
