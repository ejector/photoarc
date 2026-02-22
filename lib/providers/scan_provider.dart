import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import '../database/database.dart';
import '../services/photo_scanner.dart';
import '../services/platform_service.dart';

/// Manages scan folder selection, scan lifecycle, and progress reporting.
class ScanProvider extends ChangeNotifier {
  final AppDatabase _db;
  final PlatformService _platformService;
  final PhotoScanner _scanner;

  ScanProvider({
    required AppDatabase db,
    required PlatformService platformService,
    PhotoScanner? scanner,
  })  : _db = db,
        _platformService = platformService,
        _scanner = scanner ?? PhotoScanner();

  // ── Folder selection state ──────────────────────────────────────────────

  List<String> _selectedFolders = [];
  List<String> get selectedFolders => List.unmodifiable(_selectedFolders);

  void setSelectedFolders(List<String> folders) {
    _selectedFolders = List.of(folders);
    notifyListeners();
  }

  void addFolder(String path) {
    if (!_selectedFolders.contains(path)) {
      _selectedFolders.add(path);
      notifyListeners();
    }
  }

  void removeFolder(String path) {
    if (_selectedFolders.remove(path)) {
      notifyListeners();
    }
  }

  void toggleFolder(String path) {
    if (_selectedFolders.contains(path)) {
      _selectedFolders.remove(path);
    } else {
      _selectedFolders.add(path);
    }
    notifyListeners();
  }

  /// Persists the current folder selection to the database.
  Future<void> saveFolders() async {
    final companions = _selectedFolders
        .map((path) => ScanSettingsCompanion(
              folderPath: Value(path),
              isActive: const Value(true),
            ))
        .toList();
    await _db.saveScanFolders(companions);
  }

  /// Loads saved folder selections from the database.
  Future<void> loadFolders() async {
    final settings = await _db.loadScanFolders();
    _selectedFolders =
        settings.where((s) => s.isActive).map((s) => s.folderPath).toList();
    notifyListeners();
  }

  // ── Scan state ──────────────────────────────────────────────────────────

  bool _isScanning = false;
  bool get isScanning => _isScanning;

  int _photosFound = 0;
  int get photosFound => _photosFound;

  String _currentDirectory = '';
  String get currentDirectory => _currentDirectory;

  bool _scanComplete = false;
  bool get scanComplete => _scanComplete;

  int _totalPhotos = 0;
  int get totalPhotos => _totalPhotos;

  StreamSubscription<ScanProgress>? _scanSubscription;

  /// Starts a scan of the selected folders.
  Future<void> startScan() async {
    if (_isScanning || _selectedFolders.isEmpty) return;

    _isScanning = true;
    _photosFound = 0;
    _currentDirectory = '';
    _scanComplete = false;
    _totalPhotos = 0;
    notifyListeners();

    await saveFolders();

    final thumbnailCacheDir =
        await _platformService.getThumbnailCacheDirectory();

    final stream = _scanner.startScan(
      directories: _selectedFolders,
      thumbnailCacheDir: thumbnailCacheDir,
    );

    _scanSubscription = stream.listen(
      _handleProgress,
      onError: (error) {
        _isScanning = false;
        notifyListeners();
      },
      onDone: () {
        _isScanning = false;
        notifyListeners();
      },
    );
  }

  void _handleProgress(ScanProgress progress) {
    switch (progress) {
      case PhotosFoundProgress(:final count):
        _photosFound = count;
        notifyListeners();
      case CurrentDirectoryProgress(:final directory):
        _currentDirectory = directory;
        notifyListeners();
      case BatchReadyProgress(:final photos):
        _insertBatch(photos).catchError((error) {
          debugPrint('Failed to insert photo batch: $error');
        });
      case ScanCompleteProgress(:final totalPhotos):
        _totalPhotos = totalPhotos;
        _scanComplete = true;
        _isScanning = false;
        notifyListeners();
      case ScanErrorProgress():
        break; // Non-fatal errors are ignored for now
    }
  }

  Future<void> _insertBatch(List<ScannedPhoto> photos) async {
    final companions = photos
        .map((p) => PhotosCompanion(
              path: Value(p.path),
              filename: Value(p.filename),
              directory: Value(p.directory),
              dateTaken: Value(p.dateTaken),
              fileSize: Value(p.fileSize),
              format: Value(p.format),
              width: Value(p.width),
              height: Value(p.height),
              thumbnailPath: Value(p.thumbnailPath),
              yearMonth: Value(p.yearMonth),
              orientation: Value(p.orientation),
              fileModifiedAt: Value(p.fileModifiedAt),
            ))
        .toList();
    await _db.insertPhotoBatch(companions);
  }

  /// Stops the currently running scan.
  void stopScan() {
    _scanner.stop();
    _scanSubscription?.cancel();
    _scanSubscription = null;
    _isScanning = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    super.dispose();
  }
}
