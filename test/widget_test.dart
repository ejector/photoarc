import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:photoarc/app.dart';
import 'package:photoarc/database/database.dart';
import 'package:photoarc/providers/feed_provider.dart';
import 'package:photoarc/providers/scan_provider.dart';
import 'package:photoarc/services/photo_scanner.dart';
import 'package:photoarc/services/platform_service.dart';

class _FakePhotoScanner extends PhotoScanner {
  @override
  bool get isRunning => false;

  @override
  Stream<ScanProgress> startScan({
    required List<String> directories,
    required String thumbnailCacheDir,
    Map<String, DateTime> existingFiles = const {},
  }) =>
      const Stream.empty();

  @override
  void stop() {}
}

PlatformService _fakePlatformService() {
  return PlatformService.custom(
    getAvailableDrives: () async => [
      const DriveInfo(path: '/Users/test', label: 'Home'),
    ],
    getDefaultPhotoDirectories: () => ['/Users/test/Pictures'],
    openFileManager: (_) async {},
    getThumbnailCacheDirectory: () async => '/tmp/thumbnails',
  );
}

Widget _buildApp(AppDatabase db) {
  final platform = _fakePlatformService();
  return MultiProvider(
    providers: [
      Provider<AppDatabase>.value(value: db),
      Provider<PlatformService>.value(value: platform),
      ChangeNotifierProvider(
        create: (_) => ScanProvider(
          db: db,
          platformService: platform,
          scanner: _FakePhotoScanner(),
        ),
      ),
      ChangeNotifierProvider(
        create: (_) => FeedProvider(db: db),
      ),
    ],
    child: const PhotoFeedApp(),
  );
}

void main() {
  testWidgets('App builds and shows loading indicator initially',
      (tester) async {
    final db = AppDatabase.inMemory();
    await tester.pumpWidget(_buildApp(db));

    // The initial route decider shows a loading spinner
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('App navigates to folder selection when no photos exist',
      (tester) async {
    final db = AppDatabase.inMemory();
    await tester.pumpWidget(_buildApp(db));
    await tester.pumpAndSettle();

    // With no photos in DB, should navigate to folder selection
    expect(find.text('Select Folders'), findsOneWidget);
  });

  testWidgets('App uses Material 3', (tester) async {
    final db = AppDatabase.inMemory();
    await tester.pumpWidget(_buildApp(db));

    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(materialApp.theme?.useMaterial3, isTrue);
  });
}
