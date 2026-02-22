import 'package:flutter/foundation.dart';

import '../database/database.dart';

/// Manages the photo feed: paginated loading, sorting, and year-month grouping.
class FeedProvider extends ChangeNotifier {
  final AppDatabase _db;

  static const int _pageSize = 200;
  static const String _sortSettingKey = 'feed_sort_newest_first';

  FeedProvider({required AppDatabase db}) : _db = db;

  // ── Photo list state ────────────────────────────────────────────────────

  List<Photo> _photos = [];
  List<Photo> get photos => List.unmodifiable(_photos);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _hasMore = true;
  bool get hasMore => _hasMore;

  int _totalPhotoCount = 0;
  int get totalPhotoCount => _totalPhotoCount;

  int _offset = 0;

  // ── Sort state ──────────────────────────────────────────────────────────

  bool _newestFirst = true;
  bool get newestFirst => _newestFirst;

  // ── Year-month groups ───────────────────────────────────────────────────

  List<String> _yearMonths = [];
  List<String> get yearMonths => List.unmodifiable(_yearMonths);

  /// Groups photos by yearMonth. Returns a map of yearMonth -> photos.
  Map<String, List<Photo>> get photosByYearMonth {
    final map = <String, List<Photo>>{};
    for (final photo in _photos) {
      map.putIfAbsent(photo.yearMonth, () => []).add(photo);
    }
    return map;
  }

  // ── Loading ─────────────────────────────────────────────────────────────

  /// Initializes the feed: loads sort preference, then loads first page.
  Future<void> initialize() async {
    await _loadSortPreference();
    await refresh();
  }

  /// Resets and reloads the feed from scratch.
  Future<void> refresh() async {
    _photos = [];
    _offset = 0;
    _hasMore = true;
    notifyListeners();
    _totalPhotoCount = await _db.getValidPhotoCount();
    await loadMore();
    await _loadYearMonths();
  }

  /// Loads the next page of photos.
  Future<void> loadMore() async {
    if (_isLoading || !_hasMore) return;

    _isLoading = true;
    notifyListeners();

    final page = await _db.getPhotosPaginated(
      limit: _pageSize,
      offset: _offset,
      newestFirst: _newestFirst,
    );

    _photos.addAll(page);
    _offset += page.length;
    _hasMore = page.length == _pageSize;
    _isLoading = false;
    notifyListeners();
  }

  /// Toggles sort order and reloads the feed.
  Future<void> toggleSortOrder() async {
    _newestFirst = !_newestFirst;
    await _saveSortPreference();
    await refresh();
  }

  // ── Year-month helpers ──────────────────────────────────────────────────

  Future<void> _loadYearMonths() async {
    _yearMonths =
        await _db.getDistinctYearMonths(newestFirst: _newestFirst);
    notifyListeners();
  }

  // ── Sort preference persistence ─────────────────────────────────────────

  Future<void> _loadSortPreference() async {
    final value = await _db.getSetting(_sortSettingKey);
    if (value != null) {
      _newestFirst = value == 'true';
    }
  }

  Future<void> _saveSortPreference() async {
    await _db.setSetting(_sortSettingKey, _newestFirst.toString());
  }
}
