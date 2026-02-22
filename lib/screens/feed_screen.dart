import 'package:flutter/material.dart';

class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PhotoFeed'),
      ),
      body: const Center(
        child: Text('Photo feed will be displayed here.'),
      ),
    );
  }
}
