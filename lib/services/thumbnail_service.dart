import 'dart:io';
import 'dart:typed_data';

import 'thumbnail_cache.dart';

/// Two-tier thumbnail caching service.
///
/// Tier 1: In-memory LRU cache for currently visible tiles.
/// Tier 2: Disk cache - thumbnails stored as files referenced by [thumbnailPath].
///
/// The [loadThumbnail] method checks memory first, then disk asynchronously,
/// and returns null if the thumbnail is unavailable.
class ThumbnailService {
  final ThumbnailCache _memoryCache;
  final bool Function(String path)? _fileExistsSync;

  ThumbnailService({
    ThumbnailCache? memoryCache,
    bool Function(String path)? fileExistsSync,
  })  : _memoryCache = memoryCache ?? ThumbnailCache(),
        _fileExistsSync = fileExistsSync;

  /// Returns thumbnail bytes from the memory cache (synchronous, non-blocking).
  ///
  /// Returns null if the thumbnail is not in the memory cache.
  /// Use [loadThumbnail] to trigger an async disk load on cache miss.
  Uint8List? getFromMemory(String photoPath) {
    return _memoryCache.get(photoPath);
  }

  /// Loads a thumbnail asynchronously, checking memory then disk.
  ///
  /// Returns cached bytes immediately if in memory, otherwise reads from disk
  /// without blocking the UI thread.
  Future<Uint8List?> loadThumbnail({
    required String photoPath,
    required String? thumbnailPath,
  }) async {
    // Tier 1: Check memory cache
    final cached = _memoryCache.get(photoPath);
    if (cached != null) {
      return cached;
    }

    // Tier 2: Check disk cache (async to avoid blocking UI)
    if (thumbnailPath != null && thumbnailPath.isNotEmpty) {
      final exists = _fileExistsSync != null
          ? _fileExistsSync(thumbnailPath)
          : File(thumbnailPath).existsSync();

      if (exists) {
        final bytes = await File(thumbnailPath).readAsBytes();
        _memoryCache.put(photoPath, bytes);
        return bytes;
      }
    }

    return null;
  }

  /// Stores thumbnail bytes directly into the memory cache.
  void putInMemory(String photoPath, Uint8List bytes) {
    _memoryCache.put(photoPath, bytes);
  }

  /// Evicts a specific photo's thumbnail from the memory cache.
  void evictFromMemory(String photoPath) {
    _memoryCache.remove(photoPath);
  }

  /// Clears the entire memory cache.
  void clearMemoryCache() {
    _memoryCache.clear();
  }

  /// Number of entries in the memory cache.
  int get memoryCacheSize => _memoryCache.length;

  /// Estimated memory usage of the in-memory cache in bytes.
  int get memoryCacheSizeBytes => _memoryCache.totalSizeBytes;
}
