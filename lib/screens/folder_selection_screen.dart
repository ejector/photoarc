import 'package:flutter/material.dart';

class FolderSelectionScreen extends StatelessWidget {
  const FolderSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Folders'),
      ),
      body: const Center(
        child: Text('Folder selection will be implemented here.'),
      ),
    );
  }
}
