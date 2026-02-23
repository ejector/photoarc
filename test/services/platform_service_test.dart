import 'package:flutter_test/flutter_test.dart';
import 'package:photoarc/services/platform_service.dart';

void main() {
  group('DriveInfo', () {
    test('equality works for same path and label', () {
      const a = DriveInfo(path: '/Volumes/USB', label: 'USB');
      const b = DriveInfo(path: '/Volumes/USB', label: 'USB');
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('inequality for different path', () {
      const a = DriveInfo(path: '/Volumes/USB', label: 'USB');
      const b = DriveInfo(path: '/Volumes/HDD', label: 'USB');
      expect(a, isNot(equals(b)));
    });

    test('inequality for different label', () {
      const a = DriveInfo(path: '/Volumes/USB', label: 'USB');
      const b = DriveInfo(path: '/Volumes/USB', label: 'Flash Drive');
      expect(a, isNot(equals(b)));
    });

    test('toString returns readable representation', () {
      const drive = DriveInfo(path: '/home', label: 'Home');
      expect(drive.toString(), 'DriveInfo(path: /home, label: Home)');
    });
  });

  group('PlatformService.custom', () {
    test('getAvailableDrives delegates to provided function', () async {
      final expectedDrives = [
        const DriveInfo(path: '/home/user', label: 'Home'),
        const DriveInfo(path: '/Volumes/External', label: 'External'),
      ];

      final service = PlatformService.custom(
        getAvailableDrives: () async => expectedDrives,
        getDefaultPhotoDirectories: () => [],
        openFileManager: (_) async {},
        getThumbnailCacheDirectory: () async => '/tmp/cache',
      );

      final drives = await service.getAvailableDrives();
      expect(drives, equals(expectedDrives));
      expect(drives.length, 2);
      expect(drives[0].label, 'Home');
      expect(drives[1].path, '/Volumes/External');
    });

    test('getAvailableDrives returns empty list when no drives', () async {
      final service = PlatformService.custom(
        getAvailableDrives: () async => [],
        getDefaultPhotoDirectories: () => [],
        openFileManager: (_) async {},
        getThumbnailCacheDirectory: () async => '/tmp/cache',
      );

      final drives = await service.getAvailableDrives();
      expect(drives, isEmpty);
    });

    test('getDefaultPhotoDirectories returns configured paths', () {
      final service = PlatformService.custom(
        getAvailableDrives: () async => [],
        getDefaultPhotoDirectories: () => [
          '/home/user/Pictures',
          '/home/user/Downloads',
        ],
        openFileManager: (_) async {},
        getThumbnailCacheDirectory: () async => '/tmp/cache',
      );

      final dirs = service.getDefaultPhotoDirectories();
      expect(dirs, hasLength(2));
      expect(dirs[0], contains('Pictures'));
      expect(dirs[1], contains('Downloads'));
    });

    test('getDefaultPhotoDirectories returns empty list when none configured',
        () {
      final service = PlatformService.custom(
        getAvailableDrives: () async => [],
        getDefaultPhotoDirectories: () => [],
        openFileManager: (_) async {},
        getThumbnailCacheDirectory: () async => '/tmp/cache',
      );

      expect(service.getDefaultPhotoDirectories(), isEmpty);
    });

    test('openFileManager calls provided function with correct path', () async {
      String? capturedPath;

      final service = PlatformService.custom(
        getAvailableDrives: () async => [],
        getDefaultPhotoDirectories: () => [],
        openFileManager: (path) async {
          capturedPath = path;
        },
        getThumbnailCacheDirectory: () async => '/tmp/cache',
      );

      await service.openFileManager('/home/user/Photos/image.jpg');
      expect(capturedPath, '/home/user/Photos/image.jpg');
    });

    test('openFileManager propagates errors', () async {
      final service = PlatformService.custom(
        getAvailableDrives: () async => [],
        getDefaultPhotoDirectories: () => [],
        openFileManager: (_) async {
          throw Exception('File manager not found');
        },
        getThumbnailCacheDirectory: () async => '/tmp/cache',
      );

      expect(
        () => service.openFileManager('/some/path'),
        throwsException,
      );
    });

    test('getThumbnailCacheDirectory returns configured path', () async {
      final service = PlatformService.custom(
        getAvailableDrives: () async => [],
        getDefaultPhotoDirectories: () => [],
        openFileManager: (_) async {},
        getThumbnailCacheDirectory: () async =>
            '/home/user/.cache/photoarc/thumbnails',
      );

      final cacheDir = await service.getThumbnailCacheDirectory();
      expect(cacheDir, '/home/user/.cache/photoarc/thumbnails');
      expect(cacheDir, contains('thumbnails'));
    });

    test('multiple calls to getAvailableDrives return fresh results', () async {
      var callCount = 0;

      final service = PlatformService.custom(
        getAvailableDrives: () async {
          callCount++;
          return List.generate(
            callCount,
            (i) => DriveInfo(path: '/drive$i', label: 'Drive $i'),
          );
        },
        getDefaultPhotoDirectories: () => [],
        openFileManager: (_) async {},
        getThumbnailCacheDirectory: () async => '/tmp/cache',
      );

      final first = await service.getAvailableDrives();
      expect(first, hasLength(1));

      final second = await service.getAvailableDrives();
      expect(second, hasLength(2));
    });
  });

  group('PlatformService real (macOS)', () {
    // These tests run the actual macOS implementations on CI/dev machines.
    // They are skipped on non-macOS platforms.
    test('getAvailableDrives returns at least home directory', () async {
      final service = PlatformService();
      final drives = await service.getAvailableDrives();

      expect(drives, isNotEmpty);
      // On macOS, we should always have Home
      expect(
        drives.any((d) => d.label == 'Home'),
        isTrue,
        reason: 'Should include Home directory',
      );
    }, testOn: 'mac-os');

    test('getDefaultPhotoDirectories returns Pictures and Downloads', () {
      final service = PlatformService();
      final dirs = service.getDefaultPhotoDirectories();

      expect(dirs, hasLength(2));
      expect(dirs[0], contains('Pictures'));
      expect(dirs[1], contains('Downloads'));
    }, testOn: 'mac-os');
  });
}
