import 'package:flutter/material.dart';

import 'screens/folder_selection_screen.dart';
import 'screens/scanning_screen.dart';
import 'screens/feed_screen.dart';

class PhotoFeedApp extends StatelessWidget {
  const PhotoFeedApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PhotoFeed',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const FolderSelectionScreen(),
        '/scanning': (context) => const ScanningScreen(),
        '/feed': (context) => const FeedScreen(),
      },
    );
  }
}
