import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:photo_feed/database/database.dart';
import 'package:photo_feed/services/platform_service.dart';
import 'package:photo_feed/widgets/photo_fullscreen.dart';

List<Photo> _createTestPhotos(int count) {
  return List.generate(count, (i) {
    return Photo(
      id: i + 1,
      path: '/photos/photo_$i.jpg',
      filename: 'photo_$i.jpg',
      directory: '/photos',
      dateTaken: DateTime(2024, 6, 15, 10, i),
      fileSize: 1024 * (i + 1),
      format: 'jpg',
      yearMonth: '2024-06',
      orientation: 1,
      isValid: true,
      fileModifiedAt: DateTime(2024, 6, 15),
      createdAt: DateTime.now(),
    );
  });
}

PlatformService _testPlatformService({
  List<String>? openedPaths,
}) {
  return PlatformService.custom(
    getAvailableDrives: () async => [],
    getDefaultPhotoDirectories: () => [],
    openFileManager: (path) async {
      openedPaths?.add(path);
    },
    getThumbnailCacheDirectory: () async => '/tmp/thumbnails',
  );
}

Widget _buildTestApp({
  required List<Photo> photos,
  int initialIndex = 0,
  PlatformService? platformService,
}) {
  final platform = platformService ?? _testPlatformService();
  return MaterialApp(
    home: Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () => PhotoFullscreen.show(
              context: context,
              photos: photos,
              initialIndex: initialIndex,
              platformService: platform,
            ),
            child: const Text('Open Fullscreen'),
          ),
        ),
      ),
    ),
  );
}

/// Opens the fullscreen dialog and pumps enough frames for it to render.
/// We use pump() instead of pumpAndSettle() because Image.file with
/// nonexistent files shows a loading spinner that never settles.
Future<void> _openDialog(WidgetTester tester) async {
  await tester.tap(find.text('Open Fullscreen'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  group('PhotoFullscreen', () {
    testWidgets('renders photo info in bottom bar', (tester) async {
      final photos = _createTestPhotos(3);
      await tester.pumpWidget(_buildTestApp(photos: photos, initialIndex: 0));
      await tester.pumpAndSettle();
      await _openDialog(tester);

      expect(find.text('/photos/photo_0.jpg'), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);
      expect(find.text('1 / 3'), findsOneWidget);
      expect(find.text('Open Folder'), findsOneWidget);
    });

    testWidgets('shows navigation arrows for middle photo', (tester) async {
      final photos = _createTestPhotos(3);
      await tester.pumpWidget(_buildTestApp(photos: photos, initialIndex: 1));
      await tester.pumpAndSettle();
      await _openDialog(tester);

      expect(find.text('2 / 3'), findsOneWidget);
      expect(find.byIcon(Icons.chevron_left), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('hides left arrow on first photo', (tester) async {
      final photos = _createTestPhotos(3);
      await tester.pumpWidget(_buildTestApp(photos: photos, initialIndex: 0));
      await tester.pumpAndSettle();
      await _openDialog(tester);

      expect(find.byIcon(Icons.chevron_left), findsNothing);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('hides right arrow on last photo', (tester) async {
      final photos = _createTestPhotos(3);
      await tester.pumpWidget(_buildTestApp(photos: photos, initialIndex: 2));
      await tester.pumpAndSettle();
      await _openDialog(tester);

      expect(find.byIcon(Icons.chevron_left), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsNothing);
    });

    testWidgets('navigates right via arrow button', (tester) async {
      final photos = _createTestPhotos(3);
      await tester.pumpWidget(_buildTestApp(photos: photos, initialIndex: 0));
      await tester.pumpAndSettle();
      await _openDialog(tester);

      expect(find.text('1 / 3'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('2 / 3'), findsOneWidget);
      expect(find.text('/photos/photo_1.jpg'), findsOneWidget);
    });

    testWidgets('navigates left via arrow button', (tester) async {
      final photos = _createTestPhotos(3);
      await tester.pumpWidget(_buildTestApp(photos: photos, initialIndex: 2));
      await tester.pumpAndSettle();
      await _openDialog(tester);

      expect(find.text('3 / 3'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.chevron_left));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('2 / 3'), findsOneWidget);
    });

    testWidgets('keyboard right arrow navigates forward', (tester) async {
      final photos = _createTestPhotos(3);
      await tester.pumpWidget(_buildTestApp(photos: photos, initialIndex: 0));
      await tester.pumpAndSettle();
      await _openDialog(tester);

      expect(find.text('1 / 3'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('2 / 3'), findsOneWidget);
    });

    testWidgets('keyboard left arrow navigates backward', (tester) async {
      final photos = _createTestPhotos(3);
      await tester.pumpWidget(_buildTestApp(photos: photos, initialIndex: 2));
      await tester.pumpAndSettle();
      await _openDialog(tester);

      expect(find.text('3 / 3'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('2 / 3'), findsOneWidget);
    });

    testWidgets('keyboard escape closes the dialog', (tester) async {
      final photos = _createTestPhotos(1);
      await tester.pumpWidget(_buildTestApp(photos: photos));
      await tester.pumpAndSettle();
      await _openDialog(tester);

      expect(find.text('1 / 1'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(find.text('Open Fullscreen'), findsOneWidget);
      expect(find.text('1 / 1'), findsNothing);
    });

    testWidgets('close button closes the dialog', (tester) async {
      final photos = _createTestPhotos(1);
      await tester.pumpWidget(_buildTestApp(photos: photos));
      await tester.pumpAndSettle();
      await _openDialog(tester);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.text('Open Fullscreen'), findsOneWidget);
      expect(find.byType(PhotoFullscreen), findsNothing);
    });

    testWidgets('Open Folder button calls platformService.openFileManager',
        (tester) async {
      final openedPaths = <String>[];
      final platform = _testPlatformService(openedPaths: openedPaths);
      final photos = _createTestPhotos(1);

      await tester.pumpWidget(
        _buildTestApp(photos: photos, platformService: platform),
      );
      await tester.pumpAndSettle();
      await _openDialog(tester);

      await tester.tap(find.text('Open Folder'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(openedPaths, ['/photos/photo_0.jpg']);
    });

    testWidgets('single photo shows no navigation arrows', (tester) async {
      final photos = _createTestPhotos(1);
      await tester.pumpWidget(_buildTestApp(photos: photos));
      await tester.pumpAndSettle();
      await _openDialog(tester);

      expect(find.byIcon(Icons.chevron_left), findsNothing);
      expect(find.byIcon(Icons.chevron_right), findsNothing);
      expect(find.text('1 / 1'), findsOneWidget);
    });
  });
}
