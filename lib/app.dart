import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'database/database.dart';
import 'screens/folder_selection_screen.dart';
import 'screens/scanning_screen.dart';
import 'screens/feed_screen.dart';

class PhotoArcApp extends StatelessWidget {
  const PhotoArcApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PhotoArc',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
        useMaterial3: true,
      ),
      home: const _InitialRouteDecider(),
      routes: {
        '/folders': (context) => const FolderSelectionScreen(),
        '/scanning': (context) => const ScanningScreen(),
        '/feed': (context) => const FeedScreen(),
      },
    );
  }
}

class _InitialRouteDecider extends StatefulWidget {
  const _InitialRouteDecider();

  @override
  State<_InitialRouteDecider> createState() => _InitialRouteDeciderState();
}

class _InitialRouteDeciderState extends State<_InitialRouteDecider> {
  @override
  void initState() {
    super.initState();
    _decide();
  }

  Future<void> _decide() async {
    final db = context.read<AppDatabase>();
    final photoCount = await db.getValidPhotoCount();

    if (!mounted) return;

    if (photoCount > 0) {
      Navigator.of(context).pushReplacementNamed('/feed');
    } else {
      Navigator.of(context).pushReplacementNamed('/folders');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
