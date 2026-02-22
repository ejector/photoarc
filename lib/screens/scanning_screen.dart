import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/feed_provider.dart';
import '../providers/scan_provider.dart';

class ScanningScreen extends StatefulWidget {
  const ScanningScreen({super.key});

  @override
  State<ScanningScreen> createState() => _ScanningScreenState();
}

class _ScanningScreenState extends State<ScanningScreen> {
  late final ScanProvider _scanProvider;

  @override
  void initState() {
    super.initState();
    _scanProvider = context.read<ScanProvider>();
    _scanProvider.addListener(_onScanStateChanged);
  }

  @override
  void dispose() {
    _scanProvider.removeListener(_onScanStateChanged);
    super.dispose();
  }

  void _onScanStateChanged() {
    final scanProvider = context.read<ScanProvider>();
    if (scanProvider.scanComplete && mounted) {
      _navigateToFeed();
    }
  }

  Future<void> _navigateToFeed() async {
    final feedProvider = context.read<FeedProvider>();
    await feedProvider.initialize();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/feed');
  }

  void _onCancel() {
    final scanProvider = context.read<ScanProvider>();
    scanProvider.stopScan();
    _navigateToFeed();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Consumer<ScanProvider>(
          builder: (context, scanProvider, _) {
            return ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.photo_library_outlined,
                        size: 48,
                        color: Colors.blueGrey,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Scanning for photos...',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 24),
                      const LinearProgressIndicator(),
                      const SizedBox(height: 24),
                      Text(
                        '${scanProvider.photosFound} photos found',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        scanProvider.currentDirectory.isNotEmpty
                            ? scanProvider.currentDirectory
                            : 'Preparing...',
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 24),
                      OutlinedButton(
                        onPressed: _onCancel,
                        child: const Text('Cancel'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
