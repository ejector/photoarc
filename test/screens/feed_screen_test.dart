import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:photoarc/database/database.dart';
import 'package:photoarc/providers/feed_provider.dart';
import 'package:photoarc/providers/scan_provider.dart';
import 'package:photoarc/screens/feed_screen.dart';
import 'package:photoarc/services/photo_scanner.dart';
import 'package:photoarc/services/platform_service.dart';

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

Future<void> _insertTestPhotos(AppDatabase db, int count,
    {String yearMonth = '2024-06'}) async {
  final companions = List.generate(
    count,
    (i) => PhotosCompanion(
      path: Value('/photos/photo_${yearMonth}_$i.jpg'),
      filename: Value('photo_${yearMonth}_$i.jpg'),
      directory: Value('/photos'),
      dateTaken: Value(DateTime(2024, 6, 15, 10, i)),
      fileSize: Value(1024 * (i + 1)),
      format: Value('jpg'),
      yearMonth: Value(yearMonth),
      orientation: const Value(1),
      fileModifiedAt: Value(DateTime(2024, 6, 15)),
    ),
  );
  await db.insertPhotoBatch(companions);
}

Widget _buildTestApp({
  required AppDatabase db,
  FeedProvider? feedProvider,
}) {
  final platform = _testPlatformService();
  final scanner = FakePhotoScanner();
  final feed = feedProvider ?? FeedProvider(db: db);
  final scan = ScanProvider(
    db: db,
    platformService: platform,
    scanner: scanner,
  );

  return MultiProvider(
    providers: [
      Provider<AppDatabase>.value(value: db),
      Provider<PlatformService>.value(value: platform),
      ChangeNotifierProvider<ScanProvider>.value(value: scan),
      ChangeNotifierProvider<FeedProvider>.value(value: feed),
    ],
    child: MaterialApp(
      home: const FeedScreen(),
      routes: {
        '/folders': (context) =>
            const Scaffold(body: Text('Folder Selection')),
      },
    ),
  );
}

void main() {
  group('FeedScreen', () {
    testWidgets('shows empty state when no photos', (tester) async {
      final db = AppDatabase.inMemory();

      await tester.pumpWidget(_buildTestApp(db: db));
      await tester.pumpAndSettle();

      expect(find.text('No photos found'), findsOneWidget);
      expect(find.text('Try scanning different folders.'), findsOneWidget);
      expect(find.text('Select Folders'), findsOneWidget);
    });

    testWidgets('empty state select folders button navigates to /folders',
        (tester) async {
      final db = AppDatabase.inMemory();

      await tester.pumpWidget(_buildTestApp(db: db));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Select Folders'));
      await tester.pumpAndSettle();

      expect(find.text('Folder Selection'), findsOneWidget);
    });

    testWidgets('shows photo count in app bar title', (tester) async {
      final db = AppDatabase.inMemory();
      await _insertTestPhotos(db, 5);

      await tester.pumpWidget(_buildTestApp(db: db));
      await tester.pumpAndSettle();

      expect(find.text('PhotoFeed (5 photos)'), findsOneWidget);
    });

    testWidgets('displays month headers for photo groups', (tester) async {
      final db = AppDatabase.inMemory();
      await _insertTestPhotos(db, 3, yearMonth: '2024-06');

      await tester.pumpWidget(_buildTestApp(db: db));
      await tester.pumpAndSettle();

      expect(find.text('June 2024'), findsOneWidget);
    });

    testWidgets('displays multiple month groups', (tester) async {
      final db = AppDatabase.inMemory();
      await _insertTestPhotos(db, 2, yearMonth: '2024-06');
      // Insert photos for a different month
      await db.insertPhotoBatch([
        PhotosCompanion(
          path: const Value('/photos/jan_photo.jpg'),
          filename: const Value('jan_photo.jpg'),
          directory: const Value('/photos'),
          dateTaken: Value(DateTime(2024, 1, 10)),
          fileSize: const Value(2048),
          format: const Value('jpg'),
          yearMonth: const Value('2024-01'),
          orientation: const Value(1),
          fileModifiedAt: Value(DateTime(2024, 1, 10)),
        ),
      ]);

      await tester.pumpWidget(_buildTestApp(db: db));
      await tester.pumpAndSettle();

      expect(find.text('June 2024'), findsOneWidget);
      expect(find.text('January 2024'), findsOneWidget);
    });

    testWidgets('renders photo grid tiles', (tester) async {
      final db = AppDatabase.inMemory();
      await _insertTestPhotos(db, 4, yearMonth: '2024-06');

      await tester.pumpWidget(_buildTestApp(db: db));
      await tester.pumpAndSettle();

      // Should show placeholder icons since no actual thumbnails on disk
      expect(find.byIcon(Icons.photo_outlined), findsNWidgets(4));
    });

    testWidgets('sort toggle button is present and works', (tester) async {
      final db = AppDatabase.inMemory();
      await _insertTestPhotos(db, 2, yearMonth: '2024-06');

      await tester.pumpWidget(_buildTestApp(db: db));
      await tester.pumpAndSettle();

      // Default is newest first, shown with down arrow
      expect(find.byIcon(Icons.arrow_downward), findsOneWidget);

      // Tap sort toggle
      await tester.tap(find.byIcon(Icons.arrow_downward));
      await tester.pumpAndSettle();

      // Should now show up arrow (oldest first)
      expect(find.byIcon(Icons.arrow_upward), findsOneWidget);
    });

    testWidgets('re-scan button navigates to folders', (tester) async {
      final db = AppDatabase.inMemory();
      await _insertTestPhotos(db, 1, yearMonth: '2024-06');

      await tester.pumpWidget(_buildTestApp(db: db));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pumpAndSettle();

      expect(find.text('Folder Selection'), findsOneWidget);
    });

    testWidgets('displays PhotoFeed title when no photos', (tester) async {
      final db = AppDatabase.inMemory();

      await tester.pumpWidget(_buildTestApp(db: db));
      await tester.pumpAndSettle();

      expect(find.text('PhotoFeed'), findsOneWidget);
    });
  });

  group('MonthHeader', () {
    testWidgets('formats year-month correctly', (tester) async {
      final db = AppDatabase.inMemory();
      await _insertTestPhotos(db, 1, yearMonth: '2023-12');

      await tester.pumpWidget(_buildTestApp(db: db));
      await tester.pumpAndSettle();

      expect(find.text('December 2023'), findsOneWidget);
    });
  });

  group('PhotoGridTile', () {
    testWidgets('shows placeholder when no thumbnail', (tester) async {
      final db = AppDatabase.inMemory();
      await _insertTestPhotos(db, 1);

      await tester.pumpWidget(_buildTestApp(db: db));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.photo_outlined), findsOneWidget);
    });
  });
}
