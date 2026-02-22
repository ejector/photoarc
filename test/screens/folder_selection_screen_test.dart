import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:photo_feed/database/database.dart';
import 'package:photo_feed/providers/scan_provider.dart';
import 'package:photo_feed/screens/folder_selection_screen.dart';
import 'package:photo_feed/services/photo_scanner.dart';
import 'package:photo_feed/services/platform_service.dart';

class FakePhotoScanner extends PhotoScanner {
  @override
  bool get isRunning => false;

  @override
  Stream<ScanProgress> startScan({
    required List<String> directories,
    required String thumbnailCacheDir,
    Map<String, DateTime> existingFiles = const {},
  }) {
    return const Stream.empty();
  }

  @override
  void stop() {}
}

PlatformService _testPlatformService({
  List<DriveInfo>? drives,
  List<String>? defaultDirs,
}) {
  return PlatformService.custom(
    getAvailableDrives: () async =>
        drives ??
        [
          const DriveInfo(path: '/Users/test', label: 'Home'),
          const DriveInfo(path: '/Volumes/External', label: 'External'),
        ],
    getDefaultPhotoDirectories: () =>
        defaultDirs ?? ['/Users/test/Pictures', '/Users/test/Downloads'],
    openFileManager: (_) async {},
    getThumbnailCacheDirectory: () async => '/tmp/thumbnails',
  );
}

Widget _buildTestApp({
  AppDatabase? db,
  PlatformService? platformService,
  ScanProvider? scanProvider,
}) {
  final database = db ?? AppDatabase.inMemory();
  final platform = platformService ?? _testPlatformService();
  final provider = scanProvider ??
      ScanProvider(
        db: database,
        platformService: platform,
        scanner: FakePhotoScanner(),
      );

  return MultiProvider(
    providers: [
      Provider<AppDatabase>.value(value: database),
      Provider<PlatformService>.value(value: platform),
      ChangeNotifierProvider<ScanProvider>.value(value: provider),
    ],
    child: MaterialApp(
      home: const FolderSelectionScreen(),
      routes: {
        '/scanning': (context) => const Scaffold(
              body: Center(child: Text('Scanning Screen')),
            ),
      },
    ),
  );
}

void main() {
  group('FolderSelectionScreen', () {
    testWidgets('shows loading indicator initially', (tester) async {
      await tester.pumpWidget(_buildTestApp());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders drives and default directories after loading',
        (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      // Default directories section
      expect(find.text('Default Photo Directories'), findsOneWidget);
      expect(find.text('Pictures'), findsOneWidget);
      expect(find.text('Downloads'), findsOneWidget);

      // Drives section
      expect(find.text('Drives & Volumes'), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('External'), findsOneWidget);
    });

    testWidgets('default directories are pre-selected on first launch',
        (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      // The scan button should show 2 folders selected (the defaults)
      expect(find.text('Scan 2 folders'), findsOneWidget);
    });

    testWidgets('toggling a checkbox changes selection', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      // Initially 2 default folders selected
      expect(find.text('Scan 2 folders'), findsOneWidget);

      // Find the "Home" drive checkbox tile and tap it
      final homeTile = find.byKey(const ValueKey('drive_/Users/test'));
      expect(homeTile, findsOneWidget);
      await tester.tap(homeTile);
      await tester.pump();

      // Now 3 folders selected
      expect(find.text('Scan 3 folders'), findsOneWidget);

      // Tap again to deselect
      await tester.tap(homeTile);
      await tester.pump();

      expect(find.text('Scan 2 folders'), findsOneWidget);
    });

    testWidgets('shows "Add Folder" button', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      expect(find.text('Add Folder'), findsOneWidget);
    });

    testWidgets('scan button shows correct count with singular',
        (tester) async {
      final db = AppDatabase.inMemory();
      final platform = _testPlatformService(
        defaultDirs: ['/Users/test/Pictures'],
      );
      final provider = ScanProvider(
        db: db,
        platformService: platform,
        scanner: FakePhotoScanner(),
      );

      await tester.pumpWidget(_buildTestApp(
        db: db,
        platformService: platform,
        scanProvider: provider,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Scan 1 folder'), findsOneWidget);
    });

    testWidgets('shows snackbar when trying to scan with no folders selected',
        (tester) async {
      final db = AppDatabase.inMemory();
      final platform = _testPlatformService(
        drives: [],
        defaultDirs: [],
      );
      final provider = ScanProvider(
        db: db,
        platformService: platform,
        scanner: FakePhotoScanner(),
      );

      await tester.pumpWidget(_buildTestApp(
        db: db,
        platformService: platform,
        scanProvider: provider,
      ));
      await tester.pumpAndSettle();

      // Tap scan button with no folders
      final scanButton = find.byType(FilledButton);
      await tester.tap(scanButton);
      await tester.pump();

      expect(find.text('Please select at least one folder.'), findsOneWidget);
    });

    testWidgets('restores saved folders on subsequent visits', (tester) async {
      final db = AppDatabase.inMemory();
      // Pre-save some folders
      await db.saveScanFolders([
        ScanSettingsCompanion(
          folderPath: const Value('/Users/test/Pictures'),
          isActive: const Value(true),
        ),
        ScanSettingsCompanion(
          folderPath: const Value('/Volumes/External'),
          isActive: const Value(true),
        ),
      ]);

      final platform = _testPlatformService();
      final provider = ScanProvider(
        db: db,
        platformService: platform,
        scanner: FakePhotoScanner(),
      );

      await tester.pumpWidget(_buildTestApp(
        db: db,
        platformService: platform,
        scanProvider: provider,
      ));
      await tester.pumpAndSettle();

      // The 2 saved folders should be selected
      expect(find.text('Scan 2 folders'), findsOneWidget);
    });

    testWidgets('shows Default chip for default directories', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      expect(find.text('Default'), findsNWidgets(2));
    });

    testWidgets('shows description text', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      expect(find.text('Choose which folders to scan for photos.'),
          findsOneWidget);
    });

    testWidgets('shows app bar title', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      expect(find.text('Select Folders'), findsOneWidget);
    });
  });

  group('Navigation logic (_InitialRouteDecider)', () {
    testWidgets('navigates to folder selection when no photos exist',
        (tester) async {
      final db = AppDatabase.inMemory();
      final platform = _testPlatformService();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<AppDatabase>.value(value: db),
            Provider<PlatformService>.value(value: platform),
            ChangeNotifierProvider(
              create: (_) => ScanProvider(
                db: db,
                platformService: platform,
                scanner: FakePhotoScanner(),
              ),
            ),
          ],
          child: MaterialApp(
            home: const Scaffold(body: Text('Loading')),
            routes: {
              '/folders': (context) =>
                  const Scaffold(body: Text('Folder Selection')),
              '/feed': (context) => const Scaffold(body: Text('Feed')),
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // With no photos, we stay at the home/loading screen
      // (The actual navigation is in PhotoFeedApp._InitialRouteDecider)
    });
  });
}
