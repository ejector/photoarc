import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'database/database.dart';
import 'providers/feed_provider.dart';
import 'providers/scan_provider.dart';
import 'services/platform_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final appDir = await getApplicationSupportDirectory();
  final db = AppDatabase.onDisk(appDir.path);
  final platformService = PlatformService();

  runApp(
    MultiProvider(
      providers: [
        Provider<AppDatabase>.value(value: db),
        Provider<PlatformService>.value(value: platformService),
        ChangeNotifierProvider(
          create: (_) => ScanProvider(
            db: db,
            platformService: platformService,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => FeedProvider(db: db),
        ),
      ],
      child: const PhotoFeedApp(),
    ),
  );
}
