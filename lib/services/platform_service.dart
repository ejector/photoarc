import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Represents a drive or volume on the system.
class DriveInfo {
  final String path;
  final String label;

  const DriveInfo({required this.path, required this.label});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DriveInfo &&
          runtimeType == other.runtimeType &&
          path == other.path &&
          label == other.label;

  @override
  int get hashCode => path.hashCode ^ label.hashCode;

  @override
  String toString() => 'DriveInfo(path: $path, label: $label)';
}

/// Platform-agnostic service for OS-specific file system operations.
///
/// Uses constructor injection for testability - all platform-dependent
/// operations can be overridden via the factory constructors or by
/// subclassing for tests.
class PlatformService {
  final Future<List<DriveInfo>> Function() _getAvailableDrives;
  final List<String> Function() _getDefaultPhotoDirectories;
  final Future<void> Function(String path) _openFileManager;
  final Future<String> Function() _getThumbnailCacheDirectory;

  PlatformService._({
    required Future<List<DriveInfo>> Function() getAvailableDrives,
    required List<String> Function() getDefaultPhotoDirectories,
    required Future<void> Function(String path) openFileManager,
    required Future<String> Function() getThumbnailCacheDirectory,
  })  : _getAvailableDrives = getAvailableDrives,
        _getDefaultPhotoDirectories = getDefaultPhotoDirectories,
        _openFileManager = openFileManager,
        _getThumbnailCacheDirectory = getThumbnailCacheDirectory;

  /// Creates a PlatformService configured for the current platform.
  factory PlatformService() {
    if (Platform.isMacOS) {
      return PlatformService._forMacOS();
    } else if (Platform.isWindows) {
      return PlatformService._forWindows();
    } else if (Platform.isLinux) {
      return PlatformService._forLinux();
    } else {
      throw UnsupportedError(
          'PlatformService is not supported on ${Platform.operatingSystem}');
    }
  }

  /// Creates a PlatformService with custom implementations (for testing).
  factory PlatformService.custom({
    required Future<List<DriveInfo>> Function() getAvailableDrives,
    required List<String> Function() getDefaultPhotoDirectories,
    required Future<void> Function(String path) openFileManager,
    required Future<String> Function() getThumbnailCacheDirectory,
  }) {
    return PlatformService._(
      getAvailableDrives: getAvailableDrives,
      getDefaultPhotoDirectories: getDefaultPhotoDirectories,
      openFileManager: openFileManager,
      getThumbnailCacheDirectory: getThumbnailCacheDirectory,
    );
  }

  factory PlatformService._forMacOS() {
    return PlatformService._(
      getAvailableDrives: _macOSGetAvailableDrives,
      getDefaultPhotoDirectories: _macOSGetDefaultPhotoDirectories,
      openFileManager: _macOSOpenFileManager,
      getThumbnailCacheDirectory: _getDefaultThumbnailCacheDirectory,
    );
  }

  factory PlatformService._forWindows() {
    return PlatformService._(
      getAvailableDrives: _windowsGetAvailableDrives,
      getDefaultPhotoDirectories: _windowsGetDefaultPhotoDirectories,
      openFileManager: _windowsOpenFileManager,
      getThumbnailCacheDirectory: _getDefaultThumbnailCacheDirectory,
    );
  }

  factory PlatformService._forLinux() {
    return PlatformService._(
      getAvailableDrives: _linuxGetAvailableDrives,
      getDefaultPhotoDirectories: _linuxGetDefaultPhotoDirectories,
      openFileManager: _linuxOpenFileManager,
      getThumbnailCacheDirectory: _getDefaultThumbnailCacheDirectory,
    );
  }

  /// Returns a list of available drives/volumes on the system.
  Future<List<DriveInfo>> getAvailableDrives() => _getAvailableDrives();

  /// Returns default photo directories (Pictures, Downloads) for the platform.
  List<String> getDefaultPhotoDirectories() => _getDefaultPhotoDirectories();

  /// Opens the native file manager and reveals the file at [path].
  Future<void> openFileManager(String path) => _openFileManager(path);

  /// Returns the directory path for storing thumbnail cache files.
  Future<String> getThumbnailCacheDirectory() =>
      _getThumbnailCacheDirectory();

  // -- macOS implementations --

  static Future<List<DriveInfo>> _macOSGetAvailableDrives() async {
    final drives = <DriveInfo>[];
    final home = Platform.environment['HOME'];
    if (home != null) {
      drives.add(DriveInfo(path: home, label: 'Home'));
    }

    final volumesDir = Directory('/Volumes');
    if (await volumesDir.exists()) {
      await for (final entity in volumesDir.list()) {
        if (entity is Directory) {
          final label = p.basename(entity.path);
          drives.add(DriveInfo(path: entity.path, label: label));
        }
      }
    }
    return drives;
  }

  static List<String> _macOSGetDefaultPhotoDirectories() {
    final home = Platform.environment['HOME'] ?? '/Users/unknown';
    return [
      p.join(home, 'Pictures'),
      p.join(home, 'Downloads'),
    ];
  }

  static Future<void> _macOSOpenFileManager(String path) async {
    await Process.run('open', ['-R', path]);
  }

  // -- Windows implementations --

  static Future<List<DriveInfo>> _windowsGetAvailableDrives() async {
    final drives = <DriveInfo>[];
    // Check common drive letters A-Z
    for (var i = 65; i <= 90; i++) {
      final letter = String.fromCharCode(i);
      final drivePath = '$letter:\\';
      if (await Directory(drivePath).exists()) {
        drives.add(DriveInfo(path: drivePath, label: '$letter:'));
      }
    }
    return drives;
  }

  static List<String> _windowsGetDefaultPhotoDirectories() {
    final userProfile = Platform.environment['USERPROFILE'] ??
        'C:\\Users\\${Platform.environment['USERNAME'] ?? 'unknown'}';
    return [
      p.join(userProfile, 'Pictures'),
      p.join(userProfile, 'Downloads'),
    ];
  }

  static Future<void> _windowsOpenFileManager(String path) async {
    await Process.run('explorer.exe', ['/select,', path]);
  }

  // -- Linux implementations --

  static Future<List<DriveInfo>> _linuxGetAvailableDrives() async {
    final drives = <DriveInfo>[];
    final home = Platform.environment['HOME'];
    if (home != null) {
      drives.add(DriveInfo(path: home, label: 'Home'));
    }

    // Check common mount points
    final mountDirs = ['/media', '/mnt'];
    for (final mountDir in mountDirs) {
      final dir = Directory(mountDir);
      if (await dir.exists()) {
        await for (final entity in dir.list()) {
          if (entity is Directory) {
            // /media often has a user subdirectory
            if (mountDir == '/media') {
              await for (final subEntity in entity.list()) {
                if (subEntity is Directory) {
                  drives.add(DriveInfo(
                    path: subEntity.path,
                    label: p.basename(subEntity.path),
                  ));
                }
              }
            } else {
              drives.add(DriveInfo(
                path: entity.path,
                label: p.basename(entity.path),
              ));
            }
          }
        }
      }
    }
    return drives;
  }

  static List<String> _linuxGetDefaultPhotoDirectories() {
    final home = Platform.environment['HOME'] ?? '/home/unknown';
    return [
      p.join(home, 'Pictures'),
      p.join(home, 'Downloads'),
    ];
  }

  static Future<void> _linuxOpenFileManager(String path) async {
    final directory = File(path).parent.path;
    await Process.run('xdg-open', [directory]);
  }

  // -- Shared implementations --

  static Future<String> _getDefaultThumbnailCacheDirectory() async {
    final cacheDir = await getApplicationCacheDirectory();
    final thumbnailDir = Directory(p.join(cacheDir.path, 'thumbnails'));
    if (!await thumbnailDir.exists()) {
      await thumbnailDir.create(recursive: true);
    }
    return thumbnailDir.path;
  }
}
