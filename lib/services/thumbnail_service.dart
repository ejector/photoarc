import 'dart:io';
import 'dart:typed_data';

import 'thumbnail_cache.dart';

/// Two-tier thumbnail caching service.
///
/// Tier 1: In-memory LRU cache for currently visible tiles.
/// Tier 2: Disk cache - thumbnails stored as files referenced by [thumbnailPath].
///
/// The [getThumbnail] method checks memory first, then disk, and returns null
/// if the thumbnail is unavailable (caller should trigger regeneration).
class ThumbnailService {
  final ThumbnailCache _memoryCache;
  final bool Function(String path)? _fileExistsSync;

  ThumbnailService({
    ThumbnailCache? memoryCache,
    bool Function(String path)? fileExistsSync,
  })  : _memoryCache = memoryCache ?? ThumbnailCache(),
        _fileExistsSync = fileExistsSync;

  /// Returns thumbnail bytes for a photo, checking memory then disk.
  ///
  /// - [photoPath]: The original photo file path (used as cache key).
  /// - [thumbnailPath]: The on-disk thumbnail file path (from database).
  ///
  /// Returns null if the thumbnail is not available in either tier.
  Uint8List? getThumbnail({
    required String photoPath,
    required String? thumbnailPath,
  }) {
    // Tier 1: Check memory cache
    final cached = _memoryCache.get(photoPath);
    if (cached != null) {
      return cached;
    }

    // Tier 2: Check disk cache
    if (thumbnailPath != null && thumbnailPath.isNotEmpty) {
      final exists = _fileExistsSync != null
          ? _fileExistsSync(thumbnailPath)
          : File(thumbnailPath).existsSync();

      if (exists) {
        final bytes = File(thumbnailPath).readAsBytesSync();
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
