import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:photo_feed/database/database.dart';
import 'package:photo_feed/providers/feed_provider.dart';
import 'package:photo_feed/providers/scan_provider.dart';
import 'package:photo_feed/screens/scanning_screen.dart';
import 'package:photo_feed/services/photo_scanner.dart';
import 'package:photo_feed/services/platform_service.dart';

class FakePhotoScanner extends PhotoScanner {
  final StreamController<ScanProgress> _controller =
      StreamController<ScanProgress>.broadcast();

  @override
  bool get isRunning => false;

  @override
  Stream<ScanProgress> startScan({
    required List<String> directories,
    required String thumbnailCacheDir,
    Map<String, DateTime> existingFiles = const {},
  }) {
    return _controller.stream;
  }

  @override
  void stop() {}

  void emitProgress(ScanProgress progress) {
    _controller.add(progress);
  }

  void complete() {
    _controller.close();
  }
}

PlatformService _testPlatformService() {
  return PlatformService.custom(
    getAvailableDrives: () async => [
      const DriveInfo(path: '/Users/test', label: 'Home'),
    ],
    getDefaultPhotoDirectories: () => ['/Users/test/Pictures'],
    openFileManager: (_) async {},
    getThumbnailCacheDirectory: () async => '/tmp/thumbnails',
  );
}

Widget _buildTestApp({
  required ScanProvider scanProvider,
  FeedProvider? feedProvider,
  AppDatabase? db,
}) {
  final database = db ?? AppDatabase.inMemory();
  final feed = feedProvider ?? FeedProvider(db: database);

  return MultiProvider(
    providers: [
      Provider<AppDatabase>.value(value: database),
      Provider<PlatformService>.value(value: _testPlatformService()),
      ChangeNotifierProvider<ScanProvider>.value(value: scanProvider),
      ChangeNotifierProvider<FeedProvider>.value(value: feed),
    ],
    child: MaterialApp(
      home: const ScanningScreen(),
      routes: {
        '/feed': (context) => const Scaffold(body: Text('Feed Screen')),
      },
    ),
  );
}

void main() {
  group('ScanningScreen', () {
    testWidgets('shows scanning title', (tester) async {
      final db = AppDatabase.inMemory();
      final scanner = FakePhotoScanner();
      final provider = ScanProvider(
        db: db,
        platformService: _testPlatformService(),
        scanner: scanner,
      );

      await tester.pumpWidget(_buildTestApp(
        scanProvider: provider,
        db: db,
      ));

      expect(find.text('Scanning for photos...'), findsOneWidget);
    });

    testWidgets('shows animated progress bar', (tester) async {
      final db = AppDatabase.inMemory();
      final scanner = FakePhotoScanner();
      final provider = ScanProvider(
        db: db,
        platformService: _testPlatformService(),
        scanner: scanner,
      );

      await tester.pumpWidget(_buildTestApp(
        scanProvider: provider,
        db: db,
      ));

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('shows initial photo count of 0', (tester) async {
      final db = AppDatabase.inMemory();
      final scanner = FakePhotoScanner();
      final provider = ScanProvider(
        db: db,
        platformService: _testPlatformService(),
        scanner: scanner,
      );

      await tester.pumpWidget(_buildTestApp(
        scanProvider: provider,
        db: db,
      ));

      expect(find.text('0 photos found'), findsOneWidget);
    });

    testWidgets('shows "Preparing..." when no directory is set',
        (tester) async {
      final db = AppDatabase.inMemory();
      final scanner = FakePhotoScanner();
      final provider = ScanProvider(
        db: db,
        platformService: _testPlatformService(),
        scanner: scanner,
      );

      await tester.pumpWidget(_buildTestApp(
        scanProvider: provider,
        db: db,
      ));

      expect(find.text('Preparing...'), findsOneWidget);
    });

    testWidgets('shows cancel button', (tester) async {
      final db = AppDatabase.inMemory();
      final scanner = FakePhotoScanner();
      final provider = ScanProvider(
        db: db,
        platformService: _testPlatformService(),
        scanner: scanner,
      );

      await tester.pumpWidget(_buildTestApp(
        scanProvider: provider,
        db: db,
      ));

      expect(find.text('Cancel'), findsOneWidget);
      expect(find.byType(OutlinedButton), findsOneWidget);
    });

    testWidgets('displays updated photo count from provider', (tester) async {
      final db = AppDatabase.inMemory();
      final scanner = FakePhotoScanner();
      final provider = ScanProvider(
        db: db,
        platformService: _testPlatformService(),
        scanner: scanner,
      );

      // Start scan to set isScanning state
      provider.setSelectedFolders(['/Users/test/Pictures']);
      await provider.startScan();

      await tester.pumpWidget(_buildTestApp(
        scanProvider: provider,
        db: db,
      ));

      // Emit progress with photos found
      scanner.emitProgress(PhotosFoundProgress(42));
      await tester.pump();

      expect(find.text('42 photos found'), findsOneWidget);
    });

    testWidgets('displays current directory from provider', (tester) async {
      final db = AppDatabase.inMemory();
      final scanner = FakePhotoScanner();
      final provider = ScanProvider(
        db: db,
        platformService: _testPlatformService(),
        scanner: scanner,
      );

      provider.setSelectedFolders(['/Users/test/Pictures']);
      await provider.startScan();

      await tester.pumpWidget(_buildTestApp(
        scanProvider: provider,
        db: db,
      ));

      scanner.emitProgress(
        CurrentDirectoryProgress('/Users/test/Pictures/Vacation'),
      );
      await tester.pump();

      expect(find.text('/Users/test/Pictures/Vacation'), findsOneWidget);
    });

    testWidgets('cancel button stops scan and navigates to feed',
        (tester) async {
      final db = AppDatabase.inMemory();
      final scanner = FakePhotoScanner();
      final provider = ScanProvider(
        db: db,
        platformService: _testPlatformService(),
        scanner: scanner,
      );

      await tester.pumpWidget(_buildTestApp(
        scanProvider: provider,
        db: db,
      ));

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Should navigate to feed screen
      expect(find.text('Feed Screen'), findsOneWidget);
    });

    testWidgets('auto-navigates to feed on scan completion', (tester) async {
      final db = AppDatabase.inMemory();
      final scanner = FakePhotoScanner();
      final provider = ScanProvider(
        db: db,
        platformService: _testPlatformService(),
        scanner: scanner,
      );

      provider.setSelectedFolders(['/Users/test/Pictures']);
      await provider.startScan();

      await tester.pumpWidget(_buildTestApp(
        scanProvider: provider,
        db: db,
      ));

      // Emit scan complete
      scanner.emitProgress(ScanCompleteProgress(10));
      await tester.pumpAndSettle();

      // Should auto-navigate to feed
      expect(find.text('Feed Screen'), findsOneWidget);
    });

    testWidgets('shows photo library icon', (tester) async {
      final db = AppDatabase.inMemory();
      final scanner = FakePhotoScanner();
      final provider = ScanProvider(
        db: db,
        platformService: _testPlatformService(),
        scanner: scanner,
      );

      await tester.pumpWidget(_buildTestApp(
        scanProvider: provider,
        db: db,
      ));

      expect(find.byIcon(Icons.photo_library_outlined), findsOneWidget);
    });
  });
}
